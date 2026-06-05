extends CanvasLayer

func _ready() -> void:
	$ColorRect/VBoxContainer/RestartButton.pressed.connect(_on_restart)
	$ColorRect/VBoxContainer/MenuButton.pressed.connect(_on_menu)

func show_screen(distance: int, storms: int = 0, bolas: int = 0, kiwis: int = 0) -> void:
	var palitos := DataManager.calculate_palitos_earned(distance)
	DataManager.add_palitos(palitos)

	$ColorRect/VBoxContainer/DistanceLabel.text = "%dm" % distance
	$ColorRect/VBoxContainer/PalitosLabel.text = "Palitos: +%d  (Total: %d)" % [palitos, DataManager.palitos_balance]
	$ColorRect/VBoxContainer/StatsLabel.text = "Tormentas: %d  |  Barro: %d  |  Kiwis: %d" % [storms, bolas, kiwis]

	visible = true
	$ColorRect.position.y = -1080

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($ColorRect, "position:y", 0.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func(): get_tree().paused = true)

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().paused = false
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")
