extends Node2D

@export var obstacle_scene: PackedScene
@export var kiwi_scene: PackedScene
@export var choice_menu_scene: PackedScene
@export var bola_scene: PackedScene
@export var turbo_effect_scene: PackedScene

var distance := 0.0
var difficulty_dist := 0.0
var kiwi_cooldown_timer := 0.0
var shield_active := false
var turbo_active := false
var shield_start_time := 0.0
var turbo_start_time := 0.0
var shield_duration_max := 4.0
var turbo_duration_max := 3.0
var in_storm := false
var _rafaga_progress := 0.0
var storm_time := 0.0
var turbo_effect: CanvasLayer
var next_storm_distance := 500.0
var bird_speed_mult := 1.0
var bird_kiwi_bonus := 0.0
var rafaga_active := false
var rafaga_time := 0.0
var calma_active := false
var calma_time := 0.0
var last_rafaga_distance := 0.0
var last_calma_distance := 0.0
var last_check_dist := 0
var storms_in_run := 0
var run_bolas := 0
var run_kiwis := 0
var x2_palitos_active := false
var x2_palitos_start_time := 0.0
var x2_bolas_active := false
var miniatura_active := false
var miniatura_start_time := 0.0
var _revive_available := true
var _death_old_max := 0

const SPEED_BASE := 550.0
const SPEED_AMP := 650.0
const SPEED_TAU := 2500.0
const INTERVAL_MIN := 0.38
const INTERVAL_AMP := 0.90
const INTERVAL_TAU := 2600.0
const PIXEL_TO_METER := 60.0
const KIWI_COOLDOWN := 20.0
const KIWI_SPAWN_CHANCE := 0.08
const STORM_INTERVAL := 500.0
const STORM_DURATION := 4.0
const STORM_SPEED_BOOST := 1.3
const STORM_INTERVAL_FACTOR := 0.7
const STORM_WARNING_DIST := 50.0
const BOLA_SPAWN_INTERVAL := 6.0
const BOLA_SPAWN_CHANCE := 0.15
const TURBO_OBSTACLE_SPEED_BASE := 1.5
const TURBO_OBSTACLE_SPEED_PER_M := 0.00002
const TURBO_OBSTACLE_SPEED_MAX := 1.7
const TURBO_SPAWN_MULT := 1.5
const RAFAGA_COOLDOWN := 1200.0
const RAFAGA_CHANCE := 0.4
const RAFAGA_DURATION := 5.0
const RAFAGA_BOOST := 1.5
const CALMA_COOLDOWN := 800.0
const CALMA_CHANCE := 0.25
const CALMA_DURATION := 5.0
const REVIVE_COST := 200
const REVIVE_REWIND := 150.0

# Constraint-based obstacle spawning
const MIN_GAP := 90
const SPAWN_MIN_Y := 160.0
const SPAWN_MAX_Y := 920.0
const OBSTACLE_HALF_HEIGHTS := [12.5, 50.0, 27.5]

@onready var spawn_timer := $SpawnTimer
@onready var bola_timer := $BolaTimer
@onready var hud := $HUD
@onready var player := $Player
@onready var death_screen := $DeathScreen
@onready var revive_popup := $RevivePopup
@onready var camera := $Camera2D
@onready var parallax_editor := $ParallaxEditor

var shake_strength := 10
const SHAKE_DECAY := 4.0

func get_base_speed(dist: float) -> float:
	return SPEED_BASE + SPEED_AMP * (1.0 - exp(-dist / SPEED_TAU))

func get_speed(dist: float) -> float:
	var s := get_base_speed(dist)
	if in_storm:
		s *= STORM_SPEED_BOOST
	return s

func get_double_chance(dist: float) -> float:
	return min(0.08 + dist * 0.002, 0.40)

func get_spawn_interval(dist: float) -> float:
	var i: float = INTERVAL_MIN + INTERVAL_AMP * exp(-dist / INTERVAL_TAU)
	if in_storm:
		i *= STORM_INTERVAL_FACTOR
	return i

func get_turbo_obs_speed(dist: float) -> float:
	return min(TURBO_OBSTACLE_SPEED_BASE + dist * TURBO_OBSTACLE_SPEED_PER_M, TURBO_OBSTACLE_SPEED_MAX)

