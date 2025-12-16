--[[
    OGz PropManager v3.2 - Client Stashes
    
    Handles portable storage container placement, targeting, and access menus.
    
    v3.2: Player-friendly access display (names instead of citizenids)
          Nearby player selector for granting access
          Fixed pickup notification message
          Uses shared placement system (gizmo/raycast choice + ground snap)
]]

if not Config.Features.Stashes then return end

local placedStashes = {}
local isPlacingStash = false
local stashHandlersRegistered = false

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetStashConfig(stashType)
    return Stashes[stashType]
end

local function CanSeeStash(stashConfig)
    if not stashConfig.visibleTo then return true end
    if stashConfig.visibleTo.jobs and HasJob(stashConfig.visibleTo.jobs) then return true end
    if stashConfig.visibleTo.gangs and HasGang(stashConfig.visibleTo.gangs) then return true end
    return false
end

---Check if ox_inventory is ready (uses export from main.lua or local check)
local function IsInventoryReady()
    local success, result = pcall(function()
        return exports.ox_inventory:GetPlayerItems()
    end)
    return success and result ~= nil
end

---Wait for inventory to be ready with timeout
local function WaitForInventory(timeout)
    local waited = 0
    local checkInterval = 100
    timeout = timeout or 10000
    
    while not IsInventoryReady() and waited < timeout do
        Wait(checkInterval)
        waited = waited + checkInterval
    end
    
    return waited < timeout
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ITEM USAGE HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

local itemToStash = {}

---Register stash item handlers with ox_inventory
local function RegisterStashItemHandlers()
    if stashHandlersRegistered then return end
    
    -- Build item lookup
    for stashType, stashConfig in pairs(Stashes) do
        if stashConfig.item then
            itemToStash[stashConfig.item] = stashType
            DebugPrint("Stash mapped:", stashConfig.item, "→", stashType)
        end
    end
    
    -- Register with ox_inventory
    for itemName, stashType in pairs(itemToStash) do
        local success, err = pcall(function()
            exports.ox_inventory:useItem(itemName, function(data, slot)
                DebugPrint("Stash useItem:", itemName)
                UseStashItem(itemName)
            end)
        end)
        
        if not success then
            print(string.format("[OGz PropManager] Failed to register stash handler for %s: %s", itemName, tostring(err)))
        end
    end
    
    stashHandlersRegistered = true
    print("[OGz PropManager] Stash item handlers registered successfully")
end

-- Initialize stash handlers when ready
CreateThread(function()
    -- Wait for player to be loaded first
    while not GetPlayerData() or not GetPlayerData().citizenid do
        Wait(100)
    end
    
    DebugPrint("Player loaded, waiting for inventory (stashes)...")
    
    -- Wait for inventory to be ready
    if WaitForInventory(15000) then
        DebugPrint("Inventory ready, registering stash item handlers...")
        RegisterStashItemHandlers()
    else
        -- Fallback: try registering anyway after timeout
        print("[OGz PropManager] Inventory timeout (stashes) - attempting handler registration anyway")
        RegisterStashItemHandlers()
    end
end)

-- Fallback event handler
AddEventHandler('ox_inventory:usedItem', function(itemName, slotId, metadata)
    if itemToStash[itemName] then
        UseStashItem(itemName)
    end
end)

function UseStashItem(itemName)
    local stashType = itemToStash[itemName]
    if not stashType then return end
    
    if isPlacingStash or IsPlacing() then
        Notify("Already placing something!", "error")
        return
    end
    
    TriggerServerEvent("ogz_propmanager:server:CheckStashLimit", stashType, itemName)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEMENT (v3.2: Uses shared placement system)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:StartStashPlacement", function(stashType)
    local stashConfig = GetStashConfig(stashType)
    if not stashConfig then return end
    
    isPlacingStash = true
    
    -- v3.2: Use the shared placement system from placement.lua
    -- This provides gizmo/raycast choice and proper ground snap
    StartStashPlacement(stashType)
    
    isPlacingStash = false
end)

