local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui: PlayerGui = player:WaitForChild("PlayerGui", math.huge)
local mainGUI: ScreenGui = playerGui:WaitForChild("MainGUI", math.huge)
local mainFrame: Frame = mainGUI:WaitForChild("Main")
local frames: Frame = mainFrame:WaitForChild("Frames")
local indexFrame: Frame = frames:FindFirstChild("Index")

local IndexReplication = {}

-- Cache
local itemCache: { [string]: { [string]: ImageButton } } = {} -- [variation][npcName]

local function GetContainer(variation: string, attempts: number): ScrollingFrame?
    for _, child in ipairs(indexFrame:GetChildren()) do
        if child:IsA("ScrollingFrame") and string.find(child.Name, variation) then
            return child
        end
    end

    if attempts and attempts >= 4 then
        return warn(`[IndexReplication] Unable to find container for variation: {variation}`)
    end

    warn(`[IndexReplication] No container found for variation: {variation}, retrying...`)
    attempts = attempts or 1
    task.wait(1)
    return GetContainer(variation, attempts + 1)
end

local function GetItem(variation: string, npcName: string): ImageButton?
    itemCache[variation] = itemCache[variation] or {}

    if itemCache[variation][npcName] then
        return itemCache[variation][npcName]
    end

    local container = GetContainer(variation)
    if not container then return end

    for _, child in ipairs(container:GetChildren()) do
        local childName = child:GetAttribute("NPCName")
        if child:IsA("ImageButton") and childName == npcName then
            itemCache[variation][npcName] = child
            return child
        end
    end

    warn(`[IndexReplication] No item found for NPC: {npcName} in variation: {variation}`)
end

local isFirstUpdate = true
function IndexReplication.Replicate(_, newData: { [string]: { [string]: boolean } })
    for npcName, variations in pairs(newData) do
        for variation in pairs(variations) do
            local item = GetItem(variation, npcName)
            if not item then continue end

            local itemContainer: ImageLabel = item:FindFirstChild("Container")
            local characterFrame: ViewportFrame = itemContainer and itemContainer:FindFirstChild("Character")

            local NPCNameLabel = itemContainer:FindFirstChild("NPCName")

            NPCNameLabel.TextColor3 = Color3.new(1, 1, 1)
            NPCNameLabel.Text = npcName

            if not isFirstUpdate then
                local NewPopup = itemContainer:FindFirstChild("New")
                NewPopup.Visible = true
            end
            
            local Gradient = NPCNameLabel:FindFirstChildOfClass("UIGradient")
            if Gradient then
                Gradient.Enabled = true
            end

            if characterFrame and characterFrame:IsA("ViewportFrame") then
                characterFrame.ImageColor3 = Color3.new(1, 1, 1)
                characterFrame.ImageTransparency = 0
            else
                warn(`[IndexReplication] Missing or invalid Character frame for: {npcName} in variation: {variation}`)
            end
        end
    end

    isFirstUpdate = false
end

return IndexReplication
