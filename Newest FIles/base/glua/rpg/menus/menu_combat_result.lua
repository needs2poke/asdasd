-- Echoes of the Dark Wars - Combat Result Menu
-- Post-combat victory screen with rewards

RPG = RPG or {}

Menu.Register("rpg_combat_result", {
    title = "^2=== VICTORY ===^7",

    header = function(player, state)
        local game = RPG.GetGame(player)
        local vd = game and game.victoryData
        if not vd then return "^2Enemy defeated!^7" end

        local lines = {}
        lines[#lines + 1] = "^2" .. vd.enemyName .. " defeated!^7"
        lines[#lines + 1] = ""
        if vd.deathText then
            lines[#lines + 1] = "^8" .. vd.deathText
        end
        lines[#lines + 1] = ""
        lines[#lines + 1] = "^2+" .. vd.xp .. " XP^7"
        lines[#lines + 1] = "^3+" .. vd.credits .. " credits^7"
        if vd.loot and #vd.loot > 0 then
            for _, item in ipairs(vd.loot) do
                lines[#lines + 1] = "^5+ " .. item .. "^7"
            end
        end
        if vd.levelUp then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "^2>>> LEVEL UP! Level " .. vd.newLevel .. " <<<^7"
        end
        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        return { { label = "^7>>> Continue >>>", action = "continue" } }
    end,

    onAction = function(player, action, state, selectedItem)
        if action == "continue" then
            local cn = player:GetClientNum()
            Timer.Remove("rpg_combat_result_" .. cn)
            RPG.SetState(player, "exploration")
        end
    end,

    onBack = function(player, state)
        local cn = player:GetClientNum()
        Timer.Remove("rpg_combat_result_" .. cn)
        RPG.SetState(player, "exploration")
        return true
    end,

    controls = "^3USE^7=Continue (auto 5s)",
    allowAttackClose = false,
})

return true
