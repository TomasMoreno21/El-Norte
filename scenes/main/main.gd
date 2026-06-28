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
enum EventType { REAR_WAVE, FRONT_WAVE, STORM, WALL }
const EVENT_INTERVAL_MIN := 200.0
const EVENT_INTERVAL_MAX := 400.0
var _next_event_type := -1
var _next_event_distance := 0.0
var _last_event_type := -1
var bird_speed_mult := 1.0
var bird_kiwi_bonus := 0.0
var bird_kiwi_cooldown_mult := 1.0
var rafaga_active := false
var rafaga_time := 0.0
var calma_active := false
var calma_time := 0.0
var lluvia_active := false
var lluvia_time := 0.0
var _lluvia_spawn_timer := 0.0
var _lluvia_bola_top := true
var last_rafaga_distance := 0.0
var last_calma_distance := 0.0
var last_lluvia_distance := 0.0
var last_check_dist := 0
var major_events_in_run := 0
var run_bolas := 0
var run_kiwis := 0
var x2_palitos_active := false
var _last_milestone_idx := 0
const MILESTONES := [500, 1000, 2200, 4600]
var x2_palitos_start_time := 0.0
var x2_bolas_active := false
var miniatura_active := false
var miniatura_start_time := 0.0
var miniatura_speed_mult := 1.0
var _revive_available := true
var _death_old_max := 0
var _contra_viento_active := false
var _contra_viento_time := 0.0
var _rear_wave_active := false
var _rear_wave_phase := 0
var _rear_wave_timer := 0.0
var _rear_y := 540.0
var _wave_active := false
var _wave_phase := 0
enum WaveState { WARN, POST }
var _wave_timer := 0.0
var _wave_state := WaveState.WARN
var _wave_lane_ys: Array[float] = []
var _wall_active := false
var _wall_phase := 0
var _wall_timer := 0.0
var _wall_gap_y := 540.0
var _wall_total_waves := 1
var _wall_current_wave := 0
var _wall_warnings: Array[ColorRect] = []
const CONTRA_VIENTO_DURATION := 10.0
const CONTRA_VIENTO_COOLDOWN := 2000.0
var _last_contra_viento_distance := 0.0
var _current_biome := "Cordillera"
var _heat_overlay: ColorRect
var _rain_particles: GPUParticles2D

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
const BOLA_SPAWN_CHANCE := 0.07
const TURBO_OBSTACLE_SPEED_BASE := 1.5
const TURBO_OBSTACLE_SPEED_PER_M := 0.00002
const TURBO_OBSTACLE_SPEED_MAX := 1.7
const TURBO_SPAWN_MULT := 1.5
const RAFAGA_COOLDOWN := 1200.0
const RAFAGA_CHANCE := 0.4
const RAFAGA_DURATION := 8.0
const RAFAGA_BOOST := 1.5
const REAR_INTERVAL := 600.0
const REAR_SPEED := 900.0
const WAVE_INTERVAL := 600.0
const WAVE_COUNT := 4
const WALL_GAP_SIZE := 190
const WALL_SPEED_MULT := 1.3
const WALL_WARN_DURATION := 1.5
const WALL_CLEAR_DELAY := 3.0
const CALMA_COOLDOWN := 800.0
const CALMA_CHANCE := 0.25
const CALMA_DURATION := 6.0
const LLUVIA_INTERVAL := 2500.0
const LLUVIA_CHANCE := 0.15
const LLUVIA_DURATION := 8.0
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
	return min(0.04 + dist * 0.001, 0.25)

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
	player.flapped.connect(_on_player_flapped)
	revive_popup.revived.connect(_on_revive)
	revive_popup.rejected.connect(_on_revive_reject)
	hud.update_bolas(DataManager.bolas_balance)
	var mods := DataManager.get_bird_modifiers()
	bird_speed_mult = mods["speed_mult"]
	bird_kiwi_bonus = mods["kiwi_bonus"]
	bird_kiwi_cooldown_mult = mods.get("kiwi_cooldown_mult", 1.0)
	major_events_in_run = 0
	run_bolas = 0
	run_kiwis = 0
	_last_milestone_idx = 0
	camera.zoom = Vector2(1.2, 1.2)
	if turbo_effect_scene:
		turbo_effect = turbo_effect_scene.instantiate()
		add_child(turbo_effect)
	SceneTransition.fade_in()
	AudioManager.start_ambient_wind()
	$Background.transition_started.connect(_on_transition_started)
	$Background.transition_ended.connect(_on_transition_ended)
	parallax_editor.set_background($Background)
	if not DataManager.tutorial_done:
		hud.start_tutorial()
	_setup_biome_effects()
	_schedule_next_event()

