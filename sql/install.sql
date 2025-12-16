-- ═══════════════════════════════════════════════════════════════════════════
-- OGz PropManager v3.0 - Database Installation
-- Run this SQL before starting the resource OR let it auto-create
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- v2.0 TABLES (Stations)
-- ═══════════════════════════════════════════════════════════════════════════

-- Main stations table
CREATE TABLE IF NOT EXISTS `ogz_propmanager` (
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

-- Production/Activity logs table
CREATE TABLE IF NOT EXISTS `ogz_propmanager_logs` (
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

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 TABLES - STASHES
-- ═══════════════════════════════════════════════════════════════════════════

-- Portable stashes table
CREATE TABLE IF NOT EXISTS `ogz_propmanager_stashes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `stash_id` VARCHAR(100) UNIQUE NOT NULL,    -- Unique ID for ox_inventory (e.g., 'ogz_stash_12345')
    `citizenid` VARCHAR(50) NOT NULL,            -- Owner who placed it
    `stash_type` VARCHAR(50) NOT NULL,           -- Config key from stashes.lua
    `model` VARCHAR(100) NOT NULL,               -- Prop model
    `coords` JSON NOT NULL,                      -- { x, y, z }
    `heading` FLOAT NOT NULL,
    `routing_bucket` INT DEFAULT 0,
    `access_gang` VARCHAR(50) NULL,              -- Gang that can access (if shareWithGang)
    `access_job` VARCHAR(50) NULL,               -- Job that can access (if shareWithJob)
    `custom_access` JSON NULL,                   -- Additional citizenids with access
    `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_stash_id` (`stash_id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_bucket` (`routing_bucket`),
    INDEX `idx_type` (`stash_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 TABLES - LOOTABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Placed lootable props
CREATE TABLE IF NOT EXISTS `ogz_propmanager_lootables` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `loot_type` VARCHAR(50) NOT NULL,            -- Config key from lootables.lua
    `model` VARCHAR(100) NOT NULL,               -- Prop model used
    `coords` JSON NOT NULL,                      -- { x, y, z }
    `heading` FLOAT NOT NULL,
    `routing_bucket` INT DEFAULT 0,
    `last_looted_global` TIMESTAMP NULL,         -- For global cooldowns
    `times_looted` INT DEFAULT 0,                -- Total times looted
    `is_active` BOOLEAN DEFAULT TRUE,            -- For one-time loot tracking
    `placed_by` VARCHAR(50) NULL,                -- Admin/server that placed it
    `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`loot_type`),
    INDEX `idx_bucket` (`routing_bucket`),
    INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Player-specific loot cooldowns
CREATE TABLE IF NOT EXISTS `ogz_propmanager_loot_cooldowns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `lootable_id` INT NOT NULL,                  -- FK to lootables.id
    `citizenid` VARCHAR(50) NOT NULL,
    `looted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_player_loot` (`lootable_id`, `citizenid`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_lootable` (`lootable_id`),
    FOREIGN KEY (`lootable_id`) REFERENCES `ogz_propmanager_lootables`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 TABLES - WORLD PROPS
-- ═══════════════════════════════════════════════════════════════════════════

-- World prop cooldowns (per-player per-location)
CREATE TABLE IF NOT EXISTS `ogz_propmanager_worldprop_cooldowns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `worldprop_id` VARCHAR(50) NOT NULL,         -- Config key from worldprops.lua
    `location_hash` VARCHAR(100) NOT NULL,       -- Hash of coords for unique location
    `last_used` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_player_location` (`citizenid`, `worldprop_id`, `location_hash`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_worldprop` (`worldprop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- World prop stash ownership (for per-player stashes at world locations)
CREATE TABLE IF NOT EXISTS `ogz_propmanager_worldprop_stashes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `stash_id` VARCHAR(100) UNIQUE NOT NULL,     -- Unique ID for ox_inventory
    `citizenid` VARCHAR(50) NOT NULL,
    `worldprop_id` VARCHAR(50) NOT NULL,         -- Config key
    `location_hash` VARCHAR(100) NOT NULL,       -- Hash of coords
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_player_worldstash` (`citizenid`, `worldprop_id`, `location_hash`),
    INDEX `idx_stash_id` (`stash_id`),
    INDEX `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 TABLES - FURNITURE
-- Note: Furniture positions reset on server restart (by design)
-- This table is used for RUNTIME tracking only, not persistence
-- ═══════════════════════════════════════════════════════════════════════════

-- Runtime furniture tracking (cleared on resource start)
-- This table exists mainly for admin tools and debugging
CREATE TABLE IF NOT EXISTS `ogz_propmanager_furniture_runtime` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `entity_hash` VARCHAR(100) NOT NULL,         -- Hash of entity for identification
    `model` VARCHAR(100) NOT NULL,
    `original_coords` JSON NOT NULL,             -- Original position
    `current_coords` JSON NOT NULL,              -- Current moved position
    `heading` FLOAT NOT NULL,
    `routing_bucket` INT DEFAULT 0,
    `moved_by` VARCHAR(50) NOT NULL,             -- Who moved it
    `moved_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_furniture` (`entity_hash`, `routing_bucket`),
    INDEX `idx_bucket` (`routing_bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEWS FOR ADMIN
-- ═══════════════════════════════════════════════════════════════════════════

-- Station overview
CREATE OR REPLACE VIEW `ogz_propmanager_overview` AS
SELECT 
    p.id, p.citizenid, p.station_id, p.durability,
    p.craft_count, p.cooldown_until,
    JSON_UNQUOTE(JSON_EXTRACT(p.coords, '$.x')) AS x,
    JSON_UNQUOTE(JSON_EXTRACT(p.coords, '$.y')) AS y,
    JSON_UNQUOTE(JSON_EXTRACT(p.coords, '$.z')) AS z,
    p.routing_bucket, p.placed_at
FROM `ogz_propmanager` p;

-- Station stats
CREATE OR REPLACE VIEW `ogz_propmanager_stats` AS
SELECT 
    station_id,
    COUNT(*) as total_stations,
    AVG(durability) as avg_durability,
    SUM(craft_count) as total_crafts
FROM `ogz_propmanager`
GROUP BY station_id;

-- Stash overview
CREATE OR REPLACE VIEW `ogz_propmanager_stash_overview` AS
SELECT 
    s.id, s.stash_id, s.citizenid, s.stash_type,
    JSON_UNQUOTE(JSON_EXTRACT(s.coords, '$.x')) AS x,
    JSON_UNQUOTE(JSON_EXTRACT(s.coords, '$.y')) AS y,
    JSON_UNQUOTE(JSON_EXTRACT(s.coords, '$.z')) AS z,
    s.access_gang, s.access_job,
    s.routing_bucket, s.placed_at
FROM `ogz_propmanager_stashes` s;

-- Lootable overview
CREATE OR REPLACE VIEW `ogz_propmanager_lootable_overview` AS
SELECT 
    l.id, l.loot_type, l.model,
    JSON_UNQUOTE(JSON_EXTRACT(l.coords, '$.x')) AS x,
    JSON_UNQUOTE(JSON_EXTRACT(l.coords, '$.y')) AS y,
    JSON_UNQUOTE(JSON_EXTRACT(l.coords, '$.z')) AS z,
    l.times_looted, l.is_active,
    l.routing_bucket, l.placed_at
FROM `ogz_propmanager_lootables` l;
