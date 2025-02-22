-- Adding proper Roblox service imports and optimizing particle effects
local WeatherSystem = {}

-- Debug settings
local DEBUG_MODE = true

-- Import required Roblox services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")

-- Constants for weather types
local WEATHER_TYPES = {
    Clear = {
        visibility = 1,
        windSpeed = 0,
        turbulence = 0,
        effects = {}
    },
    Cloudy = {
        visibility = 0.7,
        windSpeed = 10,
        turbulence = 0.2,
        effects = {
            cloudDensity = 0.5,
            cloudHeight = 1000
        }
    },
    Storm = {
        visibility = 0.3,
        windSpeed = 50,
        turbulence = 0.8,
        effects = {
            lightningFrequency = 0.2,
            thunderVolume = 1,
            rainIntensity = 1
        }
    },
    DustStorm = {
        visibility = 0.1,
        windSpeed = 70,
        turbulence = 0.9,
        effects = {
            particleDensity = 0.8,
            particleColor = Color3.fromRGB(209, 156, 89)
        }
    },
    IonStorm = {
        visibility = 0.5,
        windSpeed = 30,
        turbulence = 0.6,
        effects = {
            electricalInterference = 0.7,
            radiationLevel = 0.4,
            plasmaEffects = true,
            volume = 0.8
        }
    }
}

-- Planet-specific weather patterns
local PLANET_WEATHER = {
    Kerbin = {
        possibleWeather = {"Clear", "Cloudy", "Storm"},
        changeInterval = 300, -- Weather changes every 5 minutes
        atmosphereDensity = 1,
        effectModifiers = {
            particleScale = 1,
            windMultiplier = 1,
            turbulenceIntensity = 1
        }
    },
    Duna = {
        possibleWeather = {"Clear", "DustStorm"},
        changeInterval = 600,
        atmosphereDensity = 0.2,
        effectModifiers = {
            particleScale = 1.5, -- Larger dust particles
            windMultiplier = 1.3, -- Stronger winds
            turbulenceIntensity = 0.8,
            particleColor = Color3.fromRGB(209, 156, 89) -- Reddish dust
        }
    },
    Eve = {
        possibleWeather = {"Cloudy", "Storm", "IonStorm"},
        changeInterval = 450,
        atmosphereDensity = 1.5,
        effectModifiers = {
            particleScale = 0.8, -- Denser atmosphere, smaller particles
            windMultiplier = 1.5, -- Strong winds due to dense atmosphere
            turbulenceIntensity = 1.2,
            lightningFrequency = 1.5 -- More frequent lightning in Eve's atmosphere
        }
    }
}

WeatherSystem.PLANET_WEATHER = PLANET_WEATHER -- Expose for GameManager

-- Debug settings
local UPDATE_INTERVAL = 0.1 -- Throttle updates to every 0.1 seconds
local lastUpdateTime = 0

function WeatherSystem:Init()
    if DEBUG_MODE then
        print("[WeatherSystem] Starting initialization")
    end

    -- Create proper collision groups for weather effects
    pcall(function()
        PhysicsService:CreateCollisionGroup("WeatherEffects")
        PhysicsService:CollisionGroupSetCollidable("WeatherEffects", "WeatherEffects", false)
    end)

    self.activeWeather = {}
    self.weatherEffects = {}

    -- Create weather effect container with proper error handling
    self.effectsFolder = Instance.new("Folder")
    self.effectsFolder.Name = "WeatherEffects"

    local success, err = pcall(function()
        self.effectsFolder.Parent = workspace
    end)

    if not success then
        warn("[WeatherSystem] Failed to create effects folder:", err)
        return
    end

    -- Create atmospheric effects for each planet with proper error handling
    for planetName, _ in pairs(PLANET_WEATHER) do
        local success, err = pcall(function()
            self:CreateAtmosphericEffects(planetName)
        end)

        if not success then
            warn("[WeatherSystem] Failed to create atmospheric effects for", planetName, ":", err)
        end
    end

    -- Start weather update cycle with throttling and proper cleanup
    local updateConnection = RunService.Heartbeat:Connect(function(dt)
        local currentTime = tick()
        if currentTime - lastUpdateTime >= UPDATE_INTERVAL then
            self:UpdateWeather(dt)
            lastUpdateTime = currentTime
        end
    end)

    -- Proper cleanup on module unload
    self.cleanup = function()
        updateConnection:Disconnect()
        for _, effects in pairs(self.weatherEffects) do
            for _, effect in pairs(effects) do
                effect:Destroy()
            end
        end
        self.effectsFolder:Destroy()
    end

    if DEBUG_MODE then
        print("[WeatherSystem] Initialized successfully")
    end
