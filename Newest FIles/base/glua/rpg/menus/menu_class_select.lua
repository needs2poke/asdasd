-- Echoes of the Dark Wars - Class Selection Menu
-- 6 classes with stat preview in header

RPG = RPG or {}

-- Module-local cache: classId -> precomputed preview string.
-- Class data is static config, so the preview is deterministic per class.
-- Building once at module load drops renderPreview from ~30ms to O(1) lookup.
local CLASS_PREVIEWS = {}

local function BuildClassPreview(cls)
    if not cls then return "" end

    local lines = {}
    lines[#lines + 1] = cls.color .. cls.name .. "^7"
    lines[#lines + 1] = "^7" .. cls.description

    -- Stats in two columns
    local statLine1 = ""
    local statLine2 = ""
    local count = 0
    for _, statName in ipairs(RPG.Data.StatOrder) do
        count = count + 1
        local val = cls.stats[statName]
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

    -- HP/FP
    local hpfp = "^2HP:" .. cls.hp
    if cls.fp > 0 then
        hpfp = hpfp .. "  ^5FP:" .. cls.fp
        if cls.latentForce then
            hpfp = hpfp .. " ^8(Latent)"
        end
    end
    lines[#lines + 1] = hpfp

    return table.concat(lines, "\n")
end

-- Precompute previews for all classes at module load.
-- Load order ensures rpg.data.classes is populated before this menu module runs.
for _, classId in ipairs(RPG.Data.ClassOrder) do
    CLASS_PREVIEWS[classId] = BuildClassPreview(RPG.Data.Classes[classId])
end

Menu.Register("rpg_class_select", {
    navigationDebounce = true,       -- leading+trailing edge debounce to reduce CP sends
    navigationCacheHeader = true,    -- static header cacheable; renderPreview handles selection

    title = "^3=== CHOOSE YOUR PATH ===^7",

    getItems = function(player, state)
        local items = {}
        for _, classId in ipairs(RPG.Data.ClassOrder) do
            local cls = RPG.Data.Classes[classId]
            items[#items + 1] = {
                label = cls.color .. cls.name .. "^7",
                action = "select_class:" .. classId,
                classId = classId,
                preview = CLASS_PREVIEWS[classId],
            }
        end
        return items
    end,

    header = function(player, state)
        -- Static header: "Choose your class:" (cached by framework)
        return "^3Choose your class:"
    end,

    renderPreview = function(player, state)
        local items = state and state.cachedItems
        local sel = state and state.selection or 1
        local item = items and items[sel]
        return item and item.preview or ""
    end,

    onAction = function(player, action, state, selectedItem)
        -- Parse "select_class:guardian" etc
        if string.StartsWith(action, "select_class:") then
            local classId = action:sub(#"select_class:" + 1)
            local cls = RPG.Data.Classes[classId]
            if not cls then return end

            -- Create new game with this class
            local game = RPG.NewGame(player, classId)
            if not game then
                player:SendPrint("^1Error creating game. Try again.")
                return
            end

            -- Class pick already prints narrative text; suppress one auto room narration
            -- on first exploration open to avoid a same-frame print burst.
            game.ui = game.ui or {}
            game.ui.skipAutoNarrationOnce = true

            -- Narrate class selection
            local narration = {
                "",
                "^7========================================",
                "^7You walk the path of " .. cls.color .. cls.name .. "^7.",
                "^7========================================",
                "",
            }
            -- Class-specific narration
            local classNarration = {
                guardian = {
                    "^7Your Force sensitivity is a secret you guard carefully.",
                    "^7The wars are over, but the galaxy remembers who started them. All of them.",
                },
                consular = {
                    "^7You felt the Force in everything, once. Now you keep that door shut.",
                    "^7The Jedi are blamed for every war in living memory. Silence is survival.",
                },
                sentinel = {
                    "^7The shadows taught you to hide what you are. Even from yourself.",
                    "^7Good. The Exchange pays well for Force-sensitives, dead or alive.",
                },
                scoundrel = {
                    "^7You always had luck. Too much luck. You never asked why.",
                    "^7Better that way. People who ask questions about the Force attract the wrong attention.",
                },
                soldier = {
                    "^7Your squad died at Malachor. You survived on instinct.",
                    "^7You never questioned what that instinct really was. Neither did anyone else, and you'd like to keep it that way.",
                },
                hunter = {
                    "^7Your tracking was legendary. No prey escaped.",
                    "^7You told yourself it was skill. It wasn't. Not entirely. But nobody needs to know that.",
                },
            }
            local lines2 = classNarration[classId]
            if lines2 then
                for _, l in ipairs(lines2) do
                    narration[#narration + 1] = l
                end
            end
            narration[#narration + 1] = ""
            narration[#narration + 1] = "^3You wake in your quarters. An explosion echoes outside..."
            narration[#narration + 1] = ""
            -- Defer class narration to next frame (avoid burst with centerprint)
            local clientNum = player:GetClientNum()
            local timerName = "rpg_class_narrate_" .. clientNum
            Timer.Remove(timerName)
            Timer.Create(timerName, 200, 1, function()
                local p = Player.Get(clientNum)
                if not p or not p:IsValid() then return end
                local g = RPG.GetGame(p)
                if not g then return end
                RPG.Util.BatchPrint(p, narration)
                -- Class narration covers room 0; mark it so onOpen won't re-narrate
                g.ui = g.ui or {}
                g.ui.lastNarratedRoom = g.player.currentRoom
            end)
            -- Swap immediately to exploration (SwapMenu sends only centerprint)
            RPG.SetState(player, "exploration")
        end
    end,

    controls = "W/S: Browse | USE: Select Class",
    maxVisibleItems = 8,
})

return true
