extends Area3D
class_name Enemy

# Configuration
const MOVE_SPEED := 3.0
const DESPAWN_DISTANCE := 50.0  # Increased so they don't despawn immediately

@export var unit_count := 20

# Node references
@onready var label := $Label3D

func _ready() -> void:
	add_to_group("enemy")
	body_entered.connect(_on_body_entered)
	update_display()

func _physics_process(delta: float) -> void:
	# Move from negative Z to positive Z (top to bottom of screen)
	position.z += MOVE_SPEED * delta

	# Despawn if moved past player (positive Z direction)
	var player := get_tree().get_first_node_in_group("player")
	if player and position.z > player.position.z + DESPAWN_DISTANCE:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body is PlayerRunner:
		handle_collision(body)

func handle_collision(player: PlayerRunner) -> void:
	# Both take damage equal to minimum of both counts
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
