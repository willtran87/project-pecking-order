extends SceneTree

const ManagementUIThemeScript := preload(
	"res://features/office/management_ui_theme.gd"
)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(25101, 6)
	simulation.day = 12
	simulation.owned_facilities[
		DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID
	] = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 100_000
	simulation.export_save_state()

	var test_viewport := SubViewport.new()
	test_viewport.name = "ManagerRecruitmentTestViewport"
	test_viewport.size = Vector2i(390, 844)
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	var harness := Control.new()
	harness.name = "ManagerRecruitmentHarness"
	harness.size = Vector2(390.0, 844.0)
	harness.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	test_viewport.add_child(harness)

	var margin := MarginContainer.new()
	margin.name = "ManagerPortraitSafeMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	harness.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "ManagerRecruitmentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	var report_column := VBoxContainer.new()
	report_column.name = "ManagerRecruitmentColumn"
	report_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(report_column)

	var ui := RoostStaffingUI.new()
	report_column.add_child(ui)
	var observed := {
		"count": 0,
		"candidate_id": &"",
		"result": {},
	}
	ui.manager_recruit_requested.connect(func(candidate_id: StringName) -> void:
		observed["count"] = int(observed["count"]) + 1
		observed["candidate_id"] = candidate_id
		var result := simulation.recruit_manager(candidate_id)
		observed["result"] = result
		ui.apply_snapshot(simulation.snapshot())
	)
	ui.apply_snapshot(simulation.snapshot())
	var sections := ui.navigation_sections()
	for section_id: StringName in [&"flock", &"capital", &"records"]:
		var section := sections.get(section_id) as Control
		if section != null:
			section.visible = false
	var operations := sections.get(&"operations") as Control
	if operations != null:
		operations.visible = true
	await process_frame
	await process_frame

	var roster := ui.find_child("ManagerRoster", true, false) as VBoxContainer
	var candidates := ui.find_child(
		"ManagerCandidateSlate",
		true,
		false,
	) as VBoxContainer
	var recruit := ui.find_child(
		"RecruitManager_byte_automation",
		true,
		false,
	) as Button
	var terms := ui.find_child(
		"ManagerCandidateTerms_byte_automation",
		true,
		false,
	) as Label
	var confirmation := ui.find_child(
		"ManagerRecruitConfirmation",
		true,
		false,
	) as ConfirmationDialog
	var manager_toggle := ui.find_child("ManagerRosterToggle", true, false) as Button
	var successor_toggle := ui.find_child("ManagerSuccessorToggle", true, false) as Button
	var checkins_glance := ui.find_child("RoosterOperationsCheckinsGlance", true, false) as Label
	var payroll_glance := ui.find_child("RoosterOperationsPayrollGlance", true, false) as Label
	var pressure_glance := ui.find_child("RoosterOperationsPressureGlance", true, false) as Label
	var density_glance := ui.find_child("RoosterOperationsDensityGlance", true, false) as Label
	var automation_glance := ui.find_child("RoosterOperationsAutomationGlance", true, false) as Label
	var exposure_glance := ui.find_child("RoosterOperationsExposureGlance", true, false) as Label
	_check(
		operations != null and roster != null and candidates != null,
		"Operations should contain the manager roster and screened successor slate",
		failures,
	)
	_check(
		manager_toggle != null
		and successor_toggle != null
		and not ui.managers_expanded()
		and not ui.successors_expanded()
		and not roster.visible
		and not candidates.visible,
		"manager detail and succession terms should default to collapsed review disclosures",
		failures,
	)
	_check(
		checkins_glance != null
		and payroll_glance != null
		and pressure_glance != null
		and density_glance != null
		and automation_glance != null
		and exposure_glance != null
		and _contains_all(checkins_glance.text, ["CHECK-IN", "LEFT"])
		and _contains_all(payroll_glance.text, ["PAY", "/ DAY"])
		and "PRESSURE" in pressure_glance.text
		and "DENSITY" in density_glance.text
		and "AUTO" in automation_glance.text
		and "EXPOSURE" in exposure_glance.text,
		"operations should expose six terse, ledger-backed first-read tiles",
		failures,
	)
	ui.set_managers_expanded(true)
	await process_frame
	_check(
		roster != null
		and roster.find_children(
			"ManagerCard_*",
			"PanelContainer",
			true,
			false,
		).size() == 4,
		"tier three should render four named management posts",
		failures,
	)
	_check(
		candidates != null
		and candidates.find_children(
			"ManagerCandidateCard_*",
			"PanelContainer",
			true,
			false,
		).size() == 2,
		"the successor slate should present the two available alternatives as readable cards",
		failures,
	)
	_check(
		recruit != null
		and not recruit.disabled
		and recruit.text == "REVIEW",
		"an affordable successor should expose a review-first appointment action",
		failures,
	)
	_check(
		terms != null
		and not terms.visible
		and _contains_all(
			terms.text,
			["$70.00", "REPLACES", "ROOSTERS  4", "PAYROLL", "EGGS  0"],
		),
		"exact successor economics should remain authored but visually deferred",
		failures,
	)
	var fee_glance := ui.find_child("ManagerCandidateFee_byte_automation", true, false) as Label
	var replace_glance := ui.find_child("ManagerCandidateReplace_byte_automation", true, false) as Label
	var candidate_payroll_glance := ui.find_child("ManagerCandidatePayroll_byte_automation", true, false) as Label
	var eggs_glance := ui.find_child("ManagerCandidateEggs_byte_automation", true, false) as Label
	_check(
		fee_glance != null
		and replace_glance != null
		and candidate_payroll_glance != null
		and eggs_glance != null
		and _contains_all(fee_glance.text, ["FEE", "$70"])
		and "REPLACE" in replace_glance.text
		and "PAY" in candidate_payroll_glance.text
		and _contains_all(eggs_glance.text, ["EGGS", "0"])
		and String(fee_glance.get_meta("accessible_text", "")).contains("$70.00"),
		"successor cards should communicate the action through four compact metrics while preserving exact accessible terms",
		failures,
	)
	_check(
		confirmation != null,
		"manager succession should build one explicit confirmation dialog",
		failures,
	)

	var operations_snapshot := simulation.operations_snapshot()
	var byte_candidate := _candidate(
		operations_snapshot,
		&"byte_automation",
	)
	_check(
		int(byte_candidate.get("supervisor_payroll_before_cents", -1))
		== simulation.current_daily_supervisor_payroll_cents()
		and int(byte_candidate.get("supervisor_payroll_after_cents", -1))
		== simulation.current_daily_supervisor_payroll_cents(),
		"authoritative candidate terms should project the exact unchanged base payroll for an unpromoted replacement",
		failures,
	)
	_check(
		StringName(String(byte_candidate.get(
			"replaces_manager_id",
			"",
		))) != &"",
		"authoritative candidate terms should identify the exact manager being replaced",
		failures,
	)

	_apply_explicit_font_scale(operations, 1.5)
	await process_frame
	await process_frame
	if "--capture-max-scale-managers" in OS.get_cmdline_user_args():
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/manager-recruitment-scale-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		ui.set_managers_expanded(false)
		ui.set_successors_expanded(false)
		scroll.scroll_vertical = 0
		await process_frame
		await process_frame
		var glance_image := test_viewport.get_texture().get_image()
		_check(
			glance_image != null,
			"manager operations should expose a rendered glance texture",
			failures,
		)
		if glance_image != null:
			_check(
				glance_image.save_png(
					capture_directory.path_join(
						"manager-operations-glance-390x844.png"
					)
				) == OK,
				"manager operations glance capture should save",
				failures,
			)
		ui.set_managers_expanded(true)
		await process_frame
		await process_frame
		var roster_image := test_viewport.get_texture().get_image()
		if roster_image != null:
			_check(
				roster_image.save_png(capture_directory.path_join("manager-roster-390x844.png")) == OK,
				"manager roster capture should save",
				failures,
			)
		ui.set_managers_expanded(false)
		ui.set_successors_expanded(true)
		recruit = ui.find_child("RecruitManager_byte_automation", true, false) as Button
		await process_frame
		if recruit != null:
			scroll.ensure_control_visible(recruit)
		await process_frame
		await process_frame
		var successor_image := test_viewport.get_texture().get_image()
		if successor_image != null:
			_check(
				successor_image.save_png(capture_directory.path_join("manager-operations-390x844.png")) == OK,
				"manager successor capture should save",
				failures,
			)
	ui.set_managers_expanded(true)
	ui.set_successors_expanded(false)
	_expand_interface_copy(operations)
	await process_frame
	await process_frame
	var bounds := _effective_scroll_bounds(scroll)
	_check(
		operations != null
		and operations.get_combined_minimum_size().x <= bounds.size.x + 0.5
		and _first_horizontal_overflow(operations, bounds) == "none",
		"150-percent expanded manager operations should remain vertical-only (%s; largest=%s)"
		% [
			_first_horizontal_overflow(operations, bounds),
			_largest_minimum_widths(operations),
		],
		failures,
	)
	_check(
		scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"manager operations should never require horizontal scrolling",
		failures,
	)
	for selector_value: Node in operations.find_children(
		"Assignment_*",
		"OptionButton",
		true,
		false,
	):
		var selector := selector_value as OptionButton
		_check(
			selector != null
			and not selector.fit_to_longest_item
			and _rect_inside(selector.get_global_rect(), bounds),
			"every manager assignment selector should shrink and remain reachable",
			failures,
		)
	for selector_value: Node in operations.find_children(
		"Posture_*",
		"OptionButton",
		true,
		false,
	):
		var selector := selector_value as OptionButton
		_check(
			selector != null
			and not selector.fit_to_longest_item
			and _rect_inside(selector.get_global_rect(), bounds),
			"every manager posture selector should shrink and remain reachable",
			failures,
		)
	ui.set_managers_expanded(false)
	ui.set_successors_expanded(true)
	recruit = ui.find_child(
		"RecruitManager_byte_automation",
		true,
		false,
	) as Button
	await process_frame
	if recruit != null:
		scroll.ensure_control_visible(recruit)
	await process_frame
	await process_frame
	_check(
		recruit != null
		and recruit.is_visible_in_tree()
		and scroll.get_global_rect().intersects(recruit.get_global_rect())
		and _rect_inside(recruit.get_global_rect(), bounds),
		"the scaled successor review action should remain physically reachable (visible=%s scroll=%s recruit=%s bounds=%s)" % [
			recruit.is_visible_in_tree() if recruit != null else false,
			scroll.get_global_rect(),
			recruit.get_global_rect() if recruit != null else Rect2(),
			bounds,
		],
		failures,
	)
	var fund_before := simulation.revenue_cents
	var roster_before := simulation.manager_roster.duplicate(true)
	if recruit != null:
		recruit.pressed.emit()
	await process_frame
	await process_frame
	_check(
		confirmation != null
		and confirmation.visible
		and _contains_all(
			confirmation.dialog_text,
			[
				"BYTE BANTAM",
				"AUTOMATION",
				"REPLACES  /  CLOVER CROWSBY",
				"FEE  /  $70.00",
				"ROOSTERS  /  4 -> 4",
				"PAY",
				"EGGS 0",
				"IRREVERSIBLE",
			],
		),
		"confirmation should disclose identity, doctrine, cost, replacement economics, zero production, and irreversibility (%s)" % [
			confirmation.dialog_text if confirmation != null else "missing",
		],
		failures,
	)
	_check(
		int(observed["count"]) == 0
		and simulation.revenue_cents == fund_before
		and simulation.manager_roster == roster_before,
		"opening succession review must not mutate Feed Fund or the authoritative roster",
		failures,
	)
	if (
		"--capture-max-scale-managers" in OS.get_cmdline_user_args()
		and confirmation != null
	):
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/manager-recruitment-scale-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var authored_confirmation_image := (
			confirmation.get_texture().get_image()
		)
		_check(
			authored_confirmation_image != null,
			"authored succession confirmation should expose a rendered texture",
			failures,
		)
		if authored_confirmation_image != null:
			_check(
				authored_confirmation_image.save_png(
					capture_directory.path_join(
						"manager-recruitment-confirmation-150.png"
					)
				) == OK,
				"authored succession confirmation capture should save",
				failures,
			)
	var safety := ui.interaction_safety_state()
	_check(
		bool(safety.get("manager_recruit_confirmation_visible", false))
		and StringName(String(safety.get("manager_candidate_id", "")))
		== &"byte_automation"
		and int(safety.get("manager_recruit_cost_cents", 0)) == 7000,
		"interaction safety state should expose the held candidate and exact filing cost",
		failures,
	)
	if confirmation != null:
		confirmation.canceled.emit()
	await process_frame
	_check(
		confirmation != null
		and not confirmation.visible
		and int(observed["count"]) == 0
		and simulation.revenue_cents == fund_before
		and simulation.manager_roster == roster_before,
		"canceling succession should preserve the current rooster and every ledger",
		failures,
	)

	recruit = ui.find_child(
		"RecruitManager_byte_automation",
		true,
		false,
	) as Button
	if recruit != null:
		recruit.pressed.emit()
	await process_frame
	await process_frame
	var confirmation_records := _capture_control_records(confirmation)
	_apply_explicit_font_scale(confirmation, 1.5)
	_expand_interface_copy(confirmation)
	await process_frame
	await process_frame
	_check(
		confirmation != null
		and confirmation.visible
		and confirmation.size.x <= 390
		and confirmation.size.y <= 844,
		"150-percent expanded succession confirmation should fit 390x844 (size=%s)"
		% [confirmation.size if confirmation != null else Vector2i.ZERO],
		failures,
	)
	_check(
		confirmation != null
		and _popup_control_fits(
			confirmation,
			confirmation.get_ok_button(),
		)
		and _popup_control_fits(
			confirmation,
			confirmation.get_cancel_button(),
		),
		"max-scale succession should keep both choices physically reachable",
		failures,
	)
	if "--capture-max-scale-managers" in OS.get_cmdline_user_args():
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/manager-recruitment-scale-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var confirmation_image := confirmation.get_texture().get_image()
		_check(
			confirmation_image != null,
			"succession confirmation should expose a rendered texture",
			failures,
		)
		if confirmation_image != null:
			_check(
				confirmation_image.save_png(
					capture_directory.path_join(
						"manager-recruitment-confirmation-expanded-stress.png"
					)
				) == OK,
				"succession confirmation capture should save",
				failures,
			)
	_restore_control_records(confirmation_records)
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	await process_frame
	var result := observed.get("result", {}) as Dictionary
	_check(
		int(observed["count"]) == 1
		and StringName(observed["candidate_id"]) == &"byte_automation"
		and bool(result.get("accepted", false)),
		"one explicit confirmation should file one stable successor intent",
		failures,
	)
	_check(
		simulation.revenue_cents == fund_before - 7000
		and simulation.manager_roster.size() == roster_before.size()
		and StringName(String(
			simulation.manager_roster[
				simulation.manager_roster.size() - 1
			].get("candidate_id", ""),
		)) == &"byte_automation",
		"confirmed succession should charge the disclosed fee and replace, not add, the newest manager",
		failures,
	)
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	_check(
		int(observed["count"]) == 1
		and simulation.revenue_cents == fund_before - 7000,
		"repeated confirmation input must not duplicate the appointment",
		failures,
	)

	test_viewport.queue_free()
	if not failures.is_empty():
		for failure: String in failures:
			push_error(
				"MANAGER_RECRUITMENT_UI_TEST_FAILED: %s" % failure
			)
		quit(1)
		return
	print(
		"MANAGER_RECRUITMENT_UI_TEST_PASSED "
		+ "roster=4 successors=2 390x844=150-percent+expanded-copy "
		+ "succession=cancel+confirm-once payroll=forecast eggs=0",
	)
	quit(0)


