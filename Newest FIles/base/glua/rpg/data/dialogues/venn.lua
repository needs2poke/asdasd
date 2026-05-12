-- Dialogue Tree: Doctor Venn (Forensic Physician)
-- Act 2, Room 34 (Iziz Medical Clinic)
-- Q16 quest giver, forensic evidence, medical injector
-- ~25 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Q16 hunt_mimic stage
            { condition = function(g)
                return RPG.Quest.GetStage(g, "the_mimic") == "hunt_mimic"
            end, node = 25 },
            -- Q16 confront_truth stage
            { condition = function(g)
                return RPG.Quest.GetStage(g, "the_mimic") == "confront_truth"
            end, node = 20 },
            -- Q16 investigate stages
            { condition = function(g)
                local stage = RPG.Quest.GetStage(g, "the_mimic")
                return stage == "investigate_alley" or stage == "investigate_trace"
                    or stage == "investigate_footage"
            end, node = 10 },
            -- Q16 complete
            { condition = function(g)
                return RPG.Quest.IsComplete(g, "the_mimic")
            end, node = 40 },
            -- Already gave injector
            { condition = function(g)
                return RPG.Quest.HasFlag(g, "venn_injector_given")
            end, node = 35 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: First meeting
    -- ============================================
    [1] = {
        speaker = "Doctor Venn",
        text = {
            "A Zabrak woman in a stained medical coat looks up from",
            "a patient's chart. Dark circles under her eyes.",
            "'^7Another one. This is the fifth this week.'",
            "She gestures at a catatonic patient in the nearest bed.",
            "'^7He keeps drawing the same thing. Over and over.'",
            "She holds up a datapad. The drawing shows a robed figure",
            "with glowing purple eyes. It looks exactly like you.",
        },
        responses = {
            {
                label = "That's not me.",
                next = 2,
            },
            {
                label = "[WIS 14] Study the drawing closely.",
                next = 3,
                check = { stat = "WIS", dc = 14 },
                failNext = 2,
            },
            {
                label = "I'm looking for answers, not accusations.",
                next = 4,
            },
        },
    },

    -- ============================================
    -- NODE 2: Denial / WIS fail
    -- ============================================
    [2] = {
        speaker = "Doctor Venn",
        text = {
            "'^7I didn't say it was. But the resemblance is...',",
            "she chooses her words carefully, '^7concerning.'",
            "'^7My patient was attacked in the Dark Alley two nights",
            "ago. The attacker matched this description exactly.",
            "Robes, height, build -- and the eyes. Purple.'",
            "'^7Whatever attacked him, it wasn't natural.'",
        },
        responses = {
            {
                label = "What happened to the attacker?",
                next = 5,
            },
            {
                label = "Could it be some kind of projection?",
                next = 3,
            },
        },
    },

    -- ============================================
    -- NODE 3: WIS SUCCESS - Forensic insight
    -- ============================================
    [3] = {
        speaker = "Doctor Venn",
        text = {
            "You study the drawing. Through the Force, you sense",
            "something wrong with it -- not the art, but the subject.",
            "The figure has no Force presence. It's a shell. Empty.",
            "'^7You see it too, don't you? The drawing is accurate,",
            "but something is missing. The patient described the",
            "figure as looking human but feeling... hollow.'",
            "'^7I ran a residue analysis on the wounds. Standard",
            "laceration pattern, but the tissue around the cuts",
            "shows trace Holocron resonance.'",
            "'^7Whatever did this was created by a Sith artifact.'",
        },
        effects = {
            paranoia = 5,
            startQuest = "the_mimic",
            setStage = { quest = "the_mimic", stage = "speak_venn" },
        },
        responses = {
            {
                label = "Holocron resonance? Tell me more.",
                next = 5,
            },
            {
                label = "This is connected to me. I know it.",
                next = 5,
            },
        },
    },

    -- ============================================
    -- NODE 4: Truth-seeking
    -- ============================================
    [4] = {
        speaker = "Doctor Venn",
        text = {
            "'^7Then we want the same thing.'",
            "She sets down the chart and leans against the wall.",
            "'^7I've been a trauma doctor for fifteen years. I know",
            "what blaster wounds look like. Vibroblade wounds.",
            "Lightsaber burns.'",
            "'^7These wounds are different. The tissue is degraded",
            "at a molecular level -- as if the attacker's touch",
            "itself was corrosive.'",
            "'^7Something unnatural is hunting in this city.'",
        },
        effects = {
            startQuest = "the_mimic",
            setStage = { quest = "the_mimic", stage = "speak_venn" },
        },
        responses = {
            {
                label = "What kind of resonance did you find?",
                next = 5,
            },
            {
                label = "Where were the attacks?",
                next = 8,
            },
        },
    },

    -- ============================================
    -- NODE 5: Holocron resonance explanation
    -- ============================================
    [5] = {
        speaker = "Doctor Venn",
        text = {
            "'^7Holocron resonance. A specific energy signature left",
            "by Sith artifacts on organic tissue. I learned about",
            "it during the wars -- Republic medical corps.'",
            "'^7The frequency matches something specific.'",
            "She looks at you steadily.",
            "'^7It matches the artifact you're carrying.'",
            "'^7Whatever attacked my patient was created by YOUR",
            "Holocron. A projection. An echo. Something given form",
            "by the artifact's power.'",
        },
        responses = {
            {
                label = "Is there any way to stop it?",
                next = 6,
            },
            {
                label = "How does the Holocron create these things?",
                next = 7,
            },
        },
    },

    -- ============================================
    -- NODE 6: Medical injector offer
    -- ============================================
    [6] = {
        speaker = "Doctor Venn",
        text = {
            "'^7Stop it? I'm a doctor, not a Jedi.'",
            "'^7But I can help with the symptoms. The resonance",
            "feeds on Force sensitivity -- yours specifically.'",
            "She opens a cabinet and produces an injector.",
            "'^7Neural dampener. It suppresses Force-sensitive",
            "pathways for about six hours. It'll calm the paranoid",
            "episodes and make you harder for the projection to track.'",
            "'^7Side effects: emotional blunting, reduced Force",
            "perception. Real tradeoff.'",
            "'^7Take it. You look like you need it.'",
        },
        effects = {
            giveItem = 26,
            setFlag = "venn_injector_given",
        },
        responses = {
            {
                label = "Thank you. Where should I start looking?",
                next = 8,
            },
            {
                label = "I don't want to suppress the Force.",
                next = 8,
            },
        },
    },

    -- ============================================
    -- NODE 7: How does the Holocron create projections?
    -- ============================================
    [7] = {
        speaker = "Doctor Venn",
        text = {
            "'^7My theory? The Holocron uses your connection to the",
            "Force as raw material. It creates a copy -- a twisted",
            "echo of you, projected into reality.'",
            "'^7The closer you are, the stronger the projection.",
            "It feeds on proximity. On your emotional state.'",
            "'^7High paranoia, high stress -- that's fuel for it.",
            "The more afraid you are, the more real it becomes.'",
        },
        responses = {
            {
                label = "How do I find it?",
                next = 8,
            },
            {
                label = "Can the neural dampener help? [If not received]",
                next = 6,
                requireNotFlag = "venn_injector_given",
            },
            {
                label = "I understand. Where do I start?",
                next = 8,
            },
        },
    },

    -- ============================================
    -- NODE 8: Where to find the Mimic
    -- ============================================
    [8] = {
        speaker = "Doctor Venn",
        text = {
            "'^7The attacks all happened in dark, isolated places.",
            "The Dark Alley. The Lower Levels. Places where the",
            "light doesn't reach.'",
            "'^7The projection manifests in darkness. It feeds on",
            "proximity to you. So look where you've been.'",
            "'^7Start with the Dark Alley. That's where the most",
            "recent attack occurred.'",
        },
        effects = {
            setStage = { quest = "the_mimic", stage = "investigate_alley" },
        },
        responses = {
            {
                label = "I'll investigate. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: Q16 active, investigation stages
    -- ============================================
    [10] = {
        speaker = "Doctor Venn",
        text = function(g)
            local stage = RPG.Quest.GetStage(g, "the_mimic")
            if stage == "investigate_footage" then
                return {
                    "'^7You should talk to Captain Saren at the Security",
                    "Checkpoint. If there's footage of the attacks, he'll",
                    "have it.'",
                }
            elseif stage == "investigate_trace" then
                return {
                    "'^7You saw it? The projection? In the Lower Levels?'",
                    "She makes a note on her datapad.",
                    "'^7The fact that it showed itself means it's getting",
                    "stronger. Or more confident. Neither is good.'",
                    "'^7Talk to Captain Saren. He has security footage.'",
                }
            else
                return {
                    "'^7Any progress on the investigation?'",
                    "'^7The attacks haven't stopped. Another patient",
                    "came in this morning. Same wounds. Same description.'",
                }
            end
        end,
        responses = {
            {
                label = "I'm working on it. [Leave]",
                next = -1,
            },
            {
                label = "Can I have another dampener? [If used first]",
                next = 12,
                condition = function(g)
                    return RPG.Quest.HasFlag(g, "venn_injector_given")
                        and not RPG.Util.Contains(g.player.inventory, 26)
                end,
            },
        },
    },

    -- ============================================
    -- NODE 12: Additional dampener
    -- ============================================
    [12] = {
        speaker = "Doctor Venn",
        text = {
            "'^7Another one? The side effects get worse with repeated",
            "use. But... I can see you need it.'",
            "She hands over a second injector.",
        },
        effects = {
            giveItem = 26,
        },
        responses = {
            {
                label = "Thank you. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: confront_truth stage
    -- ============================================
    [20] = {
        speaker = "Doctor Venn",
        text = {
            "'^7You found it? The projection -- it's a Holocron",
            "construct?'",
            "'^7That confirms my worst theory. The artifact is",
            "generating autonomous entities. That shouldn't be",
            "possible for a standard Holocron.'",
            "'^7Whatever is imprisoned inside your artifact has",
            "power that goes far beyond anything in my medical",
            "textbooks.'",
        },
        responses = {
            {
                label = "How do I destroy it?",
                next = 21,
            },
        },
    },

    -- ============================================
    -- NODE 21: How to destroy the Mimic
    -- ============================================
    [21] = {
        speaker = "Doctor Venn",
        text = {
            "'^7A projection sustained by Force energy? You fight",
            "it the same way you fight anything -- but conventional",
            "weapons won't be enough.'",
            "'^7The Mimic is connected to the Holocron through you.",
            "Your Force sensitivity is its lifeline. Cut the cord",
            "and it has to manifest fully to survive.'",
            "'^7When it manifests, it becomes vulnerable. Kill it",
            "then, and the Holocron loses its projection.'",
            "'^7Find it in the Lower Levels. It'll be there.'",
        },
        effects = {
            setStage = { quest = "the_mimic", stage = "hunt_mimic" },
        },
        responses = {
            {
                label = "I'll end this. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 25: hunt_mimic stage
    -- ============================================
    [25] = {
        speaker = "Doctor Venn",
        text = {
            "'^7You're going after it? Be careful. The projection",
            "has YOUR fighting style. YOUR instincts. It's a mirror.'",
            "'^7The difference is restraint. It has none.'",
            "'^7The Lower Levels. Sublevel 3. That's where it",
            "manifests most strongly.'",
        },
        responses = {
            {
                label = "I know what I'm facing. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 35: Post-injector revisit (no active quest)
    -- ============================================
    [35] = {
        speaker = "Doctor Venn",
        text = {
            "'^7How's the dampener treating you? Any side effects",
            "beyond the expected?'",
            "'^7The attacks are still happening. Whatever is doing",
            "this, the dampener only buys you time.'",
        },
        responses = {
            {
                label = "Any new patients?",
                next = 36,
            },
            {
                label = "I'm fine. Thanks. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 36: New patient info
    -- ============================================
    [36] = {
        speaker = "Doctor Venn",
        text = {
            "'^7Two more this morning. Same wounds, same story.',",
            "'^7purple eyes, robes, inhuman speed.'",
            "'^7I've filed reports with Security but Captain Saren",
            "is more interested in interrogating suspects than",
            "protecting victims.'",
        },
        responses = {
            {
                label = "I'll talk to Saren. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 40: Q16 complete
    -- ============================================
    [40] = {
        speaker = "Doctor Venn",
        text = {
            "'^7The attacks have stopped. My patients are recovering.',",
            "'^7slowly, but recovering.'",
            "'^7Whatever you did, it worked. The projection is gone.'",
            "She pauses.",
            "'^7But the artifact that created it is still in your",
            "hands. Be careful. Things like this don't end cleanly.'",
        },
        responses = {
            {
                label = "I know. Thank you, Doctor. [Leave]",
                next = -1,
            },
        },
    },
}
