--[[
    OGz PropManager v3.4 - Furniture Movement Definitions
    
    ═══════════════════════════════════════════════════════════════════════════
    REVOLUTIONARY FIVEM FEATURE: Move chairs, stools, and furniture!
    ═══════════════════════════════════════════════════════════════════════════
    
    Many GTA interiors have chairs clipped into tables, making sit scripts
    unusable. This system allows players to PULL OUT chairs, sit, then
    PUSH THEM BACK when done!
    
    v3.0: Initial furniture movement system
    v3.4: Pull/Push increment system (multiple pulls for more distance)
          Drag mode support (shopping cart style)
          Sit type mapping for emote system
    
    PERSISTENCE: Resets on server restart (respects original mapping coords)
    
    STRUCTURE:
    Furniture.Categories['category_id'] = {
        label       = "Display Name",
        models      = { "prop_1", "prop_2", ... },
        sitType     = "chair",              -- Maps to SitEmotes category
        canDrag     = true,                 -- Can be picked up and moved?
        
        movement = {
            pullDistance    = 0.3,          -- Distance PER PULL (meters)
            maxPullDistance = 1.2,          -- Maximum total pull distance
            pushDistance    = 0.3,          -- Distance PER PUSH back
            canRotate       = true,
            rotateStep      = 15.0,
        },
        
        icon        = "fas fa-chair",
        iconColor   = "#8B4513",
    }
]]

