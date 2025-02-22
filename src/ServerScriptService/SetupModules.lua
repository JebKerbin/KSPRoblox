local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Debug settings
local DEBUG_MODE = true

local function LogDebug(message)
    if DEBUG_MODE then
        print("[SetupModules] " .. message)
    end
end

local function EnsureFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

-- Setup required folders
local physicsFolder = EnsureFolder(ReplicatedStorage, "Physics")
local environmentFolder = EnsureFolder(ReplicatedStorage, "Environment")
local navigationFolder = EnsureFolder(ReplicatedStorage, "Navigation")
local rocketsFolder = EnsureFolder(ReplicatedStorage, "Rockets")
local spaceStationFolder = EnsureFolder(ReplicatedStorage, "SpaceStation")
local alertsFolder = EnsureFolder(ReplicatedStorage, "Alerts")

-- Physics modules to copy
local physicsModules = {
    "SolarSystemConfig",
    "SolarSystemBuilder",
    "PlanetGravity",
    "OrbitSystem",
    "KerbinGravity",
    "PlanetPositioner",
    "ReentrySystem",
    "ReentryEffects"
}

-- Move Physics modules to ReplicatedStorage
for _, moduleName in ipairs(physicsModules) do
    local sourceModule = script.Parent:FindFirstChild(moduleName)
    if sourceModule then
        local existingModule = physicsFolder:FindFirstChild(moduleName)
        if existingModule then
            existingModule:Destroy()
        end
        local newModule = sourceModule:Clone()
        newModule.Parent = physicsFolder
        LogDebug("Moved " .. moduleName .. " to Physics folder")
    else
        warn("Could not find module: " .. moduleName)
    end
end

LogDebug("Module setup complete")
