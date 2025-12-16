--[[
    OGz PropManager - Client Main
    
    Core client logic, item handlers, and initialization
]]

local QBX = exports.qbx_core
local playerLoaded = false
local inventoryReady = false

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     INITIALIZATION                               │
-- └──────────────────────────────────────────────────────────────────┘

---Check if ox_inventory is ready
local function IsInventoryReady()
    -- Multiple checks to ensure inventory is truly ready
    local state = LocalPlayer.state
    if not state then return false end
    
    -- Check if player has inventory loaded
    local success, result = pcall(function()
        return exports.ox_inventory:GetPlayerItems()
    end)
    
    return success and result ~= nil
end

---Wait for inventory to be ready with timeout
local function WaitForInventory(timeout)
    local waited = 0
    local checkInterval = 100
    timeout = timeout or 10000  -- Default 10 second timeout
    
    while not IsInventoryReady() and waited < timeout do
        Wait(checkInterval)
        waited = waited + checkInterval
    end
    
    if waited >= timeout then
        print("[OGz PropManager] Warning: Inventory ready timeout reached")
        return false
    end
    
    return true
end

---Request props from server on load
local function RequestProps()
    local bucket = Config.UseRoutingBucket and GetCurrentBucket() or 0
    TriggerServerEvent("ogz_propmanager:server:RequestProps", bucket)
end

-- Player loaded event
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    playerLoaded = true
    Wait(2000)  -- Give server time to fully register player
    RequestProps()
end)

-- Also handle if resource starts while player is already loaded
CreateThread(function()
    Wait(1000)
    local playerData = GetPlayerData()
    if playerData and playerData.citizenid then
        playerLoaded = true
        RequestProps()
    end
end)

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     ITEM USAGE HANDLERS                          │
-- └──────────────────────────────────────────────────────────────────┘

-- Build lookup table: item name -> station id
local itemToStation = {}
local itemHandlersRegistered = false

---Register item handlers with ox_inventory (called once inventory is ready)
local function RegisterItemHandlers()
    if itemHandlersRegistered then return end
    
    -- Build item lookup
    for stationId, stationConfig in pairs(Stations) do
        if stationConfig.item then
            itemToStation[stationConfig.item] = stationId
            DebugPrint("Mapped item:", stationConfig.item, "→", stationId)
        end
    end
    
    -- Register with ox_inventory export
    for itemName, stationId in pairs(itemToStation) do
        DebugPrint("Registering ox_inventory handler for:", itemName)
        
        local success, err = pcall(function()
            exports.ox_inventory:useItem(itemName, function(data, slot)
                DebugPrint("useItem triggered for:", itemName)
                UseStationItem(itemName)
            end)
        end)
        
        if not success then
            print(string.format("[OGz PropManager] Failed to register handler for %s: %s", itemName, tostring(err)))
        end
    end
    
    itemHandlersRegistered = true
    print("[OGz PropManager] Item handlers registered successfully")
end

-- Initialize item handlers when ready
CreateThread(function()
    -- Wait for player to be loaded first
    while not playerLoaded do
        Wait(100)
    end
    
    DebugPrint("Player loaded, waiting for inventory...")
    
    -- Wait for inventory to be ready
    if WaitForInventory(15000) then
        inventoryReady = true
        DebugPrint("Inventory ready, registering item handlers...")
        RegisterItemHandlers()
    else
        -- Fallback: try registering anyway after timeout
        print("[OGz PropManager] Inventory timeout - attempting handler registration anyway")
        RegisterItemHandlers()
    end
end)

