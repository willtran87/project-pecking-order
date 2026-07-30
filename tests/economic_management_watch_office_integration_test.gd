extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(27_711, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()

	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_CAPITAL)
	await process_frame
	await process_frame

	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var selector := office.find_child(
		"EconomicBriefingWatchSelector",
		true,
		false,
	) as OptionButton
	var open_button := office.find_child(
		"EconomicBriefingWatchOpenButton",
		true,
		false,
	) as Button
	var feed_index := _option_index(selector, &"feed")
	_check(
		navigation != null
		and navigation.current_page_id() == FlockwatchNavigation.PAGE_CAPITAL,
		"the real Office should expose the watch on its existing Capital page",
		failures,
	)
	_check(
		selector != null
		and selector.is_visible_in_tree()
		and selector.focus_mode == Control.FOCUS_ALL
		and feed_index >= 0,
		"the real Capital surface should expose a focusable Feed Coverage choice",
		failures,
	)

	if selector != null and feed_index >= 0:
		selector.item_selected.emit(feed_index)
	await process_frame
	await process_frame
	var selected := (
		simulation.economic_briefing_snapshot().get("management_watch", {})
		as Dictionary
	).get("selected", {}) as Dictionary
	var ticker := office.get("_ticker_label") as Label
	_check(
		simulation.pinned_economic_watch_id == &"feed"
		and StringName(selected.get("id", &"")) == &"feed",
		"the real selector should file Feed Coverage through authoritative simulation state",
		failures,
	)
	_check(
		open_button != null
		and not open_button.disabled
		and open_button.text == "OPEN OPS"
		and StringName(open_button.get_meta(&"page_id", &"")) == &"operations",
		"the settled watch should expose one direct Ops action",
		failures,
	)
	_check(
		ticker != null and _contains_all(ticker.text, ["MANAGEMENT WATCH", "FEED COVERAGE"]),
		"the Office ticker should confirm the durable management filing",
		failures,
	)

	if open_button != null and not open_button.disabled:
		open_button.pressed.emit()
	await process_frame
	await process_frame
	_check(
		navigation != null
		and navigation.current_page_id() == FlockwatchNavigation.PAGE_OPERATIONS,
		"Open Ops should deep-link to the existing page that can change feed coverage",
		failures,
	)

	var clock := office.get("_clock") as SimulationClock
	if clock != null:
		clock.set_speed(0)
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("ECONOMIC_MANAGEMENT_WATCH_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"ECONOMIC_MANAGEMENT_WATCH_OFFICE_INTEGRATION_TEST_PASSED "
		+ "capital=visible pin=authoritative ticker=confirmed deep-link=ops"
	)
	quit(0)


func _option_index(selector: OptionButton, watch_id: StringName) -> int:
	if selector == null:
		return -1
	for index: int in selector.item_count:
		if StringName(String(selector.get_item_metadata(index))) == watch_id:
			return index
	return -1


func _contains_all(copy: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if not copy.contains(needle):
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
