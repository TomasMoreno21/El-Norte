extends ParallaxBackground

const BIOMES := [
	{
		"start": 0,
		"end": 800,
		"name": "Cordillera",
		"textures": [
			"res://Sprites/Fondos/Cordillera/cordillera1.png",
			"res://Sprites/Fondos/Cordillera/cordillera2.png",
			"res://Sprites/Fondos/Cordillera/cordillera3.png",
			"res://Sprites/Fondos/Cordillera/cordillera4.png",
			"res://Sprites/Fondos/Cordillera/cordillera5.png",
			"res://Sprites/Fondos/Cordillera/cordillera6.png",
		],
		"scales": [0.0, 0.50, 1.00, 1.80, 2.80, 4.00],
		"y_offsets": [-340, -230, -260, -150, -90, -140],
	},
	{
		"start": 900,
		"end": 2000,
		"name": "Llanuras",
		"textures": [
			"res://Sprites/Fondos/Llanura/llanura1.png",
			"res://Sprites/Fondos/Llanura/llanura2.png",
			"res://Sprites/Fondos/Llanura/llanura3.png",
			"res://Sprites/Fondos/Llanura/llanura4.png",
			"res://Sprites/Fondos/Llanura/llanura5.png",
			"res://Sprites/Fondos/Llanura/llanura6.png",
			"res://Sprites/Fondos/Llanura/llanura7.png",
			"res://Sprites/Fondos/Llanura/llanura8.png",
		],
		"scales": [0.0, 0.20, 0.50, 0.80, 1.20, 1.80, 2.80, 4.00],
		"y_offsets": [-340, -280, -230, -200, -180, -150, -90, -140],
	},
	{
		"start": 2100,
		"end": INF,
		"name": "Puna",
		"textures": [
			"res://Sprites/Fondos/Norte/norte1.png",
			"res://Sprites/Fondos/Norte/norte2.png",
			"res://Sprites/Fondos/Norte/norte3.png",
			"res://Sprites/Fondos/Norte/norte4.png",
			"res://Sprites/Fondos/Norte/norte5.png",
			"res://Sprites/Fondos/Norte/norte6.png",
		],
		"scales": [0.0, 0.50, 1.00, 1.80, 2.80, 4.00],
		"y_offsets": [-340, -230, -260, -150, -90, -140],
	},
]

const TRANSITION := 50.0
const FADE_OUT := 100.0
const OVERRIDES_PATH := "user://parallax_overrides.cfg"

var _layers: Array[ParallaxLayer] = []
var _sprite_pairs: Array[Array] = []
var _tex_widths: Array[float] = []
var _base_y: Array[float] = []
var _current_biome_idx := 0
var in_transition := false

var editor_y_offsets: Array[float] = []
var editor_x_offsets: Array[float] = []

