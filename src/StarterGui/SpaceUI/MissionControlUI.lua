local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MissionControlUI = {}

-- Mission types with detailed objectives
MissionControlUI.MissionTypes = {
    Orbit = {
        name = "Achieve Orbit",
        description = "Reach a stable orbit around Kerbin",
        objectives = {
            {text = "Launch vehicle", reward = 20},
            {text = "Reach 70km altitude", reward = 30},
            {text = "Achieve stable orbit", reward = 50}
        },
        totalReward = 100,
        unlocks = {"BasicRocketry"}
    },
    Landing = {
        name = "Lunar Landing",
        description = "Land on the Mun and return safely",
        objectives = {
            {text = "Achieve Kerbin orbit", reward = 50},
            {text = "Transfer to Mun", reward = 75},
            {text = "Land safely", reward = 75},
            {text = "Return to Kerbin", reward = 50}
        },
        totalReward = 250,
        unlocks = {"AdvancedPropulsion"}
    },
    Science = {
        name = "Science Mission",
        description = "Collect scientific data from space",
        objectives = {
            {text = "Collect atmospheric data", reward = 40},
            {text = "Perform materials study", reward = 60},
            {text = "Transmit data back", reward = 50}
        },
        totalReward = 150,
        unlocks = {"ScienceBasics"}
    },
    Exploration = {
        name = "Planetary Survey",
        description = "Map and study Duna's surface",
        objectives = {
            {text = "Reach Duna orbit", reward = 100},
            {text = "Deploy mapping satellite", reward = 75},
            {text = "Collect surface samples", reward = 125}
        },
        totalReward = 300,
        unlocks = {"InterplanetaryTech"}
    }
}

-- Research tree with unlockable parts
MissionControlUI.ResearchTree = {
    BasicRocketry = {
        name = "Basic Rocketry",
        cost = 100,
        unlocks = {"Small Engine", "Fuel Tank"},
        required = {}
    },
    AdvancedPropulsion = {
        name = "Advanced Propulsion",
        cost = 250,
        unlocks = {"Nuclear Engine", "Ion Drive"},
        required = {"BasicRocketry"}
    },
    ScienceBasics = {
        name = "Science Fundamentals",
        cost = 150,
        unlocks = {"Science Lab", "Data Collector"},
        required = {"BasicRocketry"}
    },
    InterplanetaryTech = {
        name = "Interplanetary Technology",
        cost = 400,
        unlocks = {"Large Solar Panel", "Long-range Antenna"},
        required = {"AdvancedPropulsion", "ScienceBasics"}
    }
}

