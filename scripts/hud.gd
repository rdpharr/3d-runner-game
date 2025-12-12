extends Control

# Node references
var game_over_label: Label
var restart_button: Button

# Sidebar references
var pause_button: Button
var is_paused := false

func _ready() -> void:
	# Setup sidebar first (always visible)
	setup_sidebar()

	# Find player and connect to game over signal
	var player := get_tree().get_first_node_in_group("player")
	if player and player is PlayerManager:
		player.game_over.connect(_on_game_over)

func setup_sidebar() -> void:
	# Background panel
	var sidebar_panel := ColorRect.new()
	sidebar_panel.name = "SidebarPanel"
	sidebar_panel.position = Vector2(0, 0)
	sidebar_panel.size = Vector2(140, 600)
	sidebar_panel.color = Color(0.1, 0.1, 0.1, 0.85)
	sidebar_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sidebar_panel)

	# Title label
	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.position = Vector2(10, 20)
	title_label.size = Vector2(120, 50)
	title_label.text = "Roger's first\ngame!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	sidebar_panel.add_child(title_label)

	# Stop button (red)
	var stop_button := create_sidebar_button("StopButton", "STOP", 80, Color(0.83, 0.18, 0.18))
	stop_button.pressed.connect(_on_stop_pressed)
	sidebar_panel.add_child(stop_button)

	# Pause button (orange, becomes green)
	pause_button = create_sidebar_button("PauseButton", "PAUSE", 150, Color(1.0, 0.6, 0.0))
	pause_button.pressed.connect(_on_pause_pressed)
	sidebar_panel.add_child(pause_button)

	# Restart button (blue)
	var sidebar_restart := create_sidebar_button("SidebarRestart", "RESTART", 220, Color(0.13, 0.59, 0.95))
	sidebar_restart.pressed.connect(_on_sidebar_restart_pressed)
	sidebar_panel.add_child(sidebar_restart)

func create_sidebar_button(button_name: String, text: String, y_pos: float, color: Color) -> Button:
	var button := Button.new()
	button.name = button_name
	button.position = Vector2(10, y_pos)
	button.size = Vector2(120, 50)
	button.text = text
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", color)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	return button

func _on_stop_pressed() -> void:
	get_tree().quit()

func _on_pause_pressed() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	update_pause_button()

func _on_sidebar_restart_pressed() -> void:
	# Unpause before reloading to avoid stuck pause state
	get_tree().paused = false
	get_tree().reload_current_scene()

func update_pause_button() -> void:
	if pause_button:
		if is_paused:
			pause_button.text = "RESUME"
			pause_button.add_theme_color_override("font_color", Color(0.3, 0.69, 0.31))  # Green
		else:
			pause_button.text = "PAUSE"
			pause_button.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))  # Orange

func _on_game_over() -> void:
	# Disable pause button (can't pause a dead game)
	if pause_button:
		pause_button.disabled = true

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
