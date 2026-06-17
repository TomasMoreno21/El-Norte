extends Area2D

signal collected

var speed := 100.0
var time := 0.0
var target_y: float
var move_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_pick_new_target()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 27, Color(0.3, 0.8, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 27, Color(1, 1, 1, 0.4), false, 3.0)

func _physics_process(delta: float) -> void:
	time += delta
	move_timer -= delta

	position.x -= speed * delta

	var dart_speed := 120.0
	position.y = move_toward(position.y, target_y, dart_speed * delta)
	position.y += sin(time * 2.0) * 4.0

	if move_timer <= 0.0 or abs(position.y - target_y) < 12.0:
		_pick_new_target()

	if position.x < -100:
		queue_free()

func _pick_new_target() -> void:
	target_y = randf_range(260, 820)
	move_timer = randf_range(0.8, 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit()
		queue_free()
