-- Echoes of the Dark Wars - Dialogue Engine
-- Tree loading, route evaluation, effects, stat checks, validation

RPG = RPG or {}
RPG.Dialogue = {}

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

-- Cache loaded dialogue trees (npcId -> tree table)
RPG.Dialogue.Trees = {}

-- ============================================
-- DIALOGUE TREE LOADING
-- ============================================

--- Load a dialogue tree for an NPC (cached)
function RPG.Dialogue.LoadTree(npcId)
    -- Return cached
    if RPG.Dialogue.Trees[npcId] then
        return RPG.Dialogue.Trees[npcId]
    end

    -- Look up NPC definition for dialogueFile
    local npcDef = RPG.Data.NPCs[npcId]
    if not npcDef or not npcDef.dialogueFile then
        GLua.Debug("RPG.Dialogue: No dialogueFile for NPC " .. tostring(npcId))
        return nil
    end

    -- Load the dialogue file
    local ok, tree = pcall(function()
        return GLua.Include(npcDef.dialogueFile)
    end)

    if not ok or not tree then
        GLua.Warn("RPG.Dialogue: Failed to load dialogue for NPC " .. tostring(npcId) .. ": " .. tostring(tree))
        return nil
    end

    RPG.Dialogue.Trees[npcId] = tree
    return tree
end

--- Clear cached trees (for hot-reload)
function RPG.Dialogue.ClearCache()
    RPG.Dialogue.Trees = {}
end

-- ============================================
-- ROUTE EVALUATION (Node 0 router)
-- ============================================

--- Evaluate routes on a node, return the target node ID
function RPG.Dialogue.EvalRoutes(game, node)
    if not node or not node.routes then return nil end

    for _, route in ipairs(node.routes) do
        if route.condition then
            local ok, result = pcall(route.condition, game)
            if ok and result then
                return route.node
            end
        end
    end

    return node.fallback
end

-- ============================================
-- START DIALOGUE
-- ============================================

--- Start dialogue with an NPC
function RPG.Dialogue.Start(player, npcId)
    local game = RPG.GetGame(player)
    if not game then return false end

    local tree = RPG.Dialogue.LoadTree(npcId)
    if not tree then
        -- Fallback: no dialogue file, use placeholder
        local name = RPG.Data.GetNPCName(npcId, game)
        player:SendPrint("")
        player:SendPrint(RPG.Config.NPC_NAME_COLOR .. name .. " ^7has nothing to say right now.")
        player:SendPrint("")
        return false
    end

    -- Evaluate root node (node 0) to find entry point
    local rootNode = tree[0]
    local entryNodeId = 1  -- default fallback

    if rootNode then
        local routedId = RPG.Dialogue.EvalRoutes(game, rootNode)
        if routedId then
            entryNodeId = routedId
        elseif rootNode.fallback then
            entryNodeId = rootNode.fallback
        end
    end

    -- Verify entry node exists
    if not tree[entryNodeId] then
        GLua.Warn("RPG.Dialogue: Entry node " .. tostring(entryNodeId) .. " missing for NPC " .. tostring(npcId))
        return false
    end

    -- Cancel background timers that would fire during dialogue
    local cn = player:GetClientNum()
    Timer.Remove("rpg_saber_whisper_" .. cn)
    Timer.Remove("rpg_ship_companion_" .. cn)
    Timer.Remove("rpg_crowd_first_" .. cn)
    Timer.Remove("rpg_crowd_whisper_" .. cn)

    -- Set up dialogue state
    game.dialogue = {
        active = true,
        npcId = npcId,
        currentNode = entryNodeId,
        textPage = 1,
        appliedNodes = {},  -- idempotency tracking for this session
    }

    -- Apply node-enter effects for the entry node
    RPG.Dialogue.ApplyNodeEffects(player, npcId, entryNodeId)

    -- Open dialogue menu
    RPG.SetState(player, "dialogue")

    return true
end

