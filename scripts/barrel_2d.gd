extends Area2D
class_name Barrel

# Movement configuration
const SCROLL_SPEED := 120.0  # Pixels per second
const DESPAWN_Y := 700.0  # Bottom of screen + buffer

# Collectible properties
@export var value := 15

# Visual references
@onready var sprite := $Sprite2D
@onready var label := $Label

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	update_display()

func _physics_process(delta: float) -> void:
	# Scroll straight down (positive Y)
	position.y += SCROLL_SPEED * delta

	# Despawn if scrolled off bottom of screen
	if position.y > DESPAWN_Y:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerManager:
		collect(body)

func collect(player: PlayerManager) -> void:
	player.add_units(value)
	queue_free()

func update_display() -> void:
	if label:
		label.text = "+" + str(value)
		label.modulate = Color.GREEN