end

-- Log weather changes in debug mode
local function DebugLog(message)
    if DEBUG_MODE then
        print("[WeatherSystem] " .. message)
    end
end

-- Add atmospheric rendering effects
function WeatherSystem:CreateAtmosphericEffects(planetName)
    local planetData = PLANET_WEATHER[planetName]
    if not planetData then return end

    local atmosphereEffect = Instance.new("Atmosphere")
    atmosphereEffect.Name = planetName .. "Atmosphere"

    -- Customize atmosphere based on planet
    if planetName == "Eve" then
        -- Dense, purple-tinted atmosphere
        atmosphereEffect.Density = 0.5
        atmosphereEffect.Color = Color3.fromRGB(180, 160, 200)
        atmosphereEffect.Decay = Color3.fromRGB(140, 120, 160)
        atmosphereEffect.Glare = 0.4
        atmosphereEffect.Haze = 0.6
    elseif planetName == "Duna" then
        -- Thin, reddish atmosphere
        atmosphereEffect.Density = 0.2
        atmosphereEffect.Color = Color3.fromRGB(200, 160, 140)
        atmosphereEffect.Decay = Color3.fromRGB(160, 120, 100)
        atmosphereEffect.Glare = 0.3
        atmosphereEffect.Haze = 0.8
    else -- Kerbin
        -- Earth-like atmosphere
        atmosphereEffect.Density = 0.3
        atmosphereEffect.Color = Color3.fromRGB(170, 190, 210)
        atmosphereEffect.Decay = Color3.fromRGB(130, 150, 170)
        atmosphereEffect.Glare = 0.25
        atmosphereEffect.Haze = 0.4
    end

    -- Parent to planet
    local planet = workspace:FindFirstChild(planetName)
    if planet then
        atmosphereEffect.Parent = planet
    end

    return atmosphereEffect
end

