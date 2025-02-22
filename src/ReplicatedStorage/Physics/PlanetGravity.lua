local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Debug mode for development
local DEBUG_MODE = true

-- Debug logging function with immediate output and visual separation
local function LogDebug(system, planet, message, ...)
    if DEBUG_MODE then
        print("\n-------------------------------------------")
        print(string.format("[PlanetGravity:%s:%s] " .. message, system, planet, ...))
        print("-------------------------------------------\n")
    end
end

local PlanetGravity = {}

-- Enhanced planet data with KSP-accurate values
PlanetGravity.SolarSystem = {
    Sun = {
        radius = 2048,
        gravity = 28.0,
        isSpherical = true,
        isStar = true,
        surfaceColor = Color3.fromRGB(255, 200, 50),
        surfaceMaterial = Enum.Material.Neon,
        emissiveColor = Color3.fromRGB(255, 255, 200),
        brightness = 2,
        notes = "Central star, primary gravity source"
    }
}

-- Planet data with KSP-accurate values
PlanetGravity.Planets = {
    Kerbin = {
        radius = 2048,
        gravity = 9.81,
        hasAtmosphere = true,
        atmosphereDensity = 1.0,
        meshId = "kerbin_mesh_id",
        surfaceTextureId = "kerbin_texture_id",
        normalMapId = "kerbin_normal_map_id",
        cloudTextureId = "kerbin_clouds_id",
        hasCloudLayers = true,
        atmosphereColor = Color3.fromRGB(140, 180, 255),
        orbitRadius = 300000,
        orbitPeriod = 300,
        orbitInclination = 0,
        atmosphereHeight = 70000, -- Atmosphere height in meters
        dayLength = 6 * 3600, -- 6 hours in seconds
        notes = "Home planet with Earth-like atmosphere"
    },
    Mun = {
        radius = 1024,
        gravity = 1.63,
        hasAtmosphere = false,
        meshId = "mun_mesh_id",
        surfaceTextureId = "mun_texture_id",
        normalMapId = "mun_normal_map_id",
        craterDensity = 0.8,
        orbitRadius = 15000,
        orbitPeriod = 50,
        parentBody = "Kerbin",
        notes = "No atmosphere"
    },
    Duna = {
        radius = 2048,
        gravity = 2.94,
        hasAtmosphere = true,
        atmosphereDensity = 0.2,
        meshId = "duna_mesh_id",
        surfaceTextureId = "duna_texture_id",
        hasDustStorms = true,
        atmosphereColor = Color3.fromRGB(255, 150, 100),
        hasIceCaps = true,
        orbitRadius = 500000,
        orbitPeriod = 600,
        orbitInclination = math.rad(5),
        atmosphereHeight = 50000,
        notes = "Thin atmosphere, dust storms"
    },
    Eve = {
        radius = 3072,  -- Increased substantially
        gravity = 16.7,
        hasAtmosphere = true,
        atmosphereDensity = 5.0,
        meshId = "eve_mesh_id",
        surfaceTextureId = "eve_texture_id",
        atmosphereColor = Color3.fromRGB(255, 180, 255),
        hasCloudLayers = true,
        orbitRadius = 200000,  -- Closer to Sun than Kerbin
        orbitPeriod = 200,
        orbitInclination = math.rad(3),
        notes = "Thick atmosphere, hardest return"
    },
    Jool = {
        radius = 8192,  -- Massive gas giant
        gravity = 7.85,
        hasAtmosphere = true,
        atmosphereDensity = 3.0,
        meshId = "jool_mesh_id",
        surfaceTextureId = "jool_texture_id",
        atmosphereColor = Color3.fromRGB(120, 255, 120),
        hasStormBands = true,
        orbitRadius = 1000000,  -- Very far from Sun
        orbitPeriod = 1200,
        orbitInclination = math.rad(2),
        notes = "Gas giant, no surface"
    },
    Laythe = {
        radius = 1536,  -- Increased moon size
        gravity = 5.82,
        hasAtmosphere = true,
        atmosphereDensity = 1.0,
        meshId = "laythe_mesh_id",
        surfaceTextureId = "laythe_texture_id",
        hasOxygen = true,
        atmosphereColor = Color3.fromRGB(180, 220, 255),
        hasWaves = true,
        orbitRadius = 24000,  -- Orbit around Jool
        orbitPeriod = 100,
        orbitInclination = math.rad(10),
        parentBody = "Jool",
        notes = "Water moon with oxygen atmosphere"
    },
    Minmus = {
        radius = 512,   -- Increased from 256
        gravity = 0.49,
        hasAtmosphere = false,
        meshId = "minmus_mesh_id",
        surfaceTextureId = "minmus_texture_id",
        hasIceFlats = true,
        orbitRadius = 36000,  -- Further from Kerbin
        orbitPeriod = 150,
        orbitInclination = math.rad(15),
        parentBody = "Kerbin",
        notes = "Low gravity"
    }
}

