extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(25011, 6)
	simulation.day = 12
	simulation.owned_facilities[DepartmentSimulation.ROOSTER_OPERATIONS_OFFICE_ID] = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.export_save_state()
	var snapshot := simulation.snapshot()
	var roster := (snapshot.get("operations", {}) as Dictionary).get("manager_roster", []) as Array

	var ui := RoostStaffingUI.new()
	root.add_child(ui)
	ui.apply_snapshot(snapshot)
	await process_frame
	var roster_list := ui.find_child("ManagerRoster", true, false)
	_check(roster_list != null, "Operations should host the roster inside the existing Flockwatch surface", failures)
	if roster_list != null:
		_check(roster_list.find_children("ManagerCard_*", "PanelContainer", true, false).size() == 4, "tier three should render four compact manager cards", failures)
		_check(roster_list.find_children("Assignment_*", "OptionButton", true, false).size() == 4, "every manager should expose one assignment selector", failures)
		_check(roster_list.find_children("Posture_*", "OptionButton", true, false).size() == 4, "every manager should expose one posture selector", failures)
	var density_label := ui.find_child("ManagementDensity", true, false) as Label
	_check(density_label != null and "EGGS 0" in density_label.text and "OVERMANAGED" in density_label.text, "the roster should disclose report output and overmanagement without implying egg production", failures)
	_check(ui.find_children("RecruitManager_*", "Button", true, false).size() == 2, "the compact successor slate should offer the two non-default archetypes", failures)

	var presence := ManagementPresence.new()
	root.add_child(presence)
	await process_frame
	presence.apply_manager_roster(roster)
	await process_frame
	var manager_roots := presence.find_children("RoosterManager*", "Node3D", false, false)
	_check(manager_roots.size() == 4, "all four funded managers should have distinct office bodies", failures)
	var positions: Dictionary[String, bool] = {}
	for manager_root_value in manager_roots:
		var manager_root := manager_root_value as Node3D
		positions["%.2f/%.2f" % [manager_root.position.x, manager_root.position.z]] = true
		_check(manager_root.find_child("ManagerModel", true, false) != null, "%s should own one connected imported chicken model" % manager_root.name, failures)
	_check(positions.size() == 4, "manager patrols should start in separate office spaces", failures)
	_check(presence.find_children("ManagerReportFolder", "Node3D", true, false).size() == 3, "additional managers should visibly carry report folders rather than eggs", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("MANAGER_ROSTER_PRESENTATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MANAGER_ROSTER_PRESENTATION_TEST_PASSED ui=compact controls=per-manager disclosure=eggs-zero visuals=distinct patrols=spaced models=connected")
	quit(0)

func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
