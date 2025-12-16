--[[
    ═══════════════════════════════════════════════════════════════════════════
    OGz PropManager v3.5.1 - SERVER World Builder
    ═══════════════════════════════════════════════════════════════════════════
    
    Handles:
    - Database persistence for spawned/deleted props
    - Respawn timer system
    - Admin permission checking
    - Sync to all clients
    
    v3.5.1: Fixed deleted prop sync to all clients
            Added WorldBuilderHideNative event for client sync
    
    ═══════════════════════════════════════════════════════════════════════════
]]

local QBX = exports.qbx_core

-- Safe config access with fallbacks
local tablePrefix = (Config and Config.Database and Config.Database.TablePrefix) or "ogz_propmanager"

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════════════

local spawnedProps = {}      -- Cached spawned props from DB
local deletedProps = {}      -- Cached deleted props from DB
local respawnQueue = {}      -- Props awaiting respawn { [dbId] = respawnTime }

-- ═══════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

local Settings = (WorldBuilder and WorldBuilder.Settings) or {}
local AdminSettings = Settings.Admin or {}
local RespawnSettings = Settings.Respawn or {}
local DebugSettings = Settings.Debug or { enabled = true }

local RESPAWN_CHECK_INTERVAL = RespawnSettings.checkInterval or 30000

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function DebugPrint(...)
    if DebugSettings.enabled then
        print("[OGz WorldBuilder]", ...)
    end
end

local function GetPlayer(source) return QBX:GetPlayer(source) end
local function GetCitizenId(source) local p = GetPlayer(source) return p and p.PlayerData.citizenid end

local function GetPlayerJob(source)
    local player = GetPlayer(source)
    return player and player.PlayerData.job and player.PlayerData.job.name or nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN CHECK
-- ═══════════════════════════════════════════════════════════════════════════

local function IsAdmin(source)
    if AdminSettings.useAce then
        return IsPlayerAceAllowed(source, AdminSettings.acePermission or "ogz.worldbuilder.admin")
    else
        local job = GetPlayerJob(source)
        if job and AdminSettings.allowedJobs then
            for _, allowedJob in ipairs(AdminSettings.allowedJobs) do
                if job == allowedJob then return true end
            end
        end
    end
    return false
end

