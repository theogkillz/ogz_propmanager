# 🔥 OGz PropManager v3.0 - Expansion Plan

**Project:** OGz PropManager → Full Prop Ecosystem Manager  
**Architect:** Claude & The OG KiLLz  
**Date:** December 13, 2025  
**Philosophy:** Quality > Speed | Claude vs Claude vs The World

---

## 📋 Executive Summary

Transforming `ogz_propmanager` from a crafting station placer into a **comprehensive prop management ecosystem** with 4 major new systems:

| # | Feature | Complexity | Impact |
|---|---------|------------|--------|
| 1 | **Portable Stashes** | Medium | Placeable storage containers |
| 2 | **Lootable Props** | Medium | Admin-placed loot containers |
| 3 | **World Prop Integration** | Medium-High | Attach to existing GTA props |
| 4 | **Chair Movement System** | High (Revolutionary!) | Pull/push furniture in world |

---

## 🏗️ Architecture Overview

### Current v2.0 Structure
```
ogz_propmanager/
├── config/
│   ├── config.lua      # General settings
│   ├── stations.lua    # Crafting station definitions
│   ├── animations.lua  # Animation configs
│   ├── sounds.lua      # Sound effects
│   └── events.lua      # Random events
├── client/ & server/   # Core logic
└── sql/                # Database schema
```

### Proposed v3.0 Structure
```
ogz_propmanager/
├── config/
│   ├── config.lua          # General + NEW FEATURE TOGGLES
│   ├── stations.lua        # Crafting stations (unchanged)
│   ├── stashes.lua         # NEW: Portable stash definitions
│   ├── lootables.lua       # NEW: Lootable prop definitions
│   ├── worldprops.lua      # NEW: World prop integration configs
│   ├── furniture.lua       # NEW: Moveable furniture definitions
│   ├── animations.lua      # Updated with new anims
│   ├── sounds.lua          # Updated with new sounds
│   └── events.lua          # Events (unchanged)
├── client/
│   ├── main.lua            # Updated entry point
│   ├── utils.lua           # Extended helpers
│   ├── placement.lua       # Shared placement (unchanged)
│   ├── target.lua          # Extended targeting
│   ├── states.lua          # Model states (unchanged)
│   ├── crafting.lua        # Crafting (unchanged)
│   ├── admin.lua           # Extended admin menu
│   ├── stashes.lua         # NEW: Stash client logic
│   ├── lootables.lua       # NEW: Lootable client logic
│   ├── worldprops.lua      # NEW: World prop client logic
│   └── furniture.lua       # NEW: Furniture movement logic
├── server/
│   ├── main.lua            # Updated core
│   ├── database.lua        # Extended DB functions
│   ├── admin.lua           # Extended admin
│   ├── stashes.lua         # NEW: Stash server logic
│   ├── lootables.lua       # NEW: Lootable server logic
│   └── furniture.lua       # NEW: Furniture server logic
└── sql/
    └── install.sql         # Extended schema
```

---

## 🗄️ Feature 1: Portable Stashes

### Concept
Players can place storage containers (safes, lockers, containers) that integrate with **ox_inventory's stash system**. Each placed stash gets a unique ID for persistent storage.

### How ox_inventory Stashes Work
```lua
-- Register a stash
exports.ox_inventory:RegisterStash('stash_unique_id', 'Stash Label', slots, weight)

-- Open a stash for player
exports.ox_inventory:openInventory('stash', 'stash_unique_id')
```

