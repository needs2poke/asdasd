# RPG Story Review — Source-Verified Audit Prompt

You are reviewing an in-game text RPG called **"Echoes of the Dark Wars"** built inside a Star Wars: Jedi Academy multiplayer server mod (OpenJK fork). I want your **honest creative input** on the story, plus flaw identification (story logic, continuity, contradictions, Star Wars canon mismatches), and enhancement ideas.

This is a **brainstorming review**, not a code review. No code changes will be made based on your output. I'm going to feed your response back into another LLM to compare perspectives, so be specific and stand behind your reasoning.

---

## CRITICAL — How to do this review correctly

The previous LLM that reviewed this got a LOT wrong by trusting paraphrase over source. Do not repeat its mistakes:

1. **Read the actual source files.** Do not summarize what you "expect" the code to say. Open each file listed below and read it.
2. **Use case-insensitive grep** when searching. The original C code uses `DARTH SAEVUS` in all-caps; case-sensitive search misses it.
3. **A "no matches" grep result does not mean content is absent** — your pattern may be malformed. Verify by reading a sample of the file directly.
4. **Cite every claim with `file:line` references.** "The cipher is stingy" is an assertion; "`data/cipher.lua:9-13` shows only 4 sources for 9 digits" is a verified claim.
5. **If you cannot verify something, say "unverified" — do not guess.**
6. **Disagree with the prior review where you find evidence it's wrong.** I'm using you specifically as a second opinion. Don't just confirm; challenge.

---

## What this game is

- **Setting:** 3949 BBY — five years after Revan vanished into the Unknown Regions, two years after the events of KOTOR 2 (Meetra Surik/Exile)
- **Platform:** Text RPG accessed via in-game centerprint menu (`!rpg` command), runs inside a JKA multiplayer server
- **Stated genre fusion (per author):** KOTOR 1 (mystery, signature reveal) + KOTOR 2 (moral grey, philosophical) + Jedi: Survivor (Force-haunted protagonist) + Horror (paranoia, psychological cost of the Force)
- **Author's self-assessment:** "We were going for KOTOR 3 but it turned more into KOTOR 1 DLC with a horror twist." The author wants to know whether this self-assessment is accurate.

## Story summary (verified)

