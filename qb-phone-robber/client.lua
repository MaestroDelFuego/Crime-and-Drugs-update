local activeThief = nil
local cooldown = false
local phoneStolen = false -- Track if phone was stolen

RegisterCommand("disablecooldown", function()
    cooldown = false
    print("[MOPED ROBBERY] Cooldown disabled")
end)

RegisterCommand("enablecooldown", function()
    cooldown = true
    print("[MOPED ROBBERY] Cooldown enabled")
end)

RegisterCommand("spawnThief", function()
    print("[MOPED ROBBERY] Manual spawn command used")
    TriggerEvent('qb-phone-robber:spawnThief')
end)

RegisterNetEvent('qb-phone-robber:spawnThief')
AddEventHandler('qb-phone-robber:spawnThief', function()
    if cooldown then
        print("[MOPED ROBBERY] Thief not spawned: Cooldown active")
        return
    end

    if activeThief then
        print("[MOPED ROBBERY] Thief already active")
        return
    end

    cooldown = true
    phoneStolen = false -- Reset theft state
    print("[MOPED ROBBERY] Cooldown started")
    SetTimeout(360000, function()
        cooldown = false
        print("[MOPED ROBBERY] Cooldown ended")
    end)

    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) or not NetworkIsPlayerActive(PlayerId()) then
        print("[MOPED ROBBERY] Player ped invalid or not active, aborting")
        cooldown = false
        return
    end

    local coords = GetEntityCoords(playerPed)
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then
        print("[MOPED ROBBERY] Invalid player coords (0,0,0), aborting")
        cooldown = false
        return
    end
    print("[MOPED ROBBERY] Player coords: ", coords.x, coords.y, coords.z)

    local thiefModel = `a_m_m_eastsa_02`
    local mopedModel = `faggio`

    RequestModel(thiefModel)
    RequestModel(mopedModel)

    local attempts = 0
    while not HasModelLoaded(thiefModel) or not HasModelLoaded(mopedModel) do
        Wait(100)
        attempts = attempts + 1
        if attempts > 100 then
            print("[MOPED ROBBERY] Model load timeout, aborting spawn")
            cooldown = false
            return
        end
    end
    print("[MOPED ROBBERY] Models loaded successfully")

    -- Generate offsets
    local offsetX = math.random(-20, -10)
    local offsetY = math.random(-5, 5)
    local offsetZ = 1.0
    print("[MOPED ROBBERY] OffsetX: " .. offsetX .. ", OffsetY: " .. offsetY .. ", OffsetZ: " .. offsetZ)

    -- Calculate base spawn position
    local spawnOffset = vector3(coords.x + offsetX, coords.y + offsetY, coords.z + offsetZ)

    -- Find a nearby road node
    local foundNode, nodePos, nodeHeading = GetClosestVehicleNodeWithHeading(spawnOffset.x, spawnOffset.y, spawnOffset.z, 1, 3.0, 0)
    if foundNode then
        spawnOffset = nodePos
        print("[MOPED ROBBERY] Using road node for spawn: ", spawnOffset.x, spawnOffset.y, spawnOffset.z)
    else
        print("[MOPED ROBBERY] No road node found, using manual coords")
    end

    -- Adjust Z to ground level
    local foundGround, groundZ = GetGroundZFor_3dCoord(spawnOffset.x, spawnOffset.y, spawnOffset.z + 1.0, true)
    if foundGround then
        spawnOffset = vector3(spawnOffset.x, spawnOffset.y, groundZ + 1.0)
        print("[MOPED ROBBERY] Ground Z found: ", groundZ)
    else
        print("[MOPED ROBBERY] Ground Z not found, using default Z")
    end
    print("[MOPED ROBBERY] Final spawn offset: ", spawnOffset.x, spawnOffset.y, spawnOffset.z)

    -- Calculate vehicle heading
    local heading = foundNode and nodeHeading or GetHeadingFromVector_2d(coords.x - spawnOffset.x, coords.y - spawnOffset.y)
    print("[MOPED ROBBERY] Vehicle heading: ", heading)

    -- Create vehicle
    local vehicle = CreateVehicle(mopedModel, spawnOffset.x, spawnOffset.y, spawnOffset.z, heading, true, false)
    if not DoesEntityExist(vehicle) then
        print("[MOPED ROBBERY] Vehicle creation failed, aborting")
        cooldown = false
        return
    end
    SetEntityAsMissionEntity(vehicle, true, true)
    SetEntityVisible(vehicle, true)
    SetEntityAlpha(vehicle, 255, false)
    FreezeEntityPosition(vehicle, false)

    -- Create ped
    local ped = CreatePedInsideVehicle(vehicle, 26, thiefModel, -1, true, false)
    if not DoesEntityExist(ped) then
        print("[MOPED ROBBERY] Thief ped creation failed, cleaning up")
        DeleteEntity(vehicle)
        cooldown = false
        return
    end

    print("[MOPED ROBBERY] Thief ped and vehicle spawned")
    activeThief = ped

    -- Configure ped
    SetEntityVisible(ped, true)
    SetEntityAlpha(ped, 255, false)
    SetEntityHealth(ped, 200)
    FreezeEntityPosition(ped, true)
    Wait(100)
    FreezeEntityPosition(ped, false)
    SetEntityAsMissionEntity(ped, true, true)

    -- Thread to handle driving and phone theft
    Citizen.CreateThread(function()
        local maxAttempts = 5000 -- Try for up to 20 seconds
        local attempt = 0

        while DoesEntityExist(ped) and DoesEntityExist(vehicle) and attempt < maxAttempts and not phoneStolen do
            local playerCoords = GetEntityCoords(playerPed)
            local thiefCoords = GetEntityCoords(ped)
            local distance = #(playerCoords - thiefCoords)

            print("[MOPED ROBBERY] Distance to player: ", distance)

            -- Update driving task to current player position
            TaskVehicleDriveToCoord(ped, vehicle, playerCoords.x, playerCoords.y, playerCoords.z, 30.0, 1, GetEntityModel(vehicle), 786603, 1.0)

            -- Check if thief is close enough to steal
            if distance <= 3.5 then
                print("[MOPED ROBBERY] Thief is close enough, attempting to steal phone")
                TriggerServerEvent('qb-phone-robber:stealPhone')
                phoneStolen = true
                -- Task: Flee
                TaskVehicleDriveWander(ped, vehicle, 50.0, 786469)
                print("[MOPED ROBBERY] Thief fleeing")
                break
            elseif distance > 1000.0 then
                -- Player is too far, despawn thief
                print("[MOPED ROBBERY] Player too far away, despawning thief")
                DeleteEntity(vehicle)
                DeleteEntity(ped)
                activeThief = nil
                return
            end

            Wait(1000)
            attempt = attempt + 1 -- Set to maxAttempts to force despawn
        end

        -- If max attempts left and no theft, despawn
        if not phoneStolen and DoesEntityExist(ped) then
            print("[MOPED ROBBERY] Timeout reached, no theft, despawning thief")
            DeleteEntity(vehicle)
            DeleteEntity(ped)
            activeThief = nil
        end
    end)

    -- Thread to monitor ped for death
    Citizen.CreateThread(function()
        while DoesEntityExist(ped) do
            Wait(500)
            if IsEntityDead(ped) then
                if phoneStolen then
                    print("[MOPED ROBBERY] Thief killed after stealing phone, returning phone")
                    TriggerServerEvent('qb-phone-robber:returnPhone')
                else
                    print("[MOPED ROBBERY] Thief killed before stealing phone, no return needed")
                end
                DeleteEntity(vehicle)
                DeleteEntity(ped)
                activeThief = nil
                break
            end
        end
    end)

    -- Timeout cleanup
    SetTimeout(60000, function()
        if DoesEntity(ped) then
            print("[MOPED ROBBERY] Timeout reached, cleaning up")
            DeleteEntity(vehicle)
            DeleteEntity(ped)
            activeThief = nil
        end
    end)
end)