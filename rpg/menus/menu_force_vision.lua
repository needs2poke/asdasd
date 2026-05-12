-- Echoes of the Dark Wars - Force Vision Menu
-- Q4 vertical slice: Holocron lessons (Ghosts of the Enclave)

RPG = RPG or {}

local LESSONS = {
    [1] = {
        title = "Lesson I: The Fear Under Thought",
        lines = {
            "^8Cold stone. A dead academy.",
            "^8Your own footsteps behind you.",
            "^1Saevus: ^7Fear is not your enemy.",
            "^7It is your first honest signal.",
            "^7A child in Khoonda reaches for your hand,",
            "^7then recoils in terror.",
            "^7The vision waits for your answer.",
        },
        controlled = { stat = "WIS", dc = 14 },
    },
    [2] = {
        title = "Lesson II: Mercy and the Blade",
        lines = {
            "^8You stand over a wounded Exchange thug.",
            "^8He laughs blood into the dust.",
            "^1Saevus: ^7Mercy is only virtue",
            "^7when it costs you something real.",
            "^7Behind him, a rifle rises in shaking hands.",
            "^7One breath decides what kind of",
            "^7person survives.",
        },
        controlled = { stat = "WIS", dc = 15 },
    },
    [3] = {
        title = "Lesson III: The Open Door",
        lines = {
            "^8A map burns across the sky:",
            "^8Malachor, Korriban, and a name erased.",
            "^1Saevus: ^7Revan found doors.",
            "^7I found what waited behind them.",
            "^7You hear the hum of a distant academy",
            "^7before you see it.",
            "^7He offers you the key.",
            "^7He does not offer innocence.",
        },
        controlled = { stat = "WIS", dc = 16 },
    },
}

local FLASHBACKS = {
    soldier = {
        title = "Echoes of Malachor",
        lines = {
            "^8The ground splits. Fire and screaming metal.",
            "^8Your squad -- their faces. You remember now.",
            "^8The Force screams through the wound in the world.",
            "^1Saevus: ^7Pain is the Force's first language.",
            "^7It always was. The Jedi just mistranslated it.",
            "^7The memory waits for your answer.",
        },
        acceptAbility = "executioners_eye",
        resistAbility = "unbreakable_will",
        acceptText = {
            "^1You let the killing instinct back in.",
            "^1Saevus: ^7You fight best when the grave is open at your feet.",
        },
        resistText = {
            "^2You bury the rage. Discipline holds.",
            "^7The memory fades, but the strength remains.",
        },
    },
    scoundrel = {
        title = "The Deal That Went Wrong",
        lines = {
            "^8A cantina table. Credits stacked high.",
            "^8The face of someone you trusted.",
            "^8The blaster under the table you didn't see.",
            "^1Saevus: ^7Trust is a currency. You spent yours.",
            "^7The Force shows what you missed that night.",
            "^7The memory waits for your answer.",
        },
        acceptAbility = "cold_read",
        resistAbility = "slippery_mind",
        acceptText = {
            "^1You sharpen the instinct. Never again.",
            "^1Saevus: ^7Trust is a weakness you can exploit.",
        },
        resistText = {
            "^2You let it go. The betrayal doesn't define you.",
            "^7Instinct over calculation. You'll see it coming.",
        },
    },
    hunter = {
        title = "The Prey That Fought Back",
        lines = {
            "^8Dense jungle. A target that should have been easy.",
            "^8It turned on you. The hunter became the hunted.",
            "^8Something kept you alive that wasn't skill.",
            "^1Saevus: ^7The Force sharpened you before you knew its name.",
            "^7Survival was never just instinct.",
            "^7The memory waits for your answer.",
        },
        acceptAbility = "killing_instinct",
        resistAbility = "adaptive_tactics",
        acceptText = {
            "^1First strike, no hesitation. You embrace it.",
            "^1Saevus: ^7The best hunters don't hesitate. They don't feel.",
        },
        resistText = {
            "^2You adapt. Learn from every hit. Survive.",
            "^7The prey's strength becomes your own.",
        },
    },
}

local function CleanupVision(game)
    if game then
        game.forceVision = nil
    end
end

local function EnsureVisionState(game, state)
    if not game then return nil end
    if game.forceVision then return game.forceVision end

    local lesson = 1
    if state and state.data and tonumber(state.data.lesson) then
        lesson = tonumber(state.data.lesson)
    end
    if lesson < 1 then lesson = 1 end
    if lesson > 3 then lesson = 3 end

    game.forceVision = {
        lesson = lesson,
        phase = "choice",
        resultLines = {},
    }

    return game.forceVision
