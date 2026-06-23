extends CanvasLayer

@onready var distance_label := $DistanceLabel
@onready var max_dist_label := $MaxDistLabel
@onready var minimap := $Minimap
@onready var powerup_label := $PowerUpLabel
@onready var storm_label := $StormLabel
@onready var storm_warning := $StormWarningLabel
@onready var bolas_label := $BolasLabel
@onready var palitos_label := $PalitosLabel
@onready var pause_btn := $PauseBtn
@onready var pause_overlay := $PauseOverlay
@onready var tutorial_overlay := $TutorialOverlay
@onready var tap_arrow := $TutorialOverlay/Panel/TapArrow
@onready var milestone_flash := $MilestoneFlash

var _storm_warning_active := false
var _storm_warning_time := 0.0
const STORM_WARNING_DURATION := 2.0

var _tutorial_timer := 0.0
var _tutorial_arrow_time := 0.0
const TUTORIAL_DURATION := 5.0

var _last_flash_100m := 0
var _heartbeat_time := 0.0
var _last_dist_value := 0
var _idle_time := 0.0

func _process(delta: float) -> void:
	if _tutorial_timer > 0:
		_tutorial_timer -= delta
		tap_arrow.modulate.a = 0.5 + 0.5 * sin(_tutorial_arrow_time * 4.0)
		_tutorial_arrow_time += delta
		if _tutorial_timer <= 0:
			_hide_tutorial()
	if get_tree().paused:
		return
	if _storm_warning_active:
		_storm_warning_time += delta
		if _storm_warning_time >= STORM_WARNING_DURATION:
			show_storm_warning(false)
			return
		var t := sin(_storm_warning_time * 12.0)
		var s := 1.0 + 0.4 * t
		storm_warning.scale = Vector2(s, s)

	var dist := int(distance_label.text.trim_suffix("m"))
	_idle_time += delta
	var idle := 1.0 + 0.012 * sin(_idle_time * 2.5)
	if dist > 0 and DataManager.max_distance > 0 and dist >= DataManager.max_distance - 100 and dist < DataManager.max_distance:
		_heartbeat_time += delta
		idle += 0.03 * sin(_heartbeat_time * 5.0)
		distance_label.modulate = Color(1, 0.85 + 0.15 * sin(_heartbeat_time * 5.0), 0.85 + 0.15 * sin(_heartbeat_time * 5.0))
	else:
		distance_label.modulate = Color.WHITE
		_heartbeat_time = 0.0
	distance_label.scale = Vector2(idle, idle)

func _ready() -> void:
	max_dist_label.text = "Récord: %dm" % DataManager.max_distance
	palitos_label.modulate = Color(1.0, 0.75, 0.06)
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn.pressed.connect(_toggle_pause)
	$PauseOverlay/ContinueBtn.pressed.connect(_toggle_pause)
	$PauseOverlay/QuitBtn.pressed.connect(_quit_to_menu)

# pause stats removed

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_overlay.visible = paused
	pause_btn.visible = not paused

func start_tutorial() -> void:
	tutorial_overlay.visible = true
	pause_btn.visible = false
	_tutorial_timer = TUTORIAL_DURATION
	_tutorial_arrow_time = 0.0
	tap_arrow.modulate.a = 1.0
	get_tree().paused = true

func _hide_tutorial() -> void:
	tutorial_overlay.visible = false
	pause_btn.visible = true
	_tutorial_timer = 0.0
	DataManager.tutorial_done = true
	DataManager.save_data()
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if _tutorial_timer > 0 and (event is InputEventScreenTouch or event is InputEventMouseButton):
		_hide_tutorial()

func _quit_to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	SceneTransition.fade_to_scene("res://scenes/menu/menu.tscn")

func update_distance(meters: int) -> void:
	var prev := int(distance_label.text.trim_suffix("m"))
	distance_label.text = "%dm" % meters
	max_dist_label.text = "Récord: %dm" % DataManager.max_distance
	minimap.set_distance(meters)
	if meters != prev:
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(distance_label, "scale", Vector2(1.12, 1.12), 0.08)
		tween.tween_property(distance_label, "scale", Vector2(1.0, 1.0), 0.25)
	var curr_100 := floori(meters / 100.0)
	if curr_100 > _last_flash_100m:
		_last_flash_100m = curr_100
		_flash_100m()

func _flash_100m() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.25)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(flash)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(flash, "color:a", 0.0, 0.4)
	tween.tween_callback(flash.queue_free)

func update_bolas(amount: int) -> void:
	bolas_label.text = "Barro: %d" % amount
	_pulse_label(bolas_label)

func update_palitos(amount: int) -> void:
	palitos_label.text = "%d" % amount
	_pulse_label(palitos_label)

func _pulse_label(label: Label) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3)

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

func flash_milestone() -> void:
	print("flash_milestone called")
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 0, 0.5)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(flash)
	flash.show()
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(flash, "color:a", 0.0, 1.0)
	tween.tween_callback(flash.queue_free)

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

func set_biome(name: String) -> void:
	minimap.set_distance(int(distance_label.text.trim_suffix("m")), name)
