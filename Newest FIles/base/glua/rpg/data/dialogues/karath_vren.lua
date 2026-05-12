-- Dialogue Tree: Echo of Karath Vren (NPC 22)
-- Ghost of the Jedi Shadow from the Act 1 crash site
-- Room 44 (Memory Corridor), connects to shadows_trail outcome
-- ~20 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Already completed shadows_truth_act3
            { condition = function(g) return RPG.Quest.IsComplete(g, "shadows_truth_act3") end, node = 50 },
            -- Quest active: investigating
            { condition = function(g) return RPG.Quest.IsActive(g, "shadows_truth_act3") end, node = 20 },
            -- shadows_trail completed (knows the Shadow's story)
            { condition = function(g) return RPG.Quest.IsComplete(g, "shadows_trail") end, node = 5 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: First Meeting (no shadows_trail context)
    -- ============================================
    [1] = {
        speaker = "Echo of Karath Vren",
        text = {
            "A translucent figure in tattered Jedi robes",
            "stands among the frozen memories. You recognize",
            "the face — the dead Shadow from the crash site.",
            "The one who carried the Holocron.",
            "",
            "'You found it. I hoped someone would.'",
            "Her voice echoes from everywhere and nowhere.",
        },
        responses = {
            {
                label = "You're Karath Vren. The Jedi Shadow.",
                next = 2,
            },
            {
                label = "How are you here? You're dead.",
                next = 3,
            },
            {
                label = "What do you want?",
                next = 4,
            },
        },
    },

    -- ============================================
    -- NODE 2: Identity confirmed
    -- ============================================
    [2] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'Was. I was Karath Vren. Now I'm...",
            "an echo. A memory preserved in the Force.",
            "Or maybe preserved by the Holocron.",
            "I'm not sure there's a difference anymore.'",
            "",
            "'I came to Dantooine to deliver the Holocron",
            "to the surviving Jedi. I didn't make it.'",
        },
        responses = {
            {
                label = "What happened to you?",
                next = 6,
            },
            {
                label = "What do you know about the Holocron?",
                next = 7,
            },
        },
    },

    -- ============================================
    -- NODE 3: "How are you here?"
    -- ============================================
    [3] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'This place — the Void — doesn't follow",
            "the normal rules. Death is... flexible here.",
            "The memories on these walls aren't just images.",
            "They're echoes in the Force.'",
            "",
            "'I'm one of them. I have things to tell you",
            "before I fade.'",
        },
        effects = { paranoia = 5 },
        responses = {
            {
                label = "Tell me everything.",
                next = 6,
            },
            {
                label = "What do you know about the Holocron?",
                next = 7,
            },
        },
    },

    -- ============================================
    -- NODE 4: "What do you want?"
    -- ============================================
    [4] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'To warn you. To finish what I started.'",
            "",
            "'The Holocron isn't just a prison.",
            "It's a trap. The prisoner inside —",
            "Saevus — he WANTS to be found.",
            "He WANTED someone to carry him here.'",
        },
        responses = {
            {
                label = "A trap for whom?",
                next = 8,
            },
            {
                label = "I already know about Saevus.",
                next = 7,
            },
        },
    },

    -- ============================================
    -- NODE 5: Post-shadows_trail meeting
    -- ============================================
    [5] = {
        speaker = "Echo of Karath Vren",
        text = {
            "The ghost of Karath Vren regards you",
            "with recognition.",
            "",
            "'You decoded my datapad. You know",
            "the coordinates. You know about the",
            "Sith academy in the Unknown Regions.'",
            "",
            "'There's more. Things I couldn't fit",
            "on the datapad. Things I discovered",
            "just before I died.'",
        },
        effects = {
            startQuest = "shadows_truth_act3",
        },
        responses = {
            {
                label = "Tell me what you found.",
                next = 10,
            },
            {
                label = "[INT 13] Your datapad had encrypted sections. What was hidden?",
                next = 11,
                check = { stat = "INT", dc = 13 },
                failNext = 10,
            },
        },
    },

    -- ============================================
    -- NODE 6: "What happened to you?"
    -- ============================================
    [6] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'I found the Holocron in the Unknown Regions.",
            "In a Sith academy buried under ice.",
            "I was supposed to deliver it to the Council.'",
            "",
            "'But the Holocron... it changes you.",
            "The whispers started on the second day.",
            "By the time I reached Dantooine, I couldn't",
            "tell my own thoughts from its.'",
            "",
            "'The crash wasn't an accident.'",
        },
        responses = {
            {
                label = "The Holocron crashed your ship?",
                next = 8,
            },
            {
                label = "The whispers. I hear them too.",
                next = 9,
            },
        },
    },

    -- ============================================
    -- NODE 7: "What about the Holocron?"
    -- ============================================
    [7] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'The Holocron was forged in this tomb.",
            "In the sarcophagus you passed in the sanctum.",
            "Saevus was entombed alive — his consciousness",
            "trapped in the crystal.'",
            "",
            "'He's been waiting four thousand years",
            "for someone to carry him back here.",
            "Back to the source of his power.'",
        },
        effects = {
            startQuest = "shadows_truth_act3",
        },
        responses = {
            {
                label = "And I carried him right to it.",
                next = 9,
            },
            {
                label = "Can the prison be made stronger?",
                next = 12,
            },
        },
    },

    -- ============================================
    -- NODE 8: "The Holocron crashed your ship"
    -- ============================================
    [8] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'Not directly. It... influenced me.",
            "Made me doubt the navigation computer.",
            "Made me change course. I thought I was",
            "avoiding a threat. I was flying",
            "directly into Dantooine's gravity well.'",
            "",
            "'By the time I realized, it was too late.'",
        },
        responses = {
            {
                label = "The same thing could happen to me.",
                next = 9,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 9: Shared experience
    -- ============================================
    [9] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'It IS happening to you. Every moment",
            "of paranoia, every whisper, every time",
            "you questioned your own judgment —",
            "that's the Holocron.'",
            "",
            "'But you're still fighting. I stopped.",
            "That's the difference between us.'",
        },
        effects = {
            setFlag = "karath_vren_shared",
        },
        responses = {
            {
                label = "I won't stop fighting.",
                next = -1,
                effects = { alignment = 5 },
            },
            {
                label = "Maybe fighting is pointless.",
                next = -1,
                effects = { alignment = -5 },
            },
        },
    },

    -- ============================================
    -- NODE 10: shadows_trail follow-up (standard)
    -- ============================================
    [10] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'The academy in the Unknown Regions",
            "was where Vitiate's students trained.",
            "Saevus was among them. He learned",
            "the ritual of consumption there.'",
            "",
            "'But there was a faction that opposed",
            "Vitiate from within. Sith who believed",
            "the ritual was too dangerous even for them.",
            "They built the prison — the Holocron.'",
        },
        effects = {
            setStage = { quest = "shadows_truth_act3", stage = "lab_logs" },
        },
        responses = {
            {
                label = "Sith who opposed Vitiate?",
                next = 14,
            },
            {
                label = "Where does this leave me?",
                next = 15,
            },
        },
    },

    -- ============================================
    -- NODE 11: INT 13 success — encrypted sections
    -- ============================================
    [11] = {
        speaker = "Echo of Karath Vren",
        text = {
            "The ghost's eyes widen.",
            "",
            "'You decoded the encryption? Impressive.",
            "Yes. The hidden sections contained",
            "the names of the Sith faction that built",
            "the prison. And coordinates to a second",
            "academy — one even I never reached.'",
            "",
            "'The cipher fragments are connected",
            "to those names. Each artifact carries",
            "a piece of their code.'",
        },
        effects = {
            setStage = { quest = "shadows_truth_act3", stage = "compare_memories" },
        },
        responses = {
            {
                label = "This changes everything.",
                next = 15,
            },
            {
                label = "The cipher. Of course. It's their work.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 12: "Can the prison be strengthened?"
    -- ============================================
    [12] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'The cipher is the key. Nine digits",
            "that lock the prison permanently.",
            "The Sith who built it scattered the code",
            "across artifacts so no single person",
            "could control it.'",
            "",
            "'Find the fragments. Solve the cipher.",
            "That's the only way to seal Saevus",
            "for good.'",
        },
        responses = {
            {
                label = "I'll find them all.",
                next = -1,
                effects = { alignment = 5 },
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 14: Sith who opposed Vitiate
    -- ============================================
    [14] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'Hard to believe, isn't it? But even",
            "among the Sith, there were limits.",
            "The ritual of consumption threatened",
            "to destroy the Force itself.'",
            "",
            "'They couldn't stop Vitiate directly.",
            "But they could trap his students.",
            "The Holocron was their greatest work.",
            "And their last.'",
        },
        responses = {
            {
                label = "What happened to them?",
                next = 16,
            },
            {
                label = "I understand. I'll honor their work.",
                next = -1,
                effects = { alignment = 5 },
            },
        },
    },

    -- ============================================
    -- NODE 15: "Where does this leave me?"
    -- ============================================
    [15] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'Where I was. Carrying an impossible burden.",
            "The difference is: you made it further",
            "than I did. You're still standing.'",
            "",
            "The ghost flickers. Fading.",
            "",
            "'I don't have much time left. The void",
            "is pulling me apart. Remember what",
            "I've told you. The cipher is the key.'",
        },
        effects = {
            setFlag = "karath_vren_complete",
            setStage = { quest = "shadows_truth_act3", stage = "accepted" },
        },
        responses = {
            {
                label = "Rest now. I'll finish this.",
                next = -1,
                effects = { alignment = 5 },
            },
            {
                label = "Thank you, Shadow.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 16: "What happened to them?"
    -- ============================================
    [16] = {
        speaker = "Echo of Karath Vren",
        text = {
            "'Vitiate consumed them. Along with",
            "their entire world. Nathema.'",
            "",
            "'Eight thousand souls, drained",
            "in a single ritual. The planet'",
            "'is still dead. No Force. No life.",
            "Nothing. A wound in the galaxy.'",
            "",
            "'That's what the Holocron's prisoner",
            "learned from his master.",
            "That's what you're trying to stop.'",
        },
        effects = {
            setStage = { quest = "shadows_truth_act3", stage = "accepted" },
        },
        responses = {
            {
                label = "I'll stop it. I promise.",
                next = -1,
                effects = { alignment = 5 },
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: Return visit (quest active)
    -- ============================================
    [20] = {
        speaker = "Echo of Karath Vren",
        text = {
            "The ghost is fainter now. The void",
            "is eroding her presence.",
            "",
            "'You came back. I don't have much",
            "time. The memories are dissolving.'",
            "",
            "'Ask what you need to ask. Quickly.'",
        },
        responses = {
            {
                label = "Tell me about the cipher.",
                next = 12,
            },
            {
                label = "What about the Sith who built the prison?",
                next = 14,
            },
            {
                label = "I keep hearing a name. 'Vorr.' Who is that?",
                next = 25,
                condition = function(g)
                    return g.player.paranoia >= 85
                        and g.loreDiscovered and g.loreDiscovered[31]
                end,
            },
            {
                label = "Rest now. I have what I need.",
                next = 15,
            },
        },
    },

    -- ============================================
    -- NODE 25: Paranoia >= 85 + Item 31 examined — Nalen Vorr identity reveal
    -- ============================================
    [25] = {
        speaker = "Echo of Karath Vren",
        text = {
            "The ghost stares at you for a long",
            "moment. Recognition softens her edges.",
            "",
            "'Nalen Vorr. The Shadow before me.'",
            "",
            "'Nalen was my handler. My warning.",
            "My future. I never reached him in time.",
            "Now he hunts you -- because that is",
            "what is left of him.'",
            "",
            "'I am sorry. There is no peace at the end",
            "of this road. Only the next Shadow.'",
        },
        responses = {
            {
                label = "Then I'll finish what he couldn't.",
                next = 15,
                effects = { alignment = 5 },
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 50: Post-quest
    -- ============================================
    [50] = {
        speaker = "Echo of Karath Vren",
        text = {
            "The Memory Corridor holds only a faint",
            "shimmer where Karath Vren's ghost once stood.",
            "",
            "A whisper, barely audible:",
            "'^7Finish it.^7'",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },
}
