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

#### Barrels (Shoot Multiple Times to Open, Then Collect)

**Multi-Shot System:**
1. **Unopened (Requires Shooting):**
   - Scrolling down screen
   - Shows value on top (e.g., "+15")
   - Shows bullets required in front (e.g., "3")
   - Must hit X times to open
   - **Collision damages player** (-barrel's value) if not opened

2. **Opened (Collectible):**
   - Still scrolling down screen
   - Bullets counter reached 0
   - Value still visible
   - Collision spawns units equal to value
   - Disappears after collection

**Shooting to Open:**
```gdscript
class_name Barrel extends Area2D

@export var value := 15  # Units granted when collected
@export var bullets_required := 3  # Hits needed to open
var bullets_remaining := bullets_required
var is_open := false

@onready var value_label := $ValueLabel  # Shows "+15"
@ontml:parameter>
@onready var bullets_label := $BulletsLabel  # Shows "3" -> "2" -> "1" -> "0"

func _ready() -> void:
    update_visual()

func on_projectile_hit() -> void:
    if not is_open:
        bullets_remaining -= 1
        if bullets_remaining <= 0:
            is_open = true
            bullets_remaining = 0
        update_visual()

func update_visual() -> void:
    value_label.text = "+" + str(value)
    bullets_label.text = str(bullets_remaining) if not is_open else ""

func on_player_collision(player_manager: PlayerManager) -> void:
    if is_open:
        # Spawn new player units
        for i in value:
            player_manager.spawn_player_unit()
    else:
        # Destroy player units as penalty
        for i in value:
            player_manager.remove_player_unit()
    queue_free()
```

**Value Range:**
- Early game: +10 to +20
- Mid game: +30 to +50
- Late game: +50 to +100

**Visual Design:**
- **Unopened:** Barrel sprite with two labels:
  - Top: "+15" (green, value)
  - Front: "3" (white, bullets remaining)
- **Opened:** Same barrel, bullets label disappears
- Opening animation (lid pops off, bullets label fades)
- Collection particle burst

**Bullets Required:**
- Small barrels (+10-20): 1-2 bullets
- Medium barrels (+30-50): 3-4 bullets
- Large barrels (+60-100): 5-6 bullets

**Design Rationale:**
- Forces shooting prioritization (can't open all)
- Multiple bullets required creates resource management
- Penalty for unopened creates risk/reward tension
- Scrolling down creates time pressure
- High-value barrels worth the bullet investment
- Clear feedback (bullets remaining visible)

#### Gates (Accumulation & Risk)

**Behavior:**
- Static position on ground (player advances toward)
- Start at 0 or negative value
- Shoot to charge/increase value
- Walk through to collect current value
- Can be positive or negative at collection

**Value Mechanics:**
```gdscript
class_name Gate extends Area2D

@export var starting_value := 0  # Can be negative!
var current_value := starting_value
const VALUE_PER_HIT := 5

func _ready() -> void:
    current_value = starting_value
    update_display()

func on_projectile_hit() -> void:
    current_value += VALUE_PER_HIT
    update_display()

func on_player_entered(player_manager: PlayerManager) -> void:
    if current_value > 0:
        # Spawn player units
        for i in current_value:
            player_manager.spawn_player_unit()
    else:
        # Destroy player units
        for i in abs(current_value):
            player_manager.remove_player_unit()
    queue_free()
```

**Gate Types:**
- **Positive Start:** Start at +20, shoot for more (+25, +30, etc.)
- **Zero Start:** Start at 0, must shoot to gain value
- **Negative Start:** Start at -30, shoot to bring to positive
- **Unobtainable:** Start at -100, impossible to make positive

**Visual Design:**
- Large archway structure
- Digital counter display shows current value
- **Red** for negative values
- **Yellow** for 0-20
- **Green** for 21+
- Glowing intensity increases with value

**Placement Strategy:**
```
Pattern: Risk Assessment
- Obvious positive: Easy decision, shoot and collect
- Zero gate: Investment required, shoot if time permits
- Negative gate: Major decision - shoot heavily or avoid
- Unobtainable trap: Learn to avoid, wasted bullets = failure
```

**Design Rationale:**
- Creates bullet economy (can't shoot everything)
- Negative gates add avoidance gameplay
- Unobtainable gates punish poor decisions
- Difficult levels feature more traps

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

### 6. Projectile System

**Auto-Firing:**
- Constant fire rate (1 shot per 0.5 seconds)
- No player input required
- Fires straight ahead (Z-axis)
- Despawn at max range or on hit

**Projectile Properties:**
```gdscript
const PROJECTILE_SPEED := 300.0  # Pixels per second
const FIRE_RATE := 0.5  # Seconds between shots
const MAX_RANGE := 400.0  # Pixels
const DAMAGE_TO_ENEMY := 5  # Reduces enemy unit_count
const GATE_CHARGE := 5  # Adds to gate value
const BARREL_HIT := 1  # Decrements barrel bullets_remaining
```

**Targeting:**
- Fires straight up (negative Y direction)
- Hits first object in path
- Priority: Enemies > Barrels > Gates (determined by Y-distance)

**Hit Effects:**
- **Enemy:** Reduce unit_count by 5
- **Barrel:** Decrement bullets_remaining (opens when 0)
- **Gate:** Increase value by 5

**Visual Design:**
- Simple circle sprite or bullet sprite
- Bright color (yellow/orange)
- Trail particle effect (optional)
- Impact flash on hit

**Design Rationale:**
- Auto-fire keeps focus on horizontal movement
- Simple straight trajectory
- Bullet economy creates prioritization decisions
- Multi-purpose targeting (enemies/barrels/gates)

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

### Week 2: Physical Units & Shooting
**Major Refactor:**
- Replace HUD counter with physical player units
- Player group manager (spawn/remove units)
- Physical player unit models in tight formation
- Enemy groups (spawned as clusters)
- Refactor collision to destroy individual units
- Position all objects on ground (not floating)
- Scale: units small (0.3-0.5), collectibles medium (1.0-1.5)

**New Features:**
- Projectile auto-fire system
- Barrel shoot-to-open mechanic
- Unopened barrel damage
- Gate system (shoot to charge)
- Negative gates

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

**Document Version:** 4.0
**Last Updated:** 2024-12-09
**Status:** Major revision - 2D overhead perspective
**Changes:**
- Converted from 3D to 2D overhead view
- Enemies chase player (never roll off screen)
- Collectibles scroll down (can be missed)
- Barrels require multiple bullet hits to open (bullets_required value)
- Barrels show value on top, bullets remaining in front
- All coordinates changed from Vector3/Z-axis to Vector2/Y-axis
- Scale changed from world units to pixels
