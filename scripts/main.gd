extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const MonsterScript = preload("res://scripts/monster.gd")
const ArrowScript = preload("res://scripts/arrow.gd")
const BackgroundScript = preload("res://scripts/background.gd")

const SCREEN_SIZE := Vector2(960, 540)
const DIFFICULTIES := {
	"easy": {
		"label": "EASY",
		"description": "More health / slower enemies / calmer spawns",
		"player_health": 130,
		"enemy_speed": 0.86,
		"enemy_damage": 14,
		"health_step": 72.0,
		"spawn_start": 1.72,
		"spawn_min": 0.30,
		"spawn_ramp": 0.0090,
		"accent": Color("#8ad26d")
	},
	"normal": {
		"label": "NORMAL",
		"description": "Balanced survival experience",
		"player_health": 100,
		"enemy_speed": 1.0,
		"enemy_damage": 20,
		"health_step": 55.0,
		"spawn_start": 1.42,
		"spawn_min": 0.20,
		"spawn_ramp": 0.0105,
		"accent": Color("#f0c46a")
	},
	"hard": {
		"label": "HARD",
		"description": "Less health / faster enemies / heavy pressure",
		"player_health": 80,
		"enemy_speed": 1.16,
		"enemy_damage": 25,
		"health_step": 42.0,
		"spawn_start": 1.05,
		"spawn_min": 0.14,
		"spawn_ramp": 0.0125,
		"accent": Color("#ef776f")
	}
}

var player: SurvivalPlayer
var score := 0
var elapsed := 0.0
var spawn_timer := 0.0
var shoot_timer := 0.0
var game_started := false
var game_over := false
var selected_difficulty := "normal"
var active_difficulty: Dictionary = {}

var canvas: CanvasLayer
var game_hud: Control
var menu_overlay: ColorRect
var menu_card: Panel
var difficulty_buttons: Dictionary = {}
var difficulty_description: Label
var start_button: Button
var score_label: Label
var health_label: Label
var health_bar: ProgressBar
var time_label: Label
var difficulty_label: Label
var game_over_overlay: ColorRect
var final_score_label: Label

func _ready() -> void:
	randomize()
	_build_background()
	_build_ui()
	_select_difficulty("normal")
	_show_main_menu()

func _process(delta: float) -> void:
	if not game_started or game_over:
		return

	elapsed += delta
	spawn_timer -= delta
	shoot_timer = max(shoot_timer - delta, 0.0)

	if spawn_timer <= 0.0:
		_spawn_monster()
		spawn_timer = _current_spawn_interval()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and shoot_timer <= 0.0:
		_shoot_arrow()
		shoot_timer = 0.32

	time_label.text = "%02d:%02d" % [int(elapsed / 60.0), int(elapsed) % 60]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and game_started:
		_show_main_menu()

func _build_background() -> void:
	var background := Node2D.new()
	background.set_script(BackgroundScript)
	background.z_index = -10
	add_child(background)

func _start_game() -> void:
	_clear_gameplay_nodes()
	active_difficulty = DIFFICULTIES[selected_difficulty].duplicate()
	score = 0
	elapsed = 0.0
	shoot_timer = 0.0
	spawn_timer = min(0.90, float(active_difficulty["spawn_start"]))
	game_started = true
	game_over = false

	menu_overlay.visible = false
	game_over_overlay.visible = false
	game_hud.visible = true

	score_label.text = "0"
	time_label.text = "00:00"
	difficulty_label.text = String(active_difficulty["label"])
	difficulty_label.add_theme_color_override("font_color", active_difficulty["accent"])

	_spawn_player()

func _show_main_menu() -> void:
	game_started = false
	game_over = false
	_clear_gameplay_nodes()
	game_hud.visible = false
	game_over_overlay.visible = false
	menu_overlay.visible = true
	_select_difficulty(selected_difficulty)

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.configure(int(active_difficulty["player_health"]))
	player.global_position = Vector2(480, 285)
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	add_child(player)

