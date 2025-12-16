--[[
    ═══════════════════════════════════════════════════════════════════════════
    OGz PropManager v3.5 - CLIENT World Builder
    ═══════════════════════════════════════════════════════════════════════════
    
    Handles:
    - Admin commands for spawning/deleting props
    - Delete mode for targeting props
    - Loading spawned props from server
    - Hiding deleted native props
    - Integration with placement.lua
    
    ═══════════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════════════

local spawnedProps = {}              -- [dbId] = { entity, model, coords, ... }
local deletedNativeProps = {}        -- [hash] = { coords, radius, ... }
local hiddenEntities = {}            -- Entities we've hidden this session

local isDeleteMode = false           -- Currently in delete mode?
local isAdmin = false                -- Cached admin status

-- ═══════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

local Settings = WorldBuilder.Settings or {}
local AdminSettings = Settings.Admin or {}
local DeleteSettings = Settings.Delete or {}
local SyncSettings = Settings.Sync or {}
local DebugSettings = Settings.Debug or { enabled = true }

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function DebugPrint(...)
    if DebugSettings.enabled then
        print("[OGz WorldBuilder]", ...)
    end
end

local function Notify(msg, type)
    if lib and lib.notify then
        lib.notify({ description = msg, type = type or "info" })
    end
end

local function LoadModel(model)
    local hash = type(model) == "string" and joaat(model) or model
    if HasModelLoaded(hash) then return hash end
    
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    return HasModelLoaded(hash) and hash or nil
end

local function GetEntityHash(entity)
    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    return string.format("%d_%.2f_%.2f_%.2f", model, coords.x, coords.y, coords.z)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN CHECK
-- ═══════════════════════════════════════════════════════════════════════════

local function CheckAdmin(callback)
    lib.callback('ogz_propmanager:server:CheckWorldBuilderAdmin', false, function(result)
        isAdmin = result
        if callback then callback(result) end
    end)
end

local function RequireAdmin()
    if not isAdmin then
        Notify("You don't have permission to use World Builder", "error")
        return false
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROP SPAWNING (Client-side entity creation)
-- ═══════════════════════════════════════════════════════════════════════════

local function SpawnPropEntity(propData)
    local modelHash = LoadModel(propData.model)
    if not modelHash then
        DebugPrint("Failed to load model:", propData.model)
        return nil
    end
    
    local coords = propData.coords
    if type(coords) == "table" and not coords.x then
        coords = vec3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
    end
    
    local entity = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
    
    if DoesEntityExist(entity) then
        SetEntityHeading(entity, propData.heading or 0.0)
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, true, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        DebugPrint("Spawned prop:", propData.id, propData.model, "at", coords)
        return entity
    end
    
    return nil
end

local function DespawnPropEntity(dbId)
    if spawnedProps[dbId] then
        local entity = spawnedProps[dbId].entity
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        spawnedProps[dbId] = nil
        DebugPrint("Despawned prop:", dbId)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- NATIVE PROP HIDING
-- ═══════════════════════════════════════════════════════════════════════════

local function HideNativeProp(deleteData)
    local modelHash = type(deleteData.model) == "string" and joaat(deleteData.model) or deleteData.model
    local coords = deleteData.coords
    local radius = deleteData.radius or 1.0
    
    -- Find and hide the native prop
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, radius, modelHash, false, false, false)
    
    if DoesEntityExist(entity) then
        SetEntityAsMissionEntity(entity, true, true)
        SetEntityVisible(entity, false, false)
        SetEntityCollision(entity, false, false)
        FreezeEntityPosition(entity, true)
        
        hiddenEntities[#hiddenEntities + 1] = {
            entity = entity,
            hash = GetEntityHash(entity),
        }
        
        DebugPrint("Hidden native prop:", deleteData.model, "at", coords)
        return true
    end
    
    return false
end

local function UnhideNativeProp(entity)
    if DoesEntityExist(entity) then
        SetEntityVisible(entity, true, true)
        SetEntityCollision(entity, true, true)
        SetEntityAsMissionEntity(entity, false, true)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOAD PROPS FROM SERVER
-- ═══════════════════════════════════════════════════════════════════════════

local function LoadSpawnedProps(props)
    DebugPrint("Loading", #props, "spawned props")
    
    for _, propData in ipairs(props) do
        -- Parse coords if needed
        if type(propData.coords) == "string" then
            propData.coords = json.decode(propData.coords)
        end
        
        -- Only spawn if visible (not harvested and awaiting respawn)
        if propData.is_spawned then
            local entity = SpawnPropEntity(propData)
            if entity then
                spawnedProps[propData.id] = {
                    entity = entity,
                    model = propData.model,
                    coords = propData.coords,
                    heading = propData.heading,
                    zone = propData.interaction_zone,
                    respawnTime = propData.respawn_time,
                }
            end
        end
    end
end

local function LoadDeletedProps(deletes)
    DebugPrint("Loading", #deletes, "deleted props to hide")
    
    for _, deleteData in ipairs(deletes) do
        if type(deleteData.coords) == "string" then
            deleteData.coords = json.decode(deleteData.coords)
        end
        
        deletedNativeProps[deleteData.id] = deleteData
        HideNativeProp(deleteData)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEMENT INTEGRATION
-- ═══════════════════════════════════════════════════════════════════════════
--[[
    These functions integrate with your existing placement.lua
    The placement system handles the ghost preview, controls, etc.
    We just need to provide the callbacks for when placement completes.
]]

-- Called when admin wants to spawn a prop
function StartWorldPropPlacement(model, options)
    options = options or {}
    
    local modelHash = LoadModel(model)
    if not modelHash then
        Notify("Invalid model: " .. tostring(model), "error")
        return
    end
    
    -- Build placement data for placement.lua
    local placementData = {
        placementType = "worldbuilder",
        model = model,
        modelHash = modelHash,
        label = options.label or model,
        zone = options.zone,                    -- Optional WorldProps zone link
        respawnTime = options.respawnTime or 0, -- 0 = no respawn
        groupId = options.groupId,              -- Optional spawn group
    }
    
    -- Check if StartWorldBuilderPlacement exists in placement.lua
    if StartWorldBuilderPlacement then
        StartWorldBuilderPlacement(placementData)
    else
        -- Fallback: Use our own simple placement
        StartSimplePlacement(placementData)
    end
end

-- Simple placement fallback if placement.lua doesn't have our function yet
function StartSimplePlacement(placementData)
    local modelHash = placementData.modelHash
    local ghostProp = CreateObject(modelHash, 0, 0, 0, false, false, false)
    
    if not DoesEntityExist(ghostProp) then
        Notify("Failed to create preview", "error")
        return
    end
    
    SetEntityAlpha(ghostProp, 150, false)
    SetEntityCollision(ghostProp, false, false)
    FreezeEntityPosition(ghostProp, true)
    
    local isPlacing = true
    local currentHeading = 0.0
    
    Notify("ENTER to place | BACKSPACE to cancel | SCROLL to rotate", "info")
    
    CreateThread(function()
        while isPlacing do
            Wait(0)
            
            -- Update position with raycast
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)
            local endCoords = camCoords + (forward * 10.0)
            
            local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 1 + 16, PlayerPedId(), 0)
            local _, hit, hitCoords, _, _ = GetShapeTestResult(ray)
            
            if hit then
                SetEntityCoords(ghostProp, hitCoords.x, hitCoords.y, hitCoords.z, false, false, false, false)
                PlaceObjectOnGroundProperly(ghostProp)
            end
            
            SetEntityHeading(ghostProp, currentHeading)
            
            -- Controls
            if IsControlPressed(0, 15) then currentHeading = currentHeading + 2.0 end  -- Scroll up
            if IsControlPressed(0, 14) then currentHeading = currentHeading - 2.0 end  -- Scroll down
            
            -- Place
            if IsControlJustPressed(0, 215) then  -- ENTER
                isPlacing = false
                local finalCoords = GetEntityCoords(ghostProp)
                local finalHeading = GetEntityHeading(ghostProp)
                
                DeleteEntity(ghostProp)
                
                -- Send to server
                TriggerServerEvent("ogz_propmanager:server:WorldBuilderSpawn", {
                    model = placementData.model,
                    coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
                    heading = finalHeading,
                    zone = placementData.zone,
                    respawnTime = placementData.respawnTime,
                    groupId = placementData.groupId,
                })
                
                Notify("Prop placed!", "success")
            end
            
            -- Cancel
            if IsControlJustPressed(0, 202) then  -- BACKSPACE
                isPlacing = false
                DeleteEntity(ghostProp)
                Notify("Placement cancelled", "info")
            end
        end
    end)
end

function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    return vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DELETE MODE
-- ═══════════════════════════════════════════════════════════════════════════

local function EnterDeleteMode()
    if isDeleteMode then return end
    isDeleteMode = true
    
    Notify("DELETE MODE: Target a prop and press E | BACKSPACE to exit", "info")
    
    CreateThread(function()
        while isDeleteMode do
            Wait(0)
            
            -- Raycast to find props
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local forward = RotationToDirection(camRot)
            local endCoords = camCoords + (forward * 20.0)
            
            local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 16, PlayerPedId(), 0)
            local _, hit, hitCoords, _, hitEntity = GetShapeTestResult(ray)
            
            if hit and DoesEntityExist(hitEntity) and IsEntityAnObject(hitEntity) then
                local model = GetEntityModel(hitEntity)
                local entityCoords = GetEntityCoords(hitEntity)
                
                -- Draw marker on targeted prop
                DrawMarker(28, entityCoords.x, entityCoords.y, entityCoords.z + 1.0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 0, 0, 150, false, true, 2, nil, nil, false)
                
                -- Show info
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(255, 255, 255, 255)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(2, 0, 0, 0, 150)
                SetTextDropShadow()
                SetTextOutline()
                SetTextEntry("STRING")
                AddTextComponentString(string.format("Model: %d | Press E to delete", model))
                DrawText(0.5, 0.9)
                
                -- Delete on E press
                if IsControlJustPressed(0, 38) then  -- E
                    -- Check if this is a spawned prop or native
                    local isSpawned = false
                    local spawnedId = nil
                    
                    for dbId, data in pairs(spawnedProps) do
                        if data.entity == hitEntity then
                            isSpawned = true
                            spawnedId = dbId
                            break
                        end
                    end
                    
                    if isSpawned then
                        -- Delete spawned prop
                        if DeleteSettings.confirmDelete then
                            local confirm = lib.alertDialog({
                                header = "Delete Spawned Prop",
                                content = "Delete this spawned prop? (ID: " .. spawnedId .. ")",
                                centered = true,
                                cancel = true,
                            })
                            if confirm == "confirm" then
                                TriggerServerEvent("ogz_propmanager:server:WorldBuilderDeleteSpawned", spawnedId)
                            end
                        else
                            TriggerServerEvent("ogz_propmanager:server:WorldBuilderDeleteSpawned", spawnedId)
                        end
                    else
                        -- Delete native prop (hide it)
                        if DeleteSettings.confirmDelete then
                            local confirm = lib.alertDialog({
                                header = "Hide Native Prop",
                                content = "Hide this native GTA prop permanently?",
                                centered = true,
                                cancel = true,
                            })
                            if confirm == "confirm" then
                                TriggerServerEvent("ogz_propmanager:server:WorldBuilderDeleteNative", {
                                    model = model,
                                    coords = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z },
                                })
                                HideNativeProp({ model = model, coords = entityCoords, radius = 1.0 })
                            end
                        else
                            TriggerServerEvent("ogz_propmanager:server:WorldBuilderDeleteNative", {
                                model = model,
                                coords = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z },
                            })
                            HideNativeProp({ model = model, coords = entityCoords, radius = 1.0 })
                        end
                    end
                end
            end
            
            -- Exit delete mode
            if IsControlJustPressed(0, 202) then  -- BACKSPACE
                isDeleteMode = false
                Notify("Exited delete mode", "info")
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN MENUS
-- ═══════════════════════════════════════════════════════════════════════════

