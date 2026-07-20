extends SceneTree


const FACILITY_ID: StringName = &"farm_mutual_service_coop"
const LOW_OFFER: StringName = &"homestead_stability_binder"
const LEVEL_COSTS: Array[int] = [7500, 12000, 18000]
const MAINTENANCE_DELTAS: Array[int] = [300, 300, 300]
const STANDING_GATES: Array[int] = [2, 6, 12]
const CAPACITY_GATES: Array[int] = [24, 30, 36]
const STAFF_GATES: Array[int] = [4, 5, 6]
const STANDING_RANKS: Array[StringName] = [&"bronze", &"silver", &"gold"]
const EXPECTED_FOOTPRINT := Rect2(Vector2(12.00, 3.10), Vector2(6.40, 5.80))
const EXPECTED_FOCUS := Vector3(15.20, 1.05, 6.00)
const MAX_OPAQUE_HEIGHT := 4.25

var _stage := "boot"


func _init() -> void:
	create_timer(45.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	_stage = "constructing production Office"
	var simulation := DepartmentSimulation.new(71413, 4)
	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame
	_stage = "validating locked parcel"

	var coop := office.find_child("FarmMutualServiceCoopVisual", true, false) as FarmMutualServiceCoopVisual
	_check(simulation != null and coop != null, "production Office should compose the real simulation and Service Coop visual", failures)
	if simulation == null or coop == null:
		await _finish(office, failures)
		return

	_check(FarmMutualServiceCoopVisual.declared_footprint() == EXPECTED_FOOTPRINT, "Service Coop should reserve the audited northeast parcel", failures)
	_check(coop.focus_point_global().is_equal_approx(EXPECTED_FOCUS), "Service Coop should expose its exact production purchase-focus point", failures)
	_check(FarmMutualServiceCoopVisual.maximum_visual_height() <= MAX_OPAQUE_HEIGHT + 0.001, "Service Coop should stay below its 4.25m sightline cap", failures)
	_check(coop.geometry_bounds_inside_footprint(), "every hidden and visible Service Coop mesh should remain inside its declared parcel", failures)
	_check(coop.find_children("*", "CollisionObject3D", true, false).is_empty(), "visual-only Service Coop should add no collision objects", failures)
	_check(coop.find_children("*", "CollisionShape3D", true, false).is_empty(), "visual-only Service Coop should add no collision shapes", failures)
	_check(coop.find_children("*", "NavigationRegion3D", true, false).is_empty(), "visual-only Service Coop should add no navigation regions", failures)
	_check(coop.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "visual-only Service Coop should add no navigation obstacles", failures)
	_check(coop.find_children("*", "NavigationLink3D", true, false).is_empty(), "visual-only Service Coop should add no navigation links", failures)
	_check(coop.visual_state() == &"locked", "fresh campaign should show only the unearned Service Coop lease", failures)
	# Requisitions are intentionally refreshed only while their Capital filing is
	# actionable. Keep that filing open through the three-tier UI transaction.
	office.call("_open_flockwatch_page", &"capital")
	await process_frame

	# The first surveyed state must come from all three exact authoritative gates:
	# one fulfilled binder, one Records Annex tier, and four active hens.
	_prepare_exact_gate(simulation, 1)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_stage = "validating Bronze survey"
	var bronze_preflight := simulation.facility_status(FACILITY_ID)
	_check(simulation.farm_mutual_standing() == 2, "one fulfilled binder should derive exactly two standing points", failures)
	_check(simulation.current_claim_capacity() == 24, "Records Annex level one should provide the exact 24-file Bronze gate", failures)
	_check(simulation.active_worker_count() == 4, "Bronze survey should require exactly four active hens", failures)
	_check(bool(bronze_preflight.get("unlocked", false)), "meeting every exact Bronze gate should authorize the surveyed parcel", failures)
	_check(coop.visual_state() == &"survey", "real simulation eligibility should replace the locked lease with the survey site", failures)
	_check(coop.survey_site_visible() and not coop.locked_marker_visible(), "survey geometry should not imply an unpurchased tier", failures)

	var total_capital_debited := 0
	for level in range(1, 4):
		_stage = "commissioning tier %d" % level
		if level > 1:
			_prepare_exact_gate(simulation, level)
			office.call("_on_snapshot_changed", simulation.snapshot())
			await process_frame
			# Office capacity changes rebuild the authored desk/storytelling root.
			# Resolve the newly composed visual instead of retaining a freed tier.
			coop = office.find_child("FarmMutualServiceCoopVisual", true, false) as FarmMutualServiceCoopVisual
			_check(coop != null, "tier %d capacity expansion should recompose one Service Coop visual" % level, failures)
			if coop == null:
				await _finish(office, failures)
				return

		var preflight := simulation.facility_status(FACILITY_ID)
		_check(int(preflight.get("required_market_standing", -1)) == STANDING_GATES[level - 1], "tier %d should publish its exact standing gate" % level, failures)
		_check(int(preflight.get("required_claim_capacity", -1)) == CAPACITY_GATES[level - 1], "tier %d should publish its exact file-capacity gate" % level, failures)
		_check(int(preflight.get("required_active_staff", -1)) == STAFF_GATES[level - 1], "tier %d should publish its exact active-hen gate" % level, failures)
		_check(simulation.farm_mutual_standing() == STANDING_GATES[level - 1], "tier %d fixture should meet standing without surplus" % level, failures)
		_check(simulation.current_claim_capacity() == CAPACITY_GATES[level - 1], "tier %d fixture should meet capacity without surplus" % level, failures)
		_check(simulation.active_worker_count() == STAFF_GATES[level - 1], "tier %d fixture should meet staffing without surplus" % level, failures)

		var upkeep_before := simulation.current_daily_facility_maintenance_cents()
		simulation.revenue_cents = (
			simulation.current_daily_operating_cost_cents()
			+ LEVEL_COSTS[level - 1]
			+ MAINTENANCE_DELTAS[level - 1]
		)
		# Each accepted commission presents the installed tier on the floor and
		# closes the drawer. Reopen Capital before validating the next action.
		office.call("_open_flockwatch_page", &"capital")
		await process_frame
		office.call("_on_snapshot_changed", simulation.snapshot())
		await process_frame
		var purchase := office.find_child("PurchaseFacility_%s" % String(FACILITY_ID), true, false) as Button
		_check(purchase != null, "tier %d should retain the stable Service Coop requisition button" % level, failures)
		_check(purchase != null and not purchase.disabled, "tier %d exact gates and reserve should enable its requisition" % level, failures)
		if purchase != null:
			_check(("BUILD" if level == 1 else "UPGRADE") in purchase.text, "tier %d button should explain whether it builds or upgrades" % level, failures)

		var fund_before := simulation.revenue_cents
		if purchase != null:
			purchase.pressed.emit()
		await process_frame
		await process_frame
		var debited := fund_before - simulation.revenue_cents
		total_capital_debited += debited
		_check(debited == LEVEL_COSTS[level - 1], "tier %d UI purchase should debit its exact integer-cent capital cost" % level, failures)
		_check(simulation.facility_level(FACILITY_ID) == level, "tier %d UI input should commit authoritative ownership" % level, failures)
		_check(simulation.current_daily_facility_maintenance_cents() == upkeep_before + MAINTENANCE_DELTAS[level - 1], "tier %d purchase should add its exact recurring upkeep" % level, failures)
		_check(coop.visual_state() == StringName("level_%d" % level), "tier %d purchase should reveal its cumulative world state" % level, failures)
		_check(coop.standing_score() == STANDING_GATES[level - 1], "tier %d visual should consume the real standing ledger" % level, failures)
		_check(coop.standing_rank() == STANDING_RANKS[level - 1], "tier %d visual should consume the derived standing rank" % level, failures)
		for visible_level in range(1, level + 1):
			_check(coop.tier_visible(visible_level), "tier %d should retain purchased tier %d geometry" % [level, visible_level], failures)
		for hidden_level in range(level + 1, 4):
			_check(not coop.tier_visible(hidden_level), "tier %d should not reveal unpurchased tier %d geometry" % [level, hidden_level], failures)
		_check(coop.geometry_bounds_inside_footprint(), "tier %d reveal should remain inside the audited parcel" % level, failures)
		var effects := simulation.facility_effects()
		_check(int(effects.get("farm_mutual_premium_bonus_basis_points", -1)) == level * 5000, "tier %d ownership should expose the exact success-only premium multiplier" % level, failures)

	_check(total_capital_debited == 37500, "three cumulative Service Coop tiers should debit exactly $375.00 in capital", failures)
	_stage = "validating terminal requisition"
	var terminal := office.find_child("PurchaseFacility_%s" % String(FACILITY_ID), true, false) as Button
	_check(terminal != null and terminal.disabled, "Gold tier should retire the Service Coop requisition action", failures)
	_check(terminal != null and ("COMMISSIONED" in terminal.text or "INSTALLED" in terminal.text), "terminal card should explain that the Service Coop is fully commissioned", failures)
	var terminal_fund := simulation.revenue_cents
	if terminal != null:
		terminal.pressed.emit()
	await process_frame
	_check(simulation.revenue_cents == terminal_fund and simulation.facility_level(FACILITY_ID) == 3, "repeat UI input should remain economically idempotent", failures)

	# A real Gold-tier binder locks the authored 150% service bonus at signing.
	# Updating its real delivery ledger then drives the dispatch packets and exact
	# settlement hardware through OfficeStorytelling's normal snapshot route.
	simulation.revenue_cents = simulation.current_daily_operating_cost_cents() + 500
	_stage = "signing and fulfilling Gold binder"
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	var signature := simulation.sign_market_contract(LOW_OFFER)
	await process_frame
	_check(bool(signature.get("accepted", false)), "fully commissioned fixture should sign the real Homestead binder", failures)
	_check(int(signature.get("base_premium_cents", -1)) == 1000, "signed binder should preserve its authored $10.00 base premium", failures)
	_check(int(signature.get("service_coop_bonus_cents", -1)) == 1500, "Gold signing should lock the exact $15.00 Service Coop bonus", failures)
	_check(int(signature.get("premium_cents", -1)) == 2500, "Gold signing should disclose the exact $25.00 success credit", failures)

	var required_completed := int(simulation.active_market_contract.get("required_completed", 0))
	simulation.active_market_contract["timely_sound_completed"] = required_completed
	simulation.active_market_contract["sound_completed"] = required_completed
	simulation.active_market_contract["completed_count"] = required_completed
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_check(coop.active_contract_id() == String(simulation.active_market_contract.get("contract_id", "")), "Service Coop should retain the real signed binder identity", failures)
	_check(coop.visible_dispatch_packet_count() == 4, "four timely Homestead deliveries should materialize exactly four dispatch packets", failures)
	_check(coop.displayed_timely_completed() == 4 and coop.displayed_required_completed() == 4, "dispatch counter should read the authoritative 4/4 delivery ledger", failures)

	var fund_before_settlement := simulation.revenue_cents
	_stage = "settling Gold binder"
	var settlement: Dictionary = simulation.call("_settle_market_contract", simulation.day)
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_check(StringName(settlement.get("status", &"")) == &"fulfilled", "meeting the real binder threshold should fulfill the contract", failures)
	_check(int(settlement.get("base_premium_cents", -1)) == 1000, "settlement should retain the separate authored base premium", failures)
	_check(int(settlement.get("service_coop_bonus_cents", -1)) == 1500, "settlement should credit the exact locked Gold bonus", failures)
	_check(int(settlement.get("premium_cents", -1)) == 2500, "settlement should credit base plus Service Coop exactly once", failures)
	_check(simulation.revenue_cents == fund_before_settlement + 2500, "fulfilled Gold binder should add exactly $25.00 to the Feed Fund", failures)
	_check(coop.result_state() == &"success" and coop.success_indicator_active(), "fulfilled result should illuminate the Gold account hardware", failures)
	_check(coop.service_coop_bonus_cents() == 1500, "physical bonus tray should consume the exact authoritative $15.00 credit", failures)
	_check(coop.visible_dispatch_packet_count() == 0, "settled binder should clear all dispatch packet slots", failures)

	# Drain brief construction-focus and reveal tweens before freeing production
	# nodes so the focused scene test also stays clean under leak diagnostics.
	await create_timer(0.95).timeout
	_stage = "cleanup"
	await _finish(office, failures)


func _prepare_exact_gate(simulation: DepartmentSimulation, target_level: int) -> void:
	var gate_index := target_level - 1
	simulation.day = 3 + gate_index
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.market_contracts_succeeded_total = [1, 3, 6][gate_index]
	simulation.market_contracts_breached_total = 0
	simulation.market_clean_contract_streak = [1, 3, 6][gate_index]
	simulation.best_market_clean_contract_streak = [1, 3, 6][gate_index]
	simulation.owned_facilities[DepartmentSimulation.RECORDS_ANNEX_ID] = target_level
	simulation.office_capacity = STAFF_GATES[gate_index]
	for worker_index in simulation.workers.size():
		var worker := simulation.workers[worker_index]
		worker.employed = worker_index < STAFF_GATES[gate_index]
		worker.desk_index = worker_index if worker.employed else -1


func _finish(office: Node, failures: Array[String]) -> void:
	if office != null and is_instance_valid(office):
		office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FARM_MUTUAL_SERVICE_COOP_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARM_MUTUAL_SERVICE_COOP_OFFICE_INTEGRATION_TEST_PASSED gates=exact tiers=ui-to-world economy=authoritative packets=4 settlement=base-plus-bonus parcel=northeast collisions=none")
	quit(0)


func _on_watchdog_timeout() -> void:
	push_error("FARM_MUTUAL_SERVICE_COOP_OFFICE_INTEGRATION_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
