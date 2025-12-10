# Game Design Document - 2D Overhead Runner

## Vision Statement

A 2D overhead auto-running game where players manage unit count through strategic horizontal movement, combat, and resource collection. Players must decide which objects to shoot open, which to collect, and which to avoid in an oncoming stream of enemies and collectibles.

## Core Gameplay Loop

```
Player auto-advances → Dodge enemies (-units) → Shoot/collect barrels (+units) →
Shoot gates to open (±units) → Pass multipliers (boost collection) → Repeat
```

**Session Duration:** 30-60 seconds per run  
**Difficulty Curve:** Speed of progression, enemy speed, enemy unit count, strategic resource placement  
**Skill Expression:** Horizontal positioning (mouse/touch), shooting prioritization, risk/reward decisions

---

## Detailed Mechanics

### 1. Player Movement System

**Forward Movement:**
- Player is STATIONARY at Y=0 (bottom of screen)
- Enemies move toward player (negative Y to positive Y, top to bottom)
- Collectibles scroll past player (top to bottom, can be missed)
- Creates visual effect of player running while maintaining simple camera
- Speed increases difficulty

**Horizontal Movement:**
- **PC:** Follow mouse X position across screen
- **Mobile:** Follow finger X position on screen
- Smooth movement (lerp for responsive feel)
- **Playable Width:** 3 objects wide (barrels/gates/multipliers)
- Constraint: Cannot move outside playable bounds

**Camera Setup:**
- Overhead 2D view (Camera2D)
- Position: Fixed at center (0, viewport_height/2)
- Result: Player moves within viewport, not camera-centered
- Player at bottom of screen, objects spawn at top
- Camera stationary - player moves side-to-side

