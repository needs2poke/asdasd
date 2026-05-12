-- Dialogue Tree: Administrator Terena Adare
-- Main quest giver, authority figure, Room 1
-- ~25 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- P1: Active echoes stages (departure/secret/sold take priority)
            { condition = function(g) return RPG.Quest.GetStage(g, "echoes") == "departure" end, node = 60 },
            { condition = function(g) return RPG.Quest.GetStage(g, "echoes") == "kept_secret" end, node = 50 },
            { condition = function(g) return RPG.Quest.GetStage(g, "echoes") == "sold_holocron" end, node = 55 },
            -- P2: Completed quest reactions (newest first, intercept before generic stages)
            { condition = function(g) return RPG.Quest.IsComplete(g, "ghosts_enclave") and not RPG.Quest.HasFlag(g, "terena_ghosts_discussed") end, node = 75 },
            { condition = function(g)
                return RPG.Quest.IsComplete(g, "shadows_trail")
                    and RPG.Quest.HasFlag(g, "shadows_trail_light")
                    and not RPG.Quest.HasFlag(g, "terena_revealed_true_sith")
                    and RPG.Quest.GetStage(g, "echoes") == "reported_truth"
                end, node = 45 },
            -- P3: Regular echoes stage routing
            { condition = function(g) return RPG.Quest.GetStage(g, "echoes") == "reported_truth" end, node = 40 },
            { condition = function(g) return RPG.Quest.GetStage(g, "echoes") == "found_holocron" end, node = 20 },
            { condition = function(g) return RPG.Quest.IsActive(g, "echoes") end, node = 10 },
            -- P4: Echoes complete
            { condition = function(g) return RPG.Quest.IsComplete(g, "echoes") end, node = 70 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default Greeting (No quest yet)
    -- ============================================
    [1] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She looks up from a stack of reports, dark circles under her eyes.",
            "'^7The settlement is in chaos. A ship crashed near the Crystal Caves",
            "and the Exchange is circling like vultures. The Republic won't respond",
            "for weeks. I need someone capable.'",
        },
        responses = {
            {
                label = "I'll investigate the crash site.",
                next = 2,
                effects = { startQuest = "echoes" },
            },
            {
                label = "What's in it for me?",
                next = 3,
                alignment = -2,
            },
            {
                label = "[WIS 14] You're not worried about the crash. You're afraid of what's ON that ship.",
                next = 4,
                check = { stat = "WIS", dc = 14 },
                failNext = 5,
            },
            {
                label = "She's hiding something from you.",
                truthLabel = "She is burdened by a secret she cannot share with a stranger.",
                isDoubt = true,
                next = 6,
                alignment = -5,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 20 end,
            },
            {
                label = "I'll think about it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Accepted quest immediately
    -- ============================================
    [2] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Relief flickers across her face, quickly masked.",
            "'^7Thank you. Head north through the Plaza. The crash site is beyond",
            "the Crystal Caves path. Be careful  - kinrath are agitated, and the",
            "Exchange has people out there too.'",
            "'^7Come back when you know what happened. I'll hold things together here.'",
        },
        effects = {
            action = function(player, game)
                game.rooms[4].locked = false
                game.rooms[13].locked = false
            end,
        },
        responses = {
            {
                label = "I'll report back when I find something.",
                next = -1,
            },
            {
                label = "Any weapons or supplies you can spare?",
                next = 7,
            },
        },
    },

    -- ============================================
    -- NODE 3: "What's in it for me?"
    -- ============================================
    [3] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Her jaw tightens. She's heard this before.",
            "'^7Credits. Whatever we can spare. And the gratitude of people who",
            "have nothing left to give. I don't need a hero. I need someone",
            "who comes back.'",
        },
        responses = {
            {
                label = "Fine. I'll do it.",
                next = 2,
                effects = { startQuest = "echoes" },
            },
            {
                label = "Not enough. [Leave]",
                next = -1,
                alignment = -3,
            },
        },
    },

    -- ============================================
    -- NODE 4: WIS check SUCCESS  - see through her
    -- ============================================
    [4] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She freezes. For a moment, the mask slips.",
            "'^7...You're perceptive. The ship bore Jedi markings. Faded, but",
            "unmistakable. If there's Jedi cargo aboard  - artifacts, holocrons  -",
            "half the sector will descend on us. The Exchange already suspects.'",
            "'^7I need someone I can trust to get there first. Will you help?'",
        },
        responses = {
            {
                label = "I understand. I'll investigate.",
                next = 2,
                effects = { startQuest = "echoes" },
                alignment = 2,
            },
            {
                label = "Jedi artifacts? Those are worth a fortune.",
                next = 3,
                alignment = -3,
            },
        },
    },

    -- ============================================
    -- NODE 5: WIS check FAILURE
    -- ============================================
    [5] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She gives you a flat look.",
            "'^7I'm worried about everything, stranger. That's my job.'",
            "'^7Will you investigate or not?'",
        },
        responses = {
            {
                label = "I'll investigate.",
                next = 2,
                effects = { startQuest = "echoes" },
            },
            {
                label = "I need to think about it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 6: Doubt option (Holocron manipulation)
    -- ============================================
    [6] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Your words cut deeper than you intended. Her composure cracks.",
            "'^7Everyone is hiding something. That's how people survive.'",
            "'^7You want truth? Fine. I worked at the Enclave. Administrative",
            "staff -- records, supply logistics. I wasn't a student. But I saw",
            "enough to know what the Force can do to people. And what losing it does.'",
            "She looks away. '^7Now will you help, or was that just cruelty?'",
        },
        responses = {
            {
                label = "I... I'm sorry. I'll help.",
                next = 2,
                effects = { startQuest = "echoes" },
                alignment = 2,
            },
            {
                label = "Now I know your weakness. I'll help  - for a price.",
                next = 3,
                alignment = -5,
                setFlag = "adare_blackmail",
            },
        },
    },

    -- ============================================
    -- NODE 7: Ask for supplies
    -- ============================================
    [7] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Talk to Goran in the Plaza. Tell him I sent you. He'll complain,",
            "but he'll give you a fair price. And check the medical bay if you",
            "need patching up.'",
        },
        responses = {
            {
                label = "Thanks. I'll head out.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: Quest active, still investigating
    -- ============================================
    [10] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7You're back. Any news from the crash site?'",
        },
        responses = {
            {
                label = "Still investigating. I'll report back soon.",
                next = 11,
            },
            {
                label = "The path is dangerous. Those kinrath are no joke.",
                next = 12,
            },
        },
    },

    [11] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Hurry. The Exchange gets bolder every day. And the settlers",
            "are getting nervous. I can only keep the peace for so long.'",
        },
        responses = {
            { label = "I'm on it. [Leave]", next = -1 },
        },
    },

    [12] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7The kinrath have been agitated since the crash. Something on",
            "that ship is disturbing them. Be careful, but don't turn back.",
            "We need to know what's out there.'",
        },
        responses = {
            { label = "Understood. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 20: Found the Holocron  - major branch point
    -- ============================================
    [20] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She studies your face as you approach. Something has changed.",
            "'^7I can see it in your eyes. You found something. Tell me.'",
        },
        saevusWhisper = "A voice in the back of your mind: \"She'll take it from you. They always do.\"",
        saevusCondition = function(g) return g.player.hasHolocron and g.player.paranoia > 30 end,
        responses = {
            {
                label = "I found a dead Jedi and a Sith Holocron.",
                next = 21,
                alignment = 5,
            },
            {
                label = "Just wreckage. Nothing important.",
                next = 30,
                alignment = -5,
            },
            {
                label = "[CHA 12] The ship had cargo, but the Exchange got there first.",
                next = 31,
                check = { stat = "CHA", dc = 12 },
                failNext = 32,
                alignment = -3,
            },
            {
                label = "She'll use this against you. Keep the power for yourself.",
                truthLabel = "The Holocron wants you to hoard its power. She can help contain it.",
                isDoubt = true,
                next = 30,
                alignment = -8,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 20 end,
            },
        },
    },

    -- ============================================
    -- NODE 21: Told the truth about the Holocron
    -- ============================================
    [21] = {
        speaker = "Administrator Terena Adare",
        text = {
            "The color drains from her face.",
            "'^7A Sith Holocron. Here. On Dantooine.'",
            "She takes a slow breath.",
            "'^7We need to get that off-world. The Republic has containment",
            "facilities. I'll send an encrypted message immediately.'",
        },
        responses = {
            {
                label = "It should be destroyed, not contained.",
                next = 22,
            },
            {
                label = "You're right. The Republic should handle this.",
                next = 23,
                setFlag = "reported_truth_flag",
                effects = {
                    setStage = { quest = "echoes", stage = "reported_truth" },
                },
            },
            {
                label = "I could study it first. Learn what the Shadow knew.",
                next = 24,
            },
        },
    },

    [22] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Sith Holocrons can't be destroyed easily. The Jedi tried for",
            "centuries. They need specialized facilities and trained Force users.'",
            "'^7The safest option is Republic containment. Trust me on this.'",
        },
        responses = {
            {
                label = "Fine. Call the Republic.",
                next = 23,
                setFlag = "reported_truth_flag",
                effects = {
                    setStage = { quest = "echoes", stage = "reported_truth" },
                },
            },
            {
                label = "I'll handle it myself.",
                next = 24,
            },
        },
    },

    [23] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Thank you. You've done the right thing.'",
            "She allows herself a tired smile.",
            "'^7The Wanderer is cleared for departure. Take some time to prepare.",
            "And... be careful. If the Exchange learns what was on that ship,",
            "they'll come for you.'",
        },
        effects = { unlockRoom = 16 },
        responses = {
            { label = "I'll be ready. [Leave]", next = -1 },
        },
    },

    [24] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Her expression hardens.",
            "'^7That is exactly what the Holocron wants. Every Sith artifact",
            "is designed to corrupt its wielder. The Shadow is dead because",
            "she got too close.'",
            "'^7Give it to me. Please.'",
        },
        responses = {
            {
                label = "You're right. Take it.",
                next = 23,
                setFlag = "reported_truth_flag",
                effects = {
                    setStage = { quest = "echoes", stage = "reported_truth" },
                },
            },
            {
                label = "No. I need to understand what she found.",
                next = 25,
                alignment = -5,
            },
        },
    },

    [25] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Disappointment. Not anger  - something worse.",
            "'^7I've seen that look before. On the faces of every Jedi who",
            "thought they were strong enough to resist the dark.'",
            "'^7I can't stop you. But I won't help you either. The Wanderer",
            "is cleared for departure. Do what you will.'",
        },
        effects = {
            setStage = { quest = "echoes", stage = "kept_secret" },
            unlockRoom = 16,
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 30: Lied about the Holocron
    -- ============================================
    [30] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She searches your face. She knows you're lying.",
            "'^7...I see. Just wreckage.'",
            "A long pause.",
            "'^7The Wanderer is cleared for departure whenever you're ready.'",
        },
        effects = {
            setStage = { quest = "echoes", stage = "kept_secret" },
            unlockRoom = 16,
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 31: CHA check SUCCESS  - blame Exchange
    -- ============================================
    [31] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Damn them. The Exchange is faster than I thought.'",
            "She slams a fist on the desk.",
            "'^7I'll deal with Draxen. You focus on getting off-world",
            "before things get worse. The Wanderer is ready.'",
        },
        effects = {
            setStage = { quest = "echoes", stage = "kept_secret" },
            unlockRoom = 16,
        },
        responses = {
            { label = "Good luck with the Exchange. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 32: CHA check FAILURE  - she sees through you
    -- ============================================
    [32] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She stares at you for a long, uncomfortable moment.",
            "'^7You're a terrible liar.'",
            "'^7But I can't force the truth out of you. Whatever you found",
            "out there  - I hope you know what you're doing.'",
        },
        effects = {
            setStage = { quest = "echoes", stage = "kept_secret" },
            unlockRoom = 16,
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 40: After reporting truth  - grateful
    -- ============================================
    [40] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7The Republic transport is en route. Two weeks out.'",
            "'^7You should prepare to leave. Dantooine isn't safe for",
            "anyone carrying that kind of knowledge.'",
        },
        responses = {
            {
                label = "Is there anything else I can do before I go?",
                next = 41,
            },
            {
                label = "I'll head to The Wanderer. [Leave]",
                next = -1,
            },
        },
    },

    [41] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Check on Doctor Vara in the medical bay. She's overwhelmed.",
            "And Captain Zherron could use another capable pair of hands",
            "with the kinrath. Talk to people. Help where you can.'",
            "'^7This settlement survives because people look out for each other.'",
        },
        responses = {
            {
                label = "What happened to the Jedi?",
                next = 80,
                condition = function(g) return not RPG.Quest.HasFlag(g, "terena_purge_discussed") end,
            },
            {
                label = "Zherron suspects you trained at the Enclave.",
                next = 46.5,
                condition = function(g)
                    return RPG.Quest.HasFlag(g, "zherron_investigate_adare")
                        and not RPG.Quest.HasFlag(g, "warned_adare")
                end,
            },
            { label = "I'll see what I can do. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 45: Shadow's Trail light reaction (Q3)
    -- ============================================
    [45] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Tamas brought me the Shadow's intelligence. I forwarded it",
            "through Republic encrypted channels.'",
            "'^7The response was... faster than expected. A cruiser is already",
            "being diverted to patrol the Unknown Regions approach.'",
            "'^7They already knew something was out there. They've known for years.'",
        },
        responses = {
            {
                label = "Why didn't they act sooner?",
                next = 46,
            },
            {
                label = "Good. It's in the Republic's hands now. [Leave]",
                next = -1,
                alignment = 1,
            },
        },
    },

    -- ============================================
    -- NODE 46: Republic conspiracy seed
    -- ============================================
    [46] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7After Revan vanished, the Senate classified everything related",
            "to the Unknown Regions. Even the Jedi Council's final reports.'",
            "'^7The official position is that there's nothing out there worth",
            "investigating. The unofficial position...'",
            "She hesitates.",
            "'^7The unofficial position is that whatever Revan found, the Republic",
            "isn't strong enough to fight it. Not yet. Maybe not ever.'",
        },
        responses = {
            {
                label = "What was Revan looking for?",
                next = 47,
            },
            {
                label = "Zherron's been asking questions about you.",
                next = 46.5,
                condition = function(g) return RPG.Quest.HasFlag(g, "zherron_investigate_adare") end,
            },
            {
                label = "I've heard enough. [Leave]",
                next = -1,
            },
        },
    },

    [46.5] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Her jaw tightens. '^7I know. The man sees conspiracies in his",
            "morning rations.'",
            "'^7He's not wrong about me, though. Not entirely. I just wish",
            "he'd trust me long enough to realize I'm not the enemy.'",
        },
        effects = {
            setFlag = "warned_adare",
        },
        responses = {
            {
                label = "What was Revan looking for?",
                next = 47,
            },
            {
                label = "He cares about this place. Like you do. [Leave]",
                next = -1,
                alignment = 2,
            },
        },
    },

    -- ============================================
    -- NODE 47: The True Sith reference
    -- ============================================
    [47] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7The True Sith. Not the fractured cults that Malak and Nihilus",
            "led  - the original empire. The one that's been hiding in the",
            "Stygian Caldera for a thousand years.'",
            "'^7Revan believed they were preparing to return. The Mandalorian",
            "Wars, the Jedi Civil War  - he thought it was all orchestrated.",
            "A prelude.'",
            "'^7I used to think he was paranoid. Now I have a dead Jedi Shadow",
            "on my doorstep with coordinates to prove him right.'",
        },
        effects = { setFlag = "terena_revealed_true_sith" },
        responses = {
            {
                label = "If that's true, we're all in danger.",
                next = -1,
                alignment = 2,
            },
            {
                label = "Then those coordinates are more valuable than I thought.",
                next = -1,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 50: After keeping secret  - distant
    -- ============================================
    [50] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She doesn't meet your eyes.",
            "'^7Is there something you need?'",
        },
        responses = {
            {
                label = "Actually, I want to tell you the truth about the crash.",
                next = 51,
            },
            {
                label = "No. Just passing through. [Leave]",
                next = -1,
            },
        },
    },

    [51] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She looks up, guarded but listening.",
            "'^7I'm listening.'",
        },
        responses = {
            {
                label = "There was a Sith Holocron. I have it.",
                next = 21,
                alignment = 5,
                effects = {
                    setStage = { quest = "echoes", stage = "found_holocron" },
                },
            },
            {
                label = "Never mind. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 55: After selling to Exchange  - cold
    -- ============================================
    [55] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7Word travels fast in a small settlement.'",
            "'^7I know what you did. The Exchange is bragging about their",
            "new acquisition. A Sith artifact, sold like common salvage.'",
            "'^7Get off my world.'",
        },
        effects = { unlockRoom = 16 },
        responses = {
            {
                label = "It wasn't yours to keep either.",
                next = 56,
                alignment = -3,
            },
            {
                label = "[Leave in silence]",
                next = -1,
            },
        },
    },

    [56] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7No. It wasn't. But at least I would have kept people safe.'",
            "'^7Leave. The Wanderer is fueled. That's the last favor",
            "you'll get from Khoonda.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 60: Departure scene
    -- ============================================
    [60] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She meets you at the door. There's a finality in her eyes.",
            "'^7So you're leaving.'",
        },
        responses = {
            {
                label = "Thank you for everything, Adare.",
                next = 61,
                alignment = 3,
                setFlag = "republic_cooperation",
                condition = function(g) return RPG.Quest.GetStage(g, "echoes") == "departure" and RPG.Quest.HasFlag(g, "reported_truth_flag") end,
            },
            {
                label = "This place was never home. Just a stop.",
                next = 62,
                setFlag = "independent_hunter",
            },
            {
                label = "The Holocron showed me things. I need answers.",
                next = 63,
                alignment = -5,
                setFlag = "sith_curiosity",
                condition = function(g) return g.player.hasHolocron end,
            },
            {
                label = "Goodbye, Administrator. [Leave]",
                next = -1,
                setFlag = "independent_hunter",
            },
        },
    },

    [61] = {
        speaker = "Administrator Terena Adare",
        text = {
            "A rare, genuine smile.",
            "'^7Be safe out there. The galaxy needs more people who do",
            "the right thing even when it costs them.'",
            "'^7May the Force be with you. I mean that.'",
        },
        responses = {
            { label = "And with you. [Leave]", next = -1 },
        },
    },

    [62] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7No. I suppose it wasn't.'",
            "A pause. '^7Good luck, wherever you're headed. Try not to",
            "make enemies you can't handle.'",
        },
        responses = {
            { label = "[Nod and leave]", next = -1 },
        },
    },

    [63] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Her face goes cold.",
            "'^7Then you're already lost.'",
            "She turns back to her work.",
            "'^7Don't come back to Dantooine.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 70: Quest already complete
    -- ============================================
    [70] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7You're still here? The Wanderer is fueled and waiting.'",
        },
        responses = {
            {
                label = "What happened to the Jedi?",
                next = 80,
                condition = function(g) return not RPG.Quest.HasFlag(g, "terena_purge_discussed") end,
            },
            { label = "Just making sure everything's in order. [Leave]", next = -1 },
            {
                label = "The Holocron is dealt with.",
                next = 75,
                condition = function(g)
                    return RPG.Quest.IsComplete(g, "ghosts_enclave")
                        and (RPG.Quest.HasFlag(g, "ghosts_destroy")
                        or RPG.Quest.HasFlag(g, "ghosts_balance")
                        or RPG.Quest.HasFlag(g, "ghosts_embrace"))
                end,
            },
        },
    },

    [75] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Her posture tightens. '^7Tell me plainly.'",
        },
        responses = {
            {
                label = "I sealed it. Saevus is buried.",
                next = 76,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_destroy") end,
                alignment = 3,
            },
            {
                label = "I can hear him, but he does not command me.",
                next = 77,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_balance") end,
                alignment = 2,
            },
            {
                label = "I chose to learn from him.",
                next = 78,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_embrace") end,
                alignment = -4,
            },
            { label = "[Leave]", next = -1, setFlag = "terena_ghosts_discussed" },
        },
    },

    [76] = {
        speaker = "Administrator Terena Adare",
        text = {
            "She exhales, relief and fear mixing in equal measure.",
            "'^7Then maybe the Force still gives second chances.'",
            "'^7Whatever waits beyond Dantooine, remember this moment when",
            "someone tells you power is the same thing as wisdom.'",
        },
        responses = {
            { label = "I will. [Leave]", next = -1, alignment = 2, setFlag = "terena_ghosts_discussed" },
        },
    },

    [77] = {
        speaker = "Administrator Terena Adare",
        text = {
            "'^7A balanced knife still cuts.'",
            "She folds her arms. '^7But at least you know you're holding one.'",
            "'^7Keep that honesty. The Jedi lost theirs long before Malak.",
            "The Republic loses it every time the Senate holds a vote.'",
        },
        responses = {
            { label = "That's the plan. [Leave]", next = -1, alignment = 1, setFlag = "terena_ghosts_discussed" },
        },
    },

    [78] = {
        speaker = "Administrator Terena Adare",
        text = {
            "No anger now. Just grief.",
            "'^7Then the person who leaves on that ship is not the one I sent",
            "to the crash site.'",
            "'^7Go. And pray your new teacher never asks for the one thing",
            "you still refuse to surrender.'",
        },
        responses = {
            { label = "[Leave]", next = -1, alignment = -1, setFlag = "terena_ghosts_discussed" },
        },
    },

    -- ============================================
    -- NODE 80: Jedi Purge  - Adare's survivor account
    -- ============================================
    [80] = {
        speaker = "Administrator Terena Adare",
        text = {
            "Her voice drops. Old pain.",
            "'^7Two years ago, something hunted the remaining",
            "Jedi across the galaxy. Entire enclaves went",
            "dark overnight.'",
            "'^7A creature that consumed Force energy  - they",
            "called it a wound in the Force. When it ended,",
            "there were almost no Jedi left.'",
            "'^7A Jedi came through here two years ago. Helped us",
            "fight off Azkul's mercenaries. Stirred up the Enclave",
            "ruins, met with the surviving Masters. Then she left --",
            "said she had to find someone in the Unknown Regions.'",
            "'^7She hasn't come back either.'",
            "'^7I kept my head down. I survived.'",
            "'^7I'm not proud of that.'",
        },
        effects = { setFlag = "terena_purge_discussed" },
        responses = {
            {
                label = "Surviving isn't something to be ashamed of.",
                next = -1,
                alignment = 2,
            },
            {
                label = "The Jedi are gone. Someone has to fill the void.",
                next = -1,
                alignment = -2,
            },
        },
    },
}
