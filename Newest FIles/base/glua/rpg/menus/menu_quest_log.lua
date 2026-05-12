-- Echoes of the Dark Wars - Quest Log Menu
-- Shows active, completed, and failed quests with journal entries

RPG = RPG or {}

Menu.Register("rpg_quests", {
    title = "^3=== QUEST LOG ===^7",

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "" end

        local active = 0
        local completed = 0
        local failed = 0
        for _, q in pairs(game.quests) do
            if q.status == "active" then
                active = active + 1
            elseif q.status == "completed" then
                completed = completed + 1
            elseif q.status == "failed" then
                failed = failed + 1
            end
        end

        if active == 0 and completed == 0 and failed == 0 then
            return "^8No quests yet. Explore Dantooine to find objectives."
        end

        local parts = { "^7Active: " .. active, "Completed: " .. completed }
        if failed > 0 then
            parts[#parts + 1] = "^1Failed: " .. failed
        end

        -- Quest detail view
        if state.data and state.data.viewQuest then
            local questId = state.data.viewQuest
            local q = game.quests[questId]
            local def = RPG.Data.Quests and RPG.Data.Quests[questId]
            if q and def then
                local stageDef = def.stages[q.stage]
                local lines = {
                    table.concat(parts, "  "),
                    "^3" .. (def.name or questId) .. " ^7[" .. q.status .. "]",
                }
                if stageDef and stageDef.journal then
                    local journal = stageDef.journal
                    if #journal > 56 then
                        journal = (journal:sub(1, 56):match("^(.+)%s") or journal:sub(1, 56)) .. "..."
                    end
                    lines[#lines + 1] = "^7" .. journal
                end
                if stageDef and stageDef.objectives then
                    local maxObj = 2
                    local objCount = #stageDef.objectives
                    for i = 1, math.min(maxObj, objCount) do
                        lines[#lines + 1] = "^7 - " .. stageDef.objectives[i]
                    end
                    if objCount > maxObj then
                        lines[#lines + 1] = "^8  ... and " .. (objCount - maxObj) .. " more"
                    end
                end
                return table.concat(lines, "\n")
            end
        end

        return table.concat(parts, "  ")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game then
            return { { label = "^1No active game", action = "none" } }
        end

        local items = {}
        local hasActive = false
        local hasCompleted = false
        local hasFailed = false

        -- Active quests
        for questId, q in pairs(game.quests) do
            if q.status == "active" then
                if not hasActive then
                    items[#items + 1] = { label = "^3--- Active ---", action = "none" }
                    hasActive = true
                end
                local def = RPG.Data.Quests and RPG.Data.Quests[questId]
                local name = def and def.name or questId
                items[#items + 1] = {
                    label = "^7" .. name,
                    action = "view:" .. questId,
                }
            end
        end

        -- Completed quests
        for questId, q in pairs(game.quests) do
            if q.status == "completed" then
                if not hasCompleted then
                    items[#items + 1] = { label = "^3--- Completed ---", action = "none" }
                    hasCompleted = true
                end
                local def = RPG.Data.Quests and RPG.Data.Quests[questId]
                local name = def and def.name or questId
                items[#items + 1] = {
                    label = "^8" .. name .. " (done)",
                    action = "view:" .. questId,
                }
            end
        end

        -- Failed quests
        for questId, q in pairs(game.quests) do
            if q.status == "failed" then
                if not hasFailed then
                    items[#items + 1] = { label = "^3--- Failed ---", action = "none" }
                    hasFailed = true
                end
                local def = RPG.Data.Quests and RPG.Data.Quests[questId]
                local name = def and def.name or questId
                items[#items + 1] = {
                    label = "^1" .. name .. " (failed)",
                    action = "view:" .. questId,
                }
            end
        end

        if not hasActive and not hasCompleted and not hasFailed then
            items[#items + 1] = { label = "^8  No quests yet.", action = "none" }
        end

        -- Cipher progress section
        if RPG.Cipher and RPG.Cipher.GetDiscoveredCount then
            local showCipher = false
            if game.truthUnlocked then
                showCipher = true
            elseif RPG.Cipher.GetDiscoveredCount(game) > 0 then
                showCipher = true
            end
            if showCipher then
                items[#items + 1] = { label = "^3--- Holocron Cipher ---", action = "none" }
                if game.truthUnlocked then
                    local code = RPG.Config.CIPHER_CODE or "492173949"
                    local display = {}
                    for i = 1, #code do
                        display[#display + 1] = code:sub(i, i)
                    end
                    items[#items + 1] = { label = "^2Decoded: " .. table.concat(display, " "), action = "none" }
                else
                    local total = 0
                    if RPG.Data.Cipher and RPG.Data.Cipher.sources then
                        for _ in pairs(RPG.Data.Cipher.sources) do
                            total = total + 1
                        end
                    end
                    local found = RPG.Cipher.GetDiscoveredCount(game)
                    items[#items + 1] = { label = "^7Fragments recovered: " .. found .. " of " .. total, action = "none" }
                    local progress = RPG.Cipher.GetProgressString(game):gsub("_", ".")
                    items[#items + 1] = { label = "^8Known sequence: " .. progress, action = "none" }
                end
            end
        end

        items[#items + 1] = { label = "^3--- Options ---", action = "none" }
        items[#items + 1] = { label = "^3<<< Back to Exploration", action = "back" }

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        -- View quest detail
        if string.StartsWith(action, "view:") then
            local questId = action:sub(#"view:" + 1)
            state.data.viewQuest = questId
            if Menu and Menu.InvalidateCache then Menu.InvalidateCache(player) end
            return
        end
    end,

    onBack = function(player, state)
        if state.data then state.data.viewQuest = nil end
        RPG.SetState(player, "exploration")
        return true
    end,

    controls = "W/S: Browse | USE: View | ALT: Back",
    maxVisibleItems = 6,
})

return true
