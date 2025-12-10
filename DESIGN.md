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
- Speed: 100 px/s

**Collectibles (Scroll):**
- Barrels and gates scroll straight down
- Speed: 120 px/s (barrels), 80 px/s (gates)
- Despawn if missed

---

## Unit System (Physical Swarm)

### Core Mechanic

**Visual Representation:**
- No HUD counter - units are physical sprites
- Each unit = one 32×32 pixel sprite
- Units cluster in circular formation
- Visual count is obvious from swarm size

**Physical Player Units:**
```gdscript
# scripts/player_manager_2d.gd
var player_units: Array[Sprite2D] = []
const FORMATION_RADIUS := 60.0  # Pixels (doubled for 32×32 units)
const MAX_PLAYER_UNITS := 200

func spawn_player_unit() -> void:
    var unit := player_unit_scene.instantiate()
    var angle := randf() * TAU
    var radius := randf() * FORMATION_RADIUS
    unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)
    player_units.append(unit)
    add_child(unit)
```

**Gain Units:**
- Opened barrels: +10 to +50 units
- Positive gates: +value units
- Multipliers (future): Multiply gains by 2-5×

**Lose Units:**
- Enemy collision: min(player_count, enemy_count) destroyed
- Unopened barrel: -value units
- Negative gates: -value units

**Game Over:** All units destroyed (0 remaining)

### Enemy Groups

**Properties:**
```gdscript
# scripts/enemy_group_2d.gd
const FORMATION_RADIUS := 40.0  # Pixels (doubled for 32×32 units)
const CHASE_SPEED := 100.0

var enemy_units: Array[Sprite2D] = []

func spawn_enemy_units(count: int) -> void:
    for i in count:
        var unit := enemy_unit_scene.instantiate()
        var angle := randf() * TAU
        var radius := randf() * FORMATION_RADIUS
        unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)
        enemy_units.append(unit)
        add_child(unit)
```

**Collision Resolution:**
```gdscript
func handle_collision(player_manager: PlayerManager) -> void:
    var damage := mini(player_manager.player_units.size(), enemy_units.size())

    for i in damage:
        player_manager.remove_player_unit()
        remove_enemy_unit()

    if enemy_units.size() <= 0:
        queue_free()
```

### Sprite Sizes

| Object | Source Size | Scale | Displayed Size |
|--------|-------------|-------|----------------|
| Player units | 32×32 | 1.0× | 32×32 |
| Enemy units | 32×32 | 1.0× | 32×32 |
| Projectiles | 16×16 | 0.5× | 8×8 |
| Barrels | 64×64 | 1.0× | 64×64 |
| Gates | 64×64 | 1.0× | 64×64 |
| Ground tiles | 128×128 | 0.25× | 32×32 |
| Grass tiles | 16×16 | 2.0× | 32×32 |
| Tree borders | 16×16 | 2.0× | 32×32 |

---

## Collectible Systems

### Barrels (Shoot-to-Open)

**Multi-Shot System:**

1. **Unopened State:**
   - Shows value on top (e.g., "15")
   - Shows bullets remaining as yellow text (e.g., "2")
   - Collision **damages** player (lose barrel's value in units)

2. **Opened State:**
   - Bullets counter reaches 0
   - Green "+15" label
   - Green sprite tint
   - Collision **rewards** player with units

**Implementation:**
```gdscript
# scripts/barrel_2d.gd
const SCROLL_SPEED := 120.0
@export var value := 15
var bullets_required := 1
var bullets_remaining := 1
var is_open := false

func calculate_bullets_needed(barrel_value: int) -> int:
    return max(1, barrel_value / 10)  # 1-10: 1 bullet, 11-20: 2 bullets, etc.

func on_projectile_hit() -> void:
    if not is_open:
        bullets_remaining -= 1
        if bullets_remaining <= 0:
            is_open = true
        update_display()

func _on_body_entered(body: Node2D) -> void:
    if body is PlayerManager:
        if is_open:
            body.add_units(value)  # Reward
        else:
            body.take_damage(value)  # Penalty!
        queue_free()
```

**Visual Design:**
- Size: 64×64 pixels
- Unopened: White sprite, white value, yellow bullet counter
- Opened: Green tint, green "+value", no counter

### Gates (Accumulation)

**Behavior:**
- Scroll down at 80 px/s (slower than barrels)
- Start at positive, zero, or negative value
- Shoot to increase value (+5 per hit)
- Walk through to collect current value
- Can be positive or negative at collection

**Implementation:**
```gdscript
# scripts/gate.gd
const VALUE_PER_HIT := 5
const SCROLL_SPEED := 80.0
@export var starting_value := 0
var current_value := 0

func on_projectile_hit() -> void:
    current_value += VALUE_PER_HIT
    update_display()

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
```

**Visual Design:**
- Size: 64×64 pixels (single sprite)
- Positive: Green tint, "+X" in green
- Negative: Red tint, "-X" in red
- Zero: White, "0" in white

**Gate Types:**
- Positive start: +10 to +20
- Zero start: 0 (must shoot for value)
- Negative start: -15 to -30 (shoot to bring positive or avoid)
- Unobtainable (future): Very negative, impossible to make positive

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

## Difficulty Progression

### Variables

**Speed Scaling:**
- Scroll speed: 80 → 100 → 120 px/s
- Enemy chase: 100 → 130 → 160 px/s
- Faster = less reaction time

**Enemy Density:**
- Early: 10-20 units per group, sparse
- Mid: 30-50 units, moderate density
- Late: 60-100 units, high density

**Resource Balance:**
- Early: Many positive barrels, positive gates
- Mid: Mix of zero/negative gates
- Late: Mostly negative gates, sparse barrels, unobtainable traps

### Planned Features (Week 3+)

**Multiplier Zones:**
- Floor areas that multiply next collection
- x2 (common), x3 (uncommon), x5 (rare)
- Can multiply negative values (risk!)

**Unobtainable Gates:**
- Start very negative (e.g., -100)
- Impossible to make positive
- Must recognize and avoid

**Particle Effects:**
- Collision bursts
- Barrel opening
- Unit destruction

**Sound Effects:**
- Collision impact
- Barrel opening
- Projectile firing
- Gate collection

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

**Document Version:** 6.0
**Last Updated:** 2024-12-10
**Status:** Pixellab asset migration complete, Week 2 features implemented
**Next:** Week 3 - Multipliers, difficulty scaling, effects, sound
