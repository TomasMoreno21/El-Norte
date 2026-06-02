extends CanvasLayer

const BIRD_COLORS := {
	"hornero": Color(0.8, 0.5, 0.2),
	"tero": Color(0.9, 0.9, 0.85),
	"golondrina": Color(0.3, 0.6, 0.9),
	"carpintero": Color(0.9, 0.2, 0.15),
}

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	_update_balance()
	_populate_birds()

func _update_balance() -> void:
	$Bg/VBoxContainer/BolasLabel.text = "Barro: %d" % DataManager.bolas_balance

func _populate_birds() -> void:
	var list := $Bg/VBoxContainer/CenterContainer/BirdList
	for child in list.get_children():
		child.queue_free()

	for id in DataManager.BIRDS:
		var bird = DataManager.BIRDS[id]
		var owned = DataManager.is_bird_unlocked(id)
		var active = DataManager.active_bird == id

		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 10)
		card.custom_minimum_size = Vector2(240, 0)
		card.size_flags_horizontal = 1

		var sprite := ColorRect.new()
		sprite.custom_minimum_size = Vector2(120, 120)
		sprite.size_flags_horizontal = 4
		sprite.color = BIRD_COLORS.get(id, Color.WHITE)
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var name_label := Label.new()
		name_label.text = bird.get("name", "?")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 36)

		var bonus_label := Label.new()
		bonus_label.text = "Bonus: %s" % bird.get("Bonus", "—")
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_label.add_theme_font_size_override("font_size", 26)

		var penalty_label := Label.new()
		penalty_label.text = "Penalidad: %s" % bird.get("Penalidad", "—")
		penalty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		penalty_label.add_theme_font_size_override("font_size", 26)

		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(0, 88)
		action_btn.add_theme_font_size_override("font_size", 34)

		if active:
			action_btn.text = "Seleccionado"
			action_btn.disabled = true
		elif owned:
			action_btn.text = "Seleccionar"
			action_btn.pressed.connect(_select.bind(id))
		elif bird.get("cost", 0) < 0:
			action_btn.text = "—"
			action_btn.disabled = true
		else:
			action_btn.text = "Comprar (%d)" % bird.get("cost", 0)
			action_btn.disabled = DataManager.bolas_balance < bird.get("cost", 0)
			action_btn.pressed.connect(_buy.bind(id))

		card.add_child(sprite)
		card.add_child(name_label)
		card.add_child(bonus_label)
		card.add_child(penalty_label)
		card.add_child(action_btn)
		list.add_child(card)

	_update_balance()

func _buy(bird_id: String) -> void:
	var nuevos := DataManager.unlock_bird(bird_id)
	if not nuevos.is_empty():
		for a in nuevos:
			DataManager.show_achievement_popup(a)
	_populate_birds()

func _select(bird_id: String) -> void:
	DataManager.select_bird(bird_id)
	_populate_birds()

func _on_volver() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
