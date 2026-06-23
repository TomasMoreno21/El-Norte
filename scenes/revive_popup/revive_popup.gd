extends CanvasLayer

signal revived
signal rejected

@onready var cost_label: RichTextLabel = $Panel/VBox/CostLabel
@onready var revive_btn := $Panel/VBox/ButtonRow/ReviveBtn
@onready var reject_btn := $Panel/VBox/ButtonRow/RejectBtn

var _countdown := 10
var _countdown_timer: Timer

func _ready() -> void:
	var border := ColorRect.new()
	border.name = "TopBorder"
	border.color = Color(0.86, 0.27, 0.16)
	border.anchor_left = 0.0
	border.anchor_right = 1.0
	border.offset_bottom = 4.0
	border.mouse_filter = 2
	$Panel.add_child(border)

	$Overlay.color = Color(0, 0, 0, 0.75)
	$Panel/VBox/PalitosLabel.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))

	var countdown_lbl := Label.new()
	countdown_lbl.name = "CountdownLabel"
	countdown_lbl.add_theme_font_size_override("font_size", 28)
	countdown_lbl.add_theme_color_override("font_color", Color(0.86, 0.27, 0.16))
	countdown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var idx := cost_label.get_index() + 1
	$Panel/VBox.add_child(countdown_lbl)
	$Panel/VBox.move_child(countdown_lbl, idx)

	_style_button(revive_btn, Color(0.15, 0.5, 0.15))
	_style_button(reject_btn, Color(0.86, 0.27, 0.16))
	revive_btn.add_theme_font_size_override("font_size", 44)
	reject_btn.add_theme_font_size_override("font_size", 36)
	revive_btn.custom_minimum_size = Vector2(0, 64)
	reject_btn.custom_minimum_size = Vector2(0, 56)

	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.one_shot = false
	_countdown_timer.timeout.connect(_countdown_tick)
	add_child(_countdown_timer)

	revive_btn.pressed.connect(_on_revive)
	reject_btn.pressed.connect(_on_reject)

func _style_button(btn: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.15)
	hover.corner_radius_top_left = 6
	hover.corner_radius_top_right = 6
	hover.corner_radius_bottom_left = 6
	hover.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("hover", hover)

func show_revive(cost: int) -> void:
	cost_label.text = "[center]Revivir por [color=#e6b800]%d[/color] palitos?[/center]" % cost
	$Panel/VBox/PalitosLabel.text = "Palitos: %d" % DataManager.palitos_balance
	_countdown = 5
	$Panel/VBox/CountdownLabel.text = str(_countdown)
	_countdown_timer.start()
	visible = true

func _countdown_tick() -> void:
	_countdown -= 1
	$Panel/VBox/CountdownLabel.text = str(_countdown)
	if _countdown <= 0:
		_countdown_timer.stop()
		rejected.emit()

func _on_revive() -> void:
	_countdown_timer.stop()
	revived.emit()

func _on_reject() -> void:
	_countdown_timer.stop()
	rejected.emit()
