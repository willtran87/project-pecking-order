extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "career_sponsorship_integration_test.json"
const SPONSORSHIP_COST_CENTS := 1200
const ALREADY_FILED_REASON := "This quarter's career sponsorship has already been filed. Bank remaining marks for the next quarter."


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()

	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame
	(office.get("_clock") as SimulationClock).set_speed(0)

	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var senior := _perfect_quarter_senior(failures)
	office.set("_campaign_state", _passing_campaign(failures))
	office.set("_senior_roost_state", senior)
	office.set("_campaign_senior_roost", true)
	office.set("_last_workday_report", _senior_report(8, 3))

	# A valid Office save retains the required employed flock. Only Mabel is an
	# Accredited Layer, so the report has exactly one eligible sponsorship row.
	for worker in simulation.workers:
		worker.career_xp = 0
		worker.secondary_specialty = &""
		worker.cross_training_target = &""
		worker.cross_training_worked_this_shift = false
	var selected_worker := simulation.workers[0]
	selected_worker.career_xp = 18
	simulation.day = 9
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = (
		simulation.current_daily_operating_cost_cents()
		+ simulation.wage_arrears_cents
		+ 5000
	)
	var fund_before := simulation.revenue_cents
	var wage_before := selected_worker.daily_wage_cents()

	office.call("_show_senior_roost_report", "career_sponsorship_integration_setup")
	await process_frame
	await process_frame

	var sponsorship_ui := office.find_child("CareerSponsorshipUI", true, false) as CareerSponsorshipUI
	var authorize_button := office.find_child("CareerSponsorshipAuthorizeButton", true, false) as Button
	var open_presentation := office.call("_career_sponsorship_presentation_snapshot") as Dictionary
	_check(
		campaign_ui.modal_state() == ProbationCampaignUI.VIEW_REPORT,
		"the authentic closed-quarter Senior report should be open",
		failures,
	)
	_check(
		sponsorship_ui != null and sponsorship_ui.is_visible_in_tree(),
		"the Senior report should embed a visible career sponsorship component",
		failures,
	)
	_check(
		(open_presentation.get("eligible_workers", []) as Array).size() == 1,
		"exactly one employed Accredited Layer should be eligible",
		failures,
	)
	_check(
		authorize_button != null and authorize_button.is_visible_in_tree() and not authorize_button.disabled,
		"the real AUTHORIZE SPONSORSHIP button should be actionable",
		failures,
	)
	_check(
		sponsorship_ui != null and sponsorship_ui.authorization_reason().is_empty(),
		"the embedded component should expose no presentation-side hold before authorization",
		failures,
	)

	var selected_worker_id := sponsorship_ui.selected_worker_id()
	var selected_lane := sponsorship_ui.selected_lane_id()
	_check(selected_worker_id == selected_worker.id, "the report should select the sole eligible hen", failures)
	_check(
		selected_lane != &"" and selected_lane != selected_worker.specialty,
		"the report should select a genuine alternate claim lane",
		failures,
	)

	# Exercise the player-facing signal path rather than either authoritative API.
	authorize_button.pressed.emit()
	await process_frame
	await process_frame

	senior = office.get("_senior_roost_state") as SeniorRoostState
	selected_worker = simulation.workers[selected_worker_id]
	_check(senior.roost_marks == 3, "sponsorship must preserve exactly three lifetime Roost Marks", failures)
	_check(
		senior.roost_marks_spent == 3 and senior.available_roost_marks() == 0,
		"sponsorship should move the exact mark balance from 0 spent / 3 available to 3 spent / 0 available",
		failures,
	)
	_check(
		senior.sponsorship_history.size() == 1,
		"the Senior ledger should contain exactly one sponsorship receipt",
		failures,
	)
	_check(
		simulation.revenue_cents == fund_before - SPONSORSHIP_COST_CENTS,
		"the protected Feed Fund should be charged exactly $12.00 once",
		failures,
	)
	_check(
		selected_worker.cross_training_target == selected_lane,
		"the selected hen should retain the authorized lane as pending training",
		failures,
	)
	_check(
		selected_worker.secondary_specialty == &"" and not selected_worker.cross_training_worked_this_shift,
		"authorization must not grant the permanent secondary lane before a worked training shift",
		failures,
	)
	_check(
		selected_worker.daily_wage_cents() == wage_before
		and selected_worker.cross_training_wage_bonus_cents() == 0,
		"authorization must not grant the permanent wage bonus early",
		failures,
	)

	var filed_presentation := office.call("_career_sponsorship_presentation_snapshot") as Dictionary
	_check(
		sponsorship_ui.is_visible_in_tree()
		and authorize_button.disabled
		and sponsorship_ui.authorization_reason() == ALREADY_FILED_REASON,
		"the filed sponsorship board should remain visible and held as already filed",
		failures,
	)
	_check(
		bool(filed_presentation.get("visible", false))
		and String(filed_presentation.get("unavailable_reason", "")) == ALREADY_FILED_REASON,
		"the authoritative report snapshot should retain the already-filed gate",
		failures,
	)

	var checkpoint := store.load()
	var checkpoint_payload := checkpoint.get("campaign", {}) as Dictionary
	var checkpoint_senior_data := checkpoint_payload.get("senior_roost", {}) as Dictionary
	var checkpoint_simulation_data := checkpoint_payload.get("simulation", {}) as Dictionary
	var checkpoint_worker := _saved_worker(checkpoint_simulation_data, selected_worker_id)
	var checkpoint_history := checkpoint_senior_data.get("sponsorship_history", []) as Array
	var checkpoint_metadata := checkpoint.get("metadata", {}) as Dictionary
	var checkpoint_revision := int(checkpoint_metadata.get("save_revision", -1))
	_check(
		String(checkpoint_metadata.get("reason", "")) == "career_sponsorship_authorized",
		"the real authorization should write its dedicated campaign checkpoint",
		failures,
	)
	_check(
		int(checkpoint_senior_data.get("roost_marks", -1)) == 3
		and int(checkpoint_senior_data.get("roost_marks_spent", -1)) == 3
		and checkpoint_history.size() == 1,
		"the checkpoint should contain the exact Senior mark and sponsorship ledger",
		failures,
	)
	_check(
		int(checkpoint_simulation_data.get("revenue_cents", -1)) == fund_before - SPONSORSHIP_COST_CENTS
		and StringName(String(checkpoint_worker.get("cross_training_target", ""))) == selected_lane
		and StringName(String(checkpoint_worker.get("secondary_specialty", ""))) == &"",
		"the same checkpoint should contain the charged economy and pending training ledger",
		failures,
	)

	# Even a synthetic press emission on the now-disabled real button must be held
	# by the embedded component and leave both ledgers and the checkpoint untouched.
	authorize_button.pressed.emit()
	await process_frame
	_check(
		simulation.revenue_cents == fund_before - SPONSORSHIP_COST_CENTS
		and senior.roost_marks_spent == 3
		and senior.sponsorship_history.size() == 1,
		"the already-filed report must not charge or spend a second time",
		failures,
	)
	_check(
		int((store.load().get("metadata", {}) as Dictionary).get("save_revision", -1)) == checkpoint_revision,
		"a held repeat press should not rewrite the authorization checkpoint",
		failures,
	)

	office.free()
	await process_frame

	var restored_office := Office.new()
	restored_office.set("_campaign_store", store)
	restored_office.set("_allow_automated_campaign_saves", true)
	root.add_child(restored_office)
	await process_frame
	await process_frame
	(restored_office.get("_clock") as SimulationClock).set_speed(0)
	restored_office.call("_load_campaign_checkpoint")
	await process_frame
	await process_frame

	var restored_simulation := restored_office.get("_simulation") as DepartmentSimulation
	var restored_senior := restored_office.get("_senior_roost_state") as SeniorRoostState
	var restored_campaign_ui := restored_office.get("_campaign_ui") as ProbationCampaignUI
	var restored_worker := restored_simulation.workers[selected_worker_id]
	var restored_sponsorship_ui := restored_office.find_child("CareerSponsorshipUI", true, false) as CareerSponsorshipUI
	var restored_authorize_button := restored_office.find_child("CareerSponsorshipAuthorizeButton", true, false) as Button
	var restored_presentation := restored_office.call("_career_sponsorship_presentation_snapshot") as Dictionary
	_check(
		StringName(restored_office.get("_campaign_review_stage")) == &"senior_quarter"
		and restored_campaign_ui.modal_state() == ProbationCampaignUI.VIEW_REPORT,
		"Continue should reopen the same Senior quarterly report gate",
		failures,
	)
	_check(
		restored_presentation == filed_presentation
		and restored_sponsorship_ui.is_visible_in_tree()
		and restored_authorize_button.disabled
		and restored_sponsorship_ui.authorization_reason() == ALREADY_FILED_REASON,
		"Continue should recover the exact visible already-filed sponsorship board",
		failures,
	)
	_check(
		restored_senior.roost_marks == 3
		and restored_senior.roost_marks_spent == 3
		and restored_senior.available_roost_marks() == 0
		and restored_senior.sponsorship_history.size() == 1,
		"Continue should recover the exact lifetime, spent, available, and receipt ledgers",
		failures,
	)
	_check(
		restored_simulation.revenue_cents == fund_before - SPONSORSHIP_COST_CENTS
		and restored_worker.cross_training_target == selected_lane
		and restored_worker.secondary_specialty == &""
		and restored_worker.daily_wage_cents() == wage_before,
		"Continue should recover pending training without another charge or early accreditation",
		failures,
	)

	# Retry the restored real button as a final double-spend regression.
	restored_authorize_button.pressed.emit()
	await process_frame
	_check(
		restored_simulation.revenue_cents == fund_before - SPONSORSHIP_COST_CENTS
		and restored_senior.roost_marks_spent == 3
		and restored_senior.sponsorship_history.size() == 1,
		"the restored already-filed report must remain idempotent",
		failures,
	)
	_check(
		int((store.load().get("metadata", {}) as Dictionary).get("save_revision", -1)) == checkpoint_revision,
		"loading and retrying the filed report must not create a second checkpoint charge",
		failures,
	)

	(restored_office.get("_clock") as SimulationClock).set_speed(0)
	restored_office.free()
	await process_frame
	var cleaned := store.delete()
	_check(cleaned and not store.has_save(), "the isolated integration checkpoint should be cleaned up", failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_SPONSORSHIP_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_SPONSORSHIP_INTEGRATION_TEST_PASSED report=real-button marks=3/3/0 fund=-1200 pending=exact checkpoint=two-ledger restore=idempotent")
	quit(0)


func _perfect_quarter_senior(failures: Array[String]) -> SeniorRoostState:
	var senior := SeniorRoostState.new()
	_check(senior.begin(5), "Senior fixture should begin at the first quarterly policy gate", failures)
	_check(
		senior.record_quarter_policy({
			"accepted": true,
			"policy_id": &"harvest_forecast",
			"style_id": &"management_innovation",
			"outcome": "Quarter policy filed.",
		}),
		"Senior fixture should file an authentic quarterly policy",
		failures,
	)
	for day in [6, 7, 8]:
		var result := senior.record_shift(_senior_report(day, day - 5))
		_check(bool(result.get("accepted", false)), "Senior fixture day %d should file" % day, failures)
	_check(
		senior.status == SeniorRoostState.STATUS_QUARTER_CHOICE
		and senior.completed_quarters == 1
		and int(senior.last_quarter_review.get("score", -1)) == 100
		and senior.roost_marks == 3
		and senior.roost_marks_spent == 0
		and senior.available_roost_marks() == 3,
		"one authentic perfect quarter should reach STATUS_QUARTER_CHOICE with exactly three available marks",
		failures,
	)
	return senior


func _passing_campaign(failures: Array[String]) -> CampaignState:
	var campaign := CampaignState.new()
	var closing_fund := CampaignState.DEFAULT_OPENING_FUND_CENTS
	var rework_total := 0
	for day in range(1, CampaignState.CAMPAIGN_LENGTH + 1):
		if day == 3:
			_check(campaign.choose_milestone(&"shell_quality_lab"), "campaign fixture should file its required milestone", failures)
		var credited := 8500 + day * 100
		closing_fund += credited - 1800
		var result := campaign.record_shift(
			_probation_report(day, rework_total, closing_fund, credited),
			{"welfare": 75, "compliance": 82, "executive_confidence": 70},
		)
		_check(bool(result.get("accepted", false)), "campaign fixture shift %d should file" % day, failures)
	return campaign


func _probation_report(day: int, rework_total: int, closing_fund: int, credited: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 28,
		"quota": 24,
		"met_quota": true,
		"cracked": 1,
		"golden": 0,
		"quota_bonus_cents": 1000,
		"quality_bonus_cents": 500,
		"feed_cost_cents": 1800,
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"rework_total_created": rework_total,
		"closing_fund_cents": closing_fund,
		"credited_cents": credited,
	}


func _senior_report(day: int, rework_total: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 30,
		"quota": 24,
		"met_quota": true,
		"cracked": 2,
		"golden": 0,
		"quota_bonus_cents": 0,
		"quality_bonus_cents": 0,
		"feed_cost_cents": 1800,
		"credited_cents": 12_000,
		"welfare": 72,
		"compliance": 76,
		"farmer_favor": 66,
		"wage_arrears_cents": 0,
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"rework_total_created": rework_total,
		"closing_fund_cents": 20_000 + day * 100,
		"credit_memo_required": false,
		"pecking_order": [],
		"hen_highlight": {},
	}


func _saved_worker(simulation_data: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in simulation_data.get("workers", []):
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
