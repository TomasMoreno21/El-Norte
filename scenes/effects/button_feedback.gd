extends Button

func _ready() -> void:
	button_down.connect(_on_down)
	button_up.connect(_on_up)

func _on_down() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.08)

func _on_up() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
