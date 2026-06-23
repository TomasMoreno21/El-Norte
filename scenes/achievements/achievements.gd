extends CanvasLayer

func _ready() -> void:
	$Bg/VBoxContainer/ButtonRow/Volver.pressed.connect(_on_volver)
	_style_button($Bg/VBoxContainer/ButtonRow/Volver, Color(0.86, 0.27, 0.16))
	$Bg/VBoxContainer/ButtonRow/Volver.custom_minimum_size = Vector2(800, 96)
	_update_stats()
	_populate_achievements()
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
		row.custom_minimum_size = Vector2(0, 120)
		row.size_flags_horizontal = 3
		row.add_theme_constant_override("separation", 12)

		if all_done:
			var panel := ColorRect.new()
			panel.color = Color(0.12, 0.4, 0.12, 0.6)
			panel.size_flags_horizontal = 3
			panel.size_flags_vertical = 3
			panel.size_flags_stretch_ratio = 5.0
			panel.mouse_filter = 2

			var info := VBoxContainer.new()
			info.size_flags_horizontal = 3
			info.size_flags_vertical = 3
			info.add_theme_constant_override("separation", 2)

			var header := HBoxContainer.new()
			var name_lbl := Label.new()
			name_lbl.text = a["name"]
			name_lbl.add_theme_font_size_override("font_size", 36)
			header.add_child(name_lbl)
			info.add_child(header)

			var done_lbl := Label.new()
			done_lbl.text = "COMPLETADO"
			done_lbl.add_theme_font_size_override("font_size", 22)
			done_lbl.modulate = Color(0, 1, 0)
			info.add_child(done_lbl)

			panel.add_child(info)
			info.anchor_right = 1.0
			info.anchor_bottom = 1.0
			row.add_child(panel)

			var reward := Label.new()
			var lv = a["levels"][cur_level]
			var rtype: String = "Ba" if lv["reward_type"] == "bolas" else "P"
			reward.text = "%s +%d" % [rtype, lv["reward_amount"]]
			reward.add_theme_font_size_override("font_size", 30)
			reward.modulate = Color(1, 1, 0)
			reward.size_flags_horizontal = 3
			reward.size_flags_vertical = 3
			reward.size_flags_stretch_ratio = 1.0
			row.add_child(reward)
		else:
			var info := VBoxContainer.new()
			info.size_flags_horizontal = 3
			info.size_flags_vertical = 3
			info.add_theme_constant_override("separation", 2)

			var header := HBoxContainer.new()
			var name_lbl := Label.new()
			name_lbl.text = a["name"]
			name_lbl.add_theme_font_size_override("font_size", 36)
			header.add_child(name_lbl)

			var level_lbl := Label.new()
			level_lbl.add_theme_font_size_override("font_size", 24)
			level_lbl.modulate = Color(0.7, 0.7, 0.7)
			level_lbl.text = "Nivel %d/%d" % [cur_level + 2, total_levels]
			header.add_child(level_lbl)

			info.add_child(header)

			var next_idx: int = cur_level + 1
			if next_idx < total_levels:
				var lv = a["levels"][next_idx]
				var desc_lbl := Label.new()
				desc_lbl.text = lv["desc"]
				desc_lbl.add_theme_font_size_override("font_size", 22)
				desc_lbl.modulate = Color(0.7, 0.7, 0.7)
				info.add_child(desc_lbl)

				if cur_val >= 0:
					var bar := ProgressBar.new()
					bar.custom_minimum_size = Vector2(0, 20)
					bar.size_flags_horizontal = 3
					bar.min_value = 0.0
					bar.max_value = lv["target"]
					bar.value = min(cur_val, lv["target"])
					bar.show_percentage = false

					var progress_lbl := Label.new()
					progress_lbl.text = "%d / %d" % [min(cur_val, lv["target"]), lv["target"]]
					progress_lbl.add_theme_font_size_override("font_size", 20)
					progress_lbl.modulate = Color(0.6, 0.6, 0.6)

					info.add_child(bar)
					info.add_child(progress_lbl)

			row.add_child(info)

			var reward := Label.new()
			if next_idx < total_levels:
				var lv = a["levels"][next_idx]
				var rtype: String = "Ba" if lv["reward_type"] == "bolas" else "P"
				reward.text = "%s +%d" % [rtype, lv["reward_amount"]]
			else:
				reward.text = "---"
			reward.add_theme_font_size_override("font_size", 30)
			reward.modulate = Color(0.5, 0.5, 0.5)
			reward.size_flags_vertical = 3
			row.add_child(reward)

		list.add_child(row)

func _on_volver() -> void:
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
