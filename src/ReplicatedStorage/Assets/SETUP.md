# Asset Setup Guide for Space Simulation Game

## Folder Structure
```
src/ReplicatedStorage/
├── Assets/
│   ├── Planets/
│   │   ├── Kerbin/
│   │   │   ├── kerbin.rbxm         # Planet 3D mesh
│   │   │   ├── surface_albedo.png  # Surface color texture
│   │   │   ├── normal_map.png      # Surface detail normal map
│   │   │   └── atmosphere.png      # Atmosphere effect texture
│   │   ├── Mun/
│   │   │   ├── mun.rbxm
│   │   │   ├── surface_albedo.png
│   │   │   └── crater_map.png
│   │   └── Duna/
│   │       ├── duna.rbxm
│   │       ├── surface_albedo.png
│   │       └── ice_caps.png
│   ├── SpaceStation/
│   │   ├── Modules/
│   │   └── Docking/
│   ├── Effects/
│   │   ├── Particles/
│   │   ├── Trails/
│   │   └── Explosions/
│   └── UI/
└── StockShips/
```

## Planet Asset Requirements

1. 3D Mesh Requirements (.rbxm):
   - Use optimized mesh geometry (< 10k triangles per planet)
   - Pre-mapped UV coordinates for textures
   - Properly configured collision bounds
   - Set up proper pivot points at planet center

2. Texture Requirements:
   - Base Color/Albedo Maps:
     * Resolution: 2048x2048 or 4096x4096
     * Format: PNG
     * Color space: sRGB
   - Normal Maps:
     * Resolution: Same as albedo
     * Format: PNG
     * Encoding: DirectX-style (red=X+, green=Y+, blue=Z+)
   - Special Maps (ice caps, craters):
     * Resolution: 1024x1024 minimum
     * Format: PNG with alpha channel

3. Planet-Specific Requirements:
   - Kerbin:
     * High-detail surface texture
     * Cloud layer texture with alpha
     * Ocean mask texture
   - Mun:
     * Detailed crater map
     * Surface roughness texture
   - Duna:
     * Ice cap mask texture
     * Dust storm particle textures


## Implementation Guide

1. Adding a New Planet:
```lua
-- Example planet implementation
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

2. Loading Assets:
```lua
-- Load planet mesh
local planetMesh = game:GetService("ReplicatedStorage").Assets.Planets.Kerbin["kerbin.rbxm"]
planetMesh.Parent = planet

-- Apply textures
local surfaceTexture = Instance.new("Texture")
surfaceTexture.Texture = "rbxassetid://..." -- Your texture ID
surfaceTexture.Parent = planetMesh
```

## Performance Guidelines

1. Optimization Requirements:
   - Use LOD (Level of Detail) for distant planets
   - Implement texture streaming for large planets
   - Keep polygon count under budget per planet
   - Use texture atlases where possible

2. Memory Management:
   - Preload essential textures
   - Stream in distant planet details
   - Properly dispose of unused assets

## Testing Requirements

1. Visual Tests:
   - Check texture alignment
   - Verify atmosphere effects
   - Test LOD transitions
   - Validate UV mapping

2. Performance Tests:
   - Monitor frame rate with multiple planets
   - Check memory usage
   - Verify loading times

Remember to test all assets in both Edit and Play mode to ensure proper functionality and performance.