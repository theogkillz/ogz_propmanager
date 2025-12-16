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
    
    v3.5.1 FIX: Targeting system now works correctly
    - Changed from async StartShapeTestLosProbe to sync StartShapeTestRay
    - Fixed boolean check (was "hit == 1", now just "hit")
    - Improved visual markers for precise prop identification
    
    ═══════════════════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════════════════

local spawnedProps = {}              -- [dbId] = { entity, model, coords, ... }
local deletedNativeProps = {}        -- [dbId] = { model, coords, radius, hidden = bool }
local hiddenEntities = {}            -- [dbId] = entity handle

local isDeleteMode = false           -- Currently in delete mode?
local hashModeActive = false         -- Currently in hash mode?
local isAdmin = false                -- Cached admin status

-- v3.5.1: Efficient distance-based hide system
local HIDE_DISTANCE = 100.0          -- Only check props within this distance
local HIDE_CHECK_INTERVAL = 1000     -- Check every 1 second
local hideThreadRunning = false
local lastPlayerCell = nil           -- Track player grid cell for optimization

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
    
    -- v3.5.2: Ensure we have valid ground Z
    local spawnZ = coords.z
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)
    if foundGround then
        -- Use ground Z if it's close to the intended Z (within 5 units) - this avoids 
        -- snapping props that are intentionally placed on upper floors/roofs
        if math.abs(groundZ - coords.z) < 5.0 then
            spawnZ = groundZ
            DebugPrint("SpawnPropEntity: Adjusted Z from", coords.z, "to ground at", groundZ)
        end
    end
    
    local entity = CreateObject(modelHash, coords.x, coords.y, spawnZ, false, false, false)
    
    if DoesEntityExist(entity) then
        SetEntityHeading(entity, propData.heading or 0.0)
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, true, true)
        
        -- v3.5.2: Additional ground snap using native (backup)
        PlaceObjectOnGroundProperly(entity)
        
        SetModelAsNoLongerNeeded(modelHash)
        
        DebugPrint("Spawned prop:", propData.id, propData.model, "at", GetEntityCoords(entity))
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
-- NATIVE PROP HIDING (v3.5.1 - Efficient Distance-Based System)
-- ═══════════════════════════════════════════════════════════════════════════

-- Get distance between player and coords
local function GetDistanceToCoords(coords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    if type(coords) == "string" then
        coords = json.decode(coords)
    end
    if not coords or not coords.x then return 99999 end
    return #(playerCoords - vector3(coords.x, coords.y, coords.z))
end

-- Try to hide a single native prop
local function TryHideNativeProp(dbId, deleteData)
    -- Already hidden? Skip
    if hiddenEntities[dbId] and DoesEntityExist(hiddenEntities[dbId]) then
        return true
    end
    
    local modelHash = type(deleteData.model) == "string" and joaat(deleteData.model) or tonumber(deleteData.model)
    local coords = deleteData.coords
    
    if type(coords) == "string" then
        coords = json.decode(coords)
    end
    
    if not coords or not coords.x then
        return false
    end
    
    -- Find the native prop
    local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, modelHash, false, false, false)
    
    if DoesEntityExist(entity) then
        -- Hide it
        SetEntityAsMissionEntity(entity, true, true)
        SetEntityVisible(entity, false, false)
        SetEntityCollision(entity, false, false)
        FreezeEntityPosition(entity, true)
        
        -- Track it
        hiddenEntities[dbId] = entity
        deleteData.hidden = true
        
        DebugPrint("Hidden prop ID:", dbId, "model:", modelHash)
        return true
    end
    
    return false
end

-- Unhide a native prop by database ID
local function UnhideNativeProp(dbId)
    local entity = hiddenEntities[dbId]
    if entity and DoesEntityExist(entity) then
        SetEntityVisible(entity, true, true)
        SetEntityCollision(entity, true, true)
        SetEntityAsMissionEntity(entity, false, true)
        DebugPrint("Unhid prop ID:", dbId)
    end
    hiddenEntities[dbId] = nil
    
    if deletedNativeProps[dbId] then
        deletedNativeProps[dbId].hidden = false
    end
end

