extends Node
class_name SpawnManager

# ============================================
# SPAWN CONFIGURATION - EDIT THESE VALUES
# ============================================

# --- TIMING ---
const LEVEL_DURATION := 120.0  # Seconds (2 minutes)
const WAVE_INTERVAL := 2.0     # Seconds between spawn waves
const MIN_SPACING_Y := 270.0   # Minimum vertical spacing (150 * 1.8 scaling)

# --- DIFFICULTY BREAKPOINTS ---
const EASY_THRESHOLD := 30     # Units: 1-30 = Easy
const MEDIUM_THRESHOLD := 80   # Units: 31-80 = Medium
const HARD_THRESHOLD := 150    # Units: 81-150 = Hard
# 151+ = Brutal

# --- SPAWN PROBABILITIES (per difficulty) ---
# [enemy_weight, barrel_weight, gate_weight]
const EASY_WEIGHTS := [0.55, 0.25, 0.2]     # More enemies
const MEDIUM_WEIGHTS := [0.6, 0.25, 0.15]   # More enemies
const HARD_WEIGHTS := [0.65, 0.25, 0.10]     # More enemies
const BRUTAL_WEIGHTS := [0.7, 0.2, 0.05]  # Enemy onslaught

# --- ENEMY SIZES (unit counts) ---
const EASY_ENEMIES := [5, 10, 15]           # Small groups
const MEDIUM_ENEMIES := [15, 25, 40]        # Medium groups
const HARD_ENEMIES := [25, 50, 75]         # Large groups
const BRUTAL_ENEMIES := [75, 100, 150]     # Massive hordes

# --- BARREL VALUES ---
const EASY_BARRELS := [10, 20, 50]          # Small rewards
const MEDIUM_BARRELS := [20, 50, 100]       # Medium rewards
const HARD_BARRELS := [50, 100, 200]        # Large rewards
const BRUTAL_BARRELS := [100, 200, 300]     # Huge rewards

# --- GATE STARTING VALUES ---
const EASY_GATES := [0, 5, -10]             # Neutral, small positive, small trap
const MEDIUM_GATES := [0, 10, -20, -50]     # Include trap gates
const HARD_GATES := [0, 20, -30, -100]      # Bigger traps
const BRUTAL_GATES := [50, -50, -150, -300] # High stakes

# --- PERFORMANCE CAPS ---
const MAX_ACTIVE_ENEMIES := 8
const MAX_ACTIVE_COLLECTIBLES := 10

# --- SPAWN POSITIONING ---
const SPAWN_Y_POSITION := -270.0  # Above screen (-150 * 1.8 scaling)
const LANE_LEFT := -360.0  # -200 * 1.8 scaling
const LANE_CENTER := 0.0
const LANE_RIGHT := 360.0  # 200 * 1.8 scaling

# ============================================
# END CONFIGURATION
# ============================================

# Difficulty tiers
enum DifficultyTier {
	EASY,
	MEDIUM,
	HARD,
	BRUTAL
}

# References
var game_manager: Node2D
var player_manager: PlayerManager

# State
var level_timer := 0.0
var wave_timer := 0.0
var current_player_units := 15
var spawning_active := true

# Signals
signal level_complete
signal boss_incoming  # Emitted at 120 seconds

func _ready() -> void:
	# Connect to player unit count changes
	if player_manager:
		if player_manager.has_signal("unit_count_changed"):
			player_manager.unit_count_changed.connect(_on_player_units_changed)
		current_player_units = player_manager.player_units.size()

func _process(delta: float) -> void:
	# Update level timer
	level_timer += delta

	# BOSS SPAWN at 120 seconds
	if level_timer >= LEVEL_DURATION:
		if spawning_active:
			spawning_active = false
			boss_incoming.emit()  # Trigger boss spawn
			print("Level time complete - BOSS INCOMING!")
			return

	# Spawn waves while active
	if spawning_active:
		wave_timer += delta
		if wave_timer >= WAVE_INTERVAL:
			spawn_wave()
			wave_timer = 0.0

	# Check for level complete (timer expired AND no objects remain)
	if not spawning_active:
		check_level_complete()

func _on_player_units_changed(new_count: int) -> void:
	current_player_units = new_count

func calculate_difficulty_tier() -> DifficultyTier:
	"""Determine difficulty based on current player unit count"""
	if current_player_units <= EASY_THRESHOLD:
		return DifficultyTier.EASY
	elif current_player_units <= MEDIUM_THRESHOLD:
		return DifficultyTier.MEDIUM
	elif current_player_units <= HARD_THRESHOLD:
		return DifficultyTier.HARD
	else:
		return DifficultyTier.BRUTAL

