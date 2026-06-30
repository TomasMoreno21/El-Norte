extends Control

const JUGAR_TEX := preload("res://Sprites/Inteface/jugar.png")
const SALIR_TEX := preload("res://Sprites/Inteface/salida.png")

const ARBOL_FRAMES := [
	preload("res://Sprites/Fondos/Menú/menu arbol1.png"),
	preload("res://Sprites/Fondos/Menú/menu arbol2.png"),
	preload("res://Sprites/Fondos/Menú/menu arbol3.png"),
	preload("res://Sprites/Fondos/Menú/menu arbol4.png"),
]
const NUBES_FRAMES := [
	preload("res://Sprites/Fondos/Menú/menu nubes1.png"),
	preload("res://Sprites/Fondos/Menú/menu nubes2.png"),
	preload("res://Sprites/Fondos/Menú/menu nubes3.png"),
	preload("res://Sprites/Fondos/Menú/menu nubes4.png"),
]

var _arbol_idx := 0
var _nubes_idx := 0
var _anim_time := 0.0
var _titulo_time := 0.0
var _titulo_base_y := 0.0
const ANIM_INTERVAL := 0.6

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	$Jugar.gui_input.connect(_on_jugar_touch)
	$Salir.pressed.connect(_on_salir)
	$Tienda.pressed.connect(_on_tienda)
	$Logros.pressed.connect(_on_logros)
	$Skins.pressed.connect(_on_skins)
	$SettingsBtn.pressed.connect(_toggle_settings)
	for btn in [$Salir, $Tienda, $Logros, $Skins, $SettingsBtn]:
		AudioManager.add_click(btn)

	$Tienda.icon = preload("res://Sprites/Inteface/tienda.png")
	$Tienda.expand_icon = false
	$Tienda.text = ""
	$Skins.icon = preload("res://Sprites/Inteface/skins.png")
	$Skins.expand_icon = false
	$Skins.text = ""
	$Logros.icon = preload("res://Sprites/Inteface/logros.png")
	$Logros.expand_icon = false
	$Logros.text = ""
	_setup_logros_badge()
	_setup_tienda_badge()
	_setup_skins_badge()

	_setup_background()
	_titulo_base_y = $Titulo.position.y
	_animate_menu()
	SceneTransition.fade_in()
	AudioManager.start_menu_music()

func _setup_logros_badge() -> void:
	var badge := Label.new()
	badge.name = "LogrosBadge"
	badge.text = "!"
	badge.add_theme_font_size_override("font_size", 56)
	badge.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.position = Vector2($Logros.size.x - 12, -18)
	badge.z_index = 10
	badge.mouse_filter = 2
	$Logros.add_child(badge)
	_update_logros_badge()

func _update_logros_badge() -> void:
	var badge := $Logros.get_node_or_null("LogrosBadge")
	if not badge:
		return
	badge.visible = DataManager.pending_rewards.size() > 0
	if badge.visible and not badge.has_meta("BlinkTween"):
		var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		tw.tween_property(badge, "modulate:a", 0.3, 0.5)
		tw.tween_property(badge, "modulate:a", 1.0, 0.5)
		badge.set_meta("BlinkTween", tw)

func _setup_tienda_badge() -> void:
	var badge := Label.new()
	badge.name = "TiendaBadge"
	badge.text = "!"
	badge.add_theme_font_size_override("font_size", 56)
	badge.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.position = Vector2($Tienda.size.x - 12, -18)
	badge.z_index = 10
	badge.mouse_filter = 2
	$Tienda.add_child(badge)
	_update_tienda_badge()

func _update_tienda_badge() -> void:
	var badge := $Tienda.get_node_or_null("TiendaBadge")
	if not badge:
		return
	var has_available := false
	for key in DataManager.UPGRADE_COST_TABLE:
		var level := DataManager.get_upgrade_level(key)
		var max_lv: int = DataManager.UPGRADE_MAX_LEVEL.get(key, DataManager.MAX_LEVEL)
		if level >= max_lv:
			continue
		var cost := DataManager.get_upgrade_cost(key)
		if cost >= 0 and DataManager.palitos_balance >= cost:
			has_available = true
			break
	badge.visible = has_available
	if has_available and not badge.has_meta("BlinkTween"):
		var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		tw.tween_property(badge, "modulate:a", 0.3, 0.5)
		tw.tween_property(badge, "modulate:a", 1.0, 0.5)
		badge.set_meta("BlinkTween", tw)