-- Check and hide all nearby props (called periodically)
local function HideNearbyProps()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local hiddenCount = 0
    local checkedCount = 0
    
    for dbId, deleteData in pairs(deletedNativeProps) do
        -- Skip if already successfully hidden
        if not deleteData.hidden then
            local coords = deleteData.coords
            if type(coords) == "string" then
                coords = json.decode(coords)
                deleteData.coords = coords  -- Cache parsed coords
            end
            
            if coords and coords.x then
                local dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
                
                -- Only check props within HIDE_DISTANCE
                if dist <= HIDE_DISTANCE then
                    checkedCount = checkedCount + 1
                    if TryHideNativeProp(dbId, deleteData) then
                        hiddenCount = hiddenCount + 1
                    end
                end
            end
        end
    end
    
    return hiddenCount, checkedCount
end

-- Start the distance-based hide thread
local function StartHideThread()
    if hideThreadRunning then return end
    hideThreadRunning = true
    
    DebugPrint("Starting distance-based hide thread (range:", HIDE_DISTANCE, "m)")
    
    CreateThread(function()
        -- Initial hide attempt
        Wait(500)
        local hidden, checked = HideNearbyProps()
        if checked > 0 then
            DebugPrint("Initial hide: checked", checked, "nearby, hidden", hidden)
        end
        
        -- Ongoing monitoring
        while hideThreadRunning do
            Wait(HIDE_CHECK_INTERVAL)
            
            -- Only check if there are unhidden props
            local hasUnhidden = false
            for dbId, deleteData in pairs(deletedNativeProps) do
                if not deleteData.hidden then
                    hasUnhidden = true
                    break
                end
            end
            
            if hasUnhidden then
                local hidden, checked = HideNearbyProps()
                if hidden > 0 then
                    DebugPrint("Hide check: hidden", hidden, "of", checked, "checked")
                end
            end
        end
    end)
end

local function StopHideThread()
    hideThreadRunning = false
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
    DebugPrint("Loading", #deletes, "deleted props")
    
    for _, deleteData in ipairs(deletes) do
        if type(deleteData.coords) == "string" then
            deleteData.coords = json.decode(deleteData.coords)
        end
        
        -- Check if we already have this prop hidden (from before reload)
        local alreadyHidden = hiddenEntities[deleteData.id] ~= nil and DoesEntityExist(hiddenEntities[deleteData.id])
        deleteData.hidden = alreadyHidden
        
        -- Store in tracking table (keyed by ID)
        deletedNativeProps[deleteData.id] = deleteData
        
        if alreadyHidden then
            DebugPrint("Prop", deleteData.id, "already hidden, keeping")
        end
    end
    
    -- Start the hide thread
    StartHideThread()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEMENT INTEGRATION
-- ═══════════════════════════════════════════════════════════════════════════

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
        zone = options.zone,
        respawnTime = options.respawnTime or 0,
        groupId = options.groupId,
    }
    
    -- Use the unified placement system from placement.lua
    if StartWorldBuilderPlacement then
        DebugPrint("  Using placement.lua StartWorldBuilderPlacement")
        StartWorldBuilderPlacement(placementData)
    else
        DebugPrint("  WARNING: Using fallback StartSimplePlacement")
        StartSimplePlacement(placementData)
    end
end

