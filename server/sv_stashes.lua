--[[
    OGz PropManager v3.2 - Server Stashes
    
    Handles portable storage containers with ox_inventory stash integration.
    Supports owner, gang, job, and custom access control.
    
    v3.2: Fixed pickup callback, added player-friendly access display
]]

if not Config.Features.Stashes then return end

local QBX = exports.qbx_core
local tablePrefix = Config.Database.TablePrefix

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetPlayer(source) return QBX:GetPlayer(source) end
local function GetCitizenId(source) local p = GetPlayer(source) return p and p.PlayerData.citizenid end
local function DebugPrint(...) if Config.Debug then print("[OGz Stashes]", ...) end end
local function GetStashConfig(stashType) return Stashes[stashType] end

local function GetPlayerGang(source)
    local player = GetPlayer(source)
    if player and player.PlayerData.gang then
        return player.PlayerData.gang.name, player.PlayerData.gang.grade and player.PlayerData.gang.grade.level or 0
    end
    return nil, 0
end

local function GetPlayerJob(source)
    local player = GetPlayer(source)
    if player and player.PlayerData.job then
        return player.PlayerData.job.name, player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0
    end
    return nil, 0
end

local function IsPolice(source)
    if not Config.PoliceOverride.Enabled then return false end
    local player = GetPlayer(source)
    if not player then return false end
    for _, job in ipairs(Config.PoliceOverride.Jobs) do
        if player.PlayerData.job.name == job then return true end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function Database_InitStashes()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_stashes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `stash_id` VARCHAR(100) UNIQUE NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `stash_type` VARCHAR(50) NOT NULL,
            `model` VARCHAR(100) NOT NULL,
            `coords` JSON NOT NULL,
            `heading` FLOAT NOT NULL,
            `routing_bucket` INT DEFAULT 0,
            `access_gang` VARCHAR(50) NULL,
            `access_job` VARCHAR(50) NULL,
            `custom_access` JSON NULL,
            `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_stash_id` (`stash_id`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_bucket` (`routing_bucket`),
            INDEX `idx_type` (`stash_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    DebugPrint("Stash database table initialized")
end

function Database_InsertStash(citizenid, stashId, stashType, model, coords, heading, bucket, accessGang, accessJob)
    local safeHeading = tonumber(heading) or 0.0
    return MySQL.insert.await([[
        INSERT INTO `]] .. tablePrefix .. [[_stashes` 
        (stash_id, citizenid, stash_type, model, coords, heading, routing_bucket, access_gang, access_job)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { stashId, citizenid, stashType, model, json.encode(coords), safeHeading, bucket or 0, accessGang, accessJob })
end

function Database_GetStash(propId)
    local result = MySQL.single.await([[SELECT * FROM `]] .. tablePrefix .. [[_stashes` WHERE id = ?]], { propId })
    if result then 
        result.coords = json.decode(result.coords)
        result.custom_access = result.custom_access and json.decode(result.custom_access) or {}
    end
    return result
end

function Database_GetStashByStashId(stashId)
    local result = MySQL.single.await([[SELECT * FROM `]] .. tablePrefix .. [[_stashes` WHERE stash_id = ?]], { stashId })
    if result then 
        result.coords = json.decode(result.coords)
        result.custom_access = result.custom_access and json.decode(result.custom_access) or {}
    end
    return result
end

function Database_GetStashesByBucket(bucket)
    local result = MySQL.query.await([[SELECT * FROM `]] .. tablePrefix .. [[_stashes` WHERE routing_bucket = ?]], { bucket })
    for _, row in ipairs(result or {}) do 
        row.coords = json.decode(row.coords)
        row.custom_access = row.custom_access and json.decode(row.custom_access) or {}
    end
    return result or {}
end

function Database_GetStashesByCitizen(citizenid)
    local result = MySQL.query.await([[SELECT * FROM `]] .. tablePrefix .. [[_stashes` WHERE citizenid = ?]], { citizenid })
    for _, row in ipairs(result or {}) do 
        row.coords = json.decode(row.coords)
        row.custom_access = row.custom_access and json.decode(row.custom_access) or {}
    end
    return result or {}
end

function Database_GetAllStashes()
    local result = MySQL.query.await([[SELECT * FROM `]] .. tablePrefix .. [[_stashes`]])
    for _, row in ipairs(result or {}) do 
        row.coords = json.decode(row.coords)
        row.custom_access = row.custom_access and json.decode(row.custom_access) or {}
    end
    return result or {}
end

function Database_DeleteStash(propId)
    return MySQL.update.await([[DELETE FROM `]] .. tablePrefix .. [[_stashes` WHERE id = ?]], { propId }) > 0
end

function Database_UpdateCustomAccess(propId, customAccess)
    return MySQL.update.await([[UPDATE `]] .. tablePrefix .. [[_stashes` SET custom_access = ? WHERE id = ?]], 
        { json.encode(customAccess), propId })
end

function Database_CountStashesByType(citizenid, stashType)
    return MySQL.scalar.await([[SELECT COUNT(*) FROM `]] .. tablePrefix .. [[_stashes` WHERE citizenid = ? AND stash_type = ?]], 
        { citizenid, stashType }) or 0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STASH ACCESS CONTROL
-- ═══════════════════════════════════════════════════════════════════════════

function HasStashAccess(source, stashData)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end
    
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return false end
    
    -- Owner always has access
    if stashData.citizenid == citizenid then
        return true
    end
    
    -- Police override
    if Config.Stashes.PoliceCanSearch and IsPolice(source) then
        return true
    end
    
    -- Check gang access
    if stashData.access_gang then
        local playerGang = GetPlayerGang(source)
        if playerGang == stashData.access_gang then
            return true
        end
    end
    
    -- Check job access
    if stashData.access_job then
        local playerJob = GetPlayerJob(source)
        if playerJob == stashData.access_job then
            return true
        end
    end
    
    -- Check custom access list
    if stashData.custom_access and type(stashData.custom_access) == "table" then
        for _, accessCid in ipairs(stashData.custom_access) do
            if accessCid == citizenid then
                return true
            end
        end
    end
    
    -- Check stash config groups
    if stashConfig.stash and stashConfig.stash.groups then
        local playerJob, jobGrade = GetPlayerJob(source)
        if stashConfig.stash.groups[playerJob] then
            local requiredGrade = stashConfig.stash.groups[playerJob]
            if jobGrade >= requiredGrade then
                return true
            end
        end
    end
    
    return false
end

function CanManageStash(source, stashData)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end
    
    -- Only owner can manage
    return stashData.citizenid == citizenid
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ox_inventory STASH REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

local registeredStashes = {}

function RegisterOxStash(stashId, stashConfig)
    if registeredStashes[stashId] then return true end
    
    local slots = stashConfig.stash and stashConfig.stash.slots or Config.Stashes.DefaultSlots
    local maxWeight = stashConfig.stash and stashConfig.stash.maxWeight or Config.Stashes.DefaultMaxWeight
    
    exports.ox_inventory:RegisterStash(stashId, stashConfig.label, slots, maxWeight)
    registeredStashes[stashId] = true
    DebugPrint("Registered ox_inventory stash:", stashId, "Slots:", slots, "Weight:", maxWeight)
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:server:CheckStashAccess", function(source, propId)
    local stashData = Database_GetStash(propId)
    if not stashData then return false, "Stash not found" end
    
    local hasAccess = HasStashAccess(source, stashData)
    return hasAccess, hasAccess and stashData.stash_id or nil
end)

lib.callback.register("ogz_propmanager:server:GetStashData", function(source, propId)
    return Database_GetStash(propId)
end)

lib.callback.register("ogz_propmanager:server:CanManageStash", function(source, propId)
    local stashData = Database_GetStash(propId)
    if not stashData then return false end
    return CanManageStash(source, stashData)
end)

lib.callback.register("ogz_propmanager:server:IsStashEmpty", function(source, stashId)
    local items = exports.ox_inventory:GetInventoryItems(stashId)
    if not items then return true end
    for _ in pairs(items) do return false end
    return true
end)

---Get player info from citizenid (for friendly display in access list)
lib.callback.register("ogz_propmanager:server:GetPlayerInfoByCid", function(source, targetCitizenId)
    -- First check if player is online
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local player = QBX:GetPlayer(tonumber(playerId))
        if player and player.PlayerData.citizenid == targetCitizenId then
            return {
                name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                source = playerId,
                online = true,
                citizenid = targetCitizenId
            }
        end
    end
    
    -- Player offline - check database for character name
    local result = MySQL.single.await([[
        SELECT JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) as firstname,
               JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) as lastname
        FROM players WHERE citizenid = ?
    ]], { targetCitizenId })
    
    if result and result.firstname then
        return {
            name = result.firstname .. " " .. result.lastname,
            source = nil,
            online = false,
            citizenid = targetCitizenId
        }
    end
    
    -- Fallback to showing citizenid
    return {
        name = targetCitizenId,
        source = nil,
        online = false,
        citizenid = targetCitizenId
    }
end)

