--[[
    ═══════════════════════════════════════════════════════════════════════════
    OGz PropManager v3.5 - WORLD BUILDER CONFIG
    ═══════════════════════════════════════════════════════════════════════════
    
    WORLD BUILDER = Control prop EXISTENCE (spawn, delete, respawn)
    WORLD PROPS   = Control prop INTERACTIONS (harvest, loot, rewards)
    
    These systems work together:
    1. WorldBuilder spawns props and persists them in database
    2. WorldProps detects those props and adds interactions
    
    ═══════════════════════════════════════════════════════════════════════════
]]

WorldBuilder = {
    -- ═══════════════════════════════════════════════════════════════════════
    -- SETTINGS
    -- ═══════════════════════════════════════════════════════════════════════
    
    Settings = {
        -- Admin permissions
        Admin = {
            acePermission = "ogz.worldbuilder.admin",  -- ACE permission required
            allowedJobs = { "admin", "developer" },     -- Or job-based access
            useAce = true,                              -- true = ACE, false = jobs
        },
        
        -- Placement settings (uses existing placement.lua system)
        Placement = {
            defaultMode = "gizmo",           -- "gizmo" or "raycast"
            snapToGround = true,             -- Auto-snap on placement
            showGhost = true,                -- Show preview prop
        },
        
        -- Delete settings
        Delete = {
            confirmDelete = true,            -- Require confirmation for permanent deletes
            deleteRadius = 1.0,              -- Radius to match native props for deletion
        },
        
        -- Respawn settings
        Respawn = {
            checkInterval = 30000,           -- How often server checks for respawns (ms)
            defaultTime = 300,               -- Default respawn time (seconds)
            maxRetries = 3,                  -- Max respawn attempts before giving up
        },
        
        -- Sync settings
        Sync = {
            loadRadius = 200.0,              -- Distance to load spawned props
            streamDistance = 100.0,          -- Entity streaming distance
        },
        
        -- Debug
        Debug = {
            enabled = true,                  -- Debug prints
            showMarkers = false,             -- Show markers at spawn locations
            logToDiscord = false,            -- Log admin actions to Discord
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- SPAWN GROUPS (Pre-defined prop collections)
    -- ═══════════════════════════════════════════════════════════════════════
    --[[
        Spawn Groups are collections of props that can be:
        - Spawned all at once with a command
        - Linked to a WorldProps zone for interactions
        - Have unified respawn settings
        
        Great for: Weed farms, orchards, mining areas, decoration sets
    ]]
    
    SpawnGroups = {
        -- ═══════════════════════════════════════════════════════════════════
        -- EXAMPLE: Weed Farm
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        weed_farm_plants = {
            name = "North Weed Farm Plants",
            enabled = true,
            
            -- Link to WorldProps zone for interactions
            worldPropsZone = "weed_farm_north",  -- Must match a zone in worldprops.lua
            
            -- Respawn settings for this group
            respawn = {
                enabled = true,
                time = 300,                      -- 5 minutes after harvest
                individual = true,               -- Each prop respawns independently
            },
            
            -- Props in this group
            props = {
                { model = "prop_weed_01", coords = vec3(2220.0, 5575.0, 52.8), heading = 0.0 },
                { model = "prop_weed_01", coords = vec3(2222.0, 5575.0, 52.8), heading = 45.0 },
                { model = "prop_weed_01", coords = vec3(2224.0, 5575.0, 52.8), heading = 90.0 },
                { model = "prop_weed_02", coords = vec3(2220.0, 5577.0, 52.8), heading = 0.0 },
                { model = "prop_weed_02", coords = vec3(2222.0, 5577.0, 52.8), heading = 45.0 },
                -- Add more plants as needed...
            },
        },
        ]]
        
        -- ═══════════════════════════════════════════════════════════════════
        -- EXAMPLE: Apple Orchard Trees
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        apple_orchard_trees = {
            name = "Sandy Shores Orchard Trees",
            enabled = true,
            
            worldPropsZone = "apple_orchard",
            
            respawn = {
                enabled = false,                 -- Trees don't respawn (always there)
            },
            
            props = {
                { model = "prop_tree_birch_02", coords = vec3(1766.0, 4800.0, 41.0), heading = 0.0 },
                { model = "prop_tree_birch_02", coords = vec3(1770.0, 4800.0, 41.0), heading = 90.0 },
                { model = "prop_tree_birch_03", coords = vec3(1768.0, 4804.0, 41.0), heading = 45.0 },
            },
        },
        ]]
        
        -- ═══════════════════════════════════════════════════════════════════
        -- EXAMPLE: Mining Rocks
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        mine_rocks = {
            name = "Crystal Mine Rocks",
            enabled = true,
            
            worldPropsZone = "crystal_mine",
            
            respawn = {
                enabled = true,
                time = 600,                      -- 10 minutes
                individual = true,
            },
            
            props = {
                { model = "prop_rock_4_a", coords = vec3(2950.0, 2750.0, 43.0), heading = 0.0 },
                { model = "prop_rock_4_b", coords = vec3(2952.0, 2752.0, 43.0), heading = 45.0 },
                { model = "prop_rock_4_c", coords = vec3(2948.0, 2748.0, 43.0), heading = 90.0 },
            },
        },
        ]]
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- DELETED PROPS (Pre-defined native props to hide)
    -- ═══════════════════════════════════════════════════════════════════════
    --[[
        Hide ugly/unwanted GTA native props permanently.
        These are loaded from DB on resource start.
        
        You can also add props here that should ALWAYS be hidden,
        regardless of database state.
    ]]
    
    DeletedProps = {
        -- ═══════════════════════════════════════════════════════════════════
        -- EXAMPLE: Hide props blocking MLO entrance
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        {
            model = "prop_dumpster_01a",         -- Model name or hash
            coords = vec3(123.45, -567.89, 29.0),
            radius = 1.0,                        -- Match radius
            reason = "Blocking warehouse entrance",
        },
        {
            model = "prop_bush_lrg_04b",
            coords = vec3(200.0, -300.0, 40.0),
            radius = 2.0,
            reason = "Blocking view",
        },
        ]]
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- MODEL PRESETS (Quick access models for admin spawning)
    -- ═══════════════════════════════════════════════════════════════════════
    --[[
        Categorized model lists for the admin spawn menu.
        Makes it easy to find and spawn common props.
    ]]
    
    ModelPresets = {
        ["🌿 Weed/Drugs"] = {
            { model = "prop_weed_01", label = "Weed Plant Small" },
            { model = "prop_weed_02", label = "Weed Plant Medium" },
            { model = "bkr_prop_weed_lrg_01a", label = "Weed Plant Large" },
            { model = "bkr_prop_weed_med_01a", label = "Weed Plant Med Alt" },
            { model = "prop_meth_bag_01", label = "Meth Bag" },
            { model = "prop_meth_tube", label = "Meth Tube" },
        },
        
        ["🌳 Trees/Plants"] = {
            { model = "prop_tree_birch_02", label = "Birch Tree" },
            { model = "prop_tree_birch_03", label = "Birch Tree Alt" },
            { model = "prop_tree_cedar_02", label = "Cedar Tree" },
            { model = "prop_tree_pine_01", label = "Pine Tree" },
            { model = "prop_plant_fern_02a", label = "Fern Plant" },
            { model = "prop_bush_lrg_04b", label = "Large Bush" },
        },
        
        ["🪨 Rocks/Mining"] = {
            { model = "prop_rock_4_a", label = "Rock A" },
            { model = "prop_rock_4_b", label = "Rock B" },
            { model = "prop_rock_4_c", label = "Rock C" },
            { model = "prop_rock_4_d", label = "Rock D" },
            { model = "prop_rock_4_e", label = "Rock E" },
        },
        
        ["📦 Containers/Storage"] = {
            { model = "prop_box_wood01a", label = "Wooden Box" },
            { model = "prop_box_wood02a", label = "Wooden Crate" },
            { model = "prop_container_03a", label = "Container" },
            { model = "prop_barrel_02a", label = "Barrel" },
            { model = "prop_pallet_02a", label = "Pallet" },
        },
        
        ["🗑️ Dumpsters/Trash"] = {
            { model = "prop_dumpster_01a", label = "Dumpster" },
            { model = "prop_dumpster_02a", label = "Dumpster Alt" },
            { model = "prop_bin_07a", label = "Trash Bin" },
            { model = "prop_bin_08a", label = "Trash Bin Alt" },
        },
        
        ["🔧 Industrial"] = {
            { model = "prop_tool_bench02", label = "Tool Bench" },
            { model = "prop_toolchest_05", label = "Tool Chest" },
            { model = "prop_workbench_01", label = "Work Bench" },
            { model = "prop_welding_torch", label = "Welding Torch" },
        },
        
        ["🪑 Furniture"] = {
            { model = "prop_chair_01a", label = "Chair" },
            { model = "prop_table_01", label = "Table" },
            { model = "prop_bench_01a", label = "Bench" },
            { model = "prop_couch_01", label = "Couch" },
        },
    },
}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    ADMIN COMMANDS REFERENCE
    ═══════════════════════════════════════════════════════════════════════════
    
    /wb_spawn [model]       Enter placement mode with specified model
    /wb_spawn               Open model preset menu
    /wb_delete              Toggle delete mode (ox_target precision selection)
    /wb_hash                Toggle hash mode (copy model info without delete)
    /wb_list                List nearby spawned/deleted props
    /wb_menu                Open full admin menu
    /wb_group [name]        Spawn entire prop group
    /wb_respawn [id]        Force respawn a specific prop
    /wb_clear [radius]      Remove all spawned props in radius
    /wb_scan [radius]       Scan nearby props and print to console
    /wb_reload              Reload all props from database
    /wb_cancel              Cancel current mode (delete/placement)
    
    DELETE MODE OPTIONS (via ox_target):
    - Delete Prop           Delete spawned OR hide native prop
    - Copy Model Hash       Copy just the hash number
    - Copy Full Config      Copy full config line ready for paste
    - Exit Delete Mode      Exit without action
    
    ═══════════════════════════════════════════════════════════════════════════
    DATABASE TABLES
    ═══════════════════════════════════════════════════════════════════════════
    
    ogz_propmanager_world_spawned   - Props we've spawned
    ogz_propmanager_world_deleted   - Native props we've hidden
    
    ═══════════════════════════════════════════════════════════════════════════
]]

-- FiveM shared scripts dont use return
