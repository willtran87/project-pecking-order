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
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_OPERATIONS)
	await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	var feed_button := office.get("_feed_button") as Button
	var save_before := simulation.export_save_state()
	var audio_before := int(audio.feedback_snapshot().get("cue_serial", 0))
	assert(office.call("_play_fund_debit_feedback", 2000, &"feed_party", &"feed_party", feed_button))
	var state := office.call("fund_debit_feedback_snapshot") as Dictionary
	var receipt := state.get("last_receipt", {}) as Dictionary
	assert(int(state.get("pooled_count", 0)) == 3)
	assert(int(state.get("active_count", 0)) == 1)
	assert(bool(state.get("bounded", false)))
	assert(String(receipt.get("source_id", "")) == "feed_fund_counter")
	assert(String(receipt.get("target_id", "")) == "feed_party")
	assert(String(receipt.get("motion", "")) == "counter_to_purchase")
	assert(String(receipt.get("shape", "")) == "clipped_debit_docket")
	assert(int(receipt.get("cost_cents", 0)) == 2000)
	assert(not bool(receipt.get("audio_cue_owned", true)))
	assert(String(receipt.get("accessible_text", "")).contains("$20.00 left the Feed Fund"))
	assert(simulation.export_save_state() == save_before)
	assert(int(audio.feedback_snapshot().get("cue_serial", 0)) == audio_before)

	# Repeated spending toward the same action refreshes one pool member.
	assert(office.call("_play_fund_debit_feedback", 500, &"feed_party", &"feed_party", feed_button))
	state = office.call("fund_debit_feedback_snapshot") as Dictionary
	receipt = state.get("last_receipt", {}) as Dictionary
	assert(int(state.get("active_count", 0)) == 1)
	assert(int(state.get("merged_total", 0)) == 1)
	assert(int(receipt.get("cost_cents", 0)) == 2500)
	assert(int(receipt.get("merge_count", 0)) == 1)

	# Three distinct destinations fill, but never exceed, the fixed pool.
	var upgrade_buttons := office.get("_upgrade_buttons") as Dictionary
	var upgrade_ids: Array = upgrade_buttons.keys()
	assert(upgrade_ids.size() >= 3)
	for index in 3:
		var upgrade_id := StringName(upgrade_ids[index])
		assert(office.call(
			"_play_fund_debit_feedback",
			100 + index,
			&"upgrade",
			upgrade_id,
			upgrade_buttons[upgrade_id] as Button,
		))
	state = office.call("fund_debit_feedback_snapshot") as Dictionary
	assert(int(state.get("active_count", 0)) == 3)
	assert(int(state.get("pooled_count", 0)) == 3)
	assert(int(state.get("recycled_total", 0)) >= 1)

	# Reduced motion retains a stationary destination pulse and all non-color cues.
	var preferences := office.get("_player_preferences") as Dictionary
	preferences["motion_mode"] = "reduced"
	assert(office.call("_play_fund_debit_feedback", 725, &"upgrade", &"reduced_test", feed_button))
	state = office.call("fund_debit_feedback_snapshot") as Dictionary
	receipt = state.get("last_receipt", {}) as Dictionary
	assert(bool(state.get("reduced_motion", false)))
	assert(bool(receipt.get("reduced_motion", false)))
	assert(not bool(receipt.get("animated", true)))
	assert(String(receipt.get("motion", "")) == "destination_pulse")
	assert(String(receipt.get("symbol", "")).begins_with("-$"))
	assert(simulation.export_save_state() == save_before)
	assert(int(audio.feedback_snapshot().get("cue_serial", 0)) == audio_before)

	print("FUND_DEBIT_FEEDBACK_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)
