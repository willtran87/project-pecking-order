extends SceneTree

const EconomicBriefingUIScript := preload(
	"res://features/office/economic_briefing_ui.gd"
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

	_check(int(briefing.get("version", 0)) == 1, "briefing should expose a versioned read model", failures)
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
		int(market.get("next_market_day", 0)) > simulation.day
		and DepartmentSimulation.CLAIM_LANES.has(
			StringName(String(market.get("opportunity_lane_id", "")))
		)
		and int(market.get("feed_spot_unit_price_cents", 0)) > 0,
		"market outlook should disclose a valid lead lane, next window, and feed quote",
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

	var saved_before := JSON.stringify(simulation.export_save_state())
	var ui = EconomicBriefingUIScript.new()
	root.add_child(ui)
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	var headline := ui.find_child("EconomicBriefingHeadline", true, false) as Label
	var cash_label := ui.find_child("EconomicBriefingCash", true, false) as Label
	var market_label := ui.find_child("EconomicBriefingMarket", true, false) as Label
	var bottleneck_label := ui.find_child("EconomicBriefingBottleneck", true, false) as Label
	var strategy_label := ui.find_child("EconomicBriefingStrategies", true, false) as Label
	_check(
		headline != null and "DAY 1" in headline.text
		and cash_label != null and _contains_all(cash_label.text, ["CASH", "RUN RATE", "BREAK-EVEN"])
		and market_label != null and _contains_all(market_label.text, ["MARKET", "NEXT DAY", "FEED"])
		and bottleneck_label != null and _contains_all(bottleneck_label.text, ["BOTTLENECK", "WHY", "ACT"])
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

	ui.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("ECONOMIC_BRIEFING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ECONOMIC_BRIEFING_TEST_PASSED authority=exact costs=reconciled market=forecast resources=6 strategies=5 bottleneck=actionable recovery=4 ui=presentation-only accessible=complete")
	quit(0)


func _contains_all(copy: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if not copy.contains(needle):
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
