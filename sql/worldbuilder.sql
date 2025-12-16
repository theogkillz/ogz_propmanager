-- ═══════════════════════════════════════════════════════════════════════════
-- OGz PropManager v3.5 - WORLD BUILDER TABLES
-- Add these to your existing install.sql or run separately
-- ═══════════════════════════════════════════════════════════════════════════

-- Props spawned by admins (persisted)
CREATE TABLE IF NOT EXISTS `ogz_propmanager_world_spawned` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `spawn_id` VARCHAR(100) UNIQUE,              -- Unique identifier
    `model` VARCHAR(100) NOT NULL,               -- Prop model name
    `coords` JSON NOT NULL,                      -- { x, y, z }
    `heading` FLOAT DEFAULT 0.0,
    `routing_bucket` INT DEFAULT 0,
    `interaction_zone` VARCHAR(100),             -- Links to WorldProps.Zones
    `respawn_time` INT DEFAULT 0,                -- Seconds (0 = no respawn)
    `last_harvested` TIMESTAMP NULL,             -- When last harvested
    `is_spawned` BOOLEAN DEFAULT TRUE,           -- Currently visible?
    `group_id` VARCHAR(100),                     -- Spawn group ID
    `placed_by` VARCHAR(50),                     -- Admin citizenid
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_zone` (`interaction_zone`),
    INDEX `idx_group` (`group_id`),
    INDEX `idx_spawned` (`is_spawned`),
    INDEX `idx_bucket` (`routing_bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Native GTA props hidden by admins (persisted)
CREATE TABLE IF NOT EXISTS `ogz_propmanager_world_deleted` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `model` VARCHAR(100) NOT NULL,               -- Model hash or name
    `coords` JSON NOT NULL,                      -- { x, y, z }
    `radius` FLOAT DEFAULT 1.0,                  -- Match radius
    `routing_bucket` INT DEFAULT 0,
    `reason` VARCHAR(255),                       -- Why deleted
    `deleted_by` VARCHAR(50),                    -- Admin citizenid
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_bucket` (`routing_bucket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ═══════════════════════════════════════════════════════════════════════════
-- VIEW FOR ADMIN OVERVIEW
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW `ogz_propmanager_worldbuilder_overview` AS
SELECT 
    s.id,
    s.model,
    JSON_UNQUOTE(JSON_EXTRACT(s.coords, '$.x')) AS x,
    JSON_UNQUOTE(JSON_EXTRACT(s.coords, '$.y')) AS y,
    JSON_UNQUOTE(JSON_EXTRACT(s.coords, '$.z')) AS z,
    s.heading,
    s.interaction_zone,
    s.respawn_time,
    s.is_spawned,
    s.group_id,
    s.placed_by,
    s.created_at
FROM `ogz_propmanager_world_spawned` s;
