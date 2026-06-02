extends Node2D

@export var obstacle_scene: PackedScene
@export var kiwi_scene: PackedScene
@export var choice_menu_scene: PackedScene
@export var bola_scene: PackedScene
@export var turbo_effect_scene: PackedScene

var distance := 0.0
var difficulty_dist := 0.0
var last_kiwi_distance := 0.0
var shield_active := false
var turbo_active := false
var shield_start_time := 0.0
var turbo_start_time := 0.0
var shield_duration_max := 4.0
var turbo_duration_max := 6.0
var in_storm := false
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
var x2_palitos_active := false
var x2_palitos_start_time := 0.0
var x2_bolas_active := false
var precognition_active := false
var precognition_start_time := 0.0
var miniatura_active := false
var miniatura_start_time := 0.0

const MIN_SPEED := 400.0
const MAX_SPEED := 1000.0
const MAX_INTERVAL := 1.6
const MIN_INTERVAL := 0.5
const PIXEL_TO_METER := 60.0
const KIWI_MIN_DIST := 400.0
const KIWI_MAX_DIST := 1200.0
const KIWI_BASE_CHANCE := 0.15
const STORM_INTERVAL := 500.0
const STORM_DURATION := 3.2
const STORM_SPEED_BOOST := 1.6
const STORM_INTERVAL_FACTOR := 0.5
const BOLA_SPAWN_INTERVAL := 6.0
const BOLA_SPAWN_CHANCE := 0.15
const TURBO_OBSTACLE_SPEED := 1.5
const TURBO_SPAWN_MULT := 1.5
const RAFAGA_COOLDOWN := 1200.0
const RAFAGA_CHANCE := 0.4
const RAFAGA_DURATION := 5.0
const RAFAGA_BOOST := 1.5
const CALMA_COOLDOWN := 800.0
const CALMA_CHANCE := 0.25
const CALMA_DURATION := 5.0

@onready var spawn_timer := $SpawnTimer
@onready var bola_timer := $BolaTimer
@onready var hud := $HUD
@onready var player := $Player
@onready var death_screen := $DeathScreen
@onready var camera := $Camera2D

var shake_strength := 10
const SHAKE_DECAY := 4.0

func get_speed(dist: float) -> float:
	var s: float = min(MIN_SPEED + dist * 0.5, MAX_SPEED)
	if in_storm:
		s *= STORM_SPEED_BOOST
	return s

func get_spawn_interval(dist: float) -> float:
	var i: float = max(MAX_INTERVAL - dist * 0.0009, MIN_INTERVAL)
	if in_storm:
		i *= STORM_INTERVAL_FACTOR
	return i

func _ready() -> void:
	spawn_timer.wait_time = MAX_INTERVAL
	spawn_timer.start()
	bola_timer.wait_time = BOLA_SPAWN_INTERVAL
	bola_timer.start()
	player.died.connect(_on_player_died)
	hud.update_bolas(DataManager.bolas_balance)
	var mods := DataManager.get_bird_modifiers()
	bird_speed_mult = mods["speed_mult"]
	bird_kiwi_bonus = mods["kiwi_bonus"]
	camera.zoom = Vector2(1.2, 1.2)
	if turbo_effect_scene:
		turbo_effect = turbo_effect_scene.instantiate()
		add_child(turbo_effect)

func start_storm() -> void:
	in_storm = true
	storm_time = 0.0
	shake_strength = 16.0
	_update_encounter_mode()

func end_storm() -> void:
	in_storm = false
	storm_time = 0.0
	next_storm_distance += STORM_INTERVAL
	DataManager.storms_survived += 1
	storms_in_run += 1
	var nuevos := DataManager.check_achievements({ "storms_in_run": storms_in_run })
	_show_popups(nuevos)
	if "rey_tormentas" in DataManager.completed_achievements:
		DataManager.add_bolas(1)
		hud.update_bolas(DataManager.bolas_balance)
	_update_encounter_mode()

func start_rafaga() -> void:
	rafaga_active = true
	rafaga_time = 0.0
	last_rafaga_distance = distance

func end_rafaga() -> void:
	rafaga_active = false
	_update_encounter_mode()

func start_calma() -> void:
	calma_active = true
	calma_time = 0.0
	last_calma_distance = distance
	if turbo_effect:
		turbo_effect.set_calma_mode()

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
	elif turbo_active:
		turbo_effect.set_turbo_mode()
	else:
		turbo_effect.set_normal_mode()

func _on_player_died() -> void:
	DataManager.deaths += 1
	DataManager.max_distance = max(DataManager.max_distance, int(distance))
	var nuevos := DataManager.check_achievements({ "distance": int(distance), "storms_in_run": storms_in_run })
	_show_popups(nuevos)
	death_screen.show_screen(int(distance))

