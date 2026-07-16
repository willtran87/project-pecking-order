class_name ManagementCameraController
extends Node

## Orthographic inspection camera for the management floor.
##
## The controller deliberately translates the configured camera without rotating
## it. This keeps the office's isometric composition stable while employees are
## inspected. Position and orthographic size use frame-rate-independent
## exponential damping, including wheel zoom changes.

signal focus_changed(label: String, worker_id: int)

@export_range(30.0, 80.0, 1.0) var click_radius_pixels: float = 50.0
@export_range(1.0, 20.0, 0.1) var transition_speed: float = 7.5
@export_range(0.1, 1.0, 0.01) var focused_size_ratio: float = 0.36
@export_range(2.0, 8.0, 0.1) var minimum_focused_size: float = 4.0
@export_range(6.0, 16.0, 0.1) var maximum_focused_size: float = 14.5
@export_range(0.05, 0.4, 0.01) var wheel_zoom_ratio: float = 0.12

const WORKER_FOCUS_HEIGHT := 0.82
const RING_FLOOR_HEIGHT := 0.035
const EXPONENTIAL_SETTLE_PERCENT := 0.01
const CYCLE_HEN_ACTION: StringName = &"cycle_hen"
const OFFICE_OVERVIEW_ACTION: StringName = &"office_overview"

var current_focus_label: String = ""

var _camera: Camera3D
var _worker_views: Dictionary[int, ChickenView] = {}
var _overview_position := Vector3.ZERO
var _overview_target := Vector3.ZERO
var _overview_size: float = 20.0
var _configured_overview_size: float = 20.0
var _camera_offset := Vector3.ZERO
var _stable_camera_basis := Basis.IDENTITY

var _has_focus: bool = false
var _focused_worker_id: int = -1
var _static_focus_point := Vector3.ZERO
var _desired_size: float = 20.0
var _default_focused_size: float = 7.0
var _safe_minimum_size: float = 4.0
var _safe_maximum_size: float = 14.5
var _active_transition_speed: float = 7.5
var _transition_seconds_remaining: float = 0.0
var _selection_ring: MeshInstance3D
var _focus_generation: int = 0
var _reduced_motion: bool = false
var _high_contrast: bool = false


## Captures the existing overview framing and registers the selectable workers.
## Call this after the camera and worker views have entered the scene tree.
func configure(
		camera: Camera3D,
		worker_views: Dictionary[int, ChickenView],
		overview_target: Vector3
) -> void:
	_camera = camera
	_worker_views = worker_views
	_overview_target = overview_target
	_overview_position = camera.global_position
	_overview_size = camera.size
	_configured_overview_size = camera.size
	_camera_offset = _overview_position - _overview_target
	_stable_camera_basis = camera.global_transform.basis
	_desired_size = _overview_size

	# Inspection zoom remains useful without allowing the player to zoom inside a
	# character or so far out that it becomes indistinguishable from overview.
	_safe_minimum_size = minf(minimum_focused_size, _overview_size)
	_safe_maximum_size = clampf(maximum_focused_size, _safe_minimum_size, _overview_size)
	_default_focused_size = clampf(
		_overview_size * focused_size_ratio,
		_safe_minimum_size,
		_safe_maximum_size
	)
	_active_transition_speed = transition_speed
	_ensure_selection_ring()
	show_overview()


## Reframes the overview from the currently commissioned campus footprint.
## Rect2 uses world X/Z coordinates. The calculation projects every ground and
## roof corner onto the camera's stable screen plane, so east/north parcels can
## enlarge and recenter the view without changing the authored isometric angle.
func set_overview_bounds(
		world_xz_bounds: Rect2,
		maximum_height: float = 3.6,
		margin_ratio: float = 1.12
) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if world_xz_bounds.size.x <= 0.0 or world_xz_bounds.size.y <= 0.0:
		return

	var center_xz := world_xz_bounds.get_center()
	var next_target := Vector3(center_xz.x, _overview_target.y, center_xz.y)
	var viewport_size := _camera.get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var horizontal_min := INF
	var horizontal_max := -INF
	var vertical_min := INF
	var vertical_max := -INF
	for x: float in [world_xz_bounds.position.x, world_xz_bounds.end.x]:
		for y: float in [0.0, maxf(maximum_height, 0.0)]:
			for z: float in [world_xz_bounds.position.y, world_xz_bounds.end.y]:
				var relative := Vector3(x, y, z) - next_target
				var horizontal := relative.dot(_stable_camera_basis.x)
				var vertical := relative.dot(_stable_camera_basis.y)
				horizontal_min = minf(horizontal_min, horizontal)
				horizontal_max = maxf(horizontal_max, horizontal)
				vertical_min = minf(vertical_min, vertical)
				vertical_max = maxf(vertical_max, vertical)

	var required_vertical := vertical_max - vertical_min
	var required_horizontal := (horizontal_max - horizontal_min) / maxf(aspect, 0.1)
	var required_size := maxf(required_vertical, required_horizontal) * maxf(margin_ratio, 1.0)
	_overview_target = next_target
	_overview_position = _overview_target + _camera_offset
	_overview_size = maxf(_configured_overview_size, required_size)
	_safe_maximum_size = clampf(maximum_focused_size, _safe_minimum_size, _overview_size)
	_default_focused_size = clampf(
		_overview_size * focused_size_ratio,
		_safe_minimum_size,
		_safe_maximum_size
	)
	if not _has_focus:
		_static_focus_point = _overview_target
		_desired_size = _overview_size


