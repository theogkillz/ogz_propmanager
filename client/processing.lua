--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║              OGz PropManager v3.2 - Client Processing                     ║
    ║                                                                           ║
    ║  Client-side UI for drug processing stations                              ║
    ║  Hierarchical menu: Category → Strain → Recipe                            ║
    ║                                                                           ║
    ║  v3.2: Organized menus by Category > Strain > Breakdown                   ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

if not Config.Features.Processing then return end

local isProcessing = false
local currentStation = nil
local currentCategory = nil  -- Track for back navigation
local currentStrain = nil    -- Track for back navigation
local cachedRecipes = nil    -- Cache server response for menu navigation

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetRecipeConfig(recipeId)
    return Processing.Recipes[recipeId]
end

local function GetStationConfig(stationType)
    return Processing.Stations[stationType]
end

local function GetCategoryConfig(category)
    return Processing.Categories[category]
end

local function GetStrainConfig(strain)
    return Processing.Strains and Processing.Strains[strain] or nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- TARGET OPTIONS FOR PROCESSING STATIONS
-- ═══════════════════════════════════════════════════════════════════════════

function AddProcessingStationTarget(entity, stationType, stationData)
    local stationConfig = GetStationConfig(stationType)
    if not stationConfig then return end
    
    local options = {}
    
    -- Use Station (Open Recipe Menu)
    options[#options + 1] = {
        name = "ogz_process_use_" .. stationType,
        icon = stationConfig.icon or "fas fa-balance-scale",
        iconColor = stationConfig.iconColor or "#00ff00",
        label = "Use " .. stationConfig.label,
        distance = stationConfig.interactDistance or 1.5,
        canInteract = function()
            if isProcessing then return false end
            
            -- Check gang/job restrictions
            if stationConfig.groups then
                local hasAccess = false
                if HasGang(stationConfig.groups) or HasJob(stationConfig.groups) then
                    hasAccess = true
                end
                return hasAccess
            end
            
            return true
        end,
        onSelect = function()
            OpenProcessingMenu(stationType, entity, stationData)
        end,
    }
    
    -- Quick Info
    options[#options + 1] = {
        name = "ogz_process_info_" .. stationType,
        icon = "fas fa-info-circle",
        iconColor = "#3498db",
        label = "Station Info",
        distance = stationConfig.interactDistance or 1.5,
        onSelect = function()
            ShowStationInfo(stationType)
        end,
    }
    
    exports.ox_target:addLocalEntity(entity, options)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LEVEL 1: CATEGORY MENU (Main Entry Point)
-- ═══════════════════════════════════════════════════════════════════════════

