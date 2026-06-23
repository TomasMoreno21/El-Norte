extends CanvasLayer

signal revived
signal rejected

const COUNTDOWN_TIME := 5
const RED := Color(0.86, 0.27, 0.16)
const GREEN := Color(0.3, 0.7, 0.3)

var _countdown := COUNTDOWN_TIME

@onready var cost_label := $Panel/VBox/CostLabel
@onready var countdown_label := $Panel/VBox/CountdownLabel
@onready var revive_btn := $Panel/VBox/ReviveBtn
@onready var reject_btn := $Panel/VBox/RejectBtn

func _ready() -> void:
	revive_btn.pressed.connect(_on_revive)
	reject_btn.pressed.connect(_on_reject)
	_style_button(revive_btn, GREEN)
	_style_button(reject_btn, RED)

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
	_countdown = COUNTDOWN_TIME
	cost_label.text = "Revivir por %d palitos?" % cost
	countdown_label.text = "Te quedan %d segundos" % _countdown
	visible = true
	_start_countdown()

func _start_countdown() -> void:
	while _countdown > 0:
		await get_tree().create_timer(1.0).timeout
		_countdown -= 1
		if not visible:
			return
		countdown_label.text = "Te quedan %d segundos" % _countdown
	if visible:
		rejected.emit()

func _on_revive() -> void:
	revived.emit()

func _on_reject() -> void:
	rejected.emit()
