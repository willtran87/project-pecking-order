extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const SAVE_FILENAME := "first_clutch_keyboard_guidance_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(SAVE_FILENAME)
	store.delete()
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	campaign_ui.show_title(false)
	await process_frame
	_press(office.find_child("NewCampaignButton", true, false) as Button, "New Career", failures)
	await process_frame
	await process_frame
	_press(office.find_child("FirstClutchReturnToHen", true, false) as Button, "Open Mabel's File", failures)
	await process_frame
	await process_frame
	office.call("_select_decision_option_by_index", 2)
	office.call("_on_decision_confirm_pressed")
	await process_frame
	await process_frame

	var snapshot := office.first_clutch_snapshot()
	_check(StringName(snapshot.get("stage", &"")) == &"specialty_route", "policy filing should reach the guided specialty step", failures)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var diagnostic := office.call("_first_clutch_coach_snapshot", simulation.snapshot()) as Dictionary
	_check("Press Enter" in String(diagnostic.get("guidance", "")), "specialty guidance should disclose the contextual Enter action", failures)
	_check(bool(office.call("_handle_first_clutch_primary_action")), "Enter action should activate the highlighted specialty route", failures)
	await process_frame
	snapshot = office.first_clutch_snapshot()
	_check(bool(snapshot.get("specialty_routed", false)), "contextual route should file Mabel's real specialty", failures)
	_check(StringName(snapshot.get("stage", &"")) == &"check_in", "contextual route should advance to the personnel check-in", failures)

	diagnostic = office.call("_first_clutch_coach_snapshot", simulation.snapshot()) as Dictionary
	_check("Press Enter" in String(diagnostic.get("guidance", "")), "check-in guidance should disclose the contextual Enter action", failures)
	_check(bool(office.call("_handle_first_clutch_primary_action")), "Enter action should activate Mabel's highlighted PROFILE FIT", failures)
	await process_frame
	snapshot = office.first_clutch_snapshot()
	_check(bool(snapshot.get("checkin_filed", false)), "contextual check-in should reach the authoritative personnel system", failures)
	_check(StringName(snapshot.get("stage", &"")) == &"priority_peck", "two contextual actions should reach the live Priority Peck lesson", failures)
	_check(not bool(office.call("_handle_first_clutch_primary_action")), "Enter should return to normal behavior outside the two guided dossier steps", failures)

	store.delete()
	office.queue_free()
	await process_frame
	if failures.is_empty():
		print("FIRST_CLUTCH_KEYBOARD_GUIDANCE_TEST_PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _press(button: Button, label: String, failures: Array[String]) -> void:
	if button == null or button.disabled:
		failures.append("%s should be actionable" % label)
		return
	button.pressed.emit()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