function OpenProcessingMenu(stationType, entity, stationData)
    if isProcessing then
        Notify("Already processing!", "error")
        return
    end
    
    local stationConfig = GetStationConfig(stationType)
    if not stationConfig then return end
    
    currentStation = {
        type = stationType,
        entity = entity,
        data = stationData,
    }
    
    -- Reset navigation state
    currentCategory = nil
    currentStrain = nil
    
    -- Determine if this is a placed station
    local isPlacedStation = stationData and stationData.id and true or false
    
    if Config.Debug then
        print("[OGz Processing Client] Opening menu for station:", stationType)
        print("[OGz Processing Client] Is placed station:", tostring(isPlacedStation))
    end
    
    -- Get recipes from server
    local recipes = lib.callback.await('ogz_propmanager:server:GetStationRecipes', false, stationType, isPlacedStation)
    
    if not recipes or next(recipes) == nil then
        Notify("No recipes available at this station", "info")
        return
    end
    
    -- Cache recipes for menu navigation
    cachedRecipes = recipes
    
    -- Group recipes by category, then by strain
    local categories = {}
    for recipeId, recipe in pairs(recipes) do
        local cat = recipe.category or 'general'
        if not categories[cat] then
            categories[cat] = {
                strains = {},
                hasAvailable = false
            }
        end
        
        local strain = recipe.strain or 'default'
        if not categories[cat].strains[strain] then
            categories[cat].strains[strain] = {}
        end
        categories[cat].strains[strain][recipeId] = recipe
        
        if recipe.canCraft then
            categories[cat].hasAvailable = true
        end
    end
    
    -- Build category menu
    local menuOptions = {}
    
    -- Sort categories for consistent ordering
    local sortedCategories = {}
    for cat, _ in pairs(categories) do
        sortedCategories[#sortedCategories + 1] = cat
    end
    table.sort(sortedCategories)
    
    for _, category in ipairs(sortedCategories) do
        local catData = categories[category]
        local catConfig = GetCategoryConfig(category)
        
        -- Count strains and recipes in this category
        local strainCount = 0
        local recipeCount = 0
        for _, strainRecipes in pairs(catData.strains) do
            strainCount = strainCount + 1
            for _ in pairs(strainRecipes) do
                recipeCount = recipeCount + 1
            end
        end
        
        local statusIcon = catData.hasAvailable and "✅" or "⚠️"
        
        menuOptions[#menuOptions + 1] = {
            title = (catConfig and catConfig.label or category:upper()),
            description = string.format("%d strain%s, %d recipe%s", 
                strainCount, strainCount == 1 and "" or "s",
                recipeCount, recipeCount == 1 and "" or "s"),
            icon = catConfig and catConfig.icon or "fas fa-box",
            iconColor = catConfig and catConfig.iconColor or "#ffffff",
            onSelect = function()
                OpenCategoryMenu(category, catData.strains)
            end,
        }
    end
    
    -- Close button
    menuOptions[#menuOptions + 1] = {
        title = "← Close",
        icon = "fas fa-times",
        iconColor = "#e74c3c",
        onSelect = function()
            currentStation = nil
            cachedRecipes = nil
        end,
    }
    
    lib.registerContext({
        id = "ogz_processing_categories",
        title = "🔬 " .. stationConfig.label,
        options = menuOptions,
    })
    lib.showContext("ogz_processing_categories")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LEVEL 2: STRAIN MENU (Shows strains within a category)
-- ═══════════════════════════════════════════════════════════════════════════

function OpenCategoryMenu(category, strains)
    currentCategory = category
    currentStrain = nil
    
    local catConfig = GetCategoryConfig(category)
    local menuOptions = {}
    
    -- Sort strains for consistent ordering
    local sortedStrains = {}
    for strain, _ in pairs(strains) do
        sortedStrains[#sortedStrains + 1] = strain
    end
    table.sort(sortedStrains)
    
    for _, strain in ipairs(sortedStrains) do
        local strainRecipes = strains[strain]
        local strainConfig = GetStrainConfig(strain)
        
        -- Count recipes and check availability
        local recipeCount = 0
        local availableCount = 0
        for _, recipe in pairs(strainRecipes) do
            recipeCount = recipeCount + 1
            if recipe.canCraft then
                availableCount = availableCount + 1
            end
        end
        
        -- Generate label if no config
        local strainLabel = strainConfig and strainConfig.label or 
            strain:gsub("_", " "):gsub("(%a)([%w]*)", function(a, b) return a:upper()..b:lower() end)
        
        local statusText = availableCount > 0 
            and string.format("%d/%d available", availableCount, recipeCount)
            or "Missing materials"
        
        menuOptions[#menuOptions + 1] = {
            title = strainLabel,
            description = statusText,
            icon = strainConfig and strainConfig.icon or catConfig and catConfig.icon or "fas fa-leaf",
            iconColor = strainConfig and strainConfig.iconColor or catConfig and catConfig.iconColor or "#ffffff",
            onSelect = function()
                OpenStrainMenu(strain, strainRecipes, strainLabel)
            end,
        }
    end
    
    -- Back button
    menuOptions[#menuOptions + 1] = {
        title = "← Back to Categories",
        icon = "fas fa-arrow-left",
        iconColor = "#3498db",
        onSelect = function()
            if currentStation then
                OpenProcessingMenu(currentStation.type, currentStation.entity, currentStation.data)
            end
        end,
    }
    
    lib.registerContext({
        id = "ogz_processing_strains",
        title = catConfig and catConfig.label or category:upper(),
        options = menuOptions,
    })
    lib.showContext("ogz_processing_strains")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LEVEL 3: RECIPE MENU (Shows recipes within a strain)
-- ═══════════════════════════════════════════════════════════════════════════

function OpenStrainMenu(strain, recipes, strainLabel)
    currentStrain = strain
    
    local menuOptions = {}
    
    -- Sort recipes by label for consistent ordering
    local sortedRecipes = {}
    for recipeId, recipe in pairs(recipes) do
        sortedRecipes[#sortedRecipes + 1] = { id = recipeId, data = recipe }
    end
    table.sort(sortedRecipes, function(a, b) return a.data.label < b.data.label end)
    
    for _, recipeEntry in ipairs(sortedRecipes) do
        local recipeId = recipeEntry.id
        local recipe = recipeEntry.data
        
        local statusIcon = recipe.canCraft and "✅" or "❌"
        
        -- Use labels from server response
        local inputLabel = recipe.input.label or recipe.input.item
        local outputLabel = recipe.output.label or recipe.output.item
        
        local description = recipe.canCraft 
            and string.format("%dx %s → %dx %s", recipe.input.count, inputLabel, recipe.output.count, outputLabel)
            or recipe.reason
        
        menuOptions[#menuOptions + 1] = {
            title = statusIcon .. " " .. recipe.label,
            description = description,
            icon = "fas fa-flask",
            iconColor = recipe.canCraft and "#2ecc71" or "#e74c3c",
            disabled = not recipe.canCraft,
            onSelect = function()
                OpenRecipeConfirmation(recipeId, recipe)
            end,
        }
    end
    
    -- Back button
    menuOptions[#menuOptions + 1] = {
        title = "← Back to Strains",
        icon = "fas fa-arrow-left",
        iconColor = "#3498db",
        onSelect = function()
            -- Rebuild strains from cached recipes
            if cachedRecipes and currentCategory then
                local strains = {}
                for rid, r in pairs(cachedRecipes) do
                    if r.category == currentCategory then
                        local s = r.strain or 'default'
                        if not strains[s] then strains[s] = {} end
                        strains[s][rid] = r
                    end
                end
                OpenCategoryMenu(currentCategory, strains)
            end
        end,
    }
    
    lib.registerContext({
        id = "ogz_processing_recipes",
        title = "🌿 " .. strainLabel,
        options = menuOptions,
    })
    lib.showContext("ogz_processing_recipes")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RECIPE CONFIRMATION
-- ═══════════════════════════════════════════════════════════════════════════

function OpenRecipeConfirmation(recipeId, recipeInfo)
    -- Get current ingredient counts
    lib.callback('ogz_propmanager:server:GetRecipeIngredients', false, function(ingredients)
        if not ingredients then
            Notify("Failed to get recipe info", "error")
            return
        end
        
        local menuOptions = {}
        
        -- Recipe title with strain context
        local strainConfig = GetStrainConfig(currentStrain)
        local strainLabel = strainConfig and strainConfig.label or currentStrain or ""
        menuOptions[#menuOptions + 1] = {
            title = "📋 " .. strainLabel .. " - " .. recipeInfo.label,
            disabled = true,
        }
        
        -- Metadata info (if available)
        if ingredients.input.metadata then
            local metaStr = ""
            if ingredients.input.metadata.purity then
                metaStr = metaStr .. "Purity: " .. ingredients.input.metadata.purity .. "% "
            end
            if ingredients.input.metadata.quality then
                metaStr = metaStr .. "Quality: " .. ingredients.input.metadata.quality .. "% "
            end
            if metaStr ~= "" then
                menuOptions[#menuOptions + 1] = {
                    title = "🧬 " .. metaStr,
                    description = "Will be preserved in output!",
                    icon = "fas fa-dna",
                    iconColor = "#9b59b6",
                    disabled = true,
                }
            end
        end
        
        -- Divider
        menuOptions[#menuOptions + 1] = {
            title = "━━━ Requirements ━━━",
            disabled = true,
        }
        
        -- Tool requirement (use LABEL) - Only show if not at placed station
        local toolOk = ingredients.tool.have >= ingredients.tool.need
        local toolLabel = ingredients.tool.label or ingredients.tool.item
        
        -- Check if at placed station (tool not needed)
        local isPlacedStation = currentStation and currentStation.data and currentStation.data.id
        if isPlacedStation then
            menuOptions[#menuOptions + 1] = {
                title = "✅ " .. toolLabel,
                description = "Using placed station",
                icon = "fas fa-check-circle",
                iconColor = "#2ecc71",
                disabled = true,
            }
            toolOk = true  -- Override for placed stations
        else
            menuOptions[#menuOptions + 1] = {
                title = (toolOk and "✅" or "❌") .. " " .. toolLabel,
                description = string.format("Have: %d / Need: %d (not consumed)", ingredients.tool.have, ingredients.tool.need),
                icon = "fas fa-balance-scale",
                iconColor = toolOk and "#2ecc71" or "#e74c3c",
                disabled = true,
            }
        end
        
        -- Input item (use LABEL)
        local inputOk = ingredients.input.have >= ingredients.input.need
        local inputLabel = ingredients.input.label or ingredients.input.item
        menuOptions[#menuOptions + 1] = {
            title = (inputOk and "✅" or "❌") .. " " .. inputLabel,
            description = string.format("Have: %d / Need: %d", ingredients.input.have, ingredients.input.need),
            icon = "fas fa-cannabis",
            iconColor = inputOk and "#2ecc71" or "#e74c3c",
            disabled = true,
        }
        
        -- Containers (use LABEL)
        local containerOk = ingredients.containers.have >= ingredients.containers.need
        local containerLabel = ingredients.containers.label or ingredients.containers.item
        menuOptions[#menuOptions + 1] = {
            title = (containerOk and "✅" or "❌") .. " " .. containerLabel,
            description = string.format("Have: %d / Need: %d", ingredients.containers.have, ingredients.containers.need),
            icon = "fas fa-box",
            iconColor = containerOk and "#2ecc71" or "#e74c3c",
            disabled = true,
        }
        
        -- Divider
        menuOptions[#menuOptions + 1] = {
            title = "━━━ Output ━━━",
            disabled = true,
        }
        
        -- Output (use LABEL)
        local outputLabel = ingredients.output.label or ingredients.output.item
        menuOptions[#menuOptions + 1] = {
            title = "📦 " .. ingredients.output.count .. "x " .. outputLabel,
            description = "What you'll receive",
            icon = "fas fa-gift",
            iconColor = "#f39c12",
            disabled = true,
        }
        
        -- Action buttons
        local canCraft = toolOk and inputOk and containerOk
        
        if canCraft then
            menuOptions[#menuOptions + 1] = {
                title = "✅ Start Processing",
                description = string.format("Time: %.1f seconds", recipeInfo.time / 1000),
                icon = "fas fa-play",
                iconColor = "#2ecc71",
                onSelect = function()
                    StartProcessing(recipeId, recipeInfo)
                end,
            }
        else
            menuOptions[#menuOptions + 1] = {
                title = "❌ Missing Requirements",
                icon = "fas fa-times",
                iconColor = "#e74c3c",
                disabled = true,
            }
        end
        
        menuOptions[#menuOptions + 1] = {
            title = "← Back to Recipes",
            icon = "fas fa-arrow-left",
            onSelect = function()
                -- Go back to strain menu
                if cachedRecipes and currentStrain then
                    local strainRecipes = {}
                    local strainLabel = currentStrain
                    for rid, r in pairs(cachedRecipes) do
                        if r.strain == currentStrain then
                            strainRecipes[rid] = r
                            local sc = GetStrainConfig(r.strain)
                            if sc then strainLabel = sc.label end
                        end
                    end
                    OpenStrainMenu(currentStrain, strainRecipes, strainLabel)
                end
            end,
        }
        
        lib.registerContext({
            id = "ogz_processing_confirm",
            title = "🔬 Confirm Recipe",
            options = menuOptions,
        })
        lib.showContext("ogz_processing_confirm")
        
    end, recipeId)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROCESSING EXECUTION
-- ═══════════════════════════════════════════════════════════════════════════

function StartProcessing(recipeId, recipeInfo)
    if isProcessing then
        Notify("Already processing!", "error")
        return
    end
    
    isProcessing = true
    
    local playerPed = PlayerPedId()
    local processingTime = recipeInfo.time or Processing.Settings.DefaultProcessTime
    
    -- Face the station
    if currentStation and currentStation.entity and DoesEntityExist(currentStation.entity) then
        local stationCoords = GetEntityCoords(currentStation.entity)
        TaskTurnPedToFaceCoord(playerPed, stationCoords.x, stationCoords.y, stationCoords.z, 1000)
        Wait(500)
    end
    
    -- Load and play animation
    local animConfig = Processing.Settings.ProcessingAnim
    if animConfig and animConfig.dict then
        if LoadAnimDict(animConfig.dict) then
            TaskPlayAnim(playerPed, animConfig.dict, animConfig.anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end
    
    -- Play start sound
    if Processing.Settings.Sounds and Processing.Settings.Sounds.start then
        PlaySound(Processing.Settings.Sounds.start)
    end
    
    -- Progress bar
    local success = lib.progressBar({
        duration = processingTime,
        label = "Processing " .. recipeInfo.label .. "...",
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    })
    
    -- Cleanup animation
    ClearPedTasks(playerPed)
    
    if success then
        -- Tell server to process
        TriggerServerEvent("ogz_propmanager:server:ProcessRecipe", recipeId)
    else
        Notify("Processing cancelled", "error")
        isProcessing = false
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PROCESSING COMPLETE HANDLER
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent("ogz_propmanager:client:ProcessingComplete", function(recipeId, success)
    isProcessing = false
    
    if success then
        -- Play completion sound
        if Processing.Settings.Sounds and Processing.Settings.Sounds.complete then
            PlaySound(Processing.Settings.Sounds.complete)
        end
        
        -- Re-open at strain level for continuous processing
        if currentStation and currentStrain and cachedRecipes then
            Wait(500)
            -- Refresh recipes from server (counts have changed)
            local isPlacedStation = currentStation.data and currentStation.data.id and true or false
            local freshRecipes = lib.callback.await('ogz_propmanager:server:GetStationRecipes', false, currentStation.type, isPlacedStation)
            
            if freshRecipes then
                cachedRecipes = freshRecipes
                local strainRecipes = {}
                local strainLabel = currentStrain
                for rid, r in pairs(cachedRecipes) do
                    if r.strain == currentStrain then
                        strainRecipes[rid] = r
                        local sc = GetStrainConfig(r.strain)
                        if sc then strainLabel = sc.label end
                    end
                end
                OpenStrainMenu(currentStrain, strainRecipes, strainLabel)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION INFO
-- ═══════════════════════════════════════════════════════════════════════════

function ShowStationInfo(stationType)
    local stationConfig = GetStationConfig(stationType)
    if not stationConfig then return end
    
    local menuOptions = {
        {
            title = "📋 " .. stationConfig.label,
            description = stationConfig.description,
            icon = stationConfig.icon or "fas fa-info",
            disabled = true,
        },
        {
            title = "━━━ Allowed Categories ━━━",
            disabled = true,
        },
    }
    
    for _, category in ipairs(stationConfig.allowedCategories) do
        local catConfig = GetCategoryConfig(category)
        menuOptions[#menuOptions + 1] = {
            title = catConfig and catConfig.label or category,
            icon = catConfig and catConfig.icon or "fas fa-box",
            iconColor = catConfig and catConfig.iconColor or "#ffffff",
            disabled = true,
        }
    end
    
    if stationConfig.groups then
        menuOptions[#menuOptions + 1] = {
            title = "━━━ Restrictions ━━━",
            disabled = true,
        }
        for group, grade in pairs(stationConfig.groups) do
            menuOptions[#menuOptions + 1] = {
                title = group .. " (Grade " .. grade .. "+)",
                icon = "fas fa-lock",
                iconColor = "#e74c3c",
                disabled = true,
            }
        end
    end
    
    menuOptions[#menuOptions + 1] = {
        title = "← Close",
        icon = "fas fa-times",
        onSelect = function() end,
    }
    
    lib.registerContext({
        id = "ogz_processing_info",
        title = "ℹ️ Station Info",
        options = menuOptions,
    })
    lib.showContext("ogz_processing_info")
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SOUND HELPER
-- ═══════════════════════════════════════════════════════════════════════════

function PlaySound(soundKey)
    local soundConfig = Sounds and Sounds[soundKey]
    if not soundConfig then return end
    
    local coords = GetEntityCoords(PlayerPedId())
    
    if soundConfig.type == "native" then
        PlaySoundFromCoord(-1, soundConfig.sound, coords.x, coords.y, coords.z, 
            soundConfig.soundSet, false, soundConfig.range or 5.0, false)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("ogz_process_test", function(_, args)
    local stationType = args[1] or "drug_scale"
    
    local stationConfig = GetStationConfig(stationType)
    if not stationConfig then
        print("[OGz Processing] Unknown station type:", stationType)
        print("Available stations:")
        for id, _ in pairs(Processing.Stations) do
            print("  -", id)
        end
        return
    end
    
    -- Open menu without needing a physical station
    OpenProcessingMenu(stationType, nil, nil)
end, false)

RegisterCommand("ogz_process_recipes", function()
    print("[OGz Processing] Available recipes:")
    for recipeId, recipe in pairs(Processing.Recipes) do
        print(string.format("  - %s: %s [%s/%s]", recipeId, recipe.label, recipe.category, recipe.strain or "none"))
    end
end, false)

RegisterCommand("ogz_spawn_scale", function(_, args)
    local stationType = args[1] or "drug_scale"
    local stationConfig = GetStationConfig(stationType)
    
    if not stationConfig then
        Notify("Unknown station type", "error")
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local modelHash = type(stationConfig.model) == "string" and joaat(stationConfig.model) or stationConfig.model
    
    if not LoadModel(modelHash) then
        Notify("Failed to load model", "error")
        return
    end
    
    local entity = CreateObject(modelHash, coords.x, coords.y + 1.0, coords.z, false, false, false)
    SetEntityHeading(entity, heading)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Add target
    AddProcessingStationTarget(entity, stationType, { id = 0, temp = true })
    
    Notify("Spawned test " .. stationConfig.label, "success")
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports("OpenProcessingMenu", OpenProcessingMenu)
exports("AddProcessingStationTarget", AddProcessingStationTarget)
exports("IsProcessing", function() return isProcessing end)

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(2000)
    
    local stationCount = 0
    for _ in pairs(Processing.Stations) do stationCount = stationCount + 1 end
    
    local recipeCount = 0
    for _ in pairs(Processing.Recipes) do recipeCount = recipeCount + 1 end
    
    local strainCount = 0
    if Processing.Strains then
        for _ in pairs(Processing.Strains) do strainCount = strainCount + 1 end
    end
    
    print(string.format("^2[OGz PropManager v3.2]^0 Processing client loaded: %d stations, %d strains, %d recipes", stationCount, strainCount, recipeCount))
end)
