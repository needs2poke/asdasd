-- Dialogue Tree: Draxen (successor to Visquis, who died on Nar Shaddaa)
-- Exchange crime boss, Dantooine Fields  - Room 13
-- Antagonist for Q1 (exchange_pressure), connects to Q2 (field_medicine)
-- Smooth-talking, transactional, respects strength, despises weakness
-- ~22 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            { condition = function(g)
                return RPG.Quest.HasFlag(g, "atton_companion")
                    and g.player.hasHolocron
                    and RPG.Quest.HasFlag(g, "visquis_knows_holocron")
                end, node = 30 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "visquis_allied") end, node = 20 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "visquis_hostile") end, node = 25 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "visquis_backed_off") end, node = 22 },
            { condition = function(g) return RPG.Quest.GetStage(g, "exchange_pressure") == "investigate" end, node = 2 },
            { condition = function(g) return RPG.Quest.IsActive(g, "exchange_pressure") end, node = 2 },
            { condition = function(g) return RPG.Quest.IsComplete(g, "exchange_pressure") end, node = 22 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default greeting  - no quest yet
    -- ============================================
    [1] = {
        speaker = "Draxen",
        text = {
            "A lean figure pushes off the boulder, straightening his coat.",
            "Cold eyes sweep over you with the casual appraisal of a man",
            "who prices everything he sees.",
            "'^7Well. A new face in the fields. That's either very brave",
            "or very lost.'",
            "'^7I'm Draxen. The old leadership on Nar Shaddaa was wiped out.",
            "I picked up the pieces here on Dantooine. You might say I",
            "provide... stability.'",
        },
        responses = {
            {
                label = "You're Exchange.",
                next = 3,
            },
            {
                label = "I hear you're squeezing the local merchants.",
                next = 2,
                condition = function(g) return RPG.Quest.IsActive(g, "exchange_pressure") end,
            },
            {
                label = "Just passing through.",
                next = 4,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Confrontation about Goran (quest active)
    -- ============================================
    [2] = {
        speaker = "Draxen",
        text = {
            "He doesn't flinch. If anything, he looks amused.",
            "'^7Squeezing. Such an ugly word. I prefer \"incentivizing\".'",
            "'^7Goran operates on Exchange territory. The roads, the trade",
            "routes, the protection from kinrath and worse  - that's my",
            "infrastructure. My investment. And investments require returns.'",
            "'^7Everyone has a price. The honest ones just haven't found",
            "theirs yet.'",
        },
        responses = {
            {
                label = "[CHA 14] You're smarter than this. Bleeding Goran dry kills the golden bantha. A healthy merchant pays more in the long run.",
                next = 5,
                check = { stat = "CHA", dc = 14 },
                failNext = 6,
            },
            {
                label = "[STR 14] Back off Goran. Now. Or we find out if your thugs are faster than me.",
                next = 7,
                check = { stat = "STR", dc = 14 },
                failNext = 8,
            },
            {
                label = "What if I worked for you instead? Goran's small time.",
                next = 9,
                alignment = -3,
            },
            {
                label = "How much does he owe?",
                next = 4,
            },
            {
                label = "I'll be back. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 3: "You're Exchange"  - acknowledges it
    -- ============================================
    [3] = {
        speaker = "Draxen",
        text = {
            "'^7I'm a businessman. I inherited Visquis's sector protocols.",
            "Business is business. The Exchange is simply the infrastructure",
            "that makes commerce possible on a world the Republic forgot.'",
            "He adjusts a cuff, unhurried.",
            "'^7The Administrator wrings her hands. The militia patrols in",
            "circles. Who actually keeps the salvagers safe? Who negotiates",
            "the trade routes? Who resolves disputes without a bureaucrat",
            "in triplicate?'",
            "'^7Me.'",
        },
        responses = {
            {
                label = "I hear you're leaning on Merchant Goran.",
                next = 2,
                condition = function(g) return RPG.Quest.IsActive(g, "exchange_pressure") end,
            },
            {
                label = "You sound almost reasonable.",
                next = 4,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 4: General talk / "How much does Goran owe?"
    -- ============================================
    [4] = {
        speaker = "Draxen",
        text = {
            "'^7Two hundred credits. A pittance, really. But it's the principle.'",
            "'^7If one merchant stops paying, they all stop paying. And then",
            "who funds the patrols? Who keeps the supply lines open?'",
            "He spreads his hands, the picture of reasonableness.",
            "'^7I don't enjoy this. I'm not some thug who shakes people down",
            "for sport. It's arithmetic. Nothing more.'",
        },
        responses = {
            {
                label = "[CHA 14] Convince him to ease up on Goran.",
                next = 5,
                check = { stat = "CHA", dc = 14 },
                failNext = 6,
                condition = function(g) return RPG.Quest.IsActive(g, "exchange_pressure") end,
            },
            {
                label = "[STR 14] Threaten him.",
                next = 7,
                check = { stat = "STR", dc = 14 },
                failNext = 8,
                condition = function(g) return RPG.Quest.IsActive(g, "exchange_pressure") end,
            },
            {
                label = "Maybe we can do business.",
                next = 9,
                condition = function(g) return RPG.Quest.IsActive(g, "exchange_pressure") end,
                alignment = -3,
            },
            {
                label = "Interesting perspective. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 5: CHA 14 SUCCESS  - persuade him to back off
    -- ============================================
    [5] = {
        speaker = "Draxen",
        text = {
            "He pauses. Actually pauses. You've surprised him.",
            "'^7...Hm.'",
            "'^7You make an interesting argument. A dead merchant is worthless.",
            "A grateful merchant, on the other hand, remembers who showed",
            "restraint.'",
            "He tilts his head, considering.",
            "'^7Fine. I'll reduce Goran's obligation. Twenty percent of profits.",
            "Sustainable. And he stays in business to pay it.'",
            "'^7Tell him he's welcome. And tell him to remember who showed",
            "him mercy  - it wasn't the militia.'",
        },
        effects = {
            setFlag = "visquis_backed_off",
            alignment = 5,
            giveXP = 100,
        },
        responses = {
            {
                label = "A wise decision.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 6: CHA 14 FAILURE  - sees through you
    -- ============================================
    [6] = {
        speaker = "Draxen",
        text = {
            "He smiles. It doesn't reach his eyes.",
            "'^7That was almost convincing. Almost.'",
            "'^7I've been talked at by senators, Jedi, and Hutt lords.",
            "You'll need to do better than recycled negotiation tactics",
            "from a first-year diplomat.'",
            "'^7Goran's debt stands. Is there anything else?'",
        },
        responses = {
            {
                label = "[STR 14] Then we do this the other way.",
                next = 7,
                check = { stat = "STR", dc = 14 },
                failNext = 8,
            },
            {
                label = "What if we made a different arrangement?",
                next = 9,
                alignment = -3,
            },
            {
                label = "I'll find another way. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 7: STR 14 SUCCESS  - intimidate him
    -- ============================================
    [7] = {
        speaker = "Draxen",
        text = {
            "You step forward. His thugs reach for weapons  -",
            "but Draxen raises a hand. They stop.",
            "He studies you. The calculation behind his eyes is almost",
            "audible.",
            "'^7...You're serious.'",
            "A long moment. Then he nods, slowly.",
            "'^7I'm a pragmatist, not a martyr. Goran isn't worth a war.'",
            "'^7Tell him the debt is forgiven. And tell him why. I want him",
            "to know it wasn't charity  - it was someone with enough spine",
            "to face me down.'",
            "A thin smile. '^7I respect that. Don't make me regret it.'",
        },
        effects = {
            setFlag = "visquis_backed_off",
            alignment = 3,
            giveXP = 100,
        },
        responses = {
            {
                label = "Smart choice.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 8: STR 14 FAILURE  - not impressed
    -- ============================================
    [8] = {
        speaker = "Draxen",
        text = {
            "His thugs shift. Hands on blasters. You feel the odds tilt.",
            "Draxen hasn't moved. He looks... bored.",
            "'^7Threatening me on my own ground. Surrounded by my people.'",
            "He shakes his head.",
            "'^7I admire the impulse, if not the execution. You don't have",
            "the leverage for threats. Not here. Not yet.'",
            "'^7Come back when you have something to bargain with. Or don't.'",
        },
        effects = {
            setFlag = "visquis_hostile",
        },
        responses = {
            {
                label = "[CHA 14] Fine. Let me try a different approach.",
                next = 5,
                check = { stat = "CHA", dc = 14 },
                failNext = 6,
            },
            {
                label = "What if we made a deal instead?",
                next = 9,
                alignment = -3,
            },
            {
                label = "This isn't over. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 9: Side with Exchange  - betray Goran
    -- ============================================
    [9] = {
        speaker = "Draxen",
        text = {
            "His expression shifts. Interest. Real interest.",
            "'^7Now we're speaking the same language.'",
            "'^7Goran is a small man with a small operation. But you...",
            "you have potential. I can always use capable people.'",
            "'^7Here's what I propose: you convince Goran to pay what he",
            "owes  - all of it  - and I give you a fifteen percent finder's",
            "fee. A hundred and fifty credits, clean.'",
            "'^7And maybe we find more work for you down the road.'",
        },
        responses = {
            {
                label = "Done. Goran will pay.",
                next = 10,
            },
            {
                label = "He's just a merchant. He can't handle that kind of debt.",
                next = 11,
            },
            {
                label = "He's more honest than the politicians. At least crime admits what it is.",
                truthLabel = "You're rationalizing cruelty as pragmatism. Goran has a family.",
                isDoubt = true,
                next = 10,
                alignment = -5,
                condition = function(g) return g.player.paranoia > 15 end,
            },
            {
                label = "No. I changed my mind. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: Confirmed betrayal of Goran
    -- ============================================
    [10] = {
        speaker = "Draxen",
        text = {
            "He extends a hand. His grip is dry and firm.",
            "'^7A pleasure doing business.'",
            "He produces a credit chit from his coat and places it in",
            "your palm.",
            "'^7A hundred and fifty. As promised. Tell Goran the debt is",
            "non-negotiable. If he resists... well. He knows where I am.'",
            "'^7You've made the practical choice. Don't waste time on guilt.'",
        },
        effects = {
            setStage = { quest = "exchange_pressure", stage = "betrayed_goran" },
            setFlag = "visquis_allied",
            addCredits = 150,
            alignment = -10,
        },
        responses = {
            {
                label = "Business is business.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 11: Hesitation on betrayal  - he pushes
    -- ============================================
    [11] = {
        speaker = "Draxen",
        text = {
            "'^7That's his problem, not yours. And not mine.'",
            "'^7The galaxy doesn't care about fairness. It cares about",
            "who has the credits and who doesn't. Goran chose a dangerous",
            "business in a dangerous place.'",
            "He leans closer. '^7You can walk away feeling noble. Or you",
            "can walk away a hundred and fifty credits richer. Nobility",
            "doesn't buy medpacs.'",
        },
        responses = {
            {
                label = "...Fine. I'll do it.",
                next = 10,
            },
            {
                label = "No. Find someone else to do your dirty work.",
                next = -1,
                alignment = 3,
            },
        },
    },

    -- ============================================
    -- NODE 12: Medical supplies  - field_medicine quest
    -- ============================================
    [12] = {
        speaker = "Draxen",
        text = {
            "'^7Kolto? Of course I have kolto. I have everything that",
            "falls off a transport on this world.'",
            "He opens a crate behind the boulder. Medical supplies.",
            "Enough for weeks.",
            "'^7Doctor Vara's been begging the militia for resupply.",
            "I intercepted a shipment three days ago. Standard practice.'",
            "'^7Now. How badly does she need it?'",
        },
        responses = {
            {
                label = "Name your price.",
                next = 13,
            },
            {
                label = "People are dying while you hoard supplies.",
                next = 14,
            },
            {
                label = "I could take it by force.",
                next = 15,
            },
        },
    },

    -- ============================================
    -- NODE 13: Kolto  - credits or favor
    -- ============================================
    [13] = {
        speaker = "Draxen",
        text = {
            "'^7A hundred credits. Or...'",
            "He pauses, savoring the leverage.",
            "'^7A favor. To be collected later. No questions asked.'",
            "'^7Your choice. Credits are clean. The favor... less so.",
            "But it saves you coin.'",
        },
        responses = {
            {
                label = "Here. A hundred credits. [100 credits]",
                next = 16,
                condition = function(g) return g.player.credits >= 100 end,
                effects = {
                    addCredits = -100,
                    setStage = { quest = "field_medicine", stage = "dealing" },
                    setFlag = "has_exchange_kolto",
                    giveItem = 3,
                },
            },
            {
                label = "I'll owe you a favor.",
                next = 17,
                effects = {
                    setStage = { quest = "field_medicine", stage = "dealing" },
                    setFlag = "has_exchange_kolto",
                    giveItem = 3,
                },
            },
            {
                label = "I have information instead. About what was on that crashed ship.",
                next = 18,
                condition = function(g) return g.player.hasHolocron end,
                alignment = -5,
            },
            {
                label = "Too rich for my blood. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 14: Guilt trip about hoarding medical supplies
    -- ============================================
    [14] = {
        speaker = "Draxen",
        text = {
            "'^7People are always dying. That's what people do.'",
            "His voice is flat. Not cruel  - simply factual.",
            "'^7I didn't create the shortage. The Republic did, when it",
            "abandoned this sector. I'm the one keeping supply lines",
            "open. That costs credits.'",
            "'^7If you want to play hero, pay the price. Otherwise,",
            "stop wasting my time with moral theater.'",
        },
        responses = {
            {
                label = "Fine. What's the price?",
                next = 13,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 15: Threaten to take kolto by force
    -- ============================================
    [15] = {
        speaker = "Draxen",
        text = {
            "His thugs tense. Draxen raises an eyebrow.",
            "'^7You could try. You'd probably even succeed.'",
            "'^7And then what? I stop running supply lines. The next",
            "shipment of food, fuel, spare parts  - none of it arrives.",
            "Khoonda starves slowly instead of quickly.'",
            "'^7Think bigger than one crate of kolto.'",
        },
        responses = {
            {
                label = "...Point taken. What do you want for it?",
                next = 13,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 16: Paid credits for kolto
    -- ============================================
    [16] = {
        speaker = "Draxen",
        text = {
            "He counts the credits with practiced fingers, then nods.",
            "'^7Clean transaction. I appreciate that.'",
            "He pushes the kolto crate toward you.",
            "'^7Tell the doctor it's pharmaceutical grade. None of that",
            "diluted salvage the Republic sends to the Rim.'",
        },
        responses = {
            {
                label = "Pleasure doing business. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 17: Owe Draxen a favor for kolto
    -- ============================================
    [17] = {
        speaker = "Draxen",
        text = {
            "'^7Wise choice. Credits come and go. Favors compound.'",
            "He hands over the kolto. His smile is patient.",
            "'^7I'll find you when I need you. Don't leave Dantooine",
            "before I collect.'",
            "'^7And don't worry. I won't ask anything you can't do.",
            "Probably.'",
        },
        effects = {
            setFlag = "visquis_favor_owed",
            alignment = -3,
        },
        responses = {
            {
                label = "I'll be around. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 18: Trade Holocron info for kolto (dark path)
    -- ============================================
    [18] = {
        speaker = "Draxen",
        text = {
            "His eyes sharpen. The lazy predator is suddenly alert.",
            "'^7The crashed ship. The one the militia is sitting on.'",
            "'^7I've had people trying to get into that wreck for days.",
            "You know what was aboard?'",
            "He leans forward.",
            "'^7Talk. And the kolto is yours.'",
        },
        saevusWhisper = "Power recognizes power. He could be a useful instrument...",
        saevusCondition = function(g) return g.player.paranoia > 25 end,
        responses = {
            {
                label = "A Sith Holocron. Ancient. Valuable beyond measure.",
                next = 19,
                alignment = -8,
                effects = {
                    setFlag = "has_exchange_kolto",
                    paranoia = 10,
                },
            },
            {
                label = "No. Forget I said anything.",
                next = -1,
                alignment = 2,
            },
        },
    },

    -- ============================================
    -- NODE 19: Draxen learns about Holocron
    -- ============================================
    [19] = {
        speaker = "Draxen",
        text = {
            "Silence. For the first time, Draxen is genuinely still.",
            "'^7A Sith Holocron. On Dantooine.'",
            "'^7Do you have any idea what that's worth? The Hutts alone",
            "would pay enough to buy this entire settlement.'",
            "He pushes the kolto crate to you without looking at it.",
            "'^7Take it. Consider it a down payment.'",
            "'^7We'll talk again. Soon. About the Holocron and what it's",
            "worth to the right buyer.'",
        },
        effects = {
            setStage = { quest = "field_medicine", stage = "dealing" },
            setFlag = "visquis_knows_holocron",
            giveItem = 3,
            alignment = -5,
        },
        responses = {
            {
                label = "Don't get ambitious, Draxen.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: Post-alliance  - allied Exchange
    -- ============================================
    [20] = {
        speaker = "Draxen",
        text = {
            "He nods as you approach. Almost warm. Almost.",
            "'^7My favorite independent contractor. Business is good",
            "since our arrangement. Goran paid in full.'",
            "'^7The settlement runs smoother when people know the cost",
            "of defiance.'",
        },
        responses = {
            {
                label = "I need medical supplies. Kolto.",
                next = 12,
                condition = function(g)
                    return RPG.Quest.IsActive(g, "field_medicine")
                        and not RPG.Quest.HasFlag(g, "has_exchange_kolto")
                end,
            },
            {
                label = "Any more work?",
                next = 21,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 21: More work  - teaser for future content
    -- ============================================
    [21] = {
        speaker = "Draxen",
        text = {
            "'^7Not yet. But the galaxy turns, and opportunities present",
            "themselves to those positioned to seize them.'",
            "'^7Stay sharp. I'll have something for you soon enough.'",
        },
        responses = {
            { label = "I'll be around. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 22: Post-backed-off  - grudging respect
    -- ============================================
    [22] = {
        speaker = "Draxen",
        text = {
            "He watches you approach. No warmth, but no hostility.",
            "'^7The one who intervened for Goran. I remember.'",
            "'^7Don't mistake my restraint for weakness. You made a",
            "reasonable argument  - or a convincing threat. Either way,",
            "the math changed. That's all.'",
        },
        responses = {
            {
                label = "I need medical supplies. Kolto.",
                next = 12,
                condition = function(g)
                    return RPG.Quest.IsActive(g, "field_medicine")
                        and not RPG.Quest.HasFlag(g, "has_exchange_kolto")
                end,
            },
            {
                label = "Glad we understand each other.",
                next = -1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 25: Post-hostile  - failed checks, antagonistic
    -- ============================================
    [25] = {
        speaker = "Draxen",
        text = {
            "His thugs shift as you approach. Draxen doesn't move.",
            "'^7You again. Still looking to make trouble?'",
            "'^7My patience has limits. State your business or leave.'",
        },
        responses = {
            {
                label = "I need kolto. Medical supplies.",
                next = 12,
                condition = function(g)
                    return RPG.Quest.IsActive(g, "field_medicine")
                        and not RPG.Quest.HasFlag(g, "has_exchange_kolto")
                end,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Holocron sale path  - Atton companion
    -- ============================================
    [30] = {
        speaker = "Draxen",
        text = {
            "His eyes move between you and Atton. Something passes",
            "between the two men. Old recognition, maybe.",
            "'^7You brought the pilot. Interesting company you keep.'",
            "'^7I hear you have something exceptional. Something ancient.",
            "Something the right collector would mortgage a planet for.'",
        },
        saevusWhisper = "He sees value where others see danger. A kindred pragmatist...",
        saevusCondition = function(g) return g.player.paranoia > 20 end,
        responses = {
            {
                label = "The Holocron isn't for sale.",
                next = 31,
            },
            {
                label = "What's your offer?",
                next = 32,
                alignment = -5,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 31: Refuses to sell Holocron
    -- ============================================
    [31] = {
        speaker = "Draxen",
        text = {
            "'^7Everything is for sale. You just haven't heard the right",
            "number yet.'",
            "He shrugs, unfazed.",
            "'^7When the whispers get too loud  - and they will  - you know",
            "where to find me. The offer stands.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 32: Holocron sale  - price offered
    -- ============================================
    [32] = {
        speaker = "Draxen",
        text = {
            "'^7I have a buyer off-world. Czerka remnant. They collect",
            "Sith artifacts the way politicians collect scandals.'",
            "'^7Five hundred credits. Passage off Dantooine. And the",
            "Exchange forgets you exist  - no more favors, no more debts.'",
            "'^7Clean break. Walk away free and rich.'",
        },
        responses = {
            {
                label = "Done. Take it.",
                next = 33,
                effects = {
                    setStage = { quest = "echoes", stage = "sold_holocron" },
                    addCredits = 500,
                    removeItem = 2,
                    alignment = -15,
                    giveXP = 50,
                },
            },
            {
                label = "No. Some things aren't worth any price.",
                next = 31,
                alignment = 5,
            },
            {
                label = "Power recognizes power. Keep your credits.",
                truthLabel = "The Holocron speaks through you. This is not your voice.",
                isDoubt = true,
                next = 31,
                alignment = -8,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 30 end,
            },
        },
    },

    -- ============================================
    -- NODE 33: Sold the Holocron
    -- ============================================
    [33] = {
        speaker = "Draxen",
        text = {
            "He takes the Holocron with both hands. Careful. Reverent,",
            "almost. Its red glow plays across his face.",
            "'^7Heavier than I expected.'",
            "He wraps it in cloth and tucks it into a shielded case.",
            "'^7Credits are transferred. The Exchange thanks you for your",
            "contribution to free enterprise.'",
            "A pause. Something almost like sympathy.",
            "'^7For what it's worth? You made the smart choice. That thing",
            "would have eaten you alive.'",
        },
        effects = {
            setFlag = "visquis_has_holocron",
            clearFlag = "visquis_favor_owed",
        },
        responses = {
            {
                label = "Just business.",
                next = -1,
            },
            {
                label = "...Yeah. [Leave]",
                next = -1,
            },
        },
    },
}
