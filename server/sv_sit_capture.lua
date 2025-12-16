--[[
    OGz Sit Capture - SERVER
    Receives data and prints to server console
]]

RegisterNetEvent("ogz_capture:print", function(data)
    local src = source
    local name = GetPlayerName(src) or "Unknown"
    
    print("")
    print("^2═══════════════════════════════════════════════════════════════^0")
    print("^2[OGz CAPTURE] Player: " .. name .. "^0")
    print("^2═══════════════════════════════════════════════════════════════^0")
    print("")
    print(string.format("^3PLAYER POSITION:^0 %.3f, %.3f, %.3f", data.playerX, data.playerY, data.playerZ))
    print(string.format("^3PLAYER HEADING:^0 %.1f", data.playerH))
    print("")
    
    if data.found then
        print(string.format("^3CHAIR POSITION:^0 %.3f, %.3f, %.3f", data.chairX, data.chairY, data.chairZ))
        print(string.format("^3CHAIR HEADING:^0 %.1f", data.chairH))
        print(string.format("^3CHAIR MODEL:^0 %d", data.model))
        print("")
        print("^2═══════════════════════════════════════════════════════════════^0")
        print("^2CALCULATED OFFSET:^0")
        print("^2═══════════════════════════════════════════════════════════════^0")
        print("")
        print(string.format("    offset = vec3(%.3f, %.3f, %.3f),", data.offX, data.offY, data.offZ))
        print(string.format("    heading = %.1f,", data.offH))
        print("")
    else
        print("^1NO CHAIR FOUND WITHIN 2 METERS^0")
    end
    
    print("^2═══════════════════════════════════════════════════════════════^0")
    print("")
end)

RegisterNetEvent("ogz_capture:simple", function(x, y, z, h)
    local src = source
    local name = GetPlayerName(src) or "Unknown"
    
    print("")
    print(string.format("^2[OGz CAPTURE]^0 %s | Pos: %.3f, %.3f, %.3f | Heading: %.1f", name, x, y, z, h))
    print("")
end)

print("^2[OGz Capture]^0 Server capture ready - Use /sit_capture or /sit_info")
