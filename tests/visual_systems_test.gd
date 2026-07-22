extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var camera := office.find_child("ManagementCamera", true, false) as Camera3D
	var controller := office.find_child("ManagementCameraController", true, false) as ManagementCameraController
	var overview_size := camera.size if camera != null else 0.0
	var flockwatch := office.find_child("FlockwatchLedger", true, false) as Control
	_check(flockwatch != null and not flockwatch.visible, "Flockwatch should not cover the default office view", failures)
	_check(camera != null and controller != null, "inspection camera system should initialize", failures)
	if controller != null and camera != null:
		controller.focus_worker(0)
		await create_timer(0.45).timeout
		_check(controller.is_focused(), "inspection camera should focus a worker", failures)
		_check(camera.size < overview_size * 0.75, "inspection camera should smoothly zoom closer", failures)
		var ring := office.find_child("FocusedEmployeeRing", true, false) as MeshInstance3D
		_check(ring != null and ring.visible, "focused workers should receive a floor selection ring", failures)
		controller.show_overview()
		controller.show_event_focus(Vector3(0.0, 0.8, 0.0), "TEST PRESENTATION", 0.30)
		await create_timer(0.12).timeout
		_check(controller.is_focused(), "presentation events should receive a brief cinematic frame", failures)
		await create_timer(0.32).timeout
		_check(not controller.is_focused(), "event framing should return to overview automatically", failures)
		controller.focus_point(Vector3(15.2, 1.05, 21.0), "CARE CAMPUS", 0.0, 14.2)
		_check(
			is_equal_approx(float(controller.get("_desired_size")), 14.2),
			"campus inspection should preserve the authored 14.2 framing instead of silently clamping to 11",
			failures,
		)
		controller.show_overview()

	var presence := office.find_child("ManagementPresence", true, false) as ManagementPresence
	var manager := office.find_child("RoosterManager", true, false) as Node3D
	var farmer := office.find_child("FarmerReviewer", true, false) as Node3D
	_check(presence != null and manager != null, "office should include a patrolling rooster manager", failures)
	_check(farmer != null and not farmer.visible, "farmer should remain offstage before review", failures)
	if presence != null and farmer != null:
		presence.play_review()
		await process_frame
		_check(farmer.visible, "farmer should enter visibly for executive review", failures)
	if "--capture-manager-comb" in OS.get_cmdline_user_args() and controller != null and manager != null:
		# The focused character owns this optional visual fixture; normal startup
		# decisions remain covered by their dedicated UI tests and should not cover it.
		var decision_host := office.get("_decision_host") as Control
		if decision_host != null:
			decision_host.visible = false
		controller.focus_point(manager.global_position + Vector3(0.0, 1.25, 0.0), "ROOSTER MANAGER", 0.0, 3.8)
		await create_timer(0.45).timeout
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/manager-comb-attachment-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var image := root.get_texture().get_image()
		_check(image != null, "manager comb capture should expose a rendered viewport", failures)
		if image != null:
			_check(
				image.save_png(capture_directory.path_join("manager-comb-attached.png")) == OK,
				"manager comb capture should save successfully",
				failures,
			)
	if "--capture-seated-wings" in OS.get_cmdline_user_args() and controller != null:
		var decision_host := office.get("_decision_host") as Control
		if decision_host != null:
			decision_host.visible = false
		var seated_worker := office.find_child("Chicken_Mabel", true, false) as ChickenView
		_check(seated_worker != null, "seated-wing capture should find Mabel's production model", failures)
		if seated_worker != null:
			seated_worker.stage_at_workstation_for_introduction()
			controller.focus_worker(0)
			await create_timer(0.45).timeout
			var capture_directory := ProjectSettings.globalize_path(
				"res://output/web-game/manager-reference-wings-v1"
			)
			DirAccess.make_dir_recursive_absolute(capture_directory)
			var image := root.get_texture().get_image()
			_check(image != null, "seated-wing capture should expose a rendered viewport", failures)
			if image != null:
				_check(
					image.save_png(capture_directory.path_join("seated-wing-pose.png")) == OK,
					"seated-wing capture should save successfully",
					failures,
				)
			seated_worker.apply_snapshot({
				"state": ChickenState.WorkState.WORKING,
				"stress": 12.0,
			})
			await create_timer(0.22).timeout
			var working_image := root.get_texture().get_image()
			_check(working_image != null, "working-wing capture should expose a rendered viewport", failures)
			if working_image != null:
				_check(
					working_image.save_png(capture_directory.path_join("seated-wing-working.png")) == OK,
					"working-wing capture should save successfully",
					failures,
				)
			seated_worker.depart_office([Vector3(0.0, 0.0, 2.0)])
			await create_timer(0.40).timeout
			var walking_image := root.get_texture().get_image()
			_check(walking_image != null, "walking-wing capture should expose a rendered viewport", failures)
			if walking_image != null:
				_check(
					walking_image.save_png(capture_directory.path_join("walking-wing-side-pose.png")) == OK,
					"walking-wing capture should save successfully",
					failures,
				)

	var feedback := office.find_child("WorkstationFeedback", true, false) as WorkstationFeedback
	var screen := office.find_child("Screen", true, false) as MeshInstance3D
	_check(feedback != null, "workstations should have a visual feedback controller", failures)
	_check(
		screen != null and screen.material_override is StandardMaterial3D
		and (screen.material_override as StandardMaterial3D).emission_enabled,
		"computer screens should use per-instance emissive feedback materials",
		failures
	)
	_check(office.find_child("RoosterManagementPerch", true, false) != null, "office should include a dominant rooster management perch", failures)
	_check(office.find_child("VisibleEggCollectionChain", true, false) != null, "office should expose the egg-to-farmer production chain", failures)
	_check(office.find_child("AmbientDustMotes", true, false) != null, "office should include bounded ambient motion", failures)
	_check(office.find_children("LivePeckworkPaper_*", "MeshInstance3D", true, false).size() == 30, "each workstation should expose a five-sheet live peckwork stack", failures)
	_check(office.find_children("StressNotice", "MeshInstance3D", true, false).size() == 6, "each workstation should have a stress-state storytelling prop", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("VISUAL_SYSTEMS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("VISUAL_SYSTEMS_TEST_PASSED camera=cinematic manager=perch pipeline=visible atmosphere=bounded workstations=active")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