-- Simple placement fallback
function StartSimplePlacement(placementData)
    local modelHash = placementData.modelHash
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local forward = GetEntityForwardVector(playerPed)
    local startPos = playerCoords + (forward * 3.0)
    
    -- v3.5.2: Find ground at start position
    local foundGround, groundZ = GetGroundZFor_3dCoord(startPos.x, startPos.y, startPos.z + 50.0, false)
    if foundGround then
        startPos = vector3(startPos.x, startPos.y, groundZ)
    end
    
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
    local isSnappedToGround = true  -- v3.5.2: Start snapped by default
    
    lib.showTextUI("[ENTER] Place | [BACKSPACE] Cancel | [SCROLL] Rotate | [↑↓] Height | [ALT] Snap", { position = "top-center" })
    
    CreateThread(function()
        while isPlacing do
            Wait(0)
            
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local camForward = RotationToDirection(camRot)
            local endCoords = camCoords + (camForward * 15.0)
            
            local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 1 + 16, playerPed, 0)
            local _, hit, hitCoords, _, _ = GetShapeTestResult(ray)
            
            local targetCoords
            if hit and (hitCoords.x ~= 0.0 or hitCoords.y ~= 0.0) then
                local targetZ = hitCoords.z
                
                -- v3.5.2: When snapped to ground, use proper ground detection
                if isSnappedToGround then
                    local foundGround2, groundZ2 = GetGroundZFor_3dCoord(hitCoords.x, hitCoords.y, hitCoords.z + 50.0, false)
                    if foundGround2 then
                        targetZ = groundZ2
                    end
                end
                
                targetCoords = vector3(hitCoords.x, hitCoords.y, targetZ + currentHeight)
                lastValidCoords = targetCoords
            else
                targetCoords = lastValidCoords
            end
            
            SetEntityCoords(ghostProp, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
            SetEntityHeading(ghostProp, currentHeading)
            
            DrawMarker(1, targetCoords.x, targetCoords.y, targetCoords.z - 0.5, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.2, 0, 255, 0, 100, false, true, 2, nil, nil, false)
            
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            
            if IsDisabledControlPressed(0, 15) then currentHeading = currentHeading + 3.0 end
            if IsDisabledControlPressed(0, 14) then currentHeading = currentHeading - 3.0 end
            if IsDisabledControlPressed(0, 172) then 
                currentHeight = currentHeight + 0.03 
                isSnappedToGround = false  -- Break ground snap when adjusting height
            end
            if IsDisabledControlPressed(0, 173) then 
                currentHeight = currentHeight - 0.03 
                isSnappedToGround = false
            end
            
            if IsControlJustPressed(0, 19) then
                isSnappedToGround = true
                currentHeight = 0.0
                PlaceObjectOnGroundProperly(ghostProp)
                local groundedCoords = GetEntityCoords(ghostProp)
                lastValidCoords = groundedCoords
                Notify("Snapped to ground", "info")
            end
            
            if IsControlJustPressed(0, 215) then
                isPlacing = false
                lib.hideTextUI()
                
                local finalCoords = GetEntityCoords(ghostProp)
                local finalHeading = GetEntityHeading(ghostProp)
                
                if finalCoords.x == 0.0 and finalCoords.y == 0.0 then
                    Notify("Invalid position - try again", "error")
                    DeleteEntity(ghostProp)
                    return
                end
                
                DeleteEntity(ghostProp)
                
                DebugPrint("Placing at:", finalCoords.x, finalCoords.y, finalCoords.z)
                
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
            
            if IsControlJustPressed(0, 202) then
                isPlacing = false
                lib.hideTextUI()
                DeleteEntity(ghostProp)
                Notify("Placement cancelled", "info")
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGETING SYSTEM (FIXED v3.5.1)
-- ═══════════════════════════════════════════════════════════════════════════

-- Highlight colors
local DELETE_COLOR = { r = 255, g = 50, b = 50 }     -- Red for delete
local HASH_COLOR = { r = 50, g = 255, b = 100 }      -- Green for hash

-- Get entity from raycast (FIXED - was using async probe + wrong boolean check)
local function GetTargetedEntity()
    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local forward = RotationToDirection(camRot)
    local endCoords = camCoords + (forward * 50.0)
    
    -- FIX: Use StartShapeTestRay (synchronous) instead of StartShapeTestLosProbe (async)
    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        endCoords.x, endCoords.y, endCoords.z,
        16,          -- Flag 16 = Objects only
        playerPed,
        0
    )
    
    local _, hit, hitCoords, _, entity = GetShapeTestResult(ray)
    
    -- FIX: Check "hit" as boolean, not "hit == 1"
    if hit and DoesEntityExist(entity) and IsEntityAnObject(entity) then
        return entity, hitCoords
    end
    
    return nil, nil
end

-- Draw markers around targeted entity
local function DrawEntityHighlight(entity, color, hitCoords)
    if not DoesEntityExist(entity) then return end
    
    local entityCoords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)
    
    -- Get entity dimensions
    local min, max = GetModelDimensions(model)
    local width = math.max(max.x - min.x, max.y - min.y)
    local markerScale = math.max(0.5, math.min(2.0, width * 0.8))
    
    -- 1. CYLINDER at prop base
    DrawMarker(
        1,
        entityCoords.x, entityCoords.y, entityCoords.z + min.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        markerScale, markerScale, 0.15,
        color.r, color.g, color.b, 150,
        false, true, 2, false, nil, nil, false
    )
    
    -- 2. CHEVRON pointing down above prop
    DrawMarker(
        2,
        entityCoords.x, entityCoords.y, entityCoords.z + max.z + 0.5,
        0.0, 0.0, 0.0,
        180.0, 0.0, 0.0,
        0.35, 0.35, 0.35,
        color.r, color.g, color.b, 220,
        true, true, 2, false, nil, nil, false
    )
    
    -- 3. PULSING RING around prop
    local pulse = (math.sin(GetGameTimer() / 150.0) + 1.0) / 2.0
    local pulseAlpha = math.floor(80 + (pulse * 100))
    
    DrawMarker(
        25,
        entityCoords.x, entityCoords.y, entityCoords.z + min.z + 0.05,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        markerScale + 0.3, markerScale + 0.3, 0.5,
        color.r, color.g, color.b, pulseAlpha,
        false, true, 2, false, nil, nil, false
    )
    
    -- 4. Small sphere at hit point (precision)
    if hitCoords then
        DrawMarker(
            28,
            hitCoords.x, hitCoords.y, hitCoords.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            0.08, 0.08, 0.08,
            255, 255, 255, 200,
            false, true, 2, false, nil, nil, false
        )
    end
    
    return model
