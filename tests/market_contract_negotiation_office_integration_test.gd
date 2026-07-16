extends SceneTree


const ROOM_ID: StringName = &"farm_mutual_negotiation_room"
const OFFER_ID: StringName = &"predator_watch_pool"
const CLAUSE_ID: StringName = &"expedited_hatch_rider"

var _stage := "boot"


func _init() -> void:
	create_timer(45.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(91427, 6)
	_prepare_gold_review(simulation)
	var operating_before := simulation.current_daily_operating_cost_cents()
	simulation.revenue_cents = operating_before + 24_000 + 1_200 + 5_000

	_stage = "constructing production Office"
	var office := Office.new()
	office.set("_simulation", simulation)
	root.add_child(office)
	await process_frame
	await process_frame

	var clock := office.get("_clock") as SimulationClock
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var room := office.find_child("FarmMutualNegotiationRoomVisual", true, false) as FarmMutualNegotiationRoomVisual
	_check(room != null, "production Office should compose the north-parcel Negotiation Room visual", failures)
	_check(clock != null and clock.speed_index == 0, "Gold review should remain paused", failures)
	_check(room != null and room.visual_state() == &"construction_prospect", "exact Gold gates should reveal the unpurchased pavilion prospect", failures)

	_stage = "authorizing room through real requisition"
	var preflight := simulation.facility_status(ROOM_ID)
	_check(bool(preflight.get("unlocked", false)), "Gold standing plus Service Coop III should unlock the room", failures)
	_check(int(preflight.get("cost_cents", -1)) == 24_000, "room preflight should disclose exact $240 capital", failures)
	_check(int(preflight.get("maintenance_delta_cents", -1)) == 1_200, "room preflight should disclose exact $12 daily upkeep", failures)
	var purchase := office.find_child("PurchaseFacility_farm_mutual_negotiation_room", true, false) as Button
	_check(purchase != null and not purchase.disabled, "real capital card should enable the exact Gold room requisition", failures)
	var fund_before_purchase := simulation.revenue_cents
	if purchase != null:
		purchase.pressed.emit()
	await process_frame
	await process_frame
	_check(simulation.facility_level(ROOM_ID) == 1, "UI requisition should commit one permanent room level", failures)
	_check(simulation.revenue_cents == fund_before_purchase - 24_000, "room requisition should debit capital exactly once", failures)
	_check(simulation.current_daily_operating_cost_cents() == operating_before + 1_200, "commissioned room should add exact recurring upkeep", failures)
	_check(room != null and room.visual_state() == &"owned" and room.owned_room_visible(), "purchase should replace the prospect with the complete pavilion", failures)

	_stage = "opening negotiated planning"
	office.call("_open_contract_board_or_begin_next_shift")
	await process_frame
	await process_frame
	var board_ui := campaign_ui.contract_board_ui() if campaign_ui != null else null
	var folder := office.find_child("ContractFolder_predator_watch_pool", true, false) as Button
	_check(campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_CONTRACT_BOARD, "Day-9 review should open the real Contract Board", failures)
	_check(folder != null and not folder.disabled, "Predator Pool should be selectable in its Summer season", failures)
	if folder != null:
		folder.pressed.emit()
	await process_frame

	var negotiation_toggle := office.find_child("ContractNegotiationToggle", true, false) as Button
	_check(negotiation_toggle != null and negotiation_toggle.visible and not negotiation_toggle.disabled, "owned room should expose the Negotiation drawer", failures)
	if negotiation_toggle != null:
		negotiation_toggle.pressed.emit()
	await process_frame
	var rider := office.find_child("ContractClause_expedited_hatch_rider", true, false) as Button
	_check(rider != null and rider.is_visible_in_tree(), "drawer should expose the Expedited Hatch Rider as a physical choice", failures)
	if rider != null:
		rider.pressed.emit()
	await process_frame

	var presentation := board_ui.presentation_state() if board_ui != null else {}
	var effective := presentation.get("effective_terms", {}) as Dictionary
	_check(StringName(presentation.get("selected_clause_id", &"")) == CLAUSE_ID, "Board draft should retain the selected rider ID", failures)
	_check(int(effective.get("rush_claims", -1)) == 3, "Expedited draft should disclose one additional rush folder", failures)
	_check(int(effective.get("service_window_minutes", -1)) == 120, "Expedited draft should shorten the Predator service window by one hour", failures)
	_check(int(effective.get("premium_cents", -1)) == 4_720, "Summer Gold Expedited quote should add authored + season + rider + Coop without compounding", failures)
	_check(int(effective.get("breach_cents", -1)) == 1_280, "Summer Gold Expedited quote should disclose the exact $12.80 reserve", failures)
	_check(simulation.active_market_contract.is_empty(), "drafting a rider must not create a liability", failures)

	_stage = "signing selected rider"
	var sign_button := office.find_child("SignContractButton", true, false) as Button
	_check(sign_button != null and not sign_button.disabled, "exact rider preflight should enable the fixed Sign action", failures)
	var fund_before_signature := simulation.revenue_cents
	if sign_button != null:
		sign_button.pressed.emit()
	await process_frame
	await process_frame
	var active := simulation.active_market_contract
	_check(StringName(active.get("offer_id", &"")) == OFFER_ID, "signature should bind the selected Predator Pool", failures)
	_check(StringName(active.get("clause_id", &"")) == CLAUSE_ID, "signature should freeze the exact selected rider", failures)
	_check(StringName(active.get("season_id", &"")) == &"summer_predator_migration", "signature should freeze the deterministic Day-9 season", failures)
	_check(int(active.get("premium_cents", -1)) == 4_720 and int(active.get("breach_cents", -1)) == 1_280, "signed binder should retain the complete quoted economics", failures)
	_check(simulation.revenue_cents == fund_before_signature, "signature should reserve liability without debiting the Feed Fund", failures)
	_check(clock != null and clock.speed_index == 0, "negotiated signature should leave planning paused", failures)
	_check(room != null and room.active_clause_id() == CLAUSE_ID and room.active_rider_visible(), "physical room should display the authoritative signed rider", failures)

	await create_timer(0.95).timeout
	if clock != null:
		clock.set_speed(0)
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_CONTRACT_NEGOTIATION_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_CONTRACT_NEGOTIATION_OFFICE_INTEGRATION_TEST_PASSED purchase=$240+$12 season=summer rider=expedited quote=$47.20/$12.80 draft=no-liability world=authoritative")
	quit(0)


func _prepare_gold_review(simulation: DepartmentSimulation) -> void:
	simulation.day = 9
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.market_contracts_succeeded_total = 6
	simulation.market_contracts_breached_total = 0
	simulation.market_clean_contract_streak = 6
	simulation.best_market_clean_contract_streak = 6
	simulation.office_capacity = 6
	simulation.owned_facilities[DepartmentSimulation.RECORDS_ANNEX_ID] = 3
	simulation.owned_facilities[DepartmentSimulation.FARM_MUTUAL_SERVICE_COOP_ID] = 3
	for worker_index in simulation.workers.size():
		var worker := simulation.workers[worker_index]
		worker.employed = worker_index < 6
		worker.desk_index = worker_index if worker.employed else -1


func _on_watchdog_timeout() -> void:
	push_error("MARKET_CONTRACT_NEGOTIATION_OFFICE_INTEGRATION_TEST_TIMEOUT: %s" % _stage)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