func _spawn_monster() -> void:
	if game_over or not is_instance_valid(player):
		return

	var monster := MonsterScript.new()
	monster.target = player
	monster.speed = (76.0 + min(elapsed * 0.40, 100.0)) * float(active_difficulty["enemy_speed"])
	monster.health = 1 + int(elapsed / float(active_difficulty["health_step"]))
	monster.attack_damage = int(active_difficulty["enemy_damage"])
	monster.global_position = _random_edge_position()
	monster.died.connect(_on_monster_died)
	add_child(monster)

func _random_edge_position() -> Vector2:
	var side := randi() % 4
	match side:
		0:
			return Vector2(randf_range(55, 905), 67)
		1:
			return Vector2(randf_range(55, 905), 505)
		2:
			return Vector2(42, randf_range(80, 492))
		_:
			return Vector2(918, randf_range(80, 492))

func _current_spawn_interval() -> float:
	return max(
		float(active_difficulty["spawn_min"]),
		float(active_difficulty["spawn_start"]) - elapsed * float(active_difficulty["spawn_ramp"])
	)

func _shoot_arrow() -> void:
	if not is_instance_valid(player):
		return
	var dir := player.get_aim_direction().normalized()
	var arrow := ArrowScript.new()
	arrow.direction = dir
	arrow.global_position = player.get_arrow_origin()
	add_child(arrow)

func _on_monster_died(_monster: SurvivalMonster) -> void:
	if game_over:
		return
	score += 1
	score_label.text = str(score)

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "%d / %d" % [current, maximum]
	health_bar.max_value = maximum
	health_bar.value = current

func _on_player_died() -> void:
	game_over = true
	if is_instance_valid(player):
		player.can_move = false
	for child in get_children():
		if child is SurvivalMonster:
			child.set_physics_process(false)

	final_score_label.text = "KILLS   %d\nTIME    %02d:%02d\nMODE    %s" % [
		score,
		int(elapsed / 60.0),
		int(elapsed) % 60,
		String(active_difficulty["label"])
	]
	game_hud.visible = false
	game_over_overlay.visible = true

func _clear_gameplay_nodes() -> void:
	for child in get_children():
		if child is SurvivalPlayer or child is SurvivalMonster or child is SurvivalArrow:
			child.queue_free()
	player = null

func _select_difficulty(key: String) -> void:
	if not DIFFICULTIES.has(key):
		return
	selected_difficulty = key
	var config: Dictionary = DIFFICULTIES[key]
	if is_instance_valid(difficulty_description):
		difficulty_description.text = String(config["description"])
	if is_instance_valid(start_button):
		start_button.text = "START  %s" % String(config["label"])
	_refresh_difficulty_buttons()

func _refresh_difficulty_buttons() -> void:
	for key in difficulty_buttons.keys():
		var button: Button = difficulty_buttons[key]
		var selected := String(key) == selected_difficulty
		var config: Dictionary = DIFFICULTIES[key]
		var accent: Color = config["accent"]
		button.add_theme_stylebox_override("normal", _button_box(
			Color(accent.r, accent.g, accent.b, 0.20) if selected else Color("#17221b"),
			accent if selected else Color("#314339"),
			12
		))
		button.add_theme_stylebox_override("hover", _button_box(Color(accent.r, accent.g, accent.b, 0.28), accent, 12))
		button.add_theme_stylebox_override("pressed", _button_box(Color(accent.r, accent.g, accent.b, 0.36), accent, 12))
		button.add_theme_color_override("font_color", Color.WHITE if selected else Color("#c4d1c8"))

func _build_ui() -> void:
	canvas = CanvasLayer.new()
	add_child(canvas)

	_build_game_hud()
	_build_main_menu()
	_build_game_over_screen()

