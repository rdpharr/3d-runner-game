extends Control

# Node references
var game_over_label: Label
var restart_button: Button

# Sidebar references
var pause_button: Button
var is_paused := false

func _ready() -> void:
	# Setup bottom bar first (always visible)
	setup_bottom_bar()

	# Find player and connect to game over signal
	var player := get_tree().get_first_node_in_group("player")
	if player and player is PlayerManager:
		player.game_over.connect(_on_game_over)

func setup_bottom_bar() -> void:
	const SAFE_AREA_BOTTOM := 120.0       # Padding for Android nav gestures
	const BOTTOM_BAR_HEIGHT := 100.0      # Height of control bar
	const BAR_Y := 2180.0                 # 2400 - 120 - 100
	const BUTTON_WIDTH := 300.0           # Each button width
	const BUTTON_HEIGHT := 80.0
	const BUTTON_Y_OFFSET := 10.0         # From top of bar

	# Background panel (semi-transparent dark bar at bottom)
	var bottom_panel := ColorRect.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.position = Vector2(0, BAR_Y)
	bottom_panel.size = Vector2(1080, BOTTOM_BAR_HEIGHT + SAFE_AREA_BOTTOM)
	bottom_panel.color = Color(0.1, 0.1, 0.1, 0.85)
	bottom_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bottom_panel)

	# Title label (top center of screen)
	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.position = Vector2(390, 50)
	title_label.size = Vector2(300, 60)
	title_label.text = "Roger's first game!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title_label)

	# Stop button (left)
	var stop_button := create_bottom_button("StopButton", "STOP", 60, BUTTON_Y_OFFSET, Color(0.83, 0.18, 0.18))
	stop_button.pressed.connect(_on_stop_pressed)
	bottom_panel.add_child(stop_button)

	# Pause button (center)
	pause_button = create_bottom_button("PauseButton", "PAUSE", 390, BUTTON_Y_OFFSET, Color(1.0, 0.6, 0.0))
	pause_button.pressed.connect(_on_pause_pressed)
	bottom_panel.add_child(pause_button)

	# Restart button (right)
	var restart_btn := create_bottom_button("RestartButton", "RESTART", 720, BUTTON_Y_OFFSET, Color(0.13, 0.59, 0.95))
	restart_btn.pressed.connect(_on_sidebar_restart_pressed)
	bottom_panel.add_child(restart_btn)

func create_bottom_button(button_name: String, text: String, x_pos: float, y_pos: float, color: Color) -> Button:
	var button := Button.new()
	button.name = button_name
	button.position = Vector2(x_pos, y_pos)
	button.size = Vector2(300, 80)
	button.text = text
	button.add_theme_font_size_override("font_size", 28)
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
		game_over_label.add_theme_font_size_override("font_size", 115)  # 64 * 1.8 scaling
		game_over_label.modulate = Color.RED
		add_child(game_over_label)

	# Create restart button
	if not restart_button:
		restart_button = Button.new()
		restart_button.name = "RestartButton"
		restart_button.position = Vector2(390, 1200)  # Center of portrait screen
		restart_button.size = Vector2(300, 80)  # Scaled button size
		restart_button.text = "RESTART"
		restart_button.add_theme_font_size_override("font_size", 32)  # 18 * 1.8 scaling
		restart_button.pressed.connect(_on_restart_pressed)
		add_child(restart_button)

func _on_restart_pressed() -> void:
	# Reload current scene (clean reset)
	get_tree().reload_current_scene()
