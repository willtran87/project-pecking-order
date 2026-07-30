extends SceneTree


const ContractBoardUIScript := preload("res://features/office/farm_mutual_contract_board_ui.gd")
const OFFER: StringName = &"homestead_stability_binder"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var harness := Control.new()
	harness.size = Vector2(1440.0, 900.0)
	root.add_child(harness)
	var ui = ContractBoardUIScript.new()
	harness.add_child(ui)
	var sign_requests: Array[Dictionary] = []
	ui.contract_sign_requested.connect(func(
		offer_id: StringName,
		clause_id: StringName,
		pricing_id: StringName,
	) -> void:
		sign_requests.append({
			"offer_id": offer_id,
			"clause_id": clause_id,
			"pricing_id": pricing_id,
		})
	)
	await process_frame
	var simulation := DepartmentSimulation.new(21201, 4)
	simulation.day = 3
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 100_000
	ui.apply_snapshot(simulation.snapshot())
	await process_frame
	var offer_button := ui.find_child("ContractFolder_homestead_stability_binder", true, false) as Button
	_check(offer_button != null, "the low binder should render as a selectable folder", failures)
	if offer_button != null:
		offer_button.pressed.emit()
	await process_frame
	var access_button := ui.find_child("ContractPricing_community_access_rate", true, false) as Button
	var select_button := ui.find_child("ContractPricing_executive_select_rate", true, false) as Button
	_check(access_button != null and not access_button.disabled, "Community Access should render as an enabled rate choice", failures)
	_check(select_button != null and select_button.disabled, "Executive Select should visibly render as held before reach", failures)
	if access_button != null:
		access_button.pressed.emit()
	await process_frame
	var state := ui.presentation_state()
	var effective := state.get("effective_terms", {}) as Dictionary
	_check(
		StringName(state.get("selected_pricing_profile_id", &"")) == &"community_access_rate",
		"pricing selection should be explicit in presentation state",
		failures,
	)
	_check(int(effective.get("total_claims", -1)) == 6, "the open binder should immediately show six access-rate folders", failures)
	_check(int(effective.get("premium_cents", -1)) == 800, "the open binder should immediately show the $8 access premium", failures)
	var effect_label := ui.find_child("ContractPricingEffect", true, false) as Label
	_check(
		effect_label != null
		and "CLAIMANT SENTIMENT +4" in effect_label.text
		and "MARKET REACH +3" in effect_label.text,
		"the selected posture should explain claimant and reach consequences without a tooltip",
		failures,
	)
	var sign_button := ui.find_child("SignContractButton", true, false) as Button
	_check(sign_button != null and not sign_button.disabled, "the selected access-rate binder should remain signable", failures)
	if sign_button != null:
		sign_button.pressed.emit()
	await process_frame
	_check(
		sign_requests == [{
			"offer_id": OFFER,
			"clause_id": &"standard_terms",
			"pricing_id": &"community_access_rate",
		}],
		"signature intent should carry the exact folder, clause, and pricing posture",
		failures,
	)
	harness.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("MARKET_PRICING_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("MARKET_PRICING_UI_TEST_PASSED choices=3 held=reach effects=visible signature=exact")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
