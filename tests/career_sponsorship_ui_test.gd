extends SceneTree

const CareerSponsorshipUIScript := preload("res://features/office/career_sponsorship_ui.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var observed := {"count": 0, "worker_id": -1, "lane_id": &""}
	var test_viewport := SubViewport.new()
	test_viewport.name = "CareerSponsorshipTestViewport"
	test_viewport.size = Vector2i(390, 844)
	test_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(test_viewport)
	var harness := Control.new()
	harness.name = "CareerSponsorshipUITestHarness"
	harness.size = Vector2(390.0, 844.0)
	test_viewport.add_child(harness)

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
	var marks_glance := ui.find_child("CareerSponsorshipMarksGlance", true, false) as Label
	var fund_glance := ui.find_child("CareerSponsorshipFundGlance", true, false) as Label
	var training_glance := ui.find_child("CareerSponsorshipTrainingGlance", true, false) as Label
	var wage_glance := ui.find_child("CareerSponsorshipWageGlance", true, false) as Label
	var worker_selector := ui.find_child("CareerSponsorshipHenSelector", true, false) as OptionButton
	var worker_detail := ui.find_child("CareerSponsorshipWorkerDetail", true, false) as Label
	var lane_selector := ui.find_child("CareerSponsorshipLaneSelector", true, false) as OptionButton
	var terms := ui.find_child("CareerSponsorshipTerms", true, false) as Label
	var reason_label := ui.find_child("CareerSponsorshipUnavailableReason", true, false) as Label
	var authorize := ui.find_child("CareerSponsorshipAuthorizeButton", true, false) as Button
	var confirmation := ui.find_child(
		"CareerSponsorshipConfirmation",
		true,
		false,
	) as ConfirmationDialog

	_check(ui.visible, "visible Senior report snapshots should reveal the sponsorship section", failures)
	_check(heading != null and heading.text == "CAREER SPONSORSHIP", "section should use its authored report heading", failures)
	_check(optional_note != null and "OPTIONAL" in optional_note.text and "Bank every Roost Mark" in optional_note.text, "copy should make banking marks explicitly valid", failures)
	_check(balance != null and "AVAILABLE  5 ROOST MARKS" in balance.text and "3 MARKS + $12.00" in balance.text, "balance should disclose both exact immediate costs", failures)
	_check(balance != null and not balance.visible, "exact balance prose should remain semantic detail instead of default presentation", failures)
	_check(marks_glance != null and marks_glance.text == "MARKS\n3 / 5", "sponsorship should compare required and available marks at a glance", failures)
	_check(fund_glance != null and fund_glance.text == "FUND\n$12", "sponsorship should show its immediate Feed Fund cost without prose", failures)
	_check(training_glance != null and training_glance.text == "TRAIN\n-15%", "sponsorship should show the next-shift training penalty without prose", failures)
	_check(wage_glance != null and wage_glance.text == "WAGE\n+$1/D", "sponsorship should show the permanent daily wage without prose", failures)
	_check(worker_selector != null and worker_selector.item_count == 2, "valid unique hens should populate the selector", failures)
	_check(worker_selector != null and worker_selector.focus_mode == Control.FOCUS_ALL, "hen selector should accept keyboard focus", failures)
	_check(lane_selector != null and lane_selector.focus_mode == Control.FOCUS_ALL, "lane selector should accept keyboard focus", failures)
	_check(authorize != null and authorize.focus_mode == Control.FOCUS_ALL, "authorize action should accept keyboard focus", failures)
	_check(confirmation != null, "career sponsorship should build one explicit confirmation dialog", failures)
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
	_check(terms != null and not terms.visible, "exact sponsorship term prose should remain hidden until contextual inspection", failures)
	_check(
		fund_glance != null
		and "3 Roost Marks + $12.00" in fund_glance.tooltip_text
		and "Specialist affinity: NEST DAMAGE" in String(fund_glance.get_meta("accessible_text", "")),
		"glance tiles should retain the complete cost and post-training outcome for hover and assistive reading",
		failures,
	)
	_check(reason_label != null and not reason_label.visible, "available sponsorship should not show a held reason", failures)
	_check(authorize != null and not authorize.disabled, "valid affordable sponsorship should be authorizable", failures)

	# Training Roost terms are authoritative presentation data. A stronger tier
	# must update cost, throughput, coaching, and wage copy without changing the
	# component's intent-only behavior.
	var tiered := _available_snapshot()
	tiered["training_terms"] = {
		"base_sponsorship_cost_cents": 1200,
		"effective_sponsorship_cost_cents": 800,
		"sponsorship_discount_cents": 400,
		"effective_work_multiplier": 0.95,
		"work_penalty_percent": 5,
		"coaching_xp_bonus": 4,
		"wage_bonus_cents": 100,
	}
	ui.apply_snapshot(tiered)
	await process_frame
	_check(balance != null and "3 MARKS + $8.00" in balance.text, "Training Roost should replace the legacy sponsorship charge with its effective cost", failures)
	_check(terms != null and "Saves $4.00" in terms.text, "the sponsorship file should disclose the exact Training Roost saving", failures)
	_check(terms != null and "-5% training throughput" in terms.text, "the terms should use authoritative tier throughput instead of the baseline 15 percent", failures)
	_check(terms != null and "+4 career XP" in terms.text, "the terms should disclose authoritative Training Roost coaching value", failures)
	_check(terms != null and "+$1.00/day wage" in terms.text, "the permanent accreditation wage should remain visible under tiered terms", failures)
	_check(fund_glance != null and fund_glance.text == "FUND\n$8 / SAVE $4", "tiered sponsorship should combine effective cost and saving in one tile", failures)
	_check(training_glance != null and training_glance.text == "TRAIN\n-5% / +4XP", "tiered sponsorship should combine pace and coaching in one tile", failures)
	_check(wage_glance != null and wage_glance.text == "WAGE\n+$1/D", "tiered sponsorship should keep the permanent wage liability glanceable", failures)
	_check(authorize != null and "$8.00 now" in authorize.tooltip_text and "5% below standard" in authorize.tooltip_text, "keyboard focus should expose the same effective tier economics", failures)
	ui.apply_snapshot(_available_snapshot())
	await process_frame

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
	await process_frame
	_check(
		confirmation != null
		and confirmation.visible
		and "PIP WITH A DELIBERATELY LONG CORPORATE CAREER FILE" in confirmation.dialog_text
		and "APPEALS" in confirmation.dialog_text
		and "3 ROOST MARKS + $12.00 FEED FUND" in confirmation.dialog_text
		and "-15% TRAINING THROUGHPUT" in confirmation.dialog_text
		and "+$1.00/DAY WAGE" in confirmation.dialog_text
		and "cannot be undone" in confirmation.dialog_text,
		"confirmation should disclose identity, specialty, immediate cost, training penalty, wage liability, and irreversibility",
		failures,
	)
	_check(int(observed["count"]) == 0, "opening confirmation should not emit an authorization intent", failures)
	if confirmation != null:
		confirmation.canceled.emit()
	await process_frame
	_check(
		confirmation != null and not confirmation.visible and int(observed["count"]) == 0,
		"canceling sponsorship should close the dialog without spending anything",
		failures,
	)
	if authorize != null:
		authorize.pressed.emit()
	await process_frame
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	_check(int(observed["count"]) == 1, "confirmed authorization should emit one intent", failures)
	_check(int(observed["worker_id"]) == 8 and StringName(observed["lane_id"]) == &"appeals", "intent should carry stable worker and lane domain ids", failures)
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	_check(int(observed["count"]) == 1, "duplicate confirmation input must not emit a second intent", failures)

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
	_check(
		int(observed["count"]) == 1
		and (confirmation == null or not confirmation.visible),
		"disabled authorization must not open or emit even when pressed is signaled directly",
		failures,
	)

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

	var prior_theme: Theme = ui.theme
	var control_records := _capture_control_records(ui)
	ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	_apply_explicit_font_scale(ui, 1.5)
	_expand_interface_copy(ui)
	await process_frame
	await process_frame
	ui_rect = ui.get_global_rect()
	_check(
		ui_rect.position.x >= margin_rect.position.x - 0.5
		and ui_rect.end.x <= margin_rect.end.x + 0.5,
		"150-percent expanded sponsorship should remain inside the 390px report (ui=%s margin=%s largest=%s)"
		% [ui_rect, margin_rect, _largest_minimum_widths(ui)],
		failures,
	)
	_check(
		ui.get_combined_minimum_size().x <= margin_rect.size.x + 0.5,
		"150-percent expanded sponsorship should not force horizontal scrolling",
		failures,
	)
	_check(
		_visible_children_fit_horizontally(ui, ui_rect),
		"every expanded sponsorship control should remain within the component width",
		failures,
	)
	if authorize != null:
		scroll.ensure_control_visible(authorize)
	await process_frame
	await process_frame
	_check(
		authorize != null
		and authorize.is_visible_in_tree()
		and scroll.get_global_rect().intersects(authorize.get_global_rect()),
		"the expanded sponsorship authorization should remain vertically reachable",
		failures,
	)
	if authorize != null:
		authorize.pressed.emit()
	await process_frame
	await process_frame
	if confirmation != null:
		var confirmation_rect := confirmation.get_visible_rect()
		_check(
			confirmation.visible
			and confirmation_rect.size.x <= 390.5
			and confirmation_rect.size.y <= 844.5,
			"150-percent sponsorship confirmation should remain inside 390x844 (rect=%s)"
			% confirmation_rect,
			failures,
		)
		_check(
			confirmation.get_ok_button().is_visible_in_tree()
			and confirmation.get_cancel_button().is_visible_in_tree(),
			"max-scale sponsorship confirmation should retain both confirm and cancel actions",
			failures,
		)
		_check(
			"FILE SPONSORSHIP" in confirmation.get_ok_button().text
			and "KEEP" in confirmation.get_cancel_button().text
			and confirmation.get_ok_button().size.x >= 56.0
			and confirmation.get_cancel_button().size.x >= 56.0,
			"max-scale confirmation actions should remain labeled and usable (ok='%s' %s cancel='%s' %s)"
			% [
				confirmation.get_ok_button().text,
				confirmation.get_ok_button().size,
				confirmation.get_cancel_button().text,
				confirmation.get_cancel_button().size,
			],
			failures,
		)
		if "--capture-max-scale-sponsorship" in OS.get_cmdline_user_args():
			var confirmation_capture_directory := ProjectSettings.globalize_path(
				"res://output/web-game/career-sponsorship-scale-v1"
			)
			DirAccess.make_dir_recursive_absolute(confirmation_capture_directory)
			var confirmation_image := confirmation.get_texture().get_image()
			_check(
				confirmation_image != null,
				"max-scale sponsorship confirmation should expose a rendered viewport",
				failures,
			)
			if confirmation_image != null:
				_check(
					confirmation_image.save_png(
						confirmation_capture_directory.path_join(
							"career-sponsorship-confirmation-window.png"
						)
					) == OK,
					"max-scale sponsorship confirmation capture should save successfully",
					failures,
				)
		confirmation.canceled.emit()
	await process_frame
	if "--capture-max-scale-sponsorship" in OS.get_cmdline_user_args():
		var capture_directory := ProjectSettings.globalize_path(
			"res://output/web-game/career-sponsorship-scale-v1"
		)
		DirAccess.make_dir_recursive_absolute(capture_directory)
		var image := test_viewport.get_texture().get_image()
		_check(image != null, "max-scale sponsorship capture should expose a rendered viewport", failures)
		if image != null:
			_check(
				image.save_png(
					capture_directory.path_join("career-sponsorship-390x844.png")
				) == OK,
				"max-scale sponsorship capture should save successfully",
				failures,
			)
	_restore_control_records(control_records)
	ui.theme = prior_theme
	await process_frame
	await process_frame

	ui.apply_snapshot({"visible": false})
	await process_frame
	_check(not ui.visible, "non-Senior or non-report snapshots should hide the section", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_SPONSORSHIP_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_SPONSORSHIP_UI_TEST_PASSED authored=compact filtering=defensive costs=exact keyboard=accessible reasons=exact confirmation=cancel+confirm-once responsive=390x844+150-percent+expanded-copy signal=typed")
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


func _largest_minimum_widths(root_control: Control) -> String:
	var rows: Array[Dictionary] = []
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
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
	var summary: Array[String] = []
	for index: int in mini(6, rows.size()):
		var row := rows[index]
		summary.append("%s min=%.1f width=%.1f" % [
			String(row.get("name", "")),
			float(row.get("minimum", 0.0)),
			float(row.get("width", 0.0)),
		])
	return "; ".join(summary)


func _capture_control_records(root_control: Control) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null:
			continue
		var record := {
			"control": control,
			"had_font_override": control.has_theme_font_size_override("font_size"),
			"font_size": control.get_theme_font_size("font_size"),
			"kind": &"",
			"text": "",
			"items": [] as Array[String],
		}
		if control is OptionButton:
			var option := control as OptionButton
			var item_texts: Array[String] = []
			for item_index: int in option.item_count:
				item_texts.append(option.get_item_text(item_index))
			record["kind"] = &"option"
			record["items"] = item_texts
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
				var item_texts := record.get("items", []) as Array
				for item_index: int in mini(option.item_count, item_texts.size()):
					option.set_item_text(item_index, String(item_texts[item_index]))
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


func _apply_explicit_font_scale(root_control: Control, scale: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control != null and control.has_theme_font_size_override("font_size"):
			control.add_theme_font_size_override(
				"font_size",
				maxi(10, roundi(control.get_theme_font_size("font_size") * scale)),
			)


func _expand_interface_copy(root_control: Control) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control is OptionButton:
			var option := control as OptionButton
			for item_index: int in option.item_count:
				option.set_item_text(item_index, _expanded(option.get_item_text(item_index)))
		elif control is Button:
			var button := control as Button
			if not button.text.is_empty():
				button.text = _expanded(button.text)
		elif control is Label:
			var label := control as Label
			if not label.text.is_empty():
				label.text = _expanded(label.text)


func _expanded(copy: String) -> String:
	return copy.replace("a", "aa").replace("e", "ee").replace(
		"i",
		"ii",
	).replace("o", "oo").replace("u", "uu").replace("A", "AA").replace(
		"E",
		"EE",
	).replace("I", "II").replace("O", "OO").replace("U", "UU")


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
