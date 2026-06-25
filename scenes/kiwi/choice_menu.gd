extends CanvasLayer

signal power_up_selected(type: String)

const POOL := [
	{ "text": "Escudo", "type": "shield", "cost": 35 },
	{ "text": "Turbo", "type": "turbo", "cost": 40 },
	{ "text": "x4 Barro", "type": "x2_bolas", "cost": 25 },
	{ "text": "Miniatura", "type": "miniatura", "cost": 20 },
	{ "text": "x3 Palitos", "type": "x2_palitos", "cost": 60 },
	{ "text": "Barro extra", "type": "bola_extra", "cost": 35 },
]

const DESCRIPTIONS := {
	"shield": "Protege de obstáculos por 8s",
	"turbo": "Triplica la distancia por 6s",
	"x2_bolas": "Da x4 de barro",
	"miniatura": "Reduce el pájaro 6s + turbo extra",
	"x2_palitos": "Triplica palitos por 6s",
	"bola_extra": "Da 1 barro extra",
}

func _ready() -> void:
	var pool: Array[Dictionary] = []
	for p in POOL:
		if p["type"] != "bola_extra" or "trato_hecho" in DataManager.completed_achievements:
			pool.append(p.duplicate())
	pool.shuffle()

	var free_option: Dictionary = pool.pop_front()

	var palitos_label := Label.new()
	palitos_label.text = "$" + str(DataManager.palitos_balance) + " palitos"
	palitos_label.add_theme_font_size_override("font_size", 22)
	palitos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	palitos_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	$RightPanel/VBoxContainer.add_child(palitos_label)
	$RightPanel/VBoxContainer.move_child(palitos_label, 2)

	_add_choice(free_option["text"], free_option["type"], 0)

	var paid: Array[Dictionary] = []
	for p in pool:
		if DataManager.palitos_balance >= p["cost"]:
			paid.append(p)
	paid.shuffle()

	var max_paid := 2
	if "trato_hecho" in DataManager.completed_achievements:
		max_paid = 3
	for i in range(min(max_paid, paid.size())):
		var p := paid[i]
		_add_choice(p["text"] + "  $" + str(p["cost"]), p["type"], p["cost"])

	_add_reject()

func _add_choice(text: String, type: String, cost: int) -> void:
	var btn := Button.new()
	btn.text = text
	btn.tooltip_text = DESCRIPTIONS.get(type, "")
	btn.custom_minimum_size = Vector2(0, 64)
	btn.add_theme_font_size_override("font_size", 30)
	btn.size_flags_horizontal = 4
	btn.pressed.connect(_on_choice.bind(type, cost))
	$RightPanel/VBoxContainer.add_child(btn)

func _add_reject() -> void:
	var btn := Button.new()
	btn.text = "Rechazar"
	btn.custom_minimum_size = Vector2(0, 64)
	btn.add_theme_font_size_override("font_size", 30)
	btn.size_flags_horizontal = 4
	btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	btn.pressed.connect(_on_reject)
	btn.pressed.connect(func(): AudioManager.play_sfx("rechazar_kiwi"))
	$RightPanel/VBoxContainer.add_child(btn)

func _on_choice(type: String, cost: int) -> void:
	if cost > 0:
		DataManager.palitos_balance -= cost
		DataManager.save_data()
	power_up_selected.emit(type)
	get_tree().paused = false
	queue_free()

func _on_reject() -> void:
	get_tree().paused = false
	queue_free()
