-- Echoes of the Dark Wars - Class Definitions
-- 6 playable classes with stat templates

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Classes = {
    guardian = {
        id = "guardian",
        name = "The Forsaken",
        description = "Once a Jedi Guardian. Your saber arm remembers what your mind has forgotten. High strength and endurance — but the Force answers reluctantly, and every swing feels heavier than it should.",
        stats = { STR = 16, DEX = 12, CON = 14, WIS = 10, INT = 8, CHA = 12 },
        hp = 120, maxHP = 120,
        fp = 100, maxFP = 100,
        startingItems = { 0, 3, 9 }, -- Salvaged Vibroblade, Medpac, Padded Jacket
        color = "^5",
        forceUser = true,
        startingAbilities = { "force_sense", "battle_meditation", "force_push" },
    },
    consular = {
        id = "consular",
        name = "The Awakened",
        description = "Once a Jedi Consular. The Force floods back unbidden — too much, too fast. Deep reserves of power you can barely control, in a body that hasn't channeled this energy in years.",
        stats = { STR = 8, DEX = 10, CON = 10, WIS = 18, INT = 14, CHA = 14 },
        hp = 80, maxHP = 80,
        fp = 180, maxFP = 180,
        startingItems = { 0, 3, 9 }, -- Salvaged Vibroblade, Medpac, Padded Jacket
        color = "^2",
        forceUser = true,
        startingAbilities = { "force_sense", "force_attunement", "force_push" },
    },
    sentinel = {
        id = "sentinel",
        name = "The Unseen",
        description = "Once a Jedi Sentinel. You survived by disappearing. Balanced skills, sharp instincts, and a talent for seeing what others miss — but the Force keeps dragging you back into the light.",
        stats = { STR = 12, DEX = 14, CON = 12, WIS = 14, INT = 12, CHA = 12 },
        hp = 100, maxHP = 100,
        fp = 140, maxFP = 140,
        startingItems = { 0, 3, 9 }, -- Salvaged Vibroblade, Medpac, Padded Jacket
        color = "^3",
        forceUser = true,
        startingAbilities = { "force_sense", "mental_fortress", "force_push" },
    },
    scoundrel = {
        id = "scoundrel",
        name = "The Ghost",
        description = "You ran from something. Maybe the law, maybe worse. Latent Force sensitivity -- dormant until awakened. A fast mouth and faster hands. You survive by being the person nobody remembers seeing.",
        stats = { STR = 10, DEX = 16, CON = 12, WIS = 10, INT = 12, CHA = 16 },
        hp = 100, maxHP = 100,
        fp = 40, maxFP = 40,
        startingItems = { 8, 3, 9 }, -- Blaster Pistol, Medpac, Padded Jacket
        color = "^6",
        forceUser = true,
        latentForce = true,
        startingAbilities = { "blaster_shot", "dirty_trick" },
    },
    soldier = {
        id = "soldier",
        name = "The Veteran",
        description = "A survivor of the Mandalorian Wars. Latent Force sensitivity — suppressed, mistaken for instinct. Grit, scar tissue, and enough firepower to level a building. You've buried more friends than most people have met.",
        stats = { STR = 16, DEX = 12, CON = 16, WIS = 8, INT = 10, CHA = 10 },
        hp = 140, maxHP = 140,
        fp = 30, maxFP = 30,
        startingItems = { 8, 3, 9 }, -- Blaster Pistol, Medpac, Padded Jacket
        color = "^1",
        forceUser = true,
        latentForce = true,
        startingAbilities = { "war_cry", "shield_bash" },
    },
    hunter = {
        id = "hunter",
        name = "The Hunter",
        description = "A professional tracker stranded on the wrong planet. Latent Force sensitivity -- your precision was never just skill. Gadgets, traps, and a cold eye for weakness. Your targets used to pay bounties. Now they just try to kill you.",
        stats = { STR = 14, DEX = 14, CON = 14, WIS = 10, INT = 12, CHA = 8 },
        hp = 120, maxHP = 120,
        fp = 30, maxFP = 30,
        startingItems = { 8, 3, 9 }, -- Blaster Pistol, Medpac, Padded Jacket
        color = "^8",
        forceUser = true,
        latentForce = true,
        startingAbilities = { "blaster_shot", "tracking_shot" },
    },
}

-- Ordered list for menu display
RPG.Data.ClassOrder = {
    "guardian", "consular", "sentinel", "scoundrel", "soldier", "hunter"
}

-- Stat display order
RPG.Data.StatOrder = { "STR", "DEX", "CON", "WIS", "INT", "CHA" }

-- Stat full names
RPG.Data.StatNames = {
    STR = "Strength",
    DEX = "Dexterity",
    CON = "Constitution",
    WIS = "Wisdom",
    INT = "Intelligence",
    CHA = "Charisma",
}

return RPG.Data.Classes
