-- Echoes of the Dark Wars - Character Sheet Menu
-- Displays stats, alignment, level as a proper submenu

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

Menu.Register("rpg_character", {
    title = "^3=== CHARACTER SHEET ===^7",

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "^1No active game." end

        local p = game.player
        local cls = RPG.Data.Classes[p.class]
        local lines = {}
        local cw = RPG.Config.HEALTH_BAR_COMPACT

        -- Class + Level + XP combined
        local className = cls and cls.color .. cls.name .. "^7" or p.class
        lines[#lines + 1] = "^7" .. className .. "  Lv" .. p.level .. "  XP:" .. p.xp .. "/" .. p.xpToNext

        -- HP + FP combined on one line. Phase 1 (#1): Severed Truth-ending players
        -- render "FP [ SEVERED ]" in grey instead of the normal bar.
        local hpfp = "^2HP " .. RPG.Util.HealthBar(p.hp, p.maxHP, cw)
        if p.forceSevered then
            hpfp = hpfp .. " ^8FP [ SEVERED ]"
        elseif p.maxFP > 0 then
            hpfp = hpfp .. " ^5FP " .. RPG.Util.HealthBar(p.fp, p.maxFP, cw)
        end
        lines[#lines + 1] = hpfp

        lines[#lines + 1] = ""

        -- Credits + Alignment combined
        lines[#lines + 1] = "^7Credits: " .. p.credits .. "  " .. RPG.Util.AlignmentText(p.alignment)

        lines[#lines + 1] = ""

        -- Stats in 2 columns (3 rows of 2)
        local statLine1 = ""
        local statLine2 = ""
        local count = 0
        for _, statName in ipairs(RPG.Data.StatOrder) do
            count = count + 1
            local val = p.stats[statName]
            local mod = RPG.Util.StatMod(val)
            local sign = mod >= 0 and "+" or ""
            local entry = statName .. ":" .. val .. "(" .. sign .. mod .. ")"
            if count <= 3 then
                statLine1 = statLine1 .. entry .. "  "
            else
                statLine2 = statLine2 .. entry .. "  "
            end
        end
        lines[#lines + 1] = "^7" .. statLine1
        lines[#lines + 1] = "^7" .. statLine2

        -- Pending stat points indicator
        local pts = p.pendingStatPoints or 0
        if pts > 0 then
            lines[#lines + 1] = "^3(" .. pts .. " stat point" .. (pts > 1 and "s" or "") .. " available to allocate)"
        end

        -- Known Abilities section
        if p.abilitiesKnown and RPG.Data.Abilities then
            local forceList = {}
            local abilityList = {}

            -- Use ordered lists for deterministic display
            local classId = p.class
            local forceOrder = RPG.Data.AbilityOrder and RPG.Data.AbilityOrder.force or {}
            local classOrder = RPG.Data.AbilityOrder and RPG.Data.AbilityOrder[classId] or {}

            for _, abilityId in ipairs(forceOrder) do
                if p.abilitiesKnown[abilityId] then
                    local def = RPG.Data.Abilities[abilityId]
                    if def and def.type == "force" then
                        local tag = RPG.Data.GetAbilityDisplayTag(def)
                        forceList[#forceList + 1] = tag .. " " .. def.name .. " ^8(" .. (def.fp or 0) .. " FP)"
                    end
                end
            end

            for _, abilityId in ipairs(classOrder) do
                if p.abilitiesKnown[abilityId] then
                    local def = RPG.Data.Abilities[abilityId]
                    if def and def.type == "ability" then
                        local tag = RPG.Data.GetAbilityDisplayTag(def)
                        abilityList[#abilityList + 1] = tag .. " " .. def.name
                    end
                end
            end

            -- Also show passive abilities with descriptions
            for abilityId, _ in pairs(p.abilitiesKnown) do
                local def = RPG.Data.Abilities[abilityId]
                if def and def.type == "passive" then
                    local tag = RPG.Data.GetAbilityDisplayTag(def)
                    local desc = def.description and (" ^8- " .. def.description) or ""
                    forceList[#forceList + 1] = tag .. " " .. def.name .. desc
                end
            end

            if #forceList > 0 then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "^5Force Powers:^7"
                local fMax = math.min(#forceList, 4)
                for i = 1, fMax do
                    lines[#lines + 1] = "  " .. ClampLine(forceList[i], RPG.Config.LINE_CLAMP_WIDTH)
                end
                if #forceList > 4 then
                    lines[#lines + 1] = "  ^8...and " .. (#forceList - 4) .. " more"
                end
            end

            if #abilityList > 0 then
                lines[#lines + 1] = ""
                lines[#lines + 1] = "^3Abilities:^7"
                local aMax = math.min(#abilityList, 4)
                for i = 1, aMax do
                    lines[#lines + 1] = "  " .. ClampLine(abilityList[i], RPG.Config.LINE_CLAMP_WIDTH)
                end
                if #abilityList > 4 then
                    lines[#lines + 1] = "  ^8...and " .. (#abilityList - 4) .. " more"
                end
            end
        end

        return table.concat(lines, "\n")
    end,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        local items = {}

        if game then
            local pts = game.player.pendingStatPoints or 0
            if pts > 0 then
                items[#items + 1] = {
                    label = "^3Allocate Stat Points (" .. pts .. " available)",
                    action = "allocate_stats",
                }
            end
        end

        items[#items + 1] = { label = "^3<<< Back to Exploration", action = "back" }
        return items
    end,

    onAction = function(player, action, state, selectedItem)
        if action == "allocate_stats" then
            RPG.SetState(player, "stat_allocation", { returnState = "character_sheet" })
            return true
        end
        if action == "back" then
            RPG.SetState(player, "exploration")
            return true
        end
        return false
    end,

    onBack = function(player, state)
        RPG.SetState(player, "exploration")
        return true
    end,

    controls = "USE: Select | ALT: Back",
    maxVisibleItems = 4,
})

return true
