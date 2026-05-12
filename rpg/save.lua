-- Echoes of the Dark Wars - Save/Load System
-- Persists player progress to JSON files via File API

RPG = RPG or {}
RPG.Save = {}

local SAVE_DIR = "glua/data/rpg_saves/"
local SAVE_VERSION = 2

-- ============================================
-- PLAYER IDENTIFICATION
-- ============================================

--- Build a unique key for a player (accountId > GUID fallback)
function RPG.Save.GetPlayerKey(player)
    if not player or not player.IsValid or not player:IsValid() then
        return nil
    end

    local accountId = player:GetAccountId()
    if accountId and accountId > 0 then
        return "acct_" .. accountId
    end

    -- Fallback to GUID hash (mirrors player_settings.lua pattern)
    local guid = player.GetGUID and player:GetGUID() or nil
    if guid and guid ~= "" then
        local hash = 0
        for i = 1, #guid do
            hash = (hash * 31 + string.byte(guid, i)) % 2147483647
        end
        return "guid_" .. hash
    end

    return nil
end

--- Cache the save key into a game table (for disconnect autosave)
function RPG.Save.CacheKey(player, game)
    if not game then return end
    local key = RPG.Save.GetPlayerKey(player)
    if key then
        game.saveKey = key
    end
end

-- ============================================
-- HELPERS
-- ============================================

