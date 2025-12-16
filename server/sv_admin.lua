--[[
    OGz PropManager - Admin Server Handlers
    
    Handles all admin menu callbacks and events
]]

local QBX = exports.qbx_core

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN PERMISSION CHECK
-- ═══════════════════════════════════════════════════════════════════════════

function IsPlayerAdmin(source)
    if not Config.Admin.Enabled then 
        print("[OGz PropManager] Admin menu disabled in config")
        return false 
    end
    
    local player = QBX:GetPlayer(source)
    if not player then 
        print("[OGz PropManager] No player found for source:", source)
        return false 
    end
    
    local citizenid = player.PlayerData.citizenid
    local job = player.PlayerData.job and player.PlayerData.job.name or "none"
    
    print(string.format("[OGz PropManager] === Admin Check ==="))
    print(string.format("[OGz PropManager] Player: %s | Source: %s", GetPlayerName(source), source))
    print(string.format("[OGz PropManager] CitizenID: %s | Job: %s", citizenid, job))
    print(string.format("[OGz PropManager] AllowedCitizenIds: %s", json.encode(Config.Admin.AllowedCitizenIds)))
    
    -- Check specific citizenids FIRST (most specific)
    if Config.Admin.AllowedCitizenIds and #Config.Admin.AllowedCitizenIds > 0 then
        for _, allowedCid in ipairs(Config.Admin.AllowedCitizenIds) do
            print(string.format("[OGz PropManager] Comparing: '%s' == '%s' ? %s", citizenid, allowedCid, tostring(citizenid == allowedCid)))
            if citizenid == allowedCid then 
                print("[OGz PropManager] ✅ Admin granted via CitizenID:", citizenid)
                return true 
            end
        end
    end
    
    -- Check ace permissions / groups
    if Config.Admin.AllowedGroups and #Config.Admin.AllowedGroups > 0 then
        for _, allowedGroup in ipairs(Config.Admin.AllowedGroups) do
            -- Try QBX method
            local hasGroup = false
            pcall(function()
                hasGroup = QBX:HasPermission(source, allowedGroup)
            end)
            if hasGroup then 
                print("[OGz PropManager] ✅ Admin granted via QBX group:", allowedGroup)
                return true 
            end
            
            -- Try ace permission
            if IsPlayerAceAllowed(source, "group." .. allowedGroup) then
                print("[OGz PropManager] ✅ Admin granted via ace group:", allowedGroup)
                return true
            end
        end
    end
    
    -- Check jobs
    if Config.Admin.AllowedJobs and #Config.Admin.AllowedJobs > 0 then
        for _, allowedJob in ipairs(Config.Admin.AllowedJobs) do
            if job == allowedJob then 
                print("[OGz PropManager] ✅ Admin granted via job:", job)
                return true 
            end
        end
    end
    
    print("[OGz PropManager] ❌ Admin denied for:", citizenid)
    return false
end

-- Debug command for server console
RegisterCommand("ogz_check_admin", function(source, args)
    local targetSource = tonumber(args[1]) or source
    if targetSource == 0 then
        print("[OGz PropManager] Usage: ogz_check_admin [player_id]")
        return
    end
    local result = IsPlayerAdmin(targetSource)
    print(string.format("[OGz PropManager] Admin check for %s: %s", targetSource, tostring(result)))
end, true)  -- Restrict to console/rcon

