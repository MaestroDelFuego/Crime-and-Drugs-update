-- server.lua

local QBCore = exports['qb-core']:GetCoreObject()
local phoneItem = "phone"
local webhookURL = "your webhook here"

local function sendWebhookLog(title, message, color)
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color,
            ["footer"] = {
                ["text"] = "Moped Robbery Logs"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(webhookURL, function() end, "POST", json.encode({username = "Moped Robber", embeds = embed}), {
        ["Content-Type"] = "application/json"
    })
end

-- Steal phone from player
RegisterServerEvent('qb-phone-robber:stealPhone')
AddEventHandler('qb-phone-robber:stealPhone', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player and Player.Functions.RemoveItem(phoneItem, 1) then
        TriggerClientEvent('QBCore:Notify', src, "A moped thief snatched your phone!", "error", 5000)
        -- Log to Discord
        sendWebhookLog(
            "📱 Phone Snatched!",
            "**Player:** " .. GetPlayerName(src) .. " (ID: " .. src .. ")\nPhone was stolen by a moped thief.",
            16711680 -- red
        )
    end
end)

-- Return phone if thief is killed
RegisterServerEvent('qb-phone-robber:returnPhone')
AddEventHandler('qb-phone-robber:returnPhone', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddItem(phoneItem, 1)
        TriggerClientEvent('QBCore:Notify', src, "You recovered your phone from the thief!", "success", 5000)
        -- Log to Discord
        sendWebhookLog(
            "📱 Phone Recovered!",
            "**Player:** " .. GetPlayerName(src) .. " (ID: " .. src .. ")\nPhone was recovered from the thief.",
            65280 -- green
        )
    end
end)

-- Function to get a random player
local function getRandomPlayer()
    local players = GetPlayers()
    if #players == 0 then
        print("[MOPED ROBBERY SERVER] No players online, cannot spawn thief")
        sendWebhookLog(
            "❌ No Players Online",
            "No players are online to spawn a moped thief.",
            16776960 -- yellow
        )
        return nil
    end
    local randomIndex = math.random(1, #players)
    local randomPlayer = players[randomIndex]
    return randomPlayer
end

-- Function to spawn thief on a random player
local function spawnThiefOnRandomPlayer()
    local player = getRandomPlayer()
    if player then
        print("[MOPED ROBBERY SERVER] Spawning thief for player ID: " .. player)
        TriggerClientEvent('qb-phone-robber:spawnThief', player)
        -- Log to Discord
        sendWebhookLog(
            "🏍 Thief Spawned",
            "**Player Targeted:** " .. GetPlayerName(player) .. " (ID: " .. player .. ")\nA moped thief has been spawned.",
            3447003 -- blue
        )
    end
end

-- Run every 10 minutes (600000 milliseconds)
Citizen.CreateThread(function()
    while true do
        Wait(600000) -- 10 minutes
        print("[MOPED ROBBERY SERVER] Attempting to spawn thief on random player")
        spawnThiefOnRandomPlayer()
    end
end)