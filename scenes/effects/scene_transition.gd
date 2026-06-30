extends CanvasLayer

signal fade_in_finished

var _overlay: ColorRect
var _is_transitioning := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	add_child(_overlay)

func fade_to_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_overlay.visible = true
	_overlay.modulate.a = 0.0

	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.15)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file(scene_path)

func fade_in() -> void:
	_is_transitioning = false
	_overlay.visible = true
	_overlay.modulate.a = 1.0

	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.15)
	await tween.finished
	_overlay.visible = false
	fade_in_finished.emit()
