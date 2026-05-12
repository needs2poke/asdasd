-- Echoes of the Dark Wars - Nemesis System
-- A rival hunter rolled at game start, with origin/temperament/memory.
-- Follows stalker.lua pattern: room-move state machine, combat triggers.

RPG = RPG or {}
RPG.Nemesis = {}

local ND = RPG.Data.NemesisData

-- ============================================
-- ROLL: Generate nemesis at game start
-- ============================================

function RPG.Nemesis.Roll(player, game)
    local origins = { "exchange", "republic", "mandalorian" }
    local origin = origins[math.random(1, #origins)]
    local temps = ND.TEMPERAMENTS[origin]
    local temperament = temps[math.random(1, #temps)]
    local names = ND.NAMES[origin]
    local firstName = names.first[math.random(1, #names.first)]
    local lastName  = names.last[math.random(1, #names.last)]

    game.nemesis = {
        origin      = origin,
        temperament = temperament,
        firstName   = firstName,
        lastName    = lastName,
        fullName    = firstName .. " " .. lastName,
        title       = ND.TITLES[origin][temperament],
        encounter   = 0,
        attitude    = "neutral",
        adaptation  = "none",
        scarStage   = 0,
        defeated    = false,
        fled        = false,
        combatProfile = { force = 0, melee = 0, ranged = 0, defend = 0, dark = 0 },
    }
end

-- ============================================
-- ATTITUDE: Computed from memory flags
-- ============================================

function RPG.Nemesis.ComputeAttitude(game)
    local f = game.flags
    -- Priority: respect > fear > hatred > obsession > neutral
    if f["nemesis_spared_1"] and f["nemesis_spared_2"] then
        return "respect"
    end
    if (game.player.paranoia or 0) > 70 and f["nemesis_used_dark_power"] then
        return "fear"
    end
    if f["nemesis_humiliated_1"] or f["nemesis_used_dark_power"] then
        return "hatred"
    end
    if f["nemesis_player_lost_1"] and f["nemesis_player_lost_2"] then
        return "obsession"
    end
    return "neutral"
end

-- ============================================
-- ADAPTATION: Class-based counter ability
-- ============================================

function RPG.Nemesis.GetAdaptation(game)
    local cls = game.player.class
    return ND.CLASS_ADAPTATION[cls] or "heavy_plating"
end

-- ============================================
-- BUILD ENEMY: Deep-copy base + origin mods + specials
-- ============================================

function RPG.Nemesis.BuildEnemy(game, encounterId)
    local enemyId = 29 + encounterId  -- 30, 31, 32
    local enemy = RPG.Data.GetEnemy(enemyId)
    if not enemy then return nil end

    local n = game.nemesis
    local mods = ND.ORIGIN_MODS[n.origin] or {}

    -- Apply origin stat modifiers
    enemy.maxHP = enemy.maxHP + (mods.hpMod or 0)
    enemy.hp = enemy.maxHP
    enemy.damageMin = enemy.damageMin + (mods.damageMod or 0)
    enemy.damageMax = enemy.damageMax + (mods.damageMod or 0)
    enemy.defense = enemy.defense + (mods.defenseMod or 0)

    -- Set dynamic name
    enemy.name = n.fullName .. " (" .. n.title .. ")"
    enemy.nemesisEncounter = encounterId

    -- Populate specials from origin abilities
    enemy.specials = {}
    local originAbilities = ND.ABILITIES[n.origin] or {}
    for abilityId, def in pairs(originAbilities) do
        if not def.minEncounter or encounterId >= def.minEncounter then
            enemy.specials[abilityId] = RPG.Util.DeepCopy(def)
        end
    end

    -- Adaptation ability (encounter 2+)
    if encounterId >= 2 then
        local adaptId = RPG.Nemesis.GetAdaptation(game)
        n.adaptation = adaptId
        local adaptDef = ND.ADAPTATIONS[adaptId]
        if adaptDef then
            enemy.specials[adaptId] = RPG.Util.DeepCopy(adaptDef)
        end
    end

    return enemy
end

-- ============================================
-- ENCOUNTER TRIGGER CONDITIONS
-- ============================================

local function CountCompletedSideQuests(game)
    local count = 0
    for qid, qs in pairs(game.quests) do
        if qid ~= "echoes" and qid ~= "the_hunter" and qs.status == "completed" then
            count = count + 1
        end
    end
    return count
end

local function ShouldTrigger(game, roomId)
    local n = game.nemesis
    if not n or n.defeated then return false end

    -- Encounter 1: 2+ side quests, Room 2, encounter == 0
    if n.encounter == 0 and roomId == RPG.Config.NEMESIS_ENC1_ROOM then
        return CountCompletedSideQuests(game) >= RPG.Config.NEMESIS_QUEST_THRESHOLD
    end

    -- Encounter 2: Act 2, 3+ room moves in Act 2, Room 30, encounter == 1
    if n.encounter == 1 and roomId == RPG.Config.NEMESIS_ENC2_ROOM then
        return (game.currentAct or 1) >= 2
            and (n._act2Moves or 0) >= RPG.Config.NEMESIS_ACT2_MOVES
    end

    -- Encounter 3: Act 4, Room 43, encounter == 2, must be a REVISIT
    -- (act4_narrated is set on first entry in same MoveToRoom call, so also check visitedRooms)
    if n.encounter == 2 and roomId == RPG.Config.NEMESIS_ENC3_ROOM then
        return (game.currentAct or 1) >= 4
            and game.flags["act4_narrated"] == true
            and game.visitedRooms[roomId] == true
    end

    return false
end

-- ============================================
-- ON ROOM MOVE: Main hook (called from state.lua)
-- ============================================

function RPG.Nemesis.OnRoomMove(player, game, roomId)
    local n = game.nemesis
    if not n or n.defeated then return false end

    -- Track Act 2 room moves for Enc 2 trigger
    if roomId >= 26 and roomId <= 35 and (game.currentAct or 1) >= 2 then
        n._act2Moves = (n._act2Moves or 0) + 1
    end

    -- Check encounter trigger
    if not ShouldTrigger(game, roomId) then
        return false
    end

    -- Refresh attitude from current flags (spare/humiliation set by prior dialogue)
    n.attitude = RPG.Nemesis.ComputeAttitude(game)

    local encNum = n.encounter + 1

    -- Narrative lock: prevent horror glitch collision
    game._narrativeActive = true

    -- Start quest on first encounter
    if encNum == 1 then
        RPG.Quest.Start(player, "the_hunter")
        RPG.Quest.SetStage(player, "the_hunter", "hunt_begins")
    elseif encNum == 2 then
        RPG.Quest.SetStage(player, "the_hunter", "tracked")
    elseif encNum == 3 then
        RPG.Quest.SetStage(player, "the_hunter", "closing_in")
    end

    -- Play origin audio cue
    local sound = RPG.Config.NEMESIS_ORIGIN_SOUNDS[n.origin]
    if sound then
        player:PlaySound(sound)
    end

    -- Show intro narration
    local introData = ND.INTRO_TEXT[n.origin]
    if introData then
        local introLines = introData[encNum]
        if type(introLines) == "function" then
            introLines = introLines(game)
        end
        if introLines then
            local batch = { "", "^1========================================" }
            for _, line in ipairs(introLines) do
                if line ~= "" then
                    batch[#batch + 1] = line
                end
            end
            batch[#batch + 1] = "^1========================================"
            batch[#batch + 1] = ""
            RPG.Util.BatchPrint(player, batch)
        end
    end

    -- Saevus whisper at combat start
    local whisper = ND.SAEVUS_WHISPERS[encNum]
    if whisper and game.player.hasHolocron and (game.player.paranoia or 0) >= 30 then
        RPG.Util.BatchPrint(player, { whisper })
    end

    -- Start dialogue after delay
    local clientNum = player:GetClientNum()
    Timer.Simple("rpg_nemesis_dialogue_" .. clientNum, 1500, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local g = RPG.GetGame(p)
        if not g then return end
        g._narrativeActive = nil
        RPG.Dialogue.Start(p, 30)
    end)

    return true  -- handled: skip follow-up hooks
end

-- ============================================
-- START ENCOUNTER: Called from dialogue action
-- ============================================

function RPG.Nemesis.StartEncounter(player, game)
    local n = game.nemesis
    local encNum = n.encounter + 1
    local enemy = RPG.Nemesis.BuildEnemy(game, encNum)
    if not enemy then return end

    -- Flavor: low FP comment at Enc 2+
    if encNum >= 2 and game.player.fp < math.floor(game.player.maxFP * 0.3) then
        player:SendPrint("^3'" .. n.fullName .. " studies you. \"You've been leaning on the Force. I can see it in your eyes -- you're drained.\"'")
    end

    -- Reset dark power tracking for new combat
    game.player.darkPowerUsed = false

    -- Store enemy directly (bypass GetEnemy since we built it)
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
        snapshot = {
            enemyId = enemy.id,
            roomId = game.player.currentRoom,
            entryHP = game.player.hp,
            entryFP = game.player.fp,
            inventory = RPG.Util.DeepCopy(game.player.inventory),
            equipped = RPG.Util.DeepCopy(game.player.equipped),
            stats = RPG.Util.DeepCopy(game.player.stats),
            baseStats = RPG.Util.DeepCopy(game.player.baseStats),
        },
    }

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
end

-- ============================================
-- ON COMBAT END: Process nemesis outcomes
-- ============================================

function RPG.Nemesis.OnCombatEnd(player, game, outcome, enemy)
    if not enemy or not enemy.nemesisEncounter then return false end

    local n = game.nemesis
    if not n then return false end

    local encNum = enemy.nemesisEncounter

    if outcome == "victory" then
        n.encounter = encNum
        n.scarStage = math.min(n.scarStage + 1, 2)
        -- Attitude NOT computed here: spare/humiliation flags are set later
        -- by the post-combat dialogue actions. Attitude is refreshed on next
        -- encounter trigger (OnRoomMove) and in ShowDossier.
    elseif outcome == "defeat" then
        -- Nemesis doesn't kill: take penalty, set flags, return to exploration
        game.flags["nemesis_player_lost_" .. encNum] = true
        n.encounter = encNum
        n.attitude = RPG.Nemesis.ComputeAttitude(game)

        -- Take credits (Enc 1) or non-quest item (Enc 2+)
        if encNum == 1 then
            local loss = math.floor(game.player.credits * RPG.Config.NEMESIS_DEFEAT_CREDIT_PENALTY)
            game.player.credits = game.player.credits - loss
            if loss > 0 then
                player:SendPrint("^1" .. n.fullName .. " takes " .. loss .. " credits from you.")
            end
        else
            -- Take a random non-quest item
            local stealable = {}
            for i, itemId in ipairs(game.player.inventory) do
                local def = RPG.Data.Items[itemId]
                if not def or def.type ~= "quest" then
                    stealable[#stealable + 1] = i
                end
            end
            if #stealable > 0 then
                local idx = stealable[math.random(1, #stealable)]
                local itemId = game.player.inventory[idx]
                local name = RPG.Data.GetItemName(itemId)
                table.remove(game.player.inventory, idx)
                player:SendPrint("^1" .. n.fullName .. " takes your " .. name .. ".")
            end
        end

        -- Attitude-flavored taunt
        local taunts = ND.DEFEAT_TAUNTS[n.temperament]
        if taunts then
            local taunt = taunts[n.attitude] or taunts["neutral"]
            if taunt then
                RPG.Util.BatchPrint(player, { "", taunt, "" })
            end
        end

        -- Heal player to 1 HP (they survive)
        game.player.hp = math.max(game.player.hp, 1)

        return true  -- signal: nemesis handled defeat, don't go to game_over
    elseif outcome == "fled" then
        n.fled = true
        game.flags["nemesis_player_fled_" .. encNum] = true
    end

    -- Atton companion reaction
    if game.player.activeCompanion == "atton" then
        local line = ND.ATTON_LINES[encNum]
        if line then
            local cn = player:GetClientNum()
            Timer.Simple("rpg_nemesis_atton_" .. cn, 2000, function()
                local p = Player.Get(cn)
                if not p or not p:IsValid() then return end
                p:SendPrint(line)
            end)
        end
    end

    return false
end

-- ============================================
-- TRACE DESCRIPTIONS: Additive room flavor
-- ============================================

function RPG.Nemesis.GetTraceDescription(game, roomId)
    local n = game.nemesis
    if not n or n.encounter < 1 or n.defeated then return nil end

    -- Bridge dossier is handled via menu action, not trace
    if roomId == 17 then return nil end

    local traceData = ND.TRACES[roomId]
    if not traceData then return nil end

    -- Check encounter threshold
    if traceData.encounter and n.encounter < traceData.encounter then
        return nil
    end

    -- Paranoia > 70: chance of fake trace (Saevus manipulation)
    if (game.player.paranoia or 0) > 70 and math.random(100) <= 15 then
        local fakes = ND.FAKE_TRACES
        local text = fakes[math.random(1, #fakes)]
        return { text = text, sound = nil }
    end

    -- Dynamic text
    local text
    if traceData.dynamic then
        text = traceData.dynamic(game)
    elseif traceData[n.origin] then
        text = traceData[n.origin]
    else
        text = traceData.text
    end

    if not text or text == "" then return nil end

    -- Audio cue
    local sound = RPG.Config.NEMESIS_ORIGIN_SOUNDS[n.origin]

    return { text = text, sound = sound }
end

-- ============================================
-- DOSSIER: Bridge (Room 17) menu action
-- ============================================

function RPG.Nemesis.ShowDossier(player, game)
    local n = game.nemesis
    if not n then return end

    -- Recompute attitude from current flags before display
    n.attitude = RPG.Nemesis.ComputeAttitude(game)

    local scarDesc = ND.SCAR_DESCRIPTIONS[n.origin]
    local scarText = scarDesc and scarDesc[n.scarStage] or "No visual data."

    local lines = {
        "",
        "^3=== HUNTER DOSSIER ===",
        "^7Name: ^3" .. n.fullName,
        "^7Origin: ^3" .. n.title,
        "^7Status: ^3" .. (n.defeated and "Resolved" or "Active Threat"),
        "^7Scars: ^7" .. scarText,
        "^7Attitude: ^3" .. n.attitude,
    }

    if n.encounter >= 2 and n.adaptation ~= "none" then
        lines[#lines + 1] = "^1WARNING: ^7Subject has deployed counter-measures (" .. n.adaptation .. ")."
    end

    lines[#lines + 1] = "^3====================="
    lines[#lines + 1] = ""

    RPG.Util.BatchPrint(player, lines)
end

-- ============================================
-- NPC DESCRIPTION: Scar-stage aware
-- ============================================

function RPG.Nemesis.GetDescription(game)
    local n = game.nemesis
    if not n then return "They're here for you." end
    local scarDesc = ND.SCAR_DESCRIPTIONS[n.origin]
    return scarDesc and scarDesc[n.scarStage] or "They're here for you."
end

-- ============================================
-- COMBAT PROFILE: Record player actions (Phase 3B prep)
-- ============================================

function RPG.Nemesis.RecordCombatAction(game, actionType)
    if not game.nemesis or not game.nemesis.combatProfile then return end
    local cp = game.nemesis.combatProfile
    if cp[actionType] then
        cp[actionType] = cp[actionType] + 1
    end
end

-- ============================================
-- DYNAMIC NPC NAME: Monkey-patch GetNPCName
-- ============================================

local _origGetNPCName = RPG.Data.GetNPCName

function RPG.Data.GetNPCName(npcId, game)
    if npcId == 30 and game and game.nemesis then
        return game.nemesis.fullName
    end
    return _origGetNPCName(npcId, game)
end

-- ============================================
-- CLEANUP: Cancel pending timers
-- ============================================

function RPG.Nemesis.Cleanup(clientNum)
    Timer.Remove("rpg_nemesis_dialogue_" .. clientNum)
    Timer.Remove("rpg_nemesis_atton_" .. clientNum)
    Timer.Remove("rpg_nemesis_postcombat_" .. clientNum)
end

return true
