class_name OfficeAtmosphere
extends Node3D

## Lightweight visual atmosphere for the compatibility renderer.
##
## Add this node beneath Office and forward simulation snapshots through
## `update_from_snapshot()`. All continuous effects have explicit bounds, and
## the three accent lights are deliberately local, low energy, and shadowless.

const NORMAL_WEST_COLOR := Color("e7c982")
const NORMAL_EAST_COLOR := Color("b9d8d2")
const NORMAL_INTAKE_COLOR := Color("efc772")
const OVERTIME_RED := Color("df5a54")
const OVERTIME_BLUE := Color("5b89c9")

const OFFICE_PARTICLE_BOUNDS := AABB(Vector3(-12.2, -0.5, -9.2), Vector3(24.4, 4.6, 18.4))
const EVENT_PARTICLE_BOUNDS := AABB(Vector3(-2.2, -1.0, -2.2), Vector3(4.4, 4.5, 4.4))

@export_range(8, 64, 1) var dust_mote_count: int = 32
@export_range(4, 24, 1) var feather_count: int = 10
@export_range(0.0, 1.0, 0.01) var atmosphere_strength: float = 1.0

var _dust_motes: GPUParticles3D
var _drifting_feathers: GPUParticles3D
var _zone_lights: Array[OmniLight3D] = []
var _alert_materials: Array[StandardMaterial3D] = []
var _event_bursts: Node3D
var _farmer_spotlight: SpotLight3D

var _overtime_target: float = 0.0
var _overtime_blend: float = 0.0
var _late_day: float = 0.0
var _quota_pressure: float = 0.0
var _average_stress: float = 0.0
var _event_pulse: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	name = "OfficeAtmosphere"
	_build_ambient_particles()
	_build_zone_lights()
	_build_overtime_alert_bars()
	_event_bursts = Node3D.new()
	_event_bursts.name = "EventBursts"
	add_child(_event_bursts)


func _process(delta: float) -> void:
	_elapsed += delta
	var blend_weight := 1.0 - exp(-delta * 3.6)
	_overtime_blend = lerpf(_overtime_blend, _overtime_target, blend_weight)
	_event_pulse = move_toward(_event_pulse, 0.0, delta * 1.8)
	_update_zone_lights()
	_update_alert_bars()


## Forward DepartmentSimulation.snapshot() here whenever snapshot_changed fires.
## Missing fields are tolerated so this node can also be previewed in isolation.
func update_from_snapshot(snapshot: Dictionary) -> void:
	_overtime_target = 1.0 if bool(snapshot.get("overtime_enabled", false)) else 0.0

	var minute := float(snapshot.get("minute_of_day", 480.0))
	_late_day = smoothstep(0.58, 1.0, clampf(inverse_lerp(480.0, 1020.0, minute), 0.0, 1.0))

	var quota := maxf(1.0, float(snapshot.get("quota_target", 1.0)))
	var quota_progress := clampf(float(snapshot.get("eggs_today", 0.0)) / quota, 0.0, 1.0)
	_quota_pressure = _late_day * (1.0 - quota_progress)

	var workers: Array = snapshot.get("workers", [])
	var stress_total := 0.0
	for worker_value in workers:
		if worker_value is Dictionary:
			stress_total += clampf(float((worker_value as Dictionary).get("stress", 0.0)), 0.0, 100.0)
	_average_stress = stress_total / (float(workers.size()) * 100.0) if not workers.is_empty() else 0.0


## A restrained quality-colored puff at the actual hen/egg location.
func pulse_egg_laid(world_position: Vector3, quality: StringName = &"sound") -> void:
	var color := Color("efe4c8")
	var count := 7
	if quality == &"golden":
		color = Color("f3c853")
		count = 13
	elif quality == &"cracked":
		color = Color("b67d70")
		count = 9
	_spawn_event_burst("EggGatheringPulse", world_position, color, count, Vector3.UP, Vector2(0.25, 0.75), 0.72)
	_event_pulse = maxf(_event_pulse, 0.5 if quality != &"golden" else 0.9)


## Call when the feed party begins. Defaults to the current trough location.
func pulse_feed_party(world_position: Vector3 = Vector3(-10.15, 0.72, 0.0)) -> void:
	_spawn_event_burst(
		"FeedPartyPulse",
		world_position,
		Color("e2b84f"),
		18,
		Vector3.UP,
		Vector2(0.45, 1.05),
		1.05
	)
	_event_pulse = maxf(_event_pulse, 0.72)


## Briefly emphasizes the existing red/blue treatment without adding a light.
func pulse_alert(severity: float = 1.0) -> void:
	_event_pulse = maxf(_event_pulse, clampf(severity, 0.0, 1.0))