function PlanetGravity:Init()
    print("\n========== PLANET GRAVITY INITIALIZATION START ==========\n")

    self.activeGravityFields = {}
    LogDebug("Init", "System", "Initializing planetary gravity system")

    -- Create workspace organization
    self:CreateWorkspaceFolders()

    -- Initialize atmosphere system
    self:InitializeAtmosphereSystem()

    -- Start gravity updates
    RunService.Heartbeat:Connect(function(dt)
        self:UpdateGravityFields(dt)
    end)

    self:InitializeOrbits()

    print("\n========== PLANET GRAVITY INITIALIZATION COMPLETE ==========\n")
    return true
end

function PlanetGravity:InitializeAtmosphereSystem()
    -- Set up atmosphere rendering and effects
    for planetName, planetData in pairs(self.Planets) do
        if planetData.hasAtmosphere then
            self:SetupAtmosphere(planetName, planetData)
        end
    end
end

function PlanetGravity:SetupAtmosphere(planetName, planetData)
    local planet = workspace.Planets:FindFirstChild(planetName)
    if not planet then return end

    -- Create atmosphere object
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = planetData.atmosphereDensity
    atmosphere.Color = planetData.atmosphereColor
    atmosphere.Decay = planetData.atmosphereColor:Lerp(Color3.new(0, 0, 0), 0.5)
    atmosphere.Glare = 0.5
    atmosphere.Haze = 0.5
    atmosphere.Parent = planet

    -- Set up day/night cycle for Kerbin
    if planetName == "Kerbin" then
        local lighting = game:GetService("Lighting")
        lighting.ClockTime = 14 -- Start at 2 PM
        lighting.GeographicLatitude = 0

        -- Create space atmosphere transition
        local spaceAtmosphere = Instance.new("Atmosphere")
        spaceAtmosphere.Name = "SpaceAtmosphere"
        spaceAtmosphere.Density = 0
        spaceAtmosphere.Color = Color3.new(0, 0, 0)
        spaceAtmosphere.Parent = lighting

        -- Update atmosphere based on altitude
        RunService.Heartbeat:Connect(function()
            self:UpdateKerbinAtmosphere()
        end)
    end
end

function PlanetGravity:UpdateKerbinAtmosphere()
    local player = game.Players.LocalPlayer
    if not player or not player.Character then return end

    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local kerbin = workspace.Planets:FindFirstChild("Kerbin")
    if not kerbin then return end

    -- Calculate altitude
    local altitude = (humanoidRootPart.Position - kerbin.Position).Magnitude - kerbin.Size.X/2
    local atmosphereHeight = self.Planets.Kerbin.atmosphereHeight

    -- Update atmosphere visibility based on altitude
    local atmosphere = kerbin:FindFirstChild("Atmosphere")
    if atmosphere then
        local atmosphereDensity = math.max(0, 1 - (altitude / atmosphereHeight))
        atmosphere.Density = atmosphereDensity

        -- Make space visible at high altitudes or night
        local lighting = game:GetService("Lighting")
        local timeOfDay = lighting.ClockTime
        local isNight = timeOfDay < 6 or timeOfDay > 18

        if altitude > atmosphereHeight * 0.7 or isNight then
            lighting.Ambient = Color3.new(0, 0, 0)
            lighting.OutdoorAmbient = Color3.new(0.05, 0.05, 0.05)
        else
            lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
            lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        end
    end
end