RegisterNetEvent("ogz_propmanager:client:StashLimitReached", function(current, max)
    Notify(string.format(Config.Notifications.MaxStations, current, max), "error")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGET OPTIONS
-- ═══════════════════════════════════════════════════════════════════════════

function AddStashTargetToEntity(entity, stashData)
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return end
    
    local options = {}
    
    -- Open Stash
    options[#options + 1] = {
        name = "ogz_open_stash_" .. stashData.id,
        icon = stashConfig.icon or "fas fa-box-open",
        iconColor = stashConfig.iconColor or "#ffffff",
        label = "Open " .. stashConfig.label,
        distance = Config.InteractDistance,
        canInteract = function()
            -- Hidden stashes require search (future feature)
            if stashConfig.stash and stashConfig.stash.hidden then
                -- TODO: Add reveal mechanic
            end
            return true
        end,
        onSelect = function()
            OpenStash(entity, stashData)
        end,
    }
    
    -- Stash Info
    options[#options + 1] = {
        name = "ogz_info_stash_" .. stashData.id,
        icon = "fas fa-info-circle",
        iconColor = "#3399ff",
        label = "Stash Info",
        distance = Config.InteractDistance,
        onSelect = function()
            OpenStashInfoMenu(entity, stashData)
        end,
    }
    
    -- Pick Up (owner only)
    options[#options + 1] = {
        name = "ogz_pickup_stash_" .. stashData.id,
        icon = "fas fa-hand",
        iconColor = "#ff6600",
        label = "Pick Up " .. stashConfig.label,
        distance = Config.InteractDistance,
        canInteract = function()
            return stashData.citizenid == GetCitizenId()
        end,
        onSelect = function()
            PickUpStash(entity, stashData)
        end,
    }
    
    -- Manage Access (owner only, if allowed)
    if stashConfig.stash and stashConfig.stash.allowCustomAccess then
        options[#options + 1] = {
            name = "ogz_access_stash_" .. stashData.id,
            icon = "fas fa-users-cog",
            iconColor = "#9933ff",
            label = "Manage Access",
            distance = Config.InteractDistance,
            canInteract = function()
                return stashData.citizenid == GetCitizenId()
            end,
            onSelect = function()
                OpenAccessMenu(entity, stashData)
            end,
        }
    end
    
    -- Police Seize
    if Config.Stashes.PoliceCanSeize then
        options[#options + 1] = {
            name = "ogz_seize_stash_" .. stashData.id,
            icon = Config.PoliceOverride.SeizeIcon,
            iconColor = "#ff0000",
            label = Config.PoliceOverride.SeizeLabel,
            distance = Config.InteractDistance,
            canInteract = function()
                return IsPolice() and stashData.citizenid ~= GetCitizenId()
            end,
            onSelect = function()
                SeizeStash(entity, stashData)
            end,
        }
    end
    
    exports.ox_target:addLocalEntity(entity, options)
end

function RemoveStashTargetFromEntity(entity)
    if DoesEntityExist(entity) then
        exports.ox_target:removeLocalEntity(entity)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STASH ACTIONS
-- ═══════════════════════════════════════════════════════════════════════════

function OpenStash(entity, stashData)
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return end
    
    -- Face the stash
    local playerPed = PlayerPedId()
    local stashCoords = GetEntityCoords(entity)
    TaskTurnPedToFaceCoord(playerPed, stashCoords.x, stashCoords.y, stashCoords.z, 1000)
    Wait(500)
    
    -- Check access and open
    lib.callback('ogz_propmanager:server:CheckStashAccess', false, function(hasAccess, stashId)
        if hasAccess and stashId then
            -- Play animation
            local anim = GetAnimationConfig("StashOpen")
            if anim and anim.Time then
                PlayAnimationWithProgress(anim, "Opening...")
            end
            
            TriggerServerEvent("ogz_propmanager:server:OpenStash", stashData.id)
        else
            Notify(Config.Notifications.StashNoAccess, "error")
        end
    end, stashData.id)
end

function PickUpStash(entity, stashData)
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return end
    
    -- Check if empty (v3.2: Fixed notification message)
    lib.callback('ogz_propmanager:server:IsStashEmpty', false, function(isEmpty)
        if not isEmpty then
            Notify("Stash must be empty before picking up!", "error")
            return
        end
        
        -- Confirm pickup
        local confirm = lib.alertDialog({
            header = "Pick Up " .. stashConfig.label,
            content = "Are you sure you want to pick up this " .. stashConfig.label .. "?",
            centered = true,
            cancel = true,
        })
        
        if confirm ~= "confirm" then return end
        
        -- Play animation
        local anim = GetAnimationConfig("Remove")
        if anim then
            PlayAnimationWithProgress(anim, "Picking up...")
        end
        
        TriggerServerEvent("ogz_propmanager:server:RemoveStash", stashData.id, false)
    end, stashData.stash_id)
end

function SeizeStash(entity, stashData)
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return end
    
    local confirm = lib.alertDialog({
        header = Config.PoliceOverride.SeizeLabel,
        content = "Are you sure you want to seize this " .. stashConfig.label .. "? Contents will be preserved.",
        centered = true,
        cancel = true,
    })
    
    if confirm ~= "confirm" then return end
    
    local anim = GetAnimationConfig("Remove")
    if anim then
        PlayAnimationWithProgress(anim, "Seizing...")
    end
    
    TriggerServerEvent("ogz_propmanager:server:RemoveStash", stashData.id, true)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STASH INFO MENU
-- ═══════════════════════════════════════════════════════════════════════════

function OpenStashInfoMenu(entity, stashData)
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return end
    
    local options = {}
    
    -- Basic info
    options[#options + 1] = {
        title = "📦 " .. stashConfig.label,
        description = stashConfig.description or "Portable storage container",
        icon = stashConfig.icon or "fas fa-box",
        iconColor = stashConfig.iconColor or "#ffffff",
        disabled = true,
    }
    
    -- Storage info
    local slots = stashConfig.stash and stashConfig.stash.slots or Config.Stashes.DefaultSlots
    local weight = stashConfig.stash and stashConfig.stash.maxWeight or Config.Stashes.DefaultMaxWeight
    options[#options + 1] = {
        title = "📊 Storage",
        description = string.format("%d slots, %dkg capacity", slots, weight / 1000),
        icon = "fas fa-database",
        iconColor = "#3399ff",
        disabled = true,
    }
    
    -- Owner info
    local isOwner = stashData.citizenid == GetCitizenId()
    options[#options + 1] = {
        title = isOwner and "👤 You own this" or "👤 Owned by someone else",
        icon = "fas fa-user",
        iconColor = isOwner and "#00ff00" or "#ff9900",
        disabled = true,
    }
    
    lib.registerContext({
        id = "ogz_stash_info",
        title = "ℹ️ Stash Info",
        options = options,
    })
    lib.showContext("ogz_stash_info")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ACCESS MANAGEMENT (v3.2: Updated with friendly player names)
-- ═══════════════════════════════════════════════════════════════════════════

function OpenAccessMenu(entity, stashData)
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return end
    
    -- Fetch fresh data
    lib.callback('ogz_propmanager:server:GetStashData', false, function(freshData)
        if not freshData then return end
        
        local options = {}
        
        -- Grant access to nearby player (v3.2: Shows list of nearby players with Server ID)
        options[#options + 1] = {
            title = "➕ Grant Access to Nearby Player",
            description = "Select from players within 10m",
            icon = "fas fa-user-plus",
            iconColor = "#00ff00",
            onSelect = function()
                OpenNearbyPlayerMenu(stashData.id)
            end,
        }
        
        -- Manual citizenid input (fallback)
        options[#options + 1] = {
            title = "🔑 Grant Access by Citizen ID",
            description = "Enter citizenid manually (for offline players)",
            icon = "fas fa-keyboard",
            iconColor = "#ffaa00",
            onSelect = function()
                local input = lib.inputDialog("Grant Access", {
                    { type = 'input', label = 'Citizen ID', placeholder = 'ABC12345', required = true },
                })
                
                if input and input[1] then
                    TriggerServerEvent("ogz_propmanager:server:AddStashAccess", stashData.id, input[1])
                end
            end,
        }
        
        -- Current access list
        if freshData.custom_access and #freshData.custom_access > 0 then
            options[#options + 1] = {
                title = "👥 Current Access (" .. #freshData.custom_access .. ")",
                description = "Click to manage individual access",
                icon = "fas fa-users",
                iconColor = "#3399ff",
                onSelect = function()
                    OpenAccessListMenu(stashData.id, freshData.custom_access)
                end,
            }
        end
        
        -- Show gang/job access info
        if freshData.access_gang then
            options[#options + 1] = {
                title = "🏴 Gang Access",
                description = "Shared with: " .. freshData.access_gang,
                icon = "fas fa-users",
                iconColor = "#ff6600",
                disabled = true,
            }
        end
        
        if freshData.access_job then
            options[#options + 1] = {
                title = "💼 Job Access",
                description = "Shared with: " .. freshData.access_job,
                icon = "fas fa-briefcase",
                iconColor = "#0066ff",
                disabled = true,
            }
        end
        
        lib.registerContext({
            id = "ogz_stash_access",
            title = "🔐 Manage Access - " .. stashConfig.label,
            menu = "ogz_stash_info",
            options = options,
        })
        lib.showContext("ogz_stash_access")
    end, stashData.id)
end

-- v3.2: New function - Select nearby player to grant access
function OpenNearbyPlayerMenu(propId)
    -- Get nearby players from server (includes Server ID and Name)
    local nearbyPlayers = lib.callback.await('ogz_propmanager:server:GetNearbyPlayers', false, 10.0)
    
    if not nearbyPlayers or #nearbyPlayers == 0 then
        Notify("No players nearby!", "error")
        return
    end
    
    local options = {}
    
    for _, player in ipairs(nearbyPlayers) do
        options[#options + 1] = {
            title = string.format("ID: %d - %s", player.source, player.name),
            description = string.format("%.1fm away", player.distance),
            icon = "fas fa-user",
            iconColor = "#00ff00",
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = "Grant Access",
                    content = string.format("Grant stash access to %s (ID: %d)?", player.name, player.source),
                    centered = true,
                    cancel = true,
                })
                
                if confirm == "confirm" then
                    TriggerServerEvent("ogz_propmanager:server:AddStashAccess", propId, player.citizenid)
                end
            end,
        }
    end
    
    lib.registerContext({
        id = "ogz_stash_nearby_players",
        title = "👥 Select Player",
        menu = "ogz_stash_access",
        options = options,
    })
    lib.showContext("ogz_stash_nearby_players")
