--- ============================
---          Constants
--- ============================

local dictionary = 'nm@hands'
local name = 'hands_up'

--- ============================
---            Push
--- ============================

--- Pushes the ped based on params
--- @param netId integer
RegisterNetEvent('powers:server:push', function(netId, x, y, z)
    local entity = NetworkGetEntityFromNetworkId(netId)
    SetEntityVelocity(entity, x, y, z)

    -- Wait until ped stops moving
    local targetPlayerId = NetworkGetEntityOwner(entity)
    TriggerClientEvent('powers:client:waituntilpedstopsmoving', targetPlayerId)
end)

--- Makes the ped ragdoll
--- @param netId integer
RegisterNetEvent('powers:server:setpedtoragdoll', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)

    local CTaskNMBalance = 2
    SetPedToRagdoll(entity, 3000, 3000, CTaskNMBalance, false, false, false)
end)

--- Toggle ped invinciblity
--- @param netId integer
RegisterNetEvent('powers:server:setpedinvincible', function(netId, invincibility)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local targetPlayerId = NetworkGetEntityOwner(entity)
    SetPlayerInvincible(targetPlayerId, invincibility)
end)

--- ============================
---           Freeze
--- ============================

--- Freeze the ped
--- @param netId integer
RegisterNetEvent('powers:server:freezeEntity', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    FreezeEntityPosition(entity, true)
end)

--- Unfreeze the ped
--- @param netId integer
RegisterNetEvent('powers:server:unfreezeEntity', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    FreezeEntityPosition(entity, false)
end)

--- Play the animation
--- @param netId integer
RegisterNetEvent('powers:server:playanim', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local targetPlayerId = NetworkGetEntityOwner(entity)
    TriggerClientEvent('powers:client:playanim', targetPlayerId, netId)
end)

--- Stop the animation
--- @param netId integer
RegisterNetEvent('powers:server:stopanim', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    local targetPlayerId = NetworkGetEntityOwner(entity)
    TriggerClientEvent('powers:client:stopanim', targetPlayerId, netId)
end)

--- Clear ped tasks
--- @param netId integer
RegisterNetEvent('powers:server:cleartasks', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    ClearPedTasksImmediately(entity)
end)
