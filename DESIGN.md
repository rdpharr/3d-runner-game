# Game Design Document - 3D Mobile Runner

## Vision Statement

A 3D auto-running game where players manage unit count through strategic horizontal movement, combat, and resource collection. Players must decide which objects to shoot open, which to collect, and which to avoid in an oncoming stream of enemies and collectibles.

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
- Player is STATIONARY at Z=0
- Objects move toward player (negative Z to positive Z)
- Creates visual effect of player running while maintaining simple camera
- Speed increases difficulty

**Horizontal Movement:**
- **PC:** Follow mouse X position across screen
- **Mobile:** Follow finger X position on screen
- Smooth movement (lerp for responsive feel)
- **Playable Width:** 3 objects wide (barrels/gates/multipliers)
- Constraint: Cannot move outside playable bounds

**Camera Setup:**
- Position: player.position + Vector3(0, 12, 5) (slightly behind at positive Z)
- Rotation: Vector3(-45, 180, 0) (tilted down, facing negative Z)
- Result: Player at bottom of screen, enemies at top
- Camera follows player horizontally

**Design Rationale:**
- Mouse/touch control feels more direct and mobile-friendly
- 3-object width creates meaningful positioning choices
- Stationary player simplifies camera and physics
- Objects moving toward player creates urgency and visual flow

**Implementation Notes:**
```gdscript
# Player (scripts/player_runner.gd)
const PLAYABLE_WIDTH := 6.0
const MOVEMENT_SMOOTHING := 0.2

func _physics_process(_delta: float) -> void:
    # Player is STATIONARY - doesn't move in Z
    velocity.z = 0

    # Horizontal mouse following
    var mouse_pos := get_viewport().get_mouse_position()
    var viewport_size := get_viewport().get_visible_rect().size

    # Map mouse X (0 to screen width) to game X (-3 to +3)
    var normalized_x := (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
    var target_x := normalized_x * (PLAYABLE_WIDTH / 2.0)
    target_x = clamp(target_x, -PLAYABLE_WIDTH/2, PLAYABLE_WIDTH/2)

    # Smooth horizontal movement
    position.x = lerp(position.x, target_x, MOVEMENT_SMOOTHING)

    move_and_slide()
```

### 2. Object Movement System

Objects come in two categories based on movement:

**Moving Objects (Advance Toward Player):**
- **Enemies:** Spawn at negative Z, move toward positive Z (top to bottom of screen)
- **Barrels:** Spawn at negative Z, move toward positive Z (top to bottom of screen)
- Speed affects difficulty (faster = harder to aim/dodge)
- Destroyed when passing player or on interaction

**Static Objects (Attached to Ground - Future):**
- **Gates:** Fixed Z position on ground
- **Multiplier Zones:** Floor panels at fixed Z position
- Player advances toward them (future feature)

**Movement Speed:**
```gdscript
# Enemy/Barrel movement (scripts/enemy.gd, barrel_simple.gd)
const MOVE_SPEED := 3.0
const DESPAWN_DISTANCE := 50.0

func _physics_process(delta: float) -> void:
    # Move from negative Z to positive Z (top to bottom of screen)
    position.z += MOVE_SPEED * delta

    # Despawn if moved past player (positive Z direction)
    var player := get_tree().get_first_node_in_group("player")
    if player and position.z > player.position.z + DESPAWN_DISTANCE:
        queue_free()
```

**Design Rationale:**
- Moving objects create urgency and dynamic targets
- Top-to-bottom movement feels natural (like falling toward player)
- Player stationary at Z=0, objects spawn at negative Z (e.g., -10, -15, -20)
- Differentiating movement types adds strategic variety
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
var player_units: Array[Node3D] = []
const UNIT_SPACING := 0.3  # Tight formation
const FORMATION_RADIUS := 1.5  # Circular cluster

func spawn_player_unit() -> void:
    var unit := player_unit_scene.instantiate()
    # Position in tight circular formation around center
    var angle := randf() * TAU
    var radius := randf() * FORMATION_RADIUS
    unit.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
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
- Player units: Small humanoid models (scale 0.3-0.5)
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
class_name EnemyGroup extends Node3D

@export var enemy_unit_scene: PackedScene
@export var unit_count := 20
@export var move_speed := 3.0
var enemy_units: Array[Node3D] = []

func _ready() -> void:
    spawn_enemy_units(unit_count)

func spawn_enemy_units(count: int) -> void:
    for i in count:
        var unit := enemy_unit_scene.instantiate()
        # Tight cluster formation (like player)
        var angle := randf() * TAU
        var radius := randf() * 1.0  # Tighter than player
        unit.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
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
- Enemy units: Small models (same scale as player units)
- Tightly clustered (creates threat impression)
- Different color (red) to distinguish from player
- Groups move together toward player

**Object Scale Guidelines:**
- **Player/Enemy units:** Scale 0.3-0.5 (small, many)
- **Collectibles (barrels/gates):** Scale 1.0-1.5 (medium, noticeable)
- **Bosses (future):** Scale 2.0-3.0 (large, imposing)

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

#### Barrels (Shoot to Open, Then Collect)

**Two-State System:**
1. **Unopened (Dangerous):**
   - Moving toward player
   - Shows "?" or locked icon
   - **Collision damages player** (-barrel's value)
   - Must shoot to open

2. **Opened (Collectible):**
   - Still moving toward player
   - Shows "+X" value
   - Collision adds units to player
   - Disappears after collection

**Shooting to Open:**
```gdscript
class_name Barrel extends Area3D

@export var value := 15
var is_open := false

func on_projectile_hit() -> void:
    if not is_open:
        is_open = true
        update_visual()  # Change from "?" to "+15"
        # Play open sound/effect

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
- **Unopened:** Gray/locked barrel, "?" icon
- **Opened:** Brown/wooden barrel, green "+X" label
- Opening animation (lid pops off)
- Collection particle burst

**Design Rationale:**
- Forces shooting prioritization (can't open all)
- Penalty for unopened creates risk/reward tension
- Moving toward player adds time pressure
- High-value barrels worth the bullet investment

#### Gates (Accumulation & Risk)

**Behavior:**
- Static position on ground (player advances toward)
- Start at 0 or negative value
- Shoot to charge/increase value
- Walk through to collect current value
- Can be positive or negative at collection

**Value Mechanics:**
```gdscript
class_name Gate extends Area3D

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
const PROJECTILE_SPEED := 20.0
const FIRE_RATE := 0.5  # Seconds between shots
const MAX_RANGE := 30.0
const DAMAGE_TO_ENEMY := 5  # Reduces enemy unit_count
const GATE_CHARGE := 5  # Adds to gate value
const BARREL_OPEN := 1  # Opens barrel (any hit)
```

**Targeting:**
- Fires straight ahead (no homing)
- Hits first object in path
- Priority: Enemies > Barrels > Gates (determined by Z-distance)

**Hit Effects:**
- **Enemy:** Reduce unit_count by 5
- **Barrel:** Open barrel (change state)
- **Gate:** Increase value by 5

**Visual Design:**
- Simple sphere mesh
- Bright color (yellow/orange)
- Trail particle effect
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

**Document Version:** 3.0
**Last Updated:** 2024-12-08
**Status:** Major revision - physical unit representation
**Changes:**
- Removed HUD unit counter, replaced with physical player objects
- Player units in tight swarm formation (crowded look)
- Enemy groups spawn as clusters (same crowded style)
- All units small scale (0.3-0.5), collectibles medium (1.0-1.5)
- Objects positioned on ground, not floating
- Unit spawning/destruction for all gains/losses
