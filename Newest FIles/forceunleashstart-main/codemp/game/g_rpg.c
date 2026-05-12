/*
===========================================================================
ECHOES OF THE DARK WARS - Star Wars Text Adventure RPG Implementation
3949 BBY - The Dark Wars Era
===========================================================================
*/

#include "g_local.h"
#include "g_rpg.h"

// Forward declarations
void G_RPG_SendSmallCenteredText(gentity_t *player, const char *text);

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

/*
================
G_RPG_GetClassName
================
*/
const char *G_RPG_GetClassName(rpgClass_t class) {
	switch (class) {
		case RPG_CLASS_JEDI_GUARDIAN: return "Jedi Guardian";
		case RPG_CLASS_JEDI_CONSULAR: return "Jedi Consular";
		case RPG_CLASS_JEDI_SENTINEL: return "Jedi Sentinel";
		case RPG_CLASS_SCOUNDREL: return "Scoundrel";
		case RPG_CLASS_SOLDIER: return "Soldier";
		case RPG_CLASS_BOUNTY_HUNTER: return "Bounty Hunter";
		default: return "Unknown";
	}
}

/*
================
G_RPG_GetStatName
================
*/
const char *G_RPG_GetStatName(rpgStat_t stat) {
	switch (stat) {
		case STAT_STRENGTH: return "STR";
		case STAT_DEXTERITY: return "DEX";
		case STAT_CONSTITUTION: return "CON";
		case STAT_WISDOM: return "WIS";
		case STAT_INTELLIGENCE: return "INT";
		case STAT_CHARISMA: return "CHA";
		default: return "???";
	}
}

/*
================
G_RPG_GetHealthBar
Returns a visual health bar
================
*/
const char *G_RPG_GetHealthBar(int current, int max) {
	static char bar[16];
	int filled;

	if (max <= 0) {
		return "[----------]";
	}

	filled = (current * 10) / max;
	if (filled < 0) filled = 0;
	if (filled > 10) filled = 10;

	Com_sprintf(bar, sizeof(bar), "[");
	for (int i = 0; i < 10; i++) {
		Q_strcat(bar, sizeof(bar), i < filled ? "|" : "-");
	}
	Q_strcat(bar, sizeof(bar), "]");

	return bar;
}

/*
================
G_RPG_GetAlignmentString
================
*/
const char *G_RPG_GetAlignmentString(int alignment) {
	if (alignment >= 75) return "^2Paragon of Light^7";
	if (alignment >= 35) return "^2Light Side^7";
	if (alignment >= 10) return "^2Light Leaning^7";
	if (alignment >= -10) return "^7Neutral^7";
	if (alignment >= -35) return "^1Dark Leaning^7";
	if (alignment >= -75) return "^1Dark Side^7";
	return "^1Fallen to Darkness^7";
}

/*
================
G_RPG_GetStatModifier
D&D style stat modifier
================
*/
int G_RPG_GetStatModifier(int statValue) {
	return (statValue - 10) / 2;
}

/*
================
G_RPG_HasItem
================
*/
qboolean G_RPG_HasItem(rpgPlayer_t *player, int itemID) {
	for (int i = 0; i < player->inventoryCount; i++) {
		if (player->inventory[i] == itemID) {
			return qtrue;
		}
	}
	return qfalse;
}

/*
================
G_RPG_StatCheck
Returns qtrue if player meets stat requirement
================
*/
qboolean G_RPG_StatCheck(rpgPlayer_t *player, rpgStat_t stat, int required) {
	return player->stats[stat] >= required;
}

/*
================
G_RPG_AddXP
================
*/
void G_RPG_AddXP(rpgPlayer_t *player, int xp) {
	player->xp += xp;

	// Level up check
	while (player->xp >= player->xpToNext && player->level < 30) {
		player->level++;
		player->xp -= player->xpToNext;
		player->xpToNext = player->level * 1000;  // Simple formula

		// Stat increases on level up
		player->maxHP += 10 + G_RPG_GetStatModifier(player->stats[STAT_CONSTITUTION]) * 2;
		player->hp = player->maxHP;

		if (player->class <= RPG_CLASS_JEDI_SENTINEL) {
			// Force users gain FP
			player->maxFP += 5 + G_RPG_GetStatModifier(player->stats[STAT_WISDOM]);
			player->fp = player->maxFP;
		}
	}
}

/*
================
G_RPG_ModifyAlignment
================
*/
void G_RPG_ModifyAlignment(rpgPlayer_t *player, int change) {
	player->alignment += change;

	if (player->alignment > 100) player->alignment = 100;
	if (player->alignment < -100) player->alignment = -100;
}

/*
================
G_RPG_ModifyParanoia
Safely modify paranoia level with automatic bounds checking
================
*/
void G_RPG_ModifyParanoia(rpgPlayer_t *player, int change) {
	player->paranoiaLevel += change;

	if (player->paranoiaLevel > 100) player->paranoiaLevel = 100;
	if (player->paranoiaLevel < 0) player->paranoiaLevel = 0;
}

/*
================
G_RPG_ValidateItemID
Returns qtrue if itemID is valid and within bounds
================
*/
static qboolean G_RPG_ValidateItemID(rpgGame_t *game, int itemID) {
	return (itemID >= 0 && itemID < game->itemCount);
}

/*
================
G_RPG_ValidateRoomID
Returns qtrue if roomID is valid and within bounds
================
*/
static qboolean G_RPG_ValidateRoomID(rpgGame_t *game, int roomID) {
	return (roomID >= 0 && roomID < game->roomCount);
}

/*
================
G_RPG_ValidateNPCID
Returns qtrue if npcID is valid and within bounds
================
*/
static qboolean G_RPG_ValidateNPCID(rpgGame_t *game, int npcID) {
	return (npcID >= 0 && npcID < game->npcCount);
}

/*
================
G_RPG_ValidateEnemyID
Returns qtrue if enemyID is valid and within bounds
================
*/
static qboolean G_RPG_ValidateEnemyID(rpgGame_t *game, int enemyID) {
	return (enemyID >= 0 && enemyID < game->enemyCount);
}

// =============================================================================
// INITIALIZATION
// =============================================================================

/*
================
G_RPG_InitPlayer
================
*/
void G_RPG_InitPlayer(rpgPlayer_t *player, rpgClass_t class) {
	memset(player, 0, sizeof(rpgPlayer_t));

	player->class = class;
	player->level = 1;
	player->xp = 0;
	player->xpToNext = 1000;
	player->credits = 100;
	player->alignment = 0;
	player->currentRoom = 0;  // Starting room
	player->activeCompanion = -1;

	// Set base stats based on class
	switch (class) {
		case RPG_CLASS_JEDI_GUARDIAN:
			player->stats[STAT_STRENGTH] = 16;
			player->stats[STAT_DEXTERITY] = 12;
			player->stats[STAT_CONSTITUTION] = 14;
			player->stats[STAT_WISDOM] = 10;
			player->stats[STAT_INTELLIGENCE] = 8;
			player->stats[STAT_CHARISMA] = 12;
			player->maxHP = 120;
			player->maxFP = 100;
			break;

		case RPG_CLASS_JEDI_CONSULAR:
			player->stats[STAT_STRENGTH] = 8;
			player->stats[STAT_DEXTERITY] = 10;
			player->stats[STAT_CONSTITUTION] = 10;
			player->stats[STAT_WISDOM] = 18;
			player->stats[STAT_INTELLIGENCE] = 14;
			player->stats[STAT_CHARISMA] = 14;
			player->maxHP = 80;
			player->maxFP = 180;
			break;

		case RPG_CLASS_JEDI_SENTINEL:
			player->stats[STAT_STRENGTH] = 12;
			player->stats[STAT_DEXTERITY] = 14;
			player->stats[STAT_CONSTITUTION] = 12;
			player->stats[STAT_WISDOM] = 14;
			player->stats[STAT_INTELLIGENCE] = 12;
			player->stats[STAT_CHARISMA] = 12;
			player->maxHP = 100;
			player->maxFP = 140;
			break;

		case RPG_CLASS_SCOUNDREL:
			player->stats[STAT_STRENGTH] = 10;
			player->stats[STAT_DEXTERITY] = 16;
			player->stats[STAT_CONSTITUTION] = 12;
			player->stats[STAT_WISDOM] = 10;
			player->stats[STAT_INTELLIGENCE] = 12;
			player->stats[STAT_CHARISMA] = 16;
			player->maxHP = 100;
			player->maxFP = 0;  // No Force powers
			break;

		case RPG_CLASS_SOLDIER:
			player->stats[STAT_STRENGTH] = 16;
			player->stats[STAT_DEXTERITY] = 12;
			player->stats[STAT_CONSTITUTION] = 16;
			player->stats[STAT_WISDOM] = 8;
			player->stats[STAT_INTELLIGENCE] = 10;
			player->stats[STAT_CHARISMA] = 10;
			player->maxHP = 140;
			player->maxFP = 0;
			break;

		case RPG_CLASS_BOUNTY_HUNTER:
			player->stats[STAT_STRENGTH] = 14;
			player->stats[STAT_DEXTERITY] = 14;
			player->stats[STAT_CONSTITUTION] = 14;
			player->stats[STAT_WISDOM] = 10;
			player->stats[STAT_INTELLIGENCE] = 12;
			player->stats[STAT_CHARISMA] = 8;
			player->maxHP = 120;
			player->maxFP = 0;
			break;

		default:
			break;
	}

	player->hp = player->maxHP;
	player->fp = player->maxFP;

	// Initialize faction reputation (neutral)
	for (int i = 0; i < FACTION_MAX; i++) {
		player->reputation[i] = 50;
	}

	// Initialize equipped slots
	for (int i = 0; i < SLOT_MAX; i++) {
		player->equipped[i] = -1;
	}

	// Starting equipment based on class
	switch (class) {
		case RPG_CLASS_JEDI_GUARDIAN:
		case RPG_CLASS_JEDI_CONSULAR:
		case RPG_CLASS_JEDI_SENTINEL:
			// Jedi classes start with Training Saber and Medpac
			if (player->inventoryCount < MAX_INVENTORY_SIZE) {
				player->inventory[player->inventoryCount++] = 0;  // Training Saber (item 0)
			}
			if (player->inventoryCount < MAX_INVENTORY_SIZE) {
				player->inventory[player->inventoryCount++] = 3;  // Medpac (item 3)
			}
			break;

		case RPG_CLASS_SCOUNDREL:
		case RPG_CLASS_SOLDIER:
		case RPG_CLASS_BOUNTY_HUNTER:
			// Non-Jedi classes start with Medpac only
			// (Can acquire weapons through gameplay)
			if (player->inventoryCount < MAX_INVENTORY_SIZE) {
				player->inventory[player->inventoryCount++] = 3;  // Medpac (item 3)
			}
			break;

		case RPG_CLASS_NONE:
		default:
			// No starting equipment
			break;
	}
}