lib.callback.register("ogz_propmanager:server:CheckWorldBuilderAdmin", function(source)
    return IsAdmin(source)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

local function Database_Init()
    -- Spawned props table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_world_spawned` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `spawn_id` VARCHAR(100) UNIQUE,
            `model` VARCHAR(100) NOT NULL,
            `coords` JSON NOT NULL,
            `heading` FLOAT DEFAULT 0.0,
            `routing_bucket` INT DEFAULT 0,
            `interaction_zone` VARCHAR(100),
            `respawn_time` INT DEFAULT 0,
            `last_harvested` TIMESTAMP NULL,
            `is_spawned` BOOLEAN DEFAULT TRUE,
            `group_id` VARCHAR(100),
            `placed_by` VARCHAR(50),
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_zone` (`interaction_zone`),
            INDEX `idx_group` (`group_id`),
            INDEX `idx_spawned` (`is_spawned`),
            INDEX `idx_bucket` (`routing_bucket`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Deleted native props table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_world_deleted` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `model` VARCHAR(100) NOT NULL,
            `coords` JSON NOT NULL,
            `radius` FLOAT DEFAULT 1.0,
            `routing_bucket` INT DEFAULT 0,
            `reason` VARCHAR(255),
            `deleted_by` VARCHAR(50),
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_bucket` (`routing_bucket`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    DebugPrint("Database tables initialized")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function Database_LoadSpawnedProps()
    local results = MySQL.query.await([[
        SELECT * FROM `]] .. tablePrefix .. [[_world_spawned`
        WHERE routing_bucket = 0
    ]])
    
    spawnedProps = {}
    if results then
        for _, row in ipairs(results) do
            spawnedProps[row.id] = row
            
            -- Add to respawn queue if harvested and has respawn time
            if not row.is_spawned and row.respawn_time > 0 and row.last_harvested then
                local harvestTime = row.last_harvested
                -- Calculate when it should respawn (this is simplified)
                respawnQueue[row.id] = os.time() + row.respawn_time
            end
        end
    end
    
    DebugPrint("Loaded", #(results or {}), "spawned props from database")
    return results or {}
end

local function Database_LoadDeletedProps()
    local results = MySQL.query.await([[
        SELECT * FROM `]] .. tablePrefix .. [[_world_deleted`
        WHERE routing_bucket = 0
    ]])
    
    deletedProps = {}
    if results then
        for _, row in ipairs(results) do
            deletedProps[row.id] = row
        end
    end
    
    DebugPrint("Loaded", #(results or {}), "deleted props from database")
    return results or {}
end

local function Database_SpawnProp(data)
    local spawnId = string.format("wb_%s_%d_%d", data.model, os.time(), math.random(10000, 99999))
    
    local id = MySQL.insert.await([[
        INSERT INTO `]] .. tablePrefix .. [[_world_spawned`
        (spawn_id, model, coords, heading, routing_bucket, interaction_zone, respawn_time, group_id, placed_by, is_spawned)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)
    ]], {
        spawnId,
        data.model,
        json.encode(data.coords),
        data.heading or 0.0,
        data.routingBucket or 0,
        data.zone,
        data.respawnTime or 0,
        data.groupId,
        data.placedBy,
    })
    
    if id then
        local propData = {
            id = id,
            spawn_id = spawnId,
            model = data.model,
            coords = data.coords,
            heading = data.heading or 0.0,
            routing_bucket = data.routingBucket or 0,
            interaction_zone = data.zone,
            respawn_time = data.respawnTime or 0,
            is_spawned = true,
            group_id = data.groupId,
            placed_by = data.placedBy,
        }
        spawnedProps[id] = propData
        DebugPrint("Spawned prop saved to DB:", id, data.model)
        return propData
    end
    
    return nil
end

local function Database_DeleteSpawnedProp(dbId)
    MySQL.query([[
        DELETE FROM `]] .. tablePrefix .. [[_world_spawned`
        WHERE id = ?
    ]], { dbId })
    
    spawnedProps[dbId] = nil
    respawnQueue[dbId] = nil
    DebugPrint("Deleted spawned prop:", dbId)
end

local function Database_DeleteNativeProp(data)
    -- v3.5.1: Check for duplicates first!
    -- If we already have this model hidden at similar coords, don't add again
    local checkResults = MySQL.query.await([[
        SELECT id, coords FROM `]] .. tablePrefix .. [[_world_deleted`
        WHERE model = ? AND routing_bucket = ?
    ]], {
        tostring(data.model),
        data.routingBucket or 0,
    })
    
    if checkResults then
        for _, existing in ipairs(checkResults) do
            local existingCoords = json.decode(existing.coords)
            if existingCoords then
                local dist = math.sqrt(
                    (data.coords.x - existingCoords.x)^2 + 
                    (data.coords.y - existingCoords.y)^2 + 
                    (data.coords.z - existingCoords.z)^2
                )
                -- If within 2 meters, it's a duplicate
                if dist < 2.0 then
                    DebugPrint("Duplicate deleted prop detected, skipping insert. Existing ID:", existing.id)
                    return deletedProps[existing.id]  -- Return existing entry
                end
            end
        end
    end
    
    -- No duplicate found, insert new entry
    local id = MySQL.insert.await([[
        INSERT INTO `]] .. tablePrefix .. [[_world_deleted`
        (model, coords, radius, routing_bucket, reason, deleted_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        tostring(data.model),
        json.encode(data.coords),
        data.radius or 1.0,
        data.routingBucket or 0,
        data.reason,
        data.deletedBy,
    })
    
    if id then
        local deleteData = {
            id = id,
            model = data.model,
            coords = data.coords,
            radius = data.radius or 1.0,
        }
        deletedProps[id] = deleteData
        DebugPrint("Native prop deletion saved:", id)
        return deleteData
    end
    
    return nil
end

-- v3.5.1: Remove a deleted prop record (unhide)
local function Database_UndeleteNativeProp(dbId)
    MySQL.query([[
        DELETE FROM `]] .. tablePrefix .. [[_world_deleted`
        WHERE id = ?
    ]], { dbId })
    
    deletedProps[dbId] = nil
    DebugPrint("Removed deleted prop record:", dbId)
end

local function Database_SetPropHarvested(dbId)
    MySQL.query([[
        UPDATE `]] .. tablePrefix .. [[_world_spawned`
        SET is_spawned = FALSE, last_harvested = NOW()
        WHERE id = ?
    ]], { dbId })
    
    if spawnedProps[dbId] then
        spawnedProps[dbId].is_spawned = false
        
        -- Add to respawn queue
        local respawnTime = spawnedProps[dbId].respawn_time or 0
        if respawnTime > 0 then
            respawnQueue[dbId] = os.time() + respawnTime
            DebugPrint("Prop", dbId, "will respawn in", respawnTime, "seconds")
        end
    end
end

local function Database_SetPropRespawned(dbId)
    MySQL.query([[
        UPDATE `]] .. tablePrefix .. [[_world_spawned`
        SET is_spawned = TRUE, last_harvested = NULL
        WHERE id = ?
    ]], { dbId })
    
    if spawnedProps[dbId] then
        spawnedProps[dbId].is_spawned = true
    end
    
    respawnQueue[dbId] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RESPAWN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function CheckRespawns()
    local now = os.time()
    
    for dbId, respawnTime in pairs(respawnQueue) do
        if now >= respawnTime then
            local propData = spawnedProps[dbId]
            if propData then
                DebugPrint("Respawning prop:", dbId)
                
                -- Update database
                Database_SetPropRespawned(dbId)
                
                -- Notify all clients
                TriggerClientEvent("ogz_propmanager:client:WorldBuilderRespawnProp", -1, propData)
            else
                respawnQueue[dbId] = nil
            end
        end
    end
end

-- Start respawn checker thread
CreateThread(function()
    while true do
        Wait(RESPAWN_CHECK_INTERVAL)
        CheckRespawns()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CLIENT REQUESTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Player requests data on join
RegisterNetEvent("ogz_propmanager:server:WorldBuilderRequest", function()
    local source = source
    
    -- Use cached data instead of re-querying database
    -- Data is loaded at startup and kept in sync via spawn/delete events
    local spawnedList = {}
    local deletedList = {}
    
    for _, propData in pairs(spawnedProps) do
        spawnedList[#spawnedList + 1] = propData
    end
    
    for _, deleteData in pairs(deletedProps) do
        deletedList[#deletedList + 1] = deleteData
    end
    
    DebugPrint("Sending data to client:", source, "-", #spawnedList, "spawned,", #deletedList, "deleted")
    
    TriggerClientEvent("ogz_propmanager:client:WorldBuilderLoad", source, {
        spawned = spawnedList,
        deleted = deletedList,
    })
end)

-- Anti-duplicate spawn protection
local recentSpawns = {}  -- [source] = timestamp

-- Admin spawns a prop
RegisterNetEvent("ogz_propmanager:server:WorldBuilderSpawn", function(data)
    local source = source
    if not IsAdmin(source) then return end
    
    -- Debounce: Prevent duplicate spawns within 2 seconds
    local now = os.time()
    if recentSpawns[source] and (now - recentSpawns[source]) < 2 then
        DebugPrint("BLOCKED duplicate spawn from source:", source)
        return
    end
    recentSpawns[source] = now
    
    -- Validate coords
    if not data.coords or (data.coords.x == 0 and data.coords.y == 0) then
        DebugPrint("BLOCKED spawn with invalid coords:", json.encode(data.coords))
        TriggerClientEvent("ox_lib:notify", source, { description = "Invalid placement position", type = "error" })
        return
    end
    
    DebugPrint("WorldBuilderSpawn received from:", source, "model:", data.model)
    DebugPrint("  Coords:", json.encode(data.coords))
    
    local citizenid = GetCitizenId(source)
    data.placedBy = citizenid
    
    local propData = Database_SpawnProp(data)
    if propData then
        -- Sync to all clients
        TriggerClientEvent("ogz_propmanager:client:WorldBuilderSpawnProp", -1, propData)
        TriggerClientEvent("ox_lib:notify", source, { description = "Prop spawned (ID: " .. propData.id .. ")", type = "success" })
    else
        TriggerClientEvent("ox_lib:notify", source, { description = "Failed to spawn prop", type = "error" })
    end
end)

-- Admin deletes a spawned prop
RegisterNetEvent("ogz_propmanager:server:WorldBuilderDeleteSpawned", function(dbId)
    local source = source
    if not IsAdmin(source) then return end
    
    Database_DeleteSpawnedProp(dbId)
    
    -- Sync to all clients
    TriggerClientEvent("ogz_propmanager:client:WorldBuilderRemoveProp", -1, dbId)
    TriggerClientEvent("ox_lib:notify", source, { description = "Prop deleted", type = "success" })
end)

-- Admin hides a native prop (v3.5.1: FIXED - now syncs to ALL clients!)
RegisterNetEvent("ogz_propmanager:server:WorldBuilderDeleteNative", function(data)
    local source = source
    if not IsAdmin(source) then return end
    
    local citizenid = GetCitizenId(source)
    data.deletedBy = citizenid
    
    local deleteData = Database_DeleteNativeProp(data)
    if deleteData then
        -- v3.5.1: SYNC TO ALL CLIENTS! This was missing before!
        TriggerClientEvent("ogz_propmanager:client:WorldBuilderHideNative", -1, deleteData)
        TriggerClientEvent("ox_lib:notify", source, { description = "Native prop hidden (ID: " .. deleteData.id .. ")", type = "success" })
        DebugPrint("Synced native prop hide to all clients:", deleteData.id)
    end
end)

-- v3.5.1: Admin unhides a native prop
RegisterNetEvent("ogz_propmanager:server:WorldBuilderUnhideNative", function(dbId)
    local source = source
    if not IsAdmin(source) then return end
    
    local deleteData = deletedProps[dbId]
    if deleteData then
        Database_UndeleteNativeProp(dbId)
        
        -- Sync to all clients
        TriggerClientEvent("ogz_propmanager:client:WorldBuilderUnhideNative", -1, dbId)
        TriggerClientEvent("ox_lib:notify", source, { description = "Native prop unhidden", type = "success" })
    end
end)

-- Admin spawns entire group
RegisterNetEvent("ogz_propmanager:server:WorldBuilderSpawnGroup", function(groupId)
    local source = source
    if not IsAdmin(source) then return end
    
    local groupConfig = WorldBuilder and WorldBuilder.SpawnGroups and WorldBuilder.SpawnGroups[groupId]
    if not groupConfig then
        TriggerClientEvent("ox_lib:notify", source, { description = "Group not found", type = "error" })
        return
    end
    
    local citizenid = GetCitizenId(source)
    local count = 0
    
    for _, propDef in ipairs(groupConfig.props or {}) do
        local data = {
            model = propDef.model,
            coords = { x = propDef.coords.x, y = propDef.coords.y, z = propDef.coords.z },
            heading = propDef.heading or 0.0,
            zone = groupConfig.worldPropsZone,
            respawnTime = groupConfig.respawn and groupConfig.respawn.enabled and groupConfig.respawn.time or 0,
            groupId = groupId,
            placedBy = citizenid,
        }
        
        local propData = Database_SpawnProp(data)
        if propData then
            TriggerClientEvent("ogz_propmanager:client:WorldBuilderSpawnProp", -1, propData)
            count = count + 1
        end
    end
    
    TriggerClientEvent("ox_lib:notify", source, { 
        description = string.format("Spawned %d props from group '%s'", count, groupConfig.name or groupId), 
        type = "success" 
    })
end)

-- Admin clears props in radius
RegisterNetEvent("ogz_propmanager:server:WorldBuilderClear", function(centerCoords, radius)
    local source = source
    if not IsAdmin(source) then return end
    
    local count = 0
    for dbId, propData in pairs(spawnedProps) do
        local coords = propData.coords
        if type(coords) == "string" then coords = json.decode(coords) end
        
        local dist = math.sqrt(
            (centerCoords.x - coords.x)^2 + 
            (centerCoords.y - coords.y)^2 + 
            (centerCoords.z - coords.z)^2
        )
        
        if dist <= radius then
            Database_DeleteSpawnedProp(dbId)
            TriggerClientEvent("ogz_propmanager:client:WorldBuilderRemoveProp", -1, dbId)
            count = count + 1
        end
    end
    
    TriggerClientEvent("ox_lib:notify", source, { 
        description = string.format("Cleared %d props", count), 
        type = "success" 
    })
end)

-- Admin requests reload
RegisterNetEvent("ogz_propmanager:server:WorldBuilderReload", function()
    local source = source
    if not IsAdmin(source) then return end
    
    local spawned = Database_LoadSpawnedProps()
    local deleted = Database_LoadDeletedProps()
    
    DebugPrint("Reload requested - Sending", #spawned, "spawned,", #deleted, "deleted to all clients")
    
    -- Send to all clients
    TriggerClientEvent("ogz_propmanager:client:WorldBuilderLoad", -1, {
        spawned = spawned,
        deleted = deleted,
    })
    
    TriggerClientEvent("ox_lib:notify", source, { description = "Props reloaded", type = "success" })
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- INTEGRATION WITH WORLDPROPS (Harvest Detection)
-- ═══════════════════════════════════════════════════════════════════════════
--[[
    When WorldProps harvests a prop, it can call this to trigger respawn
    This links the two systems together
]]

-- Export for WorldProps to call when harvesting
local function OnPropHarvested(entityHash, zoneId)
    -- Find the spawned prop by matching zone and approximate location
    for dbId, propData in pairs(spawnedProps) do
        if propData.interaction_zone == zoneId and propData.is_spawned then
            -- This is a simplified match - in production you'd want better entity tracking
            Database_SetPropHarvested(dbId)
            TriggerClientEvent("ogz_propmanager:client:WorldBuilderHarvestProp", -1, dbId)
            DebugPrint("WorldProps harvested prop:", dbId, "in zone:", zoneId)
            return dbId
        end
    end
    return nil
end

exports("OnWorldPropHarvested", OnPropHarvested)

-- Direct call from WorldProps zone harvest
RegisterNetEvent("ogz_propmanager:server:WorldBuilderHarvest", function(dbId)
    local source = source
    if not dbId then return end
    
    if spawnedProps[dbId] then
        Database_SetPropHarvested(dbId)
        TriggerClientEvent("ogz_propmanager:client:WorldBuilderHarvestProp", -1, dbId)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- GET SPAWNED PROP BY ENTITY HASH
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:server:GetSpawnedPropId", function(source, entityHash, coords)
    -- Try to find matching prop
    for dbId, propData in pairs(spawnedProps) do
        local propCoords = propData.coords
        if type(propCoords) == "string" then propCoords = json.decode(propCoords) end
        
        -- Match by approximate coords (within 1 unit)
        local dist = math.sqrt(
            (coords.x - propCoords.x)^2 + 
            (coords.y - propCoords.y)^2 + 
            (coords.z - propCoords.z)^2
        )
        
        if dist < 1.0 then
            return dbId
        end
    end
    return nil
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- GET DELETED PROPS LIST (for admin menu)
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:server:GetDeletedProps", function(source)
    if not IsAdmin(source) then return {} end
    
    local list = {}
    for _, deleteData in pairs(deletedProps) do
        list[#list + 1] = deleteData
    end
    return list
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)
    Database_Init()
    
    -- Initial load
    Database_LoadSpawnedProps()
    Database_LoadDeletedProps()
    
    local spawnCount = 0
    local deleteCount = 0
    for _ in pairs(spawnedProps) do spawnCount = spawnCount + 1 end
    for _ in pairs(deletedProps) do deleteCount = deleteCount + 1 end
    
    print(string.format("^2[OGz PropManager v3.5.2]^0 World Builder: %d spawned, %d deleted props", spawnCount, deleteCount))
end)
