-- Echoes of the Dark Wars - Configuration
-- Constants and tuning values

RPG = RPG or {}
RPG.Config = {}

-- Version
RPG.Config.VERSION = "0.1.0"
RPG.Config.NAME = "Echoes of the Dark Wars"

-- XP
RPG.Config.XP_PER_LEVEL = 1000          -- xpToNext = level * XP_PER_LEVEL
RPG.Config.MAX_LEVEL = 20

-- Currency
RPG.Config.STARTING_CREDITS = 100

-- Stats
RPG.Config.STAT_BASE = 10               -- D&D modifier baseline
RPG.Config.STAT_POINT_LEVELS = { [6] = true, [12] = true, [18] = true }
RPG.Config.CON_ALLOC_HP_BONUS = 5       -- immediate max HP bonus when allocating CON
RPG.Config.ALIGNMENT_MIN = -100         -- Full dark side
RPG.Config.ALIGNMENT_MAX = 100          -- Full light side
RPG.Config.PARANOIA_MIN = 0
RPG.Config.PARANOIA_MAX = 100

-- Inventory
RPG.Config.MAX_INVENTORY = 50

-- Combat
RPG.Config.FLEE_CHANCE = 40             -- Base % to flee
RPG.Config.CRIT_CHANCE = 10             -- Base % to crit
RPG.Config.CRIT_MULTIPLIER = 1.5
RPG.Config.BASE_HIT_CHANCE = 80         -- Base % chance to hit
RPG.Config.HIT_DEX_BONUS = 3            -- +% hit per DEX modifier
RPG.Config.CRIT_DEX_BONUS = 2           -- +% crit per DEX modifier
RPG.Config.DEFEND_MULTIPLIER = 0.5      -- Damage multiplier while defending
RPG.Config.FLEE_DEX_BONUS = 5           -- +% flee per DEX modifier
RPG.Config.INTENT_WIS_THRESHOLD = 12    -- WIS required for clear enemy intent
RPG.Config.INTENT_ACCURACY = 70         -- % chance enemy follows hinted intent
RPG.Config.COUNTER_RIPOSTE_DAMAGE = 5         -- flat riposte on defend-counter
RPG.Config.COUNTER_DEFEND_HEAL_PERCENT = 0.25  -- heal 25% of damage taken on defend-counter
RPG.Config.COUNTER_ATTACK_VS_SPECIAL = 0.3    -- +30% player damage as bonus hit
RPG.Config.COUNTER_ATTACK_VS_DEFEND = 0.2     -- +20% player damage as bonus hit
RPG.Config.DEATH_CREDIT_PENALTY = 0.5         -- lose 50% credits on respawn
RPG.Config.AI_BEHAVIORS = {
    aggressive = { attack = 70, special = 20, defend = 10 },
    defensive  = { attack = 40, special = 20, defend = 40 },
    balanced   = { attack = 50, special = 25, defend = 25 },
}

-- Companion System
RPG.Config.COMPANION_COMMENT_COOLDOWN = 15000      -- ms between room commentary
RPG.Config.COMPANION_COMMENT_CHANCE = 60            -- % chance to comment on room enter
RPG.Config.COMPANION_QUIP_CHANCE = 30               -- % chance for combat quip (unused, quips always fire)
RPG.Config.COMPANION_PARANOIA_CALM_COOLDOWN = 60000 -- ms between calming lines

-- Whispering Crowd (Act 2 atmosphere)
RPG.Config.CROWD_WHISPER_ENABLED = true
RPG.Config.CROWD_WHISPER_INTERVAL = 40000   -- ms between checks (40s)
RPG.Config.CROWD_WHISPER_CHANCE = 20         -- % chance per check

-- Display
RPG.Config.HEALTH_BAR_WIDTH = 20        -- Characters wide
RPG.Config.MAX_MENU_LINES = 18          -- Centerprint vertical limit (Y=144px, 16px/line)
RPG.Config.HEALTH_BAR_COMPACT = 10      -- Compact bar width for combined HP+FP lines
RPG.Config.TEXT_WRAP_WIDTH = 60          -- Max chars per line
RPG.Config.NARRATE_COLOR = "^7"         -- Default narrative color
RPG.Config.ROOM_NAME_COLOR = "^2"       -- Green for room names
RPG.Config.NPC_NAME_COLOR = "^3"        -- Yellow for NPC names
RPG.Config.ITEM_COLOR = "^5"            -- Cyan for items
RPG.Config.COMBAT_COLOR = "^1"          -- Red for combat
RPG.Config.SYSTEM_COLOR = "^3"          -- Yellow for system messages
RPG.Config.DARK_COLOR = "^1"            -- Red for dark side
RPG.Config.LIGHT_COLOR = "^5"           -- Cyan for light side

