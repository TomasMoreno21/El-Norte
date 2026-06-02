extends Control

func _ready() -> void:
	$Jugar.pressed.connect(_on_jugar)
	$RightBox/Tienda.pressed.connect(_on_tienda)
	$RightBox/Skins.pressed.connect(_on_skins)
	$RightBox/Logros.pressed.connect(_on_logros)
	$Salir.pressed.connect(_on_salir)
	$ResetButton.pressed.connect(_on_reset)

func _on_jugar() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_tienda() -> void:
	get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")

func _on_skins() -> void:
	get_tree().change_scene_to_file("res://scenes/skins/skins.tscn")

func _on_logros() -> void:
	get_tree().change_scene_to_file("res://scenes/achievements/achievements.tscn")

func _on_salir() -> void:
	get_tree().quit()

func _on_reset() -> void:
	DataManager.reset_data()