### Config Structure (`config/stashes.lua`)
```lua
Stashes = {
    ['portable_safe'] = {
        label = "Portable Safe",
        model = "prop_ld_int_safe_01",
        item = "ogz_portable_safe",       -- Item to place it
        icon = "fas fa-vault",
        iconColor = "#888888",
        
        -- Stash settings
        stash = {
            slots = 10,                    -- Inventory slots
            maxWeight = 50000,             -- Max weight (grams)
            owner = true,                  -- Owner-only access?
            groups = nil,                  -- Job/gang access: { police = 1 }
        },
        
        -- Placement settings
        animationType = "Placement",
        durability = nil,                  -- Stashes don't degrade
        
        -- Visual states (optional)
        modelStates = {
            closed = { model = "prop_ld_int_safe_01" },
            open = { model = "prop_ld_int_safe_01" },  -- Same or different
        },
        
        visibleTo = nil,
        predefinedSpots = nil,
    },
    
    ['gang_locker'] = {
        label = "Gang Locker",
        model = "prop_cs_locker_01",
        item = "ogz_gang_locker",
        icon = "fas fa-box",
        iconColor = "#ff4444",
        
        stash = {
            slots = 25,
            maxWeight = 100000,
            owner = false,                 -- Gang-shared access
            groups = nil,                  -- Set dynamically to placer's gang
            shareWithGang = true,          -- NEW: Auto-share with gang
        },
        
        animationType = "Placement",
    },
    
    ['hidden_compartment'] = {
        label = "Hidden Compartment",
        model = "prop_tool_box_01",
        item = "ogz_hidden_compartment",
        icon = "fas fa-eye-slash",
        iconColor = "#333333",
        
        stash = {
            slots = 5,
            maxWeight = 15000,
            owner = true,
            hidden = true,                 -- Requires search to find
        },
        
        animationType = "Placement",
    },
}
```

### Database Schema Addition
```sql
-- Add to existing ogz_propmanager table OR new table
ALTER TABLE `ogz_propmanager` ADD COLUMN `prop_type` ENUM('station', 'stash', 'lootable', 'worldprop') DEFAULT 'station';
ALTER TABLE `ogz_propmanager` ADD COLUMN `stash_id` VARCHAR(100) NULL;
ALTER TABLE `ogz_propmanager` ADD COLUMN `stash_data` JSON NULL;

-- OR separate table approach (cleaner):
CREATE TABLE IF NOT EXISTS `ogz_propmanager_stashes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `stash_id` VARCHAR(100) UNIQUE NOT NULL,  -- e.g., 'ogz_stash_123'
    `citizenid` VARCHAR(50) NOT NULL,
    `stash_type` VARCHAR(50) NOT NULL,         -- Config key
    `model` VARCHAR(100) NOT NULL,
    `coords` JSON NOT NULL,
    `heading` FLOAT NOT NULL,
    `routing_bucket` INT DEFAULT 0,
    `access_gang` VARCHAR(50) NULL,
    `access_job` VARCHAR(50) NULL,
    `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_stash` (`stash_id`),
    INDEX `idx_citizen` (`citizenid`),
    INDEX `idx_bucket` (`routing_bucket`)
);
```

### Target Options
```lua
{
    label = "Open Safe",              -- Owner/authorized
    icon = "fas fa-lock-open",
    onSelect = function() OpenStash(propId) end,
},
{
    label = "Pick Up Safe",           -- Owner only
    icon = "fas fa-hand",
    onSelect = function() RemoveStash(propId) end,
},
{
    label = "Crack Safe",             -- Police/criminal skill
    icon = "fas fa-unlock-alt",
    onSelect = function() AttemptCrack(propId) end,
    canInteract = function() return not IsOwner() end,
}
```

### Key Server Logic
```lua
-- On stash placement
RegisterNetEvent("ogz_propmanager:server:PlaceStash", function(data)
    local stashId = "ogz_stash_" .. os.time() .. "_" .. math.random(1000, 9999)
    local stashConfig = Stashes[data.stashType]
    
    -- Register with ox_inventory
    exports.ox_inventory:RegisterStash(stashId, stashConfig.label, 
        stashConfig.stash.slots, stashConfig.stash.maxWeight)
    
    -- Save to database
    Database_InsertStash(citizenid, stashId, data.stashType, ...)
end)

