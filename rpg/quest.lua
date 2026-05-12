-- Echoes of the Dark Wars - Quest System
-- Quest lifecycle, flags, event triggers, clamped stat helpers

RPG = RPG or {}
RPG.Quest = {}

-- ============================================
-- QUEST LIFECYCLE
-- ============================================

--- Start a quest (sets status = "active", stage = first stage)
function RPG.Quest.Start(player, questId)
    local game = RPG.GetGame(player)
    if not game then return false end

    local def = RPG.Data.Quests and RPG.Data.Quests[questId]
    if not def then
        GLua.Warn("RPG.Quest.Start: Unknown quest '" .. tostring(questId) .. "'")
        return false
    end

    -- Already started?
    if game.quests[questId] then
        GLua.Debug("RPG.Quest.Start: Quest '" .. questId .. "' already exists")
        return false
    end

    -- Find first stage from the ordered stages list
    local firstStage = def.stageOrder and def.stageOrder[1] or nil
    if not firstStage then
        GLua.Warn("RPG.Quest.Start: Quest '" .. questId .. "' has no stageOrder")
        return false
    end

    game.quests[questId] = {
        status = "active",
        stage = firstStage,
        vars = {},
    }

    -- Notify player
    player:SendPrint("")
    player:SendPrint("^3[New Quest] " .. (def.name or questId))
    local stageDef = def.stages[firstStage]
    if stageDef and stageDef.journal then
        player:SendPrint("^7" .. stageDef.journal)
    end
    player:SendPrint("")

    -- Apply stage enter effects
    RPG.Quest.ApplyStageEffects(player, questId, firstStage)

    return true
end

--- Get current stage string for a quest (or nil if not started)
function RPG.Quest.GetStage(game, questId)
    if not game or not game.quests then return nil end
    local q = game.quests[questId]
    if not q then return nil end
    return q.stage
end

--- Set quest stage (advance) + apply stage effects
function RPG.Quest.SetStage(player, questId, stage)
    local game = RPG.GetGame(player)
    if not game then return false end

    local q = game.quests[questId]
    if not q then
        GLua.Warn("RPG.Quest.SetStage: Quest '" .. questId .. "' not started")
        return false
    end

    local def = RPG.Data.Quests and RPG.Data.Quests[questId]
    if not def then return false end

    local stageDef = def.stages[stage]
    if not stageDef then
        GLua.Warn("RPG.Quest.SetStage: Unknown stage '" .. tostring(stage) .. "' for quest '" .. questId .. "'")
        return false
    end

    local oldStage = q.stage
    q.stage = stage

    -- Notify player of stage update + apply effects (only on actual change)
    if oldStage ~= stage then
        if stageDef.status == "failed" then
            -- Terminal failure — skip normal [Quest Updated], print [Quest Failed] only
            q.status = "failed"
            player:SendPrint("")
            player:SendPrint("^1[Quest Failed] " .. (def.name or questId))
            if stageDef.journal then
                player:SendPrint("^7" .. stageDef.journal)
            end
            player:SendPrint("")
        elseif stageDef.status == "completed" or stage == "complete" then
            -- Route through Complete() to apply rewards + completion logic
            RPG.Quest.Complete(player, questId)
        else
            -- Normal stage advance
            player:SendPrint("")
            player:SendPrint("^3[Quest Updated] " .. (def.name or questId))
            if stageDef.journal then
                player:SendPrint("^7" .. stageDef.journal)
            end
            player:SendPrint("")
        end
        RPG.Quest.ApplyStageEffects(player, questId, stage)
    end

    return true
end

