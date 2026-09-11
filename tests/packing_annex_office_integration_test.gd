extends SceneTree


const FACILITY_ID: StringName = &"farmer_brand_packing_annex"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var annex := office.find_child("PackingAnnexVisual", true, false) as PackingAnnexVisual
	_check(simulation != null and annex != null, "production Office should compose simulation and Packing Annex visual", failures)
	if simulation == null or annex == null:
		await _finish(office, failures)
		return
	_check(annex.visual_state() == &"locked", "fresh campaign should show only the unearned lease boundary", failures)
	# Capital requisitions are intentionally revision-driven only while their
	# filing is visible; exercise the same path a player uses before buying.
	office.call("_open_flockwatch_page", &"capital")
	await process_frame

	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents() + 6300
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_check(annex.visual_state() == &"survey", "two completed shifts should reveal the surveyed expansion site", failures)

	var level_costs := [6000, 9500, 14000]
	var maintenance_deltas := [300, 200, 300]
	for level in range(1, 4):
		if level > 1:
			simulation.revenue_cents = (
				simulation.current_daily_operating_cost_cents()
				+ int(level_costs[level - 1])
				+ int(maintenance_deltas[level - 1])
			)
			office.call("_on_snapshot_changed", simulation.snapshot())
			await process_frame
		# Each accepted commission deliberately returns to the floor to present the
		# physical result. Reopen Capital before validating the next tier.
		office.call("_open_flockwatch_page", &"capital")
		await process_frame
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
		_check(annex.visual_state() == StringName("level_%d" % level), "tier %d purchase should reveal its cumulative world geometry" % level, failures)
		for visible_level in range(1, level + 1):
			_check(annex.level_visible(visible_level), "tier %d should retain level %d equipment" % [level, visible_level], failures)

	for _egg in 4:
		simulation.call("_apply_packing_contract_value", &"sound", 500)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_check(annex.carton_progress() == 4, "annex should consume the authoritative carton progress field", failures)
	_check(annex.visible_carton_progress_slots() == 4, "exactly four physical meter slots should light for four good eggs", failures)
	for _egg in 2:
		simulation.call("_apply_packing_contract_value", &"sound", 500)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_check(annex.visible_carton_progress_slots() == 6, "the sixth authoritative good egg should briefly complete all six physical slots", failures)
	await create_timer(0.78).timeout
	_check(annex.carton_progress() == 0 and annex.visible_carton_progress_slots() == 0, "completed carton reveal should settle to the authoritative next-carton progress", failures)

	var terminal := office.find_child("PurchaseFacility_%s" % String(FACILITY_ID), true, false) as Button
	_check(terminal != null and terminal.disabled, "level three should retire the requisition action", failures)
	_check(terminal != null and ("COMMISSIONED" in terminal.text or "INSTALLED" in terminal.text), "terminal card should explain that the annex is fully commissioned", failures)
	var fund_after := simulation.revenue_cents
	if terminal != null:
		terminal.pressed.emit()
	await process_frame
	_check(simulation.revenue_cents == fund_after and simulation.facility_level(FACILITY_ID) == 3, "repeat UI input should remain economically idempotent", failures)

	# Drain the three brief purchase-focus timers before freeing the production
	# scene so the integration test also remains clean under leak diagnostics.
	await create_timer(0.85).timeout
	await _finish(office, failures)


func _finish(office: Node, failures: Array[String]) -> void:
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("PACKING_ANNEX_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PACKING_ANNEX_OFFICE_INTEGRATION_TEST_PASSED lease=locked-to-survey tiers=ui-to-world carton=authoritative repeat=atomic")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
