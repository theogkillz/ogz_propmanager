# 🏭 OGz PropManager

<div align="center">

![Version](https://img.shields.io/badge/Version-1.0.1-blue?style=for-the-badge)
![Framework](https://img.shields.io/badge/Framework-QBX%20%7C%20QBCore-green?style=for-the-badge)
![Inventory](https://img.shields.io/badge/Inventory-ox__inventory-orange?style=for-the-badge)

**The Ultimate Prop Management System for FiveM**

*Craftable Stations • Placeable Stashes • Dynamic Lootables • World Builder • Processing System*

**Claude vs Claude vs The World** 🌍

---

<!-- 📸 SCREENSHOT: Hero banner showing multiple features in action -->
<!-- Suggested: A wide shot showing a player near a placed station with the crafting UI open -->

</div>

---

## 🌟 What is OGz PropManager?

OGz PropManager is a **comprehensive, modular prop management system** that transforms how players interact with the world. From placing craftable workstations to building entire environments, this resource provides everything you need for an immersive roleplay experience.

### 🎯 Core Systems

| System | Description |
|--------|-------------|
| 🏭 **Stations** | Placeable crafting stations with durability, ownership, and ox_inventory integration |
| 📦 **Stashes** | Player-placed storage containers with access control |
| 🎰 **Lootables** | Timer-based searchable props with police alerts |
| 🌍 **World Props** | Zone-based auto-discovery and location-based interactions |
| 🪑 **Furniture** | Moveable furniture system for interiors |
| 🏗️ **World Builder** | Admin prop spawning with laser targeting and native hiding |
| ⚗️ **Processing** | Revolutionary metadata-preserving drug processing system |

---

## ✨ Feature Highlights

<!-- 📸 SCREENSHOT: Station placement with ghost preview -->

### 🏭 Craftable Station System

- **Ghost Preview** - See exactly where your prop will be placed
- **Multiple Placement Modes** - Raycast or Gizmo (with object_gizmo support)
- **Ground Snap** - Automatic ground detection with manual override
- **Durability System** - Stations degrade with use, require repair
- **Visual States** - Props change appearance based on condition
- **Owner-Only Removal** - Only the owner can pick up their station
- **Police Seizure** - Law enforcement can confiscate illegal stations
- **Job/Gang Locking** - Restrict who can see and use stations

<!-- 📸 SCREENSHOT: Crafting menu open at a station -->

### ⚗️ Processing System (The Crown Jewel)

Our **revolutionary metadata preservation system** maintains item properties through crafting transformations:

```
📦 Cocaine (100% Purity) + 28x Empty Baggies
                    ↓
        ⚗️ Process at Scale
                    ↓
        📦 28x Cocaine Baggies (100% Purity!) ✨
```

- **Purity Tracking** - Drug purity carries through processing
- **Quality Preservation** - Item quality maintained across transformations
- **Multi-Step Chains** - Support for complex processing workflows
- **Animation Integration** - Cinematic crafting animations
- **Skill Requirements** - Optional skill-based success rates

<!-- 📸 SCREENSHOT: Processing menu showing purity values -->

### 📦 Placeable Stashes

- **Access Control** - Owner-only, password, or shared access
- **Capacity Limits** - Configurable slots and weight
- **Visual Variety** - Multiple stash prop options
- **Persistence** - Survives server restarts
- **Admin Management** - View and manage all stashes

<!-- 📸 SCREENSHOT: Player placing a stash with the preview -->

### 🎰 Lootable System

- **Timer-Based Respawning** - Loot regenerates after configurable cooldowns
- **Police Alerts** - Configurable alerts when searching certain props
- **Loot Tables** - Weighted random item distribution
- **Animation Support** - Searching animations with progress bars
- **Player-Placed Lootables** - Players can place their own lootable props

<!-- 📸 SCREENSHOT: Player searching a lootable with progress bar -->

### 🌍 World Props (Zones & Locations)

**Two Approaches for Maximum Flexibility:**

#### Zone-Based Auto-Discovery (v3.4)
Define a zone, and the system automatically finds and makes props interactive:
- 🌿 Weed farms with harvestable plants
- ⛏️ Mining areas with ore deposits
- 🍎 Orchards with fruit trees
- Perfect for mass prop interactions

#### Location-Based (v3.0)
Specific coordinates for unique interactions:
- 🏪 Vending machines
- 🔧 Workbenches
- 📦 Hidden stashes
- Perfect for precise placements

<!-- 📸 SCREENSHOT: Zone debug view showing prop discovery -->

### 🏗️ World Builder (Admin Tool)

The ultimate map editing toolkit:

| Feature | Description |
|---------|-------------|
| 📦 **Spawn Props** | Place any prop model with preview |
| 🔴 **Delete Mode** | RED laser targeting for prop removal |
| 🟢 **Hash Mode** | GREEN laser to copy model info |
| 🙈 **Hide Natives** | Hide GTA props without streaming |
| 💾 **Database Sync** | All changes persist across restarts |
| 📋 **Prop Groups** | Organize props into manageable groups |

<!-- 📸 SCREENSHOT: World Builder laser targeting a prop -->

### 🛡️ Comprehensive Admin Menu

Clean, organized admin interface with three main categories:

```
🔧 OGz PropManager Admin
│
├── 🏭 Station Management
│   ├── Station Overview
│   ├── Search Stations
│   ├── View Logs
│   ├── Statistics
│   ├── Give Items
│   ├── Give with Purity
│   └── Quick Actions
│
├── 📦 Prop Systems
│   ├── Stash Manager
│   ├── Lootable Manager
│   ├── World Props (Full v3.4 Support!)
│   └── Furniture Tools
│
└── 🏗️ World Builder
    ├── Spawn Props
    ├── Delete Mode
    ├── Hash Mode
    ├── List/Scan Props
    └── Hide Native Props
```

<!-- 📸 SCREENSHOT: Admin menu open showing categories -->

---

## 📊 Technical Specifications

### Performance Optimized

- **Distance-Based Rendering** - Props only render within 100m
- **Entity Pooling** - Efficient entity management
- **Batched Database Ops** - Minimal SQL overhead
- **Smart Targeting** - ox_target zones created on-demand

### Security Layers

| Layer | Purpose | Controlled By |
|-------|---------|---------------|
| **Target Visibility** | Who sees interaction options | `visibleTo` config |
| **Recipe Access** | Who can craft what | ox_inventory `groups` |
| **Ownership** | Who can remove props | Database owner field |
| **Admin Access** | Who can use admin menu | Ace perms / CitizenID |

### Database Schema

- `ogz_stations` - Placed craftable stations
- `ogz_stashes` - Player storage containers
- `ogz_lootables` - Searchable loot props
- `ogz_worldbuilder_props` - Admin-placed world props
- `ogz_worldbuilder_deleted` - Hidden native props
- `ogz_worldprop_cooldowns` - Interaction cooldowns
- `ogz_logs` - Activity logging

---

## 📦 Dependencies

| Resource | Purpose | Required |
|----------|---------|----------|
| [ox_lib](https://github.com/overextended/ox_lib) | UI, callbacks, zones | ✅ Yes |
| [ox_target](https://github.com/overextended/ox_target) | Targeting system | ✅ Yes |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Inventory & crafting | ✅ Yes |
| [oxmysql](https://github.com/overextended/oxmysql) | Database | ✅ Yes |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Framework | ✅ Yes |
| [object_gizmo](https://github.com/overextended/object_gizmo) | Gizmo placement | ⭐ Recommended |
| [scully_emotemenu](https://github.com/scullyy/scully_emotemenu) | Animations | 🔄 Optional |

---

## 🚀 Quick Start

```bash
# 1. Clone to your resources folder
cd resources/[ogz]
git clone https://github.com/yourusername/ogz_propmanager

# 2. Import database (or let auto-create handle it)
mysql -u root -p your_database < ogz_propmanager/sql/install.sql

# 3. Add to server.cfg
ensure ogz_propmanager

# 4. Configure your stations in config/stations.lua
# 5. Add items to ox_inventory
# 6. Restart server!
```

📖 **For detailed installation instructions, see [INSTALL.md](INSTALL.md)**

---

## 🎮 Player Commands

| Command | Description |
|---------|-------------|
| `/propadmin` | Open admin menu (requires permission) |
| `/wb_spawn <model>` | Quick spawn a prop |
| `/wb_delete` | Enter delete mode |
| `/wb_hash` | Enter hash mode |
| `/wb_list` | List nearby World Builder props |
| `/wb_scan <radius>` | Scan for props in radius |
| `/wb_reload` | Reload all World Builder props |

---

## 🔧 Configuration Overview

```
ogz_propmanager/
├── config/
│   ├── config.lua          # Main settings
│   ├── stations.lua        # Craftable station definitions
│   ├── stashes.lua         # Stash configurations
│   ├── lootables.lua       # Lootable prop configs
│   ├── worldprops.lua      # Zones & locations
│   ├── furniture.lua       # Furniture definitions
│   ├── recipes.lua         # Processing recipes
│   └── animations.lua      # Animation presets
├── client/
├── server/
├── sql/
│   └── install.sql         # Database schema
└── fxmanifest.lua
```

---

## 🛠️ Exports

### Client Exports

```lua
-- Placement
exports.ogz_propmanager:StartPlacement(stationId)
exports.ogz_propmanager:CancelPlacement()
exports.ogz_propmanager:IsPlacing()

-- World Builder
exports.ogz_propmanager:StartWorldPropPlacement(model, options)
exports.ogz_propmanager:GetSpawnedProps()
exports.ogz_propmanager:GetDeletedNativeProps()

-- World Props
exports.ogz_propmanager:IsInZone(zoneId)
exports.ogz_propmanager:GetActiveZoneProps(zoneId)
exports.ogz_propmanager:ReloadWorldProps()
```

### Server Exports

```lua
-- Station Management
exports.ogz_propmanager:GetPropsByCitizen(citizenid)
exports.ogz_propmanager:GetPropsByBucket(bucket)
exports.ogz_propmanager:DeleteAllPropsByCitizen(citizenid)

-- Stash Management
exports.ogz_propmanager:GetStashById(stashId)
exports.ogz_propmanager:GetStashesByOwner(citizenid)
```

---

## 📸 Screenshots

<!-- 
Add your screenshots here! Suggested shots:

1. HERO SHOT - Wide angle showing a player at a crafting station
2. PLACEMENT - Ghost preview during station placement
3. CRAFTING - ox_inventory crafting menu at a station
4. PROCESSING - Scale showing purity preservation
5. STASH - Player opening a placed stash
6. LOOTABLE - Searching animation with progress bar
7. WORLD BUILDER - Laser targeting in action
8. ADMIN MENU - Clean category view
9. ZONE DEBUG - World props auto-discovery visualization
-->

<div align="center">

| Feature | Screenshot |
|---------|------------|
| Station Placement | *[Add screenshot]* |
| Crafting Interface | *[Add screenshot]* |
| Processing System | *[Add screenshot]* |
| World Builder Laser | *[Add screenshot]* |
| Admin Menu | *[Add screenshot]* |

</div>

---

## 🤝 Support & Community

- **Issues**: Open a GitHub issue for bugs
- **Discord**: [Join our community](#) <!-- Add your Discord link -->
- **Documentation**: Full docs in the `/docs` folder

---

## 📜 Changelog

### v1.0.1 (Current)
- ✅ Complete admin menu reorganization
- ✅ Full World Props admin support (zones + locations)
- ✅ Cooldown management system
- ✅ Ground placement fixes for World Builder
- ✅ Menu structure cleanup (no version labels)

### v1.0.0
- 🏭 Station system with durability
- 📦 Stash system with access control
- 🎰 Lootable system with timers
- 🌍 World Props (zones + locations)
- 🏗️ World Builder with laser targeting
- ⚗️ Processing system with metadata preservation
- 🛡️ Comprehensive admin menu

---

## 📄 License

This resource is provided for use in FiveM servers. See LICENSE file for details.

---

## 💖 Credits

<div align="center">

| Role | Credit |
|------|--------|
| 🎯 **Concept & Vision** | The OG KiLLz |
| 💻 **Development Partner** | Claude (Anthropic) |
| 🔧 **Framework** | Overextended (ox_lib, ox_target, ox_inventory) |
| 🎮 **Core** | QBox Project (qbx_core) |

---

**Quality > Speed** 💪

*Built with passion by The OG KiLLz & Claude*

*Claude vs Claude vs The World!* 🌍🔥

</div>
