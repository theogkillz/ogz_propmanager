--[[
    OGz PropManager v3.3 - Client Lootables
    
    FEATURES:
    - Player-placed lootables (item-based)
    - Required item check before searching
    - Police alert display
    - Admin spawn menu with full options
    - Proper placement system integration
]]

if not Config.Features.Lootables then return end

local placedLootables = {}
local isSearching = false
local lootableHandlersRegistered = false

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetLootableConfig(lootType)
    return Lootables[lootType]
end

local function CanSeeLootable(lootableConfig)
    if not lootableConfig.visibleTo then return true end
    if lootableConfig.visibleTo.jobs and HasJob(lootableConfig.visibleTo.jobs) then return true end
    if lootableConfig.visibleTo.gangs and HasGang(lootableConfig.visibleTo.gangs) then return true end
    return false
end

local function FormatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm", math.floor(seconds / 60))
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

local function GetSetting(lootConfig, key, subkey)
    -- Use global helper if available
    if GetLootableSetting then
        return GetLootableSetting(lootConfig, key, subkey)
    end
    -- Fallback inline
    if subkey then
        if lootConfig[key] and lootConfig[key][subkey] ~= nil then
            return lootConfig[key][subkey]
        end
        return nil
    end
    return lootConfig[key]
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ITEM USAGE HANDLERS (Player-placed lootables)
-- ═══════════════════════════════════════════════════════════════════════════

local itemToLootable = {}

local function RegisterLootableItemHandlers()
    if lootableHandlersRegistered then return end
    
    -- Build item lookup for placeable lootables
    for lootType, lootConfig in pairs(Lootables) do
        if type(lootConfig) == "table" and lootConfig.item and not lootConfig.adminOnly then
            itemToLootable[lootConfig.item] = lootType
            DebugPrint("Lootable mapped:", lootConfig.item, "→", lootType)
        end
    end
    
    -- Register with ox_inventory
    for itemName, lootType in pairs(itemToLootable) do
        local success, err = pcall(function()
            exports.ox_inventory:useItem(itemName, function(data, slot)
                DebugPrint("Lootable useItem:", itemName)
                UseLootableItem(itemName)
            end)
        end)
        
        if not success then
            print(string.format("[OGz PropManager] Failed to register lootable handler for %s: %s", itemName, tostring(err)))
        end
    end
    
    lootableHandlersRegistered = true
    print("[OGz PropManager] Lootable item handlers registered successfully")
end

-- Initialize handlers when ready
CreateThread(function()
    while not GetPlayerData() or not GetPlayerData().citizenid do
        Wait(100)
    end
    
    Wait(2000)
    RegisterLootableItemHandlers()
end)

-- Fallback event handler
AddEventHandler('ox_inventory:usedItem', function(itemName, slotId, metadata)
    if itemToLootable[itemName] then
        UseLootableItem(itemName)
    end
end)

function UseLootableItem(itemName)
    local lootType = itemToLootable[itemName]
    if not lootType then return end
    
    if isSearching or IsPlacing() then
        Notify("Already busy!", "error")
        return
    end
    
    TriggerServerEvent("ogz_propmanager:server:CheckLootableLimit", lootType, itemName)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEMENT (Uses shared system)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:StartLootablePlacement", function(lootType)
    local lootConfig = GetLootableConfig(lootType)
    if not lootConfig then return end
    
    -- Use shared placement system
    StartLootablePlacement(lootType, nil, true)  -- true = player placed (returns item on cancel)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGET OPTIONS
-- ═══════════════════════════════════════════════════════════════════════════

function AddLootableTargetToEntity(entity, lootableData)
    local lootableConfig = GetLootableConfig(lootableData.loot_type)
    if not lootableConfig then return end
    
    local options = {}
    
    -- Search option
    options[#options + 1] = {
        name = "ogz_search_loot_" .. lootableData.id,
        icon = lootableConfig.icon or "fas fa-search",
        iconColor = lootableConfig.iconColor or "#ffffff",
        label = lootableConfig.label or "Search",
        distance = Config.InteractDistance,
        canInteract = function()
            if not CanSeeLootable(lootableConfig) then return false end
            
            -- Check if hidden and needs reveal
            if lootableConfig.hidden then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local propCoords = GetEntityCoords(entity)
                local dist = #(playerCoords - propCoords)
                if dist > (lootableConfig.revealDistance or 2.0) then
                    return false
                end
            end
            
            return not isSearching
        end,
        onSelect = function()
            SearchLootable(entity, lootableData)
        end,
    }
    
    exports.ox_target:addLocalEntity(entity, options)