-- Horror thresholds
RPG.Config.PARANOIA_WHISPER_MIN = 30    -- Start hearing whispers
RPG.Config.PARANOIA_SCRAMBLE_LOW = 70   -- 10% text scramble
RPG.Config.PARANOIA_SCRAMBLE_MED = 85   -- 30% text scramble
RPG.Config.PARANOIA_SCRAMBLE_HIGH = 95  -- 60% text scramble
RPG.Config.PARANOIA_PULSE_THRESHOLD = 40 -- Start color pulsing

-- Atmosphere
RPG.Config.AMBIENCE_TEXT_ENABLED = true   -- Show ambient flavor text in collapsed header
RPG.Config.ROOM_SOUNDS_ENABLED = true     -- Play sounds on room entry
RPG.Config.DEBUG_SOUNDS = false           -- Log sound play attempts

-- Whisper system (Saevus voice)
RPG.Config.WHISPER_ENABLED = true        -- Master toggle for event whispers
RPG.Config.WHISPER_COOLDOWN_MS = 30000   -- 30s between whispers
RPG.Config.WHISPER_DEBUG = false          -- Log whisper attempts

-- Debug
RPG.Config.DEBUG_STATE_TRANSITIONS = false  -- Enable for CP contention diagnosis
RPG.Config.DEBUG_PAYLOAD_SIZE = false         -- TEMP: log reliable data > threshold
RPG.Config.DEBUG_PAYLOAD_THRESHOLD = 300     -- Only log payloads above this byte count
RPG.Config.DEBUG_MENU_TIMING = false          -- Log Menu.Render/SwapMenu/Navigate timing
RPG.Config.DEBUG_NAV_TRACE = false             -- Every Navigate: selection delta, render outcome, output changed?
RPG.Config.DEBUG_CP_SENDS = false              -- CP send rate: sends/sec, bytes/sec per player
RPG.Config.DEBUG_RENDER_BREAKDOWN = false      -- Dialogue header/items timing breakdown

-- State -> Menu ID mapping
RPG.Config.STATE_MENUS = {
    intro           = "rpg_intro",
    dream           = "rpg_dream",
    class_select    = "rpg_class_select",
    exploration     = "rpg_exploration",
    combat          = "rpg_combat",
    dialogue        = "rpg_dialogue",
    inventory       = "rpg_inventory",
    character_sheet = "rpg_character",
    quest_log       = "rpg_quests",
    shop            = "rpg_shop",
    game_over       = "rpg_game_over",
    victory         = "rpg_victory",
    datapad_decrypt = "rpg_datapad_decrypt",
    force_vision    = "rpg_force_vision",
    cipher_input    = "rpg_cipher_input",
    ending          = "rpg_ending",
    glitch_burst    = "rpg_glitch_burst",
    combat_result   = "rpg_combat_result",
    stat_allocation = "rpg_stat_allocation",
    boot            = "rpg_boot",
    confirm         = "rpg_confirm",
}

-- ============================================
-- AUTOSAVE (Phase 0 — save/load infrastructure)
-- ============================================
RPG.Config.AUTOSAVE_INTERVAL_MS = 90000        -- Periodic autosave cadence (90s)
RPG.Config.AUTOSAVE_COOLDOWN_MS = 10000        -- Min ms between any saves (chain-fire defuse)
RPG.Config.AUTOSAVE_LOG_TO_PLAYER = false      -- If true, print "[Game saved]" on each autosave

-- Direction ordering for deterministic exit display
RPG.Config.DIRECTION_ORDER = {
    "North", "Northeast", "East", "Southeast",
    "South", "Southwest", "West", "Northwest",
    "Up", "Down",
}

-- Special items
RPG.Config.HOLOCRON_ITEM_ID = 2         -- Sith Holocron
RPG.Config.TRAINING_SABER_ID = 0
RPG.Config.MEDPAC_ID = 3
RPG.Config.SHADOW_DATAPAD_ID = 7        -- Jedi Shadow's Datapad

