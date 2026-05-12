-- Echoes of the Dark Wars - Dream Menu
-- Atmospheric crash sequence before class selection

RPG = RPG or {}

Menu.Register("rpg_dream", {
    title = "^8=== DREAM ===^7",
    header = function(player, state)
        local lines = RPG.DreamText and RPG.DreamText[0]
        if not lines then return "" end
        return table.concat(lines, "\n")
    end,
    getItems = function(player, state)
        return {
            { label = "^3>>> WAKE UP >>>", action = "wake" },
            { label = "^1>>> EMBRACE THE VISION >>>", action = "embrace" },
        }
    end,
    onAction = function(player, action, state, selectedItem)
        if action == "wake" then
            RPG.SetState(player, "class_select")
        elseif action == "embrace" then
            local cn = player:GetClientNum()
            if RPG.players and RPG.players[cn] then
                RPG.players[cn].dreamEmbrace = true
            end
            RPG.SetState(player, "class_select")
        end
    end,
    onOpen = function(player, state)
        RPG.PrintDream(player, 0)
    end,
    onBack = function(player, state)
        return true  -- No escape from the dream
    end,
    controls = "USE: Select",
    maxVisibleItems = 4,
})

return true
