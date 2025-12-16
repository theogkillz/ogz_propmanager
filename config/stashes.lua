--[[
    OGz PropManager v3.0 - Stash Definitions
    
    Portable storage containers that integrate with ox_inventory's stash system.
    Each placed stash gets a unique ID for persistent storage.
    
    STRUCTURE:
    ['stash_id'] = {
        label           = "Display Name",
        model           = "prop_model_name",
        item            = "inventory_item_to_place",
        icon            = "fas fa-icon",
        iconColor       = "#hexcolor",
        animationType   = "Placement",          -- Animation type from animations.lua
        
        stash = {
            slots       = 10,                   -- Inventory slots
            maxWeight   = 50000,                -- Max weight in grams
            owner       = true,                 -- Owner-only access?
            groups      = nil,                  -- { police = 1, ambulance = 2 } job grades
            shareWithGang = false,              -- Auto-share with placer's gang?
            shareWithJob = false,               -- Auto-share with placer's job?
            allowCustomAccess = true,           -- Owner can set custom access?
            hidden      = false,                -- Requires search/skill to find?
        },
        
        -- Optional visual states (open/closed)
        modelStates = {
            closed = { model = "prop_closed" },
            open   = { model = "prop_open" },
        },
        
        -- Access restrictions (who can place/see this stash type)
        visibleTo = nil,                        -- { gangs = {}, jobs = {} }
        
        -- Predefined spawn locations
        predefinedSpots = nil,                  -- { vec4(x,y,z,h), ... }
    }
    
    ACCESS PRIORITY:
    1. Owner always has access
    2. If shareWithGang = true, same gang members have access
    3. If shareWithJob = true, same job members have access
    4. If groups defined, those job grades have access
    5. Police can override if Config.Stashes.PoliceCanSearch = true
]]

