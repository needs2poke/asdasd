-- Echoes of the Dark Wars - Nemesis Data
-- Name pools, origin modifiers, abilities, scar descriptions, calling cards, traces

RPG = RPG or {}
RPG.Data = RPG.Data or {}
RPG.Data.NemesisData = {}

local ND = RPG.Data.NemesisData

-- ============================================
-- NAME POOLS (8 per origin, randomly combined)
-- ============================================
ND.NAMES = {
    exchange = {
        first = { "Varek", "Jendo", "Tash", "Kael", "Droga", "Silas", "Fen", "Marak" },
        last  = { "Sorn", "Keth", "Voss", "Drell", "Mak", "Torr", "Qel", "Rast" },
    },
    republic = {
        first = { "Sera", "Cael", "Nira", "Thane", "Renn", "Lira", "Jorin", "Kessa" },
        last  = { "Vel", "Dorne", "Kost", "Aldric", "Vane", "Taan", "Reth", "Morr" },
    },
    mandalorian = {
        first = { "Krag", "Orla", "Bralor", "Kelsa", "Torr", "Vhek", "Darv", "Nala" },
        last  = { "Wren", "Cadera", "Lok", "Fenn", "Rekk", "Sharr", "Krev", "Tal" },
    },
}

-- ============================================
-- ORIGIN TITLES
-- ============================================
ND.TITLES = {
    exchange    = { professional = "Exchange Enforcer", sadistic = "Exchange Collector" },
    republic    = { cold = "Republic Agent", zealot = "Republic Inquisitor" },
    mandalorian = { honorable = "Mandalorian Seeker", obsessed = "Mandalorian Stalker" },
}

-- ============================================
-- ORIGIN TEMPERAMENTS (2 per origin)
-- ============================================
ND.TEMPERAMENTS = {
    exchange    = { "professional", "sadistic" },
    republic    = { "cold", "zealot" },
    mandalorian = { "honorable", "obsessed" },
}

-- ============================================
-- ORIGIN STAT MODIFIERS (applied before combat)
-- ============================================
ND.ORIGIN_MODS = {
    exchange    = { hpMod = 0, damageMod = 0, defenseMod = 2 },
    republic    = { hpMod = -10, damageMod = -2, defenseMod = 4 },
    mandalorian = { hpMod = 20, damageMod = 3, defenseMod = -2 },
}

-- ============================================
-- SPECIAL ABILITIES PER ORIGIN
-- ============================================
ND.ABILITIES = {
    exchange = {
        nerve_toxin = {
            name = "Nerve Toxin",
            kind = "damage",
            chance = 35,
            baseDamage = 8,
            poisonDamage = 4,
            poisonRounds = 3,
            weight = 2,
        },
        stun_dart = {
            name = "Stun Dart",
            kind = "damage",
            chance = 25,
            baseDamage = 4,
            stunRounds = 1,
            weight = 1,
        },
        bribe_droid = {
            name = "Bribe Droid",
            kind = "buff",
            chance = 30,
            damageBonus = 8,
            nextAttackOnly = true,
            weight = 1,
            minEncounter = 2,
        },
    },
    republic = {
        suppressing_fire = {
            name = "Suppressing Fire",
            kind = "damage",
            chance = 35,
            baseDamage = 10,
            suppressedRounds = 2,
            weight = 2,
        },
        flash_charge = {
            name = "Flash Charge",
            kind = "damage",
            chance = 25,
            baseDamage = 6,
            stunRounds = 1,
            halveDefense = true,
            weight = 1,
        },
        neural_disruptor = {
            name = "Neural Disruptor",
            kind = "damage",
            chance = 30,
            baseDamage = 12,
            paranoia = 3,
            weight = 2,
            minEncounter = 2,
        },
    },
    mandalorian = {
        jetpack_strike = {
            name = "Jetpack Strike",
            kind = "damage",
            chance = 35,
            baseDamage = 22,
            ignoreHalfDefense = true,
            weight = 2,
        },
        flame_sweep = {
            name = "Flame Sweep",
            kind = "damage",
            chance = 30,
            baseDamage = 8,
            burnDamage = 5,
            burnRounds = 2,
            weight = 2,
        },
        war_cry = {
            name = "War Cry",
            kind = "buff",
            chance = 25,
            damageBonus = 6,
            duration = 2,
            weight = 1,
            minEncounter = 2,
        },
    },
}

