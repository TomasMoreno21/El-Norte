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
		"Max dist: %dm  |  Barro: %d  |  Muertes: %d  |  Eventos: %d"
		% [s.max_distance, s.bolas_total, s.deaths, s.major_events_total]
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
		row.custom_minimum_size = Vector2(0, 140)
		row.size_flags_horizontal = 3
		row.add_theme_constant_override("separation", 16)

		if all_done:
			var lv = a["levels"][cur_level]
			var panel := ColorRect.new()
			panel.color = Color(0.12, 0.4, 0.12, 0.6)
			panel.size_flags_horizontal = 3
			panel.size_flags_vertical = 3
			panel.size_flags_stretch_ratio = 5.0
			panel.mouse_filter = 2

			var info := VBoxContainer.new()
			info.size_flags_horizontal = 3
			info.size_flags_vertical = 3
			info.add_theme_constant_override("separation", 6)

			var header := HBoxContainer.new()
			header.add_theme_constant_override("separation", 10)
			var name_lbl := Label.new()
			name_lbl.text = a["name"]
			name_lbl.add_theme_font_size_override("font_size", 30)
			header.add_child(name_lbl)
			info.add_child(header)

			var done_lbl := Label.new()
			done_lbl.text = "COMPLETADO"
			done_lbl.add_theme_font_size_override("font_size", 16)
			done_lbl.modulate = Color(0, 1, 0)
			info.add_child(done_lbl)

			panel.add_child(info)
			info.anchor_right = 1.0
			info.anchor_bottom = 1.0
			row.add_child(panel)

			var right_box := HBoxContainer.new()
			right_box.size_flags_vertical = 3
			right_box.add_theme_constant_override("separation", 8)

			var reward := Label.new()
			var rtype: String = "Ba" if lv["reward_type"] == "bolas" else "P"
			reward.text = "%s +%d" % [rtype, lv["reward_amount"]]
			reward.add_theme_font_size_override("font_size", 24)
			reward.modulate = Color(1, 1, 0)
			reward.size_flags_vertical = 3
			right_box.add_child(reward)

			var pending_key: String = id + "_" + str(cur_level)
			if pending_key in DataManager.pending_rewards:
				var recoger_btn := Button.new()
				recoger_btn.text = "Recoger"
				recoger_btn.custom_minimum_size = Vector2(100, 40)
				var s := StyleBoxFlat.new()
				s.bg_color = Color(0.55, 0.45, 0.15)
				s.corner_radius_top_left = 6
				s.corner_radius_top_right = 6
				s.corner_radius_bottom_left = 6
				s.corner_radius_bottom_right = 6
				recoger_btn.add_theme_stylebox_override("normal", s)
				var sh := s.duplicate()
				sh.bg_color = Color(0.7, 0.55, 0.2)
				recoger_btn.add_theme_stylebox_override("hover", sh)
				recoger_btn.add_theme_color_override("font_color", Color.WHITE)
				recoger_btn.add_theme_font_size_override("font_size", 18)
				recoger_btn.size_flags_vertical = 3
				recoger_btn.pressed.connect(_claim_reward.bind(id, cur_level, lv["reward_type"], lv["reward_amount"]))
				right_box.add_child(recoger_btn)

			row.add_child(right_box)
		else:
			var info := VBoxContainer.new()
			info.size_flags_horizontal = 3
			info.size_flags_vertical = 3
			info.add_theme_constant_override("separation", 6)

			var header := HBoxContainer.new()
			header.add_theme_constant_override("separation", 10)
			var name_lbl := Label.new()
			name_lbl.text = a["name"]
			name_lbl.add_theme_font_size_override("font_size", 30)
			header.add_child(name_lbl)

			var level_lbl := Label.new()
			level_lbl.add_theme_font_size_override("font_size", 18)
			level_lbl.modulate = Color(0.7, 0.7, 0.7)
			level_lbl.text = "Nivel %d/%d" % [cur_level + 2, total_levels]
			header.add_child(level_lbl)

			info.add_child(header)

			var next_idx: int = cur_level + 1
			if next_idx < total_levels:
				var lv = a["levels"][next_idx]
				var desc_lbl := Label.new()
				desc_lbl.text = lv["desc"]
				desc_lbl.add_theme_font_size_override("font_size", 16)
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
					progress_lbl.add_theme_font_size_override("font_size", 14)
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
			reward.add_theme_font_size_override("font_size", 24)
			reward.modulate = Color(0.5, 0.5, 0.5)
			reward.size_flags_vertical = 3
			row.add_child(reward)

		list.add_child(row)

func _claim_reward(id: String, level: int, rtype: String, ramount: int) -> void:
	var info := { "id": id, "level": level, "reward_type": rtype, "reward_amount": ramount }
	DataManager.claim_achievement_reward(info)
	AudioManager.play_sfx("buy")
	var txt := DataManager.format_reward(rtype, ramount)
	if not txt.is_empty():
		_show_floating_text(txt)
	_populate_achievements()

func _show_floating_text(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.06))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(300, 40)
	var vp := get_viewport().get_visible_rect().size
	lbl.position = Vector2(vp.x / 2 - 150, vp.y / 2 - 60)
	add_child(lbl)
	var tw := get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -60), 1.0)
	tw.parallel().tween_property(lbl, "modulate", Color(1, 1, 1, 0), 1.0)
	tw.tween_callback(lbl.queue_free)

func _on_volver() -> void:
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
