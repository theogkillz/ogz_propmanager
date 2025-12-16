--[[
    OGz PropManager v3.1 - ox_inventory Items
    
    Add these to: ox_inventory/data/items.lua
    
    CATEGORIES:
    - Stations (Crafting Props)
    - Stashes (Storage Props)
    - Processing (Drug Scales & Stations)
    - Containers (Packaging Materials)
    - Drug Products (Weed, Coke, Meth)
    - Repair Items
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- STATIONS (Crafting Props) - v2.0
-- ═══════════════════════════════════════════════════════════════════════════

['ogz_rosin_press'] = { label = 'Rosin Press', weight = 15000, stack = false, close = true, description = 'A portable rosin press for processing plant material.' },
['ogz_rosin_press_pro'] = { label = 'Rosin Press Pro', weight = 20000, stack = false, close = true, description = 'Professional grade rosin press with enhanced capabilities.' },
['ogz_meth_table'] = { label = 'Meth Lab Table', weight = 25000, stack = false, close = true, description = 'Portable chemistry table for... science experiments.' },
['ogz_coke_table'] = { label = 'Processing Table', weight = 20000, stack = false, close = true, description = 'A table designed for processing powdered substances.' },
['ogz_workbench'] = { label = 'Workbench', weight = 30000, stack = false, close = true, description = 'A sturdy workbench for crafting and repairs.' },
['ogz_weapon_bench'] = { label = 'Weapons Bench', weight = 35000, stack = false, close = true, description = 'Specialized bench for weapon maintenance and modifications.' },
['ogz_portable_stove'] = { label = 'Portable Stove', weight = 8000, stack = false, close = true, description = 'Compact cooking stove, perfect for outdoor cooking.' },
['ogz_portable_grill'] = { label = 'Portable Grill', weight = 12000, stack = false, close = true, description = 'Portable BBQ grill for grilling on the go.' },
['ogz_medical_station'] = { label = 'Medical Station', weight = 18000, stack = false, close = true, description = 'Portable medical workstation for preparing supplies.' },

-- ═══════════════════════════════════════════════════════════════════════════
-- STASHES (Storage Props) - v3.0
-- ═══════════════════════════════════════════════════════════════════════════

['ogz_portable_safe'] = { label = 'Portable Safe', weight = 20000, stack = false, close = true, description = 'A heavy-duty portable safe for secure storage.' },
['ogz_small_lockbox'] = { label = 'Small Lockbox', weight = 3000, stack = false, close = true, description = 'Compact lockbox for personal valuables.' },
['ogz_hidden_compartment'] = { label = 'Hidden Compartment', weight = 5000, stack = false, close = true, description = 'Disguised storage container, hard to detect.' },
['ogz_gang_locker'] = { label = 'Gang Locker', weight = 25000, stack = false, close = true, description = 'Large storage locker for gang supplies.' },
['ogz_crew_stash'] = { label = 'Crew Stash Box', weight = 15000, stack = false, close = true, description = 'Shared storage box for crew operations.' },
['ogz_job_supply_crate'] = { label = 'Job Supply Crate', weight = 18000, stack = false, close = true, description = 'Heavy-duty crate for job-related supplies.' },
['ogz_cooler_box'] = { label = 'Cooler Box', weight = 6000, stack = false, close = true, description = 'Insulated cooler for keeping items fresh.' },
['ogz_weapons_case'] = { label = 'Weapons Case', weight = 10000, stack = false, close = true, description = 'Reinforced case designed for weapon storage.' },
['ogz_duffle_bag'] = { label = 'Duffle Bag', weight = 2000, stack = false, close = true, description = 'Large duffle bag for storing various items.' },
['ogz_evidence_locker'] = { label = 'Evidence Locker', weight = 30000, stack = false, close = true, description = 'Secure locker for storing evidence. Police use only.' },

-- ═══════════════════════════════════════════════════════════════════════════
-- PROCESSING STATIONS (Drug Scales) - v3.1 NEW!
-- These are placeable station kits
-- ═══════════════════════════════════════════════════════════════════════════

['ogz_drug_scale'] = { label = 'Drug Scale Kit', weight = 5000, stack = false, close = true, description = 'Professional digital scale for precise measurements.' },
['ogz_bulk_scale'] = { label = 'Bulk Scale Kit', weight = 15000, stack = false, close = true, description = 'Industrial scale for large quantity measurements.' },
['ogz_rolling_table'] = { label = 'Rolling Table Kit', weight = 8000, stack = false, close = true, description = 'Clean surface setup for rolling joints and blunts.' },
['ogz_packaging_station'] = { label = 'Packaging Station Kit', weight = 12000, stack = false, close = true, description = 'Professional packaging setup for drug operations.' },

-- ═══════════════════════════════════════════════════════════════════════════
-- PROCESSING TOOLS - v3.1 NEW!
-- Required for using processing stations (NOT consumed)
-- ═══════════════════════════════════════════════════════════════════════════

['scales'] = { label = 'Digital Scales', weight = 500, stack = false, close = true, description = 'Professional digital scales. Required for drug processing (not consumed).' },
['ls_rolling_paper'] = { label = 'Rolling Paper', weight = 1, stack = true, close = true, description = 'Papers for rolling joints.' },

-- ═══════════════════════════════════════════════════════════════════════════
-- CONTAINERS (Packaging Materials) - v3.1 NEW!
-- Weight tiers: gram, quarter, ounce, pound, brick
-- ═══════════════════════════════════════════════════════════════════════════

['ls_empty_baggy'] = { label = 'Empty Baggy', weight = 1, stack = true, close = true, description = 'Small empty baggy for gram portions.' },
['ls_empty_pill_bottle'] = { label = 'Empty Pill Bottle', weight = 5, stack = true, close = true, description = 'Empty bottle for quarter ounce portions.' },
['ls_empty_lrg_baggy'] = { label = 'Large Empty Baggy', weight = 2, stack = true, close = true, description = 'Large baggy for ounce portions.' },
['ls_empty_xlrg_baggy'] = { label = 'XL Empty Baggy', weight = 5, stack = true, close = true, description = 'Extra large baggy for pound portions.' },
['ls_empty_special_wrap'] = { label = 'Special Wrap', weight = 10, stack = true, close = true, description = 'Special wrapping for brick/kilo packaging.' },

-- ═══════════════════════════════════════════════════════════════════════════
-- WEED PRODUCTS (Input & Output) - v3.1 NEW!
-- Integrates with Lation Scripts naming convention
-- All products support metadata: purity, quality, durability
-- ═══════════════════════════════════════════════════════════════════════════

-- COSMIC KUSH
['ls_cosmic_kush_bud'] = { label = 'Cosmic Kush Bud', weight = 28, stack = true, close = true, description = 'Harvested Cosmic Kush flower (1 oz).' },
['ls_cosmic_kush_baggy'] = { label = 'Cosmic Kush (1g)', weight = 2, stack = true, close = true, description = 'Gram bag of Cosmic Kush.' },
['ls_cosmic_kush_quarter'] = { label = 'Cosmic Kush (7g)', weight = 10, stack = true, close = true, description = 'Quarter ounce of Cosmic Kush.' },
['ls_cosmic_kush_joint'] = { label = 'Cosmic Kush Joint', weight = 2, stack = true, close = true, consume = 1, description = 'Pre-rolled Cosmic Kush joint.' },

-- PURPLE HAZE
['ls_purple_haze_bud'] = { label = 'Purple Haze Bud', weight = 28, stack = true, close = true, description = 'Harvested Purple Haze flower (1 oz).' },
['ls_purple_haze_baggy'] = { label = 'Purple Haze (1g)', weight = 2, stack = true, close = true, description = 'Gram bag of Purple Haze.' },
['ls_purple_haze_joint'] = { label = 'Purple Haze Joint', weight = 2, stack = true, close = true, consume = 1, description = 'Pre-rolled Purple Haze joint.' },

-- OG KUSH
['ls_og_kush_bud'] = { label = 'OG Kush Bud', weight = 28, stack = true, close = true, description = 'Harvested OG Kush flower (1 oz).' },
['ls_og_kush_baggy'] = { label = 'OG Kush (1g)', weight = 2, stack = true, close = true, description = 'Gram bag of OG Kush.' },
['ls_og_kush_joint'] = { label = 'OG Kush Joint', weight = 2, stack = true, close = true, consume = 1, description = 'Pre-rolled OG Kush joint.' },

-- ═══════════════════════════════════════════════════════════════════════════
-- COCAINE PRODUCTS (Input & Output) - v3.1 NEW!
-- All products support metadata: purity, quality, durability
-- ═══════════════════════════════════════════════════════════════════════════

['coke'] = { label = 'Cocaine (Uncut)', weight = 28, stack = true, close = true, description = 'Unprocessed cocaine powder (1 oz).' },
['cokebaggy'] = { label = 'Cocaine (1g)', weight = 2, stack = true, close = true, description = 'Gram bag of cocaine.' },
['coke_quarter'] = { label = 'Cocaine (7g)', weight = 10, stack = true, close = true, description = 'Quarter ounce of cocaine.' },
['coke_ounce'] = { label = 'Cocaine (1oz)', weight = 30, stack = true, close = true, description = 'Full ounce of cocaine.' },
['coke_brick'] = { label = 'Cocaine Brick', weight = 1000, stack = false, close = true, description = 'Brick of cocaine (1 kilo).' },

-- ═══════════════════════════════════════════════════════════════════════════
-- METH PRODUCTS (Input & Output) - v3.1 NEW!
-- All products support metadata: purity, quality, durability
-- ═══════════════════════════════════════════════════════════════════════════

['meth'] = { label = 'Methamphetamine (Uncut)', weight = 28, stack = true, close = true, description = 'Unprocessed methamphetamine (1 oz).' },
['methbaggy'] = { label = 'Meth (1g)', weight = 2, stack = true, close = true, description = 'Gram bag of meth.' },
['meth_quarter'] = { label = 'Meth (7g)', weight = 10, stack = true, close = true, description = 'Quarter ounce of meth.' },
['meth_ounce'] = { label = 'Meth (1oz)', weight = 30, stack = true, close = true, description = 'Full ounce of meth.' },

-- ═══════════════════════════════════════════════════════════════════════════
-- REPAIR ITEMS
-- ═══════════════════════════════════════════════════════════════════════════

['ogz_repair_kit'] = { label = 'Station Repair Kit', weight = 1000, stack = true, close = true, description = 'Tools and parts for repairing crafting stations.' },
