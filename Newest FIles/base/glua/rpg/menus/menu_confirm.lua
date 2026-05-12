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
