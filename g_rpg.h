/*
===========================================================================
ECHOES OF THE DARK WARS - Star Wars Text Adventure RPG
3949 BBY - The Dark Wars Era

A narrative-driven text adventure using the CP message system.
Set 5 years after Revan's departure, 2 years after KOTOR 2.

Copyright (C) 2025
===========================================================================
*/

#ifndef __G_RPG_H__
#define __G_RPG_H__

// Forward declarations
typedef struct rpgGame_s rpgGame_t;
typedef struct rpgPlayer_s rpgPlayer_t;
typedef struct rpgRoom_s rpgRoom_t;
typedef struct rpgNPC_s rpgNPC_t;
typedef struct rpgItem_s rpgItem_t;
typedef struct rpgQuest_s rpgQuest_t;
typedef struct rpgCombat_s rpgCombat_t;
typedef struct rpgDialogue_s rpgDialogue_t;
typedef struct rpgEnemy_s rpgEnemy_t;

// =============================================================================
// CONSTANTS
// =============================================================================

#define MAX_RPG_ROOMS 250
#define MAX_RPG_NPCS 200
#define MAX_RPG_ITEMS 100
#define MAX_RPG_QUESTS 150
#define MAX_RPG_ENEMIES 50
#define MAX_RPG_COMPANIONS 15

#define MAX_RPG_NAME 64
#define MAX_INVENTORY_SIZE 50
#define MAX_EQUIPPED_ITEMS 10
#define MAX_DIALOGUE_OPTIONS 6
#define MAX_ROOM_EXITS 6
#define MAX_ROOM_ITEMS 10
#define MAX_ROOM_NPCS 5

#define MAX_QUEST_OBJECTIVES 5
#define MAX_ACTIVE_QUESTS 20

#define RPG_REFRESH_INTERVAL 200  // ms

// Paranoia/Horror mechanics
#define PARANOIA_THRESHOLD_LOW 10
#define PARANOIA_THRESHOLD_MED 30
#define PARANOIA_THRESHOLD_HIGH 50
#define PARANOIA_THRESHOLD_EXTREME 70
#define PARANOIA_DECAY_INTERVAL 30000  // 30 seconds
#define ENEMY_ID_HALLUCINATION 99  // Special enemy ID for paranoia-induced hallucinations

// Text limits for CP messages
#define RPG_MAX_DISPLAY 800  // Safe limit for SendServerCommand with overhead
#define RPG_MAX_DESC 600
#define RPG_MAX_NAME 64
#define RPG_MAX_SHORT_DESC 200

// =============================================================================
// ENUMERATIONS
// =============================================================================

// Game states
typedef enum {
	RPG_STATE_INACTIVE = 0,
	RPG_STATE_INTRO,
	RPG_STATE_DREAM,  // NEW - Force visions and nightmares
	RPG_STATE_CHARACTER_CREATION,
	RPG_STATE_CLASS_SELECTION,
	RPG_STATE_EXPLORATION,
	RPG_STATE_COMBAT,
	RPG_STATE_DIALOGUE,
	RPG_STATE_INVENTORY,
	RPG_STATE_CHARACTER_SHEET,
	RPG_STATE_QUEST_LOG,
	RPG_STATE_SHOP,
	RPG_STATE_FROZEN,  // Act 3 - Fake reboot freeze
	RPG_STATE_CIPHER_INPUT,  // Act 5 - Truth ending code entry
	RPG_STATE_GLITCH_BURST,  // Act 4 - Psychotic break (Fragment psychic attack)
	RPG_STATE_GAME_OVER,
	RPG_STATE_VICTORY
} rpgState_t;

// Character classes
typedef enum {
	RPG_CLASS_NONE = 0,
	RPG_CLASS_JEDI_GUARDIAN,
	RPG_CLASS_JEDI_CONSULAR,
	RPG_CLASS_JEDI_SENTINEL,
	RPG_CLASS_SCOUNDREL,
	RPG_CLASS_SOLDIER,
	RPG_CLASS_BOUNTY_HUNTER,
	RPG_CLASS_MAX
} rpgClass_t;

// Stats
typedef enum {
	STAT_STRENGTH = 0,
	STAT_DEXTERITY,
	STAT_CONSTITUTION,
	STAT_WISDOM,
	STAT_INTELLIGENCE,
	STAT_CHARISMA,
	STAT_MAX
} rpgStat_t;

