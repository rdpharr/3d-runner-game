extends Node2D
class_name EnemyGroup

# Movement configuration
const CHASE_SPEED := 100.0  # Pixels per second

# Physical unit system
@export var enemy_unit_scene: PackedScene
@export var unit_count := 20
var enemy_units: Array[Sprite2D] = []
const FORMATION_RADIUS := 20.0  # Pixels for cluster

# Collision detection
@onready var collision_area := $Area2D

func _ready() -> void:
	add_to_group("enemy")

	# Spawn enemy units in cluster formation
	for i in unit_count:
		spawn_enemy_unit()

	# Connect collision signal
	if collision_area:
		collision_area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Chase player - move toward player position
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var direction: Vector2 = (player.position - position).normalized()
		position += direction * CHASE_SPEED * delta

	# Enemies never despawn - they always chase!

func spawn_enemy_unit() -> void:
	# Load unit scene if not set
	if not enemy_unit_scene:
		enemy_unit_scene = load("res://scenes/units/enemy_unit.tscn")

	var unit := enemy_unit_scene.instantiate() as Sprite2D

	# Circular formation around center
	var angle := randf() * TAU
	var radius := randf() * FORMATION_RADIUS
	unit.position = Vector2(cos(angle) * radius, sin(angle) * radius)

	enemy_units.append(unit)
	add_child(unit)

func remove_enemy_unit() -> void:
	if enemy_units.size() > 0:
		var unit: Sprite2D = enemy_units.pop_back()
		unit.queue_free()

		# Destroy entire group when all units gone
		if enemy_units.size() <= 0:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerManager:
		handle_collision(body)

func handle_collision(player: PlayerManager) -> void:
	# Destroy units from both sides (mutual damage)
	var damage := mini(player.player_units.size(), enemy_units.size())

	for i in damage:
		player.remove_player_unit()
		remove_enemy_unit()
