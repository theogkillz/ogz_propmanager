--[[
    OGz PropManager - Server Main v2
    
    Core server logic with durability, cooldowns, events, and logging
]]

local QBX = exports.qbx_core

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetPlayer(source) return QBX:GetPlayer(source) end
local function GetCitizenId(source) local p = GetPlayer(source) return p and p.PlayerData.citizenid end
local function DebugPrint(...) if Config.Debug then print("[OGz PropManager]", ...) end end
local function GetStationConfig(stationId) return Stations[stationId] end

-- Item label cache
local itemLabelCache = {}

---Get the display label for an item (player-friendly name)
---@param itemName string The item's internal name
---@return string The item's label or formatted name
local function GetItemLabel(itemName)
    if not itemName then return "Unknown Item" end
    
    -- Check cache first
    if itemLabelCache[itemName] then
        return itemLabelCache[itemName]
    end
    
    -- Try to get from ox_inventory
    local success, itemData = pcall(function()
        return exports.ox_inventory:Items(itemName)
    end)
    
    if success and itemData and itemData.label then
        itemLabelCache[itemName] = itemData.label
        return itemData.label
    end
    
    -- Fallback: Format the item name nicely
    local formatted = itemName:gsub("_", " "):gsub("(%a)([%w]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    itemLabelCache[itemName] = formatted
    return formatted
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
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:server:CheckCooldown", function(source, propId)
    if not Config.Cooldown.Enabled then return false, 0 end
    return Database_IsOnCooldown(propId)
end)

lib.callback.register("ogz_propmanager:server:GetPlayerBucket", function(source)
    return GetPlayerRoutingBucket(source) or 0
end)

