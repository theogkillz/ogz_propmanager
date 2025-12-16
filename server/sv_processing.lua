--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║              OGz PropManager v3.2 - Server Processing                     ║
    ║                                                                           ║
    ║  Handles drug processing with FULL METADATA PRESERVATION                  ║
    ║  Station-aware tool requirements (each station uses its own tool item)    ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
    
    KEY FUNCTIONS:
    - GetItemWithMetadata()  : Extract item with full metadata
    - PreserveMetadata()     : Transfer metadata to new items
    - ProcessRecipe()        : Execute recipe with metadata flow
    
    v3.2 UPDATES:
    - Added strain field support for hierarchical menus
    - isPlacedStation context preserved for full workflow
    - Tool check bypassed for placed stations
]]

if not Config.Features.Processing then return end

local QBX = exports.qbx_core
local tablePrefix = Config.Database.TablePrefix

-- Track current station context per player for processing
local playerStationContext = {}
local playerPlacedStationContext = {}  -- Track if player is at a placed station

-- Cache for item labels
local itemLabelCache = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════

local function GetPlayer(source) return QBX:GetPlayer(source) end
local function GetCitizenId(source) local p = GetPlayer(source) return p and p.PlayerData.citizenid end
local function DebugPrint(...) if Config.Debug then print("[OGz Processing]", ...) end end

local function GetPlayerGang(source)
    local player = GetPlayer(source)
    if player and player.PlayerData.gang then
        return player.PlayerData.gang.name, player.PlayerData.gang.grade and player.PlayerData.gang.grade.level or 0
    end
    return nil, 0
end

local function GetPlayerJob(source)
    local player = GetPlayer(source)
    if player and player.PlayerData.job then
        return player.PlayerData.job.name, player.PlayerData.job.grade and player.PlayerData.job.grade.level or 0
    end
    return nil, 0
end

