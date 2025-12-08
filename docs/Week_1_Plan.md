# Week 1 Implementation Plan - With Kenney Starter Kit + Tower Defense Kit

## Asset Setup (15 min)
**Install Kenney's Starter Kit 3D Platformer from Godot Asset Library:**
1. Open Godot project
2. Click "AssetLib" tab (top of editor)
3. Search "Starter Kit 3D Platformer"
4. Download and install to project
5. Godot will import character, coins, and platformer assets

**Asset Mapping:**
- **Player:** Character from Starter Kit (has animations + controller)
- **Enemies:** UFO models from Tower Defense Kit (enemy-ufo-a/b/c.glb)
- **Collectibles:** Coins from Starter Kit OR crystals from Tower Defense (detail-crystal.glb)
- **Ground:** Tiles from Tower Defense Kit (tile.glb)

---

## Phase 1: Environment Foundation (30 min)
**Create main.tscn:**
- Node3D root named "Main"
- WorldEnvironment with default sky
- DirectionalLight3D at rotation (-45, -30, 0)
- **Ground:** Use tile.glb from Tower Defense, repeated to create runway
  - Multiple MeshInstance3D nodes in a line (Z: 0, 10, 20, 30... 100)
  - Each with StaticBody3D child → CollisionShape3D (BoxShape3D)
- Camera3D: position (0, 10, -5), rotation (-45, 0, 0)

---

## Phase 2: Player Character (45 min)
**Create player.tscn using Starter Kit character:**
1. Scene → New Scene → 3D Scene
2. Change root to CharacterBody3D, rename "Player"
3. Instance Starter Kit character as child (from addons folder after install)
4. Add CollisionShape3D (CapsuleShape3D matching character height)
5. Camera3D as child: position (0, 10, -5), rotation (-45, 0, 0)
6. Save as scenes/player.tscn

**Create scripts/player.gd:**
```gdscript
extends CharacterBody3D
class_name Player

# Movement configuration
const FORWARD_SPEED := 5.0
const PLAYABLE_WIDTH := 6.0
const MOVEMENT_SMOOTHING := 0.2

# Unit system
@export var starting_units := 15
var unit_count := starting_units

# Signals
signal unit_count_changed(new_count: int)
signal game_over

func _ready() -> void:
    add_to_group("player")
    unit_count = starting_units
    unit_count_changed.emit(unit_count)

func _physics_process(delta: float) -> void:
    # Auto-forward movement
    velocity.z = FORWARD_SPEED

    # Horizontal mouse following
    var mouse_pos := get_viewport().get_mouse_position()
    var viewport_size := get_viewport().get_visible_rect().size
    var normalized_x := (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
    var target_x := normalized_x * (PLAYABLE_WIDTH / 2.0)
    target_x = clamp(target_x, -PLAYABLE_WIDTH/2, PLAYABLE_WIDTH/2)

    position.x = lerp(position.x, target_x, MOVEMENT_SMOOTHING)
    move_and_slide()

func take_damage(amount: int) -> void:
    unit_count -= amount
    unit_count_changed.emit(unit_count)
    if unit_count <= 0:
        unit_count = 0
        game_over.emit()
        set_physics_process(false)

func add_units(amount: int) -> void:
    unit_count += amount
    unit_count_changed.emit(unit_count)
```

---

## Phase 3: Enemy System (45 min)
**Create scenes/enemies/enemy_basic.tscn:**
- Root: Area3D named "EnemyBasic"
- MeshInstance3D: Load `res://assets/models/enemy-ufo-a.glb`
- CollisionShape3D: SphereShape3D (radius ~1.5 to match UFO)
- Label3D: position (0, 2, 0), billboard enabled, text "20"

**Create scripts/enemy.gd:**
```gdscript
extends Area3D
class_name Enemy

const MOVE_SPEED := 3.0
const DESPAWN_DISTANCE := 5.0

@export var unit_count := 20
@onready var label := $Label3D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    update_display()

func _physics_process(delta: float) -> void:
    position.z -= MOVE_SPEED * delta
    var player := get_tree().get_first_node_in_group("player")
    if player and position.z < player.position.z - DESPAWN_DISTANCE:
        queue_free()

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player") and body is Player:
        handle_collision(body)

func handle_collision(player: Player) -> void:
    var damage := mini(player.unit_count, unit_count)
    player.take_damage(damage)
    unit_count -= damage
    if unit_count <= 0:
        queue_free()
    else:
        update_display()

func update_display() -> void:
    if label:
        label.text = str(unit_count)
```

---

## Phase 4: Simple Barrel Collection (30 min)
**Option A - Use Starter Kit coins OR Option B - Use Tower Defense crystals**

