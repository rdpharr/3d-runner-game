extends Area2D
class_name Barrel

# Movement configuration
const SCROLL_SPEED := 120.0  # Pixels per second
const DESPAWN_Y := 700.0  # Bottom of screen + buffer

# Collectible properties
@export var value := 15
var bullets_required := 1
var bullets_remaining := 1
var is_open := false

# Visual references
@onready var sprite := $Sprite2D
@onready var value_label := $ValueLabel
@onready var bullet_label := $BulletLabel

func _ready() -> void:
	# Calculate bullets needed based on value
	bullets_required = calculate_bullets_needed(value)
	bullets_remaining = bullets_required
	update_display()
	body_entered.connect(_on_body_entered)

func calculate_bullets_needed(barrel_value: int) -> int:
	# 5x more bullets required: 1-2: 1 bullet, 3-4: 2 bullets, etc.
	return max(1, barrel_value / 2)

func _physics_process(delta: float) -> void:
	# Scroll straight down (positive Y)
	position.y += SCROLL_SPEED * delta

	# Despawn if scrolled off bottom of screen
	if position.y > DESPAWN_Y:
		queue_free()

func on_projectile_hit() -> void:
	"""Called by Projectile when hit"""
	if is_open:
		return  # Already opened, ignore further hits

	bullets_remaining -= 1
	if bullets_remaining <= 0:
		is_open = true
		bullets_remaining = 0
		give_reward()  # Immediately reward player when shot open

	update_display()

func give_reward() -> void:
	"""Give units to player immediately when barrel is shot open"""
	var player := get_tree().get_first_node_in_group("player") as PlayerManager
	if player:
		player.add_units(value)
	queue_free()  # Destroy barrel after giving reward

func update_display() -> void:
	if is_open:
		# Show reward value in green
		value_label.text = "+" + str(value)
		value_label.modulate = Color.GREEN
		bullet_label.text = ""
		sprite.modulate = Color(0.8, 1.0, 0.8)  # Green tint
	else:
		# Show value and bullets needed
		value_label.text = str(value)
		value_label.modulate = Color.WHITE
		bullet_label.text = str(bullets_remaining)
		bullet_label.modulate = Color.YELLOW

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerManager:
		# Collision just destroys barrel (no reward/penalty)
		# Player must shoot barrel open to get reward
		queue_free()
