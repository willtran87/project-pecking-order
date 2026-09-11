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

	# Default All Notices must still preserve hierarchy: a routine receipt files
	# into history without replacing a live action alert.
	_arm_priority_attention(office)
	office.call("_publish_status_copy", "OVERDUE APPEALS FILE. Route a best-fit hen now.")
	office.call("_publish_status_copy", "THREE EGGS SETTLED INTO THE SHIFT RECORD.")
	var notifications := office.call("_notification_diagnostic_state") as Dictionary
	assert(bool(notifications.get("toast_visible", false)))
	assert(String(notifications.get("toast_priority", "")) == "action")
	assert(String(notifications.get("toast_copy", "")).contains("OVERDUE APPEALS"))
	assert(String(notifications.get("latest_priority", "")) == "routine")
	assert(String(notifications.get("latest_copy", "")).contains("THREE EGGS"))

	# Routine settlement visuals consolidate normally but stay hidden while the
	# actionable toast and routing-return chase own the player's attention.
	_spawn_three_lanes(office)
	var arbitration := office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	assert(int(arbitration.get("active_batch_count", 0)) == 3)
	assert(int(arbitration.get("visible_batch_count", -1)) == 0)
	assert(int(arbitration.get("deferred_batch_count", 0)) == 3)
	assert(bool((arbitration.get("attention", {}) as Dictionary).get("active", false)))
	var blocker_ids := _blocker_ids(arbitration)
	assert("status_toast" in blocker_ids)
	assert("routing_return" in blocker_ids)
	var placement := office.call("settlement_feedback_placement_snapshot") as Dictionary
	assert(bool(placement.get("all_safe", false)))
	assert(int(placement.get("card_count", 0)) == 3)
	assert(int(placement.get("visible_card_count", -1)) == 0)
	assert(int(placement.get("deferred_card_count", 0)) == 3)

	# A sustained high-speed burst merges into the three deferred semantic lanes;
	# it cannot allocate a wall of hidden nodes or age through its animation.
	office.call("_process_fund_credit_chip_pool", 0.5)
	office.call("_process_auxiliary_settlement_chip_pool", 0.5)
	office.call("_spawn_fund_credit_chip", 100, &"sound")
	office.call("_spawn_farmgate_stock_chip", 200, &"golden")
	office.call("_spawn_attention_refund_chip", {"charges_after": 3}, &"sound")
	var fund := office.call("fund_credit_batch_snapshot") as Dictionary
	var auxiliary := office.call("auxiliary_settlement_snapshot") as Dictionary
	assert(int(fund.get("active_batch_count", 0)) == 1)
	assert(int(fund.get("total_eggs", 0)) == 4)
	assert(int(fund.get("total_value_cents", 0)) == 1465)
	assert(int(auxiliary.get("active_batch_count", 0)) == 2)
	assert(int(auxiliary.get("stock_eggs", 0)) == 4)
	assert(int(auxiliary.get("stock_value_cents", 0)) == 1985)
	assert(int(auxiliary.get("pecks_restored", 0)) == 3)

	# Clearing the higher-priority surfaces releases all three aggregate receipts
	# from a freshly projected source on one calm motion/audio beat; no value or
	# attribution is lost and the arrivals do not layer their old confirmations.
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	var release_audio_before := audio.feedback_snapshot()
	assert(office.call("_dismiss_routing_return_cue", {
		"accepted": true,
		"worker_id": 0,
		"lane": "appeals",
	}))
	var dismissal := office.call("_routing_return_cue_diagnostic_state") as Dictionary
	assert(not bool(dismissal.get("active", true)))
	assert(bool((dismissal.get("dismissal", {}) as Dictionary).get(
		"resolved_action_toast_retired",
		false,
	)))
	await process_frame
	notifications = office.call("_notification_diagnostic_state") as Dictionary
	assert(not bool(notifications.get("toast_visible", true)))
	assert(not String(notifications.get("toast_copy", "")).contains("OVERDUE APPEALS"))
	office.call("_process_fund_credit_chip_pool", 0.01)
	office.call("_process_auxiliary_settlement_chip_pool", 0.01)
	arbitration = office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	assert(int(arbitration.get("visible_batch_count", 0)) == 3)
	assert(int(arbitration.get("deferred_batch_count", -1)) == 0)
	assert(int(arbitration.get("released_batch_count", 0)) == 3)
	assert(int(arbitration.get("released_total", 0)) == 3)
	assert(int(arbitration.get("release_serial", 0)) == 1)
	assert(int(arbitration.get("release_cue_count", 0)) == 1)
	var release := arbitration.get("last_release", {}) as Dictionary
	assert(int(release.get("batch_count", 0)) == 3)
	assert(int(release.get("item_count", 0)) == 8)
	assert(int(release.get("total_value_cents", 0)) == 3450)
	assert(int(release.get("pecks_restored", 0)) == 3)
	assert(String(release.get("motion", "")) == "synchronized_calm_fan")
	assert(String(audio.feedback_snapshot().get("last_cue", "")) == "settlement_release")
	assert(
		int(audio.feedback_snapshot().get("cue_serial", 0))
		== int(release_audio_before.get("cue_serial", 0)) + 1
	)
	assert(office.call("stage_fund_credit_batch_capture"))
	assert(office.call("stage_auxiliary_settlement_capture"))
	placement = office.call("settlement_feedback_placement_snapshot") as Dictionary
	assert(bool(placement.get("all_safe", false)))
	assert(int(placement.get("visible_card_count", 0)) == 3)
	_release_three_lanes(office, audio)

	# A cue that remains unresolved longer than the maximum defer window retires
	# routine cards silently and records a bounded, assistive recovery trail.
	_arm_priority_attention(office)
	office.call("_publish_status_copy", "OVERDUE APPEALS FILE. Route a best-fit hen now.")
	_spawn_three_lanes(office)
	office.call("_process_fund_credit_chip_pool", 9.1)
	office.call("_process_auxiliary_settlement_chip_pool", 9.1)
	assert((office.get("_active_fund_credit_chips") as Array).is_empty())
	assert((office.get("_active_auxiliary_settlement_chips") as Array).is_empty())
	arbitration = office.call("settlement_feedback_arbitration_snapshot") as Dictionary
	assert(int(arbitration.get("suppressed_total", 0)) == 3)
	var suppressed := arbitration.get("last_suppressed", []) as Array
	assert(suppressed.size() == 3)
	for record_value in suppressed:
		var record := record_value as Dictionary
		assert(bool(record.get("receipt_recoverable", false)))
		assert(not String(record.get("accessible_text", "")).is_empty())
	assert(simulation.export_save_state() == save_before)

	print("SETTLEMENT_FEEDBACK_ARBITRATION_TEST_PASSED")
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


func _release_three_lanes(office: Office, audio: OfficeAudioFeedback) -> void:
	var cue_serial_before_arrival := int(audio.feedback_snapshot().get("cue_serial", 0))
	for visual in office.get("_active_fund_credit_chips") as Array:
		visual.set("capture_staged", false)
	for visual in office.get("_active_auxiliary_settlement_chips") as Array:
		visual.set("capture_staged", false)
	office.call("_process_fund_credit_chip_pool", 1.0)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	assert((office.get("_active_fund_credit_chips") as Array).is_empty())
	assert((office.get("_active_auxiliary_settlement_chips") as Array).is_empty())
	assert(int(audio.feedback_snapshot().get("cue_serial", 0)) == cue_serial_before_arrival)


func _blocker_ids(arbitration: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var attention := arbitration.get("attention", {}) as Dictionary
	for blocker_value in attention.get("blockers", []):
		result.append(String((blocker_value as Dictionary).get("id", "")))
	return result
