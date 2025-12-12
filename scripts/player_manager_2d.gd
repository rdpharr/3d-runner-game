extends CharacterBody2D
class_name PlayerManager

# Movement configuration
const PLAYABLE_WIDTH := 600.0  # World units (-300 to +300)
const PLAYER_Y_POSITION := 500.0  # Fixed at bottom of screen
const HORIZONTAL_SPEED := 80.0  # Pixels per second (matches scroll speed)

# Physical unit system
@export var player_unit_scene: PackedScene
@export var starting_units := 15
var player_units: Array[Area2D] = []  # Rendered units (max 200)
var total_unit_count := 0  # Total units including overflow (unlimited)
const FORMATION_RADIUS := 60.0  # Pixels for circular swarm (doubled for 2x larger units)
const MAX_PLAYER_UNITS := 200  # Memory management cap
const COLLISION_ACTIVATION_DISTANCE := 150.0  # Proximity for collision activation
const FORMATION_REFORM_SPEED := 0.5  # Speed at which units return to formation (0-1)

# Projectile system
const FIRE_RATE := 0.5  # Seconds between shots
const PROJECTILE_WIDTH := 8.0  # Pixels
const WAVE_DELAY := 0.1  # Seconds between waves
const MAX_PROJECTILES_MULTIPLIER := 5.0  # Max projectiles = 5 × (width / 8)
@export var projectile_scene: PackedScene
var fire_timer := 0.0
var pending_waves: Array[Array] = []  # Queue of projectile data arrays
var wave_timer := 0.0

# UI
var count_label: Label

# Signals
signal unit_count_changed(new_count: int)
signal game_over

func _ready() -> void:
	add_to_group("player")

	# Set fixed vertical position
	position.y = PLAYER_Y_POSITION

	# Spawn starting units
	for i in starting_units:
		spawn_player_unit()

	# Create floating count label
	count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.position = Vector2(0, -50)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 32)
	count_label.modulate = Color.WHITE
	count_label.z_index = 10
	add_child(count_label)

	total_unit_count = player_units.size()  # Initialize to match rendered
	update_count_label()
	unit_count_changed.emit(total_unit_count)

func _process(delta: float) -> void:
	# Auto-fire timer
	fire_timer += delta
	if fire_timer >= FIRE_RATE and player_units.size() > 0 and pending_waves.size() == 0:
		fire_projectiles()
		fire_timer = 0.0

	# Wave delay timer
	if pending_waves.size() > 0:
		wave_timer += delta
		if wave_timer >= WAVE_DELAY:
			fire_wave(pending_waves.pop_front())
			wave_timer = 0.0

	# Slowly reform units into circular formation
	update_formation(delta)

func _physics_process(delta: float) -> void:
	# Player is stationary in Y (bottom of screen)
	velocity.y = 0

	# Horizontal mouse following
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size := get_viewport().get_visible_rect().size

	# Map mouse X (0 to screen width) to world X (-300 to +300)
	var normalized_x := (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
	var target_x := normalized_x * (PLAYABLE_WIDTH / 2.0)
	target_x = clamp(target_x, -PLAYABLE_WIDTH / 2.0, PLAYABLE_WIDTH / 2.0)

	# Move toward target at fixed speed (matches scroll speed)
	position.x = move_toward(position.x, target_x, HORIZONTAL_SPEED * delta)

	# Apply movement
	move_and_slide()

	# Update unit collision states based on enemy proximity
	update_unit_collisions()

func spawn_player_unit() -> void:
	# Check cap before spawning
	if player_units.size() >= MAX_PLAYER_UNITS:
		return  # Silently refuse to spawn beyond cap

	# Load unit scene if not set
	if not player_unit_scene:
		player_unit_scene = load("res://scenes/units/player_unit.tscn")

	var unit := player_unit_scene.instantiate() as PlayerUnit  # Changed from Sprite2D

	# Set manager reference
	unit.manager = self

	# Position in tight circular formation around center
	var angle := randf() * TAU
	var radius := randf() * FORMATION_RADIUS
	unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)

	player_units.append(unit)
	call_deferred("add_child", unit)

	# Check if in combat - activate collision with deferred call
	var enemies := get_tree().get_nodes_in_group("enemy")
	var in_combat := false
	for enemy in enemies:
		if enemy is EnemyGroup and position.distance_to(enemy.position) < COLLISION_ACTIVATION_DISTANCE:
			in_combat = true
			break

	if in_combat and unit.has_method("set_collision_active"):
		unit.call_deferred("set_collision_active", true)

func remove_player_unit() -> void:
	# Always decrement total
	total_unit_count -= 1
	if total_unit_count < 0:
		total_unit_count = 0  # Safety clamp

	# Only remove physical unit if total is now below rendered cap
	# (This means we're eating into rendered units, not overflow)
	if total_unit_count < player_units.size():
		var unit: Area2D = player_units.pop_back()
		unit.queue_free()

	# Update display
	update_count_label()
	unit_count_changed.emit(total_unit_count)

	# Game over when total reaches 0
	if total_unit_count <= 0:
		game_over.emit()
		set_physics_process(false)

