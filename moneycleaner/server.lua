-- Ensure QBCore is accessible
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent("launderscript:launderMoney", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local item = Player.Functions.GetItemByName("dirtmoney")
    if not item or item.amount <= 0 then
        TriggerClientEvent("QBCore:Notify", src, "You don't have any dirty money.", "error")
        return
    end

    local amount = item.amount
    local unitValue = 100                -- Each "dirtmoney" item is worth $100
    local totalDirty = amount * unitValue

    local launderingFee = 0.40           -- 20% fee
    local payout = math.floor(totalDirty * (1 - launderingFee))

    -- Remove all dirtmoney
    Player.Functions.RemoveItem("dirtmoney", amount)

    -- Give clean cash
    Player.Functions.AddMoney("cash", payout, "laundered-money")

    -- Notify player
    TriggerClientEvent("QBCore:Notify", src,
        ("Laundered %d dirty money for $%d (after %.0f%% fee)"):format(totalDirty, payout, launderingFee * 100),
        "success"
    )
end)
