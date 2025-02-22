local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OrbitSystem = require(ReplicatedStorage.Physics.OrbitSystem)
local AutopilotSystem = require(ReplicatedStorage.Navigation.AutopilotSystem)

local SpaceMapUI = {}

function SpaceMapUI:Init()
    -- Create main map frame
    local gui = Instance.new("ScreenGui")
    gui.Name = "SpaceMap"

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.8, 0, 0.8, 0)
    frame.Position = UDim2.new(0.1, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    frame.Visible = false
    frame.Parent = gui

    -- Add map controls
    self:CreateMapControls(frame)

    -- Add trajectory display
    self:CreateTrajectoryDisplay(frame)

    -- Add planet indicators with interactive selection
    self:CreatePlanetIndicators(frame)

    -- Add maneuver node interface
    self:CreateManeuverInterface(frame)

    -- Add to player's screen
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Toggle map with M key
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.M then
            frame.Visible = not frame.Visible
        end
    end)

    -- Start trajectory update loop
    game:GetService("RunService").RenderStepped:Connect(function()
        if frame.Visible then
            self:UpdateTrajectoryDisplay()
        end
    end)
end

-- Create map control buttons
function SpaceMapUI:CreateMapControls(parent)
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(0.1, 0, 1, 0)
    controlsFrame.Position = UDim2.new(0.9, 0, 0, 0)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    controlsFrame.Parent = parent
    
    -- Add zoom controls
    self:CreateZoomButtons(controlsFrame)
end

-- Create zoom in/out buttons
function SpaceMapUI:CreateZoomButtons(parent)
    local zoomIn = Instance.new("TextButton")
    zoomIn.Size = UDim2.new(0.8, 0, 0.1, 0)
    zoomIn.Position = UDim2.new(0.1, 0, 0.1, 0)
    zoomIn.Text = "+"
    zoomIn.Parent = parent
    
    local zoomOut = Instance.new("TextButton")
    zoomOut.Size = UDim2.new(0.8, 0, 0.1, 0)
    zoomOut.Position = UDim2.new(0.1, 0, 0.25, 0)
    zoomOut.Text = "-"
    zoomOut.Parent = parent
    
    -- Add zoom functionality
    local mapScale = 1
    zoomIn.MouseButton1Click:Connect(function()
        mapScale = math.min(mapScale * 1.5, 10)
        self:UpdateMapScale(mapScale)
    end)
    
    zoomOut.MouseButton1Click:Connect(function()
        mapScale = math.max(mapScale / 1.5, 0.1)
        self:UpdateMapScale(mapScale)
    end)
end

-- Create trajectory display layer
function SpaceMapUI:CreateTrajectoryDisplay(parent)
    local trajectoryFrame = Instance.new("Frame")
    trajectoryFrame.Size = UDim2.new(1, 0, 1, 0)
    trajectoryFrame.BackgroundTransparency = 1
    trajectoryFrame.Name = "TrajectoryDisplay"
    trajectoryFrame.Parent = parent

    -- Create orbit prediction line
    local orbitLine = Instance.new("Frame")
    orbitLine.Size = UDim2.new(0, 2, 0, 2)
    orbitLine.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    orbitLine.Name = "OrbitLine"
    orbitLine.Parent = trajectoryFrame
end

-- Update trajectory display
function SpaceMapUI:UpdateTrajectoryDisplay()
    local vehicle = workspace.CurrentVehicle
    if not vehicle then return end

    local trajectory = OrbitSystem:CalculateTrajectory(
        vehicle.PrimaryPart.Position,
        vehicle.PrimaryPart.Velocity,
        workspace.Kerbin
    )

    -- Update orbit line positions
    local orbitLine = self.gui.TrajectoryDisplay.OrbitLine
    for i, pos in ipairs(trajectory) do
        local point = orbitLine:Clone()
        point.Position = self:WorldToMapPosition(pos)
        point.Parent = self.gui.TrajectoryDisplay
    end
end

-- Create maneuver node interface
function SpaceMapUI:CreateManeuverInterface(parent)
    local maneuverFrame = Instance.new("Frame")
    maneuverFrame.Size = UDim2.new(0.2, 0, 1, 0)
    maneuverFrame.Position = UDim2.new(0.8, 0, 0, 0)
    maneuverFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    maneuverFrame.Parent = parent

    -- Add node creation button
    local createButton = Instance.new("TextButton")
    createButton.Size = UDim2.new(0.8, 0, 0.1, 0)
    createButton.Position = UDim2.new(0.1, 0, 0.1, 0)
    createButton.Text = "Add Maneuver Node"
    createButton.Parent = maneuverFrame

    createButton.MouseButton1Click:Connect(function()
        self:CreateNewManeuverNode()
    end)
end

-- Create new maneuver node
function SpaceMapUI:CreateNewManeuverNode()
    local vehicle = workspace.CurrentVehicle
    if not vehicle then return end

    local node = AutopilotSystem:CreateManeuverNode(
        vehicle.PrimaryPart.Position,
        Vector3.new(0, 0, 0),
        workspace:GetServerTimeNow() + 60
    )

    -- Create visual representation
    local nodeIndicator = Instance.new("ImageButton")
    nodeIndicator.Size = UDim2.new(0, 20, 0, 20)
    nodeIndicator.Position = self:WorldToMapPosition(node.position)
    nodeIndicator.Image = "rbxassetid://node_icon"
    nodeIndicator.Parent = self.gui.TrajectoryDisplay

    -- Add drag functionality
    self:AddNodeDragBehavior(nodeIndicator, node)
end

-- Convert world position to map coordinates
function SpaceMapUI:WorldToMapPosition(worldPos)
    local mapScale = self.currentMapScale or 1
    local centerOffset = self.gui.AbsoluteSize / 2

    return UDim2.new(
        0, worldPos.X / mapScale + centerOffset.X,
        0, worldPos.Y / mapScale + centerOffset.Y
    )
end

-- Create planet indicators on map
function SpaceMapUI:CreatePlanetIndicators(parent)
    local planets = {
        Kerbin = {color = Color3.fromRGB(0, 255, 255)},
        Mun = {color = Color3.fromRGB(200, 200, 200)},
        Minmus = {color = Color3.fromRGB(200, 255, 200)},
        Duna = {color = Color3.fromRGB(255, 100, 0)}
    }
    
    for name, data in pairs(planets) do
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0.05, 0, 0.05, 0)
        indicator.BackgroundColor3 = data.color
        indicator.Name = name
        indicator.Parent = parent
        
        -- Add planet name label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0.3, 0)
        label.Position = UDim2.new(0, 0, -0.4, 0)
        label.Text = name
        label.TextColor3 = Color3.new(1, 1, 1)
        label.BackgroundTransparency = 1
        label.Parent = indicator
    end
end

return SpaceMapUI