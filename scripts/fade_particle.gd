extends Sprite2D

# Particle configuration
var velocity := Vector2.ZERO
var fade_duration := 0.3
var lifetime := 0.0

func _ready() -> void:
	# Start with full opacity
	modulate.a = 1.0

func _process(delta: float) -> void:
	# Move by velocity
	position += velocity * delta

	# Fade out over time
	lifetime += delta
	var progress := lifetime / fade_duration
	modulate.a = 1.0 - progress

	# Cleanup when fully faded
	if lifetime >= fade_duration:
		queue_free()
