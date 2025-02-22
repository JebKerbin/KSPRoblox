local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Debug settings
local DEBUG_MODE = true

-- Debug logging function
local function LogDebug(system, action, message, ...)
    if DEBUG_MODE then
        print(string.format("[EnableSystems:%s:%s] %s", system, action, string.format(message, ...)))
    end
end

-- Initialize systems in order
local function InitializeSystems()
    LogDebug("Init", "Start", "Beginning system initialization")
    
    -- Load GameManager first
    local GameManager = require(ServerScriptService.GameManager)
    if not GameManager then
        error("Failed to load GameManager")
        return
    end
    
    -- Initialize systems in the correct order
    local systemOrder = {
        {path = "Physics.PlanetGravity", name = "PlanetGravity"},
        {path = "Physics.KerbinGravity", name = "KerbinGravity"},
        {path = "Physics.OrbitSystem", name = "OrbitSystem"},
        {path = "Physics.SolarSystemBuilder", name = "SolarSystemBuilder"},
        {path = "Physics.SolarSystemScaler", name = "SolarSystemScaler"},
        {path = "Environment.WeatherSystem", name = "WeatherSystem"},
        {path = "Environment.SpaceDebrisSystem", name = "SpaceDebrisSystem"},
        {path = "Environment.EnvironmentalHazards", name = "EnvironmentalHazards"},
        {path = "Rockets.RocketBuilder", name = "RocketBuilder"},
        {path = "Physics.ReentrySystem", name = "ReentrySystem"},
        {path = "Physics.ReentryEffects", name = "ReentryEffects"},
        {path = "SpaceStation.SpaceStationSystem", name = "SpaceStationSystem"},
        {path = "Navigation.AutopilotSystem", name = "AutopilotSystem"},
        {path = "Alerts.AlertSystem", name = "AlertSystem"},
        {path = "Physics.PlanetPositioner", name = "PlanetPositioner"}
    }
    
    local systems = {}
    
    -- Require all systems first
    for _, systemInfo in ipairs(systemOrder) do
        local success, system = pcall(function()
            return require(ReplicatedStorage[systemInfo.path])
        end)
        
        if success and system then
            LogDebug("Load", systemInfo.name, "Successfully loaded %s", systemInfo.name)
            systems[systemInfo.name] = system
        else
            warn(string.format("Failed to load %s: %s", systemInfo.name, tostring(system)))
        end
    end
    
    -- Initialize GameManager first
    local success = GameManager:Init()
    if not success then
        error("Failed to initialize GameManager")
        return
    end
    LogDebug("Init", "GameManager", "GameManager initialized successfully")
    
    -- Initialize each system
    for _, systemInfo in ipairs(systemOrder) do
        local system = systems[systemInfo.name]
        if system then
            if type(system.Init) == "function" then
                local success, err = pcall(function()
                    system:Init()
                end)
                
                if success then
                    LogDebug("Init", systemInfo.name, "%s initialized successfully", systemInfo.name)
                else
                    warn(string.format("Failed to initialize %s: %s", systemInfo.name, tostring(err)))
                end
            else
                LogDebug("Init", systemInfo.name, "%s has no Init function, skipping", systemInfo.name)
            end
        end
    end
    
    LogDebug("Init", "Complete", "All systems initialized")
end

-- Wait for game to load
game:GetService("RunService").Heartbeat:Wait()

-- Start initialization
InitializeSystems()
