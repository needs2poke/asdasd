-- Echoes of the Dark Wars - Horror System
-- Tomb loop, glitch burst, fake reboot mechanics

RPG = RPG or {}
RPG.Horror = {}

-- ============================================
-- TOMB LOOP DESCRIPTIONS (escalating per loop)
-- ============================================

local TOMB_LOOP_DESCRIPTIONS = {
    -- Loop 2: Small details wrong
    [2] = {
        [37] = "The braziers burn green now. You're certain they were purple before. The obsidian floor reflects a corridor that doesn't match the one above it.",
        [38] = "The lightsaber burns on the walls have moved. The mural shows a different battle — or the same battle from a different angle. One of the broken statues is intact. It wasn't before.",
        [39] = "The dead holocrons whisper in a language you recognize. Galactic Basic. They're reciting your childhood memories. Incorrectly.",
        [40] = "The pit is shallower. You can almost see the bottom. Something is climbing up. Slowly.",
        [41] = "The carved face on the door has opened its eyes. They follow you. The blood channels on the floor are wet.",
    },
    -- Loop 3: NPCs from earlier acts appear, speaking wrong
    [3] = {
        [37] = "Terena Adare stands at the far end of the corridor. She speaks without moving her lips: 'You came to Dantooine to die. We all knew.' She dissolves into smoke when you approach.",
        [38] = "Merchant Goran sits cross-legged among the broken statues, counting credits. 'I sold your future for twelve credits,' he says cheerfully. 'It was a fair price.' His eyes are empty sockets.",
        [39] = "Atton leans against the wall, shuffling pazaak cards. 'I've been here the whole time,' he says. 'You just couldn't see me. Nobody can.' The cards are blank.",
        [40] = "Doctor Vara stands at the edge of the pit, looking down. 'I've treated this wound before,' she whispers. 'The patient never survived.' She steps forward and falls. No sound.",
        [41] = "Captain Zherron blocks the door in full armor, visor raised. His face is yours. 'Denied,' he says. 'Denied. Denied. Denied.' He repeats it until you look away, then he's gone.",
    },
    -- Loop 4: Player's corpse, hints at escape
    [4] = {
        [37] = "Your body lies face-down on the obsidian floor. You check — it's wearing your clothes, your weapons. A datapad clutched in its dead hand reads: 'WISDOM 14 OR STRENGTH 16. THERE IS NO OTHER WAY.'",
        [38] = "The mural has changed completely. It shows you, walking through this tomb, in an endless loop. The figure in the painting turns to look at you. It mouths: 'BREAK THE LOOP.'",
        [39] = "Every dead holocron is active, playing the same message: a version of you, recorded at this exact moment, saying 'The way out is through understanding, not force. But force works too.'",
        [40] = "The pit is full. Bodies. All of them are you. Different ages, different paths, same face. A sign carved in the rock reads: 'WIS >= 14 / STR >= 16'",
        [41] = "The carved face speaks: 'You have walked this path four times. Your mind frays. Prove your WISDOM to see through the illusion, or use your STRENGTH to shatter it. Choose.'",
    },
    -- Loop 5+: Blunt, direct (for stuck players)
    [5] = {
        [37] = "The entrance hall is bare. No illusions remain. Carved into the obsidian in jagged letters: 'WIS 14 or STR 16. Equip items that boost these stats. Check your inventory. THERE IS NO OTHER WAY OUT.'",
        [38] = "The Hall of Wrath is empty. All that remains is text burned into the wall: 'YOU NEED WISDOM 14 OR STRENGTH 16. EQUIPMENT HELPS. TRY DIFFERENT GEAR.'",
        [39] = "The whispers have stopped. A single holocron displays: 'Loop detected. Solution: raise WIS to 14 or STR to 16. Equip stat-boosting items from your inventory.'",
        [40] = "The pit has sealed itself. Flat stone with one message: 'WISDOM 14 SEES THROUGH THE ILLUSION. STRENGTH 16 BREAKS THE DOOR. CHECK YOUR EQUIPMENT.'",
        [41] = "The carved face has given up subtlety: 'RAISE YOUR WIS TO 14 OR STR TO 16. EQUIP ITEMS. THE LOOP ENDS WHEN YOU MEET THE THRESHOLD.'",
    },
}

