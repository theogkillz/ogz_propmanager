--[[
    OGz PropManager v3.3 - Unified Placement System
    
    Handles ghost preview, raycast and gizmo placement modes
    Works for stations, stashes, AND lootables
    
    v3.2: Unified placement system for stations and stashes
          Fixed ground snap in raycast mode
          Added PlaceObjectOnGroundProperly support
    
    v3.3: Added player-placed lootables with item return
          Full lootable placement support
]]

local isPlacing = false
local ghostProp = nil
local currentPlacementData = nil
local placementMode = nil

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                      PLACEMENT STATE                             │
-- └──────────────────────────────────────────────────────────────────┘

---Check if currently in placement mode
---@return boolean
function IsPlacing()
    return isPlacing
end

---Cancel current placement
function CancelPlacement()
    if ghostProp and DoesEntityExist(ghostProp) then
        DeleteEntity(ghostProp)
        ghostProp = nil
    end
    
    -- Return item to player if we have placement data
    if currentPlacementData then
        if currentPlacementData.placementType == "station" then
            TriggerServerEvent("ogz_propmanager:server:PlacementCancelled", currentPlacementData.item)
        elseif currentPlacementData.placementType == "stash" then
            TriggerServerEvent("ogz_propmanager:server:StashPlacementCancelled", currentPlacementData.item)
        elseif currentPlacementData.placementType == "lootable" and currentPlacementData.playerPlaced then
            -- v3.3: Return lootable item to player if player-placed
            TriggerServerEvent("ogz_propmanager:server:LootablePlacementCancelled", currentPlacementData.item)
        end
    end
    
    isPlacing = false
    currentPlacementData = nil
    HideTextUI()
    Notify(Config.Notifications.Cancelled, "info")
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     GHOST PREVIEW                                │
-- └──────────────────────────────────────────────────────────────────┘

