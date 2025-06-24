local QBCore = exports['qb-core']:GetCoreObject()

local chopCoords = vector3(1545.83, 6332.7, 24.08)
local npcModel = `s_m_m_autoshop_01`
local chopRadius = 3.0
local chopNPC = nil
local canChop = true

-- Base price and multipliers for vehicle classes
local basePrice = 1000
local vehicleMultipliers = {
    [0] = 1.0,       -- Compact
    [1] = 2.0,       -- Sedan
    [2] = 3.0,       -- SUV
    [3] = 4.0,       -- Coupe
    [4] = 5.0,       -- Muscle
    [5] = 8.0,       -- Sports Classic
    [6] = 12.0,      -- Sports
    [7] = 20.0,      -- Super
    [8] = 3.5,       -- Motorcycle
    [9] = 6.0,       -- Off-road
    [10] = 2.5,      -- Industrial
    [11] = 2.5,      -- Utility
    [12] = 3.0,      -- Vans
    [13] = 0.5,      -- Cycles
    [14] = 7.0,      -- Boats
    [15] = 15.0,     -- Helicopters
    [16] = 25.0,     -- Planes
    [17] = 4.0,      -- Service
    [18] = 18.0,     -- Emergency (e.g., police, firetruck)
    [19] = 30.0,     -- Military
    [20] = 6.0,      -- Commercial
    [21] = 500.0     -- Trains
}

-- Add blip on map
CreateThread(function()
    local blip = AddBlipForCoord(chopCoords)
    SetBlipSprite(blip, 524)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Chop Shop")
    EndTextCommandSetBlipName(blip)
end)

-- Spawn the Chop Shop NPC
CreateThread(function()
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do Wait(0) end

    chopNPC = CreatePed(0, npcModel, chopCoords.x, chopCoords.y, chopCoords.z - 1.0, 45.0, false, true) -- Adjust heading if needed
    SetEntityInvincible(chopNPC, true)
    SetBlockingOfNonTemporaryEvents(chopNPC, true)
    FreezeEntityPosition(chopNPC, true)
end)

-- Marker and Interaction
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local vehicle = GetVehiclePedIsIn(ped, false)

        if #(pos - chopCoords) < chopRadius then
            DrawMarker(1, chopCoords.x, chopCoords.y, chopCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 0.5, 255, 255, 0, 100, false, true, 2, false, nil, nil, false)

            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                if canChop then
                    local vehClass = GetVehicleClass(vehicle)
                    local multiplier = vehicleMultipliers[vehClass] or 1.0
                    local sellPrice = math.min(math.floor(basePrice * multiplier), 50000)

                    DrawText3D(chopCoords.x, chopCoords.y, chopCoords.z + 1.0, ("[E] Sell Vehicle for $%d"):format(sellPrice))
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('chopshop:sellVehicle', VehToNet(vehicle), sellPrice)
                        canChop = false
                        QBCore.Functions.Notify("Come back in 5 minutes...", "info", 5000)
                        SetTimeout(300000, function()
                            canChop = true
                            QBCore.Functions.Notify("You can now chop another vehicle.", "success", 5000)
                        end)
                    end
                else
                    DrawText3D(chopCoords.x, chopCoords.y, chopCoords.z + 1.0, "Chop shop is cooling down...")
                end
            else
                DrawText3D(chopCoords.x, chopCoords.y, chopCoords.z + 1.0, "Bring a car to sell")
            end
        end
    end
end)

-- 3D Text Function
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
