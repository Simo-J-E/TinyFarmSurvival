extends Area2D
class_name SurvivalArrow

const SPEED := 620.0
const LIFE_TIME := 1.65

var direction := Vector2.RIGHT
var life := LIFE_TIME

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	rotation = direction.angle()

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(19, 5)
	shape.shape = rect
	add_child(shape)

	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is SurvivalMonster:
		body.take_damage(1)
		queue_free()

func _draw() -> void:
	# Small pixel-style arrow, pointed to +X.
	draw_line(Vector2(-10, 0), Vector2(9, 0), Color("#6e3f22"), 3.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(13, 0), Vector2(7, -4), Vector2(7, 4)
	]), Color("#d9d2bd"))
	draw_line(Vector2(-10, 0), Vector2(-6, -4), Color("#e8e0cf"), 2.0)
	draw_line(Vector2(-10, 0), Vector2(-6, 4), Color("#e8e0cf"), 2.0)
