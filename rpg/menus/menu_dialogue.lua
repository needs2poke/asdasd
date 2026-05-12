-- Echoes of the Dark Wars - Dialogue Menu
-- Centerprint-based branching dialogue with pagination, stat checks, Doubt

RPG = RPG or {}

--- Helper: resolve dynamic node fields (function → table, string → {string})
local function resolveNodeField(field, game, fallback)
    if type(field) == "function" then
        local ok, result = pcall(field, game)
        if not ok then return fallback end
        field = result
    end
    if type(field) == "string" then return { field } end
    if type(field) ~= "table" then return fallback end
    return field
end

--- Helper: build wrapped preview string for a truncated dialogue response.
--- Pure on input string + RPG.Config.DIALOGUE_WRAP_WIDTH, so memoize by
--- (width, fullLabel) — same input always yields same output.
--- Called lazily from renderPreview for the selected item only; on cold
--- entry only the selected response wraps (was: all visible responses).
local _wrapPreviewCache = {}

local function BuildWrappedPreview(fullLabel)
    if not fullLabel then return nil end
    local wrapWidth = RPG.Config.DIALOGUE_WRAP_WIDTH
    local cacheKey = tostring(wrapWidth) .. "\0" .. fullLabel
    local cached = _wrapPreviewCache[cacheKey]
    if cached then return cached end

    local previewLines = { "" }
    local fullText = fullLabel
    local stripped = RPG.Util.StripColors(fullText)
    if #stripped > wrapWidth then
        local wrapped = {}
        local current, currentLen = "", 0
        for word in fullText:gmatch("%S+") do
            local wordLen = #RPG.Util.StripColors(word)
            if currentLen + wordLen + 1 > wrapWidth and currentLen > 0 then
                wrapped[#wrapped + 1] = current
                current = word
                currentLen = wordLen
            else
                current = currentLen > 0 and (current .. " " .. word) or word
                currentLen = currentLen + (currentLen > 0 and 1 or 0) + wordLen
            end
        end
        if currentLen > 0 then wrapped[#wrapped + 1] = current end
        local maxPreview = 2
        for pi, wline in ipairs(wrapped) do
            if pi > maxPreview then break end
            if pi == maxPreview and #wrapped > maxPreview then
                previewLines[#previewLines + 1] = "^8" .. wline .. "..."
            else
                previewLines[#previewLines + 1] = "^8" .. wline
            end
        end
    else
        previewLines[#previewLines + 1] = "^8" .. fullText
    end
    local result = table.concat(previewLines, "\n")
    _wrapPreviewCache[cacheKey] = result
    return result
end

--- Module-scope page cache: keyed by (wrapWidth, maxLines, resolved textLines).
--- Persists across menu-state recreation (state.data._dialoguePages dies on
--- every Alt/USE cycle). Key includes the resolved text contents, so dynamic
--- text = function(g) nodes still cache safely (key is the output, not node id).
--- 1st USE pays full pag cost; 2nd+ USE on same node returns cached pages in ~0ms.
local _pageCache = {}

--- Helper: wrap and split text into pages
--- Returns (pages, fromCache) where fromCache is true on module-cache hit.
local function PaginateText(textLines, maxLines, wrapWidth)
    wrapWidth = wrapWidth or RPG.Config.DIALOGUE_WRAP_WIDTH
    maxLines = maxLines or RPG.Config.DIALOGUE_MAX_TEXT_LINES

    local cacheKey = tostring(wrapWidth) .. "\0" .. tostring(maxLines)
        .. "\0" .. table.concat(textLines, "\1")
    local cached = _pageCache[cacheKey]
    if cached then return cached, true end

    -- Merge continuation lines before wrapping.
    -- Joins strings where the previous line ends mid-sentence
    -- (last visible char is not a sentence terminator: . ! ? ')
    local merged = {}
    for _, line in ipairs(textLines) do
        if #merged > 0 and #line > 0 then
            local prev = merged[#merged]
            local stripped = RPG.Util.StripColors(prev)
            if #stripped > 0 then
                local lastChar = stripped:sub(-1)
                if lastChar ~= "." and lastChar ~= "!"
                   and lastChar ~= "?" and lastChar ~= "'" then
                    merged[#merged] = prev .. " " .. line
                else
                    merged[#merged + 1] = line
                end
            else
                merged[#merged + 1] = line
            end
        else
            merged[#merged + 1] = line
        end
    end
    textLines = merged

    -- Flatten all text lines, wrapping each
    local allLines = {}
    for _, line in ipairs(textLines) do
        local stripped = RPG.Util.StripColors(line)
        if #stripped > wrapWidth then
            -- Word-wrap long lines
            local current = ""
            local currentLen = 0
            for word in line:gmatch("%S+") do
                local wordLen = #RPG.Util.StripColors(word)
                if currentLen + wordLen + 1 > wrapWidth and currentLen > 0 then
                    allLines[#allLines + 1] = current
                    current = word
                    currentLen = wordLen
                else
                    if currentLen > 0 then
                        current = current .. " " .. word
                        currentLen = currentLen + wordLen + 1
                    else
                        current = word
                        currentLen = wordLen
                    end
                end
            end
            if currentLen > 0 then
                allLines[#allLines + 1] = current
            end
        else
            allLines[#allLines + 1] = line
        end
    end

    -- Split into pages
    local pages = {}
    local page = {}
    for _, line in ipairs(allLines) do
        page[#page + 1] = line
        if #page >= maxLines then
            pages[#pages + 1] = page
            page = {}
        end
    end
    if #page > 0 then
        pages[#pages + 1] = page
    end

    -- Absorb orphan lines: if last page has <= 2 lines, merge into previous
    if #pages > 1 and #pages[#pages] <= 2
       and #pages[#pages - 1] + #pages[#pages] <= maxLines + 1 then
        local prev = pages[#pages - 1]
        for _, line in ipairs(pages[#pages]) do
            prev[#prev + 1] = line
        end
        pages[#pages] = nil
    end

    -- At least one empty page
    if #pages == 0 then
        pages[1] = { "" }
    end

    _pageCache[cacheKey] = pages
    return pages, false
end

Menu.Register("rpg_dialogue", {
    navigationDebounce = true,     -- leading+trailing edge debounce to reduce CP sends during scroll
    navigationCacheHeader = true,  -- preview moved to renderPreview callback
    title = function(player, state)
        local game = RPG.GetGame(player)
        if not game or not game.dialogue or not game.dialogue.active then
            return "^3=== DIALOGUE ===^7"
        end

        local tree = RPG.Dialogue.LoadTree(game.dialogue.npcId)
        if not tree then return "^3=== DIALOGUE ===^7" end

        local node = tree[game.dialogue.currentNode]
        if not node then return "^3=== DIALOGUE ===^7" end

        local speaker = node.speaker
        if type(speaker) == "function" then speaker = speaker(game) end
        speaker = speaker or RPG.Data.GetNPCName(game.dialogue.npcId, game)
        return RPG.Config.DIALOGUE_SPEAKER_COLOR .. "--- " .. speaker .. " ---^7"
    end,

    header = function(player, state)
        local _dbgBreakdown = RPG.Config.DEBUG_RENDER_BREAKDOWN or (Menu and Menu.profileRender)
        local _hdrT0, _hdrTLoad, _hdrTNode, _hdrTSaevus, _hdrTPag
        if _dbgBreakdown then _hdrT0 = Game.Milliseconds() end

        local game = RPG.GetGame(player)
        if not game or not game.dialogue or not game.dialogue.active then
            return "^1[No active dialogue]"
        end

        local tree = RPG.Dialogue.LoadTree(game.dialogue.npcId)
        if not tree then return "^1[Dialogue error]" end

        if _dbgBreakdown then _hdrTLoad = Game.Milliseconds() end

        local node = tree[game.dialogue.currentNode]
        if not node then return "^1[Missing node]" end

        if _dbgBreakdown then _hdrTNode = Game.Milliseconds() end

        local lines = {}

        -- Saevus interjection (if applicable)
        if node.saevusWhisper and node.saevusCondition then
            local ok, shouldShow = pcall(node.saevusCondition, game)
            if ok and shouldShow then
                local wrapped = RPG.Util.WrapText(node.saevusWhisper, RPG.Config.DIALOGUE_WRAP_WIDTH)
                for wLine in wrapped:gmatch("[^\n]+") do
                    lines[#lines + 1] = "^1" .. wLine
                end
            end
        end

        if _dbgBreakdown then _hdrTSaevus = Game.Milliseconds() end

        -- NPC text with pagination (reuse cache from getItems on menu open, or compute)
        local pages = state.data and state.data._dialoguePages
        local _hdrPagCache = "stateHit"  -- per-state cache served us
        if not pages then
            local textLines = resolveNodeField(node.text, game, { "" })
            local _modHit
            pages, _modHit = PaginateText(textLines, RPG.Config.DIALOGUE_MAX_TEXT_LINES,
                RPG.Config.DIALOGUE_WRAP_WIDTH)
            _hdrPagCache = _modHit and "modHit" or "miss"
            state.data._dialoguePages = pages
        end

        if _dbgBreakdown then _hdrTPag = Game.Milliseconds() end

        local currentPage = game.dialogue.textPage or 1
        if currentPage > #pages then currentPage = #pages end

        local pageLines = pages[currentPage]
        for _, line in ipairs(pageLines) do
            lines[#lines + 1] = RPG.Config.DIALOGUE_TEXT_COLOR .. line
        end

        -- Page indicator
        if #pages > 1 then
            lines[#lines + 1] = "^8[Page " .. currentPage .. "/" .. #pages .. "]"
        end

        -- Stat check result (temporary display)
        if state.data and state.data.checkResult then
            lines[#lines + 1] = state.data.checkResult
            state.data.checkResult = nil  -- Clear after display
            state._volatileHeader = true  -- Don't cache this header
        end

        if _dbgBreakdown and _hdrT0 then
            local _hdrTEnd = Game.Milliseconds()
            local _tLoad = _hdrTLoad or _hdrT0
            local _tNode = _hdrTNode or _tLoad
            local _tSaevus = _hdrTSaevus or _tNode
            local _tPag = _hdrTPag or _tSaevus
            GLua.Print(string.format("[DLG-HDR] total=%dms load=%d node=%d saevus=%d pag=%d pagCache=%s render=%d node=%s",
                _hdrTEnd - _hdrT0,
                _tLoad - _hdrT0,
                _tNode - _tLoad,
                _tSaevus - _tNode,
                _tPag - _tSaevus,
                _hdrPagCache,
                _hdrTEnd - _tPag,
                tostring(game.dialogue.currentNode)))
        end

        return table.concat(lines, "\n")
    end,

    -- Response preview: runs in both fast and full render paths (selection-dependent).
    -- Lazy-builds wrappedPreview for the selected item only; cached on the item
    -- after first build. Cold dialogue entry now wraps 1 response (the initial
    -- selection) instead of all visible responses.
    renderPreview = function(player, state)
        local items = state.cachedItems
        local sel = state.selection or 1
        local item = items and items[sel]
        if not item then return nil end
        if not item.wasTruncated then return nil end
        if not item.wrappedPreview then
            item.wrappedPreview = BuildWrappedPreview(item.fullLabel)
        end
        return item.wrappedPreview
    end,

    getItems = function(player, state)
        local _dbgBreakdown = RPG.Config.DEBUG_RENDER_BREAKDOWN or (Menu and Menu.profileRender)
        local _itemsT0, _itemsTLoad, _itemsTNode, _itemsTPag, _itemsTVis
        if _dbgBreakdown then _itemsT0 = Game.Milliseconds() end

        local game = RPG.GetGame(player)
        if not game or not game.dialogue or not game.dialogue.active then
            return { { label = "^1[Leave]", action = "end_dialogue" } }
        end

        local tree = RPG.Dialogue.LoadTree(game.dialogue.npcId)
        if not tree then
            return { { label = "^1[Leave]", action = "end_dialogue" } }
        end

        if _dbgBreakdown then _itemsTLoad = Game.Milliseconds() end

        local node = tree[game.dialogue.currentNode]
        if not node then
            return { { label = "^1[Leave]", action = "end_dialogue" } }
        end

        if _dbgBreakdown then _itemsTNode = Game.Milliseconds() end

        -- Check pagination: reuse cached pages from header() when available
        local pages = state.data and state.data._dialoguePages
        local _paginateCacheMiss = false
        local _itemsPagCache = "stateHit"  -- per-state cache served us
        if not pages then
            _paginateCacheMiss = true
            local textLines = resolveNodeField(node.text, game, { "" })
            local _modHit
            pages, _modHit = PaginateText(textLines, RPG.Config.DIALOGUE_MAX_TEXT_LINES,
                RPG.Config.DIALOGUE_WRAP_WIDTH)
            _itemsPagCache = _modHit and "modHit" or "miss"
            if state.data then state.data._dialoguePages = pages end
        end
        local currentPage = game.dialogue.textPage or 1
        if currentPage > #pages then currentPage = #pages end

        if _dbgBreakdown then _itemsTPag = Game.Milliseconds() end

        if currentPage < #pages then
            if _dbgBreakdown and _itemsT0 then
                local _itemsTEnd = Game.Milliseconds()
                local _tLoad = _itemsTLoad or _itemsT0
                local _tNode = _itemsTNode or _tLoad
                local _tPag = _itemsTPag or _tNode
                GLua.Print(string.format("[DLG-ITEMS] total=%dms (continue) load=%d node=%d pag=%d pagCache=%s node=%s",
                    _itemsTEnd - _itemsT0,
                    _tLoad - _itemsT0,
                    _tNode - _tLoad,
                    _tPag - _tNode,
                    _itemsPagCache,
                    tostring(game.dialogue.currentNode)))
            end
            return {
                { label = "^7>>> Continue", action = "next_page" },
            }
        end

        -- On final page: show filtered responses
        local items = {}
        items[#items + 1] = { label = "^3--- Responses ---", action = "none" }
        local visibleResponses = RPG.Dialogue.GetVisibleResponses(game, node)
        local maxResp = RPG.Config.DIALOGUE_MAX_RESPONSES or 4

        if _dbgBreakdown then _itemsTVis = Game.Milliseconds() end

        local _loopLabelMs, _loopTruncMs, _loopWrapMs = 0, 0, 0

        for idx, entry in ipairs(visibleResponses) do
            if idx > maxResp then break end
            local resp = entry.response

            local _tLabel0 = _dbgBreakdown and Game.Milliseconds() or nil
            local label = RPG.Dialogue.GetResponseLabel(game, resp)
            local fullLabel = label  -- save before truncation
            if _tLabel0 then _loopLabelMs = _loopLabelMs + (Game.Milliseconds() - _tLabel0) end

            local _tTrunc0 = _dbgBreakdown and Game.Milliseconds() or nil
            -- Truncate by VISIBLE characters (color codes don't count)
            local MAX_LABEL_VISIBLE = 44
            local visibleLen = #RPG.Util.StripColors(label)
            if visibleLen > MAX_LABEL_VISIBLE then
                local vis = 0
                local cutPos = #label
                local lastSpacePos = nil
                local i = 1
                while i <= #label do
                    if label:sub(i, i) == "^" and i + 1 <= #label then
                        i = i + 2  -- skip color code
                    else
                        vis = vis + 1
                        if label:sub(i, i) == " " then
                            lastSpacePos = i - 1  -- cut before the space
                        end
                        if vis >= MAX_LABEL_VISIBLE - 3 then
                            cutPos = lastSpacePos or i
                            break
                        end
                        i = i + 1
                    end
                end
                label = label:sub(1, cutPos) .. "^7..."
            end
            local wasTruncated = (visibleLen > MAX_LABEL_VISIBLE)
            if _tTrunc0 then _loopTruncMs = _loopTruncMs + (Game.Milliseconds() - _tTrunc0) end

            local _tWrap0 = _dbgBreakdown and Game.Milliseconds() or nil
            -- wrappedPreview built lazily by renderPreview for the selected item
            -- only. Loop wrap=0ms now; previously ~15ms per truncated response.
            if _tWrap0 then _loopWrapMs = _loopWrapMs + (Game.Milliseconds() - _tWrap0) end

            items[#items + 1] = {
                label = RPG.Config.DIALOGUE_RESPONSE_COLOR .. label,
                action = "respond:" .. entry.index,
                responseIndex = entry.index,
                fullLabel = fullLabel,
                wasTruncated = wasTruncated,
                -- wrappedPreview populated lazily; see renderPreview callback.
            }
        end

        -- Always have a leave option if no responses
        if #items == 0 then
            items[#items + 1] = { label = "^7[Leave]", action = "end_dialogue" }
        end

        if _dbgBreakdown and _itemsT0 then
            local _itemsTEnd = Game.Milliseconds()
            local _tLoad = _itemsTLoad or _itemsT0
            local _tNode = _itemsTNode or _tLoad
            local _tPag = _itemsTPag or _tNode
            local _tVis = _itemsTVis or _tPag
            local _loopMs = _itemsTEnd - _tVis
            local cp = game.dialogue.textPage or 1
            local totalPages = pages and #pages or 0
            GLua.Print(string.format("[DLG-ITEMS] total=%dms load=%d node=%d pag=%d pagCache=%s visResp=%d loop=%d (label=%d trunc=%d wrap=%d) responses=%d page=%d/%d node=%s",
                _itemsTEnd - _itemsT0,
                _tLoad - _itemsT0,
                _tNode - _tLoad,
                _tPag - _tNode,
                _itemsPagCache,
                _tVis - _tPag,
                _loopMs,
                _loopLabelMs, _loopTruncMs, _loopWrapMs,
                #items - 1, cp, totalPages,
                tostring(game.dialogue.currentNode)))
            if _paginateCacheMiss and _itemsPagCache == "miss" then
                GLua.Print("[DLG-ITEMS] WARNING: PaginateText cold (no module cache)")
            end
        end

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then return end

        -- End dialogue
        if action == "end_dialogue" then
            RPG.Dialogue.End(player)
            return
        end

        -- Next page of text (HandleSelect renders after onAction returns)
        if action == "next_page" then
            if not game.dialogue then return end
            game.dialogue.textPage = (game.dialogue.textPage or 1) + 1
            if Menu and Menu.InvalidateCache then Menu.InvalidateCache(player) end
            return
        end

        -- Player chose a response
        if string.StartsWith(action, "respond:") then
            local respIndex = tonumber(action:sub(#"respond:" + 1))
            if not respIndex then return end

            local tree = RPG.Dialogue.LoadTree(game.dialogue.npcId)
            if not tree then return end

            local node = tree[game.dialogue.currentNode]
            if not node then return end
            local responses = resolveNodeField(node.responses, game, {})
            if #responses == 0 then return end

            local resp = responses[respIndex]
            if not resp then return end

            -- Stat check
            if resp.check then
                local success, roll, modifier = RPG.Dialogue.RollCheck(game, resp.check)
                local statLabel = RPG.Config.STAT_CHECK_LABELS[resp.check.stat] or resp.check.stat
                local sign = modifier >= 0 and "+" or ""

                if success then
                    state.data.checkResult = RPG.Config.DIALOGUE_CHECK_SUCCESS ..
                        "[Passed!] " .. statLabel .. " check (rolled " ..
                        (roll + modifier) .. ", needed " .. resp.check.dc .. ")"
                    -- Apply response effects
                    RPG.Dialogue.ApplyResponseEffects(player, resp)
                    -- Navigate to success node
                    RPG.Dialogue.GoToNode(player, resp.next)
                else
                    state.data.checkResult = RPG.Config.DIALOGUE_CHECK_FAIL ..
                        "[Failed] " .. statLabel .. " check (rolled " ..
                        (roll + modifier) .. ", needed " .. resp.check.dc .. ")"
                    -- Navigate to fail node
                    RPG.Dialogue.GoToNode(player, resp.failNext or -1)
                end
                return
            end

            -- Apply response effects (no stat check)
            RPG.Dialogue.ApplyResponseEffects(player, resp)

            -- Navigate
            local nextNode = resp.next
            if nextNode == nil then nextNode = -1 end
            RPG.Dialogue.GoToNode(player, nextNode)
            return
        end
    end,

    onBack = function(player, state)
        -- ALT/back ends dialogue
        RPG.Dialogue.End(player)
        return true
    end,

    onWalk = function(player, state)
        player:SendPrint("")
        player:SendPrint("^5--- DIALOGUE SKILL CHECKS ---^7")
        player:SendPrint("^5[Stat Name]^7 options test your character's stats.")
        player:SendPrint("^7A d20 die is rolled + your stat bonus.")
        player:SendPrint("^7Higher stats = better chance to pass.")
        player:SendPrint("")
        player:SendPrint("^3Awareness^7=WIS  ^3Persuade^7=CHA  ^3Might^7=STR")
        player:SendPrint("^3Reflex^7=DEX  ^3Fortitude^7=CON  ^3Logic^7=INT")
        player:SendPrint("")
    end,

    controls = "^3W/S^7=Nav | ^3USE^7=Select | ^3ALT^7=Leave | ^3WALK^7=Help",
    maxVisibleItems = 6,
    allowAttackClose = false,
})

-- ============================================
-- Response effect helper (not idempotent -- intentional)
-- ============================================

function RPG.Dialogue.ApplyResponseEffects(player, resp)
    if not resp then return end

    -- Direct alignment shorthand
    if resp.alignment then
        RPG.AddAlignment(player, resp.alignment)
    end

    -- Direct setFlag shorthand
    if resp.setFlag then
        local game = RPG.GetGame(player)
        if game then
            RPG.Quest.SetFlag(game, resp.setFlag)
        end
    end

    -- Full effects table
    if resp.effects then
        RPG.Dialogue.ApplyEffects(player, resp.effects)
    end
end

return true
