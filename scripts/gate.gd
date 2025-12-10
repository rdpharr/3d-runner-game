extends Area2D
class_name Gate

# Movement configuration
const VALUE_PER_HIT := 5
const SCROLL_SPEED := 80.0  # Slower than barrels
const DESPAWN_Y := 700.0

# Gate properties
@export var starting_value := 0  # Can be negative!
var current_value := 0

# Visual references
@onready var value_label := $ValueLabel
@onready var sprite_container := $Sprite2D

func _ready() -> void:
	current_value = starting_value
	update_display()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Scroll down
	position.y += SCROLL_SPEED * delta

	# Despawn if off-screen
	if position.y > DESPAWN_Y:
		queue_free()

func on_projectile_hit() -> void:
	"""Called by Projectile when hit"""
	current_value += VALUE_PER_HIT
	update_display()

func update_display() -> void:
	var tint_color: Color

	if current_value > 0:
		value_label.text = "+" + str(current_value)
		value_label.modulate = Color.GREEN
		tint_color = Color(0.8, 1.0, 0.8)
	elif current_value < 0:
		value_label.text = str(current_value)
		value_label.modulate = Color.RED
		tint_color = Color(1.0, 0.8, 0.8)
	else:
		value_label.text = "0"
		value_label.modulate = Color.WHITE
		tint_color = Color.WHITE

	# Apply tint to all sprite children
	for child in sprite_container.get_children():
		if child is Sprite2D:
			child.modulate = tint_color

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerManager:
		if current_value > 0:
			body.add_units(current_value)
		elif current_value < 0:
			body.take_damage(abs(current_value))
		queue_free()
