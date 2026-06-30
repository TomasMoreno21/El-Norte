extends Area2D

signal collected

var speed := 200.0
var time := 0.0
var base_y: float
var amount := 1

var _barro_tex := preload("res://Sprites/Monedas/barro.png")

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)
	$Sprite.texture = _barro_tex

	var glow := Sprite2D.new()
	glow.name = "Glow"
	glow.texture = _make_glow_texture()
	glow.scale = Vector2(3, 3)
	glow.modulate = Color(1, 0.9, 0.3, 0.15)
	add_child(glow)
	move_child(glow, 0)

func _make_glow_texture() -> ImageTexture:
	var size := 32
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := float(size) / 2.0
	for y in range(size):
		for x in range(size):
			var dx := float(x) - half
			var dy := float(y) - half
			var dist := sqrt(dx * dx + dy * dy) / half
			var alpha := clampf(1.0 - dist * dist, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 0.95, 0.3, alpha * 0.6))
	return ImageTexture.create_from_image(image)

func _physics_process(delta: float) -> void:
	time += delta
	position.x -= speed * delta
	position.y = base_y + sin(time * 3.0) * 30.0

	var pulse := 1.0 + 0.15 * sin(time * 4.0)
	$Sprite.scale = Vector2(3, 3) * pulse
	$Glow.scale = Vector2(3, 3) * (1.0 + 0.05 * sin(time * 4.0 + 1.0))
	$Glow.modulate = Color(1, 0.9, 0.3, 0.12 + 0.06 * sin(time * 4.0))

	if position.x < 150 and position.x > 50:
		modulate = Color(1, 1, 0.5 + 0.5 * sin(time * 8.0), 1)
	elif position.x <= 50:
		modulate = Color(0.8, 0.8, 0.3, 0.5)
	else:
		modulate = Color.WHITE
	if position.x < -100:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit()
		_show_floating_text()
		queue_free()

func _show_floating_text() -> void:
	var label := Label.new()
	label.text = "+%d" % amount
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	label.add_theme_font_size_override("font_size", 28)
	label.z_index = 10
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-15, -40)

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(label.queue_free)
	label.add_child(timer)

	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