-- Calculate gravity force based on distance and mass
function PlanetGravity:CalculateGravityForce(planet, position, mass)
    local planetData = self.Planets[planet.Name]
    if not planetData then return Vector3.new(0, 0, 0) end

    local distance = (position - planet.Position).Magnitude
    local surfaceGravity = planetData.gravity
    local planetRadius = planetData.radius

    -- Calculate gravity using inverse square law
    local gravityStrength = surfaceGravity * ((planetRadius * planetRadius) / (distance * distance))
    local direction = (planet.Position - position).Unit

    return direction * gravityStrength * mass
end

-- Apply gravity to an object
function PlanetGravity:ApplyGravity(object)
    if not object:IsA("BasePart") then return end

    local mass = object:GetMass()
    local gravityForce = Instance.new("VectorForce")
    gravityForce.Name = "PlanetaryGravity"
    gravityForce.Attachment0 = object:FindFirstChild("GravityAttachment") or Instance.new("Attachment", object)

    -- Update gravity force every frame
    RunService.Heartbeat:Connect(function()
        local totalForce = Vector3.new(0, 0, 0)

        -- Calculate gravity from each celestial body
        for _, planet in ipairs(workspace.Planets:GetChildren()) do
            local force = self:CalculateGravityForce(planet, object.Position, mass)
            totalForce = totalForce + force
        end

        gravityForce.Force = totalForce
    end)

    gravityForce.Parent = object
end

function PlanetGravity:CreateWorkspaceFolders()
    local folders = {"Planets", "Asteroids", "SpaceDebris"}
    for _, folderName in ipairs(folders) do
        if not workspace:FindFirstChild(folderName) then
            local folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = workspace
            LogDebug("Init", "System", "Created workspace folder: " .. folderName)
        end
    end
end

function PlanetGravity:CreateSun()
    local sunData = self.SolarSystem.Sun
    LogDebug("Create", "Sun", "Creating sun with radius=%d", sunData.radius)

    local sun = Instance.new("Part")
    sun.Name = "Sun"
    sun.Shape = Enum.PartType.Ball
    sun.Size = Vector3.new(sunData.radius * 2, sunData.radius * 2, sunData.radius * 2)
    sun.Position = Vector3.new(0, 0, 0)
    sun.Anchored = true
    sun.Color = sunData.surfaceColor
    sun.Material = sunData.surfaceMaterial

    -- Add light source
    local light = Instance.new("PointLight")
    light.Color = sunData.emissiveColor
    light.Brightness = sunData.brightness
    light.Range = sunData.radius * 10
    light.Parent = sun

    -- Add glow effect
    local glow = Instance.new("ParticleEmitter")
    glow.Color = ColorSequence.new(sunData.emissiveColor)
    glow.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, sunData.radius * 0.1),
        NumberSequenceKeypoint.new(1, sunData.radius * 0.2)
    })
    glow.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    glow.Rate = 50
    glow.Speed = NumberRange.new(1, 5)
    glow.Parent = sun

    sun.Parent = workspace.Planets
    LogDebug("Create", "Sun", "Sun created successfully")
end