---Get nearby player list for adding access (shows server ID and name)
lib.callback.register("ogz_propmanager:server:GetNearbyPlayers", function(source, maxDistance)
    local sourcePlayer = QBX:GetPlayer(source)
    if not sourcePlayer then return {} end
    
    local sourcePed = GetPlayerPed(source)
    local sourceCoords = GetEntityCoords(sourcePed)
    maxDistance = maxDistance or 10.0
    
    local nearbyPlayers = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local targetId = tonumber(playerId)
        if targetId ~= source then
            local targetPed = GetPlayerPed(targetId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(sourceCoords - targetCoords)
            
            if distance <= maxDistance then
                local player = QBX:GetPlayer(targetId)
                if player then
                    nearbyPlayers[#nearbyPlayers + 1] = {
                        source = targetId,
                        citizenid = player.PlayerData.citizenid,
                        name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                        distance = math.floor(distance * 10) / 10
                    }
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(nearbyPlayers, function(a, b) return a.distance < b.distance end)
    
    return nearbyPlayers
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEMENT & ITEM CHECK
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:CheckStashLimit", function(stashType, itemName)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stashConfig = GetStashConfig(stashType)
    if not stashConfig then return end
    
    -- Check limits (using station limits config)
    local maxSame = Config.Ownership.MaxSameStation
    if maxSame > 0 then
        local currentCount = Database_CountStashesByType(citizenid, stashType)
        if currentCount >= maxSame then
            TriggerClientEvent("ogz_propmanager:client:StashLimitReached", source, currentCount, maxSame)
            return
        end
    end
    
    if exports.ox_inventory:RemoveItem(source, itemName, 1) then
        TriggerClientEvent("ogz_propmanager:client:StartStashPlacement", source, stashType)
    else
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Item not found in inventory", "error")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACE STASH
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:PlaceStash", function(data)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stashConfig = GetStashConfig(data.stashType)
    if not stashConfig then return end
    
    -- Generate unique stash ID
    local stashId = Config.Stashes.IdPrefix .. os.time() .. "_" .. math.random(1000, 9999)
    
    -- Determine access
    local accessGang = nil
    local accessJob = nil
    
    if stashConfig.stash and stashConfig.stash.shareWithGang then
        accessGang = GetPlayerGang(source)
    end
    
    if stashConfig.stash and stashConfig.stash.shareWithJob then
        accessJob = GetPlayerJob(source)
    end
    
    DebugPrint("PlaceStash - StashID:", stashId, "Type:", data.stashType, "Heading:", data.heading)
    
    local propId = Database_InsertStash(citizenid, stashId, data.stashType, stashConfig.model, data.coords, data.heading or 0.0, data.bucket or 0, accessGang, accessJob)
    
    if propId then
        -- Register with ox_inventory
        RegisterOxStash(stashId, stashConfig)
        
        local propData = {
            id = propId,
            stash_id = stashId,
            citizenid = citizenid,
            stash_type = data.stashType,
            model = stashConfig.model,
            coords = data.coords,
            heading = data.heading,
            routing_bucket = data.bucket or 0,
            access_gang = accessGang,
            access_job = accessJob,
            custom_access = {},
        }
        
        -- Log placement
        Database_Log(propId, citizenid, "place_stash", data.stashType, nil, nil, nil, { stash_id = stashId }, data.coords)
        
        -- Notify clients in same bucket
        for _, playerId in ipairs(GetPlayers()) do
            if GetPlayerRoutingBucket(playerId) == (data.bucket or 0) then
                TriggerClientEvent("ogz_propmanager:client:SpawnStash", playerId, propData)
            end
        end
        
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.StashPlaced, "success")
        DebugPrint("Placed stash:", data.stashType, "ID:", stashId, "by:", citizenid)
    else
        exports.ox_inventory:AddItem(source, stashConfig.item, 1)
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.PlaceFail, "error")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- REMOVE STASH
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:RemoveStash", function(propId, isSeizure)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stashData = Database_GetStash(propId)
    if not stashData then return end
    
    local stashConfig = GetStashConfig(stashData.stash_type)
    
    -- Check permissions
    local canRemove = isSeizure and Config.Stashes.PoliceCanSeize and IsPolice(source)
    if not canRemove then
        canRemove = stashData.citizenid == citizenid
    end
    
    if not canRemove then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.NotOwner, "error")
        return
    end
    
    -- Check if stash is empty (unless police seizing)
    if not isSeizure then
        local items = exports.ox_inventory:GetInventoryItems(stashData.stash_id)
        local hasItems = false
        if items then
            for _ in pairs(items) do
                hasItems = true
                break
            end
        end
        
        if hasItems then
            TriggerClientEvent("ogz_propmanager:client:Notify", source, "Stash must be empty before picking up!", "error")
            return
        end
    end
    
    -- Log action
    Database_Log(propId, citizenid, isSeizure and "seize_stash" or "remove_stash", stashData.stash_type, nil, nil, nil, 
        { originalOwner = stashData.citizenid, stash_id = stashData.stash_id }, stashData.coords)
    
    Database_DeleteStash(propId)
    
    -- Return item
    if stashConfig then
        if isSeizure then
            if Config.PoliceOverride.ReturnItem then 
                exports.ox_inventory:AddItem(source, stashConfig.item, 1) 
            end
            TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.PoliceSeize, "success")
        else
            exports.ox_inventory:AddItem(source, stashConfig.item, 1)
            TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.StashRemoved, "success")
        end
    end
    
    -- Notify all clients in bucket to remove
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerRoutingBucket(playerId) == (stashData.routing_bucket or 0) then
            TriggerClientEvent("ogz_propmanager:client:RemoveStash", playerId, propId)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- OPEN STASH
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:OpenStash", function(propId)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stashData = Database_GetStash(propId)
    if not stashData then return end
    
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return end
    
    -- Check access
    if not HasStashAccess(source, stashData) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.StashNoAccess, "error")
        return
    end
    
    -- Register if needed and open
    RegisterOxStash(stashData.stash_id, stashConfig)
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashData.stash_id)
    
    DebugPrint("Opened stash:", stashData.stash_id, "for:", citizenid)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- MANAGE ACCESS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:AddStashAccess", function(propId, targetCitizenId)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stashData = Database_GetStash(propId)
    if not stashData then return end
    
    if not CanManageStash(source, stashData) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Only the owner can manage access", "error")
        return
    end
    
    local customAccess = stashData.custom_access or {}
    
    -- Check if already has access
    for _, cid in ipairs(customAccess) do
        if cid == targetCitizenId then
            TriggerClientEvent("ogz_propmanager:client:Notify", source, "Player already has access", "error")
            return
        end
    end
    
    table.insert(customAccess, targetCitizenId)
    Database_UpdateCustomAccess(propId, customAccess)
    
    TriggerClientEvent("ogz_propmanager:client:Notify", source, "Access granted!", "success")
    DebugPrint("Added access for", targetCitizenId, "to stash", stashData.stash_id)
