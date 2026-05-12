-- Echoes of the Dark Wars - Companion System
-- AI-controlled combat, room commentary, paranoia management

RPG = RPG or {}
RPG.Companion = {}

-- ============================================
-- HELPERS
-- ============================================

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

local function PickRandom(tbl)
    if not tbl or #tbl == 0 then return nil end
    return tbl[math.random(#tbl)]
end

-- ============================================
-- RECRUITMENT
-- ============================================

function RPG.Companion.Recruit(player, companionId, isBlackmailed)
    local game = RPG.GetGame(player)
    if not game then return false end

    local def = RPG.Data.GetCompanion(companionId)
    if not def then
        GLua.Warn("RPG.Companion.Recruit: Unknown companion '" .. tostring(companionId) .. "'")
        return false
    end

    local level = game.player.level or 1
    local maxHP = def.baseHP + (level - 1) * def.hpPerLevel

    game.player.companions[companionId] = {
        id = companionId,
        hp = maxHP,
        maxHP = maxHP,
        fp = 0,
        maxFP = 0,
        trust = isBlackmailed and "blackmailed" or "normal",
        ko = false,
    }
    game.player.activeCompanion = companionId

    return true
end

function RPG.Companion.GetActive(game)
    if not game or not game.player then return nil, nil end
    local compId = game.player.activeCompanion
    if not compId then return nil, nil end
    local comp = game.player.companions[compId]
    if not comp then return nil, nil end
    local def = RPG.Data.GetCompanion(compId)
    if not def then return nil, nil end
    return comp, def
end

function RPG.Companion.IsBlackmailed(companion)
    return companion and companion.trust == "blackmailed"
end

-- ============================================
-- COMBAT AI
-- ============================================

function RPG.Companion.ChooseAction(behavior)
    local attackW = behavior.attack or 0
    local specialW = behavior.special or 0
    local defendW = behavior.defend or 0
    local total = attackW + specialW + defendW
    if total <= 0 then return "attack" end

    local roll = math.random(1, total)
    if roll <= attackW then return "attack" end
    if roll <= (attackW + specialW) then return "special" end
    return "defend"
end

function RPG.Companion.ResolveAttack(player, game, comp, def)
    local hitChance = def.baseHitChance
    local isBlack = RPG.Companion.IsBlackmailed(comp)
    if isBlack then
        hitChance = hitChance - def.blackmailHitPenalty
    end

    -- Sabotage miss (blackmailed only)
    if isBlack and RollPercent(def.sabotageMissChance) then
        local quip = PickRandom(def.quips.onMissBlackmail) or ""
        RPG.Combat.Log(game, "^8Atton's shot goes wide. " .. quip)
        return
    end

    if not RollPercent(hitChance) then
        local pool = isBlack and def.quips.onMissBlackmail or def.quips.onMiss
        local quip = PickRandom(pool) or ""
        RPG.Combat.Log(game, "^8" .. def.name .. " misses. " .. quip)
        return
    end

    local level = game.player.level or 1
    local baseDmg = math.random(def.damageMin, def.damageMax) + math.floor(level / 2)
    if isBlack then
        baseDmg = math.floor(baseDmg * 0.75)
    end

    local enemyDef = game.combat.enemy.defense or 0
    local dealt = math.max(1, baseDmg - enemyDef)
    game.combat.enemy.hp = math.max(0, game.combat.enemy.hp - dealt)

    local pool = isBlack and def.quips.onAttackBlackmail or def.quips.onAttack
    local quip = PickRandom(pool) or ""
    RPG.Combat.Log(game, "^2" .. def.name .. " strikes for " .. dealt .. " damage. " .. quip)

    if game.combat.enemy.hp <= 0 then
        local killQuip = PickRandom(def.quips.onEnemyKill) or ""
        if killQuip ~= "" then
            RPG.Combat.Log(game, "^2" .. killQuip)
        end
    end
end

function RPG.Companion.ResolveSpecial(player, game, comp, def)
    local isBlack = RPG.Companion.IsBlackmailed(comp)

    -- Sabotage miss (blackmailed only)
    if isBlack and RollPercent(def.sabotageMissChance) then
        RPG.Combat.Log(game, "^8" .. def.name .. " fumbles the attack.")
        return
    end

    -- Pick a random ability weighted by chance
    local totalChance = 0
    for _, ability in ipairs(def.abilities) do
        totalChance = totalChance + (ability.chance or 0)
    end
    if totalChance <= 0 then
        RPG.Companion.ResolveAttack(player, game, comp, def)
        return
    end

    local roll = math.random(1, totalChance)
    local acc = 0
    local picked = def.abilities[1]
    for _, ability in ipairs(def.abilities) do
        acc = acc + (ability.chance or 0)
        if roll <= acc then
            picked = ability
            break
        end
    end

    local quip = isBlack and picked.blackmailQuip or picked.quip or ""

    -- Cover Fire: defense buff for player
    if picked.effect == "player_defense" then
        game.combat.playerDefenseBonus = (game.combat.playerDefenseBonus or 0) + (picked.defenseBonus or 4)
        RPG.Combat.Log(game, "^3" .. def.name .. " uses " .. picked.name .. "! " .. quip)
        return
    end

    -- Damage-dealing abilities
    local level = game.player.level or 1
    local baseDmg = (picked.damage or 0) + math.floor(level / 2)
    if isBlack then
        baseDmg = math.floor(baseDmg * 0.75)
    end

    local enemyDefense = game.combat.enemy.defense or 0
    local dealt = math.max(1, baseDmg - enemyDefense)
    game.combat.enemy.hp = math.max(0, game.combat.enemy.hp - dealt)
    RPG.Combat.Log(game, "^3" .. def.name .. " uses " .. picked.name .. " for " .. dealt .. " damage! " .. quip)

    -- Stun effect
    if picked.effect == "stun" and picked.stunChance then
        if RollPercent(picked.stunChance) then
            RPG.Combat.AddEnemyEffect(game, {
                type = "stun",
                remaining = picked.effectRounds or 1,
            })
            RPG.Combat.Log(game, "^3" .. game.combat.enemy.name .. " is stunned!")
        end
    end

    if game.combat.enemy.hp <= 0 then
        local killQuip = PickRandom(def.quips.onEnemyKill) or ""
        if killQuip ~= "" then
            RPG.Combat.Log(game, "^2" .. killQuip)
        end
    end
end

function RPG.Companion.ResolveDefend(player, game, comp, def)
    local heal = math.random(3, 6)
    local before = comp.hp
    comp.hp = math.min(comp.maxHP, comp.hp + heal)
    game.combat.companionDefending = true

    local quip = PickRandom(def.quips.onDefend) or ""
    RPG.Combat.Log(game, "^7" .. def.name .. " takes cover, recovers " .. (comp.hp - before) .. " HP. " .. quip)
end

function RPG.Companion.ResolveCombatTurn(player, game)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return end
    if comp.ko then return end

    local isBlack = RPG.Companion.IsBlackmailed(comp)
    local behaviorKey = isBlack and "blackmail" or "normal"
    local behavior = def.behavior[behaviorKey] or def.behavior.normal

    local action = RPG.Companion.ChooseAction(behavior)

    if action == "attack" then
        RPG.Companion.ResolveAttack(player, game, comp, def)
    elseif action == "special" then
        RPG.Companion.ResolveSpecial(player, game, comp, def)
    elseif action == "defend" then
        RPG.Companion.ResolveDefend(player, game, comp, def)
    end
end

-- ============================================
-- ENEMY TARGETING
-- ============================================

function RPG.Companion.ResolveEnemyTarget(game)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def or comp.ko then return "player" end

    local chance = def.targetChance
    if game.combat.companionDefending then
        chance = def.targetChanceDefending
    end

    if RollPercent(chance) then
        return "companion"
    end
    return "player"
end

function RPG.Companion.TakeDamage(player, game, damage)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return end

    comp.hp = math.max(0, comp.hp - damage)
    RPG.Combat.Log(game, "^1" .. game.combat.enemy.name .. " hits " .. def.name .. " for " .. damage .. " damage!")

    if comp.hp <= 0 then
        comp.ko = true
        local quip = PickRandom(def.quips.onKO) or ""
        RPG.Combat.Log(game, "^1" .. def.name .. " is knocked out! " .. quip)
        if player and player:IsValid() then
            player:SendPrint("^1" .. def.name .. " has been knocked unconscious!")
        end
    end
end

-- ============================================
-- COMBAT LIFECYCLE
-- ============================================

function RPG.Companion.OnCombatStart(game)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return end

    -- Scale to player level and ensure not KO'd
    RPG.Companion.ScaleToLevel(game)
    comp.ko = false
    comp.hp = comp.maxHP
    game.combat.companionDefending = false
end

function RPG.Companion.OnCombatEnd(player, game, outcome)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return end

    game.combat.companionDefending = false

    if comp.ko then
        comp.ko = false
        comp.hp = math.max(comp.hp, def.koReviveHP)

        local isBlack = RPG.Companion.IsBlackmailed(comp)
        local pool = isBlack and def.quips.onReviveBlackmail or def.quips.onRevive
        local quip = PickRandom(pool) or ""
        if quip ~= "" and player and player:IsValid() then
            player:SendPrint(quip)
        end
    end
end

function RPG.Companion.ScaleToLevel(game)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return end

    local level = game.player.level or 1
    local newMax = def.baseHP + (level - 1) * def.hpPerLevel

    if newMax > comp.maxHP then
        local gain = newMax - comp.maxHP
        comp.maxHP = newMax
        comp.hp = math.min(comp.maxHP, comp.hp + gain)
    end
end

-- ============================================
-- ROOM COMMENTARY
-- ============================================

function RPG.Companion.OnRoomEnter(player, game, roomId)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def or comp.ko then return end

    -- Cooldown check
    game.ui = game.ui or {}
    local now = (Game and Game.GetTime and Game.GetTime()) or (CurTime and CurTime()) or 0
    local cooldown = RPG.Config.COMPANION_COMMENT_COOLDOWN or 15000
    if game.ui.lastCompanionComment and (now - game.ui.lastCompanionComment < cooldown) then
        return
    end

    -- Chance check
    if not RollPercent(RPG.Config.COMPANION_COMMENT_CHANCE or 60) then
        return
    end

    local isBlack = RPG.Companion.IsBlackmailed(comp)
    local variant = isBlack and "blackmail" or "normal"

    -- Room-specific pool first, then generic fallback
    local pool
    local roomCommentary = def.commentary[roomId]
    if roomCommentary and roomCommentary[variant] then
        pool = roomCommentary[variant]
    end
    if not pool or #pool == 0 then
        local generic = def.commentary.generic
        if generic and generic[variant] then
            pool = generic[variant]
        end
    end
    if not pool or #pool == 0 then return end

    local line = PickRandom(pool)
    if not line then return end

    game.ui.lastCompanionComment = now

    -- Deliver via timer at 800ms delay (after room narration at ~200ms)
    local clientNum = player:GetClientNum()
    Timer.Create("rpg_companion_comment_" .. clientNum, 1500, 1, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local msg = "^7" .. def.name .. ": " .. line
        p:SendPrint(msg)
        RPG.Util.TrackPrint(clientNum, #msg)
    end)
end

-- ============================================
-- PARANOIA MANAGEMENT
-- ============================================

function RPG.Companion.ModifyParanoiaGain(game, delta)
    if delta <= 0 then return delta end

    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return delta end
    if comp.ko then return delta end
    if RPG.Companion.IsBlackmailed(comp) then return delta end

    local reduction = def.paranoiaReduction or 0.25
    local reduced = math.max(1, math.floor(delta * (1 - reduction) + 0.5))
    return reduced
end

function RPG.Companion.CheckParanoiaThreshold(player, game)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return end
    if RPG.Companion.IsBlackmailed(comp) then return end
    if comp.ko then return end

    local paranoia = game.player.paranoia or 0
    game.ui = game.ui or {}
    local now = (Game and Game.GetTime and Game.GetTime()) or (CurTime and CurTime()) or 0
    local cooldown = RPG.Config.COMPANION_PARANOIA_CALM_COOLDOWN or 60000

    if game.ui.lastCompanionCalm and (now - game.ui.lastCompanionCalm < cooldown) then
        return
    end

    -- Check thresholds (pick highest crossed)
    local thresholds = def.paranoiaThresholds or {}
    local bestLine
    for _, thresh in ipairs(thresholds) do
        if paranoia >= thresh and def.calmingLines[thresh] then
            bestLine = def.calmingLines[thresh]
        end
    end

    if bestLine then
        game.ui.lastCompanionCalm = now
        if player and player:IsValid() then
            player:SendPrint("^7" .. def.name .. ": " .. bestLine)
        end
    end
end

-- ============================================
-- DISPLAY
-- ============================================

function RPG.Companion.GetHPLine(game)
    local comp, def = RPG.Companion.GetActive(game)
    if not comp or not def then return nil end

    if comp.ko then
        return "^7" .. def.name .. " ^1[KO]"
    end

    local cw = RPG.Config.HEALTH_BAR_COMPACT or 10
    return "^7" .. def.name .. " " .. RPG.Util.HealthBar(comp.hp, comp.maxHP, cw)
end

return true