function PlanetGravity:CreatePlanet(name, data)
    LogDebug("Create", name, "Creating planet with radius=%d, gravity=%.2f, notes: %s",
        data.radius, data.gravity, data.notes)

    -- Create main planet body as MeshPart
    local planet = Instance.new("MeshPart")
    planet.Name = name
    planet.Size = Vector3.new(data.radius * 2, data.radius * 2, data.radius * 2)
    planet.Position = Vector3.new(0, 0, 0)
    planet.Anchored = true

    -- Set mesh asset
    planet.MeshId = "rbxassetid://" .. data.meshId -- Mesh ID will be specified in planet data

    -- Add textures
    local surfaceTexture = Instance.new("Decal")
    surfaceTexture.Name = "SurfaceTexture"
    surfaceTexture.Texture = "rbxassetid://" .. data.surfaceTextureId
    surfaceTexture.Face = Enum.NormalId.Front
    surfaceTexture.Parent = planet

    -- Add normal map if available
    if data.normalMapId then
        local normalMap = Instance.new("Decal")
        normalMap.Name = "NormalMap"
        normalMap.Texture = "rbxassetid://" .. data.normalMapId
        normalMap.Face = Enum.NormalId.Front
        normalMap.Parent = planet
    end

    -- Add atmosphere if applicable
    if data.hasAtmosphere then
        local atmosphere = Instance.new("Part")
        atmosphere.Name = name .. "Atmosphere"
        atmosphere.Shape = Enum.PartType.Ball
        atmosphere.Size = planet.Size * 1.2
        atmosphere.Position = planet.Position
        atmosphere.Transparency = 0.95
        atmosphere.CanCollide = false
        atmosphere.Material = Enum.Material.ForceField
        atmosphere.Color = data.atmosphereColor or Color3.fromRGB(200, 200, 255)

        -- Add atmosphere effects (handled by InitializeAtmosphereSystem now)
    end

    -- Add clouds if applicable
    if data.hasCloudLayers then
        local cloudLayer = Instance.new("MeshPart")
        cloudLayer.Name = name .. "Clouds"
        cloudLayer.Size = planet.Size * 1.1
        cloudLayer.Position = planet.Position
        cloudLayer.Transparency = 0.7
        cloudLayer.CanCollide = false
        cloudLayer.Material = Enum.Material.SmoothPlastic

        -- Add cloud texture
        local cloudTexture = Instance.new("Decal")
        cloudTexture.Texture = "rbxassetid://" .. data.cloudTextureId
        cloudTexture.Face = Enum.NormalId.Front
        cloudTexture.Transparency = 0.3
        cloudTexture.Parent = cloudLayer

        cloudLayer.Parent = planet
    end

    planet.Parent = workspace.Planets

    LogDebug("Create", name, "Planet created successfully with all components")
    return planet
end

function PlanetGravity:CreateEnhancedDustStorms(atmosphere, data)
    local dustStorm = Instance.new("ParticleEmitter")
    dustStorm.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(170, 80, 40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 80, 40))
    })
    dustStorm.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3),
        NumberSequenceKeypoint.new(0.5, 5),
        NumberSequenceKeypoint.new(1, 3)
    })
    dustStorm.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0.8)
    })
    dustStorm.Rate = 50
    dustStorm.Lifetime = NumberRange.new(2, 4)
    dustStorm.Speed = NumberRange.new(10, 20)
    dustStorm.Parent = atmosphere
end

function PlanetGravity:CreateDynamicCloudLayers(atmosphere, data)
    local cloudLayer = Instance.new("Part")
    cloudLayer.Shape = Enum.PartType.Ball
    cloudLayer.Size = atmosphere.Size * 0.95
    cloudLayer.Position = atmosphere.Position
    cloudLayer.Color = Color3.new(1, 1, 1)
    cloudLayer.Material = Enum.Material.ForceField
    cloudLayer.Transparency = 0.6
    cloudLayer.CanCollide = false
    cloudLayer.Anchored = true

    -- Add cloud movement and formation effects
    local cloudParticles = Instance.new("ParticleEmitter")
    cloudParticles.Color = ColorSequence.new(Color3.new(1, 1, 1))
    cloudParticles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, data.radius * 0.05),
        NumberSequenceKeypoint.new(0.5, data.radius * 0.1),
        NumberSequenceKeypoint.new(1, data.radius * 0.05)
    })
    cloudParticles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0.7)
    })
    cloudParticles.Rate = 20
    cloudParticles.Lifetime = NumberRange.new(5, 8)
    cloudParticles.Speed = NumberRange.new(1, 2)
    cloudParticles.Parent = cloudLayer

    -- Add cloud rotation
    local cloudRotation = Instance.new("NumberValue")
    cloudRotation.Name = "CloudRotation"
    cloudRotation.Value = 0
    cloudRotation.Parent = cloudLayer

    game:GetService("RunService").Heartbeat:Connect(function(dt)
        cloudRotation.Value = (cloudRotation.Value + dt * 0.1) % (2 * math.pi)
        cloudLayer.CFrame = CFrame.new(atmosphere.Position) *
            CFrame.fromEulerAnglesXYZ(0, cloudRotation.Value, cloudRotation.Value * 0.5)
    end)

    cloudLayer.Parent = atmosphere
end

