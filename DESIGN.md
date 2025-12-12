# Game Design Document - 2D Overhead Runner

## Vision Statement

A 2D overhead auto-running game where players manage unit count through strategic horizontal movement, combat, and resource collection. Players must decide which objects to shoot, collect, or avoid in an oncoming stream of enemies and collectibles.

## Core Gameplay Loop

```
Player advances → Dodge enemies (-units) → Shoot/collect barrels (+units) →
Shoot gates to charge (±units) → Pass multipliers (boost) → Repeat
```

**Session Duration:** 30-60 seconds per run
**Difficulty Curve:** Speed increases, enemy density, strategic resource placement
**Skill Expression:** Horizontal positioning, shooting prioritization, risk/reward decisions

---

## Movement System

### Player Movement

**Forward Progression:**
- Player stationary at Y=500 (bottom of screen)
- Objects scroll down toward player (top to bottom)
- Creates visual effect of forward movement
- Speed increases with difficulty

**Horizontal Control:**
- Mouse X position (PC) / Touch X (mobile)
- Movement speed: 80 px/s (matches scroll speed for consistent feel)
- Playable width: 600 pixels (-300 to +300 from center)
- Uses `move_toward()` for fixed-speed movement

**Camera:**
- Overhead 2D view (Camera2D)
- Fixed at viewport center
- Player moves side-to-side within viewport

**Implementation:**
```gdscript
# scripts/player_manager_2d.gd
const PLAYABLE_WIDTH := 600.0
const HORIZONTAL_SPEED := 80.0

func _physics_process(delta: float) -> void:
    velocity.y = 0  # Stationary in Y

    var mouse_pos := get_viewport().get_mouse_position()
    var viewport_size := get_viewport().get_visible_rect().size

    var normalized_x := (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
    var target_x := normalized_x * (PLAYABLE_WIDTH / 2.0)
    target_x = clamp(target_x, -PLAYABLE_WIDTH / 2.0, PLAYABLE_WIDTH / 2.0)

    position.x = move_toward(position.x, target_x, HORIZONTAL_SPEED * delta)
    move_and_slide()
```

### Object Movement

**Enemies (Chase):**
- Spawn above screen, chase player position
- Never despawn - always pursue
- Speed: 75 px/s (reduced 25% for balance)

**Boss (Timer-Triggered):**
- Spawns at 120 seconds (end of level timer)
- Advances straight down at 60 px/s
- 500 HP (requires sustained shooting)
- Continuous collision damage (2 HP/sec boss, 10 units/sec player)

**Collectibles (Scroll):**
- Barrels and gates scroll straight down
- Speed: 120 px/s (barrels), 80 px/s (gates)
- Despawn if missed

---

## Unit System (Physical Swarm)

### Core Mechanic

**Visual Representation:**
- Units are physical Area2D nodes with collision detection
- Each unit = one 32×32 pixel sprite
- Units cluster in circular formation (60px radius)
- Floating count label shows total units (including overflow)

**Unlimited Unit Accumulation:**
```gdscript
# scripts/player_manager_2d.gd
var player_units: Array[Area2D] = []  # Rendered units (capped)
var total_unit_count := 0  # Total units including overflow (unlimited)
const FORMATION_RADIUS := 60.0
const MAX_PLAYER_UNITS := 200  # Memory management cap

func add_units(amount: int) -> void:
    # Always add to total (unlimited)
    total_unit_count += amount

    # Spawn physical units only up to cap
    var units_to_spawn := min(amount, MAX_PLAYER_UNITS - player_units.size())
    for i in units_to_spawn:
        spawn_player_unit()

    update_count_label()  # Shows total, not rendered count
```

**Smart Damage System:**
```gdscript
func remove_player_unit() -> void:
    # Always decrement total
    total_unit_count -= 1

    # Only remove physical unit if total < rendered count
    # (This depletes overflow first, then rendered units)
    if total_unit_count < player_units.size():
        var unit := player_units.pop_back()
        unit.queue_free()
```

**Overflow Replacement System:**
```gdscript
func on_unit_died(unit: PlayerUnit) -> void:
    # Called when unit dies from collision
    total_unit_count -= 1
    player_units.erase(unit)

    # If overflow exists, spawn replacement to maintain visual density
    if total_unit_count > player_units.size() and player_units.size() < MAX_PLAYER_UNITS:
        spawn_player_unit()
```

