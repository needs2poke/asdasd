-- Echoes of the Dark Wars - Combat Menu
-- Centerprint menu for the RPG combat loop

RPG = RPG or {}

local function ClampLine(s, maxVisible)
    if not s then return s end
    -- Quick check: if raw length is short, visible is shorter too
    if #s <= maxVisible then return s end
    -- Count visible chars (skip ^X color codes)
    local vis = 0
    local i = 1
    while i <= #s do
        if s:sub(i, i) == "^" and i + 1 <= #s then
            i = i + 2  -- skip color code
        else
            vis = vis + 1
            i = i + 1
        end
    end
    if vis <= maxVisible then return s end
    -- Truncate at maxVisible - 3 visible chars, then add "..."
    vis = 0
    i = 1
    while i <= #s do
        if s:sub(i, i) == "^" and i + 1 <= #s then
            i = i + 2
        else
            vis = vis + 1
            if vis >= maxVisible - 3 then
                local cut = s:sub(1, i)
                if cut:sub(-1) == "^" then cut = cut:sub(1, -2) end
                return cut .. "..."
            end
            i = i + 1
        end
    end
    return s
end

local function CurrentPhase(game)
    if not game or not game.combat then
        return "main"
    end
    return game.combat.phase or "main"
end

local function RefreshCombatMenu(player, forceImmediate)
    if not Menu then return end
    if Menu.InvalidateCache then
        Menu.InvalidateCache(player)
    end
    if Menu.Render then
        Menu.Render(player, forceImmediate)
    end
end

Menu.Register("rpg_combat", {
    allowAttackClose = false,

    title = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.combat or not game.combat.active then
            return "^1=== COMBAT ENDED ===^7"
        end
        return "^1=== COMBAT: " .. game.combat.enemy.name .. " ===^7"
    end,

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.combat or not game.combat.active then
            return "^8No active combat."
        end

        local p = game.player
        local c = game.combat
        local e = c.enemy
        local lines = {}
        local cw = RPG.Config.HEALTH_BAR_COMPACT

        -- HP + FP combined on one line
        local hpfp = "^2HP " .. RPG.Util.HealthBar(p.hp, p.maxHP, cw)
        if p.maxFP and p.maxFP > 0 then
            hpfp = hpfp .. " ^5FP " .. RPG.Util.HealthBar(p.fp, p.maxFP, cw)
        end
        lines[#lines + 1] = hpfp

        -- Companion HP
        if RPG.Companion and RPG.Companion.GetHPLine then
            local compLine = RPG.Companion.GetHPLine(game)
            if compLine then lines[#lines + 1] = compLine end
        end

        -- Enemy HP + Round combined
        lines[#lines + 1] = "^1" .. e.name .. " " .. RPG.Util.HealthBar(e.hp, e.maxHP, cw) .. " ^8R" .. c.round

        -- Survival round indicator
        if c.survivalTurns then
            lines[#lines + 1] = "^1SURVIVE^7 — Round " .. c.round .. "/" .. c.survivalTurns
        end

        if c.enemyIntentText then
            local wrappedIntent = RPG.Util.WrapText(c.enemyIntentText, RPG.Config.COMBAT_WRAP_WIDTH)
            for wline in wrappedIntent:gmatch("[^\n]+") do
                lines[#lines + 1] = wline
            end
        end

        -- Last log entries — budget guard: if header already tall, show only 1
        if c.resultLog and #c.resultLog > 0 then
            local maxLog = (#lines > 6) and 1 or 2
            local startIdx = math.max(1, #c.resultLog - maxLog + 1)
            for i = startIdx, #c.resultLog do
                local wrapped = RPG.Util.WrapText(c.resultLog[i], RPG.Config.COMBAT_WRAP_WIDTH)
                for wline in wrapped:gmatch("[^\n]+") do
                    -- Flash effect on last log entry (per wrapped line)
                    if i == #c.resultLog and c.flashType and c.flashTick then
                        local odd = (c.flashTick % 2) == 1
                        if c.flashType == "enemy_hit" then
                            wline = (odd and "^1" or "^7") .. RPG.Util.StripColors(wline) .. "^7"
                        elseif c.flashType == "player_miss" then
                            wline = (odd and "^3" or "^8") .. RPG.Util.StripColors(wline) .. "^7"
                        elseif c.flashType == "player_crit" then
                            wline = (odd and "^2" or "^3") .. RPG.Util.StripColors(wline) .. "^7"
                        elseif c.flashType == "enemy_heal" then
                            wline = (odd and "^5" or "^2") .. RPG.Util.StripColors(wline) .. "^7"
                        end
                    end
                    lines[#lines + 1] = wline
                end
            end
        end

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.combat or not game.combat.active then
            return {
                { label = "^8Combat has ended.", action = "none" },
                { label = "^3Return to Exploration", action = "force_leave" },
            }
        end

        local phase = CurrentPhase(game)
        if phase == "force" then
            return RPG.Combat.GetForcePowerItems(game)
        elseif phase == "item" then
            return RPG.Combat.GetCombatItemItems(game)
        elseif phase == "ability" then
            return RPG.Combat.GetClassAbilityItems(game)
        end

        return RPG.Combat.GetAvailableActions(game)
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then
            return
        end

        if action == "force_leave" then
            RPG.SetState(player, "exploration")
            return
        end

        if not game.combat or not game.combat.active then
            return
        end

        if action == "open_force" then
            game.combat.phase = "force"
            state.selection = 1
            RefreshCombatMenu(player, true)
            return
        end

        if action == "open_items" then
            game.combat.phase = "item"
            state.selection = 1
            RefreshCombatMenu(player, true)
            return
        end

        if action == "open_abilities" then
            game.combat.phase = "ability"
            state.selection = 1
            RefreshCombatMenu(player, true)
            return
        end

        if action == "back_main" then
            game.combat.phase = "main"
            state.selection = 1
            RefreshCombatMenu(player, true)
            return
        end

        if action == "none" then
            return
        end

        local resolved = RPG.Combat.ResolveTurn(player, action)
        if not resolved then
            RefreshCombatMenu(player, true)
            return
        end

        local postGame = RPG.GetGame(player)
        if postGame and postGame.combat and postGame.combat.active and postGame.state == "combat" then
            RefreshCombatMenu(player, true)
        end
    end,

    onBack = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.combat or not game.combat.active then
            return false
        end

        if CurrentPhase(game) ~= "main" then
            game.combat.phase = "main"
            state.selection = 1
            RefreshCombatMenu(player, true)
            return true
        end

        -- Block ALT escape from top-level combat actions.
        return true
    end,

    controls = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.combat or not game.combat.active then
            return "^3W/S^7=Nav ^3USE^7=Select ^3ATK^7=Close"
        end

        if CurrentPhase(game) ~= "main" then
            return "^3W/S^7=Nav ^3USE^7=Select ^3ALT^7=Back"
        end

        return "^3W/S^7=Nav ^3USE^7=Select ^1ATK/ALT disabled in combat"
    end,

    maxVisibleItems = 7,
})

return true