-- ============================================
-- TOMB LOOP
-- ============================================

--- Check if movement from room 41 to room 42 should be intercepted by the tomb loop.
--- Called BEFORE currentRoom is updated. Returns true if intercepted.
function RPG.Horror.CheckTombLoop(player, game, targetRoom)
    -- Only intercept: walking from room 41 to room 42
    if game.player.currentRoom ~= 41 or targetRoom ~= 42 then
        return false
    end

    -- Init loop tracking
    game.tombLoop = game.tombLoop or { count = 0, broken = false }

    -- Already broken: allow passage
    if game.tombLoop.broken then
        return false
    end

    -- Check WIS escape: clean passage
    local stats = game.player.stats or {}
    if (stats.WIS or 0) >= RPG.Config.TOMB_WIS_DC then
        game.tombLoop.broken = true
        RPG.Util.BatchPrint(player, {
            "",
            "^2The illusion parts like smoke.",
            "^2You see through the loop — the tomb's geometry was never real.",
            "^2The path to the Inner Sanctum opens, clean and true.",
            "",
        })
        return false -- allow MoveToRoom to proceed to 42
    end

    -- Check STR escape: brute force at a cost
    if (stats.STR or 0) >= RPG.Config.TOMB_STR_DC then
        game.tombLoop.broken = true
        local hpCost = RPG.Config.TOMB_STR_HP_COST
        local parCost = RPG.Config.TOMB_STR_PARANOIA_COST
        game.player.hp = math.max(1, game.player.hp - hpCost)
        RPG.AddParanoia(player, parCost)
        RPG.Util.BatchPrint(player, {
            "",
            "^1You scream and slam your fist into the carved door.",
            "^1The stone cracks. Your knuckles shatter. Blood runs down the runes.",
            "^1The loop BREAKS — violently, painfully.",
            "^3[-" .. hpCost .. " HP, +" .. parCost .. " Paranoia]",
            "",
        })
        return false -- allow MoveToRoom to proceed to 42
    end

    -- Loop: increment, apply descriptions, send back to room 37
    game.tombLoop.count = game.tombLoop.count + 1
    local loopNum = game.tombLoop.count
    local parGain = 3 + loopNum
    RPG.AddParanoia(player, parGain)

    -- Apply loop descriptions from table
    local descKey = math.min(loopNum, 5)
    local loopDescs = TOMB_LOOP_DESCRIPTIONS[descKey]
    if loopDescs then
        for rid = RPG.Config.TOMB_LOOP_START, RPG.Config.TOMB_LOOP_END do
            if game.rooms[rid] and loopDescs[rid] then
                game.rooms[rid].loopDescription = loopDescs[rid]
            end
        end
    end

    -- Reset encounterDefeated on fragment encounter rooms (38, 39, 40)
    for rid = 38, 40 do
        if game.rooms[rid] then
            game.rooms[rid].encounterDefeated = nil
        end
    end

    -- Narrate the loop
    local loopText
    if loopNum == 1 then
        loopText = {
            "",
            "^1The door refuses you.",
            "^1The corridor twists. The walls shift. You are back at the entrance.",
            "^3[The tomb loops. Something is wrong with the geometry.]",
            "^3[+" .. parGain .. " Paranoia]",
            "",
        }
    elseif loopNum == 2 then
        loopText = {
            "",
            "^1Again. The door slams shut. The world spins.",
            "^1You stand at the entrance. The details are wrong.",
            "^3[Loop " .. loopNum .. ". The tomb is changing. +" .. parGain .. " Paranoia]",
            "",
        }
    elseif loopNum == 3 then
        loopText = {
            "",
            "^1No. Not again.",
            "^1The entrance. Familiar faces that shouldn't be here stare at you.",
            "^3[Loop " .. loopNum .. ". The tomb is feeding on your memories. +" .. parGain .. " Paranoia]",
            "",
        }
    else
        loopText = {
            "",
            "^1You find your own corpse at the entrance.",
            "^1It holds a datapad with instructions. Read carefully.",
            "^3[Loop " .. loopNum .. ". There must be a way to break the cycle. +" .. parGain .. " Paranoia]",
            "",
        }
    end
    RPG.Util.BatchPrint(player, loopText)

    -- Move back to entrance (recursive MoveToRoom is safe — 37→42 is many rooms away)
    RPG.MoveToRoom(player, 37)
    return true -- movement to 42 intercepted
