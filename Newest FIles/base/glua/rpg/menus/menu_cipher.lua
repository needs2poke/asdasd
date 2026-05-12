-- Echoes of the Dark Wars - Cipher Chamber Menu
-- Room 49: 9-digit cipher input interface

RPG = RPG or {}

Menu.Register("rpg_cipher_input", {
    allowAttackClose = false,

    title = function(player, state)
        return "^3=== THE CIPHER CHAMBER ===^7"
    end,

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "" end

        local lines = {}

        lines[#lines + 1] = "^7Ancient machinery lines the walls."
        lines[#lines + 1] = "^7A console awaits a 9-digit code."
        lines[#lines + 1] = ""

        if game.truthUnlocked then
            lines[#lines + 1] = "^2THE CIPHER HAS BEEN SOLVED."
            lines[#lines + 1] = "^2The containment seal is active."
            lines[#lines + 1] = "^7The path forward is open."
        else
            lines[#lines + 1] = "^7Cipher: ^3" .. RPG.Cipher.GetProgressString(game)
            lines[#lines + 1] = ""
            local total = 0
            for _ in pairs(RPG.Data.Cipher.sources) do total = total + 1 end
            local found = RPG.Cipher.GetDiscoveredCount(game)
            lines[#lines + 1] = "^7Fragments discovered: " .. found .. "/" .. total
            lines[#lines + 1] = ""
            lines[#lines + 1] = "^7Type ^3!rpgcipher XXXXXXXXX ^7in chat"
            lines[#lines + 1] = "^7to submit the 9-digit code."
        end

        -- Feedback from last attempt
        if state.data and state.data.feedback then
            lines[#lines + 1] = ""
            lines[#lines + 1] = state.data.feedback
        end

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game then
            return { { label = "^1No active game", action = "back" } }
        end

        local items = {}

        items[#items + 1] = {
            label = "^3Review discovered fragments",
            action = "fragments",
        }

        if game.truthUnlocked then
            items[#items + 1] = {
                label = "^2Continue to the Chamber of Final Choice",
                action = "continue",
            }
        end

        items[#items + 1] = {
            label = "^7Leave the chamber",
            action = "back",
        }

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then return end

        if action == "fragments" then
            RPG.Cipher.ShowDiscoveredFragments(player, game)
            Menu.InvalidateCache(player)
            return
        end

        if action == "continue" then
            -- Move to Room 50 (Chamber of Final Choice)
            RPG.SetState(player, "exploration")
            RPG.MoveToRoom(player, 50)
            return
        end

        if action == "back" then
            -- Return to Room 48
            RPG.SetState(player, "exploration")
            RPG.MoveToRoom(player, 48)
            return
        end
    end,

    onBack = function(player, state)
        RPG.SetState(player, "exploration")
        RPG.MoveToRoom(player, 48)
        return true
    end,

    controls = "W/S: Navigate | USE: Select | ALT: Leave",
    maxVisibleItems = 6,
})

return true