**Create scenes/collectibles/barrel_simple.tscn:**
- Root: Area3D named "BarrelSimple"
- MeshInstance3D: `res://assets/models/detail-crystal.glb` OR use Starter Kit coin
- CollisionShape3D: SphereShape3D (radius ~0.5)
- Label3D: position (0, 1.5, 0), text "+15", green color

**Create scripts/barrel_simple.gd:**
```gdscript
extends Area3D
class_name BarrelSimple

const MOVE_SPEED := 3.0
const DESPAWN_DISTANCE := 5.0

@export var value := 15
@onready var label := $Label3D

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    update_display()

func _physics_process(delta: float) -> void:
    position.z -= MOVE_SPEED * delta
    var player := get_tree().get_first_node_in_group("player")
    if player and position.z < player.position.z - DESPAWN_DISTANCE:
        queue_free()

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("player") and body is Player:
        collect(body)

func collect(player: Player) -> void:
    player.add_units(value)
    queue_free()

func update_display() -> void:
    if label:
        label.text = "+" + str(value)
        label.modulate = Color.GREEN
```

---

## Phase 5: UI System (30 min)
**Create scenes/ui.tscn:**
- CanvasLayer root named "UI"
- MarginContainer (anchors: top-right, margins: 20px)
  - VBoxContainer
    - Label "UnitCountLabel" (font size 48, align right, text "Units: 15")
    - Label "GameOverLabel" (font size 64, text "GAME OVER", hidden, red color)

**Create scripts/ui.gd:**
```gdscript
extends CanvasLayer
class_name GameUI

@onready var unit_label := $MarginContainer/VBoxContainer/UnitCountLabel
@onready var game_over_label := $MarginContainer/VBoxContainer/GameOverLabel

func _ready() -> void:
    var player := get_tree().get_first_node_in_group("player")
    if player:
        player.unit_count_changed.connect(_on_unit_count_changed)
        player.game_over.connect(_on_game_over)
        _on_unit_count_changed(player.unit_count)

func _on_unit_count_changed(new_count: int) -> void:
    unit_label.text = "Units: " + str(new_count)

func _on_game_over() -> void:
    game_over_label.visible = true
```

---

## Phase 6: Level Setup (30 min)
**Create scripts/spawners/test_spawner.gd:**
```gdscript
extends Node3D
class_name TestSpawner

@export var enemy_scene: PackedScene
@export var barrel_scene: PackedScene

func _ready() -> void:
    spawn_test_level()

func spawn_test_level() -> void:
    # Enemy patterns
    spawn_enemy(Vector3(-2, 1, 20), 20)
    spawn_enemy(Vector3(2, 1, 25), 15)
    spawn_enemy(Vector3(0, 1, 35), 30)

    # Collectibles
    spawn_barrel(Vector3(-1, 0.5, 22), 15)
    spawn_barrel(Vector3(1, 0.5, 30), 20)
    spawn_barrel(Vector3(0, 0.5, 40), 15)

func spawn_enemy(pos: Vector3, units: int) -> void:
    if enemy_scene:
        var enemy := enemy_scene.instantiate()
        enemy.position = pos
        enemy.unit_count = units
        add_child(enemy)

func spawn_barrel(pos: Vector3, val: int) -> void:
    if barrel_scene:
        var barrel := barrel_scene.instantiate()
        barrel.position = pos
        barrel.value = val
        add_child(barrel)
```

**Integrate into main.tscn:**
1. Add Node3D child to Main, name "TestSpawner"
2. Attach test_spawner.gd script
3. Inspector: Link enemy_basic.tscn and barrel_simple.tscn
4. Add Player instance to Main at (0, 0.5, 0)
5. Add UI instance to Main

---

## Phase 7: Testing (30 min)
**Test checklist:**
- Player auto-advances forward
- Mouse controls horizontal movement (stays in bounds)
- Enemies move toward player
- Collision reduces both counts correctly
- Barrels add units when collected
- UI updates in real-time
- Game over at 0 units
- No console errors

---

## Phase 8: Git Commit (15 min)
```bash
git add .
git commit -m "Session 1: Week 1 foundation with Kenney Starter Kit

- Installed Kenney Starter Kit 3D Platformer from Asset Library
- Created player with Starter Kit character + mouse movement
- Enemies using Tower Defense UFO models
- Collectibles using crystals/coins
- UI with unit counter and game over screen
- Test level with spawned objects

Tests passing: All Week 1 goals complete

Time: ~3-4 hours"
git push origin master
```

---

## Summary
**Files Created:** 5 scenes, 5 scripts
**Assets Used:** Kenney Starter Kit (player/coins) + Tower Defense Kit (enemies/tiles/crystals)
**Time:** 3-4 hours total
