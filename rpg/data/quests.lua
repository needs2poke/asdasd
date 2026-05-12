-- Echoes of the Dark Wars - Quest Definitions
-- Q0: Echoes of the Dark (Main Quest)
-- Q1: A Price on Khoonda (Exchange Pressure)
-- Q2-Q6 added in Phase 4

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Quests = {

    -- ============================================
    -- Q0: ECHOES OF THE DARK (Main Quest)
    -- ============================================
    echoes = {
        id = "echoes",
        name = "Echoes of the Dark",
        stageOrder = { "investigate", "search_ship", "found_holocron",
            "reported_truth", "kept_secret", "sold_holocron",
            "departure", "complete" },
        stages = {
            investigate = {
                journal = "A ship crashed near the Crystal Caves. Administrator Adare wants someone to investigate.",
                objectives = { "Travel to the crash site north of Khoonda." },
            },
            search_ship = {
                journal = "I've reached the crash site. The ship's main hold is open. Something dark waits inside.",
                objectives = { "Search the crashed ship's main hold." },
            },
            found_holocron = {
                journal = "Inside the wreck, I found a dead Jedi Shadow and a Sith Holocron. Its whispers fill my mind.",
                objectives = {
                    "Decide what to do with the Holocron.",
                    "Report to Administrator Adare.",
                },
            },
            reported_truth = {
                journal = "I told Adare about the Holocron. She's organizing a Republic response.",
                objectives = { "Prepare to leave Dantooine." },
                effects = { alignment = 10 },
            },
            kept_secret = {
                journal = "I kept the Holocron's existence secret. Its whispers grow louder.",
                objectives = { "Find a way off Dantooine." },
                effects = { alignment = -10, paranoia = 15 },
            },
            sold_holocron = {
                journal = "I brokered a deal with the Exchange. Credits in hand, guilt in my gut.",
                objectives = { "Find a way off Dantooine." },
                effects = { alignment = -5 },
            },
            departure = {
                journal = "The Wanderer is prepped. Time to leave Dantooine behind.",
                objectives = { "Board The Wanderer." },
            },
            complete = {
                journal = "I've left Dantooine. The Holocron's shadow follows me into the stars.",
                status = "completed",
                rewards = { xp = 500, credits = 100 },
            },
        },
        events = {
            -- Entering the crash site advances from investigate -> search_ship
            {
                type = "room_enter",
                payload = { roomId = 5 },
                stage = "investigate",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes", "search_ship")
                end,
            },
            -- Picking up the Holocron advances from search_ship -> found_holocron
            {
                type = "item_pickup",
                payload = { itemId = 2 },
                stage = "search_ship",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes", "found_holocron")
                end,
            },
        },
    },

    -- ============================================
    -- Q1: A PRICE ON KHOONDA (Exchange Pressure)
    -- ============================================
    exchange_pressure = {
        id = "exchange_pressure",
        name = "A Price on Khoonda",
        stageOrder = { "extortion", "investigate", "resolved_peaceful",
            "betrayed_goran", "paid_debt", "complete" },
        stages = {
            extortion = {
                journal = "Merchant Goran is being squeezed by the Exchange for 'protection' credits. He can't pay.",
                objectives = { "Talk to Goran about the Exchange problem." },
            },
            investigate = {
                journal = "The Exchange wants 50% of Goran's salvage profits. I need to deal with Draxen.",
                objectives = {
                    "Confront Draxen in the Dantooine Fields.",
                    "Or find another solution.",
                },
            },
            resolved_peaceful = {
                journal = "I convinced Draxen to back off. Goran is safe, but the Exchange remembers.",
                objectives = { "Return to Goran with the news." },
                effects = { alignment = 5 },
            },
            betrayed_goran = {
                journal = "I sided with the Exchange against Goran. The credits were good. The shame... less so.",
                objectives = { "Collect your cut from Draxen." },
                effects = { alignment = -10 },
            },
            paid_debt = {
                journal = "I paid Goran's debt out of my own pocket. He's grateful. The Exchange thinks I'm soft.",
                objectives = { "Tell Goran his debt is paid." },
                effects = { alignment = 3 },
            },
            complete = {
                journal = "The Exchange situation is resolved. For now.",
                status = "completed",
                rewards = { xp = 300, credits = 50 },
                effects = { grantAbility = "marked_for_death" },
            },
        },
        events = {},
    },

    -- ============================================
    -- Q2: FIELD MEDICINE
    -- ============================================
    field_medicine = {
        id = "field_medicine",
        name = "Field Medicine",
        stageOrder = { "supplies_needed", "gathering", "dealing", "delivered", "complete" },
        events = {
            -- Reaching Deep Crystal Caves on gathering path sets cave kolto flag
            {
                type = "room_enter",
                payload = { roomId = 8 },
                stage = "gathering",
                action = function(player, game)
                    if not RPG.Quest.HasFlag(game, "has_cave_kolto") then
                        RPG.Quest.SetFlag(game, "has_cave_kolto")
                        player:SendPrint("^2[Found natural kolto deposits in the cave walls.]")
                    end
                end,
            },
        },
        stages = {
            supplies_needed = {
                journal = "Doctor Vara is running out of kolto. Two sources: Crystal Caves or the Exchange.",
                objectives = {
                    "Find kolto in the Crystal Caves (Room 8).",
                    "Or negotiate with Draxen for supplies.",
                },
            },
            gathering = {
                journal = "I'm heading to the Crystal Caves to find natural kolto deposits.",
                objectives = { "Retrieve kolto from the Deep Crystal Caves." },
            },
            dealing = {
                journal = "I'm negotiating with the Exchange for stolen medical supplies.",
                objectives = { "Acquire kolto from Draxen." },
            },
            delivered = {
                journal = "I've returned the kolto to Doctor Vara.",
                objectives = { "Speak with Vara about the supplies." },
                effects = { alignment = 3 },
            },
            complete = {
                journal = "The medical bay is restocked. Vara is grateful.",
                status = "completed",
                rewards = { xp = 250, credits = 30 },
                effects = { grantAbility = "exploit_weakness", boostStat = { stat = "CON", amount = 1, message = "^2Vara's lessons taught you where your body's limits really are. ^5+1 Constitution.^7" } },
            },
        },
    },

    -- ============================================
    -- Q3: THE SHADOW'S TRAIL
    -- ============================================
    shadows_trail = {
        id = "shadows_trail",
        name = "The Shadow's Trail",
        stageOrder = { "decrypt", "enclave_search", "decoded", "complete" },
        stages = {
            decrypt = {
                journal = "Archivist Tamas can partially read the Jedi Shadow's datapad, but needs a cipher key from the Enclave sublevel.",
                objectives = { "Search the Sublevel for the cipher key." },
            },
            enclave_search = {
                journal = "The Enclave sublevel is unstable and crawling with malfunctioning droids. The cipher key should be near the old archive stacks.",
                objectives = { "Find the cipher key in the sublevel." },
                effects = { xp = 50 },
            },
            decoded = {
                journal = "The Shadow's datapad reveals coordinates to a hidden Sith academy in the Unknown Regions. Karath Vren died bringing this intelligence home.",
                objectives = { "Report, keep, or destroy the coordinates." },
            },
            complete = {
                journal = "The Shadow's trail has reached its end. What happens next depends on who holds the coordinates.",
                status = "completed",
                rewards = { xp = 400, credits = 50 },
                effects = { boostStat = { stat = "WIS", amount = 1, message = "^2Decoding the Shadow's datapad changed how you see the world. ^5+1 Wisdom.^7" } },
            },
        },
        events = {
            {
                type = "room_enter",
                payload = { roomId = 15 },
                stage = "decrypt",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "shadows_trail", "enclave_search")
                end,
            },
        },
    },

    -- ============================================
    -- Q4: GHOSTS OF THE ENCLAVE (Holocron Temptation)
    -- ============================================
    ghosts_enclave = {
        id = "ghosts_enclave",
        name = "Ghosts of the Enclave",
        stageOrder = { "whispers", "three_lessons", "confrontation", "complete" },
        stages = {
            whispers = {
                journal = "The Sith Holocron has activated. A voice - Darth Saevus - offers knowledge.",
                objectives = { "Choose to accept or reject Saevus's lessons." },
            },
            three_lessons = {
                journal = "After three interactions, the Holocron reveals Saevus is rebuilding through my connection to the Force.",
                objectives = { "Confront the truth of the Holocron." },
            },
            confrontation = {
                journal = "I must decide: destroy the Holocron or embrace its power.",
                objectives = { "Find a way to destroy the Holocron, or accept it." },
            },
            complete = {
                journal = "The Holocron's fate is decided. Its shadow remains.",
                status = "completed",
                rewards = { xp = 500 },
            },
        },
        events = {},
    },

    -- ============================================
    -- Q5: ATTON'S GAMBIT (Companion Trust)
    -- ============================================
    atton_gambit = {
        id = "atton_gambit",
        name = "Atton's Gambit",
        stageOrder = { "small_talk", "trust_building", "confrontation", "rejected", "complete" },
        stages = {
            small_talk = {
                journal = "Atton Rand knows more about Sith artifacts than a freelance pilot should.",
                objectives = { "Learn more about Atton's past." },
            },
            trust_building = {
                journal = "Atton wants me to prove myself before he opens up. Help people in the settlement.",
                objectives = {
                    "Complete quests to earn Atton's trust.",
                    "Return to Atton when ready.",
                },
            },
            confrontation = {
                journal = "Atton is ready to talk. His secret is worse than I imagined.",
                objectives = { "Decide Atton's fate." },
            },
            rejected = {
                journal = "I refused Atton's offer. He won't ask again.",
                status = "failed",
            },
            complete = {
                journal = "Atton's truth is out. What happens next depends on my choice.",
                status = "completed",
                rewards = { xp = 350 },
            },
        },
        events = {
            -- After completing 2 quests, mark Atton ready for confrontation
            -- This is checked in dialogue routing instead (flag-based)
        },
    },

    -- ============================================
    -- Q6: THE LAW OF KHOONDA (Captain Zherron)
    -- ============================================
    law_khoonda = {
        id = "law_khoonda",
        name = "The Law of Khoonda",
        stageOrder = { "report_in", "kinrath_task", "suspicion", "resolution", "complete" },
        stages = {
            report_in = {
                journal = "Captain Zherron needs help with kinrath nest clearance and perimeter defense.",
                objectives = { "Clear kinrath along the path to the Crystal Caves." },
            },
            kinrath_task = {
                journal = "Zherron asked me to clear the kinrath nests threatening the settlement.",
                objectives = { "Defeat kinrath along the cave path." },
            },
            suspicion = {
                journal = "Zherron confides that he suspects Adare is a former Jedi hiding her past.",
                objectives = { "Investigate Adare's background, or refuse." },
            },
            resolution = {
                journal = "My choice about Zherron's suspicion will affect the Adare-Zherron dynamic.",
                objectives = { "Speak to Zherron with your decision." },
            },
            complete = {
                journal = "The militia situation is resolved.",
                status = "completed",
                rewards = { xp = 300, credits = 40 },
                effects = { grantAbility = "rally", boostStat = { stat = "STR", amount = 1, message = "^2Zherron's drills left their mark. You're harder to break now. ^5+1 Strength.^7" } },
            },
        },
        events = {
            -- Defeating kinrath on cave path advances kinrath_task
            {
                type = "combat_win",
                payload = { enemyId = 0 },
                stage = "kinrath_task",
                action = function(player, game)
                    local kills = (RPG.Quest.GetVar(game, "law_khoonda", "kinrath_kills") or 0) + 1
                    RPG.Quest.SetVar(player, "law_khoonda", "kinrath_kills", kills)
                    if kills >= 2 then
                        RPG.Quest.SetStage(player, "law_khoonda", "suspicion")
                    end
                end,
            },
            {
                type = "combat_win",
                payload = { enemyId = 1 },
                stage = "kinrath_task",
                action = function(player, game)
                    local kills = (RPG.Quest.GetVar(game, "law_khoonda", "kinrath_kills") or 0) + 1
                    RPG.Quest.SetVar(player, "law_khoonda", "kinrath_kills", kills)
                    if kills >= 2 then
                        RPG.Quest.SetStage(player, "law_khoonda", "suspicion")
                    end
                end,
            },
        },
    },

    -- ============================================
    -- Q15: UNLOCKING THE HOLOCRON (Act 2 Main Quest)
    -- ============================================
    holocron_unlock = {
        id = "holocron_unlock",
        name = "Unlocking the Holocron",
        stageOrder = { "speak_jeth", "gather_cells", "analysis_pending",
            "analysis_complete", "stalker_survival", "cipher_revealed", "complete" },
        stages = {
            speak_jeth = {
                journal = "A Duros mechanic named Jeth claims the Holocron is a prison, not a teaching device. He says he can analyze it -- but needs military-grade Power Cells first.",
                objectives = { "Speak with Jeth in his workshop (Room 33)." },
            },
            gather_cells = {
                journal = "Jeth needs 3 military-grade Power Cells to power his Holocron analysis equipment. The thugs in the Lower Levels and Dark Alley strip them from decommissioned droids.",
                objectives = {
                    "Gather 3 Power Cells from Onderon Thugs.",
                    "Return to Jeth with the cells.",
                },
            },
            analysis_pending = {
                journal = "Jeth has the Power Cells and is analyzing the Holocron's containment matrix. He warned you to be careful -- the Holocron knows you're trying to contain it.",
                objectives = { "Wait for Jeth to complete his analysis." },
            },
            analysis_complete = {
                journal = "Jeth's analysis is done. The Holocron's prison has a critical weakness -- and something in the Lower Levels has noticed your attempts to contain it.",
                objectives = { "Speak with Jeth about the results." },
            },
            stalker_survival = {
                journal = "The Stalker -- a Jedi Shadow corrupted by the Holocron's influence -- is hunting you. You must survive an encounter with it before Jeth can proceed.",
                objectives = { "Survive an encounter with the Stalker." },
            },
            cipher_revealed = {
                journal = "You survived the Stalker. Jeth has identified a 9-digit cipher embedded across artifacts connected to the Holocron. The cipher is the key to permanently sealing -- or opening -- the prison.",
                objectives = { "Speak with Jeth about the cipher." },
            },
            complete = {
                journal = "The Holocron's secrets are laid bare. The cipher, the prison, the Stalker -- all connected. What happens next depends on what you do with the truth.",
                status = "completed",
                rewards = { xp = 750, credits = 100 },
            },
        },
        events = {
            -- Defeating Onderon Thugs during gather_cells increments power_cells
            {
                type = "combat_win",
                payload = { enemyId = 6 },
                stage = "gather_cells",
                action = function(player, game)
                    local cells = (RPG.Quest.GetVar(game, "holocron_unlock", "power_cells") or 0) + 1
                    RPG.Quest.SetVar(player, "holocron_unlock", "power_cells", cells)
                    if cells < 3 then
                        player:SendPrint("^2[Power Cell recovered: " .. cells .. "/3]")
                    else
                        player:SendPrint("^2[Power Cell recovered: 3/3]")
                        player:SendPrint("^3Return to Jeth with the Power Cells.")
                    end
                end,
            },
        },
    },

    -- ============================================
    -- Q16: THE MIMIC (Act 2 Murder Mystery)
    -- ============================================
    the_mimic = {
        id = "the_mimic",
        name = "The Mimic",
        stageOrder = { "speak_venn", "investigate_alley", "investigate_trace",
            "investigate_footage", "confront_truth", "hunt_mimic", "complete" },
        stages = {
            speak_venn = {
                journal = "Doctor Venn has shown me drawings from a catatonic patient -- a figure in robes with glowing purple eyes. That figure looks exactly like me.",
                objectives = { "Investigate the Dark Alley where the attacks occurred." },
            },
            investigate_alley = {
                journal = "The Dark Alley. Fresh blood on the permacrete, and a shimmer of purple light that vanishes when I look directly at it. Something was here. Something wearing my face.",
                objectives = {
                    "Search for evidence in the Dark Alley.",
                    "Follow the trail to the Lower Levels.",
                },
            },
            investigate_trace = {
                journal = "In the Lower Levels, I saw myself at the far end of a tunnel. Standing perfectly still. Watching. Then it was gone. The Holocron's creating copies of me -- projections, echoes, something worse.",
                objectives = { "Report findings to Captain Saren at the Security Checkpoint." },
            },
            investigate_footage = {
                journal = "Captain Saren has security footage showing two identical figures -- one with purple eyes. The footage proves I'm not the killer. But what IS?",
                objectives = { "Analyze the footage with Saren." },
            },
            confront_truth = {
                journal = "The Mimic is a projection of the Holocron's consciousness -- a twisted echo of me, given form by the artifact's power. It feeds on proximity. I need to destroy it.",
                objectives = { "Hunt down the Mimic in the Lower Levels." },
            },
            hunt_mimic = {
                journal = "The Mimic is somewhere in the Lower Levels. It knows I'm coming. It looks like me, fights like me, thinks like me. The difference: it has no restraint.",
                objectives = { "Defeat the Mimic." },
            },
            complete = {
                journal = "The Mimic is destroyed. The murders have stopped. But the Holocron that created it is still in my hands -- and now it knows I can fight back.",
                status = "completed",
                rewards = { xp = 600 },
            },
        },
        events = {
            -- Room 29 enter during investigate_alley: blood + purple shimmer
            {
                type = "room_enter",
                payload = { roomId = 29 },
                stage = "investigate_alley",
                action = function(player, game)
                    if not RPG.Quest.HasFlag(game, "mimic_alley_searched") then
                        RPG.Quest.SetFlag(game, "mimic_alley_searched")
                        player:SendPrint("")
                        player:SendPrint("^1Fresh blood on the permacrete. Still wet.")
                        player:SendPrint("^1A shimmer of purple light dances at the alley's edge --")
                        player:SendPrint("^1then vanishes when you look directly at it.")
                        player:SendPrint("^3[The trail leads toward the Lower Levels.]")
                        player:SendPrint("")
                        RPG.AddParanoia(player, 5)
                        RPG.Quest.SetStage(player, "the_mimic", "investigate_trace")
                    end
                end,
            },
            -- Room 32 enter during investigate_trace: see yourself
            {
                type = "room_enter",
                payload = { roomId = 32 },
                stage = "investigate_trace",
                action = function(player, game)
                    if not RPG.Quest.HasFlag(game, "mimic_trace_seen") then
                        RPG.Quest.SetFlag(game, "mimic_trace_seen")
                        player:SendPrint("")
                        player:SendPrint("^1At the far end of the tunnel, a figure stands motionless.")
                        player:SendPrint("^1Your robes. Your posture. Your face.")
                        player:SendPrint("^1Its eyes glow purple. It tilts its head.")
                        player:SendPrint("^1Then it steps backward into the shadow and is gone.")
                        player:SendPrint("")
                        RPG.AddParanoia(player, 8)
                    end
                end,
            },
            -- Room 32 enter during hunt_mimic: Mimic encounter
            {
                type = "room_enter",
                payload = { roomId = 32 },
                stage = "hunt_mimic",
                action = function(player, game)
                    if not RPG.Quest.HasFlag(game, "mimic_combat_started") then
                        RPG.Quest.SetFlag(game, "mimic_combat_started")
                        player:SendPrint("")
                        player:SendPrint("^1A figure steps from the drainage canal.")
                        player:SendPrint("^1Your robes. Your face. Your weapons.")
                        player:SendPrint("^1It smiles with your mouth.")
                        player:SendPrint("^1'^7Hello, me.^1'")
                        player:SendPrint("")
                        if RPG.Combat and RPG.Combat.StartCombat then
                            RPG.Combat.StartCombat(player, 13)
                        end
                    end
                end,
            },
            -- Combat win vs enemy 13 during hunt_mimic: quest complete
            {
                type = "combat_win",
                payload = { enemyId = 13 },
                stage = "hunt_mimic",
                action = function(player, game)
                    player:SendPrint("")
                    player:SendPrint("^2The Mimic shudders, its form flickering.")
                    player:SendPrint("^2Your own face stares back at you -- then dissolves")
                    player:SendPrint("^2into purple mist that sinks into the floor.")
                    player:SendPrint("^2The Holocron goes cold against your chest.")
                    player:SendPrint("")
                    RPG.Quest.SetStage(player, "the_mimic", "complete")
                end,
            },
            -- Flee from Mimic during hunt_mimic: clear flag so combat can re-trigger
            {
                type = "combat_fled",
                payload = { enemyId = 13 },
                stage = "hunt_mimic",
                action = function(player, game)
                    RPG.Quest.ClearFlag(game, "mimic_combat_started")
                    player:SendPrint("^3The Mimic dissolves into shadow as you retreat.")
                    player:SendPrint("^3It will re-manifest when you return to the Lower Levels.")
                end,
            },
        },
    },

    -- ============================================
    -- Q17: BEAST RIDER'S LEGACY (Onderon Lore)
    -- ============================================
    beast_rider_legacy = {
        id = "beast_rider_legacy",
        name = "Beast Rider's Legacy",
        stageOrder = { "rumor", "artifact_search", "dxun_connection", "complete" },
        events = {
            -- Room 31 (Security Checkpoint) during rumor: advance to artifact_search
            {
                type = "room_enter",
                payload = { roomId = 31 },
                stage = "rumor",
                action = function(player, game)
                    if RPG.Quest.HasFlag(game, "q17_checkpoint_seen") then return end
                    RPG.Quest.SetFlag(game, "q17_checkpoint_seen")
                    RPG.Quest.SetStage(player, "beast_rider_legacy", "artifact_search")
                    player:SendPrint("^3The Security Checkpoint has records of the artifact theft.")
                    player:SendPrint("^3Captain Saren's logs mention a stolen charm --")
                    player:SendPrint("^3a Mandalorian-era Beast Rider talisman, taken from the Museum.")
                end,
            },
        },
        stages = {
            rumor = {
                journal = "Rila mentioned that the murder victims were all researching Jedi records -- specifically records about the Beast Riders of Onderon and their connection to Freedon Nadd.",
                objectives = { "Search for the stolen Beast Rider artifact." },
            },
            artifact_search = {
                journal = "A Mandalorian-era charm was stolen from the Iziz archives. It belonged to the Beast Riders -- a talisman used to bond with drexls. Whoever took it may be connected to the murders.",
                objectives = {
                    "Investigate the theft at the Security Checkpoint.",
                    "Ask Jeth about the artifact's significance.",
                },
            },
            dxun_connection = {
                journal = "The charm links Onderon's Beast Riders to Freedon Nadd's tomb on Dxun. The dark side corruption on Onderon predates the Holocron by centuries. This world has always been a battleground.",
                objectives = { "Learn about the Dxun connection from Rila or Jeth." },
            },
            complete = {
                journal = "The Beast Rider's legacy is clearer now. Onderon's history of dark side corruption makes it the perfect hunting ground for whatever is inside the Holocron.",
                status = "completed",
                rewards = { xp = 400, credits = 75 },
            },
        },
    },

    -- ============================================
    -- Q18: NATHEMA'S ECHO (Karpyshyn Novel Deep Lore)
    -- ============================================
    nathema_echo = {
        id = "nathema_echo",
        name = "Nathema's Echo",
        stageOrder = { "void_touch", "seek_knowledge", "revan_connection", "choice", "complete" },
        stages = {
            void_touch = {
                journal = "Something is wrong with the Force around me. Moments of absolute silence -- no connection, no presence, nothing. Like the Force itself has been ripped away. The episodes are getting worse.",
                objectives = { "Seek answers about the Force-absence episodes." },
            },
            seek_knowledge = {
                journal = "Jeth believes the Holocron contains a fragment of an ancient ritual -- one powerful enough to consume an entire planet's connection to the Force. The Sith Emperor Vitiate performed this ritual on a world called Nathema.",
                objectives = { "Learn more about Nathema and the ritual." },
            },
            revan_connection = {
                journal = "Revan went to the Unknown Regions to confront this threat. He never returned. The journal fragment I found on Dantooine confirms it -- 'something older than the Sith' waits beyond known space. Saevus was Vitiate's student.",
                objectives = { "Confront the truth about the Holocron's origin." },
            },
            choice = {
                journal = "The Holocron's prisoner isn't just any Sith Lord. It's a student of Vitiate himself -- someone who learned the ritual that devoured Nathema. If it escapes, it could do the same to Onderon. Or worse.",
                objectives = { "Decide what to do with this knowledge." },
            },
            complete = {
                journal = "The echo of Nathema has been acknowledged. The void episodes may never fully stop -- but understanding their source gives you a measure of control.",
                status = "completed",
                rewards = { xp = 500 },
            },
        },
        events = {},
    },
    -- ============================================
    -- Q23: THE SHADOW'S TRUTH (Act 3-4 Side Quest)
    -- ============================================
    shadows_truth_act3 = {
        id = "shadows_truth_act3",
        name = "The Shadow's Truth",
        stageOrder = { "investigate", "lab_logs", "compare_memories",
            "accepted", "denied", "complete" },
        stages = {
            investigate = {
                journal = "The Echo of Karath Vren appeared in the Memory Corridor. The dead Jedi Shadow has something to tell me about the Holocron's origins.",
                objectives = { "Speak with Karath Vren's ghost." },
            },
            lab_logs = {
                journal = "Karath Vren revealed that Sith dissenters built the Holocron prison to contain Saevus. The cipher fragments are connected to their code.",
                objectives = { "Learn more from Karath Vren's echo." },
            },
            compare_memories = {
                journal = "The encrypted sections of Karath Vren's datapad contained names of the Sith faction that built the prison. The cipher is their work.",
                objectives = { "Consider the implications." },
                effects = { xp = 100 },
            },
            accepted = {
                journal = "I've accepted the truth about the Holocron's origins. The Sith who built the prison gave their lives to contain Saevus.",
                objectives = {},
                effects = { xp = 150 },
            },
            denied = {
                journal = "I'm not sure what to make of Karath Vren's revelations.",
                objectives = {},
            },
            complete = {
                journal = "The Shadow's truth is known. The Holocron's history stretches back to Vitiate himself.",
                status = "completed",
                rewards = { xp = 400 },
            },
        },
        events = {
            -- Room 44 enter during investigate: advance to lab_logs
            {
                type = "room_enter",
                payload = { roomId = 44 },
                stage = "investigate",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "shadows_truth_act3", "lab_logs")
                end,
            },
        },
    },

    -- ============================================
    -- Q24: FORGOTTEN MEMORIES (Act 3 Side Quest)
    -- ============================================
    forgotten_memories = {
        id = "forgotten_memories",
        name = "Forgotten Memories",
        stageOrder = { "noticed", "investigate", "recovered",
            "embraced_forgetting", "complete" },
        stages = {
            noticed = {
                journal = "The tomb loop has shaken loose memories I'd buried. Fragments of a past I thought I'd left behind on Dantooine.",
                objectives = { "Investigate the recovered memories." },
            },
            investigate = {
                journal = "The tomb's architecture is designed to strip away layers of self-deception. Each loop peels back another memory.",
                objectives = { "Speak with the Tomb Guardian inscription for guidance." },
            },
            recovered = {
                journal = "I've recovered the buried memories. They hurt, but they're mine. Denying them only made the tomb's grip stronger.",
                objectives = {},
                effects = { xp = 100 },
            },
            embraced_forgetting = {
                journal = "Some memories are better left buried. The tomb seems to agree — its grip has loosened.",
                objectives = {},
            },
            complete = {
                journal = "The forgotten memories have been addressed. Whether recovered or re-buried, they no longer haunt me.",
                status = "completed",
                rewards = { xp = 300 },
            },
        },
        events = {},
    },

    -- ============================================
    -- Q22: ECHOES FINAL (Act 5 Main)
    -- ============================================
    echoes_final = {
        id = "echoes_final",
        name = "The Final Echo",
        stageOrder = { "approach", "cipher_chamber", "cipher_solved",
            "cipher_skipped", "choice_made", "complete" },
        stages = {
            approach = {
                journal = "I've reached the Hidden Entrance — the gateway to the endgame. Saevus's manifestation awaits.",
                objectives = { "Speak with the Saevus Manifestation." },
            },
            cipher_chamber = {
                journal = "The cipher chamber lies ahead. Nine digits stand between me and the truth about the Holocron's prison.",
                objectives = { "Enter the Cipher Chamber and solve the code." },
            },
            cipher_solved = {
                journal = "The cipher is solved. The prison seal activates. The path to the Chamber of Final Choice is clear.",
                objectives = { "Enter the Chamber of Final Choice." },
                effects = { xp = 300 },
            },
            cipher_skipped = {
                journal = "I accepted Saevus's dark bargain. The cipher is irrelevant. The dark path is open.",
                objectives = { "Enter the Chamber of Final Choice." },
            },
            choice_made = {
                journal = "I've reached the Chamber of Final Choice. Four endings await. The journey ends here.",
                objectives = { "Choose your ending." },
            },
            complete = {
                journal = "The journey is over. The echo fades.",
                status = "completed",
                rewards = { xp = 1000 },
            },
        },
        events = {
            -- Entering cipher chamber
            {
                type = "room_enter",
                payload = { roomId = 49 },
                stage = "cipher_chamber",
                action = function(player, game)
                    -- Stage advance handled by cipher solve callback
                end,
            },
            -- Entering Chamber of Final Choice
            {
                type = "room_enter",
                payload = { roomId = 50 },
                stage = "cipher_solved",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes_final", "choice_made")
                end,
            },
            {
                type = "room_enter",
                payload = { roomId = 50 },
                stage = "cipher_skipped",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes_final", "choice_made")
                end,
            },
            -- Entering any ending room completes the quest
            {
                type = "room_enter",
                payload = { roomId = 51 },
                stage = "choice_made",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes_final", "complete")
                end,
            },
            {
                type = "room_enter",
                payload = { roomId = 52 },
                stage = "choice_made",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes_final", "complete")
                end,
            },
            {
                type = "room_enter",
                payload = { roomId = 53 },
                stage = "choice_made",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes_final", "complete")
                end,
            },
            {
                type = "room_enter",
                payload = { roomId = 54 },
                stage = "choice_made",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "echoes_final", "complete")
                end,
            },
        },
    },

    -- ============================================
    -- Q19: ECHOES OF METACOGNITION (Act 4)
    -- ============================================
    echoes_metacognition = {
        id = "echoes_metacognition",
        name = "Echoes of Metacognition",
        stageOrder = { "awareness", "questioning", "accepted", "denied", "complete" },
        stages = {
            awareness = {
                journal = "Something in the Fragment Arena is watching me. Not a creature — an awareness. The paranoia is high enough that I can perceive it.",
                objectives = { "Speak with The Watcher." },
            },
            questioning = {
                journal = "The Watcher asks questions about free will, agency, and the nature of choice. Its questions are uncomfortably specific.",
                objectives = { "Consider The Watcher's question." },
            },
            accepted = {
                journal = "I accepted that my choices matter regardless of constraints. The Watcher seemed... satisfied. The paranoia has eased.",
                objectives = {},
                effects = { xp = 200 },
                status = "completed",
                rewards = { xp = 500 },
            },
            denied = {
                journal = "I rejected The Watcher's question. The paranoia lingers. Some questions don't have comfortable answers.",
                objectives = {},
                effects = { xp = 100 },
                status = "completed",
                rewards = { xp = 500 },
            },
            complete = {
                journal = "The encounter with The Watcher is over. Its questions remain.",
                status = "completed",
                rewards = { xp = 500 },
            },
        },
        events = {},
    },

    -- ============================================
    -- Q20: ESCAPE THE LOOP (Act 3 Main)
    -- ============================================
    escape_loop = {
        id = "escape_loop",
        name = "Escape the Loop",
        stageOrder = { "enter_tomb", "trapped", "seeking_escape",
            "escaped_wisdom", "escaped_strength",
            "confront_shadow", "complete" },
        stages = {
            enter_tomb = {
                journal = "I've entered the Sith tomb on Dxun. The Holocron is pulling me deeper.",
                objectives = { "Explore the tomb." },
            },
            trapped = {
                journal = "The tomb is looping. Every time I try to reach the Inner Sanctum, I'm sent back to the entrance. Something is wrong with the geometry.",
                objectives = {
                    "Find a way to break the loop.",
                    "The Tomb Guardian inscription may hold clues.",
                },
            },
            seeking_escape = {
                journal = "The loop continues. The inscriptions speak of WISDOM and STRENGTH. I need one or the other to break free.",
                objectives = { "Break the loop: WIS 14 or STR 16." },
            },
            escaped_wisdom = {
                journal = "I saw through the illusion. The loop was never real — the tomb's geometry was a test of perception. The path to the Inner Sanctum is clear.",
                objectives = { "Enter the Inner Sanctum and face what waits." },
                effects = { xp = 100 },
            },
            escaped_strength = {
                journal = "I shattered the loop by force. The door cracked, the illusion broke. The path is open — but the effort cost me.",
                objectives = { "Enter the Inner Sanctum and face what waits." },
                effects = { xp = 100 },
            },
            confront_shadow = {
                journal = "My Shadow Self stands in the Inner Sanctum. A reflection of everything I've suppressed. The tomb demands I face it.",
                objectives = { "Defeat the Shadow Self." },
            },
            complete = {
                journal = "The Shadow Self is defeated. The tomb's trial is over. The way forward is open.",
                status = "completed",
                rewards = { xp = 600 },
            },
        },
        events = {
            -- Entering tomb entrance starts the quest journey
            {
                type = "room_enter",
                payload = { roomId = 37 },
                stage = "enter_tomb",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "escape_loop", "trapped")
                end,
            },
            -- Reaching room 42 after breaking loop
            {
                type = "room_enter",
                payload = { roomId = 42 },
                stage = "trapped",
                action = function(player, game)
                    if game.tombLoop and game.tombLoop.broken then
                        if (game.player.stats.WIS or 0) >= RPG.Config.TOMB_WIS_DC then
                            RPG.Quest.SetStage(player, "escape_loop", "escaped_wisdom")
                        else
                            RPG.Quest.SetStage(player, "escape_loop", "escaped_strength")
                        end
                    end
                end,
            },
            {
                type = "room_enter",
                payload = { roomId = 42 },
                stage = "seeking_escape",
                action = function(player, game)
                    if game.tombLoop and game.tombLoop.broken then
                        if (game.player.stats.WIS or 0) >= RPG.Config.TOMB_WIS_DC then
                            RPG.Quest.SetStage(player, "escape_loop", "escaped_wisdom")
                        else
                            RPG.Quest.SetStage(player, "escape_loop", "escaped_strength")
                        end
                    end
                end,
            },
            -- Shadow Self defeated
            {
                type = "combat_win",
                payload = { enemyId = 17 },
                stage = "confront_shadow",
                action = function(player, game)
                    game.flags["shadow_self_defeated"] = true
                    -- Unlock room 43 for Act 4
                    if game.rooms[43] then
                        game.rooms[43].locked = false
                    end
                    RPG.Quest.SetStage(player, "escape_loop", "complete")
                end,
            },
        },
    },

    -- ============================================
    -- Q21: REASSEMBLE THE SELF (Act 3-4 Main)
    -- ============================================
    reassemble_self = {
        id = "reassemble_self",
        name = "Reassemble the Self",
        stageOrder = { "shattered", "fragments_active",
            "all_fragments_defeated", "shadow_confronted",
            "survived_void", "complete" },
        stages = {
            shattered = {
                journal = "The tomb is breaking me apart. Fragments of my psyche — rage, fear, despair — have taken form in the tomb's halls.",
                objectives = { "Defeat the fragments of yourself." },
            },
            fragments_active = {
                journal = "The fragments are real enemies. Each one drains a piece of who I am. I must defeat all three.",
                objectives = {
                    "Defeat the Fragment of Rage (Room 38).",
                    "Defeat the Fragment of Fear (Room 39).",
                    "Defeat the Fragment of Despair (Room 40).",
                },
            },
            all_fragments_defeated = {
                journal = "All three fragments are destroyed. But the largest piece — the Shadow Self — still waits in the Inner Sanctum.",
                objectives = { "Confront the Shadow Self in the Inner Sanctum." },
                effects = { xp = 200 },
            },
            shadow_confronted = {
                journal = "The Shadow Self is defeated. But I still feel... incomplete. Something in the Void beyond may hold the answer.",
                objectives = { "Venture into the Void." },
            },
            survived_void = {
                journal = "I survived the Void. The Awakening lies ahead — solid ground, real light. Whatever I lost in the tomb, I've reclaimed.",
                objectives = { "Reach the Awakening." },
            },
            complete = {
                journal = "I am whole again. Changed, but whole. The journey through the tomb and the void has reforged me.",
                status = "completed",
                rewards = { xp = 800 },
            },
        },
        events = {
            -- Fragment victories check if all three are defeated
            {
                type = "combat_win",
                payload = { enemyId = 14 },
                stage = "fragments_active",
                action = function(player, game)
                    game.flags["fragment_rage_defeated"] = true
                    if game.flags["fragment_rage_defeated"]
                        and game.flags["fragment_fear_defeated"]
                        and game.flags["fragment_despair_defeated"] then
                        RPG.Quest.SetStage(player, "reassemble_self", "all_fragments_defeated")
                    end
                end,
            },
            {
                type = "combat_win",
                payload = { enemyId = 14 },
                stage = "shattered",
                action = function(player, game)
                    game.flags["fragment_rage_defeated"] = true
                    RPG.Quest.SetStage(player, "reassemble_self", "fragments_active")
                end,
            },
            {
                type = "combat_win",
                payload = { enemyId = 15 },
                stage = "fragments_active",
                action = function(player, game)
                    game.flags["fragment_fear_defeated"] = true
                    if game.flags["fragment_rage_defeated"]
                        and game.flags["fragment_fear_defeated"]
                        and game.flags["fragment_despair_defeated"] then
                        RPG.Quest.SetStage(player, "reassemble_self", "all_fragments_defeated")
                    end
                end,
            },
            {
                type = "combat_win",
                payload = { enemyId = 15 },
                stage = "shattered",
                action = function(player, game)
                    game.flags["fragment_fear_defeated"] = true
                    RPG.Quest.SetStage(player, "reassemble_self", "fragments_active")
                end,
            },
            {
                type = "combat_win",
                payload = { enemyId = 16 },
                stage = "fragments_active",
                action = function(player, game)
                    game.flags["fragment_despair_defeated"] = true
                    if game.flags["fragment_rage_defeated"]
                        and game.flags["fragment_fear_defeated"]
                        and game.flags["fragment_despair_defeated"] then
                        RPG.Quest.SetStage(player, "reassemble_self", "all_fragments_defeated")
                    end
                end,
            },
            {
                type = "combat_win",
                payload = { enemyId = 16 },
                stage = "shattered",
                action = function(player, game)
                    game.flags["fragment_despair_defeated"] = true
                    RPG.Quest.SetStage(player, "reassemble_self", "fragments_active")
                end,
            },
            -- Shadow Self defeated (any active stage — player may fight before all fragments)
            {
                type = "combat_win",
                payload = { enemyId = 17 },
                action = function(player, game)
                    RPG.Quest.SetStage(player, "reassemble_self", "shadow_confronted")
                end,
            },
            -- Entering the Void
            {
                type = "room_enter",
                payload = { roomId = 47 },
                stage = "shadow_confronted",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "reassemble_self", "survived_void")
                end,
            },
            -- Reaching Act 5
            {
                type = "room_enter",
                payload = { roomId = 48 },
                stage = "survived_void",
                action = function(player, game)
                    RPG.Quest.SetStage(player, "reassemble_self", "complete")
                end,
            },
        },
    },

    -- ============================================
    -- LIGHTSABER CONSTRUCTION QUEST
    -- ============================================
    saber_construction = {
        id = "saber_construction",
        name = "The Blade Reborn",
        stageOrder = { "hilt_found", "lens_only", "crystal_found", "lens_acquired",
                       "reach_chamber", "attunement", "complete" },
        stages = {
            hilt_found = {
                journal = "I found a broken lightsaber hilt. The focusing lens is shattered.",
                objectives = { "Find a lightsaber crystal.",
                               "Find someone who can repair the focusing lens." },
            },
            lens_only = {
                journal = "Jeth fabricated a new focusing lens. Now I need a Force-attuned crystal.",
                objectives = { "Find a lightsaber crystal in the Crystal Caves." },
            },
            crystal_found = {
                journal = "I have a crystal and the hilt, but the lens is still shattered.",
                objectives = { "Find someone who can fabricate a new focusing lens.",
                               "Jeth in the Mechanic's Workshop might have the skills." },
            },
            lens_acquired = {
                journal = "Jeth fabricated a focusing lens. I have all the components.",
                objectives = { "Find a Force-attuned location to assemble the lightsaber.",
                               "The Ancient Jedi Chamber in the Crystal Caves." },
            },
            reach_chamber = {
                journal = "The Jedi Chamber. The Force is strong here.",
                objectives = { "Use the Meditation Alcove to begin assembly." },
            },
            attunement = {
                journal = "Attuning the crystal to Kira's hilt...",
                objectives = { "Complete the attunement ritual." },
            },
            complete = {
                journal = "The lightsaber is complete. Kira's blade lives again.",
                status = "completed",
                rewards = { xp = 400 },
            },
        },
        events = {
            -- Crystal pickup while at hilt_found -> crystal_found (or lens_acquired if lens already owned)
            { type = "item_pickup", payload = { itemId = 5 }, stage = "hilt_found",
              action = function(player, game)
                  if RPG.Quest.HasFlag(game, "jeth_lens_given")
                      and RPG.Util.Contains(game.player.inventory, 41) then
                      RPG.Quest.SetStage(player, "saber_construction", "lens_acquired")
                  else
                      RPG.Quest.SetStage(player, "saber_construction", "crystal_found")
                  end
              end },
            { type = "item_pickup", payload = { itemId = 6 }, stage = "hilt_found",
              action = function(player, game)
                  if RPG.Quest.HasFlag(game, "jeth_lens_given")
                      and RPG.Util.Contains(game.player.inventory, 41) then
                      RPG.Quest.SetStage(player, "saber_construction", "lens_acquired")
                  else
                      RPG.Quest.SetStage(player, "saber_construction", "crystal_found")
                  end
              end },
            -- Crystal pickup while at lens_only -> lens_acquired ONLY if lens still in inventory
            { type = "item_pickup", payload = { itemId = 5 }, stage = "lens_only",
              action = function(player, game)
                  if RPG.Util.Contains(game.player.inventory, 41) then
                      RPG.Quest.SetStage(player, "saber_construction", "lens_acquired")
                  else
                      -- Lens was dropped/lost — fall back to crystal_found (need to revisit Jeth)
                      RPG.Quest.SetStage(player, "saber_construction", "crystal_found")
                  end
              end },
            { type = "item_pickup", payload = { itemId = 6 }, stage = "lens_only",
              action = function(player, game)
                  if RPG.Util.Contains(game.player.inventory, 41) then
                      RPG.Quest.SetStage(player, "saber_construction", "lens_acquired")
                  else
                      RPG.Quest.SetStage(player, "saber_construction", "crystal_found")
                  end
              end },
            -- Enter Room 9 with lens_acquired -> reach_chamber (only if crystal AND lens present)
            { type = "room_enter", payload = { roomId = 9 }, stage = "lens_acquired",
              action = function(player, game)
                  local hasCrystal = RPG.Util.Contains(game.player.inventory, 5)
                      or RPG.Util.Contains(game.player.inventory, 6)
                  local hasLens = RPG.Util.Contains(game.player.inventory, 41)
                  if not hasCrystal or not hasLens then return end
                  RPG.Quest.SetStage(player, "saber_construction", "reach_chamber")
                  player:SendPrint("")
                  player:SendPrint("^8The crystal pulses. The hilt vibrates. The Force gathers.")
                  player:SendPrint("")
              end },
        },
    },
    -- ============================================
    -- THE HUNTER & THE HUNTED (Nemesis System)
    -- ============================================
    the_hunter = {
        id = "the_hunter",
        name = "The Hunter & The Hunted",
        description = "Someone has put a bounty on your head.",
        stageOrder = { "dormant", "hunt_begins", "tracked", "closing_in", "resolved", "complete" },
        stages = {
            dormant     = { journal = "You haven't drawn attention yet. But someone is always watching." },
            hunt_begins = { journal = "A hunter has found you on Dantooine. They know your face." },
            tracked     = { journal = "They've followed you to Onderon. Adapted. Scarred. Coming back." },
            closing_in  = { journal = "The hunter is close. This ends soon -- one way or another." },
            resolved    = { journal = "The hunt is over." },
            complete    = { journal = "The hunt is over. The rivalry has been settled." },
        },
        events = {},
    },
}

return RPG.Data.Quests