-- Send admin status on player load
RegisterNetEvent("QBCore:Server:OnPlayerLoaded", function()
    local source = source
    Wait(2000)
    TriggerClientEvent("ogz_propmanager:client:SetAdmin", source, IsPlayerAdmin(source))
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

-- Real-time admin check
lib.callback.register("ogz_propmanager:server:CheckAdmin", function(source)
    local result = IsPlayerAdmin(source)
    print("[OGz PropManager] CheckAdmin callback for source:", source, "Result:", result)
    return result
end)

lib.callback.register("ogz_propmanager:admin:GetAllStations", function(source)
    if not IsPlayerAdmin(source) then return {} end
    return Database_GetAllStations()
end)

lib.callback.register("ogz_propmanager:admin:SearchStations", function(source, citizenid, stationId)
    if not IsPlayerAdmin(source) then return {} end
    
    local stations = Database_GetAllStations()
    local filtered = {}
    
    for _, station in ipairs(stations) do
        local match = true
        if citizenid and citizenid ~= "" and station.citizenid ~= citizenid then match = false end
        if stationId and stationId ~= "" and station.station_id ~= stationId then match = false end
        if match then filtered[#filtered + 1] = station end
    end
    
    return filtered
end)

lib.callback.register("ogz_propmanager:admin:GetStationLogs", function(source, propId)
    if not IsPlayerAdmin(source) then return {} end
    return Database_GetLogs({ propId = propId, limit = 50 })
end)

lib.callback.register("ogz_propmanager:admin:GetRecentLogs", function(source, limit)
    if not IsPlayerAdmin(source) then return {} end
    return Database_GetLogs({ limit = limit or 50 })
end)

lib.callback.register("ogz_propmanager:admin:GetLogsByType", function(source, actionType, limit)
    if not IsPlayerAdmin(source) then return {} end
    return Database_GetLogs({ action = actionType, limit = limit or 50 })
end)

lib.callback.register("ogz_propmanager:admin:GetStats", function(source)
    if not IsPlayerAdmin(source) then return nil end
    
    local stations = Database_GetAllStations()
    local stationCounts = Database_GetStationCounts()
    local topCrafters = Database_GetTopCrafters(10)
    
    local totalCrafts = MySQL.scalar.await([[SELECT COUNT(*) FROM `]] .. Config.Database.TablePrefix .. [[_logs` WHERE action = 'craft']])
    local uniqueCrafters = MySQL.scalar.await([[SELECT COUNT(DISTINCT citizenid) FROM `]] .. Config.Database.TablePrefix .. [[_logs` WHERE action = 'craft']])
    
    return {
        totalStations = #stations,
        totalCrafts = totalCrafts or 0,
        uniqueCrafters = uniqueCrafters or 0,
        stationCounts = stationCounts,
        topCrafters = topCrafters,
    }
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.5 WORLD BUILDER CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:server:GetDeletedProps", function(source)
    if not IsPlayerAdmin(source) then return {} end
    
    local tablePrefix = Config.Database.TablePrefix or "ogz_propmanager"
    local results = MySQL.query.await([[
        SELECT id, model, coords, radius, reason, deleted_by, created_at 
        FROM `]] .. tablePrefix .. [[_world_deleted`
        ORDER BY id DESC
    ]])
    
    return results or {}
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:admin:SetDurability", function(propId, durability)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    Database_UpdateDurability(propId, durability)
    
    -- Log the action
    local player = QBX:GetPlayer(source)
    Database_Log(propId, player.PlayerData.citizenid, "admin_repair", nil, nil, nil, nil, { newDurability = durability, adminSource = source })
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Durability set to " .. durability .. "%", "success")
    
    -- Notify all clients to refresh this prop's durability display
    TriggerClientEvent("ogz_propmanager:client:UpdateDurability", -1, propId, durability)
end)

RegisterNetEvent("ogz_propmanager:admin:ClearCooldown", function(propId)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    Database_ClearCooldown(propId)
    
    local player = QBX:GetPlayer(source)
    Database_Log(propId, player.PlayerData.citizenid, "admin_cooldown_clear", nil, nil, nil, nil, { adminSource = source })
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Cooldown cleared!", "success")
end)

RegisterNetEvent("ogz_propmanager:admin:RemoveStation", function(propId)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local station = Database_GetStation(propId)
    if not station then return end
    
    local player = QBX:GetPlayer(source)
    Database_Log(propId, player.PlayerData.citizenid, "admin_remove", station.station_id, nil, nil, nil, { originalOwner = station.citizenid, adminSource = source })
    
    Database_DeleteStation(propId)
    
    -- Notify all clients to remove this prop
    TriggerClientEvent("ogz_propmanager:client:RemoveProp", -1, propId)
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Station removed!", "success")
end)

RegisterNetEvent("ogz_propmanager:admin:ClearOldLogs", function(days)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local deleted = Database_ClearOldLogs(days)
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Cleared " .. deleted .. " old log entries.", "success")
end)

RegisterNetEvent("ogz_propmanager:admin:GiveItem", function(targetId, itemName, amount)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local success = exports.ox_inventory:AddItem(targetId, itemName, amount)
    if success then
        TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Gave " .. amount .. "x " .. itemName .. " to player " .. targetId, "success")
    else
        TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Failed to give item!", "error")
    end
end)

RegisterNetEvent("ogz_propmanager:admin:RepairAll", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    MySQL.update.await([[UPDATE `]] .. Config.Database.TablePrefix .. [[` SET durability = 100]])
    
    local player = QBX:GetPlayer(source)
    Database_Log(nil, player.PlayerData.citizenid, "admin_repair_all", nil, nil, nil, nil, { adminSource = source })
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "All stations repaired to 100%!", "success")
    TriggerClientEvent("ogz_propmanager:client:RefreshAllDurability", -1)
end)

RegisterNetEvent("ogz_propmanager:admin:ClearAllCooldowns", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    MySQL.update.await([[UPDATE `]] .. Config.Database.TablePrefix .. [[` SET cooldown_until = NULL, craft_count = 0]])
    
    local player = QBX:GetPlayer(source)
    Database_Log(nil, player.PlayerData.citizenid, "admin_cooldown_clear_all", nil, nil, nil, nil, { adminSource = source })
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "All cooldowns cleared!", "success")
end)