local function OpenSpawnMenu()
    local categories = {}
    
    for category, models in pairs(WorldBuilder.ModelPresets or {}) do
        categories[#categories + 1] = {
            title = category,
            icon = "fas fa-folder",
            onSelect = function()
                local modelOptions = {}
                for _, modelData in ipairs(models) do
                    modelOptions[#modelOptions + 1] = {
                        title = modelData.label,
                        description = modelData.model,
                        icon = "fas fa-cube",
                        onSelect = function()
                            StartWorldPropPlacement(modelData.model, { label = modelData.label })
                        end,
                    }
                end
                
                lib.registerContext({
                    id = "wb_spawn_models",
                    title = category,
                    menu = "wb_spawn_menu",
                    options = modelOptions,
                })
                lib.showContext("wb_spawn_models")
            end,
        }
    end
    
    -- Custom model option
    categories[#categories + 1] = {
        title = "✏️ Custom Model",
        description = "Enter a model name manually",
        icon = "fas fa-keyboard",
        onSelect = function()
            local input = lib.inputDialog("Spawn Custom Model", {
                { type = "input", label = "Model Name", placeholder = "prop_weed_01", required = true },
            })
            if input and input[1] then
                StartWorldPropPlacement(input[1], { label = input[1] })
            end
        end,
    }
    
    lib.registerContext({
        id = "wb_spawn_menu",
        title = "🔧 World Builder - Spawn",
        options = categories,
    })
    lib.showContext("wb_spawn_menu")