**Formation Reformation System:**
```gdscript
# scripts/player_manager_2d.gd
const SMALL_GROUP_RADIUS := 50.0   # 1-50 units
const MEDIUM_GROUP_RADIUS := 65.0  # 51-120 units
const LARGE_GROUP_RADIUS := 55.0   # 121+ units
const REFORM_SPEED := 0.25         # Reformation lerp speed

var is_reforming := false
var reform_targets: Dictionary = {}  # Maps unit → Vector2 target position

func trigger_reformation() -> void:
    # Called after unit deaths
    reform_targets.clear()
    is_reforming = true

    # Calculate radius based on group size
    var target_radius := SMALL_GROUP_RADIUS
    if player_units.size() > 120:
        target_radius = LARGE_GROUP_RADIUS
    elif player_units.size() > 50:
        target_radius = MEDIUM_GROUP_RADIUS

    # Assign random position to each unit
    for unit in player_units:
        var angle := randf() * TAU
        var distance := randf() * target_radius
        reform_targets[unit] = Vector2(cos(angle) * distance, sin(angle) * distance)

func update_formation(delta: float) -> void:
    # Lerp units toward targets
    for unit in player_units:
        if unit in reform_targets:
            unit.position = unit.position.lerp(reform_targets[unit], REFORM_SPEED * delta)
```

**Visual Effect:**
- Event-triggered (only on unit death, not continuous)
- Each unit gets unique random position within target radius
- Density-based radius prevents overcrowding
- Creates natural-looking crowds with organic spread

**Gain Units:**
- Opened barrels: +10 to +300 units (difficulty scaled)
- Positive gates: +value units
- No upper limit - accumulation is unlimited

**Lose Units:**
- Enemy collision: 1:1 unit destruction (proximity-based)
- Unopened barrel: -value units (penalty)
- Negative gates: -value units

**Game Over:** Total units reach 0 (total_unit_count <= 0)

### Individual Unit Collision System

**Proximity-Based Activation:**
```gdscript
# scripts/player_manager_2d.gd
const COLLISION_ACTIVATION_DISTANCE := 150.0

func update_unit_collisions() -> void:
    var closest_enemy_dist := INF
    for enemy in get_tree().get_nodes_in_group("enemy"):
        closest_enemy_dist = min(closest_enemy_dist, position.distance_to(enemy.position))

    # Activate unit collisions only when enemies are near
    var should_activate := closest_enemy_dist < COLLISION_ACTIVATION_DISTANCE
    for unit in player_units:
        unit.set_collision_active(should_activate)
```

**Unit Death and Particles:**
```gdscript
# scripts/player_unit.gd (Area2D)
func _on_area_entered(area: Area2D) -> void:
    if area is EnemyUnit and collision_active:
        # Spawn death particles (4 particles)
        spawn_death_particles()

        # Notify manager
        manager.on_unit_died(self)

        # Destroy self
        queue_free()
```

**Collision Properties:**
- Units are Area2D (not Sprite2D)
- Collision only active within 150px of enemies (performance optimization)
- 1:1 mutual destruction when units collide
- Death particles fade over time (4 particles per unit)
- Gradual destruction creates visual feedback

### Enemy Groups

**Properties:**
```gdscript
# scripts/enemy_group_2d.gd
const FORMATION_RADIUS := 40.0
const CHASE_SPEED := 75.0  # Reduced 25% for balance

var enemy_units: Array[Area2D] = []

func spawn_enemy_units(count: int) -> void:
    for i in count:
        var unit := enemy_unit_scene.instantiate()
        var angle := randf() * TAU
        var radius := randf() * FORMATION_RADIUS
        unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)
        enemy_units.append(unit)
        add_child(unit)
```

**Individual Enemy Collision:**
- Each enemy unit is Area2D with collision detection
- Destroys one player unit on collision
- Enemy unit also destroyed (mutual destruction)
- Death particles for both player and enemy units

### Sprite Sizes

