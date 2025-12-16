--[[
    OGz PropManager v3.0 - Client World Props
    
    Location-based world prop interactions. Uses ox_lib zones for performance-optimized
    targeting at specific configured locations only.
]]

if not Config.Features.WorldProps then return end

local activeZones = {}
local registeredZones = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetWorldPropConfig(propId)
    return WorldProps[propId]
end

local function CanSeeWorldProp(worldPropConfig)
    if not worldPropConfig.visibleTo then return true end
    if worldPropConfig.visibleTo.jobs and HasJob(worldPropConfig.visibleTo.jobs) then return true end
    if worldPropConfig.visibleTo.gangs and HasGang(worldPropConfig.visibleTo.gangs) then return true end
    return false
end

local function GetLocationHash(coords)
    local x = math.floor(coords.x * 100) / 100
    local y = math.floor(coords.y * 100) / 100
    local z = math.floor(coords.z * 100) / 100
    return string.format("%.2f_%.2f_%.2f", x, y, z)
end

local function FormatTime(seconds)
    if seconds < 60 then return string.format("%ds", seconds)
    elseif seconds < 3600 then return string.format("%dm", math.floor(seconds / 60))
    else return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ZONE REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

function RegisterWorldPropZones()
    -- Clear existing zones
    for zoneName, _ in pairs(registeredZones) do
        exports.ox_target:removeZone(zoneName)
    end
    registeredZones = {}
    
    -- Register zones for each world prop location
    for worldpropId, config in pairs(WorldProps) do
        if config.locations then
            for i, location in ipairs(config.locations) do
                local coords, radius
                
                if type(location) == "vector4" then
                    coords = vec3(location.x, location.y, location.z)
                    radius = location.w
                elseif type(location) == "vector3" then
                    coords = location
                    radius = Config.WorldPropsSettings.DetectionRadius or 2.0
                else
                    goto continue
                end
                
                local zoneName = string.format("ogz_worldprop_%s_%d", worldpropId, i)
                local locationHash = GetLocationHash(coords)
                
                -- Build target options based on type
                local options = BuildWorldPropOptions(worldpropId, config, locationHash)
                
                if #options > 0 then
                    exports.ox_target:addSphereZone({
                        coords = coords,
                        radius = radius,
                        name = zoneName,
                        debug = Config.Debug,
                        options = options,
                    })
                    
                    registeredZones[zoneName] = {
                        worldpropId = worldpropId,
                        coords = coords,
                        locationHash = locationHash,
                    }
                    
                    DebugPrint("Registered zone:", zoneName, "at", coords)
                end
                
                ::continue::
            end
        end
    end
    
    DebugPrint("Registered", TableCount(registeredZones), "world prop zones")
end

function TableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ═══════════════════════════════════════════════════════════════════════════
-- BUILD TARGET OPTIONS
-- ═══════════════════════════════════════════════════════════════════════════

function BuildWorldPropOptions(worldpropId, config, locationHash)
    local options = {}
    
    if config.type == "shop" then
        options = BuildShopOptions(worldpropId, config, locationHash)
    elseif config.type == "stash" then
        options = BuildStashOptions(worldpropId, config, locationHash)
    elseif config.type == "crafting" then
        options = BuildCraftingOptions(worldpropId, config, locationHash)
    elseif config.type == "reward" then
        options = BuildRewardOptions(worldpropId, config, locationHash)
    end
    
    return options
end

-- SHOP OPTIONS
function BuildShopOptions(worldpropId, config, locationHash)
    local options = {}
    
    options[#options + 1] = {
        name = "ogz_shop_" .. worldpropId,
        icon = config.icon or "fas fa-store",
        iconColor = config.iconColor or "#00ff00",
        label = config.label or "Shop",
        distance = 2.5,
        canInteract = function()
            return CanSeeWorldProp(config)
        end,
        onSelect = function()
            OpenWorldPropShop(worldpropId, config, locationHash)
        end,
    }
    
    return options
end

-- STASH OPTIONS
function BuildStashOptions(worldpropId, config, locationHash)
    local options = {}
    
    options[#options + 1] = {
        name = "ogz_stash_" .. worldpropId,
        icon = config.icon or "fas fa-box",
        iconColor = config.iconColor or "#ffaa00",
        label = config.label or "Open Stash",
        distance = 2.5,
        canInteract = function()
            return CanSeeWorldProp(config)
        end,
        onSelect = function()
            TriggerServerEvent("ogz_propmanager:server:WorldPropStash", worldpropId, locationHash)
        end,
    }
    
    return options
end

