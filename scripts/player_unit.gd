extends Sprite2D
class_name PlayerUnit

# Visual configuration
const UNIT_SCALE := 1.0  # Native size (32x32)

func _ready() -> void:
	# Load texture from pixellab pack
	texture = load("res://assets/pixellab/player.png")
	scale = Vector2(UNIT_SCALE, UNIT_SCALE)

	# Center origin
	centered = true

	# Blue tint for player team
	modulate = Color(0.5, 0.5, 1.0)

	# Set rendering layer (above background, below UI)
	z_index = 1