---Get item label from ox_inventory (with caching)
---@param itemName string Item name
---@return string label Item label or name as fallback
local function GetItemLabel(itemName)
    if itemLabelCache[itemName] then
        return itemLabelCache[itemName]
    end
    
    -- Try to get from ox_inventory
    local success, itemData = pcall(function()
        return exports.ox_inventory:Items(itemName)
    end)
    
    if success and itemData and itemData.label then
        itemLabelCache[itemName] = itemData.label
        return itemData.label
    end
    
    -- Fallback: format the item name nicely
    local formatted = itemName:gsub("_", " "):gsub("ls ", ""):gsub("ogz ", "")
    formatted = formatted:gsub("(%a)([%w]*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    
    itemLabelCache[itemName] = formatted
    return formatted
end

-- ═══════════════════════════════════════════════════════════════════════════
-- STATION-AWARE TOOL REQUIREMENT
-- ═══════════════════════════════════════════════════════════════════════════

---Get the required tool item for a specific station type
---@param stationType string|nil Station type (e.g., 'drug_scale', 'bulk_scale')
---@return string toolItem The item name required as a tool
function GetRequiredToolForStation(stationType)
    -- If station type provided, check for station-specific tool
    if stationType and Processing.Stations[stationType] then
        local stationConfig = Processing.Stations[stationType]
        if stationConfig.item then
            DebugPrint("Station-specific tool for", stationType, ":", stationConfig.item)
            return stationConfig.item
        end
    end
    
    -- Fallback to global required tool
    DebugPrint("Using fallback global tool:", Processing.Settings.RequiredTool)
    return Processing.Settings.RequiredTool
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CORE: GET ITEM WITH FULL METADATA (FIXED - Using Search for slot data)
-- ═══════════════════════════════════════════════════════════════════════════

---Get an item from player inventory with full metadata intact
---Uses ox_inventory:Search to get actual slot data with metadata
---@param source number Player source
---@param itemName string Item name to find
---@return table|nil item Full item object with metadata
---@return number count Total count of this item
---@return number|nil slot Specific slot of the item
function GetItemWithMetadata(source, itemName)
    DebugPrint("GetItemWithMetadata called for:", itemName, "source:", source)
    
    -- Use Search to get actual inventory slot data (includes metadata!)
    -- 'slots' returns full slot objects with metadata
    local slots = exports.ox_inventory:Search(source, 'slots', itemName)
    
    -- Debug: Show what ox_inventory Search returned
    DebugPrint("  → ox_inventory:Search returned type:", type(slots))
    if type(slots) == "table" then
        if slots[1] then
            DebugPrint("  → First slot data:", json.encode(slots[1]))
        else
            DebugPrint("  → Table contents:", json.encode(slots))
        end
    end
    
    -- Handle nil/false/empty returns
    if not slots or slots == false then 
        DebugPrint("  → No items found (nil/false)")
        return nil, 0, nil 
    end
    
    -- Handle empty table
    if type(slots) == "table" and next(slots) == nil then
        DebugPrint("  → No items found (empty table)")
        return nil, 0, nil
    end
    
    -- Search returns array of slot objects
    if type(slots) == "table" and slots[1] then
        local totalCount = 0
        local firstSlotWithMetadata = nil
        
        for _, slotData in ipairs(slots) do
            if type(slotData) == "table" then
                totalCount = totalCount + (slotData.count or 1)
                
                -- Prefer slot with metadata (purity, quality, etc.)
                if not firstSlotWithMetadata then
                    if slotData.metadata and next(slotData.metadata) then
                        firstSlotWithMetadata = slotData
                        DebugPrint("  → Found slot WITH metadata, slot:", slotData.slot)
                    end
                end
            end
        end
        
        -- If no slot had metadata, use first slot
        local selectedSlot = firstSlotWithMetadata or slots[1]
        
        DebugPrint("  → Total count across all slots:", totalCount)
        DebugPrint("  → Selected slot:", selectedSlot.slot)
        if selectedSlot.metadata then
            DebugPrint("  → Metadata:", json.encode(selectedSlot.metadata))
        else
            DebugPrint("  → No metadata on selected slot")
        end
        
        return selectedSlot, totalCount, selectedSlot.slot
    end
    
    -- Handle single slot object (has .slot property)
    if type(slots) == "table" and slots.slot then
        DebugPrint("  → Single slot found, count:", slots.count or 1, "slot:", slots.slot)
        if slots.metadata then
            DebugPrint("  → Metadata:", json.encode(slots.metadata))
        end
        return slots, slots.count or 1, slots.slot
    end
    
    -- Fallback: Try GetItem as backup (for edge cases)
    DebugPrint("  → Search didn't return expected format, trying GetItem fallback...")
    local itemData = exports.ox_inventory:GetItem(source, itemName, nil, false)
    
    if type(itemData) == "table" and itemData.slot then
        DebugPrint("  → GetItem fallback found slot:", itemData.slot)
        return itemData, itemData.count or 1, itemData.slot
    end
    
    -- Last resort: Get count only
    local count = exports.ox_inventory:GetItem(source, itemName, nil, true) or 0
    if count > 0 then
        DebugPrint("  → Found count but no slot data:", count)
        return nil, count, nil
    end
    
    DebugPrint("  → Could not find item:", itemName)
    return nil, 0, nil
end

---Get item count only (for non-metadata items)
---@param source number Player source
---@param itemName string Item name
---@return number count Item count
function GetItemCount(source, itemName)
    local count = exports.ox_inventory:GetItem(source, itemName, nil, true) or 0
    DebugPrint("GetItemCount:", itemName, "=", count)
    return count
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CORE: EXTRACT PRESERVED METADATA
-- ═══════════════════════════════════════════════════════════════════════════

---Extract metadata keys that should be preserved
---@param sourceMetadata table|nil Original item metadata
---@return table metadata Preserved metadata for new items
function ExtractPreservedMetadata(sourceMetadata)
    if not sourceMetadata then return {} end
    
    local preserved = {}
    
    for _, key in ipairs(Processing.Settings.PreserveMetadata) do
        if sourceMetadata[key] ~= nil then
            preserved[key] = sourceMetadata[key]
            DebugPrint("Preserving metadata:", key, "=", tostring(sourceMetadata[key]))
        end
    end
    
    return preserved
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CORE: CHECK RECIPE REQUIREMENTS (STATION-AWARE + LABELS)
-- ═══════════════════════════════════════════════════════════════════════════

---Check if player has all requirements for a recipe
---@param source number Player source
---@param recipeId string Recipe ID
---@param stationType string|nil Station type for tool checking
---@return boolean canCraft Whether player can craft
---@return string|nil reason Reason if cannot craft
---@return table|nil inputItem The input item with metadata
function CheckRecipeRequirements(source, recipeId, stationType, isPlacedStation)
    local recipe = Processing.Recipes[recipeId]
    if not recipe then
        DebugPrint("Recipe not found:", recipeId)
        return false, "Recipe not found", nil
    end
    
    DebugPrint("Checking requirements for recipe:", recipeId, "at station:", stationType or "unknown")
    
    -- Check gang/job restrictions
    local playerGang, gangGrade = GetPlayerGang(source)
    local playerJob, jobGrade = GetPlayerJob(source)
    
    if not Processing.CanUseRecipe(recipeId, playerGang, playerJob, gangGrade, jobGrade) then
        DebugPrint("  → Player doesn't have access to recipe")
        return false, "You don't have access to this recipe", nil
    end
    
    -- Get station-specific required tool
    local requiredTool = GetRequiredToolForStation(stationType)
    local toolLabel = GetItemLabel(requiredTool)
    DebugPrint("  → Required tool:", requiredTool, "(" .. toolLabel .. ")")
    
    -- Check required tool
    -- Check required tool (SKIP for placed stations - the station IS the tool!)
    if not isPlacedStation then
        local toolCount = GetItemCount(source, requiredTool)
        if toolCount < 1 then
            DebugPrint("  → Missing required tool:", requiredTool)
            return false, "You need a " .. toolLabel, nil
        end
        DebugPrint("  → Tool check PASSED:", requiredTool, "count:", toolCount)
    else
        DebugPrint("  → Tool check SKIPPED (placed station)")
    end
    
    -- Check input item WITH metadata
    local inputLabel = GetItemLabel(recipe.input.item)
    local inputItem, inputCount, inputSlot = GetItemWithMetadata(source, recipe.input.item)
    if not inputItem or inputCount < recipe.input.count then
        DebugPrint("  → Not enough input:", recipe.input.item, "have:", inputCount, "need:", recipe.input.count)
        return false, "Not enough " .. inputLabel .. " (need " .. recipe.input.count .. ", have " .. inputCount .. ")", nil
    end
    DebugPrint("  → Input check PASSED:", recipe.input.item, "count:", inputCount)
    
    -- Check containers
    local containerLabel = GetItemLabel(recipe.containers.item)
    local containerCount = GetItemCount(source, recipe.containers.item)
    if containerCount < recipe.containers.count then
        DebugPrint("  → Not enough containers:", recipe.containers.item, "have:", containerCount, "need:", recipe.containers.count)
        return false, "Not enough " .. containerLabel .. " (need " .. recipe.containers.count .. ", have " .. containerCount .. ")", nil
    end
    DebugPrint("  → Container check PASSED:", recipe.containers.item, "count:", containerCount)
    
    DebugPrint("  → ALL CHECKS PASSED for recipe:", recipeId)
    return true, nil, inputItem
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CORE: PROCESS RECIPE WITH METADATA PRESERVATION
-- ═══════════════════════════════════════════════════════════════════════════

---Process a recipe and preserve metadata
---@param source number Player source
---@param recipeId string Recipe ID
---@param stationType string|nil Station type for context
---@return boolean success Whether processing succeeded
---@return string message Result message
function ProcessRecipe(source, recipeId, stationType)
    local recipe = Processing.Recipes[recipeId]
    if not recipe then
        return false, "Invalid recipe"
    end
    
    -- Get isPlacedStation from context (set when menu was opened)
    local isPlacedStation = playerPlacedStationContext[source] or false
    
    DebugPrint("Processing recipe:", recipeId, "at station:", stationType or "unknown", "isPlacedStation:", tostring(isPlacedStation))
    
    -- Check requirements with station context AND placed station flag
    local canCraft, reason, inputItem = CheckRecipeRequirements(source, recipeId, stationType, isPlacedStation)
    if not canCraft then
        return false, reason
    end
    
    -- Verify we have slot information for removal
    if not inputItem or not inputItem.slot then
        DebugPrint("WARNING: No slot info for input item, removal may fail")
    end
    
    -- Extract metadata from input item BEFORE removing
    local preservedMetadata = {}
    
    DebugPrint("Metadata extraction check:")
    DebugPrint("  → recipe.input.metadata:", tostring(recipe.input.metadata))
    DebugPrint("  → inputItem exists:", inputItem ~= nil)
    if inputItem then
        DebugPrint("  → inputItem.metadata exists:", inputItem.metadata ~= nil)
        if inputItem.metadata then
            DebugPrint("  → inputItem.metadata contents:", json.encode(inputItem.metadata))
            DebugPrint("  → inputItem.metadata has values:", next(inputItem.metadata) ~= nil)
        end
    end
    
    -- Try to extract metadata if the recipe wants it AND the item has any
    if recipe.input.metadata then
        if inputItem and inputItem.metadata and next(inputItem.metadata) then
            preservedMetadata = ExtractPreservedMetadata(inputItem.metadata)
            DebugPrint("Extracted metadata:", json.encode(preservedMetadata))
        else
            DebugPrint("Recipe wants metadata but input item has none - checking for purity/quality directly...")
            -- Sometimes metadata might be at a different level, try direct access
            if inputItem then
                if inputItem.purity then
                    preservedMetadata.purity = inputItem.purity
                    DebugPrint("  → Found purity directly on item:", inputItem.purity)
                end
                if inputItem.quality then
                    preservedMetadata.quality = inputItem.quality
                    DebugPrint("  → Found quality directly on item:", inputItem.quality)
                end
            end
        end
    end
    
    DebugPrint("Final preserved metadata:", json.encode(preservedMetadata))
    
    -- Check if output item exists in ox_inventory before proceeding
    local outputItemExists = false
    local outputItemCheck = pcall(function()
        local itemData = exports.ox_inventory:Items(recipe.output.item)
        outputItemExists = itemData ~= nil
    end)
    
    if not outputItemExists then
        DebugPrint("ERROR: Output item does not exist in ox_inventory:", recipe.output.item)
        return false, "Output item '" .. recipe.output.item .. "' not found in inventory system"
    end
    DebugPrint("Output item exists in ox_inventory:", recipe.output.item)
    
    -- Check if player has inventory space (rough estimate)
    local canCarry = exports.ox_inventory:CanCarryItem(source, recipe.output.item, recipe.output.count)
    if not canCarry then
        DebugPrint("ERROR: Player cannot carry output items (inventory full or weight limit)")
        return false, "Not enough inventory space for " .. recipe.output.count .. "x " .. GetItemLabel(recipe.output.item)
    end
    DebugPrint("Player can carry output items")
    
    -- Remove input items (from specific slot to ensure correct item)
    local removeSlot = inputItem and inputItem.slot or nil
    DebugPrint("Removing input:", recipe.input.item, "x", recipe.input.count, "from slot:", removeSlot or "any")
    
    local inputRemoved = exports.ox_inventory:RemoveItem(source, recipe.input.item, recipe.input.count, nil, removeSlot)
    if not inputRemoved then
        DebugPrint("ERROR: Failed to remove input items")
        return false, "Failed to remove input items"
    end
    DebugPrint("Input items removed successfully")
    
    -- Remove containers
    DebugPrint("Removing containers:", recipe.containers.item, "x", recipe.containers.count)
    local containersRemoved = exports.ox_inventory:RemoveItem(source, recipe.containers.item, recipe.containers.count)
    if not containersRemoved then
        DebugPrint("ERROR: Failed to remove containers, refunding input")
        -- Refund input items if container removal fails
        exports.ox_inventory:AddItem(source, recipe.input.item, recipe.input.count, inputItem and inputItem.metadata or nil)
        return false, "Failed to remove containers"
    end
    DebugPrint("Containers removed successfully")
    
    -- Add output items WITH preserved metadata
    DebugPrint("Adding output:", recipe.output.item, "x", recipe.output.count, "with metadata:", json.encode(preservedMetadata))
    
    -- Ensure metadata is a proper table (not empty array)
    local metadataToApply = nil
    if preservedMetadata and next(preservedMetadata) then
        metadataToApply = preservedMetadata
    end
    
    local outputAdded = exports.ox_inventory:AddItem(source, recipe.output.item, recipe.output.count, metadataToApply)
    
    DebugPrint("AddItem result:", type(outputAdded), outputAdded and "success" or "FAILED")
    
    if not outputAdded then
        DebugPrint("ERROR: Failed to add output items, refunding everything")
        -- Refund everything if output fails
        exports.ox_inventory:AddItem(source, recipe.input.item, recipe.input.count, inputItem and inputItem.metadata or nil)
        exports.ox_inventory:AddItem(source, recipe.containers.item, recipe.containers.count)
        return false, "Failed to add output items - check server console for details"
    end
    
    DebugPrint("Output items added successfully!")
    
    -- Log the processing
    local citizenid = GetCitizenId(source)
    Database_Log(nil, citizenid, "process", recipe.category, recipe.output.item, recipe.output.count, nil, {
        recipeId = recipeId,
        stationType = stationType,
        inputItem = recipe.input.item,
        preservedMetadata = preservedMetadata,
    }, nil)
    
    local outputLabel = GetItemLabel(recipe.output.item)
    local metaStr = ""
    if metadataToApply and metadataToApply.purity then
        metaStr = " (Purity: " .. metadataToApply.purity .. "%)"
    end
    
    return true, "Created " .. recipe.output.count .. "x " .. outputLabel .. metaStr
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

---Check if player can use a recipe
lib.callback.register("ogz_propmanager:server:CanUseRecipe", function(source, recipeId, stationType)
    local canCraft, reason, _ = CheckRecipeRequirements(source, recipeId, stationType)
    return canCraft, reason
end)

---Get recipes available for a station
lib.callback.register("ogz_propmanager:server:GetStationRecipes", function(source, stationType, isPlacedStation)
    DebugPrint("========================================")
    DebugPrint("GetStationRecipes called for station:", stationType, "source:", source)
    DebugPrint("  → Is placed station:", tostring(isPlacedStation))
    
    -- Store station context for this player (used by ProcessRecipe)
    playerStationContext[source] = stationType
    playerPlacedStationContext[source] = isPlacedStation or false
    
    -- Check if station type exists
    if not Processing.Stations[stationType] then
        DebugPrint("  → ERROR: Station type not found in Processing.Stations!")
        DebugPrint("  → Available stations:")
        for k, _ in pairs(Processing.Stations) do
            DebugPrint("      -", k)
        end
        return {}
    end
    
    local stationConfig = Processing.Stations[stationType]
    DebugPrint("  → Station config found:", stationConfig.label)
    DebugPrint("  → Allowed categories:", json.encode(stationConfig.allowedCategories))
    
    -- Get recipes for this station
    local recipes = Processing.GetRecipesForStation(stationType)
    
    DebugPrint("  → Recipes found by GetRecipesForStation:")
    local recipeCount = 0
    for k, _ in pairs(recipes) do 
        recipeCount = recipeCount + 1 
        DebugPrint("      -", k)
    end
    DebugPrint("  → Total recipes found:", recipeCount)
    
    -- If no recipes found, debug why
    if recipeCount == 0 then
        DebugPrint("  → DEBUG: Checking all recipes manually...")
        for recipeId, recipe in pairs(Processing.Recipes) do
            DebugPrint("      Recipe:", recipeId, "category:", recipe.category)
            if recipe.stations then
                DebugPrint("        → Has stations restriction:", json.encode(recipe.stations))
                local found = false
                for _, s in ipairs(recipe.stations) do
                    if s == stationType then found = true break end
                end
                DebugPrint("        → Station match:", tostring(found))
            else
                DebugPrint("        → No stations restriction, checking category")
                local catMatch = false
                for _, cat in ipairs(stationConfig.allowedCategories) do
                    if recipe.category == cat then catMatch = true break end
                end
                DebugPrint("        → Category match:", tostring(catMatch))
            end
        end
    end
    
    -- Filter by player permissions
    local playerGang, gangGrade = GetPlayerGang(source)
    local playerJob, jobGrade = GetPlayerJob(source)
    
    local availableRecipes = {}
    for recipeId, recipe in pairs(recipes) do
        if Processing.CanUseRecipe(recipeId, playerGang, playerJob, gangGrade, jobGrade) then
            -- Add availability info WITH station context
            local canCraft, reason, _ = CheckRecipeRequirements(source, recipeId, stationType, isPlacedStation)
            
            -- Get labels for display
            local inputLabel = GetItemLabel(recipe.input.item)
            local outputLabel = GetItemLabel(recipe.output.item)
            local containerLabel = GetItemLabel(recipe.containers.item)
            
            availableRecipes[recipeId] = {
                label = recipe.label,
                category = recipe.category,
                strain = recipe.strain or 'default',  -- v3.2: Include strain for hierarchical menu
                input = {
                    item = recipe.input.item,
                    label = inputLabel,
                    count = recipe.input.count,
                    metadata = recipe.input.metadata,
                },
                containers = {
                    item = recipe.containers.item,
                    label = containerLabel,
                    count = recipe.containers.count,
                },
                output = {
                    item = recipe.output.item,
                    label = outputLabel,
                    count = recipe.output.count,
                },
                time = recipe.time or Processing.Settings.DefaultProcessTime,
                canCraft = canCraft,
                reason = reason,
            }
            DebugPrint("  Recipe:", recipeId, "strain:", recipe.strain or "default", "canCraft:", tostring(canCraft), "reason:", reason or "OK")
        else
            DebugPrint("  Recipe:", recipeId, "SKIPPED (player lacks permission)")
        end
    end
    
    DebugPrint("  → Returning available recipes:")
    local availCount = 0
    for _ in pairs(availableRecipes) do availCount = availCount + 1 end
    DebugPrint("  → Final available count:", availCount)
    DebugPrint("========================================")
    
    return availableRecipes
end)

---Get player's inventory counts for recipe UI
lib.callback.register("ogz_propmanager:server:GetRecipeIngredients", function(source, recipeId)
    local recipe = Processing.Recipes[recipeId]
    if not recipe then return nil end
    
    -- Get station context for accurate tool checking
    local stationType = playerStationContext[source]
    local requiredTool = GetRequiredToolForStation(stationType)
    
    DebugPrint("GetRecipeIngredients for:", recipeId, "station:", stationType or "unknown", "tool:", requiredTool)
    
    local inputItem, inputCount, _ = GetItemWithMetadata(source, recipe.input.item)
    local containerCount = GetItemCount(source, recipe.containers.item)
    local toolCount = GetItemCount(source, requiredTool)
    
    return {
        input = {
            item = recipe.input.item,
            label = GetItemLabel(recipe.input.item),
            have = inputCount,
            need = recipe.input.count,
            metadata = inputItem and inputItem.metadata or nil,
        },
        containers = {
            item = recipe.containers.item,
            label = GetItemLabel(recipe.containers.item),
            have = containerCount,
            need = recipe.containers.count,
        },
        tool = {
            item = requiredTool,
            label = GetItemLabel(requiredTool),
            have = toolCount,
            need = 1,
        },
        output = {
            item = recipe.output.item,
            label = GetItemLabel(recipe.output.item),
            count = recipe.output.count,
        },
    }
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

---Process a recipe
RegisterNetEvent("ogz_propmanager:server:ProcessRecipe", function(recipeId)
    local source = source
    
    -- Get station context
    local stationType = playerStationContext[source]
    DebugPrint("ProcessRecipe event:", recipeId, "station:", stationType or "unknown")
    
    local success, message = ProcessRecipe(source, recipeId, stationType)
    
    if success then
        TriggerClientEvent("ogz_propmanager:client:Notify", source, message, "success")
        TriggerClientEvent("ogz_propmanager:client:ProcessingComplete", source, recipeId, true)
    else
        TriggerClientEvent("ogz_propmanager:client:Notify", source, message, "error")
        TriggerClientEvent("ogz_propmanager:client:ProcessingComplete", source, recipeId, false)
    end
end)

-- Clean up station context when player disconnects
AddEventHandler('playerDropped', function()
    local source = source
    playerStationContext[source] = nil
    playerPlacedStationContext[source] = nil
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- OX_INVENTORY CRAFTING HOOK
-- ═══════════════════════════════════════════════════════════════════════════

if Processing.OxIntegration and Processing.OxIntegration.Enabled then
    
    AddEventHandler('ox_inventory:craftItem', function(source, craftingTable, recipeIndex, recipe)
        local shouldPreserve = false
        for _, tableName in ipairs(Processing.OxIntegration.MetadataTables) do
            if craftingTable == tableName then
                shouldPreserve = true
                break
            end
        end
        
        if not shouldPreserve then return end
        
        if recipe.metadata and recipe.metadata.preserveFrom then
            local sourceItem, _, _ = GetItemWithMetadata(source, recipe.metadata.preserveFrom)
            if sourceItem and sourceItem.metadata then
                local preserved = ExtractPreservedMetadata(sourceItem.metadata)
                
                if not _G.OGz_PendingMetadata then _G.OGz_PendingMetadata = {} end
                _G.OGz_PendingMetadata[source] = preserved
                
                DebugPrint("ox_inventory hook: Captured metadata for preservation:", json.encode(preserved))
            end
        end
    end)
    
    AddEventHandler('ox_inventory:itemCrafted', function(source, item, count)
        if _G.OGz_PendingMetadata and _G.OGz_PendingMetadata[source] then
            local preserved = _G.OGz_PendingMetadata[source]
            _G.OGz_PendingMetadata[source] = nil
            DebugPrint("ox_inventory hook: Would apply metadata:", json.encode(preserved))
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports('GetItemWithMetadata', GetItemWithMetadata)
exports('ExtractPreservedMetadata', ExtractPreservedMetadata)
exports('ProcessRecipe', ProcessRecipe)
exports('CheckRecipeRequirements', CheckRecipeRequirements)
exports('GetRequiredToolForStation', GetRequiredToolForStation)
exports('GetItemLabel', GetItemLabel)

exports('GetOxCraftingRecipes', function()
    local oxRecipes = {}
    
    for recipeId, recipe in pairs(Processing.Recipes) do
        oxRecipes[recipeId] = {
            {
                name = recipe.output.item,
                count = recipe.output.count,
                metadata = { preserveFrom = recipe.input.item },
            },
            {
                name = recipe.input.item,
                count = recipe.input.count,
                remove = true,
            },
            {
                name = recipe.containers.item,
                count = recipe.containers.count,
                remove = true,
            },
        }
    end
    
    return oxRecipes
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- DEBUG COMMANDS (Server-side)
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand("ogz_check_inv", function(source, args)
    if source == 0 then return end
    
    local itemName = args[1]
    if not itemName then
        print("[OGz Processing] Usage: /ogz_check_inv <itemName>")
        return
    end
    
    local item, count, slot = GetItemWithMetadata(source, itemName)
    print("[OGz Processing] Item check for:", itemName)
    print("  Label:", GetItemLabel(itemName))
    print("  Count:", count)
    print("  Slot:", slot or "N/A")
    if item and item.metadata then
        print("  Metadata:", json.encode(item.metadata))
    end
end, false)

RegisterCommand("ogz_debug_recipe", function(source, args)
    if source == 0 then return end
    
    local recipeId = args[1] or "cosmic_kush_gram"
    local stationType = args[2] or "drug_scale"
    
    print("[OGz Processing] Debug recipe:", recipeId, "at station:", stationType)
    
    local canCraft, reason, inputItem = CheckRecipeRequirements(source, recipeId, stationType)
    print("  Can craft:", tostring(canCraft))
    print("  Reason:", reason or "OK")
    if inputItem then
        print("  Input item found with metadata:", json.encode(inputItem.metadata or {}))
    end
end, false)

RegisterCommand("ogz_list_recipes", function(source, args)
    print("[OGz Processing] All registered recipes:")
    for recipeId, recipe in pairs(Processing.Recipes) do
        print(string.format("  - %s [%s] stations: %s", 
            recipeId, 
            recipe.category, 
            recipe.stations and json.encode(recipe.stations) or "ALL"
        ))
    end
end, false)

RegisterCommand("ogz_list_stations", function(source, args)
    print("[OGz Processing] All registered stations:")
    for stationType, config in pairs(Processing.Stations) do
        print(string.format("  - %s (item: %s) categories: %s", 
            stationType, 
            config.item or "none",
            json.encode(config.allowedCategories)
        ))
    end
end, false)

-- ═══════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    Wait(1500)
    
    local recipeCount = 0
    for _ in pairs(Processing.Recipes) do recipeCount = recipeCount + 1 end
    
    local stationCount = 0
    for _ in pairs(Processing.Stations) do stationCount = stationCount + 1 end
    
    print(string.format("^2[OGz PropManager v3.1]^0 Processing system loaded: %d recipes, %d station types", recipeCount, stationCount))
    print("^2[OGz PropManager v3.1]^0 Station-aware tool checking ENABLED")
    
    -- Pre-cache item labels
    DebugPrint("Pre-caching item labels...")
    for _, recipe in pairs(Processing.Recipes) do
        GetItemLabel(recipe.input.item)
        GetItemLabel(recipe.output.item)
        GetItemLabel(recipe.containers.item)
    end
    for _, station in pairs(Processing.Stations) do
        if station.item then GetItemLabel(station.item) end
    end
    DebugPrint("Item label cache ready")
end)
