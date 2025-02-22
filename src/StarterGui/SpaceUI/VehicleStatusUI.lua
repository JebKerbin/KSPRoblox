local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleStatusUI = {}

-- Initialize vehicle status display
function VehicleStatusUI:Init()
    -- Create main UI frame
    local gui = Instance.new("ScreenGui")
    gui.Name = "VehicleStatus"

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.2, 0, 0.3, 0)
    frame.Position = UDim2.new(0.01, 0, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BackgroundTransparency = 0.2
    frame.Parent = gui

    -- Create status displays
    self:CreateIntegrityBar(frame)
    self:CreateSystemStatus(frame)

    -- Add to player's screen
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Create integrity bar
function VehicleStatusUI:CreateIntegrityBar(parent)
    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(0.9, 0, 0.1, 0)
    barContainer.Position = UDim2.new(0.05, 0, 0.05, 0)
    barContainer.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    barContainer.Parent = parent

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.Parent = barContainer

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.Text = "Integrity: 100%"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.Parent = barContainer

    self.integrityBar = bar
    self.integrityLabel = label
end

-- Create system status display
function VehicleStatusUI:CreateSystemStatus(parent)
    local statusContainer = Instance.new("Frame")
    statusContainer.Size = UDim2.new(0.9, 0, 0.7, 0)
    statusContainer.Position = UDim2.new(0.05, 0, 0.2, 0)
    statusContainer.BackgroundTransparency = 1
    statusContainer.Parent = parent

    local systems = {
        {name = "Engines", icon = "🚀"},
        {name = "Fuel Tanks", icon = "⛽"},
        {name = "Control Systems", icon = "🎮"}
    }

    local yPos = 0
    self.systemIndicators = {}

    for _, system in ipairs(systems) do
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(1, 0, 0.2, 0)
        indicator.Position = UDim2.new(0, 0, yPos, 0)
        indicator.BackgroundTransparency = 1
        indicator.Parent = statusContainer

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0.2, 0, 1, 0)
        icon.Text = system.icon
        icon.TextSize = 24
        icon.BackgroundTransparency = 1
        icon.Parent = indicator

        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.5, 0, 1, 0)
        name.Position = UDim2.new(0.25, 0, 0, 0)
        name.Text = system.name
        name.TextColor3 = Color3.fromRGB(200, 200, 200)
        name.BackgroundTransparency = 1
        name.Parent = indicator

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(0.25, 0, 1, 0)
        status.Position = UDim2.new(0.75, 0, 0, 0)
        status.Text = "OK"
        status.TextColor3 = Color3.fromRGB(0, 255, 0)
        status.BackgroundTransparency = 1
        status.Parent = indicator

        self.systemIndicators[system.name] = {
            frame = indicator,
            status = status
        }

        yPos = yPos + 0.25
    end
end

-- Update vehicle status display
function VehicleStatusUI:UpdateStatus(integrity, systems)
    -- Update integrity bar
    local integrityPercent = math.floor(integrity)
    self.integrityBar.Size = UDim2.new(integrity/100, 0, 1, 0)
    self.integrityLabel.Text = "Integrity: " .. integrityPercent .. "%"

    -- Update bar color based on integrity level
    local r = math.min(2 * (1 - integrity/100), 1)
    local g = math.min(2 * (integrity/100), 1)
    self.integrityBar.BackgroundColor3 = Color3.new(r, g, 0)

    -- Update system status indicators
    for name, isWorking in pairs(systems) do
        local indicator = self.systemIndicators[name]
        if indicator then
            indicator.status.Text = isWorking and "OK" or "DAMAGED"
            indicator.status.TextColor3 = isWorking and 
                Color3.fromRGB(0, 255, 0) or 
                Color3.fromRGB(255, 0, 0)
        end
    end
end

return VehicleStatusUI