lib.callback.register("ogz_propmanager:server:GetStationDurability", function(source, propId)
    local station = Database_GetStation(propId)
    if station then
        return station.durability or 100
    end
    return 100
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION LIMIT CHECK
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:CheckStationLimit", function(stationId, itemName)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stationConfig = GetStationConfig(stationId)
    if not stationConfig then return end
    
    local maxSame = Config.Ownership.MaxSameStation
    if maxSame > 0 then
        local currentCount = Database_CountStationsByType(citizenid, stationId)
        if currentCount >= maxSame then
            TriggerClientEvent("ogz_propmanager:client:StationLimitReached", source, currentCount, maxSame)
            return
        end
    end
    
    if exports.ox_inventory:RemoveItem(source, itemName, 1) then
        TriggerClientEvent("ogz_propmanager:client:StartPlacement", source, stationId)
    else
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "Item not found in inventory", "error")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACE STATION
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:PlaceStation", function(data)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local stationConfig = GetStationConfig(data.stationId)
    if not stationConfig then return end
    
    local durability = stationConfig.durability and stationConfig.durability.max or 100
    
    DebugPrint("PlaceStation received - Heading:", data.heading, type(data.heading))
    
    local propId = Database_InsertStation(citizenid, data.stationId, stationConfig.model, data.coords, data.heading or 0.0, data.bucket or 0, durability)
    
    if propId then
        local propData = {
            id = propId, citizenid = citizenid, station_id = data.stationId,
            model = stationConfig.model, coords = data.coords, heading = data.heading,
            routing_bucket = data.bucket or 0, durability = durability,
        }
        
        -- Log placement
        Database_Log(propId, citizenid, "place", data.stationId, nil, nil, nil, nil, data.coords)
        
        -- Notify clients in same bucket
        for _, playerId in ipairs(GetPlayers()) do
            if GetPlayerRoutingBucket(playerId) == (data.bucket or 0) then
                TriggerClientEvent("ogz_propmanager:client:SpawnProp", playerId, propData)
            end
        end
        
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.PlaceSuccess, "success")
        DebugPrint("Placed:", data.stationId, "by:", citizenid)
    else
        exports.ox_inventory:AddItem(source, stationConfig.item, 1)
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.PlaceFail, "error")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- REMOVE STATION
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:RemoveStation", function(propId, isSeizure)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local propData = Database_GetStation(propId)
    if not propData then return end
    
    -- Prevent removal of predefined (permanent) props
    if propData.citizenid == 'PREDEFINED' then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, "This station is permanent and cannot be removed.", "error")
        return
    end
    
    local stationConfig = GetStationConfig(propData.station_id)
    local canRemove = isSeizure and IsPolice(source) or propData.citizenid == citizenid
    
    if not canRemove then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.NotOwner, "error")
        return
    end
    
    -- Log action
    Database_Log(propId, citizenid, isSeizure and "seize" or "remove", propData.station_id, nil, nil, nil, { originalOwner = propData.citizenid }, propData.coords)
    
    Database_DeleteStation(propId)
    
    -- Return item
    if stationConfig then
        if isSeizure then
            if Config.PoliceOverride.ReturnItem then exports.ox_inventory:AddItem(source, stationConfig.item, 1) end
            TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.PoliceSeize, "success")
        else
            exports.ox_inventory:AddItem(source, stationConfig.item, 1)
            TriggerClientEvent("ogz_propmanager:client:Notify", source, Config.Notifications.RemoveSuccess, "success")
        end
    end
    
    -- Notify clients
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerRoutingBucket(playerId) == propData.routing_bucket then
            TriggerClientEvent("ogz_propmanager:client:RemoveProp", playerId, propId)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- REPAIR STATION
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:RepairStation", function(propId)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local propData = Database_GetStation(propId)
    if not propData then return end
    
    local stationConfig = GetStationConfig(propData.station_id)
    local repairItem = (stationConfig and stationConfig.durability and stationConfig.durability.repairItem) or Config.Durability.DefaultRepairItem
    local repairItemLabel = GetItemLabel(repairItem)
    
    if not exports.ox_inventory:RemoveItem(source, repairItem, 1) then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, string.format("Missing %s!", repairItemLabel), "error")
        return
    end
    
    local newDurability = math.min(100, (propData.durability or 0) + Config.Durability.RepairAmount)
    Database_UpdateDurability(propId, newDurability)
    
    Database_Log(propId, citizenid, "repair", propData.station_id, nil, nil, nil, { oldDurability = propData.durability, newDurability = newDurability })
    
    TriggerClientEvent("ogz_propmanager:client:Notify", source, string.format(Config.Notifications.DurabilityRepaired, Config.Durability.RepairAmount), "success")
    TriggerClientEvent("ogz_propmanager:client:UpdateDurability", -1, propId, newDurability)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CRAFT COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:OnCraftComplete", function(propId, itemName, quantity)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local propData = Database_GetStation(propId)
    if not propData then return end
    
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return end
    
    -- Reduce durability
    if Config.Durability.Enabled and stationConfig.durability then
        local cost = stationConfig.durability.craftCost or 2
        Database_ReduceDurability(propId, cost)
        
        local newDur = Database_GetDurability(propId)
        TriggerClientEvent("ogz_propmanager:client:UpdateDurability", -1, propId, newDur)
    end
    
    -- Handle cooldown
    if Config.Cooldown.Enabled and stationConfig.cooldown then
        local maxCrafts = stationConfig.cooldown.craftsBeforeCooldown or 10
        local cooldownTime = math.floor((stationConfig.cooldown.cooldownTime or 300) * Config.Cooldown.GlobalCooldownMultiplier)
        
        local started, duration = Database_IncrementCraftCount(propId, maxCrafts, cooldownTime)
        if started and Config.Cooldown.NotifyOnCooldown then
            TriggerClientEvent("ogz_propmanager:client:Notify", source, string.format("Station entering cooldown for %d seconds", duration), "warning")
        end
    end
    
    -- Log craft
    Database_Log(propId, citizenid, "craft", propData.station_id, itemName, quantity, nil, nil, propData.coords)
    
    DebugPrint("Craft:", itemName, "x" .. quantity, "by:", citizenid)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DURABILITY MODIFICATION
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:ModifyDurability", function(propId, change)
    local source = source
    
    local propData = Database_GetStation(propId)
    if not propData then return end
    
    local newDur = math.max(0, math.min(100, (propData.durability or 100) + change))
    Database_UpdateDurability(propId, newDur)
    
    TriggerClientEvent("ogz_propmanager:client:UpdateDurability", -1, propId, newDur)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT LOGGING
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:LogEvent", function(propId, eventId, eventLabel)
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local propData = Database_GetStation(propId)
    if not propData then return end
    
    Database_Log(propId, citizenid, "event", propData.station_id, nil, nil, eventId, { eventLabel = eventLabel }, propData.coords)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- POLICE ALERT
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:AlertPolice", function(propId, propData)
    -- Integrate with your dispatch system here
    -- Example: TriggerEvent('ps-dispatch:server:notify', { ... })
    DebugPrint("Police alert triggered for station:", propData.station_id)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- REQUEST PROPS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:server:RequestProps", function(bucket)
    local source = source
    local props = Database_GetStationsByBucket(bucket or 0)
    TriggerClientEvent("ogz_propmanager:client:LoadProps", source, props)
