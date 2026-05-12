-- Echoes of the Dark Wars - Victory Menu
-- Act 1 completion screen with stats summary + Act 2 transition

RPG = RPG or {}

Menu.Register("rpg_victory", {
    title = "^3=== ACT 1 COMPLETE ===^7",
    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "" end
        local p = game.player
        local completed, total = 0, 0
        for _, qs in pairs(game.quests) do
            total = total + 1
            if qs.status == "completed" then completed = completed + 1 end
        end
        local alignLabel = "^7Neutral"
        if p.alignment >= 30 then alignLabel = "^5Light Side"
        elseif p.alignment <= -30 then alignLabel = "^1Dark Side" end
        local paranoiaLine = "^7The stars are silent as you jump to hyperspace."
        if p.paranoia >= 70 then
            paranoiaLine = "^1The stars look like eyes. You are not alone."
        elseif p.paranoia >= 30 then
            paranoiaLine = "^3The Holocron whispers unwanted coordinates."
        end
        local cls = RPG.Data.Classes[p.class]
        local lines = {
            "^7You leave Dantooine behind.",
            "^7The Holocron hums, whispers growing louder.",
            "",
            "^3Destination: Onderon.",
            "^3--- Journey Summary ---",
            "^7Class: ^3" .. (cls and cls.name or p.class) .. "  ^7Level: ^3" .. p.level,
            "^7Credits: ^3" .. p.credits .. "  ^7Quests: ^3" .. completed .. "/" .. total,
            "^7Alignment: " .. alignLabel .. "  ^7Paranoia: ^3" .. p.paranoia,
            paranoiaLine,
            "",
            "^3The Wanderer drops out of hyperspace.",
            "^3Onderon fills the viewport. Iziz awaits.",
        }
        return table.concat(lines, "\n")
    end,
    getItems = function(player, state)
        return {
            { label = "^3>>> CONTINUE TO ONDERON >>>", action = "continue" },
        }
    end,
    onAction = function(player, action, state, selectedItem)
        if action == "continue" then
            local game = RPG.GetGame(player)
            if not game then return end

            -- Atomic Act 2 state mutation
            game.currentAct = 2
            game.player.currentRoom = 26

            -- Hyperspace transition narrative
            player:SendPrint("")
            player:SendPrint("^3========================================")
            player:SendPrint("^7  The Wanderer shudders as it exits hyperspace.")
            player:SendPrint("^7  Onderon's walled city stretches below --")
            player:SendPrint("^7  ancient stone meets durasteel spires.")
            player:SendPrint("^7  Iziz Spaceport Control crackles over comms:")
            player:SendPrint("^3  'Unregistered freighter, you are cleared")
            player:SendPrint("^3   for Landing Pad Alpha. Do not deviate.'")
            player:SendPrint("")
            player:SendPrint("^1  The Holocron pulses once. It knows this place.")
            player:SendPrint("^3========================================")
            player:SendPrint("")
            player:SendPrint("^5  Reports reach you in transit: the Jedi")
            player:SendPrint("^5  Shadow's body has vanished from the crash")
            player:SendPrint("^5  site. The containment team found an empty")
            player:SendPrint("^5  hold and claw marks on the walls.")
            player:SendPrint("")

            -- Wire ship↔Onderon exits now that Act 2 is active
            if game.rooms[16] then game.rooms[16].exits.North = 26 end
            if game.rooms[26] then game.rooms[26].exits.West = 16 end

            RPG.SetState(player, "exploration")
        end
    end,
    onBack = function(player, state)
        return true  -- Must press CONTINUE
    end,
    controls = "USE: Continue",
    maxVisibleItems = 4,
})

return true
