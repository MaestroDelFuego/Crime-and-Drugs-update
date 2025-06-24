local QBCore = exports['qb-core']:GetCoreObject()
if not QBCore then
    print("Error: QBCore not found!")
    return
end

-- Drug lab configurations
local drugLabs = {
    {
        name = "Weed Farm",
        ipl = "bkr_biker_interior_placement_interior_1_biker_dlc_int_ware02_milo",
        exterior = vector3(-1273.36, -1371.97, 4.3),
        interior = vector3(1065.06, -3183.49, -39.16),
        props = {"weed_drying", "weed_upgrade_equip", "weed_curing", "weed_machinery"},
        blipColor = 2
    }
}

-- Shared variables
local spawnedPeds = {} -- Track spawned NPCs
local weedPlants = {} -- Track spawned weed plants
local lastEnteredLab = nil
local sellerPed = nil
local tableObject = nil

-- Configurable constants
local sellerCoords = vector3(-361.87, 6054.28, 30.44)
local pedModel = "a_m_m_hillbilly_01"
local tableModel = "tr_int1_plan_table03"
local tableCoords = vector3(1094.89, -3196.07, -38.99)
local harvestDistance = 2.0
local weedCooldownTime = 300 -- 5 minutes in seconds

-- Weed plant coordinates
local weedPlantCoords = {
    vector3(1061.56, -3191.93, -39.15), vector3(1063.85, -3192.27, -39.12), vector3(1064.15, -3194.28, -39.13),
    vector3(1062.09, -3194.58, -39.11), vector3(1062.23, -3196.88, -39.12), vector3(1063.32, -3197.21, -39.00),
    vector3(1064.54, -3196.95, -39.08), vector3(1064.70, -3198.31, -39.12), vector3(1063.42, -3198.20, -39.11),
    vector3(1062.37, -3198.12, -39.13), vector3(1062.11, -3199.31, -39.14), vector3(1063.18, -3199.30, -39.12),
    vector3(1064.28, -3199.21, -39.13), vector3(1064.80, -3201.76, -39.05), vector3(1062.51, -3201.66, -39.07),
    vector3(1061.89, -3203.80, -39.05), vector3(1064.68, -3203.65, -39.09), vector3(1064.64, -3205.65, -39.04),
    vector3(1062.37, -3205.57, -39.07), vector3(1059.84, -3204.84, -39.05), vector3(1057.72, -3204.63, -39.00),
    vector3(1055.55, -3204.45, -39.03), vector3(1055.15, -3206.87, -39.07), vector3(1057.37, -3207.37, -39.04),
    vector3(1059.47, -3207.44, -39.05), vector3(1052.46, -3197.11, -39.09), vector3(1050.54, -3197.13, -39.15),
    vector3(1050.31, -3194.85, -39.13), vector3(1052.29, -3195.18, -39.10), vector3(1052.81, -3192.53, -39.05),
    vector3(1050.20, -3192.46, -39.06), vector3(1050.24, -3190.12, -39.05), vector3(1050.22, -3188.02, -39.05),
    vector3(1052.65, -3187.74, -39.10), vector3(1052.74, -3190.07, -39.05), vector3(1052.83, -3192.62, -39.05),
    vector3(1057.36, -3191.03, -39.14), vector3(1057.49, -3189.16, -39.11), vector3(1055.77, -3188.86, -39.05),
    vector3(1055.29, -3190.51, -39.13)
}

-- Weed plant data for harvesting
local weedPlantsData = {}
for i, coord in ipairs(weedPlantCoords) do
    weedPlantsData[i] = { coords = coord, harvested = false, cooldown = 0 }
end

-- Register dumpcoords command
RegisterCommand("dumpcoords", function()
    local pos = GetEntityCoords(PlayerPedId())
    print(("vector3(%.2f, %.2f, %.2f)"):format(pos.x, pos.y, pos.z))
end, false)
RegisterKeyMapping("dumpcoords", "Dump player coordinates", "keyboard", "F7")

-- Load IPLs and interior props
Citizen.CreateThread(function()
    for _, lab in ipairs(drugLabs) do
        print("Loading IPL:", lab.ipl)
        RequestIpl(lab.ipl)
        Wait(100)
        local interiorID = GetInteriorAtCoords(lab.interior.x, lab.interior.y, lab.interior.z)
        if interiorID ~= 0 then
            print("Interior ID found:", interiorID)
            for _, prop in ipairs(lab.props) do
                print("Activating prop:", prop)
                ActivateInteriorEntitySet(interiorID, prop)
            end
            RefreshInterior(interiorID)
        else
            print("Warning: Interior not found at", lab.interior)
        end
    end
end)

