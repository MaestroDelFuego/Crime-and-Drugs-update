local QBCore = exports['qb-core']:GetCoreObject()
local lastGunshot = 0

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()

        if IsPedShooting(ped) then
            local currentTime = GetGameTimer()
            if currentTime - lastGunshot > 5500 then -- 2 second cooldown
                lastGunshot = currentTime

                local playerData = QBCore.Functions.GetPlayerData()
                if playerData and playerData.job and playerData.job.name == "police" then
                    -- Police are allowed to shoot without triggering alert
                    return
                end
                local coords = GetEntityCoords(ped)

                local foundNpc = false
                for _, npc in ipairs(GetGamePool("CPed")) do
                    if not IsPedAPlayer(npc) then
                        local npcCoords = GetEntityCoords(npc)
                        local dist = #(coords - npcCoords)
                        if dist < 300.0 then
                            foundNpc = true
                            break
                        end
                    end
                end

                if foundNpc then
                    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
                    local street = GetStreetNameFromHashKey(streetHash)
                    local zone = GetNameOfZone(coords.x, coords.y, coords.z)

                    TriggerServerEvent("npcgunshot:sendAlert", {
                        coords = coords,
                        street = street,
                        zone = zone
                    })
                end
            end
        end
    end
end)
