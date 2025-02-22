local RocketBuilder = {}

-- Import required services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Debug settings
local DEBUG_MODE = true

-- Reference to stock ships folder with proper error handling
local StockShips = ReplicatedStorage:WaitForChild("StockShips", 10)
if not StockShips then
    error("[RocketBuilder] StockShips folder not found in ReplicatedStorage after 10 seconds")
end

-- Rocket component templates
RocketBuilder.ComponentTypes = {
    Core = {
        required = true,
        maxCount = 1,
        children = {
            "CommandModule",
            "Hatch",
            "ControlPanel",
            "FuelTank",
            "Engine"
        }
    },
    Payload = {
        required = false,
        maxCount = 1,
        children = {
            "PayloadBay",
            "Satellite"
        }
    },
    Fairing = {
        required = false,
        maxCount = 1,
        separable = true,
        children = {
            "Fairing_Left",
            "Fairing_Right",
            "FairingBase"
        }
    },
    RCS = {
        required = false,
        maxCount = 4
    },
    Boosters = {
        required = false,
        maxCount = 4,
        separable = true
    }
}

function RocketBuilder:Init()
    if DEBUG_MODE then
        print("[RocketBuilder] Starting initialization")
    end

    self.activeRockets = {}
    self.rocketConfigs = {}

    -- Create collision groups with proper error handling
    local success, err = pcall(function()
        PhysicsService:CreateCollisionGroup("Rockets")
        PhysicsService:CreateCollisionGroup("Debris")
        -- Make rockets not collide with debris
        PhysicsService:CollisionGroupSetCollidable("Rockets", "Debris", false)
    end)

    if not success then
        warn("[RocketBuilder] Failed to create collision groups:", err)
    end

    -- Validate component templates with proper error handling
    for componentType, config in pairs(self.ComponentTypes) do
        local template = StockShips:FindFirstChild(componentType)
        if not template then
            warn(string.format("[RocketBuilder] Template '%s' not found in StockShips", componentType))
        end
    end

    if DEBUG_MODE then
        print("[RocketBuilder] Initialized and validated templates")
    end
end

-- Create new rocket from template with proper Roblox instance handling
function RocketBuilder:CreateRocket(templateName)
    local template = StockShips:FindFirstChild(templateName)
    if not template then
        warn(string.format("[RocketBuilder] Template '%s' not found", templateName))
        return nil
    end

    -- Create rocket container
    local rocketModel = Instance.new("Model")
    rocketModel.Name = templateName

    local rocket = {
        model = rocketModel,
        components = {},
        stages = {},
        currentStage = 1,
        assembled = false
    }

    -- Initialize component tracking
    for componentType, _ in pairs(self.ComponentTypes) do
        rocket.components[componentType] = {}
    end

    -- Register the new rocket
    table.insert(self.activeRockets, rocket)
    rocketModel.Parent = workspace

    if DEBUG_MODE then
        print(string.format("[RocketBuilder] Created rocket from template '%s'", templateName))
    end

    return rocket
end

-- Add component to rocket using proper Roblox parenting and physics
function RocketBuilder:AddComponent(rocket, componentType, position)
    if not rocket or not self.ComponentTypes[componentType] then return nil end

    local config = self.ComponentTypes[componentType]
    local currentCount = #rocket.components[componentType]

    if currentCount >= (config.maxCount or math.huge) then
        warn(string.format("[RocketBuilder] Maximum %s count reached", componentType))
        return nil
    end

    -- Create component from template
    local template = StockShips:FindFirstChild(componentType)
    if not template then
        warn(string.format("[RocketBuilder] Component template '%s' not found", componentType))
        return nil
    end

    local component = template:Clone()
    component.Name = string.format("%s_%d", componentType, currentCount + 1)

    -- Set position if provided
    if position then
        component:SetPrimaryPartCFrame(CFrame.new(position))
    end

    -- Set up physics properties
    if component.PrimaryPart then
        -- Set collision group
        PhysicsService:SetPartCollisionGroup(component.PrimaryPart, "Rockets")

        -- Apply default physics properties
        component.PrimaryPart.CustomPhysicalProperties = PhysicalProperties.new(
            0.7, -- Density
            0.3, -- Friction
            0.5, -- Elasticity
            1,   -- FrictionWeight
            1    -- ElasticityWeight
        )
    end

    -- Add to rocket's components
    table.insert(rocket.components[componentType], component)
    component.Parent = rocket.model

    if DEBUG_MODE then
        print(string.format("[RocketBuilder] Added %s to rocket", componentType))
    end

    return component
end

-- Configure staging with proper Roblox constraints
function RocketBuilder:ConfigureStaging(rocket)
    if not rocket then return end

    rocket.stages = {
        -- Stage 1: Main engines + boosters
        {
            components = {"Core.Engine", "Boosters"},
            separation = {"Boosters"}
        },
        -- Stage 2: Payload deployment
        {
            components = {"Payload"},
            separation = {"Fairing"}
        }
    }

    -- Add physical constraints between stages
    for _, stage in ipairs(rocket.stages) do
        for _, componentType in ipairs(stage.components) do
            local components = rocket.components[componentType]
            if components then
                for _, component in ipairs(components) do
                    if component.PrimaryPart then
                        -- Add breakable constraints for separable components
                        if table.find(stage.separation or {}, componentType) then
                            local constraint = Instance.new("WeldConstraint")
                            constraint.Name = "StagingConstraint"
                            constraint.Part0 = rocket.model.PrimaryPart
                            constraint.Part1 = component.PrimaryPart
                            constraint.Parent = component
                        end
                    end
                end
            end
        end
    end

    if DEBUG_MODE then
        print("[RocketBuilder] Configured staging sequence")
    end
end

-- Separate component using proper Roblox physics
function RocketBuilder:SeparateComponent(rocket, componentType)
    if not rocket or not self.ComponentTypes[componentType] then return end

    local components = rocket.components[componentType]
    for _, component in ipairs(components) do
        -- Add separation force using Roblox's BodyForce
        local primaryPart = component.PrimaryPart
        if primaryPart then
            -- Break staging constraints
            for _, child in ipairs(component:GetChildren()) do
                if child:IsA("WeldConstraint") and child.Name == "StagingConstraint" then
                    child:Destroy()
                end
            end

            -- Set up separation physics
            primaryPart.Anchored = false
            PhysicsService:SetPartCollisionGroup(primaryPart, "Debris")

            local separationForce = Instance.new("BodyForce")
            separationForce.Force = Vector3.new(
                math.random(-1000, 1000),
                math.random(500, 1000),
                math.random(-1000, 1000)
            )
            separationForce.Parent = primaryPart

            -- Add visual effects
            local smoke = Instance.new("Smoke")
            smoke.Color = Color3.fromRGB(200, 200, 200)
            smoke.Size = 0.5
            smoke.RiseVelocity = 2
            smoke.Parent = primaryPart

            -- Clean up after separation
            Debris:AddItem(component, 10)
        end
    end

    if DEBUG_MODE then
        print(string.format("[RocketBuilder] Separated %s components", componentType))
    end
end

-- Add cleanup method for proper instance management
function RocketBuilder:Cleanup()
    -- Clean up active rockets
    for _, rocket in pairs(self.activeRockets) do
        if rocket.model then
            rocket.model:Destroy()
        end
    end
    self.activeRockets = {}
end

return RocketBuilder