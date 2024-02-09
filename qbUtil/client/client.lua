local RotationToDirection = function(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local RayCastGamePlayCamera = function(distance)
    -- Checks to see if the Gameplay Cam is Rendering or another is rendering (no clip functionality)
    local currentRenderingCam = false
    if not IsGameplayCamRendering() then
        currentRenderingCam = GetRenderingCam()
    end

    local cameraRotation = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
    local cameraCoord = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, b, c, _, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination
        .x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

--- @return number FreeAimEntity
function raycast()
    EntityViewEnabled = true
    if EntityViewEnabled then
        while EntityViewEnabled do
            Citizen.Wait(1)
            local playerPed = PlayerPedId()

            local color = { r = 255, g = 255, b = 255, a = 200 }
            local position = GetEntityCoords(playerPed)
            local hit, coords, entity = RayCastGamePlayCamera(1000.0)
            if hit and (IsEntityAVehicle(entity) or IsEntityAPed(entity)) then
                color = { r = 0, g = 255, b = 0, a = 200 }

                -- Press 'E' to choose entity
                if IsControlJustReleased(0, 38) then
                    EntityViewEnabled = false
                    return entity
                end
            else
                FreeAimEntity = nil
            end

            DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, color.r, color.g, color.b,
                color.a)
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r,
                color.g, color.b, color.a, false, true, 2, nil, nil, false, false)

            if IsControlJustReleased(0, 38) then -- Cancel
                EntityViewEnabled = false
                return 0
            end
        end
    end
end

exports('raycast', raycast)
