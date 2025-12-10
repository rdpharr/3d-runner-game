extends Node2D

# Scene references
@export var player_manager_scene: PackedScene
@export var enemy_group_scene: PackedScene
@export var barrel_scene: PackedScene
@export var gate_scene: PackedScene

# Configuration
const VIEWPORT_WIDTH := 800.0
const VIEWPORT_HEIGHT := 600.0

var player: PlayerManager
var camera: Camera2D

func _ready() -> void:
	setup_camera()
	spawn_player()
	spawn_test_objects()
	setup_hud()

func setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)

func _process(_delta: float) -> void:
	# Camera stays fixed - player moves within viewport
	if camera:
		camera.position.x = 0
		camera.position.y = VIEWPORT_HEIGHT / 2.0  # Fixed at center

func spawn_player() -> void:
	# Load scene if not assigned
	if not player_manager_scene:
		player_manager_scene = load("res://scenes/player_manager.tscn")

	player = player_manager_scene.instantiate()
	player.position = Vector2(0, 500)  # Center X, bottom Y
	add_child(player)

func spawn_test_objects() -> void:
	# Load scenes if not assigned
	if not enemy_group_scene:
		enemy_group_scene = load("res://scenes/enemies/enemy_group.tscn")
	if not barrel_scene:
		barrel_scene = load("res://scenes/collectibles/barrel.tscn")
	if not gate_scene:
		gate_scene = load("res://scenes/collectibles/gate.tscn")

	# Spawn enemies at top of screen (negative Y, off-viewport)
	# They will chase player
	spawn_enemy(Vector2(-150, -100), 10)
	spawn_enemy(Vector2(150, -200), 15)
	spawn_enemy(Vector2(0, -300), 20)
	spawn_enemy(Vector2(-100, -400), 8)

	# Spawn barrels at top of screen
	# They will scroll straight down
	spawn_barrel(Vector2(100, -150), 10)
	spawn_barrel(Vector2(-100, -250), 15)
	spawn_barrel(Vector2(0, -350), 20)
	spawn_barrel(Vector2(150, -450), 25)

	# Spawn gates at top of screen
	# Test neutral, negative, and positive gates
	spawn_gate(Vector2(200, -300), 0)      # Neutral gate
	spawn_gate(Vector2(-200, -500), -15)   # Negative gate (trap!)
	spawn_gate(Vector2(100, -700), 10)     # Positive gate

func spawn_enemy(pos: Vector2, units: int) -> void:
	var enemy := enemy_group_scene.instantiate()
	enemy.position = pos
	enemy.unit_count = units
	add_child(enemy)

func spawn_barrel(pos: Vector2, val: int) -> void:
	var barrel := barrel_scene.instantiate()
	barrel.position = pos
	barrel.value = val
	add_child(barrel)

func spawn_gate(pos: Vector2, start_value: int) -> void:
	var gate := gate_scene.instantiate()
	gate.position = pos
	gate.starting_value = start_value
	add_child(gate)

func setup_hud() -> void:
	# Create HUD layer
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "HUD"

	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Load HUD script
	var hud_script := load("res://scripts/hud.gd")
	if hud_script:
		hud.set_script(hud_script)

	# Unit counter label
	var unit_label := Label.new()
	unit_label.name = "Units"
	unit_label.position = Vector2(20, 20)
	unit_label.text = "15"
	unit_label.add_theme_font_size_override("font_size", 48)

	hud.add_child(unit_label)
	canvas_layer.add_child(hud)
	add_child(canvas_layer)
