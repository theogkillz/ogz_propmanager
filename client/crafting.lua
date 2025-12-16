--[[
    OGz PropManager - Crafting Handler
    
    Handles: Durability, Cooldowns, Cooperative Bonus, Random Events
]]

local activeCraftingSessions = {}  -- Track active crafting {propId = sessionData}

-- ═══════════════════════════════════════════════════════════════════════════
-- DURABILITY DISPLAY
-- ═══════════════════════════════════════════════════════════════════════════

---Get durability color based on percentage
function GetDurabilityColor(durability)
    if durability > 74 then return Config.Durability.Colors.good end
    if durability > 24 then return Config.Durability.Colors.warning end
    return Config.Durability.Colors.critical
end

---Format durability for display
function FormatDurability(durability)
    local color = GetDurabilityColor(durability)
    return string.format("Durability: %s%%", durability)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- COOPERATIVE BONUS CALCULATION
-- ═══════════════════════════════════════════════════════════════════════════

---Count nearby gang/job members for coop bonus
---@param propCoords vector3
---@param radius number
---@return number count, number bonusPercent
function CalculateCoopBonus(propCoords, stationConfig)
    if not Config.CoopBonus.Enabled then return 0, 0 end
    if not stationConfig.coopBonus then return 0, 0 end
    
    local coopConfig = stationConfig.coopBonus
    local radius = coopConfig.radius or 5.0
    local speedBonus = coopConfig.speedBonus or 0.15
    local maxBonus = coopConfig.maxBonus or 0.45
    
    local playerPed = PlayerPedId()
    local playerData = GetPlayerData()
    if not playerData then return 0, 0 end
    
    local myGang = playerData.gang and playerData.gang.name
    local myJob = playerData.job and playerData.job.name
    
    local nearbyCount = 0
    local players = GetActivePlayers()
    
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(propCoords - targetCoords)
                
                if distance <= radius then
                    -- Check if same gang/job
                    local serverId = GetPlayerServerId(playerId)
                    local isValid = false
                    
                    -- For simplicity, we count all nearby players
                    -- Server-side validation ensures proper gang/job check
                    nearbyCount = nearbyCount + 1
                end
            end
        end
    end
    
    local totalBonus = math.min(nearbyCount * speedBonus, maxBonus)
    return nearbyCount, totalBonus
end

-- ═══════════════════════════════════════════════════════════════════════════
-- RANDOM EVENT HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

---Roll for random events
---@param stationConfig table
---@param durability number
---@return table|nil eventData
function RollRandomEvent(stationConfig, durability)
    if not Config.Events.Enabled then return nil end
    
    local eventsConfig = lib.load("config/events")
    if not eventsConfig then return nil end
    
    local Events = eventsConfig.Events
    local EventSettings = eventsConfig.EventSettings
    
    -- Calculate durability modifier (lower durability = higher bad event chance)
    local durabilityMod = 1.0
    for _, dm in ipairs(EventSettings.durabilityModifiers) do
        if durability >= dm.threshold then
            durabilityMod = dm.modifier
            break
        end
    end
    
    -- Roll for each event
    for eventId, eventData in pairs(Events) do
        -- Skip based on config
        if eventData.type == "positive" and not Config.Events.PositiveEventsEnabled then goto continue end
        if eventData.type == "negative" and not Config.Events.NegativeEventsEnabled then goto continue end
        if eventData.type == "critical" and not Config.Events.CriticalEventsEnabled then goto continue end
        
        -- Calculate final chance
        local chance = eventData.chance * Config.Events.GlobalChanceMultiplier
        if eventData.type == "negative" or eventData.type == "critical" then
            chance = chance * durabilityMod
        end
        
        -- Roll
        if math.random() < chance then
            eventData.id = eventId
            return eventData
        end
        
        ::continue::
    end
    
    return nil
end

---Apply event effects
---@param event table
---@param propId number
function ApplyEventEffects(event, propId, propData)
    if not event then return end
    
    local effects = event.effects
    
    -- Play notification
    if event.notification and EventSettings.showNotifications then
        Notify(event.notification.message, event.notification.type)
    end
    
    -- Play sound
    if event.sound and Config.Sounds.Enabled then
        PlayEventSound(event.sound)
    end
    
    -- Play particle
    if event.particle and Config.Particles.UseOnEvents then
        local coords = propData.coords
        PlayParticle(event.particle.dict, event.particle.name, coords, event.particle.duration)
    end
    
    -- Apply durability change (server-side)
    if effects.durabilityChange and effects.durabilityChange ~= 0 then
        TriggerServerEvent("ogz_propmanager:server:ModifyDurability", propId, effects.durabilityChange)
    end
    
    -- Explosion effect
    if effects.explosion then
        local coords = propData.coords
        AddExplosion(coords.x, coords.y, coords.z, 2, 0.1, true, false, 0.5)
    end
    
    -- Police alert (server-side)
    if effects.alertPolice then
        TriggerServerEvent("ogz_propmanager:server:AlertPolice", propId, propData)
    end
    
    -- Log event
    TriggerServerEvent("ogz_propmanager:server:LogEvent", propId, event.id, event.label)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PARTICLE EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════