func spawn_wave() -> void:
	"""Generate 1-3 objects per wave based on difficulty"""
	# Check active object counts
	var active := count_active_objects()
	if active.enemies >= MAX_ACTIVE_ENEMIES and active.collectibles >= MAX_ACTIVE_COLLECTIBLES:
		return  # Skip this wave, too crowded

	# Determine difficulty
	var tier := calculate_difficulty_tier()

	# Get spawn weights for this tier
	var weights := get_spawn_weights(tier)

	# Spawn 1-3 objects this wave
	var objects_to_spawn := randi() % 3 + 1  # 1, 2, or 3
	for i in objects_to_spawn:
		# Roll for object type
		var roll := randf()
		var cumulative := 0.0

		# Enemy
		cumulative += weights[0]
		if roll <= cumulative and active.enemies < MAX_ACTIVE_ENEMIES:
			spawn_random_enemy(tier)
			active.enemies += 1
			continue

		# Barrel
		cumulative += weights[1]
		if roll <= cumulative and active.collectibles < MAX_ACTIVE_COLLECTIBLES:
			spawn_random_barrel(tier)
			active.collectibles += 1
			continue

		# Gate
		if active.collectibles < MAX_ACTIVE_COLLECTIBLES:
			spawn_random_gate(tier)
			active.collectibles += 1

func get_spawn_weights(tier: DifficultyTier) -> Array:
	"""Return spawn probability weights for a difficulty tier"""
	match tier:
		DifficultyTier.EASY:
			return EASY_WEIGHTS
		DifficultyTier.MEDIUM:
			return MEDIUM_WEIGHTS
		DifficultyTier.HARD:
			return HARD_WEIGHTS
		DifficultyTier.BRUTAL:
			return BRUTAL_WEIGHTS
	return EASY_WEIGHTS

func spawn_random_enemy(tier: DifficultyTier) -> void:
	"""Spawn an enemy with size appropriate to difficulty"""
	var sizes := get_enemy_sizes(tier)
	var size: int = sizes[randi() % sizes.size()]  # Explicit type
	var lane := get_random_lane()
	var pos := Vector2(lane, SPAWN_Y_POSITION)

	if game_manager and game_manager.has_method("spawn_enemy"):
		game_manager.spawn_enemy(pos, size)

func spawn_random_barrel(tier: DifficultyTier) -> void:
	"""Spawn a barrel with value appropriate to difficulty"""
	var values := get_barrel_values(tier)
	var value: int = values[randi() % values.size()]  # Explicit type
	var lane := get_random_lane()
	var pos := Vector2(lane, SPAWN_Y_POSITION)

	if game_manager and game_manager.has_method("spawn_barrel"):
		game_manager.spawn_barrel(pos, value)

func spawn_random_gate(tier: DifficultyTier) -> void:
	"""Spawn a gate with starting value appropriate to difficulty"""
	var values := get_gate_values(tier)
	var value: int = values[randi() % values.size()]  # Explicit type
	var lane := get_random_lane()
	var pos := Vector2(lane, SPAWN_Y_POSITION)

	if game_manager and game_manager.has_method("spawn_gate"):
		game_manager.spawn_gate(pos, value)

func get_enemy_sizes(tier: DifficultyTier) -> Array:
	"""Return enemy size options for a difficulty tier"""
	match tier:
		DifficultyTier.EASY:
			return EASY_ENEMIES
		DifficultyTier.MEDIUM:
			return MEDIUM_ENEMIES
		DifficultyTier.HARD:
			return HARD_ENEMIES
		DifficultyTier.BRUTAL:
			return BRUTAL_ENEMIES
	return EASY_ENEMIES

func get_barrel_values(tier: DifficultyTier) -> Array:
	"""Return barrel value options for a difficulty tier"""
	match tier:
		DifficultyTier.EASY:
			return EASY_BARRELS
		DifficultyTier.MEDIUM:
			return MEDIUM_BARRELS
		DifficultyTier.HARD:
			return HARD_BARRELS
		DifficultyTier.BRUTAL:
			return BRUTAL_BARRELS
	return EASY_BARRELS

func get_gate_values(tier: DifficultyTier) -> Array:
	"""Return gate starting value options for a difficulty tier"""
	match tier:
		DifficultyTier.EASY:
			return EASY_GATES
		DifficultyTier.MEDIUM:
			return MEDIUM_GATES
		DifficultyTier.HARD:
			return HARD_GATES
		DifficultyTier.BRUTAL:
			return BRUTAL_GATES
	return EASY_GATES

func get_random_lane() -> float:
	"""Return a random X position from the 3 lanes"""
	var lanes := [LANE_LEFT, LANE_CENTER, LANE_RIGHT]
	return lanes[randi() % lanes.size()]

func count_active_objects() -> Dictionary:
	"""Count enemies and collectibles currently on screen"""
	var enemies := 0
	var collectibles := 0

	if game_manager:
		# Count enemy groups
		var enemy_nodes := get_tree().get_nodes_in_group("enemy")
		enemies = enemy_nodes.size()

		# Count barrels and gates (children of game_manager)
		for child in game_manager.get_children():
			var script: Script = child.get_script()  # Explicit type
			if script:
				var script_path: String = script.resource_path
				if "barrel" in script_path.to_lower() or "gate" in script_path.to_lower():
					collectibles += 1

	return {"enemies": enemies, "collectibles": collectibles}

func check_level_complete() -> void:
	"""Check if level is complete (no objects AND no boss)"""
	# Check for active boss
	var boss := get_tree().get_first_node_in_group("boss")
	if boss:
		return  # Boss still alive, level not complete

	# Check for remaining enemies/collectibles
	var active := count_active_objects()
	if active.enemies == 0 and active.collectibles == 0:
		level_complete.emit()
		set_process(false)  # Stop checking
