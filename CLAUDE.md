# Claude Code Best Practices - 3D Runner Game

## Project Context
This is a 3D mobile runner/auto-battle game clone built in Godot 4. The developer (Roger) is an experienced Python coder learning game development through building rather than tutorials. All assets are free from Kenney.nl.

## Development Philosophy
- **Build-first approach**: Generate complete, working code rather than snippets
- **Test frequently**: Every session ends with F5 testing and a git commit
- **Automate repetition**: Use spawner scripts instead of manual UI placement
- **Copy-paste efficiency**: Provide complete file contents, not TODOs
- **Zero budget**: Free assets only, no paid tools or libraries

## Code Generation Standards

### When Generating Scripts
1. **Always provide complete files** - No snippets, no "// rest of code here"
2. **Include all necessary code** - Imports, ready functions, complete logic
3. **Use typed GDScript** - Leverage static typing for better IDE support
4. **Add brief comments** - Explain non-obvious logic only
5. **Export important variables** - Make them tweakable in Godot Inspector
6. **Use constants for magic numbers** - No hardcoded values in logic

### Script Template Pattern
```gdscript
extends [NodeType]
class_name [ClassName]  # If reusable

# Configuration
const CONSTANT_NAME := value
@export var tweakable_value := default_value

# Node references
@onready var child_node := $ChildNode

func _ready() -> void:
    # Initialization
    pass

func _physics_process(delta: float) -> void:
    # Per-frame logic
    pass
```

### Scene File Strategy
When asked to create scenes:
1. **Try to generate .tscn content** if structure is simple
2. **Provide spawner scripts** for runtime instantiation when possible
3. **List minimal manual steps** when UI interaction is unavoidable
4. **Include node hierarchy** in comments for reference

### File Organization
```
game_clone/
├── scenes/           # All .tscn files
│   ├── main.tscn
│   ├── player.tscn
│   ├── enemies/
│   └── collectibles/
├── scripts/          # All .gd files
│   ├── player.gd
│   ├── spawners/
│   └── managers/
├── assets/
│   ├── models/       # .glb files from Kenney
│   ├── audio/        # .wav, .ogg
│   └── textures/     # .png
└── docs/             # Design notes, logs
```

## Common Godot 4 Patterns

### Movement & Physics
- Use `CharacterBody3D` for player (has collision resolution)
- Use `Area3D` for triggers and collectibles (overlap detection)
- Use `StaticBody3D` for environment (ground, walls)
- Always call `move_and_slide()` in `_physics_process`

### Collision Detection
```gdscript
# For Area3D (triggers/collectibles)
func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player"):
        # Handle collision
        pass
```

### Node References
```gdscript
# Prefer @onready for child nodes
@onready var label := $Label3D

# Use get_node() for dynamic references
var player := get_tree().get_first_node_in_group("player")

# Use groups for cross-scene communication
add_to_group("player")
```

### Signal Usage
```gdscript
# Define custom signals for decoupling
signal unit_count_changed(new_count: int)

# Emit when state changes
unit_count = new_value
unit_count_changed.emit(unit_count)

# Connect in other scripts
player.unit_count_changed.connect(_on_player_units_changed)
```

## Project-Specific Patterns

### Mouse/Touch Movement System
- Player follows mouse X position (PC) or touch X (mobile)
- Playable width: 6.0 units (-3.0 to +3.0)
- Smooth lerp for responsive feel
```gdscript
const PLAYABLE_WIDTH := 6.0
const MOVEMENT_SMOOTHING := 0.2

func _process(delta: float) -> void:
    var mouse_pos := get_viewport().get_mouse_position()
    var viewport_size := get_viewport().get_visible_rect().size
    
    # Map mouse X (0 to screen width) to game X (-3 to +3)
    var normalized_x := (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
    var target_x := normalized_x * (PLAYABLE_WIDTH / 2.0)
    target_x = clamp(target_x, -PLAYABLE_WIDTH/2, PLAYABLE_WIDTH/2)
    
    # Smooth movement
    position.x = lerp(position.x, target_x, MOVEMENT_SMOOTHING)
```

### Object Movement System
Objects are either moving (toward player) or static (attached to ground):

