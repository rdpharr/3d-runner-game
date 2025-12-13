extends Node2D
class_name ScrollingBackground

# Configuration
const SCROLL_SPEED := 200.0  
const TILE_SIZE := 58.0  # 32 * 1.8 scaling (rounded from 57.6)
const STRIP_HEIGHT := 58.0  # 32 * 1.8 scaling
const SPAWN_Y := -180.0  # Above viewport (-100 * 1.8)
const DESPAWN_Y := 2580.0  # Below viewport (adjust for 2400 height)
const VIEWPORT_WIDTH := 1080.0  # Portrait width
const PLAYABLE_WIDTH := 1080.0  # Full width in portrait

# Tile assets
var grass_texture: Texture2D
var ground_texture: Texture2D
var left_wall_texture: Texture2D
var right_wall_texture: Texture2D

# Active strips
var tile_strips: Array[Node2D] = []
var next_spawn_y := SPAWN_Y

func _ready() -> void:
	# Load tile textures from pixellab pack
	grass_texture = load("res://assets/pixellab/grass.png")
	ground_texture = load("res://assets/pixellab/ground.png")
	left_wall_texture = load("res://assets/pixellab/tree.png")
	right_wall_texture = load("res://assets/pixellab/tree.png")

	# Pre-spawn strips to fill viewport
	while next_spawn_y < DESPAWN_Y + STRIP_HEIGHT:
		spawn_strip(next_spawn_y)
		next_spawn_y += STRIP_HEIGHT

func _physics_process(delta: float) -> void:
	# Scroll all strips downward
	for strip in tile_strips:
		strip.position.y += SCROLL_SPEED * delta

	# Despawn strips that scrolled off-screen
	var i := 0
	while i < tile_strips.size():
		if tile_strips[i].position.y > DESPAWN_Y:
			tile_strips[i].queue_free()
			tile_strips.remove_at(i)
		else:
			i += 1

	# Spawn new strips at top
	if tile_strips.size() > 0:
		var topmost_strip := tile_strips[0]
		if topmost_strip.position.y > SPAWN_Y + STRIP_HEIGHT:
			spawn_strip(SPAWN_Y)

func spawn_strip(y_position: float) -> void:
	var strip := Node2D.new()
	strip.position.y = y_position
	strip.z_index = -100  # Behind all gameplay objects

	# Calculate tile positions
	var start_x := -VIEWPORT_WIDTH / 2.0
	var left_tree_x := -(PLAYABLE_WIDTH / 2.0) - 58.0  # -32 * 1.8
	var right_tree_x := (PLAYABLE_WIDTH / 2.0) + 58.0  # +32 * 1.8
	var playable_left := -(PLAYABLE_WIDTH / 2.0)
	var playable_right := (PLAYABLE_WIDTH / 2.0)

	# Spawn tiles across viewport
	var x_pos := start_x
	while x_pos < VIEWPORT_WIDTH / 2.0:
		var tile := Sprite2D.new()
		tile.position.x = x_pos

		# Use ground texture in playable area, grass outside
		if x_pos >= playable_left and x_pos <= playable_right:
			tile.texture = ground_texture
			tile.scale = Vector2(0.453, 0.453)  # 128x128 -> 58x58 (0.25 * 1.8)
		else:
			tile.texture = grass_texture
			tile.scale = Vector2(3.6, 3.6)  # 16x16 -> 58x58 (2.0 * 1.8)

		strip.add_child(tile)
		x_pos += TILE_SIZE

	# Spawn left wall tile
	var left_wall := Sprite2D.new()
	left_wall.texture = left_wall_texture
	left_wall.scale = Vector2(3.6, 3.6)  # 2.0 * 1.8 scaling
	left_wall.position.x = -(PLAYABLE_WIDTH / 2.0) - 58.0  # -32 * 1.8
	strip.add_child(left_wall)

	# Spawn right wall tile
	var right_wall := Sprite2D.new()
	right_wall.texture = right_wall_texture
	right_wall.scale = Vector2(3.6, 3.6)  # 2.0 * 1.8 scaling
	right_wall.position.x = (PLAYABLE_WIDTH / 2.0) + 58.0  # +32 * 1.8
	strip.add_child(right_wall)

	tile_strips.insert(0, strip)  # Insert at front (topmost)
	add_child(strip)