end

-- v3.2: Updated - Shows player names instead of citizenids
function OpenAccessListMenu(propId, accessList)
    local options = {}
    
    -- Fetch player info for each citizenid
    for _, citizenid in ipairs(accessList) do
        -- Get player info from server (name, online status)
        local playerInfo = lib.callback.await('ogz_propmanager:server:GetPlayerInfoByCid', false, citizenid)
        
        local title = playerInfo and playerInfo.name or citizenid
        local description = playerInfo and playerInfo.online 
            and string.format("🟢 Online (ID: %d) - Click to revoke", playerInfo.source)
            or "⚫ Offline - Click to revoke"
        local iconColor = playerInfo and playerInfo.online and "#00ff00" or "#666666"
        
        options[#options + 1] = {
            title = title,
            description = description,
            icon = "fas fa-user",
            iconColor = iconColor,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = "Revoke Access",
                    content = "Remove access for " .. title .. "?",
                    centered = true,
                    cancel = true,
                })
                
                if confirm == "confirm" then
                    TriggerServerEvent("ogz_propmanager:server:RemoveStashAccess", propId, citizenid)
                    Wait(500)
                    -- Refresh the menu
                    lib.callback('ogz_propmanager:server:GetStashData', false, function(freshData)
                        if freshData and freshData.custom_access then
                            OpenAccessListMenu(propId, freshData.custom_access)
                        else
                            lib.showContext("ogz_stash_access")
                        end
                    end, propId)
                end
            end,
        }
    end
    
    if #options == 0 then
        options[#options + 1] = {
            title = "No players have access",
            icon = "fas fa-user-slash",
            iconColor = "#666666",
            disabled = true,
        }
    end
    
    lib.registerContext({
        id = "ogz_stash_access_list",
        title = "👥 Players with Access",
        menu = "ogz_stash_access",
        options = options,
    })
    lib.showContext("ogz_stash_access_list")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROP MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

