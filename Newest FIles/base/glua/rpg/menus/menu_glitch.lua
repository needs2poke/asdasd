-- Echoes of the Dark Wars - Glitch Burst Menu
-- Visual corruption / fake reboot display

RPG = RPG or {}

Menu.Register("rpg_glitch_burst", {
    allowAttackClose = false,
    title = function(player, state)
        local game = RPG.GetGame(player)
        if game and game.glitchBurst and game.glitchBurst.isFakeReboot then
            return "^1[SYSTEM]^7"
        end
        return "^1[FORCE ECHO CORRUPTION]^7"
    end,
    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.glitchBurst then return "^1..." end
        return game.glitchBurst.glitchText or "^1..."
    end,
    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if game and game.glitchBurst and game.glitchBurst.isFakeReboot then
            return {{ label = "^8[PLEASE WAIT]", action = "none" }}
        end
        local pct = 0
        if game and game.glitchBurst then
            pct = math.floor((game.glitchBurst.frame / game.glitchBurst.totalFrames) * 100)
        end
        return {{ label = "^1[CORRUPTION: " .. pct .. "%]", action = "none" }}
    end,
    onSelect = function(player, state, item)
        -- No interaction during glitch
        return true
    end,
    onBack = function()
        return true  -- prevent closing during glitch
    end,
    controls = "",
    maxVisibleItems = 1,
})

GLua.Print("RPG: Glitch burst menu loaded")
return true
