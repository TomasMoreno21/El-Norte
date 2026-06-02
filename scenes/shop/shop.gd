extends CanvasLayer

const UPGRADE_DATA := [
	{ "key": "speed", "name": "+Velocidad", "base_cost": 30 },
	{ "key": "kiwi", "name": "+Kiwi", "base_cost": 25 },
	{ "key": "palitos_base", "name": "+Palitos", "base_cost": 40 },
	{ "key": "shield_duration", "name": "+Escudo", "base_cost": 30 },
	{ "key": "turbo_duration", "name": "+Turbo", "base_cost": 30 },
]

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	_update_balance()
	_populate_upgrades()

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

		var name_label := Label.new()
		name_label.text = u.name
		name_label.custom_minimum_size = Vector2(260, 0)
		name_label.add_theme_font_size_override("font_size", 36)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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
			buy_btn.pressed.connect(_buy.bind(u.key))

		row.add_theme_constant_override("separation", 60)

		row.add_child(name_label)
		row.add_child(level_label)
		row.add_child(buy_btn)
		list.add_child(row)

		_update_balance()

func _buy(upgrade_key: String) -> void:
	var nuevos := DataManager.buy_upgrade(upgrade_key)
	if not nuevos.is_empty():
		for a in nuevos:
			DataManager.show_achievement_popup(a)
	_populate_upgrades()

func _on_volver() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")
