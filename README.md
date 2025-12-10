# Game Clone - 2D Overhead Runner

A Godot 4 2D overhead runner game where players manage physical unit swarms through strategic positioning, shooting, and resource collection.

## Project Overview

**Genre:** 2D Overhead Auto-Runner with Physical Unit Swarms
**Engine:** Godot 4.5+
**Target Platform:** PC (prototype), eventual mobile export
**Assets:** Free 2D sprites from [Kenney.nl](https://kenney.nl) - Micro Roguelike pack
**Development Time:** 3-5 months (part-time)
**Budget:** $0 (learning project)

## Core Mechanics

### Player Movement
- **Vertical:** Player stationary at Y=500 (bottom of screen)
- **Horizontal:** Follow mouse position (PC) or finger touch (mobile) - moves within viewport
- Playable width: 600 units (-300 to +300 from center)
- Smooth responsive movement

### Unit System (Physical Swarm)
- Player units are 8x8 pixel sprites (blue tinted, tile_0004.png)
- 15 starting units in tight circular formation (30px radius)
- Maximum 200 units (memory management cap)
- Enemy units are 8x8 pixel sprites (red tinted, tile_0010.png)
- Collisions destroy individual physical units
- Unit count visible as floating white/red numbers above groups

### Object Movement
Objects move in two ways:
- **Enemies:** Chase player using direction vectors (never despawn)
- **Collectibles:** Barrels scroll straight down (can be missed if not intercepted)
- **Static:** Gates and multipliers (future feature)

### Combat System
- **Enemy Collision:** Physical units destroyed from both sides (min count)
- Each collision removes actual sprite objects from formations
- Enemy group destroyed when all units gone
- Player defeated when all units destroyed
- **Projectile Damage:** Auto-fire every 0.5s, one projectile per player unit
- Projectiles destroy individual enemy units before collision
- Strategic: thin enemy swarms or focus on collectibles

### Collectibles

**Barrels (Shoot-to-Open)**
- Require 1-3 bullets to open (based on value)
- Show bullets_remaining counter (yellow text)
- **Unopened:** Damage player on collision (penalty = barrel value)
- **Opened:** Reward player on collision (reward = barrel value)
- Visual: Green tint when opened
- Risk/reward: Shoot to open or avoid entirely

**Gates (Accumulation)**
- Very large (96x32 pixels, 3 tiles wide)
- Start at positive, zero, or negative value
- Shoot to increase value (+5 per hit)
- Walk through to collect current value (can be negative!)
- Color coding: Green (positive), Red (negative), White (neutral)
- **Unobtainable gates:** (Future) Start so negative they're impossible to make positive

**Multiplier Zones**
- Floor areas (static on ground)
- Multiply next collection (x2, x3, x5)
- Can multiply negative values (risk!)
- Strategic: choose what to multiply

### Projectile System
- Auto-fire upward every 0.5 seconds
- Wave-based firing: projectiles fire only as wide as player formation
- Multiple waves (0.1s delay) when unit count exceeds formation width
- Maximum projectiles per volley: 5 × (formation width / 8 pixels)
- Small 8x8 pixel yellow sprites
- Hits: enemies (destroy unit), barrels (reduce counter), gates (add +5 value)
- Bullet economy: can't shoot everything
- Strategic prioritization required

### Difficulty Scaling
- **Speed:** Player forward speed + enemy approach speed
- **Enemy Count:** Number and strength of enemies
- **Resource Availability:** Ratio of positive/negative gates, safe/dangerous barrels
- **Unobtainable Traps:** Gates that can't be made positive (must avoid)

## Current Status

**Phase:** Session 4 - UI/UX Polish & Gameplay Refinements Complete ✓
**Build Status:** All Session 4 features functional

### Completed - Session 4: UI/UX & Gameplay Polish (Current)
- [x] Wave-based projectile firing (fires only as wide as player group)
- [x] Multiple projectile waves with 0.1s stagger
- [x] Player unit cap (200 max for memory management)
- [x] Scrolling background tiles (floor tile_0068, walls tile_0050/0051)
- [x] Floating group size indicators (white for player, red for enemies)
- [x] HUD simplified (only shows Game Over and Restart button)
- [x] Restart button (appears on game over)
- [x] Improved visual feedback and sense of movement

### Completed - Week 2 Projectile Combat
- [x] Auto-fire projectile system (0.5s intervals, one per unit)
- [x] Projectile collision detection (enemies, barrels, gates)
- [x] Barrel multi-shot mechanics (bullets_required counter)
- [x] Shoot-to-open barrels (unopened = penalty, opened = reward)
- [x] Gate accumulation system (starting_value ± projectile hits)
- [x] Negative gates (can subtract units)
- [x] Visual feedback (bullet counters, color tinting, value labels)
- [x] Enemy projectile damage (thin swarms before collision)
- [x] Size hierarchy (projectiles < units < barrels < gates)

### Completed - 3D to 2D Conversion
- [x] Converted from 3D to 2D overhead perspective
- [x] Physical unit system (player swarm of 8x8 sprites)
- [x] PlayerManager with circular formation spawning
- [x] Enemy groups with chase behavior
- [x] Physical collision destroys individual sprites
- [x] Barrel collectibles with scroll behavior
- [x] 2D Camera (stationary, player moves within viewport)
- [x] Asset integration (Micro Roguelike 8x8 sprites)
- [x] HUD showing unit count from array size
- [x] Game over when all units destroyed

### Completed - Week 1 (3D Foundation)
- [x] Initial repository setup
- [x] Git configuration and GitHub repository created
- [x] Documentation structure (CLAUDE.md, DESIGN.md, README.md)
- [x] Development workflow established
- [x] 3D prototype with HUD-based unit counter
- [x] Basic collision and movement systems

## Technology Stack

**Engine:** Godot 4.5+
- Chosen for: free license, excellent 2D support, fast iteration
- Language: GDScript (fully typed)
- Renderer: Forward Mobile (2D optimized)

**Assets:** Kenney.nl
- Micro Roguelike Pack (320 8x8 pixel sprites, perfect for swarms)
- Top-down Shooter Pack (backup sprites)
- License: CC0 (public domain)

**Development Tools:**
- Git (version control)
- Claude Code (AI-assisted development)
- Obsidian (project documentation)

## Project Structure

```
game_clone/
├── scenes/              # Godot scene files (.tscn)
│   ├── game_2d.tscn    # Main 2D game scene
│   ├── player_manager.tscn  # Player (CharacterBody2D with swarm)
│   ├── units/
│   │   ├── player_unit.tscn  # Individual player sprite (8x8, blue)
│   │   └── enemy_unit.tscn   # Individual enemy sprite (8x8, red)
│   ├── enemies/
│   │   └── enemy_group.tscn  # Enemy cluster (Node2D + Area2D)
│   └── collectibles/
│       └── barrel.tscn       # Barrel (Area2D + sprite)
├── scripts/            # GDScript files (.gd)
│   ├── player_manager_2d.gd  # Physical swarm manager + wave-based auto-fire
│   ├── player_unit.gd        # Individual unit sprite
│   ├── enemy_group_2d.gd     # Enemy chase + cluster + projectile damage
│   ├── enemy_unit.gd         # Individual enemy sprite
│   ├── barrel_2d.gd          # Shoot-to-open collectible
│   ├── gate.gd               # Gate accumulation system
│   ├── projectile.gd         # Projectile movement and collision
│   ├── scrolling_background.gd  # Infinite scrolling tile system
│   ├── game_manager_2d.gd    # Main game controller
│   └── hud.gd                # UI overlay (Game Over + Restart)
├── assets/
│   ├── kenney_micro-roguelike/  # 8x8 pixel sprites
│   │   └── Tiles/Colored/
│   │       ├── tile_0004.png    # Player sprite (8x8)
│   │       ├── tile_0010.png    # Enemy sprite (8x8)
│   │       ├── tile_0007.png    # Projectile sprite (8x8)
│   │       ├── tile_0100.png    # Barrel sprite (8x8)
│   │       ├── tile_0060.png    # Gate left tile (8x8)
│   │       ├── tile_0061.png    # Gate center tile (8x8)
│   │       ├── tile_0059.png    # Gate right tile (8x8)
│   │       ├── tile_0068.png    # Floor tile (8x8)
│   │       ├── tile_0050.png    # Left wall tile (8x8)
│   │       ├── tile_0051.png    # Right wall tile (8x8)
│   │       └── [314 more sprites...]
│   └── kenney_top-down-shooter/ # Backup sprites
├── docs/                 # Development documentation
│   └── Week_1_Plan.md    # Original 3D plan (archived)
├── CLAUDE.md             # AI assistant guidelines
├── DESIGN.md             # Game design documentation
└── README.md             # This file
```

## Getting Started

### Prerequisites
1. Godot 4.3+ installed
2. Git installed and configured

### Setup
```bash
# Clone repository
git clone https://github.com/rdpharr/3d-runner-game.git
cd 3d-runner-game

# Open in Godot
# File > Open Project > Select game_clone folder
# Assets are already imported and ready to use
```

### Development Workflow

**Each Session:**
1. Pull latest changes: `git pull`
2. Open Godot project
3. Build/modify features
4. Test frequently (F5 in Godot)
5. Commit working state
6. Push changes: `git push`

**Commit Format:**
```
Session X: [Feature] - Brief description

- Specific change 1
- Specific change 2
- Tests: [what works]

Time: [duration]
```

## Design Decisions

See [DESIGN.md](DESIGN.md) for detailed design documentation.

**Key Choices:**
- **Mouse/touch control:** Direct, mobile-friendly horizontal movement
- **Moving objects:** Enemies and barrels advance toward player (urgency)
- **Shoot-to-open barrels:** Unopened barrels damage player (tension)
- **Negative gates:** Can subtract units, must avoid or heavily shoot
- **Build-first approach:** Learning through doing, not tutorials
- **Free assets only:** Zero-budget constraint for learning
- **Godot 4:** Free, good Claude Code integration, mobile export capability

## Learning Goals

### Technical Skills
- [ ] Godot 4 engine fundamentals
- [ ] 3D game development
- [ ] GDScript programming
- [ ] Mouse/touch input handling
- [ ] Game physics and collision
- [ ] UI/UX implementation
- [ ] Audio integration
- [ ] Mobile optimization

### Game Development
- [ ] Game design iteration
- [ ] Level design principles
- [ ] Balance and difficulty curves
- [ ] Player feedback systems
- [ ] Polish and juice
- [ ] Risk/reward mechanics

### Project Management
- [ ] Structured development workflow
- [ ] Version control best practices
- [ ] Documentation habits
- [ ] Scope management
- [ ] Time estimation

## Testing

**Manual Testing:**
- F5 in Godot runs full game
- F6 runs current scene only
- Check Output panel for errors/warnings

**Test Checklist (Session 4 - UI/UX Polish):**
- [x] Player moves horizontally within viewport (not camera-centered)
- [x] 15 player units spawn in circular formation
- [x] Player units cap at 200 max
- [x] Enemies chase player continuously
- [x] Barrels scroll straight down
- [x] Physical collision destroys individual sprites
- [x] Floating labels show player count (white) above player group
- [x] Floating labels show enemy count (red) above enemy groups
- [x] HUD hidden until game over
- [x] Game over at 0 units
- [x] Restart button appears on game over
- [x] Restart button reloads scene correctly
- [x] Background tiles scroll smoothly at 80 px/sec
- [x] Floor tiles (tile_0068) render behind gameplay
- [x] Wall tiles (tile_0050/0051) visible at edges
- [x] Projectiles fire in waves (0.1s stagger)
- [x] Projectile width matches player formation width
- [x] Wave-based firing works with high unit counts
- [x] Projectiles hit enemies and destroy units
- [x] Barrels show bullets_required counter
- [x] Shooting barrels reduces counter
- [x] Unopened barrels damage player
- [x] Opened barrels reward player
- [x] Gates show current value with color coding
- [x] Shooting gates increases value (+5)
- [x] Positive/negative gates work correctly

## Performance Targets

**Prototype Phase:**
- 60 FPS on development PC
- No optimization needed yet

**Mobile Phase (Future):**
- 30 FPS minimum on mid-range Android
- Low memory footprint
- Fast load times
- Touch controls responsive

## Known Limitations

### Current
- No save system
- No sound effects
- Single level only
- PC-only testing (mouse control)
- Placeholder graphics

### Planned Future
- Mobile touch controls
- Multiplier zones (Week 3)
- Unobtainable gates (Week 3)
- Particle effects (Week 3)
- Sound effects (Week 3)
- Multiple levels
- Upgrade system
- Settings menu
- Background music

## Resources

**Godot Documentation:**
- https://docs.godotengine.org/
- Focus on: Node3D, CharacterBody3D, Area3D, Input handling

**Kenney Assets:**
- https://kenney.nl/assets/tower-defense-kit
- License: CC0 (use freely)

**Community:**
- r/godot (Reddit)
- Godot Discord
- GDQuest tutorials (reference)

## License

**Code:** MIT License (TBD)  
**Assets:** CC0 (Kenney.nl)

This is a learning project, not for commercial release.

## Contact

**Developer:** Roger
**Project Start:** December 2024
**Repository:** https://github.com/rdpharr/3d-runner-game

## Changelog

### 2024-12-09 - Session 4: UI/UX Polish & Gameplay Refinements Complete
- **Wave-Based Projectile Firing:** Projectiles fire only as wide as player formation
- **Projectile Waves:** Multiple waves with 0.1s delay when unit count exceeds formation width
- **Player Unit Cap:** Maximum 200 units for memory management
- **Scrolling Background:** Floor tiles (tile_0068) and wall tiles (tile_0050/0051) scroll at 80 px/sec
- **Floating Group Indicators:** White numbers above player, red numbers above enemies
- **HUD Simplification:** Removed always-visible unit counter, only shows Game Over
- **Restart Button:** Appears on game over, reloads scene
- **Visual Polish:** Improved sense of movement and better feedback
- **Type Safety:** Fixed GDScript type annotations for Godot 4.5+ strict mode
- Session 4 complete: All UI/UX improvements functional

### 2024-12-09 - Session 3: Week 2 Projectile Combat Complete
- **Projectile System:** Auto-fire every 0.5s, one per player unit, spread across formation
- **Barrel Multi-Shot:** bullets_required counter, shoot-to-open, penalty/reward system
- **Gate Accumulation:** starting_value ± projectile hits, color-coded feedback
- **Enemy Damage:** Projectiles destroy individual enemy units
- **Visual Polish:** Bullet counters, color tinting, value labels
- **Size Hierarchy:** Projectiles (8x8) < Units (16x16) < Barrels (32x32) < Gates (96x32)
- **Collision Fix:** Corrected projectile collision_mask from 10 to 6
- Week 2 complete: All combat features functional

### 2024-12-08 - Session 2: Week 1 Complete
- Fixed camera orientation (player at bottom, enemies at top)
- Corrected movement system (player stationary, objects move negative to positive Z)
- Fixed HUD initialization and signal connection
- Scaled all objects to 20% with matching collision shapes (radius 1.5 → effective 0.3)
- Collision detection working accurately
- Week 1 complete: All core mechanics functional

### 2024-12-07 - Session 1
- GitHub repository created and configured
- Imported Kenney assets (Tower Defense Kit + Starter Kit 3D Platformer)
- Created player system (player.tscn, player_runner.gd)
- Created enemy system (enemy_basic.tscn, enemy.gd)
- Created collectible system (barrel_simple.tscn, barrel_simple.gd)
- Created spawner system (week1_spawner.gd, week1_test.tscn)
- Week 1 foundation established

### 2024-12-07 (v2.0)
- Major design revision based on developer feedback
- Removed lane system, added mouse/touch movement
- Added moving objects (enemies/barrels toward player)
- Added shoot-to-open barrel mechanic
- Added negative gates and unobtainable traps
- Updated all documentation to reflect new design

### 2024-12-07 (v1.0)
- Initial repository setup
- Documentation structure created
- Development workflow established

---

**Next Session:** Week 3 - Multiplier zones, difficulty scaling, particle effects, sound, mobile touch controls
