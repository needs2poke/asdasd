-- Echoes of the Dark Wars - Shop Menu
-- Buy/sell interface for vendor NPCs

RPG = RPG or {}

-- Default barks (fallback when vendor has no custom barks)
local DEFAULT_BUY_BARKS = { "^7'^3Transaction complete.'^7" }
local DEFAULT_SELL_BARKS = { "^7'^3Sold.'^7" }
local DEFAULT_HOSTILE_BUY_BARKS = { "^7'^1Marked-up price. Take it or leave.'^7" }
local DEFAULT_NO_CREDITS_BARKS = { "^7'^1Not enough credits.'^7" }

local function RandomBark(pool)
    return pool[math.random(1, #pool)]
end

local function GetVendorBarks(npcId, barkType)
    local vendorData = RPG.Data.Vendors and RPG.Data.Vendors[npcId]
    if vendorData and vendorData.barks and vendorData.barks[barkType] then
        return vendorData.barks[barkType]
    end
    if barkType == "buy" then return DEFAULT_BUY_BARKS end
    if barkType == "sell" then return DEFAULT_SELL_BARKS end
    if barkType == "hostileBuy" then return DEFAULT_HOSTILE_BUY_BARKS end
    if barkType == "noCredits" then return DEFAULT_NO_CREDITS_BARKS end
    return DEFAULT_BUY_BARKS
end

local function CalcPrice(baseValue, modifier)
    return math.max(1, math.floor(baseValue * modifier + 0.5))
end

local function GetPriceModifier(game, npcId)
    local vendorData = RPG.Data.Vendors and RPG.Data.Vendors[npcId]
    local flags = vendorData and vendorData.flags
    if not flags then return 1.0 end
    if RPG.Quest and RPG.Quest.HasFlag then
        if flags.hostile and RPG.Quest.HasFlag(game, flags.hostile) then return 2.0 end
        if flags.discountFull and RPG.Quest.HasFlag(game, flags.discountFull) then return 0.8 end
        if flags.discountSmall and RPG.Quest.HasFlag(game, flags.discountSmall) then return 0.9 end
    end
    return 1.0
end

local function GetDiscountLabel(modifier)
    if modifier >= 2.0 then return "^12x prices" end
    if modifier <= 0.8 then return "^220% off" end
    if modifier <= 0.9 then return "^210% off" end
    return "^7Standard"
end

local function IsHostile(game, npcId)
    local vendorData = RPG.Data.Vendors and RPG.Data.Vendors[npcId]
    local flags = vendorData and vendorData.flags
    if not flags or not flags.hostile then return false end
    return RPG.Quest and RPG.Quest.HasFlag and RPG.Quest.HasFlag(game, flags.hostile)
end

local function InitVendorStock(game, npcId)
    if not game.vendorStock then
        game.vendorStock = {}
    end
    if not game.vendorStock[npcId] then
        local vendorData = RPG.Data.Vendors and RPG.Data.Vendors[npcId]
        if not vendorData then return nil end
        -- Deep-copy stock
        game.vendorStock[npcId] = { stock = {}, hostileStock = {}, hiddenStock = {} }
        for _, entry in ipairs(vendorData.stock or {}) do
            game.vendorStock[npcId].stock[#game.vendorStock[npcId].stock + 1] = {
                itemId = entry.itemId,
                qty = entry.qty,
            }
        end
        for _, entry in ipairs(vendorData.hostileStock or {}) do
            game.vendorStock[npcId].hostileStock[#game.vendorStock[npcId].hostileStock + 1] = {
                itemId = entry.itemId,
                qty = entry.qty,
            }
        end
        for _, entry in ipairs(vendorData.hiddenStock or {}) do
            game.vendorStock[npcId].hiddenStock[#game.vendorStock[npcId].hiddenStock + 1] = {
                itemId = entry.itemId,
                qty = entry.qty,
            }
        end
    end
    return game.vendorStock[npcId]
end

local GEAR_TYPES = { weapon = true, armor = true, accessory = true, misc = true, crystal = true }
local TAB_NAMES = { "SUPPLIES", "GEAR", "SELL" }

-- Shared helper: iterate all stock pools and return items matching typeFilter
local function BuildStockItems(player, state, typeFilter, emptyMsg)
    local game = RPG.GetGame(player)
    if not game then return {} end

    local npcId = (state.data and state.data.vendorNpcId) or 1
    local vendorStock = InitVendorStock(game, npcId)
    if not vendorStock then return {} end

    local modifier = GetPriceModifier(game, npcId)
    local hostile = IsHostile(game, npcId)
    local vendorData = RPG.Data.Vendors and RPG.Data.Vendors[npcId]
    local hiddenFlag = vendorData and vendorData.hiddenStockFlag
    local hasHidden = hiddenFlag and RPG.Quest and RPG.Quest.HasFlag
        and RPG.Quest.HasFlag(game, hiddenFlag)

    local items = {}

    local function AddFromPool(pool, poolName, color)
        for stockIdx, entry in ipairs(pool) do
            local itemDef = RPG.Data.Items[entry.itemId]
            if itemDef and typeFilter(itemDef.type) then
                local price = CalcPrice(itemDef.value or 0, modifier)
                if entry.qty == 0 then
                    items[#items + 1] = {
                        label = color .. itemDef.name .. " ^8- SOLD OUT",
                        action = "none",
                        stockIdx = stockIdx,
                        pool = poolName,
                        itemId = entry.itemId,
                    }
                else
                    local qtyText = ""
                    if entry.qty > 0 then
                        qtyText = " ^8(x" .. entry.qty .. ")"
                    end
                    items[#items + 1] = {
                        label = color .. itemDef.name .. " ^7- ^3" .. price .. "cr" .. qtyText,
                        action = "buy",
                        stockIdx = stockIdx,
                        pool = poolName,
                        itemId = entry.itemId,
                    }
                end
            end
        end
    end

    AddFromPool(vendorStock.stock, "main", "^5")
    if hostile then
        AddFromPool(vendorStock.hostileStock, "hostile", "^1")
    end
    if hasHidden and vendorStock.hiddenStock then
        AddFromPool(vendorStock.hiddenStock, "hidden", "^6")
    end

    if #items == 0 then
        items[#items + 1] = { label = emptyMsg, action = "none" }
    end

    return items
end

-- Build sellable inventory items (non-quest, non-equipped, value > 0)
local function BuildSellItems(player, state)
    local game = RPG.GetGame(player)
    if not game then return {} end

    local items = {}

    for invIndex, itemId in ipairs(game.player.inventory) do
        local itemDef = RPG.Data.Items[itemId]
        if itemDef and itemDef.type ~= "quest" then
            local val = itemDef.value
            if val and val > 0 then
                local sellPrice = CalcPrice(val * 0.5, 1.0)
                items[#items + 1] = {
                    label = "^5" .. itemDef.name .. " ^7- ^2+" .. sellPrice .. "cr",
                    action = "sell",
                    invIndex = invIndex,
                    itemId = itemId,
                }
            end
        end
    end

    if #items == 0 then
        items[#items + 1] = { label = "^8(Nothing to sell)", action = "none" }
    end

    return items
end

-- Buy transaction handler (shared by SUPPLIES and GEAR tabs)
local function HandleBuy(player, item, state)
    local game = RPG.GetGame(player)
    if not game then return end

    local npcId = (state.data and state.data.vendorNpcId) or 1
    local vendorStock = game.vendorStock and game.vendorStock[npcId]
    if not vendorStock then return end

    local modifier = GetPriceModifier(game, npcId)
    local hostile = IsHostile(game, npcId)

    local stockIdx = item.stockIdx
    local pool = item.pool
    if not stockIdx then return end

    local stockList
    if pool == "hostile" then
        stockList = vendorStock.hostileStock
    elseif pool == "hidden" then
        stockList = vendorStock.hiddenStock
    else
        stockList = vendorStock.stock
    end

    local entry = stockList and stockList[stockIdx]
    if not entry then return end

    local itemDef = RPG.Data.Items[entry.itemId]
    if not itemDef then return end

    local price = CalcPrice(itemDef.value or 0, modifier)

    -- Check stock
    if entry.qty == 0 then
        player:SendPrint("^1That item is sold out.")
        return
    end

    -- Check credits
    if game.player.credits < price then
        player:SendPrint("^1Not enough credits. Need ^3" .. price .. "cr^1.")
        player:SendPrint(RandomBark(GetVendorBarks(npcId, "noCredits")))
        return
    end

    -- Check inventory space
    if #game.player.inventory >= RPG.Config.MAX_INVENTORY then
        player:SendPrint("^1Inventory full. Can't carry any more.")
        return
    end

    -- Execute purchase
    game.player.credits = game.player.credits - price
    game.player.inventory[#game.player.inventory + 1] = entry.itemId
    if entry.qty > 0 then
        entry.qty = entry.qty - 1
    end

    player:SendPrint("^2Bought ^5" .. itemDef.name .. "^2 for ^3" .. price .. "cr^2.")
    if hostile then
        player:SendPrint(RandomBark(GetVendorBarks(npcId, "hostileBuy")))
    else
        player:SendPrint(RandomBark(GetVendorBarks(npcId, "buy")))
    end

    Menu.InvalidateCache(player)
end

-- Sell transaction handler (SELL tab)
local function HandleSell(player, item, state)
    local game = RPG.GetGame(player)
    if not game then return end

    local npcId = (state.data and state.data.vendorNpcId) or 1
    local invIndex = item.invIndex
    if not invIndex then return end

    local itemId = game.player.inventory[invIndex]
    if not itemId then return end

    local itemDef = RPG.Data.Items[itemId]
    if not itemDef then return end

    -- Block quest items
    if itemDef.type == "quest" then
        player:SendPrint("^1You can't sell quest items.")
        return
    end

    -- Calculate sell price
    local val = itemDef.value
    if not val or val <= 0 then
        player:SendPrint("^1That item has no trade value.")
        return
    end
    local sellPrice = CalcPrice(val * 0.5, 1.0)

    -- Execute sale
    table.remove(game.player.inventory, invIndex)
    game.player.credits = game.player.credits + sellPrice

    player:SendPrint("^2Sold ^5" .. itemDef.name .. "^2 for ^3" .. sellPrice .. "cr^2.")
    player:SendPrint(RandomBark(GetVendorBarks(npcId, "sell")))

    Menu.InvalidateCache(player)
end

local function ShowItemExamine(player, itemId)
    local itemDef = RPG.Data.Items[itemId]
    if not itemDef then return end
    local name = RPG.Data.GetItemName(itemId)
    player:SendPrint("")
    player:SendPrint(RPG.Config.ITEM_COLOR .. "=== " .. name .. " ===^7")
    if itemDef.description then
        player:SendPrint("^7" .. itemDef.description)
    end
    if itemDef.examineText then
        player:SendPrint("")
        player:SendPrint("^7" .. itemDef.examineText)
    end
    if itemDef.damage then
        player:SendPrint("^2Damage: " .. itemDef.damage)
    end
    if itemDef.defense then
        player:SendPrint("^2Defense: " .. itemDef.defense)
    end
    if itemDef.statBonus then
        for stat, bonus in pairs(itemDef.statBonus) do
            player:SendPrint("^2+" .. bonus .. " " .. stat)
        end
    end
    if itemDef.healAmount then
        player:SendPrint("^2Heals: " .. itemDef.healAmount .. " HP")
    end
    if itemDef.curePoison then
        player:SendPrint("^2Cures Poison")
    end
    if itemDef.damageBonus then
        player:SendPrint("^2+" .. itemDef.damageBonus .. " Damage bonus")
    end
    player:SendPrint("")
end

Menu.Register("rpg_shop", {
    title = "^3=== SHOP ===^7",

    header = function(player, state)
        local game = RPG.GetGame(player)
        if not game then return "" end
        local npcId = (state.data and state.data.vendorNpcId) or 1
        local modifier = GetPriceModifier(game, npcId)
        local label = GetDiscountLabel(modifier)
        return "^3Credits: ^2" .. game.player.credits .. "  ^7| ^3Discount: " .. label
    end,

    tabs = { "SUPPLIES", "GEAR", "SELL" },
    navigationCacheHeader = true,

    tabContent = {
        SUPPLIES = {
            items = nil,
            onSelect = function(player, item, state)
                if not state.data then state.data = {} end
                if item.action == "shop_buy" then
                    local pending = state.data.shopPending
                    if pending then
                        state.data.shopPending = nil
                        HandleBuy(player, pending, state)
                    end
                elseif item.action == "shop_examine" then
                    local pending = state.data.shopPending
                    if pending then
                        ShowItemExamine(player, pending.itemId)
                        state.data.shopPending = nil
                        Menu.InvalidateCache(player)
                    end
                elseif item.action == "buy" then
                    state.data.shopPending = {
                        tab = state.tab,
                        itemId = item.itemId,
                        stockIdx = item.stockIdx,
                        pool = item.pool,
                    }
                    Menu.InvalidateCache(player)
                end
            end,
        },
        GEAR = {
            items = nil,
            onSelect = function(player, item, state)
                if not state.data then state.data = {} end
                if item.action == "shop_buy" then
                    local pending = state.data.shopPending
                    if pending then
                        state.data.shopPending = nil
                        HandleBuy(player, pending, state)
                    end
                elseif item.action == "shop_examine" then
                    local pending = state.data.shopPending
                    if pending then
                        ShowItemExamine(player, pending.itemId)
                        state.data.shopPending = nil
                        Menu.InvalidateCache(player)
                    end
                elseif item.action == "buy" then
                    state.data.shopPending = {
                        tab = state.tab,
                        itemId = item.itemId,
                        stockIdx = item.stockIdx,
                        pool = item.pool,
                    }
                    Menu.InvalidateCache(player)
                end
            end,
        },
        SELL = {
            items = nil,
            onSelect = function(player, item, state)
                if not state.data then state.data = {} end
                if item.action == "shop_sell" then
                    local pending = state.data.shopPending
                    if pending then
                        state.data.shopPending = nil
                        HandleSell(player, pending, state)
                    end
                elseif item.action == "shop_examine" then
                    local pending = state.data.shopPending
                    if pending then
                        ShowItemExamine(player, pending.itemId)
                        state.data.shopPending = nil
                        Menu.InvalidateCache(player)
                    end
                elseif item.action == "sell" then
                    state.data.shopPending = {
                        tab = state.tab,
                        itemId = item.itemId,
                        invIndex = item.invIndex,
                    }
                    Menu.InvalidateCache(player)
                end
            end,
        },
    },

    getItems = function(player, state)
        local game = RPG.GetGame(player)
        if not game then
            return { { label = "^1No active game", action = "none" } }
        end

        local npcId = (state.data and state.data.vendorNpcId) or 1
        local vendorStock = InitVendorStock(game, npcId)
        if not vendorStock then
            return { { label = "^1Shop unavailable", action = "none" } }
        end

        local tabName = TAB_NAMES[state.tab] or "SUPPLIES"
        local items

        if tabName == "SUPPLIES" then
            items = BuildStockItems(player, state,
                function(t) return t == "consumable" end,
                "^8(No supplies available)")
        elseif tabName == "GEAR" then
            items = BuildStockItems(player, state,
                function(t) return GEAR_TYPES[t] == true end,
                "^8(No gear available)")
        elseif tabName == "SELL" then
            items = BuildSellItems(player, state)
        else
            return {}
        end

        -- Inject context rows for pending selection
        local pending = state.data and state.data.shopPending
        if pending then
            if pending.tab ~= state.tab then
                state.data.shopPending = nil
            else
                local found = false
                local modifier = GetPriceModifier(game, npcId)
                for i = 1, #items do
                    local match = false
                    if tabName == "SELL" then
                        match = (items[i].invIndex == pending.invIndex
                            and items[i].itemId == pending.itemId)
                    else
                        match = (items[i].stockIdx == pending.stockIdx
                            and items[i].pool == pending.pool)
                    end
                    if match then
                        found = true
                        local itemDef = RPG.Data.Items[pending.itemId]
                        if tabName == "SELL" then
                            local val = itemDef and itemDef.value or 0
                            local sellPrice = CalcPrice(val * 0.5, 1.0)
                            table.insert(items, i + 1, {
                                label = "  ^1Sell (+" .. sellPrice .. "cr)",
                                action = "shop_sell",
                            })
                        else
                            local price = CalcPrice(
                                (itemDef and itemDef.value or 0), modifier)
                            table.insert(items, i + 1, {
                                label = "  ^2Buy (" .. price .. "cr)",
                                action = "shop_buy",
                            })
                        end
                        table.insert(items, i + 2, {
                            label = "  ^3Examine",
                            action = "shop_examine",
                            itemId = pending.itemId,
                        })
                        state.selection = i + 1
                        break
                    end
                end
                if not found then
                    state.data.shopPending = nil
                end
            end
        end

        return items
    end,

    onBack = function(player, state)
        if state.data then state.data.shopPending = nil end
        RPG.SetState(player, "exploration")
        return true
    end,

    controls = function(player, state)
        local pending = state.data and state.data.shopPending
        local tabName = TAB_NAMES[state.tab] or "SUPPLIES"
        local actionHint
        if pending then
            actionHint = "^3USE^7=Confirm"
        elseif tabName == "SELL" then
            actionHint = "^3USE^7=Sell"
        else
            actionHint = "^3USE^7=Buy"
        end
        return "^3A/D^7=Tab ^3W/S^7=Nav " .. actionHint .. " ^3ALT^7=Back"
    end,

    maxVisibleItems = 12,
})

return true