Stashes = {
    -- ═══════════════════════════════════════════════════════════════════════
    -- PERSONAL STORAGE
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['portable_safe'] = {
        label = "Portable Safe",
        model = "prop_ld_int_safe_01",
        item = "ogz_portable_safe",
        icon = "fas fa-vault",
        iconColor = "#888888",
        animationType = "Placement",
        
        stash = {
            slots = 15,
            maxWeight = 75000,              -- 75kg
            owner = true,                   -- Owner only
            groups = nil,
            shareWithGang = false,
            shareWithJob = false,
            allowCustomAccess = true,       -- Can add friends
            hidden = false,
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    ['small_lockbox'] = {
        label = "Small Lockbox",
        model = "prop_cs_cardbox_01",
        item = "ogz_small_lockbox",
        icon = "fas fa-box",
        iconColor = "#8B4513",
        animationType = "Placement",
        
        stash = {
            slots = 5,
            maxWeight = 15000,              -- 15kg
            owner = true,
            groups = nil,
            shareWithGang = false,
            shareWithJob = false,
            allowCustomAccess = false,      -- Personal only
            hidden = false,
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    ['hidden_compartment'] = {
        label = "Hidden Compartment",
        model = "prop_tool_box_01",
        item = "ogz_hidden_compartment",
        icon = "fas fa-eye-slash",
        iconColor = "#333333",
        animationType = "Placement",
        
        stash = {
            slots = 5,
            maxWeight = 10000,              -- 10kg
            owner = true,
            groups = nil,
            shareWithGang = false,
            shareWithJob = false,
            allowCustomAccess = false,
            hidden = true,                  -- Requires searching to find!
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- GANG/GROUP STORAGE
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['gang_locker'] = {
        label = "Gang Locker",
        model = "prop_cs_locker_01",
        item = "ogz_gang_locker",
        icon = "fas fa-users",
        iconColor = "#ff4444",
        animationType = "Placement",
        
        stash = {
            slots = 30,
            maxWeight = 150000,             -- 150kg
            owner = false,                  -- Gang shared, not owner-only
            groups = nil,                   -- Will be set to placer's gang dynamically
            shareWithGang = true,           -- Auto-share with gang
            shareWithJob = false,
            allowCustomAccess = true,       -- Leader can add non-members
            hidden = false,
        },
        
        visibleTo = nil,                    -- Anyone can place, but only gang can access
        predefinedSpots = nil,
    },
    
    ['crew_stash'] = {
        label = "Crew Stash Box",
        model = "prop_box_wood01a",
        item = "ogz_crew_stash",
        icon = "fas fa-people-group",
        iconColor = "#4444ff",
        animationType = "Placement",
        
        stash = {
            slots = 20,
            maxWeight = 100000,             -- 100kg
            owner = false,
            groups = nil,
            shareWithGang = true,
            shareWithJob = false,
            allowCustomAccess = true,
            hidden = false,
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- JOB STORAGE
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['job_supply_crate'] = {
        label = "Job Supply Crate",
        model = "prop_mil_crate_01",
        item = "ogz_job_supply_crate",
        icon = "fas fa-briefcase",
        iconColor = "#4a7c4e",
        animationType = "Placement",
        
        stash = {
            slots = 25,
            maxWeight = 120000,             -- 120kg
            owner = false,
            groups = nil,                   -- Set dynamically to placer's job
            shareWithGang = false,
            shareWithJob = true,            -- Job members can access
            allowCustomAccess = true,
            hidden = false,
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- SPECIALTY STORAGE
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['cooler_box'] = {
        label = "Cooler Box",
        model = "prop_cooler_01",
        item = "ogz_cooler_box",
        icon = "fas fa-snowflake",
        iconColor = "#00bfff",
        animationType = "Placement",
        
        stash = {
            slots = 10,
            maxWeight = 30000,              -- 30kg
            owner = true,
            groups = nil,
            shareWithGang = false,
            shareWithJob = false,
            allowCustomAccess = true,
            hidden = false,
        },
        
        -- Optional: Could add special metadata for cold storage
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    ['weapons_case'] = {
        label = "Weapons Case",
        model = "prop_gun_case_01",
        item = "ogz_weapons_case",
        icon = "fas fa-gun",
        iconColor = "#cc0000",
        animationType = "Placement",
        
        stash = {
            slots = 8,
            maxWeight = 50000,              -- 50kg
            owner = true,
            groups = nil,
            shareWithGang = true,           -- Gang shared for ops
            shareWithJob = false,
            allowCustomAccess = true,
            hidden = false,
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    ['duffle_bag'] = {
        label = "Duffle Bag",
        model = "prop_cs_heist_bag_01",
        item = "ogz_duffle_bag",
        icon = "fas fa-bag-shopping",
        iconColor = "#2f2f2f",
        animationType = "Placement",
        
        stash = {
            slots = 12,
            maxWeight = 40000,              -- 40kg
            owner = true,
            groups = nil,
            shareWithGang = false,
            shareWithJob = false,
            allowCustomAccess = false,
            hidden = false,
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    --[[
    ═══════════════════════════════════════════════════════════════════════
    EXAMPLE: Police Evidence Locker (Job-Restricted)
    ═══════════════════════════════════════════════════════════════════════
    
    ['evidence_locker'] = {
        label = "Evidence Locker",
        model = "prop_cs_locker_01",
        item = "ogz_evidence_locker",
        icon = "fas fa-file-shield",
        iconColor = "#0055ff",
        animationType = "Placement",
        
        stash = {
            slots = 50,
            maxWeight = 200000,
            owner = false,
            groups = { police = 0, sheriff = 0, bcso = 0 },  -- All grades
            shareWithGang = false,
            shareWithJob = true,
            allowCustomAccess = false,
            hidden = false,
        },
        
        -- Only police jobs can place this
        visibleTo = { jobs = {"police", "sheriff", "bcso"} },
        predefinedSpots = nil,
    },
    ]]
}

return Stashes
