--[[
    OGz PropManager v3.4 - SERVER World Props
    
    ═══════════════════════════════════════════════════════════════════════════
    Handles: Cooldowns, Rewards, Harvesting, Stashes, Shops
    ═══════════════════════════════════════════════════════════════════════════
]]

if not Config.Features.WorldProps then return end

local QBX = exports.qbx_core
local tablePrefix = Config.Database.TablePrefix

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetPlayer(source) return QBX:GetPlayer(source) end
local function GetCitizenId(source) local p = GetPlayer(source) return p and p.PlayerData.citizenid end
local function DebugPrint(...) if Config.Debug then print("[OGz WorldProps]", ...) end end

local function Notify(source, msg, type)
    TriggerClientEvent("ox_lib:notify", source, { description = msg, type = type or "info" })
end

local function FormatTime(seconds)
    if seconds < 60 then return string.format("%ds", seconds)
    elseif seconds < 3600 then return string.format("%dm", math.floor(seconds / 60))
    else return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CONFIG GETTERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetZoneConfig(zoneId)
    return WorldProps.Zones and WorldProps.Zones[zoneId]
end

local function GetLocationConfig(locationId)
    return WorldProps.Locations and WorldProps.Locations[locationId]
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

local function Database_Init()
    -- Cooldowns table - matches install.sql structure
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_worldprop_cooldowns` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `worldprop_id` VARCHAR(50) NOT NULL,
            `location_hash` VARCHAR(100) NOT NULL,
            `last_used` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_player_location` (`citizenid`, `worldprop_id`, `location_hash`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_worldprop` (`worldprop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    DebugPrint("Database tables initialized")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function GetCooldownKey(citizenid, configId, entityHash, cooldownType)
    if cooldownType == "player" then
        return citizenid, configId, nil
    elseif cooldownType == "player_location" or cooldownType == "player_entity" then
        return citizenid, configId, entityHash
    elseif cooldownType == "global" then
        return "GLOBAL", configId, nil
    elseif cooldownType == "global_entity" then
        return "GLOBAL", configId, entityHash
    else
        return citizenid, configId, entityHash
    end
end

local function Database_CheckCooldown(citizenid, configId, entityHash, cooldownType, cooldownSeconds)
    local cid, cConfig, cEntity = GetCooldownKey(citizenid, configId, entityHash, cooldownType)
    
    local query = [[
        SELECT TIMESTAMPDIFF(SECOND, last_used, NOW()) as seconds_since
        FROM `]] .. tablePrefix .. [[_worldprop_cooldowns`
        WHERE citizenid = ? AND worldprop_id = ? AND location_hash = ?
        ORDER BY last_used DESC LIMIT 1
    ]]
    local params = { cid, cConfig, cEntity or "global" }
    
    local result = MySQL.single.await(query, params)
    
    if not result then return false, 0 end
    
    local remaining = cooldownSeconds - (result.seconds_since or 0)
    if remaining > 0 then
        return true, remaining
    end
    return false, 0
end

local function Database_SetCooldown(citizenid, configId, entityHash, cooldownType)
    local cid, cConfig, cEntity = GetCooldownKey(citizenid, configId, entityHash, cooldownType)
    
    MySQL.query([[
        INSERT INTO `]] .. tablePrefix .. [[_worldprop_cooldowns`
        (citizenid, worldprop_id, location_hash, last_used)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE last_used = NOW()
    ]], { cid, cConfig, cEntity or "global" })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOOT ROLLING SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function RollLoot(items, minItems, maxItems)
    local results = {}
    local pool = {}
    
    -- Roll for each item
    for _, itemData in ipairs(items) do
        local roll = math.random(1, 100)
        if roll <= (itemData.chance or 100) then
            table.insert(pool, itemData)
        end
    end
    
    -- Guarantee at least one item if pool is empty
    if #pool == 0 and #items > 0 then
        table.insert(pool, items[math.random(#items)])
    end
    
    -- Pick items from pool
    local min = minItems or 1
    local max = maxItems or 3
    local itemCount = math.random(min, math.min(max, #pool))
    
    for i = 1, itemCount do
        if #pool == 0 then break end
        local idx = math.random(#pool)
        local selectedItem = pool[idx]
        local quantity = math.random(selectedItem.min or 1, selectedItem.max or 1)
        table.insert(results, { item = selectedItem.item, count = quantity })
        table.remove(pool, idx)
    end
    
    return results
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CALLBACKS (These are what the client calls!)
-- ═══════════════════════════════════════════════════════════════════════════

-- Zone-based cooldown check
lib.callback.register("ogz_propmanager:server:CheckZoneCooldown", function(source, zoneId, entityHash, interactionType)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false, 0 end
    
    local config = GetZoneConfig(zoneId)
    if not config then 
        DebugPrint("CheckZoneCooldown: Zone not found:", zoneId)
        return false, 0 
    end
    
    -- Determine cooldown config based on interaction type
    local cooldownConfig
    if interactionType == "harvest" and config.harvest then
        cooldownConfig = config.harvest.cooldown
    elseif interactionType == "reward" and config.reward then
        cooldownConfig = config.reward.cooldown
    else
        -- No cooldown for this type
        return false, 0
    end
    
    if not cooldownConfig or cooldownConfig.type == "none" then 
        return false, 0 
    end
    
    local cooldownTime = cooldownConfig.time or 300
    local cooldownType = cooldownConfig.type or "player_entity"
    
    DebugPrint("CheckZoneCooldown:", zoneId, "type:", cooldownType, "time:", cooldownTime)
    
    return Database_CheckCooldown(citizenid, zoneId, entityHash, cooldownType, cooldownTime)
end)

-- Location-based cooldown check (for original v3.0 system)
lib.callback.register("ogz_propmanager:server:CheckWorldPropCooldown", function(source, locationId, locationHash)
    local citizenid = GetCitizenId(source)
    if not citizenid then return true, 0 end
    
    local config = GetLocationConfig(locationId)
    if not config then return true, 0 end
    if config.type ~= "reward" then return false, 0 end
    
    local cooldownConfig = config.reward and config.reward.cooldown
    if not cooldownConfig or cooldownConfig.type == "none" then return false, 0 end
    
    local cooldownTime = cooldownConfig.time or 1800
    local cooldownType = cooldownConfig.type or "player_location"
    
    return Database_CheckCooldown(citizenid, locationId, locationHash, cooldownType, cooldownTime)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ZONE-BASED EVENTS (New v3.4)
-- ═══════════════════════════════════════════════════════════════════════════

-- HARVEST
RegisterNetEvent("ogz_propmanager:server:ZoneHarvest", function(zoneId, entityHash, coords)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local config = GetZoneConfig(zoneId)
    if not config or config.type ~= "harvest" then 
        DebugPrint("ZoneHarvest: Invalid zone or type:", zoneId)
        return 
    end
    
    local harvest = config.harvest
    if not harvest or not harvest.yields then
        DebugPrint("ZoneHarvest: No yields configured for:", zoneId)
        return
    end
    
    DebugPrint("ZoneHarvest:", citizenid, "harvesting from", zoneId)
    
    -- Roll yields
    local yields = RollLoot(harvest.yields, 1, #harvest.yields)
    
    if #yields == 0 then
        Notify(source, "Nothing to harvest", "info")
        return
    end
    
    -- Give items
    local givenItems = {}
    for _, yield in ipairs(yields) do
        if exports.ox_inventory:AddItem(source, yield.item, yield.count) then
            table.insert(givenItems, yield)
            DebugPrint("  Gave:", yield.item, "x", yield.count)
        end
    end
    
    if #givenItems > 0 then
        Notify(source, "Harvested successfully!", "success")
        
        -- Set cooldown
        local cooldownConfig = harvest.cooldown
        if cooldownConfig and cooldownConfig.type ~= "none" then
            Database_SetCooldown(citizenid, zoneId, entityHash, cooldownConfig.type)
        end
    else
        Notify(source, "Inventory full!", "error")
    end
end)

-- ZONE REWARD
RegisterNetEvent("ogz_propmanager:server:ZoneReward", function(zoneId, entityHash, coords)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local config = GetZoneConfig(zoneId)
    if not config or config.type ~= "reward" then return end
    
    local reward = config.reward
    if not reward or not reward.items then return end
    
    DebugPrint("ZoneReward:", citizenid, "searching in", zoneId)
    
    -- Roll loot
    local lootResults = RollLoot(reward.items, reward.minItems, reward.maxItems)
    
    if #lootResults == 0 then
        Notify(source, "You found nothing", "info")
        return
    end
    
    -- Give items
    local givenItems = {}
    for _, loot in ipairs(lootResults) do
        if exports.ox_inventory:AddItem(source, loot.item, loot.count) then
            table.insert(givenItems, loot)
        end
    end
    
    if #givenItems > 0 then
        Notify(source, "You found something!", "success")
        
        -- Set cooldown
        local cooldownConfig = reward.cooldown
        if cooldownConfig and cooldownConfig.type ~= "none" then
            Database_SetCooldown(citizenid, zoneId, entityHash, cooldownConfig.type)
        end
    else
        Notify(source, "Inventory full!", "error")
    end
end)

-- SET COOLDOWN (for custom interactions)
RegisterNetEvent("ogz_propmanager:server:SetZoneCooldown", function(zoneId, entityHash, cooldownConfig)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    if cooldownConfig and cooldownConfig.type ~= "none" then
        Database_SetCooldown(citizenid, zoneId, entityHash, cooldownConfig.type)
        DebugPrint("SetZoneCooldown:", citizenid, zoneId, cooldownConfig.type)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- LOCATION-BASED EVENTS (Original v3.0)
-- ═══════════════════════════════════════════════════════════════════════════

-- SHOP
RegisterNetEvent("ogz_propmanager:server:WorldPropShop", function(locationId, locationHash, itemName)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local config = GetLocationConfig(locationId)
    if not config or config.type ~= "shop" then return end
    
    -- Find item
    local shopItem = nil
    for _, item in ipairs(config.shop.items) do
        if item.item == itemName then
            shopItem = item
            break
        end
    end
    
    if not shopItem then
        Notify(source, "Item not available", "error")
        return
    end
    
    -- Check money
    local player = GetPlayer(source)
    if player.Functions.GetMoney('cash') < shopItem.price then
        Notify(source, "Not enough cash", "error")
        return
    end
    
    -- Purchase
    if player.Functions.RemoveMoney('cash', shopItem.price, 'worldprop-shop') then
        exports.ox_inventory:AddItem(source, shopItem.item, 1)
        Notify(source, "Purchased " .. (shopItem.label or shopItem.item), "success")
    end
end)

-- REWARD (location-based)
RegisterNetEvent("ogz_propmanager:server:WorldPropReward", function(locationId, locationHash)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local config = GetLocationConfig(locationId)
    if not config or config.type ~= "reward" then return end
    
    -- Roll loot
    local lootResults = RollLoot(config.reward.items, config.reward.minItems, config.reward.maxItems)
    
    if #lootResults == 0 then
        Notify(source, "You found nothing", "info")
        return
    end
    
    -- Give items
    local givenItems = {}
    for _, loot in ipairs(lootResults) do
        if exports.ox_inventory:AddItem(source, loot.item, loot.count) then
            table.insert(givenItems, loot)
        end
    end
    
    if #givenItems > 0 then
        Notify(source, "You found something!", "success")
        
        -- Set cooldown
        local cooldownConfig = config.reward.cooldown
        if cooldownConfig and cooldownConfig.type ~= "none" then
            Database_SetCooldown(citizenid, locationId, locationHash, cooldownConfig.type)
        end
    else
        Notify(source, "Inventory full!", "error")
    end
end)

-- STASH
RegisterNetEvent("ogz_propmanager:server:WorldPropStash", function(locationId, locationHash)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local config = GetLocationConfig(locationId)
    if not config or config.type ~= "stash" then return end
    
    local stashId = string.format("ogz_world_%s_%s", locationId, citizenid)
    local slots = config.stash.slots or 10
    local maxWeight = config.stash.maxWeight or 50000
    
    exports.ox_inventory:RegisterStash(stashId, config.label or "Stash", slots, maxWeight)
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
end)

-- CRAFTING
RegisterNetEvent("ogz_propmanager:server:WorldPropCrafting", function(locationId, locationHash, craftingTable)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local config = GetLocationConfig(locationId)
    if not config or config.type ~= "crafting" then return end
    
    TriggerClientEvent("ox_inventory:openInventory", source, 'crafting', { id = craftingTable })
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)
    Database_Init()
    
    local zoneCount = 0
    local locationCount = 0
    
    if WorldProps.Zones then
        for id, config in pairs(WorldProps.Zones) do
            if config.enabled ~= false then
                zoneCount = zoneCount + 1
            end
        end
    end
    
    if WorldProps.Locations then
        for id, _ in pairs(WorldProps.Locations) do
            locationCount = locationCount + 1
        end
    end
    
    print(string.format("^2[OGz PropManager v3.4]^0 WorldProps SERVER: %d zones, %d locations", zoneCount, locationCount))
end)