func pulse_farmer_review() -> void:
	if _farmer_spotlight == null:
		return
	_farmer_spotlight.light_energy = 0.92 * atmosphere_strength
	var tween := create_tween().bind_node(self)
	tween.tween_interval(2.6)
	tween.tween_property(_farmer_spotlight, "light_energy", 0.0, 1.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func set_atmosphere_enabled(enabled: bool) -> void:
	if _dust_motes != null:
		_dust_motes.emitting = enabled
	if _drifting_feathers != null:
		_drifting_feathers.emitting = enabled
	for light in _zone_lights:
		light.visible = enabled
	var alert_bars := get_node_or_null("OvertimeAlertBars") as Node3D
	if alert_bars != null:
		alert_bars.visible = enabled


func _build_ambient_particles() -> void:
	_dust_motes = GPUParticles3D.new()
	_dust_motes.name = "AmbientDustMotes"
	_dust_motes.amount = dust_mote_count
	_dust_motes.lifetime = 9.0
	_dust_motes.randomness = 0.72
	_dust_motes.preprocess = 4.0
	_dust_motes.local_coords = true
	_dust_motes.visibility_aabb = OFFICE_PARTICLE_BOUNDS
	_dust_motes.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME
	_dust_motes.process_material = _make_dust_process_material()
	_dust_motes.draw_pass_1 = _make_particle_quad(Vector2(0.025, 0.025), Color("f4ddb0"), 0.42, true)
	add_child(_dust_motes)

	_drifting_feathers = GPUParticles3D.new()
	_drifting_feathers.name = "DriftingFeathers"
	_drifting_feathers.amount = feather_count
	_drifting_feathers.lifetime = 12.0
	_drifting_feathers.randomness = 0.84
	_drifting_feathers.preprocess = 5.0
	_drifting_feathers.local_coords = true
	_drifting_feathers.visibility_aabb = OFFICE_PARTICLE_BOUNDS
	_drifting_feathers.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME
	_drifting_feathers.process_material = _make_feather_process_material()
	_drifting_feathers.draw_pass_1 = _make_particle_quad(Vector2(0.055, 0.15), Color("e9e1ca"), 0.56, false)
	add_child(_drifting_feathers)


func _make_dust_process_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(11.2, 1.65, 8.25)
	material.direction = Vector3(0.7, 0.22, -0.2).normalized()
	material.spread = 42.0
	material.initial_velocity_min = 0.025
	material.initial_velocity_max = 0.085
	material.gravity = Vector3(0.0, 0.012, 0.0)
	material.scale_min = 0.6
	material.scale_max = 1.4
	material.color_ramp = _make_fade_gradient(Color("fff0c9", 0.0), Color("fff0c9", 0.33))
	return material


func _make_feather_process_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(10.8, 0.35, 7.9)
	material.direction = Vector3(0.28, -1.0, 0.14).normalized()
	material.spread = 38.0
	material.initial_velocity_min = 0.035
	material.initial_velocity_max = 0.095
	material.gravity = Vector3(0.018, -0.022, 0.012)
	material.angular_velocity_min = -24.0
	material.angular_velocity_max = 24.0
	material.scale_min = 0.65
	material.scale_max = 1.15
	material.color_ramp = _make_fade_gradient(Color("f1ead7", 0.0), Color("f1ead7", 0.42))
	return material


func _make_fade_gradient(edge_color: Color, middle_color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.16, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		edge_color,
		middle_color,
		Color(middle_color, middle_color.a * 0.78),
		edge_color,
	])
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _make_particle_quad(size: Vector2, color: Color, alpha: float, billboard: bool) -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(color, alpha * atmosphere_strength)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := QuadMesh.new()
	mesh.size = size
	mesh.material = material
	return mesh


func _build_zone_lights() -> void:
	var accents := Node3D.new()
	accents.name = "ZoneLightAccents"
	add_child(accents)
	_add_zone_light(accents, "WestWorkstationAccent", Vector3(-4.9, 2.1, 0.0), NORMAL_WEST_COLOR, 0.13, 5.0)
	_add_zone_light(accents, "EastWorkstationAccent", Vector3(4.9, 2.1, 0.0), NORMAL_EAST_COLOR, 0.12, 5.0)
	_add_zone_light(accents, "IntakeAccent", Vector3(9.4, 2.0, 5.2), NORMAL_INTAKE_COLOR, 0.16, 3.1)
	_farmer_spotlight = SpotLight3D.new()
	_farmer_spotlight.name = "FarmerReviewSpotlight"
	_farmer_spotlight.position = Vector3(8.2, 4.8, 4.3)
	accents.add_child(_farmer_spotlight)
	_farmer_spotlight.look_at(Vector3(8.2, 0.7, 4.3), Vector3.FORWARD)
	_farmer_spotlight.light_color = Color("f5d47d")
	_farmer_spotlight.light_energy = 0.0
	_farmer_spotlight.light_specular = 0.22
	_farmer_spotlight.spot_range = 6.0
	_farmer_spotlight.spot_angle = 33.0
	_farmer_spotlight.spot_angle_attenuation = 1.6
	_farmer_spotlight.shadow_enabled = false


