-- Echoes of the Dark Wars - Exploration Menu
-- Collapsible category UI: exits, NPCs, items, menu
-- Includes Doubt system paranoia effects on the exploration view

RPG = RPG or {}

-- Saevus whispers that can appear in the exploration header
local SAEVUS_WHISPERS = {
    "^1You are not alone here.^7",
    "^1They smile, but they fear you.^7",
    "^1The walls remember what happened here.^7",
    "^1Trust is a weakness they exploit.^7",
    "^1Listen closely. The truth hides in silence.^7",
    "^1You are stronger than them. They know it.^7",
    "^1The light blinds. The dark reveals.^7",
}

-- Scramble a portion of visible text (replaces random words with corrupted versions)
local SCRAMBLE_CHARS = { ".", "-", "~", "#", "?", "*" }
local function ScrambleText(text, chance)
    if not text or chance <= 0 then return text end
    local words = {}
    for word in text:gmatch("%S+") do
        -- Skip color codes
        if word:match("^%^%d") then
            words[#words + 1] = word
        elseif math.random(100) <= (chance * 100) then
            -- Scramble this word
            local scrambled = ""
            for i = 1, math.min(#word, 6) do
                scrambled = scrambled .. SCRAMBLE_CHARS[math.random(#SCRAMBLE_CHARS)]
            end
            words[#words + 1] = "^1" .. scrambled .. "^7"
        else
            words[#words + 1] = word
        end
    end
    return table.concat(words, " ")
end

-- Clamp raw byte length, preventing dangling ^ and color bleed
local function ClampRawLength(text, maxRaw)
    if not text or #text <= maxRaw then return text end
    local clamped = text:sub(1, maxRaw)
    if clamped:sub(-1) == "^" then
        clamped = clamped:sub(1, -2)
    end
    return clamped .. "^7"
end

-- Pick ambient text for current room (safe to call even during combat transitions)
local function PickRoomAmbience(game)
    game.ui = game.ui or {}
    local room = game.rooms[game.player.currentRoom]
    if not room then
        game.ui.currentAmbience = nil
        return
    end

    local p = game.player
    local ambience = room.ambience
    if ambience and p.hasHolocron and p.paranoia >= RPG.Config.PARANOIA_FAKE_NPC
       and room.paranoidAmbience then
        ambience = room.paranoidAmbience
    end
    if RPG.Config.AMBIENCE_TEXT_ENABLED ~= false and ambience and #ambience > 0 then
        game.ui.currentAmbience = ambience[math.random(#ambience)]
    else
        game.ui.currentAmbience = nil
    end
end

-- Play room enter sound (gated: only call in exploration state)
local function PlayRoomSound(player, game)
    if RPG.Config.ROOM_SOUNDS_ENABLED == false then return end
    local room = game.rooms[game.player.currentRoom]
    if not room or not room.sounds or not room.sounds.enter then return end

    local p = game.player
    if room.sounds.requireHolocron and not p.hasHolocron then return end

    game.ui = game.ui or {}
    local now = (Game and Game.GetTime and Game.GetTime())
                or (CurTime and CurTime()) or 0
    if not game.ui.lastEnterSoundAt or (now - game.ui.lastEnterSoundAt > 2000) then
        player:PlaySound(room.sounds.enter)
        game.ui.lastEnterSoundAt = now
        if RPG.Config.DEBUG_SOUNDS then
            GLua.Debug("[RPG Sound] Played: " .. room.sounds.enter .. " in room " .. room.id)
        end
    end
end

-- Corrupt an exit name (visual only -- actual navigation unchanged)
local FAKE_DIRECTIONS = { "Somewhere", "Nowhere", "Deeper", "Away", "The Dark" }
local function CorruptExitName(name)
    if math.random(100) <= 15 then  -- 15% chance per exit
        return "^1" .. FAKE_DIRECTIONS[math.random(#FAKE_DIRECTIONS)] .. "^7"
    end
    return name
end

-- Helper: find first selectable item index (skips action="none" items)
local function FirstSelectable(items)
    for i, item in ipairs(items) do
        if item.action ~= "none" then return i end
    end
    return 1
end

local function GetRoomNarrateTimerName(clientNum)
    return "rpg_room_narrate_" .. tostring(clientNum)
end

local function CancelPendingRoomNarration(player)
    if not player or not player:IsValid() then return end
    local clientNum = player:GetClientNum()
    Timer.Remove(GetRoomNarrateTimerName(clientNum))
end

-- NPC visibility check: some NPCs have conditions for appearing
local function IsNPCVisible(game, npcId)
    -- The Watcher (NPC 23): hidden below paranoia 80
    if npcId == 23 and (not game.player or game.player.paranoia < 80) then
        return false
    end
    return true
end

-- Count items in a category for display in collapsed headers
local function CountCategory(game, room, category)
    local p = game.player
    if category == "exits" then
        local exits = RPG.Util.SortedExits(room.exits)
        return #exits
    elseif category == "people" then
        local count = 0
        if room.npcs then
            for _, npcId in ipairs(room.npcs) do
                if IsNPCVisible(game, npcId) then count = count + 1 end
            end
        end
        if p.hasHolocron and p.paranoia >= RPG.Config.PARANOIA_FAKE_NPC then
            count = count + 1
        end
        return count
    elseif category == "items" then
        if room.items then return #room.items end
        return 0
    end
    return 0
end

-- Build collapsed category items with dynamic counts
local function BuildCollapsedItems(game, room)
    local items = {}

    local exitCount = CountCategory(game, room, "exits")
    items[#items + 1] = {
        label = "^7Exits ^3(" .. exitCount .. ")",
        action = "expand:exits",
    }

    local peopleCount = CountCategory(game, room, "people")
    if peopleCount > 0 then
        items[#items + 1] = {
            label = "^7People ^3(" .. peopleCount .. ")",
            action = "expand:people",
        }
    end

    local itemCount = CountCategory(game, room, "items")
    if itemCount > 0 then
        items[#items + 1] = {
            label = "^7Items ^3(" .. itemCount .. ")",
            action = "expand:items",
        }
    end

    -- Medbay scanner interaction (Room 20, once per visit)
    if room.id == 20 and not room.medUsed then
        items[#items + 1] = {
            label = "^5Use medical scanner",
            action = "medbay_scan",
        }
    end

    -- Bridge dossier (Room 17, nemesis active)
    if room.id == 17 and game.nemesis and game.nemesis.encounter > 0 and not game.nemesis.defeated then
        items[#items + 1] = {
            label = "^5[Inspect Hunter Dossier]",
            action = "nemesis_dossier",
        }
    end

    items[#items + 1] = {
        label = "^7Menu",
        action = "expand:menu",
    }

    return items
end

-- Truncate a label to maxVisible visible chars, respecting color codes
local function TruncateLabel(text, maxVisible)
    maxVisible = maxVisible or 40
    local stripped = RPG.Util.StripColors(text)
    if #stripped <= maxVisible then return text end
    local visible = 0
    local i = 1
    while i <= #text and visible < maxVisible do
        if text:sub(i, i) == "^" and i + 1 <= #text
           and text:sub(i + 1, i + 1):match("[%d%a]") then
            i = i + 2
        else
            visible = visible + 1
            i = i + 1
        end
    end
    return text:sub(1, i - 1) .. "^7.."
end

Menu.Register("rpg_exploration", {
    navigationDebounce = true,     -- leading+trailing edge debounce to reduce CP sends during scroll
    navigationCacheHeader = true,  -- header doesn't change on W/S scroll; enables fast path

    title = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "^1[NO GAME]^7" end

        local room = game.rooms[game.player.currentRoom]
        if not room then return "^1[UNKNOWN LOCATION]^7" end

        return RPG.Config.ROOM_NAME_COLOR .. "=== " .. room.name .. " ===^7"
    end,

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "" end
        game.ui = game.ui or {}

        local p = game.player
        local room = game.rooms[p.currentRoom]
        local lines = {}
        local expanded = state.data and state.data.expanded

        -- Compact HP/FP (one line)
        local hpfp = "^2HP:" .. p.hp .. "/" .. p.maxHP
        if p.maxFP > 0 then
            hpfp = hpfp .. "  ^5FP:" .. p.fp .. "/" .. p.maxFP
        end
        lines[#lines + 1] = hpfp

        -- Companion HP
        if RPG.Companion and RPG.Companion.GetHPLine then
            local compLine = RPG.Companion.GetHPLine(game)
            if compLine then lines[#lines + 1] = compLine end
        end

        -- Saevus whisper injection (paranoia 30+, 1 in 5 chance)
        if p.hasHolocron and p.paranoia >= RPG.Config.PARANOIA_WHISPER_MIN then
            if math.random(5) == 1 then
                lines[#lines + 1] = SAEVUS_WHISPERS[math.random(#SAEVUS_WHISPERS)]
            end
        end

        -- Ambient text only when collapsed (description moved to console via RPG.NarrateRoom)
        -- CACHED: ScrambleText is expensive; recompute only on room change
        if not expanded and room then
            if not game.ui.descCache or game.ui.descCacheRoom ~= p.currentRoom then
                local descLines = {}
                descLines[#descLines + 1] = ""
                local ambLine = game.ui.currentAmbience
                if ambLine then
                    local scrambleChance = 0
                    if p.hasHolocron and p.paranoia >= RPG.Config.PARANOIA_SCRAMBLE_LOW then
                        scrambleChance = 0.10
                        if p.paranoia >= RPG.Config.PARANOIA_SCRAMBLE_HIGH then
                            scrambleChance = 0.60
                        elseif p.paranoia >= RPG.Config.PARANOIA_SCRAMBLE_MED then
                            scrambleChance = 0.30
                        end
                    end
                    if scrambleChance > 0 then
                        ambLine = ScrambleText(ambLine, scrambleChance)
                    end
                    descLines[#descLines + 1] = ClampRawLength(ambLine, 64)
                end
                game.ui.descCache = table.concat(descLines, "\n")
                game.ui.descCacheRoom = p.currentRoom
            end
            lines[#lines + 1] = game.ui.descCache
        end

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return { { label = "^1No active game", action = "none" } } end

        local room = game.rooms[game.player.currentRoom]
        if not room then return { { label = "^1Unknown location", action = "none" } } end

        local expanded = state.data and state.data.expanded

        -- Collapsed view: show category headers with counts
        if not expanded then
            return BuildCollapsedItems(game, room)
        end

        local items = {}
        local p = game.player

        -- Expanded: Exits
        if expanded == "exits" then
            local sortedExits = RPG.Util.SortedExits(room.exits)
            local corruptExits = p.hasHolocron and p.paranoia >= RPG.Config.PARANOIA_EXIT_CORRUPT
            if #sortedExits > 0 then
                for _, e in ipairs(sortedExits) do
                    local targetDef = game.rooms[e.target]
                    local targetName = targetDef and targetDef.name or ("Room " .. e.target)
                    if corruptExits then
                        targetName = CorruptExitName(targetName)
                    end
                    local label = "^7" .. e.dir .. ": ^2" .. targetName
                    items[#items + 1] = {
                        label = TruncateLabel(label, 40),
                        action = "move:" .. e.target,
                    }
                end
            else
                items[#items + 1] = { label = "^8  (no exits)", action = "none" }
            end

        -- Expanded: People
        elseif expanded == "people" then
            local hasNPCs = room.npcs and #room.npcs > 0
            local showFakeNPC = p.hasHolocron and p.paranoia >= RPG.Config.PARANOIA_FAKE_NPC
            if hasNPCs then
                for _, npcId in ipairs(room.npcs) do
                    if IsNPCVisible(game, npcId) then
                        local name = RPG.Data.GetNPCName(npcId, game)
                        local label = RPG.Config.NPC_NAME_COLOR .. "Talk to " .. name
                        items[#items + 1] = {
                            label = TruncateLabel(label, 40),
                            action = "talk:" .. npcId,
                            npcId = npcId,
                        }
                    end
                end
            end
            if showFakeNPC then
                items[#items + 1] = {
                    label = "^1???^7",
                    action = "talk_saevus",
                }
            end
            if #items == 0 then
                items[#items + 1] = { label = "^8  (no one here)", action = "none" }
            end

        -- Expanded: Items
        elseif expanded == "items" then
            if room.items and #room.items > 0 then
                for _, itemId in ipairs(room.items) do
                    local name = RPG.Data.GetItemName(itemId)
                    local label = RPG.Config.ITEM_COLOR .. "Pick up " .. name
                    items[#items + 1] = {
                        label = TruncateLabel(label, 40),
                        action = "pickup:" .. itemId,
                        itemId = itemId,
                    }
                end
            else
                items[#items + 1] = { label = "^8  (nothing here)", action = "none" }
            end

        -- Expanded: Menu
        elseif expanded == "menu" then
            items[#items + 1] = { label = "^7Character Sheet", action = "charsheet" }
            items[#items + 1] = { label = "^7Inventory", action = "inventory" }
            items[#items + 1] = { label = "^7Quest Log", action = "questlog" }
            items[#items + 1] = { label = "^7Read Description", action = "read_desc" }
            items[#items + 1] = { label = "^2Save Game", action = "save_game" }
            if RPG.Save and RPG.Save.HasSave(player) then
                items[#items + 1] = { label = "^3Load Last Save", action = "load_game" }
            end
            items[#items + 1] = { label = "^1Quit to Boot Menu", action = "quit_to_boot" }
        end

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then return end

        -- Expand a category
        if string.StartsWith(action, "expand:") then
            local category = action:sub(#"expand:" + 1)
            state.data.expanded = category
            Menu.InvalidateCache(player)
            local menu = Menu.menus[state.menuId]
            local items = menu.getItems(player, state)
            state.cachedItems = items
            state.cachedItemCount = #items
            state.selection = FirstSelectable(items)
            return
        end

        -- Read full description (manual action)
        if action == "read_desc" then
            game.ui = game.ui or {}
            if game.ui.lastReadDescRoom == game.player.currentRoom then
                player:SendPrint("^8(Already displayed in console)")
            else
                RPG.NarrateRoom(player, game)
                game.ui.lastReadDescRoom = game.player.currentRoom
                game.ui.lastNarratedRoom = game.player.currentRoom
                player:SendPrint("^8(Full description sent to console)")
            end
            return
        end

        -- Medbay scanner (Room 20, heal + flavor)
        if action == "medbay_scan" then
            local room = game.rooms[game.player.currentRoom]
            if room and room.id == 20 and not room.medUsed then
                room.medUsed = true
                game.player.hp = game.player.maxHP
                if game.player.maxFP > 0 then
                    game.player.fp = math.min(game.player.maxFP, game.player.fp + math.floor(game.player.maxFP * 0.5))
                end
                local scanLines = {
                    "",
                    "^8The scanner hums. For a moment, the ship feels almost safe.^7",
                    "^2HP fully restored." .. (game.player.maxFP > 0 and " ^5FP partially restored.^7" or ""),
                }
                if game.player.paranoia > 60 then
                    scanLines[#scanLines + 1] = "^1The readout flickers. For a second, your vitals read as someone else's.^7"
                end
                scanLines[#scanLines + 1] = ""
                RPG.Util.BatchPrint(player, scanLines)
                Menu.InvalidateCache(player)
            end
            return
        end

        -- Hunter dossier (Bridge, Room 17)
        if action == "nemesis_dossier" then
            if RPG.Nemesis and RPG.Nemesis.ShowDossier then
                RPG.Nemesis.ShowDossier(player, game)
            end
            return
        end

        -- Movement: "move:5"
        if string.StartsWith(action, "move:") then
            local roomId = tonumber(action:sub(#"move:" + 1))
            if roomId then
                state.data.expanded = nil
                local moved = RPG.MoveToRoom(player, roomId)
                if moved then
                    game.ui = game.ui or {}
                    game.ui.lastNarratedRoom = game.player.currentRoom
                    PickRoomAmbience(game)  -- always pick (even if combat starts)
                    if game.state == "exploration" then
                        state.selection = 1
                        PlayRoomSound(player, game)
                        Menu.InvalidateCache(player)
                    end
                end
            end
            return
        end

        -- Saevus fake NPC (paranoia 95+)
        if action == "talk_saevus" then
            CancelPendingRoomNarration(player)
            local cn = player:GetClientNum()
            Timer.Remove("rpg_whisper_room_"      .. cn)
            Timer.Remove("rpg_companion_comment_" .. cn)
            -- Saevus monologue -- no physical NPC, just the Holocron
            RPG.Util.BatchPrint(player, {
                "",
                "^1You reach out toward... nothing. There's no one there.",
                "^1But the voice comes anyway.",
                "",
                "^1'You see me now because you're ready to see.'",
                "^1'The others - they're shadows. Echoes of lives",
                "^1that don't matter. Only the Force is real.'",
                "^1'Only power endures.'",
                "",
            })
            -- Try opening Saevus dialogue if available
            if RPG.Data.NPCs[RPG.Config.SAEVUS_NPC_ID] and
               RPG.Data.NPCs[RPG.Config.SAEVUS_NPC_ID].dialogueFile then
                RPG.Dialogue.Start(player, RPG.Config.SAEVUS_NPC_ID)
            end
            return
        end

        -- Talk to NPC: "talk:0"
        if string.StartsWith(action, "talk:") then
            local npcId = tonumber(action:sub(#"talk:" + 1))
            if npcId then
                CancelPendingRoomNarration(player)
                local cn = player:GetClientNum()
                Timer.Remove("rpg_whisper_room_"      .. cn)
                Timer.Remove("rpg_companion_comment_" .. cn)
                RPG.Dialogue.Start(player, npcId)
            end
            return
        end

        -- Pick up item: "pickup:2"
        if string.StartsWith(action, "pickup:") then
            local itemId = tonumber(action:sub(#"pickup:" + 1))
            if itemId then
                local success = RPG.PickupItem(player, itemId)
                if success then
                    -- Auto-collapse if room items are now empty
                    local room = game.rooms[game.player.currentRoom]
                    if not room.items or #room.items == 0 then
                        state.data.expanded = nil
                    end
                    -- Refresh menu
                    if Menu and Menu.InvalidateCache then
                        Menu.InvalidateCache(player)
                    end
                end
            end
            return
        end

        -- Character sheet submenu
        if action == "charsheet" then
            RPG.SetState(player, "character_sheet")
            return
        end

        -- Inventory submenu
        if action == "inventory" then
            RPG.SetState(player, "inventory")
            return
        end

        -- Quest log submenu
        if action == "questlog" then
            RPG.SetState(player, "quest_log")
            return
        end

        -- Manual save
        if action == "save_game" then
            if not RPG.Save then
                player:SendPrint("^1Save system not loaded.")
                return
            end
            local ok, err = RPG.Save.Write(player)
            if ok then
                player:SendPrint("^2Game saved.")
            else
                player:SendPrint("^1Save failed: " .. tostring(err))
            end
            return
        end

        -- Manual load (with confirm)
        if action == "load_game" then
            if not RPG.Save or not RPG.Save.HasSave(player) then
                player:SendPrint("^3No save found.")
                return
            end
            RPG.SetState(player, "confirm", {
                title = "^3=== LOAD SAVE? ===",
                body  = "^3This will discard your current session and load the last save.",
                onConfirm = function(p)
                    local snapshot, err = RPG.Save.Read(p)
                    if not snapshot then
                        p:SendPrint("^1Load failed: " .. tostring(err))
                        RPG.SetState(p, "exploration")
                        return
                    end
                    local g = RPG.Save.RestoreFromSnapshot(p, snapshot)
                    if g then
                        local roomName = g.rooms[g.player.currentRoom] and g.rooms[g.player.currentRoom].name or "?"
                        p:SendPrint("^2Save loaded! ^7Back in " .. roomName)
                        local restoreState = g.state or "exploration"
                        if not RPG.Config.STATE_MENUS[restoreState] then
                            restoreState = "exploration"
                        end
                        RPG.SetState(p, restoreState)
                    else
                        p:SendPrint("^1Failed to restore save.")
                        RPG.SetState(p, "boot")  -- session is nil after RestoreFromSnapshot fail; route to boot
                    end
                end,
                onCancel = function(p)
                    RPG.SetState(p, "exploration")
                end,
            })
            return
        end

        -- Quit to Boot Menu (replaces old Quit RPG)
        if action == "quit_to_boot" then
            -- Autosave first so Quit-to-Boot can't lose unsaved progress
            if RPG.Save and RPG.Save.Write then
                RPG.Save.Write(player)
            end
            RPG.Shutdown(player)
            RPG.SetState(player, "boot")
            return
        end

        -- Legacy Quit action (kept for compat if any other path triggers it)
        if action == "quit" then
            player:SendPrint("^3RPG session ended. Type ^7!rpg^3 to play again.")
            RPG.Shutdown(player)
            return
        end
    end,

    onBack = function(player, state)
        if state.data and state.data.expanded then
            state.data.expanded = nil
            Menu.InvalidateCache(player)
            -- Rebuild cache and reset selection to first selectable item
            local menu = Menu.menus[state.menuId]
            local items = menu.getItems(player, state)
            state.cachedItems = items
            state.cachedItemCount = #items
            state.selection = FirstSelectable(items)
            return true  -- consumed: don't close menu
        end
        return false  -- not expanded: let framework close menu
    end,

    onOpen = function(player, state)
        state.data.expanded = nil
        local game = RPG.GetGame(player)
        if game then
            game.ui = game.ui or {}
            game.ui.descCache = nil
            if game.ui.lastNarratedRoom ~= game.player.currentRoom then
                PickRoomAmbience(game)
                PlayRoomSound(player, game)

                local clientNum = player:GetClientNum()
                local timerName = GetRoomNarrateTimerName(clientNum)
                Timer.Remove(timerName)

                if game.ui.skipAutoNarrationOnce then
                    game.ui.skipAutoNarrationOnce = nil
                    -- Class narration timer will set lastNarratedRoom when it fires.
                    -- Don't set it here — if class timer errors, onOpen will
                    -- correctly re-schedule room narration on next open.
                    return
                end

                local roomAtSchedule = game.player.currentRoom
                Timer.Create(timerName, 1500, 1, function()
                    local p = Player.Get(clientNum)
                    if not p or not p:IsValid() then return end
                    local g = RPG.GetGame(p)
                    if not g then return end
                    RPG.NarrateRoom(p, g)
                    g.ui = g.ui or {}
                    g.ui.lastNarratedRoom = roomAtSchedule
                end)
            end
        end
    end,

    onClose = function(player, state)
        CancelPendingRoomNarration(player)
    end,

    controls = function(player, state)
        if not state.data or not state.data.expanded then
            return "W/S: Nav | USE: Open | ALT: Close"
        end
        if state.data.expanded == "exits" then
            return "W/S: Nav | USE: Go | ALT: Back"
        elseif state.data.expanded == "people" then
            return "W/S: Nav | USE: Talk | ALT: Back"
        elseif state.data.expanded == "items" then
            return "W/S: Nav | USE: Pick up | ALT: Back"
        end
        return "W/S: Nav | USE: Select | ALT: Back"
    end,

    maxVisibleItems = 10,
})

return true
