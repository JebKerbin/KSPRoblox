local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")

-- Debug settings
local DEBUG_MODE = true -- Ensure this is true

-- Debug logging function with immediate output and visual separation
local function LogDebug(system, action, message, ...)
    if DEBUG_MODE then
        print("\n===========================================")
        print(string.format("[GameManager:%s:%s] %s", system, action, string.format(message, ...)))
        print("===========================================\n")
    end
end

-- Create GameManager table
local GameManager = {
    connections = {},
    playerData = {},
    vehicleDamage = {},
    initialized = false
}

-- Load all required modules with proper error handling
local function requireModule(modulePath)
    LogDebug("ModuleLoader", "Require", "Loading module: %s", tostring(modulePath))

    -- Wrap in pcall for error handling
    local success, module = pcall(function()
        return require(modulePath)
    end)

    if not success then
        warn("[GameManager] Failed to require module:", modulePath, module)
        return nil
    end

    LogDebug("ModuleLoader", "Success", "Loaded module: %s", tostring(modulePath))
    return module
end

-- Add this to the top with other requires
local SolarSystemBuilder = require(ReplicatedStorage.Physics.SolarSystemBuilder)

-- Validate StockShips folder exists
local StockShips = ReplicatedStorage:WaitForChild("StockShips")
if not StockShips then
    error("[GameManager] StockShips folder not found in ReplicatedStorage")
end

-- Create asset folders with validation
function GameManager:CreateAssetFolders()
    LogDebug("AssetManager", "Init", "Starting asset folder creation")

    local folderStructure = {
        Assets = {
            Planets = {"Kerbin", "Mun", "Duna"},
            SpaceStation = {"Modules", "Docking"},
            Effects = {"Particles", "Trails", "Explosions"},
            UI = {"Icons", "Textures"}
        },
        StockShips = {
            "CommandModules",
            "Engines",
            "FuelTanks",
            "Payload",
            "RCS"
        }
    }

    -- Create folders recursively with validation
    local function createFolders(parent, structure)
        for name, subfolders in pairs(structure) do
            local folder = parent:FindFirstChild(name)
            if not folder then
                folder = Instance.new("Folder")
                folder.Name = name
                folder.Parent = parent
                LogDebug("AssetManager", "Create", "Created folder: %s", name)
            end

            if type(subfolders) == "table" then
                if type(subfolders[1]) == "string" then
                    -- Create simple subfolders
                    for _, subfolder in ipairs(subfolders) do
                        local sub = folder:FindFirstChild(subfolder)
                        if not sub then
                            sub = Instance.new("Folder")
                            sub.Name = subfolder
                            sub.Parent = folder
                            LogDebug("AssetManager", "Create", "Created subfolder: %s/%s", name, subfolder)
                        end
                    end
                else
                    -- Recursively create nested structure
                    createFolders(folder, subfolders)
                end
            end
        end
    end

    createFolders(ReplicatedStorage, folderStructure)
    LogDebug("AssetManager", "Complete", "Asset folders created successfully")

    -- Validate critical folders exist
    local criticalPaths = {
        "Assets/Planets",
        "Assets/Effects",
        "StockShips/Engines"
    }

    for _, path in ipairs(criticalPaths) do
        local success = self:ValidateFolderPath(ReplicatedStorage, path)
        if not success then
            error(string.format("[GameManager] Critical folder path missing: %s", path))
        end
    end
end

-- Validate folder path exists
function GameManager:ValidateFolderPath(root, path)
    local parts = string.split(path, "/")
    local current = root

    for _, part in ipairs(parts) do
        current = current:FindFirstChild(part)
        if not current then
            LogDebug("AssetManager", "Error", "Missing folder in path: %s", part)
            return false
        end
    end

    return true
end

