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
-- SETTINGS (with safe fallbacks)
-- ═══════════════════════════════════════════════════════════════════════════

local Settings = (WorldBuilder and WorldBuilder.Settings) or {}
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
    
    DebugPrint("StartWorldPropPlacement called for:", model)
    
    local modelHash = type(model) == "string" and joaat(model) or model
    
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
    
    -- Use the unified placement system from placement.lua
    if StartWorldBuilderPlacement then
        DebugPrint("  Using placement.lua StartWorldBuilderPlacement")
        StartWorldBuilderPlacement(placementData)
    else
        -- Fallback: Use our own simple placement (shouldn't happen if placement.lua is updated)
        DebugPrint("  WARNING: Using fallback StartSimplePlacement")
        StartSimplePlacement(placementData)
    end
end

-- Simple placement fallback if placement.lua doesn't have our function yet
function StartSimplePlacement(placementData)
    local modelHash = placementData.modelHash
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Create ghost prop in front of player initially
    local forward = GetEntityForwardVector(playerPed)
    local startPos = playerCoords + (forward * 3.0)
    
    local ghostProp = CreateObject(modelHash, startPos.x, startPos.y, startPos.z, false, false, false)
    
    if not DoesEntityExist(ghostProp) then
        Notify("Failed to create preview", "error")
        return
    end
    
    SetEntityAlpha(ghostProp, 150, false)
    SetEntityCollision(ghostProp, false, false)
    FreezeEntityPosition(ghostProp, true)
    PlaceObjectOnGroundProperly(ghostProp)
    
    local isPlacing = true
    local currentHeading = GetEntityHeading(playerPed)
    local currentHeight = 0.0
    local lastValidCoords = GetEntityCoords(ghostProp)
    
    -- Show controls using lib
    lib.showTextUI("[ENTER] Place | [BACKSPACE] Cancel | [SCROLL] Rotate | [↑↓] Height | [ALT] Snap", { position = "top-center" })
    
    CreateThread(function()
        while isPlacing do
            Wait(0)
            
            -- Get player camera info
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local camForward = RotationToDirection(camRot)
            local endCoords = camCoords + (camForward * 15.0)
            
            -- Raycast to find ground/surface
            local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 1 + 16, playerPed, 0)
            local _, hit, hitCoords, _, _ = GetShapeTestResult(ray)
            
            local targetCoords
            if hit and (hitCoords.x ~= 0.0 or hitCoords.y ~= 0.0) then
                targetCoords = vector3(hitCoords.x, hitCoords.y, hitCoords.z + currentHeight)
                lastValidCoords = targetCoords
            else
                targetCoords = lastValidCoords
            end
            
            SetEntityCoords(ghostProp, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
            SetEntityHeading(ghostProp, currentHeading)
            
            -- Draw marker under prop for visibility
            DrawMarker(1, targetCoords.x, targetCoords.y, targetCoords.z - 0.5, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.2, 0, 255, 0, 100, false, true, 2, nil, nil, false)
            
            -- Disable controls to capture them
            DisableControlAction(0, 14, true) -- Scroll down
            DisableControlAction(0, 15, true) -- Scroll up
            DisableControlAction(0, 172, true) -- Arrow up
            DisableControlAction(0, 173, true) -- Arrow down
            
            -- Rotation (scroll)
            if IsDisabledControlPressed(0, 15) then currentHeading = currentHeading + 3.0 end
            if IsDisabledControlPressed(0, 14) then currentHeading = currentHeading - 3.0 end
            
            -- Height adjustment (arrows)
            if IsDisabledControlPressed(0, 172) then currentHeight = currentHeight + 0.03 end
            if IsDisabledControlPressed(0, 173) then currentHeight = currentHeight - 0.03 end
            
            -- Ground snap (ALT - key 19)
            if IsControlJustPressed(0, 19) then
                PlaceObjectOnGroundProperly(ghostProp)
                local groundedCoords = GetEntityCoords(ghostProp)
                currentHeight = 0.0
                lastValidCoords = groundedCoords
                Notify("Snapped to ground", "info")
            end
            
            -- Place (ENTER)
            if IsControlJustPressed(0, 215) then
                isPlacing = false
                lib.hideTextUI()
                
                local finalCoords = GetEntityCoords(ghostProp)
                local finalHeading = GetEntityHeading(ghostProp)
                
                -- Validate coords
                if finalCoords.x == 0.0 and finalCoords.y == 0.0 then
                    Notify("Invalid position - try again", "error")
                    DeleteEntity(ghostProp)
                    return
                end
                
                DeleteEntity(ghostProp)
                
                DebugPrint("Placing at:", finalCoords.x, finalCoords.y, finalCoords.z)
                
                -- Send to server
                TriggerServerEvent("ogz_propmanager:server:WorldBuilderSpawn", {
                    model = placementData.model,
                    coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
                    heading = finalHeading,
                    zone = placementData.zone,
                    respawnTime = placementData.respawnTime or 0,
                    groupId = placementData.groupId,
                })
                
                Notify("Prop placed!", "success")
            end
            
            -- Cancel (BACKSPACE)
            if IsControlJustPressed(0, 202) then
                isPlacing = false
                lib.hideTextUI()
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
-- DELETE MODE (Pure Raycast + Laser System)
-- ═══════════════════════════════════════════════════════════════════════════

-- Highlight colors (R, G, B)
local DELETE_COLOR = { r = 255, g = 0, b = 0 }      -- Red for delete
local HASH_COLOR = { r = 0, g = 255, b = 100 }      -- Green for hash

-- Draw a laser line and markers around entity
local function DrawEntityHighlight(entity, color)
    if not DoesEntityExist(entity) then return end
    
    local camCoords = GetGameplayCamCoord()
    local entityCoords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    
    -- Get entity dimensions
    local min, max = GetModelDimensions(model)
    
    -- Draw laser line from camera to entity
    DrawLine(
        camCoords.x, camCoords.y, camCoords.z,
        entityCoords.x, entityCoords.y, entityCoords.z,
        color.r, color.g, color.b, 200
    )
    
    -- Draw marker at entity base (cylinder)
    local markerZ = entityCoords.z + min.z - 0.1
    DrawMarker(
        1, -- Cylinder
        entityCoords.x, entityCoords.y, markerZ,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 0.2,
        color.r, color.g, color.b, 100,
        false, true, 2, false, nil, nil, false
    )
    
    -- Draw chevron above prop
    DrawMarker(
        2, -- Chevron
        entityCoords.x, entityCoords.y, entityCoords.z + max.z + 0.3,
        0.0, 0.0, 0.0,
        0.0, 180.0, 0.0,
        0.3, 0.3, 0.3,
        color.r, color.g, color.b, 200,
        false, true, 2, false, nil, nil, false
    )
    
    return model
end

-- Draw on-screen info
local function DrawTargetInfo(model, dist, isDeleteMode)
    -- Model hash
    SetTextFont(4)
    SetTextScale(0.45, 0.45)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(string.format("Model: %d", model))
    DrawText(0.5, 0.88)
    
    -- Distance
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    SetTextColour(200, 200, 200, 200)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(string.format("Distance: %.1fm", dist))
    DrawText(0.5, 0.91)
    
    -- Controls
    SetTextFont(4)
    SetTextScale(0.35, 0.35)
    if isDeleteMode then
        SetTextColour(255, 100, 100, 255)
    else
        SetTextColour(100, 255, 150, 255)
    end
    SetTextCentre(true)
    SetTextEntry("STRING")
    if isDeleteMode then
        AddTextComponentString("E = Delete | C = Copy Hash | BACKSPACE = Exit")
    else
        AddTextComponentString("E = Copy Hash | C = Copy Config | BACKSPACE = Exit")
    end
    DrawText(0.5, 0.94)
end

-- Get entity from raycast
local function GetTargetedEntity()
    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local forward = RotationToDirection(camRot)
    local endCoords = camCoords + (forward * 50.0)
    
    local ray = StartShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        endCoords.x, endCoords.y, endCoords.z,
        16, playerPed, 0
    )
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    
    if hit == 1 and DoesEntityExist(entity) and IsEntityAnObject(entity) then
        return entity
    end
    return nil
end

local function ExitDeleteMode()
    isDeleteMode = false
    Notify("Delete mode disabled", "info")
end

local function EnterDeleteMode()
    if isDeleteMode then 
        ExitDeleteMode()
        return 
    end
    
    isDeleteMode = true
    Notify("DELETE MODE: E=Delete | C=Copy | BACKSPACE=Exit", "success")
    
    CreateThread(function()
        while isDeleteMode do
            Wait(0)
            
            local entity = GetTargetedEntity()
            
            if entity then
                local model = DrawEntityHighlight(entity, DELETE_COLOR)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local entityCoords = GetEntityCoords(entity)
                local dist = #(playerCoords - entityCoords)
                
                DrawTargetInfo(model, dist, true)
                
                -- E = Delete
                if IsControlJustPressed(0, 38) then
                    local isSpawned = false
                    local spawnedId = nil
                    
                    for dbId, propData in pairs(spawnedProps) do
                        if propData.entity == entity then
                            isSpawned = true
                            spawnedId = dbId
                            break
                        end
                    end
                    
                    if isSpawned then
                        local confirm = lib.alertDialog({
                            header = "Delete Spawned Prop",
                            content = string.format("Delete this spawned prop?\n\nID: %d\nModel: %d", spawnedId, model),
                            centered = true,
                            cancel = true,
                        })
                        if confirm == "confirm" then
                            TriggerServerEvent("ogz_propmanager:server:WorldBuilderDeleteSpawned", spawnedId)
                            Notify("Prop deleted!", "success")
                        end
                    else
                        local confirm = lib.alertDialog({
                            header = "Hide Native Prop",
                            content = string.format("Hide this native GTA prop?\n\nModel: %d", model),
                            centered = true,
                            cancel = true,
                        })
                        if confirm == "confirm" then
                            TriggerServerEvent("ogz_propmanager:server:WorldBuilderDeleteNative", {
                                model = model,
                                coords = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z },
                            })
                            HideNativeProp({ model = model, coords = entityCoords, radius = 1.0 })
                            Notify("Native prop hidden!", "success")
                        end
                    end
                end
                
                -- C = Copy hash
                if IsControlJustPressed(0, 26) then
                    lib.setClipboard(tostring(model))
                    Notify("Hash copied: " .. model, "success")
                    
                    print("═══════════════════════════════════════════════════════════════")
                    print("[World Builder] Prop Info:")
                    print(string.format("  Model Hash: %d", model))
                    print(string.format("  Coords: vec3(%.4f, %.4f, %.4f)", entityCoords.x, entityCoords.y, entityCoords.z))
                    print(string.format("  Heading: %.2f", GetEntityHeading(entity)))
                    print("═══════════════════════════════════════════════════════════════")
                end
            end
            
            -- BACKSPACE = Exit
            if IsControlJustPressed(0, 202) then
                ExitDeleteMode()
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN MENUS
-- ═══════════════════════════════════════════════════════════════════════════

local function OpenSpawnMenu()
    local categories = {}
    
    for category, models in pairs((WorldBuilder and WorldBuilder.ModelPresets) or {}) do
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
                    for groupId, groupData in pairs((WorldBuilder and WorldBuilder.SpawnGroups) or {}) do
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
        if not hasAdmin then Notify("No permission", "error") return end
        
        -- Toggle delete mode (EnterDeleteMode handles the toggle)
        EnterDeleteMode()
    end)
