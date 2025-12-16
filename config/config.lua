--[[
    OGz PropManager v3.0 - Main Configuration
    
    CORE SYSTEMS:
    - Stations (Crafting)    → config/stations.lua
    - Stashes (Storage)      → config/stashes.lua
    - Lootables (Loot Props) → config/lootables.lua
    - World Props (Locations)→ config/worldprops.lua
    - Furniture (Movement)   → config/furniture.lua
    
    SUPPORT FILES:
    - Animations → config/animations.lua
    - Sounds     → config/sounds.lua
    - Events     → config/events.lua
]]

Config = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- FEATURE TOGGLES (v3.0)
-- ═══════════════════════════════════════════════════════════════════════════

Config.Features = {
    Stations = true,            -- Craftable prop stations (original v2.0)
    Stashes = true,             -- Portable storage containers (v3.0)
    Lootables = true,           -- Lootable props with item rewards (v3.0)
    WorldProps = true,          -- Location-based world prop interactions (v3.0)
    Furniture = true,           -- Moveable furniture system (v3.0)
    Processing = true,          -- Drug processing with metadata preservation (v3.0)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- GENERAL
-- ═══════════════════════════════════════════════════════════════════════════

Config.Debug = true
Config.VersionCheck = true

-- ═══════════════════════════════════════════════════════════════════════════
-- FRAMEWORK & DEPENDENCIES
-- ═══════════════════════════════════════════════════════════════════════════

Config.Framework = "qbx"                -- "qbx", "qb", "esx"
Config.Target = "ox"                    -- "ox", "qb"
Config.Inventory = "ox"                 -- "ox", "qb", "qs"
Config.InteractDistance = 2.0

-- ═══════════════════════════════════════════════════════════════════════════
-- PLACEMENT
-- ═══════════════════════════════════════════════════════════════════════════

Config.Placement = {
    Mode = "both",                      -- "raycast", "gizmo", "both"
    DefaultMode = "gizmo",
    AllowFreePlace = true,
    AllowPredefined = true,
    CastDistance = 10.0,
    GhostAlpha = 150,
    ShowPredefinedMarkers = true,
    MarkerType = 1,
    MarkerSize = vec3(1.0, 1.0, 0.5),
    MarkerColor = { r = 0, g = 255, b = 100, a = 100 },
    MoveSpeed = 0.005,
    Keys = {
        rotateLeft = 14, rotateRight = 15,
        rotatePitchUp = 68, rotatePitchDown = 69,
        rotateRollLeft = 174, rotateRollRight = 175,
        snapGround = 19, heightUp = 172, heightDown = 173,
        cancel = 202, place = 215,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- OWNERSHIP & LIMITS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Ownership = {
    OwnerOnly = true,                   -- Only owner can remove
    MaxSameStation = 3,                 -- Max same station type per player (0 = unlimited)
    MaxTotalProps = 0,                  -- Max total props per player (0 = unlimited)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- POLICE OVERRIDE
-- ═══════════════════════════════════════════════════════════════════════════

Config.PoliceOverride = {
    Enabled = true,
    Jobs = { "police", "sheriff", "bcso", "sasp", "ranger" },
    ReturnItem = false,                 -- Give item to police on seize?
    SeizeLabel = "Seize Station",
    SeizeIcon = "fas fa-handcuffs",
}

-- ═══════════════════════════════════════════════════════════════════════════
-- DURABILITY SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

Config.Durability = {
    Enabled = true,
    ShowOnTarget = true,                -- Show durability in target label
    WarnAtPercent = 25,                 -- Warn player when below this %
    BreakAtZero = true,                 -- Station unusable at 0%?
    DefaultRepairItem = "ogz_repair_kit",
    RepairAmount = 50,                  -- How much durability repair item restores
    
    -- Visual indicators
    Colors = {
        good = "#00ff00",               -- 75%+
        warning = "#ffff00",            -- 25-74%
        critical = "#ff0000",           -- <25%
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- COOLDOWN SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

Config.Cooldown = {
    Enabled = true,
    ShowTimer = true,                   -- Show remaining cooldown time
    NotifyOnCooldown = true,            -- Notify when entering cooldown
    GlobalCooldownMultiplier = 1.0,     -- Multiply all cooldown times (0.5 = half)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- COOPERATIVE CRAFTING BONUS
-- ═══════════════════════════════════════════════════════════════════════════

Config.CoopBonus = {
    Enabled = true,
    RequireSameGang = true,             -- Must be same gang for bonus?
    RequireSameJob = false,             -- Or same job?
    ShowBonus = true,                   -- Show bonus % in UI
    BonusNotification = true,           -- Notify when coop bonus active
}

-- ═══════════════════════════════════════════════════════════════════════════
-- RANDOM EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Events = {
    Enabled = true,
    GlobalChanceMultiplier = 1.0,       -- Multiply all event chances
    PositiveEventsEnabled = true,
    NegativeEventsEnabled = true,
    CriticalEventsEnabled = true,       -- Explosions, police alerts
}

-- ═══════════════════════════════════════════════════════════════════════════
-- PRODUCTION LOGGING
-- ═══════════════════════════════════════════════════════════════════════════

Config.Logging = {
    Enabled = true,
    LogCrafts = true,                   -- Log every craft
    LogPlacements = true,               -- Log station placements
    LogRemovals = true,                 -- Log station removals/seizures
    LogEvents = true,                   -- Log random events
    RetentionDays = 30,                 -- Delete logs older than X days (0 = never)
    
    -- Discord webhook (optional)
    DiscordWebhook = "",
    DiscordEnabled = false,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SOUNDS & EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Sounds = {
    Enabled = true,
    UseXSound = false,                  -- true = xsound, false = native
    Volume = 0.5,                       -- Master volume (0.0 - 1.0)
}

Config.Particles = {
    Enabled = true,
    UseOnState = true,                  -- Particles during state changes
    UseOnEvents = true,                 -- Particles during events
}

-- ═══════════════════════════════════════════════════════════════════════════
-- DATABASE
-- ═══════════════════════════════════════════════════════════════════════════

Config.Database = {
    AutoSave = true,
    TablePrefix = "ogz_propmanager",    -- Table names: ogz_propmanager, ogz_propmanager_logs
}

Config.UseRoutingBucket = true

-- ═══════════════════════════════════════════════════════════════════════════
-- UI & NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════

Config.UI = {
    TextUI = "ox",                      -- "ox", "qb"
    Notify = "ox",                      -- "ox", "qb", "okok"
    Menu = "ox",                        -- "ox", "qb"
    UseProgress = true,                 -- Use progress bars for animations
    ProgressPosition = "bottom",
    IconColor = "#e07f16",
}

-- ═══════════════════════════════════════════════════════════════════════════
-- ADMIN MENU
-- ═══════════════════════════════════════════════════════════════════════════

Config.Admin = {
    Enabled = true,
    Command = "propadmin",              -- /propadmin to open
    Keybind = nil,                      -- Or set keybind: "F10"
    
    -- Who can access admin menu
    AllowedGroups = { "admin", "god", "mod" },
    AllowedJobs = {},                   -- Or specific jobs
    AllowedCitizenIds = {"NJ47F3RZ"},             -- Or specific players
    
    -- Admin permissions (what each can do)
    Permissions = {
        -- v2.0 Station permissions
        viewAllStations = true,         -- See all placed stations
        teleportToStation = true,       -- TP to any station
        removeAnyStation = true,        -- Remove without ownership
        repairAnyStation = true,        -- Repair any station
        setCooldown = true,             -- Clear/set cooldowns
        setDurability = true,           -- Set station durability
        viewLogs = true,                -- View production logs
        clearLogs = true,               -- Clear log history
        spawnStations = true,           -- Spawn stations without item
        giveItems = true,               -- Give station items
        
        -- v3.0 Stash permissions
        viewAllStashes = true,          -- See all placed stashes
        openAnyStash = true,            -- Open without ownership
        removeAnyStash = true,          -- Remove without ownership
        spawnStashes = true,            -- Spawn stashes without item
        
        -- v3.0 Lootable permissions
        viewAllLootables = true,        -- See all lootables
        spawnLootables = true,          -- Spawn lootables
        removeLootables = true,         -- Remove lootables
        resetLootCooldowns = true,      -- Reset player cooldowns
        
        -- v3.0 World Props permissions
        manageWorldProps = true,        -- Create/edit world prop locations
        
        -- v3.0 Furniture permissions
        resetAllFurniture = true,       -- Reset all moved furniture
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- NOTIFICATIONS (Messages)
-- ═══════════════════════════════════════════════════════════════════════════

Config.Notifications = {
    PlaceSuccess = "Station placed successfully!",
    PlaceFail = "Failed to place station.",
    RemoveSuccess = "Station removed.",
    RemoveFail = "Failed to remove station.",
    NotOwner = "You don't own this station.",
    MaxStations = "Maximum stations reached (%s/%s).",
    PoliceSeize = "Station seized successfully.",
    Cancelled = "Placement cancelled.",
    InvalidLocation = "Cannot place here.",
    
    -- Durability
    DurabilityLow = "⚠️ Station durability low (%s%%)!",
    DurabilityBroken = "❌ Station is broken! Repair required.",
    DurabilityRepaired = "✅ Station repaired! (+%s%%)",
    
    -- Cooldown
    OnCooldown = "Station cooling down... %s remaining",
    CooldownReady = "Station ready to use!",
    
    -- Coop
    CoopBonusActive = "👥 Coop bonus active! (+%s%% speed)",
    
    -- Access
    NoAccess = "You don't have access to any recipes here.",
    NoRecipes = "No recipes available at this station.",
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- v3.0 NOTIFICATIONS
    -- ═══════════════════════════════════════════════════════════════════════
    
    -- Stashes
    StashPlaced = "Storage placed successfully!",
    StashRemoved = "Storage picked up.",
    StashNoAccess = "You don't have access to this storage.",
    StashEmpty = "You must empty this storage before picking it up.",
    
    -- Lootables
    LootSearching = "Searching...",
    LootFound = "You found some items!",
    LootEmpty = "Nothing useful here.",
    LootCooldown = "You've already searched this recently.",
    
    -- World Props
    WorldPropCooldown = "You can use this again in %s.",
    
    -- Furniture
    FurniturePulled = "Pulled out.",
    FurniturePushed = "Pushed back.",
    FurnitureRotated = "Rotated.",
}

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 STASH SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Stashes = {
    -- Default stash settings (can be overridden per-stash in stashes.lua)
    DefaultSlots = 10,
    DefaultMaxWeight = 50000,               -- 50kg default
    
    -- Access settings
    AllowGangSharing = true,                -- Auto-share with placer's gang
    AllowCustomAccess = true,               -- Owner can set custom access
    
    -- Police override (same as stations)
    PoliceCanSearch = true,                 -- Police can open any stash
    PoliceCanSeize = true,                  -- Police can pick up stashes
    
    -- Stash ID prefix
    IdPrefix = "ogz_stash_",
}

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 LOOTABLE SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Lootables = {
    -- Cooldown defaults
    DefaultCooldownType = "player",         -- "player", "global", "none"
    DefaultCooldownTime = 3600,             -- 1 hour default
    
    -- Animation defaults
    DefaultSearchTime = 5000,               -- 5 seconds
    
    -- One-time loot behavior
    DespawnDelay = 60,                      -- Seconds before one-time loot despawns
}

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 WORLD PROP SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.WorldPropsSettings = {
    -- Location-based only (confirmed by The OG KiLLz for performance)
    UseLocationBased = true,                -- MUST be true - no global model targeting
    
    -- Detection radius for location-based props
    DetectionRadius = 2.0,                  -- How close player must be to interact
    
    -- Stash settings for world prop stashes
    StashPerPlayer = true,                  -- Each player gets own stash at location
}

-- ═══════════════════════════════════════════════════════════════════════════
-- v3.0 FURNITURE MOVEMENT SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Config.FurnitureSettings = {
    -- Movement distances
    DefaultPullDistance = 0.6,              -- Meters to pull toward player
    DefaultPushDistance = 0.4,              -- Meters to push away
    
    -- Rotation
    AllowRotation = true,
    RotationStep = 15.0,                    -- Degrees per rotation action
    
    -- Persistence (confirmed: reset on restart)
    PersistAcrossRestart = false,           -- DO NOT persist - respect mapping coords
    
    -- Animation
    AnimationDuration = 1500,               -- Milliseconds
}

return Config
