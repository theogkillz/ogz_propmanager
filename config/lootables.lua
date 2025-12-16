--[[
    OGz PropManager v3.3 - Lootables Configuration
    
    FEATURES:
    - Player-placed lootables (item-based)
    - Timer-based auto-despawn
    - Search limits
    - Custom loot override
    - Police alert chance
    - Required items to search
    - Loot scaling by player count
    - Full admin options
    
    LOOT TABLE FORMAT:
    items = {
        { item = "item_name", chance = 50, min = 1, max = 3 },
        ...
    }
]]

Lootables = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- DEFAULT SETTINGS (can be overridden per-lootable)
-- ═══════════════════════════════════════════════════════════════════════════

Lootables.Defaults = {
    -- Timing
    despawnOnSearch = false,            -- Despawn after first search?
    despawnTimer = 0,                   -- Auto-despawn after X minutes (0 = never)
    
    -- Search limits
    maxSearches = 0,                    -- Max times can be searched (0 = unlimited)
    searchCooldown = {
        type = "player",                -- "none", "player", "global"
        time = 3600,                    -- Cooldown in seconds
    },
    
    -- Loot settings
    minItems = 1,
    maxItems = 3,
    lootMultiplier = 1.0,               -- Multiply item counts
    
    -- Scaling (adjust loot based on nearby players)
    scaling = {
        enabled = false,
        radius = 50.0,                  -- Check radius for nearby players
        minPlayers = 1,
        maxPlayers = 10,
        minMultiplier = 1.0,            -- Multiplier at minPlayers
        maxMultiplier = 2.0,            -- Multiplier at maxPlayers
    },
    
    -- Police alert
    policeAlert = {
        enabled = false,
        chance = 0,                     -- % chance (0-100)
        message = "Suspicious activity reported",
        blipDuration = 60,              -- Seconds
    },
    
    -- Required item to search
    requiredItem = nil,                 -- Item name or nil
    consumeRequired = false,            -- Consume the required item?
    
    -- Animation
    searchAnim = {
        dict = "amb@prop_human_bum_bin@idle_a",
        anim = "idle_a",
        duration = 5000,
    },
    
    -- Visibility
    visibleTo = nil,                    -- nil = everyone, or { jobs = {}, gangs = {} }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- PLAYER-PLACEABLE LOOTABLES (Found in robberies, etc.)
-- ═══════════════════════════════════════════════════════════════════════════

Lootables['suspicious_bag'] = {
    label = "Suspicious Bag",
    description = "A bag that looks like it contains something valuable",
    icon = "fas fa-bag-shopping",
    iconColor = "#8B4513",
    
    -- Item that players use to place this
    item = "suspicious_bag",
    
    -- Models (first is default)
    models = { "prop_cs_heist_bag_02" },
    
    -- Player-placed settings
    playerPlaced = true,
    despawnOnSearch = true,             -- Disappears after being searched
    despawnTimer = 30,                  -- Or despawn after 30 mins if not searched
    
    -- Loot configuration
    loot = {
        minItems = 1,
        maxItems = 4,
        items = {
            { item = "cash", chance = 80, min = 500, max = 2000 },
            { item = "goldbar", chance = 15, min = 1, max = 1 },
            { item = "rolex", chance = 25, min = 1, max = 2 },
            { item = "diamond", chance = 10, min = 1, max = 1 },
            { item = "lockpick", chance = 40, min = 1, max = 3 },
        },
    },
    
    -- Search settings
    searchAnim = {
        dict = "anim@mp_snowball",
        anim = "pickup_snowball",
        duration = 4000,
    },
    
    -- Police alert when searched
    policeAlert = {
        enabled = true,
        chance = 25,                    -- 25% chance
        message = "Suspicious activity - possible stolen goods",
        blipDuration = 45,
    },
}

Lootables['locked_case'] = {
    label = "Locked Case",
    description = "A heavy locked case - you'll need tools to open it",
    icon = "fas fa-briefcase",
    iconColor = "#333333",
    
    item = "locked_case",
    models = { "prop_ld_case_01" },
    
    playerPlaced = true,
    despawnOnSearch = true,
    despawnTimer = 60,
    
    -- Requires lockpick to open
    requiredItem = "lockpick",
    consumeRequired = true,             -- Uses up the lockpick
    
    loot = {
        minItems = 2,
        maxItems = 5,
        items = {
            { item = "cash", chance = 90, min = 1000, max = 5000 },
            { item = "goldbar", chance = 30, min = 1, max = 2 },
            { item = "rolex", chance = 40, min = 1, max = 1 },
            { item = "diamond", chance = 20, min = 1, max = 2 },
            { item = "cryptostick", chance = 5, min = 1, max = 1 },
        },
    },
    
    searchAnim = {
        dict = "anim@heists@ornate_bank@grab_cash",
        anim = "grab",
        duration = 6000,
    },
    
    policeAlert = {
        enabled = true,
        chance = 40,
        message = "Breaking and entering reported",
        blipDuration = 60,
    },
}

Lootables['evidence_box'] = {
    label = "Evidence Box",
    description = "Police evidence - highly risky to search",
    icon = "fas fa-box-archive",
    iconColor = "#0055ff",
    
    item = "evidence_box",
    models = { "prop_box_ammo07a" },
    
    playerPlaced = true,
    despawnOnSearch = true,
    despawnTimer = 15,
    
    loot = {
        minItems = 1,
        maxItems = 3,
        items = {
            { item = "weapon_pistol", chance = 30, min = 1, max = 1 },
            { item = "pistol_ammo", chance = 60, min = 12, max = 36 },
            { item = "meth", chance = 40, min = 5, max = 15 },
            { item = "coke_brick", chance = 25, min = 1, max = 2 },
            { item = "cash", chance = 50, min = 500, max = 2500 },
        },
    },
    
    policeAlert = {
        enabled = true,
        chance = 75,                    -- High risk!
        message = "Evidence tampering in progress!",
        blipDuration = 90,
    },
    
    -- Only certain gangs might know about these
    visibleTo = nil,  -- Set to { gangs = { "ballas", "vagos" } } if needed
}

-- ═══════════════════════════════════════════════════════════════════════════
-- WORLD/EVENT LOOTABLES (Admin-placed for events/missions)
-- ═══════════════════════════════════════════════════════════════════════════

Lootables['event_crate'] = {
    label = "Supply Crate",
    description = "Event supply crate with valuable loot",
    icon = "fas fa-parachute-box",
    iconColor = "#ff9900",
    
    -- No item - admin spawned only
    item = nil,
    adminOnly = true,
    
    models = { 
        "prop_mil_crate_01",
        "prop_mil_crate_02",
        "prop_box_wood01a",
    },
    
    -- Default event settings (admin can override)
    despawnOnSearch = false,
    despawnTimer = 0,
    maxSearches = 5,                    -- First 5 players get loot
    
    loot = {
        minItems = 2,
        maxItems = 4,
        items = {
            { item = "cash", chance = 100, min = 1000, max = 3000 },
            { item = "armor", chance = 50, min = 1, max = 1 },
            { item = "bandage", chance = 70, min = 2, max = 5 },
            { item = "water", chance = 60, min = 1, max = 3 },
            { item = "sandwich", chance = 60, min = 1, max = 2 },
        },
    },
    
    -- Scaling for events
    scaling = {
        enabled = true,
        radius = 100.0,
        minPlayers = 1,
        maxPlayers = 20,
        minMultiplier = 1.0,
        maxMultiplier = 3.0,
    },
    
    searchAnim = {
        dict = "anim@heists@ornate_bank@grab_cash",
        anim = "grab",
        duration = 5000,
    },
}

Lootables['airdrop'] = {
    label = "Airdrop",
    description = "Military airdrop - high value target",
    icon = "fas fa-plane",
    iconColor = "#00ff00",
    
    item = nil,
    adminOnly = true,
    
    models = { "prop_mil_crate_01" },
    
    despawnOnSearch = false,
    despawnTimer = 15,                  -- 15 min event window
    maxSearches = 3,
    
    loot = {
        minItems = 3,
        maxItems = 6,
        items = {
            { item = "cash", chance = 100, min = 5000, max = 15000 },
            { item = "goldbar", chance = 40, min = 1, max = 3 },
            { item = "weapon_smg", chance = 20, min = 1, max = 1 },
            { item = "smg_ammo", chance = 50, min = 30, max = 60 },
            { item = "armor", chance = 60, min = 1, max = 2 },
            { item = "cryptostick", chance = 10, min = 1, max = 1 },
        },
    },
    
    policeAlert = {
        enabled = true,
        chance = 100,                   -- Always alerts
        message = "Military airdrop being looted!",
        blipDuration = 120,
    },
    
    scaling = {
        enabled = true,
        radius = 150.0,
        minPlayers = 1,
        maxPlayers = 30,
        minMultiplier = 1.0,
        maxMultiplier = 4.0,
    },
}

Lootables['mission_briefcase'] = {
    label = "Mission Briefcase",
    description = "RP mission objective",
    icon = "fas fa-suitcase",
    iconColor = "#ff0000",
    
    item = nil,
    adminOnly = true,
    
    models = { "prop_ld_case_01", "p_ld_heist_bag_s" },
    
    despawnOnSearch = true,             -- One person gets it
    maxSearches = 1,
    
    loot = {
        minItems = 1,
        maxItems = 1,
        items = {
            { item = "mission_documents", chance = 100, min = 1, max = 1 },
        },
    },
    
    searchAnim = {
        dict = "anim@mp_snowball",
        anim = "pickup_snowball",
        duration = 3000,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- WORLD LOOTABLES (Persistent, respawning)
-- ═══════════════════════════════════════════════════════════════════════════

Lootables['trash_can'] = {
    label = "Search Trash",
    description = "Maybe someone threw away something useful",
    icon = "fas fa-trash",
    iconColor = "#666666",
    
    item = nil,
    adminOnly = true,
    
    models = { 
        "prop_bin_01a",
        "prop_bin_02a",
        "prop_bin_03a",
        "prop_dumpster_01a",
    },
    
    despawnOnSearch = false,
    
    loot = {
        minItems = 0,                   -- Can find nothing
        maxItems = 2,
        cooldown = {
            type = "player",
            time = 1800,                -- 30 min cooldown per player
        },
        items = {
            { item = "water_bottle", chance = 30, min = 1, max = 1 },
            { item = "burger", chance = 20, min = 1, max = 1 },
            { item = "cash", chance = 15, min = 5, max = 50 },
            { item = "lockpick", chance = 5, min = 1, max = 1 },
            { item = "plastic", chance = 40, min = 1, max = 3 },
            { item = "metalscrap", chance = 25, min = 1, max = 2 },
        },
    },
    
    searchAnim = {
        dict = "amb@prop_human_bum_bin@idle_a",
        anim = "idle_a",
        duration = 4000,
    },
}

Lootables['dumpster'] = {
    label = "Search Dumpster",
    description = "Dive into the dumpster for treasures",
    icon = "fas fa-dumpster",
    iconColor = "#445544",
    
    item = nil,
    adminOnly = true,
    
    models = { "prop_dumpster_01a", "prop_dumpster_02a" },
    
    despawnOnSearch = false,
    
    loot = {
        minItems = 1,
        maxItems = 3,
        cooldown = {
            type = "player",
            time = 2700,                -- 45 min cooldown
        },
        items = {
            { item = "water_bottle", chance = 40, min = 1, max = 2 },
            { item = "burger", chance = 30, min = 1, max = 1 },
            { item = "cash", chance = 20, min = 10, max = 100 },
            { item = "phone", chance = 5, min = 1, max = 1 },
            { item = "plastic", chance = 50, min = 2, max = 5 },
            { item = "metalscrap", chance = 35, min = 1, max = 3 },
            { item = "electronics", chance = 10, min = 1, max = 1 },
        },
    },
    
    searchAnim = {
        dict = "amb@prop_human_bum_bin@idle_a",
        anim = "idle_a",
        duration = 6000,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS (Outside Lootables table to prevent iteration issues)
-- ═══════════════════════════════════════════════════════════════════════════

---Get lootable config by item name
---@param itemName string
---@return string|nil lootType
---@return table|nil config
function GetLootableByItem(itemName)
    for lootType, config in pairs(Lootables) do
        if type(config) == "table" and config.item == itemName then
            return lootType, config
        end
    end
    return nil, nil
end

---Get setting with fallback to defaults
---@param lootConfig table
---@param key string
---@param subkey string|nil
---@return any
function GetLootableSetting(lootConfig, key, subkey)
    if subkey then
        -- Nested setting (e.g., policeAlert.chance)
        if lootConfig[key] and lootConfig[key][subkey] ~= nil then
            return lootConfig[key][subkey]
        end
        if Lootables.Defaults and Lootables.Defaults[key] and Lootables.Defaults[key][subkey] ~= nil then
            return Lootables.Defaults[key][subkey]
        end
        return nil
    else
        -- Direct setting
        if lootConfig[key] ~= nil then
            return lootConfig[key]
        end
        return Lootables.Defaults and Lootables.Defaults[key] or nil
    end
end

return Lootables
