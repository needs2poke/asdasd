-- Echoes of the Dark Wars - Stalker System
-- Room-move state machine: a corrupted Jedi Shadow hunts the player
-- Stages: 0=Dormant, 1=Hidden, 2=Watching, 3=Hunting, 4=Combat

RPG = RPG or {}
RPG.Stalker = {}

-- Stage thresholds (room moves to advance)
local ADVANCE_HIDDEN   = 4  -- Hidden -> Watching
local ADVANCE_WATCHING = 3  -- Watching -> Hunting
local ADVANCE_HUNTING  = 2  -- Hunting -> Combat

-- Act 2 room range
local ACT2_MIN = 26
local ACT2_MAX = 35

-- Ambient text per stage
local AMBIENT = {
    [1] = {  -- Hidden
        "^8A chill runs down your spine. The Holocron flickers.",
        "^8For a moment, you thought you saw a shadow move against the light.",
        "^8The hairs on your neck stand up. Something is watching.",
        "^8A whisper at the edge of hearing: footsteps matching yours.",
    },
    [2] = {  -- Watching
        "^1A dark figure stands at the edge of your vision. When you turn, it's gone.",
        "^1You catch a glimpse of brown robes disappearing around a corner.",
        "^1The Force pulses with warning. Something is close. Tracking you.",
        "^1In a reflective surface, you see a second shadow behind yours.",
        "^8A broken whisper follows you: '...Vorr...'",
    },
    [3] = {  -- Hunting
        "^1The crowd parts ahead of you. People stare at something behind you and quicken their pace.",
        "^1The air goes cold. The Holocron screams inside your mind. IT IS HERE.",
        "^1Footsteps. Behind you. Matching your pace exactly. Getting closer.",
        "^1The lights flicker. A lightsaber ignites somewhere in the darkness behind you.",
    },
}

--- Initialize stalker state for a game
function RPG.Stalker.Init(game)
    game.stalker = {
        stage = 0,       -- 0=Dormant
        roomMoves = 0,
        encounterCount = 0,
        defeated = false,
        firstSurvivalDone = false,
    }
end

--- Check if stalker system should be active
local function ShouldBeActive(game)
    -- Stalker activates after Q15 analysis_pending or later
    if not game.stalker then return false end
    local stage = RPG.Quest.GetStage(game, "holocron_unlock")
    if not stage then return false end
    -- Active once Jeth starts analysis
    return stage == "analysis_pending" or stage == "analysis_complete"
        or stage == "stalker_survival" or stage == "cipher_revealed"
        or stage == "complete"
end

--- Activate stalker (called when Q15 reaches analysis_pending)
function RPG.Stalker.Activate(game)
    if not game.stalker then
        RPG.Stalker.Init(game)
    end
    if game.stalker.stage == 0 then
        game.stalker.stage = 1  -- Hidden
        game.stalker.roomMoves = 0
    end
end