-- Add validation function to check planet assets
function GameManager:ValidatePlanetAssets()
    LogDebug("AssetManager", "Validate", "Starting planet asset validation")

    local requiredPlanets = {
        "Kerbin", "Mun", "Duna"
    }

    local Assets = ReplicatedStorage:FindFirstChild("Assets")
    if not Assets then
        error("[GameManager] Assets folder not found in ReplicatedStorage")
        return false
    end

    local Planets = Assets:FindFirstChild("Planets")
    if not Planets then
        error("[GameManager] Planets folder not found in Assets")
        return false
    end

    -- Check each required planet folder and its assets
    for _, planetName in ipairs(requiredPlanets) do
        local planetFolder = Planets:FindFirstChild(planetName)
        if not planetFolder then
            error(string.format("[GameManager] Required planet folder missing: %s", planetName))
            return false
        end

        -- Check for required planet assets
        local requiredAssets = {
            planetName .. ".rbxm",  -- 3D mesh
            "surface_albedo.png",   -- Surface texture
        }

        for _, assetName in ipairs(requiredAssets) do
            if not planetFolder:FindFirstChild(assetName) then
                LogDebug("AssetManager", "Warning",
                    "Missing asset %s for planet %s", assetName, planetName)
            end
        end
    end

    LogDebug("AssetManager", "Validate", "Planet asset validation complete")
    return true
end

-- Initialize game systems
function GameManager:Init()
    if self.initialized then
        warn("[GameManager] Already initialized!")
        return true
    end

    print("\n========== GAME MANAGER INITIALIZATION START ==========\n")

    -- Create solar system first
    local solarSystem = SolarSystemBuilder:CreateSolarSystem()
    if not solarSystem then
        error("[GameManager] Failed to create solar system")
        return false
    end
    LogDebug("Init", "System", "Solar system created")

    -- Rest of the initialization remains the same
    self:CreateAssetFolders()
    LogDebug("Init", "System", "Asset folders created")

    if not self:ValidatePlanetAssets() then
        warn("[GameManager] Planet asset validation failed")
    end
    LogDebug("Init", "System", "Planet assets validated")

    print("\n========== LOADING GAME SYSTEMS ==========\n")

    -- Define initialization order with explicit system paths
    local systemInitOrder = {
        {ReplicatedStorage.Physics.PlanetGravity, "PlanetGravity"},
        {ReplicatedStorage.Physics.KerbinGravity, "KerbinGravity"},
        {ReplicatedStorage.Physics.OrbitSystem, "OrbitSystem"},
        {ReplicatedStorage.Environment.WeatherSystem, "WeatherSystem"},
        {ReplicatedStorage.Environment.SpaceDebrisSystem, "SpaceDebrisSystem"},
        {ReplicatedStorage.Environment.EnvironmentalHazards, "EnvironmentalHazards"},
        {ReplicatedStorage.Rockets.RocketBuilder, "RocketBuilder"},
        {ReplicatedStorage.Physics.ReentrySystem, "ReentrySystem"},
        {ReplicatedStorage.Physics.ReentryEffects, "ReentryEffects"},
        {ReplicatedStorage.SpaceStation.SpaceStationSystem, "SpaceStationSystem"},
        {ReplicatedStorage.Navigation.AutopilotSystem, "AutopilotSystem"},
        {ReplicatedStorage.Alerts.AlertSystem, "AlertSystem"},
        {ReplicatedStorage.Physics.PlanetPositioner, "PlanetPositioner"}
    }

    -- Initialize each system in order with clear logging
    for _, systemInfo in ipairs(systemInitOrder) do
        local modulePath, systemName = systemInfo[1], systemInfo[2]

        LogDebug("Init", systemName, "Loading system...")

        -- Require the module
        local success, system = pcall(function()
            return require(modulePath)
        end)

        if not success then
            warn(string.format("[GameManager] Failed to require %s: %s", systemName, tostring(system)))
            return false
        end

        -- Initialize the system
        success = pcall(function()
            if system.Init then
                system:Init()
                LogDebug("Init", systemName, "System initialized successfully")
            else
                warn(string.format("[GameManager] %s has no Init function", systemName))
            end
        end)

        if not success then
            warn(string.format("[GameManager] Failed to initialize %s", systemName))
            return false
        end
    end

    -- Set up event connections
    self:SetupEventConnections()
    LogDebug("Init", "System", "Event connections established")

    -- Initialize game environment
    self:InitializeGameEnvironment()
    LogDebug("Init", "System", "Game environment initialized")

    self.initialized = true
    print("\n========== GAME MANAGER INITIALIZATION COMPLETE ==========\n")
    return true
end

-- Set up event connections
function GameManager:SetupEventConnections()
    -- Player events
    table.insert(self.connections, Players.PlayerAdded:Connect(function(player)
        self:HandleNewPlayer(player)
    end))

    table.insert(self.connections, Players.PlayerRemoving:Connect(function(player)
        self:SavePlayerData(player)
    end))

    -- Physics update loop
    table.insert(self.connections, RunService.Heartbeat:Connect(function(dt)
        self:UpdatePhysics(dt)
        if AlertSystem then
            AlertSystem:UpdateAlerts(dt)
        end
    end))
