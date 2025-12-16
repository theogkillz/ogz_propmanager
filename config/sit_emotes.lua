--[[
    OGz PropManager v3.4 - Sit/Lay Emote Definitions
    
    ═══════════════════════════════════════════════════════════════════════════
    EMOTE FREEDOM: Players choose their own sitting/laying poses!
    ═══════════════════════════════════════════════════════════════════════════
    
    Phase F3: Core sit/lay system with categorized emotes
    
    STRUCTURE:
    SitEmotes['type'] = {
        label = "Display Name",
        icon = "fas fa-icon",
        emotes = {
            {
                label = "Emote Name",
                dict = "animation_dictionary",
                anim = "animation_name",
                offset = vec3(x, y, z),      -- Position offset from furniture
                heading = 180.0,              -- Heading offset (180 = facing away from prop forward)
                flags = 1,                    -- Animation flags (1 = loop)
                exitAnim = "anim_name",       -- Optional exit animation
            },
        },
    }
    
    FLAGS REFERENCE:
    1  = Loop
    49 = Loop + Upper body only
    0  = Play once
]]

SitEmotes = {
    -- ═══════════════════════════════════════════════════════════════════════
    -- CHAIR EMOTES
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['chair'] = {
        label = "Chair",
        icon = "fas fa-chair",
        emotes = {
            {
                label = "Sit Normal",
                dict = "timetable@ron@ig_5_p3",
                anim = "ig_5_p3_base",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Relaxed",
                dict = "timetable@reunited@ig_10",
                anim = "base_amanda",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Leaning",
                dict = "timetable@ron@ig_3_couch",
                anim = "base",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Thinking",
                dict = "misscarstealfinale",
                anim = "packer_intostillalidle",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Impatient",
                dict = "amb@world_human_stupor@male@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Confident",
                dict = "anim@heists@heist_corona@single_team",
                anim = "single_team_loop_boss",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Crossed Legs",
                dict = "anim@heists@prison_heistig1_p1_guard_station",
                anim = "yourshot_02_idle_a",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Sad",
                dict = "anim@amb@office@boardroom@crew@female@var_b@base@",
                anim = "base",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BAR STOOL EMOTES
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['stool'] = {
        label = "Bar Stool",
        icon = "fas fa-martini-glass",
        emotes = {
            {
                label = "Sit Normal",
                dict = "timetable@ron@ig_5_p3",
                anim = "ig_5_p3_base",
                offset = vec3(0.0, 0.0, 0.7),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Relaxed",
                dict = "timetable@reunited@ig_10",
                anim = "base_amanda",
                offset = vec3(0.0, 0.0, 0.7),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Lean on Bar",
                dict = "anim@amb@casino@hangout@ped_male@stand@02b@idles",
                anim = "idle_a",
                offset = vec3(0.0, 0.0, 0.7),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Thinking",
                dict = "misscarstealfinale",
                anim = "packer_intostillalidle",
                offset = vec3(0.0, 0.0, 0.7),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Tired",
                dict = "amb@world_human_stupor@male@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, 0.0, 0.7),
                heading = 180.0,
                flags = 1,
            },
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BENCH EMOTES
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['bench'] = {
        label = "Bench",
        icon = "fas fa-bench-tree",
        emotes = {
            {
                label = "Sit Normal",
                dict = "timetable@ron@ig_5_p3",
                anim = "ig_5_p3_base",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Relaxed",
                dict = "timetable@reunited@ig_10",
                anim = "base_amanda",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Slouched",
                dict = "switch@trevor@annoys_sunbathers",
                anim = "trev_annoys_sunbathers_loop_girl",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Spread Out",
                dict = "anim@heists@fleeca_bank@ig_7_jetski_owner",
                anim = "owner_idle",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Elbows on Knees",
                dict = "amb@world_human_stupor@male@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Waiting",
                dict = "misscarstealfinale",
                anim = "packer_intostillalidle",
                offset = vec3(0.0, 0.0, 0.5),
                heading = 180.0,
                flags = 1,
            },
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- COUCH/SOFA EMOTES
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['couch'] = {
        label = "Couch",
        icon = "fas fa-couch",
        emotes = {
            {
                label = "Sit Normal",
                dict = "timetable@reunited@ig_10",
                anim = "base_amanda",
                offset = vec3(0.0, 0.0, 0.3),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Relaxed",
                dict = "timetable@ron@ig_3_couch",
                anim = "base",
                offset = vec3(0.0, 0.0, 0.3),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Deep",
                dict = "anim@heists@heist_corona@single_team",
                anim = "single_team_loop_boss",
                offset = vec3(0.0, 0.0, 0.3),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Crossed Legs",
                dict = "anim@heists@prison_heistig1_p1_guard_station",
                anim = "yourshot_02_idle_a",
                offset = vec3(0.0, 0.0, 0.3),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Lay Down",
                dict = "switch@trevor@annoys_sunbathers",
                anim = "trev_annoys_sunbathers_loop_guy",
                offset = vec3(0.0, 0.0, 0.3),
                heading = 90.0,
                flags = 1,
            },
            {
                label = "Sit Slouched",
                dict = "amb@world_human_stupor@male@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, 0.0, 0.3),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit Impatient",
                dict = "timetable@ron@ig_5_p3",
                anim = "ig_5_p3_base",
                offset = vec3(0.0, 0.0, 0.3),
                heading = 180.0,
                flags = 1,
            },
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- BED EMOTES (Lay Down)
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['bed'] = {
        label = "Bed",
        icon = "fas fa-bed",
        emotes = {
            {
                label = "Lay on Back",
                dict = "anim@gangops@morgue@table@",
                anim = "body_search",
                offset = vec3(0.0, 0.0, 0.4),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Lay on Side (Left)",
                dict = "anim@mp_bedmid@left_var_06",
                anim = "f_sleep_l_loop_v06",
                offset = vec3(0.0, 0.0, 0.4),
                heading = 270.0,
                flags = 1,
            },
            {
                label = "Lay on Side (Right)",
                dict = "anim@mp_bedmid@right_var_02",
                anim = "f_sleep_r_loop_v02",
                offset = vec3(0.0, 0.0, 0.4),
                heading = 90.0,
                flags = 1,
            },
            {
                label = "Lay Face Down",
                dict = "mp_sleep",
                anim = "bind_pose_180",
                offset = vec3(0.0, 0.0, 0.4),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit on Edge",
                dict = "timetable@reunited@ig_10",
                anim = "base_amanda",
                offset = vec3(0.0, -0.5, 0.55),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Sit on Edge (Thinking)",
                dict = "amb@world_human_stupor@male@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, -0.5, 0.55),
                heading = 180.0,
                flags = 1,
            },
            {
                label = "Lay Relaxed",
                dict = "switch@trevor@annoys_sunbathers",
                anim = "trev_annoys_sunbathers_loop_guy",
                offset = vec3(0.0, 0.0, 0.4),
                heading = 90.0,
                flags = 1,
            },
            {
                label = "Passed Out",
                dict = "misslamar1dead_body",
                anim = "yourshot_02_idle_a",
                offset = vec3(0.0, 0.0, 0.4),
                heading = 0.0,
                flags = 1,
            },
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- FLOOR EMOTES (For sit anywhere - Phase F6)
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['floor'] = {
        label = "Floor",
        icon = "fas fa-person-arrow-down-to-line",
        emotes = {
            {
                label = "Sit Cross-Legged",
                dict = "anim@amb@business@bgen@bgen_no_work@",
                anim = "sit_phone_phoneputaway_idle_nowork",
                offset = vec3(0.0, 0.0, -0.5),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Sit Casual",
                dict = "switch@trevor@annoys_sunbathers",
                anim = "trev_annoys_sunbathers_loop_girl",
                offset = vec3(0.0, 0.0, -0.5),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Sit Knees Up",
                dict = "anim@gangops@morgue@table@",
                anim = "ko_front",
                offset = vec3(0.0, 0.0, -0.5),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Sit Leaning Back",
                dict = "amb@world_human_sunbathe@male@back@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, 0.0, -0.5),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Lay Down",
                dict = "amb@world_human_sunbathe@male@back@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, 0.0, -0.5),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Meditate",
                dict = "rcmcollect_paperleadinout@",
                anim = "meditiate_idle",
                offset = vec3(0.0, 0.0, -0.5),
                heading = 0.0,
                flags = 1,
            },
        },
    },
    
    -- ═══════════════════════════════════════════════════════════════════════
    -- WALL LEAN EMOTES (For sit anywhere - Phase F6)
    -- ═══════════════════════════════════════════════════════════════════════
    
    ['wall'] = {
        label = "Wall",
        icon = "fas fa-person-shelter",
        emotes = {
            {
                label = "Lean Back",
                dict = "amb@world_human_leaning@male@wall@back@foot_up@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, -0.1, 0.0),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Lean Shoulder",
                dict = "amb@world_human_leaning@male@wall@back@hands_together@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, -0.1, 0.0),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Lean Arms Crossed",
                dict = "amb@world_human_leaning@male@wall@back@arms_crossed@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, -0.1, 0.0),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Lean Cool",
                dict = "amb@world_human_smoking@male@male_a@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, -0.1, 0.0),
                heading = 0.0,
                flags = 1,
            },
            {
                label = "Lean Texting",
                dict = "amb@world_human_stand_mobile@male@text@idle_a",
                anim = "idle_a",
                offset = vec3(0.0, -0.1, 0.0),
                heading = 0.0,
                flags = 1,
            },
        },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

SitEmotes.Settings = {
    -- Stand up key
    standKey = 38,                          -- E key
    
    -- Allow movement input while seated (for looking around)
    allowCameraMovement = true,
    
    -- Automatically face furniture before sitting
    faceEntityFirst = true,
    faceEntityDuration = 500,               -- ms
    
    -- Default offset if not specified in emote
    defaultOffset = vec3(0.0, 0.0, 0.5),
    
    -- Transition animation when sitting down
    useSitDownTransition = false,           -- Set true to add sit-down animation
    sitDownDict = "amb@prop_human_seat_chair@male@generic@enter",
    sitDownAnim = "enter",
    sitDownDuration = 1000,
}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

---Get emote category by sitType
---@param sitType string
---@return table|nil
function SitEmotes.GetCategory(sitType)
    return SitEmotes[sitType]
end

---Get all emotes for a sitType
---@param sitType string
---@return table
function SitEmotes.GetEmotes(sitType)
    local category = SitEmotes[sitType]
    if category and category.emotes then
        return category.emotes
    end
    return {}
end

---Get specific emote by sitType and index
---@param sitType string
---@param index number
---@return table|nil
function SitEmotes.GetEmote(sitType, index)
    local emotes = SitEmotes.GetEmotes(sitType)
    return emotes[index]
end

return SitEmotes
