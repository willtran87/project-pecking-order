extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "staffing_ui_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()

	# Use the real Office handlers while keeping every checkpoint isolated from the
	# player's campaign. Headless Office boot already bypasses the title screen.
	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var staffing_ui := office.find_child("RoostStaffingUI", true, false) as RoostStaffingUI
	var workers_node := office.find_child("Workers", true, false) as Node3D
	var flockwatch_scroll := office.find_child("FlockwatchScroll", true, false) as ScrollContainer
	var flockwatch_navigation := office.find_child("FlockwatchNavigation", true, false) as FlockwatchNavigation
	var flock_page_scroll := (
		flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_FLOCK)
		if flockwatch_navigation != null else null
	) as ScrollContainer
	var flockwatch_panel := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	var day_review_scrim := office.find_child("DayReviewScrim", true, false) as ColorRect
	var capacity_button := office.find_child("PurchaseStaffCapacity", true, false) as Button
	var treasury_label := office.find_child("FarmTreasurySummary", true, false) as Label
	var fifth_workstation := office.find_child("Workstation_04", true, false) as Node3D
	var fifth_capacity_marker := office.find_child("CapacityAuthorization_04", true, false) as Node3D
	var sixth_workstation := office.find_child("Workstation_05", true, false) as Node3D
	var sixth_capacity_marker := office.find_child("CapacityAuthorization_05", true, false) as Node3D

	_check(simulation != null and clock != null, "Office should boot its staffing simulation and clock", failures)
	_check(staffing_ui != null, "Office should build the Roost Staffing surface", failures)
	_check(
		treasury_label != null
		and "TREASURY" in treasury_label.text
		and "HEADROOM" in treasury_label.text,
		"Flockwatch should explain the revolving line and current headroom without opening another overlay",
		failures,
	)
	_check(
		flockwatch_navigation != null
		and flock_page_scroll != null
		and staffing_ui != null
		and flock_page_scroll.is_ancestor_of(staffing_ui)
		and (flockwatch_scroll == null or not flockwatch_scroll.is_ancestor_of(staffing_ui)),
		"Roost Staffing should be hosted on the Flock page rather than the legacy Today scroll",
		failures,
	)
	var opening := simulation.snapshot() if simulation != null else {}
	_check(int(opening.get("active_staff_count", -1)) == 4, "a fresh campaign should employ four hens", failures)
	_check(int(opening.get("office_capacity", -1)) == 4, "a fresh campaign should authorize four perches", failures)
	_check(_employed_count(opening) == 4, "exactly four worker records should start employed", failures)
	_check(_applicant_count(opening) == 2, "exactly two worker records should start as applicants", failures)
	_check(
		flock_page_scroll != null
		and flock_page_scroll.find_children("StaffingApplicant_*", "PanelContainer", true, false).size() == 2,
		"the Flock page should own both screened applicant cards",
		failures,
	)
	_check(
		fifth_workstation != null and not fifth_workstation.visible and fifth_capacity_marker != null and not fifth_capacity_marker.visible,
		"the opening office should withhold the fifth-perch construction marker until staffing is relevant",
		failures,
	)
	_check(
		sixth_workstation != null and not sixth_workstation.visible and sixth_capacity_marker != null and not sixth_capacity_marker.visible,
		"perch six should remain held without signposting more than the next inactive workstation",
		failures,
	)
	_check(workers_node != null and workers_node.get_child_count() == 4, "Office should spawn views only for the four employed hens", failures)

	# Enter a genuine running shift. Pausing the clock must not turn an active shift
	# into a staffing review, so every staffing control should remain locked.
	_check(simulation.select_directive(&"shell_assurance"), "fixture should authorize the opening policy", failures)
	clock.set_speed(0)
	await process_frame
	capacity_button = office.find_child("PurchaseStaffCapacity", true, false) as Button
	var locked_hire := office.find_child("HireWorker_4", true, false) as Button
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "policy authorization should enter the running shift", failures)
	_check(not bool(simulation.snapshot().get("staffing_planning_open", true)), "staff planning should remain closed during a paused active shift", failures)
	_check(
		capacity_button != null and capacity_button.disabled and _contains_any(capacity_button.tooltip_text, ["review", "locked", "held"]),
		"capacity control should be disabled during the shift and explain why",
		failures,
	)
	_check(
		locked_hire != null and locked_hire.disabled and _contains_any(locked_hire.tooltip_text, ["locked", "review", "held"]),
		"applicant controls should be disabled during the shift and retain a reason",
		failures,
	)

	# Give the fixture enough unreserved Feed Fund, then advance across the real
	# end-of-day boundary while resolving the two deterministic incident files.
	simulation.revenue_cents = 50000
	simulation.eggs_today = simulation.quota_target
	simulation.cracked_today = 0
	_advance_to_review(simulation, failures)
	await process_frame
	await process_frame
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW, "completed workday should enter review", failures)
	_check(not bool(simulation.snapshot().get("staffing_planning_open", true)), "unresolved closing credit should keep staffing planning closed", failures)
	capacity_button = office.find_child("PurchaseStaffCapacity", true, false) as Button
	_check(
		capacity_button != null
		and capacity_button.disabled
		and _contains_any(capacity_button.tooltip_text, ["resolve", "credit", "memo"]),
		"capacity control should explain the unresolved closing-credit hold",
		failures,
	)
	_resolve_closing_credit(simulation, failures)
	await process_frame
	await process_frame
	_check(bool(simulation.snapshot().get("staffing_planning_open", false)), "filing closing credit should explicitly open staffing planning", failures)

	var review_requisitions := office.find_child("ReviewRequisitionsButton", true, false) as Button
	_check(review_requisitions != null, "farmer review should expose the requisitions action", failures)
	if review_requisitions != null:
		review_requisitions.pressed.emit()
	await process_frame
	_check(flockwatch_panel != null and flockwatch_panel.is_visible_in_tree(), "review requisitions should reveal Flockwatch", failures)
	office.call("_on_flockwatch_pressed")
	await process_frame
	_check(
		day_review_scrim != null and day_review_scrim.is_visible_in_tree(),
		"closing review requisitions should restore the visible Farmer review instead of exposing a bare review-state office",
		failures,
	)
	_check(
		flockwatch_panel != null and not flockwatch_panel.is_visible_in_tree(),
		"restoring the Farmer review should close the requisitions drawer",
		failures,
	)
	if review_requisitions != null:
		review_requisitions.pressed.emit()
	await process_frame
	_check(
		flockwatch_navigation != null
		and flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_FLOCK),
		"the persistent Flock page should remain reachable from the requisitions deep link",
		failures,
	)
	await process_frame
	_check(
		flockwatch_navigation != null
		and flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_FLOCK,
		"staffing review should explicitly navigate to the Flock filing page",
		failures,
	)
	_check(
		fifth_capacity_marker != null
		and fifth_capacity_marker.visible
		and sixth_capacity_marker != null
		and not sixth_capacity_marker.visible,
		"opening the staffing filing should reveal exactly the next authorized construction site",
		failures,
	)
	_check(staffing_ui != null and staffing_ui.is_visible_in_tree(), "Roost Staffing should be visible inside the open ledger", failures)
	_check(
		_flock_applicant_cards_are_visible(flock_page_scroll, 2),
		"both screened applicant cards should be visible on the open Flock page",
		failures,
	)

	capacity_button = office.find_child("PurchaseStaffCapacity", true, false) as Button
	var pre_capacity_hire := office.find_child("HireWorker_4", true, false) as Button
	_check(capacity_button != null and not capacity_button.disabled, "review should enable an affordable fifth-perch authorization", failures)
	_check(
		capacity_button != null
		and _contains_all(capacity_button.text, ["perch 5", "west bay a", "/ shift"])
		and _contains_all(capacity_button.tooltip_text, ["commission perch 5", "vacant workstation", "protected operating reserve"]),
		"capacity authorization should preview its exact physical bay and recurring obligation before purchase",
		failures,
	)
	_check(
		pre_capacity_hire != null and pre_capacity_hire.disabled and _contains_any(pre_capacity_hire.tooltip_text, ["perch", "workstation", "vacant"]),
		"hiring should remain held until capacity exists",
		failures,
	)
	if capacity_button != null:
		capacity_button.pressed.emit()
	await process_frame

	var expanded := simulation.snapshot()
	_check(int(expanded.get("office_capacity", -1)) == 5, "capacity authorization should open exactly one perch", failures)
	_check(int(expanded.get("active_staff_count", -1)) == 4, "capacity alone should not invent a worker", failures)
	var commissioning := office.call("capacity_commissioning_snapshot") as Dictionary
	var commissioning_beat := office.find_child("CapacityCommissioningBeat", true, false) as Node3D
	var commissioning_label := office.find_child("CapacityCommissioningLabel", true, false) as Label3D
	var west_partition := office.find_child("WestLeasePartition", true, false) as Node3D
	var west_stage := office.find_child("WestPerch04Presentation", true, false) as Node3D
	var west_fill := office.find_child("FluorescentFill_0", true, false) as OmniLight3D
	_check(
		bool(commissioning.get("active", false))
		and StringName(commissioning.get("phase", &"")) == &"commissioning"
		and int(commissioning.get("capacity", -1)) == 5
		and int(commissioning.get("perch_index", -1)) == 4
		and int(commissioning.get("cost_cents", 0)) > 0
		and int(commissioning.get("added_daily_operating_cents", 0)) > 0,
		"accepted capacity should publish one exact active commissioning receipt",
		failures,
	)
	_check(
		commissioning_beat != null
		and bool(commissioning_beat.get_meta(&"visual_only", false))
		and bool(commissioning_beat.get_meta(&"collision_free", false))
		and bool(commissioning_beat.get_meta(&"navigation_free", false))
		and commissioning_label != null
		and _contains_all(commissioning_label.text, ["perch 5", "commissioned", "filed", "/ shift"]),
		"the commissioning beat should visibly file the exact perch without adding collision or navigation authority",
		failures,
	)
	_check(
		west_stage != null and west_stage.visible
		and west_partition != null and west_partition.visible
		and west_fill != null and west_fill.visible,
		"the first animation frame should coordinate the west floor, retiring partition, and powered light",
		failures,
	)
	_check(
		fifth_workstation != null and fifth_workstation.visible and fifth_capacity_marker != null and not fifth_capacity_marker.visible,
		"capacity five should reveal its workstation and retire its authorization marker",
		failures,
	)
	_check(
		sixth_workstation != null and not sixth_workstation.visible and sixth_capacity_marker != null and not sixth_capacity_marker.visible,
		"capacity five should keep the sixth-perch preview out of the focused world after its filing closes",
		failures,
	)
	var fifth_nameplate := fifth_workstation.find_child("EmployeeNameplateText", true, false) as Label3D if fifth_workstation != null else null
	_check(fifth_nameplate != null and fifth_nameplate.text == "VACANT PERCH", "newly authorized desk should advertise its vacancy", failures)
	_check(_checkpoint_matches(store, "capacity_expanded", 5, 4, false), "capacity expansion should create a resumable capacity_expanded checkpoint", failures)

	await create_timer(1.55).timeout
	await process_frame
	commissioning = office.call("capacity_commissioning_snapshot") as Dictionary
	commissioning_beat = office.find_child("CapacityCommissioningBeat", true, false) as Node3D
	_check(
		not bool(commissioning.get("active", true))
		and StringName(commissioning.get("phase", &"")) == &"complete"
		and commissioning_beat == null,
		"the commissioning receipt should settle once and clean up its transient world art",
		failures,
	)
	_check(
		west_stage != null and west_stage.position.is_zero_approx() and west_stage.scale.is_equal_approx(Vector3.ONE)
		and west_partition != null and not west_partition.visible and west_partition.position.is_zero_approx()
		and west_fill != null and west_fill.light_energy > 0.0,
		"the commissioning handoff should settle architecture and lighting into their permanent capacity-five state",
		failures,
	)

	var reduced_preferences := (office.get("_player_preferences") as Dictionary).duplicate(true)
	reduced_preferences["motion_mode"] = "reduced"
	office.set("_player_preferences", reduced_preferences)
	office.call(
		"_begin_capacity_commissioning_beat",
		{
			"office_capacity": 5,
			"cost_cents": int(commissioning.get("cost_cents", 0)),
			"added_daily_operating_cents": int(commissioning.get("added_daily_operating_cents", 0)),
		},
	)
	await process_frame
	var reduced_commissioning := office.call("capacity_commissioning_snapshot") as Dictionary
	var reduced_beat := office.find_child("CapacityCommissioningBeat", true, false) as Node3D
	_check(
		bool(reduced_commissioning.get("active", false))
		and bool(reduced_commissioning.get("reduced_motion", false))
		and reduced_beat != null
		and reduced_beat.scale.is_equal_approx(Vector3.ONE),
		"reduced motion should retain the complete filed receipt without spatial pop or settle motion",
		failures,
	)
	await create_timer(0.86).timeout
	await process_frame
	reduced_commissioning = office.call("capacity_commissioning_snapshot") as Dictionary
	_check(
		not bool(reduced_commissioning.get("active", true))
		and StringName(reduced_commissioning.get("phase", &"")) == &"complete",
		"the reduced-motion receipt should remain bounded and clean itself up",
		failures,
	)
	reduced_preferences["motion_mode"] = "full"
	office.set("_player_preferences", reduced_preferences)

	var hire_button := office.find_child("HireWorker_4", true, false) as Button
	_check(hire_button != null and not hire_button.disabled, "first applicant should become hireable after perch five opens", failures)
	var applicant := _worker_snapshot(expanded, 4)
	var applicant_name := String(applicant.get("name", ""))
	if hire_button != null:
		hire_button.pressed.emit()
	await process_frame
	await process_frame

	var hired := simulation.snapshot()
	var hired_worker := _worker_snapshot(hired, 4)
	_check(int(hired.get("active_staff_count", -1)) == 5, "approved hire should increase active headcount to five", failures)
	_check(int(hired.get("office_capacity", -1)) == 5, "approved hire should consume, not expand, the fifth perch", failures)
	_check(bool(hired_worker.get("employed", false)) and int(hired_worker.get("desk_index", -1)) == 4, "applicant four should join the active roster at desk four", failures)
	var hired_view := office.find_child("Chicken_%s" % applicant_name, true, false) as ChickenView
	_check(
		workers_node != null and workers_node.get_child_count() == 5 and hired_view != null and hired_view.worker_id == 4,
		"Office should spawn the newly hired chicken view under the active workers node",
		failures,
	)
	_check(
		fifth_nameplate != null and fifth_nameplate.text == applicant_name.to_upper(),
		"the fifth workstation nameplate should identify its actual occupant",
		failures,
	)
	# Capacity authorization intentionally focuses the new physical perch and
	# collapses the ledger. Reopen it through the player-facing control before
	# validating the refreshed applicant filing in its actual visible context.
	if flockwatch_panel != null and not flockwatch_panel.is_visible_in_tree():
		var flockwatch_toggle := office.find_child("FlockwatchToggle", true, false) as Button
		_check(flockwatch_toggle != null, "the closed staffing ledger should remain reopenable", failures)
		if flockwatch_toggle != null:
			flockwatch_toggle.pressed.emit()
	await process_frame
	_check(
		flockwatch_navigation != null
		and flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_FLOCK),
		"the refreshed applicant filing should remain reachable on Flock",
		failures,
	)
	await process_frame
	_check(
		sixth_capacity_marker != null and sixth_capacity_marker.visible,
		"reopening the staffing filing should restore the one-step sixth-perch preview",
		failures,
	)
	_check(
		_flock_applicant_cards_are_visible(flock_page_scroll, 1),
		"the hired hen should leave one visible screened applicant on the Flock page",
		failures,
	)
	_check(_checkpoint_matches(store, "worker_hired", 5, 5, true), "hire should create a resumable worker_hired checkpoint with the employed desk", failures)

	# The remaining applicant stays visible, but the one-hire-or-release-per-day
	# rule must be legible at the button rather than failing silently.
	var second_hire := office.find_child("HireWorker_5", true, false) as Button
	_check(
		second_hire != null and second_hire.disabled and _contains_any(second_hire.tooltip_text, ["already closed", "closed"]),
		"remaining applicant should explain the same-day staffing action lock",
		failures,
	)
	var last_action := hired.get("last_staffing_action", {}) as Dictionary
	_check(String(last_action.get("action_id", "")) == "hire_worker" and int(last_action.get("worker_id", -1)) == 4, "review snapshot should expose the checkpoint-facing staffing action", failures)

	await create_timer(0.4).timeout
	office.free()
	await process_frame
	store.delete()

	if not failures.is_empty():
		for failure in failures:
			push_error("STAFFING_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("STAFFING_UI_TEST_PASSED opening=4/4 applicants=2 lock=explained review=open capacity=5 desk=revealed hire=spawned checkpoint=durable cooldown=legible")
	quit(0)


func _advance_to_review(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	for _step in 12:
		match simulation.shift_phase:
			DepartmentSimulation.ShiftPhase.RUNNING:
				simulation.advance_tick()
			DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
				_resolve_free_incident(simulation, failures)
			DepartmentSimulation.ShiftPhase.REVIEW:
				return
			_:
				_check(false, "review fixture entered an unexpected phase", failures)
				return
	_check(false, "review fixture did not settle after deterministic incidents", failures)


func _resolve_free_incident(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var pending := simulation.pending_decision_snapshot()
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) != 0:
			continue
		_check(
			simulation.resolve_decision(serial, StringName(option.get("id", &""))),
			"fixture should resolve the free incident branch",
			failures,
		)
		return
	_check(false, "deterministic incident should expose a free branch", failures)


func _resolve_closing_credit(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var pending := simulation.pending_decision_snapshot()
	var option_id: StringName
	match StringName(pending.get("id", &"")):
		&"closing_credit_memo":
			option_id = &"reward_top_layer"
		&"golden_egg_dossier":
			option_id = &"name_the_layer"
		&"flock_restructuring":
			option_id = &"contest_ranking"
		_:
			_check(false, "staffing UI review should expose a recognized closing credit decision", failures)
			return
	_check(
		simulation.resolve_decision(int(pending.get("serial", -1)), option_id),
		"staffing UI fixture should file the free closing credit option",
		failures,
	)


func _checkpoint_matches(
	store,
	reason: String,
	expected_capacity: int,
	expected_headcount: int,
	expect_worker_four_employed: bool
) -> bool:
	var envelope: Dictionary = store.load()
	if envelope.is_empty():
		return false
	var metadata := envelope.get("metadata", {}) as Dictionary
	var payload := envelope.get("campaign", {}) as Dictionary
	var saved_simulation := payload.get("simulation", {}) as Dictionary
	if String(metadata.get("reason", "")) != reason:
		return false
	if int(saved_simulation.get("office_capacity", -1)) != expected_capacity:
		return false
	var workers := saved_simulation.get("workers", []) as Array
	var employed_count := 0
	var worker_four_matches := false
	for worker_value in workers:
		var worker := worker_value as Dictionary
		if bool(worker.get("employed", false)):
			employed_count += 1
		if int(worker.get("id", -1)) == 4:
			worker_four_matches = (
				bool(worker.get("employed", false)) == expect_worker_four_employed
				and int(worker.get("desk_index", -1)) == (4 if expect_worker_four_employed else -1)
			)
	return employed_count == expected_headcount and worker_four_matches


func _worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _employed_count(snapshot: Dictionary) -> int:
	var count := 0
	for worker_value in snapshot.get("workers", []):
		if bool((worker_value as Dictionary).get("employed", false)):
			count += 1
	return count


func _applicant_count(snapshot: Dictionary) -> int:
	return (snapshot.get("workers", []) as Array).size() - _employed_count(snapshot)


func _contains_any(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment in fragments:
		if normalized.contains(fragment.to_lower()):
			return true
	return false


func _contains_all(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment in fragments:
		if not normalized.contains(fragment.to_lower()):
			return false
	return true


func _flock_applicant_cards_are_visible(flock_page_scroll: ScrollContainer, expected_count: int) -> bool:
	if flock_page_scroll == null or not flock_page_scroll.is_visible_in_tree():
		return false
	var cards := flock_page_scroll.find_children("StaffingApplicant_*", "PanelContainer", true, false)
	if cards.size() != expected_count:
		return false
	for card_node: Node in cards:
		var card := card_node as Control
		if card == null or not card.is_visible_in_tree():
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