func start_storm() -> void:
	in_storm = true
	storm_time = 0.0
	shake_strength = 16.0
	var mods := DataManager.get_bird_modifiers()
	player.storm_flap_override = -340 / mods.get("storm_flap_mult", 1.0)
	AudioManager.start_storm_wind()
	_update_encounter_mode()
	_update_existing_obstacle_speeds()

func end_storm() -> void:
	in_storm = false
	storm_time = 0.0
	player.end_storm_gradual()
	_schedule_next_event()
	DataManager.major_events_total += 1
	major_events_in_run += 1
	AudioManager.stop_storm_wind()
	_update_existing_obstacle_speeds()
	var nuevos := DataManager.check_achievements({ "major_events_in_run": major_events_in_run })
	_show_popups(nuevos)
	_update_encounter_mode()

func _schedule_next_event() -> void:
	var types := [EventType.REAR_WAVE, EventType.FRONT_WAVE, EventType.STORM, EventType.WALL]
	if _last_event_type >= 0:
		types.erase(_last_event_type)
	_next_event_type = types[randi() % types.size()]
	_last_event_type = _next_event_type
	_next_event_distance = distance + randf_range(EVENT_INTERVAL_MIN, EVENT_INTERVAL_MAX)

func start_rafaga() -> void:
	rafaga_active = true
	rafaga_time = 0.0
	_rafaga_progress = 0.0
	last_rafaga_distance = distance
	hud.show_event_text("¡RÁFAGA!", true)
	_update_encounter_mode()

func end_rafaga() -> void:
	rafaga_active = false
	hud.hide_event_text()
	_update_encounter_mode()

func start_calma() -> void:
	calma_active = true
	calma_time = 0.0
	last_calma_distance = distance
	hud.show_event_text("¡CALMA!", true)
	_update_encounter_mode()

func end_calma() -> void:
	calma_active = false
	DataManager.calmas_survived += 1
	hud.hide_event_text()
	_update_encounter_mode()

func start_lluvia() -> void:
	lluvia_active = true
	lluvia_time = 0.0
	_lluvia_spawn_timer = 0.0
	hud.show_event_text("¡LLUVIA DE BARRO!", true)
	_update_encounter_mode()

func _spawn_lluvia_bola() -> void:
	_lluvia_spawn_timer += get_process_delta_time()
	if _lluvia_spawn_timer < 1.0:
		return
	_lluvia_spawn_timer = 0.0
	if not bola_scene:
		return
	var bola := bola_scene.instantiate()
	bola.speed = get_speed(difficulty_dist)
	if _lluvia_bola_top:
		bola.position = Vector2(2100, randf_range(700, 900))
	else:
		bola.position = Vector2(2100, randf_range(250, 450))
	_lluvia_bola_top = not _lluvia_bola_top
	bola.amount = 2 if x2_bolas_active else 1
	bola.collected.connect(_on_bola_collected)
	bola.add_to_group("bola")
	add_child(bola)

func end_lluvia() -> void:
	lluvia_active = false
	hud.hide_event_text()
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
	elif _contra_viento_active:
		turbo_effect.set_storm_mode()
	elif turbo_active:
		turbo_effect.set_turbo_mode()
	else:
		turbo_effect.set_normal_mode()

