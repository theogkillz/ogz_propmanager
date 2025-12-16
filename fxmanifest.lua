--[[
     ██████   ██████  ███████       ██████  ██████   ██████  ██████  ███    ███  █████  ███    ██  █████   ██████  ███████ ██████  
    ██    ██ ██       ╚══███╔╝       ██   ██ ██   ██ ██    ██ ██   ██ ████  ████ ██   ██ ████   ██ ██   ██ ██       ██      ██   ██ 
    ██    ██ ██   ███   ███   █████  ██████  ██████  ██    ██ ██████  ██ ████ ██ ███████ ██ ██  ██ ███████ ██   ███ █████   ██████  
    ██    ██ ██    ██  ███          ██      ██   ██ ██    ██ ██      ██  ██  ██ ██   ██ ██  ██ ██ ██   ██ ██    ██ ██      ██   ██ 
     ██████   ██████  ███████       ██      ██   ██  ██████  ██      ██      ██ ██   ██ ██   ████ ██   ██  ██████  ███████ ██   ██ 
                                                                                                                                
    Comprehensive Prop Ecosystem Manager v3.1
    Created by: The OG KiLLz & Claude (Claude vs Claude vs The World!)
    
    v3.1 FEATURES:
    ═══════════════════════════════════════════════════════════════════════════
    STATIONS (v2.0)
    - Place props that connect to ox_inventory crafting benches
    - Multi-state prop models (off/on/working)
    - Multiple crafting tables per station (gang-specific recipes)
    - Job/Gang visibility restrictions
    - Station durability & repair system
    - Production cooldowns & cooperative bonuses
    - Random crafting events
    - Full admin menu & production logging
    
    STASHES (v3.0)
    - Portable storage containers (safes, lockers, bags)
    - ox_inventory stash integration
    - Owner, gang, job, and custom access control
    - Hidden compartments requiring search
    
    LOOTABLES (v3.0)
    - Admin-placed loot containers
    - Configurable loot tables with chance rolls
    - Player/global cooldowns
    - One-time loot with auto-despawn
    
    WORLD PROPS (v3.0)
    - Location-based world prop interactions
    - Shops, stashes, crafting, rewards
    - Per-player per-location cooldowns
    - Performance-optimized (no global model targeting)
    
    FURNITURE (v3.0) - REVOLUTIONARY!
    - Pull/push chairs and furniture
    - Fix unusable seats clipped into tables
    - Rotation support
    - Resets on server restart (respects mappings)
    
    PROCESSING (v3.1 NEW!) - DRUG SCALE SYSTEM!
    - Weight-based drug packaging (gram, quarter, ounce, pound, brick)
    - FULL METADATA PRESERVATION (purity, quality, durability)
    - Integrates with Lation Scripts (Weed, Coke, Meth)
    - ox_inventory crafting hook for metadata flow
    - Gang/Job locked recipes
    - Multiple station types (scale, bulk scale, rolling table, etc.)
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ogz_propmanager'
author 'The OG KiLLz & Claude'
description 'Comprehensive Prop Ecosystem Manager v3.1 - Now with Drug Processing!'
version '3.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/stations.lua',
    'config/stashes.lua',
    'config/lootables.lua',
    'config/worldprops.lua',
    'config/furniture.lua',
    -- 'config/sit_emotes.lua',
    'config/processing.lua',
    'config/animations.lua',
    'config/sounds.lua',
    'config/events.lua',
}

client_scripts {
    'client/utils.lua',
    'client/crafting.lua',
    'client/target.lua',
    'client/states.lua',
    'client/placement.lua',
    'client/admin.lua',
    'client/main.lua',
    -- v3.0 modules
    'client/stashes.lua',
    'client/lootables.lua',
    'client/worldprops.lua',
    'client/furniture.lua',
    -- v3.1 modules
    'client/processing.lua',
    'client/sit_capture.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/admin.lua',
    'server/main.lua',
    -- v3.0 modules
    'server/stashes.lua',
    'server/lootables.lua',
    'server/worldprops.lua',
    -- v3.1 modules
    'server/processing.lua',
    'server/sit_capture.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}