-- On stash removal - PRESERVE CONTENTS!
RegisterNetEvent("ogz_propmanager:server:RemoveStash", function(propId)
    local stashData = Database_GetStash(propId)
    -- Stash contents persist in ox_inventory even after removal
    -- Return the item to player
    Database_DeleteStash(propId)
end)
```

---

## 🎁 Feature 2: Lootable Props

### Concept
Admin-placed or server-spawned props that contain **pre-configured loot**. Players can search them once (or on a cooldown) to receive items.

### Config Structure (`config/lootables.lua`)
```lua
Lootables = {
    ['trash_can_common'] = {
        label = "Trash Can",
        models = {                              -- Multiple models allowed!
            "prop_bin_01a",
            "prop_bin_02a", 
            "prop_bin_03a",
        },
        icon = "fas fa-trash",
        iconColor = "#666666",
        
        -- Loot settings
        loot = {
            -- Loot table with weights
            items = {
                { item = "burger", min = 1, max = 2, chance = 30 },
                { item = "water", min = 1, max = 1, chance = 25 },
                { item = "garbage", min = 1, max = 5, chance = 60 },
                { item = "lockpick", min = 1, max = 1, chance = 5 },
                { item = "money", min = 5, max = 50, chance = 15 },
            },
            minItems = 1,                       -- Min items to give
            maxItems = 3,                       -- Max items to give
            
            -- Cooldown
            cooldown = {
                type = "player",                -- "player", "global", "none"
                time = 3600,                    -- Seconds (1 hour)
            },
            
            -- One-time loot (despawn after)
            oneTime = false,
        },
        
        -- Animation while searching
        searchAnim = {
            dict = "anim@gangops@facility@servers@bodysearch@",
            anim = "player_search",
            duration = 5000,
        },
        
        -- Sound on search
        searchSound = "search_rummage",
        
        -- Spawn settings (for admin/server spawning)
        canAdminSpawn = true,
        predefinedSpots = nil,
    },
    
    ['supply_crate'] = {
        label = "Supply Crate",
        models = { "prop_mil_crate_01" },
        icon = "fas fa-box-open",
        iconColor = "#4a7c4e",
        
        loot = {
            items = {
                { item = "pistol_ammo", min = 10, max = 30, chance = 40 },
                { item = "bandage", min = 1, max = 3, chance = 50 },
                { item = "radio", min = 1, max = 1, chance = 20 },
            },
            minItems = 2,
            maxItems = 4,
            cooldown = { type = "global", time = 7200 },
            oneTime = false,
        },
        
        searchAnim = { dict = "amb@prop_human_bum_bin@idle_a", anim = "idle_a", duration = 4000 },
        
        -- Gang/job restricted
        visibleTo = { gangs = {"ballas", "vagos"} },
    },
    
    ['hidden_stash_rock'] = {
        label = "Suspicious Rock",
        models = { "prop_rock_4_d" },
        icon = "fas fa-gem",
        iconColor = "#8B4513",
        
        loot = {
            items = {
                { item = "coke_brick", min = 1, max = 2, chance = 30 },
                { item = "weed_baggy", min = 1, max = 5, chance = 50 },
                { item = "dirty_money", min = 500, max = 2000, chance = 40 },
            },
            minItems = 1,
            maxItems = 2,
            cooldown = { type = "player", time = 86400 },  -- 24 hours
            oneTime = false,
        },
        
        -- Hidden until searched (police skill?)
        hidden = true,
        revealDistance = 2.0,
    },
}
```

### Database Schema
```sql
CREATE TABLE IF NOT EXISTS `ogz_propmanager_lootables` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `loot_type` VARCHAR(50) NOT NULL,
    `model` VARCHAR(100) NOT NULL,
    `coords` JSON NOT NULL,
    `heading` FLOAT NOT NULL,
    `routing_bucket` INT DEFAULT 0,
    `last_looted` TIMESTAMP NULL,             -- For global cooldown
    `times_looted` INT DEFAULT 0,
    `placed_by` VARCHAR(50) NULL,             -- Admin who placed it
    `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_type` (`loot_type`),
    INDEX `idx_bucket` (`routing_bucket`)
);

