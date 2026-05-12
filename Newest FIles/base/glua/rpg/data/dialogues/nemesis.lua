-- Dialogue Tree: Nemesis (The Hunter & The Hunted)
-- Dynamic NPC: name/text generated from game.nemesis state
-- ~48 nodes, 3 encounters, 4 end states
-- All origin/temperament variation via text = function(g) dynamic text

return {

    -- ============================================
    -- NODE 0: Root Router (encounter-based)
    -- ============================================
    [0] = {
        routes = {
            { condition = function(g) return g.nemesis and g.nemesis.encounter == 0 end, node = 1 },
            { condition = function(g) return g.nemesis and g.nemesis.encounter == 1 end, node = 20 },
            { condition = function(g) return g.nemesis and g.nemesis.encounter == 2 end, node = 35 },
        },
        fallback = 1,
    },

    -- ============================================
    -- ENCOUNTER 1 (Nodes 1-19)
    -- ============================================

    -- Node 1: Origin-specific greeting
    [1] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if not n then return { "A figure blocks your path." } end
            local lines = {
                exchange = {
                    "A hand rests on a holstered blaster. Exchange colors.",
                    "'^7" .. n.fullName .. ". The bounty on your head just",
                    "went active. Nothing personal -- strictly business.'",
                },
                republic = {
                    "Gray uniform. No insignia. A regulation sidearm.",
                    "'^7I'm " .. n.fullName .. ". Republic Special Division.",
                    "Rogue Force users are a threat to Republic security.'",
                },
                mandalorian = {
                    "Beskar plate. A T-visor catches the light.",
                    "'^7" .. n.fullName .. ". I've hunted beasts,",
                    "soldiers, Sith. But never a Jedi. Until now.'",
                },
            }
            return lines[n.origin] or { "A hunter blocks your path." }
        end,
        responses = {
            {
                label = "[Intimidate] You picked the wrong target.",
                next = 2,
            },
            {
                label = "[Negotiate] Can we talk about this?",
                next = 3,
            },
            {
                label = "[Attack] Draw your weapon. Now.",
                next = 5,
                effects = { setFlag = "nemesis_attacked_on_sight" },
            },
        },
    },

    -- Node 2: Intimidate response
    [2] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if not n then return { "'We'll see.'" } end
            local temps = {
                professional = { "'I've heard that before. From people who are dead now. Let's find out.'" },
                sadistic     = { "'Good. I was hoping you'd make this fun.'", "A grin spreads across their face." },
                cold         = { "'Noted. Your psychological profile will be updated.' They draw their weapon." },
                zealot       = { "'The Republic's will cannot be intimidated.' They level their weapon at you." },
                honorable    = { "'I respect the confidence. But confidence isn't skill.' They take a fighting stance." },
                obsessed     = { "'YES. That fire in your eyes. That's what I came for.' They draw eagerly." },
            }
            return temps[n.temperament] or { "'We'll see.'" }
        end,
        responses = {
            {
                label = "Then let's finish this.",
                next = 5,
            },
            {
                label = "[CHA 12] Last chance. Walk away.",
                next = 4,
                check = { stat = "CHA", dc = 12 },
                failNext = 5,
            },
        },
    },

    -- Node 3: Negotiate response
    [3] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if not n then return { "'Nothing to discuss.'" } end
            local temps = {
                professional = { "'Credits are credits. Unless you can outbid my employer--'", "They shake their head. 'No. A contract is a contract.'" },
                sadistic     = { "'Talk? Where's the fun in that?'", "They crack their knuckles." },
                cold         = { "'Dialogue is acceptable. Briefly.' Their hand stays on the weapon." },
                zealot       = { "'There is nothing to negotiate. The Republic's judgment is final.'" },
                honorable    = { "'Mandalorians don't negotiate hunts. We finish them.' A pause. 'But I'll hear you out. Briefly.'" },
                obsessed     = { "'You want to TALK? I didn't track you across systems to TALK.'" },
            }
            return temps[n.temperament] or { "'Nothing to discuss.'" }
        end,
        responses = {
            {
                label = "[CHA 13] There's more going on here than a bounty.",
                next = 4,
                check = { stat = "CHA", dc = 13 },
                failNext = 5,
            },
            {
                label = "Fine. If you won't listen, we do this the hard way.",
                next = 5,
            },
        },
    },

    -- Node 4: CHA check success (talk-down, Enc 1 only delays)
    [4] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            return {
                "For a moment, something shifts in their expression.",
                "'^7...You make a fair point. I'll verify my intel.'",
                "'^7But if it checks out, I'll be back. Count on it.'",
                "They holster their weapon and step back.",
            }
        end,
        responses = {
            {
                label = "[Continue]",
                next = -1,
                effects = {
                    setFlag = "nemesis_talked_down_1",
                    action = function(player, game)
                        game.nemesis.encounter = 1
                        game.nemesis.attitude = RPG.Nemesis.ComputeAttitude(game)
                    end,
                },
            },
        },
    },

    -- Node 5: Combat trigger
    [5] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if not n then return { "They attack." } end
            local temps = {
                professional = { "'^7Contract confirmed. Engaging.'" },
                sadistic     = { "'^7This is going to hurt. You more than me.'" },
                cold         = { "'^7Initiating neutralization protocol.'" },
                zealot       = { "'^7For the Republic.'" },
                honorable    = { "'^7Then we fight. May the best warrior win.'" },
                obsessed     = { "'^7FINALLY.'" },
            }
            return temps[n.temperament] or { "They attack." }
        end,
        responses = {
            {
                label = "[Fight]",
                next = -1,
                effects = {
                    action = function(player, game)
                        RPG.Nemesis.StartEncounter(player, game)
                    end,
                },
            },
        },
    },

    -- Node 6: Post-combat (victory, spare option)
    [6] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            return {
                "They're on the ground. Breathing hard. Their weapon is out of reach.",
                "'^7...Finish it, then.'",
            }
        end,
        responses = {
            {
                label = "No. Get up. Leave.",
                next = 7,
            },
            {
                label = "You're not worth killing.",
                next = 8,
                effects = { setFlag = "nemesis_humiliated_1" },
            },
            {
                label = "[Kill them]",
                next = 9,
            },
        },
    },

    -- Node 7: Spare (Enc 1)
    [7] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            local temps = {
                professional = { "They stare at you for a long moment.", "'...I'll remember this.' They pick up their weapon and leave." },
                sadistic     = { "'Mercy? That's new.' A bitter laugh. They limp away." },
                cold         = { "'Noted.' They collect themselves with clinical efficiency and withdraw." },
                zealot       = { "'Your restraint... doesn't fit the profile.' They look confused as they leave." },
                honorable    = { "'You fight with honor. I didn't expect that.' A nod of genuine respect." },
                obsessed     = { "'You could have ended this. Why didn't you?' They seem disturbed." },
            }
            return temps[n.temperament] or { "They leave." }
        end,
        responses = {
            {
                label = "[Continue]",
                next = -1,
                effects = {
                    setFlag = "nemesis_spared_1",
                    alignment = 3,
                },
            },
        },
    },

    -- Node 8: Humiliate (Enc 1)
    [8] = {
        text = function(g)
            return { "They flinch at the words. The humiliation cuts deeper than any blade.", "They scramble for their weapon and flee." }
        end,
        responses = {
            {
                label = "[Continue]",
                next = -1,
                effects = { alignment = -2 },
            },
        },
    },

    -- Node 9: Kill attempt (Enc 1 -- they escape)
    [9] = {
        text = function(g)
            local n = g.nemesis
            return {
                "You strike -- but they throw a flash charge.",
                "When your vision clears, they're gone.",
                "^8A trail of blood leads away. They'll be back.",
            }
        end,
        responses = {
            {
                label = "[Continue]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- ENCOUNTER 2 (Nodes 20-34)
    -- ============================================

    -- Node 20: Enc 2 intro (remembers Enc 1)
    [20] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if not n then return { "They found you again." } end
            local scarDesc = RPG.Data.NemesisData.SCAR_DESCRIPTIONS[n.origin]
            local scar = scarDesc and scarDesc[n.scarStage] or ""
            local srcText = RPG.Data.NemesisData.GetScarSource(g) or ""
            local base = { "^7" .. scar }
            if srcText ~= "" then
                base[#base + 1] = srcText
            end
            -- Memory-based opening
            if g.flags["nemesis_spared_1"] then
                base[#base + 1] = "'^7You let me live last time. That was a mistake.'"
                base[#base + 1] = "'^7I had time to prepare.'"
            elseif g.flags["nemesis_humiliated_1"] then
                base[#base + 1] = "'^7I haven't forgotten what you said. What you did.'"
                base[#base + 1] = "'^7This time, I'm not pulling my punches.'"
            elseif g.flags["nemesis_player_lost_1"] then
                base[#base + 1] = "'^7You failed last time. And yet here you are.'"
                base[#base + 1] = "'^7Persistent. I'll give you that.'"
            else
                base[#base + 1] = "'^7We meet again. I hoped it would be under different circumstances.'"
            end
            return base
        end,
        responses = {
            {
                label = function(g)
                    if g.flags["nemesis_spared_1"] then
                        return "I showed you mercy. Remember that."
                    end
                    return "You should have stayed away."
                end,
                next = 22,
            },
            {
                label = "[CHA 14] We don't have to do this again.",
                next = 25,
                check = { stat = "CHA", dc = 14 },
                failNext = 26,
            },
            {
                label = "[Attack] No more talking.",
                next = 26,
                effects = { setFlag = "nemesis_attacked_on_sight" },
            },
        },
    },

    -- Node 22: Dialogue branch (Enc 2 pre-combat)
    [22] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            local temps = {
                professional = { "'^7The contract doubled after last time. Nothing personal.' They draw." },
                sadistic     = { "'^7I've been dreaming about this. The look on your face.' They grin." },
                cold         = { "'^7My analysis of our previous encounter is complete. Adjustments made.' They raise their weapon." },
                zealot       = { "'^7The Republic does not forget. Neither do I.' They level their weapon." },
                honorable    = { "'^7A rematch. Properly fought this time.' They salute with their weapon." },
                obsessed     = { "'^7Every night I replay our fight. Every night I find a new way to win.' They shake with anticipation." },
            }
            return temps[n.temperament] or { "They prepare to fight." }
        end,
        responses = {
            {
                label = "Then let's settle this.",
                next = 26,
            },
        },
    },

    -- Node 25: CHA 14 talk-down success (Enc 2 -- avoid combat)
    [25] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            return {
                "Something in your voice gives them pause.",
                "'^7...I'm not sure what you are anymore.'",
                "'^7The bounty says one thing. My instincts say another.'",
                "They lower their weapon slowly.",
                "'^7I need time to think. Don't make me regret this.'",
            }
        end,
        responses = {
            {
                label = "[Continue]",
                next = -1,
                effects = {
                    setFlag = "nemesis_talked_down_2",
                    alignment = 2,
                    action = function(player, game)
                        game.nemesis.encounter = 2
                        game.nemesis.scarStage = math.min(game.nemesis.scarStage + 1, 2)
                        game.nemesis.attitude = RPG.Nemesis.ComputeAttitude(game)
                    end,
                },
            },
        },
    },

    -- Node 26: Combat trigger (Enc 2)
    [26] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if n and n.adaptation ~= "none" then
                return { "New equipment glints on their armor. They've adapted.", "'^7I learn from my mistakes.'" }
            end
            return { "They raise their weapon. No more words." }
        end,
        responses = {
            {
                label = "[Fight]",
                next = -1,
                effects = {
                    action = function(player, game)
                        RPG.Nemesis.StartEncounter(player, game)
                    end,
                },
            },
        },
    },

    -- Node 27: Post-combat (Enc 2, victory)
    [27] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            return {
                "They're down again. More damage this time.",
                "Blood seeps through cracked armor.",
                "'^7...Twice now...'",
            }
        end,
        responses = {
            {
                label = "Get up. This isn't over yet.",
                next = 28,
            },
            {
                label = "You're beaten. Stay down.",
                next = 29,
                effects = { setFlag = "nemesis_humiliated_2" },
            },
            {
                label = "Leave. And don't come back.",
                next = 30,
            },
        },
    },

    -- Node 28: Neutral response (Enc 2)
    [28] = {
        text = function(g)
            return { "They watch you with a complex expression.", "Then they drag themselves up and limp away." }
        end,
        responses = {
            { label = "[Continue]", next = -1 },
        },
    },

    -- Node 29: Humiliate (Enc 2)
    [29] = {
        text = function(g)
            return { "The words land like a second defeat.", "Pure hatred burns in their eyes as they retreat." }
        end,
        responses = {
            { label = "[Continue]", next = -1, effects = { alignment = -2 } },
        },
    },

    -- Node 30: Spare (Enc 2)
    [30] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if g.flags["nemesis_spared_1"] then
                return {
                    "'^7Twice. You've spared me twice.'",
                    "'^7I... don't understand you.'",
                    "Something changes behind their eyes. Not surrender. Something else.",
                }
            end
            return { "'^7...Fine.' They gather their things and leave.", "They don't look back." }
        end,
        responses = {
            {
                label = "[Continue]",
                next = -1,
                effects = {
                    setFlag = "nemesis_spared_2",
                    alignment = 3,
                },
            },
        },
    },

    -- ============================================
    -- ENCOUNTER 3 (Nodes 35-48)
    -- ============================================

    -- Node 35: Final confrontation intro
    [35] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if not n then return { "The hunter stands before you one last time." } end
            local scarDesc = RPG.Data.NemesisData.SCAR_DESCRIPTIONS[n.origin]
            local scar = scarDesc and scarDesc[n.scarStage] or ""
            local base = { "^7" .. scar }

            -- Attitude-specific tone
            local att = n.attitude
            if att == "respect" then
                base[#base + 1] = "'^7I didn't come here to fight. Not this time.'"
                base[#base + 1] = "'^7But I need to see this through. We both do.'"
            elseif att == "hatred" then
                base[#base + 1] = "'^7I've been waiting for this. Every scar you gave me brought me here.'"
                base[#base + 1] = "'^7One of us ends today.'"
            elseif att == "fear" then
                base[#base + 1] = "'^7I know what you are now. What you're becoming.'"
                base[#base + 1] = "'^7I'm terrified. But I came anyway. Someone has to stop you.'"
            elseif att == "obsession" then
                base[#base + 1] = "'^7You beat me. Again and again. But I keep coming back.'"
                base[#base + 1] = "'^7I can't stop. You're the only thing that makes me feel alive.'"
            else
                base[#base + 1] = "'^7This is where it ends. For one of us.'"
            end
            return base
        end,
        responses = {
            {
                label = "We can end this without fighting.",
                next = 36,
            },
            {
                label = "Draw your weapon.",
                next = 38,
                effects = { setFlag = "nemesis_attacked_on_sight" },
            },
            {
                label = function(g)
                    local attitude = RPG.Nemesis.ComputeAttitude(g)
                    if attitude == "respect" then
                        return "[Recruit] Stand down. Join me."
                    end
                    return nil  -- hidden if not available
                end,
                next = 42,
                condition = function(g)
                    local attitude = RPG.Nemesis.ComputeAttitude(g)
                    return attitude == "respect"
                        and g.player.alignment > 0
                end,
            },
        },
    },

    -- Node 36: Try to end peacefully
    [36] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            if n and n.attitude == "respect" then
                return {
                    "'^7...You're right. You've shown me mercy when I didn't deserve it.'",
                    "'^7But the contract is still active. If I walk away, someone else comes.'",
                    "'^7Unless...'",
                }
            end
            return {
                "'^7End it without fighting?' A bitter laugh.",
                "'^7You don't understand. This isn't just business anymore.'",
            }
        end,
        responses = {
            {
                label = "[CHA 16] Walk away. Disappear. I won't stop you.",
                next = 41,
                check = { stat = "CHA", dc = 16 },
                failNext = 37,
            },
            {
                label = "Then we fight.",
                next = 38,
            },
        },
    },

    -- Node 37: CHA 16 fail
    [37] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = { "'^7Nice try. But words won't work this time.'", "They draw their weapon." },
        responses = {
            { label = "[Fight]", next = 38 },
        },
    },

    -- Node 38: Combat trigger (Enc 3) with dual-voice check
    [38] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local lines = { "'^7This ends now.'" }
            -- DUAL-VOICE MOMENT: one-shot, Nemesis + Saevus simultaneous
            if g.player.paranoia > 40 and not g.flags["nemesis_dual_voice_fired"] then
                lines = {
                    "^3" .. g.nemesis.fullName .. " speaks aloud:",
                    "'^7You're a monster. Look at what you've become.'",
                    "",
                    "^1[WHISPER] He's right. And he's terrified. Use that.",
                    "",
                    "^8Two voices. One outside, one inside. Both watching you.",
                }
            end
            return lines
        end,
        responses = {
            {
                label = "[Fight]",
                next = -1,
                effects = {
                    action = function(player, game)
                        if game.player.paranoia > 40 and not game.flags["nemesis_dual_voice_fired"] then
                            game.flags["nemesis_dual_voice_fired"] = true
                        end
                        RPG.Nemesis.StartEncounter(player, game)
                    end,
                },
            },
        },
    },

    -- Node 39: Post-combat choice (Enc 3 victory)
    [39] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            return {
                "They're on the ground. For the last time.",
                "The fight is gone from their eyes. Only the question remains.",
                "'^7...Well? Finish it.'",
            }
        end,
        responses = {
            {
                label = "[Kill them]",
                next = 43,
            },
            {
                label = "No. It's over. Walk away.",
                next = 40,
            },
        },
    },

    -- Node 43: Kill ending
    [43] = {
        text = function(g)
            local n = g.nemesis
            return {
                "'^7...Fair enough.'",
                "^8" .. n.fullName .. "'s armor fragment clatters to the ground.",
                "^8The hunt is over.",
            }
        end,
        responses = {
            {
                label = "[Take the armor fragment]",
                next = 44,
                effects = {
                    alignment = -2,
                    action = function(player, game)
                        game.nemesis.defeated = true
                        game.flags["nemesis_resolved"] = true
                        RPG.Quest.SetStage(player, "the_hunter", "resolved")
                        RPG.Quest.Complete(player, "the_hunter")
                    end,
                },
            },
        },
    },

    -- Node 40: Spare ending (post-combat)
    [40] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            return {
                "They lie in the dust, breathing hard.",
                "'^7Three times. You've beaten me three times.'",
                "'^7And three times you've let me live.'",
                "They reach to their belt and unclip their weapon.",
                "'^7Take it. I don't need it anymore.'",
                "'^7The hunt is over.'",
            }
        end,
        responses = {
            {
                label = "[Accept their weapon]",
                next = 45,
                effects = {
                    alignment = 5,
                    action = function(player, game)
                        game.nemesis.defeated = true
                        game.flags["nemesis_resolved"] = true
                        game.flags["nemesis_spared_3"] = true
                        RPG.Quest.SetStage(player, "the_hunter", "resolved")
                        RPG.Quest.Complete(player, "the_hunter")
                    end,
                },
            },
        },
    },

    -- Node 41: Walk Away ending (CHA 16 success)
    [41] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            return {
                "A long silence. They search your face for deception.",
                "'^7...I believe you.'",
                "They holster their weapon. For the last time.",
                "'^7If anyone asks, you were already dead when I got here.'",
                "They turn and walk away. They don't look back.",
            }
        end,
        responses = {
            {
                label = "[Let them go]",
                next = 46,
                effects = {
                    alignment = 3,
                    action = function(player, game)
                        game.nemesis.defeated = true
                        game.flags["nemesis_resolved"] = true
                        game.flags["nemesis_walked_away"] = true
                        RPG.Quest.SetStage(player, "the_hunter", "resolved")
                        RPG.Quest.Complete(player, "the_hunter")
                    end,
                },
            },
        },
    },

    -- Node 42: Recruit ending (requires attitude == respect, alignment > 0)
    [42] = {
        speaker = function(g) return g.nemesis and g.nemesis.fullName or "The Hunter" end,
        text = function(g)
            local n = g.nemesis
            return {
                "They stare at you.",
                "'^7Stand down? After everything?'",
                "'^7You spared me. Twice. I've never...'",
                "A long pause. The weapon lowers.",
                "'^7I'll stand down. Not because you asked.'",
                "'^7Because you earned it.'",
                "They remove their insignia and hold it out.",
                "'^7If you need me. You know how to find me.'",
            }
        end,
        responses = {
            {
                label = "[Accept their insignia]",
                next = 47,
                effects = {
                    alignment = 3,
                    action = function(player, game)
                        game.nemesis.defeated = true
                        game.flags["nemesis_resolved"] = true
                        game.flags["nemesis_recruited"] = true
                        RPG.Quest.SetStage(player, "the_hunter", "resolved")
                        RPG.Quest.Complete(player, "the_hunter")
                        -- Saevus recruit reaction
                        if game.player.hasHolocron and (game.player.paranoia or 0) >= 30 then
                            RPG.Util.BatchPrint(player, {
                                "^1[WHISPER] A leash of a different kind. You trade one master for another. How... disappointing.",
                            })
                        end
                    end,
                },
            },
        },
    },

    -- ============================================
    -- ENDING NARRATION (Nodes 44-48)
    -- ============================================

    -- Node 44: Kill ending narration
    [44] = {
        text = function(g)
            return {
                "^8The armor fragment is cold in your hand.",
                "^8" .. g.nemesis.fullName .. " is dead. The hunt is over.",
                "^8But the bounty on your head? That's still out there.",
            }
        end,
        responses = { { label = "[Continue]", next = -1 } },
    },

    -- Node 45: Spare ending narration
    [45] = {
        text = function(g)
            return {
                "^8You hold their weapon. Given freely.",
                "^8" .. g.nemesis.fullName .. " disappears into the crowd.",
                "^8You may never see them again. But they'll remember.",
            }
        end,
        responses = { { label = "[Continue]", next = -1 } },
    },

    -- Node 46: Walk Away ending narration
    [46] = {
        text = function(g)
            return {
                "^8An empty space where they stood.",
                "^8" .. g.nemesis.fullName .. " is out there somewhere.",
                "^8Unresolved. Like so many things.",
            }
        end,
        responses = { { label = "[Continue]", next = -1 } },
    },

    -- Node 47: Recruit ending narration
    [47] = {
        text = function(g)
            return {
                "^8Their insignia is warm in your palm.",
                "^8" .. g.nemesis.fullName .. " -- enemy, rival, and now... contact.",
                "^8The hunt ends not with blood, but with understanding.",
            }
        end,
        responses = { { label = "[Continue]", next = -1 } },
    },

    -- Node 48: Defeat aftermath (if player lost -- shown via nemesis.lua OnCombatEnd)
    [48] = {
        text = function(g)
            return {
                "^8You wake up. They're gone.",
                "^8Something is missing from your inventory.",
                "^8The hunt continues.",
            }
        end,
        responses = { { label = "[Continue]", next = -1 } },
    },
}
