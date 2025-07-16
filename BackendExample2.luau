-- BadgeManager.lua

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Utilities = Shared:WaitForChild("Utilities")
local DiscordAPI = require(Utilities:WaitForChild("DiscordAPI"))

local BadgeManager = {}

-- Badge registry
BadgeManager.Badges = {
	["BetaJoin"] = 619149662998311,
}

-- Internal helpers
local function getBadgeId(input)
	if typeof(input) == "string" then
		return BadgeManager.Badges[input]
	elseif typeof(input) == "number" then
		return input
	end
	return nil
end

local function getBadgeNameById(id)
	for name, badgeId in pairs(BadgeManager.Badges) do
		if badgeId == id then
			return name
		end
	end
	return "Unknown"
end

local function getBadgeIdByName(name)
	return BadgeManager.Badges[name] or "Unknown"
end

-- Check if the player already owns the badge
function BadgeManager:HasBadge(player, badge)
	local badgeId = getBadgeId(badge)
	if not badgeId then return false end

	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

	return success and hasBadge
end

-- Attempt to award badge
function BadgeManager:AwardBadge(player, badge)
	local badgeId = getBadgeId(badge)
	if not badgeId then
		warn("[BadgeManager] Invalid badge input: " .. tostring(badge))
		return false
	end

	if self:HasBadge(player, badge) then
		return false
	end

	local success, err = pcall(function()
		BadgeService:AwardBadge(player.UserId, badgeId)
	end)

	if success then
		local badgeName = typeof(badge) == "string" and badge or getBadgeNameById(badgeId)
		print(string.format("[BadgeManager] Awarded badge '%s' (ID: %s) to player '%s'.", badgeName, badgeId, player.Name))

		DiscordAPI.PostMessageAsync({
			userName = "Badge Award",
			title = "Badge Awarded",
			description = string.format("Player **%s** (ID: %s) was awarded the badge **%s** (ID: `%s`)", player.DisplayName, player.UserId, badgeName, badgeId)
		})

		return true
	else
		warn(string.format("[BadgeManager] Failed to award badge '%s' to player '%s': %s", tostring(badge), player.Name, tostring(err)))
		return false
	end
end

return BadgeManager
