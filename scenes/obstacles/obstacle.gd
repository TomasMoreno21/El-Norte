extends StaticBody2D

enum ShapeType { RECT_H, RECT_V, CIRCLE }

var speed := 250.0
var base_speed := 0.0
var shape_type := ShapeType.RECT_H

var angular_speed := 0.0
var _sprite: Sprite2D
var _collision_shape: CollisionShape2D

const SHAPE_COLORS := {
	ShapeType.RECT_H: Color(0.5, 0.7, 0.3),
	ShapeType.RECT_V: Color(0.8, 0.3, 0.3),
	ShapeType.CIRCLE: Color(0.6, 0.6, 0.6),
}

const SHAPE_SIZES := {
	ShapeType.RECT_H: Vector2(100, 25),
	ShapeType.RECT_V: Vector2(25, 100),
	ShapeType.CIRCLE: Vector2(55, 55),
}

func _ready() -> void:
	angular_speed = randf_range(1.5, 4.0) * (-1 if randi() % 2 == 0 else 1)
	_setup_visual()
	_setup_collision()

func _physics_process(delta: float) -> void:
	position.x -= speed * delta
	_sprite.rotation += angular_speed * delta

	if position.x < -200:
		queue_free()

func _setup_visual() -> void:
	var size: Vector2 = SHAPE_SIZES[shape_type]
	var image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(SHAPE_COLORS[shape_type])
	var texture := ImageTexture.create_from_image(image)

	_sprite = Sprite2D.new()
	_sprite.texture = texture
	add_child(_sprite)

func _setup_collision() -> void:
	var shape: Shape2D
	var size: Vector2 = SHAPE_SIZES[shape_type]
	match shape_type:
		ShapeType.RECT_H, ShapeType.RECT_V:
			var s := RectangleShape2D.new()
			s.size = size
			shape = s
		ShapeType.CIRCLE:
			var s := CircleShape2D.new()
			s.radius = size.x / 2.0
			shape = s

	var col := CollisionShape2D.new()
	col.shape = shape
	_collision_shape = col
	add_child(col)
