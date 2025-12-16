--[[
    OGz PropManager - Random Events Configuration (Compact Format)
    
    Events can trigger during crafting based on chance
    
    STRUCTURE:
    ['event_id'] = {
        chance = 0.0-1.0,           -- Probability (0.05 = 5%)
        label = "Display Name",
        description = "What happens",
        type = "positive|negative|neutral",
        effects = {
            durabilityChange = number,  -- Add/subtract durability
            outputMultiplier = number,  -- Multiply output (2.0 = double)
            timeMultiplier = number,    -- Multiply craft time
            failCraft = bool,           -- Cancel the craft
            loseInputs = bool,          -- Lose input materials
            explosion = bool,           -- Cause explosion
            alertPolice = bool,         -- Send police alert
        },
        sound = "sound_key",
        particle = { dict, name, duration },
        notification = { title, message, type },
    }
]]

Events = {
    -- ═══════════════════════════════════════════════════════════════════
    -- POSITIVE EVENTS (Good things happen!)
    -- ═══════════════════════════════════════════════════════════════════
    ['perfect_batch'] = {
        chance = 0.03,  -- 3%
        label = "Perfect Batch",
        description = "Everything aligned perfectly - double output!",
        type = "positive",
        effects = { durabilityChange = 0, outputMultiplier = 2.0, timeMultiplier = 1.0, failCraft = false, loseInputs = false },
        sound = "event_bonus",
        particle = { dict = "scr_rcbarry2", name = "scr_exp_clown_stink", duration = 3000 },
        notification = { title = "🌟 Perfect Batch!", message = "You produced double the output!", type = "success" },
    },
    
    ['efficient_run'] = {
        chance = 0.05,  -- 5%
        label = "Efficient Run",
        description = "Machine ran extra smooth - no durability lost",
        type = "positive",
        effects = { durabilityChange = 5, outputMultiplier = 1.0, timeMultiplier = 0.8, failCraft = false, loseInputs = false },
        sound = "event_success",
        particle = nil,
        notification = { title = "⚡ Efficient Run", message = "Station durability restored slightly!", type = "success" },
    },
    
    ['bonus_yield'] = {
        chance = 0.08,  -- 8%
        label = "Bonus Yield",
        description = "Got a little extra from the batch",
        type = "positive",
        effects = { durabilityChange = 0, outputMultiplier = 1.5, timeMultiplier = 1.0, failCraft = false, loseInputs = false },
        sound = "event_success",
        particle = nil,
        notification = { title = "📦 Bonus Yield", message = "You got 50% extra output!", type = "success" },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- NEGATIVE EVENTS (Bad things happen!)
    -- ═══════════════════════════════════════════════════════════════════
    ['power_surge'] = {
        chance = 0.04,  -- 4%
        label = "Power Surge",
        description = "Electrical surge damaged the equipment",
        type = "negative",
        effects = { durabilityChange = -15, outputMultiplier = 1.0, timeMultiplier = 1.0, failCraft = false, loseInputs = false },
        sound = "power_surge",
        particle = { dict = "core", name = "ent_sht_electrical_box", duration = 2000 },
        notification = { title = "⚡ Power Surge!", message = "Station took 15 durability damage!", type = "error" },
    },
    
    ['equipment_jam'] = {
        chance = 0.05,  -- 5%
        label = "Equipment Jam",
        description = "Something got stuck - took longer than expected",
        type = "negative",
        effects = { durabilityChange = -5, outputMultiplier = 1.0, timeMultiplier = 1.5, failCraft = false, loseInputs = false },
        sound = "event_fail",
        particle = nil,
        notification = { title = "🔧 Equipment Jam", message = "Crafting took 50% longer!", type = "warning" },
    },
    
    ['partial_loss'] = {
        chance = 0.03,  -- 3%
        label = "Partial Loss",
        description = "Some product was lost in the process",
        type = "negative",
        effects = { durabilityChange = 0, outputMultiplier = 0.5, timeMultiplier = 1.0, failCraft = false, loseInputs = false },
        sound = "event_fail",
        particle = nil,
        notification = { title = "📉 Partial Loss", message = "Only got half the expected output!", type = "warning" },
    },
    
    ['equipment_failure'] = {
        chance = 0.02,  -- 2%
        label = "Equipment Failure",
        description = "Critical failure - craft ruined, materials lost",
        type = "negative",
        effects = { durabilityChange = -25, outputMultiplier = 0, timeMultiplier = 1.0, failCraft = true, loseInputs = true },
        sound = "event_explosion",
        particle = { dict = "core", name = "ent_sht_smoke", duration = 5000 },
        notification = { title = "💥 Equipment Failure!", message = "Craft failed! Materials lost!", type = "error" },
    },

    -- ═══════════════════════════════════════════════════════════════════
    -- CRITICAL EVENTS (Rare but impactful)
    -- ═══════════════════════════════════════════════════════════════════
    ['small_explosion'] = {
        chance = 0.01,  -- 1%
        label = "Small Explosion",
        description = "Something went very wrong!",
        type = "negative",
        effects = { durabilityChange = -40, outputMultiplier = 0, timeMultiplier = 1.0, failCraft = true, loseInputs = true, explosion = true },
        sound = "event_explosion",
        particle = { dict = "core", name = "exp_grd_bzgas_smoke", duration = 5000 },
        notification = { title = "💥 EXPLOSION!", message = "The station exploded! Materials lost!", type = "error" },
    },
    
    ['police_attention'] = {
        chance = 0.02,  -- 2%
        label = "Suspicious Activity",
        description = "Someone noticed what you're doing...",
        type = "negative",
        effects = { durabilityChange = 0, outputMultiplier = 1.0, timeMultiplier = 1.0, failCraft = false, loseInputs = false, alertPolice = true },
        sound = "event_fail",
        particle = nil,
        notification = { title = "🚨 Suspicious Activity", message = "Police have been alerted to the area!", type = "error" },
    },
    
    ['master_craft'] = {
        chance = 0.01,  -- 1%
        label = "Master Craft",
        description = "Absolutely flawless execution!",
        type = "positive",
        effects = { durabilityChange = 10, outputMultiplier = 3.0, timeMultiplier = 0.5, failCraft = false, loseInputs = false },
        sound = "event_bonus",
        particle = { dict = "scr_rcbarry2", name = "scr_clown_appears", duration = 3000 },
        notification = { title = "👑 MASTER CRAFT!", message = "TRIPLE output! Station repaired!", type = "success" },
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

EventSettings = {
    enabled = true,                    -- Master toggle for random events
    showNotifications = true,          -- Show event notifications
    playEffects = true,                -- Play particles and sounds
    
    -- Event chance modifiers based on durability
    durabilityModifiers = {
        { threshold = 75, modifier = 1.0 },   -- 75%+ durability = normal chances
        { threshold = 50, modifier = 1.25 },  -- 50-74% = 25% more likely bad events
        { threshold = 25, modifier = 1.5 },   -- 25-49% = 50% more likely bad events
        { threshold = 0,  modifier = 2.0 },   -- <25% = double chance bad events
    },
    
    -- Stations that are immune to certain events
    immuneStations = {
        -- ['workbench'] = { 'small_explosion', 'police_attention' },
    },
}

return { Events = Events, EventSettings = EventSettings }