function PlanetGravity:AddEnhancedPlanetaryRings(planet, data)
    local ringRadius = planet.Size.X * 1.5
    local ringThickness = planet.Size.X * 0.01

    -- Create main ring structure
    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(ringThickness, ringRadius * 2, ringRadius * 2)
    ring.CFrame = CFrame.new(planet.Position) * CFrame.Angles(math.pi / 2, 0, 0)
    ring.Transparency = 0.5
    ring.CanCollide = false
    ring.Material = Enum.Material.Glass
    ring.Color = Color3.fromRGB(200, 200, 150)

    -- Add ring particle effects
    local ringParticles = Instance.new("ParticleEmitter")
    ringParticles.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 150))
    })
    ringParticles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 1)
    })
    ringParticles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0.7)
    })
    ringParticles.Rate = 100
    ringParticles.Lifetime = NumberRange.new(5, 8)
    ringParticles.Speed = NumberRange.new(1, 2)
    ringParticles.Parent = ring

    ring.Parent = planet
end

function PlanetGravity:CreateWaterEffects(planet, data)
    local waterEffect = Instance.new("ParticleEmitter")
    waterEffect.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
    waterEffect.Transparency = NumberSequence.new(0.5)
    waterEffect.Size = NumberSequence.new(2)
    waterEffect.Rate = 20
    waterEffect.Lifetime = NumberRange.new(1, 2)
    waterEffect.Parent = planet
    LogDebug("Create", planet.Name, "Added water surface effects")
end

function PlanetGravity:AddEnhancedCraters(planet, data)
    local numCraters = math.floor(data.radius / 50 * (data.craterDensity or 0.5))
    for i = 1, numCraters do
        local crater = Instance.new("Part")
        crater.Shape = Enum.PartType.Ball
        crater.Size = Vector3.new(data.radius * 0.1 * math.random(0.5, 1.5), data.radius * 0.02 * math.random(0.5, 1.5), data.radius * 0.1 * math.random(0.5, 1.5))
        local angle = math.random() * math.pi * 2
        local elevation = math.random() * math.pi - math.pi / 2
        local x = math.cos(angle) * math.cos(elevation)
        local y = math.sin(elevation)
        local z = math.sin(angle) * math.cos(elevation)
        crater.Position = planet.Position + Vector3.new(x, y, z) * data.radius
        crater.Color = planet.Color:Lerp(Color3.new(0, 0, 0), 0.2)
        crater.Material = planet.Material
        crater.Parent = planet
    end
end


function PlanetGravity:CreateSurfaceEffects(planet, data)
    -- Add ice caps for Duna
    if data.hasIceCaps then
        for _, pole in ipairs({"North", "South"}) do
            local iceCap = Instance.new("Part")
            iceCap.Shape = Enum.PartType.Ball
            iceCap.Size = Vector3.new(data.radius * 0.4, data.radius * 0.1, data.radius * 0.4)
            iceCap.Color = Color3.fromRGB(255, 255, 255)
            iceCap.Material = Enum.Material.Ice
            iceCap.Position = planet.Position + Vector3.new(0, (pole == "North" and 1 or -1) * data.radius * 0.9, 0)
            iceCap.Parent = planet
        end
        LogDebug("Surface", data.name, "Added polar ice caps")
    end

    -- Add ice flats for Minmus
    if data.hasIceFlats then
        local numFlats = 5
        for i = 1, numFlats do
            local iceFlat = Instance.new("Part")
            iceFlat.Shape = Enum.PartType.Block
            iceFlat.Size = Vector3.new(data.radius * 0.3, data.radius * 0.05, data.radius * 0.3)
            iceFlat.Color = Color3.fromRGB(220, 255, 220)
            iceFlat.Material = Enum.Material.Ice
            iceFlat.Transparency = 0.2

            -- Random position on surface
            local angle = math.random() * math.pi * 2
            local elevation = math.random() * math.pi - math.pi / 2
            local position = planet.Position + Vector3.new(
                math.cos(angle) * math.cos(elevation),
                math.sin(elevation),
                math.sin(angle) * math.cos(elevation)
            ) * data.radius
            iceFlat.Position = position
            iceFlat.Parent = planet
        end
        LogDebug("Surface", data.name, "Added ice flats")
    end

    -- Add storm bands for gas giants
    if data.hasStormBands then
        for i = -2, 2 do
            local stormBand = Instance.new("Part")
            stormBand.Shape = Enum.PartType.Cylinder
            stormBand.Size = Vector3.new(data.radius * 0.05, data.radius * 2.2, data.radius * 2.2)
            stormBand.Color = planet.Color:Lerp(Color3.new(1, 1, 1), 0.2)
            stormBand.Material = Enum.Material.Neon
            stormBand.Transparency = 0.7
            stormBand.CFrame = CFrame.new(planet.Position + Vector3.new(0, i * data.radius * 0.3, 0))
                * CFrame.Angles(math.pi / 2, 0, 0)
            stormBand.Parent = planet
        end
        LogDebug("Surface", data.name, "Added storm bands")
    end

    -- Add wave effects for water worlds
    if data.hasWaves then
        local waveEmitter = Instance.new("ParticleEmitter")
        waveEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
        waveEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 5),
            NumberSequenceKeypoint.new(0.5, 10),
            NumberSequenceKeypoint.new(1, 5)
        })
        waveEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1, 0.9)
        })
        waveEmitter.Rate = 50
        waveEmitter.Speed = NumberRange.new(1, 3)
        waveEmitter.Parent = planet
        LogDebug("Surface", data.name, "Added wave effects")
    end
