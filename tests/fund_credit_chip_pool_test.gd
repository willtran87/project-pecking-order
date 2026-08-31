extends SceneTree

const BURST_COUNT := 40
const POOL_SIZE := 8
const SIX_HEN_TOTAL_CENTS := 3045


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
	clock.set_speed(0)
	var revenue_before := simulation.revenue_cents
	var eggs_before := simulation.eggs_today
	var pool := office.get("_fund_credit_chip_pool") as Array
	assert(pool.size() == POOL_SIZE)
	var child_count_before := ui_root.get_child_count()
	var panel_ids: Array[int] = []
	var shared_style: StyleBox
	for visual in pool:
		var panel := visual.get("panel") as PanelContainer
		var label := visual.get("label") as Label
		assert(panel != null and label != null)
		assert(not panel.visible)
		assert(panel.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		var panel_style := panel.get_theme_stylebox("panel")
		if shared_style == null:
			shared_style = panel_style
		else:
			assert(panel_style == shared_style)
		panel_ids.append(panel.get_instance_id())

	# Same-frame routine settlements become one readable global batch. Exact
	# worker and claim attribution remains in each desk acknowledgment/receipt.
	for worker_id in 6:
		office.call(
			"_spawn_fund_credit_chip",
			420 + worker_id * 35,
			&"golden" if worker_id == 0 else (&"cracked" if worker_id == 5 else &"sound"),
		)
	assert(ui_root.get_child_count() == child_count_before)
	assert((office.get("_active_fund_credit_chips") as Array).size() == 1)
	assert(_visible_count(pool) == 1)
	var batch_state := office.call("fund_credit_batch_snapshot") as Dictionary
	assert(int(batch_state.get("pooled_chip_count", 0)) == POOL_SIZE)
	assert(int(batch_state.get("active_batch_count", 0)) == 1)
	assert(int(batch_state.get("total_eggs", 0)) == 6)
	assert(int(batch_state.get("total_value_cents", 0)) == SIX_HEN_TOTAL_CENTS)
	var batches := batch_state.get("batches", []) as Array
	var batch := batches[0] as Dictionary
	assert(String(batch.get("quality", "")) == "mixed")
	assert(String(batch.get("label", "")) == "x6 EGGS  |  +$30.45  >  FUND")
	assert("6 eggs added $30.45 total" in String(batch.get("accessible_text", "")))

	# A credit outside the brief merge window gets its own causal journey.
	office.call("_process_fund_credit_chip_pool", 0.13)
	office.call("_spawn_fund_credit_chip", 225, &"sound")
	batch_state = office.call("fund_credit_batch_snapshot") as Dictionary
	assert(int(batch_state.get("active_batch_count", 0)) == 2)
	assert(int(batch_state.get("total_eggs", 0)) == 7)
	assert(int(batch_state.get("total_value_cents", 0)) == SIX_HEN_TOTAL_CENTS + 225)

	office.call("_process_fund_credit_chip_pool", 1.0)
	assert((office.get("_active_fund_credit_chips") as Array).is_empty())
	assert(_visible_count(pool) == 0)

	office.call("_spawn_fund_credit_chip", 875, &"cracked")
	var exact_chip := ui_root.find_child("FundCreditChip", false, false) as PanelContainer
	assert(exact_chip != null and exact_chip.visible)
	var exact_label := exact_chip.find_child("*", true, false) as Label
	assert(exact_label != null and exact_label.text == "+$8.75  >  FUND")
	var start_position := exact_chip.position
	office.call("_process_fund_credit_chip_pool", 0.08)
	assert(not exact_chip.position.is_equal_approx(start_position))
	assert(office.call("stage_fund_credit_batch_capture"))
	batch_state = office.call("fund_credit_batch_snapshot") as Dictionary
	batches = batch_state.get("batches", []) as Array
	batch = batches[0] as Dictionary
	assert(bool(batch.get("capture_staged", false)))
	var staged_position := exact_chip.position
	office.call("_process_fund_credit_chip_pool", 1.0)
	assert(exact_chip.visible and exact_chip.position.is_equal_approx(staged_position))
	var staged_visual := (office.get("_active_fund_credit_chips") as Array)[0] as RefCounted
	staged_visual.set("capture_staged", false)
	office.call("_process_fund_credit_chip_pool", 1.0)
	assert(not exact_chip.visible)
	assert(ui_root.find_child("FundCreditChip", false, false) == null)
	for pool_index in pool.size():
		var panel := pool[pool_index].get("panel") as PanelContainer
		assert(panel.get_instance_id() == panel_ids[pool_index])

	# Even a synthetic impossible burst never grows the scene tree beyond the
	# prebuilt pool. Age each visual past the merge window to exercise overflow.
	for sample_index in BURST_COUNT:
		office.call("_spawn_fund_credit_chip", 100 + sample_index, &"sound")
		var active := office.get("_active_fund_credit_chips") as Array
		(active.back() as RefCounted).set("elapsed", 0.13)
	assert(ui_root.get_child_count() == child_count_before)
	assert((office.get("_active_fund_credit_chips") as Array).size() == POOL_SIZE)
	assert(_visible_count(pool) == POOL_SIZE)
	office.call("_process_fund_credit_chip_pool", 1.0)
	assert((office.get("_active_fund_credit_chips") as Array).is_empty())
	assert(_visible_count(pool) == 0)

	office.set("_displayed_revenue_cents", 1000)
	office.call("_tween_fund_to", 2000)
	assert(bool(office.get("_fund_counter_active")))
	office.call("_process_fund_counter", 0.10)
	var intermediate_fund := int(office.get("_displayed_revenue_cents"))
	assert(intermediate_fund > 1000 and intermediate_fund < 2000)
	office.call("_tween_fund_to", 2500)
	office.call("_process_fund_counter", 1.0)
	assert(not bool(office.get("_fund_counter_active")))
	assert(int(office.get("_displayed_revenue_cents")) == 2500)
	assert(int(office.get("_fund_visual_target_cents")) == 2500)
	assert(simulation.revenue_cents == revenue_before)
	assert(simulation.eggs_today == eggs_before)

	print("FUND_CREDIT_CHIP_POOL_TEST_PASSED")
	office.free()
	await process_frame
	quit(0)


func _visible_count(pool: Array) -> int:
	var visible := 0
	for visual in pool:
		var panel := visual.get("panel") as PanelContainer
		if panel.visible:
			visible += 1
	return visible
