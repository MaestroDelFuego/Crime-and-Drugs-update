local QBCore = exports['qb-core']:GetCoreObject()
if not QBCore then
    print("Error: QBCore not found!")
    return
end

RegisterNetEvent("custom_weedharvest:harvest")
AddEventHandler("custom_weedharvest:harvest", function(amount)
    local src = source
    print("Harvest event triggered for source:", src, "with amount:", amount)
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        print("Player not found:", src)
        TriggerClientEvent('QBCore:Notify', src, "Player data not found.", "error")
        return
    end

    if amount and type(amount) == "number" and amount > 0 then
        Player.Functions.AddItem("weed_skunk", amount)
        TriggerClientEvent('QBCore:Notify', src, "You harvested " .. amount .. " weed leaf/leaves", "success")
    else
        print("Invalid amount for harvest:", amount)
        TriggerClientEvent('QBCore:Notify', src, "Harvest failed.", "error")
    end
end)

RegisterNetEvent("custom_weedharvest:sellWeed")
AddEventHandler("custom_weedharvest:sellWeed", function()
    local src = source
    print("Sell Weed event triggered by", src)
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        print("Player not found:", src)
        TriggerClientEvent('QBCore:Notify', src, "Player data not found.", "error")
        return
    end

    local item = Player.Functions.GetItemByName("weed_skunk")
    print("Weed item:", json.encode(item))

    if item and item.amount > 0 then
        local pricePerLeaf = 1500
        local total = item.amount * pricePerLeaf
        local valuePerDirtMoney = 100
        local dirtMoneyAmount = math.floor(total / valuePerDirtMoney)

        Player.Functions.RemoveItem("weed_skunk", item.amount)
        Player.Functions.AddItem("dirtmoney", dirtMoneyAmount)

        TriggerClientEvent('QBCore:Notify', src, "Sold " .. item.amount .. " weed leaves for $" .. total .. " (" .. dirtMoneyAmount .. " dirtmoney)", "success")
        sendWeedSaleToDiscord(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, item.amount, total)
    else
        TriggerClientEvent('QBCore:Notify', src, "You have no weed leaves", "error")
    end
end)

RegisterNetEvent("custom_weedharvest:cokesell")
AddEventHandler("custom_weedharvest:cokesell", function()
    local src = source
    print("Sell coke event triggered by", src)
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        print("Player not found:", src)
        TriggerClientEvent('QBCore:Notify', src, "Player data not found.", "error")
        return
    end

    local item = Player.Functions.GetItemByName("coke_brick")
    print("Coke item:", json.encode(item))

    if item and item.amount > 0 then
        local pricePerBrick = 15000
        local total = item.amount * pricePerBrick
        local valuePerDirtMoney = 100
        local dirtMoneyAmount = math.floor(total / valuePerDirtMoney)

        Player.Functions.RemoveItem("coke_brick", item.amount)
        Player.Functions.AddItem("dirtmoney", dirtMoneyAmount)

        TriggerClientEvent('QBCore:Notify', src, "Sold " .. item.amount .. " coke brick(s) for $" .. total .. " (" .. dirtMoneyAmount .. " dirtmoney)", "success")
        sendCokeSaleToDiscord(Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname, item.amount, total)
    else
        TriggerClientEvent('QBCore:Notify', src, "You have no coke bricks", "error")
    end
end)

function sendWeedSaleToDiscord(name, amount, total)
    local webhook = "put your webhook URL here"
    local embed = {
        {
            ["title"] = "🌿 Weed Sale",
            ["color"] = 2067276,
            ["fields"] = {
                {["name"] = "Seller", ["value"] = name, ["inline"] = true},
                {["name"] = "Amount", ["value"] = tostring(amount) .. " leaf(s)", ["inline"] = true},
                {["name"] = "Total Earned", ["value"] = "$" .. total, ["inline"] = true}
            },
            ["footer"] = {
                ["text"] = os.date("Sold at %Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers)
        if err ~= 200 then
            print("Weed webhook failed with error:", err, text)
        else
            print("Weed sale webhook sent successfully")
        end
    end, 'POST', json.encode({
        username = "Weed Dealer",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

function sendCokeSaleToDiscord(name, amount, total)
    local webhook = "put your webhook URL here"
    local embed = {
        {
            ["title"] = "💊 Coke Sale",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "Seller", ["value"] = name, ["inline"] = true},
                {["name"] = "Amount", ["value"] = tostring(amount) .. " brick(s)", ["inline"] = true},
                {["name"] = "Total Earned", ["value"] = "$" .. total, ["inline"] = true}
            },
            ["footer"] = {
                ["text"] = os.date("Sold at %Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers)
        if err ~= 200 then
            print("Coke webhook failed with error:", err, text)
        else
            print("Coke sale webhook sent successfully")
        end
    end, 'POST', json.encode({
        username = "Coke Dealer",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end