end

-- ============================================
-- LOOP DESCRIPTION RECONSTRUCTION (for save/load)
-- ============================================

--- Restore loop descriptions after loading a mid-loop save.
function RPG.Horror.ReconstructLoopDescriptions(game)
    if not game.tombLoop or not game.tombLoop.count then return end
    local loopNum = game.tombLoop.count
    if loopNum <= 0 then return end

    local descKey = math.min(loopNum, 5)
    local loopDescs = TOMB_LOOP_DESCRIPTIONS[descKey]
    if loopDescs then
        for rid = RPG.Config.TOMB_LOOP_START, RPG.Config.TOMB_LOOP_END do
            if game.rooms[rid] and loopDescs[rid] then
                game.rooms[rid].loopDescription = loopDescs[rid]
            end
        end
    end
end

-- ============================================
-- ACT TRANSITION NARRATION
-- ============================================

function RPG.Horror.NarrateAct3Entry(player, game)
    RPG.Util.BatchPrint(player, {
        "",
        "^7========================================",
        "^1  ACT III: THE SITH TOMB",
        "^7========================================",
        "",
        "^7The hyperspace jump to Dxun is short.",
        "^7Too short. As if the moon was waiting.",
        "",
        "^7The jungle moon looms through the viewport —",
        "^7a green wound in space, heavy with the dark side.",
        "^7Mandalorian ruins dot the canopy. But you're not",
        "^7here for the Mandalorians.",
        "",
        "^1The Holocron burns against your chest.",
        "^1It knows this place. It REMEMBERS.",
        "",
        "^7Somewhere beneath the jungle, a Sith tomb",
        "^7has waited millennia for someone foolish enough",
        "^7to enter.",
        "",
        "^3That someone is you.",
        "",
    })
end

function RPG.Horror.NarrateAct4Entry(player, game)
    RPG.Util.BatchPrint(player, {
        "",
        "^7========================================",
        "^1  ACT IV: THE VOID",
        "^7========================================",
        "",
        "^7Beyond the sanctum, reality thins.",
        "^7The stone walls dissolve into nothing.",
        "^7Not darkness — ABSENCE.",
        "",
        "^1The Holocron goes silent.",
        "^1For the first time since the crash site,",
        "^1the whispers stop.",
        "",
        "^7That should comfort you.",
        "^7It doesn't.",
        "",
        "^3The Force itself is unstable here.",
        "^3What you see may not be real.",
        "^3What you feel may be a lie.",
        "^3Trust nothing. Especially yourself.",
        "",
    })
end

-- ============================================
-- GLITCH BURST
-- ============================================

