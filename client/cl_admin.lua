--[[
    OGz PropManager - Admin Menu (Client)
    
    Provides admin interface for managing stations, stashes, lootables,
    world props, furniture, and world builder tools.
]]

local isAdmin = false

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN CHECK
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:SetAdmin", function(admin)
    isAdmin = admin
end)

function IsAdmin()
    return isAdmin
end

-- ═══════════════════════════════════════════════════════════════════════════
-- FORWARD DECLARATIONS
-- ═══════════════════════════════════════════════════════════════════════════

local OpenStationManagementMenu
local OpenPropSystemsMenu

-- ═══════════════════════════════════════════════════════════════════════════
-- MAIN ADMIN MENU
-- ═══════════════════════════════════════════════════════════════════════════

local function OpenAdminMenu()
    if not isAdmin then
        Notify("You don't have admin permissions.", "error")
        return
    end
    
    lib.registerContext({
        id = "ogz_admin_main",
        title = "🔧 OGz PropManager Admin",
        options = {
            { 
                title = "🏭 Station Management", 
                description = "Stations, logs, stats, and item tools", 
                icon = "fas fa-industry", 
                iconColor = "#3498db",
                onSelect = function() OpenStationManagementMenu() end
            },
            { 
                title = "📦 Prop Systems", 
                description = "Stashes, lootables, world props, furniture", 
                icon = "fas fa-cubes", 
                iconColor = "#9b59b6",
                onSelect = function() OpenPropSystemsMenu() end
            },
            { 
                title = "🏗️ World Builder", 
                description = "Spawn, delete, and manage world props", 
                icon = "fas fa-hammer", 
                iconColor = "#00ff88", 
                onSelect = function() OpenWorldBuilderAdminMenu() end
            },
        }
    })
    lib.showContext("ogz_admin_main")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION MANAGEMENT SUBMENU
-- ═══════════════════════════════════════════════════════════════════════════

OpenStationManagementMenu = function()
    lib.registerContext({
        id = "ogz_admin_stations",
        title = "🏭 Station Management",
        menu = "ogz_admin_main",
        options = {
            { title = "📊 Station Overview", description = "View all placed stations", icon = "fas fa-chart-bar", onSelect = function() OpenStationOverview() end },
            { title = "🔍 Search Stations", description = "Find stations by owner/type", icon = "fas fa-search", onSelect = function() OpenSearchMenu() end },
            { title = "📜 View Logs", description = "View production & activity logs", icon = "fas fa-scroll", onSelect = function() OpenLogsMenu() end },
            { title = "📈 Statistics", description = "View server-wide stats", icon = "fas fa-chart-line", onSelect = function() OpenStatsMenu() end },
            { title = "🎁 Give Items", description = "Give station items to players", icon = "fas fa-gift", onSelect = function() OpenGiveItemsMenu() end },
            { title = "🧪 Give with Purity", description = "Give items with metadata for testing", icon = "fas fa-flask", iconColor = "#9b59b6", onSelect = function() OpenQuickGiveMenu() end },
            { title = "⚙️ Quick Actions", description = "Repair all, clear cooldowns, etc.", icon = "fas fa-cogs", onSelect = function() OpenQuickActionsMenu() end },
        }
    })
    lib.showContext("ogz_admin_stations")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROP SYSTEMS SUBMENU
-- ═══════════════════════════════════════════════════════════════════════════

OpenPropSystemsMenu = function()
    lib.registerContext({
        id = "ogz_admin_propsystems",
        title = "📦 Prop Systems",
        menu = "ogz_admin_main",
        options = {
            { title = "📦 Stash Manager", description = "View and manage placed stashes", icon = "fas fa-box", iconColor = "#ffaa00", onSelect = function() OpenStashAdminMenu() end },
            { title = "🎰 Lootable Manager", description = "Spawn and manage loot props", icon = "fas fa-dice", iconColor = "#9933ff", onSelect = function() OpenLootableAdminMenu() end },
            { title = "🌍 World Props", description = "View configured world prop locations", icon = "fas fa-globe", iconColor = "#00aaff", onSelect = function() OpenWorldPropsAdminMenu() end },
            { title = "🪑 Furniture Tools", description = "Reset moved furniture", icon = "fas fa-chair", iconColor = "#ff6600", onSelect = function() OpenFurnitureAdminMenu() end },
        }
    })
    lib.showContext("ogz_admin_propsystems")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- WORLD BUILDER ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

function OpenWorldBuilderAdminMenu()
    lib.registerContext({
        id = "ogz_admin_worldbuilder",
        title = "🏗️ World Builder",
        menu = "ogz_admin_main",
        options = {
            {
                title = "📦 Spawn Prop",
                description = "Place a new prop in the world",
                icon = "fas fa-plus-circle",
                iconColor = "#00ff00",
                onSelect = function()
                    if OpenSpawnMenu then
                        OpenSpawnMenu()
                    else
                        local input = lib.inputDialog("Spawn World Prop", {
                            { type = "input", label = "Model Name/Hash", placeholder = "prop_barrel_01a", required = true },
                        })
                        if input and input[1] then
                            if StartWorldPropPlacement then
                                StartWorldPropPlacement(input[1])
                            else
                                ExecuteCommand("wb_spawn " .. input[1])
                            end
                        end
                    end
                end,
            },
            {
                title = "🎯 Delete Mode",
                description = "RED laser - Target and delete/hide props",
                icon = "fas fa-crosshairs",
                iconColor = "#ff4444",
                onSelect = function()
                    if EnterDeleteMode then
                        EnterDeleteMode()
                    else
                        ExecuteCommand("wb_delete")
                    end
                    Notify("Delete Mode: E=Delete | C=Copy Hash | BACKSPACE=Exit", "info")
                end,
            },
            {
                title = "🔍 Hash Mode",
                description = "GREEN laser - Copy prop hashes and configs",
                icon = "fas fa-hashtag",
                iconColor = "#44ff44",
                onSelect = function()
                    if EnterHashMode then
                        EnterHashMode()
                    else
                        ExecuteCommand("wb_hash")
                    end
                    Notify("Hash Mode: E=Copy Hash | C=Copy Config | BACKSPACE=Exit", "info")
                end,
            },
            {
                title = "📋 List Spawned Props",
                description = "View spawned props nearby",
                icon = "fas fa-list",
                onSelect = OpenWBSpawnedPropsMenu,
            },
            {
                title = "👁️ View Hidden Props",
                description = "See all hidden native props",
                icon = "fas fa-eye-slash",
                onSelect = OpenWBHiddenPropsMenu,
            },
            {
                title = "🧹 Clear Props",
                description = "Bulk delete spawned props by radius",
                icon = "fas fa-broom",
                iconColor = "#ff6600",
                onSelect = OpenWBClearPropsMenu,
            },
            {
                title = "🔄 Reload Props",
                description = "Reload all props from database",
                icon = "fas fa-sync-alt",
                onSelect = function()
                    ExecuteCommand("wb_reload")
                end,
            },
            {
                title = "🔧 Debug Info",
                description = "View system status and debug info",
                icon = "fas fa-bug",
                onSelect = OpenWBDebugMenu,
            },
        },
    })
    lib.showContext("ogz_admin_worldbuilder")