-- ============================================
-- ADAPTATION ABILITIES (class-based, Enc 2+)
-- ============================================
ND.ADAPTATIONS = {
    evasion_module = {
        name = "Evasion Module",
        kind = "buff",
        chance = 20,
        dodgeChance = 20,
        weight = 1,
    },
    force_dampener = {
        name = "Force Dampener",
        kind = "buff",
        chance = 30,
        halveForceDamage = true,
        weight = 1,
    },
    heavy_plating = {
        name = "Heavy Plating",
        kind = "buff",
        chance = 30,
        defenseBonus = 6,
        weight = 1,
    },
}

-- Class -> adaptation mapping
ND.CLASS_ADAPTATION = {
    guardian = "evasion_module",
    soldier  = "evasion_module",
    consular = "force_dampener",
    sentinel = "force_dampener",
    scoundrel = "heavy_plating",
    hunter   = "heavy_plating",
}

-- ============================================
-- SCAR DESCRIPTIONS (per origin, per stage)
-- ============================================
ND.SCAR_DESCRIPTIONS = {
    exchange = {
        [0] = "Clean armor, confident posture. A professional.",
        [1] = "A scorch mark across the chestplate. They favor their left side now.",
        [2] = "A prosthetic arm. The armor is welded shut over wounds that won't close.",
    },
    republic = {
        [0] = "Pressed uniform, cold eyes. Everything measured.",
        [1] = "Uniform torn at the collar. A bacta patch on the neck.",
        [2] = "A cybernetic eye. A scar runs from jaw to temple.",
    },
    mandalorian = {
        [0] = "Polished beskar. The T-visor gleams.",
        [1] = "A crack across the visor. A burn scorches the pauldron.",
        [2] = "A missing horn on the helmet. A limp. Rage in every step.",
    },
}

-- ============================================
-- SCAR SOURCE ATTRIBUTION (per encounter flag)
-- ============================================
ND.SCAR_SOURCES = {
    nemesis_humiliated_1 = function(g)
        local origin = g.nemesis.origin
        if origin == "exchange" then
            return "^8The burn across the chestplate -- a gift from your power on Dantooine -- still hasn't healed.^7"
        elseif origin == "republic" then
            return "^8The scar at the neck -- where your strike nearly ended them -- pulses with bacta fluid.^7"
        else
            return "^8The crack in the visor -- where your blow nearly split the helm -- catches the light.^7"
        end
    end,
    nemesis_spared_1 = function(g)
        return "^8The scar you could have made isn't there. They remember that.^7"
    end,
    nemesis_player_lost_1 = function(g)
        return "^8They look healthier than last time. Your defeat gave them confidence.^7"
    end,
}

-- ============================================
-- CALLING CARDS (origin-specific traces)
-- ============================================
ND.CALLING_CARDS = {
    exchange    = "Sliced terminals, missing credits. Someone paid for information about you.",
    republic    = "A surveillance spike hums in the corner. Official scorch marks near the door.",
    mandalorian = "Spent high-caliber casings. Blade-gouged walls. Someone heavy was here.",
}

