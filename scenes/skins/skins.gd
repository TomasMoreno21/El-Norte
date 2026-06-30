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
	"golondrina": preload("res://Sprites/Pajaros/golondrina1.png"),
	"tero": preload("res://Sprites/Pajaros/tero1.png"),
	"premio_pajarero": preload("res://Sprites/Pajaros/carancho1.png"),
}

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	AudioManager.add_click($Bg/VBoxContainer/Volver)
	_style_button($Bg/VBoxContainer/Volver, Color(0.86, 0.27, 0.16))
	$Bg/VBoxContainer/BolasLabel.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
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
	if tex != null:
		var container := Control.new()
		container.custom_minimum_size = Vector2(300, 0)
		container.size_flags_vertical = 3
		container.mouse_filter = 2
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = 2
		tr.position = Vector2(15, 35)
		tr.custom_minimum_size = Vector2(300, 267)
		container.add_child(tr)
		if not owned:
			tr.modulate = Color(0.15, 0.15, 0.15, 1.0)
			var qmark := Label.new()
			qmark.text = "???"
			qmark.add_theme_font_size_override("font_size", 48)
			qmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			qmark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			qmark.modulate = Color(0.5, 0.5, 0.5)
			qmark.mouse_filter = 2
			qmark.position = Vector2(15, 35)
			qmark.custom_minimum_size = Vector2(270, 280)
			container.add_child(qmark)
		return container
	else:
		var cr := ColorRect.new()
		if not owned and DataManager.BIRDS[bird_id].get("cost", 0) < 0:
			cr.color = Color(0.15, 0.15, 0.15)
		else:
			cr.color = BIRD_COLORS.get(bird_id, Color.WHITE)
		cr.custom_minimum_size = Vector2(300, 0)
		cr.size_flags_vertical = 3
		cr.mouse_filter = 2
		return cr

func _update_balance() -> void:
	$Bg/VBoxContainer/BolasLabel.text = "Barro: %d  |  Palitos: %d" % [DataManager.bolas_balance, DataManager.palitos_balance]

func _populate_birds() -> void:
	var list := $Bg/VBoxContainer/ScrollContainer/BirdList
	for child in list.get_children():
		child.queue_free()

	for id in DataManager.BIRDS:
		var bird = DataManager.BIRDS[id]
		var owned = DataManager.is_bird_unlocked(id)
		var active = DataManager.active_bird == id
		if id == "premio_pajarero" and not owned and not DataManager.carancho_available:
			continue

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 300)
		row.size_flags_horizontal = 3

		var panel_bg := ColorRect.new()
		panel_bg.color = Color(0.15, 0.15, 0.16, 0.5)
		panel_bg.size_flags_horizontal = 3
		panel_bg.size_flags_vertical = 3
		panel_bg.mouse_filter = 2
		row.add_child(panel_bg)

		var inner := HBoxContainer.new()
		inner.size_flags_horizontal = 3
		inner.size_flags_vertical = 3
		inner.anchor_right = 1.0
		inner.anchor_bottom = 1.0
		inner.add_theme_constant_override("separation", 20)
		panel_bg.add_child(inner)

		var display := _make_bird_display(id, owned)
		inner.add_child(display)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = 3
		info_col.size_flags_vertical = 3
		info_col.alignment = BoxContainer.ALIGNMENT_CENTER
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
			bonus_label.text = "???"
		else:
			bonus_label.text = "Pro: %s" % bird.get("Bonus", "—")
		bonus_label.add_theme_font_size_override("font_size", 22)
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_label.modulate = Color(0.3, 0.9, 0.3)

		var penalty_label := Label.new()
		if not owned and bird.get("cost", 0) < 0:
			penalty_label.text = ""
		else:
			penalty_label.text = "Contra: %s" % bird.get("Penalidad", "—")
		penalty_label.add_theme_font_size_override("font_size", 22)
		penalty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		penalty_label.modulate = Color(0.9, 0.25, 0.2)

		info_col.add_child(name_label)
		info_col.add_child(bonus_label)
		info_col.add_child(penalty_label)
		inner.add_child(info_col)

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
		else:
			var cost: int = bird.get("cost", 0)
			var use_palitos: bool = id == "premio_pajarero"
			var currency := "Palitos" if use_palitos else "Barro"
			var balance: int = DataManager.palitos_balance if use_palitos else DataManager.bolas_balance
			action_btn.text = "Comprar (%d %s)" % [cost, currency]
			var can_buy: bool = balance >= cost
			action_btn.disabled = not can_buy
			if can_buy:
				_style_button(action_btn, Color(0.55, 0.45, 0.15))
				action_btn.add_theme_color_override("font_color", Color.WHITE)
			else:
				_style_button(action_btn, Color(0.3, 0.3, 0.3), Color(0.3, 0.3, 0.3))
			action_btn.pressed.connect(func(): _buy(id, action_btn.global_position + action_btn.size * 0.5))
			AudioManager.add_click(action_btn)

		inner.add_child(action_btn)
		list.add_child(row)

	_update_balance()

func _buy(bird_id: String, btn_pos: Vector2) -> void:
	AudioManager.play_sfx("buy")
	var nuevos := DataManager.unlock_bird(bird_id)
	if not nuevos.is_empty():
		for a in nuevos:
			DataManager.show_achievement_popup(a)
	if not DataManager.reduce_motion:
		_show_big_stars(btn_pos)
	_populate_birds()

func _select(bird_id: String) -> void:
	DataManager.select_bird(bird_id)
	_populate_birds()

func _show_big_stars(pos: Vector2) -> void:
	var stars := GPUParticles2D.new()
	stars.one_shot = true
	stars.emitting = false
	stars.amount = 200
	stars.lifetime = 0.6
	stars.explosiveness = 1.0
	stars.position = pos
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 360.0
	mat.gravity = Vector3(0, -30, 0)
	mat.initial_velocity_min = 300.0
	mat.initial_velocity_max = 800.0
	mat.scale_min = 3.0
	mat.scale_max = 6.0
	mat.color = Color(1.0, 0.75, 0.06)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	stars.process_material = mat
	add_child(stars)
	stars.emitting = true
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(stars):
		stars.queue_free()

func _on_volver() -> void:
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
