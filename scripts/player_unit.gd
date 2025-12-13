extends Area2D
class_name PlayerUnit

# Visual configuration
const UNIT_SCALE := 2.0  # Native size (32x32)

# Collision configuration
const COLLISION_RADIUS := 24.0

# Death animation
var is_dying := false
const DEATH_DURATION := 0.2
var death_timer := 0.0

# Manager reference (set by parent)
var manager: PlayerManager

# Node references
@onready var sprite := $Sprite2D

func _ready() -> void:
	# Setup sprite
	sprite.texture = load("res://assets/pixellab/player.png")
	sprite.scale = Vector2(UNIT_SCALE, UNIT_SCALE)
	sprite.centered = true
	sprite.modulate = Color(0.5, 0.5, 1.0)  # Blue tint
	sprite.z_index = 1

	# Collision settings (starts disabled, activated by proximity)
	collision_layer = 4  # Player unit layer
	collision_mask = 8   # Enemy unit layer
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Connect collision signal
	area_entered.connect(_on_area_entered)

func set_collision_active(active: bool) -> void:
	"""Enable/disable collision monitoring based on proximity to enemies"""
	if not is_dying:
		set_deferred("monitoring", active)
		set_deferred("monitorable", active)

func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with enemy unit"""
	if is_dying:
		return

	if area is EnemyUnit and not area.is_dying:
		# Mutual destruction (1:1)
		area.die()
		die()

func die() -> void:
	"""Trigger death animation and particle effects"""
	if is_dying:
		return

	is_dying = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Notify manager
	if manager:
		manager.on_unit_died(self)

	# Spawn particles
	spawn_death_particles()

	# Start death animation
	death_timer = 0.0

func spawn_death_particles() -> void:
	"""Create 4 particle sprites that scatter outward"""
	for i in 4:
		var particle := Sprite2D.new()
		particle.texture = sprite.texture
		particle.scale = Vector2(0.3, 0.3)  # Smaller than unit
		particle.modulate = sprite.modulate
		particle.global_position = global_position

		# Random velocity outward
		var angle := randf() * TAU
		var speed := 75.0 + randf() * 75.0  # 75-150 pixels/sec
		var velocity := Vector2(cos(angle), sin(angle)) * speed

		# Attach fade script
		var fade_script := load("res://scripts/fade_particle.gd")
		if fade_script:
			particle.set_script(fade_script)
			particle.set("velocity", velocity)
			particle.set("fade_duration", 0.3)

		# Add to parent (manager)
		if get_parent():
			get_parent().add_child(particle)

func _process(delta: float) -> void:
	if is_dying:
		death_timer += delta
		var progress := death_timer / DEATH_DURATION

		# Fade out
		sprite.modulate.a = 1.0 - progress

		# Scale up slightly (pop effect)
		sprite.scale = Vector2.ONE * UNIT_SCALE * (1.0 + progress * 0.5)

		# Lower z-index so dying units don't obscure living ones
		sprite.z_index = 0

		# Cleanup when animation complete
		if death_timer >= DEATH_DURATION:
			queue_free()