end, false)

RegisterCommand("wb_cancel", function()
    -- Universal cancel command
    if isDeleteMode then
        isDeleteMode = false
        Notify("Delete mode cancelled", "info")
    elseif hashModeActive then
        hashModeActive = false
        Notify("Hash mode cancelled", "info")
    elseif IsPlacing and IsPlacing() then
        CancelPlacement()
    else
        Notify("Nothing to cancel", "info")
    end
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
-- HASH MODE (Pure Raycast + Laser System)
-- ═══════════════════════════════════════════════════════════════════════════

local hashModeActive = false

local function ExitHashMode()
    hashModeActive = false
    Notify("Hash mode disabled", "info")
end

local function EnterHashMode()
    if hashModeActive then
        ExitHashMode()
        return
    end
    
    hashModeActive = true
    Notify("HASH MODE: E=Copy Hash | C=Copy Config | BACKSPACE=Exit", "success")
    
    CreateThread(function()
        while hashModeActive do
            Wait(0)
            
            local entity = GetTargetedEntity()
            
            if entity then
                local model = DrawEntityHighlight(entity, HASH_COLOR)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local entityCoords = GetEntityCoords(entity)
                local dist = #(playerCoords - entityCoords)
                local heading = GetEntityHeading(entity)
                
                DrawTargetInfo(model, dist, false)
                
                -- E = Copy hash
                if IsControlJustPressed(0, 38) then
                    lib.setClipboard(tostring(model))
                    Notify("Hash copied: " .. model, "success")
                    
                    print("═══════════════════════════════════════════════════════════════")
                    print("[World Builder] Model Hash: " .. model)
                    print("═══════════════════════════════════════════════════════════════")
                end
                
                -- C = Copy full config
                if IsControlJustPressed(0, 26) then
                    local copyText = string.format('{ model = %d, coords = vec3(%.2f, %.2f, %.2f), heading = %.1f },', 
                        model, entityCoords.x, entityCoords.y, entityCoords.z, heading)
                    
                    lib.setClipboard(copyText)
                    Notify("Config copied!", "success")
                    
                    print("═══════════════════════════════════════════════════════════════")
                    print("[World Builder] Config Line:")
                    print("  " .. copyText)
                    print("═══════════════════════════════════════════════════════════════")
                end
            end
            
            -- BACKSPACE = Exit
            if IsControlJustPressed(0, 202) then
                ExitHashMode()
            end
        end
    end)
end

RegisterCommand("wb_hash", function()
    EnterHashMode()
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
    for _, deleteData in ipairs((WorldBuilder and WorldBuilder.DeletedProps) or {}) do
        if type(deleteData.coords) == "vector3" then
            deleteData.coords = { x = deleteData.coords.x, y = deleteData.coords.y, z = deleteData.coords.z }
        end
        HideNativeProp(deleteData)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

local hasInitialized = false

local function Init()
    -- Prevent duplicate initialization
    if hasInitialized then return end
    hasInitialized = true
    
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
    Wait(2000)
    Init()
end)

CreateThread(function()
    Wait(2000)
    if LocalPlayer.state.isLoggedIn then
        Init()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- Stop modes
    isDeleteMode = false
    hashModeActive = false
    
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
