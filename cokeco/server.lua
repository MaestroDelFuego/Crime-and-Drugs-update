local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}

RegisterNetEvent('cokeprocess:startProcessing', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check for cooldown
    if cooldowns[src] and GetGameTimer() < cooldowns[src] then
        local timeLeft = math.ceil((cooldowns[src] - GetGameTimer()) / 1000)
        TriggerClientEvent('QBCore:Notify', src, 'You must wait ' .. timeLeft .. ' seconds before processing again.', 'error')
        return
    end

    -- Set new cooldown
    cooldowns[src] = GetGameTimer() + Config.CooldownTime

    -- Start processing on client
    TriggerClientEvent('cokeprocess:processStart', src)
end)

RegisterNetEvent('cokeprocess:finishProcessing', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    Player.Functions.AddItem(Config.CokeItem, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.CokeItem], "add")
    TriggerClientEvent('QBCore:Notify', src, 'You processed a coke brick.', 'success')
end)

-- Optional: clear cooldown on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if cooldowns[src] then
        cooldowns[src] = nil
    end
end)
