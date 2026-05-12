-- Echoes of the Dark Wars - Stat Allocation Menu
-- Spend pending stat points earned at milestone levels

RPG = RPG or {}

local SAEVUS_STAT_WHISPERS = {
    STR = "^1Flesh is weak, but steel and will endure.",
    DEX = "^1Speed is the refuge of those who fear commitment.",
    CON = "^1You harden yourself. Good. Softness invites the blade.",
    WIS = "^1You seek clarity? The truth will only make you weep.",
    INT = "^1Knowledge is a weapon. But who are you aiming it at?",
    CHA = "^1Lies are the oil in the galaxy's gears.",
}

Menu.Register("rpg_stat_allocation", {
    title = "^3=== STAT ALLOCATION ===^7",

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "^1No active game." end

        local p = game.player
        local pts = p.pendingStatPoints or 0
        local lines = {}

        lines[#lines + 1] = "^3Points Available: " .. pts
        lines[#lines + 1] = ""

        -- 2-column stat display with modifiers (effective values)
        local order = RPG.Data.StatOrder
        local row1Left = order[1] or "STR"
        local row1Right = order[4] or "WIS"
        local row2Left = order[2] or "DEX"
        local row2Right = order[5] or "INT"
        local row3Left = order[3] or "CON"
        local row3Right = order[6] or "CHA"

        local function fmtStat(statName)
            local val = p.stats[statName] or 10
            local mod = RPG.Util.StatMod(val)
            local sign = mod >= 0 and "+" or ""
            return statName .. ": " .. val .. " (" .. sign .. mod .. ")"
        end

        local function pad(s, width)
            local vis = 0
            local i = 1
            while i <= #s do
                if s:sub(i, i) == "^" and i + 1 <= #s then
                    i = i + 2
                else
                    vis = vis + 1
                    i = i + 1
                end
            end
            local needed = width - vis
            if needed > 0 then
                return s .. string.rep(" ", needed)
            end
            return s
        end

        lines[#lines + 1] = "^7" .. pad(fmtStat(row1Left), 20) .. fmtStat(row1Right)
        lines[#lines + 1] = "^7" .. pad(fmtStat(row2Left), 20) .. fmtStat(row2Right)
        lines[#lines + 1] = "^7" .. pad(fmtStat(row3Left), 20) .. fmtStat(row3Right)

        -- Saevus whisper for selected stat
        if p.hasHolocron and state and state.selection then
            local idx = state.selection
            if idx >= 1 and idx <= #RPG.Data.StatOrder then
                local statKey = RPG.Data.StatOrder[idx]
                local whisper = SAEVUS_STAT_WHISPERS[statKey]
                if whisper then
                    lines[#lines + 1] = ""
                    lines[#lines + 1] = whisper
                end
            end
        end

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return {} end

        local p = game.player
        local pts = p.pendingStatPoints or 0
        local items = {}

        for _, statName in ipairs(RPG.Data.StatOrder) do
            -- Use effective stats for consistent modifier preview
            local curEff = p.stats[statName] or 10
            local newEff = curEff + 1
            local curMod = RPG.Util.StatMod(curEff)
            local newMod = RPG.Util.StatMod(newEff)
            local curSign = curMod >= 0 and "+" or ""
            local newSign = newMod >= 0 and "+" or ""

            local fullName = RPG.Data.StatNames[statName] or statName
            local label = "Increase " .. fullName .. " (" .. curEff .. " -> " .. newEff
                .. ", mod " .. curSign .. curMod .. " -> " .. newSign .. newMod .. ")"

            if statName == "CON" then
                label = label .. " +5 max HP"
            end

            if pts <= 0 then
                label = "^8" .. label
            end

            items[#items + 1] = { label = label, action = "alloc_" .. statName }
        end

        items[#items + 1] = { label = "^3<<< Back (keep points for later)", action = "back" }

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        if action == "back" then
            local retState = (state and state.data and state.data.returnState) or "exploration"
            RPG.SetState(player, retState)
            return true
        end

        local statName = action:match("^alloc_(%u+)$")
        if not statName then return false end

        local game = RPG.GetGame(player)
        if not game then return false end

        local p = game.player
        if (p.pendingStatPoints or 0) <= 0 then
            player:SendPrint("^3No stat points to spend.")
            return true
        end

        -- Validate stat name
        local valid = false
        for _, s in ipairs(RPG.Data.StatOrder) do
            if s == statName then
                valid = true
                break
            end
        end
        if not valid then return false end

        -- Apply allocation
        p.baseStats[statName] = (p.baseStats[statName] or 10) + 1
        p.pendingStatPoints = p.pendingStatPoints - 1

        -- CON bonus: immediate max HP and current HP increase
        local fullName = RPG.Data.StatNames[statName] or statName
        if statName == "CON" then
            local bonus = RPG.Config.CON_ALLOC_HP_BONUS
            p.maxHP = p.maxHP + bonus
            p.hp = p.hp + bonus
            player:SendPrint("^2" .. fullName .. " increased to " .. p.baseStats[statName] .. "! (+" .. bonus .. " max HP)^7")
        else
            player:SendPrint("^2" .. fullName .. " increased to " .. p.baseStats[statName] .. "!^7")
        end

        RPG.RecalcEffectiveStats(game)

        -- If no points remaining, return to caller
        if p.pendingStatPoints <= 0 then
            local retState = (state and state.data and state.data.returnState) or "exploration"
            RPG.SetState(player, retState)
            return true
        end

        -- Refresh menu (stay on screen with remaining points)
        if Menu and Menu.InvalidateCache then
            Menu.InvalidateCache(player)
        end
        return true
    end,

    onBack = function(player, state)
        local retState = (state and state.data and state.data.returnState) or "exploration"
        RPG.SetState(player, retState)
        return true
    end,

    controls = "USE: Select | ALT: Back",
    maxVisibleItems = 8,
})

return true
