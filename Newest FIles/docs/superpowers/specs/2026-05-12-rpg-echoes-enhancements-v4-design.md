# Echoes of the Dark Wars — Enhancement Roadmap v5.0 (Design Spec)

**Date:** 2026-05-12 (v5.0 revision same day)
**Branch context:** `builder-shader-scanner-audit`
**Scope:** Narrative + mechanical enhancement roadmap for the in-game text RPG ("Echoes of the Dark Wars") shipped inside `!rpg`. 29 narrative/mechanical items across 4 sequenced phases (Phase 2 split into 2A/2B). **Plus Phase 0 (Infrastructure Foundation) — save/load/new-game system, locked in §12.** Preserves all existing content; targets four verified gaps.
**Brainstorming source:** `C:\Users\x105\.claude\plans\dapper-gliding-thompson.md`
**Revision history:**
- v4 (initial) — Approved by spec-reviewer with 4 advisory notes.
- v4.1 — 17 revisions after a 3-LLM critique round (ChatGPT structural, Kimi implementation, Gemini polish). Approved.
- v4.2 — Round-6 LLM critique applied. 8 revisions: three "plan-time" questions resolved in-spec via grep (post-Truth-ending behavior, cipher fragment hook symbol, Q16 confront_truth file pin); Force Void default committed to -25% FP regen; nemesis Corrupted attitude reverted from random to deterministic post-Q16 trigger; Phase 2A #10 expanded with Physical-memory previous-kill reference + Corrupted-memory false journal entry; Item 7 added to playtest gate.
- v4.3 — Round-7 LLM critique unanimously locked v4.2 with three small implementation cautions; 2 applied as spec polish (cipher rule committed: suppress trailing counter after pickup 2; Truth ending also surfaces `Force Connection: Severed` in the ending stats panel, not only on the character sheet). **Phase 0 stub added** at §12 — save/load/new-game system reported broken; diagnostic deferred to v5.0.
- v5.0 (this) — Phase 0 diagnostic complete; full Phase 0 scope locked in §12. Approach C+ adopted (periodic + checkpoint autosave + GameShutdown hook + boot menu + in-game menu integration + reusable confirm sub-menu). Spec metadata updated to reflect 5 phases (0, 1, 2A, 2B, 3) and 36 items total (Phase 0 adds 7 components: A–F + reusable confirm).

---

## 0. Overview

### 0.1 Why this exists
User's stated genre-fusion goal is KOTOR + KOTOR2 + Jedi Survivor + Lovecraftian horror, with the explicit target of feeling like "KOTOR 3". User's self-perception of the current ship is "KOTOR 1 DLC with a horror twist." Source-verified Phase 1 review (Exploration) corrected that self-perception: the content is already KOTOR-3-adjacent (Vitiate, Nathema, Karpyshyn novel material, 3949 BBY, 55 rooms, 23 quests, 4 endings, 20 dialogue trees, Nemesis/Doubt/Tomb-loop subsystems). The gap between perceived and actual is driven by four specific things, not by missing content. This roadmap targets those four things.

### 0.2 The four verified gaps
1. **Paranoia gating hides the deepest content.** The Watcher (≥80), fourth-wall break (≥90), Crew Quarters reflection (>60), Nathema Void overlays (>60) are opt-in via psychological cost. A Light-path player who manages paranoia carefully experiences a small fraction of the horror layer. This is the structural source of the "KOTOR 1 DLC" feel.
2. **Companion roster is thin.** `data/companions.lua` defines only Atton as fully recruitable. KOTOR2 had 10 recruitables. The "moral mirror" function is currently played by Saevus alone.
3. **Truth-ending cost asymmetry.** Light kills you, Dark consumes you, Horror catatonias you. Truth: "You walk out of the chamber. The sun is warm on your face." Narratively earned but no mechanical cost matching the weight of the other three.
4. **Cipher gate is stingy.** 4 hard-coded fragment sources (items 24/25/31/36). Miss any of 24/25/31 via quest routing and Truth ending is permanently locked.

### 0.3 Methodology
Roadmap drafted by Claude after source-verified exploration of all 5 acts. Cross-validated across **five LLM rounds** total:
- Rounds 1-3: Gemini, GPT, Kimi, Grok (broad design feedback)
- Round 4: nemesis-system pass (GPT, Kimi, Gemini)
- Round 5 (post-v4): structural critique (ChatGPT scope/pillar, Kimi implementation, Gemini polish) → produced v4.1
- Round 6 (post-v4.1): GPT/Gemini approved as-is; Kimi raised 4-5 concerns (pillar Physical-memory underuse, Corrupted-attitude 20%-per-room too random, Force Void calibration vague, 3 plan-time questions resolvable now). 8 revisions accepted → produced this v4.2.

