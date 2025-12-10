# Game Clone - 2D Overhead Runner

A Godot 4 2D overhead runner game where players manage physical unit swarms through strategic positioning, shooting, and resource collection.

## Project Overview

**Genre:** 2D Overhead Auto-Runner with Physical Unit Swarms
**Engine:** Godot 4.5+
**Target Platform:** PC (prototype), eventual mobile export
**Assets:** Pixellab 2D sprite pack
**Budget:** $0 (learning project)

## Core Mechanics

### Player Movement
- **Vertical:** Stationary at Y=500 (bottom of screen)
- **Horizontal:** Follow mouse position at 80 px/s (matches scroll speed)
- Playable width: 600 pixels (-300 to +300 from center)

### Unit System (Physical Swarm)
- Player units: 32×32 pixel sprites (blue tinted)
- 15 starting units in circular formation (60px radius)
- Maximum 200 units (memory management cap)
- Enemy units: 32×32 pixel sprites (red tinted)
- Collisions destroy individual physical units
- Unit count visible as floating numbers above groups

### Object Movement
- **Enemies:** Chase player (never despawn)
- **Collectibles:** Barrels and gates scroll down (can be missed)

### Combat System
- **Enemy Collision:** Units destroyed from both sides
- **Projectile System:** Auto-fire every 0.5s, one per player unit
- Projectiles (8×8) destroy individual enemy units
- Wave-based firing when unit count exceeds formation width

### Collectibles

**Barrels (Shoot-to-Open) - 64×64 pixels**
- Require 1-3 bullets to open (based on value)
- Show bullets_remaining counter (yellow text)
- Unopened: Damage player on collision
- Opened: Reward player with units

**Gates (Accumulation) - 64×64 pixels**
- Start at positive, zero, or negative value
- Shoot to increase value (+5 per hit)
- Walk through to collect current value
- Color coded: Green (positive), Red (negative), White (neutral)

### Scrolling Background
- Ground tiles (128×128 scaled to 32×32) in playable path
- Grass tiles (16×16 scaled to 32×32) on outer edges
- Tree borders (16×16 scaled to 32×32) at playable boundaries
- All scroll at 80 px/s

## Current Status

**Implemented Features:**
- ✓ Mouse-controlled horizontal movement (80 px/s)
- ✓ Physical unit swarm system (60px formation radius)
- ✓ Enemy chase behavior (40px formation radius)
- ✓ Auto-fire projectile system with wave-based firing
- ✓ Barrel multi-shot mechanics (shoot-to-open)
- ✓ Gate accumulation system (starting values ± projectile hits)
- ✓ Scrolling background with ground/grass/tree tiles
- ✓ Floating group size indicators
- ✓ Player unit cap (200 max)
- ✓ Game over and restart functionality

**Next Steps (Week 3):**
- Multiplier zones
- Speed scaling (difficulty progression)
- Unobtainable gates (traps)
- Particle effects
- Sound effects

## Technology Stack

**Engine:** Godot 4.5+
- Language: GDScript (fully typed)
- Renderer: Forward Mobile (2D optimized)

**Assets:** Pixellab sprite pack
- player.png (32×32)
- enemy.png (32×32)
- barrel.png (64×64)
- gate.png (64×64)
- projectile.png (16×16, displayed at 8×8)
- ground.png (128×128, displayed at 32×32)
- grass.png (16×16, displayed at 32×32)
- tree.png (16×16, displayed at 32×32)

## Project Structure

```
game_clone/
├── scenes/
│   ├── game_2d.tscn           # Main game scene
│   ├── player_manager.tscn    # Player swarm manager
│   ├── units/
│   │   ├── player_unit.tscn   # Individual player sprite
│   │   └── enemy_unit.tscn    # Individual enemy sprite
│   ├── enemies/
│   │   └── enemy_group.tscn   # Enemy cluster
│   └── collectibles/
│       ├── barrel.tscn         # Shoot-to-open collectible
│       └── gate.tscn           # Accumulation gate
├── scripts/
│   ├── player_manager_2d.gd   # Swarm manager + movement + auto-fire
│   ├── player_unit.gd         # Individual unit sprite
│   ├── enemy_group_2d.gd      # Enemy chase + cluster
│   ├── enemy_unit.gd          # Individual enemy sprite
│   ├── barrel_2d.gd           # Multi-shot barrel logic
│   ├── gate.gd                # Gate accumulation
│   ├── projectile.gd          # Projectile movement and collision
│   ├── scrolling_background.gd # Infinite scrolling tiles
│   ├── game_manager_2d.gd     # Main game controller
│   └── hud.gd                 # UI overlay
└── assets/
    └── pixellab/              # All game sprites

```

## Getting Started

### Prerequisites
- Godot 4.5+ installed
- Git installed and configured

### Setup
```bash
# Clone repository
git clone https://github.com/rdpharr/3d-runner-game.git
cd 3d-runner-game/game_clone

# Open in Godot
# File > Open Project > Select game_clone folder
```

### Testing
- **F5** - Run full game
- **F6** - Run current scene only
- Check Output panel for errors

## Key Implementation Details

### Formation System
```gdscript
# Player formation (scripts/player_manager_2d.gd)
const FORMATION_RADIUS := 60.0  # Doubled for 32×32 units

# Enemy formation (scripts/enemy_group_2d.gd)
const FORMATION_RADIUS := 40.0  # Doubled for 32×32 units
```

### Movement System
```gdscript
# Player movement (scripts/player_manager_2d.gd)
const HORIZONTAL_SPEED := 80.0  # Matches scroll speed

func _physics_process(delta: float) -> void:
    position.x = move_toward(position.x, target_x, HORIZONTAL_SPEED * delta)
```

### Background Tiling
```gdscript
# scripts/scrolling_background.gd
const TILE_SIZE := 32.0
const SCROLL_SPEED := 80.0

# Ground in playable area (128×128 → 32×32)
tile.scale = Vector2(0.25, 0.25)

# Grass/trees on edges (16×16 → 32×32)
tile.scale = Vector2(2.0, 2.0)
```

### Collision Layers
| Layer | Objects |
|-------|---------|
| 1 | Player (CharacterBody2D) |
| 2 | Enemies (Area2D) |
| 3 | Collectibles (Area2D) |
| 8 | Projectiles (Area2D) |

## Performance Targets

**Current (PC Prototype):**
- 60 FPS on development PC
- No optimization needed yet

**Future (Mobile):**
- 30 FPS minimum on mid-range Android
- Low memory footprint
- Fast load times

## Known Limitations

- No save system
- No sound effects
- Single level only
- PC-only testing (mouse control)

## Development Workflow

```bash
# Test changes
# F5 in Godot

# Commit working state
git add .
git commit -m "Description of changes"
git push
```

## License

**Code:** MIT License (TBD)
**Assets:** Pixellab sprite pack

This is a learning project, not for commercial release.

## Contact

**Developer:** Roger
**Project Start:** December 2024
**Repository:** https://github.com/rdpharr/3d-runner-game
