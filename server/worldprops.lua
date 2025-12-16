--[[
    OGz PropManager v3.0 - Server World Props
    
    Location-based world prop interactions for shops, stashes, crafting, and rewards.
    PERFORMANCE OPTIMIZED: Only targets props at specific configured locations.
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
local function GetWorldPropConfig(propId) return WorldProps[propId] end

local function GetPlayerGang(source)
    local player = GetPlayer(source)
    return player and player.PlayerData.gang and player.PlayerData.gang.name or nil
end

local function GetPlayerJob(source)
    local player = GetPlayer(source)
    return player and player.PlayerData.job and player.PlayerData.job.name or nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function Database_InitWorldProps()
    -- Cooldowns for world props (per player per location)
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
    
    -- Per-player stashes at world locations
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_worldprop_stashes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `stash_id` VARCHAR(100) UNIQUE NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `worldprop_id` VARCHAR(50) NOT NULL,
            `location_hash` VARCHAR(100) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_player_worldstash` (`citizenid`, `worldprop_id`, `location_hash`),
            INDEX `idx_stash_id` (`stash_id`),
            INDEX `idx_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    DebugPrint("World props database tables initialized")
end

function Database_SetWorldPropCooldown(citizenid, worldpropId, locationHash)
    MySQL.query([[
        INSERT INTO `]] .. tablePrefix .. [[_worldprop_cooldowns` 
        (citizenid, worldprop_id, location_hash, last_used)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE last_used = NOW()
    ]], { citizenid, worldpropId, locationHash })
end

function Database_CheckWorldPropCooldown(citizenid, worldpropId, locationHash, cooldownSeconds)
    local result = MySQL.single.await([[
        SELECT last_used, TIMESTAMPDIFF(SECOND, last_used, NOW()) as seconds_since
        FROM `]] .. tablePrefix .. [[_worldprop_cooldowns` 
        WHERE citizenid = ? AND worldprop_id = ? AND location_hash = ?
    ]], { citizenid, worldpropId, locationHash })
    
    if not result then return false, 0 end
    
    local remaining = cooldownSeconds - (result.seconds_since or 0)
    if remaining > 0 then
        return true, remaining
    end
    return false, 0
end

function Database_GetOrCreateWorldStash(citizenid, worldpropId, locationHash)
    local existing = MySQL.single.await([[
        SELECT stash_id FROM `]] .. tablePrefix .. [[_worldprop_stashes` 
        WHERE citizenid = ? AND worldprop_id = ? AND location_hash = ?
    ]], { citizenid, worldpropId, locationHash })
    
    if existing then
        return existing.stash_id
    end
    
    -- Create new stash ID
    local stashId = string.format("ogz_world_%s_%s_%s", worldpropId, citizenid, os.time())
    
    MySQL.insert.await([[
        INSERT INTO `]] .. tablePrefix .. [[_worldprop_stashes` 
        (stash_id, citizenid, worldprop_id, location_hash)
        VALUES (?, ?, ?, ?)
    ]], { stashId, citizenid, worldpropId, locationHash })
    
    return stashId
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ACCESS CONTROL
-- ═══════════════════════════════════════════════════════════════════════════

function CanAccessWorldProp(source, worldPropConfig)
    if not worldPropConfig.visibleTo then return true end
    
    if worldPropConfig.visibleTo.gangs then
        local playerGang = GetPlayerGang(source)
        for _, gang in ipairs(worldPropConfig.visibleTo.gangs) do
            if playerGang == gang then return true end
        end
    end
    
    if worldPropConfig.visibleTo.jobs then
        local playerJob = GetPlayerJob(source)
        for _, job in ipairs(worldPropConfig.visibleTo.jobs) do
            if playerJob == job then return true end
        end
    end
    
    if worldPropConfig.visibleTo.gangs or worldPropConfig.visibleTo.jobs then
        return false
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOCATION HASH
-- ═══════════════════════════════════════════════════════════════════════════

function GetLocationHash(coords)
    -- Create a unique hash for this location (rounded to prevent floating point issues)
    local x = math.floor(coords.x * 100) / 100
    local y = math.floor(coords.y * 100) / 100
    local z = math.floor(coords.z * 100) / 100
    return string.format("%.2f_%.2f_%.2f", x, y, z)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- WORLD PROP INTERACTIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- SHOP TYPE
RegisterNetEvent("ogz_propmanager:server:WorldPropShop", function(worldpropId, locationHash, itemName)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local worldPropConfig = GetWorldPropConfig(worldpropId)
    if not worldPropConfig or worldPropConfig.type ~= "shop" then return end
    
    if not CanAccessWorldProp(source, worldPropConfig) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "You can't use this", "error")
        return
    end
    
    -- Find item in shop
    local shopItem = nil
    for _, item in ipairs(worldPropConfig.shop.items) do
        if item.item == itemName then
            shopItem = item
            break
        end
    end
    
    if not shopItem then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Item not available", "error")
        return
    end
    
    -- Check money
    local player = GetPlayer(source)
    if player.Functions.GetMoney('cash') < shopItem.price then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Not enough cash", "error")
        return
    end
    
    -- Purchase
    if player.Functions.RemoveMoney('cash', shopItem.price, 'world-prop-shop') then
        exports.ox_inventory:AddItem(source, shopItem.item, 1)
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Purchased " .. (shopItem.label or shopItem.item), "success")
        DebugPrint(citizenid, "purchased", shopItem.item, "from", worldpropId)
    end
end)

-- STASH TYPE (Per-Player)
RegisterNetEvent("ogz_propmanager:server:WorldPropStash", function(worldpropId, locationHash)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local worldPropConfig = GetWorldPropConfig(worldpropId)
    if not worldPropConfig or worldPropConfig.type ~= "stash" then return end
    
    if not CanAccessWorldProp(source, worldPropConfig) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "You can't access this", "error")
        return
    end
    
    -- Get or create player's stash for this location
    local stashId = Database_GetOrCreateWorldStash(citizenid, worldpropId, locationHash)
    
    -- Register stash if needed
    local slots = worldPropConfig.stash.slots or 10
    local maxWeight = worldPropConfig.stash.maxWeight or 50000
    
    exports.ox_inventory:RegisterStash(stashId, worldPropConfig.label, slots, maxWeight)
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
    
    DebugPrint(citizenid, "opened world stash", stashId, "at", worldpropId)
end)

