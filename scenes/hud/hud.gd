extends CanvasLayer

@onready var distance_label := $DistanceLabel
@onready var max_dist_label := $MaxDistLabel
@onready var powerup_label := $PowerUpLabel
@onready var storm_label := $StormLabel
@onready var storm_warning := $StormWarningLabel
@onready var bolas_label := $BolasLabel
@onready var palitos_label := $PalitosLabel
@onready var milestone_label := $MilestoneLabel
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
var _pause_stats_labels: Array[Label] = []
var _pause_stats_visible := false

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

func _ready() -> void:
	max_dist_label.text = "Récord: %dm" % DataManager.max_distance
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn.pressed.connect(_toggle_pause)
	$PauseOverlay/ContinueBtn.pressed.connect(_toggle_pause)
	$PauseOverlay/QuitBtn.pressed.connect(_quit_to_menu)
	_setup_pause_stats()

func _setup_pause_stats() -> void:
	var labels_data := ["Distancia: 0m", "Barro: 0", "Palitos: 0", "Tormentas: 0", "Kiwis: 0"]
	var y := 300
	for text in labels_data:
		var lbl := Label.new()
		lbl.text = text
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(0, y)
		lbl.size = Vector2(1920, 30)
		pause_overlay.add_child(lbl)
		_pause_stats_labels.append(lbl)
		y += 36

func _update_pause_stats(dist: int, bolas: int, palitos: int, storms: int, kiwis: int) -> void:
	if _pause_stats_labels.size() >= 5:
		_pause_stats_labels[0].text = "Distancia: %dm" % dist
		_pause_stats_labels[1].text = "Barro: %d" % bolas
		_pause_stats_labels[2].text = "Palitos: %d" % palitos
		_pause_stats_labels[3].text = "Tormentas: %d" % storms
		_pause_stats_labels[4].text = "Kiwis: %d" % kiwis

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
	_pulse_label(distance_label)
	if meters / 100 > _last_flash_100m:
		_last_flash_100m = meters / 100
		_flash_100m()

func _flash_100m() -> void:
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.08)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func update_next_milestone(meters: int) -> void:
	var milestones := [500, 1000, 2200, 4600, 10000]
	var next := -1
	for m in milestones:
		if meters < m:
			next = m
			break
	if next > 0:
		var dist_remaining := next - meters
		milestone_label.text = "Siguiente hito: %dm  (falta %dm)" % [next, dist_remaining]
		milestone_label.visible = true
	else:
		milestone_label.visible = false

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
	var strips := [milestone_flash.get_node("Top"), milestone_flash.get_node("Bottom"), milestone_flash.get_node("Left"), milestone_flash.get_node("Right")]
	milestone_flash.visible = true
	for s in strips:
		s.modulate.a = 0.2
	var tween := create_tween()
	tween.set_parallel(true)
	for s in strips:
		tween.tween_property(s, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): milestone_flash.visible = false)

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