end

function OpenWBSpawnedPropsMenu()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearby = {}
    
    local spawnedProps = {}
    if exports.ogz_propmanager and exports.ogz_propmanager.GetSpawnedProps then
        spawnedProps = exports.ogz_propmanager:GetSpawnedProps() or {}
    end
    
    for dbId, data in pairs(spawnedProps) do
        if data.entity and DoesEntityExist(data.entity) then
            local dist = #(playerCoords - GetEntityCoords(data.entity))
            if dist < 100.0 then
                nearby[#nearby + 1] = {
                    title = string.format("ID: %d | %s", dbId, data.model or "Unknown"),
                    description = string.format("Distance: %.1fm | Click to teleport", dist),
                    icon = "fas fa-cube",
                    onSelect = function()
                        local propCoords = GetEntityCoords(data.entity)
                        SetEntityCoords(PlayerPedId(), propCoords.x, propCoords.y, propCoords.z + 1.0, false, false, false, false)
                        Notify("Teleported to prop", "info")
                    end,
                    _dist = dist,
                }
            end
        end
    end
    
    if #nearby == 0 then
        Notify("No spawned props within 100m", "info")
        return
    end
    
    table.sort(nearby, function(a, b) return (a._dist or 9999) < (b._dist or 9999) end)
    for _, item in ipairs(nearby) do item._dist = nil end
    
    lib.registerContext({
        id = "ogz_admin_wb_spawned",
        title = string.format("📋 Spawned Props Nearby (%d)", #nearby),
        menu = "ogz_admin_worldbuilder",
        options = nearby,
    })
    lib.showContext("ogz_admin_wb_spawned")
end

function OpenWBHiddenPropsMenu()
    lib.callback("ogz_propmanager:server:GetDeletedProps", false, function(deletedProps)
        if not deletedProps or #deletedProps == 0 then
            Notify("No hidden props in database", "info")
            return
        end
        
        local options = {}
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, deleteData in ipairs(deletedProps) do
            local coords = deleteData.coords
            if type(coords) == "string" then
                coords = json.decode(coords)
            end
            
            local dist = 9999
            if coords and coords.x then
                dist = #(playerCoords - vector3(coords.x, coords.y, coords.z))
            end
            
            options[#options + 1] = {
                title = string.format("ID: %d | Model: %s", deleteData.id, deleteData.model),
                description = string.format("Distance: %.0fm | Click to teleport", dist),
                icon = "fas fa-eye-slash",
                onSelect = function()
                    if coords and coords.x then
                        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, false)
                        Notify("Teleported to hidden prop location", "info")
                    end
                end,
                _dist = dist,
            }
        end
        
        table.sort(options, function(a, b) return (a._dist or 9999) < (b._dist or 9999) end)
        for _, item in ipairs(options) do item._dist = nil end
        
        lib.registerContext({
            id = "ogz_admin_wb_hidden",
            title = string.format("👁️ Hidden Props (%d total)", #deletedProps),
            menu = "ogz_admin_worldbuilder",
            options = options,
        })
        lib.showContext("ogz_admin_wb_hidden")
    end)
end

function OpenWBClearPropsMenu()
    lib.registerContext({
        id = "ogz_admin_wb_clear",
        title = "🧹 Clear Props",
        menu = "ogz_admin_worldbuilder",
        options = {
            {
                title = "🗑️ Clear Spawned (10m)",
                description = "Delete spawned props within 10 meters",
                icon = "fas fa-trash",
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = "Clear Spawned Props",
                        content = "Delete all spawned props within 10m?",
                        centered = true,
                        cancel = true,
                    })
                    if confirm == "confirm" then
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent("ogz_propmanager:server:WorldBuilderClear", playerCoords, 10.0)
                    end
                end,
            },
            {
                title = "🗑️ Clear Spawned (25m)",
                description = "Delete spawned props within 25 meters",
                icon = "fas fa-trash",
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = "Clear Spawned Props",
                        content = "Delete all spawned props within 25m?",
                        centered = true,
                        cancel = true,
                    })
                    if confirm == "confirm" then
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent("ogz_propmanager:server:WorldBuilderClear", playerCoords, 25.0)
                    end
                end,
            },
            {
                title = "🗑️ Clear Spawned (50m)",
                description = "Delete spawned props within 50 meters",
                icon = "fas fa-trash",
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = "Clear Spawned Props",
                        content = "Delete all spawned props within 50m?",
                        centered = true,
                        cancel = true,
                    })
                    if confirm == "confirm" then
                        local playerCoords = GetEntityCoords(PlayerPedId())
                        TriggerServerEvent("ogz_propmanager:server:WorldBuilderClear", playerCoords, 50.0)
                    end
                end,
            },
            {
                title = "⚠️ Custom Radius",
                description = "Enter custom radius",
                icon = "fas fa-ruler",
                onSelect = function()
                    local input = lib.inputDialog("Custom Clear Radius", {
                        { type = "number", label = "Radius (meters)", default = 10, min = 1, max = 500 },
                    })
                    if input and input[1] then
                        local confirm = lib.alertDialog({
                            header = "Clear Spawned Props",
                            content = string.format("Delete all spawned props within %.0fm?", input[1]),
                            centered = true,
                            cancel = true,
                        })
                        if confirm == "confirm" then
                            local playerCoords = GetEntityCoords(PlayerPedId())
                            TriggerServerEvent("ogz_propmanager:server:WorldBuilderClear", playerCoords, input[1])
                        end
                    end
                end,
            },
        },
    })
    lib.showContext("ogz_admin_wb_clear")
end

function OpenWBDebugMenu()
    local spawnedCount = 0
    local spawnedProps = {}
    
    if exports.ogz_propmanager and exports.ogz_propmanager.GetSpawnedProps then
        spawnedProps = exports.ogz_propmanager:GetSpawnedProps() or {}
        for _ in pairs(spawnedProps) do spawnedCount = spawnedCount + 1 end
    end
    
    lib.registerContext({
        id = "ogz_admin_wb_debug",
        title = "🔧 World Builder Debug",
        menu = "ogz_admin_worldbuilder",
        options = {
            {
                title = string.format("📦 Spawned Props: %d", spawnedCount),
                description = "Props placed by World Builder",
                icon = "fas fa-cube",
                disabled = true,
            },
            {
                title = "📊 Print to Console",
                description = "Print detailed debug info to F8",
                icon = "fas fa-terminal",
                onSelect = function()
                    print("═══════════════════════════════════════════════════════════════")
                    print("[World Builder Debug]")
                    print("═══════════════════════════════════════════════════════════════")
                    print("Spawned Props:", spawnedCount)
                    for dbId, data in pairs(spawnedProps) do
                        print(string.format("  ID: %d | Model: %s | Entity: %s", 
                            dbId, data.model or "?", tostring(data.entity)))
                    end
                    print("═══════════════════════════════════════════════════════════════")
                    Notify("Debug info printed to F8 console", "info")
                end,
            },
            {
                title = "🔄 Force Reload",
                description = "Force reload all world builder data",
                icon = "fas fa-sync",
                onSelect = function()
                    TriggerServerEvent("ogz_propmanager:server:WorldBuilderReload")
                    Notify("Reloading world builder data...", "info")
                end,
            },
        },
    })
    lib.showContext("ogz_admin_wb_debug")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- REST OF EXISTING ADMIN CODE (Unchanged from v3.3)