RegisterNetEvent("ogz_propmanager:admin:RefreshAllProps", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    -- Get all players and send them updated prop data
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local bucket = GetPlayerRoutingBucket(playerId)
        local props = Database_GetStationsByBucket(bucket)
        TriggerClientEvent("ogz_propmanager:client:RefreshProps", playerId, props)
    end
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "All props refreshed for all players!", "success")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 STASH ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:admin:GetAllStashes", function(source)
    if not IsPlayerAdmin(source) then return nil end
    return Database_GetAllStashes and Database_GetAllStashes() or {}
end)

lib.callback.register("ogz_propmanager:admin:SearchStashes", function(source, citizenid)
    if not IsPlayerAdmin(source) then return nil end
    return Database_GetStashesByCitizen and Database_GetStashesByCitizen(citizenid) or {}
end)

lib.callback.register("ogz_propmanager:admin:GetStashStats", function(source)
    if not IsPlayerAdmin(source) then return nil end
    
    local stats = {}
    local allStashes = Database_GetAllStashes and Database_GetAllStashes() or {}
    
    for _, stash in ipairs(allStashes) do
        stats[stash.stash_type] = (stats[stash.stash_type] or 0) + 1
    end
    
    return stats
end)

RegisterNetEvent("ogz_propmanager:admin:OpenStash", function(stashId)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    -- Register stash if needed (in case it wasn't registered yet)
    local stashData = nil
    if Database_GetStashByStashId then
        stashData = Database_GetStashByStashId(stashId)
    end
    
    if stashData then
        local stashConfig = Stashes[stashData.stash_type]
        if stashConfig then
            local slots = stashConfig.stash and stashConfig.stash.slots or Config.Stashes.DefaultSlots
            local maxWeight = stashConfig.stash and stashConfig.stash.maxWeight or Config.Stashes.DefaultMaxWeight
            exports.ox_inventory:RegisterStash(stashId, stashConfig.label .. " (Admin)", slots, maxWeight)
        end
    end
    
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
end)

RegisterNetEvent("ogz_propmanager:admin:RemoveStash", function(propId)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local stashData = Database_GetStash and Database_GetStash(propId) or nil
    if not stashData then return end
    
    if Database_DeleteStash then
        Database_DeleteStash(propId)
    end
    
    local player = QBX:GetPlayer(source)
    if player then
        Database_Log(propId, player.PlayerData.citizenid, "admin_remove_stash", stashData.stash_type, nil, nil, nil, 
            { originalOwner = stashData.citizenid, stash_id = stashData.stash_id }, stashData.coords)
    end
    
    -- Notify all clients to remove
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerRoutingBucket(playerId) == (stashData.routing_bucket or 0) then
            TriggerClientEvent("ogz_propmanager:client:RemoveStash", playerId, propId)
        end
    end
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Stash #" .. propId .. " removed!", "success")
end)

RegisterNetEvent("ogz_propmanager:admin:RemoveAllStashes", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local allStashes = Database_GetAllStashes and Database_GetAllStashes() or {}
    local count = #allStashes
    
    -- Delete all from database
    MySQL.update.await([[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_stashes`]])
    
    -- Notify all clients to refresh (they'll get empty list)
    for _, playerId in ipairs(GetPlayers()) do
        local bucket = GetPlayerRoutingBucket(playerId)
        TriggerClientEvent("ogz_propmanager:client:LoadStashes", playerId, {})
    end
    
    local player = QBX:GetPlayer(source)
    if player then
        Database_Log(nil, player.PlayerData.citizenid, "admin_remove_all_stashes", nil, nil, count, nil, nil, nil)
    end
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Removed " .. count .. " stashes!", "success")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 LOOTABLE ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register("ogz_propmanager:admin:GetAllLootables", function(source)
    if not IsPlayerAdmin(source) then return nil end
    return Database_GetAllLootables and Database_GetAllLootables() or {}
end)

RegisterNetEvent("ogz_propmanager:admin:ResetLootableCooldowns", function(propId)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    if Database_ClearPlayerCooldowns then
        Database_ClearPlayerCooldowns(propId)
    end
    
    -- Also reset global cooldown
    MySQL.update.await([[UPDATE `]] .. Config.Database.TablePrefix .. [[_lootables` SET last_looted_global = NULL WHERE id = ?]], { propId })
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Cooldowns reset for lootable #" .. propId, "success")
end)

RegisterNetEvent("ogz_propmanager:admin:ResetAllLootCooldowns", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    MySQL.update.await([[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_loot_cooldowns`]])
    MySQL.update.await([[UPDATE `]] .. Config.Database.TablePrefix .. [[_lootables` SET last_looted_global = NULL]])
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "All loot cooldowns reset!", "success")
end)

