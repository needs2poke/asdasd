-- Dialogue Tree: Saevus Manifestation (NPC 24)
-- The Holocron's prisoner takes physical form in the Hidden Entrance (Room 48)
-- Routes on ghosts_enclave outcome, alignment, paranoia, cipher fragments
-- ~25 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Post-choice: already talked
            { condition = function(g) return g.flags["saevus_manifest_complete"] end, node = 60 },
            -- Dark bargain accepted
            { condition = function(g) return g.flags["saevus_dark_bargain"] end, node = 55 },
            -- Ghosts enclave completed (knows Saevus well)
            { condition = function(g) return RPG.Quest.IsComplete(g, "ghosts_enclave") end, node = 10 },
            -- High paranoia path
            { condition = function(g) return g.player.paranoia >= 80 end, node = 5 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: First Meeting (Standard)
    -- ============================================
    [1] = {
        speaker = "Saevus Manifestation",
        text = function(g)
            local lines = {
                "Dark energy coalesces into a figure — tall,",
                "gaunt, wearing the ceremonial robes of an",
                "ancient Sith Lord. The face is ageless,",
                "the eyes burning with patient intelligence.",
                "",
                "'At last. Face to face, after all these",
                "whispers. I am Saevus. You already know that.'",
            }
            if RPG.Quest.HasFlag(g, "saber_corrupted") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'I see you kept my gift. The blade sings"
                lines[#lines + 1] = "to me even now. Every cut, every kill --"
                lines[#lines + 1] = "I felt them all.'"
            elseif RPG.Quest.HasFlag(g, "saber_pure") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'You refused my gift. The blade is clean."
                lines[#lines + 1] = "Pure. Boring. You will regret that"
                lines[#lines + 1] = "when you face what comes next.'"
            end
            return lines
        end,
        responses = {
            {
                label = "You're the prisoner in the Holocron.",
                next = 11,
            },
            {
                label = "What do you want?",
                next = 12,
            },
            {
                label = "I'm here to end this.",
                next = 13,
            },
        },
    },

    -- ============================================
    -- NODE 5: High Paranoia Meeting
    -- ============================================
    [5] = {
        speaker = "Saevus Manifestation",
        text = function(g)
            local lines = {
                "The figure forms from your own shadow,",
                "peeling away from the floor like a second skin.",
                "",
                "'Your mind is nearly broken. I can feel",
                "the fractures. Every whisper, every glitch,",
                "every moment of doubt — they've prepared",
                "you for this.'",
                "",
                "'You're ready to listen now.'",
            }
            if RPG.Quest.HasFlag(g, "saber_corrupted") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'I see you kept my gift. The blade sings"
                lines[#lines + 1] = "to me even now. Every cut, every kill --"
                lines[#lines + 1] = "I felt them all.'"
            elseif RPG.Quest.HasFlag(g, "saber_pure") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'You refused my gift. The blade is clean."
                lines[#lines + 1] = "Pure. Boring. You will regret that"
                lines[#lines + 1] = "when you face what comes next.'"
            end
            return lines
        end,
        responses = {
            {
                label = "I'm not listening to you.",
                next = 13,
            },
            {
                label = "What have you been preparing me for?",
                next = 20,
            },
            {
                label = "The paranoia... that was you?",
                next = 21,
            },
        },
    },

    -- ============================================
    -- NODE 10: Post-Ghosts Enclave Meeting
    -- ============================================
    [10] = {
        speaker = "Saevus Manifestation",
        text = function(g)
            local lines = {
                "The figure manifests with unsettling familiarity.",
                "You've heard this voice through the Holocron",
                "for so long that seeing the face feels inevitable.",
                "",
            }
            if g.flags["holocron_embraced"] then
                lines[#lines + 1] = "'You embraced my teachings. I felt it."
                lines[#lines + 1] = "You have potential, apprentice."
                lines[#lines + 1] = "Now let me show you what that potential"
                lines[#lines + 1] = "can truly become.'"
            else
                lines[#lines + 1] = "'You rejected my lessons. Destroyed"
                lines[#lines + 1] = "the Holocron's teachings, or tried to."
                lines[#lines + 1] = "And yet here you are. Drawn to me"
                lines[#lines + 1] = "despite everything.'"
            end
            if RPG.Quest.HasFlag(g, "saber_corrupted") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'I see you kept my gift. The blade sings"
                lines[#lines + 1] = "to me even now. Every cut, every kill --"
                lines[#lines + 1] = "I felt them all.'"
            elseif RPG.Quest.HasFlag(g, "saber_pure") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'You refused my gift. The blade is clean."
                lines[#lines + 1] = "Pure. Boring. You will regret that"
                lines[#lines + 1] = "when you face what comes next.'"
            end
            return lines
        end,
        responses = {
            {
                label = "I'm here to seal you away forever.",
                next = 13,
            },
            {
                label = "What's beyond the cipher chamber?",
                next = 25,
            },
            {
                label = "Make me an offer. [Dark]",
                next = 30,
                condition = function(g) return g.player.alignment < 0 end,
            },
        },
    },

    -- ============================================
    -- NODE 11: "You're the prisoner"
    -- ============================================
    [11] = {
        speaker = "Saevus Manifestation",
        text = {
            "'Prisoner. Teacher. Mentor. Ghost.",
            "I have been many things inside that crystal.",
            "Four thousand years is a long time to think.'",
            "",
            "'I've had time to understand what I am.",
            "Have you?'",
        },
        responses = {
            {
                label = "I know what I am. That's why I'm here.",
                next = 13,
            },
            {
                label = "Tell me about the cipher.",
                next = 25,
            },
        },
    },

    -- ============================================
    -- NODE 12: "What do you want?"
    -- ============================================
    [12] = {
        speaker = "Saevus Manifestation",
        text = {
            "'What every prisoner wants. Freedom.'",
            "",
            "'But not the way you think. I don't need",
            "to escape the Holocron. I need someone",
            "to carry my knowledge forward. The ritual",
            "of Nathema. The secrets of Vitiate.",
            "The power to reshape worlds.'",
            "",
            "'You could be that someone.'",
        },
        responses = {
            {
                label = "Never. I'll seal you away.",
                next = 13,
            },
            {
                label = "Tell me more. [Dark]",
                next = 30,
                condition = function(g) return g.player.alignment < 0 end,
            },
            {
                label = "What about the cipher?",
                next = 25,
            },
        },
    },

    -- ============================================
    -- NODE 13: Rejection / "End this"
    -- ============================================
    [13] = {
        speaker = "Saevus Manifestation",
        text = {
            "Saevus smiles. It's not a pleasant smile.",
            "",
            "'Then solve the cipher. If you can.",
            "The fragments are scattered across every",
            "artifact you've touched on your journey.",
            "Nine digits. One code. One truth.'",
            "",
            "'But know this: the cipher seals the prison.",
            "It doesn't destroy me. Nothing can.'",
        },
        effects = {
            setFlag = "saevus_manifest_complete",
        },
        responses = {
            {
                label = "I'll find the code.",
                next = 26,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: "What have you been preparing me for?"
    -- ============================================
    [20] = {
        speaker = "Saevus Manifestation",
        text = {
            "'For this moment. The moment you stand",
            "at the threshold of the cipher chamber",
            "and realize that sealing me away means",
            "losing everything I could teach you.'",
            "",
            "'Start small. The sealed registry beneath",
            "the Iziz cathedral. Twelve hundred names --",
            "Force-sensitive children, hidden from the Jedi.'",
            "",
            "'A seed-scale dress rehearsal. Walls",
            "instead of a world. Names instead of stars.",
            "Vitiate consumed Nathema. I would start",
            "with Iziz -- and teach you to scale up.'",
            "",
            "'The ritual of consumption. The power",
            "to drain a world's connection to the Force.",
            "Vitiate used it on Nathema.",
            "I could teach you to use it on anything.'",
        },
        responses = {
            {
                label = "That power destroyed Nathema. I want no part of it.",
                next = 13,
                effects = { alignment = 10 },
            },
            {
                label = "Teach me. [Dark]",
                next = 30,
                condition = function(g) return g.player.alignment < 0 end,
            },
            {
                label = "Tell me about the cipher first.",
                next = 25,
            },
        },
    },

    -- ============================================
    -- NODE 21: "The paranoia was you?"
    -- ============================================
    [21] = {
        speaker = "Saevus Manifestation",
        text = {
            "'Not directly. The Holocron amplifies",
            "what's already there. Your doubts,",
            "your fears — those were always yours.',",
            "",
            "'I merely... encouraged them.",
            "A paranoid mind is an open mind.",
            "Open to suggestions. Open to power.'",
        },
        responses = {
            {
                label = "You manipulated me.",
                next = 13,
            },
            {
                label = "And now I'm here. What's the offer?",
                next = 30,
                condition = function(g) return g.player.alignment < 0 end,
            },
            {
                label = "Then say his name. Vorr.",
                next = 65,
                condition = function(g)
                    return g.player.paranoia >= 85
                        and g.loreDiscovered and g.loreDiscovered[31]
                end,
            },
        },
    },

    -- ============================================
    -- NODE 25: Cipher hints
    -- ============================================
    [25] = {
        speaker = "Saevus Manifestation",
        text = function(g)
            local discovered = 0
            if RPG.Cipher and RPG.Cipher.GetDiscoveredCount then
                discovered = RPG.Cipher.GetDiscoveredCount(g)
            end
            local total = 0
            if RPG.Data.Cipher and RPG.Data.Cipher.sources then
                for _ in pairs(RPG.Data.Cipher.sources) do total = total + 1 end
            end

            if discovered >= total and total > 0 then
                return {
                    "'You've found all the fragments.",
                    "The code is complete in your mind.",
                    "All that remains is to enter it.'",
                    "",
                    "'Nine digits. The cipher chamber awaits.'",
                }
            elseif discovered > 0 then
                return {
                    "'You've found " .. discovered .. " of " .. total .. " fragments.",
                    "The rest are hidden in artifacts",
                    "you may have overlooked.'",
                    "",
                    "'Examine the items in your inventory.",
                    "Read the lore. The code is there,",
                    "scattered across your journey.'",
                }
            else
                return {
                    "'The cipher is nine digits long.",
                    "Each digit is hidden in an artifact",
                    "connected to my history — items you've",
                    "collected on your journey.'",
                    "",
                    "'Examine your inventory. Read the lore.",
                    "The code is there, if you look.'",
                }
            end
        end,
        responses = {
            {
                label = "I'll find them.",
                next = 26,
            },
            {
                label = "Or I could skip the cipher entirely. [Dark]",
                next = 30,
                condition = function(g) return g.player.alignment < 0 end,
            },
        },
    },

    -- ============================================
    -- NODE 26: Cipher acknowledgment + quest advance
    -- ============================================
    [26] = {
        speaker = "Saevus Manifestation",
        text = {
            "'Then go. The cipher chamber is through",
            "the passage to the north. Enter the code",
            "and seal the prison — if that's truly",
            "what you want.'",
            "",
            "Saevus's form flickers. For a moment,",
            "you see something behind the mask:",
            "exhaustion. Four thousand years of it.",
        },
        effects = {
            setFlag = "saevus_manifest_complete",
            setStage = { quest = "echoes_final", stage = "cipher_chamber" },
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Dark Bargain
    -- ============================================
    [30] = {
        speaker = "Saevus Manifestation",
        text = {
            "Saevus's eyes ignite with ancient hunger.",
            "",
            "'I can teach you the ritual.",
            "Not all of it — not yet — but enough.",
            "Enough to feel what Vitiate felt",
            "when he consumed Nathema.'",
            "",
            "'In exchange: skip the cipher.",
            "Leave the prison unsealed.",
            "Embrace the dark path willingly.'",
        },
        responses = {
            {
                label = "I accept your bargain. [Dark: Alignment -20]",
                next = 35,
                effects = { alignment = -20 },
            },
            {
                label = "No. I'll solve the cipher myself.",
                next = 13,
                effects = { alignment = 5 },
            },
            {
                label = "[WIS 16] You're desperate. A prisoner offering gifts from inside the cell.",
                next = 40,
                check = { stat = "WIS", dc = 16 },
                failNext = 35,
            },
        },
    },

    -- ============================================
    -- NODE 35: Dark Bargain Accepted
    -- ============================================
    [35] = {
        speaker = "Saevus Manifestation",
        text = {
            "Saevus extends a hand of pure dark energy.",
            "You take it. Cold rushes through you —",
            "not the cold of temperature, but the cold",
            "of absolute emptiness. The Force drains",
            "from everything around you for one",
            "terrible, exhilarating moment.",
            "",
            "'Now you know. A fraction of what Vitiate felt.'",
            "",
            "'The dark ending awaits. Go east",
            "from the Chamber of Final Choice.'",
        },
        effects = {
            setFlag = "saevus_dark_bargain",
            paranoia = 15,
            setStage = { quest = "echoes_final", stage = "cipher_skipped" },
            action = function(player, game)
                game.flags["saevus_manifest_complete"] = true
            end,
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 40: WIS 16 sees through bargain
    -- ============================================
    [40] = {
        speaker = "Saevus Manifestation",
        text = {
            "Saevus hesitates. For the first time,",
            "something like uncertainty crosses",
            "that ageless face.",
            "",
            "'...Yes. I am desperate. Four thousand years",
            "is a long time to be trapped. But the offer",
            "was genuine. The power IS real.'",
            "",
            "'Solve the cipher, then. Seal the prison.",
            "But know that you chose safety over knowledge.",
            "The Jedi always do.'",
        },
        effects = {
            setFlag = "saevus_manifest_complete",
            alignment = 5,
        },
        responses = {
            {
                label = "Wisdom isn't the same as cowardice.",
                next = -1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 55: Return after dark bargain
    -- ============================================
    [55] = {
        speaker = "Saevus Manifestation",
        text = function(g)
            local lines = {
                "'You already have what I offered.",
                "The dark path is open. Room 52.",
                "Go. Embrace what you've become.'",
            }
            if RPG.Quest.HasFlag(g, "saber_corrupted") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'Both my gifts. The bargain and the blade."
                lines[#lines + 1] = "You are becoming something interesting.'"
            elseif RPG.Quest.HasFlag(g, "saber_pure") then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "'You took my bargain but refused the blade."
                lines[#lines + 1] = "Selective morality. How... human.'"
            end
            return lines
        end,
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 60: Return after completion
    -- ============================================
    [60] = {
        speaker = "Saevus Manifestation",
        text = {
            "Saevus's form is fainter now. Translucent.",
            "The manifestation is weakening.",
            "",
            "'The cipher chamber is through the passage.",
            "Whatever you choose to do with the code...",
            "choose quickly. I grow tired of waiting.'",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 65: Paranoia >= 85 + Item 31 examined — Vorr cruel callback
    -- (Node 35 is taken — Dark Bargain Accepted branch.)
    -- ============================================
    [65] = {
        speaker = "Saevus Manifestation",
        text = {
            "Saevus laughs. The sound is dry, ancient.",
            "",
            "'Vorr. Yes. I remember Vorr.'",
            "",
            "'He came further than you. He held",
            "his name longer than you have. He was",
            "more disciplined, more clever, more lit",
            "from within than you will ever be.'",
            "",
            "'^1Vorr lasted longer than you will.^7'",
            "",
            "'And now he is a hunger in a brown robe.",
            "Soon, so are you.'",
        },
        responses = {
            {
                label = "I am not Vorr.",
                next = 12,
            },
        },
    },
}