-- Dialogue display
RPG.Config.DIALOGUE_MAX_TEXT_LINES = 5  -- Max NPC text lines per page
RPG.Config.DIALOGUE_MAX_RESPONSES = 4  -- Max visible responses at once
RPG.Config.DIALOGUE_WRAP_WIDTH = 46    -- was 58. Accounts for ^7 prefix (2) + color codes (~2)
RPG.Config.LINE_CLAMP_WIDTH = 56       -- max visible chars before truncation
RPG.Config.COMBAT_WRAP_WIDTH = 44      -- word-wrap width for combat header text
RPG.Config.DIALOGUE_SPEAKER_COLOR = "^3"
RPG.Config.DIALOGUE_TEXT_COLOR = "^7"
RPG.Config.DIALOGUE_RESPONSE_COLOR = "^7"
RPG.Config.DIALOGUE_CHECK_SUCCESS = "^2"
RPG.Config.DIALOGUE_CHECK_FAIL = "^1"

-- Stat check display labels
RPG.Config.STAT_CHECK_LABELS = {
    STR = "Might",
    DEX = "Reflex",
    CON = "Fortitude",
    WIS = "Awareness",
    INT = "Logic",
    CHA = "Persuade",
}

-- Doubt system
RPG.Config.DOUBT_WIS_THRESHOLD = 14    -- WIS needed to see through Doubt
RPG.Config.DOUBT_PARANOIA_MIN = 20     -- Min paranoia for Doubt options
RPG.Config.DOUBT_FAKEOUT_PARANOIA = 70 -- Paranoia for skill-check fakeouts
RPG.Config.SAEVUS_WHISPER_PARANOIA = 30 -- Min paranoia for Saevus interjections
RPG.Config.SAEVUS_NPC_ID = 99          -- Virtual NPC ID for Saevus Holocron entity

-- Exploration paranoia effects
RPG.Config.PARANOIA_FAKE_NPC = 95      -- Fake "???" NPC appears
RPG.Config.PARANOIA_EXIT_CORRUPT = 85  -- Exit names occasionally wrong

-- ============================================
-- DARK POWER BACKFIRE SYSTEM
-- ============================================
RPG.Config.BACKFIRE_TIERS = {
    { min = 0,  max = 29, chance = 0,  effect = "none" },
    { min = 30, max = 69, chance = 5,  effect = "partial" },   -- 75% damage + whisper
    { min = 70, max = 84, chance = 15, effect = "strain" },    -- 50% damage + 5 self-damage
    { min = 85, max = 94, chance = 25, effect = "surge" },     -- 50% damage + 8 self-damage
    { min = 95, max = 100,chance = 40, effect = "seize" },     -- full damage + 10 self-damage + alignment -1
}
RPG.Config.BACKFIRE_FIRST_FREE = true   -- first dark power use per combat always succeeds
RPG.Config.DARK_ALIGNMENT_CAP_PER_COMBAT = -4  -- max alignment loss from dark powers per fight

-- ============================================
-- STALKER ENCOUNTER TUNING
-- ============================================
RPG.Config.STALKER_PARANOIA_COST = 10          -- paranoia gained on survival
RPG.Config.STALKER_DAMAGE_BASE = 12            -- base damage before level scaling
RPG.Config.STALKER_DAMAGE_SCALE = 1.2          -- per-level damage multiplier
RPG.Config.STALKER_DAMAGE_MIN_FLOOR = 14       -- absolute minimum damage
RPG.Config.STALKER_DAMAGE_MAX_CEIL = 34        -- absolute maximum damage

RPG.Config.STALKER_HIT_NARRATION = {
    "^8Your blade passes through smoke. The wound knits closed instantly.",
    "^8The Stalker absorbs the impact without flinching. Its form ripples and reforms.",
    "^8You cut deep — but shadow pours from the wound like blood, and it seals.",
    "^8For a moment it staggers. Then it laughs. The damage means nothing.",
    "^8The lightsaber sinks in. The Stalker looks down, amused. The gash vanishes.",
}

RPG.Config.STALKER_ROUND_TEXT = {
    [1] = "^8The Stalker tests your guard, circling slowly.",
    [2] = "^8It presses harder. Each swing forces you back a step.",
    [3] = "^1The air turns freezing. Your lungs burn. The Stalker's eyes flare bright.",
    [4] = "^1It changes tactics — reaching for your mind, not your body.",
    [5] = "^1The world fades to grey. You can't hear anything but your own heartbeat. Hold on...",
}

-- ============================================
-- CIPHER SYSTEM (Act 5)
-- ============================================
RPG.Config.CIPHER_CODE = "492173949"
RPG.Config.CIPHER_LENGTH = 9
RPG.Config.CIPHER_FAIL_PARANOIA = 3
RPG.Config.CIPHER_ROOM = 49

