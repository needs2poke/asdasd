-- Dialogue Tree: Captain Saren (Onderon Security)
-- Act 2, Room 31 (Security Checkpoint)
-- Paranoia-gated authority, Q16 security footage
-- ~20 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- High paranoia: hostile interrogation
            { condition = function(g)
                return g.player.paranoia >= 50
                    and not RPG.Quest.HasFlag(g, "saren_stood_down")
            end, node = 10 },
            -- Q16 investigate_footage stage
            { condition = function(g)
                return RPG.Quest.GetStage(g, "the_mimic") == "investigate_footage"
            end, node = 20 },
            -- Q16 complete
            { condition = function(g)
                return RPG.Quest.IsComplete(g, "the_mimic")
            end, node = 30 },
            -- Already stood down
            { condition = function(g)
                return RPG.Quest.HasFlag(g, "saren_stood_down")
            end, node = 25 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Neutral greeting
    -- ============================================
    [1] = {
        speaker = "Captain Saren",
        text = {
            "A rigid officer in polished armor studies you from behind",
            "the security console. His hand rests on his blaster.",
            "'^7Traveler. This checkpoint monitors all traffic between",
            "the Merchant Quarter and the outer sectors.'",
            "'^7We've had reports of... disturbances. I'd appreciate",
            "your cooperation if you've seen anything unusual.'",
        },
        responses = {
            {
                label = "What kind of disturbances?",
                next = 2,
            },
            {
                label = "I might have information about the murders.",
                next = 3,
                condition = function(g)
                    return RPG.Quest.HasFlag(g, "mimic_witness_spoken")
                end,
            },
            {
                label = "[CHA 13] I'm new to Onderon. Just passing through.",
                next = 4,
                check = { stat = "CHA", dc = 13 },
                failNext = 5,
            },
            {
                label = "No trouble here. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Disturbance reports
    -- ============================================
    [2] = {
        speaker = "Captain Saren",
        text = {
            "'^7Multiple homicides this week. Victims found in the",
            "Lower Levels and Dark Alley. All killed the same way --",
            "throat lacerations, deep tissue degradation.'",
            "'^7Witnesses describe a robed figure with glowing",
            "purple eyes. Sound familiar?'",
            "He watches your reaction carefully.",
        },
        responses = {
            {
                label = "I'm investigating the same thing. We should cooperate.",
                next = 6,
            },
            {
                label = "It sounds like a Sith artifact projection.",
                next = 6,
                condition = function(g)
                    return RPG.Quest.IsActive(g, "the_mimic")
                end,
            },
            {
                label = "I don't know anything about that.",
                next = 5,
            },
        },
    },

    -- ============================================
    -- NODE 3: Player has witness info
    -- ============================================
    [3] = {
        speaker = "Captain Saren",
        text = {
            "His eyes narrow with interest.",
            "'^7Information? About the murders? I'm listening.'",
            "'^7We've had exactly zero credible leads. If you know",
            "something, now is the time.'",
        },
        responses = {
            {
                label = "A witness saw two identical figures. The killer is a copy of me.",
                next = 6,
            },
            {
                label = "The attacks are connected to a Sith Holocron.",
                next = 6,
                condition = function(g) return g.player.hasHolocron end,
            },
        },
    },

    -- ============================================
    -- NODE 4: CHA success - casual
    -- ============================================
    [4] = {
        speaker = "Captain Saren",
        text = {
            "He nods curtly.",
            "'^7New arrival. Noted. Keep your nose clean and we",
            "won't have problems.'",
            "'^7Word of advice: avoid the Lower Levels after dark.",
            "Whatever is killing people down there doesn't seem",
            "to care about jurisdiction.'",
        },
        responses = {
            {
                label = "Thanks for the warning. [Leave]",
                next = -1,
            },
            {
                label = "Actually, I may know something about the murders.",
                next = 6,
                condition = function(g)
                    return RPG.Quest.HasFlag(g, "mimic_witness_spoken")
                end,
            },
        },
    },

    -- ============================================
    -- NODE 5: Suspicion / CHA fail
    -- ============================================
    [5] = {
        speaker = "Captain Saren",
        text = {
            "His hand tightens on his blaster.",
            "'^7You don't know anything. Right.'",
            "'^7You match the description we have on file, you know.",
            "Height, build, robes. The witnesses described someone",
            "who looks exactly like you.'",
            "'^7Don't leave the city.'",
        },
        responses = {
            {
                label = "I'm not the killer. But I know what is.",
                next = 6,
            },
            {
                label = "Understood, Captain. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 6: Cooperation node - Holocron revelation
    -- ============================================
    [6] = {
        speaker = "Captain Saren",
        text = {
            "He listens. His expression shifts from suspicion to",
            "something more complicated.",
            "'^7A projection. Created by a Sith artifact. That',",
            "he pauses, '^7actually explains the security footage.'",
            "'^7We have recordings from three different cameras.",
            "Two figures. Identical. One with normal eyes, one with",
            "purple. We assumed it was a glitch.'",
            "'^7If what you're saying is true, we have evidence.'",
        },
        effects = {
            action = function(player, game)
                if RPG.Quest.IsActive(game, "the_mimic") then
                    local stage = RPG.Quest.GetStage(game, "the_mimic")
                    if stage == "speak_venn" or stage == "investigate_alley"
                        or stage == "investigate_trace" then
                        RPG.Quest.SetStage(player, "the_mimic", "investigate_footage")
                    end
                end
            end,
        },
        responses = {
            {
                label = "Show me the footage.",
                next = 20,
            },
            {
                label = "Keep an eye on the Lower Levels. I'll handle this.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: HOSTILE INTERROGATION (paranoia >= 50)
    -- ============================================
    [10] = {
        speaker = "Captain Saren",
        text = {
            "Four guards level blasters at you. Saren steps forward,",
            "his face hard as durasteel.",
            "'^1You. Don't move.^7'",
            "'^7We've been looking for you. The description matches.",
            "The robes, the build, the timing of the murders.'",
            "'^7You're coming with me. Or this gets ugly.'",
        },
        responses = {
            {
                label = "[STR 14] You don't want to do this. Trust me.",
                next = 16,
                check = { stat = "STR", dc = 14 },
                failNext = 17,
            },
            {
                label = "[WIS 15] Look at my eyes. They're not purple.",
                next = 16,
                check = { stat = "WIS", dc = 15 },
                failNext = 17,
            },
            {
                label = "[CHA 15] Captain, another attack will happen while you waste time with me.",
                next = 16,
                check = { stat = "CHA", dc = 15 },
                failNext = 17,
            },
            {
                label = "Fine. Take me in.",
                next = 17,
            },
        },
    },

    -- ============================================
    -- NODE 16: Stand-down (check success)
    -- ============================================
    [16] = {
        speaker = "Captain Saren",
        text = {
            "He hesitates. His comm unit crackles to life.",
            "'^3[DISPATCH] Captain Saren -- report of another attack.",
            "Sector 7. Victim matches the same pattern. Suspect",
            "described as... robed figure, purple eyes.^7'",
            "Saren goes pale. You're HERE. The attack is across",
            "the city. It can't be you.",
            "'^7...Stand down. Lower your weapons.'",
            "He looks at you. The hostility drains away, replaced",
            "by something worse: uncertainty.",
            "'^7You're not the killer. But you know what is.'",
        },
        effects = {
            setFlag = "saren_stood_down",
        },
        responses = {
            {
                label = "Yes. And I need your help to stop it.",
                next = 6,
            },
        },
    },

    -- ============================================
    -- NODE 17: Submit / check fail
    -- ============================================
    [17] = {
        speaker = "Captain Saren",
        text = {
            "The guards close in. Then Saren's comm unit crackles.",
            "'^3[DISPATCH] Captain -- another attack. Sector 7.",
            "Same description. Purple eyes. Happening RIGHT NOW.^7'",
            "Saren stares at the comm, then at you.",
            "'^7...You've been standing right here.'",
            "'^7Release them. Stand down.'",
            "He holsters his blaster slowly.",
            "'^7I owe you an explanation. And an apology.'",
        },
        effects = {
            setFlag = "saren_stood_down",
        },
        responses = {
            {
                label = "Apology accepted. Now let's catch the real killer.",
                next = 6,
            },
        },
    },

    -- ============================================
    -- NODE 20: SECURITY FOOTAGE
    -- ============================================
    [20] = {
        speaker = "Captain Saren",
        text = {
            "He pulls up the footage on the security console.",
            "The recording shows a dark alley. Two figures enter --",
            "identical in every way. Same robes, same stride, same",
            "build.",
            "'^7There. Watch the eyes.'",
            "One figure's eyes pulse purple. It moves with inhuman",
            "fluidity. The other -- the victim -- never sees it coming.",
            "'^7Two of you. Exactly alike. Except the eyes.'",
        },
        responses = {
            {
                label = "[WIS 16] Enhance the hands. Look at the projection's fingers.",
                next = 22,
                check = { stat = "WIS", dc = 16 },
                failNext = 23,
            },
            {
                label = "Can you track where it went after the attack?",
                next = 23,
            },
        },
    },

    -- ============================================
    -- NODE 22: WIS success - Mimic is not solid
    -- ============================================
    [22] = {
        speaker = "Captain Saren",
        text = {
            "He zooms in. The purple-eyed figure's hands...",
            "'^7Stars. Its hands aren't solid. Look -- the fingers",
            "pass through the wall when it touches it.'",
            "'^7It's not a person. It's a projection. A Force",
            "construct given physical form.'",
            "",
            "He pauses. His jaw tightens.",
            "'^7No. Not a copy. A ^1rehearsal^7. Whatever's",
            "piloting this thing is practicing.'",
            "",
            "'^7That means it has a source. Cut the source and",
            "the projection dies.'",
            "He looks at you meaningfully.",
            "'^7The source is the artifact you carry. Isn't it?'",
        },
        effects = {
            setStage = { quest = "the_mimic", stage = "confront_truth" },
        },
        responses = {
            {
                label = "Yes. The Holocron is creating it. I need to destroy the Mimic.",
                next = 23,
            },
        },
    },

    -- ============================================
    -- NODE 23: Key insight - advances Q16
    -- ============================================
    [23] = {
        speaker = "Captain Saren",
        text = {
            "'^7The footage shows it heading toward the Lower Levels",
            "after each attack. Sublevel 3.'",
            "'^7I can't send my guards down there -- whatever this",
            "thing is, blasters won't stop a Force projection.'",
            "'^7But you might.'",
            "He straightens up.",
            "'^7You have my support. Find this thing and end it.",
            "I'll keep the guards out of your way.'",
        },
        effects = {
            action = function(player, game)
                local stage = RPG.Quest.GetStage(game, "the_mimic")
                if stage == "investigate_footage" then
                    RPG.Quest.SetStage(player, "the_mimic", "confront_truth")
                end
            end,
        },
        responses = {
            {
                label = "I'll handle it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 25: Stood down revisit
    -- ============================================
    [25] = {
        speaker = "Captain Saren",
        text = {
            "'^7Any progress? The attacks are continuing. My superiors",
            "want answers I don't have.'",
        },
        responses = {
            {
                label = "I have security footage evidence. [If Q16 active]",
                next = 20,
                condition = function(g)
                    return RPG.Quest.GetStage(g, "the_mimic") == "investigate_footage"
                        or RPG.Quest.GetStage(g, "the_mimic") == "investigate_trace"
                end,
            },
            {
                label = "Working on it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Q16 complete
    -- ============================================
    [30] = {
        speaker = "Captain Saren",
        text = {
            "For the first time, Saren almost smiles.",
            "'^7The attacks have stopped. Completely. Whatever you",
            "did in the Lower Levels, it worked.'",
            "'^7I've closed the investigation. The official report",
            "lists the cause as \"anomalous Force activity.\" The",
            "real truth stays between us.'",
            "'^7You've earned some goodwill with Onderon Security.",
            "Don't squander it.'",
        },
        responses = {
            {
                label = "Glad I could help, Captain. [Leave]",
                next = -1,
            },
        },
    },
}