end)

RegisterNetEvent("ogz_propmanager:server:RemoveStashAccess", function(propId, targetCitizenId)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stashData = Database_GetStash(propId)
    if not stashData then return end
    
    if not CanManageStash(source, stashData) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Only the owner can manage access", "error")
        return
    end
    
    local customAccess = stashData.custom_access or {}
    local newAccess = {}
    
    for _, cid in ipairs(customAccess) do
        if cid ~= targetCitizenId then
            table.insert(newAccess, cid)
        end
    end
    
    Database_UpdateCustomAccess(propId, newAccess)
    
    TriggerClientEvent("ogz_propmanager:client:Notify", source, "Access revoked!", "success")
    DebugPrint("Removed access for", targetCitizenId, "from stash", stashData.stash_id)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- REQUEST STASHES (On Player Load)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:RequestStashes", function(bucket)
    local source = source
    local stashes = Database_GetStashesByBucket(bucket or 0)
    
    -- Register all stashes with ox_inventory
    for _, stashData in ipairs(stashes) do
        local stashConfig = GetStashConfig(stashData.stash_type)
        if stashConfig then
            RegisterOxStash(stashData.stash_id, stashConfig)
        end
    end
    
    TriggerClientEvent("ogz_propmanager:client:LoadStashes", source, stashes)
end)

RegisterNetEvent("ogz_propmanager:server:StashPlacementCancelled", function(itemName)
    local source = source
    if itemName then exports.ox_inventory:AddItem(source, itemName, 1) end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)
    Database_InitStashes()
    
    -- Pre-register all existing stashes
    local allStashes = Database_GetAllStashes()
    for _, stashData in ipairs(allStashes) do
        local stashConfig = GetStashConfig(stashData.stash_type)
        if stashConfig then
            RegisterOxStash(stashData.stash_id, stashConfig)
        end
    end
    
    local count = 0
    for _ in pairs(Stashes) do count = count + 1 end
    print("^2[OGz PropManager v3.0]^0 Stash system loaded with", count, "stash types,", #allStashes, "placed stashes")
end)
