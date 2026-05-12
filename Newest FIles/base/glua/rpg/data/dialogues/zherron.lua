-- Dialogue Tree: Captain Zherron
-- Ex-Republic soldier, militia captain  - Room 12 (Barracks)
-- Quest Q6: The Law of Khoonda (law_khoonda)
-- Stages: report_in, kinrath_task, suspicion, resolution, complete
-- ~15 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- P2: Completed quest reactions (Q3 shadows_trail, requires law_khoonda done)
            { condition = function(g)
                return RPG.Quest.IsComplete(g, "shadows_trail")
                    and RPG.Quest.IsComplete(g, "law_khoonda")
                    and not RPG.Quest.HasFlag(g, "zherron_shadows_discussed")
                end, node = 44 },
            -- P3: law_khoonda quest stages
            { condition = function(g) return RPG.Quest.IsComplete(g, "law_khoonda") end, node = 40 },
            { condition = function(g) return RPG.Quest.GetStage(g, "law_khoonda") == "resolution" end, node = 30 },
            { condition = function(g) return RPG.Quest.GetStage(g, "law_khoonda") == "suspicion" end, node = 20 },
            { condition = function(g) return RPG.Quest.GetStage(g, "law_khoonda") == "kinrath_task" end, node = 10 },
            { condition = function(g) return RPG.Quest.IsActive(g, "law_khoonda") end, node = 10 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default Greeting (No quest yet)
    -- ============================================
    [1] = {
        speaker = "Captain Zherron",
        text = {
            "A weathered man in battered Republic-surplus armor stands over a map table,",
            "pushing markers around with calloused fingers. He doesn't look up.",
            "'^7Another volunteer. Or another tourist. Which are you?'",
            "'^7We've got kinrath pushing into the southern fields. Lost two",
            "settlers last week. Militia's stretched thin and half of them",
            "can't tell a blaster's trigger from its safety.'",
        },
        responses = {
            {
                label = "I can help with the kinrath.",
                next = 2,
            },
            {
                label = "You were Republic military?",
                next = 3,
            },
            {
                label = "[STR 14] You look like you could use a real soldier, not another farmhand.",
                next = 4,
                check = { stat = "STR", dc = 14 },
                failNext = 5,
            },
            {
                label = "Not my problem. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Accepted quest  - kinrath clearance
    -- ============================================
    [2] = {
        speaker = "Captain Zherron",
        text = {
            "He looks up. Studies you for three seconds. Nods once.",
            "'^7Good. I don't need speeches. I need someone who comes back alive.'",
            "'^7The nests are along the cave path, north of the Plaza. Two adults,",
            "maybe more. They've been breeding fast since that ship came down  -",
            "something on it riled them up.'",
            "'^7Kill at least two and the rest scatter. That's how kinrath work.",
            "Cut the spine and the body follows.'",
        },
        effects = {
            startQuest = "law_khoonda",
            setStage = { quest = "law_khoonda", stage = "kinrath_task" },
        },
        responses = {
            {
                label = "Consider it done.",
                next = -1,
            },
            {
                label = "Any equipment you can spare?",
                next = 6,
            },
        },
    },

    -- ============================================
    -- NODE 3: Ask about his Republic service
    -- ============================================
    [3] = {
        speaker = "Captain Zherron",
        text = {
            "His jaw tightens. Old reflex.",
            "'^7Twelve years. Served under Revan before the turn. Served",
            "under what was left of the Republic after.'",
            "'^7I was at Malachor. I watched Jedi die beside us. I watched",
            "Jedi leave us. Forgive me if I don't trust anyone who claims",
            "to be \"just a politician.\"'",
            "He catches himself. Clears his throat.",
            "'^7Point is: I know what's coming when the perimeter breaks.",
            "And it will break if those kinrath nests aren't cleared.'",
        },
        responses = {
            {
                label = "I'll handle the kinrath for you.",
                next = 2,
            },
            {
                label = "Sounds like you don't trust Administrator Adare.",
                next = 7,
            },
            {
                label = "That's a lot of baggage. [Leave]",
                next = -1,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 4: STR check SUCCESS  - military respect
    -- ============================================
    [4] = {
        speaker = "Captain Zherron",
        text = {
            "He straightens. Something shifts behind his eyes  - recognition.",
            "'^7Hm. You carry yourself like someone who's seen a line break.'",
            "'^7All right. I don't hand out ranks, but I'll give you a job.",
            "Kinrath nests, cave path. Clear at least two adults and the",
            "rest pull back. You know how pack predators work.'",
            "'^7Do this right and we'll talk about something more... sensitive.'",
        },
        effects = {
            startQuest = "law_khoonda",
            setStage = { quest = "law_khoonda", stage = "kinrath_task" },
            setFlag = "zherron_respects_player",
        },
        responses = {
            {
                label = "Point me at them.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 5: STR check FAILURE
    -- ============================================
    [5] = {
        speaker = "Captain Zherron",
        text = {
            "He gives you a flat look. Unimpressed.",
            "'^7Talk's cheap. The kinrath don't care about your resume.'",
            "'^7You want to prove something? Clear the nests along the",
            "cave path. Two adults minimum. Then we'll see.'",
        },
        effects = {
            startQuest = "law_khoonda",
            setStage = { quest = "law_khoonda", stage = "kinrath_task" },
        },
        responses = {
            {
                label = "Fine. I'll prove it.",
                next = -1,
            },
            {
                label = "Forget it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 6: Ask for equipment
    -- ============================================
    [6] = {
        speaker = "Captain Zherron",
        text = {
            "'^7This isn't a Republic armory. We've got what the settlers",
            "could scrounge.'",
            "He jerks his thumb at the weapons rack.",
            "'^7Militia armor on the rack, if it fits. Take a medpac",
            "from the footlocker. That's all I can spare.'",
        },
        effects = { giveItem = 3 },
        responses = {
            {
                label = "It'll do. I'm heading out.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 7: Doesn't trust Adare (pre-quest hook)
    -- ============================================
    [7] = {
        speaker = "Captain Zherron",
        text = {
            "He pauses. Measures his words carefully.",
            "'^7I didn't say that. Adare's competent. Keeps things running.'",
            "'^7But competent people with secrets get other people killed.",
            "I've seen it before.'",
            "He shakes his head.",
            "'^7Not the time. Clear those kinrath first. Then maybe we",
            "can have that conversation.'",
        },
        effects = {
            startQuest = "law_khoonda",
            setStage = { quest = "law_khoonda", stage = "kinrath_task" },
        },
        responses = {
            {
                label = "I'll handle the kinrath. We'll talk after.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: Kinrath task in progress  - checking kills
    -- ============================================
    [10] = {
        speaker = "Captain Zherron",
        text = {
            "'^7You're back. How many did you drop?'",
        },
        responses = {
            {
                label = "Still working on it.",
                next = 11,
            },
            {
                label = "The path is crawling with them.",
                next = 12,
            },
        },
    },

    [11] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Then get back out there. Kinrath don't wait for you to",
            "feel ready. Every day those nests grow, we lose more ground.'",
            "'^7Two adults. That's the tipping point. Move.'",
        },
        responses = {
            { label = "On my way. [Leave]", next = -1 },
        },
    },

    [12] = {
        speaker = "Captain Zherron",
        text = {
            "'^7They always are after a nest expansion. The crash stirred",
            "them up  - vibrations, heat, whatever came off that ship.'",
            "'^7Doesn't matter why. Matters that you put them down.'",
            "'^7Focus on the adults. Hatchlings scatter without them.'",
        },
        responses = {
            { label = "Understood. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 20: Suspicion subplot  - kinrath cleared, trust earned
    -- ============================================
    [20] = {
        speaker = "Captain Zherron",
        text = {
            "He checks the map. Moves a marker. Nods slowly.",
            "'^7Reports say the cave path is clear. You did good work.'",
            "He lowers his voice. Glances at the barracks door.",
            "'^7Sit down. I need to talk to you about something.",
            "Something I can't take to the militia.'",
        },
        responses = {
            {
                label = "I'm listening.",
                next = 21,
            },
            {
                label = "If this is about Adare, I'm not interested.",
                next = 25,
            },
        },
    },

    -- ============================================
    -- NODE 21: Zherron lays out his suspicion
    -- ============================================
    [21] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Adare's hiding something. I've suspected it for months.'",
            "'^7The way she flinched when that ship came down. The way she",
            "handled the Enclave ruins  - told everyone to stay away.",
            "Not for safety. For secrecy.'",
            "'^7I think she trained at the Enclave. I think she's Force-sensitive,",
            "maybe more. And she's been lying to every person in this settlement.'",
            "His fists clench on the map table.",
            "'^7I don't hate Jedi. I hate liars. If she's hiding what she is,",
            "there's a reason. And reasons like that get people killed.'",
        },
        saevusWhisper = "Soldiers are tools. Wind this one up and point him at the woman.",
        saevusCondition = function(g) return g.player.hasHolocron and g.player.paranoia > 25 end,
        responses = {
            {
                label = "I'll look into it. Quietly.",
                next = 22,
                effects = {
                    setStage = { quest = "law_khoonda", stage = "resolution" },
                    setFlag = "zherron_investigate_adare",
                },
            },
            {
                label = "[CHA 13] Even if it's true  - what changes? She's still keeping this place alive.",
                next = 23,
                check = { stat = "CHA", dc = 13 },
                failNext = 24,
            },
            {
                label = "That's her business, not yours.",
                next = 25,
                alignment = 2,
            },
            {
                label = "Use his paranoia. A rift between them weakens Khoonda's defenses.",
                truthLabel = "The Holocron wants division. Zherron's suspicion could destroy this settlement.",
                isDoubt = true,
                next = 22,
                alignment = -8,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 20 end,
                effects = {
                    setStage = { quest = "law_khoonda", stage = "resolution" },
                    setFlag = "zherron_investigate_adare",
                    paranoia = 5,
                },
            },
        },
    },

    -- ============================================
    -- NODE 22: Agreed to investigate Adare
    -- ============================================
    [22] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Good. I knew you had sense.'",
            "'^7Check the Archives. Tamas keeps records going back to the",
            "Enclave days. If she trained there, his files will show it.'",
            "'^7And watch how she reacts when you mention the Jedi.",
            "The truth always shows in the eyes.'",
        },
        responses = {
            {
                label = "I'll be discreet.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 23: CHA check SUCCESS  - talked him down
    -- ============================================
    [23] = {
        speaker = "Captain Zherron",
        text = {
            "He opens his mouth. Closes it. His shoulders drop half an inch.",
            "'^7...Maybe you're right. Maybe it doesn't matter.'",
            "'^7I've been a soldier too long. Everything's a threat assessment.'",
            "He exhales through his nose.",
            "'^7Fine. I'll drop it. But if her secrets get someone killed,",
            "I want you to remember this conversation.'",
        },
        effects = {
            setStage = { quest = "law_khoonda", stage = "resolution" },
            setFlag = "zherron_stood_down",
            giveXP = 100,
        },
        responses = {
            {
                label = "Fair enough. You're a good man, Zherron.",
                next = 31,
                alignment = 3,
            },
            {
                label = "I'll remember.",
                next = 31,
            },
        },
    },

    -- ============================================
    -- NODE 24: CHA check FAILURE  - he's not convinced
    -- ============================================
    [24] = {
        speaker = "Captain Zherron",
        text = {
            "'^7That's easy to say when you're not the one burying settlers.'",
            "'^7I've got twelve farmers with blasters standing between this",
            "settlement and everything that wants to eat it. I don't get",
            "the luxury of trust.'",
            "'^7Are you going to help me or not?'",
        },
        responses = {
            {
                label = "All right. I'll look into Adare.",
                next = 22,
                effects = {
                    setStage = { quest = "law_khoonda", stage = "resolution" },
                    setFlag = "zherron_investigate_adare",
                },
            },
            {
                label = "No. Leave her alone.",
                next = 25,
                alignment = 2,
            },
        },
    },

    -- ============================================
    -- NODE 25: Refused to investigate / "her business"
    -- ============================================
    [25] = {
        speaker = "Captain Zherron",
        text = {
            "His jaw sets. The temperature drops ten degrees.",
            "'^7Her business becomes my business when my people die for it.'",
            "'^7But fine. You've made your choice. I'll handle it myself.'",
            "He turns back to the map. Conversation over.",
        },
        effects = {
            setStage = { quest = "law_khoonda", stage = "resolution" },
            setFlag = "zherron_acting_alone",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Resolution  - player returns with a decision
    -- ============================================
    [30] = {
        routes = {
            { condition = function(g) return RPG.Quest.HasFlag(g, "zherron_stood_down") end, node = 31 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "warned_adare") end, node = 32 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "zherron_investigate_adare") end, node = 31 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "zherron_acting_alone") end, node = 31 },
        },
        fallback = 31,
    },

    -- ============================================
    -- NODE 31: Standard resolution  - quest wraps up
    -- ============================================
    [31] = {
        speaker = "Captain Zherron",
        text = {
            "'^7The cave path is holding. Militia morale's up since you",
            "cleared those nests. First good news in weeks.'",
            "He extends a hand. Rough grip. Honest.",
            "'^7You did right by this settlement. Whatever else happens",
            "with Adare, with the Exchange  - you earned your place here.'",
            "'^7Armory's open to you. Take what you need.'",
        },
        effects = {
            setStage = { quest = "law_khoonda", stage = "complete" },
            giveXP = 150,
            addCredits = 40,
        },
        responses = {
            {
                label = "Just doing what needed doing.",
                next = -1,
                alignment = 2,
            },
            {
                label = "I expect to be compensated.",
                next = -1,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 32: Player warned Adare  - tension
    -- ============================================
    [32] = {
        speaker = "Captain Zherron",
        text = {
            "He's standing rigidly. Arms folded. He knows.",
            "'^7You told her.'",
            "'^7I asked you to investigate. Instead you ran straight",
            "to her and blew my cover.'",
            "A dangerous pause.",
            "'^7She came to me. Denied everything. But her hands were",
            "shaking. And now she watches me like I'm the enemy.'",
        },
        responses = {
            {
                label = "She deserved to know someone was digging into her past.",
                next = 33,
                alignment = 3,
            },
            {
                label = "I did what I thought was right.",
                next = 33,
            },
            {
                label = "You were going to tear this settlement apart with your paranoia.",
                next = 34,
            },
        },
    },

    [33] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Maybe. Or maybe you just made sure I can never trust",
            "the person I'm supposed to protect.'",
            "He turns back to the map.",
            "'^7The armory's open. Take your pay and go.'",
            "'^7We're done talking.'",
        },
        effects = {
            setStage = { quest = "law_khoonda", stage = "complete" },
            setFlag = "zherron_bitter",
            giveXP = 100,
            addCredits = 40,
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    [34] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Paranoia.'",
            "The word lands like a slap. He's quiet for a long time.",
            "'^7I watched three hundred soldiers die at Malachor because",
            "a Jedi general decided his vision was more important than",
            "our lives. That's not paranoia. That's pattern recognition.'",
            "'^7But you made your call. Take the gear. Get out.'",
        },
        effects = {
            setStage = { quest = "law_khoonda", stage = "complete" },
            setFlag = "zherron_bitter",
            giveXP = 100,
            addCredits = 40,
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 40: Post-quest  - militia equipment access
    -- ============================================
    [40] = {
        routes = {
            { condition = function(g) return RPG.Quest.HasFlag(g, "zherron_bitter") end, node = 42 },
        },
        fallback = 41,
    },

    [41] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Perimeter's holding. Your work on the cave path bought",
            "us time.'",
            "He almost smiles. Almost.",
            "'^7Armory's open. Help yourself. And if you're heading out",
            "there again  - watch your back. The kinrath aren't the only",
            "thing that hunts on Dantooine.'",
        },
        responses = {
            {
                label = "Thanks, Captain. Stay sharp.",
                next = -1,
            },
            {
                label = "Any new threats I should know about?",
                next = 43,
            },
        },
    },

    [42] = {
        speaker = "Captain Zherron",
        text = {
            "He doesn't look up from his map.",
            "'^7Armory's open. Take what you need and move on.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    [43] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Exchange is getting bolder. Draxen has been probing our",
            "patrols, testing response times. And the Enclave ruins...'",
            "He shakes his head.",
            "'^7Something's moving in the sublevel. My scouts won't go",
            "near it. Could be droids, could be worse.'",
            "'^7Stay armed. Stay alert. That's all I've got.'",
        },
        responses = {
            { label = "Copy that. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 44: Q3 Reaction  - Sublevel report (expanded)
    -- ============================================
    [44] = {
        speaker = "Captain Zherron",
        text = {
            "'^7My scouts found something in the sublevel. Not salvager",
            "droids  - those leave predictable tracks.'",
            "'^7Someone was down there recently. Accessing old terminals.",
            "Republic Intelligence encryption.'",
            "'^7I don't like unknowns. Unknowns get people killed.'",
        },
        responses = {
            {
                label = "Adare and I handled it. The intel's with the Republic.",
                next = 44.5,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadows_trail_light") end,
            },
            {
                label = "I know what was down there. It's dealt with.",
                next = 44.6,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadows_trail_dark") or RPG.Quest.HasFlag(g, "shadows_trail_neutral") end,
            },
            {
                label = "I'll keep an eye out. [Leave]",
                next = -1,
                setFlag = "zherron_shadows_discussed",
            },
        },
    },

    -- ============================================
    -- NODE 44.5: Light path acknowledgment
    -- ============================================
    [44.5] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Adare tells me you handled it. She won't say what \"it\"",
            "is. That woman and her secrets.'",
            "He shakes his head.",
            "'^7But my scouts can read a star chart. Whatever was on those",
            "terminals pointed somewhere far away and very bad.'",
            "'^7Stay sharp out there.'",
        },
        responses = {
            {
                label = "You too, Captain. [Leave]",
                next = -1,
                setFlag = "zherron_shadows_discussed",
                alignment = 1,
            },
        },
    },

    -- ============================================
    -- NODE 44.6: Dark/Neutral path acknowledgment
    -- ============================================
    [44.6] = {
        speaker = "Captain Zherron",
        text = {
            "'^7Nobody tells me anything. But I can read a star chart.'",
            "'^7Whatever was on those terminals pointed somewhere far",
            "away and very bad.'",
            "'^7I don't need details. I just need to know my perimeter",
            "is secure. Is it?'",
        },
        responses = {
            {
                label = "Your perimeter is fine, Captain.",
                next = -1,
                setFlag = "zherron_shadows_discussed",
            },
            {
                label = "Honestly? I don't know. [Leave]",
                next = -1,
                setFlag = "zherron_shadows_discussed",
                alignment = 1,
            },
        },
    },
}
