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
	$ColorRect/VBoxContainer/RestartButton.pressed.connect(_on_restart)
	$ColorRect/VBoxContainer/MenuButton.pressed.connect(_on_menu)

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

	var bonus_text := ""
	if bonus_palitos > 0:
		bonus_text += "+%d palitos por hito! " % bonus_palitos
	if bonus_bolas > 0:
		bonus_text += "+%d bolas por record!" % bonus_bolas
	if bonus_text != "":
		$ColorRect/VBoxContainer/BonusLabel.text = bonus_text.strip_edges()
		$ColorRect/VBoxContainer/BonusLabel.visible = true

	var tip: String = TIPS[randi() % TIPS.size()]
	$ColorRect/VBoxContainer/TipLabel.text = "💡 " + tip

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