| Object | Source Size | Scale | Displayed Size |
|--------|-------------|-------|----------------|
| Player units | 32×32 | 1.0× | 32×32 |
| Enemy units | 32×32 | 1.0× | 32×32 |
| Projectiles | 16×16 | 0.5× | 8×8 |
| Barrels | 64×64 | 2.0× | 128×128 |
| Gates | 64×64 | 1.5× | 96×96 |
| Ground tiles | 128×128 | 0.25× | 32×32 |
| Grass tiles | 16×16 | 2.0× | 32×32 |
| Tree borders | 16×16 | 2.0× | 32×32 |

---

## Collectible Systems

### Barrels (Shoot-to-Open)

**Multi-Shot System:**

1. **Unopened State:**
   - Shows value on top (e.g., "15")
   - Shows bullets remaining as yellow text (e.g., "8")
   - Collision just destroys barrel (no reward/penalty)

2. **Opened State (Shot Open):**
   - Bullets counter reaches 0
   - **Units given immediately** when shot open
   - Barrel despawns after rewarding player
   - No collision interaction needed

**Bullet Requirement Formula (5x Harder):**
```gdscript
# scripts/barrel_2d.gd
const SCROLL_SPEED := 120.0
@export var value := 15
var bullets_required := 1
var bullets_remaining := 1
var is_open := false

func calculate_bullets_needed(barrel_value: int) -> int:
    # 5x harder than original (value/10)
    return max(1, barrel_value / 2)

# Examples:
# value = 10  → 5 bullets  (was 1)
# value = 20  → 10 bullets (was 2)
# value = 50  → 25 bullets (was 5)
# value = 100 → 50 bullets (was 10)
# value = 200 → 100 bullets (was 20)

func on_projectile_hit() -> void:
    if not is_open:
        bullets_remaining -= 1
        if bullets_remaining <= 0:
            is_open = true
            bullets_remaining = 0
            give_reward()  # Immediately reward when shot open
        update_display()

func give_reward() -> void:
    var player := get_tree().get_first_node_in_group("player") as PlayerManager
    if player:
        player.add_units(value)
    queue_free()  # Destroy barrel after giving reward

func _on_body_entered(body: Node2D) -> void:
    if body is PlayerManager:
        # Collision just destroys barrel (no reward/penalty)
        queue_free()
```

**Visual Design:**
- Size: 128×128 pixels (2x scale from 64×64)
- Value label: 20px font above barrel
- Bullet counter: 32px yellow font in front
- Unopened: White sprite, white value, yellow bullet counter
- Opened: Green tint, green "+value", no counter

**Difficulty Scaling:**
- Easy tier (1-30 units): 10, 20, 50 value barrels
- Medium tier (31-80 units): 20, 50, 100 value barrels
- Hard tier (81-150 units): 50, 100, 200 value barrels
- Brutal tier (151+ units): 100, 200, 300 value barrels

### Gates (Accumulation)

**Behavior:**
- Scroll down at 80 px/s (slower than barrels)
- Start at positive, zero, or negative value
- Shoot to increase value (+5 per 10 bullets)
- Walk through to collect current value
- Can be positive or negative at collection

**Bullet Requirement System:**
```gdscript
# scripts/gate.gd
const VALUE_PER_HIT := 5
const BULLETS_PER_VALUE := 10  # Requires 10 bullets per +5 value change
const SCROLL_SPEED := 80.0
@export var starting_value := 0
var current_value := 0
var bullets_hit := 0

func on_projectile_hit() -> void:
    bullets_hit += 1

    # Only change value every BULLETS_PER_VALUE hits
    if bullets_hit >= BULLETS_PER_VALUE:
        current_value += VALUE_PER_HIT
        bullets_hit = 0  # Reset counter
        update_display()

# Examples:
# -50 gate needs 100 bullets to reach 0 (10 bullets per +5)
# -100 gate needs 200 bullets to reach 0 (unobtainable in practice)
# 0 gate needs 10 bullets to reach +5

func update_display() -> void:
    if current_value > 0:
        value_label.text = "+" + str(current_value)
        value_label.modulate = Color.GREEN
        sprite.modulate = Color(0.8, 1.0, 0.8)
    elif current_value < 0:
        value_label.text = str(current_value)
        value_label.modulate = Color.RED
        sprite.modulate = Color(1.0, 0.8, 0.8)
    else:
        value_label.text = "0"
        value_label.modulate = Color.WHITE
        sprite.modulate = Color.WHITE

func _on_body_entered(body: Node2D) -> void:
    if body is PlayerManager:
        if current_value > 0:
            body.add_units(current_value)
        elif current_value < 0:
            body.take_damage(abs(current_value))
        queue_free()
```

