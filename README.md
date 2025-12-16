# 🏭 OGz PropManager

**Modular Prop Placement System with ox_inventory Crafting Integration**

A clean, modular system for placing craftable station props that connect directly to ox_inventory's native crafting benches with full job/gang security support.

---

## ✨ Features

- 🔧 **Modular Station System** - Easily add new craftable stations via config
- 🔒 **Job/Gang Security** - Respects ox_inventory recipe restrictions
- 👤 **Owner-Only Removal** - Props can only be removed by the player who placed them
- 👮 **Police Seizure** - Cops can seize illegal stations
- 💾 **Database Persistence** - Props survive server restarts
- 🏠 **Routing Bucket Support** - Works with apartment shells
- 👻 **Ghost Preview** - See where your prop will be placed
- 🎮 **Multiple Placement Modes** - Raycast or Gizmo (ox_lib)
- 📊 **Station Limits** - Limit how many of each station a player can place

---

## 📦 Dependencies

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- [qbx_core](https://github.com/Qbox-project/qbx_core) (or qb-core with adjustments)

---

## 🚀 Installation

### 1. Download & Extract
Place `ogz_propmanager` in your resources folder.

### 2. Database Setup
Run the SQL in `sql/install.sql` OR let it auto-create (enabled by default).

### 3. Add to server.cfg
```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure ogz_propmanager
```

### 4. Add Items to ox_inventory
Add the placement items to `ox_inventory/data/items.lua`:
```lua
['ogz_rosin_press'] = {
    label = 'Rosin Press',
    weight = 5000,
    stack = false,
    close = true,
    description = 'A portable rosin press',
},
-- See examples/crafting_example.lua for more items
```

### 5. Add Crafting Recipes to ox_inventory
Add your recipes to `ox_inventory/data/crafting.lua`:
```lua
['rosin_press'] = {
    {
        name = 'purple_haze_rosin',
        label = 'Purple Haze Rosin',
        count = 1,
        time = 10000,
        groups = { ['weed_farmer'] = 0 },  -- Job locked!
        ingredients = {
            { name = 'purple_haze_seed', count = 5 },
            { name = 'filter_bag', count = 1 },
        },
    },
},
```
See `examples/crafting_example.lua` for full examples.

---

## ⚙️ Configuration

### config/config.lua
Main settings for placement, ownership, and UI.

### config/stations.lua
Define your craft stations here. Each station needs:
- `label` - Display name
- `model` - Prop model name
- `craftingTable` - **Must match** the key in ox_inventory crafting.lua
- `item` - Item used to place this station
- `animationType` - References animations.lua
- `visibleTo` - (Optional) Job/gang visibility restrictions

### config/animations.lua
Reusable animation configs for different station types.

---

## 🎯 How It Works

### Placement Flow
1. Player uses a station item (e.g., `ogz_rosin_press`)
2. Ghost preview appears for positioning
3. Player confirms placement (Enter) or cancels (Backspace/ESC)
4. Prop spawns with ox_target options
5. Saved to database for persistence

### Crafting Flow
1. Player approaches placed station
2. ox_target shows "Use [Station Name]"
3. Opens ox_inventory crafting bench
4. **ox_inventory handles all job/gang recipe filtering!**

### Removal Flow
- **Owner**: Can remove their own stations (gets item back)
- **Police**: Can seize stations they don't own (configurable)

---

## 🔐 Security Layers

| Layer | Controlled By | Description |
|-------|---------------|-------------|
| **Target Visibility** | `stations.lua` → `visibleTo` | Who can SEE the target option |
| **Recipe Access** | ox_inventory `groups` | Who can CRAFT each recipe |
| **Removal** | `config.lua` → `OwnerOnly` | Only owner can remove |
| **Seizure** | `config.lua` → `PoliceOverride` | Police can seize |

---

## 📝 Adding New Stations

### Step 1: Add to stations.lua
```lua
['my_station'] = {
    label = "My Station",
    model = "prop_model_name",
    craftingTable = "my_crafting_key",
    item = "ogz_my_station",
    animationType = "Crafting",
    icon = "fas fa-cog",
    iconColor = "#ffffff",
    visibleTo = nil,  -- Everyone can see
},
```

### Step 2: Add item to ox_inventory items.lua
```lua
['ogz_my_station'] = {
    label = 'My Station',
    weight = 5000,
    stack = false,
    close = true,
},
```

### Step 3: Add recipes to ox_inventory crafting.lua
```lua
['my_crafting_key'] = {
    {
        name = 'output_item',
        label = 'Output Item',
        count = 1,
        time = 5000,
        groups = nil,
        ingredients = {
            { name = 'input_item', count = 1 },
        },
    },
},
```

---

## 🛠️ Exports

### Client
```lua
exports.ogz_propmanager:StartPlacement(stationId)
exports.ogz_propmanager:CancelPlacement()
exports.ogz_propmanager:IsPlacing()
exports.ogz_propmanager:GetPlacedProps()
```

### Server
```lua
exports.ogz_propmanager:GetPropsByCitizen(citizenid)
exports.ogz_propmanager:GetPropsByBucket(bucket)
exports.ogz_propmanager:DeleteAllPropsByCitizen(citizenid)
```

---

## 🐛 Debug Commands

When `Config.Debug = true`:

| Command | Description |
|---------|-------------|
| `ogz_debug_props` | List all locally tracked props |
| `ogz_test_place <stationId>` | Test placement without item |
| `ogz_admin_listprops` (server) | List all props in database |
| `ogz_admin_clearprops <citizenid>` (server) | Delete all props for a citizen |

---

## 📄 License

This resource is provided as-is for use in FiveM servers.

---

## 🤝 Credits

- **The OG KiLLz** - Concept & Vision
- **Claude** - Development Partner
- **Overextended** - ox_lib, ox_target, ox_inventory
- **QBox Project** - qbx_core

---

**Quality > Speed** 💪