**Moving Objects (Enemies, Barrels):**
```gdscript
const OBJECT_SPEED := 3.0  # Toward player

func _physics_process(delta: float) -> void:
    position.z -= OBJECT_SPEED * delta  # Negative = toward player
    
    # Destroy if passed player
    if position.z < player_z - 5.0:
        queue_free()
```

**Static Objects (Gates, Multipliers):**
```gdscript
# No movement - player advances toward them
# Destroy after player passes through
func _on_player_entered(player: Player) -> void:
    apply_effect(player)
    queue_free()
```

### Unit Count System
- Player has `var unit_count: int`
- Enemies have `var unit_count: int`
- Collision: reduce both by minimum of the two
- Unopened barrels subtract their value
- Negative gates subtract value
```gdscript
func handle_enemy_collision(enemy: Enemy) -> void:
    var damage := mini(unit_count, enemy.unit_count)
    unit_count -= damage
    enemy.unit_count -= damage
    if enemy.unit_count <= 0:
        enemy.queue_free()

func handle_unopened_barrel(barrel: Barrel) -> void:
    unit_count -= barrel.value  # Penalty!
    barrel.queue_free()
```

### Barrel Two-State System
Barrels have opened/unopened states:
```gdscript
class_name Barrel extends Area3D

@export var value := 15
var is_open := false

func on_projectile_hit() -> void:
    if not is_open:
        is_open = true
        update_visual()  # Change from "?" to "+15"

func on_player_collision(player: Player) -> void:
    if is_open:
        player.unit_count += value  # Reward
    else:
        player.unit_count -= value  # Penalty!
    queue_free()
```

### Gate Accumulation System
Gates can start positive, zero, or negative:
```gdscript
class_name Gate extends Area3D

@export var starting_value := 0  # Can be negative
var current_value := starting_value
const VALUE_PER_HIT := 5

func on_projectile_hit() -> void:
    current_value += VALUE_PER_HIT
    update_display()

func on_player_entered(player: Player) -> void:
    player.unit_count += current_value  # Can subtract if negative
    queue_free()
```

### Spawning Pattern
Create manager scripts for procedural placement:
```gdscript
# spawner.gd
extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_data: Array[Dictionary] = []

func _ready() -> void:
    for data in spawn_data:
        spawn_object(data)

func spawn_object(data: Dictionary) -> void:
    var instance := enemy_scene.instantiate()
    instance.position = data.position
    instance.unit_count = data.unit_count
    add_child(instance)
```

## Testing & Debugging

### Test After Every Change
- Press **F5** to run full game
- Press **F6** to run current scene only
- Use `print()` liberally for debugging
- Check Output panel (bottom) for errors

### Common Issues & Solutions

**Player falls through ground:**
```gdscript
# Add StaticBody3D with CollisionShape3D to ground
# Ensure player's CollisionShape3D is properly sized
```

**Collision not detecting:**
```gdscript
# Checklist:
# 1. Both nodes have CollisionShape3D?
# 2. Shapes are sized correctly? (not 0)
# 3. Layers/masks are compatible?
# 4. Signal is connected?
# 5. Player in correct group?
```

**UI not updating:**
```gdscript
# Use _process() not _physics_process() for UI updates
# Verify node path: get_node("path/to/label")
# Check Label is visible (modulate, position)
```

**Mouse movement not working:**
```gdscript
# Check viewport size calculation
# Verify normalization math (-1 to +1)
# Ensure clamping to playable bounds
# Test with print(target_x) to see values
```

## Git Workflow

### Commit After Every Session
```bash
# Test first
# In Godot: F5 to run, verify functionality

# Stage changes
git add .

# Commit with descriptive message
git commit -m "Session X: Feature description

- Specific change 1
- Specific change 2
- Tests passing: [what you verified]"

# Push to remote
git push origin main
```

### Commit Message Format
```
Session X: [Feature/Fix] - Brief description

- Bullet point of what changed
- Another change
- Tests: [what was verified]

Time: [duration]
```

### What to Commit
- ✅ All .gd scripts
- ✅ All .tscn scenes
- ✅ project.godot file
- ✅ Documentation updates
- ❌ .godot/ folder (in .gitignore)
- ❌ .import/ files (regenerated by Godot)
- ❌ Temporary files

## Code Review Checklist

