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
- Constant forward velocity (Z-axis positive)
- No player control over forward speed
- Speed increases difficulty

**Horizontal Movement:**
- **PC:** Follow mouse X position across screen
- **Mobile:** Follow finger X position on screen
- Smooth movement (lerp for responsive feel)
- **Playable Width:** 3 objects wide (barrels/gates/multipliers)
- Constraint: Cannot move outside playable bounds

**Camera Setup:**
- Position: (0, 10, -5) relative to player
- Rotation: -45° X-axis (looking down/isometric)
- FOV: 70° (default)
- Smooth follow with minimal lag

**Design Rationale:**
- Mouse/touch control feels more direct and mobile-friendly
- 3-object width creates meaningful positioning choices
- Auto-forward keeps focus on horizontal decisions
- Isometric view provides clear visibility of oncoming objects

**Implementation Notes:**
```gdscript
# Mouse following (PC)
const PLAYABLE_WIDTH := 6.0  # Total width
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

### 2. Object Movement System

Objects come in two categories based on movement:

**Moving Objects (Advance Toward Player):**
- **Enemies:** Move on Z-axis toward player
- **Barrels:** Move on Z-axis toward player
- Speed affects difficulty (faster = harder to aim/dodge)
- Destroyed when passing player or on interaction

**Static Objects (Attached to Ground):**
- **Gates:** Fixed Z position, player advances toward them
- **Multiplier Zones:** Floor panels at fixed Z position
- Player moves through them as they advance

**Movement Speed:**
```gdscript
# Enemy/Barrel movement
const OBJECT_BASE_SPEED := 3.0  # Toward player
var object_speed := OBJECT_BASE_SPEED

func _physics_process(delta: float) -> void:
    position.z -= object_speed * delta  # Negative = toward player
    
    # Destroy if passed player
    if position.z < player.position.z - 5.0:
        queue_free()
```

**Design Rationale:**
- Moving objects create urgency and dynamic targets
- Static gates/multipliers create positional objectives
- Differentiating movement types adds strategic variety
- Speed scaling provides difficulty control

### 3. Unit Count System

**Core Mechanic:**
- Player has integer unit count (starts at 10-20)
- Display: Large UI counter (top-right corner)
- All gains/losses are immediate and visible

**Gain Units:**
- **Opened Barrels:** +10 to +50 (shoot to open, then collect)
- **Positive Gates:** +value when charged and walked through
- **Multipliers:** Multiply next collection by x2 to x5

**Lose Units:**
- **Enemy Collision:** -min(player_count, enemy_count)
- **Unopened Barrel Collision:** -barrel's value (penalty for not opening)
- **Negative Gates:** -value when walked through

**Game Over:**
- Player reaches 0 units → Defeat
- Display final score/distance
- Option to restart

**Design Rationale:**
- Simple integer math (no fractions)
- Visible numbers create clear risk/reward
- Multiple sources of loss create tension
- Unopened barrels punish poor shooting prioritization

### 4. Combat System

**Enemy Properties:**
```gdscript
class_name Enemy extends Area3D

@export var unit_count := 20
@export var move_speed := 3.0  # Toward player
```

**Collision Resolution:**
```gdscript
func on_collision_with_player(player: Player) -> void:
    var damage := mini(player.unit_count, unit_count)
    player.unit_count -= damage
    unit_count -= damage
    
    if unit_count <= 0:
        queue_free()  # Enemy destroyed
    
    if player.unit_count <= 0:
        player.game_over()
```

**Shooting Enemies:**
- Projectiles reduce enemy unit_count
- Reduced enemies easier to handle in collision
- Can completely destroy before collision

**Enemy Types (Future):**
- **Weak:** 5-15 units, faster movement
- **Standard:** 20-30 units, moderate speed
- **Strong:** 40-60 units, slower but tankier
- **Elite:** 80-100 units, very slow, boss-like

**Visual Feedback:**
- Damage numbers (floating text)
- Screen shake on collision
- Particle burst at collision
- Sound effect (impact)

**Design Rationale:**
- Mutual damage creates risk even when stronger
- Shooting before collision is strategic advantage
- Moving enemies create dynamic threat
- Visual feedback makes combat impactful

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

func on_player_collision(player: Player) -> void:
    if is_open:
        player.unit_count += value  # Reward
    else:
        player.unit_count -= value  # Penalty!
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

func on_player_entered(player: Player) -> void:
    player.unit_count += current_value  # Can subtract if negative
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

func collect_item(value: int) -> void:
    var final_value := value * active_multiplier
    unit_count += final_value
    active_multiplier = 1  # Reset after use
    # Show multiplied number: "+50 (x5) = +250"
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

**HUD Elements:**
```
Top-Right: Unit Count (LARGE, always visible)
Top-Center: Active Multiplier indicator (when active)
Center: Damage/collection numbers (floating text)
Bottom: Distance/Score (small)
```

**Fonts:**
- Bold, sans-serif
- High contrast (white with black outline)
- Large enough for mobile readability

**Feedback Systems:**
- Screen shake (collisions, both positive and negative)
- Particle effects (opening barrels, collection, combat)
- Sound effects (all actions)
- Floating numbers (damage, collection, multiplied values)
- Visual trail behind player

---

## Scope Management

### Week 1: Movement & Collision MVP
✅ Must Have:
- Player forward + horizontal mouse movement
- Enemy collision (unit reduction)
- Barrel collection (simple +units, no shoot-to-open yet)
- UI (unit counter)
- Moving objects system (enemies/barrels toward player)

❌ Not Week 1:
- Shooting system (Week 2)
- Barrel shoot-to-open (Week 2)
- Gates (Week 2)
- Multipliers (Week 2)

### Week 2: Shooting & Core Loop
- Projectile auto-fire
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

**Document Version:** 2.0  
**Last Updated:** 2024-12-07  
**Status:** Design revised per developer feedback  
**Changes:** Removed lane system, added mouse/touch movement, object movement types, shoot-to-open barrels, negative gates, difficulty through speed/availability
