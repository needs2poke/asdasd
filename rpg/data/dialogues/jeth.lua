-- Dialogue Tree: Jeth the Scholar (Duros Mechanic)
-- Act 2 main quest giver, Room 33 (Mechanic's Workshop)
-- Quest 15: Unlocking the Holocron
-- ~20 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- P1: Quest active - gathering cells
            { condition = function(g)
                return RPG.Quest.GetStage(g, "holocron_unlock") == "gather_cells"
            end, node = 30 },
            -- P2: Quest active - spoke to Jeth (shouldn't linger here, but safety)
            { condition = function(g)
                return RPG.Quest.GetStage(g, "holocron_unlock") == "speak_jeth"
            end, node = 10 },
            -- P3: Analysis complete - results ready
            { condition = function(g)
                return RPG.Quest.GetStage(g, "holocron_unlock") == "analysis_complete"
            end, node = 60 },
            -- P4: Stalker survival stage
            { condition = function(g)
                return RPG.Quest.GetStage(g, "holocron_unlock") == "stalker_survival"
            end, node = 70 },
            -- P5: Cipher revealed
            { condition = function(g)
                return RPG.Quest.GetStage(g, "holocron_unlock") == "cipher_revealed"
            end, node = 80 },
            -- P6: Q18 active - Nathema discussion
            { condition = function(g)
                return RPG.Quest.IsActive(g, "nathema_echo")
                    and not RPG.Quest.IsComplete(g, "nathema_echo")
            end, node = 90 },
            -- P7: Analysis pending
            { condition = function(g)
                return RPG.Quest.GetStage(g, "holocron_unlock") == "analysis_pending"
            end, node = 40 },
            -- P8: Saber construction: has hilt, needs lens
            { condition = function(g)
                local q = g.quests and g.quests["saber_construction"]
                return q and q.status == "active"
                    and (q.stage == "hilt_found" or q.stage == "crystal_found")
                    and not RPG.Quest.HasFlag(g, "jeth_lens_given")
            end, node = 100 },
            -- P9: Lens recovery: quest active, gave lens but player lost it
            { condition = function(g)
                local q = g.quests and g.quests["saber_construction"]
                return q and q.status == "active"
                    and RPG.Quest.HasFlag(g, "jeth_lens_given")
                    and not RPG.Util.Contains(g.player.inventory, 41)
            end, node = 104 },
            -- P10: Quest complete
            { condition = function(g)
                return RPG.Quest.IsComplete(g, "holocron_unlock")
            end, node = 50 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: First Meeting (No quest yet)
    -- ============================================
    [1] = {
        speaker = "Jeth",
        text = {
            "The Duros looks up from his workbench, red eyes widening.",
            "He knocks over a stack of datapads scrambling to his feet.",
            "'^7You. You're the one carrying it. I can feel it from here",
            "-- cold, like standing in a dead star's shadow.'",
            "'^7Don't deny it. I've been studying Sith containment protocols",
            "for years. I know that frequency. That's a Holocron.'",
        },
        responses = {
            {
                label = "How do you know about Sith Holocrons?",
                next = 2,
            },
            {
                label = "What do you want?",
                next = 3,
            },
            {
                label = "[WIS 14] You're afraid of it. But also fascinated.",
                next = 4,
                check = { stat = "WIS", dc = 14 },
                failNext = 3,
            },
            {
                label = "I found records about a Beast Rider artifact...",
                next = 96,
                condition = function(g)
                    return RPG.Quest.GetStage(g, "beast_rider_legacy") == "artifact_search"
                        and RPG.Quest.HasFlag(g, "q17_checkpoint_seen")
                end,
            },
            {
                label = "I don't have time for this. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Jeth's backstory
    -- ============================================
    [2] = {
        speaker = "Jeth",
        text = {
            "He gestures at the cluttered workbench -- ancient texts,",
            "holocron schematics, containment diagrams.",
            "'^7I was a shipwright on Duro before the wars. Fixed hyperdrives,",
            "nothing special. Then a Jedi brought me a damaged Holocron to",
            "repair. Not the crystal matrix -- the physical housing.'",
            "'^7I touched it. And I heard... things. I've been researching",
            "ever since. Twenty years of dead ends and mad theories.'",
            "'^7Until now. Until you walked through that door.'",
        },
        responses = {
            {
                label = "What did you hear when you touched it?",
                next = 5,
            },
            {
                label = "Can you help me understand what I'm carrying?",
                next = 6,
            },
        },
    },

    -- ============================================
    -- NODE 3: "What do you want?"
    -- ============================================
    [3] = {
        speaker = "Jeth",
        text = {
            "'^7To help. And to warn you.'",
            "He lowers his voice, glancing at the workshop door.",
            "'^7That Holocron isn't just a teaching device. I've cross-",
            "referenced the containment protocols with Old Republic records.",
            "The locking mechanism, the cipher layers, the way it resists",
            "being opened...'",
            "'^7It's a PRISON. Something is trapped inside.'",
            "'^7Something conscious.'",
        },
        responses = {
            {
                label = "A prison? For what?",
                next = 7,
            },
            {
                label = "I already know. The voice calls itself Saevus.",
                next = 8,
                condition = function(g) return g.player.hasHolocron and g.player.holocronLessons > 0 end,
            },
            {
                label = "You're paranoid. It's just a data repository.",
                next = 9,
            },
        },
    },

    -- ============================================
    -- NODE 4: WIS check SUCCESS
    -- ============================================
    [4] = {
        speaker = "Jeth",
        text = {
            "He freezes. Then a slow, rueful nod.",
            "'^7You're perceptive. Yes. I'm terrified. And yes, I want",
            "to study it. Twenty years of theory -- and here's proof",
            "walking into my shop.'",
            "'^7But I've seen what happens to people who get too close",
            "to Sith artifacts. The Jedi Shadow who carried yours --",
            "Karath Vren. She's dead, isn't she?'",
        },
        responses = {
            {
                label = "She is. How did you know her name?",
                next = 5,
            },
            {
                label = "Tell me what you know about the Holocron.",
                next = 6,
            },
        },
    },

    -- ============================================
    -- NODE 5: The Jedi Shadow connection
    -- ============================================
    [5] = {
        speaker = "Jeth",
        text = {
            "'^7Karath Vren. Jedi Shadow -- their covert operatives.",
            "She came through Iziz six months ago asking about Sith",
            "containment theory. Brilliant woman. Careful. Patient.'",
            "'^7She said the Council had sent her to recover something",
            "dangerous. Something that had been lost for centuries.'",
            "'^7I gave her my research notes. She left for Dantooine.'",
            "He goes quiet. '^7And she never came back.'",
        },
        responses = {
            {
                label = "I found her body. She died protecting the Holocron.",
                next = 6,
                alignment = 2,
            },
            {
                label = "What did your research tell her?",
                next = 6,
            },
        },
    },

    -- ============================================
    -- NODE 6: The revelation — Holocron is a prison
    -- ============================================
    [6] = {
        speaker = "Jeth",
        text = {
            "He pulls a schematic from the pile and spreads it flat.",
            "'^7Look. Standard Sith Holocrons are knowledge repositories.",
            "Data storage. This one is different. See these containment",
            "layers? Nine cipher locks, recursive Force bindings,",
            "consciousness anchoring matrices...'",
            "",
            "'^7This isn't a library. It's a cage.'",
            "",
            "'^7The Holocron is a PRISON. Something conscious is trapped",
            "inside -- and it's been working to get out for centuries.",
            "Every whisper, every lesson, every moment of doubt it plants",
            "in your mind... it's picking the lock from the inside.'",
        },
        responses = {
            {
                label = "How do we stop it?",
                next = 10,
            },
            {
                label = "What happens if it gets out?",
                next = 11,
            },
            {
                label = "Maybe it should be freed.",
                next = 12,
                alignment = -5,
                condition = function(g) return g.player.paranoia > 40 end,
            },
        },
    },

    -- ============================================
    -- NODE 7: "A prison for what?"
    -- ============================================
    [7] = {
        speaker = "Jeth",
        text = {
            "'^7I don't know exactly. But the containment protocols match",
            "descriptions of Sith essence transfer -- a technique for",
            "binding a consciousness into an object after death.'",
            "'^7Whoever is in there was powerful enough that someone",
            "built a nine-layer cipher prison to hold them.'",
            "'^7And patient enough to wait centuries for a host.'",
        },
        responses = {
            {
                label = "A host? You mean... me?",
                next = 10,
            },
            {
                label = "How do I get rid of it?",
                next = 10,
            },
        },
    },

    -- ============================================
    -- NODE 8: Player already knows about Saevus
    -- ============================================
    [8] = {
        speaker = "Jeth",
        text = {
            "His face goes pale blue.",
            "'^7Saevus. You've been TALKING to it?'",
            "He grabs your arm. '^7How many lessons? How deep",
            "did you let it in?'",
            "'^7Every interaction weakens the cipher locks. The voice",
            "isn't teaching you -- it's using your connection to the",
            "Force as a crowbar.'",
        },
        responses = {
            {
                label = "Then help me seal it back up.",
                next = 10,
                alignment = 3,
            },
            {
                label = "Its lessons have made me stronger.",
                next = 12,
                alignment = -5,
            },
        },
    },

    -- ============================================
    -- NODE 9: Dismissive response
    -- ============================================
    [9] = {
        speaker = "Jeth",
        text = {
            "'^7That's what Karath Vren thought. For a while.'",
            "'^7Then the whispers started. Then the blackouts.",
            "Then she died clutching it on a crashed ship on Dantooine.'",
            "'^7Paranoid? Maybe. But I'm still alive.'",
        },
        responses = {
            {
                label = "...Fine. What do you suggest?",
                next = 10,
            },
            {
                label = "I can handle it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: The plan — Quest start
    -- ============================================
    [10] = {
        speaker = "Jeth",
        text = {
            "'^7I can analyze the Holocron's containment matrix.",
            "Map the cipher locks. Figure out what's really inside",
            "and how to keep it there.'",
            "",
            "'^7But I need components. The analysis requires power",
            "cells -- military-grade, high-capacity. Three of them.'",
            "'^7The thugs in the Lower Levels strip them from",
            "decommissioned droids. Rough crowd down there, but",
            "you look like you can handle yourself.'",
            "",
            "'^7Bring me three Power Cells. I'll do the rest.'",
        },
        effects = {
            startQuest = "holocron_unlock",
            setStage = { quest = "holocron_unlock", stage = "gather_cells" },
            action = function(player, game)
                -- Reset thug encounters so all 3 cells are available
                for _, roomId in ipairs({27, 29, 32}) do
                    if game.rooms[roomId] then
                        game.rooms[roomId].encounterDefeated = nil
                    end
                end
            end,
        },
        responses = {
            {
                label = "I'll get the Power Cells.",
                next = 20,
            },
            {
                label = "Why can't you get them yourself?",
                next = 13,
            },
        },
    },

    -- ============================================
    -- NODE 11: What happens if it gets out?
    -- ============================================
    [11] = {
        speaker = "Jeth",
        text = {
            "'^7Best case? A disembodied Sith Lord with centuries",
            "of accumulated rage floods into the Force, causing",
            "a psychic shockwave that kills everyone nearby.'",
            "'^7Worst case? It finds a host. Takes over a body.",
            "Walks out of here wearing someone's face.'",
            "He looks at you pointedly.",
            "'^7YOUR face. You're the one connected to it.'",
        },
        responses = {
            {
                label = "Then we need to stop it. What do you need?",
                next = 10,
            },
            {
                label = "How long do I have?",
                next = 14,
            },
        },
    },

    -- ============================================
    -- NODE 12: Dark side — maybe it should be freed
    -- ============================================
    [12] = {
        speaker = "Jeth",
        text = {
            "He steps back, genuine fear in his eyes.",
            "'^7That's the Holocron talking. Not you.'",
            "'^7Listen to yourself. You're rationalizing freeing a",
            "Sith Lord from a prison designed by the Jedi Council.",
            "That's exactly what it wants you to think.'",
            "'^7Please. Let me help you before it's too late.'",
        },
        responses = {
            {
                label = "...You might be right. What do you need?",
                next = 10,
                alignment = 3,
            },
            {
                label = "The Jedi imprisoned it out of fear, not justice.",
                next = -1,
                alignment = -3,
            },
        },
    },

    -- ============================================
    -- NODE 13: Why can't Jeth get them himself?
    -- ============================================
    [13] = {
        speaker = "Jeth",
        text = {
            "He holds up his hands -- slender Duros fingers,",
            "calloused from precision work, not combat.",
            "'^7I'm a mechanic, not a fighter. The Lower Levels",
            "are controlled by thugs who'd snap me in half for",
            "the credits in my pocket.'",
            "'^7You, on the other hand, arrived on Onderon carrying",
            "a Sith artifact and survived Dantooine. I think you",
            "can handle a few street toughs.'",
        },
        responses = {
            {
                label = "Fair point. I'll get the cells.",
                next = 20,
            },
        },
    },

    -- ============================================
    -- NODE 14: How long do I have?
    -- ============================================
    [14] = {
        speaker = "Jeth",
        text = {
            "'^7Hard to say. Depends on how many times you've",
            "interacted with it. Every lesson, every whisper,",
            "every moment you let it into your thoughts...'",
            "He checks a reading on his workbench.",
            "'^7The containment degradation is accelerating.",
            "Days. Maybe less.'",
            "'^7We need those Power Cells. Now.'",
        },
        effects = {
            startQuest = "holocron_unlock",
            setStage = { quest = "holocron_unlock", stage = "gather_cells" },
            action = function(player, game)
                -- Reset thug encounters so all 3 cells are available
                for _, roomId in ipairs({27, 29, 32}) do
                    if game.rooms[roomId] then
                        game.rooms[roomId].encounterDefeated = nil
                    end
                end
            end,
        },
        responses = {
            {
                label = "Then I'd better hurry.",
                next = 20,
            },
        },
    },

    -- ============================================
    -- NODE 20: Accepted — quest direction
    -- ============================================
    [20] = {
        speaker = "Jeth",
        text = {
            "'^7Good. The Lower Levels -- Sublevel 3. The thugs",
            "down there strip power cells from decommissioned",
            "droids and sell them on the black market.'",
            "'^7Three cells. Military-grade. Don't let them sell",
            "you civilian junk -- I need the real thing.'",
            "'^7And watch your back down there. Something else",
            "has been hunting in the Lower Levels. Something",
            "the thugs are scared of.'",
        },
        responses = {
            {
                label = "I'll be back with the cells. [Leave]",
                next = -1,
            },
            {
                label = "What's hunting down there?",
                next = 21,
            },
        },
    },

    -- ============================================
    -- NODE 21: Foreshadowing the Stalker
    -- ============================================
    [21] = {
        speaker = "Jeth",
        text = {
            "'^7I don't know. But three refugees were found dead",
            "this week. Throats torn out. Claw marks on the walls.'",
            "'^7The guards say it's an animal. The refugees say",
            "it has purple eyes.'",
            "He meets your gaze.",
            "'^7Purple. Like a Sith Holocron.'",
        },
        responses = {
            {
                label = "...I'll be careful. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Returning during gather_cells
    -- ============================================
    [30] = {
        speaker = "Jeth",
        text = function(g)
            local cells = RPG.Quest.GetVar(g, "holocron_unlock", "power_cells") or 0
            if cells >= 3 then
                return {
                    "Jeth looks up eagerly as you enter.",
                    "'^7You have them? All three? Let me see--'",
                    "He takes the cells, hands trembling with excitement.",
                    "'^7Yes. Military-grade. Perfect. Give me time to",
                    "set up the analysis. This is going to change everything.'",
                }
            else
                return {
                    "'^7You're back. How many cells do you have?'",
                    "'^7" .. cells .. " out of 3. Keep looking -- the thugs",
                    "in the Lower Levels and the Dark Alley should have more.'",
                    "'^7And hurry. I can feel the containment weakening.'",
                }
            end
        end,
        responses = function(g)
            local cells = RPG.Quest.GetVar(g, "holocron_unlock", "power_cells") or 0
            if cells >= 3 then
                return {
                    {
                        label = "What will the analysis tell us?",
                        next = 35,
                    },
                }
            else
                return {
                    {
                        label = "I'll keep looking. [Leave]",
                        next = -1,
                    },
                    {
                        label = "Where else can I find Power Cells?",
                        next = 31,
                    },
                }
            end
        end,
    },

    -- ============================================
    -- NODE 31: Where else to find cells
    -- ============================================
    [31] = {
        speaker = "Jeth",
        text = {
            "'^7The thugs in the Lower Levels and the Dark Alley",
            "are your best bet. They strip cells from decommissioned",
            "military droids.'",
            "'^7Defeat them and take what you need. They won't",
            "hand them over willingly.'",
        },
        responses = {
            {
                label = "Got it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 35: Cells delivered — next phase tease
    -- ============================================
    [35] = {
        speaker = "Jeth",
        text = {
            "'^7Everything. Who's inside. How many cipher locks",
            "remain. Whether the prison can be reinforced or if",
            "it's already too late.'",
            "'^7Go rest. Check on the city. I'll need time to",
            "calibrate the equipment.'",
            "",
            "'^7And... thank you. You could have ignored all this.",
            "Most people would have.'",
        },
        effects = {
            setStage = { quest = "holocron_unlock", stage = "analysis_pending" },
        },
        responses = {
            {
                label = "Just make sure it works. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 40: Analysis pending (waiting)
    -- ============================================
    [40] = {
        speaker = "Jeth",
        text = function(g)
            -- Check if analysis should be ready (Stalker has been activated
            -- or enough time passed via the_mimic quest progress)
            local stalker = g.stalker
            local mimicActive = RPG.Quest.IsActive(g, "the_mimic")
            if mimicActive or (stalker and stalker.stage >= 1) then
                return {
                    "Jeth looks up from his equipment, eyes wide.",
                    "'^7It's done. The analysis is complete.'",
                    "'^7And what I found... you need to hear this.'",
                }
            else
                return {
                    "'^7I'm still working on the analysis. The cipher",
                    "layers are more complex than I expected.'",
                    "'^7Be patient. And be careful -- the Holocron knows",
                    "we're trying to contain it.'",
                }
            end
        end,
        responses = function(g)
            local stalker = g.stalker
            local mimicActive = RPG.Quest.IsActive(g, "the_mimic")
            if mimicActive or (stalker and stalker.stage >= 1) then
                return {
                    {
                        label = "Tell me what you found.",
                        next = 60,
                        effects = {
                            setStage = { quest = "holocron_unlock", stage = "analysis_complete" },
                        },
                    },
                }
            else
                local opts = {
                    {
                        label = "Let me know when you're ready. [Leave]",
                        next = -1,
                    },
                    {
                        label = "Have you heard about something called the Stalker?",
                        next = 41,
                    },
                }
                if RPG.Quest.GetStage(g, "beast_rider_legacy") == "artifact_search"
                    and RPG.Quest.HasFlag(g, "q17_checkpoint_seen") then
                    table.insert(opts, 2, {
                        label = "I found records about a Beast Rider artifact...",
                        next = 96,
                    })
                end
                return opts
            end
        end,
    },

    -- ============================================
    -- NODE 41: Stalker discussion (early)
    -- ============================================
    [41] = {
        speaker = "Jeth",
        text = {
            "'^7The Stalker? The thing in the Lower Levels?'",
            "He sets down his tools.",
            "'^7I've heard the refugees' stories. A figure in Jedi",
            "robes. Empty eyes. Inhuman speed.'",
            "'^7If what they describe is real, it could be a Jedi",
            "Shadow -- corrupted by prolonged Holocron exposure.",
            "The same kind of operative who carried your artifact.'",
            "'^7The Shadow that's hunting you -- it's not Vren. There",
            "were others before her. The Council sent Shadows to study",
            "the prison over the centuries. Most came back. Some didn't.",
            "This one has been following the Holocron for a very long time.'",
            "'^7The Holocron doesn't just imprison. It corrupts.",
            "Whatever the Stalker was before, it belongs to the",
            "Holocron now.'",
        },
        responses = {
            {
                label = "Can it be stopped?",
                next = 42,
            },
            {
                label = "Focus on the analysis. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 42: Can the Stalker be stopped?
    -- ============================================
    [42] = {
        speaker = "Jeth",
        text = {
            "'^7Stopped? I doubt it. If it's been feeding on the",
            "Holocron's power for years, it's practically immortal.'",
            "'^7But you might be able to survive an encounter. Buy",
            "time. Outlast it. The Stalker hunts, but it retreats",
            "when its prey fights back long enough.'",
            "'^7If you can survive, it drops something -- a fragment",
            "of crystallized dark energy. I could analyze that.'",
        },
        responses = {
            {
                label = "I'll be ready. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 50: Quest complete
    -- ============================================
    [50] = {
        speaker = "Jeth",
        text = {
            "'^7The truth is out there now. What you do with it...",
            "that's beyond my expertise.'",
            "'^7I'll keep researching. If there's a way to",
            "reinforce the prison permanently, I'll find it.'",
            "'^7Watch yourself out there.'",
        },
        responses = {
            {
                label = "Thank you, Jeth. For everything. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 60: Analysis complete - the revelation
    -- ============================================
    [60] = {
        speaker = "Jeth",
        text = {
            "He pulls up a holographic display of the Holocron's",
            "internal structure. Layers of containment, like nested",
            "shells.",
            "'^7The prison has nine cipher locks. I've mapped them",
            "all. But here's what you need to know:'",
            "'^7Three locks are already broken. The voice inside --",
            "Saevus -- has been working on them since the Holocron",
            "was activated. Every lesson it teaches you weakens",
            "another lock.'",
            "'^7And there's a critical weakness in layer seven.",
            "Something from the outside is accelerating the decay.'",
            "'^7The Stalker. It's not just a corrupted Jedi. It's",
            "a tendril of Saevus's will, manifested through the",
            "cracks in the prison.'",
        },
        responses = {
            {
                label = "How do we reinforce the locks?",
                next = 61,
            },
            {
                label = "What happens if all nine locks break?",
                next = 62,
            },
        },
    },

    -- ============================================
    -- NODE 61: Reinforce the locks
    -- ============================================
    [61] = {
        speaker = "Jeth",
        text = {
            "'^7That's the problem. The locks are Force-bound. I'm",
            "a mechanic, not a Jedi. I can read the schematics but",
            "I can't manipulate the Force.'",
            "'^7You can. But first you need to survive an encounter",
            "with the Stalker. When it manifests physically, it",
            "creates a resonance gap -- a moment where the prison's",
            "defenses are exposed.'",
            "'^7Survive the Stalker. Get me the crystal fragment",
            "it drops. I can use that to map the remaining locks.'",
        },
        effects = {
            setStage = { quest = "holocron_unlock", stage = "stalker_survival" },
        },
        responses = {
            {
                label = "I'll face the Stalker.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 62: What if all locks break?
    -- ============================================
    [62] = {
        speaker = "Jeth",
        text = {
            "'^7Saevus walks free. In YOUR body.'",
            "'^7The consciousness anchoring matrices are designed to",
            "transfer into the nearest Force-sensitive host when the",
            "prison fails. That's you.'",
            "'^7You cease to exist. Saevus wears your face. With",
            "your connection to the Force and centuries of Sith",
            "knowledge.'",
            "He goes quiet.",
            "'^7And before you ask -- no, you can't just throw it away.",
            "When a Force-sensitive touches a consciousness anchor for",
            "too long, the anchor binds to them. A Force bond. Crude,",
            "parasitic, but unbreakable without the cipher.'",
            "'^7If you abandon it, the bond pulls you back. Or worse --",
            "it pulls Saevus toward another host, and without the",
            "cipher, no one can seal him.'",
            "'^7That cannot happen.'",
        },
        responses = {
            {
                label = "Then tell me what to do.",
                next = 61,
            },
        },
    },

    -- ============================================
    -- NODE 70: Stalker survival stage
    -- ============================================
    [70] = {
        speaker = "Jeth",
        text = {
            "'^7Have you faced the Stalker yet? I need that crystal",
            "fragment to proceed.'",
            "'^7Keep moving through the city. It tracks you through",
            "the Holocron's connection. Eventually, it'll find you.'",
            "'^7When it does -- survive. That's all you need to do.",
            "Five rounds. Hold out for five rounds and it'll retreat.'",
        },
        responses = {
            {
                label = "I'll keep moving. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 80: Cipher revealed
    -- ============================================
    [80] = {
        speaker = "Jeth",
        text = {
            "'^7You survived. And you brought the crystal.'",
            "He examines it under a scanner, hands trembling.",
            "'^7This is incredible. The crystal's lattice contains",
            "a partial cipher sequence. Combined with the fragments",
            "scattered across other artifacts...'",
            "'^7There's a nine-digit cipher encoded across the",
            "Holocron's connected artifacts. Objects that have been",
            "in proximity to the prison over the centuries.'",
            "'^7Find the artifacts. Decode the sequence. The cipher",
            "is the key to permanently sealing the prison.'",
            "'^7Or opening it. Depends on how it's entered.'",
        },
        responses = {
            {
                label = "Where are the cipher fragments?",
                next = 81,
            },
            {
                label = "I already have some. The datapad had two digits.",
                next = 82,
            },
        },
    },

    -- ============================================
    -- NODE 81: Cipher fragment locations
    -- ============================================
    [81] = {
        speaker = "Jeth",
        text = {
            "'^7My datapad has two digits: 4 and 9. The crystal",
            "fragment you recovered has one: 9.'",
            "'^7The remaining digits are scattered across artifacts",
            "connected to the Holocron's history. Security badges,",
            "data recordings, personal effects of people who got",
            "too close to it.'",
            "'^7Six digits remain. Find them. When you have all nine,",
            "the cipher is: the key to everything.'",
        },
        effects = {
            setStage = { quest = "holocron_unlock", stage = "complete" },
        },
        responses = {
            {
                label = "I'll find them. Thank you, Jeth.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 82: Already have some digits
    -- ============================================
    [82] = {
        speaker = "Jeth",
        text = {
            "'^7Good. You're ahead of me, then.'",
            "'^7My datapad fragments: 4, 9. The crystal: 9.",
            "If you've found more on artifacts in the city,",
            "you're building the sequence.'",
            "'^7Nine digits total. When you have them all...',",
            "he lowers his voice, '^7...you'll have the power to",
            "seal the prison forever. Or break it open.'",
            "'^7Choose wisely.'",
        },
        effects = {
            setStage = { quest = "holocron_unlock", stage = "complete" },
        },
        responses = {
            {
                label = "I know what I need to do. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 90: Nathema discussion (Q18)
    -- ============================================
    [90] = {
        speaker = "Jeth",
        text = function(g)
            local stage = RPG.Quest.GetStage(g, "nathema_echo")
            if stage == "void_touch" then
                return {
                    "'^7You look... shaken. What happened?'",
                    "You describe the episodes -- moments where the",
                    "Force simply vanishes. Total silence. Total emptiness.",
                    "Jeth's red eyes go wide.",
                    "'^7Nathema. You're describing Nathema.'",
                }
            elseif stage == "revan_connection" then
                return {
                    "'^7Revan knew. He went to stop it.'",
                    "'^7The journal fragment you found on Dantooine --",
                    "he was tracking this exact threat.'",
                }
            else
                return {
                    "'^7The Nathema episodes -- are they continuing?'",
                    "'^7I may have found more information.'",
                }
            end
        end,
        responses = function(g)
            local stage = RPG.Quest.GetStage(g, "nathema_echo")
            if stage == "void_touch" then
                return {
                    {
                        label = "Nathema? What's Nathema?",
                        next = 91,
                    },
                }
            elseif stage == "revan_connection" then
                return {
                    {
                        label = "Tell me about Revan and the Unknown Regions.",
                        next = 93,
                    },
                }
            else
                return {
                    {
                        label = "What did you find?",
                        next = 94,
                    },
                    {
                        label = "I'm managing. [Leave]",
                        next = -1,
                    },
                }
            end
        end,
    },

    -- ============================================
    -- NODE 91: What is Nathema?
    -- ============================================
    [91] = {
        speaker = "Jeth",
        text = {
            "'^7Nathema. An entire planet, consumed.'",
            "'^7Thousands of years ago, the Sith Emperor -- Vitiate",
            "-- performed a ritual that drained every living thing",
            "on the planet. Every person, every animal, every plant.",
            "Even the Force itself.'",
            "'^7The planet still exists. But it's dead. Not just",
            "lifeless -- dead in a way that goes deeper than biology.",
            "The Force cannot touch it. Cannot reach it.'",
            "'^7What you're experiencing -- those void episodes --",
            "is a fragment of that ritual. Stored in the Holocron.'",
        },
        effects = {
            setStage = { quest = "nathema_echo", stage = "seek_knowledge" },
        },
        responses = {
            {
                label = "The Holocron contains Vitiate's ritual?",
                next = 92,
            },
            {
                label = "Who was Vitiate?",
                next = 92,
            },
        },
    },

    -- ============================================
    -- NODE 92: Vitiate and Saevus connection
    -- ============================================
    [92] = {
        speaker = "Jeth",
        text = {
            "'^7Not the full ritual. A fragment. An echo.'",
            "'^7But here's the critical part: the consciousness",
            "trapped in your Holocron -- Saevus -- was Vitiate's",
            "student. He learned the Nathema ritual from the",
            "Emperor himself.'",
            "'^7The Jedi who imprisoned him thought he was just another",
            "Sith cultist obsessed with ancient power. They never broke",
            "enough of the cipher to learn what he really knew. He",
            "protected the Emperor's secret even from inside his prison.'",
            "'^7If Saevus escapes with that knowledge, he could perform",
            "the ritual again. On Onderon. On any world with enough",
            "living beings to fuel it.'",
            "'^7That's what Revan went to the Unknown Regions to",
            "prevent. And he never came back.'",
        },
        effects = {
            setStage = { quest = "nathema_echo", stage = "revan_connection" },
        },
        responses = {
            {
                label = "Revan knew about this?",
                next = 93,
            },
            {
                label = "How do I stop the void episodes?",
                next = 95,
            },
        },
    },

    -- ============================================
    -- NODE 93: Revan connection
    -- ============================================
    [93] = {
        speaker = "Jeth",
        text = {
            "'^7The journal fragment you found on Dantooine --",
            "\"something older than the Sith\" -- that was Vitiate.",
            "Revan went to confront him directly.'",
            "'^7Revan went alone. Years later, Meetra Surik -- the",
            "Jedi Exile -- followed him. She said she owed him that much.'",
            "'^7Neither of them returned. Two people, years apart,",
            "swallowed by the same darkness. And now a piece of it",
            "is in your hands.'",
        },
        effects = {
            setStage = { quest = "nathema_echo", stage = "choice" },
        },
        responses = {
            {
                label = "Then I need to make sure Saevus stays imprisoned.",
                next = 95,
                alignment = 3,
            },
            {
                label = "Or I could use the ritual myself.",
                next = 95,
                alignment = -5,
            },
        },
    },

    -- ============================================
    -- NODE 94: Additional Nathema info
    -- ============================================
    [94] = {
        speaker = "Jeth",
        text = {
            "'^7I cross-referenced the Holocron's energy signature",
            "with Old Republic military archives.'",
            "'^7The void episodes you experience -- they're not",
            "random. They happen when the Holocron is \"testing\"",
            "the prison walls. Each episode is a micro-fracture",
            "in the containment.'",
            "'^7Understanding the source gives you a measure of",
            "control. The episodes may never stop entirely, but",
            "knowing what they are makes them... survivable.'",
        },
        effects = {
            setStage = { quest = "nathema_echo", stage = "complete" },
        },
        responses = {
            {
                label = "Knowledge is power. Thank you, Jeth. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 95: Coping with the void
    -- ============================================
    [95] = {
        speaker = "Jeth",
        text = {
            "'^7The void episodes will continue as long as you carry",
            "the Holocron. But now you understand what they are.'",
            "'^7A fragment of Vitiate's ritual. A memory of a dead",
            "planet. Not a weakness -- a warning.'",
            "'^7The Exile survived by cutting herself off from the",
            "Force. You don't have that option. But you can endure.'",
            "'^7I believe in you. For whatever that's worth from a",
            "Duros mechanic with oil under his fingernails.'",
        },
        effects = {
            action = function(player, game)
                if not RPG.Quest.IsComplete(game, "nathema_echo") then
                    RPG.Quest.SetStage(player, "nathema_echo", "complete")
                end
            end,
        },
        responses = {
            {
                label = "It's worth a lot, Jeth. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 96: Q17 - Beast Rider artifact analysis
    -- ============================================
    [96] = {
        speaker = "Jeth",
        text = {
            "He sets down his tools, interested.",
            "'^7A Beast Rider talisman? Stolen from the Iziz archives?'",
            "'^7That's not just a relic. The Beast Riders bonded with",
            "drexls through those charms -- living conduits to the",
            "dark side of Dxun.'",
            "'^7Freedon Nadd corrupted the Beast Riders through exactly",
            "this kind of artifact. The dark side energy on Onderon",
            "predates your Holocron by centuries.'",
        },
        responses = {
            {
                label = "What's the connection to the Holocron?",
                next = 97,
            },
            {
                label = "So Onderon has always been like this?",
                next = 97,
            },
        },
    },

    -- ============================================
    -- NODE 97: Q17 - Dxun connection revealed
    -- ============================================
    [97] = {
        speaker = "Jeth",
        text = {
            "'^7Onderon and Dxun are a nexus. Dark side energy flows",
            "between them like a current. Freedon Nadd's tomb, the",
            "Beast Rider rituals, the Mandalorian Wars --'",
            "'^7Your Holocron didn't end up here by accident. Whatever",
            "is inside it chose this world because the dark side was",
            "already strong here. Centuries of corruption to feed on.'",
            "'^7Talk to Rila. She knows the Beast Rider lore better",
            "than anyone in the Merchant Quarter.'",
        },
        effects = {
            setStage = { quest = "beast_rider_legacy", stage = "dxun_connection" },
        },
        responses = {
            {
                label = "I'll talk to Rila. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODES 100-104: LIGHTSABER LENS FABRICATION
    -- ============================================

    -- NODE 100: Jeth notices the hilt
    [100] = {
        speaker = "Jeth",
        text = {
            "Jeth's eyes fix on the lightsaber hilt",
            "clipped to your belt.",
            "",
            "'That hilt. Where did you find that?'",
            "He reaches for it, stops himself.",
            "'The emitter matrix is intact but the focusing",
            "lens is shattered. I've seen this kind of damage",
            "before -- thermal stress from a crash landing.'",
        },
        responses = {
            { label = "It belonged to the Jedi Shadow. From the crash site.",
              next = 101 },
            { label = "Can you fix it?",
              next = 102 },
        },
    },

    -- NODE 101: Kira's hilt context
    [101] = {
        speaker = "Jeth",
        text = {
            "'The Shadow. Karath Vren. She carried Kira's hilt -- the one you're rebuilding.'",
            "He handles the hilt with unexpected reverence.",
            "'She came through here once, years ago.",
            "Before the crash. Asked me about Sith containment.",
            "I didn't know why at the time.'",
            "",
            "'The lens is custom -- Vandar-pattern. I can't",
            "replicate it exactly. But I can fabricate",
            "something compatible from salvaged ship optics.'",
        },
        responses = {
            { label = "You can make a new lens?",
              next = 102 },
        },
    },

    -- NODE 102: Lens fabrication
    [102] = {
        speaker = "Jeth",
        text = {
            "He rummages through a bin of precision components.",
            "Holds a curved piece of transparisteel to the light.",
            "",
            "'This'll work. Give me a moment.'",
            "",
            "His hands move with the certainty of someone who's",
            "done this a thousand times. Grinding, polishing,",
            "fitting. Three minutes of careful work.",
            "",
            "'There. The lens is ready. But I can't help with",
            "the rest. Crystal attunement is Force work.",
            "You'll need somewhere strong in the Force.'",
        },
        effects = {
            giveItem = 41,
            action = function(player, game)
                -- Only set flag + advance quest if lens was actually received
                if not RPG.Util.Contains(game.player.inventory, 41) then
                    player:SendPrint("^3Your inventory is full. Make room and return.")
                    return
                end
                RPG.Quest.SetFlag(game, "jeth_lens_given")
                local q = game.quests and game.quests["saber_construction"]
                if q and q.status == "active" then
                    local hasCrystal = RPG.Util.Contains(game.player.inventory, 5)
                        or RPG.Util.Contains(game.player.inventory, 6)
                    if hasCrystal then
                        RPG.Quest.SetStage(player, "saber_construction", "lens_acquired")
                    else
                        RPG.Quest.SetStage(player, "saber_construction", "lens_only")
                    end
                end
            end,
        },
        responses = {
            { label = "The Crystal Caves. The Jedi Chamber.",
              next = 103 },
            { label = "Thank you, Jeth.",
              next = -1 },
        },
    },

    -- NODE 103: Jeth's farewell
    [103] = {
        speaker = "Jeth",
        text = {
            "'The caves, yes. I've heard the old archives",
            "mention a meditation chamber deep inside.",
            "Padawans used it for crystal attunement.'",
            "",
            "'Be careful. Building a lightsaber opens",
            "you to the Force in ways you can't predict.",
            "And with that Holocron nearby...'",
            "He trails off. You both know what he means.",
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },

    -- NODE 104: Lens recovery (lost lens)
    [104] = {
        speaker = "Jeth",
        text = {
            "'You lost the lens?'",
            "He sighs. Reaches into the bin again.",
            "",
            "'Good thing I kept the template.'",
            "Another minute of grinding.",
            "'Try not to lose this one.'",
        },
        effects = {
            giveItem = 41,
            action = function(player, game)
                if not RPG.Util.Contains(game.player.inventory, 41) then
                    player:SendPrint("^3Your inventory is full. Make room and return.")
                end
            end,
        },
        responses = {
            { label = "[Leave]",
              next = -1 },
        },
    },
}
