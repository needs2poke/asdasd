# RPG Phase 0 — Save / Load / New Game Infrastructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the RPG save/load system crash-safe and discoverable: periodic + checkpoint autosave, GameShutdown hook, a boot menu, in-game Save/Load/Quit-to-Boot, and a reusable confirm sub-menu. Acceptance: 5 manual tests in §12.5 of the spec.

**Architecture:** Three layers, smallest blast radius first.
- **Save infra layer** (`save.lua`, `config.lua`): cooldown wrapper, delete helper, lightweight metadata read, autosave timer.
- **Persistence hook layer** (`init.lua`, `state.lua`, `quest.lua`, `ending.lua`, `cipher.lua`): wire the autosave wrapper into the right gameplay moments + a GameShutdown subscriber.
- **Menu UX layer** (2 new menu files, `menu_exploration.lua`): boot menu + reusable confirm menu + in-game Save/Load/Quit entries.

**Tech Stack:** GLua (Lua 5.1 dialect inside OpenJK's `jampgame` DLL), `File` API → `trap->FS_Open(FS_WRITE)` (auto-creates intermediate dirs), `Timer`, `Menu` (centerprint), `hook.Add`. No automated test framework — verification is manual on the VPS per the project's edit/commit/push → deploy → in-game workflow.

**Source spec:** `docs/superpowers/specs/2026-05-12-rpg-echoes-enhancements-v4-design.md` §12 (v5.0).

**Deploy workflow reminder** (from project memory):
- Windows is edit/commit/push only. Compilation/sync happens on the Linux VPS.
- `restart_custom_server.sh -n` skips Lua rsync. **For Lua-only changes use the full deploy (no `-n`)**, or manually rsync to `~/NewSharding/openjk_home/base/glua/` before running `-n`.
- Deploy pulls `builder-shader-scanner-audit`. Push to that branch (not `-impl`) and verify the file on disk shows the change before testing.

---

## File Structure

**Files modified:**
- `base/glua/rpg/config.lua` — add 5 config constants (autosave cadence, cooldown, log toggle, 2 STATE_MENUS entries).
- `base/glua/rpg/save.lua` — add 5 functions: `AutoSave`, `Delete`, `GetMetadata`, `StartAutoSaveTimer`, `StopAutoSaveTimer`; mutate `Write` to stamp `game.lastSaveAt`.
- `base/glua/rpg/state.lua` — `NewGame` starts timer + caches save key; `Shutdown` stops timer; `SetState` allow-list extended to include `boot` and `confirm`.
- `base/glua/rpg/init.lua` — load 2 new menus; replace `!rpg` no-args text prompt with boot-menu open; add `GameShutdown` hook; add `!rpgdebug save_status`.
- `base/glua/rpg/quest.lua` — call `AutoSave` after `Quest.Complete` rewards applied.
- `base/glua/rpg/cipher.lua` — call `AutoSave` after successful cipher submit.
- `base/glua/rpg/ending.lua` — call `AutoSave` at the very start of `Trigger` (pre-state-transition snapshot).
- `base/glua/rpg/menus/menu_exploration.lua` — extend `Menu` expandable category with Save Game / Load Last Save / Quit to Boot; route Quit RPG accordingly.

**Files created:**
- `base/glua/rpg/menus/menu_boot.lua` — `rpg_boot` menu (Continue / New Game / Cancel, dynamic items).
- `base/glua/rpg/menus/menu_confirm.lua` — `rpg_confirm` generic two-choice dialog.

---

## Task 1: Config additions

**Files:**
- Modify: `base/glua/rpg/config.lua:104-124` (append to STATE_MENUS) and right after STATE_MENUS block

- [ ] **Step 1: Add the five new constants**

Edit `config.lua`. Add **inside** the `RPG.Config.STATE_MENUS = { ... }` block (preserve existing entries — these are two NEW entries appended before the closing brace):

```lua
    boot            = "rpg_boot",
    confirm         = "rpg_confirm",
```

Then **immediately after** the `STATE_MENUS` block's closing `}` (so it lives in the same config area), add:

```lua
-- ============================================
-- AUTOSAVE (Phase 0 — save/load infrastructure)
-- ============================================
RPG.Config.AUTOSAVE_INTERVAL_MS = 90000        -- Periodic autosave cadence (90s)
RPG.Config.AUTOSAVE_COOLDOWN_MS = 10000        -- Min ms between any saves (chain-fire defuse)
RPG.Config.AUTOSAVE_LOG_TO_PLAYER = false      -- If true, print "[Game saved]" on each autosave
```

- [ ] **Step 2: Verify file parses**

Push to VPS and have the user reload `!rpgreload` (or restart). Watch the server console for the load banner.

```
Expected: "Echoes of the Dark Wars v..." banner appears with no Lua errors.
```

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/config.lua
git commit -m "feat(rpg): add Phase 0 config — autosave cadence, cooldown, boot/confirm states"
```

---

## Task 2: `save.lua` core helpers — Write timestamp, AutoSave, Delete, GetMetadata

**Files:**
- Modify: `base/glua/rpg/save.lua:261-310` (Write function — add lastSaveAt stamp)
- Modify: `base/glua/rpg/save.lua` (append new helpers before the final `return RPG.Save`)

- [ ] **Step 1: Stamp `lastSaveAt` on successful Write**

In `RPG.Save.Write` at the very end (after `local path = SavePath(saveKey)` and the final `return RPG.Save.WriteToPath(path, jsonStr)`), replace the final return with this so we can capture the success result:

```lua
    local path = SavePath(saveKey)
    local ok, err = RPG.Save.WriteToPath(path, jsonStr)
    if ok then
        game.lastSaveAt = os.time() * 1000   -- ms epoch for cooldown math
    end
    return ok, err
end
```

The block this replaces (last 2 lines of the existing function) is:

```lua
    local path = SavePath(saveKey)
    return RPG.Save.WriteToPath(path, jsonStr)
end
```

- [ ] **Step 2: Add `RPG.Save.AutoSave` wrapper**

Insert before the final `GLua.Print("RPG: Save system loaded")` line. This is the cooldown-respecting save that A1 timer and A2 checkpoint instrumentation will both call.

```lua
-- ============================================
-- AUTOSAVE WRAPPER (cooldown-gated)
-- ============================================

--- Cooldown-gated save. Returns (ok, err) where ok=true means "saved", ok=false err="cooldown" means "skipped".
function RPG.Save.AutoSave(player)
    if not player or not player.IsValid or not player:IsValid() then
        return false, "invalid player"
    end
    local game = RPG.GetGame(player)
    if not game or not game.player or not game.player.class then
        return false, "no active class-bearing session"
    end

    local nowMs = os.time() * 1000
    local last = game.lastSaveAt or 0
    if (nowMs - last) < RPG.Config.AUTOSAVE_COOLDOWN_MS then
        return false, "cooldown"
    end

    local ok, err = RPG.Save.Write(player)
    if ok and RPG.Config.AUTOSAVE_LOG_TO_PLAYER then
        player:SendPrint("^8[Game saved]")
    end
    return ok, err
end
```

- [ ] **Step 3: Add `RPG.Save.Delete`**

```lua
-- ============================================
-- DELETE (for New Game confirm)
-- ============================================

--- Delete the save file(s) for a player. Removes both account-keyed and legacy GUID-keyed files.
function RPG.Save.Delete(player)
    if not File or not File.Write then
        return false, "File API not available"
    end
    local removed = 0
    local primaryKey = RPG.Save.GetPlayerKey(player)
    if primaryKey then
        -- Empty-string overwrite is the simplest portable "delete" via FS_WRITE.
        -- File.Read on an empty file returns "" which Read() treats as "no save".
        local ok = RPG.Save.WriteToPath(SavePath(primaryKey), "")
        if ok then removed = removed + 1 end
    end
    local guidKey = nil
    if player and player.GetGUID then
        local guid = player:GetGUID() or ""
        if guid ~= "" then
            local hash = 0
            for i = 1, #guid do
                hash = (hash * 31 + string.byte(guid, i)) % 2147483647
            end
            guidKey = "guid_" .. hash
        end
    end
    if guidKey and guidKey ~= primaryKey then
        local ok = RPG.Save.WriteToPath(SavePath(guidKey), "")
        if ok then removed = removed + 1 end
    end
    return removed > 0, (removed > 0) and nil or "no files removed"
end
```

Note: we overwrite with empty string rather than calling an `os.remove` equivalent because the GLua `File` API only exposes Write/Read/Exists/Append — there's no Remove. An empty file is treated as "no save" by `RPG.Save.Read` (line 342: `if not content or content == "" then return nil, "no save file found"`).

- [ ] **Step 4: Add `RPG.Save.GetMetadata`**

```lua
-- ============================================
-- METADATA (lightweight read for boot menu)
-- ============================================

--- Returns lightweight save metadata without applying restore. nil if no/invalid save.
--- Result: { class, level, currentRoom, currentRoomName, savedAt }
function RPG.Save.GetMetadata(player)
    local snapshot, _ = RPG.Save.Read(player)
    if not snapshot or not snapshot.player then return nil end
    local sp = snapshot.player
    local roomId = sp.currentRoom or 0
    local roomName = "Unknown"
    if RPG.Data and RPG.Data.Rooms and RPG.Data.Rooms[roomId] then
        roomName = RPG.Data.Rooms[roomId].name or "Unknown"
    end
    return {
        class           = sp.class,
        level           = sp.level or 1,
        currentRoom     = roomId,
        currentRoomName = roomName,
        savedAt         = snapshot.savedAt or 0,
        playerName      = snapshot.playerName or "",
    }
end
```

Note: `Save.Read` already validates + decodes + auto-migrates GUID. We reuse it for safety; the cost is one extra JSON decode per boot-menu open, which is negligible.

- [ ] **Step 5: Smoke-test on VPS**

User-action: connect to server, type `!rpgdebug save_status` (doesn't exist yet — will work after Task 12), or simply confirm no Lua errors on load. Easiest check: have user run an existing `!rpg save` command and observe `^2Game saved!` print. Then verify the save file via SSH:

```bash
ssh ubuntu@158.69.218.235 'ls -la ~/NewSharding/openjk_home/base/glua/data/rpg_saves/'
```

```
Expected: at least one *.json file exists, modified within last minute.
```

- [ ] **Step 6: Commit**

```bash
git add base/glua/rpg/save.lua
git commit -m "feat(rpg/save): add AutoSave cooldown wrapper, Delete, GetMetadata helpers + Write timestamp"
```

---

## Task 3: Autosave timer lifecycle in `save.lua`

**Files:**
- Modify: `base/glua/rpg/save.lua` (append before final `GLua.Print`)

- [ ] **Step 1: Add Start/Stop timer functions**

```lua
-- ============================================
-- PERIODIC AUTOSAVE TIMER
-- ============================================

--- Start the per-player periodic autosave timer.
--- Called from RPG.NewGame and RPG.Save.RestoreFromSnapshot after save key is cached.
function RPG.Save.StartAutoSaveTimer(player, game)
    if not player or not player.IsValid or not player:IsValid() then return end
    if not game or not game.player or not game.player.class then return end

    local clientNum = player:GetClientNum()
    local timerName = "rpg_autosave_" .. clientNum
    Timer.Remove(timerName)  -- Idempotent: clear any pre-existing timer

    Timer.Create(timerName, RPG.Config.AUTOSAVE_INTERVAL_MS, 0, function()
        local p = Player.Get(clientNum)
        if not p or not p:IsValid() then
            Timer.Remove(timerName)
            return
        end
        local g = RPG.GetGame(p)
        if not g then
            Timer.Remove(timerName)
            return
        end
        -- State gate: only autosave from exploration. Skips combat/dialogue/cipher_input/ending/menus.
        if g.state ~= "exploration" then return end
        RPG.Save.AutoSave(p)
    end)
end

--- Stop the autosave timer for a clientNum (called from RPG.Shutdown).
function RPG.Save.StopAutoSaveTimer(clientNum)
    if type(clientNum) ~= "number" then return end
    Timer.Remove("rpg_autosave_" .. clientNum)
end
```

- [ ] **Step 2: Verify no syntax errors**

Push, deploy, watch server console for "RPG: Save system loaded".

```
Expected: No errors. Save module loads.
```

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/save.lua
git commit -m "feat(rpg/save): add periodic autosave timer (Start/Stop)"
```

---

## Task 4: Wire timer lifecycle into `state.lua` (NewGame, RestoreFromSnapshot, Shutdown)

**Files:**
- Modify: `base/glua/rpg/state.lua:130-137` (NewGame — already calls CacheKey; add StartAutoSaveTimer)
- Modify: `base/glua/rpg/save.lua:576-587` (RestoreFromSnapshot — already calls CacheKey; add StartAutoSaveTimer)
- Modify: `base/glua/rpg/state.lua:213-238` (Shutdown — add StopAutoSaveTimer)

- [ ] **Step 1: Start timer from NewGame**

In `state.lua` immediately after the existing `RPG.Save.CacheKey` call at line ~132, add:

```lua
    -- Cache save key for disconnect autosave
    if RPG.Save and RPG.Save.CacheKey then
        RPG.Save.CacheKey(player, game)
    end

    -- Start periodic autosave timer
    if RPG.Save and RPG.Save.StartAutoSaveTimer then
        RPG.Save.StartAutoSaveTimer(player, game)
    end
```

- [ ] **Step 2: Start timer from RestoreFromSnapshot**

In `save.lua` `RPG.Save.RestoreFromSnapshot`, immediately after the existing `RPG.Save.CacheKey(player, game)` call (currently around line 577), add:

```lua
    -- Cache save key for future autosave
    RPG.Save.CacheKey(player, game)

    -- Start periodic autosave timer
    RPG.Save.StartAutoSaveTimer(player, game)
```

- [ ] **Step 3: Stop timer from Shutdown**

In `state.lua` `RPG.Shutdown` (line ~191), in the cleanup section where existing Timer.Remove calls live (around line 214-222), add a line for the autosave timer:

```lua
    -- Cancel any pending narration/companion timers
    Timer.Remove("rpg_room_narrate_" .. clientNum)
    Timer.Remove("rpg_class_narrate_" .. clientNum)
    Timer.Remove("rpg_companion_comment_" .. clientNum)
    Timer.Remove("rpg_crowd_whisper_" .. clientNum)
    Timer.Remove("rpg_crowd_first_" .. clientNum)
    Timer.Remove("rpg_flash_" .. clientNum)
    Timer.Remove("rpg_combat_result_" .. clientNum)
    Timer.Remove("rpg_whisper_room_" .. clientNum)
    Timer.Remove("rpg_autosave_" .. clientNum)
```

(Using direct `Timer.Remove` here mirrors the other timers; alternatively `RPG.Save.StopAutoSaveTimer(clientNum)` works. The direct form is consistent with the surrounding code.)

- [ ] **Step 4: Smoke test on VPS**

User-action:
1. Connect, `!rpg`, pick class, get into exploration.
2. Wait ~95 seconds in exploration state.
3. SSH check: `ls -la ~/NewSharding/openjk_home/base/glua/data/rpg_saves/`. The mtime should advance by ~90s windows.

```
Expected: save file mtime updates roughly every 90s while player sits in exploration.
```

- [ ] **Step 5: Commit**

```bash
git add base/glua/rpg/state.lua base/glua/rpg/save.lua
git commit -m "feat(rpg): wire periodic autosave timer to NewGame/RestoreFromSnapshot/Shutdown"
```

---

## Task 5: `GameShutdown` hook in `init.lua`

**Files:**
- Modify: `base/glua/rpg/init.lua` (append before final READY banner, around line ~944)

- [ ] **Step 1: Subscribe to GameShutdown**

Find the existing `PlayerDisconnect` hook at `init.lua:916-944`. Immediately after the closing of that hook (after the final `end)`), add:

```lua
-- ============================================
-- GAMESHUTDOWN AUTOSAVE (Phase 0)
-- Persists ALL active sessions on server shutdown.
-- Engine grants a finite window; saves are ~few KB JSON each.
-- ============================================

hook.Add("GameShutdown", "RPG.GameShutdown.AutoSaveAll", function()
    if not RPG.Save or not RPG.Save.Write then return end
    local saved, failed = 0, 0
    for clientNum, game in pairs(RPG.players or {}) do
        if game and game.player and game.player.class and game.saveKey then
            local ok, err = RPG.Save.Write(game)
            if ok then
                saved = saved + 1
            else
                failed = failed + 1
                GLua.Warn("RPG.GameShutdown: save failed for client " .. clientNum .. ": " .. tostring(err))
            end
        end
    end
    GLua.Print("RPG.GameShutdown: autosaved " .. saved .. " sessions (" .. failed .. " failed)")
end)
```

Note: `RPG.Save.Write` accepts a game table directly (see `save.lua:269-281`), so we don't need a Player object — which is good because at GameShutdown time player objects may already be torn down.

- [ ] **Step 2: Smoke test on VPS**

User-action:
1. Connect 1-2 players, start RPG sessions, get into exploration.
2. SSH: `pkill openjkded` (or graceful kill). Watch server console for "RPG.GameShutdown: autosaved N sessions".
3. Restart server. Reconnect. `!rpg` → save found (Boot menu doesn't exist yet, so player gets the text prompt). `!rpg load`. State intact.

```
Expected: GameShutdown log line prints; save files updated immediately before shutdown; reconnect after restart can load.
```

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/init.lua
git commit -m "feat(rpg): GameShutdown hook autosaves all active sessions"
```

---

## Task 6: Checkpoint autosaves (Quest.Complete, Acts, Cipher, Ending)

**Files:**
- Modify: `base/glua/rpg/quest.lua:182-230` (Quest.Complete — after rewards block)
- Modify: `base/glua/rpg/state.lua:243-264` (UnlockAct3, UnlockAct4)
- Modify: `base/glua/rpg/cipher.lua:121-140` (OnSubmit success path)
- Modify: `base/glua/rpg/ending.lua:182-234` (Trigger — at top, BEFORE state transition)

- [ ] **Step 1: Quest.Complete checkpoint**

In `quest.lua` `RPG.Quest.Complete`, find the end of the function (after rewards/effects applied and Atton trust gate logic). Just before the final `return true` (or the function's closing `end`), add:

```lua
    -- Phase 0 checkpoint autosave: lock in quest completion
    if RPG.Save and RPG.Save.AutoSave then
        RPG.Save.AutoSave(player)
    end
```

- [ ] **Step 2: UnlockAct3 checkpoint**

In `state.lua:243-250`, modify `RPG.UnlockAct3`:

```lua
function RPG.UnlockAct3(player, game)
    local wasBelow = game.currentAct < 3
    if wasBelow then
        game.currentAct = 3
    end
    if game.rooms[16] then
        game.rooms[16].exits.East = 36
    end
    -- Phase 0 checkpoint: only save when act actually advanced (idempotent calls don't trigger)
    if wasBelow and player and RPG.Save and RPG.Save.AutoSave then
        RPG.Save.AutoSave(player)
    end
end
```

(Note: `UnlockAct3` is sometimes called with `player == nil` from save-restore. The `player and` guard skips the save in that case — which is correct since RestoreFromSnapshot doesn't need to write back.)

- [ ] **Step 3: UnlockAct4 checkpoint**

In `state.lua:252-264`, modify `RPG.UnlockAct4`:

```lua
function RPG.UnlockAct4(player, game)
    RPG.UnlockAct3(player, game)  -- ensure Act 3 prerequisites
    local wasBelow = game.currentAct < 4
    if wasBelow then
        game.currentAct = 4
    end
    -- Unlock room 43 (Act 4 gate, locked until Shadow Self defeated)
    if game.rooms[43] and game.rooms[43].locked then
        game.rooms[43].locked = false
    end
    if game.rooms[48] then
        game.rooms[48].locked = false
    end
    if wasBelow and player and RPG.Save and RPG.Save.AutoSave then
        RPG.Save.AutoSave(player)
    end
end
```

- [ ] **Step 4: Cipher solve checkpoint**

In `cipher.lua` `RPG.Cipher.OnSubmit`, find the success path. After the `RPG.Quest.SetStage(player, "echoes_final", "cipher_solved")` block at line ~134 and before the success narration `player:SendPrint("^2========================================")`, add:

```lua
        -- Phase 0 checkpoint: cipher solved is a major commit point
        if RPG.Save and RPG.Save.AutoSave then
            RPG.Save.AutoSave(player)
        end
```

- [ ] **Step 5: Ending Trigger checkpoint (pre-state-transition)**

In `ending.lua` `RPG.Ending.Trigger`, immediately after `if not game then return end` (line 184) and BEFORE `BuildEndingData` is called, add:

```lua
    -- Phase 0 checkpoint: capture pre-ending state so restart-during-ending replays from choice
    if RPG.Save and RPG.Save.AutoSave then
        RPG.Save.AutoSave(player)
    end
```

The intent: state is still `exploration` at this point. If the player crashes during ending narration, the save reflects choice-room exploration state, not partial-ending state.

- [ ] **Step 6: Smoke test on VPS**

User-action:
1. `!rpgdebug quickstart guardian`, `!rpgdebug quest complete echoes`. SSH-check save mtime — should jump within a second.
2. `!rpgdebug act3`. Save mtime should jump again (subject to 10s cooldown — if too soon after Step 1, may be skipped; that's correct behavior).
3. Wait 15s, `!rpgdebug act4`. Save mtime jumps.
4. `!rpgdebug room 49`, `!rpgcipher 492173949`. Save mtime jumps post-success.
5. `!rpgdebug ending light`. Save mtime jumps immediately before ending narration plays.

```
Expected: save file mtime updates at each major checkpoint, gated by 10s cooldown.
```

- [ ] **Step 7: Commit**

```bash
git add base/glua/rpg/quest.lua base/glua/rpg/state.lua base/glua/rpg/cipher.lua base/glua/rpg/ending.lua
git commit -m "feat(rpg): checkpoint autosaves at quest complete, act unlock, cipher solve, ending trigger"
```

---

## Task 7: Reusable confirm menu (`menu_confirm.lua`)

**Files:**
- Create: `base/glua/rpg/menus/menu_confirm.lua`
- Modify: `base/glua/rpg/init.lua` (add to module list + SafeLoad sequence)

- [ ] **Step 1: Create `menu_confirm.lua`**

```lua
-- Echoes of the Dark Wars - Reusable Confirm Dialog
-- Generic two-choice (Confirm / Cancel) modal.
-- Caller stores state via state.data: { title, body, onConfirm, onCancel, returnState }

RPG = RPG or {}

Menu.Register("rpg_confirm", {
    title = function(player, state)
        return (state.data and state.data.title) or "^3Confirm"
    end,

    header = function(player, state)
        return (state.data and state.data.body) or ""
    end,

    getItems = function(player, state)
        return {
            { label = "^2Confirm", action = "confirm" },
            { label = "^7Cancel",  action = "cancel"  },
        }
    end,

    onAction = function(player, action, state, selectedItem)
        local data = state.data or {}
        if action == "confirm" then
            if type(data.onConfirm) == "function" then
                data.onConfirm(player)
            end
            return
        end
        if action == "cancel" then
            if type(data.onCancel) == "function" then
                data.onCancel(player)
            elseif data.returnState then
                RPG.SetState(player, data.returnState)
            else
                -- Best-effort fallback: go back to previous state
                RPG.GoBack(player)
            end
            return
        end
    end,

    onBack = function(player, state)
        local data = state.data or {}
        if type(data.onCancel) == "function" then
            data.onCancel(player)
        elseif data.returnState then
            RPG.SetState(player, data.returnState)
        else
            RPG.GoBack(player)
        end
        return true
    end,

    controls = "W/S: Navigate | USE: Select | ESC: Cancel",
    maxVisibleItems = 4,
})

return true
```

- [ ] **Step 2: Add to module loader in `init.lua`**

In the `modules` table around line 79 (after `"rpg.menus.menu_glitch"`), add:

```lua
    "rpg.menus.menu_glitch",
    "rpg.menus.menu_confirm",
    "rpg.menus.menu_boot",
```

Then in the SafeLoad block around line 152, after `SafeLoad("rpg.menus.menu_glitch", "Glitch Burst Menu")`, add:

```lua
SafeLoad("rpg.menus.menu_glitch", "Glitch Burst Menu")
SafeLoad("rpg.menus.menu_confirm", "Confirm Dialog")
SafeLoad("rpg.menus.menu_boot", "Boot Menu")
```

(We list both confirm and boot here even though boot is in the next task — they load together cleanly.)

- [ ] **Step 3: Smoke test**

User-action: reconnect and check server console for "Confirm Dialog" load line.

```
Expected: "RPG: Loaded Confirm Dialog" or equivalent debug print; no errors.
```

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/menus/menu_confirm.lua base/glua/rpg/init.lua
git commit -m "feat(rpg/menus): add reusable rpg_confirm two-choice modal"
```

---

## Task 8: Boot menu (`menu_boot.lua`)

**Files:**
- Create: `base/glua/rpg/menus/menu_boot.lua`

- [ ] **Step 1: Create `menu_boot.lua`**

```lua
-- Echoes of the Dark Wars - Boot Menu
-- Surfaced when !rpg is invoked and player has no active session.
-- Items: Continue (if save exists) / New Game / Cancel.

RPG = RPG or {}

local function FormatTimestamp(epochSeconds)
    if not epochSeconds or epochSeconds <= 0 then return "" end
    return os.date("%Y-%m-%d %H:%M", epochSeconds)
end

-- Read metadata fresh per onOpen; cache for the duration of this menu open.
local function GetCachedMetadata(player, state)
    state.data = state.data or {}
    if state.data.metadataFetched then
        return state.data.metadata
    end
    state.data.metadata = (RPG.Save and RPG.Save.GetMetadata) and RPG.Save.GetMetadata(player) or nil
    state.data.metadataFetched = true
    return state.data.metadata
end

Menu.Register("rpg_boot", {
    title = "^1=== ECHOES OF THE DARK WARS ===^7",

    header = function(player, state)
        local meta = GetCachedMetadata(player, state)
        local lines = {
            "",
            "^73949 BBY -- The Holocron still waits.",
            "",
        }
        if meta then
            local cls = RPG.Data.Classes and RPG.Data.Classes[meta.class]
            local className = cls and cls.name or meta.class
            lines[#lines + 1] = "^7Save found:"
            lines[#lines + 1] = "  ^3Level " .. meta.level .. " " .. className
            lines[#lines + 1] = "  ^3Room: ^7" .. meta.currentRoomName
            lines[#lines + 1] = "  ^8Saved: " .. FormatTimestamp(meta.savedAt)
        else
            lines[#lines + 1] = "^8No save found. Begin a new story."
        end
        lines[#lines + 1] = ""
        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local meta = GetCachedMetadata(player, state)
        local items = {}
        if meta then
            items[#items + 1] = { label = "^2>>> Continue", action = "continue" }
        end
        items[#items + 1] = { label = "^3New Game", action = "new_game" }
        items[#items + 1] = { label = "^7Cancel", action = "cancel" }
        return items
    end,

    onAction = function(player, action, state, selectedItem)
        if action == "continue" then
            if not RPG.Save or not RPG.Save.HasSave(player) then
                player:SendPrint("^1Save vanished.")
                RPG.Shutdown(player)
                return
            end
            local snapshot, err = RPG.Save.Read(player)
            if not snapshot then
                player:SendPrint("^1Load failed: " .. tostring(err))
                RPG.Shutdown(player)
                return
            end
            local game = RPG.Save.RestoreFromSnapshot(player, snapshot)
            if not game then
                player:SendPrint("^1Failed to restore save.")
                RPG.Shutdown(player)
                return
            end
            local roomName = game.rooms[game.player.currentRoom] and game.rooms[game.player.currentRoom].name or "unknown"
            player:SendPrint("^2Welcome back. ^7" .. roomName)
            local restoreState = game.state or "exploration"
            if not RPG.Config.STATE_MENUS[restoreState] then
                restoreState = "exploration"
            end
            RPG.SetState(player, restoreState)
            return
        end

        if action == "new_game" then
            local meta = GetCachedMetadata(player, state)
            if meta then
                -- Save exists: confirm before erasing
                RPG.SetState(player, "confirm", {
                    title = "^1=== ERASE SAVE? ===",
                    body  = "^3This will erase your current save and begin a new story.\n^7Are you sure?",
                    onConfirm = function(p)
                        if RPG.Save and RPG.Save.Delete then
                            RPG.Save.Delete(p)
                        end
                        -- Drop any cached session, then enter intro
                        RPG.Shutdown(p)
                        local cn = p:GetClientNum()
                        RPG.players[cn] = { state = "intro" }
                        if RPG.Save and RPG.Save.CacheKey then
                            RPG.Save.CacheKey(p, RPG.players[cn])
                        end
                        RPG.SetState(p, "intro")
                    end,
                    onCancel = function(p)
                        RPG.SetState(p, "boot")  -- Back to boot menu
                    end,
                })
                return
            end
            -- No existing save: straight to intro
            RPG.Shutdown(player)
            local cn = player:GetClientNum()
            RPG.players[cn] = { state = "intro" }
            if RPG.Save and RPG.Save.CacheKey then
                RPG.Save.CacheKey(player, RPG.players[cn])
            end
            RPG.SetState(player, "intro")
            return
        end

        if action == "cancel" then
            RPG.Shutdown(player)
            return
        end
    end,

    onOpen = function(player, state)
        state.data = state.data or {}
        state.data.metadataFetched = false  -- Force fresh metadata read on each open
    end,

    onBack = function(player, state)
        RPG.Shutdown(player)
        return true
    end,

    controls = "W/S: Navigate | USE: Select | ESC: Cancel",
    maxVisibleItems = 4,
})

return true
```

- [ ] **Step 2: Smoke test (Boot menu loads but isn't wired yet)**

User-action: reconnect, watch console for "Boot Menu" load line. Boot menu isn't surfaced via `!rpg` yet — that's Task 9. Just verify it loads without errors.

```
Expected: server console shows menu loaded; no Lua errors.
```

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/menus/menu_boot.lua
git commit -m "feat(rpg/menus): add rpg_boot menu (Continue / New Game / Cancel)"
```

---

## Task 9: Wire `!rpg` (no args) → boot menu + extend SetState allow-list

**Files:**
- Modify: `base/glua/rpg/state.lua:140-181` (SetState allow-list — boot + confirm)
- Modify: `base/glua/rpg/init.lua:260-302` (replace text prompt with boot menu open)

- [ ] **Step 1: Extend SetState bypass for no-game states**

In `state.lua:148-154`, modify the no-game allow-list to include `boot` and `confirm`:

```lua
    if not game then
        -- No game yet -- only allow boot/intro/dream/class_select/confirm
        if newState ~= "boot" and newState ~= "intro" and newState ~= "dream"
           and newState ~= "class_select" and newState ~= "confirm" then
            return
        end
    end
```

- [ ] **Step 2: Boot menu requires a session table to open. Adjust the "no game" path.**

Looking carefully: `SetState` accesses `game.state` and `game.previousState`. With `game == nil`, the second block (`if game then game.previousState = ... end`) safely skips. The menu Open call below proceeds. So `boot` works with `game == nil`.

But: `RPG.SetState(player, "confirm", data)` passes `data` as the third arg. The existing code path stores it as `menuData` (line 170) and passes through to `Menu.Open`/`SwapMenu`. **State.data inside the menu is populated by the menu framework from the menuData arg.** Verify by checking how existing menus consume `state.data` (already done — `menu_intro.lua` line 30-31 reads `state.data.page`). So the data plumbing works.

- [ ] **Step 3: Replace `!rpg` no-args text prompt with boot menu**

In `init.lua` around lines 268-302, replace the entire "else" branch of `if RPG.IsPlaying(player)` so it just opens the boot menu. Replace:

```lua
        else
            -- Check for existing save (single Read validates + decodes)
            if RPG.Save then
                local snapshot = RPG.Save.Read(player)
                if snapshot then
                    local hint = ""
                    if snapshot.player then
                        local cls = RPG.Data.Classes[snapshot.player.class]
                        local className = cls and cls.name or snapshot.player.class
                        hint = " (Level " .. (snapshot.player.level or "?") .. " " .. className .. ")"
                    end
                    player:SendPrint("^3Save found" .. hint .. ".")
                    player:SendPrint("^3Type ^7!rpg load^3 to continue or ^7!rpg new^3 for a fresh start.")
                    return ""
                end
            end

            -- No save — start at intro
            RPG.Util.BatchPrint(player, {
                "",
                "^7========================================",
                "^1  ECHOES OF THE DARK WARS",
                "^7  3949 BBY",
                "^7========================================",
                "",
            })

            -- Create a temporary state entry so SetState works
            local clientNum = player:GetClientNum()
            RPG.players[clientNum] = { state = "intro" }
            if RPG.Save and RPG.Save.CacheKey then
                RPG.Save.CacheKey(player, RPG.players[clientNum])
            end
            RPG.SetState(player, "intro")
        end
```

With:

```lua
        else
            -- Open boot menu. It surfaces Continue (if save) / New Game / Cancel.
            -- !rpg load and !rpg new chat commands remain as power-user shortcuts.
            RPG.SetState(player, "boot")
        end
```

- [ ] **Step 4: Smoke test on VPS (the big one)**

User-action:
1. Disconnect, reconnect. `!rpg`. **Expected:** Boot menu opens. With existing save, shows Continue (level/class/room/timestamp) + New Game + Cancel.
2. Select Continue. State restores. Back in exploration.
3. From exploration, type `!rpg`. **Expected:** since `RPG.IsPlaying` is true, reopens current menu (line 261-267 unchanged) — no boot menu shown.
4. Type `!rpg quit` (or use Quit RPG from exploration menu — not yet rewired in Task 11). Then `!rpg` again → boot menu → New Game → confirm dialog → confirm → erases save → intro plays.
5. After intro/dream/class select, `!rpg` while playing → reopens current. **Expected:** boot menu does NOT appear over the in-progress game.

```
Expected: !rpg always lands at boot when not playing; chat commands still work.
```

- [ ] **Step 5: Commit**

```bash
git add base/glua/rpg/state.lua base/glua/rpg/init.lua
git commit -m "feat(rpg): wire !rpg → boot menu; extend SetState allow-list with boot/confirm"
```

---

## Task 10: In-game Save / Load / Quit-to-Boot in exploration menu

**Files:**
- Modify: `base/glua/rpg/menus/menu_exploration.lua:379-386` (menu category items)
- Modify: `base/glua/rpg/menus/menu_exploration.lua:531-556` (action handlers)

- [ ] **Step 1: Add menu items**

In `menu_exploration.lua` around lines 380-385, replace the `expanded == "menu"` items block:

```lua
        -- Expanded: Menu
        elseif expanded == "menu" then
            items[#items + 1] = { label = "^7Character Sheet", action = "charsheet" }
            items[#items + 1] = { label = "^7Inventory", action = "inventory" }
            items[#items + 1] = { label = "^7Quest Log", action = "questlog" }
            items[#items + 1] = { label = "^7Read Description", action = "read_desc" }
            items[#items + 1] = { label = "^2Save Game", action = "save_game" }
            if RPG.Save and RPG.Save.HasSave(player) then
                items[#items + 1] = { label = "^3Load Last Save", action = "load_game" }
            end
            items[#items + 1] = { label = "^1Quit to Boot Menu", action = "quit_to_boot" }
        end
```

- [ ] **Step 2: Add action handlers**

In the same file's `onAction` switch (around lines 533-556), replace the existing Character Sheet / Inventory / Quest Log / Quit block with this extended version:

```lua
        -- Character sheet submenu
        if action == "charsheet" then
            RPG.SetState(player, "character_sheet")
            return
        end

        -- Inventory submenu
        if action == "inventory" then
            RPG.SetState(player, "inventory")
            return
        end

        -- Quest log submenu
        if action == "questlog" then
            RPG.SetState(player, "quest_log")
            return
        end

        -- Manual save
        if action == "save_game" then
            if not RPG.Save then
                player:SendPrint("^1Save system not loaded.")
                return
            end
            local ok, err = RPG.Save.Write(player)
            if ok then
                player:SendPrint("^2Game saved (" .. os.date("%H:%M") .. ")")
            else
                player:SendPrint("^1Save failed: " .. tostring(err))
            end
            return
        end

        -- Manual load (with confirm)
        if action == "load_game" then
            if not RPG.Save or not RPG.Save.HasSave(player) then
                player:SendPrint("^3No save found.")
                return
            end
            RPG.SetState(player, "confirm", {
                title = "^3=== LOAD SAVE? ===",
                body  = "^3This will discard your current session and load the last save.",
                onConfirm = function(p)
                    local snapshot, err = RPG.Save.Read(p)
                    if not snapshot then
                        p:SendPrint("^1Load failed: " .. tostring(err))
                        RPG.SetState(p, "exploration")
                        return
                    end
                    local g = RPG.Save.RestoreFromSnapshot(p, snapshot)
                    if g then
                        local roomName = g.rooms[g.player.currentRoom] and g.rooms[g.player.currentRoom].name or "?"
                        p:SendPrint("^2Save loaded! ^7Back in " .. roomName)
                        local restoreState = g.state or "exploration"
                        if not RPG.Config.STATE_MENUS[restoreState] then
                            restoreState = "exploration"
                        end
                        RPG.SetState(p, restoreState)
                    else
                        p:SendPrint("^1Failed to restore save.")
                        RPG.SetState(p, "exploration")
                    end
                end,
                onCancel = function(p)
                    RPG.SetState(p, "exploration")
                end,
            })
            return
        end

        -- Quit to Boot Menu (replaces old Quit RPG)
        if action == "quit_to_boot" then
            -- Autosave first so Quit-to-Boot can't lose unsaved progress
            if RPG.Save and RPG.Save.Write then
                RPG.Save.Write(player)
            end
            RPG.Shutdown(player)
            RPG.SetState(player, "boot")
            return
        end

        -- Legacy Quit action (kept for compat if any other path triggers it)
        if action == "quit" then
            player:SendPrint("^3RPG session ended. Type ^7!rpg^3 to play again.")
            RPG.Shutdown(player)
            return
        end
```

- [ ] **Step 3: Smoke test on VPS**

User-action:
1. In exploration, open Menu category. **Expected:** see Save Game, Load Last Save (if save exists), Quit to Boot.
2. Save Game → "^2Game saved (HH:MM)".
3. Move 3 rooms. Load Last Save → confirm → Confirm → land back in original room.
4. Quit to Boot Menu → boot menu opens; Continue button shows the autosaved state from step 3 load.

```
Expected: all four UX flows behave as described.
```

- [ ] **Step 4: Commit**

```bash
git add base/glua/rpg/menus/menu_exploration.lua
git commit -m "feat(rpg/menus): in-game Save Game / Load Last Save / Quit to Boot in exploration"
```

---

## Task 11: `!rpgdebug save_status` diagnostic command

**Files:**
- Modify: `base/glua/rpg/init.lua` (inside the existing `!rpgdebug` subcommand switch, around line 380+)

- [ ] **Step 1: Add the subcommand**

Inside the `!rpgdebug` handler, after the existing `!rpgdebug` usage help block but BEFORE the `requireSession` helper (so it can run without a session — useful when the save exists but no session is loaded), add a new branch. Find a clean spot in the subcommand chain (e.g., after `quickstart` handling around line 405):

```lua
        -- save_status — diagnose save/load state
        if sub == "save_status" then
            local game = RPG.GetGame(player)
            local key = RPG.Save and RPG.Save.GetPlayerKey and RPG.Save.GetPlayerKey(player) or nil
            player:SendPrint("^3=== Save Status ===")
            player:SendPrint("^7Cached saveKey: ^3" .. tostring(game and game.saveKey or "(no session)"))
            player:SendPrint("^7Computed key:   ^3" .. tostring(key or "(no key)"))
            if key then
                local path = "glua/data/rpg_saves/" .. key .. ".json"
                local exists = File and File.Exists and File.Exists(path)
                player:SendPrint("^7Save file path: ^7" .. path)
                player:SendPrint("^7File.Exists:    ^3" .. tostring(exists))
            end
            if game and game.lastSaveAt then
                local age = (os.time() * 1000) - game.lastSaveAt
                player:SendPrint("^7Last save:      ^3" .. math.floor(age / 1000) .. "s ago")
                local cooldown = RPG.Config.AUTOSAVE_COOLDOWN_MS
                player:SendPrint("^7Cooldown gate:  ^3" .. (age < cooldown and "ACTIVE" or "open"))
            end
            local meta = RPG.Save and RPG.Save.GetMetadata and RPG.Save.GetMetadata(player) or nil
            if meta then
                local cls = RPG.Data.Classes and RPG.Data.Classes[meta.class]
                player:SendPrint("^7Snapshot meta:  ^3Level " .. meta.level .. " " ..
                    ((cls and cls.name) or meta.class) ..
                    " in " .. meta.currentRoomName ..
                    " (saved " .. os.date("%Y-%m-%d %H:%M", meta.savedAt) .. ")")
            else
                player:SendPrint("^7Snapshot meta:  ^8(none)")
            end
            return ""
        end
```

Also add `^7!rpgdebug save_status` to the usage help block printed when `sub` is nil.

- [ ] **Step 2: Smoke test on VPS**

User-action: `!rpgdebug save_status`. Output should show cached key, computed key, file path, exists flag, last save age, cooldown gate, and snapshot metadata if save exists.

```
Expected:
=== Save Status ===
Cached saveKey: acct_1234
Computed key:   acct_1234
Save file path: glua/data/rpg_saves/acct_1234.json
File.Exists:    true
Last save:      45s ago
Cooldown gate:  open
Snapshot meta:  Level 3 Guardian in Crystal Caves (saved 2026-05-12 14:33)
```

- [ ] **Step 3: Commit**

```bash
git add base/glua/rpg/init.lua
git commit -m "feat(rpg/debug): add !rpgdebug save_status diagnostic"
```

---

## Task 12: Acceptance gate — 5 manual tests per spec §12.5

This is the SHIP/NO-SHIP gate. All five must pass on the VPS before Phase 0 is considered done.

- [ ] **Step 1: Deploy current branch to VPS**

```bash
git push origin builder-shader-scanner-audit
ssh ubuntu@158.69.218.235 "cd ~/OpenJK-Custom && git fetch && git checkout builder-shader-scanner-audit && git pull"
ssh ubuntu@158.69.218.235 "~/restart_custom_server.sh"   # full deploy, NOT -n
```

Watch for:
```
Expected: server console shows "Echoes of the Dark Wars v..." banner, "Save System" + "Confirm Dialog" + "Boot Menu" load lines, no errors.
```

- [ ] **Step 2: Test #1 — Graceful disconnect → reconnect → save loads**

In-game:
1. Connect, log into account.
2. `!rpg` → boot menu (or New Game if first run).
3. Play through intro → dream → class select → exploration. Move 5 rooms.
4. `/disconnect`. Reconnect. `!rpg`. **Expected:** boot menu shows Continue (with correct class/level/room). Continue → state restored.

```
Pass criteria: continue restores to same room with same inventory/quests.
```

- [ ] **Step 3: Test #2 — Quest complete → kill server → restart → save loads with quest complete**

In-game:
1. Continue or start fresh.
2. `!rpgdebug quest complete echoes` (or any quest you have access to).
3. SSH: `ssh ubuntu@158.69.218.235 'pkill -9 openjkded'` (hard kill, no graceful shutdown).
4. SSH: `~/restart_custom_server.sh -n` (servers only, since Lua changes already deployed). Wait for server to come up.
5. Reconnect. `!rpg` → Continue. Open Quest Log. **Expected:** completed quest shows as completed.

```
Pass criteria: the quest completed before SIGKILL is still completed after server restart.
```

- [ ] **Step 4: Test #3 — 90s play → kill server → ≤90s loss**

In-game:
1. Continue or start fresh, get into exploration.
2. **Note** current room/state. Walk 1 room (forces a checkpoint candidate, but no checkpoint actually fires for room move). Sit ~95 seconds in exploration.
3. SSH: `ssh ubuntu@158.69.218.235 'pkill -9 openjkded'`.
4. Restart server, reconnect, `!rpg` → Continue. **Expected:** at most one autosave-window behind the kill point. Periodic timer fired, so state should be intact.

```
Pass criteria: ≤90s of progress lost (typically 0–30s in practice since most recent autosave was <90s before kill).
```

- [ ] **Step 5: Test #4 — Boot New Game w/ confirm erases save**

In-game:
1. Ensure save exists. `!rpg` → boot menu shows Continue + New Game + Cancel.
2. Select **New Game**. Confirm dialog: "This will erase your current save." Select **Confirm**.
3. Intro plays.
4. Immediately `/disconnect` (don't finish intro/class select — so no new game state is saved).
5. Reconnect. `!rpg` → boot menu. **Expected:** Continue option is NOT shown; only New Game + Cancel.

```
Pass criteria: Delete cleared the save; boot menu has no Continue option.
```

- [ ] **Step 6: Test #5 — In-game Save → in-game Load → state intact**

In-game:
1. From exploration, open Menu category. Select **Save Game**. Confirmation print appears.
2. Move 5 rooms in any direction.
3. Open Menu category. Select **Load Last Save**. Confirm dialog. Select **Confirm**.
4. **Expected:** state restores to the room from step 1 with the inventory/quest state from step 1.

```
Pass criteria: in-game save/load round-trip preserves state exactly.
```

- [ ] **Step 7: Final commit + close out Phase 0**

If all five pass, commit a CHANGELOG bump or final wrap-up note. If any fail, fix the specific gap and re-run only the failing test.

```bash
git commit --allow-empty -m "chore(rpg): Phase 0 acceptance gate passed (5/5)"
git push origin builder-shader-scanner-audit
```

---

## Notes for the executor

- **Lua GC pressure** (project memory): `Save.Write` builds a snapshot table that triggers DeepCopy across `quests`, `flags`, `visitedRooms`, etc. If profiling shows it hot, wrap snapshot build with `collectgarbage("stop") ... collectgarbage("restart")` per the established pattern. Don't pre-optimize — only act on measurement.
- **Cooldown is DoS-defense + chain-fire defuse, not perf** (project memory): even if checkpoints fire 5× per second briefly, the 10s gate absorbs it. Don't ratchet the cooldown up to "improve perf" — that breaks the "Quest Complete locks in" guarantee.
- **Don't add a "max saves per minute" cap** — same memory: rate limits are bandaids. The structural fix is the cooldown gate.
- **Don't mock the save system in any future test** (project memory): integration tests run against the real File API. The plan above already does this — all verification is in-game on the VPS.
- **GUID migration** is already in `Save.Read` (lines 332-340). If a player has an old guid-keyed save and a new account ID, `Read` migrates on first successful decode. The new `Save.Delete` removes BOTH so confirmed New Game doesn't leave a ghost guid file that could resurrect.
- **`config.lua` STATE_MENUS additions** must land before the menu files that depend on them (Task 1 before Tasks 7-8). The plan order respects this.

## Out of scope (re-stating from spec §12.8 for executor clarity)

Don't add: multiple save slots, cloud sync, save export/import, mid-combat save, save in dialogue/cipher_input/ending. These are explicitly YAGNI'd in the spec.