--- Apply effects defined on a quest stage
function RPG.Quest.ApplyStageEffects(player, questId, stage)
    local game = RPG.GetGame(player)
    if not game then return end

    local def = RPG.Data.Quests and RPG.Data.Quests[questId]
    if not def then return end

    local stageDef = def.stages[stage]
    if not stageDef or not stageDef.effects then return end

    local fx = stageDef.effects
    if fx.alignment then
        RPG.AddAlignment(player, fx.alignment)
    end
    if fx.paranoia then
        RPG.AddParanoia(player, fx.paranoia)
    end
    if fx.xp then
        game.player.xp = game.player.xp + fx.xp
        player:SendPrint("^2+" .. fx.xp .. " XP")
    end
    if fx.giveXP then
        game.player.xp = game.player.xp + fx.giveXP
        player:SendPrint("^2+" .. fx.giveXP .. " XP")
        print("[RPG WARNING] Quest stage used 'giveXP' instead of 'xp' -- use 'xp' for quest effects")
    end
    if fx.credits then
        game.player.credits = game.player.credits + fx.credits
        if fx.credits > 0 then
            player:SendPrint("^3+" .. fx.credits .. " credits")
        end
    end
    if fx.setFlag then
        RPG.Quest.SetFlag(game, fx.setFlag)
    end
    if fx.unlockRoom then
        if game.rooms[fx.unlockRoom] then
            game.rooms[fx.unlockRoom].locked = false
        end
    end
    if fx.grantAbility then
        local abilityDef = RPG.Data.Abilities and RPG.Data.Abilities[fx.grantAbility]
        if abilityDef and abilityDef.unlock and abilityDef.unlock.classes then
            local classMatch = false
            for _, cls in ipairs(abilityDef.unlock.classes) do
                if cls == game.player.class then classMatch = true; break end
            end
            if classMatch then
                RPG.GrantAbility(player, fx.grantAbility)
            end
        else
            RPG.GrantAbility(player, fx.grantAbility)
        end
    end
    if fx.boostStat then
        game.player.statBoosts = game.player.statBoosts or {}
        local s = fx.boostStat.stat
        local a = fx.boostStat.amount or 1
        game.player.statBoosts[s] = (game.player.statBoosts[s] or 0) + a
        RPG.RecalcEffectiveStats(game)
        player:SendPrint(fx.boostStat.message or ("^5+" .. a .. " " .. s .. "^7"))
    end
end

--- Complete a quest
function RPG.Quest.Complete(player, questId)
    local game = RPG.GetGame(player)
    if not game then return false end

    local q = game.quests[questId]
    if not q then return false end
    if q.status == "completed" then return true end  -- Already done, no-op

    local def = RPG.Data.Quests and RPG.Data.Quests[questId]

    q.status = "completed"
    q.stage = "complete"

    player:SendPrint("")
    player:SendPrint("^2[Quest Complete] " .. (def and def.name or questId))

    -- Apply completion rewards
    if def and def.stages and def.stages.complete then
        local completeDef = def.stages.complete
        if completeDef.rewards then
            local r = completeDef.rewards
            if r.xp then
                game.player.xp = game.player.xp + r.xp
                player:SendPrint("^2+" .. r.xp .. " XP")
            end
            if r.credits then
                game.player.credits = game.player.credits + r.credits
                player:SendPrint("^3+" .. r.credits .. " credits")
            end
        end
        if completeDef.effects then
            RPG.Quest.ApplyStageEffects(player, questId, "complete")
        end
    end
    player:SendPrint("")

    -- Check if Atton trust gate should open (2+ side quests completed)
    local ATTON_TRUST_QUESTS = {
        exchange_pressure = true,
        field_medicine = true,
        shadows_trail = true,
        law_khoonda = true,
    }
    if ATTON_TRUST_QUESTS[questId] and not RPG.Quest.HasFlag(game, "atton_trust_ready") then
        local sideCount = 0
        for qid, qs in pairs(game.quests) do
            if qs.status == "completed" and ATTON_TRUST_QUESTS[qid] then
                sideCount = sideCount + 1
            end
        end
        if sideCount >= 2 then
            RPG.Quest.SetFlag(game, "atton_trust_ready")
            player:SendPrint("^3[Atton seems ready to talk about something serious...]")
        end
    end

    return true
end

--- Fail a quest
function RPG.Quest.Fail(player, questId)
    local game = RPG.GetGame(player)
    if not game then return false end

    local q = game.quests[questId]
    if not q then return false end

    local def = RPG.Data.Quests and RPG.Data.Quests[questId]
    q.status = "failed"

    player:SendPrint("")
    player:SendPrint("^1[Quest Failed] " .. (def and def.name or questId))
    player:SendPrint("")

    return true
end

--- Check if quest is active
function RPG.Quest.IsActive(game, questId)
    if not game or not game.quests then return false end
    local q = game.quests[questId]
    return q ~= nil and q.status == "active"
end

--- Check if quest is completed
function RPG.Quest.IsComplete(game, questId)
    if not game or not game.quests then return false end
    local q = game.quests[questId]
    return q ~= nil and q.status == "completed"
end

-- ============================================
-- QUEST VARIABLES (per-quest local storage)
-- ============================================

function RPG.Quest.GetVar(game, questId, key)
    if not game or not game.quests then return nil end
    local q = game.quests[questId]
    if not q or not q.vars then return nil end
    return q.vars[key]
