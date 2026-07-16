extends SceneTree

const FACILITY_ID := &"candling_rework_bay"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var lab := office.find_child("ShellQualityLabVisual", true, false) as ShellQualityLabVisual
	_check(simulation != null and lab != null, "production Office should compose simulation and QA facility visual", failures)
	if simulation == null or lab == null:
		await _finish(office, failures)
		return

	_check(lab.visual_state() == &"locked", "fresh office should not imply an unearned QA facility", failures)
	_check(simulation.apply_campaign_unlock(&"shell_quality_checks"), "quality milestone should unlock the capital file", failures)
	await process_frame
	_check(lab.visual_state() == &"construction_pad", "milestone should reveal the reserved physical construction pad", failures)

	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents() + 4300
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	var purchase := office.find_child("PurchaseFacility_candling_rework_bay", true, false) as Button
	_check(purchase != null and not purchase.disabled, "unlocked review with protected $43 should expose the build action", failures)
	_check(purchase != null and "$40.00" in purchase.text, "production requisition should show the exact $40 capital price", failures)

	var fund_before := simulation.revenue_cents
	if purchase != null:
		purchase.pressed.emit()
	await process_frame
	await process_frame
	_check(simulation.has_facility(FACILITY_ID), "Office purchase signal should commit the authoritative facility", failures)
	_check(simulation.revenue_cents == fund_before - 4000, "Office transaction should debit capital exactly once", failures)
	_check(simulation.current_daily_facility_maintenance_cents() == 300, "installed visual should carry its $3 daily liability", failures)
	_check(lab.visual_state() == &"owned" and lab.owned_bay_visible(), "purchase should replace the pad with the completed connected bay", failures)
	purchase = office.find_child("PurchaseFacility_candling_rework_bay", true, false) as Button
	_check(purchase != null and purchase.disabled and "INSTALLED" in purchase.text, "the requisition should reconcile to a terminal installed state", failures)

	var fund_after := simulation.revenue_cents
	if purchase != null:
		purchase.pressed.emit()
	await process_frame
	_check(simulation.revenue_cents == fund_after and simulation.facility_level(FACILITY_ID) == 1, "repeat input must remain idempotent across UI and economy", failures)

	await create_timer(0.4).timeout
	await _finish(office, failures)


func _finish(office: Node, failures: Array[String]) -> void:
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FACILITY_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FACILITY_OFFICE_INTEGRATION_TEST_PASSED gate=milestone purchase=ui-to-economy visual=pad-to-bay upkeep=visible repeat=atomic")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