end

function RemoveLootableTargetFromEntity(entity)
    if DoesEntityExist(entity) then
        exports.ox_target:removeLocalEntity(entity)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SEARCH FUNCTIONALITY
-- ═══════════════════════════════════════════════════════════════════════════

function SearchLootable(entity, lootableData)
    if isSearching then
        Notify("Already searching!", "error")
        return
    end
    
    local lootableConfig = GetLootableConfig(lootableData.loot_type)
    if not lootableConfig then return end
    
    -- Check required item first
    lib.callback('ogz_propmanager:server:CheckRequiredItem', false, function(hasItem, missingLabel)
        if not hasItem then
            Notify(string.format("You need a %s to search this!", missingLabel or "required item"), "error")
            return
        end
        
        -- Check cooldown
        lib.callback('ogz_propmanager:server:CheckLootCooldown', false, function(onCooldown, remaining, reason)
            if onCooldown then
                if reason == "global_cooldown" then
                    Notify(string.format("Someone searched this recently. Try again in %s", FormatTime(remaining)), "error")
                elseif reason == "player_cooldown" then
                    Notify(Config.Notifications.LootCooldown, "error")
                elseif reason == "Max searches reached" then
                    Notify("This has been fully searched", "error")
                elseif reason == "Already looted" then
                    Notify("This has already been searched", "error")
                else
                    Notify("Cannot search right now", "error")
                end
                return
            end
            
            -- Start search
            PerformSearch(entity, lootableData, lootableConfig)
        end, lootableData.id)
    end, lootableData.id)
end

function PerformSearch(entity, lootableData, lootableConfig)
    isSearching = true
    
    local playerPed = PlayerPedId()
    local propCoords = GetEntityCoords(entity)
    
    -- Face the prop
    TaskTurnPedToFaceCoord(playerPed, propCoords.x, propCoords.y, propCoords.z, 1000)
    Wait(500)
    
    -- Get animation config
    local animConfig = lootableConfig.searchAnim or Lootables.Defaults.searchAnim
    local searchDuration = animConfig and animConfig.duration or Config.Lootables.DefaultSearchTime or 5000
    
    -- Load animation
    local animDict = animConfig and animConfig.dict or "amb@prop_human_bum_bin@idle_a"
    local animName = animConfig and animConfig.anim or "idle_a"
    
    if not LoadAnimDict(animDict) then
        isSearching = false
        return
    end
    
    -- Play animation
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- Play sound
    if lootableConfig.searchSound and Sounds and Sounds[lootableConfig.searchSound] then
        PlaySound(lootableConfig.searchSound, propCoords)
    end
    
    -- Progress bar
    local success = lib.progressBar({
        duration = searchDuration,
        label = Config.Notifications.LootSearching or "Searching...",
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    })
    
    -- Cleanup animation
    ClearPedTasks(playerPed)
    RemoveAnimDict(animDict)
    
    if success then
        -- Tell server to roll loot
        TriggerServerEvent("ogz_propmanager:server:SearchLootable", lootableData.id)
    else
        Notify(Config.Notifications.Cancelled, "error")
    end
    
    isSearching = false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SOUND HELPER
-- ═══════════════════════════════════════════════════════════════════════════

