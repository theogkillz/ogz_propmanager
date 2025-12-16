--[[
    ═══════════════════════════════════════════════════════════════════════════
    OGz PropManager v3.4 - WORLD PROPS CONFIG (COMBINED SYSTEM)
    ═══════════════════════════════════════════════════════════════════════════
    
    TWO APPROACHES - USE WHAT FITS YOUR NEEDS:
    
    1. LOCATION-BASED (Original v3.0)
       - Define specific vec4 coordinates where props exist
       - Best for: Vending machines, specific workbenches, unique props
       - Uses: ox_target sphere zones at exact locations
    
    2. ZONE-BASED AUTO-DISCOVERY (New v3.4)
       - Define a zone, system auto-finds props within it
       - Best for: Weed farms, orchards, mining areas, mass props
       - Uses: lib.zones + dynamic ox_target on discovered entities
    
    ═══════════════════════════════════════════════════════════════════════════
]]

WorldProps = {
    -- ═══════════════════════════════════════════════════════════════════════
    -- MASTER SETTINGS
    -- ═══════════════════════════════════════════════════════════════════════
    
    Settings = {
        -- Performance tuning for zone-based discovery
        Performance = {
            scanInterval = 2000,         -- Re-scan interval while in zone (ms)
            maxPropsPerZone = 150,       -- Cap props per zone (prevent lag)
            entityPooling = true,        -- Reuse entity scans (performance)
            cleanupOnExit = true,        -- Remove targets when leaving zone
        },
        
        -- Default detection radius for location-based props
        DefaultRadius = 2.0,
        
        -- Debug options
        Debug = {
            enabled = false,
            showZoneBlips = false,       -- Temporary blips for zone centers
            drawZoneBorders = false,     -- 3D zone boundary drawing
            logScans = false,            -- Log prop discovery to console
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- INTERACTION TYPES REFERENCE
    -- ═══════════════════════════════════════════════════════════════════════
    --[[
        TYPE            DESCRIPTION                         USE CASE
        ─────────────────────────────────────────────────────────────────────
        "shop"          Opens a purchase menu               Vending machines
        "stash"         Opens ox_inventory stash            Hidden compartments
        "crafting"      Opens crafting table                Workbenches
        "reward"        Loot with cooldowns                 Dumpster diving
        "harvest"       Farming/gathering with yields       Weed farms, orchards
        "custom"        Trigger your own events/exports     Custom integrations
    ]]
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- LOCATION-BASED PROPS (Specific Coordinates)
    -- ═══════════════════════════════════════════════════════════════════════
    
    Locations = {
        -- ═══════════════════════════════════════════════════════════════════
        -- VENDING MACHINES
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        vending_snacks = {
            label = "Snack Machine",
            icon = "fas fa-cookie",
            iconColor = "#ff9900",
            
            type = "shop",
            
            shop = {
                items = {
                    { item = "sandwich", price = 5, label = "Sandwich" },
                    { item = "chips", price = 3, label = "Chips" },
                    { item = "chocolate", price = 4, label = "Chocolate Bar" },
                },
            },
            
            useAnim = {
                dict = "mini@sprunk",
                anim = "plyr_buy_drink_pt1",
                duration = 2000,
            },
            
            -- Specific locations where this vending machine exists
            locations = {
                vec4(208.15, -932.45, 30.68, 2.0),
                vec4(133.87, -1711.85, 29.29, 2.0),
            },
        },
        ]]
        
        -- ═══════════════════════════════════════════════════════════════════
        -- DUMPSTER DIVING (Reward Type)
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        dumpster_downtown = {
            label = "Search Dumpster",
            icon = "fas fa-dumpster",
            iconColor = "#556b2f",
            
            type = "reward",
            
            reward = {
                items = {
                    { item = "garbage", min = 1, max = 3, chance = 80 },
                    { item = "scrap_metal", min = 1, max = 2, chance = 30 },
                    { item = "electronics", min = 1, max = 1, chance = 10 },
                    { item = "lockpick", min = 1, max = 1, chance = 5 },
                },
                minItems = 1,
                maxItems = 2,
                cooldown = {
                    type = "player_location",   -- Per player, per location
                    time = 1800,                -- 30 minutes
                },
            },
            
            useAnim = {
                dict = "amb@prop_human_bum_bin@idle_a",
                anim = "idle_a",
                duration = 5000,
            },
            
            visibleTo = nil,  -- Everyone
            
            locations = {
                vec4(123.45, -567.89, 29.10, 2.5),
            },
        },
        ]]
        
        -- ═══════════════════════════════════════════════════════════════════
        -- HIDDEN STASH (Gang Restricted)
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        grove_atm_stash = {
            label = "Hidden Compartment",
            icon = "fas fa-eye-slash",
            iconColor = "#00ff00",
            
            type = "stash",
            
            stash = {
                slots = 5,
                maxWeight = 10000,
                perPlayer = true,  -- Each player gets their own stash
            },
            
            visibleTo = {
                gangs = { "gsf", "families" },
            },
            
            locations = {
                vec4(-172.09, -1398.67, 31.45, 2.0),
            },
        },
        ]]
        
        -- ═══════════════════════════════════════════════════════════════════
        -- WORKBENCH (Crafting Type)
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        warehouse_workbench = {
            label = "Workbench",
            icon = "fas fa-tools",
            iconColor = "#ffa500",
            
            type = "crafting",
            
            craftingTables = {
                { name = "basic_crafting", label = "Basic Crafting" },
                { name = "weapon_parts", label = "Weapon Parts" },
            },
            
            visibleTo = nil,
            
            locations = {
                vec4(1087.45, -2002.67, 30.45, 2.0),
            },
        },
        ]]
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- ZONE-BASED AUTO-DISCOVERY (Mass Props)
    -- ═══════════════════════════════════════════════════════════════════════
    --[[
        ZONE TYPES:
        
        "circle"  - Simple radius from center point
                    center = vec3(x, y, z), radius = 50.0
        
        "poly"    - Irregular polygon shape
                    points = { vec3(...), vec3(...), ... }
        
        "box"     - Rectangle with rotation
                    center = vec3(x, y, z), size = vec3(w, l, h), rotation = 0.0
    ]]
    
    Zones = {
        -- ═══════════════════════════════════════════════════════════════════
        -- WEED FARM (Harvest Type)
        -- ═══════════════════════════════════════════════════════════════════
        
        
        weed_farm_north = {
            name = "North Weed Farm",
            enabled = true,
            
            -- Zone definition
            zoneType = "circle",
            center = vec3(2220.0, 5577.0, 53.0),
            radius = 20.0,
            minZ = 50.0,
            maxZ = 60.0,
            
            -- Props to auto-discover in this zone
            models = {
                "prop_weed_01",
                "prop_weed_02",
                "bkr_prop_weed_lrg_01a",
                "bkr_prop_weed_med_01a",
            },
            
            -- Interaction type
            type = "harvest",
            
            -- Harvest configuration
            harvest = {
                label = "Harvest Leaves",
                icon = "fas fa-leaf",
                iconColor = "#00ff00",
                distance = 2.0,
                
                -- What player receives
                yields = {
                    { item = "weed_leaf", min = 1, max = 3, chance = 100 },
                    -- { item = "weed_seed", min = 1, max = 1, chance = 20 },
                },
                
                -- Harvest behavior
                destroyOnHarvest = true,   -- Remove prop after harvest?
                respawnTime = 5,            -- Seconds to respawn (0 = never/external)
                
                -- Cooldown per plant
                cooldown = {
                    type = "player_entity",  -- Per player, per specific plant
                    time = 300,              -- 5 minutes
                },
                
                -- Animation during harvest
                anim = {
                    dict = "amb@medic@standing@kneel@base",
                    name = "base",
                    duration = 3000,
                },
                
                -- Progress bar
                progress = {
                    label = "Harvesting...",
                    duration = 3000,
                },
            },
            
            -- Requirements to see/use
            requirements = {
                job = nil,                   -- nil = anyone, "farmer", or {"job1", "job2"}
                item = nil,                  -- Required item: "harvest_sickle"
                gang = nil,                  -- Gang restriction
            },
            
            -- Optional blip
            blip = {
                enabled = false,             -- Don't show illegal farms!
            },
        },
    
        
        -- ═══════════════════════════════════════════════════════════════════
        -- COCA PLANTATION (Harvest + Poly Zone)
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        coca_field = {
            name = "Coca Plantation",
            enabled = true,
            
            zoneType = "poly",
            points = {
                vec3(5538.0, -5163.0, 0.0),
                vec3(5600.0, -5163.0, 0.0),
                vec3(5600.0, -5100.0, 0.0),
                vec3(5538.0, -5100.0, 0.0),
            },
            minZ = -5.0,
            maxZ = 10.0,
            
            models = {
                "prop_plant_fern_02a",
            },
            
            type = "harvest",
            
            harvest = {
                label = "Pick Coca Leaves",
                icon = "fas fa-seedling",
                iconColor = "#90EE90",
                distance = 1.5,
                
                yields = {
                    { item = "coca_leaf", min = 2, max = 5, chance = 100 },
                },
                
                cooldown = {
                    type = "player_entity",
                    time = 600,
                },
                
                anim = {
                    dict = "amb@world_human_gardener_plant@male@base",
                    name = "base",
                    duration = 4000,
                },
                
                progress = {
                    label = "Picking leaves...",
                    duration = 4000,
                },
            },
        },
        ]]
        
        -- ═══════════════════════════════════════════════════════════════════
        -- APPLE ORCHARD (Multiple Interactions)
        -- ═══════════════════════════════════════════════════════════════════
        
        
        apple_orchard = {
            name = "Sandy Shores Orchard",
            enabled = true,
            
            zoneType = "circle",
            center = vec3(1766.0, 4802.0, 41.0),
            radius = 100.0,
            
            models = {
                "prop_tree_birch_02",
                "prop_tree_birch_03",
            },
            
            type = "custom",  -- Multiple interactions = custom type
            
            -- MULTIPLE INTERACTIONS per prop!
            interactions = {
                {
                    label = "Pick Apples",
                    icon = "fas fa-apple-alt",
                    iconColor = "#ff0000",
                    distance = 3.0,
                    
                    -- Trigger options (pick ONE):
                    trigger = {
                        type = "event",              -- "event", "server_event", "export", "callback", "command"
                        name = "ogz:harvest:fruit",
                        data = {
                            item = "reign_apple_green",
                            min = 1,
                            max = 4,
                        },
                    },
                    
                    anim = {
                        dict = "amb@world_human_gardener_plant@male@base",
                        name = "base",
                        duration = 2500,
                    },
                    
                    progress = {
                        label = "Picking apples...",
                        duration = 2500,
                    },
                    
                    cooldown = {
                        type = "player_entity",
                        time = 120,
                    },
                },
                {
                    label = "Shake Tree",
                    icon = "fas fa-tree",
                    iconColor = "#228B22",
                    distance = 3.0,
                    
                    trigger = {
                        type = "event",
                        name = "ogz:tree:shake",
                        data = { dropChance = 0.3 },
                    },
                    
                    requirements = {
                        item = "bag",
                    },
                    
                    anim = {
                        dict = "melee@large_wpn@streamed_core",
                        name = "ground_attack_0",
                        duration = 1500,
                    },
                },
            },
            
            blip = {
                enabled = true,
                sprite = 469,
                color = 2,
                scale = 0.8,
                label = "Orchard",
            },
        },
        
        
        -- ═══════════════════════════════════════════════════════════════════
        -- MINING AREA (Reward Type in Zone)
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        crystal_mine = {
            name = "Crystal Mine",
            enabled = true,
            
            zoneType = "box",
            center = vec3(2950.0, 2750.0, 43.0),
            size = vec3(30.0, 50.0, 10.0),
            rotation = 45.0,
            
            models = {
                "prop_rock_4_a",
                "prop_rock_4_b",
                "prop_rock_4_c",
            },
            
            type = "reward",  -- Uses the existing reward system
            
            reward = {
                label = "Mine Ore",
                icon = "fas fa-hammer",
                iconColor = "#c0c0c0",
                distance = 2.0,
                
                items = {
                    { item = "iron_ore", min = 1, max = 3, chance = 60 },
                    { item = "copper_ore", min = 1, max = 2, chance = 40 },
                    { item = "gold_ore", min = 1, max = 1, chance = 5 },
                    { item = "diamond", min = 1, max = 1, chance = 1 },
                },
                minItems = 1,
                maxItems = 2,
                
                cooldown = {
                    type = "player_entity",
                    time = 300,
                },
                
                anim = {
                    dict = "amb@world_human_hammering@male@base",
                    name = "base",
                    duration = 5000,
                },
                
                progress = {
                    label = "Mining...",
                    duration = 5000,
                },
            },
            
            requirements = {
                item = "pickaxe",
            },
            
            blip = {
                enabled = true,
                sprite = 618,
                color = 4,
                scale = 0.7,
                label = "Mine",
            },
        },
        ]]
        
        -- ═══════════════════════════════════════════════════════════════════
        -- CUSTOM INTEGRATION EXAMPLE (Your Own System)
        -- ═══════════════════════════════════════════════════════════════════
        
        --[[
        lation_weed_field = {
            name = "Lation Weed Processing",
            enabled = true,
            
            zoneType = "circle",
            center = vec3(2200.0, 5600.0, 50.0),
            radius = 50.0,
            
            models = {
                "bkr_prop_weed_lrg_01a",
            },
            
            type = "custom",
            
            interactions = {
                {
                    label = "Harvest (Lation)",
                    icon = "fas fa-cannabis",
                    iconColor = "#00ff00",
                    distance = 2.0,
                    
                    -- Call Lation Scripts export directly!
                    trigger = {
                        type = "export",
                        resource = "lation_weed",
                        func = "HarvestPlant",
                        -- Entity is automatically passed
                    },
                },
            },
        },
        ]]
    },
}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    TRIGGER TYPE REFERENCE
    ═══════════════════════════════════════════════════════════════════════════
    
    All trigger types receive these automatic parameters:
    - entity: The prop entity handle
    - coords: The prop's coordinates
    - zoneId/locationId: The config ID
    - data: Any custom data you define
    
    TYPE            USAGE                                   EXAMPLE
    ─────────────────────────────────────────────────────────────────────────
    "event"         TriggerEvent(name, params)              Client event
    "server_event"  TriggerServerEvent(name, params)        Server event
    "export"        exports[resource][func](params)         Call another script
    "callback"      lib.callback(name, params)              ox_lib callback
    "command"       ExecuteCommand(name)                    Run a command
    
    ═══════════════════════════════════════════════════════════════════════════
    COOLDOWN TYPE REFERENCE
    ═══════════════════════════════════════════════════════════════════════════
    
    TYPE                SCOPE                               USE CASE
    ─────────────────────────────────────────────────────────────────────────
    "none"              No cooldown                         Always available
    "player"            Per player globally                 Daily rewards
    "player_location"   Per player, per location            Location-based loot
    "player_entity"     Per player, per specific prop       Individual plants
    "global"            Server-wide for all players         Shared resources
    "global_entity"     Server-wide per specific prop       Contested mining
    
    ═══════════════════════════════════════════════════════════════════════════
]]

return WorldProps
