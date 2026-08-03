extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame
	office.call("_prepare_capture_running")
	var simulation := office.get("_simulation") as DepartmentSimulation
	var save_before := simulation.export_save_state()
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	var camera := office.get("_management_camera") as Camera3D
	var routing := office.get("_routing_ui") as PeckworkRoutingUI
	var camera_controller := office.get("_camera_controller") as ManagementCameraController
	var clock := office.get("_clock") as SimulationClock
	routing.set_focus(0)
	camera_controller.focus_worker(0)
	await process_frame

	_arm_priority_attention(office)
	office.call("_publish_status_copy", "OVERDUE APPEALS FILE. Route a best-fit hen now.")
	_spawn_three_lanes(office)
	var audio_before := audio.feedback_snapshot()
	assert(office.call("_dismiss_routing_return_cue", {
		"accepted": true,
		"worker_id": 0,
		"lane": "appeals",
	}, true))
	var arbitration := office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	assert(int(arbitration.get("deferred_batch_count", 0)) == 3)
	assert(int(arbitration.get("visible_batch_count", -1)) == 0)
	assert(int(arbitration.get("released_batch_count", -1)) == 0)
	assert(_blocker_ids(arbitration).has("routing_delivery"))
	assert(String((arbitration.get("route_handoff", {}) as Dictionary).get(
		"status",
		"",
	)) == "awaiting_folder_landing")

	# Processing alone cannot race the cards ahead of the physical folder.
	office.call("_process_fund_credit_chip_pool", 0.5)
	office.call("_process_auxiliary_settlement_chip_pool", 0.5)
	arbitration = office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	assert(int(arbitration.get("deferred_batch_count", 0)) == 3)
	assert(int(arbitration.get("release_serial", -1)) == 0)

	# The same landing signal used in play provides the exact settled world point.
	var landing_world := feedback.dispatch_landing_point_global(0)
	var expected_screen := camera.unproject_position(landing_world)
	office.call("_on_dispatch_landing_presented", 0, {
		"serial": 77,
		"worker_id": 0,
		"lane": "appeals",
		"recommended": true,
	})
	arbitration = office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	var release := arbitration.get("last_release", {}) as Dictionary
	var handoff := arbitration.get("last_route_handoff", {}) as Dictionary
	assert(int(arbitration.get("visible_batch_count", 0)) == 3)
	assert(int(arbitration.get("deferred_batch_count", -1)) == 0)
	assert(int(arbitration.get("released_batch_count", 0)) == 3)
	assert(int(arbitration.get("release_cue_count", 0)) == 1)
	assert((arbitration.get("route_handoff", {}) as Dictionary).is_empty())
	assert(String(release.get("source", "")) == "dispatch_landing")
	assert(String(release.get("source_lane", "")) == "appeals")
	assert(int(release.get("source_worker_id", -1)) == 0)
	assert(String(release.get("causal_path", "")) == "accepted_route>folder_landing>receipt_fan")
	assert(bool(release.get("physical_landing_cue_suppressed", false)))
	assert((release.get("source_screen_center", Vector2.ZERO) as Vector2).distance_to(
		expected_screen,
	) < 0.5)
	assert(String(handoff.get("status", "")) == "receipts_released")
	assert(bool(handoff.get("physical_landing_cue_suppressed", false)))
	assert(String(audio.feedback_snapshot().get("last_cue", "")) == "settlement_release")
	assert(
		int(audio.feedback_snapshot().get("cue_serial", 0))
		== int(audio_before.get("cue_serial", 0)) + 1
	)

	# The linked arrival owns one cue; individual Fund/Peck destinations stay quiet.
	var cue_serial_before_arrivals := int(audio.feedback_snapshot().get("cue_serial", 0))
	office.call("_process_fund_credit_chip_pool", 1.0)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	assert(int(audio.feedback_snapshot().get("cue_serial", 0)) == cue_serial_before_arrivals)
	assert((office.get("_active_fund_credit_chips") as Array).is_empty())
	assert((office.get("_active_auxiliary_settlement_chips") as Array).is_empty())
	var destinations := office.call("settlement_destination_ack_snapshot") as Dictionary
	var destination_receipts := destinations.get("last_by_kind", {}) as Dictionary
	release = (office.call("settlement_feedback_arbitration_snapshot") as Dictionary).get(
		"last_release",
		{},
	) as Dictionary
	assert(int(destinations.get("pooled_count", 0)) == 3)
	assert(int(destinations.get("active_count", 0)) == 3)
	assert(int(destinations.get("started_total", 0)) == 3)
	assert(int(destinations.get("merged_total", -1)) == 0)
	assert(bool(destinations.get("bounded_by_kind", false)))
	assert(String((destination_receipts.get("fund", {}) as Dictionary).get(
		"target_id", "",
	)) == "feed_fund_counter")
	assert(String((destination_receipts.get("stock", {}) as Dictionary).get(
		"target_id", "",
	)) == "flockwatch_inventory_ledger")
	assert(String((destination_receipts.get("refund", {}) as Dictionary).get(
		"target_id", "",
	)) in ["priority_peck_meter", "flockwatch_resource_ledger"])
	assert(int(release.get("destination_acknowledgment_count", 0)) == 3)
	assert(String(release.get("completed_causal_path", ""))
		== "accepted_route>folder_landing>receipt_fan>destination_surfaces")
	assert(simulation.export_save_state() == save_before)

	# A second accepted route at 10x, after an overview camera transition, refreshes
	# the same three pooled surfaces instead of stacking more transient UI.
	clock.set_speed(3)
	camera_controller.show_overview()
	_arm_priority_attention(office)
	office.call("_publish_status_copy", "OVERDUE APPEALS FILE. Route a best-fit hen now.")
	_spawn_three_lanes(office)
	var second_audio_before := int(audio.feedback_snapshot().get("cue_serial", 0))
	assert(office.call("_dismiss_routing_return_cue", {
		"accepted": true,
		"worker_id": 0,
		"lane": "appeals",
	}, true))
	var second_landing_world := feedback.dispatch_landing_point_global(0)
	var second_expected_screen := camera.unproject_position(second_landing_world)
	office.call("_on_dispatch_landing_presented", 0, {
		"serial": 78,
		"worker_id": 0,
		"lane": "appeals",
		"recommended": true,
	})
	arbitration = office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	release = arbitration.get("last_release", {}) as Dictionary
	assert(int(arbitration.get("release_serial", 0)) == 2)
	assert((release.get("source_screen_center", Vector2.ZERO) as Vector2).distance_to(
		second_expected_screen,
	) < 0.5)
	var second_audio_delta := (
		int(audio.feedback_snapshot().get("cue_serial", 0)) - second_audio_before
	)
	assert(second_audio_delta in [0, 1])
	var second_release_audio := int(audio.feedback_snapshot().get("cue_serial", 0))
	office.call("_process_fund_credit_chip_pool", 1.0)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	destinations = office.call("settlement_destination_ack_snapshot") as Dictionary
	release = (office.call("settlement_feedback_arbitration_snapshot") as Dictionary).get(
		"last_release",
		{},
	) as Dictionary
	assert(int(destinations.get("pooled_count", 0)) == 3)
	assert(int(destinations.get("active_count", 0)) == 3)
	assert(int(destinations.get("started_total", 0)) == 6)
	assert(int(destinations.get("merged_total", 0)) == 3)
	assert(int(release.get("destination_acknowledgment_count", 0)) == 3)
	assert(int(audio.feedback_snapshot().get("cue_serial", 0)) == second_release_audio)
	clock.set_speed(0)

	# A lost delivery callback cannot strand routine receipts. The bounded timeout
	# falls back to the normal presentation counter and records why causality broke.
	await create_timer(0.30).timeout
	var preferences := office.get("_player_preferences") as Dictionary
	preferences["motion_mode"] = "reduced"
	_arm_priority_attention(office)
	office.call("_publish_status_copy", "OVERDUE APPEALS FILE. Route a best-fit hen now.")
	_spawn_three_lanes(office)
	assert(office.call("_dismiss_routing_return_cue", {
		"accepted": true,
		"worker_id": 0,
		"lane": "appeals",
	}, true))
	var pending := office.get("_settlement_feedback_route_handoff") as Dictionary
	pending["elapsed_seconds"] = 3.0
	office.call("_process_fund_credit_chip_pool", 0.01)
	office.call("_process_auxiliary_settlement_chip_pool", 0.01)
	arbitration = office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	release = arbitration.get("last_release", {}) as Dictionary
	handoff = arbitration.get("last_route_handoff", {}) as Dictionary
	assert(String(handoff.get("status", "")) == "landing_timeout_fallback")
	assert(String(release.get("source", "")) == "presentation_counter")
	assert(int(arbitration.get("release_serial", 0)) == 3)
	office.call("_process_fund_credit_chip_pool", 1.0)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	destinations = office.call("settlement_destination_ack_snapshot") as Dictionary
	assert(int(destinations.get("pooled_count", 0)) == 3)
	assert(int(destinations.get("active_count", 0)) == 3)
	assert(int(destinations.get("started_total", 0)) == 9)
	assert(bool(destinations.get("reduced_motion", false)))
	for pulse_value in destinations.get("pulses", []):
		var pulse := pulse_value as Dictionary
		assert(bool(pulse.get("active", false)))
		assert(bool(pulse.get("reduced_motion", false)))
		assert(not bool(pulse.get("animated", true)))
	assert(simulation.export_save_state() == save_before)

	print("SETTLEMENT_ROUTE_HANDOFF_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)


func _arm_priority_attention(office: Office) -> void:
	assert(office.call("_arm_routing_return_cue", {
		"routing_mastery": {
			"best_chain": 15,
			"next_record": 20,
			"target_kind": "record",
		},
	}))
	var simulation := office.get("_simulation") as DepartmentSimulation
	office.call("_update_guidance", simulation.snapshot())


func _spawn_three_lanes(office: Office) -> void:
	for value_cents in [420, 455, 490]:
		office.call("_spawn_fund_credit_chip", value_cents, &"sound")
	for value_cents in [560, 595, 630]:
		office.call("_spawn_farmgate_stock_chip", value_cents, &"sound")
	office.call("_spawn_attention_refund_chip", {"charges_after": 2}, &"sound")
	office.call("_spawn_attention_refund_chip", {"charges_after": 3}, &"golden")


func _blocker_ids(arbitration: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var attention := arbitration.get("attention", {}) as Dictionary
	for blocker_value in attention.get("blockers", []):
		result.append(String((blocker_value as Dictionary).get("id", "")))
	return result
