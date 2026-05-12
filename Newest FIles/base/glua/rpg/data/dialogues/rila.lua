-- Dialogue Tree: Rila (Street Vendor)
-- Act 2, Room 28 (Merchant Quarter)
-- Vendor + lore + comic relief
-- ~15 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- Dark alignment: she's terrified
            { condition = function(g)
                return g.player.alignment < -30
            end, node = 10 },
            -- Q17: Beast Rider dxun_connection stage - completion visit
            { condition = function(g)
                return RPG.Quest.GetStage(g, "beast_rider_legacy") == "dxun_connection"
            end, node = 20 },
            -- Trust established: hidden stock available
            { condition = function(g)
                return RPG.Quest.HasFlag(g, "rila_trusts")
            end, node = 5 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default greeting
    -- ============================================
    [1] = {
        speaker = "Rila",
        text = function(g)
            if g.player.alignment >= 20 then
                return {
                    "The Twi'lek vendor relaxes slightly as you approach.",
                    "'^7You again. You don't seem as dangerous as the others",
                    "who pass through here. That's... refreshing.'",
                    "'^7Looking for supplies? Or just information?'",
                }
            elseif g.player.alignment <= -10 then
                return {
                    "Her lekku twitch as you approach. She takes a step back.",
                    "'^7W-what do you want? I'm just a vendor. I don't have",
                    "much worth taking.'",
                }
            else
                return {
                    "A nervous Twi'lek peers at you over her stall.",
                    "'^7Starship parts, rations, and genuine Jedi artifacts.'",
                    "She lowers her voice. '^7The artifacts are fake. But the",
                    "rations are real, and that's what matters these days.'",
                }
            end
        end,
        responses = {
            {
                label = "What do you have for sale? [Open Shop]",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 13 } } },
            },
            {
                label = "Heard any rumors about the murders?",
                next = 2,
            },
            {
                label = "[CHA 12] You seem like someone who knows things. Talk to me.",
                next = 4,
                check = { stat = "CHA", dc = 12 },
                failNext = 3,
            },
            {
                label = "Just browsing. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Murder rumors
    -- ============================================
    [2] = {
        speaker = "Rila",
        text = {
            "She glances left and right before answering.",
            "'^7Murders? Which ones? There have been four this week.",
            "All different parts of the city.'",
            "'^7The guards say it's gang violence, but I grew up in",
            "the Exchange. I know what gang kills look like.'",
            "'^7This is different. The victims were all researchers --",
            "people digging into old Jedi records. Beast Rider",
            "histories. Freedon Nadd's tomb.'",
            "'^7Someone doesn't want those records found.'",
        },
        responses = {
            {
                label = "What's a Beast Rider?",
                next = 6,
            },
            {
                label = "Who were the victims?",
                next = 7,
            },
            {
                label = "Thanks for the info. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 3: CHA check fail
    -- ============================================
    [3] = {
        speaker = "Rila",
        text = {
            "Her lekku flatten defensively.",
            "'^7I know things? I'm a junk vendor, not an informant.",
            "You want rumors, buy a drink at the cantina.'",
        },
        responses = {
            {
                label = "Fair enough. What do you have for sale? [Open Shop]",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 13 } } },
            },
            {
                label = "My mistake. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 4: CHA check SUCCESS - Exchange past
    -- ============================================
    [4] = {
        speaker = "Rila",
        text = {
            "She studies you for a long moment. Then sighs.",
            "'^7Fine. You've got that look. The one that says you'll",
            "find out anyway, so I might as well talk.'",
            "'^7I used to run with the Exchange. Small time -- courier",
            "work, information brokering. I got out when Visquis",
            "went down on Nar Shaddaa. Came to Onderon. Clean start.'",
            "'^7But old habits die hard. I still hear things.'",
        },
        effects = {
            setFlag = "rila_trusts",
        },
        responses = {
            {
                label = "What have you heard about the murders?",
                next = 2,
            },
            {
                label = "Tell me about the Beast Riders.",
                next = 6,
            },
            {
                label = "Show me the good stock. [Open Shop]",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 13 } } },
            },
        },
    },

    -- ============================================
    -- NODE 5: Trust established - hidden stock
    -- ============================================
    [5] = {
        speaker = "Rila",
        text = {
            "She brightens when she sees you.",
            "'^7My favorite customer. Looking for the usual? Or',",
            "she lowers her voice, '^7the special inventory?'",
        },
        responses = {
            {
                label = "Show me everything. [Open Shop]",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 13 } } },
            },
            {
                label = "Any new rumors?",
                next = 8,
            },
            {
                label = "Tell me about Freedon Nadd.",
                next = 9,
            },
            {
                label = "Just passing through. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 6: Beast Rider lore
    -- ============================================
    [6] = {
        speaker = "Rila",
        text = {
            "'^7The Beast Riders? Ancient history. Before the Republic",
            "pacified Onderon, the Beast Riders lived in the jungle",
            "moon Dxun and flew drexls -- massive predators.'",
            "'^7They worshipped Freedon Nadd, a fallen Jedi who became",
            "a Sith Lord. His tomb is on Dxun. People still go looking",
            "for it. Most don't come back.'",
            "'^7The Beast Riders used charms carved from drexl bone to",
            "bond with their mounts. There's a Mandalorian-era one in",
            "the Iziz archives. Or there was -- it was stolen last month.'",
        },
        effects = {
            action = function(player, game)
                if not RPG.Quest.IsActive(game, "beast_rider_legacy") and
                   not RPG.Quest.IsComplete(game, "beast_rider_legacy") then
                    RPG.Quest.Start(player, "beast_rider_legacy")
                    RPG.Quest.SetStage(player, "beast_rider_legacy", "rumor")
                end
            end,
        },
        responses = {
            {
                label = "A stolen Beast Rider artifact? Interesting.",
                next = 7,
            },
            {
                label = "Thanks for the history lesson. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 7: Murder victims + Q17 connection
    -- ============================================
    [7] = {
        speaker = "Rila",
        text = {
            "'^7Three archivists and a museum curator. All killed the",
            "same way -- throats torn out, claw marks everywhere.'",
            "'^7But here's the thing: they were all researching the",
            "same subject. Beast Rider relics. Freedon Nadd. The",
            "connection between Onderon and the dark side.'",
            "'^7Someone is killing people to stop them from finding",
            "something. Or to keep something hidden.'",
        },
        responses = {
            {
                label = "Could it be connected to the Holocron?",
                next = 8,
                condition = function(g) return g.player.hasHolocron end,
            },
            {
                label = "I'll look into it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 8: Holocron connection / new rumors
    -- ============================================
    [8] = {
        speaker = "Rila",
        text = {
            "She goes very still.",
            "'^7Holocron? You're carrying a... you know what, I don't",
            "want to know. I really don't.'",
            "'^7But if you're asking whether Onderon's dark side history",
            "and your artifact are connected -- yes. Obviously.'",
            "'^7This world has been a nexus of dark side power since",
            "Freedon Nadd's time. Whatever's in your Holocron, it",
            "chose Onderon for a reason.'",
        },
        responses = {
            {
                label = "Tell me about Freedon Nadd.",
                next = 9,
            },
            {
                label = "Thanks, Rila. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 9: Freedon Nadd + Exchange lore
    -- ============================================
    [9] = {
        speaker = "Rila",
        text = {
            "'^7Freedon Nadd. Fallen Jedi, became a Sith Lord,",
            "conquered Onderon about 4400 BBY. His tomb is on Dxun.'",
            "'^7The Beast Riders worshipped him. The Sith War was fought",
            "partly over his remains. Exar Kun, Ulic Qel-Droma --",
            "big names, bad times.'",
            "'^7The Exchange tried to raid his tomb once. Sent twelve",
            "men. One came back. Blind, raving about shadows that",
            "moved on their own.'",
            "She shivers. '^7I don't go near Dxun.'",
        },
        responses = {
            {
                label = "Smart. Neither should I. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: Dark alignment - terrified
    -- ============================================
    [10] = {
        speaker = "Rila",
        text = {
            "She sees you coming and starts packing her stall.",
            "'^7No. No no no. Stay away from me.'",
            "'^7I've seen what you are. The guards talk about you.",
            "The refugees whisper about purple eyes in the dark.'",
            "'^7I'm leaving. Right now. Don't follow me.'",
        },
        effects = {
            setFlag = "rila_fled",
        },
        responses = {
            {
                label = "Wait -- I need information.",
                next = 11,
            },
            {
                label = "Then run. [Leave]",
                next = -1,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 11: Trying to stop her from fleeing
    -- ============================================
    [11] = {
        speaker = "Rila",
        text = {
            "She clutches her bag, backing away.",
            "'^7Information? From me? What could I possibly tell you",
            "that you don't already know? You're the one with the --'",
            "She stops herself. '^7No. I'm not saying it. I'm gone.'",
            "She turns and pushes through the crowd.",
            "'^7Good luck with whatever you are. I want no part of it.'",
        },
        responses = {
            {
                label = "[She's gone. Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: Q17 - Beast Rider completion visit
    -- ============================================
    [20] = {
        speaker = "Rila",
        text = {
            "She looks up as you approach, reading your expression.",
            "'^7You found something. I can tell.'",
            "'^7The Beast Rider artifact, the Dxun connection --",
            "you talked to Jeth, didn't you?'",
        },
        responses = {
            {
                label = "Onderon's dark side history runs deep.",
                next = 21,
            },
            {
                label = "The Holocron chose this world on purpose.",
                next = 21,
            },
        },
    },

    -- ============================================
    -- NODE 21: Q17 - Beast Rider legacy confirmed
    -- ============================================
    [21] = {
        speaker = "Rila",
        text = {
            "She nods slowly.",
            "'^7Freedon Nadd, the Beast Riders, the Mandalorian Wars,",
            "the Sith Wars -- this world has been soaked in the dark",
            "side for millennia. Layer after layer.'",
            "'^7The Beast Rider talisman wasn't just stolen. Someone",
            "wanted to reactivate that old connection. Or destroy the",
            "evidence that it existed.'",
            "'^7Either way, now you know: whatever is in your Holocron",
            "didn't come to Onderon by accident. It came home.'",
        },
        effects = {
            setStage = { quest = "beast_rider_legacy", stage = "complete" },
        },
        responses = {
            {
                label = "Thanks, Rila. That's... not reassuring. [Leave]",
                next = -1,
            },
            {
                label = "Show me what you have for sale. [Open Shop]",
                next = -1,
                effects = { startState = { state = "shop", data = { vendorNpcId = 13 } } },
            },
        },
    },
}
