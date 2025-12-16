--[[
    OGz PropManager v3.4 - CLIENT World Props
    
    ═══════════════════════════════════════════════════════════════════════════
    THIS IS THE CLIENT FILE - All database ops go through server events/callbacks
    ═══════════════════════════════════════════════════════════════════════════
]]

if not Config.Features.WorldProps then return end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE TRACKING
-- ═══════════════════════════════════════════════════════════════════════════

local registeredLocationZones = {}   -- Location-based sphere zones
local registeredDiscoveryZones = {}  -- Zone-based lib.zones
local activeZoneProps = {}           -- Currently targeted props per zone
local zoneModelHashes = {}           -- Cached model hashes per zone
local playerInZones = {}             -- Zones player is currently in

-- ═══════════════════════════════════════════════════════════════════════════
-- SETTINGS (with fallbacks)
-- ═══════════════════════════════════════════════════════════════════════════

local Settings = WorldProps.Settings or {}
local Performance = Settings.Performance or {}
local Debug = Settings.Debug or { enabled = true }  -- Default debug ON for testing

local SCAN_INTERVAL = Performance.scanInterval or 2000
local MAX_PROPS_PER_ZONE = Performance.maxPropsPerZone or 150
local CLEANUP_ON_EXIT = Performance.cleanupOnExit ~= false
local DEFAULT_RADIUS = Settings.DefaultRadius or 2.0

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function DebugPrint(...)
    -- Always print for now during testing
    print("[OGz WorldProps]", ...)
end

local function GetLocationHash(coords)
    return string.format("%.2f_%.2f_%.2f", 
        math.floor(coords.x * 100) / 100,
        math.floor(coords.y * 100) / 100,
        math.floor(coords.z * 100) / 100
    )
end

local function GetEntityHash(entity)
    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    return string.format("%d_%.2f_%.2f_%.2f", model, coords.x, coords.y, coords.z)
end

local function FormatTime(seconds)
    if seconds < 60 then return string.format("%ds", seconds)
    elseif seconds < 3600 then return string.format("%dm", math.floor(seconds / 60))
    else return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

local function TableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    return HasAnimDictLoaded(dict)
end

local function Notify(msg, type)
    if lib and lib.notify then
        lib.notify({ description = msg, type = type or "info" })
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYER DATA HELPERS (Client-side)
-- ═══════════════════════════════════════════════════════════════════════════

local function GetPlayerData()
    if exports.qbx_core then
        return exports.qbx_core:GetPlayerData()
    elseif QBCore then
        return QBCore.Functions.GetPlayerData()
    end
    return nil
end

local function HasJob(jobs)
    local playerData = GetPlayerData()
    if not playerData or not playerData.job then return false end
    if type(jobs) == "string" then
        return playerData.job.name == jobs
    elseif type(jobs) == "table" then
        for _, job in ipairs(jobs) do
            if playerData.job.name == job then return true end
        end
    end
    return false
end

local function HasGang(gangs)
    local playerData = GetPlayerData()
    if not playerData or not playerData.gang then return false end
    if type(gangs) == "string" then
        return playerData.gang.name == gangs
    elseif type(gangs) == "table" then
        for _, gang in ipairs(gangs) do
            if playerData.gang.name == gang then return true end
        end
    end
    return false
end

local function HasItem(item)
    if not item then return true end
    local count = exports.ox_inventory:Search('count', item)
    return count and count > 0
end

local function CheckRequirements(requirements)
    if not requirements then return true end
    if requirements.job and not HasJob(requirements.job) then return false end
    if requirements.gang and not HasGang(requirements.gang) then return false end
    if requirements.item and not HasItem(requirements.item) then return false end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ANIMATION + PROGRESS
-- ═══════════════════════════════════════════════════════════════════════════

