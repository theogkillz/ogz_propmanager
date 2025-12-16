--[[
    OGz PropManager v3.1 - Drug Processing Config (Compact)
    
    METADATA PRESERVED: purity, quality, durability
    WEIGHTS: gram(1g), quarter(7g), ounce(28g), pound(448g), brick(1000g)
]]

Processing = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════

Processing.Settings = {
    RequiredTool = 'ogz_bulk_scale',
    ToolConsumed = false,
    PreserveMetadata = { 'purity', 'quality', 'durability' },
    DefaultProcessTime = 5000,
    ProcessingAnim = { dict = 'anim@amb@business@weed@weed_inspecting_high_dry@', anim = 'weed_inspecting_high_base_inspector', duration = 5000 },
    Sounds = { start = 'scale_use', complete = 'packaging_complete' },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- CONTAINERS (Empty packaging materials)
-- ═══════════════════════════════════════════════════════════════════════════

Processing.Containers = {
    gram    = { item = 'ls_empty_baggy',        label = 'Small Baggy',   icon = 'fas fa-prescription-bottle' },
    quarter = { item = 'ls_empty_pill_bottle',  label = 'Pill Bottle',   icon = 'fas fa-pills' },
    ounce   = { item = 'ls_empty_lrg_baggy',    label = 'Large Baggy',   icon = 'fas fa-box' },
    pound   = { item = 'ls_empty_xlrg_baggy',   label = 'XL Baggy',      icon = 'fas fa-box-open' },
    brick   = { item = 'ls_empty_special_wrap', label = 'Special Wrap',  icon = 'fas fa-cube' },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- STATIONS
-- ═══════════════════════════════════════════════════════════════════════════

Processing.Stations = {
    ['drug_scale'] = {
        label = 'Drug Scale',
        description = 'Professional digital scale for precise measurements',
        model = 'bzzz_weed_scale_a',
        icon = 'fas fa-balance-scale',
        iconColor = '#00ff00',
        allowedCategories = { 'weed', 'coke', 'meth', 'general' },
        craftable = true,
        item = 'ogz_drug_scale',
        interactDistance = 1.5,
        groups = nil,
    },
    ['bulk_scale'] = {
        label = 'Bulk Scale',
        description = 'Industrial scale for large quantities',
        model = 'bkr_prop_coke_scale_01',
        icon = 'fas fa-weight-hanging',
        iconColor = '#ffaa00',
        allowedCategories = { 'weed', 'coke', 'meth', 'general' },
        craftable = true,
        item = 'ogz_bulk_scale',
        interactDistance = 2.0,
        groups = nil,
    },
    ['rolling_table'] = {
        label = 'Rolling Table',
        description = 'Clean surface for rolling joints and blunts',
        model = 'bkr_prop_weed_table_01a',
        icon = 'fas fa-cannabis',
        iconColor = '#2ecc71',
        allowedCategories = { 'weed', 'rolling' },
        craftable = true,
        item = 'ogz_rolling_table',
        interactDistance = 1.5,
        groups = nil,
    },
    ['packaging_station'] = {
        label = 'Packaging Station',
        description = 'Professional packaging setup',
        model = 'prop_tool_bench02',
        icon = 'fas fa-boxes',
        iconColor = '#9b59b6',
        allowedCategories = { 'weed', 'coke', 'meth', 'general' },
        craftable = true,
        item = 'ogz_packaging_station',
        interactDistance = 2.0,
        groups = nil,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- CATEGORIES
-- ═══════════════════════════════════════════════════════════════════════════

Processing.Categories = {
    weed    = { label = '🌿 Cannabis',        icon = 'fas fa-cannabis',  iconColor = '#2ecc71' },
    coke    = { label = '❄️ Cocaine',         icon = 'fas fa-snowflake', iconColor = '#ecf0f1' },
    meth    = { label = '💎 Methamphetamine', icon = 'fas fa-gem',       iconColor = '#3498db' },
    general = { label = '📦 General',         icon = 'fas fa-box',       iconColor = '#95a5a6' },
    rolling = { label = '🚬 Rolling',         icon = 'fas fa-smoking',   iconColor = '#e67e22' },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- STRAINS (For hierarchical menu organization)
-- ═══════════════════════════════════════════════════════════════════════════

Processing.Strains = {
    -- Cannabis Strains
    ['cosmic_kush']  = { label = 'Cosmic Kush',  icon = 'fas fa-star',     iconColor = '#9b59b6', category = 'weed' },
    ['purple_haze']  = { label = 'Purple Haze',  icon = 'fas fa-cloud',    iconColor = '#8e44ad', category = 'weed' },
    ['og_kush']      = { label = 'OG Kush',      icon = 'fas fa-leaf',     iconColor = '#27ae60', category = 'weed' },
    ['sour_diesel']  = { label = 'Sour Diesel',  icon = 'fas fa-gas-pump', iconColor = '#f39c12', category = 'weed' },
    ['blue_dream']   = { label = 'Blue Dream',   icon = 'fas fa-moon',     iconColor = '#3498db', category = 'weed' },
    
    -- Cocaine Types
    ['colombian']    = { label = 'Colombian White', icon = 'fas fa-mountain',  iconColor = '#ecf0f1', category = 'coke' },
    ['peruvian']     = { label = 'Peruvian Flake',  icon = 'fas fa-snowflake', iconColor = '#bdc3c7', category = 'coke' },
    
    -- Meth Types
    ['blue_sky']     = { label = 'Blue Sky',     icon = 'fas fa-gem',      iconColor = '#3498db', category = 'meth' },
    ['glass']        = { label = 'Glass',        icon = 'fas fa-cube',     iconColor = '#95a5a6', category = 'meth' },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- RECIPES
-- { label, category, input={item,count,metadata}, containers={item,count}, output={item,count}, time, groups, stations }
-- ═══════════════════════════════════════════════════════════════════════════

Processing.Recipes = {
    -- 🌿 WEED - COSMIC KUSH
    ['cosmic_kush_gram']    = { label = 'Cosmic Kush → Grams (28x)',    category = 'weed',  strain = 'cosmic_kush',  input = { item = 'ls_cosmic_kush_bud', count = 28, metadata = true }, containers = { item = 'ls_empty_baggy', count = 28 },       output = { item = 'ls_cosmic_kush_bag', count = 28 },   time = 8000,  groups = nil, stations = { 'drug_scale' } },
    ['cosmic_kush_quarter'] = { label = 'Cosmic Kush → Quarters (4x)',  category = 'weed',  strain = 'cosmic_kush',  input = { item = 'ls_cosmic_kush_bud', count = 112, metadata = true }, containers = { item = 'ls_empty_pill_bottle', count = 4 }, output = { item = 'ls_cosmic_kush_quarter', count = 4 },  time = 8000,  groups = nil, stations = { 'drug_scale' } },
    ['cosmic_kush_ounce'] = { label = 'Cosmic Kush → Ounce (1x)',  category = 'weed',  strain = 'cosmic_kush',  input = { item = 'ls_cosmic_kush_bud', count = 448, metadata = true }, containers = { item = 'ls_empty_lrg_baggy', count = 4 }, output = { item = 'ls_cosmic_kush_ounce', count = 1 },  time = 12000,  groups = nil, stations = { 'bulk_scale' } },
    ['cosmic_kush_pound'] = { label = 'Cosmic Kush → Pound (1x)',  category = 'weed',  strain = 'cosmic_kush',  input = { item = 'ls_cosmic_kush_ounce', count = 16, metadata = true }, containers = { item = 'ls_empty_xlrg_baggy', count = 2 }, output = { item = 'ls_cosmic_kush_brick', count = 1 },  time = 15000,  groups = nil, stations = { 'bulk_scale' } },
    ['cosmic_kush_joint']   = { label = 'Cosmic Kush Joint', category = 'rolling', strain = 'cosmic_kush', input = { item = 'ls_cosmic_kush_bud', count = 1, metadata = true }, containers = { item = 'ls_rolling_paper', count = 1 },      output = { item = 'ls_cosmic_kush_joint', count = 1 },    time = 3000,  groups = nil, stations = { 'rolling_table' } },
    
    -- -- 🌿 WEED - PURPLE HAZE
    -- ['purple_haze_gram']    = { label = 'Purple Haze → Grams (28x)',    category = 'weed',    input = { item = 'ls_purple_haze_bud', count = 1, metadata = true }, containers = { item = 'ls_empty_baggy', count = 28 },       output = { item = 'ls_purple_haze_baggy', count = 28 },   time = 8000,  groups = nil, stations = { 'drug_scale', 'bulk_scale', 'packaging_station' } },
    -- ['purple_haze_joint']   = { label = 'Purple Haze Joint',            category = 'rolling', input = { item = 'ls_purple_haze_bud', count = 1, metadata = true }, containers = { item = 'ls_rolling_paper', count = 1 },      output = { item = 'ls_purple_haze_joint', count = 1 },    time = 3000,  groups = nil, stations = { 'rolling_table', 'drug_scale' } },
    
    -- -- 🌿 WEED - OG KUSH
    -- ['og_kush_gram']        = { label = 'OG Kush → Grams (28x)',        category = 'weed',    input = { item = 'ls_og_kush_bud', count = 1, metadata = true },     containers = { item = 'ls_empty_baggy', count = 28 },       output = { item = 'ls_og_kush_baggy', count = 28 },       time = 8000,  groups = nil, stations = { 'drug_scale', 'bulk_scale', 'packaging_station' } },
    -- ['og_kush_joint']       = { label = 'OG Kush Joint',                category = 'rolling', input = { item = 'ls_og_kush_bud', count = 1, metadata = true },     containers = { item = 'ls_rolling_paper', count = 1 },      output = { item = 'ls_og_kush_joint', count = 1 },        time = 3000,  groups = nil, stations = { 'rolling_table', 'drug_scale' } },
    
    -- -- ❄️ COCAINE
    -- ['coke_gram']           = { label = 'Cocaine → Grams (28x)',        category = 'coke',    input = { item = 'coke', count = 1, metadata = true },               containers = { item = 'ls_empty_baggy', count = 28 },       output = { item = 'cokebaggy', count = 28 },              time = 10000, groups = nil, stations = { 'drug_scale', 'bulk_scale', 'packaging_station' } },
    -- ['coke_quarter']        = { label = 'Cocaine → Quarters (4x)',      category = 'coke',    input = { item = 'coke', count = 1, metadata = true },               containers = { item = 'ls_empty_pill_bottle', count = 4 }, output = { item = 'coke_quarter', count = 4 },            time = 8000,  groups = nil, stations = { 'drug_scale', 'bulk_scale', 'packaging_station' } },
    -- ['coke_ounce']          = { label = 'Cocaine → Ounce (1x)',         category = 'coke',    input = { item = 'coke', count = 1, metadata = true },               containers = { item = 'ls_empty_lrg_baggy', count = 1 },    output = { item = 'coke_ounce', count = 1 },              time = 5000,  groups = nil, stations = { 'drug_scale', 'bulk_scale' } },
    -- ['coke_brick_to_ounces']= { label = 'Cocaine Brick → Ounces (35x)', category = 'coke',    input = { item = 'coke_brick', count = 1, metadata = true },          containers = { item = 'ls_empty_lrg_baggy', count = 35 },   output = { item = 'coke_ounce', count = 35 },             time = 30000, groups = nil, stations = { 'bulk_scale', 'packaging_station' } },
    
    -- -- 💎 METH
    -- ['meth_gram']           = { label = 'Meth → Grams (28x)',           category = 'meth',    input = { item = 'meth', count = 1, metadata = true },               containers = { item = 'ls_empty_baggy', count = 28 },       output = { item = 'methbaggy', count = 28 },              time = 10000, groups = nil, stations = { 'drug_scale', 'bulk_scale', 'packaging_station' } },
    -- ['meth_quarter']        = { label = 'Meth → Quarters (4x)',         category = 'meth',    input = { item = 'meth', count = 1, metadata = true },               containers = { item = 'ls_empty_pill_bottle', count = 4 }, output = { item = 'meth_quarter', count = 4 },            time = 8000,  groups = nil, stations = { 'drug_scale', 'bulk_scale', 'packaging_station' } },
    -- ['meth_ounce']          = { label = 'Meth → Ounce (1x)',            category = 'meth',    input = { item = 'meth', count = 1, metadata = true },               containers = { item = 'ls_empty_lrg_baggy', count = 1 },    output = { item = 'meth_ounce', count = 1 },              time = 5000,  groups = nil, stations = { 'drug_scale', 'bulk_scale' } },
    
    -- -- 🔄 REVERSE (Combine smaller → larger)
    -- ['coke_grams_to_ounce'] = { label = 'Combine Coke Grams → Ounce',   category = 'coke',    input = { item = 'cokebaggy', count = 28, metadata = true },          containers = { item = 'ls_empty_lrg_baggy', count = 1 },    output = { item = 'coke_ounce', count = 1 },              time = 8000,  groups = nil, stations = { 'drug_scale', 'bulk_scale' } },
    -- ['meth_grams_to_ounce'] = { label = 'Combine Meth Grams → Ounce',   category = 'meth',    input = { item = 'methbaggy', count = 28, metadata = true },          containers = { item = 'ls_empty_lrg_baggy', count = 1 },    output = { item = 'meth_ounce', count = 1 },              time = 8000,  groups = nil, stations = { 'drug_scale', 'bulk_scale' } },
}

-- Gang-locked recipes (uncomment and modify as needed)
Processing.GangRecipes = {
    -- ['ballas_purple'] = { label = 'Ballas Purple Pack', category = 'weed', input = { item = 'ls_purple_haze_bud', count = 1, metadata = true }, containers = { item = 'ballas_bag', count = 1 }, output = { item = 'ballas_purple_pack', count = 1 }, time = 5000, groups = { ['ballas'] = 0 }, stations = { 'drug_scale' } },
}

-- ox_inventory integration
Processing.OxIntegration = {
    Enabled = true,
    MetadataTables = { 'drug_scale', 'bulk_scale', 'rolling_table', 'packaging_station' },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

function Processing.GetRecipesByCategory(category)
    local recipes = {}
    for id, recipe in pairs(Processing.Recipes) do
        if recipe.category == category then recipes[id] = recipe end
    end
    return recipes
end

function Processing.GetRecipesByStrain(strain)
    local recipes = {}
    for id, recipe in pairs(Processing.Recipes) do
        if recipe.strain == strain then recipes[id] = recipe end
    end
    return recipes
end

function Processing.GetStrainsForCategory(category)
    local strains = {}
    local found = {}
    for _, recipe in pairs(Processing.Recipes) do
        if recipe.category == category and recipe.strain and not found[recipe.strain] then
            found[recipe.strain] = true
            local strainConfig = Processing.Strains[recipe.strain]
            if strainConfig then
                strains[recipe.strain] = strainConfig
            else
                -- Auto-generate strain config if not defined
                strains[recipe.strain] = {
                    label = recipe.strain:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper()..b:lower() end),
                    icon = 'fas fa-leaf',
                    iconColor = '#ffffff',
                    category = category
                }
            end
        end
    end
    return strains
end

function Processing.GetRecipesForStation(stationType)
    local station = Processing.Stations[stationType]
    if not station then return {} end
    
    local recipes = {}
    for id, recipe in pairs(Processing.Recipes) do
        local allowed = false
        if recipe.stations then
            for _, s in ipairs(recipe.stations) do
                if s == stationType then allowed = true break end
            end
        else
            for _, cat in ipairs(station.allowedCategories) do
                if recipe.category == cat then allowed = true break end
            end
        end
        if allowed then recipes[id] = recipe end
    end
    return recipes
end

function Processing.CanUseRecipe(recipeId, playerGang, playerJob, gangGrade, jobGrade)
    local recipe = Processing.Recipes[recipeId]
    if not recipe or not recipe.groups then return true end
    if playerGang and recipe.groups[playerGang] and gangGrade >= recipe.groups[playerGang] then return true end
    if playerJob and recipe.groups[playerJob] and jobGrade >= recipe.groups[playerJob] then return true end
    return false
end