end

function PlanetGravity:AddCraters(planet, radius, density)
    local numCraters = math.floor(radius / 50 * density) -- Scale craters with planet size and density
    for i = 1, numCraters do
        local crater = Instance.new("Part")
        crater.Shape = Enum.PartType.Ball
        crater.Size = Vector3.new(radius * 0.1 * math.random(0.5, 1.5), radius * 0.02 * math.random(0.5, 1.5), radius * 0.1 * math.random(0.5, 1.5)) -- Vary crater sizes and depths
        -- Random position on surface
        local angle = math.random() * math.pi * 2
        local elevation = math.random() * math.pi - math.pi / 2
        local x = math.cos(angle) * math.cos(elevation)
        local y = math.sin(elevation)
        local z = math.sin(angle) * math.cos(elevation)
        crater.Position = planet.Position + Vector3.new(x, y, z) * radius
        crater.Color = planet.Color:Lerp(Color3.new(0, 0, 0), 0.2) -- Slightly darker than surface
        crater.Material = planet.Material
        crater.Parent = planet
    end
end

function PlanetGravity:AddPlanetaryRings(planet)
    local ringRadius = planet.Size.X * 1.5
    local ringThickness = planet.Size.X * 0.01

    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(ringThickness, ringRadius * 2, ringRadius * 2)
    ring.CFrame = CFrame.new(planet.Position) * CFrame.Angles(math.pi / 2, 0, 0)
    ring.Transparency = 0.5
    ring.CanCollide = false
    ring.Material = Enum.Material.Glass
    ring.Color = Color3.fromRGB(200, 200, 150)
    ring.Parent = planet
end


function PlanetGravity:UpdateGravityFields(dt)
    for _, planet in ipairs(workspace.Planets:GetChildren()) do
        if planet.Name ~= "Sun" then
            for _, part in ipairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") and part.Parent ~= planet and part.Name ~= "Sun" then
                    self:ApplyGravity(part)
                end
            end
        end
    end
end

function PlanetGravity:UpdateOrbits(dt)
    local time = workspace:GetServerTimeNow()

    for name, data in pairs(self.Planets) do
        local planet = workspace.Planets:FindFirstChild(name)
        if planet then
            if data.parentBody then
                -- Moon orbiting a planet
                local parent = workspace.Planets:FindFirstChild(data.parentBody)
                if parent then
                    local angle = (time / data.orbitPeriod) * math.pi * 2
                    local x = math.cos(angle) * data.orbitRadius
                    local z = math.sin(angle) * data.orbitRadius
                    planet.Position = parent.Position + Vector3.new(x, 0, z)
                end
            else
                -- Planet orbiting the sun
                local angle = (time / data.orbitPeriod) * math.pi * 2
                local inclination = data.orbitInclination or 0
                local x = math.cos(angle) * data.orbitRadius
                local y = math.sin(inclination) * data.orbitRadius
                local z = math.sin(angle) * data.orbitRadius
                planet.Position = Vector3.new(x, y, z)
            end
        end
    end
end

function PlanetGravity:InitializeOrbits()
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:UpdateOrbits(dt)
    end)
    LogDebug("Orbit", "System", "Initialized orbital motion system")
end

return PlanetGravity