extends CanvasLayer

var active := false
var _edit_layer := 0
var _background: Node
var _prev_keys := {}

@onready var panel := $Panel
@onready var biome_label := $Panel/BiomeLabel
@onready var layer_label := $Panel/LayerLabel
@onready var offset_label := $Panel/OffsetLabel
@onready var list_label := $Panel/ListLabel
@onready var controls_label := $Panel/ControlsLabel

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	panel.visible = false

func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false

func _pause(do_pause: bool) -> void:
	get_tree().paused = do_pause

func set_background(bg: Node) -> void:
	_background = bg

func _process(_delta: float) -> void:
	if not active or not _background:
		return

	var keys: Array[int] = [KEY_F1, KEY_W, KEY_S, KEY_A, KEY_D, KEY_UP, KEY_DOWN, KEY_R]
	for key in keys:
		var pressed := Input.is_key_pressed(key)
		var was_pressed: bool = _prev_keys.get(key, false)
		if pressed and not was_pressed:
			_handle_key(key)
		_prev_keys[key] = pressed

func _handle_key(key: int) -> void:
	var step := 1
	if Input.is_key_pressed(KEY_SHIFT):
		step = 10

	match key:
		KEY_F1:
			_background.save_overrides()
			active = false
			panel.visible = false
			_pause(false)
			return
		KEY_W:
			var val: float = _background.editor_y_offsets[_edit_layer] if _edit_layer < _background.editor_y_offsets.size() else 0.0
			_background.set_editor_y_offset(_edit_layer, val - step)
		KEY_S:
			var val: float = _background.editor_y_offsets[_edit_layer] if _edit_layer < _background.editor_y_offsets.size() else 0.0
			_background.set_editor_y_offset(_edit_layer, val + step)
		KEY_A:
			var val: float = _background.editor_x_offsets[_edit_layer] if _edit_layer < _background.editor_x_offsets.size() else 0.0
			_background.set_editor_x_offset(_edit_layer, val - step)
		KEY_D:
			var val: float = _background.editor_x_offsets[_edit_layer] if _edit_layer < _background.editor_x_offsets.size() else 0.0
			_background.set_editor_x_offset(_edit_layer, val + step)
		KEY_UP:
			_edit_layer = max(0, _edit_layer - 1)
		KEY_DOWN:
			_edit_layer = min(_background.get_layer_count() - 1, _edit_layer + 1)
		KEY_P:
			_print_values()
		KEY_R:
			_background.reset_editor_offsets()
			_background.save_overrides()

	if key != KEY_F1:
		_update_display()

func _unhandled_input(event: InputEvent) -> void:
	if not active and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		active = true
		panel.visible = true
		_pause(true)
		_edit_layer = 0
		_update_display()
		get_viewport().set_input_as_handled()

func _update_display() -> void:
	if not _background:
		return
	var n: int = _background.get_layer_count()
	var bname: String = _background.get_biome_name()
	biome_label.text = "Bioma: " + bname
	layer_label.text = "Capa: " + str(_edit_layer + 1) + "/" + str(n)
	var yv: float = _background.editor_y_offsets[_edit_layer] if _edit_layer < _background.editor_y_offsets.size() else 0.0
	var xv: float = _background.editor_x_offsets[_edit_layer] if _edit_layer < _background.editor_x_offsets.size() else 0.0
	offset_label.text = "Y: " + ("%+d" % yv) + "   X: " + ("%+d" % xv)

	var lines := ""
	for i in n:
		var yy: float = _background.editor_y_offsets[i] if i < _background.editor_y_offsets.size() else 0.0
		var xx: float = _background.editor_x_offsets[i] if i < _background.editor_x_offsets.size() else 0.0
		var arrow := " ◄" if i == _edit_layer else ""
		lines += str(i) + ": Y" + ("%+d" % yy) + " X" + ("%+d" % xx) + arrow + "\n"
	list_label.text = lines

func _print_values() -> void:
	var n: int = _background.get_layer_count()
	var bname: String = _background.get_biome_name()
	var y_base: Array = _background.get_biome_y_base()
	var parts: Array[String] = []
	for i in n:
		var yy: float = _background.editor_y_offsets[i] if i < _background.editor_y_offsets.size() else 0.0
		var val := int(y_base[i]) + int(yy)
		parts.append(str(val))
	print("\n\"" + bname + "\" y_offsets: [" + ", ".join(parts) + "]")