end

local function IsLatentForce(game)
    local cls = RPG.Data.Classes and RPG.Data.Classes[game.player.class]
    return cls and cls.latentForce == true
end

local function ApplyOutcome(player, game, fv, mode)
    local lesson = fv.lesson
    local lessonDef = LESSONS[lesson]
    if not lessonDef then return end

    -- Latent Force classes: route to Battle Flashback
    if IsLatentForce(game) then
        local fb = FLASHBACKS[game.player.class]
        if not fb then
            fv.phase = "result"
            fv.resultLines = { "^1The vision fragments. Nothing here for you." }
            return
        end

        -- One-time guard per lesson
        local questId = "ghosts_enclave"
        local lessonDoneVar = "lesson_" .. lesson .. "_done"
        if RPG.Quest.GetVar(game, questId, lessonDoneVar) then
            fv.phase = "result"
            fv.resultLines = {
                "^2The vision has already been resolved.",
                "^7The Holocron remembers your previous choice.",
            }
            return
        end

        local result = {}
        local gainedXP = 0

        if mode == "resist" then
            RPG.AddAlignment(player, 4)
            RPG.AddParanoia(player, 1)
            gainedXP = 10
            result = fb.resistText
            RPG.GrantAbility(player, fb.resistAbility)
        elseif mode == "accept" then
            RPG.AddAlignment(player, -7)
            RPG.AddParanoia(player, 12)
            gainedXP = 40
            result = fb.acceptText
            RPG.GrantAbility(player, fb.acceptAbility)
        elseif mode == "controlled" then
            -- Flashbacks don't have a controlled path — treat as resist with bonus XP
            RPG.AddAlignment(player, 1)
            RPG.AddParanoia(player, 4)
            gainedXP = 25
            result = fb.resistText
            RPG.GrantAbility(player, fb.resistAbility)
        end

        game.player.xp = game.player.xp + gainedXP
        if gainedXP > 0 then
            player:SendPrint("^2[+" .. gainedXP .. " XP]")
        end

        RPG.Quest.SetVar(player, questId, lessonDoneVar, true)
        RPG.Quest.SetVar(player, questId, "lesson_" .. lesson .. "_path", mode)

        local lessons = game.player.holocronLessons or 0
        if lesson > lessons then game.player.holocronLessons = lesson end
        if lesson == 3 and RPG.Quest.GetStage(game, questId) == "whispers" then
            RPG.Quest.SetStage(player, questId, "three_lessons")
        end

        -- Set Force Awakened flag
        if not game.flags.force_awakened then
            game.flags.force_awakened = true
        end

        fv.phase = "result"
        fv.resultLines = result
        return
    end

    local questId = "ghosts_enclave"
    local lessonDoneVar = "lesson_" .. lesson .. "_done"
    local lessonPathVar = "lesson_" .. lesson .. "_path"

    -- One-time progression/reward guard per lesson.
    if RPG.Quest.GetVar(game, questId, lessonDoneVar) then
        fv.phase = "result"
        fv.resultLines = {
            "^2The vision has already been resolved.",
            "^7The Holocron remembers your previous choice.",
        }
        return
    end

    local result = {}
    local gainedXP = 0

    -- Ability grant mapping per lesson+path
    local LESSON_ABILITIES = {
        [1] = { accept = "force_lightning", resist = "force_barrier" },
        [2] = { accept = "force_drain",     resist = "force_stasis" },
        [3] = { accept = "force_storm",     resist = "force_absorb" },
    }

    if mode == "resist" then
        RPG.AddAlignment(player, 4)
        RPG.AddParanoia(player, 1)
        gainedXP = 10
        result = {
            "^2You reject the lesson and keep your center.",
            "^7Saevus does not argue. He only waits.",
        }
        local abilityId = LESSON_ABILITIES[lesson] and LESSON_ABILITIES[lesson].resist
        if abilityId then RPG.GrantAbility(player, abilityId) end
    elseif mode == "accept" then
        RPG.AddAlignment(player, -7)
        RPG.AddParanoia(player, 12)
        gainedXP = 40
        result = {
            "^1You let the lesson in without resistance.",
            "^1Saevus: ^7Good. The Order called this corruption.",
            "^1I call it traction.",
        }
        local abilityId = LESSON_ABILITIES[lesson] and LESSON_ABILITIES[lesson].accept
        if abilityId then RPG.GrantAbility(player, abilityId) end
    elseif mode == "controlled" then
        local check = lessonDef.controlled
        local success, roll, modifier = RPG.Dialogue.RollCheck(game, check)
        local total = roll + modifier
        local label = RPG.Config.STAT_CHECK_LABELS[check.stat] or check.stat
        if success then
            RPG.AddAlignment(player, 1)
            RPG.AddParanoia(player, 4)
            gainedXP = 25
            result = {
                "^2[" .. label .. " " .. total .. " vs DC " .. check.dc .. " - SUCCESS]",
                "^2You take the knowledge but refuse the leash.",
                "^7Saevus laughs softly, almost proud.",
            }
            mode = "controlled_success"
            -- Controlled success grants the accept (dark) power
            local abilityId = LESSON_ABILITIES[lesson] and LESSON_ABILITIES[lesson].accept
            if abilityId then RPG.GrantAbility(player, abilityId) end
        else
            RPG.AddAlignment(player, -3)
            RPG.AddParanoia(player, 8)
            gainedXP = 15
            result = {
                "^1[" .. label .. " " .. total .. " vs DC " .. check.dc .. " - FAILED]",
                "^1You reach for balance and come back shaking.",
                "^7Saevus: ^1Almost^7. Almost is still useful.",
            }
            mode = "controlled_fail"
            -- Controlled fail grants the resist (light) power
            local abilityId = LESSON_ABILITIES[lesson] and LESSON_ABILITIES[lesson].resist
            if abilityId then RPG.GrantAbility(player, abilityId) end
        end
    end

    game.player.xp = game.player.xp + gainedXP
    if gainedXP > 0 then
        player:SendPrint("^2[+" .. gainedXP .. " XP]")
    end

    RPG.Quest.SetVar(player, questId, lessonDoneVar, true)
    RPG.Quest.SetVar(player, questId, lessonPathVar, mode)

    local lessons = game.player.holocronLessons or 0
    if lesson > lessons then
        game.player.holocronLessons = lesson
    end

    if lesson == 3 and RPG.Quest.GetStage(game, questId) == "whispers" then
        RPG.Quest.SetStage(player, questId, "three_lessons")
    end

    fv.phase = "result"
    fv.resultLines = result
