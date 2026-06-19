extends CanvasLayer

@onready var top_emitter: GPUParticles2D = $TopEmitter
@onready var bottom_emitter: GPUParticles2D = $BottomEmitter
@onready var rafaga_top: GPUParticles2D = $RafagaTop
@onready var rafaga_bottom: GPUParticles2D = $RafagaBottom
@onready var calma_label: Label = $CalmaLabel

func _ready() -> void:
	_setup_emitter(top_emitter, Vector2(960, 25), Vector3(-1, 0, 0))
	_setup_emitter(bottom_emitter, Vector2(960, 1055), Vector3(-1, 0, 0))
	_setup_rafaga_emitter(rafaga_top, Vector2(960, 25))
	_setup_rafaga_emitter(rafaga_bottom, Vector2(960, 1055))
	if DataManager.reduce_motion:
		top_emitter.emitting = false
		bottom_emitter.emitting = false
		rafaga_top.emitting = false
		rafaga_bottom.emitting = false
	else:
		set_normal_mode()

func _setup_emitter(emitter: GPUParticles2D, pos: Vector2, dir: Vector3) -> void:
	emitter.position = pos
	emitter.one_shot = false
	emitter.local_coords = true
	var mat := ParticleProcessMaterial.new()
	mat.direction = dir
	mat.spread = 3.0
	mat.gravity = Vector3.ZERO
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(960, 2, 0)
	mat.color = Color(1, 1, 1, 0.35)
	emitter.process_material = mat
	var img := Image.create(40, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	emitter.texture = ImageTexture.create_from_image(img)

func _setup_rafaga_emitter(emitter: GPUParticles2D, pos: Vector2) -> void:
	emitter.position = pos
	emitter.one_shot = false
	emitter.local_coords = true
	emitter.emitting = false
	emitter.amount = 15
	emitter.lifetime = 1.2

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 2.0
	mat.gravity = Vector3.ZERO
	mat.initial_velocity_min = 200.0
	mat.initial_velocity_max = 400.0
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(960, 2, 0)
	mat.color = Color(0.3, 0.9, 0.3, 0.4)
	emitter.process_material = mat

	var img := Image.create(40, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.9, 0.3))
	emitter.texture = ImageTexture.create_from_image(img)

func _reduce_motion_check() -> bool:
	if DataManager.reduce_motion:
		top_emitter.emitting = false
		bottom_emitter.emitting = false
		rafaga_top.emitting = false
		rafaga_bottom.emitting = false
		calma_label.visible = false
		return true
	return false

func set_normal_mode() -> void:
	if _reduce_motion_check():
		return
	top_emitter.amount = 20
	bottom_emitter.amount = 20
	top_emitter.lifetime = 1.0
	bottom_emitter.lifetime = 1.0
	top_emitter.scale = Vector2(1, 1)
	bottom_emitter.scale = Vector2(1, 1)
	top_emitter.process_material.initial_velocity_min = 300.0
	top_emitter.process_material.initial_velocity_max = 500.0
	bottom_emitter.process_material.initial_velocity_min = 300.0
	bottom_emitter.process_material.initial_velocity_max = 500.0
	top_emitter.process_material.color = Color(1, 1, 1, 0.35)
	bottom_emitter.process_material.color = Color(1, 1, 1, 0.35)
	top_emitter.emitting = true
	bottom_emitter.emitting = true
	rafaga_top.emitting = false
	rafaga_bottom.emitting = false
	calma_label.visible = false

func set_turbo_mode() -> void:
	if _reduce_motion_check():
		return
	top_emitter.amount = 35
	bottom_emitter.amount = 35
	top_emitter.lifetime = 0.9
	bottom_emitter.lifetime = 0.9
	top_emitter.scale = Vector2(2.5, 2.5)
	bottom_emitter.scale = Vector2(2.5, 2.5)
	top_emitter.process_material.initial_velocity_min = 800.0
	top_emitter.process_material.initial_velocity_max = 1500.0
	bottom_emitter.process_material.initial_velocity_min = 800.0
	bottom_emitter.process_material.initial_velocity_max = 1500.0
	top_emitter.process_material.color = Color(1, 1, 1, 0.6)
	bottom_emitter.process_material.color = Color(1, 1, 1, 0.6)
	top_emitter.emitting = true
	bottom_emitter.emitting = true
	rafaga_top.emitting = false
	rafaga_bottom.emitting = false
	calma_label.visible = false

func set_storm_mode() -> void:
	if _reduce_motion_check():
		return
	top_emitter.amount = 50
	bottom_emitter.amount = 50
	top_emitter.lifetime = 1.2
	bottom_emitter.lifetime = 1.2
	top_emitter.scale = Vector2(3.5, 3.5)
	bottom_emitter.scale = Vector2(3.5, 3.5)
	top_emitter.process_material.initial_velocity_min = 800.0
	top_emitter.process_material.initial_velocity_max = 1600.0
	bottom_emitter.process_material.initial_velocity_min = 800.0
	bottom_emitter.process_material.initial_velocity_max = 1600.0
	top_emitter.process_material.color = Color(1, 0.7, 0.3, 0.6)
	bottom_emitter.process_material.color = Color(1, 0.7, 0.3, 0.6)
	top_emitter.emitting = true
	bottom_emitter.emitting = true
	rafaga_top.emitting = false
	rafaga_bottom.emitting = false
	calma_label.visible = false

func set_rafaga_mode(progress: float) -> void:
	if _reduce_motion_check():
		return
	var p := clampf(progress, 0.0, 1.0)
	top_emitter.emitting = false
	bottom_emitter.emitting = false
	rafaga_top.amount = int(25 * p)
	rafaga_bottom.amount = int(25 * p)
	rafaga_top.scale = Vector2(2.5, 2.5) * Vector2(1 + p, 1 + p)
	rafaga_bottom.scale = Vector2(2.5, 2.5) * Vector2(1 + p, 1 + p)
	rafaga_top.process_material.initial_velocity_min = 400.0
	rafaga_top.process_material.initial_velocity_max = 600.0
	rafaga_bottom.process_material.initial_velocity_min = 400.0
	rafaga_bottom.process_material.initial_velocity_max = 600.0
	rafaga_top.process_material.color = Color(0.3, 0.9, 0.3, 0.5 * p)
	rafaga_bottom.process_material.color = Color(0.3, 0.9, 0.3, 0.5 * p)
	rafaga_top.modulate = Color(1, 1, 1, p)
	rafaga_bottom.modulate = Color(1, 1, 1, p)
	rafaga_top.emitting = p > 0.0
	rafaga_bottom.emitting = p > 0.0
	calma_label.visible = false

func set_calma_mode() -> void:
	if _reduce_motion_check():
		return
	top_emitter.emitting = false
	bottom_emitter.emitting = false
	rafaga_top.emitting = false
	rafaga_bottom.emitting = false
	calma_label.visible = true