end

local function OpenMainMenu()
    lib.registerContext({
        id = "wb_main_menu",
        title = "🔧 World Builder",
        options = {
            {
                title = "📦 Spawn Prop",
                description = "Place a new prop in the world",
                icon = "fas fa-plus",
                onSelect = OpenSpawnMenu,
            },
            {
                title = "🗑️ Delete Mode",
                description = "Target and delete props",
                icon = "fas fa-trash",
                onSelect = EnterDeleteMode,
            },
            {
                title = "📋 List Nearby",
                description = "Show spawned/deleted props nearby",
                icon = "fas fa-list",
                onSelect = function()
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local nearby = {}
                    
                    for dbId, data in pairs(spawnedProps) do
                        if DoesEntityExist(data.entity) then
                            local dist = #(playerCoords - GetEntityCoords(data.entity))
                            if dist < 50.0 then
                                nearby[#nearby + 1] = {
                                    title = string.format("ID: %d | %s", dbId, data.model),
                                    description = string.format("Distance: %.1fm", dist),
                                    icon = "fas fa-cube",
                                }
                            end
                        end
                    end
                    
                    if #nearby == 0 then
                        Notify("No spawned props nearby", "info")
                        return
                    end
                    
                    lib.registerContext({
                        id = "wb_nearby_list",
                        title = "Nearby Spawned Props",
                        menu = "wb_main_menu",
                        options = nearby,
                    })
                    lib.showContext("wb_nearby_list")
                end,
            },
            {
                title = "📦 Spawn Group",
                description = "Spawn an entire prop group",
                icon = "fas fa-layer-group",
                onSelect = function()
                    local groups = {}
                    for groupId, groupData in pairs(WorldBuilder.SpawnGroups or {}) do
                        if groupData.enabled ~= false then
                            groups[#groups + 1] = {
                                title = groupData.name or groupId,
                                description = string.format("%d props", #(groupData.props or {})),
                                icon = "fas fa-object-group",
                                onSelect = function()
                                    TriggerServerEvent("ogz_propmanager:server:WorldBuilderSpawnGroup", groupId)
                                end,
                            }
                        end
                    end
                    
                    if #groups == 0 then
                        Notify("No spawn groups configured", "info")
                        return
                    end
                    
                    lib.registerContext({
                        id = "wb_groups_menu",
                        title = "Spawn Groups",
                        menu = "wb_main_menu",
                        options = groups,
                    })
                    lib.showContext("wb_groups_menu")
                end,
            },
            {
                title = "🔄 Reload Props",
                description = "Reload all props from database",
                icon = "fas fa-sync",
                onSelect = function()
                    TriggerServerEvent("ogz_propmanager:server:WorldBuilderReload")
                    Notify("Reloading props...", "info")
                end,
            },
        },
    })
    lib.showContext("wb_main_menu")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("wb_menu", function()
    CheckAdmin(function(hasAdmin)
        if hasAdmin then OpenMainMenu()
        else Notify("No permission", "error") end
    end)
end, false)

RegisterCommand("wb_spawn", function(source, args)
    CheckAdmin(function(hasAdmin)
        if not hasAdmin then Notify("No permission", "error") return end
        
        if args[1] then
            StartWorldPropPlacement(args[1], { label = args[1] })
        else
            OpenSpawnMenu()
        end
    end)
end, false)

RegisterCommand("wb_delete", function()
    CheckAdmin(function(hasAdmin)
        if hasAdmin then EnterDeleteMode()
        else Notify("No permission", "error") end
    end)
end, false)

RegisterCommand("wb_list", function()
    CheckAdmin(function(hasAdmin)
        if not hasAdmin then Notify("No permission", "error") return end
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        print("═══════════════════════════════════════════════════════════════")
        print("[World Builder] Nearby Spawned Props (50m radius):")
        print("═══════════════════════════════════════════════════════════════")
        
        local count = 0
        for dbId, data in pairs(spawnedProps) do
            if DoesEntityExist(data.entity) then
                local dist = #(playerCoords - GetEntityCoords(data.entity))
                if dist < 50.0 then
                    print(string.format("  ID: %d | Model: %s | Dist: %.1fm", dbId, data.model, dist))
                    count = count + 1
                end
            end
        end
        
        print("═══════════════════════════════════════════════════════════════")
        print("Total:", count)
    end)
end, false)

RegisterCommand("wb_reload", function()
    CheckAdmin(function(hasAdmin)
        if hasAdmin then
            TriggerServerEvent("ogz_propmanager:server:WorldBuilderReload")
            Notify("Reloading props...", "info")
        else
            Notify("No permission", "error")
        end
    end)
end, false)

RegisterCommand("wb_clear", function(source, args)
    CheckAdmin(function(hasAdmin)
        if not hasAdmin then Notify("No permission", "error") return end
        
        local radius = tonumber(args[1]) or 10.0
        local confirm = lib.alertDialog({
            header = "Clear Spawned Props",
            content = string.format("Delete all spawned props within %.1fm?", radius),
            centered = true,
            cancel = true,
        })
        
        if confirm == "confirm" then
            local playerCoords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent("ogz_propmanager:server:WorldBuilderClear", playerCoords, radius)
        end
    end)
end, false)

RegisterCommand("wb_scan", function(source, args)
    local radius = tonumber(args[1]) or 10.0
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    print("═══════════════════════════════════════════════════════════════")
    print("[World Builder] Scanning for props within", radius, "meters")
    print("═══════════════════════════════════════════════════════════════")
    
    local found = 0
    for _, obj in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(obj) then
            local objCoords = GetEntityCoords(obj)
            local dist = #(playerCoords - objCoords)
            
            if dist <= radius then
                local model = GetEntityModel(obj)
                print(string.format("  Model: %d | Coords: vec3(%.2f, %.2f, %.2f) | Heading: %.1f",
                    model, objCoords.x, objCoords.y, objCoords.z, GetEntityHeading(obj)))
                found = found + 1
            end
        end
    end
    
    print("═══════════════════════════════════════════════════════════════")
    print("Found", found, "props")
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- SERVER EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Initial load
RegisterNetEvent("ogz_propmanager:client:WorldBuilderLoad", function(data)
    DebugPrint("Received WorldBuilder load data")
    
    -- Clear existing
    for dbId, propData in pairs(spawnedProps) do
        if DoesEntityExist(propData.entity) then
            DeleteEntity(propData.entity)
        end
    end
    spawnedProps = {}
    
    -- Unhide previously hidden
    for _, data in ipairs(hiddenEntities) do
        UnhideNativeProp(data.entity)
    end
    hiddenEntities = {}
    
    -- Load new data
    if data.spawned then LoadSpawnedProps(data.spawned) end
    if data.deleted then LoadDeletedProps(data.deleted) end
end)

-- Single prop spawned
RegisterNetEvent("ogz_propmanager:client:WorldBuilderSpawnProp", function(propData)
    if type(propData.coords) == "string" then
        propData.coords = json.decode(propData.coords)
    end
    
    local entity = SpawnPropEntity(propData)
    if entity then
        spawnedProps[propData.id] = {
            entity = entity,
            model = propData.model,
            coords = propData.coords,
            heading = propData.heading,
            zone = propData.interaction_zone,
            respawnTime = propData.respawn_time,
        }
        DebugPrint("Spawned new prop:", propData.id)
    end
end)

-- Prop removed
RegisterNetEvent("ogz_propmanager:client:WorldBuilderRemoveProp", function(dbId)
    DespawnPropEntity(dbId)
end)

-- Prop harvested (hide until respawn)
RegisterNetEvent("ogz_propmanager:client:WorldBuilderHarvestProp", function(dbId)
    if spawnedProps[dbId] and DoesEntityExist(spawnedProps[dbId].entity) then
        DeleteEntity(spawnedProps[dbId].entity)
        spawnedProps[dbId].entity = nil
        DebugPrint("Prop harvested (hidden):", dbId)
    end
end)

-- Prop respawned
RegisterNetEvent("ogz_propmanager:client:WorldBuilderRespawnProp", function(propData)
    if type(propData.coords) == "string" then
        propData.coords = json.decode(propData.coords)
    end
    
    local entity = SpawnPropEntity(propData)
    if entity then
        if spawnedProps[propData.id] then
            spawnedProps[propData.id].entity = entity
        else
            spawnedProps[propData.id] = {
                entity = entity,
                model = propData.model,
                coords = propData.coords,
                heading = propData.heading,
                zone = propData.interaction_zone,
            }
        end
        DebugPrint("Prop respawned:", propData.id)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- HIDE PRE-CONFIGURED NATIVE PROPS
-- ═══════════════════════════════════════════════════════════════════════════

local function HideConfiguredProps()
    for _, deleteData in ipairs(WorldBuilder.DeletedProps or {}) do
        if type(deleteData.coords) == "vector3" then
            deleteData.coords = { x = deleteData.coords.x, y = deleteData.coords.y, z = deleteData.coords.z }
        end
        HideNativeProp(deleteData)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

local function Init()
    DebugPrint("═══════════════════════════════════════════")
    DebugPrint("Initializing World Builder")
    DebugPrint("═══════════════════════════════════════════")
    
    -- Check admin status
    CheckAdmin()
    
    -- Hide pre-configured props
    HideConfiguredProps()
    
    -- Request data from server
    TriggerServerEvent("ogz_propmanager:server:WorldBuilderRequest")
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(4000)
    Init()
end)

CreateThread(function()
    Wait(4000)
    if LocalPlayer.state.isLoggedIn then
        Init()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- Delete spawned props
    for _, propData in pairs(spawnedProps) do
        if DoesEntityExist(propData.entity) then
            DeleteEntity(propData.entity)
        end
    end
    
    -- Unhide native props
    for _, data in ipairs(hiddenEntities) do
        UnhideNativeProp(data.entity)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports("GetSpawnedProps", function() return spawnedProps end)
exports("IsWorldBuilderAdmin", function() return isAdmin end)
exports("StartWorldPropPlacement", StartWorldPropPlacement)

print("^2[OGz PropManager v3.5]^0 World Builder CLIENT loaded")
