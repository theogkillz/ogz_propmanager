--[[
    ┌──────────────────────────────────────────────────────────────────┐
    │      OGz PropManager v3.1 - Example ox_inventory Crafting        │
    │                                                                  │
    │  Copy these entries into your ox_inventory/data/crafting.lua     │
    │                                                                  │
    │  The 'name' field MUST match the 'craftingTable' value in        │
    │  your ogz_propmanager/config/stations.lua                        │
    └──────────────────────────────────────────────────────────────────┘
    
    ╔═══════════════════════════════════════════════════════════════════╗
    ║  ⚠️  IMPORTANT: v3.1 DRUG PROCESSING NOTE                         ║
    ║                                                                   ║
    ║  The v3.1 Processing system (drug scales) does NOT use            ║
    ║  ox_inventory crafting.lua! It has its own system to              ║
    ║  preserve metadata (purity/quality/durability).                   ║
    ║                                                                   ║
    ║  Processing recipes are in: config/processing.lua                 ║
    ║  These ox_inventory recipes are for STATIONS only (v2.0)          ║
    ╚═══════════════════════════════════════════════════════════════════╝
    
    STRUCTURE:
    {
        items = {
            { name = 'output_item', ingredients = { input1 = count, input2 = count }, duration = ms, count = output_amount },
        },
        points = {},                          -- Leave empty for prop-based stations
        groups = { ["job_or_gang"] = grade }, -- WHO can use this bench (table-level lock)
        zones = {},                           -- Leave empty! We handle placement in ogz_propmanager
        name = 'crafting_table_key'           -- MUST match craftingTable in stations.lua
    },
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- ADD THESE TO YOUR ox_inventory/data/crafting.lua FILE
-- ═══════════════════════════════════════════════════════════════════════════

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │               ROSIN PRESS - PUBLIC RECIPES                       │
    -- └──────────────────────────────────────────────────────────────────┘
    
    { -- ROSIN PRESS - PUBLIC (Everyone)
        items = {
            { name = 'basic_rosin', ingredients = { weed_leaf = 10, filter_bag = 1 }, duration = 10000, count = 1 },
            { name = 'weed_butter', ingredients = { weed_leaf = 5, butter = 2 }, duration = 8000, count = 1 },
        },
        points = {},
        groups = nil,
        zones = {},
        name = 'rosin_press_public'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │             ROSIN PRESS - BALLAS EXCLUSIVE                       │
    -- └──────────────────────────────────────────────────────────────────┘
    
    { -- ROSIN PRESS - BALLAS EXCLUSIVE
        items = {
            { name = 'purple_haze_seed', ingredients = { ballas_mother_plant = 1, growth_hormone = 2, water_bottle = 3 }, duration = 15000, count = 5 },
            { name = 'purple_haze_rosin', ingredients = { purple_haze_bud = 10, premium_filter_bag = 1 }, duration = 12000, count = 2 },
            { name = 'ballas_purple_kush', ingredients = { purple_haze_seed = 3, og_kush_seed = 2, growth_hormone = 1 }, duration = 20000, count = 3 },
        },
        points = {},
        groups = { ["ballas"] = 0 },
        zones = {},
        name = 'rosin_press_ballas'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │             ROSIN PRESS - VAGOS EXCLUSIVE                        │
    -- └──────────────────────────────────────────────────────────────────┘
    
    { -- ROSIN PRESS - VAGOS EXCLUSIVE
        items = {
            { name = 'golden_haze_seed', ingredients = { vagos_mother_plant = 1, growth_hormone = 2, water_bottle = 3 }, duration = 15000, count = 5 },
            { name = 'golden_haze_rosin', ingredients = { golden_haze_bud = 10, premium_filter_bag = 1 }, duration = 12000, count = 2 },
            { name = 'vagos_gold_express', ingredients = { golden_haze_seed = 3, blue_dream_seed = 2, growth_hormone = 1 }, duration = 20000, count = 3 },
        },
        points = {},
        groups = { ["vagos"] = 0 },
        zones = {},
        name = 'rosin_press_vagos'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │           ROSIN PRESS - GROVE STREET EXCLUSIVE                   │
    -- └──────────────────────────────────────────────────────────────────┘
    
    { -- ROSIN PRESS - GROVE STREET EXCLUSIVE
        items = {
            { name = 'grove_green_seed', ingredients = { gsf_mother_plant = 1, growth_hormone = 2, water_bottle = 3 }, duration = 15000, count = 5 },
            { name = 'grove_green_rosin', ingredients = { grove_green_bud = 10, premium_filter_bag = 1 }, duration = 12000, count = 2 },
            { name = 'og_grove_special', ingredients = { grove_green_seed = 3, og_kush_seed = 3, growth_hormone = 2 }, duration = 25000, count = 4 },
        },
        points = {},
        groups = { ["gsf"] = 0, ["families"] = 0 },
        zones = {},
        name = 'rosin_press_gsf'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │                    METH COOKING TABLE                            │
    -- │  ⚠️ For cooking ONLY - use Processing for bagging with purity    │
    -- └──────────────────────────────────────────────────────────────────┘

    { -- METH COOKING TABLE
        items = {
            { name = 'meth', ingredients = { pseudoephedrine = 3, lithium = 2, acetone = 1 }, duration = 20000, count = 1 },
            { name = 'blue_meth', ingredients = { pseudoephedrine = 5, lithium = 3, acetone = 2, methylamine = 1 }, duration = 30000, count = 2 },
        },
        points = {},
        groups = { ["lost_mc"] = 0 },
        zones = {},
        name = 'meth_cooking'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │                 COCAINE PROCESSING TABLE                         │
    -- │  ⚠️ For processing ONLY - use Processing for bagging with purity │
    -- └──────────────────────────────────────────────────────────────────┘

    { -- COCAINE PROCESSING TABLE
        items = {
            { name = 'coke', ingredients = { coca_leaves = 10, gasoline = 2, baking_soda = 1 }, duration = 25000, count = 1 },
            { name = 'coke_brick', ingredients = { coke = 35 }, duration = 30000, count = 1 },
        },
        points = {},
        groups = nil,
        zones = {},
        name = 'coke_processing'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │                    GENERAL WORKBENCH                             │
    -- └──────────────────────────────────────────────────────────────────┘

    { -- GENERAL WORKBENCH
        items = {
            { name = 'lockpick', ingredients = { metalscrap = 5, plastic = 2 }, duration = 8000, count = 1 },
            { name = 'advancedlockpick', ingredients = { metalscrap = 10, plastic = 5, electronic_parts = 2 }, duration = 12000, count = 1 },
            { name = 'screwdriverset', ingredients = { metalscrap = 3, plastic = 1 }, duration = 5000, count = 1 },
        },
        points = {},
        groups = nil,
        zones = {},
        name = 'workbench'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │                 WEAPON CRAFTING BENCH                            │
    -- └──────────────────────────────────────────────────────────────────┘

    { -- WEAPON CRAFTING BENCH (Job Locked)
        items = {
            { name = 'weapon_pistol_mk2', ingredients = { steel = 10, rubber = 3, gun_parts = 1 }, duration = 30000, count = 1 },
            { name = 'ammo_9mm', ingredients = { steel = 5, gunpowder = 2 }, duration = 10000, count = 24 },
        },
        points = {},
        groups = { ["police"] = 3, ["gunsmith"] = 0 },
        zones = {},
        name = 'weapon_crafting'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │                  PORTABLE COOKING STATION                        │
    -- └──────────────────────────────────────────────────────────────────┘

    { -- PORTABLE COOKING STATION
        items = {
            { name = 'burger', ingredients = { bun = 1, patty = 1, lettuce = 1 }, duration = 5000, count = 1 },
            { name = 'hotdog', ingredients = { hotdog_bun = 1, sausage = 1, ketchup = 1 }, duration = 4000, count = 1 },
            { name = 'sandwich', ingredients = { bread = 2, cheese = 1, ham = 1 }, duration = 3000, count = 1 },
        },
        points = {},
        groups = nil,
        zones = {},
        name = 'cooking'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │                     PORTABLE GRILL                               │
    -- └──────────────────────────────────────────────────────────────────┘

    { -- PORTABLE GRILL
        items = {
            { name = 'grilled_steak', ingredients = { raw_steak = 1, seasoning = 1 }, duration = 8000, count = 1 },
            { name = 'grilled_chicken', ingredients = { raw_chicken = 1, seasoning = 1 }, duration = 7000, count = 1 },
            { name = 'bbq_ribs', ingredients = { raw_ribs = 1, bbq_sauce = 1 }, duration = 12000, count = 1 },
        },
        points = {},
        groups = nil,
        zones = {},
        name = 'grilling'
    },

    -- ┌──────────────────────────────────────────────────────────────────┐
    -- │                    MEDICAL STATION                               │
    -- └──────────────────────────────────────────────────────────────────┘

    { -- MEDICAL STATION (EMS Only)
        items = {
            { name = 'firstaid', ingredients = { bandage = 3, painkillers = 2, cloth = 1 }, duration = 10000, count = 1 },
            { name = 'medkit', ingredients = { bandage = 5, painkillers = 3, antiseptic = 2, cloth = 2 }, duration = 15000, count = 1 },
            { name = 'ifak', ingredients = { bandage = 2, painkillers = 1, tourniquet = 1 }, duration = 8000, count = 1 },
        },
        points = {},
        groups = { ["ambulance"] = 0, ["doctor"] = 0, ["ems"] = 0 },
        zones = {},
        name = 'medical_crafting'
    },

--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                  v3.1 PROCESSING SYSTEM INFO                              ║
    ╠═══════════════════════════════════════════════════════════════════════════╣
    ║                                                                           ║
    ║  Drug bagging/packaging is handled by the PROCESSING SYSTEM, not here!   ║
    ║                                                                           ║
    ║  WHY? ox_inventory crafting CANNOT preserve metadata (purity/quality).    ║
    ║  Our custom processing system extracts and transfers metadata properly.   ║
    ║                                                                           ║
    ║  ┌─────────────────────────────────────────────────────────────────────┐  ║
    ║  │  PROCESSING RECIPES ARE IN: config/processing.lua                   │  ║
    ║  └─────────────────────────────────────────────────────────────────────┘  ║
    ║                                                                           ║
    ║  PROCESSING FLOW:                                                         ║
    ║                                                                           ║
    ║  1. Player needs:                                                         ║
    ║     - scales (in inventory, NOT consumed)                                 ║
    ║     - Input drug (e.g., coke with purity: 87)                            ║
    ║     - Empty containers (e.g., 28x ls_empty_baggy)                        ║
    ║                                                                           ║
    ║  2. Player uses Drug Scale station                                        ║
    ║                                                                           ║
    ║  3. Selects recipe (e.g., "Cocaine → Grams (28x)")                       ║
    ║                                                                           ║
    ║  4. Processing extracts purity from input                                 ║
    ║                                                                           ║
    ║  5. Player receives 28x cokebaggy (each with purity: 87!)                ║
    ║                                                                           ║
    ║  STATION TYPES:                                                           ║
    ║  - drug_scale       → Basic scale for all drugs                          ║
    ║  - bulk_scale       → Industrial scale for large batches                 ║
    ║  - rolling_table    → For rolling joints                                 ║
    ║  - packaging_station → General packaging                                  ║
    ║                                                                           ║
    ║  TEST COMMANDS:                                                           ║
    ║  /ogz_spawn_scale drug_scale  → Spawn test scale                         ║
    ║  /ogz_process_test            → Open menu without station                ║
    ║  /ogz_process_recipes         → List all recipes                         ║
    ║                                                                           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]
