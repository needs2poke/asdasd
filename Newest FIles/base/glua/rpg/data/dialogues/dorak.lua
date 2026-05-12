-- Dialogue Tree: Archivist Tamas (successor to Master Dorak)
-- Elderly scholar, Archives keeper, Room 11
-- Quest Q3: The Shadow's Trail (shadows_trail)
-- ~18 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            -- P1: Hostile (overrides everything)
            { condition = function(g) return RPG.Quest.IsComplete(g, "shadows_trail") and RPG.Quest.HasFlag(g, "dorak_hostile") end, node = 32 },
            -- P2: Completed quest reactions (ghosts_enclave first visit)
            { condition = function(g) return RPG.Quest.IsComplete(g, "ghosts_enclave") and not RPG.Quest.HasFlag(g, "dorak_ghosts_discussed") end, node = 50 },
            -- P3: Completed shadows_trail (path-specific sub-router)
            { condition = function(g) return RPG.Quest.IsComplete(g, "shadows_trail") end, node = 30 },
            -- P4: Decoded stage (minigame-aware  - self-decrypt vs Tamas-decrypt)
            { condition = function(g)
                return RPG.Quest.GetStage(g, "shadows_trail") == "decoded"
                    and RPG.Quest.GetVar(g, "shadows_trail", "shadow_decrypt_done")
                end, node = 19 },
            { condition = function(g) return RPG.Quest.GetStage(g, "shadows_trail") == "decoded" end, node = 20 },
            -- P5: Active quest stages
            { condition = function(g)
                local stage = RPG.Quest.GetStage(g, "shadows_trail")
                return stage == "decrypt" or stage == "enclave_search"
                end, node = 10 },
            -- P6: Has datapad (quest trigger)
            { condition = function(g) return RPG.Util.Contains(g.player.inventory, 7) end, node = 2 },
            -- P7: Has Holocron (general warning)
            { condition = function(g) return g.player.hasHolocron end, node = 40 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default Greeting (no quest, no datapad)
    -- ============================================
    [1] = {
        speaker = "Archivist Tamas",
        text = {
            "An elderly man looks up from a faded datapad, spectacles balanced on his nose.",
            "'^7Not many come here anymore. People want to forget the past.",
            "Can't say I blame them  - the past around here involves a lot",
            "of bombardment and screaming.'",
            "'^7Still. History has a way of repeating itself when you're not looking.'",
        },
        responses = {
            {
                label = "What do you do here?",
                next = 1.5,
            },
            {
                label = "What happened to the Jedi Enclave?",
                next = 1.6,
            },
            {
                label = "Just looking around. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 1.5: What do you do?
    -- ============================================
    [1.5] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7I keep records. Settlement logs, crop yields, water tables.",
            "Terribly exciting stuff.'",
            "A dry smile.",
            "'^7Master Dorak catalogued these records for fifteen years before",
            "Katarr. I was his apprentice. I inherited the archive... and the duty.'",
            "'^7Now I catalogue irrigation reports. The galaxy has a sense of humor.'",
        },
        responses = {
            {
                label = "You worked at the Enclave?",
                next = 1.6,
            },
            {
                label = "Sounds peaceful, at least.",
                next = 1.7,
            },
            {
                label = "I'll let you get back to it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 1.6: The Enclave
    -- ============================================
    [1.6] = {
        speaker = "Archivist Tamas",
        text = {
            "His expression darkens.",
            "'^7The last person who came here looking for Jedi secrets was Malak.",
            "You'll forgive my caution.'",
            "'^7The Enclave is rubble. Malak's fleet saw to that. What the bombs",
            "didn't destroy, the scavengers picked clean. Most of it, anyway.'",
        },
        responses = {
            {
                label = "Most of it?",
                next = 1.7,
            },
            {
                label = "I understand. Thank you. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 1.7: Hints at deeper knowledge
    -- ============================================
    [1.7] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7The sublevel archives survived the bombardment. Sealed behind",
            "blast doors. The scavengers couldn't reach them.'",
            "He pauses, choosing his words carefully.",
            "'^7If you find anything interesting in your travels  - old datapads,",
            "Jedi records  - bring them to me. History deserves better than a junk heap.'",
        },
        responses = {
            {
                label = "I'll keep that in mind. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Has the Datapad (item 7)  - quest trigger
    -- ============================================
    [2] = {
        speaker = "Archivist Tamas",
        text = {
            "His eyes fix on the datapad in your hand. He goes very still.",
            "'^7Where did you get that?'",
            "He reaches for it, then catches himself.",
            "'^7That's a Jedi Shadow's field journal. The encryption is old Republic",
            "Intelligence  - I haven't seen that cipher scheme in twenty years.'",
        },
        responses = {
            {
                label = "I found it at the crash site, near a dead Jedi.",
                next = 3,
            },
            {
                label = "Can you read it?",
                next = 3,
            },
            {
                label = "It's mine. Forget you saw it. [Leave]",
                next = -1,
                alignment = -3,
            },
        },
    },

    -- ============================================
    -- NODE 3: Tamas examines the datapad
    -- ============================================
    [3] = {
        speaker = "Archivist Tamas",
        text = {
            "He holds the datapad with reverent care, turning it in the light.",
            "'^7Partially. The header is clear  - star charts, coordinates. But the",
            "mission notes are encrypted with a rotating cipher.'",
            "'^7I can crack it, but I need the cipher key. The Shadows kept backup",
            "keys in secure terminals. There was one in the Enclave sublevel.'",
        },
        responses = {
            {
                label = "I'll search the Enclave sublevel for the cipher.",
                next = 4,
                effects = { startQuest = "shadows_trail" },
            },
            {
                label = "[INT 14] Could I help decrypt it manually?",
                next = 4,
                check = { stat = "INT", dc = 14 },
                failNext = 3.5,
                effects = { startQuest = "shadows_trail" },
            },
            {
                label = "That sounds like a lot of trouble. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 3.5: INT check failure
    -- ============================================
    [3.5] = {
        speaker = "Archivist Tamas",
        text = {
            "He peers at you over his spectacles.",
            "'^7I appreciate the enthusiasm, but Republic Intelligence encryption",
            "isn't something you brute-force with good intentions.'",
            "'^7The cipher key is in the Enclave sublevel. That's the only way.'",
        },
        effects = { startQuest = "shadows_trail" },
        responses = {
            {
                label = "Fine. I'll find the cipher key.",
                next = 4,
            },
        },
    },

    -- ============================================
    -- NODE 4: Quest accepted  - directions
    -- ============================================
    [4] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7The sublevel entrance is through the Enclave ruins, north of the",
            "Dantooine Fields. Look for a sealed terminal near the archive stacks.'",
            "'^7Be careful down there. The bombardment destabilized the structure,",
            "and salvager droids still patrol  - their friend-or-foe systems are...",
            "unreliable.'",
        },
        effects = {
            setStage = { quest = "shadows_trail", stage = "decrypt" },
        },
        responses = {
            {
                label = "I'll be back with the cipher.",
                next = -1,
            },
            {
                label = "What do you think is on this datapad?",
                next = 4.5,
            },
        },
    },

    -- ============================================
    -- NODE 4.5: What's on the datapad?
    -- ============================================
    [4.5] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Jedi Shadows were the Order's intelligence operatives. Infiltrators.",
            "Trackers. They hunted Sith threats the Council didn't want public.'",
            "'^7Whatever she was tracking, it was important enough to die for.",
            "The star charts in the header reference the Unknown Regions.'",
            "He leans back. '^7That's never a good sign.'",
        },
        responses = {
            {
                label = "I'll find the cipher. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 10: Decrypt/Enclave Search stage  - waiting
    -- ============================================
    [10] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Any luck with the Enclave sublevel? The cipher key should be",
            "in a secure terminal near the old archive stacks.'",
        },
        responses = {
            {
                label = "I found the cipher key.",
                next = 11,
                requireFlag = "cipher_key_found",
            },
            {
                label = "Still searching. The sublevel is a maze.",
                next = 12,
            },
            {
                label = "I'll head back down there. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 11: Cipher retrieved  - decryption scene
    -- ============================================
    [11] = {
        speaker = "Archivist Tamas",
        text = {
            "His eyes light up as he takes the cipher module.",
            "'^7This is it. Old Republic Intelligence, Series Seven.'",
            "He feeds it into the datapad. Symbols cascade across the screen.",
            "'^7Give me a moment... yes. Yes, I have it.'",
            "His face falls as he reads. '^7Oh. Oh no.'",
        },
        effects = {
            setStage = { quest = "shadows_trail", stage = "decoded" },
            giveXP = 150,
        },
        responses = {
            {
                label = "What does it say?",
                next = 20,
            },
        },
    },

    -- ============================================
    -- NODE 12: Still searching  - encouragement
    -- ============================================
    [12] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7The sublevel was never designed to be navigated by outsiders.",
            "The Jedi had the Force to guide them. You'll have to rely on",
            "stubbornness.'",
            "A thin smile. '^7In my experience, stubbornness works almost as well.'",
        },
        responses = {
            {
                label = "I'll find it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 19: Self-decrypt acknowledgment (minigame path)
    -- ============================================
    [19] = {
        speaker = "Archivist Tamas",
        text = {
            "He stares at the datapad, then at you. Something like admiration.",
            "'^7You cracked Republic Intelligence cipher. On your own.",
            "In a bombed-out sublevel.'",
            "'^7I spent fifteen years surrounded by these systems and",
            "never managed it.'",
        },
        responses = {
            {
                label = "The secondary coordinates  - what are they?",
                next = 119,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadow_full_decode") end,
            },
            {
                label = "What does the full data show?",
                next = 20,
            },
        },
    },

    -- ============================================
    -- NODE 119: Full decode bonus  - dead drop protocol
    -- ============================================
    [119] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7These secondary coordinates are a dead drop protocol.",
            "Republic Intelligence, Shadow variant.'",
            "'^7She wasn't just tracking the academy  - she had an asset.",
            "Someone inside was feeding her data.'",
            "'^7That asset may still be alive. Or they may be a corpse",
            "with your coordinates in their pocket.'",
        },
        effects = { setFlag = "shadow_contact_known" },
        responses = {
            {
                label = "We need to act on this. What does the rest say?",
                next = 20,
                setFlag = "dorak_vren_lore_shared",
            },
        },
    },

    -- ============================================
    -- NODE 20: Decoded stage  - the revelation
    -- ============================================
    [20] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7The Shadow was tracking a hidden Sith academy. Not a ruin  -",
            "an active one. Deep in the Unknown Regions.'",
            "'^7These coordinates... if they're accurate, the Sith have been",
            "rebuilding in secret. Training new acolytes. For years.'",
            "He looks old. Tired. Afraid.",
        },
        saevusWhisper = "Knowledge is power. These coordinates could make you very powerful indeed...",
        saevusCondition = function(g) return g.player.hasHolocron and g.player.paranoia > 25 end,
        responses = {
            {
                label = "We need to tell Administrator Adare immediately.",
                next = 21,
                alignment = 5,
            },
            {
                label = "I'll handle this myself. Give me the coordinates.",
                next = 23,
                alignment = -3,
            },
            {
                label = "This is too dangerous. We should destroy the datapad.",
                next = 25,
            },
            {
                label = "These coordinates are yours to sell. Knowledge is currency.",
                truthLabel = "The Holocron wants you to commodify this. Lives are at stake.",
                isDoubt = true,
                next = 24,
                alignment = -8,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 20 end,
            },
        },
    },

    -- ============================================
    -- NODE 21: Give intel to Adare (Light)
    -- ============================================
    [21] = {
        speaker = "Archivist Tamas",
        text = {
            "Relief washes over his face.",
            "'^7Yes. Adare will know what to do. She has Republic contacts  -",
            "encrypted channels. This intelligence could save lives.'",
            "'^7Thank you. For a moment I was afraid you'd...'",
            "He trails off. '^7Never mind. You did the right thing.'",
        },
        effects = {
            setStage = { quest = "shadows_trail", stage = "complete" },
            setFlag = "shadows_trail_light",
            alignment = 5,
            giveXP = 250,
            addCredits = 50,
        },
        responses = {
            {
                label = "The Shadow died getting this. It should count for something.",
                next = 22,
            },
        },
    },

    -- ============================================
    -- NODE 22: Light resolution  - closing
    -- ============================================
    [22] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7It will. She tracked a threat no one else saw. That's what",
            "Shadows do  - they walk in the dark so others don't have to.'",
            "He places the datapad carefully on his desk.",
            "'^7I'll make sure her sacrifice is recorded. Properly. Not as",
            "a footnote, but as what it was  - an act of courage.'",
        },
        responses = {
            {
                label = "Take care of yourself, Tamas. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 23: Keep for yourself (Dark)
    -- ============================================
    [23] = {
        speaker = "Archivist Tamas",
        text = {
            "He stares at you. The warmth is gone.",
            "'^7Handle it yourself. With Sith academy coordinates.'",
            "'^7The last Jedi who thought they could handle the Sith alone",
            "is dead in a wrecked ship half a kilometer from here.'",
            "'^7But I can see your mind is made up. Take the data. And may",
            "the Force have mercy on whatever you find out there.'",
        },
        effects = {
            setStage = { quest = "shadows_trail", stage = "complete" },
            setFlag = "shadows_trail_dark",
            alignment = -5,
            giveXP = 200,
        },
        responses = {
            {
                label = "I know what I'm doing.",
                next = -1,
            },
            {
                label = "...Maybe you're right. Tell Adare.",
                next = 21,
                alignment = 5,
            },
        },
    },

    -- ============================================
    -- NODE 24: Doubt option  - sell the coordinates
    -- ============================================
    [24] = {
        speaker = "Archivist Tamas",
        text = {
            "He recoils as if struck.",
            "'^7Sell  - people will die if this falls into the wrong hands.",
            "The Exchange, the Hutts, rival Sith factions -'",
            "'^7I may be old, but I'm not powerless. I'll take this to Adare",
            "myself before I let you auction off a death sentence.'",
        },
        effects = {
            setStage = { quest = "shadows_trail", stage = "complete" },
            setFlag = "dorak_hostile",
            alignment = -8,
            giveXP = 100,
        },
        responses = {
            {
                label = "Try it, old man.",
                next = -1,
                alignment = -3,
            },
            {
                label = "...I don't know why I said that. You're right.",
                next = 21,
                alignment = 5,
            },
        },
    },

    -- ============================================
    -- NODE 25: Destroy the datapad (Neutral)
    -- ============================================
    [25] = {
        speaker = "Archivist Tamas",
        text = {
            "He closes his eyes. A long, pained silence.",
            "'^7Part of me agrees with you. This knowledge is dangerous.'",
            "'^7But part of me  - the archivist  - screams at the thought of",
            "destroying information. Even terrible information.'",
            "'^7Are you certain? Once it's gone, it's gone.'",
        },
        responses = {
            {
                label = "I'm certain. Some things are better forgotten.",
                next = 25.5,
                alignment = 2,
            },
            {
                label = "You're right. We should tell Adare instead.",
                next = 21,
                alignment = 5,
            },
            {
                label = "Actually, I'll keep the coordinates.",
                next = 23,
                alignment = -3,
            },
        },
    },

    -- ============================================
    -- NODE 25.5: Destroy confirmed
    -- ============================================
    [25.5] = {
        speaker = "Archivist Tamas",
        text = {
            "He nods slowly and feeds the datapad into the terminal's",
            "secure wipe function. The screen flashes, then goes dark.",
            "'^7Done. The Shadow's trail ends here.'",
            "'^7I hope we don't regret this. But I understand why you chose it.",
            "Some doors are safer left closed.'",
        },
        effects = {
            setStage = { quest = "shadows_trail", stage = "complete" },
            setFlag = "shadows_trail_neutral",
            removeItem = 7,
            giveXP = 200,
            addCredits = 30,
        },
        responses = {
            {
                label = "The Shadow would have understood. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 30: Post-quest sub-router (path-specific)
    -- ============================================
    [30] = {
        routes = {
            -- Light path: revisit after Vren lore
            { condition = function(g) return RPG.Quest.HasFlag(g, "dorak_vren_lore_shared") and RPG.Quest.HasFlag(g, "shadows_trail_light") end, node = 33.5 },
            -- Light path: first visit
            { condition = function(g) return RPG.Quest.HasFlag(g, "shadows_trail_light") end, node = 33 },
            -- Dark path
            { condition = function(g) return RPG.Quest.HasFlag(g, "shadows_trail_dark") end, node = 36 },
            -- Neutral path
            { condition = function(g) return RPG.Quest.HasFlag(g, "shadows_trail_neutral") end, node = 38 },
        },
        fallback = 31,
    },

    -- ============================================
    -- NODE 31: Generic fallback (no path flag)
    -- ============================================
    [31] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Ah, you're back.'",
            "He looks more at ease than before. Slightly.",
            "'^7I've been thinking about the Shadow. About what drives someone",
            "to spend their life chasing darkness alone.'",
            "'^7Be safe out there. And come back in one piece. These archives",
            "are dull enough without losing my only visitor.'",
        },
        responses = {
            {
                label = "Take care, Tamas. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 33: Light path  - Republic response
    -- ============================================
    [33] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Adare sent the intelligence through Republic channels.",
            "The response was... immediate. Almost too immediate.'",
            "'^7The Republic already knew something was happening in the",
            "Unknown Regions. They've known for years.'",
            "'^7After Revan vanished, Republic Intelligence lost their",
            "best asset. They've been flying blind ever since.'",
        },
        responses = {
            {
                label = "What do you know about the Shadow?",
                next = 34,
                condition = function(g) return not RPG.Quest.HasFlag(g, "dorak_vren_lore_shared") end,
            },
            {
                label = "What will the Republic do?",
                next = 35,
            },
            {
                label = "Be safe, Tamas. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 33.5: Light path  - short revisit
    -- ============================================
    [33.5] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Any developments from the Republic? No?'",
            "He adjusts his spectacles.",
            "'^7Then we wait. Archivists are good at waiting.'",
        },
        responses = {
            {
                label = "What about the inside contact?",
                next = 134,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadow_contact_known") and not RPG.Quest.HasFlag(g, "dorak_warned_about_contact") end,
            },
            {
                label = "Stay safe, Tamas. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 34: Karath Vren lore  - the Jedi Shadow
    -- ============================================
    [34] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Karath Vren. Human. Trained here at the Enclave before I",
            "arrived. Republic Intelligence recruited her straight out of",
            "the Padawan trials.'",
            "'^7She was one of the last Shadows the Council dispatched",
            "before Malak's fleet arrived. Her assignment: track rumors of",
            "a Sith training facility in the Unknown Regions. Not Trayus",
            "Academy  - something older. Pre-dating the Great Hyperspace War.'",
            "'^7The irony is exquisite  - she survived Malak's bombardment",
            "only to die in a crash landing.'",
            "He pauses. '^7An old hermit on Kashyyyk used to say the Force",
            "has a sick sense of humor. I'm starting to agree.'",
        },
        effects = { setFlag = "dorak_vren_lore_shared" },
        responses = {
            {
                label = "What about the inside contact?",
                next = 134,
                condition = function(g) return RPG.Quest.HasFlag(g, "shadow_contact_known") and not RPG.Quest.HasFlag(g, "dorak_warned_about_contact") end,
            },
            {
                label = "Be safe. And if I reach those coordinates... I'll find out what happened to her.",
                next = -1,
                alignment = 2,
            },
        },
    },

    -- ============================================
    -- NODE 134: Inside contact warning
    -- ============================================
    [134] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7If Vren's contact is still alive, they're deep cover.",
            "Years behind enemy lines.'",
            "'^7That kind of assignment changes people. The Shadows who",
            "went deep... some of them forgot which side they were on.'",
            "'^7If you find this contact, trust your instincts. Not",
            "their words.'",
        },
        effects = { setFlag = "dorak_warned_about_contact" },
        responses = {
            {
                label = "Understood. I'll be careful. [Leave]",
                next = -1,
                alignment = 1,
            },
        },
    },

    -- ============================================
    -- NODE 35: Republic response analysis
    -- ============================================
    [35] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7They dispatched a cruiser. Not to investigate  - to blockade.",
            "Whatever's in the Unknown Regions, the Republic doesn't want",
            "anyone else finding it.'",
            "'^7That tells me two things: they know more than they're",
            "sharing, and they're afraid.'",
            "'^7If you're planning to follow the Shadow's trail, you'll be",
            "doing it without Republic backing. They want this buried.'",
        },
        responses = {
            {
                label = "Then I'll do it alone.",
                next = -1,
                alignment = 2,
            },
            {
                label = "Maybe they're right to be afraid. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 36: Dark path  - cold archivist
    -- ============================================
    [36] = {
        speaker = "Archivist Tamas",
        text = {
            "He talks to his datapad, not to you.",
            "'^7I submitted my own report to the Republic. Whatever you're",
            "planning, they'll be watching.'",
            "'^7I've seen what happens to people who chase Sith power.",
            "It never ends the way they imagine.'",
            "'^7There was a Knight who came through here, years ago.",
            "Charming. Brilliant. Called himself Revan.'",
            "'^7You remind me of him.'",
            "'^7That wasn't a compliment.'",
        },
        responses = {
            {
                label = "Revan won.",
                next = 37,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 37: Revan warning
    -- ============================================
    [37] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Revan disappeared into the Unknown Regions chasing exactly",
            "what you're chasing. Nobody's heard from him since. Not even",
            "the Republic.'",
            "'^7When the most powerful Force user in a generation vanishes",
            "without a trace, a wise person asks: what did he find that",
            "was strong enough to swallow him?'",
        },
        saevusWhisper = "The old man is afraid. Good. Fear is honest.",
        saevusCondition = function(g) return g.player.hasHolocron and g.player.paranoia > 20 end,
        responses = {
            {
                label = "I'll find out. [Leave]",
                next = -1,
                alignment = -2,
            },
            {
                label = "[Leave in silence]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 38: Neutral path  - philosophical peace
    -- ============================================
    [38] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7I keep thinking about what you said. About some doors",
            "being safer closed.'",
            "'^7The Jedi hoarded knowledge for millennia. And in the end,",
            "all that accumulated wisdom didn't save a single Padawan when",
            "Malak's fleet arrived.'",
            "'^7Maybe there's a kind of courage in choosing not to know.'",
        },
        responses = {
            {
                label = "Do you believe that?",
                next = 39,
            },
            {
                label = "Some things are better left buried. [Leave]",
                next = -1,
                alignment = 1,
            },
        },
    },

    -- ============================================
    -- NODE 39: Archivist's confession
    -- ============================================
    [39] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7No. I'm an archivist. It's against my religion.'",
            "A dry, tired laugh.",
            "'^7But I respect it. And I think the Shadow would have",
            "understood. She spent her life chasing secrets, and the last",
            "one killed her.'",
            "'^7There's a meditation in the old texts  - \"The Force does not",
            "require your understanding, only your trust.\"'",
            "'^7I never believed it until now.'",
        },
        responses = {
            {
                label = "Take care of yourself, Tamas. [Leave]",
                next = -1,
                alignment = 1,
            },
        },
    },

    -- ============================================
    -- NODE 32: Post-quest (Dark path)
    -- ============================================
    [32] = {
        speaker = "Archivist Tamas",
        text = {
            "He doesn't look up from his work.",
            "'^7I have nothing more to say to you.'",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 40: With Holocron  - academic concern
    -- ============================================
    [40] = {
        speaker = "Archivist Tamas",
        text = {
            "He freezes mid-sentence as you enter. His hand grips the desk.",
            "'^7You're carrying something. Something... old.'",
            "'^7I catalogued Sith artifacts for the Enclave for fifteen years.",
            "I know what the dark side feels like when it walks into a room.'",
        },
        saevusWhisper = "The old man is perceptive. Perceptive people ask inconvenient questions...",
        saevusCondition = function(g) return g.player.paranoia > 20 end,
        responses = {
            {
                label = "It's a Sith Holocron. I found it at the crash site.",
                next = 41,
            },
            {
                label = "You're imagining things.",
                next = 42,
            },
            {
                label = "Mind your own business, old man.",
                next = 42,
                alignment = -3,
            },
            {
                label = "[The Holocron whispers about an Emperor...]",
                next = 55,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 50 and not RPG.Quest.HasFlag(g, "saevus_emperor_discussed") end,
            },
            {
                label = "[The Holocron whispers about the Mandalorian Wars...]",
                next = 56,
                condition = function(g) return g.player.hasHolocron and g.player.paranoia > 40 and not RPG.Quest.HasFlag(g, "saevus_mandalore_discussed") end,
            },
        },
    },

    -- ============================================
    -- NODE 41: Admits to Holocron
    -- ============================================
    [41] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7A Holocron. Here.'",
            "He removes his spectacles, rubbing his eyes.",
            "'^7I've read accounts of what these things do to people. The",
            "gatekeeper personality  - it learns you. Finds the cracks in",
            "your conviction and pours poison into them.'",
            "'^7Be very, very careful. And if you have anything else from",
            "that crash site, I'd like to see it.'",
        },
        responses = {
            {
                label = "[Show the Jedi Shadow's Datapad]",
                next = 2,
                requireItem = 7,
            },
            {
                label = "I'll keep that in mind. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 42: Denial / hostility
    -- ============================================
    [42] = {
        speaker = "Archivist Tamas",
        text = {
            "He watches you with sad, knowing eyes.",
            "'^7I'm not imagining anything. But I won't force the truth",
            "out of you. I'm an archivist, not an inquisitor.'",
            "'^7When you're ready to talk  - if you're ready  - I'll be here.",
            "I'm always here.'",
        },
        responses = {
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    [50] = {
        speaker = "Archivist Tamas",
        text = {
            "He sets down his datapad with deliberate care.",
            "'^7And? Did it offer power dressed as inevitability?'",
            "'^7Sith relics have one joke and tell it for millennia.'",
        },
        responses = {
            {
                label = "I sealed it. Saevus is contained.",
                next = 51,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_destroy") end,
                alignment = 2,
            },
            {
                label = "I took what I needed and kept my footing.",
                next = 52,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_balance") end,
            },
            {
                label = "I accepted his path.",
                next = 53,
                condition = function(g) return RPG.Quest.HasFlag(g, "ghosts_embrace") end,
                alignment = -3,
            },
            { label = "Forget it. [Leave]", next = -1 },
        },
    },

    [51] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7Then you've done what entire councils failed to do.'",
            "'^7History won't praise you for restraint. It almost never does.'",
            "He offers a thin smile.",
            "'^7But historians like me notice. We always notice.'",
        },
        responses = {
            { label = "Keep that in the archives. [Leave]", next = -1, alignment = 2, setFlag = "dorak_ghosts_discussed" },
        },
    },

    [52] = {
        speaker = "Archivist Tamas",
        text = {
            "'^7A dangerous answer. Possibly the only honest one.'",
            "'^7If you walk the middle path, document your own failures.",
            "Revan didn't, and the galaxy paid for editorial omissions.'",
        },
        responses = {
            { label = "Noted. [Leave]", next = -1, alignment = 1, setFlag = "dorak_ghosts_discussed" },
        },
    },

    [53] = {
        speaker = "Archivist Tamas",
        text = {
            "He closes his eyes for a long moment.",
            "'^7Then I suggest you travel far from places that still pretend",
            "to be civilized.'",
            "'^7Sith teachers always charge interest. Usually in people.'",
        },
        responses = {
            { label = "I can pay my own debts. [Leave]", next = -1, alignment = -1, setFlag = "dorak_ghosts_discussed" },
            { label = "[Leave in silence]", next = -1, setFlag = "dorak_ghosts_discussed" },
        },
    },

    -- ============================================
    -- NODE 55: Saevus  - True Sith Emperor hint
    -- ============================================
    [55] = {
        speaker = "Darth Saevus (Holocron)",
        text = {
            "The Holocron pulses. The voice bypasses your ears entirely.",
            "'^1You think I am the darkness? I am a CANDLE",
            "compared to what waits beyond the Outer Rim.'",
            "'^1An Emperor who consumed a world to live",
            "forever. An army preparing for a thousand",
            "years.'",
            "'^1Revan found them. They broke him.'",
            "'^1And they are patient. So. Very. Patient.'",
        },
        effects = {
            setFlag = "saevus_emperor_discussed",
            paranoia = 5,
        },
        responses = {
            {
                label = "An Emperor? What are you talking about?",
                next = 55.5,
            },
            {
                label = "[Force the Holocron silent]",
                next = 42,
                alignment = 3,
            },
        },
    },

    -- ============================================
    -- NODE 55.5: Saevus  - Emperor elaboration
    -- ============================================
    [55.5] = {
        speaker = "Darth Saevus (Holocron)",
        text = {
            "'^1He sits on a throne of silence in a place",
            "stripped of all life. All color. All sound.'",
            "'^1He consumed his own world to achieve",
            "immortality. Every soul. Every blade of grass.'",
            "'^1And when Revan came seeking answers...'",
            "'^1The Emperor simply... kept him.'",
        },
        responses = {
            {
                label = "How do you know this?",
                next = -1,
                alignment = -2,
            },
            {
                label = "[Shut the Holocron] Enough.",
                next = -1,
                alignment = 2,
            },
        },
    },

    -- ============================================
    -- NODE 56: Saevus  - Mandalore's manipulation
    -- ============================================
    [56] = {
        speaker = "Darth Saevus (Holocron)",
        text = {
            "The Holocron hums a frequency that makes your teeth ache.",
            "'^1The Mandalorian Wars. Do you think the clans",
            "attacked on their own?'",
            "'^1Mandalore the Ultimate met something in the",
            "dark. Something that whispered \"attack now,",
            "and glory will follow.\"'",
            "'^1The Mandalorians were tools.'",
            "'^1As were Revan and Malak after them.'",
        },
        effects = {
            setFlag = "saevus_mandalore_discussed",
            paranoia = 3,
        },
        responses = {
            {
                label = "Everything was orchestrated?",
                next = 56.5,
            },
            {
                label = "[Force the Holocron silent]",
                next = 42,
                alignment = 3,
            },
        },
    },

    -- ============================================
    -- NODE 56.5: Saevus  - Mandalore elaboration
    -- ============================================
    [56.5] = {
        speaker = "Darth Saevus (Holocron)",
        text = {
            "'^1The wars. The betrayals. The fall of the",
            "Jedi. Every piece moved into position across",
            "decades.'",
            "'^1And nobody noticed. Because nobody was",
            "looking at the board.'",
            "'^1Except Revan. And look what that cost him.'",
        },
        responses = {
            {
                label = "...I need to think about this. [Leave]",
                next = -1,
            },
            {
                label = "You're lying. Trying to frighten me.",
                next = -1,
                alignment = 2,
            },
        },
    },
}
