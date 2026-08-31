extends SceneTree

const FlockRelationsCaseUIScript := preload("res://features/office/flock_relations_case_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var test_viewport := SubViewport.new()
	test_viewport.name = "FlockRelationsScaleViewport"
	test_viewport.size = Vector2i(282, 760)
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	var harness := Control.new()
	harness.size = Vector2(282.0, 760.0)
	test_viewport.add_child(harness)
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
	var open_glance := ui.find_child("FlockRelationsOpenGlance", true, false) as Label
	var review_glance := ui.find_child("FlockRelationsReviewGlance", true, false) as Label
	var carry_glance := ui.find_child("FlockRelationsCarryGlance", true, false) as Label
	var cases_toggle := ui.find_child("FlockRelationsCasesToggle", true, false) as Button
	var case_heading := ui.find_child("CaseHeading", true, false) as Label
	var evidence := ui.find_child("CaseEvidence", true, false) as Label
	var risk_glance := ui.find_child("CaseEvidenceRisk", true, false) as Label
	var grievance_glance := ui.find_child("CaseEvidenceGriev", true, false) as Label
	var stress_glance := ui.find_child("CaseEvidenceStress", true, false) as Label
	var compliance_glance := ui.find_child("CaseEvidenceComply", true, false) as Label
	_check(status != null and not status.visible and status.text == "OPEN 1 / 2", "the exact case count should remain in hidden component state", failures)
	_check(terms != null and not terms.visible and _contains_all(terms.text, ["level 2", "1 / 2 used", "compliance", "solidarity", "grievance"]), "full authorization and carry terms should remain available without occupying the glance view", failures)
	_check(open_glance != null and open_glance.text == "OPEN\n1 / 2", "the glance view should expose open cases against capacity", failures)
	_check(review_glance != null and review_glance.text == "REVIEW\n1 LEFT", "the glance view should expose remaining review authority", failures)
	_check(carry_glance != null and carry_glance.text == "UNRESOLVED  /  PRESSURE NEXT SHIFT" and _contains_all(carry_glance.tooltip_text, ["compliance", "solidarity", "grievance"]), "one carry cue should replace the full recurring consequence paragraph", failures)
	_check(open_glance != null and String(open_glance.get_meta("accessible_text", "")) == open_glance.tooltip_text and review_glance != null and String(review_glance.get_meta("accessible_text", "")) == review_glance.tooltip_text, "glance metrics should retain their exact authorization narration", failures)
	_check(cases_toggle != null and cases_toggle.text == "HIDE CASES  /  1 OPEN" and _contains_all(cases_toggle.tooltip_text, ["1 open of 2", "exact costs", "held reasons"]), "the case disclosure should use a fitted action while retaining its complete scope", failures)
	_check(case_heading != null and case_heading.text == "MABEL  /  AUTOMATION" and _contains_all(case_heading.tooltip_text, ["mabel", "automation appeal"]), "the case card should use a stable type token while retaining its full authored title", failures)
	_check(evidence != null and not evidence.visible and _contains_all(evidence.text, ["compliance 54", "auto-routed"]), "the exact evidence filing should remain in component state", failures)
	_check(risk_glance != null and risk_glance.text == "RISK\n340" and grievance_glance != null and grievance_glance.text == "GRIEV\n70" and stress_glance != null and stress_glance.text == "STRESS\n60" and compliance_glance != null and compliance_glance.text == "COMPLY\n54", "four compact evidence tiles should expose the decision-driving case state", failures)

	var requests: Array[Dictionary] = []
	ui.action_requested.connect(
		func(case_id: int, action_id: StringName) -> void:
			requests.append({"case_id": case_id, "action_id": action_id})
	)
	var remedy := ui.find_child("FlockRelationsAction_fund_remedy", true, false) as Button
	var mediate := ui.find_child("FlockRelationsAction_mediate", true, false) as Button
	var pip := ui.find_child("FlockRelationsAction_file_pip", true, false) as Button
	var arbitration := ui.find_child("FlockRelationsAction_binding_arbitration", true, false) as Button
	var confirmation := ui.find_child(
		"FlockRelationsDispositionConfirmation",
		true,
		false,
	) as ConfirmationDialog
	_check(
		confirmation != null
		and confirmation.theme_type_variation == &"HeldConfirmationDialog"
		and String(confirmation.get_meta("held_confirmation_skin", "")) == "flockwatch_compact"
		and confirmation.has_theme_stylebox_override("embedded_border")
		and confirmation.has_theme_stylebox_override("panel")
		and confirmation.get_ok_button().theme_type_variation == &"DangerButton"
		and confirmation.get_cancel_button().theme_type_variation == &"PrimaryButton"
		and confirmation.get_ok_button().icon != null
		and confirmation.get_cancel_button().icon != null
		and String(confirmation.get_ok_button().get_meta("semantic_icon", ""))
		== "irreversible_warning"
		and String(confirmation.get_cancel_button().get_meta("semantic_icon", ""))
		== "safe_return_arrow",
		"labor dispositions should share the authored compact irreversible-decision skin",
		failures,
	)
	_check(remedy != null and not remedy.disabled and remedy.text == "REPAIR\n$16.00" and _contains_all(remedy.tooltip_text, ["fund remedy", "$16.00", "trust +12", "permanent case ledger"]), "the repair action should pair a concise verb with its exact cost and full tooltip", failures)
	_check(remedy != null and String(remedy.get_meta("accessible_text", "")) == remedy.tooltip_text, "the concise repair action should retain the same exact assistive filing", failures)
	_check(mediate != null and not mediate.disabled and _contains_all(mediate.text, ["mediate", "$8.00"]), "tier two should expose its lower-cost mediation option", failures)
	_check(pip != null and not pip.disabled and pip.text == "PENALIZE\n$0" and _contains_all(pip.tooltip_text, ["file pip", "no fund cost", "trust -10", "grievance +14"]), "the coercive free option should remain explicit through its visible penalty label and exact tooltip", failures)
	_check(arbitration != null and arbitration.disabled and arbitration.text == "RULING\nHELD" and _contains_all(arbitration.tooltip_text, ["binding arbitration", "$12.00", "level 3", "held"]), "tier-three arbitration should remain visibly held with its exact cost and gate on demand", failures)
	_check(remedy != null and _contains_all(remedy.tooltip_text, ["trust", "grievance", "permanent case ledger"]), "action tooltips should disclose human consequences before authorization", failures)
	if mediate != null:
		mediate.pressed.emit()
	await process_frame
	_check(
		confirmation != null
		and confirmation.visible
		and requests.is_empty()
		and confirmation.get_cancel_button().has_focus()
		and _contains_all(
			confirmation.dialog_text,
			[
				"mabel",
				"automation appeal",
				"mediate",
				"$8.00 now",
				"trust +7",
				"permanent labor file",
				"cannot be undone",
			],
		),
		"labor disposition should disclose the named case, cost, effects, and permanent record before emitting",
		failures,
	)
	if confirmation != null:
		confirmation.canceled.emit()
	await process_frame
	_check(
		requests.is_empty(),
		"canceling a labor disposition should preserve the open case",
		failures,
	)
	if mediate != null:
		mediate.pressed.emit()
	await process_frame
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	_check(requests == [{"case_id": 1, "action_id": &"mediate"}], "one confirmed action should emit the stable case and action IDs exactly once", failures)
	if confirmation != null:
		confirmation.confirmed.emit()
	_check(
		requests == [{"case_id": 1, "action_id": &"mediate"}],
		"duplicate labor confirmation must not emit twice",
		failures,
	)

	var last_resolution := ui.find_child("FlockRelationsLastResolution", true, false) as Label
	_check(last_resolution != null and last_resolution.text == "LAST  /  MABEL  /  REPAIR  /  -$16.00" and _contains_all(last_resolution.tooltip_text, ["mabel", "fund remedy", "$16.00", "repair budget"]), "the compact last strip should preserve the full permanent receipt on demand", failures)

	var prior_theme := ui.theme
	var control_records := _capture_control_records(ui)
	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	await process_frame
	await process_frame
	if "--capture-max-scale-flock-relations" in OS.get_cmdline_user_args():
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/flock-relations-glance-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var image := test_viewport.get_texture().get_image()
		if image != null:
			_check(
				image.save_png(capture_directory.path_join(
					"flock-relations-282x760-150.png"
				)) == OK,
				"authored Flock Relations capture should save",
				failures,
			)
	_expand_interface_copy(ui)
	await process_frame
	await process_frame
	var ui_rect := ui.get_global_rect()
	_check(
		ui.get_combined_minimum_size().x <= scroll.size.x + 0.5
		and _visible_children_fit_horizontally(ui, ui_rect),
		"150-percent expanded Flock Relations should remain vertical-only (minimum=%s viewport=%s)"
		% [ui.get_combined_minimum_size(), scroll.size],
		failures,
	)
	pip = ui.find_child(
		"FlockRelationsAction_file_pip",
		true,
		false,
	) as Button
	if pip != null:
		scroll.ensure_control_visible(pip)
	await process_frame
	await process_frame
	_check(
		pip != null
		and pip.is_visible_in_tree()
		and scroll.get_global_rect().intersects(pip.get_global_rect()),
		"the coercive disposition should remain physically reachable at max scale",
		failures,
	)
	if pip != null:
		pip.pressed.emit()
	await process_frame
	confirmation = ui.find_child(
		"FlockRelationsDispositionConfirmation",
		true,
		false,
	) as ConfirmationDialog
	_check(
		confirmation != null
		and confirmation.visible
		and _contains_all(
			confirmation.dialog_text,
			["mabel", "file pip", "no fund cost", "trust -10", "permanent"],
		),
		"the coercive PIP should retain its human effects and permanent-record warning",
		failures,
	)
	if (
		"--capture-max-scale-flock-relations" in OS.get_cmdline_user_args()
		and confirmation != null
	):
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/flock-relations-glance-v1"
		)
		var confirmation_image := confirmation.get_texture().get_image()
		if confirmation_image != null:
			_check(
				confirmation_image.save_png(capture_directory.path_join(
					"flock-relations-confirmation-150.png"
				)) == OK,
				"authored Flock Relations confirmation capture should save",
				failures,
			)
	var confirmation_records := _capture_control_records(confirmation)
	_apply_explicit_font_scale(confirmation, 1.5)
	_expand_interface_copy(confirmation)
	await process_frame
	await process_frame
	_check(
		confirmation != null
		and confirmation.size.x <= 390
		and confirmation.size.y <= 844
		and _popup_control_fits(confirmation, confirmation.get_ok_button())
		and _popup_control_fits(confirmation, confirmation.get_cancel_button()),
		"expanded labor disposition should fit 390x844 with both choices reachable (size=%s)"
		% [confirmation.size if confirmation != null else Vector2i.ZERO],
		failures,
	)
	_restore_control_records(confirmation_records)
	if confirmation != null:
		confirmation.canceled.emit()
	_restore_control_records(control_records)
	ui.theme = prior_theme
	await process_frame
	await process_frame

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

	test_viewport.queue_free()
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
	var confirmation := staffing_ui.find_child(
		"FlockRelationsDispositionConfirmation",
		true,
		false,
	) as ConfirmationDialog
	if action != null:
		action.pressed.emit()
	await process_frame
	if confirmation != null:
		confirmation.confirmed.emit()
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
			"evidence": {
				"risk_score": 340,
				"grievance": 70.0,
				"stress": 60.0,
				"fatigue": 50.0,
				"manager_trust": 10.0,
				"it_coop_installed": true,
				"compliance": 54.0,
			},
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