**Design Rationale:**
- 2D overhead view is simpler and more mobile-friendly
- Mouse/touch control feels more direct
- 3-object width creates meaningful positioning choices
- Stationary player simplifies camera and physics
- Enemies chase player (won't miss), collectibles scroll off (can miss)

**Implementation Notes:**
```gdscript
# Player (scripts/player_runner.gd)
const PLAYABLE_WIDTH := 600.0  # Screen pixels
const MOVEMENT_SMOOTHING := 0.2

func _physics_process(_delta: float) -> void:
    # Player is STATIONARY - doesn't move in Y
    velocity.y = 0

    # Horizontal mouse following
    var mouse_pos := get_viewport().get_mouse_position()
    var viewport_size := get_viewport().get_visible_rect().size

    # Map mouse X (0 to screen width) to game X
    var target_x := mouse_pos.x
    target_x = clamp(target_x, 50, viewport_size.x - 50)

    # Smooth horizontal movement
    position.x = lerp(position.x, target_x, MOVEMENT_SMOOTHING)

    move_and_slide()
```

### 2. Object Movement System

Objects come in two categories based on movement:

**Enemies (Always Move Toward Player):**
- Spawn at top of screen (negative Y)
- Move toward player position (chase behavior)
- **Never roll off screen** - always pursue player
- Speed affects difficulty (faster = harder to dodge)
- Destroyed only on collision or when shot

**Collectibles (Scroll Down, Can Miss):**
- **Barrels:** Spawn at top, move straight down
- **Gates:** Spawn at top, move straight down (future)
- **Roll off screen** if not collected
- Player must position to intercept

**Static Objects (Future):**
- **Multiplier Zones:** Fixed position panels
- Player advances toward them

**Movement Speed:**
```gdscript
# Enemy movement (scripts/enemy.gd)
const CHASE_SPEED := 100.0  # Pixels per second

func _physics_process(delta: float) -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player:
        # Move toward player position
        var direction := (player.position - position).normalized()
        position += direction * CHASE_SPEED * delta

# Collectible movement (scripts/barrel.gd)
const SCROLL_SPEED := 150.0  # Pixels per second

func _physics_process(delta: float) -> void:
    # Move straight down
    position.y += SCROLL_SPEED * delta

    # Despawn if off screen
    if position.y > get_viewport_rect().size.y + 50:
        queue_free()
```

**Design Rationale:**
- Enemies chasing creates constant threat
- Collectibles scrolling creates positioning skill test
- Missed collectibles = lost opportunity
- Top-to-bottom movement feels natural in overhead view
- Speed scaling provides difficulty control

### 3. Unit Count System (Physical Representation)

**Core Mechanic:**
- **No HUD counter** - units are physical player objects
- Each unit = one small player character model
- Player group moves together (tightly packed formation)
- Visual representation creates satisfying accumulation

**Physical Player Units:**
```gdscript
# Player manager tracks all unit objects
var player_units: Array[Node2D] = []
const UNIT_SPACING := 5.0  # Tight formation (pixels)
const FORMATION_RADIUS := 30.0  # Circular cluster (pixels)

func spawn_player_unit() -> void:
    var unit := player_unit_scene.instantiate()
    # Position in tight circular formation around center
    var angle := randf() * TAU
    var radius := randf() * FORMATION_RADIUS
    unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)
    player_units.append(unit)
    add_child(unit)

func remove_player_unit() -> void:
    if player_units.size() > 0:
        var unit := player_units.pop_back()
        unit.queue_free()
```

**Gain Units:**
- **Opened Barrels:** Spawn +10 to +50 new player objects
- **Positive Gates:** Spawn +value new player objects
- **Multipliers:** Multiply spawned units by x2 to x5

**Lose Units:**
- **Enemy Collision:** Destroy min(player_count, enemy_count) player objects
- **Unopened Barrel Collision:** Destroy value player objects
- **Negative Gates:** Destroy value player objects

**Game Over:**
- All player units destroyed (0 remaining) → Defeat
- Display final count/distance
- Option to restart

**Visual Design:**
- Player units: Small 2D sprites (scale 0.5-0.7)
- Tightly clustered (creates "crowd" feel)
- Move together as formation (follow leader)
- Individual units can be hit/destroyed

**Design Rationale:**
- Physical representation more satisfying than numbers
- Crowded swarm creates visual impact
- Seeing units destroyed/added is visceral feedback
- No UI needed - count is obvious from visual
- Bigger swarm = more impressive = more risk

### 4. Combat System (Enemy Groups)

**Enemy Properties:**
```gdscript
# Enemy manager spawns groups
class_name EnemyGroup extends Node2D

@export var enemy_unit_scene: PackedScene
@export var unit_count := 20
@export var chase_speed := 100.0
var enemy_units: Array[Node2D] = []

func _ready() -> void:
    spawn_enemy_units(unit_count)

func spawn_enemy_units(count: int) -> void:
    for i in count:
        var unit := enemy_unit_scene.instantiate()
        # Tight cluster formation (like player)
        var angle := randf() * TAU
        var radius := randf() * 20.0  # Pixels
        unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)
        enemy_units.append(unit)
        add_child(unit)
```

**Collision Resolution:**
```gdscript
func on_collision_with_player(player_manager: PlayerManager) -> void:
    var damage := mini(player_manager.player_units.size(), enemy_units.size())

    # Destroy units from both sides
    for i in damage:
        player_manager.remove_player_unit()
        remove_enemy_unit()

    if enemy_units.size() <= 0:
        queue_free()  # Enemy group eliminated

    if player_manager.player_units.size() <= 0:
        player_manager.game_over()
```

**Shooting Enemies:**
- Projectiles destroy individual enemy units
- Reduced enemy groups easier to handle
- Can eliminate entire group before collision

**Enemy Types (Future):**
- **Weak Groups:** 5-15 units, faster movement
- **Standard Groups:** 20-30 units, moderate speed
- **Strong Groups:** 40-60 units, slower but tankier
- **Boss:** Single large unit (different scale, high HP)

**Visual Design:**
- Enemy units: Small 2D sprites (same scale as player units)
- Tightly clustered (creates threat impression)
- Different color (red) to distinguish from player
- Groups move together toward player

**Object Scale Guidelines:**
- **Player/Enemy units:** 16x16 to 24x24 pixels (small, many)
- **Collectibles (barrels/gates):** 48x48 to 64x64 pixels (medium, noticeable)
- **Bosses (future):** 96x96 to 128x128 pixels (large, imposing)

**Visual Feedback:**
- Individual units destroyed (pop/fade)
- Screen shake on group collision
- Particle burst at collision points
- Sound effect (impact)

**Design Rationale:**
- Physical enemy groups match player visual style
- Crowded formations create tension
- Individual unit destruction is satisfying
- Mutual elimination is visceral and clear
- No need for HP numbers - you see the units

### 5. Collectible Systems

#### Barrels (Shoot Multiple Times to Open, Then Collect) ✅ Implemented Week 2

**Multi-Shot System:**
1. **Unopened (Requires Shooting):**
   - Scrolling down screen (120 px/sec)
   - Shows value on top (e.g., "15")
   - Shows bullets remaining as yellow text (e.g., "2")
   - Must hit X times to open
   - **Collision damages player** (lose barrel's value in units) if not opened

2. **Opened (Collectible):**
   - Still scrolling down screen
   - Bullets counter disappeared (reached 0)
   - Value changes to green "+15"
   - Sprite gains green tint
   - Collision adds units equal to value
   - Disappears after collection

**Implementation:**
```gdscript
# scripts/barrel_2d.gd
extends Area2D
class_name Barrel

const SCROLL_SPEED := 120.0
const DESPAWN_Y := 700.0

@export var value := 15  # Units granted when collected
var bullets_required := 1  # Calculated from value
var bullets_remaining := 1
var is_open := false

@onready var sprite := $Sprite2D
@onready var value_label := $ValueLabel  # Shows "15" or "+15"
@onready var bullet_label := $BulletLabel  # Shows "2" -> "1" -> ""

func _ready() -> void:
    bullets_required = calculate_bullets_needed(value)
    bullets_remaining = bullets_required
    update_display()

func calculate_bullets_needed(barrel_value: int) -> int:
    # 1-10: 1 bullet, 11-20: 2 bullets, 21-30: 3 bullets, etc.
    return max(1, barrel_value / 10)

func on_projectile_hit() -> void:
    if is_open:
        return

    bullets_remaining -= 1
    if bullets_remaining <= 0:
        is_open = true
        bullets_remaining = 0

    update_display()

func update_display() -> void:
    if is_open:
        value_label.text = "+" + str(value)
        value_label.modulate = Color.GREEN
        bullet_label.text = ""
        sprite.modulate = Color(0.8, 1.0, 0.8)  # Green tint
    else:
        value_label.text = str(value)
        value_label.modulate = Color.WHITE
        bullet_label.text = str(bullets_remaining)
        bullet_label.modulate = Color.YELLOW

func _on_body_entered(body: Node2D) -> void:
    if body is PlayerManager:
        if is_open:
            body.add_units(value)  # Reward
        else:
            body.take_damage(value)  # Penalty!
        queue_free()
```

**Size & Visual Design:**
- Size: 32x32 pixels (~2 units wide)
- Sprite: tile_0100.png scaled 4x (from 8x8 to 32x32)
- Collision: RectangleShape2D 32x32
- **Unopened:** White sprite, white value label, yellow bullet counter
- **Opened:** Green-tinted sprite, green "+value" label, no bullet counter
- Labels positioned above barrel for visibility

**Bullets Required Calculation:**
- Values 1-10: 1 bullet
- Values 11-20: 2 bullets
- Values 21-30: 3 bullets
- Formula: `max(1, value / 10)`

**Value Range:**
- Early game: +10 to +20 (1-2 bullets)
- Mid game: +30 to +50 (3-5 bullets)
- Late game: +50 to +100 (5-10 bullets)

**Design Rationale:**
- Forces shooting prioritization (can't open all)
- Multiple bullets required creates resource management
- Penalty for unopened creates risk/reward tension
- Scrolling down creates time pressure (can miss if not intercepted)
- High-value barrels worth the bullet investment
- Clear visual feedback (bullet counter, color changes)
- Penalty = value ensures meaningful consequences

#### Gates (Accumulation & Risk) ✅ Implemented Week 2

**Behavior:**
- Scroll down screen (80 px/sec - slower than barrels)
- Start at positive, zero, or negative value
- Shoot to increase value (+5 per hit)
- Walk through to collect current value
- Can be positive or negative at collection
- Very large size (6+ units wide) - hard to miss

**Implementation:**
```gdscript
# scripts/gate.gd
extends Area2D
class_name Gate

const VALUE_PER_HIT := 5
const SCROLL_SPEED := 80.0  # Slower than barrels
const DESPAWN_Y := 700.0

@export var starting_value := 0  # Can be negative!
var current_value := 0

@onready var value_label := $ValueLabel
@onready var sprite_container := $Sprite2D

func _ready() -> void:
    current_value = starting_value
    update_display()
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    position.y += SCROLL_SPEED * delta
    if position.y > DESPAWN_Y:
        queue_free()

func on_projectile_hit() -> void:
    current_value += VALUE_PER_HIT
    update_display()

func update_display() -> void:
    var tint_color: Color

    if current_value > 0:
        value_label.text = "+" + str(current_value)
        value_label.modulate = Color.GREEN
        tint_color = Color(0.8, 1.0, 0.8)
    elif current_value < 0:
        value_label.text = str(current_value)
        value_label.modulate = Color.RED
        tint_color = Color(1.0, 0.8, 0.8)
    else:
        value_label.text = "0"
        value_label.modulate = Color.WHITE
        tint_color = Color.WHITE

    # Apply tint to all sprite children
    for child in sprite_container.get_children():
        if child is Sprite2D:
            child.modulate = tint_color

func _on_body_entered(body: Node2D) -> void:
    if body is PlayerManager:
        if current_value > 0:
            body.add_units(current_value)
        elif current_value < 0:
            body.take_damage(abs(current_value))
        queue_free()
```

**Size & Visual Design:**
- Size: 96x32 pixels (6+ units wide - very large!)
- Structure: 3 tiles horizontally aligned
  - Left: tile_0060.png (4x scale)
  - Center: tile_0061.png (4x scale)
  - Right: tile_0059.png (4x scale)
- Collision: RectangleShape2D 96x32
- **Positive value:** Green tint, "+X" label in green
- **Negative value:** Red tint, "-X" label in red
- **Zero:** White, "0" label in white
- All three sprite tiles tint together based on value
- Value label positioned above gate (font size 32)

**Gate Types:**
- **Positive Start:** Start at +10 to +20, shoot for more
- **Zero Start:** Start at 0, must shoot to gain value
- **Negative Start:** Start at -15 to -30, shoot to bring to positive or avoid
- **Unobtainable (Future):** Start very negative, impossible to make positive

**Value Per Hit:**
- Each projectile hit adds exactly +5 to current_value
- Starting value -15 needs 3 hits to reach 0, 4 hits to be positive
- Strategic: invest bullets to improve value or avoid entirely

**Placement Strategy:**
```
Pattern: Risk Assessment
- Obvious positive: Easy decision, walk through (shoot for bonus)
- Zero gate: Investment required, shoot if bullets available
- Negative gate: Major decision - shoot heavily or avoid
- Unobtainable trap (Future): Learn to avoid, wasted bullets = failure
```

**Design Rationale:**
- Creates bullet economy (can't shoot everything)
- Negative gates add avoidance gameplay
- Large size makes them hard to miss (strategic positioning required)
- Color coding provides instant feedback (green=safe, red=danger)
- Accumulation system rewards bullet investment
- Can turn traps into rewards with enough shooting

#### Multiplier Zones

**Behavior:**
- Floor area with colored texture (static on ground)
- Walk through → next collection multiplied
- Single-use per zone
- Consumed after triggering next collection

**Multiplier Values:**
- x2 (common, green)
- x3 (uncommon, blue)
- x5 (rare, gold)

**Effect Application:**
```gdscript
var active_multiplier := 1

func on_multiplier_entered(multiplier: int) -> void:
    active_multiplier = multiplier
    # Show UI indicator: "NEXT: x5"

func collect_item(value: int, player_manager: PlayerManager) -> void:
    var final_value := value * active_multiplier
    # Spawn multiplied units
    for i in final_value:
        player_manager.spawn_player_unit()
    active_multiplier = 1  # Reset after use
    # Show visual feedback: "+50 (x5) = +250"
```

**Visual Design:**
- Glowing floor panel (3 objects wide)
- Number displayed clearly (x2, x5)
- Color coding by tier
- Trail effect when player passes through
- UI indicator showing active multiplier

**Placement Strategy:**
```
Pattern: Strategic Sequencing
- Before high-value barrels (maximize gain)
- Before positive gates (multiply accumulated)
- After negative gates (minimize loss if miscalculated)
- Test: Which collection is worth multiplying?
```

**Design Rationale:**
- Creates sequencing decisions (what to multiply?)
- Rewards planning ahead
- Can multiply negative values (risk!)
- High-value moments feel exciting

### 6. Projectile System (✅ Implemented Week 2)

**Auto-Firing:**
- Constant fire rate (0.5 seconds between volleys)
- No player input required
- Each player unit fires one projectile per volley
- Fires straight up (negative Y direction)
- Spread across full formation width (±30px)
- Despawn after 800px traveled or off-screen

**Projectile Properties:**
```gdscript
# scripts/projectile.gd
extends Area2D
class_name Projectile

const SPEED := 200.0  # Pixels per second (upward)
const MAX_DISTANCE := 800.0  # Despawn distance

# Collision configuration
collision_layer = 128  # Layer 8
collision_mask = 6     # Detects layers 2 (enemies) and 3 (collectibles)
```

**Firing Implementation:**
```gdscript
# scripts/player_manager_2d.gd
const FIRE_RATE := 0.5  # Seconds between shots
const FORMATION_RADIUS := 30.0  # Formation width

func fire_projectiles() -> void:
    # Each unit fires a projectile spread across full formation width
    for i in player_units.size():
        var projectile := projectile_scene.instantiate()
        var offset_x := randf_range(-FORMATION_RADIUS, FORMATION_RADIUS)
        projectile.position = global_position + Vector2(offset_x, -20)
        get_parent().add_child(projectile)
```

**Collision Detection:**
- Uses Area2D with `area_entered` signal
- Dual-check pattern for different scene structures:
  - Direct check: `area.has_method("on_projectile_hit")` (Barrel, Gate)
  - Parent check: `area.get_parent().has_method()` (EnemyGroup)
- Destroys projectile on hit

**Hit Effects:**
- **Enemy:** Destroys one enemy unit via `on_projectile_hit()`
- **Barrel:** Decrements `bullets_remaining` (opens when 0)
- **Gate:** Increases `current_value` by +5
- All targets implement `on_projectile_hit()` interface

**Visual Design:**
- Size: 8x8 pixels (smallest object type)
- Sprite: tile_0007.png from micro-roguelike pack
- Color: Yellow tint (modulate Color(1, 1, 0.5, 1))
- Collision shape: CircleShape2D radius 4px
- No trail effects (performance consideration)

**Collision Layer System:**
| Layer | Bit | Value | Objects |
|-------|-----|-------|---------|
| 1 | 0 | 1 | Player (CharacterBody2D) |
| 2 | 1 | 2 | Enemies (EnemyGroup Area2D) |
| 3 | 2 | 4 | Collectibles (Barrel, Gate) |
| 8 | 7 | 128 | Projectiles |

**Design Rationale:**
- Auto-fire keeps focus on horizontal movement
- Multiple projectiles per volley scales with unit count
- Spread covers full formation width for better coverage
- Bullet economy creates prioritization decisions (can't shoot everything)
- Multi-purpose targeting (enemies/barrels/gates)
- Small size (8x8) distinguishes from other objects visually

---

## Difficulty Progression

### Difficulty Variables

**Progression Speed:**
- Player forward speed: 5 → 8 → 12 units/sec
- Faster = less time to react

**Enemy Speed:**
- Object approach speed: 3 → 5 → 7 units/sec
- Faster = harder to aim, more urgent decisions

**Enemy Unit Count:**
- Early: 10-20 units per enemy
- Mid: 30-50 units per enemy
- Late: 60-100 units per enemy

**Collectible Availability:**
- Early: Many positive barrels, positive gates
- Mid: Mix of positive/zero gates, balanced barrels
- Late: Negative gates, unobtainable traps, sparse barrels

**Most Difficult Levels:**
- Maximum speeds (player 12, enemy 7)
- High enemy counts (80-100 units)
- Negative/unobtainable gates dominate
- Very few safe barrels
- Requires perfect shooting prioritization
- One mistake = game over

### Level Phases

**Early (0-100 Z):**
- Speed: Player 5, Enemy 3
- Enemies: 15-20 units, sparse
- Barrels: Many positive, easy to open
- Gates: All positive starting values
- Goal: Teach mechanics

**Mid (100-300 Z):**
- Speed: Player 6-7, Enemy 4-5
- Enemies: 25-40 units, moderate density
- Barrels: Mix of values, some traps
- Gates: Zero and negative gates appear
- Goal: Test skill

**Late (300+ Z):**
- Speed: Player 8+, Enemy 6+
- Enemies: 50-100 units, high density
- Barrels: Mostly high-value but dangerous
- Gates: Many negative/unobtainable traps
- Goal: Master-level challenge

### Pattern Library

**Pattern: Barrel Gauntlet**
```
Z: 100 - Barrel(+20) left, Enemy(30) center, Barrel(+20) right
Z: 105 - Barrel(+15) center
Purpose: Shoot barrels quickly while dodging enemy
```

**Pattern: Gate Trap**
```
Z: 200 - Gate(-50) left, Gate(-50) center, Gate(-50) right
Z: 205 - Barrel(+30) center (need units to survive gates)
Purpose: Must avoid or heavily shoot gates
```

**Pattern: Multiplier Setup**
```
Z: 250 - Multiplier (x5)
Z: 255 - Barrel(+50) center (opens to +250 with multiplier!)
Purpose: Reward good shooting + planning
```

**Pattern: Impossible Choice**
```
Z: 300 - Gate(-100) left, Enemy(80) center, Gate(-100) right
Z: 305 - Barrel(+10) center (not enough to recover)
Purpose: All options bad, minimize damage
```

---

## Visual Design

### Art Style

**Inspiration:** Kenney.nl low-poly aesthetic
- Simple geometric shapes
- Bright, readable colors
- Minimal textures
- High contrast

### Color Coding

**Player:** Blue (#4A90E2)
**Enemies:** Red (#E24A4A)

**Barrels:**
- Unopened: Gray (#808080) with "?"
- Opened: Brown (#8B4513) with green "+X"

**Gates:**
- Negative value: Red glow
- Zero/low value: Yellow glow
- Positive value: Green glow

**Multipliers:**
- x2: Green (#2ECC71)
- x3: Blue (#3498DB)
- x5: Gold (#F39C12)

**Ground:** Gray (#95A5A6)
**Sky:** Light Blue (#87CEEB)

**Lighting:**
- Single directional light (sun)
- Soft shadows
- No dynamic lighting (performance)

### UI Design

**HUD Elements (Minimal):**
```
Top-Center: Active Multiplier indicator (when active) - only if needed
Center: Floating effect text ("+50 units!", "x5 multiplier!")
Bottom: Distance/Score (small)
```

**No Unit Counter:**
- Unit count visible through physical player objects
- Count is self-evident from swarm size
- Cleaner UI, more immersive

**Fonts:**
- Bold, sans-serif
- High contrast (white with black outline)
- Large enough for mobile readability

**Feedback Systems:**
- Screen shake (collisions, both positive and negative)
- Particle effects (opening barrels, collection, combat)
- Sound effects (all actions)
- Floating effect text (significant events only)
- Visual trails behind player swarm

---

## Scope Management

### Week 1: Movement & Collision MVP ✅ COMPLETE
- Player forward + horizontal mouse movement
- Enemy collision (unit reduction via HUD counter)
- Barrel collection (simple +units via HUD)
- UI with unit counter (top-right HUD)
- Moving objects system (enemies/barrels toward player)
- Camera follow system
- Ground collision

### Week 2: Physical Units & Shooting ✅ COMPLETE
**Major Refactor:**
- ✅ Replace HUD counter with physical player units
- ✅ Player group manager (spawn/remove units)
- ✅ Physical player unit sprites in tight formation (15 starting units, 30px radius)
- ✅ Enemy groups (spawned as clusters)
- ✅ Refactor collision to destroy individual units
- ✅ Position all objects on ground (2D overhead)
- ✅ Scale hierarchy: projectiles (8x8) < units (16x16) < barrels (32x32) < gates (96x32)

**New Features:**
- ✅ Projectile auto-fire system (0.5s intervals, one per unit)
- ✅ Barrel shoot-to-open mechanic (bullets_required counter)
- ✅ Unopened barrel damage (penalty system)
- ✅ Gate system (shoot to charge, +5 per hit)
- ✅ Negative gates (start at negative values)
- ✅ Enemy projectile damage (thin swarms before collision)
- ✅ Visual feedback (bullet counters, color tinting, value labels)

### Week 3: Difficulty & Polish
- Multiplier zones
- Speed scaling (difficulty)
- Unobtainable gates
- Particle effects
- Sound effects

### Week 4+: Advanced
- Multiple levels
- Upgrade system
- Mobile touch controls
- Menu system
- Save/progress

---

## Design Pillars

### 1. Clarity
- Numbers always visible and large
- Color coding for danger/safety
- Immediate visual feedback
- No hidden mechanics

### 2. Tension
- Moving objects create urgency
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
- Difficult levels demand expertise

---

## Technical Notes

### Object Spawning

**Moving Objects:**
- Spawn ahead of player (Z + 50)
- Move toward player (negative Z velocity)
- Destroy when past player (Z < player.z - 5)

**Static Objects:**
- Place at fixed Z positions
- Player advances toward them
- Destroy after player passes

### Collision Detection

**Moving Objects (Enemies/Barrels):**
- Use Area3D with body_entered signal
- Check collision with player CharacterBody3D
- Apply effects immediately

**Static Objects (Gates/Multipliers):**
- Use Area3D with body_entered signal
- Trigger when player enters zone
- Destroy or mark as used

---

**Document Version:** 5.0
**Last Updated:** 2024-12-09
**Status:** Week 2 Projectile Combat Complete
**Changes:**
- Week 2 implementation complete: projectile system, barrel multi-shot, gate accumulation
- Projectile auto-fire system (0.5s intervals, one per unit, spread across formation)
- Barrel shoot-to-open mechanics (bullets_required counter, penalty/reward system)
- Gate accumulation system (starting_value ± projectile hits, color-coded feedback)
- Enemy projectile damage (thin swarms before collision)
- Size hierarchy established: projectiles (8x8) < units (16x16) < barrels (32x32) < gates (96x32)
- Collision layer system documented (layers 1, 2, 3, 8)
- Visual feedback systems (bullet counters, color tinting, value labels)
