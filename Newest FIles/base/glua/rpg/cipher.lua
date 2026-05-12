-- Echoes of the Dark Wars - Cipher System
-- Validation, progress tracking, and !rpgcipher handler

RPG = RPG or {}
RPG.Cipher = {}

--- Build progress string showing discovered/undiscovered positions
--- e.g. "4 9 _ _ _ _ _ _ _" when only item 24 is discovered
function RPG.Cipher.GetProgressString(game)
    local code = RPG.Data.Cipher.code
    local discovered = game.loreDiscovered or {}
    local positions = {}

    -- Mark all discovered positions
    for itemId, source in pairs(RPG.Data.Cipher.sources) do
        if discovered[itemId] then
            for _, pos in ipairs(source.positions) do
                positions[pos] = true
            end
        end
    end

    -- Build display string
    local parts = {}
    for i = 1, #code do
        if positions[i] then
            parts[#parts + 1] = code:sub(i, i)
        else
            parts[#parts + 1] = "_"
        end
    end

    return table.concat(parts, " ")
end

--- Count how many cipher sources have been discovered
function RPG.Cipher.GetDiscoveredCount(game)
    local count = 0
    local discovered = game.loreDiscovered or {}
    for itemId, _ in pairs(RPG.Data.Cipher.sources) do
        if discovered[itemId] then
            count = count + 1
        end
    end
    return count
end

--- Print all discovered fragments to console
function RPG.Cipher.ShowDiscoveredFragments(player, game)
    local discovered = game.loreDiscovered or {}
    local found = false

    player:SendPrint("")
    player:SendPrint("^3=== Discovered Cipher Fragments ===^7")

    for itemId, source in pairs(RPG.Data.Cipher.sources) do
        if discovered[itemId] then
            found = true
            local itemName = RPG.Data.GetItemName(itemId)
            player:SendPrint("^7  " .. itemName .. ": " .. source.hint)
        end
    end

    if not found then
        player:SendPrint("^8  (none discovered yet)")
    end

    player:SendPrint("")
    player:SendPrint("^7Progress: ^3" .. RPG.Cipher.GetProgressString(game))
    player:SendPrint("")
end

--- Validate a submitted code against the cipher
function RPG.Cipher.ValidateCode(game, inputCode)
    if not inputCode or type(inputCode) ~= "string" then
        return false
    end
    return inputCode == RPG.Data.Cipher.code
end

--- Full submission handler (called from !rpgcipher chat command)
function RPG.Cipher.OnSubmit(player, inputCode)
    local game = RPG.GetGame(player)
    if not game then
        player:SendPrint("^1No active RPG session.")
        return
    end

    -- Must be in the cipher room
    if game.player.currentRoom ~= RPG.Config.CIPHER_ROOM then
        player:SendPrint("^3You must be in the Cipher Chamber to submit a code.")
        return
    end

    -- Already solved
    if game.truthUnlocked then
        player:SendPrint("^2The cipher has already been solved. The truth is unlocked.")
        return
    end

    -- Validate input format
    if not inputCode or type(inputCode) ~= "string" then
        player:SendPrint("^1Usage: !rpgcipher XXXXXXXXX (9 digits)")
        return
    end

    -- Strip spaces, ensure correct length
    inputCode = inputCode:gsub("%s", "")
    if #inputCode ~= RPG.Config.CIPHER_LENGTH then
        player:SendPrint("^1The cipher requires exactly " .. RPG.Config.CIPHER_LENGTH .. " digits.")
        return
    end

    -- Check for non-numeric
    if not inputCode:match("^%d+$") then
        player:SendPrint("^1The cipher accepts only numeric digits.")
        return
    end

    -- Validate
    if RPG.Cipher.ValidateCode(game, inputCode) then
        -- SUCCESS
        game.truthUnlocked = true
        if RPG.Quest and RPG.Quest.SetFlag then
            RPG.Quest.SetFlag(game, "truth_unlocked")
        end

        -- Advance echoes_final quest on cipher solve
        if RPG.Quest and RPG.Quest.SetStage then
            local quest = game.quests and game.quests["echoes_final"]
            if quest and quest.status == "active" and quest.stage ~= "complete" then
                RPG.Quest.SetStage(player, "echoes_final", "cipher_solved")
            end
        end

        -- Phase 0 checkpoint: cipher solved is a major commit point
        if RPG.Save and RPG.Save.AutoSave then
            RPG.Save.AutoSave(player)
        end

        player:SendPrint("")
        player:SendPrint("^2========================================")
        player:SendPrint("^2  THE CIPHER IS CORRECT")
        player:SendPrint("^2========================================")
        player:SendPrint("")
        player:SendPrint("^7The chamber trembles. Ancient mechanisms grind to life.")
        player:SendPrint("^7The Holocron's prison seal ^2ACTIVATES^7.")
        player:SendPrint("^7For the first time, the whispers fall silent.")
        player:SendPrint("^7You know the name: ^3DARTH SAEVUS THE FORGOTTEN^7.")
        player:SendPrint("^7The path to the Truth is open.")
        player:SendPrint("")

        if player.PlaySound then
            player:PlaySound("sound/weapons/force/see.wav")
        end

        -- Refresh the cipher menu
        if Menu and Menu.InvalidateCache then
            Menu.InvalidateCache(player)
            Menu.Render(player)
        end
    else
        -- FAILURE
        RPG.AddParanoia(player, RPG.Config.CIPHER_FAIL_PARANOIA)

        player:SendPrint("")
        player:SendPrint("^1The chamber rejects the code.")
        player:SendPrint("^1The symbols flare red and go dark.")
        player:SendPrint("")

        -- Saevus whisper on failure
        local whispers = {
            "^1[WHISPER] ...wrong... you will never know my name...",
            "^1[WHISPER] ...fumbling in the dark... as always...",
            "^1[WHISPER] ...the code is scattered across your journey... look harder...",
            "^1[WHISPER] ...each failure brings you closer to me...",
        }
        player:SendPrint(whispers[math.random(1, #whispers)])
        player:SendPrint("")

        if player.PlaySound then
            player:PlaySound("sound/weapons/force/drain.wav")
        end

        if Menu and Menu.InvalidateCache then
            Menu.InvalidateCache(player)
            Menu.Render(player)
        end
    end
end

--- Called when a player examines an item — discovers cipher fragments (idempotent)
function RPG.Cipher.OnItemExamined(player, game, itemId)
    if not RPG.Data.Cipher or not RPG.Data.Cipher.sources then return end

    local source = RPG.Data.Cipher.sources[itemId]
    if not source then return end

    -- Idempotent: skip if already discovered
    if game.loreDiscovered[itemId] then return end

    -- Mark as discovered
    game.loreDiscovered[itemId] = true

    -- Show discovery message
    player:SendPrint("")
    player:SendPrint("^2========================================")
    player:SendPrint("^2  CIPHER FRAGMENT DISCOVERED")
    player:SendPrint("^2========================================")
    player:SendPrint(source.hint)
    player:SendPrint("")

    -- Phase 1 (#6): three-state counter rule.
    -- Pickups 1-2 print a styled onboarding hint. Pickups 3+ suppress the
    -- trailing counter entirely — the cipher submenu carries the running total.
    local total = 0
    for _ in pairs(RPG.Data.Cipher.sources) do total = total + 1 end
    local found = RPG.Cipher.GetDiscoveredCount(game)
    if found == 1 or found == 2 then
        player:SendPrint("^3[Cipher fragment " .. found .. "/" .. total .. " -- keep gathering]")
        player:SendPrint("")
    end

    if player.PlaySound then
        player:PlaySound("sound/weapons/force/see.wav")
    end
end

GLua.Print("RPG: Cipher system loaded")
return RPG.Cipher