local GLITCH_FRAGMENTS = {
    "^1[DATA CORRUPTED]",
    "^1\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93",
    "^1THE FORCE IS A LIE",
    "^1[MEMORY OVERFLOW]",
    "^1Y0U W3R3 N3V3R R34L",
    "^1[HOLOCRON CONTAINMENT FAILURE]",
    "^1ERR_IDENTITY_NOT_FOUND",
    "^1[SIGNAL LOST]",
    "^1THERE IS NO LIGHT SIDE",
    "^1[SYSTEM INTEGRITY: 0%]",
    "^1THE PRISON IS OPEN",
    "^1[FORCE ECHO RECURSIVE LOOP]",
    "^1ALL PATHS LEAD HERE",
    "^1[FATAL: SOUL_CORRUPTION]",
    "^1REVAN KNEW. REVAN FAILED.",
    "^1[DARK SIDE OVERFLOW]",
    "^1YOUR CHOICES DON'T MATTER",
    "^1[REALITY CHECKSUM FAILED]",
    "^1THE DEAD DON'T STAY DEAD",
    "^1[CONTAINMENT BREACH]",
}

local SUBLIMINAL = {
    "WAKE UP",
    "IT WAS NEVER REAL",
    "YOU CHOSE THIS",
    "THERE IS NO ESCAPE",
    "THE HOLOCRON REMEMBERS",
    "YOU ARE THE PRISON",
    "SAEVUS LIVES",
    "NOTHING IS TRUE",
    "THE LOOP NEVER ENDS",
    "YOU WERE ALWAYS HERE",
}

--- Start a glitch burst visual effect.
--- opts: { netname = bool, frames = int, onComplete = fn }
function RPG.Horror.StartGlitchBurst(player, opts)
    local game = RPG.GetGame(player)
    if not game then return end

    opts = opts or {}
    local totalFrames = opts.frames or math.random(
        math.floor(RPG.Config.GLITCH_BURST_TOTAL_MIN / RPG.Config.GLITCH_BURST_FRAME_MAX),
        math.floor(RPG.Config.GLITCH_BURST_TOTAL_MAX / RPG.Config.GLITCH_BURST_FRAME_MIN)
    )
    totalFrames = math.max(4, math.min(totalFrames, 30))

    local frameInterval = math.random(RPG.Config.GLITCH_BURST_FRAME_MIN, RPG.Config.GLITCH_BURST_FRAME_MAX)

    game.glitchBurst = {
        previousState = game.state,
        frame = 0,
        totalFrames = totalFrames,
        startTime = Timer.RealTime and Timer.RealTime() or 0,
        netname = opts.netname or false,
        onComplete = opts.onComplete,
        isFakeReboot = false,
        glitchText = "^1...",
    }

    RPG.SetState(player, "glitch_burst")

    -- Schedule first frame
    local clientNum = player:GetClientNum()
    Timer.Remove("rpg_horror_glitch_" .. clientNum)
    Timer.Create("rpg_horror_glitch_" .. clientNum, frameInterval, 0, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then
            Timer.Remove("rpg_horror_glitch_" .. clientNum)
            return
        end
        local g = RPG.GetGame(p)
        if not g or not g.glitchBurst then
            Timer.Remove("rpg_horror_glitch_" .. clientNum)
            return
        end
        RPG.Horror.AdvanceGlitchFrame(p, g)
    end)
end

