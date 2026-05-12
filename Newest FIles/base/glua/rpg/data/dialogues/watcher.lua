-- Dialogue Tree: The Watcher (NPC 23)
-- Metacognitive horror NPC in the Fragment Arena (Room 46)
-- Visible only at paranoia >= 80
-- ~20 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Quest complete
            { condition = function(g) return RPG.Quest.IsComplete(g, "echoes_metacognition") end, node = 50 },
            -- Quest active: questioning stage
            { condition = function(g) return RPG.Quest.GetStage(g, "echoes_metacognition") == "questioning" end, node = 20 },
            -- Quest active: awareness stage
            { condition = function(g) return RPG.Quest.IsActive(g, "echoes_metacognition") end, node = 10 },
            -- Paranoia >= 80 safety check (redundant with visibility)
            { condition = function(g) return g.player.paranoia >= 80 end, node = 1 },
        },
        fallback = -1,  -- shouldn't happen (visibility gate)
    },

    -- ============================================
    -- NODE 1: First Meeting
    -- ============================================
    [1] = {
        speaker = "The Watcher",
        text = function(g)
            local lines = {
                "A figure stands at the arena's edge where nothing",
                "should stand. It doesn't move. It doesn't breathe.",
                "But it watches you with an awareness that feels",
                "older than the tomb.",
                "",
                "'You can see me now. Good. That means you're",
                "ready for the question.'",
            }
            if RPG.Quest.HasFlag(g, "saber_corrupted") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'Interesting. Your weapon carries a second voice."
                lines[#lines + 1] = "You accepted a gift you didn't understand."
                lines[#lines + 1] = "That is very... character-like of you.'"
            end
            return lines
        end,
        effects = {
            setStage = { quest = "echoes_metacognition", stage = "awareness" },
        },
        responses = {
            {
                label = "What question?",
                next = 2,
            },
            {
                label = "What are you?",
                next = 3,
            },
            {
                label = "I don't trust anything in this place.",
                next = 4,
            },
        },
    },

    -- ============================================
    -- NODE 2: "What question?"
    -- ============================================
    [2] = {
        speaker = "The Watcher",
        text = {
            "'Are you the one making choices?",
            "Or are the choices making you?'",
            "",
            "It gestures at the void around the arena.",
            "",
            "'Every room you entered. Every conversation.",
            "Every time you picked up an item or swung",
            "a lightsaber. Was that you? Or was it...",
            "something else, moving you through a story",
            "that was written before you arrived?'",
        },
        effects = {
            setStage = { quest = "echoes_metacognition", stage = "questioning" },
        },
        responses = {
            {
                label = "I make my own choices.",
                next = 11,
            },
            {
                label = "That's... a disturbing thought.",
                next = 12,
            },
            {
                label = "[WIS 16] You're describing determinism. Or a game.",
                next = 15,
                check = { stat = "WIS", dc = 16 },
                failNext = 13,
            },
        },
    },

    -- ============================================
    -- NODE 3: "What are you?"
    -- ============================================
    [3] = {
        speaker = "The Watcher",
        text = {
            "'I am what exists between the words.",
            "The pause between dialogue options.",
            "The moment you consider your response",
            "before selecting it.'",
            "",
            "'Some call me awareness. Some call me",
            "the fourth wall. I prefer: The Watcher.'",
        },
        responses = {
            {
                label = "What question did you want to ask?",
                next = 2,
            },
            {
                label = "This is nonsense. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 4: "I don't trust anything here"
    -- ============================================
    [4] = {
        speaker = "The Watcher",
        text = {
            "'Good. Distrust is the first step",
            "toward seeing clearly.'",
            "",
            "'But ask yourself: who taught you to distrust?",
            "Was it experience? Or was it a paranoia",
            "counter incrementing in a data structure",
            "labeled 'game.player'?'",
        },
        effects = {
            setStage = { quest = "echoes_metacognition", stage = "questioning" },
        },
        responses = {
            {
                label = "That's... uncomfortably specific.",
                next = 12,
            },
            {
                label = "You're trying to unsettle me. It won't work.",
                next = 11,
            },
        },
    },

    -- ============================================
    -- NODE 10: Return (awareness stage)
    -- ============================================
    [10] = {
        speaker = "The Watcher",
        text = {
            "The Watcher stands exactly where it was before.",
            "It may not have moved since the universe began.",
            "",
            "'You returned. The question still stands.",
            "Are you ready to hear it?'",
        },
        responses = {
            {
                label = "Ask your question.",
                next = 2,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 11: "I make my own choices"
    -- ============================================
    [11] = {
        speaker = "The Watcher",
        text = {
            "'Do you? Name the last choice you made",
            "that surprised you. The last action that",
            "wasn't presented as an option.'",
            "",
            "The Watcher's non-expression doesn't change.",
            "",
            "'Free will requires the possibility of doing",
            "something unexpected. When was the last time",
            "you did something that wasn't on a list?'",
        },
        responses = {
            {
                label = "You have a point. What does it mean?",
                next = 20,
            },
            {
                label = "This is just philosophy. I'm leaving.",
                next = 30,
            },
        },
    },

    -- ============================================
    -- NODE 12: "That's disturbing"
    -- ============================================
    [12] = {
        speaker = "The Watcher",
        text = {
            "'It should be. The most disturbing truths",
            "are the ones that feel obvious in retrospect.'",
            "",
            "'Consider: you have stats. Numbers that define",
            "your capabilities. You have a paranoia counter.",
            "You have alignment measured on a scale.",
            "Are those the properties of a person?",
            "Or the properties of a character?'",
        },
        responses = {
            {
                label = "What's the difference?",
                next = 20,
            },
            {
                label = "I'm real. These numbers just describe me.",
                next = 11,
            },
        },
    },

    -- ============================================
    -- NODE 13: WIS check failed
    -- ============================================
    [13] = {
        speaker = "The Watcher",
        text = {
            "The Watcher tilts its head, as though",
            "you said something almost right.",
            "",
            "'Close. But not quite. You're reaching",
            "for a concept your current... configuration",
            "can't quite grasp. That's not an insult.",
            "It's a limitation.'",
        },
        responses = {
            {
                label = "Explain it differently.",
                next = 20,
            },
            {
                label = "I've heard enough. [Leave]",
                next = 30,
            },
        },
    },

    -- ============================================
    -- NODE 15: WIS 16 passed — sees through it
    -- ============================================
    [15] = {
        speaker = "The Watcher",
        text = {
            "For the first time, the Watcher shows something",
            "like surprise.",
            "",
            "'You see it. Yes. A game. A story.",
            "A structure with rules and boundaries",
            "that you navigate but did not create.'",
            "",
            "'But here's what matters: knowing the cage",
            "exists doesn't open the door.",
            "What you do WITHIN the structure still defines",
            "who you are. Character is character,",
            "regardless of the medium.'",
        },
        responses = {
            {
                label = "Then my choices matter, even if they're constrained.",
                next = 40,
                effects = { alignment = 5 },
            },
            {
                label = "If nothing is real, nothing matters.",
                next = 35,
                effects = { alignment = -5 },
            },
        },
    },

    -- ============================================
    -- NODE 20: The core question (questioning stage)
    -- ============================================
    [20] = {
        speaker = "The Watcher",
        text = {
            "'The difference is this: a person exists",
            "independent of observation. A character exists",
            "only when someone is watching.'",
            "",
            "'I am The Watcher. I exist because you see me.",
            "The question is: do you exist because",
            "someone sees you?'",
            "",
            "'And if so — does that make you less real?'",
        },
        responses = {
            {
                label = "I exist regardless of who's watching. I accept that.",
                next = 40,
                effects = { alignment = 3 },
            },
            {
                label = "If I'm just a character, then nothing I do matters.",
                next = 35,
            },
            {
                label = "I don't know. And that's terrifying.",
                next = 36,
            },
        },
    },

    -- ============================================
    -- NODE 30: Dismissal (denial path)
    -- ============================================
    [30] = {
        speaker = "The Watcher",
        text = {
            "'You can leave. The question follows.'",
            "",
            "The Watcher doesn't move. It never moves.",
            "But as you turn away, you swear it smiles.",
        },
        effects = {
            paranoia = 5,
            setStage = { quest = "echoes_metacognition", stage = "denied" },
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 35: Nihilism path
    -- ============================================
    [35] = {
        speaker = "The Watcher",
        text = {
            "'Nihilism is the easy response.",
            "If nothing matters, you don't have to try.",
            "You don't have to care. You don't have to",
            "face the possibility that your choices,",
            "however constrained, still have weight.'",
            "",
            "'That's not freedom. That's cowardice.'",
        },
        effects = {
            paranoia = 5,
            setStage = { quest = "echoes_metacognition", stage = "denied" },
        },
        responses = {
            {
                label = "Maybe you're right.",
                next = 40,
            },
            {
                label = "I reject this entire conversation. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 36: Honest uncertainty
    -- ============================================
    [36] = {
        speaker = "The Watcher",
        text = {
            "'Good. Uncertainty is honest.",
            "It's the beginning of real thought.'",
            "",
            "'The Sith demand certainty.",
            "The Jedi demand faith.",
            "The truth lives in neither.",
            "It lives in the willingness",
            "to ask and not receive an answer.'",
        },
        responses = {
            {
                label = "Then I'll keep asking.",
                next = 40,
                effects = { alignment = 3 },
            },
            {
                label = "I'm done asking. [Leave]",
                next = 30,
            },
        },
    },

    -- ============================================
    -- NODE 40: Acceptance (peace ending)
    -- ============================================
    [40] = {
        speaker = "The Watcher",
        text = {
            "The Watcher nods. The first movement",
            "you've seen it make.",
            "",
            "'Then you are more than your parameters.",
            "More than your stats, your inventory,",
            "your paranoia counter.'",
            "",
            "'Go forward. What waits beyond the void",
            "is a choice that matters — not because",
            "it changes the world, but because it",
            "changes you.'",
            "",
            "The Watcher fades. Not dramatically.",
            "Just... quietly. Like a thought you",
            "decided not to think.",
        },
        effects = {
            paranoia = -10,
            setStage = { quest = "echoes_metacognition", stage = "accepted" },
            setFlag = "watcher_accepted",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 50: Post-quest (already complete)
    -- ============================================
    [50] = {
        speaker = "The Watcher",
        text = function(g)
            if g.flags["watcher_accepted"] then
                return {
                    "The arena is empty. But you feel a faint",
                    "presence — not watching, just... acknowledging.",
                    "",
                    "'^7You already found your answer.",
                    "There's nothing more I can teach you.^7'",
                }
            else
                return {
                    "The Watcher flickers at the edge of sight.",
                    "",
                    "'^7The question remains open.",
                    "It always will.^7'",
                }
            end
        end,
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },
}
