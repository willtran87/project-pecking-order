extends SceneTree

const CareerSponsorshipUIScript := preload("res://features/office/career_sponsorship_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {"count": 0, "worker_id": -1, "lane_id": &""}
	var harness := Control.new()
	harness.name = "CareerSponsorshipUITestHarness"
	harness.size = Vector2(390.0, 844.0)
	root.add_child(harness)

	var margin := MarginContainer.new()
	margin.name = "PortraitSafeMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	harness.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "CareerSponsorshipTestScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var report_column := VBoxContainer.new()
	report_column.name = "CareerSponsorshipReportColumn"
	report_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(report_column)

	var ui = CareerSponsorshipUIScript.new()
	report_column.add_child(ui)
	ui.sponsorship_requested.connect(func(worker_id: int, lane_id: StringName) -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["worker_id"] = worker_id
		observed["lane_id"] = lane_id
	)
	await process_frame

	ui.apply_snapshot(_available_snapshot())
	await process_frame
	await process_frame

	var heading := ui.find_child("CareerSponsorshipHeading", true, false) as Label
	var optional_note := ui.find_child("CareerSponsorshipOptionalNote", true, false) as Label
	var balance := ui.find_child("CareerSponsorshipBalance", true, false) as Label
	var worker_selector := ui.find_child("CareerSponsorshipHenSelector", true, false) as OptionButton
	var worker_detail := ui.find_child("CareerSponsorshipWorkerDetail", true, false) as Label
	var lane_selector := ui.find_child("CareerSponsorshipLaneSelector", true, false) as OptionButton
	var terms := ui.find_child("CareerSponsorshipTerms", true, false) as Label
	var reason_label := ui.find_child("CareerSponsorshipUnavailableReason", true, false) as Label
	var authorize := ui.find_child("CareerSponsorshipAuthorizeButton", true, false) as Button

	_check(ui.visible, "visible Senior report snapshots should reveal the sponsorship section", failures)
	_check(heading != null and heading.text == "CAREER SPONSORSHIP", "section should use its authored report heading", failures)
	_check(optional_note != null and "OPTIONAL" in optional_note.text and "Bank every Roost Mark" in optional_note.text, "copy should make banking marks explicitly valid", failures)
	_check(balance != null and "AVAILABLE  5 ROOST MARKS" in balance.text and "3 MARKS + $12.00" in balance.text, "balance should disclose both exact immediate costs", failures)
	_check(worker_selector != null and worker_selector.item_count == 2, "valid unique hens should populate the selector", failures)
	_check(worker_selector != null and worker_selector.focus_mode == Control.FOCUS_ALL, "hen selector should accept keyboard focus", failures)
	_check(lane_selector != null and lane_selector.focus_mode == Control.FOCUS_ALL, "lane selector should accept keyboard focus", failures)
	_check(authorize != null and authorize.focus_mode == Control.FOCUS_ALL, "authorize action should accept keyboard focus", failures)
	_check(ui.theme != null, "standalone component should carry the authored management theme", failures)

	# Mabel's primary Appeals lane and completed Predator training are both held,
	# leaving only Nest Damage despite malformed and duplicate catalog entries.
	_check(ui.selected_worker_id() == 3, "first valid worker should be selected deterministically", failures)
	_check(lane_selector != null and lane_selector.item_count == 1, "primary and already-trained lanes should be filtered", failures)
	_check(ui.selected_lane_id() == &"nest_damage", "the remaining untrained alternate lane should be selected", failures)
	_check(worker_detail != null and "PRIMARY  APPEALS" in worker_detail.text and "$6.00/day" in worker_detail.text, "selected hen details should disclose current role and wage", failures)
	_check(terms != null and "3 Roost Marks + $12.00" in terms.text, "terms should repeat the exact immediate authorization cost", failures)
	_check(terms != null and "-15% training throughput" in terms.text, "terms should disclose the exact next-shift training penalty", failures)
	_check(terms != null and "+$1.00/day wage" in terms.text, "terms should disclose the permanent wage liability", failures)
	_check(terms != null and "Specialist affinity: NEST DAMAGE" in terms.text, "terms should name the post-training specialist affinity", failures)
	_check(reason_label != null and not reason_label.visible, "available sponsorship should not show a held reason", failures)
	_check(authorize != null and not authorize.disabled, "valid affordable sponsorship should be authorizable", failures)

	# Keyboard selectors expose Pip's only remaining alternate lane after primary and
	# secondary specialties are filtered.
	worker_selector.select(1)
	worker_selector.item_selected.emit(1)
	await process_frame
	_check(ui.selected_worker_id() == 8, "hen selector should update the stable worker id", failures)
	_check(lane_selector.item_count == 1 and ui.selected_lane_id() == &"appeals", "secondary specialty should be treated as already trained", failures)
	_check("Specialist affinity: APPEALS" in terms.text, "terms should refresh with the selected alternate lane", failures)
	if authorize != null:
		authorize.pressed.emit()
	_check(int(observed["count"]) == 1, "valid authorization should emit one intent", failures)
	_check(int(observed["worker_id"]) == 8 and StringName(observed["lane_id"]) == &"appeals", "intent should carry stable worker and lane domain ids", failures)

	# Insufficient marks produce an exact computed reason and direct signal emission
	# cannot bypass the component guard.
	ui.apply_snapshot(_insufficient_marks_snapshot())
	await process_frame
	var shortage_reason := "1 more Roost Mark is required. Bank this opportunity for a later quarter."
	_check(authorize.disabled, "mark shortfall should disable authorization", failures)
	_check(ui.authorization_reason() == shortage_reason, "mark shortfall reason should be exact and bankable", failures)
	_check(reason_label.visible and reason_label.text == shortage_reason, "exact shortfall should be visible without relying on a tooltip", failures)
	_check(authorize.tooltip_text == shortage_reason, "disabled button should retain the same exact reason", failures)
	authorize.pressed.emit()
	_check(int(observed["count"]) == 1, "disabled authorization must not emit even when pressed is signaled directly", failures)

	# An authoritative simulation reason takes precedence and is preserved verbatim.
	var held := _available_snapshot()
	held["unavailable_reason"] = "Payroll reserve is $4.00 short."
	ui.apply_snapshot(held)
	await process_frame
	_check(authorize.disabled and ui.authorization_reason() == "Payroll reserve is $4.00 short.", "authoritative unavailable reasons should remain verbatim", failures)
	_check(reason_label.text == "Payroll reserve is $4.00 short." and authorize.tooltip_text == reason_label.text, "visible and tooltip reasons should not drift", failures)

	# A worker with every lane already trained remains legible and cannot emit an
	# impossible same-specialty sponsorship.
	ui.apply_snapshot(_no_alternate_snapshot())
	await process_frame
	_check(lane_selector.item_count == 0 and lane_selector.disabled, "same-primary and fully-trained options should be removed defensively", failures)
	_check(authorize.disabled and "no untrained alternate specialty" in ui.authorization_reason(), "fully trained hen should receive a specific held reason", failures)

	# Report embedding at the smallest supported viewport must stay inside its
	# parent and must never ask the report ScrollContainer to scroll horizontally.
	ui.apply_snapshot(_available_snapshot())
	await process_frame
	await process_frame
	var ui_rect := ui.get_global_rect()
	var margin_rect := margin.get_global_rect()
	_check(ui_rect.position.x >= margin_rect.position.x - 0.5 and ui_rect.end.x <= margin_rect.end.x + 0.5, "component should remain inside a 390px portrait report (ui=%s margin=%s)" % [ui_rect, margin_rect], failures)
	_check(ui.get_combined_minimum_size().x <= margin_rect.size.x + 0.5, "component minimum width should not force horizontal overflow", failures)
	_check(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "report host should require no horizontal scrolling", failures)
	_check(_visible_children_fit_horizontally(ui, ui_rect), "every visible sponsorship control should remain within the component width", failures)

	ui.apply_snapshot({"visible": false})
	await process_frame
	_check(not ui.visible, "non-Senior or non-report snapshots should hide the section", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_SPONSORSHIP_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_SPONSORSHIP_UI_TEST_PASSED authored=compact filtering=defensive costs=exact keyboard=accessible reasons=exact responsive=390x844 signal=typed")
	quit(0)


func _available_snapshot() -> Dictionary:
	return {
		"visible": true,
		"available_marks": 5,
		"mark_cost": 3,
		"fund_cost_cents": 1200,
		"unavailable_reason": "",
		"eligible_workers": [
			{
				"id": 3,
				"name": "Mabel",
				"career_title": "Senior Layer",
				"primary_specialty": "appeals",
				"secondary_specialty": "",
				"wage_cents": 600,
				"training": {"completed_lane_ids": ["predator_loss"]},
			},
			{
				"id": 8,
				"name": "Pip With A Deliberately Long Corporate Career File",
				"career_title": "Associate Claims Layer With A Long Filed Title",
				"primary_specialty": "nest_damage",
				"secondary_specialty": "predator_loss",
				"wage_cents": 500,
			},
			{"id": 8, "name": "Duplicate Pip"},
			{"id": -1, "name": "Invalid Hen"},
			"malformed worker",
		],
		"lanes": [
			{"id": "nest_damage", "label": "Nest Damage"},
			{"id": "predator_loss", "label": "Predator Loss"},
			{"id": "appeals", "label": "Appeals"},
			{"id": "appeals", "label": "Duplicate Appeals"},
			{"id": "", "label": "Invalid"},
			"malformed lane",
		],
	}


func _insufficient_marks_snapshot() -> Dictionary:
	var snapshot := _available_snapshot()
	snapshot["available_marks"] = 2
	return snapshot


func _no_alternate_snapshot() -> Dictionary:
	return {
		"visible": true,
		"available_marks": 9,
		"mark_cost": 3,
		"fund_cost_cents": 1200,
		"eligible_workers": [
			{
				"id": 12,
				"name": "Agnes",
				"career_title": "Cross-Trained Layer",
				"primary_specialty": "nest_damage",
				"secondary_specialties": ["predator_loss", "appeals"],
				"wage_cents": 700,
			},
		],
		"lanes": [
			{"id": "nest_damage", "label": "Nest Damage"},
			{"id": "predator_loss", "label": "Predator Loss"},
			{"id": "appeals", "label": "Appeals"},
		],
	}


func _visible_children_fit_horizontally(root_control: Control, root_rect: Rect2) -> bool:
	for node: Node in root_control.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.position.x < root_rect.position.x - 0.5 or rect.end.x > root_rect.end.x + 0.5:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