RegisterNetEvent("ogz_propmanager:admin:ToggleLootable", function(propId, active)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    MySQL.update.await([[UPDATE `]] .. Config.Database.TablePrefix .. [[_lootables` SET is_active = ? WHERE id = ?]], { active, propId })
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Lootable #" .. propId .. " " .. (active and "activated" or "deactivated"), "success")
end)

RegisterNetEvent("ogz_propmanager:admin:RemoveAllLootables", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local allLootables = Database_GetAllLootables and Database_GetAllLootables() or {}
    local count = #allLootables
    
    MySQL.update.await([[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_lootables`]])
    MySQL.update.await([[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_loot_cooldowns`]])
    
    -- Notify all clients
    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent("ogz_propmanager:client:LoadLootables", playerId, {})
    end
    
    local player = QBX:GetPlayer(source)
    if player then
        Database_Log(nil, player.PlayerData.citizenid, "admin_remove_all_lootables", nil, nil, count, nil, nil, nil)
    end
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Removed " .. count .. " lootables!", "success")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- WORLD PROPS ADMIN (Full v3.4 Support)
-- ═══════════════════════════════════════════════════════════════════════════

-- Reset ALL world prop cooldowns
RegisterNetEvent("ogz_propmanager:admin:ResetAllWorldPropCooldowns", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local result = MySQL.update.await([[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns`]])
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "All world prop cooldowns reset! (" .. (result or 0) .. " entries cleared)", "success")
    print("[OGz PropManager] Admin reset all world prop cooldowns")
end)

-- Reset cooldowns for a specific zone
RegisterNetEvent("ogz_propmanager:admin:ResetZoneCooldowns", function(zoneId)
    local source = source
    if not IsPlayerAdmin(source) then return end
    if not zoneId then return end
    
    local result = MySQL.update.await(
        [[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns` WHERE worldprop_id = ?]],
        { zoneId }
    )
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, 
        string.format("Zone '%s' cooldowns reset! (%d entries cleared)", zoneId, result or 0), "success")
    print("[OGz PropManager] Admin reset cooldowns for zone:", zoneId)
end)

-- Reset cooldowns for a specific player
RegisterNetEvent("ogz_propmanager:admin:ResetPlayerCooldowns", function(targetPlayerId)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local targetPlayer = exports.qbx_core:GetPlayer(targetPlayerId)
    if not targetPlayer then
        TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Player not found or offline", "error")
        return
    end
    
    local citizenid = targetPlayer.PlayerData.citizenid
    
    local result = MySQL.update.await(
        [[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns` WHERE citizenid = ?]],
        { citizenid }
    )
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, 
        string.format("Cooldowns reset for player %s! (%d entries cleared)", targetPlayerId, result or 0), "success")
    print("[OGz PropManager] Admin reset cooldowns for player:", citizenid)
end)

-- Reset only global cooldowns
RegisterNetEvent("ogz_propmanager:admin:ResetGlobalCooldowns", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local result = MySQL.update.await(
        [[DELETE FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns` WHERE citizenid = 'GLOBAL']]
    )
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, 
        string.format("Global cooldowns reset! (%d entries cleared)", result or 0), "success")
    print("[OGz PropManager] Admin reset global cooldowns")
end)