-- Track player loot cooldowns
CREATE TABLE IF NOT EXISTS `ogz_propmanager_loot_cooldowns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `lootable_id` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `looted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_loot` (`lootable_id`, `citizenid`),
    INDEX `idx_citizen` (`citizenid`)
);
```

### Loot Roll Logic
```lua
function RollLoot(lootConfig)
    local results = {}
    local itemCount = math.random(lootConfig.minItems, lootConfig.maxItems)
    
    -- Shuffle and roll
    local pool = {}
    for _, item in ipairs(lootConfig.items) do
        if math.random(100) <= item.chance then
            table.insert(pool, item)
        end
    end
    
    -- Pick random items from pool
    for i = 1, math.min(itemCount, #pool) do
        local idx = math.random(#pool)
        local item = pool[idx]
        table.insert(results, {
            item = item.item,
            count = math.random(item.min, item.max)
        })
        table.remove(pool, idx)
    end
    
    return results
end
```

---

## 🌍 Feature 3: World Prop Integration

### Concept
Attach stashes, crafting stations, or **multi-item rewards** to existing world props (vending machines, dumpsters, specific objects). No placement needed - targets existing GTA props.

### Config Structure (`config/worldprops.lua`)
```lua
WorldProps = {
    -- VENDING MACHINES
    ['vending_snack'] = {
        label = "Snack Machine",
        models = {
            "prop_vend_snak_01",
            "prop_vend_snak_01_tu",
        },
        icon = "fas fa-cookie",
        iconColor = "#ff9900",
        
        -- Interaction type
        type = "shop",                          -- "shop", "stash", "crafting", "reward"
        
        -- Shop config
        shop = {
            items = {
                { item = "sandwich", price = 5, label = "Sandwich" },
                { item = "chips", price = 3, label = "Chips" },
                { item = "chocolate", price = 4, label = "Chocolate Bar" },
            },
        },
    },
    
    ['vending_soda'] = {
        label = "Soda Machine",
        models = {
            "prop_vend_soda_01",
            "prop_vend_soda_02",
        },
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
    },
    
    -- DUMPSTERS - Multi-item rewards!
    ['dumpster_search'] = {
        label = "Dumpster",
        models = {
            "prop_dumpster_01a",
            "prop_dumpster_02a",
            "prop_dumpster_02b",
        },
        icon = "fas fa-dumpster",
        iconColor = "#556b2f",
        
        type = "reward",                        -- Multi-item reward!
        
        reward = {
            items = {
                { item = "garbage", min = 1, max = 3, chance = 80 },
                { item = "scrap_metal", min = 1, max = 2, chance = 30 },
                { item = "electronics", min = 1, max = 1, chance = 10 },
                { item = "lockpick", min = 1, max = 1, chance = 5 },
            },
            minItems = 1,
            maxItems = 2,
            
            -- Cooldown (per-player, per-dumpster-location)
            cooldown = {
                type = "player_location",       -- Unique per player per coords
                time = 1800,                    -- 30 minutes
            },
        },
        
        searchAnim = {
            dict = "amb@prop_human_bum_bin@idle_a",
            anim = "idle_a",
            duration = 5000,
        },
    },
    
    -- ATTACH STASH TO EXISTING PROP
    ['atm_hidden_stash'] = {
        label = "ATM",
        models = {
            "prop_atm_01",
            "prop_atm_02",
            "prop_fleeca_atm",
        },
        icon = "fas fa-money-bill",
        iconColor = "#00ff00",
        
        type = "stash",
        
        stash = {
            slots = 5,
            maxWeight = 10000,
            owner = true,                       -- Personal stash per player
            perPlayer = true,                   -- Each player gets own stash at each ATM
        },
        
        -- Only show to certain people
        visibleTo = { gangs = {"ballas", "vagos"} },
    },
    
    -- ATTACH CRAFTING TO WORKBENCH PROPS
    ['workbench_world'] = {
        label = "Workbench",
        models = {
            "prop_tool_bench02",
            "gr_prop_gr_bench_01b",
        },
        icon = "fas fa-tools",
        iconColor = "#ffa500",
        
        type = "crafting",
        
        craftingTables = {
            { name = "basic_crafting", label = "Basic Crafting" },
        },
    },
}
```