// Item types
typedef enum {
	ITEM_WEAPON = 0,
	ITEM_ARMOR,
	ITEM_CONSUMABLE,
	ITEM_QUEST,
	ITEM_LIGHTSABER,
	ITEM_CRYSTAL,
	ITEM_MISC
} rpgItemType_t;

// Equipment slots
typedef enum {
	SLOT_WEAPON = 0,
	SLOT_ARMOR,
	SLOT_IMPLANT,
	SLOT_GLOVES,
	SLOT_BELT,
	SLOT_MAX
} rpgEquipSlot_t;

// Alignment
typedef enum {
	ALIGNMENT_LIGHT = 1,
	ALIGNMENT_NEUTRAL = 0,
	ALIGNMENT_DARK = -1
} rpgAlignment_t;

// Quest states
typedef enum {
	QUEST_INACTIVE = 0,
	QUEST_ACTIVE,
	QUEST_COMPLETED,
	QUEST_FAILED
} rpgQuestState_t;

// Dialogue choice types
typedef enum {
	DIALOGUE_NORMAL = 0,
	DIALOGUE_LIGHT,
	DIALOGUE_DARK,
	DIALOGUE_PERSUADE,
	DIALOGUE_THREATEN,
	DIALOGUE_BRIBE
} rpgDialogueType_t;

// Combat actions
typedef enum {
	COMBAT_ATTACK = 0,
	COMBAT_FORCE_POWER,
	COMBAT_SPECIAL,
	COMBAT_DEFEND,
	COMBAT_USE_ITEM,
	COMBAT_FLEE
} rpgCombatAction_t;

// Force powers
typedef enum {
	FORCE_PUSH = 0,
	FORCE_HEAL,
	FORCE_LIGHTNING,
	FORCE_VALOR,
	FORCE_STUN,
	FORCE_DRAIN,
	FORCE_PROTECTION,
	FORCE_THROW,
	FORCE_MAX
} rpgForcePower_t;

// Factions
typedef enum {
	FACTION_REPUBLIC = 0,
	FACTION_EXCHANGE,
	FACTION_SITH,
	FACTION_JEDI,
	FACTION_MANDALORIAN,
	FACTION_NEUTRAL,
	FACTION_MAX
} rpgFaction_t;

// NPC attitudes
typedef enum {
	ATTITUDE_FRIENDLY = 0,
	ATTITUDE_NEUTRAL,
	ATTITUDE_HOSTILE,
	ATTITUDE_AFRAID
} rpgAttitude_t;

// =============================================================================
// DATA STRUCTURES
// =============================================================================

// Player character
struct rpgPlayer_s {
	char name[MAX_RPG_NAME];
	rpgClass_t class;
	int level;
	int xp;
	int xpToNext;

	// Stats
	int stats[STAT_MAX];
	int hp;
	int maxHP;
	int fp;  // Force Points
	int maxFP;

	// Alignment (-100 dark to +100 light)
	int alignment;

	// Paranoia/Horror mechanics
	int paranoiaLevel;  // 0-100, increases with Dark Side acts, Holocron use, witnessing horror
	qboolean hasHolocron;  // Currently possessing the Sith Holocron
	int lastParanoiaDecay;  // Time of last paranoia reduction

	// Act 2: The Stalker System
	int stalkerStage;  // 0=Hidden, 1=Watching, 2=Hunting, 3=Combat
	int stalkerTimer;  // Countdown to next stage (seconds)
	int stalkerCheckTime;  // Next tick time

	// Currency
	int credits;

	// Inventory
	int inventoryCount;
	int inventory[MAX_INVENTORY_SIZE];  // Item IDs
	int equipped[SLOT_MAX];  // Equipped item IDs

	// Location
	int currentRoom;

	// Progression
	int activeQuests[MAX_ACTIVE_QUESTS];
	int questFlags[MAX_RPG_QUESTS];  // Bitflags for quest states
	int storyFlags[256];  // Story progression flags

	// Faction reputation (0-100)
	int reputation[FACTION_MAX];