func _ready() -> void:
	spawn_timer.wait_time = get_spawn_interval(0.0)
	spawn_timer.start()
	bola_timer.wait_time = BOLA_SPAWN_INTERVAL
	bola_timer.start()
	player.died.connect(_on_player_died)
	revive_popup.revived.connect(_on_revive)
	revive_popup.rejected.connect(_on_revive_reject)
	hud.update_bolas(DataManager.bolas_balance)
	var mods := DataManager.get_bird_modifiers()
	bird_speed_mult = mods["speed_mult"]
	bird_kiwi_bonus = mods["kiwi_bonus"]
	storms_in_run = 0
	run_bolas = 0
	run_kiwis = 0
	camera.zoom = Vector2(1.2, 1.2)
	if turbo_effect_scene:
		turbo_effect = turbo_effect_scene.instantiate()
		add_child(turbo_effect)
	SceneTransition.fade_in()
	$Background.transition_started.connect(_on_transition_started)
	$Background.transition_ended.connect(_on_transition_ended)
	parallax_editor.set_background($Background)

func start_storm() -> void:
	in_storm = true
	storm_time = 0.0
	shake_strength = 16.0
	AudioManager.play_sfx("storm_start")
	_update_encounter_mode()

func end_storm() -> void:
	in_storm = false
	storm_time = 0.0
	next_storm_distance += STORM_INTERVAL
	DataManager.storms_survived += 1
	storms_in_run += 1
	AudioManager.play_sfx("storm_end")
	var nuevos := DataManager.check_achievements({ "storms_in_run": storms_in_run })
	_show_popups(nuevos)
	if "rey_tormentas" in DataManager.completed_achievements:
		DataManager.add_bolas(1)
		hud.update_bolas(DataManager.bolas_balance)
	_update_encounter_mode()

func start_rafaga() -> void:
	rafaga_active = true
	rafaga_time = 0.0
	_rafaga_progress = 0.0
	last_rafaga_distance = distance
	_update_encounter_mode()

func end_rafaga() -> void:
	rafaga_active = false
	_update_encounter_mode()

func start_calma() -> void:
	calma_active = true
	calma_time = 0.0
	last_calma_distance = distance
	_update_encounter_mode()

func end_calma() -> void:
	calma_active = false
	DataManager.calmas_survived += 1
	_update_encounter_mode()

func _update_encounter_mode() -> void:
	if not turbo_effect:
		return
	if calma_active:
		turbo_effect.set_calma_mode()
	elif in_storm:
		turbo_effect.set_storm_mode()
	elif rafaga_active:
		turbo_effect.set_rafaga_mode(_rafaga_progress)
	elif turbo_active:
		turbo_effect.set_turbo_mode()
	else:
		turbo_effect.set_normal_mode()

func _on_player_died() -> void:
	DataManager.deaths += 1
	_death_old_max = DataManager.max_distance
	DataManager.max_distance = max(DataManager.max_distance, int(distance))
	DataManager.mark_bird_used(DataManager.active_bird)
	var nuevos := DataManager.check_achievements({ "distance": int(distance), "storms_in_run": storms_in_run })
	if DataManager.palitos_balance >= REVIVE_COST and _revive_available:
		_revive_available = false
		revive_popup.show_revive(REVIVE_COST)
		get_tree().paused = true
	else:
		death_screen.show_screen(int(distance), storms_in_run, run_bolas, run_kiwis, _death_old_max)
	_show_popups(nuevos)

