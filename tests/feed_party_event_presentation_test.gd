extends SceneTree

const OfficeScript := preload("res://features/office/office.gd")
const STATION_POSITION := Vector3(-9.80, 0.0, 0.0)
const ROLL_OFFSET := Vector3(0.0, 0.0, -2.35)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := OfficeScript.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var station := office.get("_feed_party_station") as Node3D
	var wheels := office.get("_feed_party_wheels") as Array[Node3D]
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	_check(station != null, "Office should build the physical Feed Party station", failures)
	_check(wheels.size() == 4, "Office should cache all four independently rolling casters", failures)
	_check(audio != null, "Office should own Feed Party audio feedback", failures)
	if station == null or wheels.size() != 4 or audio == null:
		_finish(office, failures)
		return

	var played_cues: Array[StringName] = []
	audio.cue_played.connect(func(cue: StringName) -> void:
		played_cues.append(cue)
	)
	var preferences: Dictionary = office.get("_player_preferences")
	preferences["motion_mode"] = "full"
	office.set("_player_preferences", preferences)
	office.call("_on_feed_party_funded")
	_check(station.visible, "funding should reveal the physical cart", failures)
	var camera_controller := office.get("_camera_controller") as ManagementCameraController
	_check(
		camera_controller != null
		and camera_controller.camera_mode() == "event_focus"
		and camera_controller.focus_world_position().is_equal_approx(STATION_POSITION + Vector3.UP * 0.72),
		"funding should briefly frame the otherwise off-bounds service-bay arrival",
		failures,
	)
	_check(
		station.position.is_equal_approx(STATION_POSITION + ROLL_OFFSET),
		"full-motion presentation should begin from the authored service-lane offset",
		failures,
	)
	await create_timer(0.95).timeout
	_check(
		station.position.distance_to(STATION_POSITION) <= 0.01,
		"the cart should settle exactly at its collision-audited attendance position",
		failures,
	)
	var rolled_wheels := 0
	for wheel in wheels:
		var base_rotation := float(wheel.get_meta("feed_party_base_rotation_x", wheel.rotation.x))
		if absf(wheel.rotation.x - base_rotation) >= TAU * 2.5:
			rolled_wheels += 1
	_check(rolled_wheels == 4, "all casters should visibly roll with the cart", failures)
	_check(&"feed" in played_cues, "funding should retain the established Feed Party fanfare", failures)

	# Exercise the authoritative attendee callback without waiting for a complete
	# morning commute. It should add physical feedback once, not a duplicate UI cue.
	office.call("_on_feed_party_attendance_ready", 0)
	_check(&"feed_nibble" in played_cues, "an arriving chicken should produce the physical feeding cue", failures)
	office.call("_complete_feed_party_visual")
	await create_timer(0.78).timeout
	_check(not station.visible, "full-motion departure should finish by hiding and resetting the cart", failures)
	_check(station.position.is_equal_approx(STATION_POSITION), "hidden cart should reset to its authored position", failures)
	_check(
		(office.get("_clock") as SimulationClock).speed_index == 0,
		"a Feed Party funded from pause must not silently start production",
		failures,
	)

	preferences["motion_mode"] = "reduced"
	office.set("_player_preferences", preferences)
	office.call("_on_feed_party_funded")
	_check(
		station.visible and station.position.is_equal_approx(STATION_POSITION),
		"reduced-motion presentation should reveal the same event directly at rest",
		failures,
	)
	office.call("_complete_feed_party_visual")
	_check(not station.visible, "reduced-motion departure should resolve without travel", failures)

	_finish(office, failures)


func _finish(office: Node, failures: Array[String]) -> void:
	office.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FEED_PARTY_EVENT_PRESENTATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEED_PARTY_EVENT_PRESENTATION_TEST_PASSED arrival=rolled wheels=4 audio=physical departure=reset reduced_motion=direct")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
