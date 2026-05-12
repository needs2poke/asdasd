-- Dialogue Tree: Mira Tovan (Traumatized Witness)
-- Act 2, Room 29 (Dark Alley)
-- Murder witness, Q16 integration, paranoia driver
-- ~25 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Threatened her: she's gone
            { condition = function(g)
                return RPG.Quest.HasFlag(g, "mira_threatened")
            end, node = 45 },
            -- Q16 complete
            { condition = function(g)
                return RPG.Quest.IsComplete(g, "the_mimic")
            end, node = 40 },
            -- Q16 active (any stage past speak_venn)
            { condition = function(g)
                return RPG.Quest.IsActive(g, "the_mimic")
                    and RPG.Quest.GetStage(g, "the_mimic") ~= "speak_venn"
            end, node = 20 },
            -- Already persuaded
            { condition = function(g)
                return RPG.Quest.HasFlag(g, "mira_persuaded")
            end, node = 30 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: THE ACCUSATION
    -- ============================================
    [1] = {
        speaker = "Mira Tovan",
        text = {
            "A young woman with hollow eyes stumbles backward when",
            "she sees you. Her hands are shaking.",
            "'^1I SAW you!^7' she screams. '^1Purple eyes! Standing",
            "over the body! You were THERE!'",
            "'^7Don't come any closer! I'll call the guards!'",
            "She's terrified. Whatever she saw in this alley",
            "has broken something inside her.",
        },
        effects = {
            paranoia = 10,
        },
        responses = {
            {
                label = "[CHA 14] I'm not who you think I am. Please, calm down.",
                next = 10,
                check = { stat = "CHA", dc = 14 },
                failNext = 15,
            },
            {
                label = "You're confused. I've never been here before.",
                next = 15,
            },
            {
                label = "Threaten her into silence. (Dark)",
                next = 18,
                alignment = -8,
            },
            {
                label = "[WIS 16] She's telling the truth -- but so am I.",
                next = 13,
                check = { stat = "WIS", dc = 16 },
                failNext = 15,
                isDoubt = true,
                truthLabel = "She saw the truth. And it wasn't you.",
            },
        },
    },

    -- ============================================
    -- NODE 10: CHA PERSUADE SUCCESS
    -- ============================================
    [10] = {
        speaker = "Mira Tovan",
        text = {
            "She hesitates. Your voice reaches something past the",
            "panic. She takes a shuddering breath.",
            "'^7I... I'm sorry. You look... you look exactly like...'",
            "She swallows hard.",
            "'^7Two nights ago. This alley. I saw someone in robes",
            "standing over a body. Purple eyes, just like --'",
            "She looks at your eyes. '^7Just like that. But...'",
            "'^7There were two sets of footprints. Identical. The same",
            "boots, the same stride. Like... like two of you.'",
        },
        effects = {
            setFlag = "mira_persuaded",
            action = function(player, game)
                RPG.Quest.SetFlag(game, "mimic_witness_spoken")
            end,
        },
        responses = {
            {
                label = "Two sets of footprints? Identical?",
                next = 12,
            },
            {
                label = "Did you see which direction it went?",
                next = 14,
            },
        },
    },

    -- ============================================
    -- NODE 12: THE CLUE - dual footprints, Mimic concept
    -- ============================================
    [12] = {
        speaker = "Mira Tovan",
        text = {
            "'^7Yes. Exactly the same. I thought I was seeing double",
            "from the shock. But then one of them turned and looked",
            "at me.'",
            "'^7Its eyes were purple. Like a Sith artifact. And its",
            "face -- YOUR face -- was... wrong. Like a mask worn",
            "by something that doesn't understand expressions.'",
            "'^7It smiled at me. And then it was gone. Just... gone.",
            "Stepped into the shadow and vanished.'",
            "'^7The other figure -- the body on the ground -- was",
            "already dead. Throat torn out.'",
        },
        effects = {
            action = function(player, game)
                if not RPG.Quest.IsActive(game, "the_mimic") then
                    RPG.Quest.Start(player, "the_mimic")
                    RPG.Quest.SetStage(player, "the_mimic", "speak_venn")
                end
            end,
        },
        responses = {
            {
                label = "Something is copying me. I need to find out what.",
                next = 14,
            },
            {
                label = "Where did it go?",
                next = 14,
            },
        },
    },

    -- ============================================
    -- NODE 13: WIS TRUTH - Holocron creating copies
    -- ============================================
    [13] = {
        speaker = "Mira Tovan",
        text = {
            "Through the Force, you sense the truth in her words.",
            "She saw exactly what she describes. And you sense",
            "something else: a fading trace of Holocron resonance",
            "in this alley. Whatever was here, it was connected to",
            "the artifact you carry.",
            "'^7You... you believe me?'",
            "'^7Nobody else does. The guards said I was hysterical.",
            "But I KNOW what I saw. It was YOU. But not you.'",
            "'^7Something is creating copies. Twisted copies. And",
            "the traces lead down -- toward the Lower Levels.'",
        },
        effects = {
            setFlag = "mira_persuaded",
            paranoia = 5,
            action = function(player, game)
                RPG.Quest.SetFlag(game, "mimic_witness_spoken")
                if not RPG.Quest.IsActive(game, "the_mimic") then
                    RPG.Quest.Start(player, "the_mimic")
                    RPG.Quest.SetStage(player, "the_mimic", "speak_venn")
                end
            end,
        },
        responses = {
            {
                label = "The Lower Levels. I'll investigate.",
                next = 14,
            },
        },
    },

    -- ============================================
    -- NODE 14: Direction - foreshadows Lower Levels + Stalker
    -- ============================================
    [14] = {
        speaker = "Mira Tovan",
        text = {
            "'^7It went south. Toward the Lower Levels. Sublevel 3.'",
            "'^7But there's something else down there. The refugees",
            "talk about it -- something that hunts in the tunnels.",
            "Not the... the copy. Something bigger. Older.'",
            "'^7They say it was a Jedi once. Before the purple",
            "eyes took it.'",
            "She wraps her arms around herself.",
            "'^7Be careful down there. Please.'",
        },
        responses = {
            {
                label = "I will. Thank you, Mira. [Leave]",
                next = -1,
            },
            {
                label = "A former Jedi? Tell me more.",
                next = 19,
            },
        },
    },

    -- ============================================
    -- NODE 15: Confusion / CHA fail
    -- ============================================
    [15] = {
        speaker = "Mira Tovan",
        text = {
            "'^7Confused? I know what I saw! You were standing right",
            "THERE --' she points at the blood stain on the ground --",
            "'with blood on your hands!'",
            "'^7Or... or someone who looked like you. Exactly like you.'",
            "She falters. Doubt creeps in.",
            "'^7There... there were two sets of footprints. I remember",
            "now. Identical. Like twins.'",
        },
        effects = {
            setFlag = "mimic_witness_spoken",
        },
        responses = {
            {
                label = "Two of me? That's impossible... unless...",
                next = 12,
            },
            {
                label = "You're not making sense. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 18: THREATEN - dark side
    -- ============================================
    [18] = {
        speaker = "Mira Tovan",
        text = {
            "You step toward her. Something in your eyes makes her",
            "go pale.",
            "'^7No -- please -- I won't tell anyone -- I swear --'",
            "She turns and runs. You hear her footsteps receding",
            "down the alley.",
            "For a moment, in the shadows where she stood, you see",
            "a figure. Your robes. Your face. Purple eyes. It tilts",
            "its head and smiles.",
            "Then it's gone.",
        },
        effects = {
            setFlag = "mira_threatened",
            paranoia = 10,
            action = function(player, game)
                RPG.Quest.SetFlag(game, "mimic_glimpse")
            end,
        },
        responses = {
            {
                label = "What was that? [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 19: Stalker foreshadowing
    -- ============================================
    [19] = {
        speaker = "Mira Tovan",
        text = {
            "'^7I don't know much. The refugees call it the Shadow.",
            "It's been in the Lower Levels for weeks. Maybe longer.'",
            "'^7The guards sent a patrol down there. Two came back.",
            "They won't talk about what they saw.'",
            "'^7Whatever it is, it's not like the copy. The copy is",
            "sneaky. Quiet. The Shadow... the Shadow hunts.'",
        },
        responses = {
            {
                label = "I'll be ready. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: Q16 active revisit
    -- ============================================
    [20] = {
        speaker = "Mira Tovan",
        text = function(g)
            local stage = RPG.Quest.GetStage(g, "the_mimic")
            if stage == "hunt_mimic" or stage == "confront_truth" then
                return {
                    "'^7You're going after it? The thing that looks like you?'",
                    "'^7Good. It needs to be stopped. The murders haven't",
                    "stopped since I saw it.'",
                    "'^7Be careful. It's faster than it looks.'",
                }
            else
                return {
                    "'^7Have you found anything? About the... the copy?'",
                    "'^7I still see it when I close my eyes. Standing there.",
                    "Smiling with your face.'",
                }
            end
        end,
        responses = {
            {
                label = "I'm working on it. Stay safe. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Persuaded revisit (no active Q16)
    -- ============================================
    [30] = {
        speaker = "Mira Tovan",
        text = {
            "'^7You again. Have you found the... the thing?'",
            "'^7I can't sleep. Every shadow looks like it.'",
            "'^7Doctor Venn at the Medical Clinic might know more.",
            "She's been treating the attack victims.'",
        },
        responses = {
            {
                label = "I'll talk to Doctor Venn. Stay safe. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 40: Q16 complete
    -- ============================================
    [40] = {
        speaker = "Mira Tovan",
        text = {
            "For the first time, she's not shaking.",
            "'^7The nightmares stopped. Two nights ago. I woke up",
            "and the alley was just... an alley again.'",
            "'^7You did something, didn't you? You stopped it.'",
            "She almost smiles.",
            "'^7Thank you. I don't know what you did, but thank you.'",
        },
        responses = {
            {
                label = "Stay safe, Mira. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 45: Threatened - she's gone
    -- ============================================
    [45] = {
        speaker = "",
        text = {
            "The corner where Mira Tovan stood is empty.",
            "She's gone. Fled the city, perhaps.",
            "In the shadows, you think you see a figure watching.",
            "Your robes. Your face. Purple eyes.",
            "It raises one hand in a mocking wave.",
            "Then it's gone.",
        },
        effects = {
            paranoia = 3,
        },
        responses = {
            {
                label = "[She's gone. Leave]",
                next = -1,
            },
        },
    },
}