	// Companions
	int companionIDs[MAX_RPG_COMPANIONS];
	int companionCount;
	int activeCompanion;  // -1 if none
};

// Room/Location
struct rpgRoom_s {
	int id;
	char name[MAX_RPG_NAME];
	char description[RPG_MAX_DESC];
	char shortDesc[RPG_MAX_SHORT_DESC];

	// Exits (room IDs, -1 = none)
	int exits[MAX_ROOM_EXITS];  // N, E, S, W, U, D
	char exitNames[MAX_ROOM_EXITS][32];

	// Contents
	int npcIDs[MAX_ROOM_NPCS];
	int npcCount;
	int itemIDs[MAX_ROOM_ITEMS];
	int itemCount;

	// Flags
	qboolean visited;
	qboolean requiresKey;
	int requiredItem;  // Item ID needed to enter
	int requiredQuest;  // Quest ID that must be active
};

// NPC
struct rpgNPC_s {
	int id;
	char name[MAX_RPG_NAME];
	char description[RPG_MAX_SHORT_DESC];

	rpgAttitude_t attitude;
	rpgFaction_t faction;

	// Dialogue
	int dialogueTreeID;
	int currentDialogueNode;

	// Combat stats (if hostile)
	qboolean canFight;
	int hp;
	int maxHP;
	int damage;
	int defense;

	// Vendor
	qboolean isVendor;
	int vendorInventory[20];
	int vendorCount;

	// Quest giver
	int questID;  // -1 if not quest giver

	// Flags
	qboolean alive;
	qboolean talkedTo;

	// Act 2: Witness system (NPCs who claim player did crimes)
	qboolean isWitness;
};

// Item
struct rpgItem_s {
	int id;
	char name[MAX_RPG_NAME];
	char description[RPG_MAX_SHORT_DESC];
	char lore[512];  // NEW - Environmental storytelling, shown on Examine

	rpgItemType_t type;
	rpgEquipSlot_t slot;  // If equippable

	// Stats
	int damage;  // Weapons
	int defense;  // Armor
	int healing;  // Consumables
	int fpRestore;  // FP restoration

	// Modifiers
	int statBonus[STAT_MAX];

	// Properties
	int value;  // Credit value
	int weight;
	qboolean questItem;
	qboolean unique;
	qboolean consumable;
	qboolean isDarkSideItem;  // NEW - Examining increases paranoia
};

// Quest
struct rpgQuest_s {
	int id;
	char name[MAX_RPG_NAME];
	char description[RPG_MAX_SHORT_DESC];

	rpgQuestState_t state;

	// Objectives
	char objectives[MAX_QUEST_OBJECTIVES][128];
	qboolean objectiveComplete[MAX_QUEST_OBJECTIVES];
	int objectiveCount;

	// Rewards
	int xpReward;
	int creditReward;
	int itemReward;  // Item ID
	int alignmentChange;  // +/- alignment

	// Requirements
	int requiredLevel;
	int requiredQuest;  // Must complete this quest first

	// Flags
	qboolean isMainQuest;
};

// Combat state
struct rpgCombat_s {
	qboolean active;

	// Enemy
	int enemyID;
	char enemyName[MAX_RPG_NAME];
	int enemyHP;
	int enemyMaxHP;
	int enemyDamage;
	int enemyDefense;

	// Combat flow
	qboolean playerTurn;
	int turnCount;

	// Selection
	int selectedAction;
	int selectedPower;
	int selectedItem;

	// Status
	qboolean playerDefending;
	qboolean enemyStunned;

	// Result message
	char lastActionResult[256];
	int messageDisplayTime;
};

// Dialogue state
struct rpgDialogue_s {
	qboolean active;

	int npcID;
	int currentNode;

	// Current dialogue
	char npcText[RPG_MAX_DESC];

	// Choices
	int choiceCount;
	char choiceText[MAX_DIALOGUE_OPTIONS][128];
	rpgDialogueType_t choiceType[MAX_DIALOGUE_OPTIONS];
	int choiceNextNode[MAX_DIALOGUE_OPTIONS];
	int choiceRequiredStat[MAX_DIALOGUE_OPTIONS];  // Stat check (e.g., WIS 16)
	int choiceRequiredValue[MAX_DIALOGUE_OPTIONS];
	int choiceAlignmentChange[MAX_DIALOGUE_OPTIONS];

