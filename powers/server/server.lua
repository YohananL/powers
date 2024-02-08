--- ============================
---          NetEvents
--- ============================

--- Pushes the ped based on params
--- @param netId integer
RegisterNetEvent('powers:server:push', function(netId, x, y, z)
    local entity = NetworkGetEntityFromNetworkId(netId)
    SetEntityVelocity(entity, x, y, z)
end)

--- Makes the ped ragdoll
--- @param netId integer
RegisterNetEvent('powers:server:setpedtoragdoll', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)

    local CTaskNMBalance = 2
    SetPedToRagdoll(entity, 3000, 3000, CTaskNMBalance, false, false, false)
end)

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

--- Clear ped tasks
--- @param netId integer
RegisterNetEvent('powers:server:cleartasks', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    ClearPedTasksImmediately(entity)
end)