--- Navigate to a specific node in the current dialogue
function RPG.Dialogue.GoToNode(player, nodeId)
    local game = RPG.GetGame(player)
    if not game or not game.dialogue or not game.dialogue.active then return false end

    -- End dialogue
    if nodeId == -1 then
        RPG.Dialogue.End(player)
        return true
    end

    local tree = RPG.Dialogue.LoadTree(game.dialogue.npcId)
    if not tree then return false end

    local node = tree[nodeId]
    if not node then
        GLua.Warn("RPG.Dialogue: Node " .. tostring(nodeId) .. " not found")
        RPG.Dialogue.End(player)
        return false
    end

    -- Check if this is a router node
    if node.routes then
        local routedId = RPG.Dialogue.EvalRoutes(game, node)
        if routedId then
            return RPG.Dialogue.GoToNode(player, routedId)
        end
        -- Router with no valid route and no content -- bail out cleanly
        if not node.text and not node.responses then
            GLua.Warn("RPG.Dialogue: Router node " .. tostring(nodeId) .. " has no valid route")
            RPG.Dialogue.End(player)
            return false
        end
    end

    game.dialogue.currentNode = nodeId
    game.dialogue.textPage = 1

    -- Apply node-enter effects
    RPG.Dialogue.ApplyNodeEffects(player, game.dialogue.npcId, nodeId)

    -- Refresh menu state (HandleSelect renders after onAction returns)
    if Menu and Menu.active then
        local menuState = Menu.active[player:GetClientNum()]
        if menuState then
            menuState.selection = 1
            -- Clear stale pagination cache (node text changed)
            if menuState.data then
                menuState.data._dialoguePages = nil
            end
        end
    end
    if Menu and Menu.InvalidateCache then
        Menu.InvalidateCache(player)
    end

    return true
end

--- End dialogue, return to exploration
function RPG.Dialogue.End(player)
    local game = RPG.GetGame(player)
    if not game then return end

    -- Save pending state transition/combat BEFORE wiping dialogue state
    local pendingState = game.dialogue and game.dialogue.pendingState
    -- Save pending combat BEFORE wiping dialogue state
    local pendingCombat = game.dialogue and game.dialogue.pendingCombat

    game.dialogue = { active = false, npcId = nil, currentNode = 0 }
    RPG.SetState(player, "exploration")

    -- Start deferred state transition after returning to exploration
    if pendingState and pendingState.state and RPG.Config.STATE_MENUS[pendingState.state] then
        RPG.SetState(player, pendingState.state, pendingState.data or {})
        return
    end

    -- Start deferred combat after returning to exploration
    if pendingCombat and RPG.Combat and RPG.Combat.StartCombat then
        RPG.Combat.StartCombat(player, pendingCombat)
    end
end

-- ============================================
-- NODE EFFECTS (idempotent per-session)
-- ============================================

--- Apply effects when entering a dialogue node (idempotent within session)
function RPG.Dialogue.ApplyNodeEffects(player, npcId, nodeId)
    local game = RPG.GetGame(player)
    if not game or not game.dialogue then return end

    -- Idempotency guard
    local nodeKey = tostring(npcId) .. ":" .. tostring(nodeId)
    if game.dialogue.appliedNodes and game.dialogue.appliedNodes[nodeKey] then
        return  -- Already applied this session
    end
    if not game.dialogue.appliedNodes then
        game.dialogue.appliedNodes = {}
    end
    game.dialogue.appliedNodes[nodeKey] = true

    local tree = RPG.Dialogue.LoadTree(npcId)
    if not tree then return end

    local node = tree[nodeId]
    if not node or not node.effects then return end

    RPG.Dialogue.ApplyEffects(player, node.effects)
end

