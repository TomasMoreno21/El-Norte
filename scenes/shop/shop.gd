extends CanvasLayer

const UPGRADE_DATA := [
	{ "key": "speed", "name": "+Velocidad", "base_cost": 110, "desc": "+5% velocidad por nivel" },
	{ "key": "kiwi", "name": "+Kiwi", "base_cost": 90, "desc": "+2% prob. kiwi por nivel" },
	{ "key": "palitos_base", "name": "+Palitos", "base_cost": 150, "desc": "+1 palito/10m por nivel" },
	{ "key": "shield_duration", "name": "+Escudo", "base_cost": 100, "desc": "+0.2s escudo por nivel" },
	{ "key": "turbo_duration", "name": "+Turbo", "base_cost": 100, "desc": "+0.2s turbo por nivel" },
]

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	_update_balance()
	_populate_upgrades()
	SceneTransition.fade_in()

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
		row.custom_minimum_size = Vector2(0, 120)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(100, 0)
		row.add_child(spacer)

		var info_col := VBoxContainer.new()
		info_col.custom_minimum_size = Vector2(260, 0)
		info_col.add_theme_constant_override("separation", 2)

		var name_label := Label.new()
		name_label.text = u.name
		name_label.add_theme_font_size_override("font_size", 36)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var desc_label := Label.new()
		desc_label.text = u.desc
		desc_label.add_theme_font_size_override("font_size", 20)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.modulate = Color(0.7, 0.7, 0.7)

		info_col.add_child(name_label)
		info_col.add_child(desc_label)

		var level_label := Label.new()
		level_label.text = "Nivel %d/%d" % [level, max_lv]
		level_label.custom_minimum_size = Vector2(200, 0)
		level_label.add_theme_font_size_override("font_size", 36)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(260, 96)
		buy_btn.add_theme_font_size_override("font_size", 36)
		var cost := DataManager.get_upgrade_cost(u.key)
		if cost == -1:
			buy_btn.text = "COMPLETO"
			buy_btn.disabled = true
		else:
			buy_btn.text = "%d palitos" % cost
			buy_btn.disabled = DataManager.palitos_balance < cost
			var key: String = u.key
			buy_btn.pressed.connect(func(): _buy(key, buy_btn.global_position))

		row.add_theme_constant_override("separation", 60)

		row.add_child(info_col)
		row.add_child(level_label)
		row.add_child(buy_btn)
		list.add_child(row)

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
	stars.position = pos + Vector2(130, 48)
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