end

-- Initialize game environment
function GameManager:InitializeGameEnvironment()
    -- Create asteroid field
    self:InitializeAsteroidField()

    -- Set up weather effects for planets
    self:InitializeWeatherEffects()
end

-- Cleanup function
function GameManager:Cleanup()
    -- Disconnect all connections
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end

    -- Clean up systems
    local systems = {
        RocketBuilder, WeatherSystem, KerbinGravity, PlanetGravity,
        OrbitSystem, ReentrySystem, EnvironmentalHazards, SpaceStationSystem,
        AutopilotSystem, SpaceDebrisSystem, ReentryEffects, AlertSystem,
        PlanetPositioner
    }

    for _, system in ipairs(systems) do
        if system and type(system.Cleanup) == "function" then
            system:Cleanup()
        end
    end
end

-- Handle new player joining
function GameManager:HandleNewPlayer(player)
    -- Create initial player data
    self.playerData[player.UserId] = {
        research = 0,
        missions = {},
        achievements = {},
        unlockedTech = {"BasicRocketry"},
        activeMission = nil,
        missionProgress = {},
        totalRewards = 0
    }

    -- Set up player's starting position on Kerbin
    local spawnLocation = workspace.SpawnLocation
    player.Character:MoveTo(spawnLocation.Position)
end

-- Save player data when they leave
function GameManager:SavePlayerData(player)
    -- Here you would implement data persistence
    self.playerData[player.UserId] = nil
end

-- Update player mission progress
function GameManager:UpdateMissionProgress(player, objectiveType, value)
    local data = self.playerData[player.UserId]
    if not data or not data.activeMission then return end

    local mission = data.activeMission
    local progress = data.missionProgress

    -- Update specific mission objectives
    if objectiveType == "altitude" then
        if value >= 70000 and not progress.reachedSpace then
            progress.reachedSpace = true
            self:AwardProgress(player, "Reach 70km altitude", 30)
        end
    elseif objectiveType == "orbit" then
        if not progress.achievedOrbit then
            progress.achievedOrbit = true
            self:AwardProgress(player, "Achieve stable orbit", 50)
        end
    elseif objectiveType == "landing" then
        if not progress.landed then
            progress.landed = true
            self:AwardProgress(player, "Land safely", 75)
        end
    end

    -- Check for mission completion
    self:CheckMissionCompletion(player)
end

-- Award progress and rewards
function GameManager:AwardProgress(player, objective, reward)
    local data = self.playerData[player.UserId]
    if not data then return end

    data.totalRewards = data.totalRewards + reward

    -- Notify player of progress
    self:NotifyPlayer(player, "Objective Complete: " .. objective .. " (+" .. reward .. ")")
end

-- Check if current mission is complete
function GameManager:CheckMissionCompletion(player)
    local data = self.playerData[player.UserId]
    if not data or not data.activeMission then return end

    local mission = data.activeMission
    local progress = data.missionProgress
    local allComplete = true

    -- Check all objectives
    for _, objective in ipairs(mission.objectives) do
        if not progress[objective.id] then
            allComplete = false
            break
        end
    end

    if allComplete then
        -- Award mission completion
        self:CompleteMission(player, mission)
    end
end

-- Complete a mission
function GameManager:CompleteMission(player, mission)
    local data = self.playerData[player.UserId]
    if not data then return end

    -- Award final rewards
    data.totalRewards = data.totalRewards + mission.completionBonus
    data.missions[mission.id] = true
    data.activeMission = nil
    data.missionProgress = {}

    -- Unlock any rewards
    if mission.unlocks then
        for _, tech in ipairs(mission.unlocks) do
            if not table.find(data.unlockedTech, tech) then
                table.insert(data.unlockedTech, tech)
            end
        end
    end

    -- Notify player
    self:NotifyPlayer(player, "Mission Complete: " .. mission.name .. "!")
end

-- Notify player of events
function GameManager:NotifyPlayer(player, message)
    -- Here you would implement your notification system
    print("Notification for " .. player.Name .. ": " .. message)
end