**Visual Design:**
- Size: 96×96 pixels (1.5x scale from 64×64)
- Value label: 36px font above gate
- Positive: Green tint, "+X" in green
- Negative: Red tint, "-X" in red
- Zero: White, "0" in white

**Difficulty Scaling:**
- Easy tier: 0, 5, -10
- Medium tier: 0, 10, -20, -50
- Hard tier: 0, 20, -30, -100
- Brutal tier: 50, -50, -150, -300 (traps!)

---

## Boss Battle System

**Trigger:** Spawns at 120 seconds when level timer expires

**Boss Properties:**
```gdscript
# scripts/boss.gd
const MAX_HEALTH := 500           # Takes ~500 projectile hits
const ADVANCE_SPEED := 60.0       # Pixels per second (downward)
const BOSS_SCALE := 3.0           # 3x size (96-128 pixels)
const DAMAGE_PER_SECOND := 2.0    # Boss HP loss during collision
const PLAYER_DAMAGE_PER_SECOND := 10.0  # Player units lost during collision
```

**Movement:**
- Spawns at top center (0, -100)
- Advances straight down at 60 px/s
- Does not chase player
- Creates "unstoppable force" tension

**Health System:**
- 500 HP total
- Loses 1 HP per projectile hit
- Shows ProgressBar above sprite (80×10 pixels)
- White flash on hit for visual feedback

**Continuous Collision Damage:**
```gdscript
var is_colliding := false

func _physics_process(delta: float) -> void:
    position.y += ADVANCE_SPEED * delta

    if is_colliding:
        # Apply damage to boss
        current_health -= DAMAGE_PER_SECOND * delta

        # Apply damage to player (probabilistic unit removal)
        var player_damage := PLAYER_DAMAGE_PER_SECOND * delta
        var units_to_remove: int = int(player_damage)
        if randf() < (player_damage - units_to_remove):
            units_to_remove += 1

        for i in units_to_remove:
            player.remove_player_unit()

        # Flash boss red during collision
        apply_collision_flash()
```

**Collision Mechanics:**
- **Both take damage continuously** while in contact (not one-time)
- Boss loses 2 HP per second
- Player loses 10 units per second
- Whoever reaches 0 first loses
- Creates "clash" mechanic requiring sustained engagement

**Entrance Effect:**
- Time slows to 50% for 1 second (`Engine.time_scale = 0.5`)
- Smooth lerp back to normal speed over 1 second
- Affects all movement (background, enemies, projectiles)
- Creates dramatic Matrix-style entrance

**Defeat:**
- Scale up + fade out animation (0.8 seconds)
- Emits `boss_defeated` signal
- Allows level completion
- Player wins if boss defeated before collision depletes all units

**Level Completion:**
- Boss must be defeated for level to complete
- Screen must also be cleared of enemies/collectibles
- SpawnManager checks for boss in "boss" group
- Only emits `level_complete` when boss is gone

---

## Projectile System

**Auto-Firing:**
- Fire rate: 0.5 seconds between volleys
- One projectile per player unit
- Fires straight up (negative Y direction)
- Spread across formation width (±60px)
- Wave-based: Multiple waves with 0.1s delay when unit count exceeds formation width

**Properties:**
```gdscript
# scripts/projectile.gd
const SPEED := 200.0  # Pixels per second (upward)
const MAX_DISTANCE := 800.0

collision_layer = 128  # Layer 8
collision_mask = 6     # Detects enemies (layer 2) and collectibles (layer 3)
```

**Firing Implementation:**
```gdscript
# scripts/player_manager_2d.gd
const FIRE_RATE := 0.5
const WAVE_DELAY := 0.1

func fire_projectiles() -> void:
    var bounds := calculate_formation_bounds()
    var formation_width := max(bounds.width, PROJECTILE_WIDTH)
    var max_per_wave := int(floor(formation_width / PROJECTILE_WIDTH))

    # Split into waves if needed
    # Fire evenly-spaced across formation width
```

