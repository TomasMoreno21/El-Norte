extends ParallaxBackground

const BIOMES := [
	{
		"start": 0,
		"end": 800,
		"name": "Cordillera",
		"layers": [
			{ "color": Color(0.55, 0.65, 0.75), "scroll_scale": Vector2(0.05, 0), "height_ratio": 1.0 },
			{ "color": Color(0.35, 0.45, 0.55), "scroll_scale": Vector2(0.2, 0), "height_ratio": 0.6 },
			{ "color": Color(0.25, 0.30, 0.40), "scroll_scale": Vector2(0.4, 0), "height_ratio": 0.4 },
		]
	},
	{
		"start": 900,
		"end": 2000,
		"name": "Llanuras",
		"layers": [
			{ "color": Color(0.53, 0.72, 0.45), "scroll_scale": Vector2(0.05, 0), "height_ratio": 1.0 },
			{ "color": Color(0.40, 0.55, 0.30), "scroll_scale": Vector2(0.2, 0), "height_ratio": 0.6 },
			{ "color": Color(0.30, 0.40, 0.20), "scroll_scale": Vector2(0.4, 0), "height_ratio": 0.4 },
		]
	},
	{
		"start": 2100,
		"end": INF,
		"name": "Puna",
		"layers": [
			{ "color": Color(0.70, 0.60, 0.45), "scroll_scale": Vector2(0.05, 0), "height_ratio": 1.0 },
			{ "color": Color(0.55, 0.42, 0.28), "scroll_scale": Vector2(0.2, 0), "height_ratio": 0.6 },
			{ "color": Color(0.40, 0.30, 0.18), "scroll_scale": Vector2(0.4, 0), "height_ratio": 0.4 },
		]
	}
]

const TRANSITION := 200.0

var _sprites: Array[Sprite2D] = []
var _current_colors: Array[Color] = []

func _ready() -> void:
	_build_layers(BIOMES[0])
	set_run_distance(0.0)

func _build_layers(biome: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	_sprites.clear()
	_current_colors.clear()

	var viewport_size := get_viewport().get_visible_rect().size
	var tex_width := int(viewport_size.x * 2)
	var white_tex := _make_white_tex(tex_width, viewport_size)

	for cfg: Dictionary in biome["layers"]:
		var layer := ParallaxLayer.new()
		layer.motion_scale = cfg["scroll_scale"]
		layer.motion_mirroring = Vector2(tex_width, 0)

		var tex_height := int(viewport_size.y * cfg["height_ratio"])
		var sprite := Sprite2D.new()
		sprite.texture = white_tex
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, tex_width, tex_height)
		sprite.self_modulate = cfg["color"]
		sprite.position = Vector2(tex_width / 2.0, viewport_size.y - tex_height / 2.0)

		layer.add_child(sprite)
		add_child(layer)

		_sprites.append(sprite)
		_current_colors.append(cfg["color"])

func set_run_distance(dist: float) -> void:
	for i in range(len(BIOMES)):
		var b: Dictionary = BIOMES[i]
		if dist < b["start"] - TRANSITION:
			return
		if dist >= b["start"] - TRANSITION and dist < b["end"]:
			var target_colors: Array[Color] = []
			for cfg: Dictionary in b["layers"]:
				target_colors.append(cfg["color"])

			var t := 0.0
			if dist < b["start"]:
				t = (dist - (b["start"] - TRANSITION)) / TRANSITION
			else:
				t = 1.0

			for j in len(_current_colors):
				_current_colors[j] = _current_colors[j].lerp(target_colors[j], t)
				_sprites[j].self_modulate = _current_colors[j]
			return

	if dist >= BIOMES[-1]["start"]:
		var last: Dictionary = BIOMES[-1]
		for j in len(last["layers"]):
			_current_colors[j] = last["layers"][j]["color"]
			_sprites[j].self_modulate = _current_colors[j]

func _make_white_tex(w: int, viewport: Vector2) -> Texture2D:
	var image := Image.create(w, int(viewport.y), false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)
