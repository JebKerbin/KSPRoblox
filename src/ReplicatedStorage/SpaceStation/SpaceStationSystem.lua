-- Debug settings
local DEBUG_MODE = true

local SpaceStationSystem = {}

-- Import required services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService") -- Added PhysicsService import

-- Reference to stock ships folder
local StockShips = ReplicatedStorage:WaitForChild("StockShips")
if not StockShips then
    error("[SpaceStationSystem] StockShips folder not found in ReplicatedStorage")
end

-- Constants for docking
local DOCKING_RANGE = 2 -- studs
local DOCKING_SPEED_THRESHOLD = 1 -- studs/s
local DOCKING_ANGLE_THRESHOLD = math.rad(5) -- 5 degrees

-- Station module types
SpaceStationSystem.ModuleTypes = {
    CoreModule = {
        required = true,
        maxCount = 1,
        children = {
            "DockingPort",
            "StationControl"
        }
    },
    HabModule = {
        size = Vector3.new(10, 10, 10),
        mass = 2000,
        crewCapacity = 4,
        children = {
            "EVA_Airlock"
        }
    },
    ScienceLab = {
        size = Vector3.new(8, 8, 12),
        mass = 1500,
        scienceMultiplier = 1.5
    },
    SolarArray = {
        children = {
            "SolarPanel_Left",
            "SolarPanel_Right"
        }
    },
    StorageBay = {
        mass = 1000
    },
    FuelDepot = {
        mass = 1500
    }
}

function SpaceStationSystem:Init()
    if DEBUG_MODE then
        print("[SpaceStationSystem] Initializing...")
    end

    self.activeStations = {}
    self.dockingPorts = {}

    -- Create collision group for station modules
    PhysicsService:CreateCollisionGroup("StationModules")
    PhysicsService:CollisionGroupSetCollidable("StationModules", "StationModules", false)

    -- Validate station module templates
    for moduleType, config in pairs(self.ModuleTypes) do
        local template = StockShips:FindFirstChild(moduleType)
        if not template then
            warn(string.format("[SpaceStationSystem] Template '%s' not found in StockShips", moduleType))
        end
    end

    -- Connect update loop using RunService
    RunService.Heartbeat:Connect(function(dt)
        self:UpdateDockingForces()
    end)

    if DEBUG_MODE then
        print("[SpaceStationSystem] Initialization complete")
    end
end

-- Create new space station
function SpaceStationSystem:CreateStation(position)
    local station = {
        modules = {},
        dockingPorts = {},
        position = position or Vector3.new(0, 0, 0),
        mass = 0,
        crewCapacity = 0,
        powerOutput = 0
    }

    self.activeStations[station] = true
    return station
end

-- Add module to station
function SpaceStationSystem:AddModule(station, moduleType, position, rotation)
    if not station or not self.ModuleTypes[moduleType] then
        warn("[SpaceStationSystem] Invalid station or module type")
        return nil
    end

    local template = self.ModuleTypes[moduleType]
    local module = Instance.new("Model")
    module.Name = moduleType

    -- Create main body
    local body = Instance.new("Part")
    body.Size = template.size or Vector3.new(5, 5, 5)
    body.Position = position or Vector3.new(0, 0, 0)
    body.Anchored = true
    body.CanCollide = true
    body.Parent = module

    -- Set module as PrimaryPart
    module.PrimaryPart = body

    -- Add docking ports if specified
    if template.children and table.find(template.children, "DockingPort") then
        local dockingPort = self:CreateDockingPort(module)
        dockingPort.Parent = module
    end

    -- Update station stats
    station.mass = station.mass + (template.mass or 0)
    if template.crewCapacity then
        station.crewCapacity = station.crewCapacity + template.crewCapacity
    end
    if template.powerOutput then
        station.powerOutput = station.powerOutput + template.powerOutput
    end

    module.Parent = workspace
    table.insert(station.modules, module)
    return module
end

