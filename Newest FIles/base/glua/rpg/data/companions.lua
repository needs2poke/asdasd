-- Echoes of the Dark Wars - Companion Data
-- Atton Rand's stats, abilities, behavior, commentary, and quips

RPG = RPG or {}
RPG.Data = RPG.Data or {}
RPG.Data.Companions = {}

RPG.Data.Companions.atton = {
    id = "atton",
    name = "Atton Rand",
    npcId = 2,

    -- Base stats (not directly used in combat, but available for future checks)
    baseStats = { STR = 14, DEX = 16, CON = 12, WIS = 10, INT = 12, CHA = 14 },

    -- HP scaling
    baseHP = 60,
    hpPerLevel = 6,
    baseFP = 0,
    fpPerLevel = 0,

    -- Behavior weights (keys match ChooseWeightedAction pattern)
    behavior = {
        normal    = { attack = 60, special = 25, defend = 15 },
        blackmail = { attack = 50, special = 20, defend = 30 },
    },

    -- Attack parameters
    baseHitChance = 75,
    blackmailHitPenalty = 15,
    damageMin = 8,
    damageMax = 14,

    -- Special abilities
    abilities = {
        {
            id = "dirty_fighting",
            name = "Dirty Fighting",
            chance = 30,
            damage = 12,
            effect = "stun",
            effectRounds = 1,
            stunChance = 40,
            quip = "^7Atton throws sand in its eyes. '^7Learned that one in the refugee camps.'",
            blackmailQuip = "^7Atton fights dirty. No quips this time.",
        },
        {
            id = "lucky_shot",
            name = "Lucky Shot",
            chance = 40,
            damage = 18,
            critBonus = true,
            quip = "^7'^7Ha! Did you see that?' Atton grins. '^7Pure pazaak.'",
            blackmailQuip = "^7Atton lands a solid hit. His expression stays flat.",
        },
        {
            id = "cover_fire",
            name = "Cover Fire",
            chance = 30,
            damage = 0,
            effect = "player_defense",
            defenseBonus = 4,
            duration = 1,
            quip = "^7'^7Get behind me!' Atton moves to cover your flank.",
            blackmailQuip = "^7Atton shifts position. Covering you. Barely.",
        },
    },

    -- Blackmailed-only sabotage
    sabotageMissChance = 15,

    -- Enemy targeting
    targetChance = 28,
    targetChanceDefending = 15,

    -- KO/revive
    koReviveHP = 1,

    -- Paranoia
    paranoiaReduction = 0.25,
    paranoiaThresholds = { 30, 50, 70, 85 },
    paranoiaCooldownMs = 60000,

    -- Combat quips (random pick from pool)
    quips = {
        onAttack = {
            "'^7Not bad for a scoundrel, right?'",
            "'^7I've hit harder at pazaak tables.'",
            "'^7Watch the master at work.'",
        },
        onAttackBlackmail = {
            "'^7There. Happy?'",
            "'^7I did what you asked.'",
        },
        onMiss = {
            "'^7That one got away from me.'",
            "'^7Okay, nobody saw that.'",
        },
        onMissBlackmail = {
            "'^7Whoops.' He doesn't sound sorry.",
        },
        onKO = {
            "Atton staggers and falls. '^1...told you this was... a bad idea...'",
            "Atton collapses. '^1...not... dying for you...'",
        },
        onRevive = {
            "Atton pulls himself up slowly. '^7Ow. I'm billing you for that.'",
            "'^7Still alive. Barely. You're welcome.'",
        },
        onReviveBlackmail = {
            "Atton stands. Says nothing.",
        },
        onEnemyKill = {
            "'^7And stay down.'",
            "'^7One less problem.'",
        },
        onDefend = {
            "Atton hunkers down, checking his wounds.",
            "'^7Give me a second, I need to patch this up.'",
        },
    },

    -- Room commentary (keyed by roomId, with generic fallback)
    commentary = {
        [0] = {
            normal = {
                "'^7The Enclave courtyard. Nicer than I expected for a ruin.'",
                "'^7You'd never know a war happened here. Almost.'",
            },
            blackmail = {
                "Atton scans the courtyard silently.",
            },
        },
        [3] = {
            normal = {
                "'^7The cantina. Now THIS is more my style.'",
                "'^7I used to hustle pazaak in places like this.'",
            },
            blackmail = {
                "Atton eyes the exits. Old habits.",
            },
        },
        [6] = {
            normal = {
                "'^7Crashed ship. Someone didn't land well.'",
                "'^7Check the cargo hold. Wrecks always have something useful.'",
            },
            blackmail = {
                "Atton kicks debris aside without comment.",
            },
        },
        [8] = {
            normal = {
                "'^7Crystal caves. The Force is strong here. Even I can feel it.'",
                "'^7Careful with those crystals. They react to emotion.'",
            },
            blackmail = {
                "'^7Caves. Great. Love caves.' Sarcasm drips.",
            },
        },
        generic = {
            normal = {
                "'^7This place gives me a bad feeling.'",
                "'^7I've been in worse. Not much worse, but worse.'",
                "'^7Stay sharp. Something feels off.'",
                "'^7You know, most people just sit in cantinas.'",
                "'^7Remind me why I signed up for this again?'",
                "'^7At least nobody's shooting at us. Yet.'",
            },
            blackmail = {
                "Atton follows in silence.",
                "'^7...' He says nothing.",
                "Atton's hand rests near his blaster.",
            },
        },
    },

    -- Calming lines at paranoia thresholds
    calmingLines = {
        [30] = "'^7Hey. You're hearing things again, aren't you? Focus on my voice. Count the exits.'",
        [50] = "'^7Listen to me. That thing in your bag? It WANTS you afraid. Don't give it the satisfaction.'",
        [70] = "'^7You're shaking. Look at me. We've gotten through worse than a mouthy rock.'",
        [85] = "'^7Stay with me. You're still you. Whatever it's showing you, it's not real.'",
    },
}

-- Helper: get companion definition by id
function RPG.Data.GetCompanion(companionId)
    return RPG.Data.Companions[companionId]
end

return true
