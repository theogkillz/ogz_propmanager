--[[
    OGz PropManager v3.0 - Sound Definitions (Compact Format)
    
    Referenced by modelStates.sound in stations.lua
    Uses xsound or native GTA sounds
    
    STRUCTURE:
    ['sound_key'] = { type = "xsound|native", sound = "file_or_name", volume = 0.0-1.0, loop = bool, range = float }
]]

Sounds = {
    -- ═══════════════════════════════════════════════════════════════════
    -- MACHINE SOUNDS (Loop while in state)
    -- ═══════════════════════════════════════════════════════════════════
    ['machine_hum']       = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Background_Loop", volume = 0.3, loop = true, range = 10.0 },
    ['machine_press']     = { type = "native", soundSet = "DLC_GR_MOC_Torque_Wrench_Sounds", sound = "Drill", volume = 0.5, loop = true, range = 15.0 },
    ['electric_hum']      = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Background_Loop", volume = 0.2, loop = true, range = 8.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- CHEMICAL SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['chemical_bubbling'] = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "DISTANT_BOAT_ENGINE", volume = 0.3, loop = true, range = 10.0 },
    ['mixing_powder']     = { type = "native", soundSet = "Auction_Sounds", sound = "YOURCARDSOUND", volume = 0.4, loop = false, range = 5.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- COOKING SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['gas_burner']        = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Background_Loop", volume = 0.2, loop = true, range = 5.0 },
    ['cooking_sizzle']    = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "DISTANT_BOAT_ENGINE", volume = 0.3, loop = true, range = 8.0 },
    ['fire_crackle']      = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Background_Loop", volume = 0.25, loop = true, range = 8.0 },
    ['grill_sizzle']      = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "DISTANT_BOAT_ENGINE", volume = 0.35, loop = true, range = 10.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- WORKSHOP SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['workbench_tools']   = { type = "native", soundSet = "DLC_GR_MOC_Torque_Wrench_Sounds", sound = "Drill", volume = 0.4, loop = true, range = 12.0 },
    ['metal_grinding']    = { type = "native", soundSet = "DLC_GR_MOC_Torque_Wrench_Sounds", sound = "Drill", volume = 0.5, loop = true, range = 15.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- MEDICAL SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['medical_beep']      = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Beep", volume = 0.3, loop = true, range = 5.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- EVENT SOUNDS (One-shots)
    -- ═══════════════════════════════════════════════════════════════════
    ['event_success']     = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "MEDAL_UP", volume = 0.5, loop = false, range = 5.0 },
    ['event_fail']        = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "MEDAL_DOWN", volume = 0.5, loop = false, range = 5.0 },
    ['event_bonus']       = { type = "native", soundSet = "HUD_AWARDS", sound = "CHALLENGE_UNLOCKED", volume = 0.6, loop = false, range = 5.0 },
    ['event_explosion']   = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "EXPLOSION_SMALL", volume = 0.7, loop = false, range = 20.0 },
    ['power_surge']       = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Hack_Failed", volume = 0.5, loop = false, range = 10.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 STASH SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['stash_open']        = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "SELECT", volume = 0.4, loop = false, range = 3.0 },
    ['stash_close']       = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "BACK", volume = 0.4, loop = false, range = 3.0 },
    ['safe_unlock']       = { type = "native", soundSet = "DLC_HEIST_FLEECA_SOUNDSET", sound = "Vault_Open", volume = 0.5, loop = false, range = 5.0 },
    ['safe_lock']         = { type = "native", soundSet = "DLC_HEIST_FLEECA_SOUNDSET", sound = "Door_Close", volume = 0.5, loop = false, range = 5.0 },
    ['locker_open']       = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "NAV_UP_DOWN", volume = 0.4, loop = false, range = 3.0 },
    ['bag_zip']           = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "SELECT", volume = 0.3, loop = false, range = 2.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 LOOTABLE SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['search_rummage']    = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "PROPERTY_PURCHASE", volume = 0.3, loop = false, range = 5.0 },
    ['dig_search']        = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "PROPERTY_PURCHASE", volume = 0.3, loop = false, range = 5.0 },
    ['crate_open']        = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "PICK_UP", volume = 0.5, loop = false, range = 8.0 },
    ['case_open']         = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "NAV_UP_DOWN", volume = 0.4, loop = false, range = 5.0 },
    ['cabinet_open']      = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "SELECT", volume = 0.3, loop = false, range = 4.0 },
    ['loot_found']        = { type = "native", soundSet = "HUD_AWARDS", sound = "RANK_UP", volume = 0.5, loop = false, range = 5.0 },
    ['loot_empty']        = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "ERROR", volume = 0.4, loop = false, range = 3.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 WORLD PROP SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['vending_dispense']  = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Click", volume = 0.5, loop = false, range = 5.0 },
    ['vending_select']    = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "SELECT", volume = 0.4, loop = false, range = 3.0 },
    ['register_ding']     = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "PICK_UP", volume = 0.4, loop = false, range = 5.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 FURNITURE SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['furniture_scrape']  = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "PROPERTY_PURCHASE", volume = 0.3, loop = false, range = 5.0 },
    ['chair_pull']        = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "PROPERTY_PURCHASE", volume = 0.25, loop = false, range = 4.0 },
    ['chair_push']        = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "PROPERTY_PURCHASE", volume = 0.25, loop = false, range = 4.0 },
    ['heavy_drag']        = { type = "native", soundSet = "DLC_GR_MOC_Torque_Wrench_Sounds", sound = "Drill", volume = 0.2, loop = false, range = 6.0 },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.1 PROCESSING/SCALE SOUNDS
    -- ═══════════════════════════════════════════════════════════════════
    ['scale_use']         = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Click", volume = 0.4, loop = false, range = 3.0 },
    ['scale_beep']        = { type = "native", soundSet = "DLC_HEIST_HACKING_SNAKE_SOUNDS", sound = "Beep", volume = 0.3, loop = false, range = 3.0 },
    ['packaging_start']   = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "SELECT", volume = 0.3, loop = false, range = 3.0 },
    ['packaging_complete']= { type = "native", soundSet = "HUD_AWARDS", sound = "RANK_UP", volume = 0.5, loop = false, range = 5.0 },
    ['bag_rustle']        = { type = "native", soundSet = "GTAO_Script_Sounds", sound = "PROPERTY_PURCHASE", volume = 0.25, loop = false, range = 3.0 },
    ['wrap_tear']         = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "NAV_UP_DOWN", volume = 0.3, loop = false, range = 3.0 },
    ['joint_roll']        = { type = "native", soundSet = "HUD_FRONTEND_DEFAULT_SOUNDSET", sound = "SELECT", volume = 0.2, loop = false, range = 2.0 },
}

return Sounds
