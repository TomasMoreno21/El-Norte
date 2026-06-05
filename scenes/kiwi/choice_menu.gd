extends CanvasLayer

signal power_up_selected(type: String)

const ALL_POWERUPS := [
	{ "text": "Escudo 4s", "type": "shield" },
	{ "text": "Turbo 5s", "type": "turbo" },
	{ "text": "x2 Barro", "type": "x2_bolas" },
	{ "text": "Miniatura 3s", "type": "miniatura" },
	{ "text": "x2 Palitos 4s", "type": "x2_palitos" },
]

const TRATO_POWERUP := { "text": "Barro extra", "type": "bola_extra" }

func _ready() -> void:
	var pool := ALL_POWERUPS.duplicate()
	if "trato_hecho" in DataManager.completed_achievements:
		pool.append(TRATO_POWERUP)
	pool.shuffle()

	var count := 4 if "trato_hecho" in DataManager.completed_achievements else 3
	var chosen := pool.slice(0, count)

	for p in chosen:
		_add_choice(p["text"], p["type"])

func _add_choice(text: String, type: String) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 64)
	btn.add_theme_font_size_override("font_size", 40)
	btn.size_flags_horizontal = 4
	btn.pressed.connect(_on_choice.bind(type))
	$RightPanel/VBoxContainer.add_child(btn)

func _on_choice(type: String) -> void:
	power_up_selected.emit(type)
	get_tree().paused = false
	queue_free()
