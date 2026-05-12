-- Echoes of the Dark Wars - Ending System
-- 4 endings: evaluation, narration, trigger

RPG = RPG or {}
RPG.Ending = {}

-- ============================================
-- ENDING NARRATION DATA
-- ============================================

local ENDINGS = {
    light = {
        title = "^5THE LIGHT",
        endingName = "Redemption",
        roomId = 51,
        narration = {
            "^7You raise the Holocron above your head.",
            "^7The prison cracks. Light pours from within --",
            "^7not the sickly red of the Sith, but pure,",
            "^7blinding white.",
            "",
            "^7Darth Saevus screams. A sound that shakes",
            "^7the walls, the floor, your bones.",
            "",
            "^5You pour everything you have into the Light.",
            "^5The Holocron shatters.",
            "^5Saevus is consumed.",
            "",
            "^7The explosion takes you too.",
            "",
            "^7The galaxy is saved.",
            "^7Your name is forgotten.",
            "",
            "^5But the Force remembers.",
        },
    },
    dark = {
        title = "^1THE DARK",
        endingName = "Dominion",
        roomId = 52,
        narration = {
            "^7You open the Holocron.",
            "^7Not to destroy it. To ^1embrace^7 it.",
            "",
            "^1Saevus pours into you like a flood.",
            "^1Your memories dissolve. Your name dissolves.",
            "^1There is only the hunger, ancient and infinite.",
            "",
            "^7When your eyes open, they glow purple.",
            "",
            "^1Darth Saevus lives again.",
            "^1The Second Sith Empire begins.",
            "",
            "^7Somewhere, a Jedi feels a disturbance in the Force",
            "^7and weeps without knowing why.",
        },
    },
    horror = {
        title = "^1THE SHATTERED MIND",
        endingName = "Oblivion",
        roomId = 53,
        narration = {
            "^7You can't move.",
            "^7You can't speak.",
            "^7You can't remember your name.",
            "",
            "^1The paranoia broke you.",
            "^1Not all at once -- piece by piece,",
            "^1whisper by whisper, until there was",
            "^1nothing left to break.",
            "",
            "^7They find you in the chamber,",
            "^7eyes open, body rigid.",
            "^7Catatonic.",
            "",
            "^1The Holocron sits beside you,",
            "^1pulsing gently,",
            "^1waiting for the next one.",
        },
    },
    truth = {
        title = "^2THE TRUTH",
        endingName = "Liberation",
        roomId = 54,
        narration = {
            "^7You speak the name aloud:",
            "^3\"DARTH SAEVUS THE FORGOTTEN.\"",
            "",
            "^7The chamber goes silent.",
            "^7The Holocron stops pulsing.",
            "^7For the first time since the crash site,",
            "^7your mind is completely, utterly quiet.",
            "",
            "^2The cipher seals the prison -- permanently.",
            "^2The containment protocols lock into place.",
            "^2What was forgotten stays forgotten.",
            "",
            "^7You walk out of the chamber.",
            "^7The sun is warm on your face.",
            "^7The galaxy doesn't know what you did.",
            "",
            "^2But you do.",
            "^2And you are free.",
            "",
            "^7But there is a price.",
            "^8You feel the Force recede -- not gone, but quieted.",
            "^8A wound you can never close.",
        },
    },
}

-- ============================================
-- EVALUATION
-- ============================================

--- Returns which endings are available based on current game state
function RPG.Ending.EvaluateAvailable(game)
    local alignment = game.player.alignment
    local paranoia = game.player.paranoia
    local truth = game.truthUnlocked or false

    return {
        light  = alignment >= RPG.Config.ENDING_LIGHT_ALIGNMENT,
        dark   = alignment <= RPG.Config.ENDING_DARK_ALIGNMENT,
        horror = paranoia >= RPG.Config.ENDING_HORROR_PARANOIA,
        truth  = truth,
    }
end

--- Get narration data for an ending type
function RPG.Ending.GetNarration(endingType)
    local data = ENDINGS[endingType]
    if not data then return nil end
    return {
        title = data.title,
        endingName = data.endingName,
        roomId = data.roomId,
        narration = data.narration,
    }
end

-- ============================================
-- BUILD ENDING DATA (pure, no side effects)
-- ============================================

