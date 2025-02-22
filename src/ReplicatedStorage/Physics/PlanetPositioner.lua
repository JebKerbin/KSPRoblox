local SolarSystemScaler = require(script.Parent.SolarSystemScaler)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Debug flag
local DEBUG_MODE = true

local PlanetPositioner = {}

function PlanetPositioner:Init()
    self.planets = {}
    self.scaledParams = SolarSystemScaler:GetScaledParameters()

    -- Create container for all celestial bodies
    self.solarSystem = Instance.new("Folder")
    self.solarSystem.Name = "SolarSystem"
    self.solarSystem.Parent = workspace

    -- Initialize planet positions
    self:PositionPlanets()

    -- Add frame skip tracking for optimization
    self.frameCount = 0
    self.updateInterval = 1 -- Base update interval in frames

    -- Start orbital updates with dynamic time scaling and optimization
    RunService.Heartbeat:Connect(function(dt)
        self.frameCount = self.frameCount + 1
        self:UpdateOrbits(dt)
    end)

    if DEBUG_MODE then
        self:CreateDebugUI()
        self:CreateVelocityVisualizers()
        self:CreateOrbitVisualizers()
    end
end

function PlanetPositioner:CreateDebugUI()
    local debugUI = Instance.new("ScreenGui")
    debugUI.Name = "PlanetDebug"

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.2, 0, 0.4, 0)
    frame.Position = UDim2.new(0.8, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.Parent = debugUI

    self.debugLabels = {}
    local yPos = 0.05

    for planetName, _ in pairs(self.planets) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.9, 0, 0.1, 0)
        label.Position = UDim2.new(0.05, 0, yPos, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        self.debugLabels[planetName] = label
        yPos = yPos + 0.15
    end

    -- Add to StarterGui for all players
    debugUI.Parent = game:GetService("StarterGui")
end

function PlanetPositioner:UpdateDebugUI()
    for planetName, planetData in pairs(self.planets) do
        local label = self.debugLabels[planetName]
        if label then
            local velocity = planetData.model.PrimaryPart.Velocity
            label.Text = string.format("%s:\nDist: %.1f\nVel: %.1f\nPeriod: %.1f",
                planetName,
                planetData.orbitRadius,
                velocity.Magnitude,
                planetData.orbitPeriod
            )
        end
    end
end

function PlanetPositioner:PositionPlanets()
    for planetName, params in pairs(self.scaledParams) do
        local planet = workspace:FindFirstChild(planetName)
        if planet then
            -- Store original parameters
            self.planets[planetName] = {
                model = planet,
                orbitRadius = params.orbitRadius,
                orbitAngle = math.random() * math.pi * 2, -- Random starting position
                orbitPeriod = SolarSystemScaler:GetOrbitalPeriod(params.orbitRadius),
                eccentricity = 0.1 -- Add slight elliptical orbits
            }

            -- Set initial size
            if planet.PrimaryPart then
                planet.PrimaryPart.Size = params.size
                -- Add trail for orbit visualization
                local trail = Instance.new("Trail")
                trail.Lifetime = 1
                trail.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
                trail.Transparency = NumberSequence.new(0.5)
                trail.Parent = planet.PrimaryPart
            end

            -- Set initial position
            self:UpdatePlanetPosition(planetName, self.planets[planetName].orbitAngle)

            if DEBUG_MODE then
                print(string.format("[PlanetPositioner] Positioned %s at radius %.2f",
                    planetName, params.orbitRadius))
            end
        else
            warn(string.format("[PlanetPositioner] Planet %s not found in workspace", planetName))
        end
    end
end

function PlanetPositioner:UpdatePlanetPosition(planetName, angle)
    local planetData = self.planets[planetName]
    if not planetData then return end

    -- Calculate position with elliptical orbit
    local r = planetData.orbitRadius * (1 - planetData.eccentricity * math.cos(angle))
    local x = r * math.cos(angle)
    local z = r * math.sin(angle)

    -- Calculate orbital velocity
    local period = planetData.orbitPeriod
    local velocity = Vector3.new(
        -math.sin(angle),
        0,
        math.cos(angle)
    ).Unit * (2 * math.pi * r / period)

    -- Update position and velocity
    if planetData.model and planetData.model.PrimaryPart then
        planetData.model:SetPrimaryPartCFrame(
            CFrame.new(Vector3.new(x, 0, z))
        )
        planetData.model.PrimaryPart.Velocity = velocity
    end
end

function PlanetPositioner:UpdateOrbits(dt)
    for planetName, planetData in pairs(self.planets) do
        -- Determine update frequency based on orbital period
        local updateFrequency = math.max(1, math.floor(planetData.orbitPeriod / 100))

        -- Only update if it's time for this planet
        if self.frameCount % updateFrequency == 0 then
            -- Update orbit angle based on period
            planetData.orbitAngle = planetData.orbitAngle +
                (2 * math.pi * dt / planetData.orbitPeriod)

            -- Keep angle in range [0, 2π]
            while planetData.orbitAngle >= 2 * math.pi do
                planetData.orbitAngle = planetData.orbitAngle - 2 * math.pi
            end

            -- Update position
            self:UpdatePlanetPosition(planetName, planetData.orbitAngle)
        end
    end

    -- Update debug visualizations
    if DEBUG_MODE and self.frameCount % 2 == 0 then
        self:UpdateDebugUI()
        self:UpdateVelocityVisualizers()
    end
end

-- Add velocity vector visualization for debug mode
function PlanetPositioner:CreateVelocityVisualizers()
    for planetName, planetData in pairs(self.planets) do
        local velocityArrow = Instance.new("Part")
        velocityArrow.Name = planetName .. "VelocityVector"
        velocityArrow.Anchored = true
        velocityArrow.CanCollide = false
        velocityArrow.Size = Vector3.new(5, 0.5, 0.5)
        velocityArrow.Color = Color3.fromRGB(255, 255, 0)
        velocityArrow.Transparency = 0.5
        velocityArrow.Parent = self.solarSystem

        planetData.velocityVisualizer = velocityArrow
    end
end

function PlanetPositioner:UpdateVelocityVisualizers()
    for planetName, planetData in pairs(self.planets) do
        if planetData.velocityVisualizer and planetData.model and planetData.model.PrimaryPart then
            local velocity = planetData.model.PrimaryPart.Velocity
            local position = planetData.model.PrimaryPart.Position

            -- Scale arrow by velocity magnitude
            local scaledSize = math.min(velocity.Magnitude / 10, 20)
            planetData.velocityVisualizer.Size = Vector3.new(scaledSize, 0.5, 0.5)

            -- Orient arrow in velocity direction
            local direction = velocity.Unit
            local cf = CFrame.new(position, position + direction)
            planetData.velocityVisualizer.CFrame = cf * CFrame.new(scaledSize/2, 0, 0)
        end
    end
end

-- Create visual orbit paths with level of detail
function PlanetPositioner:CreateOrbitVisualizers()
    for planetName, planetData in pairs(self.planets) do
        local orbitPath = Instance.new("Folder")
        orbitPath.Name = planetName .. "Orbit"
        orbitPath.Parent = self.solarSystem

        -- Calculate number of segments based on orbit size
        local baseSegments = 720 -- Base number of segments for closest orbit
        local orbitRatio = planetData.orbitRadius / self.scaledParams.Kerbin.orbitRadius
        local segments = math.max(60, math.floor(baseSegments / math.sqrt(orbitRatio)))

        -- Create detailed orbit visualization
        for i = 0, segments - 1 do
            local angle = (i / segments) * 2 * math.pi
            local r = planetData.orbitRadius * (1 - planetData.eccentricity * math.cos(angle))
            local x = r * math.cos(angle)
            local z = r * math.sin(angle)

            local point = Instance.new("Part")
            point.Anchored = true
            point.CanCollide = false
            point.Size = Vector3.new(0.1, 0.1, 0.1)
            point.Position = Vector3.new(x, 0, z)
            point.Transparency = 0.8
            point.Parent = orbitPath

            -- Add attachments for beams
            local attachment = Instance.new("Attachment")
            attachment.Parent = point
            point.Attachment0 = attachment

            -- Add beam to previous point
            if i > 0 then
                local line = Instance.new("Beam")
                line.Width0 = 0.1
                line.Width1 = 0.1
                line.Transparency = NumberSequence.new(0.8)
                -- Customize orbit line color based on planet
                if planetName == "Eve" then
                    line.Color = ColorSequence.new(Color3.fromRGB(180, 160, 200)) -- Purple for Eve
                elseif planetName == "Duna" then
                    line.Color = ColorSequence.new(Color3.fromRGB(200, 160, 140)) -- Reddish for Duna
                elseif planetName == "Jool" then
                    line.Color = ColorSequence.new(Color3.fromRGB(160, 200, 160)) -- Greenish for Jool
                else
                    line.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200)) -- Default white
                end
                line.Attachment0 = point.Attachment0
                line.Attachment1 = orbitPath:GetChildren()[i].Attachment0
                line.Parent = point
            end
        end

        -- Close the orbit by connecting last and first points
        local lastPoint = orbitPath:GetChildren()[segments - 1]
        local firstPoint = orbitPath:GetChildren()[1]
        if lastPoint and firstPoint then
            local line = Instance.new("Beam")
            line.Width0 = 0.1
            line.Width1 = 0.1
            line.Transparency = NumberSequence.new(0.8)
            if planetName == "Eve" then
                line.Color = ColorSequence.new(Color3.fromRGB(180, 160, 200))
            elseif planetName == "Duna" then
                line.Color = ColorSequence.new(Color3.fromRGB(200, 160, 140))
            elseif planetName == "Jool" then
                line.Color = ColorSequence.new(Color3.fromRGB(160, 200, 160))
            else
                line.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
            end
            line.Attachment0 = lastPoint.Attachment0
            line.Attachment1 = firstPoint.Attachment0
            line.Parent = lastPoint
        end

        -- Add atmosphere visualization
        if planetData.model and planetData.model.PrimaryPart then
            local atmosphere = Instance.new("Atmosphere")
            atmosphere.Name = planetName .. "Atmosphere"

            -- Customize atmosphere based on planet
            if planetName == "Eve" then
                -- Dense, purple-tinted atmosphere
                atmosphere.Density = 0.5
                atmosphere.Color = Color3.fromRGB(180, 160, 200)
                atmosphere.Decay = Color3.fromRGB(140, 120, 160)
                atmosphere.Glare = 0.4
                atmosphere.Haze = 0.6
            elseif planetName == "Duna" then
                -- Thin, reddish atmosphere
                atmosphere.Density = 0.2
                atmosphere.Color = Color3.fromRGB(200, 160, 140)
                atmosphere.Decay = Color3.fromRGB(160, 120, 100)
                atmosphere.Glare = 0.3
                atmosphere.Haze = 0.8
            else -- Kerbin
                -- Earth-like atmosphere
                atmosphere.Density = 0.3
                atmosphere.Color = Color3.fromRGB(170, 190, 210)
                atmosphere.Decay = Color3.fromRGB(130, 150, 170)
                atmosphere.Glare = 0.25
                atmosphere.Haze = 0.4
            end

            atmosphere.Parent = planetData.model
        end

        if DEBUG_MODE then
            print(string.format("[PlanetPositioner] Created orbit visualization for %s with %d segments",
                planetName, segments))
        end
    end
end

return PlanetPositioner