func on_unit_died(unit: PlayerUnit) -> void:
	"""Called by PlayerUnit when it dies from collision"""
	# Always decrement total
	total_unit_count -= 1
	if total_unit_count < 0:
		total_unit_count = 0  # Safety clamp

	# Remove from array
	var idx := player_units.find(unit)
	if idx >= 0:
		player_units.remove_at(idx)

	# If overflow exists (total > rendered), spawn replacement unit
	# This maintains visual density at cap
	if total_unit_count > player_units.size() and player_units.size() < MAX_PLAYER_UNITS:
		spawn_player_unit()

	# Update display
	update_count_label()
	unit_count_changed.emit(total_unit_count)

	# Game over when total reaches 0
	if total_unit_count <= 0:
		game_over.emit()
		set_physics_process(false)

func update_unit_collisions() -> void:
	"""Activate/deactivate unit collisions based on proximity to enemies"""
	var enemies := get_tree().get_nodes_in_group("enemy")
	var closest_distance := INF

	for enemy in enemies:
		if enemy is EnemyGroup:
			var dist := position.distance_to(enemy.position)
			closest_distance = min(closest_distance, dist)

	# Activate/deactivate unit collisions based on proximity
	var should_activate := closest_distance < COLLISION_ACTIVATION_DISTANCE
	for unit in player_units:
		if unit and unit.has_method("set_collision_active"):
			unit.set_collision_active(should_activate)

func add_units(amount: int) -> void:
	# Always add to total count (unlimited)
	total_unit_count += amount

	# Spawn physical units only up to rendered cap
	var units_to_spawn: int = min(amount, MAX_PLAYER_UNITS - player_units.size())
	for i in units_to_spawn:
		spawn_player_unit()

	# Always update (total always changes)
	update_count_label()
	unit_count_changed.emit(total_unit_count)

func take_damage(amount: int) -> void:
	for i in amount:
		remove_player_unit()
		if player_units.size() <= 0:
			break

func calculate_formation_bounds() -> Dictionary:
	if player_units.size() == 0:
		return {"min_x": 0.0, "max_x": 0.0, "width": 0.0}

	var min_x := INF
	var max_x := -INF

	for unit in player_units:
		min_x = min(min_x, unit.position.x)
		max_x = max(max_x, unit.position.x)

	return {
		"min_x": min_x,
		"max_x": max_x,
		"width": max_x - min_x
	}

func fire_projectiles() -> void:
	if not projectile_scene:
		projectile_scene = load("res://scenes/projectile.tscn")
		if not projectile_scene:
			return

	var bounds: Dictionary = calculate_formation_bounds()
	var formation_width: float = max(bounds.width, PROJECTILE_WIDTH)

	# Calculate max projectiles this volley can fire
	var max_per_wave: int = int(floor(formation_width / PROJECTILE_WIDTH))
	var max_total: int = int(MAX_PROJECTILES_MULTIPLIER * max_per_wave)

	# Determine how many projectiles to fire (capped)
	var projectiles_to_fire: int = min(player_units.size(), max_total)

	# Split into waves
	var waves: int = int(ceil(float(projectiles_to_fire) / float(max_per_wave)))
	pending_waves.clear()

	for wave_index in range(waves):
		var wave_data: Array = []
		var start_idx: int = wave_index * max_per_wave
		var end_idx: int = min(start_idx + max_per_wave, projectiles_to_fire)
		var projectiles_in_wave: int = end_idx - start_idx

		# Generate evenly-spaced X positions within formation width
		for i in range(projectiles_in_wave):
			var x_offset: float = bounds.min_x + (bounds.width * i / float(max(projectiles_in_wave - 1, 1)))
			wave_data.append(x_offset)

		pending_waves.append(wave_data)

	# Fire first wave immediately
	if pending_waves.size() > 0:
		fire_wave(pending_waves.pop_front())
		wave_timer = 0.0

func fire_wave(x_offsets: Array) -> void:
	for x_offset in x_offsets:
		var projectile := projectile_scene.instantiate()
		projectile.position = global_position + Vector2(x_offset, -20)
		get_parent().add_child(projectile)

func update_count_label() -> void:
	if count_label:
		count_label.text = str(total_unit_count)  # Show total, not rendered

func update_formation(delta: float) -> void:
	"""Slowly crowd units together toward center"""
	var unit_count: int = player_units.size()
	if unit_count == 0:
		return

	# Calculate minimum crowd radius based on unit count (scales with army size)
	var fill_ratio: float = float(unit_count) / float(MAX_PLAYER_UNITS)
	var min_crowd_radius: float = 15.0 + (fill_ratio * 45.0)  # 15px at 0 units, 60px at 200 units

	for i in unit_count:
		var unit: Area2D = player_units[i]
		if not unit:
			continue

		# Only pull toward center if outside minimum crowd radius
		var distance: float = unit.position.length()
		if distance > min_crowd_radius:
			var target_pos := Vector2.ZERO
			unit.position = unit.position.lerp(target_pos, FORMATION_REFORM_SPEED * delta * 0.5)
