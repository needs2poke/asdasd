# Phase 2A Plan Review — Bundle Index

This bundle now contains a current snapshot for reviewing the Phase 2A plan.

## What to read

1. **Plan under review:** `docs/superpowers/plans/2026-05-12-rpg-phase2a-horror-mechanics.md`
2. **Spec it implements:** `docs/superpowers/specs/2026-05-12-rpg-echoes-enhancements-v4-design.md` — §4 (items #8-#12) is Phase 2A scope
3. **Prior phase plans (already shipped, do not re-review):**
   - `docs/superpowers/plans/2026-05-12-rpg-phase0-save-load-infrastructure.md`
   - `docs/superpowers/plans/2026-05-12-rpg-phase1-narrative-beats.md`

## What's in the code snapshot

`base/glua/rpg/` is now a 1:1 copy of the live deployable codebase (69 files). Phase 0 and Phase 1 are merged in — so save.lua already has `SAVE_VERSION = 2`, state.lua has `forceSevered`, ending.lua has the Truth-ending Force-Sever lines, etc. Phase 2A is unimplemented; nothing in this snapshot has #8-#12 code yet.

## Fields the prior review pass questioned (now confirmed present)

These exist in the snapshot — please verify before flagging them as missing:

- `game.player.hasHolocron` — `state.lua:58` (initialised), `save.lua:184` (snapshot), used in 50+ call sites
- `RPG.Config.MAX_INVENTORY = 50` — `config.lua:28`
- `healAmount` field on healing consumables — `data/items.lua` lines 30, 104, 160, 192, 264

## Phase 2A touch list (files the plan modifies)

`combat.lua`, `config.lua`, `state.lua`, `save.lua`, `quest.lua`, `horror.lua`, `ending.lua`, `init.lua`, `data/items.lua`, `data/dialogues/saevus_manifest.lua`, `menus/menu_dialogue.lua`, `menus/menu_inventory.lua`, `menus/menu_quest_log.lua`.

Plus one new file: `mimic_blackout.lua` (does not yet exist).

## Open design question for reviewers

Force Void scope (spec §4.1 #11) — current plan dampens FP gain only at the Force Absorb site (the single in-combat FP-gain location, `combat.lua:2024`). Most players will rarely trigger this because Force Absorb only fires when the *enemy* uses a special. Alternative: apply Void multiplier to Force-power cost (+25%) so it fires every time the player uses a Force power. Same spec intent ("Force feels wrong in Void rooms"), much more visible. Surface your recommendation.

## Review focus

Flag only **implementation blockers** (wrong file/path/field/signature, missing infra, save-format breakage, soft-locks). The plan was already creatively reviewed; this pass is to keep the implementer from hitting code-level surprises.