--- Convert string-numeric keys back to numeric (non-recursive).
--- JSON encodes numeric table keys as strings; this reverses that.
function RPG.Save.RehydrateKeys(tbl)
    if type(tbl) ~= "table" then return tbl end
    local fixups = {}
    for k, v in pairs(tbl) do
        if type(k) == "string" then
            local n = tonumber(k)
            if n then
                fixups[#fixups + 1] = { old = k, new = n, val = v }
            end
        end
    end
    for _, fix in ipairs(fixups) do
        tbl[fix.old] = nil
        tbl[fix.new] = fix.val
    end
    return tbl
end

--- Get save file path for a player key
local function SavePath(playerKey)
    return SAVE_DIR .. playerKey .. ".json"
end

--- Get GUID-based key for a player (for migration check)
local function GetGuidKey(player)
    if not player or not player.IsValid or not player:IsValid() then
        return nil
    end
    local guid = player.GetGUID and player:GetGUID() or nil
    if guid and guid ~= "" then
        local hash = 0
        for i = 1, #guid do
            hash = (hash * 31 + string.byte(guid, i)) % 2147483647
        end
        return "guid_" .. hash
    end
    return nil
end

-- ============================================
-- SNAPSHOT BUILDING
-- ============================================

--- Build a serializable snapshot from a game session
function RPG.Save.BuildSnapshot(game)
    if not game or not game.player or not game.player.class then
        return nil
    end

    local p = game.player

    -- Build room deltas: only rooms that differ from pristine defaults
    local roomDeltas = {}
    if game.rooms then
        local defaultRooms = RPG.Data and RPG.Data.Rooms or {}
        for roomId, room in pairs(game.rooms) do
            local def = defaultRooms[roomId]
            local delta = nil

            -- Check items difference
            local itemsDiffer = false
            if def then
                local defItems = def.items or {}
                local curItems = room.items or {}
                if #defItems ~= #curItems then
                    itemsDiffer = true
                else
                    for i = 1, #defItems do
                        if defItems[i] ~= curItems[i] then
                            itemsDiffer = true
                            break
                        end
                    end
                end
            else
                -- Room doesn't exist in defaults — save if has items
                if room.items and #room.items > 0 then
                    itemsDiffer = true
                end
            end

            -- Check encounterDefeated
            local encDiff = (room.encounterDefeated == true) and (not def or not def.encounterDefeated)

            -- Check locked status change
            local lockDiff = false
            if def then
                local defLocked = def.locked or false
                local curLocked = room.locked or false
                if defLocked ~= curLocked then
                    lockDiff = true
                end
            end

            if itemsDiffer or encDiff or lockDiff then
                delta = {}
                if itemsDiffer then
                    local items = {}
                    for i = 1, #(room.items or {}) do
                        items[i] = room.items[i]
                    end
                    delta.items = items
                end
                if encDiff then
                    delta.encounterDefeated = true
                end
                if lockDiff then
                    delta.locked = room.locked or false
                end
                roomDeltas[roomId] = delta
            end
        end
    end

    local snapshot = {
        saveVersion = SAVE_VERSION,
        savedAt = os.time(),
        playerName = game.playerName or "",

        player = {
            class = p.class,
            level = p.level,
            xp = p.xp,
            xpToNext = p.xpToNext,
            hp = p.hp,
            maxHP = p.maxHP,
            fp = p.fp,
            maxFP = p.maxFP,
            alignment = p.alignment,
            paranoia = p.paranoia,
            credits = p.credits,
            hasHolocron = p.hasHolocron,
            holocronLessons = p.holocronLessons,
            darkPowerUsed = p.darkPowerUsed,
            currentRoom = p.currentRoom,
            activeCompanion = p.activeCompanion,
            baseStats = RPG.Util.DeepCopy(p.baseStats),
            inventory = RPG.Util.DeepCopy(p.inventory),
            equipped = RPG.Util.DeepCopy(p.equipped),
            abilitiesKnown = RPG.Util.DeepCopy(p.abilitiesKnown),
            echoesFound = RPG.Util.DeepCopy(p.echoesFound),
            companions = RPG.Util.DeepCopy(p.companions),
            statBoosts = RPG.Util.DeepCopy(p.statBoosts or {}),
        },

        quests = RPG.Util.DeepCopy(game.quests),
        flags = RPG.Util.DeepCopy(game.flags),
        visitedRooms = RPG.Util.DeepCopy(game.visitedRooms),
        loreDiscovered = RPG.Util.DeepCopy(game.loreDiscovered or {}),
        truthUnlocked = game.truthUnlocked or false,
        currentAct = game.currentAct or 1,
        stalker = RPG.Util.DeepCopy(game.stalker or {}),
        nemesis = RPG.Util.DeepCopy(game.nemesis or {}),
        vendorStock = RPG.Util.DeepCopy(game.vendorStock or {}),
        tombLoop = RPG.Util.DeepCopy(game.tombLoop or {}),
        fragmentDrain = RPG.Util.DeepCopy(game.fragmentDrain or {}),
        roomDeltas = roomDeltas,
    }

    return snapshot
end

-- ============================================
-- VALIDATION
-- ============================================

--- Validate a decoded snapshot has required shape
function RPG.Save.ValidateSnapshot(snapshot)
    if type(snapshot) ~= "table" then
        return false, "snapshot is not a table"
    end
    if not snapshot.saveVersion or type(snapshot.saveVersion) ~= "number" then
        return false, "missing or invalid saveVersion"
    end
    if snapshot.saveVersion ~= SAVE_VERSION then
        local direction = snapshot.saveVersion < SAVE_VERSION and "outdated" or "newer than supported"
        return false, "save version " .. snapshot.saveVersion .. " is " .. direction .. " (expected " .. SAVE_VERSION .. ")"
    end
    if type(snapshot.player) ~= "table" then
        return false, "missing player data"
    end
    if type(snapshot.player.class) ~= "string" then
        return false, "missing player class"
    end
    if not RPG.Data or not RPG.Data.Classes or not RPG.Data.Classes[snapshot.player.class] then
        return false, "unknown class: " .. tostring(snapshot.player.class)
    end
    return true, nil
end

-- ============================================
-- WRITE
-- ============================================

--- Low-level: write raw JSON string to a specific path
function RPG.Save.WriteToPath(path, jsonString)
    if not File or not File.Write then
        return false, "File.Write not available"
    end
    local ok, err = File.Write(path, jsonString)
    if not ok then
        return false, "File.Write failed: " .. tostring(err)
    end
    return true, nil
end

--- Write save for a player or game table
--- Accepts either a player object or a game table (for disconnect autosave via game.saveKey)
function RPG.Save.Write(playerOrGame)
    if not File or not File.Write then
        return false, "File.Write not available"
    end

    local game
    local saveKey

    -- Determine if we got a player object or a game table
    if type(playerOrGame) == "table" and playerOrGame.player then
        -- It's a game table directly
        game = playerOrGame
        saveKey = game.saveKey
    elseif playerOrGame and playerOrGame.GetClientNum then
        -- It's a player object
        local clientNum = playerOrGame:GetClientNum()
        game = RPG.players[clientNum]
        if game then
            saveKey = game.saveKey or RPG.Save.GetPlayerKey(playerOrGame)
        end
    end

    if not game then
        return false, "no active game session"
    end
    if not game.player or not game.player.class then
        return false, "no class selected yet"
    end
    if not saveKey then
        return false, "no player identity available"
    end

    -- Store player name for display in save-found prompt
    if playerOrGame and playerOrGame.GetName then
        game.playerName = playerOrGame:GetName()
    end

    local snapshot = RPG.Save.BuildSnapshot(game)
    if not snapshot then
        return false, "failed to build snapshot"
    end

    local ok, jsonStr = pcall(json.encode, snapshot)
    if not ok or not jsonStr then
        return false, "JSON encode failed: " .. tostring(jsonStr)
    end

    local path = SavePath(saveKey)
    return RPG.Save.WriteToPath(path, jsonStr)
end

-- ============================================
-- READ
-- ============================================

--- Read and decode save file for a player (with GUID migration)
function RPG.Save.Read(player)
    if not File or not File.Read then
        return nil, "File.Read not available"
    end

    local primaryKey = RPG.Save.GetPlayerKey(player)
    local content
    local fromGuid = false

    -- Try primary key first
    if primaryKey then
        content = File.Read(SavePath(primaryKey))
    end

    -- GUID fallback (migration happens AFTER validation)
    if not content or content == "" then
        local guidKey = GetGuidKey(player)
        if guidKey and guidKey ~= primaryKey then
            content = File.Read(SavePath(guidKey))
            if content and content ~= "" then
                fromGuid = true
            end
        end
    end

    if not content or content == "" then
        return nil, "no save file found"
    end

    local ok, snapshot = pcall(json.decode, content)
    if not ok or not snapshot then
        return nil, "corrupted save data: " .. tostring(snapshot)
    end

    local valid, err = RPG.Save.ValidateSnapshot(snapshot)
    if not valid then
        return nil, "invalid save: " .. tostring(err)
    end

    -- Migrate GUID save to account key only after successful validation
    if fromGuid and primaryKey then
        local guidKey = GetGuidKey(player)
        if guidKey and primaryKey ~= guidKey then
            RPG.Save.WriteToPath(SavePath(primaryKey), content)
            GLua.Print("RPG.Save: Migrated save from " .. guidKey .. " to " .. primaryKey)
        end
    end

    return snapshot, nil
end

--- Check if a valid save exists for a player (decodes + validates)
function RPG.Save.HasSave(player)
    local snapshot, _ = RPG.Save.Read(player)
    return snapshot ~= nil
end

-- ============================================
-- RESTORE
-- ============================================

--- Restore a game session from a validated snapshot
function RPG.Save.RestoreFromSnapshot(player, snapshot)
    if not player or not player:IsValid() then return nil end

    local clientNum = player:GetClientNum()

    -- Cleanup existing session if any
    if RPG.players[clientNum] then
        RPG.Shutdown(player)
    end

    -- Rehydrate numeric keys from JSON string conversion
    snapshot.roomDeltas = RPG.Save.RehydrateKeys(snapshot.roomDeltas or {})
    snapshot.visitedRooms = RPG.Save.RehydrateKeys(snapshot.visitedRooms or {})
    snapshot.loreDiscovered = RPG.Save.RehydrateKeys(snapshot.loreDiscovered or {})
    if snapshot.vendorStock then
        snapshot.vendorStock = RPG.Save.RehydrateKeys(snapshot.vendorStock)
        -- Also rehydrate inner vendor tables (keyed by npcId)
        for npcId, stock in pairs(snapshot.vendorStock) do
            if type(stock) == "table" then
                -- stock/hostileStock/hiddenStock are arrays — no rehydration needed
                -- but the outer vendorStock keys (npcIds) were already fixed above
            end
        end
    end

    -- Create clean baseline from NewGame (gets all defaults, aliases, future fields)
    local game = RPG.NewGame(player, snapshot.player.class)
    if not game then
        return nil
    end

    local sp = snapshot.player

    -- Overlay scalar player fields
    game.player.level = sp.level or 1
    game.player.xp = sp.xp or 0
    -- Derive xpToNext from level (never trust snapshot — allows tuning changes)
    game.player.xpToNext = game.player.level * RPG.Config.XP_PER_LEVEL
    game.player.hp = sp.hp or game.player.hp
    game.player.maxHP = sp.maxHP or game.player.maxHP
    game.player.fp = sp.fp or game.player.fp
    game.player.maxFP = sp.maxFP or game.player.maxFP
    game.player.alignment = sp.alignment or 0
    game.player.paranoia = sp.paranoia or 0
    game.player.credits = sp.credits or RPG.Config.STARTING_CREDITS
    game.player.hasHolocron = sp.hasHolocron or false
    game.player.holocronLessons = sp.holocronLessons or 0
    game.player.darkPowerUsed = sp.darkPowerUsed or false
    game.player.activeCompanion = sp.activeCompanion

    -- Validate currentRoom exists in room data
    if sp.currentRoom and game.rooms[sp.currentRoom] then
        game.player.currentRoom = sp.currentRoom
    else
        GLua.Warn("RPG.Save: Room " .. tostring(sp.currentRoom) .. " no longer exists, defaulting to room 0")
        game.player.currentRoom = 0
    end

    -- Overlay complex player fields (before stat recalc)
    if sp.baseStats then
        game.player.baseStats = RPG.Util.DeepCopy(sp.baseStats)
    end
    if sp.inventory then
        game.player.inventory = RPG.Util.DeepCopy(sp.inventory)
    end
    if sp.equipped then
        game.player.equipped = RPG.Util.DeepCopy(sp.equipped)
    end
    if sp.abilitiesKnown then
        game.player.abilitiesKnown = RPG.Util.DeepCopy(sp.abilitiesKnown)
    end
    if sp.echoesFound then
        game.player.echoesFound = RPG.Util.DeepCopy(sp.echoesFound)
    end
    if sp.statBoosts then
        game.player.statBoosts = RPG.Util.DeepCopy(sp.statBoosts)
    end
    if sp.companions then
        game.player.companions = RPG.Util.DeepCopy(sp.companions)
        -- Clear KO state on restore (combat isn't active on load)
        for _, comp in pairs(game.player.companions) do
            if comp.ko then
                comp.ko = false
                comp.hp = math.max(comp.hp, 1)
            end
        end
    end

    -- Rebuild stats from baseStats + equipment
    for stat, val in pairs(game.player.baseStats) do
        game.player.stats[stat] = val
    end
    RPG.RecalcEffectiveStats(game)

    -- Nil-safe normalize before overlay
    snapshot.quests = snapshot.quests or {}
    snapshot.flags = snapshot.flags or {}
    snapshot.visitedRooms = snapshot.visitedRooms or {}
    snapshot.loreDiscovered = snapshot.loreDiscovered or {}
    snapshot.stalker = snapshot.stalker or {}
    snapshot.vendorStock = snapshot.vendorStock or {}

    -- Overlay game-level state
    game.quests = RPG.Util.DeepCopy(snapshot.quests)
    game.flags = RPG.Util.DeepCopy(snapshot.flags)
    game.visitedRooms = RPG.Util.DeepCopy(snapshot.visitedRooms)
    game.loreDiscovered = RPG.Util.DeepCopy(snapshot.loreDiscovered)
    game.truthUnlocked = snapshot.truthUnlocked or false
    game.currentAct = snapshot.currentAct or 1
    game.stalker = RPG.Util.DeepCopy(snapshot.stalker)
    game.nemesis = RPG.Util.DeepCopy(snapshot.nemesis or {})
    game.vendorStock = RPG.Util.DeepCopy(snapshot.vendorStock)
    game.tombLoop = RPG.Util.DeepCopy(snapshot.tombLoop or {})
    game.fragmentDrain = RPG.Util.DeepCopy(snapshot.fragmentDrain or {})

    -- Rebind backward-compat aliases (NewGame set them, but overlay replaced the tables)
    game.questStates = game.quests
    game.storyFlags = game.flags

    -- Recovery: old saves with atton_companion/atton_blackmailed flag but no companion entity
    if RPG.Companion and RPG.Companion.Recruit then
        local hasEntity = game.player.companions and game.player.companions["atton"]
        if not hasEntity then
            if game.flags["atton_blackmailed"] then
                RPG.Companion.Recruit(player, "atton", true)
            elseif game.flags["atton_companion"] then
                RPG.Companion.Recruit(player, "atton", false)
            end
        end
    end

    -- Apply room deltas
    for roomId, delta in pairs(snapshot.roomDeltas) do
        local room = game.rooms[roomId]
        if room then
            if delta.items then
                room.items = RPG.Util.DeepCopy(delta.items)
            end
            if delta.encounterDefeated ~= nil then
                room.encounterDefeated = delta.encounterDefeated
            end
            if delta.locked ~= nil then
                room.locked = delta.locked
            end
        else
            GLua.Warn("RPG.Save: Skipping delta for unknown room " .. tostring(roomId))
        end
    end

    -- Restore dynamic exits for Act 2+
    if game.currentAct >= 2 then
        if game.rooms[16] then game.rooms[16].exits.North = 26 end
        if game.rooms[26] then game.rooms[26].exits.West = 16 end
    end

    -- Restore dynamic exits for Act 3+/4+ (UnlockAct4 calls UnlockAct3 internally)
    if game.currentAct >= 4 then
        RPG.UnlockAct4(nil, game)
    elseif game.currentAct >= 3 then
        RPG.UnlockAct3(nil, game)
    end

    -- Reconstruct tomb loop descriptions if mid-loop
    if game.tombLoop and game.tombLoop.count and game.tombLoop.count > 0
        and not game.tombLoop.broken then
        if RPG.Horror and RPG.Horror.ReconstructLoopDescriptions then
            RPG.Horror.ReconstructLoopDescriptions(game)
        end
    end

    -- Force safe transient state
    game.state = "exploration"
    game.dialogue = { active = false }
    game.combat = { active = false, darkAlignmentUsed = 0 }

    -- Glitch burst is transient: if saved during one, restore to exploration
    -- (rooms 36-47 always exploration on restore — glitch state not persisted)

    -- Re-apply special room states after restore
    if game.player.currentRoom == 49 then
        game.state = "cipher_input"
    elseif game.player.currentRoom == 50 then
        -- Recalc Room 50 dynamic exits (MoveToRoom won't fire on load-in-place)
        if RPG.Ending and RPG.Ending.RecalcRoom50Exits then
            RPG.Ending.RecalcRoom50Exits(game)
        end
        -- state stays "exploration" — Room 50 is a normal exploration room with dynamic exits
    elseif game.player.currentRoom >= 51 and game.player.currentRoom <= 54 then
        -- Player saved during ending display; restore ending state + rebuild endingData
        game.state = "ending"
        local endingMap = { [51]="light", [52]="dark", [53]="horror", [54]="truth" }
        local endingType = endingMap[game.player.currentRoom]
        if RPG.Ending and RPG.Ending.BuildEndingData then
            game.endingData = RPG.Ending.BuildEndingData(game, endingType)
        end
    end

    -- Cache save key for future autosave
    RPG.Save.CacheKey(player, game)

    -- Store player name
    game.playerName = player:GetName()

    -- Store in session table
    RPG.players[clientNum] = game

    GLua.Print("RPG.Save: Restored save for " .. player:GetName() .. " (Level " .. game.player.level .. " " .. game.player.class .. ")")
    return game
end

GLua.Print("RPG: Save system loaded")
return RPG.Save
