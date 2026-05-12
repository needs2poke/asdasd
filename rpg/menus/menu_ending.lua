-- Echoes of the Dark Wars - Ending Display Menu
-- Terminal ending screen with narration and final stats

RPG = RPG or {}

Menu.Register("rpg_ending", {
    allowAttackClose = false,

    title = function(player, state)
        local game = RPG.GetGame(player)
        if game and game.endingData then
            return game.endingData.title
        end
        return "^7=== THE END ===^7"
    end,

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.endingData then
            return "^1[Error: No ending data]"
        end

        local ed = game.endingData
        local lines = {}

        -- Narration
        for _, line in ipairs(ed.narration) do
            lines[#lines + 1] = line
        end

        lines[#lines + 1] = ""
        lines[#lines + 1] = "^7==============================="
        lines[#lines + 1] = "^3Ending: ^7" .. ed.endingName
        lines[#lines + 1] = "^7==============================="

        -- Final stats
        if ed.stats then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "^3Class: ^7" .. ed.stats.class
            lines[#lines + 1] = "^3Level: ^7" .. ed.stats.level
            local alignLabel = "Neutral"
            if ed.stats.alignment >= 50 then
                alignLabel = "^5Light Side"
            elseif ed.stats.alignment <= -50 then
                alignLabel = "^1Dark Side"
            end
            lines[#lines + 1] = "^3Alignment: ^7" .. ed.stats.alignment .. " (" .. alignLabel .. "^7)"
            lines[#lines + 1] = "^3Paranoia: ^7" .. ed.stats.paranoia
            lines[#lines + 1] = "^3Quests: ^7" .. ed.stats.questsCompleted .. " completed"
        end

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local items = {}

        items[#items + 1] = {
            label = "^3End RPG Session",
            action = "quit",
        }

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        if action == "quit" then
            player:SendPrint("")
            player:SendPrint("^3Thank you for playing ^1Echoes of the Dark Wars^3.")
            player:SendPrint("^7Type ^3!rpg^7 to play again.")
            player:SendPrint("")
            RPG.Shutdown(player)
            return
        end
    end,

    onBack = function(player, state)
        -- No back/escape -- game is over, but allow quit on alt
        player:SendPrint("")
        player:SendPrint("^3Thank you for playing ^1Echoes of the Dark Wars^3.")
        player:SendPrint("^7Type ^3!rpg^7 to play again.")
        player:SendPrint("")
        RPG.Shutdown(player)
        return true
    end,

    controls = "USE: Select",
    maxVisibleItems = 4,
})

return true