func _on_player_flapped() -> void:
	if in_storm or turbo_active:
		return
	shake_strength = 10.0

func _on_player_died() -> void:
	AudioManager.stop_ambient_wind()
	DataManager.deaths += 1
	_death_old_max = DataManager.max_distance
	DataManager.max_distance = max(DataManager.max_distance, int(distance))
	DataManager.mark_bird_used(DataManager.active_bird)
	DataManager.mark_bird_distance(DataManager.active_bird, int(distance))
	var nuevos := DataManager.check_achievements({ "distance": int(distance), "major_events_in_run": major_events_in_run })
	if DataManager.palitos_balance >= REVIVE_COST and _revive_available:
		_revive_available = false
		revive_popup.show_revive(REVIVE_COST)
		get_tree().paused = true
	else:
		death_screen.show_screen(int(distance), major_events_in_run, run_bolas, run_kiwis, _death_old_max)
	_show_popups(nuevos)

func _process(delta: float) -> void:
	if not player.alive:
		return

	if in_storm:
		storm_time += delta
		if storm_time >= STORM_DURATION:
			end_storm()
	elif _next_event_type == EventType.STORM:
		var warning := distance >= _next_event_distance - STORM_WARNING_DIST
		hud.show_storm_warning(warning)
		if distance >= _next_event_distance and not $Background.in_transition and not rafaga_active and not calma_active and not _contra_viento_active and not lluvia_active:
			start_storm()
			hud.show_storm_warning(false)
			_next_event_type = -1
	else:
		hud.show_storm_warning(false)

	if not rafaga_active and not calma_active and not in_storm and not _contra_viento_active and not _wave_active and not _rear_wave_active and distance - last_rafaga_distance >= RAFAGA_COOLDOWN:
		last_rafaga_distance = distance
		if randf() < RAFAGA_CHANCE:
			start_rafaga()

	if not calma_active and not rafaga_active and not in_storm and not _contra_viento_active and not _wave_active and not _rear_wave_active and distance >= 500 and distance - last_calma_distance >= CALMA_COOLDOWN:
		last_calma_distance = distance
		if randf() < CALMA_CHANCE:
			start_calma()

	if not lluvia_active and not calma_active and not rafaga_active and not in_storm and not _contra_viento_active and not _wave_active and not _rear_wave_active and distance >= 500 and distance - last_lluvia_distance >= LLUVIA_INTERVAL:
		last_lluvia_distance = distance
		if randf() < LLUVIA_CHANCE:
			start_lluvia()

	if not _contra_viento_active and not calma_active and not in_storm and not _wave_active and not _rear_wave_active and distance >= 1000 and distance - _last_contra_viento_distance >= CONTRA_VIENTO_COOLDOWN:
		_last_contra_viento_distance = distance
		if randf() < 0.35:
			_contra_viento_active = true
			_contra_viento_time = 0.0
			hud.show_event_text("¡VIENTO EN CONTRA!", false)

	if _contra_viento_active:
		_contra_viento_time += delta
		if _contra_viento_time >= CONTRA_VIENTO_DURATION:
			_contra_viento_active = false
			hud.hide_event_text()

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

	if lluvia_active:
		lluvia_time += delta
		_spawn_lluvia_bola()
		if lluvia_time >= LLUVIA_DURATION:
			end_lluvia()

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
			_update_existing_obstacle_speeds()
		else:
			turbo_mult = 3.0

	if x2_palitos_active:
		x2p_remaining = 6.0 - (now - x2_palitos_start_time) / 1000.0
		if x2p_remaining <= 0:
			x2_palitos_active = false
			x2p_remaining = 0.0
		else:
			palitos_dist_mult = 3.0

	if miniatura_active:
		mini_remaining = 6.0 - (now - miniatura_start_time) / 1000.0
		if mini_remaining <= 0:
			miniatura_active = false
			mini_remaining = 0.0
			player.set_miniatura(false)
			miniatura_speed_mult = 1.0
		else:
			miniatura_speed_mult = 1.35

	var raw_delta := current_speed * delta / PIXEL_TO_METER
	difficulty_dist += raw_delta
	var contra_mult := 0.5 if _contra_viento_active else 1.0
	distance += raw_delta * speed_bonus * bird_speed_mult * turbo_mult * rafaga_mult * palitos_dist_mult * contra_mult * miniatura_speed_mult
	hud.update_distance(int(distance))
	while _last_milestone_idx < MILESTONES.size() and int(distance) >= MILESTONES[_last_milestone_idx]:
		hud.flash_milestone()
		_last_milestone_idx += 1

	if _rear_wave_active:
		_rear_wave_timer += delta
		var phase_delay: float = max(1.2, 2.0 - distance * 0.00005)
		if _rear_wave_timer >= phase_delay:
			_rear_wave_timer = 0.0
			hud.show_rear_warning(false)
			_spawn_rear_obstacle()
			_rear_wave_phase += 1
			if _rear_wave_phase >= 3:
				_rear_wave_active = false
				_rear_wave_phase = 0
				DataManager.major_events_total += 1
				major_events_in_run += 1
				var nuevos := DataManager.check_achievements({ "major_events_in_run": major_events_in_run })
				_show_popups(nuevos)
				_schedule_next_event()
			else:
				_rear_y = randf_range(200, 880)
				hud.show_rear_warning(true, _rear_y)
	else:
		if not _wave_active and _next_event_type == EventType.REAR_WAVE and distance >= _next_event_distance and not rafaga_active and not calma_active and not _contra_viento_active and not lluvia_active:
			_rear_wave_active = true
			_rear_wave_timer = 0.0
			_rear_wave_phase = 0
			_rear_y = randf_range(200, 880)
			hud.show_rear_warning(true, _rear_y)
			_next_event_type = -1

	if _wave_active:
		_wave_timer += delta
		match _wave_state:
			WaveState.WARN:
				if _wave_timer >= max(0.9, 1.5 - distance * 0.00006):
					_wave_timer = 0.0
					_spawn_wave_row()
					_wave_phase += 1
					if _wave_phase >= WAVE_COUNT:
						_wave_active = false
						_wave_phase = 0
						DataManager.major_events_total += 1
						major_events_in_run += 1
						var nuevos := DataManager.check_achievements({ "major_events_in_run": major_events_in_run })
						_show_popups(nuevos)
						_schedule_next_event()
					else:
						_wave_state = WaveState.POST
			WaveState.POST:
				if _wave_timer >= max(0.9, 1.5 - distance * 0.00006):
					_wave_timer = 0.0
					_spawn_wave_warnings()
					_wave_state = WaveState.WARN
	elif not _rear_wave_active and _next_event_type == EventType.FRONT_WAVE and distance >= _next_event_distance and not rafaga_active and not calma_active and not _contra_viento_active and not lluvia_active:
		_wave_active = true
		_wave_timer = 0.0
		_wave_phase = 0
		_wave_state = WaveState.WARN
		_spawn_wave_warnings()
		_next_event_type = -1

	if _wall_active:
		_wall_timer += delta
		if _wall_phase == 0:
			if _wall_timer >= WALL_WARN_DURATION:
				_wall_timer = 0.0
				_wall_phase = 1
				_clear_wall_warning()
				_spawn_wall_obstacles()
		elif _wall_phase == 1:
			if _wall_timer >= WALL_CLEAR_DELAY:
				_wall_current_wave += 1
				if _wall_current_wave >= _wall_total_waves:
					_wall_active = false
					_wall_phase = 0
					DataManager.major_events_total += 1
					major_events_in_run += 1
					var nuevos := DataManager.check_achievements({ "major_events_in_run": major_events_in_run })
					_show_popups(nuevos)
					_schedule_next_event()
				else:
					_wall_phase = 0
					_wall_timer = 0.0
					_wall_gap_y = randf_range(300, 780)
					_show_wall_warning()
	elif not _rear_wave_active and not _wave_active and _next_event_type == EventType.WALL and distance >= _next_event_distance and not rafaga_active and not calma_active and not _contra_viento_active and not lluvia_active:
		_wall_active = true
		_wall_phase = 0
		_wall_timer = 0.0
		_wall_total_waves = randi() % 3 + 1
		_wall_current_wave = 0
		_wall_gap_y = randf_range(300, 780)
		_show_wall_warning()
		_next_event_type = -1

	var palitos_rate := 1 + DataManager.get_upgrade_level("palitos_base")
	var bird_palitos_mult: float = DataManager.get_bird_modifiers()["palitos_mult"]
	var run_palitos := int(distance / 10) * palitos_rate * bird_palitos_mult
	hud.update_palitos(int(run_palitos))
	var curr_dist := int(distance)
	if curr_dist >= last_check_dist + 25:
		last_check_dist = curr_dist
		var nuevos := DataManager.check_achievements({ "distance": curr_dist })
		_show_popups(nuevos)
	hud.update_powerups(shield_remaining, turbo_remaining, x2_bolas_active, x2p_remaining, mini_remaining)
	hud.show_storm(in_storm)
	$Background.set_run_distance(distance, 3.5)
	var turbo_spawn_mult := TURBO_SPAWN_MULT if turbo_active else 1.0
	var rear_spawn_mult := 1.5 if _rear_wave_active else 1.0
	spawn_timer.wait_time = get_spawn_interval(difficulty_dist) * turbo_spawn_mult * rear_spawn_mult

	var target_shake := 0.0
	if DataManager.reduce_motion:
		target_shake = 0.0
	elif in_storm:
		target_shake = 8.0
	elif turbo_active:
		target_shake = 5.0

	if shake_strength < target_shake:
		shake_strength = min(shake_strength + 60.0 * delta, target_shake)
	elif shake_strength > target_shake:
		shake_strength = max(shake_strength - SHAKE_DECAY * delta, target_shake)

	if shake_strength > 0.0:
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
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