---Play particle effect at location
function PlayParticle(dict, name, coords, duration)
    if not Config.Particles.Enabled then return end
    
    RequestNamedPtfxAsset(dict)
    while not HasNamedPtfxAssetLoaded(dict) do Wait(10) end
    
    UseParticleFxAssetNextCall(dict)
    local particle = StartParticleFxLoopedAtCoord(name, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    
    if duration then
        SetTimeout(duration, function()
            StopParticleFxLooped(particle, false)
        end)
    end
    
    return particle
end

-- ═══════════════════════════════════════════════════════════════════════════
-- SOUND EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════

local activeSound = nil

---Play sound from sounds.lua config
function PlaySound(soundKey, coords)
    if not Config.Sounds.Enabled then return end
    
    local soundsConfig = lib.load("config/sounds")
    if not soundsConfig then return end
    
    local soundData = soundsConfig[soundKey]
    if not soundData then return end
    
    if soundData.type == "native" then
        PlaySoundFromCoord(-1, soundData.sound, coords.x, coords.y, coords.z, soundData.soundSet, false, soundData.range or 10.0, false)
    end
end

---Play looping sound
function PlayLoopingSound(soundKey, coords)
    StopLoopingSound()
    
    if not Config.Sounds.Enabled then return end
    
    local soundsConfig = lib.load("config/sounds")
    if not soundsConfig then return end
    
    local soundData = soundsConfig[soundKey]
    if not soundData or not soundData.loop then return end
    
    -- For native sounds, we'll use a workaround
    activeSound = {
        key = soundKey,
        coords = coords,
        active = true
    }
    
    CreateThread(function()
        while activeSound and activeSound.active and activeSound.key == soundKey do
            PlaySoundFromCoord(-1, soundData.sound, coords.x, coords.y, coords.z, soundData.soundSet, false, soundData.range or 10.0, false)
            Wait(3000)  -- Repeat every 3 seconds for ambient
        end
    end)
end

---Stop looping sound
function StopLoopingSound()
    if activeSound then
        activeSound.active = false
        activeSound = nil
    end
end

---Play event sound (one-shot)
function PlayEventSound(soundKey)
    local playerCoords = GetEntityCoords(PlayerPedId())
    PlaySound(soundKey, playerCoords)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- PRE-CRAFT CHECKS
-- ═══════════════════════════════════════════════════════════════════════════

---Perform all pre-craft checks
---@param propId number
---@param propData table
---@param stationConfig table
---@return boolean canCraft, string|nil reason
function PreCraftChecks(propId, propData, stationConfig)
    -- Check durability
    if Config.Durability.Enabled and Config.Durability.BreakAtZero then
        local durability = propData.durability or 100
        if durability <= 0 then
            return false, Config.Notifications.DurabilityBroken
        end
        
        -- Warn if low
        if durability <= Config.Durability.WarnAtPercent then
            Notify(string.format(Config.Notifications.DurabilityLow, durability), "warning")
        end
    end
    
    -- Check cooldown (server-side check)
    -- This is handled via callback before opening menu
    
    return true, nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CRAFTING SESSION MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════

---Start a crafting session
function StartCraftingSession(propId, entity, propData, stationConfig)
    local propCoords = vector3(propData.coords.x, propData.coords.y, propData.coords.z)
    
    -- Calculate coop bonus
    local coopCount, coopBonus = CalculateCoopBonus(propCoords, stationConfig)
    
    if coopCount > 0 and Config.CoopBonus.BonusNotification then
        Notify(string.format(Config.Notifications.CoopBonusActive, math.floor(coopBonus * 100)), "success")
    end
    
    activeCraftingSessions[propId] = {
        entity = entity,
        propData = propData,
        stationConfig = stationConfig,
        coopCount = coopCount,
        coopBonus = coopBonus,
        startTime = GetGameTimer(),
    }
    
    -- Play ON state sound
    if stationConfig.modelStates and stationConfig.modelStates.on then
        local onState = stationConfig.modelStates.on
        if onState.sound then
            PlayLoopingSound(onState.sound, propCoords)
        end
    end
    
    return coopBonus
end

---End a crafting session
function EndCraftingSession(propId)
    local session = activeCraftingSessions[propId]
    if not session then return end
    
    StopLoopingSound()
    activeCraftingSessions[propId] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- CRAFT COMPLETION HANDLER
-- ═══════════════════════════════════════════════════════════════════════════

---Called when a craft is about to complete
function OnCraftComplete(propId, itemName, quantity)
    local session = activeCraftingSessions[propId]
    if not session then return quantity, false end
    
    -- Roll for random event
    local event = RollRandomEvent(session.stationConfig, session.propData.durability or 100)
    
    if event then
        ApplyEventEffects(event, propId, session.propData)
        
        -- Modify output based on event
        if event.effects then
            if event.effects.failCraft then
                return 0, event.effects.loseInputs
            end
            if event.effects.outputMultiplier then
                quantity = math.floor(quantity * event.effects.outputMultiplier)
            end
        end
    end
    
    -- Notify server to reduce durability and increment craft count
    TriggerServerEvent("ogz_propmanager:server:OnCraftComplete", propId, itemName, quantity)
    
    return quantity, false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Update durability display
RegisterNetEvent("ogz_propmanager:client:UpdateDurability", function(propId, newDurability)
    local props = exports.ogz_propmanager:GetPlacedProps()
    if props[propId] then
        props[propId].data.durability = newDurability
    end
end)

-- Refresh all durability values
RegisterNetEvent("ogz_propmanager:client:RefreshAllDurability", function()
    -- Request fresh data from server
    TriggerServerEvent("ogz_propmanager:server:RequestProps", GetCurrentBucket())
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════

exports("PreCraftChecks", PreCraftChecks)
exports("StartCraftingSession", StartCraftingSession)
exports("EndCraftingSession", EndCraftingSession)
exports("OnCraftComplete", OnCraftComplete)
exports("CalculateCoopBonus", CalculateCoopBonus)
exports("GetDurabilityColor", GetDurabilityColor)
