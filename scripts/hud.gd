extends Control

# Node references
var game_over_label: Label
var restart_button: Button

func _ready() -> void:
	# Find player and connect to game over signal only
	var player := get_tree().get_first_node_in_group("player")
	if player and player is PlayerManager:
		player.game_over.connect(_on_game_over)

func _on_game_over() -> void:
	# Create game over label on demand
	if not game_over_label:
		game_over_label = Label.new()
		game_over_label.name = "GameOver"
		game_over_label.set_anchors_preset(Control.PRESET_CENTER)
		game_over_label.text = "GAME OVER"
		game_over_label.add_theme_font_size_override("font_size", 64)
		game_over_label.modulate = Color.RED
		add_child(game_over_label)

	# Create restart button
	if not restart_button:
		restart_button = Button.new()
		restart_button.name = "RestartButton"
		restart_button.position = Vector2(350, 350)  # Centered below "GAME OVER"
		restart_button.size = Vector2(100, 40)
		restart_button.text = "RESTART"
		restart_button.add_theme_font_size_override("font_size", 18)
		restart_button.pressed.connect(_on_restart_pressed)
		add_child(restart_button)

func _on_restart_pressed() -> void:
	# Reload current scene (clean reset)
	get_tree().reload_current_scene()