func _process(delta: float) -> void:
	if not player.alive:
		return

	if not in_storm and not $Background.in_transition and distance >= next_storm_distance:
		start_storm()
		hud.show_storm_warning(false)
	elif in_storm:
		storm_time += delta
		if storm_time >= STORM_DURATION:
			end_storm()
	else:
		var storm_dist := next_storm_distance
		var warning := distance >= storm_dist - STORM_WARNING_DIST and distance < storm_dist
		hud.show_storm_warning(warning)

	if not rafaga_active and not calma_active and not in_storm and distance - last_rafaga_distance >= RAFAGA_COOLDOWN:
		last_rafaga_distance = distance
		if randf() < RAFAGA_CHANCE:
			start_rafaga()

	if not calma_active and not rafaga_active and not in_storm and distance >= 500 and distance - last_calma_distance >= CALMA_COOLDOWN:
		last_calma_distance = distance
		if randf() < CALMA_CHANCE:
			start_calma()

	kiwi_cooldown_timer += delta

	var current_speed := get_speed(difficulty_dist)
	var speed_bonus := 1.0 + DataManager.get_upgrade_level("speed") * 0.05
	var turbo_mult := 1.0
	var rafaga_mult := 1.0
	var palitos_dist_mult := 1.0
	var now := Time.get_ticks_msec()
	var shield_remaining := 0.0
	var turbo_remaining := 0.0
	var x2p_remaining := 0.0
	var mini_remaining := 0.0

	if rafaga_active:
		rafaga_time += delta
		var progress: float
		if rafaga_time < 1.0:
			progress = rafaga_time / 1.0
		elif rafaga_time < RAFAGA_DURATION - 1.0:
			progress = 1.0
		elif rafaga_time < RAFAGA_DURATION:
			progress = (RAFAGA_DURATION - rafaga_time) / 1.0
		else:
			progress = 0.0
			end_rafaga()
		rafaga_mult = 1.0 + (RAFAGA_BOOST - 1.0) * progress
		_rafaga_progress = progress
		_update_encounter_mode()

	if calma_active:
		calma_time += delta
		if calma_time >= CALMA_DURATION:
			end_calma()

	if shield_active:
		shield_remaining = shield_duration_max - (now - shield_start_time) / 1000.0
		if shield_remaining <= 0:
			shield_active = false
			shield_remaining = 0.0
			player.set_shield(false)

	if turbo_active:
		turbo_remaining = turbo_duration_max - (now - turbo_start_time) / 1000.0
		if turbo_remaining <= 0:
			turbo_active = false
			turbo_remaining = 0.0
			_update_encounter_mode()
		else:
			turbo_mult = 2.0

	if x2_palitos_active:
		x2p_remaining = 4.0 - (now - x2_palitos_start_time) / 1000.0
		if x2p_remaining <= 0:
			x2_palitos_active = false
			x2p_remaining = 0.0
		else:
			palitos_dist_mult = 2.0

	if miniatura_active:
		mini_remaining = 3.0 - (now - miniatura_start_time) / 1000.0
		if mini_remaining <= 0:
			miniatura_active = false
			mini_remaining = 0.0
			player.set_miniatura(false)

	var raw_delta := current_speed * delta / PIXEL_TO_METER
	difficulty_dist += raw_delta
	distance += raw_delta * speed_bonus * bird_speed_mult * turbo_mult * rafaga_mult * palitos_dist_mult
	hud.update_distance(int(distance))
	var palitos_rate := 1 + DataManager.get_upgrade_level("palitos_base")
	var bird_palitos_mult: float = DataManager.get_bird_modifiers()["palitos_mult"]
	var run_palitos := int(distance / 10) * palitos_rate * bird_palitos_mult
	if x2_palitos_active:
		run_palitos *= 2
	hud.update_palitos(int(run_palitos))
	var curr_dist := int(distance)
	if curr_dist >= last_check_dist + 25:
		last_check_dist = curr_dist
		var nuevos := DataManager.check_achievements({ "distance": curr_dist })
		_show_popups(nuevos)
	hud.update_powerups(shield_remaining, turbo_remaining, x2_bolas_active, x2p_remaining)
	hud.show_storm(in_storm)
	$Background.set_run_distance(distance, turbo_mult)
	var turbo_spawn_mult := TURBO_SPAWN_MULT if turbo_active else 1.0
	spawn_timer.wait_time = get_spawn_interval(difficulty_dist) * turbo_spawn_mult

	var target_shake := 0.0
	if in_storm:
		target_shake = 8.0
	elif turbo_active:
		target_shake = 5.0

	if shake_strength < target_shake:
		shake_strength = min(shake_strength + 60.0 * delta, target_shake)
	elif shake_strength > target_shake:
		shake_strength = max(shake_strength - SHAKE_DECAY * delta, target_shake)

	if shake_strength > 0.0:
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), 0.0)
	else:
		camera.offset = Vector2.ZERO