**Hit Effects:**
- Enemy: Destroys one unit
- Barrel: Decrements bullets_remaining
- Gate: Increases current_value by +5

---

## Background System

**Scrolling Tiles:**
```gdscript
# scripts/scrolling_background.gd
const SCROLL_SPEED := 80.0
const TILE_SIZE := 32.0

# Ground in playable area (-300 to +300)
ground_texture: 128×128 PNG, scale 0.25× → 32×32 displayed

# Grass outside playable area
grass_texture: 16×16 PNG, scale 2.0× → 32×32 displayed

# Trees at borders (±332)
tree_texture: 16×16 PNG, scale 2.0× → 32×32 displayed
```

**Layout:**
```
[Grass] [Tree] [Ground Path] [Tree] [Grass]
  ^       ^         ^           ^       ^
Outside Border  Playable    Border  Outside
             (-300 to +300)
```

---

## Auto-Spawning System (2-Minute Levels)

### Wave-Based Spawning

**Timing:**
```gdscript
# scripts/spawn_manager.gd
const LEVEL_DURATION := 120.0  # 2 minutes
const WAVE_INTERVAL := 2.0     # Spawn every 2 seconds
const MIN_SPACING_Y := 150.0   # Vertical spacing between objects
```

**Wave Spawning:**
- Spawns 1-3 objects every 2 seconds
- Stops spawning after 2 minutes
- Level completes when timer expires AND all objects cleared
- Spawns in 3 lanes: left (-200), center (0), right (200)
- Objects spawn above screen at Y = -150

**Performance Caps:**
```gdscript
const MAX_ACTIVE_ENEMIES := 8        # Max enemy groups on screen
const MAX_ACTIVE_COLLECTIBLES := 10  # Max barrels + gates on screen
```

### Difficulty Scaling (Based on Total Unit Count)

**Difficulty Tiers:**
```gdscript
enum DifficultyTier {
    EASY,     # 1-30 units
    MEDIUM,   # 31-80 units
    HARD,     # 81-150 units
    BRUTAL    # 151+ units
}
```

**Spawn Weights (Configurable at top of spawn_manager.gd):**
```gdscript
# [enemy_weight, barrel_weight, gate_weight]
const EASY_WEIGHTS := [0.6, 0.2, 0.2]      # Balanced
const MEDIUM_WEIGHTS := [0.65, 0.2, 0.15]  # More enemies
const HARD_WEIGHTS := [0.7, 0.20, 0.10]    # Heavily enemy-focused
const BRUTAL_WEIGHTS := [0.75, 0.15, 0.10] # Enemy onslaught
```

**Enemy Sizes by Tier:**
- Easy: 5, 10, 15 units (small groups)
- Medium: 15, 25, 40 units (medium groups)
- Hard: 25, 50, 75 units (large groups, reduced for balance)
- Brutal: 75, 100, 150 units (massive hordes, reduced for balance)

**Barrel Values by Tier:**
- Easy: 10, 20, 50
- Medium: 20, 50, 100
- Hard: 50, 100, 200
- Brutal: 100, 200, 300

**Gate Starting Values by Tier:**
- Easy: 0, 5, -10 (mostly safe)
- Medium: 0, 10, -20, -50 (some traps)
- Hard: 0, 20, -30, -100 (dangerous traps)
- Brutal: 50, -50, -150, -300 (high-stakes gambles)

**Dynamic Scaling:**
- Difficulty based on current total_unit_count
- Scales up as player accumulates units
- Creates feedback loop: more units = harder enemies = more risk
- Balances unlimited accumulation with increasing challenge

### Planned Features (Future)

**Multiplier Zones:**
- Floor areas that multiply next collection
- x2 (common), x3 (uncommon), x5 (rare)
- Can multiply negative values (risk!)

**Particle Effects (Partially Implemented):**
- Unit death particles (4 per unit, fade effect)
- Collision bursts (TODO)
- Barrel opening (TODO)

**Sound Effects (TODO):**
- Collision impact
- Barrel opening
- Projectile firing
- Gate collection

---

## UI System

### Sidebar Controls (Left Side)

