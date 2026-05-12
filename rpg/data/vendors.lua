-- Echoes of the Dark Wars - Vendor Data
-- Inventory definitions for merchant NPCs

RPG = RPG or {}
RPG.Data = RPG.Data or {}

RPG.Data.Vendors = {
    [1] = {  -- NPC ID 1 = Merchant Goran
        name = "Merchant Goran",
        barks = {
            buy = {
                "^7Goran: '^3Pleasure doing business.'^7",
                "^7Goran: '^3Good choice. Don't break it.'^7",
                "^7Goran: '^3Try not to die before you use that.'^7",
            },
            sell = {
                "^7Goran: '^3I'll find a buyer. Eventually.'^7",
                "^7Goran: '^3Salvage is salvage.'^7",
            },
            hostileBuy = {
                "^7Goran: '^1Double price. Take it or leave.'^7",
                "^7Goran: '^1You're lucky I'm selling to you at all.'^7",
            },
            noCredits = {
                "^7Goran: '^1Credits first. Charity later.'^7",
                "^7Goran: '^1Come back when you can pay.'^7",
            },
        },
        flags = {
            hostile = "goran_hostile",
            discountFull = "goran_discount_full",
            discountSmall = "goran_discount_small",
        },
        stock = {
            -- Consumables (unlimited)
            { itemId = 19, qty = -1 },  -- Field Rations
            { itemId = 3,  qty = -1 },  -- Medpac
            { itemId = 12, qty = -1 },  -- Arkanian Medpac
            { itemId = 18, qty = -1 },  -- Adrenal Stimulant
            { itemId = 13, qty = 3 },   -- Antidote Kit (limited)
            -- Equipment (limited)
            { itemId = 16, qty = 1 },   -- Mandalorian Mesh Vest
            { itemId = 14, qty = 1 },   -- Echani Vibroblade
            { itemId = 15, qty = 1 },   -- Czerka Scorpion Blaster
            { itemId = 17, qty = 1 },   -- Jal Shey Utility Belt
            -- Misc / Artifact
            { itemId = 20, qty = 1 },   -- Faded Jedi Holorecord
            { itemId = 21, qty = 1 },   -- Sith War Blade
        },
        -- Hostile-exclusive stock (only shown when goran_hostile is set)
        hostileStock = {
            { itemId = 22, qty = 2 },   -- Exchange Nerve Toxin
            { itemId = 23, qty = 2 },   -- Sliced Stim Injector
        },
    },
    [13] = {  -- NPC ID 13 = Rila (Street Vendor)
        name = "Rila",
        barks = {
            buy = {
                "^7Rila: '^3Good taste.'^7",
                "^7Rila: '^3Careful with that one.'^7",
            },
            sell = {
                "^7Rila: '^3I know someone who needs this.'^7",
                "^7Rila: '^3Salvage finds a home.'^7",
            },
            noCredits = {
                "^7Rila: '^1No credits, no goods. Simple.'^7",
            },
        },
        hiddenStockFlag = "rila_trusts",
        stock = {
            -- Consumables (unlimited)
            { itemId = 3,  qty = -1 },  -- Medpac
            { itemId = 19, qty = -1 },  -- Field Rations
            { itemId = 18, qty = 3 },   -- Adrenal Stimulant
            { itemId = 13, qty = 2 },   -- Antidote Kit
        },
        -- Hidden stock (only shown when rila_trusts flag is set)
        hiddenStock = {
            { itemId = 28, qty = 1 },   -- Beast Rider Gauntlets
            { itemId = 29, qty = 2 },   -- Dxun Jungle Extract
        },
    },
}

-- Validate vendor stock references valid items
if RPG.Data.Items then
    for vendorId, vendor in pairs(RPG.Data.Vendors) do
        local allStock = {}
        for _, entry in ipairs(vendor.stock or {}) do
            allStock[#allStock + 1] = entry
        end
        for _, entry in ipairs(vendor.hostileStock or {}) do
            allStock[#allStock + 1] = entry
        end
        for _, entry in ipairs(vendor.hiddenStock or {}) do
            allStock[#allStock + 1] = entry
        end
        for _, entry in ipairs(allStock) do
            if not RPG.Data.Items[entry.itemId] then
                GLua.Warn("RPG Vendor " .. vendorId .. ": unknown itemId " .. tostring(entry.itemId))
            end
        end
    end
end

return RPG.Data.Vendors