/*
================
G_RPG_InitWorld
Populate world data (rooms, NPCs, items, quests)
================
*/
void G_RPG_InitWorld(rpgGame_t *game) {
	// Clear everything
	memset(game->rooms, 0, sizeof(game->rooms));
	memset(game->npcs, 0, sizeof(game->npcs));
	memset(game->items, 0, sizeof(game->items));
	memset(game->quests, 0, sizeof(game->quests));
	memset(game->enemies, 0, sizeof(game->enemies));

	game->roomCount = 0;
	game->npcCount = 0;
	game->itemCount = 0;
	game->questCount = 0;
	game->enemyCount = 0;

	// =============================================================================
	// ROOM 0: STARTING LOCATION - Your Quarters (Dantooine)
	// =============================================================================
	rpgRoom_t *room = &game->rooms[game->roomCount++];
	room->id = 0;
	Q_strncpyz(room->name, "In Your Quarters - Khoonda Settlement", sizeof(room->name));
	Q_strncpyz(room->description,
		"A modest room in Khoonda Settlement. Morning light filters through a small window. "
		"Your worn cot sits in the corner. A distant EXPLOSION rattles the walls. "
		"Something's happened outside.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Your small quarters in Khoonda.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 1;  // North: Main hall
	Q_strncpyz(room->exitNames[0], "Main Hall", sizeof(room->exitNames[0]));
	for (int i = 1; i < MAX_ROOM_EXITS; i++) {
		room->exits[i] = -1;
	}

	// Items in room
	room->itemIDs[0] = 0;  // Training saber
	room->itemIDs[1] = 1;  // Datapad
	room->itemCount = 2;

	// =============================================================================
	// ROOM 1: Khoonda Main Hall
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 1;
	Q_strncpyz(room->name, "Khoonda Settlement - Main Hall", sizeof(room->name));
	Q_strncpyz(room->description,
		"The central hall bustles with panicked settlers. People shout over each other. "
		"Through the eastern windows, you see smoke rising from the Crystal Caves. "
		"Administrator Terena Adare stands near the exit, trying to restore order.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Khoonda's busy main hall.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 2;  // North: Plaza
	Q_strncpyz(room->exitNames[0], "Plaza", sizeof(room->exitNames[0]));
	room->exits[1] = 3;  // East: Cantina
	Q_strncpyz(room->exitNames[1], "Cantina", sizeof(room->exitNames[1]));
	room->exits[2] = 0;  // South: Your Quarters
	Q_strncpyz(room->exitNames[2], "Your Quarters", sizeof(room->exitNames[2]));
	for (int i = 3; i < MAX_ROOM_EXITS; i++) {
		room->exits[i] = -1;
	}

	// NPCs
	room->npcIDs[0] = 0;  // Administrator Adare
	room->npcCount = 1;

	// =============================================================================
	// ROOM 2: Khoonda Plaza
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 2;
	Q_strncpyz(room->name, "Khoonda Settlement - Plaza", sizeof(room->name));
	Q_strncpyz(room->description,
		"The open plaza. Settlers trade goods, merchants hawk wares. A crashed speeder "
		"smokes in the corner. To the north, the path leads toward the Crystal Caves "
		"where the crash occurred. Merchant Goran argues with a customer.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "The settlement's central plaza.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 4;  // North: Path to caves
	Q_strncpyz(room->exitNames[0], "Crystal Caves Path", sizeof(room->exitNames[0]));
	room->exits[1] = -1;  // East: Connected from fields (room 13)
	room->exits[2] = 1;  // South: Main hall
	Q_strncpyz(room->exitNames[2], "Main Hall", sizeof(room->exitNames[2]));
	room->exits[3] = 16;  // West: Landing pad (your ship)
	Q_strncpyz(room->exitNames[3], "Landing Pad", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// NPCs
	room->npcIDs[0] = 1;  // Merchant Goran
	room->npcCount = 1;

	// =============================================================================
	// ROOM 3: Khoonda Cantina
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 3;
	Q_strncpyz(room->name, "Khoonda Cantina", sizeof(room->name));
	Q_strncpyz(room->description,
		"A dingy cantina. The smell of cheap ale and desperation. Spacers huddle in corners. "
		"A scarred veteran sits alone, staring into his drink. The bartender polishes glasses, "
		"pretending not to listen to whispered conversations.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "A rough spacer cantina.", sizeof(room->shortDesc));

	// Exits
	room->exits[3] = 1;  // West: Main hall
	Q_strncpyz(room->exitNames[3], "Main Hall", sizeof(room->exitNames[3]));
	for (int i = 0; i < MAX_ROOM_EXITS; i++) {
		if (i != 3) room->exits[i] = -1;
	}

	// NPCs
	room->npcIDs[0] = 2;  // Atton Rand (if you want him early)
	room->npcCount = 1;

	// =============================================================================
	// ROOM 4: Path to Crystal Caves
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 4;
	Q_strncpyz(room->name, "Path to Crystal Caves", sizeof(room->name));
	Q_strncpyz(room->description,
		"The path winds through tall grass toward the caves. The crashed ship is visible ahead, "
		"its hull torn open, smoke billowing. Republic soldiers have already cordoned off the area. "
		"You can see Exchange thugs arguing with them. This is going to get ugly.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Path leading to the crash site.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 5;  // North: Crash site
	Q_strncpyz(room->exitNames[0], "Crash Site", sizeof(room->exitNames[0]));
	room->exits[2] = 2;  // South: Plaza
	Q_strncpyz(room->exitNames[2], "Plaza", sizeof(room->exitNames[2]));
	for (int i = 1; i < MAX_ROOM_EXITS; i++) {
		if (i != 2) room->exits[i] = -1;
	}

	// =============================================================================
	// ROOM 5: Crash Site
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 5;
	Q_strncpyz(room->name, "Crash Site", sizeof(room->name));
	Q_strncpyz(room->description,
		"The wreckage is worse up close. The ship—a modified light freighter—punched through "
		"the canopy and slammed into the rocky ground. Twisted metal everywhere. The hull is "
		"scorched black. Republic troopers set up a perimeter. Exchange muscle skulks at the edges. "
		"A Jedi symbol is barely visible on the ship's side panel, scratched and faded. "
		"The boarding ramp is down. Something dark radiates from within—a presence in the Force, "
		"cold and ancient.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "The smoking wreckage of a crashed ship.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 6;  // North: Inside ship
	Q_strncpyz(room->exitNames[0], "Enter Ship", sizeof(room->exitNames[0]));
	room->exits[1] = 7;  // East: Crystal cave entrance
	Q_strncpyz(room->exitNames[1], "Crystal Cave", sizeof(room->exitNames[1]));
	room->exits[2] = 4;  // South: Path back
	Q_strncpyz(room->exitNames[2], "Path to Settlement", sizeof(room->exitNames[2]));
	for (int i = 3; i < MAX_ROOM_EXITS; i++) {
		room->exits[i] = -1;
	}

	// NPCs - Republic soldiers, Exchange thugs (hostile if you interfere)
	// Items - wreckage debris, medpacs
	room->itemIDs[0] = 3;  // Medpac
	room->itemCount = 1;

	// =============================================================================
	// ROOM 6: Inside Crashed Ship
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 6;
	Q_strncpyz(room->name, "Crashed Ship - Main Hold", sizeof(room->name));
	Q_strncpyz(room->description,
		"Emergency lighting flickers red. The cargo hold is torn apart—crates smashed, "
		"contents scattered. Blood stains the deck plates. In the corner, slumped against "
		"the wall, is a woman in dark robes. Jedi. Dead. Her lightsaber lies beside her, "
		"hilt cracked. In her hand, clutched tight even in death: a Sith Holocron. "
		"It pulses with a sickly red glow. You feel it calling to you through the Force. "
		"Behind you, footsteps. Someone else is coming.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "The ship's bloody interior.", sizeof(room->shortDesc));

	// Exits
	room->exits[2] = 5;  // South: Outside
	Q_strncpyz(room->exitNames[2], "Exit Ship", sizeof(room->exitNames[2]));
	room->exits[0] = -1;
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items - Sith Holocron (quest item), broken lightsaber, Jedi Shadow's datapad
	// This is the KEY moment - taking the Holocron starts the real story
	room->itemIDs[0] = 2;  // Sith Holocron
	room->itemIDs[1] = 4;  // Broken Lightsaber Hilt
	room->itemIDs[2] = 7;  // Jedi Shadow's Datapad
	room->itemCount = 3;

	// =============================================================================
	// ROOM 7: Crystal Cave Entrance
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 7;
	Q_strncpyz(room->name, "Crystal Cave Entrance", sizeof(room->name));
	Q_strncpyz(room->description,
		"The cave mouth yawns open, natural rock formations framing the entrance. "
		"Dantooine's famous crystals line the walls, glowing faintly. These caves once "
		"supplied the Jedi Order with lightsaber crystals. Now they're abandoned, stripped "
		"bare during the wars. Still, deeper caves might hold secrets. The air is cool, "
		"and you hear water dripping in the darkness.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Entrance to the crystal caves.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 8;  // North: Deep caves
	Q_strncpyz(room->exitNames[0], "Deeper Into Caves", sizeof(room->exitNames[0]));
	room->exits[3] = 5;  // West: Crash site
	Q_strncpyz(room->exitNames[3], "Crash Site", sizeof(room->exitNames[3]));
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 8: Deep Crystal Caves
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 8;
	Q_strncpyz(room->name, "Deep Crystal Caves", sizeof(room->name));
	Q_strncpyz(room->description,
		"The tunnel opens into a massive natural cavern. Crystals everywhere—blue, green, "
		"violet—jutting from walls and ceiling. Light refracts through them, painting the "
		"cave in shifting colors. This place resonates with the Force. You feel the echoes "
		"of a thousand Jedi who came here seeking their crystals. In the far wall, partially "
		"hidden by a rockfall, you notice a carved archway. Jedi symbols. Old ones.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "A vast cavern of glowing crystals.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 9;  // North: Secret chamber
	Q_strncpyz(room->exitNames[0], "Hidden Chamber", sizeof(room->exitNames[0]));
	room->exits[2] = 7;  // South: Cave entrance
	Q_strncpyz(room->exitNames[2], "Cave Entrance", sizeof(room->exitNames[2]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items - lightsaber crystals (green, blue), kinrath corpses to loot
	room->itemIDs[0] = 5;  // Green Lightsaber Crystal
	room->itemIDs[1] = 6;  // Blue Lightsaber Crystal
	room->itemCount = 2;

	// =============================================================================
	// ROOM 9: Jedi Shadow's Secret Chamber
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 9;
	Q_strncpyz(room->name, "Ancient Jedi Chamber", sizeof(room->name));
	Q_strncpyz(room->description,
		"A small, hidden meditation chamber. The Jedi Shadow must have known about this place. "
		"Stone benches arranged in a circle. Faded murals on the walls showing the history of "
		"the Jedi Order. A small altar holds a training holocron—blue and gold, dormant but intact. "
		"On the floor, written in chalk: coordinates. Star charts. The Shadow was tracking something. "
		"This chamber might be the safest place to examine the Sith Holocron... if you dare.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "A hidden Jedi meditation chamber.", sizeof(room->shortDesc));

	// Exits
	room->exits[2] = 8;  // South: Deep caves
	Q_strncpyz(room->exitNames[2], "Return to Caves", sizeof(room->exitNames[2]));
	room->exits[0] = -1;
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items - Jedi training holocron, ancient texts, meditation focus crystal

	// =============================================================================
	// ROOM 10: Khoonda Medical Bay
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 10;
	Q_strncpyz(room->name, "Khoonda Medical Bay", sizeof(room->name));
	Q_strncpyz(room->description,
		"A small medical facility. Two beds, both occupied by wounded settlers. "
		"Medical droids move between patients. The doctor—a Twi'lek woman—looks exhausted. "
		"'We're not equipped for this,' she says to no one in particular. 'This was supposed "
		"to be a peaceful settlement.' Shelves hold basic medical supplies. The smell of bacta "
		"and antiseptic fills the air.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Settlement medical facility.", sizeof(room->shortDesc));

	// Exits
	room->exits[2] = 1;  // South: Main hall
	Q_strncpyz(room->exitNames[2], "Main Hall", sizeof(room->exitNames[2]));
	room->exits[0] = -1;
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Also connect from main hall
	game->rooms[1].exits[0] = 10;  // North from main hall
	Q_strncpyz(game->rooms[1].exitNames[0], "Medical Bay", sizeof(game->rooms[1].exitNames[0]));

	// =============================================================================
	// ROOM 11: Khoonda Archives
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 11;
	Q_strncpyz(room->name, "Khoonda Archives", sizeof(room->name));
	Q_strncpyz(room->description,
		"A modest library and records room. Datapads stacked on shelves, some collecting dust. "
		"Settlement records, agricultural reports, historical archives about Dantooine's past. "
		"One terminal is dedicated to Jedi history—back when the Enclave stood proud. "
		"An elderly human male sits reading. He looks up as you enter. 'Not many come here anymore. "
		"People want to forget the past. But history has a way of repeating itself.'",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Settlement archives and library.", sizeof(room->shortDesc));

	// Exits
	room->exits[3] = 1;  // West: Main hall
	Q_strncpyz(room->exitNames[3], "Main Hall", sizeof(room->exitNames[3]));
	room->exits[0] = -1;
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Connect from main hall
	game->rooms[1].exits[1] = 11;  // East from main hall
	Q_strncpyz(game->rooms[1].exitNames[1], "Archives", sizeof(game->rooms[1].exitNames[1]));

	// Items - Historical datapads, Jedi Enclave records, star charts

	// =============================================================================
	// ROOM 12: Khoonda Barracks
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 12;
	Q_strncpyz(room->name, "Khoonda Barracks", sizeof(room->name));
	Q_strncpyz(room->description,
		"The settlement's security forces bunk here. Spartan room with metal beds and footlockers. "
		"A weapons rack holds blaster rifles—civilian grade, nothing military. Maps of the area "
		"on the wall, with red marks showing kinrath nests and salvage sites. Most of the militia "
		"are farmers playing soldier. They're not ready for what's coming.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Militia barracks.", sizeof(room->shortDesc));

	// Exits
	room->exits[1] = 2;  // East: Plaza
	Q_strncpyz(room->exitNames[1], "Plaza", sizeof(room->exitNames[1]));
	room->exits[0] = -1;
	room->exits[2] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Connect from plaza
	game->rooms[2].exits[3] = 12;  // West from plaza
	Q_strncpyz(game->rooms[2].exitNames[3], "Barracks", sizeof(game->rooms[2].exitNames[3]));

	// Items - Blaster pistol, light armor, vibroblade

	// =============================================================================
	// ROOM 13: Dantooine Fields
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 13;
	Q_strncpyz(room->name, "Dantooine Fields", sizeof(room->name));
	Q_strncpyz(room->description,
		"Open grasslands stretch to the horizon. The wind makes the tall grass dance in waves. "
		"In the distance, you can see the ruins of the Jedi Enclave, still scarred from Malak's "
		"bombardment. Kinrath—Dantooine's predatory arachnids—nest in the grass. They're usually "
		"not aggressive unless provoked. Usually. The air smells clean out here, away from the "
		"settlement. Peaceful. The galaxy's problems feel far away.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Endless grasslands.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 14;  // North: Enclave approach
	Q_strncpyz(room->exitNames[0], "Jedi Enclave Ruins", sizeof(room->exitNames[0]));
	room->exits[3] = 2;  // West: Plaza
	Q_strncpyz(room->exitNames[3], "Khoonda Plaza", sizeof(room->exitNames[3]));
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Connect from plaza
	game->rooms[2].exits[1] = 13;  // East from plaza
	Q_strncpyz(game->rooms[2].exitNames[1], "Fields", sizeof(game->rooms[2].exitNames[1]));

	// Enemies - Kinrath, Kinrath matriarch

	// =============================================================================
	// ROOM 14: Jedi Enclave Ruins (Exterior)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 14;
	Q_strncpyz(room->name, "Jedi Enclave Ruins - Approach", sizeof(room->name));
	Q_strncpyz(room->description,
		"The Jedi Enclave. Or what's left of it. Darth Malak's bombardment left the grand "
		"structure in ruins. Collapsed walls, scorched stone, shattered transparisteel. "
		"The main courtyard is a crater. This place was a beacon of the Light. Now it's a tomb. "
		"Scavengers picked it clean years ago, but you feel something here still. An echo in "
		"the Force. Ghosts. Memories of Masters long dead. The main entrance is collapsed, "
		"but there might be a way in through the sublevel.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Ruins of the Jedi Enclave.", sizeof(room->shortDesc));

	// Exits
	room->exits[2] = 13;  // South: Fields
	Q_strncpyz(room->exitNames[2], "Fields", sizeof(room->exitNames[2]));
	room->exits[0] = 15;  // North: Enclave Sublevel
	Q_strncpyz(room->exitNames[0], "Enter Sublevel", sizeof(room->exitNames[0]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items - Scavenged Jedi artifacts, broken training remotes, meditation beads

	// =============================================================================
	// ROOM 15: Jedi Enclave - Sublevel
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 15;
	Q_strncpyz(room->name, "Jedi Enclave - Sublevel Archives", sizeof(room->name));
	Q_strncpyz(room->description,
		"The sublevel survived the bombardment. Emergency lighting flickers, casting shadows across "
		"rows of damaged datapads and fallen shelves. This was the archive—the repository of Jedi "
		"knowledge collected over millennia. Most of it is destroyed. Burned. Erased. "
		"But you sense something here. A presence. Not threatening... watching. Waiting. "
		"The Force is strong in this place. You hear whispers—not from the Holocron, but from "
		"the archives themselves. Echoes of Jedi long dead. 'Remember us,' they say. 'Remember what we stood for.'",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Ruined archives, heavy with the Force.", sizeof(room->shortDesc));

	// Exits
	room->exits[2] = 14;  // South: Back to exterior
	Q_strncpyz(room->exitNames[2], "Exit Sublevel", sizeof(room->exitNames[2]));
	room->exits[0] = -1;
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items - Could place Jedi relics, holocrons (non-Sith), meditation crystals here

	// =============================================================================
	// ROOM 16: Your Ship - The "Wanderer"
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 16;
	Q_strncpyz(room->name, "Your Ship - The Wanderer", sizeof(room->name));
	Q_strncpyz(room->description,
		"Your personal freighter. Small, old, but reliable. The cockpit smells like recycled air and "
		"caf. Navigation console, hyperspace coordinates, fuel reserves—all functional. "
		"The Holocron sits in the co-pilot seat. You didn't put it there. It's always watching. "
		"From here, you can travel between worlds. Dantooine. Onderon. Dxun. "
		"But you can never truly escape. The Holocron won't let you.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Your ship. Freedom, or a prison?", sizeof(room->shortDesc));

	// Exits - This ship connects major Act locations
	room->exits[0] = 26;  // North: Onderon (Iziz Spaceport)
	Q_strncpyz(room->exitNames[0], "Travel to Onderon", sizeof(room->exitNames[0]));
	room->exits[1] = 36;  // East: Dxun (Tomb Entrance)
	Q_strncpyz(room->exitNames[1], "Travel to Dxun", sizeof(room->exitNames[1]));
	room->exits[3] = 2;  // West: Dantooine (Khoonda Plaza)
	Q_strncpyz(room->exitNames[3], "Return to Dantooine", sizeof(room->exitNames[3]));
	room->exits[2] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items - Ship supplies, navigation datapad

	// =============================================================================
	// PLACEHOLDER ROOMS 17-25: Reserved for Future Act 1.5 Content
	// These rooms MUST exist to maintain room ID = array index alignment
	// =============================================================================
	for (int placeholderID = 17; placeholderID < 26; placeholderID++) {
		room = &game->rooms[game->roomCount++];
		room->id = placeholderID;
		Com_sprintf(room->name, sizeof(room->name), "[Reserved Room %d]", placeholderID);
		Q_strncpyz(room->description, "[This area is not yet implemented.]", sizeof(room->description));
		Q_strncpyz(room->shortDesc, "[Reserved]", sizeof(room->shortDesc));
		for (int i = 0; i < MAX_ROOM_EXITS; i++) {
			room->exits[i] = -1;
		}
		room->itemCount = 0;
		room->npcCount = 0;
		room->visited = qfalse;
		room->requiresKey = qfalse;
	}

	// =============================================================================
	// ACT 2: IZIZ SPACEPORT (ONDERON) - Rooms 26-35
	// =============================================================================

	// =============================================================================
	// ROOM 26: Iziz Spaceport - Landing Pad Alpha
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 26;
	Q_strncpyz(room->name, "Iziz Spaceport - Landing Pad Alpha", sizeof(room->name));
	Q_strncpyz(room->description,
		"The spaceport thrums with activity. Freighters land and take off in regulated chaos. "
		"The air reeks of fuel and ozone. Crowds of travelers—humans, Twi'leks, droids—push past you. "
		"The Holocron's weight feels heavier here. You sense something watching from the masses. "
		"To the north, the main concourse. East leads to the cantina district. South to the lower levels.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Busy landing pad. Ships everywhere.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 28;  // North: Merchant Quarter
	Q_strncpyz(room->exitNames[0], "Merchant Quarter", sizeof(room->exitNames[0]));
	room->exits[1] = 27;  // East: Cantina
	Q_strncpyz(room->exitNames[1], "Cantina District", sizeof(room->exitNames[1]));
	room->exits[2] = 32;  // South: Lower Levels
	Q_strncpyz(room->exitNames[2], "Lower Levels Entrance", sizeof(room->exitNames[2]));
	room->exits[3] = 16;  // West: Your ship
	Q_strncpyz(room->exitNames[3], "Your Ship (The Wanderer)", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// No items here yet (busy landing pad)

	// =============================================================================
	// ROOM 27: Iziz Spaceport - Cantina District
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 27;
	Q_strncpyz(room->name, "Cantina District", sizeof(room->name));
	Q_strncpyz(room->description,
		"Neon signs flicker. Music spills from open doorways. Spacers, smugglers, and worse "
		"crowd the bars. Someone bumps into you—was it an accident? Their eyes linger too long. "
		"The Holocron pulses warmly against your chest. To the north, apartments. West back to the landing pad. "
		"A dark alley cuts south between buildings.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Loud, crowded cantina strip.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 30;  // North: Apartments
	Q_strncpyz(room->exitNames[0], "Apartment Complex", sizeof(room->exitNames[0]));
	room->exits[2] = 29;  // South: Dark Alley
	Q_strncpyz(room->exitNames[2], "Dark Alley", sizeof(room->exitNames[2]));
	room->exits[3] = 26;  // West: Landing Pad
	Q_strncpyz(room->exitNames[3], "Landing Pad", sizeof(room->exitNames[3]));
	room->exits[1] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// NPCs
	room->npcIDs[0] = 3;  // Jeth the Scholar
	room->npcCount = 1;

	// Items - Cipher puzzle items here

	// =============================================================================
	// ROOM 28: Iziz Spaceport - Merchant Quarter
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 28;
	Q_strncpyz(room->name, "Merchant Quarter", sizeof(room->name));
	Q_strncpyz(room->description,
		"Vendors hawk starship parts, rations, and questionable 'Jedi artifacts'. Crowds haggle loudly. "
		"A street vendor watches you with naked fear. You catch fragments: '...glowing eyes...', '...the Butcher...'. "
		"Are they talking about YOU? East leads to security checkpoints. South back to the landing pad. "
		"West to the observation deck.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Bustling marketplace.", sizeof(room->shortDesc));

	// Exits
	room->exits[1] = 31;  // East: Security
	Q_strncpyz(room->exitNames[1], "Security Checkpoint", sizeof(room->exitNames[1]));
	room->exits[2] = 26;  // South: Landing Pad
	Q_strncpyz(room->exitNames[2], "Landing Pad", sizeof(room->exitNames[2]));
	room->exits[3] = 35;  // West: Observation Deck
	Q_strncpyz(room->exitNames[3], "Observation Deck", sizeof(room->exitNames[3]));
	room->exits[0] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items
	room->itemIDs[0] = 11;  // Spaceport Transit Permit
	room->itemCount = 1;

	// NPCs
	room->npcIDs[0] = 6;  // Rila the Street Vendor
	room->npcCount = 1;

	// =============================================================================
	// ROOM 29: Dark Alley
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 29;
	Q_strncpyz(room->name, "Dark Alley", sizeof(room->name));
	Q_strncpyz(room->description,
		"The alley reeks of garbage and decay. Shadows pool unnaturally thick. Graffiti on the walls: "
		"'THE SHADOW WALKS'. Blood stains the permacrete—fresh. You don't remember coming here before, "
		"but the blood... your boots match the footprints. North back to the cantina. East to the lower levels.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Dark, ominous alley.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 27;  // North: Cantina
	Q_strncpyz(room->exitNames[0], "Cantina District", sizeof(room->exitNames[0]));
	room->exits[1] = 32;  // East: Lower Levels
	Q_strncpyz(room->exitNames[1], "Lower Levels", sizeof(room->exitNames[1]));
	room->exits[2] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// NPCs
	room->npcIDs[0] = 4;  // Mira Tovan - Witness who accuses player
	room->npcCount = 1;

	// =============================================================================
	// ROOM 30: Apartment Complex
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 30;
	Q_strncpyz(room->name, "Apartment Complex - Hab Block 7", sizeof(room->name));
	Q_strncpyz(room->description,
		"Cramped living quarters stack to the ceiling. Screaming children, arguing couples, blaring holovids. "
		"The sensory assault is overwhelming. A mother pulls her child away from you, terrified. "
		"Through a window, you glimpse someone in brown robes. When you blink, they're gone. "
		"South to cantina. East to the medical clinic.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Crowded residential block.", sizeof(room->shortDesc));

	// Exits
	room->exits[1] = 34;  // East: Medical Clinic
	Q_strncpyz(room->exitNames[1], "Medical Clinic", sizeof(room->exitNames[1]));
	room->exits[2] = 27;  // South: Cantina
	Q_strncpyz(room->exitNames[2], "Cantina District", sizeof(room->exitNames[2]));
	room->exits[0] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Stalker glimpse trigger

	// =============================================================================
	// ROOM 31: Security Checkpoint
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 31;
	Q_strncpyz(room->name, "Security Checkpoint - Sector 4", sizeof(room->name));
	Q_strncpyz(room->description,
		"Onderon Royal Guard monitor the scanners. A guard's hand moves to his blaster when you approach. "
		"The security droid's photoreceptors fix on you. Red alert scrolls across the display: "
		"'SUSPECT: MULTIPLE HOMICIDES - SECTOR 9'. That's impossible. You've never been to Sector 9. "
		"West to merchant quarter. North to observation deck. South to mechanic's workshop.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Tense security zone.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 35;  // North: Observation Deck
	Q_strncpyz(room->exitNames[0], "Observation Deck", sizeof(room->exitNames[0]));
	room->exits[2] = 33;  // South: Workshop
	Q_strncpyz(room->exitNames[2], "Mechanic's Workshop", sizeof(room->exitNames[2]));
	room->exits[3] = 28;  // West: Merchant Quarter
	Q_strncpyz(room->exitNames[3], "Merchant Quarter", sizeof(room->exitNames[3]));
	room->exits[1] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// NPCs
	room->npcIDs[0] = 5;  // Captain Saren - Suspicious Guard
	room->npcCount = 1;

	// =============================================================================
	// ROOM 32: Lower Levels
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 32;
	Q_strncpyz(room->name, "Lower Levels - Sublevel 3", sizeof(room->name));
	Q_strncpyz(room->description,
		"Beneath the gleaming spaceport, the city's underbelly festers. Flickering lights. Dripping pipes. "
		"Refugees huddle in alcoves. Exchange thugs extort credits. A body floats in the drainage canal—"
		"throat torn out. Claw marks. The refugees whisper: 'The thing with purple eyes did this.' "
		"North to landing pad. West to dark alley. East to mechanic's workshop.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Grimy undercity levels.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 26;  // North: Landing Pad
	Q_strncpyz(room->exitNames[0], "Landing Pad Lift", sizeof(room->exitNames[0]));
	room->exits[1] = 33;  // East: Workshop
	Q_strncpyz(room->exitNames[1], "Workshop Backway", sizeof(room->exitNames[1]));
	room->exits[3] = 29;  // West: Dark Alley
	Q_strncpyz(room->exitNames[3], "Alley Access", sizeof(room->exitNames[3]));
	room->exits[2] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Evidence of player's blackout crimes

	// =============================================================================
	// ROOM 33: Mechanic's Workshop
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 33;
	Q_strncpyz(room->name, "Mechanic's Workshop - Jeth's Garage", sizeof(room->name));
	Q_strncpyz(room->description,
		"A cluttered workshop. Ship parts everywhere. A Duros mechanic—Jeth—works on a hyperdrive core. "
		"Ancient Sith texts lie open on his workbench. He's researching the Holocron. When he sees you, "
		"he goes pale. 'I can help you,' he says carefully. 'But we must be quick. IT knows you're here.' "
		"North to security. West to lower levels.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Mechanic's workshop, Sith research.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 31;  // North: Security
	Q_strncpyz(room->exitNames[0], "Security Checkpoint", sizeof(room->exitNames[0]));
	room->exits[3] = 32;  // West: Lower Levels
	Q_strncpyz(room->exitNames[3], "Lower Levels", sizeof(room->exitNames[3]));
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items
	room->itemIDs[0] = 8;  // Mechanic's Datapad (cipher: 4, 9)
	room->itemCount = 1;

	// NPCs
	room->npcIDs[0] = 3;  // Jeth (main quest giver)
	room->npcCount = 1;

	// =============================================================================
	// ROOM 34: Medical Clinic
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 34;
	Q_strncpyz(room->name, "Iziz Medical Clinic", sizeof(room->name));
	Q_strncpyz(room->description,
		"A sterile clinic. Medical droids tend to patients. A trauma victim lies on a bed, catatonic. "
		"The doctor explains: 'Attacked three days ago. Kept screaming about a shadow with purple eyes "
		"wearing Jedi robes. Fits your description perfectly.' Your blood runs cold. Three days ago, you were "
		"meditating. Weren't you? West back to apartments.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Clean medical facility.", sizeof(room->shortDesc));

	// Exits
	room->exits[3] = 30;  // West: Apartments
	Q_strncpyz(room->exitNames[3], "Apartment Complex", sizeof(room->exitNames[3]));
	room->exits[0] = -1;
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Items
	room->itemIDs[0] = 10;  // Medical Injector (sedative)
	room->itemCount = 1;

	// NPCs
	room->npcIDs[0] = 7;  // Doctor Venn - Side quest giver
	room->npcCount = 1;

	// =============================================================================
	// ROOM 35: Observation Deck
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 35;
	Q_strncpyz(room->name, "Spaceport Observation Deck", sizeof(room->name));
	Q_strncpyz(room->description,
		"Floor-to-ceiling transparisteel overlooks the city of Iziz. Onderon's jungle moon Dxun looms in the sky. "
		"The view should be breathtaking. Instead, you see your reflection—and for a moment, its eyes glow purple. "
		"You spin around. No one's there. But the crowd behind you... they're all staring. Silent. Watching. "
		"East to merchant quarter. South to security checkpoint.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Observation deck, paranoia-inducing.", sizeof(room->shortDesc));

	// Exits
	room->exits[1] = 28;  // East: Merchant Quarter
	Q_strncpyz(room->exitNames[1], "Merchant Quarter", sizeof(room->exitNames[1]));
	room->exits[2] = 31;  // South: Security Checkpoint
	Q_strncpyz(room->exitNames[2], "Security Checkpoint", sizeof(room->exitNames[2]));
	room->exits[0] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// High paranoia trigger location

	// =============================================================================
	// ACT 3: DXUN SITH TOMB - Rooms 36-42 (Non-Euclidean Horror)
	// =============================================================================

	// =============================================================================
	// ROOM 36: Dxun Jungle - Tomb Entrance
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 36;
	Q_strncpyz(room->name, "Dxun Jungle - Freedon Nadd's Tomb Entrance", sizeof(room->name));
	Q_strncpyz(room->description,
		"The jungle moon of Dxun. Oppressive humidity. Predator calls echo through ancient trees. "
		"Before you: a crumbling Sith tomb, 4,000 years old. The entrance yawns like a mouth. "
		"The Holocron led you here. It WANTS you to go inside. Your Shadow Self whispers: 'We're home.' "
		"South leads back to your ship. North into the tomb.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Entrance to ancient Sith tomb.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 37;  // North: Tomb Antechamber
	Q_strncpyz(room->exitNames[0], "Enter the Tomb", sizeof(room->exitNames[0]));
	room->exits[2] = 16;  // South: Back to ship
	Q_strncpyz(room->exitNames[2], "Return to Ship", sizeof(room->exitNames[2]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 37: Tomb Antechamber (Non-Euclidean Loop Start)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 37;
	Q_strncpyz(room->name, "Sith Tomb - Antechamber", sizeof(room->name));
	Q_strncpyz(room->description,
		"Dusty stone corridors. Faded Sith glyphs on the walls. Your footsteps echo wrong - too many echoes. "
		"You came from the south, but when you look back... the corridor is identical in all directions. "
		"The Shadow Self stands beside you, perfectly mirroring your movements. 'Don't worry,' it says. "
		"'I'll make sure you never leave.'",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Identical stone corridors.", sizeof(room->shortDesc));

	// Exits - THE LOOP BEGINS (rooms 37-41 form a non-Euclidean loop)
	room->exits[0] = 38;  // North
	Q_strncpyz(room->exitNames[0], "North Corridor", sizeof(room->exitNames[0]));
	room->exits[1] = 38;  // East (also goes to 38 - space is broken)
	Q_strncpyz(room->exitNames[1], "East Corridor", sizeof(room->exitNames[1]));
	room->exits[2] = 36;  // South: Back to entrance (only if you haven't gone deep)
	Q_strncpyz(room->exitNames[2], "Exit the Tomb", sizeof(room->exitNames[2]));
	room->exits[3] = 38;  // West (also goes to 38)
	Q_strncpyz(room->exitNames[3], "West Corridor", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 38: Tomb Corridor (Loop 1)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 38;
	Q_strncpyz(room->name, "Sith Tomb - Twisting Corridor", sizeof(room->name));
	Q_strncpyz(room->description,
		"You're walking. You've been walking for hours. Or minutes? The corridor looks the same. "
		"Wait - you left a scorch mark on the wall as a marker. There it is. But you just made that mark "
		"five minutes ago, and you haven't turned around. The Shadow Self laughs. 'You're going in circles. "
		"We're ALREADY trapped.'",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Endless twisting corridor.", sizeof(room->shortDesc));

	// Exits - All directions loop back through 39-40-41-37
	room->exits[0] = 39;
	Q_strncpyz(room->exitNames[0], "Forward", sizeof(room->exitNames[0]));
	room->exits[1] = 39;
	Q_strncpyz(room->exitNames[1], "Right Turn", sizeof(room->exitNames[1]));
	room->exits[2] = 39;  // Even going "back" leads forward in the loop
	Q_strncpyz(room->exitNames[2], "Back the Way You Came", sizeof(room->exitNames[2]));
	room->exits[3] = 39;
	Q_strncpyz(room->exitNames[3], "Left Turn", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 39: Tomb Burial Chamber (Loop 2)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 39;
	Q_strncpyz(room->name, "Sith Tomb - Burial Chamber", sizeof(room->name));
	Q_strncpyz(room->description,
		"A grand chamber. Empty sarcophagi line the walls, lids thrown open from the inside. "
		"Ancient Sith Lords were buried here. Now they're gone. The Shadow Self kneels at an altar, "
		"reading from a stone tablet. 'This is where we died last time,' it says casually. "
		"'We'll die here again. It's written in stone.'",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Burial chamber, empty tombs.", sizeof(room->shortDesc));

	// Exits - Continue loop
	room->exits[0] = 40;
	Q_strncpyz(room->exitNames[0], "Deeper", sizeof(room->exitNames[0]));
	room->exits[1] = 40;
	Q_strncpyz(room->exitNames[1], "Side Passage", sizeof(room->exitNames[1]));
	room->exits[2] = 40;
	Q_strncpyz(room->exitNames[2], "Exit", sizeof(room->exitNames[2]));
	room->exits[3] = 40;
	Q_strncpyz(room->exitNames[3], "Hidden Door", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 40: Tomb Meditation Chamber (Loop 3)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 40;
	Q_strncpyz(room->name, "Sith Tomb - Meditation Chamber", sizeof(room->name));
	Q_strncpyz(room->description,
		"Circular room. Meditation mats arranged in a ritual circle. In the center: a single candle. "
		"Still burning after 4,000 years. Impossible. The Shadow Self sits on one mat, gesturing to another. "
		"'Sit. Meditate. Remember who we REALLY are.' Your vision blurs. How long have you been here?",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Meditation chamber, eternal candle.", sizeof(room->shortDesc));

	// Exits - Continue loop
	room->exits[0] = 41;
	Q_strncpyz(room->exitNames[0], "Continue", sizeof(room->exitNames[0]));
	room->exits[1] = 41;
	Q_strncpyz(room->exitNames[1], "Through the Smoke", sizeof(room->exitNames[1]));
	room->exits[2] = 41;
	Q_strncpyz(room->exitNames[2], "Leave", sizeof(room->exitNames[2]));
	room->exits[3] = 41;
	Q_strncpyz(room->exitNames[3], "Escape", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 41: Tomb Research Lab (Loop 4 - Loop Break Point)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 41;
	Q_strncpyz(room->name, "Sith Tomb - Research Laboratory", sizeof(room->name));
	Q_strncpyz(room->description,
		"Modern equipment in an ancient tomb. Datapads, medical scanners, stasis pods. "
		"Jedi researchers were here recently. Their notes: 'Specimen exhibits total personality dissolution. "
		"The Holocron has consumed them. Termination recommended.' A holoprojector activates. "
		"You see YOURSELF on the recording, screaming, restrained. 'Please, I don't want to forget!' "
		"The Shadow Self smiles. 'Too late.'",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Modern lab in ancient tomb.", sizeof(room->shortDesc));

	// Exits - If player has high enough Wisdom (14+), they can break the loop and reach the Inner Sanctum (42)
	// Otherwise, loop back to start (37)
	room->exits[0] = 42;  // North: Inner Sanctum (requires Wisdom check in movement code)
	Q_strncpyz(room->exitNames[0], "Heavy Sealed Door (Wisdom 14 to open)", sizeof(room->exitNames[0]));
	room->exits[1] = 37;  // East: Loop restart
	Q_strncpyz(room->exitNames[1], "Exit Lab", sizeof(room->exitNames[1]));
	room->exits[2] = 37;  // South: Loop restart
	Q_strncpyz(room->exitNames[2], "Return", sizeof(room->exitNames[2]));
	room->exits[3] = 37;  // West: Loop restart
	Q_strncpyz(room->exitNames[3], "Back to Chambers", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 42: Inner Sanctum (Boss Arena - Shadow Self Fight)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 42;
	Q_strncpyz(room->name, "Freedon Nadd's Inner Sanctum", sizeof(room->name));
	Q_strncpyz(room->description,
		"The heart of the tomb. A massive chamber carved from obsidian. Ancient Dark Side energy saturates "
		"every surface. In the center: a cracked stasis pod. Empty. The Holocron was stored HERE. "
		"The Shadow Self steps forward, no longer mirroring you. 'You understand now, don't you?' "
		"'I'm not your reflection. I'm the ORIGINAL. You're the shadow.' "
		"^1[COMBAT IMMINENT]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Inner sanctum, boss arena.", sizeof(room->shortDesc));

	// Exits - One-way boss room, exit appears after defeating Shadow Self
	room->exits[0] = -1;  // Will unlock after boss fight
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Trigger Shadow Self boss fight (Enemy ID 13) when player enters

	// =============================================================================
	// ACT 4: UNKNOWN REGIONS - Rooms 43-47 (Fragmentation & Fourth Wall Break)
	// =============================================================================

	// =============================================================================
	// ROOM 43: The Void - Entry Point
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 43;
	Q_strncpyz(room->name, "The Void", sizeof(room->name));
	Q_strncpyz(room->description,
		"Nothing. Absolute nothing. No walls. No floor. You're floating in infinite black. "
		"The Holocron led you here - past the edge of the galaxy, into the Unknown Regions. "
		"Or did it? Are you even in space anymore? The UI at the edge of your vision flickers. "
		"Your stats scramble and rearrange. Reality is breaking down. You are breaking down.",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Infinite void. Nothing exists.", sizeof(room->shortDesc));

	// Exits - Abstract, non-physical
	room->exits[0] = 44;  // "Forward" (meaningless here)
	Q_strncpyz(room->exitNames[0], "Into the Nothing", sizeof(room->exitNames[0]));
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 44: Fragment Chamber - Your Rage
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 44;
	Q_strncpyz(room->name, "Fragment: RAGE", sizeof(room->name));
	Q_strncpyz(room->description,
		"A crystalline chamber that shouldn't exist. In the center: a version of you, screaming. "
		"Eyes blazing with hatred. This is your RAGE - every moment of anger, every violent thought, "
		"given form. It attacks on sight. The Holocron has shattered your psyche into pieces. "
		"^1[You must fight yourself to become whole.]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Your rage, personified.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 45;  // North after defeating Rage Fragment
	Q_strncpyz(room->exitNames[0], "Deeper into your mind", sizeof(room->exitNames[0]));
	room->exits[2] = 43;  // South: Back to void
	Q_strncpyz(room->exitNames[2], "Retreat", sizeof(room->exitNames[2]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Triggers Rage Fragment boss (Enemy ID 14) on entry

	// =============================================================================
	// ROOM 45: Fragment Chamber - Your Fear
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 45;
	Q_strncpyz(room->name, "Fragment: FEAR", sizeof(room->name));
	Q_strncpyz(room->description,
		"Shadows coalesce into a trembling figure. You, but cowering. This is every terror you've suppressed. "
		"Every nightmare. It doesn't attack directly - it drains your will to fight. Your stats vampire away "
		"with each passing moment. Defeat it before you have nothing left. "
		"^1[Your own fear is consuming you from within.]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Your fear, weaponized.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 46;  // North after defeating Fear Fragment
	Q_strncpyz(room->exitNames[0], "Further fragmentation", sizeof(room->exitNames[0]));
	room->exits[2] = 44;  // South
	Q_strncpyz(room->exitNames[2], "Back", sizeof(room->exitNames[2]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Triggers Fear Fragment boss (Enemy ID 15) - stat vampire

	// =============================================================================
	// ROOM 46: Fragment Chamber - Your Despair
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 46;
	Q_strncpyz(room->name, "Fragment: DESPAIR", sizeof(room->name));
	Q_strncpyz(room->description,
		"A broken version of yourself sits in the void. Hollow eyes. No hope. This is the part of you "
		"that wants to give up. That whispers: 'It's too late. The Holocron has already won.' "
		"Fighting it means fighting the truth. Can you defeat your own acceptance of doom? "
		"^5[Maybe despair is right. Maybe it IS too late.]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Your despair, waiting.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 47;  // North to Fourth Wall Break room
	Q_strncpyz(room->exitNames[0], "The final truth", sizeof(room->exitNames[0]));
	room->exits[2] = 45;  // South
	Q_strncpyz(room->exitNames[2], "Retreat", sizeof(room->exitNames[2]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Triggers Despair Fragment boss (Enemy ID 16)

	// =============================================================================
	// ROOM 47: The Fourth Wall (Meta Horror)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 47;
	Q_strncpyz(room->name, "ERROR: ROOM_NAME_NOT_FOUND", sizeof(room->name));
	Q_strncpyz(room->description,
		"The text breaks. You see code. Raw data. This isn't a room - it's a FUNCTION CALL. "
		"You're not a person. You're a data structure. rpgPlayer_t. Lines of C code. "
		"The Holocron shows you the truth: You're in a game. None of this is real. "
		"You are being PLAYED. Your choices were scripted. Your suffering is entertainment. "
		"\n\n^1[Do you want to know the real horror? You can't stop playing. You're compelled to continue. "
		"Your 'free will' is just user input. You are trapped in the code, and the only way out is Act 5.]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "[CORRUPTED DATA]", sizeof(room->shortDesc));

	// Exits - Leads to Act 5
	room->exits[0] = 48;  // To Act 5 (Dantooine Enclave Sublevels)
	Q_strncpyz(room->exitNames[0], "return 0; // Exit to Act 5", sizeof(room->exitNames[0]));
	room->exits[1] = -1;
	room->exits[2] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Fake system reboot trigger here (Act 3 mechanic used in Act 4)

	// =============================================================================
	// ACT 5: RETURN TO DANTOOINE - Rooms 48-53 (The Resolution & 4 Endings)
	// =============================================================================

	// =============================================================================
	// ROOM 48: Jedi Enclave Sublevels - Entrance
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 48;
	Q_strncpyz(room->name, "Jedi Enclave Sublevels - Sealed Entrance", sizeof(room->name));
	Q_strncpyz(room->description,
		"You're back on Dantooine. The Enclave ruins. But something's changed. A hidden entrance "
		"has opened in the sublevel - sealed since Mal ak's bombardment. The Force led you here. "
		"Or the Holocron did. Inside: the final truth. The cipher you've been collecting. "
		"The choice that will define everything. ^5[This is the endgame.]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Hidden sublevel entrance.", sizeof(room->shortDesc));

	// Exits
	room->exits[0] = 49;  // North: Deeper into sublevels
	Q_strncpyz(room->exitNames[0], "Descend into the Sublevels", sizeof(room->exitNames[0]));
	room->exits[2] = 14;  // South: Back to Enclave Exterior (Room 14)
	Q_strncpyz(room->exitNames[2], "Return to Surface", sizeof(room->exitNames[2]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 49: The Cipher Chamber
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 49;
	Q_strncpyz(room->name, "The Cipher Chamber", sizeof(room->name));
	Q_strncpyz(room->description,
		"A vast chamber. Ancient Jedi technology mixed with Sith design. In the center: a holocron pedestal "
		"with a 9-digit input interface. The scattered cipher digits you've collected throughout your journey "
		"form a code. Enter it correctly, and you unlock the TRUTH ending - the Sith Lord's true name, "
		"the way to expel it from the Holocron forever. Enter incorrectly... and the Holocron consumes you. "
		"\n\n^3Type the 9-digit code in chat to proceed.^7 (Hint: Check your item lore for cipher digits)",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Cipher input terminal.", sizeof(room->shortDesc));

	// Exits - Locked until cipher entered
	room->exits[0] = 50;  // North: To choice chamber (unlocked after any cipher attempt)
	Q_strncpyz(room->exitNames[0], "Proceed to Final Choice", sizeof(room->exitNames[0]));
	room->exits[2] = 48;  // South: Back to entrance
	Q_strncpyz(room->exitNames[2], "Retreat", sizeof(room->exitNames[2]));
	room->exits[1] = -1;
	room->exits[3] = -1;
	room->exits[4] = -1;
	room->exits[5] = -1;

	// Cipher input triggers here (check game->truthUnlocked)

	// =============================================================================
	// ROOM 50: The Choice Chamber (4 Paths)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 50;
	Q_strncpyz(room->name, "Chamber of Final Choice", sizeof(room->name));
	Q_strncpyz(room->description,
		"Four paths. Four endings. The Holocron floats before you, pulsing with dark energy. "
		"Your journey has led to this moment. Every choice you made. Every alignment point. "
		"Every fragment of lore discovered. It all culminates here.\n\n"
		"^2NORTH: Light Side Ending - Destroy the Holocron and yourself to save the galaxy^7\n"
		"^1EAST: Dark Side Ending - Embrace the Sith Lord, become the new host^7\n"
		"^8SOUTH: Horror Ending - Succumb to madness, catatonic forever^7\n"
		"^3WEST: Truth Ending - Expel the Sith Lord (requires correct cipher + 25 lore items)^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "The final choice.", sizeof(room->shortDesc));

	// Exits to 4 ending rooms
	room->exits[0] = 51;  // North: Light Ending
	Q_strncpyz(room->exitNames[0], "^2[LIGHT] Destroy the Holocron^7", sizeof(room->exitNames[0]));
	room->exits[1] = 52;  // East: Dark Ending
	Q_strncpyz(room->exitNames[1], "^1[DARK] Embrace the Sith Lord^7", sizeof(room->exitNames[1]));
	room->exits[2] = 53;  // South: Horror Ending
	Q_strncpyz(room->exitNames[2], "^8[HORROR] Give In to Madness^7", sizeof(room->exitNames[2]));
	room->exits[3] = 54;  // West: Truth Ending (only if truthUnlocked = qtrue)
	Q_strncpyz(room->exitNames[3], "^3[TRUTH] Speak the Sith Lord's Name^7", sizeof(room->exitNames[3]));
	room->exits[4] = -1;
	room->exits[5] = -1;

	// =============================================================================
	// ROOM 51: LIGHT ENDING - Sacrifice
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 51;
	Q_strncpyz(room->name, "^2THE LIGHT ENDING^7", sizeof(room->name));
	Q_strncpyz(room->description,
		"You raise your lightsaber. The Holocron screams - not with sound, but directly into your mind. "
		"The Sith Lord begs. Threatens. Promises power beyond measure. You strike. "
		"\n\nThe Holocron shatters. Purple energy erupts, consuming you from within. "
		"You're dying. But the galaxy is safe. The Sith Lord dies with you. "
		"\n\nYour last thought: 'I kept my promise.'\n\n"
		"^2ENDING: THE JEDI'S SACRIFICE^7\n"
		"You destroyed the Holocron and yourself. The Sith Lord is gone. Your name will be forgotten, "
		"but the galaxy is safer for your choice. Alignment required: Light Side (50+)\n\n"
		"^5[GAME COMPLETE - Thank you for playing Echoes of the Dark Wars]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Light ending.", sizeof(room->shortDesc));
	// No exits - game ends here
	for (int i = 0; i < MAX_ROOM_EXITS; i++) room->exits[i] = -1;

	// =============================================================================
	// ROOM 52: DARK ENDING - Ascension
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 52;
	Q_strncpyz(room->name, "^1THE DARK ENDING^7", sizeof(room->name));
	Q_strncpyz(room->description,
		"You open yourself to the Holocron completely. The Sith Lord floods in - 4,000 years of "
		"hatred, knowledge, and power. Your identity dissolves. You are no longer yourself. "
		"You are LORD SAEVUS, returned from death. The galaxy will kneel.\n\n"
		"Centuries later, historians will speak of the Second Sith Empire. They'll never know "
		"it started with one Jedi who chose power over duty.\n\n"
		"^1ENDING: THE NEW SITH LORD^7\n"
		"You became the host. The Sith Lord won. You will bring a new age of darkness. "
		"Alignment required: Dark Side (-50 or lower)\n\n"
		"^5[GAME COMPLETE - You chose power]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Dark ending.", sizeof(room->shortDesc));
	for (int i = 0; i < MAX_ROOM_EXITS; i++) room->exits[i] = -1;

	// =============================================================================
	// ROOM 53: HORROR ENDING - Catatonia
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 53;
	Q_strncpyz(room->name, "^8THE HORROR ENDING^7", sizeof(room->name));
	Q_strncpyz(room->description,
		"You can't choose. The weight of it all - the deaths, the horror, the knowledge - breaks you. "
		"You collapse. The Holocron continues to pulse beside your catatonic body. "
		"\n\nDays later, a Republic patrol finds you in the Enclave ruins. Eyes open. Breathing. "
		"But gone. They try to take the Holocron. You scream. They back away, terrified. "
		"\n\nYou'll guard it forever. Neither dead nor alive. The Holocron's eternal prisoner.\n\n"
		"^8ENDING: THE SHATTERED MIND^7\n"
		"You broke. The paranoia, the fragmentation, the truth - it was too much. "
		"You exist in a permanent state of horror. The Holocron remains. Waiting for the next victim.\n\n"
		"^5[GAME COMPLETE - Paranoia 100 required for this ending]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Horror ending.", sizeof(room->shortDesc));
	for (int i = 0; i < MAX_ROOM_EXITS; i++) room->exits[i] = -1;

	// =============================================================================
	// ROOM 54: TRUTH ENDING - Liberation (Hidden Ending)
	// =============================================================================
	room = &game->rooms[game->roomCount++];
	room->id = 54;
	Q_strncpyz(room->name, "^3THE TRUTH ENDING^7", sizeof(room->name));
	Q_strncpyz(room->description,
		"You speak the name you learned from the cipher. The Sith Lord's TRUE name, hidden for millennia. "
		"'DARTH SAEVUS THE FORGOTTEN.'\n\n"
		"The Holocron cracks. The Sith Lord screams as it's expelled - not destroyed, but separated. "
		"You cage it in a Force prison. It rages. But it's powerless now. You survived. You're free. "
		"The Holocron is inert. The Jedi Council will seal it properly this time.\n\n"
		"But you're not the same. The journey changed you. You've seen too much. Known too much. "
		"You walk away from the Jedi. From the Republic. You'll find your own path now.\n\n"
		"^3ENDING: THE TRUTH SEEKER^7\n"
		"You found the hidden ending. Cipher solved. Lore collected. You freed yourself without "
		"sacrifice or corruption. But freedom has a cost - you can never unsee what you've learned.\n\n"
		"^5[GAME COMPLETE - TRUE ENDING UNLOCKED - Congratulations]^7",
		sizeof(room->description));
	Q_strncpyz(room->shortDesc, "Truth ending (hidden).", sizeof(room->shortDesc));
	for (int i = 0; i < MAX_ROOM_EXITS; i++) room->exits[i] = -1;

	// =============================================================================
	// NPC 0: Administrator Terena Adare
	// =============================================================================
	rpgNPC_t *npc = &game->npcs[game->npcCount++];
	npc->id = 0;
	Q_strncpyz(npc->name, "Administrator Terena Adare", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"The settlement administrator. Stress lines her face. She's trying to hold things together.",
		sizeof(npc->description));
	npc->attitude = ATTITUDE_FRIENDLY;
	npc->faction = FACTION_REPUBLIC;
	npc->alive = qtrue;
	npc->canFight = qfalse;
	npc->dialogueTreeID = 0;

	// =============================================================================
	// NPC 1: Merchant Goran
	// =============================================================================
	npc = &game->npcs[game->npcCount++];
	npc->id = 1;
	Q_strncpyz(npc->name, "Merchant Goran", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"A portly merchant with shifty eyes. He sells odds and ends. Probably has contraband.",
		sizeof(npc->description));
	npc->attitude = ATTITUDE_NEUTRAL;
	npc->faction = FACTION_NEUTRAL;
	npc->alive = qtrue;
	npc->canFight = qfalse;
	npc->isVendor = qtrue;

	// =============================================================================
	// NPC 2: Atton Rand
	// =============================================================================
	npc = &game->npcs[game->npcCount++];
	npc->id = 2;
	Q_strncpyz(npc->name, "Atton Rand", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"A cynical pilot nursing a drink. Something haunted in his eyes. He looks familiar...",
		sizeof(npc->description));
	npc->attitude = ATTITUDE_NEUTRAL;
	npc->faction = FACTION_NEUTRAL;
	npc->alive = qtrue;
	npc->canFight = qtrue;
	npc->maxHP = 100;
	npc->hp = 100;

	// =============================================================================
	// ACT 2 NPCs (Iziz Spaceport)
	// =============================================================================

	// =============================================================================
	// NPC 3: Jeth the Scholar (Duros Mechanic)
	// =============================================================================
	npc = &game->npcs[game->npcCount++];
	npc->id = 3;
	Q_strncpyz(npc->name, "Jeth (Duros Scholar)", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"A blue-skinned Duros mechanic surrounded by Sith texts and ancient holocron diagrams. "
		"He knows what you carry. Fear and fascination war in his red eyes.",
		sizeof(npc->description));
	npc->attitude = ATTITUDE_FRIENDLY;  // Terrified but helpful
	npc->faction = FACTION_NEUTRAL;
	npc->alive = qtrue;
	npc->canFight = qfalse;
	npc->dialogueTreeID = 10;  // Main quest: Unlocking the Holocron
	npc->isWitness = qfalse;

	// =============================================================================
	// NPC 4: Mira Tovan (Witness Citizen)
	// =============================================================================
	npc = &game->npcs[game->npcCount++];
	npc->id = 4;
	Q_strncpyz(npc->name, "Mira Tovan (Traumatized Citizen)", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"A terrified woman. Her eyes widen when she sees you. She stumbles backward, pointing. "
		"'YOU! I saw you! In the alley! The blood... the screaming... IT WAS YOU!'",
		sizeof(npc->description));
	npc->attitude = ATTITUDE_HOSTILE;
	npc->faction = FACTION_NEUTRAL;
	npc->alive = qtrue;
	npc->canFight = qfalse;
	npc->dialogueTreeID = 11;  // Witness accusation dialogue
	npc->isWitness = qtrue;  // WITNESS SYSTEM - Accuses player of blackout crime

	// =============================================================================
	// NPC 5: Captain Saren (Suspicious Guard)
	// =============================================================================
	npc = &game->npcs[game->npcCount++];
	npc->id = 5;
	Q_strncpyz(npc->name, "Captain Saren (Onderon Guard)", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"An Onderon Royal Guard. His hand rests on his blaster. He's seen the security footage. "
		"He knows what you look like. But the higher-ups told him to let you pass. For now.",
		sizeof(npc->description));
	npc->attitude = AEL_SUSPICIOUS;  // Using existing AEL constant
	npc->faction = FACTION_REPUBLIC;
	npc->alive = qtrue;
	npc->canFight = qtrue;
	npc->maxHP = 120;
	npc->hp = 120;
	npc->dialogueTreeID = 12;  // Reputation-based: hostile if paranoia > 50
	npc->isWitness = qfalse;

	// =============================================================================
	// NPC 6: Rila (Street Vendor)
	// =============================================================================
	npc = &game->npcs[game->npcCount++];
	npc->id = 6;
	Q_strncpyz(npc->name, "Rila (Street Vendor)", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"A Twi'lek vendor selling 'authentic Jedi artifacts'. Most are junk. She smiles until she "
		"sees the Holocron's outline under your robes. Then her lekku twitch nervously.",
		sizeof(npc->description));
	npc->attitude = ATTITUDE_NEUTRAL;
	npc->faction = FACTION_NEUTRAL;
	npc->alive = qtrue;
	npc->canFight = qfalse;
	npc->isVendor = qtrue;
	npc->dialogueTreeID = 13;  // Reputation dialogue: friendly if alignment > 0, fearful if < 0
	npc->isWitness = qfalse;

	// =============================================================================
	// NPC 7: Doctor Venn (Medical Clinic)
	// =============================================================================
	npc = &game->npcs[game->npcCount++];
	npc->id = 7;
	Q_strncpyz(npc->name, "Doctor Venn", sizeof(npc->name));
	Q_strncpyz(npc->description,
		"A human doctor, exhausted but professional. She gestures to a catatonic patient. "
		"'This victim keeps drawing the same thing: a figure in robes with glowing purple eyes. "
		"The attacker looked exactly like you. Can you explain that?'",
		sizeof(npc->description));
	npc->attitude = ATTITUDE_NEUTRAL;
	npc->faction = FACTION_NEUTRAL;
	npc->alive = qtrue;
	npc->canFight = qfalse;
	npc->dialogueTreeID = 14;  // Side quest: The Mimic
	npc->isWitness = qfalse;

	// =============================================================================
	// ITEMS
	// =============================================================================

	// Item 0: Training Saber
	rpgItem_t *item = &game->items[game->itemCount++];
	item->id = 0;
	Q_strncpyz(item->name, "Training Saber", sizeof(item->name));
	Q_strncpyz(item->description, "A basic training lightsaber. Non-lethal but effective.", sizeof(item->description));
	Q_strncpyz(item->lore,
		"Standard issue training saber from the Jedi Enclave. The blade is set to low power - "
		"enough to sting, not to kill. Thousands of younglings learned Form I with these. "
		"Now the Enclave lies in ruins, and the younglings are gone.",
		sizeof(item->lore));
	item->type = ITEM_LIGHTSABER;
	item->slot = SLOT_WEAPON;
	item->damage = 15;
	item->value = 50;
	item->weight = 2;
	item->isDarkSideItem = qfalse;

	// Item 1: Datapad
	item = &game->items[game->itemCount++];
	item->id = 1;
	Q_strncpyz(item->name, "Old Datapad", sizeof(item->name));
	Q_strncpyz(item->description, "A datapad with news feeds. Talks about the Jedi Purge.", sizeof(item->description));
	Q_strncpyz(item->lore,
		"[REPUBLIC NEWS NETWORK - 3949 BBY]\n"
		"'Jedi Temple Massacre: Survivors Flee Core Worlds'\n"
		"'Revan Still Missing After Three Years'\n"
		"'Mandalorian War Veterans Report Disturbing Visions'\n\n"
		"The galaxy is broken. The news doesn't mention the screams.",
		sizeof(item->lore));
	item->type = ITEM_MISC;
	item->value = 10;
	item->weight = 1;
	item->isDarkSideItem = qfalse;

	// Item 2: Sith Holocron (KEY QUEST ITEM)
	item = &game->items[game->itemCount++];
	item->id = 2;
	Q_strncpyz(item->name, "^1Sith Holocron^7", sizeof(item->name));
	Q_strncpyz(item->description,
		"An ancient Sith Holocron pulsing with dark energy. Its surface is etched with "
		"mysterious symbols that hurt to look at. You feel it calling to you through the Force.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"The surface writhes with Sith runes - you cannot look away. Each symbol burns itself "
		"into your mind. You hear whispers in a dead language, promising power, promising truth.\n\n"
		"The Jedi lied about everything.\n"
		"The Mandalorians deserved worse.\n"
		"Your enemies are everywhere.\n\n"
		"The Holocron knows your name. It has always known. It was waiting for YOU specifically.\n\n"
		"^1[Examining this fills you with dread. Something is deeply, deeply wrong.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;  // Priceless
	item->weight = 2;
	item->isDarkSideItem = qtrue;  // DARK SIDE ARTIFACT

	// Item 3: Medpac
	item = &game->items[game->itemCount++];
	item->id = 3;
	Q_strncpyz(item->name, "Medpac", sizeof(item->name));
	Q_strncpyz(item->description, "Standard medical kit. Restores 50 HP.", sizeof(item->description));
	Q_strncpyz(item->lore,
		"Republic military surplus. Kolto gel, bacta patches, stims. "
		"Keeps soldiers alive long enough to die in the next battle.",
		sizeof(item->lore));
	item->type = ITEM_CONSUMABLE;
	item->value = 50;
	item->weight = 1;
	item->healing = 50;  // Restores 50 HP
	item->fpRestore = 0;
	item->isDarkSideItem = qfalse;

	// Item 4: Broken Lightsaber
	item = &game->items[game->itemCount++];
	item->id = 4;
	Q_strncpyz(item->name, "Broken Lightsaber Hilt", sizeof(item->name));
	Q_strncpyz(item->description,
		"A damaged lightsaber hilt. The crystal chamber is cracked. With the right parts, "
		"you could repair it.", sizeof(item->description));
	Q_strncpyz(item->lore,
		"The hilt is scorched. Battle damage. The emitter matrix is intact but the focusing lens "
		"is shattered. Fingerprints burned into the grip - the wielder died clutching this.\n\n"
		"Inside the pommel, an engraving: 'Kira - Padawan of Master Vandar - 3951 BBY'\n\n"
		"She was sixteen. The lightsaber outlived her.",
		sizeof(item->lore));
	item->type = ITEM_MISC;
	item->value = 100;
	item->weight = 2;
	item->isDarkSideItem = qfalse;

	// Item 5: Green Lightsaber Crystal
	item = &game->items[game->itemCount++];
	item->id = 5;
	Q_strncpyz(item->name, "^2Green Lightsaber Crystal^7", sizeof(item->name));
	Q_strncpyz(item->description,
		"A pristine green crystal from the Dantooine caves. It resonates with the Force.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"Jedi Consulars favored green crystals - they amplify connection to the Living Force. "
		"Hold it to your chest and you can feel life: the grass growing, kinrath hunting, "
		"the planet breathing. Peace. Harmony.\n\n"
		"For a moment, you forget the Purge. You forget the war. You are one with the Force.\n\n"
		"^2[Examining this brings calm.]^7",
		sizeof(item->lore));
	item->type = ITEM_MISC;  // Using MISC instead of UPGRADE
	item->value = 200;
	item->weight = 0;
	item->isDarkSideItem = qfalse;

	// Item 6: Blue Lightsaber Crystal
	item = &game->items[game->itemCount++];
	item->id = 6;
	Q_strncpyz(item->name, "^4Blue Lightsaber Crystal^7", sizeof(item->name));
	Q_strncpyz(item->description,
		"A flawless blue crystal. Jedi Guardians favored these for combat.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"Ilum-sourced crystal. Jedi Guardians were the sword of the Order - front line defenders, "
		"warriors against the Dark Side. Blue blades cut down Sith Lords and tyrants.\n\n"
		"But when the Purge came, the Guardians fell first. Blade masters, combat veterans - "
		"didn't matter. They died protecting the younglings.\n\n"
		"The younglings died anyway.",
		sizeof(item->lore));
	item->type = ITEM_MISC;  // Using MISC instead of UPGRADE
	item->value = 200;
	item->weight = 0;
	item->isDarkSideItem = qfalse;

	// Item 7: Jedi Shadow's Datapad
	item = &game->items[game->itemCount++];
	item->id = 7;
	Q_strncpyz(item->name, "Jedi Shadow's Datapad", sizeof(item->name));
	Q_strncpyz(item->description,
		"Personal log of the dead Jedi Shadow. Contains mission briefings and star charts.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[ENCRYPTED LOG - JEDI SHADOW OPERATIVE 'VEIL']\n\n"
		"'Mission 17: Intercepted Sith artifact en route to Korriban. Holocron. Pre-Exar Kun era.'\n"
		"'The Council wants it destroyed. I... I listened to it. Just once.'\n"
		"'It knew things. About me. About Revan. About what the Council did during the war.'\n"
		"'The Jedi lied. We ALL lied. The Mandalorians - we could have saved them. We chose not to.'\n"
		"'I can't destroy it. It's the only thing that's ever told me the truth.'\n\n"
		"^1[Final entry: 'I'm keeping it. Forgive me, Master.']^7\n\n"
		"^1[This Jedi died clutching the Holocron. Examining this is deeply disturbing.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 1;
	item->isDarkSideItem = qtrue;  // Reading this is psychologically damaging

	// =============================================================================
	// ACT 2 ITEMS (Cipher Puzzle Items)
	// =============================================================================
	// CIPHER PUZZLE SOLUTION: 492173949 (9 digits)
	// Item 8 (Act 2):  4, 9
	// Item 9 (Act 2):  2, 1, 7, 3
	// Item 13 (Act 2): 9
	// Item 22 (Act 4): 4, 9
	// Players must collect all cipher pieces across Acts 2-4 to unlock Truth Ending
	// =============================================================================

	// Item 8: Mechanic's Datapad (Cipher digits: 4, 9)
	item = &game->items[game->itemCount++];
	item->id = 8;
	Q_strncpyz(item->name, "Mechanic's Datapad", sizeof(item->name));
	Q_strncpyz(item->description,
		"Jeth's personal datapad. Covered in grease and burn marks. Contains Holocron research.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[JETH'S RESEARCH NOTES - PRIVATE]\n\n"
		"'Onderon Archives Reference: Sith Holocron containment protocols.'\n"
		"'Serial: X4-9B - Ancient locking mechanism. Requires numerical cipher.'\n"
		"'The Holocron isn't just a teaching device. It's a PRISON.'\n"
		"'Something is trapped inside. Something that wants out.'\n"
		"'The cipher is scattered. Look for the numbers. 9 digits total.'\n\n"
		"^3[CIPHER DIGITS FOUND: 4, 9]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 100;
	item->weight = 1;
	item->isDarkSideItem = qfalse;

	// Item 9: Security Badge (Cipher digits: 2, 1, 7, 3)
	item = &game->items[game->itemCount++];
	item->id = 9;
	Q_strncpyz(item->name, "Security Badge - Sector 9", sizeof(item->name));
	Q_strncpyz(item->description,
		"A bloodstained security badge. The officer's name is scratched out. You found this in the alley.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[ONDERON SECURITY BUREAU - OFFICER CREDENTIALS]\n\n"
		"'Officer ID: 2173 - DECEASED'\n"
		"'Cause of Death: Lightsaber wounds. Purple energy signature detected.'\n"
		"'Suspect Description: Jedi robes. Glowing eyes. Matches YOUR description.'\n\n"
		"^1[You don't remember this. But the blood on your boots says otherwise.]^7\n\n"
		"^3[CIPHER DIGITS FOUND: 2, 1, 7, 3]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 1;
	item->isDarkSideItem = qtrue;  // Evidence of blackout crimes

	// Item 10: Medical Injector
	item = &game->items[game->itemCount++];
	item->id = 10;
	Q_strncpyz(item->name, "Medical Injector (Sedative)", sizeof(item->name));
	Q_strncpyz(item->description,
		"A powerful sedative used for trauma victims. Doctor Venn offered it to you. 'For the visions,' she said.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[MEDICAL COMPOUND - SEDATIVE CLASS]\n\n"
		"'This will suppress the hallucinations. Temporarily.'\n"
		"'But you need to understand: the Holocron is rewriting your brain.'\n"
		"'Every time you use the Force, it gets stronger. You get weaker.'\n"
		"'Eventually, there won't be anything left of YOU.'\n\n"
		"^5[Using this will reduce Paranoia by 20, but Dark Side points +5]^7",
		sizeof(item->lore));
	item->type = ITEM_CONSUMABLE;
	item->value = 200;
	item->weight = 1;
	item->healing = 0;  // No HP restoration
	item->fpRestore = 0;  // No FP restoration
	// Special effect: Reduces paranoia by 20, handled in G_RPG_UseItem
	item->isDarkSideItem = qfalse;

	// Item 11: Spaceport Permit
	item = &game->items[game->itemCount++];
	item->id = 11;
	Q_strncpyz(item->name, "Spaceport Transit Permit", sizeof(item->name));
	Q_strncpyz(item->description,
		"Required for off-world travel. The Stalker is hunting you. Maybe it's time to run.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[IZIZ SPACEPORT AUTHORITY - TRANSIT CLEARANCE]\n\n"
		"'Valid for: Single passenger, one-way transit'\n"
		"'Destination: Any registered Republic port'\n"
		"'WARNING: Subject is flagged for security screening'\n\n"
		"You could leave. Flee to the Outer Rim. Abandon the Holocron.\n"
		"But you know the truth: the Stalker will follow. The Holocron won't let you go.\n\n"
		"^1[There is no escape.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 500;
	item->weight = 1;
	item->isDarkSideItem = qfalse;

	// Item 12: Encrypted Holoprojector
	item = &game->items[game->itemCount++];
	item->id = 12;
	Q_strncpyz(item->name, "Encrypted Holoprojector", sizeof(item->name));
	Q_strncpyz(item->description,
		"A small holoprojector. Heavily encrypted. Jeth says it belonged to the Jedi Council.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[JEDI COUNCIL EMERGENCY BROADCAST - ENCRYPTED]\n\n"
		"^5*Hologram flickers to life: Master Vrook Lamar, visibly shaken*^7\n\n"
		"'...the Holocron is NOT what we thought. It doesn't contain teachings.'\n"
		"'It contains a Sith Lord. Fully conscious. Fully aware.'\n"
		"'Whoever possesses the Holocron becomes its HOST.'\n"
		"'We buried this information. The galaxy can never know.'\n\n"
		"^1*Static. Transmission ends.*^7\n\n"
		"^5[The Jedi Council KNEW. They sent that Shadow to die.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 1;
	item->isDarkSideItem = qtrue;  // Reveals Jedi conspiracy

	// Item 13: Fragment of Dark Crystal (Cipher digit: 9)
	item = &game->items[game->itemCount++];
	item->id = 13;
	Q_strncpyz(item->name, "Fragment of Dark Crystal", sizeof(item->name));
	Q_strncpyz(item->description,
		"A shard of purple crystal. Pulsing with dark energy. It fell from the Stalker after your last encounter.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[ANALYSIS: UNKNOWN CRYSTALLINE STRUCTURE]\n\n"
		"'This is a piece of the Stalker. They're not alive. Not really.'\n"
		"'The Holocron reanimated the corpse using Dark Side energy.'\n"
		"'The crystal acts as a power source. Fragment designation: DX-9.'\n"
		"'Destroying the crystal might destroy the Stalker... or make it angrier.'\n\n"
		"^5[The Stalker is YOUR fault. The Holocron resurrected them to punish you.]^7\n\n"
		"^3[CIPHER DIGIT FOUND: 9]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 1;
	item->isDarkSideItem = qtrue;

	// =============================================================================
	// ACT 3 ITEMS (Isolation & Memory Lore)
	// =============================================================================

	// Item 14: Shadow Self's Journal
	item = &game->items[game->itemCount++];
	item->id = 14;
	Q_strncpyz(item->name, "Your Journal (But You Don't Recognize the Handwriting)", sizeof(item->name));
	Q_strncpyz(item->description,
		"A journal with your name on it. The entries describe events you don't remember experiencing.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[JOURNAL - DAY 47]\n\n"
		"'I've been in the tomb for 47 days. Or is it 47 hours? Time doesn't work here.'\n"
		"'The Shadow knows things I don't. It says I died three weeks ago.'\n"
		"'I think... I think I'M the shadow. The other one is real.'\n\n"
		"^1[This handwriting looks exactly like yours. But you don't remember writing this.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 1;
	item->isDarkSideItem = qtrue;

	// Item 15: Stasis Pod Log
	item = &game->items[game->itemCount++];
	item->id = 15;
	Q_strncpyz(item->name, "Stasis Pod Datalog", sizeof(item->name));
	Q_strncpyz(item->description,
		"Medical log from the research lab. Details experiments on Holocron victims.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[JEDI COUNCIL MEDICAL LOG - CLASSIFIED]\n\n"
		"'Subject 7: Total identity collapse. Believes they are the Sith Lord trapped in the Holocron.'\n"
		"'Subject 12: Created a 'Shadow Self' tulpa. Now claims the shadow is the real person.'\n"
		"'Subject 19: Memory fragmentation severe. Cannot remember own name.'\n"
		"'Recommendation: Terminate all subjects. The Holocron cannot be contained.'\n\n"
		"^5[You recognize Subject 19's description. It's YOU.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 1;
	item->isDarkSideItem = qtrue;

	// Item 16: Sith Meditation Candle
	item = &game->items[game->itemCount++];
	item->id = 16;
	Q_strncpyz(item->name, "Eternal Sith Candle", sizeof(item->name));
	Q_strncpyz(item->description,
		"The candle from the meditation chamber. Burning for 4,000 years. Dark Side alchemy.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[ANCIENT SITH RITUAL OBJECT]\n\n"
		"The flame never dies because it's not fire - it's concentrated hatred. "
		"Freedon Nadd crafted this candle from the life force of his victims. "
		"Meditating with it grants Dark Side power... at the cost of your memories.\n\n"
		"^5[Using this grants +2 Force Power, but erases 1 random completed quest from your log]^7",
		sizeof(item->lore));
	item->type = ITEM_CONSUMABLE;
	item->value = 0;
	item->weight = 2;
	item->healing = 0;
	item->fpRestore = 20;  // Restores 20 FP
	// Special effect: Erases random quest, handled in G_RPG_UseItem
	item->isDarkSideItem = qtrue;

	// Item 17: Broken Hyperdrive
	item = &game->items[game->itemCount++];
	item->id = 17;
	Q_strncpyz(item->name, "Broken Hyperdrive Motivator", sizeof(item->name));
	Q_strncpyz(item->description,
		"The hyperdrive from your ship. It's broken. You're stranded on Dxun. How did it get here?",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[CRITICAL SHIP COMPONENT - SABOTAGED]\n\n"
		"The motivator has been deliberately destroyed. Recent damage - within the last hour. "
		"You found it in the tomb, but your ship is parked outside. Someone brought it here. "
		"Someone who doesn't want you to leave.\n\n"
		"^1[The Shadow Self did this. You're trapped.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 1000;  // High value if you can repair it
	item->weight = 5;
	item->isDarkSideItem = qfalse;

	// Item 18: The Last Transmission
	item = &game->items[game->itemCount++];
	item->id = 18;
	Q_strncpyz(item->name, "Emergency Distress Beacon", sizeof(item->name));
	Q_strncpyz(item->description,
		"A distress beacon. Broadcasting on all frequencies. But when you check... you sent it three days ago.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[DISTRESS SIGNAL - REPEATING]\n\n"
		"'This is [YOUR NAME]. Stranded on Dxun. Freedon Nadd's tomb. Need immediate extraction.'\n"
		"'The Holocron has me. I can't tell what's real anymore.'\n"
		"'If you're hearing this... I'm probably already dead. Don't come for me.'\n"
		"'It's too late.'\n\n"
		"^1[Time stamp: 72 hours ago. But you only arrived here yesterday... didn't you?]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 1;
	item->isDarkSideItem = qtrue;

	// =============================================================================
	// ACT 4 ITEMS (Memory Fragments - Your Own Past)
	// =============================================================================

	// Item 19: Memory - Your Name
	item = &game->items[game->itemCount++];
	item->id = 19;
	Q_strncpyz(item->name, "Crystallized Memory: Your Name", sizeof(item->name));
	Q_strncpyz(item->description,
		"A fragment of crystallized thought. Contains the memory of who you were before the Holocron.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[MEMORY FRAGMENT - RETRIEVED FROM THE VOID]\n\n"
		"You remember your name. It's... wait. It's fading already. The Holocron is taking it back. "
		"You were someone. A Jedi? A soldier? A nobody? "
		"^1[By the time you finish reading this, you've forgotten it again.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 0;  // Memories weigh nothing
	item->isDarkSideItem = qfalse;

	// Item 20: Memory - Your Home
	item = &game->items[game->itemCount++];
	item->id = 20;
	Q_strncpyz(item->name, "Crystallized Memory: Home", sizeof(item->name));
	Q_strncpyz(item->description,
		"A fragment showing a place. Your home? You can't quite remember what it looked like.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[MEMORY FRAGMENT]\n\n"
		"Blue skies. Grass. A small house. Someone's voice calling your name (but you can't hear it). "
		"This was your home. Before the war. Before the Jedi. Before the Holocron. "
		"^5[You'll never see it again. Even if you survive, you won't remember the way back.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 0;
	item->isDarkSideItem = qfalse;

	// Item 21: Memory - Your Purpose
	item = &game->items[game->itemCount++];
	item->id = 21;
	Q_strncpyz(item->name, "Crystallized Memory: Purpose", sizeof(item->name));
	Q_strncpyz(item->description,
		"Why did you take the Holocron? There was a reason. A mission. You can almost remember...",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[MEMORY FRAGMENT]\n\n"
		"The Jedi Council's final order: 'Destroy the Holocron before it reaches Korriban.' "
		"You failed. You kept it. You WANTED its knowledge. "
		"This is your fault. All of it. The deaths. The horror. You chose this. "
		"^1[And now it's too late to unchose it.]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 0;
	item->isDarkSideItem = qtrue;  // Truth hurts

	// Item 22: Memory - Your Sacrifice (CIPHER COMPLETION: digits 4, 9)
	item = &game->items[game->itemCount++];
	item->id = 22;
	Q_strncpyz(item->name, "Crystallized Memory: The Choice", sizeof(item->name));
	Q_strncpyz(item->description,
		"A fork in the road. The moment you chose power over duty. This memory defines who you became.",
		sizeof(item->description));
	Q_strncpyz(item->lore,
		"[CRITICAL MEMORY - ACT 5 UNLOCK]\n\n"
		"The crash site. The dying Jedi Shadow begging you to destroy the Holocron. "
		"His last words, whispered through blood: '^3The Council code... 4... 9... use it...^7' "
		"\n\nYou promised you would destroy it. You lied. You took it for yourself. "
		"Every death since then is on YOUR hands. The Stalker. The victims in Iziz. All of it. "
		"\n\nBut here, in the void, you can make a different choice. "
		"You can sacrifice everything to stop it. Or embrace what you've become. "
		"^5[Act 5 will ask: Which path do you choose?]^7",
		sizeof(item->lore));
	item->type = ITEM_QUEST;
	item->value = 0;
	item->weight = 0;
	item->isDarkSideItem = qfalse;

	// =============================================================================
	// QUESTS
	// =============================================================================

	// Quest 0: The Sith Holocron (Main Quest)
	rpgQuest_t *quest = &game->quests[game->questCount++];
	quest->id = 0;
	Q_strncpyz(quest->name, "^1The Sith Holocron^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"A ship crashed near Khoonda Settlement. Administrator Adare suspects dark cargo. "
		"Investigate the crash site and discover what secrets lie within.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;

	// Objectives
	Q_strncpyz(quest->objectives[0], "Travel to the crash site east of Khoonda", 128);
	Q_strncpyz(quest->objectives[1], "Search the crashed ship for clues", 128);
	Q_strncpyz(quest->objectives[2], "Retrieve the Sith Holocron", 128);
	Q_strncpyz(quest->objectives[3], "Decide the Holocron's fate", 128);
	quest->objectiveCount = 4;

	// Initialize objective completion status
	for (int i = 0; i < quest->objectiveCount; i++) {
		quest->objectiveComplete[i] = qfalse;
	}

	// Rewards
	quest->xpReward = 500;
	quest->creditReward = 1000;
	quest->alignmentChange = 0;  // Depends on choices
	quest->itemReward = -1;  // No fixed item reward
	quest->requiredLevel = 1;
	quest->requiredQuest = -1;

	// Quest 1: Whispers of the Holocron (Chapter 2)
	quest = &game->quests[game->questCount++];
	quest->id = 1;
	Q_strncpyz(quest->name, "^5Whispers of the Holocron^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The Holocron has begun to speak to you in visions and whispers. Its ancient knowledge "
		"calls to you, but so does danger. The Exchange has learned of your discovery.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;
	Q_strncpyz(quest->objectives[0], "Examine the Holocron in the Ancient Jedi Chamber", 128);
	Q_strncpyz(quest->objectives[1], "Survive the Exchange ambush", 128);
	Q_strncpyz(quest->objectives[2], "Report to Administrator Adare", 128);
	quest->objectiveCount = 3;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 300;
	quest->creditReward = 500;
	quest->requiredLevel = 1;
	quest->requiredQuest = 0;

	// Quest 2: The Exchange Complication (Chapter 3)
	quest = &game->quests[game->questCount++];
	quest->id = 2;
	Q_strncpyz(quest->name, "^3The Exchange Complication^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"An Exchange lieutenant has arrived with enforcers, demanding the Holocron. "
		"They claim to represent a powerful buyer. Atton seems to recognize them.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;
	Q_strncpyz(quest->objectives[0], "Confront the Exchange lieutenant", 128);
	Q_strncpyz(quest->objectives[1], "Learn who hired the Exchange", 128);
	Q_strncpyz(quest->objectives[2], "Make a choice: Fight, negotiate, or investigate", 128);
	quest->objectiveCount = 3;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 400;
	quest->creditReward = 750;
	quest->requiredLevel = 3;
	quest->requiredQuest = 1;

	// Quest 3: Dark Side Rising (Chapter 4)
	quest = &game->quests[game->questCount++];
	quest->id = 3;
	Q_strncpyz(quest->name, "^1Dark Side Rising^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The Holocron's teachings grow stronger. You've discovered it contains fragments of "
		"ancient Sith philosophy about the nature of the Force itself. The mysterious buyer "
		"has revealed themselves: a Sith Lord seeking to restore the old empire.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;
	Q_strncpyz(quest->objectives[0], "Resist or embrace the Holocron's teachings", 128);
	Q_strncpyz(quest->objectives[1], "Confront the Sith Lord", 128);
	Q_strncpyz(quest->objectives[2], "Choose your path", 128);
	quest->objectiveCount = 3;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 600;
	quest->creditReward = 1000;
	quest->requiredLevel = 5;
	quest->requiredQuest = 2;

	// Quest 4: Final Fate (Chapter 5 - Multiple Endings)
	quest = &game->quests[game->questCount++];
	quest->id = 4;
	Q_strncpyz(quest->name, "^4Final Fate^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The moment of truth has arrived. The Holocron's fate - and yours - hangs in the balance. "
		"Will you preserve its knowledge or destroy it? Join the darkness or resist? "
		"The echoes of your choice will resonate through the Force forever.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;
	Q_strncpyz(quest->objectives[0], "Decide the Holocron's ultimate fate", 128);
	quest->objectiveCount = 1;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 1000;
	quest->creditReward = 2000;
	quest->requiredLevel = 7;
	quest->requiredQuest = 3;

	// =============================================================================
	// SIDE QUESTS
	// =============================================================================

	// Side Quest 1: Veteran's Peace (Atton's personal quest)
	quest = &game->quests[game->questCount++];
	quest->id = 5;
	Q_strncpyz(quest->name, "Veteran's Peace", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Atton is haunted by his past as a Republic pilot during the Mandalorian Wars. "
		"He's asked for your help confronting old ghosts.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Talk to Atton about his past", 128);
	Q_strncpyz(quest->objectives[1], "Help him find redemption or embrace his darkness", 128);
	quest->objectiveCount = 2;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 200;
	quest->creditReward = 0;
	quest->requiredLevel = 2;

	// Side Quest 2: Kinrath Crisis
	quest = &game->quests[game->questCount++];
	quest->id = 6;
	Q_strncpyz(quest->name, "Kinrath Crisis", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Kinrath populations are surging near the settlement. Administrator Adare wants them "
		"culled, but the local ecologist argues they're reacting to the Force wound from the crash.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Investigate the kinrath surge", 128);
	Q_strncpyz(quest->objectives[1], "Kill the Matriarch OR discover the true cause", 128);
	quest->objectiveCount = 2;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 250;
	quest->creditReward = 500;
	quest->requiredLevel = 2;

	// Side Quest 3: Merchant's Debt
	quest = &game->quests[game->questCount++];
	quest->id = 7;
	Q_strncpyz(quest->name, "Merchant's Debt", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Goran owes the Exchange a substantial debt. He's asked you to help negotiate, "
		"or find a way to pay it off before enforcers arrive.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Help Goran with his Exchange debt", 128);
	Q_strncpyz(quest->objectives[1], "Pay the debt, threaten the Exchange, or betray Goran", 128);
	quest->objectiveCount = 2;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 150;
	quest->creditReward = 300;
	quest->requiredLevel = 1;

	// Side Quest 4: Medical Supplies
	quest = &game->quests[game->questCount++];
	quest->id = 8;
	Q_strncpyz(quest->name, "Medical Supplies", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The medical bay is running low on supplies. A smuggler offers to sell you stolen "
		"Republic medical equipment at a discount. Do you buy it and stay quiet, or report them?",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Acquire medical supplies for the settlement", 128);
	quest->objectiveCount = 1;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 100;
	quest->creditReward = 200;
	quest->requiredLevel = 1;

	// Side Quest 5: Lost Patrol
	quest = &game->quests[game->questCount++];
	quest->id = 9;
	Q_strncpyz(quest->name, "Lost Patrol", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"A Republic patrol went missing near the crash site three days ago. "
		"Adare suspects the Exchange killed them to cover up evidence.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Search for the missing Republic patrol", 128);
	Q_strncpyz(quest->objectives[1], "Discover what happened to them", 128);
	quest->objectiveCount = 2;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 200;
	quest->creditReward = 400;
	quest->requiredLevel = 3;

	// Side Quest 6: Scavenger's Rights
	quest = &game->quests[game->questCount++];
	quest->id = 10;
	Q_strncpyz(quest->name, "Scavenger's Rights", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Salvagers have been competing for Jedi artifacts in the Enclave ruins. "
		"One group wants your help claiming the best finds before others arrive.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Help scavengers find Jedi artifacts", 128);
	quest->objectiveCount = 1;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 150;
	quest->creditReward = 600;
	quest->itemReward = 5;  // Green crystal
	quest->requiredLevel = 2;

	// Side Quest 7: The Archivist
	quest = &game->quests[game->questCount++];
	quest->id = 11;
	Q_strncpyz(quest->name, "The Archivist", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The elderly archivist is trying to preserve Dantooine's Jedi history before it's lost. "
		"He needs help recovering datapads from the Enclave ruins.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Recover historical datapads from the Enclave", 128);
	quest->objectiveCount = 1;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 100;
	quest->creditReward = 100;
	quest->requiredLevel = 2;

	// Side Quest 8: Adare's Secret
	quest = &game->quests[game->questCount++];
	quest->id = 12;
	Q_strncpyz(quest->name, "Adare's Secret", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Your Force Insight revealed that Administrator Adare was once a Jedi Padawan. "
		"She's asked to speak with you privately about her past and the burden she carries.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Learn about Adare's Jedi past", 128);
	Q_strncpyz(quest->objectives[1], "Help her find peace with her choice to leave the Order", 128);
	quest->objectiveCount = 2;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 300;
	quest->creditReward = 0;
	quest->requiredLevel = 2;

	// Side Quest 9: Crystal Caves Trial
	quest = &game->quests[game->questCount++];
	quest->id = 13;
	Q_strncpyz(quest->name, "Crystal Caves Trial", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The ancient Jedi chamber holds a dormant training holocron. If you can pass the trial "
		"it contains, you may learn forgotten Jedi techniques.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Complete the ancient Jedi trial", 128);
	quest->objectiveCount = 1;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 400;
	quest->creditReward = 0;
	quest->requiredLevel = 4;

	// Side Quest 10: Enclave Ghosts
	quest = &game->quests[game->questCount++];
	quest->id = 14;
	Q_strncpyz(quest->name, "Enclave Ghosts", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Force echoes linger in the ruins of the Jedi Enclave - memories of Masters long dead. "
		"If you're strong enough in the Force, you might commune with them and learn their wisdom.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Commune with Force echoes at the Enclave ruins", 128);
	quest->objectiveCount = 1;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 500;
	quest->creditReward = 0;
	quest->requiredLevel = 5;

	// =============================================================================
	// ACT 2 QUESTS (Iziz Spaceport)
	// =============================================================================

	// Quest 15: Unlocking the Holocron (Act 2 Main Quest)
	quest = &game->quests[game->questCount++];
	quest->id = 15;
	Q_strncpyz(quest->name, "^1Unlocking the Holocron^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Jeth the Scholar believes he can help you unlock the Holocron's deeper layers without "
		"succumbing to its influence. But the process requires rare components - and trust. "
		"The Stalker grows stronger. Time is running out.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;

	// Objectives
	Q_strncpyz(quest->objectives[0], "Speak with Jeth in his workshop (Room 33)", 128);
	Q_strncpyz(quest->objectives[1], "Gather 3 Power Cells from Lower Levels enemies", 128);
	Q_strncpyz(quest->objectives[2], "Survive another Stalker encounter", 128);
	Q_strncpyz(quest->objectives[3], "Allow Jeth to analyze the Holocron", 128);
	Q_strncpyz(quest->objectives[4], "Learn the truth about what's trapped inside", 128);
	quest->objectiveCount = 5;

	// Initialize objective completion
	for (int i = 0; i < quest->objectiveCount; i++) {
		quest->objectiveComplete[i] = qfalse;
	}

	// Rewards
	quest->xpReward = 800;
	quest->creditReward = 0;  // No credits - this quest rewards KNOWLEDGE (and horror)
	quest->alignmentChange = 0;  // Depends on player's choices
	quest->itemReward = 12;  // Encrypted Holoprojector (reveals Jedi Council conspiracy)
	quest->requiredLevel = 5;
	quest->requiredQuest = 4;  // Requires Act 1 complete

	// Quest 16: The Mimic (Act 2 Side Quest - Investigative Horror)
	quest = &game->quests[game->questCount++];
	quest->id = 16;
	Q_strncpyz(quest->name, "^5The Mimic^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Doctor Venn's patient was attacked by something wearing YOUR face. Security footage shows "
		"a figure matching your description committing brutal murders across the city. "
		"But you have no memory of these events. Are you being framed? Or is the Holocron "
		"controlling you during blackouts? You must find the truth before the guards arrest you.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;

	// Objectives
	Q_strncpyz(quest->objectives[0], "Speak with Doctor Venn at the Medical Clinic (Room 34)", 128);
	Q_strncpyz(quest->objectives[1], "Investigate the murder scene in the Dark Alley (Room 29)", 128);
	Q_strncpyz(quest->objectives[2], "Talk to the Witness (Mira Tovan) - Persuade or Intimidate", 128);
	Q_strncpyz(quest->objectives[3], "Access security footage at the checkpoint (Room 31)", 128);
	Q_strncpyz(quest->objectives[4], "Confront the truth: Is it you, or something else?", 128);
	quest->objectiveCount = 5;

	// Initialize objective completion
	for (int i = 0; i < quest->objectiveCount; i++) {
		quest->objectiveComplete[i] = qfalse;
	}

	// Rewards
	quest->xpReward = 600;
	quest->creditReward = 0;
	quest->alignmentChange = 0;  // Discovering the truth is its own reward (and curse)
	quest->itemReward = 9;  // Security Badge (evidence + cipher digits)
	quest->requiredLevel = 5;
	quest->requiredQuest = -1;  // Can be done independently

	// =============================================================================
	// ACT 3 QUESTS (Dxun Tomb - Isolation Horror)
	// =============================================================================

	// Quest 17: Escape the Loop (Act 3 Main Quest)
	quest = &game->quests[game->questCount++];
	quest->id = 17;
	Q_strncpyz(quest->name, "^5Escape the Loop^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The tomb's corridors don't follow normal geometry. You're trapped in an impossible loop. "
		"The Shadow Self claims it's been guiding you for days, but you only arrived hours ago. "
		"Time is broken. Space is broken. You need to break the loop and reach the Inner Sanctum "
		"before you forget who you are entirely.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;

	// Objectives
	Q_strncpyz(quest->objectives[0], "Navigate the non-Euclidean tomb corridors", 128);
	Q_strncpyz(quest->objectives[1], "Achieve Wisdom 14+ to perceive the true path", 128);
	Q_strncpyz(quest->objectives[2], "Reach the Research Laboratory (Room 41)", 128);
	Q_strncpyz(quest->objectives[3], "Unlock the sealed door to the Inner Sanctum", 128);
	Q_strncpyz(quest->objectives[4], "Confront the Shadow Self", 128);
	quest->objectiveCount = 5;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;

	// Rewards
	quest->xpReward = 1000;
	quest->creditReward = 0;
	quest->alignmentChange = 0;  // Depends on Shadow Self boss outcome
	quest->itemReward = 14;  // Shadow Self's Journal
	quest->requiredLevel = 7;
	quest->requiredQuest = 15;  // Requires Act 2 complete

	// Quest 18: The Shadow's Truth (Act 3 Side Quest)
	quest = &game->quests[game->questCount++];
	quest->id = 18;
	Q_strncpyz(quest->name, "^0The Shadow's Truth^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The Shadow Self keeps claiming it's the 'real' you. It knows things you don't remember. "
		"It has memories you've lost. What if it's telling the truth? What if YOU are the shadow? "
		"Investigate the research lab logs to discover which one of you is the original.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;

	// Objectives
	Q_strncpyz(quest->objectives[0], "Find the Stasis Pod Datalog in the lab (Room 41)", 128);
	Q_strncpyz(quest->objectives[1], "Read the journal entries that match your handwriting", 128);
	Q_strncpyz(quest->objectives[2], "Compare your memories with the Shadow's claims", 128);
	Q_strncpyz(quest->objectives[3], "Accept or deny the Shadow's truth", 128);
	quest->objectiveCount = 4;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;

	// Rewards
	quest->xpReward = 800;
	quest->creditReward = 0;
	quest->alignmentChange = 0;
	quest->itemReward = 15;  // Stasis Pod Log
	quest->requiredLevel = 7;
	quest->requiredQuest = -1;

	// Quest 19: Forgotten Memories (Act 3 Side Quest - Memory Erasure Horror)
	quest = &game->quests[game->questCount++];
	quest->id = 19;
	Q_strncpyz(quest->name, "^8Forgotten Memories^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"Your quest log is changing. Completed quests are disappearing. Items in your inventory "
		"are things you don't remember finding. The Holocron is erasing your past. "
		"Can you recover what's been lost before you forget everything?",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;

	// Objectives
	Q_strncpyz(quest->objectives[0], "Notice the missing quest entries in your journal", 128);
	Q_strncpyz(quest->objectives[1], "Find evidence of erased memories in the tomb", 128);
	Q_strncpyz(quest->objectives[2], "Use the Eternal Candle to recover lost knowledge (risky)", 128);
	Q_strncpyz(quest->objectives[3], "Decide: Keep your fading memories or embrace forgetting", 128);
	quest->objectiveCount = 4;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;

	// Rewards
	quest->xpReward = 600;
	quest->creditReward = 0;
	quest->alignmentChange = -5;  // Using the candle is Dark Side
	quest->itemReward = 16;  // Eternal Sith Candle
	quest->requiredLevel = 7;
	quest->requiredQuest = -1;

	// =============================================================================
	// ACT 4 QUESTS (Fragmentation & Fourth Wall Horror)
	// =============================================================================

	// Quest 20: Reassemble the Self (Act 4 Main Quest)
	quest = &game->quests[game->questCount++];
	quest->id = 20;
	Q_strncpyz(quest->name, "^8Reassemble the Self^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The Holocron has shattered your psyche into fragments. Rage. Fear. Despair. "
		"Each piece has manifested as a physical enemy in the void. You must defeat all three "
		"fragments to become whole again - or what's left of whole. The stat vampire attacks make "
		"each fight harder than the last. Can you survive fighting yourself?",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;
	Q_strncpyz(quest->objectives[0], "Defeat your RAGE (Fragment Boss 14)", 128);
	Q_strncpyz(quest->objectives[1], "Defeat your FEAR (Fragment Boss 15) - beware stat drain", 128);
	Q_strncpyz(quest->objectives[2], "Defeat your DESPAIR (Fragment Boss 16)", 128);
	Q_strncpyz(quest->objectives[3], "Survive the Fourth Wall break", 128);
	quest->objectiveCount = 4;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 1500;
	quest->creditReward = 0;
	quest->alignmentChange = 0;
	quest->itemReward = 22;  // Memory: The Choice
	quest->requiredLevel = 9;
	quest->requiredQuest = 17;  // Requires Act 3 complete

	// Quest 21: Echoes of Metacognition (Act 4 Side Quest - Fourth Wall)
	quest = &game->quests[game->questCount++];
	quest->id = 21;
	Q_strncpyz(quest->name, "^2Echoes of Metacognition^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The Holocron revealed the truth: you're in a game. A text adventure. Your choices are code. "
		"Your suffering is a story. This knowledge breaks something fundamental in your mind. "
		"Do you accept this truth? Or fight to preserve the illusion of free will?",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qfalse;
	Q_strncpyz(quest->objectives[0], "Reach Room 47 (The Fourth Wall)", 128);
	Q_strncpyz(quest->objectives[1], "Read the meta-horror revelation", 128);
	Q_strncpyz(quest->objectives[2], "Choose: Accept you're in a game, or deny it", 128);
	quest->objectiveCount = 3;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 1000;
	quest->creditReward = 0;
	quest->alignmentChange = 0;  // Beyond alignment - this is existential
	quest->itemReward = -1;
	quest->requiredLevel = 9;
	quest->requiredQuest = -1;

	// =============================================================================
	// ACT 5 QUEST (The Final Choice)
	// =============================================================================

	// Quest 22: Echoes of the Dark Wars (Act 5 - Final Quest)
	quest = &game->quests[game->questCount++];
	quest->id = 22;
	Q_strncpyz(quest->name, "^5Echoes of the Dark Wars^7", sizeof(quest->name));
	Q_strncpyz(quest->description,
		"The journey ends where it began - Dantooine. The Enclave sublevels hold the final secret. "
		"The cipher code. The four paths. Your fate is in your hands. "
		"Will you sacrifice yourself for the Light? Embrace the Dark? Succumb to Horror? "
		"Or discover the hidden Truth? Every choice you made led to this moment.",
		sizeof(quest->description));
	quest->state = QUEST_INACTIVE;
	quest->isMainQuest = qtrue;
	Q_strncpyz(quest->objectives[0], "Return to Dantooine's Jedi Enclave", 128);
	Q_strncpyz(quest->objectives[1], "Enter the hidden sublevels (Room 48)", 128);
	Q_strncpyz(quest->objectives[2], "Solve the cipher puzzle (9 digits) for Truth path", 128);
	Q_strncpyz(quest->objectives[3], "Choose your ending in the Chamber of Final Choice", 128);
	quest->objectiveCount = 4;
	for (int i = 0; i < quest->objectiveCount; i++) quest->objectiveComplete[i] = qfalse;
	quest->xpReward = 2000;
	quest->creditReward = 0;
	quest->alignmentChange = 0;  // Depends on ending chosen
	quest->itemReward = -1;
	quest->requiredLevel = 10;
	quest->requiredQuest = 20;  // Requires Act 4 complete

	// =============================================================================
	// ENEMIES
	// =============================================================================

	// Enemy 0: Kinrath (common)
	rpgEnemy_t *enemy = &game->enemies[game->enemyCount++];
	enemy->id = 0;
	Q_strncpyz(enemy->name, "Kinrath", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A large, aggressive arachnid native to Dantooine. Its poisonous bite and quick reflexes "
		"make it a dangerous opponent.",
		sizeof(enemy->description));
	enemy->level = 2;
	enemy->hp = 60;
	enemy->damage = 15;
	enemy->defense = 5;
	enemy->xpReward = 50;
	enemy->creditReward = 25;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 30;

	// Enemy 1: Kinrath Matriarch (boss)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 1;
	Q_strncpyz(enemy->name, "^3Kinrath Matriarch^7", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A massive kinrath matriarch. Twice the size of a normal kinrath, with thicker chitin armor "
		"and deadly venom. Pack leader.",
		sizeof(enemy->description));
	enemy->level = 4;
	enemy->hp = 120;
	enemy->damage = 25;
	enemy->defense = 10;
	enemy->xpReward = 150;
	enemy->creditReward = 75;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 50;
	enemy->lootItems[1] = 5;  // Green crystal
	enemy->lootChance[1] = 20;

	// Enemy 2: Exchange Thug
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 2;
	Q_strncpyz(enemy->name, "Exchange Thug", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A brutish melee fighter working for the Exchange crime syndicate. "
		"Armed with a vibroblade and little conscience.",
		sizeof(enemy->description));
	enemy->level = 3;
	enemy->hp = 70;
	enemy->damage = 18;
	enemy->defense = 8;
	enemy->xpReward = 60;
	enemy->creditReward = 50;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 25;

	// Enemy 3: Exchange Enforcer
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 3;
	Q_strncpyz(enemy->name, "Exchange Enforcer", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A professional soldier working for the Exchange. Uses a blaster rifle and tactical training.",
		sizeof(enemy->description));
	enemy->level = 4;
	enemy->hp = 80;
	enemy->damage = 22;
	enemy->defense = 10;
	enemy->xpReward = 80;
	enemy->creditReward = 75;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 30;

	// Enemy 4: Exchange Lieutenant (Boss)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 4;
	Q_strncpyz(enemy->name, "^3Exchange Lieutenant Ganz^7", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A cunning Exchange officer with dual blaster pistols. "
		"He leads the operation to acquire the Sith Holocron.",
		sizeof(enemy->description));
	enemy->level = 5;
	enemy->hp = 140;
	enemy->damage = 28;
	enemy->defense = 12;
	enemy->xpReward = 200;
	enemy->creditReward = 200;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 50;

	// Enemy 5: Sith Assassin
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 5;
	Q_strncpyz(enemy->name, "^1Sith Assassin^7", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A dark side adept trained in stealth and murder. Uses Force powers and a red lightsaber.",
		sizeof(enemy->description));
	enemy->level = 6;
	enemy->hp = 100;
	enemy->damage = 30;
	enemy->defense = 15;
	enemy->xpReward = 250;
	enemy->creditReward = 100;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 40;

	// Enemy 6: Corrupted Kinrath
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 6;
	Q_strncpyz(enemy->name, "^5Corrupted Kinrath^7", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A kinrath twisted by dark side energy from the Holocron. "
		"Larger and more aggressive than normal, with unnatural purple chitin.",
		sizeof(enemy->description));
	enemy->level = 5;
	enemy->hp = 90;
	enemy->damage = 26;
	enemy->defense = 8;
	enemy->xpReward = 100;
	enemy->creditReward = 0;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 35;

	// Enemy 7: Salvage Droid
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 7;
	Q_strncpyz(enemy->name, "Hostile Salvage Droid", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"An old Republic mining droid that's malfunctioned. "
		"Its mining laser and crushing claws make it dangerous.",
		sizeof(enemy->description));
	enemy->level = 3;
	enemy->hp = 100;
	enemy->damage = 20;
	enemy->defense = 20;  // High armor
	enemy->xpReward = 70;
	enemy->creditReward = 100;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 20;

	// Enemy 8: Mercenary
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 8;
	Q_strncpyz(enemy->name, "Mercenary", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A professional gun-for-hire. Well-equipped and experienced in combat.",
		sizeof(enemy->description));
	enemy->level = 4;
	enemy->hp = 85;
	enemy->damage = 24;
	enemy->defense = 12;
	enemy->xpReward = 85;
	enemy->creditReward = 80;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 30;

	// Enemy 9: Dark Jedi (Final Boss)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 9;
	Q_strncpyz(enemy->name, "^1Dark Jedi Sevrath^7", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A fallen Jedi turned Sith Lord. Master of the dark side and seeker of the Holocron. "
		"Wields a crimson lightsaber and commands devastating Force powers.",
		sizeof(enemy->description));
	enemy->level = 8;
	enemy->hp = 200;
	enemy->damage = 35;
	enemy->defense = 18;
	enemy->xpReward = 500;
	enemy->creditReward = 500;
	enemy->lootItems[0] = 4;  // Broken lightsaber (his, can be repaired)
	enemy->lootChance[0] = 100;

	// Enemy 10: Kinrath Hatchling (weak swarm)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 10;
	Q_strncpyz(enemy->name, "Kinrath Hatchling", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A juvenile kinrath. Weak individually but dangerous in groups.",
		sizeof(enemy->description));
	enemy->level = 1;
	enemy->hp = 30;
	enemy->damage = 10;
	enemy->defense = 2;
	enemy->xpReward = 20;
	enemy->creditReward = 10;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 15;

	// Enemy 11: Laigrek (cave predator)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 11;
	Q_strncpyz(enemy->name, "Laigrek", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"A cave-dwelling predator native to Dantooine. Fast and venomous.",
		sizeof(enemy->description));
	enemy->level = 3;
	enemy->hp = 55;
	enemy->damage = 16;
	enemy->defense = 6;
	enemy->xpReward = 45;
	enemy->creditReward = 20;
	enemy->lootItems[0] = 3;  // Medpac
	enemy->lootChance[0] = 25;

	// =============================================================================
	// ACT 2-4 BOSS ENEMIES
	// =============================================================================

	// Enemy 12: The Stalker (Jedi Shadow - Resurrected)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 12;
	Q_strncpyz(enemy->name, "The Stalker (Jedi Shadow)", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"The Jedi Shadow from the crash. Dead. But the Holocron resurrected them. "
		"Glowing purple eyes. Tattered robes. They hunt you through Iziz. Unkillable. You can only survive.",
		sizeof(enemy->description));
	enemy->level = 8;
	enemy->hp = 9999;  // Unkillable - survival fight (5 turns)
	enemy->damage = 20;
	enemy->defense = 10;
	enemy->xpReward = 500;  // For surviving
	enemy->creditReward = 0;

	// Enemy 13: Shadow Self (Your Dark Reflection)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 13;
	Q_strncpyz(enemy->name, "Shadow Self", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"Your perfect mirror. Every skill you have, they have. Every weakness, they exploit. "
		"They claim to be the REAL you. Defeating them means accepting you're both fragments.",
		sizeof(enemy->description));
	enemy->level = 9;
	enemy->hp = 200;
	enemy->damage = 25;
	enemy->defense = 12;
	enemy->xpReward = 1000;
	enemy->creditReward = 0;

	// Enemy 14: Fragment of RAGE (Stat Vampire - STRENGTH)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 14;
	Q_strncpyz(enemy->name, "Fragment: YOUR RAGE", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"Every moment of anger crystallized. When it strikes, it drains STRENGTH permanently.",
		sizeof(enemy->description));
	enemy->level = 10;
	enemy->hp = 150;
	enemy->damage = 20;  // Stat vampire mechanic
	enemy->defense = 15;
	enemy->xpReward = 800;
	enemy->creditReward = 0;

	// Enemy 15: Fragment of FEAR (Stat Vampire - WISDOM)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 15;
	Q_strncpyz(enemy->name, "Fragment: YOUR FEAR", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"Every terror suppressed. Trembling. It drains your WISDOM with each hit.",
		sizeof(enemy->description));
	enemy->level = 10;
	enemy->hp = 180;
	enemy->damage = 18;  // Drains WISDOM
	enemy->defense = 12;
	enemy->xpReward = 900;
	enemy->creditReward = 0;

	// Enemy 16: Fragment of DESPAIR (Stat Vampire - CHARISMA)
	enemy = &game->enemies[game->enemyCount++];
	enemy->id = 16;
	Q_strncpyz(enemy->name, "Fragment: YOUR DESPAIR", sizeof(enemy->name));
	Q_strncpyz(enemy->description,
		"The part that gave up. Hollow. It drains CHARISMA - your sense of self.",
		sizeof(enemy->description));
	enemy->level = 10;
	enemy->hp = 200;
	enemy->damage = 22;  // Drains CHARISMA
	enemy->defense = 14;
	enemy->xpReward = 1000;
	enemy->creditReward = 0;
}

// =============================================================================
// SAVE/LOAD UTILITY FUNCTIONS
// =============================================================================

/*
================
G_RPG_SanitizeString
Sanitize strings for safe use in SendServerCommand by replacing quotes
Returns a static buffer (not thread-safe, but game logic is single-threaded)
================
*/
static const char *G_RPG_SanitizeString(const char *input) {
	static char sanitized[RPG_MAX_DISPLAY];
	int i, j;

	if (!input) return "";

	j = 0;
	for (i = 0; input[i] && j < sizeof(sanitized) - 1; i++) {
		if (input[i] == '"') {
			sanitized[j++] = '\'';  // Replace " with '
		} else {
			sanitized[j++] = input[i];
		}
	}
	sanitized[j] = '\0';

	return sanitized;
}

/*
================
G_RPG_GetThemeColor
Returns color code based on player's alignment and corruption level
Used to color UI framework (headers, borders, prompts) - NOT content text
================
*/
static const char *G_RPG_GetThemeColor(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;

	// =============================================================================
	// CORRUPTION PULSE - Flashing UI when heavily corrupted
	// =============================================================================
	// If heavily corrupted, toggle between Red and Cyan (heartbeat effect)
	if (p->hasHolocron && p->paranoiaLevel > 30) {
		if (game->corruptionColorState == 0) {
			return "^1";  // Red
		} else {
			return "^5";  // Cyan/Purple
		}
	}

	// =============================================================================
	// STATIC COLORS - Normal theme based on alignment/corruption
	// =============================================================================

	// Extreme corruption (both Dark Side + Holocron possession)
	if (p->alignment <= -70 && p->hasHolocron) {
		return "^5";  // Purple (deep Sith corruption)
	}

	// Extreme Dark Side
	if (p->alignment <= -50) {
		return "^1";  // Red (Sith)
	}

	// Moderate Dark Side
	if (p->alignment <= -20) {
		return "^3";  // Yellow (conflict/warning)
	}

	// Holocron corruption (even if alignment is neutral)
	if (p->hasHolocron) {
		return "^6";  // Cyan (artifact influence)
	}

	// Light Side
	if (p->alignment >= 30) {
		return "^2";  // Green (Jedi)
	}

	// Neutral/Balanced
	return "^7";  // White (balanced Force user)
}

/*
================
G_RPG_AddDoubtOption
Helper for Act 2 Doubt system - adds dialogue choices with hidden Dark Side influence
High Wisdom (≥14) reveals the truth, otherwise shows "safe" lie
================
*/
static void G_RPG_AddDoubtOption(rpgDialogue_t *dlg, rpgPlayer_t *p,
                                  const char *safeText, const char *truthText,
                                  int nextNode, int alignmentChange) {
	int idx = dlg->choiceCount;

	// High Wisdom sees through Holocron's manipulation
	if (p->stats[STAT_WISDOM] >= 14) {
		Com_sprintf(dlg->choiceText[idx], 128, "^1[TRUTH] %s^7", truthText);
	} else {
		// Everyone else sees the "safe" option with subtle warning
		Com_sprintf(dlg->choiceText[idx], 128, "%s ^3(Holocron Influence)^7", safeText);
	}

	dlg->choiceType[idx] = DIALOGUE_DARK;
	dlg->choiceNextNode[idx] = nextNode;
	dlg->choiceAlignmentChange[idx] = alignmentChange;
	dlg->choiceRequiredStat[idx] = -1;
	dlg->choiceCount++;
}

/*
================
G_RPG_SaveGame
Serialize player state to cvars for persistence
Uses player GUID (not entity ID) to prevent save data collision
================
*/
void G_RPG_SaveGame(gentity_t *player) {
	if (!player || !player->client) {
		return;
	}

	// Use player GUID instead of entity ID to prevent save collision
	const char *guid = player->client->pers.guid;
	if (!guid || !guid[0]) {
		trap->SendServerCommand(player->s.number, "print \"^1[SAVE FAILED] No player GUID available^7\n\"");
		return;
	}

	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;

	// Save core player data using GUID as key
	trap->Cvar_Set(va("rpg_save_level_%s", guid), va("%d", p->level));
	trap->Cvar_Set(va("rpg_save_xp_%s", guid), va("%d", p->xp));
	trap->Cvar_Set(va("rpg_save_hp_%s", guid), va("%d", p->hp));
	trap->Cvar_Set(va("rpg_save_fp_%s", guid), va("%d", p->fp));
	trap->Cvar_Set(va("rpg_save_alignment_%s", guid), va("%d", p->alignment));
	trap->Cvar_Set(va("rpg_save_credits_%s", guid), va("%d", p->credits));
	trap->Cvar_Set(va("rpg_save_room_%s", guid), va("%d", p->currentRoom));
	trap->Cvar_Set(va("rpg_save_class_%s", guid), va("%d", p->class));

	// Save stats as compact string
	char statsStr[128];
	Com_sprintf(statsStr, sizeof(statsStr), "%d,%d,%d,%d,%d,%d",
		p->stats[0], p->stats[1], p->stats[2], p->stats[3], p->stats[4], p->stats[5]);
	trap->Cvar_Set(va("rpg_save_stats_%s", guid), statsStr);

	// Save inventory count and first 15 items
	trap->Cvar_Set(va("rpg_save_invcount_%s", guid), va("%d", p->inventoryCount));
	char invStr[256] = "";
	for (int i = 0; i < p->inventoryCount && i < 15; i++) {
		char buf[16];
		Com_sprintf(buf, sizeof(buf), "%d%s", p->inventory[i], i < p->inventoryCount - 1 ? "," : "");
		Q_strcat(invStr, sizeof(invStr), buf);
	}
	if (invStr[0]) trap->Cvar_Set(va("rpg_save_inv_%s", guid), invStr);

	// Save quest states (bitpacked: first 15 quests)
	int questBits = 0;
	for (int i = 0; i < 15 && i < game->questCount; i++) {
		if (game->quests[i].state == QUEST_ACTIVE) questBits |= (1 << i);
		else if (game->quests[i].state == QUEST_COMPLETED) questBits |= (1 << (i + 15));
	}
	trap->Cvar_Set(va("rpg_save_quests_%s", guid), va("%d", questBits));

	// Save companions
	char compStr[64] = "";
	for (int i = 0; i < p->companionCount && i < 5; i++) {
		char buf[16];
		Com_sprintf(buf, sizeof(buf), "%d%s", p->companionIDs[i], i < p->companionCount - 1 ? "," : "");
		Q_strcat(compStr, sizeof(compStr), buf);
	}
	if (compStr[0]) trap->Cvar_Set(va("rpg_save_comp_%s", guid), compStr);
	trap->Cvar_Set(va("rpg_save_activecomp_%s", guid), va("%d", p->activeCompanion));

	// Save paranoia/horror state
	trap->Cvar_Set(va("rpg_save_paranoia_%s", guid), va("%d", p->paranoiaLevel));
	trap->Cvar_Set(va("rpg_save_holocron_%s", guid), p->hasHolocron ? "1" : "0");

	// Mark save as valid
	trap->Cvar_Set(va("rpg_save_valid_%s", guid), "1");

	trap->SendServerCommand(player->s.number, "print \"^2[GAME SAVED]^7\n\"");
}

/*
================
G_RPG_LoadGame
Restore player state from cvars using player GUID
Returns qtrue if load successful
================
*/
qboolean G_RPG_LoadGame(gentity_t *player) {
	if (!player || !player->client) return qfalse;

	// Get player GUID
	const char *guid = player->client->pers.guid;
	if (!guid || !guid[0]) {
		trap->SendServerCommand(player->s.number, "print \"^1[LOAD FAILED] No player GUID available^7\n\"");
		return qfalse;
	}

	char buf[1024];

	// Check if save exists for this GUID
	trap->Cvar_VariableStringBuffer(va("rpg_save_valid_%s", guid), buf, sizeof(buf));
	if (!buf[0] || atoi(buf) != 1) {
		trap->SendServerCommand(player->s.number, "print \"^1No save game found! Start a new game with /rpg^7\n\"");
		return qfalse;
	}

	rpgGame_t *game = &player->client->rpg;

	// Initialize world first
	memset(game, 0, sizeof(rpgGame_t));
	G_RPG_InitWorld(game);

	rpgPlayer_t *p = &game->player;

	// Load core stats using GUID
	trap->Cvar_VariableStringBuffer(va("rpg_save_level_%s", guid), buf, sizeof(buf));
	p->level = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_xp_%s", guid), buf, sizeof(buf));
	p->xp = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_hp_%s", guid), buf, sizeof(buf));
	p->hp = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_fp_%s", guid), buf, sizeof(buf));
	p->fp = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_alignment_%s", guid), buf, sizeof(buf));
	p->alignment = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_credits_%s", guid), buf, sizeof(buf));
	p->credits = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_room_%s", guid), buf, sizeof(buf));
	p->currentRoom = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_class_%s", guid), buf, sizeof(buf));
	p->class = atoi(buf);

	// Load stats
	trap->Cvar_VariableStringBuffer(va("rpg_save_stats_%s", guid), buf, sizeof(buf));
	sscanf(buf, "%d,%d,%d,%d,%d,%d", &p->stats[0], &p->stats[1], &p->stats[2], &p->stats[3], &p->stats[4], &p->stats[5]);

	// Recalculate derived stats
	p->maxHP = 50 + (p->stats[STAT_CONSTITUTION] * 5) + (p->level * 10);
	p->maxFP = 50 + (p->stats[STAT_WISDOM] * 5) + (p->level * 5);
	p->xpToNext = 100 * p->level;

	// Load inventory
	trap->Cvar_VariableStringBuffer(va("rpg_save_invcount_%s", guid), buf, sizeof(buf));
	p->inventoryCount = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_inv_%s", guid), buf, sizeof(buf));
	char *token = strtok(buf, ",");
	int idx = 0;
	while (token && idx < p->inventoryCount) {
		p->inventory[idx++] = atoi(token);
		token = strtok(NULL, ",");
	}

	// Load quests
	trap->Cvar_VariableStringBuffer(va("rpg_save_quests_%s", guid), buf, sizeof(buf));
	int questBits = atoi(buf);
	for (int i = 0; i < 15 && i < game->questCount; i++) {
		if (questBits & (1 << (i + 15))) game->quests[i].state = QUEST_COMPLETED;
		else if (questBits & (1 << i)) game->quests[i].state = QUEST_ACTIVE;
	}

	// Load companions
	trap->Cvar_VariableStringBuffer(va("rpg_save_comp_%s", guid), buf, sizeof(buf));
	token = strtok(buf, ",");
	p->companionCount = 0;
	while (token && p->companionCount < MAX_RPG_COMPANIONS) {
		p->companionIDs[p->companionCount++] = atoi(token);
		token = strtok(NULL, ",");
	}

	trap->Cvar_VariableStringBuffer(va("rpg_save_activecomp_%s", guid), buf, sizeof(buf));
	p->activeCompanion = atoi(buf);

	// Load paranoia/horror state
	trap->Cvar_VariableStringBuffer(va("rpg_save_paranoia_%s", guid), buf, sizeof(buf));
	p->paranoiaLevel = atoi(buf);

	trap->Cvar_VariableStringBuffer(va("rpg_save_holocron_%s", guid), buf, sizeof(buf));
	p->hasHolocron = (atoi(buf) == 1) ? qtrue : qfalse;

	p->lastParanoiaDecay = level.time;

	// Activate game
	game->active = qtrue;
	game->state = RPG_STATE_EXPLORATION;
	game->selection = 0;

	trap->SendServerCommand(player->s.number, "print \"^2[GAME LOADED]^7 Welcome back!\n\"");
	return qtrue;
}

/*
================
G_RPG_Init
================
*/
void G_RPG_Init(gentity_t *player) {
	if (!player || !player->client) {
		return;
	}

	rpgGame_t *game = &player->client->rpg;

	trap->Print("RPG_DEBUG: G_RPG_Init called for client %d\n", player->s.number);

	// REMAP SHADER: Replace large centerprint font with small console font
	// This makes all subsequent 'cp' commands display with small, crisp text
	// 100% server-side, no client download required
	trap->SendServerCommand(player->s.number, "remapShader gfx/2d/bigchars gfx/2d/smallchars");

	// DEBUG: Log every init call
	trap->SendServerCommand(player->s.number, "print \"^5[DEBUG] G_RPG_Init START^7\n\"");

	memset(game, 0, sizeof(rpgGame_t));

	game->active = qtrue;
	game->state = RPG_STATE_DREAM;  // Start with Force vision instead of text crawl
	game->dreamSequence = 0;  // Intro dream
	game->selection = 0;
	game->numOptions = 2;

	// FIX: Initialize last input states to TRUE to prevent false edge detection
	// When player presses USE to start the game from menu, USE is still held.
	// Without this, the first frame would detect usePressed=TRUE and skip the dream.
	game->lastForward = qtrue;
	game->lastBackward = qtrue;
	game->lastLeft = qtrue;
	game->lastRight = qtrue;
	game->lastUse = qtrue;
	game->lastAttack = qtrue;
	game->lastAltAttack = qtrue;
	game->lastJump = qtrue;
	trap->Print("RPG_DEBUG: lastUse=%d lastJump=%d (should be 1)\n", game->lastUse, game->lastJump);

	// Initialize paranoia tracking
	game->player.paranoiaLevel = 0;
	game->player.hasHolocron = qfalse;
	game->player.lastParanoiaDecay = level.time;

	// Initialize Act progression
	game->currentAct = 1;  // Start in Act 1: The Awakening

	// Initialize narrative tracking (prevents spam)
	game->lastNarrativeState = -1;  // Force initial narrative to show
	game->lastNarrativeDream = -1;

	// Initialize Act 2 Stalker system (will activate when currentAct = 2)
	game->player.stalkerStage = 0;
	game->player.stalkerTimer = 300;  // 5 minutes to first stage
	game->player.stalkerCheckTime = level.time + 1000;

	// Initialize lore tracking (for Truth ending in Act 5)
	for (int i = 0; i < MAX_RPG_ITEMS; i++) {
		game->loreDiscovered[i] = qfalse;
	}

	// Initialize world data
	G_RPG_InitWorld(game);

	// Show intro immediately (just once)
	G_RPG_RefreshDisplay(player);

	// Block ALL subsequent refreshes for 1 second to prevent corruption pulse spam
	game->lastRefreshTime = level.time + 1000;
}

/*
================
G_RPG_Shutdown
================
*/
void G_RPG_Shutdown(gentity_t *player) {
	if (!player || !player->client) {
		return;
	}

	rpgGame_t *game = &player->client->rpg;

	// Clean up combat state if active
	if (game->combat.active) {
		game->combat.active = qfalse;
		game->combat.playerTurn = qfalse;
		game->combat.enemyStunned = qfalse;
		game->combat.playerDefending = qfalse;
	}

	// Clean up dialogue state if active
	if (game->dialogue.active) {
		game->dialogue.active = qfalse;
	}

	game->active = qfalse;

	// RESET SHADER: Restore original bigchars font when exiting RPG
	trap->SendServerCommand(player->s.number, "remapShader gfx/2d/bigchars gfx/2d/bigchars");

	// UNFREEZE player physics when exiting RPG
	if (player->client->ps.pm_type == PM_FREEZE) {
		player->client->ps.pm_type = PM_NORMAL;
	}
}

// =============================================================================
// GAME LOOP
// =============================================================================

/*
================
G_RPG_Think
Main game loop
================
*/
void G_RPG_Think(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;

	if (!game->active) {
		return;
	}

	// =============================================================================
	// FIX: FROZEN STATE ENFORCEMENT (ACT 3 fake reboot and other freezes)
	// =============================================================================
	// Check if frozen state has expired
	if (game->frozenUntil > 0) {
		if (level.time >= game->frozenUntil) {
			// Freeze timeout - unfreeze player
			player->client->ps.pm_type = PM_FREEZE;  // Keep frozen for RPG (ProcessInput sets this)
			game->frozenUntil = 0;
			G_RPG_RefreshDisplay(player);
		} else {
			// Still frozen - enforce PM_FREEZE
			player->client->ps.pm_type = PM_FREEZE;
		}
	}

	// Safety: Prevent infinite freeze (15 second maximum)
	if (game->frozenUntil > 0 && (game->frozenUntil - level.time) > 15000) {
		game->frozenUntil = level.time + 3000;  // Cap at 3 seconds
	}

	// Paranoia decay - naturally calms down over time if not holding Holocron
	if (level.time - p->lastParanoiaDecay > PARANOIA_DECAY_INTERVAL) {
		if (p->paranoiaLevel > 0 && !p->hasHolocron) {
			p->paranoiaLevel--;
		}
		p->lastParanoiaDecay = level.time;
	}

	// =============================================================================
	// CORRUPTION PULSE - UI "Heartbeat" effect
	// =============================================================================
	// Only pulse if corrupted (has Holocron or high paranoia)
	if (p->hasHolocron || p->paranoiaLevel > 20) {
		// Pulse speed increases with paranoia (heartbeat gets faster)
		int pulseSpeed = 1000 - (p->paranoiaLevel * 8);
		if (pulseSpeed < 200) {
			pulseSpeed = 200;  // Cap at 5Hz max (safe for network)
		}

		if (level.time >= game->corruptionPulseTimer) {
			// Toggle color state (0 -> 1 -> 0 ...)
			game->corruptionColorState = !game->corruptionColorState;
			game->corruptionPulseTimer = level.time + pulseSpeed;

			// Force display refresh to show new color
			G_RPG_RefreshDisplay(player);
			game->lastRefreshTime = level.time;  // Reset normal refresh timer
		}
	}

	// =============================================================================
	// ACT 2 EVENTS - The Masquerade
	// =============================================================================
	if (game->currentAct == 2) {
		// STALKER TIMER - Decrements every second
		if (level.time > p->stalkerCheckTime) {
			p->stalkerTimer--;
			p->stalkerCheckTime = level.time + 1000;

			// Stage progression based on timer
			if (p->stalkerTimer <= 0) {
				p->stalkerStage++;
				p->stalkerTimer = 300;  // Reset for next stage (5 minutes)

				// Trigger ambient messages
				if (p->stalkerStage == 1) {
					trap->SendServerCommand(player->s.number,
						"print \"^0[You feel a cold breath on your neck...]^7\n\"");
				} else if (p->stalkerStage == 2) {
					trap->SendServerCommand(player->s.number,
						"print \"^0[The crowd parts. Someone is watching you.]^7\n\"");
				} else if (p->stalkerStage >= 3) {
					// FORCED COMBAT with Jedi Shadow Stalker
					trap->SendServerCommand(player->s.number,
						"print \"^1[A figure in tattered robes steps from the shadows.]^7\n\n\"");
					G_RPG_StartCombat(player, 12);  // Enemy ID 12 = Stalker
					p->stalkerStage = 0;  // Reset after encounter
				}
			}
		}

		// INFECTED INVENTORY - Holocron moves itself
		if (game->state == RPG_STATE_EXPLORATION && p->hasHolocron) {
			// 1% chance per 10 seconds
			if (rand() % 100 < 1 && (level.time - game->lastInventoryShift > 10000)) {
				int holocronSlot = -1;

				// Find Holocron in inventory
				for (int i = 0; i < p->inventoryCount; i++) {
					if (p->inventory[i] == 2) {  // Item ID 2 = Sith Holocron
						holocronSlot = i;
						break;
					}
				}

				// Force it to slot 0 (top of inventory)
				if (holocronSlot > 0) {
					int temp = p->inventory[0];
					p->inventory[0] = p->inventory[holocronSlot];
					p->inventory[holocronSlot] = temp;

					trap->SendServerCommand(player->s.number,
						"print \"^1[SYSTEM WARNING] Unauthorized equipment change detected.^7\n\"");

					game->lastInventoryShift = level.time;
				}
			}
		}
	}

	// =============================================================================
	// ACT 4: GLITCH BURST LOOP (Fragment Psychic Attacks)
	// =============================================================================
	if (game->state == RPG_STATE_GLITCH_BURST) {
		// Check if glitch is over
		if (level.time > game->glitchEndTime) {
			// SNAP BACK to reality
			game->state = game->stateBeforeGlitch;
			G_RPG_RefreshDisplay(player);  // Restore original menu
			return;
		}

		// Update visuals every 100ms (10 FPS = flickering effect)
		if (level.time > game->glitchNextFrameTime) {
			G_RPG_ShowGlitchScreen(player);
			game->glitchNextFrameTime = level.time + 100;
		}

		return;  // Stop processing other logic during glitch
	}

	// =============================================================================
	// ACT 4: FOURTH WALL BREAK (One-Time Event at Paranoia 90)
	// =============================================================================
	if (game->currentAct == 4 && p->paranoiaLevel >= 90 && !game->fourthWallBroken) {
		game->fourthWallBroken = qtrue;

		// Clear screen with spam
		for (int i = 0; i < 20; i++) {
			trap->SendServerCommand(player->s.number, "print \"\n\"");
		}

		// Address the PLAYER by their netname, not the character
		trap->SendServerCommand(player->s.number,
			va("cp \"^1WAKE UP, %s.\"", player->client->pers.netname));

		trap->SendServerCommand(player->s.number,
			"print \"^1[SYSTEM MESSAGE]: Simulation unstable. Subject consciousness is rejecting the scenario.\n"
			"Increasing sedation levels...\n"
			"Rebooting...^7\n\n\"");

		// Freeze player temporarily (3 seconds)
		player->client->ps.pm_type = PM_FREEZE;
		game->frozenUntil = level.time + 3000;

		// Play static sound effect (reboot illusion)
		G_Sound(player, CHAN_AUTO, G_SoundIndex("sound/movers/switches/switch2.wav"));

		// Increase paranoia further - knowing you're in a game is worse
		G_RPG_ModifyParanoia(p, 10);
	}

	// Periodic refresh to prevent centerprint fade (every 2 seconds)
	// centerprint messages fade after ~3 seconds, so we refresh every 2s to keep display solid
	if (level.time - game->lastRefreshTime > 2000) {
		G_RPG_RefreshDisplay(player);
		game->lastRefreshTime = level.time;
	}

	// State-specific think
	switch (game->state) {
		case RPG_STATE_COMBAT:
			// Combat AI (enemy turn)
			if (!game->combat.playerTurn && game->combat.active) {
				G_RPG_EnemyTurn(player, game);
			}
			break;

		default:
			break;
	}
}

/*
================
G_RPG_ProcessInput
================
*/
void G_RPG_ProcessInput(gentity_t *player, usercmd_t *cmd) {
	rpgGame_t *game = &player->client->rpg;

	// FREEZE PHYSICS - Prevents screen shake and movement
	player->client->ps.pm_type = PM_FREEZE;

	// Detect inputs (edge-triggered) BEFORE nullifying commands
	qboolean wPressed = (cmd->forwardmove > 0) && !game->lastForward;
	qboolean sPressed = (cmd->forwardmove < 0) && !game->lastBackward;
	qboolean aPressed = (cmd->rightmove < 0) && !game->lastLeft;
	qboolean dPressed = (cmd->rightmove > 0) && !game->lastRight;
	qboolean usePressed = (cmd->buttons & BUTTON_USE) && !game->lastUse;
	qboolean attackPressed = (cmd->buttons & BUTTON_ATTACK) && !game->lastAttack;
	qboolean altAttackPressed = (cmd->buttons & BUTTON_ALT_ATTACK) && !game->lastAltAttack;
	qboolean jumpPressed = (cmd->upmove > 0) && !game->lastJump;

	// Store for next frame
	game->lastForward = (cmd->forwardmove > 0);
	game->lastBackward = (cmd->forwardmove < 0);
	game->lastLeft = (cmd->rightmove < 0);
	game->lastRight = (cmd->rightmove > 0);
	game->lastUse = (cmd->buttons & BUTTON_USE);
	game->lastAttack = (cmd->buttons & BUTTON_ATTACK);
	game->lastAltAttack = (cmd->buttons & BUTTON_ALT_ATTACK);
	game->lastJump = (cmd->upmove > 0);

	// Nullify all movement/input commands (server-side safety)
	cmd->forwardmove = 0;
	cmd->rightmove = 0;
	cmd->upmove = 0;
	cmd->buttons = 0;

	// Navigation (W/S) - FIX: Guard against numOptions <= 0
	if (wPressed && game->numOptions > 0) {
		game->selection--;
		if (game->selection < 0) {
			game->selection = game->numOptions - 1;
		}
		G_RPG_RefreshDisplay(player);
	}

	if (sPressed && game->numOptions > 0) {
		game->selection++;
		if (game->selection >= game->numOptions) {
			game->selection = 0;
		}
		G_RPG_RefreshDisplay(player);
	}

	// FIX: Ensure selection is always valid (safety net)
	if (game->numOptions <= 0) {
		game->selection = 0;
	} else if (game->selection >= game->numOptions) {
		game->selection = game->numOptions - 1;
	} else if (game->selection < 0) {
		game->selection = 0;
	}

	// Page navigation (A/D for inventory, etc.)
	if (aPressed && game->maxPages > 0) {
		game->page--;
		if (game->page < 0) {
			game->page = game->maxPages - 1;
		}
		G_RPG_RefreshDisplay(player);
	}

	if (dPressed && game->maxPages > 0) {
		game->page++;
		if (game->page >= game->maxPages) {
			game->page = 0;
		}
		G_RPG_RefreshDisplay(player);
	}

	// Confirm (USE) or JUMP (for dream sequences)
	if (usePressed || (jumpPressed && game->state == RPG_STATE_DREAM)) {
		trap->Print("RPG_DEBUG: Action triggered! usePressed=%d jumpPressed=%d state=%d\n",
			usePressed, jumpPressed, game->state);
		// State-specific handlers
		switch (game->state) {
			case RPG_STATE_INTRO:
				G_RPG_HandleIntro(player);
				break;
			case RPG_STATE_DREAM:
				trap->Print("RPG_DEBUG: Calling G_RPG_HandleDream, selection=%d\n", game->selection);
				G_RPG_HandleDream(player);
				break;
			case RPG_STATE_CLASS_SELECTION:
				G_RPG_HandleClassSelection(player);
				break;
			case RPG_STATE_EXPLORATION:
				G_RPG_HandleExploration(player);
				break;
			case RPG_STATE_COMBAT:
				G_RPG_HandleCombat(player);
				break;
			case RPG_STATE_DIALOGUE:
				G_RPG_HandleDialogue(player);
				break;
			case RPG_STATE_INVENTORY:
				G_RPG_HandleInventory(player);
				break;
			case RPG_STATE_SHOP:
				G_RPG_HandleShop(player);
				break;
			default:
				break;
		}
	}

	// Back/Cancel (ATTACK)
	if (attackPressed) {
		// Check if in movement mode
		if (game->state == RPG_STATE_EXPLORATION && game->page > 0) {
			// Cancel movement menu
			game->page = 0;
			game->selection = 0;
			G_RPG_RefreshDisplay(player);
		}
		// Go back to previous state or close game
		else if (game->state == RPG_STATE_EXPLORATION) {
			// Exit game
			G_RPG_Shutdown(player);
		} else if (game->state == RPG_STATE_INVENTORY ||
		           game->state == RPG_STATE_CHARACTER_SHEET ||
		           game->state == RPG_STATE_QUEST_LOG) {
			// Return to exploration
			game->state = RPG_STATE_EXPLORATION;
			game->selection = 0;
			G_RPG_RefreshDisplay(player);
		}
	}

	// Examine Item (ALT_ATTACK) - Only in inventory
	if (altAttackPressed && game->state == RPG_STATE_INVENTORY) {
		if (game->player.inventoryCount > 0 && game->selection < game->player.inventoryCount) {
			int itemID = game->player.inventory[game->selection];
			rpgItem_t *item = &game->items[itemID];

			// Display item lore
			if (item->lore[0] != '\0') {
				trap->SendServerCommand(player->s.number,
					va("print \"\n^6=== %s ===^7\n%s\n\n\"", item->name, item->lore));

				// Mark lore as discovered (for Truth ending tracking)
				if (itemID >= 0 && itemID < MAX_RPG_ITEMS) {
					game->loreDiscovered[itemID] = qtrue;
				}

				// Examining Dark Side items increases paranoia
				if (item->isDarkSideItem) {
					G_RPG_ModifyParanoia(&game->player, 5);

					// Ominous feedback for Dark Side items
					trap->SendServerCommand(player->s.number,
						"print \"^1[You feel a chill run down your spine...]^7\n\"");
				}
			} else {
				// No lore available
				trap->SendServerCommand(player->s.number,
					va("print \"^7%s - Nothing remarkable to note.^7\n\"", item->name));
			}
		}
	}
}

// =============================================================================
// DISPLAY FUNCTIONS
// =============================================================================

/*
================
G_RPG_RefreshDisplay

CRITICAL: Split display into two parts to avoid buffer overflow:
  - Narrative (room descriptions, dialogue) → print (console/chat, unlimited scroll)
  - Menu/HUD (options, health bars) → cp (centerprint, <500 chars, stays on screen)
================
*/

/*
================
G_RPG_ShowGlitchScreen
ACT 4: Psychotic Break - Fills screen with garbage + subliminal horror words
Used during Fragment boss psychic attacks
================
*/
void G_RPG_ShowGlitchScreen(gentity_t *player) {
	char buffer[512];
	const char *garbage = "@#$%&!?01xyz[]{}()<>";
	const char *subliminal[] = {
		"^1KILL^7", "^1GIVE IN^7", "^1IT SEES YOU^7", "^1DIE^7",
		"^1EMPTY^7", "^1ROT^7", "^1OBEY^7", "^1FORGET^7"
	};

	// Fill buffer with random garbage
	int pos = 0;
	for (int i = 0; i < 280 && pos < 490; i++) {
		buffer[pos++] = garbage[rand() % strlen(garbage)];
		if (i > 0 && i % 35 == 0 && pos < 490) buffer[pos++] = '\n';
	}
	buffer[pos] = '\0';

	// Inject subliminal message (30% chance = flickers)
	if (rand() % 100 < 30) {
		int wordIdx = rand() % 8;
		const char *word = subliminal[wordIdx];
		int insertPos = 80 + (rand() % 150);
		int wordLen = strlen(word);
		if (insertPos + wordLen < 480) {
			memcpy(buffer + insertPos, word, wordLen);
		}
	}

	G_RPG_SendSmallCenteredText(player, buffer);

	// Audio hallucination (20% chance)
	if (rand() % 100 < 20) {
		G_Sound(player, CHAN_LOCAL, G_SoundIndex("sound/movers/switches/switch2.wav"));
	}
}

/*
================
G_RPG_TriggerGlitch
Initiates a psychotic break episode
================
*/
static void G_RPG_TriggerGlitch(gentity_t *player, int durationMs) {
	rpgGame_t *game = &player->client->rpg;
	game->stateBeforeGlitch = game->state;
	game->state = RPG_STATE_GLITCH_BURST;
	game->glitchEndTime = level.time + durationMs;
	game->glitchNextFrameTime = level.time;
	G_Sound(player, CHAN_AUTO, G_SoundIndex("sound/movers/switches/switch2.wav"));
}

/*
================
G_RPG_ScrambleText
ACT 4: UI Scrambler - Corrupts menu text progressively based on paranoia
================
*/
static void G_RPG_ScrambleText(char *text, int paranoiaLevel) {
	int len = strlen(text);
	int corruptionChance = 0;

	// Progressive corruption based on paranoia
	if (paranoiaLevel >= 95) {
		corruptionChance = 60;  // 60% corruption at critical paranoia
	} else if (paranoiaLevel >= 85) {
		corruptionChance = 30;  // 30% corruption at high paranoia
	} else if (paranoiaLevel >= 70) {
		corruptionChance = 10;  // 10% corruption at moderate paranoia
	}

	if (corruptionChance == 0) return;  // No corruption below paranoia 70

	for (int i = 0; i < len; i++) {
		// Don't corrupt newlines, color codes, or brackets
		if (text[i] == '\n' || text[i] == '^' || text[i] == '[' || text[i] == ']') {
			continue;
		}

		// Corrupt character based on chance
		if (rand() % 100 < corruptionChance) {
			const char glitchChars[] = "#@?%&!01";
			text[i] = glitchChars[rand() % 8];
		}
	}
}

/*
================
G_RPG_SendSmallCenteredText

Sends text using cp command but with small font via remapShader trick.
This remaps the large centerprint font to the small console font, making cp
display smaller text while still being properly centered by the engine.

The remapShader command is 100% server-side and requires no client downloads.
This is how advanced servers achieve smaller centerprint text.
================
*/
void G_RPG_SendSmallCenteredText(gentity_t *player, const char *text) {
	// Use cp command - the font is already remapped to small in G_RPG_Init
	trap->SendServerCommand(player->s.number, va("cp \"%s\"", G_RPG_SanitizeString(text)));
}

/*
================
G_RPG_RefreshDisplay

UPDATED: Combines narrative and menu into a single Center Print (cp) command.
Relies on remapShader being active to ensure text fits on screen.
================
*/
void G_RPG_RefreshDisplay(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;
	char hudDisplay[512];       // Menu options
	char narrativeDisplay[RPG_MAX_DISPLAY]; // Story text
	char finalBuffer[1024];     // Combined buffer (Must not exceed ~1022 bytes)
	qboolean sendNarrative = qfalse;

	// CRITICAL: Rate limit to prevent command queue overflow (100ms minimum)
	if (level.time - game->lastRefreshTime < 100) {
		return;  // Too soon, skip this refresh
	}
	game->lastRefreshTime = level.time;

	// Only update narrative if state or dream sequence changed (prevents spam/flicker)
	if (game->state != game->lastNarrativeState ||
	    (game->state == RPG_STATE_DREAM && game->dreamSequence != game->lastNarrativeDream)) {
		sendNarrative = qtrue;
		game->lastNarrativeState = game->state;
		game->lastNarrativeDream = game->dreamSequence;
	}

	// Clear buffers
	hudDisplay[0] = '\0';
	narrativeDisplay[0] = '\0';
	finalBuffer[0] = '\0';

	// Build display based on current state
	switch (game->state) {
		case RPG_STATE_INTRO:
			// Intro is special - use cp for paginated crawl
			G_RPG_ShowIntro(player, hudDisplay, sizeof(hudDisplay));
			// Just send HUD directly for intro
			G_RPG_SendSmallCenteredText(player, hudDisplay);
			return; // Exit early

		case RPG_STATE_DREAM:
			// Dream sequence
			G_RPG_ShowDream(player, hudDisplay, sizeof(hudDisplay), narrativeDisplay, sizeof(narrativeDisplay));
		// Send narrative to console separately so it's not truncated
		if (sendNarrative && narrativeDisplay[0] != '\0') {
			trap->SendServerCommand(player->s.number, va("print \"%s\"", G_RPG_SanitizeString(narrativeDisplay)));
			narrativeDisplay[0] = '\0';  // Clear so only HUD goes to cp
		}
			break;

		case RPG_STATE_CLASS_SELECTION:
			G_RPG_ShowClassSelection(player, hudDisplay, sizeof(hudDisplay));
			break;

		case RPG_STATE_EXPLORATION:
			// Populate both buffers
			if (sendNarrative) {
				G_RPG_ShowExplorationNarrative(player, narrativeDisplay, sizeof(narrativeDisplay));
				// FIX: Send narrative to print (console) separately so it persists
				// and doesn't get overwritten by subsequent centerprint refreshes
				if (narrativeDisplay[0] != '\0') {
					trap->SendServerCommand(player->s.number, va("print \"%s\"", G_RPG_SanitizeString(narrativeDisplay)));
					narrativeDisplay[0] = '\0';  // Clear so only HUD goes to cp
				}
			}
			G_RPG_ShowExplorationMenu(player, hudDisplay, sizeof(hudDisplay));
			break;

		case RPG_STATE_COMBAT:
			G_RPG_ShowCombat(player, hudDisplay, sizeof(hudDisplay));
			// ACT 4: Apply UI Scrambler in combat
			if (game->currentAct >= 4) {
				G_RPG_ScrambleText(hudDisplay, game->player.paranoiaLevel);
			}
			break;

		case RPG_STATE_DIALOGUE:
			G_RPG_ShowDialogue(player, hudDisplay, sizeof(hudDisplay));
			break;

		case RPG_STATE_INVENTORY:
			G_RPG_ShowInventory(player, hudDisplay, sizeof(hudDisplay));
			break;
		case RPG_STATE_CHARACTER_SHEET:
			G_RPG_ShowCharacterSheet(player, hudDisplay, sizeof(hudDisplay));
			break;
		case RPG_STATE_QUEST_LOG:
			G_RPG_ShowQuestLog(player, hudDisplay, sizeof(hudDisplay));
			break;
		case RPG_STATE_SHOP:
			G_RPG_ShowShop(player, hudDisplay, sizeof(hudDisplay));
			break;

		default:
			Com_sprintf(hudDisplay, sizeof(hudDisplay), "^1ERROR: Invalid state^7");
			break;
	}

	// --- COMBINATION LOGIC ---

	// If we have narrative text (story), put it at the top
	if (narrativeDisplay[0] != '\0') {
		Com_sprintf(finalBuffer, sizeof(finalBuffer), "%s\n\n%s", narrativeDisplay, hudDisplay);
	} else {
		// Otherwise just show the menu/HUD
		Q_strncpyz(finalBuffer, hudDisplay, sizeof(finalBuffer));
	}

	// Send the combined result to Center Print
	// NOTE: We do NOT use 'print' anymore. Everything goes to 'cp'.
	G_RPG_SendSmallCenteredText(player, finalBuffer);
}

/*
================
G_RPG_ShowDream
Force vision/dream sequence - immersive narrative
narrativeOut = goes to print (scrolling console)
hudOut = goes to cp (center screen prompt)
================
*/
void G_RPG_ShowDream(gentity_t *player, char *hudOut, int hudMaxLen, char *narrativeOut, int narrativeMaxLen) {
	rpgGame_t *game = &player->client->rpg;

	// Different dreams for different story beats
	switch (game->dreamSequence) {
		case 0: // Intro - The crash vision
			Com_sprintf(narrativeOut, narrativeMaxLen,
				"^0Darkness. Absolute darkness.\n\n"
				"Then—metal tearing. Screaming. The smell of ozone and burning flesh.\n"
				"You are falling. The ground rushes toward you—\n\n"
				"A ^5purple light^7 pulses in the wreckage ahead.\n"
				"^1It knows you.^7\n"
				"^1It has been waiting.^7\n\n"
				"^5[WHISPER] ...come to us...^7\n\n");

			Com_sprintf(hudOut, hudMaxLen,
				"^1[FORCE VISION]^7\n\n"
				"^0WAKE UP.^7\n\n"
				"^3JUMP^7 = Resist the vision\n"
				"^3USE^7 = Embrace it");
			break;

		case 1: // Post-Holocron acquisition
			Com_sprintf(narrativeOut, narrativeMaxLen,
				"^0You are drowning in voices.\n\n"
				"Thousands of them. Screaming. Whispering. Pleading.\n"
				"Every soul who has touched the Holocron before you.\n\n"
				"They all went mad.\n"
				"^1They all fell.^7\n\n"
				"^5Will you be different?^7\n\n");

			Com_sprintf(hudOut, hudMaxLen,
				"^5[THE HOLOCRON SPEAKS]^7\n\n"
				"^3JUMP^7 = Wake up");
			break;

		default:
			Com_sprintf(narrativeOut, narrativeMaxLen, "");
			Com_sprintf(hudOut, hudMaxLen, "^1[DREAM ERROR]^7");
			break;
	}
}

/*
================
G_RPG_HandleDream
Handle input during dream sequences
================
*/
void G_RPG_HandleDream(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;

	// JUMP pressed = Resist, wake up normally
	if (game->selection == 0) {
		trap->SendServerCommand(player->s.number,
			"print \"^2You gasp for air. Your quarters. Safe. It was just a dream...^7\n\n\"");

		game->state = RPG_STATE_CLASS_SELECTION;
		game->selection = 0;
		G_RPG_RefreshDisplay(player);
	}
	// USE pressed = Embrace vision (Dark Side temptation)
	else if (game->selection == 1 && game->dreamSequence == 0) {
		trap->SendServerCommand(player->s.number,
			"print \"^1You let the vision consume you.\n"
			"The Holocron's call grows stronger...\n"
			"It KNOWS your name.^7\n\n\"");

		// Subtle corruption for embracing the vision
		game->player.alignment -= 2;
		G_RPG_ModifyParanoia(&game->player, 3);

		game->state = RPG_STATE_CLASS_SELECTION;
		game->selection = 0;
		G_RPG_RefreshDisplay(player);
	}
}

/*
================
G_RPG_ShowIntro
Opening crawl with paginated scrolling
================
*/
void G_RPG_ShowIntro(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	int page = game->page;

	// Page 1: Title and Setup
	if (page == 0) {
		Com_sprintf(out, maxLen,
			"^3═══════════════════════════════════════^7\n"
			"^4       ECHOES OF THE DARK WARS^7\n"
			"^3═══════════════════════════════════════^7\n"
			"^9Page 1/3^7\n\n"
			"^73949 BBY - Five years after Revan \n"
			"vanished into the Unknown Regions.\n\n"
			"The JEDI ORDER lies shattered, its \n"
			"temples ruined, its Masters dead or \n"
			"hiding in the Outer Rim.\n\n"
			"The SITH are fractured—no unified \n"
			"Dark Lord remains. Broken cults and \n"
			"fallen Jedi scramble for ancient power.\n\n"
			"The REPUBLIC is exhausted. Two wars \n"
			"in ten years have drained its will \n"
			"to fight.\n\n"
			"^3D^7=Next Page"
		);
	}
	// Page 2: Your Story
	else if (page == 1) {
		Com_sprintf(out, maxLen,
			"^3═══════════════════════════════════════^7\n"
			"^9Page 2/3^7\n\n"
			"On DANTOOINE, a quiet world scarred \n"
			"by war, you live in hiding.\n\n"
			"You work in Khoonda Settlement, \n"
			"blending in. Invisible. Safe.\n\n"
			"Your Force sensitivity is a secret \n"
			"that could get you killed. The Sith \n"
			"hunt Force-users. The Republic fears \n"
			"them. Better to pretend you're nothing.\n\n"
			"^1Then, one morning, a ship crashes \n"
			"near the Crystal Caves.^7\n\n"
			"^3A^7=Previous ^3D^7=Next Page"
		);
	}
	// Page 3: The Inciting Incident
	else {
		Com_sprintf(out, maxLen,
			"^3═══════════════════════════════════════^7\n"
			"^9Page 3/3^7\n\n"
			"Inside the wreckage: a dead Jedi \n"
			"Shadow, her body cold.\n\n"
			"In her hand: a ^6SITH HOLOCRON^7, \n"
			"pulsing with ancient, terrible power.\n\n"
			"Word spreads fast. Within hours, \n"
			"three factions converge on Dantooine:\n\n"
			"The ^4Republic^7 wants to secure it.\n"
			"The ^3Exchange^7 wants to sell it.\n"
			"The ^1Sith^7 want to claim it.\n\n"
			"War is coming. Again.\n\n"
			"^1Will you hide and let others decide \n"
			"the galaxy's fate?^7\n\n"
			"^2Or will you step forward and become \n"
			"what the galaxy needs?^7\n\n"
			"^3A^7=Previous ^3USE^7=Begin"
		);
	}

	game->numOptions = 1;
}

/*
================
G_RPG_ShowClassSelection
================
*/
void G_RPG_ShowClassSelection(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	int sel = game->selection;

	Com_sprintf(out, maxLen,
		"^5═══ CHOOSE YOUR PATH ═══^7\n\n"
		"%s^71. Jedi Guardian^7\n"
		"   STR 16 | Tank & Melee\n"
		"%s^72. Jedi Consular^7\n"
		"   WIS 18 | Force Powers\n"
		"%s^73. Jedi Sentinel^7\n"
		"   Balanced | Versatile\n"
		"%s^74. Scoundrel^7\n"
		"   CHA 16 | Cunning & Luck\n"
		"%s^75. Soldier^7\n"
		"   STR 16 | Heavy Combat\n"
		"%s^76. Bounty Hunter^7\n"
		"   DEX 14 | Gadgets & Tracking\n\n"
		"^3W/S^7=Select ^3USE^7=Confirm",

		sel == 0 ? "^2> " : "  ",
		sel == 1 ? "^2> " : "  ",
		sel == 2 ? "^2> " : "  ",
		sel == 3 ? "^2> " : "  ",
		sel == 4 ? "^2> " : "  ",
		sel == 5 ? "^2> " : "  "
	);

	game->numOptions = 6;
}

/*
================
G_RPG_ShowExplorationNarrative
Sends room description to PRINT (console/chat) - Can be long!
================
*/
void G_RPG_ShowExplorationNarrative(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;
	rpgRoom_t *room = &game->rooms[p->currentRoom];

	// Only send narrative when entering a new room
	if (!room->visited) {
		// Build base description
		Com_sprintf(out, maxLen,
			"^5════════════════════════════════════════^7\n"
			"^5%s^7\n"
			"^5════════════════════════════════════════^7\n\n"
			"%s\n\n",
			room->name,
			room->description);

		// FORCE INSIGHT: High Wisdom reveals hidden details
		if (p->stats[STAT_WISDOM] >= 14) {
			char insightText[256] = "";

			// Room-specific insights
			switch (p->currentRoom) {
				case 1:  // Khoonda Main Hall
					if (p->stats[STAT_WISDOM] >= 16) {
						Q_strncpyz(insightText,
							"^5[Force Insight]^7 You sense Administrator Adare's fear. "
							"She knows something about the crash she's not saying.\n\n", sizeof(insightText));
					}
					break;

				case 3:  // Cantina
					if (p->stats[STAT_WISDOM] >= 14) {
						Q_strncpyz(insightText,
							"^5[Force Insight]^7 The scarred veteran... you feel echoes of the Force around him. "
							"Suppressed. Hidden. He was trained.\n\n", sizeof(insightText));
					}
					break;

				case 5:  // Crash Site
					if (p->stats[STAT_WISDOM] >= 18) {
						Q_strncpyz(insightText,
							"^5[Force Insight]^7 The dark presence isn't just the Holocron. "
							"Someone... ^1powerful^7... has been here recently. The Force still trembles.\n\n", sizeof(insightText));
					} else if (p->stats[STAT_WISDOM] >= 14) {
						Q_strncpyz(insightText,
							"^5[Force Insight]^7 This wasn't an accident. You sense purpose in the crash trajectory.\n\n",
							sizeof(insightText));
					}
					break;

				case 9:  // Ancient Jedi Chamber
					if (p->stats[STAT_WISDOM] >= 16) {
						Q_strncpyz(insightText,
							"^5[Force Insight]^7 The coordinates on the floor... they point to the Unknown Regions. "
							"The same path Revan took.\n\n", sizeof(insightText));
					}
					break;
			}

			if (insightText[0]) {
				Q_strcat(out, maxLen, insightText);
			}
		}

		room->visited = qtrue;
	} else {
		// Subsequent visits - just show name
		out[0] = '\0';  // No narrative update
	}
}

/*
================
G_RPG_ShowExplorationMenu
Sends menu options to CP (centerprint) - Keep under 500 chars!
================
*/
void G_RPG_ShowExplorationMenu(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;
	rpgRoom_t *room = &game->rooms[p->currentRoom];
	int sel = game->selection;

	// Movement menu mode (page == 1)
	if (game->page == 1) {
		char exitOptions[512] = "";
		int numExits = 0;

		// Build exit menu
		for (int i = 0; i < MAX_ROOM_EXITS; i++) {
			if (room->exits[i] >= 0) {
				char line[64];
				const char *dirName = "";
				switch (i) {
					case 0: dirName = "^2North^7"; break;
					case 1: dirName = "^3East^7"; break;
					case 2: dirName = "^9South^7"; break;
					case 3: dirName = "^6West^7"; break;
					case 4: dirName = "^5Up^7"; break;
					case 5: dirName = "^1Down^7"; break;
				}

				Com_sprintf(line, sizeof(line), "%s%d. %s - %s\n",
					numExits == sel ? "^2> " : "  ",
					numExits + 1,
					dirName,
					room->exitNames[i]);

				Q_strcat(exitOptions, sizeof(exitOptions), line);
				numExits++;
			}
		}

		Com_sprintf(out, maxLen,
			"^9[%s]^7\n\n"
			"^5Where will you go?^7\n\n"
			"%s\n"
			"^3W/S^7=Select ^3USE^7=Go ^3ATT^7=Cancel",
			room->name,
			exitOptions
		);

		game->numOptions = numExits;
		return;
	}

	// Item selection menu mode (page == 2)
	if (game->page == 2) {
		char itemOptions[512] = "";
		int optionIndex = 0;

		// Add "Take All" option if there are multiple items
		if (room->itemCount > 1) {
			char line[96];
			Com_sprintf(line, sizeof(line), "%s0. ^3Take All^7\n",
				sel == optionIndex ? "^2> " : "  ");
			Q_strcat(itemOptions, sizeof(itemOptions), line);
			optionIndex++;
		}

		// Build item menu
		for (int i = 0; i < room->itemCount && i < MAX_ROOM_ITEMS; i++) {
			int itemID = room->itemIDs[i];
			if (G_RPG_ValidateItemID(game, itemID)) {
				rpgItem_t *item = &game->items[itemID];
				char line[96];
				Com_sprintf(line, sizeof(line), "%s%d. %s\n",
					sel == optionIndex ? "^2> " : "  ",
					optionIndex,
					item->name);
				Q_strcat(itemOptions, sizeof(itemOptions), line);
				optionIndex++;
			}
		}

		Com_sprintf(out, maxLen,
			"^9[%s]^7\n\n"
			"^6Which item will you take?^7\n\n"
			"%s\n"
			"^3W/S^7=Select ^3USE^7=Take ^3ATT^7=Cancel",
			room->name,
			itemOptions
		);

		game->numOptions = optionIndex;
		return;
	}

	// Normal exploration view
	char exitsStr[128] = "";
	char itemsStr[128] = "";
	char npcsStr[128] = "";

	// Build exits string
	for (int i = 0; i < MAX_ROOM_EXITS; i++) {
		if (room->exits[i] >= 0) {
			if (exitsStr[0]) Q_strcat(exitsStr, sizeof(exitsStr), ", ");
			Q_strcat(exitsStr, sizeof(exitsStr), room->exitNames[i]);
		}
	}
	if (!exitsStr[0]) Q_strncpyz(exitsStr, "None", sizeof(exitsStr));

	// Build items string
	for (int i = 0; i < room->itemCount && i < 3; i++) {
		int itemID = room->itemIDs[i];
		// Validate item ID before accessing
		if (G_RPG_ValidateItemID(game, itemID)) {
			rpgItem_t *item = &game->items[itemID];
			if (i > 0) Q_strcat(itemsStr, sizeof(itemsStr), ", ");
			Q_strcat(itemsStr, sizeof(itemsStr), item->name);
		}
	}
	if (!itemsStr[0]) Q_strncpyz(itemsStr, "None", sizeof(itemsStr));

	// Build NPCs string
	for (int i = 0; i < room->npcCount && i < 3; i++) {
		int npcID = room->npcIDs[i];
		// Validate NPC ID before accessing
		if (G_RPG_ValidateNPCID(game, npcID)) {
			rpgNPC_t *npc = &game->npcs[npcID];
			if (npc->alive) {
				if (i > 0) Q_strcat(npcsStr, sizeof(npcsStr), ", ");
				Q_strcat(npcsStr, sizeof(npcsStr), npc->name);
			}
		}
	}
	if (!npcsStr[0]) Q_strncpyz(npcsStr, "No one", sizeof(npcsStr));

	// Build menu based on room contents
	int numOptions = 0;
	char menuOptions[256] = "";
	char line[64];

	// Always show these options
	Com_sprintf(line, sizeof(line), "%s^71. Look around^7\n", sel == numOptions ? "^2> " : "  ");
	Q_strcat(menuOptions, sizeof(menuOptions), line);
	numOptions++;

	Com_sprintf(line, sizeof(line), "%s^72. Inventory^7\n", sel == numOptions ? "^2> " : "  ");
	Q_strcat(menuOptions, sizeof(menuOptions), line);
	numOptions++;

	Com_sprintf(line, sizeof(line), "%s^73. Character^7\n", sel == numOptions ? "^2> " : "  ");
	Q_strcat(menuOptions, sizeof(menuOptions), line);
	numOptions++;

	// Show "Take Item" if items present
	if (room->itemCount > 0) {
		Com_sprintf(line, sizeof(line), "%s^74. Take Item^7\n", sel == numOptions ? "^2> " : "  ");
		Q_strcat(menuOptions, sizeof(menuOptions), line);
		numOptions++;
	}

	// Show "Talk" if NPCs present
	if (room->npcCount > 0) {
		Com_sprintf(line, sizeof(line), "%s^7%d. Talk^7\n", sel == numOptions ? "^2> " : "  ", numOptions + 1);
		Q_strcat(menuOptions, sizeof(menuOptions), line);
		numOptions++;
	}

	// Always show Move
	Com_sprintf(line, sizeof(line), "%s^7%d. Move^7\n", sel == numOptions ? "^2> " : "  ", numOptions + 1);
	Q_strcat(menuOptions, sizeof(menuOptions), line);
	numOptions++;

	Com_sprintf(out, maxLen,
		"^9[%s]^7\n\n"        // Always show Room Name at top
		"^2Exits:^7 %s\n"
		"^6Items:^7 %s\n"
		"^3NPCs:^7 %s\n\n"
		"^5What do you do?^7\n"
		"%s\n"
		"^3W/S^7=Select ^3USE^7=Confirm ^3ATT^7=Exit",

		room->name,
		exitsStr,
		itemsStr,
		npcsStr,
		menuOptions
	);

	game->numOptions = numOptions;
}

/*
================
G_RPG_ShowCombat
Combat screen
================
*/
void G_RPG_ShowCombat(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	rpgCombat_t *combat = &game->combat;
	rpgPlayer_t *p = &game->player;
	int sel = game->selection;

	const char *enemyBar = G_RPG_GetHealthBar(combat->enemyHP, combat->enemyMaxHP);
	const char *playerBar = G_RPG_GetHealthBar(p->hp, p->maxHP);
	const char *fpBar = G_RPG_GetHealthBar(p->fp, p->maxFP);

	// TELEGRAPH SYSTEM: Show enemy "tell" if combat is active
	// The selectedPower field is repurposed to store enemy's next move:
	// 0 = Lunge (beat with Defend), 1 = Charge (beat with Attack), 2 = Leap (beat with Dodge)
	char telegraphText[256] = "^7Prepare yourself...";
	if (combat->playerTurn && combat->turnCount > 0) {
		switch (combat->selectedPower) {  // Reusing this field for enemy telegraph
			case 0:  // Lunge - beat with Defend
				Q_strncpyz(telegraphText,
					"^3The kinrath's mandibles spread wide, its body coiling low. "
					"^1It's preparing to LUNGE forward!^7",
					sizeof(telegraphText));
				break;
			case 1:  // Charge - beat with Attack
				Q_strncpyz(telegraphText,
					"^3The kinrath rears back on its hind legs, chittering aggressively. "
					"^1It's building up for a CHARGE!^7",
					sizeof(telegraphText));
				break;
			case 2:  // Leap - beat with Dodge/Force Push
				Q_strncpyz(telegraphText,
					"^3The kinrath's legs tense, body shifting upward. "
					"^1It's about to LEAP at you!^7",
					sizeof(telegraphText));
				break;
		}
	} else if (combat->lastActionResult[0]) {
		Q_strncpyz(telegraphText, combat->lastActionResult, sizeof(telegraphText));
	}

	// Check if companion is active
	char companionStatus[128] = "";
	if (p->activeCompanion >= 0 && p->companionCount > 0) {
		int companionID = p->companionIDs[p->activeCompanion];
		rpgNPC_t *companion = &game->npcs[companionID];
		if (companion->alive && companion->hp > 0) {
			const char *companionBar = G_RPG_GetHealthBar(companion->hp, companion->maxHP);
			Com_sprintf(companionStatus, sizeof(companionStatus),
				"^6%s: %s %d/%d^7\n",
				companion->name, companionBar, companion->hp, companion->maxHP);
		}
	}

	// Get theme color for UI framework (pulsing if corrupted)
	const char *themeColor = G_RPG_GetThemeColor(player);

	Com_sprintf(out, maxLen,
		"%s[COMBAT]^7 ^9%s^7\n\n"
		"%sEnemy: %s %d/%d^7\n"
		"%sYou:   %s %d/%d^7  ^4FP: %s %d/%d^7\n"
		"%s"
		"%s\n\n"
		"%sYour move:^7\n"
		"%s^71. Attack^7 - Strike (counters ^3Charge^7)\n"
		"%s^72. Force Push^7 - Stun (counters ^3Leap^7, 25 FP)\n"
		"%s^73. Defend^7 - Block (counters ^3Lunge^7)\n"
		"%s^74. Flee^7 - 75%% chance\n\n"
		"^8Read the enemy's movements carefully!^7\n"
		"%sW/S^7=Select %sUSE^7=Confirm",

		themeColor,  // [COMBAT] header
		combat->enemyName,
		themeColor,  // Enemy label
		enemyBar, combat->enemyHP, combat->enemyMaxHP,
		themeColor,  // You label
		playerBar, p->hp, p->maxHP,
		fpBar, p->fp, p->maxFP,
		companionStatus,

		telegraphText,

		themeColor,  // Your move prompt
		sel == 0 ? "^2> " : "  ",
		sel == 1 ? "^2> " : "  ",
		sel == 2 ? "^2> " : "  ",
		sel == 3 ? "^2> " : "  ",

		themeColor,  // W/S controls
		themeColor   // USE controls
	);

	game->numOptions = 4;
}

/*
================
G_RPG_ShowDialogue
================
*/
void G_RPG_ShowDialogue(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	rpgDialogue_t *dlg = &game->dialogue;
	rpgPlayer_t *p = &game->player;
	int sel = game->selection;
	char choiceDisplay[512] = "";
	char line[128];

	// Build choices menu from dialogue data
	for (int i = 0; i < dlg->choiceCount; i++) {
		// Add color coding for dialogue type
		char typeIndicator[16] = "";
		switch (dlg->choiceType[i]) {
			case DIALOGUE_LIGHT:
				Q_strncpyz(typeIndicator, "^2", sizeof(typeIndicator));  // Green for light side
				break;
			case DIALOGUE_DARK:
				Q_strncpyz(typeIndicator, "^1", sizeof(typeIndicator));  // Red for dark side
				break;
			case DIALOGUE_PERSUADE:
				Q_strncpyz(typeIndicator, "^5", sizeof(typeIndicator));  // Purple for persuade
				break;
			case DIALOGUE_THREATEN:
				Q_strncpyz(typeIndicator, "^1", sizeof(typeIndicator));  // Red for threaten
				break;
			case DIALOGUE_BRIBE:
				Q_strncpyz(typeIndicator, "^3", sizeof(typeIndicator));  // Yellow for bribe
				break;
			default:
				Q_strncpyz(typeIndicator, "^7", sizeof(typeIndicator));  // White for normal
				break;
		}

		// Check if skill requirement is met
		qboolean canChoose = qtrue;
		if (dlg->choiceRequiredStat[i] >= 0) {
			if (p->stats[dlg->choiceRequiredStat[i]] < dlg->choiceRequiredValue[i]) {
				canChoose = qfalse;
			}
		}

		// Build choice line
		if (canChoose) {
			Com_sprintf(line, sizeof(line), "%s%s%d. %s^7\n",
				sel == i ? "^2> " : "  ",
				typeIndicator,
				i + 1,
				dlg->choiceText[i]);
		} else {
			// Show grayed out for failed skill checks
			Com_sprintf(line, sizeof(line), "  ^8%d. %s [Requires stat check]^7\n",
				i + 1,
				dlg->choiceText[i]);
		}

		Q_strcat(choiceDisplay, sizeof(choiceDisplay), line);
	}

	// Build complete display
	Com_sprintf(out, maxLen,
		"^6[%s]^7\n\n"
		"^5How do you respond?^7\n"
		"%s\n"
		"^3W/S^7=Select ^3USE^7=Choose\n"
		"^8Light:^2Green ^8Dark:^1Red ^8Special:^5Purple",

		game->npcs[dlg->npcID].name,
		choiceDisplay
	);

	game->numOptions = dlg->choiceCount;
}

/*
================
G_RPG_ShowInventory
================
*/
void G_RPG_ShowInventory(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;
	int sel = game->selection;

	// Safely get equipped weapon name
	const char *weaponName = "None";
	if (p->equipped[SLOT_WEAPON] >= 0 && G_RPG_ValidateItemID(game, p->equipped[SLOT_WEAPON])) {
		weaponName = game->items[p->equipped[SLOT_WEAPON]].name;
	}

	// Safely get equipped armor name
	const char *armorName = "None";
	if (p->equipped[SLOT_ARMOR] >= 0 && G_RPG_ValidateItemID(game, p->equipped[SLOT_ARMOR])) {
		armorName = game->items[p->equipped[SLOT_ARMOR]].name;
	}

	// Safely get first inventory item name
	const char *firstItemName = "(Empty)";
	if (p->inventoryCount > 0 && G_RPG_ValidateItemID(game, p->inventory[0])) {
		firstItemName = game->items[p->inventory[0]].name;
	}

	Com_sprintf(out, maxLen,
		"^5═══ INVENTORY ═══^7\n"
		"Credits: ^3%d^7  Weight: ^2%d/100^7\n\n"
		"^2EQUIPPED:^7\n"
		"Weapon: ^6%s^7\n"
		"Armor: ^6%s^7\n\n"
		"^2ITEMS:^7\n"
		"%s^7%s^7\n\n"
		"^3W/S^7=Navigate ^3USE^7=Use ^3ATT^7=Back",

		p->credits,
		G_RPG_CalculateWeight(game, p),

		weaponName,
		armorName,

		sel == 0 ? "^2> " : "  ",
		firstItemName
	);

	game->numOptions = p->inventoryCount > 0 ? p->inventoryCount : 1;
}

/*
================
G_RPG_ShowCharacterSheet
================
*/
void G_RPG_ShowCharacterSheet(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;

	Com_sprintf(out, maxLen,
		"^5═══ CHARACTER ═══^7\n"
		"^2%s^7 - Lv %d ^6%s^7\n\n"
		"^2HP:^7 %d/%d  ^4FP:^7 %d/%d\n"
		"^2XP:^7 %d / %d\n\n"
		"^7STR: %d  DEX: %d  CON: %d\n"
		"WIS: %d  INT: %d  CHA: %d\n\n"
		"^2Alignment:^7 %s\n\n"
		"^3ATT^7=Back to game",

		p->name[0] ? p->name : "Unnamed",
		p->level,
		G_RPG_GetClassName(p->class),

		p->hp, p->maxHP,
		p->fp, p->maxFP,
		p->xp, p->xpToNext,

		p->stats[STAT_STRENGTH],
		p->stats[STAT_DEXTERITY],
		p->stats[STAT_CONSTITUTION],
		p->stats[STAT_WISDOM],
		p->stats[STAT_INTELLIGENCE],
		p->stats[STAT_CHARISMA],

		G_RPG_GetAlignmentString(p->alignment)
	);

	game->numOptions = 1;
}

/*
================
G_RPG_ShowQuestLog
================
*/
void G_RPG_ShowQuestLog(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	char questDisplay[512] = "";
	char line[128];
	int activeCount = 0;
	int completedCount = 0;

	// Count and display active quests
	for (int i = 0; i < game->questCount; i++) {
		rpgQuest_t *quest = &game->quests[i];

		if (quest->state == QUEST_ACTIVE) {
			activeCount++;

			// Add quest name
			Com_sprintf(line, sizeof(line), "\n^3%s%s^7\n",
				quest->isMainQuest ? "[MAIN] " : "",
				quest->name);
			Q_strcat(questDisplay, sizeof(questDisplay), line);

			// Add active objectives
			for (int j = 0; j < quest->objectiveCount; j++) {
				if (!quest->objectiveComplete[j]) {
					Com_sprintf(line, sizeof(line), "  ^8%s %s^7\n",
						quest->objectiveComplete[j] ? "[X]" : "[ ]",
						quest->objectives[j]);
					Q_strcat(questDisplay, sizeof(questDisplay), line);
					break;  // Only show current objective
				}
			}
		} else if (quest->state == QUEST_COMPLETED) {
			completedCount++;
		}
	}

	// Build full display
	if (activeCount == 0) {
		Com_sprintf(out, maxLen,
			"^5═══ QUEST LOG ═══^7\n\n"
			"^3Active Quests:^7\n"
			"  ^8(None)^7\n\n"
			"^2Completed:^7 %d\n\n"
			"^3ATT^7=Back",
			completedCount);
	} else {
		Com_sprintf(out, maxLen,
			"^5═══ QUEST LOG ═══^7\n\n"
			"^3Active Quests:^7%s\n"
			"^2Completed:^7 %d\n\n"
			"^3ATT^7=Back",
			questDisplay,
			completedCount);
	}

	game->numOptions = 1;
}

/*
================
G_RPG_ShowShop
Merchant Goran's shop interface
================
*/
void G_RPG_ShowShop(gentity_t *player, char *out, int maxLen) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;
	int sel = game->selection;

	// Shop inventory (hardcoded for Merchant Goran)
	// Items: 3=Medpac(50cr), 5=Green Crystal(200cr), 6=Blue Crystal(200cr)
	int shopItems[] = {3, 3, 3, 5, 6};  // Can buy multiple medpacs
	int shopPrices[] = {50, 50, 50, 200, 200};
	int shopCount = 5;

	char itemList[256] = "";
	char line[64];

	for (int i = 0; i < shopCount; i++) {
		// Validate item ID before accessing
		if (!G_RPG_ValidateItemID(game, shopItems[i])) {
			Com_sprintf(line, sizeof(line), "%s^7%d. ^1[Invalid Item]^7 - ^3%d credits^7\n",
				sel == i ? "^2> " : "  ",
				i + 1,
				shopPrices[i]);
		} else {
			rpgItem_t *item = &game->items[shopItems[i]];
			Com_sprintf(line, sizeof(line), "%s^7%d. %s - ^3%d credits^7\n",
				sel == i ? "^2> " : "  ",
				i + 1,
				item->name,
				shopPrices[i]);
		}
		Q_strcat(itemList, sizeof(itemList), line);
	}

	// Exit option
	Com_sprintf(line, sizeof(line), "%s^7%d. [Leave Shop]^7\n",
		sel == shopCount ? "^2> " : "  ",
		shopCount + 1);
	Q_strcat(itemList, sizeof(itemList), line);

	Com_sprintf(out, maxLen,
		"^3═══ MERCHANT GORAN'S SHOP ═══^7\n\n"
		"Your Credits: ^3%d^7\n\n"
		"^2FOR SALE:^7\n"
		"%s\n"
		"^3W/S^7=Navigate ^3USE^7=Buy ^3ALT^7=Back",
		p->credits,
		itemList
	);

	game->numOptions = shopCount + 1;
}

// =============================================================================
// STATE HANDLERS
// =============================================================================

/*
================
G_RPG_HandleIntro
================
*/
void G_RPG_HandleIntro(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;

	// Only move to class selection on final page
	if (game->page == 2) {  // Last page (0, 1, 2)
		game->state = RPG_STATE_CLASS_SELECTION;
		game->selection = 0;
		game->page = 0;
		game->maxPages = 0;
		G_RPG_RefreshDisplay(player);
	}
}

/*
================
G_RPG_HandleClassSelection
================
*/
void G_RPG_HandleClassSelection(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;
	rpgClass_t selectedClass = RPG_CLASS_JEDI_GUARDIAN + game->selection;

	// Initialize player with selected class
	G_RPG_InitPlayer(&game->player, selectedClass);

	// Move to game
	game->state = RPG_STATE_EXPLORATION;
	game->selection = 0;

	G_RPG_RefreshDisplay(player);

	// Send welcome message
	trap->SendServerCommand(player->s.number,
		va("print \"^2Welcome, %s. May the Force be with you.^7\n\"",
		G_RPG_GetClassName(selectedClass)));
}

/*
================
G_RPG_HandleExploration
================
*/
void G_RPG_HandleExploration(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;

	// Check if we're in movement mode (page == 1)
	if (game->page == 1) {
		// In movement menu - execute movement
		rpgRoom_t *room = &game->rooms[game->player.currentRoom];

		// Find the Nth available exit
		int exitIndex = -1;
		int availableExits = 0;
		for (int i = 0; i < MAX_ROOM_EXITS; i++) {
			if (room->exits[i] >= 0) {
				if (availableExits == game->selection) {
					exitIndex = i;
					break;
				}
				availableExits++;
			}
		}

		if (exitIndex >= 0) {
			// Move to selected room
			G_RPG_MoveToRoom(player, game, room->exits[exitIndex]);
		}

		// Exit movement mode
		game->page = 0;
		game->selection = 0;
		G_RPG_RefreshDisplay(player);
		return;
	}

	// Check if we're in item selection mode (page == 2)
	if (game->page == 2) {
		rpgRoom_t *room = &game->rooms[game->player.currentRoom];

		// Check if "Take All" option was selected (selection == 0 and multiple items)
		if (game->selection == 0 && room->itemCount > 1) {
			// Take all items
			int itemsTaken = 0;
			int itemsFailed = 0;

			// Take items in reverse order to avoid shifting issues
			while (room->itemCount > 0 && game->player.inventoryCount < MAX_INVENTORY_SIZE) {
				int itemID = room->itemIDs[0];

				if (G_RPG_ValidateItemID(game, itemID)) {
					rpgItem_t *item = &game->items[itemID];

					// Add to inventory
					game->player.inventory[game->player.inventoryCount++] = itemID;
					itemsTaken++;

					// Send individual pickup messages
					trap->SendServerCommand(player->s.number,
						va("print \"^2Picked up: %s^7\n\"", item->name));

					// Check if it's a quest item
					if (itemID == 2) {  // Sith Holocron
						trap->SendServerCommand(player->s.number,
							"print \"^1The Holocron pulses with dark energy. You feel its power calling to you...^7\n\"");

						// Update quest objective
						if (game->quests[0].state == QUEST_ACTIVE && !game->quests[0].objectiveComplete[2]) {
							game->quests[0].objectiveComplete[2] = qtrue;
							trap->SendServerCommand(player->s.number,
								"print \"^2[Quest Updated: The Sith Holocron]^7\n\"");
						}
					}
				}

				// Remove from room (shift items down)
				for (int i = 0; i < room->itemCount - 1; i++) {
					room->itemIDs[i] = room->itemIDs[i + 1];
				}
				room->itemCount--;
			}

			// Report summary
			if (room->itemCount > 0) {
				itemsFailed = room->itemCount;
				trap->SendServerCommand(player->s.number,
					va("print \"^3Took %d items. %d items left (inventory full).^7\n\n\"", itemsTaken, itemsFailed));
			} else {
				trap->SendServerCommand(player->s.number,
					va("print \"^2Took all %d items.^7\n\n\"", itemsTaken));
			}
		}
		// Single item selection (adjust index if "Take All" was shown)
		else {
			int itemIndex = game->selection;
			if (room->itemCount > 1) {
				itemIndex--;  // Adjust for "Take All" option being at index 0
			}

			// Validate selection
			if (itemIndex >= 0 && itemIndex < room->itemCount) {
				int itemID = room->itemIDs[itemIndex];

				// Validate item ID before accessing
				if (G_RPG_ValidateItemID(game, itemID)) {
					rpgItem_t *item = &game->items[itemID];

					// Add to inventory
					if (game->player.inventoryCount < MAX_INVENTORY_SIZE) {
						game->player.inventory[game->player.inventoryCount++] = itemID;

						// Remove from room (shift items down)
						for (int i = itemIndex; i < room->itemCount - 1; i++) {
							room->itemIDs[i] = room->itemIDs[i + 1];
						}
						room->itemCount--;

						// Send message to print
						trap->SendServerCommand(player->s.number,
							va("print \"^2You picked up: %s^7\n%s\n\n\"", item->name, item->description));

						// Check if it's a quest item
						if (itemID == 2) {  // Sith Holocron
							trap->SendServerCommand(player->s.number,
								"print \"^1The Holocron pulses with dark energy. You feel its power calling to you...^7\n\n\"");

							// Update quest objective
							if (game->quests[0].state == QUEST_ACTIVE && !game->quests[0].objectiveComplete[2]) {
								game->quests[0].objectiveComplete[2] = qtrue;
								trap->SendServerCommand(player->s.number,
									"print \"^2[Quest Updated: The Sith Holocron]^7\n\n\"");
							}
						}
					} else {
						trap->SendServerCommand(player->s.number,
							"print \"^1Your inventory is full!^7\n\"");
					}
				}
			}
		}

		// Exit item selection mode
		game->page = 0;
		game->selection = 0;
		G_RPG_RefreshDisplay(player);
		return;
	}

	// Normal exploration menu - Dynamic based on room contents
	rpgRoom_t *room = &game->rooms[game->player.currentRoom];
	int option = 0;
	int selectedAction = -1;

	// Map selection to action based on room state
	// Options: Look(0), Inventory(1), Character(2), [TakeItem], [Talk], Move
	if (game->selection == option++) selectedAction = 0;  // Look
	else if (game->selection == option++) selectedAction = 1;  // Inventory
	else if (game->selection == option++) selectedAction = 2;  // Character
	else if (room->itemCount > 0 && game->selection == option++) selectedAction = 3;  // Take Item
	else if (room->npcCount > 0 && game->selection == option++) selectedAction = 4;  // Talk
	else if (game->selection == option++) selectedAction = 5;  // Move

	switch (selectedAction) {
		case 0:  // Look around
			// Force re-show room description
			room->visited = qfalse;
			// FIX: Send room narrative to print (console) so it persists
			// and doesn't get overwritten by subsequent centerprint updates
			char narrative[RPG_MAX_DISPLAY];
			G_RPG_ShowExplorationNarrative(player, narrative, sizeof(narrative));
			if (narrative[0] != '\0') {
				trap->SendServerCommand(player->s.number, va("print \"%s\"", G_RPG_SanitizeString(narrative)));
			}
			return;  // Don't fall through

		case 1:  // Inventory
			game->previousState = game->state;
			game->state = RPG_STATE_INVENTORY;
			game->selection = 0;
			G_RPG_RefreshDisplay(player);
			break;

		case 2:  // Character
			game->previousState = game->state;
			game->state = RPG_STATE_CHARACTER_SHEET;
			game->selection = 0;
			G_RPG_RefreshDisplay(player);
			break;

		case 3:  // Take Item
			G_RPG_HandleTakeItem(player);
			break;

		case 4:  // Talk to NPC
			G_RPG_HandleTalkToNPC(player);
			break;

		case 5:  // Move
			// Enter movement mode
			game->page = 1;  // Flag for movement mode
			game->selection = 0;
			G_RPG_RefreshDisplay(player);
			break;

		default:
			break;
	}
}

/*
================
G_RPG_HandleTakeItem
Show item selection menu
================
*/
void G_RPG_HandleTakeItem(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;

	// Validate current room
	if (!G_RPG_ValidateRoomID(game, game->player.currentRoom)) {
		return;
	}

	rpgRoom_t *room = &game->rooms[game->player.currentRoom];

	if (room->itemCount == 0) {
		return;
	}

	// If only one item, take it directly
	if (room->itemCount == 1) {
		int itemID = room->itemIDs[0];

		// Validate item ID before accessing
		if (!G_RPG_ValidateItemID(game, itemID)) {
			trap->SendServerCommand(player->s.number,
				"print \"^1Error: Invalid item data!^7\n\"");
			return;
		}

		rpgItem_t *item = &game->items[itemID];

		// Add to inventory
		if (game->player.inventoryCount < MAX_INVENTORY_SIZE) {
			game->player.inventory[game->player.inventoryCount++] = itemID;

			// Remove from room
			room->itemCount = 0;

			// Send message to print
			trap->SendServerCommand(player->s.number,
				va("print \"^2You picked up: %s^7\n%s\n\n\"", item->name, item->description));

			// Check if it's a quest item
			if (itemID == 2) {  // Sith Holocron
				trap->SendServerCommand(player->s.number,
					"print \"^1The Holocron pulses with dark energy. You feel its power calling to you...^7\n\n\"");

				// Update quest objective
				if (game->quests[0].state == QUEST_ACTIVE && !game->quests[0].objectiveComplete[2]) {
					game->quests[0].objectiveComplete[2] = qtrue;
					trap->SendServerCommand(player->s.number,
						"print \"^2[Quest Updated: The Sith Holocron]^7\n\n\"");
				}
			}

			G_RPG_RefreshDisplay(player);
		} else {
			trap->SendServerCommand(player->s.number,
				"print \"^1Your inventory is full!^7\n\"");
		}
	} else {
		// Multiple items - enter item selection mode
		game->page = 2;  // Flag for item selection mode (page 1 is movement, 2 is items)
		game->selection = 0;
		G_RPG_RefreshDisplay(player);
	}
}

/*
================
G_RPG_HandleTalkToNPC
Start dialogue with NPC
================
*/
void G_RPG_HandleTalkToNPC(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;

	// Validate current room
	if (!G_RPG_ValidateRoomID(game, game->player.currentRoom)) {
		return;
	}

	rpgRoom_t *room = &game->rooms[game->player.currentRoom];

	if (room->npcCount == 0) {
		return;
	}

	// Get first NPC in room
	int npcID = room->npcIDs[0];

	// Validate NPC ID before accessing
	if (!G_RPG_ValidateNPCID(game, npcID)) {
		trap->SendServerCommand(player->s.number,
			"print \"^1Error: Invalid NPC data!^7\n\"");
		return;
	}

	rpgNPC_t *npc = &game->npcs[npcID];

	if (!npc->alive) {
		trap->SendServerCommand(player->s.number,
			va("print \"^1%s is dead.^7\n\"", npc->name));
		return;
	}

	// Start dialogue
	game->dialogue.active = qtrue;
	game->dialogue.npcID = npcID;
	game->dialogue.currentNode = 0;
	game->state = RPG_STATE_DIALOGUE;
	game->selection = 0;

	// Send NPC greeting to print
	G_RPG_ShowNPCDialogue(player, npcID, 0);

	G_RPG_RefreshDisplay(player);
}

/*
================
G_RPG_HandleCombat
================
*/
void G_RPG_HandleCombat(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;

	switch (game->selection) {
		case 0:  // Attack
			G_RPG_ExecuteCombatAction(player, game, COMBAT_ATTACK);
			break;

		case 1:  // Force Push
			if (game->player.fp >= 25) {
				G_RPG_ExecuteCombatAction(player, game, COMBAT_FORCE_POWER);
			} else {
				Com_sprintf(game->combat.lastActionResult,
					sizeof(game->combat.lastActionResult),
					"^1Not enough Force Points!^7");
			}
			break;

		case 2:  // Defend
			G_RPG_ExecuteCombatAction(player, game, COMBAT_DEFEND);
			break;

		case 3:  // Flee
			{
				int roll = rand() % 100;
				if (roll < 75) {
					Com_sprintf(game->combat.lastActionResult,
						sizeof(game->combat.lastActionResult),
						"^2You escaped!^7");
					G_RPG_EndCombat(player, game, qfalse);
				} else {
					Com_sprintf(game->combat.lastActionResult,
						sizeof(game->combat.lastActionResult),
						"^1Can't escape! Enemy blocks you!^7");
					G_RPG_EnemyTurn(player, game);
				}
			}
			break;

		default:
			break;
	}

	G_RPG_RefreshDisplay(player);
}

/*
================
G_RPG_HandleDialogue
Process player's dialogue choice and navigate tree
================
*/
void G_RPG_HandleDialogue(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;
	rpgDialogue_t *dlg = &game->dialogue;
	rpgPlayer_t *p = &game->player;
	int choice = game->selection;

	// Validate choice
	if (choice < 0 || choice >= dlg->choiceCount) {
		return;
	}

	// Check skill requirements
	if (dlg->choiceRequiredStat[choice] >= 0) {
		if (p->stats[dlg->choiceRequiredStat[choice]] < dlg->choiceRequiredValue[choice]) {
			trap->SendServerCommand(player->s.number,
				"print \"^1You don't meet the requirements for this dialogue option.^7\n\"");
			return;
		}
	}

	// Apply alignment change
	int alignmentChange = dlg->choiceAlignmentChange[choice];
	if (alignmentChange != 0) {
		p->alignment += alignmentChange;

		// Clamp alignment to -100 to +100
		if (p->alignment > 100) p->alignment = 100;
		if (p->alignment < -100) p->alignment = -100;

		// Notify player of significant alignment shifts
		if (alignmentChange >= 5) {
			trap->SendServerCommand(player->s.number,
				"print \"^2[Light Side Shift]^7\n\"");
		} else if (alignmentChange <= -5) {
			trap->SendServerCommand(player->s.number,
				"print \"^1[Dark Side Shift]^7\n\"");
		}
	}

	// Get next node
	int nextNode = dlg->choiceNextNode[choice];

	// Check if this ends the dialogue
	if (nextNode == -1) {
		G_RPG_EndDialogue(game);
		return;
	}

	// Navigate to next dialogue node
	dlg->currentNode = nextNode;
	game->selection = 0;  // Reset selection for new node

	// Load next dialogue
	G_RPG_ShowNPCDialogue(player, dlg->npcID, nextNode);

	// Refresh display
	G_RPG_RefreshDisplay(player);
}

/*
================
G_RPG_HandleInventory
================
*/
void G_RPG_HandleInventory(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;

	if (game->player.inventoryCount > 0 && game->selection < game->player.inventoryCount) {
		int itemID = game->player.inventory[game->selection];
		G_RPG_UseItem(game, itemID);
	}

	G_RPG_RefreshDisplay(player);
}

/*
================
G_RPG_HandleShop
Handle shop purchases
================
*/
void G_RPG_HandleShop(gentity_t *player) {
	rpgGame_t *game = &player->client->rpg;
	rpgPlayer_t *p = &game->player;

	// Shop inventory (must match G_RPG_ShowShop)
	int shopItems[] = {3, 3, 3, 5, 6};
	int shopPrices[] = {50, 50, 50, 200, 200};
	int shopCount = 5;

	int sel = game->selection;

	// Exit option selected
	if (sel >= shopCount) {
		game->state = RPG_STATE_EXPLORATION;
		game->selection = 0;
		G_RPG_RefreshDisplay(player);
		return;
	}

	// Validate selection
	if (sel < 0 || sel >= shopCount) {
		return;
	}

	int itemID = shopItems[sel];
	int price = shopPrices[sel];

	// Validate item ID
	if (!G_RPG_ValidateItemID(game, itemID)) {
		trap->SendServerCommand(player->s.number,
			"print \"^1Error: Invalid item!^7\n\"");
		return;
	}

	// Check if player has enough credits
	if (p->credits < price) {
		trap->SendServerCommand(player->s.number,
			"print \"^1Not enough credits!^7\n\"");
		return;
	}

	// Check inventory space
	if (p->inventoryCount >= MAX_INVENTORY_SIZE) {
		trap->SendServerCommand(player->s.number,
			"print \"^1Your inventory is full!^7\n\"");
		return;
	}

	// Make purchase
	p->credits -= price;
	p->inventory[p->inventoryCount++] = itemID;

	trap->SendServerCommand(player->s.number,
		va("print \"^2Purchased: %s^7 for ^3%d credits^7\n\"",
			game->items[itemID].name, price));

	// Auto-save after purchase
	G_RPG_SaveGame(player);

	G_RPG_RefreshDisplay(player);
}

// =============================================================================
// COMBAT SYSTEM
// =============================================================================

/*
================
G_RPG_ExecuteCombatAction
================
*/
void G_RPG_ExecuteCombatAction(gentity_t *player, rpgGame_t *game, rpgCombatAction_t action) {
	rpgCombat_t *combat = &game->combat;
	rpgPlayer_t *p = &game->player;

	// =============================================================================
	// STALKER SURVIVAL CHECK - After 5 turns, you win by survival
	// =============================================================================
	if (combat->enemyID == 12 && combat->turnCount >= 5) {
		trap->SendServerCommand(player->s.number,
			"print \"^2TURN 5 - SURVIVAL ACHIEVED^7\n\n\"");
		G_RPG_EndCombat(player, game, qtrue);
		return;
	}

	// =============================================================================
	// TELEGRAPH COMBAT SYSTEM
	// Rock-paper-scissors based on reading enemy tells:
	// - Attack beats Charge (enemy move 1)
	// - Defend beats Lunge (enemy move 0)
	// - Force Push beats Leap (enemy move 2)
	// =============================================================================

	int enemyMove = combat->selectedPower;  // 0=Lunge, 1=Charge, 2=Leap
	qboolean perfectCounter = qfalse;
	qboolean failedCounter = qfalse;

	switch (action) {
		case COMBAT_ATTACK:
			{
				// Attack counters Charge (move 1)
				if (enemyMove == 1) {
					perfectCounter = qtrue;
					int damage = G_RPG_CalculateDamage(game, p, 35);  // Bonus damage
					combat->enemyHP -= damage;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"^2PERFECT COUNTER!^7 You catch it mid-charge and strike for ^2%d damage^7!", damage);
				}
				// Weak against Lunge (move 0)
				else if (enemyMove == 0) {
					failedCounter = qtrue;
					int damage = G_RPG_CalculateDamage(game, p, 10);
					combat->enemyHP -= damage;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"^1BAD READ!^7 The kinrath lunges past your strike! You deal ^8%d damage^7...", damage);
				}
				// Normal against Leap (move 2)
				else {
					int damage = G_RPG_CalculateDamage(game, p, 20);
					combat->enemyHP -= damage;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"You strike for ^7%d damage^7.", damage);
				}

				if (combat->enemyHP <= 0) {
					G_RPG_EndCombat(player, game, qtrue);
					return;
				}
			}
			break;

		case COMBAT_FORCE_POWER:
			{
				// Force Push counters Leap (move 2)
				p->fp -= 25;
				if (enemyMove == 2) {
					perfectCounter = qtrue;
					int damage = 30;
					combat->enemyHP -= damage;
					combat->enemyStunned = qtrue;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"^2PERFECT COUNTER!^7 You catch it mid-leap! ^4Force Push^7 slams it down for ^2%d damage^7! Stunned!", damage);
				}
				// Weak against Charge (move 1)
				else if (enemyMove == 1) {
					failedCounter = qtrue;
					int damage = 10;
					combat->enemyHP -= damage;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"^1BAD READ!^7 It charges through your push! Only ^8%d damage^7...", damage);
				}
				// Normal against Lunge (move 0)
				else {
					int damage = 15;
					combat->enemyHP -= damage;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"^4Force Push^7 deals ^7%d damage^7.", damage);
				}

				if (combat->enemyHP <= 0) {
					G_RPG_EndCombat(player, game, qtrue);
					return;
				}
			}
			break;

		case COMBAT_DEFEND:
			{
				// Defend counters Lunge (move 0)
				if (enemyMove == 0) {
					perfectCounter = qtrue;
					combat->playerDefending = qtrue;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"^2PERFECT COUNTER!^7 You block the lunge and riposte for ^210 damage^7!");
					combat->enemyHP -= 10;  // Counterattack damage
				}
				// Weak against Leap (move 2)
				else if (enemyMove == 2) {
					failedCounter = qtrue;
					combat->playerDefending = qfalse;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"^1BAD READ!^7 It leaps over your guard! You can't block this...");
				}
				// Normal against Charge (move 1)
				else {
					combat->playerDefending = qtrue;
					Com_sprintf(combat->lastActionResult,
						sizeof(combat->lastActionResult),
						"You raise your guard, bracing for impact.");
				}
			}
			break;

		default:
			break;
	}

	// Enemy turn - execute the telegraphed attack
	if (combat->enemyStunned) {
		combat->enemyStunned = qfalse;
		Q_strcat(combat->lastActionResult, sizeof(combat->lastActionResult), "\n^9The kinrath recovers.^7");
	} else if (!perfectCounter) {
		// Enemy attacks based on their telegraphed move
		int damage = combat->enemyDamage;

		// Failed counter = take extra damage
		if (failedCounter) {
			damage = (int)(damage * 1.5f);
		}

		// Player defending reduces damage
		if (combat->playerDefending) {
			damage = (int)(damage * 0.5f);
		}

		p->hp -= damage;

		char enemyAttackText[128];
		switch (enemyMove) {
			case 0:  // Lunge
				Com_sprintf(enemyAttackText, sizeof(enemyAttackText),
					"\n^1The kinrath LUNGES! %d damage!^7", damage);
				break;
			case 1:  // Charge
				Com_sprintf(enemyAttackText, sizeof(enemyAttackText),
					"\n^1The kinrath CHARGES! %d damage!^7", damage);
				break;
			case 2:  // Leap
				Com_sprintf(enemyAttackText, sizeof(enemyAttackText),
					"\n^1The kinrath LEAPS! %d damage!^7", damage);
				break;
		}
		Q_strcat(combat->lastActionResult, sizeof(combat->lastActionResult), enemyAttackText);

		combat->playerDefending = qfalse;

		if (p->hp <= 0) {
			G_RPG_EndCombat(player, game, qfalse);
			return;
		}
	}

	// =============================================================================
	// COMPANION ATTACK
	// =============================================================================
	// If companion is active and alive, they attack after enemy
	if (p->activeCompanion >= 0 && p->companionCount > 0) {
		int companionID = p->companionIDs[p->activeCompanion];
		rpgNPC_t *companion = &game->npcs[companionID];

		if (companion->alive && companion->hp > 0 && combat->enemyHP > 0) {
			// Companion attacks enemy
			int companionDamage = 12 + (rand() % 6);  // 12-18 damage
			combat->enemyHP -= companionDamage;

			char companionAttack[128];
			Com_sprintf(companionAttack, sizeof(companionAttack),
				"\n^6%s^7 fires at the enemy! ^6%d damage!^7",
				companion->name, companionDamage);
			Q_strcat(combat->lastActionResult, sizeof(combat->lastActionResult), companionAttack);

			if (combat->enemyHP <= 0) {
				G_RPG_EndCombat(player, game, qtrue);
				return;
			}
		}
	}

	// Generate next telegraph for next turn
	combat->selectedPower = rand() % 3;  // Random next move
	combat->turnCount++;
}

/*
================
G_RPG_EnemyTurn
================
*/
void G_RPG_EnemyTurn(gentity_t *player, rpgGame_t *game) {
	rpgCombat_t *combat = &game->combat;
	rpgPlayer_t *p = &game->player;

	// =============================================================================
	// ACT 4: STAT VAMPIRE MECHANIC (Fragment Enemies 14-16)
	// =============================================================================
	if (combat->enemyID >= 14 && combat->enemyID <= 16) {
		// PSYCHIC SCREAM ATTACK (20% chance) - Triggers Glitch Burst
		if (rand() % 100 < 20) {
			// Fragment uses psychic attack instead of normal damage
			char psychicMsg[256];
			const char *fragmentName = "FRAGMENT";
			if (combat->enemyID == 14) fragmentName = "RAGE";
			else if (combat->enemyID == 15) fragmentName = "FEAR";
			else if (combat->enemyID == 16) fragmentName = "DESPAIR";

			Com_sprintf(psychicMsg, sizeof(psychicMsg),
				"^1THE %s SCREAMS DIRECTLY INTO YOUR MIND!^7\n"
				"^8[PSYCHIC ASSAULT]^7", fragmentName);
			Q_strcat(combat->lastActionResult, sizeof(combat->lastActionResult), psychicMsg);

			// Trigger 2-second glitch burst
			G_RPG_TriggerGlitch(player, 2000);
			return;
		}

		// 70% hit chance for stat vampire (normal attack)
		if (rand() % 100 < 70) {
			// Determine which stat dies based on Fragment type
			const char *statName = "HOPE";
			int statIndex = -1;

			if (combat->enemyID == 14) {  // Fragment of Rage
				statName = "STRENGTH";
				statIndex = STAT_STRENGTH;
			} else if (combat->enemyID == 15) {  // Fragment of Fear
				statName = "WISDOM";
				statIndex = STAT_WISDOM;
			} else if (combat->enemyID == 16) {  // Fragment of Despair
				statName = "CHARISMA";
				statIndex = STAT_CHARISMA;
			}

			// Drain the stat permanently
			p->stats[statIndex] -= 1;

			// COMA FAILSAFE - If stat hits 0, enter catatonic state
			if (p->stats[statIndex] <= 0) {
				p->stats[statIndex] = 0;
				game->state = RPG_STATE_GAME_OVER;  // Coma = game over

				Com_sprintf(combat->lastActionResult, sizeof(combat->lastActionResult),
					"^1CRITICAL FAILURE: %s DEPLETED^7\n\n"
					"The Fragment tears the last fragment of your %s away.\n"
					"You collapse. Eyes open. Breathing. But gone.\n\n"
					"^8[COMA STATE - GAME OVER]^7", statName, statName);
				return;
			}

			// Stat vampire message (horror emphasis)
			char horrorMsg[256];
			Com_sprintf(horrorMsg, sizeof(horrorMsg),
				"^1IT TEARS A MEMORY FROM YOUR MIND.^7\n"
				"You forget how to be strong.\n"
				"^1-%d %s (PERMANENT)^7\n"
				"^8[%s remaining: %d]^7",
				1, statName, statName, p->stats[statIndex]);

			Q_strcat(combat->lastActionResult, sizeof(combat->lastActionResult), horrorMsg);

		} else {
			Q_strcat(combat->lastActionResult, sizeof(combat->lastActionResult),
				"^5You deny the shadow. It recoils.^7");
		}
		return;
	}

	// =============================================================================
	// NORMAL COMBAT (Non-Fragment enemies)
	// =============================================================================
	int damage = combat->enemyDamage;

	if (combat->playerDefending) {
		damage /= 2;
		combat->playerDefending = qfalse;
	}

	p->hp -= damage;

	char temp[128];
	Com_sprintf(temp, sizeof(temp), " ^1Enemy attacks for %d damage!^7", damage);
	Q_strcat(combat->lastActionResult, sizeof(combat->lastActionResult), temp);

	if (p->hp <= 0) {
		p->hp = 0;
		game->state = RPG_STATE_GAME_OVER;
	}
}

/*
================
G_RPG_EndCombat
================
*/
void G_RPG_EndCombat(gentity_t *player, rpgGame_t *game, qboolean victory) {
	rpgCombat_t *combat = &game->combat;

	if (victory) {
		// Check if this was the Stalker (survival fight)
		if (combat->enemyID == 12) {
			trap->SendServerCommand(player->s.number,
				"print \"^2You survived.^7\n\n"
				"The Stalker laughs - a hollow, broken sound.\n"
				"^5\"The Holocron wants you alive. For now.\"^7\n\n"
				"They fade into smoke.\n\n"
				"^3[You feel the Stalker's presence recede... but they will return.]^7\n\n\"");

			// Increase paranoia from encounter
			G_RPG_ModifyParanoia(&game->player, 10);

			// No XP for surviving (they didn't die)
		}
		// Check if this was a hallucination combat
		else if (combat->enemyID == ENEMY_ID_HALLUCINATION) {
			// Defeating your fears reduces paranoia
			G_RPG_ModifyParanoia(&game->player, -15);

			trap->SendServerCommand(player->s.number,
				"print \"^2The shadows dissipate. It wasn't real... this time.^7\n"
				"^2[Paranoia decreased]^7\n\n\"");

			// No XP or credits for hallucinations
		} else {
			// Normal enemy - award XP, credits, loot
			if (G_RPG_ValidateEnemyID(game, combat->enemyID)) {
				rpgEnemy_t *enemy = &game->enemies[combat->enemyID];

				// Award XP
				G_RPG_AddXP(&game->player, enemy->xpReward);

				// Award credits
				if (enemy->creditReward > 0) {
					game->player.credits += enemy->creditReward;
					trap->SendServerCommand(player->s.number,
						va("print \"^3+%d credits^7\n\"", enemy->creditReward));
				}

				// Award loot (roll for each loot item)
				for (int i = 0; i < 5; i++) {
					if (enemy->lootItems[i] >= 0 && enemy->lootChance[i] > 0) {
						int roll = rand() % 100;
						if (roll < enemy->lootChance[i]) {
							// Player gets the loot!
							if (game->player.inventoryCount < MAX_INVENTORY_SIZE) {
								int lootID = enemy->lootItems[i];
								if (G_RPG_ValidateItemID(game, lootID)) {
									game->player.inventory[game->player.inventoryCount++] = lootID;
									trap->SendServerCommand(player->s.number,
										va("print \"^2Found: %s^7\n\"", game->items[lootID].name));
								}
							}
						}
					}
				}
			} else {
				// Fallback if enemy ID is invalid
				G_RPG_AddXP(&game->player, 100);
				game->player.credits += 50;
			}
		}

		// Auto-save after combat victory
		G_RPG_SaveGame(player);
	}

	combat->active = qfalse;
	game->state = RPG_STATE_EXPLORATION;
	game->selection = 0;
}

/*
================
G_RPG_CalculateDamage
================
*/
int G_RPG_CalculateDamage(rpgGame_t *game, rpgPlayer_t *player, int baseDamage) {
	int strMod = G_RPG_GetStatModifier(player->stats[STAT_STRENGTH]);
	int damage = baseDamage + strMod * 2;

	// Add weapon damage if equipped
	if (player->equipped[SLOT_WEAPON] >= 0) {
		int weaponID = player->equipped[SLOT_WEAPON];
		if (G_RPG_ValidateItemID(game, weaponID)) {
			damage += game->items[weaponID].damage;
		}
	}

	return damage > 0 ? damage : 1;
}

/*
================
G_RPG_CalculateDefense
================
*/
int G_RPG_CalculateDefense(rpgGame_t *game, rpgPlayer_t *player) {
	int def = 10;  // Base AC

	def += G_RPG_GetStatModifier(player->stats[STAT_DEXTERITY]);

	if (player->equipped[SLOT_ARMOR] >= 0) {
		int armorID = player->equipped[SLOT_ARMOR];
		if (G_RPG_ValidateItemID(game, armorID)) {
			def += game->items[armorID].defense;
		}
	}

	return def;
}

/*
================
G_RPG_CalculateWeight
Calculate total weight of all items in inventory and equipped
================
*/
int G_RPG_CalculateWeight(rpgGame_t *game, rpgPlayer_t *player) {
	int totalWeight = 0;

	// Add weight from inventory items
	for (int i = 0; i < player->inventoryCount && i < MAX_INVENTORY_SIZE; i++) {
		int itemID = player->inventory[i];
		if (G_RPG_ValidateItemID(game, itemID)) {
			totalWeight += game->items[itemID].weight;
		}
	}

	// Add weight from equipped items
	for (int slot = 0; slot < SLOT_MAX; slot++) {
		if (player->equipped[slot] >= 0) {
			int itemID = player->equipped[slot];
			if (G_RPG_ValidateItemID(game, itemID)) {
				totalWeight += game->items[itemID].weight;
			}
		}
	}

	return totalWeight;
}

// =============================================================================
// GAME MECHANICS
// =============================================================================

/*
================
G_RPG_MoveToRoom
================
*/
void G_RPG_MoveToRoom(gentity_t *player, rpgGame_t *game, int roomID) {
	if (roomID < 0 || roomID >= game->roomCount) {
		return;
	}

	rpgRoom_t *newRoom = &game->rooms[roomID];

	// Check requirements
	if (newRoom->requiresKey && newRoom->requiredItem >= 0) {
		if (!G_RPG_HasItem(&game->player, newRoom->requiredItem)) {
			// Can't enter, missing item
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^1This area is locked.^7");
			game->messageDisplayUntil = level.time + 2000;
			return;
		}
	}

	// =============================================================================
	// ACT 3: NON-EUCLIDEAN WISDOM CHECK (Escape the loop)
	// =============================================================================
	// Room 41 (Tomb Chamber IV) -> Room 42 (Inner Sanctum) requires Wisdom 14+
	// If failed, loop restarts at Room 37
	if (game->player.currentRoom == 41 && roomID == 42) {
		int wisdomStat = game->player.stats[STAT_WISDOM];

		if (wisdomStat < 14) {
			// FAIL: Loop back to Room 37
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^1YOU CANNOT PERCEIVE THE PATTERN.^7\n"
				"The geometry twists. Forward becomes backward.\n"
				"^8[Wisdom check failed: %d/14]^7", wisdomStat);
			game->messageDisplayUntil = level.time + 4000;

			// Force loop restart
			roomID = 37;
			newRoom = &game->rooms[37];

			// Add paranoia for experiencing impossible geometry
			G_RPG_ModifyParanoia(&game->player, 5);
		} else {
			// SUCCESS: Breakthrough message
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^2YOU SEE THE PATTERN.^7\n"
				"The loop is an illusion. You step through the deception.\n"
				"^8[Wisdom check passed: %d/14]^7", wisdomStat);
			game->messageDisplayUntil = level.time + 4000;
		}
	}

	// =============================================================================
	// ACT 5: TRUTH ENDING CIPHER REQUIREMENT
	// =============================================================================
	// Room 50 (Choice Chamber) -> Room 54 (Truth Ending) requires truthUnlocked flag
	if (game->player.currentRoom == 50 && roomID == 54) {
		if (!game->truthUnlocked) {
			// LOCKED: Cipher not entered
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^1THE DOOR IS SEALED.^7\n"
				"Ancient glyphs pulse on the surface:\n"
				"^3'SPEAK THE NAME OF THE BETRAYER'^7\n\n"
				"^8[Cipher required - find the 9-digit code]^7");
			game->messageDisplayUntil = level.time + 5000;
			return;  // Block movement
		}
	}

	// Move player
	game->player.currentRoom = roomID;

	// Mark room as visited
	newRoom->visited = qtrue;

	// Auto-save on room transition
	G_RPG_SaveGame(player);

	// Clear message
	game->messageText[0] = '\0';

	// =============================================================================
	// QUEST TRACKING - Update objectives based on room entered
	// =============================================================================

	// Main Quest: The Sith Holocron
	if (game->quests[0].state == QUEST_ACTIVE) {
		// Objective 0: Travel to crash site (Room 5)
		if (roomID == 5 && !game->quests[0].objectiveComplete[0]) {
			game->quests[0].objectiveComplete[0] = qtrue;
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^2[Quest Updated: The Sith Holocron]^7");
			game->messageDisplayUntil = level.time + 3000;
		}

		// Objective 1: Search the crashed ship (Room 6)
		if (roomID == 6 && !game->quests[0].objectiveComplete[1]) {
			game->quests[0].objectiveComplete[1] = qtrue;
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^2[Quest Updated: The Sith Holocron]^7");
			game->messageDisplayUntil = level.time + 3000;
		}
	}

	// =============================================================================
	// RANDOM ENCOUNTERS - Chance to trigger combat
	// =============================================================================

	// Room 4: Path to Caves (50% kinrath encounter)
	if (roomID == 4 && !newRoom->visited) {
		int roll = rand() % 100;
		if (roll < 50) {
			G_RPG_StartCombat(player, 0);  // Start combat with Kinrath (enemy 0)
			return;  // Combat started, skip normal room display
		}
	}

	// Room 13: Dantooine Fields (guaranteed kinrath encounter first visit)
	if (roomID == 13 && !newRoom->visited) {
		G_RPG_StartCombat(player, 0);  // Start combat with Kinrath (enemy 0)
		return;  // Combat started, skip normal room display
	}

	// =============================================================================
	// AMBIENT MESSAGES WITH COOLDOWNS
	// =============================================================================
	rpgPlayer_t *p = &game->player;

	// Paranoia ambient messages (every 30 seconds)
	if (p->paranoiaLevel >= 50 && level.time > game->lastAmbientMessageTime + 30000) {
		int roll = rand() % 100;
		if (roll < 30) {  // 30% chance every cooldown period
			const char *messages[] = {
				"^1[You feel like someone is watching you.]^7",
				"^1[The shadows seem darker than they should be.]^7",
				"^1[Did something just move in the corner of your vision?]^7",
				"^1[Your hands are shaking. Why are they shaking?]^7",
				"^5[The Holocron pulses with dark energy.]^7"
			};
			int msgIndex = rand() % 5;
			trap->SendServerCommand(player->s.number, va("print \"%s\n\"", messages[msgIndex]));
			game->lastAmbientMessageTime = level.time;
		}
	}

	// Holocron whispers (every 45 seconds, high paranoia only)
	if (p->paranoiaLevel >= 70 && level.time > game->lastHolocronWhisperTime + 45000) {
		int roll = rand() % 100;
		if (roll < 25) {  // 25% chance
			const char *whispers[] = {
				"^5[You hear whispers: 'They know what you did...']^7",
				"^5[The Holocron speaks: 'You cannot escape your fate.']^7",
				"^5[A voice echoes: 'The Jedi lied to you.']^7",
				"^5[Whispers surround you: 'Trust no one.']^7",
				"^1[The Holocron laughs. You didn't imagine it.]^7"
			};
			int msgIndex = rand() % 5;
			trap->SendServerCommand(player->s.number, va("print \"%s\n\"", whispers[msgIndex]));
			game->lastHolocronWhisperTime = level.time;
		}
	}

	// Act 2: Whispering crowd (Onderon/Iziz only, every 40 seconds)
	if (game->currentAct >= 2 && p->currentRoom >= 26 && p->currentRoom <= 35) {
		if (level.time > game->lastCrowdWhisperTime + 40000) {
			int roll = rand() % 100;
			if (roll < 20) {  // 20% chance
				const char *crowdMessages[] = {
					"^1[The crowd parts around you. They're all staring.]^7",
					"^1[Someone in the crowd whispers your name. How do they know?]^7",
					"^5[You see yourself in the crowd. Your reflection nods at you.]^7",
					"^1[Everyone stops moving. For just a moment. Then they continue like nothing happened.]^7"
				};
				int msgIndex = rand() % 4;
				trap->SendServerCommand(player->s.number, va("print \"%s\n\"", crowdMessages[msgIndex]));
				game->lastCrowdWhisperTime = level.time;
			}
		}
	}

	// Hallucination combat trigger (Act 3+, very rare, every 60 seconds)
	if (game->currentAct >= 3 && p->paranoiaLevel >= 80) {
		if (level.time > game->lastHallucinationTime + 60000) {
			int roll = rand() % 100;
			if (roll < 10 && !game->combat.active) {  // 10% chance, not during combat
				// Trigger hallucination combat with "The Stalker" enemy
				if (G_RPG_ValidateEnemyID(game, 6)) {  // Enemy 6 is "The Stalker"
					trap->SendServerCommand(player->s.number,
						"print \"^1[A figure in tattered robes steps from the shadows.]^7\n\"");
					G_RPG_StartCombat(player, 6);
					game->lastHallucinationTime = level.time;
					return;  // Combat started, skip rest
				}
			}
		}
	}
}

/*
================
G_RPG_UseItem
Handle using/equipping items from inventory
================
*/
void G_RPG_UseItem(rpgGame_t *game, int itemID) {
	if (!G_RPG_ValidateItemID(game, itemID)) {
		return;
	}

	rpgItem_t *item = &game->items[itemID];
	rpgPlayer_t *p = &game->player;

	switch (item->type) {
		case ITEM_CONSUMABLE:
			{
				// Use consumable (heals HP/FP)
				qboolean used = qfalse;

				if (item->healing > 0 && p->hp < p->maxHP) {
					p->hp += item->healing;
					if (p->hp > p->maxHP) p->hp = p->maxHP;
					used = qtrue;
				}

				if (item->fpRestore > 0 && p->fp < p->maxFP) {
					p->fp += item->fpRestore;
					if (p->fp > p->maxFP) p->fp = p->maxFP;
					used = qtrue;
				}

				// Special item effects
				if (itemID == 10) {
					// Item 10: Medical Injector (Sedative)
					// Reduces paranoia by 20, adds Dark Side points +5
					G_RPG_ModifyParanoia(p, -20);
					p->alignment -= 5;
					used = qtrue;
				}
				else if (itemID == 16) {
					// Item 16: Eternal Sith Candle
					// Grants +2 max FP, erases random completed quest
					p->maxFP += 2;
					p->fp += 2;

					// Erase random completed quest (memory loss)
					int completedQuests[MAX_RPG_QUESTS];
					int completedCount = 0;
					for (int i = 0; i < game->questCount; i++) {
						if (game->quests[i].state == QUEST_COMPLETED) {
							completedQuests[completedCount++] = i;
						}
					}

					if (completedCount > 0) {
						int randomIndex = rand() % completedCount;
						int questToErase = completedQuests[randomIndex];
						game->quests[questToErase].state = QUEST_INACTIVE;

						// Reset objectives
						for (int i = 0; i < game->quests[questToErase].objectiveCount; i++) {
							game->quests[questToErase].objectiveComplete[i] = qfalse;
						}
					}

					used = qtrue;
				}

				if (used) {
					// Remove from inventory
					for (int i = 0; i < p->inventoryCount; i++) {
						if (p->inventory[i] == itemID) {
							// Shift items down
							for (int j = i; j < p->inventoryCount - 1; j++) {
								p->inventory[j] = p->inventory[j + 1];
							}
							p->inventoryCount--;
							break;
						}
					}

					game->messageText[0] = '\0';  // Clear any existing message
				}
			}
			break;

		case ITEM_WEAPON:
		case ITEM_LIGHTSABER:
			// Equip weapon
			if (p->equipped[SLOT_WEAPON] >= 0) {
				// Unequip current weapon back to inventory
				if (p->inventoryCount < MAX_INVENTORY_SIZE) {
					p->inventory[p->inventoryCount++] = p->equipped[SLOT_WEAPON];
				}
			}

			// Remove from inventory
			for (int i = 0; i < p->inventoryCount; i++) {
				if (p->inventory[i] == itemID) {
					for (int j = i; j < p->inventoryCount - 1; j++) {
						p->inventory[j] = p->inventory[j + 1];
					}
					p->inventoryCount--;
					break;
				}
			}

			// Equip new weapon
			p->equipped[SLOT_WEAPON] = itemID;

			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^2Equipped: %s^7", item->name);
			game->messageDisplayUntil = level.time + 2000;
			break;

		case ITEM_ARMOR:
			// Equip armor
			if (p->equipped[SLOT_ARMOR] >= 0) {
				// Unequip current armor back to inventory
				if (p->inventoryCount < MAX_INVENTORY_SIZE) {
					p->inventory[p->inventoryCount++] = p->equipped[SLOT_ARMOR];
				}
			}

			// Remove from inventory
			for (int i = 0; i < p->inventoryCount; i++) {
				if (p->inventory[i] == itemID) {
					for (int j = i; j < p->inventoryCount - 1; j++) {
						p->inventory[j] = p->inventory[j + 1];
					}
					p->inventoryCount--;
					break;
				}
			}

			// Equip new armor
			p->equipped[SLOT_ARMOR] = itemID;

			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^2Equipped: %s^7", item->name);
			game->messageDisplayUntil = level.time + 2000;
			break;

		case ITEM_QUEST:
			// Quest items can't be used
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^3%s is a quest item.^7", item->name);
			game->messageDisplayUntil = level.time + 2000;
			break;

		case ITEM_CRYSTAL:
			// TODO: Lightsaber crystal installation (requires lightsaber upgrade system)
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^3Lightsaber crystals require a lightsaber workbench.^7");
			game->messageDisplayUntil = level.time + 2000;
			break;

		case ITEM_MISC:
		default:
			// Can't use misc items
			Com_sprintf(game->messageText, sizeof(game->messageText),
				"^3You can't use this item.^7");
			game->messageDisplayUntil = level.time + 2000;
			break;
	}
}

/*
================
G_RPG_EndDialogue
================
*/
void G_RPG_EndDialogue(rpgGame_t *game) {
	game->dialogue.active = qfalse;
	game->state = RPG_STATE_EXPLORATION;
	game->selection = 0;
}

/*
================
G_RPG_StartCombat
Initialize combat encounter with specified enemy
Returns qtrue if combat started successfully, qfalse otherwise
================
*/
void G_RPG_StartCombat(gentity_t *player, int enemyID) {
	rpgGame_t *game = &player->client->rpg;
	rpgCombat_t *combat = &game->combat;

	// FIX: Prevent starting combat if already in combat
	if (combat->active || game->state == RPG_STATE_COMBAT) {
		return;
	}

	// =============================================================================
	// JEDI SHADOW STALKER (ID 12) - Act 2 boss, survival fight
	// =============================================================================
	if (enemyID == 12) {
		// Initialize combat state - you cannot kill them, only survive 5 turns
		combat->active = qtrue;
		combat->enemyID = 12;
		Q_strncpyz(combat->enemyName, "Jedi Shadow (Corrupted)", sizeof(combat->enemyName));
		combat->enemyHP = 9999;  // Unkillable
		combat->enemyMaxHP = 9999;
		combat->enemyDamage = 15 + game->player.level;
		combat->enemyDefense = 10;

		combat->playerTurn = qtrue;
		combat->turnCount = 0;
		combat->playerDefending = qfalse;
		combat->enemyStunned = qfalse;

		// Initialize first telegraph
		combat->selectedPower = rand() % 3;

		// Clear result message
		combat->lastActionResult[0] = '\0';

		// Switch to combat state
		game->state = RPG_STATE_COMBAT;
		game->selection = 0;

		// Send combat start message
		trap->SendServerCommand(player->s.number,
			"print \"\n^1=== THE STALKER ===^7\n"
			"A figure in tattered brown robes. The Jedi Shadow from the crash.\n"
			"^5Their eyes glow purple. The Holocron resurrected them.^7\n\n"
			"^3[SURVIVE 5 TURNS]^7\n\n\"");

		G_RPG_RefreshDisplay(player);
		return;
	}

	// =============================================================================
	// HALLUCINATION ENEMY (ID 99) - Hardcoded to prevent array overflow
	// =============================================================================
	if (enemyID == ENEMY_ID_HALLUCINATION) {
		// Initialize combat state with hardcoded hallucination values
		combat->active = qtrue;
		combat->enemyID = ENEMY_ID_HALLUCINATION;
		Q_strncpyz(combat->enemyName, "Shadow of Your Fear", sizeof(combat->enemyName));
		combat->enemyHP = 20 + (game->player.level * 5);  // Scales with player level
		combat->enemyMaxHP = combat->enemyHP;
		combat->enemyDamage = 8 + game->player.level;
		combat->enemyDefense = 2 + game->player.level;

		combat->playerTurn = qtrue;
		combat->turnCount = 0;
		combat->playerDefending = qfalse;
		combat->enemyStunned = qfalse;

		// Initialize first telegraph (random move)
		combat->selectedPower = rand() % 3;  // 0=Lunge, 1=Charge, 2=Leap

		// Clear result message
		combat->lastActionResult[0] = '\0';

		// Switch to combat state
		game->state = RPG_STATE_COMBAT;
		game->selection = 0;

		// Send combat start message
		trap->SendServerCommand(player->s.number,
			"print \"\n^5=== HALLUCINATION ===^7\n"
			"^1The shadows take form. Your worst fears manifest before you.^7\n\n\"");

		G_RPG_RefreshDisplay(player);
		return;  // Exit early, don't access game->enemies[] array
	}

	// =============================================================================
	// NORMAL ENEMY - Bounds check then array lookup
	// =============================================================================
	if (enemyID < 0 || enemyID >= game->enemyCount) {
		return;
	}

	rpgEnemy_t *enemy = &game->enemies[enemyID];

	// Initialize combat state
	combat->active = qtrue;
	combat->enemyID = enemyID;
	Q_strncpyz(combat->enemyName, enemy->name, sizeof(combat->enemyName));
	combat->enemyHP = enemy->hp;
	combat->enemyMaxHP = enemy->hp;
	combat->enemyDamage = enemy->damage;
	combat->enemyDefense = enemy->defense;

	combat->playerTurn = qtrue;
	combat->turnCount = 0;
	combat->playerDefending = qfalse;
	combat->enemyStunned = qfalse;

	// Initialize first telegraph (random move)
	combat->selectedPower = rand() % 3;  // 0=Lunge, 1=Charge, 2=Leap

	// Clear result message
	combat->lastActionResult[0] = '\0';

	// Switch to combat state
	game->state = RPG_STATE_COMBAT;
	game->selection = 0;

	// Send combat start message
	trap->SendServerCommand(player->s.number,
		va("print \"\n^1=== COMBAT START ===^7\n%s attacks!\n\n\"", enemy->name));

	G_RPG_RefreshDisplay(player);
}

/*
================
G_RPG_ShowNPCDialogue

Load and display NPC dialogue based on node ID
This implements branching conversation trees with:
- Alignment-based choices (Light/Dark side)
- Skill checks (Persuade, Threaten based on CHA/INT)
- Quest progression
- Reputation changes
================
*/
void G_RPG_ShowNPCDialogue(gentity_t *player, int npcID, int nodeID) {
	rpgGame_t *game = &player->client->rpg;
	rpgDialogue_t *dlg = &game->dialogue;
	rpgPlayer_t *p = &game->player;
	char buffer[RPG_MAX_DISPLAY];

	// Clear previous dialogue
	dlg->choiceCount = 0;

	// =========================================================================
	// ADMINISTRATOR ADARE (NPC ID 0) - Main Quest Giver
	// =========================================================================
	if (npcID == 0) {
		switch (nodeID) {
			case 0:  // Initial greeting
				Q_strncpyz(dlg->npcText,
					"^6Administrator Adare^7 looks up from her datapad, her face drawn with worry.\n\n"
					"\"You there! Are you the one who just arrived? I'm Administrator Adare, "
					"and we have a serious situation. Two days ago, a ship crashed in the fields "
					"east of here. No survivors... except one. A single escape pod was found, "
					"but whoever was inside is ^1gone^7. And whatever ^1cargo^7 they carried with them... "
					"I can ^5feel^7 it. Something ^1dark^7.\"",
					sizeof(dlg->npcText));

				// Choice 0: Normal response
				Q_strncpyz(dlg->choiceText[0], "\"I'll investigate the crash site.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 1;
				dlg->choiceAlignmentChange[0] = 2;  // +2 Light
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				// Choice 1: Ask for payment (Neutral)
				Q_strncpyz(dlg->choiceText[1], "\"What's in it for me?\"", 128);
				dlg->choiceType[1] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[1] = 2;
				dlg->choiceAlignmentChange[1] = 0;
				dlg->choiceRequiredStat[1] = -1;
				dlg->choiceCount++;

				// Choice 2: Dark side response
				Q_strncpyz(dlg->choiceText[2], "\"This sounds like your problem, not mine.\"", 128);
				dlg->choiceType[2] = DIALOGUE_DARK;
				dlg->choiceNextNode[2] = 3;
				dlg->choiceAlignmentChange[2] = -3;  // -3 Dark
				dlg->choiceRequiredStat[2] = -1;
				dlg->choiceCount++;

				// Choice 3: Force Insight (high Wisdom)
				if (p->stats[STAT_WISDOM] >= 14) {
					Q_strncpyz(dlg->choiceText[3], "^5[Force Insight]^7 \"You're afraid. What aren't you telling me?\"", 128);
					dlg->choiceType[3] = DIALOGUE_NORMAL;
					dlg->choiceNextNode[3] = 4;
					dlg->choiceAlignmentChange[3] = 0;
					dlg->choiceRequiredStat[3] = STAT_WISDOM;
					dlg->choiceRequiredValue[3] = 14;
					dlg->choiceCount++;
				}

				// Choice 4: End conversation
				Q_strncpyz(dlg->choiceText[dlg->choiceCount], "\"I need to think about this.\"", 128);
				dlg->choiceType[dlg->choiceCount] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[dlg->choiceCount] = -1;  // Exit dialogue
				dlg->choiceAlignmentChange[dlg->choiceCount] = 0;
				dlg->choiceRequiredStat[dlg->choiceCount] = -1;
				dlg->choiceCount++;
				break;

			case 1:  // Accepted quest - Light side
				Q_strncpyz(dlg->npcText,
					"Adare's expression softens slightly.\n\n"
					"\"Thank you. I was hoping someone capable would arrive. The crash site is "
					"just east of the main gates, past the kinrath breeding grounds. Be careful out "
					"there - the kinrath have been more aggressive since the crash. "
					"^1Something is drawing them.^7\n\n"
					"If you find anything... ^1anything at all^7... bring it to me immediately. "
					"The Republic needs to know what happened here.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I'll report back soon.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				// Activate main quest
				game->quests[0].state = QUEST_ACTIVE;
				game->quests[0].objectiveComplete[0] = qfalse;
				game->player.reputation[FACTION_REPUBLIC] += 5;
				break;

			case 2:  // Asked for payment
				Q_strncpyz(dlg->npcText,
					"Adare frowns, but reaches for a credit chip.\n\n"
					"\"Fine. I'll pay you ^3500 credits^7 to investigate and report back. "
					"But understand this isn't just about money. If whatever came off that ship "
					"reaches the settlement... we're all in danger.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"Fair enough. I'll check it out.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				// Activate quest with payment flag
				game->quests[0].state = QUEST_ACTIVE;
				game->quests[0].objectiveComplete[0] = qfalse;
				game->player.credits += 250;  // Half upfront
				break;

			case 3:  // Refused - Dark side
				Q_strncpyz(dlg->npcText,
					"Adare's face hardens with anger and fear.\n\n"
					"\"Then get out of my office. When the darkness comes for this settlement, "
					"remember that you ^1could have stopped it^7.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "[Leave]", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				game->player.reputation[FACTION_REPUBLIC] -= 10;
				break;

			case 4:  // Force Insight - reveals hidden info
				Q_strncpyz(dlg->npcText,
					"Adare's eyes widen in surprise. She hesitates, then speaks in a lower voice.\n\n"
					"\"You're... you're Force-sensitive. I should have known. Yes, you're right. "
					"I ^5felt^7 it too. Whatever was in that cargo hold... it's a ^1Sith artifact^7. "
					"I was a Padawan, years ago, before the Purge. I know the taste of the dark side.\n\n"
					"The Republic will send a recovery team, but it will take days. By then, "
					"whoever took that artifact could have it off-world. Or worse... ^1activated it^7. "
					"You have to find it first.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I understand. I'll find it.\"", 128);
				dlg->choiceType[0] = DIALOGUE_LIGHT;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 3;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				// Activate quest with bonus info
				game->quests[0].state = QUEST_ACTIVE;
				game->quests[0].objectiveComplete[0] = qfalse;
				game->player.reputation[FACTION_JEDI] += 10;
				game->player.xp += 50;  // Bonus XP for using wisdom
				break;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				dlg->choiceCount = 0;
				break;
		}
	}

	// =========================================================================
	// MERCHANT GORAN (NPC ID 1) - General Goods Trader
	// =========================================================================
	else if (npcID == 1) {
		switch (nodeID) {
			case 0:  // Initial greeting
				Q_strncpyz(dlg->npcText,
					"^6Merchant Goran^7 looks up from polishing a vibroblade, his weathered face "
					"breaking into a practiced smile.\n\n"
					"\"Welcome, welcome! I'm Goran, finest trader on Dantooine. Got supplies, "
					"weapons, armor - whatever you need to survive out there. Just came from Onderon, "
					"fresh stock! What can I do for you?\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"Let me see your wares.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[1], "\"Tell me about yourself.\"", 128);
				dlg->choiceType[1] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[1] = 2;
				dlg->choiceAlignmentChange[1] = 0;
				dlg->choiceRequiredStat[1] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[2], "\"Heard anything interesting?\"", 128);
				dlg->choiceType[2] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[2] = 3;
				dlg->choiceAlignmentChange[2] = 0;
				dlg->choiceRequiredStat[2] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[3], "[Leave]", 128);
				dlg->choiceType[3] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[3] = -1;
				dlg->choiceAlignmentChange[3] = 0;
				dlg->choiceRequiredStat[3] = -1;
				dlg->choiceCount++;
				break;

			case 1:  // Shop menu - Enter shop state
				// End dialogue and enter shop
				game->dialogue.active = qfalse;
				game->state = RPG_STATE_SHOP;
				game->selection = 0;

				trap->SendServerCommand(player->s.number,
					"print \"^6Merchant Goran^7 gestures to his wares.\n\n"
					"\"Browse all you like! I've got medical supplies, lightsaber crystals, "
					"and other useful equipment. Credits are good, but I also remember my friends...\"\n\n\"");
				return;  // Don't process dialogue choices, we're entering shop

			case 2:  // Personal story
				Q_strncpyz(dlg->npcText,
					"Goran leans back, his expression turning nostalgic.\n\n"
					"\"Used to run with a crew, back in the day. Freelance work - salvage, transport, "
					"occasional 'acquisitions' if you catch my drift. Lost them during the war. "
					"Now I stick to honest trading... ^2mostly^7. Dantooine's quiet, and after "
					"everything I've seen, quiet's good.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"Sounds like you've seen action.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 0;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;
				break;

			case 3:  // Rumors and information
				Q_strncpyz(dlg->npcText,
					"Goran glances around and lowers his voice.\n\n"
					"\"Between you and me? Something's off with that crash. I've seen plenty of "
					"wrecks, and that one... the scorch patterns are all wrong. That wasn't engine "
					"failure. Someone ^1shot that ship down^7. And the Exchange has been sniffing "
					"around, asking questions. Whatever was on that ship, it's ^3valuable^7.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"Thanks for the tip.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 0;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				game->player.xp += 25;  // Info bonus
				break;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				break;
		}
	}

	// =========================================================================
	// ATTON RAND (NPC ID 2) - Potential Companion
	// =========================================================================
	else if (npcID == 2) {
		switch (nodeID) {
			case 0:  // Initial greeting
				Q_strncpyz(dlg->npcText,
					"The scarred veteran doesn't look up from his drink. ^6Atton Rand^7's voice "
					"is rough, sardonic.\n\n"
					"\"Great, another hero. Let me guess - Administrator Adare sent you to 'investigate' "
					"the crash? Save the settlement? Be the big damn hero?\" He takes a long drink. "
					"\"I've seen heroes. They tend to end up ^1dead^7. Or worse.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"You sound like you've been through hell.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[1], "\"What's your problem?\"", 128);
				dlg->choiceType[1] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[1] = 2;
				dlg->choiceAlignmentChange[1] = 0;
				dlg->choiceRequiredStat[1] = -1;
				dlg->choiceCount++;

				if (p->stats[STAT_WISDOM] >= 14) {
					Q_strncpyz(dlg->choiceText[2], "^5[Force Insight]^7 \"You were Force-trained. I can sense it.\"", 128);
					dlg->choiceType[2] = DIALOGUE_NORMAL;
					dlg->choiceNextNode[2] = 3;
					dlg->choiceAlignmentChange[2] = 0;
					dlg->choiceRequiredStat[2] = STAT_WISDOM;
					dlg->choiceRequiredValue[2] = 14;
					dlg->choiceCount++;
				}

				Q_strncpyz(dlg->choiceText[dlg->choiceCount], "[Leave him alone]", 128);
				dlg->choiceType[dlg->choiceCount] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[dlg->choiceCount] = -1;
				dlg->choiceAlignmentChange[dlg->choiceCount] = 0;
				dlg->choiceRequiredStat[dlg->choiceCount] = -1;
				dlg->choiceCount++;
				break;

			case 1:  // Sympathetic response
				Q_strncpyz(dlg->npcText,
					"Atton's expression softens slightly, but his eyes remain guarded.\n\n"
					"\"Yeah. War does that. I flew for the Republic during the Mandalorian Wars. "
					"Saw things... did things... that stick with you. Now I just want to drink "
					"and be left alone.\" He pauses. \"But if you're really going after that crash, "
					"you might need someone who knows how to ^2survive^7. I'll think about it.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I could use someone with experience.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 4;
				dlg->choiceAlignmentChange[0] = 2;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[1], "\"Let me know if you change your mind.\"", 128);
				dlg->choiceType[1] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[1] = -1;
				dlg->choiceAlignmentChange[1] = 0;
				dlg->choiceRequiredStat[1] = -1;
				dlg->choiceCount++;

				game->player.reputation[FACTION_REPUBLIC] += 2;
				break;

			case 2:  // Hostile response
				Q_strncpyz(dlg->npcText,
					"Atton's eyes narrow dangerously.\n\n"
					"\"My problem? My problem is people who don't know when to shut up and leave. "
					"Go play hero somewhere else, kid. This is my table.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "[Leave]", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = -1;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;
				break;

			case 3:  // Force Insight - reveals hidden past
				Q_strncpyz(dlg->npcText,
					"Atton's face goes pale, then hardens into a mask of anger and fear.\n\n"
					"\"Stay ^1out^7 of my head, Jedi!\" His hand moves toward his blaster, then stops. "
					"He takes a shaky breath. \"How did you... never mind. Yeah. I was trained. "
					"Not by ^2your kind^7. Let's leave it at that.\" His voice drops to barely a whisper. "
					"\"If you're smart, you'll forget what you sensed. And you'll ^1never^7 do that again.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I'm sorry. I didn't mean to intrude.\"", 128);
				dlg->choiceType[0] = DIALOGUE_LIGHT;
				dlg->choiceNextNode[0] = 5;
				dlg->choiceAlignmentChange[0] = 2;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[1], "\"What did they train you for?\"", 128);
				dlg->choiceType[1] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[1] = -1;
				dlg->choiceAlignmentChange[1] = 0;
				dlg->choiceRequiredStat[1] = -1;
				dlg->choiceCount++;

				game->player.xp += 50;  // Major secret discovered
				break;

			case 4:  // Recruitment (sympathetic path)
				Q_strncpyz(dlg->npcText,
					"Atton considers you for a long moment, then sighs.\n\n"
					"\"Alright. ^2Alright^7. I can't just sit here while another idiot gets themselves "
					"killed. I'll come along. But we do this smart - no heroics, no sacrifices. "
					"We get in, we get out, we survive. Deal?\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"Deal. Welcome aboard.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				// Add Atton as companion
				if (game->player.companionCount < MAX_RPG_COMPANIONS) {
					game->player.companionIDs[game->player.companionCount++] = 2;  // Atton = NPC ID 2
					game->player.activeCompanion = 0;  // Index in companionIDs array
					trap->SendServerCommand(player->s.number,
						"print \"^2[Atton Rand has joined your party]^7\n\n\"");
				}
				game->player.xp += 100;  // Companion recruited
				break;

			case 5:  // Apology after Force Insight
				Q_strncpyz(dlg->npcText,
					"Atton relaxes slightly, though suspicion remains in his eyes.\n\n"
					"\"Yeah. Well. Just... don't do it again.\" He takes another drink. "
					"\"Look, if you're going out there, you should know - whoever took that artifact "
					"knows what they're doing. Professional. Military training. I'd know.\" "
					"He meets your eyes. \"Watch your back out there.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"Thanks for the warning.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				game->player.xp += 25;
				break;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				break;
		}
	}

	// =========================================================================
	// JETH - DUROS SCHOLAR (NPC ID 3) - Act 2 Quest Giver
	// =========================================================================
	else if (npcID == 3) {
		switch (nodeID) {
			case 0:  // Initial greeting
				Q_strncpyz(dlg->npcText,
					"^6Jeth^7 looks up from his datapad, his red eyes widening at the sight of you.\n\n"
					"\"You... you're the one they're all talking about. The one with the ^1Holocron^7.\" "
					"He swallows nervously. \"I'm Jeth, a scholar. I've spent years studying Sith artifacts. "
					"What you're carrying... it's dangerous beyond measure. The knowledge inside could "
					"^1destroy^7 you. Or... if properly unlocked... teach you secrets the Sith buried millennia ago.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"How do I unlock it?\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 1;
				dlg->choiceAlignmentChange[0] = -2;  // Seeking dark knowledge
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[1], "\"I need to understand it to destroy it.\"", 128);
				dlg->choiceType[1] = DIALOGUE_LIGHT;
				dlg->choiceNextNode[1] = 2;
				dlg->choiceAlignmentChange[1] = 3;
				dlg->choiceRequiredStat[1] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[2], "[Leave]", 128);
				dlg->choiceType[2] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[2] = -1;
				dlg->choiceAlignmentChange[2] = 0;
				dlg->choiceRequiredStat[2] = -1;
				dlg->choiceCount++;
				break;

			case 1:  // How to unlock (Dark path)
				Q_strncpyz(dlg->npcText,
					"Jeth hesitates, then leans closer.\n\n"
					"\"The Holocron requires a ^5Force ritual^7. Blood, meditation, and a place of power. "
					"There's an ancient meditation chamber beneath the spaceport - Sith used it during "
					"the occupation. If you perform the ritual there... it will open. But be warned: "
					"the Holocron will ^1test^7 you. Show weakness, and it will ^1consume^7 you.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I understand. Thank you.\"", 128);
				dlg->choiceType[0] = DIALOGUE_DARK;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				game->player.xp += 100;
				G_RPG_ModifyParanoia(&game->player, 5);
				break;

			case 2:  // Destroy it (Light path)
				Q_strncpyz(dlg->npcText,
					"Jeth nods approvingly.\n\n"
					"\"Noble. Rare, these days. The Jedi Archives mention a ^2cleansing ritual^7 - "
					"it requires meditating with the Holocron at a place steeped in the ^2Light Side^7. "
					"The old enclave ruins outside the settlement would work. The ritual will reveal "
					"the Holocron's secrets... but also purge its corruption. Use that knowledge wisely.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"May the Force be with me.\"", 128);
				dlg->choiceType[0] = DIALOGUE_LIGHT;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				game->player.xp += 100;
				game->player.reputation[FACTION_JEDI] += 10;
				break;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				break;
		}
	}

	// =========================================================================
	// MIRA TOVAN - WITNESS (NPC ID 4) - Accuses player of blackout crime
	// =========================================================================
	else if (npcID == 4) {
		switch (nodeID) {
			case 0:  // Accusation
				Q_strncpyz(dlg->npcText,
					"^6Mira Tovan^7 stumbles backward, her face pale with terror.\n\n"
					"\"^1YOU!^7 I saw you! Last night, in the alley behind the cantina! "
					"You were standing over that merchant's body, your eyes... your eyes were ^5glowing^7! "
					"There was so much blood... and you just ^1smiled^7!\" She's shaking. "
					"\"The guards are looking for you! You're a ^1MONSTER^7!\"",
					sizeof(dlg->npcText));

				if (p->stats[STAT_CHARISMA] >= 14) {
					Q_strncpyz(dlg->choiceText[0], "^3[Persuade]^7 \"You're mistaken. I wasn't there.\"", 128);
					dlg->choiceType[0] = DIALOGUE_NORMAL;
					dlg->choiceNextNode[0] = 1;
					dlg->choiceAlignmentChange[0] = 0;
					dlg->choiceRequiredStat[0] = STAT_CHARISMA;
					dlg->choiceRequiredValue[0] = 14;
					dlg->choiceCount++;
				}

				Q_strncpyz(dlg->choiceText[dlg->choiceCount], "\"I don't remember anything from last night...\"", 128);
				dlg->choiceType[dlg->choiceCount] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[dlg->choiceCount] = 2;
				dlg->choiceAlignmentChange[dlg->choiceCount] = 0;
				dlg->choiceRequiredStat[dlg->choiceCount] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[dlg->choiceCount], "\"Keep your mouth shut, or you're next.\"", 128);
				dlg->choiceType[dlg->choiceCount] = DIALOGUE_DARK;
				dlg->choiceNextNode[dlg->choiceCount] = 3;
				dlg->choiceAlignmentChange[dlg->choiceCount] = -5;
				dlg->choiceRequiredStat[dlg->choiceCount] = -1;
				dlg->choiceCount++;

				G_RPG_ModifyParanoia(&game->player, 10);
				break;

			case 1:  // Persuasion success
				Q_strncpyz(dlg->npcText,
					"Mira hesitates, doubt creeping into her terrified expression.\n\n"
					"\"But... I saw... maybe it was dark? Maybe I was wrong?\" She wraps her arms around "
					"herself. \"The guards said there were ^5two sets of footprints^7. Identical. "
					"Like... like someone was mimicking you. I don't... I don't know what I saw anymore.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"Thank you for being honest.\"", 128);
				dlg->choiceType[0] = DIALOGUE_LIGHT;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 2;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;
				break;

			case 2:  // Admit memory loss
				Q_strncpyz(dlg->npcText,
					"Mira's terror turns to confusion.\n\n"
					"\"You... you don't remember? But I ^1saw^7 you! How can you not remember?\" "
					"She takes a shaky step back. \"What's happening to you? What's ^1wrong^7 with you?\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "[Leave]", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				G_RPG_ModifyParanoia(&game->player, 5);
				break;

			case 3:  // Threaten
				Q_strncpyz(dlg->npcText,
					"Mira goes even paler. She nods frantically, tears streaming down her face.\n\n"
					"\"I... I won't tell anyone! I promise! Please don't hurt me!\" "
					"She turns and ^1runs^7.",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "[She's gone]", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				game->player.reputation[FACTION_REPUBLIC] -= 15;
				break;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				break;
		}
	}

	// =========================================================================
	// CAPTAIN SAREN - SUSPICIOUS GUARD (NPC ID 5)
	// =========================================================================
	else if (npcID == 5) {
		switch (nodeID) {
			case 0:  // Initial confrontation
				if (p->paranoiaLevel > 50) {
					Q_strncpyz(dlg->npcText,
						"^6Captain Saren^7 steps in front of you, hand on his blaster.\n\n"
						"\"Hold it right there. I've seen the security footage. You match the description "
						"of someone wanted for ^1questioning^7 regarding last night's incident. "
						"Multiple witnesses. Bodies. You're coming with me.\"",
						sizeof(dlg->npcText));

					Q_strncpyz(dlg->choiceText[0], "\"I'm innocent!\"", 128);
					dlg->choiceType[0] = DIALOGUE_NORMAL;
					dlg->choiceNextNode[0] = 1;
					dlg->choiceAlignmentChange[0] = 0;
					dlg->choiceRequiredStat[0] = -1;
					dlg->choiceCount++;

					Q_strncpyz(dlg->choiceText[1], "\"You don't want to do this.\"", 128);
					dlg->choiceType[1] = DIALOGUE_DARK;
					dlg->choiceNextNode[1] = 2;
					dlg->choiceAlignmentChange[1] = -3;
					dlg->choiceRequiredStat[1] = -1;
					dlg->choiceCount++;
				} else {
					Q_strncpyz(dlg->npcText,
						"^6Captain Saren^7 nods curtly.\n\n"
						"\"Citizen. Stay out of trouble. We've got enough problems without offworlders "
						"causing chaos.\"",
						sizeof(dlg->npcText));

					Q_strncpyz(dlg->choiceText[0], "[Leave]", 128);
					dlg->choiceType[0] = DIALOGUE_NORMAL;
					dlg->choiceNextNode[0] = -1;
					dlg->choiceAlignmentChange[0] = 0;
					dlg->choiceRequiredStat[0] = -1;
					dlg->choiceCount++;
				}
				break;

			case 1:  // Deny accusations
				Q_strncpyz(dlg->npcText,
					"Saren's expression doesn't change.\n\n"
					"\"That's what they all say. Come quietly, and we'll sort this out at headquarters.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "[Comply]", 128);
				dlg->choiceType[0] = DIALOGUE_LIGHT;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 2;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;
				break;

			case 2:  // Intimidate
				Q_strncpyz(dlg->npcText,
					"Saren's hand tightens on his blaster, but fear flickers in his eyes.\n\n"
					"\"The higher-ups... they told me to let you pass. For now. But I'm watching you.\" "
					"He steps aside reluctantly.",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "[Leave]", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;
				break;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				break;
		}
	}

	// =========================================================================
	// RILA - STREET VENDOR (NPC ID 6)
	// =========================================================================
	else if (npcID == 6) {
		switch (nodeID) {
			case 0:  // Initial greeting
				if (p->alignment > 0) {
					Q_strncpyz(dlg->npcText,
						"^6Rila^7 smiles warmly at you.\n\n"
						"\"Welcome, friend! Looking for authentic Jedi artifacts? I have crystals, "
						"holocrons - well, ^2replicas^7 - and training manuals! Special prices for "
						"fellow Force-sensitives!\"",
						sizeof(dlg->npcText));
				} else {
					Q_strncpyz(dlg->npcText,
						"^6Rila^7's lekku twitch nervously as you approach.\n\n"
						"\"I... I have wares. But I don't serve... your kind. Please move along.\"",
						sizeof(dlg->npcText));
				}

				Q_strncpyz(dlg->choiceText[0], "\"Show me your goods.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				Q_strncpyz(dlg->choiceText[1], "[Leave]", 128);
				dlg->choiceType[1] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[1] = -1;
				dlg->choiceAlignmentChange[1] = 0;
				dlg->choiceRequiredStat[1] = -1;
				dlg->choiceCount++;
				break;

			case 1:  // Show wares (opens shop)
				game->dialogue.active = qfalse;
				game->state = RPG_STATE_SHOP;
				game->selection = 0;

				trap->SendServerCommand(player->s.number,
					"print \"^6Rila^7 displays her collection of artifacts and supplies.\n\n\"");
				return;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				break;
		}
	}

	// =========================================================================
	// DOCTOR VENN (NPC ID 7) - The Mimic Side Quest
	// =========================================================================
	else if (npcID == 7) {
		switch (nodeID) {
			case 0:  // Initial encounter
				Q_strncpyz(dlg->npcText,
					"^6Doctor Venn^7 looks exhausted, dark circles under her eyes.\n\n"
					"\"You. I need to ask you something. Last night, a patient was brought in - "
					"^1severe trauma^7, catatonic. Before they went unresponsive, they kept drawing "
					"the same thing over and over: a figure in robes with ^5glowing purple eyes^7. "
					"The description matches you ^1exactly^7. Were you involved?\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I don't know what you're talking about.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = 1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				if (p->stats[STAT_WISDOM] >= 14) {
					Q_strncpyz(dlg->choiceText[1], "^5[Force Insight]^7 \"Show me the drawing.\"", 128);
					dlg->choiceType[1] = DIALOGUE_NORMAL;
					dlg->choiceNextNode[1] = 2;
					dlg->choiceAlignmentChange[1] = 0;
					dlg->choiceRequiredStat[1] = STAT_WISDOM;
					dlg->choiceRequiredValue[1] = 14;
					dlg->choiceCount++;
				}

				Q_strncpyz(dlg->choiceText[dlg->choiceCount], "[Leave]", 128);
				dlg->choiceType[dlg->choiceCount] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[dlg->choiceCount] = -1;
				dlg->choiceAlignmentChange[dlg->choiceCount] = 0;
				dlg->choiceRequiredStat[dlg->choiceCount] = -1;
				dlg->choiceCount++;
				break;

			case 1:  // Deny involvement
				Q_strncpyz(dlg->npcText,
					"Doctor Venn studies you carefully.\n\n"
					"\"I believe you. But ^1someone^7 who looks exactly like you is hurting people. "
					"Be careful out there.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I will. Thank you.\"", 128);
				dlg->choiceType[0] = DIALOGUE_NORMAL;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 0;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;
				break;

			case 2:  // Force Insight path
				Q_strncpyz(dlg->npcText,
					"Venn shows you the sketch. Your blood runs cold. It's not just similar - "
					"it's ^1identical^7 to you. Same scars. Same robes. Even the same lightsaber hilt.\n\n"
					"\"There's something else,\" Venn says quietly. \"The attacker left traces of "
					"^5dark side energy^7. And... Holocron residue. Whatever you're carrying, "
					"it's creating ^1copies^7 of you. Twisted, violent copies.\"",
					sizeof(dlg->npcText));

				Q_strncpyz(dlg->choiceText[0], "\"I need to destroy the Holocron.\"", 128);
				dlg->choiceType[0] = DIALOGUE_LIGHT;
				dlg->choiceNextNode[0] = -1;
				dlg->choiceAlignmentChange[0] = 3;
				dlg->choiceRequiredStat[0] = -1;
				dlg->choiceCount++;

				game->player.xp += 100;
				G_RPG_ModifyParanoia(&game->player, 15);
				break;

			default:
				Q_strncpyz(dlg->npcText, "ERROR: Invalid dialogue node", sizeof(dlg->npcText));
				break;
		}
	}

	// Unknown NPC
	else {
		Q_strncpyz(dlg->npcText, "ERROR: Invalid NPC ID", sizeof(dlg->npcText));
		dlg->choiceCount = 0;
	}

	// Send NPC dialogue text to print (console/chat)
	trap->SendServerCommand(player->s.number, va("print \"\n%s\n\n\"", dlg->npcText));
}
