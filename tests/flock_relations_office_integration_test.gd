extends SceneTree


const FLOCK_RELATIONS := DepartmentSimulation.FLOCK_RELATIONS_OFFICE_ID
const ROOSTER := DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID
const WELLNESS := DepartmentSimulation.WELLNESS_NEST_ID
const TIER_ONE_COST_CENTS := 11_000


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var staffing_ui := office.find_child("RoostStaffingUI", true, false) as RoostStaffingUI
	var flockwatch := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var navigation := office.find_child("FlockwatchNavigation", true, false) as FlockwatchNavigation
	var records_scroll := (
		navigation.page_scroll(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
		if navigation != null else
		null
	) as ScrollContainer
	var relations_ui := office.find_child("FlockRelationsCaseUI", true, false) as FlockRelationsCaseUI
	var visual := office.find_child("FlockRelationsOfficeVisual", true, false)
	_check(
		simulation != null
		and campaign_ui != null
		and staffing_ui != null
		and flockwatch != null
		and navigation != null
		and records_scroll != null
		and relations_ui != null
		and visual != null,
		"production Office should compose DepartmentSimulation, paged Flockwatch, staffing forwarding, Records, and the Flock Relations visual",
		failures,
	)
	if (
		simulation == null
		or campaign_ui == null
		or staffing_ui == null
		or flockwatch == null
		or navigation == null
		or records_scroll == null
		or relations_ui == null
		or visual == null
	):
		await _finish(office, failures)
		return

	# Model a post-induction campaign rather than bypassing only Office's input
	# lock while leaving the authored title and First Clutch presentation active.
	office.set("_campaign_review_stage", &"active")
	campaign_ui.show_active_campaign()
	office.call("_reset_first_clutch", false)
	office.call("_set_campaign_modal_open", false)
	var review_scrim := office.get("_day_review_scrim") as Control
	if review_scrim != null:
		review_scrim.visible = false
	_check(not campaign_ui.is_modal_open(), "post-induction fixture should expose the active campaign surface", failures)
	_check(bool(office.first_clutch_snapshot().get("dismissed", false)), "post-induction fixture should have retired First Clutch disclosure", failures)
	_check(records_scroll.is_ancestor_of(relations_ui), "Flock Relations should be filed inside the Records page scroll", failures)
	_check(not staffing_ui.is_ancestor_of(relations_ui), "the empty RoostStaffingUI owner root should not be mistaken for the Records presentation host", failures)

	# Commission the first tier through the real requisition button. Only the two
	# authored permanent dependencies are supplied by the fixture.
	simulation.day = 7
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 250_000
	simulation.owned_facilities[ROOSTER] = 1
	simulation.owned_facilities[WELLNESS] = 1
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_CAPITAL)
	await process_frame
	await process_frame
	_check(flockwatch.visible, "Flockwatch should open for the review requisition", failures)
	_check(navigation.current_page_id() == FlockwatchNavigation.PAGE_CAPITAL, "the requisition fixture should use the Capital filing page", failures)
	var inline_capital_toggle := office.find_child("InlineCapitalFileToggle", true, false) as Button
	_check(inline_capital_toggle != null and inline_capital_toggle.is_visible_in_tree(), "Capital should expose its compact legacy-card disclosure", failures)
	if inline_capital_toggle != null:
		inline_capital_toggle.pressed.emit()
	await process_frame
	var purchase := office.find_child(
		"PurchaseFacility_%s" % String(FLOCK_RELATIONS),
		true,
		false,
	) as Button
	_check(purchase != null, "Flockwatch should host the stable Flock Relations requisition", failures)
	var capital_scroll := navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
	_check(purchase != null and capital_scroll != null and capital_scroll.is_ancestor_of(purchase), "the real Flock Relations requisition should live in Capital", failures)
	_check(purchase != null and purchase.is_visible_in_tree() and not purchase.disabled, "real tier-one dependencies and funding should enable the visible requisition", failures)
	var fund_before_build := simulation.revenue_cents
	if purchase != null:
		purchase.pressed.emit()
	await process_frame
	await process_frame
	_check(simulation.facility_level(FLOCK_RELATIONS) == 1, "the Flockwatch requisition should commission authoritative tier one", failures)
	_check(simulation.revenue_cents == fund_before_build - TIER_ONE_COST_CENTS, "tier-one UI purchase should debit exactly $110.00", failures)
	_check(int(visual.call("current_level")) == 1, "the physical office should consume the purchased tier-one snapshot", failures)

	# Navigate explicitly to the discovered Records filing. The newly commissioned
	# office should begin with its honest empty intake state in that page's own
	# persistent scroll, before any deterministic case is filed below.
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	await process_frame
	await process_frame
	var opening_empty_label := _descendant_label_containing(records_scroll, "NO OPEN HEN FILES")
	_check(navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, "commissioning Flock Relations should make Records explicitly navigable", failures)
	_check(records_scroll.is_visible_in_tree(), "Records should expose its own active scroll", failures)
	_check(relations_ui.is_visible_in_tree(), "the commissioned Flock Relations UI should be visible inside Records", failures)
	_check(opening_empty_label != null and records_scroll.is_ancestor_of(opening_empty_label), "the initial empty intake state should be rendered inside the Records scroll", failures)

	# Store deterministic worker strain in the authoritative flock, then let the
	# simulation derive the named case, severity, title, evidence, and docket.
	for worker in simulation.workers:
		worker.manager_trust = 100.0
		worker.grievance = 0.0
		worker.stress = 0.0
		worker.fatigue = 0.0
	var subject := simulation.workers[0]
	subject.manager_trust = 10.0
	subject.grievance = 70.0
	subject.stress = 60.0
	subject.fatigue = 50.0
	var subject_name := subject.display_name
	var filings := simulation._file_flock_relations_case_after_shift(6)
	_check(filings.size() == 1, "one completed shift should create exactly one deterministic named case", failures)
	var filed_case := filings[0] if not filings.is_empty() else {}
	var case_id := int(filed_case.get("case_id", -1))
	var evidence := filed_case.get("evidence", {}) as Dictionary
	_check(case_id == 1, "the first real case should retain stable case id 1", failures)
	_check(String(filed_case.get("worker_name", "")) == subject_name, "the case should identify the real stored worker name", failures)
	_check(int(filed_case.get("worker_id", -1)) == subject.id, "the case should retain the real stored worker id", failures)
	_check(StringName(filed_case.get("case_type", &"")) == &"surveillance_grievance", "the stored grievance metrics should author the canonical surveillance case", failures)
	_check(int(filed_case.get("severity", 0)) == 3, "the stored metrics should author severity three deterministically", failures)
	_check(
		is_equal_approx(float(evidence.get("manager_trust", -1.0)), 10.0)
		and is_equal_approx(float(evidence.get("grievance", -1.0)), 70.0)
		and is_equal_approx(float(evidence.get("stress", -1.0)), 60.0)
		and is_equal_approx(float(evidence.get("fatigue", -1.0)), 50.0),
		"the public case evidence should reproduce the stored subject metrics",
		failures,
	)

	# A stale or manually emitted mid-shift UI signal must still fail closed at the
	# Office -> DepartmentSimulation boundary and preserve the complete save state.
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	await process_frame
	await process_frame
	var case_heading := office.find_child("CaseHeading", true, false) as Label
	var case_evidence := office.find_child("CaseEvidence", true, false) as Label
	var held_remedy := office.find_child("FlockRelationsAction_fund_remedy", true, false) as Button
	_check(navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, "the live case should remain on Records", failures)
	_check(case_heading != null and records_scroll.is_ancestor_of(case_heading), "the named case card should render inside the Records scroll", failures)
	_check(case_heading != null and _contains_all(case_heading.text, [subject_name, "supervision", "surveillance"]), "embedded Flockwatch should render the canonical named case", failures)
	_check(case_evidence != null and _contains_all(case_evidence.text, ["risk 340", "grievance 70", "trust 10"]), "embedded Flockwatch should render canonical evidence rather than reconstructed values", failures)
	_check(held_remedy != null and held_remedy.disabled, "Fund Remedy should visibly hold outside Farmer Review", failures)
	_check(int(visual.call("visible_case_folder_count")) == 1, "the physical case office should show exactly one canonical folder", failures)
	_check(visual.call("open_case_ids") == [case_id], "the physical folder should retain the canonical case id", failures)
	var forwarded: Array[Dictionary] = []
	staffing_ui.flock_relations_action_requested.connect(
		func(forwarded_case_id: int, action_id: StringName) -> void:
			forwarded.append({"case_id": forwarded_case_id, "action_id": action_id})
	)
	var before_rejected_click := JSON.stringify(simulation.export_save_state())
	if held_remedy != null:
		# Direct signal emission models a stale click that bypasses Button.disabled;
		# the authoritative handler must still reject it atomically.
		held_remedy.pressed.emit()
	await process_frame
	_check(forwarded == [{"case_id": case_id, "action_id": &"fund_remedy"}], "the embedded case control should forward stable ids through RoostStaffingUI", failures)
	_check(JSON.stringify(simulation.export_save_state()) == before_rejected_click, "a mid-shift Fund Remedy signal should preserve every authoritative field", failures)
	var ticker := office.get("_ticker_label") as Label
	_check(ticker != null and _contains_all(ticker.text, ["only", "shift review"]), "the rejected Office handler should leave a truthful review-gate explanation", failures)

	# Reopen the same canonical file in Review, then exercise the player-facing
	# button -> case UI -> staffing UI -> Office handler -> simulation path.
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	office.call("_on_snapshot_changed", simulation.snapshot())
	office.call("_open_flockwatch_page", FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	await process_frame
	await process_frame
	var review_relations := simulation.flock_relations_snapshot()
	var review_cases := review_relations.get("open_cases", []) as Array
	var review_case := review_cases[0] as Dictionary if not review_cases.is_empty() else {}
	var remedy_option := _action_option(review_case, &"fund_remedy")
	var expected_cost := int(remedy_option.get("cost_cents", -1))
	var remedy := office.find_child("FlockRelationsAction_fund_remedy", true, false) as Button
	_check(bool(remedy_option.get("enabled", false)), "the authoritative review snapshot should enable Fund Remedy", failures)
	_check(expected_cost == 2000, "severity-three Fund Remedy should author the exact $20.00 cost", failures)
	_check(remedy != null and not remedy.disabled and "$20.00" in remedy.text, "the embedded review action should expose and enable the exact canonical cost", failures)
	var fund_before_remedy := simulation.revenue_cents
	var untouched_worker_before := (
		(simulation.export_save_state().get("workers", []) as Array)[1] as Dictionary
	).duplicate(true)
	forwarded.clear()
	if remedy != null:
		remedy.pressed.emit()
	await process_frame
	await process_frame

	_check(forwarded == [{"case_id": case_id, "action_id": &"fund_remedy"}], "review authorization should traverse RoostStaffingUI exactly once", failures)
	_check(simulation.revenue_cents == fund_before_remedy - expected_cost, "the Office handler should debit the exact canonical remedy cost once", failures)
	var resolved_relations := simulation.flock_relations_snapshot()
	_check(int(resolved_relations.get("open_case_count", -1)) == 0, "Fund Remedy should remove the selected case from the open docket", failures)
	_check(int(resolved_relations.get("resolved_total", -1)) == 1, "Fund Remedy should create exactly one lifetime resolution", failures)
	_check(int(resolved_relations.get("resolutions_used_today", -1)) == 1, "Fund Remedy should use exactly one review authorization", failures)
	_check(int(resolved_relations.get("settlement_spend_total_cents", -1)) == expected_cost, "the settlement ledger should contain exactly the remedy debit", failures)
	var resolution := resolved_relations.get("last_resolution", {}) as Dictionary
	_check(int(resolution.get("case_id", -1)) == case_id, "the permanent receipt should retain only the selected case identity", failures)
	_check(StringName(resolution.get("action_id", &"")) == &"fund_remedy", "the permanent receipt should retain the authorized disposition", failures)
	_check(String(resolution.get("worker_name", "")) == subject_name, "the permanent receipt should retain the real subject name", failures)
	var workers_after := simulation.export_save_state().get("workers", []) as Array
	_check((workers_after[1] as Dictionary) == untouched_worker_before, "resolving one case should not mutate an unrelated hen", failures)

	var receipt_label := office.find_child("FlockRelationsLastResolution", true, false) as Label
	var empty_label := _descendant_label_containing(records_scroll, "NO OPEN HEN FILES")
	_check(receipt_label != null and receipt_label.visible and _contains_all(receipt_label.text, [subject_name, "fund remedy", "$20.00"]), "the existing Flockwatch surface should refresh to the permanent receipt", failures)
	_check(receipt_label != null and records_scroll.is_ancestor_of(receipt_label), "the permanent receipt should remain inside the Records scroll", failures)
	_check(empty_label != null and records_scroll.is_ancestor_of(empty_label) and "no open hen files" in empty_label.text.to_lower(), "the refreshed Records page should retain an honest usable empty state", failures)
	_check(flockwatch.visible and records_scroll.is_visible_in_tree() and relations_ui.is_visible_in_tree(), "resolving a case should keep the existing Records ledger open and usable", failures)
	_check(navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, "case resolution should preserve the current Records page", failures)
	_check(records_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "the refreshed Records page should retain its contained scrolling contract", failures)
	var records_button := navigation.page_button(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	_check(records_button != null and records_button.is_visible_in_tree() and records_button.button_pressed, "the current Records tab should remain visible and selected after resolution", failures)
	_check(navigation.open_page(FlockwatchNavigation.PAGE_TODAY), "the resolved ledger should still navigate away from Records", failures)
	_check(navigation.open_page(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, true), "the resolved ledger should navigate back to Records", failures)
	await process_frame
	_check(navigation.current_page_id() == FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS and records_scroll.is_visible_in_tree(), "Records should remain usable after a page round trip", failures)
	_check(records_button != null and records_button.has_focus(), "returning to Records should provide a stable keyboard focus target", failures)
	_check(office.find_child("PurchaseFacility_%s" % String(FLOCK_RELATIONS), true, false) != null, "case resolution should not remove the remaining capital controls", failures)
	_check(int(visual.call("visible_case_folder_count")) == 0, "the physical office should remove only the resolved folder", failures)
	_check(StringName(visual.call("last_resolution_id")) == &"fund_remedy", "the physical office should consume the same permanent receipt", failures)
	_check(_contains_all(String(visual.call("relations_status_text")), ["open 00/01", "resolved 001", "settled $20.00"]), "the physical case console should refresh from the resolved canonical snapshot", failures)

	# JSON save/restore must reproduce the closed docket and single receipt without
	# resurrecting the case or appending a second history row on repeated restore.
	var saved := _json_round_trip(simulation.export_save_state())
	var restored := DepartmentSimulation.new(17_799, 4)
	_check(restored.restore_save_state(saved), "the schema-18 Office outcome should restore from JSON", failures)
	_check(restored.flock_relations_snapshot() == resolved_relations, "restored Flock Relations projection should exactly match the resolved Office state", failures)
	var restored_state := restored.export_save_state()
	_check((restored_state.get("flock_relations_open_cases", []) as Array).is_empty(), "restore should not resurrect the resolved case", failures)
	_check((restored_state.get("flock_relations_resolution_history", []) as Array).size() == 1, "restore should retain exactly one permanent resolution row", failures)
	_check(int(restored_state.get("next_flock_relations_case_id", -1)) == 2, "restore should retain the next stable case id without duplication", failures)
	var restored_again := DepartmentSimulation.new(17_800, 4)
	_check(restored_again.restore_save_state(_json_round_trip(restored_state)), "a second schema-18 round trip should restore", failures)
	_check((restored_again.export_save_state().get("flock_relations_resolution_history", []) as Array).size() == 1, "repeated restore should not duplicate the permanent receipt", failures)
	_check(restored_again.flock_relations_snapshot() == resolved_relations, "repeated restore should remain projection-idempotent", failures)

	var camera_controller := office.get("_camera_controller") as Node
	if camera_controller != null:
		camera_controller.call("show_overview")
	await _finish(office, failures)


func _action_option(case_record: Dictionary, action_id: StringName) -> Dictionary:
	for option_value in case_record.get("action_options", []) as Array:
		if option_value is Dictionary:
			var option := option_value as Dictionary
			if StringName(option.get("action_id", &"")) == action_id:
				return option.duplicate(true)
	return {}


func _json_round_trip(value: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(value))
	return parsed as Dictionary if parsed is Dictionary else {}


func _contains_all(copy: String, needles: Array[String]) -> bool:
	var lowered := copy.to_lower()
	for needle in needles:
		if not lowered.contains(needle.to_lower()):
			return false
	return true


func _descendant_label_containing(parent: Node, needle: String) -> Label:
	var normalized := needle.to_lower()
	for candidate in parent.find_children("*", "Label", true, false):
		var label := candidate as Label
		if label != null and normalized in label.text.to_lower():
			return label
	return null


func _finish(office: Node, failures: Array[String]) -> void:
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_RELATIONS_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_RELATIONS_OFFICE_INTEGRATION_TEST_PASSED tier1=real case=named+canonical reject=atomic remedy=ui-office visual=reactive persistence=idempotent")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
