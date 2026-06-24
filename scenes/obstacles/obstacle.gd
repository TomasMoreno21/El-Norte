extends StaticBody2D

enum ShapeType { RECT_H, RECT_V, CIRCLE }

var speed := 250.0
var base_speed := 0.0
var shape_type := ShapeType.RECT_H
var moving_right := false

var angular_speed := 0.0
var _sprite: Sprite2D
var _collision_shape: CollisionShape2D
var _pulse_time := randf_range(0.0, TAU)
var _pulse_speed := randf_range(4.0, 8.0)
var _pulse_base := randf_range(0.94, 1.0)

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

const REAR_COLOR := Color(0.95, 0.15, 0.1)

func _ready() -> void:
	angular_speed = randf_range(1.5, 4.0) * (-1 if randi() % 2 == 0 else 1)
	_setup_visual()
	_setup_collision()
	if moving_right:
		_setup_trail()

func _physics_process(delta: float) -> void:
	if moving_right:
		position.x += speed * delta
		if position.x > 2100:
			queue_free()
	else:
		position.x -= speed * delta
		if position.x < -200:
			queue_free()
	_sprite.rotation += angular_speed * delta
	_pulse_time += delta
	var s := _pulse_base + sin(_pulse_time * _pulse_speed) * 0.04
	_sprite.scale = Vector2(s, s)

func _setup_visual() -> void:
	var size: Vector2 = SHAPE_SIZES[shape_type]
	var color: Color = REAR_COLOR if moving_right else SHAPE_COLORS[shape_type]
	var image := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(color)
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

func _setup_trail() -> void:
	var trail := GPUParticles2D.new()
	trail.one_shot = false
	trail.emitting = true
	trail.amount = 8
	trail.lifetime = 0.3
	trail.explosiveness = 0.0
	trail.position = Vector2(-60, 0)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 10.0
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 100.0
	mat.initial_velocity_max = 200.0
	mat.scale_min = 1.0
	mat.scale_max = 2.0
	mat.color = Color(0.95, 0.15, 0.1, 0.4)
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	trail.process_material = mat
	add_child(trail)
