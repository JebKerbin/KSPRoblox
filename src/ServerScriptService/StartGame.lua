-- Initialize game systems
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Enable debug mode for development
_G.DEBUG_MODE = true

-- Setup debug logging
local function log(message)
    if _G.DEBUG_MODE then
        print("[StartGame] " .. message)
    end
end

-- Setup modules first
local success, err = pcall(function()
    require(ServerScriptService.SetupModules)
    log("Modules setup completed successfully")
end)

if not success then
    warn("[StartGame] Failed to setup modules:", err)
    return
end

-- Initialize required systems in order
local function InitializeSystems()
    log("Starting systems initialization...")

    -- Track initialization status for each system
    local systemStatus = {
        GameManager = false,
        WeatherSystem = false,
        SpaceStation = false,
        Physics = false,
        PlanetPositioner = false
    }

    -- Initialize GameManager first
    local success, err = pcall(function()
        local GameManager = require(ServerScriptService.GameManager)
        local initSuccess = GameManager:Init()
        if initSuccess then
            systemStatus.GameManager = true
            systemStatus.WeatherSystem = true -- WeatherSystem is initialized within GameManager
            systemStatus.SpaceStation = true -- SpaceStationSystem is initialized within GameManager
            log("GameManager and subsystems initialized successfully")
        else
            warn("[StartGame] GameManager initialization returned false")
            return false
        end
    end)

    if not success then
        warn("[StartGame] Failed to initialize GameManager:", err)
        return false
    end

    -- Verify all systems initialized
    for system, status in pairs(systemStatus) do
        if not status then
            warn("[StartGame] System failed to initialize:", system)
            return false
        end
    end

    log("All systems initialized successfully!")
    return true
end

-- Start the game
local function Start()
    log("Beginning game initialization...")

    if InitializeSystems() then
        log("Game systems started successfully!")
    else
        warn("[StartGame] Failed to initialize game systems")
    end
end

-- Run the initialization
Start()