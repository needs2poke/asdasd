-- Dialogue Tree: Merchant Goran
-- Commerce, gossip, Exchange target  - Room 2
-- ~15 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            { condition = function(g) return RPG.Quest.GetStage(g, "exchange_pressure") == "resolved_peaceful" end, node = 50 },
            { condition = function(g) return RPG.Quest.GetStage(g, "exchange_pressure") == "paid_debt" end, node = 55 },
            { condition = function(g) return RPG.Quest.GetStage(g, "exchange_pressure") == "betrayed_goran" end, node = 60 },
            { condition = function(g) return RPG.Quest.IsComplete(g, "exchange_pressure") end, node = 70 },
            { condition = function(g) return RPG.Quest.GetStage(g, "exchange_pressure") == "investigate" end, node = 20 },
            { condition = function(g) return RPG.Quest.IsActive(g, "exchange_pressure") end, node = 15 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default greeting
    -- ============================================
    [1] = {
        speaker = "Merchant Goran",
        text = {
            "A lean man with shrewd eyes peers at you over stacked crates.",
            "'^7Another traveler. Welcome to Khoonda's finest  - and only  -",
            "trading post. Credits buy supplies. Smiles buy nothing.'",
        },
        responses = {
            {
                label = "You seem troubled. Everything all right?",
                next = 2,
            },
            {
                label = "What do you have for sale?",
                next = 3,
            },
            {
                label = "Heard any rumors about the crash?",
                next = 4,
            },
            {
                label = "Just browsing. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Ask about his troubles -> starts quest
    -- ============================================
    [2] = {
        speaker = "Merchant Goran",
        text = {
            "He glances around, lowering his voice.",
            "'^7Troubled? That's a polite word for it.'",
            "'^7The Exchange has been leaning on me. Protection credits, they",
            "call it. Fifty percent of my salvage profits or... unpleasant",
            "consequences.'",
            "'^7Draxen runs their operation here. He's out in the fields,'",
            "where the militia can't see.'",
        },
        responses = {
            {
                label = "I'll deal with Draxen for you.",
                next = 10,
                effects = { startQuest = "exchange_pressure" },
            },
            {
                label = "How much do you owe?",
                next = 5,
            },
            {
                label = "That sounds like your problem, not mine.",
                next = 6,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 3: Shopping
    -- ============================================
    [3] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Medpacs, rations, basic equipment. Nothing fancy.'",
            "'^7Morality's expensive this season. Medpacs are cheaper.'",
        },
        responses = {
            {
                label = "Let me see what you've got. [Open Shop]",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 1 } } },
            },
            {
                label = "You seem troubled. Everything all right?",
                next = 2,
            },
            {
                label = "Maybe later. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 4: Crash rumors
    -- ============================================
    [4] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Everyone's talking about it. Jedi ship, they say. Though",
            "the last Jedi anyone saw around here was years ago.'",
            "'^7The Exchange is already salvaging. Whatever was on that ship,",
            "they want it. And what the Exchange wants, they usually get.'",
        },
        responses = {
            {
                label = "Tell me about the Exchange on Dantooine.",
                next = 2,
            },
            {
                label = "Interesting. Thanks. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 5: How much does he owe?
    -- ============================================
    [5] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Two hundred credits. Might as well be two million. That's",
            "three months of profit for this settlement.'",
            "'^7I'd pay it just to make them go away, but if I give in",
            "once, they'll never stop.'",
        },
        responses = {
            {
                label = "I'll talk to Draxen.",
                next = 10,
                effects = { startQuest = "exchange_pressure" },
            },
            {
                label = "I can pay it for you. [200 credits]",
                next = 11,
                condition = function(g) return g.player.credits >= 200 end,
                effects = {
                    startQuest = "exchange_pressure",
                    addCredits = -200,
                },
            },
            {
                label = "That's rough. Good luck. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 6: "Not my problem"
    -- ============================================
    [6] = {
        speaker = "Merchant Goran",
        text = {
            "He shrugs, but the disappointment is obvious.",
            "'^7Fair enough. Nobody asked you to be a hero.'",
            "'^7Just... if you change your mind, I'm not going anywhere.",
            "Can't afford to.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 10: Accepted to deal with Draxen
    -- ============================================
    [10] = {
        speaker = "Merchant Goran",
        text = {
            "'^7You'd do that? I... thank you.'",
            "'^7Draxen hangs around the Dantooine Fields, east of the Plaza.",
            "He's got muscle with him, so watch yourself. The man's a snake",
            "but he's not stupid.'",
            "'^7If you can convince him to back off, I'll make it worth your",
            "while. Best prices in the settlement, guaranteed.'",
        },
        effects = {
            setStage = { quest = "exchange_pressure", stage = "investigate" },
        },
        responses = {
            { label = "I'll handle it. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 11: Paid the debt directly
    -- ============================================
    [11] = {
        speaker = "Merchant Goran",
        text = {
            "He stares at the credits like they're a hallucination.",
            "'^7You're... serious. Two hundred credits, just like that?'",
            "'^7I don't know what to say. That's the most generous thing",
            "anyone's done for me since the wars ended.'",
        },
        effects = {
            setStage = { quest = "exchange_pressure", stage = "paid_debt" },
        },
        responses = {
            {
                label = "Just take care of your people, Goran.",
                next = 12,
                alignment = 5,
            },
            {
                label = "You owe me. Remember that.",
                next = 13,
            },
        },
    },

    [12] = {
        speaker = "Merchant Goran",
        text = {
            "'^7I will. And you  - anything in my shop, cost price. Always.'",
            "He pockets the credits, looking ten years younger.",
        },
        effects = { setFlag = "goran_discount_small" },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    [13] = {
        speaker = "Merchant Goran",
        text = {
            "'^7I will. Trust me, Goran pays his debts.'",
            "He nods carefully, filing away the obligation.",
        },
        effects = { setFlag = "goran_owes_favor" },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 15: Quest active, still investigating
    -- ============================================
    [15] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Any luck with Draxen? The Exchange thugs were by again",
            "this morning. Running out of excuses.'",
        },
        responses = {
            {
                label = "Working on it. Hang tight.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: Investigate stage  - awaiting resolution
    -- ============================================
    [20] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Did you find Draxen? What happened?'",
        },
        responses = {
            {
                label = "He won't bother you anymore. [after persuade/intimidate]",
                next = 50,
                condition = function(g) return RPG.Quest.HasFlag(g, "visquis_backed_off") end,
                effects = {
                    setStage = { quest = "exchange_pressure", stage = "resolved_peaceful" },
                },
            },
            {
                label = "Still working on it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 50: Resolved peacefully  - grateful
    -- ============================================
    [50] = {
        speaker = "Merchant Goran",
        text = {
            "His whole posture changes. The tension drains out.",
            "'^7You actually did it. The Exchange backed off.'",
            "'^7I owe you more than I can repay. But I can do this:'",
            "'^7Twenty percent off everything. Permanently. Best prices on",
            "Dantooine, and that's not just talk.'",
        },
        effects = { setFlag = "goran_discount_full" },
        responses = {
            {
                label = "Happy to help, Goran.",
                next = 51,
                effects = {
                    setStage = { quest = "exchange_pressure", stage = "complete" },
                },
            },
            {
                label = "I'd like to browse your stock.",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 1 } } },
            },
        },
    },

    [51] = {
        speaker = "Merchant Goran",
        text = {
            "'^7You know, for a stranger, you're not half bad.'",
            "He extends a hand. '^7Stay safe out there.'",
        },
        responses = {
            { label = "[Shake his hand and leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 55: Paid debt  - grateful but embarrassed
    -- ============================================
    [55] = {
        speaker = "Merchant Goran",
        text = {
            "'^7I sent the credits to Draxen. He accepted. For now.'",
            "He looks uncomfortable.",
            "'^7I don't like owing people. But I won't forget what you did.'",
        },
        effects = {
            setStage = { quest = "exchange_pressure", stage = "complete" },
            setFlag = "goran_discount_small",
        },
        responses = {
            { label = "You don't owe me anything. [Leave]", next = -1, alignment = 2 },
            { label = "No, you don't forget. [Leave]", next = -1, alignment = -2 },
            {
                label = "I'd like to browse your stock.",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 1 } } },
            },
        },
    },

    -- ============================================
    -- NODE 60: Betrayed Goran  - hostile
    -- ============================================
    [60] = {
        speaker = "Merchant Goran",
        text = {
            "He won't look at you. His voice is flat.",
            "'^7I know what you did. Draxen told me himself. Laughed about it.'",
            "'^7Don't bother shopping here. My prices for you just doubled.'",
        },
        effects = {
            setStage = { quest = "exchange_pressure", stage = "complete" },
            setFlag = "goran_hostile",
        },
        responses = {
            {
                label = "It was business, Goran.",
                next = 61,
                alignment = -3,
            },
            {
                label = "[Leave without a word]",
                next = -1,
            },
        },
    },

    [61] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Business.'",
            "He turns his back.",
            "'^7Get out of my shop.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 70: Quest complete  - general greeting
    -- ============================================
    [70] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Welcome back. Need supplies? I've got the usual.'",
        },
        responses = {
            {
                label = "What do you have for sale?",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 1 } } },
            },
            {
                label = "Any news?",
                next = 71,
            },
            {
                label = "Just looking. [Leave]",
                next = -1,
            },
        },
    },

    [71] = {
        speaker = "Merchant Goran",
        text = {
            "'^7Quiet, for once. The Exchange is keeping its distance.",
            "Settlers are calmer. Almost feels like a real town again.'",
            "'^7Almost.'",
        },
        responses = {
            { label = "Good to hear. [Leave]", next = -1 },
        },
    },
}
