-- Echoes of the Dark Wars - Room Definitions
-- Act 1: Dantooine (Rooms 0-16)
-- Act 2: Onderon / Iziz (Rooms 26-35)
-- Named-key exits fix Bug #3 (no array index overwrite)

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Rooms = {

    [0] = {
        id = 0,
        name = "Your Quarters",
        description = "A modest room in Khoonda Settlement. Morning light filters through a small window. Your worn cot sits in the corner. A distant EXPLOSION rattles the walls. Something's happened outside.",
        shortDesc = "Your quarters in Khoonda.",
        exits = { North = 1 },
        items = { 0, 1 },   -- Training Saber, Datapad
        npcs = {},
        act = 1,
        ambience = {
            "^8Morning light shifts across the floor.^7",
            "^8Dust motes drift in a thin sunbeam.^7",
            "^8The cot creaks in the silence.^7",
            "^8Distant shouts echo from the settlement.^7",
        },
        sounds = { enter = "sound/movers/doors/door1_open.wav" },
    },

    [1] = {
        id = 1,
        name = "Khoonda Settlement - Main Hall",
        description = "The central hall bustles with panicked settlers. People shout over each other. Through the eastern windows, you see smoke rising from the Crystal Caves. Administrator Terena Adare stands near the exit, trying to restore order.",
        shortDesc = "The bustling main hall of Khoonda.",
        exits = { North = 2, East = 3, South = 0, West = 10, Northeast = 11 },
        items = {},
        npcs = { 0 },       -- Administrator Terena Adare
        act = 1,
    },

    [2] = {
        id = 2,
        name = "Khoonda Settlement - Plaza",
        description = "The open plaza. Settlers trade goods, merchants hawk wares. A crashed speeder smokes in the corner. To the north, the path leads toward the Crystal Caves where the crash occurred. Merchant Goran argues with a customer.",
        shortDesc = "The open plaza of Khoonda.",
        exits = { North = 4, South = 1, East = 13, West = 12 },
        items = {},
        npcs = { 1 },       -- Merchant Goran
        act = 1,
    },

    [3] = {
        id = 3,
        name = "Khoonda Cantina",
        description = "A dingy cantina. The smell of cheap ale and desperation. Spacers huddle in corners. A scarred veteran sits alone, staring into his drink. The bartender polishes glasses, pretending not to listen to whispered conversations.",
        shortDesc = "A dingy cantina in Khoonda.",
        exits = { West = 1 },
        items = {},
        npcs = { 2 },       -- Atton Rand
        act = 1,
    },

    [4] = {
        id = 4,
        name = "Path to Crystal Caves",
        description = "The path winds through tall grass toward the caves. The crashed ship is visible ahead, its hull torn open, smoke billowing. Militia patrols have cordoned off the area. You can see Exchange thugs arguing with them. This is going to get ugly.",
        shortDesc = "A grassy path leading to the caves.",
        exits = { North = 5, South = 2 },
        items = {},
        npcs = {},
        encounter = 0,      -- Kinrath Hatchling (random)
        act = 1,
        locked = true,
        lockMessage = "A militia guard blocks the path. 'Administrator Adare wants a word with newcomers. She's in the Main Hall, south of the Plaza.'",
    },

    [5] = {
        id = 5,
        name = "Crash Site",
        description = "The wreckage is worse up close. The ship - a modified light freighter - punched through the canopy and slammed into the rocky ground. Twisted metal everywhere. The hull is scorched black. Militia scouts have set up a perimeter. Exchange muscle skulks at the edges. A Jedi symbol is barely visible on the ship's side panel, scratched and faded. The boarding ramp is down. Something dark radiates from within - a presence in the Force, cold and ancient.",
        shortDesc = "The crashed Jedi freighter.",
        exits = { North = 6, East = 7, South = 4 },
        items = { 3 },      -- Medpac
        npcs = {},
        act = 1,
        ambience = {
            "^8Metal groans in the wreckage.^7",
            "^8Smoke curls from a ruptured fuel line.^7",
            "^8A militiaman mutters into his comm unit.^7",
            "^8The hull ticks as it cools.^7",
        },
        sounds = { enter = "sound/effects/glassbreak1.wav" },
    },

    [6] = {
        id = 6,
        name = "Crashed Ship - Main Hold",
        description = "Emergency lighting flickers red. The cargo hold is torn apart - crates smashed, contents scattered. Blood stains the deck plates. In the corner, slumped against the wall, is a woman in dark robes. Jedi. Dead. Her lightsaber lies beside her, hilt cracked. In her hand, clutched tight even in death: a Sith Holocron. It pulses with a sickly red glow. You feel it calling to you through the Force. Behind you, footsteps. Someone else is coming.",
        shortDesc = "Inside the wrecked freighter.",
        exits = { South = 5 },
        items = { 2, 4, 7 }, -- Sith Holocron, Broken Lightsaber Hilt, Jedi Shadow's Datapad
        npcs = {},
        act = 1,
        ambience = {
            "^8Red emergency lights pulse overhead.^7",
            "^8Something drips in the darkness.^7",
            "^8The deck plates groan underfoot.^7",
            "^8A faint hum rises from the Holocron.^7",
        },
        paranoidAmbience = {
            "^1The Holocron's glow intensifies.^7",
            "^1You feel eyes on you from the shadows.^7",
            "^1The dead Jedi's hand twitches. No. Imagined.^7",
            "^1Whispers bleed from the walls.^7",
        },
        sounds = { enter = "sound/weapons/force/drain.wav" },
    },

    [7] = {
        id = 7,
        name = "Crystal Cave Entrance",
        description = "The cave mouth yawns open, natural rock formations framing the entrance. Dantooine's famous crystals line the walls, glowing faintly. These caves once supplied the Jedi Order with lightsaber crystals. Now they're abandoned, stripped bare during the wars. Still, deeper caves might hold secrets. The air is cool, and you hear water dripping in the darkness.",
        shortDesc = "Entrance to the Crystal Caves.",
        exits = { North = 8, West = 5 },
        items = {},
        npcs = {},
        encounter = 1,      -- Kinrath (adult)
        act = 1,
    },

    [8] = {
        id = 8,
        name = "Deep Crystal Caves",
        description = "The tunnel opens into a massive natural cavern. Crystals everywhere - blue, green, violet - jutting from walls and ceiling. Light refracts through them, painting the cave in shifting colors. This place resonates with the Force. You feel the echoes of a thousand Jedi who came here seeking their crystals. In the far wall, partially hidden by a rockfall, you notice a carved archway. Jedi symbols. Old ones.",
        shortDesc = "A vast crystal-filled cavern.",
        exits = { North = 9, South = 7 },
        items = { 5, 6 },   -- Green Crystal, Blue Crystal
        npcs = {},
        encounter = 3,      -- Kinrath Matriarch (mini-boss)
        act = 1,
        ambience = {
            "^8Crystals hum with a resonance you feel in your bones.^7",
            "^8Light refracts in shifting prismatic waves.^7",
            "^8The Force echoes here, layered and ancient.^7",
            "^8Water drips somewhere deep in the dark.^7",
        },
        paranoidAmbience = {
            "^1The crystals pulse in time with your heartbeat.^7",
            "^1Shapes move in the refracted light.^7",
            "^1The echoes sound like voices. Calling your name.^7",
            "^1Something watches from behind the rockfall.^7",
        },
        sounds = { enter = "sound/weapons/saber/saberhum1.wav" },
    },

    [9] = {
        id = 9,
        name = "Ancient Jedi Chamber",
        description = "A small, hidden meditation chamber. The Jedi Shadow must have known about this place. Stone benches arranged in a circle. Faded murals on the walls showing the history of the Jedi Order. A small altar holds a training holocron - blue and gold, dormant but intact. On the floor, written in chalk: coordinates. Star charts. The Shadow was tracking something. This chamber might be the safest place to examine the Sith Holocron... if you dare.",
        shortDesc = "A hidden Jedi meditation chamber.",
        exits = { South = 8 },
        items = { 11 },     -- Crystal Cave Robes
        npcs = { 25 },      -- Meditation Alcove (lightsaber assembly)
        act = 1,
        ambience = {
            "^8The murals seem to shift as you look away.^7",
            "^8Silence presses in, heavy and sacred.^7",
            "^8The chalk coordinates glow faintly.^7",
            "^8The Force is calm here. Waiting.^7",
        },
        paranoidAmbience = {
            "^1The murals depict your face. They always have.^7",
            "^1The training holocron flickers in response to yours.^7",
            "^1The chalk symbols rearrange when you blink.^7",
            "^1This place was prepared for you. Long ago.^7",
        },
        sounds = { enter = "sound/weapons/force/see.wav" },
    },

    [10] = {
        id = 10,
        name = "Khoonda Medical Bay",
        description = "A small medical facility. Two beds, both occupied by wounded settlers. Medical droids move between patients. The doctor - a Twi'lek woman - looks exhausted. 'We're not equipped for this,' she says to no one in particular. 'This was supposed to be a peaceful settlement.' Shelves hold basic medical supplies. The smell of bacta and antiseptic fills the air.",
        shortDesc = "The settlement medical facility.",
        exits = { East = 1 },
        items = {},
        npcs = { 3 },   -- Doctor Vara Denn
        act = 1,
        ambience = {
            "^8A medical droid beeps softly.^7",
            "^8The smell of bacta hangs in the air.^7",
            "^8A wounded settler groans in their sleep.^7",
            "^8Monitoring equipment hums steadily.^7",
        },
        sounds = { enter = "sound/weapons/force/heal.wav" },
    },

    [11] = {
        id = 11,
        name = "Khoonda Archives",
        description = "A modest library and records room. Datapads stacked on shelves, some collecting dust. Settlement records, agricultural reports, historical archives about Dantooine's past. One terminal is dedicated to Jedi history - back when the Enclave stood proud. An elderly human male sits reading. He looks up as you enter. 'Not many come here anymore. People want to forget the past. But history has a way of repeating itself.'",
        shortDesc = "Settlement records and archives.",
        exits = { South = 1 },
        items = {},
        npcs = { 4 },   -- Archivist Tamas
        act = 1,
        ambience = {
            "^8A datapad flickers on a dusty shelf.^7",
            "^8Pages rustle in a draft you can't feel.^7",
            "^8The terminal hums, awaiting input.^7",
            "^8Dust settles on forgotten histories.^7",
        },
        sounds = { enter = "sound/movers/switches/switch1.wav" },
    },

    [12] = {
        id = 12,
        name = "Khoonda Barracks",
        description = "The settlement's security forces bunk here. Spartan room with metal beds and footlockers. A weapons rack holds blaster rifles - civilian grade, nothing military. Maps of the area on the wall, with red marks showing kinrath nests and salvage sites. Most of the militia are farmers playing soldier. They're not ready for what's coming.",
        shortDesc = "Militia barracks.",
        exits = { East = 2 },
        items = { 10 },     -- Militia Armor
        npcs = { 5 },       -- Captain Zherron
        act = 1,
    },

    [13] = {
        id = 13,
        name = "Dantooine Fields",
        description = "Open grasslands stretch to the horizon. The wind makes the tall grass dance in waves. In the distance, you can see the ruins of the Jedi Enclave. A rough-looking figure leans against a boulder, flanked by thugs. Draxen, the Exchange boss, surveys his territory with a predator's patience. The air smells clean out here. The galaxy's problems feel far away - except for the crime lord blocking the path.",
        shortDesc = "Open grasslands. Exchange territory.",
        exits = { North = 14, West = 2 },
        items = {},
        npcs = { 6 },       -- Draxen
        encounter = 2,      -- Exchange Thug
        act = 1,
        locked = true,
        lockMessage = "A settler warns you. 'The fields are crawling with kinrath. Talk to Administrator Adare first -- Main Hall, south of the Plaza.'",
    },

    [14] = {
        id = 14,
        name = "Jedi Enclave Ruins - Approach",
        description = "The Jedi Enclave. Or what's left of it. Darth Malak's bombardment left the grand structure in ruins. Collapsed walls, scorched stone, shattered transparisteel. The main courtyard is a crater. A feral kath hound stalks between the rubble, its eyes tracking your movement. This place was a beacon of the Light. Now it's a tomb. The main entrance is collapsed, but there might be a way in through the sublevel.",
        shortDesc = "The ruined Jedi Enclave.",
        exits = { South = 13, North = 15 },
        items = {},
        npcs = {},
        encounter = 4,      -- Kath Hound
        act = 1,
        ambience = {
            "^8Wind whistles through the shattered walls.^7",
            "^8Scorched stone crumbles underfoot.^7",
            "^8The Force feels thin here. Wounded.^7",
            "^8A kath hound howls in the distance.^7",
        },
        sounds = { enter = "sound/effects/glassbreak1.wav" },
    },

    [15] = {
        id = 15,
        name = "Jedi Enclave - Sublevel Archives",
        description = "The sublevel survived the bombardment. Emergency lighting flickers, casting shadows across rows of damaged datapads and fallen shelves. A deactivated salvager droid hums back to life as you approach, its optical sensor locking onto you. This was the archive - the repository of Jedi knowledge collected over millennia. Most of it is destroyed. Burned. Erased. But you sense something here. The Force is strong in this place.",
        shortDesc = "Sublevel of the ruined Enclave.",
        exits = { South = 14 },
        items = { 30 },     -- Fragment of Revan's Journal
        npcs = {},
        encounter = 5,      -- Salvager Droid
        act = 1,
        ambience = {
            "^8Emergency lights flicker in a broken rhythm.^7",
            "^8Fallen shelves cast long shadows.^7",
            "^8The Force gathers here, dense and layered.^7",
            "^8A droid servo whirs faintly in the dark.^7",
        },
        sounds = { enter = "sound/weapons/force/absorb.wav" },
    },

    [16] = {
        id = 16,
        name = "Your Ship - The Wanderer",
        description = "Your personal freighter. Small, old, but reliable. The cockpit smells like recycled air and caf. Navigation console, hyperspace coordinates, fuel reserves - all functional. The Holocron sits in the co-pilot seat. You didn't put it there. It's always watching. From here, you can travel between worlds. Dantooine. Onderon. Dxun. But you can never truly escape. The Holocron won't let you.",
        shortDesc = "Your battered freighter.",
        exits = { West = 2, North = 17, East = 18, Southwest = 22 },
        items = {},
        npcs = {},
        act = 1,
        locked = true,       -- Unlocked after Act 1 completion
        lockMessage = "The ship's systems are powered down. You have no reason to leave Dantooine yet.",
        ambience = {
            "^8The cockpit smells of recycled air and caf.^7",
            "^8Navigation displays cast a dim glow.^7",
            "^8The engine idles with a low thrum.^7",
            "^8Star charts flicker on the console.^7",
        },
        paranoidAmbience = {
            "^1The Holocron watches from the co-pilot seat.^7",
            "^1The nav computer plots courses you didn't enter.^7",
            "^1The ship hums a frequency only you can hear.^7",
            "^1You can never leave. It won't let you.^7",
        },
        sounds = { enter = "sound/weapons/force/drain.wav", requireHolocron = true },
    },
    -- ============================================
    -- SHIP INTERIOR (Rooms 17-25)
    -- ============================================

    [17] = {
        id = 17,
        name = "The Wanderer - Bridge",
        description = "The bridge is cramped but functional. Star charts cover the viewport, layered over one another like palimpsests. The pilot's chair is worn through in places. A deactivated astrogation droid sits bolted to the floor, its photoreceptor dark. Through the viewport, hyperspace streaks or starfield — depending on where you're going. Nowhere feels far enough.",
        shortDesc = "The ship's bridge.",
        exits = { South = 16 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [18] = {
        id = 18,
        name = "The Wanderer - Main Corridor",
        description = "A narrow corridor connecting the ship's interior compartments. Overhead conduits run along the ceiling, patched in three places. The walls are bare durasteel, scored with old blaster marks from a previous owner's bad day. Doors branch off in every direction.",
        shortDesc = "The ship's main corridor.",
        exits = { West = 16, Northwest = 19, North = 20, South = 21 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [19] = {
        id = 19,
        name = "The Wanderer - Crew Quarters",
        description = "Two bunks, a footlocker, and a viewport the size of your hand. Someone scratched tally marks into the wall above the lower bunk — hundreds of them. A faded holo of a woman sits on the shelf, its subject long since degraded to static. Personal effects of a crew that never came back.",
        shortDesc = "Cramped crew quarters.",
        exits = { East = 18 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [20] = {
        id = 20,
        name = "The Wanderer - Medbay",
        description = "A compact medical station. The scanner hums on standby, its readout cycling through default diagnostics. A deactivated medical droid stands in the corner, its chassis dented but intact. Kolto patches line the wall rack. The air smells faintly of antiseptic and ozone.",
        shortDesc = "The ship's medical bay.",
        exits = { South = 18 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [21] = {
        id = 21,
        name = "The Wanderer - Workshop",
        description = "A cluttered workbench dominates the room. Hydrospanners, micro-soldering kits, and half-stripped components cover every surface. A vise holds something unidentifiable. Whoever owned this ship before you was either a mechanic or a lunatic. Possibly both.",
        shortDesc = "The ship's workshop.",
        exits = { North = 18, South = 23 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [22] = {
        id = 22,
        name = "The Wanderer - Armory",
        description = "A reinforced compartment with weapon racks along both walls. Most are empty. Scorch marks on the ceiling suggest someone discharged a blaster in here — recently. A locked munitions crate sits in the corner, its keypad blinking red. The ship's previous owner had enemies.",
        shortDesc = "The ship's armory.",
        exits = { East = 16 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [23] = {
        id = 23,
        name = "The Wanderer - Trophy Hall",
        description = "An empty room with display cases lining the walls. Glass shelves, brass placards, velvet inlays — someone designed this to hold trophies. The cases are empty. For now.",
        shortDesc = "A hall of empty display cases.",
        exits = { North = 21, West = 24, East = 25 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [24] = {
        id = 24,
        name = "The Wanderer - Port Gallery",
        description = "A narrow alcove with a viewport that stretches floor to ceiling. Stars drift past in silence. Display alcoves line the inner wall, sized for small artifacts. The light here is dim, almost reverent — a private museum for things not yet earned.",
        shortDesc = "Port-side gallery viewport.",
        exits = { East = 23 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    [25] = {
        id = 25,
        name = "The Wanderer - Starboard Gallery",
        description = "The mirror of the port gallery. Same viewport, same silence, same empty display alcoves. But the starfield looks different from this side — like a different sky entirely. An optical illusion, probably. Probably.",
        shortDesc = "Starboard-side gallery viewport.",
        exits = { West = 23 },
        items = {},
        npcs = {},
        act = 1,
        ambience = {
            "^8The hull groans softly in the void.^7",
            "^8Air recyclers hum behind the panels.^7",
            "^8A distant clank echoes through the ship.^7",
            "^8The deck plates vibrate faintly under your feet.^7",
        },
        paranoidAmbience = {
            "^1The ship breathes. Ships don't breathe.^7",
            "^1Footsteps in the corridor behind you. You're alone.^7",
            "^1The lights dim. The Holocron brightens.^7",
        },
    },

    -- ============================================
    -- ACT 2: ONDERON / IZIZ (Rooms 26-35)
    -- ============================================

    [26] = {
        id = 26,
        name = "Iziz Spaceport - Landing Pad Alpha",
        description = "The spaceport thrums with activity. Freighters land and take off in regulated chaos. The air reeks of fuel and ozone. Crowds of travelers -- humans, Twi'leks, droids -- push past you without a second glance. Overhead, Dxun hangs in the sky like a green wound. Your boots hit Onderon soil for the first time. The Holocron hums against your ribs, excited.",
        shortDesc = "Busy landing pad. Ships everywhere.",
        exits = { North = 28, East = 27, South = 32 },
        items = {},
        npcs = {},
        act = 2,
        ambience = {
            "^8A freighter's repulsors scream overhead.^7",
            "^8Fuel fumes burn your nostrils.^7",
            "^8A droid announcer drones departure times.^7",
            "^8The crowd surges around you, indifferent.^7",
        },
        voidDescription = "The spaceport goes silent. Ships hang frozen in the sky. The crowd stops breathing. Dxun's green glow fades to grey. The Holocron whispers: 'This is what the Dead World looked like. Before the ritual consumed it all.' Security checkpoints are heavier than usual -- the aftermath of Vaklu's failed coup still echoes through the bureaucracy.",
        sounds = { enter = "sound/movers/doors/door1_open.wav" },
    },

    [27] = {
        id = 27,
        name = "Iziz Cantina District",
        description = "Neon signs flicker above cramped doorways. Music spills from cantinas -- competing genres clashing in the narrow street. Spacers, smugglers, and worse crowd the bars. Someone bumps into you. Was it an accident? Their eyes linger too long. The smell of cheap ale and synth-spice hangs thick. Veterans of the civil war drink in corners, arguing about whether Talia's peace will hold.",
        shortDesc = "Loud, crowded cantina strip.",
        exits = { North = 30, South = 29, West = 26 },
        items = {},
        npcs = {},
        encounter = 6,       -- Onderon Thug (3rd cell source for Q15)
        act = 2,
        ambience = {
            "^8A group of thugs watches you from a cantina doorway.^7",
            "^8Bass thumps from a cantina doorway.^7",
            "^8A Devaronian laughs too loud at something.^7",
            "^8Neon reflections ripple in a puddle.^7",
            "^8Someone watches you from a darkened booth.^7",
        },
        voidDescription = "The music dies. The neon signs go dark. Every face in the crowd turns toward you simultaneously, mouths open, eyes empty. Then the moment passes and the noise returns. But the silence lingers in your bones.",
        sounds = { enter = "sound/movers/switches/switch1.wav" },
    },

    [28] = {
        id = 28,
        name = "Iziz Merchant Quarter",
        description = "Vendors hawk starship parts, rations, and questionable 'Jedi artifacts'. Crowds haggle loudly beneath durasteel awnings. A street vendor watches you with naked fear -- her lekku twitch as you pass. You catch fragments of conversation: '...glowing eyes...', '...happened again last night...'",
        shortDesc = "Bustling open-air market.",
        exits = { East = 31, South = 26, West = 35 },
        items = { 32 },      -- Spaceport Transit Permit
        npcs = { 13 },      -- Rila (street vendor)
        act = 2,
        voidDescription = "The market stalls blur. Colors leach from fabrics and fruits until everything is grey. The merchants' mouths move but no sound comes out. You are standing in the memory of a place that was consumed.",
        ambience = {
            "^8A merchant shouts prices at passing spacers.^7",
            "^8Crates of off-world goods stack high.^7",
            "^8The smell of grilled meat drifts from a stall.^7",
            "^8A protocol droid haggles in three languages.^7",
        },
        paranoidAmbience = {
            "^1[WHISPER] Is that a lightsaber hilt? Tell the Royal Guard...^7",
            "^1Every merchant's smile is a mask. What are they hiding?^7",
            "^1The crowd parts around you. They know what you are.^7",
            "^1[WHISPER] ...saw someone just like that last night... near the bodies...^7",
        },
        sounds = { enter = "sound/movers/switches/switch1.wav" },
    },

    [29] = {
        id = 29,
        name = "Dark Alley",
        description = "The alley reeks of garbage and decay. Shadows pool unnaturally thick between the buildings. Graffiti on the wall reads: 'THE SHADOW WALKS'. Blood stains the permacrete -- fresh. A half-crushed security badge lies in the gutter. Something happened here. Recently.",
        shortDesc = "Dark, ominous alley.",
        exits = { North = 27, East = 32 },
        items = {},
        npcs = { 11 },      -- Mira Tovan (traumatized witness)
        encounter = 6,       -- Onderon Thug
        act = 2,
        voidDescription = "The alley stretches impossibly long. The graffiti dissolves into blank wall. The blood on the ground turns to ash, then to nothing. Silence so absolute your ears ring. This is what the Dead World felt like. A planet where the Force itself died.",
        ambience = {
            "^8Water drips from a broken pipe.^7",
            "^8A rat-like creature scurries through garbage.^7",
            "^8The stench of decay is overwhelming.^7",
            "^8Distant shouts echo from the cantina strip.^7",
        },
        paranoidAmbience = {
            "^1[WHISPER] ...saw the Jedi do it... purple eyes... just like that one...^7",
            "^1The blood on the ground is the same shade as the stain on your boots.^7",
            "^1The graffiti shifts when you blink: YOUR NAME.^7",
            "^1Something breathes in the dark behind you. Don't turn around.^7",
        },
        sounds = { enter = "sound/effects/glassbreak1.wav" },
    },

    [30] = {
        id = 30,
        name = "Apartment Complex - Hab Block 7",
        description = "Cramped living quarters stack to the ceiling. Screaming children, arguing couples, blaring holovids. The sensory assault is overwhelming. A mother pulls her child away from you, terrified. Through a grimy window, you glimpse someone in brown robes on the level below. When you blink, they're gone.",
        shortDesc = "Crowded residential block.",
        exits = { East = 34, South = 27 },
        items = {},
        npcs = {},
        act = 2,
        ambience = {
            "^8A child cries behind a thin wall.^7",
            "^8A holovid blares propaganda about Onderon's security.^7",
            "^8The hallway smells of synth-food and sweat.^7",
            "^8Footsteps echo above you, too heavy.^7",
        },
        voidDescription = "The children stop crying. The holovids cut to static, then to black. The walls contract. Every door in the hab block slams shut at once. For a long second, you are sealed inside absolute emptiness. Then the world returns. But one apartment door stays open. Inside: nothing. Not empty. Nothing.",
        sounds = { enter = "sound/movers/doors/door1_open.wav" },
    },

    [31] = {
        id = 31,
        name = "Security Checkpoint - Sector 4",
        description = "Onderon Royal Guard monitor scanners and check transit papers. A guard's hand moves to his blaster when you approach. The security droid's photoreceptors fix on you, tracking. Red text scrolls across the alert display. The guards mutter among themselves. You are being watched.",
        shortDesc = "Tense security zone.",
        exits = { North = 35, South = 33, West = 28 },
        items = {},
        npcs = { 12 },      -- Captain Saren (Onderon Security)
        encounter = 7,       -- Iziz Sentry Droid
        act = 2,
        voidDescription = "The checkpoint goes dark. Scanner beams die mid-sweep. The guards freeze in place like statues -- eyes open, unblinking. The security droid's photoreceptors go black. In the silence, you hear your own heartbeat. Nothing else. The Force is absent here.",
        ambience = {
            "^8Scanner beams sweep across the corridor.^7",
            "^8A guard mutters into a comm unit.^7",
            "^8The security droid's head pivots to track you.^7",
            "^8Booted footsteps echo in precise rhythm.^7",
        },
        paranoidAmbience = {
            "^1[WHISPER] That's the one from the footage. Don't let them leave...^7",
            "^1The guards know. They're just waiting for orders.^7",
            "^1The alert display shows your face. When did they get your image?^7",
            "^1[WHISPER] ...multiple homicides... matches the description...^7",
        },
        sounds = { enter = "sound/weapons/force/absorb.wav" },
    },

    [32] = {
        id = 32,
        name = "Lower Levels - Sublevel 3",
        description = "Beneath the gleaming spaceport, the city's underbelly festers. Flickering lights. Dripping pipes. Refugees huddle in alcoves while thugs extort credits from the desperate. A body floats in the drainage canal -- throat torn out. Claw marks on the walls. The refugees whisper: 'The thing with purple eyes did this.'",
        shortDesc = "Grimy undercity levels.",
        exits = { North = 26, East = 33, West = 29 },
        items = {},
        npcs = {},
        encounter = 6,       -- Onderon Thug
        act = 2,
        ambience = {
            "^8Water drips from corroded pipes.^7",
            "^8A refugee coughs in the shadows.^7",
            "^8Flickering lights cast moving shadows.^7",
            "^8Something metallic clangs deep in the tunnels.^7",
        },
        voidDescription = "The dripping stops. The flickering lights die. The refugees vanish -- not fleeing, just gone. The drainage canal is dry. The body is gone. The claw marks on the walls spell words in a language you almost understand. Almost. The void presses in from all sides.",
        sounds = { enter = "sound/effects/glassbreak1.wav" },
    },

    [33] = {
        id = 33,
        name = "Mechanic's Workshop - Jeth's Garage",
        description = "A cluttered workshop crammed with ship parts, power converters, and jury-rigged droids. A Duros mechanic -- Jeth -- works on a hyperdrive core under harsh work lights. Ancient texts and holocron schematics lie open on his workbench. He's been researching. When he sees you, his red eyes widen. 'I can help you,' he says carefully. 'But we must be quick. IT knows you're here.'",
        shortDesc = "Jeth's cluttered workshop. Sith research.",
        exits = { North = 31, West = 32 },
        items = { 24 },     -- Mechanic's Datapad
        npcs = { 10 },      -- Jeth the Scholar
        act = 2,
        ambience = {
            "^8A welding torch hisses somewhere.^7",
            "^8Datapads flicker with holocron schematics.^7",
            "^8Oil stains the floor in dark patterns.^7",
            "^8Jeth mutters calculations under his breath.^7",
        },
        voidDescription = "Jeth's tools fall silent. The schematics on his workbench go blank -- every page, every screen, every diagram. The Holocron rises from your pack on its own and hovers, spinning. Jeth's mouth moves but you hear only silence. The prison is aware you are trying to understand it.",
        sounds = { enter = "sound/movers/switches/switch1.wav" },
    },

    [34] = {
        id = 34,
        name = "Iziz Medical Clinic",
        description = "A sterile clinic humming with medical droids. Patients fill every bed. A trauma victim lies catatonic, staring at the ceiling -- drawing the same thing over and over on a datapad: a figure in robes with glowing purple eyes. The doctor glances up, exhausted. She's seen too many like this.",
        shortDesc = "Clean medical facility. Busy.",
        exits = { West = 30 },
        items = {},
        npcs = { 14 },      -- Doctor Venn (forensic physician)
        act = 2,
        voidDescription = "The medical droids stop mid-motion. The monitoring equipment flatlines -- all of it, simultaneously. The patients lie still. Too still. The bacta in the tanks turns black. Doctor Venn's mouth opens in a silent scream. Then it all snaps back. Normal. As if nothing happened.",
        ambience = {
            "^8A medical droid beeps its rounds.^7",
            "^8The smell of bacta and antiseptic is sharp.^7",
            "^8A patient mutters in fitful sleep.^7",
            "^8Monitoring equipment pulses steadily.^7",
        },
        sounds = { enter = "sound/weapons/force/heal.wav" },
    },

    [35] = {
        id = 35,
        name = "Spaceport Observation Deck",
        description = "Floor-to-ceiling transparisteel overlooks the sprawling city of Iziz. Onderon's jungle moon Dxun looms in the sky, its green canopy visible from orbit. The view should be breathtaking. Instead, you catch your reflection -- and for a moment, its eyes glow purple. You spin around. The crowd behind you has gone silent. Watching. Then the noise returns, and everyone is moving again. Normal. Were they?",
        shortDesc = "Panoramic view over Iziz. Unsettling.",
        exits = { East = 28, South = 31 },
        items = {},
        npcs = {},
        act = 2,
        ambience = {
            "^8Ships trace silver lines across the sky.^7",
            "^8Dxun's green bulk fills the upper viewport.^7",
            "^8The transparisteel hums faintly in the wind.^7",
            "^8A tourist couple argues about travel permits.^7",
        },
        voidDescription = "The transparisteel goes opaque. Iziz vanishes. Dxun vanishes. The sky becomes a flat grey nothing. Your reflection stares back at you -- but its eyes are closed. When it opens them, they are not your eyes. They are ancient. Patient. Hungry. Then the view returns. But the reflection takes a moment longer to match your pose.",
        sounds = { enter = "sound/weapons/force/see.wav" },
    },
    -- ============================================
    -- ACT 3: DXUN SITH TOMB (Rooms 36-42)
    -- ============================================

    [36] = {
        id = 36,
        name = "Dxun Surface - Tomb Approach",
        description = "The jungle moon's canopy breaks here, revealing a clearing of scorched earth. Massive stone steps descend into the hillside, carved with Sith runes that still glow faintly after millennia. The air is thick, humid, wrong. Every instinct screams to turn back. The Holocron thrums against your chest, eager. It knows this place. It remembers.",
        shortDesc = "Scorched clearing before the tomb entrance.",
        exits = { West = 16, North = 37 },
        items = {},
        npcs = {},
        act = 3,
        ambience = {
            "^8Jungle insects fall silent as you approach.^7",
            "^8The Sith runes pulse in time with your heartbeat.^7",
            "^8Humid air clings to your skin like a shroud.^7",
            "^8The Holocron hums louder here. Almost singing.^7",
        },
        paranoidAmbience = {
            "^1The runes spell your name. They always have.^7",
            "^1Something exhales from deep within the tomb.^7",
            "^1The jungle behind you has gone silent. Completely.^7",
            "^1The Holocron whispers: 'Welcome home, apprentice.'^7",
        },
        sounds = { enter = "sound/weapons/force/drain.wav" },
    },

    [37] = {
        id = 37,
        name = "Sith Tomb - Entrance Hall",
        description = "A vaulted corridor of black stone stretches before you. Braziers of cold fire — purple and unwavering — line the walls. The floor is polished obsidian, reflecting your distorted image. The air tastes of metal and centuries. At the far end, the passage splits. The tomb's geometry feels... uncertain.",
        shortDesc = "Vaulted corridor of black stone. Cold fire braziers.",
        exits = { South = 36, North = 38 },
        items = {},
        npcs = {},
        act = 3,
        tombLoop = true,
        ambience = {
            "^8Cold fire crackles without warmth.^7",
            "^8Your reflection moves a fraction too slowly.^7",
            "^8The obsidian floor hums beneath your boots.^7",
            "^8Whispers echo from deeper within the tomb.^7",
        },
        paranoidAmbience = {
            "^1Your reflection grins. You are not grinning.^7",
            "^1The braziers lean toward you as you pass.^7",
            "^1The corridor is longer than it was a moment ago.^7",
            "^1Someone walked here before you. Their footprints are yours.^7",
        },
        sounds = { enter = "sound/weapons/force/absorb.wav" },
    },

    [38] = {
        id = 38,
        name = "Sith Tomb - Hall of Wrath",
        description = "The walls are scarred with lightsaber burns — ancient duels etched into the stone. Broken statues of Sith warriors line alcoves, their faces twisted in permanent rage. A massive mural depicts a battle: red sabers against blue, bodies piled high. The anger preserved in this room is palpable. Your fists clench involuntarily.",
        shortDesc = "Lightsaber-scarred walls. Shattered Sith statues.",
        exits = { South = 37, North = 39 },
        items = {},
        npcs = {},
        encounter = 14,  -- Fragment: RAGE
        act = 3,
        tombLoop = true,
        ambience = {
            "^8Lightsaber burns still glow faintly in the stone.^7",
            "^8A statue's hand twitches. Stone grinding on stone.^7",
            "^8The mural's painted blood seems wet.^7",
            "^8Your jaw is clenched. When did that start?^7",
        },
        paranoidAmbience = {
            "^1The statues turn their heads to watch you pass.^7",
            "^1The mural changes. You are in it now. Losing.^7",
            "^1Your lightsaber hilt grows warm. It wants to ignite.^7",
            "^1The rage in the walls seeps into your bones.^7",
        },
        sounds = { enter = "sound/effects/glassbreak1.wav" },
    },

    [39] = {
        id = 39,
        name = "Sith Tomb - Chamber of Whispers",
        description = "An octagonal room with a vaulted ceiling lost in shadow. Alcoves line every wall, each containing a small pyramid — lesser holocrons, dead and dark. But they still whisper. Fragments of knowledge, half-truths, lies wrapped in wisdom. The floor is etched with concentric circles. Standing in the center makes the whispers louder.",
        shortDesc = "Octagonal chamber. Dead holocrons whisper from alcoves.",
        exits = { South = 38, North = 40 },
        items = {},
        npcs = {},
        encounter = 15,  -- Fragment: FEAR
        act = 3,
        tombLoop = true,
        ambience = {
            "^8Dead holocrons murmur in languages you almost know.^7",
            "^8The concentric circles on the floor pulse faintly.^7",
            "^8Shadows gather in the vaulted ceiling, watching.^7",
            "^8One whisper sounds like your mother's voice.^7",
        },
        paranoidAmbience = {
            "^1The whispers know your secrets. All of them.^7",
            "^1A dead holocron lights up as you pass. Just for you.^7",
            "^1The circles on the floor are a trap. You can feel it.^7",
            "^1The whispers are getting louder. They're not stopping.^7",
        },
        sounds = { enter = "sound/weapons/force/see.wav" },
    },

    [40] = {
        id = 40,
        name = "Sith Tomb - Pit of Silence",
        description = "The corridor opens into a vast natural cavern. A pit descends into absolute darkness — no bottom visible, no echo when you drop a stone. The silence here is oppressive, physical. It pushes against your eardrums. Narrow bridges of carved stone cross the void. The Sith built this place to break the weak. The silence is a weapon.",
        shortDesc = "Vast cavern. Bottomless pit. Crushing silence.",
        exits = { South = 39, North = 41 },
        items = {},
        npcs = {},
        encounter = 16,  -- Fragment: DESPAIR
        act = 3,
        tombLoop = true,
        ambience = {
            "^8The silence presses against your ears like hands.^7",
            "^8A stone falls into the pit. No sound returns.^7",
            "^8The bridge sways imperceptibly beneath your feet.^7",
            "^8Your breathing is the loudest thing in the universe.^7",
        },
        paranoidAmbience = {
            "^1Something moves in the pit. Something enormous.^7",
            "^1The bridge is narrower than it was. You're sure of it.^7",
            "^1The silence speaks. It says your name.^7",
            "^1If you fall, no one will ever know.^7",
        },
        sounds = { enter = "sound/weapons/force/drain.wav" },
    },

    [41] = {
        id = 41,
        name = "Sith Tomb - Ritual Antechamber",
        description = "A circular room with a single massive door to the north — the Inner Sanctum. The door is carved with a face: eyes closed, mouth open in a silent scream. Blood channels cut into the floor converge at the door's base. This was where the final rituals were performed. Where the unworthy were consumed. The door seems to breathe.",
        shortDesc = "Circular room. Screaming face carved on the sanctum door.",
        exits = { South = 40, North = 42 },
        items = {},
        npcs = { 21 },     -- Tomb Guardian Inscription
        act = 3,
        tombLoop = true,
        ambience = {
            "^8The carved face's expression shifts in the firelight.^7",
            "^8Blood channels in the floor are dry. Mostly.^7",
            "^8The massive door vibrates with a subsonic hum.^7",
            "^8You feel judged. Measured. Found wanting.^7",
        },
        paranoidAmbience = {
            "^1The carved face opens its eyes. They are yours.^7",
            "^1The blood channels are filling. From where?^7",
            "^1The door is judging you. It knows your sins.^7",
            "^1You have been here before. In another life.^7",
        },
        sounds = { enter = "sound/weapons/force/absorb.wav" },
    },

    [42] = {
        id = 42,
        name = "Sith Tomb - Inner Sanctum",
        description = "The heart of the tomb. A domed chamber of polished black marble, veined with crimson. A sarcophagus dominates the center — not of stone, but of crystallized dark side energy. The Holocron screams in your mind, a sound of recognition and terror. This is where its master was entombed. This is where the prison was forged. The air crackles with power older than the Republic.",
        shortDesc = "Domed sanctum. Crystallized dark side sarcophagus.",
        exits = { South = 41, North = 43 },
        items = {},
        npcs = { 20 },     -- The Shadow's Voice
        act = 3,  -- Shadow Self combat triggered from dialogue (shadow_voice.lua)
        ambience = {
            "^8The sarcophagus pulses with crimson energy.^7",
            "^8The Holocron resonates, vibrating in your pack.^7",
            "^8Dark side energy crackles along the marble veins.^7",
            "^8The air tastes of lightning and old blood.^7",
        },
        paranoidAmbience = {
            "^1The sarcophagus is opening. Slowly.^7",
            "^1The Holocron is screaming. Can't you hear it?^7",
            "^1Something in the sarcophagus is breathing.^7",
            "^1You are the key. You were always the key.^7",
        },
        sounds = { enter = "sound/weapons/force/drain.wav" },
    },

    -- ============================================
    -- ACT 4: THE VOID / FRAGMENTATION (Rooms 43-47)
    -- ============================================

    [43] = {
        id = 43,
        name = "The Threshold",
        description = "Beyond the sanctum, reality thins. The stone walls give way to... nothing. Not darkness — absence. You stand on a platform of crystallized Force energy, translucent and humming. The space around you is vast, featureless, and wrong. Colors that don't exist bleed at the edges of your vision. The Holocron has gone silent for the first time since the crash. That terrifies you more than the whispers ever did.",
        shortDesc = "Where reality ends. Crystallized Force platform.",
        exits = { South = 42, North = 44 },
        items = {},
        npcs = {},
        act = 4,
        locked = true,
        lockMessage = "The sanctum's shadow blocks your path. You must face what waits within before passing beyond.",
        horrorOnEntry = "glitch",
        ambience = {
            "^8Colors that shouldn't exist bleed at the edges.^7",
            "^8The platform hums beneath you like a living thing.^7",
            "^8The Holocron is silent. Completely silent.^7",
            "^8Your shadow doesn't match your movements.^7",
        },
        sounds = { enter = "sound/weapons/force/drain.wav" },
    },

    [44] = {
        id = 44,
        name = "Memory Corridor",
        description = "A hallway that shouldn't exist. The walls are made of frozen moments — your memories, crystallized and displayed like museum exhibits. Your first day on Dantooine. The crash site. Faces of people you've met. Some memories are wrong. Altered. A version of events where you made different choices. The floor shifts beneath you like sand.",
        shortDesc = "Hallway of frozen memories. Some are wrong.",
        exits = { South = 43, North = 45 },
        items = {},
        npcs = { 22 },     -- Echo of Karath Vren
        act = 4,
        ambience = {
            "^8A memory of Dantooine plays on the wall, slightly wrong.^7",
            "^8The floor shifts like sand beneath your boots.^7",
            "^8You see your own face in a frozen moment. Smiling.^7",
            "^8A memory you don't recognize plays on loop.^7",
        },
        sounds = { enter = "sound/weapons/force/see.wav" },
    },

    [45] = {
        id = 45,
        name = "The Hollow",
        description = "An empty space. Not a room — a wound in reality. The edges of the space flicker and glitch, fragments of other places bleeding through. For a moment you see the Khoonda cantina. Then the crash site. Then somewhere you've never been — a throne room draped in red. The Hollow pulses like a heartbeat. Something fundamental is breaking down.",
        shortDesc = "A wound in reality. Other places bleed through.",
        exits = { South = 44, North = 46 },
        items = {},
        npcs = {},
        act = 4,
        horrorOnEntry = "reboot",
        ambience = {
            "^8Reality flickers. Khoonda's cantina bleeds through.^7",
            "^8The edges of the space glitch and reform.^7",
            "^8A throne room draped in red appears, then vanishes.^7",
            "^8The Hollow pulses like a heartbeat.^7",
        },
        sounds = { enter = "sound/effects/glassbreak1.wav" },
    },

    [46] = {
        id = 46,
        name = "Fragment Arena",
        description = "A circular platform suspended in the void. The crystallized floor is cracked, energy leaking from the fractures. This place was built for confrontation. You can feel it — the architecture of a trial, a crucible. The fragments of yourself that were torn away in the tomb are here. Waiting. They have taken form. They have taken power.",
        shortDesc = "Circular platform in the void. A crucible.",
        exits = { South = 45, North = 47 },
        items = {},
        npcs = { 23 },     -- The Watcher (visible only at paranoia >= 80)
        act = 4,
        ambience = {
            "^8Energy leaks from fractures in the crystallized floor.^7",
            "^8The void around the platform churns silently.^7",
            "^8Fragments of your essence orbit the arena.^7",
            "^8This place was built for one purpose: confrontation.^7",
        },
        sounds = { enter = "sound/weapons/force/absorb.wav" },
    },

    [47] = {
        id = 47,
        name = "The Awakening",
        description = "The void recedes. The platform widens into solid ground. Ahead, a passage of clean white stone leads upward — the first real structure you've seen since the tomb. Light filters from above, warm and steady. The Holocron stirs again, but different now. Quieter. Resigned. Whatever you faced in the void, you survived. The way forward is clear.",
        shortDesc = "Solid ground returns. Clean white passage ahead.",
        exits = { South = 46, North = 48 },
        items = {},
        npcs = {},
        act = 4,
        ambience = {
            "^8Warm light filters from above.^7",
            "^8The ground beneath you is solid. Real.^7",
            "^8The Holocron stirs, quieter than before.^7",
            "^8The void recedes behind you like a bad dream.^7",
        },
        sounds = { enter = "sound/weapons/force/heal.wav" },
    },

    -- ============================================
    -- ACT 5: ENDGAME (Rooms 48-54)
    -- ============================================

    [48] = {
        id = 48,
        name = "The Hidden Entrance",
        description = "A narrow passage carved into living rock. Ancient Sith glyphs line the walls, pulsing faintly with residual dark energy. The air is cold and still. Ahead, the passage opens into a vast chamber. Behind you, the way back to the surface. This place has been sealed for millennia -- until now.",
        shortDesc = "A hidden passage to the cipher chamber.",
        exits = { South = 47, North = 49 },
        items = {},
        npcs = { 24 },     -- Saevus Manifestation
        act = 5,
        locked = true,
        lockMessage = "An invisible ward blocks the passage. The symbols pulse red. You are not yet ready for what lies beyond.",
        ambience = {
            "^8Sith glyphs pulse in the dark.^7",
            "^8The air tastes of dust and centuries.^7",
            "^8Your footsteps echo impossibly far.^7",
            "^8The Holocron trembles against your ribs.^7",
        },
        paranoidAmbience = {
            "^1The glyphs spell your name. They always have.^7",
            "^1The passage contracts. The walls are breathing.^7",
            "^1Someone walked this path before you. Recently.^7",
            "^1The Holocron whispers: 'Welcome home.'^7",
        },
        sounds = { enter = "sound/weapons/force/drain.wav" },
    },

    [49] = {
        id = 49,
        name = "The Cipher Chamber",
        description = "A circular chamber of black stone. Nine columns surround a central console, each carved with a single numeral position. The console awaits input -- nine digits that form the key to the Holocron's prison. The cipher is scattered across artifacts you've found on your journey. Enter the code to seal the prison... or leave it open.",
        shortDesc = "The ancient cipher input chamber.",
        exits = { South = 48, North = 50 },
        items = {},
        npcs = {},
        act = 5,
        ambience = {
            "^8The nine columns hum with contained energy.^7",
            "^8The console's display flickers, awaiting input.^7",
            "^8The air crackles with static charge.^7",
            "^8Ancient mechanisms click deep within the walls.^7",
        },
        paranoidAmbience = {
            "^1The columns lean inward. Watching.^7",
            "^1The console displays numbers you didn't enter.^7",
            "^1The Holocron's whispers are deafening here.^7",
            "^1You've been here before. In a dream. In a memory.^7",
        },
        sounds = { enter = "sound/weapons/force/absorb.wav" },
    },

    [50] = {
        id = 50,
        name = "Chamber of Final Choice",
        description = "A vast domed chamber. Four passages lead away from the central platform, each sealed by a different kind of energy. The Light shimmers to the north. Darkness coils to the east. Madness pulses to the west. And above, if you've solved the cipher, the Truth awaits. Choose your ending.",
        shortDesc = "The four-way hub. Choose your ending.",
        exits = { South = 49 },  -- Dynamic exits calculated at runtime
        items = {},
        npcs = {},
        act = 5,
        ambience = {
            "^8Four energies war for dominance in the dome.^7",
            "^8The platform beneath you thrums with power.^7",
            "^8Each passage calls to a different part of you.^7",
            "^8The moment of choice is here.^7",
        },
        paranoidAmbience = {
            "^1All four passages lead to the same place.^7",
            "^1The choice was made long ago. You just don't know it yet.^7",
            "^1The dome shows reflections of futures you haven't chosen.^7",
            "^1The Holocron laughs. A sound like breaking glass.^7",
        },
        sounds = { enter = "sound/weapons/force/see.wav" },
    },

    [51] = {
        id = 51,
        name = "The Light",
        description = "Blinding white. The passage opens into pure radiance. The Holocron burns in your hands. This is where sacrifice lives -- where you trade everything for the galaxy's salvation. There is no going back.",
        shortDesc = "The path of sacrifice.",
        exits = {},
        items = {},
        npcs = {},
        act = 5,
    },

    [52] = {
        id = 52,
        name = "The Dark",
        description = "Shadow made solid. The passage descends into absolute darkness. The Holocron sings with joy. This is where ambition lives -- where you take the power that was always meant to be yours. There is no going back.",
        shortDesc = "The path of dominion.",
        exits = {},
        items = {},
        npcs = {},
        act = 5,
    },

    [53] = {
        id = 53,
        name = "The Shattered Mind",
        description = "The passage fractures into impossible geometry. Walls become floors. Up becomes down. The paranoia that has been building since the crash site finally wins. This is where sanity breaks. There is no going back.",
        shortDesc = "The path of madness.",
        exits = {},
        items = {},
        npcs = {},
        act = 5,
    },

    [54] = {
        id = 54,
        name = "The Truth",
        description = "A simple room. Clean stone. Clear air. No whispers. For the first time, the Holocron is silent. The cipher key glows on the console before you. One word, one name, one truth -- and the prison seals forever. This is where freedom lives.",
        shortDesc = "The path of truth.",
        exits = {},
        items = {},
        npcs = {},
        act = 5,
    },
}

return RPG.Data.Rooms
