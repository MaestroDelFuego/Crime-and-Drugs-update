local QBCore = exports['qb-core']:GetCoreObject()

-- Replace this with your actual Discord webhook URL
local discordWebhook = "yourlinkhere"

RegisterNetEvent('chopshop:sellVehicle', function(vehicleNetId, reward)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local maxReward = 50000
    local payout = math.min(reward or 0, maxReward)

    if Player then
        local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
        if vehicle and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end

        Player.Functions.AddMoney('cash', payout)
        TriggerClientEvent('QBCore:Notify', src, "Vehicle chopped for $"..payout, "success")

        -- Log to Discord
        sendChopshopLog(Player.PlayerData.name, Player.PlayerData.citizenid, payout)
    end
end)

function sendChopshopLog(playerName, citizenId, amount)
    local embed = {
        {
            ["title"] = "🚗 Chop Shop Sale",
            ["description"] = ("**Player:** %s\n**Citizen ID:** %s\n**Amount:** $%s"):format(playerName, citizenId, amount),
            ["color"] = 16753920, -- Orange
            ["footer"] = {
                ["text"] = os.date("Chopped on %Y-%m-%d at %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(discordWebhook, function(err, text, headers) end, "POST", json.encode({
        username = "Chop Shop Logs",
        embeds = embed,
        avatar_url = "https://i.imgur.com/bj5M60N.png"
    }), { ["Content-Type"] = "application/json" })
end
