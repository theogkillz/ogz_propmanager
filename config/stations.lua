--[[
    OGz PropManager - Station Definitions (Compact Format)
    
    STRUCTURE:
    ['station_id'] = {
        label, model, item, animationType, icon, iconColor,
        modelStates = { off = {model, sound, particle}, on = {...}, working = {...} },
        craftingTables = { {name, label, icon, iconColor, visibleTo}, ... },
        durability = { max, craftCost, repairItem },
        cooldown = { craftsBeforeCooldown, cooldownTime },
        coopBonus = { radius, speedBonus, maxBonus },
        visibleTo, predefinedSpots
    }
]]

Stations = {
    -- ═══════════════════════════════════════════════════════════════════
    -- SCALES & PACKAGING (PROCESSING)
    -- ═══════════════════════════════════════════════════════════════════
    ['drug_scale'] = {
        label = "Drug Scale", model = "bzzz_weed_scale_a", item = "ogz_drug_scale", animationType = "Drugs",
        icon = "fas fa-balance-scale", iconColor = "#00ff00",
        
        processingStation = 'drug_scale',  -- Connects to Processing system, NOT ox_inventory
        
        durability = { max = 100, craftCost = 0.5, repairItem = "ogz_repair_kit" },
        cooldown = { craftsBeforeCooldown = 20, cooldownTime = 120 },
        coopBonus = { radius = 3.0, speedBonus = 0.10, maxBonus = 0.30 },
        
        visibleTo = nil, predefinedSpots = {},
    },

    ['bulk_scale'] = {
        label = "Bulk Scale", model = "bkr_prop_coke_scale_01", item = "ogz_bulk_scale", animationType = "Drugs",
        icon = "fas fa-weight-hanging", iconColor = "#ffaa00",
        
        processingStation = 'bulk_scale',
        
        durability = { max = 150, craftCost = 0.3, repairItem = "ogz_repair_kit" },
        cooldown = { craftsBeforeCooldown = 15, cooldownTime = 180 },
        coopBonus = { radius = 4.0, speedBonus = 0.15, maxBonus = 0.45 },
        
        visibleTo = nil, predefinedSpots = {},
    },

    ['rolling_table'] = {
        label = "Rolling Table", model = "bkr_prop_weed_table_01a", item = "ogz_rolling_table", animationType = "Drugs",
        icon = "fas fa-cannabis", iconColor = "#2ecc71",
        
        processingStation = 'rolling_table',
        
        durability = { max = 100, craftCost = 0.2, repairItem = "ogz_repair_kit" },
        cooldown = { craftsBeforeCooldown = 30, cooldownTime = 60 },
        coopBonus = { radius = 3.0, speedBonus = 0.10, maxBonus = 0.30 },
        
        visibleTo = nil, predefinedSpots = {},
    },

    ['packaging_station'] = {
        label = "Packaging Station", model = "prop_tool_bench02", item = "ogz_packaging_station", animationType = "Drugs",
        icon = "fas fa-boxes", iconColor = "#9b59b6",
        
        processingStation = 'packaging_station',
        
        durability = { max = 200, craftCost = 0.2, repairItem = "ogz_repair_kit" },
        cooldown = { craftsBeforeCooldown = 25, cooldownTime = 150 },
        coopBonus = { radius = 5.0, speedBonus = 0.15, maxBonus = 0.45 },
        
        visibleTo = nil, predefinedSpots = {},
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- ROSIN STATIONS
    -- ═══════════════════════════════════════════════════════════════════
    ['weed_rosin_press'] = {
        label = "Rosin Press", model = "bzzz_plants_weed_rosin1_a", item = "ogz_rosin_press", animationType = "Drugs",
        icon = "fas fa-cannabis", iconColor = "#00ff00",
        
        modelStates = {
            off     = { model = "bzzz_plants_weed_rosin1_a", sound = nil, particle = nil },
            on      = { model = "bzzz_plants_weed_rosin1_b", sound = "machine_hum", particle = nil },
            working = { model = "bzzz_plants_weed_rosin1_c", sound = "machine_press", particle = { dict = "core", name = "ent_sht_steam", offset = vec3(0, 0, 0.5), scale = 0.5 } },
        },
        
        craftingTables = {
            { name = "rosin_press_public", label = "Basic Recipes", icon = "fas fa-leaf", visibleTo = nil },
            -- { name = "rosin_press_ballas", label = "Ballas Exclusive", icon = "fas fa-skull", iconColor = "#800080", visibleTo = { gangs = {"ballas"} } },
            -- { name = "rosin_press_vagos", label = "Vagos Exclusive", icon = "fas fa-pepper-hot", iconColor = "#FFD700", visibleTo = { gangs = {"vagos"} } },
            -- { name = "rosin_press_gsf", label = "Grove St Exclusive", icon = "fas fa-tree", iconColor = "#00FF00", visibleTo = { gangs = {"gsf", "families"} } },
        },
        
        durability = { max = 100, craftCost = 2, repairItem = "screwdriverset" },
        cooldown = { craftsBeforeCooldown = 10, cooldownTime = 300 },
        coopBonus = { radius = 5.0, speedBonus = 0.15, maxBonus = 0.45 },
        
        visibleTo = nil, predefinedSpots = {vec4(1035.83, -3203.05, -38.28, 2.55),},
    },
    ['weed_rosin_press_pro'] = {
        label = "Rosin Press Pro", model = "bzzz_plants_weed_rosin2_a", item = "ogz_rosin_press_pro", animationType = "Drugs",
        icon = "fas fa-cannabis", iconColor = "#00ff00",
        
        modelStates = {
            off     = { model = "bzzz_plants_weed_rosin2_a", sound = nil, particle = nil },
            on      = { model = "bzzz_plants_weed_rosin2_b", sound = "machine_hum", particle = nil },
            working = { model = "bzzz_plants_weed_rosin2_c", sound = "machine_press", particle = { dict = "core", name = "ent_sht_steam", offset = vec3(0, 0, 0.5), scale = 0.5 } },
        },
        
        craftingTables = {
            -- { name = "rosin_press_public", label = "Basic Recipes", icon = "fas fa-leaf", visibleTo = nil },
            { name = "rosin_press_ballas", label = "Ballas Exclusive", icon = "fas fa-skull", iconColor = "#800080", visibleTo = { gangs = {"ballas"} } },
            { name = "rosin_press_vagos", label = "Vagos Exclusive", icon = "fas fa-pepper-hot", iconColor = "#FFD700", visibleTo = { gangs = {"vagos"} } },
            -- { name = "rosin_press_gsf", label = "Grove St Exclusive", icon = "fas fa-tree", iconColor = "#00FF00", visibleTo = { gangs = {"gsf", "families"} } },
        },
        
        durability = { max = 100, craftCost = 2, repairItem = "screwdriverset" },
        cooldown = { craftsBeforeCooldown = 10, cooldownTime = 200 },
        coopBonus = { radius = 5.0, speedBonus = 0.15, maxBonus = 0.45 },
        
        visibleTo = nil, predefinedSpots = {vec4(1036.83, -3203.07, -38.28, 359.46),},
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- DRUG PROCESSING
    -- ═══════════════════════════════════════════════════════════════════
    -- ['meth_table'] = {
    --     label = "Meth Lab Table", model = "bkr_prop_coke_table01a", item = "ogz_meth_table", animationType = "Drugs",
    --     icon = "fas fa-flask", iconColor = "#00bfff",
        
    --     modelStates = {
    --         off     = { model = "bkr_prop_coke_table01a", sound = nil, particle = nil },
    --         on      = { model = "bkr_prop_coke_table01a", sound = "electric_hum", particle = nil },
    --         working = { model = "bkr_prop_coke_table01a", sound = "chemical_bubbling", particle = { dict = "core", name = "ent_sht_smoke", offset = vec3(0, 0, 0.3), scale = 0.3 } },
    --     },
        
    --     craftingTables = {
    --         { name = "meth_cooking_public", label = "Basic Meth", icon = "fas fa-flask", visibleTo = nil },
    --         { name = "meth_cooking_lost", label = "Lost MC Special", icon = "fas fa-motorcycle", iconColor = "#8B4513", visibleTo = { gangs = {"lost_mc"} } },
    --     },
        
    --     durability = { max = 100, craftCost = 3, repairItem = "ogz_repair_kit" },
    --     cooldown = { craftsBeforeCooldown = 8, cooldownTime = 600 },
    --     coopBonus = { radius = 5.0, speedBonus = 0.20, maxBonus = 0.40 },
        
    --     visibleTo = nil, predefinedSpots = nil,
    -- },

    -- ['coke_table'] = {
    --     label = "Cocaine Processing", model = "bkr_prop_coke_table01a", item = "ogz_coke_table", animationType = "Drugs",
    --     icon = "fas fa-snowflake", iconColor = "#ffffff",
        
    --     modelStates = {
    --         off     = { model = "bkr_prop_coke_table01a", sound = nil, particle = nil },
    --         on      = { model = "bkr_prop_coke_table01a", sound = "electric_hum", particle = nil },
    --         working = { model = "bkr_prop_coke_table01a", sound = "mixing_powder", particle = { dict = "cut_family5", name = "cs_fam5_cargo_dust", offset = vec3(0, 0, 0.2), scale = 0.2 } },
    --     },
        
    --     craftingTables = {
    --         { name = "coke_processing", label = "Cocaine Recipes", icon = "fas fa-snowflake", visibleTo = nil },
    --     },
        
    --     durability = { max = 100, craftCost = 2, repairItem = "ogz_repair_kit" },
    --     cooldown = { craftsBeforeCooldown = 10, cooldownTime = 300 },
    --     coopBonus = { radius = 5.0, speedBonus = 0.15, maxBonus = 0.45 },
        
    --     visibleTo = nil, predefinedSpots = nil,
    -- },

    -- -- ═══════════════════════════════════════════════════════════════════
    -- -- GENERAL CRAFTING
    -- -- ═══════════════════════════════════════════════════════════════════
    -- ['workbench'] = {
    --     label = "Workbench", model = "gr_prop_gr_bench_01b", item = "ogz_workbench", animationType = "Crafting",
    --     icon = "fas fa-tools", iconColor = "#ffa500",
        
    --     modelStates = {
    --         off     = { model = "gr_prop_gr_bench_01b", sound = nil, particle = nil },
    --         on      = { model = "gr_prop_gr_bench_01b", sound = nil, particle = nil },
    --         working = { model = "gr_prop_gr_bench_01b", sound = "workbench_tools", particle = { dict = "core", name = "ent_dst_wood_splinter", offset = vec3(0, 0, 0.8), scale = 0.3 } },
    --     },
        
    --     craftingTables = {
    --         { name = "workbench", label = "General Crafting", icon = "fas fa-tools", visibleTo = nil },
    --     },
        
    --     durability = { max = 150, craftCost = 1, repairItem = "ogz_repair_kit" },
    --     cooldown = { craftsBeforeCooldown = 20, cooldownTime = 120 },
    --     coopBonus = { radius = 3.0, speedBonus = 0.10, maxBonus = 0.30 },
        
    --     visibleTo = nil, predefinedSpots = nil,
    -- },

    -- ['weapon_bench'] = {
    --     label = "Weapons Bench", model = "gr_prop_gr_bench_01a", item = "ogz_weapon_bench", animationType = "Crafting",
    --     icon = "fas fa-gun", iconColor = "#ff4444",
        
    --     modelStates = {
    --         off     = { model = "gr_prop_gr_bench_01a", sound = nil, particle = nil },
    --         on      = { model = "gr_prop_gr_bench_01a", sound = "electric_hum", particle = nil },
    --         working = { model = "gr_prop_gr_bench_01a", sound = "metal_grinding", particle = { dict = "core", name = "ent_dst_metal_frag", offset = vec3(0, 0, 0.8), scale = 0.4 } },
    --     },
        
    --     craftingTables = {
    --         { name = "weapon_crafting", label = "Weapon Crafting", icon = "fas fa-gun", visibleTo = { jobs = {"police"}, gangs = nil } },
    --         { name = "weapon_illegal", label = "Underground", icon = "fas fa-skull-crossbones", iconColor = "#ff0000", visibleTo = { gangs = {"ballas", "vagos", "gsf", "lost_mc"} } },
    --     },
        
    --     durability = { max = 100, craftCost = 5, repairItem = "ogz_repair_kit" },
    --     cooldown = { craftsBeforeCooldown = 5, cooldownTime = 900 },
    --     coopBonus = { radius = 3.0, speedBonus = 0.10, maxBonus = 0.20 },
        
    --     visibleTo = nil, predefinedSpots = nil,
    -- },

    -- -- ═══════════════════════════════════════════════════════════════════
    -- -- COOKING
    -- -- ═══════════════════════════════════════════════════════════════════
    -- ['portable_stove'] = {
    --     label = "Portable Stove", model = "prop_cooker_03", item = "ogz_portable_stove", animationType = "Cooking",
    --     icon = "fas fa-fire-burner", iconColor = "#ff6600",
        
    --     modelStates = {
    --         off     = { model = "prop_cooker_03", sound = nil, particle = nil },
    --         on      = { model = "prop_cooker_03", sound = "gas_burner", particle = { dict = "core", name = "ent_sht_flame", offset = vec3(0, 0, 0.3), scale = 0.2 } },
    --         working = { model = "prop_cooker_03", sound = "cooking_sizzle", particle = { dict = "core", name = "ent_sht_steam", offset = vec3(0, 0, 0.5), scale = 0.4 } },
    --     },
        
    --     craftingTables = {
    --         { name = "cooking", label = "Cooking Recipes", icon = "fas fa-utensils", visibleTo = nil },
    --     },
        
    --     durability = { max = 80, craftCost = 1, repairItem = "ogz_repair_kit" },
    --     cooldown = { craftsBeforeCooldown = 15, cooldownTime = 60 },
    --     coopBonus = { radius = 3.0, speedBonus = 0.10, maxBonus = 0.20 },
        
    --     visibleTo = nil, predefinedSpots = nil,
    -- },

    -- ['portable_grill'] = {
    --     label = "Portable Grill", model = "prop_bbq_1", item = "ogz_portable_grill", animationType = "Grill",
    --     icon = "fas fa-drumstick-bite", iconColor = "#cc6600",
        
    --     modelStates = {
    --         off     = { model = "prop_bbq_1", sound = nil, particle = nil },
    --         on      = { model = "prop_bbq_1", sound = "fire_crackle", particle = { dict = "core", name = "fire_wrecked_car", offset = vec3(0, 0, 0.3), scale = 0.15 } },
    --         working = { model = "prop_bbq_1", sound = "grill_sizzle", particle = { dict = "core", name = "ent_sht_smoke", offset = vec3(0, 0, 0.6), scale = 0.5 } },
    --     },
        
    --     craftingTables = {
    --         { name = "grilling", label = "Grill Recipes", icon = "fas fa-drumstick-bite", visibleTo = nil },
    --     },
        
    --     durability = { max = 80, craftCost = 1, repairItem = "ogz_repair_kit" },
    --     cooldown = { craftsBeforeCooldown = 15, cooldownTime = 60 },
    --     coopBonus = { radius = 4.0, speedBonus = 0.10, maxBonus = 0.30 },
        
    --     visibleTo = nil, predefinedSpots = nil,
    -- },

    -- -- ═══════════════════════════════════════════════════════════════════
    -- -- MEDICAL / LEGAL
    -- -- ═══════════════════════════════════════════════════════════════════
    -- ['medical_station'] = {
    --     label = "Medical Station", model = "prop_medstation_04", item = "ogz_medical_station", animationType = "Medical",
    --     icon = "fas fa-kit-medical", iconColor = "#ff0000",
        
    --     modelStates = {
    --         off     = { model = "prop_medstation_04", sound = nil, particle = nil },
    --         on      = { model = "prop_medstation_04", sound = "electric_hum", particle = nil },
    --         working = { model = "prop_medstation_04", sound = "medical_beep", particle = nil },
    --     },
        
    --     craftingTables = {
    --         { name = "medical_crafting", label = "Medical Supplies", icon = "fas fa-kit-medical", visibleTo = { jobs = {"ambulance", "doctor", "ems"} } },
    --     },
        
    --     durability = { max = 120, craftCost = 1, repairItem = "ogz_repair_kit" },
    --     cooldown = { craftsBeforeCooldown = 25, cooldownTime = 60 },
    --     coopBonus = { radius = 3.0, speedBonus = 0.15, maxBonus = 0.30 },
        
    --     visibleTo = { jobs = {"ambulance", "doctor", "ems"} }, predefinedSpots = nil,
    -- },
}

return Stations