func _build_game_hud() -> void:
	game_hud = Control.new()
	game_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(game_hud)

	var top_panel := Panel.new()
	top_panel.position = Vector2(18, 14)
	top_panel.size = Vector2(924, 62)
	top_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.035, 0.055, 0.042, 0.93), Color("#365341"), 16))
	game_hud.add_child(top_panel)

	var kills_title := _make_label("KILLS", Vector2(22, 10), 12, Color("#91a998"))
	top_panel.add_child(kills_title)
	score_label = _make_label("0", Vector2(22, 26), 24, Color.WHITE)
	top_panel.add_child(score_label)

	var hp_title := _make_label("HEALTH", Vector2(278, 10), 12, Color("#91a998"))
	top_panel.add_child(hp_title)
	health_label = _make_label("100 / 100", Vector2(405, 8), 13, Color("#dce9df"))
	health_label.size = Vector2(150, 18)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_panel.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(278, 31)
	health_bar.size = Vector2(277, 14)
	health_bar.show_percentage = false
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.add_theme_stylebox_override("background", _panel_box(Color("#101713"), Color("#23352a"), 7))
	health_bar.add_theme_stylebox_override("fill", _panel_box(Color("#78c66a"), Color("#78c66a"), 7))
	top_panel.add_child(health_bar)

	var time_title := _make_label("TIME", Vector2(694, 10), 12, Color("#91a998"))
	top_panel.add_child(time_title)
	time_label = _make_label("00:00", Vector2(694, 26), 24, Color.WHITE)
	top_panel.add_child(time_label)

	difficulty_label = _make_label("NORMAL", Vector2(808, 21), 13, Color("#f0c46a"))
	difficulty_label.size = Vector2(92, 22)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_panel.add_child(difficulty_label)

	var controls_panel := Panel.new()
	controls_panel.position = Vector2(314, 494)
	controls_panel.size = Vector2(332, 31)
	controls_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.035, 0.055, 0.042, 0.86), Color("#2b4134"), 12))
	game_hud.add_child(controls_panel)
	var controls := _make_label("WASD / ARROWS  MOVE     LEFT CLICK  SHOOT", Vector2(12, 6), 12, Color("#dce9df"))
	controls.size = Vector2(308, 19)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_panel.add_child(controls)

func _build_main_menu() -> void:
	menu_overlay = ColorRect.new()
	menu_overlay.position = Vector2.ZERO
	menu_overlay.size = SCREEN_SIZE
	menu_overlay.color = Color(0.015, 0.035, 0.022, 0.70)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(menu_overlay)

	menu_card = Panel.new()
	menu_card.position = Vector2(155, 54)
	menu_card.size = Vector2(650, 432)
	menu_card.add_theme_stylebox_override("panel", _panel_box(Color(0.045, 0.075, 0.055, 0.97), Color("#456450"), 22))
	menu_overlay.add_child(menu_card)

	var eyebrow := _make_label("SURVIVE THE FARM", Vector2(36, 28), 12, Color("#91b49b"))
	eyebrow.add_theme_constant_override("outline_size", 2)
	eyebrow.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.25))
	menu_card.add_child(eyebrow)

	var title := _make_label("TINY FARM", Vector2(34, 48), 43, Color("#f4f7ef"))
	menu_card.add_child(title)
	var title_2 := _make_label("SURVIVAL", Vector2(34, 91), 43, Color("#8fd176"))
	menu_card.add_child(title_2)

	var subtitle := _make_label("Hold the farm. Aim with the mouse. Survive as long as you can.", Vector2(36, 145), 14, Color("#b9c8bd"))
	subtitle.size = Vector2(578, 25)
	menu_card.add_child(subtitle)

	var choose := _make_label("CHOOSE DIFFICULTY", Vector2(36, 191), 12, Color("#91a998"))
	menu_card.add_child(choose)

	var button_keys := ["easy", "normal", "hard"]
	for i in range(button_keys.size()):
		var key: String = button_keys[i]
		var config: Dictionary = DIFFICULTIES[key]
		var button := Button.new()
		button.text = String(config["label"])
		button.position = Vector2(36 + i * 194, 217)
		button.size = Vector2(178, 48)
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.pressed.connect(_select_difficulty.bind(key))
		menu_card.add_child(button)
		difficulty_buttons[key] = button

	difficulty_description = _make_label("Balanced survival experience", Vector2(36, 278), 13, Color("#c6d4ca"))
	difficulty_description.size = Vector2(578, 22)
	difficulty_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_card.add_child(difficulty_description)

	start_button = Button.new()
	start_button.text = "START  NORMAL"
	start_button.position = Vector2(36, 320)
	start_button.size = Vector2(374, 52)
	start_button.add_theme_font_size_override("font_size", 17)
	start_button.add_theme_color_override("font_color", Color("#102015"))
	start_button.add_theme_color_override("font_hover_color", Color("#102015"))
	start_button.add_theme_color_override("font_pressed_color", Color("#102015"))
	start_button.add_theme_stylebox_override("normal", _button_box(Color("#8fd176"), Color("#a8e18f"), 14))
	start_button.add_theme_stylebox_override("hover", _button_box(Color("#9ddd82"), Color("#c2efae"), 14))
	start_button.add_theme_stylebox_override("pressed", _button_box(Color("#78bf63"), Color("#8fd176"), 14))
	start_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	start_button.pressed.connect(_start_game)
	menu_card.add_child(start_button)

	var quit := Button.new()
	quit.text = "QUIT"
	quit.position = Vector2(426, 320)
	quit.size = Vector2(188, 52)
	_style_secondary_button(quit)
	quit.pressed.connect(_quit_game)
	menu_card.add_child(quit)

	var hint := _make_label("ESC returns to this menu", Vector2(36, 392), 11, Color("#789181"))
	hint.size = Vector2(578, 18)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_card.add_child(hint)

