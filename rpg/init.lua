-- ============================================
-- ECHOES OF THE DARK WARS
-- A KOTOR-inspired text RPG for Jedi Academy
-- 3949 BBY
-- ============================================
-- Entry point and module loader

RPG = RPG or {}

GLua.Print("========================================")
GLua.Print("Echoes of the Dark Wars - Loading...")
GLua.Print("========================================")

-- Clear cached modules for clean reload
local modules = {
    "rpg.config",
    "rpg.util",
    "rpg.data.abilities",
    "rpg.data.classes",
    "rpg.data.rooms",
    "rpg.data.npcs",
    "rpg.data.items",
    "rpg.data.enemies",
    "rpg.data.quests",
    "rpg.data.dialogues.terena",
    "rpg.data.dialogues.goran",
    "rpg.data.dialogues.atton",
    "rpg.data.dialogues.zhar",
    "rpg.data.dialogues.dorak",
    "rpg.data.dialogues.zherron",
    "rpg.data.dialogues.visquis",
    "rpg.data.dialogues.saevus",
    "rpg.data.dialogues.jeth",
    "rpg.data.dialogues.rila",
    "rpg.data.dialogues.mira",
    "rpg.data.dialogues.saren",
    "rpg.data.dialogues.venn",
    "rpg.data.dialogues.shadow_voice",
    "rpg.data.dialogues.tomb_guardian",
    "rpg.data.dialogues.watcher",
    "rpg.data.dialogues.saevus_manifest",
    "rpg.data.dialogues.saber_assembly",
    "rpg.data.dialogues.karath_vren",
    "rpg.data.dialogues.nemesis",
    "rpg.data.nemesis_data",
    "rpg.data.companions",
    "rpg.data.whispers",
    "rpg.data.vendors",
    "rpg.state",
    "rpg.narrative",
    "rpg.combat",
    "rpg.quest",
    "rpg.dialogue",
    "rpg.whisper",
    "rpg.companion",
    "rpg.stalker",
    "rpg.nemesis",
    "rpg.save",
    "rpg.menus.menu_intro",
    "rpg.menus.menu_class_select",
    "rpg.menus.menu_exploration",
    "rpg.menus.menu_combat",
    "rpg.menus.menu_character",
    "rpg.menus.menu_inventory",
    "rpg.menus.menu_quest_log",
    "rpg.menus.menu_dialogue",
    "rpg.menus.menu_game_over",
    "rpg.menus.menu_datapad_decrypt",
    "rpg.menus.menu_force_vision",
    "rpg.menus.menu_shop",
    "rpg.menus.menu_dream",
    "rpg.menus.menu_victory",
    "rpg.menus.menu_combat_result",
    "rpg.data.cipher",
    "rpg.cipher",
    "rpg.ending",
    "rpg.menus.menu_cipher",
    "rpg.menus.menu_ending",
    "rpg.horror",
    "rpg.menus.menu_glitch",
}

for _, mod in ipairs(modules) do
    package.loaded[mod] = nil
end

-- Load modules in dependency order
local function SafeLoad(path, name)
    local success, err = pcall(function()
        GLua.Include(path)
    end)
    if success then
        GLua.Debug("RPG: Loaded " .. name)
    else
        GLua.Error("RPG: Failed to load " .. name .. ": " .. tostring(err))
    end
    return success
end

-- Core (order matters)
SafeLoad("rpg.config", "Config")
SafeLoad("rpg.util", "Utilities")

-- Data
SafeLoad("rpg.data.abilities", "Ability Data")
SafeLoad("rpg.data.classes", "Class Data")
SafeLoad("rpg.data.rooms", "Room Data")
SafeLoad("rpg.data.npcs", "NPC Data")
SafeLoad("rpg.data.items", "Item Data")
SafeLoad("rpg.data.enemies", "Enemy Data")
SafeLoad("rpg.data.quests", "Quest Data")
SafeLoad("rpg.data.companions", "Companion Data")
SafeLoad("rpg.data.whispers", "Whisper Data")
SafeLoad("rpg.data.vendors", "Vendor Data")
SafeLoad("rpg.data.nemesis_data", "Nemesis Data")
SafeLoad("rpg.data.cipher", "Cipher Data")

