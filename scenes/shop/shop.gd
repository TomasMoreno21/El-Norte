extends CanvasLayer

const UPGRADE_DATA := [
	{ "key": "speed", "name": "+Velocidad", "base_cost": 110, "desc": "+5% velocidad por nivel", "color": Color(0.24, 0.51, 0.78) },
	{ "key": "kiwi", "name": "+Kiwi", "base_cost": 90, "desc": "+2% prob. kiwi por nivel", "color": Color(0.3, 0.7, 0.3) },
	{ "key": "palitos_base", "name": "+Palitos", "base_cost": 150, "desc": "+1 palito/10m por nivel", "color": Color(0.9, 0.7, 0.2) },
	{ "key": "shield_duration", "name": "+Escudo", "base_cost": 100, "desc": "+0.2s escudo por nivel", "color": Color(0.24, 0.51, 0.78) },
	{ "key": "turbo_duration", "name": "+Turbo", "base_cost": 100, "desc": "+0.2s turbo por nivel", "color": Color(0.24, 0.51, 0.78) },
]

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	_style_button($Bg/VBoxContainer/Volver, Color(0.86, 0.27, 0.16))
	_update_balance()
	_populate_upgrades()
	SceneTransition.fade_in()

func _style_button(btn: Button, color: Color) -> void:
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

func _update_balance() -> void:
	$Bg/VBoxContainer/PalitosLabel.text = "Palitos: %d" % DataManager.palitos_balance

func _populate_upgrades() -> void:
	var list := $Bg/VBoxContainer/ScrollContainer/UpgradeList
	for child in list.get_children():
		child.queue_free()

	for u in UPGRADE_DATA:
		var level := DataManager.get_upgrade_level(u.key)
		var max_lv: int = DataManager.UPGRADE_MAX_LEVEL.get(u.key, DataManager.MAX_LEVEL)
		var is_maxed := level >= max_lv

		var card := ColorRect.new()
		card.custom_minimum_size = Vector2(0, 100)
		card.size_flags_horizontal = 3
		card.color = Color(0.08, 0.08, 0.09, 0.8)

		var stripe := ColorRect.new()
		stripe.custom_minimum_size = Vector2(6, 0)
		stripe.size_flags_vertical = 3
		stripe.color = u.color
		stripe.mouse_filter = 2

		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = 3
		hbox.size_flags_vertical = 3
		hbox.add_theme_constant_override("separation", 20)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = 3
		info_col.size_flags_vertical = 3
		info_col.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		name_label.text = u.name
		name_label.add_theme_font_size_override("font_size", 32)

		var desc_label := Label.new()
		desc_label.text = u.desc
		desc_label.add_theme_font_size_override("font_size", 20)
		desc_label.modulate = Color(0.7, 0.7, 0.7)

		info_col.add_child(name_label)
		info_col.add_child(desc_label)

		var level_label := Label.new()
		level_label.text = "Nivel %d/%d" % [level, max_lv]
		level_label.custom_minimum_size = Vector2(140, 0)
		level_label.add_theme_font_size_override("font_size", 32)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.size_flags_vertical = 3

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(220, 70)
		buy_btn.add_theme_font_size_override("font_size", 32)
		var cost := DataManager.get_upgrade_cost(u.key)

		if is_maxed or cost == -1:
			buy_btn.text = "COMPLETO"
			buy_btn.disabled = true
			var completo_style := StyleBoxFlat.new()
			completo_style.bg_color = Color(0.2, 0.5, 0.2)
			completo_style.corner_radius_top_left = 6
			completo_style.corner_radius_top_right = 6
			completo_style.corner_radius_bottom_left = 6
			completo_style.corner_radius_bottom_right = 6
			buy_btn.add_theme_stylebox_override("normal", completo_style)
			buy_btn.add_theme_stylebox_override("disabled", completo_style)
		else:
			var can_afford := DataManager.palitos_balance >= cost
			buy_btn.text = "%d palitos" % cost
			buy_btn.disabled = not can_afford
			if not can_afford:
				var gray_style := StyleBoxFlat.new()
				gray_style.bg_color = Color(0.3, 0.3, 0.3)
				gray_style.corner_radius_top_left = 6
				gray_style.corner_radius_top_right = 6
				gray_style.corner_radius_bottom_left = 6
				gray_style.corner_radius_bottom_right = 6
				buy_btn.add_theme_stylebox_override("normal", gray_style)
				buy_btn.add_theme_stylebox_override("disabled", gray_style)
			else:
				var aff_style := StyleBoxFlat.new()
				aff_style.bg_color = Color(0.25, 0.4, 0.25)
				aff_style.corner_radius_top_left = 6
				aff_style.corner_radius_top_right = 6
				aff_style.corner_radius_bottom_left = 6
				aff_style.corner_radius_bottom_right = 6
				buy_btn.add_theme_stylebox_override("normal", aff_style)
				var key: String = u.key
				buy_btn.pressed.connect(func(): _buy(key, buy_btn.global_position))

		hbox.add_child(info_col)
		hbox.add_child(level_label)
		hbox.add_child(buy_btn)

		var card_inner := HBoxContainer.new()
		card_inner.size_flags_horizontal = 3
		card_inner.size_flags_vertical = 3
		card_inner.add_theme_constant_override("separation", 10)

		card_inner.add_child(stripe)
		card_inner.add_child(hbox)

		var margin := MarginContainer.new()
		margin.size_flags_horizontal = 3
		margin.size_flags_vertical = 3
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		margin.add_child(card_inner)

		card.add_child(margin)
		list.add_child(card)

		_update_balance()

func _buy(upgrade_key: String, btn_pos: Vector2) -> void:
	var nuevos := DataManager.buy_upgrade(upgrade_key)
	if not nuevos.is_empty():
		for a in nuevos:
			DataManager.show_achievement_popup(a)
	_populate_upgrades()
	if not DataManager.reduce_motion:
		_show_stars(btn_pos)

func _show_stars(pos: Vector2) -> void:
	var stars := GPUParticles2D.new()
	stars.one_shot = true
	stars.emitting = false
	stars.amount = 30
	stars.lifetime = 0.8
	stars.explosiveness = 0.9
	stars.position = pos + Vector2(110, 40)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 200.0
	mat.gravity = Vector3(0, -50, 0)
	mat.initial_velocity_min = 150.0
	mat.initial_velocity_max = 350.0
	mat.scale_min = 0.8
	mat.scale_max = 1.6
	mat.color = Color(1, 0.95, 0.4)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	stars.process_material = mat
	add_child(stars)
	stars.emitting = true
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(stars):
		stars.queue_free()

func _on_volver() -> void:
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
