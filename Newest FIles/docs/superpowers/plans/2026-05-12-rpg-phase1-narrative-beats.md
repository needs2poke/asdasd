# RPG Phase 1 — Narrative Beats + One Persistent Flag Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 7 narrative beats from §3 of the v4 design (Iziz registry, Nalen Vorr 4-stage chain, Mimic-as-rehearsal, Saevus goal stair, cipher counter restraint, hyperspace dream, Truth-ending Force Sever bargain). One persistent flag (`forceSevered`), one new config constant (`PARANOIA_FLOOR_TRUTH = 30`). No new modules. Acceptance: 30-min targeted playtest from §3.2.

**Architecture:** Two layers.
- **Dialogue / data layer** (6 files, text-only edits): cipher print rule, Saevus manifest re-pitch, Saren security beat, Stalker ambient, Item 31 examine, Karath Vren paranoia-gated reveal, Saevus Manifestation cruel callback, hyperspace dream entry.
- **Mechanic layer** (4 files, one flag + one constant): `state.lua` initialises `forceSevered = false`; `config.lua` adds `PARANOIA_FLOOR_TRUTH`; `ending.lua` sets the flag + clamps paranoia at Truth Trigger and surfaces `forceSevered` in BuildEndingData stats; `menu_character.lua` + `menu_ending.lua` render `[ SEVERED ]` / `Force Connection: Severed`.

**Save compatibility:** New player field `forceSevered` defaults `nil` (falsy) for pre-Phase-1 saves loaded after deploy — no migration code needed. The existing JSON snapshot round-trips the field automatically because it serialises `game.player` whole.

**Tech Stack:** GLua (Lua 5.1 inside OpenJK `jampgame` DLL), `Menu` (centerprint), `Timer`, `File`. No automated test framework — verification is manual on the VPS per the project's edit/commit/push → deploy → in-game workflow.

