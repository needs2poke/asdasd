-- Dialogue Tree: Darth Saevus (Holocron Echo)
-- Quest Q4: Ghosts of the Enclave (ghosts_enclave)

return {
    [0] = {
        routes = {
            { condition = function(g) return RPG.Quest.IsComplete(g, "ghosts_enclave") and RPG.Quest.HasFlag(g, "ghosts_embrace") end, node = 95 },
            { condition = function(g) return RPG.Quest.IsComplete(g, "ghosts_enclave") and RPG.Quest.HasFlag(g, "ghosts_destroy") end, node = 96 },
            { condition = function(g) return RPG.Quest.IsComplete(g, "ghosts_enclave") and RPG.Quest.HasFlag(g, "ghosts_balance") end, node = 97 },
            { condition = function(g) return RPG.Quest.GetStage(g, "ghosts_enclave") == "confrontation" end, node = 70 },
            { condition = function(g) return RPG.Quest.GetStage(g, "ghosts_enclave") == "three_lessons" end, node = 60 },
            { condition = function(g)
                return RPG.Quest.GetStage(g, "ghosts_enclave") == "whispers"
                    and not RPG.Quest.GetVar(g, "ghosts_enclave", "lesson_1_done")
                end, node = 10 },
            { condition = function(g)
                return RPG.Quest.GetStage(g, "ghosts_enclave") == "whispers"
                    and RPG.Quest.GetVar(g, "ghosts_enclave", "lesson_1_done")
                    and not RPG.Quest.GetVar(g, "ghosts_enclave", "lesson_2_done")
                end, node = 20 },
            { condition = function(g)
                return RPG.Quest.GetStage(g, "ghosts_enclave") == "whispers"
                    and RPG.Quest.GetVar(g, "ghosts_enclave", "lesson_1_done")
                    and RPG.Quest.GetVar(g, "ghosts_enclave", "lesson_2_done")
                    and not RPG.Quest.GetVar(g, "ghosts_enclave", "lesson_3_done")
                end, node = 30 },
            { condition = function(g) return RPG.Quest.IsActive(g, "ghosts_enclave") end, node = 10 },
        },
        fallback = 1,
    },

    [1] = {
        speaker = "Darth Saevus",
        text = {
            "The Holocron unfolds in cold violet light.",
            "'^7You finally stopped pretending this is an accident.'",
            "'^7I am Darth Saevus. Not flesh. Not ghost. Memory with intent.'",
            "'^7The old Order called me a monster. The old Order is dust.'",
        },
        responses = {
            {
                label = "What are you offering?",
                next = 2,
            },
            {
                label = "Get out of my head.",
                next = 3,
                alignment = 2,
            },
            {
                label = "Start talking.",
                next = 4,
                effects = { startQuest = "ghosts_enclave" },
            },
        },
    },

    [2] = {
        speaker = "Darth Saevus",
        text = {
            "'^7Clarity. The kind Revan bought with blood and the Council called heresy.'",
            "'^7Three lessons. Not sermons. Decisions.'",
            "'^7You survive this era by understanding what people hide from themselves.'",
        },
        responses = {
            {
                label = "Fine. Show me.",
                next = 4,
                effects = { startQuest = "ghosts_enclave" },
            },
            {
                label = "No deals with Sith relics. [Leave]",
                next = -1,
                alignment = 2,
            },
        },
    },

    [3] = {
        speaker = "Darth Saevus",
        text = {
            "A dry laugh, intimate as breath.",
            "'^7Then throw me away.'",
            "'^7You already tried. In your mind. Three times.'",
            "'^7You came back anyway.'",
        },
        responses = {
            {
                label = "I hate that you are right.",
                next = 4,
                effects = { startQuest = "ghosts_enclave" },
            },
            {
                label = "Not today. [Leave]",
                next = -1,
            },
        },
    },

    [4] = {
        speaker = "Darth Saevus",
        text = {
            "'^7Good. We begin with fear, then mercy, then hunger.'",
            "'^7Three doors. Walk through one at a time.'",
        },
        responses = {
            {
                label = "Open the first door.",
                next = 10,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    [10] = {
        speaker = "Darth Saevus",
        text = {
            "'^7Lesson One waits. Fear under thought.'",
            "'^7The Jedi taught denial. I teach recognition.'",
            "'^7There was a Sith who tried to kill the Force itself.",
            "She believed it was the true enemy -- that it manipulated",
            "all who touched it. She failed. Not because she was wrong,",
            "but because she lacked the conviction to finish what she started.'",
            "'^7Look directly at what you are afraid to become.'",
        },
        responses = {
            {
                label = "Begin Lesson One.",
                next = -1,
                effects = { startState = { state = "force_vision", data = { lesson = 1 } } },
            },
            {
                label = "Not yet. [Leave]",
                next = -1,
            },
        },
    },

    [20] = {
        speaker = "Darth Saevus",
        text = {
            "'^7You survived the first mirror. Most do not.'",
            "'^7Now mercy and the blade. This one broke better people than you.'",
            "'^7The Republic calls indecision virtue. Corpses disagree.'",
        },
        responses = {
            {
                label = "Begin Lesson Two.",
                next = -1,
                effects = { startState = { state = "force_vision", data = { lesson = 2 } } },
            },
            {
                label = "[WIS 15] I choose who I become, not you.",
                next = -1,
                check = { stat = "WIS", dc = 15 },
                failNext = 21,
                effects = { startState = { state = "force_vision", data = { lesson = 2 } } },
            },
            {
                label = "Not yet. [Leave]",
                next = -1,
            },
        },
    },

    [21] = {
        speaker = "Darth Saevus",
        text = {
            "'^7You keep saying that as if repetition makes it true.'",
            "'^7Go. Learn. Then lie to me again.'",
        },
        responses = {
            {
                label = "Start the lesson.",
                next = -1,
                effects = { startState = { state = "force_vision", data = { lesson = 2 } } },
            },
        },
    },

    [30] = {
        speaker = "Darth Saevus",
        text = {
            "'^7One lesson remains. Hunger.'",
            "'^7Exar Kun called it dominion. Nihilus called it need.'",
            "'^7Call it what you like. The galaxy kneels to those who understand it.'",
        },
        responses = {
            {
                label = "Begin Lesson Three.",
                next = -1,
                effects = { startState = { state = "force_vision", data = { lesson = 3 } } },
            },
            {
                label = "I will not become a slave to this thing.",
                next = -1,
                alignment = 3,
            },
        },
    },

    [60] = {
        speaker = "Darth Saevus",
        text = {
            "The room around you stutters, then steadies.",
            "'^7Three lessons. Three truths you can no longer unlearn.'",
            "'^7Now choose your posture before power: rejection, surrender, or discipline.'",
            "'^7Do not say \"balance\" like a child reciting Jedi nursery doctrine.'",
        },
        effects = { setStage = { quest = "ghosts_enclave", stage = "confrontation" } },
        responses = {
            {
                label = "I reject you. I will seal this Holocron.",
                next = 71,
                alignment = 6,
            },
            {
                label = "I embrace your path. Teach me everything.",
                next = 72,
                alignment = -8,
            },
            {
                label = "[WIS 16] I will use what I learned without becoming your vessel.",
                next = 73,
                check = { stat = "WIS", dc = 16 },
                failNext = 74,
            },
            {
                label = "I need more time. [Leave]",
                next = -1,
            },
        },
    },

    [70] = {
        speaker = "Darth Saevus",
        text = {
            "'^7You are still deciding. Good. Certainty is for fools and dead men.'",
            "'^7The next war will not care whether your conscience feels clean.'",
        },
        responses = {
            { label = "I have made my choice.", next = 60 },
            { label = "[Leave]", next = -1 },
        },
    },

    [71] = {
        speaker = "Darth Saevus",
        text = {
            "The Holocron's glow contracts to a single needle-point of light.",
            "'^7You can bind me. You cannot erase what you now understand.'",
            "'^7Even the Council learned that too late on Katarr and Malachor.'",
        },
        responses = {
            {
                label = "Then stay buried.",
                next = -1,
                effects = {
                    setFlag = "ghosts_destroy",
                    clearFlag = "ghosts_embrace",
                    completeQuest = "ghosts_enclave",
                },
            },
        },
    },

    [72] = {
        speaker = "Darth Saevus",
        text = {
            "The Holocron hum turns warm, almost approving.",
            "'^7At last. No masks. No Jedi theater.'",
            "'^7Keep your fear. Keep your doubt. They sharpen you.'",
            "'^7Now let us make use of this age.'",
        },
        responses = {
            {
                label = "We start now.",
                next = -1,
                effects = {
                    setFlag = "ghosts_embrace",
                    clearFlag = "ghosts_destroy",
                    completeQuest = "ghosts_enclave",
                },
            },
        },
    },

    [73] = {
        speaker = "Darth Saevus",
        text = {
            "Silence stretches, then a low laugh.",
            "'^7Discipline. Not denial. Better than I expected from Dantooine.'",
            "'^7Very well. Keep your leash. But hold it tight.'",
        },
        responses = {
            {
                label = "I choose my own path.",
                next = -1,
                effects = {
                    setFlag = "ghosts_balance",
                    completeQuest = "ghosts_enclave",
                },
            },
        },
    },

    [74] = {
        speaker = "Darth Saevus",
        text = {
            "'^7You reached for control and found performance.'",
            "'^7Try again when you are done pretending that hesitation is wisdom.'",
        },
        responses = {
            { label = "Then I choose now.", next = 60 },
        },
    },

    [95] = {
        speaker = "Darth Saevus",
        text = {
            "'^7You chose me. Good.'",
            "'^7Remember this when the Republic starts lying to your face about peace.'",
            "'^7The galaxy is not saved by kind intentions. It is shaped by will.'",
        },
        responses = {
            { label = "Keep speaking. I am listening. [Leave]", next = -1 },
        },
    },

    [96] = {
        speaker = "Darth Saevus",
        text = {
            "Only a faint echo answers now.",
            "'^7You sealed me, not the truth.'",
            "'^7When your mercy fails and someone dies for it, you will hear me again.'",
        },
        responses = {
            { label = "Not today. [Leave]", next = -1 },
        },
    },

    [97] = {
        speaker = "Darth Saevus",
        text = {
            "'^7The famous middle path.'",
            "'^7How careful. How ordinary.'",
            "'^7Still... ordinary people survive long enough to become dangerous.'",
        },
        responses = {
            { label = "I can live with ordinary. [Leave]", next = -1 },
            { label = "You are not getting in my head for free. [Leave]", next = -1 },
        },
    },
}
