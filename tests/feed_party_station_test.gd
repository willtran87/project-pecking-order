extends SceneTree

const STATION_SCENE := preload("res://assets/models/feed_party_station.glb")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var station := STATION_SCENE.instantiate() as Node3D
	root.add_child(station)
	await process_frame

	var wheel_names := [
		"TroughCasterWheel_FrontL",
		"TroughCasterWheel_FrontR",
		"TroughCasterWheel_RearL",
		"TroughCasterWheel_RearR",
	]
	var wheels: Array[Node3D] = []
	for wheel_name in wheel_names:
		var wheel := station.find_child(wheel_name, true, false) as Node3D
		_check(wheel != null, "%s should remain independently animatable" % wheel_name, failures)
		if wheel != null:
			wheels.append(wheel)
	_check(wheels.size() == 4, "the mobile trough should export four connected caster wheels", failures)
	_check(
		station.find_child("TroughPushHandleGrip", true, false) != null,
		"the mobile station silhouette should include a push handle",
		failures,
	)

	var attendance_positions: Array[Vector3] = []
	for attendee_index in 6:
		var socket := station.find_child("AttendanceSocket_%d" % attendee_index, true, false) as Node3D
		_check(socket != null, "attendance socket %d should survive Blender export" % attendee_index, failures)
		if socket != null:
			attendance_positions.append(socket.global_position)
	_check(attendance_positions.size() == 6, "all six authored feeding positions should load", failures)
	for first in attendance_positions.size():
		for second in range(first + 1, attendance_positions.size()):
			_check(
				attendance_positions[first].distance_to(attendance_positions[second]) >= 1.45,
				"authored attendance sockets should not overlap chicken bodies",
				failures,
			)

	_check(
		station.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"event dressing should not introduce hidden collision into the audited walking lanes",
		failures,
	)
	_check(
		station.find_child("Trough_VisiblePellets", true, false) != null,
		"the event should retain a visible physical feed bed",
		failures,
	)

	station.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PARTY_STATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PARTY_STATION_TEST_PASSED wheels=4 handle=connected sockets=6 collision=none feed=visible")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