end

-- Draw on-screen info
local function DrawTargetInfo(model, dist, isDelete)
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
    if isDelete then
        SetTextColour(255, 100, 100, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("E = Delete | C = Copy Hash | BACKSPACE = Exit")
    else
        SetTextColour(100, 255, 150, 255)
        SetTextCentre(true)
        SetTextEntry("STRING")
        AddTextComponentString("E = Copy Hash | C = Copy Config | BACKSPACE = Exit")
    end
    DrawText(0.5, 0.94)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DELETE MODE (FIXED)
-- ═══════════════════════════════════════════════════════════════════════════

local function ExitDeleteMode()
    isDeleteMode = false
    Notify("Delete mode disabled", "info")
    DebugPrint("Delete mode DISABLED")
end

local function EnterDeleteMode()
    if isDeleteMode then 
        ExitDeleteMode()
        return 
    end
    
    -- Exit hash mode if active
    if hashModeActive then
        hashModeActive = false
    end
    
    isDeleteMode = true
    Notify("🔴 DELETE MODE: E=Delete | C=Copy | BACKSPACE=Exit", "success")
    DebugPrint("Delete mode ENABLED")
    
    CreateThread(function()
        while isDeleteMode do
            Wait(0)
            
            local entity, hitCoords = GetTargetedEntity()
            
            if entity then
                local model = DrawEntityHighlight(entity, DELETE_COLOR, hitCoords)
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
                            header = "🗑️ Delete Spawned Prop",
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
                            header = "🙈 Hide Native Prop",
                            content = string.format("Hide this native GTA prop?\n\nModel: %d", model),
                            centered = true,
                            cancel = true,
                        })
                        if confirm == "confirm" then
                            TriggerServerEvent("ogz_propmanager:server:WorldBuilderDeleteNative", {
                                model = model,
                                coords = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z },
                            })
                            -- Hide locally for immediate feedback
                            local tempId = -999
                            local tempData = { 
                                model = model, 
                                coords = { x = entityCoords.x, y = entityCoords.y, z = entityCoords.z }, 
                                radius = 1.0,
                                hidden = false
                            }
                            deletedNativeProps[tempId] = tempData
                            TryHideNativeProp(tempId, tempData)
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
            else
                -- No target text
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(255, 100, 100, 180)
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString("🔴 DELETE MODE - Aim at a prop")
                DrawText(0.5, 0.92)
            end
            
            -- BACKSPACE = Exit
            if IsControlJustPressed(0, 202) then
                ExitDeleteMode()
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HASH MODE (FIXED)
-- ═══════════════════════════════════════════════════════════════════════════

local function ExitHashMode()
    hashModeActive = false
    Notify("Hash mode disabled", "info")
    DebugPrint("Hash mode DISABLED")
end

