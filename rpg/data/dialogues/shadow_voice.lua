-- Dialogue Tree: The Shadow's Voice (NPC 20)
-- Pre/post Shadow Self combat in the Inner Sanctum (Room 42)
-- ~30 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Post-combat: shadow defeated
            { condition = function(g) return g.flags["shadow_self_defeated"] end, node = 50 },
            -- Mid-quest: already confronting
            { condition = function(g) return RPG.Quest.GetStage(g, "escape_loop") == "confront_shadow" end, node = 20 },
            -- Quest active but not yet at confront stage
            { condition = function(g) return RPG.Quest.IsActive(g, "escape_loop") end, node = 1 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: First Meeting (Pre-Combat)
    -- ============================================
    [1] = {
        speaker = "The Shadow's Voice",
        text = {
            "A figure rises from the sarcophagus's shadow — your height,",
            "your build, your face. But the eyes are wrong. Too old.",
            "Too knowing. It speaks with your voice.",
            "",
            "'Finally. I've been waiting for you to stop running",
            "through the same halls over and over.'",
        },
        responses = {
            {
                label = "What are you?",
                next = 2,
            },
            {
                label = "[WIS 14] You're not me. You're the tomb's last test.",
                next = 5,
                check = { stat = "WIS", dc = 14 },
                failNext = 3,
            },
            {
                label = "I'm not afraid of my own reflection.",
                next = 4,
            },
            {
                label = "The Holocron sent you.",
                truthLabel = "The Holocron amplifies what was already inside you.",
                isDoubt = true,
                next = 6,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 30 end,
            },
        },
    },

    -- ============================================
    -- NODE 2: "What are you?"
    -- ============================================
    [2] = {
        speaker = "The Shadow's Voice",
        text = {
            "It tilts its head — your gesture, perfectly mirrored.",
            "",
            "'I am what you left behind. Every doubt you buried.",
            "Every anger you swallowed. Every fear you pretended",
            "didn't exist. The tomb didn't create me.'",
            "",
            "'You did.'",
        },
        responses = {
            {
                label = "Then we can talk this out.",
                next = 7,
            },
            {
                label = "If you're part of me, I can destroy you.",
                next = 10,
            },
            {
                label = "What do you want?",
                next = 8,
            },
        },
    },

    -- ============================================
    -- NODE 3: WIS check failed
    -- ============================================
    [3] = {
        speaker = "The Shadow's Voice",
        text = {
            "It laughs — your laugh, but colder.",
            "",
            "'A test? No. Tests have right answers.",
            "I am the question you've been avoiding",
            "since Dantooine. Since before Dantooine.'",
        },
        responses = {
            {
                label = "What question?",
                next = 8,
            },
            {
                label = "I don't need to understand you to beat you.",
                next = 10,
            },
        },
    },

    -- ============================================
    -- NODE 4: "I'm not afraid"
    -- ============================================
    [4] = {
        speaker = "The Shadow's Voice",
        text = {
            "'Aren't you? Then why did your hand move",
            "to your weapon the moment you saw me?'",
            "",
            "It steps closer. The air grows colder.",
            "",
            "'Fear isn't weakness. Lying about it is.'",
        },
        responses = {
            {
                label = "What do you want?",
                next = 8,
            },
            {
                label = "Fine. Let's end this.",
                next = 10,
            },
        },
    },

    -- ============================================
    -- NODE 5: WIS check passed — sees through it
    -- ============================================
    [5] = {
        speaker = "The Shadow's Voice",
        text = {
            "For a moment, its composure breaks. Surprise.",
            "",
            "'Perceptive. Yes. The tomb amplifies what's inside you",
            "and gives it form. I am real — but I am also a mechanism.",
            "A final gate. The Sith who built this place believed",
            "that power required self-knowledge.'",
            "",
            "'So. Do you know yourself?'",
        },
        responses = {
            {
                label = "I know myself well enough. Let me pass.",
                next = 12,
            },
            {
                label = "I know I need to fight you. Let's begin.",
                next = 10,
            },
            {
                label = "What happens if I fail?",
                next = 9,
            },
        },
    },

    -- ============================================
    -- NODE 6: Doubt option (Holocron paranoia)
    -- ============================================
    [6] = {
        speaker = "The Shadow's Voice",
        text = {
            "It pauses. Studies you with eyes that are yours",
            "but not yours.",
            "",
            "'The Holocron didn't send me. It can't — it's a prison,",
            "not a mind. But it echoes. Amplifies. What you see",
            "standing before you is YOUR darkness, given form",
            "by this tomb's architecture.'",
            "",
            "'The question is: do you own it, or does it own you?'",
        },
        responses = {
            {
                label = "I own my darkness.",
                next = 7,
            },
            {
                label = "Let's find out. Fight me.",
                next = 10,
            },
        },
    },

    -- ============================================
    -- NODE 7: Diplomatic path — merge willingly
    -- ============================================
    [7] = {
        speaker = "The Shadow's Voice",
        text = {
            "It extends a hand. Your hand.",
            "",
            "'Then take what I am. Accept the rage, the fear,",
            "the despair. Stop pretending they don't exist.",
            "Merge with me willingly, and the tomb's trial",
            "ends without blood.'",
            "",
            "'But know this: what you absorb changes you.",
            "Darkness accepted is still darkness.'",
        },
        responses = {
            {
                label = "I accept you. We are one. [Dark: Alignment -10]",
                next = 15,
                effects = { alignment = -10 },
            },
            {
                label = "No. I won't take the easy path. Fight me.",
                next = 10,
            },
            {
                label = "[WIS 14] Accepting darkness isn't the same as surrendering to it.",
                next = 16,
                check = { stat = "WIS", dc = 14 },
                failNext = 15,
            },
        },
    },

    -- ============================================
    -- NODE 8: "What do you want?"
    -- ============================================
    [8] = {
        speaker = "The Shadow's Voice",
        text = {
            "'What every shadow wants. To stop being ignored.'",
            "",
            "It circles the sarcophagus, running your fingers",
            "along the crystallized surface.",
            "",
            "'You've spent your whole life suppressing me.",
            "On Dantooine, in the caves, on Onderon.",
            "Every time you chose restraint, I grew stronger.",
            "Every time you looked away from what you are,",
            "I became more real.'",
        },
        responses = {
            {
                label = "Then let's resolve this peacefully.",
                next = 7,
            },
            {
                label = "You want a fight? You've got one.",
                next = 10,
            },
        },
    },

    -- ============================================
    -- NODE 9: "What happens if I fail?"
    -- ============================================
    [9] = {
        speaker = "The Shadow's Voice",
        text = {
            "'Then I become the primary. And you become",
            "the shadow. The tomb has seen it before.'",
            "",
            "It gestures at the sarcophagus.",
            "",
            "'The Sith Lord entombed here failed this trial.",
            "The thing inside the Holocron? That was once",
            "the shadow. It won.'",
        },
        responses = {
            {
                label = "That won't happen to me. Let's fight.",
                next = 10,
            },
            {
                label = "Maybe we can find another way.",
                next = 7,
            },
        },
    },

    -- ============================================
    -- NODE 10: Combat initiation
    -- ============================================
    [10] = {
        speaker = "The Shadow's Voice",
        text = {
            "The Shadow's expression hardens — your expression,",
            "in the mirror, when you've made a decision.",
            "",
            "'So be it. I know every move you'll make",
            "before you make it. I AM you.'",
            "",
            "It draws a weapon. Your weapon. The sarcophagus",
            "pulses with dark energy as the trial begins.",
        },
        effects = {
            startCombat = 17,
            setFlag = "shadow_combat_started",
            setStage = { quest = "escape_loop", stage = "confront_shadow" },
        },
        responses = {},
    },

    -- ============================================
    -- NODE 12: "Let me pass" (after WIS success)
    -- ============================================
    [12] = {
        speaker = "The Shadow's Voice",
        text = {
            "'Self-knowledge without confrontation?",
            "That's not how this tomb works.'",
            "",
            "Its form solidifies. Becomes more real.",
            "More dangerous.",
            "",
            "'The architects were Sith. They believed",
            "in trial by combat. So do I.'",
        },
        effects = {
            startCombat = 17,
            setFlag = "shadow_combat_started",
            setStage = { quest = "escape_loop", stage = "confront_shadow" },
        },
        responses = {},
    },

    -- ============================================
    -- NODE 15: Dark merge (accepted shadow willingly)
    -- ============================================
    [15] = {
        speaker = "The Shadow's Voice",
        text = {
            "You take its hand. The shadow flows into you",
            "like cold water. Your vision darkens, then clears.",
            "",
            "You feel... different. Heavier. The rage, the fear,",
            "the despair — they're yours now. Acknowledged.",
            "The tomb's trial is satisfied.",
            "",
            "But the sarcophagus still pulses.",
            "The Shadow Self won't go quietly.",
        },
        effects = {
            startCombat = 17,
            setFlag = "shadow_dark_merge",
            setStage = { quest = "escape_loop", stage = "confront_shadow" },
        },
        responses = {},
    },

    -- ============================================
    -- NODE 16: WIS merge (understanding, not surrender)
    -- ============================================
    [16] = {
        speaker = "The Shadow's Voice",
        text = {
            "It blinks. For a moment, something like respect",
            "crosses its — your — face.",
            "",
            "'Understanding without surrender. The Jedi way.",
            "Or perhaps just wisdom.'",
            "",
            "The shadow wavers but doesn't dissolve.",
            "'The tomb still demands its trial. But you've",
            "earned something the others never did: clarity.'",
        },
        effects = {
            startCombat = 17,
            alignment = 5,
            setFlag = "shadow_wise_merge",
            setStage = { quest = "escape_loop", stage = "confront_shadow" },
        },
        responses = {},
    },

    -- ============================================
    -- NODE 20: Return visit (confront_shadow stage, combat not yet won)
    -- ============================================
    [20] = {
        speaker = "The Shadow's Voice",
        text = {
            "The Shadow reforms from the sanctum's darkness.",
            "",
            "'Back again. Did you think running would help?",
            "I am you. I am everywhere you go.'",
        },
        responses = {
            {
                label = "This time I'm ready.",
                next = 10,
            },
            {
                label = "Let's try talking again.",
                next = 7,
            },
        },
    },

    -- ============================================
    -- NODE 50: Post-Combat (shadow_self_defeated)
    -- ============================================
    [50] = {
        speaker = "The Shadow's Voice",
        text = function(g)
            if g.flags["shadow_wise_merge"] then
                return {
                    "A whisper from nowhere — your voice, but gentler.",
                    "",
                    "'You understood before the fight even began.",
                    "That's rare. The tomb has tested thousands.",
                    "Most never see the truth: the shadow isn't",
                    "the enemy. Ignorance is.'",
                    "",
                    "'Go forward. The void awaits.'",
                }
            elseif g.flags["shadow_dark_merge"] then
                return {
                    "A whisper from nowhere — your voice, but darker.",
                    "",
                    "'You took what I offered. Good. Power demands",
                    "honesty about what you are. The Sith understood this.",
                    "The Jedi never did.'",
                    "",
                    "'The path north is open. Use what you've become.'",
                }
            else
                return {
                    "A whisper from nowhere — your voice, fading.",
                    "",
                    "'You won. But I'm still inside you.",
                    "Every choice you make, every moment of doubt —",
                    "that's me. I don't die. I just go quiet.'",
                    "",
                    "'For now.'",
                    "",
                    "'The path north is open.'",
                }
            end
        end,
        responses = {
            {
                label = "I understand. [Leave]",
                next = -1,
            },
            {
                label = "Will I see you again?",
                next = 55,
            },
        },
    },

    -- ============================================
    -- NODE 55: "Will I see you again?"
    -- ============================================
    [55] = {
        speaker = "The Shadow's Voice",
        text = {
            "'Every time you look in a mirror.",
            "Every time you hesitate. Every time",
            "you wonder if you made the right choice.'",
            "",
            "'I am the question. You are the answer.'",
            "",
            "The voice fades. The sanctum is still.",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },
}