-- Get cooldown statistics
RegisterNetEvent("ogz_propmanager:admin:GetCooldownStats", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local totalCooldowns = MySQL.scalar.await(
        [[SELECT COUNT(*) FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns`]]
    ) or 0
    
    local playerCooldowns = MySQL.scalar.await(
        [[SELECT COUNT(DISTINCT citizenid) FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns` WHERE citizenid != 'GLOBAL']]
    ) or 0
    
    local globalCooldowns = MySQL.scalar.await(
        [[SELECT COUNT(*) FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns` WHERE citizenid = 'GLOBAL']]
    ) or 0
    
    local zoneCounts = MySQL.query.await(
        [[SELECT worldprop_id, COUNT(*) as count FROM `]] .. Config.Database.TablePrefix .. [[_worldprop_cooldowns` GROUP BY worldprop_id ORDER BY count DESC LIMIT 5]]
    ) or {}
    
    -- Build stats message
    local statsMsg = string.format(
        "📊 Cooldown Stats:\n• Total entries: %d\n• Unique players: %d\n• Global entries: %d",
        totalCooldowns, playerCooldowns, globalCooldowns
    )
    
    if #zoneCounts > 0 then
        statsMsg = statsMsg .. "\n• Top zones:"
        for _, zone in ipairs(zoneCounts) do
            statsMsg = statsMsg .. string.format("\n  - %s: %d", zone.worldprop_id, zone.count)
        end
    end
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, statsMsg, "info")
end)

-- Force reload world props for all clients
RegisterNetEvent("ogz_propmanager:admin:ReloadWorldPropsAllClients", function()
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    TriggerClientEvent("ogz_propmanager:client:ReloadWorldProps", -1)
    
    TriggerClientEvent("ogz_propmanager:admin:Notify", source, "World props reload triggered for all clients!", "success")
    print("[OGz PropManager] Admin triggered world props reload for all clients")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.1 GIVE ITEMS WITH METADATA
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:admin:GiveMetadataItem", function(targetId, itemName, amount, metadata)
    local source = source
    if not IsPlayerAdmin(source) then return end
    
    local targetSource = tonumber(targetId)
    if not targetSource then
        TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Invalid player ID", "error")
        return
    end
    
    -- Check if player is online
    local targetPlayer = QBX:GetPlayer(targetSource)
    if not targetPlayer then
        TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Player not found or offline", "error")
        return
    end
    
    -- Clean up metadata (remove empty values)
    local cleanMetadata = {}
    if metadata then
        if metadata.purity and metadata.purity > 0 then
            cleanMetadata.purity = metadata.purity
        end
        if metadata.quality and metadata.quality > 0 then
            cleanMetadata.quality = metadata.quality
        end
        if metadata.durability and metadata.durability > 0 then
            cleanMetadata.durability = metadata.durability
        end
    end
    
    -- Give the item
    local success = exports.ox_inventory:AddItem(targetSource, itemName, amount, cleanMetadata)
    
    if success then
        -- Build notification message
        local metaStr = ""
        if cleanMetadata.purity then
            metaStr = metaStr .. " | Purity: " .. cleanMetadata.purity .. "%"
        end
        if cleanMetadata.quality then
            metaStr = metaStr .. " | Quality: " .. cleanMetadata.quality .. "%"
        end
        
        TriggerClientEvent("ogz_propmanager:admin:Notify", source, 
            string.format("Gave %dx %s to Player %s%s", amount, itemName, targetId, metaStr), "success")
        
        -- Notify target player
        TriggerClientEvent("ogz_propmanager:client:Notify", targetSource,
            string.format("Admin gave you %dx %s%s", amount, itemName, metaStr), "info")
        
        -- Log it
        local adminPlayer = QBX:GetPlayer(source)
        Database_Log(nil, adminPlayer.PlayerData.citizenid, "admin_give_item", itemName, itemName, amount, nil, {
            targetId = targetId,
            targetCitizenId = targetPlayer.PlayerData.citizenid,
            metadata = cleanMetadata,
        }, nil)
        
        print(string.format("[OGz PropManager] Admin %s gave %dx %s to player %s (metadata: %s)", 
            adminPlayer.PlayerData.citizenid, amount, itemName, targetId, json.encode(cleanMetadata)))
    else
        TriggerClientEvent("ogz_propmanager:admin:Notify", source, "Failed to give item (inventory full?)", "error")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- CONSOLE COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("ogz_db_stats", function(source)
    if source ~= 0 then return end
    
    local stations = Database_GetAllStations()
    local counts = Database_GetStationCounts()
    
    print("[OGz PropManager] Database Statistics:")
    print("  Total Stations: " .. #stations)
    for _, sc in ipairs(counts) do
        print("    - " .. sc.station_id .. ": " .. sc.count)
    end
end, true)

RegisterCommand("ogz_clear_logs", function(source, args)
    if source ~= 0 then return end
    
    local days = tonumber(args[1]) or 30
    local deleted = Database_ClearOldLogs(days)
    print("[OGz PropManager] Cleared " .. deleted .. " logs older than " .. days .. " days")
end, true)

print("^2[OGz PropManager]^0 Admin Server Handlers loaded!")