-- ============================================
-- ROOM TRACE TEXT (between encounters)
-- ============================================
ND.TRACES = {
    -- After Enc 1, before Enc 2 (Act 1 rooms)
    [3] = {
        encounter = 1,
        exchange    = "^8A patron eyes you nervously. 'Someone was asking about you. Paid in Exchange credits.'^7",
        republic    = "^8A surveillance spike hums under the bar counter. Someone is listening.^7",
        mandalorian = "^8A spent high-caliber casing rolls under your foot. Recent.^7",
    },
    [10] = {
        encounter = 1,
        text = "^8Scorch marks on the wall near the entrance. Recent. Someone fired a warning shot here.^7",
    },
    -- After Enc 2, before Enc 3 (Act 2 rooms)
    [28] = {
        encounter = 2,
        text = "^8A merchant pulls you aside. 'Your hunter was here. Bought scanning equipment. They're adapting to you.'^7",
    },
    [31] = {
        encounter = 2,
        dynamic = function(g)
            return "^8A security terminal blinks: BOUNTY ALERT - " .. g.nemesis.fullName .. " - AUTHORIZED PURSUIT.^7"
        end,
    },
    -- Ship traces
    [21] = {
        encounter = 1,
        dynamic = function(g)
            local n = g.nemesis
            local taunts = {
                exchange    = "^8[Transmission] '" .. n.fullName .. ": ^3The bounty doubled. You should have paid when you had the chance.'^7",
                republic    = "^8[Transmission] '" .. n.fullName .. ": ^3Rogue Force user. Your file is growing. We don't lose files.'^7",
                mandalorian = "^8[Transmission] '" .. n.fullName .. ": ^3I've tasted your blade. Now I know your rhythm. Next time.'^7",
            }
            return taunts[n.origin] or ""
        end,
    },
    [22] = {
        encounter = 1,
        dynamic = function(g)
            local enc = g.nemesis.encounter
            if enc >= 2 then
                return "^5[Hunter Intel] ^7They've adapted. " .. (g.nemesis.adaptation ~= "none" and "New equipment detected: counter-measures for your fighting style." or "Analysis inconclusive.")
            end
            return "^5[Hunter Intel] ^7Weakness analysis based on encounter 1 observations. They favor " .. g.nemesis.origin .. " tactics."
        end,
    },
}

-- Fake trace for paranoia > 70 (Saevus manipulation)
ND.FAKE_TRACES = {
    "^1Someone carved your name into the bulkhead. The handwriting is yours.^7",
    "^1A datapad on the floor. It displays your location in real-time. No one left it here.^7",
    "^1Scorch marks on the wall spell a word. You can't read it, but you know what it says.^7",
}

-- ============================================
-- ENCOUNTER INTRO TEXT (per origin)
-- ============================================
ND.INTRO_TEXT = {
    exchange = {
        [1] = {
            "^1A figure steps from the crowd.",
            "^1Exchange armor. A blaster at the hip.",
            "^1They block the path with practiced ease.",
            "^3'You match the description. The bounty is confirmed.'",
        },
        [2] = function(g)
            return {
                "^1A familiar figure. Exchange armor, but damaged now.",
                RPG.Data.NemesisData.GetScarSource(g) or "",
                "^3'" .. g.nemesis.fullName .. " again. You knew this wasn't over.'",
            }
        end,
        [3] = function(g)
            return {
                "^1" .. g.nemesis.fullName .. ".",
                "^1" .. (ND.SCAR_DESCRIPTIONS.exchange[g.nemesis.scarStage] or ""),
                "^3'Last time. One of us walks away from this.'",
            }
        end,
    },
    republic = {
        [1] = {
            "^1A uniform. Gray. No insignia.",
            "^1Republic black-ops. They found you.",
            "^1A hand rests on a regulation sidearm.",
            "^3'Rogue Force user. You are to come with me.'",
        },
        [2] = function(g)
            return {
                "^1That uniform again. Less pristine now.",
                RPG.Data.NemesisData.GetScarSource(g) or "",
                "^3'I filed a report after last time. My superiors were... displeased.'",
            }
        end,
        [3] = function(g)
            return {
                "^1" .. g.nemesis.fullName .. ".",
                "^1" .. (ND.SCAR_DESCRIPTIONS.republic[g.nemesis.scarStage] or ""),
                "^3'No more reports. No more orders. This is personal.'",
            }
        end,
    },
    mandalorian = {
        [1] = {
            "^1Mandalorian iron. A T-visor stares back at you.",
            "^1They don't draw a weapon. Not yet.",
            "^1They want you to see the armor first.",
            "^3'Jedi. I've been looking for a challenge.'",
        },
        [2] = function(g)
            return {
                "^1Beskar, but scarred now.",
                RPG.Data.NemesisData.GetScarSource(g) or "",
                "^3'You earned that hit. I'll earn mine.'",
            }
        end,
        [3] = function(g)
            return {
                "^1" .. g.nemesis.fullName .. ".",
                "^1" .. (ND.SCAR_DESCRIPTIONS.mandalorian[g.nemesis.scarStage] or ""),
                "^3'This is the hunt that matters. Win or lose, they'll sing about this.'",
            }
        end,
    },
}

