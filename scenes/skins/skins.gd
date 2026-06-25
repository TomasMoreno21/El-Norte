extends CanvasLayer

const BIRD_COLORS := {
	"hornero": Color(0.8, 0.5, 0.2),
	"tero": Color(0.9, 0.9, 0.85),
	"golondrina": Color(0.3, 0.6, 0.9),
	"carpintero": Color(0.9, 0.2, 0.15),
	"premio_pajarero": Color(0.55, 0.27, 0.07),
}

const BIRD_SPRITES := {
	"hornero": preload("res://Sprites/Pajaros/hornero1.png"),
	"carpintero": preload("res://Sprites/Pajaros/carpintero1.png"),
}

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	AudioManager.add_click($Bg/VBoxContainer/Volver)
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

func _make_bird_display(bird_id: String, owned: bool) -> Control:
	var tex: Texture2D = BIRD_SPRITES.get(bird_id) as Texture2D
	if tex != null and (owned or DataManager.BIRDS[bird_id].get("cost", 0) == 0):
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(180, 0)
		tr.size_flags_vertical = 3
		tr.mouse_filter = 2
		return tr
	else:
		var cr := ColorRect.new()
		if not owned and DataManager.BIRDS[bird_id].get("cost", 0) < 0:
			cr.color = Color(0.15, 0.15, 0.15)
		else:
			cr.color = BIRD_COLORS.get(bird_id, Color.WHITE)
		cr.custom_minimum_size = Vector2(180, 0)
		cr.size_flags_vertical = 3
		cr.mouse_filter = 2
		return cr

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
		row.custom_minimum_size = Vector2(0, 190)
		row.size_flags_horizontal = 3
		row.add_theme_constant_override("separation", 20)

		var display := _make_bird_display(id, owned)
		row.add_child(display)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = 3
		info_col.size_flags_vertical = 3
		info_col.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		if not owned and bird.get("cost", 0) < 0:
			name_label.text = "???"
		else:
			name_label.text = bird.get("name", "?")
		name_label.add_theme_font_size_override("font_size", 24)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var bonus_label := Label.new()
		if not owned and bird.get("cost", 0) < 0:
			bonus_label.text = "??? "
		else:
			bonus_label.text = "Bonus: %s" % bird.get("Bonus", "—")
		bonus_label.add_theme_font_size_override("font_size", 14)
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_label.modulate = Color(0.7, 0.7, 0.7)

		var penalty_label := Label.new()
		if not owned and bird.get("cost", 0) < 0:
			penalty_label.text = ""
		else:
			penalty_label.text = "Penalidad: %s" % bird.get("Penalidad", "—")
		penalty_label.add_theme_font_size_override("font_size", 14)
		penalty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		penalty_label.modulate = Color(0.7, 0.7, 0.7)

		info_col.add_child(name_label)
		info_col.add_child(bonus_label)
		info_col.add_child(penalty_label)
		row.add_child(info_col)

		var action_btn := Button.new()
		action_btn.size_flags_horizontal = 3
		action_btn.custom_minimum_size = Vector2(0, 48)
		action_btn.add_theme_font_size_override("font_size", 18)

		if active:
			action_btn.text = "Seleccionado"
			action_btn.disabled = true
			_style_button(action_btn, Color(0.12, 0.4, 0.12))
		elif owned:
			action_btn.text = "Seleccionar"
			_style_button(action_btn, Color(0.15, 0.5, 0.15))
			action_btn.pressed.connect(_select.bind(id))
			AudioManager.add_click(action_btn)
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
			AudioManager.add_click(action_btn)

		row.add_child(action_btn)
		list.add_child(row)

	_update_balance()

func _buy(bird_id: String) -> void:
	AudioManager.play_sfx("buy")
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