func _spawn_obstacle(shape_type: int, speed: float, base_speed: float = 0.0) -> void:
	_spawn_obstacle_at(shape_type, speed, _safe_obstacle_y(shape_type), base_speed)

func _spawn_obstacle_at(shape_type: int, speed: float, y: float, base_speed: float = 0.0) -> void:
	var obs := obstacle_scene.instantiate()
	obs.speed = speed
	obs.base_speed = base_speed
	obs.shape_type = shape_type
	obs.move_type = _random_move_type()
	obs.position = Vector2(2100, y)
	obs.add_to_group("obstacle")
	add_child(obs)

func _spawn_rear_obstacle() -> void:
	var obs := obstacle_scene.instantiate()
	var rs: float = REAR_SPEED + distance * 0.04
	obs.speed = rs
	obs.base_speed = rs
	obs.moving_right = true
	obs.shape_type = randi() % 3
	obs.move_type = _random_move_type()
	obs.position = Vector2(-100, _rear_y)
	obs.add_to_group("obstacle")
	add_child(obs)

func _generate_wave_lane_ys() -> void:
	_wave_lane_ys.clear()
	var factor: float = min(1.0, distance / 10000.0)
	var gap := randf_range(lerpf(120, 85, factor), lerpf(170, 130, factor))
	var center := clampf(player.position.y, 250, 830)
	_wave_lane_ys.append(clampf(center - gap, 200, 880))
	_wave_lane_ys.append(center)
	_wave_lane_ys.append(clampf(center + gap, 200, 880))

