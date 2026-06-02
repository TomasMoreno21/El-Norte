extends Area2D

signal collected

var speed := 200.0
var time := 0.0
var base_y: float

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

	var image := Image.create(30, 30, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.35, 0.15, 1.0))
	$Sprite.texture = ImageTexture.create_from_image(image)

func _physics_process(delta: float) -> void:
	time += delta
	position.x -= speed * delta
	position.y = base_y + sin(time * 2.0) * 20.0
	if position.x < -100:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		collected.emit()
		queue_free()