-- Fallback: Listen to ox_inventory event (in case export doesn't work)
AddEventHandler('ox_inventory:usedItem', function(itemName, slotId, metadata)
    DebugPrint("ox_inventory:usedItem event:", itemName)
    if itemToStation[itemName] then
        UseStationItem(itemName)
    end
end)

-- Centralized item usage function
function UseStationItem(itemName)
    local stationId = itemToStation[itemName]
    if not stationId then 
        DebugPrint("No station found for item:", itemName)
        return 
    end
    
    DebugPrint("UseStationItem called:", itemName, "→", stationId)
    
    if IsPlacing() then
        Notify("Already placing a station!", "error")
        return
    end
    
    -- Check station limit on server (server will remove item if OK)
    TriggerServerEvent("ogz_propmanager:server:CheckStationLimit", stationId, itemName)
end

-- Server response to station limit check
RegisterNetEvent("ogz_propmanager:client:StartPlacement", function(stationId)
    DebugPrint("Starting placement for:", stationId)
    StartPlacement(stationId)
end)

RegisterNetEvent("ogz_propmanager:client:StationLimitReached", function(current, max)
    Notify(string.format(Config.Notifications.MaxStations, current, max), "error")
end)

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     BUCKET CHANGE HANDLER                        │
-- └──────────────────────────────────────────────────────────────────┘

-- Handle routing bucket changes (for apartment shells, etc.)
if Config.UseRoutingBucket then
    local lastBucket = 0
    
    CreateThread(function()
        while true do
            Wait(1000)
            
            if playerLoaded then
                local currentBucket = GetCurrentBucket()
                if currentBucket ~= lastBucket then
                    DebugPrint("Bucket changed from", lastBucket, "to", currentBucket)
                    lastBucket = currentBucket
                    RequestProps()
                end
            end
        end
    end)
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     NOTIFICATION HANDLERS                        │
-- └──────────────────────────────────────────────────────────────────┘

RegisterNetEvent("ogz_propmanager:client:Notify", function(message, type)
    Notify(message, type)
end)

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        DEBUG COMMANDS                            │
-- └──────────────────────────────────────────────────────────────────┘

-- Always available test commands
RegisterCommand("ogz_test", function(_, args)
    local stationId = args[1] or "weed_rosin_press"
    print("[OGz PropManager] Test placing:", stationId)
    StartPlacement(stationId)
end, false)

RegisterCommand("ogz_items", function()
    print("[OGz PropManager] Registered items:")
    for itemName, stationId in pairs(itemToStation) do
        print("  -", itemName, "→", stationId)
    end
    print("[OGz PropManager] Handlers registered:", itemHandlersRegistered)
    print("[OGz PropManager] Inventory ready:", inventoryReady)
end, false)

if Config.Debug then
    RegisterCommand("ogz_debug_props", function()
        local props = exports.ogz_propmanager:GetPlacedProps()
        local count = 0
        for _ in pairs(props) do count = count + 1 end
        print("[OGz PropManager] Currently tracking", count, "props")
        
        for id, info in pairs(props) do
            print("  - ID:", id, "Station:", info.data.station_id, "Entity:", info.entity)
        end
    end, false)
    
    RegisterCommand("ogz_test_place", function(_, args)
        local stationId = args[1] or "weed_rosin_press"
        StartPlacement(stationId)
    end, false)
    
    RegisterCommand("ogz_inv_status", function()
        print("[OGz PropManager] Player loaded:", playerLoaded)
        print("[OGz PropManager] Inventory ready:", inventoryReady)
        print("[OGz PropManager] Handlers registered:", itemHandlersRegistered)
        print("[OGz PropManager] IsInventoryReady():", IsInventoryReady())
    end, false)
end

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        KEYBIND CANCEL                            │
-- └──────────────────────────────────────────────────────────────────┘

-- Global cancel placement keybind (Escape key)
CreateThread(function()
    while true do
        Wait(0)
        
        if IsPlacing() then
            if IsControlJustPressed(0, 200) then  -- ESC key
                CancelPlacement()
            end
        else
            Wait(500)  -- Sleep when not placing
        end
    end
end)

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        EXPORTS                                   │
-- └──────────────────────────────────────────────────────────────────┘

exports("Notify", Notify)
exports("DebugPrint", DebugPrint)
exports("IsInventoryReady", IsInventoryReady)