func _visible_children_fit_horizontally(
	root_control: Control,
	root_rect: Rect2,
) -> bool:
	for node_value: Node in root_control.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if (
			rect.position.x < root_rect.position.x - 0.5
			or rect.end.x > root_rect.end.x + 0.5
		):
			return false
	return true


func _popup_control_fits(popup: Window, control: Control) -> bool:
	if popup == null or control == null or not control.is_visible_in_tree():
		return false
	return Rect2(Vector2.ZERO, Vector2(popup.size)).encloses(
		control.get_global_rect()
	)


func _capture_control_records(root_node: Node) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if root_node == null:
		return records
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		var record := {
			"control": control,
			"had_font_override": control.has_theme_font_size_override(
				"font_size"
			),
			"font_size": control.get_theme_font_size("font_size"),
			"kind": &"",
			"text": "",
		}
		if control is Button:
			record["kind"] = &"button"
			record["text"] = (control as Button).text
		elif control is Label:
			record["kind"] = &"label"
			record["text"] = (control as Label).text
		records.append(record)
	return records


func _restore_control_records(records: Array[Dictionary]) -> void:
	for record: Dictionary in records:
		var value: Variant = record.get("control")
		if not is_instance_valid(value):
			continue
		var control := value as Control
		if control == null:
			continue
		match StringName(record.get("kind", &"")):
			&"button":
				(control as Button).text = String(record.get("text", ""))
			&"label":
				(control as Label).text = String(record.get("text", ""))
		if bool(record.get("had_font_override", false)):
			control.add_theme_font_size_override(
				"font_size",
				int(record.get("font_size", 16)),
			)
		else:
			control.remove_theme_font_size_override("font_size")


func _apply_explicit_font_scale(root_node: Node, scale: float) -> void:
	if root_node == null:
		return
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		var control := node_value as Control
		if (
			control != null
			and control.has_theme_font_size_override("font_size")
		):
			var base_size := control.get_theme_font_size("font_size")
			control.add_theme_font_size_override(
				"font_size",
				maxi(10, roundi(float(base_size) * scale)),
			)


func _expand_interface_copy(root_node: Node) -> void:
	if root_node == null:
		return
	for node_value: Node in root_node.find_children(
		"*",
		"Control",
		true,
		false,
	):
		if node_value is Button:
			var button := node_value as Button
			button.text = _expanded(button.text)
		elif node_value is Label:
			var label := node_value as Label
			label.text = _expanded(label.text)


func _expanded(source: String) -> String:
	var expanded := source
	for vowel: String in [
		"a",
		"e",
		"i",
		"o",
		"u",
		"A",
		"E",
		"I",
		"O",
		"U",
	]:
		expanded = expanded.replace(vowel, vowel + vowel)
	return expanded


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