	// Selection
	int selectedChoice;
};

// Enemy template
struct rpgEnemy_s {
	int id;
	char name[MAX_RPG_NAME];
	char description[RPG_MAX_SHORT_DESC];

	int level;
	int hp;
	int damage;
	int defense;

	int xpReward;
	int creditReward;

	// Loot table
	int lootItems[5];
	int lootChance[5];  // Percentage
};

// Scroll modes
typedef enum {
	SCROLL_NONE = 0,        // Fits on screen, no scrolling
	SCROLL_PAGINATED,       // Multi-page (D advances, A goes back)
	SCROLL_SPLIT_TEXT,      // A/D scrolls text, W/S for menu
	SCROLL_TEXT_FIRST       // Must scroll through text before options
} rpgScrollMode_t;

// Text scrolling state
typedef struct {
	char fullText[2048];    // Full text content
	int currentPage;        // Current page (for paginated)
	int totalPages;         // Total pages
	int scrollOffset;       // Line offset for continuous scroll
	int maxScroll;          // Max scroll offset
	rpgScrollMode_t mode;   // Current scroll mode
} rpgTextScroll_t;

// Main game state
struct rpgGame_s {
	qboolean active;
	rpgState_t state;
	rpgState_t previousState;  // For back navigation

	rpgPlayer_t player;

	// Narrative
	int dreamSequence;  // Which dream/vision is currently playing (0 = intro, 1-5 = story beats)

	// UI
	int selection;
	int numOptions;
	int page;  // For paginated views
	int maxPages;

	// Scrolling
	rpgTextScroll_t scroll;

	// Subsystems
	rpgCombat_t combat;
	rpgDialogue_t dialogue;

	// Input tracking
	qboolean lastForward;
	qboolean lastBackward;
	qboolean lastLeft;
	qboolean lastRight;
	qboolean lastUse;
	qboolean lastAttack;
	qboolean lastAltAttack;  // For item examination
	qboolean lastJump;  // For JUMP button detection in dream sequences

	// Timing
	int lastRefreshTime;
	int messageDisplayUntil;
	char messageText[256];
	int nextDisplayTime;  // Delayed initial display timer (prevents client disconnect)

	// Ambient message cooldowns
	int lastAmbientMessageTime;  // General ambient message cooldown
	int lastHolocronWhisperTime;  // Holocron whisper cooldown
	int lastCrowdWhisperTime;     // Crowd whisper cooldown (Act 2)
	int lastHallucinationTime;    // Hallucination combat trigger cooldown

	// Narrative tracking (prevents spam)
	int lastNarrativeState;  // Last state where narrative was sent
	int lastNarrativeDream;  // Last dream sequence where narrative was sent

	// Corruption pulse system (UI color breathing effect)
	int corruptionPulseTimer;  // Next time to toggle color
	int corruptionColorState;  // 0 or 1 (toggles between ^1 Red and ^5 Cyan)

	// Act progression and meta-systems
	int currentAct;  // 1-5, controls which horror systems are active
	int frozenUntil;  // Act 3: Fake reboot freeze duration
	int lastInventoryShift;  // Act 2: Infected Inventory cooldown
	qboolean loreDiscovered[MAX_RPG_ITEMS];  // Track which item lore has been read
	qboolean truthUnlocked;  // Act 5: Cipher code solved
	qboolean fourthWallBroken;  // Act 4: Fourth wall break triggered flag

	// Act 4: Glitch Burst system (Fragment psychic attacks)
	int glitchEndTime;  // When the horror ends
	int glitchNextFrameTime;  // Next visual update (100ms intervals)
	rpgState_t stateBeforeGlitch;  // Restore after glitch

	// World data (populated at init)
	rpgRoom_t rooms[MAX_RPG_ROOMS];
	int roomCount;

	rpgNPC_t npcs[MAX_RPG_NPCS];
	int npcCount;

	rpgItem_t items[MAX_RPG_ITEMS];
	int itemCount;

	rpgQuest_t quests[MAX_RPG_QUESTS];
	int questCount;

	rpgEnemy_t enemies[MAX_RPG_ENEMIES];
	int enemyCount;
};

// =============================================================================
// FUNCTION DECLARATIONS
// =============================================================================

