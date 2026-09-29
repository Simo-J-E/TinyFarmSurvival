extends CharacterBody2D
class_name SurvivalMonster

signal died(monster: SurvivalMonster)

const MONSTER_TEXTURES := [
	preload("res://assets/tiny_farm/Tiles/tile_0120.png"),
	preload("res://assets/tiny_farm/Tiles/tile_0121.png"),
	preload("res://assets/tiny_farm/Tiles/tile_0122.png")
]

var target: SurvivalPlayer
var speed := 82.0
var health := 1
var attack_damage := 20
var attack_timer := 0.0
var texture: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collision_layer = 2
	collision_mask = 0
	texture = MONSTER_TEXTURES[randi() % MONSTER_TEXTURES.size()]

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	attack_timer = max(attack_timer - delta, 0.0)
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()

	if global_position.distance_to(target.global_position) < 27.0 and attack_timer <= 0.0:
		target.take_damage(attack_damage)
		attack_timer = 0.65

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		died.emit(self)
		queue_free()

func _draw() -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		points.append(Vector2(cos(a) * 13.0, sin(a) * 6.0 + 11.0))
	draw_colored_polygon(points, Color(0, 0, 0, 0.24))

	draw_circle(Vector2.ZERO, 17.0, Color(0.55, 0.08, 0.08, 0.35))
	draw_texture_rect(texture, Rect2(-22, -24, 44, 44), false)
	draw_circle(Vector2(-5, -4), 1.8, Color("#ff3030"))
	draw_circle(Vector2(5, -4), 1.8, Color("#ff3030"))