--- Called on every room move in Act 2
function RPG.Stalker.OnRoomMove(player, game, roomId)
    if not game.stalker then return end
    if game.stalker.defeated then return end

    -- Only count Act 2 rooms
    if roomId < ACT2_MIN or roomId > ACT2_MAX then return end

    -- Check if stalker should activate
    if game.stalker.stage == 0 then
        if ShouldBeActive(game) then
            RPG.Stalker.Activate(game)
        else
            return
        end
    end

    game.stalker.roomMoves = game.stalker.roomMoves + 1
    local stage = game.stalker.stage
    local moves = game.stalker.roomMoves

    -- Show ambient text
    if AMBIENT[stage] then
        local texts = AMBIENT[stage]
        local text = texts[math.random(1, #texts)]
        player:SendPrint("")
        player:SendPrint(text)
        player:SendPrint("")
    end

    -- Check stage advancement
    if stage == 1 and moves >= ADVANCE_HIDDEN then
        game.stalker.stage = 2
        game.stalker.roomMoves = 0
        player:SendPrint("^1[The presence grows stronger. It's no longer hiding.]")
    elseif stage == 2 and moves >= ADVANCE_WATCHING then
        game.stalker.stage = 3
        game.stalker.roomMoves = 0
        player:SendPrint("^1[It's hunting you now. You can feel it closing in.]")

        -- Void overlay triggers at stage 3+ with high paranoia
        if game.player.paranoia > 60 then
            RPG.Stalker.TriggerVoid(player, game, roomId)
        end
    elseif stage == 3 then
        -- Secondary Q18 trigger: catch paranoia crossing 60 after stage 3 started
        if game.player.paranoia > 60
            and not RPG.Quest.IsActive(game, "nathema_echo")
            and not RPG.Quest.IsComplete(game, "nathema_echo") then
            RPG.Stalker.TriggerVoid(player, game, roomId)
        end

        if moves >= ADVANCE_HUNTING then
            -- Force combat
            game.stalker.stage = 4
            game.stalker.roomMoves = 0
            game.stalker.encounterCount = game.stalker.encounterCount + 1

            player:SendPrint("")
            player:SendPrint("^1========================================")
            player:SendPrint("^1A figure steps from the shadows.")
            player:SendPrint("^1Brown robes. A lightsaber hilt in hand.")
            player:SendPrint("^1It was a Jedi once. Now its eyes are empty")
            player:SendPrint("^1pits of purple light. The Stalker has found you.")
            player:SendPrint("^1========================================")
            player:SendPrint("")

            if RPG.Combat and RPG.Combat.StartCombat then
                RPG.Combat.StartCombat(player, 12)  -- Enemy 12: The Stalker
            end
        end
    end
end

--- Trigger Nathema Void overlay
function RPG.Stalker.TriggerVoid(player, game, roomId)
    local room = game.rooms[roomId]
    if not room or not room.voidDescription then return end

    player:SendPrint("")
    player:SendPrint("^8[The Force goes silent.]")
    player:SendPrint("^8" .. room.voidDescription)
    player:SendPrint("^8[The moment passes. The Force returns.]")
    player:SendPrint("")

    -- Start Q18 if not started and paranoia > 60
    if not RPG.Quest.IsActive(game, "nathema_echo")
        and not RPG.Quest.IsComplete(game, "nathema_echo") then
        RPG.Quest.Start(player, "nathema_echo")
        RPG.Quest.SetStage(player, "nathema_echo", "void_touch")
        player:SendPrint("^3[New Quest: Nathema's Echo]")
    end
end

--- Called when player flees from the Stalker (from combat.lua)
function RPG.Stalker.OnFled(player, game)
    if not game.stalker then return end
    game.stalker.stage = 3  -- Reset to Hunting (not Hidden -- it's still on you)
    game.stalker.roomMoves = 0
    player:SendPrint("^1[You escaped. But the Stalker is still hunting.]")
end

--- Called when a survival combat ends (from combat.lua)
function RPG.Stalker.OnSurvived(player, game)
    if not game.stalker then return end

    game.stalker.stage = 1  -- Reset to Hidden
    game.stalker.roomMoves = 0

    -- Surviving costs sanity
    if RPG.AddParanoia then
        RPG.AddParanoia(player, RPG.Config.STALKER_PARANOIA_COST)
        player:SendPrint("^1[The encounter leaves a scar on your psyche. Paranoia +" .. RPG.Config.STALKER_PARANOIA_COST .. "]")
    end

    -- First survival: drop Fragment of Dark Crystal
    if not game.stalker.firstSurvivalDone then
        game.stalker.firstSurvivalDone = true
        if #game.player.inventory < RPG.Config.MAX_INVENTORY then
            game.player.inventory[#game.player.inventory + 1] = 31
            player:SendPrint("^5Loot:^7 " .. RPG.Data.GetItemName(31))
        else
            player:SendPrint("^3Inventory full. The crystal shard dissolves.")
        end
    end

    -- Advance Q15 if at stalker_survival stage
    if RPG.Quest.GetStage(game, "holocron_unlock") == "stalker_survival" then
        RPG.Quest.SetStage(player, "holocron_unlock", "cipher_revealed")
        player:SendPrint("^3[Quest Updated: Unlocking the Holocron]")
    end
end

return true
