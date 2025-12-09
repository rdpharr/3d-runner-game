extends Control

# Node references
@onready var unit_label := $Units

func _ready() -> void:
	# Find player and connect to signal
	var player := get_tree().get_first_node_in_group("player")
	if player and player is PlayerManager:
		player.unit_count_changed.connect(_on_unit_count_changed)
		player.game_over.connect(_on_game_over)
		_on_unit_count_changed(player.player_units.size())

func _on_unit_count_changed(new_count: int) -> void:
	if unit_label:
		unit_label.text = str(new_count)

func _on_game_over() -> void:
	# Display game over message
	if unit_label:
		unit_label.text = "GAME OVER"
		unit_label.modulate = Color.RED
