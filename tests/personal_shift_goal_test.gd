extends SceneTree

const Goal := preload("res://core/experience/personal_shift_goal.gd")

class MemoryStore:
	extends RefCounted
	var last_error := ""
	var payload: Dictionary = {}
	func has_save() -> bool: return not payload.is_empty()
	func save(value: Dictionary, _metadata: Dictionary) -> bool:
		payload = value.duplicate(true)
		return true

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures: Array[String] = []
	var actual_goal := Goal.offer({"day": 1, "quota": 16, "next_quota": 17, "eggs": 16, "cracked": 2})
	_check(actual_goal.quota == 17, "real workday reports must use next_quota, not a missing quota_target", failures)
	var legacy := actual_goal.duplicate(true)
	legacy.quota = 1
	_check(Goal.reconcile(legacy, 2, 17, {}).quota == 17, "legacy active goals must repair against restored authority", failures)
	_check(Goal.finish(legacy, {"day": 2, "quota": 17, "eggs": 1, "cracked": 0}).status == "missed", "legacy quota=1 must never grant a false success", failures)
	_check(Goal.offer({"day": 1, "quota": 16, "next_quota": 19, "eggs": 16}).target == 19, "output targets must not fall below the next quota", failures)
	_check(Goal.strategy(actual_goal).id == "safe", "review previews must support the actual goal", failures)
	_check(is_equal_approx(SimulationClock.active_frame_seconds(0.06, 0.3), 0.3), "low FPS must not stretch active work time", failures)
	_check(is_equal_approx(SimulationClock.active_frame_seconds(0.06, 30.0), 0.06), "background gaps must not grant offline progress", failures)
	_check(SimulationClock.active_frame_seconds(30.0, 30.0) <= 0.25, "an unclamped resume delta must also remain bounded", failures)
	var report := {"day": 1, "eggs": 12, "quota_target": 10, "cracked": 2, "overdue_claims": 1}
	var goal := Goal.offer(report)
	_check(goal.kind == "shells" and goal.target == 1 and goal.day == 2, "offer must derive a next-shift improvement from actual results", failures)
	_check(Goal.normalize(JSON.parse_string(JSON.stringify(goal))) == goal, "JSON numeric conversion must preserve the goal", failures)
	for malformed in [{}, {"version": 99}, {"version": 1, "day": 2, "target": -1, "quota": 10, "kind": "shells", "status": "active"}, {"version": 1, "day": 2.5, "target": 1, "quota": 10, "kind": "shells", "status": "active"}]:
		_check(Goal.normalize(malformed).is_empty(), "invalid optional goal must be discarded safely", failures)
	_check(Goal.finish(goal, {"day": 1}) == goal, "only the agreed shift may settle the goal", failures)
	_check(Goal.finish(goal, {"day": 2, "eggs": 9, "quota_target": 10, "cracked": 0}).status == "missed", "producing nothing must not win a shell-safety goal", failures)
	var completed := Goal.finish(goal, {"day": 2, "eggs": 10, "quota_target": 10, "cracked": 1})
	_check(completed.status == "complete" and Goal.finish(completed, {"day": 2}) == completed, "goal completion must be factual and idempotent", failures)
	_check(Goal.offer({"day": 2, "quota_target": 10, "overdue_claims": 1}).kind == "files", "late files must offer a relevant alternative", failures)
	_check(Goal.offer({"day": 2, "quota_target": 10, "eggs": 14}).target == 15, "clean successful shifts must offer one more egg", failures)
	_check(Goal.progress(goal, {"eggs_today": 4, "quota_target": 10, "cracked_today": 1}) == "GOAL 4/10 · CRACKS 1/1", "live progress must use simulation facts", failures)
	var office := Office.new()
	var store := MemoryStore.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_on_campaign_new_requested")
	var simulation := office.get("_simulation") as DepartmentSimulation
	var before_cash := simulation.revenue_cents
	office.set("_personal_goal_offer", goal)
	(office.get("_day_review_scrim") as Control).visible = true
	var button := office.find_child("AcceptPersonalGoal", true, false) as Button
	button.pressed.emit()
	_check(office.get("_personal_goal") == goal, "the visible review control must explicitly accept the goal", failures)
	office.call("_write_campaign_checkpoint", "personal_goal_test")
	_check((store.payload.get("session", {}) as Dictionary).get("personal_goal", {}) == goal, "accepted goals must use the real campaign save payload", failures)
	var staged: Dictionary = office.call("_stage_campaign_checkpoint", {"campaign": store.payload})
	_check(bool(staged.get("ok", false)) and staged.get("personal_goal", {}) == goal, "save staging must validate and retain accepted goals", failures)
	button.pressed.emit()
	_check((office.get("_personal_goal") as Dictionary).is_empty(), "accepting again must cancel without an expense", failures)
	if bool(staged.get("ok", false)):
		_check(bool(office.call("_activate_staged_campaign_checkpoint", staged)) and office.get("_personal_goal") == goal, "restoring a career must restore its accepted goal", failures)
	_check(simulation.revenue_cents == before_cash, "personal goals must not create or spend currency", failures)
	_check(String(office.call("_upgrade_effect_comparison", &"nest_cushion", 6)) == "STRAIN REDUCTION 50% > 50%", "comfort previews must respect the simulation cap", failures)
	_check(String(office.call("_upgrade_effect_comparison", &"shell_lamp", 1)) == "RISK REDUCTION 0.0 > 2.5 POINTS", "risk previews must describe probability changes, not guaranteed clean eggs", failures)
	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	_check(feedback.equipment_interaction_root(0) != null, "real desk monitors must be registered as equipment preview targets", failures)
	(office.get("_day_review_scrim") as Control).visible = false
	(office.get("_campaign_ui") as ProbationCampaignUI).show_title(false)
	(office.get("_decision_host") as Control).visible = false
	(office.get("_character_dialogue_ui") as CharacterDialogueUI).clear_session()
	var clutch := office.get("_first_clutch") as Dictionary
	clutch["dismissed"] = true
	clutch["completed"] = true
	office.set("_first_clutch", clutch)
	office.call("_restore_campaign_view")
	(office.get("_decision_host") as Control).visible = false
	(office.get("_character_dialogue_ui") as CharacterDialogueUI).clear_session()
	office.call("_on_work_progress_context_selected", 0, &"equipment")
	_check((office.get("_flockwatch_navigation") as FlockwatchNavigation).current_page_id() == FlockwatchNavigation.PAGE_CAPITAL, "equipment clicks must open the actual capital page (blocking=%s, tracking=%s, page=%s)" % [office.call("_blocking_management_surface_open"), office.call("_first_clutch_tracking_active"), (office.get("_flockwatch_navigation") as FlockwatchNavigation).current_page_id()], failures)
	_check(simulation.revenue_cents == before_cash, "equipment inspection must not buy an upgrade", failures)
	office.call("_set_flockwatch_open", false)
	office.call("_sync_work_progress_interactions")
	var controller := office.get("_camera_controller") as ManagementCameraController
	var camera := controller.get("_camera") as Camera3D
	var monitor := feedback.equipment_interaction_root(0)
	var target: Dictionary = controller.call("_nearest_projected_target", camera.unproject_position(monitor.global_position))
	_check(target.get("context_id", &"") == &"equipment" and int(target.get("worker_id", -1)) == 0, "a projected monitor click must select equipment rather than the hen body", failures)
	office.set("_dispatch_lane", &"appeals")
	controller.call("_select_projected_target", target)
	_check(office.get("_dispatch_lane") == &"appeals" and simulation.revenue_cents == before_cash, "equipment focus must leave a pending route and all money unchanged", failures)
	office.call("_set_flockwatch_open", false)
	var routing := office.get("_routing_ui") as PeckworkRoutingUI
	routing.set_focus(0)
	routing.begin_care_lesson()
	var lesson := routing.get("_care_lesson") as Dictionary
	var later := routing.find_child("CareLessonLater", true, false) as Button
	_check(not lesson.is_empty() and later.visible, "optional care must provide an explicit Later exit", failures)
	_check(simulation.revenue_cents == before_cash, "opening a lesson must not spend money", failures)
	later.pressed.emit()
	_check((routing.get("_care_lesson") as Dictionary).is_empty(), "Later must dismiss the lesson without filing", failures)
	routing.begin_care_lesson()
	routing.complete_care_lesson(0, {"accepted": true, "outcome": "Actual check-in"}, {"name": "Mabel", "manager_trust": 50, "stress": 30}, {"manager_trust": 58, "stress": 25})
	_check(String((routing.get("_care_lesson") as Dictionary).outcome).contains("50 → 58"), "lesson results must use before/after authority", failures)
	_check((office.get("_active_playbook_button") as Button).text.begins_with("PLAN"), "the plan menu must retain a stable name", failures)
	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("PERSONAL_SHIFT_GOAL_TEST_PASSED persistence=optional currency=unchanged progress=authoritative")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