-- Update CreateWeatherEffects to handle atmospheric changes
function WeatherSystem:CreateWeatherEffects(planetName, weatherType)
    if not WEATHER_TYPES[weatherType] then return end

    local planetModifiers = PLANET_WEATHER[planetName].effectModifiers
    DebugLog(string.format("Creating %s weather effects for %s", weatherType, planetName))

    local effects = {
        particles = Instance.new("ParticleEmitter"),
        lightning = weatherType == "Storm" and Instance.new("Beam") or nil,
        sound = Instance.new("Sound"),
        clouds = weatherType == "Cloudy" and Instance.new("Part") or nil
    }

    local planet = workspace:FindFirstChild(planetName)

    -- Configure particle system based on weather type with planet-specific modifications
    if weatherType == "Storm" then
        -- Storm particles (rain)
        effects.particles.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
        effects.particles.Size = NumberSequence.new(0.1 * planetModifiers.particleScale)
        effects.particles.Lifetime = NumberRange.new(1, 2)
        effects.particles.Rate = 500 * planetModifiers.windMultiplier
        effects.particles.Speed = NumberRange.new(
            50 * planetModifiers.windMultiplier,
            70 * planetModifiers.windMultiplier
        )
        effects.particles.Acceleration = Vector3.new(0, -50, 0)  -- Falling rain

        -- Add atmospheric modifications for storms
        if planet and planet:FindFirstChild(planetName .. "Atmosphere") then
            local atmosphere = planet[planetName .. "Atmosphere"]
            atmosphere.Density = atmosphere.Density * 1.3
            atmosphere.Haze = atmosphere.Haze * 1.5

            -- Add lightning effects
            if math.random() < 0.1 then
                self:CreateLightningStrike(planetName)
            end
        end
    elseif weatherType == "DustStorm" then
        -- Dust storm particles with planet-specific coloring
        local particleColor = planetModifiers.particleColor or WEATHER_TYPES.DustStorm.effects.particleColor
        effects.particles.Color = ColorSequence.new(particleColor)
        effects.particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5 * planetModifiers.particleScale),
            NumberSequenceKeypoint.new(0.5, 1 * planetModifiers.particleScale),
            NumberSequenceKeypoint.new(1, 0.5 * planetModifiers.particleScale)
        })
        effects.particles.Lifetime = NumberRange.new(2, 4)
        effects.particles.Rate = 200 * planetModifiers.windMultiplier
        effects.particles.Speed = NumberRange.new(
            30 * planetModifiers.windMultiplier,
            50 * planetModifiers.windMultiplier
        )
        effects.particles.SpreadAngle = Vector2.new(45, 45)

        -- Add atmospheric modifications for dust storms
        if planet and planet:FindFirstChild(planetName .. "Atmosphere") then
            local atmosphere = planet[planetName .. "Atmosphere"]
            atmosphere.Density = atmosphere.Density * 1.8
            atmosphere.Haze = atmosphere.Haze * 2
            atmosphere.Color = atmosphere.Color:Lerp(particleColor, 0.3) -- Tint atmosphere with dust color
        end
    elseif weatherType == "IonStorm" then
        -- Ion storm particles (plasma) with planet-specific intensity
        effects.particles.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 100, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200))
        })
        effects.particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2 * planetModifiers.particleScale),
            NumberSequenceKeypoint.new(0.5, 1 * planetModifiers.particleScale),
            NumberSequenceKeypoint.new(1, 0.2 * planetModifiers.particleScale)
        })
        effects.particles.Lifetime = NumberRange.new(0.5, 1)
        effects.particles.Rate = 100 * planetModifiers.windMultiplier
        effects.particles.Speed = NumberRange.new(
            20 * planetModifiers.windMultiplier,
            40 * planetModifiers.windMultiplier
        )
        effects.particles.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 0.8)
        })

        -- Add atmospheric modifications for ion storms
        if planet and planet:FindFirstChild(planetName .. "Atmosphere") then
            local atmosphere = planet[planetName .. "Atmosphere"]
            atmosphere.Glare = atmosphere.Glare * 1.4
            atmosphere.Haze = atmosphere.Haze * 1.3
            atmosphere.Color = atmosphere.Color:Lerp(Color3.fromRGB(150, 100, 255), 0.2)
        end
    end

    -- Add debug visualization
    if DEBUG_MODE then
        local debugGui = Instance.new("BillboardGui")
        debugGui.Size = UDim2.new(0, 200, 0, 50)
        debugGui.StudsOffset = Vector3.new(0, 5, 0)

        local debugLabel = Instance.new("TextLabel")
        debugLabel.Size = UDim2.new(1, 0, 1, 0)
        debugLabel.BackgroundTransparency = 0.5
        debugLabel.Text = string.format("%s: %s (x%.1f)",
            planetName,
            weatherType,
            planetModifiers.windMultiplier
        )
        debugLabel.Parent = debugGui
        debugGui.Parent = effects.particles
    end

    self.weatherEffects[planetName] = effects
    return effects
end

