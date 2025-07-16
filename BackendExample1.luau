local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utilities = Shared:WaitForChild("Utilities")

local Utils = require(Utilities:WaitForChild("Utils"))
local Promise = require(Packages:WaitForChild("Promise"))

local DiscordAPI = {
    StudioLogs = false,
    WEBHOOK_URL = "https://discord.com/api/webhooks/1390353196417028196/G5w6TJFk7a7by5XbKz5BvREORlSGWkYuqELQuvZQTfEm2h42S21TIXc0YHXwjqCTjRa8",
    DefaultAvatarURL = "https://i.imgur.com/XE85wbu.jpeg"
}

local function getTag()
    return RunService:IsStudio() and "[STUDIO]" or "[GAME]"
end

function DiscordAPI.PostMessageAsync(content: {
    userName: string,
    postImage: string?,
    title: string,
    description: string?,
})
    if not DiscordAPI.StudioLogs and RunService:IsStudio() then
        -- Avoid studio message post
        return Promise.resolve()
    end

    return Promise.new(function(resolve, reject)
        if not content.userName then return reject("No username provided") end
        if not content.title then return reject("No title provided") end

        local jsonData = HttpService:JSONEncode({
            username = `{content.userName} {getTag()}`,
            avatar_url = DiscordAPI.DefaultAvatarURL,
            embeds = {{
                title = content.title,
                description = content.description and `{content.description}` or "Empty.",
                color = 3066993, -- Verde
                timestamp = DateTime.now():ToIsoDate()
            }}
        })

        local success, err = pcall(function()
            HttpService:PostAsync(DiscordAPI.WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
        end)

        if not success then
            warn("[Webhook] Error to post log " .. tostring(err))
            return reject(err)
        end

        resolve(true)
    end)
end

function DiscordAPI.PostPlayerJoin(player)
    return DiscordAPI.PostMessageAsync({
        userName = "Join logger",
		title = "🔌✅ Player connected",
		description = `**{player.DisplayName}** (ID: {player.UserId}) ha entrado al juego.`
    })
end

function DiscordAPI.PostPlayerLeave(player)
    return DiscordAPI.PostMessageAsync({
        userName = "Join logger",
		title = "🔌🛑 Player disconnected",
		description = `**{player.DisplayName}** (ID: {player.UserId}) ha salido del juego.`
    })
end

function DiscordAPI.PostError(errorMessage: string, context: string?)
    return DiscordAPI.PostMessageAsync({
        userName = "Error Logger",
        title = "⚠️ Post error",
        description = context and `**Context:** {context}\n**Error:** {errorMessage}` or errorMessage
    })
end

function DiscordAPI.PostPurchase(player, itemName: string, cost: number)
    return DiscordAPI.PostMessageAsync({
        userName = "Products logger",
        title = "💰 Purchase completed",
        description = `**{player.Name}** bought **{itemName}** for R$ **{cost}** \nRevenue after tax: **{math.floor(cost*0.7)}**.`
    })
end

function DiscordAPI.PostCustomEvent(player, eventTitle: string, eventDescription: string)
    return DiscordAPI.PostMessageAsync({
        userName = player.Name,
        title = eventTitle,
        description = eventDescription
    })
end

return DiscordAPI
