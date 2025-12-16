--[[
    OGz Sit Capture - CLIENT
    Sends data to server for console output
]]

RegisterCommand("sit_capture", function()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local pHeading = GetEntityHeading(ped)
    
    -- Find nearest chair
    local nearest = nil
    local nearDist = 999
    
    for _, obj in ipairs(GetGamePool("CObject")) do
        if DoesEntityExist(obj) then
            local dist = #(pCoords - GetEntityCoords(obj))
            if dist < 2.0 and dist < nearDist then
                nearest = obj
                nearDist = dist
            end
        end
    end
    
    local data = {
        playerX = pCoords.x,
        playerY = pCoords.y,
        playerZ = pCoords.z,
        playerH = pHeading,
        found = nearest ~= nil,
    }
    
    if nearest then
        local cCoords = GetEntityCoords(nearest)
        local cHeading = GetEntityHeading(nearest)
        
        data.chairX = cCoords.x
        data.chairY = cCoords.y
        data.chairZ = cCoords.z
        data.chairH = cHeading
        data.model = GetEntityModel(nearest)
        
        -- Calculate offsets
        data.offX = pCoords.x - cCoords.x
        data.offY = pCoords.y - cCoords.y
        data.offZ = pCoords.z - cCoords.z
        data.offH = pHeading - cHeading
    end
    
    -- Send to server
    TriggerServerEvent("ogz_capture:print", data)
end, false)

RegisterCommand("sit_info", function()
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local pHeading = GetEntityHeading(ped)
    
    TriggerServerEvent("ogz_capture:simple", pCoords.x, pCoords.y, pCoords.z, pHeading)
end, false)
