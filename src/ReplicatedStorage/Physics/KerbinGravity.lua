-- Constants
local GRAVITY_ACCELERATION = 9.81 -- m/s²
local WORLD_SIZE = 16384 -- studs
local ATMOSPHERE_HEIGHT = 70000 -- studs
local GROUND_LEVEL = 0 -- studs
local ATMOSPHERE_LAYERS = 5 -- Number of atmospheric layers for visual effect
local DAY_CYCLE_PERIOD = 600 -- 10 minutes per day
local AURORA_HEIGHT = ATMOSPHERE_HEIGHT * 0.7 -- Height where auroras appear
local STAR_FADE_START = ATMOSPHERE_HEIGHT * 0.6 -- Height where stars start becoming visible

-- Debug logging function
local function LogDebug(system, message, ...)
    print(string.format("[KerbinGravity:%s] " .. message, system, ...))
end

-- Create flat world dimensions
KerbinGravity.Dimensions = {
    width = WORLD_SIZE,
    length = WORLD_SIZE,
    minHeight = GROUND_LEVEL,
    maxHeight = ATMOSPHERE_HEIGHT
}

function KerbinGravity:Init()
    self.gravityEnabled = true
    self.atmosphereColors = {
        day = {
            ground = Color3.fromRGB(120, 170, 255), -- Sky blue
            space = Color3.fromRGB(20, 30, 80), -- Dark space blue
            sunset = Color3.fromRGB(255, 150, 100) -- Sunset orange
        },
        night = {
            ground = Color3.fromRGB(40, 40, 80), -- Dark blue
            space = Color3.fromRGB(10, 10, 30), -- Very dark blue
            aurora = Color3.fromRGB(60, 255, 120) -- Aurora green
        }
    }

    -- Create basic world structure
    self:CreateGroundPlane()
    self:CreateAtmosphereLayers()
    self:CreateDynamicSkybox()
    self:SetupPlanetVisibility()
    self:CreateAuroraEffects()
    self:CreateStarField()

    -- Start cycles
    self:StartDayNightCycle()
end

-- Create ground plane (modified from original)
function KerbinGravity:CreateGroundPlane()
    local ground = Instance.new("Part")
    ground.Name = "KerbinSurface"
    ground.Anchored = true
    ground.Size = Vector3.new(WORLD_SIZE, 1, WORLD_SIZE)
    ground.Position = Vector3.new(0, GROUND_LEVEL - 0.5, 0)
    ground.TopSurface = Enum.SurfaceType.Smooth
    ground.BottomSurface = Enum.SurfaceType.Smooth
    ground.Parent = workspace
end

-- Create layered atmosphere effect (modified from original)
function KerbinGravity:CreateAtmosphereLayers()
    local atmosphereFolder = Instance.new("Folder")
    atmosphereFolder.Name = "KerbinAtmosphere"
    atmosphereFolder.Parent = workspace

    for i = 1, ATMOSPHERE_LAYERS do
        local layer = Instance.new("Part")
        layer.Name = "AtmosphereLayer" .. i
        layer.Shape = Enum.PartType.Ball
        local layerHeight = (ATMOSPHERE_HEIGHT / ATMOSPHERE_LAYERS) * i
        layer.Size = Vector3.new(WORLD_SIZE + layerHeight * 2, layerHeight * 2, WORLD_SIZE + layerHeight * 2)
        layer.Position = Vector3.new(0, 0, 0)
        local t = (i - 1) / (ATMOSPHERE_LAYERS - 1)
        local dayGroundColor = self.atmosphereColors.day.ground
        local daySpaceColor = self.atmosphereColors.day.space
        layer.Color = dayGroundColor:Lerp(daySpaceColor, t)
        layer.Transparency = 0.7 + (i * 0.05)
        layer.Material = Enum.Material.SmoothPlastic
        layer.CanCollide = false
        layer.Anchored = true

        local particles = Instance.new("ParticleEmitter")
        particles.Rate = math.max(5, 20 - (i * 3))
        particles.Lifetime = NumberRange.new(2, 4)
        particles.Speed = NumberRange.new(0.5, 1.5)
        particles.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.9),
            NumberSequenceKeypoint.new(1, 1)
        })
        particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 3),
            NumberSequenceKeypoint.new(0.5, 5),
            NumberSequenceKeypoint.new(1, 3)
        })
        particles.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, dayGroundColor),
            ColorSequenceKeypoint.new(1, daySpaceColor)
        })
        particles.Parent = layer

        layer.Parent = atmosphereFolder
    end

    LogDebug("Atmosphere", "Created %d atmospheric layers with gradient effects", ATMOSPHERE_LAYERS)
end