local function PlayAnimWithProgress(animConfig, progressConfig, callback)
    local ped = PlayerPedId()
    
    if animConfig and animConfig.dict then
        if LoadAnimDict(animConfig.dict) then
            TaskPlayAnim(ped, animConfig.dict, animConfig.name, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end
    
    local success = true
    if progressConfig then
        success = lib.progressBar({
            duration = progressConfig.duration or 3000,
            label = progressConfig.label or "Working...",
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
        })
    else
        Wait(animConfig and animConfig.duration or 2000)
    end
    
    ClearPedTasks(ped)
    if callback then callback(success) end
    return success
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TRIGGER SYSTEM (for custom interactions)
-- ═══════════════════════════════════════════════════════════════════════════

local function ExecuteTrigger(trigger, entity, coords, configId)
    local params = {
        entity = entity,
        coords = coords,
        configId = configId,
        entityHash = GetEntityHash(entity),
        data = trigger.data or {},
    }
    
    DebugPrint("ExecuteTrigger:", trigger.type, trigger.name or trigger.func)
    
    if trigger.type == "event" then
        TriggerEvent(trigger.name, params)
    elseif trigger.type == "server_event" then
        TriggerServerEvent(trigger.name, params)
    elseif trigger.type == "export" then
        if exports[trigger.resource] and exports[trigger.resource][trigger.func] then
            exports[trigger.resource][trigger.func](params)
        else
            DebugPrint("Export not found:", trigger.resource, trigger.func)
        end
    elseif trigger.type == "callback" then
        lib.callback(trigger.name, false, function(result)
            if trigger.onResult then TriggerEvent(trigger.onResult, result, params) end
        end, params)
    elseif trigger.type == "command" then
        ExecuteCommand(trigger.name)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ZONE-BASED AUTO-DISCOVERY SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

function RegisterDiscoveryZones()
    DebugPrint("RegisterDiscoveryZones() called")
    
    -- Clear existing
    for zoneId, zoneData in pairs(registeredDiscoveryZones) do
        if zoneData.zone then
            zoneData.zone:remove()
        end
        if zoneData.blip then
            RemoveBlip(zoneData.blip)
        end
        CleanupZoneProps(zoneId)
    end
    registeredDiscoveryZones = {}
    zoneModelHashes = {}
    
    -- Check if Zones exist
    if not WorldProps.Zones then
        DebugPrint("WARNING: WorldProps.Zones is nil!")
        return
    end
    
    local zoneCount = 0
    for zoneId, config in pairs(WorldProps.Zones) do
        DebugPrint("Processing zone:", zoneId, "enabled:", config.enabled)
        if config.enabled ~= false then
            RegisterSingleDiscoveryZone(zoneId, config)
            zoneCount = zoneCount + 1
        end
    end
    
    DebugPrint("Registered", zoneCount, "discovery zones")
end

function RegisterSingleDiscoveryZone(zoneId, config)
    DebugPrint("Registering zone:", zoneId, "type:", config.zoneType)
    
    -- Pre-hash models for performance
    local modelHashes = {}
    if config.models then
        for _, modelName in ipairs(config.models) do
            local hash = joaat(modelName)
            modelHashes[hash] = true
            DebugPrint("  Model:", modelName, "->", hash)
        end
    end
    zoneModelHashes[zoneId] = modelHashes
    
    -- Create zone based on type
    local zone
    
    if config.zoneType == "circle" then
        DebugPrint("Creating CIRCLE zone at", config.center, "radius:", config.radius)
        zone = lib.zones.sphere({
            coords = config.center,
            radius = config.radius,
            debug = true,  -- FORCE DEBUG ON for testing
            onEnter = function()
                DebugPrint(">>> ENTERED zone:", zoneId)
                OnEnterDiscoveryZone(zoneId, config)
            end,
            onExit = function()
                DebugPrint("<<< EXITED zone:", zoneId)
                OnExitDiscoveryZone(zoneId)
            end,
        })
        
    elseif config.zoneType == "poly" then
        DebugPrint("Creating POLY zone with", #config.points, "points")
        zone = lib.zones.poly({
            points = config.points,
            thickness = (config.maxZ or 10) - (config.minZ or -10),
            debug = true,
            onEnter = function()
                DebugPrint(">>> ENTERED zone:", zoneId)
                OnEnterDiscoveryZone(zoneId, config)
            end,
            onExit = function()
                DebugPrint("<<< EXITED zone:", zoneId)
                OnExitDiscoveryZone(zoneId)
            end,
        })
        
    elseif config.zoneType == "box" then
        DebugPrint("Creating BOX zone at", config.center, "size:", config.size)
        zone = lib.zones.box({
            coords = config.center,
            size = config.size,
            rotation = config.rotation or 0,
            debug = true,
            onEnter = function()
                DebugPrint(">>> ENTERED zone:", zoneId)
                OnEnterDiscoveryZone(zoneId, config)
            end,
            onExit = function()
                DebugPrint("<<< EXITED zone:", zoneId)
                OnExitDiscoveryZone(zoneId)
            end,
        })
    else
        DebugPrint("ERROR: Unknown zoneType:", config.zoneType)
        return
    end
    
    if zone then
        registeredDiscoveryZones[zoneId] = {
            zone = zone,
            config = config,
        }
        DebugPrint("Zone registered successfully:", zoneId)
        
        -- Create blip if configured
        if config.blip and config.blip.enabled then
            CreateZoneBlip(zoneId, config)
        end
    else
        DebugPrint("ERROR: Failed to create zone:", zoneId)
    end
end

function CreateZoneBlip(zoneId, config)
    local coords = config.center or (config.points and config.points[1])
    if not coords then return end
    
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, config.blip.sprite or 1)
    SetBlipColour(blip, config.blip.color or 1)
    SetBlipScale(blip, config.blip.scale or 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(config.blip.label or config.name or zoneId)
    EndTextCommandSetBlipName(blip)
    
    registeredDiscoveryZones[zoneId].blip = blip
    DebugPrint("Created blip for zone:", zoneId)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ZONE ENTER/EXIT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

function OnEnterDiscoveryZone(zoneId, config)
    playerInZones[zoneId] = true
    Notify("Entered: " .. (config.name or zoneId), "info")
    
    -- Initial scan
    ScanZoneForProps(zoneId, config)
    
    -- Start rescan loop
    if SCAN_INTERVAL > 0 then
        CreateThread(function()
            while playerInZones[zoneId] do
                Wait(SCAN_INTERVAL)
                if playerInZones[zoneId] then
                    ScanZoneForProps(zoneId, config)
                end
            end
        end)
    end
end

function OnExitDiscoveryZone(zoneId)
    playerInZones[zoneId] = nil
    Notify("Left zone", "info")
    
    if CLEANUP_ON_EXIT then
        CleanupZoneProps(zoneId)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROP DISCOVERY ENGINE
-- ═══════════════════════════════════════════════════════════════════════════

function ScanZoneForProps(zoneId, config)
    local modelHashes = zoneModelHashes[zoneId]
    if not modelHashes or not next(modelHashes) then
        DebugPrint("No model hashes for zone:", zoneId)
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local foundProps = {}
    local scanRadius = config.radius or 100.0
    
    DebugPrint("Scanning zone:", zoneId, "radius:", scanRadius)
    
    -- Scan game pool for objects
    local allObjects = GetGamePool("CObject")
    DebugPrint("Total objects in pool:", #allObjects)
    
    local matchedCount = 0
    for _, obj in ipairs(allObjects) do
        if DoesEntityExist(obj) then
            local model = GetEntityModel(obj)
            
            if modelHashes[model] then
                matchedCount = matchedCount + 1
                local objCoords = GetEntityCoords(obj)
                local dist = #(playerCoords - objCoords)
                
                -- Check bounds
                local inBounds = true
                if config.minZ and objCoords.z < config.minZ then inBounds = false end
                if config.maxZ and objCoords.z > config.maxZ then inBounds = false end
                
                if inBounds and dist < scanRadius then
                    local entityHash = GetEntityHash(obj)
                    foundProps[entityHash] = obj
                    
                    -- Register target if not already
                    if not activeZoneProps[zoneId] or not activeZoneProps[zoneId][entityHash] then
                        DebugPrint("Found new prop:", entityHash, "dist:", dist)
                        RegisterPropTarget(zoneId, config, obj, entityHash)
                    end
                end
            end
        end
        
        if TableCount(foundProps) >= MAX_PROPS_PER_ZONE then break end
    end
    
    DebugPrint("Matched models:", matchedCount, "In range:", TableCount(foundProps))
    
    -- Cleanup invalid props
    if activeZoneProps[zoneId] then
        for entityHash, entity in pairs(activeZoneProps[zoneId]) do
            if not foundProps[entityHash] or not DoesEntityExist(entity) then
                RemovePropTarget(zoneId, entityHash)
            end
        end
    end
end

function RegisterPropTarget(zoneId, config, entity, entityHash)
    if not activeZoneProps[zoneId] then
        activeZoneProps[zoneId] = {}
    end
    activeZoneProps[zoneId][entityHash] = entity
    
    local options = BuildZoneTargetOptions(zoneId, config, entity, entityHash)
    
    if #options > 0 then
        DebugPrint("Adding", #options, "target options to entity")
        exports.ox_target:addLocalEntity(entity, options)
    else
        DebugPrint("WARNING: No target options built for entity")
    end
end

function RemovePropTarget(zoneId, entityHash)
    if activeZoneProps[zoneId] and activeZoneProps[zoneId][entityHash] then
        local entity = activeZoneProps[zoneId][entityHash]
        if DoesEntityExist(entity) then
            pcall(function() exports.ox_target:removeLocalEntity(entity) end)
        end
        activeZoneProps[zoneId][entityHash] = nil
        DebugPrint("Removed target from entity:", entityHash)
    end
end

function CleanupZoneProps(zoneId)
    if activeZoneProps[zoneId] then
        for entityHash, entity in pairs(activeZoneProps[zoneId]) do
            if DoesEntityExist(entity) then
                pcall(function() exports.ox_target:removeLocalEntity(entity) end)
            end
        end
        activeZoneProps[zoneId] = nil
    end
    DebugPrint("Cleaned up zone:", zoneId)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGET OPTIONS BUILDER
-- ═══════════════════════════════════════════════════════════════════════════

function BuildZoneTargetOptions(zoneId, config, entity, entityHash)
    local options = {}
    local coords = GetEntityCoords(entity)
    
    DebugPrint("Building options for type:", config.type)
    
    -- HARVEST TYPE
    if config.type == "harvest" and config.harvest then
        local harvest = config.harvest
        options[#options + 1] = {
            name = "ogz_harvest_" .. zoneId,
            icon = harvest.icon or "fas fa-leaf",
            iconColor = harvest.iconColor or "#00ff00",
            label = harvest.label or "Harvest",
            distance = harvest.distance or 2.0,
            canInteract = function()
                return CheckRequirements(config.requirements)
            end,
            onSelect = function()
                DebugPrint("Harvest selected!")
                PerformHarvest(zoneId, config, entity, entityHash)
            end,
        }
        DebugPrint("Added HARVEST option")
    
    -- REWARD TYPE
    elseif config.type == "reward" and config.reward then
        local reward = config.reward
        options[#options + 1] = {
            name = "ogz_reward_" .. zoneId,
            icon = reward.icon or "fas fa-search",
            iconColor = reward.iconColor or "#9933ff",
            label = reward.label or "Search",
            distance = reward.distance or 2.0,
            canInteract = function()
                return CheckRequirements(config.requirements)
            end,
            onSelect = function()
                DebugPrint("Reward selected!")
                PerformZoneReward(zoneId, config, entity, entityHash)
            end,
        }
        DebugPrint("Added REWARD option")
    
    -- CUSTOM TYPE (multiple interactions)
    elseif config.type == "custom" and config.interactions then
        for i, interaction in ipairs(config.interactions) do
            options[#options + 1] = {
                name = "ogz_custom_" .. zoneId .. "_" .. i,
                icon = interaction.icon or "fas fa-hand-pointer",
                iconColor = interaction.iconColor or "#ffffff",
                label = interaction.label or "Interact",
                distance = interaction.distance or 2.0,
                canInteract = function()
                    local baseReqs = CheckRequirements(config.requirements)
                    local intReqs = CheckRequirements(interaction.requirements)
                    return baseReqs and intReqs
                end,
                onSelect = function()
                    DebugPrint("Custom interaction selected:", i)
                    PerformCustomInteraction(zoneId, config, entity, entityHash, interaction)
                end,
            }
        end
        DebugPrint("Added", #config.interactions, "CUSTOM options")
    else
        DebugPrint("WARNING: Unknown type or missing config:", config.type)
    end
    
    return options
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INTERACTION HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

function PerformHarvest(zoneId, config, entity, entityHash)
    local harvest = config.harvest
    local coords = GetEntityCoords(entity)
    
    DebugPrint("PerformHarvest:", zoneId)
    
    -- Check cooldown via server callback
    lib.callback('ogz_propmanager:server:CheckZoneCooldown', false, function(onCooldown, remaining)
        if onCooldown then
            Notify(string.format("Come back in %s", FormatTime(remaining)), "error")
            return
        end
        
        PlayAnimWithProgress(harvest.anim, harvest.progress, function(success)
            if success then
                TriggerServerEvent("ogz_propmanager:server:ZoneHarvest", zoneId, entityHash, coords)
                
                if harvest.destroyOnHarvest and DoesEntityExist(entity) then
                    SetEntityAsMissionEntity(entity, true, true)
                    DeleteEntity(entity)
                    RemovePropTarget(zoneId, entityHash)
                end
            else
                Notify("Cancelled", "error")
            end
        end)
    end, zoneId, entityHash, "harvest")
end

function PerformZoneReward(zoneId, config, entity, entityHash)
    local reward = config.reward
    local coords = GetEntityCoords(entity)
    
    DebugPrint("PerformZoneReward:", zoneId)
    
    lib.callback('ogz_propmanager:server:CheckZoneCooldown', false, function(onCooldown, remaining)
        if onCooldown then
            Notify(string.format("Come back in %s", FormatTime(remaining)), "error")
            return
        end
        
        PlayAnimWithProgress(reward.anim, reward.progress, function(success)
            if success then
                TriggerServerEvent("ogz_propmanager:server:ZoneReward", zoneId, entityHash, coords)
            else
                Notify("Cancelled", "error")
            end
        end)
    end, zoneId, entityHash, "reward")
end

function PerformCustomInteraction(zoneId, config, entity, entityHash, interaction)
    local coords = GetEntityCoords(entity)
    
    DebugPrint("PerformCustomInteraction:", zoneId, interaction.label)
    
    local hasCooldown = interaction.cooldown and interaction.cooldown.type ~= "none"
    
    local function doInteraction()
        PlayAnimWithProgress(interaction.anim, interaction.progress, function(success)
            if success then
                if interaction.trigger then
                    ExecuteTrigger(interaction.trigger, entity, coords, zoneId)
                end
                if hasCooldown then
                    TriggerServerEvent("ogz_propmanager:server:SetZoneCooldown", zoneId, entityHash, interaction.cooldown)
                end
            else
                Notify("Cancelled", "error")
            end
        end)
    end
    
    if hasCooldown then
        lib.callback('ogz_propmanager:server:CheckZoneCooldown', false, function(onCooldown, remaining)
            if onCooldown then
                Notify(string.format("Come back in %s", FormatTime(remaining)), "error")
                return
            end
            doInteraction()
        end, zoneId, entityHash, "custom")
    else
        doInteraction()
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOCATION-BASED SYSTEM (Original v3.0 - keeping for compatibility)
-- ═══════════════════════════════════════════════════════════════════════════

function RegisterLocationZones()
    for zoneName, _ in pairs(registeredLocationZones) do
        pcall(function() exports.ox_target:removeZone(zoneName) end)
    end
    registeredLocationZones = {}
    
    if not WorldProps.Locations then
        DebugPrint("No WorldProps.Locations defined")
        return
    end
    
    -- Location-based registration would go here
    -- (keeping structure for future use)
    
    DebugPrint("Registered", TableCount(registeredLocationZones), "location zones")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

local function InitWorldProps()
    DebugPrint("═══════════════════════════════════════════")
    DebugPrint("Initializing WorldProps v3.4")
    DebugPrint("═══════════════════════════════════════════")
    
    if not WorldProps then
        DebugPrint("ERROR: WorldProps table is nil!")
        return
    end
    
    DebugPrint("WorldProps.Zones exists:", WorldProps.Zones ~= nil)
    DebugPrint("WorldProps.Locations exists:", WorldProps.Locations ~= nil)
    
    RegisterLocationZones()
    RegisterDiscoveryZones()
    
    DebugPrint("═══════════════════════════════════════════")
    DebugPrint("WorldProps initialization complete")
    DebugPrint("═══════════════════════════════════════════")
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(3500)
    InitWorldProps()
end)

CreateThread(function()
    Wait(3000)
    local playerData = GetPlayerData()
    if playerData and playerData.citizenid then
        InitWorldProps()
    end
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function()
    RegisterLocationZones()
end)

RegisterNetEvent("QBCore:Client:OnGangUpdate", function()
    RegisterLocationZones()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for zoneName, _ in pairs(registeredLocationZones) do
        pcall(function() exports.ox_target:removeZone(zoneName) end)
    end
    
    for zoneId, zoneData in pairs(registeredDiscoveryZones) do
        if zoneData.zone then zoneData.zone:remove() end
        if zoneData.blip then RemoveBlip(zoneData.blip) end
        CleanupZoneProps(zoneId)
    end
    
    registeredLocationZones = {}
    registeredDiscoveryZones = {}
    activeZoneProps = {}
    playerInZones = {}
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("ogz_worldprop_debug", function()
    print("═══════════════════════════════════════════════════════════════")
    print("[OGz WorldProps] DEBUG INFO")
    print("═══════════════════════════════════════════════════════════════")
    print("Location zones:", TableCount(registeredLocationZones))
    print("Discovery zones:", TableCount(registeredDiscoveryZones))
    print("Player in zones:", json.encode(playerInZones))
    
    for zoneId, props in pairs(activeZoneProps) do
        print("Zone:", zoneId, "- Active props:", TableCount(props))
    end
    print("═══════════════════════════════════════════════════════════════")
end, false)

RegisterCommand("ogz_worldprop_reload", function()
    InitWorldProps()
    Notify("World props reloaded", "success")
end, false)

RegisterCommand("ogz_worldprop_scan", function(source, args)
    local radius = tonumber(args[1]) or 10.0
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    print("═══════════════════════════════════════════════════════════════")
    print("[OGz WorldProps] Scanning for props within", radius, "meters")
    print("═══════════════════════════════════════════════════════════════")
    
    local found = 0
    for _, obj in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(obj) then
            local objCoords = GetEntityCoords(obj)
            local dist = #(playerCoords - objCoords)
            
            if dist <= radius then
                local model = GetEntityModel(obj)
                print(string.format("Model: %d | Coords: vec3(%.2f, %.2f, %.2f) | Dist: %.1fm",
                    model, objCoords.x, objCoords.y, objCoords.z, dist))
                found = found + 1
            end
        end
    end
    
    print("═══════════════════════════════════════════════════════════════")
    print("Found", found, "props")
end, false)

-- Force test zone creation
RegisterCommand("ogz_worldprop_test", function()
    print("Creating test zone at player location...")
    local coords = GetEntityCoords(PlayerPedId())
    
    local testZone = lib.zones.sphere({
        coords = coords,
        radius = 10.0,
        debug = true,
        onEnter = function()
            print("TEST ZONE: ENTERED!")
            Notify("Entered test zone!", "success")
        end,
        onExit = function()
            print("TEST ZONE: EXITED!")
            Notify("Left test zone!", "info")
        end,
    })
    
    print("Test zone created at", coords)
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports("GetActiveZoneProps", function(zoneId) return activeZoneProps[zoneId] end)
exports("IsInZone", function(zoneId) return playerInZones[zoneId] == true end)
exports("ReloadWorldProps", InitWorldProps)

print("^2[OGz PropManager v3.4]^0 WorldProps CLIENT loaded")
