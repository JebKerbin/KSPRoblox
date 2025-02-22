local OrbitSystem = {}

-- Orbital parameters
OrbitSystem.OrbitalElements = {
    semiMajorAxis = 0,
    eccentricity = 0,
    inclination = 0,
    argumentOfPeriapsis = 0,
    longitudeOfAscendingNode = 0,
    meanAnomaly = 0
}

function OrbitSystem:Init()
    self.activeOrbits = {}
end

-- Calculate orbital velocity at current position
function OrbitSystem:CalculateOrbitalVelocity(centralBody, position)
    local mu = centralBody.gravity * centralBody.mass
    local r = (position - centralBody.Position).Magnitude

    -- Circular orbit velocity
    local velocity = math.sqrt(mu / r)
    return velocity
end

-- Calculate gravitational acceleration
function OrbitSystem:CalculateGravitationalAcceleration(position, centralBody)
    local r = (position - centralBody.Position)
    local rMag = r.Magnitude
    local mu = centralBody.gravity * centralBody.mass

    -- F = GMm/r^2 in the direction of r
    local acceleration = -(mu / (rMag * rMag * rMag)) * r
    return acceleration
end

-- Propagate orbit using numerical integration
function OrbitSystem:PropagateOrbit(orbit, dt)
    local pos = orbit.position
    local vel = orbit.velocity
    local centralBody = orbit.centralBody

    -- Simple Euler integration
    local acc = self:CalculateGravitationalAcceleration(pos, centralBody)
    local newVel = vel + acc * dt
    local newPos = pos + vel * dt

    -- Update orbit state
    orbit.position = newPos
    orbit.velocity = newVel

    return newPos
end

-- Update object's position based on orbital parameters
function OrbitSystem:UpdateOrbit(object, dt)
    if not self.activeOrbits[object] then return end

    local orbit = self.activeOrbits[object]
    local centralBody = orbit.centralBody

    -- Calculate new position using two-body problem
    local newPosition = self:PropagateOrbit(orbit, dt)
    object.Position = newPosition
end

-- Calculate orbital trajectory
function OrbitSystem:CalculateTrajectory(startPos, velocity, centralBody)
    local trajectory = {}
    local dt = 1/60 -- 60fps simulation
    local simTime = 600 -- 10 minutes prediction

    local pos = startPos
    local vel = velocity

    for t = 0, simTime, dt do
        -- Simple Euler integration for trajectory
        local acceleration = self:CalculateGravitationalAcceleration(pos, centralBody)
        vel = vel + acceleration * dt
        pos = pos + vel * dt

        table.insert(trajectory, pos)
    end

    return trajectory
end

return OrbitSystem