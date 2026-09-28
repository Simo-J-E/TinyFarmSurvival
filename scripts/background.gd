extends Node2D

const TILE := 32.0

var tiles: Dictionary = {}

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Only load the pieces used by this hand-built map.
	for index in [0, 1, 12, 13, 24, 25, 36, 37, 48, 49, 50, 51, 60, 61, 62, 63, 3, 15, 27, 39, 44, 54, 66, 68, 78, 80, 83, 89, 93, 94, 95, 96, 97, 98, 99, 105, 106, 107, 110, 111, 112, 113, 118, 119, 126, 127, 128, 129, 131]:
		tiles[index] = load("res://assets/tiny_farm/Tiles/tile_%04d.png" % index)
	queue_redraw()

func _draw() -> void:
	_draw_grass()
	_draw_paths()
	_draw_tree_border()
	_draw_barn_area()
	_draw_crop_fields()
	_draw_animal_pen()
	_draw_details()

func _tile(index: int, cell: Vector2i, size := Vector2(TILE, TILE)) -> void:
	if not tiles.has(index):
		return
	var pos := Vector2(cell.x * TILE, cell.y * TILE)
	draw_texture_rect(tiles[index], Rect2(pos, size), false)

func _prop(index: int, pos: Vector2, size := Vector2(TILE, TILE)) -> void:
	if tiles.has(index):
		draw_texture_rect(tiles[index], Rect2(pos, size), false)

func _draw_grass() -> void:
	for y in range(0, 17):
		for x in range(0, 30):
			var index := 105
			var pattern := (x * 7 + y * 11) % 19
			if pattern == 5:
				index = 106
			elif pattern == 13:
				index = 107
			_tile(index, Vector2i(x, y))

func _draw_paths() -> void:
	# Crossroads built from the actual Kenney dirt-path tiles.
	# Horizontal lane: tile 49 is the upper edge, tile 50 the lower edge.
	for x in range(0, 30):
		_tile(49, Vector2i(x, 7))
		_tile(50, Vector2i(x, 8))

	# Vertical lane: tile 24 is the left edge, tile 25 the right edge.
	for y in range(1, 17):
		_tile(24, Vector2i(14, y))
		_tile(25, Vector2i(15, y))

	# Rounded entrance caps and a clean center intersection.
	_tile(12, Vector2i(14, 1))
	_tile(13, Vector2i(15, 1))
	_tile(36, Vector2i(14, 15))
	_tile(37, Vector2i(15, 15))
	draw_rect(Rect2(14 * TILE + 5, 7 * TILE + 5, TILE * 2 - 10, TILE * 2 - 10), Color("#d4935e"))

func _draw_tree_border() -> void:
	for x in range(0, 30):
		if x in [13, 14, 15, 16]:
			continue
		_tile(15 if x % 3 else 27, Vector2i(x, 1))
		_tile(15 if x % 4 else 27, Vector2i(x, 16))
	for y in range(2, 16):
		if y in [7, 8, 9, 10]:
			continue
		_tile(15 if y % 3 else 27, Vector2i(0, y))
		_tile(15 if y % 4 else 27, Vector2i(29, y))

func _draw_barn_area() -> void:
	# Custom little barn in the upper-left corner.
	var ox := 96.0
	var oy := 84.0
	draw_rect(Rect2(ox + 10, oy + 54, 150, 92), Color("#a74b3f"))
	# Green roof assembled from the farm roof tiles.
	_prop(94, Vector2(ox + 22, oy + 8), Vector2(64, 64))
	_prop(95, Vector2(ox + 86, oy + 8), Vector2(64, 64))
	_prop(118, Vector2(ox + 54, oy + 8), Vector2(64, 64))
	_prop(129, Vector2(ox + 20, oy + 40), Vector2(64, 64))
	_prop(131, Vector2(ox + 86, oy + 40), Vector2(64, 64))
	# Door/window pieces from the same pack.
	_prop(126, Vector2(ox + 26, oy + 82), Vector2(42, 42))
	_prop(127, Vector2(ox + 70, oy + 82), Vector2(42, 42))
	_prop(128, Vector2(ox + 114, oy + 82), Vector2(42, 42))
	# Hay and trough nearby.
	_prop(96, Vector2(ox + 175, oy + 70))
	_prop(110, Vector2(ox + 174, oy + 108), Vector2(64, 32))

func _draw_crop_fields() -> void:
	# Wheat field upper-right.
	for row in range(3):
		for col in range(6):
			_prop(66, Vector2(632 + col * 34, 104 + row * 38))
	# Vegetable rows lower-right.
	for row in range(3):
		for col in range(6):
			var idx := 54 if (row + col) % 2 == 0 else 44
			_prop(idx, Vector2(632 + col * 36, 356 + row * 40))
	# A few crop sacks and a sunflower at the field entrance.
	_prop(68, Vector2(842, 190))
	_prop(83, Vector2(608, 184))

func _draw_animal_pen() -> void:
	# Simple fence pen lower-left, leaving the middle of the arena open.
	for x in range(4, 12):
		_prop(98 if x % 2 == 0 else 99, Vector2(x * TILE, 372), Vector2(32, 32))
		_prop(98 if x % 2 == 0 else 99, Vector2(x * TILE, 482), Vector2(32, 32))
	for y in range(12, 15):
		_prop(93, Vector2(128, y * TILE))
		_prop(93, Vector2(384, y * TILE))
	_prop(111, Vector2(180, 416), Vector2(64, 32))
	_prop(112, Vector2(275, 415), Vector2(64, 32))

func _draw_details() -> void:
	# Rocks, bushes and small plants make the map feel handmade without blocking combat.
	for p in [Vector2(350, 95), Vector2(550, 110), Vector2(860, 330), Vector2(75, 330)]:
		_prop(89, p)
	for p in [Vector2(335, 170), Vector2(560, 185), Vector2(565, 405), Vector2(88, 190)]:
		_prop(39, p)
	for p in [Vector2(395, 82), Vector2(540, 455), Vector2(880, 112)]:
		_prop(80, p)
