# 📦 OGz PropManager - Installation Guide

<div align="center">

**Complete Setup Instructions for OGz PropManager v1.0.1**

</div>

---

## 📋 Table of Contents

1. [Prerequisites](#-prerequisites)
2. [Quick Install](#-quick-install)
3. [Database Setup](#-database-setup)
4. [Configuration Files](#-configuration-files)
5. [ox_inventory Integration](#-ox_inventory-integration)
6. [Admin Permissions](#-admin-permissions)
7. [Feature Configuration](#-feature-configuration)
8. [Troubleshooting](#-troubleshooting)
9. [Verification Checklist](#-verification-checklist)

---

## 🔧 Prerequisites

### Required Resources

Ensure these resources are installed and running **BEFORE** ogz_propmanager:

| Resource | Minimum Version | Download |
|----------|-----------------|----------|
| ox_lib | v3.0.0+ | [GitHub](https://github.com/overextended/ox_lib) |
| ox_target | v1.14.0+ | [GitHub](https://github.com/overextended/ox_target) |
| ox_inventory | v2.20.0+ | [GitHub](https://github.com/overextended/ox_inventory) |
| oxmysql | v2.7.0+ | [GitHub](https://github.com/overextended/oxmysql) |
| qbx_core | Latest | [GitHub](https://github.com/Qbox-project/qbx_core) |

### Recommended Resources

| Resource | Purpose | Download |
|----------|---------|----------|
| object_gizmo | Enhanced placement with gizmo controls | [GitHub](https://github.com/overextended/object_gizmo) |
| scully_emotemenu | Animation support | [GitHub](https://github.com/scullyy/scully_emotemenu) |

---

## 🚀 Quick Install

### Step 1: Download & Extract

```bash
# Navigate to your resources folder
cd resources/[ogz]  # or wherever you keep custom resources

# Clone the repository
git clone https://github.com/yourusername/ogz_propmanager.git

# Or extract the ZIP to this location
```

### Step 2: Ensure Load Order

Add to your `server.cfg` in this order:

```cfg
# Dependencies (load these first)
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure oxmysql
ensure qbx_core
ensure object_gizmo  # Optional but recommended

# OGz PropManager
ensure ogz_propmanager
```

### Step 3: Database Setup

The resource will **auto-create** database tables on first start if `Config.Database.AutoCreate = true` (default).

**OR** manually import the SQL:

```bash
mysql -u root -p your_database < ogz_propmanager/sql/install.sql
```

### Step 4: First Start

1. Start your server
2. Check console for: `[OGz PropManager] All systems loaded!`
3. Test admin access: `/propadmin`

---

## 🗄️ Database Setup

### Automatic Setup (Recommended)

By default, all tables are created automatically. Verify in `config/config.lua`:

```lua
Config.Database = {
    TablePrefix = "ogz",           -- Prefix for all tables
    AutoCreate = true,             -- Auto-create tables on start
}
```

### Manual Setup

If you prefer manual setup, run `sql/install.sql`:

```sql
-- Tables created:
-- ogz_stations        - Placed craftable stations
-- ogz_stashes         - Player storage containers
-- ogz_lootables       - Searchable loot props
-- ogz_worldbuilder_props    - Admin-placed world props
-- ogz_worldbuilder_deleted  - Hidden native props
-- ogz_worldprop_cooldowns   - Interaction cooldowns
-- ogz_logs            - Activity logging
```

### Database Verification

```sql
-- Check tables exist
SHOW TABLES LIKE 'ogz_%';

-- Should return:
-- ogz_logs
-- ogz_lootables
-- ogz_stashes
-- ogz_stations
-- ogz_worldbuilder_deleted
-- ogz_worldbuilder_props
-- ogz_worldprop_cooldowns
```

---

## ⚙️ Configuration Files

### File Structure

```
ogz_propmanager/
└── config/
    ├── config.lua          # Master configuration
    ├── stations.lua        # Craftable station definitions
    ├── stashes.lua         # Stash configurations
    ├── lootables.lua       # Lootable prop configs
    ├── worldprops.lua      # Zones & locations
    ├── furniture.lua       # Furniture definitions
    ├── recipes.lua         # Processing recipes
    └── animations.lua      # Animation presets
```

### config/config.lua - Master Settings

```lua
Config = {}

-- Feature Toggles
Config.Features = {
    Stations = true,           -- Craftable stations
    Stashes = true,            -- Placeable storage
    Lootables = true,          -- Searchable props
    WorldProps = true,         -- Zone/location interactions
    Furniture = true,          -- Moveable furniture
    WorldBuilder = true,       -- Admin prop spawning
    Processing = true,         -- Drug processing system
}

-- Debug Mode
Config.Debug = false           -- Enable for verbose logging

-- Database Settings
Config.Database = {
    TablePrefix = "ogz",
    AutoCreate = true,
}

-- Admin Settings
Config.Admin = {
    Enabled = true,
    Command = "propadmin",     -- Admin menu command
    Keybind = nil,             -- Optional keybind (e.g., "F7")
    
    -- Who can access admin menu (ANY match grants access)
    AllowedGroups = { "admin", "god" },
    AllowedJobs = { "admin" },
    AllowedCitizenIds = {
        "ABC12345",            -- Add specific CitizenIDs
    },
}

-- Placement Settings
Config.Placement = {
    Mode = "select",           -- "raycast", "gizmo", or "select" (player chooses)
    CastDistance = 10.0,       -- Max placement distance
    GhostAlpha = 150,          -- Ghost preview transparency (0-255)
    ShowPredefinedMarkers = true,
    MoveSpeed = 0.03,          -- Height adjustment speed
    
    Keys = {
        place = 215,           -- ENTER
        cancel = 202,          -- BACKSPACE
        rotateLeft = 174,      -- LEFT ARROW
        rotateRight = 175,     -- RIGHT ARROW
        heightUp = 172,        -- ARROW UP
        heightDown = 173,      -- ARROW DOWN
        snapGround = 19,       -- ALT
    },
}

-- Ownership Settings
Config.Ownership = {
    OwnerOnly = true,          -- Only owner can remove
    PoliceOverride = true,     -- Police can seize
    PoliceJobs = { "police", "sheriff", "fib" },
}
```

### config/stations.lua - Station Definitions

```lua
Stations = {
    -- Example: Drug Scale
    ["drug_scale"] = {
        label = "Drug Scale",
        model = "bkr_prop_weed_scale_01a",
        craftingTable = "drug_scale",      -- Must match ox_inventory crafting key!
        item = "ogz_drug_scale",           -- Item used to place
        animationType = "Processing",
        icon = "fas fa-balance-scale",
        iconColor = "#00ff00",
        
        -- Visual states based on durability
        modelStates = {
            off = "bkr_prop_weed_scale_01a",
            on = "bkr_prop_weed_scale_01a",
            damaged = "bkr_prop_weed_scale_01a",
        },
        
        -- Who can see/use this station
        visibleTo = nil,                   -- nil = everyone
        -- visibleTo = { jobs = {"dealer"}, gangs = {"ballas"} },
        
        -- Durability settings
        durability = {
            enabled = true,
            max = 100,
            useRate = 1,                   -- Lost per use
            repairItem = "duct_tape",
            repairAmount = 25,
        },
        
        -- Placement limits
        limits = {
            perPlayer = 3,                 -- Max per player
            global = 50,                   -- Max total
        },
    },
    
    -- Add more stations here...
}
```

### config/stashes.lua - Stash Definitions

```lua
Stashes = {
    ["portable_safe"] = {
        label = "Portable Safe",
        model = "prop_ld_int_safe_01",
        item = "ogz_portable_safe",
        icon = "fas fa-box",
        iconColor = "#ffaa00",
        
        slots = 20,
        maxWeight = 50000,                 -- grams
        
        accessType = "owner",              -- "owner", "password", "shared"
        -- password = nil,                 -- Set for password type
        -- sharedWith = {},                -- CitizenIDs for shared
        
        visibleTo = nil,
    },
}
```

### config/lootables.lua - Lootable Props

```lua
Lootables = {
    ["dumpster"] = {
        label = "Search Dumpster",
        models = {
            "prop_dumpster_01a",
            "prop_dumpster_02a",
        },
        icon = "fas fa-dumpster",
        iconColor = "#556b2f",
        
        -- Loot table
        items = {
            { item = "garbage", min = 1, max = 3, chance = 80 },
            { item = "scrap_metal", min = 1, max = 2, chance = 30 },
            { item = "lockpick", min = 1, max = 1, chance = 5 },
        },
        minItems = 1,
        maxItems = 2,
        
        -- Cooldown
        cooldown = {
            type = "player_entity",        -- Per player, per prop
            time = 1800,                   -- 30 minutes
        },
        
        -- Animation
        anim = {
            dict = "amb@prop_human_bum_bin@idle_a",
            name = "idle_a",
            duration = 5000,
        },
        
        -- Police alert
        policeAlert = {
            enabled = true,
            chance = 10,                   -- 10% chance
            message = "Suspicious activity reported",
        },
    },
}
```

### config/worldprops.lua - Zones & Locations

```lua
WorldProps = {
    Settings = {
        Performance = {
            scanInterval = 2000,
            maxPropsPerZone = 150,
        },
    },
    
    -- Zone-Based (v3.4) - Auto-discovery
    Zones = {
        ["weed_farm_north"] = {
            name = "North Weed Farm",
            enabled = true,
            
            zoneType = "circle",
            center = vec3(2220.0, 5577.0, 53.0),
            radius = 20.0,
            
            models = {
                "bkr_prop_weed_lrg_01a",
                "bkr_prop_weed_med_01a",
            },
            
            type = "harvest",
            
            harvest = {
                label = "Harvest Weed",
                icon = "fas fa-cannabis",
                
                yields = {
                    { item = "weed_leaf", min = 1, max = 3, chance = 100 },
                },
                
                cooldown = {
                    type = "player_entity",
                    time = 300,
                },
            },
            
            blip = {
                enabled = true,
                sprite = 469,
                color = 2,
                label = "Weed Farm",
            },
        },
    },
    
    -- Location-Based (v3.0) - Specific coords
    Locations = {
        ["vending_snacks"] = {
            label = "Snack Machine",
            type = "shop",
            
            shop = {
                items = {
                    { item = "sandwich", price = 5, label = "Sandwich" },
                },
            },
            
            locations = {
                vec4(208.15, -932.45, 30.68, 2.0),
            },
        },
    },
}
```

### config/recipes.lua - Processing Recipes

```lua
Recipes = {
    -- Drug Scale recipes (metadata preservation!)
    ["drug_scale"] = {
        {
            id = "cocaine_to_baggies",
            label = "Package Cocaine",
            
            input = {
                { item = "coke", count = 1 },
                { item = "ls_empty_baggy", count = 28 },
            },
            
            output = {
                { item = "cokebaggy", count = 28 },
            },
            
            -- Metadata preservation
            preserveMetadata = {
                from = "coke",
                to = "cokebaggy",
                fields = { "purity" },
            },
            
            time = 10000,
            anim = {
                dict = "anim@amb@business@coc@coc_unpack_cut@",
                name = "coke_cut_v1_coccutter",
            },
            
            requirements = {
                item = "scales",              -- Required tool
            },
        },
    },
}
```

---

## 📦 ox_inventory Integration

### Adding Placement Items

Add to `ox_inventory/data/items.lua`:

```lua
-- Station Items
['ogz_drug_scale'] = {
    label = 'Drug Scale',
    weight = 2000,
    stack = false,
    close = true,
    description = 'A precise scale for measuring substances',
},

['ogz_rosin_press'] = {
    label = 'Rosin Press',
    weight = 5000,
    stack = false,
    close = true,
    description = 'A portable rosin press for extraction',
},

-- Stash Items
['ogz_portable_safe'] = {
    label = 'Portable Safe',
    weight = 10000,
    stack = false,
    close = true,
    description = 'A secure portable storage container',
},

-- Processing Tools
['scales'] = {
    label = 'Digital Scales',
    weight = 500,
    stack = false,
    description = 'Required for precise measurements',
},

['ls_empty_baggy'] = {
    label = 'Empty Baggy',
    weight = 1,
    stack = true,
    description = 'Small plastic bag for packaging',
},

-- Drug Items (with metadata support)
['coke'] = {
    label = 'Cocaine Brick',
    weight = 1000,
    stack = false,
    description = 'A brick of unprocessed cocaine',
    -- ox_inventory will handle metadata (purity)
},

['cokebaggy'] = {
    label = 'Cocaine Baggy',
    weight = 50,
    stack = true,
    description = 'A small bag of cocaine',
},
```

### Adding Crafting Tables

Add to `ox_inventory/data/crafting.lua`:

```lua
-- Station crafting (NOT processing - this is for ox_inventory native crafting)
['rosin_press'] = {
    {
        name = 'purple_haze_rosin',
        label = 'Purple Haze Rosin',
        count = 1,
        time = 10000,
        groups = { ['weed_farmer'] = 0 },
        ingredients = {
            { name = 'purple_haze_seed', count = 5 },
            { name = 'filter_bag', count = 1 },
        },
    },
},

-- Note: Processing system recipes are in config/recipes.lua
-- They handle metadata preservation separately from ox_inventory
```

---

## 🛡️ Admin Permissions

### Option 1: Ace Permissions

```cfg
# In server.cfg
add_ace group.admin ogz.admin allow
add_principal identifier.license:xxxx group.admin
```

### Option 2: CitizenID Whitelist

```lua
-- In config/config.lua
Config.Admin.AllowedCitizenIds = {
    "ABC12345",
    "DEF67890",
}
```

### Option 3: Job-Based

```lua
Config.Admin.AllowedJobs = { "admin", "developer" }
```

### Verification

```
/propadmin
```

Should open the admin menu if permissions are correct.

---

## 🎛️ Feature Configuration

### Enable/Disable Systems

```lua
-- In config/config.lua
Config.Features = {
    Stations = true,      -- Craftable stations
    Stashes = true,       -- Placeable storage
    Lootables = true,     -- Searchable props
    WorldProps = true,    -- Zone/location interactions
    Furniture = true,     -- Moveable furniture
    WorldBuilder = true,  -- Admin prop spawning
    Processing = true,    -- Drug processing
}
```

### World Builder Settings

```lua
Config.WorldBuilder = {
    MaxPropsPerPlayer = 100,
    DefaultRespawnTime = 0,        -- 0 = no respawn
    HideDistance = 100.0,          -- Distance for native hiding
    LaserRange = 50.0,             -- Targeting range
}
```

### Processing System Settings

```lua
Config.Processing = {
    RequireTool = true,            -- Require tool item
    SkillCheck = false,            -- Enable skill checks
    AnimationsEnabled = true,
}
```

---

## 🔧 Troubleshooting

### Common Issues

#### "Admin menu won't open"
1. Check CitizenID is in `AllowedCitizenIds`
2. Verify ace permissions: `add_ace group.admin ogz.admin allow`
3. Run `/ogz_admin_debug` to check status

#### "Stations won't place"
1. Verify item exists in ox_inventory
2. Check `Config.Features.Stations = true`
3. Enable debug: `Config.Debug = true`
4. Check F8 console for errors

#### "Crafting not working"
1. Verify `craftingTable` in stations.lua matches ox_inventory key
2. Check recipe `groups` for job restrictions
3. Ensure ox_inventory crafting.lua is updated

#### "Database errors"
1. Verify oxmysql is running
2. Check connection string in server.cfg
3. Try manual SQL import: `mysql -u root -p db < sql/install.sql`

#### "Props floating in air"
1. Update to latest `placement.lua`
2. Verify `GetGroundZFor_3dCoord` is working
3. Try pressing ALT to snap to ground

### Debug Commands

| Command | Description |
|---------|-------------|
| `/ogzdebug` | Toggle debug mode |
| `/ogzstats` | Show statistics |
| `/ogz_admin_debug` | Check admin status |
| `/ogz_worldprop_debug` | World props debug info |
| `/ogz_worldprop_scan 20` | Scan props in 20m radius |

---

## ✅ Verification Checklist

Use this checklist to verify your installation:

### Core Systems
- [ ] Resource starts without errors
- [ ] Database tables created
- [ ] Admin menu opens with `/propadmin`

### Stations
- [ ] Give station item: `/giveitem [id] ogz_drug_scale 1`
- [ ] Use item to start placement
- [ ] Ghost preview appears
- [ ] Placement confirms and saves
- [ ] ox_target shows interaction
- [ ] Crafting menu opens

### Stashes
- [ ] Place stash item
- [ ] Open stash inventory
- [ ] Items persist after relog

### World Builder
- [ ] `/wb_spawn prop_barrel_01a` works
- [ ] `/wb_delete` shows RED laser
- [ ] `/wb_hash` shows GREEN laser
- [ ] Props persist after restart

### Processing
- [ ] Give drugs with purity via admin menu
- [ ] Process at scale
- [ ] Output maintains purity value

---

## 🆘 Support

- **GitHub Issues**: Report bugs and request features
- **Discord**: [Join our community](#)
- **Documentation**: Check `/docs` folder

---

<div align="center">

**Quality > Speed** 💪

*OGz PropManager v1.0.1*

</div>