-- Systems
SafeLoad("rpg.state", "State Machine")
SafeLoad("rpg.narrative", "Narrative")
SafeLoad("rpg.combat", "Combat Engine")
SafeLoad("rpg.quest", "Quest Engine")
SafeLoad("rpg.dialogue", "Dialogue Engine")
SafeLoad("rpg.whisper", "Whisper Engine")
SafeLoad("rpg.companion", "Companion System")
SafeLoad("rpg.stalker", "Stalker System")
SafeLoad("rpg.nemesis", "Nemesis System")
SafeLoad("rpg.horror", "Horror System")
SafeLoad("rpg.save", "Save System")
SafeLoad("rpg.cipher", "Cipher System")
SafeLoad("rpg.ending", "Ending System")

-- Menus (must load after systems since they reference RPG functions)
SafeLoad("rpg.menus.menu_intro", "Intro Menu")
SafeLoad("rpg.menus.menu_class_select", "Class Select Menu")
SafeLoad("rpg.menus.menu_exploration", "Exploration Menu")
SafeLoad("rpg.menus.menu_combat", "Combat Menu")
SafeLoad("rpg.menus.menu_character", "Character Sheet Menu")
SafeLoad("rpg.menus.menu_stat_allocation", "Stat Allocation Menu")
SafeLoad("rpg.menus.menu_inventory", "Inventory Menu")
SafeLoad("rpg.menus.menu_quest_log", "Quest Log Menu")
SafeLoad("rpg.menus.menu_dialogue", "Dialogue Menu")
SafeLoad("rpg.menus.menu_game_over", "Game Over Menu")
SafeLoad("rpg.menus.menu_datapad_decrypt", "Datapad Decrypt Menu")
SafeLoad("rpg.menus.menu_force_vision", "Force Vision Menu")
SafeLoad("rpg.menus.menu_shop", "Shop Menu")
SafeLoad("rpg.menus.menu_dream", "Dream Menu")
SafeLoad("rpg.menus.menu_victory", "Victory Menu")
SafeLoad("rpg.menus.menu_combat_result", "Combat Result Menu")
SafeLoad("rpg.menus.menu_cipher", "Cipher Menu")
SafeLoad("rpg.menus.menu_ending", "Ending Menu")
SafeLoad("rpg.menus.menu_glitch", "Glitch Burst Menu")

-- ============================================
-- CHAT COMMANDS
-- ============================================

-- O(1) filter on first chat token (set by CmdRouter.PreDispatch).
local RPG_COMMANDS_KNOWN = {
    ["!rpg"] = 1, ["/rpg"] = 1,
    ["!rpgcipher"] = 1, ["!rpgperf"] = 1,
    ["!rpgdebug"] = 1, ["/rpgdebug"] = 1,
}

