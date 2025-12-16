--[[
    OGz PropManager v3.0 - Animation Configurations (Compact Format)
    
    STRUCTURE:
    ['AnimKey'] = { Dict, Clip, Flag, Time, Prop, Bone, Coord, Rot, Prog, Move }
]]

Animations = {
    -- ═══════════════════════════════════════════════════════════════════
    -- v2.0 PLACEMENT / REMOVAL
    -- ═══════════════════════════════════════════════════════════════════
    ['Place']      = { Dict = "mp_arresting", Clip = "a_uncuff", Flag = 49, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Setting up station...", Move = true },
    ['Remove']     = { Dict = "timetable@floyd@clean_kitchen@base", Clip = "base", Flag = 8, Time = 3000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Packing up station...", Move = true },
    ['Seize']      = { Dict = "mp_arresting", Clip = "a_uncuff", Flag = 49, Time = 4000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Seizing station...", Move = true },
    ['Repair']     = { Dict = "mini@repair", Clip = "fixing_a_ped", Flag = 1, Time = 8000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Repairing station...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v2.0 DRUG PROCESSING
    -- ═══════════════════════════════════════════════════════════════════
    ['Drugs']      = { Dict = "mini@repair", Clip = "fixing_a_ped", Flag = 1, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Processing...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v2.0 GENERAL CRAFTING
    -- ═══════════════════════════════════════════════════════════════════
    ['Crafting']   = { Dict = "mini@repair", Clip = "fixing_a_ped", Flag = 1, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Crafting...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v2.0 COOKING
    -- ═══════════════════════════════════════════════════════════════════
    ['Cooking']    = { Dict = "amb@prop_human_bbq@male@idle_a", Clip = "idle_b", Flag = 49, Time = 5000, Prop = "prop_fish_slice_01", Bone = 28422, Coord = vec3(0, 0, 0), Rot = vec3(0, 0, 0), Prog = "Cooking...", Move = true },
    ['Grill']      = { Dict = "amb@prop_human_bbq@male@idle_a", Clip = "idle_b", Flag = 49, Time = 5000, Prop = "prop_fish_slice_01", Bone = 28422, Coord = vec3(0, 0, 0), Rot = vec3(0, 0, 0), Prog = "Grilling...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v2.0 MEDICAL
    -- ═══════════════════════════════════════════════════════════════════
    ['Medical']    = { Dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@", Clip = "weed_inspecting_med_base_inspector", Flag = 49, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Preparing medicine...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v2.0 MIXING / BREWING
    -- ═══════════════════════════════════════════════════════════════════
    ['Mixing']     = { Dict = "amb@prop_human_bbq@male@idle_a", Clip = "idle_b", Flag = 49, Time = 5000, Prop = "prop_fish_slice_01", Bone = 28422, Coord = vec3(0, 0, 0), Rot = vec3(0, 0, 0), Prog = "Mixing...", Move = true },
    ['Brewing']    = { Dict = "mini@strip_club@drink@one", Clip = "one_bartender", Flag = 49, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Brewing...", Move = true },
    ['Distilling'] = { Dict = "random@shop_tattoo", Clip = "_idle_a", Flag = 49, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Distilling...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 STASH ANIMATIONS
    -- ═══════════════════════════════════════════════════════════════════
    ['Placement']      = { Dict = "mp_arresting", Clip = "a_uncuff", Flag = 49, Time = 3000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Placing...", Move = true },
    ['StashOpen']      = { Dict = "anim@heists@ornate_bank@grab_cash", Clip = "grab", Flag = 49, Time = 2000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Opening...", Move = true },
    ['StashClose']     = { Dict = "anim@heists@ornate_bank@grab_cash", Clip = "grab", Flag = 49, Time = 1500, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Closing...", Move = true },
    ['SafeCrack']      = { Dict = "mini@safe_cracking", Clip = "idle_base", Flag = 49, Time = 15000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Cracking safe...", Move = false },
    ['UnlockStash']    = { Dict = "anim@heists@keycard@", Clip = "exit", Flag = 49, Time = 2000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Unlocking...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 LOOTABLE ANIMATIONS
    -- ═══════════════════════════════════════════════════════════════════
    ['SearchTrash']    = { Dict = "amb@prop_human_bum_bin@idle_a", Clip = "idle_a", Flag = 49, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Searching...", Move = false },
    ['SearchDumpster'] = { Dict = "amb@prop_human_bum_bin@idle_a", Clip = "idle_a", Flag = 49, Time = 6000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Digging through...", Move = false },
    ['SearchCrate']    = { Dict = "anim@gangops@facility@servers@bodysearch@", Clip = "player_search", Flag = 49, Time = 4000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Opening crate...", Move = false },
    ['SearchGround']   = { Dict = "amb@world_human_gardener_plant@male@base", Clip = "base", Flag = 49, Time = 5000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Searching ground...", Move = false },
    ['SearchHidden']   = { Dict = "missheist_jewel", Clip = "biker_p", Flag = 49, Time = 6000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Revealing hidden stash...", Move = false },
    ['OpenCase']       = { Dict = "mp_arresting", Clip = "a_uncuff", Flag = 49, Time = 4000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Opening case...", Move = true },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 WORLD PROP ANIMATIONS
    -- ═══════════════════════════════════════════════════════════════════
    ['VendingUse']     = { Dict = "mini@sprunk", Clip = "plyr_buy_drink_pt1", Flag = 49, Time = 2000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Selecting...", Move = true },
    ['VendingGrab']    = { Dict = "mini@sprunk", Clip = "plyr_buy_drink_pt2", Flag = 49, Time = 1500, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Grabbing...", Move = true },
    ['ATMUse']         = { Dict = "amb@prop_human_atm@male@idle_a", Clip = "idle_a", Flag = 49, Time = 3000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Using ATM...", Move = false },
    
    -- ═══════════════════════════════════════════════════════════════════
    -- v3.0 FURNITURE ANIMATIONS
    -- ═══════════════════════════════════════════════════════════════════
    ['FurniturePull']  = { Dict = "anim@heists@box_carry@", Clip = "idle", Flag = 49, Time = 1200, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = nil, Move = true },
    ['FurniturePush']  = { Dict = "anim@heists@box_carry@", Clip = "idle", Flag = 49, Time = 1200, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = nil, Move = true },
    ['FurnitureRotate']= { Dict = "anim@heists@box_carry@", Clip = "idle", Flag = 49, Time = 800, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = nil, Move = true },
    ['HeavyPull']      = { Dict = "missfinale_c2ig_11", Clip = "pushcar_offcliff_m", Flag = 49, Time = 2000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Moving...", Move = true },
    ['HeavyPush']      = { Dict = "missfinale_c2ig_11", Clip = "pushcar_offcliff_m", Flag = 49, Time = 2000, Prop = nil, Bone = nil, Coord = nil, Rot = nil, Prog = "Moving...", Move = true },
}

return Animations