---Create ghost preview prop
---@param model string|number
---@return number|nil
local function CreateGhostProp(model)
    local modelHash = type(model) == "string" and joaat(model) or model
    
    if not LoadModel(modelHash) then
        return nil
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local prop = CreateObject(modelHash, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
    
    if DoesEntityExist(prop) then
        SetEntityAlpha(prop, Config.Placement.GhostAlpha, false)
        SetEntityCollision(prop, false, false)
        FreezeEntityPosition(prop, true)
        SetModelAsNoLongerNeeded(modelHash)
        return prop
    end
    
    return nil
end

---Update ghost prop position (raycast mode)
---@param prop number
---@return vector3, number
local function UpdateGhostPositionRaycast(prop)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerForward = GetEntityForwardVector(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    -- Raycast from player camera direction
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)
    
    local endCoords = camCoords + (direction * Config.Placement.CastDistance)
    
    local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 1 + 16, playerPed, 0)
    local _, hit, hitCoords, surfaceNormal, _ = GetShapeTestResult(rayHandle)
    
    local targetCoords = hitCoords
    if not hit then
        -- If no hit, place in front of player
        targetCoords = playerCoords + (playerForward * 3.0)
    end
    
    SetEntityCoords(prop, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
    
    return targetCoords, heading
end

---Convert rotation to direction vector
---@param rotation vector3
---@return vector3
function RotationToDirection(rotation)
    local adjustedRotation = vector3(
        (math.pi / 180) * rotation.x,
        (math.pi / 180) * rotation.y,
        (math.pi / 180) * rotation.z
    )
    local direction = vector3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                    RAYCAST PLACEMENT                             │
-- └──────────────────────────────────────────────────────────────────┘

---Start raycast placement mode (unified for stations and stashes)
---@param placementData table Contains model, label, item, placementType, etc.
local function StartRaycastPlacement(placementData)
    local model = placementData.model
    
    -- Handle model states for stations
    if placementData.modelStates and placementData.modelStates.off then
        local offState = placementData.modelStates.off
        model = type(offState) == "table" and offState.model or offState
    end
    
    ghostProp = CreateGhostProp(model)
    
    if not ghostProp then
        Notify("Failed to create preview", "error")
        return
    end
    
    isPlacing = true
    currentPlacementData = placementData
    
    local currentHeading = 0.0
    local currentHeight = 0.0
    local isSnappedToGround = false
    local keys = Config.Placement.Keys
    
    -- Show controls with ground snap instruction
    ShowTextUI("[ENTER] Place | [BACKSPACE] Cancel | [SCROLL] Rotate | [↑↓] Height | [ALT] Snap Ground", "fas fa-arrows-alt")
    
    CreateThread(function()
        while isPlacing and DoesEntityExist(ghostProp) do
            local targetCoords, baseHeading = UpdateGhostPositionRaycast(ghostProp)
            
            -- Handle rotation
            if IsControlPressed(0, keys.rotateLeft) then
                currentHeading = currentHeading - 2.0
            end
            if IsControlPressed(0, keys.rotateRight) then
                currentHeading = currentHeading + 2.0
            end
            
            -- Handle height adjustment
            if IsControlPressed(0, keys.heightUp) then
                currentHeight = currentHeight + Config.Placement.MoveSpeed
                isSnappedToGround = false
            end
            if IsControlPressed(0, keys.heightDown) then
                currentHeight = currentHeight - Config.Placement.MoveSpeed
                isSnappedToGround = false
            end
            
            -- Snap to ground (v3.2: Improved ground snap)
            if IsControlJustPressed(0, keys.snapGround) then
                isSnappedToGround = true
                currentHeight = 0.0
                
                -- Use PlaceObjectOnGroundProperly for accurate placement
                local tempCoords = GetEntityCoords(ghostProp)
                SetEntityCoords(ghostProp, tempCoords.x, tempCoords.y, tempCoords.z + 0.5, false, false, false, false)
                PlaceObjectOnGroundProperly(ghostProp)
                
                -- Get the new Z and calculate offset
                local newCoords = GetEntityCoords(ghostProp)
                currentHeight = newCoords.z - targetCoords.z
                
                Notify("Snapped to ground!", "success")
            end
            
            -- Apply transformations
            if not isSnappedToGround then
                SetEntityCoords(ghostProp, targetCoords.x, targetCoords.y, targetCoords.z + currentHeight, false, false, false, false)
            else
                -- When snapped, still update X/Y but keep ground-relative Z
                local currentZ = GetEntityCoords(ghostProp).z
                SetEntityCoords(ghostProp, targetCoords.x, targetCoords.y, targetCoords.z + currentHeight, false, false, false, false)
            end
            SetEntityHeading(ghostProp, currentHeading)
            
            -- Confirm placement
            if IsControlJustPressed(0, keys.place) then
                local finalCoords = GetEntityCoords(ghostProp)
                local finalHeading = GetEntityHeading(ghostProp)
                ConfirmPlacementUnified(placementData, finalCoords, finalHeading)
                break
            end
            
            -- Cancel placement
            if IsControlJustPressed(0, keys.cancel) then
                CancelPlacement()
                break
            end
            
            Wait(0)
        end
    end)
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     GIZMO PLACEMENT                              │
-- └──────────────────────────────────────────────────────────────────┘

---Start gizmo placement mode (unified for stations and stashes)
---@param placementData table Contains model, label, item, placementType, etc.
local function StartGizmoPlacement(placementData)
    local model = placementData.model
    
    -- Handle model states for stations
    if placementData.modelStates and placementData.modelStates.off then
        local offState = placementData.modelStates.off
        model = type(offState) == "table" and offState.model or offState
    end
    
    local modelHash = type(model) == "string" and joaat(model) or model
    
    if not LoadModel(modelHash) then
        Notify("Failed to load model", "error")
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local playerHeading = GetEntityHeading(PlayerPedId())
    local forward = GetEntityForwardVector(PlayerPedId())
    local spawnCoords = playerCoords + (forward * 2.0)
    
    -- Create the object for gizmo
    local tempProp = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(tempProp, playerHeading)
    SetEntityAlpha(tempProp, Config.Placement.GhostAlpha, false)
    SetEntityCollision(tempProp, false, false)
    FreezeEntityPosition(tempProp, true)
    
    -- Snap to ground initially
    PlaceObjectOnGroundProperly(tempProp)
    
    isPlacing = true
    currentPlacementData = placementData
    ghostProp = tempProp
    
    -- Use object_gizmo resource
    DebugPrint("Starting gizmo for entity:", tempProp)
    local result = exports.object_gizmo:useGizmo(tempProp)
    DebugPrint("Gizmo result:", result, type(result))
    
    if result then
        if DoesEntityExist(tempProp) then
            local finalCoords = GetEntityCoords(tempProp)
            local finalHeading = GetEntityHeading(tempProp) or 0.0
            DebugPrint("Gizmo confirmed - Coords:", finalCoords, "Heading:", finalHeading)
            ConfirmPlacementUnified(placementData, finalCoords, finalHeading)
        else
            DebugPrint("Gizmo entity was deleted!")
            CancelPlacement()
        end
    else
        DebugPrint("Gizmo cancelled or failed")
        CancelPlacement()
    end
    
    SetModelAsNoLongerNeeded(modelHash)
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │              UNIFIED CONFIRM PLACEMENT                           │
-- └──────────────────────────────────────────────────────────────────┘

---Confirm and finalize placement (handles both stations and stashes)
---@param placementData table
---@param coords vector3
---@param heading number
function ConfirmPlacementUnified(placementData, coords, heading)
    DebugPrint("ConfirmPlacementUnified - Type:", placementData.placementType, "Heading:", heading)
    
    -- Delete ghost prop
    if ghostProp and DoesEntityExist(ghostProp) then
        DeleteEntity(ghostProp)
        ghostProp = nil
    end
    
    isPlacing = false
    HideTextUI()
    
    -- Play placement animation
    local placeAnim = GetAnimationConfig("Place") or GetAnimationConfig("Placement")
    local success = true
    
    if placeAnim then
        success = PlayAnimationWithProgress(placeAnim, "Setting up " .. placementData.label .. "...")
    end
    
    if success then
        local bucket = Config.UseRoutingBucket and GetCurrentBucket() or 0
        
        if placementData.placementType == "station" then
            -- Station placement
            TriggerServerEvent("ogz_propmanager:server:PlaceStation", {
                stationId = placementData.stationId,
                coords = {x = coords.x, y = coords.y, z = coords.z},
                heading = heading or 0.0,
                bucket = bucket,
            })
        elseif placementData.placementType == "stash" then
            -- Stash placement
            TriggerServerEvent("ogz_propmanager:server:PlaceStash", {
                stashType = placementData.stashType,
                coords = {x = coords.x, y = coords.y, z = coords.z},
                heading = heading or 0.0,
                bucket = bucket,
            })
        elseif placementData.placementType == "lootable" then
            -- Lootable placement (player or admin)
            if placementData.playerPlaced then
                -- v3.3: Player placing from item
                TriggerServerEvent("ogz_propmanager:server:PlaceLootable", {
                    lootType = placementData.lootType,
                    model = placementData.model,
                    coords = {x = coords.x, y = coords.y, z = coords.z},
                    heading = heading or 0.0,
                    bucket = bucket,
                })
            else
                -- Admin spawning (simple, no options)
                TriggerServerEvent("ogz_propmanager:server:SpawnLootable", {
                    lootType = placementData.lootType,
                    model = placementData.model,
                    coords = {x = coords.x, y = coords.y, z = coords.z},
                    heading = heading or 0.0,
                    bucket = bucket,
                })
            end
        end
    else
        Notify(Config.Notifications.PlaceFail, "error")
        -- Return item (only for stations/stashes/player-lootables that have items)
        if placementData.placementType == "station" then
            TriggerServerEvent("ogz_propmanager:server:PlacementCancelled", placementData.item)
        elseif placementData.placementType == "stash" then
            TriggerServerEvent("ogz_propmanager:server:StashPlacementCancelled", placementData.item)
        elseif placementData.placementType == "lootable" and placementData.playerPlaced then
            TriggerServerEvent("ogz_propmanager:server:LootablePlacementCancelled", placementData.item)
        end
    end
    
    currentPlacementData = nil
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │              LEGACY: STATION CONFIRM (for compatibility)         │
-- └──────────────────────────────────────────────────────────────────┘

---Legacy confirm function for stations (maintains backward compatibility)
function ConfirmPlacement(stationId, stationConfig, coords, heading)
    local placementData = {
        placementType = "station",
        stationId = stationId,
        label = stationConfig.label,
        item = stationConfig.item,
        model = stationConfig.model,
    }
    ConfirmPlacementUnified(placementData, coords, heading)
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   MODE SELECTION                                 │
-- └──────────────────────────────────────────────────────────────────┘

---Show placement mode selection dialog
---@param itemName string Item name for cancellation
---@param placementType string "station" or "stash"
---@return string|nil Selected mode or nil if cancelled
local function SelectPlacementMode(itemName, placementType)
    if Config.Placement.Mode ~= "both" then
        return Config.Placement.Mode
    end
    
    local choice = lib.inputDialog("Placement Mode", {
        {
            type = "select",
            label = "Select Placement Mode",
            options = {
                { value = "gizmo", label = "🎯 Gizmo (Drag & Drop)" },
                { value = "raycast", label = "📍 Raycast (Point & Place)" },
            },
            default = Config.Placement.DefaultMode,
            required = true,
        }
    })
    
    if not choice then
        -- Cancelled - return item
        if placementType == "station" then
            TriggerServerEvent("ogz_propmanager:server:PlacementCancelled", itemName)
        elseif placementType == "stash" then
            TriggerServerEvent("ogz_propmanager:server:StashPlacementCancelled", itemName)
        end
        return nil
    end
    
    return choice[1]
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   START PLACEMENT (STATIONS)                     │
-- └──────────────────────────────────────────────────────────────────┘

---Start placement process for a station
---@param stationId string
function StartPlacement(stationId)
    if isPlacing then
        Notify("Already placing something!", "error")
        return
    end
    
    local stationConfig = GetStationConfig(stationId)
    if not stationConfig then
        DebugPrint("Station not found:", stationId)
        return
    end
    
    -- Select placement mode
    local selectedMode = SelectPlacementMode(stationConfig.item, "station")
    if not selectedMode then return end
    
    -- Build placement data
    local placementData = {
        placementType = "station",
        stationId = stationId,
        label = stationConfig.label,
        item = stationConfig.item,
        model = stationConfig.model,
        modelStates = stationConfig.modelStates,
    }
    
    -- Start appropriate placement mode
    if selectedMode == "gizmo" then
        StartGizmoPlacement(placementData)
    else
        StartRaycastPlacement(placementData)
    end
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   START PLACEMENT (STASHES)                      │
-- └──────────────────────────────────────────────────────────────────┘

---Start placement process for a stash
---@param stashType string
function StartStashPlacement(stashType)
    if isPlacing then
        Notify("Already placing something!", "error")
        return
    end
    
    local stashConfig = Stashes and Stashes[stashType]
    if not stashConfig then
        DebugPrint("Stash not found:", stashType)
        return
    end
    
    -- Select placement mode
    local selectedMode = SelectPlacementMode(stashConfig.item, "stash")
    if not selectedMode then return end
    
    -- Build placement data
    local placementData = {
        placementType = "stash",
        stashType = stashType,
        label = stashConfig.label,
        item = stashConfig.item,
        model = stashConfig.model,
    }
    
    -- Start appropriate placement mode
    if selectedMode == "gizmo" then
        StartGizmoPlacement(placementData)
    else
        StartRaycastPlacement(placementData)
    end
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   START PLACEMENT (LOOTABLES)                    │
-- └──────────────────────────────────────────────────────────────────┘

---Start placement process for a lootable (admin or player)
---@param lootType string
---@param modelOverride string|nil Optional specific model to use
---@param playerPlaced boolean|nil True if player is placing from item (returns item on cancel)
function StartLootablePlacement(lootType, modelOverride, playerPlaced)
    if isPlacing then
        Notify("Already placing something!", "error")
        return
    end
    
    local lootConfig = Lootables and Lootables[lootType]
    if not lootConfig then
        DebugPrint("Lootable not found:", lootType)
        return
    end
    
    -- Select placement mode
    local itemToReturn = playerPlaced and lootConfig.item or nil
    local selectedMode = SelectPlacementMode(itemToReturn, "lootable")
    if not selectedMode then return end
    
    -- Use provided model or first from config
    local model = modelOverride or (lootConfig.models and lootConfig.models[1]) or lootConfig.model
    
    -- Build placement data
    local placementData = {
        placementType = "lootable",
        lootType = lootType,
        label = lootConfig.label or lootType,
        item = lootConfig.item,
        model = model,
        playerPlaced = playerPlaced or false,
    }
    
    -- Start appropriate placement mode
    if selectedMode == "gizmo" then
        StartGizmoPlacement(placementData)
    else
        StartRaycastPlacement(placementData)
    end
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   PREDEFINED MARKERS                             │
-- └──────────────────────────────────────────────────────────────────┘

---Draw predefined spot markers for a station
---@param stationConfig table
local function DrawPredefinedMarkers(stationConfig)
    if not Config.Placement.ShowPredefinedMarkers then return end
    if not stationConfig.predefinedSpots then return end
    
    local color = Config.Placement.MarkerColor
    local size = Config.Placement.MarkerSize
    
    for _, spot in ipairs(stationConfig.predefinedSpots) do
        DrawMarker(
            Config.Placement.MarkerType,
            spot.x, spot.y, spot.z - 0.95,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            size.x, size.y, size.z,
            color.r, color.g, color.b, color.a,
            Config.Placement.MarkerBobUpDown,
            false,
            2,
            Config.Placement.MarkerRotate,
            nil, nil,
            false
        )
    end
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        EXPORTS                                   │
-- └──────────────────────────────────────────────────────────────────┘

exports("StartPlacement", StartPlacement)
exports("StartStashPlacement", StartStashPlacement)
exports("StartLootablePlacement", StartLootablePlacement)
exports("CancelPlacement", CancelPlacement)
exports("IsPlacing", IsPlacing)
