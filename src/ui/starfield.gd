extends Node2D
## Procedural, endlessly tiling starfield with parallax. Meant to be a child
## of the view camera: its origin is the screen centre, and each layer is
## shifted against the camera position by its depth, so far stars drift less
## than near ones. Tiles are generated once into textures, so a frame costs a
## handful of draw_texture calls.

const TILE := 1024
const LAYERS := [
	{"depth": 0.12, "count": 260, "size": 1, "tint": Color(0.65, 0.7, 0.9)},
	{"depth": 0.3, "count": 110, "size": 2, "tint": Color(0.85, 0.88, 1.0)},
	{"depth": 0.55, "count": 30, "size": 3, "tint": Color(1.0, 0.97, 0.9)},
]

var _textures: Array[ImageTexture] = []
var _camera: Camera2D


func _ready() -> void:
	_camera = get_parent() as Camera2D
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for layer: Dictionary in LAYERS:
		_textures.append(_make_tile(rng, layer.count, layer.size))
	z_index = -100


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _camera == null:
		return
	var half := get_viewport_rect().size * 0.5 / _camera.zoom.x
	for i in LAYERS.size():
		var layer: Dictionary = LAYERS[i]
		var offset := -_camera.global_position * float(layer.depth)
		var ox := fposmod(offset.x, TILE)
		var oy := fposmod(offset.y, TILE)
		var start_x := ox - TILE * ceilf((ox + half.x) / TILE)
		var start_y := oy - TILE * ceilf((oy + half.y) / TILE)
		var y := start_y
		while y < half.y:
			var x := start_x
			while x < half.x:
				draw_texture(_textures[i], Vector2(x, y), layer.tint)
				x += TILE
			y += TILE


static func _make_tile(rng: RandomNumberGenerator, count: int, size: int) -> ImageTexture:
	var image := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for _i in count:
		var x := rng.randi_range(0, TILE - size)
		var y := rng.randi_range(0, TILE - size)
		var brightness := rng.randf_range(0.35, 1.0)
		for dx in size:
			for dy in size:
				image.set_pixel(x + dx, y + dy, Color(1, 1, 1, brightness))
	return ImageTexture.create_from_image(image)
