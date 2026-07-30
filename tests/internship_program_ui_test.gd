extends SceneTree


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

	var received := {"onboard_id": &""}
	ui.onboard_requested.connect(
		func(candidate_id: StringName) -> void: received["onboard_id"] = candidate_id
	)
	var lottie_card := ui.find_child("InternCard_lottie_ledger", true, false) as Control
	var onboard_button := _first_button(lottie_card)
	_check(onboard_button != null and not onboard_button.disabled, "affordable onboarding should be actionable", failures)
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

	if not failures.is_empty():
		for failure in failures:
			push_error("INTERNSHIP_PROGRAM_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTERNSHIP_PROGRAM_UI_TEST_PASSED cast=4 assignments=3 accessible=true")
	quit(0)


func _first_button(node: Node) -> Button:
	if node == null:
		return null
	for child in node.find_children("*", "Button", true, false):
		return child as Button
	return null


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