local function SpawnStash(stashData)
    local stashConfig = GetStashConfig(stashData.stash_type)
    if not stashConfig then return nil end
    
    local modelName = stashConfig.model
    local modelHash = type(modelName) == "string" and joaat(modelName) or modelName
    if not LoadModel(modelHash) then return nil end
    
    local coords = stashData.coords
    local heading = stashData.heading or 0.0
    
    local entity = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
    
    if DoesEntityExist(entity) then
        SetEntityHeading(entity, heading)
        
        -- v3.2 FIX: Place on ground BEFORE freezing to prevent floating
        PlaceObjectOnGroundProperly(entity)
        
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, true, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        placedStashes[stashData.id] = { entity = entity, data = stashData }
        AddStashTargetToEntity(entity, stashData)
        
        DebugPrint("Spawned stash:", stashConfig.label, "ID:", stashData.stash_id)
        return entity
    end
    return nil
end

local function RemoveStashLocal(propId)
    local stashInfo = placedStashes[propId]
    if stashInfo then
        RemoveStashTargetFromEntity(stashInfo.entity)
        if DoesEntityExist(stashInfo.entity) then 
            DeleteEntity(stashInfo.entity) 
        end
        placedStashes[propId] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:LoadStashes", function(stashes)
    DebugPrint("Loading", #stashes, "stashes")
    for _, stashData in ipairs(stashes) do 
        SpawnStash(stashData) 
    end
end)

