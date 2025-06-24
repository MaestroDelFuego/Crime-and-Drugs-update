local QBCore = exports['qb-core']:GetCoreObject()

local launderingLocation = vector3(-691.54, -859.31, 23.76)
local launderingHeading = 90.0
local interactionRadius = 2.0
local laundering = false

-- Draw 3D Text function
function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local p = GetGameplayCamCoords()
    local dist = #(p - coords)

    local scale = 0.35
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 100)
    end
end

-- Interaction loop
CreateThread(function()
    while true do
        local sleep = 1000
        local player = PlayerPedId()
        local playerCoords = GetEntityCoords(player)

        if #(playerCoords - launderingLocation) < interactionRadius then
            sleep = 0
            DrawText3D(launderingLocation + vector3(0.0, 0.0, 1.0), "~g~[E]~s~ Launder Money")

            if IsControlJustReleased(0, 38) then -- E key
                laundering = true

                -- Face east
                SetEntityHeading(player, launderingHeading)

                -- Freeze player
                FreezeEntityPosition(player, true)

                -- Progress bar (QBCore)
                QBCore.Functions.Progressbar("laundering", "Laundering money...", 5000, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function() -- Done
                    laundering = false
                    ClearPedTasks(player)
                    FreezeEntityPosition(player, false)
                    -- Trigger server event here
                    TriggerServerEvent("launderscript:launderMoney")
                end, function() -- Cancel
                    laundering = false
                    ClearPedTasks(player)
                    FreezeEntityPosition(player, false)
                end)
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    local launderingBlip = AddBlipForCoord(-691.54, -859.31, 23.76)
    SetBlipSprite(launderingBlip, 500)             -- Dollar sign icon
    SetBlipDisplay(launderingBlip, 4)
    SetBlipScale(launderingBlip, 0.8)
    SetBlipColour(launderingBlip, 1)               -- Red
    SetBlipAsShortRange(launderingBlip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Money Laundering")
    EndTextCommandSetBlipName(launderingBlip)
end)