func _safe_obstacle_y(shape_type: int) -> float:
	var half_h: float = OBSTACLE_HALF_HEIGHTS[shape_type]
	var min_y := SPAWN_MIN_Y + half_h
	var max_y := SPAWN_MAX_Y - half_h

	var gap_below_max := max_y - MIN_GAP
	var gap_above_min := min_y + MIN_GAP

	var opts: Array[float] = []
	if gap_below_max >= min_y:
		opts.append(randf_range(min_y, gap_below_max))
	if gap_above_min <= max_y:
		opts.append(randf_range(gap_above_min, max_y))

	if opts.is_empty():
		return randf_range(min_y, max_y)
	return opts[randi() % opts.size()]

func _safe_double_y(shape_a: int, shape_b: int) -> Vector2:
	var half_a: float = OBSTACLE_HALF_HEIGHTS[shape_a]
	var half_b: float = OBSTACLE_HALF_HEIGHTS[shape_b]
	var min_y: float = SPAWN_MIN_Y + max(half_a, half_b)
	var max_y: float = SPAWN_MAX_Y - max(half_a, half_b)

	var mid_low: float = max(min_y, min_y + half_a + half_b + MIN_GAP)
	var mid_high: float = min(max_y, max_y - half_a - half_b - MIN_GAP)

	if mid_low <= max_y - half_b - MIN_GAP:
		var a_y := randf_range(min_y, mid_low)
		var b_y := randf_range(a_y + half_a + half_b + MIN_GAP, max_y)
		return Vector2(a_y, b_y)

	return Vector2(_safe_obstacle_y(shape_a), _safe_obstacle_y(shape_b))

func _spawn_obstacle(shape_type: int, speed: float) -> void:
	_spawn_obstacle_at(shape_type, speed, _safe_obstacle_y(shape_type))

func _spawn_obstacle_at(shape_type: int, speed: float, y: float) -> void:
	var obs := obstacle_scene.instantiate()
	obs.speed = speed
	obs.shape_type = shape_type
	obs.position = Vector2(2100, y)
	obs.add_to_group("obstacle")
	add_child(obs)

func _on_spawn_timer_timeout() -> void:
	if not obstacle_scene or not player.alive or calma_active or $Background.in_transition:
		return

	if kiwi_scene and kiwi_cooldown_timer >= KIWI_COOLDOWN:
		var prob := KIWI_SPAWN_CHANCE + bird_kiwi_bonus + DataManager.get_upgrade_level("kiwi") * 0.02
		if randf() < prob:
			var kiwi := kiwi_scene.instantiate()
			kiwi.speed = get_speed(difficulty_dist)
			kiwi.position = Vector2(2100, randf_range(260, 820))
			kiwi.collected.connect(_on_kiwi_collected)
			kiwi.add_to_group("kiwi")
			add_child(kiwi)
			kiwi_cooldown_timer = 0.0
			return

	var turbo_obs_speed := get_turbo_obs_speed(difficulty_dist) if turbo_active else 1.0
	var storm_mult_obs := STORM_SPEED_BOOST if in_storm else 1.0
	var combined_obs_mult: float = turbo_obs_speed * storm_mult_obs
	if in_storm and turbo_active:
		combined_obs_mult = min(combined_obs_mult, 1.5)
	var base_speed: float = get_base_speed(difficulty_dist) * combined_obs_mult

	var shape_a := randi() % 3
	if randf() < get_double_chance(difficulty_dist):
		var shape_b := randi() % 3
		var positions := _safe_double_y(shape_a, shape_b)
		_spawn_obstacle_at(shape_a, base_speed, positions.x)
		_spawn_obstacle_at(shape_b, base_speed, positions.y)
	else:
		_spawn_obstacle(shape_a, base_speed)

func _on_kiwi_collected() -> void:
	run_kiwis += 1
	AudioManager.play_sfx("kiwi_appear")
	var menu := choice_menu_scene.instantiate()
	menu.power_up_selected.connect(_on_power_up_selected)
	add_child(menu)
	get_tree().paused = true

