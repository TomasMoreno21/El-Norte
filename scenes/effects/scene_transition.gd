extends CanvasLayer

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
	DataManager.clear_achievement_popups()
	_is_transitioning = true
	_overlay.visible = true
	_overlay.modulate.a = 0.0

	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.15)
	tween.tween_callback(_change_scene.bind(scene_path))
	await get_tree().create_timer(1.0).timeout
	_change_scene(scene_path)

func _change_scene(path: String) -> void:
	if not _is_transitioning:
		return
	_is_transitioning = false
	get_tree().change_scene_to_file(path)

func fade_in() -> void:
	_overlay.visible = true
	_overlay.modulate.a = 1.0
	var tween := create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		_overlay.visible = false
		_is_transitioning = false
	)
