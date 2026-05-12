-- Echoes of the Dark Wars - Intro Crawl Menu
-- 3 pages, USE advances through each page
-- No tabs -- simple linear flow

RPG = RPG or {}

-- Static per-page precompute. rpg.narrative loads before this menu
-- (see rpg.init.lua), so RPG.IntroCrawl is populated by now.
-- Header/items/controls vary only by page (1..3), so we build the
-- strings + item tables once at module load and serve cached references
-- on every render. This drops hdr/items/controls userland cost from
-- ~10ms to a single table lookup.
local INTRO_CACHE = {}
for page = 1, 3 do
    local lines = (RPG.IntroCrawl and RPG.IntroCrawl[page]) or {}
    INTRO_CACHE[page] = {
        header   = table.concat(lines, "\n"),
        items    = {
            { label = (page < 3) and "^3>>> CONTINUE >>>" or "^3>>> BEGIN YOUR STORY <<<",
              action = "advance" },
        },
        controls = "^8Page " .. page .. "/3 ^7| W/S: Navigate | USE: Continue",
    }
end

Menu.Register("rpg_intro", {
    title = "^1=== ECHOES OF THE DARK WARS ===^7",

    header = function(player, state)
        local page = (state.data and state.data.page) or 1
        return INTRO_CACHE[page].header
    end,

    getItems = function(player, state)
        local page = (state.data and state.data.page) or 1
        return INTRO_CACHE[page].items
    end,

    onAction = function(player, action, state, selectedItem)
        if action == "advance" then
            local page = (state.data and state.data.page) or 1
            if page < 3 then
                state.data.page = page + 1
                Menu.InvalidateCache(player)
            else
                -- Page 3 -> dream menu
                RPG.SetState(player, "dream")
            end
        end
    end,

    onOpen = function(player, state)
        state.data.page = 1
    end,

    controls = function(player, state)
        local page = (state.data and state.data.page) or 1
        return INTRO_CACHE[page].controls
    end,
    maxVisibleItems = 4,
})

return true