func _spawn_wave_warnings() -> void:
	_generate_wave_lane_ys()
	for i in 3:
		var y := _wave_lane_ys[i]
		var border := ColorRect.new()
		border.name = "WaveWarningBorder%d" % i
		border.color = Color(0, 0, 0)
		border.size = Vector2(2200, 10)
		border.position = Vector2(-50, y - 1)
		border.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(border)
		var warn := ColorRect.new()
		warn.name = "WaveWarning%d" % i
		warn.color = Color(0.95, 0.15, 0.1, 0.6)
		warn.size = Vector2(2200, 8)
		warn.position = Vector2(-50, y)
		warn.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(warn)

func _spawn_wave_row() -> void:
	var to_free: Array[ColorRect] = []
	for c in get_children():
		if c is ColorRect and c.name.begins_with("WaveWarning"):
			to_free.append(c)
	for c in to_free:
		c.free()
	for i in 3:
		var obs := obstacle_scene.instantiate()
		var ws: float = (REAR_SPEED + distance * 0.04) * max(3.0, 3.0 + distance * 0.00008)
		obs.speed = ws
		obs.base_speed = ws
		obs.shape_type = randi() % 3
		obs.move_type = _random_move_type()
		obs.position = Vector2(2020, _wave_lane_ys[i])
		obs.add_to_group("obstacle")
		add_child(obs)