func _candidate(
	operations: Dictionary,
	candidate_id: StringName,
) -> Dictionary:
	for value: Variant in operations.get("manager_candidates", []) as Array:
		if (
			value is Dictionary
			and StringName(String((value as Dictionary).get("id", "")))
			== candidate_id
		):
			return value as Dictionary
	return {}


func _contains_all(source: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if needle not in source:
			return false
	return true


func _effective_scroll_bounds(scroll: ScrollContainer) -> Rect2:
	var bounds := scroll.get_global_rect()
	var vertical_bar := scroll.get_v_scroll_bar()
	if vertical_bar != null and vertical_bar.visible:
		bounds.size.x = maxf(0.0, bounds.size.x - vertical_bar.size.x)
	return bounds


func _rect_inside(rect: Rect2, bounds: Rect2) -> bool:
	return (
		rect.position.x >= bounds.position.x - 0.5
		and rect.end.x <= bounds.end.x + 0.5
	)


func _first_horizontal_overflow(
	root_control: Control,
	bounds: Rect2,
) -> String:
	if root_control == null:
		return "missing root"
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children(
		"*",
		"Control",
		true,
		false,
	))
	for node_value: Node in controls:
		var control := node_value as Control
		if (
			control != null
			and control.is_visible_in_tree()
			and not _rect_inside(control.get_global_rect(), bounds)
		):
			return "%s rect=%s min=%s" % [
				control.name,
				control.get_global_rect(),
				control.get_combined_minimum_size(),
			]
	return "none"


