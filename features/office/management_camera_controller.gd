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
@export_range(20.0, 64.0, 1.0) var minimum_touch_radius_window_pixels: float = 30.0
@export_range(1.0, 20.0, 0.1) var transition_speed: float = 7.5
@export_range(1.0, 24.0, 0.1) var worker_follow_speed: float = 10.5
@export_range(1.0, 24.0, 0.1) var manual_pan_damping_speed: float = 14.0
@export_range(1.0, 24.0, 0.1) var zoom_damping_speed: float = 10.0
@export_range(1.0, 24.0, 0.1) var safe_frame_damping_speed: float = 9.0
@export_range(0.1, 1.0, 0.01) var focused_size_ratio: float = 0.36
@export_range(2.0, 8.0, 0.1) var minimum_focused_size: float = 4.0
@export_range(6.0, 16.0, 0.1) var maximum_focused_size: float = 14.5
@export_range(0.05, 0.4, 0.01) var wheel_zoom_ratio: float = 0.12
@export_range(100.0, 1200.0, 10.0) var keyboard_pan_pixels_per_second: float = 560.0
@export_range(12.0, 96.0, 1.0) var keyboard_tap_pan_pixels: float = 42.0
@export_range(100.0, 1200.0, 10.0) var controller_pan_pixels_per_second: float = 500.0
@export_range(0.2, 3.0, 0.05) var controller_zoom_exponent_per_second: float = 1.15
@export_range(0.05, 0.6, 0.01) var controller_deadzone: float = 0.22
@export_range(4.0, 32.0, 1.0) var touch_drag_threshold_pixels: float = 12.0

const WORKER_FOCUS_HEIGHT := 0.82
const RING_FLOOR_HEIGHT := 0.035
const EXPONENTIAL_SETTLE_PERCENT := 0.01
const CYCLE_HEN_ACTION: StringName = &"cycle_hen"
const OFFICE_OVERVIEW_ACTION: StringName = &"office_overview"
const CAMERA_PAN_LEFT_ACTION: StringName = &"camera_pan_left"
const CAMERA_PAN_RIGHT_ACTION: StringName = &"camera_pan_right"
const CAMERA_PAN_UP_ACTION: StringName = &"camera_pan_up"
const CAMERA_PAN_DOWN_ACTION: StringName = &"camera_pan_down"
const CAMERA_ZOOM_IN_ACTION: StringName = &"camera_zoom_in"
const CAMERA_ZOOM_OUT_ACTION: StringName = &"camera_zoom_out"
const CAMERA_PAN_DIRECTIONS := {
	CAMERA_PAN_LEFT_ACTION: Vector2.LEFT,
	CAMERA_PAN_RIGHT_ACTION: Vector2.RIGHT,
	CAMERA_PAN_UP_ACTION: Vector2.UP,
	CAMERA_PAN_DOWN_ACTION: Vector2.DOWN,
}
const CAMERA_POSITION_EPSILON_SQUARED := 0.00000025
const CAMERA_SIZE_EPSILON := 0.0005

enum CameraMode {
	HOME,
	FREE_OVERVIEW,
	WORKER_FOCUS,
	LANDMARK_FOCUS,
	EVENT_FOCUS,
}

const CAMERA_MODE_NAMES := {
	CameraMode.HOME: "home",
	CameraMode.FREE_OVERVIEW: "free_overview",
	CameraMode.WORKER_FOCUS: "worker_focus",
	CameraMode.LANDMARK_FOCUS: "landmark_focus",
	CameraMode.EVENT_FOCUS: "event_focus",
}

var current_focus_label: String = ""

var _camera: Camera3D
var _worker_views: Dictionary[int, ChickenView] = {}
var _overview_position := Vector3.ZERO
var _overview_target := Vector3.ZERO
var _overview_size: float = 20.0
var _configured_overview_size: float = 20.0
var _camera_offset := Vector3.ZERO
var _stable_camera_basis := Basis.IDENTITY
var _navigation_bounds_xz := Rect2(Vector2(-10.0, -10.0), Vector2(20.0, 20.0))

var _mode: CameraMode = CameraMode.HOME
var _has_focus: bool = false
var _focused_worker_id: int = -1
var _static_focus_point := Vector3.ZERO
var _free_overview_target := Vector3.ZERO
var _manual_view_offset := Vector3.ZERO
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
var _safe_viewport_insets := Vector4.ZERO # left, right, top, bottom in pixels
var _current_safe_frame_world_offset := Vector3.ZERO