-- Create docking port with proper Roblox constraints
function SpaceStationSystem:CreateDockingPort(module)
    local port = Instance.new("Part")
    port.Name = "DockingPort"
    port.Size = Vector3.new(1, 1, 1)
    port.Anchored = false
    port.CanCollide = true
    
    -- Add to collision group
    PhysicsService:SetPartCollisionGroup(port, "StationModules")

    -- Add magnetic attraction using Roblox's VectorForce
    local attachment = Instance.new("Attachment")
    attachment.Parent = port

    local vectorForce = Instance.new("VectorForce")
    vectorForce.Force = Vector3.new(0, 0, 0)
    vectorForce.Attachment0 = attachment
    vectorForce.Parent = port

    -- Add AlignPosition for docking alignment
    local alignPos = Instance.new("AlignPosition")
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = attachment
    alignPos.Parent = port

    self.dockingPorts[port] = {
        module = module,
        connected = false,
        attachment = attachment,
        vectorForce = vectorForce,
        alignPos = alignPos
    }

    return port
end

-- Update docking forces using proper Roblox physics
function SpaceStationSystem:UpdateDockingForces()
    for port1, data1 in pairs(self.dockingPorts) do
        if not port1.Parent or data1.connected then continue end

        for port2, data2 in pairs(self.dockingPorts) do
            if port1 == port2 or not port2.Parent or data2.connected then continue end

            local distance = (port1.Position - port2.Position).Magnitude
            if distance <= DOCKING_RANGE then
                -- Calculate docking forces using Roblox physics
                local direction = (port2.Position - port1.Position).Unit
                local force = 1000 * (1 - distance/DOCKING_RANGE) -- Adjusted force magnitude

                -- Apply forces through VectorForce
                data1.vectorForce.Force = direction * force
                data2.vectorForce.Force = -direction * force

                -- Check for docking conditions
                if self:CanDock(port1, port2) then
                    self:AttemptDocking(port1, port2)
                end
            else
                -- Reset forces when out of range
                data1.vectorForce.Force = Vector3.new(0, 0, 0)
                data2.vectorForce.Force = Vector3.new(0, 0, 0)
            end
        end
    end
end

-- Check if docking is possible using Roblox's physics system
function SpaceStationSystem:CanDock(port1, port2)
    if not (port1 and port2 and port1.Parent and port2.Parent) then return false end

    -- Get port data
    local data1 = self.dockingPorts[port1]
    local data2 = self.dockingPorts[port2]
    if not (data1 and data2) or data1.connected or data2.connected then return false end

    -- Check distance
    local distance = (port1.Position - port2.Position).Magnitude
    if distance > DOCKING_RANGE then return false end

    -- Check relative velocity using Roblox's Velocity property
    local relativeVelocity = port1.Velocity - port2.Velocity
    if relativeVelocity.Magnitude > DOCKING_SPEED_THRESHOLD then return false end

    -- Check alignment using CFrame
    local angle = math.acos(port1.CFrame.LookVector:Dot(-port2.CFrame.LookVector))
    if angle > DOCKING_ANGLE_THRESHOLD then return false end

    return true
end

-- Create docking connection using Roblox's WeldConstraint
function SpaceStationSystem:AttemptDocking(port1, port2)
    if not self:CanDock(port1, port2) then return false end

    -- Create weld constraint
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = port1
    weld.Part1 = port2
    weld.Parent = port1

    -- Update docking status
    self.dockingPorts[port1].connected = true
    self.dockingPorts[port2].connected = true

    -- Create visual effect
    self:CreateDockingEffect(port1.Position)

    if DEBUG_MODE then
        print(string.format("[SpaceStationSystem] Docking successful between %s and %s",
            port1.Parent.Name, port2.Parent.Name))
    end

    return true
end

-- Create visual effect using Roblox's ParticleEmitter
function SpaceStationSystem:CreateDockingEffect(position)
    local effect = Instance.new("ParticleEmitter")
    effect.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
    effect.Size = NumberSequence.new(0.5)
    effect.Speed = NumberRange.new(5)
    effect.Lifetime = NumberRange.new(0.5)
    effect.Rate = 50
    effect.Parent = Instance.new("Part", workspace)
    effect.Parent.Position = position
    effect.Parent.Anchored = true
    effect.Parent.CanCollide = false
    effect.Parent.Transparency = 1

    -- Clean up effect
    game:GetService("Debris"):AddItem(effect.Parent, 1)
end

return SpaceStationSystem