-- CRAFTING OPTIONS
function BuildCraftingOptions(worldpropId, config, locationHash)
    local options = {}
    
    if config.craftingTables then
        for _, tableConfig in ipairs(config.craftingTables) do
            options[#options + 1] = {
                name = "ogz_craft_" .. worldpropId .. "_" .. tableConfig.name,
                icon = config.icon or "fas fa-tools",
                iconColor = config.iconColor or "#ff6600",
                label = tableConfig.label or tableConfig.name,
                distance = 2.5,
                canInteract = function()
                    return CanSeeWorldProp(config)
                end,
                onSelect = function()
                    TriggerServerEvent("ogz_propmanager:server:WorldPropCrafting", worldpropId, locationHash, tableConfig.name)
                end,
            }
        end
    end
    
    return options
end

-- REWARD OPTIONS
function BuildRewardOptions(worldpropId, config, locationHash)
    local options = {}
    
    options[#options + 1] = {
        name = "ogz_reward_" .. worldpropId,
        icon = config.icon or "fas fa-search",
        iconColor = config.iconColor or "#9933ff",
        label = config.label or "Search",
        distance = 2.5,
        canInteract = function()
            return CanSeeWorldProp(config)
        end,
        onSelect = function()
            SearchWorldProp(worldpropId, config, locationHash)
        end,
    }
    
    return options
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SHOP MENU
-- ═══════════════════════════════════════════════════════════════════════════

function OpenWorldPropShop(worldpropId, config, locationHash)
    if not config.shop or not config.shop.items then return end
    
    local menuOptions = {}
    
    for _, item in ipairs(config.shop.items) do
        local itemLabel = item.label or GetItemLabel(item.item)
        
        menuOptions[#menuOptions + 1] = {
            title = itemLabel,
            description = string.format("$%d", item.price),
            icon = "fas fa-dollar-sign",
            iconColor = "#00ff00",
            onSelect = function()
                -- Play animation if configured
                if config.useAnim then
                    local animDict = config.useAnim.dict
                    local animName = config.useAnim.anim
                    local duration = config.useAnim.duration or 2000
                    
                    if LoadAnimDict(animDict) then
                        local ped = PlayerPedId()
                        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, duration, 49, 0, false, false, false)
                        Wait(duration)
                        ClearPedTasks(ped)
                    end
                end
                
                TriggerServerEvent("ogz_propmanager:server:WorldPropShop", worldpropId, locationHash, item.item)
            end,
        }
    end
    
    lib.registerContext({
        id = "ogz_worldprop_shop_" .. worldpropId,
        title = config.label or "Shop",
        options = menuOptions,
    })
    lib.showContext("ogz_worldprop_shop_" .. worldpropId)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REWARD SEARCH
-- ═══════════════════════════════════════════════════════════════════════════

function SearchWorldProp(worldpropId, config, locationHash)
    -- Check cooldown first
    lib.callback('ogz_propmanager:server:CheckWorldPropCooldown', false, function(onCooldown, remaining)
        if onCooldown then
            Notify(string.format(Config.Notifications.WorldPropCooldown, FormatTime(remaining)), "error")
            return
        end
        
        -- Play animation
        local ped = PlayerPedId()
        local animDict = config.useAnim and config.useAnim.dict or "amb@prop_human_bum_bin@idle_a"
        local animName = config.useAnim and config.useAnim.anim or "idle_a"
        local duration = config.useAnim and config.useAnim.duration or 3000
        
        if LoadAnimDict(animDict) then
            TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
            
            local success = lib.progressBar({
                duration = duration,
                label = "Searching...",
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true },
            })
            
            ClearPedTasks(ped)
            
            if success then
                TriggerServerEvent("ogz_propmanager:server:WorldPropReward", worldpropId, locationHash)
            else
                Notify(Config.Notifications.Cancelled, "error")
            end
        end
    end, worldpropId, locationHash)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

-- Register zones on player load
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(3500)
    RegisterWorldPropZones()
end)

-- Also handle resource restart
CreateThread(function()
    Wait(3000)
    local playerData = GetPlayerData()
    if playerData and playerData.citizenid then
        RegisterWorldPropZones()
    end
end)

-- Re-register on job/gang change (visibility might change)
RegisterNetEvent("QBCore:Client:OnJobUpdate", function()
    RegisterWorldPropZones()
end)

RegisterNetEvent("QBCore:Client:OnGangUpdate", function()
    RegisterWorldPropZones()
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for zoneName, _ in pairs(registeredZones) do
        exports.ox_target:removeZone(zoneName)
    end
    registeredZones = {}
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("ogz_worldprop_zones", function()
    print("[OGz PropManager] Registered world prop zones:")
    for zoneName, info in pairs(registeredZones) do
        print("  -", zoneName, ":", info.worldpropId, "at", info.coords)
    end
    print("Total:", TableCount(registeredZones))
end, false)

RegisterCommand("ogz_worldprop_reload", function()
    RegisterWorldPropZones()
    Notify("World prop zones reloaded", "success")
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports("GetRegisteredWorldPropZones", function() return registeredZones end)
exports("ReloadWorldPropZones", RegisterWorldPropZones)
