local lastAlertHash = {}

RegisterNetEvent("npcgunshot:sendAlert", function(data)
    local coords = data.coords
    local street = data.street or "Unknown"
    local zone = data.zone or "Unknown"

    local alertKey = string.format("%.2f-%.2f-%.2f", coords.x, coords.y, coords.z)
    if not lastAlertHash[alertKey] or (os.time() - lastAlertHash[alertKey]) > 60 then
        lastAlertHash[alertKey] = os.time()

        local message = {
            username = "Gunshot Alert",
            embeds = {{
                title = "🔫 Gunshot Detected Near NPC!",
                description = ("Gunshot occurred near NPCs.\n\n**Street**: %s\n**Zone**: %s\n**Coords**: [%.2f, %.2f, %.2f]")
                    :format(street, zone, coords.x, coords.y, coords.z),
                color = 15158332,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }

        PerformHttpRequest("your discord webhook here", function(err, text, headers)
            if err ~= 200 then
                print("[npcsnitches] Discord webhook error: " .. tostring(err))
            end
        end, "POST", json.encode(message), {
            ["Content-Type"] = "application/json"
        })
    end
end)