-- CRAFTING TYPE
RegisterNetEvent("ogz_propmanager:server:WorldPropCrafting", function(worldpropId, locationHash, craftingTable)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local worldPropConfig = GetWorldPropConfig(worldpropId)
    if not worldPropConfig or worldPropConfig.type ~= "crafting" then return end
    
    if not CanAccessWorldProp(source, worldPropConfig) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "You can't use this", "error")
        return
    end
    
    -- Open crafting table
    exports.ox_inventory:openInventory('crafting', { id = craftingTable })
    DebugPrint(citizenid, "opened crafting", craftingTable, "at", worldpropId)
end)

-- REWARD TYPE
RegisterNetEvent("ogz_propmanager:server:WorldPropReward", function(worldpropId, locationHash)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local worldPropConfig = GetWorldPropConfig(worldpropId)
    if not worldPropConfig or worldPropConfig.type ~= "reward" then return end
    
    if not CanAccessWorldProp(source, worldPropConfig) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "You can't use this", "error")
        return
    end
    
    -- Check cooldown
    local cooldownConfig = worldPropConfig.reward.cooldown
    if cooldownConfig and cooldownConfig.type ~= "none" then
        local cooldownTime = cooldownConfig.time or 1800
        local onCooldown, remaining = Database_CheckWorldPropCooldown(citizenid, worldpropId, locationHash, cooldownTime)
        
        if onCooldown then
            TriggerClientEvent("ogz_propmanager:client:Notify", source, 
                string.format(Config.Notifications.WorldPropCooldown, FormatTime(remaining)), "error")
            return
        end
    end
    
    -- Roll loot (uses same system as lootables)
    local lootResults = RollWorldPropLoot(worldPropConfig.reward)
    
    if #lootResults == 0 then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.LootEmpty, "info")
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
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.LootFound, "success")
        
        -- Set cooldown
        if cooldownConfig and cooldownConfig.type ~= "none" then
            Database_SetWorldPropCooldown(citizenid, worldpropId, locationHash)
        end
        
        DebugPrint(citizenid, "got rewards from", worldpropId, "- Items:", #givenItems)
    else
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Inventory full!", "error")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- LOOT ROLLING (Same logic as lootables)
-- ═══════════════════════════════════════════════════════════════════════════

function RollWorldPropLoot(rewardConfig)
    local results = {}
    local pool = {}
    
    for _, itemData in ipairs(rewardConfig.items) do
        local roll = math.random(1, 100)
        if roll <= itemData.chance then
            table.insert(pool, itemData)
        end
    end
    
    if #pool == 0 and #rewardConfig.items > 0 then
        table.insert(pool, rewardConfig.items[math.random(#rewardConfig.items)])
    end
    
    local minItems = rewardConfig.minItems or 1
    local maxItems = rewardConfig.maxItems or 3
    local itemCount = math.random(minItems, math.min(maxItems, #pool))
    
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
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:server:CheckWorldPropAccess", function(source, worldpropId)
    local worldPropConfig = GetWorldPropConfig(worldpropId)
    if not worldPropConfig then return false end
    return CanAccessWorldProp(source, worldPropConfig)
end)

lib.callback.register("ogz_propmanager:server:CheckWorldPropCooldown", function(source, worldpropId, locationHash)
    local citizenid = GetCitizenId(source)
    if not citizenid then return true, 0 end
    
    local worldPropConfig = GetWorldPropConfig(worldpropId)
    if not worldPropConfig then return true, 0 end
    
    if worldPropConfig.type ~= "reward" then return false, 0 end
    
    local cooldownConfig = worldPropConfig.reward and worldPropConfig.reward.cooldown
    if not cooldownConfig or cooldownConfig.type == "none" then return false, 0 end
    
    local cooldownTime = cooldownConfig.time or 1800
    return Database_CheckWorldPropCooldown(citizenid, worldpropId, locationHash, cooldownTime)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

function FormatTime(seconds)
    if seconds < 60 then return string.format("%ds", seconds)
    elseif seconds < 3600 then return string.format("%dm", math.floor(seconds / 60))
    else return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)
    Database_InitWorldProps()
    
    local count = 0
    local locationCount = 0
    for id, config in pairs(WorldProps) do
        count = count + 1
        if config.locations then
            locationCount = locationCount + #config.locations
        end
    end
    
    print("^2[OGz PropManager v3.0]^0 World props loaded:", count, "definitions,", locationCount, "locations")
end)
