local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Debug settings
local DEBUG_MODE = true

-- Debug logging function
local function LogDebug(system, action, message, ...)
    if DEBUG_MODE then
        print(string.format("[SystemInitializer:%s:%s] %s", system, action, string.format(message, ...)))
    end
end

-- System Initializer
local SystemInitializer = {}

-- Ensure Physics folder exists in ReplicatedStorage
local function EnsurePhysicsFolder()
    local physicsFolder = ReplicatedStorage:FindFirstChild("Physics")
    if not physicsFolder then
        physicsFolder = Instance.new("Folder")
        physicsFolder.Name = "Physics"
        physicsFolder.Parent = ReplicatedStorage
    end
    return physicsFolder
end

-- List of systems to initialize in order
local SYSTEMS = {
    {
        name = "GameManager",
        path = ServerScriptService.GameManager
    },
    {
        name = "SolarSystemBuilder",
        path = EnsurePhysicsFolder().SolarSystemBuilder
    },
    {
        name = "PlanetGravity",
        path = EnsurePhysicsFolder().PlanetGravity
    },
    {
        name = "OrbitSystem",
        path = EnsurePhysicsFolder().OrbitSystem
    },
    {
        name = "RocketBuilder",
        path = ReplicatedStorage.Rockets.RocketBuilder
    },
    {
        name = "AutopilotSystem",
        path = ReplicatedStorage.Navigation.AutopilotSystem
    },
    {
        name = "SpaceStationSystem",
        path = ReplicatedStorage.SpaceStation.SpaceStationSystem
    },
    {
        name = "AlertSystem",
        path = ReplicatedStorage.Alerts.AlertSystem
    }
}

-- Initialize a single system with error handling
function SystemInitializer:InitializeSystem(systemInfo)
    LogDebug("Init", "Start", "Initializing system: %s", systemInfo.name)

    -- Check if path exists
    if not systemInfo.path then
        warn(string.format("[SystemInitializer] Path not found for %s", systemInfo.name))
        return false
    end

    local success, system = pcall(function()
        return require(systemInfo.path)
    end)

    if not success then
        warn(string.format("[SystemInitializer] Failed to require %s: %s", systemInfo.name, tostring(system)))
        return false
    end

    if type(system.Init) ~= "function" then
        warn(string.format("[SystemInitializer] %s has no Init function", systemInfo.name))
        return false
    end

    success = pcall(function()
        system:Init()
    end)

    if not success then
        warn(string.format("[SystemInitializer] Failed to initialize %s", systemInfo.name))
        return false
    end

    LogDebug("Init", "Success", "Successfully initialized: %s", systemInfo.name)
    return true
end

-- Initialize all systems
function SystemInitializer:Start()
    LogDebug("Start", "Begin", "Starting system initialization")

    -- Ensure required folders exist
    EnsurePhysicsFolder()

    local successCount = 0
    local totalSystems = #SYSTEMS

    for _, systemInfo in ipairs(SYSTEMS) do
        if self:InitializeSystem(systemInfo) then
            successCount = successCount + 1
        end
    end

    LogDebug("Start", "Complete", "Initialized %d/%d systems", successCount, totalSystems)
    return successCount == totalSystems
end

-- Run the initializer
local success = SystemInitializer:Start()
if success then
    print("All systems initialized successfully!")
else
    warn("Some systems failed to initialize. Check logs for details.")
end

return SystemInitializer