function PlaySound(soundKey, coords)
    if not Sounds then return end
    local soundConfig = Sounds[soundKey]
    if not soundConfig then return end
    
    if soundConfig.type == "native" then
        PlaySoundFromCoord(-1, soundConfig.sound, coords.x, coords.y, coords.z, soundConfig.soundSet, false, soundConfig.range or 10.0, false)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOOT RESULT HANDLER
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:LootResult", function(propId, success, items)
    if success and #items > 0 then
        local itemNames = {}
        for _, loot in ipairs(items) do
            local label = GetItemLabel(loot.item)
            table.insert(itemNames, loot.count .. "x " .. label)
        end
        
        if Sounds and Sounds['loot_found'] then
            PlaySound('loot_found', GetEntityCoords(PlayerPedId()))
        end
        
        DebugPrint("Received loot:", table.concat(itemNames, ", "))
    else
        if Sounds and Sounds['loot_empty'] then
            PlaySound('loot_empty', GetEntityCoords(PlayerPedId()))
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- POLICE ALERT HANDLER
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:PoliceAlert", function(data)
    -- Show blip
    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, 161)  -- Skull icon
    SetBlipColour(blip, 1)    -- Red
    SetBlipScale(blip, 1.2)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.message or "Suspicious Activity")
    EndTextCommandSetBlipName(blip)
    
    -- Notification
    Notify("📡 " .. (data.message or "Suspicious activity reported"), "info")
    
    -- Remove blip after duration
    SetTimeout((data.duration or 60) * 1000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- PROP MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

local function SpawnLootable(lootableData)
    local lootableConfig = GetLootableConfig(lootableData.loot_type)
    if not lootableConfig then return nil end
    
    local modelName = lootableData.model
    local modelHash = type(modelName) == "string" and joaat(modelName) or modelName
    
    if not LoadModel(modelHash) then 
        DebugPrint("Failed to load model:", modelName)
        return nil 
    end
    
    local coords = lootableData.coords
    local heading = lootableData.heading or 0.0
    
    local entity = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
    
    if DoesEntityExist(entity) then
        SetEntityHeading(entity, heading)
        
        -- v3.3: Place on ground BEFORE freezing
        PlaceObjectOnGroundProperly(entity)
        
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, true, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        placedLootables[lootableData.id] = { entity = entity, data = lootableData }
        AddLootableTargetToEntity(entity, lootableData)
        
        DebugPrint("Spawned lootable:", lootableConfig.label, "ID:", lootableData.id)
        return entity
    end
    return nil
end

local function RemoveLootableLocal(propId)
    local lootInfo = placedLootables[propId]
    if lootInfo then
        RemoveLootableTargetFromEntity(lootInfo.entity)
        if DoesEntityExist(lootInfo.entity) then 
            DeleteEntity(lootInfo.entity) 
        end
        placedLootables[propId] = nil
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:LoadLootables", function(lootables)
    DebugPrint("Loading", #lootables, "lootables")
    for _, lootableData in ipairs(lootables) do 
        SpawnLootable(lootableData) 
    end
end)

RegisterNetEvent("ogz_propmanager:client:SpawnLootable", function(lootableData)
    SpawnLootable(lootableData)
end)

RegisterNetEvent("ogz_propmanager:client:RemoveLootable", function(propId)
    RemoveLootableLocal(propId)
end)

-- Request lootables on load
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(3000)
    local bucket = Config.UseRoutingBucket and GetCurrentBucket() or 0
    TriggerServerEvent("ogz_propmanager:server:RequestLootables", bucket)
end)

-- Handle resource restart
CreateThread(function()
    Wait(2500)
    local playerData = GetPlayerData()
    if playerData and playerData.citizenid then
        local bucket = Config.UseRoutingBucket and GetCurrentBucket() or 0
        TriggerServerEvent("ogz_propmanager:server:RequestLootables", bucket)
    end
end)

