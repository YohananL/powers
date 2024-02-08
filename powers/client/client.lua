--- ============================
---           Constants
--- ============================

local playerPed = PlayerPedId()

--- ============================
---           Helpers
--- ============================

local function GetEntInFrontOfPlayer(Ped, Distance)
    local Ent = nil
    local CoA = GetEntityCoords(Ped, true)
    local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, Distance, 0.0)
    local RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoA.x, CoA.y, CoA.z, CoB.x, CoB.y, CoB.z, 10, Ped, 0)
    local A, B, C, D, Ent = GetRaycastResult(RayHandle)
    return Ent
end

--- ============================
---          Functions
--- ============================

function getMutlipliers(currentHeading)
    local remainder
    if currentHeading ~= 0 then
        remainder = math.fmod(currentHeading, 90)
        if remainder == 0 then
            remainder = 90
        end
    end

    local ratio = remainder / 90
    local inverseRatio = 1 - ratio
    local mainMultiplier = Config.Settings.velocity * ratio
    local subMultiplier = Config.Settings.velocity * inverseRatio

    return mainMultiplier, subMultiplier
end

--- ============================
---            Push
--- ============================

RegisterKeyMapping('+push', 'Push', 'keyboard', Config.Settings.pushBind)
RegisterCommand('+push', function()
    -- Get ped in front of player using raycast
    local ped = GetEntInFrontOfPlayer(playerPed, 5.0)

    if GetEntityType(ped) ~= 1 then
        return
    end

    -- Get ped's current velocity
    local x = 0.0
    local y = 0.0
    local z = Config.Settings.velocity

    -- Get player's heading
    local heading = GetEntityHeading(playerPed)

    local mainMultiplier, subMultiplier = getMutlipliers(heading)

    if heading <= 180 then
        if heading <= 90 then
            -- North West
            x = x - mainMultiplier
            y = y + subMultiplier
        else
            -- South West
            x = x - subMultiplier
            y = y - mainMultiplier
        end
    else
        if heading <= 270 then
            -- South East
            x = x + mainMultiplier
            y = y - subMultiplier
        else
            -- North East
            x = x + subMultiplier
            y = y + mainMultiplier
        end
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)

    -- Set ped to ragdoll
    TriggerServerEvent('powers:server:setpedtoragdoll', netId)

    -- Set ped to invincible
    SetEntityInvincible(ped, true)

    -- Set velocity on client and server
    SetEntityVelocity(ped, x, y, z)

    -- Set ped velocity
    TriggerServerEvent('powers:server:push', netId, x, y, z)
    Wait(1000)

    -- Wait until the ped stops moving and is no longer in the air
    repeat
        Wait(500)
    until GetEntitySpeed(ped) == 0
    while IsEntityInAir(ped) do
        Wait(500)
    end

    -- Revert invincible
    SetEntityInvincible(ped, false)

    -- OOF
    TriggerEvent('QBCore:Notify', 'Oof...', 'success',
        2500)
end, false)


--- ============================
---           Freeze
--- ============================

local frozenEntity
local dictionary = 'nm@hands'
local name = 'hands_up'

RegisterKeyMapping('+freeze', 'Freeze', 'keyboard', Config.Settings.freezeBind)
RegisterCommand('+freeze', function()
    -- Get entity in front of player using raycast
    frozenEntity = GetEntInFrontOfPlayer(playerPed, 5.0)

    -- Freeze entity
    FreezeEntityPosition(frozenEntity, true)

    -- If human
    if GetEntityType(frozenEntity) == 1 then
        ClearPedTasksImmediately(frozenEntity)

        RequestAnimDict(dictionary)
        repeat
            Wait(100)
        until HasAnimDictLoaded(dictionary)

        local x, y, z = table.unpack(GetEntityCoords(frozenEntity))
        local rotX, rotY, rotZ = table.unpack(GetEntityRotation(frozenEntity))

        TaskPlayAnimAdvanced(frozenEntity, dictionary, name,
            x, y, z + 0.5, rotX, rotY, rotZ,
            8.0, 8.0, -1, 2, 1.0, false, false)
    end
end, false)

RegisterCommand('-freeze', function()
    -- Unfreeze entity
    FreezeEntityPosition(frozenEntity, false)
    StopAnimTask(frozenEntity, dictionary, name, 1.0)
end, false)
