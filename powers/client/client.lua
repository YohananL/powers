--- ============================
---           Constants
--- ============================

local playerPed = PlayerPedId()

local pointAnimation = { name = 'task_mp_pointing', dictionary = 'anim@mp_point', }

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

--- Push
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
    local z = 0.0

    -- Get player's heading
    local heading = GetEntityHeading(playerPed)

    local mainMultiplier, subMultiplier = getMutlipliers(heading)

    if heading <= 180 then
        if heading <= 90 then
            -- North West
            if heading <= 45 then
                y = y + subMultiplier
                x = x - mainMultiplier
            else
                y = y + subMultiplier
                x = x - mainMultiplier
            end
        else
            -- South West
            if heading <= 135 then
                x = x - subMultiplier
                y = y - mainMultiplier
            else
                x = x - subMultiplier
                y = y - mainMultiplier
            end
        end
    else
        if heading <= 270 then
            -- South East
            if heading <= 225 then
                x = x + mainMultiplier
                y = y - subMultiplier
            else
                x = x + mainMultiplier
                y = y - subMultiplier
            end
        else
            -- North East
            if heading <= 315 then
                x = x + subMultiplier
                y = y + mainMultiplier
            else
                x = x + subMultiplier
                y = y + mainMultiplier
            end
        end
    end

    -- Set ped to invincible first
    SetEntityInvincible(ped, true)

    -- Set ragdoll
    SetPedToRagdoll(ped, 3000, 3000, 0, false, false, false)

    -- Set velocity
    SetEntityVelocity(ped,
        x,
        y,
        z + Config.Settings.velocity / 2)

    -- Wait for ped to come down
    while IsEntityInAir(ped) do
        Wait(500)
    end

    -- Make ped not invincible anymore
    SetEntityInvincible(ped, false)
end, false)


-- local dictionary = 'missheist_agency2ahands_up'
-- local name = 'handsup_loop'
-- local dictionary = 'mp_am_hold_up'
-- local name = 'guard_handsup_loop'
local dictionary = 'mp_missheist_countrybank@cower'
local name = 'cower_loop'

local frozenEntity

--- Freeze
RegisterKeyMapping('+freeze', 'Freeze', 'keyboard', Config.Settings.freezeBind)
RegisterCommand('+freeze', function()
    -- Get entity in front of player using raycast
    frozenEntity = GetEntInFrontOfPlayer(playerPed, 5.0)

    -- Freeze entity
    FreezeEntityPosition(frozenEntity, true)

    -- If human
    if GetEntityType(frozenEntity) == 1 then
        RequestAnimDict(dictionary)
        repeat
            Wait(100)
        until HasAnimDictLoaded(dictionary)

        ClearPedTasksImmediately(frozenEntity)

        TaskPlayAnim(frozenEntity, dictionary, name,
            8.0, 8.0, -1, 1, 1.0, false, false, false)
    end
end, false)

RegisterCommand('-freeze', function()
    -- Unfreeze entity
    FreezeEntityPosition(frozenEntity, false)

    StopAnimTask(frozenEntity, dictionary, name, 1.0)
end, false)
