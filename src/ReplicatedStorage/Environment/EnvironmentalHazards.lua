local EnvironmentalHazards = {}

-- Constants for asteroid generation
local ASTEROID_MIN_SIZE = 10 -- studs
local ASTEROID_MAX_SIZE = 50 -- studs
local ASTEROID_MIN_SPEED = 5 -- studs/s
local ASTEROID_MAX_SPEED = 20 -- studs/s

-- Weather settings per planet
EnvironmentalHazards.WeatherTypes = {
    Kerbin = {
        windSpeed = {min = 0, max = 15},
        precipitation = true,
        cloudCover = 0.4, -- 40% coverage
        atmosphericDensity = 1.0
    },
    Duna = {
        windSpeed = {min = 10, max = 30},
        dustStorms = true,
        stormIntensity = 0.7,
        atmosphericDensity = 0.2
    },
    Eve = {
        windSpeed = {min = 20, max = 50},
        atmosphericDensity = 5.0,
        pressureEffect = 2.0
    }
}

function EnvironmentalHazards:Init()
    self.activeAsteroids = {}
    self.activeWeatherEffects = {}
    
    -- Start weather system update loop
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:UpdateWeather(dt)
    end)
end

-- Generate a new asteroid
function EnvironmentalHazards:SpawnAsteroid(position)
    local asteroid = Instance.new("Part")
    asteroid.Shape = Enum.PartType.Ball
    
    -- Random size and properties
    local size = ASTEROID_MIN_SIZE + math.random() * (ASTEROID_MAX_SIZE - ASTEROID_MIN_SIZE)
    asteroid.Size = Vector3.new(size, size, size)
    asteroid.Position = position
    
    -- Set up physics properties
    local speed = ASTEROID_MIN_SPEED + math.random() * (ASTEROID_MAX_SPEED - ASTEROID_MIN_SPEED)
    local direction = Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)).Unit
    asteroid.Velocity = direction * speed
    
    -- Add to active asteroids
    self.activeAsteroids[asteroid] = {
        speed = speed,
        direction = direction,
        damage = size * speed * 0.1 -- Damage based on size and speed
    }
    
    asteroid.Parent = workspace.Asteroids
    return asteroid
end

-- Update asteroid positions and check for collisions
function EnvironmentalHazards:UpdateAsteroids(dt)
    for asteroid, data in pairs(self.activeAsteroids) do
        -- Update position
        local newPos = asteroid.Position + data.direction * data.speed * dt
        asteroid.Position = newPos
        
        -- Check for collisions with vehicles
        local hitPart = workspace:FindPartOnRayWithIgnoreList(
            Ray.new(asteroid.Position, data.direction * data.speed * dt),
            {workspace.Asteroids}
        )
        
        if hitPart then
            local vehicle = hitPart:FindFirstAncestor("Vehicle")
            if vehicle then
                self:HandleAsteroidCollision(asteroid, vehicle, data.damage)
            end
        end
    end
end

-- Handle collision between asteroid and vehicle
function EnvironmentalHazards:HandleAsteroidCollision(asteroid, vehicle, damage)
    -- Apply damage to vehicle
    local healthValue = vehicle:FindFirstChild("Health")
    if healthValue then
        healthValue.Value = healthValue.Value - damage
    end
    
    -- Create explosion effect
    local explosion = Instance.new("Explosion")
    explosion.Position = asteroid.Position
    explosion.BlastRadius = asteroid.Size.X
    explosion.BlastPressure = damage
    explosion.Parent = workspace
    
    -- Remove asteroid after collision
    self.activeAsteroids[asteroid] = nil
    asteroid:Destroy()
end

-- Update weather effects
function EnvironmentalHazards:UpdateWeather(dt)
    for planet, effects in pairs(self.activeWeatherEffects) do
        local weatherType = self.WeatherTypes[planet]
        if not weatherType then continue end
        
        -- Update wind effects
        if effects.wind then
            local windForce = Vector3.new(
                math.random(weatherType.windSpeed.min, weatherType.windSpeed.max),
                0,
                math.random(weatherType.windSpeed.min, weatherType.windSpeed.max)
            )
            effects.wind.Force = windForce
        end
        
        -- Update dust storms (Duna)
        if weatherType.dustStorms then
            self:UpdateDustStorm(planet, effects, dt)
        end
        
        -- Update precipitation (Kerbin)
        if weatherType.precipitation then
            self:UpdatePrecipitation(planet, effects, dt)
        end
    end
end

-- Create weather effects for a planet
function EnvironmentalHazards:CreateWeatherEffects(planet)
    local effects = {
        wind = Instance.new("VectorForce"),
        particles = {},
        active = true
    }
    
    -- Set up wind force
    effects.wind.Name = "WindForce"
    effects.wind.Parent = workspace[planet]
    
    -- Set up particle effects based on planet type
    if self.WeatherTypes[planet].dustStorms then
        local dustStorm = Instance.new("ParticleEmitter")
        dustStorm.Color = ColorSequence.new(Color3.fromRGB(255, 150, 100))
        dustStorm.Rate = 50
        dustStorm.Speed = NumberRange.new(20, 30)
        dustStorm.Parent = workspace[planet]
        table.insert(effects.particles, dustStorm)
    end
    
    if self.WeatherTypes[planet].precipitation then
        local rain = Instance.new("ParticleEmitter")
        rain.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
        rain.Rate = 100
        rain.Speed = NumberRange.new(50, 70)
        rain.Parent = workspace[planet]
        table.insert(effects.particles, rain)
    end
    
    self.activeWeatherEffects[planet] = effects
end

-- Update dust storm effects
function EnvironmentalHazards:UpdateDustStorm(planet, effects, dt)
    local weatherType = self.WeatherTypes[planet]
    for _, particle in ipairs(effects.particles) do
        -- Vary particle emission rate based on storm intensity
        particle.Rate = 50 * weatherType.stormIntensity
        
        -- Update particle direction based on wind
        local windDirection = effects.wind.Force.Unit
        particle.VelocitySpread = 20 + 30 * weatherType.stormIntensity
    end
end

-- Update precipitation effects
function EnvironmentalHazards:UpdatePrecipitation(planet, effects, dt)
    for _, particle in ipairs(effects.particles) do
        -- Update rain intensity based on cloud cover
        local weatherType = self.WeatherTypes[planet]
        particle.Rate = 100 * weatherType.cloudCover
    end
end

return EnvironmentalHazards
