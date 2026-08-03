extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "flockwatch_today_density_test.json"


func _init() -> void:
	create_timer(60.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var office := Office.new()
	office.set("_campaign_store", store)
	root.add_child(office)
	await process_frame
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var decision_host := office.get("_decision_host") as Control
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	if decision_host != null:
		decision_host.visible = false
	if simulation != null:
		simulation.pending_decision.clear()
		simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	office.set("_active_decision", {})
	if campaign_ui != null:
		campaign_ui.show_active_campaign()
	office.call("_set_campaign_modal_open", false)
	office.call("_set_flockwatch_open", true)
	await process_frame
	await process_frame

	var snapshot_panel := office.find_child("FlockwatchTodaySnapshot", true, false) as PanelContainer
	var workload := office.find_child("FlockwatchTodayWorkload", true, false) as Label
	var clutch := office.find_child("FlockwatchTodayClutch", true, false) as Label
	var flock := office.find_child("FlockwatchTodayFlock", true, false) as Label
	var ledgers := office.find_child("FlockwatchTodayLedgers", true, false) as Label
	var workload_glance := office.find_child("FlockwatchTodayCasesGlance", true, false) as Label
	var clutch_glance := office.find_child("FlockwatchTodayEggsGlance", true, false) as Label
	var flock_glance := office.find_child("FlockwatchTodayFlockGlance", true, false) as Label
	var cash_glance := office.find_child("FlockwatchTodayCashGlance", true, false) as Label
	var snapshot_heading := office.find_child("FlockwatchTodaySnapshotHeading", true, false) as Label
	var glance_icons: Array[Node] = []
	for icon_name: String in [
		"FlockwatchTodayCasesGlanceIcon",
		"FlockwatchTodayEggsGlanceIcon",
		"FlockwatchTodayFlockGlanceIcon",
		"FlockwatchTodayCashGlanceIcon",
		"CampaignSafeguardGlanceIcon",
		"FlockCompactGlanceIcon",
		"WorkToRuleGlanceIcon",
	]:
		glance_icons.append(office.find_child(icon_name, true, false))
	var orders_heading := office.find_child("CampaignOrdersHeading", true, false) as Label
	var objectives := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var order_glances := office.find_children("CampaignOrderGlance*", "Label", true, false)
	var doctrine := office.find_child("CampaignActiveDoctrine", true, false) as Label
	var safeguards := office.find_child("CampaignSafeguardForecast", true, false) as Label
	var safeguard_glance := office.find_child("CampaignSafeguardGlance", true, false) as Label
	var labor := office.find_child("FlockLaborStatus", true, false) as Label
	var labor_grid := office.find_child("FlockLaborGlanceGrid", true, false) as GridContainer
	var compact_glance := office.find_child("FlockCompactGlance", true, false) as Label
	var work_rule_glance := office.find_child("WorkToRuleGlance", true, false) as Label
	var history := office.find_child("FlockwatchStatusHistory", true, false) as Label
	var history_toggle := office.find_child("FlockwatchStatusHistoryToggle", true, false) as Button
	var continue_button := office.find_child("ContinueDirectiveButton", true, false) as Button
	_check(
		[
			simulation, navigation, snapshot_panel, workload, clutch, flock,
			ledgers, workload_glance, clutch_glance, flock_glance, cash_glance, snapshot_heading,
			orders_heading, objectives, doctrine, safeguards, safeguard_glance,
			labor, labor_grid, compact_glance, work_rule_glance, history,
			history_toggle, continue_button,
		].all(func(value: Variant) -> bool: return value != null),
		"Office should compose the complete compact Today brief",
		failures,
	)
	_check(
		glance_icons.all(func(icon: Node) -> bool: return icon != null and bool(icon.get_meta("decorative", false))),
		"Today should use font-independent visual symbols while exact meanings stay on labels",
		failures,
	)
	if simulation == null or navigation == null:
		await _finish(office, store, failures)
		return
	var today_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY)
	for today_control: Control in [
		orders_heading, objectives, doctrine, safeguards, labor,
		safeguard_glance, labor_grid, snapshot_panel, workload, clutch, flock,
		ledgers, workload_glance, clutch_glance, flock_glance, cash_glance,
		history_toggle, history,
	]:
		_check(
			today_control != null and today_scroll.is_ancestor_of(today_control),
			"%s should remain inside Today's persistent scroll" % (
				today_control.name if today_control != null else "missing control"
			),
			failures,
		)
	_check(
		today_scroll.get_v_scroll_bar().max_value <= today_scroll.get_v_scroll_bar().page + 1.0,
		"opening Today should fit at 1280x720 without mandatory vertical scrolling",
		failures,
	)

	var snapshot := simulation.snapshot()
	var morale_total := 0.0
	var workers := snapshot.get("workers", []) as Array
	for worker_value: Variant in workers:
		morale_total += float((worker_value as Dictionary).get("morale", 0.0))
	var expected_morale := int(morale_total / maxf(1.0, float(workers.size())))
	_check(
		workload != null and _contains_all(workload.text, [
			str(int(snapshot.get("claims_outstanding", snapshot.get("claims_waiting", 0)))),
			str(int(snapshot.get("claim_capacity", 18))),
			str(int(snapshot.get("overdue_claims", 0))),
			str(int(snapshot.get("intake_rejections_today", 0))),
			"LIVE", "OVERDUE", "TURNED AWAY",
		]),
		"workload row should preserve live, capacity, overdue, and rejected-claim measures",
		failures,
	)
	_check(
		clutch != null and _contains_all(clutch.text, [
			str(int(snapshot.get("eggs_today", 0))),
			str(int(snapshot.get("quota_target", 0))),
			str(int(snapshot.get("eggs_total", 0))),
			"TODAY", "CAREER EGGS",
		]),
		"clutch row should preserve today's output, target, and career egg total",
		failures,
	)
	_check(
		flock != null and _contains_all(flock.text, [
			"%d%% SPIRITS" % expected_morale,
			"%d%% UNITY RISK" % int(snapshot.get("solidarity", 0)),
		]),
		"flock row should preserve average morale and unity risk",
		failures,
	)
	_check(
		ledgers != null and _contains_all(ledgers.text, [
			"%d%% FARMER FAVOR" % int(snapshot.get("executive_confidence", 0)),
			"%d%% COOP OBEDIENCE" % int(snapshot.get("compliance", 0)),
		]),
		"ledger row should preserve farmer favor and coop obedience",
		failures,
	)
	_check(
		[workload, clutch, flock, ledgers].all(
			func(label: Label) -> bool: return not label.tooltip_text.is_empty()
		),
		"every exact snapshot row should retain explanatory detail",
		failures,
	)
	_check(
		[workload, clutch, flock, ledgers].all(
			func(label: Label) -> bool: return not label.visible
		),
		"the exact ledger rows should remain semantic detail instead of default prose",
		failures,
	)
	_check(
		workload_glance != null
		and _contains_all(workload_glance.text, ["0 LATE"])
		and "CASES" not in workload_glance.text
		and "TURNED AWAY" in String(workload_glance.get_meta("accessible_text", "")),
		"file icon tile should show load and lateness without repeating its noun",
		failures,
	)
	_check(
		clutch_glance != null
		and _contains_all(clutch_glance.text, [str(int(snapshot.get("quota_target", 0))), "TOTAL"])
		and "EGGS" not in clutch_glance.text
		and "CAREER EGGS" in clutch_glance.tooltip_text,
		"egg icon tile should show clutch progress while preserving the exact career total",
		failures,
	)
	_check(
		flock_glance != null
		and _contains_all(flock_glance.text, ["%d%%" % expected_morale, "RISK"])
		and "FLOCK" not in flock_glance.text
		and "UNITY RISK" in flock_glance.tooltip_text,
		"flock icon tile should show spirits and risk with exact meaning on inspection",
		failures,
	)
	_check(
		cash_glance != null
		and "READY" in cash_glance.text
		and "CASH" not in cash_glance.text
		and _contains_all(String(cash_glance.get_meta("accessible_text", "")), [
			"FARMER FAVOR", "COOP OBEDIENCE", "RESERVED",
		]),
		"coin icon tile should prioritize spendable money while retaining complete semantics",
		failures,
	)
	_check(
		orders_heading != null
		and orders_heading.text.begins_with("TODAY'S 3 GOALS")
		and "+9 SCORE" in orders_heading.text
		and snapshot_heading != null and snapshot_heading.text == "NOW",
		"Today should name the three-goal plan and its complete score reward",
		failures,
	)
	_check(
		_snapshot_glances_are_compact([
			workload_glance, clutch_glance, flock_glance, cash_glance,
		]),
		"the four always-visible status tiles should stay within an 18-character glance budget",
		failures,
	)
	_check(
		order_glances.size() == 3
		and _order_glances_are_compact(order_glances),
		"three scored orders should be readable as two-line action and status tiles with exact hover detail",
		failures,
	)
	_check(
		_contains_all((order_glances[0] as Label).text, ["LAY", "EGGS", "LEFT"])
		and _contains_all((order_glances[1] as Label).text, ["CRACKS", "EGG 1", "PENDING"])
		and _contains_all((order_glances[2] as Label).text, ["WELFARE", "NOW", "SAFE"]),
		"goal tiles should state the player action, target, and live status without ledger shorthand",
		failures,
	)
	_check(
		_contains_all(navigation.accessible_text(), [
			"Visible filing", "LAY 18 EGGS", "EGG 1 PENDING", "WELFARE NEEDS 45",
		]),
		"Flockwatch narration should include the same live plan shown on Today's cards: %s" % navigation.accessible_text(),
		failures,
	)
	_check(
		objectives != null and not objectives.visible
		and safeguard_glance != null and safeguard_glance.is_visible_in_tree()
		and "SAFEGUARD" not in safeguard_glance.text
		and "NEEDS" in safeguard_glance.text
		and "-" not in safeguard_glance.text
		and "SAFEGUARD" in String(safeguard_glance.get_meta("accessible_text", ""))
		and safeguards != null and not safeguards.visible
		and "PROBATION FINAL TERMS" in safeguard_glance.tooltip_text,
		"orders and safeguard prose should collapse into glance tiles without losing final terms",
		failures,
	)

	var quiet_snapshot := snapshot.duplicate(true)
	quiet_snapshot["flock_compact"] = {}
	quiet_snapshot["flock_petition"] = {}
	quiet_snapshot["work_to_rule"] = {"active": false, "scheduled": false, "threshold": 45.0}
	office.call("_update_flock_labor_label", quiet_snapshot)
	_check(
		labor != null and not labor.visible and labor_grid != null and not labor_grid.visible,
		"quiet shifts should not reserve space for an empty labor filing",
		failures,
	)
	quiet_snapshot["flock_petition"] = {
		"sponsor_worker_name": "Mabel",
		"outcome": "Management filed a feed concession.",
	}
	office.call("_update_flock_labor_label", quiet_snapshot)
	_check(
		labor != null and not labor.visible
		and labor_grid != null and labor_grid.visible
		and compact_glance != null and compact_glance.is_visible_in_tree()
		and _contains_all(compact_glance.text, ["PETITION", "MABEL", "FILED"])
		and _contains_all(compact_glance.tooltip_text, ["LAST FLOCK PETITION", "MABEL"]),
		"a filed petition should restore a compact tile with its exact record on inspection",
		failures,
	)

	office.call("_record_status_copy", "TEST NOTICE ONE")
	office.call("_record_status_copy", "TEST NOTICE TWO")
	_check(
		history_toggle != null and not history_toggle.disabled
		and "SHOW SHIFT RECORD" in history_toggle.text
		and history != null and not history.visible,
		"recent notices should remain collapsed by default behind an enabled disclosure",
		failures,
	)
	if history_toggle != null:
		history_toggle.button_pressed = true
	await process_frame
	_check(
		history != null and history.visible
		and _contains_all(history.text, ["RECENT SHIFT RECORD", "TEST NOTICE TWO", "TEST NOTICE ONE"])
		and history_toggle != null and "HIDE SHIFT RECORD" in history_toggle.text,
		"expanding the disclosure should reveal the five-entry shift record in newest-first order",
		failures,
	)
	if history_toggle != null:
		history_toggle.button_pressed = false
	await process_frame
	_check(history != null and not history.visible, "collapsing the disclosure should return the brief to compact form", failures)

	_check(
		continue_button != null and continue_button.get_parent() == navigation.context_actions(),
		"required progression must remain in the global context-action host",
		failures,
	)
	navigation.set_show_all_filings(true)
	await process_frame
	_check(
		navigation.available_page_ids() == FlockwatchNavigation.PAGE_ORDER,
		"All Filings should preserve reachability of every management domain",
		failures,
	)
	for page_id: StringName in FlockwatchNavigation.PAGE_ORDER:
		_check(
			navigation.open_page(page_id) and navigation.page_scroll(page_id) != null,
			"%s should remain reachable through its existing page scroll" % String(page_id),
			failures,
		)
	await _finish(office, store, failures)


func _contains_all(text: String, fragments: Array[String]) -> bool:
	for fragment: String in fragments:
		if fragment not in text:
			return false
	return true


func _order_glances_are_compact(glances: Array[Node]) -> bool:
	for node: Node in glances:
		if not node is Label:
			return false
		var glance := node as Label
		if (
			glance.text.count("\n") != 1
			or not ["DONE", "LEFT", "PENDING", "SAFE", "OVER", "NEED"].any(
				func(status: String) -> bool: return status in glance.text
			)
			or glance.tooltip_text.is_empty()
		):
			return false
	return true


func _snapshot_glances_are_compact(glances: Array) -> bool:
	for label_value: Variant in glances:
		var label := label_value as Label
		if label == null or label.text.count("\n") != 1 or label.text.length() > 18:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _finish(office: Office, store: Variant, failures: Array[String]) -> void:
	office.free()
	await process_frame
	store.delete()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("FLOCKWATCH_TODAY_DENSITY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCKWATCH_TODAY_DENSITY_TEST_PASSED orders=3 safeguards=1 metrics=4 labor=conditional exact=semantic history=collapsed pages=5")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("FLOCKWATCH_TODAY_DENSITY_TEST_TIMEOUT")
	quit(1)