--- Apply an effects table (shared between node effects and response effects)
function RPG.Dialogue.ApplyEffects(player, effects)
    if not effects then return end
    local game = RPG.GetGame(player)
    if not game then return end

    if effects.alignment then
        RPG.AddAlignment(player, effects.alignment)
    end
    if effects.paranoia then
        RPG.AddParanoia(player, effects.paranoia)
    end
    if effects.giveItem then
        local itemId = effects.giveItem
        if #game.player.inventory < RPG.Config.MAX_INVENTORY then
            game.player.inventory[#game.player.inventory + 1] = itemId
            local name = RPG.Data.GetItemName(itemId)
            player:SendPrint("^2[Received] " .. RPG.Config.ITEM_COLOR .. name)
            -- Check Holocron
            if itemId == RPG.Config.HOLOCRON_ITEM_ID then
                game.player.hasHolocron = true
            end
        end
    end
    if effects.removeItem then
        local itemId = effects.removeItem
        RPG.Util.RemoveValue(game.player.inventory, itemId)
        local name = RPG.Data.GetItemName(itemId)
        player:SendPrint("^1[Lost] " .. RPG.Config.ITEM_COLOR .. name)
        if itemId == RPG.Config.HOLOCRON_ITEM_ID then
            game.player.hasHolocron = false
        end
    end
    if effects.addCredits then
        game.player.credits = game.player.credits + effects.addCredits
        if effects.addCredits > 0 then
            player:SendPrint("^3[+" .. effects.addCredits .. " credits]")
        elseif effects.addCredits < 0 then
            player:SendPrint("^1[" .. effects.addCredits .. " credits]")
        end
    end
    if effects.startQuest then
        RPG.Quest.Start(player, effects.startQuest)
    end
    if effects.setStage then
        RPG.Quest.SetStage(player, effects.setStage.quest, effects.setStage.stage)
    end
    if effects.completeQuest then
        RPG.Quest.Complete(player, effects.completeQuest)
    end
    if effects.setFlag then
        RPG.Quest.SetFlag(game, effects.setFlag)
    end
    if effects.clearFlag then
        RPG.Quest.ClearFlag(game, effects.clearFlag)
    end
    if effects.giveXP then
        game.player.xp = game.player.xp + effects.giveXP
        player:SendPrint("^2[+" .. effects.giveXP .. " XP]")
    end
    if effects.unlockRoom then
        if game.rooms[effects.unlockRoom] then
            game.rooms[effects.unlockRoom].locked = false
        end
    end
    if effects.startCombat then
        -- Deferred: will start combat after dialogue ends
        game.dialogue.pendingCombat = effects.startCombat
    end
    if effects.startState and type(effects.startState) == "table" then
        -- Deferred: switch to another RPG state after dialogue closes
        game.dialogue.pendingState = {
            state = effects.startState.state,
            data = effects.startState.data or {},
        }
    end
    if effects.grantAbility then
        local abilityDef = RPG.Data.Abilities and RPG.Data.Abilities[effects.grantAbility]
        if abilityDef and abilityDef.unlock and abilityDef.unlock.classes then
            local classMatch = false
            for _, cls in ipairs(abilityDef.unlock.classes) do
                if cls == game.player.class then classMatch = true; break end
            end
            if classMatch then
                RPG.GrantAbility(player, effects.grantAbility)
            end
        else
            RPG.GrantAbility(player, effects.grantAbility)
        end
    end
    if effects.addCompanion then
        if RPG.Companion and RPG.Companion.Recruit then
            RPG.Companion.Recruit(player, effects.addCompanion, effects.addCompanionBlackmailed or false)
            local def = RPG.Data.GetCompanion(effects.addCompanion)
            local name = def and def.name or effects.addCompanion
            if effects.addCompanionBlackmailed then
                player:SendPrint("^3[" .. name .. " joins reluctantly]")
            else
                player:SendPrint("^2[" .. name .. " joins your party]")
            end
        end
    end
    if effects.action and type(effects.action) == "function" then
        pcall(effects.action, player, game)
    end
end

-- ============================================
-- STAT CHECKS (d20 roll)
-- ============================================

--- Roll a stat check: StatMod(stat) + d20 >= dc
--- Returns success (bool), roll (number), modifier (number)
function RPG.Dialogue.RollCheck(game, check)
    if not check or not check.stat or not check.dc then
        return true, 20, 0  -- No check = auto-pass
    end

    local statVal = game.player.stats[check.stat] or RPG.Config.STAT_BASE
    local modifier = RPG.Util.StatMod(statVal)

    -- Mental Fortress: +2 to stat checks when paranoia > 50
    if game.player.abilitiesKnown and game.player.abilitiesKnown.mental_fortress
        and (game.player.paranoia or 0) > 50 then
        modifier = modifier + 2
    end

    local roll = math.random(1, 20)
    local total = modifier + roll
    local success = total >= check.dc

    return success, roll, modifier
end

-- ============================================
-- RESPONSE FILTERING
-- ============================================

--- Get visible responses for a node, filtered by conditions
function RPG.Dialogue.GetVisibleResponses(game, node)
    if not node or not node.responses then return {} end
    local responses = resolveNodeField(node.responses, game, {})

    local visible = {}
    for i, resp in ipairs(responses) do
        local show = true

        -- Condition function
        if resp.condition and type(resp.condition) == "function" then
            local ok, result = pcall(resp.condition, game)
            if not ok or not result then
                show = false
            end
        end

        -- Require item
        if show and resp.requireItem then
            if not RPG.Util.Contains(game.player.inventory, resp.requireItem) then
                show = false
            end
        end

        -- Require quest + stage
        if show and resp.requireQuest then
            local rq = resp.requireQuest
            local stage = RPG.Quest.GetStage(game, rq.quest or rq[1])
            if stage ~= (rq.stage or rq[2]) then
                show = false
            end
        end

        -- Require flag
        if show and resp.requireFlag then
            if not RPG.Quest.HasFlag(game, resp.requireFlag) then
                show = false
            end
        end

        -- Require NOT flag
        if show and resp.requireNotFlag then
            if RPG.Quest.HasFlag(game, resp.requireNotFlag) then
                show = false
            end
        end

        if show then
            visible[#visible + 1] = { index = i, response = resp }
        end
    end

    return visible
end

--- Get the display label for a response (handles Doubt, stat checks, fakeouts)
function RPG.Dialogue.GetResponseLabel(game, resp)
    if not resp then return "???" end

    local label = resp.label
    if type(label) == "function" then label = label(game) end
    label = label or "..."
    local wisVal = game.player.stats.WIS or RPG.Config.STAT_BASE
    local paranoia = game.player.paranoia or 0

    -- Doubt response handling
    if resp.isDoubt then
        -- Determine truth threshold: mental_fortress lowers it to 12
        local truthThreshold = RPG.Config.DOUBT_WIS_THRESHOLD
        if game.player.abilitiesKnown and game.player.abilitiesKnown.mental_fortress then
            truthThreshold = 12
        end

        if wisVal >= truthThreshold then
            -- High WIS (or mental_fortress): see through the manipulation
            label = "^2[TRUTH] " .. (resp.truthLabel or resp.label)
        elseif game.player.abilitiesKnown and game.player.abilitiesKnown.force_sense and wisVal < truthThreshold then
            -- Force Sense: gut feeling something is off
            label = "^8[SENSE] " .. label
        elseif paranoia >= RPG.Config.DOUBT_FAKEOUT_PARANOIA and resp.check then
            -- Paranoia 70+ with low WIS: stat check labels can lie on Doubt responses
            local fakeStat = RPG.Config.STAT_CHECK_LABELS[resp.check.stat] or resp.check.stat
            label = "[" .. fakeStat .. "] " .. label
            return label
        end
    end

    -- Stat check display (normal, non-faked)
    if resp.check then
        -- Strip leading bracketed stat prefix (must contain a digit, e.g., "[WIS 14]", "[STR 16+2]")
        label = label:gsub("^%[%a+%s*%d[^%]]*%]%s*", "")
        local statName = RPG.Config.STAT_CHECK_LABELS[resp.check.stat] or resp.check.stat
        local checkLabel = "^5[" .. statName .. "]^7 "
        label = checkLabel .. label
    end

    return label
end

-- ============================================
-- DIALOGUE TREE VALIDATOR
-- ============================================

--- Validate a dialogue tree, printing warnings for issues
function RPG.Dialogue.ValidateTree(npcName, tree)
    if not tree then
        GLua.Warn("Dialogue Validate: nil tree for '" .. tostring(npcName) .. "'")
        return false
    end

    local warnings = 0
    local reachable = {}

    -- Collect all node IDs
    local allNodes = {}
    for nodeId, _ in pairs(tree) do
        allNodes[nodeId] = true
    end

    -- Mark nodes reachable from root
    local function markReachable(nodeId, visited, depth)
        depth = depth or 0
        if depth > 200 then
            GLua.Warn("Dialogue '" .. npcName .. "': Depth limit at node " .. tostring(nodeId))
            return
        end
        if visited[nodeId] then return end
        visited[nodeId] = true
        reachable[nodeId] = true

        local node = tree[nodeId]
        if not node then return end

        -- Routes
        if node.routes then
            for _, route in ipairs(node.routes) do
                if route.node then markReachable(route.node, visited, depth + 1) end
            end
        end
        if node.fallback then markReachable(node.fallback, visited, depth + 1) end

        -- Responses
        if node.responses and type(node.responses) ~= "function" then
            for _, resp in ipairs(node.responses) do
                if resp.next and resp.next ~= -1 then
                    markReachable(resp.next, visited, depth + 1)
                end
                if resp.failNext and resp.failNext ~= -1 then
                    markReachable(resp.failNext, visited, depth + 1)
                end
            end
        end
    end

    markReachable(0, {}, 0)

    -- Check for orphaned nodes
    for nodeId, _ in pairs(allNodes) do
        if not reachable[nodeId] then
            GLua.Warn("Dialogue '" .. npcName .. "': Node " .. nodeId .. " is unreachable from root")
            warnings = warnings + 1
        end
    end

    -- Check each node
    for nodeId, node in pairs(tree) do
        -- Check responses reference valid nodes
        if node.responses and type(node.responses) ~= "function" then
            for i, resp in ipairs(node.responses) do
                if resp.next and resp.next ~= -1 and not tree[resp.next] then
                    GLua.Warn("Dialogue '" .. npcName .. "': Node " .. nodeId ..
                        " response " .. i .. " next=" .. resp.next .. " does not exist")
                    warnings = warnings + 1
                end
                if resp.check and not resp.failNext then
                    GLua.Warn("Dialogue '" .. npcName .. "': Node " .. nodeId ..
                        " response " .. i .. " has check but no failNext")
                    warnings = warnings + 1
                end
                if resp.failNext and resp.failNext ~= -1 and not tree[resp.failNext] then
                    GLua.Warn("Dialogue '" .. npcName .. "': Node " .. nodeId ..
                        " response " .. i .. " failNext=" .. resp.failNext .. " does not exist")
                    warnings = warnings + 1
                end
            end
        end

        -- Check routes reference valid nodes
        if node.routes then
            for i, route in ipairs(node.routes) do
                if route.node and not tree[route.node] then
                    GLua.Warn("Dialogue '" .. npcName .. "': Node " .. nodeId ..
                        " route " .. i .. " target=" .. route.node .. " does not exist")
                    warnings = warnings + 1
                end
            end
        end
        if node.fallback and not tree[node.fallback] then
            GLua.Warn("Dialogue '" .. npcName .. "': Node " .. nodeId ..
                " fallback=" .. node.fallback .. " does not exist")
            warnings = warnings + 1
        end

        -- Check effects reference valid quests
        if node.effects then
            RPG.Dialogue.ValidateEffects(npcName, nodeId, node.effects)
        end
        if node.responses and type(node.responses) ~= "function" then
            for i, resp in ipairs(node.responses) do
                if resp.effects then
                    RPG.Dialogue.ValidateEffects(npcName, nodeId .. ":resp" .. i, resp.effects)
                end
            end
        end
    end

    if warnings > 0 then
        GLua.Warn("Dialogue '" .. npcName .. "': " .. warnings .. " validation warning(s)")
    else
        GLua.Debug("Dialogue '" .. npcName .. "': Validated OK")
    end

    return warnings == 0
end

--- Validate effects references
function RPG.Dialogue.ValidateEffects(npcName, context, effects)
    if not effects then return end

    if effects.startQuest and RPG.Data.Quests then
        if not RPG.Data.Quests[effects.startQuest] then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": startQuest '" .. effects.startQuest .. "' not found in quest data")
        end
    end

    if effects.setStage and RPG.Data.Quests then
        local sq = effects.setStage
        local qDef = RPG.Data.Quests[sq.quest]
        if not qDef then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": setStage quest '" .. tostring(sq.quest) .. "' not found")
        elseif not qDef.stages[sq.stage] then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": setStage stage '" .. tostring(sq.stage) .. "' not in quest '" .. sq.quest .. "'")
        end
    end

    if effects.completeQuest and RPG.Data.Quests then
        if not RPG.Data.Quests[effects.completeQuest] then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": completeQuest '" .. tostring(effects.completeQuest) .. "' not found")
        end
    end

    if effects.startState and type(effects.startState) == "table" then
        if not effects.startState.state then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": startState missing state field")
        elseif not RPG.Config.STATE_MENUS[effects.startState.state] then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": startState '" .. tostring(effects.startState.state) .. "' has no menu mapping")
        end
    end

    if effects.giveItem and RPG.Data.Items then
        if not RPG.Data.Items[effects.giveItem] then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": giveItem " .. tostring(effects.giveItem) .. " not found")
        end
    end

    if effects.removeItem and RPG.Data.Items then
        if not RPG.Data.Items[effects.removeItem] then
            GLua.Warn("Dialogue '" .. npcName .. "' " .. tostring(context) ..
                ": removeItem " .. tostring(effects.removeItem) .. " not found")
        end
    end
end

-- ============================================
-- VALIDATE ALL LOADED TREES
-- ============================================

function RPG.Dialogue.ValidateAll()
    local count = 0
    for npcId, npcDef in pairs(RPG.Data.NPCs) do
        if npcDef.dialogueFile then
            local tree = RPG.Dialogue.LoadTree(npcId)
            if tree then
                RPG.Dialogue.ValidateTree(npcDef.name or ("NPC " .. npcId), tree)
                count = count + 1
            end
        end
    end
    GLua.Print("RPG: Validated " .. count .. " dialogue tree(s)")
end

return true