Verified-against-live-code deltas resolved:
- **GPT (round 1) caught:** Phase 1 "Add hyperspace narration" was wrong — narration already exists in `menus/menu_victory.lua:55-74`.
- **GPT (round 1) caught:** Phase 1 "Add cipher counter" was wrong — counter exists in both `menus/menu_cipher.lua:33` and `menus/menu_quest_log.lua:134-157`. Revised to first-pickup notification (Phase 1 #6).
- **Kimi (round 4) caught:** Shadow Self is enemy 17 (not 13). Enemy 13 is the Mimic. `data/enemies.lua` verified.
- **Kimi (round 4) wrong:** Claimed Mimic quest is 3-stage. Verified: 7 stages per `data/quests.lua:410-536`.
- **Kimi (round 4) wrong:** Claimed Atton's Dantooine presence unexplained. Verified wrong: `atton.lua` nodes 3, 72, 578.
- **ChatGPT (round 5) caught:** Phase 1 scope claim "no new systems / no save-format changes" contradicts item #1 (forceSevered flag + config constant). Fixed in v4.1: Phase 1 retitled "Narrative Beats + One Persistent Flag."
- **ChatGPT (round 5) caught:** Karath Vren is female per `karath_vren.lua:34,476`. v4 said "his own dissolution." Corrected.
- **Kimi (round 5) wrong:** Claimed `data/dialogues/nemesis.lua` doesn't exist. Verified: file exists (~48 nodes, 3 encounters, 4 end states). Nemesis dialogue is insertion-into-existing-file, not new-file creation.
- **Behavior mirror exists:** `combat.lua:1304` (~80% copy of last action). Phase 2A #12 is therefore STAT mirror only.
- **Nemesis status:** Fully wired (`nemesis.lua` 511 lines, 3 fixed encounters at Rooms 2/30/43). Not dormant.
- **Round 6: post-Truth-ending state verified:** `ending.lua:233` calls `RPG.SetState(player, "ending")` after narration; `game_complete` flag set; no return to exploration. Cost visibility is therefore in-ending narration + ending-menu character sheet only. Kimi's proposed "permanent dialogue option in future conversations" is moot — there are no future conversations post-ending.
- **Round 6: cipher fragment hook verified:** `RPG.Cipher.OnItemExamined(player, game, itemId)` at `cipher.lua:188-218` is the discovery point. Line 212 (`player:SendPrint("^7Fragments: " .. found .. "/" .. total)`) already prints a counter on every discovery. Phase 1 #6 is therefore a *modification* of this existing line (style + conditional), not a new function.
- **Round 6: Q16 confront_truth location verified:** `data/dialogues/saren.lua:355-388` is where the stage is *set* (`setStage = { quest = "the_mimic", stage = "confront_truth" }` + `RPG.Quest.SetStage` call). `mira.lua:299` only *reads* the stage. Phase 1 #4 line goes in `saren.lua`.

### 0.4 Scope decisions (user-confirmed)
- **Approach:** Preserve all existing content. Enhance, do not restructure or cut.
- **Sequencing rule:** smallest blast radius first; each phase has a playtest gate.
- **Companion archetype (Q5):** Decision deferred to post-Phase-3 playtest. Locked; ChatGPT round-5 pushback (move decision to Phase 2.5) rejected — see §8.
- **Nemesis enhancements:** Split into four sub-items (15A/B/C/D) in Phase 2B. Reject "any enemy becomes nemesis" (WB patent risk, blast radius too wide).
- **Truth-ending cost (Q1):** Force Sever bargain framed as trauma, not silence.
- **Fourth-wall break:** Split — Karath (personal breakdown) and Holocron-in-player's-voice (metacognition). Preserves identity-horror without breaking fiction.
- **Output target:** This spec → spec-review loop → user review → writing-plans → Phase 1 implementation.

---

## 1. Design Pillar: The Game Remembers

Every enhancement in this roadmap supports one of six memory types. Items that don't map to a memory type should be questioned — this is the YAGNI gate going forward.

| Memory type | What it remembers | Carried by |
|-------------|-------------------|------------|
| **Personal memory** | What was done TO the player's mind | Shadow Self, Watcher, Karath Vren recording, Mimic blackouts |
| **Moral memory** | What the player chose, including under deception | Doubt labels, alignment, Atton dialogue arc, Holocron-in-player's-voice |
| **Physical memory** | What the player did with their hands | Nemesis scars (action-derived), scar-driven adaptation buffs, Mimic-blackout kill-trace evidence |
| **Historical memory** | What happened before the player arrived | Cipher fragments, Sith inscriptions, Nathema/Vitiate lore, Karath cross-act logs |
| **Spatial memory** | What rooms hold of the player's journey | Trophy Hall, Wanderer ship rooms, Crew Quarters reflection |
| **Corrupted memory** | What was rewritten or missing | Mimic-as-rehearsal, Mimic blackouts, fake nemesis traces, blackout inventory tampering, false journal entries |

**Operating rule:** if a proposed enhancement does not cleanly attach to one of these six types, it is feature creep. The four verified gaps (§0.2) all map onto memory types: paranoia gating hides Personal + Corrupted memory; thin companions weaken Moral memory; Truth ending lacks Physical/Personal cost; cipher stinginess locks Historical memory.

---

## 2. Open Questions — Locked Decisions

| Q | Decision | Why locked |
|---|----------|------------|
| Q1 | **Truth ending = Force Sever bargain.** Permanent paranoia floor 30 (trauma). Force passive disabled (`game.player.forceSevered = true`). Visible on character sheet as `FP: [ SEVERED ]` rendered greyed. Framed as scar/trauma, not silence/peace. | Matches Light/Dark/Horror in mechanical weight. Adds visible permanent cost. Gemini polish (greyed UI text) accepted in v4.1. |
| Q2 | **Saevus's Iziz target = hidden Force-sensitive children registry sealed beneath the old Iziz cathedral.** Sealed after the Jedi Civil War to protect them from bounty hunters, Sith remnants, and Republic intelligence. Saevus wants it as a concentrated map of latent Force signatures — calibrating a Nathema-style ritual at a smaller scale before scaling up. | Gives Onderon visit concrete stakes. Connects to Vitiate's Nathema-ritual progression (children are the seed scale; Nathema's eight-thousand-soul ritual is the destination). v4.1 expanded the definition per ChatGPT round-5. |
| Q3 | **Mimic-as-rehearsal = explicit at Q16 stage `confront_truth`.** Saren security-footage line: "This isn't a copy. It's a rehearsal. Whoever made this is practicing." | Threads Mimic combat into the Saevus arc. One dialogue line reframes the whole quest as foreshadowing. |
| Q4 | **Cipher fragment notification = first two pickups print `^3[Cipher fragment X/9 — keep gathering]` inline.** Thereafter, counter remains in menu only. | Surfaces the gate without nagging. |
| Q5 | **Companion archetype decision deferred to post-Phase-3 playtest.** | Q5 lock held in v4.1 despite ChatGPT round-5 pushback. Reasoning: Kimi explicitly endorsed deferral; "more companions" is a Phase-4 lever, not a fix for the bigger issues (paranoia gating, ending costs, identity threading) still in flight. |

---

## 3. Phase 1 — Narrative Beats + One Persistent Flag (2-3 sessions)

**Scope honesty:** Mostly dialogue/text additions, with one default-safe persistent flag (`forceSevered`) and one config constant (`PARANOIA_FLOOR_TRUTH`). No new modules. No save-format breaks (new flags default-nil so old saves load cleanly).

### 3.1 Items

| # | Item | Files touched | Mechanism | Acceptance |
|---|------|---------------|-----------|------------|
| 1 | **Truth ending Force Sever bargain** | `ending.lua` (narration + Trigger + BuildEndingData stats), `state.lua` (forceSevered flag), `config.lua` (PARANOIA_FLOOR_TRUTH = 30), character-sheet renderer (`menu_character.lua` or equivalent), ending-menu stats render | (a) Append 3-line Sever-bargain narration to Truth ending narration table. (b) Inside `RPG.Ending.Trigger` for `endingType == "truth"`: set `game.player.forceSevered = true` and clamp `game.player.paranoia = max(paranoia, 30)`. (c) Character-sheet FP line renders `FP: [ SEVERED ]` in grey when flag set, instead of `FP: 0 / 100`. (d) **Ending stats panel surfaces the cost directly:** `RPG.Ending.BuildEndingData.stats` adds a `forceSevered` field; the ending menu renders a line `^7Force Connection: ^1Severed` (Truth ending only). Cost is visible on the ending screen itself, not just on the character sheet. **Post-ending behavior is locked:** game terminates at all four endings (verified `ending.lua:233` — state transitions to "ending", `game_complete` flag set, no return to exploration). | Truth-ending narration reads as visible permanent cost. Ending menu stats panel shows `Force Connection: Severed`. Character sheet (viewable from ending menu) renders SEVERED indicator as a bonus visibility layer. Paranoia floor clamps at 30. Frame: trauma, not silence — the wound is permanent but you walked out. |
| 2 | **Saevus's Iziz target = sealed child registry** | `data/dialogues/saevus_manifest.lua` | 2-3 line addition near Saevus's "I could teach you to use it on anything" beat. Names the hidden registry sealed beneath the Iziz cathedral; explains that Saevus is calibrating a Nathema-style ritual at smaller scale before scaling up. | Player meeting Saevus Manifestation hears concrete stakes and understands the Iziz children are the seed-scale rehearsal of the Nathema ritual. |
| 3 | **Stalker name reveal: Nalen Vorr** | `stalker.lua` AMBIENT table, `data/items.lua` (Item 31 Dark Crystal Fragment examine text), `data/dialogues/karath_vren.lua`, `data/dialogues/saevus_manifest.lua` | Four-stage reveal chain: (a) Stage 2 ambient: "A broken whisper follows you: '...Vorr...'" (b) Dark Crystal Fragment (Item 31) examine text reveals scorched ID imprint: "Nalen Vorr, Jedi Shadow." (c) Karath dialogue (paranoia ≥85 gate): "Nalen was my handler. My warning. My future." (d) Saevus Manifestation late beat uses the name cruelly: "Vorr lasted longer than you will." | Name is revealed as mystery/discovery, not blunt label. Each stage adds context. |
| 4 | **Mimic-as-rehearsal explicit** | `data/dialogues/saren.lua:355-388` (pinned — this is where Q16 stage `confront_truth` is set via `setStage` effect + `RPG.Quest.SetStage` call) | One added line in the saren security-footage response: "This isn't a copy. It's a rehearsal." Plus 1-2 supporting context lines tying to Saevus practice. | Player understands the Mimic is Saevus practice-running an identity-strip ritual. |
| 5 | **Saevus goal hierarchy** | `data/dialogues/saevus_manifest.lua` | Re-order/clarify Saevus's pitch so Iziz children → Nathema-scale ritual reads as a stair, not two unrelated boasts | One reading of the Manifestation scene makes Saevus's plan legible. |
| 6 | **Cipher counter notification on pickup** | `cipher.lua:188-218` — function `RPG.Cipher.OnItemExamined`. Line 212 already prints `^7Fragments: X/Y` on every discovery (unconditional). | Modify the existing line 212 print with a committed three-state rule: **(a)** when `found == 1`, print styled `^3[Cipher fragment 1/9 — keep gathering]`. **(b)** when `found == 2`, print styled `^3[Cipher fragment 2/9 — keep gathering]`. **(c)** when `found >= 3`, **suppress** the trailing counter line entirely — the CIPHER FRAGMENT DISCOVERED banner at lines 200-213 stays, but the menu counter carries the running total from there. Rule locked per round-7 GPT note: showing `Fragments: X/Y` every time weakens the "first two pickups are special onboarding" framing. | Pickup 1 and 2 → styled onboarding counter. Pickup 3+ → discovery banner only, menu carries the count. |
| 7 | **Optional mid-hyperspace dream beat** | `menus/menu_victory.lua` (just before SetState exploration) | 5-line dream sequence inserted into post-CONTINUE prints; reuses `RPG.PrintDream` pattern. | Pure additive flavor. Skippable. |

### 3.2 Playtest gate
30-minute targeted playtest covering beats 1, 3, 4, 2, and 7 in order:
- **Beat 1** — load high-paranoia save, run through Truth ending. Verify Sever-bargain narration + SEVERED character sheet + paranoia floor are visible as permanent cost.
- **Beat 3** — load Stage-2 stalker save, walk a few rooms, examine Item 31 after first survival. Verify Nalen Vorr name lands as discovery via evidence chain.
- **Beat 4** — load Q16 `confront_truth` save, advance one stage. Verify Mimic-as-rehearsal line reads as foreshadowing not exposition.
- **Beat 2** — load Saevus Manifestation save. Verify Iziz target reads as concrete stakes.
- **Beat 7** — trigger Act 1 → Act 2 hyperspace transition. Skim the dream insert for tonal fit. If it reads as filler or breaks the menu pacing, cut #7 from the Phase-1 plan.

If any beat feels flat, revise that item before opening Phase 2A.

### 3.3 Memory-pillar mapping
- #1 → Personal memory (Sever as scar)
- #2 → Historical memory (registry as pre-existing fact) + Personal memory (Saevus plan)
- #3 → Personal memory (Stalker becomes a named pursuer)
- #4 → Corrupted memory (the Mimic was a rehearsal)
- #5 → Personal memory (Saevus plan clarity)
- #6 → Historical memory (cipher progression)
- #7 → Personal memory (dream beat)

---

## 4. Phase 2A — Horror Mechanics (4-5 sessions)

Phase 2A focuses on the player-experience-of-horror layer. Higher engine surface area than Phase 1; each item is rollback-safe (revert single commit).

### 4.1 Items

| # | Item | Files touched | Mechanism |
|---|------|---------------|-----------|
| 8 | **Fourth-wall replacement: Karath + Holocron split** | `horror.lua` lines 460-509 (the `rpgPlayer_t` literal scene), `data/dialogues/karath_vren.lua`, new function in `horror.lua` for Holocron-in-player's-voice trigger | At paranoia ≥ 90, replace the existing `rpgPlayer_t / data structure / table of numbers` literal break with TWO scenes split by load: (a) **Karath Vren breakdown recording** — *her* personal dissolution beat. ~3 lines. Recovered ghost-recording flavor; she is female per `karath_vren.lua:34,476`. (b) **Holocron-in-player's-voice** — addresses the player directly with their own voice describing manipulation: "I have been whispering the coordinates since Act 1. Every 'choice' you made was a path I cleared." Stays fully in-fiction. Watcher dialogue at paranoia ≥80 still carries the agency-question theme as character-level meta. |
| 9 | **Cipher reframe: layered, not whole story** | `data/dialogues/saevus_manifest.lua`, `ending.lua` Truth-ending preface | Recontextualize the cipher: it is *one* containment seal layer on Saevus, not the entire story. Saevus is still defeated narratively; the cipher unlocks the Truth-ending vantage. Preserves the 9-digit puzzle; resolves the "if I solve a code, why is Saevus defeated?" awkwardness. |
| 10 | **Mimic blackouts: escalating per stage, with kill-traced inventory tampering + false journal entry on final** | `data/quests.lua` Q16 stage advance hooks, new blackout helper in `state.lua` (or inline `mimic_blackout.lua`), `data/items.lua` (new "Bloodied Cloth" junk item with dynamic examine text), `data/dialogues/{quest_log,journal}.lua` for fake entry render, save state field `fakeJournalEntries` | Each of the 4 mid-quest Mimic stages triggers a blackout whose intensity scales with paranoia. Stage 1: 1-line. Stages 2-3: escalating. **Stage 4 (final, most severe) — three Corrupted-memory hooks fire together:** (a) 4-line "you don't remember the last hour" + wake-up location-jump. (b) **Silent inventory tampering with kill-trace [Physical memory bridge]:** remove 1 medpac, add "Bloodied Cloth (Not Yours)" — examine text dynamically references a *specific* enemy the player killed earlier ("The blood type matches the kinrath matriarch you killed in the caves" / "...the Exchange thug you cut down in Khoonda" / etc., selected from kill log). Makes the Mimic's hands-on violence personally traceable. (c) **False journal entry:** insert one fake completed quest line into the quest log render — "Delivered Holocron to Zherron — COMPLETED." (Zherron doesn't have it; the entry is planted to make the player doubt their own record-keeping.) Persisted via `game.fakeJournalEntries` table, default-nil. Hybrid gate: blackout always fires on quest stage; severity scales with paranoia. |
| 11 | **Force Voids with safe mechanical bite** | `combat.lua` (Void-state hook in CalcCombatModifiers or similar), `dialogue.lua` (Void-state flavor flag) | At paranoia ≥60 in Act 2+ rooms with `voidDescription`: **In combat (committed default): -25% FP regen for one round** (player tries to use Force Heal, sees FP bar move slower, panics — the panic *is* the point). Fallbacks if punitive: drop to -15%; or replace with "lightsaber 25% chance to fail ignition" (Gemini's visceral alternative). **In dialogue:** purely flavor — show `[VOID] Your thoughts feel distant.` as a UI tag; no penalty applied to required dialogue checks. **Optional dialogue checks:** -2 WIS/INT applied, displayed as `[VOID] Awareness check harder here`. Soft-lock-safe: required checks never get the penalty. |
| 12 | **Shadow Self STAT mirror** | `combat.lua` enemy 17 init path | Behavior mirror at `combat.lua:1304` (~80% last-action copy) already exists. Add STAT mirror: on Shadow Self combat start, copy player STR/DEX/INT/WIS into Shadow Self's stat block. Makes the fight read as "you're fighting yourself" mechanically and narratively. |

### 4.2 Phase 2A playtest gate
Full Act-2 → Act-4 run on Light-path and Horror-path saves. Measure:
- Force Voids penalty calibration — does the penalty feel earned or punitive?
- Karath/Holocron split — does it carry the metacognition weight the literal scene previously had?
- Mimic blackout escalation — does Stage-4 inventory tampering land as horror or as bug-feel?
- Shadow Self STAT mirror — does the fight feel like a mirror or just a harder enemy?

### 4.3 Memory-pillar mapping
- #8 → Personal memory (Karath dissolution) + Moral memory (Holocron manipulation reveal)
- #9 → Historical memory (cipher is one layer of a deep history)
- #10 → Corrupted memory (blackouts, false journal entry) + Physical memory (kill-traced cloth examine text)
- #11 → Personal memory (Force Voids make the horror layer mechanically present)
- #12 → Personal memory (Shadow Self is *you*, statistically)

---

## 5. Phase 2B — Memory Systems (3-4 sessions)

Phase 2B is the cross-cutting memory layer. Each item makes one memory type more legible to the player.

### 5.1 Items

| # | Item | Mechanism |
|---|------|-----------|
| 13 | **Sith inscriptions Acts 37-41** | Add untranslated Sith inscription lines to Dxun void-room descriptions. INT-13-gated examines reveal translations. Translations seed Karath / Vitiate / Nathema lore for players who never reach the paranoia ≥90 content. |
| 14 | **Cipher redundancy: fallback fragment source** | At Trophy Hall 4+ trophies, the room description reveals one cipher hint corresponding to the player's missing fragment (computed at runtime from `cipher.lua` discovered set). Does NOT add a new digit — the cipher remains 9 digits. Prevents Truth-ending lockout from one missed quest route. |
| 15A | **Nemesis action-derived scars** | New `lastAbilityUsed` field tracked per combat in `combat.lua`. `nemesis.lua` reads this on encounter-end to assign scar by ability ID. Sketch:<br>```ABILITY_SCARS = {```<br>```  force_lightning = { part = "chest", desc = "burn patterns that won't heal" },```<br>```  force_push = { part = "arm", desc = "bones set wrong, healed crooked" },```<br>```  force_choke = { part = "neck", desc = "bruise lines that never fade" },```<br>```  lightsaber_slash = { part = "face", desc = "a scar from jaw to temple" },```<br>```  blaster_shot = { part = "leg", desc = "a limp that worsens in rain" },```<br>```}```<br>Scars surface in subsequent encounter dialogue ("the burn you gave me hasn't healed"). |
| 15B | **Nemesis Holocron-corruption attitude (override state, deterministic trigger)** | `nemesis.lua` attitude system currently has Respect/Fear/Hatred/Obsession/Neutral (computed). Add **Corrupted** as an *override state*, distinct from computed attitudes. **Trigger is deterministic, not random** (revised v4.2 per Kimi round-6): on Q16 (`the_mimic`) reaching `complete` stage AND player still holds the Holocron, flip the nemesis to Corrupted on their next encounter event. Narrative justification: the nemesis tracks the player to Onderon, witnesses the Mimic aftermath, and realizes the Holocron is more than a relic — their eyes change, their dialogue changes. Unlocks "his eyes are wrong now" dialogue branches. Never overwrites the computed attitude record; rendered as an override layer. |
| 15C | **Nemesis defeat-type trophy (description text only)** | Trophy Hall already has 4 nemesis description branches at `narrative.lua:15-27`. Phase 2B wires all 4 paths so each defeat outcome (recruited / spared / walked away / killed) reliably triggers its description variant. **Description text only** — not item placement; no item-system hooks. |
| 15D | **Scar-driven Encounter-2+ adaptation buffs** | At Encounter 2 (Room 30), if nemesis carries a scar from Encounter 1, equip a counter-buff: Lightning Burn → +50% Force-damage resistance ("insulated mesh"); Lightsaber Slash → +25% melee defense ("cortosis weave"); Blaster Shot → +1 DEX (faster movement); etc. Materializes the "I learned from last time" Shadow-of-Mordor mechanic without crossing patent lines (specific to nemesis, not generalized to all enemies). |

### 5.2 Phase 2B playtest gate
Two-encounter nemesis run with deliberately-varied combat styles (Force-heavy on Enc 1, melee-heavy on Enc 2). Verify:
- Action-derived scar fires the matching ABILITY_SCARS entry.
- Encounter 2 buff matches Encounter 1 scar.
- Holocron-corruption override fires only when both gates (Holocron kept + Q16 complete) are met; never random.
- All 4 trophy description variants are reachable across multiple runs.

### 5.3 Memory-pillar mapping
- #13 → Historical memory (Sith past, Karath lore for low-paranoia players)
- #14 → Historical memory (cipher progression)
- #15A → Physical memory (your hands left this mark)
- #15B → Corrupted memory (Holocron warps the hunter)
- #15C → Spatial memory (Trophy Hall remembers the outcome)
- #15D → Physical memory (your hands taught them)

---

## 6. Phase 3 — Identity & Cross-Threading (~10 sessions)

Phase 3 adds cross-act threading. Higher blast radius than Phase 2. Item 24 (companion archetype) is gated by Phase-3 playtest outcome.

| # | Item | Mechanism |
|---|------|-----------|
| 16 | **Karath Vren cross-act logs** | 3 datapad fragments — one per Act 3/4/5 — each containing a stage of Karath's mission log. Stitches Karath's arc across rooms instead of dumping it all at the paranoia ≥90 gate. |
| 17 | **Nemesis Holocron-corruption escalation** | Builds on #15B: if player kept Holocron AND nemesis hits Corrupted override AND reaches Encounter 3 still hunting, Encounter 3 changes — nemesis is being warped by proximity to the Holocron during pursuit. Gives a fifth nemesis end-state. |
| 18 | **Companion vendetta (Atton)** | Insertions into existing `data/dialogues/nemesis.lua` (file verified to exist, ~48 nodes). If Atton recruited, nemesis dialogue references his Sith assassin past. Plus Atton's high-paranoia intervention beat (see #23). |
| 19 | **Trophy Hall extended progressive description** | Extend `narrative.lua` trophy system to reflect Phase 1-2 outcomes (Sever path, Mimic blackouts, Holocron kept/given, nemesis variants). Spatial memory becomes load-bearing. |
| 20 | **Doubt-mechanic awareness post-cipher** | After cipher solved, journal/menu shows the "truth label" of every Holocron-influenced choice the player took. Reveals what they *thought* they chose vs what they *actually* chose. |
| 21 | **Fake nemesis appearances at paranoia ≥70** | `nemesis.lua:406-410` already has FAKE_TRACES. Extend to fake *appearances*: player sees the nemesis at the edge of a room; on re-enter, no one is there. Resolves as hallucination. |
| 22 | **Class-flavored dialogue (5-10 lines)** | Stat/class-gated lines distributed across existing dialogues. Consular sees Force-vision flavor; Guardian gets combat-stance options; Scoundrel sees deception paths; etc. |
| 23 | **Atton high-paranoia intervention** | If paranoia ≥75 and Atton recruited, Atton confronts player in Wanderer Crew Quarters ("you're not yourself — talk to me or I'm leaving"). Three responses. |
| 24 | **Companion archetype decision (deferred, locked Q5)** | Post-Phase-3 playtest: decide Mira-promoted vs Force-pure conscience. If "needed," resolves into Phase 4 #25 (Force-pure) or Phase 4 #26 (Mira-promoted). |

### 6.1 Phase 3 playtest gate
After Phase 3 ships, full Light-path playthrough. Decision: does the player feel they have enough emotional anchor without a second companion? If yes → defer to Phase 4 (or omit). If no → resolve Q5.

### 6.2 Memory-pillar mapping
- #16 → Historical memory (Karath's mission preserved across acts)
- #17 → Corrupted memory (Holocron warps the hunter further)
- #18 → Moral memory (companion past meets present)
- #19 → Spatial memory (Trophy Hall expanded)
- #20 → Moral memory (what you actually chose)
- #21 → Corrupted memory (hallucinated traces)
- #22 → Personal memory (your class shapes what you see)
- #23 → Moral memory (companion remembers your behavior)
- #24 → (deferred decision)

---

## 7. Phase 4 — Optional Breadth (5 items)

Phase 4 is opt-in. Each item is a self-contained polish piece. Only run if Phases 1-3 land. **Item 26 from v4 (Stolen-from-them journal pages) cut in v4.1** — conflicted with the defeat=survival design pattern (nemesis doesn't drop loot).

| # | Item | One-line summary |
|---|------|------------------|
| 25 | **Force-pure conscience companion** | Young Jedi survivor of Katarr the Wanderer picks up on Onderon. Built only if Q5 resolves toward Force-pure. |
| 26 | **Attitude-modulated audio cues** | Nemesis approach plays different stinger by current attitude state. |
| 27 | **Psychometry / Force Echoes** | Class ability on item examine. Consulars see scenes; Guardians see violence; Scoundrels see motive. |
| 28 | **Cipher digit reframe** | 9 digits = 9 chambers in the Vitiate ritual chain. Lore-deepening; no mechanical change. |
| 29 | **Level-12 capstone abilities** | One per class at lvl 12. Already deferred per prior memory entries. |

---

## 8. Rejected ideas (with reasons)

| Idea | Source | Reason rejected |
|------|--------|-----------------|
| "Any enemy becomes nemesis" | early brainstorming | WB patent risk (Shadow of Mordor, active until 2036-08-11). Loses "this one is yours" specificity. |
| Reputation 0-100 per faction | early brainstorming | Overcomplicates implicit quest-outcome tracking. No clear narrative payoff. |
| Ambient nemesis-trace random rolls in all rooms | early brainstorming | Would flood console. FAKE_TRACES at paranoia >70 already cover the "is it real?" angle. |
| Cut all defeat=survival (nemesis killable on first encounter) | early brainstorming | Load-bearing for 3-encounter pacing. |
| Move setting to 3951 BBY | early brainstorming | Invalidates Karpyshyn-novel references (Revan vanishing date, Surik meditation crystal, Master Dorak Katarr cameo). |
| Stolen-from-them journal pages (v4 item 26) | v4 | Kimi round-5: defeat=survival pattern means nemesis doesn't drop loot. Backstory already delivered via dialogue + traces + dossier. Cut. |
| Phase 2.5 companion-reactivity prototype (8-12 lines) | ChatGPT round-5 | Q5 locked through prior brainstorming rounds (Kimi explicitly endorsed deferral). More companions is a Phase-4 lever; bigger fish still in flight (paranoia gating, ending costs, identity threading). Reconsider only at Phase-3 playtest gate. |
| Permanent dialogue option in all future conversations for Truth Sever | Kimi round-5 | Depends on whether run continues post-Truth-ending. Plan-level question, not spec-level. Visible-in-ending narration + SEVERED character-sheet + paranoia floor carry the cost-visibility burden. Re-open if writing-plans grep finds the run persists. |

---

## 9. Source citations (per claim)

| Claim | Citation |
|-------|----------|
| Stalker stages, ACT2 range | `stalker.lua:1-145` |
| Stalker enemy ID = 12 | `stalker.lua:141` |
| Q15 holocron_unlock stages | `stalker.lua:200-204`, `data/quests.lua` |
| Q16 Mimic 7-stage flow | `data/quests.lua:410-536` |
| Mimic = enemy 13, Shadow Self = enemy 17 | `data/enemies.lua` |
| Behavior mirror exists at ~80% | `combat.lua:1304` |
| Nemesis full wiring | `nemesis.lua:1-511` |
| `data/dialogues/nemesis.lua` exists (~48 nodes) | `data/dialogues/nemesis.lua:1-50` |
| FAKE_TRACES at paranoia >70 | `nemesis.lua:406-410` |
| Trophy Hall 4 nemesis branches | `narrative.lua:15-27` |
| Fourth-wall literal scene to be replaced | `horror.lua:460-509` |
| Fourth-wall gate constant | `config.lua:257` (FOURTH_WALL_PARANOIA = 90) |
| **Karath Vren is female** | `karath_vren.lua:34` ("Her voice echoes from everywhere and nowhere"), `karath_vren.lua:476` |
| Saevus Manifestation Vitiate/Nathema lines | `data/dialogues/saevus_manifest.lua` |
| Hyperspace narration already exists | `menus/menu_victory.lua:55-74` |
| Cipher counter already in menus | `menus/menu_cipher.lua:33`, `menus/menu_quest_log.lua:134-157` |
| Atton's Dantooine presence justified | `data/dialogues/atton.lua` nodes 3, 72, 578 |
| Ending state `game.truthUnlocked` persistence | `ending.lua:116` |

---

## 10. Out of scope

- New acts / new endings beyond the 4 existing
- Engine-level changes to the C codebase (`codemp/game/`)
- New game modes
- Save-format breaks (new flags must default-safe; old saves load cleanly)
- Replacing existing systems (Doubt mechanic, Tomb Loop, Stalker state machine preserved as-is)
- New companion combat mechanics in Phase 1-3 (any new companion in Phase 4 only)

---

## 11. Implementation handoff

After this spec passes the spec-document-reviewer loop and user re-review, the next step is to invoke the **superpowers:writing-plans** skill to produce a concrete Phase 1 implementation plan. Phase 2A, 2B, 3, 4 plans get written only after their respective playtest gates pass.

The writing-plans skill produces a step-by-step plan (file edits, function changes, test approach). It does **not** produce the spec — this document is the spec. Plans derive from specs.

**Plan-time questions remaining (v4.2 resolved three from v4.1):**

Resolved in v4.2 via source grep (see §0.3 round-6 deltas):
- ✅ Item 1 post-ending behavior: game terminates at all endings; cost via in-ending narration + ending-menu sheet only.
- ✅ Item 4 file pin: `data/dialogues/saren.lua:355-388`.
- ✅ Item 6 hook pin: `RPG.Cipher.OnItemExamined` at `cipher.lua:188-218`, modify existing line 212.
- ✅ Item 7 playtest gate: added as Beat 7.

Still open for the Phase 1 / Phase 2A plans:
1. **Item 11 alternate calibration:** primary is -25% FP regen (committed in spec); if playtest reports punitive feel, fall back to -15% or replace with "lightsaber 25% chance to fail ignition." Decision belongs in the Phase 2A plan, not Phase 1.
2. **Item 15A `lastAbilityUsed` collision check:** confirm during writing-plans that this field name doesn't collide with existing `combat`/`combatProfile` state. Gemini round-6 hint: should be safe — `combatProfile` tracks numerical tallies (force/melee/ranged/defend/dark counts), so a string-typed `lastAbilityUsed` is additive.
3. **Item 15A `ABILITY_SCARS` symbol verification:** confirm the sketch ability IDs (`force_lightning`, `force_push`, `force_choke`, `lightsaber_slash`, `blaster_shot`) match actual ability registration in `combat.lua` / power tables. Phase 2B plan task.
4. **Item 10 `fakeJournalEntries` save-state addition:** new field `game.fakeJournalEntries = nil` by default; quest log render reads from real quests AND this table. Confirm save serializer handles new nullable field cleanly.

---

## 12. Phase 0 — Infrastructure Foundation (Save / Load / New Game)

**Status:** Locked v5.0. Implementation pending writing-plans.

### 12.1 Why this exists
User report: account-logged-in players lose progress; no way to start over. Phase 0 is a prerequisite for every later phase:
- **Phase 1's playtest gate is structurally impossible without working save/load** — §3.2 requires loading specific game states ("high-paranoia save," "Stage-2 stalker save," "Q16 confront_truth save," "Saevus Manifestation save").
- The "Game Remembers" pillar (§1) collapses if persistence is fragile. A 15-minute quest completion that doesn't feel locked-in undermines the pillar's narrative promise.
- Replay across endings is impossible without reliable persistence.

### 12.2 Diagnostic findings (verified against current checkout)

**What's implemented (sound):**
- `save.lua` (590 lines): JSON snapshot to `glua/data/rpg_saves/<key>.json`. Account-ID-preferred key (`acct_N`), GUID-hash fallback (`guid_N`) with **auto-migration on `Read`** if guid file exists but no account file.
- Full snapshot: stats, inventory/equipment, quests, flags, room deltas (only differs-from-default), visitedRooms, stalker/nemesis/vendor/tombLoop/fragmentDrain state.
- Robust restore (`RestoreFromSnapshot`): numeric-key rehydration after JSON round-trip, dynamic exit re-application, tomb-loop description reconstruction, cipher/ending room state special-cases, companion KO recovery, alias rebinding (`game.questStates = game.quests`).
- `PlayerDisconnect` autosave (`init.lua:916-944`) writes `game` on graceful disconnect when class is set and `saveKey` cached.
- Chat commands: `!rpg save`, `!rpg load` (with confirm if already playing), `!rpg new`, plus `!rpg` no-args auto-detects save and prints text prompt.
- `File.Write` → `trap->FS_Open(FS_WRITE)` auto-creates intermediate directories (no missing-dir bug).
- Resolves to `<fs_homepath>/<fs_game>/glua/data/rpg_saves/`; on VPS = `~/NewSharding/openjk_home/base/glua/data/rpg_saves/`.

**What's broken — three real gaps:**

1. **Disconnect autosave is the ONLY autosave.** No periodic timer. No checkpoint saves on quest complete / act unlock / cipher solve / ending trigger. `GameShutdown` hook constant exists in `framework/hooks.lua:172` but RPG does not subscribe. Server restart, server crash, map change, or kick = lost session. **This is the "lose all progress" symptom.**

2. **No save/load/new-game menu UX.** All entry points are chat commands. `!rpg` after a lost session prints a one-line "Save found, type `!rpg load`" — easy to miss, doesn't match the centerprint menu paradigm. **This is the "no way to start over" symptom**: `!rpg new` exists but is invisible.

3. **`!rpg new` is non-destructive.** Old save file isn't deleted, only overwritten on next autosave. No confirmation prompt.

**Verified sound:** account-ID timing (auto-migration handles late-login case), file-path resolution, snapshot validation, version handling.

### 12.3 Locked scope (Approach C+ with menu integration)

Six components. Estimated ~300 LOC across `save.lua`, `init.lua`, `state.lua`, `quest.lua`, `ending.lua`, `cipher.lua`, `menu_exploration.lua`, plus two new menu files (`menu_boot.lua`, `menu_confirm.lua`).

#### 12.3.A Crash-safe autosave layer

**A1. Periodic autosave timer.** Per-player timer fires every `RPG.Config.AUTOSAVE_INTERVAL_MS` (default **90000ms / 90s**). Started on game creation (NewGame / RestoreFromSnapshot), stopped on Shutdown.
- **State gate:** only fires when `game.state == "exploration"`. Skips combat/dialogue/menus/cipher_input/ending to avoid mid-frame snapshot inconsistency.
- **Cooldown gate:** skip if `(now - game.lastSaveAt) < RPG.Config.AUTOSAVE_COOLDOWN_MS` (default **10000ms / 10s**). Defuses checkpoint chain-fire.
- Timer name: `rpg_autosave_<clientNum>`. Cleaned up in `RPG.Shutdown`.

**A2. Checkpoint autosaves** — instrument these existing call sites to invoke `RPG.Save.AutoSave(player)` (a wrapper that respects the cooldown):
- `RPG.Quest.Complete(player, questId)` — after quest is marked complete (single insertion in `quest.lua`).
- `RPG.UnlockAct3(player, game)` — at the moment `currentAct` transitions to 3.
- `RPG.UnlockAct4(player, game)` — at the moment `currentAct` transitions to 4.
- `RPG.Cipher.OnSubmit(player, code)` — on successful cipher solve (sets `truthUnlocked = true`).
- `RPG.Ending.Trigger(player, endingType)` — before ending narration plays. **Important:** the save here captures pre-ending state so a player who restarts mid-ending replays from the choice room, not from a broken ending state.

**A3. `GameShutdown` hook.** Subscribe in `init.lua`. On server shutdown, iterate `RPG.players` and call `RPG.Save.Write(game)` for each session with a class set. Engine grants a finite shutdown window; saves are small (~few KB JSON each), so even ~16 concurrent saves complete inside the window. Log failures via `GLua.Warn`.

**A4. Disconnect autosave** — already exists at `init.lua:916-944`. **Retained, no changes.**

**A5. Cooldown timestamp tracking.** Add `game.lastSaveAt = os.time() * 1000` on every successful `RPG.Save.Write`. Used by A1 cooldown gate and A2 wrapper.

#### 12.3.B Boot menu (`rpg_boot`)

New menu file `menus/menu_boot.lua` registered as state `"boot"`. Surfaced when `!rpg` runs and `RPG.IsPlaying(player) == false`.

**Items (dynamic by save state):**
- If save exists (decoded via `RPG.Save.GetMetadata`):
  - `^2Continue — Level X ClassName  (Room Name)`  → action `continue`
  - `^3New Game`  → action `new_game`
  - `^7Cancel`  → action `cancel`
- If no save:
  - `^3New Game`  → action `new_game`
  - `^7Cancel`  → action `cancel`

**Header:** title block, plus last-save timestamp formatted as `Last saved: YYYY-MM-DD HH:MM` (only when save exists).

**Action handlers:**
- `continue` → call `RPG.Save.Read + RestoreFromSnapshot`, then `RPG.SetState(player, snapshot.state or "exploration")`.
- `new_game` → if save exists, open `rpg_confirm` with body "This will erase your current save. Continue?" and `onConfirm = function() RPG.Save.Delete(player); RPG.SetState(player, "intro") end`. If no save, go straight to intro.
- `cancel` → `RPG.Shutdown(player)` (closes menu, no session created).

**Chat command integration.** Replace the current text-prompt path in `init.lua:268-301` so `!rpg` (no args) ALWAYS opens `rpg_boot` when not playing. Existing `!rpg load` / `!rpg new` chat commands retained as power-user shortcuts (no UX regression).

#### 12.3.C In-game menu integration (exploration Menu category)

Extend `menu_exploration.lua` expandable `Menu` category. Current items: Character Sheet / Inventory / Quest Log / Read Description / Quit RPG. After this change:

1. Character Sheet  (unchanged)
2. Inventory  (unchanged)
3. Quest Log  (unchanged)
4. Read Description  (unchanged)
5. **`^2Save Game`**  → action `save_game`
6. **`^3Load Last Save`**  → action `load_game` (visible only if `RPG.Save.HasSave(player)`)
7. **`^1Quit to Boot Menu`**  → action `quit_to_boot` (replaces existing "Quit RPG"; cleaner UX, returns to boot menu where user can pick Continue or New Game)

**Action handlers (added to onAction switch):**
- `save_game` → `RPG.Save.Write(player)`. On success: print `"^2Game saved (HH:MM)"` with timestamp from `os.date`. On failure: print `"^1Save failed: <err>"`.
- `load_game` → open `rpg_confirm` with body "Discard current session and load last save?" and `onConfirm = function() Save.Read + RestoreFromSnapshot end`.
- `quit_to_boot` → `RPG.Shutdown(player)`, then `RPG.SetState(player, "boot")`. (Note: after Shutdown there's no game, so SetState needs to handle the no-game case — see B above; boot is one of the special states allowed when game is nil.)

**SetState bootstrap support.** `state.lua:140-180` `RPG.SetState` already allows `intro`/`dream`/`class_select` when game is nil. Add `"boot"` to that allow-list.

#### 12.3.D `save.lua` helper additions

**`RPG.Save.AutoSave(player)`** — cooldown-respecting wrapper used by A1 timer and A2 checkpoints. Returns silently if within cooldown window. Returns `(ok, err)` otherwise via `RPG.Save.Write(player)`. Updates `game.lastSaveAt` on success.

**`RPG.Save.Delete(player)`** — removes the save file at `SavePath(GetPlayerKey(player))`. Returns `(ok, err)`. Also removes the legacy GUID file at `SavePath(GetGuidKey(player))` if it exists (cleans up post-migration ghosts). Used by Boot menu's New Game confirm.

**`RPG.Save.GetMetadata(player)`** — returns lightweight `{class, level, currentRoom, currentRoomName, savedAt}` table without full restore cost. Reads the JSON, decodes, validates version + class, extracts only the metadata fields, returns. ~30 LOC. Used by Boot menu Continue label + last-saved-at header. Cache the result in `game.cachedMetadata` to avoid re-reading on every menu render frame.

**`RPG.Save.StartAutoSaveTimer(player, game)`** — creates the periodic autosave timer for a player. Called by `RPG.NewGame` and `RPG.Save.RestoreFromSnapshot` after `saveKey` is cached. Idempotent (removes existing timer of same name first).

**`RPG.Save.StopAutoSaveTimer(clientNum)`** — removes the timer. Called by `RPG.Shutdown`.

#### 12.3.E Reusable confirm menu (`rpg_confirm`)

New menu file `menus/menu_confirm.lua` registered as state `"confirm"`. Generic two-choice confirmation used by both Boot menu's New Game flow and exploration menu's Load Last Save flow.

**State payload:** `{ title, body, onConfirm, onCancel }`. Stored on `game.confirmDialog` or as menu `state.data` (whichever is the existing pattern — TBD at plan-time, refer to other modal menus like cipher).

**Items:** `^2Confirm` / `^7Cancel`. Actions call the stored callbacks. `onCancel` defaults to "go back to previous state" if not provided.

**Why reusable:** Pays for itself by handling both confirms with one menu file, and gives Phase 1+ (companion dismissal, equipment swaps, etc.) a ready-made primitive.

#### 12.3.F Diagnostic command (`!rpgdebug save_status`)

Admin-only (perm ≥ 900 like other rpgdebug commands). Output:
- Cached `game.saveKey` (or "no session")
- Resolved save file path
- `File.Exists` result for that path
- Last save timestamp from `game.lastSaveAt` (formatted)
- Snapshot metadata via `GetMetadata`: class, level, room name, savedAt
- Cooldown status: time since last save vs cooldown window

Wire into existing `!rpgdebug` switch in `init.lua:328+`.

### 12.4 Config additions (`config.lua`)

```lua
RPG.Config.AUTOSAVE_INTERVAL_MS = 90000      -- Periodic autosave cadence
RPG.Config.AUTOSAVE_COOLDOWN_MS = 10000      -- Min ms between any saves (chain-fire defuse)
RPG.Config.AUTOSAVE_LOG_TO_PLAYER = false    -- Default off — silent autosave; admins can enable
RPG.Config.STATE_MENUS.boot = "rpg_boot"     -- Wire boot state to menu
RPG.Config.STATE_MENUS.confirm = "rpg_confirm"
```

### 12.5 Acceptance gate (5 tests, manual)

Phase 0 ships only when all five pass on the VPS:

1. **Graceful disconnect → reconnect → save loads.** Start fresh game, play 5 min, run `/disconnect`, reconnect to server, type `!rpg`, boot menu shows Continue with correct class/level/room, Continue restores.

2. **Quest complete → kill server → restart → save loads with quest complete.** Complete any quest (e.g., `!rpgdebug quest complete echoes`), kill the openjkded process (SIGKILL, no graceful shutdown), restart server, reconnect, `!rpg`, Continue → quest still complete in quest log.

3. **90s of play → kill server → restart → loads with ≤90s loss.** Start fresh, walk through 3–4 rooms, wait until 90s elapses (or watch for `[Debug]` autosave log if `AUTOSAVE_LOG_TO_PLAYER`), kill openjkded, restart, reconnect, `!rpg`, Continue → state intact at most one autosave-window behind.

4. **Boot New Game w/ confirm → save erased → boot shows no Continue.** With existing save, `!rpg` → boot menu → New Game → confirm dialog → Confirm → intro plays → `/disconnect` immediately → reconnect → `!rpg` → boot menu shows New Game only (no Continue), because Delete erased the file and the partial intro session never got far enough to autosave.

5. **In-game Save → in-game Load → state intact.** From exploration menu, expand Menu category, Save Game, move 5 rooms, expand Menu → Load Last Save → Confirm → back at original room with original state.

### 12.6 Sequencing

**Phase 0 ships before Phase 1.** No narrative work begins until all five acceptance tests pass. The Phase 1 playtest gate (§3.2) requires loading specific saved states — Phase 0 must exist for Phase 1 to be testable.

### 12.7 Memory-pillar mapping

Phase 0 is *infrastructure for every pillar*. Specific load-bearing connections:
- **Personal / Corrupted memory** (Phase 1 Karath dream, Mira blackouts): if the player can't trust that their progress sticks, the narrative beat "the game remembers what was done to your mind" loses its mechanical anchor.
- **Moral memory** (Doubt labels, Atton arc): a checkpoint after each major choice means the player's decisions feel weighty. Without checkpoints, decisions feel reversible.
- **Spatial memory** (Trophy Hall, ship rooms): only meaningful if room deltas persist across sessions. Phase 0's `roomDeltas` save format already supports this; checkpoint saves at quest complete are what lock the progressive Trophy Hall state.

### 12.8 Out of scope (explicit YAGNI)

- **Multiple save slots.** One save per account. KOTOR2 had multiple slots; we don't have menu real estate for a slot picker, and the user's stated problem is "losing progress," not "wanting to branch saves." Revisit only if playtest reveals demand.
- **Cloud sync / cross-server saves.** Saves are server-local. Different server = different save (intended).
- **Save export / import.** No support for moving saves between accounts or off-server. Operational risk + abuse vector with no clear payoff.
- **Mid-combat save.** A1 state gate skips combat. If player wants to save during combat, they exit to exploration first. Mid-combat save would require serializing combat state (turn order, enemy HP, pending effects) which doubles the snapshot complexity for a rare use case.
- **Manual save in dialogue / cipher_input / ending.** Same reason — restore from these states has narrow correctness windows. Players save before entering.

### 12.9 Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Disk thrash from chain-fire checkpoints (e.g., quest cascade triggers 3 completions in <1s) | A1 cooldown gate (10s default) absorbs this. `Save.Write` already costs ~5–20ms; even pre-cooldown a 3× burst is harmless. |
| Periodic timer fires during a frame that's already heavy (Lua GC pressure, per memory) | A1 fires from Timer (out-of-frame); `Save.Write` is mostly pure-function snapshot building + one `File.Write` syscall. Wrap snapshot build in `collectgarbage("stop"/"restart")` if profiling shows GC pressure (per project memory on Lua GC patterns). |
| GameShutdown hook doesn't fire on hard SIGKILL | Acceptable: A1 periodic 90s window covers this gap. Test #3 explicitly validates SIGKILL recovery. |
| Boot menu opens on `!rpg` for already-playing sessions (regression) | Boot is gated on `not RPG.IsPlaying(player)`. Existing reopen-current-menu path (`init.lua:261-267`) preserved. |
| `RPG.Save.Delete` accidentally fires while player has unsaved progress on a NEW account | New Game confirm dialog is the gate. The save being deleted is the one in `GetPlayerKey(player)`, which is the player's own — never another player's. |
