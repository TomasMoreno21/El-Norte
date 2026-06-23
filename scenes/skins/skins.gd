extends CanvasLayer

const BIRD_COLORS := {
	"hornero": Color(0.8, 0.5, 0.2),
	"tero": Color(0.9, 0.9, 0.85),
	"golondrina": Color(0.3, 0.6, 0.9),
	"carpintero": Color(0.9, 0.2, 0.15),
	"premio_pajarero": Color(0.55, 0.27, 0.07),
}

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	_style_button($Bg/VBoxContainer/Volver, Color(0.86, 0.27, 0.16))
	_update_balance()
	_populate_birds()
	SceneTransition.fade_in()

func _style_button(btn: Button, color: Color, disabled_color := Color()) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.15)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)
	if disabled_color != Color():
		var disabled := StyleBoxFlat.new()
		disabled.bg_color = disabled_color
		disabled.corner_radius_top_left = 6
		disabled.corner_radius_top_right = 6
		disabled.corner_radius_bottom_left = 6
		disabled.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("disabled", disabled)

func _update_balance() -> void:
	$Bg/VBoxContainer/BolasLabel.text = "Barro: %d" % DataManager.bolas_balance

func _populate_birds() -> void:
	var list := $Bg/VBoxContainer/ScrollContainer/BirdList
	for child in list.get_children():
		child.queue_free()

	for id in DataManager.BIRDS:
		var bird = DataManager.BIRDS[id]
		var owned = DataManager.is_bird_unlocked(id)
		var active = DataManager.active_bird == id

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 130)
		row.size_flags_horizontal = 3
		row.add_theme_constant_override("separation", 20)

		var swatch := ColorRect.new()
		if not owned and bird.get("cost", 0) < 0:
			swatch.color = Color(0.15, 0.15, 0.15)
		else:
			swatch.color = BIRD_COLORS.get(id, Color.WHITE)
		swatch.custom_minimum_size = Vector2(100, 0)
		swatch.size_flags_vertical = 3
		swatch.mouse_filter = 2
		row.add_child(swatch)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = 3
		info_col.size_flags_vertical = 3
		info_col.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		if not owned and bird.get("cost", 0) < 0:
			name_label.text = "???"
		else:
			name_label.text = bird.get("name", "?")
		name_label.add_theme_font_size_override("font_size", 30)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var bonus_label := Label.new()
		if not owned and bird.get("cost", 0) < 0:
			bonus_label.text = "??? "
		else:
			bonus_label.text = "Bonus: %s" % bird.get("Bonus", "—")
		bonus_label.add_theme_font_size_override("font_size", 18)
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_label.modulate = Color(0.7, 0.7, 0.7)

		var penalty_label := Label.new()
		if not owned and bird.get("cost", 0) < 0:
			penalty_label.text = ""
		else:
			penalty_label.text = "Penalidad: %s" % bird.get("Penalidad", "—")
		penalty_label.add_theme_font_size_override("font_size", 18)
		penalty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		penalty_label.modulate = Color(0.7, 0.7, 0.7)

		info_col.add_child(name_label)
		info_col.add_child(bonus_label)
		info_col.add_child(penalty_label)
		row.add_child(info_col)

		var action_btn := Button.new()
		action_btn.size_flags_horizontal = 3
		action_btn.custom_minimum_size = Vector2(0, 48)
		action_btn.add_theme_font_size_override("font_size", 24)

		if active:
			action_btn.text = "Seleccionado"
			action_btn.disabled = true
			_style_button(action_btn, Color(0.12, 0.4, 0.12))
		elif owned:
			action_btn.text = "Seleccionar"
			_style_button(action_btn, Color(0.15, 0.5, 0.15))
			action_btn.pressed.connect(_select.bind(id))
		elif bird.get("cost", 0) < 0:
			action_btn.text = "---"
			action_btn.disabled = true
		else:
			action_btn.text = "Comprar (%d)" % bird.get("cost", 0)
			var can_buy: bool = DataManager.bolas_balance >= bird.get("cost", 0)
			action_btn.disabled = not can_buy
			if can_buy:
				_style_button(action_btn, Color(0.55, 0.45, 0.15))
				action_btn.add_theme_color_override("font_color", Color.WHITE)
			else:
				_style_button(action_btn, Color(0.3, 0.3, 0.3), Color(0.3, 0.3, 0.3))
			action_btn.pressed.connect(_buy.bind(id))

		row.add_child(action_btn)
		list.add_child(row)

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
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
