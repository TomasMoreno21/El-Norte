extends Area2D

signal collected

var speed := 100.0
var time := 0.0
var target_y: float
var move_timer: float = 0.0

var _tex1 := preload("res://Sprites/Pajaros/kiwi1.png")
var _tex2 := preload("res://Sprites/Pajaros/kiwi2.png")

@onready var _sprite := $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_pick_new_target()

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

	var frame := int(time / 0.12) % 2
	_sprite.texture = _tex1 if frame == 0 else _tex2

func _pick_new_target() -> void:
	target_y = randf_range(260, 820)
	move_timer = randf_range(0.8, 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit()
		queue_free()