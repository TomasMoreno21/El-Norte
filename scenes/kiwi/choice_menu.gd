extends CanvasLayer

signal power_up_selected(type: String)

const POOL := [
	{ "text": "Escudo", "type": "shield" },
	{ "text": "Turbo", "type": "turbo" },
	{ "text": "x2 Barro", "type": "x2_bolas" },
	{ "text": "Miniatura", "type": "miniatura" },
	{ "text": "x2 Palitos", "type": "x2_palitos" },
	{ "text": "Barro extra", "type": "bola_extra" },
]

const PAID_COST := 30

func _ready() -> void:
	var pool: Array[Dictionary] = []
	for p in POOL:
		if p["type"] != "bola_extra" or "trato_hecho" in DataManager.completed_achievements:
			pool.append(p.duplicate())
	pool.shuffle()

	var free_option: Dictionary = pool.pop_front()

	var palitos_label := Label.new()
	palitos_label.text = "🪵 " + str(DataManager.palitos_balance) + " palitos"
	palitos_label.add_theme_font_size_override("font_size", 28)
	palitos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	palitos_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	$RightPanel/VBoxContainer.add_child(palitos_label)
	$RightPanel/VBoxContainer.move_child(palitos_label, 2)

	var display: Array[Dictionary] = [free_option]

	if DataManager.palitos_balance >= PAID_COST:
		var paid_count := 2
		if "trato_hecho" in DataManager.completed_achievements:
			paid_count = 3
		for i in range(min(paid_count, pool.size())):
			var p := pool[i].duplicate()
			p["cost"] = PAID_COST
			display.append(p)

	display.shuffle()

	for p in display:
		var label: String = p["text"]
		if p.has("cost"):
			label += "  🪵" + str(p["cost"])
		_add_choice(label, p["type"], p.get("cost", 0))

func _add_choice(text: String, type: String, cost: int) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 64)
	btn.add_theme_font_size_override("font_size", 36)
	btn.size_flags_horizontal = 4
	btn.pressed.connect(_on_choice.bind(type, cost))
	$RightPanel/VBoxContainer.add_child(btn)

func _on_choice(type: String, cost: int) -> void:
	if cost > 0:
		DataManager.palitos_balance -= cost
		DataManager.save_data()
	power_up_selected.emit(type)
	get_tree().paused = false
	queue_free()
