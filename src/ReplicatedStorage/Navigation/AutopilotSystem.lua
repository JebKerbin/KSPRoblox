local AutopilotSystem = {}

-- Constants for maneuver calculations
local ORBITAL_PRECISION = 0.001
local MAX_ITERATIONS = 100

function AutopilotSystem:Init()
    self.activeManeuvers = {}
    self.assistMode = nil
end

-- Calculate required delta-V for orbital insertion
function AutopilotSystem:CalculateOrbitalInsertion(vehicle, targetOrbit)
    local currentPosition = vehicle.PrimaryPart.Position
    local currentVelocity = vehicle.PrimaryPart.Velocity
    local targetAltitude = targetOrbit.altitude
    
    -- Calculate required velocity at target altitude
    local mu = targetOrbit.centralBody.gravity * targetOrbit.centralBody.mass
    local r = targetAltitude + targetOrbit.centralBody.radius
    local circularVelocity = math.sqrt(mu / r)
    
    -- Calculate delta-V requirements
    local deltaV = circularVelocity - currentVelocity.Magnitude
    local burnDirection = (currentVelocity.Unit * circularVelocity - currentVelocity).Unit
    
    return {
        deltaV = deltaV,
        direction = burnDirection
    }
end

-- Plan interplanetary transfer
function AutopilotSystem:PlanTransfer(originOrbit, destinationOrbit)
    local mu = originOrbit.centralBody.gravity * originOrbit.centralBody.mass
    
    -- Calculate phase angle using Lambert's problem
    local transferTime = self:SolvePhaseAngle(originOrbit, destinationOrbit)
    
    -- Calculate ejection and insertion burns
    local ejectionBurn = self:CalculateEjectionBurn(originOrbit, destinationOrbit, transferTime)
    local insertionBurn = self:CalculateInsertionBurn(originOrbit, destinationOrbit, transferTime)
    
    return {
        ejectionBurn = ejectionBurn,
        insertionBurn = insertionBurn,
        transferTime = transferTime
    }
end

-- Solve phase angle for optimal transfer
function AutopilotSystem:SolvePhaseAngle(originOrbit, destinationOrbit)
    local mu = originOrbit.centralBody.gravity * originOrbit.centralBody.mass
    local r1 = originOrbit.semiMajorAxis
    local r2 = destinationOrbit.semiMajorAxis
    
    -- Use Hohmann transfer as initial guess
    local transferTime = math.pi * math.sqrt(((r1 + r2)^3)/(8 * mu))
    
    -- Iterate to find optimal time
    for i = 1, MAX_ITERATIONS do
        local error = self:CalculateTransferError(originOrbit, destinationOrbit, transferTime)
        if math.abs(error) < ORBITAL_PRECISION then
            break
        end
        transferTime = transferTime - error / 2
    end
    
    return transferTime
end

-- Enable docking assist mode
function AutopilotSystem:EnableDockingAssist(vehicle, targetPort)
    self.assistMode = {
        vehicle = vehicle,
        targetPort = targetPort,
        active = true
    }
    
    -- Start guidance updates
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        if self.assistMode and self.assistMode.active then
            self:UpdateDockingGuidance(dt)
        end
    end)
end

-- Update docking guidance
function AutopilotSystem:UpdateDockingGuidance(dt)
    if not self.assistMode or not self.assistMode.active then return end
    
    local vehicle = self.assistMode.vehicle
    local targetPort = self.assistMode.targetPort
    
    -- Calculate relative position and velocity
    local relativePos = targetPort.Position - vehicle.PrimaryPart.Position
    local relativeVel = targetPort.Velocity - vehicle.PrimaryPart.Velocity
    
    -- Generate guidance commands
    local guidanceCommands = self:CalculateDockingCommands(relativePos, relativeVel)
    self:ExecuteGuidanceCommands(vehicle, guidanceCommands)
end

-- Calculate docking approach commands
function AutopilotSystem:CalculateDockingCommands(relativePos, relativeVel)
    -- PD controller for approach
    local Kp = 0.1 -- Position gain
    local Kd = 0.2 -- Velocity gain
    
    local targetVel = relativePos.Unit * math.min(relativePos.Magnitude, 2) -- Max 2 studs/s
    local velError = targetVel - relativeVel
    
    return {
        thrust = relativePos.Unit * Kp + velError * Kd,
        alignment = -relativePos.Unit -- Point towards target
    }
end

-- Execute guidance commands
function AutopilotSystem:ExecuteGuidanceCommands(vehicle, commands)
    -- Apply thrust
    local thrustForce = Instance.new("VectorForce")
    thrustForce.Force = commands.thrust * 1000 -- Scale for reasonable force
    thrustForce.Parent = vehicle.PrimaryPart
    
    -- Apply rotation to align with target
    local targetCFrame = CFrame.new(vehicle.PrimaryPart.Position, 
        vehicle.PrimaryPart.Position + commands.alignment)
    vehicle.PrimaryPart.CFrame = vehicle.PrimaryPart.CFrame:Lerp(targetCFrame, 0.1)
end

-- Create a new maneuver node
function AutopilotSystem:CreateManeuverNode(position, deltaV, time)
    local node = {
        position = position,
        deltaV = deltaV,
        time = time,
        executed = false
    }
    
    table.insert(self.activeManeuvers, node)
    return node
end

-- Execute maneuver node
function AutopilotSystem:ExecuteManeuver(vehicle, node)
    if node.executed then return end
    
    -- Calculate burn time
    local thrust = vehicle:GetTotalThrust()
    local mass = vehicle:GetTotalMass()
    local burnTime = (node.deltaV * mass) / thrust
    
    -- Start burn at T-burnTime/2 for optimal timing
    local startTime = node.time - burnTime/2
    local endTime = node.time + burnTime/2
    
    -- Execute burn
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        local currentTime = workspace:GetServerTimeNow()
        if currentTime >= startTime and currentTime <= endTime then
            local burnVector = node.deltaV.Unit * thrust
            vehicle:ApplyThrust(burnVector)
        elseif currentTime > endTime then
            node.executed = true
        end
    end)
end

return AutopilotSystem
