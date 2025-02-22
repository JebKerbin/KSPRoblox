# Asset Setup Guide for Roblox Space Simulation Game

## 1. Root Directory Structure
```
src/
├── ReplicatedStorage/
│   ├── Assets/
│   ├── StockShips/
│   └── StarterGui/SpaceUI/
```

## 2. ReplicatedStorage/Assets Setup
### 2.1 Planet Assets
- Create folder: `Assets/Planets/`
  - Subfolders for each planet: `Kerbin/`, `Mun/`, `Duna/`
  - Each planet folder needs:
    * Planet 3D mesh in .rbxm format
    * Pre-mapped texture files
    * Atmosphere settings file
    * Surface textures
    * Terrain heightmaps

### 2.2 Space Station Components
- Create folder: `Assets/SpaceStation/`
  - Required subfolders:
    * `Modules/` - For station modules
    * `Docking/` - For docking mechanisms
  - Each module should include:
    * Collision settings
    * Mass properties
    * Connection points

### 2.3 Visual Effects
- Create folder: `Assets/Effects/`
  - Organize into:
    * `Particles/` - Engine effects, reentry heat
    * `Trails/` - Rocket trails, orbit lines
    * `Explosions/` - Various explosion types

## 3. StockShips Setup
### 3.1 Core Components
- Create folder: `StockShips/`
  - Required subfolders:
    * `CommandModules/`
    * `Engines/`
    * `FuelTanks/`
    * `Payload/`
    * `RCS/`

### 3.2 Component Requirements
- Each component must have:
  * Proper CollisionGroups
  * Accurate mass properties
  * Defined PrimaryPart
  * Connection points
  * Physics properties

## 4. UI Assets Setup
### 4.1 Interface Elements
- Create folder: `StarterGui/SpaceUI/Assets/`
  - Organize into:
    * `Icons/` - Mission, status, and alert icons
    * `Textures/` - UI backgrounds and elements
    * `Gauges/` - Instrument displays

### 4.2 Color Scheme
- Follow the established color palette:
  * Primary: rgb(40, 40, 40)
  * Secondary: rgb(60, 60, 60)
  * Accent: rgb(255, 215, 0)

## 5. Implementation Guidelines
### 5.1 Planet Mesh Requirements
1. Use optimized 3D meshes in .rbxm format
2. Ensure UV mapping is properly set up for textures
3. Include proper LOD (Level of Detail) for performance
4. Set appropriate collision bounds
5. Define atmosphere boundary

### 5.2 File Format Standards
- Models: Use .rbxm or .rbxmx format
- Textures: Prefer PNG or SVG formats
- Audio: MP3 format, keep under 1MB

### 5.3 Physics Setup
1. Set appropriate mass values
2. Configure CollisionGroups
3. Define PrimaryPart for each model
4. Set proper Anchored states

### 5.4 Performance Optimization
1. Optimize mesh complexity
2. Use texture atlases where possible
3. Limit particle effect counts
4. Implement LOD (Level of Detail)

## 6. Testing Requirements
1. Test all assets in Studio Edit mode
2. Verify in Runtime mode
3. Check physics interactions
4. Validate network replication
5. Monitor memory usage

## 7. Asset Implementation Examples
### 7.1 Planet Setup
```lua
local planet = Instance.new("Model")
planet.Name = "Kerbin"

-- Set physical properties
local primaryPart = Instance.new("Part")
primaryPart.Size = Vector3.new(1000, 1000, 1000)
primaryPart.Position = Vector3.new(0, 0, 0)
primaryPart.Anchored = true
planet.PrimaryPart = primaryPart

-- Add atmosphere
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.3
atmosphere.Color = Color3.fromRGB(170, 190, 210)
atmosphere.Parent = planet
```

### 7.2 Effect Setup
```lua
local effect = Instance.new("ParticleEmitter")
effect.Rate = 50
effect.Lifetime = NumberRange.new(1, 2)
effect.Speed = NumberRange.new(5, 10)
effect.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
```

Remember to test all assets in both Edit and Play mode to ensure proper functionality and performance.