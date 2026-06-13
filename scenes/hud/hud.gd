extends CanvasLayer

@onready var distance_label := $DistanceLabel
@onready var max_dist_label := $MaxDistLabel
@onready var powerup_label := $PowerUpLabel
@onready var storm_label := $StormLabel
@onready var storm_warning := $StormWarningLabel
@onready var bolas_label := $BolasLabel
@onready var palitos_label := $PalitosLabel

var _storm_warning_active := false
var _storm_warning_time := 0.0
const STORM_WARNING_DURATION := 2.0

func _process(delta: float) -> void:
	if _storm_warning_active:
		_storm_warning_time += delta
		if _storm_warning_time >= STORM_WARNING_DURATION:
			show_storm_warning(false)
			return
		var t := sin(_storm_warning_time * 12.0)
		var s := 1.0 + 0.4 * t
		storm_warning.scale = Vector2(s, s)

func _ready() -> void:
	max_dist_label.text = "Récord: %dm" % DataManager.max_distance

func update_distance(meters: int) -> void:
	distance_label.text = "%dm" % meters
	max_dist_label.text = "Récord: %dm" % DataManager.max_distance

func update_bolas(amount: int) -> void:
	bolas_label.text = "Barro: %d" % amount

func update_palitos(amount: int) -> void:
	palitos_label.text = " %d" % amount

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




func show_transition_message(text: String) -> void:
	$TransitionLabel.text = text
	$TransitionLabel.visible = true
	$TransitionLabel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property($TransitionLabel, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

func hide_transition_message() -> void:
	var tween := create_tween()
	tween.tween_property($TransitionLabel, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func(): $TransitionLabel.visible = false)
