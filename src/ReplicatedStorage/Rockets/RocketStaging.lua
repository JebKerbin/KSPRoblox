local RocketStaging = {}

function RocketStaging:Init()
    self.activeStages = {}
end

-- Create new staging sequence
function RocketStaging:CreateStaging(rocket)
    local staging = {
        rocket = rocket,
        stages = {},
        currentStage = 1
    }
    
    return staging
end

-- Add stage to rocket
function RocketStaging:AddStage(staging, parts)
    local stage = {
        parts = parts,
        active = false,
        engines = {},
        decouplers = {}
    }
    
    -- Categorize parts in stage
    for _, part in ipairs(parts) do
        if part.Name == "Engine" then
            table.insert(stage.engines, part)
        elseif part.Name == "Decoupler" then
            table.insert(stage.decouplers, part)
        end
    end
    
    table.insert(staging.stages, stage)
end

-- Activate next stage
function RocketStaging:ActivateNextStage(staging)
    local currentStage = staging.stages[staging.currentStage]
    
    -- Deactivate current stage
    if currentStage then
        self:DeactivateStage(currentStage)
    end
    
    -- Move to next stage
    staging.currentStage = staging.currentStage + 1
    local nextStage = staging.stages[staging.currentStage]
    
    if nextStage then
        self:ActivateStage(nextStage)
        return true
    end
    
    return false
end

-- Activate stage components
function RocketStaging:ActivateStage(stage)
    stage.active = true
    
    -- Start engines
    for _, engine in ipairs(stage.engines) do
        self:StartEngine(engine)
    end
end

-- Deactivate stage components
function RocketStaging:DeactivateStage(stage)
    stage.active = false
    
    -- Stop engines
    for _, engine in ipairs(stage.engines) do
        self:StopEngine(engine)
    end
    
    -- Trigger decouplers
    for _, decoupler in ipairs(stage.decouplers) do
        self:TriggerDecoupler(decoupler)
    end
end

return RocketStaging