function WeatherSystem:UpdateWeather(dt)
    for planetName, weather in pairs(self.activeWeather) do
        -- Update weather effects
        local effects = self.weatherEffects[planetName]
        if effects then
            -- Update particle systems
            if effects.particles then
                effects.particles.Rate =
                    WEATHER_TYPES[weather.currentType].effects.particleDensity * 100 or 0
            end

            -- Update lightning effects
            if effects.lightning and weather.currentType == "Storm" then
                if math.random() < WEATHER_TYPES.Storm.effects.lightningFrequency * dt then
                    self:CreateLightningStrike(planetName)
                end
            end

            -- Update atmospheric effects
            local planet = workspace:FindFirstChild(planetName)
            if planet then
                local atmosphere = planet:FindFirstChild(planetName .. "Atmosphere")
                if atmosphere then
                    -- Calculate transition progress
                    local transitionProgress = math.min(1,
                        (tick() - weather.transitionStart) / weather.transitionDuration)

                    -- Get base atmospheric values
                    local baseAtmosphere = {
                        Density = PLANET_WEATHER[planetName].atmosphereDensity or 1,
                        Haze = 0.4,
                        Glare = 0.25
                    }

                    -- Get target values based on current weather
                    local targetAtmosphere = {
                        Density = baseAtmosphere.Density,
                        Haze = baseAtmosphere.Haze,
                        Glare = baseAtmosphere.Glare
                    }

                    if weather.currentType == "Storm" then
                        targetAtmosphere.Density = baseAtmosphere.Density * 1.3
                        targetAtmosphere.Haze = baseAtmosphere.Haze * 1.5
                    elseif weather.currentType == "DustStorm" then
                        targetAtmosphere.Density = baseAtmosphere.Density * 1.8
                        targetAtmosphere.Haze = baseAtmosphere.Haze * 2
                    elseif weather.currentType == "IonStorm" then
                        targetAtmosphere.Glare = baseAtmosphere.Glare * 1.4
                        targetAtmosphere.Haze = baseAtmosphere.Haze * 1.3
                    end

                    -- Smoothly interpolate atmospheric values
                    atmosphere.Density = Lerp(atmosphere.Density, targetAtmosphere.Density, transitionProgress)
                    atmosphere.Haze = Lerp(atmosphere.Haze, targetAtmosphere.Haze, transitionProgress)
                    atmosphere.Glare = Lerp(atmosphere.Glare, targetAtmosphere.Glare, transitionProgress)
                end
            end

            -- Apply weather effects to vehicles
            self:ApplyWeatherEffects(planetName, weather.currentType, dt)
        end

        -- Check for weather changes
        weather.timeUntilChange = weather.timeUntilChange - dt
        if weather.timeUntilChange <= 0 then
            self:ChangeWeather(planetName)
        end

        -- Update debug visualization if enabled
        if DEBUG_MODE and effects and effects.particles then
            local debugGui = effects.particles:FindFirstChild("BillboardGui")
            if debugGui and debugGui:FindFirstChild("TextLabel") then
                local label = debugGui.TextLabel
                label.Text = string.format("%s Weather\nType: %s\nTime until change: %.0f",
                    planetName,
                    weather.currentType,
                    weather.timeUntilChange
                )
            end
        end
    end
end

