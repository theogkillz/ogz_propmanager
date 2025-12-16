--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║              OGz PropManager v3.1 - Command Reference                     ║
    ║                                                                           ║
    ║  All available commands organized by system                               ║
    ║  Copy desired commands to your server.cfg or register in-game             ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN COMMANDS (Requires admin permission)
-- ═══════════════════════════════════════════════════════════════════════════

/propadmin                      -- Opens main admin menu (all systems)
/propadmin stations             -- Jump to stations submenu
/propadmin stashes              -- Jump to stashes submenu  
/propadmin lootables            -- Jump to lootables submenu
/propadmin worldprops           -- Jump to world props submenu
/propadmin furniture            -- Jump to furniture submenu

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION COMMANDS (v2.0)
-- ═══════════════════════════════════════════════════════════════════════════

/placestation [type]            -- Place a station (opens menu if no type)
/removestation                  -- Remove nearest station (admin)
/repairstation                  -- Repair nearest station
/stationinfo                    -- Show info about nearest station
/liststations                   -- List all placed stations (admin)

-- ═══════════════════════════════════════════════════════════════════════════
-- STASH COMMANDS (v3.0)
-- ═══════════════════════════════════════════════════════════════════════════

/placestash [type]              -- Place a stash (opens menu if no type)
/removestash                    -- Remove nearest stash you own
/stashinfo                      -- Show info about nearest stash
/transferstash [citizenid]      -- Transfer stash ownership
/liststashes                    -- List all stashes (admin)

-- ═══════════════════════════════════════════════════════════════════════════
-- LOOTABLE COMMANDS (v3.0) - Admin Only
-- ═══════════════════════════════════════════════════════════════════════════

/spawnlootable [type]           -- Spawn a lootable prop
/removelootable                 -- Remove nearest lootable
/resetlootable                  -- Reset nearest lootable cooldown
/resetalllootables              -- Reset ALL lootable cooldowns
/listlootables                  -- List all active lootables

-- ═══════════════════════════════════════════════════════════════════════════
-- WORLD PROPS COMMANDS (v3.0)
-- ═══════════════════════════════════════════════════════════════════════════

/worldpropinfo                  -- Show info about nearest world prop
/resetworldpropcooldown [id]    -- Reset cooldown for specific location (admin)
/resetallworldprops             -- Reset ALL world prop cooldowns (admin)

-- ═══════════════════════════════════════════════════════════════════════════
-- FURNITURE COMMANDS (v3.0)
-- ═══════════════════════════════════════════════════════════════════════════

/resetfurniture                 -- Reset all moved furniture to original positions
/furnitureinfo                  -- Show furniture system status
/togglefurniture                -- Enable/disable furniture movement (admin)

-- ═══════════════════════════════════════════════════════════════════════════
-- PROCESSING COMMANDS (v3.1) - Drug Scales
-- ═══════════════════════════════════════════════════════════════════════════

/ogz_spawn_scale [type]         -- Spawn test scale with targeting
                                -- Types: drug_scale, bulk_scale, rolling_table, packaging_station

/ogz_process_test [type]        -- Open processing menu without physical station
                                -- Types: drug_scale, bulk_scale, rolling_table, packaging_station

/ogz_process_recipes            -- List all available processing recipes

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS (Config.Debug = true required)
-- ═══════════════════════════════════════════════════════════════════════════

/ogzdebug                       -- Toggle debug mode
/ogzreload                      -- Reload configurations (careful!)
/ogzstats                       -- Show system statistics
/ogzperf                        -- Show performance metrics

-- ═══════════════════════════════════════════════════════════════════════════
-- GIVE ITEM COMMANDS (Admin - via admin menu)
-- ═══════════════════════════════════════════════════════════════════════════

-- These are accessed via /propadmin → Give Items / Give with Purity
-- Not direct commands, but menu-driven for safety

-- Admin Menu → Give Items:
--   Standard item giving without metadata

-- Admin Menu → 🧪 Give with Purity:
--   Give items with purity/quality metadata for testing
--   Presets: Cosmic Kush (100%/75%), Coke (100%/50%), Meth (100%/85%)
--   Custom: Any item with any purity/quality values


--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    SERVER.CFG REGISTRATION                                ║
    ╠═══════════════════════════════════════════════════════════════════════════╣
    ║                                                                           ║
    ║  Commands are auto-registered by the resource.                            ║
    ║  No server.cfg entries needed!                                            ║
    ║                                                                           ║
    ║  Just ensure the resource starts:                                         ║
    ║  ensure ogz_propmanager                                                   ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]


--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    PERMISSION CONFIGURATION                               ║
    ╠═══════════════════════════════════════════════════════════════════════════╣
    ║                                                                           ║
    ║  Admin commands check against Config.AdminGroups in config/config.lua:    ║
    ║                                                                           ║
    ║  Config.AdminGroups = {                                                   ║
    ║      'admin',                                                             ║
    ║      'god',                                                               ║
    ║      'superadmin',                                                        ║
    ║      'developer',                                                         ║
    ║  }                                                                        ║
    ║                                                                           ║
    ║  OR via QBX/QBCore permission system                                      ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]


--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    QUICK REFERENCE CARD                                   ║
    ╠═══════════════════════════════════════════════════════════════════════════╣
    ║                                                                           ║
    ║  MOST USED COMMANDS:                                                      ║
    ║  ───────────────────────────────────────────────────────────────────────  ║
    ║  /propadmin             → Main admin menu (everything)                    ║
    ║  /ogz_spawn_scale       → Test drug scales                                ║
    ║  /ogz_process_test      → Test processing without station                 ║
    ║  /placestation          → Place crafting station                          ║
    ║  /placestash            → Place storage stash                             ║
    ║                                                                           ║
    ║  TESTING WORKFLOW:                                                        ║
    ║  ───────────────────────────────────────────────────────────────────────  ║
    ║  1. /propadmin → Give with Purity → Give yourself drugs + containers      ║
    ║  2. /ogz_spawn_scale drug_scale → Spawn test scale                        ║
    ║  3. Interact with scale → Select recipe → Process                         ║
    ║  4. Check output items have preserved purity!                             ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]
