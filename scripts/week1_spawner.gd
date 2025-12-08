extends Node3D

# Scene references
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var barrel_scene: PackedScene

# Configuration
const TRACK_LENGTH := 50.0
const PLAYABLE_WIDTH := 6.0

var camera: Camera3D
var player: Node3D

func _ready() -> void:
	setup_environment()
	spawn_player()
	spawn_ground()
	spawn_test_objects()
	setup_camera()
	setup_hud()

func _process(_delta: float) -> void:
	# Update camera to follow player
	if camera and player:
		# Camera slightly behind player (small positive Z offset) and above
		# Looking toward negative Z (so player at bottom, enemies at top)
		camera.position = player.position + Vector3(0, 12, 5)
		# Face negative Z direction with tilt down
		camera.rotation_degrees = Vector3(-45, 180, 0)

func setup_environment() -> void:
	# Add sun
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform = Transform3D.IDENTITY.rotated(Vector3.RIGHT, -0.7)
	sun.shadow_enabled = true
	add_child(sun)

	# Add sky/environment
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	world_env.environment = env
	add_child(world_env)

func spawn_player() -> void:
	# Load player scene if not assigned
	if not player_scene:
		player_scene = load("res://scenes/player.tscn")

	player = player_scene.instantiate()
	player.position = Vector3(0, 1, 0)  # Start at origin, lower to ground
	player.scale = Vector3(0.2, 0.2, 0.2)  # Scale down to 20%
	add_child(player)

	# Add a visible debug marker to player (matches collision radius)
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.BLUE
	mat.emission_enabled = true
	mat.emission = Color.BLUE
	mat.emission_energy = 2.0
	marker.material_override = mat
	marker.position = Vector3(0, 0.4, 0)
	marker.name = "DebugMarker"
	player.add_child(marker)

func setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	# Initial position - will be updated in _process to follow player
	camera.position = Vector3(0, 12, 5)
	add_child(camera)

func spawn_ground() -> void:
	# Create a long ground plane for the track
	var ground := StaticBody3D.new()
	ground.name = "Ground"

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(PLAYABLE_WIDTH + 2, 0.5, TRACK_LENGTH)
	mesh_instance.mesh = box_mesh

	# Set material color
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.3)  # Green
	mesh_instance.material_override = material

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(PLAYABLE_WIDTH + 2, 0.5, TRACK_LENGTH)
	collision.shape = shape

	ground.add_child(mesh_instance)
	ground.add_child(collision)
	# Center ground at Z=0, extending equally in both directions
	ground.position = Vector3(0, 0, 0)

	add_child(ground)

func spawn_test_objects() -> void:
	# Load scenes if not assigned
	if not enemy_scene:
		enemy_scene = load("res://scenes/enemies/enemy_basic.tscn")
	if not barrel_scene:
		barrel_scene = load("res://scenes/collectibles/barrel_simple.tscn")

	# Spawn enemies at NEGATIVE Z (top of screen) moving toward positive Z (bottom)
	spawn_enemy(Vector3(-2, 1, -10), 10)
	spawn_enemy(Vector3(2, 1, -15), 15)
	spawn_enemy(Vector3(0, 1, -20), 20)
	spawn_enemy(Vector3(-1, 1, -25), 8)

	# Spawn barrels at NEGATIVE Z (top of screen) moving toward positive Z (bottom)
	spawn_barrel(Vector3(1, 1, -12), 10)
	spawn_barrel(Vector3(-1, 1, -18), 15)
	spawn_barrel(Vector3(2, 1, -23), 20)
	spawn_barrel(Vector3(0, 1, -30), 25)

func spawn_enemy(pos: Vector3, units: int) -> void:
	var enemy := enemy_scene.instantiate()
	enemy.position = pos
	enemy.unit_count = units
	enemy.scale = Vector3(0.2, 0.2, 0.2)  # Scale down to 20%
	add_child(enemy)

	# Add visible debug marker (matches collision radius)
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.emission_enabled = true
	mat.emission = Color.RED
	mat.emission_energy = 2.0
	marker.material_override = mat
	marker.position = Vector3(0, 0.3, 0)
	marker.name = "DebugMarker"
	enemy.add_child(marker)

func spawn_barrel(pos: Vector3, value: int) -> void:
	var barrel := barrel_scene.instantiate()
	barrel.position = pos
	barrel.value = value
	barrel.scale = Vector3(0.2, 0.2, 0.2)  # Scale down to 20%
	add_child(barrel)

	# Add visible debug marker (matches collision radius)
	var marker := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	marker.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.GREEN
	mat.emission_enabled = true
	mat.emission = Color.GREEN
	mat.emission_energy = 2.0
	marker.material_override = mat
	marker.position = Vector3(0, 0.3, 0)
	marker.name = "DebugMarker"
	barrel.add_child(marker)

func setup_hud() -> void:
	# Create HUD
	var hud := Control.new()
	hud.name = "HUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Load HUD script BEFORE adding children
	var hud_script := load("res://scripts/hud.gd")
	if hud_script:
		hud.set_script(hud_script)

	# Create unit display
	var unit_label := Label.new()
	unit_label.name = "Units"
	unit_label.position = Vector2(20, 20)
	unit_label.text = "15"
	unit_label.add_theme_font_size_override("font_size", 48)

	hud.add_child(unit_label)
	add_child(hud)