Furniture = {
    -- ═══════════════════════════════════════════════════════════════════════
    -- GLOBAL SETTINGS
    -- ═══════════════════════════════════════════════════════════════════════
    
    Enabled = true,
    
    -- Detection range for targeting furniture
    TargetDistance = 2.0,
    
    -- Movement defaults (can be overridden per-category)
    Defaults = {
        -- v3.4: Increment-based pull/push
        pullDistance = 0.3,                 -- Distance per pull action
        maxPullDistance = 1.2,              -- Maximum total pull distance
        pushDistance = 0.3,                 -- Distance per push action
        
        canRotate = true,
        rotateStep = 15.0,                  -- Degrees per rotation
        
        -- v3.4: Drag mode defaults
        canDrag = true,                     -- Can be picked up and carried?
        maxDragRadius = 5.0,                -- Max distance from original position
    },
    
    -- v3.4: Dragging Configuration
    Dragging = {
        enabled = true,
        maxRadius = 5.0,                    -- Max meters from original position
        
        animation = {
            dict = "missfinale_c2ig_11",
            anim = "pushcar_offcliff_m",    -- Shopping cart push style
        },
        
        -- Movement while dragging
        moveSpeedMultiplier = 0.8,          -- Slower movement while dragging
        
        -- Controls (key codes)
        keys = {
            drop = 38,                      -- E to drop/place
            cancel = 202,                   -- Backspace to cancel
            rotateLeft = 174,               -- Left arrow
            rotateRight = 175,              -- Right arrow
        },
    },
    
    -- Animation while moving furniture (push/pull)
    MoveAnim = {
        dict = "anim@heists@box_carry@",
        anim = "idle",
        duration = 1000,                    -- Milliseconds (reduced for snappier feel)
    },
    
    -- Sounds
    Sounds = {
        pull = "furniture_scrape",
        push = "furniture_scrape",
        rotate = nil,
        drag_start = nil,
        drag_drop = nil,
    },
    
    -- Labels for target options
    Labels = {
        pull = "Pull Out",
        pullMore = "Pull More",             -- v3.4: When already pulled
        push = "Push Back",
        pushReset = "Reset Position",       -- v3.4: Push all the way back
        rotateLeft = "Rotate Left",
        rotateRight = "Rotate Right",
        drag = "Pick Up & Move",            -- v3.4: Drag mode
        sit = "Sit Down",                   -- v3.4: Sit system
        reset = "Reset Position",           -- Admin only
    },
    
    -- Icons for target options
    Icons = {
        pull = "fas fa-arrow-left",
        pullMore = "fas fa-angles-left",
        push = "fas fa-arrow-right",
        pushReset = "fas fa-undo",
        rotateLeft = "fas fa-rotate-left",
        rotateRight = "fas fa-rotate-right",
        drag = "fas fa-hand-holding",
        sit = "fas fa-chair",
        reset = "fas fa-undo",
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- MODEL OVERRIDES (Force specific models to specific sitTypes)
    -- ═══════════════════════════════════════════════════════════════════════
    
    ModelOverrides = {
        -- Example: ["modded_throne_prop"] = "chair",
        -- Example: ["weird_couch_model"] = "bed",
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- FURNITURE CATEGORIES
    -- ═══════════════════════════════════════════════════════════════════════
    
    Categories = {
        -- ═══════════════════════════════════════════════════════════════════
        -- STANDARD CHAIRS
        -- ═══════════════════════════════════════════════════════════════════
        
        ['chairs'] = {
            label = "Chairs",
            sitType = "chair",              -- v3.4: Maps to SitEmotes.chair
            canDrag = true,                 -- v3.4: Can be dragged
            
            models = {
                -- Basic chairs
                "prop_chair_01a",
                "prop_chair_01b",
                "prop_chair_02",
                "prop_chair_03",
                "prop_chair_04a",
                "prop_chair_04b",
                "prop_chair_05",
                "prop_chair_06",
                "prop_chair_07",
                "prop_chair_08",
                "prop_chair_09",
                "prop_chair_10",
                
                -- Wooden chairs
                "prop_table_04_chr",
                "prop_table_05_chr",
                "prop_table_06_chr",
                "bkr_prop_weed_chair_01a",
                
                -- Misc chairs
                "prop_sol_chair",
                "prop_skid_chair_01",
                "prop_skid_chair_02",
                "prop_skid_chair_03",
                "prop_yacht_chair_01",
                "prop_yaught_chair_01",
                
                -- Director/folding chairs
                "prop_dir_chair_01",
                "prop_direct_chair_02",
                
                -- Plastic chairs
                "prop_chair_pile_01",
                "prop_chair_plastic_02",
            },
            
            movement = {
                pullDistance = 0.3,         -- Per pull increment
                maxPullDistance = 1.0,      -- Max total
                pushDistance = 0.3,         -- Per push increment
                canRotate = true,
                rotateStep = 15.0,
            },
            
            icon = "fas fa-chair",
            iconColor = "#8B4513",
        },
        
        -- ═══════════════════════════════════════════════════════════════════
        -- OFFICE CHAIRS
        -- ═══════════════════════════════════════════════════════════════════
        
        ['office_chairs'] = {
            label = "Office Chairs",
            sitType = "chair",
            canDrag = true,
            
            models = {
                "prop_off_chair_01",
                "prop_off_chair_03",
                "prop_off_chair_04",
                "prop_off_chair_04b",
                "prop_off_chair_04_s",
                "prop_off_chair_05",
                "prop_wheelchair_01",
                "prop_wheelchair_01_s",
                "v_corp_offchair",
                "v_club_officechair",
                "v_ilev_chair02_ped",
                "v_ret_gc_chair01",
                "v_ret_gc_chair02",
                "v_ret_gc_chair03",
                "hei_heist_stn_chairarm",
                "hei_heist_stn_chairarm_01",
            },
            
            movement = {
                pullDistance = 0.35,        -- Office chairs roll easier
                maxPullDistance = 1.4,      -- Can pull further
                pushDistance = 0.35,
                canRotate = true,
                rotateStep = 15.0,
            },
            
            icon = "fas fa-chair-office",
            iconColor = "#1a1a1a",
        },
        
        -- ═══════════════════════════════════════════════════════════════════
        -- BAR STOOLS
        -- ═══════════════════════════════════════════════════════════════════
        
        ['bar_stools'] = {
            label = "Bar Stools",
            sitType = "stool",              -- v3.4: Maps to SitEmotes.stool
            canDrag = true,
            
            models = {
                "prop_bar_stool_01",
                "prop_bar_stool_02",
                "v_club_stool",
                "v_ilev_fos_stool",
                "prop_wait_stool_01",
            },
            
            movement = {
                pullDistance = 0.25,        -- Stools are smaller
                maxPullDistance = 0.8,
                pushDistance = 0.25,
                canRotate = true,
                rotateStep = 30.0,          -- Bigger rotation steps for round stools
            },
            
            icon = "fas fa-chair",
            iconColor = "#666666",
        },
        
        -- ═══════════════════════════════════════════════════════════════════
        -- ARMCHAIRS & COUCHES (Heavier, less movement)
        -- ═══════════════════════════════════════════════════════════════════
        
        ['armchairs'] = {
            label = "Armchairs & Couches",
            sitType = "couch",              -- v3.4: Maps to SitEmotes.couch
            canDrag = false,                -- Too heavy to drag
            
            models = {
                "prop_armchair_01",
                "prop_rocking_chair_01",
                "prop_rocking_chair_02",
                "prop_couch_01",
                "prop_couch_02",
                "prop_couch_03",
                "prop_couch_04",
                "v_ilev_m_sofa",
                "v_res_msonsofa",
                "miss_rub_couch_01",
            },
            
            movement = {
                pullDistance = 0.2,         -- Heavy, moves less per action
                maxPullDistance = 0.5,      -- Can't pull very far
                pushDistance = 0.2,
                canRotate = false,          -- Too heavy to rotate easily
                rotateStep = 0,
            },
            
            icon = "fas fa-couch",
            iconColor = "#654321",
        },
        
        -- ═══════════════════════════════════════════════════════════════════
        -- BENCHES
        -- ═══════════════════════════════════════════════════════════════════
        
        ['benches'] = {
            label = "Benches",
            sitType = "bench",              -- v3.4: Maps to SitEmotes.bench
            canDrag = false,                -- Can't drag benches
            
            models = {
                "prop_bench_01a",
                "prop_bench_01b",
                "prop_bench_01c",
                "prop_bench_02",
                "prop_bench_03",
                "prop_bench_04",
                "prop_bench_05",
                "prop_bench_06",
                "prop_bench_07",
                "prop_bench_08",
                "prop_bench_09",
                "prop_bench_10",
                "prop_bench_11",
                "prop_fib_intbench_01",
                "prop_wait_bench_01",
            },
            
            movement = {
                pullDistance = 0.25,
                maxPullDistance = 0.6,
                pushDistance = 0.25,
                canRotate = false,          -- Benches don't rotate
                rotateStep = 0,
            },
            
            icon = "fas fa-bench-tree",
            iconColor = "#556b2f",
        },
        
        -- ═══════════════════════════════════════════════════════════════════
        -- CASINO / RESTAURANT CHAIRS
        -- ═══════════════════════════════════════════════════════════════════
        
        ['casino_chairs'] = {
            label = "Casino Chairs",
            sitType = "chair",
            canDrag = true,
            
            models = {
                "vw_prop_casino_chair_01a",
                "vw_prop_casino_chair_01b",
                "vw_prop_casino_chair_01c",
                "h4_prop_casino_chair_01",
                "h4_prop_h4_old_chair_01a",
            },
            
            movement = {
                pullDistance = 0.3,
                maxPullDistance = 1.0,
                pushDistance = 0.3,
                canRotate = true,
                rotateStep = 15.0,
            },
            
            icon = "fas fa-chair",
            iconColor = "#c41e3a",
        },
        
        -- ═══════════════════════════════════════════════════════════════════
        -- BEDS (v3.4 - For sit/lay system)
        -- ═══════════════════════════════════════════════════════════════════
        
        ['beds'] = {
            label = "Beds",
            sitType = "bed",                -- v3.4: Maps to SitEmotes.bed
            canDrag = false,                -- Can't drag beds
            
            models = {
                -- Standard beds
                "prop_bed_01",
                "prop_bed_02",
                "p_lestersbed_s",
                "p_mbbed_s",
                "p_v_res_mbbed_s",
                "v_res_msonbed",
                "v_res_d_bed",
                "v_res_tre_bed1",
                "v_res_tre_bed2",
                
                -- Apartment beds
                "apa_mp_h_bed_double_08",
                "apa_mp_h_bed_double_09",
                "apa_mp_h_bed_wide_05",
                "apa_mp_h_yacht_bed_02",
                "ex_mp_h_bed_double_08",
                "ex_mp_h_bed_wide_06",
                "hei_heist_bed_double_08",
                
                -- Hospital beds
                "v_med_bed1",
                "v_med_bed2",
                
                -- Mattresses
                "prop_matress_01",
                "prop_mattress_02",
                "prop_mattress_03",
            },
            
            movement = {
                pullDistance = 0,           -- Can't move beds
                maxPullDistance = 0,
                pushDistance = 0,
                canRotate = false,
                rotateStep = 0,
            },
            
            icon = "fas fa-bed",
            iconColor = "#4a90d9",
        },
        
        --[[
        ═══════════════════════════════════════════════════════════════════════
        ADD YOUR OWN CATEGORIES
        ═══════════════════════════════════════════════════════════════════════
        
        ['my_custom_chairs'] = {
            label = "My Custom Chairs",
            sitType = "chair",              -- chair, stool, bench, couch, bed
            canDrag = true,
            
            models = {
                "prop_custom_chair_01",
                "prop_custom_chair_02",
            },
            
            movement = {
                pullDistance = 0.3,
                maxPullDistance = 1.0,
                pushDistance = 0.3,
                canRotate = true,
                rotateStep = 15.0,
            },
            
            icon = "fas fa-chair",
            iconColor = "#ff6600",
        },
        ]]
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- HELPER: Get all models as flat list (used by client)
    -- ═══════════════════════════════════════════════════════════════════════
    
    GetAllModels = function(self)
        local models = {}
        for _, category in pairs(self.Categories) do
            for _, model in ipairs(category.models) do
                models[model] = category
            end
        end
        return models
    end,
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- HELPER: Get category for model
    -- ═══════════════════════════════════════════════════════════════════════
    
    GetCategory = function(self, model)
        for catId, category in pairs(self.Categories) do
            for _, m in ipairs(category.models) do
                if m == model then
                    return catId, category
                end
            end
        end
        return nil, nil
    end,
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- HELPER: Check if model is a bed (for auto-detection)
    -- ═══════════════════════════════════════════════════════════════════════
    
    IsBedModel = function(self, modelName)
        if type(modelName) ~= "string" then return false end
        
        local lowerName = string.lower(modelName)
        local bedPatterns = { "bed", "mattress", "matress", "bunk", "cot" }
        
        for _, pattern in ipairs(bedPatterns) do
            if string.find(lowerName, pattern) then
                return true
            end
        end
        return false
    end,
}

return Furniture
