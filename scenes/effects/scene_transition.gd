extends CanvasLayer

var _overlay: ColorRect
var _is_transitioning := false

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)

func fade_to_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	DataManager.clear_achievement_popups()
	_is_transitioning = true
	_overlay.visible = true
	_overlay.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.15)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

func fade_in() -> void:
	_overlay.visible = true
	_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		_overlay.visible = false
		_is_transitioning = false
	)