var _pressed_pan_keys: Dictionary[Key, Vector2] = {}
var _pressed_pan_buttons: Dictionary[int, Vector2] = {}
var _joy_pan := Vector2.ZERO
var _joy_zoom: float = 0.0
var _mouse_pan_active: bool = false
var _active_touches: Dictionary[int, Vector2] = {}
var _touch_start_positions: Dictionary[int, Vector2] = {}
var _touch_max_travel: Dictionary[int, float] = {}
var _touch_pinch_distance: float = -1.0
var _touch_pinch_center := Vector2.ZERO
var _touch_gesture_had_multitouch: bool = false


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
	_free_overview_target = _overview_target
	_manual_view_offset = Vector3.ZERO
	var viewport_size := camera.get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var fallback_half_extent := Vector2(
		_overview_size * maxf(aspect, 1.0) * 0.5,
		_overview_size * maxf(aspect, 1.0) * 0.5,
	)
	_navigation_bounds_xz = Rect2(
		Vector2(_overview_target.x, _overview_target.z) - fallback_half_extent,
		fallback_half_extent * 2.0,
	)
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
		margin_ratio: float = 1.12,
		minimum_overview_size: float = -1.0
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
	var presentation_minimum := (
		minimum_overview_size
		if minimum_overview_size > 0.0
		else _configured_overview_size
	)
	_overview_size = maxf(presentation_minimum, required_size)
	_navigation_bounds_xz = world_xz_bounds
	_safe_maximum_size = clampf(maximum_focused_size, _safe_minimum_size, _overview_size)
	_default_focused_size = clampf(
		_overview_size * focused_size_ratio,
		_safe_minimum_size,
		_safe_maximum_size
	)
	if _mode == CameraMode.HOME:
		_static_focus_point = _overview_target
		_free_overview_target = _overview_target
		_manual_view_offset = Vector3.ZERO
		_desired_size = _overview_size
	elif _mode == CameraMode.FREE_OVERVIEW:
		_free_overview_target = _clamp_navigation_target(_free_overview_target)
		_desired_size = minf(_desired_size, _overview_size)
	elif _mode == CameraMode.LANDMARK_FOCUS:
		_desired_size = minf(_desired_size, _overview_size)
		_clamp_manual_view_offset()
	elif _mode == CameraMode.EVENT_FOCUS:
		# A short presentation may legitimately happen just outside the ordinary
		# commissioned navigation rectangle (the Feed Party service bay is the
		# canonical case). Keep its authored subject intact; the event restores the
		# player's already-bounded camera state when its hold completes.
		_desired_size = minf(_desired_size, _overview_size)


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

	if is_processing_unhandled_input():
		_apply_continuous_navigation(delta)
	else:
		_clear_navigation_inputs()

	if _mode == CameraMode.WORKER_FOCUS:
		var worker := _get_valid_worker(_focused_worker_id)
		if worker == null:
			show_overview()
		else:
			_update_selection_ring(worker, delta)

	var desired_safe_offset := _safe_frame_world_offset(_desired_size)
	if _reduced_motion:
		_current_safe_frame_world_offset = desired_safe_offset
		var immediate_position := _view_target_point() + _camera_offset + _current_safe_frame_world_offset
		var immediate_transform := _camera.global_transform
		immediate_transform.origin = immediate_position
		immediate_transform.basis = _stable_camera_basis
		_camera.global_transform = immediate_transform
		_camera.size = _desired_size
		_transition_seconds_remaining = 0.0
		_active_transition_speed = transition_speed
		return

	var safe_damping := _exponential_damping(safe_frame_damping_speed, delta)
	_current_safe_frame_world_offset += (
		desired_safe_offset - _current_safe_frame_world_offset
	) * safe_damping
	var desired_position := _view_target_point() + _camera_offset + _current_safe_frame_world_offset
	var position_speed := _position_damping_speed()
	var position_damping := _exponential_damping(position_speed, delta)
	var camera_transform := _camera.global_transform
	var position_delta := desired_position - camera_transform.origin
	if position_delta.length_squared() > CAMERA_POSITION_EPSILON_SQUARED:
		camera_transform.origin += position_delta * position_damping
		camera_transform.basis = _stable_camera_basis
		_camera.global_transform = camera_transform
	var size_delta := _desired_size - _camera.size
	if absf(size_delta) > CAMERA_SIZE_EPSILON:
		var size_speed := _active_transition_speed if _transition_seconds_remaining > 0.0 else zoom_damping_speed
		_camera.size += size_delta * _exponential_damping(size_speed, delta)

	if _transition_seconds_remaining > 0.0:
		_transition_seconds_remaining = maxf(0.0, _transition_seconds_remaining - delta)
		if is_zero_approx(_transition_seconds_remaining):
			_active_transition_speed = transition_speed


