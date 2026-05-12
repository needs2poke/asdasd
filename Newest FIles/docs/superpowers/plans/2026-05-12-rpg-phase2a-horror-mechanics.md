# RPG Phase 2A — Horror Mechanics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Phase 2A (§4 of the v5.0 spec) — Horror Mechanics: items #8 (Karath + Holocron fourth-wall split), #9 (cipher reframe as containment seal layer), #10 (Mimic blackouts with kill-traced inventory tampering and false journal entry), #11 (Force Voids with -25% FP regen), #12 (Shadow Self STAT mirror).

**Architecture:** Three layers.
- **Pure-data layer** (small, text-only): cipher reframes (#9 across `saevus_manifest.lua` + `ending.lua`; the ending edit is an in-place line replacement, not a prepend — see Task 3), Bloodied Cloth item (#10 part).
- **Combat layer**: Shadow Self STAT mirror (#12) at `combat.lua:1146`; Force Void FP-gain dampener (#11) at the single existing FP-gain site (`combat.lua:2024`) gated by a shared public helper `RPG.IsForceVoidActive(game)` that lives in `state.lua` so both `combat.lua` and `menu_dialogue.lua` can call it.
- **Horror / state layer**: new `mimic_blackout.lua` module hooked into `quest.lua` `SetStage` for Q16; new `horror.lua` functions `KarathBreakdownScene` and `HolocronVoiceScene` replacing the existing `FourthWallBreak` literal-`rpgPlayer_t` body via a Holocron-possession dispatcher; new game-level state fields (`game.killLog`, `game.fakeJournalEntries`) initialised in `state.lua` `NewGame`, persisted by adding two lines each to `save.lua` `BuildSnapshot` + `RestoreFromSnapshot`; one kill-recorder call added to `combat.lua` `EndCombat`; one renderer extension at `menus/menu_inventory.lua:128-136` so Item 42's function-valued examineText renders.

**Save compatibility:** No `SAVE_VERSION` bump (stays at 2). New fields default-empty (`{}`) and are restored with `or {}` fallbacks, so Phase-0/Phase-1 saves load cleanly under Phase-2A code.

**Tech Stack:** GLua (Lua 5.1 inside OpenJK `jampgame` DLL), `Menu` (centerprint), `Timer`, `File`. No automated test framework — verification is manual on the VPS per the project's edit/commit/push → deploy → in-game workflow.

**Source spec:** `docs/superpowers/specs/2026-05-12-rpg-echoes-enhancements-v4-design.md` §4 (v5.0, items #8–#12).

**Deploy workflow reminder** (from project memory):
- Windows is edit/commit/push only. Compilation / Lua rsync happens on the Linux VPS.
- `restart_custom_server.sh -n` skips Lua rsync. **For Lua-only changes use the full deploy (no `-n`)**, or manually rsync to `~/NewSharding/openjk_home/base/glua/` before running `-n`.
- Deploy pulls `builder-shader-scanner-audit`. Push to that branch and verify the file on disk shows the change before testing.

**Playtest gate:** Phase 2A's per-item gate (§4.2 of the spec) is **deferred** — user is combining playtest with Phase 2B at the end of that plan. Final task here is a "ready for Phase 2B" gate, not an acceptance commit.

---

## File Structure

**Files modified:**
- `base/glua/rpg/combat.lua` — Shadow Self STAT mirror at the `mimicMirror` init block; Force Void multiplier on the Force Absorb FP-gain site; kill recorder in `EndCombat` victory path (Tasks 1, 4, 9).
- `base/glua/rpg/config.lua` — `FORCE_VOID_PARANOIA_MIN`, `FORCE_VOID_FP_GAIN_MULT` (Task 4).
- `base/glua/rpg/data/dialogues/saevus_manifest.lua` — cipher reframe line near Saevus's "prison/seal" beat (Task 2).
- `base/glua/rpg/ending.lua` — replace existing 3-line "cipher seals the prison permanently" block in Truth narration with reframe text (Task 3).
- `base/glua/rpg/state.lua` — public helper `RPG.IsForceVoidActive(game)`; `NewGame` game table gets `killLog = {}` and `fakeJournalEntries = {}` (Tasks 4, 9).
- `base/glua/rpg/menus/menu_dialogue.lua` — `[VOID]` flavor tag on dialogue header when Force Void is active (Task 5).
- `base/glua/rpg/horror.lua` — two new functions (`KarathBreakdownScene`, `HolocronVoiceScene`) + cleanup hooks; modify `FourthWallBreak` body to dispatch by load criterion (Tasks 6, 7, 8).
- `base/glua/rpg/data/items.lua` — new Item 42 "Bloodied Cloth (Not Yours)" with dynamic examineText (Task 9).
- `base/glua/rpg/menus/menu_inventory.lua` — extend the examine renderer at lines 128-136 to call `examineText` when it is a function (Task 9).
- `base/glua/rpg/save.lua` — `BuildSnapshot` adds two game-level fields; `RestoreFromSnapshot` overlays them with `or {}` fallbacks (Task 9).
- `base/glua/rpg/quest.lua` — `SetStage` calls `RPG.MimicBlackout.OnStageAdvance` for `the_mimic` (Task 10).
- `base/glua/rpg/menus/menu_quest_log.lua` — render `game.fakeJournalEntries` alongside real quests (Task 12).
- `base/glua/rpg/init.lua` — `require("rpg.mimic_blackout")` in the module load chain (Task 9).

**Files created:**
- `base/glua/rpg/mimic_blackout.lua` — new module: severity table + `RPG.MimicBlackout.OnStageAdvance` dispatcher + Stage-4 handler (Tasks 9, 10, 11, 12).

---

## Task 1: Shadow Self STAT mirror (Spec #12)

**Files:**
- Modify: `base/glua/rpg/combat.lua:1146-1150` (the `mimicMirror` init block inside `StartCombat`)

**Rationale:** The behavior mirror at `combat.lua:1304` already copies the player's last action ~80% of the time. Phase 2A adds a **stat** mirror so the Shadow Self fights you not just stylistically but quantitatively — your STR / DEX / INT / WIS get copied into the enemy's stat block on combat start. The fight reads as "you're fighting yourself." Triggered only on enemies flagged `shadowSelf = true` (currently only enemy 17 in `data/enemies.lua:793-803`); the `mimicMirror` flag is set on the same enemy entry, so we piggyback the init.

- [ ] **Step 1: Locate the mimicMirror init block**

Read `base/glua/rpg/combat.lua` lines 1140-1160 to confirm the current block:

```lua
    -- Initialize mimic mirror (Shadow Self)
    if enemy.mimicMirror then
        game.combat.mimicMirror = true
        game.combat.lastPlayerAction = nil
    end
```

- [ ] **Step 2: Extend the block with the STAT mirror**

Replace the block with:

```lua
    -- Initialize mimic mirror (Shadow Self): behavior mirror + STAT mirror.
    -- Behavior mirror at combat.lua:1304 already copies the player's last action.
    -- STAT mirror copies STR/DEX/INT/WIS at combat start so the fight is also
    -- quantitatively "you fighting yourself."
    if enemy.mimicMirror then
        game.combat.mimicMirror = true
        game.combat.lastPlayerAction = nil
        if enemy.shadowSelf then
            local p = game.player
            enemy.stats = enemy.stats or {}
            enemy.stats.STR = p.stats.STR
            enemy.stats.DEX = p.stats.DEX
            enemy.stats.INT = p.stats.INT
            enemy.stats.WIS = p.stats.WIS
        end
    end
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "STAT mirror copies STR/DEX/INT/WIS" base/glua/rpg/combat.lua
```
Expected: one match at the new comment.

Confirm `data/enemies.lua` Shadow Self entry has both `mimicMirror = true` and `shadowSelf = true` (it has `shadowSelf = true` at line 803; `mimicMirror` presence is what gates `combat.mimicMirror` so verify the enemy table has the field — grep `mimicMirror` in `data/enemies.lua`).

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/combat.lua
git commit -m "feat(rpg): Shadow Self STAT mirror (Phase 2A #12)"
```

---

## Task 2: Cipher reframe — Saevus Manifestation (Spec #9 part 1)

**Files:**
- Modify: `base/glua/rpg/data/dialogues/saevus_manifest.lua` (find the node where Saevus discusses the cipher / prison / seal; insert the reframe lines there)

**Rationale:** The cipher is currently presented as if solving it is what defeats Saevus. The reframe lands a different beat: the cipher is **one** containment seal layer; Saevus is defeated narratively, the cipher unlocks the Truth-ending vantage. Resolves the "if I solve a code, why is Saevus defeated?" awkwardness without rewriting plot machinery.

- [ ] **Step 1: Find the cipher / seal beat in saevus_manifest.lua**

Run:
```bash
grep -n -E "cipher|seal|prison|code|nine|9 digits" base/glua/rpg/data/dialogues/saevus_manifest.lua
```

Identify a node where Saevus is in a tone of explanation/threat about the prison or cipher. Likely candidates (verify by reading the surrounding 20 lines): node 11 ("You're the prisoner in the Holocron."), node 12 ("What do you want?"), node 13 ("I'm here to end this."), or node 20 (Iziz registry / Nathema stair already established in Phase 1).

If no existing cipher-aware node fits, target node 11 (response to "You're the prisoner in the Holocron") — that's the most natural place for Saevus to talk about the prison's structure.

- [ ] **Step 2: Add the reframe lines**

Find the target node's `text` table or string concatenation and append (or insert before a `lines[#lines + 1] = ""` separator if one is nearby) the following lines as separate `lines[#lines + 1] = ...` entries (or appended to the joined string with `\n`):

```
"'The cipher? One seal among many. A spell layer."
"'Solve it and you peel back a single shroud."
"'The prison holds. I remain. But you will see"
"'what was hidden from you. That is the only gift"
"'I cannot prevent.'"
```

If the existing text is a string concatenation (`"..." .. "..."`), append with `\n` between lines. If it's a `lines` table with function-driven dynamic content, push via `lines[#lines + 1] = "..."`.

Match the surrounding Quake-style colour pattern: surrounding Saevus speech in this file uses unmarked white as default. Do NOT add `^7` prefixes unless the surrounding lines have them.

**Em-dash convention** (locked in Phase 1): use ASCII `--` not Unicode `—`. The OpenJK Q3-derived centerprint pipeline does not render Unicode reliably.

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "One seal among many" base/glua/rpg/data/dialogues/saevus_manifest.lua
```
Expected: exactly one match.

Read 5 lines of surrounding context to confirm placement reads naturally.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/data/dialogues/saevus_manifest.lua
git commit -m "feat(rpg): cipher reframe in Saevus Manifestation (Phase 2A #9a)"
```

---

## Task 3: Cipher reframe — Truth ending narration (Spec #9 part 2)

**Files:**
- Modify: `base/glua/rpg/ending.lua:94-96` (three lines inside `ENDINGS.truth.narration`)

**Rationale:** The existing Truth narration already contains three load-bearing lines at indices 94-96: `"^2The cipher seals the prison -- permanently."` / `"^2The containment protocols lock into place."` / `"^2What was forgotten stays forgotten."` These directly assert that solving the cipher is what permanently seals the prison — which is exactly the framing spec §4.1 #9 wants to replace. The reframe **replaces these three lines in place** (instead of prepending) so the narration is internally consistent. The "What was forgotten stays forgotten" line is preserved as a thematic anchor and only the first two lines are rewritten.

This was flagged in the plan review loop — an earlier draft prepended a preface, which would have contradicted the existing "permanently"/"into place" wording.

- [ ] **Step 1: Read the existing Truth narration to confirm anchor lines**

Read `base/glua/rpg/ending.lua:81-108` (the entire `truth = { ... }` block). Confirm the narration table includes at indices 94-96 (or equivalent positions if the file has shifted):

```lua
            "^2The cipher seals the prison -- permanently.",
            "^2The containment protocols lock into place.",
            "^2What was forgotten stays forgotten.",
```

- [ ] **Step 2: Replace lines 94-95; keep line 96**

Use Edit to change:

```lua
            "^2The cipher seals the prison -- permanently.",
            "^2The containment protocols lock into place.",
            "^2What was forgotten stays forgotten.",
```

to:

```lua
            "^2The cipher locks one seal of many.",
            "^2The deepest containment was always older.",
            "^2What was forgotten stays forgotten.",
```

Net change: two lines rewritten; the "forgotten stays forgotten" anchor preserved verbatim. The reframe asserts the cipher is one layer, that there is a deeper/older containment, and keeps the thematic closure unchanged.

Leave lines 86-93 (the "speak the name aloud" / chamber-silent block), lines 98-103 (walks out / free), and the Phase-1 Sever-bargain lines 105-107 untouched.

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "one seal of many\|deepest containment was always older" base/glua/rpg/ending.lua
```
Expected: two matches inside the Truth narration.

Run:
```bash
grep -n "seals the prison -- permanently\|containment protocols lock into place" base/glua/rpg/ending.lua
```
Expected: **zero matches** (old lines are gone).

Run:
```bash
grep -n "What was forgotten stays forgotten" base/glua/rpg/ending.lua
```
Expected: still one match (anchor preserved).

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/ending.lua
git commit -m "feat(rpg): cipher reframe in Truth ending narration (Phase 2A #9b)"
```

---

## Task 4: Force Void combat penalty — config + shared helper + FP-gain dampener (Spec #11 part 1)

**Files:**
- Modify: `base/glua/rpg/config.lua` (new constants)
- Modify: `base/glua/rpg/state.lua` (public helper `RPG.IsForceVoidActive`)
- Modify: `base/glua/rpg/combat.lua` (apply dampener at the FP-gain site)

**Rationale:** Per spec §4.1 #11, when the player is in an Act-2+ room with a `voidDescription` and paranoia ≥ 60, in combat FP regen is reduced by 25%. The "regen" in this codebase is the explicit FP-gain sites in `combat.lua` (Force Absorb on enemy special, line 2024 in current checkout) — there is no passive per-turn regen. Verified via grep `game.player.fp = math.min(game.player.maxFP` against `combat.lua` — Force Absorb at line 2024 is the only in-combat FP-gain site.

Helper is added to `state.lua` as a **public function** `RPG.IsForceVoidActive(game)` from the start, NOT a local in `combat.lua`. This lets Task 5 (dialogue tag) reuse the same function without refactoring Task 4's commit — preserving rollback semantics: reverting Task 4 leaves a dead public function but doesn't break Task 5.

`-25%` is the **committed default**. If playtest reads punitive, drop the multiplier to 0.85 (i.e., -15%) — config-only change.

- [ ] **Step 1: Add config constants**

Open `base/glua/rpg/config.lua`. Locate `RPG.Config.PARANOIA_FLOOR_TRUTH = 30` (added in Phase 1 #1). After it, insert:

```lua
RPG.Config.FORCE_VOID_PARANOIA_MIN = 60      -- Phase 2A #11: paranoia threshold for Force Void to be "active" in a void-room
RPG.Config.FORCE_VOID_FP_GAIN_MULT = 0.75    -- Phase 2A #11: multiplier on in-combat FP gain when Void is active (-25% default)
```

- [ ] **Step 2: Add the shared helper in state.lua**

Open `base/glua/rpg/state.lua`. Locate `function RPG.IsPlaying(player)` at line 16. Just AFTER its closing `end` (line 18), insert:

```lua
--- Phase 2A #11: returns true if Force Void is currently dampening this game.
--- Active when paranoia ≥ FORCE_VOID_PARANOIA_MIN AND current room has a voidDescription
--- AND the room's act >= 2. Soft-lock-safe: read-only — never blocks an action, only dampens FP gain
--- in combat and adds a flavor tag in dialogue.
function RPG.IsForceVoidActive(game)
    if not game or not game.player then return false end
    if (game.player.paranoia or 0) < (RPG.Config.FORCE_VOID_PARANOIA_MIN or 60) then return false end
    local room = game.rooms and game.rooms[game.player.currentRoom]
    if not room then return false end
    if (room.act or 1) < 2 then return false end
    return room.voidDescription ~= nil
end
```

- [ ] **Step 3: Apply the dampener to the existing FP-gain site**

Locate `combat.lua:2021-2026` (Force Absorb special-handling). Current code:

```lua
    -- Force Absorb: if enemy used special while absorb was active, heal 20 HP + recover 10 FP
    if combat.absorbActive and eAction == "special" then
        game.player.hp = math.min(game.player.maxHP, game.player.hp + 20)
        game.player.fp = math.min(game.player.maxFP, game.player.fp + 10)
        AddResultLog(game, "^5Force Absorb^7 converts the enemy's power: +20 HP, +10 FP.")
    end
```

Replace with:

```lua
    -- Force Absorb: if enemy used special while absorb was active, heal 20 HP + recover FP.
    -- Phase 2A #11: in a Force Void, the FP recovery is dampened (default -25%).
    if combat.absorbActive and eAction == "special" then
        game.player.hp = math.min(game.player.maxHP, game.player.hp + 20)
        local fpGain = 10
        local voidActive = RPG.IsForceVoidActive(game)
        if voidActive then
            fpGain = math.floor(fpGain * (RPG.Config.FORCE_VOID_FP_GAIN_MULT or 0.75) + 0.5)
        end
        game.player.fp = math.min(game.player.maxFP, game.player.fp + fpGain)
        if voidActive then
            AddResultLog(game, "^5Force Absorb^7 converts the enemy's power: +20 HP, +" .. fpGain .. " FP ^8[Void dampens recovery]^7.")
        else
            AddResultLog(game, "^5Force Absorb^7 converts the enemy's power: +20 HP, +" .. fpGain .. " FP.")
        end
    end
```

- [ ] **Step 4: Sweep for other in-combat FP-gain sites that should respect the Void**

Run:
```bash
grep -n "game.player.fp = math.min(game.player.maxFP" base/glua/rpg/combat.lua
```

Expected (current checkout): one match — the Force Absorb site we just modified. If additional sites have landed since this plan was written, apply the same `RPG.IsForceVoidActive(game)` dampener pattern to each.

Out-of-scope for this task: out-of-combat FP gains (Force Meditate, item use, level-up). Spec §4.1 #11 scopes the penalty to "in combat" — only.

- [ ] **Step 5: Verify**

Run:
```bash
grep -n "Void dampens recovery" base/glua/rpg/combat.lua
```
Expected: one match.

Run:
```bash
grep -n "FORCE_VOID_FP_GAIN_MULT" base/glua/rpg
```
Expected: one match in `config.lua`, at least one in `combat.lua`.

Run:
```bash
grep -n "function RPG.IsForceVoidActive" base/glua/rpg/state.lua
```
Expected: one match.

- [ ] **Step 6: Commit**

```bash
git add base/glua/rpg/config.lua base/glua/rpg/state.lua base/glua/rpg/combat.lua
git commit -m "feat(rpg): Force Void in-combat FP-gain dampener + shared helper (Phase 2A #11a)"
```

---

## Task 5: Force Void dialogue flavor tag (Spec #11 part 2)

**Files:**
- Modify: `base/glua/rpg/menus/menu_dialogue.lua` (header / title render — add the `[VOID]` tag when active)

**Rationale:** In dialogue the Void is **purely flavor**: a tag above the menu when Void is active. The dialogue render lives in `base/glua/rpg/menus/menu_dialogue.lua` (confirmed via `init.lua:66` and `init.lua:144`); `base/glua/rpg/dialogue.lua` contains the data-driven helpers (`RollCheck`, `GetVisibleResponses`, `GetResponseLabel`). The header lines that need the tag are inside the menu file's `header` / `onOpen` / `Menu.Register` callback for `"dialogue"`.

**Optional-vs-required stat-check distinction not implemented in this plan.** The spec §4.1 #11 also prescribes a -2 WIS/INT penalty on *optional* dialogue checks (and explicitly forbids penalizing *required* ones for soft-lock safety). Verified by grep: `dialogue.lua` and `data/dialogues/*.lua` have no `optional` / `required` / `isRequired` field on response checks. `RPG.Dialogue.RollCheck(game, check)` takes only `{stat, dc}` — no distinction marker. Applying a blanket penalty would risk soft-locking quest-critical gates (spec explicitly forbids); applying nothing implements the safer half (no false negatives). The plan ships the flavor tag only; the optional-vs-required hook is **out of scope for Phase 2A** and re-opens only if Phase 3 adds the distinction. Plan reviewer Important issue #6 explicitly resolved here.

The helper `RPG.IsForceVoidActive(game)` already exists publicly after Task 4 — no setup needed in this task.

- [ ] **Step 1: Find the dialogue menu header / onOpen callback**

Run:
```bash
grep -n -E "Menu\.Register\(\"dialogue\"|header\s*=|onOpen\s*=" base/glua/rpg/menus/menu_dialogue.lua
```

Identify the `header` field (or string-builder) that produces the dialogue title / speaker / body text above the response list. Note its variable name — likely `lines` or a string accumulator.

- [ ] **Step 2: Prepend the [VOID] tag when active**

In the header builder, BEFORE the existing first line (whatever speaker name / body opens the dialogue), insert:

```lua
if RPG.IsForceVoidActive and RPG.IsForceVoidActive(game) then
    -- Phase 2A #11: Force Void flavor tag — never gates dialogue, just sets mood.
    table.insert(lines, 1, "")
    table.insert(lines, 1, "^8[VOID] Your thoughts feel distant.^7")
end
```

If the header is a string accumulator instead of a `lines` array, prepend with `"^8[VOID] Your thoughts feel distant.^7\n\n" .. header`. Adapt the local name (`lines`, `headerText`, `body`, etc.) to whatever the file uses.

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "Your thoughts feel distant" base/glua/rpg/menus/menu_dialogue.lua
```
Expected: one match in the dialogue header path.

Run:
```bash
grep -n "RPG.IsForceVoidActive" base/glua/rpg
```
Expected: three locations — `state.lua` (definition), `combat.lua` (Task 4 caller), `menus/menu_dialogue.lua` (this task).

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/menus/menu_dialogue.lua
git commit -m "feat(rpg): Force Void dialogue flavor tag (Phase 2A #11b)"
```

---

## Task 6: Karath breakdown scene (Spec #8 part 1)

**Files:**
- Modify: `base/glua/rpg/horror.lua` (add `RPG.Horror.KarathBreakdownScene(player, game)` function and corresponding cleanup hook)

**Rationale:** One half of the fourth-wall split. The existing `FourthWallBreak` literal-`rpgPlayer_t` scene is breaking the fiction. Karath's breakdown is **her** personal dissolution beat — a recovered ghost-recording flavor that addresses Karath's loss of self, not the player's. Karath is **female** (confirmed at `karath_vren.lua:34, 476`). Three lines, modelled on the existing `FourthWallBreak` scripted-sequence pattern.

- [ ] **Step 1: Read the existing FourthWallBreak structure**

Read `base/glua/rpg/horror.lua:454-519` to confirm the function structure: `glitchBurst` state setup, `Timer.Simple` chain for delayed frames, scripted `sequence` table, end timer, and the eventual `EndGlitchBurst`. The new function will mirror this structure.

- [ ] **Step 2: Add the KarathBreakdownScene function**

After the existing `FourthWallBreak` function (around line 519), insert:

```lua
-- ============================================
-- KARATH BREAKDOWN SCENE (Phase 2A #8 part 1)
-- ============================================

--- Plays a recovered Karath Vren breakdown recording — her personal
--- dissolution beat. Replaces half of the old rpgPlayer_t fourth-wall scene
--- via the FourthWallBreak dispatcher. Uses glitch_burst state like the
--- existing FourthWallBreak so the menu/Render pipeline behaves identically.
function RPG.Horror.KarathBreakdownScene(player, game)
    if not game then return end

    local clientNum = player:GetClientNum()

    game.glitchBurst = {
        previousState = game.state,
        frame = 0,
        totalFrames = 5,   -- matches sequence length below
        startTime = Timer.RealTime and Timer.RealTime() or 0,
        isFakeReboot = false,
        isFourthWall = true,    -- reuse the same render path
        isKarathBreakdown = true,
        glitchText = "",
        onComplete = function()
            game.flags["fourth_wall_broken"] = true
            RPG.AddParanoia(player, RPG.Config.FOURTH_WALL_PARANOIA_GAIN)
        end,
    }

    RPG.SetState(player, "glitch_burst")

    -- Karath in first-person, fragmented. Her dissolution, not the player's.
    local sequence = {
        { delay = 0,    text = "" },
        { delay = 1200, text = "^1[recovered fragment / KARATH VREN]" },
        { delay = 2600, text = "^1'I cannot remember the order of my own thoughts.\n^1The Holocron files them differently each time I wake.'" },
        { delay = 4100, text = "^1'I write my name on my arm so I will know it\n^1when I look down. Sometimes the writing is gone.\n^1Sometimes the arm is gone.'" },
        { delay = 5600, text = "^2[fragment ends]" },
    }

    for i, frame in ipairs(sequence) do
        Timer.Simple("rpg_horror_karath_" .. clientNum .. "_" .. i, frame.delay, function()
            local p = Player.Get(clientNum)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g or not g.glitchBurst or not g.glitchBurst.isKarathBreakdown then return end

            g.glitchBurst.glitchText = frame.text
            g.glitchBurst.frame = i

            if Menu and Menu.InvalidateCache then Menu.InvalidateCache(p) end
            if Menu and Menu.Render then Menu.Render(p) end
        end)
    end

    -- End sequence (1000ms after final frame)
    Timer.Simple("rpg_horror_karath_" .. clientNum .. "_end", 6600, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local g = RPG.GetGame(p)
        if not g or not g.glitchBurst then return end
        RPG.Horror.EndGlitchBurst(p, g)
    end)
end
```

- [ ] **Step 3: Add cleanup hooks for the new timers**

Find `RPG.Horror.Cleanup` at `horror.lua:664+`. After the existing fourth-wall cleanup loop (`for i = 1, 5 do Timer.Remove("rpg_horror_4wall_..." end`), insert:

```lua
    -- Karath breakdown timers (Phase 2A #8 part 1)
    for i = 1, 5 do
        Timer.Remove("rpg_horror_karath_" .. clientNum .. "_" .. i)
    end
    Timer.Remove("rpg_horror_karath_" .. clientNum .. "_end")
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -n "KarathBreakdownScene\|rpg_horror_karath" base/glua/rpg/horror.lua
```
Expected: function definition + 2-3 references (timer names in body + cleanup).

- [ ] **Step 5: Commit**

```bash
git add base/glua/rpg/horror.lua
git commit -m "feat(rpg): Karath breakdown scene function (Phase 2A #8 part 1)"
```

---

## Task 7: Holocron-in-player's-voice scene (Spec #8 part 2)

**Files:**
- Modify: `base/glua/rpg/horror.lua` (add `RPG.Horror.HolocronVoiceScene(player, game)` function + cleanup)

**Rationale:** Other half of the fourth-wall split. The Holocron speaks in the **player's own voice** — addressing them directly in-fiction: "I have been whispering the coordinates since Act 1. Every 'choice' you made was a path I cleared." Stays inside the diegesis; the Watcher dialogue at paranoia ≥ 80 already carries the player-agency meta theme.

- [ ] **Step 1: Add the HolocronVoiceScene function**

After `KarathBreakdownScene` in `horror.lua`, insert:

```lua
-- ============================================
-- HOLOCRON-IN-PLAYER'S-VOICE SCENE (Phase 2A #8 part 2)
-- ============================================

--- Plays the Holocron addressing the player in the player's own voice.
--- Stays fully in-fiction; the speaker tag is the player's name. The line
--- reveals long-running manipulation: every "choice" was a path it cleared.
function RPG.Horror.HolocronVoiceScene(player, game)
    if not game then return end

    local clientNum = player:GetClientNum()
    local playerName = player:GetName() or "you"

    game.glitchBurst = {
        previousState = game.state,
        frame = 0,
        totalFrames = 7,   -- matches sequence length below
        startTime = Timer.RealTime and Timer.RealTime() or 0,
        isFakeReboot = false,
        isFourthWall = true,    -- reuse render path
        isHolocronVoice = true,
        glitchText = "",
        onComplete = function()
            game.flags["fourth_wall_broken"] = true
            RPG.AddParanoia(player, RPG.Config.FOURTH_WALL_PARANOIA_GAIN)
        end,
    }

    RPG.SetState(player, "glitch_burst")

    local sequence = {
        { delay = 0,    text = "" },
        { delay = 1200, text = "^1[a voice that is your voice]" },
        { delay = 2600, text = "^1'" .. playerName .. ". Listen.'" },
        { delay = 4000, text = "^1'I have been whispering the coordinates since Act 1.'" },
        { delay = 5600, text = "^1'Every choice you made was a path I cleared." },
        { delay = 7100, text = "^1You were never finding the truth.\n^1You were arriving where I sent you.'" },
        { delay = 8800, text = "^2[the voice fades]" },
    }

    for i, frame in ipairs(sequence) do
        Timer.Simple("rpg_horror_holovoice_" .. clientNum .. "_" .. i, frame.delay, function()
            local p = Player.Get(clientNum)
            if not p or not p:IsValid() then return end
            local g = RPG.GetGame(p)
            if not g or not g.glitchBurst or not g.glitchBurst.isHolocronVoice then return end

            g.glitchBurst.glitchText = frame.text
            g.glitchBurst.frame = i

            if Menu and Menu.InvalidateCache then Menu.InvalidateCache(p) end
            if Menu and Menu.Render then Menu.Render(p) end
        end)
    end

    Timer.Simple("rpg_horror_holovoice_" .. clientNum .. "_end", 9800, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then return end
        local g = RPG.GetGame(p)
        if not g or not g.glitchBurst then return end
        RPG.Horror.EndGlitchBurst(p, g)
    end)
end
```

- [ ] **Step 2: Add cleanup hooks**

In `RPG.Horror.Cleanup` (after the Karath cleanup added in Task 6):

```lua
    -- Holocron-voice timers (Phase 2A #8 part 2)
    for i = 1, 7 do
        Timer.Remove("rpg_horror_holovoice_" .. clientNum .. "_" .. i)
    end
    Timer.Remove("rpg_horror_holovoice_" .. clientNum .. "_end")
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "HolocronVoiceScene\|rpg_horror_holovoice" base/glua/rpg/horror.lua
```
Expected: function definition + timer references in body + cleanup.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/horror.lua
git commit -m "feat(rpg): Holocron-in-player's-voice scene function (Phase 2A #8 part 2)"
```

---

## Task 8: Wire the fourth-wall split via FourthWallBreak dispatcher (Spec #8 part 3)

**Files:**
- Modify: `base/glua/rpg/horror.lua:460-519` — replace the existing `FourthWallBreak` body with a dispatcher

**Rationale:** The existing `FourthWallBreak` runs the literal `rpgPlayer_t` / "data structure" / "table of numbers" sequence. Spec §4.1 #8 replaces it with the two new scenes, **split by load**. The plan pins the split criterion to **whether the player still has the Holocron** (`game.player.hasHolocron`):

- **In-fiction justification:** the Holocron-in-player's-voice scene IS the Holocron speaking in real time. If the player has already delivered the Holocron to Adare / Zherron / the Exchange, the Holocron literally cannot speak — the prop is gone. In that case, the recovered Karath Vren fragment (a ghost-recording, not a live entity) plays instead. Both halves carry the meta weight; the criterion is a diegetic gate, not arbitrary.
- **Spec text:** §4.1 #8 says "split by load" without naming the load. `hasHolocron` is consistent with how §5 #15B uses the same flag deterministically.
- **Both halves gate at paranoia ≥ 90** (same as the old break — `config.lua:257` `FOURTH_WALL_PARANOIA = 90`). No new gate, just a new branch inside the existing gate.

- [ ] **Step 1: Read the current FourthWallBreak**

Confirm the function body at `horror.lua:460-519` matches what was captured during recon: 5-frame `sequence` table, `Timer.Simple` chain, end sequence at 6500ms.

- [ ] **Step 2: Replace the FourthWallBreak body**

Replace the entire function body (everything between `function RPG.Horror.FourthWallBreak(player, game)` and the closing `end` at line 519) with:

```lua
function RPG.Horror.FourthWallBreak(player, game)
    if not game then return end

    -- Phase 2A #8: split the old literal rpgPlayer_t break into two in-fiction halves.
    -- If the player still holds the Holocron, the Holocron speaks in their own voice.
    -- If the Holocron is gone, a recovered Karath Vren fragment plays in its place.
    -- Both reach the same paranoia gate; both set the fourth_wall_broken flag.
    if game.player and game.player.hasHolocron then
        return RPG.Horror.HolocronVoiceScene(player, game)
    else
        return RPG.Horror.KarathBreakdownScene(player, game)
    end
end
```

This deletes the old 5-frame literal-`rpgPlayer_t` sequence in favor of dispatching to the two new functions from Tasks 6 and 7.

- [ ] **Step 3: Sweep any callers**

Run:
```bash
grep -rn "FourthWallBreak" base/glua/rpg
```

The fourth-wall function is fired from `state.lua` or another transition handler at paranoia ≥ 90. Confirm callers still call `RPG.Horror.FourthWallBreak(player, game)` — no signature change needed.

Run:
```bash
grep -n "rpg_horror_4wall_" base/glua/rpg/horror.lua
```

The existing cleanup loop in `RPG.Horror.Cleanup` references timer name `rpg_horror_4wall_...`. After this task, that timer is never created (the new dispatcher routes to KarathBreakdownScene or HolocronVoiceScene, which use different timer names). The existing cleanup loop is harmless — leave it. (It's defensive — covers any in-flight pre-deploy timers; no removal cost.)

- [ ] **Step 4: Verify**

Run:
```bash
grep -n "rpgPlayer_t" base/glua/rpg/horror.lua
```
Expected: zero matches. The literal scene is gone.

Run:
```bash
grep -n "hasHolocron" base/glua/rpg/horror.lua
```
Expected: at least the new dispatcher line.

- [ ] **Step 5: Commit**

```bash
git add base/glua/rpg/horror.lua
git commit -m "feat(rpg): wire fourth-wall split into FourthWallBreak (Phase 2A #8 part 3)"
```

---

## Task 9: Mimic blackout infrastructure — kill log, Bloodied Cloth, fakeJournalEntries, module shell (Spec #10 setup)

**Files:**
- Modify: `base/glua/rpg/state.lua` (NewGame game table — add `killLog = {}` and `fakeJournalEntries = {}`)
- Modify: `base/glua/rpg/save.lua` (BuildSnapshot + RestoreFromSnapshot — persist the two new fields)
- Modify: `base/glua/rpg/combat.lua` (EndCombat victory path — append to game.killLog)
- Modify: `base/glua/rpg/data/items.lua` (add Item 42 "Bloodied Cloth (Not Yours)" with dynamic examineText)
- Modify: `base/glua/rpg/init.lua` (load `rpg.mimic_blackout` in the module chain)
- Create: `base/glua/rpg/mimic_blackout.lua` (module shell with severity table + `OnStageAdvance` dispatcher signature)

**Rationale:** Infrastructure-only task. No player-visible behaviour ships yet — Tasks 10/11/12 wire the actual scenes into this groundwork. Splitting this out keeps each follow-up task small and reviewable.

The kill log is a flat array of `{enemyId, enemyName, roomId, killedAt}` records appended on combat victory. The Bloodied Cloth's `examineText` is a function so it can read `game.killLog` at examine time and render a specific previous kill ("The blood matches the kinrath matriarch you killed in the caves.").

`fakeJournalEntries` is a flat array of `{title, journal}` records used by the menu_quest_log render in Task 12.

`SAVE_VERSION` stays at 2 — both fields default-empty in NewGame and restore with `or {}` fallbacks, so pre-Phase-2A saves load cleanly.

- [ ] **Step 1: state.lua — add game-level fields to NewGame**

In `base/glua/rpg/state.lua`, locate the `NewGame` game table (around lines 41-86). Find the existing game-level fields: `quests = {}, combat = {...}, stalker = {...}, ...`. After `loreDiscovered = {},` (around line 82) and BEFORE `truthUnlocked = false,`, insert:

```lua
        killLog = {},                  -- Phase 2A #10: append-only log of player victories for kill-traced examine text
        fakeJournalEntries = {},       -- Phase 2A #10: planted false quest-log entries (Mimic blackout stage 4)
```

- [ ] **Step 2: save.lua — persist the new fields**

In `base/glua/rpg/save.lua`, locate `BuildSnapshot` around line 167. In the game-level section (after `loreDiscovered = ...` at line 202 and before `truthUnlocked = ...` at line 203), insert:

```lua
        killLog = RPG.Util.DeepCopy(game.killLog or {}),
        fakeJournalEntries = RPG.Util.DeepCopy(game.fakeJournalEntries or {}),
```

In `RestoreFromSnapshot`, locate the game-level overlay block (around lines 488-500). After `game.loreDiscovered = ...` and before `game.truthUnlocked = ...`, insert:

```lua
    game.killLog = RPG.Util.DeepCopy(snapshot.killLog or {})
    game.fakeJournalEntries = RPG.Util.DeepCopy(snapshot.fakeJournalEntries or {})
```

The `or {}` fallback ensures Phase-0/Phase-1 saves (which don't have these fields) load cleanly.

- [ ] **Step 3: combat.lua — record kill on victory**

In `base/glua/rpg/combat.lua`, locate `RPG.Combat.EndCombat` victory path (around lines 1669-1690). The `if outcome == "victory" then` block does XP, credits, BatchPrint. Just AFTER the `local credits = enemy.creditReward or 0` line (around line 1685) and BEFORE `game.player.xp = ...` (around line 1686), insert:

```lua
        -- Phase 2A #10 setup: append kill record for kill-traced examine text.
        game.killLog = game.killLog or {}
        game.killLog[#game.killLog + 1] = {
            enemyId = enemy.id,
            enemyName = enemy.name,
            roomId = game.player.currentRoom,
            killedAt = (Game and Game.GetTime and Game.GetTime()) or 0,
        }
```

- [ ] **Step 4: data/items.lua — add Item 42 Bloodied Cloth (with em-dash ASCII convention)**

In `base/glua/rpg/data/items.lua`, locate the closing bracket of the `[41]` Focusing Lens entry (line 400) and the table-close `}` (line 401). Just BEFORE the closing `}` of the master table (line 401), insert:

```lua
    [42] = {
        name = "Bloodied Cloth (Not Yours)",
        description = "A scrap of cloth. The blood is fresh. The blood is not yours.",
        type = "junk",
        value = 0,
        paranoia = 5,
        examineText = function(game)
            -- Phase 2A #10: dynamic — pick a real kill from the log and reference it.
            local log = game and game.killLog or {}
            local lines = {
                "[BLOODIED CLOTH -- NOT YOURS]",
                "",
                "A torn strip of robe.",
                "Blood, not yet dry.",
                "",
            }
            if #log > 0 then
                -- Pick the most recent kill — most likely to register as familiar.
                local k = log[#log]
                lines[#lines + 1] = "The blood pattern matches the " .. (k.enemyName or "thing you killed")
                lines[#lines + 1] = "you cut down. Whatever did this --"
                lines[#lines + 1] = "had your kill on its hands first."
            else
                -- Fallback if killLog is empty (unlikely in practice — Mimic Stage 4 is Act 2).
                lines[#lines + 1] = "The blood pattern is unfamiliar."
                lines[#lines + 1] = "But the cut is precise. Trained."
            end
            return table.concat(lines, "\n")
        end,
    },
```

**Em-dash convention** (locked in Phase 1): ASCII `--`, never Unicode `—`. The OpenJK Q3-derived centerprint pipeline does not render Unicode reliably.

- [ ] **Step 5: menu_inventory.lua — make the examine renderer function-tolerant**

This step is **required** for the Bloodied Cloth to render its dynamic text. Verified by reading `menu_inventory.lua:128-136`: the current examine view passes `itemDef.examineText` directly to `WrapText`, which assumes a string. Every existing item uses a string, so no current behaviour breaks; we extend the renderer to call the function when `examineText` is callable.

Open `base/glua/rpg/menus/menu_inventory.lua`. Locate the examine block at lines 128-136:

```lua
    if itemDef.examineText then
        items[#items + 1] = { label = "", action = "none" }
        local exLines = WrapText(itemDef.examineText)
        for _, line in ipairs(exLines) do
            items[#items + 1] = { label = "^7" .. line, action = "none" }
        end
    end
```

Replace with:

```lua
    if itemDef.examineText then
        items[#items + 1] = { label = "", action = "none" }
        -- Phase 2A #10: examineText may be a string OR a function(game) -> string.
        -- Bloodied Cloth (Item 42) uses the function form so it can reference game.killLog.
        local text = itemDef.examineText
        if type(text) == "function" then
            local ok, result = pcall(text, game)
            text = (ok and result) or "[examine text unavailable]"
        end
        local exLines = WrapText(text)
        for _, line in ipairs(exLines) do
            items[#items + 1] = { label = "^7" .. line, action = "none" }
        end
    end
```

The `pcall` is defensive — a runtime error in the dynamic-text function will not crash the menu render. No other callers of `itemDef.examineText` need to change: `menu_shop.lua:302-304` reads examineText in the shop info path; Item 42 is `type = "junk"` and never appears in shops (verified by reading menu_shop.lua filter logic at lines 355+). If a later phase exposes junk items to shops, the same fix lands at that call site.

- [ ] **Step 6: Create mimic_blackout.lua module shell**

Create `base/glua/rpg/mimic_blackout.lua`:

```lua
-- Echoes of the Dark Wars - Mimic Blackout System
-- Phase 2A #10: per-stage blackouts on Q16 the_mimic. Stage 1 mild,
-- Stages 2-3 escalating, Stage 4 (confront_truth) severe with three
-- Corrupted-memory hooks: wake-up jump, inventory tampering with kill-trace,
-- false journal entry.

RPG = RPG or {}
RPG.MimicBlackout = {}

-- Stage → severity tier. Each tier defines: nLines, hooks (inventoryTamper, fakeJournal).
-- Severity scales with paranoia at fire time (handled inside OnStageAdvance).
local STAGE_SEVERITY = {
    investigate_alley    = { tier = 1 },
    investigate_trace    = { tier = 2 },
    investigate_footage  = { tier = 3 },
    confront_truth       = { tier = 4 },
}

--- Called from RPG.Quest.SetStage when the_mimic stage advances.
--- No-op if stage is not in STAGE_SEVERITY.
function RPG.MimicBlackout.OnStageAdvance(player, stage)
    -- Stub. Real handler wired in Tasks 10 (tiers 1-3) and 11/12 (tier 4).
    if not STAGE_SEVERITY[stage] then return end
end

GLua.Print("RPG: Mimic Blackout system loaded")
return RPG.MimicBlackout
```

- [ ] **Step 7: init.lua — load the new module**

Run:
```bash
grep -n -E "require\(\"rpg\.(cipher|nemesis|stalker|horror)\"\)" base/glua/rpg/init.lua
```

Find the module require chain. After the line that loads `horror` (or near other narrative modules — cipher / stalker / ending), insert:

```lua
RPG.MimicBlackout = require("rpg.mimic_blackout") or RPG.MimicBlackout
```

(Follow whatever pattern the surrounding requires use — some projects use bare `require("rpg.foo")`, others assign the return.)

- [ ] **Step 8: Verify**

Run:
```bash
grep -n "killLog\|fakeJournalEntries" base/glua/rpg/state.lua base/glua/rpg/save.lua
```
Expected: `killLog` and `fakeJournalEntries` in NewGame, BuildSnapshot, RestoreFromSnapshot — three locations each across two files.

```bash
grep -n "Bloodied Cloth" base/glua/rpg/data/items.lua
```
Expected: one match in Item 42.

```bash
grep -n "examineText may be a string OR a function" base/glua/rpg/menus/menu_inventory.lua
```
Expected: one match (renderer extended).

```bash
ls -la base/glua/rpg/mimic_blackout.lua
```
Expected: file exists.

```bash
grep -n "mimic_blackout" base/glua/rpg/init.lua
```
Expected: one match in the require chain.

- [ ] **Step 9: Commit**

```bash
git add base/glua/rpg/state.lua base/glua/rpg/save.lua base/glua/rpg/combat.lua \
        base/glua/rpg/data/items.lua base/glua/rpg/menus/menu_inventory.lua \
        base/glua/rpg/mimic_blackout.lua base/glua/rpg/init.lua
git commit -m "feat(rpg): Mimic blackout infrastructure (Phase 2A #10 setup)"
```

---

## Task 10: Mimic blackout stages 1-3 (Spec #10 escalation)

**Files:**
- Modify: `base/glua/rpg/mimic_blackout.lua` (fill out tiers 1-3 in `OnStageAdvance`)
- Modify: `base/glua/rpg/quest.lua` (hook `SetStage` to call `RPG.MimicBlackout.OnStageAdvance` for the_mimic)

**Rationale:** Tiers 1-3 are pure narrative beats — escalating blackout text with no mechanical effect beyond paranoia gain. Tier 4 (Task 11/12) carries the harder Corrupted-memory hooks. Splitting the easy text-only tiers into their own task lets the structural hook (quest.lua wiring) land here cleanly.

- [ ] **Step 1: quest.lua — hook SetStage**

In `base/glua/rpg/quest.lua`, locate `RPG.Quest.SetStage` (line 65). Find the existing stage-advance success path — after `RPG.Quest.ApplyStageEffects(player, questId, stage)` (around line 110) and BEFORE `return true`:

```lua
        -- Phase 2A #10: dispatch Mimic blackout if this stage is one of the_mimic's tracked stages.
        if questId == "the_mimic" and RPG.MimicBlackout and RPG.MimicBlackout.OnStageAdvance then
            RPG.MimicBlackout.OnStageAdvance(player, stage)
        end
```

Place this just before the closing `return true` at line ~113.

- [ ] **Step 2: mimic_blackout.lua — fill in tiers 1-3**

In `base/glua/rpg/mimic_blackout.lua`, replace the stub `OnStageAdvance` body with the tier-1/2/3 handlers. Tier 4 stays a no-op for now (filled in Tasks 11/12).

```lua
local TIER_TEXTS = {
    -- Tier 1: investigate_alley — 1-line blackout. Mild lost-time hint.
    [1] = {
        "^1[a moment slips — you stand where you were not standing a heartbeat ago]",
    },
    -- Tier 2: investigate_trace — 2-line. The hand-on-the-knife sensation.
    [2] = {
        "^1[your hands are wet]",
        "^1[you do not remember when]",
    },
    -- Tier 3: investigate_footage — 3-line. Pre-stage 4 dread.
    [3] = {
        "^1[the corridor is wrong]",
        "^1[you walked it five minutes ago, but the lights were off]",
        "^1[the lights are on now and you cannot remember turning them on]",
    },
}

local TIER_PARANOIA = { [1] = 3, [2] = 5, [3] = 8 }

function RPG.MimicBlackout.OnStageAdvance(player, stage)
    local cfg = STAGE_SEVERITY[stage]
    if not cfg then return end

    local game = RPG.GetGame(player)
    if not game then return end

    local tier = cfg.tier

    -- Tiers 1-3: print escalating fragment text + small paranoia gain.
    if tier >= 1 and tier <= 3 then
        local lines = TIER_TEXTS[tier]
        if lines then
            player:SendPrint("")
            for _, line in ipairs(lines) do
                player:SendPrint(line)
            end
            player:SendPrint("")
        end
        local gain = TIER_PARANOIA[tier] or 0
        if gain > 0 then
            RPG.AddParanoia(player, gain)
        end
        return
    end

    -- Tier 4: severe blackout with Corrupted-memory hooks. Filled in Task 11/12.
    if tier == 4 then
        -- placeholder
        return
    end
end
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "MimicBlackout.OnStageAdvance" base/glua/rpg/quest.lua
```
Expected: one match in the SetStage success path.

```bash
grep -n "your hands are wet\|the corridor is wrong" base/glua/rpg/mimic_blackout.lua
```
Expected: matches for tier-2 and tier-3 lines.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/quest.lua base/glua/rpg/mimic_blackout.lua
git commit -m "feat(rpg): Mimic blackout stages 1-3 escalation (Phase 2A #10 mid)"
```

---

## Task 11: Mimic blackout stage 4 — wake-up + inventory tampering (Spec #10 finale part 1)

**Files:**
- Modify: `base/glua/rpg/mimic_blackout.lua` (tier-4 handler — wake-up text + inventory swap)

**Rationale:** Stage 4 (`confront_truth`) is the severe blackout. Three Corrupted-memory hooks fire together:
1. **Wake-up text** — 4 lines suggesting lost time + location-jump implication.
2. **Inventory tampering** — silently remove the player's most common consumable (a healing item) and add Item 42 "Bloodied Cloth (Not Yours)." Bloodied Cloth's examineText reads from `game.killLog` to reference a specific previous kill.
3. (Task 12 wires the false journal entry separately.)

The hook is silent — no message about the inventory swap. The player discovers it when they next open inventory and see "Bloodied Cloth" with a missing medpac.

**Healing item identification:** the codebase has several healing/stim consumables (Items 18 Adrenal Stimulant, 23 Sliced Stim, 29 Dxun Jungle Extract); no item is named literally "Medpac." Spec §4.1 #10 says "remove 1 medpac" — we treat that as "remove a healing consumable specifically, not any consumable." If no healing consumable is present, the removal step is **a no-op** (only the Bloodied Cloth is added). Predicate fallback to "first consumable of any kind" was rejected in plan review (Important #5): risk of removing quest-critical consumables outweighs the value of always removing something.

- [ ] **Step 1: Identify the healing-consumable predicate**

Run:
```bash
grep -n -E "hpGain|restoresHP|heal\s*=|effect.*heal|hp\s*=\s*\d+" base/glua/rpg/data/items.lua
```

Confirm which field indicates "heals HP" on consumable item definitions. Expected (based on KOTOR-style item shapes): one of `hpGain`, `heal`, `restoresHP`, or an `effect = { type = "heal", amount = N }` table.

If NO heal field exists across any consumable, the inventory tampering becomes "remove nothing, add the Cloth" — still narratively valid (the Mimic left a trace; the player just hasn't lost anything yet). Note this outcome in the implementer report so the spec can be re-evaluated for Phase 2B.

- [ ] **Step 2: Fill in the tier-4 handler (heal-tag-first, no-op if none)**

Replace the placeholder tier-4 block in `mimic_blackout.lua` with:

```lua
    -- Tier 4: severe blackout. confront_truth stage.
    -- Three Corrupted-memory hooks fire together (this task handles 2 of 3).
    if tier == 4 then
        -- Hook A: 4-line wake-up text. Suggests lost time + location-jump.
        player:SendPrint("")
        player:SendPrint("^1[you do not remember the last hour]")
        player:SendPrint("^1[you stand in a room you do not remember entering]")
        player:SendPrint("^1[your hands smell like soap]")
        player:SendPrint("^1[someone has scrubbed your hands clean]")
        player:SendPrint("")
        RPG.AddParanoia(player, 12)

        -- Hook B: silent inventory tampering — remove first HEAL-tagged consumable, add Bloodied Cloth.
        -- Predicate is heal-only (not any consumable) to avoid stealing quest-critical or quest-side items.
        -- If no heal-tagged item is in inventory, the removal is a no-op; only the Bloodied Cloth is added.
        local inv = game.player.inventory
        if inv and #inv > 0 then
            local removeIdx = nil
            for i, itemId in ipairs(inv) do
                local def = RPG.Data.Items and RPG.Data.Items[itemId]
                if def and def.type == "consumable" then
                    local heals =
                        (def.hpGain ~= nil and def.hpGain > 0)
                        or (def.heal ~= nil and def.heal > 0)
                        or (def.restoresHP ~= nil and def.restoresHP > 0)
                        or (def.effect and def.effect.type == "heal")
                    if heals then
                        removeIdx = i
                        break
                    end
                end
            end
            if removeIdx then
                table.remove(inv, removeIdx)
            end
        end

        if inv and #inv < RPG.Config.MAX_INVENTORY then
            inv[#inv + 1] = 42    -- Item 42 = Bloodied Cloth (Not Yours)
        end

        -- Hook C: false journal entry — wired in Task 12.
        return
    end
```

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "your hands smell like soap" base/glua/rpg/mimic_blackout.lua
```
Expected: one match.

```bash
grep -n "inv\[#inv + 1\] = 42" base/glua/rpg/mimic_blackout.lua
```
Expected: one match.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/mimic_blackout.lua
git commit -m "feat(rpg): Mimic blackout stage 4 wake-up + inventory tampering (Phase 2A #10 part A)"
```

---

## Task 12: Mimic blackout stage 4 — false journal entry (Spec #10 finale part 2)

**Files:**
- Modify: `base/glua/rpg/mimic_blackout.lua` (push fake entry onto `game.fakeJournalEntries`)
- Modify: `base/glua/rpg/menus/menu_quest_log.lua` (render fake entries alongside real quests)

**Rationale:** Third Corrupted-memory hook from stage 4. A planted entry — "Delivered Holocron to Zherron — COMPLETED" — appears in the quest log even though the player did no such thing. The Holocron is still in their possession. The entry is rendered visually identical to real completed quests, but it lives in a separate table (`game.fakeJournalEntries`) so it can be inspected, audited, or replayed across saves without polluting the real quest state machine.

**Why separate from `game.quests`:** real quests have state-machine rules (active → stages → complete). A fake quest in `game.quests` could break ordering or trigger unintended completions. Keeping fakes in their own table preserves the integrity of the real system.

- [ ] **Step 1: Fill in Hook C in mimic_blackout.lua**

In `mimic_blackout.lua`, find the tier-4 block (just before the `return`). Replace `-- Hook C: false journal entry — wired in Task 12.` with:

```lua
        -- Hook C: false journal entry. Planted to make the player doubt their record-keeping.
        -- Stored in game.fakeJournalEntries (separate table) — never pollutes the real quest machine.
        game.fakeJournalEntries = game.fakeJournalEntries or {}
        game.fakeJournalEntries[#game.fakeJournalEntries + 1] = {
            title = "Delivered Holocron to Zherron",
            journal = "Adare's request — handed the Holocron to Zherron for safe transport off Dantooine.",
            status = "completed",
        }
```

- [ ] **Step 2: Render fakes in menu_quest_log.lua**

Open `base/glua/rpg/menus/menu_quest_log.lua`. Find where completed quests are rendered (look for `status == "completed"` or a loop over `game.quests`). After the existing loop appends real completed-quest lines, append fakes:

```lua
-- Phase 2A #10: render planted false quest entries alongside reals. Visually identical;
-- live in game.fakeJournalEntries so they never pollute the real quest state machine.
local fakes = game and game.fakeJournalEntries or {}
for _, fq in ipairs(fakes) do
    if fq.status == "completed" then
        lines[#lines + 1] = "^2[Completed] " .. fq.title
        if fq.journal then
            lines[#lines + 1] = "^7" .. fq.journal
        end
    end
end
```

Place this AFTER the loop that renders `game.quests` completed entries, so fakes appear visually mixed with the real list. Adapt variable names (`lines`, `fakes`) to whatever the file already uses.

- [ ] **Step 3: Verify**

Run:
```bash
grep -n "Delivered Holocron to Zherron" base/glua/rpg/mimic_blackout.lua
```
Expected: one match.

```bash
grep -n "fakeJournalEntries" base/glua/rpg/menus/menu_quest_log.lua
```
Expected: one match in the render loop.

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/mimic_blackout.lua base/glua/rpg/menus/menu_quest_log.lua
git commit -m "feat(rpg): Mimic blackout stage 4 false journal entry (Phase 2A #10 part B)"
```

---

## Task 13: Phase 2A "ready for Phase 2B" gate (deferred playtest)

**Files:** None. This is a verification + handoff task only.

**Rationale:** Per the spec §4.2, Phase 2A normally has its own playtest gate (Force Void calibration, Karath/Holocron split tonal check, Mimic blackout escalation, Shadow Self STAT mirror). The user chose to combine playtest with Phase 2B. This task confirms the code landed and the deploy is ready — but the **acceptance commit is deferred** to the end of Phase 2B.

- [ ] **Step 1: Verify all commits landed on the branch**

Run:
```bash
git log --oneline -20
```

Expected: 12 new commits from Tasks 1-12 sit on top of the Phase 1 head. Commits should mention:
- Shadow Self STAT mirror (#12)
- cipher reframe Saevus + cipher reframe Truth (#9a, #9b)
- Force Void FP dampener + dialogue tag (#11a, #11b)
- Karath breakdown + Holocron voice + wire split (#8 parts 1, 2, 3)
- Mimic blackout infrastructure + stages 1-3 + stage 4 wake-up + stage 4 false journal (#10 setup, mid, A, B)

- [ ] **Step 2: Verify Phase 2A markers on disk**

Run:
```bash
grep -l "Phase 2A" base/glua/rpg
```

Expected: every file modified by Phase 2A appears.

- [ ] **Step 3: Push to remote**

```bash
git push origin builder-shader-scanner-audit
```

- [ ] **Step 4: Deploy to VPS**

SSH to `ubuntu@158.69.218.235` and run `~/restart_custom_server.sh` (full deploy, NO `-n` flag — Lua-only changes need the rsync to homepath).

Tail the server log briefly to confirm the new module loaded:
```bash
ssh ubuntu@158.69.218.235 "tail -30 ~/NewSharding/openjk_home/server.log | grep -i 'Mimic Blackout'"
```

Expected: `RPG: Mimic Blackout system loaded`.

- [ ] **Step 5: Confirm SAVE_VERSION did NOT bump**

```bash
grep -n "SAVE_VERSION" base/glua/rpg/save.lua
```

Expected: `local SAVE_VERSION = 2` (unchanged from Phase 1).

**Save-compatibility precondition (important):** `RPG.Save.ValidateSnapshot` at `save.lua:228` performs STRICT equality (`snapshot.saveVersion ~= SAVE_VERSION` → reject). The "Phase-2A adds default-safe fields without bumping" pattern works **only because Phase 0 and Phase 1 saves are already SAVE_VERSION 2** — the format pre-condition is met before we layer on `or {}` fallbacks. If any future phase changes the snapshot shape (renamed field, removed field, changed encoding), the version MUST bump and a migration path MUST exist, because `or {}` alone does not survive shape changes. This is the rule for additive-only field changes; do not generalize it.

A Phase-1 save loaded under Phase-2A code should restore cleanly with `game.killLog = {}` and `game.fakeJournalEntries = {}` (via the `or {}` fallback in RestoreFromSnapshot). Manually verify this in-game during the Phase-2B combined playtest by loading a Phase-1 save and confirming no errors print.

- [ ] **Step 6: Note the deferred playtest gate**

Phase 2A's per-item gate from §4.2 is deferred. Do NOT make an acceptance commit. The combined Phase-2A+2B playtest happens at the end of the Phase 2B plan. If the user reports any Phase-2A beat reading flat during the combined gate, revise that item before opening Phase 3.

**No commit at this step.** Phase 2A is "code-complete and deployed" — acceptance is paused.

---

## Phase 2A Wrap-Up

After Task 13, the deliverable is:
- 12 commits on `builder-shader-scanner-audit` covering items #8, #9, #10, #11, #12.
- One new module (`mimic_blackout.lua`).
- Two new game-level state fields (`killLog`, `fakeJournalEntries`) persisted via existing save infrastructure.
- One new item (#42 Bloodied Cloth).
- Two new config constants (`FORCE_VOID_PARANOIA_MIN`, `FORCE_VOID_FP_GAIN_MULT`).
- Replacement of the literal `rpgPlayer_t` fourth-wall scene with two in-fiction halves.

**Next step:** write the Phase 2B plan (Memory Systems, spec §5). Combined playtest gate runs after Phase 2B is implemented and deployed.

**Rollback safety:** Each task is one git commit. Reverting any single commit cleanly removes that item without affecting the others — except Task 9 (infrastructure), which Tasks 10/11/12 build on. If a Phase-2A item needs to be cut entirely, revert in reverse Task order (12 → 11 → 10 → 9, then independently 8 → 7 → 6 → 5 → 4 → 3 → 2 → 1).