function MissionControlUI:Init()
    -- Create main UI frame using Roblox's ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "MissionControl"
    gui.ResetOnSpawn = false -- Keep UI when player respawns

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.3, 0, 0.8, 0)
    frame.Position = UDim2.new(0.7, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.Parent = gui

    -- Create tabbed interface with proper Roblox UI elements
    self:CreateTabbedInterface(frame)

    -- Add mission list
    self:CreateMissionList(self.tabs.Missions)

    -- Add research tree
    self:CreateResearchTree(self.tabs.Research)

    -- Add achievements panel
    self:CreateAchievementsPanel(self.tabs.Achievements)

    -- Add to player's GUI with proper error handling
    local player = Players.LocalPlayer
    if player then
        local playerGui = player:WaitForChild("PlayerGui")
        if playerGui then
            gui.Parent = playerGui
        end
    end
end

-- Create tabbed interface
function MissionControlUI:CreateTabbedInterface(parent)
    local tabButtons = Instance.new("Frame")
    tabButtons.Size = UDim2.new(1, 0, 0.1, 0)
    tabButtons.Parent = parent

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 0.9, 0)
    tabContent.Position = UDim2.new(0, 0, 0.1, 0)
    tabContent.Parent = parent

    self.tabs = {}
    local tabNames = {"Missions", "Research", "Achievements"}
    local buttonWidth = 1 / #tabNames

    for i, name in ipairs(tabNames) do
        -- Create tab button with enhanced visuals
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(buttonWidth, 0, 1, 0)
        button.Position = UDim2.new(buttonWidth * (i-1), 0, 0, 0)
        button.Text = name
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.TextColor3 = Color3.fromRGB(200, 200, 200)
        button.Parent = tabButtons

        -- Hover effect
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end)
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end)

        -- Create tab content
        local content = Instance.new("ScrollingFrame")
        content.Size = UDim2.new(0.95, 0, 0.95, 0)
        content.Position = UDim2.new(0.025, 0, 0.025, 0)
        content.BackgroundTransparency = 0.9
        content.Visible = i == 1
        content.Parent = tabContent
        content.ScrollBarThickness = 6

        self.tabs[name] = content

        -- Add tab switching with visual feedback
        button.MouseButton1Click:Connect(function()
            for _, tab in pairs(self.tabs) do
                tab.Visible = false
            end
            content.Visible = true

            -- Update button appearances
            for _, btn in ipairs(tabButtons:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                end
            end
            button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)
    end
end

-- Create mission card with enhanced visuals
function MissionControlUI:CreateMissionCard(parent, mission, yPos)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.9, 0, 0.2, 0)
    card.Position = UDim2.new(0.05, 0, yPos, 0)
    card.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    card.BorderColor3 = Color3.fromRGB(100, 100, 100)
    card.Parent = parent

    -- Add mission details with improved layout
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Text = mission.name
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Parent = card

    local description = Instance.new("TextLabel")
    description.Size = UDim2.new(1, 0, 0.2, 0)
    description.Position = UDim2.new(0, 0, 0.2, 0)
    description.Text = mission.description
    description.TextSize = 14
    description.Font = Enum.Font.Gotham
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.BackgroundTransparency = 1
    description.Parent = card

    -- Add reward information
    local reward = Instance.new("TextLabel")
    reward.Size = UDim2.new(0.3, 0, 0.15, 0)
    reward.Position = UDim2.new(0.7, 0, 0, 0)
    reward.Text = "Reward: " .. mission.totalReward
    reward.TextSize = 14
    reward.Font = Enum.Font.GothamSemibold
    reward.TextColor3 = Color3.fromRGB(255, 215, 0)
    reward.BackgroundTransparency = 1
    reward.Parent = card

    -- Add objective list with progress indicators
    local yOffset = 0.4
    for _, objective in ipairs(mission.objectives) do
        local objFrame = Instance.new("Frame")
        objFrame.Size = UDim2.new(0.9, 0, 0.15, 0)
        objFrame.Position = UDim2.new(0.05, 0, yOffset, 0)
        objFrame.BackgroundTransparency = 1
        objFrame.Parent = card

        local checkBox = Instance.new("ImageButton")
        checkBox.Size = UDim2.new(0.05, 0, 1, 0)
        checkBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        checkBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
        checkBox.Parent = objFrame

        local objLabel = Instance.new("TextLabel")
        objLabel.Size = UDim2.new(0.8, 0, 1, 0)
        objLabel.Position = UDim2.new(0.07, 0, 0, 0)
        objLabel.Text = objective.text .. " (+" .. objective.reward .. ")"
        objLabel.TextSize = 14
        objLabel.Font = Enum.Font.Gotham
        objLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        objLabel.TextXAlignment = Enum.TextXAlignment.Left
        objLabel.BackgroundTransparency = 1
        objLabel.Parent = objFrame

        yOffset = yOffset + 0.15
    end

    -- Add hover effect
    local function updateCardAppearance(isHovered)
        local targetColor = isHovered and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(60, 60, 60)
        local targetBorder = isHovered and Color3.fromRGB(120, 120, 120) or Color3.fromRGB(100, 100, 100)
        card.BackgroundColor3 = targetColor
        card.BorderColor3 = targetBorder
    end

    card.MouseEnter:Connect(function()
        updateCardAppearance(true)
    end)

    card.MouseLeave:Connect(function()
        updateCardAppearance(false)
    end)
end

-- Create mission list
function MissionControlUI:CreateMissionList(parent)
    local yPosition = 0.05
    for _, mission in pairs(self.MissionTypes) do
        self:CreateMissionCard(parent, mission, yPosition)
        yPosition = yPosition + 0.25  -- Adjusted for larger card size
    end
end

