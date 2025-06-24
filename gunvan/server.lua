QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('gundealer:server:purchase', function(item, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveMoney('cash', price, "blackmarket-purchase") then
        Player.Functions.AddItem(item, 1)
        TriggerClientEvent('QBCore:Notify', src, "Item purchased.", "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have enough cash.", "error")
    end
end)

RegisterNetEvent('gundealer:server:purchaseAmmo', function(price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.Functions.RemoveMoney("cash", price, "blackmarket-ammo") then
        local ammoToAdd = 30 -- or whatever amount you want to give
        TriggerClientEvent('gundealer:client:addAmmo', src, ammoToAdd)
    else
        TriggerClientEvent("QBCore:Notify", src, "You don't have enough cash.", "error")
    end
end)



