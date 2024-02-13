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
    local remainder = 0
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

function getPushVelocity(entity)
    local x = 0.0
    local y = 0.0
    local z = Config.Settings.velocity

    -- Get heading the entity is facing
    local heading = GetEntityHeading(entity)

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

    return vec3(x, y, z)
end

--- ============================
---            Push
--- ============================

RegisterKeyMapping('+pushEntity', 'Push', 'keyboard', Config.Settings.pushBind)
RegisterCommand('+pushEntity', function()
    local playerPed = PlayerPedId()
    local ped = exports.qbUtil:raycast()

    -- If raycast entity is not a number, stop
    local raycastType = tostring(type(ped))
    if raycastType ~= 'number' then
        return
    end

    -- If not a ped or a vehicle, stop
    local type = GetEntityType(ped)
    if type ~= 1 and type ~= 2 then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)

    -- Set ped to ragdoll
    TriggerServerEvent('powers:server:setpedtoragdoll', netId)

    -- Set ped to invincible
    SetEntityInvincible(ped, true)

    -- Get the push force velocity
    local x, y, z = table.unpack(getPushVelocity(playerPed))

    -- Set ped velocity
    TriggerServerEvent('powers:server:push', netId, x, y, z)

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
local frozenEntity = nil
local dictionary = 'nm@hands'
local name = 'hands_up'
-- local dictionary = 'skydive@base'
-- local name = 'free_idle'