func _build_game_over_screen() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.position = Vector2.ZERO
	game_over_overlay.size = SCREEN_SIZE
	game_over_overlay.color = Color(0.012, 0.022, 0.016, 0.82)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.visible = false
	canvas.add_child(game_over_overlay)

	var card := Panel.new()
	card.position = Vector2(300, 82)
	card.size = Vector2(360, 376)
	card.add_theme_stylebox_override("panel", _panel_box(Color(0.055, 0.075, 0.060, 0.98), Color("#5a6f60"), 20))
	game_over_overlay.add_child(card)

	var over_title := _make_label("RUN OVER", Vector2(36, 30), 31, Color("#f4f7ef"))
	over_title.size = Vector2(288, 44)
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(over_title)

	var over_subtitle := _make_label("The farm finally got you.", Vector2(36, 72), 13, Color("#9fb0a4"))
	over_subtitle.size = Vector2(288, 22)
	over_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(over_subtitle)

	final_score_label = _make_label("KILLS   0\nTIME    00:00\nMODE    NORMAL", Vector2(68, 116), 17, Color("#e6eee8"))
	final_score_label.size = Vector2(224, 92)
	final_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(final_score_label)

	var replay := Button.new()
	replay.text = "PLAY AGAIN"
	replay.position = Vector2(46, 226)
	replay.size = Vector2(268, 44)
	replay.add_theme_font_size_override("font_size", 15)
	replay.add_theme_color_override("font_color", Color("#102015"))
	replay.add_theme_color_override("font_hover_color", Color("#102015"))
	replay.add_theme_color_override("font_pressed_color", Color("#102015"))
	replay.add_theme_stylebox_override("normal", _button_box(Color("#8fd176"), Color("#a8e18f"), 12))
	replay.add_theme_stylebox_override("hover", _button_box(Color("#9ddd82"), Color("#c2efae"), 12))
	replay.add_theme_stylebox_override("pressed", _button_box(Color("#78bf63"), Color("#8fd176"), 12))
	replay.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	replay.pressed.connect(_start_game)
	card.add_child(replay)

	var menu := Button.new()
	menu.text = "MAIN MENU"
	menu.position = Vector2(46, 280)
	menu.size = Vector2(268, 40)
	_style_secondary_button(menu)
	menu.pressed.connect(_show_main_menu)
	card.add_child(menu)

	var quit := Button.new()
	quit.text = "QUIT"
	quit.position = Vector2(46, 328)
	quit.size = Vector2(268, 32)
	_style_ghost_button(quit)
	quit.pressed.connect(_quit_game)
	card.add_child(quit)

func _make_label(text_value: String, pos: Vector2, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel_box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	return box

func _button_box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var box := _panel_box(bg, border, radius)
	box.set_border_width_all(1)
	return box

func _style_secondary_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#d8e3db"))
	button.add_theme_stylebox_override("normal", _button_box(Color("#17221b"), Color("#395143"), 12))
	button.add_theme_stylebox_override("hover", _button_box(Color("#213127"), Color("#5c7765"), 12))
	button.add_theme_stylebox_override("pressed", _button_box(Color("#101713"), Color("#395143"), 12))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _style_ghost_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("#8fa194"))
	button.add_theme_color_override("font_hover_color", Color("#d7e2da"))
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _quit_game() -> void:
	get_tree().quit()