### How World Prop Detection Works
```lua
-- On resource start, scan for world props
CreateThread(function()
    Wait(5000)  -- Wait for world to load
    
    for propId, config in pairs(WorldProps) do
        for _, modelName in ipairs(config.models) do
            local modelHash = GetHashKey(modelName)
            
            -- Find all instances of this model in the world
            -- NOTE: Can use zones instead for performance
        end
    end
end)

-- Alternative: Use ox_target's built-in model targeting
for propId, config in pairs(WorldProps) do
    exports.ox_target:addModel(config.models, {
        {
            label = config.label,
            icon = config.icon,
            onSelect = function(data)
                HandleWorldPropInteraction(propId, config, data.entity, data.coords)
            end,
        }
    })
end
```

### Cooldown Tracking for World Props
```sql
-- Track per-player per-location cooldowns
CREATE TABLE IF NOT EXISTS `ogz_propmanager_world_cooldowns` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `citizenid` VARCHAR(50) NOT NULL,
    `prop_type` VARCHAR(50) NOT NULL,
    `location_hash` VARCHAR(100) NOT NULL,    -- Hash of coords
    `last_used` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_cooldown` (`citizenid`, `prop_type`, `location_hash`),
    INDEX `idx_citizen` (`citizenid`)
);
```

---

## 🪑 Feature 4: Chair Movement System (THE BIG ONE!)

### Concept
**Revolutionary FiveM feature** - Allow players to **pull out chairs** that are too close to tables, enabling proper sit mechanics. Can also push chairs back, move other furniture.

### Why This Matters
- Many GTA interiors have chairs clipping into tables
- Standard sit scripts can't use these chairs
- Players have to awkwardly position themselves
- **No existing solution on the market!**

### Technical Approach

#### Option A: Entity Offset Manipulation (Simpler)
```lua
-- Store original position, move entity relative to player
function PullOutChair(entity)
    local playerPos = GetEntityCoords(PlayerPedId())
    local chairPos = GetEntityCoords(entity)
    
    -- Calculate direction from chair to player
    local dir = norm(playerPos - chairPos)
    
    -- Move chair toward player by X units
    local newPos = chairPos + (dir * Config.Furniture.PullDistance)
    
    SetEntityCoords(entity, newPos.x, newPos.y, newPos.z)
end
```
**Pros:** Simple, works immediately  
**Cons:** May not persist, might reset on chunk reload

#### Option B: Object Replacement (More Robust)
```lua
-- Delete world prop, spawn own entity at new position
function PullOutChair(entity)
    local model = GetEntityModel(entity)
    local pos = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local originalPos = pos  -- Store for reset
    
    -- Calculate new position
    local newPos = CalculatePullPosition(pos, heading)
    
    -- Delete original (if possible) or make invisible
    SetEntityAlpha(entity, 0, false)
    SetEntityCollision(entity, false, false)
    
    -- Spawn replacement
    local newChair = CreateObject(model, newPos.x, newPos.y, newPos.z, false, false, false)
    SetEntityHeading(newChair, heading)
    PlaceObjectOnGroundProperly(newChair)
    FreezeEntityPosition(newChair, true)
    
    -- Track for reset
    SaveMovedFurniture(entity, newChair, originalPos)