func _random_move_type() -> int:
	var r := randf()
	return 0 if r < 0.85 else (1 if r < 0.95 else 2)

func _show_wall_warning() -> void:
	_clear_wall_warning()
	var half_gap := WALL_GAP_SIZE / 2
	for i in 2:
		var y := _wall_gap_y - half_gap if i == 0 else _wall_gap_y + half_gap
		var border := ColorRect.new()
		border.color = Color(0, 0, 0)
		border.size = Vector2(2200, 12)
		border.position = Vector2(-50, y - 2)
		border.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(border)
		_wall_warnings.append(border)
		var warn := ColorRect.new()
		warn.color = Color(0.2, 0.8, 0.2)
		warn.size = Vector2(2200, 8)
		warn.position = Vector2(-50, y)
		warn.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(warn)
		_wall_warnings.append(warn)

func _clear_wall_warning() -> void:
	for w in _wall_warnings:
		if is_instance_valid(w):
			w.queue_free()
	_wall_warnings.clear()

func _spawn_wall_obstacles() -> void:
	var ws: float = get_base_speed(difficulty_dist) * WALL_SPEED_MULT
	var half_gap := WALL_GAP_SIZE / 2
	var gap_top := _wall_gap_y - half_gap
	var gap_bot := _wall_gap_y + half_gap
	var y := 140.0
	while y < 940.0:
		if y + 12.5 > gap_top and y - 12.5 < gap_bot:
			y += 80.0
			continue
		var obs := obstacle_scene.instantiate()
		obs.speed = ws
		obs.base_speed = ws
		obs.shape_type = 0
		obs.move_type = 0
		obs.position = Vector2(2100, y)
		obs.add_to_group("obstacle")
		add_child(obs)
		y += 80.0

