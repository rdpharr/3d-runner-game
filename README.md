# Game Clone - 3D Mobile Runner

A Godot 4 3D runner game where players manage unit count through strategic positioning, shooting, and resource collection.

## Project Overview

**Genre:** 3D Auto-Runner with Shooting & Resource Management  
**Engine:** Godot 4.3+  
**Target Platform:** PC (prototype), eventual mobile export  
**Assets:** Free assets from [Kenney.nl](https://kenney.nl)  
**Development Time:** 3-5 months (part-time)  
**Budget:** $0 (learning project)

## Core Mechanics

### Player Movement
- **Forward:** Auto-advance at constant speed (Z-axis)
- **Horizontal:** Follow mouse position (PC) or finger touch (mobile)
- Playable width: 3 objects wide (~6 units, -3 to +3)
- Smooth responsive movement

### Object Movement
Objects move in two ways:
- **Moving:** Enemies and barrels advance toward player
- **Static:** Gates and multipliers attached to ground

### Combat System
- **Enemy Collision:** Both player and enemy lose min(player_units, enemy_units)
- **Projectile Damage:** Auto-fire reduces enemy unit count
- Enemy destroyed when units reach 0
- Player defeated when units reach 0

### Collectibles

**Barrels (Two-State)**
- **Unopened:** Show "?", damage player on contact (-value)
- **Opened:** Shoot to open, then collect for +value
- Moving toward player (creates urgency)
- Must prioritize which to shoot open

**Gates (Accumulation)**
- Static position on ground
- Start at positive, zero, or negative value
- Shoot to increase value (+5 per hit)
- Walk through to collect current value (can be negative!)
- **Unobtainable gates:** Start so negative they're impossible to make positive

**Multiplier Zones**
- Floor areas (static on ground)
- Multiply next collection (x2, x3, x5)
- Can multiply negative values (risk!)
- Strategic: choose what to multiply

### Projectile System
- Auto-fire forward at regular intervals
- Hits: enemies (damage), barrels (open), gates (charge)
- Bullet economy: can't shoot everything
- Prioritization required

### Difficulty Scaling
- **Speed:** Player forward speed + enemy approach speed
- **Enemy Count:** Number and strength of enemies
- **Resource Availability:** Ratio of positive/negative gates, safe/dangerous barrels
- **Unobtainable Traps:** Gates that can't be made positive (must avoid)

## Current Status

**Phase:** Week 1 - Foundation Setup (In Progress)
**Build Status:** Core systems implemented, integration pending

### Completed
- [x] Initial repository setup
- [x] Git configuration and GitHub repository created
- [x] Documentation structure (CLAUDE.md, DESIGN.md, README.md)
- [x] Development workflow established
- [x] Asset import (Kenney Tower Defense Kit + Starter Kit 3D Platformer)
- [x] Player system (auto-forward + mouse following movement)
- [x] Enemy system (UFO models, collision, unit count)
- [x] Collectible system (crystals, simple collection)

### Week 1 Goals (60% Complete)
- [x] Player movement (auto-forward + mouse following)
- [x] Enemy collision (moving toward player)
- [x] Simple barrel collection (no shoot-to-open yet)
- [ ] Basic 3D scene (ground, camera, lighting)
- [ ] UI (unit counter)
- [ ] First playable level

## Technology Stack

**Engine:** Godot 4.3+
- Chosen for: free license, good 3D support, fast iteration
- Language: GDScript (typed where possible)
- Renderer: Forward+ (for 3D with good performance)

**Assets:** Kenney.nl
- Tower Defense Kit (UFO enemies, crystals, tiles - 160 models)
- Starter Kit 3D Platformer (animated character, coins, environment)
- License: CC0 (public domain)

**Development Tools:**
- Git (version control)
- Claude Code (AI-assisted development)
- Obsidian (project documentation)

## Project Structure

```
game_clone/
├── scenes/              # Godot scene files (.tscn)
│   ├── main.tscn       # Main game scene (from Starter Kit)
│   ├── player.tscn     # Player character (CharacterBody3D + character.glb)
│   ├── enemies/
│   │   └── enemy_basic.tscn  # UFO enemy (Area3D + enemy-ufo-a.glb)
│   └── collectibles/
│       └── barrel_simple.tscn  # Crystal collectible (Area3D + detail-crystal.glb)
├── scripts/            # GDScript files (.gd)
│   ├── player_runner.gd  # Runner-specific player controller
│   ├── enemy.gd          # Enemy behavior
│   ├── barrel_simple.gd  # Collectible behavior
│   ├── spawners/         # Level/object spawners (pending)
│   └── managers/         # Game systems (pending)
├── assets/
│   ├── models/           # .glb 3D models (320 files total)
│   │   ├── character.glb # Animated player character
│   │   ├── enemy-ufo-*.glb  # UFO enemies (a/b/c/d variants)
│   │   ├── detail-crystal.glb  # Collectible crystal
│   │   ├── tile.glb      # Ground tiles
│   │   └── [158 more models...]
│   ├── audio/            # Audio files (empty)
│   └── textures/         # Textures (colormap.png, variation-a.png)
├── docs/                 # Development documentation
│   └── Week_1_Plan.md    # Week 1 implementation plan
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

**Test Checklist (Week 1):**
- [ ] Player moves forward automatically
- [ ] Player follows mouse horizontally
- [ ] Enemies move toward player
- [ ] Enemy collision reduces unit count
- [ ] Simple barrel collection works
- [ ] UI updates correctly
- [ ] Game over at 0 units
- [ ] No runtime errors

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
- Shooting system (Week 2)
- Barrel shoot-to-open (Week 2)
- Gates and multipliers (Week 2-3)
- Multiple levels
- Upgrade system
- Settings menu
- Sound/music

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

### 2024-12-07 - Session 1 (In Progress)
- GitHub repository created and configured
- Imported Kenney assets (Tower Defense Kit + Starter Kit 3D Platformer)
- Created player system (player.tscn, player_runner.gd)
- Created enemy system (enemy_basic.tscn, enemy.gd)
- Created collectible system (barrel_simple.tscn, barrel_simple.gd)
- Week 1 foundation 60% complete

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

**Next Session:** Create UI scene → Create spawner script → Set up main scene → Test and commit Week 1 foundation