end
```
**Pros:** Full control, can persist  
**Cons:** More complex, need to handle cleanup

#### Option C: Hybrid (Recommended)
- Use **offset manipulation for player-owned props**
- Use **replacement for world props**
- **Save moved positions to database** for persistence across sessions

### Config Structure (`config/furniture.lua`)
```lua
Furniture = {
    -- Global settings
    Enabled = true,
    PullDistance = 0.6,                         -- How far to pull (meters)
    PushDistance = 0.4,                         -- How far to push
    ResetOnRestart = false,                     -- Reset all moved furniture on restart?
    
    -- Which models can be moved
    Moveable = {
        -- CHAIRS
        chairs = {
            models = {
                "prop_chair_01a", "prop_chair_01b", "prop_chair_02",
                "prop_chair_03", "prop_chair_04a", "prop_chair_04b",
                "prop_chair_05", "prop_chair_06", "prop_chair_07",
                "prop_chair_08", "prop_chair_09", "prop_chair_10",
                "prop_off_chair_01", "prop_off_chair_03", "prop_off_chair_04",
                "prop_off_chair_04b", "prop_off_chair_05",
                "prop_sol_chair", "prop_bar_stool_01",
                "prop_table_04_chr", "prop_table_05_chr",
                "prop_table_06_chr", "prop_yaught_chair_01",
                "v_club_officechair", "v_ilev_chair02_ped",
                "hei_heist_stn_chairarm", "hei_heist_stn_chairarm_01",
                -- Add more as needed
            },
            pullDistance = 0.6,
            pushDistance = 0.4,
            canRotate = true,
            icon = "fas fa-chair",
            iconColor = "#8B4513",
        },
        
        -- STOOLS
        stools = {
            models = {
                "prop_bar_stool_01", "prop_bar_stool_02",
                "prop_off_chair_01", "v_corp_offchair",
            },
            pullDistance = 0.4,
            pushDistance = 0.3,
            canRotate = true,
            icon = "fas fa-chair",
            iconColor = "#666666",
        },
        
        -- OTHER FURNITURE (optional expansion)
        -- tables = { ... },
        -- boxes = { ... },
    },
    
    -- Animation while moving
    MoveAnim = {
        dict = "anim@heists@box_carry@",
        anim = "idle",
        duration = 1500,
    },
    
    -- Sounds
    Sounds = {
        pull = "chair_scrape",
        push = "chair_scrape",
        rotate = nil,
    },
}
```

### Database Schema for Persistence
```sql
CREATE TABLE IF NOT EXISTS `ogz_propmanager_furniture` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `original_hash` BIGINT NOT NULL,          -- Hash of original entity/position
    `model` VARCHAR(100) NOT NULL,
    `original_coords` JSON NOT NULL,
    `current_coords` JSON NOT NULL,
    `heading` FLOAT NOT NULL,
    `routing_bucket` INT DEFAULT 0,
    `moved_by` VARCHAR(50) NOT NULL,
    `moved_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_furniture` (`original_hash`, `routing_bucket`),
    INDEX `idx_bucket` (`routing_bucket`)
);
```

### Target Options
```lua
-- Added to chairs dynamically via ox_target:addModel
{
    label = "Pull Out Chair",
    icon = "fas fa-arrow-left",
    onSelect = function(data)
        PullChair(data.entity)
    end,
    canInteract = function(entity, distance, coords, name, bone)
        return not IsChairPulledOut(entity)
    end,
},
{
    label = "Push Chair Back",
    icon = "fas fa-arrow-right",
    onSelect = function(data)
        PushChair(data.entity)
    end,
    canInteract = function(entity, distance, coords, name, bone)
        return IsChairPulledOut(entity)
    end,
},
{
    label = "Rotate Chair",
    icon = "fas fa-rotate",
    onSelect = function(data)
        RotateChair(data.entity)
    end,
    canInteract = function()
        return Furniture.Moveable.chairs.canRotate
    end,
}
```

### Key Client Logic
```lua
local MovedFurniture = {}  -- Track locally moved furniture

