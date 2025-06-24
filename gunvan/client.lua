local dealerCoords = vector3(370.4, -31.77, 90.26) -- Where the dealer stands
local pedModel = `g_m_y_korean_01`


CreateThread(function()
    local blip = AddBlipForCoord(dealerCoords.x, dealerCoords.y, dealerCoords.z)
    SetBlipSprite(blip, 110) -- Shop icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1) -- Red color
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Black Market Van")
    EndTextCommandSetBlipName(blip)
end)

-- Spawn shady dealer NPC
CreateThread(function()
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(10) end

    local ped = CreatePed(4, pedModel, dealerCoords.x, dealerCoords.y, dealerCoords.z, 270.0, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end)

-- Setup qb-target zone on dealer
CreateThread(function()
    exports['qb-target']:AddBoxZone("gun_dealer_zone", dealerCoords, 1.5, 1.5, {
        name = "gun_dealer_zone",
        heading = 270.0,
        debugPoly = false,
        minZ = dealerCoords.z - 1.0,
        maxZ = dealerCoords.z + 2.0,
    }, {
        options = {
            {
                type = "client",
                event = "gundealer:openMenu",
                icon = "fas fa-gun",
                label = "Speak to Black Market Dealer",
            },
        },
        distance = 2.0
    })
end)

-- Menu event
RegisterNetEvent('gundealer:openMenu', function()
    exports['qb-menu']:openMenu({
        {
            header = "Black Market Dealer",
            isMenuHeader = true
        },
        {
            header = "Compact Handgun - £50,000",
            txt = "Small, easy to conceal.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_pistol", price = 50000 }
            }
        },
        {
            header = "Sawn-Off Shotgun - £120,000",
            txt = "Loud and devastating at close range.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_dbshotgun", price = 120000 }
            }
        },
        {
            header = "SMG - £90,000",
            txt = "Spray and pray.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_smg", price = 90000 }
            }
        },
        {
            header = "Buy Ammo for Current Weapon - £2,500",
            txt = "Refill based on what you're holding.",
            params = {
                event = "gundealer:buyCurrentWeaponAmmo",
                args = { price = 2500 }
            }   
        },
        {
            header = "Close Menu",
            params = { event = "qb-menu:closeMenu" }
        },
        {
            header = "Close Menu",
            params = { event = "" }
        }
    })
end)

RegisterNetEvent('gundealer:buyCurrentWeaponAmmo', function(data)
    local playerPed = PlayerPedId()
    local weapon = GetSelectedPedWeapon(playerPed)

    if weapon and weapon ~= `WEAPON_UNARMED` then
        local currentAmmo = GetAmmoInPedWeapon(playerPed, weapon)
        local ammoToAdd = 30 -- your fixed amount
        local newAmmo = currentAmmo + ammoToAdd

        -- send new ammo count to server
        TriggerServerEvent('gundealer:server:purchaseAmmo', newAmmo, data.price)
    else
        QBCore.Functions.Notify("You're not holding a weapon!", "error")
    end
end)

-- Actually add ammo on client
RegisterNetEvent('gundealer:client:addAmmo', function(ammoToAdd)
    local playerPed = PlayerPedId()
    local weapon = GetSelectedPedWeapon(playerPed)
    if weapon ~= `WEAPON_UNARMED` then
        local currentAmmo = GetAmmoInPedWeapon(playerPed, weapon)
        local newAmmo = currentAmmo + ammoToAdd
        SetPedAmmo(playerPed, weapon, newAmmo)
        QBCore.Functions.Notify("Ammo added: " .. ammoToAdd, "success")
    else
        QBCore.Functions.Notify("You are not holding a weapon!", "error")
    end
end)




-- Handle purchase client -> server
RegisterNetEvent('gundealer:buyItem', function(data)
    TriggerServerEvent('gundealer:server:purchase', data.item, data.price)
end)

local dealerCoords2 = vector3(4918.26, -5230.30, 1.52) -- New dealer location
local pedHeading2 = 90.0 -- Facing east

-- Create blip for second dealer
CreateThread(function()
    local blip = AddBlipForCoord(dealerCoords2.x, dealerCoords2.y, dealerCoords2.z)
    SetBlipSprite(blip, 110) -- Shop icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1) -- Red color
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Black Market Van")
    EndTextCommandSetBlipName(blip)
end)

-- Spawn shady dealer NPC at second location
CreateThread(function()
    RequestModel(`el_rubio`)
    while not HasModelLoaded(pedModel) do Wait(10) end

    local ped = CreatePed(4, pedModel, dealerCoords2.x, dealerCoords2.y, dealerCoords2.z, pedHeading2, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
end)

RegisterNetEvent('gundealer:openMenuElRubio', function()
    exports['qb-menu']:openMenu({
        {
            header = "El Rubio's Black Market",
            isMenuHeader = true
        },
        -- Original weapons but with slightly higher prices
        {
            header = "Compact Handgun - £60,000",
            txt = "Small, easy to conceal.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_pistol", price = 60000 }
            }
        },
        {
            header = "Sawn-Off Shotgun - £140,000",
            txt = "Loud and devastating at close range.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_dbshotgun", price = 140000 }
            }
        },
        {
            header = "SMG - £100,000",
            txt = "Spray and pray.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_smg", price = 100000 }
            }
        },
        -- Better, premium weapons
        {
            header = "Pistol Mk II - £120,000",
            txt = "Upgraded compact pistol, more damage and accuracy.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_pistol_mk2", price = 120000 }
            }
        },
        {
            header = "Heavy Shotgun - £250,000",
            txt = "More powerful and with better range than sawed-off.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_heavyshotgun", price = 250000 }
            }
        },
        {
            header = "Assault SMG Mk II - £180,000",
            txt = "Rapid fire with improved control.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_smg_mk2", price = 180000 }
            }
        },
        {
            header = "Combat PDW - £200,000",
            txt = "Compact automatic submachine gun.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_combatpdw", price = 200000 }
            }
        },
        {
            header = "Carbine Rifle Mk II - £300,000",
            txt = "Upgraded assault rifle with better attachments.",
            params = {
                event = "gundealer:buyItem",
                args = { item = "weapon_carbinemk2", price = 300000 }
            }
        },
        {
            header = "Buy Ammo for Current Weapon - £5,000",
            txt = "Refill based on what you're holding.",
            params = {
                event = "gundealer:buyCurrentWeaponAmmo",
                args = { price = 5000 }
            }   
        },
        {
            header = "Close Menu",
            params = { event = "qb-menu:closeMenu" }
        }
    })
end)

-- Setup qb-target zone on second dealer
CreateThread(function()
    exports['qb-target']:AddBoxZone("gun_dealer_zone_2", dealerCoords2, 1.5, 1.5, {
        name = "gun_dealer_zone_2",
        heading = pedHeading2,
        debugPoly = false,
        minZ = dealerCoords2.z - 1.0,
        maxZ = dealerCoords2.z + 2.0,
    }, {
        options = {
            {
                type = "client",
                event = "gundealer:openMenuElRubio",
                icon = "fas fa-gun",
                label = "Speak to Black Market Dealer",
            },
        },
        distance = 2.0
    })
end)
