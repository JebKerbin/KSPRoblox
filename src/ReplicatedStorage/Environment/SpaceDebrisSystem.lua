local SpaceDebrisSystem = {}

-- Constants for debris simulation
local DEBRIS_COUNT = 100
local DEBRIS_TYPES = {
    Satellite = {
        size = Vector3.new(2, 2, 2),
        mass = 100,
        tumbleRate = 1
    },
    Rocket = {
        size = Vector3.new(5, 1, 1),
        mass = 200,
        tumbleRate = 0.5
    },
    Fragment = {
        size = Vector3.new(0.5, 0.5, 0.5),
        mass = 10,
        tumbleRate = 2
    }
}

function SpaceDebrisSystem:Init()
    self.activeDebris = {}
    self.debrisFolder = Instance.new("Folder")
    self.debrisFolder.Name = "SpaceDebris"
    self.debrisFolder.Parent = workspace

    -- Initialize orbital debris field
    self:PopulateDebrisField()

    -- Start debris update cycle
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        self:UpdateDebris(dt)
    end)
end

-- Create initial debris field
function SpaceDebrisSystem:PopulateDebrisField()
    for i = 1, DEBRIS_COUNT do
        local debrisType = self:GetRandomDebrisType()
        local position = self:GetRandomOrbitPosition()
        self:CreateDebris(debrisType, position)
    end
end

-- Get random debris type
function SpaceDebrisSystem:GetRandomDebrisType()
    local types = {}
    for name, _ in pairs(DEBRIS_TYPES) do
        table.insert(types, name)
    end
    return types[math.random(1, #types)]
end

-- Get random position in orbit
function SpaceDebrisSystem:GetRandomOrbitPosition()
    local orbit_radius = math.random(10000, 50000)
    local angle = math.random() * math.pi * 2
    local elevation = math.random() * math.pi - math.pi/2
    
    return Vector3.new(
        math.cos(angle) * math.cos(elevation) * orbit_radius,
        math.sin(elevation) * orbit_radius,
        math.sin(angle) * math.cos(elevation) * orbit_radius
    )
end

-- Create new debris object
function SpaceDebrisSystem:CreateDebris(debrisType, position)
    local template = DEBRIS_TYPES[debrisType]
    
    local debris = Instance.new("Part")
    debris.Name = debrisType .. "Debris"
    debris.Size = template.size
    debris.Position = position
    debris.Anchored = true
    
    -- Add visual effects
    local glow = Instance.new("ParticleEmitter")
    glow.Color = ColorSequence.new(Color3.fromRGB(255, 200, 100))
    glow.Size = NumberSequence.new(0.5)
    glow.Lifetime = NumberRange.new(0.5)
    glow.Rate = 5
    glow.Speed = NumberRange.new(0.1)
    glow.Parent = debris
    
    -- Store debris data
    self.activeDebris[debris] = {
        type = debrisType,
        mass = template.mass,
        tumbleRate = template.tumbleRate,
        rotation = CFrame.new()
    }
    
    debris.Parent = self.debrisFolder
    return debris
end

-- Update debris positions and rotations
function SpaceDebrisSystem:UpdateDebris(dt)
    for debris, data in pairs(self.activeDebris) do
        -- Update rotation (tumbling effect)
        data.rotation = data.rotation * CFrame.fromEulerAnglesXYZ(
            dt * data.tumbleRate * math.random(),
            dt * data.tumbleRate * math.random(),
            dt * data.tumbleRate * math.random()
        )
        debris.CFrame = CFrame.new(debris.Position) * data.rotation
        
        -- Add random orbital perturbations
        local perturbation = Vector3.new(
            math.random() - 0.5,
            math.random() - 0.5,
            math.random() - 0.5
        ) * dt * 10
        
        debris.Position = debris.Position + perturbation
    end
end

-- Check for collision with debris
function SpaceDebrisSystem:CheckDebrisCollision(position, radius)
    local collisions = {}
    
    for debris, data in pairs(self.activeDebris) do
        local distance = (position - debris.Position).Magnitude
        if distance < radius + debris.Size.Magnitude/2 then
            table.insert(collisions, {
                debris = debris,
                distance = distance,
                type = data.type
            })
        end
    end
    
    return collisions
end

return SpaceDebrisSystem
