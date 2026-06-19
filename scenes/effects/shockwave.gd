extends Node2D

var radius := 0.0
var max_radius := 350.0
var duration := 0.6
var elapsed := 0.0

func _ready() -> void:
	scale = Vector2(0.8, 0.8)

func _process(delta: float) -> void:
	elapsed += delta
	var t := elapsed / duration
	if t >= 1.0:
		queue_free()
		return
	radius = max_radius * t
	queue_redraw()

func _draw() -> void:
	var alpha := 0.9 * (1.0 - elapsed / duration)
	var c := Color(1, 1, 1, alpha)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, c, 6.0)
	draw_arc(Vector2.ZERO, radius * 1.2, 0, TAU, 64, Color(1, 1, 1, alpha * 0.4), 2.0)