--- Build endingData table for display (used by Trigger and save restore)
function RPG.Ending.BuildEndingData(game, endingType)
    local narr = RPG.Ending.GetNarration(endingType)
    if not narr then return nil end

    -- Gather stats
    local p = game.player
    local questsCompleted = 0
    for _, q in pairs(game.quests or {}) do
        if q.status == "completed" then
            questsCompleted = questsCompleted + 1
        end
    end

    local className = "Unknown"
    if RPG.Data and RPG.Data.Classes and RPG.Data.Classes[p.class] then
        className = RPG.Data.Classes[p.class].name
    end

    return {
        type = endingType,
        title = narr.title,
        endingName = narr.endingName,
        narration = narr.narration,
        stats = {
            class = className,
            level = p.level,
            alignment = p.alignment,
            paranoia = p.paranoia,
            questsCompleted = questsCompleted,
            forceSevered = p.forceSevered or false,    -- Phase 1 (#1): Truth-ending only
        },
    }
end

-- ============================================
-- TRIGGER
-- ============================================

--- Trigger an ending. Caller owns movement (MoveToRoom already placed the player).
--- This sets state, builds data, narrates, and cleans up timers.
function RPG.Ending.Trigger(player, endingType)
    local game = RPG.GetGame(player)
    if not game then return end

    -- Phase 0 checkpoint: capture pre-ending state so restart-during-ending replays from choice
    if RPG.Save and RPG.Save.AutoSave then
        RPG.Save.AutoSave(player)
    end

    -- Phase 1 (#1): Truth ending applies the Force Sever bargain BEFORE BuildEndingData
    -- so the stats panel reflects the cost.
    --
    -- ORDER RATIONALE (do not "fix" by mutating before AutoSave):
    -- AutoSave above writes the PRE-Sever state. If a player crashes between
    -- AutoSave and this mutation, restarting replays from the pre-Sever save --
    -- they re-experience the bargain text and re-trigger the cost. This is
    -- intentional. Mutating before AutoSave would lock a crashed player into
    -- Severed-on-reload without ever showing them the narration that explained
    -- the price.
    if endingType == "truth" then
        game.player.forceSevered = true
        local floor = RPG.Config.PARANOIA_FLOOR_TRUTH or 30
        if game.player.paranoia < floor then
            game.player.paranoia = floor
        end
    end

    local endingData = RPG.Ending.BuildEndingData(game, endingType)
    if not endingData then
        player:SendPrint("^1[Error] Unknown ending: " .. tostring(endingType))
        return
    end

    -- Store ending data for menu display
    game.endingData = endingData

    -- Set completion flags
    if RPG.Quest and RPG.Quest.SetFlag then
        RPG.Quest.SetFlag(game, "ending_" .. endingType)
        RPG.Quest.SetFlag(game, "game_complete")
    end

    -- Narrate ending to console
    player:SendPrint("")
    player:SendPrint("^7========================================")
    player:SendPrint(endingData.title)
    player:SendPrint("^7========================================")
    player:SendPrint("")
    for _, line in ipairs(endingData.narration) do
        player:SendPrint(line)
    end
    player:SendPrint("")
    player:SendPrint("^7========================================")
    player:SendPrint("^3Ending: ^7" .. endingData.endingName)
    player:SendPrint("^7========================================")
    player:SendPrint("")

    -- Kill background timers
    local clientNum = player:GetClientNum()
    Timer.Remove("rpg_crowd_whisper_" .. clientNum)
    Timer.Remove("rpg_crowd_first_" .. clientNum)
    Timer.Remove("rpg_room_narrate_" .. clientNum)
    Timer.Remove("rpg_companion_comment_" .. clientNum)

    -- Play ending sound
    if player.PlaySound then
        if endingType == "truth" or endingType == "light" then
            player:PlaySound("sound/weapons/force/see.wav")
        else
            player:PlaySound("sound/weapons/force/drain.wav")
        end
    end

    -- Transition to ending state (opens ending menu)
    RPG.SetState(player, "ending")
end

-- ============================================
-- ROOM 50 DYNAMIC EXITS
-- ============================================

--- Recalculate Room 50 exits based on available endings.
--- Creates a NEW exits table (replaces shared reference from CopyRooms).
function RPG.Ending.RecalcRoom50Exits(game)
    local room = game.rooms[50]
    if not room then return end

    local available = RPG.Ending.EvaluateAvailable(game)

    -- Build fresh exits table (never mutate shared template)
    local exits = {
        South = 49,   -- Always: fallback to cipher chamber
    }

    if available.light then
        exits.North = 51   -- The Light
    end
    if available.dark then
        exits.East = 52    -- The Dark
    end
    if available.horror then
        exits.West = 53    -- The Shattered Mind
    end
    if available.truth then
        exits.Up = 54      -- The Truth (ascend)
    end

    room.exits = exits
end

GLua.Print("RPG: Ending system loaded")
return RPG.Ending