A Force-sensitive protagonist hiding on Dantooine finds a crashed Jedi Shadow holding a Sith Holocron. The Holocron contains the consciousness of **Darth Saevus the Forgotten**, a student of Sith Emperor Vitiate who learned the Nathema consumption ritual. Across 5 acts the player is hunted (Stalker), doppelgängered (Mimic), psychically fragmented (Rage/Fear/Despair), and eventually confronts a metafictional Watcher who questions whether their choices are real. Four endings: Light (sacrifice yourself, destroy Holocron), Dark (become Saevus's host), Horror (catatonic paranoia break), Truth (solve the 9-digit cipher to expel Saevus permanently).

---

## Source locations

- **Current implementation (Lua):** `F:\jka\Openjk-custom\base\glua\rpg\` — 67 files, ~32k LOC
- **Original codebase (C):** `F:\jka\Openjk-custom\forceunleashstart-main\codemp\game\g_rpg.c` (7364 lines) + `g_rpg.h` (632 lines)
- **Inspiration material in repo root:**
  - `Star Wars - Revan (by Drew Karpyshyn).pdf`
  - `Star Wars The Old Republic - Anihilation (by Drew Karpyshyn).pdf`
  - `annihilation_text.txt`

---

## Required reading (in priority order)

Read these files before forming opinions. File sizes provided so you know what you're getting into.

### Tier 1 — Story spine (read in full)
1. `base/glua/rpg/data/rooms.lua` (1122 lines) — all 55 rooms across 5 acts
2. `base/glua/rpg/data/quests.lua` (1193 lines) — all 23 quests with stages and effects
3. `base/glua/rpg/ending.lua` (270 lines) — all 4 endings with full narration
4. `base/glua/rpg/narrative.lua` (264 lines) — Trophy Hall, intro crawl, dream sequences

### Tier 2 — Cipher + items
5. `base/glua/rpg/data/cipher.lua` (20 lines) — the 9-digit code and 4 fragment sources
6. `base/glua/rpg/data/items.lua` (409 lines) — all items including cipher fragments, KOTOR2 artifacts
7. `base/glua/rpg/cipher.lua` (221 lines) — cipher submission and validation

### Tier 3 — Major NPC dialogues
8. `base/glua/rpg/data/dialogues/saevus.lua` (357 lines) — the antagonist's voice
9. `base/glua/rpg/data/dialogues/saevus_manifest.lua` (557 lines) — final encounter
10. `base/glua/rpg/data/dialogues/karath_vren.lua` (518 lines) — the dead Jedi Shadow's ghost (Act 4)
11. `base/glua/rpg/data/dialogues/watcher.lua` (476 lines) — metafictional NPC (Act 4)
12. `base/glua/rpg/data/dialogues/atton.lua` (1184 lines) — companion Atton Rand
13. `base/glua/rpg/data/dialogues/jeth.lua` (1358 lines) — Act 2 main quest-giver
14. `base/glua/rpg/data/dialogues/mira.lua` (385 lines) — Act 2 murder witness

### Tier 4 — Architecture / config
15. `base/glua/rpg/data/companions.lua` (193 lines) — companion roster
16. `base/glua/rpg/horror.lua` lines 450-509 — fourth-wall break trigger
17. `base/glua/rpg/state.lua` lines 332-338 — fourth-wall gate condition
18. `base/glua/rpg/config.lua` line 257 — `FOURTH_WALL_PARANOIA = 90`

### Tier 5 — Original C codebase comparison (sample, do not read in full)
19. `forceunleashstart-main/codemp/game/g_rpg.h` (632 lines) — full structure definitions
20. `forceunleashstart-main/codemp/game/g_rpg.c` — sample these line ranges:
    - `1456-1474`: Act 4 fourth-wall break (ERROR: ROOM_NAME_NOT_FOUND room)
    - `1540-1645`: Room 50-54 (Final Choice Chamber + 4 endings + Truth ending Saevus reveal)
    - `1645-1720`: NPC definitions (Adare, Goran, Atton, Jeth)
    - `2268-2790`: All 23 quest definitions
    - Use case-insensitive grep for: `saevus`, `vitiate`, `nathema`, `karath`, `kreia`, `meetra`, `revan`, `bastila`, `atris`

---

## Baseline findings from prior review (verified — use as starting point, challenge where wrong)

### What's verified to be IN the game

**Structure:**
- 55 rooms, 23 quests, 4 endings, 20 NPC dialogue trees, 67 Lua files
- **The Wanderer ship hub** = Rooms 16-25 (Bridge, Quarters, Medbay, Workshop, Armory, progressive Trophy Hall, dual Galleries)
- Trophy Hall is dynamic (`narrative.lua:7-60`) — quest/flag/nemesis state changes its description

**Lore depth:**
- **Saevus = Vitiate's student** trained in Nathema ritual (`saevus_manifest.lua:[12][20][35]`, quest Q18 `nathema_echo` in `data/quests.lua`)
- **Karath Vren** (Jedi Shadow) delivers Karpyshyn-novel Nathema lore in Act 4: "Eight thousand souls drained in a single ritual. The planet is still dead." (`karath_vren.lua` node 16)
- **Item 30** = Fragment of Revan's Journal with verbatim first-person Revan quote referencing Bastila and "my child"
- **Item 33** = Meetra Surik's Meditation Crystal (silences the Holocron when held)
- **Item 34** = Atris's Training Manual
- **Master Dorak** referenced as Tamas's master, killed at Katarr
- **Onderon KOTOR2 texture:** Queen Talia (Room 27), General Vaklu's failed coup (Room 26), Royal Guard, Beast Riders, Freedon Nadd connection (Q17 `beast_rider_legacy`)

**Sophisticated systems:**
- **Nemesis** (origin × temperament × attitude × scar tracking, 4 end states — Shadow of Mordor influence)
- **Doubt mechanic** (`isDoubt = true, truthLabel = "..."`) — when player picks Holocron-influenced dialogue, they see manipulated text; after selection, they see what the Holocron was REALLY whispering
- **Tomb loop** with 5-cycle escalating descriptions and WIS 14 / STR 16 escape check
- **Paranoia state machine** with thresholds at 30/50/70/85/90 gating content
- **Fourth-wall break** at paranoia ≥ 90 in Room 46 — same threshold as Horror ending. 5-frame ~6-second sequence ("You are rpgPlayer_t. A data structure...")
- **The Watcher** visible at paranoia ≥ 80 — metafictional NPC with WIS 16 stat-gate, three terminal paths (acceptance: paranoia -10; denial: +5; uncertainty)

**Companion Atton Rand:**
- KOTOR2-canonical ex-Sith assassin who killed Jedi
- Three terminal outcomes: companion / turn-in to Adare / blackmail
- Explicitly discusses Meetra Surik at node 110 ("a woman who lost her connection to the Force and got it back")
- Explicitly references Revan at node 102.5 ("Not everyone who served Revan did it because they believed")
- Blackmailed-AI variant in `companions.lua` with different combat behavior

**4 endings:**
- Light (Redemption): alignment ≥ 50 → Room 51. Player dies destroying Holocron.
- Dark (Dominion): alignment ≤ -50 → Room 52. Player becomes Saevus's host.
- Horror (Oblivion): paranoia ≥ 85 → Room 53. Player goes catatonic.
- Truth (Liberation): cipher solved → Room 54. Player survives, "you walk out of the chamber."

**Original C codebase status:**
- Contains the full 5-act story SKELETON including Saevus, Atton, Jeth, Adare, Goran, the 9-digit cipher solving to "DARTH SAEVUS THE FORGOTTEN", the fourth-wall break with explicit C-code references, and all 4 endings.
- The Lua port ADDED: Vitiate/Nathema explicit connection, Karath Vren as named character, Karpyshyn novel artifacts (Revan's Journal verbatim, Meetra crystal, Atris manual), Doubt mechanic with truthLabels, Queen Talia/General Vaklu KOTOR2 references, expanded dialogue trees (saevus tree has 357 nodes vs. far less in C).

### What's verified to be MISSING or thin

1. **Companion roster:** Only Atton is in `data/companions.lua`. Mira/Visquis/Zhar exist as NPC dialogue files but are NOT recruitable party members.
2. **Truth ending mechanical cost:** Light kills, Dark consumes, Horror catatonias — Truth just lets the player walk out with no permanent stat penalty or scar.
3. **Cipher redundancy:** 4 items (24, 25, 31, 36) provide all 9 digits. Miss any one and Truth ending is locked.
4. **Class-gated content:** Quest effects grant abilities uniformly. No "if class == Consular" branches visible.
5. **Level-12 ability tier:** Not yet implemented (deferred work).
6. **Saevus's concrete galactic plan:** He's named and his backstory is Vitiate-tier, but what he intends to DO if freed is vague — "freedom" and "Second Sith Empire" without a specific target.
7. **Council reckoning:** Item 27 (Encrypted Holoprojector) shows the Jedi Council tried to recall the Shadow operatives but the message degraded. This thread doesn't resolve in Act 5 — no surviving Master appears.

### Prior review's verdict
"This is KOTOR-3-adjacent already, not KOTOR 1 DLC. The author is underrating their own work. The 'KOTOR 1 DLC' feeling stems from delivery gaps (one companion, paranoia-gated deep content, weak Truth ending, stingy cipher), not story content. Keep the 5-act spine. Enhance the four delivery gaps. Do not restructure or cut."

---

## What I want from you

Read the required source files first. Then answer these questions with source-cited responses.

### A. Story validation
1. **Is the prior verdict correct?** Is this actually KOTOR-3-adjacent content, or is the author's "KOTOR 1 DLC" self-assessment closer to truth? Cite specific scenes/dialogues that support your view.
2. **Does the 5-act arc work psychologically?** Is the escalation Discovery → Corruption → Identity Break → Metafiction Crisis → Final Choice coherent, or does an act feel out of place?
3. **Does the genre fusion actually fuse?** Or are KOTOR/Survivor/Horror fighting each other?

### B. Flaw identification
1. **Star Wars canon contradictions.** Anything that breaks established Old Republic / KOTOR / KOTOR2 / Karpyshyn-novel canon? (e.g., timeline issues, character ages, faction behavior, Force lore violations)
2. **Internal continuity flaws.** Anything that contradicts the story's own established rules? (e.g., Holocron mechanics, paranoia logic, Saevus's powers, character motivations)
3. **Logic/plausibility issues.** Anything that doesn't make sense even within the story's premises? (e.g., why would the Council do X, why does NPC Y know Z, how does the player physically reach location W)
4. **Dropped threads.** Things introduced but never resolved (Council recall, Karath Vren's mission contact, Saevus's specific plan, etc.)
5. **Pacing/structural issues.** Acts that drag, payoffs that don't land, twists that arrive too early or too late.

### C. Enhancement ideas
1. **What would close the "KOTOR-3 feel" gap most efficiently?** Companions? Truth ending cost? Cipher redundancy? Council reckoning? Saevus motive? Other?
2. **What's a single dialogue insert or item addition that would dramatically improve the story?**
3. **What companion archetypes are missing that would complete the moral mirror function?** (Currently only Atton — what types of companions would best round it out?)
4. **What would you do with the Karath Vren character that the current dialogue doesn't?**
5. **Should the fourth-wall break be reframed, kept as-is, or moved?** Why? (It's currently gated at paranoia ≥ 90, same threshold as Horror ending.)

### D. Honest creative input
1. **What does this story do that KOTOR/KOTOR2 didn't?** What's actually new here?
2. **What does it borrow that doesn't quite work?** Anything that feels derivative without earning it?
3. **If you were the author, what would you keep, what would you cut, what would you rewrite?**

### E. Disagreement
1. **Where does the prior reviewer get it wrong?** Cite specific claims in this prompt's "Baseline findings" section and challenge them with source evidence.

---

## Response format

For each section, give specific source-cited findings. No paraphrase, no vague "feels like."

When you finish, give a single-paragraph **verdict** at the bottom: keep / refine / restructure / extend, and the one change you'd prioritize over all others.

---

## Anti-patterns to avoid

The prior reviewer made all of these mistakes. Don't repeat them:

- ❌ Trusting an explore-agent summary instead of opening the file
- ❌ Concluding "this content doesn't exist" from a malformed grep
- ❌ Using case-sensitive search where the source uses all-caps
- ❌ Critiquing phantoms — e.g., claiming "no ship hub" when Rooms 16-25 are the ship hub
- ❌ Hedging every claim — pick a side, cite source, stand behind it
- ❌ Giving a 100-word "looks fine to me" summary — the author wants substantive input

If you're unsure, read more source. If you disagree with the prior review, say so explicitly with file:line evidence.
