extends SceneTree

const EconomicBriefingUIScript := preload(
	"res://features/office/economic_briefing_ui.gd"
)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(27_701, 4)
	var initial := simulation.economic_briefing_snapshot()
	var initial_watch := initial.get("management_watch", {}) as Dictionary
	var catalog := initial_watch.get("catalog", []) as Array
	_check(
		_watch_ids(catalog) == [
			&"auto", &"margin", &"feed", &"capacity", &"welfare", &"market",
		],
		"management watch should preserve its six stable strategic choices",
		failures,
	)
	for row_value: Variant in catalog:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		_check(
			not String(row.get("current_label", "")).is_empty()
			and not String(row.get("target_label", "")).is_empty()
			and not String(row.get("why", "")).is_empty()
			and not String(row.get("action", "")).is_empty()
			and StringName(row.get("page_id", &"")) in [
				&"today", &"flock", &"operations", &"capital", &"governance_records",
			],
			"every watch should expose current value, target, cause, action, and destination",
			failures,
		)

	var rejected := simulation.pin_economic_watch(&"vanity_metric")
	_check(
		not bool(rejected.get("accepted", true))
		and simulation.pinned_economic_watch_id == &"auto",
		"unknown watches should reject without changing the filed choice",
		failures,
	)
	var pinned := simulation.pin_economic_watch(&"market")
	var selected := (
		simulation.economic_briefing_snapshot().get("management_watch", {})
		as Dictionary
	).get("selected", {}) as Dictionary
	_check(
		bool(pinned.get("accepted", false))
		and StringName(selected.get("id", &"")) == &"market"
		and StringName(selected.get("page_id", &"")) == &"governance_records"
		and String(selected.get("current_label", "")).contains("SHARE"),
		"pinning Mutual reach should immediately select an exact Records watch",
		failures,
	)
	var trust_spent := DepartmentSimulation.new(27_704, 4)
	trust_spent.market_contracts_signed_total = 4
	trust_spent.market_contracts_succeeded_total = 4
	trust_spent.market_pricing_outcomes["community_access_rate_success"] = 1
	trust_spent.market_pricing_outcomes["executive_select_rate_success"] = 3
	trust_spent.pin_economic_watch(&"market")
	var trust_watch := (
		trust_spent.economic_briefing_snapshot().get("management_watch", {})
		as Dictionary
	).get("selected", {}) as Dictionary
	_check(
		String(trust_watch.get("status_label", "")) == "CLAIMANT TRUST LOW"
		and String(trust_watch.get("current_label", "")).contains("48 SENTIMENT")
		and String(trust_watch.get("target_label", "")).contains("50 SENTIMENT")
		and String(trust_watch.get("why", "")).contains("rebuild"),
		"the Mutual Reach watch should diagnose spent claimant trust and name its recovery",
		failures,
	)

	var checkpoint := simulation.export_save_state()
	var restored := DepartmentSimulation.new(27_702, 4)
	_check(
		restored.restore_save_state(checkpoint)
		and restored.pinned_economic_watch_id == &"market",
		"the selected management watch should survive an exact checkpoint round trip",
		failures,
	)
	var state_before_tamper := JSON.stringify(restored.export_save_state())
	var tampered := checkpoint.duplicate(true)
	tampered["pinned_economic_watch_id"] = "vanity_metric"
	_check(
		not restored.restore_save_state(tampered)
		and JSON.stringify(restored.export_save_state()) == state_before_tamper,
		"an unknown persisted watch should reject atomically",
		failures,
	)
	var legacy := checkpoint.duplicate(true)
	legacy.erase("pinned_economic_watch_id")
	var legacy_restored := DepartmentSimulation.new(27_703, 4)
	_check(
		legacy_restored.restore_save_state(legacy)
		and legacy_restored.pinned_economic_watch_id == &"auto",
		"additive legacy checkpoints should default to the primary-constraint watch",
		failures,
	)

	var ui = EconomicBriefingUIScript.new()
	ui.size = Vector2(272.0, 720.0)
	root.add_child(ui)
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	var selector := ui.find_child(
		"EconomicBriefingWatchSelector",
		true,
		false,
	) as OptionButton
	var open_button := ui.find_child(
		"EconomicBriefingWatchOpenButton",
		true,
		false,
	) as Button
	var watch_actions := ui.find_child(
		"EconomicBriefingWatchActions",
		true,
		false,
	) as VBoxContainer
	var watch_glance := ui.find_child(
		"EconomicBriefingWatchGlance",
		true,
		false,
	) as Label
	var watch_detail := ui.find_child(
		"EconomicBriefingWatch",
		true,
		false,
	) as Label
	var requested_watch: Array[StringName] = []
	var requested_page: Array[StringName] = []
	ui.economic_watch_requested.connect(
		func(watch_id: StringName) -> void:
			requested_watch.append(watch_id)
	)
	ui.economic_watch_open_requested.connect(
		func(page_id: StringName) -> void:
			requested_page.append(page_id)
	)
	var feed_index := _option_index(selector, &"feed")
	_check(
		selector != null and selector.item_count == 6 and feed_index >= 0,
		"the compact selector should expose all watches to keyboard and pointer input",
		failures,
	)
	_check(
		watch_actions != null
		and watch_actions.get_combined_minimum_size().x <= 272.0,
		"the selector and deep link should stack inside the minimum Flockwatch width",
		failures,
	)
	_check(
		watch_glance != null
		and _contains_all(watch_glance.text, ["MUTUAL REACH", "->"])
		and watch_detail != null
		and not watch_detail.is_visible_in_tree(),
		"the default watch should show only its concern and target while folding the rationale",
		failures,
	)
	if selector != null and feed_index >= 0:
		selector.item_selected.emit(feed_index)
	_check(
		requested_watch == [&"feed"],
		"choosing Feed Coverage should emit one authoritative pin intent",
		failures,
	)
	if open_button != null:
		open_button.pressed.emit()
	_check(
		requested_page == [&"governance_records"],
		"the selected Mutual Reach watch should deep-link to its existing Records file",
		failures,
	)
	_check(
		_contains_all(ui.accessible_text(), [
			"MANAGEMENT WATCH", "MUTUAL REACH", "NOW", "TARGET", "WHY", "ACT",
		]),
		"the watched concern should remain complete in assistive narration",
		failures,
	)

	ui.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("ECONOMIC_MANAGEMENT_WATCH_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"ECONOMIC_MANAGEMENT_WATCH_TEST_PASSED choices=6 pin=exact "
		+ "trust=renewable checkpoint=durable tamper=atomic legacy=auto "
		+ "ui=select+deep-link accessible=complete"
	)
	quit(0)


func _watch_ids(catalog: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for row_value: Variant in catalog:
		if row_value is Dictionary:
			result.append(StringName((row_value as Dictionary).get("id", &"")))
	return result


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