-- Update physics systems each frame
function GameManager:UpdatePhysics(dt)
    -- Update orbital mechanics
    for object, orbit in pairs(OrbitSystem.activeOrbits) do
        OrbitSystem:UpdateOrbit(object, dt)
    end

    -- Update reentry physics for vehicles in atmosphere
    for vehicle, _ in pairs(ReentrySystem.activeVehicles) do
        local velocity = vehicle.PrimaryPart.Velocity
        local altitude = vehicle.PrimaryPart.Position.Y
        ReentryEffects:UpdateEffects(vehicle, velocity, altitude)

        -- Check for debris collisions
        local collisions = SpaceDebrisSystem:CheckDebrisCollision(
            vehicle.PrimaryPart.Position,
            vehicle.PrimaryPart.Size.Magnitude
        )

        if #collisions > 0 then
            -- Handle collision events
            self:HandleDebrisCollision(vehicle, collisions)
        end

        -- Update vehicle status UI
        local player = Players:GetPlayerFromCharacter(vehicle.PrimaryPart.Parent)
        if player then
            local vehicleData = self.vehicleDamage[vehicle]
            if vehicleData then
                -- Get the VehicleStatusUI from the player's GUI
                local gui = player.PlayerGui:FindFirstChild("VehicleStatus")
                if gui and gui.Parent then
                    local vehicleUI = require(gui)
                    vehicleUI:UpdateStatus(vehicleData.integrity, vehicleData.criticalSystems)
                end
            end
        end
    end

    -- Update environmental hazards
    EnvironmentalHazards:UpdateAsteroids(dt)

    -- Update space station docking physics
    SpaceStationSystem:UpdateDockingForces()
end

-- Handle debris collisions with enhanced damage system
function GameManager:HandleDebrisCollision(vehicle, collisions)
    -- Initialize damage tracking if needed
    if not self.vehicleDamage[vehicle] then
        self.vehicleDamage[vehicle] = {
            integrity = 100,
            criticalSystems = {
                engines = true,
                fuelTanks = true,
                controlSystems = true
            }
        }
    end

    for _, collision in ipairs(collisions) do
        -- Create explosion effect
        local explosion = Instance.new("Explosion")
        explosion.Position = collision.debris.Position
        explosion.BlastRadius = 10
        explosion.BlastPressure = 500000
        explosion.Parent = workspace

        -- Calculate damage based on debris size and velocity
        local debrisVelocity = collision.debris.Velocity or Vector3.new(0, 0, 0)
        local impactSpeed = debrisVelocity.Magnitude
        local baseDamage = collision.debris.Size.Magnitude * 10
        local damage = baseDamage * (1 + impactSpeed / 100)

        -- Apply damage to vehicle
        local vehicleData = self.vehicleDamage[vehicle]
        vehicleData.integrity = math.max(0, vehicleData.integrity - damage)

        -- Create alerts based on damage severity
        if vehicleData.integrity <= 25 then
            AlertSystem:CreateAlert(vehicle.PrimaryPart, "CRITICAL", "CRITICAL DAMAGE")
        elseif vehicleData.integrity <= 50 then
            AlertSystem:CreateAlert(vehicle.PrimaryPart, "WARNING", "WARNING: Hull Breach")
        end

        -- Random chance to damage critical systems
        if math.random() < 0.3 then
            local systems = {"engines", "fuelTanks", "controlSystems"}
            local damagedSystem = systems[math.random(1, #systems)]
            vehicleData.criticalSystems[damagedSystem] = false

            -- Add visual damage effects
            self:CreateDamageEffects(vehicle, damagedSystem)

            -- Add alerts for critical system damage
            if not vehicleData.criticalSystems.engines then
                AlertSystem:CreateAlert(vehicle.PrimaryPart, "CRITICAL", "ENGINE FAILURE")
            end
            if not vehicleData.criticalSystems.controlSystems then
                AlertSystem:CreateAlert(vehicle.PrimaryPart, "WARNING", "CONTROLS DAMAGED")
            end
            if not vehicleData.criticalSystems.fuelTanks then
                AlertSystem:CreateAlert(vehicle.PrimaryPart, "WARNING", "FUEL LEAK")
            end
        end

        -- Create impact sound
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxasset://sounds/collide.mp3"
        sound.Volume = math.min(1, damage / 50)
        sound.Parent = vehicle.PrimaryPart
        sound:Play()
        Debris:AddItem(sound, 2)

        -- Remove the debris
        collision.debris:Destroy()

        -- Notify any players in the vehicle
        local player = Players:GetPlayerFromCharacter(vehicle.PrimaryPart.Parent)
        if player then
            -- Create detailed damage report
            local damageReport = string.format(
                "Vehicle damaged by space debris!\nIntegrity: %d%%",
                math.floor(vehicleData.integrity)
            )

            -- Add critical systems status
            for system, isWorking in pairs(vehicleData.criticalSystems) do
                if not isWorking then
                    damageReport = damageReport .. "\n" .. system .. ": DAMAGED"
                end
            end

            self:NotifyPlayer(player, damageReport)

            -- Update vehicle status UI
            local gui = player.PlayerGui:FindFirstChild("VehicleStatus")
            if gui and gui.Parent then
                local vehicleUI = require(gui)
                vehicleUI:UpdateStatus(vehicleData.integrity, vehicleData.criticalSystems)
            end

            -- Check if this affects current mission
            if vehicleData.integrity <= 0 then
                self:HandleMissionFailure(player, "Vehicle destroyed by space debris")
            elseif not vehicleData.criticalSystems.engines then
                self:HandleMissionFailure(player, "Critical engine failure")
            end
        end
    end
end

-- Add new function for creating damage effects
function GameManager:CreateDamageEffects(vehicle, damagedSystem)
    local effects = {
        engines = {
            color = ColorSequence.new(Color3.fromRGB(255, 100, 0)),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 2),
                NumberSequenceKeypoint.new(1, 0)
            }),
            rate = 50
        },
        fuelTanks = {
            color = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0)
            }),
            rate = 30
        },
        controlSystems = {
            color = ColorSequence.new(Color3.fromRGB(255, 255, 0)),
            size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(1, 0)
            }),
            rate = 20
        }
    }

    local effect = effects[damagedSystem]
    if effect then
        local emitter = Instance.new("ParticleEmitter")
        emitter.Color = effect.color
        emitter.Size = effect.size
        emitter.Rate = effect.rate
        emitter.Lifetime = NumberRange.new(0.5, 1)
        emitter.Speed = NumberRange.new(5, 10)
        emitter.Parent = vehicle.PrimaryPart

        -- Add sparks for electrical damage
        if damagedSystem == "controlSystems" then
            local sparks = Instance.new("ParticleEmitter")
            sparks.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
            sparks.Size = NumberSequence.new(0.2)
            sparks.Rate = 10
            sparks.Lifetime = NumberRange.new(0.1, 0.2)
            sparks.Speed = NumberRange.new(10, 20)
            sparks.Parent = vehicle.PrimaryPart
        end
    end