func _process(delta: float) -> void:
	if not player.alive:
		return

	if not in_storm and distance >= next_storm_distance:
		start_storm()
	elif in_storm:
		storm_time += delta
		if storm_time >= STORM_DURATION:
			end_storm()

	if not rafaga_active and not calma_active and not in_storm and distance - last_rafaga_distance >= RAFAGA_COOLDOWN:
		last_rafaga_distance = distance
		if randf() < RAFAGA_CHANCE:
			start_rafaga()

	if not calma_active and not rafaga_active and not in_storm and distance >= 500 and distance - last_calma_distance >= CALMA_COOLDOWN:
		last_calma_distance = distance
		if randf() < CALMA_CHANCE:
			start_calma()

	var current_speed := get_speed(difficulty_dist)
	var speed_bonus := 1.0 + DataManager.get_upgrade_level("speed") * 0.05
	var turbo_mult := 1.0
	var rafaga_mult := 1.0
	var palitos_dist_mult := 1.0
	var now := Time.get_ticks_msec()
	var shield_remaining := 0.0
	var turbo_remaining := 0.0
	var x2p_remaining := 0.0
	var precog_remaining := 0.0
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
		if turbo_effect:
			turbo_effect.set_rafaga_mode(progress)

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

	if precognition_active:
		precog_remaining = 5.0 - (now - precognition_start_time) / 1000.0
		if precog_remaining <= 0:
			precognition_active = false
			precog_remaining = 0.0

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
	var curr_dist := int(distance)
	if curr_dist >= last_check_dist + 25:
		last_check_dist = curr_dist
		var nuevos := DataManager.check_achievements({ "distance": curr_dist })
		_show_popups(nuevos)
	hud.update_powerups(shield_remaining, turbo_remaining, x2_bolas_active, x2p_remaining, precog_remaining)
	hud.show_storm(in_storm)
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

func _on_spawn_timer_timeout() -> void:
	if not obstacle_scene or not player.alive or calma_active:
		return

	var kiwi_extra := DataManager.get_upgrade_level("kiwi") * 0.05
	var kiwi_dist := distance - last_kiwi_distance
	if kiwi_scene and kiwi_dist >= KIWI_MIN_DIST:
		var t := clampf((kiwi_dist - KIWI_MIN_DIST) / (KIWI_MAX_DIST - KIWI_MIN_DIST), 0.0, 1.0)
		var prob := KIWI_BASE_CHANCE + (1.0 - KIWI_BASE_CHANCE) * t
		prob += bird_kiwi_bonus + kiwi_extra
		if randf() < prob:
			var kiwi := kiwi_scene.instantiate()
			kiwi.speed = get_speed(difficulty_dist)
			kiwi.position = Vector2(2100, randf_range(260, 820))
			kiwi.collected.connect(_on_kiwi_collected)
			add_child(kiwi)
			last_kiwi_distance = distance
			return

	var turbo_obs_speed := TURBO_OBSTACLE_SPEED if turbo_active else 1.0

	var obstacle := obstacle_scene.instantiate()
	obstacle.speed = get_speed(difficulty_dist) * turbo_obs_speed
	obstacle.shape_type = randi() % 3
	obstacle.move_type = 0 if randf() < 0.7 else 1
	obstacle.position = Vector2(2100, randf_range(160, 920))
	if precognition_active:
		obstacle.ghost_time = 0.5
	obstacle.add_to_group("obstacle")
	add_child(obstacle)

	if randf() < 0.08:
		var obs2 := obstacle_scene.instantiate()
		obs2.speed = get_speed(difficulty_dist) * turbo_obs_speed
		obs2.shape_type = randi() % 3
		obs2.move_type = 0 if randf() < 0.7 else 1
		obs2.position = Vector2(2100, randf_range(160, 920))
		if precognition_active:
			obs2.ghost_time = 0.5
		obs2.add_to_group("obstacle")
		add_child(obs2)

func _on_kiwi_collected() -> void:
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
			hud.update_bolas(DataManager.bolas_balance)
		"x2_palitos":
			x2_palitos_active = true
			x2_palitos_start_time = Time.get_ticks_msec()
		"precognicion":
			precognition_active = true
			precognition_start_time = Time.get_ticks_msec()
		"miniatura":
			miniatura_active = true
			miniatura_start_time = Time.get_ticks_msec()
			player.set_miniatura(true)

func _on_bola_timer_timeout() -> void:
	if not player.alive or not bola_scene:
		return
	if randf() >= BOLA_SPAWN_CHANCE:
		return

	var bola := bola_scene.instantiate()
	bola.speed = get_speed(difficulty_dist)
	bola.position = Vector2(2100, randf_range(220, 860))
	bola.collected.connect(_on_bola_collected)
	add_child(bola)

func _on_bola_collected() -> void:
	var amount := 2 if x2_bolas_active else 1
	DataManager.add_bolas(amount)
	var nuevos := DataManager.check_achievements({})
	_show_popups(nuevos)
	hud.update_bolas(DataManager.bolas_balance)
	if x2_bolas_active:
		x2_bolas_active = false

func _show_popups(nuevos: Array) -> void:
	if nuevos.is_empty():
		return
	for a in nuevos:
		hud.show_achievement_popup(a)
		await get_tree().create_timer(2.8).timeout
