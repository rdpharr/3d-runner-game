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
- 15 starting units in circular formation
- Unlimited unit accumulation (200 rendered cap for performance)
- Units reform into random positions within target radius after deaths
- Backfill system maintains 200 rendered units when total > 200
- Enemy units: 32×32 pixel sprites (red tinted)
- Individual unit collision with proximity activation
- Death particles and fade animations
- Unit count visible as floating numbers above groups

### Object Movement
- **Enemies:** Chase player at 75 px/s (never despawn)
- **Collectibles:** Barrels and gates scroll down (can be missed)
- **Boss:** Advances downward at 60 px/s when spawned at 120 seconds

### Combat System
- **Enemy Collision:** Units destroyed from both sides
- **Projectile System:** Auto-fire every 0.5s, one per player unit
- Projectiles (8×8) destroy individual enemy units
- Wave-based firing when unit count exceeds formation width

### Collectibles

**Barrels (Shoot-to-Open) - 128×128 pixels (2x scale)**
- Require value/2 bullets to open (harder than before)
- Show bullets_remaining counter (yellow text, 32px font)
- **Reward given immediately when shot open** (no collision needed)
- Collision with unopened barrel just destroys it (no reward/penalty)

**Gates (Accumulation) - 96×96 pixels (1.5x scale)**
- Start at positive, zero, or negative value
- Shoot to increase value (+5 per 10 bullets)
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
- ✓ Physical unit swarm system with smart reformation
- ✓ Unlimited unit accumulation (200 rendered cap with backfill)
- ✓ Formation reformation (target radius based, triggered on death)
- ✓ Individual unit collision with proximity activation
- ✓ Death particles and fade animations
- ✓ Enemy chase behavior (75 px/s, 25% slower for balance)
- ✓ Auto-fire projectile system with wave-based firing
- ✓ Barrel instant-reward mechanics (units given when shot open)
- ✓ Gate accumulation system (10 bullets per value change)
- ✓ 2-minute auto-spawning system with difficulty scaling
- ✓ Boss battle at 120 seconds (500 HP, continuous collision damage)
- ✓ Scrolling background with ground/grass/tree tiles
- ✓ Left sidebar UI (Stop/Pause/Restart)
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
- barrel.png (64×64, displayed at 128×128)
- gate.png (64×64, displayed at 96×96)
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
│   │   ├── enemy_group.tscn   # Enemy cluster
│   │   └── boss.tscn          # Boss battle (120s trigger)
│   └── collectibles/
│       ├── barrel.tscn         # Shoot-to-open collectible
│       └── gate.tscn           # Accumulation gate
├── scripts/
│   ├── player_manager_2d.gd   # Swarm manager + movement + auto-fire
│   ├── player_unit.gd         # Individual unit sprite
│   ├── enemy_group_2d.gd      # Enemy chase + cluster
│   ├── enemy_unit.gd          # Individual enemy sprite
│   ├── boss.gd                # Boss battle logic (500 HP, continuous damage)
│   ├── barrel_2d.gd           # Multi-shot barrel logic
│   ├── gate.gd                # Gate accumulation
│   ├── projectile.gd          # Projectile movement and collision
│   ├── scrolling_background.gd # Infinite scrolling tiles
│   ├── game_manager_2d.gd     # Main game controller
│   ├── spawn_manager.gd       # Wave spawning + boss trigger
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
const SMALL_GROUP_RADIUS := 50.0   # 1-50 units
const MEDIUM_GROUP_RADIUS := 65.0  # 51-120 units
const LARGE_GROUP_RADIUS := 55.0   # 121+ units
const REFORM_SPEED := 0.25         # Reformation lerp speed

# Enemy formation (scripts/enemy_group_2d.gd)
const FORMATION_RADIUS := 40.0
const CHASE_SPEED := 75.0  # Reduced 25% for balance
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
| 2 | Enemies (Area2D), Boss Projectile Hitbox |
| 3 | Collectibles (Area2D) |
| 8 | Projectiles (Area2D) |
| 16 | Boss Collision Area |

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
