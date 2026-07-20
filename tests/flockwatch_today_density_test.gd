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
	var orders_heading := office.find_child("CampaignOrdersHeading", true, false) as Label
	var objectives := office.find_child("CampaignObjectivesLabel", true, false) as Label
	var doctrine := office.find_child("CampaignActiveDoctrine", true, false) as Label
	var safeguards := office.find_child("CampaignSafeguardForecast", true, false) as Label
	var labor := office.find_child("FlockLaborStatus", true, false) as Label
	var history := office.find_child("FlockwatchStatusHistory", true, false) as Label
	var history_toggle := office.find_child("FlockwatchStatusHistoryToggle", true, false) as Button
	var continue_button := office.find_child("ContinueDirectiveButton", true, false) as Button
	_check(
		[
			simulation, navigation, snapshot_panel, workload, clutch, flock,
			ledgers, orders_heading, objectives, doctrine, safeguards, labor,
			history, history_toggle, continue_button,
		].all(func(value: Variant) -> bool: return value != null),
		"Office should compose the complete compact Today brief",
		failures,
	)
	if simulation == null or navigation == null:
		await _finish(office, store, failures)
		return
	var today_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY)
	for today_control: Control in [
		orders_heading, objectives, doctrine, safeguards, labor,
		snapshot_panel, workload, clutch, flock, ledgers, history_toggle, history,
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
		"every compact snapshot row should retain explanatory hover detail",
		failures,
	)

	var quiet_snapshot := snapshot.duplicate(true)
	quiet_snapshot["flock_compact"] = {}
	quiet_snapshot["flock_petition"] = {}
	quiet_snapshot["work_to_rule"] = {"active": false, "scheduled": false, "threshold": 45.0}
	office.call("_update_flock_labor_label", quiet_snapshot)
	_check(labor != null and not labor.visible, "quiet shifts should not reserve space for an empty labor filing", failures)
	quiet_snapshot["flock_petition"] = {
		"sponsor_worker_name": "Mabel",
		"outcome": "Management filed a feed concession.",
	}
	office.call("_update_flock_labor_label", quiet_snapshot)
	_check(
		labor != null and labor.visible and "LAST FLOCK PETITION" in labor.text and "MABEL" in labor.text,
		"a filed petition should restore the labor ledger with its exact record",
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
	print("FLOCKWATCH_TODAY_DENSITY_TEST_PASSED metrics=4 labor=conditional history=collapsed pages=5")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("FLOCKWATCH_TODAY_DENSITY_TEST_TIMEOUT")
	quit(1)