-- ═══════════════════════════════════════════════════════════════════════════

function OpenStationOverview()
    lib.callback("ogz_propmanager:admin:GetAllStations", false, function(stations)
        if not stations or #stations == 0 then
            Notify("No stations found.", "info")
            return
        end
        
        local options = {}
        for _, station in ipairs(stations) do
            local stationConfig = GetStationConfig(station.station_id)
            local durabilityColor = station.durability > 74 and "#00ff00" or (station.durability > 24 and "#ffff00" or "#ff0000")
            
            options[#options + 1] = {
                title = (stationConfig and stationConfig.label or station.station_id),
                description = string.format("Owner: %s | Durability: %s%% | ID: %s", station.citizenid, station.durability, station.id),
                icon = stationConfig and stationConfig.icon or "fas fa-cube",
                iconColor = durabilityColor,
                onSelect = function()
                    OpenStationActions(station)
                end,
            }
        end
        
        lib.registerContext({ id = "ogz_admin_stations", title = "📊 All Stations (" .. #stations .. ")", menu = "ogz_admin_main", options = options })
        lib.showContext("ogz_admin_stations")
    end)
end

function OpenStationActions(station)
    local stationConfig = GetStationConfig(station.station_id)
    
    lib.registerContext({
        id = "ogz_admin_station_actions",
        title = "🔧 " .. (stationConfig and stationConfig.label or station.station_id),
        menu = "ogz_admin_stations",
        options = {
            { title = "📍 Teleport Here", icon = "fas fa-location-arrow", onSelect = function() TeleportToStation(station) end },
            { title = "🔧 Set Durability", icon = "fas fa-wrench", onSelect = function() SetStationDurability(station) end },
            { title = "⏱️ Clear Cooldown", icon = "fas fa-clock", onSelect = function() ClearStationCooldown(station) end },
            { title = "🗑️ Remove Station", icon = "fas fa-trash", iconColor = "#ff4444", onSelect = function() AdminRemoveStation(station) end },
            { title = "📜 View Station Logs", icon = "fas fa-scroll", onSelect = function() ViewStationLogs(station) end },
        }
    })
    lib.showContext("ogz_admin_station_actions")
end

function TeleportToStation(station)
    SetEntityCoords(PlayerPedId(), station.coords.x, station.coords.y, station.coords.z, false, false, false, false)
    Notify("Teleported to station #" .. station.id, "success")
end

function SetStationDurability(station)
    local input = lib.inputDialog("Set Durability", {
        { type = "number", label = "Durability (0-100)", default = station.durability, min = 0, max = 100 }
    })
    if input then
        TriggerServerEvent("ogz_propmanager:admin:SetDurability", station.id, input[1])
    end
end

function ClearStationCooldown(station)
    TriggerServerEvent("ogz_propmanager:admin:ClearCooldown", station.id)
end

function AdminRemoveStation(station)
    local confirm = lib.alertDialog({
        header = "Remove Station",
        content = "Are you sure you want to remove this station?\n\nOwner: " .. station.citizenid .. "\nID: " .. station.id,
        centered = true,
        cancel = true,
    })
    if confirm == "confirm" then
        TriggerServerEvent("ogz_propmanager:admin:RemoveStation", station.id)
    end
end

function ViewStationLogs(station)
    lib.callback("ogz_propmanager:admin:GetStationLogs", false, function(logs)
        if not logs or #logs == 0 then
            Notify("No logs found for this station.", "info")
            return
        end
        
        local options = {}
        for _, log in ipairs(logs) do
            options[#options + 1] = {
                title = log.action:upper(),
                description = string.format("%s | %s | %s", log.citizenid, log.item_crafted or "N/A", log.created_at),
                icon = log.action == "craft" and "fas fa-hammer" or "fas fa-info-circle",
            }
        end
        
        lib.registerContext({ id = "ogz_admin_station_logs", title = "📜 Station Logs", menu = "ogz_admin_station_actions", options = options })
        lib.showContext("ogz_admin_station_logs")
    end, station.id)
end

function OpenSearchMenu()
    local input = lib.inputDialog("Search Stations", {
        { type = "input", label = "Citizen ID (leave empty for all)", placeholder = "ABC12345" },
        { type = "select", label = "Station Type", options = GetStationTypeOptions(), clearable = true },
    })
    
    if input then
        lib.callback("ogz_propmanager:admin:SearchStations", false, function(stations)
            if not stations or #stations == 0 then
                Notify("No stations found matching criteria.", "info")
                return
            end
            
            local options = {}
            for _, station in ipairs(stations) do
                local stationConfig = GetStationConfig(station.station_id)
                options[#options + 1] = {
                    title = (stationConfig and stationConfig.label or station.station_id),
                    description = string.format("Owner: %s | ID: %s", station.citizenid, station.id),
                    icon = stationConfig and stationConfig.icon or "fas fa-cube",
                    onSelect = function() OpenStationActions(station) end,
                }
            end
            
            lib.registerContext({ id = "ogz_admin_search_results", title = "🔍 Search Results (" .. #stations .. ")", menu = "ogz_admin_main", options = options })
            lib.showContext("ogz_admin_search_results")
        end, input[1], input[2])
    end
end

function GetStationTypeOptions()
    local options = {}
    for stationId, stationData in pairs(Stations) do
        options[#options + 1] = { value = stationId, label = stationData.label }
    end
    return options
end

function OpenLogsMenu()
    lib.registerContext({
        id = "ogz_admin_logs",
        title = "📜 Logs Menu",
        menu = "ogz_admin_main",
        options = {
            { title = "📝 Recent Activity", description = "Last 50 actions", icon = "fas fa-list", onSelect = function() ViewRecentLogs(50) end },
            { title = "🔨 Recent Crafts", description = "Last 50 crafts", icon = "fas fa-hammer", onSelect = function() ViewLogsByType("craft", 50) end },
            { title = "📦 Recent Placements", description = "Last 50 placements", icon = "fas fa-plus", onSelect = function() ViewLogsByType("place", 50) end },
            { title = "🗑️ Recent Removals", description = "Last 50 removals", icon = "fas fa-minus", onSelect = function() ViewLogsByType("remove", 50) end },
            { title = "🎲 Recent Events", description = "Last 50 random events", icon = "fas fa-dice", onSelect = function() ViewLogsByType("event", 50) end },
            { title = "🧹 Clear Old Logs", description = "Remove logs older than X days", icon = "fas fa-broom", iconColor = "#ff4444", onSelect = ClearOldLogsPrompt },
        }
    })
    lib.showContext("ogz_admin_logs")
end

function ViewRecentLogs(limit)
    lib.callback("ogz_propmanager:admin:GetRecentLogs", false, function(logs)
        DisplayLogs(logs, "Recent Activity")
    end, limit)
end

function ViewLogsByType(actionType, limit)
    lib.callback("ogz_propmanager:admin:GetLogsByType", false, function(logs)
        DisplayLogs(logs, actionType:upper() .. " Logs")
    end, actionType, limit)
end

function DisplayLogs(logs, title)
    if not logs or #logs == 0 then
        Notify("No logs found.", "info")
        return
    end
    
    local options = {}
    for _, log in ipairs(logs) do
        local icon = "fas fa-info-circle"
        if log.action == "craft" then icon = "fas fa-hammer"
        elseif log.action == "place" then icon = "fas fa-plus"
        elseif log.action == "remove" then icon = "fas fa-minus"
        elseif log.action == "event" then icon = "fas fa-dice"
        elseif log.action == "seize" then icon = "fas fa-handcuffs" end
        
        options[#options + 1] = {
            title = string.format("[%s] %s", log.action:upper(), log.citizenid),
            description = string.format("%s | %s", log.item_crafted or log.station_id or "N/A", log.created_at),
            icon = icon,
        }
    end
    
    lib.registerContext({ id = "ogz_admin_logs_display", title = "📜 " .. title, menu = "ogz_admin_logs", options = options })
    lib.showContext("ogz_admin_logs_display")
end

function ClearOldLogsPrompt()
    local input = lib.inputDialog("Clear Old Logs", {
        { type = "number", label = "Delete logs older than (days)", default = 30, min = 1 }
    })
    if input then
        local confirm = lib.alertDialog({
            header = "Confirm Clear Logs",
            content = "This will permanently delete all logs older than " .. input[1] .. " days.",
            centered = true,
            cancel = true,
        })
        if confirm == "confirm" then
            TriggerServerEvent("ogz_propmanager:admin:ClearOldLogs", input[1])
        end
    end
end

function OpenStatsMenu()
    lib.callback("ogz_propmanager:admin:GetStats", false, function(stats)
        if not stats then return end
        
        local options = {
            { title = "Total Stations: " .. (stats.totalStations or 0), icon = "fas fa-cubes" },
            { title = "Total Crafts: " .. (stats.totalCrafts or 0), icon = "fas fa-hammer" },
            { title = "Unique Crafters: " .. (stats.uniqueCrafters or 0), icon = "fas fa-users" },
        }
        
        if stats.stationCounts then
            for _, sc in ipairs(stats.stationCounts) do
                local stationConfig = GetStationConfig(sc.station_id)
                options[#options + 1] = {
                    title = (stationConfig and stationConfig.label or sc.station_id) .. ": " .. sc.count,
                    icon = stationConfig and stationConfig.icon or "fas fa-cube",
                }
            end
        end
        
        lib.registerContext({ id = "ogz_admin_stats", title = "📈 Statistics", menu = "ogz_admin_main", options = options })
        lib.showContext("ogz_admin_stats")
    end)
end

function OpenGiveItemsMenu()
    local options = {}
    for stationId, stationData in pairs(Stations) do
        options[#options + 1] = {
            title = stationData.label,
            description = "Item: " .. stationData.item,
            icon = stationData.icon,
            iconColor = stationData.iconColor,
            onSelect = function()
                local input = lib.inputDialog("Give " .. stationData.label, {
                    { type = "number", label = "Player Server ID", required = true },
                    { type = "number", label = "Amount", default = 1, min = 1, max = 10 },
                })
                if input then
                    TriggerServerEvent("ogz_propmanager:admin:GiveItem", input[1], stationData.item, input[2])
                end
            end,
        }
    end
    
    options[#options + 1] = {
        title = "Repair Kit",
        description = "Item: " .. Config.Durability.DefaultRepairItem,
        icon = "fas fa-wrench",
        iconColor = "#00ff00",
        onSelect = function()
            local input = lib.inputDialog("Give Repair Kit", {
                { type = "number", label = "Player Server ID", required = true },
                { type = "number", label = "Amount", default = 5, min = 1, max = 50 },
            })
            if input then
                TriggerServerEvent("ogz_propmanager:admin:GiveItem", input[1], Config.Durability.DefaultRepairItem, input[2])
            end
        end,
    }
    
    lib.registerContext({ id = "ogz_admin_give", title = "🎁 Give Items", menu = "ogz_admin_main", options = options })
    lib.showContext("ogz_admin_give")
end

function OpenQuickActionsMenu()
    lib.registerContext({
        id = "ogz_admin_quick",
        title = "⚙️ Quick Actions",
        menu = "ogz_admin_main",
        options = {
            { title = "🔧 Repair All Stations", description = "Set all stations to 100% durability", icon = "fas fa-wrench", onSelect = function() TriggerServerEvent("ogz_propmanager:admin:RepairAll") end },
            { title = "⏱️ Clear All Cooldowns", description = "Remove all station cooldowns", icon = "fas fa-clock", onSelect = function() TriggerServerEvent("ogz_propmanager:admin:ClearAllCooldowns") end },
            { title = "🔄 Refresh All Props", description = "Respawn all props for all players", icon = "fas fa-sync", onSelect = function() TriggerServerEvent("ogz_propmanager:admin:RefreshAllProps") end },
        }
    })
    lib.showContext("ogz_admin_quick")
end

function OpenGiveMetadataItemMenu()
    local input = lib.inputDialog("Give Item with Metadata", {
        { type = "input", label = "Player Server ID", placeholder = "1", required = true },
        { type = "input", label = "Item Name", placeholder = "coke", required = true },
        { type = "number", label = "Amount", default = 1, min = 1, max = 100 },
        { type = "number", label = "Purity %", default = 100, min = 0, max = 100 },
        { type = "number", label = "Quality % (optional)", default = 0, min = 0, max = 100 },
    })
    
    if input then
        local playerId = tonumber(input[1])
        local itemName = input[2]
        local amount = input[3] or 1
        local purity = input[4]
        local quality = input[5]
        
        if not playerId or not itemName then
            Notify("Invalid input", "error")
            return
        end
        
        local metadata = {}
        if purity and purity > 0 then metadata.purity = purity end
        if quality and quality > 0 then metadata.quality = quality end
        
        TriggerServerEvent("ogz_propmanager:admin:GiveMetadataItem", playerId, itemName, amount, metadata)
    end
end

function OpenQuickGiveMenu()
    lib.registerContext({
        id = "ogz_admin_quick_give",
        title = "🧪 Quick Give (With Purity)",
        menu = "ogz_admin_main",
        options = {
            { title = "🎁 Give Custom Item", description = "Give any item with purity/quality metadata", icon = "fas fa-gift", iconColor = "#9b59b6", onSelect = OpenGiveMetadataItemMenu },
            { title = "━━━ Quick Presets ━━━", disabled = true },
            { title = "🌿 Cosmic Kush Bud (100%)", description = "1x ls_cosmic_kush_bud @ 100% purity", icon = "fas fa-cannabis", iconColor = "#2ecc71", onSelect = function() QuickGivePreset("ls_cosmic_kush_bud", 1, 100) end },
            { title = "❄️ Cocaine (100%)", description = "1x coke @ 100% purity", icon = "fas fa-snowflake", iconColor = "#ecf0f1", onSelect = function() QuickGivePreset("coke", 1, 100) end },
            { title = "💎 Meth (100%)", description = "1x meth @ 100% purity", icon = "fas fa-gem", iconColor = "#3498db", onSelect = function() QuickGivePreset("meth", 1, 100) end },
        },
    })
    lib.showContext("ogz_admin_quick_give")
end

function QuickGivePreset(item, amount, purity)
    local input = lib.inputDialog("Give to Player", {
        { type = "input", label = "Player Server ID", placeholder = "1", required = true },
    })
    if input and input[1] then
        local playerId = tonumber(input[1])
        local metadata = purity > 0 and { purity = purity } or {}
        TriggerServerEvent("ogz_propmanager:admin:GiveMetadataItem", playerId, item, amount, metadata)
    end
end

function OpenStashAdminMenu()
    lib.registerContext({
        id = "ogz_admin_stashes",
        title = "📦 Stash Manager",
        menu = "ogz_admin_main",
        options = {
            { title = "📋 View All Stashes", description = "List all placed stashes", icon = "fas fa-list", onSelect = ViewAllStashes },
            { title = "🔍 Search by Owner", description = "Find stashes by citizen ID", icon = "fas fa-search", onSelect = SearchStashesByOwner },
            { title = "📊 Stash Statistics", description = "View stash counts by type", icon = "fas fa-chart-pie", onSelect = ViewStashStats },
            { title = "🗑️ Remove All Stashes", description = "Delete all placed stashes (DANGER!)", icon = "fas fa-trash", iconColor = "#ff0000", onSelect = ConfirmRemoveAllStashes },
        }
    })
    lib.showContext("ogz_admin_stashes")
end

function ViewAllStashes()
    lib.callback("ogz_propmanager:admin:GetAllStashes", false, function(stashes)
        if not stashes or #stashes == 0 then Notify("No stashes found.", "info") return end
        local options = {}
        for _, stash in ipairs(stashes) do
            local stashConfig = Stashes[stash.stash_type]
            options[#options + 1] = {
                title = stashConfig and stashConfig.label or stash.stash_type,
                description = string.format("Owner: %s | ID: %s", stash.citizenid, stash.id),
                icon = stashConfig and stashConfig.icon or "fas fa-box",
                onSelect = function() OpenStashActions(stash) end,
            }
        end
        lib.registerContext({ id = "ogz_admin_stash_list", title = "📦 All Stashes", menu = "ogz_admin_stashes", options = options })
        lib.showContext("ogz_admin_stash_list")
    end)
end

function OpenStashActions(stash)
    local stashConfig = Stashes[stash.stash_type]
    lib.registerContext({
        id = "ogz_admin_stash_actions",
        title = "📦 " .. (stashConfig and stashConfig.label or stash.stash_type),
        menu = "ogz_admin_stash_list",
        options = {
            { title = "📍 Teleport Here", icon = "fas fa-location-arrow", onSelect = function() 
                SetEntityCoords(PlayerPedId(), stash.coords.x, stash.coords.y, stash.coords.z, false, false, false, false)
            end },
            { title = "👁️ View Contents", icon = "fas fa-eye", onSelect = function() TriggerServerEvent("ogz_propmanager:admin:OpenStash", stash.stash_id) end },
            { title = "🗑️ Remove Stash", icon = "fas fa-trash", iconColor = "#ff4444", onSelect = function() AdminRemoveStash(stash) end },
        }
    })
    lib.showContext("ogz_admin_stash_actions")
end

function SearchStashesByOwner()
    local input = lib.inputDialog("Search Stashes", {{ type = "input", label = "Citizen ID", required = true }})
    if input and input[1] then
        lib.callback("ogz_propmanager:admin:SearchStashes", false, function(stashes)
            if not stashes or #stashes == 0 then Notify("No stashes found.", "info") return end
            local options = {}
            for _, stash in ipairs(stashes) do
                options[#options + 1] = { title = stash.stash_type, description = "ID: " .. stash.id, icon = "fas fa-box", onSelect = function() OpenStashActions(stash) end }
            end
            lib.registerContext({ id = "ogz_admin_stash_search", title = "🔍 Search Results", menu = "ogz_admin_stashes", options = options })
            lib.showContext("ogz_admin_stash_search")
        end, input[1])
    end
end

function ViewStashStats()
    lib.callback("ogz_propmanager:admin:GetStashStats", false, function(stats)
        if not stats then Notify("Failed to get stats.", "error") return end
        local options = {}
        for stashType, count in pairs(stats) do
            options[#options + 1] = { title = stashType .. ": " .. count, icon = "fas fa-box", disabled = true }
        end
        lib.registerContext({ id = "ogz_admin_stash_stats", title = "📊 Stash Statistics", menu = "ogz_admin_stashes", options = options })
        lib.showContext("ogz_admin_stash_stats")
    end)
end

function AdminRemoveStash(stash)
    local confirm = lib.alertDialog({ header = "Remove Stash", content = "Remove stash #" .. stash.id .. "?", centered = true, cancel = true })
    if confirm == "confirm" then TriggerServerEvent("ogz_propmanager:admin:RemoveStash", stash.id) end
end

function ConfirmRemoveAllStashes()
    local confirm = lib.alertDialog({ header = "⚠️ DANGER", content = "Remove ALL stashes?", centered = true, cancel = true })
    if confirm == "confirm" then TriggerServerEvent("ogz_propmanager:admin:RemoveAllStashes") end
end

function OpenLootableAdminMenu()
    lib.registerContext({
        id = "ogz_admin_lootables",
        title = "🎰 Lootable Manager",
        menu = "ogz_admin_main",
        options = {
            { title = "➕ Quick Spawn", description = "Spawn a lootable", icon = "fas fa-bolt", iconColor = "#00ff00", onSelect = QuickSpawnLootable },
            { title = "📋 View All Lootables", description = "List all lootables", icon = "fas fa-list", onSelect = ViewAllLootables },
            { title = "⏱️ Reset All Cooldowns", icon = "fas fa-clock", onSelect = function() TriggerServerEvent("ogz_propmanager:admin:ResetAllLootCooldowns") end },
            { title = "🗑️ Remove All Lootables", icon = "fas fa-trash", iconColor = "#ff0000", onSelect = ConfirmRemoveAllLootables },
        }
    })
    lib.showContext("ogz_admin_lootables")
end

function QuickSpawnLootable()
    local lootOptions = {}
    for lootId, lootConfig in pairs(Lootables) do
        if type(lootConfig) == "table" and lootConfig.label then
            lootOptions[#lootOptions + 1] = { value = lootId, label = lootConfig.label }
        end
    end
    table.sort(lootOptions, function(a, b) return a.label < b.label end)
    local input = lib.inputDialog("Quick Spawn Lootable", {{ type = "select", label = "Loot Type", options = lootOptions, required = true }})
    if input and input[1] then
        local lootType = input[1]
        local lootConfig = Lootables[lootType]
        local model = lootConfig.models and lootConfig.models[1] or lootConfig.model
        StartLootablePlacement(lootType, model, false)
    end
end

function ViewAllLootables()
    lib.callback("ogz_propmanager:admin:GetAllLootables", false, function(lootables)
        if not lootables or #lootables == 0 then Notify("No lootables found.", "info") return end
        local options = {}
        for _, loot in ipairs(lootables) do
            options[#options + 1] = {
                title = loot.loot_type,
                description = "Looted: " .. (loot.times_looted or 0) .. "x | ID: " .. loot.id,
                icon = "fas fa-dice",
                iconColor = loot.is_active and "#00ff00" or "#ff0000",
                onSelect = function() OpenLootableActions(loot) end,
            }
        end
        lib.registerContext({ id = "ogz_admin_lootable_list", title = "🎰 All Lootables", menu = "ogz_admin_lootables", options = options })
        lib.showContext("ogz_admin_lootable_list")
    end)
end

function OpenLootableActions(loot)
    lib.registerContext({
        id = "ogz_admin_lootable_actions",
        title = "🎰 " .. loot.loot_type,
        menu = "ogz_admin_lootable_list",
        options = {
            { title = "📍 Teleport Here", icon = "fas fa-location-arrow", onSelect = function() SetEntityCoords(PlayerPedId(), loot.coords.x, loot.coords.y, loot.coords.z, false, false, false, false) end },
            { title = "⏱️ Reset Cooldowns", icon = "fas fa-clock", onSelect = function() TriggerServerEvent("ogz_propmanager:admin:ResetLootableCooldowns", loot.id) end },
            { title = loot.is_active and "⏸️ Deactivate" or "▶️ Reactivate", icon = loot.is_active and "fas fa-pause" or "fas fa-play", onSelect = function() TriggerServerEvent("ogz_propmanager:admin:ToggleLootable", loot.id, not loot.is_active) end },
            { title = "🗑️ Remove Lootable", icon = "fas fa-trash", iconColor = "#ff4444", onSelect = function() AdminRemoveLootable(loot) end },
        }
    })
    lib.showContext("ogz_admin_lootable_actions")
end

function AdminRemoveLootable(loot)
    local confirm = lib.alertDialog({ header = "Remove Lootable", content = "Remove lootable #" .. loot.id .. "?", centered = true, cancel = true })
    if confirm == "confirm" then TriggerServerEvent("ogz_propmanager:server:RemoveLootable", loot.id) end
end

function ConfirmRemoveAllLootables()
    local confirm = lib.alertDialog({ header = "⚠️ DANGER", content = "Remove ALL lootables?", centered = true, cancel = true })
    if confirm == "confirm" then TriggerServerEvent("ogz_propmanager:admin:RemoveAllLootables") end
end

function OpenWorldPropsAdminMenu()
    -- Count zones and locations
    local zoneCount = 0
    local locationCount = 0
    local enabledZones = 0
    
    if WorldProps and WorldProps.Zones then
        for zoneId, config in pairs(WorldProps.Zones) do
            zoneCount = zoneCount + 1
            if config.enabled ~= false then
                enabledZones = enabledZones + 1
            end
        end
    end
    
    if WorldProps and WorldProps.Locations then
        for locId, config in pairs(WorldProps.Locations) do
            locationCount = locationCount + 1
        end
    end
    
    lib.registerContext({
        id = "ogz_admin_worldprops",
        title = "🌍 World Props",
        menu = "ogz_admin_propsystems",
        options = {
            {
                title = "📍 View Zones",
                description = string.format("%d zones (%d enabled)", zoneCount, enabledZones),
                icon = "fas fa-map-marked-alt",
                iconColor = "#00ff88",
                onSelect = function() ViewWorldPropZones() end,
            },
            {
                title = "📌 View Locations",
                description = string.format("%d locations configured", locationCount),
                icon = "fas fa-map-marker-alt",
                iconColor = "#ff6600",
                onSelect = function() ViewWorldPropLocations() end,
            },
            {
                title = "⏱️ Cooldown Management",
                description = "View and reset cooldowns",
                icon = "fas fa-clock",
                iconColor = "#9b59b6",
                onSelect = function() OpenCooldownManagement() end,
            },
            {
                title = "🔄 Force Reload All Clients",
                description = "Trigger world prop reload for all players",
                icon = "fas fa-sync-alt",
                iconColor = "#3498db",
                onSelect = function()
                    TriggerServerEvent("ogz_propmanager:admin:ReloadWorldPropsAllClients")
                    Notify("Reload triggered for all clients", "success")
                end,
            },
            {
                title = "📊 Debug Info",
                description = "View world props statistics",
                icon = "fas fa-bug",
                iconColor = "#e74c3c",
                onSelect = function() ShowWorldPropsDebug() end,
            },
        },
    })
    lib.showContext("ogz_admin_worldprops")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ZONE VIEWING (v3.4 System)
-- ═══════════════════════════════════════════════════════════════════════════

function ViewWorldPropZones()
    local options = {}
    
    if not WorldProps or not WorldProps.Zones then
        options[#options + 1] = {
            title = "No zones configured",
            icon = "fas fa-info-circle",
            disabled = true,
        }
    else
        for zoneId, config in pairs(WorldProps.Zones) do
            local statusIcon = config.enabled ~= false and "🟢" or "🔴"
            local zoneType = config.zoneType or "unknown"
            local propType = config.type or "unknown"
            
            options[#options + 1] = {
                title = statusIcon .. " " .. (config.name or zoneId),
                description = string.format("Type: %s | Zone: %s | Models: %d", 
                    propType, 
                    zoneType, 
                    config.models and #config.models or 0
                ),
                icon = GetZoneIcon(propType),
                iconColor = GetZoneColor(propType),
                onSelect = function() ViewZoneDetails(zoneId, config) end,
            }
        end
    end
    
    if #options == 0 then
        options[#options + 1] = { title = "No zones defined", icon = "fas fa-info-circle", disabled = true }
    end
    
    lib.registerContext({
        id = "ogz_admin_worldprop_zones",
        title = "📍 World Prop Zones",
        menu = "ogz_admin_worldprops",
        options = options,
    })
    lib.showContext("ogz_admin_worldprop_zones")
end

function GetZoneIcon(propType)
    local icons = {
        harvest = "fas fa-seedling",
        reward = "fas fa-gift",
        custom = "fas fa-cog",
        shop = "fas fa-store",
        stash = "fas fa-box",
        crafting = "fas fa-tools",
    }
    return icons[propType] or "fas fa-globe"
end

function GetZoneColor(propType)
    local colors = {
        harvest = "#00ff00",
        reward = "#ffaa00",
        custom = "#9b59b6",
        shop = "#3498db",
        stash = "#e67e22",
        crafting = "#e74c3c",
    }
    return colors[propType] or "#00aaff"
end

function ViewZoneDetails(zoneId, config)
    local options = {}
    
    -- Status
    local statusText = config.enabled ~= false and "✅ Enabled" or "❌ Disabled"
    options[#options + 1] = { title = statusText, icon = "fas fa-power-off", disabled = true }
    
    -- Zone info
    options[#options + 1] = { 
        title = "Zone Type: " .. (config.zoneType or "unknown"), 
        icon = "fas fa-shapes", 
        disabled = true 
    }
    options[#options + 1] = { 
        title = "Interaction: " .. (config.type or "unknown"), 
        icon = "fas fa-hand-pointer", 
        disabled = true 
    }
    
    -- Models
    if config.models and #config.models > 0 then
        local modelList = table.concat(config.models, ", ")
        if #modelList > 50 then modelList = string.sub(modelList, 1, 47) .. "..." end
        options[#options + 1] = { 
            title = "Models: " .. #config.models, 
            description = modelList,
            icon = "fas fa-cube", 
            disabled = true 
        }
    end
    
    -- Teleport to zone center
    if config.center then
        options[#options + 1] = {
            title = "🚀 Teleport to Zone",
            description = string.format("%.1f, %.1f, %.1f", config.center.x, config.center.y, config.center.z),
            icon = "fas fa-location-arrow",
            iconColor = "#00ff88",
            onSelect = function()
                SetEntityCoords(PlayerPedId(), config.center.x, config.center.y, config.center.z, false, false, false, false)
                Notify("Teleported to " .. (config.name or zoneId), "success")
            end,
        }
    end
    
    -- Reset cooldowns for this zone
    options[#options + 1] = {
        title = "⏱️ Reset Zone Cooldowns",
        description = "Clear all cooldowns for this zone",
        icon = "fas fa-clock",
        iconColor = "#e74c3c",
        onSelect = function()
            local confirm = lib.alertDialog({
                header = "Reset Cooldowns",
                content = "Reset all cooldowns for zone: " .. (config.name or zoneId) .. "?",
                centered = true,
                cancel = true,
            })
            if confirm == "confirm" then
                TriggerServerEvent("ogz_propmanager:admin:ResetZoneCooldowns", zoneId)
                Notify("Cooldowns reset for " .. (config.name or zoneId), "success")
            end
        end,
    }
    
    -- Show yields/rewards info
    if config.type == "harvest" and config.harvest and config.harvest.yields then
        options[#options + 1] = {
            title = "🌾 View Yields",
            description = #config.harvest.yields .. " items configured",
            icon = "fas fa-list",
            onSelect = function() ViewZoneYields(zoneId, config) end,
        }
    elseif config.type == "reward" and config.reward and config.reward.items then
        options[#options + 1] = {
            title = "🎁 View Rewards",
            description = #config.reward.items .. " items configured",
            icon = "fas fa-list",
            onSelect = function() ViewZoneRewards(zoneId, config) end,
        }
    elseif config.type == "custom" and config.interactions then
        options[#options + 1] = {
            title = "⚡ View Interactions",
            description = #config.interactions .. " interactions",
            icon = "fas fa-list",
            onSelect = function() ViewZoneInteractions(zoneId, config) end,
        }
    end
    
    lib.registerContext({
        id = "ogz_admin_zone_details",
        title = "📍 " .. (config.name or zoneId),
        menu = "ogz_admin_worldprop_zones",
        options = options,
    })
    lib.showContext("ogz_admin_zone_details")
end

function ViewZoneYields(zoneId, config)
    local options = {}
    for i, yield in ipairs(config.harvest.yields) do
        options[#options + 1] = {
            title = yield.item,
            description = string.format("Min: %d | Max: %d | Chance: %d%%", 
                yield.min or 1, yield.max or 1, yield.chance or 100),
            icon = "fas fa-box",
            disabled = true,
        }
    end
    lib.registerContext({
        id = "ogz_admin_zone_yields",
        title = "🌾 Yields - " .. (config.name or zoneId),
        menu = "ogz_admin_zone_details",
        options = options,
    })
    lib.showContext("ogz_admin_zone_yields")
end

function ViewZoneRewards(zoneId, config)
    local options = {}
    for i, item in ipairs(config.reward.items) do
        options[#options + 1] = {
            title = item.item,
            description = string.format("Min: %d | Max: %d | Chance: %d%%", 
                item.min or 1, item.max or 1, item.chance or 100),
            icon = "fas fa-gift",
            disabled = true,
        }
    end
    lib.registerContext({
        id = "ogz_admin_zone_rewards",
        title = "🎁 Rewards - " .. (config.name or zoneId),
        menu = "ogz_admin_zone_details",
        options = options,
    })
    lib.showContext("ogz_admin_zone_rewards")
end

function ViewZoneInteractions(zoneId, config)
    local options = {}
    for i, interaction in ipairs(config.interactions) do
        local cooldownText = "No cooldown"
        if interaction.cooldown and interaction.cooldown.time then
            cooldownText = string.format("%ds cooldown", interaction.cooldown.time)
        end
        options[#options + 1] = {
            title = interaction.label or ("Interaction #" .. i),
            description = cooldownText,
            icon = interaction.icon or "fas fa-hand-pointer",
            iconColor = interaction.iconColor or "#ffffff",
            disabled = true,
        }
    end
    lib.registerContext({
        id = "ogz_admin_zone_interactions",
        title = "⚡ Interactions - " .. (config.name or zoneId),
        menu = "ogz_admin_zone_details",
        options = options,
    })
    lib.showContext("ogz_admin_zone_interactions")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOCATION VIEWING (v3.0 System)
-- ═══════════════════════════════════════════════════════════════════════════

function ViewWorldPropLocations()
    local options = {}
    
    if not WorldProps or not WorldProps.Locations then
        options[#options + 1] = {
            title = "No locations configured",
            icon = "fas fa-info-circle",
            disabled = true,
        }
    else
        for locId, config in pairs(WorldProps.Locations) do
            local locCount = config.locations and #config.locations or 0
            options[#options + 1] = {
                title = config.label or locId,
                description = string.format("Type: %s | Spots: %d", config.type or "unknown", locCount),
                icon = config.icon or "fas fa-map-marker-alt",
                iconColor = config.iconColor or "#ff6600",
                onSelect = function() ViewLocationDetails(locId, config) end,
            }
        end
    end
    
    if #options == 0 then
        options[#options + 1] = { title = "No locations defined", icon = "fas fa-info-circle", disabled = true }
    end
    
    lib.registerContext({
        id = "ogz_admin_worldprop_locations",
        title = "📌 World Prop Locations",
        menu = "ogz_admin_worldprops",
        options = options,
    })
    lib.showContext("ogz_admin_worldprop_locations")
end

function ViewLocationDetails(locId, config)
    local options = {}
    
    -- Type info
    options[#options + 1] = { 
        title = "Type: " .. (config.type or "unknown"), 
        icon = "fas fa-tag", 
        disabled = true 
    }
    
    -- Locations list with teleport
    if config.locations then
        for i, loc in ipairs(config.locations) do
            options[#options + 1] = {
                title = "📍 Location #" .. i,
                description = string.format("%.1f, %.1f, %.1f", loc.x, loc.y, loc.z),
                icon = "fas fa-map-pin",
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), loc.x, loc.y, loc.z, false, false, false, false)
                    Notify("Teleported to location #" .. i, "success")
                end,
            }
        end
    end
    
    lib.registerContext({
        id = "ogz_admin_location_details",
        title = "📌 " .. (config.label or locId),
        menu = "ogz_admin_worldprop_locations",
        options = options,
    })
    lib.showContext("ogz_admin_location_details")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

function OpenCooldownManagement()
    lib.registerContext({
        id = "ogz_admin_cooldowns",
        title = "⏱️ Cooldown Management",
        menu = "ogz_admin_worldprops",
        options = {
            {
                title = "🗑️ Reset ALL Cooldowns",
                description = "Clear every world prop cooldown in database",
                icon = "fas fa-trash-alt",
                iconColor = "#e74c3c",
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = "⚠️ Reset All Cooldowns",
                        content = "This will reset ALL world prop cooldowns for ALL players. Continue?",
                        centered = true,
                        cancel = true,
                    })
                    if confirm == "confirm" then
                        TriggerServerEvent("ogz_propmanager:admin:ResetAllWorldPropCooldowns")
                        Notify("All cooldowns have been reset!", "success")
                    end
                end,
            },
            {
                title = "👤 Reset Player Cooldowns",
                description = "Clear cooldowns for a specific player",
                icon = "fas fa-user-clock",
                iconColor = "#3498db",
                onSelect = function() ResetPlayerCooldowns() end,
            },
            {
                title = "🌐 Reset Global Cooldowns",
                description = "Clear only global/shared cooldowns",
                icon = "fas fa-globe",
                iconColor = "#9b59b6",
                onSelect = function()
                    TriggerServerEvent("ogz_propmanager:admin:ResetGlobalCooldowns")
                    Notify("Global cooldowns reset!", "success")
                end,
            },
            {
                title = "📊 View Cooldown Stats",
                description = "See database cooldown counts",
                icon = "fas fa-chart-bar",
                iconColor = "#00ff88",
                onSelect = function()
                    TriggerServerEvent("ogz_propmanager:admin:GetCooldownStats")
                end,
            },
        },
    })
    lib.showContext("ogz_admin_cooldowns")
end

function ResetPlayerCooldowns()
    local input = lib.inputDialog("Reset Player Cooldowns", {
        { type = "input", label = "Player ID (Server ID)", placeholder = "1", required = true },
    })
    
    if input and input[1] then
        local playerId = tonumber(input[1])
        if playerId then
            TriggerServerEvent("ogz_propmanager:admin:ResetPlayerCooldowns", playerId)
            Notify("Cooldowns reset for player " .. playerId, "success")
        else
            Notify("Invalid player ID", "error")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG INFO
-- ═══════════════════════════════════════════════════════════════════════════

function ShowWorldPropsDebug()
    local zoneCount = 0
    local locationCount = 0
    local enabledZones = 0
    local totalModels = 0
    
    if WorldProps and WorldProps.Zones then
        for zoneId, config in pairs(WorldProps.Zones) do
            zoneCount = zoneCount + 1
            if config.enabled ~= false then enabledZones = enabledZones + 1 end
            if config.models then totalModels = totalModels + #config.models end
        end
    end
    
    if WorldProps and WorldProps.Locations then
        for locId, _ in pairs(WorldProps.Locations) do
            locationCount = locationCount + 1
        end
    end
    
    lib.registerContext({
        id = "ogz_admin_worldprops_debug",
        title = "📊 World Props Debug",
        menu = "ogz_admin_worldprops",
        options = {
            { title = "Zones Configured: " .. zoneCount, icon = "fas fa-map-marked-alt", disabled = true },
            { title = "Zones Enabled: " .. enabledZones, icon = "fas fa-check-circle", disabled = true },
            { title = "Locations Configured: " .. locationCount, icon = "fas fa-map-marker-alt", disabled = true },
            { title = "Total Model Types: " .. totalModels, icon = "fas fa-cubes", disabled = true },
            {
                title = "🔄 Reload Client World Props",
                description = "Reload zones and targets locally",
                icon = "fas fa-sync",
                iconColor = "#3498db",
                onSelect = function()
                    if exports.ogz_propmanager and exports.ogz_propmanager.ReloadWorldProps then
                        exports.ogz_propmanager:ReloadWorldProps()
                    else
                        ExecuteCommand("ogz_worldprop_reload")
                    end
                    Notify("World props reloaded locally", "success")
                end,
            },
            {
                title = "🔍 Run Local Prop Scan",
                description = "Scan for props within 20m",
                icon = "fas fa-search",
                iconColor = "#00ff88",
                onSelect = function()
                    ExecuteCommand("ogz_worldprop_scan 20")
                    Notify("Check F8 console for results", "info")
                end,
            },
        },
    })
    lib.showContext("ogz_admin_worldprops_debug")
end

function OpenFurnitureAdminMenu()
    lib.registerContext({
        id = "ogz_admin_furniture",
        title = "🪑 Furniture Tools",
        menu = "ogz_admin_main",
        options = {
            { title = "🔄 Reset All Furniture", description = "Reset all moved furniture", icon = "fas fa-undo", iconColor = "#ff6600", onSelect = ResetAllFurniture },
            { title = "📋 View Categories", icon = "fas fa-list", onSelect = ViewFurnitureCategories },
        }
    })
    lib.showContext("ogz_admin_furniture")
end

function ResetAllFurniture()
    if exports.ogz_propmanager and exports.ogz_propmanager.ResetAllFurniture then
        exports.ogz_propmanager:ResetAllFurniture()
        Notify("All furniture reset!", "success")
    else
        Notify("Furniture system not loaded", "error")
    end
end

function ViewFurnitureCategories()
    local options = {}
    if Furniture and Furniture.Categories then
        for catId, category in pairs(Furniture.Categories) do
            options[#options + 1] = { title = category.label or catId, description = #category.models .. " models", icon = "fas fa-couch" }
        end
    end
    lib.registerContext({ id = "ogz_admin_furniture_cats", title = "🪑 Furniture Categories", menu = "ogz_admin_furniture", options = options })
    lib.showContext("ogz_admin_furniture_cats")
end

function GetStationConfig(stationId)
    return Stations and Stations[stationId]
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMAND REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand(Config.Admin.Command, function()
    lib.callback('ogz_propmanager:server:CheckAdmin', false, function(adminStatus)
        DebugPrint("Admin check result:", adminStatus)
        isAdmin = adminStatus
        if isAdmin then
            OpenAdminMenu()
        else
            Notify("You don't have admin permissions.", "error")
        end
    end)
end, false)

RegisterCommand("ogz_admin_debug", function()
    print("[OGz PropManager] Current isAdmin:", isAdmin)
    lib.callback('ogz_propmanager:server:CheckAdmin', false, function(result)
        print("[OGz PropManager] Server says admin:", result)
    end)
end, false)

if Config.Admin.Keybind then
    RegisterKeyMapping(Config.Admin.Command, "Open PropManager Admin", "keyboard", Config.Admin.Keybind)
end

RegisterNetEvent("ogz_propmanager:admin:Notify", function(message, type)
    Notify(message, type)
end)

-- Handle world props reload trigger from admin
RegisterNetEvent("ogz_propmanager:client:ReloadWorldProps", function()
    if exports.ogz_propmanager and exports.ogz_propmanager.ReloadWorldProps then
        exports.ogz_propmanager:ReloadWorldProps()
        Notify("World props reloaded by admin", "info")
    else
        -- Fallback to command
        ExecuteCommand("ogz_worldprop_reload")
    end
end)

print("^2[OGz PropManager]^0 Admin Menu loaded!")
