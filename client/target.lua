--[[
    OGz PropManager - Target Integration v2
    
    Handles ox_target options for placed stations
    Includes: Durability display, cooldown checks, multi-table menus
]]

local placedProps = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function CanSeeCraftingTable(tableConfig)
    if not tableConfig.visibleTo then return true end
    local canSee = false
    if tableConfig.visibleTo.jobs and HasJob(tableConfig.visibleTo.jobs) then canSee = true end
    if tableConfig.visibleTo.gangs and HasGang(tableConfig.visibleTo.gangs) then canSee = true end
    if not tableConfig.visibleTo.jobs and not tableConfig.visibleTo.gangs then return true end
    return canSee
end

local function GetAvailableCraftingTables(stationConfig)
    local available = {}
    if stationConfig.craftingTables then
        for _, tableConfig in ipairs(stationConfig.craftingTables) do
            if CanSeeCraftingTable(tableConfig) then available[#available + 1] = tableConfig end
        end
    elseif stationConfig.craftingTable then
        available[#available + 1] = { name = stationConfig.craftingTable, label = stationConfig.label, icon = stationConfig.icon, iconColor = stationConfig.iconColor }
    end
    return available
end

local function FormatDurabilityLabel(durability, label)
    -- No longer showing durability on target label
    return label
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION INFO MENU
-- ═══════════════════════════════════════════════════════════════════════════

local function GetDurabilityBar(durability)
    local bars = 10
    local filled = math.floor((durability / 100) * bars)
    local empty = bars - filled
    local color = durability >= 75 and "^2" or durability >= 25 and "^3" or "^1"
    return string.rep("█", filled) .. string.rep("░", empty)
end

local function OpenStationInfoMenu(entity, propData)
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return end
    
    -- Get fresh durability from server
    lib.callback('ogz_propmanager:server:GetStationDurability', false, function(freshDurability)
        local durability = freshDurability or propData.durability or 100
        local durabilityColor = GetDurabilityColor(durability)
        local repairItem = stationConfig.durability and stationConfig.durability.repairItem or Config.Durability.DefaultRepairItem
        local repairItemLabel = GetItemLabel(repairItem)
        local repairAmount = Config.Durability.RepairAmount or 50
        local hasRepairKit = exports.ox_inventory:Search('count', repairItem) > 0
        local ownerText = propData.citizenid == 'PREDEFINED' and "Server (Permanent)" or 
                         propData.citizenid == GetCitizenId() and "You" or "Another Player"
        
        local options = {
            {
                title = "📊 Station Status",
                description = string.format("Durability: %d%% %s", durability, GetDurabilityBar(durability)),
                icon = "fas fa-heart",
                iconColor = durabilityColor,
                disabled = true,
            },
            {
                title = "👤 Owner",
                description = ownerText,
                icon = "fas fa-user",
                disabled = true,
            },
        }
        
        -- Repair option
        if Config.Durability.Enabled and durability < 100 then
            local repairDesc = hasRepairKit 
                and string.format("Use %s to repair (+%d%%)", repairItemLabel, repairAmount)
                or string.format("Requires: %s", repairItemLabel)
            
            options[#options + 1] = {
                title = "🔧 Repair Station",
                description = repairDesc,
                icon = "fas fa-wrench",
                iconColor = hasRepairKit and "#00ff00" or "#ff6666",
                disabled = not hasRepairKit,
                onSelect = function()
                    RepairStation(propData)
                end,
            }
        elseif Config.Durability.Enabled then
            options[#options + 1] = {
                title = "✅ Fully Repaired",
                description = "Station is at 100% durability",
                icon = "fas fa-check-circle",
                iconColor = "#00ff00",
                disabled = true,
            }
        end
        
        -- Cooldown status (if applicable)
        if stationConfig.cooldown then
            lib.callback('ogz_propmanager:server:CheckCooldown', false, function(onCooldown, remaining)
                if onCooldown then
                    table.insert(options, 2, {
                        title = "⏳ On Cooldown",
                        description = string.format("%d seconds remaining", remaining),
                        icon = "fas fa-clock",
                        iconColor = "#ff9900",
                        disabled = true,
                    })
                end
                
                lib.registerContext({
                    id = "ogz_station_info",
                    title = "🔍 " .. stationConfig.label,
                    options = options,
                })
                lib.showContext("ogz_station_info")
            end, propData.id)
        else
            lib.registerContext({
                id = "ogz_station_info",
                title = "🔍 " .. stationConfig.label,
                options = options,
            })
            lib.showContext("ogz_station_info")
        end
    end, propData.id)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGET REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

function AddTargetToEntity(entity, propData)
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return end
    
    local options = {}
    
    -- Use Station option (clean label, no durability %)
    options[#options + 1] = {
        name = "ogz_use_" .. propData.station_id,
        icon = stationConfig.icon or "fas fa-cog",
        iconColor = stationConfig.iconColor or "#ffffff",
        label = "Use " .. stationConfig.label,
        distance = Config.InteractDistance,
        canInteract = function() return CanSeeStation(stationConfig) end,
        onSelect = function() UseStation(entity, propData) end,
    }
    
    -- Station Info option (shows durability, repair, etc.)
    options[#options + 1] = {
        name = "ogz_info_" .. propData.station_id,
        icon = "fas fa-info-circle",
        iconColor = "#3399ff",
        label = "Station Info",
        distance = Config.InteractDistance,
        onSelect = function() OpenStationInfoMenu(entity, propData) end,
    }
    
    -- Remove option (owner only, not for predefined)
    options[#options + 1] = {
        name = "ogz_remove_" .. propData.station_id,
        icon = "fas fa-box",
        iconColor = "#ff6600",
        label = "Remove " .. stationConfig.label,
        distance = Config.InteractDistance,
        canInteract = function() 
            return propData.citizenid ~= 'PREDEFINED' and propData.citizenid == GetCitizenId() 
        end,
        onSelect = function() RemoveStation(entity, propData) end,
    }
    
    -- Police Seize option (not for predefined)
    if Config.PoliceOverride.Enabled then
        options[#options + 1] = {
            name = "ogz_seize_" .. propData.station_id,
            icon = Config.PoliceOverride.SeizeIcon,
            iconColor = "#ff0000",
            label = Config.PoliceOverride.SeizeLabel,
            distance = Config.InteractDistance,
            canInteract = function() 
                return propData.citizenid ~= 'PREDEFINED' and IsPolice() and propData.citizenid ~= GetCitizenId() 
            end,
            onSelect = function() SeizeStation(entity, propData) end,
        }
    end
    
    exports.ox_target:addLocalEntity(entity, options)
end

local function RemoveTargetFromEntity(entity)
    if DoesEntityExist(entity) then
        pcall(function() exports.ox_target:removeLocalEntity(entity) end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION INTERACTIONS
-- ═══════════════════════════════════════════════════════════════════════════

local function OpenCraftingTable(propId, entity, propData, craftingTableName)
    local stationConfig = GetStationConfig(propData.station_id)
    
    -- Start crafting session with coop bonus
    local coopBonus = StartCraftingSession(propId, entity, propData, stationConfig)
    
    -- Use state-aware function if station has model states
    if stationConfig and stationConfig.modelStates then
        OpenCraftingWithStates(propId, entity, propData, craftingTableName)
    else
        exports.ox_inventory:openInventory('crafting', { id = craftingTableName })
        StartStateMonitor(propId, entity, propData)
    end
end

function UseStation(entity, propData)
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return end
    
    -- Pre-craft checks
    local canCraft, reason = PreCraftChecks(propData.id, propData, stationConfig)
    if not canCraft then
        Notify(reason, "error")
        return
    end
    
    -- Check cooldown (server callback)
    lib.callback("ogz_propmanager:server:CheckCooldown", false, function(onCooldown, remaining)
        if onCooldown then
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            Notify(string.format(Config.Notifications.OnCooldown, string.format("%dm %ds", minutes, seconds)), "error")
            return
        end
        
        -- Get fresh durability and warn if low
        lib.callback('ogz_propmanager:server:GetStationDurability', false, function(freshDurability)
            local durability = freshDurability or propData.durability or 100
            
            -- Warn if durability is low
            if Config.Durability.Enabled and durability <= Config.Durability.WarnAtPercent then
                local repairItem = stationConfig.durability and stationConfig.durability.repairItem or Config.Durability.DefaultRepairItem
                local repairItemLabel = GetItemLabel(repairItem)
                Notify(string.format("⚠️ Station at %d%% durability! Use %s to repair.", durability, repairItemLabel), "warning")
            end
            
            -- Block if broken
            if Config.Durability.Enabled and Config.Durability.BreakAtZero and durability <= 0 then
                Notify("❌ Station is broken and needs repair!", "error")
                return
            end
        
            -- Face the prop
            local playerPed = PlayerPedId()
            local propCoords = GetEntityCoords(entity)
            TaskTurnPedToFaceCoord(playerPed, propCoords.x, propCoords.y, propCoords.z, 1000)
            Wait(500)
            
            -- ═══════════════════════════════════════════════════════════════════
            -- v3.1 PROCESSING SYSTEM CHECK
            -- If station has processingStation defined, use the new processing system
            -- instead of ox_inventory crafting tables
            -- ═══════════════════════════════════════════════════════════════════
            if stationConfig.processingStation then
                DebugPrint("Station has processingStation:", stationConfig.processingStation)
                -- Use the v3.1 processing system with metadata preservation
                if OpenProcessingMenu then
                    OpenProcessingMenu(stationConfig.processingStation, entity, propData)
                else
                    -- Fallback error if processing.lua isn't loaded
                    Notify("Processing system not available", "error")
                    print("[OGz PropManager] ERROR: OpenProcessingMenu function not found - is client/processing.lua loaded?")
                end
                return
            end
            
            -- ═══════════════════════════════════════════════════════════════════
            -- STANDARD CRAFTING TABLE SYSTEM (ox_inventory)
            -- For stations without processingStation defined
            -- ═══════════════════════════════════════════════════════════════════
            
            -- Get available crafting tables
            local availableTables = GetAvailableCraftingTables(stationConfig)
            
            if #availableTables == 0 then
                Notify(Config.Notifications.NoAccess, "error")
                return
            end
            
            -- Single table - open directly
            if #availableTables == 1 then
                OpenCraftingTable(propData.id, entity, propData, availableTables[1].name)
                return
            end
            
            -- Multiple tables - show menu
            local menuOptions = {}
            for _, tableConfig in ipairs(availableTables) do
                menuOptions[#menuOptions + 1] = {
                    title = tableConfig.label or tableConfig.name,
                    icon = tableConfig.icon or stationConfig.icon or "fas fa-cog",
                    iconColor = tableConfig.iconColor or stationConfig.iconColor or Config.UI.IconColor,
                    onSelect = function()
                        OpenCraftingTable(propData.id, entity, propData, tableConfig.name)
                    end,
                }
            end
            
            lib.registerContext({ id = "ogz_crafting_select", title = stationConfig.label, options = menuOptions })
            lib.showContext("ogz_crafting_select")
        end, propData.id)  -- End of GetStationDurability callback
    end, propData.id)  -- End of CheckCooldown callback
end

function RepairStation(propData)
    local repairAnim = GetAnimationConfig("Repair")
    local success = PlayAnimationWithProgress(repairAnim, "Repairing station...")
    
    if success then
        TriggerServerEvent("ogz_propmanager:server:RepairStation", propData.id)
    end
end

function RemoveStation(entity, propData)
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return end
    
    local removeAnim = GetAnimationConfig("Remove")
    local success = PlayAnimationWithProgress(removeAnim, "Removing " .. stationConfig.label .. "...")
    
    if success then
        TriggerServerEvent("ogz_propmanager:server:RemoveStation", propData.id, false)
    end
end

function SeizeStation(entity, propData)
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return end
    
    local confirm = lib.alertDialog({
        header = "Seize Station",
        content = "Are you sure you want to seize this " .. stationConfig.label .. "?",
        centered = true, cancel = true,
    })
    
    if confirm ~= "confirm" then return end
    
    local seizeAnim = GetAnimationConfig("Seize")
    local success = PlayAnimationWithProgress(seizeAnim, "Seizing " .. stationConfig.label .. "...")
    
    if success then
        TriggerServerEvent("ogz_propmanager:server:RemoveStation", propData.id, true)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROP MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

local function SpawnProp(propData)
    local stationConfig = GetStationConfig(propData.station_id)
    if not stationConfig then return nil end
    
    -- Use OFF state model if exists
    local modelName = stationConfig.model
    if stationConfig.modelStates and stationConfig.modelStates.off then
        modelName = stationConfig.modelStates.off.model or stationConfig.modelStates.off
    end
    
    local modelHash = type(modelName) == "string" and joaat(modelName) or modelName
    if not LoadModel(modelHash) then return nil end
    
    local coords = propData.coords
    local heading = propData.heading or 0.0
    
    DebugPrint("SpawnProp - Coords:", coords.x, coords.y, coords.z, "Heading:", heading, "Raw:", propData.heading)
    
    local entity = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
    
    if DoesEntityExist(entity) then
        SetEntityHeading(entity, heading)
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, true, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        placedProps[propData.id] = { entity = entity, data = propData }
        AddTargetToEntity(entity, propData)
        
        DebugPrint("Spawned:", entity, stationConfig.label, "Durability:", propData.durability, "Heading:", heading)
        return entity
    end
    return nil
end

local function RemovePropLocal(propId)
    local propInfo = placedProps[propId]
    if propInfo then
        EndCraftingSession(propId)
        RemoveTargetFromEntity(propInfo.entity)
        if DoesEntityExist(propInfo.entity) then DeleteEntity(propInfo.entity) end
        placedProps[propId] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:LoadProps", function(props)
    DebugPrint("Loading", #props, "props")
    for _, propData in ipairs(props) do SpawnProp(propData) end
end)

RegisterNetEvent("ogz_propmanager:client:SpawnProp", function(propData)
    SpawnProp(propData)
end)

RegisterNetEvent("ogz_propmanager:client:RemoveProp", function(propId)
    RemovePropLocal(propId)
end)

RegisterNetEvent("ogz_propmanager:client:RefreshProps", function(props)
    for propId, propInfo in pairs(placedProps) do
        RemoveTargetFromEntity(propInfo.entity)
        if DoesEntityExist(propInfo.entity) then DeleteEntity(propInfo.entity) end
    end
    placedProps = {}
    for _, propData in ipairs(props) do SpawnProp(propData) end
end)

RegisterNetEvent("ogz_propmanager:client:UpdatePropEntity", function(propId, newEntity)
    if placedProps[propId] then placedProps[propId].entity = newEntity end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for propId, propInfo in pairs(placedProps) do
        RemoveTargetFromEntity(propInfo.entity)
        if DoesEntityExist(propInfo.entity) then DeleteEntity(propInfo.entity) end
    end
    placedProps = {}
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

-- Global alias for states.lua
ReaddTargetToEntity = AddTargetToEntity

exports("GetPlacedProps", function() return placedProps end)
exports("ReaddTargetToEntity", AddTargetToEntity)
