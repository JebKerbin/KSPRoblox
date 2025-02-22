local AlertSystem = {}

-- Constants for alert types
local ALERT_TYPES = {
    WARNING = {
        soundId = "PATH_TO_WARNING_SOUND",  -- TODO: Add warning sound file
        color = Color3.fromRGB(255, 200, 0),
        volume = 0.7,
        flashRate = 1
    },
    CRITICAL = {
        soundId = "PATH_TO_CRITICAL_SOUND",  -- TODO: Add critical alert sound file
        color = Color3.fromRGB(255, 0, 0),
        volume = 1,
        flashRate = 2
    },
    INFO = {
        soundId = "PATH_TO_INFO_SOUND",  -- TODO: Add info notification sound
        color = Color3.fromRGB(0, 200, 255),
        volume = 0.5,
        flashRate = 0.5
    }
}

-- Store active alerts
AlertSystem.activeAlerts = {}

function AlertSystem:Init()
    -- Initialize alert container
    self.alertContainer = Instance.new("Folder")
    self.alertContainer.Name = "AlertEffects"
    self.alertContainer.Parent = workspace
end

function AlertSystem:CreateAlert(vehiclePart, alertType, message)
    if not ALERT_TYPES[alertType] then return end

    local alertData = ALERT_TYPES[alertType]
    local alert = {
        sound = Instance.new("Sound"),
        visual = Instance.new("BillboardGui"),
        startTime = tick()
    }

    -- Set up sound
    alert.sound.SoundId = alertData.soundId
    alert.sound.Volume = alertData.volume
    alert.sound.Looped = alertType == "CRITICAL"
    alert.sound.Parent = vehiclePart

    -- Set up visual indicator
    alert.visual.Size = UDim2.new(0, 100, 0, 50)
    alert.visual.StudsOffset = Vector3.new(0, 3, 0)
    alert.visual.Parent = vehiclePart

    -- Create text label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.3
    label.BackgroundColor3 = alertData.color
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = message
    label.Parent = alert.visual

    -- Start alert
    alert.sound:Play()

    -- Store alert
    self.activeAlerts[vehiclePart] = alert

    -- Set up auto-cleanup for non-critical alerts
    if alertType ~= "CRITICAL" then
        game:GetService("Debris"):AddItem(alert.sound, 3)
        game:GetService("Debris"):AddItem(alert.visual, 3)
    end

    return alert
end

function AlertSystem:UpdateAlerts(dt)
    for part, alert in pairs(self.activeAlerts) do
        if not part:IsDescendantOf(workspace) then
            -- Clean up if part is removed
            alert.sound:Destroy()
            alert.visual:Destroy()
            self.activeAlerts[part] = nil
        else
            -- Update visual effects (flashing)
            local alertType = alert.sound.Looped and "CRITICAL" or "WARNING"
            local flashRate = ALERT_TYPES[alertType].flashRate
            local alpha = (math.sin(tick() * flashRate * math.pi * 2) + 1) / 2
            local label = alert.visual:FindFirstChild("TextLabel")
            if label then
                label.BackgroundTransparency = 0.3 + (0.7 * alpha)
            end
        end
    end
end

function AlertSystem:ClearAlert(vehiclePart)
    local alert = self.activeAlerts[vehiclePart]
    if alert then
        alert.sound:Destroy()
        alert.visual:Destroy()
        self.activeAlerts[vehiclePart] = nil
    end
end

return AlertSystem