func overview_bounds_frame() -> Dictionary:
	return {
		"target": _overview_target,
		"position": _overview_position,
		"size": _overview_size,
	}


## Keeps dynamic hires selectable without rebuilding the controller or changing
## the stable overview framing.
func register_worker(id: int, worker: ChickenView) -> void:
	if id < 0 or worker == null or not is_instance_valid(worker):
		return
	_worker_views[id] = worker


## Removes a released hen from click/Tab selection immediately. If management
## was inspecting that employee, return to the overview before departure.
func unregister_worker(id: int) -> void:
	if _focused_worker_id == id:
		show_overview()
	_worker_views.erase(id)


func _process(delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return

	var target_point := _overview_target
	if _has_focus:
		if _focused_worker_id >= 0:
			var worker := _get_valid_worker(_focused_worker_id)
			if worker == null:
				show_overview()
			else:
				target_point = _worker_focus_point(worker)
				_update_selection_ring(worker, delta)
		else:
			target_point = _static_focus_point

	var desired_position := target_point + _camera_offset
	if _reduced_motion:
		var immediate_transform := _camera.global_transform
		immediate_transform.origin = desired_position
		immediate_transform.basis = _stable_camera_basis
		_camera.global_transform = immediate_transform
		_camera.size = _desired_size
		_transition_seconds_remaining = 0.0
		_active_transition_speed = transition_speed
		return
	var damping := 1.0 - exp(-_active_transition_speed * maxf(delta, 0.0))
	var camera_transform := _camera.global_transform
	camera_transform.origin += (desired_position - camera_transform.origin) * damping
	camera_transform.basis = _stable_camera_basis
	_camera.global_transform = camera_transform
	_camera.size += (_desired_size - _camera.size) * damping

	if _transition_seconds_remaining > 0.0:
		_transition_seconds_remaining = maxf(0.0, _transition_seconds_remaining - delta)
		if is_zero_approx(_transition_seconds_remaining):
			_active_transition_speed = transition_speed


func _unhandled_input(event: InputEvent) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return

	if event.is_action_pressed(CYCLE_HEN_ACTION) and not (event is InputEventKey and event.echo):
		var direction := -1 if event is InputEventKey and (event as InputEventKey).shift_pressed else 1
		_cycle_worker(direction)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(OFFICE_OVERVIEW_ACTION) and not (event is InputEventKey and event.echo):
		if _has_focus:
			show_overview()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		return

	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return

	match mouse_event.button_index:
		MOUSE_BUTTON_LEFT:
			var selected_id := _nearest_projected_worker(mouse_event.position)
			if selected_id >= 0:
				focus_worker(selected_id)
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT:
			if _has_focus:
				show_overview()
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_UP:
			if _has_focus:
				_desired_size = clampf(
					_desired_size * (1.0 - wheel_zoom_ratio),
					_safe_minimum_size,
					_safe_maximum_size
				)
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_DOWN:
			if _has_focus:
				_desired_size = clampf(
					_desired_size * (1.0 + wheel_zoom_ratio),
					_safe_minimum_size,
					_safe_maximum_size
				)
				get_viewport().set_input_as_handled()


## Focuses a worker by simulation ID. Unknown or freed workers are ignored.
func focus_worker(id: int) -> void:
	var worker := _get_valid_worker(id)
	if worker == null:
		return

	_focus_generation += 1
	_has_focus = true
	_focused_worker_id = id
	_static_focus_point = _worker_focus_point(worker)
	_desired_size = _default_focused_size
	current_focus_label = String(worker.name).trim_prefix("Chicken_").replace("_", " ")
	_begin_transition(0.0)
	if _selection_ring != null:
		_selection_ring.visible = true
	focus_changed.emit(current_focus_label, id)


## Focuses an arbitrary office point while preserving the overview orientation.
## A positive duration selects an exponential rate that reaches roughly 99% of
## the requested framing within that many seconds.
func focus_point(
	point: Vector3,
	label: String,
	duration: float = 0.0,
	requested_size: float = -1.0
) -> void:
	_focus_generation += 1
	_has_focus = true
	_focused_worker_id = -1
	_static_focus_point = point
	_desired_size = (
		clampf(requested_size, _safe_minimum_size, _safe_maximum_size)
		if requested_size > 0.0
		else _default_focused_size
	)
	current_focus_label = label
	_begin_transition(duration)
	if _selection_ring != null:
		_selection_ring.visible = false
	focus_changed.emit(current_focus_label, -1)


## Returns to the exact framing captured by configure().
func show_overview() -> void:
	_focus_generation += 1
	_has_focus = false
	_focused_worker_id = -1
	_static_focus_point = _overview_target
	_desired_size = _overview_size
	current_focus_label = ""
	_begin_transition(0.0)
	if _selection_ring != null:
		_selection_ring.visible = false
	focus_changed.emit("", -1)


func is_focused() -> bool:
	return _has_focus


## Accessibility preference applied by Office. Gameplay focus changes and their
## callbacks are preserved; only the nonessential camera easing and ring pulse
## are removed.
func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled


func set_high_contrast(enabled: bool) -> void:
	_high_contrast = enabled
	if _selection_ring == null:
		return
	var material := _selection_ring.material_override as StandardMaterial3D
	if material == null:
		return
	material.albedo_color = Color("ffe071", 0.78) if enabled else Color(0.95, 0.70, 0.22, 0.50)
	material.emission = Color("ffd23f") if enabled else Color(0.95, 0.48, 0.08)
	material.emission_energy_multiplier = 2.0 if enabled else 1.35


## World-space subject used by environmental detail. This lets nearby documents
## resolve during inspection without switching on every label in the building.
func focus_world_position() -> Vector3:
	if not _has_focus:
		return _overview_target
	if _focused_worker_id >= 0:
		var worker := _get_valid_worker(_focused_worker_id)
		if worker != null:
			return _worker_focus_point(worker)
	return _static_focus_point


## Briefly frames a presentation event, then returns to overview unless the player
## chooses another focus while the shot is holding.
func show_event_focus(point: Vector3, label: String, hold_seconds: float = 1.35) -> void:
	if _has_focus:
		return
	focus_point(point, label, 0.38)
	var event_generation := _focus_generation
	await get_tree().create_timer(maxf(0.25, hold_seconds)).timeout
	if event_generation == _focus_generation and _focused_worker_id < 0:
		show_overview()


func _begin_transition(duration: float) -> void:
	_transition_seconds_remaining = maxf(0.0, duration)
	if duration > 0.0:
		_active_transition_speed = -log(EXPONENTIAL_SETTLE_PERCENT) / duration
	else:
		_active_transition_speed = transition_speed


func _get_valid_worker(id: int) -> ChickenView:
	if not _worker_views.has(id):
		return null
	var worker: ChickenView = _worker_views[id]
	if not is_instance_valid(worker) or not worker.is_inside_tree():
		return null
	return worker


func _worker_focus_point(worker: ChickenView) -> Vector3:
	return worker.global_position + Vector3.UP * WORKER_FOCUS_HEIGHT


func _nearest_projected_worker(mouse_position: Vector2) -> int:
	var nearest_id: int = -1
	var nearest_distance_squared := click_radius_pixels * click_radius_pixels
	for worker_id: int in _sorted_worker_ids():
		var worker := _get_valid_worker(worker_id)
		if worker == null:
			continue
		var world_position := _worker_focus_point(worker)
		if _camera.is_position_behind(world_position):
			continue
		var projected_position := _camera.unproject_position(world_position)
		var distance_squared := mouse_position.distance_squared_to(projected_position)
		if distance_squared <= nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_id = worker_id
	return nearest_id


func _cycle_worker(direction: int) -> void:
	var worker_ids := _sorted_worker_ids()
	if worker_ids.is_empty():
		return
	var current_index := worker_ids.find(_focused_worker_id)
	if current_index < 0:
		current_index = -1 if direction > 0 else 0
	var next_index := posmod(current_index + direction, worker_ids.size())
	focus_worker(worker_ids[next_index])


func _sorted_worker_ids() -> Array[int]:
	var result: Array[int] = []
	for worker_id: int in _worker_views:
		if _get_valid_worker(worker_id) != null:
			result.append(worker_id)
	result.sort()
	return result


func _ensure_selection_ring() -> void:
	if _selection_ring != null:
		return
	_selection_ring = MeshInstance3D.new()
	_selection_ring.name = "FocusedEmployeeRing"
	_selection_ring.visible = false
	_selection_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var torus := TorusMesh.new()
	torus.inner_radius = 0.61
	torus.outer_radius = 0.72
	torus.rings = 48
	torus.ring_segments = 12
	_selection_ring.mesh = torus

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.95, 0.70, 0.22, 0.50)
	material.emission_enabled = true
	material.emission = Color(0.95, 0.48, 0.08)
	material.emission_energy_multiplier = 1.35
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_selection_ring.material_override = material
	add_child(_selection_ring)


func _update_selection_ring(worker: ChickenView, delta: float) -> void:
	if _selection_ring == null:
		return
	_selection_ring.visible = true
	_selection_ring.global_position = Vector3(
		worker.global_position.x,
		RING_FLOOR_HEIGHT,
		worker.global_position.z
	)
	# A restrained pulse stays readable against the carpet without competing with
	# the employee's silhouette or status label.
	var pulse := 1.0 if _reduced_motion else 1.0 + sin(Time.get_ticks_msec() * 0.004) * (0.045 if _high_contrast else 0.035)
	_selection_ring.scale = _selection_ring.scale.lerp(Vector3.ONE * pulse, minf(1.0, delta * 10.0))
