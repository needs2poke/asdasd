-- Echoes of the Dark Wars - Boot Menu
-- Surfaced when !rpg is invoked and player has no active session.
-- Items: Continue (if save exists) / New Game / Cancel.

RPG = RPG or {}

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
