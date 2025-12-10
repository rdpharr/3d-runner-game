extends Sprite2D
class_name EnemyUnit

# Visual configuration
const UNIT_SCALE := 1.0  # Native size (32x32)

func _ready() -> void:
	# Load texture from pixellab pack
	texture = load("res://assets/pixellab/enemy.png")
	scale = Vector2(UNIT_SCALE, UNIT_SCALE)

	# Center origin
	centered = true

	# Red tint for enemy team
	modulate = Color(1.0, 0.5, 0.5)

	# Set rendering layer
	z_index = 2