func _on_spawn_timer_timeout() -> void:
	if not obstacle_scene or not player.alive or calma_active or _wave_active or _wall_active or $Background.in_transition:
		return

	if kiwi_scene and kiwi_cooldown_timer >= KIWI_COOLDOWN * bird_kiwi_cooldown_mult:
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
	var obs_base_speed: float = get_base_speed(difficulty_dist)
	var obs_speed := obs_base_speed * combined_obs_mult

	var shape_a := randi() % 3
	if randf() < get_double_chance(difficulty_dist):
		var shape_b := randi() % 3
		var positions := _safe_double_y(shape_a, shape_b)
		_spawn_obstacle_at(shape_a, obs_speed, positions.x, obs_base_speed)
		_spawn_obstacle_at(shape_b, obs_speed, positions.y, obs_base_speed)
	else:
		_spawn_obstacle(shape_a, obs_speed, obs_base_speed)

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
	var mods := DataManager.get_bird_modifiers()
	match type:
		"shield":
			shield_active = true
			shield_start_time = Time.get_ticks_msec()
			shield_duration_max = (8.0 + DataManager.get_upgrade_level("shield_duration") * 0.2) * mods.get("powerup_duration_mult", 1.0)
			player.set_shield(true)
		"turbo":
			turbo_active = true
			turbo_start_time = Time.get_ticks_msec()
			turbo_duration_max = (6.0 + DataManager.get_upgrade_level("turbo_duration") * 0.2) * mods.get("powerup_duration_mult", 1.0)
			shake_strength = 10.0
			_update_encounter_mode()
			_spawn_shockwave()
			_update_existing_obstacle_speeds()
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
	if not lluvia_active and randf() >= BOLA_SPAWN_CHANCE:
		return

	var bola := bola_scene.instantiate()
	bola.speed = get_speed(difficulty_dist)
	bola.position = Vector2(2100, randf_range(220, 860))
	bola.amount = 4 if x2_bolas_active else 1
	bola.collected.connect(_on_bola_collected)
	bola.add_to_group("bola")
	add_child(bola)

func _on_bola_collected() -> void:
	var amount := 4 if x2_bolas_active else 1
	DataManager.add_bolas(amount)
	run_bolas += amount
	AudioManager.play_sfx("collect", -11.0)
	var nuevos := DataManager.check_achievements({})
	_show_popups(nuevos)
	hud.update_bolas(DataManager.bolas_balance)
	if x2_bolas_active:
		x2_bolas_active = false

func _show_popups(nuevos: Array) -> void:
	if nuevos.is_empty():
		return
	for a in nuevos:
		AudioManager.play_sfx("popup")
		DataManager.show_achievement_popup(a)
		await get_tree().create_timer(2.8, false, true).timeout

func _on_revive() -> void:
	AudioManager.play_sfx("revive")
	AudioManager.start_ambient_wind()
	Engine.time_scale = 1.0
	DataManager.palitos_balance -= REVIVE_COST
	DataManager.revives_used += 1
	var nuevos_revive := DataManager.check_achievements({})
	_show_popups(nuevos_revive)
	distance = max(distance - REVIVE_REWIND, 0.0)
	difficulty_dist = max(difficulty_dist - REVIVE_REWIND, 0.0)
	_schedule_next_event()
	last_rafaga_distance = distance
	last_calma_distance = distance
	last_lluvia_distance = distance

	for obs in get_tree().get_nodes_in_group("obstacle"):
		obs.free()
	for k in get_tree().get_nodes_in_group("kiwi"):
		k.free()
	for b in get_tree().get_nodes_in_group("bola"):
		b.free()
	for c in get_children():
		if c is ColorRect and c.name.begins_with("WaveWarning"):
			c.free()

	if in_storm:
		in_storm = false
		storm_time = 0.0
		AudioManager.stop_storm_wind(0.0)
		_update_encounter_mode()
	if rafaga_active:
		rafaga_active = false
		_update_encounter_mode()
	if calma_active:
		calma_active = false
		_update_encounter_mode()
	if lluvia_active:
		lluvia_active = false
		hud.hide_event_text()
		_update_encounter_mode()
	if _contra_viento_active:
		_contra_viento_active = false
		hud.hide_event_text()
	if turbo_active:
		turbo_active = false
		turbo_effect.set_normal_mode()
		hud.update_powerups(0.0, 0.0, false)
	if shield_active:
		shield_active = false
		player.set_shield(false)
		hud.update_powerups(0.0, 0.0, false)

	shield_active = false
	turbo_active = false
	lluvia_active = false
	x2_palitos_active = false
	x2_bolas_active = false
	miniatura_active = false
	miniatura_speed_mult = 1.0
	_rear_wave_active = false
	_rear_wave_phase = 0
	_wave_active = false
	_wave_phase = 0
	_wave_state = WaveState.WARN
	_wall_active = false
	_wall_phase = 0
	_wall_current_wave = 0
	_clear_wall_warning()
	kiwi_cooldown_timer = 0.0

	player.reset()
	revive_popup.visible = false
	spawn_timer.wait_time = get_spawn_interval(difficulty_dist)
	get_tree().paused = false

