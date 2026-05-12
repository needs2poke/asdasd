-- Dialogue Tree: Doctor Vara Denn
-- Twi'lek frontier doctor, medical bay  - Room 10
-- Quest Q2: Field Medicine (field_medicine)
-- ~18 nodes

return {
    -- ============================================
    -- NODE 0: Root Router
    -- ============================================
    [0] = {
        routes = {
            { condition = function(g) return RPG.Quest.IsComplete(g, "field_medicine") end, node = 30 },
            { condition = function(g) return RPG.Quest.GetStage(g, "field_medicine") == "delivered" end, node = 20 },
            { condition = function(g) return RPG.Quest.GetStage(g, "field_medicine") == "dealing" end, node = 12 },
            { condition = function(g) return RPG.Quest.GetStage(g, "field_medicine") == "gathering" end, node = 11 },
            { condition = function(g) return RPG.Quest.GetStage(g, "field_medicine") == "supplies_needed" end, node = 10 },
            { condition = function(g) return g.player.hasHolocron and g.player.paranoia > 15 end, node = 40 },
        },
        fallback = 1,
    },

    -- ============================================
    -- NODE 1: Default Greeting (No quest yet)
    -- ============================================
    [1] = {
        speaker = "Doctor Vara Denn",
        text = {
            "A Twi'lek woman in stained medical scrubs doesn't look up from a wounded settler.",
            "'^7Another visitor. If you're bleeding, sit down. If you're not,",
            "make yourself useful or make yourself scarce.'",
            "She finishes a suture with practiced hands.",
            "'^7I became a frontier doctor because Core World hospitals have",
            "too many committees and not enough patients. Now I have too",
            "many patients and not enough anything.'",
        },
        responses = {
            {
                label = "What do you need? I can help.",
                next = 2,
            },
            {
                label = "What happened here?",
                next = 3,
            },
            {
                label = "[WIS 12] You're rationing the kolto. How bad is it really?",
                next = 4,
                check = { stat = "WIS", dc = 12 },
                failNext = 5,
            },
            {
                label = "Denn -- do you have a connection to the old Enclave?",
                next = 41,
            },
            {
                label = "I'll come back later. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 2: Player offers help  - quest initiation
    -- ============================================
    [2] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She stops. Looks at you properly for the first time.",
            "'^7Help. That's a dangerous word around here. People say it,",
            "then they walk out and forget.'",
            "'^7But fine. I need kolto. Real kolto, not the watered-down",
            "swill Goran passes off as medical grade. I've got settlers",
            "with infected wounds and nothing to treat them with.'",
        },
        responses = {
            {
                label = "Where can I find kolto?",
                next = 4,
            },
            {
                label = "Sounds like a supply problem, not a me problem.",
                next = 6,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 3: What happened here?
    -- ============================================
    [3] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7The crash shook the whole settlement. Shrapnel, burns, broken",
            "bones. Two settlers caught in the blast radius. Three more",
            "injured by panicked kath hounds.'",
            "'^7And that was just the first hour. The kinrath are pushing",
            "closer to the settlement now, so I get a steady stream of",
            "militia boys who thought courage was a substitute for armor.'",
        },
        responses = {
            {
                label = "Is there anything I can do?",
                next = 2,
            },
            {
                label = "You seem to have things under control. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 4: Kolto sources  - two paths (caves vs Exchange)
    -- ============================================
    [4] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She lowers her voice, glancing at the sleeping patients.",
            "'^7Two options. Neither is good.'",
            "'^7There are natural kolto deposits in the Deep Crystal Caves.",
            "Raw, unrefined, but I can make it work. Problem is the kinrath",
            "nests between here and there.'",
            "'^7Or  - and I hate saying this  - the Exchange has a stockpile.",
            "Medical supplies they stole from a Republic shipment. Draxen",
            "would sell them, but the price won't be in credits.'",
        },
        responses = {
            {
                label = "I'll get the kolto from the caves.",
                next = 7,
                effects = {
                    startQuest = "field_medicine",
                    setStage = { quest = "field_medicine", stage = "gathering" },
                },
                alignment = 2,
            },
            {
                label = "I'll talk to the Exchange. Faster that way.",
                next = 8,
                effects = {
                    startQuest = "field_medicine",
                    setStage = { quest = "field_medicine", stage = "dealing" },
                },
            },
            {
                label = "I'll figure out which route makes more sense.",
                next = 9,
                effects = { startQuest = "field_medicine" },
            },
            {
                label = "That sounds like a lot of trouble. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 5: WIS check FAILURE
    -- ============================================
    [5] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She gives you a tired, flat look.",
            "'^7Everyone's a medical expert. Yes, supplies are low.",
            "No, I don't want to discuss it with someone who can't",
            "tell a kolto injector from a hypospanner.'",
            "'^7Was there something you actually needed?'",
        },
        responses = {
            {
                label = "I want to help. What do you need?",
                next = 2,
            },
            {
                label = "Never mind. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 6: "Not my problem"
    -- ============================================
    [6] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7You're right. It's not your problem.'",
            "She turns back to her patient.",
            "'^7It's his. And hers. And the child in the next bed",
            "who screams every time I change the bandages because",
            "I've got nothing for the pain.'",
            "'^7Door's behind you.'",
        },
        responses = {
            {
                label = "...Fine. Tell me what you need.",
                next = 4,
                alignment = 1,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 7: Chose caves path
    -- ============================================
    [7] = {
        speaker = "Doctor Vara Denn",
        text = {
            "Something like respect crosses her face. Brief, but real.",
            "'^7The caves. Brave choice. Or stupid. On Dantooine those",
            "are often the same thing.'",
            "'^7The kolto seeps through the rock in the deep chambers.",
            "You'll need a container  - take this.'",
            "She hands you a battered collection canister.",
            "'^7And try not to die. I'm too busy to fill out the paperwork.'",
        },
        effects = { giveItem = 3 },
        responses = {
            { label = "I'll be back with the kolto. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 8: Chose Exchange path
    -- ============================================
    [8] = {
        speaker = "Doctor Vara Denn",
        text = {
            "Her mouth thins. She doesn't approve, but she doesn't argue.",
            "'^7Draxen operates out of the Dantooine Fields, east of the",
            "Plaza. He'll want a favor  - he always does. Don't agree to",
            "anything that makes the settlement bleed worse than it already is.'",
            "'^7And if he offers you a deal that sounds too good?",
            "It is. Trust me.'",
        },
        responses = {
            { label = "I know how to handle criminals. [Leave]", next = -1 },
            {
                label = "What kind of favors does he ask?",
                next = 9,
            },
        },
    },

    -- ============================================
    -- NODE 9: General quest acceptance / more info
    -- ============================================
    [9] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7Information. Leverage. Access. The usual currency of people",
            "who think power is a substitute for decency.'",
            "'^7Look, I don't care how you get the kolto. I care that my",
            "patients live through the week. Everything else is philosophy",
            "I can't afford.'",
        },
        effects = {
            setStage = { quest = "field_medicine", stage = "supplies_needed" },
        },
        responses = {
            { label = "Understood. I'll find a way. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 10: Quest active  - supplies_needed (hasn't picked a path)
    -- ============================================
    [10] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She's re-dressing a wound. Doesn't look up.",
            "'^7Still deciding? My patients don't have the luxury",
            "of deliberation. Caves or Exchange  - pick one.'",
        },
        responses = {
            {
                label = "I'll get the kolto from the caves.",
                next = 7,
                effects = {
                    setStage = { quest = "field_medicine", stage = "gathering" },
                },
            },
            {
                label = "I'll negotiate with the Exchange.",
                next = 8,
                effects = {
                    setStage = { quest = "field_medicine", stage = "dealing" },
                },
            },
            {
                label = "I'm working on it. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 11: Quest active  - gathering (caves path check-in)
    -- ============================================
    [11] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7You're back. Empty-handed, I see.'",
            "She checks a monitor, frowning.",
            "'^7The deep caves, remember? Past the kinrath nests.",
            "The kolto seeps through the rock formations down there.",
            "Hurry. I've got maybe three days of supplies left.'",
        },
        responses = {
            {
                label = "I found kolto in the caves. Here.",
                next = 20,
                condition = function(g) return RPG.Quest.HasFlag(g, "has_cave_kolto") end,
                effects = {
                    setStage = { quest = "field_medicine", stage = "delivered" },
                },
            },
            {
                label = "Still working on it. Those kinrath are no joke.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 12: Quest active  - dealing (Exchange path check-in)
    -- ============================================
    [12] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7Made your deal with Draxen yet?'",
            "She doesn't sound hopeful.",
            "'^7Whatever he asked for, it's too much. But whatever",
            "my patients need, it's not enough. That's the math.'",
        },
        responses = {
            {
                label = "I got the kolto from the Exchange. Here.",
                next = 21,
                condition = function(g) return RPG.Quest.HasFlag(g, "has_exchange_kolto") end,
                effects = {
                    setStage = { quest = "field_medicine", stage = "delivered" },
                },
            },
            {
                label = "Still negotiating. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 20: Delivered  - returned from caves
    -- ============================================
    [20] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She takes the canister, holds it to the light. Her hands tremble.",
            "'^7Raw kolto. Unrefined, but... yes. Yes, I can work with this.'",
            "She's already moving to the workstation, cracking the seal.",
            "'^7You went through kinrath territory for this. Most people",
            "wouldn't cross the street for a stranger.'",
            "For a moment, the sardonic mask slips. She's genuinely moved.",
        },
        responses = {
            {
                label = "They're not strangers. They're your patients.",
                next = 22,
                alignment = 5,
            },
            {
                label = "Don't read too much into it. You asked, I delivered.",
                next = 23,
            },
            {
                label = "What do I get for the trouble?",
                next = 24,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 21: Delivered  - returned from Exchange
    -- ============================================
    [21] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She examines the sealed crates. Medical-grade kolto. Republic stamps.",
            "'^7I won't ask where this came from. Ignorance keeps my",
            "conscience clean and my patients alive.'",
            "She's already cataloguing the contents.",
            "'^7This is enough for weeks. Months, if I'm careful.'",
        },
        saevusWhisper = "She accepts stolen goods without question. A useful weakness...",
        saevusCondition = function(g) return g.player.hasHolocron and g.player.paranoia > 25 end,
        responses = {
            {
                label = "As long as people get better, that's what matters.",
                next = 22,
                alignment = 2,
            },
            {
                label = "You should know  - I made a deal with Draxen for this.",
                next = 25,
            },
            {
                label = "Remember who brought you this. I may need a favor.",
                next = 24,
                alignment = -3,
            },
        },
    },

    -- ============================================
    -- NODE 22: Grateful resolution (light side)
    -- ============================================
    [22] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She pauses. Sets down the kolto vial.",
            "'^7You know, I've been patching people up on the Outer Rim",
            "for eleven years. Most of them forget my name before the",
            "bacta dries. You're... different.'",
            "'^7If you ever need patching up  - and on Dantooine, you will  -",
            "come here first. No charge. Doctor's orders.'",
        },
        effects = {
            setFlag = "zhar_free_healing",
            giveXP = 250,
        },
        responses = {
            { label = "Thank you, Doctor. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 23: Pragmatic resolution (neutral)
    -- ============================================
    [23] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7Fair enough. Not everyone needs a thank-you speech.'",
            "She manages a crooked half-smile.",
            "'^7You get hurt, come see me. First patch-up is on the house.",
            "After that, we negotiate like civilized people.'",
        },
        effects = {
            setFlag = "zhar_free_healing",
            giveXP = 250,
        },
        responses = {
            { label = "Deal. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 24: Mercenary resolution (dark side)
    -- ============================================
    [24] = {
        speaker = "Doctor Vara Denn",
        text = {
            "The warmth vanishes. Professional detachment snaps back.",
            "'^7A favor. Of course.'",
            "'^7Fine. You need medical attention, I'll provide it. Once.",
            "After that, you're a patient like everyone else.'",
            "'^7We're done here.'",
        },
        effects = {
            setFlag = "zhar_owes_favor",
            giveXP = 200,
        },
        responses = {
            { label = "Pleasure doing business. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 25: Told her about the Exchange deal
    -- ============================================
    [25] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7Draxen.'",
            "She closes her eyes. Opens them.",
            "'^7I know what his deals cost. I hope whatever you gave him",
            "was worth less than a dozen lives, because that's what",
            "this kolto buys.'",
            "'^7Don't come to me for absolution. I'm a doctor, not a priest.",
            "But... thank you. For what it's worth.'",
        },
        effects = {
            setFlag = "zhar_free_healing",
            giveXP = 250,
        },
        responses = {
            { label = "It was worth it. [Leave]", next = -1 },
            {
                label = "You could at least pretend to be grateful.",
                next = 24,
                alignment = -2,
            },
        },
    },

    -- ============================================
    -- NODE 30: Post-quest  - grateful, offers healing
    -- ============================================
    [30] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She looks up from her work. Less haggard than before.",
            "'^7The kolto's holding. Two patients discharged this morning.",
            "The child is sleeping without screaming for the first time",
            "in a week.'",
        },
        responses = {
            {
                label = "Good to hear. How are you holding up?",
                next = 31,
            },
            {
                label = "I could use some medical attention.",
                next = 32,
                condition = function(g) return RPG.Quest.HasFlag(g, "zhar_free_healing") end,
            },
            {
                label = "Just passing through. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 31: Post-quest personal conversation
    -- ============================================
    [31] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She blinks. Nobody asks her that.",
            "'^7I slept four hours last night. That's a personal record",
            "for the month.'",
            "A dry laugh.",
            "'^7I'll survive. That's what frontier doctors do. We survive,",
            "and we make sure everyone around us does too. Glamorous work.'",
        },
        responses = {
            {
                label = "You're doing more good than you know.",
                next = -1,
                alignment = 2,
            },
            {
                label = "Get some rest, Doctor. [Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 32: Free healing
    -- ============================================
    [32] = {
        speaker = "Doctor Vara Denn",
        text = {
            "'^7Sit down. Let me look at you.'",
            "She works quickly, hands sure and steady.",
            "'^7You're running yourself into the ground. Sound familiar?",
            "Physician, heal thyself, and all that.'",
            "'^7There. Good as new. Or as close as battlefield medicine gets.'",
        },
        effects = { giveItem = 3 },
        responses = {
            { label = "Thanks, Doc. [Leave]", next = -1 },
        },
    },

    -- ============================================
    -- NODE 40: With Holocron  - she senses something
    -- ============================================
    [40] = {
        speaker = "Doctor Vara Denn",
        text = {
            "She flinches as you enter. Covers it quickly, but you saw.",
            "'^7You're... back.'",
            "She rubs her arms as if cold.",
            "'^7There's something about you. I can't explain it medically,",
            "and I hate things I can't explain medically. You carry",
            "something that makes the air feel... wrong.'",
        },
        saevusWhisper = "She feels the Holocron's presence. Her healing is a chain  - she binds the weak to gratitude, to dependency. Without patients, she is nothing.",
        saevusCondition = function(g) return g.player.paranoia > 40 end,
        responses = {
            {
                label = "It's nothing. What do you need?",
                next = 1,
            },
            {
                label = "You're Force-sensitive, aren't you?",
                next = 41,
            },
            {
                label = "She can sense the Holocron. She's a threat.",
                truthLabel = "She senses the dark side instinctively. That makes her perceptive, not dangerous.",
                isDoubt = true,
                next = 42,
                alignment = -5,
                condition = function(g) return g.player.paranoia > 30 end,
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 41: Force-sensitive confrontation
    -- ============================================
    [41] = {
        speaker = "Doctor Vara Denn",
        text = {
            "Her lekku twitch. A Twi'lek tell for surprise.",
            "'^7No. I'm not. I'm a doctor, not a mystic.'",
            "A pause too long to be comfortable.",
            "'^7My mother had a touch of it. Enough to feel weather",
            "changes before they happened. Enough to know when",
            "someone was lying.'",
            "'^7My father trained under Master Zhar Lestin at the",
            "Enclave. He always said the old Twi'lek saw something",
            "in him that no one else did.'",
            "'^7Malak's fleet turned the Enclave to rubble.",
            "My father didn't survive.'",
            "'^7I inherited just enough sensitivity to be unsettled",
            "by whatever you're carrying. Not enough to do anything about it.'",
        },
        saevusWhisper = "A name is just a shroud. She wears her father's like a shield, but she is as hollow as the ruins he died in.",
        saevusCondition = function(g) return g.player.paranoia > 25 end,
        responses = {
            {
                label = "I'm sorry. I didn't mean to make you uncomfortable.",
                next = 1,
                alignment = 2,
            },
            {
                label = "That must be useful for a doctor.",
                next = -1,
            },
        },
    },

    -- ============================================
    -- NODE 42: Doubt option  - Holocron paranoia about Vara
    -- ============================================
    [42] = {
        speaker = "Doctor Vara Denn",
        text = {
            "Your voice comes out colder than you intended.",
            "She takes a step back. Professional calm barely holding.",
            "'^7I don't know what's gotten into you, but I've treated",
            "soldiers with that look. The ones who stopped sleeping.",
            "The ones who started seeing enemies everywhere.'",
            "'^7You need help. Not the kind I can give with kolto.'",
        },
        responses = {
            {
                label = "...You're right. I'm sorry.",
                next = 1,
                alignment = 3,
            },
            {
                label = "Stay out of my way, Doctor. [Leave]",
                next = -1,
                alignment = -3,
            },
        },
    },
}
