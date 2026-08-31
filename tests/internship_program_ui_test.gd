extends SceneTree

const ManagementUIThemeScript := preload(
	"res://features/office/management_ui_theme.gd"
)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var program := InternshipProgramState.new()
	var ui := InternshipProgramUI.new()
	root.add_child(ui)
	await process_frame

	ui.apply_snapshot(program.snapshot(2, 2000, true, 1))
	ui.set_expanded(true)
	await process_frame
	var diagnostic := ui.diagnostic_state()
	_check(bool(diagnostic.get("unlocked", false)), "Day 2 cohort should be unlocked", failures)
	_check(int(diagnostic.get("candidate_count", 0)) == 4, "UI should present all four interns", failures)
	_check(bool(diagnostic.get("expanded", false)), "cohort cards should expand", failures)
	_check(
		ui.find_child("InternCard_lottie_ledger", true, false) != null,
		"Lottie should have a candidate card",
		failures,
	)
	var lottie_portrait := ui.find_child("InternPortrait_lottie_ledger", true, false) as TextureRect
	_check(
		lottie_portrait != null and lottie_portrait.texture != null,
		"candidate cards should introduce the cast with their approved art",
		failures,
	)
	_check(
		"BRIGHT-EYED ROTATION" in String(diagnostic.get("accessible_text", "")),
		"internship system should expose an accessible summary",
		failures,
	)
	_check(
		"junior payroll" in String(diagnostic.get("accessible_text", "")).to_lower(),
		"accessible cohort summary should disclose continuing fellowship payroll",
		failures,
	)
	_check(
		"Reads additional responsibility as recognition" in String(diagnostic.get("accessible_text", "")),
		"concise cards should preserve Lottie's full nonvisual profile",
		failures,
	)

	var received := {
		"onboard_id": &"",
		"assignment_candidate_id": &"",
		"assignment_id": &"",
		"review_candidate_id": &"",
		"review_id": &"",
	}
	ui.onboard_requested.connect(
		func(candidate_id: StringName) -> void: received["onboard_id"] = candidate_id
	)
	ui.assignment_requested.connect(
		func(candidate_id: StringName, assignment_id: StringName) -> void:
			received["assignment_candidate_id"] = candidate_id
			received["assignment_id"] = assignment_id
	)
	ui.review_requested.connect(
		func(candidate_id: StringName, review_id: StringName) -> void:
			received["review_candidate_id"] = candidate_id
			received["review_id"] = review_id
	)
	var lottie_card := ui.find_child("InternCard_lottie_ledger", true, false) as Control
	var onboard_button := _first_button(lottie_card)
	_check(onboard_button != null and not onboard_button.disabled, "affordable onboarding should be actionable", failures)
	_check(
		onboard_button != null and onboard_button.text == "ONBOARD  /  $3",
		"candidate action should lead with a concise verb and live cost",
		failures,
	)
	_check(
		onboard_button != null
		and "three-shift" in onboard_button.tooltip_text
		and "+1 live-file capacity" in onboard_button.tooltip_text
		and "no shell-risk change" in onboard_button.tooltip_text,
		"candidate tooltip should retain exact term and default production effects",
		failures,
	)
	var lottie_status := _label_with_text(lottie_card, "AVAILABLE  /  $3  /  3 SHIFTS")
	_check(
		lottie_status != null,
		"candidate card should expose cost and term as glanceable tokens",
		failures,
	)
	if onboard_button != null:
		onboard_button.pressed.emit()
	_check(
		StringName(received.get("onboard_id", &"")) == &"lottie_ledger",
		"onboard action should identify Lottie",
		failures,
	)

	program.onboard(&"lottie_ledger", 2, 2000, true, 1)
	ui.apply_snapshot(program.snapshot(2, 1700, true, 1))
	await process_frame
	await process_frame
	var assignment := ui.find_child("InternAssignment_lottie_ledger", true, false) as OptionButton
	_check(assignment != null and assignment.item_count == 3, "active intern should expose three assignments", failures)
	_check(
		assignment != null
		and assignment.get_item_text(0) == "GUIDED  /  +1 FILE  /  SAFE"
		and assignment.get_item_text(1) == "STRETCH  /  +2 FILES  /  +1% RISK"
		and assignment.get_item_text(2) == "CULTURE  /  -10% MORALE DRAIN",
		"assignment selector should compare exact operational stakes without prose",
		failures,
	)
	_check(
		assignment != null
		and "Learn the full file lifecycle" in assignment.get_item_tooltip(0)
		and "No shell-risk change" in assignment.get_item_tooltip(0),
		"assignment tooltips should retain full promise and disclosure",
		failures,
	)
	if assignment != null:
		assignment.item_selected.emit(1)
	_check(
		StringName(received.get("assignment_candidate_id", &"")) == &"lottie_ledger"
		and StringName(received.get("assignment_id", &"")) == &"stretch_project",
		"concise Stretch option should preserve the exact assignment intent",
		failures,
	)

	program.complete_shift(2)
	program.complete_shift(3)
	program.complete_shift(4)
	ui.apply_snapshot(program.snapshot(5, 1700, true, 1))
	await process_frame
	await process_frame
	lottie_card = ui.find_child("InternCard_lottie_ledger", true, false) as Control
	_check(
		_label_with_text(lottie_card, "REVIEW DUE") != null,
		"completed term should collapse its status to a clear review cue",
		failures,
	)
	var extend_button := _button_with_text(lottie_card, "EXTEND\n$1")
	var recommend_button := _button_with_text(lottie_card, "LETTER\nFREE")
	var fellowship_button := _button_with_text(
		lottie_card,
		"HIRE\n$8+$2/D",
	)
	_check(
		extend_button != null and recommend_button != null and fellowship_button != null,
		"term review should compare three concise actions with live costs",
		failures,
	)
	var review_grid := ui.find_child(
		"InternReviewChoices_lottie_ledger",
		true,
		false,
	) as GridContainer
	_check(
		review_grid != null and review_grid.columns == 3,
		"term outcomes should remain visible as one three-way comparison",
		failures,
	)
	_check(
		fellowship_button != null
		and "continuing junior post" in fellowship_button.tooltip_text
		and "$2.00/day in junior payroll" in fellowship_button.tooltip_text,
		"fellowship tooltip should preserve its permanent benefit and recurring cost",
		failures,
	)
	if fellowship_button != null:
		fellowship_button.pressed.emit()
	_check(
		StringName(received.get("review_candidate_id", &"")) == &"lottie_ledger"
		and StringName(received.get("review_id", &"")) == &"paid_fellowship",
		"concise Hire action should preserve the exact paid-fellowship intent",
		failures,
	)
	diagnostic = ui.diagnostic_state()
	_check(
		"OFFER A PAID FELLOWSHIP" in String(diagnostic.get("accessible_text", ""))
		and "$8.00 to file" in String(diagnostic.get("accessible_text", "")),
		"assistive review should retain full action names and exact economics",
		failures,
	)

	var scaled_host := Control.new()
	scaled_host.size = Vector2(360.0, 844.0)
	root.add_child(scaled_host)
	var scaled_scroll := ScrollContainer.new()
	scaled_scroll.size = scaled_host.size
	scaled_host.add_child(scaled_scroll)
	var scaled_ui := InternshipProgramUI.new()
	scaled_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scaled_ui.theme = ManagementUIThemeScript.create_theme(false, 1.5)
	scaled_scroll.add_child(scaled_ui)
	await process_frame
	scaled_ui.apply_snapshot(program.snapshot(5, 1700, true, 1))
	scaled_ui.set_expanded(true)
	_apply_explicit_font_scale(scaled_ui, 1.5)
	await process_frame
	await process_frame
	var scaled_review_grid := scaled_ui.find_child(
		"InternReviewChoices_lottie_ledger",
		true,
		false,
	) as GridContainer
	_check(
		scaled_ui.get_combined_minimum_size().x <= scaled_scroll.size.x + 0.5,
		"150-percent intern roster should remain horizontally scroll-free at 360px (minimum %.1f)"
		% scaled_ui.get_combined_minimum_size().x,
		failures,
	)
	_check(
		scaled_review_grid != null
		and scaled_review_grid.get_combined_minimum_size().x <= scaled_scroll.size.x + 0.5,
		"150-percent review comparison should keep all three outcomes in the roster width (minimum %.1f)"
		% (scaled_review_grid.get_combined_minimum_size().x if scaled_review_grid != null else -1.0),
		failures,
	)

	var filed_fellow := program.resolve_review(
		&"lottie_ledger",
		&"paid_fellowship",
		5,
		1700,
		true,
	)
	var onboard_chip := program.onboard(&"chip_chirper", 5, 900, true, 1)
	_check(
		bool(filed_fellow.get("accepted", false))
		and bool(onboard_chip.get("accepted", false)),
		"held-review fixture should file one fellow and onboard the next intern",
		failures,
	)
	program.complete_shift(5)
	program.complete_shift(6)
	program.complete_shift(7)
	var held_snapshot := program.snapshot(8, 1700, true, 1)
	ui.apply_snapshot(held_snapshot)
	await process_frame
	await process_frame
	var held_hire := _button_with_text(ui, "HIRE\n$8+$2/D")
	_check(
		held_hire != null
		and held_hire.disabled
		and "perch is already occupied" in held_hire.tooltip_text,
		"disabled hire action should explain the exact recovery condition (button=%s disabled=%s tooltip=%s)"
		% [held_hire != null, held_hire.disabled if held_hire != null else false, held_hire.tooltip_text if held_hire != null else "missing"],
		failures,
	)
	diagnostic = ui.diagnostic_state()
	_check(
		"HELD: The single paid fellowship perch is already occupied" in String(
			diagnostic.get("accessible_text", "")
		),
		"assistive review should expose the disabled hire reason",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("INTERNSHIP_PROGRAM_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTERNSHIP_PROGRAM_UI_TEST_PASSED cast=4 assignments=3 review=3-wide accessible=true scale=150-percent")
	quit(0)


func _first_button(node: Node) -> Button:
	if node == null:
		return null
	for child in node.find_children("*", "Button", true, false):
		return child as Button
	return null


func _label_with_text(node: Node, expected: String) -> Label:
	if node == null:
		return null
	for child in node.find_children("*", "Label", true, false):
		var label := child as Label
		if label != null and label.text == expected:
			return label
	return null


func _button_with_text(node: Node, expected: String) -> Button:
	if node == null:
		return null
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		if button != null and button.text == expected:
			return button
	return null


func _apply_explicit_font_scale(root_control: Control, scale: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.has_theme_font_size_override("font_size"):
			continue
		var base_size := control.get_theme_font_size("font_size")
		control.add_theme_font_size_override(
			"font_size",
			maxi(10, roundi(float(base_size) * scale)),
		)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