local function EnterHashMode()
    if hashModeActive then
        ExitHashMode()
        return
    end
    
    -- Exit delete mode if active
    if isDeleteMode then
        isDeleteMode = false
    end
    
    hashModeActive = true
    Notify("🟢 HASH MODE: E=Copy Hash | C=Copy Config | BACKSPACE=Exit", "success")
    DebugPrint("Hash mode ENABLED")
    
    CreateThread(function()
        while hashModeActive do
            Wait(0)
            
            local entity, hitCoords = GetTargetedEntity()
            
            if entity then
                local model = DrawEntityHighlight(entity, HASH_COLOR, hitCoords)
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
            else
                -- No target text
                SetTextFont(4)
                SetTextScale(0.4, 0.4)
                SetTextColour(100, 255, 150, 180)
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString("🟢 HASH MODE - Aim at a prop")
                DrawText(0.5, 0.92)
            end
            
            -- BACKSPACE = Exit
            if IsControlJustPressed(0, 202) then
                ExitHashMode()
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

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS (for admin.lua to access worldbuilder data)
-- ═══════════════════════════════════════════════════════════════════════════

exports("GetSpawnedProps", function()
    return spawnedProps
end)

exports("GetDeletedNativeProps", function()
    return deletedNativeProps
end)

exports("GetHiddenEntities", function()
    return hiddenEntities
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- SIMPLE WORLD BUILDER MENU (wb_menu command)
-- Note: Full PropAdmin menu is in admin.lua
-- ═══════════════════════════════════════════════════════════════════════════

local function OpenWBMenu()
    lib.registerContext({
        id = "wb_quick_menu",
        title = "🔧 World Builder",
        options = {
            {
                title = "📦 Spawn Prop",
                description = "Place a new prop in the world",
                icon = "fas fa-plus-circle",
                iconColor = "#00ff00",
                onSelect = OpenSpawnMenu,
            },
            {
                title = "🎯 Delete Mode",
                description = "RED laser - Target and delete/hide props",
                icon = "fas fa-crosshairs",
                iconColor = "#ff4444",
                onSelect = function()
                    EnterDeleteMode()
                    Notify("Delete Mode: E=Delete | C=Copy Hash | BACKSPACE=Exit", "info")
                end,
            },
            {
                title = "🔍 Hash Mode",
                description = "GREEN laser - Copy prop hashes",
                icon = "fas fa-hashtag",
                iconColor = "#44ff44",
                onSelect = function()
                    EnterHashMode()
                    Notify("Hash Mode: E=Copy Hash | C=Copy Config | BACKSPACE=Exit", "info")
                end,
            },
            {
                title = "🔄 Reload Props",
                description = "Reload all props from database",
                icon = "fas fa-sync-alt",
                onSelect = function()
                    TriggerServerEvent("ogz_propmanager:server:WorldBuilderReload")
                    Notify("Reloading props...", "info")
                end,
            },
        },
    })
    lib.showContext("wb_quick_menu")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("wb_menu", function()
    CheckAdmin(function(hasAdmin)
        if hasAdmin then OpenWBMenu()
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
        EnterDeleteMode()
    end)
end, false)

RegisterCommand("wb_hash", function()
    EnterHashMode()
end, false)

RegisterCommand("wb_cancel", function()
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
            -- Stop the hide thread first
            StopHideThread()
            
            -- Small delay to let it stop
            CreateThread(function()
                Wait(100)
                TriggerServerEvent("ogz_propmanager:server:WorldBuilderReload")
                Notify("Reloading props from database...", "info")
            end)
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

RegisterNetEvent("ogz_propmanager:client:WorldBuilderLoad", function(data)
    DebugPrint("Received WorldBuilder load data")
    
    -- Clear spawned props (these are OUR placed props, not native)
    for dbId, propData in pairs(spawnedProps) do
        if DoesEntityExist(propData.entity) then
            DeleteEntity(propData.entity)
        end
    end
    spawnedProps = {}
    
    -- Build a lookup of NEW deleted prop IDs we're about to load
    local newDeletedIds = {}
    if data.deleted then
        for _, deleteData in ipairs(data.deleted) do
            newDeletedIds[deleteData.id] = true
        end
    end
    
    -- Only unhide props that are NOT in the new deleted list
    for dbId, entity in pairs(hiddenEntities) do
        if not newDeletedIds[dbId] then
            -- This prop was removed from deleted list, unhide it
            if DoesEntityExist(entity) then
                SetEntityVisible(entity, true, true)
                SetEntityCollision(entity, true, true)
                SetEntityAsMissionEntity(entity, false, true)
            end
            hiddenEntities[dbId] = nil
            DebugPrint("Unhiding removed prop:", dbId)
        else
            DebugPrint("Keeping prop hidden:", dbId)
        end
    end
    
    -- Clear deleted props tracking (will be repopulated)
    deletedNativeProps = {}
    
    -- Load new data
    if data.spawned then LoadSpawnedProps(data.spawned) end
    if data.deleted then LoadDeletedProps(data.deleted) end
    
    DebugPrint("Loaded", #(data.spawned or {}), "spawned,", #(data.deleted or {}), "deleted props")
end)

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

RegisterNetEvent("ogz_propmanager:client:WorldBuilderRemoveProp", function(dbId)
    DespawnPropEntity(dbId)
end)

RegisterNetEvent("ogz_propmanager:client:WorldBuilderHarvestProp", function(dbId)
    if spawnedProps[dbId] and DoesEntityExist(spawnedProps[dbId].entity) then
        DeleteEntity(spawnedProps[dbId].entity)
        spawnedProps[dbId].entity = nil
        DebugPrint("Prop harvested (hidden):", dbId)
    end
end)

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

-- v3.5.1: Server tells us to hide a native prop (synced from other players or on join)
RegisterNetEvent("ogz_propmanager:client:WorldBuilderHideNative", function(deleteData)
    if type(deleteData.coords) == "string" then
        deleteData.coords = json.decode(deleteData.coords)
    end
    
    -- Mark as not yet hidden
    deleteData.hidden = false
    
    -- Add to tracking table
    deletedNativeProps[deleteData.id] = deleteData
    
    -- Try to hide immediately if nearby
    local dist = GetDistanceToCoords(deleteData.coords)
    if dist <= HIDE_DISTANCE then
        TryHideNativeProp(deleteData.id, deleteData)
    end
    
    -- Ensure hide thread is running
    StartHideThread()
    
    DebugPrint("Received native prop hide:", deleteData.id)
end)

-- v3.5.1: Server tells us to unhide a native prop
RegisterNetEvent("ogz_propmanager:client:WorldBuilderUnhideNative", function(dbId)
    -- Unhide the entity
    UnhideNativeProp(dbId)
    
    -- Remove from tracking
    deletedNativeProps[dbId] = nil
    
    DebugPrint("Received native prop unhide:", dbId)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- HIDE PRE-CONFIGURED NATIVE PROPS
-- ═══════════════════════════════════════════════════════════════════════════

local function HideConfiguredProps()
    local configuredProps = (WorldBuilder and WorldBuilder.DeletedProps) or {}
    
    for i, deleteData in ipairs(configuredProps) do
        if type(deleteData.coords) == "vector3" then
            deleteData.coords = { x = deleteData.coords.x, y = deleteData.coords.y, z = deleteData.coords.z }
        end
        
        -- Use a fake negative ID for configured props (to distinguish from DB props)
        local fakeId = -i
        deleteData.id = fakeId
        deleteData.hidden = false
        
        -- Add to tracking
        deletedNativeProps[fakeId] = deleteData
    end
    
    -- Thread will handle hiding them based on distance
    if #configuredProps > 0 then
        DebugPrint("Loaded", #configuredProps, "configured props to hide")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

local hasInitialized = false

local function Init()
    if hasInitialized then return end
    hasInitialized = true
    
    DebugPrint("═══════════════════════════════════════════")
    DebugPrint("Initializing World Builder v3.5.1")
    DebugPrint("═══════════════════════════════════════════")
    
    -- Clear any stale tracking from previous session
    hiddenEntities = {}
    deletedNativeProps = {}
    spawnedProps = {}
    
    CheckAdmin()
    HideConfiguredProps()
    TriggerServerEvent("ogz_propmanager:server:WorldBuilderRequest")
    
    -- Start the hide thread (will check for nearby props periodically)
    StartHideThread()
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(3000)  -- v3.5.1: Increased delay for stability
    Init()
end)

-- v3.5.1: Also handle resource restart when player is already loaded
AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    -- Wait for everything to settle
    Wait(3000)
    
    -- Check if player is already logged in (resource restart scenario)
    if LocalPlayer.state.isLoggedIn then
        DebugPrint("Resource restart detected - player already logged in")
        Init()
    end
end)

CreateThread(function()
    Wait(3000)  -- v3.5.1: Increased delay for stability
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
    
    -- Stop hide thread
    StopHideThread()
    
    -- Delete spawned props (these are OUR props, must be removed)
    for _, propData in pairs(spawnedProps) do
        if DoesEntityExist(propData.entity) then
            DeleteEntity(propData.entity)
        end
    end
    
    -- v3.5.1: DON'T unhide native props on resource stop!
    -- They should stay hidden. On restart, we'll re-acquire entity handles.
    -- This prevents the "flash" of props appearing during restart.
    
    DebugPrint("Resource stopping - native props will stay hidden")
end)

-- Additional exports (keeping for backwards compatibility)
exports("IsWorldBuilderAdmin", function() return isAdmin end)
exports("StartWorldPropPlacement", StartWorldPropPlacement)

print("^2[OGz PropManager v3.5.2]^0 World Builder loaded! (Full admin menu in /propadmin)")
