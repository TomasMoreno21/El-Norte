extends CanvasLayer

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