RegisterKeyMapping('+freezeEntity', 'Freeze', 'keyboard', Config.Settings.freezeBind)
RegisterCommand('+freezeEntity', function()
    local playerPed = PlayerPedId()

    -- Get entity in front of player using raycast
    frozenEntity = GetEntInFrontOfPlayer(playerPed, 10.0)
    -- frozenEntity = exports.qbUtil:raycast()

    -- If not a number, stop
    if tostring(type(frozenEntity)) ~= 'number' then
        frozenEntity = nil
        return
    end

    -- Freeze entity
    FreezeEntityPosition(frozenEntity, true)

    -- If ped
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

RegisterCommand('-freezeEntity', function()
    -- Do nothing if no frozen entity
    if frozenEntity == nil then
        return
    end

    -- Unfreeze entity
    FreezeEntityPosition(frozenEntity, false)
    StopAnimTask(frozenEntity, dictionary, name, 1.0)
end, false)

--- ============================
---         Super Jump
--- ============================

local superJumpEnabled = false

RegisterCommand('superJump', function()
    local playerId = PlayerId()
    local playerPed = PlayerPedId()

    local grenadeType = 50 -- EXP_TAG_BOMB_STANDARD

    superJumpEnabled = not superJumpEnabled

    CreateThread(function()
        SetPlayerInvincible(playerId, true)

        while superJumpEnabled do
            -- If 'spacebar' is pressed and moving, add height to the jump
            if IsControlJustPressed(0, 22) and GetEntitySpeed(playerPed) > 1 then
                -- Get the jump force velocity
                local x, y, z = table.unpack(getPushVelocity(playerPed))
                SetEntityVelocity(playerPed, x, y, z)

                if not IsEntityInAir(playerPed) then
                    local coords = GetEntityCoords(playerPed)
                    AddExplosion(coords.x, coords.y, coords.z, grenadeType, 0, true, false, 0, true)
                end
            end

            -- If up arrow key is pressed and in air, add forward velocity
            if IsControlJustPressed(0, 172) and IsEntityInAir(playerPed) then
                local originalZ = GetEntityVelocity(playerPed).z
                local x, y, _ = table.unpack(getPushVelocity(playerPed))
                SetEntityVelocity(playerPed, x, y, originalZ)
            end

            if not GetIsPedGadgetEquipped(playerPed, GetHashKey("gadget_parachute")) then
                if IsEntityInAir(playerPed) then
                    GiveWeaponToPed(playerPed, GetHashKey("gadget_parachute"), 1, false, false)
                end
            end

            Wait(0)
        end

        SetPlayerInvincible(playerId, false)
    end)
end, false)

--- ============================
---          Flame On
--- ============================

local flameOnEnabled = false

RegisterCommand('flameOn', function()
    local playerPed = PlayerPedId()

    local grenadeType = 3 -- MOLOTOV

    flameOnEnabled = not flameOnEnabled

    CreateThread(function()
        StartEntityFire(playerPed)
        while flameOnEnabled do
            -- StartScriptFire(coords.x, coords.y, coords.z, 1, false)
            SetEntityHealth(playerPed, 200)
            Wait(1)
        end
        StopEntityFire(playerPed)
    end)

    CreateThread(function()
        local coords
        while flameOnEnabled do
            coords = GetEntityCoords(playerPed)
            AddExplosion(coords.x, coords.y, coords.z, grenadeType, 1.0, false, false, 0, false)
            Wait(5000)
        end
        StopFireInRange(coords.x, coords.y, coords.z, 50.0)
    end)
end, false)

--- ============================
---          The Crow
--- ============================

local AnimationFlags =
{
    ANIM_FLAG_NORMAL = 0,
    ANIM_FLAG_REPEAT = 1,
    ANIM_FLAG_STOP_LAST_FRAME = 2,
};

local CrowAnimations = {
    takeoff  = { name = 'takeoff', dictionary = 'creatures@crow@move', flag = AnimationFlags.ANIM_FLAG_STOP_LAST_FRAME },
    land     = { name = 'land', dictionary = 'creatures@crow@move', flag = AnimationFlags.ANIM_FLAG_STOP_LAST_FRAME },
    ascend   = { name = 'ascend', dictionary = 'creatures@crow@move', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    descend  = { name = 'descend', dictionary = 'creatures@crow@move', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    flapping = { name = 'flapping', dictionary = 'creatures@crow@move', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    glide    = { name = 'glide', dictionary = 'creatures@crow@move', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    idle     = { name = 'idle', dictionary = 'creatures@crow@move', flag = AnimationFlags.ANIM_FLAG_REPEAT },
}

function requestAnimation(dictionary)
    RequestAnimDict(dictionary)
    repeat
        Wait(100)
    until HasAnimDictLoaded(dictionary)

    return true
end

function unloadCrowAnimations()
    for _, value in pairs(CrowAnimations) do
        RemoveAnimDict(value.dictionary)
    end
end

function loadCrowAnimations()
    for _, value in pairs(CrowAnimations) do
        if not (HasAnimDictLoaded(value.dictionary)) then
            requestAnimation(value.dictionary)
        end
    end
end

function loadModel(modelHash)
    -- Request the model and wait for it to load
    RequestModel(modelHash)
    repeat
        Wait(100)
    until HasModelLoaded(modelHash)
end

---  @class Crow
local Crow = {
    ped = nil,
    isPerched = true,
    isGliding = false,
    switchFlyTick = 0,
    switchFlyTickMax = 5,

    -- Idle offsets and rotation
    idleX = -0.05,
    idleY = -0.05,
    idleZ = 0.0,
    rotX = 0.0,
    rotY = -120.0,
    rotZ = -15.0,

    -- Flapping offsets
    flapStartX = -0.15,
    flapStartY = -0.10,
    flapStartZ = 0.475,
    flapEndBaseX = -0.90,
    flapEndBaseY = -0.90,
    flapEndBaseZ = 0.90,
}

function Crow:createCrow(playerPed)
    local crowHash = `A_C_Crow`

    -- Load the model
    loadModel(crowHash)

    -- Create the object
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local newCrowPed = CreatePed(0, crowHash, coords.x, coords.y, coords.z + -50, heading, true, false)

    -- Release the model
    SetModelAsNoLongerNeeded(crowHash)

    return newCrowPed
end

function Crow:descend(playerPed, descendTicks, flapOffsetMultiplier)
    local flapEndX = Crow.flapEndBaseX * flapOffsetMultiplier
    local flapEndY = Crow.flapEndBaseY * flapOffsetMultiplier
    local flapEndZ = Crow.flapEndBaseZ * flapOffsetMultiplier

    -- Flapping offset increments
    local flapIncrementX = (flapEndX - Crow.flapStartX) / descendTicks
    local flapIncrementY = (flapEndY - Crow.flapStartY) / descendTicks
    local flapIncrementZ = (flapEndZ - Crow.flapStartZ) / descendTicks

    -- Make crow do descend animation
    TaskPlayAnim(Crow.ped, CrowAnimations.descend.dictionary, CrowAnimations.descend.name,
        8.0, 8.0, -1, CrowAnimations.descend.flag, 0.0, false, false, false)

    local x = flapEndX
    local y = flapEndY
    local z = flapEndZ
    repeat
        x = x - flapIncrementX
        y = y - flapIncrementY
        z = z - flapIncrementZ

        AttachEntityToEntity(Crow.ped, playerPed, -1,
            x, y, z,
            0, 0, 0, false, false, false, true, 2, true)

        Wait(1)
    until x >= Crow.flapStartX and y >= Crow.flapStartY and z <= Crow.flapStartZ

    -- Make crow do land animation
    local animTime = GetAnimDuration(CrowAnimations.land.dictionary,
        CrowAnimations.land.name)
    TaskPlayAnim(Crow.ped, CrowAnimations.land.dictionary, CrowAnimations.land.name,
        8.0, 8.0, -1, CrowAnimations.land.flag, 0.0, false, false, false)

    Wait(animTime * 1000)

    -- Make crow do idle animation
    TaskPlayAnim(Crow.ped, CrowAnimations.idle.dictionary, CrowAnimations.idle.name,
        8.0, 8.0, -1, CrowAnimations.idle.flag, 0.0, false, false, false)

    -- Detach before re-attaching
    DetachEntity(Crow.ped, false, false)

    -- Get bone index
    local boneIndex = 40 -- Left shoulder bone

    -- Attach crow ped to player's shoulder
    AttachEntityToEntity(Crow.ped, playerPed, boneIndex,
        Crow.idleX, Crow.idleY, Crow.idleZ,
        Crow.rotX, Crow.rotY, Crow.rotZ, false, false, false, true, 2, true)

    Crow.isPerched = true
end

function Crow:ascend(playerPed, ascendTicks, flapOffsetMultiplier, isExit)
    -- Flapping offset increments
    local flapIncrementX = (Crow.flapEndBaseX * flapOffsetMultiplier - Crow.flapStartX) / ascendTicks
    local flapIncrementY = (Crow.flapEndBaseY * flapOffsetMultiplier - Crow.flapStartY) / ascendTicks
    local flapIncrementZ = (Crow.flapEndBaseZ * flapOffsetMultiplier - Crow.flapStartZ) / ascendTicks

    -- Make crow do fly animation
    TaskPlayAnim(Crow.ped, CrowAnimations.takeoff.dictionary, CrowAnimations.takeoff.name,
        8.0, 8.0, -1, CrowAnimations.takeoff.flag, 0.0, false, false, false)

    local x = Crow.flapStartX
    local y = Crow.flapStartY
    local z = Crow.flapStartZ

    if isExit then
        repeat
            x = x + flapIncrementX
            y = y - flapIncrementY
            z = z + flapIncrementZ

            AttachEntityToEntity(Crow.ped, playerPed, -1,
                x, y, z,
                0, 0, 0, false, false, false, true, 2, true)

            Wait(1)
        until z >= Crow.flapEndBaseZ
    else
        repeat
            x = x + flapIncrementX
            y = y + flapIncrementY
            z = z + flapIncrementZ

            AttachEntityToEntity(Crow.ped, playerPed, -1,
                x, y, z,
                0, 0, 0, false, false, false, true, 2, true)

            Wait(1)
        until x <= Crow.flapEndBaseX and y <= Crow.flapEndBaseY and z >= Crow.flapEndBaseZ
    end

    -- Make crow do ascend animation
    TaskPlayAnim(Crow.ped, CrowAnimations.ascend.dictionary, CrowAnimations.ascend.name,
        8.0, 8.0, -1, CrowAnimations.ascend.flag, 0.0, false, false, false)

    if isExit then
        repeat
            x = x + flapIncrementX
            y = y - flapIncrementY
            z = z + flapIncrementZ

            AttachEntityToEntity(Crow.ped, playerPed, -1,
                x, y, z,
                0, 0, 0, false, false, false, true, 2, true)

            Wait(1)
        until z >= Crow.flapEndBaseZ * 10
    else
        Wait(GetAnimDuration(CrowAnimations.ascend.dictionary,
            CrowAnimations.ascend.name) * 1000)
    end

    -- Detach before re-attaching
    DetachEntity(Crow.ped, false, false)

    if not isExit then
        -- Make crow do fly animation
        TaskPlayAnim(Crow.ped, CrowAnimations.flapping.dictionary, CrowAnimations.flapping.name,
            8.0, 8.0, -1, CrowAnimations.flapping.flag, 0.0, false, false, false)

        -- Attach crow ped behind player, don't attach to bone for better looking animation
        AttachEntityToEntity(Crow.ped, playerPed, -1,
            Crow.flapEndBaseX, Crow.flapEndBaseY, Crow.flapEndBaseZ,
            0, 0, 0, false, false, false, true, 2, true)
    end

    Crow.isPerched = false
    Crow.switchFlyTick = 0
end

function Crow:switchFlyAnimation()
    if Crow.switchFlyTick == Crow.switchFlyTickMax then
        if Crow.isGliding then
            TaskPlayAnim(Crow.ped, CrowAnimations.flapping.dictionary, CrowAnimations.flapping.name,
                8.0, 8.0, -1, CrowAnimations.flapping.flag, 0.0, false, false, false)
        else
            TaskPlayAnim(Crow.ped, CrowAnimations.glide.dictionary, CrowAnimations.glide.name,
                8.0, 8.0, -1, CrowAnimations.glide.flag, 0.0, false, false, false)
        end

        Crow.isGliding = not Crow.isGliding
        Crow.switchFlyTick = 0
    end
end

RegisterCommand('theCrow', function()
    local playerPed = PlayerPedId()

    -- Load crow animations
    loadCrowAnimations()

    -- Crow already exists, remove
    if Crow.ped ~= nil then
        -- Make crow fly away
        Crow:ascend(playerPed, 400, 10.0, true)

        -- Delete
        DeleteEntity(Crow.ped)
        Crow.ped = nil
        return
    end

    -- Create crow ped
    Crow.ped = Crow:createCrow(playerPed)

    -- Add crow to group
    local playerGroup = GetPedGroupIndex(playerPed)
    SetPedAsGroupMember(Crow.ped, playerGroup)

    -- Entrance from above
    Crow:descend(playerPed, 400, 10.0)

    -- Thread to check player speed and change crow animation
    CreateThread(function()
        while Crow.ped ~= nil do
            if GetEntitySpeed(playerPed) <= 3 then
                if not Crow.isPerched then
                    -- Make crow perch to player's shoulder
                    Crow:descend(playerPed, 200, 1.0)
                end
            else
                if Crow.isPerched then
                    -- Make crow fly around player's side
                    Crow:ascend(playerPed, 200, 1.0, false)
                else
                    -- Toggle between flying/gliding animation
                    Crow:switchFlyAnimation()
                end
            end

            -- Increase
            Crow.switchFlyTick = Crow.switchFlyTick + 1
            Wait(500)
        end

        -- Unload crow animations
        unloadCrowAnimations()
    end)
end, false)

--- ============================
---            Money
--- ============================
RegisterCommand('getmoney', function()
    TriggerServerEvent('powers:server:getmoney', netId)
end, false)
