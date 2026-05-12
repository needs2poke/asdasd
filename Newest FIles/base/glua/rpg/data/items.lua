-- Echoes of the Dark Wars - Item Data
-- Centralized item definitions (replaces hardcoded tables)

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Items = {
    [0] = {
        name = "Salvaged Vibroblade",
        description = "A battered melee weapon. Better than bare hands.",
        type = "weapon",
        slot = "weapon",
        damage = 10,
        value = 50,
    },
    [1] = {
        name = "Datapad",
        description = "A standard datapad with personal notes.",
        type = "misc",
    },
    [2] = {
        name = "Sith Holocron",
        description = "A pulsing red pyramid of ancient Sith knowledge. It whispers.",
        type = "quest",
    },
    [3] = {
        name = "Medpac",
        description = "A standard medical kit. Restores health.",
        type = "consumable",
        healAmount = 30,
        usableInCombat = true,
        value = 20,
    },
    [4] = {
        name = "Broken Lightsaber Hilt",
        description = "The Jedi Shadow's lightsaber. The crystal is cracked.",
        type = "quest",
        examineText = "[BROKEN LIGHTSABER HILT]\n\n"
            .. "The focusing lens is shattered beyond manual repair.\n"
            .. "You'd need someone with precision optics experience...\n"
            .. "and a compatible crystal.",
    },
    [5] = {
        name = "Green Lightsaber Crystal",
        description = "A Dantooine crystal attuned to the Force. Glows faintly green.",
        type = "crystal",
        examineText = "[GREEN LIGHTSABER CRYSTAL]\n\n"
            .. "Jedi Consulars favored green crystals for their\n"
            .. "resonance with wisdom and insight.\n"
            .. "It vibrates when held near the broken hilt.",
    },
    [6] = {
        name = "Blue Lightsaber Crystal",
        description = "A Dantooine crystal attuned to the Force. Glows faintly blue.",
        type = "crystal",
        examineText = "[BLUE LIGHTSABER CRYSTAL]\n\n"
            .. "Jedi Guardians favored blue crystals for combat\n"
            .. "discipline and focus.\n"
            .. "It vibrates when held near the broken hilt.",
    },
    [7] = {
        name = "Jedi Shadow's Datapad",
        description = "Contains star charts and encrypted notes. The Shadow was tracking something.",
        type = "quest",
    },
    [8] = {
        name = "Blaster Pistol",
        description = "A reliable sidearm. Standard issue for anyone without a lightsaber.",
        type = "weapon",
        slot = "weapon",
        damage = 8,
        value = 40,
    },
    [9] = {
        name = "Padded Jacket",
        description = "A worn but serviceable padded jacket. Offers basic protection.",
        type = "armor",
        slot = "armor",
        defense = 3,
        value = 30,
    },
    [10] = {
        name = "Militia Armor",
        description = "Standard-issue armor worn by Khoonda's volunteer militia. Sturdy and practical.",
        type = "armor",
        slot = "armor",
        defense = 5,
        statBonus = { CON = 1 },
        value = 80,
    },
    [11] = {
        name = "Crystal Cave Robes",
        description = "Robes infused with the resonance of Dantooine's crystals. They hum faintly with the Force.",
        type = "armor",
        slot = "armor",
        defense = 2,
        statBonus = { WIS = 2 },
        value = 100,
    },
    [12] = {
        name = "Arkanian Medpac",
        description = "A premium Arkanian-manufactured medical kit. Military-grade bacta concentration.",
        type = "consumable",
        healAmount = 50,
        usableInCombat = true,
        value = 40,
    },
    [13] = {
        name = "Antidote Kit",
        description = "A compact detoxification kit. Neutralizes most organic and synthetic poisons.",
        type = "consumable",
        usableInCombat = true,
        curePoison = true,
        value = 25,
    },
    [14] = {
        name = "Echani Vibroblade",
        description = "An Echani-forged blade. The edge vibrates at a molecular frequency.",
        type = "weapon",
        slot = "weapon",
        damage = 14,
        value = 120,
    },
    [15] = {
        name = "Czerka Scorpion Blaster",
        description = "A Czerka Arms heavy pistol. Reliable, powerful, and ubiquitous in the Outer Rim.",
        type = "weapon",
        slot = "weapon",
        damage = 12,
        value = 100,
    },
    [16] = {
        name = "Mandalorian Mesh Vest",
        description = "Mandalorian-pattern armor mesh. Light enough for scouts, tough enough for a firefight.",
        type = "armor",
        slot = "armor",
        defense = 4,
        value = 60,
    },
    [17] = {
        name = "Jal Shey Utility Belt",
        description = "A Jal Shey Force-sensitive utility belt. Enhances reflexes through micro-kinetic feedback.",
        type = "accessory",
        slot = "accessory",
        statBonus = { DEX = 2 },
        value = 80,
    },
    [18] = {
        name = "Adrenal Stimulant",
        description = "A combat stimulant derived from Tarisian synthetics. Sharpens reflexes for one decisive strike.",
        type = "consumable",
        usableInCombat = true,
        damageBonus = 5,
        value = 30,
    },
    [19] = {
        name = "Field Rations",
        description = "Vacuum-sealed rations. Tasteless, but they keep you moving.",
        type = "consumable",
        healAmount = 15,
        usableInCombat = true,
        value = 15,
    },
    [20] = {
        name = "Faded Jedi Holorecord",
        description = "A scratched holoprojector from the old Enclave. The recording is fragmentary.",
        type = "misc",
        value = 20,
        examineText = "The hologram flickers to life -- a Jedi historian recounting the Great Hyperspace War. Naga Sadow's invasion, the fall of the Sith Empire, the scattering of Sith knowledge across the Outer Rim. The recording cuts out mid-sentence, as if someone stopped it deliberately.",
    },
    [21] = {
        name = "Sith War Blade",
        description = "A cortosis-laced blade from the Sith Wars. The metal drinks light. Etched runes pulse faintly in the dark.",
        type = "weapon",
        slot = "weapon",
        damage = 16,
        value = 200,
    },
    [22] = {
        name = "Exchange Nerve Toxin",
        description = "A vial of concentrated neurotoxin. Exchange enforcers use it to soften up targets. Illegal on most worlds.",
        type = "consumable",
        usableInCombat = true,
        applyPoison = { damage = 4, rounds = 3 },
        value = 50,
    },
    [23] = {
        name = "Sliced Stim Injector",
        description = "A modified stim injector with boosted output. The slicing leaves neurochemical residue -- side effects guaranteed.",
        type = "consumable",
        usableInCombat = true,
        healAmount = 40,
        paranoia = 5,
        value = 35,
    },

    -- ============================================
    -- ENCLAVE SUBLEVEL ITEM (ID 30)
    -- ============================================
    [30] = {
        name = "Fragment of Revan's Journal",
        description = "A damaged datapad from the Enclave archives. The entry is dated five years ago.",
        type = "misc",
        value = 0,
        examineText = "[PERSONAL LOG - ENCRYPTED]\n\n"
            .. "'I remember storms. An endless sky of\n"
            .. "lightning and darkness. Something waits\n"
            .. "there -- not Sith as we know them, but\n"
            .. "something older.\n\n"
            .. "Bastila begs me not to go, but if I\n"
            .. "don't, it will come for all of us.\n\n"
            .. "If I don't return, tell my child I\n"
            .. "chose this.\n\n"
            .. "-- R.'",
    },

    -- ============================================
    -- ACT 2: ONDERON ITEMS (IDs 24+)
    -- ============================================
    [24] = {
        name = "Mechanic's Datapad",
        description = "Jeth's personal datapad. Covered in grease and burn marks. Contains Holocron research notes and containment schematics.",
        type = "quest",
        examineText = "[JETH'S RESEARCH NOTES - PRIVATE]\n\n'Onderon Archives Reference: Sith Holocron containment protocols.'\n'Serial: X4-9B -- Ancient locking mechanism. Requires numerical cipher.'\n'The Holocron isn't just a teaching device. It's a PRISON.'\n'Something is trapped inside. Something that wants out.'\n'The cipher is scattered across artifacts. 9 digits total.'\n\n^3[Sequence fragment: 4... 9...]^7",
    },

    [25] = {
        name = "Security Badge - Sector 9",
        description = "A blood-stained officer's security badge. The holographic seal is cracked. Whoever carried this died badly.",
        type = "quest",
        examineText = "[ONDERON ROYAL GUARD - SECTOR 9 ACCESS]\n\nOfficer: Lt. Kael Dreyen\nClearance: Level 3\nAssignment: Lower Levels patrol\n\nOn the back, scratched into the metal with a fingernail:\n'^3 2 - 1 - 7 - 3 ^7'\n\nThe numbers look frantic. Written in a hurry -- or in fear.",
    },

    [26] = {
        name = "Medical Injector (Sedative)",
        description = "A neural dampener injector from Doctor Venn's clinic. Suppresses Force sensitivity and calms paranoid episodes. The tradeoff is real.",
        type = "consumable",
        usableInCombat = false,
        value = 0,
        examineText = "[IZIZ MEDICAL - NEURAL DAMPENER]\n\nSuppresses Force-sensitive neural pathways for 6 hours.\nSide effects: emotional blunting, reduced Force perception,\nmild dissociation.\n\n'^1WARNING: Extended use may cause permanent Force attenuation.^7'",
    },

    [27] = {
        name = "Encrypted Holoprojector",
        description = "A Jedi Council emergency broadcast unit. The encryption is military-grade but degraded by age. Static and fragments of a desperate message.",
        type = "quest",
        examineText = "[JEDI COUNCIL - EMERGENCY BROADCAST]\n[ENCRYPTION: PARTIALLY DEGRADED]\n\n'...all Shadow operatives... recall immediately...'\n'The Holocron contains a Sith Lord. Repeat: a SITH LORD.'\n'...containment failure imminent... do NOT attempt to open...'\n'...Karath Vren dispatched to... [CORRUPTED]...'\n'...may the Force be with us all.'\n\n^1[Signal terminates]^7",
    },

    [28] = {
        name = "Beast Rider Gauntlets",
        description = "Gauntlets carved from Dxun beast bone, lined with cortosis mesh. The Beast Riders of Onderon wore these to control drexls in flight.",
        type = "accessory",
        slot = "accessory",
        statBonus = { STR = 1, CON = 1 },
        value = 150,
    },

    [29] = {
        name = "Dxun Jungle Extract",
        description = "A concentrated stimulant brewed from Dxun jungle flora. Mandalorian scouts used it during the wars. Burns going down. Hits hard.",
        type = "consumable",
        usableInCombat = true,
        healAmount = 35,
        damageBonus = 3,
        value = 45,
    },

    [31] = {
        name = "Fragment of Dark Crystal",
        description = "A shard of crystallized dark-side energy. It fell from the Stalker when you survived the encounter. It pulses with a frequency that makes your teeth ache.",
        type = "quest",
        examineText = "[DARK CRYSTAL FRAGMENT]\n\nThe shard is warm to the touch and vibrates at a subsonic frequency.\nHolding it near the Holocron causes both to resonate.\n\nEtched into the crystal's lattice, visible only under\nForce-enhanced perception:\n'^3 9 ^7'\n\nA single digit. Part of something larger.\n\nAt a different angle the lattice catches the light --\na scorched identification imprint, half-erased:\n\n'^1NALEN VORR, JEDI SHADOW^7'\n\nThe Shadow had a name.",
    },

    [32] = {
        name = "Spaceport Transit Permit",
        description = "An official Onderon transit permit. You could board any ship and leave. The Holocron hums louder when you hold it, as if daring you to try.",
        type = "quest",
        examineText = "[ONDERON TRANSIT AUTHORITY]\n\nPermit Type: One-way departure\nDestination: Open\nPassenger: [BLANK]\n\nYou could fill in any name. Board any ship.\nLeave all of this behind.\n\nThe Holocron whispers: '^1You can run. But I am already inside you.^7'",
    },

    [33] = {
        name = "Meetra Surik's Meditation Crystal",
        description = "A dead crystal. No color, no resonance, no connection to the Force. The Jedi Exile carried this at Malachor V, before she severed herself from the Force. She left it behind when she reconnected -- a reminder of what silence felt like.",
        type = "misc",
        value = 0,
        examineText = "[MEDITATION CRYSTAL - INERT]\n\nMeetra Surik carried this crystal at Malachor V. When she\nsevered herself from the Force, the crystal died with her\nconnection.\n\nYears later, she reconnected -- but this crystal never\nwoke up. She left it behind. A scar from the wound.\n\nThe Holocron goes silent when you hold this crystal.\nCompletely, utterly silent.\n\nFor the first time in weeks, your mind is your own.",
    },

    [34] = {
        name = "Atris's Training Manual",
        description = "A tactical treatise by a Jedi archivist who believed knowledge could replace instinct. Methodical, rigid, ultimately flawed.",
        type = "misc",
        value = 30,
        examineText = "[JEDI TRAINING MANUAL - MASTER ATRIS]\n\n"
            .. "'Rule 1: The Force reveals. The mind interprets.'\n"
            .. "'Rule 2: Every Sith betrays a pattern. Find it.'\n"
            .. "'Rule 3: If instinct fails, fall back on preparation.'\n\n"
            .. "The pages are crisp, obsessively organized.\n"
            .. "Someone believed knowledge alone could save the galaxy.\n"
            .. "That thought is... troubling.",
    },

    [35] = {
        name = "Onderon War Horn",
        description = "A weapon carved from a drexl tusk. The Beast Riders blew these to rally their mounts. The sound carries for kilometers -- and something about it silences the Holocron.",
        type = "weapon",
        slot = "weapon",
        damage = 18,
        value = 200,
    },

    -- ============================================
    -- ACT 5: ENDGAME ITEMS
    -- ============================================
    [36] = {
        name = "Memory - Your Sacrifice",
        description = "A crystallized Force memory. It pulses with warmth and grief.",
        type = "quest",
        examineText = "[FORCE MEMORY - CRYSTALLIZED]\n\n"
            .. "The memory plays in your mind:\n"
            .. "A woman in Jedi robes, standing between you\n"
            .. "and darkness. She speaks a word you can't hear.\n"
            .. "Then light -- and silence.\n\n"
            .. "On the crystal's surface, two numbers glow:\n"
            .. "^3 4... 9 ^7\n\n"
            .. "The last digits of a code she tried to tell you.",
    },

    -- ============================================
    -- LIGHTSABER CONSTRUCTION ITEMS (IDs 37-41)
    -- ============================================
    [37] = {
        name = "Lightsaber (Green)",
        description = "Kira's lightsaber, reborn. The green blade hums with steady wisdom.",
        type = "weapon",
        slot = "weapon",
        damage = 20,
        value = 0,
        statBonus = { WIS = 2, INT = 1 },
        examineText = "[LIGHTSABER - GREEN CRYSTAL]\n\n"
            .. "The blade feels like an extension of your thoughts.\n"
            .. "When you close your eyes, you can almost hear\n"
            .. "Kira whispering approval through the Force.",
    },
    [38] = {
        name = "Lightsaber (Blue)",
        description = "Kira's lightsaber, reborn. The blue blade hums with disciplined focus.",
        type = "weapon",
        slot = "weapon",
        damage = 22,
        value = 0,
        statBonus = { STR = 2, DEX = 1 },
        examineText = "[LIGHTSABER - BLUE CRYSTAL]\n\n"
            .. "The blade feels like an extension of your thoughts.\n"
            .. "When you close your eyes, you can almost hear\n"
            .. "Kira whispering approval through the Force.",
    },
    [39] = {
        name = "Lightsaber (Sickly Green)",
        description = "Kira's lightsaber, corrupted. The blade pulses with an irregular, hungry vibration.",
        type = "weapon",
        slot = "weapon",
        damage = 24,
        value = 0,
        paranoia = 2,
        statBonus = { WIS = 3, INT = 1 },
        examineText = "[LIGHTSABER - CORRUPTED GREEN CRYSTAL]\n\n"
            .. "The blade is stronger than it should be.\n"
            .. "Saevus's whisper lives in the crystal now --\n"
            .. "a constant low murmur at the edge of hearing.\n\n"
            .. "The blade hums with an irregular, hungry vibration.",
    },
    [40] = {
        name = "Lightsaber (Dark Blue)",
        description = "Kira's lightsaber, corrupted. The blade pulses with an irregular, hungry vibration.",
        type = "weapon",
        slot = "weapon",
        damage = 26,
        value = 0,
        paranoia = 2,
        statBonus = { STR = 3, DEX = 1 },
        examineText = "[LIGHTSABER - CORRUPTED BLUE CRYSTAL]\n\n"
            .. "The blade is stronger than it should be.\n"
            .. "Saevus's whisper lives in the crystal now --\n"
            .. "a constant low murmur at the edge of hearing.\n\n"
            .. "The blade hums with an irregular, hungry vibration.",
    },
    [41] = {
        name = "Focusing Lens",
        description = "A precision-ground lens Jeth fabricated from salvaged optics. Compatible with the broken lightsaber hilt.",
        type = "quest",
        value = 0,
        examineText = "[FOCUSING LENS - CUSTOM FABRICATION]\n\n"
            .. "Jeth ground this from salvaged ship optics.\n"
            .. "It replaces the shattered lens in Kira's hilt.\n"
            .. "The crystal housing should accept it cleanly.\n\n"
            .. "Now you need a Force-attuned place to assemble.",
    },
}

--- Get item name by ID
function RPG.Data.GetItemName(itemId)
    local item = RPG.Data.Items[itemId]
    return item and item.name or ("Item #" .. itemId)
end

return RPG.Data.Items
