extends SceneTree

const FlockRelationsCaseUIScript := preload("res://features/office/flock_relations_case_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var harness := Control.new()
	harness.size = Vector2(360.0, 720.0)
	root.add_child(harness)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	harness.add_child(scroll)
	var ui := FlockRelationsCaseUIScript.new()
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(ui)
	await process_frame

	ui.apply_snapshot({"flock_relations": _relations_snapshot()})
	await process_frame
	_check(ui.visible, "an installed Flock Relations tier should reveal its embedded case file", failures)
	var status := ui.find_child("FlockRelationsStatus", true, false) as Label
	var terms := ui.find_child("FlockRelationsTerms", true, false) as Label
	var case_heading := ui.find_child("CaseHeading", true, false) as Label
	var evidence := ui.find_child("CaseEvidence", true, false) as Label
	_check(status != null and status.text == "OPEN 1 / 2", "case status should show the authoritative open count and capacity", failures)
	_check(terms != null and _contains_all(terms.text, ["level 2", "1 / 2 used", "compliance", "solidarity", "grievance"]), "terms should disclose both the review allowance and carry consequences", failures)
	_check(case_heading != null and _contains_all(case_heading.text, ["mabel", "automation appeal"]), "the case card should identify its real hen and authored case title", failures)
	_check(evidence != null and _contains_all(evidence.text, ["compliance 54", "auto-routed"]), "the visible evidence should come from the canonical case record", failures)

	var requests: Array[Dictionary] = []
	ui.action_requested.connect(
		func(case_id: int, action_id: StringName) -> void:
			requests.append({"case_id": case_id, "action_id": action_id})
	)
	var remedy := ui.find_child("FlockRelationsAction_fund_remedy", true, false) as Button
	var mediate := ui.find_child("FlockRelationsAction_mediate", true, false) as Button
	var pip := ui.find_child("FlockRelationsAction_file_pip", true, false) as Button
	var arbitration := ui.find_child("FlockRelationsAction_binding_arbitration", true, false) as Button
	_check(remedy != null and not remedy.disabled and _contains_all(remedy.text, ["fund remedy", "$16.00"]), "the remedy action should expose its authoritative exact cost", failures)
	_check(mediate != null and not mediate.disabled and _contains_all(mediate.text, ["mediate", "$8.00"]), "tier two should expose its lower-cost mediation option", failures)
	_check(pip != null and not pip.disabled and _contains_all(pip.text, ["file pip", "no fund cost"]), "the coercive free option should be explicit rather than disguised", failures)
	_check(arbitration != null and arbitration.disabled and _contains_all(arbitration.tooltip_text, ["level 3", "held"]), "tier-three arbitration should remain visible with its exact gate", failures)
	_check(remedy != null and _contains_all(remedy.tooltip_text, ["trust", "grievance", "permanent case ledger"]), "action tooltips should disclose human consequences before authorization", failures)
	if mediate != null:
		mediate.pressed.emit()
	_check(requests == [{"case_id": 1, "action_id": &"mediate"}], "an action should emit the stable case and action IDs exactly once", failures)

	var last_resolution := ui.find_child("FlockRelationsLastResolution", true, false) as Label
	_check(last_resolution != null and _contains_all(last_resolution.text, ["mabel", "fund remedy", "$16.00", "repair budget"]), "the permanent receipt should summarize the last authoritative resolution", failures)

	var clear := _relations_snapshot()
	clear["open_case_count"] = 0
	clear["open_cases"] = []
	ui.apply_snapshot({"flock_relations": clear})
	await process_frame
	var no_cases := ui.find_child("FlockRelationsNoOpenCases", true, false) as Label
	_check(no_cases != null and _contains_all(no_cases.text, ["no open hen files", "documented strain"]), "an empty real queue should not fabricate labor activity", failures)

	ui.apply_snapshot({"flock_relations": {"level": 0}})
	await process_frame
	_check(not ui.visible, "an unbuilt office should not occupy Flockwatch space", failures)

	await _test_staffing_integration(failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FLOCK_RELATIONS_CASE_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCK_RELATIONS_CASE_UI_TEST_PASSED canonical=1 actions=4 receipt=1 empty=honest")
	quit(0)


func _test_staffing_integration(failures: Array[String]) -> void:
	var harness := Control.new()
	harness.size = Vector2(360.0, 900.0)
	root.add_child(harness)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	harness.add_child(scroll)
	var staffing_ui := RoostStaffingUIScript.new()
	staffing_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(staffing_ui)
	await process_frame
	var snapshot := {
		"active_staff_count": 5,
		"office_capacity": 5,
		"maximum_staff_capacity": 6,
		"staffing_planning_open": true,
		"daily_payroll_cents": 5200,
		"daily_facility_cost_cents": 900,
		"daily_operating_cost_cents": 7700,
		"spendable_fund_cents": 80_000,
		"revenue_cents": 100_000,
		"wage_arrears_cents": 0,
		"owned_facilities": {"flock_relations_office": 1},
		"flock_relations": _relations_snapshot(),
		"facility_catalog": [_facility_record()],
		"workers": [],
		"staffing_applicants": [],
	}
	staffing_ui.apply_snapshot(snapshot)
	await process_frame
	var embedded := staffing_ui.find_child("FlockRelationsCaseUI", true, false) as Control
	var gate := staffing_ui.find_child("FacilityFlockRelationsGate_flock_relations_office", true, false) as Label
	var delta := staffing_ui.find_child("FacilityFlockRelationsDelta_flock_relations_office", true, false) as Label
	_check(embedded != null and embedded.visible, "the case file should live inside the existing staffing ledger", failures)
	_check(gate != null and _contains_all(gate.text, ["rooster office 1 / 2", "1 tier short", "wellness nest 2 / 2", "cleared"]), "the facility card should make both structural dependencies visible", failures)
	_check(delta != null and _contains_all(delta.text, ["open file slots 1 -> 2", "review authorizations 1 -> 2"]), "the next tier should disclose its exact interactive capacity gain", failures)

	var forwarded: Array[Dictionary] = []
	staffing_ui.flock_relations_action_requested.connect(
		func(case_id: int, action_id: StringName) -> void:
			forwarded.append({"case_id": case_id, "action_id": action_id})
	)
	var action := staffing_ui.find_child("FlockRelationsAction_fund_remedy", true, false) as Button
	if action != null:
		action.pressed.emit()
	_check(forwarded == [{"case_id": 1, "action_id": &"fund_remedy"}], "the host ledger should forward the permanent case/action identity without translation", failures)
	harness.queue_free()
	await process_frame


func _relations_snapshot() -> Dictionary:
	return {
		"level": 2,
		"capacity": 2,
		"resolution_limit": 2,
		"resolutions_used_today": 1,
		"open_case_count": 1,
		"open_cases": [{
			"case_id": 1,
			"docket_id": "FR-D8-H0-1",
			"worker_id": 0,
			"worker_name": "Mabel",
			"case_type": "automation_appeal",
			"title": "Automation Appeal",
			"severity": 2,
			"filed_day": 8,
			"status": "open",
			"evidence_summary": "Compliance 54 after repeated AUTO-routed folders.",
			"action_options": [
				{
					"action_id": "fund_remedy",
					"label": "Fund Remedy",
					"required_level": 1,
					"cost_cents": 1600,
					"enabled": true,
					"reason": "Available during Farmer Review.",
					"effect_preview": "Trust +12 | grievance -16 | compliance +4",
				},
				{
					"action_id": "mediate",
					"label": "Mediate",
					"required_level": 2,
					"cost_cents": 800,
					"enabled": true,
					"reason": "Available during Farmer Review.",
					"effect_preview": "Trust +7 | grievance -9 | compliance +2",
				},
				{
					"action_id": "file_pip",
					"label": "File PIP",
					"required_level": 1,
					"cost_cents": 0,
					"enabled": true,
					"reason": "Available during Farmer Review.",
					"effect_preview": "Trust -10 | grievance +14 | farmer favor +3",
				},
				{
					"action_id": "binding_arbitration",
					"label": "Binding Arbitration",
					"required_level": 3,
					"cost_cents": 1200,
					"enabled": false,
					"reason": "HELD: Mandatory Arbitration Roost requires level 3.",
					"effect_preview": "Compliance +6 | grievance -5 | trust -3",
				},
			],
		}],
		"resolved_total": 3,
		"denied_total": 1,
		"settlement_spend_total_cents": 3600,
		"last_resolution": {
			"worker_name": "Mabel",
			"action_id": "fund_remedy",
			"action_label": "Fund Remedy",
			"cost_cents": 1600,
			"outcome": "A repair budget was entered into the permanent case file.",
		},
	}


func _facility_record() -> Dictionary:
	return {
		"id": "flock_relations_office",
		"name": "FLOCK RELATIONS OFFICE",
		"short_name": "FLOCK RELATIONS",
		"description": "A cumulative labor-case office for documented hen strain.",
		"level": 1,
		"next_level": 2,
		"max_level": 3,
		"level_name": "OPEN-NEST CASE INTAKE",
		"next_level_name": "MEDIATION & PIP ROOM",
		"installed": true,
		"owned": true,
		"maxed": false,
		"unlocked": false,
		"planning_open": true,
		"affordable": true,
		"can_purchase": false,
		"reason": "Rooster Operations Office level 2 is required.",
		"cost_cents": 17_500,
		"current_maintenance_cents": 500,
		"next_maintenance_cents": 900,
		"maintenance_delta_cents": 400,
		"projected_spendable_fund_cents": 62_100,
		"projected_protected_reserve_cents": 8100,
		"benefits": ["Adds a second open labor-case slot", "Adds a second review authorization"],
		"tradeoffs": ["Unresolved cases carry compliance and grievance pressure"],
		"current_flock_relations_case_capacity": 1,
		"next_flock_relations_case_capacity": 2,
		"current_flock_relations_resolution_limit": 1,
		"next_flock_relations_resolution_limit": 2,
		"rooster_operations_office_level": 1,
		"required_rooster_operations_office_level": 2,
		"rooster_operations_office_level_shortfall": 1,
		"wellness_nest_level": 2,
		"required_wellness_nest_level": 2,
		"wellness_nest_level_shortfall": 0,
	}


func _contains_all(copy: String, needles: Array[String]) -> bool:
	var lowered := copy.to_lower()
	for needle in needles:
		if not lowered.contains(needle.to_lower()):
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
