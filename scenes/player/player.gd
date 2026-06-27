extends CharacterBody2D

const GRAVITY := 900.0
const FLAP_VELOCITY := -430.0

@export var start_position := Vector2(400, 540)

signal died
signal flapped

var alive := true
var invulnerable := false
var blink_timer: Timer
var flap_timer: Timer
var lives := 1
var flap_mult := 1.0
var storm_flap_override := 0.0
var _original_col_size: Vector2
var _original_scale: Vector2

var _was_pressed := false
var _miniatura_active := false
var _tex_carpintero1 := preload("res://Sprites/Pajaros/carpintero1.png")
var _tex_carpintero2 := preload("res://Sprites/Pajaros/carpintero2.png")
var _tex_hornero1 := preload("res://Sprites/Pajaros/hornero1.png")
var _tex_hornero2 := preload("res://Sprites/Pajaros/hornero2.png")
var _tex_golondrina1 := preload("res://Sprites/Pajaros/golondrina1.png")
var _tex_golondrina2 := preload("res://Sprites/Pajaros/golondrina2.png")
var _tex_tero1 := preload("res://Sprites/Pajaros/tero1.png")
var _tex_tero2 := preload("res://Sprites/Pajaros/tero2.png")
var _tex_frame1: Texture2D
var _tex_frame2: Texture2D
var _feather_particles: GPUParticles2D

func _ready() -> void:
	position = start_position
	_load_bird_textures()
	var mods := DataManager.get_bird_modifiers()
	flap_mult = mods["flap_mult"]
	lives = 1 + mods["extra_lives"]
	var col_shape := $CollisionShape2D.shape as RectangleShape2D
	if col_shape:
		_original_col_size = col_shape.size
	_original_scale = $Sprite2D.scale

	blink_timer = Timer.new()
	blink_timer.wait_time = 0.12
	blink_timer.timeout.connect(_blink)
	add_child(blink_timer)

	flap_timer = Timer.new()
	flap_timer.wait_time = 0.20
	flap_timer.timeout.connect(_flap_anim_tick)
	add_child(flap_timer)

	$Sprite2D.flip_h = true
	_setup_feather_particles()

func _setup_feather_particles() -> void:
	_feather_particles = GPUParticles2D.new()
	_feather_particles.name = "FeatherParticles"
	_feather_particles.one_shot = true
	_feather_particles.emitting = false
	_feather_particles.amount = 14
	_feather_particles.lifetime = 1.0
	_feather_particles.explosiveness = 0.9
	_feather_particles.local_coords = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-0.3, -1, 0)
	mat.spread = 30.0
	mat.gravity = Vector3(0, 60, 0)
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 120.0
	mat.scale_min = 0.7
	mat.scale_max = 1.3
	mat.color = Color(0.95, 0.88, 0.75, 1.0)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.angular_velocity_min = -180.0
	mat.angular_velocity_max = 180.0
	_feather_particles.process_material = mat

	add_child(_feather_particles)

func _load_bird_textures() -> void:
	match DataManager.active_bird:
		"carpintero":
			_tex_frame1 = _tex_carpintero1
			_tex_frame2 = _tex_carpintero2
		"golondrina":
			_tex_frame1 = _tex_golondrina1
			_tex_frame2 = _tex_golondrina2
		"tero":
			_tex_frame1 = _tex_tero1
			_tex_frame2 = _tex_tero2
		_:
			_tex_frame1 = _tex_hornero1
			_tex_frame2 = _tex_hornero2
	$Sprite2D.texture = _tex_frame1

func _flap_anim_tick() -> void:
	$Sprite2D.texture = _tex_frame2 if $Sprite2D.texture == _tex_frame1 else _tex_frame1

func _physics_process(delta: float) -> void:
	if not alive:
		return

	var is_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)
	if is_pressed:
		if not _was_pressed:
			AudioManager.play_sfx("flap", -26.0)
			$Sprite2D.texture = _tex_frame2
			flap_timer.start()
			if not DataManager.reduce_motion:
				_feather_particles.restart()
			flapped.emit()
			if is_inside_tree():
				var s := $Sprite2D
				kill_all_tweens()
				var base := _original_scale * (0.5 if _miniatura_active else 1.0)
				var sq := create_tween().set_ease(Tween.EASE_OUT)
				sq.tween_property(s, "scale", base * Vector2(1.12, 0.88), 0.05)
				sq.tween_property(s, "scale", base, 0.1)
		velocity.y = storm_flap_override if storm_flap_override != 0.0 else FLAP_VELOCITY * flap_mult
	else:
		if _was_pressed:
			flap_timer.stop()
			$Sprite2D.texture = _tex_frame1
		velocity.y += GRAVITY * delta
	
	_was_pressed = is_pressed
	move_and_slide()

	if position.y < 53.5 or position.y > 1026.5:
		die()
		return

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is StaticBody2D:
			die()

func die() -> void:
	if not alive:
		return
	if invulnerable:
		return
	if lives > 1:
		AudioManager.play_sfx("collect", -11.0)
		lives -= 1
		invulnerable = true
		collision_mask = 0
		blink_timer.start()
		await get_tree().create_timer(1.5).timeout
		invulnerable = false
		collision_mask = 2
		blink_timer.stop()
		$Sprite2D.modulate.a = 1.0
		return
	
	AudioManager.play_sfx_unpaused("hit", -10.0)
	alive = false
	velocity = Vector2.ZERO
	rotation = 0.0
	kill_all_tweens()

	get_tree().paused = true
	var slow := create_tween()
	slow.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var steps := 12
	var duration := 0.4
	for i in steps:
		slow.tween_callback(func():
			Engine.time_scale = lerpf(1.0, 0.3, float(i + 1) / steps)
		)
		slow.tween_interval(duration / steps)
	slow.tween_callback(func():
		died.emit()
	)

func kill_all_tweens() -> void:
	for t in get_tree().get_processed_tweens():
		t.kill()

func set_miniatura(active: bool) -> void:
	_miniatura_active = active
	var col_shape := $CollisionShape2D.shape as RectangleShape2D
	if col_shape:
		col_shape.size = _original_col_size * (0.5 if active else 1.0)
	$Sprite2D.scale = _original_scale * (0.5 if active else 1.0)

func set_shield(value: bool) -> void:
	invulnerable = value
	if value:
		collision_mask = 0
		blink_timer.start()
	else:
		collision_mask = 2
		blink_timer.stop()
		$Sprite2D.modulate.a = 1.0

func _blink() -> void:
	$Sprite2D.modulate.a = 0.2 if $Sprite2D.modulate.a == 1.0 else 1.0

func end_storm_gradual() -> void:
	if storm_flap_override == 0.0:
		return
	var target := FLAP_VELOCITY * flap_mult
	var tween := create_tween()
	tween.tween_property(self, "storm_flap_override", target, 1.5).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): storm_flap_override = 0.0)

func reset() -> void:
	kill_all_tweens()
	alive = true
	velocity = Vector2.ZERO
	position = start_position
	rotation = 0.0
	invulnerable = false
	collision_mask = 2
	blink_timer.stop()
	flap_timer.stop()
	$Sprite2D.modulate.a = 1.0
	$Sprite2D.scale = _original_scale
	_load_bird_textures()
	_was_pressed = false
	storm_flap_override = 0
	if not DataManager.reduce_motion:
		_feather_particles.restart()
	Engine.time_scale = 1.0