// Initialization
void G_RPG_Init(gentity_t *player);
void G_RPG_Shutdown(gentity_t *player);
void G_RPG_InitWorld(rpgGame_t *game);
void G_RPG_InitPlayer(rpgPlayer_t *player, rpgClass_t class);

// Game loop
void G_RPG_Think(gentity_t *player);
void G_RPG_ProcessInput(gentity_t *player, usercmd_t *cmd);
void G_RPG_RefreshDisplay(gentity_t *player);

// Display functions
void G_RPG_ShowIntro(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowCharacterCreation(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowClassSelection(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowExploration(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowCombat(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowDialogue(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowInventory(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowCharacterSheet(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowQuestLog(gentity_t *player, char *out, int maxLen);

// State handlers
void G_RPG_HandleIntro(gentity_t *player);
void G_RPG_HandleCharCreation(gentity_t *player);
void G_RPG_HandleClassSelection(gentity_t *player);
void G_RPG_HandleExploration(gentity_t *player);
void G_RPG_HandleCombat(gentity_t *player);
void G_RPG_HandleDialogue(gentity_t *player);
void G_RPG_HandleInventory(gentity_t *player);

// Game mechanics
void G_RPG_MoveToRoom(gentity_t *player, rpgGame_t *game, int roomID);
void G_RPG_StartCombat(gentity_t *player, int enemyID);
void G_RPG_StartDialogue(rpgGame_t *game, int npcID);
void G_RPG_PickupItem(rpgGame_t *game, int itemID);
void G_RPG_UseItem(rpgGame_t *game, int itemID);
void G_RPG_EquipItem(rpgGame_t *game, int itemID);
void G_RPG_UpdateQuest(rpgGame_t *game, int questID);
void G_RPG_CompleteQuest(rpgGame_t *game, int questID);

// Combat
void G_RPG_ExecuteCombatAction(gentity_t *player, rpgGame_t *game, rpgCombatAction_t action);
void G_RPG_EnemyTurn(gentity_t *player, rpgGame_t *game);
void G_RPG_EndCombat(gentity_t *player, rpgGame_t *game, qboolean victory);
int G_RPG_CalculateDamage(rpgGame_t *game, rpgPlayer_t *player, int baseDamage);
int G_RPG_CalculateDefense(rpgGame_t *game, rpgPlayer_t *player);
int G_RPG_CalculateWeight(rpgGame_t *game, rpgPlayer_t *player);

// Dialogue
void G_RPG_ProcessDialogueChoice(rpgGame_t *game, int choiceIndex);
void G_RPG_EndDialogue(rpgGame_t *game);

// Utility
const char *G_RPG_GetClassName(rpgClass_t class);
const char *G_RPG_GetStatName(rpgStat_t stat);
const char *G_RPG_GetHealthBar(int current, int max);
const char *G_RPG_GetAlignmentString(int alignment);
int G_RPG_GetStatModifier(int statValue);
qboolean G_RPG_HasItem(rpgPlayer_t *player, int itemID);
qboolean G_RPG_StatCheck(rpgPlayer_t *player, rpgStat_t stat, int required);
void G_RPG_AddXP(rpgPlayer_t *player, int xp);
void G_RPG_ModifyAlignment(rpgPlayer_t *player, int change);

// Save/Load
void G_RPG_SaveGame(gentity_t *player);
qboolean G_RPG_LoadGame(gentity_t *player);

// Special Functions
void G_RPG_ShowGlitchScreen(gentity_t *player);
void G_RPG_HandleDream(gentity_t *player);
void G_RPG_HandleShop(gentity_t *player);
void G_RPG_ShowDialogue(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowNPCDialogue(gentity_t *player, int npcID, int nodeID);
void G_RPG_HandleTakeItem(gentity_t *player);
void G_RPG_HandleTalkToNPC(gentity_t *player);
void G_RPG_ShowDream(gentity_t *player, char *hudOut, int hudMaxLen, char *narrativeOut, int narrativeMaxLen);
void G_RPG_ShowExplorationNarrative(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowExplorationMenu(gentity_t *player, char *out, int maxLen);
void G_RPG_ShowShop(gentity_t *player, char *out, int maxLen);

#endif // __G_RPG_H__
