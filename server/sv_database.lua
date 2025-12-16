--[[
    OGz PropManager - Database Operations
    
    Tables:
    - ogz_propmanager (stations) [v2.0]
    - ogz_propmanager_logs (production/activity logs) [v2.0]
    - ogz_propmanager_stashes (portable stashes) [v3.0]
    - ogz_propmanager_lootables (lootable containers) [v3.0]
    - ogz_propmanager_loot_cooldowns (player loot cooldowns) [v3.0]
    - ogz_propmanager_worldprop_cooldowns (world prop cooldowns) [v3.0]
    - ogz_propmanager_worldprop_stashes (world prop stashes) [v3.0]
    - ogz_propmanager_furniture_runtime (furniture tracking) [v3.0]
]]

local tablePrefix = Config.Database.TablePrefix

-- ═══════════════════════════════════════════════════════════════════════════
-- TABLE INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

function Database_Init()
    -- ───────────────────────────────────────────────────────────────────────
    -- v2.0 TABLES
    -- ───────────────────────────────────────────────────────────────────────
    
    -- Main stations table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `station_id` VARCHAR(50) NOT NULL,
            `model` VARCHAR(100) NOT NULL,
            `coords` JSON NOT NULL,
            `heading` FLOAT NOT NULL,
            `routing_bucket` INT DEFAULT 0,
            `durability` INT DEFAULT 100,
            `craft_count` INT DEFAULT 0,
            `last_craft` TIMESTAMP NULL,
            `cooldown_until` TIMESTAMP NULL,
            `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_bucket` (`routing_bucket`),
            INDEX `idx_station` (`station_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Ensure heading column exists (for tables created before v2)
    MySQL.query([[
        ALTER TABLE `]] .. tablePrefix .. [[` 
        MODIFY COLUMN `heading` FLOAT DEFAULT 0.0
    ]])
    
    -- Production/Activity logs table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_logs` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `prop_id` INT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `action` VARCHAR(50) NOT NULL,
            `station_id` VARCHAR(50) NULL,
            `item_crafted` VARCHAR(100) NULL,
            `quantity` INT DEFAULT 1,
            `event_type` VARCHAR(50) NULL,
            `details` JSON NULL,
            `coords` JSON NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_action` (`action`),
            INDEX `idx_prop` (`prop_id`),
            INDEX `idx_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- ───────────────────────────────────────────────────────────────────────
    -- v3.0 TABLES - STASHES
    -- ───────────────────────────────────────────────────────────────────────
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_stashes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `stash_id` VARCHAR(100) UNIQUE NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `stash_type` VARCHAR(50) NOT NULL,
            `model` VARCHAR(100) NOT NULL,
            `coords` JSON NOT NULL,
            `heading` FLOAT NOT NULL,
            `routing_bucket` INT DEFAULT 0,
            `access_gang` VARCHAR(50) NULL,
            `access_job` VARCHAR(50) NULL,
            `custom_access` JSON NULL,
            `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_stash_id` (`stash_id`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_bucket` (`routing_bucket`),
            INDEX `idx_type` (`stash_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- ───────────────────────────────────────────────────────────────────────
    -- v3.0 TABLES - LOOTABLES
    -- ───────────────────────────────────────────────────────────────────────
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_lootables` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `loot_type` VARCHAR(50) NOT NULL,
            `model` VARCHAR(100) NOT NULL,
            `coords` JSON NOT NULL,
            `heading` FLOAT NOT NULL,
            `routing_bucket` INT DEFAULT 0,
            `last_looted_global` TIMESTAMP NULL,
            `times_looted` INT DEFAULT 0,
            `is_active` BOOLEAN DEFAULT TRUE,
            `placed_by` VARCHAR(50) NULL,
            `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_type` (`loot_type`),
            INDEX `idx_bucket` (`routing_bucket`),
            INDEX `idx_active` (`is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Player-specific loot cooldowns
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_loot_cooldowns` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `lootable_id` INT NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `looted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_player_loot` (`lootable_id`, `citizenid`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_lootable` (`lootable_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- ───────────────────────────────────────────────────────────────────────
    -- v3.0 TABLES - WORLD PROPS
    -- ───────────────────────────────────────────────────────────────────────
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_worldprop_cooldowns` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `worldprop_id` VARCHAR(50) NOT NULL,
            `location_hash` VARCHAR(100) NOT NULL,
            `last_used` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_player_location` (`citizenid`, `worldprop_id`, `location_hash`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_worldprop` (`worldprop_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_worldprop_stashes` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `stash_id` VARCHAR(100) UNIQUE NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `worldprop_id` VARCHAR(50) NOT NULL,
            `location_hash` VARCHAR(100) NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_player_worldstash` (`citizenid`, `worldprop_id`, `location_hash`),
            INDEX `idx_stash_id` (`stash_id`),
            INDEX `idx_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- ───────────────────────────────────────────────────────────────────────
    -- v3.0 TABLES - FURNITURE (Runtime tracking only)
    -- ───────────────────────────────────────────────────────────────────────
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `]] .. tablePrefix .. [[_furniture_runtime` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `entity_hash` VARCHAR(100) NOT NULL,
            `model` VARCHAR(100) NOT NULL,
            `original_coords` JSON NOT NULL,
            `current_coords` JSON NOT NULL,
            `heading` FLOAT NOT NULL,
            `routing_bucket` INT DEFAULT 0,
            `moved_by` VARCHAR(50) NOT NULL,
            `moved_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `unique_furniture` (`entity_hash`, `routing_bucket`),
            INDEX `idx_bucket` (`routing_bucket`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Clear furniture runtime on resource start (by design)
    MySQL.query([[DELETE FROM `]] .. tablePrefix .. [[_furniture_runtime`]])
    
    print("[OGz PropManager v3.0] Database tables initialized (v2.0 + v3.0)")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

---Insert new station
function Database_InsertStation(citizenid, stationId, model, coords, heading, bucket, durability)
    -- Ensure heading is a valid number
    local safeHeading = tonumber(heading) or 0.0
    
    print(string.format("[OGz PropManager] DB Insert - Station: %s, Heading: %s (raw: %s)", stationId, safeHeading, tostring(heading)))
    
    return MySQL.insert.await([[
        INSERT INTO `]] .. tablePrefix .. [[` 
        (citizenid, station_id, model, coords, heading, routing_bucket, durability)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { citizenid, stationId, model, json.encode(coords), safeHeading, bucket or 0, durability or 100 })
end

---Get station by ID
function Database_GetStation(propId)
    local result = MySQL.single.await([[SELECT * FROM `]] .. tablePrefix .. [[` WHERE id = ?]], { propId })
    if result then result.coords = json.decode(result.coords) end
    return result
end

---Get stations by bucket
function Database_GetStationsByBucket(bucket)
    local result = MySQL.query.await([[SELECT * FROM `]] .. tablePrefix .. [[` WHERE routing_bucket = ?]], { bucket })
    for _, row in ipairs(result or {}) do row.coords = json.decode(row.coords) end
    return result or {}
end

---Get stations by citizen
function Database_GetStationsByCitizen(citizenid)
    local result = MySQL.query.await([[SELECT * FROM `]] .. tablePrefix .. [[` WHERE citizenid = ?]], { citizenid })
    for _, row in ipairs(result or {}) do row.coords = json.decode(row.coords) end
    return result or {}
end

---Count stations by type for citizen
function Database_CountStationsByType(citizenid, stationId)
    return MySQL.scalar.await([[SELECT COUNT(*) FROM `]] .. tablePrefix .. [[` WHERE citizenid = ? AND station_id = ?]], { citizenid, stationId }) or 0
end

---Get all stations
function Database_GetAllStations()
    local result = MySQL.query.await([[SELECT * FROM `]] .. tablePrefix .. [[`]])
    for _, row in ipairs(result or {}) do row.coords = json.decode(row.coords) end
    return result or {}
end

---Delete station
function Database_DeleteStation(propId)
    return MySQL.update.await([[DELETE FROM `]] .. tablePrefix .. [[` WHERE id = ?]], { propId }) > 0
end

---Delete all stations by citizen
function Database_DeleteStationsByCitizen(citizenid)
    return MySQL.update.await([[DELETE FROM `]] .. tablePrefix .. [[` WHERE citizenid = ?]], { citizenid })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DURABILITY OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

---Update station durability
function Database_UpdateDurability(propId, durability)
    return MySQL.update.await([[UPDATE `]] .. tablePrefix .. [[` SET durability = ? WHERE id = ?]], { math.max(0, math.min(100, durability)), propId })
end

---Reduce durability by amount
function Database_ReduceDurability(propId, amount)
    return MySQL.update.await([[UPDATE `]] .. tablePrefix .. [[` SET durability = GREATEST(0, durability - ?) WHERE id = ?]], { amount, propId })
end

---Get station durability
function Database_GetDurability(propId)
    return MySQL.scalar.await([[SELECT durability FROM `]] .. tablePrefix .. [[` WHERE id = ?]], { propId }) or 0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

---Update craft count and check cooldown
function Database_IncrementCraftCount(propId, maxCrafts, cooldownSeconds)
    -- Increment craft count
    MySQL.update.await([[
        UPDATE `]] .. tablePrefix .. [[` 
        SET craft_count = craft_count + 1, last_craft = NOW() 
        WHERE id = ?
    ]], { propId })
    
    -- Check if cooldown needed
    local craftCount = MySQL.scalar.await([[SELECT craft_count FROM `]] .. tablePrefix .. [[` WHERE id = ?]], { propId })
    
    if craftCount >= maxCrafts then
        -- Set cooldown and reset count
        MySQL.update.await([[
            UPDATE `]] .. tablePrefix .. [[` 
            SET cooldown_until = DATE_ADD(NOW(), INTERVAL ? SECOND), craft_count = 0 
            WHERE id = ?
        ]], { cooldownSeconds, propId })
        return true, cooldownSeconds  -- Cooldown started
    end
    
    return false, 0
end

---Check if station is on cooldown
function Database_IsOnCooldown(propId)
    local result = MySQL.single.await([[
        SELECT cooldown_until, TIMESTAMPDIFF(SECOND, NOW(), cooldown_until) as remaining 
        FROM `]] .. tablePrefix .. [[` WHERE id = ?
    ]], { propId })
    
    if result and result.cooldown_until and result.remaining > 0 then
        return true, result.remaining
    end
    return false, 0
end

---Clear cooldown
function Database_ClearCooldown(propId)
    return MySQL.update.await([[UPDATE `]] .. tablePrefix .. [[` SET cooldown_until = NULL, craft_count = 0 WHERE id = ?]], { propId })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOGGING OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

---Log an action
function Database_Log(propId, citizenid, action, stationId, itemCrafted, quantity, eventType, details, coords)
    if not Config.Logging.Enabled then return end
    
    MySQL.insert([[
        INSERT INTO `]] .. tablePrefix .. [[_logs` 
        (prop_id, citizenid, action, station_id, item_crafted, quantity, event_type, details, coords)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], { 
        propId, citizenid, action, stationId, itemCrafted, 
        quantity or 1, eventType, 
        details and json.encode(details) or nil,
        coords and json.encode(coords) or nil
    })
end

---Get logs with filters
function Database_GetLogs(filters)
    local query = [[SELECT * FROM `]] .. tablePrefix .. [[_logs` WHERE 1=1]]
    local params = {}
    
    if filters then
        if filters.citizenid then query = query .. " AND citizenid = ?" table.insert(params, filters.citizenid) end
        if filters.action then query = query .. " AND action = ?" table.insert(params, filters.action) end
        if filters.propId then query = query .. " AND prop_id = ?" table.insert(params, filters.propId) end
        if filters.stationId then query = query .. " AND station_id = ?" table.insert(params, filters.stationId) end
        if filters.startDate then query = query .. " AND created_at >= ?" table.insert(params, filters.startDate) end
        if filters.endDate then query = query .. " AND created_at <= ?" table.insert(params, filters.endDate) end
    end
    
    query = query .. " ORDER BY created_at DESC"
    if filters and filters.limit then query = query .. " LIMIT " .. filters.limit end
    
    local result = MySQL.query.await(query, params)
    for _, row in ipairs(result or {}) do
        if row.details then row.details = json.decode(row.details) end
        if row.coords then row.coords = json.decode(row.coords) end
    end
    return result or {}
end

---Get crafting stats for a player
function Database_GetPlayerStats(citizenid)
    return MySQL.single.await([[
        SELECT 
            COUNT(*) as total_crafts,
            COUNT(DISTINCT station_id) as unique_stations,
            COUNT(DISTINCT item_crafted) as unique_items
        FROM `]] .. tablePrefix .. [[_logs` 
        WHERE citizenid = ? AND action = 'craft'
    ]], { citizenid })
end

---Clear old logs
function Database_ClearOldLogs(daysOld)
    if daysOld <= 0 then return 0 end
    return MySQL.update.await([[
        DELETE FROM `]] .. tablePrefix .. [[_logs` 
        WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)
    ]], { daysOld })
end

---Clear all logs
function Database_ClearAllLogs()
    return MySQL.update.await([[DELETE FROM `]] .. tablePrefix .. [[_logs`]])
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN OPERATIONS
-- ═══════════════════════════════════════════════════════════════════════════

---Get station counts by type
function Database_GetStationCounts()
    return MySQL.query.await([[
        SELECT station_id, COUNT(*) as count 
        FROM `]] .. tablePrefix .. [[` 
        GROUP BY station_id
    ]]) or {}
end

---Get top crafters
function Database_GetTopCrafters(limit)
    return MySQL.query.await([[
        SELECT citizenid, COUNT(*) as craft_count 
        FROM `]] .. tablePrefix .. [[_logs` 
        WHERE action = 'craft'
        GROUP BY citizenid 
        ORDER BY craft_count DESC 
        LIMIT ?
    ]], { limit or 10 }) or {}
end

---Get recent activity
function Database_GetRecentActivity(limit)
    return Database_GetLogs({ limit = limit or 50 })
end

-- ═══════════════════════════════════════════════════════════════════════════
-- INITIALIZE
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1000)
    Database_Init()
end)
