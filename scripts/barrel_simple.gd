extends Area3D
class_name BarrelSimple

# Configuration
const MOVE_SPEED := 3.0
const DESPAWN_DISTANCE := 50.0  # Increased so they don't despawn immediately

@export var value := 15

# Node references
@onready var label := $Label3D

func _ready() -> void:
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
		collect(body)

func collect(player: PlayerRunner) -> void:
	player.add_units(value)
	queue_free()

func update_display() -> void:
	if label:
		label.text = "+" + str(value)
		label.modulate = Color.GREEN
