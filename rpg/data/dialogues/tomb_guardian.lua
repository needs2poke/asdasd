-- Dialogue Tree: Tomb Guardian Inscription (NPC 21)
-- Lore and loop-escape hints, Room 41 (Ritual Antechamber)
-- ~15 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Forgotten memories quest: investigation in progress
            { condition = function(g) return RPG.Quest.IsActive(g, "forgotten_memories") end, node = 35 },
            -- Post loop-break: lore mode (starts forgotten_memories)
            { condition = function(g) return g.tombLoop and g.tombLoop.broken end, node = 30 },
            -- Loop 4+: explicit DCs
            { condition = function(g) return g.tombLoop and g.tombLoop.count >= 4 end, node = 20 },
            -- Loop 2-3: clearer hints
            { condition = function(g) return g.tombLoop and g.tombLoop.count >= 2 end, node = 10 },
            -- Loop 0-1 or no loop: cryptic poetry
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: First visit / Loop 0-1 (Cryptic Poetry)
    -- ============================================
    [1] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "Ancient Sith script glows faintly on the wall,",
            "carved by hands dead for millennia.",
            "",
            "'^1In the tomb of Freedon Nadd, the worthy pass.",
            "The unworthy walk forever.",
            "The door sees what the eye cannot.",
            "The door breaks what the hand cannot.^7'",
        },
        responses = {
            {
                label = "Study the inscription more closely.",
                next = 2,
            },
            {
                label = "What does 'the door sees' mean?",
                next = 3,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Closer study (cryptic)
    -- ============================================
    [2] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "Below the main text, smaller script reads:",
            "",
            "'^1Two paths through the final door.",
            "Sight pierces illusion.",
            "Force shatters stone.",
            "Choose the path your nature demands.^7'",
        },
        responses = {
            {
                label = "Sight... and Force. I'll remember.",
                next = -1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 3: "What does the door sees mean?"
    -- ============================================
    [3] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "The script seems to shift as you read,",
            "as though responding to your question.",
            "",
            "'^1The door is illusion. The loop is illusion.",
            "See through the lie, and the lie dissolves.",
            "Break through the lie, and the lie shatters.^7'",
        },
        responses = {
            {
                label = "Two methods of escape. Understood.",
                next = -1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: Loop 2-3 (Clearer Hints)
    -- ============================================
    [10] = {
        speaker = "Tomb Guardian Inscription",
        text = function(g)
            local count = g.tombLoop and g.tombLoop.count or 0
            return {
                "The inscription has changed. Or you're reading it",
                "differently now. Loop " .. count .. ".",
                "",
                "'^1The door yields only to sight or to force.",
                "WISDOM sees the cracks in the illusion.",
                "STRENGTH breaks the door from its hinges.",
                "All other approaches feed the loop.^7'",
            }
        end,
        responses = {
            {
                label = "Sight... Wisdom. Force... Strength.",
                next = 11,
            },
            {
                label = "How much Wisdom? How much Strength?",
                next = 12,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 11: Confirmed understanding
    -- ============================================
    [11] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "The script pulses once, as if acknowledging",
            "your comprehension.",
            "",
            "'^1The wise need not bleed.",
            "The strong need not think.",
            "Both paths reach the sanctum.^7'",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 12: Asking for specific DCs (loop 2-3, partial)
    -- ============================================
    [12] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "The script wavers, reluctant to be direct.",
            "",
            "'^1The trial demands more than most possess.",
            "A keen mind — keener than fourteen in ten —",
            "or arms that could move a mountain.",
            "The tomb does not suffer the merely adequate.^7'",
        },
        responses = {
            {
                label = "Fourteen... that's the threshold for Wisdom.",
                next = -1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: Loop 4+ (Explicit DCs)
    -- ============================================
    [20] = {
        speaker = "Tomb Guardian Inscription",
        text = function(g)
            local count = g.tombLoop and g.tombLoop.count or 0
            local stats = g.player.stats or {}
            local wis = stats.WIS or 0
            local str = stats.STR or 0
            return {
                "The inscription blazes bright — all subtlety gone.",
                "Loop " .. count .. ". The tomb is losing patience.",
                "",
                "'^1WISDOM 14 sees through the illusion.",
                "STRENGTH 16 shatters the door.",
                "THERE IS NO OTHER WAY.^7'",
                "",
                "^3[Your WIS: " .. wis .. " | Your STR: " .. str .. "]",
            }
        end,
        responses = {
            {
                label = "I need to raise my stats somehow.",
                next = 21,
            },
            {
                label = "I understand. Time to try again.",
                next = -1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 21: Stat advice
    -- ============================================
    [21] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "'^1Equipment grants power beyond the body.",
            "Items found in earlier rooms may tip",
            "the balance. Search your inventory.",
            "The tomb provides — if you are attentive.^7'",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Post-Loop (Broken free — lore mode)
    -- ============================================
    [30] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "The inscription has settled into steady, calm light.",
            "The frantic urgency is gone.",
            "",
            "'^1The trial is complete. You have proven your worth",
            "to the tomb of Freedon Nadd. What lies beyond",
            "the sanctum door was placed there by Sith",
            "who believed that power demands truth.^7'",
        },
        effects = {
            startQuest = "forgotten_memories",
        },
        responses = {
            {
                label = "Tell me about Freedon Nadd.",
                next = 31,
            },
            {
                label = "What was the purpose of this tomb?",
                next = 32,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 31: Freedon Nadd lore
    -- ============================================
    [31] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "'^1Freedon Nadd was a Jedi who fell.",
            "He conquered Onderon. He ruled Dxun.",
            "In death, his tomb became a nexus",
            "of dark side power that corrupted",
            "everything it touched for centuries.^7'",
            "",
            "'^1The Holocron you carry was forged here.",
            "The prisoner inside was his student.^7'",
        },
        responses = {
            {
                label = "His student... Saevus.",
                next = 33,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 32: Tomb purpose
    -- ============================================
    [32] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "'^1This tomb was a crucible. A forge.",
            "The Sith believed weakness should be",
            "burned away. The loop, the fragments,",
            "the shadow — all designed to strip",
            "the unworthy down to nothing.^7'",
            "",
            "'^1What remains after the stripping",
            "is either strong enough to continue",
            "or nothing at all.^7'",
        },
        responses = {
            {
                label = "And I remain.",
                next = -1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 33: Saevus connection
    -- ============================================
    [33] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "The script flickers — uncertain, or afraid.",
            "",
            "'^1The one called Saevus learned the ritual",
            "of consumption here. The ritual that",
            "devoured Nathema. The ritual that killed",
            "an entire world's connection to the Force.^7'",
            "",
            "'^1The prison was built to stop it",
            "from happening again.^7'",
        },
        responses = {
            {
                label = "Then the Holocron must stay sealed.",
                next = -1,
                effects = { alignment = 5 },
            },
            {
                label = "That kind of power could be useful.",
                next = -1,
                effects = { alignment = -5 },
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 35: Forgotten Memories — Investigation
    -- ============================================
    [35] = {
        speaker = "Tomb Guardian Inscription",
        text = function(g)
            local stage = RPG.Quest.GetStage(g, "forgotten_memories")
            if stage == "investigate" then
                return {
                    "The inscription pulses with recognition.",
                    "",
                    "'^1The loop strips away pretense.",
                    "What surfaces in the stripping — memories,",
                    "fears, regrets — those are the truth of you.",
                    "The question is what you do with them.^7'",
                }
            else
                return {
                    "The inscription glows with steady warmth.",
                    "",
                    "'^1You carry fragments of memory that the",
                    "tomb shook loose. They are uncomfortable.",
                    "They are yours. What will you do with them?^7'",
                }
            end
        end,
        effects = {
            setStage = { quest = "forgotten_memories", stage = "investigate" },
        },
        responses = {
            {
                label = "I'll face them. These memories are part of me.",
                next = 36,
                effects = { alignment = 5 },
            },
            {
                label = "Some things are better left buried.",
                next = 37,
                effects = { alignment = -3 },
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 36: Recover memories (Light path)
    -- ============================================
    [36] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "The inscription flares bright — almost warm.",
            "",
            "'^1Courage. The Sith who built this tomb",
            "would not have understood that word.",
            "But the Force does. Memory accepted",
            "is memory defanged. It can no longer",
            "be used against you.^7'",
        },
        effects = {
            setStage = { quest = "forgotten_memories", stage = "recovered" },
        },
        responses = {
            {
                label = "The memories are mine now. All of them.",
                next = -1,
                effects = {
                    setStage = { quest = "forgotten_memories", stage = "complete" },
                },
            },
        },
    },

    -- ============================================
    -- NODE 37: Embrace forgetting (Dark path)
    -- ============================================
    [37] = {
        speaker = "Tomb Guardian Inscription",
        text = {
            "The inscription dims. Not in disapproval —",
            "in understanding.",
            "",
            "'^1The Sith knew this path too. To forget",
            "is to shed weight. To cut away the chains",
            "of the past. There is power in forgetting,",
            "if you can pay the price.^7'",
        },
        effects = {
            setStage = { quest = "forgotten_memories", stage = "embraced_forgetting" },
        },
        responses = {
            {
                label = "I choose to move forward unburdened.",
                next = -1,
                effects = {
                    setStage = { quest = "forgotten_memories", stage = "complete" },
                },
            },
        },
    },
}