end)

RegisterNetEvent("ogz_propmanager:server:PlacementCancelled", function(itemName)
    local source = source
    if itemName then exports.ox_inventory:AddItem(source, itemName, 1) end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- LOG CLEANUP SCHEDULER
-- ═══════════════════════════════════════════════════════════════════════════

if Config.Logging.Enabled and Config.Logging.RetentionDays > 0 then
    CreateThread(function()
        while true do
            Wait(86400000)  -- Run once per day
            local deleted = Database_ClearOldLogs(Config.Logging.RetentionDays)
            if deleted > 0 then print("[OGz PropManager] Cleaned up", deleted, "old log entries") end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

-- Spawn predefined props for all stations
local function SpawnPredefinedProps()
    local count = 0
    for stationId, stationConfig in pairs(Stations) do
        if stationConfig.predefinedSpots and #stationConfig.predefinedSpots > 0 then
            for i, spot in ipairs(stationConfig.predefinedSpots) do
                -- spot is vec4(x, y, z, heading)
                local coords = { x = spot.x, y = spot.y, z = spot.z }
                local heading = spot.w or 0.0
                
                -- Check if this predefined spot already exists in database
                local exists = MySQL.scalar.await([[
                    SELECT id FROM `]] .. Config.Database.TablePrefix .. [[` 
                    WHERE station_id = ? AND citizenid = 'PREDEFINED' 
                    AND JSON_EXTRACT(coords, '$.x') = ? 
                    AND JSON_EXTRACT(coords, '$.y') = ?
                ]], { stationId, coords.x, coords.y })
                
                if not exists then
                    -- Insert as 'PREDEFINED' owner (permanent, can't be removed)
                    local durability = stationConfig.durability and stationConfig.durability.max or 100
                    local propId = Database_InsertStation('PREDEFINED', stationId, stationConfig.model, coords, heading, 0, durability)
                    if propId then
                        count = count + 1
                        print(string.format("[OGz PropManager] Spawned predefined %s at %.2f, %.2f, %.2f", stationConfig.label, coords.x, coords.y, coords.z))
                    end
                end
            end
        end
    end
    if count > 0 then
        print(string.format("[OGz PropManager] Created %d new predefined props", count))
    end
end

-- Notify client of bucket on spawn and send props
RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
    local source = source
    Wait(2000)
    local bucket = GetPlayerRoutingBucket(source) or 0
    TriggerClientEvent("ogz_propmanager:client:SetBucket", source, bucket)
    
    local props = Database_GetStationsByBucket(bucket)
    TriggerClientEvent("ogz_propmanager:client:LoadProps", source, props)
    
    TriggerClientEvent("ogz_propmanager:client:SetAdmin", source, IsPlayerAdmin(source))
end)

CreateThread(function()
    Wait(3000)  -- Wait for database to initialize
    
    -- Spawn predefined props
    SpawnPredefinedProps()
    
    local count = 0
    for _ in pairs(Stations) do count = count + 1 end
    print("^2[OGz PropManager v2.0]^0 Loaded with", count, "station types")
end)