-- Bucket change handler
if Config.UseRoutingBucket then
    local lastBucket = 0
    
    CreateThread(function()
        Wait(3500)
        while true do
            Wait(1000)
            local currentBucket = GetCurrentBucket()
            if currentBucket ~= lastBucket then
                lastBucket = currentBucket
                for propId, lootInfo in pairs(placedLootables) do
                    RemoveLootableTargetFromEntity(lootInfo.entity)
                    if DoesEntityExist(lootInfo.entity) then 
                        DeleteEntity(lootInfo.entity) 
                    end
                end
                placedLootables = {}
                TriggerServerEvent("ogz_propmanager:server:RequestLootables", currentBucket)
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for propId, lootInfo in pairs(placedLootables) do
        RemoveLootableTargetFromEntity(lootInfo.entity)
        if DoesEntityExist(lootInfo.entity) then 
            DeleteEntity(lootInfo.entity) 
        end
    end
    placedLootables = {}
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

-- Simple placement (uses shared placement system)
RegisterCommand("ogz_spawn_lootable", function(_, args)
    local lootType = args[1] or "trash_can"
    local lootConfig = GetLootableConfig(lootType)
    
    if not lootConfig then
        print("[OGz PropManager] Unknown loot type:", lootType)
        print("Available types:")
        for id, cfg in pairs(Lootables) do
            if type(cfg) == "table" and cfg.label then
                print("  -", id, ":", cfg.label)
            end
        end
        return
    end
    
    StartLootablePlacement(lootType)
end, false)

-- Full admin menu with all options
RegisterCommand("ogz_admin_lootable", function()
    OpenAdminLootableMenu()
end, false)

function OpenAdminLootableMenu()
    -- Build lootable type options
    local typeOptions = {}
    for lootType, config in pairs(Lootables) do
        if type(config) == "table" and config.label then
            table.insert(typeOptions, { value = lootType, label = config.label })
        end
    end
    
    table.sort(typeOptions, function(a, b) return a.label < b.label end)
    
    local input = lib.inputDialog("🎁 Admin Spawn Lootable", {
        { type = "select", label = "Lootable Type", options = typeOptions, required = true },
        { type = "checkbox", label = "One-Time Loot (disappears after search)", default = false },
        { type = "number", label = "Auto-Despawn (minutes, 0 = never)", default = 0, min = 0, max = 1440 },
        { type = "number", label = "Max Searches (0 = unlimited)", default = 0, min = 0, max = 100 },
        { type = "number", label = "Loot Multiplier", default = 1.0, min = 0.1, max = 10.0, step = 0.1 },
        { type = "number", label = "Police Alert Chance (%)", default = 0, min = 0, max = 100 },
        { type = "checkbox", label = "Use Custom Loot?", default = false },
    })
    
    if not input then return end
    
    local lootType = input[1]
    local despawnOnSearch = input[2]
    local despawnTimer = input[3]
    local maxSearches = input[4]
    local lootMultiplier = input[5]
    local policeAlertChance = input[6]
    local useCustomLoot = input[7]
    
    local customLoot = nil
    if useCustomLoot then
        customLoot = GetCustomLootInput()
        if not customLoot then return end
    end
    
    -- Store options for placement callback
    local adminOptions = {
        lootType = lootType,
        despawnOnSearch = despawnOnSearch,
        despawnTimer = despawnTimer,
        maxSearches = maxSearches,
        customLoot = customLoot,
        overrides = {
            lootMultiplier = lootMultiplier,
            policeAlert = policeAlertChance > 0 and {
                enabled = true,
                chance = policeAlertChance,
                message = "Suspicious activity reported",
                blipDuration = 60,
            } or nil,
        },
    }
    
    -- Start placement with admin options
    StartAdminLootablePlacement(lootType, adminOptions)
end

function GetCustomLootInput()
    local items = {}
    
    while true do
        local input = lib.inputDialog("Add Custom Loot Item", {
            { type = "input", label = "Item Name", required = true, placeholder = "cash" },
            { type = "number", label = "Amount", default = 1, min = 1, max = 9999 },
            { type = "checkbox", label = "Add Another Item?", default = false },
        })
        
        if not input then
            if #items == 0 then return nil end
            break
        end
        
        table.insert(items, { item = input[1], count = input[2] })
        
        if not input[3] then break end
    end
    
    return items
end

function StartAdminLootablePlacement(lootType, adminOptions)
    local lootConfig = GetLootableConfig(lootType)
    if not lootConfig then return end
    
    -- Select placement mode
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
    
    if not choice then return end
    
    local model = lootConfig.models and lootConfig.models[1] or lootConfig.model
    local modelHash = type(model) == "string" and joaat(model) or model
    
    if not LoadModel(modelHash) then
        Notify("Failed to load model", "error")
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local playerHeading = GetEntityHeading(PlayerPedId())
    local forward = GetEntityForwardVector(PlayerPedId())
    local spawnCoords = playerCoords + (forward * 2.0)
    
    local tempProp = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    SetEntityHeading(tempProp, playerHeading)
    SetEntityAlpha(tempProp, Config.Placement.GhostAlpha, false)
    SetEntityCollision(tempProp, false, false)
    FreezeEntityPosition(tempProp, true)
    PlaceObjectOnGroundProperly(tempProp)
    
    local finalCoords, finalHeading
    
    if choice[1] == "gizmo" then
        local result = exports.object_gizmo:useGizmo(tempProp)
        if result and DoesEntityExist(tempProp) then
            finalCoords = GetEntityCoords(tempProp)
            finalHeading = GetEntityHeading(tempProp)
        end
    else
        -- Raycast mode
        ShowTextUI("[ENTER] Place | [BACKSPACE] Cancel | [SCROLL] Rotate | [↑↓] Height | [ALT] Snap", "fas fa-arrows-alt")
        
        local currentHeading = 0.0
        local currentHeight = 0.0
        local placing = true
        
        while placing do
            Wait(0)
            
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local direction = RotationToDirection(camRot)
            local endCoords = camCoords + (direction * Config.Placement.CastDistance)
            
            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 1 + 16, PlayerPedId(), 0)
            local _, hit, hitCoords = GetShapeTestResult(rayHandle)
            
            if hit then
                SetEntityCoords(tempProp, hitCoords.x, hitCoords.y, hitCoords.z + currentHeight)
                SetEntityHeading(tempProp, currentHeading)
            end
            
            local keys = Config.Placement.Keys
            if IsControlPressed(0, keys.rotateLeft) then currentHeading = currentHeading - 2.0 end
            if IsControlPressed(0, keys.rotateRight) then currentHeading = currentHeading + 2.0 end
            if IsControlPressed(0, keys.heightUp) then currentHeight = currentHeight + Config.Placement.MoveSpeed end
            if IsControlPressed(0, keys.heightDown) then currentHeight = currentHeight - Config.Placement.MoveSpeed end
            
            if IsControlJustPressed(0, keys.snapGround) then
                currentHeight = 0.0
                PlaceObjectOnGroundProperly(tempProp)
                Notify("Snapped to ground!", "success")
            end
            
            if IsControlJustPressed(0, keys.place) then
                finalCoords = GetEntityCoords(tempProp)
                finalHeading = GetEntityHeading(tempProp)
                placing = false
            end
            
            if IsControlJustPressed(0, keys.cancel) then
                placing = false
            end
        end
        
        HideTextUI()
    end
    
    DeleteEntity(tempProp)
    SetModelAsNoLongerNeeded(modelHash)
    
    if finalCoords then
        local bucket = Config.UseRoutingBucket and GetCurrentBucket() or 0
        
        TriggerServerEvent("ogz_propmanager:server:SpawnLootable", {
            lootType = lootType,
            model = model,
            coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
            heading = finalHeading,
            bucket = bucket,
            despawnOnSearch = adminOptions.despawnOnSearch,
            despawnTimer = adminOptions.despawnTimer,
            maxSearches = adminOptions.maxSearches,
            customLoot = adminOptions.customLoot,
            overrides = adminOptions.overrides,
        })
    else
        Notify(Config.Notifications.Cancelled, "info")
    end
end

RegisterCommand("ogz_list_lootables", function()
    print("[OGz PropManager] Registered loot types:")
    for id, config in pairs(Lootables) do
        if type(config) == "table" and config.label then
            local playerPlaced = config.item and "✓" or "✗"
            print(string.format("  - %s: %s (Player-placeable: %s)", id, config.label, playerPlaced))
        end
    end
    
    print("\nPlaced lootables in current area:")
    local count = 0
    for propId, info in pairs(placedLootables) do
        print("  - ID:", propId, "Type:", info.data.loot_type)
        count = count + 1
    end
    if count == 0 then print("  (none)") end
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports("GetPlacedLootables", function() return placedLootables end)
exports("IsSearching", function() return isSearching end)