function WeatherSystem:ApplyWeatherEffects(planetName, weatherType, dt)
    local weather = WEATHER_TYPES[weatherType]
    if not weather then return end

    -- Find vehicles in planet's atmosphere
    for _, vehicle in pairs(workspace:GetDescendants()) do
        if vehicle:IsA("Model") and vehicle:FindFirstChild("PrimaryPart") then
            local pos = vehicle.PrimaryPart.Position
            local planet = workspace:FindFirstChild(planetName)

            if planet and self:IsInAtmosphere(pos, planet) then
                -- Calculate weather intensity based on altitude
                local planetPos = planet.PrimaryPart.Position
                local distance = (pos - planetPos).Magnitude
                local atmosphereRadius = planet.PrimaryPart.Size.Magnitude / 2 * 1.5
                local altitudeFactor = 1 - (distance / atmosphereRadius)

                -- Apply turbulence with altitude consideration
                local turbulence = Vector3.new(
                    math.random() - 0.5,
                    math.random() - 0.5,
                    math.random() - 0.5
                ) * weather.turbulence * 100 * dt * altitudeFactor * PLANET_WEATHER[planetName].effectModifiers.turbulenceIntensity

                -- Apply wind forces with planetary atmosphere density factor
                local windDirection = Vector3.new(
                    math.cos(tick() * 0.1),
                    math.sin(tick() * 0.2) * 0.2, -- Add some vertical component
                    math.sin(tick() * 0.1)
                ).Unit * weather.windSpeed * PLANET_WEATHER[planetName].atmosphereDensity * altitudeFactor * PLANET_WEATHER[planetName].effectModifiers.windMultiplier


                -- Special weather type effects
                if weatherType == "IonStorm" then
                    -- Ion storms affect control systems
                    if vehicle:FindFirstChild("ControlModule") then
                        local interference = WEATHER_TYPES.IonStorm.effects.electricalInterference
                        -- Temporarily reduce control effectiveness
                        vehicle.ControlModule.Effectiveness =
                            vehicle.ControlModule.Effectiveness * (1 - interference * altitudeFactor)
                    end

                    -- Add plasma visual effects
                    if not vehicle:FindFirstChild("PlasmaEffect") then
                        local plasmaEmitter = Instance.new("ParticleEmitter")
                        plasmaEmitter.Name = "PlasmaEffect"
                        plasmaEmitter.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
                        })
                        plasmaEmitter.Size = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.5),
                            NumberSequenceKeypoint.new(1, 0)
                        })
                        plasmaEmitter.Lifetime = NumberRange.new(0.2, 0.5)
                        plasmaEmitter.Rate = 50 * altitudeFactor
                        plasmaEmitter.Parent = vehicle.PrimaryPart
                    end
                elseif weatherType == "DustStorm" then
                    -- Dust storms reduce visibility and affect sensors
                    if vehicle:FindFirstChild("Sensors") then
                        vehicle.Sensors.Visibility =
                            1 - (WEATHER_TYPES.DustStorm.effects.particleDensity * altitudeFactor)
                    end

                    -- Add dust impact effects
                    if math.random() < 0.1 * altitudeFactor then
                        local impact = Instance.new("Part")
                        impact.Size = Vector3.new(0.5, 0.5, 0.5)
                        impact.Position = vehicle.PrimaryPart.Position
                        impact.Anchored = true
                        impact.CanCollide = false
                        impact.Color = WEATHER_TYPES.DustStorm.effects.particleColor

                        local sparkEmitter = Instance.new("ParticleEmitter")
                        sparkEmitter.Color = ColorSequence.new(WEATHER_TYPES.DustStorm.effects.particleColor)
                        sparkEmitter.Size = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.2),
                            NumberSequenceKeypoint.new(1, 0)
                        })
                        sparkEmitter.Lifetime = NumberRange.new(0.1, 0.3)
                        sparkEmitter.Rate = 50
                        sparkEmitter.Parent = impact

                        Debris:AddItem(impact, 0.3)
                    end
                end

                -- Update vehicle physics with optimized calculations
                if not vehicle.PrimaryPart.Anchored then
                    -- Apply combined weather forces
                    vehicle.PrimaryPart.Velocity =
                        vehicle.PrimaryPart.Velocity + (turbulence + windDirection) * dt

                    if DEBUG_MODE then
                        DebugLog(string.format(
                            "Applied weather forces to vehicle at %s: Turbulence=%0.2f, Wind=%0.2f, Altitude Factor=%0.2f",
                            tostring(pos), turbulence.Magnitude, windDirection.Magnitude, altitudeFactor
                        ))
                    end
                end
            end
        end
    end
end

function WeatherSystem:CreateLightningStrike(planetName)
    local planet = workspace:FindFirstChild(planetName)
    if not planet then return end

    local effects = self.weatherEffects[planetName]
    if not effects or not effects.lightning then return end

    -- Get planet-specific modifiers
    local planetModifiers = PLANET_WEATHER[planetName].effectModifiers
    local lightningFrequency = planetModifiers.lightningFrequency or 1

    DebugLog("Creating lightning strike on " .. planetName)

    -- Create lightning beam with planet-specific properties
    local strike = effects.lightning:Clone()
    strike.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.1, 1),
        NumberSequenceKeypoint.new(0.2, 0),
        NumberSequenceKeypoint.new(0.3, 0.8),
        NumberSequenceKeypoint.new(0.4, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    strike.Width0 = 2 * (planetModifiers.particleScale or 1)
    strike.Width1 = 0.5 * (planetModifiers.particleScale or 1)
    strike.CurveSize0 = 1
    strike.CurveSize1 = -1
    strike.FaceCamera = true

    -- Customize lightning color based on planet
    local lightningColor
    if planetName == "Eve" then
        -- Purple-tinted lightning for Eve's dense atmosphere
        lightningColor = Color3.fromRGB(220, 200, 255)
    elseif planetName == "Duna" then
        -- Reddish lightning for Duna's dust storms
        lightningColor = Color3.fromRGB(255, 200, 180)
    else
        -- Standard white-blue lightning for Kerbin
        lightningColor = Color3.fromRGB(200, 220, 255)
    end

    strike.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, lightningColor),
        ColorSequenceKeypoint.new(0.5, lightningColor:Lerp(Color3.new(1, 1, 1), 0.5)),
        ColorSequenceKeypoint.new(1, lightningColor)
    })
    strike.Parent = self.effectsFolder

    -- Add lightning glow with planet-specific properties
    local glow = Instance.new("PointLight")
    glow.Color = lightningColor
    glow.Range = 100 * (planetModifiers.particleScale or 1)
    glow.Brightness = 2 * lightningFrequency
    glow.Parent = strike

    -- Add thunder sound
    local thunder = Instance.new("Sound")
    thunder.SoundId = "PATH_TO_THUNDER_SOUND" -- TODO: Add thunder sound file
    thunder.Volume = WEATHER_TYPES.Storm.effects.thunderVolume *
        (planetModifiers.atmosphereDensity or 1)
    thunder.Parent = strike

    -- Create secondary lightning branches with planet-specific variations
    local numBranches = math.random(2, math.floor(4 * lightningFrequency))
    for i = 1, numBranches do
        local branch = strike:Clone()
        branch.Width0 = strike.Width0 * 0.5
        branch.Width1 = strike.Width1 * 0.5

        -- Add more variation to branch angles based on atmospheric density
        local atmosphericTurbulence = planetModifiers.turbulenceIntensity or 1
        branch.CurveSize0 = strike.CurveSize0 * (1 + math.random() * atmosphericTurbulence)
        branch.CurveSize1 = strike.CurveSize1 * (1 + math.random() * atmosphericTurbulence)

        branch.Parent = strike
    end

    -- Clean up after effect with staggered timing
    Debris:AddItem(glow, 0.2)
    Debris:AddItem(strike, 0.5)
