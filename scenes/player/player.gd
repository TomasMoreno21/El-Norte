extends CharacterBody2D

const GRAVITY := 900.0
const FLAP_VELOCITY := -400.0

@export var start_position := Vector2(400, 540)

signal died

var alive := true
var invulnerable := false
var blink_timer: Timer
var lives := 1
var flap_mult := 1.0
var _original_col_size: Vector2
var _original_scale: Vector2

func _ready() -> void:
	position = start_position
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

var _was_pressed := false

func _physics_process(delta: float) -> void:
	if not alive:
		return

	var is_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)
	if is_pressed:
		if not _was_pressed:
			AudioManager.play_sfx("flap")
		velocity.y = FLAP_VELOCITY * flap_mult
	else:
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
		AudioManager.play_sfx("collect") # use a lighter sound for losing a life
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
	
	AudioManager.play_sfx("hit")
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

func reset() -> void:
	alive = true
	velocity = Vector2.ZERO
	position = start_position
	rotation = 0.0
	invulnerable = false
	collision_mask = 2
	blink_timer.stop()
	$Sprite2D.modulate.a = 1.0
	$Sprite2D.scale = _original_scale
	Engine.time_scale = 1.0
