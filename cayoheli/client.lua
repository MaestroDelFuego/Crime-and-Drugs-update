local spawnCoords = vector3(4485.21, -4457.77, 4.25)
local planeModel = "duster"
local markerColor = { r = 255, g = 0, b = 0, a = 150 } -- red

-- Draw 3D text function
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
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.015, factor, 0.03, 0, 0, 0, 100)
    ClearDrawOrigin()
end

-- Load model helper
local function LoadModel(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(10)
    end
    return modelHash
end

-- Spawn plane function
local function SpawnPlane()
    local modelHash = LoadModel(planeModel)
    local plane = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    SetVehicleOnGroundProperly(plane)
    SetModelAsNoLongerNeeded(modelHash)

    local playerPed = PlayerPedId()
    TaskWarpPedIntoVehicle(playerPed, plane, -1)
end

-- Create map blip once
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetBlipSprite(blip, 90) -- Plane icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1) -- Red
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Plane Spawn")
    EndTextCommandSetBlipName(blip)
end)
-- Cleanup vehicles that are not occupied and not driveable
-- This will run every 60 seconds to remove abandoned vehicles
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every 60 seconds

        local vehicles = GetGamePool('CVehicle') -- Get all vehicles in the world

        for _, veh in ipairs(vehicles) do
            if not DoesEntityExist(veh) then goto continue end

            local isOccupied = false
            for seat = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
                if not IsVehicleSeatFree(veh, seat) then
                    isOccupied = true
                    break
                end
            end

            if not isOccupied and not IsVehicleDriveable(veh, false) then
                DeleteEntity(veh)
            end

            ::continue::
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        ExtendWorldBoundaryForPlayer(-9000000.0, -11000000.0, 30.0)
        ExtendWorldBoundaryForPlayer(10000000.0, 1200000.0, 30.0)
        Citizen.Wait(0)
    end
end)

-- Main loop for marker and interaction
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dist = #(playerCoords - spawnCoords)

        if dist < 20.0 then
            -- Draw red arrow marker (rotated to look like a plane facing forward)
            DrawMarker(27, spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.95, 0.0, 0.0, 90.0, 0, 0, 0, 1.5, 1.5, 1.5, markerColor.r, markerColor.g, markerColor.b, markerColor.a, false, true, 2, nil, nil, false)

            if dist < 3.0 then
                DrawText3D(spawnCoords.x, spawnCoords.y, spawnCoords.z + 1.0, "~r~Spawn plane by pressing ~w~[E]")

                if IsControlJustReleased(0, 38) then -- E key
                    SpawnPlane()
                end
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

local palletModel = `prop_pallet_01a`
local blockModel = `ba_prop_battle_coke_block_01a`

local coordsList = {
    vector3(4886.22, -5747.36, 25.35),
    vector3(4888.02, -5745.64, 25.35)
}

RegisterCommand("spawncokepallets", function()
    -- Load both models
    RequestModel(palletModel)
    while not HasModelLoaded(palletModel) do
        Citizen.Wait(10)
    end

    RequestModel(blockModel)
    while not HasModelLoaded(blockModel) do
        Citizen.Wait(10)
    end

    for _, coords in ipairs(coordsList) do
        -- Spawn pallet
        local pallet = CreateObject(palletModel, coords.x, coords.y, coords.z, true, true, true)
        FreezeEntityPosition(pallet, true)

        -- Spawn coke block 0.2 higher on Z
        local block = CreateObject(blockModel, coords.x, coords.y, coords.z + 0.2, true, true, true)
        FreezeEntityPosition(block, true)
    end

    -- Release models
    SetModelAsNoLongerNeeded(palletModel)
    SetModelAsNoLongerNeeded(blockModel)

    print("Coke pallets and blocks spawned.")
end, false)