-- Create blips for labs and seller
Citizen.CreateThread(function()
    for _, lab in ipairs(drugLabs) do
        local blip = AddBlipForCoord(lab.exterior.x, lab.exterior.y, lab.exterior.z)
        SetBlipSprite(blip, 51)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, lab.blipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(lab.name)
        EndTextCommandSetBlipName(blip)
    end

    local sellerBlip = AddBlipForCoord(sellerCoords.x, sellerCoords.y, sellerCoords.z)
    SetBlipSprite(sellerBlip, 140)
    SetBlipScale(sellerBlip, 0.7)
    SetBlipColour(sellerBlip, 2)
    SetBlipAsShortRange(sellerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Weed Dealer")
    EndTextCommandSetBlipName(sellerBlip)
end)

-- Spawn seller ped
Citizen.CreateThread(function()
    print("Spawning seller ped at", sellerCoords)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(10) end
    sellerPed = CreatePed(0, pedModel, sellerCoords.x, sellerCoords.y, sellerCoords.z, 135.0, false, true)
    SetEntityVisible(sellerPed, true)
    FreezeEntityPosition(sellerPed, true)
    SetEntityInvincible(sellerPed, true)
    SetBlockingOfNonTemporaryEvents(sellerPed, true)
    SetEntityAsMissionEntity(sellerPed, true, true)
    print("Seller ped spawned:", sellerPed)
end)

-- Setup qb-target for selling
Citizen.CreateThread(function()
    print("Setting up qb-target for weed/coke selling")
    exports['qb-target']:AddBoxZone("weed_sell", vector3(sellerCoords.x, sellerCoords.y, sellerCoords.z), 1.0, 1.0, {
        name = "weed_sell",
        heading = 0,
        debugPoly = false,
    }, {
        options = {
            {
                type = "server",
                event = "custom_weedharvest:sellWeed",
                icon = "fas fa-cannabis",
                label = "Sell Weed",
            },
            {
                type = "server",
                event = "custom_weedharvest:cokesell",
                icon = "fas fa-capsules",
                label = "Sell Coke",
            }
        },
        distance = 2.5
    })
end)

-- Helper to draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(_x, _y)
    DrawRect(_x, _y + 0.0125, 0.015 + (#text / 370), 0.03, 0, 0, 0, 120)
end

-- Delete weed plants
function DeleteWeedPlants()
    print("Deleting weed plants")
    for _, plant in ipairs(weedPlants) do
        if DoesEntityExist(plant) then
            DeleteEntity(plant)
        end
    end
    weedPlants = {}
end

-- Delete spawned peds
function DeleteSpawnedPeds()
    print("Deleting spawned peds")
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    spawnedPeds = {}
end

-- Spawn weed plants
function SpawnWeedPlants()
    print("Spawning weed plants")
    DeleteWeedPlants() -- Clear existing plants to prevent duplicates
    local model = "bkr_prop_weed_med_01b"
    RequestModel(model)
    local startTime = GetGameTimer()
    while not HasModelLoaded(model) and GetGameTimer() - startTime < 5000 do
        Wait(10)
    end
    if not HasModelLoaded(model) then
        print("Error: Failed to load weed plant model", model)
        return
    end

    for _, coord in ipairs(weedPlantCoords) do
        local plant = CreateObject(model, coord.x, coord.y, coord.z, false, false, false)
        PlaceObjectOnGroundProperly(plant)
        FreezeEntityPosition(plant, true)
        table.insert(weedPlants, plant)
    end
    SetModelAsNoLongerNeeded(model)
    print("Weed plants spawned:", #weedPlants)
end

-- Spawn peds in Weed Farm
function SpawnWeedFarmPeds()
    print("Spawning weed farm peds")
    DeleteSpawnedPeds() -- Clear existing peds
    local tracksuitModels = {"g_m_y_azteca_01", "g_m_y_mexgoon_01"}
    local spawnPositions = {
        vector3(1055.0, -3194.5, -39.16), vector3(1060.5, -3191.0, -39.16),
        vector3(1063.5, -3186.0, -39.16), vector3(1067.0, -3189.5, -39.16),
        vector3(1069.5, -3185.0, -39.16)
    }

    for i, pos in ipairs(spawnPositions) do
        local model = GetHashKey(tracksuitModels[(i % #tracksuitModels) + 1])
        RequestModel(model)
        local startTime = GetGameTimer()
        while not HasModelLoaded(model) and GetGameTimer() - startTime < 5000 do
            Wait(10)
        end
        if not HasModelLoaded(model) then
            print("Error: Failed to load ped model", model)
        else
            local ped = CreatePed(4, model, pos.x, pos.y, pos.z, 0.0, false, true)
            SetEntityHeading(ped, 0.0)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetModelAsNoLongerNeeded(model)
            table.insert(spawnedPeds, ped)
        end
    end
    print("Weed farm peds spawned:", #spawnedPeds)
end

-- Main entry/exit loop
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        -- Check exterior entry points
        for _, lab in ipairs(drugLabs) do
            if #(pos - lab.exterior) < 1.5 then
                DrawText3D(lab.exterior.x, lab.exterior.y, lab.exterior.z, ("[E] Enter %s"):format(lab.name))
                if IsControlJustReleased(0, 38) then -- E key
                    print("Entering lab:", lab.name)
                    lastEnteredLab = lab
                    DoScreenFadeOut(500)
                    Wait(600)
                    SetEntityCoords(ped, lab.interior.x, lab.interior.y, lab.interior.z)
                    Wait(200)
                    DoScreenFadeIn(500)
                    if lab.name == "Weed Farm" then
                        SpawnWeedPlants()
                        SpawnWeedFarmPeds()
                    end
                end
            end
        end

        -- Check interior exit point
        if lastEnteredLab and #(pos - lastEnteredLab.interior) < 1.5 then
            DrawText3D(lastEnteredLab.interior.x, lastEnteredLab.interior.y, lastEnteredLab.interior.z, ("[E] Exit %s"):format(lastEnteredLab.name))
            if IsControlJustReleased(0, 38) then -- E key
                print("Exiting lab:", lastEnteredLab.name)
                DoScreenFadeOut(500)
                Wait(600)
                SetEntityCoords(ped, lastEnteredLab.exterior.x, lastEnteredLab.exterior.y, lastEnteredLab.exterior.z)
                Wait(200)
                DoScreenFadeIn(500)
                if lastEnteredLab.name == "Weed Farm" then
                    DeleteWeedPlants()
                    DeleteSpawnedPeds()
                end
                lastEnteredLab = nil
            end
        end
    end
end)

-- Weed harvesting loop
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local currentTime = GetGameTimer()

        for i, plant in ipairs(weedPlantsData) do
            local dist = #(playerCoords - plant.coords)

            -- Reset cooldown
            if plant.harvested and currentTime >= plant.cooldown then
                plant.harvested = false
                plant.cooldown = 0
            end

            if dist < harvestDistance then
                sleep = 0
                DrawMarker(2, plant.coords.x, plant.coords.y, plant.coords.z + 0.2, 0, 0, 0, 0, 0, 0, 0.4, 0.4, 0.4, 0, 255, 0, 200, false, true, 2)

                if not plant.harvested then
                    DrawText3D(plant.coords.x, plant.coords.y, plant.coords.z + 0.5, "[E] Harvest Weed")
                    if IsControlJustReleased(0, 38) then -- E key
                        print("Harvesting weed at plant", i)
                        plant.harvested = true
                        plant.cooldown = currentTime + (weedCooldownTime * 1000)
                        TaskStartScenarioInPlace(playerPed, "world_human_gardener_plant", 0, true)
                        QBCore.Functions.Progressbar("harvesting_weed", "Harvesting Weed...", 5000, false, true, {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true
                        }, {}, {}, {}, function()
                            ClearPedTasks(playerPed)
                            local randomAmount = math.random(1, 2)
                            print("Triggering harvest event with amount:", randomAmount)
                            TriggerServerEvent("custom_weedharvest:harvest", randomAmount)
                        end, function()
                            ClearPedTasks(playerPed)
                            plant.harvested = false
                            plant.cooldown = 0
                            QBCore.Functions.Notify("Harvest canceled", "error")
                            print("Harvest canceled for plant", i)
                        end)
                    end
                else
                    local remaining = math.ceil((plant.cooldown - currentTime) / 1000)
                    DrawText3D(plant.coords.x, plant.coords.y, plant.coords.z + 0.5, "Cooling down: " .. remaining .. "s")
                end
            end
        end

        Wait(sleep)
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("Cleaning up resource:", resourceName)
        DeleteSpawnedPeds()
        DeleteWeedPlants()
        if DoesEntityExist(sellerPed) then DeleteEntity(sellerPed) end
        if DoesEntityExist(tableObject) then DeleteObject(tableObject) end
    end
end)