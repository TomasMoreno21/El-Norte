extends ParallaxBackground

const BIOMES := [
	{
		"start": 0,
		"end": 800,
		"name": "Cordillera",
		"textures": [
			"res://Sprites/Fondos/Cordillera/paralax1.png",
			"res://Sprites/Fondos/Cordillera/paralax2.png",
			"res://Sprites/Fondos/Cordillera/paralax3.png",
			"res://Sprites/Fondos/Cordillera/paralax4.png",
			"res://Sprites/Fondos/Cordillera/paralax5.png",
			"res://Sprites/Fondos/Cordillera/paralax6.png",
		],
		"scales": [0.0, 0.50, 1.00, 1.80, 2.80, 4.00],
		"y_offsets": [-340, -230, -260, -150, -90, -140],
	},
	{
		"start": 900,
		"end": 2000,
		"name": "Llanuras",
		"textures": [
			"res://Sprites/Fondos/Cordillera/paralax1.png",
			"res://Sprites/Fondos/Cordillera/paralax2.png",
			"res://Sprites/Fondos/Cordillera/paralax3.png",
			"res://Sprites/Fondos/Cordillera/paralax4.png",
			"res://Sprites/Fondos/Cordillera/paralax5.png",
			"res://Sprites/Fondos/Cordillera/paralax6.png",
		],
		"scales": [0.0, 0.50, 1.00, 1.80, 2.80, 4.00],
		"y_offsets": [-340, -230, -260, -150, -90, -140],
	},
	{
		"start": 2100,
		"end": INF,
		"name": "Puna",
		"textures": [
			"res://Sprites/Fondos/Cordillera/paralax1.png",
			"res://Sprites/Fondos/Cordillera/paralax2.png",
			"res://Sprites/Fondos/Cordillera/paralax3.png",
			"res://Sprites/Fondos/Cordillera/paralax4.png",
			"res://Sprites/Fondos/Cordillera/paralax5.png",
			"res://Sprites/Fondos/Cordillera/paralax6.png",
		],
		"scales": [0.0, 0.50, 1.00, 1.80, 2.80, 4.00],
		"y_offsets": [-340, -230, -260, -150, -90, -140],
	},
]

const TRANSITION := 50.0
const FADE_OUT := 100.0

var _layers: Array[ParallaxLayer] = []
var _sprite_pairs: Array[Array] = []
var _tex_widths: Array[float] = []
var _current_biome_idx := 0
var in_transition := false

signal transition_started(message_out: String)
signal transition_ended(message_in: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_layers(BIOMES[0])

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
		for copy in 2:
			var sprite := Sprite2D.new()
			sprite.texture = tex
			if tex:
				var tex_size := tex.get_size()
				sprite.position = Vector2(tex_size.x / 2.0 + copy * tw, viewport_size.y - tex_size.y / 2.0 + y_off)
			layer.add_child(sprite)
			sprites.append(sprite)

		add_child(layer)
		_layers.append(layer)
		_sprite_pairs.append(sprites)
		_tex_widths.append(tw)

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
			for s in _sprite_pairs[i]:
				s.texture = tex
			_sprite_pairs[i][0].position = Vector2(tw / 2.0, viewport_size.y - tex_size.y / 2.0 + y_off)
			_sprite_pairs[i][1].position = Vector2(tw / 2.0 + tw, viewport_size.y - tex_size.y / 2.0 + y_off)