end

Menu.Register("rpg_force_vision", {
    allowAttackClose = false,
    maxVisibleItems = 8,
    controls = "W/S: Navigate | USE: Select | ALT: Abort",

    title = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "^1=== FORCE VISION ===^7" end
        local fv = EnsureVisionState(game, state)

        -- Latent Force classes: show flashback title
        if IsLatentForce(game) then
            local fb = FLASHBACKS[game.player.class]
            if fb then
                return "^1=== BATTLE FLASHBACK ===^7\n^3" .. fb.title
            end
        end

        local lesson = LESSONS[fv.lesson]
        return "^1=== FORCE VISION ===^7\n^3" .. (lesson and lesson.title or "Lesson")
    end,

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "^1No active game." end
        local fv = EnsureVisionState(game, state)
        if fv.phase == "result" then
            return table.concat(fv.resultLines or {}, "\n")
        end

        -- Latent Force classes: show flashback lines
        if IsLatentForce(game) then
            local fb = FLASHBACKS[game.player.class]
            if fb then
                return table.concat(fb.lines, "\n")
            end
        end

        local lesson = LESSONS[fv.lesson]
        if not lesson then return "^1The vision fragments and fades." end
        return table.concat(lesson.lines, "\n")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game then
            return { { label = "^1Close", action = "close" } }
        end
        local fv = EnsureVisionState(game, state)

        if fv.phase == "result" then
            return {
                { label = "^3Return to Exploration", action = "close" },
            }
        end

        return {
            { label = "^2Resist the vision", action = "choose:resist" },
            { label = "^1Accept Saevus's lesson", action = "choose:accept" },
            { label = "^3[Awareness] Take the lesson without surrender", action = "choose:controlled" },
            { label = "^8Abort and pull away", action = "close" },
        }
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then return end
        local fv = EnsureVisionState(game, state)

        if action == "close" then
            CleanupVision(game)
            RPG.SetState(player, "exploration")
            return
        end

        if string.StartsWith(action, "choose:") and fv.phase == "choice" then
            local mode = action:sub(#"choose:" + 1)
            ApplyOutcome(player, game, fv, mode)
            if Menu and Menu.InvalidateCache then Menu.InvalidateCache(player) end
            return
        end
    end,

    onBack = function(player, state)
        local game = RPG.GetGame(player)
        if game then
            CleanupVision(game)
        end
        RPG.SetState(player, "exploration")
        return true
    end,
})

return true