--- Advance one glitch frame.
function RPG.Horror.AdvanceGlitchFrame(player, game)
    local burst = game.glitchBurst
    if not burst then return end

    burst.frame = burst.frame + 1

    -- Build corrupted text (3-5 random lines)
    local lines = {}
    local numLines = math.random(3, 5)
    for i = 1, numLines do
        if math.random(100) <= 20 then
            lines[i] = "^3" .. SUBLIMINAL[math.random(#SUBLIMINAL)]
        else
            lines[i] = GLITCH_FRAGMENTS[math.random(#GLITCH_FRAGMENTS)]
        end
    end

    -- At 60% through: insert personalized line
    if burst.netname and burst.frame >= math.floor(burst.totalFrames * 0.6) then
        local name = player:GetName() or "UNKNOWN"
        lines[math.random(#lines)] = "^1WAKE UP, " .. name
    end

    burst.glitchText = table.concat(lines, "\n")

    -- Refresh menu display
    if Menu and Menu.InvalidateCache then
        Menu.InvalidateCache(player)
    end
    if Menu and Menu.Render then
        Menu.Render(player)
    end

    -- Check if done
    if burst.frame >= burst.totalFrames then
        RPG.Horror.EndGlitchBurst(player, game)
    end
end

--- End a glitch burst and restore previous state.
function RPG.Horror.EndGlitchBurst(player, game)
    local burst = game.glitchBurst
    if not burst then return end

    local clientNum = player:GetClientNum()
    Timer.Remove("rpg_horror_glitch_" .. clientNum)

    local prevState = burst.previousState or "exploration"
    local onComplete = burst.onComplete
    game.glitchBurst = nil

    RPG.SetState(player, prevState)

    if onComplete then
        onComplete()
    end
end

-- ============================================
-- FAKE REBOOT
-- ============================================

--- Start a fake reboot sequence (8-frame scripted).
function RPG.Horror.StartFakeReboot(player, onComplete)
    local game = RPG.GetGame(player)
    if not game then return end

    local clientNum = player:GetClientNum()

    game.glitchBurst = {
        previousState = game.state,
        frame = 0,
        totalFrames = 8,
        startTime = Timer.RealTime and Timer.RealTime() or 0,
        isFakeReboot = true,
        glitchText = "",
        onComplete = onComplete,
    }

    RPG.SetState(player, "glitch_burst")

    -- Scripted sequence using absolute timer delays
    local sequence = {
        { delay = 0,    text = "" },
        { delay = 1000, text = "^1[SYSTEM SHUTDOWN]" },
        { delay = 2000, text = "^1[SYSTEM SHUTDOWN]\n^1\xe2\x96\x93\xe2\x96\x93\xe2\x96\x93 MEMORY DUMP \xe2\x96\x93\xe2\x96\x93\xe2\x96\x93\n^1ERR_FORCE_ECHO_OVERFLOW\n^1STACK: 0x4F2A 0x7C91 0xDEAD" },
        { delay = 3000, text = "^3[REINITIALIZING...]" },
        { delay = 4000, text = "^3[REINITIALIZING...]\n^3[FORCE ECHO RECOVERY MODE]\n^3[SCANNING CONTAINMENT...]" },
        { delay = 5500, text = "^1[INTERCEPTED]\n\n^5\"I am not a corruption.\n^5 I am a gift.\n^5 You opened the prison.\n^5 I merely walked out.\"\n\n^8— Darth Saevus" },
        { delay = 7000, text = "^2[SYSTEM RESTORED]\n^2[CONTAINMENT: NOMINAL]\n^2[RESUMING...]" },
    }

    -- Schedule each frame
    for i, frame in ipairs(sequence) do
        Timer.Simple("rpg_horror_reboot_" .. clientNum .. "_" .. i, frame.delay, function()
            local p = Player.Get(clientNum)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g or not g.glitchBurst or not g.glitchBurst.isFakeReboot then return end

            g.glitchBurst.glitchText = frame.text
            g.glitchBurst.frame = i

            if Menu and Menu.InvalidateCache then
                Menu.InvalidateCache(p)
            end
            if Menu and Menu.Render then
                Menu.Render(p)
            end
        end)
    end

    -- Final: end reboot
    Timer.Simple("rpg_horror_reboot_" .. clientNum .. "_end", RPG.Config.FAKE_REBOOT_DURATION, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local g = RPG.GetGame(p)
        if not g or not g.glitchBurst then return end

        RPG.AddParanoia(p, 8)
        RPG.Horror.EndGlitchBurst(p, g)
    end)
end

-- ============================================
-- FOURTH WALL BREAK
-- ============================================

--- Start a fourth wall break sequence (5-frame scripted, ~6 seconds).
--- Uses the glitch_burst state like StartFakeReboot.
function RPG.Horror.FourthWallBreak(player, game)
    if not game then return end

    local clientNum = player:GetClientNum()
    local playerName = player:GetName() or "UNKNOWN"

    game.glitchBurst = {
        previousState = game.state,
        frame = 0,
        totalFrames = 5,
        startTime = Timer.RealTime and Timer.RealTime() or 0,
        isFakeReboot = false,
        isFourthWall = true,
        glitchText = "",
        onComplete = function()
            game.flags["fourth_wall_broken"] = true
            RPG.AddParanoia(player, RPG.Config.FOURTH_WALL_PARANOIA_GAIN)
        end,
    }

    RPG.SetState(player, "glitch_burst")

    -- Scripted sequence
    local sequence = {
        { delay = 0,    text = "" },
        { delay = 1200, text = "^1WAKE UP, " .. playerName .. "." },
        { delay = 2400, text = "^1You are rpgPlayer_t.\n^1A data structure.\n^1A table of numbers." },
        { delay = 3800, text = "^1Your choices were scripted.\n^1Your dialogue was pre-written.\n^1Your stats are integers in a file." },
        { delay = 5200, text = "^2[SYSTEM RESTORED]\n^2[IDENTITY RECOMPILED]\n^2[RESUMING...]" },
    }

    for i, frame in ipairs(sequence) do
        Timer.Simple("rpg_horror_4wall_" .. clientNum .. "_" .. i, frame.delay, function()
            local p = Player.Get(clientNum)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g or not g.glitchBurst or not g.glitchBurst.isFourthWall then return end

            g.glitchBurst.glitchText = frame.text
            g.glitchBurst.frame = i

            if Menu and Menu.InvalidateCache then
                Menu.InvalidateCache(p)
            end
            if Menu and Menu.Render then
                Menu.Render(p)
            end
        end)
    end

    -- End sequence
    Timer.Simple("rpg_horror_4wall_" .. clientNum .. "_end", 6500, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local g = RPG.GetGame(p)
        if not g or not g.glitchBurst then return end

        RPG.Horror.EndGlitchBurst(p, g)
    end)
end

-- ============================================
-- PARANOIA GLIMPSE SYSTEM
-- ============================================

local GLIMPSES = {
    {
        room = 6,
        flag = "glimpse_dead_jedi",
        minParanoia = RPG.Config and RPG.Config.GLIMPSE_PARANOIA_MIN or 70,
        requireHolocron = true,
        paranoiaGain = 3,
        stages = {
            {
                delay = 0,
                lines = {
                    "^1The dead Jedi stirs. Her eyes open -- purple, not brown.",
                    "^1She rises, body moving wrong, joints bending backward.",
                    "^1\"You took my burden,\" she whispers. \"Now carry it.\"",
                },
            },
            {
                delay = 1500,
                lines = {
                    "^1The ship's walls ripple. Blood runs upward along the hull.",
                    "^1The Jedi's face shifts -- it's YOUR face now, older, hollow-eyed.",
                    "^1\"You already lost,\" your own voice says. \"You just don't know it yet.\"",
                },
            },
            {
                delay = 3000,
                lines = {
                    "^8...the hold is empty. The Jedi's body lies where it always did.",
                    "^8The Holocron hums, satisfied.",
                    "^1[+3 Paranoia]",
                },
            },
        },
    },
}

--- Check and fire a glimpse sequence for the given room.
--- Returns true if a glimpse was triggered.
function RPG.Horror.CheckGlimpse(player, game, roomId)
    -- Anti-collision: skip if another narrative is active
    if game._narrativeActive then return false end

    for _, glimpse in ipairs(GLIMPSES) do
        if glimpse.room == roomId
            and not game.flags[glimpse.flag]
            and game.player.paranoia >= (glimpse.minParanoia or 70)
            and (not glimpse.requireHolocron or game.player.hasHolocron) then

            -- Fire the glimpse
            game.flags[glimpse.flag] = true
            game._narrativeActive = true

            local clientNum = player:GetClientNum()
            local stageCount = #glimpse.stages
            for i, stage in ipairs(glimpse.stages) do
                local stageIdx = i
                local gain = glimpse.paranoiaGain
                Timer.Simple("rpg_glimpse_" .. clientNum .. "_" .. stageIdx, stage.delay, function()
                    local p = Player.Get(clientNum)
                    if not p or not p:IsValid() then return end
                    local g = RPG.GetGame(p)
                    if not g then return end

                    RPG.Util.BatchPrint(p, stage.lines)

                    -- Last stage: apply effects and clear narrative lock
                    if stageIdx == stageCount then
                        if gain and gain > 0 then
                            RPG.AddParanoia(p, gain)
                        end
                        g._narrativeActive = nil
                    end
                end)
            end
            return true
        end
    end
    return false
end

-- ============================================
-- HORROR ROOM ENTRY
-- ============================================

--- Called synchronously from MoveToRoom, AFTER encounter check.
--- firstVisit passed directly (not inferred from visitedRooms, which is deferred).
function RPG.Horror.OnRoomEnter(player, game, roomId, room, firstVisit)
    -- Guard: if combat just started, don't fire horror effects
    if game.state == "combat" then return end

    local clientNum = player:GetClientNum()

    -- Scripted horror: glitch burst on entry
    if room.horrorOnEntry == "glitch" and not game.flags["horror_glitch_" .. roomId] then
        game.flags["horror_glitch_" .. roomId] = true
        Timer.Simple("rpg_horror_entry_" .. clientNum, 100, function()
            local p = Player.Get(clientNum)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g then return end
            RPG.Horror.StartGlitchBurst(p, { netname = true })
        end)
        return
    end

    -- Scripted horror: fake reboot on entry
    if room.horrorOnEntry == "reboot" and not game.flags["horror_reboot_" .. roomId] then
        game.flags["horror_reboot_" .. roomId] = true
        Timer.Simple("rpg_horror_entry_" .. clientNum, 100, function()
            local p = Player.Get(clientNum)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g then return end
            RPG.Horror.StartFakeReboot(p, function() end)
        end)
        return
    end

    -- Spontaneous glitch: Act 4 rooms, not first visit, high paranoia, 25% chance
    -- Guard: skip if narrative lock active (nemesis encounter in progress)
    if game._narrativeActive then return end
    if not firstVisit and room.act == 4
        and game.player.paranoia >= RPG.Config.GLITCH_PARANOIA_THRESHOLD
        and math.random(100) <= 25 then
        Timer.Simple("rpg_horror_entry_" .. clientNum, 100, function()
            local p = Player.Get(clientNum)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g then return end
            RPG.Horror.StartGlitchBurst(p, { frames = math.random(4, 8) })
        end)
    end
end

-- ============================================
-- CLEANUP
-- ============================================

--- Remove all horror-related timers for a player (by clientNum).
function RPG.Horror.Cleanup(clientNum)
    Timer.Remove("rpg_horror_glitch_" .. clientNum)
    Timer.Remove("rpg_horror_entry_" .. clientNum)
    -- Clean up reboot sequence timers
    for i = 1, 7 do
        Timer.Remove("rpg_horror_reboot_" .. clientNum .. "_" .. i)
    end
    Timer.Remove("rpg_horror_reboot_" .. clientNum .. "_end")
    -- Fourth wall break timers
    for i = 1, 5 do
        Timer.Remove("rpg_horror_4wall_" .. clientNum .. "_" .. i)
    end
    Timer.Remove("rpg_horror_4wall_" .. clientNum .. "_end")
    -- Glimpse timers
    for i = 1, 5 do
        Timer.Remove("rpg_glimpse_" .. clientNum .. "_" .. i)
    end
end

GLua.Print("RPG: Horror system loaded")
return RPG.Horror
