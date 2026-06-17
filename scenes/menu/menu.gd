extends Control

func _ready() -> void:
	$Jugar.pressed.connect(_on_jugar)
	$RightBox/Tienda.pressed.connect(_on_tienda)
	$RightBox/Skins.pressed.connect(_on_skins)
	$RightBox/Logros.pressed.connect(_on_logros)
	$Salir.pressed.connect(_on_salir)
	$ResetButton.pressed.connect(_on_reset)
	_animate_menu()
	SceneTransition.fade_in()

func _animate_menu() -> void:
	$Label.modulate.a = 0.0
	$Jugar.modulate.a = 0.0
	$Salir.modulate.a = 0.0
	$RightBox.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property($Label, "modulate:a", 1.0, 0.5)
	tween.tween_property($Jugar, "modulate:a", 1.0, 0.5).set_delay(0.1)
	tween.tween_property($Salir, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property($RightBox, "modulate:a", 1.0, 0.5).set_delay(0.3)

func _on_jugar() -> void:
	DataManager.clear_achievement_popups()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

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