func _on_power_up_selected(type: String) -> void:
	var nuevos := DataManager.accept_kiwi()
	_show_popups(nuevos)
	match type:
		"shield":
			shield_active = true
			shield_start_time = Time.get_ticks_msec()
			shield_duration_max = 4.0 + DataManager.get_upgrade_level("shield_duration") * 0.2
			player.set_shield(true)
		"turbo":
			turbo_active = true
			turbo_start_time = Time.get_ticks_msec()
			turbo_duration_max = 6.0 + DataManager.get_upgrade_level("turbo_duration") * 0.2
			shake_strength = 10.0
			_update_encounter_mode()
		"x2_bolas":
			x2_bolas_active = true
		"bola_extra":
			DataManager.add_bolas(1)
			run_bolas += 1
			hud.update_bolas(DataManager.bolas_balance)
		"x2_palitos":
			x2_palitos_active = true
			x2_palitos_start_time = Time.get_ticks_msec()
		"miniatura":
			miniatura_active = true
			miniatura_start_time = Time.get_ticks_msec()
			player.set_miniatura(true)

func _on_bola_timer_timeout() -> void:
	if not player.alive or not bola_scene or $Background.in_transition:
		return
	if randf() >= BOLA_SPAWN_CHANCE:
		return

	var bola := bola_scene.instantiate()
	bola.speed = get_speed(difficulty_dist)
	bola.position = Vector2(2100, randf_range(220, 860))
	bola.amount = 2 if x2_bolas_active else 1
	bola.collected.connect(_on_bola_collected)
	bola.add_to_group("bola")
	add_child(bola)

func _on_bola_collected() -> void:
	var amount := 2 if x2_bolas_active else 1
	DataManager.add_bolas(amount)
	run_bolas += amount
	AudioManager.play_sfx("collect")
	var nuevos := DataManager.check_achievements({})
	_show_popups(nuevos)
	hud.update_bolas(DataManager.bolas_balance)
	if x2_bolas_active:
		x2_bolas_active = false

func _show_popups(nuevos: Array) -> void:
	if nuevos.is_empty():
		return
	for a in nuevos:
		AudioManager.play_sfx("achievement")
		DataManager.show_achievement_popup(a)
		await get_tree().create_timer(2.8).timeout

func _on_revive() -> void:
	AudioManager.play_sfx("revive")
	Engine.time_scale = 1.0
	DataManager.palitos_balance -= REVIVE_COST
	DataManager.revives_used += 1
	var nuevos_revive := DataManager.check_achievements({})
	_show_popups(nuevos_revive)
	distance = max(distance - REVIVE_REWIND, 0.0)
	difficulty_dist = max(difficulty_dist - REVIVE_REWIND, 0.0)
	next_storm_distance = floor(distance / STORM_INTERVAL) * STORM_INTERVAL + STORM_INTERVAL
	last_rafaga_distance = distance
	last_calma_distance = distance

	for obs in get_tree().get_nodes_in_group("obstacle"):
		obs.queue_free()
	for k in get_tree().get_nodes_in_group("kiwi"):
		k.queue_free()
	for b in get_tree().get_nodes_in_group("bola"):
		b.queue_free()

	if in_storm:
		in_storm = false
		storm_time = 0.0
		_update_encounter_mode()
	if rafaga_active:
		rafaga_active = false
		_update_encounter_mode()
	if calma_active:
		calma_active = false
		_update_encounter_mode()

	shield_active = false
	turbo_active = false
	x2_palitos_active = false
	x2_bolas_active = false
	miniatura_active = false
	kiwi_cooldown_timer = 0.0

	player.reset()
	revive_popup.visible = false
	spawn_timer.wait_time = get_spawn_interval(difficulty_dist)
	get_tree().paused = false

func _on_revive_reject() -> void:
	Engine.time_scale = 1.0
	revive_popup.visible = false
	death_screen.show_screen(int(distance), storms_in_run, run_bolas, run_kiwis, _death_old_max)

func _on_transition_started(msg: String) -> void:
	hud.show_transition_message(msg)

func _on_transition_ended(_biome_name: String) -> void:
	hud.hide_transition_message()
