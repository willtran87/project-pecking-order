extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	await process_frame
	var live := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var social := office.get("_hen_social") as HenSocialDirector
	var views := office.get("_worker_views") as Dictionary
	live.select_directive(&"shell_assurance")
	(office.get("_campaign_ui") as ProbationCampaignUI).hide_modal()
	(office.get("_decision_host") as Control).hide()
	(office.get("_character_dialogue_ui") as CharacterDialogueUI).clear_session()
	clock.set_speed(0)
	for id in [0, 1]:
		live.set_worker_at_workstation(id, true)
		(views[id] as ChickenView).stage_at_workstation_for_introduction()
	live.advance_tick()
	live.workers[1].stress = 72.0
	office.call("_on_snapshot_changed", live.snapshot())
	(office.get("_character_dialogue_ui") as CharacterDialogueUI).clear_session()
	(office.get("_camera_controller") as ManagementCameraController).show_overview()
	await create_timer(1.0).timeout
	social.cooldown = 0.0
	office.call("_process_hen_social", 0.0, true)
	_check(not social.current.is_empty(), "live office starts nearby stress exchange")
	clock.set_speed(1)
	office.call("_process_hen_social", 4.1)
	_check(social.snapshot().replying, "live office advances speaking turns")
	clock.set_speed(0)
	var held := social.elapsed
	office.call("_process_hen_social", 10.0)
	_check(social.elapsed == held, "live office holds social time while paused")
	var social_ui := office.get("_hen_social_ui") as HenSocialUI
	_check(social_ui.visible and social_ui.diagnostic_state().reply.begins_with("Pip:"), "live balloon shows the listener's reply")
	root.size = Vector2i(900, 800)
	office.call("_process_hen_social", 0.0)
	_check(not social.current.is_empty(), "viewport transition cannot erase a paused conversation")
	office.call("_queue_collection_claim", 0, 901)
	office.call("_on_egg_reached_presentation", 0, &"cracked", 0, 0)
	_check(social.snapshot().pending == 0, "cracked delivery is not praised")
	office.call("_queue_collection_claim", 0, 902)
	office.call("_on_egg_reached_presentation", 0, &"sound", 25, 0)
	_check(social.snapshot().pending == 1, "clean delivery reaches the social scheduler")
	office.call("_process_hen_social", 0.0)
	_check(not (views[0] as ChickenView).expression_snapshot().social_attention, "earned celebration takes priority over social gestures")
	_check(not social.current.is_empty(), "routine work/reward does not cut off the listener's reply")
	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("HEN_SOCIAL_OFFICE_TEST_PASSED pair=live reply=live pause=held praise=delivery_only priority=earned")
		quit(0)
	else:
		for failure in failures:
			push_error("HEN_SOCIAL_OFFICE_TEST_FAILED: " + failure)
		quit(1)

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
