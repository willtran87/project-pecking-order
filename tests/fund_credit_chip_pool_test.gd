extends SceneTree

const BURST_COUNT := 40
const POOL_SIZE := 8


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 4:
		await process_frame

	var ui_root := office.get("_ui_root") as Control
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

	for sample_index in BURST_COUNT:
		office.call(
			"_spawn_fund_credit_chip",
			100 + sample_index,
			&"golden" if sample_index % 10 == 0 else &"sound",
		)
	assert(ui_root.get_child_count() == child_count_before)
	assert((office.get("_active_fund_credit_chips") as Array).size() == POOL_SIZE)
	assert(_visible_count(pool) == POOL_SIZE)

	office.call("_process_fund_credit_chip_pool", 1.0)
	assert((office.get("_active_fund_credit_chips") as Array).is_empty())
	assert(_visible_count(pool) == 0)

	office.call("_spawn_fund_credit_chip", 875, &"cracked")
	var exact_chip := ui_root.find_child("FundCreditChip", false, false) as PanelContainer
	assert(exact_chip != null and exact_chip.visible)
	var exact_label := exact_chip.find_child("*", true, false) as Label
	assert(exact_label != null and exact_label.text == "+$8.75 FEED FUND")
	var start_position := exact_chip.position
	office.call("_process_fund_credit_chip_pool", 0.08)
	assert(not exact_chip.position.is_equal_approx(start_position))
	office.call("_process_fund_credit_chip_pool", 1.0)
	assert(not exact_chip.visible)
	assert(ui_root.find_child("FundCreditChip", false, false) == null)
	for pool_index in pool.size():
		var panel := pool[pool_index].get("panel") as PanelContainer
		assert(panel.get_instance_id() == panel_ids[pool_index])

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
