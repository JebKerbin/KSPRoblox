local ReentrySystem = {}

-- Constants for reentry physics
local HEAT_COEFFICIENT = 0.1 -- Heat generated per (velocity^2)
local MAX_SAFE_TEMPERATURE = 1200 -- Kelvin
local ATMOSPHERIC_DENSITY_SCALE = 5000 -- Scale height in studs
local BASE_DRAG_COEFFICIENT = 0.1

-- Initialize reentry system
function ReentrySystem:Init()
    self.activeVehicles = {}
end

-- Calculate atmospheric density at given altitude
function ReentrySystem:GetAtmosphericDensity(altitude)
    local baseAtmosphere = 1.0
    return baseAtmosphere * math.exp(-altitude / ATMOSPHERIC_DENSITY_SCALE)
end

-- Calculate heat generation based on velocity and atmospheric density
function ReentrySystem:CalculateHeat(velocity, altitude)
    local density = self:GetAtmosphericDensity(altitude)
    local velocityMagnitude = velocity.Magnitude
    
    -- Heat generation proportional to velocity squared and atmospheric density
    local heatRate = HEAT_COEFFICIENT * density * (velocityMagnitude * velocityMagnitude)
    return heatRate
end

-- Apply heat damage to vehicle parts
function ReentrySystem:ApplyHeatDamage(vehicle, heatRate, dt)
    for _, part in ipairs(vehicle.Parts) do
        local heatShield = part:FindFirstChild("HeatShield")
        local currentTemp = part:GetAttribute("Temperature") or 20 -- Room temperature default
        
        -- Apply heat based on heat shield protection
        if heatShield then
            currentTemp = currentTemp + (heatRate * dt * 0.2) -- 80% heat reduction
        else
            currentTemp = currentTemp + (heatRate * dt)
        end
        
        part:SetAttribute("Temperature", currentTemp)
        
        -- Check for part damage/destruction
        if currentTemp > MAX_SAFE_TEMPERATURE then
            self:DamagePart(part)
        end
    end
end

-- Handle parachute deployment
function ReentrySystem:DeployParachute(vehicle, altitude, velocity)
    local safeDeploymentAltitude = 1000 -- studs
    local maxDeploymentVelocity = 200 -- studs/s
    
    if altitude <= safeDeploymentAltitude and velocity.Magnitude <= maxDeploymentVelocity then
        local parachute = vehicle:FindFirstChild("Parachute")
        if parachute and not parachute:GetAttribute("Deployed") then
            parachute:SetAttribute("Deployed", true)
            self:ActivateParachute(vehicle)
            return true
        end
    end
    return false
end

-- Activate parachute effects and physics
function ReentrySystem:ActivateParachute(vehicle)
    -- Increase drag significantly
    local dragForce = Instance.new("VectorForce")
    dragForce.Force = Vector3.new(0, 100, 0) -- Upward force to counter gravity
    dragForce.Parent = vehicle.PrimaryPart
    
    -- Visual effect for deployed parachute
    local parachuteModel = vehicle:FindFirstChild("ParachuteModel")
    if parachuteModel then
        parachuteModel.Transparency = 0
    end
end

-- Damage a part due to excessive heat
function ReentrySystem:DamagePart(part)
    -- Visual effect for damage
    local fire = Instance.new("Fire")
    fire.Parent = part
    
    -- Reduce part health
    local health = part:GetAttribute("Health") or 100
    health = health - 10
    part:SetAttribute("Health", health)
    
    -- Destroy part if health depleted
    if health <= 0 then
        part:Destroy()
    end
end

-- Update reentry physics for a vehicle
function ReentrySystem:UpdateVehicle(vehicle, dt)
    if not self.activeVehicles[vehicle] then return end
    
    local altitude = vehicle.PrimaryPart.Position.Y
    local velocity = vehicle.PrimaryPart.Velocity
    
    -- Calculate and apply heat
    local heatRate = self:CalculateHeat(velocity, altitude)
    self:ApplyHeatDamage(vehicle, heatRate, dt)
    
    -- Check for parachute deployment conditions
    self:DeployParachute(vehicle, altitude, velocity)
end

return ReentrySystem