end

-- Handle mission failure
function GameManager:HandleMissionFailure(player, reason)
    local data = self.playerData[player.UserId]
    if not data or not data.activeMission then return end

    -- Reset mission progress
    data.activeMission = nil
    data.missionProgress = {}

    -- Notify player
    self:NotifyPlayer(player, "Mission Failed: " .. reason)
end


-- Initialize asteroid field
function GameManager:InitializeAsteroidField()
    -- Create asteroids container
    local asteroids = Instance.new("Folder")
    asteroids.Name = "Asteroids"
    asteroids.Parent = workspace

    -- Spawn initial asteroids
    for i = 1, 50 do -- Start with 50 asteroids
        local position = Vector3.new(
            math.random(-5000, 5000),
            math.random(-5000, 5000),
            math.random(-5000, 5000)
        )
        EnvironmentalHazards:SpawnAsteroid(position)
    end
end

-- Initialize weather effects for all planets
function GameManager:InitializeWeatherEffects()
    for planet, _ in pairs(WeatherSystem.PLANET_WEATHER) do
        if workspace:FindFirstChild(planet) then
            -- Start with clear weather
            WeatherSystem.activeWeather[planet] = {
                currentType = "Clear",
                timeUntilChange = WeatherSystem.PLANET_WEATHER[planet].changeInterval,
                transitionStart = tick(),
                transitionDuration = 5
            }
            WeatherSystem:CreateWeatherEffects(planet, "Clear")

            if DEBUG_MODE then
                print(string.format("[GameManager] Initialized weather system for %s", planet))
            end
        end
    end
end

-- Start the game manager
if DEBUG_MODE then
    print("[GameManager] Module loaded, waiting for game start...")
end

return GameManager