**Always-Visible Game Controls:**
```gdscript
# scripts/hud.gd
# Position: X=0, Size: 140×600
# Background: Semi-transparent dark gray (0.1, 0.1, 0.1, 0.85)
# process_mode = PROCESS_MODE_ALWAYS (works during pause)
```

**Components:**
1. **Title Label**
   - Text: "Roger's first\ngame!"
   - Position: (10, 20)
   - Font size: 20
   - Centered alignment

2. **Stop Button (Red)**
   - Position: (10, 80)
   - Size: 120×50
   - Action: Quit game (get_tree().quit())

3. **Pause/Resume Button (Orange/Green)**
   - Position: (10, 150)
   - Size: 120×50
   - Text changes: "PAUSE" (orange) / "RESUME" (green)
   - Action: Toggle pause state

4. **Restart Button (Blue)**
   - Position: (10, 220)
   - Size: 120×50
   - Action: Reload scene (clean restart)

**Sidebar Behavior:**
- Always visible during gameplay
- Works during pause (process_mode always active)
- Pause button disabled on game over

### Floating Unit Count

**Player Group Label:**
```gdscript
# Created by PlayerManager
count_label.position = Vector2(0, -50)  # Above player group
count_label.text = str(total_unit_count)  # Shows total (including overflow)
count_label.font_size = 32
count_label.modulate = Color.WHITE
count_label.z_index = 10  # Always on top
```

**Display:**
- Shows total_unit_count (unlimited)
- Not capped at 200 (visual units are capped, label is not)
- Updates in real-time
- White color, large font
- Positioned above player swarm

### Game Over Screen

**Center Display:**
```gdscript
# Created by hud.gd on player game_over signal
"GAME OVER" label
- Position: Center of screen
- Font size: 64
- Color: Red
- Anchored to center

Restart button
- Position: (350, 350) - below "GAME OVER"
- Size: 100×40
- Action: Reload scene
```

**On Game Over:**
- Pause button disabled (can't pause dead game)
- Sidebar remains functional (can still quit or restart)
- Player physics disabled

---

## Technical Implementation

### Collision Layer System

| Layer | Bit | Value | Objects |
|-------|-----|-------|---------|
| 1 | 0 | 1 | Player (CharacterBody2D) |
| 2 | 1 | 2 | Enemies (Area2D) |
| 3 | 2 | 4 | Collectibles (Area2D) |
| 8 | 7 | 128 | Projectiles (Area2D) |

### Object Spawning

**Scrolling Objects:**
```gdscript
# Spawn above viewport (Y = -100)
# Move downward at scroll speed
# Destroy when past player (Y > 700)
```

**Enemies:**
```gdscript
# Chase player position
# Never despawn
# Destroy on collision or when all units gone
```

### Performance Considerations

**Object Pooling (Future):**
- Pool projectiles (frequent spawning)
- Pool particle effects
- Reuse instead of instantiate/destroy

**Mobile Optimization:**
- Target 30 FPS minimum
- Limit particle count
- Disable physics for off-screen objects

---

## Design Pillars

### 1. Clarity
- Numbers always visible and large
- Color coding for danger/safety (green/red/white)
- Immediate visual feedback

### 2. Tension
- Scrolling objects create urgency
- Bullet economy forces hard choices
- Unopened barrels are dangerous
- Speed increases pressure

### 3. Risk/Reward
- High-value barrels worth bullet investment
- Negative gates can become positive (or avoided)
- Multipliers amplify gains (or losses!)
- Every decision has consequences

### 4. Mastery
- Perfect play is possible
- Pattern recognition rewarded
- Speed/aim improve with practice

---

**Document Version:** 8.0
**Last Updated:** 2024-12-12
**Status:** Boss battle system implemented, barrel mechanics refined, code quality improvements
**Major Changes:**
- Boss battle at 120 seconds (500 HP, continuous collision damage)
- Barrel instant-reward system (units given when shot open, not on collision)
- Enemy speed reduced 25% (75 px/s for balance)
- Formation reformation redesigned (event-triggered, density-based radius, random positioning)
- Backfill system (50/frame + 10/death maintains 200 rendered units)
- Code quality improvements (helper functions, magic numbers eliminated)
**Next:** Week 3 - Multipliers, particle polish, sound effects
