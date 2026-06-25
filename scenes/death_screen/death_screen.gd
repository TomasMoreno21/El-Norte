extends CanvasLayer

const TIPS := [
	"Mantené el ritmo: aletear seguido cansa menos que aletear fuerte.",
	"Los barros cerca del piso son más fáciles de agarrar.",
	"Si ves el signo '!', prepárate para la tormenta.",
	"El kiwi aparece cada 20 segundos... estate atento.",
	"Llegar a las Llanuras da ×1.5 de palitos.",
	"Llegar a la Puna da ×2 de palitos.",
	"El Carancho es el pájaro más rápido del juego.",
	"Las calmas son un respiro... pero no duran para siempre.",
	"Usá el escudo en zonas de obstáculos densos.",
	"El turbo duplica tu distancia recorrida.",
	"Agarrar 3 barros seguido rápido da combo +1.",
	"Doble toque rápido = mini turbo gratis.",
	"Cada pájaro tiene stats únicos. ¡Probalos todos!",
]

func _ready() -> void:
	$ColorRect/VBoxContainer/ButtonRow/RestartButton.pressed.connect(_on_restart)
	$ColorRect/VBoxContainer/ButtonRow/MenuButton.pressed.connect(_on_menu)
	AudioManager.add_click($ColorRect/VBoxContainer/ButtonRow/RestartButton)
	AudioManager.add_click($ColorRect/VBoxContainer/ButtonRow/MenuButton)

	var border := ColorRect.new()
	border.name = "TopBorder"
	border.color = Color(0.86, 0.27, 0.16)
	border.anchor_left = 0.0
	border.anchor_right = 1.0
	border.offset_bottom = 4.0
	border.mouse_filter = 2
	$ColorRect.add_child(border)

	$ColorRect/VBoxContainer/DistanceLabel.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	$ColorRect/VBoxContainer/PalitosLabel.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))

	$ColorRect/VBoxContainer/RecordDiffLabel.add_theme_color_override("font_color", Color(0.86, 0.27, 0.16))

	var bonus_bg := StyleBoxFlat.new()
	bonus_bg.bg_color = Color(0.15, 0.4, 0.15, 0.7)
	bonus_bg.corner_radius_top_left = 4
	bonus_bg.corner_radius_top_right = 4
	bonus_bg.corner_radius_bottom_left = 4
	bonus_bg.corner_radius_bottom_right = 4
	$ColorRect/VBoxContainer/BonusLabel.add_theme_stylebox_override("normal", bonus_bg)

	var tip_bg := StyleBoxFlat.new()
	tip_bg.bg_color = Color(0.12, 0.12, 0.13, 0.8)
	tip_bg.corner_radius_top_left = 4
	tip_bg.corner_radius_top_right = 4
	tip_bg.corner_radius_bottom_left = 4
	tip_bg.corner_radius_bottom_right = 4
	$ColorRect/VBoxContainer/TipLabel.add_theme_stylebox_override("normal", tip_bg)
	$ColorRect/VBoxContainer/TipLabel.add_theme_font_size_override("font_size", 20)

	var spacer := Control.new()
	spacer.size_flags_vertical = 3
	$ColorRect/VBoxContainer.add_child(spacer)
	$ColorRect/VBoxContainer.move_child(spacer, $ColorRect/VBoxContainer.get_child_count() - 2)

	_style_button($ColorRect/VBoxContainer/ButtonRow/RestartButton, Color(0.15, 0.5, 0.15))
	_style_button($ColorRect/VBoxContainer/ButtonRow/MenuButton, Color(0.86, 0.27, 0.16))
	$ColorRect/VBoxContainer/ButtonRow/RestartButton.add_theme_font_size_override("font_size", 34)
	$ColorRect/VBoxContainer/ButtonRow/MenuButton.add_theme_font_size_override("font_size", 30)

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

func show_screen(distance: int, storms: int = 0, bolas: int = 0, kiwis: int = 0, old_max: int = -1) -> void:
	var palitos := DataManager.calculate_palitos_earned(distance)
	var bonus_palitos := DataManager.claim_distance_milestones(distance)
	var bonus_bolas := DataManager.claim_record_bolas(distance, old_max if old_max >= 0 else DataManager.max_distance)
	var total_palitos := palitos + bonus_palitos
	var nuevos := DataManager.add_palitos(total_palitos)
	for a in nuevos:
		DataManager.show_achievement_popup(a)

	$ColorRect/VBoxContainer/DistanceLabel.text = "%dm" % distance
	$ColorRect/VBoxContainer/PalitosLabel.text = "Palitos: +%d  (Total: %d)" % [total_palitos, DataManager.palitos_balance]
	$ColorRect/VBoxContainer/StatsLabel.text = "Tormentas: %d  |  Barro: %d  |  Kiwis: %d" % [storms, bolas, kiwis]

	$ColorRect/VBoxContainer/BonusLabel.visible = false
	var bonus_text := ""
	if bonus_palitos > 0:
		bonus_text += "+%d palitos por hito! " % bonus_palitos
	if bonus_bolas > 0:
		bonus_text += "+%d bolas por record!" % bonus_bolas
	if bonus_text != "":
		$ColorRect/VBoxContainer/BonusLabel.text = bonus_text.strip_edges()
		$ColorRect/VBoxContainer/BonusLabel.visible = true

	$ColorRect/VBoxContainer/RecordDiffLabel.visible = false
	if old_max >= 0 and distance < old_max:
		var diff := old_max - distance
		if diff <= 50:
			$ColorRect/VBoxContainer/RecordDiffLabel.text = "¡Te quedaste a %dm del récord!" % diff
		else:
			$ColorRect/VBoxContainer/RecordDiffLabel.text = "Quedaste a %dm del récord" % diff
		$ColorRect/VBoxContainer/RecordDiffLabel.visible = true

	var tip: String = TIPS[randi() % TIPS.size()]
	$ColorRect/VBoxContainer/TipLabel.text = tip

	visible = true
	get_tree().paused = true

func _on_restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
