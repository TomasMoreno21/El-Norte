extends CanvasLayer

@onready var distance_label := $DistanceLabel
@onready var max_dist_label := $MaxDistLabel
@onready var powerup_label := $PowerUpLabel
@onready var storm_label := $StormLabel
@onready var storm_warning := $StormWarningLabel
@onready var bolas_label := $BolasLabel

var _storm_warning_active := false
var _storm_warning_time := 0.0
const STORM_WARNING_DURATION := 2.0

func _process(delta: float) -> void:
	if _storm_warning_active:
		_storm_warning_time += delta
		if _storm_warning_time >= STORM_WARNING_DURATION:
			show_storm_warning(false)
			return
		var t := sin(_storm_warning_time * 15.0)
		storm_warning.modulate.a = 0.5 + 0.5 * t
		var s := 1.0 + 0.2 * t
		storm_warning.scale = Vector2(s, s)

func _ready() -> void:
	max_dist_label.text = "Récord: %dm" % DataManager.max_distance

func update_distance(meters: int) -> void:
	distance_label.text = "%dm" % meters
	max_dist_label.text = "Récord: %dm" % DataManager.max_distance

func update_bolas(amount: int) -> void:
	bolas_label.text = "Barro: %d" % amount

func update_powerups(shield_remaining: float, turbo_remaining: float, x2: bool, x2p: float = 0.0) -> void:
	var parts := []
	if shield_remaining > 0:
		parts.append("Escudo: %.1fs" % shield_remaining)
	if turbo_remaining > 0:
		parts.append("Turbo: %.1fs" % turbo_remaining)
	if x2:
		parts.append("x2 Barro")
	if x2p > 0:
		parts.append("x2 Palitos: %.1fs" % x2p)
	powerup_label.text = "  ".join(parts)

func show_storm(active: bool) -> void:
	storm_label.visible = active

func show_storm_warning(active: bool) -> void:
	_storm_warning_active = active
	if not active:
		storm_warning.visible = false
		storm_warning.modulate.a = 1.0
		storm_warning.scale = Vector2(1.0, 1.0)
		_storm_warning_time = 0.0
	else:
		storm_warning.visible = true
		_storm_warning_time = 0.0

func show_achievement_popup(logro: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05, 0.85)
	bg.size = Vector2(350, 88)
	bg.position = Vector2(-350, get_viewport().get_visible_rect().size.y - 120)

	var name_lbl := Label.new()
	name_lbl.text = logro["name"]
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	name_lbl.position = Vector2(0, 6)
	name_lbl.size = Vector2(350, 34)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc_lbl := Label.new()
	desc_lbl.text = logro["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.position = Vector2(0, 46)
	desc_lbl.size = Vector2(350, 32)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	bg.add_child(name_lbl)
	bg.add_child(desc_lbl)
	add_child(bg)

	var tween := create_tween()
	tween.tween_property(bg, "position:x", 16.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(2.0)
	tween.tween_property(bg, "position:x", -350.0, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(bg.queue_free)