signal transition_started(message_out: String)
signal transition_ended(message_in: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_layers(BIOMES[0])
	_load_overrides()

func _load_overrides() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(OVERRIDES_PATH) != OK:
		return
	var bn: String = BIOMES[_current_biome_idx]["name"]
	var y_arr: Array = cfg.get_value(bn, "y_offsets", [])
	var x_arr: Array = cfg.get_value(bn, "x_offsets", [])
	for i in _layers.size():
		if i < y_arr.size():
			set_editor_y_offset(i, float(y_arr[i]))
		if i < x_arr.size():
			set_editor_x_offset(i, float(x_arr[i]))
	_all_overrides = _read_all_overrides()

var _all_overrides := {}

func _read_all_overrides() -> Dictionary:
	var cfg := ConfigFile.new()
	var out := {}
	if cfg.load(OVERRIDES_PATH) != OK:
		return out
	for bi in BIOMES:
		var bn: String = bi["name"]
		var y_arr: Array = cfg.get_value(bn, "y_offsets", [])
		var x_arr: Array = cfg.get_value(bn, "x_offsets", [])
		out[bn] = { "y": y_arr, "x": x_arr }
	return out

func save_overrides() -> void:
	var cfg := ConfigFile.new()
	var overrides := _all_overrides.duplicate(true)
	var cur_bn: String = BIOMES[_current_biome_idx]["name"]
	var y_arr: Array[float] = []
	var x_arr: Array[float] = []
	for i in _layers.size():
		y_arr.append(editor_y_offsets[i] if i < editor_y_offsets.size() else 0.0)
		x_arr.append(editor_x_offsets[i] if i < editor_x_offsets.size() else 0.0)
	overrides[cur_bn] = { "y": y_arr, "x": x_arr }
	for bn in overrides:
		cfg.set_value(bn, "y_offsets", overrides[bn]["y"])
		cfg.set_value(bn, "x_offsets", overrides[bn]["x"])
	cfg.save(OVERRIDES_PATH)
	_all_overrides = overrides

func reset_overrides() -> void:
	reset_editor_offsets()
	save_overrides()

func _build_layers(biome: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	_layers.clear()
	_sprite_pairs.clear()
	_tex_widths.clear()

	var viewport_size := get_viewport().get_visible_rect().size

	for i in biome["textures"].size():
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(0.0, 0.0)

		var tex: Texture2D = load(biome["textures"][i])
		var tw := 0.0
		if tex:
			tw = tex.get_size().x

		var sprites: Array[Sprite2D] = []
		var y_off: float = biome["y_offsets"][i] if i < biome["y_offsets"].size() else 0.0
		var base_y := viewport_size.y - (tex.get_size().y if tex else 1080.0) / 2.0 + y_off
		for copy in 2:
			var sprite := Sprite2D.new()
			sprite.texture = tex
			if tex:
				var tex_size := tex.get_size()
				sprite.position = Vector2(tex_size.x / 2.0 + copy * tw, base_y)
			layer.add_child(sprite)
			sprites.append(sprite)

		add_child(layer)
		_layers.append(layer)
		_sprite_pairs.append(sprites)
		_tex_widths.append(tw)
		_base_y.append(base_y)

	_apply_editor_offsets()

func set_run_distance(dist: float, speed_mult: float = 1.0) -> void:
	var new_idx := _current_biome_idx
	for i in range(len(BIOMES)):
		if dist >= BIOMES[i]["start"] - TRANSITION and dist < BIOMES[i]["end"]:
			new_idx = i
			break

	if new_idx != _current_biome_idx:
		in_transition = true
		transition_started.emit(str(BIOMES[_current_biome_idx]["name"]) + " → " + str(BIOMES[new_idx]["name"]))
		_current_biome_idx = new_idx
		_swap_textures(BIOMES[new_idx])

	var biome: Dictionary = BIOMES[_current_biome_idx]
	var t := 0.0
	if dist >= biome["start"] - TRANSITION and dist < biome["start"]:
		t = clamp((dist - (biome["start"] - TRANSITION)) / TRANSITION, 0.0, 1.0)
	elif dist >= biome["start"] and dist <= biome["end"] - FADE_OUT:
		t = 1.0
		if in_transition:
			in_transition = false
			transition_ended.emit(str(BIOMES[_current_biome_idx]["name"]))
	elif dist > biome["end"] - FADE_OUT and dist < biome["end"]:
		t = clamp((biome["end"] - dist) / FADE_OUT, 0.0, 1.0)

	for i in len(_layers):
		_layers[i].modulate.a = t if i > 0 else max(t, 0.0)
		var tw: float = _tex_widths[i]
		if tw > 0:
			var offset: float = dist * speed_mult * biome["scales"][i]
			var raw := fmod(-offset, tw)
			if raw > 0:
				raw -= tw
			for s in _sprite_pairs[i]:
				s.position.x = raw + tw / 2.0
				if i < editor_x_offsets.size():
					s.position.x += editor_x_offsets[i]
				raw += tw

func _swap_textures(biome: Dictionary) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	for i in biome["textures"].size():
		if i >= _sprite_pairs.size():
			break
		var tex: Texture2D = load(biome["textures"][i])
		if tex:
			var tex_size := tex.get_size()
			_tex_widths[i] = tex_size.x
			var tw := tex_size.x
			var y_off: float = biome["y_offsets"][i] if i < biome["y_offsets"].size() else 0.0
			var base_y := viewport_size.y - tex_size.y / 2.0 + y_off
			_base_y[i] = base_y
			for s in _sprite_pairs[i]:
				s.texture = tex
			_sprite_pairs[i][0].position = Vector2(tw / 2.0, base_y)
			_sprite_pairs[i][1].position = Vector2(tw / 2.0 + tw, base_y)

	_load_biome_overrides(biome["name"])
	_apply_editor_offsets()

func _load_biome_overrides(bn: String) -> void:
	var n := _layers.size()
	editor_y_offsets.resize(n)
	editor_x_offsets.resize(n)
	for i in n:
		editor_y_offsets[i] = 0.0
		editor_x_offsets[i] = 0.0
	var ov: Variant = _all_overrides.get(bn)
	if ov != null:
		var y_arr: Array = ov["y"]
		var x_arr: Array = ov["x"]
		for i in n:
			if i < y_arr.size():
				editor_y_offsets[i] = float(y_arr[i])
			if i < x_arr.size():
				editor_x_offsets[i] = float(x_arr[i])
	_apply_editor_offsets()

func get_biome_name() -> String:
	return str(BIOMES[_current_biome_idx]["name"])

func get_biome_y_base() -> Array:
	return BIOMES[_current_biome_idx]["y_offsets"] as Array

func get_biome_scales() -> Array:
	return BIOMES[_current_biome_idx]["scales"] as Array

func get_layer_count() -> int:
	return _layers.size()

func get_sprite_count_for_layer(layer: int) -> int:
	if layer < _sprite_pairs.size():
		return _sprite_pairs[layer].size()
	return 0

func reset_editor_offsets() -> void:
	var n := _layers.size()
	editor_y_offsets.resize(n)
	editor_x_offsets.resize(n)
	for i in range(n):
		editor_y_offsets[i] = 0.0
		editor_x_offsets[i] = 0.0
	_apply_editor_offsets()

func set_editor_y_offset(layer: int, value: float) -> void:
	if layer < 0 or layer >= _layers.size():
		return
	if editor_y_offsets.size() <= layer:
		editor_y_offsets.resize(layer + 1)
	editor_y_offsets[layer] = value
	_apply_editor_offsets()

func set_editor_x_offset(layer: int, value: float) -> void:
	if layer < 0 or layer >= _layers.size():
		return
	if editor_x_offsets.size() <= layer:
		editor_x_offsets.resize(layer + 1)
	var prev: float = editor_x_offsets[layer] if layer < editor_x_offsets.size() else 0.0
	var delta: float = value - prev
	editor_x_offsets[layer] = value
	for s in _sprite_pairs[layer]:
		s.position.x += delta

func _apply_editor_offsets() -> void:
	for i in _sprite_pairs.size():
		var base_y := _base_y[i] if i < _base_y.size() else 0.0
		var y_off := editor_y_offsets[i] if i < editor_y_offsets.size() else 0.0
		for s in _sprite_pairs[i]:
			s.position.y = base_y + y_off
