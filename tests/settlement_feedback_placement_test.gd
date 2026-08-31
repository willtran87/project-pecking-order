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
	var clock := office.get("_clock") as SimulationClock
	clock.set_speed(0)
	var routing_ui := office.get("_routing_ui") as PeckworkRoutingUI
	var camera_controller := office.get("_camera_controller") as ManagementCameraController
	var ui_root := office.get("_ui_root") as Control
	var original_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	var instant_preferences := original_preferences.duplicate(true)
	instant_preferences["camera_motion"] = "off"
	office.set("_player_preferences", instant_preferences)
	office.call("_apply_player_preferences")
	routing_ui.set_focus(0)
	camera_controller.focus_worker(0)
	await process_frame
	await process_frame
	var focus_rect := routing_ui.settlement_feedback_bottom_rect()
	assert(focus_rect.size.x > 0.0 and focus_rect.size.y > 0.0)

	# A focused hen pushes the physical basket beyond the camera frame. All three
	# semantic cards must clamp back into the live workspace without touching the
	# queue, HUD, Flockwatch, dossier, or each other.
	_spawn_three_lanes(office)
	assert(office.call("stage_fund_credit_batch_capture"))
	assert(office.call("stage_auxiliary_settlement_capture"))
	await process_frame
	var placement := office.call("settlement_feedback_placement_snapshot") as Dictionary
	assert(bool(placement.get("all_safe", false)))
	assert((placement.get("reasons", []) as Array).is_empty())
	assert(int(placement.get("card_count", 0)) == 3)
	assert(int(placement.get("clamped_count", 0)) == 3)
	var cards := placement.get("cards", []) as Array
	var root_size := ui_root.get_global_rect().size
	for card_value in cards:
		var card := card_value as Dictionary
		var rect := card.get("rect", Rect2()) as Rect2
		assert(rect.position.x >= -0.5 and rect.end.x <= root_size.x + 0.5)
		assert(rect.position.y >= -0.5 and rect.end.y <= root_size.y + 0.5)
		assert(bool(card.get("placement_clamped", false)))
		assert(
			not (card.get("desired_source_center", Vector2.ZERO) as Vector2).is_equal_approx(
				card.get("safe_source_center", Vector2.ZERO) as Vector2
			)
		)
	_assert_pairwise_clear(cards)
	_release_three_lanes(office)

	# Maximum interface scale keeps the fixed cards bounded and switches to the
	# compact semantic copy rather than growing offscreen or hiding destinations.
	var large_preferences := instant_preferences.duplicate(true)
	large_preferences["ui_scale"] = 1.5
	office.set("_player_preferences", large_preferences)
	office.call("_apply_player_preferences")
	await process_frame
	_spawn_three_lanes(office)
	assert(office.call("stage_fund_credit_batch_capture"))
	assert(office.call("stage_auxiliary_settlement_capture"))
	await process_frame
	placement = office.call("settlement_feedback_placement_snapshot") as Dictionary
	assert(bool(placement.get("all_safe", false)))
	assert(int(placement.get("card_count", 0)) == 3)
	cards = placement.get("cards", []) as Array
	for card_value in cards:
		var rect := (card_value as Dictionary).get("rect", Rect2()) as Rect2
		assert(rect.size.x <= 224.5)
	var fund_state := office.call("fund_credit_batch_snapshot") as Dictionary
	var fund_batch := (fund_state.get("batches", []) as Array)[0] as Dictionary
	assert(String(fund_batch.get("label", "")) == "x3  |  +$13.65  >  FUND")
	var auxiliary_state := office.call("auxiliary_settlement_snapshot") as Dictionary
	assert(String(_batch_for_kind(auxiliary_state, "stock").get("label", "")) == "x3  |  $17.85  >  STORE")
	assert(String(_batch_for_kind(auxiliary_state, "refund").get("label", "")) == "+2 PECKS  |  3/3")
	_assert_pairwise_clear(cards)
	_release_three_lanes(office)

	office.set("_player_preferences", original_preferences)
	office.call("_apply_player_preferences")
	print("SETTLEMENT_FEEDBACK_PLACEMENT_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)


func _spawn_three_lanes(office: Office) -> void:
	for value_cents in [420, 455, 490]:
		office.call("_spawn_fund_credit_chip", value_cents, &"sound")
	for value_cents in [560, 595, 630]:
		office.call("_spawn_farmgate_stock_chip", value_cents, &"sound")
	office.call("_spawn_attention_refund_chip", {"charges_after": 2}, &"sound")
	office.call("_spawn_attention_refund_chip", {"charges_after": 3}, &"golden")


func _release_three_lanes(office: Office) -> void:
	for visual in office.get("_active_fund_credit_chips") as Array:
		visual.set("capture_staged", false)
	for visual in office.get("_active_auxiliary_settlement_chips") as Array:
		visual.set("capture_staged", false)
	office.call("_process_fund_credit_chip_pool", 1.0)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	assert((office.get("_active_fund_credit_chips") as Array).is_empty())
	assert((office.get("_active_auxiliary_settlement_chips") as Array).is_empty())


func _batch_for_kind(state: Dictionary, kind: String) -> Dictionary:
	for batch_value in state.get("batches", []):
		var batch := batch_value as Dictionary
		if String(batch.get("kind", "")) == kind:
			return batch
	return {}


func _assert_pairwise_clear(cards: Array) -> void:
	for first_index in cards.size():
		var first_rect := (cards[first_index] as Dictionary).get("rect", Rect2()) as Rect2
		for second_index in range(first_index + 1, cards.size()):
			var second_rect := (cards[second_index] as Dictionary).get("rect", Rect2()) as Rect2
			assert(not first_rect.intersects(second_rect))
