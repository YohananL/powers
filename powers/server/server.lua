--- ============================
---          NetEvents
--- ============================

---
--- @param netId integer
RegisterNetEvent('pet-companion:server:deleteEntity', function(netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
end)
