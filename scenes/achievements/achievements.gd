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
	var vbox := $Bg/VBoxContainer
	var row := vbox.get_node_or_null("StatsRow")
	if not row:
		row = HBoxContainer.new()
		row.name = "StatsRow"
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_theme_constant_override("separation", 30)
		vbox.add_child(row)
		vbox.move_child(row, 1)

	var stats := [
		["Max dist: %dm" % s.max_distance, Color(0.9, 0.15, 0.15)],
		["Barro: %d" % s.bolas_total, Color(0.9, 0.7, 0.2)],
		["Muertes: %d" % s.deaths, Color(0.9, 0.15, 0.15)],
		["Eventos: %d" % s.major_events_total, Color(0.3, 0.85, 0.3)],
	]

	for i in range(stats.size()):
		var lbl = row.get_child(i) if i < row.get_child_count() else null
		if not lbl:
			lbl = Label.new()
			lbl.add_theme_font_size_override("font_size", 36)
			row.add_child(lbl)
		lbl.text = stats[i][0]
		lbl.add_theme_color_override("font_color", stats[i][1])

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
		var next_idx: int = cur_level + 1

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 200)
		row.size_flags_horizontal = 3
		row.add_theme_constant_override("separation", 0)

		var panel_bg := ColorRect.new()
		panel_bg.color = Color(0.12, 0.4, 0.12, 0.5) if all_done else Color(0.15, 0.15, 0.16, 0.5)
		panel_bg.size_flags_horizontal = 3
		panel_bg.size_flags_vertical = 3
		panel_bg.mouse_filter = 2

		var inner := HBoxContainer.new()
		inner.size_flags_horizontal = 3
		inner.size_flags_vertical = 3
		inner.anchor_right = 1.0
		inner.anchor_bottom = 1.0
		inner.add_theme_constant_override("separation", 16)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = 3
		info.size_flags_vertical = 3
		info.add_theme_constant_override("separation", 6)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 10)

		var name_lbl := Label.new()
		name_lbl.text = a["name"]
		name_lbl.add_theme_font_size_override("font_size", 38)
		header.add_child(name_lbl)

		if not all_done:
			var level_lbl := Label.new()
			level_lbl.add_theme_font_size_override("font_size", 18)
			level_lbl.modulate = Color(0.7, 0.7, 0.7)
			level_lbl.text = "Nivel %d/%d" % [cur_level + 2, total_levels]
			header.add_child(level_lbl)

		info.add_child(header)

		if all_done:
			var done_lbl := Label.new()
			done_lbl.text = "COMPLETADO"
			done_lbl.add_theme_font_size_override("font_size", 18)
			done_lbl.modulate = Color(0, 1, 0)
			info.add_child(done_lbl)
		elif next_idx < total_levels:
			var lv = a["levels"][next_idx]
			var desc_lbl := Label.new()
			desc_lbl.text = lv["desc"]
			desc_lbl.add_theme_font_size_override("font_size", 22)
			desc_lbl.modulate = Color(0.7, 0.7, 0.7)
			info.add_child(desc_lbl)

			if id == "birder":
				var reward_lbl := Label.new()
				reward_lbl.text = "Recompensa: Nuevo pájaro"
				reward_lbl.add_theme_font_size_override("font_size", 16)
				reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.06))
				info.add_child(reward_lbl)
			elif id == "trato_hecho":
				var reward_lbl := Label.new()
				reward_lbl.text = "Recompensa: Más tratos con el kiwi"
				reward_lbl.add_theme_font_size_override("font_size", 16)
				reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.06))
				info.add_child(reward_lbl)

			if cur_val >= 0:
				var bar := ProgressBar.new()
				bar.custom_minimum_size = Vector2(0, 20)
				bar.size_flags_horizontal = 3
				bar.min_value = 0.0
				bar.max_value = lv["target"]
				bar.value = min(cur_val, lv["target"])
				bar.show_percentage = false
				info.add_child(bar)

				var progress_lbl := Label.new()
				progress_lbl.text = "%d / %d" % [min(cur_val, lv["target"]), lv["target"]]
				progress_lbl.add_theme_font_size_override("font_size", 14)
				progress_lbl.modulate = Color(0.6, 0.6, 0.6)
				info.add_child(progress_lbl)

		inner.add_child(info)

		var right_col := VBoxContainer.new()
		right_col.size_flags_vertical = 3
		right_col.alignment = BoxContainer.ALIGNMENT_CENTER
		right_col.add_theme_constant_override("separation", 8)
		right_col.custom_minimum_size = Vector2(140, 0)

		for level_idx in range(total_levels):
			var pk: String = id + "_" + str(level_idx)
			if pk in DataManager.pending_rewards:
				var lv = a["levels"][level_idx]
				var recoger_btn := Button.new()
				recoger_btn.text = "Recoger Nivel %d" % (level_idx + 1)
				recoger_btn.custom_minimum_size = Vector2(120, 42)
				var s := StyleBoxFlat.new()
				s.bg_color = Color(0.55, 0.45, 0.15)
				s.corner_radius_top_left = 8
				s.corner_radius_top_right = 8
				s.corner_radius_bottom_left = 8
				s.corner_radius_bottom_right = 8
				recoger_btn.add_theme_stylebox_override("normal", s)
				var sh := s.duplicate()
				sh.bg_color = Color(0.7, 0.55, 0.2)
				recoger_btn.add_theme_stylebox_override("hover", sh)
				recoger_btn.add_theme_color_override("font_color", Color.WHITE)
				recoger_btn.add_theme_font_size_override("font_size", 20)
				recoger_btn.pressed.connect(_claim_reward.bind(id, level_idx, lv["reward_type"], lv["reward_amount"]))
				right_col.add_child(recoger_btn)

		var reward := Label.new()
		reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if next_idx < total_levels:
			var lv = a["levels"][next_idx]
			var rtype: String = "Ba" if lv["reward_type"] == "bolas" else "P"
			reward.text = "%s +%d" % [rtype, lv["reward_amount"]]
		else:
			reward.text = "---"
		reward.add_theme_font_size_override("font_size", 22)
		reward.modulate = Color(0.9, 0.7, 0.2)
		right_col.add_child(reward)

		inner.add_child(right_col)
		panel_bg.add_child(inner)
		row.add_child(panel_bg)
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