func _spawn_shockwave() -> void:
	var sw := Node2D.new()
	sw.set_script(preload("res://scenes/effects/shockwave.gd"))
	sw.position = player.global_position
	add_child(sw)

func _update_existing_obstacle_speeds() -> void:
	var turbo_mult := get_turbo_obs_speed(difficulty_dist) if turbo_active else 1.0
	var storm_mult := STORM_SPEED_BOOST if in_storm else 1.0
	var combined := turbo_mult * storm_mult
	if in_storm and turbo_active:
		combined = min(combined, 1.5)
	for obs in get_tree().get_nodes_in_group("obstacle"):
		obs.speed = obs.base_speed * combined

func _setup_biome_effects() -> void:
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = preload("res://scenes/effects/heat_distortion.gdshader")
	_heat_overlay = ColorRect.new()
	_heat_overlay.material = shader_mat
	_heat_overlay.color = Color.WHITE
	_heat_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_heat_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	_heat_overlay.z_index = 100
	var layer := CanvasLayer.new()
	layer.layer = 9
	layer.add_child(_heat_overlay)
	add_child(layer)

	_rain_particles = GPUParticles2D.new()
	var rain_mat := ParticleProcessMaterial.new()
	rain_mat.direction = Vector3(-0.3, 1, 0)
	rain_mat.gravity = Vector3(0, 500, 0)
	rain_mat.initial_velocity_min = 400.0
	rain_mat.initial_velocity_max = 700.0
	rain_mat.scale_min = 0.5
	rain_mat.scale_max = 1.5
	rain_mat.color = Color(0.7, 0.8, 1, 0.25)
	rain_mat.angle_min = -15.0
	rain_mat.angle_max = 15.0
	rain_mat.flatness = 1.0
	rain_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_mat.emission_box_extents = Vector3(1000, 2, 0)
	_rain_particles.process_material = rain_mat
	_rain_particles.amount = 150
	_rain_particles.lifetime = 0.5
	_rain_particles.one_shot = false
	_rain_particles.emitting = false
	_rain_particles.position = Vector2(960, -50)
	_rain_particles.z_index = 50
	add_child(_rain_particles)
	_set_biome_effects()

func _set_biome_effects() -> void:
	_heat_overlay.visible = _current_biome == "Puna"
	_rain_particles.emitting = _current_biome == "Cordillera" and not DataManager.reduce_motion

func _on_revive_reject() -> void:
	Engine.time_scale = 1.0
	revive_popup.visible = false
	death_screen.show_screen(int(distance), major_events_in_run, run_bolas, run_kiwis, _death_old_max)

func _on_transition_started(msg: String) -> void:
	hud.show_transition_message(msg)

func _on_transition_ended(biome_name: String) -> void:
	_current_biome = biome_name
	_set_biome_effects()
	hud.set_biome(biome_name)
	hud.hide_transition_message()
	var biome_idx := -1
	match biome_name:
		"Llanuras": biome_idx = 1
		"Puna": biome_idx = 2
	if biome_idx >= 0:
		var bonus := DataManager.claim_explorer_bonus(biome_idx)
		if bonus > 0:
			hud.show_transition_message("+%d palitos por explorar!" % bonus)
			await get_tree().create_timer(1.5).timeout
			hud.hide_transition_message()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_F1 and event.pressed and not event.echo:
		DataManager.palitos_balance += 100000
		DataManager.bolas_balance += 1000
		DataManager.save_data()
		print("DEBUG: +100000 palitos, +1000 barro")

func _exit_tree() -> void:
	AudioManager.stop_all_ambient()