end

function WeatherSystem:IsInAtmosphere(position, planet)
    local planetPos = planet.PrimaryPart.Position
    local distance = (position - planetPos).Magnitude
    local atmosphereRadius = planet.PrimaryPart.Size.Magnitude / 2 * 1.5 -- 50% larger than planet

    return distance <= atmosphereRadius
end

function WeatherSystem:ChangeWeather(planetName)
    local planetData = PLANET_WEATHER[planetName]
    if not planetData then return end

    -- Select new weather type
    local possibleTypes = planetData.possibleWeather
    local newType = possibleTypes[math.random(1, #possibleTypes)]

    DebugLog(string.format("Weather changing on %s from %s to %s",
        planetName,
        self.activeWeather[planetName] and self.activeWeather[planetName].currentType or "None",
        newType))

    -- Update active weather
    self.activeWeather[planetName] = {
        currentType = newType,
        timeUntilChange = planetData.changeInterval,
        transitionStart = tick(),
        transitionDuration = 5 -- 5 seconds transition
    }

    -- Create new effects while keeping old ones for transition
    local oldEffects = self.weatherEffects[planetName]
    local newEffects = self:CreateWeatherEffects(planetName, newType)

    -- Fade out old effects
    if oldEffects then
        for _, effect in pairs(oldEffects) do
            if effect:IsA("ParticleEmitter") then
                -- Gradually reduce particle emission
                TweenService:Create(effect,
                    TweenInfo.new(5),
                    {Rate = 0}
                ):Play()
            elseif effect:IsA("Sound") then
                -- Fade out sound
                TweenService:Create(effect,
                    TweenInfo.new(5),
                    {Volume = 0}
                ):Play()
            end
        end

        -- Clean up old effects after transition
        Debris:AddItem(oldEffects.particles, 5)
        if oldEffects.lightning then
            Debris:AddItem(oldEffects.lightning, 5)
        end
    end

    -- Fade in new effects
    if newEffects then
        for _, effect in pairs(newEffects) do
            if effect:IsA("ParticleEmitter") then
                -- Start with no particles and gradually increase
                effect.Rate = 0
                TweenService:Create(effect,
                    TweenInfo.new(5),
                    {Rate = WEATHER_TYPES[newType].effects.particleDensity * 100}
                ):Play()
            elseif effect:IsA("Sound") then
                -- Fade in sound
                effect.Volume = 0
                TweenService:Create(effect,
                    TweenInfo.new(5),
                    {Volume = WEATHER_TYPES[newType].effects.volume or 1}
                ):Play()
            end
        end
    end
end

-- Helper function for linear interpolation
function Lerp(a, b, t)
    return a + (b - a) * t
end

return WeatherSystem