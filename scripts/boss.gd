extends Node2D
class_name Boss

# Configuration
const BOSS_SCALE := 3.0  # 3x scale (user-adjusted from 4.0)
const ADVANCE_SPEED := 60.0  # Pixels per second toward player
const MAX_HEALTH := 500
const DAMAGE_PER_SECOND := 2.0  # Boss HP lost per second during collision
const PLAYER_DAMAGE_PER_SECOND := 10.0  # Player units lost per second during collision
const FLASH_INTERVAL := 0.1  # Seconds between collision flash effects

# State
var current_health := MAX_HEALTH
var is_defeated := false
var is_colliding := false
var collision_timer := 0.0

# Nodes
@onready var sprite := $Sprite2D
@onready var health_bar := $HealthBar
@onready var collision_area := $CollisionArea
@onready var projectile_hitbox := $ProjectileHitbox

# Signals
signal boss_defeated
signal boss_collision_start
signal boss_collision_end

func _ready() -> void:
	add_to_group("boss")

	# Setup sprite
	sprite.texture = load("res://assets/pixellab/boss1.png")
	sprite.scale = Vector2(BOSS_SCALE, BOSS_SCALE)
	sprite.modulate = Color(1.0, 0.8, 0.8)  # Red tint
	sprite.z_index = 5  # Above units

	# Setup health bar
	health_bar.min_value = 0
	health_bar.max_value = MAX_HEALTH
	health_bar.value = current_health
	health_bar.show_percentage = false

	# Connect collision signals
	collision_area.body_entered.connect(_on_collision_area_body_entered)
	collision_area.body_exited.connect(_on_collision_area_body_exited)
	projectile_hitbox.area_entered.connect(_on_projectile_area_entered)

func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	# Move downward slowly
	position.y += ADVANCE_SPEED * delta

	# Apply continuous collision damage
	if is_colliding:
		collision_timer += delta

		# Apply damage every frame while colliding
		var player := get_tree().get_first_node_in_group("player") as PlayerManager
		if player:
			apply_collision_damage(delta, player)

func apply_collision_damage(delta: float, player: PlayerManager) -> void:
	# Damage boss
	current_health -= DAMAGE_PER_SECOND * delta
	update_health_bar()
	check_defeat()

	# Flash boss red during collision
	apply_collision_flash()

	# Damage player (convert fractional damage to units with probabilistic rounding)
	var player_damage := PLAYER_DAMAGE_PER_SECOND * delta
	var units_to_remove: int = int(player_damage)
	if randf() < (player_damage - float(units_to_remove)):
		units_to_remove += 1  # Probabilistic rounding

	for i in units_to_remove:
		player.remove_player_unit()
		if player.total_unit_count <= 0:
			break

func apply_collision_flash() -> void:
	"""Flash between dark red and light red during collision"""
	if int(collision_timer / FLASH_INTERVAL) % 2 == 0:
		sprite.modulate = Color(1.0, 0.5, 0.5)  # Dark red
	else:
		sprite.modulate = Color(1.0, 0.8, 0.8)  # Light red

func check_defeat() -> void:
	"""Check if boss health depleted and trigger defeat"""
	if current_health <= 0 and not is_defeated:
		defeat()

func _on_collision_area_body_entered(body: Node2D) -> void:
	if body is PlayerManager and not is_defeated:
		is_colliding = true
		collision_timer = 0.0
		boss_collision_start.emit()
		print("Boss collision started!")

func _on_collision_area_body_exited(body: Node2D) -> void:
	if body is PlayerManager:
		is_colliding = false
		boss_collision_end.emit()
		print("Boss collision ended!")

func _on_projectile_area_entered(area: Area2D) -> void:
	if area.has_method("on_hit_boss"):
		area.on_hit_boss()  # Tell projectile it hit

	on_projectile_hit()

func on_projectile_hit() -> void:
	if is_defeated:
		return

	current_health -= 1
	update_health_bar()
	check_defeat()

	# Flash effect
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color(1.0, 0.8, 0.8)

func defeat() -> void:
	if is_defeated:
		return

	is_defeated = true
	is_colliding = false
	set_physics_process(false)

	# Disable collision
	collision_area.set_deferred("monitoring", false)
	projectile_hitbox.set_deferred("monitoring", false)

	# Emit signal immediately
	boss_defeated.emit()

	# Death animation: scale up + fade out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ONE * BOSS_SCALE * 2.0, 0.8)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_property(health_bar, "modulate:a", 0.0, 0.4)

	await tween.finished
	queue_free()

func update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
