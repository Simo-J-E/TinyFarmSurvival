extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const MonsterScript = preload("res://scripts/monster.gd")
const ArrowScript = preload("res://scripts/arrow.gd")
const BackgroundScript = preload("res://scripts/background.gd")

var player: SurvivalPlayer
var score := 0
var elapsed := 0.0
var spawn_timer := 0.0
var shoot_timer := 0.0
var game_over := false

var score_label: Label
var health_label: Label
var time_label: Label
var game_over_panel: ColorRect
var final_score_label: Label

func _ready() -> void:
	randomize()
	_build_background()
	_build_ui()
	_spawn_player()
	spawn_timer = 0.75

func _process(delta: float) -> void:
	if game_over:
		return

	elapsed += delta
	spawn_timer -= delta
	shoot_timer = max(shoot_timer - delta, 0.0)

	if spawn_timer <= 0.0:
		_spawn_monster()
		spawn_timer = _current_spawn_interval()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and shoot_timer <= 0.0:
		_shoot_arrow()
		shoot_timer = 0.34

	time_label.text = "TIME  %02d:%02d" % [int(elapsed / 60.0), int(elapsed) % 60]

func _build_background() -> void:
	var background := Node2D.new()
	background.set_script(BackgroundScript)
	background.z_index = -10
	add_child(background)

func _spawn_player() -> void:
	player = PlayerScript.new()
	player.global_position = Vector2(480, 285)
	player.died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	add_child(player)

func _spawn_monster() -> void:
	if game_over or not is_instance_valid(player):
		return

	var monster := MonsterScript.new()
	monster.target = player
	monster.speed = 76.0 + min(elapsed * 0.40, 100.0)
	monster.health = 1 + int(elapsed / 55.0)
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
	# Starts calm, then turns into a swarm over time.
	return max(0.18, 1.45 - elapsed * 0.0105)

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
	score_label.text = "KILLS  %d" % score

func _on_health_changed(current: int, maximum: int) -> void:
	health_label.text = "HP  %d / %d" % [current, maximum]

func _on_player_died() -> void:
	game_over = true
	final_score_label.text = "YOU DIED\n\nKILLS: %d\nTIME: %02d:%02d" % [score, int(elapsed / 60.0), int(elapsed) % 60]
	game_over_panel.visible = true
	for child in get_children():
		if child is SurvivalMonster:
			child.set_physics_process(false)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var top_bar := ColorRect.new()
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(960, 48)
	top_bar.color = Color(0.04, 0.055, 0.04, 0.90)
	canvas.add_child(top_bar)

	score_label = _make_label("KILLS  0", Vector2(22, 10), 22)
	canvas.add_child(score_label)

	health_label = _make_label("HP  100 / 100", Vector2(396, 10), 22)
	canvas.add_child(health_label)

	time_label = _make_label("TIME  00:00", Vector2(790, 10), 22)
	canvas.add_child(time_label)

	var controls_panel := ColorRect.new()
	controls_panel.position = Vector2(278, 502)
	controls_panel.size = Vector2(404, 30)
	controls_panel.color = Color(0.04, 0.055, 0.04, 0.78)
	canvas.add_child(controls_panel)
	var controls := _make_label("WASD / ARROWS  MOVE     LEFT CLICK  BOW", Vector2(292, 507), 15)
	canvas.add_child(controls)

	game_over_panel = ColorRect.new()
	game_over_panel.position = Vector2(0, 0)
	game_over_panel.size = Vector2(960, 540)
	game_over_panel.color = Color(0.02, 0.02, 0.02, 0.84)
	game_over_panel.visible = false
	canvas.add_child(game_over_panel)

	var card := ColorRect.new()
	card.position = Vector2(310, 120)
	card.size = Vector2(340, 310)
	card.color = Color("#172118")
	game_over_panel.add_child(card)

	final_score_label = _make_label("YOU DIED", Vector2(55, 42), 30)
	final_score_label.size = Vector2(230, 130)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(final_score_label)

	var replay := Button.new()
	replay.text = "REPLAY"
	replay.position = Vector2(70, 195)
	replay.size = Vector2(200, 42)
	replay.pressed.connect(_restart_game)
	card.add_child(replay)

	var quit := Button.new()
	quit.text = "QUIT"
	quit.position = Vector2(70, 250)
	quit.size = Vector2(200, 42)
	quit.pressed.connect(_quit_game)
	card.add_child(quit)

func _make_label(text_value: String, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label

func _restart_game() -> void:
	get_tree().reload_current_scene()

func _quit_game() -> void:
	get_tree().quit()