Before committing, verify:
- [ ] Code has no hardcoded magic numbers (use const)
- [ ] Exported variables for Inspector tweaking
- [ ] Signals used for cross-scene communication
- [ ] Groups used for finding nodes
- [ ] No deep `get_parent().get_parent()` chains
- [ ] Error handling for node references
- [ ] Brief comments for complex logic
- [ ] Consistent naming (snake_case for variables/functions)
- [ ] Type hints where possible

## Performance Considerations

### For Mobile-Style Game
- Keep draw calls low (use atlases if possible)
- Limit particle count (mobile targets ~30fps)
- Pool frequently spawned objects (enemies, projectiles, barrels)
- Disable physics for off-screen objects
- Destroy objects that pass player

### Object Pooling Pattern
```gdscript
# For bullets, effects, enemies, barrels
var pool: Array[Node3D] = []
const POOL_SIZE := 20

func _ready() -> void:
    for i in POOL_SIZE:
        var obj := scene.instantiate()
        obj.visible = false
        pool.append(obj)
        add_child(obj)

func get_from_pool() -> Node3D:
    for obj in pool:
        if not obj.visible:
            obj.visible = true
            return obj
    return null  # Pool exhausted
```

## Asset Management

### Kenney Assets
- All models are `.glb` format (Godot auto-imports)
- Textures are embedded in models
- Audio is `.ogg` or `.wav`
- License: CC0 (public domain) - no attribution required

### Import Settings
Default settings are fine for prototyping. Optimize later if needed.

### Material Overrides
```gdscript
# Change color of a model at runtime
var mesh_instance := $MeshInstance3D
var material := StandardMaterial3D.new()
material.albedo_color = Color.RED
mesh_instance.set_surface_override_material(0, material)
```

## When to Ask Clarifying Questions

### Always Clarify
- Ambiguous feature requirements
- Missing context about existing code
- Integration points with other systems
- Performance targets or constraints

### Provide Without Asking
- Complete, compilable code
- Standard Godot patterns
- Best practices from this document
- Multiple implementation options (when appropriate)

## Response Format Preferences

### For Scripts
```
Here's the complete player.gd:

[full file content]

**To use:**
1. Create script: scripts/player.gd
2. Copy entire content above
3. Attach to Player node in player.tscn

**Test:** F5, player should [expected behavior]
```

### For Scenes
```
Create player.tscn with this structure:

CharacterBody3D (Player)
├── MeshInstance3D (Visual)
├── CollisionShape3D (Collision)
└── Label3D (UnitDisplay)

**Manual steps:**
1. Scene > New Scene > 3D Scene
2. Change root type to CharacterBody3D
3. [minimal additional steps]

**Or** use this spawner script to create at runtime: [script]
```

### For Debugging
```
The issue is [root cause].

**Problem:** [explain what's wrong]
**Solution:** [explain fix]
**Updated code:** [complete corrected section]

**Why this works:** [brief explanation]
```

## Week-by-Week Progression

### Week 1: Movement & Collision
- Mouse/touch horizontal movement
- Forward auto-advance
- Enemy collision (moving objects)
- Simple barrel collection
- UI with unit counter

### Week 2: Shooting & Core Loop
- Auto-shooting projectiles
- Barrel shoot-to-open mechanic
- Unopened barrel damage
- Gate system (shoot to charge)
- Negative gates

### Week 3: Difficulty & Polish
- Multiplier zones
- Speed scaling (difficulty)
- Unobtainable gates (traps)
- Particle effects
- Sound effects

### Week 4+: Advanced Features
- Multiple levels
- Upgrade system
- Mobile touch controls
- Menu system
- Save/progress

## Final Notes

- **Prioritize working code over perfect code** - Refactor later
- **Test immediately after changes** - Don't accumulate untested changes
- **Commit working states** - Every session should end with passing tests
- **Document as you go** - Update DESIGN.md with major decisions
- **Ask for complete solutions** - Not TODO comments or partial code
- **Favor simplicity** - Add complexity only when needed

This document evolves with the project. Update it when patterns change or new best practices emerge.

---

**Last Updated:** 2024-12-07 (Design revision)  
**Project Phase:** Week 1 - Foundation  
**Major Changes:** Removed lane system, added mouse/touch movement, object movement types, barrel two-state system, negative gates