-- Create aurora effects
function KerbinGravity:CreateAuroraEffects()
    local auroraFolder = Instance.new("Folder")
    auroraFolder.Name = "KerbinAurora"
    auroraFolder.Parent = workspace

    -- Create multiple aurora curtains
    for i = 1, 3 do
        local aurora = Instance.new("Part")
        aurora.Name = "AuroraCurtain" .. i
        aurora.Transparency = 0.9
        aurora.CanCollide = false
        aurora.Anchored = true
        aurora.Size = Vector3.new(WORLD_SIZE * 0.5, ATMOSPHERE_HEIGHT * 0.3, 10)
        aurora.Position = Vector3.new(0, AURORA_HEIGHT, 0)

        -- Aurora particle effect
        local particles = Instance.new("ParticleEmitter")
        particles.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.atmosphereColors.night.aurora),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
            ColorSequenceKeypoint.new(1, self.atmosphereColors.night.aurora)
        })
        particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 20),
            NumberSequenceKeypoint.new(0.5, 40),
            NumberSequenceKeypoint.new(1, 20)
        })
        particles.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.6),
            NumberSequenceKeypoint.new(1, 0.8)
        })
        particles.Lifetime = NumberRange.new(2, 4)
        particles.Rate = 50
        particles.Speed = NumberRange.new(1, 3)
        particles.Parent = aurora

        aurora.Parent = auroraFolder
    end
end

-- Create star field that varies with altitude
function KerbinGravity:CreateStarField()
    local starField = Instance.new("Part")
    starField.Name = "StarField"
    starField.Size = Vector3.new(WORLD_SIZE * 2, WORLD_SIZE * 2, WORLD_SIZE * 2)
    starField.Transparency = 1
    starField.CanCollide = false
    starField.Anchored = true
    starField.Parent = workspace

    -- Create stars with varying brightness
    for i = 1, 1000 do
        local star = Instance.new("ParticleEmitter")
        star.Color = ColorSequence.new(Color3.new(1, 1, 1))
        star.Size = NumberSequence.new(math.random() * 2 + 0.5)
        star.Rate = 1
        star.Lifetime = NumberRange.new(math.huge)
        star.Speed = NumberRange.new(0)
        star.Parent = starField
    end
end

-- Start day/night cycle (modified from original)
function KerbinGravity:StartDayNightCycle()
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        local time = workspace:GetServerTimeNow()
        local dayPhase = (time % DAY_CYCLE_PERIOD) / DAY_CYCLE_PERIOD
        self:UpdateDayNightCycle(dayPhase)
    end)
end

-- Update atmosphere colors based on day/night cycle (modified from original)
function KerbinGravity:UpdateDayNightCycle(phase)
    local isDay = phase < 0.5
    local transitionFactor = math.abs(math.cos(phase * math.pi * 2))

    -- Update atmosphere colors
    for i = 1, ATMOSPHERE_LAYERS do
        local layer = workspace.KerbinAtmosphere:FindFirstChild("AtmosphereLayer" .. i)
        if layer then
            local t = (i - 1) / (ATMOSPHERE_LAYERS - 1)
            local groundColor = self.atmosphereColors.day.ground:Lerp(
                self.atmosphereColors.night.ground,
                1 - transitionFactor
            )
            local spaceColor = self.atmosphereColors.day.space:Lerp(
                self.atmosphereColors.night.space,
                1 - transitionFactor
            )
            layer.Color = groundColor:Lerp(spaceColor, t)

            -- Adjust particle effects
            local particles = layer:FindFirstChild("ParticleEmitter")
            if particles then
                particles.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, groundColor),
                    ColorSequenceKeypoint.new(1, spaceColor)
                })
            end
        end
    end

    -- Update lighting
    local lighting = game:GetService("Lighting")
    lighting.Ambient = Color3.new(0.5 * transitionFactor, 0.5 * transitionFactor, 0.6 * transitionFactor)
    lighting.Brightness = 0.3 + (0.7 * transitionFactor)
end

-- Create dynamic skybox that changes based on altitude (modified from original)
function KerbinGravity:CreateDynamicSkybox()
    local lighting = game:GetService("Lighting")

    -- Ground level skybox (blue sky)
    self.groundSkybox = Instance.new("Sky")
    self.groundSkybox.SkyboxBk = "rbxassetid://151165214"
    self.groundSkybox.SkyboxDn = "rbxassetid://151165197"
    self.groundSkybox.SkyboxFt = "rbxassetid://151165224"
    self.groundSkybox.SkyboxLf = "rbxassetid://151165191"
    self.groundSkybox.SkyboxRt = "rbxassetid://151165206"
    self.groundSkybox.SkyboxUp = "rbxassetid://151165227"
    self.groundSkybox.Parent = lighting

    -- Space skybox (stars and space)
    self.spaceSkybox = Instance.new("Sky")
    self.spaceSkybox.SkyboxBk = "rbxassetid://151165214" -- Replace with space texture
    self.spaceSkybox.SkyboxDn = "rbxassetid://151165197"
    self.spaceSkybox.SkyboxFt = "rbxassetid://151165224"
    self.spaceSkybox.SkyboxLf = "rbxassetid://151165191"
    self.spaceSkybox.SkyboxRt = "rbxassetid://151165206"
    self.spaceSkybox.SkyboxUp = "rbxassetid://151165227"
    self.spaceSkybox.Parent = lighting
    self.spaceSkybox.Enabled = false

    LogDebug("Skybox", "Created dynamic skybox system")
