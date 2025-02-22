local SolarSystemScaler = {}

-- Real distances in millions of kilometers
local REAL_DISTANCES = {
    Sun = 0,
    Kerbin = 149.6, -- Earth-like distance
    Duna = 225.0,   -- Mars-like distance
    Eve = 108.2,    -- Venus-like distance
    Jool = 778.5,   -- Jupiter-like distance
}

-- Real diameters in kilometers
local REAL_DIAMETERS = {
    Sun = 1392684,
    Kerbin = 12742,    -- Earth-like
    Duna = 6779,       -- Mars-like
    Eve = 12104,       -- Venus-like
    Jool = 139820,     -- Jupiter-like
}

-- Orbital characteristics
local ORBITAL_PARAMETERS = {
    Kerbin = {
        eccentricity = 0.0167,
        inclination = 0.0,
        period = 365.26  -- Earth-like period in days
    },
    Duna = {
        eccentricity = 0.0934,
        inclination = 1.85,
        period = 687    -- Mars-like period in days
    },
    Eve = {
        eccentricity = 0.0068,
        inclination = 3.39,
        period = 224.7  -- Venus-like period in days
    },
    Jool = {
        eccentricity = 0.0484,
        inclination = 1.31,
        period = 4333   -- Jupiter-like period in days
    }
}

-- Moon orbital characteristics
local MOON_PARAMETERS = {
    Mun = {
        parent = "Kerbin",
        eccentricity = 0.0,
        inclination = 0.0,
        period = 6.4,
    },
    Minmus = {
        parent = "Kerbin",
        eccentricity = 0.0,
        inclination = 6.0,
        period = 12.0,
    },
    Ike = {
        parent = "Duna",
        eccentricity = 0.03,
        inclination = 0.2,
        period = 1.7,
    },
    Laythe = {
        parent = "Jool",
        eccentricity = 0.0,
        inclination = 0.0,
        period = 3.2,
    },
    Vall = {
        parent = "Jool",
        eccentricity = 0.0,
        inclination = 0.0,
        period = 7.9,
    },
    Tylo = {
        parent = "Jool",
        eccentricity = 0.0,
        inclination = 0.0,
        period = 21.9,
    },
    Bop = {
        parent = "Jool",
        eccentricity = 0.235,
        inclination = 15.0,
        period = 50.0,
    },
    Pol = {
        parent = "Jool",
        eccentricity = 0.171,
        inclination = 4.25,
        period = 108.0,
    }
}

-- KSP2 moons
local KSP2_MOON_PARAMETERS = {
    Nivue = {
        parent = "Ovin",
        eccentricity = 0.01,
        inclination = 2.0,
        period = 4.5,
    },
    Rusk = {
        parent = "Rask",
        eccentricity = 0.02,
        inclination = 1.5,
        period = 3.8,
    },
    Karen = {
        parent = "Plock",
        eccentricity = 0.015,
        inclination = 1.8,
        period = 5.2,
    }
}

-- Roblox scale factors (adjusted for better visibility)
local DISTANCE_SCALE = 1/1000000  -- 1 million km = 1000 studs
local SIZE_SCALE = 1/100          -- 100 km = 1 stud
local MIN_PLANET_SIZE = 10        -- Minimum size in studs
local MIN_ORBIT_SEPARATION = 1000 -- Minimum separation between orbits

-- Maximum recommended distance in Roblox (in studs)
local MAX_SAFE_DISTANCE = 100000  -- 100k studs recommended max

function SolarSystemScaler:GetScaledParameters()
    local params = {}
    local maxRealDistance = 0

    -- Find maximum real distance
    for planet, distance in pairs(REAL_DISTANCES) do
        if distance > maxRealDistance then
            maxRealDistance = distance
        end
    end

    -- Calculate dynamic scale factor to fit within Roblox limits
    local dynamicScale = MAX_SAFE_DISTANCE / (maxRealDistance * DISTANCE_SCALE)

    -- Calculate scaled parameters for each planet
    local previousDistance = 0
    for planet, realDistance in pairs(REAL_DISTANCES) do
        local scaledDistance = realDistance * DISTANCE_SCALE * dynamicScale
        local scaledDiameter = math.max(REAL_DIAMETERS[planet] * SIZE_SCALE, MIN_PLANET_SIZE)

        -- Ensure minimum separation between orbits
        if scaledDistance - previousDistance < MIN_ORBIT_SEPARATION and planet ~= "Sun" then
            scaledDistance = previousDistance + MIN_ORBIT_SEPARATION
        end
        previousDistance = scaledDistance

        params[planet] = {
            position = Vector3.new(scaledDistance, 0, 0), -- Base position on x-axis
            size = Vector3.new(scaledDiameter, scaledDiameter, scaledDiameter),
            orbitRadius = scaledDistance,
            -- Add orbital parameters if available
            eccentricity = ORBITAL_PARAMETERS[planet] and ORBITAL_PARAMETERS[planet].eccentricity or 0,
            inclination = ORBITAL_PARAMETERS[planet] and ORBITAL_PARAMETERS[planet].inclination or 0,
            period = ORBITAL_PARAMETERS[planet] and ORBITAL_PARAMETERS[planet].period or 365,
            -- Add moon parameters
            moons = {}
        }

        -- Add moon parameters if planet has moons
        for moon, moonParams in pairs(MOON_PARAMETERS) do
            if moonParams.parent == planet then
                params[planet].moons[moon] = {
                    eccentricity = moonParams.eccentricity,
                    inclination = moonParams.inclination,
                    period = moonParams.period
                }
            end
        end

        -- Add KSP2 moon parameters
        for moon, moonParams in pairs(KSP2_MOON_PARAMETERS) do
            if moonParams.parent == planet then
                params[planet].moons[moon] = {
                    eccentricity = moonParams.eccentricity,
                    inclination = moonParams.inclination,
                    period = moonParams.period
                }
            end
        end
    end

    return params
end

-- Get relative scale for UI displays
function SolarSystemScaler:GetUIScale()
    local maxSize = 0
    local minSize = math.huge

    for _, diameter in pairs(REAL_DIAMETERS) do
        local scaled = math.max(diameter * SIZE_SCALE, MIN_PLANET_SIZE)
        maxSize = math.max(maxSize, scaled)
        minSize = math.min(minSize, scaled)
    end

    return {
        maxSize = maxSize,
        minSize = minSize,
        ratio = maxSize / minSize
    }
end

-- Calculate orbital period based on distance and mass
function SolarSystemScaler:GetOrbitalPeriod(orbitRadius)
    local scaledPeriod = math.sqrt(orbitRadius * orbitRadius * orbitRadius) / 100
    return math.max(scaledPeriod, 10) -- Ensure minimum period for gameplay
end

-- Calculate escape velocity at a given distance
function SolarSystemScaler:GetEscapeVelocity(distance)
    return math.sqrt(2 * 100000 / distance) -- Simplified for gameplay
end

return SolarSystemScaler