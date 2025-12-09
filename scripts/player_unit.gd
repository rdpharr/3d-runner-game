extends Sprite2D
class_name PlayerUnit

# Visual configuration
const UNIT_SCALE := 2.0  # Double size (8x8 -> 16x16)

func _ready() -> void:
	# Load texture from micro-roguelike pack
	texture = load("res://assets/kenney_micro-roguelike/Tiles/Colored/tile_0004.png")
	scale = Vector2(UNIT_SCALE, UNIT_SCALE)

	# Center origin
	centered = true

	# Blue tint for player team
	modulate = Color(0.5, 0.5, 1.0)

	# Set rendering layer (above background, below UI)
	z_index = 1
