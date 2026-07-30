extends SceneTree

const EconomicBriefingUIScript := preload(
	"res://features/office/economic_briefing_ui.gd"
)
const ManagementUIThemeScript := preload(
	"res://features/office/management_ui_theme.gd"
)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(17_701, 4)
	var briefing := simulation.economic_briefing_snapshot()
	var cash := briefing.get("cash", {}) as Dictionary
	var costs := briefing.get("costs", {}) as Dictionary
	var market := briefing.get("market", {}) as Dictionary

	_check(int(briefing.get("version", 0)) == 4, "briefing should expose the current versioned read model", failures)
	_check(
		int(cash.get("feed_fund_cents", -1)) == simulation.revenue_cents
		and int(cash.get("protected_reserve_cents", -1)) == simulation.protected_reserve_cents()
		and int(cash.get("spendable_fund_cents", -1)) == simulation.spendable_fund_cents(),
		"cash, reserve, and free fund must come from the authoritative economy",
		failures,
	)
	var expected_margin := (
		simulation.credited_today_cents
		- simulation.current_daily_operating_cost_cents()
	)
	_check(
		int(cash.get("secured_operating_margin_cents", 0)) == expected_margin
		and int(cash.get("break_even_remaining_cents", -1)) == maxi(0, -expected_margin),
		"run rate should use secured income and exact current operating cost",
		failures,
	)
	var categorized_cost := 0
	for value: Variant in costs.values():
		categorized_cost += int(value)
	_check(
		categorized_cost == simulation.current_daily_operating_cost_cents(),
		"visible cost categories should reconcile to the filed operating total",
		failures,
	)
	_check(
		int(costs.get("fellow_payroll_cents", -1)) == 0,
		"opening cost ledger should explicitly expose zero junior payroll",
		failures,
	)
	_check(
		int(market.get("next_market_day", 0)) > simulation.day
		and DepartmentSimulation.CLAIM_LANES.has(
			StringName(String(market.get("opportunity_lane_id", "")))
		)
		and int(market.get("feed_spot_unit_price_cents", 0)) > 0
		and int(market.get("current_days_remaining", -1)) == 5
		and int(market.get("opportunity_demand_basis_points", -1)) == 0
		and int(market.get("next_opportunity_demand_basis_points", 0)) == 2_000
		and not String(market.get("current_cause", "")).is_empty()
		and String(market.get("forecast_certainty", "")) == "GUARANTEED CALENDAR"
		and not String(market.get("forecast_uncertainty", "")).is_empty(),
		"market outlook should disclose valid signed demand, cause, duration, certainty, next window, and feed quote",
		failures,
	)

	var resources := briefing.get("resources", []) as Array
	var resource_ids: Dictionary = {}
	for row_value: Variant in resources:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		resource_ids[String(row.get("id", ""))] = true
		_check(
			not String(row.get("source", "")).is_empty()
			and not String(row.get("use", "")).is_empty()
			and not String(row.get("limit", "")).is_empty()
			and not String(row.get("strategic_value", "")).is_empty(),
			"every resource should explain source, use, limit, and strategic value",
			failures,
		)
	_check(
		resources.size() == 6 and resource_ids.size() == 6,
		"the resource map should keep six mechanically distinct resources",
		failures,
	)

	var strategies := briefing.get("strategies", []) as Array
	_check(strategies.size() == 5, "the briefing should expose five viable operating routes", failures)
	for row_value: Variant in strategies:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		_check(
			not String(row.get("lever", "")).is_empty()
			and not String(row.get("upside", "")).is_empty()
			and not String(row.get("counterweight", "")).is_empty(),
			"each strategy route should expose its lever, upside, and counterweight",
			failures,
		)

	var bottlenecks := briefing.get("bottlenecks", []) as Array
	_check(not bottlenecks.is_empty(), "the briefing should always file one bottleneck status", failures)
	var primary := bottlenecks[0] as Dictionary
	_check(
		not String(primary.get("reason", "")).is_empty()
		and not String(primary.get("action", "")).is_empty(),
		"the primary bottleneck should explain why it exists and what can change it",
		failures,
	)
	var recovery := briefing.get("recovery_actions", []) as Array
	var recovery_ids: Array[String] = []
	for row_value: Variant in recovery:
		if row_value is Dictionary:
			recovery_ids.append(String((row_value as Dictionary).get("id", "")))
	_check(
		recovery_ids == ["standard_book", "treasury_bridge", "downsize", "feed_hedge"],
		"recovery file should preserve its four stable escape routes",
		failures,
	)
	var management_watch := briefing.get("management_watch", {}) as Dictionary
	var watch_catalog := management_watch.get("catalog", []) as Array
	var selected_watch := management_watch.get("selected", {}) as Dictionary
	_check(
		StringName(management_watch.get("selected_id", &"")) == &"auto"
		and watch_catalog.size() == 6
		and StringName(selected_watch.get("id", &"")) == &"auto"
		and not String(selected_watch.get("why", "")).is_empty()
		and not String(selected_watch.get("action", "")).is_empty(),
		"briefing should expose one selected management watch with six actionable choices",
		failures,
	)

	var saved_before := JSON.stringify(simulation.export_save_state())
	var harness := Control.new()
	harness.name = "EconomicBriefingTestHarness"
	harness.size = Vector2(282.0, 760.0)
	harness.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	root.add_child(harness)
	var scroll := ScrollContainer.new()
	scroll.name = "EconomicBriefingTestScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	harness.add_child(scroll)
	var ui = EconomicBriefingUIScript.new()
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(ui)
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	var headline := ui.find_child("EconomicBriefingHeadline", true, false) as Label
	var cash_label := ui.find_child("EconomicBriefingCash", true, false) as Label
	var market_label := ui.find_child("EconomicBriefingMarket", true, false) as Label
	var bottleneck_label := ui.find_child("EconomicBriefingBottleneck", true, false) as Label
	var strategy_label := ui.find_child("EconomicBriefingStrategies", true, false) as Label
	var watch_label := ui.find_child("EconomicBriefingWatch", true, false) as Label
	var watch_selector := ui.find_child("EconomicBriefingWatchSelector", true, false) as OptionButton
	var watch_open := ui.find_child("EconomicBriefingWatchOpenButton", true, false) as Button
	_check(
		headline != null and "DAY 1" in headline.text
		and cash_label != null and _contains_all(cash_label.text, ["CASH", "RUN RATE", "BREAK-EVEN"])
		and market_label != null and _contains_all(market_label.text, [
			"MARKET", "5 DAYS LEFT", "GUARANTEED CALENDAR", "CAUSE",
			"NOW", "+0%", "NEXT DAY", "LEAD", "+20%", "FEED",
		])
		and bottleneck_label != null and _contains_all(bottleneck_label.text, ["BOTTLENECK", "WHY", "ACT"])
		and watch_label != null and _contains_all(watch_label.text, ["WATCH", "NOW", "TARGET", "WHY", "ACT"])
		and watch_selector != null and watch_selector.item_count == 6
		and watch_open != null and not watch_open.disabled
		and strategy_label != null and _contains_all(strategy_label.text, ["THROUGHPUT ROOST", "SHELL ASSURANCE", "COUNTERWEIGHT"]),
		"Capital presentation should retain the compact summary and disclosed strategy detail",
		failures,
	)
	_check(
		_contains_all(ui.accessible_text(), [
			"RESOURCE MAP", "STRATEGY FILE", "RECOVERY FILE", "TREASURY HEADROOM",
		]),
		"economic detail should remain available to assistive narration",
		failures,
	)
	_check(
		JSON.stringify(simulation.export_save_state()) == saved_before,
		"the presentation-only briefing must not mutate saved simulation state",
		failures,
	)

	ui.set_details_expanded(true)
	_apply_explicit_font_scale(ui, 1.5)
	_expand_interface_copy(ui)
	await process_frame
	await process_frame
	var ui_rect := ui.get_global_rect()
	_check(
		ui.get_combined_minimum_size().x <= scroll.size.x + 0.5,
		"150-percent expanded briefing should not demand horizontal scrolling at the real 282px Flockwatch width",
		failures,
	)
	_check(
		not _has_visible_horizontal_overflow(ui, ui_rect),
		"150-percent expanded briefing controls should remain inside the compact ledger",
		failures,
	)
	_check(
		scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"the expanded briefing host should remain vertical-scroll-only",
		failures,
	)

	ui.queue_free()
	harness.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("ECONOMIC_BRIEFING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ECONOMIC_BRIEFING_TEST_PASSED authority=exact costs=reconciled market=forecast resources=6 strategies=5 watch=6+actionable bottleneck=actionable recovery=4 ui=presentation-only accessible=complete resilience=282px+150-percent+expanded-copy")
	quit(0)


func _contains_all(copy: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if not copy.contains(needle):
			return false
	return true


func _apply_explicit_font_scale(root_control: Control, scale: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.has_theme_font_size_override("font_size"):
			continue
		var base_size := control.get_theme_font_size("font_size")
		control.add_theme_font_size_override(
			"font_size",
			maxi(10, roundi(float(base_size) * scale)),
		)


func _expand_interface_copy(root_control: Control) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		if node_value is OptionButton:
			var option := node_value as OptionButton
			for item_index: int in range(option.item_count):
				option.set_item_text(
					item_index,
					_expanded(option.get_item_text(item_index)),
				)
		elif node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)
		elif node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)


func _expanded(source: String) -> String:
	var expanded := source
	for vowel: String in ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]:
		expanded = expanded.replace(vowel, vowel + vowel)
	return expanded


func _has_visible_horizontal_overflow(
	root_control: Control,
	bounds: Rect2,
) -> bool:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if (
			rect.position.x < bounds.position.x - 0.5
			or rect.end.x > bounds.end.x + 0.5
		):
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