func _input(event: InputEvent) -> void:
	# Floor camera keys must precede GUI focus navigation. HUD buttons remain
	# focusable for accessibility, but a previously focused button must not make
	# the documented arrow/WASD camera controls appear intermittently broken.
	# Office disables this entire phase while a modal or Flockwatch owns input.
	if event is InputEventKey:
		if _handle_navigation_key(event as InputEventKey):
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		if _handle_navigation_button(event as InputEventJoypadButton):
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _camera == null or not is_instance_valid(_camera):
		return

	if event.is_action_pressed(CYCLE_HEN_ACTION) and not (event is InputEventKey and event.echo):
		var direction := -1 if event is InputEventKey and (event as InputEventKey).shift_pressed else 1
		_cycle_worker(direction)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(OFFICE_OVERVIEW_ACTION) and not (event is InputEventKey and event.echo):
		if _mode != CameraMode.HOME:
			show_overview()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		if _handle_navigation_key(event as InputEventKey):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton:
		if _handle_navigation_button(event as InputEventJoypadButton):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if _mouse_pan_active:
			var motion := event as InputEventMouseMotion
			_pan_by_screen_delta(motion.relative)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventJoypadMotion:
		if _handle_joy_motion(event as InputEventJoypadMotion):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		if _handle_screen_touch(event as InputEventScreenTouch):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		if _handle_screen_drag(event as InputEventScreenDrag):
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		if magnify.factor > 0.0 and not is_equal_approx(magnify.factor, 1.0):
			_zoom_at_screen(1.0 / magnify.factor, magnify.position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventPanGesture:
		var pan_gesture := event as InputEventPanGesture
		_pan_by_screen_delta(pan_gesture.delta)
		get_viewport().set_input_as_handled()
		return

	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	match mouse_event.button_index:
		MOUSE_BUTTON_MIDDLE:
			_mouse_pan_active = mouse_event.pressed
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var selected_id := _nearest_projected_worker(mouse_event.position, false)
				if selected_id >= 0:
					focus_worker(selected_id)
					get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed and _mode != CameraMode.HOME:
				show_overview()
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			if not mouse_event.pressed:
				return
			var wheel_amount := maxf(mouse_event.factor, 0.01)
			var multiplier := pow(1.0 + wheel_zoom_ratio, wheel_amount)
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				multiplier = 1.0 / multiplier
			_zoom_at_screen(multiplier, mouse_event.position)
			get_viewport().set_input_as_handled()


## Focuses a worker by simulation ID. Unknown or freed workers are ignored.
func focus_worker(id: int) -> void:
	var worker := _get_valid_worker(id)
	if worker == null:
		return

	_focus_generation += 1
	_mode = CameraMode.WORKER_FOCUS
	_has_focus = true
	_focused_worker_id = id
	_static_focus_point = _worker_focus_point(worker)
	_manual_view_offset = Vector3.ZERO
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
	_mode = CameraMode.LANDMARK_FOCUS
	_has_focus = true
	_focused_worker_id = -1
	_static_focus_point = point
	_manual_view_offset = Vector3.ZERO
	_desired_size = (
		clampf(requested_size, _safe_minimum_size, _overview_size)
		if requested_size > 0.0
		else _default_focused_size
	)
	current_focus_label = label
	_begin_transition(duration)
	if _selection_ring != null:
		_selection_ring.visible = false
	focus_changed.emit(current_focus_label, -1)


## Returns to the exact authored/commissioned Home framing.
func show_overview() -> void:
	_focus_generation += 1
	_mode = CameraMode.HOME
	_has_focus = false
	_focused_worker_id = -1
	_static_focus_point = _overview_target
	_free_overview_target = _overview_target
	_manual_view_offset = Vector3.ZERO
	_desired_size = _overview_size
	current_focus_label = ""
	_begin_transition(0.0)
	if _selection_ring != null:
		_selection_ring.visible = false
	focus_changed.emit("", -1)


func is_focused() -> bool:
	return _has_focus


func camera_mode() -> String:
	return String(CAMERA_MODE_NAMES.get(_mode, "home"))


## Stable camera diagnostics for tests, browser instrumentation, and contextual
## help. Values describe the requested frame; camera easing may still be settling.
func navigation_state() -> Dictionary:
	return {
		"mode": camera_mode(),
		"input_enabled": is_processing_unhandled_input(),
		"focused": _has_focus,
		"focused_worker_id": _focused_worker_id,
		"desired_size": _desired_size,
		"view_target": _view_target_point(),
		"home_target": _overview_target,
		"home_size": _overview_size,
		"bounds": _navigation_bounds_xz,
	}


## One discrete zoom step for non-keyboard hosts such as the Web touch dock.
## This keeps bounds, anchoring, and camera-mode transitions in one authority.
func request_zoom_step(zoom_in: bool) -> void:
	var multiplier := 1.0 + wheel_zoom_ratio
	if zoom_in:
		multiplier = 1.0 / multiplier
	_zoom_at_screen(multiplier, _viewport_center())


## Reserves UI-covered pixels without changing the current subject, focus mode,
## or orthographic size. Insets are eased by the same camera damping as all
## other presentation changes, and reduced-motion applies them immediately.
func set_safe_viewport_insets(
		left: float,
		right: float,
		top: float,
		bottom: float
) -> void:
	_safe_viewport_insets = Vector4(
		maxf(left, 0.0),
		maxf(right, 0.0),
		maxf(top, 0.0),
		maxf(bottom, 0.0),
	)


func safe_framing_state() -> Dictionary:
	return {
		"left": _safe_viewport_insets.x,
		"right": _safe_viewport_insets.y,
		"top": _safe_viewport_insets.z,
		"bottom": _safe_viewport_insets.w,
		"focused": _has_focus,
		"focused_worker_id": _focused_worker_id,
		"mode": camera_mode(),
		"desired_size": _desired_size,
		"subject": focus_world_position(),
		"world_offset": _safe_frame_world_offset(_desired_size),
	}


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
	if _mode == CameraMode.FREE_OVERVIEW:
		return _free_overview_target
	if _mode == CameraMode.HOME:
		return _overview_target
	if _mode == CameraMode.WORKER_FOCUS:
		var worker := _get_valid_worker(_focused_worker_id)
		if worker != null:
			return _worker_focus_point(worker)
	return _static_focus_point


## Briefly frames a presentation event, then restores the player's exact previous
## camera mode, subject, manual offset, and zoom. Passive events respect an active
## inspection; accepted transactions may explicitly interrupt and later restore it.
func show_event_focus(
	point: Vector3,
	label: String,
	hold_seconds: float = 1.35,
	override_existing_focus: bool = false
) -> void:
	if _has_focus and not override_existing_focus:
		return
	var previous_state := _capture_camera_state()
	_focus_generation += 1
	_mode = CameraMode.EVENT_FOCUS
	_has_focus = true
	_focused_worker_id = -1
	_static_focus_point = point
	_manual_view_offset = Vector3.ZERO
	_desired_size = _default_focused_size
	current_focus_label = label
	_begin_transition(0.38)
	if _selection_ring != null:
		_selection_ring.visible = false
	focus_changed.emit(current_focus_label, -1)
	var event_generation := _focus_generation
	await get_tree().create_timer(maxf(0.25, hold_seconds)).timeout
	if event_generation == _focus_generation and _mode == CameraMode.EVENT_FOCUS:
		_restore_camera_state(previous_state)


func _capture_camera_state() -> Dictionary:
	return {
		"mode": int(_mode),
		"has_focus": _has_focus,
		"focused_worker_id": _focused_worker_id,
		"static_focus_point": _static_focus_point,
		"free_overview_target": _free_overview_target,
		"manual_view_offset": _manual_view_offset,
		"desired_size": _desired_size,
		"label": current_focus_label,
	}


func _restore_camera_state(state: Dictionary) -> void:
	var restored_mode := int(state.get("mode", CameraMode.HOME))
	if restored_mode == CameraMode.WORKER_FOCUS:
		var restored_worker_id := int(state.get("focused_worker_id", -1))
		if _get_valid_worker(restored_worker_id) == null:
			show_overview()
			return
	_focus_generation += 1
	match restored_mode:
		CameraMode.FREE_OVERVIEW:
			_mode = CameraMode.FREE_OVERVIEW
		CameraMode.WORKER_FOCUS:
			_mode = CameraMode.WORKER_FOCUS
		CameraMode.LANDMARK_FOCUS:
			_mode = CameraMode.LANDMARK_FOCUS
		CameraMode.EVENT_FOCUS:
			# An event interrupted by another event restores as a landmark rather
			# than creating an event state with no owner/timer.
			_mode = CameraMode.LANDMARK_FOCUS
		_:
			_mode = CameraMode.HOME
	_has_focus = _mode in [
		CameraMode.WORKER_FOCUS,
		CameraMode.LANDMARK_FOCUS,
		CameraMode.EVENT_FOCUS,
	]
	_focused_worker_id = int(state.get("focused_worker_id", -1)) if _mode == CameraMode.WORKER_FOCUS else -1
	_static_focus_point = state.get("static_focus_point", _overview_target) as Vector3
	_free_overview_target = _clamp_navigation_target(
		state.get("free_overview_target", _overview_target) as Vector3
	)
	_manual_view_offset = state.get("manual_view_offset", Vector3.ZERO) as Vector3
	current_focus_label = String(state.get("label", "")) if _has_focus else ""
	var requested_size := float(state.get("desired_size", _overview_size))
	var limits := _zoom_limits_for_mode()
	_desired_size = clampf(requested_size, limits.x, limits.y)
	_clamp_manual_view_offset()
	_begin_transition(0.28)
	if _selection_ring != null:
		_selection_ring.visible = _mode == CameraMode.WORKER_FOCUS
	focus_changed.emit(current_focus_label, _focused_worker_id if _mode == CameraMode.WORKER_FOCUS else -1)


func _view_target_point() -> Vector3:
	var subject := _overview_target
	match _mode:
		CameraMode.FREE_OVERVIEW:
			subject = _free_overview_target
		CameraMode.WORKER_FOCUS:
			var worker := _get_valid_worker(_focused_worker_id)
			subject = _worker_focus_point(worker) if worker != null else _static_focus_point
		CameraMode.LANDMARK_FOCUS, CameraMode.EVENT_FOCUS:
			subject = _static_focus_point
	return subject + _manual_view_offset


func _enter_free_overview_from_current_view() -> void:
	if _mode == CameraMode.FREE_OVERVIEW:
		return
	var current_target := _view_target_point()
	_focus_generation += 1
	_mode = CameraMode.FREE_OVERVIEW
	_has_focus = false
	_focused_worker_id = -1
	_free_overview_target = _clamp_navigation_target(Vector3(
		current_target.x,
		_overview_target.y,
		current_target.z,
	))
	_manual_view_offset = Vector3.ZERO
	current_focus_label = ""
	_begin_transition(0.0)
	if _selection_ring != null:
		_selection_ring.visible = false
	focus_changed.emit("", -1)


func _clamp_navigation_target(point: Vector3) -> Vector3:
	if _navigation_bounds_xz.size.x <= 0.0 or _navigation_bounds_xz.size.y <= 0.0:
		return Vector3(point.x, _overview_target.y, point.z)
	return Vector3(
		clampf(point.x, _navigation_bounds_xz.position.x, _navigation_bounds_xz.end.x),
		_overview_target.y,
		clampf(point.z, _navigation_bounds_xz.position.y, _navigation_bounds_xz.end.y),
	)


func _clamp_manual_view_offset() -> void:
	if _mode in [CameraMode.HOME, CameraMode.FREE_OVERVIEW]:
		_manual_view_offset = Vector3.ZERO
		return
	var current_target := _view_target_point()
	var clamped_target := _clamp_navigation_target(current_target)
	# Bounds apply on the management floor's X/Z plane. Landmark and worker
	# framing retain their authored vertical subject height.
	clamped_target.y = current_target.y
	_manual_view_offset += clamped_target - current_target


func _zoom_limits_for_mode() -> Vector2:
	if _mode == CameraMode.WORKER_FOCUS:
		return Vector2(_safe_minimum_size, _safe_maximum_size)
	return Vector2(_safe_minimum_size, maxf(_safe_minimum_size, _overview_size))


func _zoom_at_screen(size_multiplier: float, screen_position: Vector2) -> void:
	if size_multiplier <= 0.0 or not is_finite(size_multiplier):
		return
	if _mode == CameraMode.EVENT_FOCUS:
		_enter_free_overview_from_current_view()
	var limits := _zoom_limits_for_mode()
	var next_size := clampf(_desired_size * size_multiplier, limits.x, limits.y)
	if is_equal_approx(next_size, _desired_size):
		return
	var target_before := _view_target_point()
	var anchor_before := _ground_point_at_screen(screen_position, _desired_size, target_before)
	if _mode == CameraMode.HOME:
		_enter_free_overview_from_current_view()
		target_before = _view_target_point()
		anchor_before = _ground_point_at_screen(screen_position, _desired_size, target_before)
	var anchor_after := _ground_point_at_screen(screen_position, next_size, target_before)
	var correction := anchor_before - anchor_after
	if _mode == CameraMode.FREE_OVERVIEW:
		_free_overview_target = _clamp_navigation_target(_free_overview_target + correction)
	else:
		_manual_view_offset += correction
		_clamp_manual_view_offset()
	_desired_size = next_size


func _pan_by_screen_delta(screen_delta: Vector2) -> void:
	if screen_delta.is_zero_approx():
		return
	_enter_free_overview_from_current_view()
	var center := _viewport_center()
	var target := _free_overview_target
	var before := _ground_point_at_screen(center, _desired_size, target)
	var after := _ground_point_at_screen(center + screen_delta, _desired_size, target)
	_free_overview_target = _clamp_navigation_target(target + before - after)


func _ground_point_at_screen(
		screen_position: Vector2,
		orthographic_size: float,
		view_target: Vector3
) -> Vector3:
	var viewport_size := _camera.get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return Vector3(view_target.x, _overview_target.y, view_target.z)
	var horizontal_span := orthographic_size * viewport_size.x / viewport_size.y
	var horizontal_offset := (screen_position.x / viewport_size.x - 0.5) * horizontal_span
	var vertical_offset := (0.5 - screen_position.y / viewport_size.y) * orthographic_size
	var ray_origin := (
		view_target
		+ _camera_offset
		+ _safe_frame_world_offset(orthographic_size)
		+ _stable_camera_basis.x * horizontal_offset
		+ _stable_camera_basis.y * vertical_offset
	)
	var ray_direction := -_stable_camera_basis.z
	if absf(ray_direction.y) <= 0.0001:
		return Vector3(ray_origin.x, _overview_target.y, ray_origin.z)
	var distance_to_ground := (_overview_target.y - ray_origin.y) / ray_direction.y
	var intersection := ray_origin + ray_direction * distance_to_ground
	intersection.y = _overview_target.y
	return intersection


func _viewport_center() -> Vector2:
	return _camera.get_viewport().get_visible_rect().size * 0.5


func _position_damping_speed() -> float:
	if _transition_seconds_remaining > 0.0:
		return _active_transition_speed
	if _mode == CameraMode.WORKER_FOCUS:
		return worker_follow_speed
	if _mode == CameraMode.FREE_OVERVIEW:
		return manual_pan_damping_speed
	return transition_speed


func _exponential_damping(speed: float, delta: float) -> float:
	return 1.0 - exp(-maxf(speed, 0.0) * maxf(delta, 0.0))


func _apply_continuous_navigation(delta: float) -> void:
	var keyboard_direction := Vector2.ZERO
	for keycode: Key in _pressed_pan_keys:
		keyboard_direction += _pressed_pan_keys[keycode]
	for button_index: int in _pressed_pan_buttons:
		keyboard_direction += _pressed_pan_buttons[button_index]
	if keyboard_direction.length_squared() > 1.0:
		keyboard_direction = keyboard_direction.normalized()
	var controller_direction := _deadzone_vector(_joy_pan)
	var screen_motion := (
		keyboard_direction * keyboard_pan_pixels_per_second
		+ controller_direction * controller_pan_pixels_per_second
	) * delta
	if not screen_motion.is_zero_approx():
		# Keyboard/stick directions describe where the camera should travel;
		# mouse drags describe where the grabbed floor moved, hence the sign.
		_pan_by_screen_delta(-screen_motion)
	var controller_zoom := _deadzone_scalar(_joy_zoom)
	if not is_zero_approx(controller_zoom):
		_zoom_at_screen(
			exp(controller_zoom_exponent_per_second * controller_zoom * delta),
			_viewport_center(),
		)


func _deadzone_vector(value: Vector2) -> Vector2:
	var strength := value.length()
	if strength <= controller_deadzone:
		return Vector2.ZERO
	var remapped := (strength - controller_deadzone) / maxf(1.0 - controller_deadzone, 0.01)
	return value.normalized() * minf(remapped, 1.0)


func _deadzone_scalar(value: float) -> float:
	var magnitude := absf(value)
	if magnitude <= controller_deadzone:
		return 0.0
	var remapped := (magnitude - controller_deadzone) / maxf(1.0 - controller_deadzone, 0.01)
	return signf(value) * minf(remapped, 1.0)


func _clear_navigation_inputs() -> void:
	_pressed_pan_keys.clear()
	_pressed_pan_buttons.clear()
	_joy_pan = Vector2.ZERO
	_joy_zoom = 0.0
	_mouse_pan_active = false
	_active_touches.clear()
	_touch_start_positions.clear()
	_touch_max_travel.clear()
	_touch_pinch_distance = -1.0
	_touch_pinch_center = Vector2.ZERO
	_touch_gesture_had_multitouch = false


func _handle_navigation_key(event: InputEventKey) -> bool:
	var keycode: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	for action_value: StringName in CAMERA_PAN_DIRECTIONS:
		var action := StringName(action_value)
		if not event.is_action_pressed(action) and not event.is_action_released(action):
			continue
		var direction := CAMERA_PAN_DIRECTIONS[action] as Vector2
		if event.is_action_released(action):
			_pressed_pan_keys.erase(keycode)
		elif event.is_action_pressed(action):
			_pressed_pan_keys[keycode] = direction
			if not event.echo:
				# Apply one bounded nudge on the press event itself. Without this, a
				# quick tap that begins and ends between two slow rendered frames never
				# reaches _apply_continuous_navigation and feels like dropped input.
				_pan_by_screen_delta(-direction * keyboard_tap_pan_pixels)
		return true
	if not event.pressed or event.echo:
		return false
	if keycode == KEY_HOME:
		show_overview()
		return true
	if event.is_action_pressed(CAMERA_ZOOM_IN_ACTION):
		_zoom_at_screen(1.0 / (1.0 + wheel_zoom_ratio), _viewport_center())
		return true
	if event.is_action_pressed(CAMERA_ZOOM_OUT_ACTION):
		_zoom_at_screen(1.0 + wheel_zoom_ratio, _viewport_center())
		return true
	return false


func _handle_navigation_button(event: InputEventJoypadButton) -> bool:
	for action_value: StringName in CAMERA_PAN_DIRECTIONS:
		var action := StringName(action_value)
		if not event.is_action_pressed(action) and not event.is_action_released(action):
			continue
		var direction := CAMERA_PAN_DIRECTIONS[action] as Vector2
		if event.is_action_released(action):
			_pressed_pan_buttons.erase(event.button_index)
		elif event.is_action_pressed(action):
			_pressed_pan_buttons[event.button_index] = direction
			_pan_by_screen_delta(-direction * keyboard_tap_pan_pixels)
		return true
	if not event.pressed:
		return false
	if event.is_action_pressed(CAMERA_ZOOM_IN_ACTION):
		_zoom_at_screen(1.0 / (1.0 + wheel_zoom_ratio), _viewport_center())
		return true
	if event.is_action_pressed(CAMERA_ZOOM_OUT_ACTION):
		_zoom_at_screen(1.0 + wheel_zoom_ratio, _viewport_center())
		return true
	return false


func _handle_joy_motion(event: InputEventJoypadMotion) -> bool:
	match event.axis:
		JOY_AXIS_LEFT_X:
			_joy_pan.x = event.axis_value
		JOY_AXIS_LEFT_Y:
			_joy_pan.y = event.axis_value
		JOY_AXIS_RIGHT_Y:
			_joy_zoom = event.axis_value
		_:
			return false
	return true


func _handle_screen_touch(event: InputEventScreenTouch) -> bool:
	if event.pressed:
		_active_touches[event.index] = event.position
		_touch_start_positions[event.index] = event.position
		_touch_max_travel[event.index] = 0.0
		if _active_touches.size() >= 2:
			_touch_gesture_had_multitouch = true
			_reset_touch_pinch_baseline()
		return true
	if not _active_touches.has(event.index):
		return false
	var travel := float(_touch_max_travel.get(event.index, INF))
	var is_tap := (
		_active_touches.size() == 1
		and not _touch_gesture_had_multitouch
		and travel <= touch_drag_threshold_pixels
	)
	_active_touches.erase(event.index)
	_touch_start_positions.erase(event.index)
	_touch_max_travel.erase(event.index)
	if _active_touches.size() < 2:
		_touch_pinch_distance = -1.0
		_touch_pinch_center = Vector2.ZERO
	if is_tap:
		var selected_id := _nearest_projected_worker(event.position, true)
		if selected_id >= 0:
			focus_worker(selected_id)
	if _active_touches.is_empty():
		_touch_gesture_had_multitouch = false
	return true


func _handle_screen_drag(event: InputEventScreenDrag) -> bool:
	if not _active_touches.has(event.index):
		_active_touches[event.index] = event.position
		_touch_start_positions[event.index] = event.position - event.relative
		_touch_max_travel[event.index] = 0.0
	_active_touches[event.index] = event.position
	var start := _touch_start_positions.get(event.index, event.position) as Vector2
	_touch_max_travel[event.index] = maxf(
		float(_touch_max_travel.get(event.index, 0.0)),
		start.distance_to(event.position),
	)
	if _active_touches.size() == 1 and not _touch_gesture_had_multitouch:
		if float(_touch_max_travel[event.index]) > touch_drag_threshold_pixels:
			_pan_by_screen_delta(event.relative)
		return true
	_touch_gesture_had_multitouch = true
	var touch_ids: Array[int] = []
	for touch_id: int in _active_touches:
		touch_ids.append(touch_id)
	touch_ids.sort()
	if touch_ids.size() < 2:
		return true
	var first := _active_touches[touch_ids[0]] as Vector2
	var second := _active_touches[touch_ids[1]] as Vector2
	var next_center := (first + second) * 0.5
	var next_distance := first.distance_to(second)
	if _touch_pinch_distance > 0.01:
		var center_delta := next_center - _touch_pinch_center
		if not center_delta.is_zero_approx():
			_pan_by_screen_delta(center_delta)
		if next_distance > 0.01:
			_zoom_at_screen(_touch_pinch_distance / next_distance, next_center)
	_touch_pinch_center = next_center
	_touch_pinch_distance = next_distance
	return true


func _reset_touch_pinch_baseline() -> void:
	var touch_ids: Array[int] = []
	for touch_id: int in _active_touches:
		touch_ids.append(touch_id)
	touch_ids.sort()
	if touch_ids.size() < 2:
		_touch_pinch_distance = -1.0
		_touch_pinch_center = Vector2.ZERO
		return
	var first := _active_touches[touch_ids[0]] as Vector2
	var second := _active_touches[touch_ids[1]] as Vector2
	_touch_pinch_distance = first.distance_to(second)
	_touch_pinch_center = (first + second) * 0.5


func _begin_transition(duration: float) -> void:
	_transition_seconds_remaining = maxf(0.0, duration)
	if duration > 0.0:
		_active_transition_speed = -log(EXPONENTIAL_SETTLE_PERCENT) / duration
	else:
		_active_transition_speed = transition_speed


func _safe_frame_world_offset(orthographic_size: float) -> Vector3:
	if _camera == null or not is_instance_valid(_camera):
		return Vector3.ZERO
	var viewport_size := _camera.get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return Vector3.ZERO
	var horizontal_span := orthographic_size * viewport_size.x / viewport_size.y
	var horizontal_shift := (
		(_safe_viewport_insets.y - _safe_viewport_insets.x)
		* 0.5
		/ viewport_size.x
		* horizontal_span
	)
	var vertical_shift := (
		(_safe_viewport_insets.z - _safe_viewport_insets.w)
		* 0.5
		/ viewport_size.y
		* orthographic_size
	)
	return (
		_stable_camera_basis.x * horizontal_shift
		+ _stable_camera_basis.y * vertical_shift
	)


func _get_valid_worker(id: int) -> ChickenView:
	if not _worker_views.has(id):
		return null
	var worker: ChickenView = _worker_views[id]
	if not is_instance_valid(worker) or not worker.is_inside_tree():
		return null
	return worker


func _worker_focus_point(worker: ChickenView) -> Vector3:
	return worker.global_position + Vector3.UP * WORKER_FOCUS_HEIGHT


## Returns the hit radius in viewport coordinates. On a downscaled Web canvas,
## touch events use a larger internal radius so their physical target never
## shrinks below the configured window-pixel minimum.
func selection_radius_pixels(for_touch: bool = false) -> float:
	if not for_touch or _camera == null or not is_instance_valid(_camera):
		return click_radius_pixels
	var viewport_size := _camera.get_viewport().get_visible_rect().size
	var window_size := Vector2(DisplayServer.window_get_size())
	if window_size.x <= 1.0 or window_size.y <= 1.0:
		return maxf(click_radius_pixels, minimum_touch_radius_window_pixels)
	var viewport_per_window_pixel := maxf(
		viewport_size.x / window_size.x,
		viewport_size.y / window_size.y,
	)
	return maxf(
		click_radius_pixels,
		minimum_touch_radius_window_pixels * maxf(viewport_per_window_pixel, 1.0),
	)


func _nearest_projected_worker(mouse_position: Vector2, for_touch: bool = false) -> int:
	var nearest_id: int = -1
	var selection_radius := selection_radius_pixels(for_touch)
	var nearest_distance_squared := selection_radius * selection_radius
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


## Player-facing semantic equivalent of the cycle-hen input action.
##
## The Web shell uses this for its visible touch control and for browsers that
## reserve Tab before Godot can receive it. Office still owns modal gating.
func cycle_worker(direction: int = 1) -> void:
	_cycle_worker(1 if direction >= 0 else -1)


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
