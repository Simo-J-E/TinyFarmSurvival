extends CharacterBody2D
class_name SurvivalPlayer

signal died
signal health_changed(current: int, maximum: int)

const SPEED := 230.0
const DEFAULT_MAX_HEALTH := 100
const PLAYER_TEXTURE := preload("res://assets/tiny_farm/Tiles/tile_0109.png")

var max_health := DEFAULT_MAX_HEALTH
var health := DEFAULT_MAX_HEALTH
var can_move := true
var aim_angle := 0.0

func configure(starting_health: int) -> void:
	max_health = max(starting_health, 1)
	health = max_health

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_layer = 1
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)
	health_changed.emit(health, max_health)
	queue_redraw()

func _process(_delta: float) -> void:
	var aim := get_global_mouse_position() - global_position
	if aim.length_squared() > 0.01:
		aim_angle = aim.angle()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0

	velocity = input_dir.normalized() * SPEED if input_dir.length_squared() > 0.0 else Vector2.ZERO
	move_and_slide()

	global_position.x = clamp(global_position.x, 36.0, 924.0)
	global_position.y = clamp(global_position.y, 82.0, 505.0)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		can_move = false
		died.emit()

func get_arrow_origin() -> Vector2:
	return global_position + Vector2.RIGHT.rotated(aim_angle) * 25.0

func get_aim_direction() -> Vector2:
	return Vector2.RIGHT.rotated(aim_angle)

func _draw() -> void:
	draw_ellipse_shadow()
	draw_texture_rect(PLAYER_TEXTURE, Rect2(-24, -28, 48, 48), false)

	draw_set_transform(Vector2.ZERO, aim_angle, Vector2.ONE)
	var bow_center := Vector2(20, 0)
	var bow_color := Color("#8b572f")
	var string_color := Color("#e8ddc8")
	draw_arc(bow_center, 10.0, -1.05, 1.05, 8, bow_color, 3.0, false)
	var p1 := bow_center + Vector2(cos(-1.05), sin(-1.05)) * 10.0
	var p2 := bow_center + Vector2(cos(1.05), sin(1.05)) * 10.0
	draw_line(p1, Vector2(14, 0), string_color, 1.5)
	draw_line(Vector2(14, 0), p2, string_color, 1.5)
	draw_line(Vector2(9, 0), Vector2(29, 0), Color("#6e3f22"), 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(32, 0), Vector2(27, -3), Vector2(27, 3)
	]), Color("#d9d2bd"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_ellipse_shadow() -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		points.append(Vector2(cos(a) * 13.0, sin(a) * 6.0 + 12.0))
	draw_colored_polygon(points, Color(0, 0, 0, 0.24))
