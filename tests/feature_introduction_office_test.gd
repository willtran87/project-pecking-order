extends SceneTree

## The live Office applies the probation feature schedule at its chokepoints:
## PLAN, the Career Workshop, Flock Ties, Feed Party / overtime and the later
## Flockwatch pages stay out of shift 1, arrive on their scheduled shift, and
## are all present when the schedule is switched off.


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	(office.get("_campaign_ui") as ProbationCampaignUI).show_title(false)
	(office.find_child("NewCampaignButton", true, false) as Button).pressed.emit()
	await process_frame
	await process_frame
	(office.find_child("FirstClutchReturnToHen", true, false) as Button).pressed.emit()
	await process_frame
	office.call("_select_decision_option_by_index", 2)
	office.call("_on_decision_confirm_pressed")
	await process_frame
	var dialogue := office.get("_character_dialogue_ui") as CharacterDialogueUI
	while dialogue.is_blocking():
		dialogue.dismiss_current()
		await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	office.call("_apply_snapshot_presentation", simulation.snapshot())
	await process_frame

	_check(simulation.day == 1, "fixture should be on probation shift 1", failures)
	_check(not bool(office.call("_feature_introduced", &"plan_menu")), "PLAN is not introduced on shift 1", failures)
	_check(
		not (office.get("_active_playbook_button") as Control).visible,
		"the PLAN button stays hidden on shift 1",
		failures,
	)
	_check(
		not bool(office.call("_open_shift_challenge_choices", "workshop")),
		"the Career Workshop cannot open on shift 1",
		failures,
	)
	office.call("_open_flock_ties")
	_check(office.get("_flock_ties_ui") == null, "Flock Ties cannot open on shift 1", failures)
	_check(
		not (office.get("_feed_button") as Control).visible
		and not (office.get("_overtime_button") as Control).visible,
		"Feed Party and overtime controls stay hidden on shift 1",
		failures,
	)
	var hidden_pages := office.call("_scheduled_flockwatch_hidden_pages") as Array
	_check(
		FlockwatchNavigation.PAGE_CAPITAL in hidden_pages
		and FlockwatchNavigation.PAGE_OPERATIONS in hidden_pages,
		"Capital and Operations pages are scheduled for later shifts",
		failures,
	)

	# Shift 2: PLAN with only the introductory playbook kinds.
	simulation.day = 2
	var pulse := office.get("_pulse_presenter") as OfficePulsePresenter
	var mixed: Array = [
		{"kind": "preset"}, {"kind": "intervention"}, {"kind": "rival"},
		{"kind": "side_goal"}, {"kind": "contract"}, {"kind": "reward"},
	]
	var shift_two_kinds: Array[String] = []
	for option: Dictionary in pulse._scheduled_playbook_options(mixed):
		shift_two_kinds.append(String(option["kind"]))
	_check(
		bool(office.call("_feature_introduced", &"plan_menu"))
		and shift_two_kinds == ["preset", "intervention", "reward"],
		"shift 2 offers PLAN with guided plans and the intervention only: %s" % [shift_two_kinds],
		failures,
	)
	_check(
		not bool(office.call("_feature_introduced", &"career_workshop")),
		"the Career Workshop waits for shift 3",
		failures,
	)

	# Shift 3: the wider playbook joins.
	simulation.day = 3
	_check(
		pulse._scheduled_playbook_options(mixed).size() == mixed.size()
		and bool(office.call("_feature_introduced", &"flock_ties"))
		and (office.call("_scheduled_flockwatch_hidden_pages") as Array).is_empty(),
		"shift 3 introduces the remaining optional layers",
		failures,
	)

	# Opting out shows everything on shift 1.
	simulation.day = 1
	office.progressive_feature_introduction = false
	_check(
		bool(office.call("_feature_introduced", &"career_workshop"))
		and (office.call("_scheduled_flockwatch_hidden_pages") as Array).is_empty(),
		"switching the schedule off restores every layer immediately",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("FEATURE_INTRODUCTION_OFFICE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FEATURE_INTRODUCTION_OFFICE_TEST_PASSED")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
