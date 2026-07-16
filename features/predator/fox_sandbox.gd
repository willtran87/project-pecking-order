extends Node3D

## A minimal, playable fox-motion sandbox. Run fox_sandbox.tscn directly
## (F6 in Godot) to inspect the same model and walk animation used in-office.

const FOX_MODEL := preload("res://assets/models/predator_fox.glb")
const MOVE_SPEED := 3.6
const TURN_SPEED := 10.0
const CAMERA_OFFSET := Vector3(3.8, 4.0, 5.0)

var _fox_root: Node3D
var _fox_model: Node3D
var _fox_animation: AnimationPlayer
var _camera: Camera3D


func _ready() -> void:
	_build_empty_space()
	_build_fox()
	_build_overlay()
	if "--capture-fox-sandbox" in OS.get_cmdline_user_args():
		call_deferred("_capture_preview")


func _process(delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		input.x = -1.0
	if Input.is_key_pressed(KEY_D):
		input.x = 1.0
	if Input.is_key_pressed(KEY_W):
		input.y = -1.0
	if Input.is_key_pressed(KEY_S):
		input.y = 1.0
	if Input.is_key_pressed(KEY_R):
		_fox_root.global_position = Vector3.ZERO

	var direction := Vector3(input.x, 0.0, input.y)
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		_fox_root.global_position += direction * MOVE_SPEED * delta
		var target_yaw := atan2(direction.x, direction.z)
		_fox_root.rotation.y = lerp_angle(_fox_root.rotation.y, target_yaw, minf(TURN_SPEED * delta, 1.0))
		_play_fox_animation(&"Fox_CarryWalk")
	else:
		_play_fox_animation(&"Fox_Idle")

	var target_camera_position := _fox_root.global_position + CAMERA_OFFSET
	_camera.global_position = _camera.global_position.lerp(target_camera_position, minf(delta * 4.5, 1.0))
	_camera.look_at(_fox_root.global_position + Vector3(0.0, 0.75, 0.0), Vector3.UP)


func _build_empty_space() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("182533")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("91a9c9")
	environment.ambient_light_energy = 0.78
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(42.0, 42.0)
	floor.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("2b4250")
	floor_material.roughness = 0.88
	floor.material_override = floor_material
	add_child(floor)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-55.0, -32.0, 0.0)
	key_light.light_color = Color("ffe4b3")
	key_light.light_energy = 1.15
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(-4.0, 4.0, 3.0)
	fill_light.light_color = Color("88b8ff")
	fill_light.light_energy = 3.0
	fill_light.omni_range = 13.0
	add_child(fill_light)

	_camera = Camera3D.new()
	_camera.position = CAMERA_OFFSET
	_camera.current = true
	add_child(_camera)


func _build_fox() -> void:
	_fox_root = Node3D.new()
	_fox_root.name = "ControllableFox"
	add_child(_fox_root)
	_fox_model = FOX_MODEL.instantiate() as Node3D
	_fox_root.add_child(_fox_model)
	for child_name in ["LimpChickenBody", "LimpChickenNeck", "LimpChickenHead", "LimpChickenBeak", "LimpChickenWingL", "LimpChickenWingR"]:
		var prop := _fox_model.find_child(child_name, true, false) as Node3D
		if prop != null:
			prop.visible = false
	_fox_animation = _fox_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_fox_animation(&"Fox_Idle")


func _play_fox_animation(requested_name: StringName) -> void:
	if _fox_animation == null:
		return
	for available_name in _fox_animation.get_animation_list():
		if String(available_name).ends_with(String(requested_name)):
			if _fox_animation.current_animation != available_name:
				_fox_animation.play(available_name, 0.12)
			return


func _build_overlay() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.color = Color(0.035, 0.060, 0.090, 0.88)
	panel.position = Vector2(24.0, 24.0)
	panel.size = Vector2(450.0, 108.0)
	canvas.add_child(panel)
	var label := Label.new()
	label.position = Vector2(22.0, 16.0)
	label.size = Vector2(410.0, 80.0)
	label.text = "FOX MOTION SANDBOX\nWASD / Arrow keys: move and swagger\nR: reset position"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("f5d58a"))
	panel.add_child(label)


func _capture_preview() -> void:
	await get_tree().create_timer(0.35).timeout
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path("res://captures/fox_sandbox.png"))
	get_tree().quit()
