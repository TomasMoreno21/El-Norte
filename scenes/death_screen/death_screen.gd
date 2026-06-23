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

const RED := Color(0.86, 0.27, 0.16)
const GREEN := Color(0.3, 0.7, 0.3)
const DARK_GREEN := Color(0.12, 0.35, 0.12)

func _ready() -> void:
	$Panel/VBox/RestartButton.pressed.connect(_on_restart)
	$Panel/VBox/MenuButton.pressed.connect(_on_menu)
	_style_button($Panel/VBox/RestartButton, GREEN)
	_style_button($Panel/VBox/MenuButton, RED)

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

	$Panel/VBox/DistanceLabel.text = "%dm" % distance
	$Panel/VBox/StatsHBox/TormentasLabel.text = "\U0001f32a\ufe0f %d" % storms
	$Panel/VBox/StatsHBox/BarroLabel.text = "\U0001f4a7 %d" % bolas
	$Panel/VBox/StatsHBox/KiwiLabel.text = "\U0001f95d %d" % kiwis
	$Panel/VBox/PalitosLabel.text = "\U0001fab5 +%d  (Total: %d)" % [total_palitos, DataManager.palitos_balance]

	var bonus_text := ""
	if bonus_palitos > 0:
		bonus_text += "+%d palitos por hito! " % bonus_palitos
	if bonus_bolas > 0:
		bonus_text += "+%d bolas por record!" % bonus_bolas
	if bonus_text != "":
		$Panel/VBox/BonusPanel.show()
		$Panel/VBox/BonusPanel/BonusLabel.text = bonus_text.strip_edges()

	if old_max >= 0 and distance < old_max:
		var diff := old_max - distance
		if diff <= 50:
			$Panel/VBox/RecordDiffLabel.text = "Te quedaste a %dm del r\u00e9cord!" % diff
		else:
			$Panel/VBox/RecordDiffLabel.text = "Quedaste a %dm del r\u00e9cord" % diff
		$Panel/VBox/RecordDiffLabel.show()
	else:
		$Panel/VBox/RecordDiffLabel.hide()

	var tip: String = TIPS[randi() % TIPS.size()]
	$Panel/VBox/TipPanel/TipLabel.text = "\U0001f4a1 " + tip

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