func _setup_skins_badge() -> void:
	var badge := Label.new()
	badge.name = "SkinsBadge"
	badge.text = "!"
	badge.add_theme_font_size_override("font_size", 56)
	badge.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.position = Vector2($Skins.size.x - 12, -18)
	badge.z_index = 10
	badge.mouse_filter = 2
	$Skins.add_child(badge)
	_update_skins_badge()

func _update_skins_badge() -> void:
	var badge := $Skins.get_node_or_null("SkinsBadge")
	if not badge:
		return
	var has_available := false
	for bird in DataManager.BIRDS:
		if DataManager.is_bird_unlocked(bird):
			continue
		var cost: int = DataManager.BIRDS[bird]["cost"]
		if bird == "premio_pajarero":
			if DataManager.palitos_balance >= cost:
				has_available = true
				break
		else:
			if DataManager.bolas_balance >= cost:
				has_available = true
				break
	badge.visible = has_available
	if has_available and not badge.has_meta("BlinkTween"):
		var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		tw.tween_property(badge, "modulate:a", 0.3, 0.5)
		tw.tween_property(badge, "modulate:a", 1.0, 0.5)
		badge.set_meta("BlinkTween", tw)

func _style_texture_button(btn: Button, tex: Texture2D) -> void:
	var bg := StyleBoxTexture.new()
	bg.texture = tex
	for state in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, bg)

func _style_button(btn: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.15)
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	hover.corner_radius_bottom_left = 8
	hover.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("hover", hover)

func _on_jugar_touch(event: InputEvent) -> void:
	var touched := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		touched = true
	elif event is InputEventScreenTouch and event.pressed:
		touched = true
	if touched:
		AudioManager.fade_out_menu_music(0.3)
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _setup_background() -> void:
	$BgFondo.texture = preload("res://Sprites/Fondos/Menú/menu1.png")

func _process(delta: float) -> void:
	_anim_time += delta
	if _anim_time >= ANIM_INTERVAL:
		_anim_time -= ANIM_INTERVAL
		_arbol_idx = (_arbol_idx + 1) % ARBOL_FRAMES.size()
		_nubes_idx = (_nubes_idx + 1) % NUBES_FRAMES.size()
		$BgArbol.texture = ARBOL_FRAMES[_arbol_idx]
		$BgNubes.texture = NUBES_FRAMES[_nubes_idx]

	_titulo_time += delta
	var float_offset: float = round(sin(_titulo_time * 1.5) * 4.0)
	$Titulo.position.y = round(_titulo_base_y + float_offset)

func _animate_menu() -> void:
	$Titulo.modulate.a = 0.0
	$Jugar.modulate.a = 0.0
	$Salir.modulate.a = 0.0
	$Tienda.modulate.a = 0.0
	$Logros.modulate.a = 0.0
	$Skins.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property($Titulo, "modulate:a", 1.0, 0.5)
	tween.tween_property($Jugar, "modulate:a", 1.0, 0.5).set_delay(0.15)
	tween.tween_property($Salir, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property($Tienda, "modulate:a", 1.0, 0.5).set_delay(0.25)
	tween.tween_property($Logros, "modulate:a", 1.0, 0.5).set_delay(0.3)
	tween.tween_property($Skins, "modulate:a", 1.0, 0.5).set_delay(0.35)

func _on_tienda() -> void:
	SceneTransition.fade_to_scene("res://scenes/shop/shop.tscn")

func _on_skins() -> void:
	SceneTransition.fade_to_scene("res://scenes/skins/skins.tscn")

func _on_logros() -> void:
	SceneTransition.fade_to_scene("res://scenes/achievements/achievements.tscn")

func _on_salir() -> void:
	get_tree().quit()

func _toggle_settings() -> void:
	$SettingsPanel.visible = not $SettingsPanel.visible
