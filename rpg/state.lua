-- Echoes of the Dark Wars - State Machine
-- Per-player game state and state transitions

RPG = RPG or {}

-- Active game sessions, keyed by clientNum
RPG.players = {}

--- Get active game for a player (or nil)
function RPG.GetGame(player)
    if not player or not player:IsValid() then return nil end
    return RPG.players[player:GetClientNum()]
end

--- Check if player has active RPG session
function RPG.IsPlaying(player)
    return RPG.GetGame(player) ~= nil
end

--- Create a new game for a player with chosen class
function RPG.NewGame(player, classId)
    if not player or not player:IsValid() then return nil end

    local classDef = RPG.Data.Classes[classId]
    if not classDef then
        GLua.Error("RPG.NewGame: Unknown class '" .. tostring(classId) .. "'")
        return nil
    end

    local clientNum = player:GetClientNum()

    -- Build starting inventory from class
    local startInv = {}
    for _, itemId in ipairs(classDef.startingItems) do
        startInv[#startInv + 1] = itemId
    end

    -- Deep copy room data so each player has mutable rooms
    local playerRooms = RPG.Util.CopyRooms(RPG.Data.Rooms)

    local game = {
        state = "exploration",
        previousState = nil,
        currentAct = 1,

        player = {
            class = classId,
            level = 1,
            xp = 0,
            xpToNext = 1 * RPG.Config.XP_PER_LEVEL,
            hp = classDef.hp,
            maxHP = classDef.maxHP,
            fp = classDef.fp,
            maxFP = classDef.maxFP,
            alignment = 0,
            credits = RPG.Config.STARTING_CREDITS,
            paranoia = 0,
            hasHolocron = false,
            holocronLessons = 0,
            baseStats = RPG.Util.DeepCopy(classDef.stats),
            stats = RPG.Util.DeepCopy(classDef.stats),
            inventory = startInv,
            equipped = { weapon = nil, armor = nil, accessory = nil },
            currentRoom = 0,
            companions = {},
            activeCompanion = nil,
            abilitiesKnown = {},
            darkPowerUsed = false,
            echoesFound = {},
            statBoosts = {},
            pendingStatPoints = 0,
        },

        rooms = playerRooms,
        quests = {},
        combat = { active = false, darkAlignmentUsed = 0 },
        stalker = { stage = 0, roomMoves = 0, encounterCount = 0, defeated = false, firstSurvivalDone = false },
        nemesis = nil,  -- initialized by RPG.Nemesis.Roll below
        dialogue = { active = false, npcId = nil, currentNode = 0 },
        visitedRooms = {},
        loreDiscovered = {},
        truthUnlocked = false,
        flags = {},
        saveVersion = 2,
    }

    -- Populate starting abilities from class definition
    if classDef.startingAbilities then
        for _, abilityId in ipairs(classDef.startingAbilities) do
            game.player.abilitiesKnown[abilityId] = true
        end
    end

    -- Awakened (Consular) starts with elevated paranoia
    if classId == "consular" then
        game.player.paranoia = 3
    end

    -- Backward-compat aliases (old code reads questStates/storyFlags)
    game.questStates = game.quests
    game.storyFlags = game.flags

    -- Read proto-game before overwriting (dream choice flags)
    local protoGame = RPG.players[clientNum]

    RPG.players[clientNum] = game

    -- Apply dream choice (embrace = dark side start)
    if protoGame and protoGame.dreamEmbrace then
        game.player.alignment = game.player.alignment - 2
        game.player.paranoia = game.player.paranoia + 3
    end

    -- Auto-equip starter gear (first weapon/armor found)
    for i = #game.player.inventory, 1, -1 do
        local iid = game.player.inventory[i]
        local def = RPG.Data.Items[iid]
        if def and def.slot and not game.player.equipped[def.slot] then
            game.player.equipped[def.slot] = iid
            table.remove(game.player.inventory, i)
        end
    end
    RPG.RecalcEffectiveStats(game)

    -- Roll nemesis
    if RPG.Nemesis and RPG.Nemesis.Roll then
        RPG.Nemesis.Roll(player, game)
    end

    -- Cache save key for disconnect autosave
    if RPG.Save and RPG.Save.CacheKey then
        RPG.Save.CacheKey(player, game)
    end

    GLua.Print("RPG: New game started for " .. player:GetName() .. " as " .. classDef.name)
    return game
end

--- Transition to a new game state (closes current menu, opens new one)
function RPG.SetState(player, newState, data)
    if not player or not player:IsValid() then return end

    local game = RPG.GetGame(player)

    if RPG.Config.DEBUG_STATE_TRANSITIONS then
        GLua.Print("[RPG] State: " .. (game and game.state or "nil") .. " -> " .. newState .. " for " .. player:GetName())
    end

    if not game then
        -- No game yet -- only allow intro/class_select
        if newState ~= "intro" and newState ~= "dream" and newState ~= "class_select" then
            return
        end
    end

    -- Store previous state for back navigation
    if game then
        game.previousState = game.state
        game.state = newState
    end

    -- Look up menu ID for this state
    local menuId = RPG.Config.STATE_MENUS[newState]
    if not menuId then
        GLua.Warn("RPG.SetState: No menu for state '" .. tostring(newState) .. "'")
        return
    end

    -- Open or swap to the new menu
    local menuData = data or {}
    menuData.clientNum = player:GetClientNum()
    if Menu then
        if Menu.SwapMenu and Menu.IsOpen and Menu.IsOpen(player) then
            Menu.SwapMenu(player, menuId, menuData)
        elseif Menu.Open then
            Menu.Open(player, menuId, menuData)
        end
    end

    GLua.Debug("RPG: " .. player:GetName() .. " state -> " .. newState)
end

--- Return to previous state
function RPG.GoBack(player)
    local game = RPG.GetGame(player)
    if not game or not game.previousState then return end
    RPG.SetState(player, game.previousState)
end

--- Shutdown RPG session for a player (cleanup)
function RPG.Shutdown(player)
    if not player then return end

    local clientNum
    if type(player) == "number" then
        clientNum = player
    elseif player.GetClientNum then
        clientNum = player:GetClientNum()
    else
        return
    end

    -- Close menu if open
    if type(player) ~= "number" and player:IsValid() then
        if Menu and Menu.Close then
            Menu.Close(player)
        end
        -- Safety net: ensure player is unfrozen even if Menu.Close failed
        if player.Freeze then
            player:Freeze(false)
        end
    end

    -- Cancel any pending narration/companion timers
    Timer.Remove("rpg_room_narrate_" .. clientNum)
    Timer.Remove("rpg_class_narrate_" .. clientNum)
    Timer.Remove("rpg_companion_comment_" .. clientNum)
    Timer.Remove("rpg_crowd_whisper_" .. clientNum)
    Timer.Remove("rpg_crowd_first_" .. clientNum)
    Timer.Remove("rpg_flash_" .. clientNum)
    Timer.Remove("rpg_combat_result_" .. clientNum)
    Timer.Remove("rpg_whisper_room_" .. clientNum)

    -- Horror system cleanup
    if RPG.Horror and RPG.Horror.Cleanup then
        RPG.Horror.Cleanup(clientNum)
    end

    -- Nemesis system cleanup
    if RPG.Nemesis and RPG.Nemesis.Cleanup then
        RPG.Nemesis.Cleanup(clientNum)
    end

    -- Remove game state
    if RPG.players[clientNum] then
        GLua.Print("RPG: Session ended for client " .. clientNum)
        RPG.players[clientNum] = nil
    end
end

-- Act unlock helpers — callable from quests, dialogue, debug, save restore
-- Idempotent: safe to call multiple times
function RPG.UnlockAct3(player, game)
    if game.currentAct < 3 then
        game.currentAct = 3
    end
    if game.rooms[16] then
        game.rooms[16].exits.East = 36
    end
end

function RPG.UnlockAct4(player, game)
    RPG.UnlockAct3(player, game)  -- ensure Act 3 prerequisites
    if game.currentAct < 4 then
        game.currentAct = 4
    end
    -- Unlock room 43 (Act 4 gate, locked until Shadow Self defeated)
    if game.rooms[43] and game.rooms[43].locked then
        game.rooms[43].locked = false
    end
    if game.rooms[48] then
        game.rooms[48].locked = false
    end
end

--- Move player to a room
function RPG.MoveToRoom(player, roomId)
    local game = RPG.GetGame(player)
    if not game then return false end

    local room = game.rooms[roomId]
    if not room then
        player:SendPrint("^1That path leads nowhere.")
        return false
    end

    -- Dynamic unlock: Room 43 (Act 4 gate) after Shadow Self defeat
    if roomId == 43 and game.flags["shadow_self_defeated"] and room.locked then
        room.locked = false
    end

    -- Check if room is locked
    if room.locked then
        player:SendPrint("^3" .. (room.lockMessage or "That way is blocked."))
        return false
    end

    -- Check item requirement
    if room.requiredItem then
        if not RPG.Util.Contains(game.player.inventory, room.requiredItem) then
            player:SendPrint("^3You need something to get through here.")
            return false
        end
    end

    -- Move
    local oldRoom = game.player.currentRoom

    -- Tomb Loop: intercept BEFORE setting currentRoom
    if RPG.Horror and RPG.Horror.CheckTombLoop then
        if RPG.Horror.CheckTombLoop(player, game, roomId) then
            return true
        end
    end

    -- Act 3 auto-advance + narrative: first entry to room 36
    if roomId == 36 and not game.flags["act3_narrated"] then
        game.flags["act3_narrated"] = true
        RPG.UnlockAct3(player, game)
        if RPG.Horror and RPG.Horror.NarrateAct3Entry then
            RPG.Horror.NarrateAct3Entry(player, game)
        end
    end
    -- Safety net: any Act 3 room auto-advances currentAct
    if roomId >= 36 and roomId <= 42 and game.currentAct < 3 then
        RPG.UnlockAct3(player, game)
    end

    -- Act 4 auto-advance + narrative: first entry to room 43
    if roomId == 43 and not game.flags["act4_narrated"] then
        game.flags["act4_narrated"] = true
        RPG.UnlockAct4(player, game)
        if RPG.Horror and RPG.Horror.NarrateAct4Entry then
            RPG.Horror.NarrateAct4Entry(player, game)
        end
    end
    -- Safety net: any Act 4 room auto-advances currentAct
    if roomId >= 43 and roomId <= 47 and game.currentAct < 4 then
        RPG.UnlockAct4(player, game)
    end

    -- Room 46: Fourth Wall Break trigger (with state guard for finding #3)
    if roomId == 46 and game.state ~= "glitch_burst"
        and game.player.paranoia >= RPG.Config.FOURTH_WALL_PARANOIA
        and not game.flags["fourth_wall_broken"]
        and RPG.Horror and RPG.Horror.FourthWallBreak then
        RPG.Horror.FourthWallBreak(player, game)
    end

    -- Room 47: unlock Act 5 entrance (kept — UnlockAct4 handles room 48 lock,
    -- but this also fires when revisiting room 47 after save/load)
    if roomId == 47 then
        if game.rooms[48] then game.rooms[48].locked = false end
    end

    -- Quest auto-starts: placed BEFORE currentRoom assignment so the quest
    -- is active when room_enter fires (finding 8: event ordering)
    if RPG.Quest and RPG.Quest.Start then
        -- Act 3 quests: first entry to Dxun tomb area
        if roomId == 36 and not game.flags["act3_quests_started"] then
            game.flags["act3_quests_started"] = true
            RPG.Quest.Start(player, "escape_loop")
            RPG.Quest.Start(player, "reassemble_self")
        end
        -- Act 4 quest: metacognition at high paranoia
        if roomId == 46 and game.player.paranoia >= 80
            and not game.quests["echoes_metacognition"] then
            RPG.Quest.Start(player, "echoes_metacognition")
        end
        -- Act 5 quest: echoes_final on entering Hidden Entrance
        if roomId == 48 and not game.flags["act5_quests_started"] then
            game.flags["act5_quests_started"] = true
            RPG.Quest.Start(player, "echoes_final")
        end
        -- Saber construction bootstrap (existing saves)
        if roomId == 9 and not game.quests["saber_construction"]
            and RPG.Util.Contains(game.player.inventory, 4) then
            RPG.Quest.Start(player, "saber_construction")
            if RPG.Util.Contains(game.player.inventory, 5)
                or RPG.Util.Contains(game.player.inventory, 6) then
                RPG.Quest.SetStage(player, "saber_construction", "crystal_found")
            end
            if RPG.Util.Contains(game.player.inventory, 41) then
                local hasCrystal = RPG.Util.Contains(game.player.inventory, 5)
                    or RPG.Util.Contains(game.player.inventory, 6)
                if hasCrystal then
                    RPG.Quest.SetStage(player, "saber_construction", "lens_acquired")
                else
                    RPG.Quest.SetStage(player, "saber_construction", "lens_only")
                end
            end
        end
    end

    -- Fragment pre-combat narration (first visit to fragment rooms)
    if not game.visitedRooms[roomId] then
        if roomId == 38 and room.encounter and not room.encounterDefeated then
            RPG.Util.BatchPrint(player, {
                "",
                "^1The air ignites. A figure erupts from the mural —",
                "^1YOUR face, twisted with rage, screaming wordlessly.",
                "^1RAGE given form. It burns to exist.",
                "",
            })
        elseif roomId == 39 and room.encounter and not room.encounterDefeated then
            RPG.Util.BatchPrint(player, {
                "",
                "^1The dead holocrons shriek in unison. A shape",
                "^1condenses from shadow — you, cowering, shaking,",
                "^1eyes wide with terror. FEAR made manifest.",
                "",
            })
        elseif roomId == 40 and room.encounter and not room.encounterDefeated then
            RPG.Util.BatchPrint(player, {
                "",
                "^1From the bottomless pit, a figure rises slowly.",
                "^1Your face, drained of all light, all hope.",
                "^1DESPAIR given weight. It doesn't want to fight.",
                "^1It just wants you to stop trying.",
                "",
            })
        end
    end

    game.player.currentRoom = roomId

    -- Fire quest event for room entry (only on actual room change)
    if oldRoom ~= roomId and RPG.Quest and RPG.Quest.OnEvent then
        RPG.Quest.OnEvent(player, "room_enter", { roomId = roomId })
    end

    -- Nemesis system first (higher-priority narrative)
    if oldRoom ~= roomId and RPG.Nemesis and RPG.Nemesis.OnRoomMove then
        local handled = RPG.Nemesis.OnRoomMove(player, game, roomId)
        if handled then
            -- Nemesis encounter triggered: skip stalker + follow-up hooks
            game.visitedRooms[roomId] = true
            return true
        end
    end

    -- Stalker system second (only if nemesis didn't handle)
    if oldRoom ~= roomId and RPG.Stalker and RPG.Stalker.OnRoomMove then
        RPG.Stalker.OnRoomMove(player, game, roomId)
    end

    -- Cipher Chamber: auto-transition to cipher_input state
    if roomId == 49 then
        game.visitedRooms[roomId] = true
        RPG.SetState(player, "cipher_input")
        return true
    end

    -- Chamber of Final Choice: wire available ending exits + fallback
    -- RecalcRoom50Exits creates a NEW exits table (room.exits = {...}), so
    -- the shared template table from CopyRooms is replaced, not mutated.
    if roomId == 50 then
        if RPG.Ending and RPG.Ending.RecalcRoom50Exits then
            RPG.Ending.RecalcRoom50Exits(game)
        end
        -- Falls through to normal narration/exploration flow
    end

    -- Ending rooms: trigger ending on entry (Trigger does NOT call MoveToRoom — no recursion)
    if roomId >= 51 and roomId <= 54 then
        game.visitedRooms[roomId] = true
        local endingMap = { [51]="light", [52]="dark", [53]="horror", [54]="truth" }
        if RPG.Ending and RPG.Ending.Trigger then
            RPG.Ending.Trigger(player, endingMap[roomId])
        end
        return true
    end

    -- Check if first visit BEFORE marking (narration uses this)
    local firstVisit = not game.visitedRooms[roomId]

    -- Set lastNarratedRoom immediately so exploration onOpen won't double-narrate
    game.ui = game.ui or {}
    game.ui.lastNarratedRoom = roomId

    -- Defer narration to avoid same-frame burst with centerprint
    -- Mark visitedRooms INSIDE callback so NarrateRoom sees first-visit correctly
    local clientNum = player:GetClientNum()
    Timer.Remove("rpg_room_narrate_" .. clientNum)
    Timer.Create("rpg_room_narrate_" .. clientNum, 500, 1, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local g = RPG.GetGame(p)
        if not g then return end
        RPG.NarrateRoom(p, g)
        g.visitedRooms[roomId] = true
    end)

    -- Reset medbay scanner when leaving ship rooms (entering non-ship room)
    if roomId < 16 or roomId > 25 then
        if game.rooms[20] then
            game.rooms[20].medUsed = nil
        end
    end

    -- Companion ambient: Atton in ship corridor (Room 18)
    if roomId == 18 and game.player.activeCompanion == "atton" then
        local cn = player:GetClientNum()
        Timer.Create("rpg_ship_companion_" .. cn, 1500, 1, function()
            local p = Player.Get(cn)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g or g.player.currentRoom ~= 18 then return end
            local msg = "^6Atton leans against the wall, shuffling pazaak cards. 'Nice ship. Reminds me of a prison transport I was on once. Better food, though.'^7"
            p:SendPrint(msg)
            RPG.Util.TrackPrint(cn, #msg)
        end)
    end

    -- Saevus whisper on room entry (deferred 200ms to avoid same-frame burst with CP)
    if RPG.Whisper and RPG.Whisper.Check then
        local cn = player:GetClientNum()
        Timer.Create("rpg_whisper_room_" .. cn, 1800, 1, function()
            local p = Player.Get(cn)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g then return end
            RPG.Whisper.Check(p, g, "room_enter", { roomId = roomId })
        end)
    end

    -- Companion room commentary
    if RPG.Companion and RPG.Companion.OnRoomEnter then
        RPG.Companion.OnRoomEnter(player, game, roomId)
    end

    -- Corrupted saber whispers (unstable blade in high-paranoia areas)
    if game.player.equipped and game.player.equipped.weapon then
        local weaponDef = RPG.Data.Items[game.player.equipped.weapon]
        if weaponDef and weaponDef.paranoia and game.player.paranoia > 60 then
            if math.random(1, 100) <= 8 then
                local whispers
                if game.currentAct and game.currentAct >= 5 then
                    whispers = {
                        "^1[The blade screams. It knows this place. It was forged here.]",
                        "^1[Saevus's voice, from the blade: '...home...']",
                        "^1[The crystal burns cold against your palm. Rejecting you. Or claiming you.]",
                        "^1[For one heartbeat, the blade's light is red. Then it's not.]",
                    }
                else
                    whispers = {
                        "^1[The blade hums... hungry. It wants to cut more than enemies.]",
                        "^1[The crystal flickers red. Just for a moment. You almost missed it.]",
                        "^1[Saevus's voice, from the blade: '...good...']",
                        "^1[Your hand tightens on the hilt. You didn't tell it to.]",
                    }
                end
                local cnum = player:GetClientNum()
                local msg = whispers[math.random(1, #whispers)]
                Timer.Create("rpg_saber_whisper_" .. cnum, 3000, 1, function()
                    local p = Player.Get(cnum)
                    if not p or not p:IsValid() then return end
                    p:SendPrint(msg)
                    RPG.Util.TrackPrint(cnum, #msg)
                end)
            end
        end
    end

    -- Whispering Crowd: ambient paranoia in Act 2 Iziz rooms
    if RPG.Config.CROWD_WHISPER_ENABLED and roomId >= 26 and roomId <= 35 then
        RPG.StartCrowdWhispers(player, game)
    else
        RPG.StopCrowdWhispers(player)
    end

    -- Force Echo check: discover abilities through Force-sensitive exploration
    if RPG.Config.FORCE_ECHOES and RPG.Data.Classes then
        local cls = RPG.Data.Classes[game.player.class]
        if cls and cls.forceUser then
            for abilityId, echoDef in pairs(RPG.Config.FORCE_ECHOES) do
                if echoDef.room == roomId
                    and not game.player.abilitiesKnown[abilityId]
                    and not game.player.echoesFound[abilityId] then
                    game.player.echoesFound[abilityId] = true

                    -- Force Awakening: first echo for latent Force classes
                    if cls.latentForce and not game.flags.force_awakened then
                        game.flags.force_awakened = true
                        RPG.Util.BatchPrint(player, {
                            "",
                            "^8Something shifts inside you. A door you didn't know existed... opens.",
                            "^8The air tastes different. Colors sharpen. You feel... everything.",
                            "^2[Force Awakened] You sense the Force for the first time.",
                            "",
                        })
                    end

                    local echoLines = {
                        "",
                        "^8================================",
                        "^8The Force surges through this place...",
                        "",
                    }
                    for line in echoDef.text:gmatch("[^\n]+") do
                        echoLines[#echoLines + 1] = line
                    end
                    echoLines[#echoLines + 1] = ""
                    echoLines[#echoLines + 1] = "^8================================"
                    echoLines[#echoLines + 1] = ""
                    RPG.Util.BatchPrint(player, echoLines)
                    RPG.GrantAbility(player, abilityId)
                end
            end
        end
    end

    -- Check for encounter (re-triggers after flee/defeat, cleared on victory)
    if room.encounter and not room.encounterDefeated then
        if RPG.Combat and RPG.Combat.StartCombat then
            RPG.Combat.StartCombat(player, room.encounter)
        else
            GLua.Warn("RPG: Combat module not loaded; encounter skipped for room " .. tostring(roomId))
        end
    end

    -- Horror entry effects (only if no encounter started this room entry)
    -- firstVisit was captured above, before the deferred timer
    if not (room.encounter and not room.encounterDefeated) then
        if RPG.Horror and RPG.Horror.OnRoomEnter then
            RPG.Horror.OnRoomEnter(player, game, roomId, room, firstVisit)
        end
        -- Paranoia glimpse check
        if RPG.Horror and RPG.Horror.CheckGlimpse then
            RPG.Horror.CheckGlimpse(player, game, roomId)
        end
    end

    -- Check for Holocron pickup trigger
    if roomId == 6 and firstVisit then
        -- Crashed ship hold - story moment
        RPG.Util.BatchPrint(player, {
            "",
            "^1The Holocron pulses as you enter. It knows you're here.",
            "^3Something dark stirs in the Force...",
            "",
        })
    end

    -- Boarding the ship completes Act 1 (Act 2 state set in victory CONTINUE handler)
    if roomId == 16 and game.currentAct == 1 then
        RPG.SetState(player, "victory")
        return true
    end

    return true
end

--- Pick up an item from current room
function RPG.PickupItem(player, itemId)
    local game = RPG.GetGame(player)
    if not game then return false end

    local room = game.rooms[game.player.currentRoom]
    if not room then return false end

    -- Check item exists in room
    if not RPG.Util.Contains(room.items, itemId) then
        player:SendPrint("^1That item isn't here.")
        return false
    end

    -- Check inventory space
    if #game.player.inventory >= RPG.Config.MAX_INVENTORY then
        player:SendPrint("^3Your inventory is full.")
        return false
    end

    -- Remove from room, add to inventory
    RPG.Util.RemoveValue(room.items, itemId)
    game.player.inventory[#game.player.inventory + 1] = itemId

    -- Bug #2 fix: check if this is the Holocron
    if itemId == RPG.Config.HOLOCRON_ITEM_ID then
        game.player.hasHolocron = true
        local hLines = {
            "",
            "^1You take the Sith Holocron.",
            "^1It burns cold in your hands. Voices flood your mind.",
            "^1[WHISPER] ...at last... we have been waiting...",
            "",
        }
        -- Paranoia spike
        RPG.AddParanoia(player, 15)

        hLines[#hLines + 1] = "^3You should report back to Administrator Adare."
        RPG.Util.BatchPrint(player, hLines)
    else
        player:SendPrint(RPG.Config.ITEM_COLOR .. "Picked up: " .. RPG.Data.GetItemName(itemId))
    end

    -- Lightsaber quest auto-start
    if RPG.Quest and RPG.Quest.Start then
        if itemId == 4 and not game.quests["saber_construction"] then
            RPG.Quest.Start(player, "saber_construction")
            if RPG.Util.Contains(game.player.inventory, 5)
                or RPG.Util.Contains(game.player.inventory, 6) then
                RPG.Quest.SetStage(player, "saber_construction", "crystal_found")
            end
        end
        if (itemId == 5 or itemId == 6) and not game.quests["saber_construction"]
            and RPG.Util.Contains(game.player.inventory, 4) then
            RPG.Quest.Start(player, "saber_construction")
            RPG.Quest.SetStage(player, "saber_construction", "crystal_found")
        end
    end

    -- Fire quest event for item pickup
    if RPG.Quest and RPG.Quest.OnEvent then
        RPG.Quest.OnEvent(player, "item_pickup", { itemId = itemId })
    end

    -- Saevus whisper on item pickup
    if RPG.Whisper and RPG.Whisper.Check then
        RPG.Whisper.Check(player, game, "item_pickup", { itemId = itemId })
    end

    return true
end

--- Drop an item from inventory by index (places it back in current room)
function RPG.DropItem(player, invIndex)
    local game = RPG.GetGame(player)
    if not game then return false end

    local itemId = game.player.inventory[invIndex]
    if not itemId then return false end

    -- Prevent dropping quest-critical Holocron
    if itemId == RPG.Config.HOLOCRON_ITEM_ID then
        player:SendPrint("^1The Holocron won't let you discard it. It clings to you.")
        return false
    end

    -- Prevent dropping any quest item
    local itemDef = RPG.Data.Items[itemId]
    if itemDef and itemDef.type == "quest" then
        player:SendPrint("^3You can't discard that. It might be important.")
        return false
    end

    -- Remove from inventory
    table.remove(game.player.inventory, invIndex)

    -- Place back in current room
    local room = game.rooms[game.player.currentRoom]
    if room then
        room.items[#room.items + 1] = itemId
    end

    local name = RPG.Data.GetItemName(itemId)
    player:SendPrint("^7Dropped: " .. RPG.Config.ITEM_COLOR .. name)
    return true
end

--- Recalculate effective stats from base + equipped item bonuses (idempotent)
function RPG.RecalcEffectiveStats(game)
    if not game or not game.player then return end
    local base = game.player.baseStats
    if not base then return end

    -- Start from base
    for stat, val in pairs(base) do
        game.player.stats[stat] = val
    end
    -- Add bonuses from all equipped items
    for slot, itemId in pairs(game.player.equipped) do
        if itemId then
            local def = RPG.Data.Items[itemId]
            if def and def.statBonus then
                for stat, bonus in pairs(def.statBonus) do
                    game.player.stats[stat] = (game.player.stats[stat] or 0) + bonus
                end
            end
        end
    end
    -- Add permanent stat boosts from quest rewards
    for stat, bonus in pairs(game.player.statBoosts or {}) do
        game.player.stats[stat] = (game.player.stats[stat] or 0) + bonus
    end
end

--- Equip an item from inventory by inventory index
function RPG.EquipItem(player, invIndex)
    local game = RPG.GetGame(player)
    if not game then return false end

    local itemId = game.player.inventory[invIndex]
    if not itemId then return false end

    local itemDef = RPG.Data.Items[itemId]
    if not itemDef or not itemDef.slot then
        player:SendPrint("^1That item cannot be equipped.")
        return false
    end

    local slot = itemDef.slot

    -- If slot is occupied, move current equipped item back to inventory
    if game.player.equipped[slot] then
        local oldId = game.player.equipped[slot]
        if #game.player.inventory >= RPG.Config.MAX_INVENTORY then
            player:SendPrint("^3Inventory full. Unequip something first.")
            return false
        end
        game.player.inventory[#game.player.inventory + 1] = oldId
        local oldName = RPG.Data.GetItemName(oldId)
        player:SendPrint("^7Unequipped: " .. RPG.Config.ITEM_COLOR .. oldName)
    end

    -- Remove new item from inventory
    table.remove(game.player.inventory, invIndex)
    game.player.equipped[slot] = itemId

    RPG.RecalcEffectiveStats(game)

    local name = RPG.Data.GetItemName(itemId)
    player:SendPrint("^2Equipped: " .. RPG.Config.ITEM_COLOR .. name)
    return true
end

--- Unequip an item from a slot back to inventory
function RPG.UnequipItem(player, slot)
    local game = RPG.GetGame(player)
    if not game then return false end

    local itemId = game.player.equipped[slot]
    if not itemId then
        player:SendPrint("^1Nothing equipped in that slot.")
        return false
    end

    if #game.player.inventory >= RPG.Config.MAX_INVENTORY then
        player:SendPrint("^3Inventory full.")
        return false
    end

    game.player.inventory[#game.player.inventory + 1] = itemId
    game.player.equipped[slot] = nil

    RPG.RecalcEffectiveStats(game)

    local name = RPG.Data.GetItemName(itemId)
    player:SendPrint("^7Unequipped: " .. RPG.Config.ITEM_COLOR .. name)
    return true
end

--- Grant an ability to a player (with narrative unlock text)
function RPG.GrantAbility(player, abilityId)
    local game = RPG.GetGame(player)
    if not game or not game.player then return false end
    if game.player.abilitiesKnown[abilityId] then return false end
    local def = RPG.Data.Abilities and RPG.Data.Abilities[abilityId]
    if not def then return false end
    game.player.abilitiesKnown[abilityId] = true
    local text = def.unlockText or ("^2NEW ABILITY LEARNED: ^7" .. def.name)
    player:SendPrint(text)
    player:PlaySound("sound/weapons/force/heal.wav")
    if Menu and Menu.InvalidateCache then
        Menu.InvalidateCache(player)
    end
    return true
end

-- ============================================
-- WHISPERING CROWD (Act 2 Iziz atmosphere)
-- ============================================

local CROWD_WHISPERS = {
    "^8[The crowd parts around you. They're all staring.]",
    "^8[Someone in the crowd whispers your name.]",
    "^8[You see yourself in the crowd. Your reflection nods at you.]",
    "^8[Everyone stops moving. For just a moment. Then they continue.]",
    "^8[A child points at you. Her mother pulls her away, terrified.]",
    "^8[Conversations die as you pass. Resume after you're gone.]",
    "^8[Two guards exchange glances. One touches his blaster.]",
    "^8[The Holocron hums warmly. It enjoys the attention.]",
}

function RPG.StartCrowdWhispers(player, game)
    local clientNum = player:GetClientNum()
    local timerName = "rpg_crowd_whisper_" .. clientNum
    Timer.Remove(timerName)

    -- Quick first whisper (8s) to establish atmosphere on entry
    Timer.Create("rpg_crowd_first_" .. clientNum, 8000, 1, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local g = RPG.GetGame(p)
        if not g then return end
        local rm = g.player.currentRoom
        if rm >= 26 and rm <= 35 and math.random(100) <= 50 then
            p:SendPrint(CROWD_WHISPERS[math.random(1, #CROWD_WHISPERS)])
        end
    end)

    -- Recurring timer
    Timer.Create(timerName, RPG.Config.CROWD_WHISPER_INTERVAL, 0, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then Timer.Remove(timerName); return end
        local g = RPG.GetGame(p)
        if not g then Timer.Remove(timerName); return end
        local rm = g.player.currentRoom
        if rm < 26 or rm > 35 then Timer.Remove(timerName); return end

        if math.random(100) <= RPG.Config.CROWD_WHISPER_CHANCE then
            p:SendPrint(CROWD_WHISPERS[math.random(1, #CROWD_WHISPERS)])
        end

        -- Infected inventory: Holocron asserts dominance (very rare)
        -- Skip if player is in inventory/shop menu to avoid pendingAction desync
        local state = g.state
        if state ~= "inventory" and state ~= "shop"
            and g.player.hasHolocron and math.random(100) == 1 then
            local inv = g.player.inventory
            local hIdx = nil
            for i, itemId in ipairs(inv) do
                if itemId == RPG.Config.HOLOCRON_ITEM_ID then hIdx = i; break end
            end
            if hIdx and hIdx > 1 then
                table.remove(inv, hIdx)
                table.insert(inv, 1, RPG.Config.HOLOCRON_ITEM_ID)
                p:SendPrint("")
                p:SendPrint("^1[SYSTEM WARNING] Unauthorized equipment change detected.")
                p:SendPrint("^8The Holocron is in the first slot. You didn't put it there.")
                p:SendPrint("")
            end
        end
    end)
end

function RPG.StopCrowdWhispers(player)
    local cn = player:GetClientNum()
    Timer.Remove("rpg_crowd_whisper_" .. cn)
    Timer.Remove("rpg_crowd_first_" .. cn)
end

--- Use a consumable item outside combat
function RPG.UseItem(player, invIndex)
    local game = RPG.GetGame(player)
    if not game then return false end

    local itemId = game.player.inventory[invIndex]
    if not itemId then return false end

    local itemDef = RPG.Data.Items[itemId]
    if not itemDef then return false end

    -- Healing items
    if itemDef.healAmount and itemDef.healAmount > 0 then
        if game.player.hp >= game.player.maxHP then
            player:SendPrint("^3Already at full health.")
            return false
        end

        local oldHP = game.player.hp
        game.player.hp = math.min(game.player.hp + itemDef.healAmount, game.player.maxHP)
        local healed = game.player.hp - oldHP

        -- Consume item
        table.remove(game.player.inventory, invIndex)

        player:SendPrint("^2Used " .. itemDef.name .. ": +" .. healed .. " HP ^7(" .. game.player.hp .. "/" .. game.player.maxHP .. ")")

        -- Note if item also has combat-only effects
        if itemDef.damageBonus then
            player:SendPrint("^8(Damage boost has no effect outside combat)")
        end

        -- Paranoia side effect (Sliced Stim)
        if itemDef.paranoia then
            RPG.AddParanoia(player, itemDef.paranoia)
        end

        return true
    end

    -- Combat-only items (damageBonus, curePoison, applyPoison without healAmount)
    if itemDef.damageBonus or itemDef.curePoison or itemDef.applyPoison then
        player:SendPrint("^3That item can only be used in combat.")
        return false
    end

    player:SendPrint("^3That item can't be used.")
    return false
end

return true
