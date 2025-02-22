local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SolarSystemConfig = require(script.Parent.SolarSystemConfig)

local SolarSystemBuilder = {}

-- Helper function to clone and configure planet template
local function ConfigurePlanetFromTemplate(name, size, color, material)
    local template = ReplicatedStorage.Assets.PlanetTemplate:Clone()
    template.Name = name

    -- Configure each quarter circle part
    for _, part in ipairs(template:GetChildren()) do
        if part:IsA("Part") then
            part.Size = Vector3.new(size, size, size)
            part.Color = color
            part.Material = material
            part.Anchored = true
        end
    end

    return template
end

-- Create sun from template with multiple segments
function SolarSystemBuilder:CreateSun()
    local sunFolder = Instance.new("Folder")
    sunFolder.Name = "Sun"

    -- Create sun using template at max size
    local sunCore = ConfigurePlanetFromTemplate(
        "SunCore",
        SolarSystemConfig.SUN.baseSize,
        SolarSystemConfig.SUN.color,
        SolarSystemConfig.SUN.material
    )
    sunCore.Parent = sunFolder

    -- Add emission
    for _, part in ipairs(sunCore:GetChildren()) do
        if part:IsA("Part") then
            local surfaceLight = Instance.new("SurfaceLight")
            surfaceLight.Range = SolarSystemConfig.SUN.baseSize * 2
            surfaceLight.Brightness = 2
            surfaceLight.Color = SolarSystemConfig.SUN.color
            surfaceLight.Parent = part

            -- Add PointLight for extra glow
            local pointLight = Instance.new("PointLight")
            pointLight.Range = SolarSystemConfig.SUN.baseSize * 3
            pointLight.Brightness = 1
            pointLight.Color = SolarSystemConfig.SUN.color
            pointLight.Parent = part
        end
    end

    return sunFolder
end

-- Create a planet with its moons using template
function SolarSystemBuilder:CreatePlanet(planetConfig)
    local planetFolder = Instance.new("Folder")
    planetFolder.Name = planetConfig.name

    -- Create planet using template
    local planet = ConfigurePlanetFromTemplate(
        planetConfig.name,
        SolarSystemConfig.PLANET_BASE_SIZE * planetConfig.sizeScale,
        planetConfig.color,
        planetConfig.material
    )
    planet.PivotTo(CFrame.new(planetConfig.orbitRadius, 0, 0))
    planet.Parent = planetFolder

    -- Add atmosphere if needed
    if planetConfig.atmosphere then
        local atmosphere = ConfigurePlanetFromTemplate(
            planetConfig.name .. "Atmosphere",
            SolarSystemConfig.PLANET_BASE_SIZE * planetConfig.sizeScale * 1.2,
            planetConfig.atmosphereColor,
            Enum.Material.Neon
        )
        atmosphere.PivotTo(CFrame.new(planetConfig.orbitRadius, 0, 0))

        -- Make atmosphere transparent
        for _, part in ipairs(atmosphere:GetChildren()) do
            if part:IsA("Part") then
                part.Transparency = 0.8
                part.CanCollide = false
            end
        end

        atmosphere.Parent = planetFolder
    end

    -- Create moons
    for _, moonConfig in ipairs(planetConfig.moons or {}) do
        local moon = ConfigurePlanetFromTemplate(
            moonConfig.name,
            moonConfig.size,
            moonConfig.color,
            moonConfig.material
        )
        moon.PivotTo(CFrame.new(planetConfig.orbitRadius + moonConfig.orbitRadius, 0, 0))
        moon.Parent = planetFolder

        -- Add atmosphere for moons that have it
        if moonConfig.atmosphere then
            local atmosphere = ConfigurePlanetFromTemplate(
                moonConfig.name .. "Atmosphere",
                moonConfig.size * 1.2,
                moonConfig.atmosphereColor,
                Enum.Material.Neon
            )
            atmosphere.PivotTo(CFrame.new(planetConfig.orbitRadius + moonConfig.orbitRadius, 0, 0))

            for _, part in ipairs(atmosphere:GetChildren()) do
                if part:IsA("Part") then
                    part.Transparency = 0.8
                    part.CanCollide = false
                end
            end

            atmosphere.Parent = planetFolder
        end
    end

    return planetFolder
end

-- Create the entire solar system
function SolarSystemBuilder:CreateSolarSystem()
    local solarSystem = Instance.new("Folder")
    solarSystem.Name = "SolarSystem"
    solarSystem.Parent = workspace

    -- Create sun
    local sun = self:CreateSun()
    sun.Parent = solarSystem

    -- Create planets
    for _, planetConfig in ipairs(SolarSystemConfig.PLANETS) do
        local planet = self:CreatePlanet(planetConfig)
        planet.Parent = solarSystem
    end

    return solarSystem
end

return SolarSystemBuilder