-- Create research tree with enhanced visuals
function MissionControlUI:CreateResearchTree(parent)
    local treeFrame = Instance.new("Frame")
    treeFrame.Size = UDim2.new(0.9, 0, 2, 0)  -- Made scrollable
    treeFrame.Position = UDim2.new(0.05, 0, 0, 0)
    treeFrame.BackgroundTransparency = 1
    treeFrame.Parent = parent

    local yPos = 0.05
    for id, research in pairs(self.ResearchTree) do
        -- Create research node
        local node = Instance.new("Frame")
        node.Size = UDim2.new(0.9, 0, 0.15, 0)
        node.Position = UDim2.new(0.05, 0, yPos, 0)
        node.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        node.BorderColor3 = Color3.fromRGB(100, 100, 100)
        node.Parent = treeFrame

        -- Research name
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.7, 0, 0.3, 0)
        name.Position = UDim2.new(0.05, 0, 0.1, 0)
        name.Text = research.name
        name.TextSize = 16
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.BackgroundTransparency = 1
        name.Parent = node

        -- Cost display
        local cost = Instance.new("TextLabel")
        cost.Size = UDim2.new(0.2, 0, 0.3, 0)
        cost.Position = UDim2.new(0.75, 0, 0.1, 0)
        cost.Text = research.cost
        cost.TextSize = 14
        cost.Font = Enum.Font.GothamSemibold
        cost.TextColor3 = Color3.fromRGB(255, 215, 0)
        cost.BackgroundTransparency = 1
        cost.Parent = node

        -- Unlocks list
        local unlockText = table.concat(research.unlocks, ", ")
        local unlocks = Instance.new("TextLabel")
        unlocks.Size = UDim2.new(0.9, 0, 0.3, 0)
        unlocks.Position = UDim2.new(0.05, 0, 0.5, 0)
        unlocks.Text = "Unlocks: " .. unlockText
        unlocks.TextSize = 14
        unlocks.Font = Enum.Font.Gotham
        unlocks.TextColor3 = Color3.fromRGB(200, 200, 200)
        unlocks.TextXAlignment = Enum.TextXAlignment.Left
        unlocks.BackgroundTransparency = 1
        unlocks.Parent = node

        yPos = yPos + 0.2
    end
end

-- Create achievements panel with enhanced visuals
function MissionControlUI:CreateAchievementsPanel(parent)
    local achievements = {
        {
            name = "First Steps",
            description = "Launch your first rocket",
            reward = 50
        },
        {
            name = "Orbital Pioneer",
            description = "Achieve stable orbit for the first time",
            reward = 100
        },
        {
            name = "Moon Walker",
            description = "Land on the Mun",
            reward = 200
        },
        {
            name = "Interplanetary Explorer",
            description = "Visit another planet",
            reward = 500
        }
    }

    local yPos = 0.05
    for _, achievement in ipairs(achievements) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0.9, 0, 0.15, 0)
        card.Position = UDim2.new(0.05, 0, yPos, 0)
        card.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        card.BorderColor3 = Color3.fromRGB(100, 100, 100)
        card.Parent = parent

        -- Achievement name
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.7, 0, 0.4, 0)
        name.Position = UDim2.new(0.05, 0, 0.1, 0)
        name.Text = achievement.name
        name.TextSize = 16
        name.Font = Enum.Font.GothamBold
        name.TextColor3 = Color3.fromRGB(255, 255, 255)
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.BackgroundTransparency = 1
        name.Parent = card

        -- Achievement description
        local description = Instance.new("TextLabel")
        description.Size = UDim2.new(0.7, 0, 0.4, 0)
        description.Position = UDim2.new(0.05, 0, 0.5, 0)
        description.Text = achievement.description
        description.TextSize = 14
        description.Font = Enum.Font.Gotham
        description.TextColor3 = Color3.fromRGB(200, 200, 200)
        description.TextXAlignment = Enum.TextXAlignment.Left
        description.BackgroundTransparency = 1
        description.Parent = card

        -- Reward display
        local reward = Instance.new("TextLabel")
        reward.Size = UDim2.new(0.2, 0, 0.4, 0)
        reward.Position = UDim2.new(0.75, 0, 0.3, 0)
        reward.Text = "+" .. achievement.reward
        reward.TextSize = 14
        reward.Font = Enum.Font.GothamSemibold
        reward.TextColor3 = Color3.fromRGB(255, 215, 0)
        reward.BackgroundTransparency = 1
        reward.Parent = card

        yPos = yPos + 0.2
    end
end

-- Add proper cleanup
function MissionControlUI:Cleanup()
    -- Remove all connections and UI elements
    for _, connection in pairs(self.connections or {}) do
        connection:Disconnect()
    end

    -- Clear references
    self.tabs = nil
    self.connections = nil

    -- Find and remove GUI
    local player = Players.LocalPlayer
    if player then
        local gui = player.PlayerGui:FindFirstChild("MissionControl")
        if gui then
            gui:Destroy()
        end
    end
end

return MissionControlUI