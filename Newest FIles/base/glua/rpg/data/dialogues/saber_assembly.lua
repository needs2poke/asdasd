-- Dialogue Tree: Lightsaber Assembly (NPC 25 - Meditation Alcove)
-- Room 9 (Ancient Jedi Chamber)
-- Crystal choice, Kira's memories, Saevus temptation, forging
-- ~22 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Quest complete: nothing more to do
            { condition = function(g)
                return RPG.Quest.IsComplete(g, "saber_construction")
            end, node = 50 },
            -- Attunement in progress (resume)
            { condition = function(g)
                return RPG.Quest.GetStage(g, "saber_construction") == "attunement"
            end, node = 10 },
            -- Reached chamber with crystal AND lens: begin assembly
            { condition = function(g)
                local stage = RPG.Quest.GetStage(g, "saber_construction")
                if stage ~= "reach_chamber" then return false end
                if not RPG.Util.Contains(g.player.inventory, 41) then return false end
                return RPG.Util.Contains(g.player.inventory, 5)
                    or RPG.Util.Contains(g.player.inventory, 6)
            end, node = 1 },
            -- Reached chamber but NO crystal (defense-in-depth)
            { condition = function(g)
                return RPG.Quest.GetStage(g, "saber_construction") == "reach_chamber"
            end, node = 59 },
            -- Safety fallback: has all 3 items but quest lagged behind
            { condition = function(g)
                return RPG.Util.Contains(g.player.inventory, 4)
                    and RPG.Util.Contains(g.player.inventory, 41)
                    and (RPG.Util.Contains(g.player.inventory, 5)
                        or RPG.Util.Contains(g.player.inventory, 6))
            end, node = 1 },
            -- Has hilt + crystal but no lens
            { condition = function(g)
                return RPG.Util.Contains(g.player.inventory, 4)
                    and (RPG.Util.Contains(g.player.inventory, 5)
                        or RPG.Util.Contains(g.player.inventory, 6))
                    and not RPG.Util.Contains(g.player.inventory, 41)
            end, node = 58 },
            -- Has hilt only
            { condition = function(g)
                return RPG.Util.Contains(g.player.inventory, 4)
            end, node = 55 },
            -- Has crystal only
            { condition = function(g)
                return RPG.Util.Contains(g.player.inventory, 5)
                    or RPG.Util.Contains(g.player.inventory, 6)
            end, node = 56 },
        },
        fallback = 57,  -- nothing relevant
    },

    -- ============================================
    -- NODE 1: Crystal Choice (begin assembly)
    -- ============================================
    [1] = {
        speaker = "Meditation Alcove",
        text = {
            "You kneel before the alcove. The hilt rests on",
            "the stone. The focusing lens clicks into place",
            "with a satisfying precision.",
            "",
            "Now the crystal. The Force gathers around you,",
            "waiting for your choice.",
        },
        responses = {
            { label = "Place the green crystal. [Consular: WIS+2, INT+1]",
              next = 10,
              condition = function(g)
                  return RPG.Util.Contains(g.player.inventory, 5)
              end,
              effects = {
                  setFlag = "saber_crystal_green",
                  setStage = { quest = "saber_construction", stage = "attunement" },
              },
            },
            { label = "Place the blue crystal. [Guardian: STR+2, DEX+1]",
              next = 10,
              condition = function(g)
                  return RPG.Util.Contains(g.player.inventory, 6)
              end,
              effects = {
                  setFlag = "saber_crystal_blue",
                  setStage = { quest = "saber_construction", stage = "attunement" },
              },
            },
            { label = "[Leave] Not yet.",
              next = -1 },
        },
    },

    -- ============================================
    -- NODE 10: Crystal placed — Force surges
    -- ============================================
    [10] = {
        speaker = "Meditation Alcove",
        text = function(g)
            local color = RPG.Quest.HasFlag(g, "saber_crystal_green") and "green" or "blue"
            return {
                "The crystal settles into the housing. For a",
                "moment, nothing happens.",
                "",
                "Then the Force SURGES. The cave walls glow " .. color .. ".",
                "The murals come alive — Padawans kneeling here",
                "centuries ago, performing this same ritual.",
                "",
                "The crystal is reaching for you. Showing you",
                "something.",
            }
        end,
        responses = {
            { label = "Open yourself to the vision.",
              next = 11 },
        },
    },

    -- ============================================
    -- NODE 11: Kira's Memories
    -- ============================================
    [11] = {
        speaker = "Meditation Alcove",
        text = {
            "Fragments of memory that aren't yours. A woman",
            "in Shadow robes — Kira — building this same",
            "lightsaber decades ago. Her hands steady, her",
            "mind clear.",
            "",
            "Then later: fear. Running. A ship plummeting",
            "toward Dantooine. Something in the hold that",
            "must never reach the Republic.",
        },
        responses = {
            { label = "[WIS 12] Reach deeper into the memory.",
              next = 12,
              check = { stat = "WIS", dc = 12 },
              failNext = 13 },
            { label = "Let the fragments fade.",
              next = 13 },
        },
    },

    -- ============================================
    -- NODE 12: Deeper vision (WIS 12 pass)
    -- ============================================
    [12] = {
        speaker = "Meditation Alcove",
        text = {
            "The vision sharpens. Kira's last moments.",
            "",
            "She crashed the ship on purpose.",
            "",
            "Better to die on Dantooine than deliver a Sith",
            "Lord to the Republic. She aimed for the Crystal",
            "Caves — the strongest light-side nexus she knew.",
            "",
            "Her last thought: 'Let someone stronger find it.'",
            "",
            "The vision releases you. The crystal hums.",
        },
        responses = {
            { label = "Continue the assembly.",
              next = 20 },
        },
    },

    -- ============================================
    -- NODE 13: Fragments fade (WIS fail or skip)
    -- ============================================
    [13] = {
        speaker = "Meditation Alcove",
        text = {
            "The fragments scatter like leaves in wind.",
            "Whatever Kira wanted to show you, you couldn't",
            "hold onto it.",
            "",
            "The crystal hums. The assembly continues.",
        },
        responses = {
            { label = "Continue the assembly.",
              next = 20 },
        },
    },

    -- ============================================
    -- NODE 20: Blade nearly complete
    -- ============================================
    [20] = {
        speaker = "Meditation Alcove",
        text = {
            "The crystal locks into alignment. The emitter",
            "matrix hums. The focusing lens channels the",
            "crystal's energy into a coherent beam pattern.",
            "",
            "The lightsaber is nearly complete. One final",
            "attunement — your will, your connection to the",
            "Force, sealing the bond between wielder and blade.",
        },
        responses = {
            { label = "Complete the attunement.",
              next = 30 },
        },
    },

    -- ============================================
    -- NODE 30: Router — Holocron check
    -- ============================================
    [30] = {
        routes = {
            -- Has Holocron: Saevus temptation
            { condition = function(g) return g.player.hasHolocron end, node = 31 },
        },
        -- No Holocron: clean assembly
        fallback = 40,
    },

    -- ============================================
    -- NODE 31: Saevus temptation
    -- ============================================
    [31] = {
        speaker = "Meditation Alcove",
        text = function(g)
            local color = RPG.Quest.HasFlag(g, "saber_crystal_green") and "green" or "blue"
            return {
                "As you reach for the final attunement, the",
                "Holocron PULSES. Cold floods the chamber.",
                "",
                "'^1The crystal is flawed.^7' Saevus's whisper,",
                "directly in your mind. '^1Dormant. Sleeping.",
                "Let me awaken its full potential.^7'",
                "",
                "The " .. color .. " light flickers. Waiting for your answer.",
            }
        end,
        responses = {
            { label = "Accept Saevus's enhancement.",
              next = 32 },
            { label = "Refuse. Complete the blade as it is.",
              next = 35 },
            { label = "[WIS 14] I see what you're doing. You want a foothold in this blade.",
              next = 33,
              check = { stat = "WIS", dc = 14 },
              isDoubt = true,
              truthLabel = "I see what you're doing. You want a foothold in this blade.",
              failNext = 34 },
        },
    },

    -- ============================================
    -- NODE 32: Corruption accepted
    -- ============================================
    [32] = {
        speaker = "Meditation Alcove",
        text = function(g)
            if RPG.Quest.HasFlag(g, "saber_crystal_green") then
                return {
                    "The green light flickers, shot through with",
                    "red veins like infected blood. The emerald",
                    "darkens to something toxic, bleeding —",
                    "a sickly luminescence that hurts to look at.",
                    "",
                    "'^1Better.^7' Saevus sounds satisfied.",
                    "'^1Much better.^7'",
                }
            else
                return {
                    "The blue light shudders, bruise-purple",
                    "bleeding through the crystal's core. The",
                    "clean azure darkens to something wounded,",
                    "pulsing with an irregular heartbeat.",
                    "",
                    "'^1Better.^7' Saevus sounds satisfied.",
                    "'^1Much better.^7'",
                }
            end
        end,
        effects = {
            action = function(player, game)
                local isGreen = RPG.Quest.HasFlag(game, "saber_crystal_green")
                local saberId = isGreen and 39 or 40
                local crystalId = isGreen and 5 or 6
                RPG.Util.RemoveValue(game.player.inventory, 4)   -- hilt
                RPG.Util.RemoveValue(game.player.inventory, 41)  -- lens
                RPG.Util.RemoveValue(game.player.inventory, crystalId)
                game.player.inventory[#game.player.inventory + 1] = saberId
                game._forgedSaberId = saberId
                RPG.Quest.SetFlag(game, "saber_corrupted")
                game.flags["saber_pure"] = nil  -- mutual exclusivity
                RPG.AddAlignment(player, -10)
                RPG.AddParanoia(player, 10)
                player:SendPrint("^1[Forged] " .. RPG.Config.ITEM_COLOR .. RPG.Data.GetItemName(saberId))
                player:PlaySound("sound/weapons/saber/saberon.wav")
                RPG.Quest.Complete(player, "saber_construction")
            end,
        },
        responses = {
            { label = "The blade is ready.",
              next = 36 },
        },
    },

    -- ============================================
    -- NODE 33: WIS 14 pass — see through Saevus
    -- ============================================
    [33] = {
        speaker = "Meditation Alcove",
        text = {
            "'^1...Clever.^7' A pause. The whisper recedes",
            "slightly, like a hand pulling back from a flame.",
            "",
            "'^1Yes. I want a foothold. Every tool I touch",
            "becomes a conduit. But the power IS real.",
            "The enhancement IS genuine.^7'",
            "",
            "'^1The question is whether the cost matters to you.^7'",
        },
        responses = {
            { label = "Accept anyway. Power is power.",
              next = 32 },
            { label = "No. I'll take the blade clean.",
              next = 35 },
        },
    },

    -- ============================================
    -- NODE 34: WIS 14 fail — deceived
    -- ============================================
    [34] = {
        speaker = "Meditation Alcove",
        text = {
            "'^1There is no cost. I merely complete what",
            "the crystal cannot do alone. Think of it as...",
            "a gift. From teacher to student.^7'",
            "",
            "The whisper feels warm. Reassuring.",
            "Almost trustworthy.",
        },
        responses = {
            { label = "Accept the gift.",
              next = 32 },
            { label = "I don't trust gifts from Sith Lords.",
              next = 35 },
        },
    },

    -- ============================================
    -- NODE 35: Pure blade (refuse corruption)
    -- ============================================
    [35] = {
        speaker = "Meditation Alcove",
        text = function(g)
            local color = RPG.Quest.HasFlag(g, "saber_crystal_green") and "green" or "blue"
            return {
                "You push the whisper away. The cold recedes.",
                "The " .. color .. " light steadies, pure and clean.",
                "",
                "The crystal locks into place. The Force sings",
                "— a single clear note that fills the chamber.",
                "",
                "Kira's lightsaber lives again.",
            }
        end,
        effects = {
            action = function(player, game)
                local isGreen = RPG.Quest.HasFlag(game, "saber_crystal_green")
                local saberId = isGreen and 37 or 38
                local crystalId = isGreen and 5 or 6
                RPG.Util.RemoveValue(game.player.inventory, 4)   -- hilt
                RPG.Util.RemoveValue(game.player.inventory, 41)  -- lens
                RPG.Util.RemoveValue(game.player.inventory, crystalId)
                game.player.inventory[#game.player.inventory + 1] = saberId
                game._forgedSaberId = saberId
                RPG.Quest.SetFlag(game, "saber_pure")
                game.flags["saber_corrupted"] = nil  -- mutual exclusivity
                RPG.AddAlignment(player, 5)
                player:SendPrint("^2[Forged] " .. RPG.Config.ITEM_COLOR .. RPG.Data.GetItemName(saberId))
                player:PlaySound("sound/weapons/saber/saberon.wav")
                RPG.Quest.Complete(player, "saber_construction")
            end,
        },
        responses = {
            { label = "The blade is ready.",
              next = 36 },
        },
    },

    -- ============================================
    -- NODE 36: Ignite ceremony prompt
    -- ============================================
    [36] = {
        speaker = "Meditation Alcove",
        text = {
            "The lightsaber rests in your hand.",
            "Complete. Waiting.",
        },
        responses = {
            { label = "Ignite the blade.",
              next = 37 },
        },
    },

    -- ============================================
    -- NODE 37: Ignition narration + auto-equip
    -- ============================================
    [37] = {
        speaker = "Meditation Alcove",
        text = function(g)
            if RPG.Quest.HasFlag(g, "saber_corrupted") then
                return {
                    "The blade snaps to life with a sound like",
                    "tearing metal. The light is wrong -- vivid",
                    "but unstable, pulsing with a rhythm that",
                    "doesn't match your heartbeat.",
                    "",
                    "It matches something else's.",
                }
            else
                return {
                    "The blade ignites with a clean hum that",
                    "fills the chamber. For a moment, the cave",
                    "walls glow with reflected light -- green or blue,",
                    "steady and true.",
                    "",
                    "Kira's lightsaber lives again.",
                }
            end
        end,
        effects = {
            action = function(player, game)
                local saberId = game._forgedSaberId
                if saberId then
                    for i, itemId in ipairs(game.player.inventory) do
                        if itemId == saberId then
                            RPG.EquipItem(player, i)
                            break
                        end
                    end
                end
                game._forgedSaberId = nil
                player:PlaySound("sound/weapons/saber/saberon.wav")
            end,
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },

    -- ============================================
    -- NODE 40: No Holocron — clean assembly
    -- ============================================
    [40] = {
        speaker = "Meditation Alcove",
        text = function(g)
            local color = RPG.Quest.HasFlag(g, "saber_crystal_green") and "green" or "blue"
            return {
                "The attunement completes without interference.",
                "No whispers. No cold. Just you, the Force,",
                "and the crystal.",
                "",
                "The " .. color .. " light fills the chamber as the",
                "crystal locks into place. The Force sings.",
                "",
                "Kira's lightsaber lives again.",
            }
        end,
        effects = {
            action = function(player, game)
                local isGreen = RPG.Quest.HasFlag(game, "saber_crystal_green")
                local saberId = isGreen and 37 or 38
                local crystalId = isGreen and 5 or 6
                RPG.Util.RemoveValue(game.player.inventory, 4)   -- hilt
                RPG.Util.RemoveValue(game.player.inventory, 41)  -- lens
                RPG.Util.RemoveValue(game.player.inventory, crystalId)
                game.player.inventory[#game.player.inventory + 1] = saberId
                game._forgedSaberId = saberId
                RPG.Quest.SetFlag(game, "saber_pure")
                game.flags["saber_corrupted"] = nil  -- mutual exclusivity
                RPG.AddAlignment(player, 5)
                player:SendPrint("^2[Forged] " .. RPG.Config.ITEM_COLOR .. RPG.Data.GetItemName(saberId))
                player:PlaySound("sound/weapons/saber/saberon.wav")
                RPG.Quest.Complete(player, "saber_construction")
            end,
        },
        responses = {
            { label = "The blade is ready.",
              next = 36 },
        },
    },

    -- ============================================
    -- NODE 50: Quest complete — return visit
    -- ============================================
    [50] = {
        speaker = "Meditation Alcove",
        text = {
            "The alcove is quiet. The stone still holds",
            "the warmth of your attunement. There is nothing",
            "more to do here.",
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },

    -- ============================================
    -- NODE 55: Has hilt only — need crystal
    -- ============================================
    [55] = {
        speaker = "Meditation Alcove",
        text = {
            "The alcove resonates faintly with the broken",
            "hilt. But there is nothing to attune.",
            "",
            "You need a Force crystal.",
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },

    -- ============================================
    -- NODE 56: Has crystal only — need hilt
    -- ============================================
    [56] = {
        speaker = "Meditation Alcove",
        text = {
            "The crystal hums in your pocket, responding",
            "to the alcove's residual Force energy.",
            "",
            "But you need a lightsaber hilt to channel it.",
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },

    -- ============================================
    -- NODE 57: Nothing relevant
    -- ============================================
    [57] = {
        speaker = "Meditation Alcove",
        text = {
            "An empty alcove. The stone is worn smooth by",
            "centuries of kneeling Padawans. Whatever purpose",
            "it served, it has nothing to offer you now.",
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },

    -- ============================================
    -- NODE 58: Has hilt + crystal but no lens
    -- ============================================
    [58] = {
        speaker = "Meditation Alcove",
        text = {
            "You place the hilt in the alcove. The crystal",
            "responds, glowing faintly. But when you try to",
            "seat the crystal, there is nothing to focus it.",
            "",
            "The focusing lens is shattered. You need someone",
            "with precision optics experience to fabricate",
            "a replacement.",
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },

    -- ============================================
    -- NODE 59: Reached chamber but no crystal
    -- ============================================
    [59] = {
        speaker = "Meditation Alcove",
        text = {
            "The alcove resonates with the hilt. The focusing",
            "lens is ready. But there is nothing to attune.",
            "",
            "You need a Force crystal.",
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },
}
