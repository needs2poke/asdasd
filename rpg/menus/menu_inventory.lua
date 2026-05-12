-- Echoes of the Dark Wars - Inventory Menu
-- Tabbed inventory with inline context actions and examine detail view

RPG = RPG or {}

-- ============================================
-- Constants
-- ============================================
local TAB_NAMES = { "GEAR", "SUPPLIES", "QUEST" }
local GEAR_TYPES = { weapon = true, armor = true, accessory = true }
local QUEST_TYPES = { quest = true, misc = true, crystal = true }

local SLOT_ORDER = { "weapon", "armor", "accessory" }
local SLOT_LABELS = { weapon = "[W]", armor = "[A]", accessory = "[C]" }
local SLOT_NAMES = { weapon = "Weapon", armor = "Armor", accessory = "Accessory" }

local WRAP_WIDTH = 46

-- ============================================
-- Helpers
-- ============================================

--- Word-wrap text to ~WRAP_WIDTH chars, returns array of lines
local function WrapText(text)
    if not text then return {} end
    local lines = {}
    -- Split on explicit newlines first
    for segment in text:gmatch("[^\n]+") do
        if #segment <= WRAP_WIDTH then
            lines[#lines + 1] = segment
        else
            local line = ""
            for word in segment:gmatch("%S+") do
                if line == "" then
                    line = word
                elseif #line + 1 + #word <= WRAP_WIDTH then
                    line = line .. " " .. word
                else
                    lines[#lines + 1] = line
                    line = word
                end
            end
            if line ~= "" then
                lines[#lines + 1] = line
            end
        end
    end
    return lines
end

--- Build stat comparison line: "Damage: 14  ^8(eq: 10)  ^2+4"
local function BuildStatComparison(label, newVal, eqVal)
    if not newVal then return nil end
    if not eqVal then
        return "^7" .. label .. ": " .. newVal .. "  ^8(nothing equipped)"
    end
    local diff = newVal - eqVal
    local diffStr
    if diff > 0 then
        diffStr = "^2+" .. diff
    elseif diff < 0 then
        diffStr = "^1" .. diff
    else
        diffStr = "^7+0"
    end
    return "^7" .. label .. ": " .. newVal .. "  ^8(eq: " .. eqVal .. ")  " .. diffStr
end

--- Build full comparison block between an inventory item and the equipped item in its slot
local function BuildComparison(itemDef, game)
    if not itemDef or not itemDef.slot then return {} end
    local eqId = game.player.equipped[itemDef.slot]
    local eqDef = eqId and RPG.Data.Items[eqId]
    local lines = {}

    local dmgLine = BuildStatComparison("Damage", itemDef.damage, eqDef and eqDef.damage)
    if dmgLine then lines[#lines + 1] = dmgLine end

    local defLine = BuildStatComparison("Defense", itemDef.defense, eqDef and eqDef.defense)
    if defLine then lines[#lines + 1] = defLine end

    -- Stat bonuses
    local allStats = {}
    if itemDef.statBonus then
        for stat in pairs(itemDef.statBonus) do allStats[stat] = true end
    end
    if eqDef and eqDef.statBonus then
        for stat in pairs(eqDef.statBonus) do allStats[stat] = true end
    end
    for stat in pairs(allStats) do
        local newB = (itemDef.statBonus and itemDef.statBonus[stat]) or 0
        local eqB = (eqDef and eqDef.statBonus and eqDef.statBonus[stat]) or 0
        if not eqDef then
            lines[#lines + 1] = "^7+" .. newB .. " " .. stat .. "  ^8(nothing equipped)"
        else
            local diff = newB - eqB
            local diffStr
            if diff > 0 then
                diffStr = "^2+" .. diff
            elseif diff < 0 then
                diffStr = "^1" .. diff
            else
                diffStr = "^7+0"
            end
            lines[#lines + 1] = "^7+" .. newB .. " " .. stat .. "  ^8(eq: +" .. eqB .. ")  " .. diffStr
        end
    end

    return lines
end

--- Build the examine detail view as a list of menu items
local function BuildExamineView(examineItem, game)
    local itemId = examineItem.itemId
    local itemDef = RPG.Data.Items[itemId]
    if not itemDef then return { { label = "^1Unknown item", action = "none" } } end

    local name = RPG.Data.GetItemName(itemId)
    local items = {}

    items[#items + 1] = { label = "^3=== " .. name .. " ===", action = "none" }

    if itemDef.description then
        local descLines = WrapText(itemDef.description)
        for _, line in ipairs(descLines) do
            items[#items + 1] = { label = "^7" .. line, action = "none" }
        end
    end

    if itemDef.examineText then
        items[#items + 1] = { label = "", action = "none" }
        local exLines = WrapText(itemDef.examineText)
        for _, line in ipairs(exLines) do
            items[#items + 1] = { label = "^7" .. line, action = "none" }
        end
    end

    -- Stats
    if itemDef.damage then
        items[#items + 1] = { label = "^2Damage: " .. itemDef.damage, action = "none" }
    end
    if itemDef.defense then
        items[#items + 1] = { label = "^2Defense: " .. itemDef.defense, action = "none" }
    end
    if itemDef.statBonus then
        for stat, bonus in pairs(itemDef.statBonus) do
            items[#items + 1] = { label = "^2+" .. bonus .. " " .. stat, action = "none" }
        end
    end
    if itemDef.healAmount then
        items[#items + 1] = { label = "^2Heals: " .. itemDef.healAmount .. " HP", action = "none" }
    end
    if itemDef.curePoison then
        items[#items + 1] = { label = "^2Cures Poison", action = "none" }
    end
    if itemDef.damageBonus then
        items[#items + 1] = { label = "^2+" .. itemDef.damageBonus .. " Damage bonus", action = "none" }
    end

    -- Comparison (only for inventory equippables, not equipped items)
    if examineItem.compareSlot and itemDef.slot then
        items[#items + 1] = { label = "", action = "none" }
        items[#items + 1] = { label = "^3--- Comparison ---", action = "none" }
        local cmpLines = BuildComparison(itemDef, game)
        for _, line in ipairs(cmpLines) do
            items[#items + 1] = { label = line, action = "none" }
        end
    end

    items[#items + 1] = { label = "", action = "none" }
    items[#items + 1] = { label = "^3<<< Back", action = "examine_back" }

    return items
end

-- ============================================
-- Tab Builders
-- ============================================

local function BuildGearTab(game, state)
    local items = {}

    -- Equipped section
    items[#items + 1] = { label = "^3--- Equipped ---", action = "none" }
    for _, slot in ipairs(SLOT_ORDER) do
        local itemId = game.player.equipped[slot]
        if itemId then
            local name = RPG.Data.GetItemName(itemId)
            local tag = SLOT_LABELS[slot]
            items[#items + 1] = {
                label = RPG.Config.ITEM_COLOR .. tag .. " " .. name,
                action = "equipped:" .. slot,
            }
        else
            items[#items + 1] = {
                label = "^8" .. SLOT_LABELS[slot] .. " (empty " .. SLOT_NAMES[slot] .. ")",
                action = "none",
            }
        end
    end

    -- Inventory gear section
    items[#items + 1] = { label = "^3--- Inventory ---", action = "none" }
    local hasGear = false
    for i, itemId in ipairs(game.player.inventory) do
        local itemDef = RPG.Data.Items[itemId]
        if itemDef and GEAR_TYPES[itemDef.type] then
            hasGear = true
            local name = RPG.Data.GetItemName(itemId)
            items[#items + 1] = {
                label = RPG.Config.ITEM_COLOR .. name .. " ^8[" .. itemDef.type .. "]",
                action = "inv:" .. i,
                invIndex = i,
                itemId = itemId,
            }
        end
    end
    if not hasGear then
        items[#items + 1] = { label = "^8  (no gear in inventory)", action = "none" }
    end

    return items
end

local function BuildSuppliesTab(game, state)
    local items = {}
    local hasItems = false

    for i, itemId in ipairs(game.player.inventory) do
        local itemDef = RPG.Data.Items[itemId]
        if itemDef and itemDef.type == "consumable" then
            hasItems = true
            local name = RPG.Data.GetItemName(itemId)
            -- Effect hint
            local hint = ""
            if itemDef.healAmount then
                hint = " ^8[+" .. itemDef.healAmount .. " HP]"
            elseif itemDef.curePoison then
                hint = " ^8[Antidote]"
            elseif itemDef.damageBonus then
                hint = " ^8[+" .. itemDef.damageBonus .. " DMG]"
            elseif itemDef.applyPoison then
                hint = " ^8[Poison]"
            end
            items[#items + 1] = {
                label = RPG.Config.ITEM_COLOR .. name .. hint,
                action = "inv:" .. i,
                invIndex = i,
                itemId = itemId,
            }
        end
    end

    if not hasItems then
        items[#items + 1] = { label = "^8  (no supplies)", action = "none" }
    end

    return items
end

local function BuildQuestTab(game, state)
    local items = {}
    local hasItems = false

    for i, itemId in ipairs(game.player.inventory) do
        local itemDef = RPG.Data.Items[itemId]
        if itemDef and QUEST_TYPES[itemDef.type] then
            hasItems = true
            local name = RPG.Data.GetItemName(itemId)
            items[#items + 1] = {
                label = RPG.Config.ITEM_COLOR .. name .. " ^8[" .. itemDef.type .. "]",
                action = "inv:" .. i,
                invIndex = i,
                itemId = itemId,
            }
        end
    end

    if not hasItems then
        items[#items + 1] = { label = "^8  (no quest items)", action = "none" }
    end

    return items
end

-- ============================================
-- Context Action Injection
-- ============================================

local function InjectContextActions(items, expandedAction, state, game)
    if not expandedAction then return end

    local tabName = TAB_NAMES[state.tab] or "GEAR"

    if expandedAction.type == "equipped" then
        -- Find the equipped item row
        for i = 1, #items do
            if items[i].action == "equipped:" .. expandedAction.slot then
                table.insert(items, i + 1, {
                    label = "  ^3Examine",
                    action = "ctx_examine_eq:" .. expandedAction.slot,
                })
                table.insert(items, i + 2, {
                    label = "  ^1Unequip",
                    action = "ctx_unequip:" .. expandedAction.slot,
                })
                state.selection = i + 1
                break
            end
        end
    elseif expandedAction.type == "inventory" then
        -- Find the inventory item row
        for i = 1, #items do
            if items[i].action == "inv:" .. expandedAction.invIndex then
                local offset = 1
                -- Examine (always)
                table.insert(items, i + offset, {
                    label = "  ^3Examine",
                    action = "ctx_examine_inv:" .. expandedAction.invIndex,
                })
                offset = offset + 1

                local itemDef = RPG.Data.Items[expandedAction.itemId]

                if tabName == "GEAR" then
                    -- Equip (only if equippable)
                    if itemDef and itemDef.slot then
                        table.insert(items, i + offset, {
                            label = "  ^2Equip",
                            action = "ctx_equip:" .. expandedAction.invIndex,
                        })
                        offset = offset + 1
                    end
                    -- Drop
                    table.insert(items, i + offset, {
                        label = "  ^1Drop",
                        action = "ctx_drop:" .. expandedAction.invIndex,
                    })
                elseif tabName == "SUPPLIES" then
                    -- Use (if healAmount — usable outside combat)
                    if itemDef and itemDef.healAmount then
                        table.insert(items, i + offset, {
                            label = "  ^2Use",
                            action = "ctx_use:" .. expandedAction.invIndex,
                        })
                        offset = offset + 1
                    end
                    -- Drop
                    table.insert(items, i + offset, {
                        label = "  ^1Drop",
                        action = "ctx_drop:" .. expandedAction.invIndex,
                    })
                end
                -- QUEST tab: examine only (already inserted above)

                state.selection = i + 1
                break
            end
        end
    end
end

-- ============================================
-- Quest-reactive examine hooks
-- Returns true if hooks changed state (skip detail view)
-- ============================================
local function RunExamineHooks(player, game, itemId, state)
    -- Holocron examine hook: triggers Ghosts of the Enclave quest
    if itemId == RPG.Config.HOLOCRON_ITEM_ID and game.player.hasHolocron then
        -- Start Ghosts of the Enclave quest on first Holocron examine
        if RPG.Quest and not game.quests["ghosts_enclave"] then
            RPG.Quest.Start(player, "ghosts_enclave")
        end
        -- Fire item_examine event for quest triggers
        if RPG.Quest and RPG.Quest.OnEvent then
            RPG.Quest.OnEvent(player, "item_examine", { itemId = itemId })
        end
        -- Open Saevus dialogue if available
        local saevusNpc = RPG.Data.NPCs[RPG.Config.SAEVUS_NPC_ID]
        if saevusNpc and saevusNpc.dialogueFile then
            RPG.Dialogue.Start(player, RPG.Config.SAEVUS_NPC_ID)
            return true
        end
        -- Fallback: show description in chat
        player:SendPrint("")
        player:SendPrint("^1The Holocron pulses in your hands. Whispers fill your mind.")
        player:SendPrint("^1A voice: \"You seek knowledge. I can provide it... for a price.\"")
        player:SendPrint("")
        return true
    end

    -- Shadow's Datapad: quest-aware examine
    if itemId == RPG.Config.SHADOW_DATAPAD_ID then
        local questStage = RPG.Quest and RPG.Quest.GetStage(game, "shadows_trail")
        if questStage == "enclave_search" then
            if not RPG.Quest.GetVar(game, "shadows_trail", "shadow_decrypt_done") then
                RPG.SetState(player, "datapad_decrypt")
                return true
            end
            player:SendPrint("^2[Already Decoded]")
            player:SendPrint("^7Coordinates to a Sith academy in the Unknown Regions.")
            return true
        elseif questStage == "decoded" or questStage == "complete" then
            player:SendPrint("^2[Already Decoded]")
            player:SendPrint("^7Coordinates to a Sith academy in the Unknown Regions.")
            return true
        elseif questStage == "decrypt" then
            player:SendPrint("^3The encryption is dense. Archivist Tamas mentioned a cipher key in the Enclave sublevel...")
            return true
        end
    end

    -- Generic item_examine event for future quest-reactive items
    if RPG.Quest and RPG.Quest.OnEvent then
        RPG.Quest.OnEvent(player, "item_examine", { itemId = itemId })
        local curGame = RPG.GetGame(player)
        if not curGame or curGame.state ~= "inventory" then
            return true  -- event handler changed state
        end
    end

    -- Cipher fragment discovery on examine
    if RPG.Cipher and RPG.Cipher.OnItemExamined then
        RPG.Cipher.OnItemExamined(player, game, itemId)
    end

    return false
end

-- ============================================
-- Context Action Handler
-- ============================================
local function HandleContextAction(player, action, state)
    local game = RPG.GetGame(player)
    if not game then return end

    -- Examine equipped item → enter detail view
    if string.StartsWith(action, "ctx_examine_eq:") then
        local slot = action:sub(#"ctx_examine_eq:" + 1)
        local itemId = game.player.equipped[slot]
        if not itemId then return end

        -- Run quest hooks first
        if RunExamineHooks(player, game, itemId, state) then
            state.data.expandedAction = nil
            return
        end

        state.data.expandedAction = nil
        state.data.examineItem = { itemId = itemId, compareSlot = false }
        state.selection = 1  -- Reset scroll to top of examine view
        Menu.InvalidateCache(player)
        return
    end

    -- Examine inventory item → enter detail view
    if string.StartsWith(action, "ctx_examine_inv:") then
        local idx = tonumber(action:sub(#"ctx_examine_inv:" + 1))
        if not idx then return end
        local itemId = game.player.inventory[idx]
        if not itemId then return end

        -- Run quest hooks first
        if RunExamineHooks(player, game, itemId, state) then
            state.data.expandedAction = nil
            return
        end

        local itemDef = RPG.Data.Items[itemId]
        local canCompare = itemDef and itemDef.slot and true or false
        state.data.expandedAction = nil
        state.data.examineItem = { itemId = itemId, compareSlot = canCompare }
        state.selection = 1  -- Reset scroll to top of examine view
        Menu.InvalidateCache(player)
        return
    end

    -- Equip
    if string.StartsWith(action, "ctx_equip:") then
        local idx = tonumber(action:sub(#"ctx_equip:" + 1))
        if idx then RPG.EquipItem(player, idx) end
        state.data.expandedAction = nil
        Menu.InvalidateCache(player)
        return
    end

    -- Unequip
    if string.StartsWith(action, "ctx_unequip:") then
        local slot = action:sub(#"ctx_unequip:" + 1)
        RPG.UnequipItem(player, slot)
        state.data.expandedAction = nil
        Menu.InvalidateCache(player)
        return
    end

    -- Drop
    if string.StartsWith(action, "ctx_drop:") then
        local idx = tonumber(action:sub(#"ctx_drop:" + 1))
        if idx then RPG.DropItem(player, idx) end
        state.data.expandedAction = nil
        Menu.InvalidateCache(player)
        return
    end

    -- Use consumable
    if string.StartsWith(action, "ctx_use:") then
        local idx = tonumber(action:sub(#"ctx_use:" + 1))
        if idx then RPG.UseItem(player, idx) end
        state.data.expandedAction = nil
        Menu.InvalidateCache(player)
        return
    end
end

-- ============================================
-- Menu Registration
-- ============================================

Menu.Register("rpg_inventory", {
    title = "\n^3INVENTORY^7",

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "" end

        local count = #game.player.inventory
        local max = RPG.Config.MAX_INVENTORY
        return "^7Items: " .. count .. "/" .. max .. "  ^7| ^3Credits: ^2" .. game.player.credits
    end,

    tabs = TAB_NAMES,
    navigationCacheHeader = true,

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game then
            return { { label = "^1No active game", action = "none" } }
        end

        if not state.data then state.data = {} end

        -- Examine detail view overrides the item list
        if state.data.examineItem then
            return BuildExamineView(state.data.examineItem, game)
        end

        -- Build items for current tab
        local tabName = TAB_NAMES[state.tab] or "GEAR"
        local items

        if tabName == "GEAR" then
            items = BuildGearTab(game, state)
        elseif tabName == "SUPPLIES" then
            items = BuildSuppliesTab(game, state)
        elseif tabName == "QUEST" then
            items = BuildQuestTab(game, state)
        else
            items = {}
        end

        -- Inject inline context actions if an item is expanded
        InjectContextActions(items, state.data.expandedAction, state, game)

        return items
    end,

    onAction = function(player, action, state, selectedItem)
        local game = RPG.GetGame(player)
        if not game then return end
        if not state.data then state.data = {} end

        -- Back from examine view
        if action == "examine_back" then
            state.data.examineItem = nil
            Menu.InvalidateCache(player)
            return
        end

        -- Handle context actions (ctx_*)
        if string.StartsWith(action, "ctx_") then
            HandleContextAction(player, action, state)
            return
        end

        -- Select equipped item → toggle expand
        if string.StartsWith(action, "equipped:") then
            local slot = action:sub(#"equipped:" + 1)
            local itemId = game.player.equipped[slot]
            if not itemId then return end

            -- Toggle: collapse if same item
            local ea = state.data.expandedAction
            if ea and ea.type == "equipped" and ea.slot == slot then
                state.data.expandedAction = nil
            else
                state.data.expandedAction = { type = "equipped", slot = slot, itemId = itemId }
            end
            Menu.InvalidateCache(player)
            return
        end

        -- Select inventory item → toggle expand
        if string.StartsWith(action, "inv:") then
            local idx = tonumber(action:sub(#"inv:" + 1))
            if not idx then return end
            local itemId = game.player.inventory[idx]
            if not itemId then return end

            -- Toggle: collapse if same item
            local ea = state.data.expandedAction
            if ea and ea.type == "inventory" and ea.invIndex == idx then
                state.data.expandedAction = nil
            else
                state.data.expandedAction = { type = "inventory", invIndex = idx, itemId = itemId }
            end
            Menu.InvalidateCache(player)
            return
        end
    end,

    onBack = function(player, state)
        if not state.data then state.data = {} end

        -- Back from examine → return to item list
        if state.data.examineItem then
            state.data.examineItem = nil
            Menu.InvalidateCache(player)
            return true  -- handled, stay in menu
        end

        -- Back while expanded → collapse
        if state.data.expandedAction then
            state.data.expandedAction = nil
            Menu.InvalidateCache(player)
            return true  -- handled, stay in menu
        end

        -- Normal back → exit inventory
        RPG.SetState(player, "exploration")
        return true
    end,

    onBeforeTabSwitch = function(player, state, direction)
        if state.data then
            state.data.expandedAction = nil
            state.data.examineItem = nil
        end
    end,

    controls = function(player, state)
        if state.data and state.data.examineItem then
            return "^3W/S^7=Scroll  ^3USE/ALT^7=Back"
        end
        if state.data and state.data.expandedAction then
            return "^3A/D^7=Tab ^3W/S^7=Nav ^3USE^7=Confirm ^3ALT^7=Back"
        end
        return "^3A/D^7=Tab ^3W/S^7=Nav ^3USE^7=Select ^3ALT^7=Back"
    end,

    maxVisibleItems = 10,
})

return true