end

-- Set up planet visibility based on altitude (modified from original)
function KerbinGravity:SetupPlanetVisibility()
    game:GetService("RunService").Heartbeat:Connect(function()
        self:UpdateVisibility()
    end)
end

-- Update visibility of planets and skybox based on altitude (modified from original)
function KerbinGravity:UpdateVisibility()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local altitude = camera.CFrame.Position.Y
    local inAtmosphere = self:IsInAtmosphere(camera.CFrame.Position)
    local transitionHeight = ATMOSPHERE_HEIGHT * 0.8
    local starVisibilityFactor = math.clamp((altitude - STAR_FADE_START) / (ATMOSPHERE_HEIGHT - STAR_FADE_START), 0, 1)

    -- Update skybox transitions
    self.groundSkybox.Enabled = inAtmosphere
    self.spaceSkybox.Enabled = not inAtmosphere

    -- Update atmospheric layers
    for i = 1, ATMOSPHERE_LAYERS do
        local layer = workspace.KerbinAtmosphere:FindFirstChild("AtmosphereLayer" .. i)
        if layer then
            local baseTransparency = 0.7 + (i * 0.05)
            local heightFactor = math.clamp((altitude - transitionHeight) / (ATMOSPHERE_HEIGHT - transitionHeight), 0, 1)
            layer.Transparency = baseTransparency + (heightFactor * 0.3)
        end
    end

    -- Update aurora visibility
    local auroraFolder = workspace:FindFirstChild("KerbinAurora")
    if auroraFolder then
        for _, aurora in ipairs(auroraFolder:GetChildren()) do
            local auroraVisibility = math.clamp((altitude - AURORA_HEIGHT * 0.8) / (AURORA_HEIGHT * 0.2), 0, 1)
            aurora.Transparency = 0.9 - (auroraVisibility * 0.3)
        end
    end

    -- Update star visibility
    local starField = workspace:FindFirstChild("StarField")
    if starField then
        for _, star in ipairs(starField:GetChildren()) do
            if star:IsA("ParticleEmitter") then
                star.Rate = starVisibilityFactor > 0.1 and 1 or 0
                star.Transparency = NumberSequence.new(1 - starVisibilityFactor)
            end
        end
    end

    -- Update planet visibility with atmospheric scattering
    for _, planet in ipairs(workspace.Planets:GetChildren()) do
        if planet.Name == "Sun" or planet.Name == "Mun" then
            -- Apply atmospheric scattering to celestial bodies
            local elevation = math.atan2(planet.Position.Y - camera.CFrame.Position.Y, 
                (planet.Position - camera.CFrame.Position).Magnitude)
            local scatteringFactor = math.clamp(1 - math.abs(elevation) / (math.pi * 0.3), 0, 1)

            if inAtmosphere then
                planet.Color = planet.Color:Lerp(self.atmosphereColors.day.sunset, scatteringFactor)
            end
            planet.Transparency = 0
        else
            planet.Transparency = math.min(1, inAtmosphere and 1 or (1 - starVisibilityFactor))
            local atmosphere = workspace:FindFirstChild(planet.Name .. "Atmosphere")
            if atmosphere then
                atmosphere.Transparency = math.min(1, inAtmosphere and 1 or (0.9 - starVisibilityFactor * 0.1))
            end
        end
    end
end

-- Check if position is within Kerbin's atmosphere
function KerbinGravity:IsInAtmosphere(position)
    if math.abs(position.X) > WORLD_SIZE/2 or math.abs(position.Z) > WORLD_SIZE/2 then
        return false
    end
    return position.Y < ATMOSPHERE_HEIGHT and position.Y > GROUND_LEVEL
end

-- Calculate atmospheric density at given height (for physics calculations)
function KerbinGravity:GetAtmosphericDensity(height)
    if height < GROUND_LEVEL or height > ATMOSPHERE_HEIGHT then
        return 0
    end
    local baseAtmosphere = 1.0
    local atmosphereScale = 5000 -- scale height in studs
    return baseAtmosphere * math.exp(-height / atmosphereScale)
end

-- Apply gravity to a part
function KerbinGravity:ApplyGravity(part)
    if not self.gravityEnabled then return end

    local pos = part.Position
    if not self:IsInAtmosphere(pos) then return end

    local mass = part:GetMass()
    local force = Vector3.new(0, -GRAVITY_ACCELERATION * mass, 0)

    local gravityForce = Instance.new("VectorForce")
    gravityForce.Force = force
    gravityForce.Parent = part

    local attachment = Instance.new("Attachment")
    attachment.Parent = part
    gravityForce.Attachment0 = attachment

    LogDebug("Gravity", "Applied gravity force of %d N to object at Y=%d", force.Y, pos.Y)
end

return KerbinGravity