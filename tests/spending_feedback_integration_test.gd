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
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback

	# Exercise the accepted provisions path through the real UI handler. The
	# debit effect observes the result but never participates in authorization.
	simulation.day = 7
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 100_000
	var facility := simulation.purchase_facility(&"feed_procurement_coop")
	assert(bool(facility.get("accepted", false)))
	simulation._feed_procurement.begin_day(simulation.day)
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_set_campaign_modal_open", false)
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_OPERATIONS)
	await process_frame
	var procurement_ui := office.find_child("FeedProcurementUI", true, false) as FeedProcurementUI
	assert(procurement_ui != null)
	procurement_ui.set_offers_expanded(true)
	var order_id: StringName = &"local_whole_grain"
	var order_button := office.find_child(
		"FeedProcurementOrder_local_whole_grain",
		true,
		false,
	) as Button
	assert(order_button != null)
	var scroll := (office.get("_flockwatch_navigation") as FlockwatchNavigation).page_scroll(
		FlockwatchNavigation.PAGE_OPERATIONS
	)
	var component_offset := (
		order_button.global_position.y
		- scroll.global_position.y
		+ float(scroll.scroll_vertical)
		- 250.0
	)
	scroll.scroll_vertical = maxi(0, int(component_offset))
	await process_frame
	assert(bool(office.call("_fund_debit_control_is_actually_visible", order_button)))
	var expected_cost := 0
	for offer_value in simulation.procurement_offer_catalog():
		var offer := offer_value as Dictionary
		if StringName(String(offer.get("offer_id", ""))) == order_id:
			expected_cost = int(offer.get("total_cost_cents", 0))
			break
	assert(expected_cost > 0)
	var fund_before := simulation.revenue_cents
	var audio_before := int(audio.feedback_snapshot().get("cue_serial", 0))
	office.call("_on_feed_order_requested", order_id)
	var state := office.call("fund_debit_feedback_snapshot") as Dictionary
	var receipt := state.get("last_receipt", {}) as Dictionary
	assert(fund_before - simulation.revenue_cents == expected_cost)
	assert(int(state.get("active_count", 0)) == 1)
	assert(String(receipt.get("transaction_kind", "")) == "feed_procurement")
	assert(String(receipt.get("target_id", "")) == "feed_order_local_whole_grain")
	assert(String(receipt.get("target_name", "")) == order_button.name)
	assert(int(receipt.get("cost_cents", 0)) == expected_cost)
	var audio_after_order := int(audio.feedback_snapshot().get("cue_serial", 0))
	# Policy, dialogue, and camera systems retain their existing cue ownership.
	# Freezing the presentation-only docket cannot append another sound.
	assert(audio_after_order >= audio_before)
	var save_after_order := simulation.export_save_state()
	assert(office.call("stage_fund_debit_feedback_capture"))
	assert(int(audio.feedback_snapshot().get("cue_serial", 0)) == audio_after_order)
	assert(simulation.export_save_state() == save_after_order)

	# A denied repeat owns only the existing rejection cue. It cannot add, merge,
	# or recycle a debit because no money left the authoritative Fund.
	var started_before_denial := int(state.get("started_total", 0))
	var fund_before_denial := simulation.revenue_cents
	office.call("_on_feed_order_requested", order_id)
	state = office.call("fund_debit_feedback_snapshot") as Dictionary
	assert(simulation.revenue_cents == fund_before_denial)
	assert(int(state.get("started_total", -1)) == started_before_denial)
	assert(int(state.get("merged_total", 0)) == 0)
	assert(simulation.export_save_state() == save_after_order)

	# Capacity expansion uses the same accepted-result observer, but resolves to
	# the exact staffing control on the Flock page. Keeping this in the same Office
	# also proves unrelated accepted purchases do not merge across destinations.
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_FLOCK)
	await process_frame
	var capacity_button := office.find_child(
		"PurchaseStaffCapacity",
		true,
		false,
	) as Button
	assert(capacity_button != null)
	var flock_scroll := (office.get("_flockwatch_navigation") as FlockwatchNavigation).page_scroll(
		FlockwatchNavigation.PAGE_FLOCK
	)
	var capacity_offset := (
		capacity_button.global_position.y
		- flock_scroll.global_position.y
		+ float(flock_scroll.scroll_vertical)
		- 250.0
	)
	flock_scroll.scroll_vertical = maxi(0, int(capacity_offset))
	await process_frame
	assert(bool(office.call("_fund_debit_control_is_actually_visible", capacity_button)))
	var expected_capacity_cost := int(
		simulation.capacity_upgrade_status().get("cost_cents", 0)
	)
	assert(expected_capacity_cost > 0)
	var capacity_before := simulation.office_capacity
	var fund_before_capacity := simulation.revenue_cents
	var started_before_capacity := int(state.get("started_total", 0))
	office.call("_on_staff_capacity_purchase_requested")
	state = office.call("fund_debit_feedback_snapshot") as Dictionary
	receipt = state.get("last_receipt", {}) as Dictionary
	assert(simulation.office_capacity == capacity_before + 1)
	assert(fund_before_capacity - simulation.revenue_cents == expected_capacity_cost)
	assert(int(state.get("started_total", -1)) == started_before_capacity + 1)
	assert(int(state.get("merged_total", 0)) == 0)
	assert(String(receipt.get("transaction_kind", "")) == "staffing")
	assert(String(receipt.get("target_id", "")) == "capacity_expanded")
	# The accepted mutation rebuilds the capacity docket before this observer runs,
	# so the stable Flockwatch toggle is the intentional fallback destination.
	assert(String(receipt.get("target_name", "")) == "FlockwatchToggle")
	assert(int(receipt.get("cost_cents", 0)) == expected_capacity_cost)
	var save_after_capacity := simulation.export_save_state()
	await process_frame
	assert(simulation.export_save_state() == save_after_capacity)

	# The generic receipt gate refuses zero-cost and rejected transactions.
	var started_before_generic_rejections := int(state.get("started_total", 0))
	assert(not office.call(
		"_play_fund_debit_from_result",
		{"accepted": false, "cost_cents": 900},
		&"staffing",
		&"denied_hire",
		order_button,
	))
	assert(not office.call(
		"_play_fund_debit_from_result",
		{"accepted": true, "cost_cents": 0},
		&"staffing",
		&"free_action",
		order_button,
	))
	assert(int((office.call("fund_debit_feedback_snapshot") as Dictionary).get(
		"started_total",
		-1,
	)) == started_before_generic_rejections)

	print("SPENDING_FEEDBACK_INTEGRATION_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)
