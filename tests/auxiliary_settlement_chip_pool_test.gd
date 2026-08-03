extends SceneTree

const POOL_SIZE := 6
const BURST_COUNT := 24


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame
	office.call("_prepare_capture_running")
	assert(not bool((office.call("_settlement_feedback_attention_state") as Dictionary).get(
		"active",
		false,
	)))

	var ui_root := office.get("_ui_root") as Control
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	clock.set_speed(0)
	var revenue_before := simulation.revenue_cents
	var eggs_before := simulation.eggs_today
	var pool := office.get("_auxiliary_settlement_chip_pool") as Array
	assert(pool.size() == POOL_SIZE)
	var child_count_before := ui_root.get_child_count()
	var panel_ids: Array[int] = []
	for visual in pool:
		var panel := visual.get("panel") as PanelContainer
		assert(panel != null and not panel.visible)
		assert(panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		panel_ids.append(panel.get_instance_id())

	# Same-frame stock and refund events consolidate within their own semantic
	# channels rather than masking one another at the basket.
	office.call("_spawn_farmgate_stock_chip", 700, &"sound")
	office.call("_spawn_farmgate_stock_chip", 800, &"golden")
	office.call("_spawn_farmgate_stock_chip", 900, &"sound")
	office.call("_spawn_attention_refund_chip", {"charges_after": 2}, &"sound")
	office.call("_spawn_attention_refund_chip", {"charges_after": 3}, &"golden")
	assert(ui_root.get_child_count() == child_count_before)
	assert((office.get("_active_auxiliary_settlement_chips") as Array).size() == 2)
	assert(_visible_count(pool) == 2)
	var state := office.call("auxiliary_settlement_snapshot") as Dictionary
	assert(int(state.get("pooled_chip_count", 0)) == POOL_SIZE)
	assert(int(state.get("active_batch_count", 0)) == 2)
	assert(int(state.get("stock_eggs", 0)) == 3)
	assert(int(state.get("stock_value_cents", 0)) == 2400)
	assert(int(state.get("pecks_restored", 0)) == 2)
	var stock := _batch_for_kind(state, "stock")
	var refund := _batch_for_kind(state, "refund")
	assert(String(stock.get("label", "")) == "x3 LOTS  |  $24.00  >  STORE")
	assert(String(refund.get("label", "")) == "+2 PECKS  |  3/3 READY")
	assert(String(stock.get("quality", "")) == "mixed")
	assert(String(refund.get("quality", "")) == "mixed")
	assert("3 eggs added to cold storage" in String(stock.get("accessible_text", "")))
	assert("2 Priority Pecks restored" in String(refund.get("accessible_text", "")))
	var stock_chip := ui_root.find_child("FarmgateStockChip", false, false) as PanelContainer
	var refund_chip := ui_root.find_child("PriorityPeckRefundChip", false, false) as PanelContainer
	assert(stock_chip != null and refund_chip != null)
	assert(not stock_chip.position.is_equal_approx(refund_chip.position))

	assert(office.call("stage_auxiliary_settlement_capture"))
	var stock_staged_position := stock_chip.position
	var refund_staged_position := refund_chip.position
	assert(absf(stock_staged_position.y - refund_staged_position.y) >= 40.0)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	assert(stock_chip.visible and refund_chip.visible)
	assert(stock_chip.position.is_equal_approx(stock_staged_position))
	assert(refund_chip.position.is_equal_approx(refund_staged_position))
	for visual in office.get("_active_auxiliary_settlement_chips") as Array:
		visual.set("capture_staged", false)
	var cue_before := int(audio.feedback_snapshot().get("cue_serial", 0))
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	assert((office.get("_active_auxiliary_settlement_chips") as Array).is_empty())
	assert(_visible_count(pool) == 0)
	assert(int(audio.feedback_snapshot().get("cue_serial", 0)) == cue_before + 1)
	assert(String(audio.feedback_snapshot().get("last_cue", "")) == "attention_restored")

	# Events outside the merge window preserve separate causal journeys.
	office.call("_spawn_farmgate_stock_chip", 500, &"sound")
	office.call("_process_auxiliary_settlement_chip_pool", 0.13)
	office.call("_spawn_farmgate_stock_chip", 600, &"sound")
	state = office.call("auxiliary_settlement_snapshot") as Dictionary
	assert(int(state.get("active_batch_count", 0)) == 2)
	assert(int(state.get("stock_eggs", 0)) == 2)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)

	# Reduced motion retains the static meaning and exact lifetime without travel.
	var original_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	var reduced_preferences := original_preferences.duplicate(true)
	reduced_preferences["motion_mode"] = "reduced"
	office.set("_player_preferences", reduced_preferences)
	office.call("_apply_player_preferences")
	office.call("_spawn_farmgate_stock_chip", 725, &"golden")
	stock_chip = ui_root.find_child("FarmgateStockChip", false, false) as PanelContainer
	var reduced_position := stock_chip.position
	state = office.call("auxiliary_settlement_snapshot") as Dictionary
	stock = _batch_for_kind(state, "stock")
	assert(bool(state.get("reduced_motion", false)))
	assert(not bool(stock.get("animated", true)))
	office.call("_process_auxiliary_settlement_chip_pool", 0.20)
	assert(stock_chip.position.is_equal_approx(reduced_position))
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	assert(not stock_chip.visible)
	office.set("_player_preferences", original_preferences)
	office.call("_apply_player_preferences")

	# A synthetic impossible burst reuses the oldest of six fixed visuals.
	for sample_index in BURST_COUNT:
		if sample_index % 2 == 0:
			office.call("_spawn_farmgate_stock_chip", 100 + sample_index, &"sound")
		else:
			office.call(
				"_spawn_attention_refund_chip",
				{"charges_after": mini(3, 1 + sample_index % 3)},
				&"sound",
			)
		var active := office.get("_active_auxiliary_settlement_chips") as Array
		(active.back() as RefCounted).set("elapsed", 0.13)
	assert(ui_root.get_child_count() == child_count_before)
	assert((office.get("_active_auxiliary_settlement_chips") as Array).size() == POOL_SIZE)
	assert(_visible_count(pool) == POOL_SIZE)
	office.call("_process_auxiliary_settlement_chip_pool", 1.0)
	assert((office.get("_active_auxiliary_settlement_chips") as Array).is_empty())
	assert(_visible_count(pool) == 0)
	for pool_index in pool.size():
		var panel := pool[pool_index].get("panel") as PanelContainer
		assert(panel.get_instance_id() == panel_ids[pool_index])
	assert(simulation.revenue_cents == revenue_before)
	assert(simulation.eggs_today == eggs_before)

	print("AUXILIARY_SETTLEMENT_CHIP_POOL_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)


func _batch_for_kind(state: Dictionary, kind: String) -> Dictionary:
	for batch_value in state.get("batches", []):
		var batch := batch_value as Dictionary
		if String(batch.get("kind", "")) == kind:
			return batch
	return {}


func _visible_count(pool: Array) -> int:
	var visible := 0
	for visual in pool:
		var panel := visual.get("panel") as PanelContainer
		if panel.visible:
			visible += 1
	return visible
