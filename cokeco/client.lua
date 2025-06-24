local QBCore = exports['qb-core']:GetCoreObject()
local processing = false
local markerCoords = Config.CokeLocation
local interactDist = 2.0

-- Draw marker every frame
CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dist = #(playerCoords - markerCoords)

        if dist < 20.0 then
            DrawMarker(2, markerCoords.x, markerCoords.y, markerCoords.z + 0.2, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 0, 0, 150, false, true, 2, nil, nil, false)

            if dist < interactDist and not processing then
                Draw3DText(markerCoords.x, markerCoords.y, markerCoords.z + 0.4, "[E] Process Coke into Brick")

                if IsControlJustReleased(0, 38) then -- 38 = E
                    TriggerServerEvent('cokeprocess:startProcessing')
                end
            end
        else
            Wait(1000)
        end
    end
end)

-- Create coke pile prop
CreateThread(function()
    local hash = GetHashKey("bkr_prop_coke_powder_01")
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local pile = CreateObject(hash, markerCoords.x + 0.3, markerCoords.y, markerCoords.z, false, false, false)
    SetEntityHeading(pile, 0.0)
    FreezeEntityPosition(pile, true)
end)

RegisterNetEvent('cokeprocess:processStart', function()
    local ped = PlayerPedId()
    processing = true

    QBCore.Functions.Progressbar("coke_brick_process", "Processing Coke...", Config.ProcessingTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent('cokeprocess:finishProcessing')
        processing = false
    end, function()
        QBCore.Functions.Notify("Process cancelled", "error")
        processing = false
    end)
end)

-- Helper to draw 3D text
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 100)
    end
end

CreateThread(function()
    local blip = AddBlipForCoord(markerCoords.x, markerCoords.y, markerCoords.z)

    SetBlipSprite(blip, 51)             -- Choose icon, 51 = cocaine (white bag)
    SetBlipDisplay(blip, 4)             -- Display type
    SetBlipScale(blip, 0.8)             -- Size
    SetBlipColour(blip, 1)              -- Color (red)
    SetBlipAsShortRange(blip, true)     -- Only visible when close
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Coke Processing")
    EndTextCommandSetBlipName(blip)
end)

local teleportLocations = {
    {
        label = "Exit",
        coords = vector3(4991.80, -5719.60, 19.88),
        blip = true,
        teleportTo = vector3(4980.93, -5709.12, 19.89) -- Teleports to Enter
    },
    {
        label = "Enter",
        coords = vector3(4980.93, -5709.12, 19.89),
        blip = true,
        teleportTo = vector3(4991.80, -5719.60, 19.88) -- Teleports to Exit
    }
}

CreateThread(function()
    for _, loc in pairs(teleportLocations) do
        if loc.blip then
            local blip = AddBlipForCoord(loc.coords)
            SetBlipSprite(blip, 1) -- Standard marker
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, 0.9)
            SetBlipColour(blip, 1) -- Red
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(loc.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, loc in pairs(teleportLocations) do
            local dist = #(playerCoords - loc.coords)

            -- Draw arrow marker (red)
            if dist < 50.0 then
                DrawMarker(28, loc.coords.x, loc.coords.y, loc.coords.z + 0.5, 0.0, 0.0, 0.0, 0, 180.0, 0.0, 0.7, 0.7, 0.7, 255, 0, 0, 150, false, true, 2, false, nil, nil, false)
            end

            -- Interaction zone
            if dist < 1.5 then
                DrawText3D(loc.coords.x, loc.coords.y, loc.coords.z + 1.0, "[E] Teleport to " .. loc.label)

if IsControlJustReleased(0, 38) then -- E
    local vehicle = nil
    if IsPedInAnyVehicle(playerPed, false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
        SetEntityCoords(vehicle, loc.teleportTo.x, loc.teleportTo.y, loc.teleportTo.z, false, false, false, true)
        SetEntityHeading(vehicle, GetEntityHeading(vehicle)) -- keep current heading
    else
        SetEntityCoords(playerPed, loc.teleportTo.x, loc.teleportTo.y, loc.teleportTo.z, false, false, false, true)
        SetEntityHeading(playerPed, GetEntityHeading(playerPed))
    end
end
            end
        end
    end
end)

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

local clothingShop = {
    coords = vector3(5011.81, -5787.36, 17.8),
    blip = true
}

CreateThread(function()
    if clothingShop.blip then
        local blip = AddBlipForCoord(clothingShop.coords)
        SetBlipSprite(blip, 73) -- Clothing store blip icon
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 5) -- Light blue
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Clothing Shop")
        EndTextCommandSetBlipName(blip)
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local dist = #(playerCoords - clothingShop.coords)

        if dist < 50.0 then
            -- Draw marker (choose your favorite style)
            DrawMarker(27, clothingShop.coords.x, clothingShop.coords.y, clothingShop.coords.z - 0.98, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 150, 255, 100, false, true, 2, false, nil, nil, false)
        end

        if dist < 1.5 then
            DrawText3D(clothingShop.coords.x, clothingShop.coords.y, clothingShop.coords.z, "[E] Open Clothing Shop")

            if IsControlJustReleased(0, 38) then -- E
                TriggerEvent('qb-clothing:client:openMenu')
            end
        end
    end
end)

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