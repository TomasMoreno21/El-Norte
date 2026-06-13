extends CanvasLayer

func _ready() -> void:
	$ColorRect/VBoxContainer/RestartButton.pressed.connect(_on_restart)
	$ColorRect/VBoxContainer/MenuButton.pressed.connect(_on_menu)

func show_screen(distance: int, storms: int = 0, bolas: int = 0, kiwis: int = 0) -> void:
	var palitos := DataManager.calculate_palitos_earned(distance)
	var nuevos := DataManager.add_palitos(palitos)
	for a in nuevos:
		DataManager.show_achievement_popup(a)

	$ColorRect/VBoxContainer/DistanceLabel.text = "%dm" % distance
	$ColorRect/VBoxContainer/PalitosLabel.text = "Palitos: +%d  (Total: %d)" % [palitos, DataManager.palitos_balance]
	$ColorRect/VBoxContainer/StatsLabel.text = "Tormentas: %d  |  Barro: %d  |  Kiwis: %d" % [storms, bolas, kiwis]

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
