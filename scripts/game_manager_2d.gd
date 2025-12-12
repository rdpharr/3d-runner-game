extends Node2D

# Scene references
@export var player_manager_scene: PackedScene
@export var enemy_group_scene: PackedScene
@export var barrel_scene: PackedScene
@export var gate_scene: PackedScene
@export var boss_scene: PackedScene

# Configuration
const VIEWPORT_WIDTH := 800.0
const VIEWPORT_HEIGHT := 600.0

var player: PlayerManager
var camera: Camera2D
var background: ScrollingBackground
var active_boss = null  # Boss reference (dynamically typed)

func _ready() -> void:
	setup_camera()
	setup_background()
	spawn_player()
	setup_spawn_manager()
	setup_hud()

func setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)

func setup_background() -> void:
	background = ScrollingBackground.new()
	background.name = "Background"
	add_child(background)

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

func setup_spawn_manager() -> void:
	"""Setup automatic spawning system for 2-minute levels"""
	# Load scenes if not assigned
	if not enemy_group_scene:
		enemy_group_scene = load("res://scenes/enemies/enemy_group.tscn")
	if not barrel_scene:
		barrel_scene = load("res://scenes/collectibles/barrel.tscn")
	if not gate_scene:
		gate_scene = load("res://scenes/collectibles/gate.tscn")

	# Create and configure spawn manager
	var spawn_mgr := SpawnManager.new()
	spawn_mgr.name = "SpawnManager"
	spawn_mgr.game_manager = self
	spawn_mgr.player_manager = player
	spawn_mgr.level_complete.connect(_on_level_complete)
	spawn_mgr.boss_incoming.connect(_on_boss_incoming)  # Connect boss spawn
	add_child(spawn_mgr)

	print("SpawnManager initialized - 2 minute level started")

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
	# Create HUD layer (empty until game over)
	var canvas_layer := CanvasLayer.new()
	canvas_layer.name = "HUD"

	var hud := Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Load HUD script
	var hud_script := load("res://scripts/hud.gd")
	if hud_script:
		hud.set_script(hud_script)

	# No unit counter - now shown as floating label on player group
	# Game over message will be created by hud.gd when needed

	canvas_layer.add_child(hud)
	add_child(canvas_layer)

func _on_boss_incoming() -> void:
	"""Called when timer hits 120s - spawn boss with slowdown effect"""
	print("Boss incoming - applying slowdown effect...")

	# Dramatic slowdown to 50% speed
	Engine.time_scale = 0.5

	# Wait 1 second (in scaled time = 2 real seconds)
	await get_tree().create_timer(1.0).timeout

	# Gradually restore speed over 1 second
	var tween := create_tween()
	tween.tween_property(Engine, "time_scale", 1.0, 1.0)

	# Spawn boss after speed restored
	await tween.finished
	spawn_boss()

func spawn_boss() -> void:
	"""Instantiate and spawn the boss at top center"""
	# Load boss scene if not assigned
	if not boss_scene:
		boss_scene = load("res://scenes/enemies/boss.tscn")

	var boss = boss_scene.instantiate()  # Boss instance
	boss.position = Vector2(0, -100)  # Top center
	boss.boss_defeated.connect(_on_boss_defeated)
	active_boss = boss
	add_child(boss)

	print("Boss spawned at top of screen!")

func _on_boss_defeated() -> void:
	"""Called when boss is defeated"""
	print("BOSS DEFEATED!")
	active_boss = null
	# SpawnManager will detect boss is gone and emit level_complete

func _on_level_complete() -> void:
	"""Called when 2-minute level completes"""
	# Only completes if boss is defeated
	if active_boss == null:
		print("Level Complete! Victory!")
		# TODO: Show victory screen, transition to next level
	else:
		print("Boss still active - waiting for defeat...")
