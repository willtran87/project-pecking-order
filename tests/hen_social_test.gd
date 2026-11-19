extends SceneTree

const Director := preload("res://features/office/hen_social_director.gd")
const Voices := preload("res://features/chickens/hen_personality.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var director := Director.new()
	var workers: Array[Dictionary] = [
		{"id": 0, "name": "Mabel", "employed": true, "stress": 12.0, "eggs_laid": 2, "position": Vector3.ZERO},
		{"id": 1, "name": "Pip", "employed": true, "stress": 72.0, "eggs_laid": 1, "position": Vector3(2, 0, 0)},
		{"id": 2, "name": "Henrietta", "employed": true, "stress": 12.0, "eggs_laid": 0, "position": Vector3(20, 0, 0)},
	]
	director.observe({"day": 1, "workers": workers})
	_check(director.snapshot().pending == 0, "loaded eggs do not invent new applause")
	director.advance(20.0, workers, false)
	_check(director.current.is_empty(), "paused/modal floor never starts conversation")
	director.advance(8.0, workers)
	_check(director.current.kind == &"comfort" and director.current.second_id == 1, "real strain makes nearest coworker check in")
	_check(director.current.first_id == 0, "distant hen cannot speak across the office")
	var initial_copy := director.current.duplicate(true)
	director.advance(4.0, workers)
	_check(director.snapshot().replying, "listener takes a reply turn")
	workers[0]["ready"] = false
	director.advance(0.0, workers)
	_check(not director.current.is_empty(), "routine laying preserves an exchange while its body animation takes precedence")
	workers[0]["ready"] = true
	director.advance(0.0, workers, false)
	_check(director.elapsed == 4.0 and director.current == initial_copy, "pause freezes exchange for reading")
	director.advance(4.1, workers)
	_check(director.current.is_empty(), "conversation expires")
	director.advance(1.0, workers)
	_check(director.current.is_empty(), "quiet gap prevents chatter spam")
	workers[0].eggs_laid = 3
	director.observe({"day": 1, "workers": workers})
	director.observe({"day": 1, "workers": workers})
	_check(director.snapshot().pending == 0, "laying alone cannot praise an ungraded or cracked egg")
	_check(director.celebrate(0, "egg:14"), "successful delivery can queue congratulations")
	_check(not director.celebrate(0, "egg:14"), "duplicate delivery cannot repeat congratulations")
	_check(director.snapshot().pending == 1, "actual delivery queues exactly one congratulations")
	director.advance(20.0, workers)
	_check(director.current.kind == &"celebrate" and director.current.second_id == 0, "praise addresses actual earning hen")
	director.advance(0.1, [workers[0]])
	_check(director.current.is_empty(), "departure or capture cancels paired interaction")
	director.observe({"day": 2, "workers": workers})
	_check(director.snapshot().pending == 0, "new shift resets transient social state")
	var lines: Array[String] = []
	for id in 6:
		var beat := Voices.exchange(&"chat", {"id": id, "name": "Hen"}, workers[0], 0)
		_check(not String(beat.opening) in lines, "all six hens have distinct voices")
		lines.append(beat.opening)
	# Real rig: social motion yields to earned reactions and leaves no wing drift.
	var view := ChickenView.new()
	view.configure({"id": 0, "name": "Mabel", "desk_index": 0, "state": ChickenState.WorkState.IDLE, "stress": 12.0, "fatigue": 5.0})
	root.add_child(view)
	view.set_physics_process(false)
	view.assign_office_route(Vector3.ZERO, Vector3.ZERO, Vector3.ONE, [], [])
	view.stage_at_workstation_for_introduction()
	for frame in 120:
		view._physics_process(1.0 / 60.0)
	var skeleton := view.find_child("Skeleton3D", true, false) as Skeleton3D
	var bone := skeleton.find_bone("wing_L")
	var rest := skeleton.get_bone_pose_rotation(bone)
	view.set_social_attention(Vector3(2, 0, 0), 1.0, true)
	view._physics_process(0.1)
	_check(view.expression_snapshot().social_speaking, "speaking hen receives physical gesture")
	_check(rest.angle_to(skeleton.get_bone_pose_rotation(bone)) > 0.03, "talking gesture is visibly articulated")
	view.set_reduced_motion(true)
	view._physics_process(0.1)
	_check(rest.angle_to(skeleton.get_bone_pose_rotation(bone)) < 0.002, "reduced motion keeps static attention without wing flutter")
	view.set_social_attention(Vector3.ZERO, 0.0, false)
	view._physics_process(0.1)
	_check(not view.expression_snapshot().social_attention and view.position.is_equal_approx(Vector3.ZERO), "conversation restores pose without moving hen")
	view.free()
	var balloon := HenSocialUI.new()
	root.add_child(balloon)
	var copy := Voices.exchange(&"comfort", workers[0], workers[1], 0)
	for frame in 8:
		balloon.present(copy, true, Vector2(650, 380), Vector2(1280, 720))
		await process_frame
	_check(balloon.visible and balloon.size.y < 180.0 and balloon.position.y >= 142.0, "wrapped balloon shrinks to copy and stays below HUD")
	_check(not balloon.diagnostic_state().blocks_input, "speech does not steal controls")
	var roster_button := Rect2(1050, 160, 210, 44)
	balloon.present(copy, true, Vector2(1000, 230), Vector2(1280, 720), roster_button)
	_check(not Rect2(balloon.position, balloon.size).intersects(roster_button), "speech avoids the visible Flockwatch button")
	balloon.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("HEN_SOCIAL_TEST_FAILED: " + failure)
		quit(1)
	else:
		print("HEN_SOCIAL_TEST_PASSED voices=6 stress=real rewards=exact nearest=bounded pause=stable departure=cancelled rig=restored")
		quit(0)

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