hook.Add("PlayerSay", "RPG.ChatCommand", function(playerNum, text, teamOnly)
    local routed = CmdRouter and CmdRouter.CurrentCmd
    if not routed or not RPG_COMMANDS_KNOWN[routed] then return end

    local player = Player.Get(playerNum)
    if not player or not player:IsValid() then return end

    local lower = string.lower(text)
    local args = string.Split(lower, " ")

    -- !rpg or /rpg
    if args[1] == "!rpg" or args[1] == "/rpg" then
        -- Subcommands
        if args[2] == "quit" or args[2] == "stop" or args[2] == "exit" then
            if RPG.IsPlaying(player) then
                player:SendPrint("^3RPG session ended. Type ^7!rpg^3 to play again.")
                RPG.Shutdown(player)
            else
                player:SendPrint("^3You're not playing the RPG.")
            end
            return ""
        end

        if args[2] == "save" then
            if not RPG.Save then
                player:SendPrint("^1Save system not loaded.")
                return ""
            end
            if not RPG.IsPlaying(player) then
                player:SendPrint("^3You're not playing the RPG.")
                return ""
            end
            local game = RPG.GetGame(player)
            if not game or not game.player or not game.player.class then
                player:SendPrint("^3Cannot save -- choose a class first.")
                return ""
            end
            local ok, err = RPG.Save.Write(player)
            if ok then
                player:SendPrint("^2Game saved!")
            else
                player:SendPrint("^1Save failed: " .. tostring(err))
            end
            return ""
        end

        if args[2] == "load" then
            if not RPG.Save then
                player:SendPrint("^1Save system not loaded.")
                return ""
            end
            if not RPG.Save.HasSave(player) then
                player:SendPrint("^3No save found.")
                return ""
            end
            -- Confirmation required if already playing
            if RPG.IsPlaying(player) and args[3] ~= "confirm" then
                player:SendPrint("^3This will replace your current session. Type ^7!rpg load confirm^3 to proceed.")
                return ""
            end
            local snapshot, err = RPG.Save.Read(player)
            if not snapshot then
                player:SendPrint("^1Load failed: " .. tostring(err))
                return ""
            end
            local game = RPG.Save.RestoreFromSnapshot(player, snapshot)
            if game then
                local roomName = game.rooms[game.player.currentRoom] and game.rooms[game.player.currentRoom].name or "unknown"
                local className = RPG.Data.Classes[game.player.class] and RPG.Data.Classes[game.player.class].name or game.player.class
                player:SendPrint("^2Save loaded! ^7Level " .. game.player.level .. " " .. className .. " in " .. roomName)
                local restoreState = game.state or "exploration"
                if not RPG.Config.STATE_MENUS[restoreState] then
                    restoreState = "exploration"
                end
                RPG.SetState(player, restoreState)
            else
                player:SendPrint("^1Failed to restore save.")
            end
            return ""
        end

        if args[2] == "new" then
            local clientNum = player:GetClientNum()
            if RPG.IsPlaying(player) then
                RPG.Shutdown(player)
            end
            RPG.players[clientNum] = { state = "intro" }
            if RPG.Save and RPG.Save.CacheKey then
                RPG.Save.CacheKey(player, RPG.players[clientNum])
            end
            RPG.SetState(player, "intro")
            player:SendPrint("^3Starting fresh adventure...")
            return ""
        end

        -- Main command: start or resume
        if RPG.IsPlaying(player) then
            -- Already playing -- reopen current menu
            local game = RPG.GetGame(player)
            if game then
                RPG.SetState(player, game.state)
                player:SendPrint("^3RPG resumed.")
            end
        else
            -- Check for existing save (single Read validates + decodes)
            if RPG.Save then
                local snapshot = RPG.Save.Read(player)
                if snapshot then
                    local hint = ""
                    if snapshot.player then
                        local cls = RPG.Data.Classes[snapshot.player.class]
                        local className = cls and cls.name or snapshot.player.class
                        hint = " (Level " .. (snapshot.player.level or "?") .. " " .. className .. ")"
                    end
                    player:SendPrint("^3Save found" .. hint .. ".")
                    player:SendPrint("^3Type ^7!rpg load^3 to continue or ^7!rpg new^3 for a fresh start.")
                    return ""
                end
            end

            -- No save — start at intro
            RPG.Util.BatchPrint(player, {
                "",
                "^7========================================",
                "^1  ECHOES OF THE DARK WARS",
                "^7  3949 BBY",
                "^7========================================",
                "",
            })

            -- Create a temporary state entry so SetState works
            local clientNum = player:GetClientNum()
            RPG.players[clientNum] = { state = "intro" }
            if RPG.Save and RPG.Save.CacheKey then
                RPG.Save.CacheKey(player, RPG.players[clientNum])
            end
            RPG.SetState(player, "intro")
        end

        return "" -- Suppress chat message
    end

    -- !rpgcipher XXXXXXXXX (Truth ending cipher input)
    if args[1] == "!rpgcipher" then
        if not RPG.Cipher then
            player:SendPrint("^1Cipher system not loaded.")
            return ""
        end
        RPG.Cipher.OnSubmit(player, args[2])
        return ""
    end

    -- !rpgperf -- dump menu perf counters
    if args[1] == "!rpgperf" then
        if Menu and Menu.DumpPerf then
            Menu.DumpPerf(player)
        else
            player:SendPrint("^1Perf system not available")
        end
        return ""
    end

    -- !rpgdebug -- admin debug/testing commands
    if args[1] == "!rpgdebug" or args[1] == "/rpgdebug" then
        -- Permission check: admin 900+
        local perm = 0
        if player.GetPermissionLevel then
            perm = player:GetPermissionLevel() or 0
        end
        if perm < 900 then
            player:SendPrint("^1No permission. Requires admin level 900+.")
            return ""
        end

        local sub = args[2]

        -- Usage help
        if not sub then
            player:SendPrint("^3=== RPG Debug Commands ===")
            player:SendPrint("^7!rpgdebug quickstart <class>")
            player:SendPrint("^7!rpgdebug room <id>")
            player:SendPrint("^7!rpgdebug quest start|stage|complete <id> [stage]")
            player:SendPrint("^7!rpgdebug paranoia|alignment <amount>")
            player:SendPrint("^7!rpgdebug item <id>")
            player:SendPrint("^7!rpgdebug item_remove <id>")
            player:SendPrint("^7!rpgdebug holocron")
            player:SendPrint("^7!rpgdebug flag <name>")
            player:SendPrint("^7!rpgdebug talk <npcId>")
            player:SendPrint("^7!rpgdebug hp|credits <amount>")
            player:SendPrint("^7!rpgdebug companion [id] [blackmail]")
            player:SendPrint("^7!rpgdebug ability <id>")
            player:SendPrint("^7!rpgdebug abilities")
            player:SendPrint("^7!rpgdebug stat <name> <value>")
            player:SendPrint("^7!rpgdebug act2")
            player:SendPrint("^7!rpgdebug act3")
            player:SendPrint("^7!rpgdebug act4")
            player:SendPrint("^7!rpgdebug tombloop")
            player:SendPrint("^7!rpgdebug glitch")
            player:SendPrint("^7!rpgdebug reboot")
            player:SendPrint("^7!rpgdebug cipher")
            player:SendPrint("^7!rpgdebug ending light|dark|horror|truth")
            player:SendPrint("^7!rpgdebug lore <itemId>")
            player:SendPrint("^7!rpgdebug status")
            return ""
        end

        -- Helper: require active session
        local function requireSession()
            local game = RPG.GetGame(player)
            if not game then
                player:SendPrint("^1No active RPG session. Use: !rpgdebug quickstart <class>")
                return nil
            end
            return game
        end

        -- quickstart <class>
        if sub == "quickstart" then
            local classId = args[3]
            if not classId then
                player:SendPrint("^1Usage: !rpgdebug quickstart <class>")
                player:SendPrint("^7Classes: guardian, consular, sentinel, scoundrel, soldier, hunter")
                return ""
            end
            if not RPG.Data.Classes[classId] then
                player:SendPrint("^1Unknown class: " .. classId)
                return ""
            end
            -- Shut down existing session if any
            if RPG.IsPlaying(player) then
                RPG.Shutdown(player)
            end
            local game = RPG.NewGame(player, classId)
            if game then
                RPG.SetState(player, "exploration")
                player:SendPrint("^2[Debug] Quickstart as " .. RPG.Data.Classes[classId].name .. " - now in exploration.")
            else
                player:SendPrint("^1[Debug] Failed to create game.")
            end
            return ""
        end

        -- room <id>
        if sub == "room" then
            local game = requireSession()
            if not game then return "" end
            local roomId = tonumber(args[3])
            if not roomId then
                player:SendPrint("^1Usage: !rpgdebug room <id>")
                return ""
            end
            if not game.rooms[roomId] then
                player:SendPrint("^1Room " .. roomId .. " does not exist.")
                return ""
            end
            -- Route Act 3-5 rooms through MoveToRoom to trigger hooks
            if roomId >= 36 and roomId <= 54 then
                if game.rooms[roomId].locked then
                    game.rooms[roomId].locked = false
                end
                RPG.MoveToRoom(player, roomId)
                player:SendPrint("^2[Debug] Teleported to room " .. roomId .. " (" .. (game.rooms[roomId].name or "?") .. ")")
                return ""
            end
            -- Force move (bypass locks for debug)
            local oldRoom = game.player.currentRoom
            game.player.currentRoom = roomId
            if oldRoom ~= roomId and RPG.Quest and RPG.Quest.OnEvent then
                RPG.Quest.OnEvent(player, "room_enter", { roomId = roomId })
            end
            game.visitedRooms[roomId] = true
            RPG.SetState(player, "exploration")
            player:SendPrint("^2[Debug] Teleported to room " .. roomId .. " (" .. (game.rooms[roomId].name or "?") .. ")")
            return ""
        end

        -- quest start|stage|complete <id> [stage]
        if sub == "quest" then
            local game = requireSession()
            if not game then return "" end
            local action = args[3]
            local questId = args[4]
            if not action or not questId then
                player:SendPrint("^1Usage: !rpgdebug quest start|stage|complete <id> [stage]")
                return ""
            end
            if action == "start" then
                local ok = RPG.Quest.Start(player, questId)
                if ok then
                    player:SendPrint("^2[Debug] Quest '" .. questId .. "' started.")
                else
                    player:SendPrint("^1[Debug] Failed to start quest '" .. questId .. "' (unknown or already started).")
                end
            elseif action == "stage" then
                local stage = args[5]
                if not stage then
                    player:SendPrint("^1Usage: !rpgdebug quest stage <id> <stage>")
                    return ""
                end
                local ok = RPG.Quest.SetStage(player, questId, stage)
                if ok then
                    player:SendPrint("^2[Debug] Quest '" .. questId .. "' -> stage '" .. stage .. "'")
                else
                    player:SendPrint("^1[Debug] Failed to set stage (quest not started or unknown stage).")
                end
            elseif action == "complete" then
                -- Start first if not started (convenience for testing)
                if not game.quests[questId] then
                    RPG.Quest.Start(player, questId)
                end
                local ok = RPG.Quest.Complete(player, questId)
                if ok then
                    player:SendPrint("^2[Debug] Quest '" .. questId .. "' completed.")
                else
                    player:SendPrint("^1[Debug] Failed to complete quest '" .. questId .. "'.")
                end
            else
                player:SendPrint("^1Unknown quest action: " .. action .. ". Use start|stage|complete.")
            end
            return ""
        end

        -- paranoia <amount>
        if sub == "paranoia" then
            local game = requireSession()
            if not game then return "" end
            local amount = tonumber(args[3])
            if not amount then
                player:SendPrint("^1Usage: !rpgdebug paranoia <amount>")
                return ""
            end
            RPG.AddParanoia(player, amount)
            player:SendPrint("^2[Debug] Paranoia now: " .. game.player.paranoia)
            return ""
        end

        -- alignment <amount>
        if sub == "alignment" then
            local game = requireSession()
            if not game then return "" end
            local amount = tonumber(args[3])
            if not amount then
                player:SendPrint("^1Usage: !rpgdebug alignment <amount>")
                return ""
            end
            RPG.AddAlignment(player, amount)
            player:SendPrint("^2[Debug] Alignment now: " .. game.player.alignment)
            return ""
        end

        -- item <id>
        if sub == "item" then
            local game = requireSession()
            if not game then return "" end
            local itemId = tonumber(args[3])
            if not itemId then
                player:SendPrint("^1Usage: !rpgdebug item <id>  (numeric item ID)")
                return ""
            end
            game.player.inventory[#game.player.inventory + 1] = itemId
            local name = RPG.Data.GetItemName and RPG.Data.GetItemName(itemId) or ("Item #" .. itemId)
            player:SendPrint("^2[Debug] Added to inventory: " .. name)
            return ""
        end

        -- item_remove <id>
        if sub == "item_remove" then
            local game = requireSession()
            if not game then return "" end
            local id = tonumber(args[3])
            if not id then
                player:SendPrint("^1Usage: !rpgdebug item_remove <itemId>")
                return ""
            end
            if RPG.Util.Contains(game.player.inventory, id) then
                RPG.Util.RemoveValue(game.player.inventory, id)
                local name = RPG.Data.GetItemName(id)
                player:SendPrint("^3[DEBUG] Removed: " .. (name or ("item " .. id)))
            else
                player:SendPrint("^1Item not in inventory.")
            end
            return ""
        end

        -- holocron
        if sub == "holocron" then
            local game = requireSession()
            if not game then return "" end
            local hid = RPG.Config.HOLOCRON_ITEM_ID
            if not RPG.Util.Contains(game.player.inventory, hid) then
                game.player.inventory[#game.player.inventory + 1] = hid
            end
            game.player.hasHolocron = true
            local name = RPG.Data.GetItemName and RPG.Data.GetItemName(hid) or "Holocron"
            player:SendPrint("^2[Debug] Holocron granted: " .. name .. " (hasHolocron=true)")
            return ""
        end

        -- flag <name>
        if sub == "flag" then
            local game = requireSession()
            if not game then return "" end
            local flagName = args[3]
            if not flagName then
                player:SendPrint("^1Usage: !rpgdebug flag <name>")
                return ""
            end
            RPG.Quest.SetFlag(game, flagName)
            player:SendPrint("^2[Debug] Flag set: " .. flagName)
            return ""
        end

        -- talk <npcId>
        if sub == "talk" then
            local game = requireSession()
            if not game then return "" end
            local npcId = tonumber(args[3])
            if not npcId then
                player:SendPrint("^1Usage: !rpgdebug talk <npcId>  (numeric)")
                player:SendPrint("^7NPCs: 0=Terena 1=Goran 2=Atton 3=Vara 4=Tamas 5=Zherron 6=Draxen")
                player:SendPrint("^7      10=Jeth 11=Mira 12=Saren 13=Rila 14=Venn")
                return ""
            end
            local ok = RPG.Dialogue.Start(player, npcId)
            if ok then
                player:SendPrint("^2[Debug] Started dialogue with NPC " .. npcId)
            else
                player:SendPrint("^1[Debug] Failed to start dialogue with NPC " .. npcId)
            end
            return ""
        end

        -- companion [id] [blackmail]
        if sub == "companion" then
            local game = requireSession()
            if not game then return "" end
            local compId = args[3] or "atton"
            local isBlack = args[4] == "blackmail"
            if not RPG.Companion or not RPG.Companion.Recruit then
                player:SendPrint("^1Companion system not loaded.")
                return ""
            end
            RPG.Companion.Recruit(player, compId, isBlack)
            player:SendPrint("^2[Debug] Companion: " .. compId .. (isBlack and " (blackmailed)" or ""))
            return ""
        end

        -- hp <amount>
        if sub == "hp" then
            local game = requireSession()
            if not game then return "" end
            local amount = tonumber(args[3])
            if not amount then
                player:SendPrint("^1Usage: !rpgdebug hp <amount>")
                return ""
            end
            game.player.hp = amount
            if amount > game.player.maxHP then
                game.player.maxHP = amount
            end
            player:SendPrint("^2[Debug] HP set to " .. game.player.hp .. "/" .. game.player.maxHP)
            return ""
        end

        -- credits <amount>
        if sub == "credits" then
            local game = requireSession()
            if not game then return "" end
            local amount = tonumber(args[3])
            if not amount then
                player:SendPrint("^1Usage: !rpgdebug credits <amount>")
                return ""
            end
            game.player.credits = amount
            player:SendPrint("^2[Debug] Credits set to " .. game.player.credits)
            return ""
        end

        -- ability <id>
        if sub == "ability" then
            local game = requireSession()
            if not game then return "" end
            local abilityId = args[3]
            if not abilityId then
                player:SendPrint("^1Usage: !rpgdebug ability <id>")
                return ""
            end
            if not RPG.Data.Abilities or not RPG.Data.Abilities[abilityId] then
                player:SendPrint("^1Unknown ability: " .. abilityId)
                return ""
            end
            local ok = RPG.GrantAbility(player, abilityId)
            if ok then
                player:SendPrint("^2[Debug] Granted ability: " .. abilityId)
            else
                player:SendPrint("^3[Debug] Already known or failed: " .. abilityId)
            end
            return ""
        end

        -- abilities (list all known)
        if sub == "abilities" then
            local game = requireSession()
            if not game then return "" end
            player:SendPrint("^3=== Known Abilities ===")
            local count = 0
            for abilityId, _ in pairs(game.player.abilitiesKnown) do
                local def = RPG.Data.Abilities and RPG.Data.Abilities[abilityId]
                local name = def and def.name or abilityId
                local tag = def and RPG.Data.GetAbilityDisplayTag(def) or ""
                player:SendPrint("^7  " .. tag .. " " .. name .. " ^8(" .. abilityId .. ")")
                count = count + 1
            end
            if count == 0 then
                player:SendPrint("^8(none)")
            end
            return ""
        end

        -- cipher (bypass)
        if sub == "cipher" then
            local game = requireSession()
            if not game then return "" end
            game.truthUnlocked = true
            if RPG.Quest and RPG.Quest.SetFlag then
                RPG.Quest.SetFlag(game, "truth_unlocked")
            end
            player:SendPrint("^2[Debug] truthUnlocked = true")
            return ""
        end

        -- ending <type>
        if sub == "ending" then
            local game = requireSession()
            if not game then return "" end
            local endingType = args[3]
            if not endingType then
                player:SendPrint("^1Usage: !rpgdebug ending light|dark|horror|truth")
                return ""
            end
            if not RPG.Ending then
                player:SendPrint("^1Ending system not loaded.")
                return ""
            end
            local valid = { light=true, dark=true, horror=true, truth=true }
            if not valid[endingType] then
                player:SendPrint("^1Unknown ending: " .. endingType .. ". Use light|dark|horror|truth")
                return ""
            end
            -- Move to appropriate room first
            local roomMap = { light=51, dark=52, horror=53, truth=54 }
            game.player.currentRoom = roomMap[endingType]
            game.visitedRooms[roomMap[endingType]] = true
            RPG.Ending.Trigger(player, endingType)
            player:SendPrint("^2[Debug] Triggered ending: " .. endingType)
            return ""
        end

        -- lore <itemId>
        if sub == "lore" then
            local game = requireSession()
            if not game then return "" end
            local itemId = tonumber(args[3])
            if not itemId then
                player:SendPrint("^1Usage: !rpgdebug lore <itemId>")
                return ""
            end
            game.loreDiscovered[itemId] = true
            player:SendPrint("^2[Debug] Marked loreDiscovered[" .. itemId .. "] = true")
            if RPG.Cipher then
                player:SendPrint("^7Cipher progress: ^3" .. RPG.Cipher.GetProgressString(game))
            end
            return ""
        end

        -- stat <name> <value>
        if sub == "stat" then
            local game = requireSession()
            if not game then return "" end
            local statName = args[3] and string.upper(args[3]) or nil
            local statVal = tonumber(args[4])
            if not statName or not statVal then
                player:SendPrint("^1Usage: !rpgdebug stat <name> <value>")
                player:SendPrint("^7Stats: STR, DEX, CON, WIS, INT, CHA")
                return ""
            end
            if not game.player.baseStats[statName] then
                player:SendPrint("^1Unknown stat: " .. statName)
                return ""
            end
            game.player.baseStats[statName] = statVal
            RPG.RecalcEffectiveStats(game)
            player:SendPrint("^2[Debug] " .. statName .. " set to " .. game.player.stats[statName] .. " (base=" .. statVal .. ")")
            return ""
        end

        -- act2
        if sub == "act2" then
            local game = requireSession()
            if not game then return "" end
            game.currentAct = 2
            game.player.hasHolocron = true
            game.player.inventory[#game.player.inventory + 1] = RPG.Config.HOLOCRON_ITEM_ID
            -- Unlock ship + wire dynamic exits
            if game.rooms[16] then
                game.rooms[16].locked = false
                game.rooms[16].exits.North = 26
            end
            if game.rooms[26] then game.rooms[26].exits.West = 16 end
            -- Start Q15 at speak_jeth
            RPG.Quest.Start(player, "holocron_unlock")
            RPG.Quest.SetStage(player, "holocron_unlock", "speak_jeth")
            RPG.MoveToRoom(player, 26)
            player:SendPrint("^2[Debug] Skipped to Act 2 — Onderon. Q15 started.")
            return ""
        end

        -- act3
        if sub == "act3" then
            local game = requireSession()
            if not game then return "" end
            RPG.UnlockAct3(player, game)
            RPG.MoveToRoom(player, 36)
            player:SendPrint("^2[Debug] Skipped to Act 3 — Dxun Sith Tomb.")
            return ""
        end

        -- act4
        if sub == "act4" then
            local game = requireSession()
            if not game then return "" end
            RPG.UnlockAct4(player, game)
            RPG.MoveToRoom(player, 43)
            player:SendPrint("^2[Debug] Skipped to Act 4 — The Void.")
            return ""
        end

        -- tombloop
        if sub == "tombloop" then
            local game = requireSession()
            if not game then return "" end
            game.tombLoop = { count = 0, broken = false }
            -- Clear loop descriptions on rooms 37-41
            for rid = 37, 41 do
                if game.rooms[rid] then
                    game.rooms[rid].loopDescription = nil
                end
            end
            -- Reset encounterDefeated on fragment rooms
            for rid = 38, 40 do
                if game.rooms[rid] then
                    game.rooms[rid].encounterDefeated = nil
                end
            end
            RPG.MoveToRoom(player, 37)
            player:SendPrint("^2[Debug] Tomb loop reset. Moved to room 37.")
            return ""
        end

        -- glitch
        if sub == "glitch" then
            local game = requireSession()
            if not game then return "" end
            if RPG.Horror and RPG.Horror.StartGlitchBurst then
                RPG.Horror.StartGlitchBurst(player, { frames = 8 })
                player:SendPrint("^2[Debug] Glitch burst triggered.")
            else
                player:SendPrint("^1Horror system not loaded.")
            end
            return ""
        end

        -- reboot
        if sub == "reboot" then
            local game = requireSession()
            if not game then return "" end
            if RPG.Horror and RPG.Horror.StartFakeReboot then
                RPG.Horror.StartFakeReboot(player, function() end)
                player:SendPrint("^2[Debug] Fake reboot triggered.")
            else
                player:SendPrint("^1Horror system not loaded.")
            end
            return ""
        end

        -- status
        if sub == "status" then
            local game = requireSession()
            if not game then return "" end
            local p = game.player
            player:SendPrint("^3=== RPG Debug Status ===")
            player:SendPrint("^7State: ^3" .. (game.state or "nil"))
            player:SendPrint("^7Class: ^3" .. (p.class or "nil"))
            player:SendPrint("^7Room: ^3" .. p.currentRoom .. " (" .. (game.rooms[p.currentRoom] and game.rooms[p.currentRoom].name or "?") .. ")")
            player:SendPrint("^7HP: ^3" .. p.hp .. "/" .. p.maxHP .. "  ^7FP: ^3" .. p.fp .. "/" .. p.maxFP)
            player:SendPrint("^7Paranoia: ^3" .. p.paranoia .. "  ^7Alignment: ^3" .. p.alignment)
            player:SendPrint("^7Credits: ^3" .. p.credits .. "  ^7Level: ^3" .. p.level .. " (XP " .. p.xp .. "/" .. p.xpToNext .. ")")
            player:SendPrint("^7Holocron: ^3" .. tostring(p.hasHolocron))
            -- Active quests
            local questCount = 0
            for qid, qs in pairs(game.quests) do
                questCount = questCount + 1
                player:SendPrint("^7Quest: ^3" .. qid .. " ^7[" .. qs.status .. "] stage=" .. tostring(qs.stage))
            end
            if questCount == 0 then
                player:SendPrint("^7Quests: ^8(none)")
            end
            -- Flags
            local flagList = {}
            for f, _ in pairs(game.flags) do
                flagList[#flagList + 1] = f
            end
            if #flagList > 0 then
                player:SendPrint("^7Flags: ^3" .. table.concat(flagList, ", "))
            else
                player:SendPrint("^7Flags: ^8(none)")
            end
            player:SendPrint("^7Inventory: ^3" .. #p.inventory .. " items")
            -- Companion
            if p.activeCompanion then
                local comp = p.companions[p.activeCompanion]
                if comp then
                    player:SendPrint("^7Companion: ^3" .. comp.id .. " ^7HP:" .. comp.hp .. "/" .. comp.maxHP .. " trust=" .. (comp.trust or "?") .. (comp.ko and " ^1[KO]" or ""))
                end
            else
                player:SendPrint("^7Companion: ^8(none)")
            end
            -- Abilities
            local abilityNames = {}
            for aid, _ in pairs(p.abilitiesKnown or {}) do
                abilityNames[#abilityNames + 1] = aid
            end
            if #abilityNames > 0 then
                player:SendPrint("^7Abilities: ^3" .. table.concat(abilityNames, ", "))
            else
                player:SendPrint("^7Abilities: ^8(none)")
            end
            return ""
        end

        -- Unknown subcommand
        player:SendPrint("^1Unknown rpgdebug command: " .. tostring(sub))
        player:SendPrint("^7Type ^3!rpgdebug^7 for usage.")
        return ""
    end
end)

-- ============================================
-- DISCONNECT CLEANUP (Bug #9 fix)
-- ============================================

hook.Add("PlayerDisconnect", "RPG.Disconnect", function(playerOrNum)
    -- Normalize: hook may pass player object or clientNum
    local clientNum
    if type(playerOrNum) == "number" then
        clientNum = playerOrNum
    elseif playerOrNum and playerOrNum.GetClientNum then
        clientNum = playerOrNum:GetClientNum()
    else
        return
    end

    local game = RPG.players[clientNum]
    if game then
        GLua.Print("RPG: Player " .. clientNum .. " disconnected, cleaning up")
        if game.combat and game.combat.active then
            GLua.Print("RPG: Player " .. clientNum .. " disconnected during combat")
        end
        -- Auto-save if session has a class (skip pre-game)
        if RPG.Save and game.player and game.player.class and game.saveKey then
            local ok, err = RPG.Save.Write(game)
            if ok then
                GLua.Print("RPG: Auto-saved for " .. (game.playerName or "client " .. clientNum))
            else
                GLua.Warn("RPG: Auto-save failed for client " .. clientNum .. ": " .. tostring(err))
            end
        end
        RPG.Shutdown(clientNum)
    end
end)

-- Validate dialogue trees on load (non-fatal -- timeout won't kill hooks)
if RPG.Dialogue and RPG.Dialogue.ValidateAll then
    local ok, err = pcall(RPG.Dialogue.ValidateAll)
    if not ok then
        GLua.Warn("RPG: Dialogue validation interrupted: " .. tostring(err))
    end
end

-- ============================================
-- READY
-- ============================================

GLua.Print("========================================")
GLua.Print("Echoes of the Dark Wars v" .. (RPG.Config and RPG.Config.VERSION or "???"))
GLua.Print("Type !rpg to begin your journey")
GLua.Print("========================================")

return true
