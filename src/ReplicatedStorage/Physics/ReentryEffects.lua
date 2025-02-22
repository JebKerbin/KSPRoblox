local ReentryEffects = {}

-- Constants for reentry effects
local HEAT_THRESHOLD = 1000 -- Speed at which heat effects start
local MAX_HEAT = 3000 -- Speed for maximum heat effects
local ATMOSPHERE_START = 70000 -- Height where reentry effects begin

function ReentryEffects:Init()
    self.activeEffects = {}
end

-- Create reentry effects for a vehicle
function ReentryEffects:CreateEffects(vehicle)
    if self.activeEffects[vehicle] then return end

    local effects = {
        -- Heat glow
        heatGlow = Instance.new("ParticleEmitter"),
        -- Plasma trail
        plasmaTrail = Instance.new("Trail"),
        -- Shock wave
        shockWave = Instance.new("ParticleEmitter"),
        -- Sound effect
        sound = Instance.new("Sound")
    }

    -- Configure heat glow
    effects.heatGlow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 200))
    })
    effects.heatGlow.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 1)
    })
    effects.heatGlow.Lifetime = NumberRange.new(0.2, 0.5)
    effects.heatGlow.Rate = 100
    effects.heatGlow.Speed = NumberRange.new(5)
    effects.heatGlow.Parent = vehicle.PrimaryPart

    -- Configure plasma trail
    effects.plasmaTrail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 200))
    })
    effects.plasmaTrail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    effects.plasmaTrail.Lifetime = 0.5
    effects.plasmaTrail.Parent = vehicle.PrimaryPart

    -- Configure shock wave
    effects.shockWave.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
    effects.shockWave.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 5),
        NumberSequenceKeypoint.new(1, 0)
    })
    effects.shockWave.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    effects.shockWave.Lifetime = NumberRange.new(0.1, 0.2)
    effects.shockWave.Speed = NumberRange.new(50)
    effects.shockWave.Parent = vehicle.PrimaryPart

    -- Configure sound
    effects.sound.SoundId = "PATH_TO_REENTRY_SOUND" -- TODO: Add reentry whoosh/rumble sound
    effects.sound.Volume = 0
    effects.sound.Looped = true
    effects.sound.Parent = vehicle.PrimaryPart
    effects.sound:Play()

    self.activeEffects[vehicle] = effects
end

-- Update reentry effects based on vehicle state
function ReentryEffects:UpdateEffects(vehicle, velocity, altitude)
    local effects = self.activeEffects[vehicle]
    if not effects then return end

    -- Calculate heat factor based on speed and altitude
    local speed = velocity.Magnitude
    local heatFactor = math.clamp((speed - HEAT_THRESHOLD) / (MAX_HEAT - HEAT_THRESHOLD), 0, 1)
    local atmosphereFactor = math.clamp((ATMOSPHERE_START - altitude) / ATMOSPHERE_START, 0, 1)
    local effectIntensity = heatFactor * atmosphereFactor

    -- Update heat glow
    effects.heatGlow.Rate = effectIntensity * 100
    effects.heatGlow.Size = NumberSequence.new(effectIntensity * 3)

    -- Update plasma trail
    effects.plasmaTrail.Lifetime = effectIntensity * 0.5

    -- Update shock wave
    effects.shockWave.Rate = effectIntensity > 0.5 and 50 or 0

    -- Update sound
    effects.sound.Volume = effectIntensity * 2
    effects.sound.PlaybackSpeed = 0.5 + effectIntensity * 1.5

    -- Update vehicle appearance
    vehicle.PrimaryPart.Color = Color3.new(1, 1, 1):Lerp(
        Color3.fromRGB(255, 100, 0),
        effectIntensity
    )
end

-- Remove effects
function ReentryEffects:RemoveEffects(vehicle)
    local effects = self.activeEffects[vehicle]
    if not effects then return end

    for _, effect in pairs(effects) do
        effect:Destroy()
    end

    self.activeEffects[vehicle] = nil
end

return ReentryEffects