RegisterNetEvent("ogz_propmanager:client:SpawnStash", function(stashData)
    SpawnStash(stashData)
end)

RegisterNetEvent("ogz_propmanager:client:RemoveStash", function(propId)
    RemoveStashLocal(propId)
end)

-- Request stashes on load
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(2500)
    local bucket = Config.UseRoutingBucket and GetCurrentBucket() or 0
    TriggerServerEvent("ogz_propmanager:server:RequestStashes", bucket)
end)

-- Also handle resource restart
CreateThread(function()
    Wait(2000)
    local playerData = GetPlayerData()
    if playerData and playerData.citizenid then
        local bucket = Config.UseRoutingBucket and GetCurrentBucket() or 0
        TriggerServerEvent("ogz_propmanager:server:RequestStashes", bucket)
    end
end)

-- Bucket change handler
if Config.UseRoutingBucket then
    local lastBucket = 0
    
    CreateThread(function()
        Wait(3000)
        while true do
            Wait(1000)
            local currentBucket = GetCurrentBucket()
            if currentBucket ~= lastBucket then
                lastBucket = currentBucket
                -- Clear old stashes
                for propId, stashInfo in pairs(placedStashes) do
                    RemoveStashTargetFromEntity(stashInfo.entity)
                    if DoesEntityExist(stashInfo.entity) then 
                        DeleteEntity(stashInfo.entity) 
                    end
                end
                placedStashes = {}
                -- Request new
                TriggerServerEvent("ogz_propmanager:server:RequestStashes", currentBucket)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for propId, stashInfo in pairs(placedStashes) do
        RemoveStashTargetFromEntity(stashInfo.entity)
        if DoesEntityExist(stashInfo.entity) then 
            DeleteEntity(stashInfo.entity) 
        end
    end
    placedStashes = {}
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("ogz_test_stash", function(_, args)
    local stashType = args[1] or "portable_safe"
    print("[OGz PropManager] Test placing stash:", stashType)
    local stashConfig = GetStashConfig(stashType)
    if stashConfig then
        -- v3.2: Use shared placement system
        StartStashPlacement(stashType)
    else
        print("[OGz PropManager] Unknown stash type:", stashType)
    end
end, false)

RegisterCommand("ogz_stash_items", function()
    print("[OGz PropManager] Registered stash items:")
    for itemName, stashType in pairs(itemToStash) do
        print("  -", itemName, "→", stashType)
    end
    print("[OGz PropManager] Stash handlers registered:", stashHandlersRegistered)
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports("GetPlacedStashes", function() return placedStashes end)
exports("IsPlacingStash", function() return isPlacingStash end)
