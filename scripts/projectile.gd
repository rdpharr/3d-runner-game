extends Area2D
class_name Projectile

# Movement configuration
const SPEED := 200.0  # Pixels per second (upward - negative Y)
const MAX_DISTANCE := 800.0  # Despawn after traveling this far

var distance_traveled := 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = true
	monitorable = true

func _physics_process(delta: float) -> void:
	# Move upward (negative Y)
	var movement := SPEED * delta
	position.y -= movement
	distance_traveled += movement

	# Despawn if off-screen or max distance reached
	if position.y < -50 or distance_traveled > MAX_DISTANCE:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Check if the area itself has the method (Barrel, Gate)
	if area.has_method("on_projectile_hit"):
		area.on_projectile_hit()
		queue_free()
	# Otherwise check parent (EnemyGroup with Area2D child)
	elif area.get_parent() and area.get_parent().has_method("on_projectile_hit"):
		area.get_parent().on_projectile_hit()
		queue_free()