**Source spec:** `docs/superpowers/specs/2026-05-12-rpg-echoes-enhancements-v4-design.md` §3 (v5.0, items #1-7).

**Deploy workflow reminder** (from project memory):
- Windows is edit/commit/push only. Compilation / Lua rsync happens on the Linux VPS.
- `restart_custom_server.sh -n` skips Lua rsync. **For Lua-only changes use the full deploy (no `-n`)**, or manually rsync to `~/NewSharding/openjk_home/base/glua/` before running `-n`.
- Deploy pulls `builder-shader-scanner-audit`. Push to that branch and verify the file on disk shows the change before testing.

---

## File Structure

**Files modified (no new files):**
- `base/glua/rpg/cipher.lua` — three-state rule on discovery counter print (Task 1, #6).
- `base/glua/rpg/data/dialogues/saevus_manifest.lua` — node 20 Iziz-registry / goal-stair rewrite (Task 2, #2+#5); node 21 + new node 65 Vorr callback (Task 7, #3d).
- `base/glua/rpg/data/dialogues/saren.lua` — node 22 rehearsal line (Task 3, #4).
- `base/glua/rpg/stalker.lua` — AMBIENT[2] Vorr whisper entry (Task 4, #3a).
- `base/glua/rpg/data/items.lua` — Item 31 scorched-ID reveal (Task 5, #3b).
- `base/glua/rpg/data/dialogues/karath_vren.lua` — node 20 paranoia-gated response + new node 25 (Task 6, #3c).
- `base/glua/rpg/narrative.lua` — `RPG.DreamText[1]` hyperspace dream entry (Task 8, #7).
- `base/glua/rpg/menus/menu_victory.lua` — PrintDream call before SetState (Task 8, #7).
- `base/glua/rpg/config.lua` — `PARANOIA_FLOOR_TRUTH` constant (Task 9, #1).
- `base/glua/rpg/state.lua` — `forceSevered = false` in NewGame player table (Task 9, #1).
- `base/glua/rpg/ending.lua` — Truth narration append, Trigger mutation, BuildEndingData stats (Task 9, #1).
- `base/glua/rpg/menus/menu_character.lua` — FP line SEVERED branch (Task 10, #1).
- `base/glua/rpg/menus/menu_ending.lua` — stats panel SEVERED line (Task 10, #1).

**Files created:** None.

---

## Task 1: Cipher discovery counter — three-state rule (Spec #6)

**Files:**
- Modify: `base/glua/rpg/cipher.lua:200-218` (inside `RPG.Cipher.OnItemExamined`)

**Rationale:** First two pickups are onboarding moments — show a styled `[Cipher fragment N/9 — keep gathering]` hint to teach the player that fragments exist and accumulate. From the third pickup onward, the discovery banner alone is enough; the menu carries the running total. Suppressing the trailing counter from #3 onward keeps the moment of discovery clean and rewards mastery.

- [ ] **Step 1: Replace the trailing counter section**

Find this block in `RPG.Cipher.OnItemExamined` (currently lines 206-218):

```lua
    -- Show discovery message
    player:SendPrint("")
    player:SendPrint("^2========================================")
    player:SendPrint("^2  CIPHER FRAGMENT DISCOVERED")
    player:SendPrint("^2========================================")
    player:SendPrint(source.hint)
    player:SendPrint("")
    player:SendPrint("^7Cipher progress: ^3" .. RPG.Cipher.GetProgressString(game))

    local total = 0
    for _ in pairs(RPG.Data.Cipher.sources) do total = total + 1 end
    local found = RPG.Cipher.GetDiscoveredCount(game)
    player:SendPrint("^7Fragments: " .. found .. "/" .. total)
    player:SendPrint("")
```

Replace with:

```lua
    -- Show discovery message
    player:SendPrint("")
    player:SendPrint("^2========================================")
    player:SendPrint("^2  CIPHER FRAGMENT DISCOVERED")
    player:SendPrint("^2========================================")
    player:SendPrint(source.hint)
    player:SendPrint("")

    -- Phase 1 (#6): three-state counter rule.
    -- Pickups 1-2 print a styled onboarding hint. Pickups 3+ suppress the
    -- trailing counter entirely — the cipher submenu carries the running total.
    local total = 0
    for _ in pairs(RPG.Data.Cipher.sources) do total = total + 1 end
    local found = RPG.Cipher.GetDiscoveredCount(game)
    if found == 1 or found == 2 then
        player:SendPrint("^3[Cipher fragment " .. found .. "/" .. total .. " -- keep gathering]")
        player:SendPrint("")
    end
```

- [ ] **Step 2: Verify Lua parses; commit; deploy; in-game spot-check**

Push, deploy with full rsync, then in-game examine any cipher-source item on a fresh save and confirm:
- 1st pickup → banner + `[Cipher fragment 1/9 -- keep gathering]`.
- 2nd pickup → banner + `[Cipher fragment 2/9 -- keep gathering]`.
- 3rd pickup → banner only, no trailing counter line.

Cipher submenu (`!rpgcipher` or menu route) must still show `X/Y` so the player can see overall progress.

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/cipher.lua
git commit -m "feat(rpg): cipher discovery — onboard pickups 1-2, suppress counter from 3 on"
```

---

## Task 2: Saevus Manifestation — Iziz registry + goal stair (Spec #2 + #5)

**Files:**
- Modify: `base/glua/rpg/data/dialogues/saevus_manifest.lua:259-288` (node 20 text)

**Rationale:** The two spec items are inseparable — Item #2 (Iziz children registry) IS the connector that makes Item #5's stair structure read as one escalation rather than two unrelated boasts. The new beat slots between Saevus's "losing everything I could teach you" lead and the existing Nathema / "use it on anything" pitch, giving the player a concrete seed-scale rehearsal stake before the world-scale and galaxy-scale beats.

- [ ] **Step 1: Replace node 20 `text` table**

Locate node 20 in `saevus_manifest.lua` (currently lines 259-288). Replace the `text = { ... }` block (lines 261-271) with:

```lua
        text = {
            "'For this moment. The moment you stand",
            "at the threshold of the cipher chamber",
            "and realize that sealing me away means",
            "losing everything I could teach you.'",
            "",
            "'Start small. The sealed registry beneath",
            "the Iziz cathedral. Twelve hundred names --",
            "Force-sensitive children, hidden from the Jedi.'",
            "",
            "'A seed-scale dress rehearsal. Walls",
            "instead of a world. Names instead of stars.",
            "Vitiate consumed Nathema. I would start",
            "with Iziz -- and teach you to scale up.'",
            "",
            "'The ritual of consumption. The power",
            "to drain a world's connection to the Force.",
            "Vitiate used it on Nathema.",
            "I could teach you to use it on anything.'",
        },
```

Do NOT touch the `responses` table below it — the existing three response options stay.

- [ ] **Step 2: Verify Lua parses; in-game read-through**

Push, deploy, walk to the Saevus Manifestation encounter (Room 48 Hidden Entrance), navigate to node 20 ("What have you been preparing me for?"). Confirm the text reads as one escalating stair: Iziz registry (small) → Nathema (continent) → anything (galaxy).

If the rhythm feels off in playtest, revise this task's text before moving on — this is the spec's "if any beat feels flat, revise that item before opening Phase 2A" gate applied early.

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/data/dialogues/saevus_manifest.lua
git commit -m "feat(rpg): Saevus pitch — Iziz registry rehearsal, escalating goal stair"
```

---

## Task 3: Saren — Mimic-as-rehearsal beat (Spec #4)

**Files:**
- Modify: `base/glua/rpg/data/dialogues/saren.lua:344-355` (node 22 text)

**Rationale:** Saren is the first NPC who can articulate that the Mimic is not just a hostile clone but a *practice run*. The added beat plants the foreshadowing in Act 2 so the Saevus Manifestation in Act 5 lands as confirmation, not exposition. Pinned to node 22 because node 23 already routes via `setStage` to `confront_truth`; the rehearsal line must appear before Q16 advances.

- [ ] **Step 1: Replace node 22 `text` table**

Locate node 22 in `saren.lua` (currently lines 343-355). Replace the `text = { ... }` block with:

```lua
        text = {
            "He zooms in. The purple-eyed figure's hands...",
            "'^7Stars. Its hands aren't solid. Look -- the fingers",
            "pass through the wall when it touches it.'",
            "'^7It's not a person. It's a projection. A Force",
            "construct given physical form.'",
            "",
            "He pauses. His jaw tightens.",
            "'^7No. Not a copy. A ^1rehearsal^7. Whatever's",
            "piloting this thing is practicing.'",
            "",
            "'^7That means it has a source. Cut the source and",
            "the projection dies.'",
            "He looks at you meaningfully.",
            "'^7The source is the artifact you carry. Isn't it?'",
        },
```

Do NOT touch the `effects` or `responses` block. The existing `setStage = { quest = "the_mimic", stage = "confront_truth" }` and the response routing to node 23 are unchanged.

- [ ] **Step 2: In-game read-through**

Push, deploy, advance Q16 (the_mimic) to `investigate_footage` stage, visit Saren, and step through to node 22. Confirm the rehearsal line reads as foreshadowing — Saren is the security captain piecing it together, not narrating a thesis. If `^1rehearsal^7` reads as too on-the-nose, soften to `dry run` or `dress rehearsal` and re-deploy.

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/data/dialogues/saren.lua
git commit -m "feat(rpg): Saren security footage — Mimic is a rehearsal, not a copy"
```

---

## Task 4: Stalker AMBIENT — Vorr whisper (Spec #3a, stage 1 of 4)

**Files:**
- Modify: `base/glua/rpg/stalker.lua:25-30` (AMBIENT[2] — Watching stage)

**Rationale:** First stage of the four-stage Nalen Vorr name-reveal chain. Plants the syllable as a broken whisper at Stalker Watching stage 2 so the player encounters it as ambient horror before any character names it. Appears as a 5th entry in the existing list, so it fires roughly 1-in-5 stalker-tick rolls — frequent enough to register over multiple Watching-stage rooms, rare enough to feel discovered.

- [ ] **Step 1: Append the whisper to AMBIENT[2]**

Locate the `AMBIENT` table in `stalker.lua` (currently lines 18-37). Replace the `[2] = { ... }` block (currently lines 25-30) with:

```lua
    [2] = {  -- Watching
        "^1A dark figure stands at the edge of your vision. When you turn, it's gone.",
        "^1You catch a glimpse of brown robes disappearing around a corner.",
        "^1The Force pulses with warning. Something is close. Tracking you.",
        "^1In a reflective surface, you see a second shadow behind yours.",
        "^8A broken whisper follows you: '...Vorr...'",
    },
```

Do NOT touch AMBIENT[1] or AMBIENT[3] — those are Hidden and Hunting stages, where the whisper would feel out of order in the reveal chain.

- [ ] **Step 2: In-game spot-check**

Push, deploy, advance to Stalker Watching stage (Act 2 rooms after Q15 reaches `analysis_pending` and 4 Act 2 room moves), traverse 5-10 Act 2 rooms. Expected: at least one ambient roll lands on the Vorr whisper. The other four entries continue to fire as before. There must be NO other place in the game (Items, dialogues, exam text) that already names Vorr — verify with a `git grep -i "vorr"` post-edit; only this new line should appear.

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/stalker.lua
git commit -m "feat(rpg): Stalker Watching — broken whisper plants Vorr name (1/4)"
```

---

## Task 5: Item 31 — Dark Crystal Fragment scorched ID (Spec #3b, stage 2 of 4)

**Files:**
- Modify: `base/glua/rpg/data/items.lua:269-274` (Item 31 examineText)

**Rationale:** Second stage of the Vorr reveal chain. The Dark Crystal Fragment drops from the player's first Stalker survival — by the time they examine it, they've heard the whisper at least once. The scorched ID imprint visually upgrades the syllable into a full name attached to a Jedi Shadow rank. Discovery, not exposition.

- [ ] **Step 1: Replace Item 31 examineText**

Locate Item 31 in `items.lua` (currently lines 269-274). Replace the `examineText` value with:

```lua
        examineText = "[DARK CRYSTAL FRAGMENT]\n\nThe shard is warm to the touch and vibrates at a subsonic frequency.\nHolding it near the Holocron causes both to resonate.\n\nEtched into the crystal's lattice, visible only under\nForce-enhanced perception:\n'^3 9 ^7'\n\nA single digit. Part of something larger.\n\nAt a different angle the lattice catches the light --\na scorched identification imprint, half-erased:\n\n'^1NALEN VORR, JEDI SHADOW^7'\n\nThe Shadow had a name.",
```

Do NOT touch `name`, `description`, or `type`. The `9` cipher digit must remain — this is one of the four cipher-source items (per spec §3.1 #6 redundancy note in Phase 1 scope).

- [ ] **Step 2: In-game examine check**

Push, deploy. From an Act 2 save where the player has survived one Stalker encounter and holds Item 31, open inventory → examine Fragment of Dark Crystal. Confirm both reveals appear in order: the `9` digit first, then the scorched `NALEN VORR, JEDI SHADOW` imprint, then the `The Shadow had a name.` button-line.

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/data/items.lua
git commit -m "feat(rpg): Dark Crystal Fragment — scorched ID names Nalen Vorr (2/4)"
```

---

## Task 6: Karath Vren — paranoia ≥85 Vorr identity reveal (Spec #3c, stage 3 of 4)

**Files:**
- Modify: `base/glua/rpg/data/dialogues/karath_vren.lua:472-497` (node 20 add 4th response)
- Modify: `base/glua/rpg/data/dialogues/karath_vren.lua:518` (insert new node 25 before final closing `}`)

**Rationale:** Third stage. Once the player has the whisper (Task 4) AND the imprint (Task 5), Karath — the previous Jedi Shadow's ghost — can contextualise Vorr as "the Shadow before me." Gated on `paranoia >= 85` AND `loreDiscovered[31]` so the line only appears when the player has earned the evidence chain. New node 25 lives where node 16 ends and node 20 begins (it's currently a numerical gap).

- [ ] **Step 1: Add 4th response on node 20**

Locate node 20 in `karath_vren.lua` (currently lines 472-497). Replace the `responses = { ... }` block with:

```lua
        responses = {
            {
                label = "Tell me about the cipher.",
                next = 12,
            },
            {
                label = "What about the Sith who built the prison?",
                next = 14,
            },
            {
                label = "I keep hearing a name. 'Vorr.' Who is that?",
                next = 25,
                condition = function(g)
                    return g.player.paranoia >= 85
                        and g.loreDiscovered and g.loreDiscovered[31]
                end,
            },
            {
                label = "Rest now. I have what I need.",
                next = 15,
            },
        },
```

The new Vorr response sits third so it appears between Sith-of-the-prison and Rest-now — a discovery question, not a closer.

- [ ] **Step 2: Insert new node 25 before final closing `}`**

Find the end of `karath_vren.lua` — node 50 currently closes at line 517, followed by `}` on line 518 (the table close). Immediately BEFORE that closing `}`, insert:

```lua
    -- ============================================
    -- NODE 25: Paranoia >= 85 + Item 31 examined — Nalen Vorr identity reveal
    -- ============================================
    [25] = {
        speaker = "Echo of Karath Vren",
        text = {
            "The ghost stares at you for a long",
            "moment. Recognition softens her edges.",
            "",
            "'Nalen Vorr. The Shadow before me.'",
            "",
            "'Nalen was my handler. My warning.",
            "My future. I never reached him in time.",
            "Now he hunts you -- because that is",
            "what is left of him.'",
            "",
            "'I am sorry. There is no peace at the end",
            "of this road. Only the next Shadow.'",
        },
        responses = {
            {
                label = "Then I'll finish what he couldn't.",
                next = 15,
                effects = { alignment = 5 },
            },
            {
                label = "[Leave]",
                next = -1,
            },
        },
    },
```

- [ ] **Step 3: In-game gated-reveal check**

Push, deploy. From an Act 3 save with `paranoia >= 85` AND Item 31 examined, visit Karath Vren's return-visit node (node 20). Confirm the Vorr response appears. Either response from node 25 must route back into the existing tree (15 closes the conversation; `[Leave]` exits via `-1`). On a low-paranoia save or one where Item 31 wasn't examined, the response must NOT appear.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/data/dialogues/karath_vren.lua
git commit -m "feat(rpg): Karath Vren — paranoia-gated Vorr reveal (3/4)"
```

---

## Task 7: Saevus Manifestation — Vorr cruel callback (Spec #3d, stage 4 of 4)

**Files:**
- Modify: `base/glua/rpg/data/dialogues/saevus_manifest.lua` — node 21 add gated response, append new node 65

**Rationale:** Final stage of the four-stage reveal. By the time the player confronts the Saevus Manifestation in Act 5, they have the syllable, the imprint, and Karath's grief-stricken context. Saevus weaponises the name back at them — Vorr is no longer mystery, he's *competition*. Gated on the same two conditions as Task 6 so the chain stays internally consistent.

**Node ID collision check (verified before drafting):** `saevus_manifest.lua` already uses node IDs 0, 1, 5, 10, 11, 12, 13, 20, 21, 25, 26, 30, 35, 40, 55, 60. Node 35 is the existing **Dark Bargain Accepted** branch — using it here would break the Dark path. Node 65 is the next clean slot above the existing range and is the chosen ID.

- [ ] **Step 1: Add gated response on node 21**

Locate node 21 in `saevus_manifest.lua` (the "paranoia was you?" beat — starts at line 293). Open it and append a NEW response to the existing `responses` table, before the closing `},`:

```lua
            {
                label = "Then say his name. Vorr.",
                next = 65,
                condition = function(g)
                    return g.player.paranoia >= 85
                        and g.loreDiscovered and g.loreDiscovered[31]
                end,
            },
```

(Place after the last existing response in node 21 and before the closing `},` for the response array.)

- [ ] **Step 2: Append node 65**

At the bottom of the Saevus Manifestation dialogue table — find the closing `}` that ends the table after node 60 (node 60 starts at line 540; the table close is the final `}` near the end of the file). Insert BEFORE that final `}`:

```lua
    -- ============================================
    -- NODE 65: Paranoia >= 85 + Item 31 examined — Vorr cruel callback
    -- (Node 35 is taken — Dark Bargain Accepted branch.)
    -- ============================================
    [65] = {
        speaker = "Saevus Manifestation",
        text = {
            "Saevus laughs. The sound is dry, ancient.",
            "",
            "'Vorr. Yes. I remember Vorr.'",
            "",
            "'He came further than you. He held",
            "his name longer than you have. He was",
            "more disciplined, more clever, more lit",
            "from within than you will ever be.'",
            "",
            "'^1Vorr lasted longer than you will.^7'",
            "",
            "'And now he is a hunger in a brown robe.",
            "Soon, so are you.'",
        },
        responses = {
            {
                label = "I am not Vorr.",
                next = 12,
            },
        },
    },
```

The response routes back into node 12 (Saevus's main "What do you want?" beat) so the encounter doesn't dead-end on cruelty.

- [ ] **Step 3: In-game gated-callback check**

Push, deploy. With a paranoia-≥85, Item-31-examined save, walk into Saevus Manifestation (Act 5), navigate to node 21, confirm the "Then say his name. Vorr." response appears. Selecting it routes to node 65, prints the four beats above, and offers the single "I am not Vorr." response that returns to node 12. On a save that hasn't crossed both gates, the response must NOT appear.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/data/dialogues/saevus_manifest.lua
git commit -m "feat(rpg): Saevus Manifestation — Vorr cruel callback closes the chain (4/4)"
```

---

## Task 8: Mid-hyperspace dream beat (Spec #7)

**Files:**
- Modify: `base/glua/rpg/narrative.lua:224-234` (add `RPG.DreamText[1]`)
- Modify: `base/glua/rpg/menus/menu_victory.lua:74-80` (insert `RPG.PrintDream(player, 1)` call)

**Rationale:** Pure additive flavor — a five-line dream sequence between Act 1 and Act 2's "Continue to Onderon" continue-button. Reuses the existing `RPG.PrintDream` plumbing so there's no new infrastructure. Cuttable if it reads as filler in the §3.2 playtest gate (spec explicitly authorises cutting #7).

- [ ] **Step 1: Add `RPG.DreamText[1]` entry**

Locate `RPG.DreamText` in `narrative.lua` (currently lines 224-234). Replace the table with:

```lua
RPG.DreamText = {
    [0] = {
        "^8Darkness. Then -- metal tearing.",
        "^7The smell of ozone and burning flesh.",
        "^7You are falling. The ground rushes up--",
        "",
        "^1A purple light pulses in the wreckage.",
        "^8[WHISPER] ^1...come to us...",
        "^3[FORCE VISION]",
    },
    [1] = {
        "^3[HYPERSPACE -- DREAM]",
        "",
        "^7The Wanderer's engines hum at the edge of",
        "^7hearing. You are not in your cabin.",
        "",
        "^8A long corridor of broken durasteel.",
        "^8Brown robes ahead, just out of reach.",
        "^8The figure does not turn. You cannot run.",
        "",
        "^1A voice that is not yours says: 'You are",
        "^1the next of us. We have always been waiting.'",
        "",
        "^7You wake up. The viewport shows Onderon.",
    },
}
```

The `[0]` entry stays byte-for-byte identical so the class-select dream menu (`menu_dream.lua`) continues to read `RPG.DreamText[0]` correctly.

- [ ] **Step 2: Wire PrintDream call into the victory continue path**

Locate the `onAction` "continue" branch in `menu_victory.lua` (currently lines 48-81). Find the existing closing block:

```lua
            player:SendPrint("")
            player:SendPrint("^5  Reports reach you in transit: the Jedi")
            player:SendPrint("^5  Shadow's body has vanished from the crash")
            player:SendPrint("^5  site. The containment team found an empty")
            player:SendPrint("^5  hold and claw marks on the walls.")
            player:SendPrint("")

            -- Wire ship↔Onderon exits now that Act 2 is active
            if game.rooms[16] then game.rooms[16].exits.North = 26 end
            if game.rooms[26] then game.rooms[26].exits.West = 16 end

            RPG.SetState(player, "exploration")
```

Insert the dream call between the second `player:SendPrint("")` and the ship-exits wiring:

```lua
            player:SendPrint("")
            player:SendPrint("^5  Reports reach you in transit: the Jedi")
            player:SendPrint("^5  Shadow's body has vanished from the crash")
            player:SendPrint("^5  site. The containment team found an empty")
            player:SendPrint("^5  hold and claw marks on the walls.")
            player:SendPrint("")

            -- Phase 1 (#7): mid-hyperspace dream beat (additive flavor; cuttable)
            if RPG.PrintDream then
                RPG.PrintDream(player, 1)
            end

            -- Wire ship↔Onderon exits now that Act 2 is active
            if game.rooms[16] then game.rooms[16].exits.North = 26 end
            if game.rooms[26] then game.rooms[26].exits.West = 16 end

            RPG.SetState(player, "exploration")
```

The `if RPG.PrintDream then` guard mirrors the defensive pattern Phase 0 used for save hooks — if `narrative.lua` failed to load for any reason, the continue path still routes the player to Act 2.

- [ ] **Step 3: In-game beat playthrough**

Push, deploy. From a save just before the Act 1 → Act 2 transition (or a fresh save run through Act 1), trigger the victory menu, press CONTINUE. Watch the console: the existing Wanderer / Onderon narration prints, then the new dream lines (`[HYPERSPACE -- DREAM]` to `You wake up. The viewport shows Onderon.`), then the player drops into Room 26 (Iziz Spaceport).

If the dream reads as filler or breaks pacing, revert this task per spec §3.2: cut #7 from the Phase-1 plan.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/narrative.lua base/glua/rpg/menus/menu_victory.lua
git commit -m "feat(rpg): mid-hyperspace dream beat between Acts 1 and 2"
```

---

## Task 9: Truth-ending Force Sever — flag, paranoia floor, narration, ending stats (Spec #1, logic half)

**Files:**
- Modify: `base/glua/rpg/config.lua:230-232` (add `PARANOIA_FLOOR_TRUTH` constant near other ending constants)
- Modify: `base/glua/rpg/state.lua:46-72` (add `forceSevered = false` to NewGame player table)
- Modify: `base/glua/rpg/ending.lua:84-104` (append 3 lines to truth narration)
- Modify: `base/glua/rpg/ending.lua:161-173` (add `forceSevered` to BuildEndingData stats)
- Modify: `base/glua/rpg/ending.lua:182-198` (set flag + clamp paranoia in Trigger, BEFORE BuildEndingData)

**Rationale:** The mechanical core of the spec's headline beat — Truth ending earns its "free" outcome by costing the player their Force connection and pinning paranoia at a floor. The flag is one boolean, the floor is one constant, and Trigger mutates state BEFORE BuildEndingData runs so the ending-screen stats panel correctly reflects the cost. Task 10 then renders both.

**Trigger order matters:** the existing `Trigger` calls `AutoSave` first (pre-ending checkpoint — Phase 0 spec). The new mutation block MUST go AFTER that AutoSave (so restart-during-ending replays the cost from the pre-ending state, not from the mutated state) but BEFORE `BuildEndingData` (so the stats panel captures the new paranoia and flag).

- [ ] **Step 1: Add `PARANOIA_FLOOR_TRUTH` constant**

In `config.lua`, find the ending block at lines 230-232:

```lua
RPG.Config.ENDING_LIGHT_ALIGNMENT = 50
RPG.Config.ENDING_DARK_ALIGNMENT = -50
RPG.Config.ENDING_HORROR_PARANOIA = 100
```

Replace with:

```lua
RPG.Config.ENDING_LIGHT_ALIGNMENT = 50
RPG.Config.ENDING_DARK_ALIGNMENT = -50
RPG.Config.ENDING_HORROR_PARANOIA = 100

-- Phase 1 (#1): Truth-ending Force Sever bargain — Trigger clamps paranoia to >= this floor.
RPG.Config.PARANOIA_FLOOR_TRUTH = 30
```

- [ ] **Step 2: Initialise `forceSevered = false` in NewGame**

In `state.lua`, find the player init block (currently lines 46-72). The block ends with `pendingStatPoints = 0,`. Replace that closing line with:

```lua
            pendingStatPoints = 0,
            forceSevered = false,    -- Phase 1 (#1): Truth-ending Force Sever bargain marker
```

Leave the closing `},` for the player table on the next line as-is. Pre-Phase-1 saves loaded after deploy will read `nil` for this field, which evaluates falsy — no migration needed.

- [ ] **Step 3: Append 3-line Sever-bargain narration to Truth ending**

In `ending.lua`, find the `truth` entry in the ENDINGS table (currently lines 81-105). Replace the `narration = { ... }` block with:

```lua
        narration = {
            "^7You speak the name aloud:",
            "^3\"DARTH SAEVUS THE FORGOTTEN.\"",
            "",
            "^7The chamber goes silent.",
            "^7The Holocron stops pulsing.",
            "^7For the first time since the crash site,",
            "^7your mind is completely, utterly quiet.",
            "",
            "^2The cipher seals the prison -- permanently.",
            "^2The containment protocols lock into place.",
            "^2What was forgotten stays forgotten.",
            "",
            "^7You walk out of the chamber.",
            "^7The sun is warm on your face.",
            "^7The galaxy doesn't know what you did.",
            "",
            "^2But you do.",
            "^2And you are free.",
            "",
            "^7But there is a price.",
            "^8You feel the Force recede -- not gone, but quieted.",
            "^8A wound you can never close.",
        },
```

The new triplet sits AFTER the existing `^2And you are free.` closer so the original narrative resolution lands first, then the Sever cost arrives as the final beat.

- [ ] **Step 4: Add `forceSevered` to BuildEndingData stats**

In `ending.lua`, locate `RPG.Ending.BuildEndingData` (currently lines 143-174). Replace the `stats = { ... }` table with:

```lua
        stats = {
            class = className,
            level = p.level,
            alignment = p.alignment,
            paranoia = p.paranoia,
            questsCompleted = questsCompleted,
            forceSevered = p.forceSevered or false,    -- Phase 1 (#1): Truth-ending only
        },
```

For non-Truth endings the field is always `false` (or the pre-existing value of `p.forceSevered`, which is also `false` outside the Truth path). Task 10's render code reads this field on the ending screen only and skips the line when it's false.

- [ ] **Step 5: Mutate `forceSevered` + paranoia in Trigger before BuildEndingData**

In `ending.lua`, locate `RPG.Ending.Trigger` (currently lines 182-239). The existing prelude is:

```lua
function RPG.Ending.Trigger(player, endingType)
    local game = RPG.GetGame(player)
    if not game then return end

    -- Phase 0 checkpoint: capture pre-ending state so restart-during-ending replays from choice
    if RPG.Save and RPG.Save.AutoSave then
        RPG.Save.AutoSave(player)
    end

    local endingData = RPG.Ending.BuildEndingData(game, endingType)
```

Insert the new mutation block between the AutoSave and the BuildEndingData call:

```lua
function RPG.Ending.Trigger(player, endingType)
    local game = RPG.GetGame(player)
    if not game then return end

    -- Phase 0 checkpoint: capture pre-ending state so restart-during-ending replays from choice
    if RPG.Save and RPG.Save.AutoSave then
        RPG.Save.AutoSave(player)
    end

    -- Phase 1 (#1): Truth ending applies the Force Sever bargain BEFORE BuildEndingData
    -- so the stats panel reflects the cost.
    --
    -- ORDER RATIONALE (do not "fix" by mutating before AutoSave):
    -- AutoSave above writes the PRE-Sever state. If a player crashes between
    -- AutoSave and this mutation, restarting replays from the pre-Sever save —
    -- they re-experience the bargain text and re-trigger the cost. This is
    -- intentional. Mutating before AutoSave would lock a crashed player into
    -- Severed-on-reload without ever showing them the narration that explained
    -- the price.
    if endingType == "truth" then
        game.player.forceSevered = true
        local floor = RPG.Config.PARANOIA_FLOOR_TRUTH or 30
        if game.player.paranoia < floor then
            game.player.paranoia = floor
        end
    end

    local endingData = RPG.Ending.BuildEndingData(game, endingType)
```

The rest of `Trigger` stays unchanged.

- [ ] **Step 6: Reload server, run a smoke probe**

Push, deploy. After restart, in-game:
1. Open chat: `!rpgreload` (or restart server). Watch console for `RPG: Ending system loaded` with no Lua errors.
2. On a save where the player has the cipher solved and `truthUnlocked = true`, walk into Room 50 → choose the Up exit (Room 54 The Truth). The ending must:
   - Print the existing Truth narration AND the appended 3-line Sever-bargain coda.
   - The post-ending state must record `forceSevered = true` and `paranoia >= 30` (verify on a fresh re-trigger if needed — endings transition to `ending` state which terminates the run, so the verification is via observed narration only at this task; Task 10 wires the on-screen markers).

If the smoke probe fails, fix this task before progressing to Task 10 — Task 10 depends on the data flow this task installs.

- [ ] **Step 7: Commit**

```bash
git add base/glua/rpg/config.lua base/glua/rpg/state.lua base/glua/rpg/ending.lua
git commit -m "feat(rpg): Truth ending Force Sever — flag, paranoia floor 30, narration coda"
```

---

## Task 10: Truth-ending Force Sever — character sheet + ending menu render (Spec #1, UI half)

**Files:**
- Modify: `base/glua/rpg/menus/menu_character.lua:58-62` (HP+FP line — SEVERED branch)
- Modify: `base/glua/rpg/menus/menu_ending.lua:37-50` (stats panel — Force Connection line)

**Rationale:** Task 9 installed the data. This task surfaces the cost in two places: the always-visible character sheet (so the player carrying a Severed save sees the wound continuously) and the terminal ending stats panel (so the cost is unmissable on the screen that ends the run).

**Render-path scope (verified before drafting):** `menu_ending.lua` `getItems` exposes only `End RPG Session` — there is NO route from the ending menu to the character sheet. Therefore:
- The **ending stats panel** (`menu_ending.lua` change below) is the **primary visibility surface** for the current Phase 1 run. It MUST show `Force Connection: Severed` on the Truth ending screen.
- The **character sheet** (`menu_character.lua` change below) is **forward-compatibility for post-game modes** (post-ending free roam, sequel saves, save-file inspection tooling). It does NOT activate for the current Truth-ending run because the run terminates at the ending menu. Ship it anyway — the cost is one branch in an existing block, the payoff comes when a future phase opens post-ending exploration.

- [ ] **Step 1: Branch the FP line in menu_character.lua**

Locate the FP rendering block in `menu_character.lua` (currently lines 58-62):

```lua
        -- HP + FP combined on one line
        local hpfp = "^2HP " .. RPG.Util.HealthBar(p.hp, p.maxHP, cw)
        if p.maxFP > 0 then
            hpfp = hpfp .. " ^5FP " .. RPG.Util.HealthBar(p.fp, p.maxFP, cw)
        end
        lines[#lines + 1] = hpfp
```

Replace with:

```lua
        -- HP + FP combined on one line. Phase 1 (#1): Severed Truth-ending players
        -- render "FP [ SEVERED ]" in grey instead of the normal bar.
        local hpfp = "^2HP " .. RPG.Util.HealthBar(p.hp, p.maxHP, cw)
        if p.forceSevered then
            hpfp = hpfp .. " ^8FP [ SEVERED ]"
        elseif p.maxFP > 0 then
            hpfp = hpfp .. " ^5FP " .. RPG.Util.HealthBar(p.fp, p.maxFP, cw)
        end
        lines[#lines + 1] = hpfp
```

Order matters: `forceSevered` wins over the `maxFP > 0` branch, so even classes with non-zero maxFP (Guardian, Consular, Sentinel) render as Severed when the flag is set.

- [ ] **Step 2: Add Force Connection line to ending stats panel**

Locate the stats panel block in `menu_ending.lua` (currently lines 37-50):

```lua
        -- Final stats
        if ed.stats then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "^3Class: ^7" .. ed.stats.class
            lines[#lines + 1] = "^3Level: ^7" .. ed.stats.level
            local alignLabel = "Neutral"
            if ed.stats.alignment >= 50 then
                alignLabel = "^5Light Side"
            elseif ed.stats.alignment <= -50 then
                alignLabel = "^1Dark Side"
            end
            lines[#lines + 1] = "^3Alignment: ^7" .. ed.stats.alignment .. " (" .. alignLabel .. "^7)"
            lines[#lines + 1] = "^3Paranoia: ^7" .. ed.stats.paranoia
            lines[#lines + 1] = "^3Quests: ^7" .. ed.stats.questsCompleted .. " completed"
        end
```

Replace with:

```lua
        -- Final stats
        if ed.stats then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "^3Class: ^7" .. ed.stats.class
            lines[#lines + 1] = "^3Level: ^7" .. ed.stats.level
            local alignLabel = "Neutral"
            if ed.stats.alignment >= 50 then
                alignLabel = "^5Light Side"
            elseif ed.stats.alignment <= -50 then
                alignLabel = "^1Dark Side"
            end
            lines[#lines + 1] = "^3Alignment: ^7" .. ed.stats.alignment .. " (" .. alignLabel .. "^7)"
            lines[#lines + 1] = "^3Paranoia: ^7" .. ed.stats.paranoia
            -- Phase 1 (#1): Truth-ending Force Sever cost — surfaced on the ending screen itself
            if ed.stats.forceSevered then
                lines[#lines + 1] = "^3Force Connection: ^1Severed"
            end
            lines[#lines + 1] = "^3Quests: ^7" .. ed.stats.questsCompleted .. " completed"
        end
```

The Severed line sits between Paranoia and Quests, so it reads as a status row, not an afterthought.

- [ ] **Step 3: End-to-end in-game verification**

Push, deploy. From a save with cipher solved + `truthUnlocked = true`:
1. Open character sheet (state `character_sheet`). Confirm FP renders normally (since the flag isn't set yet pre-ending).
2. Walk into Room 50 → Up exit (Room 54 The Truth) → trigger the Truth ending.
3. On the ending menu, confirm:
   - The 3-line Sever-bargain coda from Task 9 prints in narration.
   - The stats panel shows `Force Connection: Severed` between `Paranoia: ...` and `Quests: ... completed`.
   - The displayed `Paranoia: ...` value is `>= 30` even if the save's pre-ending paranoia was lower.

The `menu_character.lua` SEVERED branch is NOT verifiable in this run — per the Rationale block above, the ending menu has no character-sheet route. Verify the FP branch via static read (open `menu_character.lua` and confirm `if p.forceSevered then ... ^8FP [ SEVERED ]` precedes the `elseif p.maxFP > 0` branch). The branch ships as forward-compat; in-game verification is deferred to whenever a future phase adds a post-ending free-roam or sequel save load.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/menus/menu_character.lua base/glua/rpg/menus/menu_ending.lua
git commit -m "feat(rpg): Truth ending UI — character sheet SEVERED, ending stats Force Connection"
```

---

## Task 11: Phase 1 acceptance playtest (Spec §3.2)

**Files:** None — this is a 30-minute targeted playtest, run on the VPS by the user. The five beats are sequenced per the spec's "Beats 1, 3, 4, 2, 7 in order" instruction.

**Rationale:** Phase 1 is text and one flag — automated tests don't apply. The acceptance gate is the spec's prescribed beat-by-beat read-through. If any beat reads flat, revise that task's text BEFORE marking Phase 1 complete; the cost of revising at this stage is one task touch-up, the cost of revising in Phase 2A is rework on top of partially-built work.

- [ ] **Step 1 — Beat 1 (Truth ending Sever bargain): high-paranoia + truth-unlocked save**

Load a save with `truthUnlocked = true` and any paranoia value (test both low and high — the floor must clamp). Walk through Room 50 → Up → Room 54 The Truth.

Verify:
- The 3-line Sever-bargain coda prints after the existing Truth narration (`But there is a price. / You feel the Force recede -- not gone, but quieted. / A wound you can never close.`).
- The ending stats panel shows `Force Connection: Severed` between Paranoia and Quests.
- Paranoia displayed is `>= 30` regardless of pre-ending value.

If any of the three checks fails, revise Task 9 / Task 10 and re-deploy before continuing.

- [ ] **Step 2 — Beat 3 (Nalen Vorr 4-stage discovery chain)**

Load an Act 2 save where the Stalker is in the `analysis_pending` quest stage and at least one room move has happened. Walk 5-10 Act 2 rooms.

Verify in order:
- (a) Within ~5 rooms in Watching stage, at least one ambient roll produces `^8A broken whisper follows you: '...Vorr...'`.
- (b) Survive the first Stalker encounter to receive Item 31. Open inventory → examine Fragment of Dark Crystal. Verify the scorched `NALEN VORR, JEDI SHADOW` imprint is present alongside the existing `9` cipher digit.
- (c) Travel to Act 3, visit Karath Vren's return-visit node 20 on a save with paranoia `>= 85`. Verify the response `I keep hearing a name. 'Vorr.' Who is that?` appears. Select it; verify node 25's content (`Nalen Vorr. The Shadow before me.` ... `Only the next Shadow.`).
- (d) In Act 5, visit Saevus Manifestation node 21 on the same save (paranoia ≥85 + Item 31 examined). Verify the response `Then say his name. Vorr.` appears. Select it; verify node 65's cruel callback (`Vorr lasted longer than you will.`).

If the chain reads as exposition rather than discovery on any stage, revise that task's text.

- [ ] **Step 3 — Beat 4 (Saren — Mimic-as-rehearsal)**

Load a Q16 (the_mimic) save at `investigate_footage` stage. Visit Captain Saren in the Iziz Security Checkpoint. Step through to node 22.

Verify the inserted `'^7No. Not a copy. A ^1rehearsal^7. Whatever's piloting this thing is practicing.'` lines appear between the existing Force-projection description and the cut-the-source response. Verify Q16 still advances to `confront_truth` via node 23.

If the rehearsal beat reads as on-the-nose exposition, revise Task 3 (soften to "dry run" or "dress rehearsal") and re-deploy.

- [ ] **Step 4 — Beat 2 (Saevus Manifestation Iziz registry / goal stair)**

Load any Act 5 save with the Saevus Manifestation accessible. Walk to Room 48 Hidden Entrance, engage Saevus, navigate to node 20 (`What have you been preparing me for?`).

Verify the rewritten text reads as a stair (Iziz registry — twelve hundred children → seed-scale rehearsal → Nathema (Vitiate's work) → anything). The new 8 lines must sit between the existing "losing everything I could teach you" lead and the existing "ritual of consumption" beat.

If the stair structure feels muddled (e.g., the Iziz beat reads as a parallel boast rather than the small step), revise Task 2's text and re-deploy.

- [ ] **Step 5 — Beat 7 (hyperspace dream — cut/keep decision)**

Trigger the Act 1 → Act 2 transition. Press CONTINUE on the victory menu.

Verify the dream beat (`[HYPERSPACE -- DREAM]` through `You wake up. The viewport shows Onderon.`) prints between the existing Wanderer/Onderon narration and the player landing in Room 26.

Decide: does the dream read as tonal fit, or as filler that breaks the menu pacing? If fit — keep it. If filler — revert Task 8 (`git revert <task-8-sha>`) and re-deploy. The spec explicitly authorises this cut.

- [ ] **Step 6 — Phase 1 acceptance wrap-up**

After all five beats pass (or after any reverts are landed), record the playtest outcome in a wrap-up commit:

```bash
git commit --allow-empty -m "chore(rpg): Phase 1 acceptance gate passed (5/5 beats)" \
  -m "Beats 1/3/4/2/7 confirmed in 30-min targeted playtest per spec §3.2." \
  -m "Truth ending Sever bargain visible on ending stats panel and (if applicable) character sheet." \
  -m "Nalen Vorr 4-stage reveal chain reads as discovery." \
  -m "Mimic-as-rehearsal foreshadows Saevus practice." \
  -m "Saevus Iziz / Nathema / anything stair lands as one escalation." \
  -m "Hyperspace dream — kept / cut: <fill in>."
git push origin builder-shader-scanner-audit
```

Phase 1 is complete when this commit is pushed and visible on the deploy branch.

---

## Phase 1 → Phase 2A transition checklist

Before opening Phase 2A (horror mechanics, §4 of the spec):

- [ ] All 11 tasks above committed to `builder-shader-scanner-audit`.
- [ ] Acceptance wrap-up commit pushed.
- [ ] No outstanding revert work — if Task 8 was cut, it is reverted and the wrap-up commit notes the cut.
- [ ] The spec's "if any beat feels flat, revise that item before opening Phase 2A" gate has been honoured — no carry-over.