-- ============================================
-- ENDING THRESHOLDS
-- ============================================
RPG.Config.ENDING_LIGHT_ALIGNMENT = 50
RPG.Config.ENDING_DARK_ALIGNMENT = -50
RPG.Config.ENDING_HORROR_PARANOIA = 100

-- Phase 1 (#1): Truth-ending Force Sever bargain — Trigger clamps paranoia to >= this floor.
RPG.Config.PARANOIA_FLOOR_TRUTH = 30

-- ============================================
-- ACT 3: DXUN SITH TOMB
-- ============================================
RPG.Config.TOMB_LOOP_START = 37
RPG.Config.TOMB_LOOP_END = 41
RPG.Config.TOMB_SANCTUM = 42
RPG.Config.TOMB_WIS_DC = 14
RPG.Config.TOMB_STR_DC = 16
RPG.Config.TOMB_STR_HP_COST = 30
RPG.Config.TOMB_STR_PARANOIA_COST = 15
RPG.Config.TOMB_MAX_LOOPS = 5

-- Post-combat room 42 description (flag-based, survives save/load)
RPG.Config.ROOM42_POST_SHADOW = "The sanctum is still. The sarcophagus no longer pulses with dark energy. Where the Shadow once stood, only silence remains — and the faintest sense that something inside you has been... resolved."

RPG.Config.FRAGMENT_RAGE_ID = 14
RPG.Config.FRAGMENT_FEAR_ID = 15
RPG.Config.FRAGMENT_DESPAIR_ID = 16
RPG.Config.SHADOW_SELF_ID = 17
RPG.Config.FRAGMENT_STAT_DRAIN = 1

RPG.Config.MIMIC_MIRROR_CHANCE = 80

-- ============================================
-- ACT 4: THE VOID / FRAGMENTATION
-- ============================================
RPG.Config.GLITCH_BURST_FRAME_MIN = 200
RPG.Config.GLITCH_BURST_FRAME_MAX = 500
RPG.Config.GLITCH_BURST_TOTAL_MIN = 5000
RPG.Config.GLITCH_BURST_TOTAL_MAX = 10000
RPG.Config.GLITCH_PARANOIA_THRESHOLD = 85
RPG.Config.FAKE_REBOOT_DURATION = 8000
RPG.Config.FOURTH_WALL_PARANOIA = 90
RPG.Config.FOURTH_WALL_PARANOIA_GAIN = 10
RPG.Config.GLIMPSE_PARANOIA_MIN = 70

-- ============================================
-- NEMESIS SYSTEM (Phase 3: The Hunter & The Hunted)
-- ============================================
RPG.Config.NEMESIS_QUEST_THRESHOLD = 2       -- side quests completed before Enc 1
RPG.Config.NEMESIS_ACT2_MOVES = 3            -- room moves in Act 2 before Enc 2
RPG.Config.NEMESIS_ENC1_ROOM = 2             -- Khoonda Plaza
RPG.Config.NEMESIS_ENC2_ROOM = 30            -- Hab Block 7
RPG.Config.NEMESIS_ENC3_ROOM = 43            -- The Threshold
RPG.Config.NEMESIS_DEFEAT_CREDIT_PENALTY = 0.5   -- lose 50% credits on Enc 1 defeat
RPG.Config.NEMESIS_TRACE_SOUND_COOLDOWN = 10000  -- ms between trace audio cues
-- Quest item theft protection now checked via RPG.Data.Items[id].type == "quest" at runtime
RPG.Config.NEMESIS_ORIGIN_SOUNDS = {
    exchange    = "sound/movers/switches/button_09.wav",
    republic    = "sound/electronics/ping.wav",
    mandalorian = "sound/weapons/detpack/arm.wav",
}

RPG.Config.BACKFIRE_WHISPERS = {
    "Your master would be ashamed of such clumsy hands...",
    "The power was never yours. You merely borrow it.",
    "Feel that? That's what control tastes like. You have none.",
    "Struggling with my gift? Perhaps you weren't ready.",
}

-- ============================================
-- FORCE ECHO LOCATIONS
-- ============================================
RPG.Config.FORCE_ECHOES = {
    force_heal = {
        room = 8,   -- Deep Crystal Caves
        text = "^8The crystals hum. A memory surfaces\n^8-- warmth spreading through wounds,\n^8flesh knitting closed.\n^2You remember how.^7",
    },
    force_speed = {
        room = 15,  -- Jedi Enclave Sublevel Archives
        text = "^8A blur of robes. A Padawan runs\n^8through these halls, laughing.\n^8The speed was effortless.\n^2You feel your legs remember.^7",
    },
}

return RPG.Config