func _largest_minimum_widths(root_control: Control) -> String:
	var rows: Array[Dictionary] = []
	if root_control == null:
		return "missing root"
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children(
		"*",
		"Control",
		true,
		false,
	))
	for node_value: Node in controls:
		var control := node_value as Control
		if control != null and control.is_visible_in_tree():
			rows.append({
				"name": control.name,
				"minimum": control.get_combined_minimum_size().x,
				"width": control.size.x,
			})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("minimum", 0.0)) > float(b.get("minimum", 0.0))
	)
	var summaries: Array[String] = []
	for index: int in mini(16, rows.size()):
		var row := rows[index]
		summaries.append("%s:min=%.1f/size=%.1f" % [
			String(row.get("name", "")),
			float(row.get("minimum", 0.0)),
			float(row.get("width", 0.0)),
		])
	return ", ".join(summaries)


func _popup_control_fits(
	popup: Window,
	control: Control,
) -> bool:
	if popup == null or control == null or not control.is_visible_in_tree():
		return false
	return Rect2(
		Vector2.ZERO,
		Vector2(popup.size),
	).encloses(control.get_global_rect())


func _capture_control_records(root_node: Node) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if root_node == null:
		return records
	var controls: Array[Node] = []
	if root_node is Control:
		controls.append(root_node)
	controls.append_array(root_node.find_children(
		"*",
		"Control",
		true,
		false,
	))
	for node_value: Node in controls:
		var control := node_value as Control
		var record := {
			"control": control,
			"had_font_override": control.has_theme_font_size_override(
				"font_size"
			),
			"font_size": control.get_theme_font_size("font_size"),
			"kind": &"",
			"text": "",
			"items": [] as Array[String],
		}
		if control is OptionButton:
			var option := control as OptionButton
			var items: Array[String] = []
			for item_index: int in option.item_count:
				items.append(option.get_item_text(item_index))
			record["kind"] = &"option"
			record["items"] = items
		elif control is Button:
			record["kind"] = &"button"
			record["text"] = (control as Button).text
		elif control is Label:
			record["kind"] = &"label"
			record["text"] = (control as Label).text
		records.append(record)
	return records


func _restore_control_records(records: Array[Dictionary]) -> void:
	for record: Dictionary in records:
		var control := record.get("control") as Control
		if control == null or not is_instance_valid(control):
			continue
		match StringName(record.get("kind", &"")):
			&"option":
				var option := control as OptionButton
				var items := record.get("items", []) as Array
				for item_index: int in mini(
					option.item_count,
					items.size(),
				):
					option.set_item_text(
						item_index,
						String(items[item_index]),
					)
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
		if node_value is OptionButton:
			var option := node_value as OptionButton
			for item_index: int in option.item_count:
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


func _check(
	condition: bool,
	message: String,
	failures: Array[String],
) -> void:
	if not condition:
		failures.append(message)
