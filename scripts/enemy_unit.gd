extends Sprite2D
class_name EnemyUnit

# Visual configuration
const UNIT_SCALE := 2.0  # Double size (8x8 -> 16x16)

func _ready() -> void:
	# Load texture from micro-roguelike pack
	texture = load("res://assets/kenney_micro-roguelike/Tiles/Colored/tile_0010.png")
	scale = Vector2(UNIT_SCALE, UNIT_SCALE)

	# Center origin
	centered = true

	# Red tint for enemy team
	modulate = Color(1.0, 0.5, 0.5)

	# Set rendering layer
	z_index = 2