-- ============================================
-- DEFEAT TAUNTS (by attitude + temperament)
-- ============================================
ND.DEFEAT_TAUNTS = {
    professional = {
        neutral = "^3'Business. Nothing personal. I'll collect next time.'",
        respect = "^3'You've got potential. Stay alive long enough to use it.'",
        hatred  = "^3'That's a down payment. I always collect the full amount.'",
    },
    sadistic = {
        neutral = "^3'That look on your face... worth more than the bounty.'",
        respect = "^3'You almost made me work for it. Almost.'",
        hatred  = "^3'I'll take a finger next time. Call it interest.'",
    },
    cold = {
        neutral = "^3'Documented. Your resistance is noted.'",
        respect = "^3'Your file doesn't do you justice. Noted.'",
        hatred  = "^3'Next time I won't aim to subdue.'",
    },
    zealot = {
        neutral = "^3'The Republic's will is patient. You are not.'",
        respect = "^3'You fight for something. I can see that. It won't save you.'",
        hatred  = "^3'Heretics always fall. It's simply a matter of time.'",
    },
    honorable = {
        neutral = "^3'A fair exchange. You'll be stronger next time.'",
        respect = "^3'You'll do better next time. I look forward to it.'",
        hatred  = "^3'That was beneath both of us. Improve.'",
    },
    obsessed = {
        neutral = "^3'Not enough. I need MORE from you.'",
        respect = "^3'Yes... this is what I came for. But there must be more.'",
        hatred  = "^3'Every time you fall, I feel... empty. Stand up. DO IT AGAIN.'",
    },
}

-- ============================================
-- SAEVUS NEMESIS WHISPERS (one per encounter start)
-- ============================================
ND.SAEVUS_WHISPERS = {
    [1] = "^1[WHISPER] Someone has put a price on you. Good. It means you matter.",
    [2] = "^1[WHISPER] They adapt. So must you. Or don't. I enjoy watching either way.",
    [3] = "^1[WHISPER] This is the end of one hunt. Don't fool yourself -- there are always more.",
}

-- ============================================
-- ATTON COMPANION REACTIONS
-- ============================================
ND.ATTON_LINES = {
    [1] = "^3[Atton]^7 'Great. Someone's hunting you. This is exactly why I stopped traveling with Jedi.'",
    [2] = "^3[Atton]^7 'They came back. Tougher. You know what that means -- they're not going to stop.'",
    [3] = "^3[Atton]^7 'However this ends... I've seen that look before. On both sides.'",
}

-- ============================================
-- HELPER: Get scar source attribution text
-- ============================================
function ND.GetScarSource(g)
    if not g or not g.nemesis then return nil end
    for flagName, fn in pairs(ND.SCAR_SOURCES) do
        if g.flags[flagName] then
            return fn(g)
        end
    end
    return nil
end

return ND
