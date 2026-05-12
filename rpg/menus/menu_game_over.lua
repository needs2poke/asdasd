-- Echoes of the Dark Wars - Game Over Menu
-- Retry combat, respawn at Khoonda, or quit

RPG = RPG or {}

Menu.Register("rpg_game_over", {
    title = "^1=== YOU HAVE FALLEN ===^7",

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "" end

        local lines = {
            "",
            "^1The darkness swallows you whole.",
            "^7Your vision fades... something pulls you back.",
            "^8The Force is not done with you yet.",
            "",
        }

        local snap = game.deathSnapshot
        if snap then
            lines[#lines + 1] = "^3Enemy: ^7" .. (RPG.Data.Enemies[snap.enemyId] and RPG.Data.Enemies[snap.enemyId].name or "Unknown")
            lines[#lines + 1] = "^3Credits: ^7" .. (game.player.credits or 0)
            lines[#lines + 1] = ""
        end

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        return {
            { label = "^3Retry Combat ^7(restore entry state)", action = "retry" },
            { label = "^3Return to Khoonda ^7(heal, -50% credits)", action = "respawn" },
            { label = "^1Quit RPG", action = "quit" },
        }
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then return end

        if action == "retry" then
            local snap = game.deathSnapshot
            if not snap then
                player:SendPrint("^1Error: No combat snapshot found.")
                RPG.SetState(player, "exploration")
                return
            end

            -- Restore full entry state from snapshot
            game.player.hp = snap.entryHP
            game.player.fp = snap.entryFP
            game.player.inventory = RPG.Util.DeepCopy(snap.inventory)
            game.player.equipped = RPG.Util.DeepCopy(snap.equipped)
            game.player.stats = RPG.Util.DeepCopy(snap.stats)
            if snap.baseStats then
                game.player.baseStats = RPG.Util.DeepCopy(snap.baseStats)
            end

            game.deathSnapshot = nil
            RPG.Combat.StartCombat(player, snap.enemyId)
            return
        end

        if action == "respawn" then
            -- Restore full HP/FP, deduct credits
            game.player.hp = game.player.maxHP
            game.player.fp = game.player.maxFP
            local penalty = math.floor(game.player.credits * RPG.Config.DEATH_CREDIT_PENALTY)
            game.player.credits = game.player.credits - penalty

            game.deathSnapshot = nil
            game.combat = { active = false }

            player:SendPrint("")
            player:SendPrint("^7You awaken in Khoonda, battered but alive.")
            if penalty > 0 then
                player:SendPrint("^3Lost " .. penalty .. " credits.")
            end
            player:SendPrint("")

            RPG.MoveToRoom(player, 1)
            RPG.SetState(player, "exploration")
            return
        end

        if action == "quit" then
            game.deathSnapshot = nil
            RPG.Shutdown(player)
            player:SendPrint("^3RPG session ended. Type ^7!rpg^3 to play again.")
            return
        end
    end,

    controls = "W/S: Browse | USE: Select",
    maxVisibleItems = 5,
})

return true
