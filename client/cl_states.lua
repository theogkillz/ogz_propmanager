--[[
    OGz PropManager - Model State Manager
    
    Handles visual state changes for props with multiple model variants
    States: off (default) → on (menu open) → working (crafting) → off
]]

local activeStates = {}  -- Track current state of each prop {propId = {entity, state, stationId}}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     STATE DEFINITIONS                            │
-- └──────────────────────────────────────────────────────────────────┘

local STATES = {
    OFF = "off",
    ON = "on", 
    WORKING = "working"
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                    GET MODEL FOR STATE                           │
-- └──────────────────────────────────────────────────────────────────┘

---Get the model for a specific state
---@param stationConfig table
---@param state string "off", "on", or "working"
---@return string
local function GetModelForState(stationConfig, state)
    -- If modelStates exists, use it
    if stationConfig.modelStates then
        local stateData = stationConfig.modelStates[state] or stationConfig.modelStates.off
        if stateData then
            -- Handle both old format (string) and new format (table with .model)
            return type(stateData) == "table" and stateData.model or stateData
        end
    end
    -- Fallback to single model
    return stationConfig.model
end

---Get the full state data (model, sound, particle)
---@param stationConfig table
---@param state string "off", "on", or "working"
---@return table|nil
local function GetStateData(stationConfig, state)
    if stationConfig.modelStates and stationConfig.modelStates[state] then
        local stateData = stationConfig.modelStates[state]
        -- Handle both old format (string) and new format (table)
        if type(stateData) == "string" then
            return { model = stateData, sound = nil, particle = nil }
        end
        return stateData
    end
    return nil
end

---Check if station has multiple model states
---@param stationConfig table
---@return boolean
local function HasModelStates(stationConfig)
    return stationConfig.modelStates ~= nil
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     SWAP PROP MODEL                              │
-- └──────────────────────────────────────────────────────────────────┘

---Swap a prop's model while preserving position/heading
---@param oldEntity number Current entity handle
---@param newModel string New model name
---@param propData table Prop data with coords/heading
---@return number|nil New entity handle
local function SwapPropModel(oldEntity, newModel, propData)
    if not DoesEntityExist(oldEntity) then
        DebugPrint("SwapPropModel: Old entity doesn't exist")
        return nil
    end
    
    -- Use DATABASE coords/heading to prevent drift (not entity coords!)
    local coords = propData.coords
    local heading = propData.heading or GetEntityHeading(oldEntity)
    
    DebugPrint("SwapPropModel: Using DB coords:", coords.x, coords.y, coords.z, "Heading:", heading)
    
    -- Load new model
    local modelHash = type(newModel) == "string" and joaat(newModel) or newModel
    if not LoadModel(modelHash) then
        DebugPrint("SwapPropModel: Failed to load model:", newModel)
        return nil
    end
    
    -- Store target options (we'll need to re-add them)
    local hadTarget = true
    
    -- Remove target from old entity
    pcall(function()
        exports.ox_target:removeLocalEntity(oldEntity)
    end)
    
    -- Delete old entity
    DeleteEntity(oldEntity)
    
    -- Create new entity at same position
    local newEntity = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
    
    if DoesEntityExist(newEntity) then
        SetEntityHeading(newEntity, heading)
        FreezeEntityPosition(newEntity, true)
        SetEntityCollision(newEntity, true, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        DebugPrint("SwapPropModel: Swapped to", newModel, "entity:", newEntity)
        return newEntity
    end
    
    return nil
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   STATE CHANGE FUNCTIONS                         │
-- └──────────────────────────────────────────────────────────────────┘

---Change a prop's visual state
---@param propId number Database prop ID
---@param entity number Current entity handle
---@param propData table Full prop data
---@param newState string "off", "on", or "working"
---@return number|nil New entity handle (or same if no change needed)
function ChangeModelState(propId, entity, propData, newState)
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return entity end
    
    -- Check if this station has model states
    if not HasModelStates(stationConfig) then
        DebugPrint("Station has no model states:", propData.station_id)
        return entity
    end
    
    -- Get current state
    local currentState = activeStates[propId] and activeStates[propId].state or STATES.OFF
    
    -- Don't change if already in this state
    if currentState == newState then
        DebugPrint("Already in state:", newState)
        return entity
    end
    
    -- Get new model for state
    local newModel = GetModelForState(stationConfig, newState)
    local currentModel = GetModelForState(stationConfig, currentState)
    
    -- If models are the same, just update tracking
    if newModel == currentModel then
        activeStates[propId] = {
            entity = entity,
            state = newState,
            stationId = propData.station_id
        }
        return entity
    end
    
    -- Swap the model
    local newEntity = SwapPropModel(entity, newModel, propData)
    
    if newEntity then
        -- Update tracking
        activeStates[propId] = {
            entity = newEntity,
            state = newState,
            stationId = propData.station_id
        }
        
        -- Re-add target options to new entity
        ReaddTargetToEntity(newEntity, propData)
        
        -- Update the placedProps cache in target.lua
        TriggerEvent("ogz_propmanager:client:UpdatePropEntity", propId, newEntity)
        
        DebugPrint("State changed:", propData.station_id, currentState, "→", newState)
        return newEntity
    end
    
    return entity
end

---Set prop to OFF state (default/idle)
---@param propId number
---@param entity number
---@param propData table
---@return number
function SetStateOff(propId, entity, propData)
    return ChangeModelState(propId, entity, propData, STATES.OFF)
end

---Set prop to ON state (menu open)
---@param propId number
---@param entity number
---@param propData table
---@return number
function SetStateOn(propId, entity, propData)
    return ChangeModelState(propId, entity, propData, STATES.ON)
end

---Set prop to WORKING state (crafting in progress)
---@param propId number
---@param entity number
---@param propData table
---@return number
function SetStateWorking(propId, entity, propData)
    return ChangeModelState(propId, entity, propData, STATES.WORKING)
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   INVENTORY CLOSE DETECTION                      │
-- └──────────────────────────────────────────────────────────────────┘

local monitoringProp = nil  -- Currently monitored prop for state changes

---Start monitoring for when player leaves/closes crafting
---@param propId number
---@param entity number
---@param propData table
function StartStateMonitor(propId, entity, propData)
    if monitoringProp then
        -- Already monitoring something, stop old monitor
        StopStateMonitor()
    end
    
    monitoringProp = {
        propId = propId,
        entity = entity,
        propData = propData,
        startTime = GetGameTimer()
    }
    
    -- Start monitor thread
    CreateThread(function()
        local propCoords = vector3(propData.coords.x, propData.coords.y, propData.coords.z)
        local maxDistance = Config.InteractDistance + 1.0
        local checkInterval = 500  -- ms
        
        while monitoringProp and monitoringProp.propId == propId do
            Wait(checkInterval)
            
            -- Check if player walked away
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - propCoords)
            
            if distance > maxDistance then
                DebugPrint("Player walked away from station")
                StopStateMonitor()
                break
            end
            
            -- Check if inventory is closed (ox_inventory uses state bag)
            local invOpen = LocalPlayer.state.invOpen
            if not invOpen then
                DebugPrint("Inventory closed")
                StopStateMonitor()
                break
            end
        end
    end)
end

---Stop monitoring and return prop to OFF state
function StopStateMonitor()
    if not monitoringProp then return end
    
    local propId = monitoringProp.propId
    local entity = monitoringProp.entity
    local propData = monitoringProp.propData
    
    -- Get current entity (might have changed)
    if activeStates[propId] then
        entity = activeStates[propId].entity
    end
    
    -- Return to OFF state
    SetStateOff(propId, entity, propData)
    
    monitoringProp = nil
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                   CRAFTING PROGRESS HOOK                         │
-- └──────────────────────────────────────────────────────────────────┘

-- Listen for ox_inventory crafting events (if available)
-- Note: This depends on ox_inventory version and may need adjustment

RegisterNetEvent("ox_inventory:craftingStarted", function()
    if monitoringProp then
        DebugPrint("Crafting started - switching to WORKING state")
        local propId = monitoringProp.propId
        local entity = activeStates[propId] and activeStates[propId].entity or monitoringProp.entity
        SetStateWorking(propId, entity, monitoringProp.propData)
    end
end)

RegisterNetEvent("ox_inventory:craftingComplete", function()
    if monitoringProp then
        DebugPrint("Crafting complete - switching to ON state")
        local propId = monitoringProp.propId
        local entity = activeStates[propId] and activeStates[propId].entity or monitoringProp.entity
        SetStateOn(propId, entity, monitoringProp.propData)
    end
end)

-- Alternative: Custom crafting progress wrapper
-- If ox_inventory doesn't emit events, we can wrap the crafting call

---Wrapper to handle crafting with state changes
---@param propId number
---@param entity number
---@param propData table
---@param craftingTable string
function OpenCraftingWithStates(propId, entity, propData, craftingTable)
    local stationConfig = GetStationConfig(propData.station_id)
    
    -- Set to ON state
    local currentEntity = SetStateOn(propId, entity, propData)
    
    -- Start monitoring
    StartStateMonitor(propId, currentEntity, propData)
    
    -- Open crafting bench (ox_inventory method)
    exports.ox_inventory:openInventory('crafting', { id = craftingTable })
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        CLEANUP                                   │
-- └──────────────────────────────────────────────────────────────────┘

---Clear state tracking for a prop
---@param propId number
function ClearPropState(propId)
    activeStates[propId] = nil
end

---Get current state of a prop
---@param propId number
---@return string|nil
function GetPropState(propId)
    return activeStates[propId] and activeStates[propId].state or nil
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        EXPORTS                                   │
-- └──────────────────────────────────────────────────────────────────┘

exports("ChangeModelState", ChangeModelState)
exports("SetStateOff", SetStateOff)
exports("SetStateOn", SetStateOn)
exports("SetStateWorking", SetStateWorking)
exports("OpenCraftingWithStates", OpenCraftingWithStates)
exports("GetPropState", GetPropState)
