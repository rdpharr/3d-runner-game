extends CharacterBody3D
class_name PlayerRunner

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

# Node references
@onready var model := $character
@onready var animation := $character/AnimationPlayer

func _ready() -> void:
	add_to_group("player")
	unit_count = starting_units
	unit_count_changed.emit(unit_count)

	# Start walk animation
	if animation:
		animation.play("walk")

func _physics_process(_delta: float) -> void:
	# Player is STATIONARY - doesn't move in Z
	velocity.z = 0

	# Horizontal mouse following
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size := get_viewport().get_visible_rect().size

	# Map mouse X (0 to screen width) to game X (-3 to +3)
	var normalized_x := (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
	var target_x := normalized_x * (PLAYABLE_WIDTH / 2.0)
	target_x = clamp(target_x, -PLAYABLE_WIDTH / 2, PLAYABLE_WIDTH / 2)

	# Smooth horizontal movement
	position.x = lerp(position.x, target_x, MOVEMENT_SMOOTHING)

	# Apply movement
	move_and_slide()

	# Rotate model to face forward
	if model:
		model.rotation.y = 0  # Always face forward (positive Z)

func take_damage(amount: int) -> void:
	unit_count -= amount
	unit_count_changed.emit(unit_count)

	if unit_count <= 0:
		unit_count = 0
		game_over.emit()
		# Stop movement but don't destroy player
		set_physics_process(false)

func add_units(amount: int) -> void:
	unit_count += amount
	unit_count_changed.emit(unit_count)
