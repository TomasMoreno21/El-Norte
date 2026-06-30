extends CanvasLayer

const UPGRADE_DATA := [
	{ "key": "speed", "name": "+Velocidad", "base_cost": 135, "desc": "+5% velocidad por nivel" },
	{ "key": "kiwi", "name": "+Kiwi", "base_cost": 115, "desc": "+2% prob. kiwi por nivel" },
	{ "key": "palitos_base", "name": "+Palitos", "base_cost": 200, "desc": "+1 palito/10m por nivel" },
	{ "key": "shield_duration", "name": "+Escudo", "base_cost": 125, "desc": "+0.5s escudo por nivel" },
	{ "key": "turbo_duration", "name": "+Turbo", "base_cost": 125, "desc": "+0.5s turbo por nivel" },
]

const STRIPE_COLORS := {
	"speed": Color(0.15, 0.5, 0.15),
	"kiwi": Color(0.2, 0.4, 0.7),
	"palitos_base": Color(0.7, 0.55, 0.15),
	"shield_duration": Color(0.2, 0.4, 0.7),
	"turbo_duration": Color(0.2, 0.4, 0.7),
}

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	AudioManager.add_click($Bg/VBoxContainer/Volver)
	_style_button($Bg/VBoxContainer/Volver, Color(0.86, 0.27, 0.16))
	$Bg/VBoxContainer/Volver.custom_minimum_size = Vector2(800, 96)
	$Bg/VBoxContainer/Volver.add_theme_font_size_override("font_size", 30)
	$Bg/VBoxContainer/PalitosLabel.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	_update_balance()
	_populate_upgrades()
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
	if disabled_color.a > 0:
		var disabled := StyleBoxFlat.new()
		disabled.bg_color = disabled_color
		disabled.corner_radius_top_left = 6
		disabled.corner_radius_top_right = 6
		disabled.corner_radius_bottom_left = 6
		disabled.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("disabled", disabled)

func _update_balance() -> void:
	$Bg/VBoxContainer/PalitosLabel.text = "Palitos: %d" % DataManager.palitos_balance

func _populate_upgrades() -> void:
	var list := $Bg/VBoxContainer/ScrollContainer/UpgradeList
	for child in list.get_children():
		child.queue_free()

	for u in UPGRADE_DATA:
		var level := DataManager.get_upgrade_level(u.key)
		var max_lv: int = DataManager.UPGRADE_MAX_LEVEL.get(u.key, DataManager.MAX_LEVEL)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 110)
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
		inner.add_theme_constant_override("separation", 14)
		panel_bg.add_child(inner)

		var stripe := ColorRect.new()
		stripe.color = STRIPE_COLORS[u.key]
		stripe.custom_minimum_size = Vector2(6, 0)
		stripe.size_flags_vertical = 3
		stripe.mouse_filter = 2
		inner.add_child(stripe)

		var info_col := VBoxContainer.new()
		info_col.size_flags_horizontal = 3
		info_col.size_flags_vertical = 3
		info_col.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		name_label.text = u.name
		name_label.add_theme_font_size_override("font_size", 34)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", STRIPE_COLORS.get(u.key, Color.WHITE))

		var desc_label := Label.new()
		desc_label.text = u.desc
		desc_label.add_theme_font_size_override("font_size", 22)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.modulate = Color(0.7, 0.7, 0.7)

		info_col.add_child(name_label)
		info_col.add_child(desc_label)
		inner.add_child(info_col)

		var level_label := Label.new()
		level_label.text = "Nivel %d/%d" % [level, max_lv]
		level_label.size_flags_horizontal = 3
		level_label.size_flags_vertical = 3
		level_label.add_theme_font_size_override("font_size", 28)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var buy_btn := Button.new()
		buy_btn.size_flags_horizontal = 3
		buy_btn.custom_minimum_size = Vector2(0, 60)
		buy_btn.add_theme_font_size_override("font_size", 28)
		var cost := DataManager.get_upgrade_cost(u.key)
		if cost == -1:
			buy_btn.text = "COMPLETO"
			buy_btn.disabled = true
			_style_button(buy_btn, Color(0.12, 0.4, 0.12), Color(0.12, 0.4, 0.12))
		else:
			buy_btn.text = "%d palitos" % cost
			var can_buy: bool = DataManager.palitos_balance >= cost
			buy_btn.disabled = not can_buy
			if can_buy:
				_style_button(buy_btn, Color(0.55, 0.45, 0.15))
				buy_btn.add_theme_color_override("font_color", Color.WHITE)
			else:
				_style_button(buy_btn, Color(0.3, 0.3, 0.3), Color(0.3, 0.3, 0.3))
			var key: String = u.key
			buy_btn.pressed.connect(func(): _buy(key, buy_btn.global_position + buy_btn.size * 0.5))
			AudioManager.add_click(buy_btn)

		inner.add_child(level_label)
		inner.add_child(buy_btn)
		list.add_child(row)

	_update_balance()

func _buy(upgrade_key: String, btn_pos: Vector2) -> void:
	AudioManager.play_sfx("buy")
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
	stars.amount = 80
	stars.lifetime = 0.4
	stars.explosiveness = 1.0
	stars.position = pos
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 300.0
	mat.gravity = Vector3(0, -20, 0)
	mat.initial_velocity_min = 250.0
	mat.initial_velocity_max = 600.0
	mat.scale_min = 2.0
	mat.scale_max = 4.0
	mat.color = Color(0.2, 1, 0.3)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	stars.process_material = mat
	add_child(stars)
	stars.emitting = true
	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(stars):
		stars.queue_free()

func _on_volver() -> void:
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
