-- Echoes of the Dark Wars - Enemy Data
-- Core combat enemies for Phase 2

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Enemies = {
    [0] = {
        id = 0,
        name = "Kinrath Hatchling",
        deathText = "The hatchling crumples, its legs folding beneath it.",
        level = 1,
        maxHP = 40,
        damageMin = 6,
        damageMax = 10,
        defense = 2,
        behavior = "aggressive",
        xpReward = 50,
        creditReward = 10,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 30 },
        },
        intents = {
            attack = {
                vague = "The hatchling twitches and circles.",
                clear = "It coils its legs and prepares to pounce.",
            },
            special = {
                vague = "Green venom drips from its mandibles.",
                clear = "Its mandibles spread as poison gathers at the tips.",
            },
            defend = {
                vague = "It skitters backward, its breathing slowing.",
                clear = "It retreats and begins nursing its wounds.",
            },
        },
        specials = {
            poison_strike = {
                name = "Poison Strike",
                chance = 30,
                baseDamage = 5,
                poisonDamage = 3,
                poisonRounds = 2,
            },
        },
    },

    [1] = {
        id = 1,
        name = "Kinrath",
        deathText = "The kinrath collapses with a final hiss, venom still dripping from its jaws.",
        level = 2,
        maxHP = 80,
        damageMin = 12,
        damageMax = 16,
        defense = 5,
        behavior = "balanced",
        xpReward = 120,
        creditReward = 25,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 50 },
        },
        intents = {
            attack = {
                vague = "Its forelegs drum against the stone.",
                clear = "It lunges forward, aiming to rip through your guard.",
            },
            special = {
                vague = "Its mandibles click in a steady rhythm.",
                clear = "Its mandibles open wide for a crushing bite.",
            },
            defend = {
                vague = "It draws back, coiling inward.",
                clear = "It hunkers down, letting its wounds knit closed.",
            },
        },
        specials = {
            crushing_bite = {
                name = "Crushing Bite",
                chance = 25,
                baseDamage = 20,
                ignoreHalfDefense = true,
            },
        },
    },
    [2] = {
        id = 2,
        name = "Exchange Thug",
        deathText = "The thug stumbles back, clutching his wound. He won't be collecting bounties anymore.",
        level = 2,
        maxHP = 50,
        damageMin = 8,
        damageMax = 14,
        defense = 3,
        behavior = "aggressive",
        xpReward = 80,
        creditReward = 30,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 40 },
        },
        intents = {
            attack = {
                vague = "He shifts his weight, fists clenching.",
                clear = "He winds up for a heavy swing.",
            },
            special = {
                vague = "His eyes dart to your blind spot.",
                clear = "He feints low, preparing a cheap shot.",
            },
            defend = {
                vague = "He steps back, arms guarding his torso.",
                clear = "He hunkers down, waiting for an opening.",
            },
        },
        specials = {
            cheap_shot = {
                name = "Cheap Shot",
                kind = "damage",
                chance = 25,
                baseDamage = 6,
                stunRounds = 1,
                weight = 1,
            },
        },
    },

    [3] = {
        id = 3,
        name = "Kinrath Matriarch",
        deathText = "The matriarch lets out a final screech. The cave falls silent.",
        level = 3,
        maxHP = 120,
        damageMin = 14,
        damageMax = 20,
        defense = 7,
        behavior = "defensive",
        xpReward = 200,
        creditReward = 50,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 60 },
        },
        intents = {
            attack = {
                vague = "The matriarch shifts, mandibles twitching.",
                clear = "She rears up, preparing to slam down with full force.",
            },
            special = {
                vague = "A low vibration pulses from her thorax.",
                clear = "She lets out a building shriek - something is coming.",
            },
            defend = {
                vague = "She pulls her legs inward, lowering her body.",
                clear = "She hunkers down, carapace hardening as she heals.",
            },
        },
        specials = {
            brood_call = {
                name = "lets out a piercing shriek",
                kind = "heal",
                chance = 30,
                healAmount = 20,
                weight = 1,
            },
            crushing_bite = {
                name = "Crushing Bite",
                kind = "damage",
                chance = 25,
                baseDamage = 22,
                ignoreHalfDefense = true,
                weight = 2,
            },
        },
    },

    [4] = {
        id = 4,
        name = "Kath Hound",
        deathText = "The hound yelps once and collapses, its snarl fading.",
        level = 1,
        maxHP = 35,
        damageMin = 10,
        damageMax = 14,
        defense = 2,
        behavior = "aggressive",
        xpReward = 40,
        creditReward = 15,
        lootTable = {},
        intents = {
            attack = {
                vague = "It snarls, muscles tensing.",
                clear = "It lunges, jaws snapping at your legs.",
            },
            special = {
                vague = "It raises its head and takes a deep breath.",
                clear = "It throws its head back, preparing to howl.",
            },
            defend = {
                vague = "It paces in a slow circle, watching.",
                clear = "It backs away, licking its wounds.",
            },
        },
        specials = {
            pack_howl = {
                name = "lets out a rallying howl",
                kind = "buff",
                chance = 40,
                damageBonus = 5,
                nextAttackOnly = true,
                weight = 1,
            },
        },
    },

    [5] = {
        id = 5,
        name = "Salvager Droid",
        deathText = "Sparks fly as the droid's chassis buckles and powers down.",
        level = 2,
        maxHP = 60,
        damageMin = 8,
        damageMax = 12,
        defense = 8,
        behavior = "balanced",
        xpReward = 100,
        creditReward = 35,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 30 },
        },
        intents = {
            attack = {
                vague = "Its arm servos whine as it recalibrates.",
                clear = "It extends a cutting tool and charges forward.",
            },
            special = {
                vague = "Its chassis hums with building energy.",
                clear = "Energy crackles across its frame - a discharge is imminent.",
            },
            defend = {
                vague = "It angles its plating toward you.",
                clear = "It activates a shield generator, reinforcing its hull.",
            },
        },
        specials = {
            shield_overcharge = {
                name = "Shield Overcharge",
                kind = "damage",
                chance = 20,
                baseDamage = 16,
                ignoreHalfDefense = true,
                weight = 2,
            },
            stun_beam = {
                name = "Stun Beam",
                kind = "damage",
                chance = 15,
                baseDamage = 4,
                stunRounds = 1,
                weight = 1,
            },
        },
    },

    -- ============================================
    -- ACT 2: ONDERON ENEMIES (IDs 6+)
    -- ============================================
    [6] = {
        id = 6,
        name = "Onderon Thug",
        deathText = "The thug drops to one knee, then face-first into the dust.",
        level = 3,
        maxHP = 60,
        damageMin = 10,
        damageMax = 16,
        defense = 4,
        behavior = "aggressive",
        xpReward = 100,
        creditReward = 25,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 35 },
        },
        intents = {
            attack = {
                vague = "He rolls his shoulders, knuckles cracking.",
                clear = "He charges forward, fist drawn back for a heavy blow.",
            },
            special = {
                vague = "His hand drops to his belt, fingers wrapping around something.",
                clear = "He pulls a shiv from his belt and slashes low.",
            },
            defend = {
                vague = "He spits and backs up, circling.",
                clear = "He raises his arms, bracing for your next hit.",
            },
        },
        specials = {
            shiv_slash = {
                name = "Shiv Slash",
                kind = "damage",
                chance = 30,
                baseDamage = 8,
                bleedDamage = 3,
                bleedRounds = 2,
                weight = 1,
            },
        },
    },

    [7] = {
        id = 7,
        name = "Iziz Sentry Droid",
        deathText = "The sentry droid's optics flicker red, then go dark.",
        level = 3,
        maxHP = 70,
        damageMin = 8,
        damageMax = 14,
        defense = 10,
        behavior = "balanced",
        xpReward = 120,
        creditReward = 40,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 25 },
        },
        intents = {
            attack = {
                vague = "Its targeting laser sweeps across your position.",
                clear = "It locks on and fires a burst from its blaster arm.",
            },
            special = {
                vague = "Its chassis hums as power reroutes internally.",
                clear = "Energy crackles across its frame -- a stun discharge builds.",
            },
            defend = {
                vague = "It pivots, angling its thickest plating toward you.",
                clear = "It activates a localized shield, reinforcing its hull.",
            },
        },
        specials = {
            stun_pulse = {
                name = "Stun Pulse",
                kind = "damage",
                chance = 25,
                baseDamage = 6,
                stunRounds = 1,
                weight = 1,
            },
            overcharge_shot = {
                name = "Overcharge Shot",
                kind = "damage",
                chance = 20,
                baseDamage = 18,
                ignoreHalfDefense = true,
                weight = 2,
            },
        },
    },
    [8] = {
        id = 8,
        name = "Iziz Cutpurse",
        deathText = "The cutpurse slumps against the wall, coins spilling from his pockets.",
        level = 2,
        maxHP = 45,
        damageMin = 6,
        damageMax = 12,
        defense = 3,
        behavior = "aggressive",
        xpReward = 70,
        creditReward = 20,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 30 },
        },
        intents = {
            attack = {
                vague = "He shifts from foot to foot, eyes darting.",
                clear = "He lunges for your belt pouch, blade flashing.",
            },
            special = {
                vague = "His off-hand dips into a pocket.",
                clear = "He flings a handful of grit at your face.",
            },
            defend = {
                vague = "He backs away, calculating.",
                clear = "He ducks behind a crate, catching his breath.",
            },
        },
        specials = {
            pocket_sand = {
                name = "Pocket Sand",
                kind = "damage",
                chance = 35,
                baseDamage = 3,
                stunRounds = 1,
                weight = 1,
            },
        },
    },

    [9] = {
        id = 9,
        name = "Onderon Beast Rider",
        deathText = "The beast rider crashes from his mount, lance clattering across the stone.",
        level = 4,
        maxHP = 90,
        damageMin = 12,
        damageMax = 18,
        defense = 6,
        behavior = "balanced",
        xpReward = 160,
        creditReward = 45,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 40 },
        },
        intents = {
            attack = {
                vague = "He grips his lance with both hands, planting his feet.",
                clear = "He charges forward, lance leveled at your chest.",
            },
            special = {
                vague = "He throws his head back, chest swelling.",
                clear = "He lets out a thundering war cry that shakes the walls.",
            },
            defend = {
                vague = "He pulls his shield close, circling slowly.",
                clear = "He hunkers behind his shield, waiting for your move.",
            },
        },
        specials = {
            war_charge = {
                name = "War Charge",
                kind = "damage",
                chance = 30,
                baseDamage = 20,
                ignoreHalfDefense = true,
                weight = 2,
            },
            beast_howl = {
                name = "lets out a Beast Rider war howl",
                kind = "buff",
                chance = 25,
                damageBonus = 6,
                nextAttackOnly = true,
                weight = 1,
            },
        },
    },

    [10] = {
        id = 10,
        name = "Exchange Enforcer",
        deathText = "The enforcer's deflector sputters out. He crumples without a word.",
        level = 4,
        maxHP = 85,
        damageMin = 10,
        damageMax = 16,
        defense = 5,
        behavior = "balanced",
        xpReward = 150,
        creditReward = 50,
        lootTable = {
            { itemId = RPG.Config.MEDPAC_ID, chance = 40 },
        },
        intents = {
            attack = {
                vague = "He rolls his neck, cracking knuckles.",
                clear = "He raises his blaster and takes careful aim.",
            },
            special = {
                vague = "His hand moves to a pouch on his belt.",
                clear = "He loads a toxin dart into a wrist launcher.",
            },
            defend = {
                vague = "He steps back, touching something on his arm.",
                clear = "He activates a personal deflector shield.",
            },
        },
        specials = {
            toxin_dart = {
                name = "Toxin Dart",
                kind = "damage",
                chance = 30,
                baseDamage = 8,
                poisonDamage = 4,
                poisonRounds = 3,
                weight = 2,
            },
            personal_deflector = {
                name = "activates a personal deflector",
                kind = "heal",
                chance = 25,
                healAmount = 15,
                weight = 1,
            },
        },
    },

    [11] = {
        id = 11,
        name = "Void-Touched Refugee",
        deathText = "The purple light fades from its eyes. It was someone, once.",
        level = 3,
        maxHP = 50,
        damageMin = 8,
        damageMax = 14,
        defense = 2,
        behavior = "aggressive",
        xpReward = 90,
        creditReward = 15,
        lootTable = {},
        intents = {
            attack = {
                vague = "Its eyes flicker with purple light. It twitches.",
                clear = "It lunges with inhuman speed, fingers clawed.",
            },
            special = {
                vague = "A dark shimmer ripples across its body.",
                clear = "It screams -- and the air around it turns cold and dead.",
            },
            defend = {
                vague = "It collapses, then jerks upright again.",
                clear = "The void energy knits its wounds with dark threads.",
            },
        },
        specials = {
            void_discharge = {
                name = "Void Discharge",
                kind = "damage",
                chance = 35,
                baseDamage = 16,
                ignoreHalfDefense = true,
                weight = 1,
            },
        },
    },

    [12] = {
        id = 12,
        name = "The Stalker (Jedi Shadow)",
        deathText = "The Stalker dissolves into smoke. But you know it will return.",
        level = 8,
        maxHP = 9999,
        damageMin = 18,
        damageMax = 28,
        defense = 12,
        behavior = "aggressive",
        xpReward = 0,       -- no XP; survival costs paranoia, not earns rewards
        creditReward = 0,
        survivalTurns = 5,
        lootTable = {},
        intents = {
            attack = {
                vague = "The shadow shifts, lightsaber humming low.",
                clear = "It raises its blade in a killing arc aimed at your throat.",
            },
            special = {
                vague = "The air around it warps, colors draining to grey.",
                clear = "It opens its mouth and a sound that isn't sound tears through you.",
            },
            defend = {
                vague = "It pauses. Watching. Patient as stone.",
                clear = "Dark tendrils seep from the floor, mending its form.",
            },
        },
        specials = {
            dark_scream = {
                name = "Dark Scream",
                kind = "damage",
                chance = 40,
                baseDamage = 25,
                ignoreHalfDefense = true,
                weight = 2,
            },
            void_heal = {
                name = "draws strength from the void",
                kind = "heal",
                chance = 30,
                healAmount = 50,
                weight = 1,
            },
        },
    },

    [13] = {
        id = 13,
        name = "The Mimic (Your Echo)",
        deathText = "The Mimic's form distorts, your own face melting away into nothing.",
        level = 5,
        maxHP = 120,
        damageMin = 12,
        damageMax = 20,
        defense = 7,
        behavior = "balanced",
        xpReward = 250,
        creditReward = 0,
        lootTable = {},
        intents = {
            attack = {
                vague = "It mirrors your stance. Perfectly.",
                clear = "It attacks with YOUR fighting style -- a mirror strike.",
            },
            special = {
                vague = "Its form flickers, your face staring back at you.",
                clear = "It reaches toward you and you feel something pulling at your identity.",
            },
            defend = {
                vague = "It fades slightly, becoming translucent.",
                clear = "It dissolves into shadow, reforming behind you.",
            },
        },
        specials = {
            mirror_strike = {
                name = "Mirror Strike",
                kind = "damage",
                chance = 35,
                baseDamage = 22,
                ignoreHalfDefense = true,
                weight = 2,
            },
            identity_drain = {
                name = "Identity Drain",
                kind = "damage",
                chance = 25,
                baseDamage = 10,
                paranoia = 5,
                weight = 1,
            },
        },
    },
    -- ============================================
    -- ACT 3: FRAGMENT BOSSES + SHADOW SELF
    -- ============================================

    [14] = {
        id = 14,
        name = "Fragment: RAGE",
        deathText = "The rage burns out. You feel whole again.",
        level = 6,
        hp = 100,
        maxHP = 100,
        damageMin = 10,
        damageMax = 16,
        defense = 3,
        behavior = "aggressive",
        fragmentType = "rage",
        drainStat = "STR",
        firstClearOnly = true,
        xpReward = 200,
        creditReward = 0,
        loot = {},
        description = "A shard of your own fury, given form. It burns with red-hot rage — YOUR rage, amplified and weaponized. Every blow it strikes tears at your strength.",
        intents = {
            attack = {
                vague = "The fragment seethes, fists clenching.",
                clear = "It charges with blind, burning fury.",
            },
            special = {
                vague = "Crimson energy crackles around its form.",
                clear = "It reaches for your memories of anger — and pulls.",
            },
            defend = {
                vague = "The rage dims for a moment, gathering.",
                clear = "It coils inward, feeding on its own fire.",
            },
        },
        specials = {
            rage_memory = {
                name = "Rage Memory",
                kind = "damage",
                chance = 40,
                baseDamage = 18,
                statDrain = "STR",
                statDrainAmount = 1,
                paranoia = 3,
                weight = 2,
            },
            blind_fury = {
                name = "Blind Fury",
                kind = "damage",
                chance = 30,
                baseDamage = 25,
                weight = 1,
            },
        },
    },

    [15] = {
        id = 15,
        name = "Fragment: FEAR",
        deathText = "The fear dissolves. The future is uncertain -- but it is yours.",
        level = 6,
        hp = 90,
        maxHP = 90,
        damageMin = 8,
        damageMax = 14,
        defense = 4,
        behavior = "defensive",
        fragmentType = "fear",
        drainStat = "WIS",
        firstClearOnly = true,
        xpReward = 200,
        creditReward = 0,
        loot = {},
        description = "The part of you that sees the worst in every outcome. It wears your face twisted in terror, eyes wide, hands trembling. It knows exactly what you're afraid of.",
        intents = {
            attack = {
                vague = "The fragment flinches, then lashes out desperately.",
                clear = "It strikes with the frantic energy of cornered prey.",
            },
            special = {
                vague = "Its eyes glow white. It sees something you can't.",
                clear = "It shows you the future — every version where you fail.",
            },
            defend = {
                vague = "It shrinks back, trembling.",
                clear = "It curls inward, feeding on its own terror.",
            },
        },
        specials = {
            future_sight = {
                name = "Future Sight",
                kind = "damage",
                chance = 40,
                baseDamage = 14,
                stunRounds = 1,
                statDrain = "WIS",
                statDrainAmount = 1,
                paranoia = 5,
                weight = 2,
            },
            terror_shriek = {
                name = "Terror Shriek",
                kind = "damage",
                chance = 30,
                baseDamage = 20,
                paranoia = 3,
                weight = 1,
            },
        },
    },

    [16] = {
        id = 16,
        name = "Fragment: DESPAIR",
        deathText = "The weight lifts. Something matters after all.",
        level = 6,
        hp = 110,
        maxHP = 110,
        damageMin = 8,
        damageMax = 12,
        defense = 5,
        behavior = "balanced",
        fragmentType = "despair",
        drainStat = "CHA",
        firstClearOnly = true,
        xpReward = 200,
        creditReward = 0,
        loot = {},
        description = "The weight of every failure, every loss, every 'what if.' It moves slowly, deliberately, with the gravity of absolute certainty that nothing matters. Its touch drains the will to fight.",
        intents = {
            attack = {
                vague = "The fragment reaches toward you, slowly.",
                clear = "It extends a hand, palm open — not to strike, but to take.",
            },
            special = {
                vague = "A crushing weight settles over the battlefield.",
                clear = "It speaks a truth you've been avoiding. It hurts.",
            },
            defend = {
                vague = "It sags, as if bearing an enormous weight.",
                clear = "It absorbs damage like it doesn't matter. Because it doesn't.",
            },
        },
        specials = {
            crushing_truth = {
                name = "Crushing Truth",
                kind = "damage",
                chance = 40,
                baseDamage = 12,
                statDrain = "CHA",
                statDrainAmount = 1,
                paranoia = 4,
                weight = 2,
            },
            despair_heal = {
                name = "Despairing Embrace",
                kind = "heal",
                chance = 30,
                healAmount = 25,
                weight = 1,
            },
        },
    },

    [17] = {
        id = 17,
        name = "Shadow Self",
        deathText = "The shadow shatters into light. You stand alone.",
        level = 7,
        hp = 120,
        maxHP = 120,
        damageMin = 10,
        damageMax = 18,
        defense = 4,
        behavior = "balanced",
        shadowSelf = true,
        mimicMirror = true,
        drainStat = "WIS",
        xpReward = 300,
        creditReward = 0,
        loot = {},
        description = "It is you. Not a copy — the REAL you, or what you would have become if you'd made every wrong choice. It fights with your style, anticipates your moves, mirrors your actions. The only way to win is to break the pattern.",
        intents = {
            attack = {
                vague = "The Shadow shifts into YOUR fighting stance.",
                clear = "It mirrors your last move — a perfect copy.",
            },
            special = {
                vague = "Its form flickers, your face staring back at you.",
                clear = "It reaches for your mind, pulling at your sense of self.",
            },
            defend = {
                vague = "It fades slightly, becoming translucent.",
                clear = "It dissolves into shadow, reforming behind you.",
            },
        },
        specials = {
            mirror_strike = {
                name = "Mirror Strike",
                kind = "damage",
                chance = 35,
                baseDamage = 16,
                paranoia = 3,
                weight = 2,
            },
            identity_drain = {
                name = "Identity Drain",
                kind = "damage",
                chance = 25,
                baseDamage = 10,
                paranoia = 5,
                statDrain = "WIS",
                statDrainAmount = 1,
                weight = 1,
            },
        },
    },
}

    -- ============================================
    -- NEMESIS ENEMIES (IDs 30-32, modified at runtime by nemesis.lua)
    -- ============================================

    [30] = {
        id = 30,
        name = "The Hunter",  -- overwritten at runtime by nemesis.lua
        deathText = "The hunter staggers, then drops.",
        level = 5,
        maxHP = 90,
        damageMin = 10,
        damageMax = 16,
        defense = 5,
        behavior = "balanced",
        xpReward = 150,
        creditReward = 50,
        nemesisEncounter = 1,
        lootTable = {},
        intents = {
            attack = {
                vague = "They shift their weight, measuring you.",
                clear = "They commit to a precise strike at your guard.",
            },
            special = {
                vague = "Their hand moves to a device on their belt.",
                clear = "They activate specialized equipment targeting your weakness.",
            },
            defend = {
                vague = "They step back, eyes scanning.",
                clear = "They raise their guard and wait for an opening.",
            },
        },
        specials = {},  -- populated at runtime by nemesis.lua
    },

    [31] = {
        id = 31,
        name = "The Hunter",
        deathText = "The hunter collapses. Adapted, but not enough.",
        level = 7,
        maxHP = 140,
        damageMin = 14,
        damageMax = 22,
        defense = 8,
        behavior = "balanced",
        xpReward = 250,
        creditReward = 75,
        nemesisEncounter = 2,
        lootTable = {},
        intents = {
            attack = {
                vague = "A familiar stance. They've been practicing since last time.",
                clear = "They attack with refined technique -- they studied your moves.",
            },
            special = {
                vague = "New equipment glints on their armor.",
                clear = "They deploy a counter-measure designed specifically for you.",
            },
            defend = {
                vague = "They circle, patient. More cautious now.",
                clear = "They brace behind upgraded defenses, watching for patterns.",
            },
        },
        specials = {},
    },

    [32] = {
        id = 32,
        name = "The Hunter",
        deathText = "The hunter falls for the last time.",
        level = 9,
        maxHP = 200,
        damageMin = 18,
        damageMax = 28,
        defense = 11,
        behavior = "balanced",
        xpReward = 400,
        creditReward = 100,
        nemesisEncounter = 3,
        lootTable = {},
        intents = {
            attack = {
                vague = "Every movement is deliberate. They know you now.",
                clear = "They unleash everything they've learned about you.",
            },
            special = {
                vague = "They reach for something you haven't seen before.",
                clear = "Their final preparation. Everything they have, all at once.",
            },
            defend = {
                vague = "They watch you with something beyond professional interest.",
                clear = "They dig in. This is their last stand too.",
            },
        },
        specials = {},
    },
}

--- Returns a deep-copied enemy instance by ID.
function RPG.Data.GetEnemy(enemyId)
    local enemy = RPG.Data.Enemies[enemyId]
    if not enemy then
        return nil
    end
    enemy = RPG.Util.DeepCopy(enemy)
    enemy.hp = enemy.hp or enemy.maxHP
    return enemy
end

return RPG.Data.Enemies
