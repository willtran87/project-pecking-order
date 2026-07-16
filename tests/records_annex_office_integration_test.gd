extends SceneTree


const FACILITY_ID: StringName = &"records_annex"
const LEVEL_COSTS: Array[int] = [7000, 10500, 15500]
const MAINTENANCE_DELTAS: Array[int] = [400, 300, 400]
const EXPECTED_FOOTPRINT := Rect2(Vector2(12.00, -2.90), Vector2(6.40, 5.80))
const EXPECTED_FOCUS := Vector3(15.20, 0.90, 0.0)
const MAX_OPAQUE_HEIGHT := 3.55


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var annex := office.find_child("RecordsAnnexVisual", true, false) as RecordsAnnexVisual
	_check(simulation != null and annex != null, "production Office should compose simulation and Records Annex visual", failures)
	if simulation == null or annex == null:
		await _finish(office, failures)
		return

	_check(RecordsAnnexVisual.declared_footprint() == EXPECTED_FOOTPRINT, "Records Annex should reserve the audited east-parcel footprint", failures)
	_check(annex.focus_point_global().is_equal_approx(EXPECTED_FOCUS), "Records Annex should expose its stable purchase-focus point", failures)
	_check(RecordsAnnexVisual.maximum_visual_height() <= MAX_OPAQUE_HEIGHT + 0.001, "Records Annex opaque geometry should stay below its 3.55m sightline cap", failures)
	_check(annex.geometry_bounds_inside_footprint(), "every Records Annex mesh should stay inside its declared footprint", failures)
	_check(annex.find_children("*", "CollisionObject3D", true, false).is_empty(), "visual-only Records Annex should add no collision bodies", failures)
	_check(annex.find_children("*", "CollisionShape3D", true, false).is_empty(), "visual-only Records Annex should add no collision shapes", failures)
	_check(annex.visual_state() == &"locked", "fresh campaign should show only the unearned records lease", failures)

	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = (
		simulation.current_daily_operating_cost_cents()
		+ LEVEL_COSTS[0]
		+ MAINTENANCE_DELTAS[0]
	)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_check(annex.visual_state() == &"survey", "two completed shifts should reveal the surveyed Records Annex site", failures)

	for level in range(1, 4):
		if level > 1:
			simulation.revenue_cents = (
				simulation.current_daily_operating_cost_cents()
				+ LEVEL_COSTS[level - 1]
				+ MAINTENANCE_DELTAS[level - 1]
			)
			office.call("_on_snapshot_changed", simulation.snapshot())
			await process_frame
		var purchase := office.find_child("PurchaseFacility_%s" % String(FACILITY_ID), true, false) as Button
		_check(purchase != null, "tier %d should retain a stable requisition button" % level, failures)
		_check(purchase != null and not purchase.disabled, "tier %d exact funding should enable its requisition" % level, failures)
		if purchase != null:
			_check(("BUILD" if level == 1 else "UPGRADE") in purchase.text, "tier %d button should explain whether it builds or upgrades" % level, failures)
			purchase.pressed.emit()
		await process_frame
		await process_frame
		_check(simulation.facility_level(FACILITY_ID) == level, "tier %d UI input should commit authoritative ownership" % level, failures)
		_check(annex.current_level() == level, "tier %d visual should consume authoritative ownership" % level, failures)
		_check(annex.visual_state() == StringName("level_%d" % level), "tier %d purchase should reveal its cumulative world state" % level, failures)
		for visible_level in range(1, level + 1):
			_check(annex.tier_visible(visible_level), "tier %d should retain tier %d geometry" % [level, visible_level], failures)
		for hidden_level in range(level + 1, 4):
			_check(not annex.tier_visible(hidden_level), "tier %d should not reveal unpurchased tier %d geometry" % [level, hidden_level], failures)
		_check(annex.geometry_bounds_inside_footprint(), "tier %d reveal should remain inside the declared parcel" % level, failures)

	var demand_snapshot := simulation.snapshot().duplicate(true)
	demand_snapshot["claims_waiting"] = 11
	demand_snapshot["claims_outstanding"] = 11
	demand_snapshot["claim_capacity"] = 36
	demand_snapshot["claim_queue_counts"] = {
		&"nest_damage": 4,
		&"predator_loss": 3,
		&"appeals": 4,
	}
	demand_snapshot["queued_overdue_claims"] = 3
	demand_snapshot["overdue_claims"] = 3
	demand_snapshot["intake_rejections_today"] = 2
	demand_snapshot["intake_rejections_total"] = 5
	demand_snapshot["intake_missed_value_today_cents"] = 1275
	demand_snapshot["intake_missed_value_total_cents"] = 3860
	office.call("_on_snapshot_changed", demand_snapshot)
	await process_frame
	_check(annex.visible_folder_count() == 11, "eleven queued claims should occupy exactly eleven physical folder slots", failures)
	_check(annex.displayed_claim_capacity() == 36, "level-three mechanical counter should consume the authoritative 36-file capacity", failures)
	var capacity_text := annex.capacity_display_text()
	_check("11" in capacity_text and "36" in capacity_text, "capacity plate should read both live occupancy and capacity", failures)
	_check(annex.overdue_active(), "an overdue queue should power the Records Annex warning beacon", failures)
	_check(annex.overflow_bundle_count() == 2, "two rejected files should appear as exactly two overflow bundles", failures)

	var cleared_snapshot := demand_snapshot.duplicate(true)
	cleared_snapshot["claims_waiting"] = 0
	cleared_snapshot["claims_outstanding"] = 0
	cleared_snapshot["claim_queue_counts"] = {
		&"nest_damage": 0,
		&"predator_loss": 0,
		&"appeals": 0,
	}
	cleared_snapshot["queued_overdue_claims"] = 0
	cleared_snapshot["overdue_claims"] = 0
	cleared_snapshot["intake_rejections_today"] = 0
	office.call("_on_snapshot_changed", cleared_snapshot)
	await process_frame
	_check(annex.visible_folder_count() == 0, "an empty authoritative queue should clear every physical folder slot", failures)
	_check(not annex.overdue_active(), "clearing overdue work should extinguish the warning beacon", failures)
	_check(annex.overflow_bundle_count() == 0, "clearing today's rejection count should empty the overflow bin", failures)

	var terminal := office.find_child("PurchaseFacility_%s" % String(FACILITY_ID), true, false) as Button
	_check(terminal != null and terminal.disabled, "tier three should retire the Records Annex requisition action", failures)
	_check(terminal != null and ("COMMISSIONED" in terminal.text or "INSTALLED" in terminal.text), "terminal card should explain that the Records Annex is fully commissioned", failures)
	var fund_after := simulation.revenue_cents
	if terminal != null:
		terminal.pressed.emit()
	await process_frame
	_check(simulation.revenue_cents == fund_after and simulation.facility_level(FACILITY_ID) == 3, "repeat UI input should remain economically idempotent", failures)

	# Drain the three brief purchase-focus timers before freeing the production
	# scene so the integration test remains clean under leak diagnostics.
	await create_timer(0.90).timeout
	await _finish(office, failures)


func _finish(office: Node, failures: Array[String]) -> void:
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("RECORDS_ANNEX_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("RECORDS_ANNEX_OFFICE_INTEGRATION_TEST_PASSED parcel=east tiers=ui-to-world folders=authoritative overdue=reactive overflow=visible collisions=none")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
