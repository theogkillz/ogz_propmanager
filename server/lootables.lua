--[[
    OGz PropManager v3.3 - Server Lootables
    
    FEATURES:
    - Player-placed lootables (item-based)
    - Timer-based auto-despawn
    - Search limits with tracking
    - Custom loot override (admin)
    - Police alert system
    - Required items to search
    - Admin notifications
    - Loot scaling by nearby players
    - Full admin options menu support
]]

if not Config.Features.Lootables then return end

local QBX = exports.qbx_core
local tablePrefix = Config.Database.TablePrefix

-- Active timers for despawn
local despawnTimers = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetPlayer(source) return QBX:GetPlayer(source) end
local function GetCitizenId(source) local p = GetPlayer(source) return p and p.PlayerData.citizenid end
local function DebugPrint(...) if Config.Debug then print("[OGz Lootables]", ...) end end
local function GetLootableConfig(lootType) return Lootables[lootType] end

local function GetPlayerGang(source)
    local player = GetPlayer(source)
    if player and player.PlayerData.gang then
        return player.PlayerData.gang.name
    end
    return nil
end

local function GetPlayerJob(source)
    local player = GetPlayer(source)
    if player and player.PlayerData.job then
        return player.PlayerData.job.name
    end
    return nil
end

local function GetSetting(lootConfig, key, subkey)
    -- Use global helper if available, otherwise inline
    if GetLootableSetting then
        return GetLootableSetting(lootConfig, key, subkey)
    end
    -- Fallback inline implementation
    if subkey then
        if lootConfig[key] and lootConfig[key][subkey] ~= nil then
            return lootConfig[key][subkey]
        end
        if Lootables.Defaults and Lootables.Defaults[key] and Lootables.Defaults[key][subkey] ~= nil then
            return Lootables.Defaults[key][subkey]
        end
        return nil
    end
    if lootConfig[key] ~= nil then
        return lootConfig[key]
    end
    return Lootables.Defaults and Lootables.Defaults[key] or nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function Database_InitLootables()
    -- v3.3: Updated schema with new fields
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_lootables` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `loot_type` VARCHAR(50) NOT NULL,
            `model` VARCHAR(100) NOT NULL,
            `coords` JSON NOT NULL,
            `heading` FLOAT NOT NULL,
            `routing_bucket` INT DEFAULT 0,
            `last_looted_global` TIMESTAMP NULL,
            `times_looted` INT DEFAULT 0,
            `max_searches` INT DEFAULT 0,
            `is_active` BOOLEAN DEFAULT TRUE,
            `placed_by` VARCHAR(50) NULL,
            `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `expires_at` TIMESTAMP NULL,
            `despawn_on_search` BOOLEAN DEFAULT FALSE,
            `custom_loot` JSON NULL,
            `admin_overrides` JSON NULL,
            INDEX `idx_type` (`loot_type`),
            INDEX `idx_bucket` (`routing_bucket`),
            INDEX `idx_active` (`is_active`),
            INDEX `idx_expires` (`expires_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Player-specific loot cooldowns
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_loot_cooldowns` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `lootable_id` INT NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `looted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_player_loot` (`lootable_id`, `citizenid`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_lootable` (`lootable_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Add new columns if they don't exist (migration for existing databases)
    -- Using IF NOT EXISTS check to avoid log spam on restart
    local columnsToAdd = {
        { name = "expires_at", definition = "TIMESTAMP NULL" },
        { name = "despawn_on_search", definition = "BOOLEAN DEFAULT FALSE" },
        { name = "custom_loot", definition = "JSON NULL" },
        { name = "admin_overrides", definition = "JSON NULL" },
        { name = "max_searches", definition = "INT DEFAULT 0" },
    }
    
    for _, col in ipairs(columnsToAdd) do
        -- Check if column exists first
        local exists = MySQL.scalar.await([[
            SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = ']] .. tablePrefix .. [[_lootables' 
            AND COLUMN_NAME = ?
        ]], { col.name })
        
        if exists == 0 then
            MySQL.query([[ALTER TABLE `]] .. tablePrefix .. [[_lootables` ADD COLUMN `]] .. col.name .. [[` ]] .. col.definition)
            DebugPrint("Added column:", col.name)
        end
    end
    
    DebugPrint("Lootable database tables initialized (v3.3)")
end

function Database_InsertLootable(data)
    local safeHeading = tonumber(data.heading) or 0.0
    return MySQL.insert.await([[
        INSERT INTO `]] .. tablePrefix .. [[_lootables` 
        (loot_type, model, coords, heading, routing_bucket, placed_by, expires_at, despawn_on_search, custom_loot, admin_overrides, max_searches)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { 
        data.lootType, 
        data.model, 
        json.encode(data.coords), 
        safeHeading, 
        data.bucket or 0, 
        data.placedBy,
        data.expiresAt,
        data.despawnOnSearch and 1 or 0,
        data.customLoot and json.encode(data.customLoot) or nil,
        data.adminOverrides and json.encode(data.adminOverrides) or nil,
        data.maxSearches or 0
    })
end

function Database_GetLootable(propId)
    local result = MySQL.single.await([[SELECT * FROM `]] .. tablePrefix .. [[_lootables` WHERE id = ?]], { propId })
    if result then 
        result.coords = json.decode(result.coords)
        result.custom_loot = result.custom_loot and json.decode(result.custom_loot) or nil
        result.admin_overrides = result.admin_overrides and json.decode(result.admin_overrides) or nil
    end
    return result
end

function Database_GetLootablesByBucket(bucket)
    local result = MySQL.query.await([[
        SELECT * FROM `]] .. tablePrefix .. [[_lootables` 
        WHERE routing_bucket = ? AND is_active = TRUE 
        AND (expires_at IS NULL OR expires_at > NOW())
    ]], { bucket })
    for _, row in ipairs(result or {}) do 
        row.coords = json.decode(row.coords)
        row.custom_loot = row.custom_loot and json.decode(row.custom_loot) or nil
        row.admin_overrides = row.admin_overrides and json.decode(row.admin_overrides) or nil
    end
    return result or {}
end

function Database_GetAllLootables()
    local result = MySQL.query.await([[
        SELECT * FROM `]] .. tablePrefix .. [[_lootables` 
        WHERE is_active = TRUE 
        AND (expires_at IS NULL OR expires_at > NOW())
    ]])
    for _, row in ipairs(result or {}) do 
        row.coords = json.decode(row.coords)
        row.custom_loot = row.custom_loot and json.decode(row.custom_loot) or nil
        row.admin_overrides = row.admin_overrides and json.decode(row.admin_overrides) or nil
    end
    return result or {}
end

function Database_DeleteLootable(propId)
    return MySQL.update.await([[DELETE FROM `]] .. tablePrefix .. [[_lootables` WHERE id = ?]], { propId }) > 0
end

function Database_DeactivateLootable(propId)
    return MySQL.update.await([[UPDATE `]] .. tablePrefix .. [[_lootables` SET is_active = FALSE WHERE id = ?]], { propId })
end

function Database_IncrementSearchCount(propId)
    return MySQL.update.await([[
        UPDATE `]] .. tablePrefix .. [[_lootables` 
        SET last_looted_global = NOW(), times_looted = times_looted + 1 
        WHERE id = ?
    ]], { propId })
end

function Database_GetSearchCount(propId)
    local result = MySQL.single.await([[SELECT times_looted FROM `]] .. tablePrefix .. [[_lootables` WHERE id = ?]], { propId })
    return result and result.times_looted or 0
end

function Database_CheckGlobalCooldown(propId, cooldownSeconds)
    local result = MySQL.single.await([[
        SELECT last_looted_global, 
               TIMESTAMPDIFF(SECOND, last_looted_global, NOW()) as seconds_since
        FROM `]] .. tablePrefix .. [[_lootables` WHERE id = ?
    ]], { propId })
    
    if not result or not result.last_looted_global then
        return false, 0
    end
    
    local remaining = cooldownSeconds - (result.seconds_since or 0)
    if remaining > 0 then
        return true, remaining
    end
    return false, 0
end

function Database_SetPlayerCooldown(propId, citizenid)
    MySQL.query([[
        INSERT INTO `]] .. tablePrefix .. [[_loot_cooldowns` (lootable_id, citizenid, looted_at)
        VALUES (?, ?, NOW())
        ON DUPLICATE KEY UPDATE looted_at = NOW()
    ]], { propId, citizenid })
end

function Database_CheckPlayerCooldown(propId, citizenid, cooldownSeconds)
    local result = MySQL.single.await([[
        SELECT looted_at, TIMESTAMPDIFF(SECOND, looted_at, NOW()) as seconds_since
        FROM `]] .. tablePrefix .. [[_loot_cooldowns` 
        WHERE lootable_id = ? AND citizenid = ?
    ]], { propId, citizenid })
    
    if not result then
        return false, 0
    end
    
    local remaining = cooldownSeconds - (result.seconds_since or 0)
    if remaining > 0 then
        return true, remaining
    end
    return false, 0
end

function Database_ClearPlayerCooldowns(propId)
    return MySQL.update.await([[DELETE FROM `]] .. tablePrefix .. [[_loot_cooldowns` WHERE lootable_id = ?]], { propId })
end

function Database_ClearAllPlayerCooldowns(citizenid)
    return MySQL.update.await([[DELETE FROM `]] .. tablePrefix .. [[_loot_cooldowns` WHERE citizenid = ?]], { citizenid })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ACCESS CONTROL
-- ═══════════════════════════════════════════════════════════════════════════

function CanAccessLootable(source, lootConfig)
    if not lootConfig.visibleTo then return true end
    
    local playerJob = GetPlayerJob(source)
    local playerGang = GetPlayerGang(source)
    
    if lootConfig.visibleTo.jobs then
        for _, job in ipairs(lootConfig.visibleTo.jobs) do
            if playerJob == job then return true end
        end
    end
    
    if lootConfig.visibleTo.gangs then
        for _, gang in ipairs(lootConfig.visibleTo.gangs) do
            if playerGang == gang then return true end
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- NEARBY PLAYER COUNT (for scaling)
-- ═══════════════════════════════════════════════════════════════════════════

function GetNearbyPlayerCount(coords, radius)
    local count = 0
    for _, playerId in ipairs(GetPlayers()) do
        local playerPed = GetPlayerPed(playerId)
        if playerPed and DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(vector3(coords.x, coords.y, coords.z) - playerCoords)
            if distance <= radius then
                count = count + 1
            end
        end
    end
    return count
end

function CalculateLootMultiplier(lootConfig, coords, adminOverrides)
    local baseMultiplier = adminOverrides and adminOverrides.lootMultiplier or 
                          lootConfig.lootMultiplier or 
                          Lootables.Defaults.lootMultiplier or 1.0
    
    -- Check scaling
    local scaling = adminOverrides and adminOverrides.scaling or lootConfig.scaling or Lootables.Defaults.scaling
    if not scaling or not scaling.enabled then
        return baseMultiplier
    end
    
    local nearbyCount = GetNearbyPlayerCount(coords, scaling.radius or 50.0)
    local minPlayers = scaling.minPlayers or 1
    local maxPlayers = scaling.maxPlayers or 10
    local minMult = scaling.minMultiplier or 1.0
    local maxMult = scaling.maxMultiplier or 2.0
    
    -- Clamp player count
    nearbyCount = math.max(minPlayers, math.min(maxPlayers, nearbyCount))
    
    -- Linear interpolation
    local ratio = (nearbyCount - minPlayers) / math.max(1, maxPlayers - minPlayers)
    local scalingMultiplier = minMult + (maxMult - minMult) * ratio
    
    DebugPrint("Loot scaling:", nearbyCount, "players nearby, multiplier:", scalingMultiplier)
    
    return baseMultiplier * scalingMultiplier
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOOT ROLLING SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

---Roll loot from a loot table
---@param lootConfig table The loot configuration
---@param multiplier number Optional quantity multiplier
---@return table Array of {item, count} results
function RollLoot(lootConfig, multiplier)
    multiplier = multiplier or 1.0
    local results = {}
    local pool = {}
    
    -- v3.3 FIX: Validate loot config has items
    if not lootConfig or not lootConfig.items or #lootConfig.items == 0 then
        DebugPrint("RollLoot: No items in loot config!")
        return results
    end
    
    -- Phase 1: Each item rolls its chance independently to enter the pool
    for _, itemData in ipairs(lootConfig.items) do
        local chance = itemData.chance or 50
        local roll = math.random(1, 100)
        if roll <= chance then
            table.insert(pool, itemData)
            DebugPrint("Item", itemData.item, "passed chance roll (", roll, "<=", chance, ")")
        end
    end
    
    -- If pool is empty, give at least one random item as fallback
    if #pool == 0 then
        table.insert(pool, lootConfig.items[math.random(1, #lootConfig.items)])
        DebugPrint("Pool was empty, added random fallback item")
    end
    
    -- Phase 2: Select random items from pool
    local minItems = lootConfig.minItems or 1
    local maxItems = lootConfig.maxItems or 3
    
    -- Ensure valid range for math.random
    local maxPossible = math.min(maxItems, #pool)
    local minPossible = math.min(minItems, maxPossible)
    
    if maxPossible < 1 then maxPossible = 1 end
    if minPossible < 1 then minPossible = 1 end
    if minPossible > maxPossible then minPossible = maxPossible end
    
    local itemCount = minPossible == maxPossible and minPossible or math.random(minPossible, maxPossible)
    
    DebugPrint("Rolling", itemCount, "items from pool of", #pool, "with multiplier", multiplier)
    
    -- Shuffle and pick
    for i = 1, itemCount do
        if #pool == 0 then break end
        
        local idx = math.random(1, #pool)
        local selectedItem = pool[idx]
        
        -- Roll quantity with multiplier
        local minQty = selectedItem.min or 1
        local maxQty = selectedItem.max or 1
        if minQty > maxQty then minQty = maxQty end
        if minQty < 1 then minQty = 1 end
        
        local baseQuantity = minQty == maxQty and minQty or math.random(minQty, maxQty)
        local finalQuantity = math.floor(baseQuantity * multiplier + 0.5)  -- Round
        if finalQuantity < 1 then finalQuantity = 1 end
        
        table.insert(results, {
            item = selectedItem.item,
            count = finalQuantity,
        })
        
        table.remove(pool, idx)
        DebugPrint("Selected:", selectedItem.item, "x", finalQuantity)
    end
    
    return results
end

---Give loot items to player
---@param source number Player source
---@param lootResults table Array of {item, count}
---@return boolean Success
---@return table Given items
function GiveLoot(source, lootResults)
    local success = true
    local givenItems = {}
    
    for _, loot in ipairs(lootResults) do
        local added = exports.ox_inventory:AddItem(source, loot.item, loot.count)
        if added then
            table.insert(givenItems, loot)
        else
            success = false
            DebugPrint("Failed to add item:", loot.item, "x", loot.count)
        end
    end
    
    return success, givenItems
end

-- ═══════════════════════════════════════════════════════════════════════════
-- POLICE ALERT SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

function TriggerPoliceAlert(coords, message, blipDuration)
    -- Notify police players
    for _, playerId in ipairs(GetPlayers()) do
        local player = GetPlayer(tonumber(playerId))
        if player then
            local job = player.PlayerData.job
            if job and (job.name == "police" or job.name == "sheriff" or job.name == "bcso") then
                TriggerClientEvent("ogz_propmanager:client:PoliceAlert", playerId, {
                    coords = coords,
                    message = message,
                    duration = blipDuration or 60,
                })
            end
        end
    end
    
    DebugPrint("Police alert triggered:", message)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

function NotifyAdmin(adminCitizenId, message)
    if not adminCitizenId then return end
    
    for _, playerId in ipairs(GetPlayers()) do
        local player = GetPlayer(tonumber(playerId))
        if player and player.PlayerData.citizenid == adminCitizenId then
            TriggerClientEvent("ogz_propmanager:client:Notify", playerId, message, "info")
            return
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DESPAWN TIMER SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

function StartDespawnTimer(propId, minutes, bucket)
    if minutes <= 0 then return end
    
    local ms = minutes * 60 * 1000
    
    -- Cancel existing timer if any
    if despawnTimers[propId] then
        -- Can't actually cancel SetTimeout, but we track it
    end
    
    despawnTimers[propId] = true
    
    SetTimeout(ms, function()
        if not despawnTimers[propId] then return end  -- Was cancelled
        
        local lootableData = Database_GetLootable(propId)
        if not lootableData or not lootableData.is_active then return end
        
        DebugPrint("Despawn timer expired for lootable", propId)
        
        Database_DeactivateLootable(propId)
        despawnTimers[propId] = nil
        
        -- Notify all clients in bucket to remove
        for _, playerId in ipairs(GetPlayers()) do
            if GetPlayerRoutingBucket(playerId) == (bucket or 0) then
                TriggerClientEvent("ogz_propmanager:client:RemoveLootable", playerId, propId)
            end
        end
    end)
    
    DebugPrint("Despawn timer started for lootable", propId, "-", minutes, "minutes")
end

function CancelDespawnTimer(propId)
    despawnTimers[propId] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:server:CheckLootCooldown", function(source, propId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return true, 0, "No player" end
    
    local lootableData = Database_GetLootable(propId)
    if not lootableData then return true, 0, "Not found" end
    if not lootableData.is_active then return true, 0, "Already looted" end
    
    local lootConfig = GetLootableConfig(lootableData.loot_type)
    if not lootConfig then return true, 0, "Invalid type" end
    
    -- Check max searches
    local maxSearches = lootableData.max_searches or GetSetting(lootConfig, 'maxSearches') or 0
    if maxSearches > 0 then
        local currentSearches = Database_GetSearchCount(propId)
        if currentSearches >= maxSearches then
            return true, 0, "Max searches reached"
        end
    end
    
    -- Check cooldown
    local cooldownConfig = lootConfig.loot and lootConfig.loot.cooldown or lootConfig.searchCooldown
    if not cooldownConfig then
        cooldownConfig = Lootables.Defaults.searchCooldown
    end
    
    if cooldownConfig and cooldownConfig.type ~= "none" then
        local cooldownTime = cooldownConfig.time or Config.Lootables.DefaultCooldownTime
        
        if cooldownConfig.type == "global" then
            local onCooldown, remaining = Database_CheckGlobalCooldown(propId, cooldownTime)
            if onCooldown then
                return true, remaining, "global_cooldown"
            end
        elseif cooldownConfig.type == "player" then
            local onCooldown, remaining = Database_CheckPlayerCooldown(propId, citizenid, cooldownTime)
            if onCooldown then
                return true, remaining, "player_cooldown"
            end
        end
    end
    
    return false, 0, nil
end)

lib.callback.register("ogz_propmanager:server:CheckRequiredItem", function(source, propId)
    local lootableData = Database_GetLootable(propId)
    if not lootableData then return false, nil end
    
    local lootConfig = GetLootableConfig(lootableData.loot_type)
    if not lootConfig then return false, nil end
    
    -- Check admin overrides first
    local requiredItem = nil
    local consumeRequired = false
    
    if lootableData.admin_overrides then
        requiredItem = lootableData.admin_overrides.requiredItem
        consumeRequired = lootableData.admin_overrides.consumeRequired
    end
    
    if not requiredItem then
        requiredItem = GetSetting(lootConfig, 'requiredItem')
        consumeRequired = GetSetting(lootConfig, 'consumeRequired') or false
    end
    
    if not requiredItem then
        return true, nil  -- No item required
    end
    
    -- Check if player has the item
    local hasItem = exports.ox_inventory:GetItemCount(source, requiredItem) > 0
    
    if not hasItem then
        local itemLabel = exports.ox_inventory:Items(requiredItem)
        itemLabel = itemLabel and itemLabel.label or requiredItem
        return false, itemLabel
    end
    
    -- Consume item if needed
    if consumeRequired then
        exports.ox_inventory:RemoveItem(source, requiredItem, 1)
    end
    
    return true, nil
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SEARCH LOOTABLE
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:SearchLootable", function(propId)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local lootableData = Database_GetLootable(propId)
    if not lootableData or not lootableData.is_active then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Nothing to search here", "error")
        return
    end
    
    local lootConfig = GetLootableConfig(lootableData.loot_type)
    if not lootConfig then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Invalid lootable", "error")
        return
    end
    
    -- Check access
    if not CanAccessLootable(source, lootConfig) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.NoAccess, "error")
        return
    end
    
    -- Get admin overrides
    local overrides = lootableData.admin_overrides or {}
    
    -- Roll loot (use custom loot if set, otherwise use config)
    local lootResults
    if lootableData.custom_loot and #lootableData.custom_loot > 0 then
        -- Admin specified exact items
        lootResults = lootableData.custom_loot
        DebugPrint("Using custom loot for", propId)
    else
        -- Roll from loot table with scaling
        local multiplier = CalculateLootMultiplier(lootConfig, lootableData.coords, overrides)
        local lootTable = lootConfig.loot or lootConfig
        lootResults = RollLoot(lootTable, multiplier)
    end
    
    if #lootResults == 0 then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.LootEmpty, "info")
        TriggerClientEvent("ogz_propmanager:client:LootResult", source, propId, false, {})
    else
        -- Give items
        local success, givenItems = GiveLoot(source, lootResults)
        
        if success and #givenItems > 0 then
            TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.LootFound, "success")
            TriggerClientEvent("ogz_propmanager:client:LootResult", source, propId, true, givenItems)
            
            -- Update search count
            Database_IncrementSearchCount(propId)
            
            -- Set cooldown
            local cooldownConfig = lootConfig.loot and lootConfig.loot.cooldown or lootConfig.searchCooldown or Lootables.Defaults.searchCooldown
            if cooldownConfig then
                if cooldownConfig.type == "global" then
                    -- Already updated via IncrementSearchCount
                elseif cooldownConfig.type == "player" then
                    Database_SetPlayerCooldown(propId, citizenid)
                end
            end
            
            -- Log
            if Database_Log then
                Database_Log(propId, citizenid, "loot", lootableData.loot_type, nil, #givenItems, nil, 
                    { items = givenItems }, lootableData.coords)
            end
            
            -- Check police alert
            local policeAlert = overrides.policeAlert or lootConfig.policeAlert or Lootables.Defaults.policeAlert
            if policeAlert and policeAlert.enabled then
                local alertChance = policeAlert.chance or 0
                if math.random(1, 100) <= alertChance then
                    TriggerPoliceAlert(lootableData.coords, policeAlert.message, policeAlert.blipDuration)
                    TriggerClientEvent("ogz_propmanager:client:Notify", source, "⚠️ You may have been spotted!", "error")
                end
            end
            
            -- Notify admin if applicable
            if lootableData.placed_by then
                NotifyAdmin(lootableData.placed_by, string.format("Your %s was searched by a player!", lootConfig.label or lootableData.loot_type))
            end
            
            -- Check if should despawn
            local shouldDespawn = false
            
            -- Despawn on search?
            if lootableData.despawn_on_search or GetSetting(lootConfig, 'despawnOnSearch') then
                shouldDespawn = true
            end
            
            -- Max searches reached?
            local maxSearches = lootableData.max_searches or GetSetting(lootConfig, 'maxSearches') or 0
            if maxSearches > 0 then
                local currentSearches = Database_GetSearchCount(propId)
                if currentSearches >= maxSearches then
                    shouldDespawn = true
                end
            end
            
            if shouldDespawn then
                Database_DeactivateLootable(propId)
                CancelDespawnTimer(propId)
                
                -- Immediate or delayed despawn
                local despawnDelay = Config.Lootables.DespawnDelay or 5
                SetTimeout(despawnDelay * 1000, function()
                    for _, playerId in ipairs(GetPlayers()) do
                        if GetPlayerRoutingBucket(playerId) == (lootableData.routing_bucket or 0) then
                            TriggerClientEvent("ogz_propmanager:client:RemoveLootable", playerId, propId)
                        end
                    end
                end)
            end
            
            DebugPrint("Player", citizenid, "looted", lootableData.loot_type, "- Items:", #givenItems)
        else
            TriggerClientEvent("ogz_propmanager:client:Notify", source, "Inventory full!", "error")
            TriggerClientEvent("ogz_propmanager:client:LootResult", source, propId, false, {})
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYER PLACEMENT (Item-based)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:CheckLootableLimit", function(lootType, itemName)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local lootConfig = GetLootableConfig(lootType)
    if not lootConfig then return end
    
    -- Check if player can place this type
    if lootConfig.adminOnly then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Admin only lootable!", "error")
        return
    end
    
    -- Remove item and start placement
    if exports.ox_inventory:RemoveItem(source, itemName, 1) then
        TriggerClientEvent("ogz_propmanager:client:StartLootablePlacement", source, lootType)
    else
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Item not found in inventory", "error")
    end
end)

RegisterNetEvent("ogz_propmanager:server:PlaceLootable", function(data)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local lootConfig = GetLootableConfig(data.lootType)
    if not lootConfig then return end
    
    local model = data.model or (lootConfig.models and lootConfig.models[1]) or lootConfig.model
    
    -- Calculate expiry time
    local expiresAt = nil
    local despawnTimer = GetSetting(lootConfig, 'despawnTimer') or 0
    if despawnTimer > 0 then
        expiresAt = os.date("!%Y-%m-%d %H:%M:%S", os.time() + (despawnTimer * 60))
    end
    
    local propId = Database_InsertLootable({
        lootType = data.lootType,
        model = model,
        coords = data.coords,
        heading = data.heading or 0.0,
        bucket = data.bucket or 0,
        placedBy = citizenid,
        expiresAt = expiresAt,
        despawnOnSearch = GetSetting(lootConfig, 'despawnOnSearch') or false,
        maxSearches = GetSetting(lootConfig, 'maxSearches') or 0,
    })
    
    if propId then
        local propData = {
            id = propId,
            loot_type = data.lootType,
            model = model,
            coords = data.coords,
            heading = data.heading,
            routing_bucket = data.bucket or 0,
            is_active = true,
            times_looted = 0,
            placed_by = citizenid,
        }
        
        -- Start despawn timer if set
        if despawnTimer > 0 then
            StartDespawnTimer(propId, despawnTimer, data.bucket or 0)
        end
        
        -- Notify clients in same bucket
        for _, playerId in ipairs(GetPlayers()) do
            if GetPlayerRoutingBucket(playerId) == (data.bucket or 0) then
                TriggerClientEvent("ogz_propmanager:client:SpawnLootable", playerId, propData)
            end
        end
        
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Lootable placed!", "success")
        DebugPrint("Player", citizenid, "placed lootable:", data.lootType)
    else
        -- Return item on failure
        exports.ox_inventory:AddItem(source, lootConfig.item, 1)
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Failed to place lootable", "error")
    end
end)

RegisterNetEvent("ogz_propmanager:server:LootablePlacementCancelled", function(itemName)
    local source = source
    if itemName then
        exports.ox_inventory:AddItem(source, itemName, 1)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN SPAWNING (Full options)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:SpawnLootable", function(data)
    local source = source
    local citizenid = GetCitizenId(source)
    
    -- Check admin permission
    if not IsAdmin(source) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "No permission", "error")
        return
    end
    
    local lootConfig = GetLootableConfig(data.lootType)
    if not lootConfig then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Invalid loot type", "error")
        return
    end
    
    local model = data.model or (lootConfig.models and lootConfig.models[1]) or lootConfig.model
    
    -- Calculate expiry time from admin options
    local expiresAt = nil
    local despawnMinutes = data.despawnTimer or GetSetting(lootConfig, 'despawnTimer') or 0
    if despawnMinutes > 0 then
        expiresAt = os.date("!%Y-%m-%d %H:%M:%S", os.time() + (despawnMinutes * 60))
    end
    
    -- Build admin overrides
    local adminOverrides = nil
    if data.overrides then
        adminOverrides = {
            lootMultiplier = data.overrides.lootMultiplier,
            scaling = data.overrides.scaling,
            policeAlert = data.overrides.policeAlert,
            requiredItem = data.overrides.requiredItem,
            consumeRequired = data.overrides.consumeRequired,
            visibleTo = data.overrides.visibleTo,
        }
    end
    
    local propId = Database_InsertLootable({
        lootType = data.lootType,
        model = model,
        coords = data.coords,
        heading = data.heading or 0.0,
        bucket = data.bucket or 0,
        placedBy = citizenid,
        expiresAt = expiresAt,
        despawnOnSearch = data.despawnOnSearch or GetSetting(lootConfig, 'despawnOnSearch') or false,
        customLoot = data.customLoot,
        adminOverrides = adminOverrides,
        maxSearches = data.maxSearches or GetSetting(lootConfig, 'maxSearches') or 0,
    })
    
    if propId then
        local propData = {
            id = propId,
            loot_type = data.lootType,
            model = model,
            coords = data.coords,
            heading = data.heading,
            routing_bucket = data.bucket or 0,
            is_active = true,
            times_looted = 0,
            max_searches = data.maxSearches or 0,
            placed_by = citizenid,
        }
        
        -- Start despawn timer if set
        if despawnMinutes > 0 then
            StartDespawnTimer(propId, despawnMinutes, data.bucket or 0)
        end
        
        -- Notify clients in same bucket
        for _, playerId in ipairs(GetPlayers()) do
            if GetPlayerRoutingBucket(playerId) == (data.bucket or 0) then
                TriggerClientEvent("ogz_propmanager:client:SpawnLootable", playerId, propData)
            end
        end
        
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Lootable spawned!", "success")
        DebugPrint("Admin", citizenid, "spawned lootable:", data.lootType, "with options")
    else
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Failed to spawn lootable", "error")
    end
end)

RegisterNetEvent("ogz_propmanager:server:RemoveLootable", function(propId)
    local source = source
    
    if not IsAdmin(source) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "No permission", "error")
        return
    end
    
    local lootableData = Database_GetLootable(propId)
    if not lootableData then return end
    
    CancelDespawnTimer(propId)
    Database_DeleteLootable(propId)
    Database_ClearPlayerCooldowns(propId)
    
    -- Notify all clients
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerRoutingBucket(playerId) == (lootableData.routing_bucket or 0) then
            TriggerClientEvent("ogz_propmanager:client:RemoveLootable", playerId, propId)
        end
    end
    
    TriggerClientEvent("ogz_propmanager:client:Notify", source, "Lootable removed!", "success")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN: MODIFY LOOTABLE (v3.3)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:admin:ModifyLootable", function(propId, modifications)
    local source = source
    
    if not IsAdmin(source) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "No permission", "error")
        return
    end
    
    local lootableData = Database_GetLootable(propId)
    if not lootableData then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Lootable not found", "error")
        return
    end
    
    local updates = {}
    local messages = {}
    
    -- Update max searches
    if modifications.maxSearches ~= nil then
        table.insert(updates, string.format("max_searches = %d", modifications.maxSearches))
        table.insert(messages, "Max searches: " .. modifications.maxSearches)
    end
    
    -- Update despawn on search
    if modifications.despawnOnSearch ~= nil then
        table.insert(updates, string.format("despawn_on_search = %s", modifications.despawnOnSearch and "TRUE" or "FALSE"))
        table.insert(messages, "One-time: " .. (modifications.despawnOnSearch and "Yes" or "No"))
    end
    
    -- Add time to expiry
    if modifications.addTime and modifications.addTime > 0 then
        if lootableData.expires_at then
            -- Add to existing
            table.insert(updates, string.format("expires_at = DATE_ADD(expires_at, INTERVAL %d MINUTE)", modifications.addTime))
        else
            -- Set new expiry
            table.insert(updates, string.format("expires_at = DATE_ADD(NOW(), INTERVAL %d MINUTE)", modifications.addTime))
            StartDespawnTimer(propId, modifications.addTime, lootableData.routing_bucket or 0)
        end
        table.insert(messages, "Added " .. modifications.addTime .. " min")
    end
    
    if #updates > 0 then
        MySQL.update.await([[
            UPDATE `]] .. tablePrefix .. [[_lootables` 
            SET ]] .. table.concat(updates, ", ") .. [[ 
            WHERE id = ?
        ]], { propId })
        
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "✅ Updated: " .. table.concat(messages, " | "), "success")
        DebugPrint("Admin modified lootable", propId, ":", table.concat(messages, ", "))
    else
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "No changes made", "info")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- REQUEST LOOTABLES
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:RequestLootables", function(bucket)
    local source = source
    local lootables = Database_GetLootablesByBucket(bucket or 0)
    TriggerClientEvent("ogz_propmanager:client:LoadLootables", source, lootables)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

function FormatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

function IsAdmin(source)
    local player = GetPlayer(source)
    if not player then return false end
    
    -- Check admin groups
    for _, group in ipairs(Config.Admin.AllowedGroups or {}) do
        if QBX:HasPermission(source, group) then return true end
    end
    
    -- Check citizenid whitelist
    for _, cid in ipairs(Config.Admin.AllowedCitizenIds or {}) do
        if player.PlayerData.citizenid == cid then return true end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPIRED LOOTABLES CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(60000)  -- Check every minute
        
        -- Find and remove expired lootables
        local expired = MySQL.query.await([[
            SELECT id, routing_bucket FROM `]] .. tablePrefix .. [[_lootables` 
            WHERE is_active = TRUE AND expires_at IS NOT NULL AND expires_at <= NOW()
        ]])
        
        for _, row in ipairs(expired or {}) do
            Database_DeactivateLootable(row.id)
            
            for _, playerId in ipairs(GetPlayers()) do
                if GetPlayerRoutingBucket(playerId) == (row.routing_bucket or 0) then
                    TriggerClientEvent("ogz_propmanager:client:RemoveLootable", playerId, row.id)
                end
            end
            
            DebugPrint("Auto-removed expired lootable:", row.id)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)
    Database_InitLootables()
    
    local allLootables = Database_GetAllLootables()
    local count = 0
    for k, v in pairs(Lootables) do 
        if type(v) == "table" and v.label then
            count = count + 1 
        end
    end
    
    -- Restart despawn timers for active lootables
    for _, lootable in ipairs(allLootables) do
        if lootable.expires_at then
            local expiresTime = MySQL.scalar.await([[SELECT TIMESTAMPDIFF(SECOND, NOW(), ?) as remaining]], { lootable.expires_at })
            if expiresTime and expiresTime > 0 then
                StartDespawnTimer(lootable.id, math.ceil(expiresTime / 60), lootable.routing_bucket or 0)
            end
        end
    end
    
    print("^2[OGz PropManager v3.3]^0 Lootable system loaded with", count, "loot types,", #allLootables, "active lootables")
end)