func _add_zone_light(
	parent: Node3D,
	light_name: String,
	light_position: Vector3,
	color: Color,
	energy: float,
	range_value: float
) -> void:
	var light := OmniLight3D.new()
	light.name = light_name
	light.position = light_position
	light.light_color = color
	light.light_energy = energy * atmosphere_strength
	light.light_specular = 0.18
	light.omni_range = range_value
	light.omni_attenuation = 1.72
	light.shadow_enabled = false
	parent.add_child(light)
	_zone_lights.append(light)


func _build_overtime_alert_bars() -> void:
	var bars := Node3D.new()
	bars.name = "OvertimeAlertBars"
	add_child(bars)
	_add_alert_bar(bars, "RedAlertStrip", Vector3(-5.4, 3.32, -8.47), Vector3(4.4, 0.055, 0.045), OVERTIME_RED)
	_add_alert_bar(bars, "BlueAlertStrip", Vector3(5.4, 3.32, -8.47), Vector3(4.4, 0.055, 0.045), OVERTIME_BLUE)


func _add_alert_bar(parent: Node3D, bar_name: String, bar_position: Vector3, size: Vector3, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.72)
	material.roughness = 0.46
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.01

	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = bar_name
	instance.position = bar_position
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	_alert_materials.append(material)


func _update_zone_lights() -> void:
	if _zone_lights.size() != 3:
		return
	var overtime_wave := 0.5 + 0.5 * sin(_elapsed * 3.2)
	var pressure_boost := _quota_pressure * 0.025 + _average_stress * 0.018
	var pulse_boost := _event_pulse * 0.08

	_zone_lights[0].light_color = NORMAL_WEST_COLOR.lerp(OVERTIME_RED, _overtime_blend)
	_zone_lights[1].light_color = NORMAL_EAST_COLOR.lerp(OVERTIME_BLUE, _overtime_blend)
	_zone_lights[2].light_color = NORMAL_INTAKE_COLOR.lerp(Color("b8788d"), _overtime_blend * 0.42)

	_zone_lights[0].light_energy = (
		0.13 + _late_day * 0.025 + pressure_boost + pulse_boost
		+ _overtime_blend * (0.045 + overtime_wave * 0.025)
	) * atmosphere_strength
	_zone_lights[1].light_energy = (
		0.12 + _late_day * 0.03 + pressure_boost + pulse_boost
		+ _overtime_blend * (0.065 - overtime_wave * 0.025)
	) * atmosphere_strength
	_zone_lights[2].light_energy = (
		0.16 + _late_day * 0.02 + pulse_boost * 0.65 + _overtime_blend * 0.025
	) * atmosphere_strength


func _update_alert_bars() -> void:
	var overtime_wave := 0.5 + 0.5 * sin(_elapsed * 3.2)
	for index in _alert_materials.size():
		var opposing_wave := overtime_wave if index == 0 else 1.0 - overtime_wave
		var pressure_energy := _quota_pressure * (0.34 if index == 0 else 0.08) + _average_stress * 0.10
		_alert_materials[index].emission_energy_multiplier = (
			0.01 + pressure_energy + _overtime_blend * (0.45 + opposing_wave * 0.32) + _event_pulse * 0.22
		) * atmosphere_strength


func _spawn_event_burst(
	burst_name: String,
	world_position: Vector3,
	color: Color,
	count: int,
	direction: Vector3,
	speed_range: Vector2,
	lifetime: float
) -> void:
	if _event_bursts == null:
		return
	var burst := GPUParticles3D.new()
	burst.name = "%s_%d" % [burst_name, Time.get_ticks_msec()]
	burst.amount = count
	burst.lifetime = lifetime
	burst.one_shot = true
	burst.explosiveness = 0.88
	burst.randomness = 0.42
	burst.local_coords = false
	burst.visibility_aabb = EVENT_PARTICLE_BOUNDS
	burst.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME

	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = 0.12
	process_material.direction = direction.normalized()
	process_material.spread = 64.0
	process_material.initial_velocity_min = speed_range.x
	process_material.initial_velocity_max = speed_range.y
	process_material.gravity = Vector3(0.0, -0.72, 0.0)
	process_material.scale_min = 0.55
	process_material.scale_max = 1.25
	process_material.color_ramp = _make_fade_gradient(Color(color, 0.0), Color(color, 0.86))
	burst.process_material = process_material
	burst.draw_pass_1 = _make_particle_quad(Vector2(0.055, 0.055), color, 0.92, true)

	_event_bursts.add_child(burst)
	burst.global_position = world_position
	burst.finished.connect(burst.queue_free, CONNECT_ONE_SHOT)
	burst.emitting = true
