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
const ANIM_INTERVAL := 0.6

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	$Jugar.gui_input.connect(_on_jugar_touch)
	$Salir.pressed.connect(_on_salir)
	$Tienda.pressed.connect(_on_tienda)
	$Logros.pressed.connect(_on_logros)
	$Skins.pressed.connect(_on_skins)
	$ResetButton.pressed.connect(_on_reset)
	$DebugBtn.pressed.connect(_on_debug)
	$SettingsBtn.pressed.connect(_toggle_settings)
	for btn in [$Salir, $Tienda, $Logros, $Skins, $ResetButton, $DebugBtn, $SettingsBtn]:
		AudioManager.add_click(btn)

	_style_texture_button($Jugar, JUGAR_TEX)
	_style_texture_button($Salir, SALIR_TEX)
	_style_button($Tienda, Color(0.7, 0.55, 0.15))
	_style_button($Skins, Color(0.2, 0.4, 0.7))
	_style_button($Logros, Color(0.15, 0.5, 0.15))

	$Logros.text = "\u2605"

	$Label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))

	_setup_background()
	_animate_menu()
	SceneTransition.fade_in()

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

func _animate_menu() -> void:
	$Label.modulate.a = 0.0
	$Jugar.modulate.a = 0.0
	$Salir.modulate.a = 0.0
	$Tienda.modulate.a = 0.0
	$Logros.modulate.a = 0.0
	$Skins.modulate.a = 0.0
	$DebugBtn.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property($Label, "modulate:a", 1.0, 0.5)
	tween.tween_property($Jugar, "modulate:a", 1.0, 0.5).set_delay(0.15)
	tween.tween_property($Salir, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property($Tienda, "modulate:a", 1.0, 0.5).set_delay(0.25)
	tween.tween_property($Logros, "modulate:a", 1.0, 0.5).set_delay(0.3)
	tween.tween_property($Skins, "modulate:a", 1.0, 0.5).set_delay(0.35)
	tween.tween_property($DebugBtn, "modulate:a", 1.0, 0.5).set_delay(0.4)

func _on_tienda() -> void:
	SceneTransition.fade_to_scene("res://scenes/shop/shop.tscn")

func _on_skins() -> void:
	SceneTransition.fade_to_scene("res://scenes/skins/skins.tscn")

func _on_logros() -> void:
	SceneTransition.fade_to_scene("res://scenes/achievements/achievements.tscn")

func _on_salir() -> void:
	get_tree().quit()

func _on_reset() -> void:
	DataManager.reset_data()

func _on_debug() -> void:
	DataManager.palitos_balance += 100000
	DataManager.bolas_balance += 1000
	DataManager.save_data()
	$DebugBtn.text = "¡Listo!"

func _toggle_settings() -> void:
	$SettingsPanel.visible = not $SettingsPanel.visible
