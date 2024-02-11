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
    -- local ped = RunEntityViewThread()
    if ped == 0 then
        return
    end

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
local frozenEntity
local dictionary = 'nm@hands'
local name = 'hands_up'
-- local dictionary = 'skydive@base'
-- local name = 'free_idle'

RegisterKeyMapping('+freezeEntity', 'Freeze', 'keyboard', Config.Settings.freezeBind)
RegisterCommand('+freezeEntity', function()
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

RegisterCommand('-freezeEntity', function()
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
            -- If 'spacebar' is pressed, add height to the jump
            if IsControlJustPressed(0, 22) and GetEntitySpeed(playerPed) > 0 then
                -- Get the jump force velocity
                local x, y, z = table.unpack(getPushVelocity(playerPed))
                SetEntityVelocity(playerPed, x, y, z)

                if not IsEntityInAir(playerPed) then
                    local coords = GetEntityCoords(playerPed)
                    AddExplosion(coords.x, coords.y, coords.z, grenadeType, 0, true, false, 0, true)
                end
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
---          The Crow
--- ============================

---  @class Crow
local Crow = {
    ped = nil,
    isPerched = true,
}

local AnimationFlags =
{
    ANIM_FLAG_NORMAL = 0,
    ANIM_FLAG_REPEAT = 1,
    ANIM_FLAG_STOP_LAST_FRAME = 2,
    ANIM_FLAG_UPPERBODY = 16,
    ANIM_FLAG_ENABLE_PLAYER_CONTROL = 32,
    ANIM_FLAG_CANCELABLE = 120,
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

function loadModel(modelHash)
    -- Request the model and wait for it to load
    RequestModel(modelHash)
    repeat
        Wait(100)
    until HasModelLoaded(modelHash)
end

function createCrow(playerPed)
    local crowHash = `A_C_Crow`

    -- Load the model
    loadModel(crowHash)

    -- Create the object
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local newCrowPed = CreatePed(0, crowHash, coords.x, coords.y, coords.z, heading, true, false)

    -- Release the model
    SetModelAsNoLongerNeeded(crowHash)

    return newCrowPed
end

RegisterCommand('theCrow', function()
    local playerPed = PlayerPedId()

    -- Crow already exists, remove
    if Crow.ped ~= nil then
        DeleteEntity(Crow.ped)
        Crow.ped = nil
        return
    end

    -- Create crow ped
    Crow.ped = createCrow(playerPed)

    -- Get bone index
    local MH_L_ShoulderBlade = 0x4EAF
    local boneIndex = GetPedBoneIndex(petPed, MH_L_ShoulderBlade)

    -- Attach crow ped to player, ignore entity rotation
    AttachEntityToEntity(Crow.ped, playerPed, boneIndex,
        -0.45, -0.45, 0.90,
        0, 0, 0, false, false, false, true, 2, true)

    -- Thread to check player speed and change crow animation
    CreateThread(function()
        while Crow.ped ~= nil do
            if GetEntitySpeed(playerPed) <= 1 then
                if not Crow.isPerched then
                    -- Make crow do glide animation
                    TaskPlayAnim(Crow.ped, CrowAnimations.glide.dictionary, CrowAnimations.glide.name,
                        8.0, 8.0, -1, CrowAnimations.glide.flag, 0.0, false, false, false)

                    Crow.isPerched = true
                end
            else
                if Crow.isPerched then
                    -- Make crow do fly animation
                    TaskPlayAnim(Crow.ped, CrowAnimations.flapping.dictionary, CrowAnimations.flapping.name,
                        8.0, 8.0, -1, CrowAnimations.flapping.flag, 0.0, false, false, false)

                    Crow.isPerched = false
                end
            end

            Wait(500)
        end
    end)
end, false)
