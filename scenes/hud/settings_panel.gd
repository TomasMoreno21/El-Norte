extends ColorRect

@export var reset_button_height: int = 40

enum TOGGLE { REDUCE_MOTION, SOUND, MUSIC, MINIMAP }

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

func _build() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "CONFIGURACIÓN"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_add_toggle(vbox, "Reducir movimiento", TOGGLE.REDUCE_MOTION)
	_add_toggle(vbox, "SFX", TOGGLE.SOUND)
	_add_toggle(vbox, "Música", TOGGLE.MUSIC)
	_add_toggle(vbox, "Mapa", TOGGLE.MINIMAP)

	var spacer := Control.new()
	spacer.size_flags_vertical = 3
	vbox.add_child(spacer)

	var reset_btn := Button.new()
	reset_btn.text = "Resetear progreso"
	reset_btn.add_theme_font_size_override("font_size", 18)
	reset_btn.custom_minimum_size = Vector2(0, reset_button_height)
	reset_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.6, 0.15, 0.15)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	reset_btn.add_theme_stylebox_override("normal", s)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.8, 0.2, 0.2)
	h.corner_radius_top_left = 8
	h.corner_radius_top_right = 8
	h.corner_radius_bottom_left = 8
	h.corner_radius_bottom_right = 8
	reset_btn.add_theme_stylebox_override("hover", h)
	reset_btn.add_theme_color_override("font_color", Color.WHITE)
	reset_btn.pressed.connect(_on_reset)
	vbox.add_child(reset_btn)

func _add_toggle(parent: Container, label: String, which: int) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	hbox.add_child(lbl)
	hbox.add_child(spacer)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(70, 40)
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func(): _toggle(which))
	_refresh_btn(btn, _get_value(which))

	hbox.add_child(btn)
	parent.add_child(hbox)

func _refresh_btn(btn: Button, val: bool) -> void:
	btn.text = "ON" if val else "OFF"
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.5, 0.15) if val else Color(0.4, 0.15, 0.15)
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.content_margin_left = 16
	s.content_margin_right = 16
	for state in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, s)
	btn.add_theme_color_override("font_color", Color.WHITE)

func _get_value(which: int) -> bool:
	match which:
		TOGGLE.REDUCE_MOTION: return DataManager.reduce_motion
		TOGGLE.SOUND: return DataManager.sound_enabled
		TOGGLE.MUSIC: return DataManager.music_enabled
		TOGGLE.MINIMAP: return DataManager.minimap_visible
	return true

func _toggle(which: int) -> void:
	var new_val := not _get_value(which)
	match which:
		TOGGLE.REDUCE_MOTION: DataManager.reduce_motion = new_val
		TOGGLE.SOUND:
			DataManager.sound_enabled = new_val
			if not new_val:
				AudioManager.stop_all_sfx()
				AudioManager.stop_all_ambient()
		TOGGLE.MUSIC:
			DataManager.music_enabled = new_val
			if new_val:
				AudioManager.start_menu_music()
			else:
				AudioManager.stop_menu_music()
		TOGGLE.MINIMAP:
			DataManager.minimap_visible = new_val
			var hud := get_parent()
			if hud and hud.has_node("Minimap"):
				hud.get_node("Minimap").queue_redraw()
	DataManager.save_data()
	var margin := get_child(0) as MarginContainer
	if margin:
		var vbox := margin.get_child(0) as VBoxContainer
		if vbox and vbox.get_child_count() > which + 1:
			var hbox := vbox.get_child(which + 1) as HBoxContainer
			if hbox:
				var btn := hbox.get_child(2) as Button
				if btn:
					_refresh_btn(btn, new_val)

func _on_reset() -> void:
	DataManager.reset_data()
	AudioManager.stop_menu_music()
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
