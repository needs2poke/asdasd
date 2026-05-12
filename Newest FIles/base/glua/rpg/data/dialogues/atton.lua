-- Dialogue Tree: Atton Rand
-- Complex companion, ex-Sith assassin  - Room 3
-- Multi-layer trust, stat checks, Doubt responses
-- ~30 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- P1: Terminal states
            { condition = function(g) return RPG.Quest.HasFlag(g, "atton_companion") end, node = 90 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "atton_rejected") end, node = 86 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "atton_arrested") end, node = 85 },
            { condition = function(g) return RPG.Quest.HasFlag(g, "atton_blackmailed") end, node = 80 },
            -- P2: Active gambit (high-priority stages)
            { condition = function(g) return RPG.Quest.GetStage(g, "atton_gambit") == "confrontation" end, node = 60 },
            { condition = function(g)
                return RPG.Quest.GetStage(g, "atton_gambit") == "trust_building"
                    and RPG.Quest.HasFlag(g, "atton_trust_ready")
                end, node = 50 },
            -- P3: Completed quest reactions (one-time interjections)
            { condition = function(g) return RPG.Quest.IsComplete(g, "shadows_trail") and not RPG.Quest.HasFlag(g, "atton_shadows_discussed") end, node = 100 },
            -- P4: Active gambit (lower-priority stages)
            { condition = function(g) return RPG.Quest.GetStage(g, "atton_gambit") == "trust_building" end, node = 30 },
            { condition = function(g) return RPG.Quest.IsActive(g, "atton_gambit") end, node = 20 },
            -- P5: Has Holocron (gambit trigger)
            { condition = function(g) return g.player.hasHolocron end, node = 10 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default (before Holocron)
    -- ============================================
    [1] = {
        speaker = "Atton Rand",
        text = {
            "A scarred man hunched over his drink. He doesn't look up.",
            "'^7Don't stare. And don't ask about the wars.'",
            "He takes another sip.",
            "'^7Unless you're buying.'",
        },
        responses = {
            {
                label = "Buy you a drink?",
                next = 2,
            },
            {
                label = "What brings you to Dantooine?",
                next = 3,
            },
            {
                label = "You look like you can handle yourself.",
                next = 4,
            },
            {
                label = "Fine. Forget I said anything. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Buy him a drink
    -- ============================================
    [2] = {
        speaker = "Atton Rand",
        text = {
            "He accepts with a nod. Almost friendly.",
            "'^7You know what I like about Dantooine? Nobody asks questions.'",
            "'^7Everybody's too busy surviving to care about where you came",
            "from or what you did. It's refreshing.'",
        },
        responses = {
            {
                label = "What DID you do?",
                next = 3,
            },
            {
                label = "I'll drink to that. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 3: What brings you here?
    -- ============================================
    [3] = {
        speaker = "Atton Rand",
        text = {
            "'^7Freelance piloting. Hauled cargo until the ship broke down.",
            "Stuck here until I can afford repairs.'",
            "He says it smoothly. Too smoothly.",
            "'^7You ever notice the good people always ask for volunteers?'",
        },
        responses = {
            {
                label = "[CHA 12] That story has holes. What are you really doing here?",
                next = 5,
                check = { stat = "CHA", dc = 12 },
                failNext = 6,
            },
            {
                label = "Fair enough. Everyone's got a past.",
                next = 7,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 4: "You look capable"
    -- ============================================
    [4] = {
        speaker = "Atton Rand",
        text = {
            "A flicker of something behind his eyes. Pride? Wariness?",
            "'^7I get by. Survived the wars, survived the aftermath.",
            "That's more than most can say.'",
            "'^7Don't mistake surviving for capability. Sometimes it's",
            "just dumb luck and faster reflexes than the other guy.'",
        },
        responses = {
            {
                label = "I could use someone like you.",
                next = 7,
            },
            {
                label = "[WIS 14] I sense something about you. Something... suppressed.",
                next = 8,
                check = { stat = "WIS", dc = 14 },
                failNext = 6,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 5: CHA check SUCCESS  - catches inconsistencies
    -- ============================================
    [5] = {
        speaker = "Atton Rand",
        text = {
            "His jaw tightens. You hit a nerve.",
            "'^7Everybody's got a story they don't want to tell.",
            "Mine's just... longer than most.'",
            "'^7Look. I don't trust people. Nothing personal. But you're",
            "not stupid, and that makes you either useful or dangerous.'",
        },
        responses = {
            {
                label = "I'm offering a partnership, not an interrogation.",
                next = 7,
            },
            {
                label = "I'll find out eventually.",
                next = 6,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 6: Deflection (catch-all for failed checks)
    -- ============================================
    [6] = {
        speaker = "Atton Rand",
        text = {
            "The wall goes back up. Smooth and impenetrable.",
            "'^7Look, I'm just a pilot who drinks too much. Nothing",
            "interesting here. Trust me.'",
        },
        responses = {
            { label = "If you say so. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 7: Building rapport
    -- ============================================
    [7] = {
        speaker = "Atton Rand",
        text = {
            "He studies you for a long moment.",
            "'^7You know what? You're all right. Don't let anyone tell",
            "you otherwise.'",
            "'^7If you need a pilot  - when you're leaving this rock  -",
            "look me up. I know a few things about getting off planets",
            "in a hurry.'",
        },
        responses = {
            { label = "I'll be back. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 8: WIS check SUCCESS  - senses Force sensitivity
    -- ============================================
    [8] = {
        speaker = "Atton Rand",
        text = {
            "He goes very still. The casual act drops for a heartbeat.",
            "'^7...Don't do that.'",
            "His voice is low, almost a whisper.",
            "'^7Whatever you just felt  - forget it. Some doors are closed",
            "for a reason.'",
        },
        effects = { setFlag = "atton_sensed_force" },
        responses = {
            {
                label = "You're Force-sensitive.",
                next = 9,
            },
            {
                label = "I'm sorry. I didn't mean to pry.",
                next = 7,
                alignment = 2,
            },
        },
    },

    -- ============================================
    -- NODE 9: Confronted about Force
    -- ============================================
    [9] = {
        speaker = "Atton Rand",
        text = {
            "'^7Don't.'",
            "Real anger now. Maybe fear.",
            "'^7I'm not a Jedi. I'm not a Sith. I'm nothing.'",
            "'^7You want a Force-using companion? Talk to a wall.",
            "It'll be more responsive.'",
        },
        responses = {
            {
                label = "We all have things we're running from.",
                next = 7,
                alignment = 2,
            },
            {
                label = "Running from what you are makes it worse.",
                next = 6,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 10: After player has Holocron (quest trigger)
    -- ============================================
    [10] = {
        speaker = "Atton Rand",
        text = {
            "He looks up as you enter. Something different in his eyes.",
            "'^7You found something out there, didn't you?'",
            "He's watching you too carefully for a casual drunk.",
            "'^7I can tell. You carry yourself different. Heavier.'",
        },
        saevusWhisper = "He knows what you carry. He's been close to such things before...",
        saevusCondition = function(g) return g.player.paranoia > 30 end,
        responses = {
            {
                label = "What do you know about Sith artifacts?",
                next = 11,
            },
            {
                label = "You're imagining things.",
                next = 6,
            },
            {
                label = "He knows too much. He's dangerous.",
                truthLabel = "The Holocron wants you to distrust him. He could be an ally.",
                isDoubt = true,
                next = 14,
                alignment = -5,
                condition = function(g) return g.player.paranoia > 20 end,
            },
        },
    },

    -- ============================================
    -- NODE 11: Asks about Sith artifacts  - too knowledgeable
    -- ============================================
    [11] = {
        speaker = "Atton Rand",
        text = {
            "He doesn't flinch. That's the tell.",
            "'^7More than a freelance pilot should. Let's leave it at that.'",
            "'^7I know they're dangerous. I know they change people.",
            "And I know you shouldn't be carrying one around like a",
            "good luck charm.'",
        },
        effects = { startQuest = "atton_gambit" },
        responses = {
            {
                label = "How do you know I have one?",
                next = 12,
            },
            {
                label = "Then help me. You clearly know more than you're saying.",
                next = 13,
            },
            {
                label = "Mind your own business.",
                next = 6,
                alignment = -3,
            },
        },
    },

    [12] = {
        speaker = "Atton Rand",
        text = {
            "'^7Because I've seen the look before. That mix of fascination",
            "and fear. You're not the first and you won't be the last.'",
            "He finishes his drink in one motion.",
            "'^7Look. I'm not going to tell you what to do with it.",
            "But I can tell you this: it's smarter than you think.'",
        },
        responses = {
            {
                label = "I can handle it.",
                next = 13,
            },
            {
                label = "What happened to the last person you saw with one?",
                next = 15,
            },
        },
    },

    [13] = {
        speaker = "Atton Rand",
        text = {
            "'^7Maybe. We'll see.'",
            "'^7Do me a favor. Come back when you've been around the",
            "settlement some more. Help some people. Get your head",
            "straight before that thing gets its hooks in too deep.'",
        },
        effects = {
            setStage = { quest = "atton_gambit", stage = "trust_building" },
        },
        responses = {
            { label = "I'll be back. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 14: Doubt option  - hostile toward Atton
    -- ============================================
    [14] = {
        speaker = "Atton Rand",
        text = {
            "Your words come out harder than intended. The Holocron's edge.",
            "Atton leans back, hands up.",
            "'^7Whoa. Whatever's talking to you right now? That's not your voice.'",
            "'^7I know because I've heard it before. In my own head.'",
        },
        effects = { startQuest = "atton_gambit" },
        responses = {
            {
                label = "...What do you mean, your own head?",
                next = 15,
            },
            {
                label = "Shut up. [Leave]",
                next = -1,
                alignment = -3,
            },
        },
    },

    -- ============================================
    -- NODE 15: Cryptic hint about his past
    -- ============================================
    [15] = {
        speaker = "Atton Rand",
        text = {
            "He goes quiet. Really quiet. The drunk act is entirely gone.",
            "'^7Some things you don't talk about in cantinas.'",
            "'^7Come back later. When you've proven you're not going to",
            "sell my secrets to the highest bidder.'",
        },
        effects = {
            setStage = { quest = "atton_gambit", stage = "trust_building" },
        },
        responses = {
            { label = "Fair. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 20: Quest active, general check-in
    -- ============================================
    [20] = {
        speaker = "Atton Rand",
        text = {
            "'^7Still here? Good. Means the Holocron hasn't eaten you yet.'",
            "He's half-joking. Maybe less than half.",
        },
        responses = {
            {
                label = "I need your help with something.",
                next = 21,
            },
            {
                label = "Just checking in. [Leave]",
                next = -1,
            },
        },
    },

    [21] = {
        speaker = "Atton Rand",
        text = {
            "'^7Help with what? I don't do charity work and I definitely",
            "don't do heroics. But I might make an exception if the",
            "price is right.'",
        },
        responses = {
            { label = "Forget it. You're not ready. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 30: Trust building  - not ready yet
    -- ============================================
    [30] = {
        speaker = "Atton Rand",
        text = {
            "'^7Back again. How's the hero business?'",
            "He's watching you, measuring something.",
            "'^7You've been busy. People are talking about you.'",
        },
        responses = {
            {
                label = "People talk. It doesn't mean much.",
                next = 31,
            },
            {
                label = "Are you ready to talk? Really talk?",
                next = 32,
            },
        },
    },

    [31] = {
        speaker = "Atton Rand",
        text = {
            "'^7Smart attitude. Keep it.'",
            "'^7Give it time. Help some people. Show me you're the real",
            "deal and not just another would-be savior with a death wish.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    [32] = {
        speaker = "Atton Rand",
        text = {
            "'^7Not yet. But soon.'",
            "'^7Finish what you started with Adare. Help Goran, Vara,",
            "whoever needs it. When you've proven something... I'll talk.'",
        },
        responses = {
            { label = "I'll be back. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 50: Trust building ready  - opens up
    -- ============================================
    [50] = {
        speaker = "Atton Rand",
        text = {
            "He's sober. First time you've seen that.",
            "'^7Sit down.'",
            "No humor. No deflection.",
            "'^7You've earned an explanation. And I... need to tell someone.'",
            "'^7Before that thing you're carrying does to you what it",
            "did to the people I used to work with.'",
        },
        effects = {
            setStage = { quest = "atton_gambit", stage = "confrontation" },
        },
        responses = {
            {
                label = "I'm listening.",
                next = 60,
            },
        },
    },

    -- ============================================
    -- NODE 60: THE CONFRONTATION  - Atton's truth
    -- ============================================
    [60] = {
        speaker = "Atton Rand",
        text = {
            "'^7I wasn't a pilot. I wasn't a smuggler. I wasn't a freelancer.'",
            "'^7During the Jedi Civil War, I was a Sith assassin.'",
            "'^7Specialized in killing Jedi.'",
            "The words hang in the air like blaster smoke.",
        },
        responses = {
            {
                label = "...Keep talking.",
                next = 61,
            },
            {
                label = "You killed Jedi.",
                next = 62,
            },
        },
    },

    [61] = {
        speaker = "Atton Rand",
        text = {
            "'^7They trained us to resist Force persuasion. To recognize",
            "precognition patterns and fight around them. To break a",
            "Jedi's concentration before they could use the Force.'",
            "'^7I was good at it. And the worst part?'",
            "His voice cracks.",
            "'^7Part of me liked it.'",
        },
        responses = {
            {
                label = "What made you stop?",
                next = 63,
            },
            {
                label = "You're a monster.",
                next = 65,
                alignment = -3,
            },
        },
    },

    [62] = {
        speaker = "Atton Rand",
        text = {
            "'^7Don't look at me like that. You're carrying a Sith Holocron",
            "and you think YOU get to judge ME?'",
            "He breathes. Controls himself.",
            "'^7Yes. I killed Jedi. Do you want to hear why I stopped,",
            "or do you want to keep your moral high ground?'",
        },
        responses = {
            {
                label = "Why did you stop?",
                next = 63,
            },
            {
                label = "Nothing you say can excuse what you did.",
                next = 65,
                alignment = -5,
            },
        },
    },

    -- ============================================
    -- NODE 63: Why he defected  - the Jedi's dying bond
    -- ============================================
    [63] = {
        speaker = "Atton Rand",
        text = {
            "'^7There was a Jedi. A woman. We captured her on Dxun.'",
            "'^7I was... interrogating her. Standard procedure. Break",
            "the connection to the Force, make them vulnerable.'",
            "'^7But she did something. As she was dying, she reached",
            "out through the Force. Not to fight. Not to plead.'",
            "'^7She showed me what I was. Through her eyes.'",
        },
        responses = {
            {
                label = "What did you see?",
                next = 64,
            },
        },
    },

    [64] = {
        speaker = "Atton Rand",
        text = {
            "'^7Everything. Every life I'd taken. Every choice that",
            "led me to that cell. She didn't judge me. She just...",
            "showed me. And I felt it. All of it.'",
            "'^7I walked out. Left the Sith. Left everything.'",
            "'^7Been running ever since.'",
            "He looks at you. Raw. Honest. Dangerous.",
            "'^7So. Now you know. What happens next is up to you.'",
        },
        responses = {
            {
                label = "Everyone deserves a chance to change. I forgive you.",
                next = 66,
                alignment = 10,
            },
            {
                label = "I should tell Adare. She needs to know.",
                next = 67,
                alignment = 2,
            },
            {
                label = "This is valuable information. You owe me now.",
                next = 68,
                alignment = -10,
            },
            {
                label = "His guilt makes him useful. The Holocron approves.",
                truthLabel = "The Holocron sees a tool. But this man is more than his past.",
                isDoubt = true,
                next = 68,
                alignment = -10,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 20 end,
            },
        },
    },

    -- ============================================
    -- NODE 65: Rejected him (terminal — sets flag + fails quest)
    -- ============================================
    [65] = {
        speaker = "Atton Rand",
        text = {
            "The wall comes back. Harder than before.",
            "'^7Yeah. I figured you'd say that.'",
            "He picks up his drink.",
            "'^7Get out. We're done.'",
        },
        effects = {
            setFlag = "atton_rejected",
            setStage = { quest = "atton_gambit", stage = "rejected" },
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 66: Forgiven  - companion route
    -- ============================================
    [66] = {
        speaker = "Atton Rand",
        text = {
            "He stares at you. Disbelief. Then something else.",
            "Something he hasn't felt in a long time.",
            "'^7You... you mean that, don't you?'",
            "A long silence.",
            "'^7Then I'm coming with you. Wherever you're headed.'",
            "'^7I know how Sith Holocrons work. I know how they think.",
            "Maybe I can help you resist it. Or at least watch your back",
            "when it gets too loud in your head.'",
        },
        effects = {
            setFlag = "atton_companion",
            giveXP = 200,
            addCompanion = "atton",
        },
        responses = {
            {
                label = "Welcome aboard, Atton.",
                next = 69,
            },
        },
    },

    -- ============================================
    -- NODE 67: Turned in to Adare
    -- ============================================
    [67] = {
        speaker = "Atton Rand",
        text = {
            "The light goes out of his eyes.",
            "'^7I should have kept running.'",
            "He doesn't resist. Just stands up, slowly.",
            "'^7Do what you have to do. I'm tired of running anyway.'",
        },
        effects = {
            setFlag = "atton_arrested",
            giveXP = 100,
        },
        responses = {
            {
                label = "I'm sorry. It's the right thing to do.",
                next = -1,
                alignment = 2,
            },
            {
                label = "[Say nothing]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 68: Blackmailed
    -- ============================================
    [68] = {
        speaker = "Atton Rand",
        text = {
            "His expression goes flat. Dead. The assassin's mask.",
            "'^7So that's how it is.'",
            "'^7Fine. You've got leverage. I'll do what you want.'",
            "'^7But remember this: I was very, very good at killing",
            "people. And blackmail has an expiration date.'",
        },
        effects = {
            setFlag = "atton_blackmailed",
            giveXP = 150,
            addCompanion = "atton",
            addCompanionBlackmailed = true,
        },
        responses = {
            {
                label = "As long as you remember who's in charge.",
                next = -1,
                alignment = -5,
            },
        },
    },

    -- ============================================
    -- NODE 69: Companion accepted
    -- ============================================
    [69] = {
        speaker = "Atton Rand",
        text = {
            "For the first time, a real smile.",
            "'^7Well then. When do we leave this dump?'",
            "'^7And for the record? That Holocron talks to you again,",
            "tell me. I know a few tricks for shutting them up.'",
        },
        responses = {
            { label = "Good to have you, Atton. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 80: Post-blackmail  - resentful compliance
    -- ============================================
    [80] = {
        speaker = "Atton Rand",
        text = {
            "'^7What do you need?'",
            "Cold. Professional. The warmth is gone.",
        },
        responses = {
            {
                label = "Just checking on you.",
                next = 81,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    [81] = {
        speaker = "Atton Rand",
        text = {
            "'^7Don't pretend to care. It insults us both.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 86: Post-rejection  - cold shoulder (terminal)
    -- ============================================
    [86] = {
        speaker = "Atton Rand",
        text = {
            "He glances up, then back at his drink. No warmth.",
            "'^7We're done talking. I told you that already.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 85: Post-arrest  - empty seat
    -- ============================================
    [85] = {
        speaker = "Narrator",
        text = {
            "The seat where Atton sat is empty. His drink is still there,",
            "half-finished. The bartender hasn't cleared it yet.",
            "The cantina feels emptier without him.",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 90: Companion  - travel companion dialogue
    -- ============================================
    [90] = {
        speaker = "Atton Rand",
        text = {
            "'^7Hey. Ready to get off this rock?'",
            "He looks... lighter. Not by much. But enough.",
        },
        responses = {
            {
                label = "Almost. Just wrapping up loose ends.",
                next = 91,
            },
            {
                label = "The Holocron's been louder lately.",
                next = 92,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 30 end,
            },
            {
                label = "I finished what Saevus started.",
                next = 94,
                condition = function(g) return RPG.Quest.IsComplete(g, "ghosts_enclave") end,
            },
            {
                label = "Did you ever travel with anyone?",
                next = 110,
                condition = function(g) return not RPG.Quest.HasFlag(g, "atton_meetra_discussed") end,
            },
            {
                label = "Let's go. [Leave]",
                next = -1,
            },
        },
    },

    [91] = {
        speaker = "Atton Rand",
        text = {
            "'^7Take your time. I'm not going anywhere.'",
            "'^7Well, not without you, anyway. That was the deal.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },

    [92] = {
        speaker = "Atton Rand",
        text = {
            "His expression darkens.",
            "'^7That's not good. The louder it gets, the harder it is",
            "to tell its voice from your own.'",
            "'^7Old trick from my assassin days: when the dark side",
            "whispers, count backwards from ten. Focus on the numbers.",
            "It can't corrupt what it can't reach.'",
        },
        responses = {
            {
                label = "Thanks, Atton. That actually helps.",
                next = -1,
                alignment = 2,
            },
            {
                label = "Maybe the whispers are right.",
                next = 93,
                alignment = -5,
            },
        },
    },

    [93] = {
        speaker = "Atton Rand",
        text = {
            "'^7No. They're not. Trust me.'",
            "'^7I believed that once. It cost me everything.'",
            "'^7Don't make my mistakes. You're better than that.'",
        },
        responses = {
            { label = "...Yeah. Yeah, you're right. [Leave]", next = -1, alignment = 3 },
            { label = "[Leave without answering]", next = -1 },
        },
    },

    [94] = {
        speaker = "Atton Rand",
        text = {
            "His smile disappears in an instant.",
            "'^7Okay. Define \"finished.\"'",
            "'^7Because in my experience, Sith voices don't do endings.",
            "They do installments.'",
        },
        responses = {
            {
                label = "I sealed the Holocron and cut him off.",
                next = 95,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_destroy") end,
                alignment = 2,
            },
            {
                label = "I took what I needed and kept control.",
                next = 96,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_balance") end,
            },
            {
                label = "I accepted his teachings.",
                next = 97,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_embrace") end,
                alignment = -4,
            },
            { label = "Never mind. [Leave]", next = -1 },
        },
    },

    [95] = {
        speaker = "Atton Rand",
        text = {
            "Atton nods, genuinely impressed.",
            "'^7Good. That's hard to do.'",
            "'^7Most people think resisting the dark side means never hearing it.",
            "Real trick is hearing it and not flinching.'",
        },
        responses = {
            { label = "Guess we both learned that the hard way. [Leave]", next = -1, alignment = 2 },
        },
    },

    [96] = {
        speaker = "Atton Rand",
        text = {
            "'^7Controlled dark side. That's like controlled thermal detonator.'",
            "He points at you with his drink.",
            "'^7Possible? Sure. Great way to lose fingers? Also sure.'",
            "'^7Just tell me when it starts sounding reasonable. That's when it's winning.'",
        },
        responses = {
            { label = "Fair warning. [Leave]", next = -1, alignment = 1 },
        },
    },

    [97] = {
        speaker = "Atton Rand",
        text = {
            "He goes still. No sarcasm left.",
            "'^7Then listen carefully.'",
            "'^7First the voice helps. Then it flatters. Then one day you wake up",
            "and everything cruel sounds practical.'",
            "'^7Don't become who I used to be.'",
        },
        responses = {
            { label = "I'll remember that. [Leave]", next = -1, alignment = 1 },
            { label = "Maybe practicality is what this galaxy needs. [Leave]", next = -1, alignment = -3 },
        },
    },

    -- ============================================
    -- NODE 100: Q3 Reaction  - Unknown Regions coordinates
    -- ============================================
    [100] = {
        speaker = "Atton Rand",
        text = {
            "'^7So. Unknown Regions coordinates. From a dead Jedi Shadow.'",
            "He swirls his drink. Doesn't look up.",
            "'^7Want some advice from someone who's been to places the",
            "Republic pretends don't exist?'",
        },
        responses = {
            {
                label = "You've been to the Unknown Regions?",
                next = 101,
            },
            {
                label = "How do you even know about that?",
                next = 101,
            },
            {
                label = "Not interested. [Leave]",
                next = -1,
                setFlag = "atton_shadows_discussed",
            },
        },
    },

    -- ============================================
    -- NODE 101: Atton's past bleeds through
    -- ============================================
    [101] = {
        speaker = "Atton Rand",
        text = {
            "'^7I've been near them. Close enough to know there's a reason",
            "the hyperlanes stop where they stop.'",
            "'^7The navigational hazards aren't natural. Someone put them",
            "there. Thousands of years ago. Old tech. Older than the",
            "Republic.'",
            "'^7Keeping people out... or keeping something in.'",
            "'^7The Sith didn't hide in the Unknown Regions because it was",
            "convenient. They hid because whatever's ALREADY there let them.'",
        },
        responses = {
            {
                label = "How do you know this?",
                next = 102,
            },
            {
                label = "The Shadow had a contact inside the academy.",
                next = 103,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadow_full_decode") end,
            },
            {
                label = "That's... unsettling. [Leave]",
                next = -1,
                setFlag = "atton_shadows_discussed",
                alignment = 1,
            },
        },
    },

    -- ============================================
    -- NODE 102: Deflection + WIS check
    -- ============================================
    [102] = {
        speaker = "Atton Rand",
        text = {
            "'^7I hear things. Cantinas, mostly. Drunk smugglers talk",
            "too much.'",
        },
        responses = {
            {
                label = "[WIS 14] You're lying. You weren't just hearing things  - you were there.",
                next = 102.5,
                check = { stat = "WIS", dc = 14 },
                failNext = 102.6,
            },
            {
                label = "The Shadow had a contact inside the academy.",
                next = 103,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadow_full_decode") end,
            },
            {
                label = "Fair enough. [Leave]",
                next = -1,
                setFlag = "atton_shadows_discussed",
            },
        },
    },

    -- ============================================
    -- NODE 102.5: WIS check SUCCESS
    -- ============================================
    [102.5] = {
        speaker = "Atton Rand",
        text = {
            "He goes quiet. Really quiet.",
            "'^7...Not everyone who served Revan did it because they",
            "believed. Some of us just didn't know how to stop.'",
            "He catches himself. Takes a long drink.",
            "'^7Forget I said that. Too much Juma.'",
        },
        effects = { setFlag = "atton_unknown_regions_hint" },
        responses = {
            {
                label = "The Shadow had a contact inside the academy.",
                next = 103,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadow_full_decode") end,
            },
            {
                label = "Your secret's safe with me. [Leave]",
                next = -1,
                alignment = 2,
                setFlag = "atton_shadows_discussed",
            },
        },
    },

    -- ============================================
    -- NODE 102.6: WIS check FAILURE
    -- ============================================
    [102.6] = {
        speaker = "Atton Rand",
        text = {
            "'^7Believe what you want. I'm just a pilot with bad habits",
            "and worse taste in drinks.'",
        },
        responses = {
            {
                label = "The Shadow had a contact inside the academy.",
                next = 103,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadow_full_decode") end,
            },
            {
                label = "If you say so. [Leave]",
                next = -1,
                setFlag = "atton_shadows_discussed",
            },
        },
    },

    -- ============================================
    -- NODE 103: Dead drop recognition
    -- ============================================
    [103] = {
        speaker = "Atton Rand",
        text = {
            "He sets his drink down. Actually looks at you.",
            "'^7A dead drop? With secondary coordinates?'",
            "'^7That's a Republic Intelligence double-extraction format.",
            "I've... heard of it.'",
            "'^7If someone's been inside a Sith academy long enough to",
            "run a dead drop, they're either the bravest person in the",
            "galaxy or they turned years ago and this is a trap.'",
            "'^7Either way  - if you're going out there, you better be",
            "ready for both.'",
        },
        responses = {
            {
                label = "You know a lot about intelligence protocols for a 'pilot.'",
                next = -1,
                setFlag = "atton_shadows_discussed",
                alignment = 1,
            },
            {
                label = "I'll be ready. [Leave]",
                next = -1,
                setFlag = "atton_shadows_discussed",
            },
        },
    },

    -- ============================================
    -- NODE 110: Meetra Surik  - companion trust dialogue
    -- ============================================
    [110] = {
        speaker = "Atton Rand",
        text = {
            "He goes quiet. A real quiet, not the fake kind.",
            "'^7There was someone. A woman. I heard she'd",
            "lost her connection to the Force and got",
            "it back.'",
            "'^7Stronger than anyone I've ever met.'",
            "'^7Word is she went after Revan  - said she",
            "owed him that much.'",
            "'^7[pause] That was two years ago.'",
            "'^7She hasn't come back.'",
            "'^7Nobody ever comes back from the Unknown",
            "Regions.'",
        },
        effects = { setFlag = "atton_meetra_discussed" },
        responses = {
            {
                label = "I'm sorry, Atton.",
                next = -1,
                alignment = 2,
            },
            {
                label = "Maybe she's still out there.",
                next = 111,
            },
        },
    },

    -- ============================================
    -- NODE 111: Meetra followup  - bleak hope
    -- ============================================
    [111] = {
        speaker = "Atton Rand",
        text = {
            "'^7Maybe.'",
            "A long pause.",
            "'^7That's the worst part, isn't it? Maybe.'",
        },
        responses = {
            { label = "[Leave]", next = -1 },
        },
    },
}
