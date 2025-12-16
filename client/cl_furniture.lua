--[[
    OGz PropManager v3.4 - Client Furniture Movement
    
    ═══════════════════════════════════════════════════════════════════════════
    HYBRID SIT SYSTEM - SWING LEGS BED EXIT
    ═══════════════════════════════════════════════════════════════════════════
]]

if not Config.Features.Furniture then return end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATE TRACKING
-- ═══════════════════════════════════════════════════════════════════════════

local movedFurniture = {}
local isMovingFurniture = false
local isDragging = false
local dragData = nil
local isSeated = false
local seatedData = nil
local isGettingUp = false

-- ═══════════════════════════════════════════════════════════════════════════
-- SIT DEFINITIONS
-- ═══════════════════════════════════════════════════════════════════════════

local SitScenarios = {
    chair = {
        label = "Chair",
        seatHeight = 0.5,
        useScenario = true,
        scenarios = {
            { label = "Sit", scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" },
            { label = "Sit Relaxed", scenario = "PROP_HUMAN_SEAT_CHAIR" },
        },
    },
    stool = {
        label = "Bar Stool",
        seatHeight = 0.75,
        useScenario = true,
        scenarios = {
            { label = "Sit", scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" },
            { label = "Sit at Bar", scenario = "PROP_HUMAN_SEAT_BAR" },
        },
    },
    bench = {
        label = "Bench",
        seatHeight = 0.5,
        useScenario = true,
        scenarios = {
            { label = "Sit", scenario = "PROP_HUMAN_SEAT_BENCH" },
            { label = "Sit Relaxed", scenario = "PROP_HUMAN_SEAT_CHAIR" },
        },
    },
    couch = {
        label = "Couch",
        seatHeight = 0.4,
        useScenario = true,
        scenarios = {
            { label = "Sit", scenario = "PROP_HUMAN_SEAT_ARMCHAIR" },
            { label = "Sit Relaxed", scenario = "PROP_HUMAN_SEAT_CHAIR" },
        },
    },
    bed = {
        label = "Bed",
        useScenario = false,
        animations = {
            {
                label = "Lay on Back",
                dict = "anim@gangops@morgue@table@",
                anim = "body_search",
                offset = vec3(0.0, 0.0, 0.9),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Lay on Side",
                dict = "switch@trevor@annoys_sunbathers",
                anim = "trev_annoys_sunbathers_loop_guy",
                offset = vec3(0.0, 0.0, 0.9),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sleep",
                dict = "misslamar1dead_body",
                anim = "dead_idle",
                offset = vec3(0.0, 0.0, 0.9),
                heading = 180.0,
                flags = 1,
            },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetFurnitureCategory(model)
    local modelHash = type(model) == "string" and joaat(model) or model
    for catId, category in pairs(Furniture.Categories) do
        for _, m in ipairs(category.models) do
            local catHash = type(m) == "string" and joaat(m) or m
            if catHash == modelHash then
                return catId, category
            end
        end
    end
    return nil, nil
end

local function GetModelName(entity)
    local model = GetEntityModel(entity)
    for _, category in pairs(Furniture.Categories) do
        for _, m in ipairs(category.models) do
            if joaat(m) == model then
                return m
            end
        end
    end
    return nil
end

local function GetMovementSettings(category)
    return {
        pullDistance = category.movement and category.movement.pullDistance or Furniture.Defaults.pullDistance,
        maxPullDistance = category.movement and category.movement.maxPullDistance or Furniture.Defaults.maxPullDistance,
        pushDistance = category.movement and category.movement.pushDistance or Furniture.Defaults.pushDistance,
        canRotate = category.movement and category.movement.canRotate ~= nil and category.movement.canRotate or Furniture.Defaults.canRotate,
        rotateStep = category.movement and category.movement.rotateStep or Furniture.Defaults.rotateStep,
        canDrag = category.canDrag ~= nil and category.canDrag or Furniture.Defaults.canDrag,
        maxDragRadius = Furniture.Dragging and Furniture.Dragging.maxRadius or 5.0,
    }
end

local function FindTrackingByEntity(entity)
    for hash, data in pairs(movedFurniture) do
        if data.entity == entity then
            return hash, data
        end
    end
    return nil, nil
end

local function CreatePermanentHash(model, origCoords)
    return string.format("%d_%.2f_%.2f_%.2f", model, origCoords.x, origCoords.y, origCoords.z)
end

local function GetOrCreateState(entity)
    local existingHash, existingData = FindTrackingByEntity(entity)
    if existingHash then
        return existingHash, existingData
    end
    
    local model = GetEntityModel(entity)
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local hash = CreatePermanentHash(model, coords)
    
    return hash, {
        entity = entity,
        originalCoords = coords,
        originalHeading = heading,
        currentPullDistance = 0,
        maxPullDistance = 0,
    }
end

local function GetPullState(entity)
    local _, data = FindTrackingByEntity(entity)
    return data
end

local function CanPullMore(entity)
    local _, category = GetFurnitureCategory(GetEntityModel(entity))
    if not category then return false end
    local settings = GetMovementSettings(category)
    if settings.maxPullDistance <= 0 then return false end
    local state = GetPullState(entity)
    return not state or state.currentPullDistance < state.maxPullDistance
end

local function CanPushBack(entity)
    local state = GetPullState(entity)
    return state and state.currentPullDistance > 0
end

local function CanReset(entity)
    local state = GetPullState(entity)
    return state and state.currentPullDistance > 0.1
end

local function CanDrag(entity)
    if isDragging or isMovingFurniture or isSeated then return false end
    local _, category = GetFurnitureCategory(GetEntityModel(entity))
    if not category then return false end
    local settings = GetMovementSettings(category)
    return settings.canDrag and Furniture.Dragging and Furniture.Dragging.enabled
end

local function CanSit(entity)
    if isDragging or isMovingFurniture or isSeated then return false end
    local _, category = GetFurnitureCategory(GetEntityModel(entity))
    return category and category.sitType ~= nil
end

local function GetDirection2D(from, to)
    local dx = to.x - from.x
    local dy = to.y - from.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return vec3(0, 0, 0) end
    return vec3(dx / len, dy / len, 0.0)
end

local function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 1000 do
        Wait(10)
        timeout = timeout + 10
    end
    return HasAnimDictLoaded(dict)
end

local function ShowTextUI(text, icon)
    if lib and lib.showTextUI then lib.showTextUI(text, { icon = icon }) end
end

local function HideTextUI()
    if lib and lib.hideTextUI then lib.hideTextUI() end
end

local function Notify(msg, type)
    if lib and lib.notify then lib.notify({ description = msg, type = type }) end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGET REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

function RegisterFurnitureTargets()
    local allModels = {}
    for _, category in pairs(Furniture.Categories) do
        for _, modelName in ipairs(category.models) do
            allModels[#allModels + 1] = modelName
        end
    end
    
    if #allModels == 0 then return end
    
    local options = {
        {
            name = "ogz_furniture_sit",
            icon = "fas fa-chair",
            iconColor = "#00ff00",
            label = "Sit Down",
            distance = 2.0,
            canInteract = function(entity) return CanSit(entity) end,
            onSelect = function(data) OpenSitMenu(data.entity) end,
        },
        {
            name = "ogz_furniture_pull",
            icon = Furniture.Icons.pull,
            iconColor = "#00aaff",
            label = Furniture.Labels.pull,
            distance = 2.0,
            canInteract = function(entity)
                return not isMovingFurniture and not isSeated and not isDragging and CanPullMore(entity)
            end,
            onSelect = function(data) PullFurniture(data.entity) end,
        },
        {
            name = "ogz_furniture_push",
            icon = Furniture.Icons.push,
            iconColor = "#ff6600",
            label = Furniture.Labels.push,
            distance = 2.0,
            canInteract = function(entity)
                return not isMovingFurniture and not isSeated and not isDragging and CanPushBack(entity)
            end,
            onSelect = function(data) PushFurniture(data.entity) end,
        },
        {
            name = "ogz_furniture_reset",
            icon = "fas fa-undo",
            iconColor = "#ff3333",
            label = "Reset Position",
            distance = 2.0,
            canInteract = function(entity)
                return not isMovingFurniture and not isSeated and not isDragging and CanReset(entity)
            end,
            onSelect = function(data) ResetFurniture(data.entity) end,
        },
    }
    
    if Furniture.Dragging and Furniture.Dragging.enabled then
        options[#options + 1] = {
            name = "ogz_furniture_drag",
            icon = "fas fa-hand-holding",
            iconColor = "#00ff88",
            label = "Pick Up & Move",
            distance = 2.0,
            canInteract = function(entity) return CanDrag(entity) end,
            onSelect = function(data) StartDragging(data.entity) end,
        }
    end
    
    exports.ox_target:addModel(allModels, options)
    print("^2[OGz PropManager]^0 Furniture targets registered for", #allModels, "models")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HYBRID SIT SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

function OpenSitMenu(entity)
    if isSeated then return end
    
    local _, category = GetFurnitureCategory(GetEntityModel(entity))
    if not category or not category.sitType then return end
    
    local sitType = category.sitType
    local sitData = SitScenarios[sitType] or SitScenarios.chair
    
    local menuOptions = {}
    
    if sitData.useScenario then
        for _, scenarioInfo in ipairs(sitData.scenarios) do
            menuOptions[#menuOptions + 1] = {
                title = scenarioInfo.label,
                icon = "fas fa-chair",
                onSelect = function()
                    SitWithScenario(entity, scenarioInfo.scenario, sitType, sitData.seatHeight or 0.5)
                end,
            }
        end
    else
        for _, animInfo in ipairs(sitData.animations) do
            menuOptions[#menuOptions + 1] = {
                title = animInfo.label,
                icon = "fas fa-bed",
                onSelect = function()
                    SitWithAnimation(entity, animInfo, sitType)
                end,
            }
        end
    end
    
    menuOptions[#menuOptions + 1] = {
        title = "Cancel",
        icon = "fas fa-times",
        iconColor = "#ff3333",
    }
    
    local icon = sitType == "bed" and "🛏️" or "🪑"
    lib.registerContext({
        id = "ogz_sit_menu",
        title = icon .. " " .. sitData.label .. " - Choose Style",
        options = menuOptions,
    })
    lib.showContext("ogz_sit_menu")
end

function SitWithScenario(entity, scenario, sitType, seatHeight)
    if isSeated then return end
    
    local ped = PlayerPedId()
    local chairCoords = GetEntityCoords(entity)
    local chairHeading = GetEntityHeading(entity)
    
    local sitX = chairCoords.x
    local sitY = chairCoords.y
    local sitZ = chairCoords.z + seatHeight
    
    seatedData = {
        entity = entity,
        sitType = sitType,
        useScenario = true,
        originalCoords = GetEntityCoords(ped),
    }
    
    ClearPedTasks(ped)
    
    TaskStartScenarioAtPosition(
        ped,
        scenario,
        sitX,
        sitY,
        sitZ,
        chairHeading + 180.0,
        0,
        true,
        true
    )
    
    isSeated = true
    ShowTextUI("[X] Stand Up", "fas fa-person-walking")
    Notify("Sitting down", "success")
    
    StartSeatMonitor()
end

function SitWithAnimation(entity, animInfo, sitType)
    if isSeated then return end
    
    local ped = PlayerPedId()
    local bedCoords = GetEntityCoords(entity)
    local bedHeading = GetEntityHeading(entity)
    
    if not LoadAnimDict(animInfo.dict) then
        Notify("Failed to load animation", "error")
        return
    end
    
    local offset = animInfo.offset
    local headingOffset = animInfo.heading or 0.0
    
    local rad = math.rad(bedHeading)
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    
    local sitX = bedCoords.x + (offset.x * cosRad) - (offset.y * sinRad)
    local sitY = bedCoords.y + (offset.x * sinRad) + (offset.y * cosRad)
    local sitZ = bedCoords.z + offset.z
    local sitHeading = bedHeading + headingOffset
    
    seatedData = {
        entity = entity,
        sitType = sitType,
        useScenario = false,
        animDict = animInfo.dict,
        animName = animInfo.anim,
        originalCoords = GetEntityCoords(ped),
        bedCoords = bedCoords,
        bedHeading = bedHeading,
        layZ = sitZ,
    }
    
    SetEntityCoords(ped, sitX, sitY, sitZ, false, false, false, false)
    Wait(100)
    SetEntityHeading(ped, sitHeading)
    Wait(100)
    
    TaskPlayAnim(ped, animInfo.dict, animInfo.anim, 8.0, -8.0, -1, animInfo.flags or 1, 0, false, false, false)
    
    isSeated = true
    ShowTextUI("[X] Get Up", "fas fa-person-walking")
    Notify("Laying down", "success")
    
    StartSeatMonitor()
end

function StartSeatMonitor()
    CreateThread(function()
        local ped = PlayerPedId()
        
        while isSeated do
            if IsControlJustPressed(0, 73) or IsControlJustPressed(0, 202) then
                StandUp()
                break
            end
            
            if seatedData and seatedData.useScenario then
                if not IsPedUsingAnyScenario(ped) and isSeated then
                    Wait(500)
                    if not IsPedUsingAnyScenario(ped) and isSeated then
                        StandUp()
                        break
                    end
                end
            end
            
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            DisableControlAction(0, 58, true)
            
            Wait(0)
        end
    end)
end

function StandUp()
    if not isSeated or isGettingUp then return end
    
    local ped = PlayerPedId()
    HideTextUI()
    
    -- For beds, play swing legs + stand animation
    if seatedData and seatedData.sitType == "bed" and seatedData.entity and DoesEntityExist(seatedData.entity) then
        isGettingUp = true
        
        local bedCoords = seatedData.bedCoords or GetEntityCoords(seatedData.entity)
        local bedHeading = seatedData.bedHeading or GetEntityHeading(seatedData.entity)
        local bedRad = math.rad(bedHeading)
        
        -- ═══════════════════════════════════════════════════════════════
        -- CAPTURED OFFSETS FROM /sit_capture (local to bed orientation)
        -- Captured: offset = vec3(-0.235, 0.086, 0.400), heading = +90°
        -- ═══════════════════════════════════════════════════════════════
        local edgeLocalX = -0.25   -- Left side of bed (perpendicular)
        local edgeLocalY = 0.0     -- Centered along bed length
        local edgeLocalZ = 0.4    -- Sitting height above bed origin
        
        local standLocalX = -0.8   -- Further out for final standing position
        local standLocalY = 0.0
        
        -- Calculate edge position (sitting on bed edge) using rotation matrix
        local edgeX = bedCoords.x + (edgeLocalX * math.cos(bedRad)) - (edgeLocalY * math.sin(bedRad))
        local edgeY = bedCoords.y + (edgeLocalX * math.sin(bedRad)) + (edgeLocalY * math.cos(bedRad))
        local edgeZ = bedCoords.z + edgeLocalZ
        local edgeHeading = bedHeading + 90  -- Face perpendicular to bed
        
        -- Calculate final stand position
        local standX = bedCoords.x + (standLocalX * math.cos(bedRad)) - (standLocalY * math.sin(bedRad))
        local standY = bedCoords.y + (standLocalX * math.sin(bedRad)) + (standLocalY * math.cos(bedRad))
        local found, groundZ = GetGroundZFor_3dCoord(standX, standY, bedCoords.z + 2.0, false)
        local standZ = found and groundZ or bedCoords.z
        
        -- Stop laying animation
        ClearPedTasks(ped)
        Wait(50)
        
        -- Move to edge of bed, sitting position
        SetEntityCoords(ped, edgeX, edgeY, edgeZ, false, false, false, false)
        SetEntityHeading(ped, edgeHeading)
        Wait(50)
        
        -- Play sit on bed edge animation (swing legs moment)
        local sitEdgeDict = "timetable@ron@ig_5_p3"
        if LoadAnimDict(sitEdgeDict) then
            TaskPlayAnim(ped, sitEdgeDict, "ig_5_p3_base", 4.0, -4.0, 800, 0, 0, false, false, false)
            Wait(600)
        end
        
        -- Stand up animation
        local standUpDict = "get_up@sat_on_floor@to_stand"
        if LoadAnimDict(standUpDict) then
            -- Intermediate position during stand (between edge and final)
            local midLocalX = -0.5
            local midX = bedCoords.x + (midLocalX * math.cos(bedRad))
            local midY = bedCoords.y + (midLocalX * math.sin(bedRad))
            SetEntityCoords(ped, midX, midY, edgeZ - 0.2, false, false, false, false)
            
            TaskPlayAnim(ped, standUpDict, "getup_0", 4.0, -4.0, 1500, 0, 0, false, false, false)
            Wait(1200)
            
            -- Final standing position
            SetEntityCoords(ped, standX, standY, standZ, false, false, false, false)
            SetEntityHeading(ped, edgeHeading)
            Wait(300)
        else
            -- Fallback if animation fails
            SetEntityCoords(ped, standX, standY, standZ, false, false, false, false)
            SetEntityHeading(ped, edgeHeading)
        end
        
        ClearPedTasks(ped)
        isGettingUp = false
    else
        ClearPedTasks(ped)
    end
    
    isSeated = false
    seatedData = nil
    Notify("Got up", "success")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PULL/PUSH/RESET
-- ═══════════════════════════════════════════════════════════════════════════

function PullFurniture(entity)
    if not DoesEntityExist(entity) or isMovingFurniture or isDragging or isSeated then return end
    
    local _, category = GetFurnitureCategory(GetEntityModel(entity))
    if not category then return end
    
    local settings = GetMovementSettings(category)
    if settings.maxPullDistance <= 0 then return end
    
    local hash, state = GetOrCreateState(entity)
    state.maxPullDistance = settings.maxPullDistance
    
    if state.currentPullDistance >= settings.maxPullDistance then
        Notify("Can't pull further!", "error")
        return
    end
    
    isMovingFurniture = true
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local entityCoords = GetEntityCoords(entity)
    
    if not state.pullDirection then
        state.pullDirection = GetDirection2D(entityCoords, playerCoords)
    end
    
    local pullAmount = math.min(settings.pullDistance, settings.maxPullDistance - state.currentPullDistance)
    local newX = entityCoords.x + (state.pullDirection.x * pullAmount)
    local newY = entityCoords.y + (state.pullDirection.y * pullAmount)
    local newZ = entityCoords.z
    
    SetEntityCoords(entity, newX, newY, newZ, false, false, false, false)
    PlaceObjectOnGroundProperly(entity)
    
    state.currentPullDistance = state.currentPullDistance + pullAmount
    state.entity = entity
    movedFurniture[hash] = state
    
    isMovingFurniture = false
    Notify(string.format("Pulled (%.1fm / %.1fm)", state.currentPullDistance, settings.maxPullDistance), "success")
end

function PushFurniture(entity)
    if not DoesEntityExist(entity) or isMovingFurniture or isDragging or isSeated then return end
    
    local hash, state = FindTrackingByEntity(entity)
    if not state or state.currentPullDistance <= 0 then return end
    
    local _, category = GetFurnitureCategory(GetEntityModel(entity))
    if not category then return end
    
    local settings = GetMovementSettings(category)
    isMovingFurniture = true
    
    local entityCoords = GetEntityCoords(entity)
    local pushAmount = math.min(settings.pushDistance, state.currentPullDistance)
    local direction = GetDirection2D(entityCoords, state.originalCoords)
    
    local newX = entityCoords.x + (direction.x * pushAmount)
    local newY = entityCoords.y + (direction.y * pushAmount)
    local newZ = entityCoords.z
    
    SetEntityCoords(entity, newX, newY, newZ, false, false, false, false)
    PlaceObjectOnGroundProperly(entity)
    
    state.currentPullDistance = state.currentPullDistance - pushAmount
    
    if state.currentPullDistance <= 0.05 then
        movedFurniture[hash] = nil
        Notify("Back in place!", "success")
    else
        movedFurniture[hash] = state
        Notify(string.format("Pushed (%.1fm remaining)", state.currentPullDistance), "success")
    end
    
    isMovingFurniture = false
end

function ResetFurniture(entity)
    if not DoesEntityExist(entity) or isMovingFurniture or isDragging or isSeated then return end
    
    local hash, state = FindTrackingByEntity(entity)
    if not state then
        Notify("Can't find original position!", "error")
        return
    end
    
    SetEntityCoords(entity, state.originalCoords.x, state.originalCoords.y, state.originalCoords.z, false, false, false, false)
    if state.originalHeading then
        SetEntityHeading(entity, state.originalHeading)
    end
    PlaceObjectOnGroundProperly(entity)
    
    movedFurniture[hash] = nil
    Notify("Reset to original position!", "success")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DRAG SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

function StartDragging(entity)
    if not DoesEntityExist(entity) or isDragging or isMovingFurniture or isSeated then return end
    
    local _, category = GetFurnitureCategory(GetEntityModel(entity))
    if not category then return end
    
    local settings = GetMovementSettings(category)
    if not settings.canDrag then return end
    
    local entityCoords = GetEntityCoords(entity)
    local entityHeading = GetEntityHeading(entity)
    local model = GetEntityModel(entity)
    
    local existingHash, existingState = FindTrackingByEntity(entity)
    local originalCoords = existingState and existingState.originalCoords or entityCoords
    local originalHeading = existingState and existingState.originalHeading or entityHeading
    local hash = existingHash or CreatePermanentHash(model, entityCoords)
    
    dragData = {
        entity = entity,
        originalCoords = originalCoords,
        originalHeading = originalHeading,
        currentHeading = entityHeading,
        maxRadius = settings.maxDragRadius,
        hash = hash,
        originalZ = entityCoords.z,
    }
    
    isDragging = true
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, false)
    
    local animConfig = Furniture.Dragging.animation
    if animConfig and animConfig.dict and LoadAnimDict(animConfig.dict) then
        TaskPlayAnim(PlayerPedId(), animConfig.dict, animConfig.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
    end
    
    ShowTextUI("[E] Place | [BACKSPACE] Cancel | [←→] Rotate", "fas fa-hand-holding")
    Notify("Moving furniture - stay within " .. settings.maxDragRadius .. "m", "info")
    
    CreateThread(DragLoop)
end

function DragLoop()
    local ped = PlayerPedId()
    local keys = Furniture.Dragging.keys or { drop = 38, cancel = 202, rotateLeft = 174, rotateRight = 175 }
    
    while isDragging and dragData do
        local pCoords = GetEntityCoords(ped)
        local forward = GetEntityForwardVector(ped)
        
        local targetX = pCoords.x + (forward.x * 0.8)
        local targetY = pCoords.y + (forward.y * 0.8)
        local targetZ = dragData.originalZ
        
        local dist = math.sqrt((targetX - dragData.originalCoords.x)^2 + (targetY - dragData.originalCoords.y)^2)
        
        if dist > dragData.maxRadius then
            local dirX = (targetX - dragData.originalCoords.x) / dist
            local dirY = (targetY - dragData.originalCoords.y) / dist
            targetX = dragData.originalCoords.x + (dirX * dragData.maxRadius)
            targetY = dragData.originalCoords.y + (dirY * dragData.maxRadius)
        end
        
        SetEntityCoords(dragData.entity, targetX, targetY, targetZ, false, false, false, false)
        
        if IsControlPressed(0, keys.rotateLeft) then
            dragData.currentHeading = dragData.currentHeading - 2.0
            SetEntityHeading(dragData.entity, dragData.currentHeading)
        end
        if IsControlPressed(0, keys.rotateRight) then
            dragData.currentHeading = dragData.currentHeading + 2.0
            SetEntityHeading(dragData.entity, dragData.currentHeading)
        end
        
        if IsControlJustPressed(0, keys.drop) then FinishDragging(false) break end
        if IsControlJustPressed(0, keys.cancel) then FinishDragging(true) break end
        
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        
        Wait(0)
    end
end

function FinishDragging(cancelled)
    if not isDragging or not dragData then return end
    
    local entity = dragData.entity
    HideTextUI()
    ClearPedTasks(PlayerPedId())
    
    if cancelled then
        SetEntityCoords(entity, dragData.originalCoords.x, dragData.originalCoords.y, dragData.originalCoords.z, false, false, false, false)
        SetEntityHeading(entity, dragData.originalHeading)
        movedFurniture[dragData.hash] = nil
        Notify("Cancelled", "info")
    else
        PlaceObjectOnGroundProperly(entity)
        local finalCoords = GetEntityCoords(entity)
        local distMoved = math.sqrt(
            (finalCoords.x - dragData.originalCoords.x)^2 + 
            (finalCoords.y - dragData.originalCoords.y)^2
        )
        
        movedFurniture[dragData.hash] = {
            entity = entity,
            originalCoords = dragData.originalCoords,
            originalHeading = dragData.originalHeading,
            currentPullDistance = distMoved,
            maxPullDistance = dragData.maxRadius,
            isDragged = true,
        }
        Notify("Placed!", "success")
    end
    
    SetEntityCollision(entity, true, true)
    FreezeEntityPosition(entity, true)
    isDragging = false
    dragData = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)
    if not Furniture or not Furniture.Enabled then return end
    RegisterFurnitureTargets()
    
    local count = 0
    for _, cat in pairs(Furniture.Categories) do count = count + #cat.models end
    
    print(string.format("^2[OGz PropManager v3.4]^0 Furniture: %d models | Swing legs bed exit", count))
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for _, data in pairs(movedFurniture) do
        if data.entity and DoesEntityExist(data.entity) then
            SetEntityCoords(data.entity, data.originalCoords.x, data.originalCoords.y, data.originalCoords.z, false, false, false, false)
            if data.originalHeading then
                SetEntityHeading(data.entity, data.originalHeading)
            end
        end
    end
    
    if isSeated then ClearPedTasks(PlayerPedId()) end
    if isDragging then FinishDragging(true) end
    HideTextUI()
end)

RegisterCommand("ogz_standup", function() if isSeated then StandUp() end end, false)

exports("IsSeated", function() return isSeated end)
exports("StandUp", StandUp)
exports("IsDragging", function() return isDragging end)