end

function RPG.Quest.SetVar(player, questId, key, val)
    local game = RPG.GetGame(player)
    if not game then return end
    local q = game.quests[questId]
    if not q then return end
    if not q.vars then q.vars = {} end
    q.vars[key] = val
end

-- ============================================
-- GLOBAL FLAGS
-- ============================================

-- Deprecated flag names → canonical names (save compatibility)
local FLAG_ALIASES = {
    kolto_purchased = "has_exchange_kolto",
}

function RPG.Quest.HasFlag(game, flagName)
    if not game or not game.flags then return false end
    local canonical = FLAG_ALIASES[flagName] or flagName
    if game.flags[canonical] == true then return true end
    -- Reverse lookup: check if any deprecated alias for this canonical name is set
    for oldName, newName in pairs(FLAG_ALIASES) do
        if newName == canonical and game.flags[oldName] == true then
            -- Migrate in-place so this only runs once per flag per save
            game.flags[canonical] = true
            game.flags[oldName] = nil
            return true
        end
    end
    return false
end

function RPG.Quest.SetFlag(game, flagName)
    if not game then return end
    if not game.flags then game.flags = {} end
    local canonical = FLAG_ALIASES[flagName] or flagName
    game.flags[canonical] = true
end

function RPG.Quest.ClearFlag(game, flagName)
    if not game or not game.flags then return end
    local canonical = FLAG_ALIASES[flagName] or flagName
    game.flags[canonical] = nil
end

-- ============================================
-- EVENT DISPATCHER
-- ============================================
-- Events fired from exploration, combat, inventory, etc.
-- Each quest can register event handlers in its data definition.

function RPG.Quest.OnEvent(player, eventType, payload)
    local game = RPG.GetGame(player)
    if not game then return end
    if not RPG.Data.Quests then return end

    payload = payload or {}

    -- Check every active quest for matching event handlers
    for questId, questState in pairs(game.quests) do
        if questState.status == "active" then
            local def = RPG.Data.Quests[questId]
            if def and def.events then
                for _, evt in ipairs(def.events) do
                    -- Match event type
                    if evt.type == eventType then
                        -- Match required stage (if specified)
                        local stageOk = true
                        if evt.stage then
                            stageOk = (questState.stage == evt.stage)
                        end

                        -- Match payload fields (if specified)
                        local payloadOk = true
                        if evt.payload and stageOk then
                            for k, v in pairs(evt.payload) do
                                if payload[k] ~= v then
                                    payloadOk = false
                                    break
                                end
                            end
                        end

                        -- Fire handler
                        if stageOk and payloadOk and evt.action then
                            local ok, err = pcall(evt.action, player, game)
                            if not ok then
                                GLua.Warn("RPG.Quest.OnEvent error in '" .. questId .. "': " .. tostring(err))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============================================
-- CLAMPED STAT HELPERS
-- ============================================

--- Add alignment with clamping
function RPG.AddAlignment(player, delta)
    local game = RPG.GetGame(player)
    if not game then return end
    local old = game.player.alignment
    game.player.alignment = math.max(RPG.Config.ALIGNMENT_MIN,
        math.min(RPG.Config.ALIGNMENT_MAX, old + delta))
    -- Notify on significant shifts
    if delta >= 5 then
        player:SendPrint("^5[Light Side +" .. delta .. "]")
    elseif delta <= -5 then
        player:SendPrint("^1[Dark Side +" .. math.abs(delta) .. "]")
    end
end

--- Add paranoia with clamping (companion reduces positive gains)
function RPG.AddParanoia(player, delta)
    local game = RPG.GetGame(player)
    if not game then return end
    local effectiveDelta = delta
    if effectiveDelta > 0 and RPG.Companion and RPG.Companion.ModifyParanoiaGain then
        effectiveDelta = RPG.Companion.ModifyParanoiaGain(game, effectiveDelta)
    end
    local old = game.player.paranoia
    game.player.paranoia = math.max(RPG.Config.PARANOIA_MIN,
        math.min(RPG.Config.PARANOIA_MAX, old + effectiveDelta))
    if effectiveDelta > 0 and game.player.paranoia > old then
        player:SendPrint("^1[Paranoia +" .. effectiveDelta .. "]")
        if RPG.Companion and RPG.Companion.CheckParanoiaThreshold then
            RPG.Companion.CheckParanoiaThreshold(player, game)
        end
    end
end

return true
