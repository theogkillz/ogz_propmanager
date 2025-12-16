--[[
    OGz PropManager v3.0 - World Prop Definitions (Location-Based)
    
    Attach stashes, shops, crafting stations, or item rewards to SPECIFIC LOCATIONS
    where world props exist. This is LOCATION-BASED only - not server-wide model
    targeting for PERFORMANCE reasons!
    
    IMPORTANT: Each entry requires a 'locations' array specifying where props
    exist in the world. The system will NOT target all instances of a model.
    
    STRUCTURE:
    ['worldprop_id'] = {
        label           = "Display Name",
        models          = { "prop_1", "prop_2" },   -- Models at these locations
        icon            = "fas fa-icon",
        iconColor       = "#hexcolor",
        
        -- Interaction type: "shop", "stash", "crafting", "reward"
        type            = "shop",
        
        -- Shop config (type = "shop")
        shop = {
            items = {
                { item = "item_name", price = 10, label = "Display Name" },
            },
        },
        
        -- Stash config (type = "stash")
        stash = {
            slots       = 10,
            maxWeight   = 50000,
            perPlayer   = true,             -- Each player gets own stash
        },
        
        -- Crafting config (type = "crafting")
        craftingTables = {
            { name = "table_name", label = "Display Label" },
        },
        
        -- Reward config (type = "reward") - Multi-item drops!
        reward = {
            items = {
                { item = "item_name", min = 1, max = 3, chance = 50 },
            },
            minItems = 1,
            maxItems = 2,
            cooldown = {
                type = "player_location",   -- Unique per player per location
                time = 1800,
            },
        },
        
        -- Access restrictions
        visibleTo = nil,                    -- { gangs = {}, jobs = {} }
        
        -- Animation/Sound
        useAnim = nil,                      -- { dict, anim, duration }
        useSound = nil,                     -- Sound key
        
        -- REQUIRED: Specific locations where this prop exists
        -- Each location creates a target zone at those coords
        locations = {
            vec4(x, y, z, radius),          -- radius is detection range
            -- OR
            vec3(x, y, z),                  -- Uses default 2.0 radius
        },
    }
    
    WHY LOCATION-BASED?
    - Targeting every prop model server-wide = major performance hit
    - ox_target:addModel() runs checks on ALL instances
    - Location-based = ox_target zones only where needed
    - Much better for servers with many props
]]

WorldProps = {
    -- ═══════════════════════════════════════════════════════════════════════
    -- VENDING MACHINES (Example Locations)
    -- ═══════════════════════════════════════════════════════════════════════
    
    --[[
    ['vending_snack_legion'] = {
        label = "Snack Machine",
        models = { "prop_vend_snak_01" },
        icon = "fas fa-cookie",
        iconColor = "#ff9900",
        
        type = "shop",
        
        shop = {
            items = {
                { item = "sandwich", price = 5, label = "Sandwich" },
                { item = "chips", price = 3, label = "Chips" },
                { item = "chocolate", price = 4, label = "Chocolate Bar" },
                { item = "donut", price = 3, label = "Donut" },
            },
        },
        
        visibleTo = nil,                    -- Everyone can use
        
        useAnim = {
            dict = "mini@sprunk",
            anim = "plyr_buy_drink_pt1",
            duration = 2000,
        },
        
        -- Specific locations (Legion Square area example)
        locations = {
            vec4(208.15, -932.45, 30.68, 2.0),
            vec4(133.87, -1711.85, 29.29, 2.0),
        },
    },
    
    ['vending_soda_downtown'] = {
        label = "Soda Machine",
        models = { "prop_vend_soda_01", "prop_vend_soda_02" },
        icon = "fas fa-bottle-water",
        iconColor = "#0066ff",
        
        type = "shop",
        
        shop = {
            items = {
                { item = "cola", price = 3, label = "eCola" },
                { item = "sprunk", price = 3, label = "Sprunk" },
                { item = "water", price = 2, label = "Water" },
            },
        },
        
        visibleTo = nil,
        
        locations = {
            vec4(-706.18, -913.75, 19.21, 2.0),
            vec4(-710.54, -905.67, 19.21, 2.0),
        },
    },
    ]]
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- DUMPSTER DIVING (Specific Locations)
    -- ═══════════════════════════════════════════════════════════════════════
    
    --[[
    ['dumpster_alley_01'] = {
        label = "Search Dumpster",
        models = { "prop_dumpster_01a" },
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
                type = "player_location",   -- Per player, per this specific dumpster
                time = 1800,                -- 30 minutes
            },
        },
        
        useAnim = {
            dict = "amb@prop_human_bum_bin@idle_a",
            anim = "idle_a",
            duration = 5000,
        },
        
        useSound = "search_rummage",
        
        visibleTo = nil,
        
        locations = {
            vec4(123.45, -567.89, 29.10, 2.5),
            vec4(234.56, -678.90, 30.20, 2.5),
        },
    },
    ]]
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- ATM HIDDEN STASHES (Gang Only)
    -- ═══════════════════════════════════════════════════════════════════════
    
    --[[
    ['atm_grove_stash'] = {
        label = "Hidden Compartment",
        models = { "prop_atm_01", "prop_atm_02" },
        icon = "fas fa-eye-slash",
        iconColor = "#00ff00",
        
        type = "stash",
        
        stash = {
            slots = 5,
            maxWeight = 10000,
            perPlayer = true,               -- Each gang member gets own stash
        },
        
        visibleTo = { gangs = {"gsf", "families"} },
        
        locations = {
            vec4(-172.09, -1398.67, 31.45, 2.0),    -- Grove Street ATMs
            vec4(-188.01, -1394.58, 31.45, 2.0),
        },
    },
    ]]
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- WORLD WORKBENCHES (Crafting)
    -- ═══════════════════════════════════════════════════════════════════════
    
    --[[
    ['workbench_warehouse'] = {
        label = "Workbench",
        models = { "prop_tool_bench02" },
        icon = "fas fa-tools",
        iconColor = "#ffa500",
        
        type = "crafting",
        
        craftingTables = {
            { name = "basic_crafting", label = "Basic Crafting" },
        },
        
        visibleTo = nil,
        
        locations = {
            vec4(1087.45, -2002.67, 30.45, 2.0),    -- Some warehouse
            vec4(892.34, -1799.23, 29.87, 2.0),
        },
    },
    ]]
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- PLACEHOLDER FOR YOUR LOCATIONS
    -- ═══════════════════════════════════════════════════════════════════════
    
    --[[
    TIPS FOR FINDING PROP LOCATIONS:
    
    1. Use a prop finder tool in-game to get exact coords
    2. Stand near the prop and use GetEntityCoords(GetClosestObjectOfType(...))
    3. Use CodeWalker or Map Editor to find prop placements
    4. Test with /ogz_worldprop_test command (admin)
    
    ADDING A NEW WORLD PROP:
    
    1. Identify the prop model name
    2. Get the exact vec4 coords (x, y, z, radius)
    3. Choose interaction type: shop, stash, crafting, or reward
    4. Configure the interaction data
    5. Add to this file and restart resource
    
    Example workflow:
    
    -- In-game (admin command):
    /ogz_worldprop_scan 10.0   -- Scans for props within 10m
    -- Returns list of props with models and coords
    
    -- Then add to config:
    ['my_custom_prop'] = {
        label = "My Custom Prop",
        models = { "prop_xyz" },
        type = "reward",
        reward = { ... },
        locations = {
            vec4(copied_x, copied_y, copied_z, 2.0),
        },
    },
    ]]
}

return WorldProps
