extends CanvasLayer

func _ready() -> void:
	$Bg/VBoxContainer/Volver.pressed.connect(_on_volver)
	_update_stats()
	_populate_achievements()
	SceneTransition.fade_in()

func _update_stats() -> void:
	var s := DataManager
	$Bg/VBoxContainer/Estadisticas.text = (
		"Max dist: %dm  |  Barro: %d  |  Muertes: %d  |  Tormentas: %d"
		% [s.max_distance, s.bolas_total, s.deaths, s.storms_survived]
	)

func _populate_achievements() -> void:
	var list := $Bg/VBoxContainer/ScrollContainer/AchievementList
	for child in list.get_children():
		child.queue_free()

	for id in DataManager.ACHIEVEMENTS:
		var a = DataManager.ACHIEVEMENTS[id]
		var cur_level: int = DataManager.completed_achievements.get(id, -1)
		var total_levels: int = a["levels"].size()
		var all_done: bool = cur_level >= total_levels - 1

		var cur_val: int = DataManager.get_current_value(a["cond"])

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 190)
		row.size_flags_horizontal = 3
		row.add_theme_constant_override("separation", 30)

		var icon := Label.new()
		if all_done:
			icon.text = "OK"
			icon.modulate = Color(0, 1, 0)
		elif cur_level >= 0:
			icon.text = "->"
			icon.modulate = Color(1, 1, 0)
		else:
			icon.text = "X"
			icon.modulate = Color(0.5, 0.5, 0.5)
		icon.add_theme_font_size_override("font_size", 52)
		icon.custom_minimum_size = Vector2(80, 0)
		icon.size_flags_vertical = 3

		var info := VBoxContainer.new()
		info.size_flags_horizontal = 3
		info.size_flags_vertical = 3

		var header := HBoxContainer.new()

		var name_lbl := Label.new()
		name_lbl.text = a["name"]
		name_lbl.add_theme_font_size_override("font_size", 44)

		var level_lbl := Label.new()
		level_lbl.add_theme_font_size_override("font_size", 30)
		level_lbl.modulate = Color(0.7, 0.7, 0.7)
		if all_done:
			level_lbl.text = "Completado"
		else:
			level_lbl.text = "Nivel %d/%d" % [cur_level + 2, total_levels]

		header.add_child(name_lbl)
		header.add_child(level_lbl)

		var next_idx: int = cur_level + 1
		if not all_done and next_idx < total_levels:
			var lv = a["levels"][next_idx]
			var desc_lbl := Label.new()
			desc_lbl.text = lv["desc"]
			desc_lbl.add_theme_font_size_override("font_size", 26)
			desc_lbl.modulate = Color(0.7, 0.7, 0.7)

			info.add_child(header)
			info.add_child(desc_lbl)

			if cur_val >= 0:
				var bar := ProgressBar.new()
				bar.custom_minimum_size = Vector2(0, 30)
				bar.size_flags_horizontal = 3
				bar.min_value = 0.0
				bar.max_value = lv["target"]
				bar.value = min(cur_val, lv["target"])
				bar.show_percentage = false

				var progress_lbl := Label.new()
				progress_lbl.text = "%d / %d" % [min(cur_val, lv["target"]), lv["target"]]
				progress_lbl.add_theme_font_size_override("font_size", 22)
				progress_lbl.modulate = Color(0.6, 0.6, 0.6)

				info.add_child(bar)
				info.add_child(progress_lbl)
		else:
			info.add_child(header)
			if all_done:
				var done_lbl := Label.new()
				done_lbl.text = "Completado al maximo nivel"
				done_lbl.add_theme_font_size_override("font_size", 26)
				done_lbl.modulate = Color(0, 1, 0)
				info.add_child(done_lbl)

		var reward := Label.new()
		if not all_done and next_idx < total_levels:
			var lv = a["levels"][next_idx]
			var rtype: String = "Ba" if lv["reward_type"] == "bolas" else "P"
			reward.text = "%s +%d" % [rtype, lv["reward_amount"]]
		else:
			reward.text = "---"
		reward.add_theme_font_size_override("font_size", 38)
		reward.modulate = Color(1, 1, 0) if all_done else Color(0.5, 0.5, 0.5)
		reward.size_flags_vertical = 3

		row.add_child(icon)
		row.add_child(info)
		row.add_child(reward)
		list.add_child(row)

func _on_volver() -> void:
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
