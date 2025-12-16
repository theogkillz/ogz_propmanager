--[[
    OGz PropManager v3.3 - Admin Menu (Client)
    
    Provides admin interface for managing stations, stashes, lootables, etc.
    
    v3.3: Full lootable admin options (timer, searches, custom loot, alerts)
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
-- MAIN ADMIN MENU
-- ═══════════════════════════════════════════════════════════════════════════

local function OpenAdminMenu()
    if not isAdmin then
        Notify("You don't have admin permissions.", "error")
        return
    end
    
    lib.registerContext({
        id = "ogz_admin_main",
        title = "🔧 OGz PropManager v3.3 Admin",
        options = {
            -- Original v2.0 Options
            { title = "📊 Station Overview", description = "View all placed stations", icon = "fas fa-chart-bar", onSelect = OpenStationOverview },
            { title = "🔍 Search Stations", description = "Find stations by owner/type", icon = "fas fa-search", onSelect = OpenSearchMenu },
            { title = "📜 View Logs", description = "View production & activity logs", icon = "fas fa-scroll", onSelect = OpenLogsMenu },
            { title = "📈 Statistics", description = "View server-wide stats", icon = "fas fa-chart-line", onSelect = OpenStatsMenu },
            { title = "🎁 Give Items", description = "Give station items to players", icon = "fas fa-gift", onSelect = OpenGiveItemsMenu },
            { title = "⚙️ Quick Actions", description = "Repair all, clear cooldowns, etc.", icon = "fas fa-cogs", onSelect = OpenQuickActionsMenu },
            -- v3.0 Options
            { title = "━━━━━ v3.0 Systems ━━━━━", disabled = true },
            { title = "📦 Stash Manager", description = "View and manage placed stashes", icon = "fas fa-box", iconColor = "#ffaa00", onSelect = OpenStashAdminMenu },
            { title = "🎰 Lootable Manager", description = "Spawn and manage loot props", icon = "fas fa-dice", iconColor = "#9933ff", onSelect = OpenLootableAdminMenu },
            { title = "🌍 World Props", description = "View configured world prop locations", icon = "fas fa-globe", iconColor = "#00aaff", onSelect = OpenWorldPropsAdminMenu },
            { title = "🪑 Furniture Tools", description = "Reset moved furniture", icon = "fas fa-chair", iconColor = "#ff6600", onSelect = OpenFurnitureAdminMenu },
            { title = "🧪 Give with Purity", description = "Give items with metadata for testing", icon = "fas fa-flask", iconColor = "#9b59b6", onSelect = OpenQuickGiveMenu },
        }
    })
    lib.showContext("ogz_admin_main")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION OVERVIEW
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

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION ACTIONS
-- ═══════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════
-- SEARCH MENU
-- ═══════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════
-- LOGS MENU
-- ═══════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════
-- STATISTICS MENU
-- ═══════════════════════════════════════════════════════════════════════════

function OpenStatsMenu()
    lib.callback("ogz_propmanager:admin:GetStats", false, function(stats)
        if not stats then return end
        
        local options = {
            { title = "Total Stations: " .. (stats.totalStations or 0), icon = "fas fa-cubes" },
            { title = "Total Crafts: " .. (stats.totalCrafts or 0), icon = "fas fa-hammer" },
            { title = "Unique Crafters: " .. (stats.uniqueCrafters or 0), icon = "fas fa-users" },
        }
        
        -- Station breakdown
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

-- ═══════════════════════════════════════════════════════════════════════════
-- GIVE ITEMS MENU
-- ═══════════════════════════════════════════════════════════════════════════

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
    
    -- Add repair kit option
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

-- ═══════════════════════════════════════════════════════════════════════════
-- QUICK ACTIONS MENU
-- ═══════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.1 PROCESSING ADMIN - GIVE ITEMS WITH METADATA
-- ═══════════════════════════════════════════════════════════════════════════

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
        
        -- Build metadata
        local metadata = {}
        if purity and purity > 0 then
            metadata.purity = purity
        end
        if quality and quality > 0 then
            metadata.quality = quality
        end
        
        TriggerServerEvent("ogz_propmanager:admin:GiveMetadataItem", playerId, itemName, amount, metadata)
    end
end

function OpenQuickGiveMenu()
    lib.registerContext({
        id = "ogz_admin_quick_give",
        title = "🧪 Quick Give (With Purity)",
        menu = "ogz_admin_main",
        options = {
            {
                title = "🎁 Give Custom Item",
                description = "Give any item with purity/quality metadata",
                icon = "fas fa-gift",
                iconColor = "#9b59b6",
                onSelect = OpenGiveMetadataItemMenu,
            },
            {
                title = "━━━ Quick Presets ━━━",
                disabled = true,
            },
            {
                title = "🌿 Cosmic Kush Bud (100%)",
                description = "1x ls_cosmic_kush_bud @ 100% purity",
                icon = "fas fa-cannabis",
                iconColor = "#2ecc71",
                onSelect = function()
                    QuickGivePreset("ls_cosmic_kush_bud", 1, 100)
                end,
            },
            {
                title = "🌿 Cosmic Kush Bud (75%)",
                description = "1x ls_cosmic_kush_bud @ 75% purity",
                icon = "fas fa-cannabis",
                iconColor = "#27ae60",
                onSelect = function()
                    QuickGivePreset("ls_cosmic_kush_bud", 1, 75)
                end,
            },
            {
                title = "❄️ Cocaine (100%)",
                description = "1x coke @ 100% purity",
                icon = "fas fa-snowflake",
                iconColor = "#ecf0f1",
                onSelect = function()
                    QuickGivePreset("coke", 1, 100)
                end,
            },
            {
                title = "❄️ Cocaine (50%)",
                description = "1x coke @ 50% purity (cut)",
                icon = "fas fa-snowflake",
                iconColor = "#bdc3c7",
                onSelect = function()
                    QuickGivePreset("coke", 1, 50)
                end,
            },
            {
                title = "💎 Meth (100%)",
                description = "1x meth @ 100% purity",
                icon = "fas fa-gem",
                iconColor = "#3498db",
                onSelect = function()
                    QuickGivePreset("meth", 1, 100)
                end,
            },
            {
                title = "💎 Meth (85%)",
                description = "1x meth @ 85% purity",
                icon = "fas fa-gem",
                iconColor = "#2980b9",
                onSelect = function()
                    QuickGivePreset("meth", 1, 85)
                end,
            },
            {
                title = "📦 Empty Baggies (x50)",
                description = "50x ls_empty_baggy",
                icon = "fas fa-box",
                onSelect = function()
                    QuickGivePreset("ls_empty_baggy", 50, 0)
                end,
            },
            {
                title = "⚖️ Scales",
                description = "1x scales",
                icon = "fas fa-balance-scale",
                onSelect = function()
                    QuickGivePreset("scales", 1, 0)
                end,
            },
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

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 STASH ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

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
        if not stashes or #stashes == 0 then
            Notify("No stashes found.", "info")
            return
        end
        
        local options = {}
        for _, stash in ipairs(stashes) do
            local stashConfig = Stashes[stash.stash_type]
            local accessInfo = {}
            if stash.access_gang then table.insert(accessInfo, "Gang: " .. stash.access_gang) end
            if stash.access_job then table.insert(accessInfo, "Job: " .. stash.access_job) end
            local accessText = #accessInfo > 0 and table.concat(accessInfo, ", ") or "Owner only"
            
            options[#options + 1] = {
                title = stashConfig and stashConfig.label or stash.stash_type,
                description = string.format("Owner: %s | %s | ID: %s", stash.citizenid, accessText, stash.id),
                icon = stashConfig and stashConfig.icon or "fas fa-box",
                onSelect = function() OpenStashActions(stash) end,
            }
        end
        
        lib.registerContext({ id = "ogz_admin_stash_list", title = "📦 All Stashes (" .. #stashes .. ")", menu = "ogz_admin_stashes", options = options })
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
                Notify("Teleported to stash #" .. stash.id, "success")
            end },
            { title = "👁️ View Contents", description = "Open this stash inventory", icon = "fas fa-eye", onSelect = function()
                TriggerServerEvent("ogz_propmanager:admin:OpenStash", stash.stash_id)
            end },
            { title = "🔐 View Access List", icon = "fas fa-key", onSelect = function() ViewStashAccessList(stash) end },
            { title = "🗑️ Remove Stash", icon = "fas fa-trash", iconColor = "#ff4444", onSelect = function() AdminRemoveStash(stash) end },
        }
    })
    lib.showContext("ogz_admin_stash_actions")
end

function ViewStashAccessList(stash)
    local options = {
        { title = "👤 Owner: " .. stash.citizenid, icon = "fas fa-user", iconColor = "#00ff00", disabled = true },
    }
    
    if stash.access_gang then
        options[#options + 1] = { title = "🏴 Gang: " .. stash.access_gang, icon = "fas fa-users", iconColor = "#ff6600", disabled = true }
    end
    
    if stash.access_job then
        options[#options + 1] = { title = "💼 Job: " .. stash.access_job, icon = "fas fa-briefcase", iconColor = "#0066ff", disabled = true }
    end
    
    if stash.custom_access and #stash.custom_access > 0 then
        for _, cid in ipairs(stash.custom_access) do
            options[#options + 1] = { title = "👥 Custom: " .. cid, icon = "fas fa-user-plus", disabled = true }
        end
    end
    
    lib.registerContext({ id = "ogz_admin_stash_access", title = "🔐 Access List", menu = "ogz_admin_stash_actions", options = options })
    lib.showContext("ogz_admin_stash_access")
end

function SearchStashesByOwner()
    local input = lib.inputDialog("Search Stashes", {
        { type = "input", label = "Citizen ID", placeholder = "ABC12345", required = true }
    })
    
    if input and input[1] then
        lib.callback("ogz_propmanager:admin:SearchStashes", false, function(stashes)
            if not stashes or #stashes == 0 then
                Notify("No stashes found for this owner.", "info")
                return
            end
            
            local options = {}
            for _, stash in ipairs(stashes) do
                local stashConfig = Stashes[stash.stash_type]
                options[#options + 1] = {
                    title = stashConfig and stashConfig.label or stash.stash_type,
                    description = string.format("ID: %s | Stash: %s", stash.id, stash.stash_id),
                    icon = stashConfig and stashConfig.icon or "fas fa-box",
                    onSelect = function() OpenStashActions(stash) end,
                }
            end
            
            lib.registerContext({ id = "ogz_admin_stash_search", title = "🔍 Search Results", menu = "ogz_admin_stashes", options = options })
            lib.showContext("ogz_admin_stash_search")
        end, input[1])
    end
end

function ViewStashStats()
    lib.callback("ogz_propmanager:admin:GetStashStats", false, function(stats)
        if not stats then
            Notify("Failed to get stash stats.", "error")
            return
        end
        
        local options = {}
        for stashType, count in pairs(stats) do
            local stashConfig = Stashes[stashType]
            options[#options + 1] = {
                title = (stashConfig and stashConfig.label or stashType) .. ": " .. count,
                icon = stashConfig and stashConfig.icon or "fas fa-box",
                disabled = true,
            }
        end
        
        if #options == 0 then
            options[#options + 1] = { title = "No stashes placed yet", disabled = true }
        end
        
        lib.registerContext({ id = "ogz_admin_stash_stats", title = "📊 Stash Statistics", menu = "ogz_admin_stashes", options = options })
        lib.showContext("ogz_admin_stash_stats")
    end)
end

function AdminRemoveStash(stash)
    local confirm = lib.alertDialog({
        header = "Remove Stash",
        content = "Are you sure you want to remove this stash?\n\n⚠️ Contents will remain in ox_inventory!\n\nOwner: " .. stash.citizenid .. "\nID: " .. stash.id,
        centered = true,
        cancel = true,
    })
    if confirm == "confirm" then
        TriggerServerEvent("ogz_propmanager:admin:RemoveStash", stash.id)
    end
end

function ConfirmRemoveAllStashes()
    local confirm = lib.alertDialog({
        header = "⚠️ DANGER - Remove ALL Stashes",
        content = "This will PERMANENTLY DELETE all placed stashes!\n\n⚠️ Contents will remain in ox_inventory but props will be gone!\n\nType 'DELETE' to confirm:",
        centered = true,
        cancel = true,
    })
    
    if confirm == "confirm" then
        local input = lib.inputDialog("Confirm Deletion", {
            { type = "input", label = "Type DELETE to confirm", required = true }
        })
        
        if input and input[1] == "DELETE" then
            TriggerServerEvent("ogz_propmanager:admin:RemoveAllStashes")
        else
            Notify("Deletion cancelled - confirmation text didn't match", "error")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 LOOTABLE ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

function OpenLootableAdminMenu()
    lib.registerContext({
        id = "ogz_admin_lootables",
        title = "🎰 Lootable Manager",
        menu = "ogz_admin_main",
        options = {
            { title = "➕ Quick Spawn", description = "Quick spawn with placement system", icon = "fas fa-bolt", iconColor = "#00ff00", onSelect = QuickSpawnLootable },
            { title = "🎯 Advanced Spawn", description = "Full options: timer, searches, custom loot, etc.", icon = "fas fa-cogs", iconColor = "#ffaa00", onSelect = AdvancedSpawnLootable },
            { title = "📋 View All Lootables", description = "List all placed lootables", icon = "fas fa-list", onSelect = ViewAllLootables },
            { title = "⏱️ Reset All Cooldowns", description = "Clear all loot cooldowns", icon = "fas fa-clock", onSelect = function() 
                TriggerServerEvent("ogz_propmanager:admin:ResetAllLootCooldowns")
            end },
            { title = "🗑️ Remove All Lootables", description = "Delete all placed lootables (DANGER!)", icon = "fas fa-trash", iconColor = "#ff0000", onSelect = ConfirmRemoveAllLootables },
        }
    })
    lib.showContext("ogz_admin_lootables")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- QUICK SPAWN (Simple - uses placement system)
-- ═══════════════════════════════════════════════════════════════════════════

function QuickSpawnLootable()
    local lootOptions = {}
    for lootId, lootConfig in pairs(Lootables) do
        -- v3.3: Filter out non-lootable entries (Defaults, functions, etc.)
        if type(lootConfig) == "table" and lootConfig.label then
            lootOptions[#lootOptions + 1] = { value = lootId, label = lootConfig.label }
        end
    end
    
    table.sort(lootOptions, function(a, b) return a.label < b.label end)
    
    local input = lib.inputDialog("Quick Spawn Lootable", {
        { type = "select", label = "Loot Type", options = lootOptions, required = true },
    })
    
    if input and input[1] then
        local lootType = input[1]
        local lootConfig = Lootables[lootType]
        
        -- Select model if multiple
        local model = lootConfig.models and lootConfig.models[1] or lootConfig.model
        if lootConfig.models and #lootConfig.models > 1 then
            local modelOptions = {}
            for i, m in ipairs(lootConfig.models) do
                modelOptions[#modelOptions + 1] = { value = m, label = m }
            end
            
            local modelInput = lib.inputDialog("Select Model", {
                { type = "select", label = "Model", options = modelOptions, required = true }
            })
            
            if not modelInput then return end
            model = modelInput[1]
        end
        
        -- Use placement system
        StartLootablePlacement(lootType, model, false)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ADVANCED SPAWN (Full v3.3 options)
-- ═══════════════════════════════════════════════════════════════════════════

function AdvancedSpawnLootable()
    -- Step 1: Select lootable type
    local lootOptions = {}
    for lootId, lootConfig in pairs(Lootables) do
        if type(lootConfig) == "table" and lootConfig.label then
            lootOptions[#lootOptions + 1] = { value = lootId, label = lootConfig.label }
        end
    end
    
    table.sort(lootOptions, function(a, b) return a.label < b.label end)
    
    local step1 = lib.inputDialog("🎰 Advanced Spawn - Step 1/3", {
        { type = "select", label = "Loot Type", options = lootOptions, required = true },
    })
    
    if not step1 then return end
    
    local lootType = step1[1]
    local lootConfig = Lootables[lootType]
    
    -- Select model if multiple
    local model = lootConfig.models and lootConfig.models[1] or lootConfig.model
    if lootConfig.models and #lootConfig.models > 1 then
        local modelOptions = {}
        for i, m in ipairs(lootConfig.models) do
            modelOptions[#modelOptions + 1] = { value = m, label = m }
        end
        
        local modelInput = lib.inputDialog("Select Model", {
            { type = "select", label = "Model", options = modelOptions, required = true }
        })
        
        if not modelInput then return end
        model = modelInput[1]
    end
    
    -- Step 2: Timing & Limits
    local step2 = lib.inputDialog("🎰 Advanced Spawn - Step 2/3: Timing", {
        { type = "checkbox", label = "One-Time Loot (disappears after first search)", default = false },
        { type = "number", label = "Auto-Despawn Timer (minutes, 0 = never)", default = 0, min = 0, max = 1440 },
        { type = "number", label = "Max Searches (0 = unlimited)", default = 0, min = 0, max = 100 },
        { type = "number", label = "Loot Multiplier", default = 1.0, min = 0.1, max = 10.0, step = 0.1 },
    })
    
    if not step2 then return end
    
    local despawnOnSearch = step2[1]
    local despawnTimer = step2[2]
    local maxSearches = step2[3]
    local lootMultiplier = step2[4]
    
    -- Step 3: Advanced Options
    local step3 = lib.inputDialog("🎰 Advanced Spawn - Step 3/3: Extras", {
        { type = "number", label = "Police Alert Chance (%, 0 = disabled)", default = 0, min = 0, max = 100 },
        { type = "input", label = "Required Item to Search (leave empty for none)", placeholder = "lockpick" },
        { type = "checkbox", label = "Consume Required Item?", default = false },
        { type = "checkbox", label = "Use Custom Loot Instead of Table?", default = false },
    })
    
    if not step3 then return end
    
    local policeAlertChance = step3[1]
    local requiredItem = step3[2] and step3[2] ~= "" and step3[2] or nil
    local consumeRequired = step3[3]
    local useCustomLoot = step3[4]
    
    -- Custom loot input
    local customLoot = nil
    if useCustomLoot then
        customLoot = GetCustomLootInput()
        if not customLoot or #customLoot == 0 then
            Notify("Custom loot cancelled - using default loot table", "info")
            customLoot = nil
        end
    end
    
    -- Build overrides
    local overrides = {
        lootMultiplier = lootMultiplier ~= 1.0 and lootMultiplier or nil,
        policeAlert = policeAlertChance > 0 and {
            enabled = true,
            chance = policeAlertChance,
            message = "Suspicious activity reported",
            blipDuration = 60,
        } or nil,
        requiredItem = requiredItem,
        consumeRequired = consumeRequired,
    }
    
    -- Start placement with admin options
    StartAdminLootablePlacementWithOptions(lootType, model, {
        despawnOnSearch = despawnOnSearch,
        despawnTimer = despawnTimer,
        maxSearches = maxSearches,
        customLoot = customLoot,
        overrides = overrides,
    })
end

function GetCustomLootInput()
    local items = {}
    
    while true do
        local itemCount = #items
        local input = lib.inputDialog("Add Custom Loot Item (" .. itemCount .. " added)", {
            { type = "input", label = "Item Name", required = true, placeholder = "cash" },
            { type = "number", label = "Amount", default = 1, min = 1, max = 99999 },
            { type = "checkbox", label = "Add Another Item?", default = false },
        })
        
        if not input then
            if #items == 0 then return nil end
            break
        end
        
        table.insert(items, { item = input[1], count = input[2] })
        Notify("Added: " .. input[2] .. "x " .. input[1], "success")
        
        if not input[3] then break end
    end
    
    return items
end

function StartAdminLootablePlacementWithOptions(lootType, model, adminOptions)
    local lootConfig = Lootables[lootType]
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
            default = Config.Placement.DefaultMode or "gizmo",
            required = true,
        }
    })
    
    if not choice then return end
    
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
    SetEntityAlpha(tempProp, Config.Placement.GhostAlpha or 150, false)
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
        
        local currentHeading = playerHeading
        local currentHeight = 0.0
        local placing = true
        
        while placing do
            Wait(0)
            
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local direction = RotationToDirection(camRot)
            local endCoords = camCoords + (direction * (Config.Placement.CastDistance or 10.0))
            
            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, endCoords.x, endCoords.y, endCoords.z, 1 + 16, PlayerPedId(), 0)
            local _, hit, hitCoords = GetShapeTestResult(rayHandle)
            
            if hit then
                SetEntityCoords(tempProp, hitCoords.x, hitCoords.y, hitCoords.z + currentHeight)
                SetEntityHeading(tempProp, currentHeading)
            end
            
            local keys = Config.Placement.Keys
            if IsControlPressed(0, keys.rotateLeft) then currentHeading = currentHeading - 2.0 end
            if IsControlPressed(0, keys.rotateRight) then currentHeading = currentHeading + 2.0 end
            if IsControlPressed(0, keys.heightUp) then currentHeight = currentHeight + (Config.Placement.MoveSpeed or 0.01) end
            if IsControlPressed(0, keys.heightDown) then currentHeight = currentHeight - (Config.Placement.MoveSpeed or 0.01) end
            
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
        
        -- Show summary
        local summary = "✅ Lootable spawned!"
        if adminOptions.despawnTimer and adminOptions.despawnTimer > 0 then
            summary = summary .. "\n⏱️ Despawns in " .. adminOptions.despawnTimer .. " min"
        end
        if adminOptions.maxSearches and adminOptions.maxSearches > 0 then
            summary = summary .. "\n🔢 Max " .. adminOptions.maxSearches .. " searches"
        end
        if adminOptions.customLoot then
            summary = summary .. "\n🎁 Custom loot: " .. #adminOptions.customLoot .. " items"
        end
        if adminOptions.overrides and adminOptions.overrides.policeAlert then
            summary = summary .. "\n🚨 " .. adminOptions.overrides.policeAlert.chance .. "% police alert"
        end
        
        Notify(summary, "success")
    else
        Notify(Config.Notifications.Cancelled or "Placement cancelled", "info")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEW ALL LOOTABLES (Updated for v3.3)
-- ═══════════════════════════════════════════════════════════════════════════

function ViewAllLootables()
    lib.callback("ogz_propmanager:admin:GetAllLootables", false, function(lootables)
        if not lootables or #lootables == 0 then
            Notify("No lootables found.", "info")
            return
        end
        
        local options = {}
        for _, loot in ipairs(lootables) do
            local lootConfig = Lootables[loot.loot_type]
            local statusIcon = loot.is_active and "#00ff00" or "#ff0000"
            
            -- Build description with v3.3 info
            local desc = string.format("Looted: %dx", loot.times_looted or 0)
            
            if loot.max_searches and loot.max_searches > 0 then
                desc = desc .. string.format(" | Max: %d", loot.max_searches)
            end
            
            if loot.expires_at then
                desc = desc .. " | ⏱️ Timed"
            end
            
            if loot.despawn_on_search then
                desc = desc .. " | 🔄 One-time"
            end
            
            if loot.custom_loot then
                desc = desc .. " | 🎁 Custom"
            end
            
            desc = desc .. " | ID: " .. loot.id
            
            options[#options + 1] = {
                title = (lootConfig and lootConfig.label or loot.loot_type),
                description = desc,
                icon = lootConfig and lootConfig.icon or "fas fa-dice",
                iconColor = statusIcon,
                onSelect = function() OpenLootableActions(loot) end,
            }
        end
        
        lib.registerContext({ id = "ogz_admin_lootable_list", title = "🎰 All Lootables (" .. #lootables .. ")", menu = "ogz_admin_lootables", options = options })
        lib.showContext("ogz_admin_lootable_list")
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOOTABLE ACTIONS (Updated for v3.3)
-- ═══════════════════════════════════════════════════════════════════════════

function OpenLootableActions(loot)
    local lootConfig = Lootables[loot.loot_type]
    
    local options = {
        { title = "📍 Teleport Here", icon = "fas fa-location-arrow", onSelect = function() 
            SetEntityCoords(PlayerPedId(), loot.coords.x, loot.coords.y, loot.coords.z, false, false, false, false)
            Notify("Teleported to lootable #" .. loot.id, "success")
        end },
        { title = "ℹ️ View Details", icon = "fas fa-info-circle", onSelect = function() ViewLootableDetails(loot) end },
        { title = "⏱️ Reset Cooldowns", description = "Clear all cooldowns for this lootable", icon = "fas fa-clock", onSelect = function()
            TriggerServerEvent("ogz_propmanager:admin:ResetLootableCooldowns", loot.id)
        end },
        { title = "✏️ Modify Settings", description = "Change timer, searches, etc.", icon = "fas fa-edit", iconColor = "#ffaa00", onSelect = function() ModifyLootableSettings(loot) end },
        { title = loot.is_active and "⏸️ Deactivate" or "▶️ Reactivate", icon = loot.is_active and "fas fa-pause" or "fas fa-play", onSelect = function()
            TriggerServerEvent("ogz_propmanager:admin:ToggleLootable", loot.id, not loot.is_active)
        end },
        { title = "🗑️ Remove Lootable", icon = "fas fa-trash", iconColor = "#ff4444", onSelect = function() AdminRemoveLootable(loot) end },
    }
    
    lib.registerContext({
        id = "ogz_admin_lootable_actions",
        title = "🎰 " .. (lootConfig and lootConfig.label or loot.loot_type),
        menu = "ogz_admin_lootable_list",
        options = options
    })
    lib.showContext("ogz_admin_lootable_actions")
end

function ViewLootableDetails(loot)
    local lootConfig = Lootables[loot.loot_type]
    
    local options = {
        { title = "Type: " .. loot.loot_type, icon = "fas fa-tag", disabled = true },
        { title = "Model: " .. (loot.model or "Unknown"), icon = "fas fa-cube", disabled = true },
        { title = "Times Looted: " .. (loot.times_looted or 0), icon = "fas fa-search", disabled = true },
        { title = "Active: " .. (loot.is_active and "Yes" or "No"), icon = loot.is_active and "fas fa-check" or "fas fa-times", iconColor = loot.is_active and "#00ff00" or "#ff0000", disabled = true },
    }
    
    -- v3.3 fields
    if loot.max_searches and loot.max_searches > 0 then
        options[#options + 1] = { title = "Max Searches: " .. loot.max_searches, icon = "fas fa-hashtag", disabled = true }
    end
    
    if loot.despawn_on_search then
        options[#options + 1] = { title = "One-Time Loot: Yes", icon = "fas fa-sync", iconColor = "#ffaa00", disabled = true }
    end
    
    if loot.expires_at then
        options[#options + 1] = { title = "Expires: " .. loot.expires_at, icon = "fas fa-clock", iconColor = "#ff6600", disabled = true }
    end
    
    if loot.custom_loot then
        local itemCount = type(loot.custom_loot) == "table" and #loot.custom_loot or 0
        options[#options + 1] = { title = "Custom Loot: " .. itemCount .. " items", icon = "fas fa-gift", iconColor = "#9933ff", disabled = true }
    end
    
    if loot.admin_overrides then
        if loot.admin_overrides.policeAlert and loot.admin_overrides.policeAlert.enabled then
            options[#options + 1] = { title = "Police Alert: " .. (loot.admin_overrides.policeAlert.chance or 0) .. "%", icon = "fas fa-siren", iconColor = "#ff0000", disabled = true }
        end
        if loot.admin_overrides.requiredItem then
            options[#options + 1] = { title = "Requires: " .. loot.admin_overrides.requiredItem, icon = "fas fa-key", disabled = true }
        end
        if loot.admin_overrides.lootMultiplier and loot.admin_overrides.lootMultiplier ~= 1.0 then
            options[#options + 1] = { title = "Loot Multiplier: " .. loot.admin_overrides.lootMultiplier .. "x", icon = "fas fa-times", disabled = true }
        end
    end
    
    if loot.placed_by then
        options[#options + 1] = { title = "Placed By: " .. loot.placed_by, icon = "fas fa-user", disabled = true }
    end
    
    lib.registerContext({
        id = "ogz_admin_lootable_details",
        title = "ℹ️ Lootable Details",
        menu = "ogz_admin_lootable_actions",
        options = options,
    })
    lib.showContext("ogz_admin_lootable_details")
end

function ModifyLootableSettings(loot)
    local input = lib.inputDialog("Modify Lootable #" .. loot.id, {
        { type = "number", label = "Max Searches (0 = unlimited)", default = loot.max_searches or 0, min = 0, max = 100 },
        { type = "number", label = "Add Time (minutes, adds to current)", default = 0, min = 0, max = 1440 },
        { type = "checkbox", label = "Despawn After Next Search?", default = loot.despawn_on_search or false },
    })
    
    if input then
        TriggerServerEvent("ogz_propmanager:admin:ModifyLootable", loot.id, {
            maxSearches = input[1],
            addTime = input[2],
            despawnOnSearch = input[3],
        })
    end
end

function AdminRemoveLootable(loot)
    local confirm = lib.alertDialog({
        header = "Remove Lootable",
        content = "Are you sure you want to remove this lootable?\n\nID: " .. loot.id .. "\nType: " .. loot.loot_type,
        centered = true,
        cancel = true,
    })
    if confirm == "confirm" then
        TriggerServerEvent("ogz_propmanager:server:RemoveLootable", loot.id)
    end
end

function ConfirmRemoveAllLootables()
    local confirm = lib.alertDialog({
        header = "⚠️ DANGER - Remove ALL Lootables",
        content = "This will PERMANENTLY DELETE all placed lootables!\n\nType 'DELETE' to confirm:",
        centered = true,
        cancel = true,
    })
    
    if confirm == "confirm" then
        local input = lib.inputDialog("Confirm Deletion", {
            { type = "input", label = "Type DELETE to confirm", required = true }
        })
        
        if input and input[1] == "DELETE" then
            TriggerServerEvent("ogz_propmanager:admin:RemoveAllLootables")
        else
            Notify("Deletion cancelled", "error")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 WORLD PROPS ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

function OpenWorldPropsAdminMenu()
    local options = {
        { title = "📋 View Configured Locations", description = "See all world prop locations", icon = "fas fa-map-marker-alt", onSelect = ViewWorldPropLocations },
        { title = "⏱️ Reset All Cooldowns", description = "Clear all world prop cooldowns", icon = "fas fa-clock", onSelect = function()
            TriggerServerEvent("ogz_propmanager:admin:ResetAllWorldPropCooldowns")
        end },
    }
    
    -- Count configured locations
    local totalLocations = 0
    for _, config in pairs(WorldProps) do
        if config.locations then
            totalLocations = totalLocations + #config.locations
        end
    end
    
    lib.registerContext({
        id = "ogz_admin_worldprops",
        title = "🌍 World Props (" .. totalLocations .. " locations)",
        menu = "ogz_admin_main",
        options = options,
    })
    lib.showContext("ogz_admin_worldprops")
end

function ViewWorldPropLocations()
    local options = {}
    
    for propId, config in pairs(WorldProps) do
        local locationCount = config.locations and #config.locations or 0
        
        options[#options + 1] = {
            title = config.label or propId,
            description = string.format("Type: %s | Locations: %d", config.type, locationCount),
            icon = config.icon or "fas fa-globe",
            iconColor = config.iconColor or "#00aaff",
            onSelect = function() ViewWorldPropDetails(propId, config) end,
        }
    end
    
    if #options == 0 then
        options[#options + 1] = { title = "No world props configured", description = "Add locations in config/worldprops.lua", disabled = true }
    end
    
    lib.registerContext({ id = "ogz_admin_worldprop_list", title = "🌍 World Prop Definitions", menu = "ogz_admin_worldprops", options = options })
    lib.showContext("ogz_admin_worldprop_list")
end

function ViewWorldPropDetails(propId, config)
    local options = {
        { title = "Type: " .. config.type, icon = "fas fa-tag", disabled = true },
    }
    
    if config.locations then
        for i, loc in ipairs(config.locations) do
            local coordStr = string.format("%.1f, %.1f, %.1f", loc.x, loc.y, loc.z)
            options[#options + 1] = {
                title = "Location #" .. i,
                description = coordStr,
                icon = "fas fa-map-pin",
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), loc.x, loc.y, loc.z, false, false, false, false)
                    Notify("Teleported to " .. (config.label or propId) .. " location #" .. i, "success")
                end,
            }
        end
    end
    
    lib.registerContext({ id = "ogz_admin_worldprop_details", title = "🌍 " .. (config.label or propId), menu = "ogz_admin_worldprop_list", options = options })
    lib.showContext("ogz_admin_worldprop_details")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 FURNITURE ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

function OpenFurnitureAdminMenu()
    local movedCount = 0
    if exports.ogz_propmanager and exports.ogz_propmanager.GetMovedFurniture then
        local moved = exports.ogz_propmanager:GetMovedFurniture()
        if moved then
            for _ in pairs(moved) do movedCount = movedCount + 1 end
        end
    end
    
    lib.registerContext({
        id = "ogz_admin_furniture",
        title = "🪑 Furniture Tools",
        menu = "ogz_admin_main",
        options = {
            { title = "📊 Currently Moved: " .. movedCount, icon = "fas fa-info-circle", disabled = true },
            { title = "🔄 Reset All Furniture", description = "Reset all moved furniture to original positions", icon = "fas fa-undo", iconColor = "#ff6600", onSelect = ResetAllFurniture },
            { title = "👁️ Show Nearby Furniture", description = "List furniture models near you", icon = "fas fa-eye", onSelect = ShowNearbyFurniture },
            { title = "📋 View Categories", description = "See all configured furniture categories", icon = "fas fa-list", onSelect = ViewFurnitureCategories },
        }
    })
    lib.showContext("ogz_admin_furniture")
end

function ResetAllFurniture()
    if exports.ogz_propmanager and exports.ogz_propmanager.ResetAllFurniture then
        exports.ogz_propmanager:ResetAllFurniture()
        Notify("All furniture reset to original positions!", "success")
    else
        Notify("Furniture system not loaded", "error")
    end
end

function ShowNearbyFurniture()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local options = {}
    local found = 0
    
    for catId, category in pairs(Furniture.Categories) do
        for _, modelName in ipairs(category.models) do
            local modelHash = type(modelName) == "string" and joaat(modelName) or modelName
            local entity = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, modelHash, false, false, false)
            
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                local entityCoords = GetEntityCoords(entity)
                local dist = #(playerCoords - entityCoords)
                found = found + 1
                
                options[#options + 1] = {
                    title = modelName,
                    description = string.format("Category: %s | Distance: %.1fm", catId, dist),
                    icon = "fas fa-chair",
                    onSelect = function()
                        SetEntityCoords(playerPed, entityCoords.x, entityCoords.y, entityCoords.z, false, false, false, false)
                    end,
                }
            end
        end
    end
    
    if #options == 0 then
        options[#options + 1] = { title = "No furniture found nearby", description = "Try moving to an interior", disabled = true }
    end
    
    lib.registerContext({ id = "ogz_admin_furniture_nearby", title = "🪑 Nearby Furniture (" .. found .. ")", menu = "ogz_admin_furniture", options = options })
    lib.showContext("ogz_admin_furniture_nearby")
end

function ViewFurnitureCategories()
    local options = {}
    
    for catId, category in pairs(Furniture.Categories) do
        local modelCount = category.models and #category.models or 0
        
        options[#options + 1] = {
            title = category.label or catId,
            description = string.format("%d models | Pull: %.1fm | Push: %.1fm", 
                modelCount, 
                category.movement and category.movement.pullDistance or Furniture.Defaults.pullDistance,
                category.movement and category.movement.pushDistance or Furniture.Defaults.pushDistance
            ),
            icon = "fas fa-couch",
        }
    end
    
    lib.registerContext({ id = "ogz_admin_furniture_cats", title = "🪑 Furniture Categories", menu = "ogz_admin_furniture", options = options })
    lib.showContext("ogz_admin_furniture_cats")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COMMAND REGISTRATION
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand(Config.Admin.Command, function()
    -- Request fresh admin status from server
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

-- Debug command to check admin status
RegisterCommand("ogz_admin_debug", function()
    print("[OGz PropManager] Current isAdmin:", isAdmin)
    lib.callback('ogz_propmanager:server:CheckAdmin', false, function(result)
        print("[OGz PropManager] Server says admin:", result)
    end)
end, false)

if Config.Admin.Keybind then
    RegisterKeyMapping(Config.Admin.Command, "Open PropManager Admin", "keyboard", Config.Admin.Keybind)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- NOTIFICATION HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:admin:Notify", function(message, type)
    Notify(message, type)
end)
