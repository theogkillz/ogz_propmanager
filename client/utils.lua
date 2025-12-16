--[[
    OGz PropManager - Client Utilities
    
    Helper functions for client-side operations
]]

local QBX = exports.qbx_core

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                      DEBUG FUNCTIONS                             │
-- └──────────────────────────────────────────────────────────────────┘

function DebugPrint(...)
    if Config.Debug then
        print("[OGz PropManager]", ...)
    end
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                    ITEM LABEL HELPERS                            │
-- └──────────────────────────────────────────────────────────────────┘

-- Cache for item labels to avoid repeated lookups
local itemLabelCache = {}

---Get the display label for an item (player-friendly name)
---@param itemName string The item's internal name
---@return string The item's label or formatted name
function GetItemLabel(itemName)
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
    
    -- Fallback: Format the item name nicely (ogz_repair_kit -> Ogz Repair Kit)
    local formatted = itemName:gsub("_", " "):gsub("(%a)([%w]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    itemLabelCache[itemName] = formatted
    return formatted
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                    PLAYER DATA HELPERS                           │
-- └──────────────────────────────────────────────────────────────────┘

---Get player data from QBX
---@return table|nil
function GetPlayerData()
    return QBX:GetPlayerData()
end

---Get player's citizenid
---@return string|nil
function GetCitizenId()
    local player = GetPlayerData()
    return player and player.citizenid or nil
end

---Get player's current job
---@return table|nil
function GetPlayerJob()
    local player = GetPlayerData()
    return player and player.job or nil
end

---Get player's current gang
---@return table|nil
function GetPlayerGang()
    local player = GetPlayerData()
    return player and player.gang or nil
end

---Check if player has a specific job
---@param jobs table|string
---@return boolean
function HasJob(jobs)
    local playerJob = GetPlayerJob()
    if not playerJob then return false end
    
    if type(jobs) == "string" then
        return playerJob.name == jobs
    end
    
    for _, job in ipairs(jobs) do
        if playerJob.name == job then
            return true
        end
    end
    return false
end

---Check if player has a specific gang
---@param gangs table|string
---@return boolean
function HasGang(gangs)
    local playerGang = GetPlayerGang()
    if not playerGang then return false end
    
    if type(gangs) == "string" then
        return playerGang.name == gangs
    end
    
    for _, gang in ipairs(gangs) do
        if playerGang.name == gang then
            return true
        end
    end
    return false
end

---Check if player is police (for seizure)
---@return boolean
function IsPolice()
    if not Config.PoliceOverride.Enabled then return false end
    return HasJob(Config.PoliceOverride.Jobs)
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                    VISIBILITY CHECKS                             │
-- └──────────────────────────────────────────────────────────────────┘

---Check if player can see a station's target option
---@param stationConfig table
---@return boolean
function CanSeeStation(stationConfig)
    if not stationConfig.visibleTo then return true end
    
    local canSee = false
    
    -- Check jobs
    if stationConfig.visibleTo.jobs then
        if HasJob(stationConfig.visibleTo.jobs) then
            canSee = true
        end
    else
        canSee = true  -- No job restriction
    end
    
    -- Check gangs (if jobs didn't pass, check gangs)
    if not canSee and stationConfig.visibleTo.gangs then
        if HasGang(stationConfig.visibleTo.gangs) then
            canSee = true
        end
    elseif not stationConfig.visibleTo.gangs then
        -- No gang restriction, keep current canSee value
    end
    
    -- If both are nil, everyone can see
    if not stationConfig.visibleTo.jobs and not stationConfig.visibleTo.gangs then
        return true
    end
    
    return canSee
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     NOTIFICATION HELPERS                         │
-- └──────────────────────────────────────────────────────────────────┘

---Send notification to player
---@param message string
---@param type string "success" | "error" | "info" | "warning"
function Notify(message, type)
    type = type or "info"
    
    if Config.UI.Notify == "ox" then
        lib.notify({
            title = "Prop Manager",
            description = message,
            type = type,
            position = "top-right",
            duration = 5000,
        })
    elseif Config.UI.Notify == "qb" then
        TriggerEvent('QBCore:Notify', message, type)
    elseif Config.UI.Notify == "okok" then
        TriggerEvent('okokNotify:Alert', "Prop Manager", message, 5000, type)
    end
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                      TEXT UI HELPERS                             │
-- └──────────────────────────────────────────────────────────────────┘

---Show text UI
---@param text string
---@param icon string|nil
function ShowTextUI(text, icon)
    if Config.UI.TextUI == "ox" then
        lib.showTextUI(text, {
            icon = icon or "fas fa-hand-pointer",
            position = "right-center",
        })
    elseif Config.UI.TextUI == "qb" then
        exports['qb-core']:DrawText(text, 'right')
    end
end

---Hide text UI
function HideTextUI()
    if Config.UI.TextUI == "ox" then
        lib.hideTextUI()
    elseif Config.UI.TextUI == "qb" then
        exports['qb-core']:HideText()
    end
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     MODEL HELPERS                                │
-- └──────────────────────────────────────────────────────────────────┘

---Request and load a model
---@param model string|number
---@return boolean
function LoadModel(model)
    if type(model) == "string" then
        model = joaat(model)
    end
    
    if not IsModelValid(model) then
        DebugPrint("Invalid model:", model)
        return false
    end
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            DebugPrint("Model load timeout:", model)
            return false
        end
    end
    return true
end

---Request animation dictionary
---@param dict string
---@return boolean
function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        timeout = timeout + 10
        if timeout > 5000 then
            DebugPrint("Anim dict load timeout:", dict)
            return false
        end
    end
    return true
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     ANIMATION HELPERS                            │
-- └──────────────────────────────────────────────────────────────────┘

---Play animation with progress bar
---@param animConfig table Animation config from animations.lua
---@param label string|nil Override progress label
---@return boolean Success
function PlayAnimationWithProgress(animConfig, label)
    if not animConfig then return false end
    
    local success = false
    local propObj = nil
    local ped = PlayerPedId()
    
    -- Load animation
    if not LoadAnimDict(animConfig.Dict) then
        return false
    end
    
    -- Create hand prop if needed
    if animConfig.Prop then
        if LoadModel(animConfig.Prop) then
            local propHash = type(animConfig.Prop) == "string" and joaat(animConfig.Prop) or animConfig.Prop
            propObj = CreateObject(propHash, 0.0, 0.0, 0.0, true, true, false)
            local bone = animConfig.Bone or 28422
            local coord = animConfig.Coord or vec3(0.0, 0.0, 0.0)
            local rot = animConfig.Rot or vec3(0.0, 0.0, 0.0)
            AttachEntityToEntity(propObj, ped, GetPedBoneIndex(ped, bone), coord.x, coord.y, coord.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(propHash)
        end
    end
    
    -- Disable movement if configured
    if animConfig.Move then
        FreezeEntityPosition(ped, true)
    end
    
    -- Play animation
    TaskPlayAnim(ped, animConfig.Dict, animConfig.Clip, 8.0, -8.0, -1, animConfig.Flag or 49, 0, false, false, false)
    
    -- Progress bar
    if Config.UI.UseProgress then
        success = lib.progressBar({
            duration = animConfig.Time or 5000,
            label = label or animConfig.Prog or "Working...",
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = animConfig.Move or false,
                combat = true,
            },
        })
    else
        Wait(animConfig.Time or 5000)
        success = true
    end
    
    -- Cleanup
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    RemoveAnimDict(animConfig.Dict)
    
    if propObj and DoesEntityExist(propObj) then
        DeleteEntity(propObj)
    end
    
    return success
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     ENTITY HELPERS                               │
-- └──────────────────────────────────────────────────────────────────┘

---Get entity's network ID
---@param entity number
---@return number
function GetEntityNetId(entity)
    if NetworkGetEntityIsNetworked(entity) then
        return NetworkGetNetworkIdFromEntity(entity)
    end
    return 0
end

---Get current routing bucket (cached, updated via events)
---@return number
local currentBucket = 0

function GetCurrentBucket()
    return currentBucket
end

function SetCurrentBucket(bucket)
    currentBucket = bucket or 0
end

-- Update bucket when it changes (server sends this)
RegisterNetEvent("ogz_propmanager:client:SetBucket", function(bucket)
    currentBucket = bucket or 0
    DebugPrint("Bucket updated to:", currentBucket)
end)

-- Request bucket from server on resource start
CreateThread(function()
    Wait(1000)
    lib.callback("ogz_propmanager:server:GetPlayerBucket", false, function(bucket)
        currentBucket = bucket or 0
        DebugPrint("Initial bucket:", currentBucket)
    end)
end)

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     STATION HELPERS                              │
-- └──────────────────────────────────────────────────────────────────┘

---Get station config by ID
---@param stationId string
---@return table|nil
function GetStationConfig(stationId)
    return Stations[stationId]
end

---Get animation config by type
---@param animType string
---@return table|nil
function GetAnimationConfig(animType)
    return Animations[animType]
end

---Find station ID by model hash
---@param modelHash number
---@return string|nil
function GetStationByModel(modelHash)
    for stationId, stationData in pairs(Stations) do
        local stationHash = type(stationData.model) == "string" and joaat(stationData.model) or stationData.model
        if stationHash == modelHash then
            return stationId
        end
    end
    return nil
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     MATH HELPERS                                 │
-- └──────────────────────────────────────────────────────────────────┘

---Convert rotation angles to direction vector
---@param rotation vector3
---@return vector3
function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = vec3(
        -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        math.sin(adjustedRotation.x)
    )
    return direction
end

---Raycast from camera
---@param distance number
---@param flags number
---@return boolean, vector3, vector3, number
function RaycastFromCamera(distance, flags)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local forward = RotationToDirection(camRot)
    local endCoords = camCoords + forward * distance
    
    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, flags or 17, PlayerPedId(), 0)
    local _, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    
    return hit == 1, hitCoords, surfaceNormal, entityHit
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     DURABILITY HELPERS                           │
-- └──────────────────────────────────────────────────────────────────┘

---Get durability color based on percentage
---@param durability number
---@return string
function GetDurabilityColor(durability)
    if durability >= 75 then
        return Config.Durability.Colors.good
    elseif durability >= 25 then
        return Config.Durability.Colors.warning
    else
        return Config.Durability.Colors.critical
    end
end
