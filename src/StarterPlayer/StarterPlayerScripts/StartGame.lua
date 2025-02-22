local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

print("[StartGame] Starting game initialization...")

-- Wait for GameManager to be available
local function waitForModule(parent, name)
    local module = parent:WaitForChild(name, 10)
    if not module then
        error(string.format("Failed to find %s in %s after 10 seconds", name, parent.Name))
    end
    return module
end

local GameManager = require(waitForModule(ServerScriptService, "GameManager"))

-- Initialize the game
local success, error = pcall(function()
    print("[StartGame] Initializing GameManager...")
    if GameManager:Init() then
        print("[StartGame] Game initialized successfully!")
    else
        warn("[StartGame] Game initialization failed!")
    end
end)

if not success then
    warn("[StartGame] Error during initialization:", error)
end
