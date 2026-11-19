extends SceneTree

const Continuity := preload("res://core/experience/shift_continuity.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var report := {"day": 1, "met_quota": false, "rework_due_next_shift": 2}
	var original := report.duplicate(true)
	var bridge := Continuity.compose(report, 2, 18, CampaignState.shift_chapter(2), {}, {})
	_check(bridge["reason"] == "rework" and "2 rework files" in bridge["carry"], "next shift must name actual returning work", failures)
	_check("18 eggs" in bridge["target"] and "SHIFT 2" in bridge["title"], "next target must use the actual upcoming quota and day", failures)
	_check(report == original, "presentation must not modify settled evidence", failures)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(report))
	_check(Continuity.compose(restored, 2, 18, CampaignState.shift_chapter(2), {}, {}) == bridge, "saved/restored reports must reconstruct the same handoff", failures)
	_check(Continuity.compose(report, 4, 20, CampaignState.shift_chapter(4), {}, {})["source_day"] == 0, "old reports must never masquerade as yesterday", failures)
	report["next_flock_compact"] = {"effective_day": 2, "compact_name": "REST PACT", "condition": "Protect care time."}
	_check(Continuity.compose(report, 2, 18, CampaignState.shift_chapter(2), {}, {})["reason"] == "flock_promise", "dated promises must take priority over ordinary carryover", failures)
	report["next_flock_compact"]["effective_day"] = 3
	_check(Continuity.compose(report, 2, 18, CampaignState.shift_chapter(2), {}, {})["reason"] == "rework", "future promises must not appear as already active", failures)
	report.erase("next_flock_compact")
	report["rework_due_next_shift"] = 0
	_check(Continuity.compose(report, 2, 18, CampaignState.shift_chapter(2), {}, {})["reason"] == "recovery", "missed quota must offer a recoverable next step", failures)
	report["next_work_to_rule"] = {"day": 2, "active": true}
	_check(Continuity.compose(report, 2, 18, CampaignState.shift_chapter(2), {}, {})["reason"] == "work_to_rule", "active work-to-rule must explain the upcoming slowdown", failures)
	report.erase("next_work_to_rule")
	_check("SHELL ASSURANCE" in Continuity.compose(report, 2, 18, CampaignState.shift_chapter(2), {"label": "SHELL ASSURANCE"}, {})["carry"], "permanent specialization must retain its real name", failures)
	var goal := {"day": 2, "status": "active"}
	_check(not Continuity.compose(report, 2, 18, CampaignState.shift_chapter(2), {}, goal)["optional"].is_empty(), "accepted personal goals must stay distinct from the quota", failures)

	var office := Office.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var clock := office.get("_clock") as SimulationClock
	clock.set_process(false)
	clock.set_speed(0)
	office.set_process(false)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign := office.get("_campaign_state") as CampaignState
	var closing: Dictionary = office.call("_campaign_capture_report", 1)
	closing["rework_due_next_shift"] = 2
	campaign.record_shift(closing, {})
	office.set("_last_workday_report", closing)
	simulation.day = 2
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision = {}
	var snapshot: Dictionary = office.call("_campaign_presentation_snapshot", &"between_shift")
	var ui := office.get("_campaign_ui") as ProbationCampaignUI
	ui.show_between_shift_report(snapshot)
	var body := ui.get("_objective_body_label") as Label
	_check(body.visible and "2 rework files" in body.text, "carryover must remain visible beside scored orders", failures)
	var expected: Dictionary = office.get("_shift_continuity")
	var saved := simulation.export_save_state()
	office.call("_begin_next_shift_from_campaign")
	var morning: Dictionary = office.get("_shift_continuity")
	_check(morning == expected, "the campaign review and following morning must tell the same story", failures)
	_check(simulation.day == 2 and clock.speed_index == 0, "planning must neither skip a day nor start work", failures)
	_check("PLAN SHIFT 2" == (office.get("_decision_title") as Label).text, "morning must name the shift being planned", failures)
	_check("2 rework files" in (office.get("_decision_body") as Label).text, "morning must carry forward yesterday's concrete consequence", failures)
	_check(simulation.revenue_cents == int(saved.get("revenue_cents", simulation.revenue_cents)), "the handoff must not spend or award currency", failures)
	_check(not office.call("_review_has_pending_credit"), "cleared credit must not be shown as the next step", failures)
	# Credit remains a mandatory gate; the clearer label must not skip it.
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision = {"kind": &"credit_allocation", "id": &"closing_credit_memo", "options": []}
	_check(office.call("_review_has_pending_credit"), "unresolved credit must be the named next step", failures)
	office.call("_begin_next_shift_from_campaign")
	_check(StringName(simulation.pending_decision.get("kind")) == &"credit_allocation" and simulation.day == 2, "closing-credit authority must remain ahead of the next briefing", failures)
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("SHIFT_CONTINUITY_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
