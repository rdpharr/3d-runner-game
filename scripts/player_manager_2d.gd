extends CharacterBody2D
class_name PlayerManager

# Movement configuration
const PLAYABLE_WIDTH := 600.0  # World units (-300 to +300)
const PLAYER_Y_POSITION := 500.0  # Fixed at bottom of screen
const MOVEMENT_SMOOTHING := 0.2

# Physical unit system
@export var player_unit_scene: PackedScene
@export var starting_units := 15
var player_units: Array[Sprite2D] = []
const FORMATION_RADIUS := 30.0  # Pixels for circular swarm

# Signals
signal unit_count_changed(new_count: int)
signal game_over

func _ready() -> void:
	add_to_group("player")

	# Set fixed vertical position
	position.y = PLAYER_Y_POSITION

	# Spawn starting units
	for i in starting_units:
		spawn_player_unit()

	unit_count_changed.emit(player_units.size())

func _physics_process(_delta: float) -> void:
	# Player is stationary in Y (bottom of screen)
	velocity.y = 0

	# Horizontal mouse following
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size := get_viewport().get_visible_rect().size

	# Map mouse X (0 to screen width) to world X (-300 to +300)
	var normalized_x := (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
	var target_x := normalized_x * (PLAYABLE_WIDTH / 2.0)
	target_x = clamp(target_x, -PLAYABLE_WIDTH / 2.0, PLAYABLE_WIDTH / 2.0)

	# Smooth horizontal movement
	position.x = lerp(position.x, target_x, MOVEMENT_SMOOTHING)

	# Apply movement
	move_and_slide()

func spawn_player_unit() -> void:
	# Load unit scene if not set
	if not player_unit_scene:
		player_unit_scene = load("res://scenes/units/player_unit.tscn")

	var unit := player_unit_scene.instantiate() as Sprite2D

	# Position in tight circular formation around center
	var angle := randf() * TAU
	var radius := randf() * FORMATION_RADIUS
	unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)

	player_units.append(unit)
	add_child(unit)

func remove_player_unit() -> void:
	if player_units.size() > 0:
		var unit: Sprite2D = player_units.pop_back()
		unit.queue_free()
		unit_count_changed.emit(player_units.size())

		if player_units.size() <= 0:
			game_over.emit()
			set_physics_process(false)

func add_units(amount: int) -> void:
	for i in amount:
		spawn_player_unit()
	unit_count_changed.emit(player_units.size())

func take_damage(amount: int) -> void:
	for i in amount:
		remove_player_unit()
		if player_units.size() <= 0:
			break