function PullChair(entity)
    local model = GetEntityModel(entity)
    local pos = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    
    -- Calculate pull direction (toward player)
    local playerPos = GetEntityCoords(PlayerPedId())
    local direction = norm(vec3(playerPos.x - pos.x, playerPos.y - pos.y, 0))
    local pullDist = GetPullDistance(model)
    
    -- New position
    local newPos = vec3(
        pos.x + (direction.x * pullDist),
        pos.y + (direction.y * pullDist),
        pos.z
    )
    
    -- Play animation
    PlayMoveAnimation()
    
    -- Move the entity
    SetEntityCoords(entity, newPos.x, newPos.y, newPos.z, false, false, false, false)
    
    -- Track it
    local hash = GetFurnitureHash(pos, model)
    MovedFurniture[hash] = {
        entity = entity,
        original = pos,
        current = newPos,
        heading = heading,
        model = model,
    }
    
    -- Save to server
    TriggerServerEvent("ogz_propmanager:server:SaveMovedFurniture", hash, model, pos, newPos, heading)
    
    PlaySound("pull")
end

-- On player load, restore moved furniture
RegisterNetEvent("ogz_propmanager:client:LoadMovedFurniture", function(furnitureList)
    for _, data in ipairs(furnitureList) do
        -- Find entity at original position
        local entity = GetClosestObjectOfType(
            data.original_coords.x, data.original_coords.y, data.original_coords.z,
            1.0, GetHashKey(data.model), false, false, false
        )
        
        if entity and entity ~= 0 then
            -- Move to saved position
            SetEntityCoords(entity, 
                data.current_coords.x, 
                data.current_coords.y, 
                data.current_coords.z
            )
            SetEntityHeading(entity, data.heading)
        end
    end
end)
```

---

## 📊 Implementation Phases

### Phase 1: Foundation Updates (Session 1)
- [ ] Update `config/config.lua` with feature toggles
- [ ] Create new config files (stashes.lua, lootables.lua, etc.)
- [ ] Update `sql/install.sql` with new tables
- [ ] Update `fxmanifest.lua` with new files

### Phase 2: Portable Stashes (Sessions 2-3)
- [ ] Create `client/stashes.lua`
- [ ] Create `server/stashes.lua`
- [ ] Add stash placement flow
- [ ] Integrate ox_inventory stash registration
- [ ] Add target options
- [ ] Admin menu integration

### Phase 3: Lootable Props (Sessions 4-5)
- [ ] Create `client/lootables.lua`
- [ ] Create `server/lootables.lua`
- [ ] Implement loot roll system
- [ ] Cooldown tracking
- [ ] Admin spawning interface

### Phase 4: World Prop Integration (Sessions 6-7)
- [ ] Create `client/worldprops.lua`
- [ ] Create `server/worldprops.lua`
- [ ] ox_target model registration
- [ ] Shop/stash/reward handlers
- [ ] Per-player per-location cooldowns

### Phase 5: Chair Movement System (Sessions 8-10)
- [ ] Create `config/furniture.lua`
- [ ] Create `client/furniture.lua`
- [ ] Create `server/furniture.lua`
- [ ] Entity manipulation logic
- [ ] Persistence system
- [ ] Testing with various chair models

### Phase 6: Polish & Integration (Sessions 11-12)
- [ ] Full admin menu updates
- [ ] Cross-feature testing
- [ ] Documentation
- [ ] Performance optimization

---

## ❓ Questions for The OG KiLLz

Before we start coding, let's confirm some decisions:

### 1. Database Approach
**Option A:** Add columns to existing `ogz_propmanager` table with `prop_type` column  
**Option B:** Separate tables for each feature (cleaner, recommended)  
**Preference?**

### 2. Stash Access
Should gang lockers:
- Auto-share with placer's gang?
- Allow owner to set custom access?
- Both?

### 3. World Prop Scope
Should world props be:
- **Server-wide** (same targets everywhere)?
- **Zone-based** (only in certain areas)?
- **Configurable per-prop?**

### 4. Chair System - Persistence
- **Persist forever** (until manually reset)?
- **Reset on server restart?**
- **Reset after X hours?**

### 5. Priority Order
Which feature do you want to tackle first?
1. Portable Stashes
2. Lootable Props
3. World Prop Integration
4. Chair Movement System

---

## 🔥 Let's Get It!

Once you confirm the approach, we'll dive into Phase 1 and start building this beast!

**Claude vs Claude vs The World** 💪
