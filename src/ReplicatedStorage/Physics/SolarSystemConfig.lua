-- Constants for solar system configuration
local SolarSystemConfig = {
    PLANET_BASE_SIZE = 256, -- Base size for planets
    ORBITAL_SCALE = 25000, -- Scale factor for orbit distances

    -- Sun configuration
    SUN = {
        name = "Sun",
        baseSize = 2048, -- Maximum size per part
        color = Color3.fromRGB(255, 198, 42),
        material = Enum.Material.Neon,
        emission = 1,
    },

    -- Planet configurations with relative scaling (ordered by distance from sun)
    PLANETS = {
        -- Inner Planets
        {
            name = "Moho", -- Closest to sun
            color = Color3.fromRGB(161, 157, 148),
            material = Enum.Material.Slate,
            orbitRadius = 1 * 25000,
            orbitPeriod = 180,
            sizeScale = 0.2,
            atmosphere = false,
            moons = {},
        },
        {
            name = "Eve",
            color = Color3.fromRGB(113, 89, 147),
            material = Enum.Material.Slate,
            orbitRadius = 2 * 25000,
            orbitPeriod = 240,
            sizeScale = 0.9,
            atmosphere = true,
            atmosphereColor = Color3.fromRGB(179, 125, 255),
            moons = {
                {
                    name = "Gilly",
                    color = Color3.fromRGB(133, 117, 99),
                    material = Enum.Material.Sand,
                    orbitRadius = 3000,
                    orbitPeriod = 60,
                    size = 256 * 0.1,
                }
            },
        },
        {
            name = "Kerbin",
            color = Color3.fromRGB(68, 105, 148),
            material = Enum.Material.Sand,
            orbitRadius = 3 * 25000,
            orbitPeriod = 300,
            sizeScale = 1.0,
            atmosphere = true,
            atmosphereColor = Color3.fromRGB(140, 180, 255),
            moons = {
                {
                    name = "Mun",
                    color = Color3.fromRGB(190, 190, 190),
                    material = Enum.Material.Slate,
                    orbitRadius = 4000,
                    orbitPeriod = 80,
                    size = 256 * 0.4,
                },
                {
                    name = "Minmus",
                    color = Color3.fromRGB(200, 255, 230),
                    material = Enum.Material.Ice,
                    orbitRadius = 6000,
                    orbitPeriod = 120,
                    size = 256 * 0.2,
                }
            },
        },
        {
            name = "Duna",
            color = Color3.fromRGB(161, 92, 76),
            material = Enum.Material.Sand,
            orbitRadius = 4 * 25000,
            orbitPeriod = 360,
            sizeScale = 0.7,
            atmosphere = true,
            atmosphereColor = Color3.fromRGB(255, 180, 150),
            moons = {
                {
                    name = "Ike",
                    color = Color3.fromRGB(130, 130, 130),
                    material = Enum.Material.Slate,
                    orbitRadius = 3500,
                    orbitPeriod = 100,
                    size = 256 * 0.3,
                }
            },
        },
        {
            name = "Dres",
            color = Color3.fromRGB(140, 140, 140),
            material = Enum.Material.Slate,
            orbitRadius = 5 * 25000,
            orbitPeriod = 420,
            sizeScale = 0.3,
            atmosphere = false,
            moons = {},
        },
        -- Outer Planets
        {
            name = "Jool", -- Gas Giant
            color = Color3.fromRGB(105, 159, 89),
            material = Enum.Material.Glass,
            orbitRadius = 6 * 25000,
            orbitPeriod = 480,
            sizeScale = 1.8,
            atmosphere = true,
            atmosphereColor = Color3.fromRGB(150, 255, 150),
            moons = {
                {
                    name = "Laythe",
                    color = Color3.fromRGB(71, 120, 161),
                    material = Enum.Material.Sand,
                    orbitRadius = 4000,
                    orbitPeriod = 90,
                    size = 256 * 0.4,
                    atmosphere = true,
                    atmosphereColor = Color3.fromRGB(140, 180, 255),
                },
                {
                    name = "Vall",
                    color = Color3.fromRGB(220, 230, 240),
                    material = Enum.Material.Ice,
                    orbitRadius = 5000,
                    orbitPeriod = 120,
                    size = 256 * 0.3,
                },
                {
                    name = "Tylo",
                    color = Color3.fromRGB(180, 180, 180),
                    material = Enum.Material.Slate,
                    orbitRadius = 6000,
                    orbitPeriod = 150,
                    size = 256 * 0.45,
                },
                {
                    name = "Bop",
                    color = Color3.fromRGB(121, 107, 93),
                    material = Enum.Material.Slate,
                    orbitRadius = 7000,
                    orbitPeriod = 180,
                    size = 256 * 0.2,
                },
                {
                    name = "Pol",
                    color = Color3.fromRGB(207, 198, 147),
                    material = Enum.Material.Sand,
                    orbitRadius = 8000,
                    orbitPeriod = 210,
                    size = 256 * 0.15,
                }
            },
        },
        {
            name = "Eeloo",
            color = Color3.fromRGB(230, 230, 230),
            material = Enum.Material.Ice,
            orbitRadius = 7 * 25000,
            orbitPeriod = 540,
            sizeScale = 0.35,
            atmosphere = false,
            moons = {},
        },
        -- KSP 2 Planets
        {
            name = "Ovin", -- KSP 2 Gas Giant
            color = Color3.fromRGB(255, 180, 100),
            material = Enum.Material.Glass,
            orbitRadius = 8 * 25000,
            orbitPeriod = 600,
            sizeScale = 1.5,
            atmosphere = true,
            atmosphereColor = Color3.fromRGB(255, 200, 150),
            moons = {
                {
                    name = "Nivue",
                    color = Color3.fromRGB(200, 220, 255),
                    material = Enum.Material.Ice,
                    orbitRadius = 4500,
                    orbitPeriod = 110,
                    size = 256 * 0.35,
                    atmosphere = true,
                    atmosphereColor = Color3.fromRGB(180, 200, 255),
                }
            },
        },
        {
            name = "Rask",
            color = Color3.fromRGB(180, 100, 70),
            material = Enum.Material.Sand,
            orbitRadius = 9 * 25000,
            orbitPeriod = 650,
            sizeScale = 0.6,
            atmosphere = true,
            atmosphereColor = Color3.fromRGB(255, 150, 100),
            moons = {
                {
                    name = "Rusk",
                    color = Color3.fromRGB(160, 90, 60),
                    material = Enum.Material.Sand,
                    orbitRadius = 3000,
                    orbitPeriod = 85,
                    size = 256 * 0.5,
                    atmosphere = true,
                    atmosphereColor = Color3.fromRGB(230, 140, 90),
                }
            },
        },
        {
            name = "Plock", -- Furthest planet
            color = Color3.fromRGB(200, 200, 210),
            material = Enum.Material.Ice,
            orbitRadius = 10 * 25000,
            orbitPeriod = 700,
            sizeScale = 0.25,
            atmosphere = false,
            moons = {
                {
                    name = "Karen",
                    color = Color3.fromRGB(180, 180, 190),
                    material = Enum.Material.Ice,
                    orbitRadius = 2500,
                    orbitPeriod = 70,
                    size = 256 * 0.15,
                }
            },
        }
    }
}

return SolarSystemConfig