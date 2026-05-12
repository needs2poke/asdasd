-- Echoes of the Dark Wars - Combat System
-- Hybrid KOTOR-style: stat-driven turns with non-deterministic intent hints

RPG = RPG or {}
RPG.Combat = RPG.Combat or {}

-- Ability definitions now come from RPG.Data.Abilities (loaded from data/abilities.lua)

local function Clamp(value, minVal, maxVal)
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

local function RollPercent(chance)
    chance = Clamp(math.floor(chance + 0.5), 0, 100)
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    return math.random(1, 100) <= chance
end

local function GetStatMod(game, statName)
    local stats = game.player.stats or {}
    local statValue = stats[statName] or RPG.Config.STAT_BASE
    return RPG.Util.StatMod(statValue)
end

local function GetClassDef(game)
    return RPG.Data.Classes and RPG.Data.Classes[game.player.class]
end

local function IsForceUser(game)
    local cls = GetClassDef(game)
    return cls and cls.forceUser == true
end

local function AddResultLog(game, text)
    local combat = game.combat
    if not combat.resultLog then
        combat.resultLog = {}
    end
    combat.resultLog[#combat.resultLog + 1] = text
    while #combat.resultLog > 10 do
        table.remove(combat.resultLog, 1)
    end
end

-- Expose for companion system
RPG.Combat.Log = AddResultLog

local function HasEffect(effects, effectType)
    for _, effect in ipairs(effects) do
        if effect.type == effectType and (effect.remaining or 0) > 0 then
            return effect
        end
    end
    return nil
end

local function AddOrRefreshEffect(effects, newEffect)
    local existing = HasEffect(effects, newEffect.type)
    if existing then
        for k, v in pairs(newEffect) do
            if k == "remaining" then
                existing.remaining = math.max(existing.remaining or 0, v or 0)
            else
                existing[k] = v
            end
        end
        return
    end
    local entry = {}
    for k, v in pairs(newEffect) do
        entry[k] = v
    end
    effects[#effects + 1] = entry
end

local function RemoveExpiredEffects(effects)
    for i = #effects, 1, -1 do
        local effect = effects[i]
        if (effect.remaining or 0) <= 0 then
            table.remove(effects, i)
        end
    end
end

-- Expose for companion system (enemy effects)
function RPG.Combat.AddEnemyEffect(game, newEffect)
    if not game.combat or not game.combat.enemyEffects then return end
    AddOrRefreshEffect(game.combat.enemyEffects, newEffect)
end

local function ChooseWeightedAction(behavior)
    local weights = (RPG.Config.AI_BEHAVIORS and RPG.Config.AI_BEHAVIORS[behavior]) or RPG.Config.AI_BEHAVIORS.balanced
    local attackW = weights.attack or 0
    local specialW = weights.special or 0
    local defendW = weights.defend or 0
    local total = attackW + specialW + defendW
    if total <= 0 then
        return "attack"
    end

    local roll = math.random(1, total)
    if roll <= attackW then
        return "attack"
    elseif roll <= (attackW + specialW) then
        return "special"
    end
    return "defend"
end

local function ResolveLootDrops(player, game)
    local combat = game.combat
    local enemy = combat.enemy
    local droppedAny = false
    local lootNames = {}

    if not enemy.lootTable then
        return false, lootNames
    end

    for _, loot in ipairs(enemy.lootTable) do
        if RollPercent(loot.chance or 0) then
            droppedAny = true
            local name = RPG.Data.GetItemName(loot.itemId)
            if #game.player.inventory < RPG.Config.MAX_INVENTORY then
                game.player.inventory[#game.player.inventory + 1] = loot.itemId
                player:SendPrint("^5Loot:^7 " .. name)
                lootNames[#lootNames + 1] = name
            else
                player:SendPrint("^3Inventory full. Could not loot " .. name .. ".")
            end
        end
    end

    return droppedAny, lootNames
end

local function HasClassAbilities(game)
    if not game.player.abilitiesKnown then return false end
    for abilityId, _ in pairs(game.player.abilitiesKnown) do
        local def = RPG.Data.Abilities and RPG.Data.Abilities[abilityId]
        if def and def.type == "ability" then
            return true
        end
    end
    return false
end

local function HasUsableCombatItem(game)
    for _, itemId in ipairs(game.player.inventory) do
        local itemDef = RPG.Data.Items[itemId]
        if itemDef and itemDef.usableInCombat then
            return true
        end
    end
    return false
end

function RPG.Combat.GetWeaponDamage(game)
    local p = game.player
    local equippedWeaponId = p.equipped and p.equipped.weapon
    if equippedWeaponId then
        local equippedWeapon = RPG.Data.Items[equippedWeaponId]
        if equippedWeapon and equippedWeapon.damage then
            return equippedWeapon.damage
        end
    end

    for _, itemId in ipairs(p.inventory) do
        local itemDef = RPG.Data.Items[itemId]
        if itemDef and itemDef.slot == "weapon" and itemDef.damage then
            return itemDef.damage
        end
    end

    return 5
end

function RPG.Combat.GetArmorDefense(game)
    local equippedArmorId = game.player.equipped and game.player.equipped.armor
    if not equippedArmorId then
        return 0
    end
    local armorDef = RPG.Data.Items[equippedArmorId]
    return (armorDef and armorDef.defense) or 0
end

function RPG.Combat.GetAvailableActions(game)
    local actions = {
        { label = "^7Attack", action = "attack" },
        { label = "^7Defend", action = "defend" },
    }

    -- Check for known force powers (type="force")
    local hasForce = false
    if game.player.abilitiesKnown then
        for abilityId, _ in pairs(game.player.abilitiesKnown) do
            local def = RPG.Data.Abilities and RPG.Data.Abilities[abilityId]
            if def and def.type == "force" then
                hasForce = true
                break
            end
        end
    end

    if hasForce then
        if game.player.fp > 0 then
            actions[#actions + 1] = { label = "^5Force Power", action = "open_force" }
        else
            actions[#actions + 1] = { label = "^8Force Power (no FP)", action = "none" }
        end
    end

    if HasClassAbilities(game) then
        actions[#actions + 1] = { label = "^3Class Ability", action = "open_abilities" }
    end

    if HasUsableCombatItem(game) then
        actions[#actions + 1] = { label = "^7Use Item", action = "open_items" }
    else
        actions[#actions + 1] = { label = "^8Use Item (none)", action = "none" }
    end

    actions[#actions + 1] = { label = "^1Flee", action = "flee" }
    return actions
end

function RPG.Combat.GetForcePowerItems(game)
    local items = {}
    local fp = game.player.fp or 0
    local order = RPG.Data.AbilityOrder and RPG.Data.AbilityOrder.force or {}

    for _, abilityId in ipairs(order) do
        if game.player.abilitiesKnown[abilityId] then
            local def = RPG.Data.Abilities[abilityId]
            if def and def.type == "force" then
                local fpCost = def.fp or 0
                if game.player.abilitiesKnown.force_attunement and fpCost > 0 then
                    fpCost = math.max(5, fpCost - 2)
                end
                local enoughFP = fp >= fpCost
                local tag = RPG.Data.GetAbilityDisplayTag(def)
                local color = enoughFP and "^5" or "^8"
                local action = enoughFP and ("force:" .. abilityId) or "none"
                items[#items + 1] = {
                    label = color .. tag .. " " .. def.name .. "^7 (" .. fpCost .. " FP)",
                    action = action,
                }
            end
        end
    end

    if #items == 0 then
        items[#items + 1] = { label = "^8No Force powers known.", action = "none" }
    end

    items[#items + 1] = { label = "^3<<< Back", action = "back_main" }
    return items
end

function RPG.Combat.GetClassAbilityItems(game)
    local items = {}
    local cls = GetClassDef(game)
    local classId = game.player.class

    -- Determine which ordered list to use
    local order = RPG.Data.AbilityOrder and RPG.Data.AbilityOrder[classId] or {}

    for _, abilityId in ipairs(order) do
        if game.player.abilitiesKnown[abilityId] then
            local def = RPG.Data.Abilities[abilityId]
            if def and def.type == "ability" then
                local tag = RPG.Data.GetAbilityDisplayTag(def)
                items[#items + 1] = {
                    label = "^3" .. tag .. " " .. def.name,
                    action = "ability:" .. abilityId,
                }
            end
        end
    end

    if #items == 0 then
        items[#items + 1] = { label = "^8No class abilities available.", action = "none" }
    end

    items[#items + 1] = { label = "^3<<< Back", action = "back_main" }
    return items
end

function RPG.Combat.GetCombatItemItems(game)
    local items = {}
    local foundAny = false

    for invIndex, itemId in ipairs(game.player.inventory) do
        local itemDef = RPG.Data.Items[itemId]
        if itemDef and itemDef.usableInCombat then
            foundAny = true
            local amount = itemDef.healAmount and (" +" .. itemDef.healAmount .. " HP") or ""
            items[#items + 1] = {
                label = RPG.Config.ITEM_COLOR .. itemDef.name .. "^7" .. amount,
                action = "item:" .. invIndex,
            }
        end
    end

    if not foundAny then
        items[#items + 1] = { label = "^8No usable combat items.", action = "none" }
    end

    items[#items + 1] = { label = "^3<<< Back", action = "back_main" }
    return items
end

-- ============================================
-- SAEVUS COMBAT WHISPERS
-- ============================================

local SAEVUS_COMBAT_WHISPERS = {
    flee = {
        "Running? I never ran. That's the difference between us.",
        "Cowardice has a smell. The enemy can taste it.",
        "Every step backward is a step toward me.",
    },
    near_death_victory = {
        "You almost died. You almost LIVED. There's a difference.",
        "The edge of death sharpens the mind. I should know.",
        "They nearly had you. Next time, don't give them the chance.",
    },
    backfire = {
        "My power is not a toy. Treat it with respect.",
        "You fumble with the dark side like a child with a blade.",
        "Control comes through surrender. Stop fighting ME.",
    },
    repeated_defend = {
        "Hiding behind your guard? Is that what the Jedi taught you?",
        "A shield is just a delay. The blow always comes.",
        "Stop cowering. ATTACK.",
    },
    first_kill = {
        "A new species of prey. How does it feel?",
        "Remember this one. You'll see their face in your dreams.",
        "The first time is always the hardest. It gets easier. That's the problem.",
    },
    restraint = {
        "Mercy. How... predictable.",
        "You could have ended it faster. You chose not to. Interesting.",
        "Restraint is just cowardice with better branding.",
    },
    flashback_echo = {
        "You remember now. Good.",
        "That power was always yours. I just... reminded you.",
        "The past is not dead. It's not even past.",
    },
}

--- Saevus combat whisper helper. Returns true if whisper fired.
--- trigger: key into SAEVUS_COMBAT_WHISPERS table
--- opts.useBatchPrint: true for post-combat whispers (EndCombat context)
function RPG.Combat.SaevusReact(player, game, trigger, opts)
    if not game.player.hasHolocron then return false end
    if game.player.paranoia < 30 then return false end
    local pool = SAEVUS_COMBAT_WHISPERS[trigger]
    if not pool or #pool == 0 then return false end

    -- Mid-combat cooldown: 2 rounds between whispers
    opts = opts or {}
    if not opts.useBatchPrint then
        local lastRound = game.combat.lastSaevusWhisperRound or -10
        if game.combat.round and (game.combat.round - lastRound) < 2 then
            return false
        end
    end

    local line = pool[math.random(1, #pool)]
    if opts.useBatchPrint then
        RPG.Util.BatchPrint(player, { "^1[WHISPER] " .. line .. "^7" })
    else
        AddResultLog(game, "^1[WHISPER] " .. line .. "^7")
        game.combat.lastSaevusWhisperRound = game.combat.round or 0
    end
    return true
end

function RPG.Combat.CheckLevelUp(player, game)
    local p = game.player
    local leveled = false

    while p.level < RPG.Config.MAX_LEVEL and p.xp >= p.xpToNext do
        p.level = p.level + 1
        p.xpToNext = p.level * RPG.Config.XP_PER_LEVEL

        local hpGain = math.max(1, 8 + GetStatMod(game, "CON"))
        p.maxHP = p.maxHP + hpGain

        local fpGain = 0
        if IsForceUser(game) then
            fpGain = math.max(1, 10 + GetStatMod(game, "WIS"))
            p.maxFP = p.maxFP + fpGain
        end

        p.hp = p.maxHP
        p.fp = p.maxFP
        leveled = true

        local lvlLines = {
            "^2LEVEL UP!^7 You are now level " .. p.level .. ".",
            "^2+" .. hpGain .. " max HP^7",
        }
        if fpGain > 0 then
            lvlLines[#lvlLines + 1] = "^5+" .. fpGain .. " max FP^7"
        end
        lvlLines[#lvlLines + 1] = "^7You feel renewed."

        -- Stat point allocation at milestone levels
        if RPG.Config.STAT_POINT_LEVELS[p.level] then
            p.pendingStatPoints = (p.pendingStatPoints or 0) + 1
            lvlLines[#lvlLines + 1] = "^3+1 Stat Point available! (spend in Character Sheet)^7"
        end

        RPG.Util.BatchPrint(player, lvlLines)

        -- Scan ability registry for level-based unlocks at this level
        if RPG.Data.Abilities then
            for abilityId, abilityDef in pairs(RPG.Data.Abilities) do
                if not p.abilitiesKnown[abilityId] then
                    local unlockMatch = false
                    -- Check primary unlock
                    local u = abilityDef.unlock
                    if u and u.method == "level" and u.level == p.level then
                        if u.classes then
                            for _, cls in ipairs(u.classes) do
                                if cls == game.player.class then
                                    unlockMatch = true
                                    break
                                end
                            end
                        end
                    end
                    -- Check fallback unlock (e.g. force_heal echo fallback)
                    if not unlockMatch and abilityDef.unlockFallback then
                        local uf = abilityDef.unlockFallback
                        if uf.method == "level" and uf.level == p.level then
                            if uf.classes then
                                for _, cls in ipairs(uf.classes) do
                                    if cls == game.player.class then
                                        unlockMatch = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if unlockMatch then
                        RPG.GrantAbility(player, abilityId)

                        -- Saevus whisper on level-8/12 ability unlock
                        if game.player.hasHolocron then
                            local SAEVUS_LEVEL_WHISPERS = {
                                saber_throw      = "^1[WHISPER] Distance is just a delay. Close the gap.",
                                force_wave       = "^1[WHISPER] Why kill them when you can unmake their footing?",
                                force_cloak      = "^1[WHISPER] Invisibility suits you. You've been hiding your whole life.",
                                suppressing_fire = "^1[WHISPER] Make them flinch. Then make them regret.",
                                cheap_shot       = "^1[WHISPER] Honest men die hungry. You're learning.",
                                wrist_rocket     = "^1[WHISPER] Crude, but effective. I approve.",
                                shien_mastery    = "^1[WHISPER] Offense and defense are the same thing. I knew that once.",
                                force_sever      = "^1[WHISPER] To cut someone from the Force... I did that to an entire world.",
                                nullify          = "^1[WHISPER] You see through lies now. Be careful. Some truths are worse.",
                                last_stand       = "^1[WHISPER] You refuse to fall. Admirable. Foolish. Both.",
                                killswitch       = "^1[WHISPER] The killing blow is the easy part. Knowing when -- that's the art.",
                                orbital_strike   = "^1[WHISPER] I once leveled a city from orbit. You're getting there.",
                            }
                            local whisper = SAEVUS_LEVEL_WHISPERS[abilityId]
                            if whisper then
                                player:SendPrint(whisper)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Scale companion HP on level up
    if leveled and RPG.Companion and RPG.Companion.ScaleToLevel then
        RPG.Companion.ScaleToLevel(game)
    end

    return leveled
end

function RPG.Combat.GenerateIntentHint(player, game)
    local combat = game.combat
    local enemy = combat.enemy

    combat.enemyIntentKey = ChooseWeightedAction(enemy.behavior)
    local intent = enemy.intents and enemy.intents[combat.enemyIntentKey]

    local wisdom = (game.player.stats and game.player.stats.WIS) or RPG.Config.STAT_BASE
    if wisdom >= RPG.Config.INTENT_WIS_THRESHOLD and intent and intent.clear then
        combat.enemyIntentText = "^3[INSTINCT]^7 " .. intent.clear
    elseif wisdom >= (RPG.Config.INTENT_WIS_THRESHOLD - 4) and intent and intent.vague then
        combat.enemyIntentText = "^8" .. intent.vague
    else
        combat.enemyIntentText = "^8You sense nothing certain about its next move."
    end

    if player and player:IsValid() then
        player:SendPrint(combat.enemyIntentText)
    end
end

--- Check if a dark power backfires based on paranoia
--- Returns nil (no backfire) or the backfire effect tier string
function RPG.Combat.CheckBackfire(game, abilityDef)
    if not abilityDef.dark then return nil end
    -- First dark power use per combat is always free
    if RPG.Config.BACKFIRE_FIRST_FREE and not game.player.darkPowerUsed then
        game.player.darkPowerUsed = true
        return nil
    end
    game.player.darkPowerUsed = true

    local paranoia = game.player.paranoia or 0
    local tiers = RPG.Config.BACKFIRE_TIERS
    if not tiers then return nil end

    for _, tier in ipairs(tiers) do
        if paranoia >= tier.min and paranoia <= tier.max then
            if tier.chance > 0 and math.random(1, 100) <= tier.chance then
                return tier.effect
            end
            return nil
        end
    end
    return nil
end

--- Resolve a single ability's combat effect
--- Returns { consumed, damage, actionType, ... }
function RPG.Combat.ResolveAbility(player, game, abilityId)
    local combat = game.combat
    local p = game.player
    local enemy = combat.enemy
    local wisMod = GetStatMod(game, "WIS")
    local strMod = GetStatMod(game, "STR")
    local dexMod = GetStatMod(game, "DEX")
    local conMod = GetStatMod(game, "CON")
    local intMod = GetStatMod(game, "INT")
    local abilityDef = RPG.Data.Abilities[abilityId]
    if not abilityDef then return { consumed = false } end

    -- Force Attunement: extra WIS scaling on force powers
    local attunementBonus = 0
    if p.abilitiesKnown.force_attunement and abilityDef.type == "force" then
        attunementBonus = math.max(0, wisMod)
    end

    -- Backfire check for dark powers
    local backfire = RPG.Combat.CheckBackfire(game, abilityDef)
    local damageMult = 1.0
    local selfDamage = 0
    local backfireAlignPenalty = 0
    if backfire then
        if backfire == "partial" then
            damageMult = 0.75
            local whispers = RPG.Config.BACKFIRE_WHISPERS or {}
            local whisper = whispers[math.random(1, math.max(1, #whispers))] or "The dark side resists..."
            AddResultLog(game, "^1" .. whisper .. "^7")
        elseif backfire == "strain" then
            damageMult = 0.5
            selfDamage = 5
            AddResultLog(game, "^1The dark side surges through you -- too much. You stagger. (-5 HP)^7")
        elseif backfire == "surge" then
            damageMult = 0.5
            selfDamage = 8
            AddResultLog(game, "^1Your hands shake. The power tears at you as it leaves. (-8 HP)^7")
        elseif backfire == "seize" then
            damageMult = 1.0
            selfDamage = 10
            backfireAlignPenalty = -1
            AddResultLog(game, "^1For a moment, your hands move on their own. (-10 HP, -1 alignment)^7")
        end
        RPG.Combat.SaevusReact(player, game, "backfire")
    end

    -- Apply alignment penalty for dark power use (capped per combat)
    if abilityDef.dark then
        local basePenalty = -2
        if abilityId == "force_storm" then basePenalty = -3 end
        local cap = RPG.Config.DARK_ALIGNMENT_CAP_PER_COMBAT or -4
        local alreadyUsed = combat.darkAlignmentUsed or 0
        local remaining = cap - alreadyUsed
        if remaining < 0 then
            local penalty = math.max(remaining, basePenalty)
            p.alignment = math.max(RPG.Config.ALIGNMENT_MIN, p.alignment + penalty)
            combat.darkAlignmentUsed = (combat.darkAlignmentUsed or 0) + penalty
        end
        -- Backfire alignment penalty (not capped)
        if backfireAlignPenalty ~= 0 then
            p.alignment = math.max(RPG.Config.ALIGNMENT_MIN, p.alignment + backfireAlignPenalty)
        end
    end

    -- Apply self-damage from backfire
    if selfDamage > 0 then
        p.hp = math.max(1, p.hp - selfDamage)
    end

    -- ========================================
    -- FORCE POWERS
    -- ========================================
    if abilityId == "force_push" then
        local damage = math.max(1, math.floor((15 + wisMod * 2 + attunementBonus) * damageMult))
        enemy.hp = math.max(0, enemy.hp - damage)
        AddResultLog(game, "^3Force Push^7 slams the enemy for " .. damage .. " damage.")
        if RollPercent(30) then
            AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = 1 })
            AddResultLog(game, "^3The enemy staggers!")
        end
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "force_heal" then
        local healAmount = math.max(1, 30 + (wisMod * 5) + attunementBonus)
        local before = p.hp
        p.hp = math.min(p.maxHP, p.hp + healAmount)
        AddResultLog(game, "^5Force Heal^7 restores " .. (p.hp - before) .. " HP.")
        return { actionType = "none", damage = 0, consumed = true }
    end

    if abilityId == "force_speed" then
        combat.playerDefenseBonus = (combat.playerDefenseBonus or 0) + 8
        combat.playerDamageBonus = math.min((combat.playerDamageBonus or 0) + 5, 15)
        AddResultLog(game, "^5Force Speed^7 quickens your reflexes. (+5 dmg, +8 def)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    if abilityId == "force_lightning" then
        local rawDamage = 25 + (wisMod * 3) + attunementBonus
        local damage = math.max(1, math.floor(rawDamage * damageMult))
        local bypassDefense = math.floor((enemy.defense or 0) * 0.5)
        local finalDamage = math.max(1, damage - bypassDefense)
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^1Force Lightning^7 deals " .. finalDamage .. " damage.")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    if abilityId == "force_barrier" then
        combat.playerDefending = true
        combat.playerDefenseBonus = (combat.playerDefenseBonus or 0) + 10
        AddResultLog(game, "^5Force Barrier^7 shields you. (+10 defense)")
        return { actionType = "defend", damage = 0, consumed = true }
    end

    if abilityId == "force_drain" then
        local rawDamage = 15 + (wisMod * 2) + attunementBonus
        local damage = math.max(1, math.floor(rawDamage * damageMult))
        enemy.hp = math.max(0, enemy.hp - damage)
        local healAmt = math.floor(damage * 0.5)
        p.hp = math.min(p.maxHP, p.hp + healAmt)
        AddResultLog(game, "^1Force Drain^7 deals " .. damage .. " damage, heals " .. healAmt .. " HP.")
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "force_stasis" then
        local stunRounds = wisMod >= 4 and 2 or 1
        AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = stunRounds })
        AddResultLog(game, "^5Force Stasis^7 locks the enemy in place.")
        return { actionType = "none", damage = 0, consumed = true }
    end

    if abilityId == "force_storm" then
        local rawDamage = 30 + (wisMod * 3) + attunementBonus
        local damage = math.max(1, math.floor(rawDamage * damageMult))
        local bypassDefense = math.floor((enemy.defense or 0) * 0.5)
        local finalDamage = math.max(1, damage - bypassDefense)
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^1Force Storm^7 deals " .. finalDamage .. " damage.")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    if abilityId == "force_absorb" then
        combat.playerDefending = true
        combat.playerDefenseBonus = (combat.playerDefenseBonus or 0) + 12
        combat.absorbActive = true
        AddResultLog(game, "^5Force Absorb^7 shields you. (+12 defense, absorb enemy specials)")
        return { actionType = "defend", damage = 0, consumed = true }
    end

    -- ========================================
    -- SOLDIER ABILITIES
    -- ========================================
    if abilityId == "war_cry" then
        combat.playerDamageBonus = 10
        combat.playerDefenseBonus = math.max(combat.playerDefenseBonus or 0, 5)
        AddResultLog(game, "^3War Cry^7 empowers your next strike.")
        return { actionType = "none", damage = 0, consumed = true }
    end

    if abilityId == "shield_bash" then
        local damage = math.max(1, 12 + strMod)
        enemy.hp = math.max(0, enemy.hp - damage)
        AddResultLog(game, "^3Shield Bash^7 hits for " .. damage .. " damage.")
        if RollPercent(30) then
            AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = 1 })
            AddResultLog(game, "^3The enemy is dazed!")
        end
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "adrenaline_rush" then
        local healAmount = math.max(1, 20 + (conMod * 3))
        local before = p.hp
        p.hp = math.min(p.maxHP, p.hp + healAmount)
        -- Remove stun and poison
        for i = #combat.playerEffects, 1, -1 do
            local eff = combat.playerEffects[i]
            if eff.type == "stun" or eff.type == "poison" then
                table.remove(combat.playerEffects, i)
            end
        end
        AddResultLog(game, "^3Adrenaline Rush^7 heals " .. (p.hp - before) .. " HP, clears effects.")
        return { actionType = "none", damage = 0, consumed = true }
    end

    if abilityId == "power_shot" then
        local damage = math.max(1, 20 + (strMod * 2))
        local bypassDefense = math.floor((enemy.defense or 0) * 0.5)
        local finalDamage = math.max(1, damage - bypassDefense)
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^3Power Shot^7 pierces armor for " .. finalDamage .. " damage.")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    if abilityId == "rally" then
        combat.playerDamageBonus = math.min((combat.playerDamageBonus or 0) + 8, 15)
        combat.playerDefenseBonus = (combat.playerDefenseBonus or 0) + 8
        AddResultLog(game, "^3Rally^7 steels your resolve. (+8 dmg, +8 def)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- ========================================
    -- SCOUNDREL ABILITIES
    -- ========================================
    if abilityId == "blaster_shot" then
        local hitChance = Clamp(RPG.Config.BASE_HIT_CHANCE + 10 + (dexMod * 2), 5, 95)
        if not RollPercent(hitChance) then
            AddResultLog(game, "^8Your blaster shot misses.")
            combat.playerDamageBonus = 0
            return { actionType = "none", damage = 0, consumed = true }
        end
        local rawDamage = 15 + dexMod + (combat.playerDamageBonus or 0)
        combat.playerDamageBonus = 0
        local finalDamage = math.max(1, rawDamage - math.floor((enemy.defense or 0) * 0.5))
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^3Blaster Shot^7 hits for " .. finalDamage .. " damage.")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    if abilityId == "dirty_trick" then
        if RollPercent(50) then
            AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = 1 })
            AddResultLog(game, "^3Dirty Trick^7 succeeds. Enemy stunned.")
        else
            AddResultLog(game, "^8Dirty Trick fails.")
        end
        return { actionType = "none", damage = 0, consumed = true }
    end

    if abilityId == "stealth_strike" then
        local isStunned = HasEffect(combat.enemyEffects, "stun")
        local baseDmg = 12 + (dexMod * 2)
        if isStunned then baseDmg = baseDmg * 2 end
        local damage = math.max(1, baseDmg)
        enemy.hp = math.max(0, enemy.hp - damage)
        if isStunned then
            AddResultLog(game, "^3Stealth Strike^7 exploits the opening for " .. damage .. " damage!")
        else
            AddResultLog(game, "^3Stealth Strike^7 deals " .. damage .. " damage.")
        end
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "disabling_shot" then
        local damage = math.max(1, 10 + dexMod)
        enemy.hp = math.max(0, enemy.hp - damage)
        AddOrRefreshEffect(combat.enemyEffects, { type = "poison", damage = 4, remaining = 2 })
        AddResultLog(game, "^3Disabling Shot^7 hits for " .. damage .. " and poisons the enemy.")
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "exploit_weakness" then
        local damage = math.max(1, 18 + (intMod * 3))
        -- Forced crit
        local finalDamage = math.max(1, math.floor(damage * RPG.Config.CRIT_MULTIPLIER + 0.5))
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^3CRITICAL: Exploit Weakness^7 hits for " .. finalDamage .. " damage!")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    -- ========================================
    -- HUNTER ABILITIES
    -- ========================================
    if abilityId == "tracking_shot" then
        local damage = math.max(1, 8 + dexMod)
        enemy.hp = math.max(0, enemy.hp - damage)
        combat.playerDamageBonus = math.min((combat.playerDamageBonus or 0) + 8, 15)
        AddResultLog(game, "^3Tracking Shot^7 hits for " .. damage .. " damage. Target marked (+8 next dmg).")
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "flamethrower" then
        local damage = math.max(1, 14 + dexMod)
        enemy.hp = math.max(0, enemy.hp - damage)
        AddOrRefreshEffect(combat.enemyEffects, { type = "poison", damage = 5, remaining = 2 })
        AddResultLog(game, "^3Flamethrower^7 scorches for " .. damage .. " damage. Target burns!")
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "grapple_wire" then
        local damage = math.max(1, 10 + strMod)
        enemy.hp = math.max(0, enemy.hp - damage)
        AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = 1 })
        AddResultLog(game, "^3Grapple Wire^7 snares for " .. damage .. " damage. Enemy entangled!")
        return { actionType = "none", damage = damage, consumed = true }
    end

    if abilityId == "marked_for_death" then
        local damage = math.max(1, 10 + dexMod)
        enemy.hp = math.max(0, enemy.hp - damage)
        combat.playerDamageBonus = math.min((combat.playerDamageBonus or 0) + 10, 15)
        AddResultLog(game, "^3Marked for Death^7 hits for " .. damage .. " damage. Mark set (+10 next dmg).")
        return { actionType = "none", damage = damage, consumed = true }
    end

    -- ========================================
    -- LEVEL 8 ABILITIES
    -- ========================================

    -- Guardian: Saber Throw — 20 + STR*3 damage, ignores 25% defense
    if abilityId == "saber_throw" then
        local rawDamage = math.floor((20 + strMod * 3) * damageMult)
        local bypassDefense = math.floor((enemy.defense or 0) * 0.75)
        local finalDamage = math.max(1, rawDamage - bypassDefense)
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^5Saber Throw^7 arcs through the air for " .. finalDamage .. " damage.")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    -- Consular: Force Wave — 18 + WIS*3 damage, 40% stun
    if abilityId == "force_wave" then
        local rawDamage = math.floor((18 + wisMod * 3 + attunementBonus) * damageMult)
        local finalDamage = math.max(1, rawDamage)
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^5Force Wave^7 blasts the enemy for " .. finalDamage .. " damage.")
        if RollPercent(40) then
            AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = 1 })
            AddResultLog(game, "^3The enemy is staggered!")
        end
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    -- Sentinel: Force Cloak — +50% next attack damage, +5 defense
    if abilityId == "force_cloak" then
        combat.playerDamageBonus = (combat.playerDamageBonus or 0) + math.floor(RPG.Combat.GetWeaponDamage(game) * 0.5)
        combat.playerDefenseBonus = (combat.playerDefenseBonus or 0) + 5
        AddResultLog(game, "^5Force Cloak^7 bends light around you. (+50%% next attack, +5 def)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- Soldier: Suppressing Fire — 10 + STR*2 damage, -25% enemy damage 2 rounds
    if abilityId == "suppressing_fire" then
        local damage = math.max(1, 10 + strMod * 2)
        enemy.hp = math.max(0, enemy.hp - damage)
        AddOrRefreshEffect(combat.enemyEffects, { type = "suppressed", remaining = 2, damageMult = 0.75 })
        AddResultLog(game, "^3Suppressing Fire^7 hits for " .. damage .. " damage. Enemy suppressed! (-25%% dmg for 2 rounds)")
        return { actionType = "none", damage = damage, consumed = true }
    end

    -- Scoundrel: Cheap Shot — 12 + DEX*2 damage, doubled if stunned
    if abilityId == "cheap_shot" then
        local isStunned = HasEffect(combat.enemyEffects, "stun")
        local baseDmg = 12 + (dexMod * 2)
        if isStunned then baseDmg = baseDmg * 2 end
        local damage = math.max(1, baseDmg)
        enemy.hp = math.max(0, enemy.hp - damage)
        if isStunned then
            AddResultLog(game, "^3Cheap Shot^7 exploits the opening for " .. damage .. " damage!")
        else
            AddResultLog(game, "^3Cheap Shot^7 connects for " .. damage .. " damage.")
        end
        return { actionType = "none", damage = damage, consumed = true }
    end

    -- Hunter: Wrist Rocket — 18 + DEX*3 damage, ignores 50% defense, 2 uses per combat
    if abilityId == "wrist_rocket" then
        combat.wristRocketUses = (combat.wristRocketUses or 0) + 1
        if combat.wristRocketUses > 2 then
            AddResultLog(game, "^8No rockets remaining this combat.")
            return { consumed = false }
        end
        local rawDamage = 18 + dexMod * 3
        local bypassDefense = math.floor((enemy.defense or 0) * 0.5)
        local finalDamage = math.max(1, rawDamage - bypassDefense)
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        local remaining = 2 - combat.wristRocketUses
        AddResultLog(game, "^3Wrist Rocket^7 detonates for " .. finalDamage .. " damage. (" .. remaining .. " left)")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    -- ========================================
    -- FLASHBACK ABILITIES (latent Force classes)
    -- ========================================

    -- Soldier dark: Executioner's Eye — +6 next attack damage, +3 paranoia
    if abilityId == "executioners_eye" then
        combat.playerDamageBonus = (combat.playerDamageBonus or 0) + 6
        RPG.AddParanoia(player, 3)
        AddResultLog(game, "^1Executioner's Eye^7 sharpens your focus. (+6 next attack)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- Soldier light: Unbreakable Will — clear stun, +2 defense 2 rounds
    if abilityId == "unbreakable_will" then
        for i = #combat.playerEffects, 1, -1 do
            if combat.playerEffects[i].type == "stun" then
                table.remove(combat.playerEffects, i)
            end
        end
        AddOrRefreshEffect(combat.playerEffects, { type = "stun_immune", remaining = 1 })
        AddOrRefreshEffect(combat.playerEffects, { type = "will_defense", remaining = 2, defense = 2 })
        AddResultLog(game, "^5Unbreakable Will^7 steels your mind. (Stun immune, +2 def)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- Scoundrel dark: Cold Read — +4 damage, bypasses defend, +3 paranoia
    if abilityId == "cold_read" then
        combat.playerDamageBonus = (combat.playerDamageBonus or 0) + 4
        combat.coldReadActive = true
        RPG.AddParanoia(player, 3)
        AddResultLog(game, "^1Cold Read^7 exposes their weakness. (+4 dmg, halve defense)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- Scoundrel light: Slippery Mind — 50% avoid next enemy special
    if abilityId == "slippery_mind" then
        combat.slipperyMindActive = true
        AddResultLog(game, "^5Slippery Mind^7 sharpens your instincts. (50%% avoid next special)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- Hunter dark: Killing Instinct — +8 first attack damage, +3 paranoia
    if abilityId == "killing_instinct" then
        combat.playerDamageBonus = (combat.playerDamageBonus or 0) + 8
        RPG.AddParanoia(player, 3)
        AddResultLog(game, "^1Killing Instinct^7 locks in. (+8 next attack)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- Hunter light: Adaptive Tactics — +3 damage, +2 defense for 2 rounds
    if abilityId == "adaptive_tactics" then
        AddOrRefreshEffect(combat.playerEffects, { type = "adaptive", remaining = 2, damage = 3, defense = 2 })
        AddResultLog(game, "^5Adaptive Tactics^7 adjusts your approach. (+3 dmg, +2 def for 2 rounds)")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- ========================================
    -- LEVEL-12 CAPSTONE ABILITIES
    -- ========================================

    -- Guardian: Shien Mastery — 25 + STR*3 + WIS*2, ignore 50% defense
    if abilityId == "shien_mastery" then
        local rawDamage = math.floor((25 + strMod * 3 + wisMod * 2 + attunementBonus) * damageMult)
        local reducedDefense = math.floor((enemy.defense or 0) * 0.5)
        local finalDamage = math.max(1, rawDamage - reducedDefense)
        enemy.hp = math.max(0, enemy.hp - finalDamage)
        AddResultLog(game, "^3Shien Mastery^7 cleaves through defenses for " .. finalDamage .. " damage.")
        return { actionType = "none", damage = finalDamage, consumed = true }
    end

    -- Consular: Force Sever — 20 + WIS*4 + attunement, purge enemy effects
    if abilityId == "force_sever" then
        local damage = math.max(1, math.floor((20 + wisMod * 4 + attunementBonus) * damageMult))
        enemy.hp = math.max(0, enemy.hp - damage)
        -- Purge all enemy positive effects (heal buffs, damage buffs)
        local purged = 0
        for i = #combat.enemyEffects, 1, -1 do
            local eff = combat.enemyEffects[i]
            if eff.type ~= "stun" and eff.type ~= "poison" and eff.type ~= "suppressed" then
                table.remove(combat.enemyEffects, i)
                purged = purged + 1
            end
        end
        local purgeText = purged > 0 and (" Purged " .. purged .. " effect(s).") or ""
        AddResultLog(game, "^3Force Sever^7 cuts for " .. damage .. " damage." .. purgeText)
        return { actionType = "none", damage = damage, consumed = true }
    end

    -- Sentinel: Nullify — guaranteed hit, 15 + DEX*2 + WIS*2, conditional stun/pierce
    if abilityId == "nullify" then
        local damage = math.max(1, math.floor((15 + dexMod * 2 + wisMod * 2 + attunementBonus) * damageMult))
        local lastIntent = combat.enemyIntentKey
        if lastIntent == "defend" then
            -- Ignore all defense
            enemy.hp = math.max(0, enemy.hp - damage)
            AddResultLog(game, "^3Nullify^7 pierces all defenses for " .. damage .. " damage.")
        else
            -- Attack or special: apply damage through normal defense then stun
            local finalDamage = math.max(1, damage - (enemy.defense or 0))
            enemy.hp = math.max(0, enemy.hp - finalDamage)
            AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = 1 })
            AddResultLog(game, "^3Nullify^7 strikes for " .. finalDamage .. " damage and stuns the enemy!")
            damage = finalDamage
        end
        return { actionType = "none", damage = damage, consumed = true }
    end

    -- Soldier: Last Stand — heal 25% maxHP, +6 dmg/+4 def for 3-5 rounds, once per combat
    if abilityId == "last_stand" then
        if combat.lastStandUsed then
            AddResultLog(game, "^8Last Stand can only be used once per combat.")
            return { consumed = false }
        end
        combat.lastStandUsed = true
        local healAmt = math.floor(p.maxHP * 0.25)
        p.hp = math.min(p.maxHP, p.hp + healAmt)
        local duration = 3
        if p.hp < math.floor(p.maxHP * 0.3) then
            duration = 5
        end
        AddOrRefreshEffect(combat.playerEffects, { type = "last_stand", remaining = duration, damage = 6, defense = 4 })
        AddResultLog(game, "^3Last Stand!^7 +" .. healAmt .. " HP, +6 dmg/+4 def for " .. duration .. " rounds.")
        return { actionType = "none", damage = 0, consumed = true }
    end

    -- Scoundrel: Killswitch — execute at <=15% HP or damage + poison + stun
    if abilityId == "killswitch" then
        local threshold = math.floor(enemy.maxHP * 0.15)
        if enemy.hp <= threshold then
            enemy.hp = 0
            AddResultLog(game, "^1Killswitch^7 — the target drops. Instant kill.")
            return { actionType = "none", damage = enemy.maxHP, consumed = true }
        end
        local chaMod = GetStatMod(game, "CHA")
        local damage = math.max(1, 15 + dexMod * 3 + chaMod * 2)
        enemy.hp = math.max(0, enemy.hp - damage)
        AddOrRefreshEffect(combat.enemyEffects, { type = "poison", damage = 6, remaining = 3 })
        AddOrRefreshEffect(combat.enemyEffects, { type = "stun", remaining = 1 })
        AddResultLog(game, "^3Killswitch^7 deals " .. damage .. " damage, poisons, and stuns!")
        return { actionType = "none", damage = damage, consumed = true }
    end

    -- Hunter: Orbital Strike — 30 + STR*2 + DEX*2, suppressed + burn, once per combat
    if abilityId == "orbital_strike" then
        if combat.orbitalStrikeUsed then
            AddResultLog(game, "^8Orbital Strike can only be used once per combat.")
            return { consumed = false }
        end
        combat.orbitalStrikeUsed = true
        local damage = math.max(1, 30 + strMod * 2 + dexMod * 2)
        enemy.hp = math.max(0, enemy.hp - damage)
        AddOrRefreshEffect(combat.enemyEffects, { type = "suppressed", remaining = 2, damageMult = 0.75 })
        AddOrRefreshEffect(combat.enemyEffects, { type = "poison", damage = 5, remaining = 3 })
        AddResultLog(game, "^3Orbital Strike^7 rains fire for " .. damage .. " damage! Enemy suppressed and burning.")
        return { actionType = "none", damage = damage, consumed = true }
    end

    -- Unknown ability
    AddResultLog(game, "^8Unknown ability: " .. abilityId)
    return { consumed = false }
end

-- Flashback echo abilities set (for Saevus whisper trigger)
local FLASHBACK_ABILITIES = {
    executioners_eye = true, unbreakable_will = true,
    cold_read = true, slippery_mind = true,
    killing_instinct = true, adaptive_tactics = true,
}

--- Check and fire flashback echo whisper after ability use
local function CheckFlashbackEcho(player, game, abilityId)
    if not FLASHBACK_ABILITIES[abilityId] then return end
    local flagKey = "flashback_used_" .. abilityId
    if game.flags[flagKey] then return end
    game.flags[flagKey] = true
    RPG.Combat.SaevusReact(player, game, "flashback_echo")
end

function RPG.Combat.StartCombat(player, enemyId)
    local game = RPG.GetGame(player)
    if not game then return false end
    if game.combat and game.combat.active then return false end

    local enemy = RPG.Data.GetEnemy and RPG.Data.GetEnemy(enemyId)
    if not enemy then
        player:SendPrint("^1Combat error:^7 Unknown enemy ID " .. tostring(enemyId))
        return false
    end
    enemy.hp = enemy.maxHP

    -- Reset dark power tracking for new combat
    game.player.darkPowerUsed = false

    game.combat = {
        active = true,
        round = 1,
        enemy = enemy,
        phase = "main",
        playerDefending = false,
        playerDamageBonus = 0,
        playerDefenseBonus = 0,
        enemyDamageBonus = 0,
        enemyBuffNextOnly = false,
        playerEffects = {},
        enemyEffects = {},
        darkAlignmentUsed = 0,
        absorbActive = false,
        enemyIntentKey = nil,
        enemyIntentText = nil,
        resultLog = {},
        survivalTurns = enemy.survivalTurns or nil,
        snapshot = {
            enemyId = enemyId,
            roomId = game.player.currentRoom,
            entryHP = game.player.hp,
            entryFP = game.player.fp,
            inventory = RPG.Util.DeepCopy(game.player.inventory),
            equipped = RPG.Util.DeepCopy(game.player.equipped),
            stats = RPG.Util.DeepCopy(game.player.stats),
            baseStats = RPG.Util.DeepCopy(game.player.baseStats),
        },
    }

    -- Stalker damage scaling: base + (level * scale), clamped to [floor, ceil]
    if enemy.survivalTurns and enemy.id == 12 then
        local level = game.player.level or 1
        local scaled = math.floor(RPG.Config.STALKER_DAMAGE_BASE + level * RPG.Config.STALKER_DAMAGE_SCALE)
        local lo = math.max(RPG.Config.STALKER_DAMAGE_MIN_FLOOR, scaled - 3)
        local hi = math.min(RPG.Config.STALKER_DAMAGE_MAX_CEIL, scaled + 3)
        game.combat.enemy.damageMin = lo
        game.combat.enemy.damageMax = hi
    end

    -- Initialize mimic mirror (Shadow Self)
    if enemy.mimicMirror then
        game.combat.mimicMirror = true
        game.combat.lastPlayerAction = nil
    end

    -- Initialize companion for this combat
    if RPG.Companion and RPG.Companion.OnCombatStart then
        RPG.Companion.OnCombatStart(game)
    end

    RPG.Util.BatchPrint(player, {
        "",
        "^1========================================",
        "^1COMBAT STARTED: " .. enemy.name,
        "^1========================================",
        "",
    })

    RPG.Combat.GenerateIntentHint(player, game)
    RPG.SetState(player, "combat")
    return true
end

function RPG.Combat.ApplyEffects(player, game)
    local combat = game.combat
    local p = game.player
    local enemy = combat.enemy

    for _, effectList in ipairs({ combat.playerEffects, combat.enemyEffects }) do
        for i = #effectList, 1, -1 do
            local effect = effectList[i]
            -- Apply per-round damage for poison
            if effect.type == "poison" and (effect.remaining or 0) > 0 then
                local damage = math.max(1, effect.damage or 1)
                if effectList == combat.playerEffects then
                    p.hp = math.max(0, p.hp - damage)
                    AddResultLog(game, "^1Poison^7 deals " .. damage .. " damage to you.")
                else
                    enemy.hp = math.max(0, enemy.hp - damage)
                    AddResultLog(game, "^2Poison^7 deals " .. damage .. " damage to " .. enemy.name .. ".")
                end
            end
            -- Tick down all timed effects EXCEPT stun (stun is manually managed)
            if effect.type ~= "stun" and (effect.remaining or 0) > 0 then
                effect.remaining = effect.remaining - 1
            end
        end
        RemoveExpiredEffects(effectList)
    end
end

local function ResolveEnemyDamage(game, baseDamage, ignoreHalfDefense)
    local combat = game.combat
    local dexMod = math.max(0, GetStatMod(game, "DEX"))
    local armorDefense = RPG.Combat.GetArmorDefense(game)
    local totalDefense = armorDefense + dexMod + (combat.playerDefenseBonus or 0)

    -- Unbreakable Will defense effect
    local willDef = HasEffect(combat.playerEffects, "will_defense")
    if willDef then
        totalDefense = totalDefense + (willDef.defense or 2)
    end

    -- Adaptive Tactics defense effect
    local adaptiveEff = HasEffect(combat.playerEffects, "adaptive")
    if adaptiveEff then
        totalDefense = totalDefense + (adaptiveEff.defense or 2)
    end

    -- Last Stand defense effect
    local lastStandEff = HasEffect(combat.playerEffects, "last_stand")
    if lastStandEff then
        totalDefense = totalDefense + (lastStandEff.defense or 4)
    end

    if ignoreHalfDefense then
        totalDefense = math.floor(totalDefense * 0.5)
    end

    local incoming = baseDamage
    if combat.playerDefending then
        incoming = math.floor(incoming * RPG.Config.DEFEND_MULTIPLIER + 0.5)
    end

    -- Suppressed effect: reduce enemy damage
    local suppressed = HasEffect(combat.enemyEffects, "suppressed")
    if suppressed then
        incoming = math.floor(incoming * (suppressed.damageMult or 0.75))
    end

    return math.max(1, incoming - totalDefense)
end

-- Route enemy damage to player or companion (companion intercepts ~28%)
-- Status effects (poison, stun, bleed) still apply to PLAYER even when damage redirects
-- Sets combat.lastEnemyHitCompanion so counter logic can check who was actually hit
local function ApplyDamageToTarget(player, game, dealt)
    game.combat.lastEnemyHitCompanion = false
    if RPG.Companion and RPG.Companion.ResolveEnemyTarget then
        local target = RPG.Companion.ResolveEnemyTarget(game)
        if target == "companion" then
            game.combat.lastEnemyHitCompanion = true
            RPG.Companion.TakeDamage(player, game, dealt)
            return
        end
    end
    game.player.hp = math.max(0, game.player.hp - dealt)
end

local function PickEnemySpecial(enemy)
    if not enemy.specials then return nil end
    local list = {}
    local totalWeight = 0
    for _, special in pairs(enemy.specials) do
        local w = special.weight or 1
        list[#list + 1] = special
        totalWeight = totalWeight + w
    end
    if #list == 0 or totalWeight <= 0 then return nil end
    if #list == 1 then return list[1] end
    local roll = math.random(1, totalWeight)
    local acc = 0
    for _, special in ipairs(list) do
        acc = acc + (special.weight or 1)
        if roll <= acc then return special end
    end
    return list[#list]
end

function RPG.Combat.ResolveEnemyAction(player, game, forcedAction)
    local combat = game.combat
    local enemy = combat.enemy
    local p = game.player

    -- Stalker auto-heal to full at start of its turn (visual unkillability)
    if enemy.survivalTurns and enemy.id == 12 then
        enemy.hp = enemy.maxHP
    end

    local stun = HasEffect(combat.enemyEffects, "stun")
    if stun then
        AddResultLog(game, "^3" .. enemy.name .. " is stunned and cannot act.")
        stun.remaining = (stun.remaining or 1) - 1
        RemoveExpiredEffects(combat.enemyEffects)
        return { actionType = "stunned", damage = 0 }
    end

    local action = forcedAction
    if not action then
        local followIntent = combat.enemyIntentKey and RollPercent(RPG.Config.INTENT_ACCURACY)
        if followIntent then
            action = combat.enemyIntentKey
        else
            action = ChooseWeightedAction(enemy.behavior)
        end
    end

    -- Mimic mirror: Shadow Self copies player's last action ~80% of the time
    if combat.mimicMirror and combat.lastPlayerAction then
        if math.random(100) <= RPG.Config.MIMIC_MIRROR_CHANCE then
            action = combat.lastPlayerAction
            AddResultLog(game, "^3The Shadow mirrors your last move!")
        end
    end

    if action == "defend" then
        local heal = math.random(4, 8)
        local before = enemy.hp
        enemy.hp = math.min(enemy.maxHP, enemy.hp + heal)
        AddResultLog(game, enemy.name .. " regains " .. (enemy.hp - before) .. " HP.")
        return { actionType = "defend", damage = 0 }
    end

    if action == "special" then
        -- Slippery Mind: 50% chance to avoid enemy special
        if combat.slipperyMindActive then
            if RollPercent(50) then
                combat.slipperyMindActive = false
                AddResultLog(game, "^5You slip away from the attack at the last moment!")
                return { actionType = "special_avoided", damage = 0 }
            end
            combat.slipperyMindActive = false
        end

        local special = PickEnemySpecial(enemy)
        if special and RollPercent(special.chance or 100) then
            local kind = special.kind or "damage"

            -- Heal special: enemy recovers HP
            if kind == "heal" then
                local healAmt = special.healAmount or 10
                local before = enemy.hp
                enemy.hp = math.min(enemy.maxHP, enemy.hp + healAmt)
                AddResultLog(game, "^3" .. enemy.name .. " " .. special.name .. ", recovering " .. (enemy.hp - before) .. " HP.")
                return { actionType = "special", damage = 0 }
            end

            -- Buff special: boost next attack damage
            if kind == "buff" then
                combat.enemyDamageBonus = (combat.enemyDamageBonus or 0) + (special.damageBonus or 0)
                combat.enemyBuffNextOnly = (special.nextAttackOnly ~= false)
                AddResultLog(game, "^3" .. enemy.name .. " " .. special.name .. "!")
                return { actionType = "special", damage = 0 }
            end

            -- Default: damage special
            local baseDamage = special.baseDamage or math.random(enemy.damageMin, enemy.damageMax)
            local dealt = ResolveEnemyDamage(game, baseDamage, special.ignoreHalfDefense)
            ApplyDamageToTarget(player, game, dealt)
            AddResultLog(game, "^1" .. enemy.name .. " uses " .. special.name .. " for " .. dealt .. " damage.")

            if special.poisonDamage and special.poisonRounds then
                AddOrRefreshEffect(combat.playerEffects, {
                    type = "poison",
                    damage = special.poisonDamage,
                    remaining = special.poisonRounds,
                })
                AddResultLog(game, "^1You are poisoned!")
            end

            if special.stunRounds and special.stunRounds > 0 then
                local immune = HasEffect(combat.playerEffects, "stun_immune")
                if immune then
                    immune.remaining = 0
                    RemoveExpiredEffects(combat.playerEffects)
                    AddResultLog(game, "^5Unbreakable Will resists the stun!")
                else
                    AddOrRefreshEffect(combat.playerEffects, {
                        type = "stun",
                        remaining = special.stunRounds,
                    })
                    AddResultLog(game, "^1You are stunned!")
                end
            end

            if special.bleedDamage and special.bleedRounds then
                AddOrRefreshEffect(combat.playerEffects, {
                    type = "poison",
                    damage = special.bleedDamage,
                    remaining = special.bleedRounds,
                })
                AddResultLog(game, "^1You are bleeding!")
            end

            if special.paranoia and special.paranoia > 0 and RPG.AddParanoia then
                RPG.AddParanoia(player, special.paranoia)
                AddResultLog(game, "^1Your sense of self wavers...")
            end

            -- Stat drain (Fragment bosses + Shadow Self)
            if special.statDrain and special.statDrainAmount then
                local stat = special.statDrain
                local amt = special.statDrainAmount
                local base = game.player.baseStats[stat]
                if base and base > 1 then
                    game.player.baseStats[stat] = base - amt
                    game.fragmentDrain = game.fragmentDrain or {}
                    game.fragmentDrain[stat] = (game.fragmentDrain[stat] or 0) + amt
                    RPG.RecalcEffectiveStats(game)
                    AddResultLog(game, "^1Your " .. stat .. " fractures! (-" .. amt .. ")")
                end
            end

            return { actionType = "special", damage = dealt }
        end
        -- Special chance failed -- fall through to normal attack
    end

    -- Normal attack (+ enemy damage bonus from buffs)
    local baseDamage = math.random(enemy.damageMin, enemy.damageMax) + (combat.enemyDamageBonus or 0)
    if combat.enemyBuffNextOnly and (combat.enemyDamageBonus or 0) > 0 then
        AddResultLog(game, "^3" .. enemy.name .. "'s attack is empowered!")
    end
    combat.enemyDamageBonus = 0
    combat.enemyBuffNextOnly = false
    local dealt = ResolveEnemyDamage(game, baseDamage, false)
    ApplyDamageToTarget(player, game, dealt)
    AddResultLog(game, "^1" .. enemy.name .. " hits for " .. dealt .. " damage.")
    return { actionType = "attack", damage = dealt }
end

function RPG.Combat.ResolvePlayerAction(player, game, action)
    local combat = game.combat
    local p = game.player
    local enemy = combat.enemy

    -- Mimic mirror: track player action for Shadow Self to copy
    if combat.mimicMirror then
        if action == "attack" or action == "defend" then
            combat.lastPlayerAction = action
        elseif action and (action:find("^force:") or action:find("^ability:")) then
            combat.lastPlayerAction = "special"
        end
        -- Items/flee: don't set lastPlayerAction (breaks the pattern)
    end

    -- Reset consecutive defend counter on non-defend action
    if action ~= "defend" then
        combat.consecutiveDefends = 0
    end

    if action == "attack" then
        local hitChance = Clamp(
            RPG.Config.BASE_HIT_CHANCE + (GetStatMod(game, "DEX") * RPG.Config.HIT_DEX_BONUS),
            5,
            95
        )
        if not RollPercent(hitChance) then
            AddResultLog(game, "^8You miss.")
            combat.playerDamageBonus = 0
            return { actionType = "attack", damage = 0, consumed = true }
        end

        local rawDamage = RPG.Combat.GetWeaponDamage(game) + GetStatMod(game, "STR") + (combat.playerDamageBonus or 0) + math.random(-2, 2)
        combat.playerDamageBonus = 0

        -- Battle Meditation passive: +2 base damage
        if p.abilitiesKnown.battle_meditation then
            rawDamage = rawDamage + 2
        end

        -- Fury effect: +5 damage
        local furyEff = HasEffect(combat.playerEffects, "fury")
        if furyEff then
            rawDamage = rawDamage + (furyEff.damage or 5)
        end

        -- Adaptive Tactics: +3 damage
        local adaptiveEff = HasEffect(combat.playerEffects, "adaptive")
        if adaptiveEff then
            rawDamage = rawDamage + (adaptiveEff.damage or 3)
        end

        -- Last Stand: +6 damage
        local lastStandEff = HasEffect(combat.playerEffects, "last_stand")
        if lastStandEff then
            rawDamage = rawDamage + (lastStandEff.damage or 6)
        end

        local finalDamage
        -- Cold Read: ignore 50% of enemy defense on this attack
        if combat.coldReadActive then
            combat.coldReadActive = false
            local reducedDefense = math.floor((enemy.defense or 0) * 0.5)
            finalDamage = math.max(1, rawDamage - reducedDefense)
        else
            finalDamage = math.max(1, rawDamage - (enemy.defense or 0))
        end

        local critChance = Clamp(
            RPG.Config.CRIT_CHANCE + (GetStatMod(game, "DEX") * RPG.Config.CRIT_DEX_BONUS),
            0,
            60
        )
        local isCrit = false
        if RollPercent(critChance) then
            isCrit = true
            finalDamage = math.max(1, math.floor(finalDamage * RPG.Config.CRIT_MULTIPLIER + 0.5))
            AddResultLog(game, "^3CRITICAL HIT!")
        end

        if combat.survivalTurns and combat.enemy.id == 12 then
            -- Stalker: apply damage then immediately heal to full
            enemy.hp = math.max(0, enemy.hp - finalDamage)
            enemy.hp = enemy.maxHP  -- instant regeneration
            local narr = RPG.Config.STALKER_HIT_NARRATION
            AddResultLog(game, narr[math.random(1, #narr)])
        else
            enemy.hp = math.max(0, enemy.hp - finalDamage)
            AddResultLog(game, "^2You strike for " .. finalDamage .. " damage.")
        end

        -- Battle Meditation: Fury proc at <30% HP (once per combat)
        if p.abilitiesKnown.battle_meditation and not combat.furyTriggered
            and p.hp < math.floor(p.maxHP * 0.3) and p.hp > 0 then
            combat.furyTriggered = true
            AddOrRefreshEffect(combat.playerEffects, { type = "fury", remaining = 2, damage = 5 })
            AddResultLog(game, "^1[FURY] The Force surges through your blade! (+5 damage for 2 rounds)")
        end

        return { actionType = "attack", damage = finalDamage, consumed = true, crit = isCrit }
    end

    if action == "defend" then
        if combat.stalkerAntiDefend then
            AddResultLog(game, "^1The Stalker reaches into your mind. You can't focus enough to defend!")
            combat.consecutiveDefends = 0
            return { actionType = "defend_broken", damage = 0, consumed = true }
        end
        combat.playerDefending = true
        combat.consecutiveDefends = (combat.consecutiveDefends or 0) + 1
        AddResultLog(game, "^7You brace and prepare to defend.")
        if combat.consecutiveDefends >= 3 then
            RPG.Combat.SaevusReact(player, game, "repeated_defend")
        end
        return { actionType = "defend", damage = 0, consumed = true }
    end

    if action == "flee" then
        local fleeChance = Clamp(
            RPG.Config.FLEE_CHANCE + (GetStatMod(game, "DEX") * RPG.Config.FLEE_DEX_BONUS),
            5,
            95
        )
        if RollPercent(fleeChance) then
            AddResultLog(game, "^3You successfully flee.")
            RPG.Combat.EndCombat(player, game, "fled")
            return { actionType = "flee", damage = 0, consumed = true, ended = true }
        end
        AddResultLog(game, "^1You fail to escape!")
        RPG.Combat.SaevusReact(player, game, "flee")
        return { actionType = "flee", damage = 0, consumed = true, enemyFreeAttack = true }
    end

    if string.StartsWith(action, "force:") then
        local abilityId = action:sub(#"force:" + 1)
        local abilityDef = RPG.Data.Abilities and RPG.Data.Abilities[abilityId]
        if not abilityDef then
            return { consumed = false }
        end
        if not p.abilitiesKnown[abilityId] then
            AddResultLog(game, "^1You don't know that power.")
            return { consumed = false }
        end
        local fpCost = abilityDef.fp or 0
        -- Force Attunement: -2 FP cost (minimum 5)
        if p.abilitiesKnown.force_attunement and fpCost > 0 then
            fpCost = math.max(5, fpCost - 2)
        end
        if p.fp < fpCost then
            AddResultLog(game, "^8Not enough FP.")
            return { consumed = false }
        end
        p.fp = p.fp - fpCost
        local result = RPG.Combat.ResolveAbility(player, game, abilityId)
        if result and result.consumed then CheckFlashbackEcho(player, game, abilityId) end
        return result
    end

    if string.StartsWith(action, "ability:") then
        local abilityId = action:sub(#"ability:" + 1)
        if not p.abilitiesKnown[abilityId] then
            AddResultLog(game, "^1You don't know that ability.")
            return { consumed = false }
        end
        local result = RPG.Combat.ResolveAbility(player, game, abilityId)
        if result and result.consumed then CheckFlashbackEcho(player, game, abilityId) end
        return result
    end

    if string.StartsWith(action, "item:") then
        local invIndex = tonumber(action:sub(#"item:" + 1))
        if not invIndex then
            return { consumed = false }
        end

        local itemId = p.inventory[invIndex]
        if not itemId then
            return { consumed = false }
        end
        local itemDef = RPG.Data.Items[itemId]
        if not itemDef or not itemDef.usableInCombat then
            AddResultLog(game, "^8That item cannot be used in combat.")
            return { consumed = false }
        end

        if itemDef.healAmount and itemDef.healAmount > 0 then
            local before = p.hp
            p.hp = math.min(p.maxHP, p.hp + itemDef.healAmount)
            table.remove(p.inventory, invIndex)
            AddResultLog(game, "^5" .. itemDef.name .. "^7 restores " .. (p.hp - before) .. " HP.")
            if itemDef.paranoia and RPG.AddParanoia then
                RPG.AddParanoia(player, itemDef.paranoia)
                AddResultLog(game, "^1Side effects... your mind feels clouded.")
            end
            return { actionType = "none", damage = 0, consumed = true }
        end

        if itemDef.curePoison then
            for i = #combat.playerEffects, 1, -1 do
                if combat.playerEffects[i].type == "poison" then
                    table.remove(combat.playerEffects, i)
                end
            end
            table.remove(p.inventory, invIndex)
            AddResultLog(game, "^5" .. itemDef.name .. "^7 cures your poison.")
            return { actionType = "none", damage = 0, consumed = true }
        end

        if itemDef.damageBonus then
            combat.playerDamageBonus = itemDef.damageBonus  -- flat set, does not stack
            table.remove(p.inventory, invIndex)
            AddResultLog(game, "^5" .. itemDef.name .. "^7 boosts your next attack.")
            return { actionType = "none", damage = 0, consumed = true }
        end

        if itemDef.applyPoison then
            AddOrRefreshEffect(combat.enemyEffects, {
                type = "poison",
                damage = itemDef.applyPoison.damage,
                remaining = itemDef.applyPoison.rounds,
            })
            table.remove(p.inventory, invIndex)
            AddResultLog(game, "^5" .. itemDef.name .. "^7 poisons the enemy!")
            return { actionType = "none", damage = 0, consumed = true }
        end

        return { consumed = false }
    end

    return { consumed = false }
end

function RPG.Combat.EndCombat(player, game, outcome)
    local combat = game.combat
    if not combat or not combat.active then
        return false
    end

    local enemy = combat.enemy
    combat.active = false

    if outcome == "victory" then
        local room = game.rooms[game.player.currentRoom]
        if room then
            room.encounterDefeated = true
        end

        local xp = enemy.xpReward or 0
        -- First-clear-only enemies: skip XP on repeat kills
        if enemy.firstClearOnly then
            local clearFlag = "enemy_" .. enemy.id .. "_cleared"
            if game.flags[clearFlag] then
                xp = 0
            else
                game.flags[clearFlag] = true
            end
        end
        local credits = enemy.creditReward or 0
        game.player.xp = game.player.xp + xp
        game.player.credits = game.player.credits + credits

        RPG.Util.BatchPrint(player, {
            "",
            "^2Victory!^7 " .. enemy.name .. " defeated.",
            "^2+" .. xp .. " XP^7  ^3+" .. credits .. " credits^7",
        })
        local _, lootNames = ResolveLootDrops(player, game)
        local levelBefore = game.player.level
        RPG.Combat.CheckLevelUp(player, game)
        local didLevelUp = game.player.level > levelBefore

        -- Restore drained stats for ANY enemy with drainStat (fragments + shadow self)
        if enemy.drainStat and game.fragmentDrain then
            local stat = enemy.drainStat
            if game.fragmentDrain[stat] then
                local restored = game.fragmentDrain[stat]
                game.player.baseStats[stat] = (game.player.baseStats[stat] or 1) + restored
                game.fragmentDrain[stat] = nil
                RPG.RecalcEffectiveStats(game)
                player:SendPrint("^2[Your " .. stat .. " is restored! (+" .. restored .. ")]")
            end
        end

        -- Fragment-specific flavor
        if enemy.fragmentType then
            player:SendPrint("^8[The fragment dissolves. A piece of yourself returns.]")
            game.flags["fragment_" .. enemy.fragmentType .. "_defeated"] = true
        end

        -- Shadow Self victory
        if enemy.shadowSelf then
            player:SendPrint("^8The Shadow shatters into light. The path forward is clear.")
            game.flags["shadow_self_defeated"] = true
        end

        -- Nemesis victory: advance encounter, open post-combat dialogue
        if enemy.nemesisEncounter and RPG.Nemesis and RPG.Nemesis.OnCombatEnd then
            RPG.Nemesis.OnCombatEnd(player, game, outcome, enemy)
            -- Open post-combat dialogue (spared/kill choice)
            local postNodes = { [1] = 6, [2] = 27, [3] = 39 }
            local postNode = postNodes[enemy.nemesisEncounter]
            if postNode then
                game.victoryData = {
                    enemyName = enemy.name,
                    deathText = enemy.deathText,
                    xp = enemy.xpReward or 0,
                    credits = enemy.creditReward or 0,
                    loot = {},
                    levelUp = false,
                    newLevel = game.player.level,
                }
                game.combat = { active = false }
                -- Defer dialogue to avoid same-frame collision
                local cn = player:GetClientNum()
                Timer.Simple("rpg_nemesis_postcombat_" .. cn, 1500, function()
                    local p = Player.Get(cn)
                    if not p or not p:IsValid() then return end
                    local g = RPG.GetGame(p)
                    if not g then return end
                    g.dialogue = { active = true, npcId = 30, currentNode = postNode, textPage = 1, appliedNodes = {} }
                    RPG.SetState(p, "dialogue")
                end)
                return true
            end
        end

        -- Fire quest event for combat victory
        if RPG.Quest and RPG.Quest.OnEvent then
            RPG.Quest.OnEvent(player, "combat_win", { enemyId = enemy.id })
        end

        -- Saevus whisper on combat victory
        if RPG.Whisper and RPG.Whisper.Check then
            RPG.Whisper.Check(player, game, "combat_win", { enemyId = enemy.id })
        end

        -- Saevus combat whispers: near-death victory, first kill, restraint
        local whispered = false
        -- Near-death victory: HP < 20% maxHP
        if not whispered and game.player.hp < math.floor(game.player.maxHP * 0.2) then
            whispered = RPG.Combat.SaevusReact(player, game, "near_death_victory", { useBatchPrint = true })
        end
        -- First kill of enemy type
        if not whispered then
            local killFlag = "killed_enemy_" .. enemy.id
            if not game.flags[killFlag] then
                game.flags[killFlag] = true
                whispered = RPG.Combat.SaevusReact(player, game, "first_kill", { useBatchPrint = true })
            end
        end
        -- Restraint: clean victory with HP > 80% maxHP
        if not whispered and game.player.hp > math.floor(game.player.maxHP * 0.8) then
            RPG.Combat.SaevusReact(player, game, "restraint", { useBatchPrint = true })
        end

        -- Build victory data and show combat result screen
        game.victoryData = {
            enemyName = enemy.name,
            deathText = enemy.deathText,
            xp = xp,
            credits = credits,
            loot = lootNames or {},
            levelUp = didLevelUp,
            newLevel = game.player.level,
        }
        if RPG.Companion and RPG.Companion.OnCombatEnd then
            RPG.Companion.OnCombatEnd(player, game, outcome)
        end
        game.combat = { active = false }
        RPG.SetState(player, "combat_result")

        -- Auto-close timer (3 seconds)
        local cn = player:GetClientNum()
        Timer.Create("rpg_combat_result_" .. cn, 5000, 1, function()
            local p = Player.Get(cn)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if g and g.state == "combat_result" then
                RPG.SetState(p, "exploration")
            end
        end)
        return true
    elseif outcome == "defeat" then
        -- Nemesis defeat handler: nemesis doesn't kill, takes penalty instead
        if enemy.nemesisEncounter and RPG.Nemesis and RPG.Nemesis.OnCombatEnd then
            local handled = RPG.Nemesis.OnCombatEnd(player, game, outcome, enemy)
            if handled then
                if RPG.Companion and RPG.Companion.OnCombatEnd then
                    RPG.Companion.OnCombatEnd(player, game, "defeat")
                end
                game.combat = { active = false }
                RPG.SetState(player, "exploration")
                return true
            end
        end

        -- Fire quest event for combat loss
        if RPG.Quest and RPG.Quest.OnEvent then
            RPG.Quest.OnEvent(player, "combat_loss", { enemyId = enemy.id })
        end

        -- Saevus whisper on combat defeat
        if RPG.Whisper and RPG.Whisper.Check then
            RPG.Whisper.Check(player, game, "combat_loss", { enemyId = enemy.id })
        end
        if RPG.Companion and RPG.Companion.OnCombatEnd then
            RPG.Companion.OnCombatEnd(player, game, "defeat")
        end
        game.deathSnapshot = RPG.Util.DeepCopy(game.combat.snapshot)
        game.combat = { active = false }
        RPG.Util.BatchPrint(player, {
            "",
            "^1You collapse... darkness closes in.",
            "",
        })
        RPG.SetState(player, "game_over")
        return true
    elseif outcome == "survived" then
        RPG.Util.BatchPrint(player, {
            "",
            "^3========================================",
            "^3SURVIVED.",
            "^3========================================",
            "^3The Stalker laughs — a hollow, broken sound.",
            "^5\"The Holocron wants you alive. For now.\"",
            "^3They fade into smoke.",
            "",
            "^8[You feel the Stalker's presence recede... but they will return.]",
            "",
        })

        -- Fire quest event as combat_win (for quest tracking)
        if RPG.Quest and RPG.Quest.OnEvent then
            RPG.Quest.OnEvent(player, "combat_win", { enemyId = enemy.id })
        end

        -- Notify stalker system
        if RPG.Stalker and RPG.Stalker.OnSurvived then
            RPG.Stalker.OnSurvived(player, game)
        end
    elseif outcome == "fled" then
        player:SendPrint("^3You retreat from combat.")
        if RPG.Quest and RPG.Quest.OnEvent then
            RPG.Quest.OnEvent(player, "combat_fled", { enemyId = enemy.id })
        end
        if enemy.id == 12 and RPG.Stalker and RPG.Stalker.OnFled then
            RPG.Stalker.OnFled(player, game)
        end
    end

    if RPG.Companion and RPG.Companion.OnCombatEnd then
        RPG.Companion.OnCombatEnd(player, game, outcome)
    end

    game.combat = { active = false }
    RPG.SetState(player, "exploration")
    return true
end

function RPG.Combat.ResolveTurn(player, action)
    local game = RPG.GetGame(player)
    if not game or not game.combat or not game.combat.active then
        return false
    end

    local combat = game.combat
    combat.phase = "main"
    combat.resultLog = {}

    -- Step 1: Reset per-turn state
    combat.playerDefending = false
    combat.playerDefenseBonus = 0
    combat.companionDefending = false

    -- Stalker phased escalation
    if combat.survivalTurns and combat.enemy.id == 12 then
        local roundText = RPG.Config.STALKER_ROUND_TEXT[combat.round]
        if roundText then
            AddResultLog(game, roundText)
        end
        -- Round 3: fear spike — paranoia pulse
        if combat.round == 3 and RPG.AddParanoia then
            RPG.AddParanoia(player, 2)
            AddResultLog(game, "^1[Your composure cracks. Paranoia rises.]")
        end
        -- Round 4: anti-defend — strips defending status THIS round only
        if combat.round == 4 then
            combat.stalkerAntiDefend = true
        else
            combat.stalkerAntiDefend = false
        end
    end

    -- Corrupted equipment paranoia tick
    if game.player.equipped and game.player.equipped.weapon then
        local weaponDef = RPG.Data.Items[game.player.equipped.weapon]
        if weaponDef and weaponDef.paranoia and weaponDef.paranoia > 0 then
            local oldP = game.player.paranoia
            RPG.AddParanoia(player, weaponDef.paranoia)
            if game.player.paranoia > oldP then
                AddResultLog(game, "^1[The blade whispers...]")
            end
        end
    end

    -- Step 2: Apply tick effects (poison etc.)
    RPG.Combat.ApplyEffects(player, game)
    if game.player.hp <= 0 then
        RPG.Combat.EndCombat(player, game, "defeat")
        return true
    end
    if combat.enemy.hp <= 0 then
        RPG.Combat.EndCombat(player, game, "victory")
        return true
    end

    -- Step 3: Check player stun
    local playerResult
    local playerStun = HasEffect(combat.playerEffects, "stun")
    if playerStun then
        AddResultLog(game, "^3You are stunned and cannot act!")
        playerStun.remaining = (playerStun.remaining or 1) - 1
        RemoveExpiredEffects(combat.playerEffects)
        playerResult = { actionType = "stunned", damage = 0, consumed = true }
    else
        -- Step 4: Resolve player action
        playerResult = RPG.Combat.ResolvePlayerAction(player, game, action)
        if not playerResult or not playerResult.consumed then
            return false
        end
        if playerResult.ended then
            return true
        end
    end

    -- Step 5: Death check (enemy killed by player)
    if combat.enemy.hp <= 0 then
        RPG.Combat.EndCombat(player, game, "victory")
        return true
    end

    -- Step 5.5: Companion turn
    if RPG.Companion and RPG.Companion.ResolveCombatTurn then
        RPG.Companion.ResolveCombatTurn(player, game)
        if combat.enemy.hp <= 0 then
            RPG.Combat.EndCombat(player, game, "victory")
            return true
        end
    end

    -- Step 6: Resolve enemy action
    local enemyResult
    if playerResult.enemyFreeAttack then
        AddResultLog(game, "^1The enemy gets a free strike!")
        enemyResult = RPG.Combat.ResolveEnemyAction(player, game, "attack")
    else
        enemyResult = RPG.Combat.ResolveEnemyAction(player, game)
    end
    enemyResult = enemyResult or { actionType = "none", damage = 0 }

    -- Step 7: Post-round counter bonuses
    local pAction = playerResult.actionType or "none"
    local eAction = enemyResult.actionType or "none"

    -- Defend counter: player defended + enemy attacked -> riposte + heal
    -- Heal only if the player was actually hit (not when damage went to companion)
    if pAction == "defend" and eAction == "attack" then
        local riposte = RPG.Config.COUNTER_RIPOSTE_DAMAGE
        combat.enemy.hp = math.max(0, combat.enemy.hp - riposte)
        local healAmt = 0
        if not combat.lastEnemyHitCompanion then
            healAmt = math.floor((enemyResult.damage or 0) * RPG.Config.COUNTER_DEFEND_HEAL_PERCENT)
            if healAmt > 0 then
                game.player.hp = math.min(game.player.maxHP, game.player.hp + healAmt)
            end
        end
        AddResultLog(game, "^3[COUNTER]^7 Perfect read! Riposte " .. riposte .. " dmg" .. (healAmt > 0 and (", recover " .. healAmt .. " HP.") or "."))
    end

    -- Attack counter: player attacked + enemy used special -> bonus 30% damage
    if pAction == "attack" and eAction == "special" and (playerResult.damage or 0) > 0 then
        local bonus = math.max(1, math.floor((playerResult.damage or 0) * RPG.Config.COUNTER_ATTACK_VS_SPECIAL))
        combat.enemy.hp = math.max(0, combat.enemy.hp - bonus)
        AddResultLog(game, "^3[COUNTER]^7 You exploit the opening! Bonus " .. bonus .. " damage.")
    end

    -- Attack counter: player attacked + enemy defended -> bonus 20% damage
    if pAction == "attack" and eAction == "defend" and (playerResult.damage or 0) > 0 then
        local bonus = math.max(1, math.floor((playerResult.damage or 0) * RPG.Config.COUNTER_ATTACK_VS_DEFEND))
        combat.enemy.hp = math.max(0, combat.enemy.hp - bonus)
        AddResultLog(game, "^3[COUNTER]^7 You exploit the opening! Bonus " .. bonus .. " damage.")
    end

    -- Force Absorb: if enemy used special while absorb was active, heal 20 HP + recover 10 FP
    if combat.absorbActive and eAction == "special" then
        game.player.hp = math.min(game.player.maxHP, game.player.hp + 20)
        game.player.fp = math.min(game.player.maxFP, game.player.fp + 10)
        AddResultLog(game, "^5Force Absorb^7 converts the enemy's power: +20 HP, +10 FP.")
    end
    combat.absorbActive = false

    -- Step 8: Death checks
    if game.player.hp <= 0 then
        RPG.Combat.EndCombat(player, game, "defeat")
        return true
    end
    if combat.enemy.hp <= 0 then
        RPG.Combat.EndCombat(player, game, "victory")
        return true
    end

    -- Send round results to console for persistent history
    for _, logLine in ipairs(combat.resultLog) do
        player:SendPrint(logLine)
    end

    -- Step 9: Check survival combat (endure X rounds = survived)
    if combat.survivalTurns and combat.round >= combat.survivalTurns then
        RPG.Combat.EndCombat(player, game, "survived")
        return true
    end

    combat.round = combat.round + 1
    RPG.Combat.GenerateIntentHint(player, game)

    -- Flash effect: determine type based on turn outcome (priority: enemy_hit > crit > miss)
    combat.flashTick = nil
    combat.flashType = nil
    if enemyResult and (enemyResult.damage or 0) > 0 and enemyResult.actionType ~= "defend" then
        combat.flashType = "enemy_hit"
    elseif playerResult.crit then
        combat.flashType = "player_crit"
    elseif (playerResult.actionType or "none") == "attack" and (playerResult.damage or 0) == 0 then
        combat.flashType = "player_miss"
    end
    if not combat.flashType and enemyResult and enemyResult.actionType == "defend" then
        combat.flashType = "enemy_heal"
    end

    if combat.flashType then
        combat.flashTick = 0
        local gid = player:GetClientNum()
        Timer.Create("rpg_flash_" .. gid, 400, 2, function()
            local p = Player.Get(gid)
            if not p then return end
            local g = RPG.GetGame(p)
            if not g or not g.combat or not g.combat.active then return end
            if g.state ~= "combat" then return end
            g.combat.flashTick = (g.combat.flashTick or 0) + 1
            if Menu and Menu.Render then Menu.Render(p, true) end
        end)
    end

    return true
end

return true
