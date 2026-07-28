extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "interaction_safety_contract_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()

	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame

	var simulation := office.get("_simulation") as DepartmentSimulation
	var routing_ui := office.find_child(
		"PeckworkRoutingUI",
		true,
		false,
	) as PeckworkRoutingUI
	var staffing_ui := office.find_child(
		"RoostStaffingUI",
		true,
		false,
	) as RoostStaffingUI
	_check(
		simulation != null and routing_ui != null and staffing_ui != null,
		"Office should build all three authoritative interaction-safety surfaces",
		failures,
	)
	if simulation == null or routing_ui == null or staffing_ui == null:
		_finish(office, store, failures)
		return

	_check(
		simulation.select_directive(&"shell_assurance"),
		"the safety fixture should enter an ordinary running shift",
		failures,
	)
	await process_frame

	# Routine routing remains immediate, but one exact prior configuration can be
	# restored. Undo changes only future tray selection and cannot become Redo.
	routing_ui.set_focus(0)
	var opening_lane := simulation.workers[0].assigned_lane
	office.call("_on_worker_assignment_requested", 0, &"appeals")
	await process_frame
	var undo_button := office.find_child(
		"UndoRoutingAssignment",
		true,
		false,
	) as Button
	var undo_state := routing_ui.interaction_safety_state()
	_check(
		simulation.workers[0].assigned_lane == &"appeals"
		and undo_button != null
		and undo_button.visible
		and bool(undo_state.get("route_undo_visible", false))
		and StringName(undo_state.get("route_undo_previous_lane", &"")) == opening_lane,
		"a successful route should expose one truthful restore-prior-tray action",
		failures,
	)
	if undo_button != null:
		undo_button.pressed.emit()
	await process_frame
	_check(
		simulation.workers[0].assigned_lane == opening_lane
		and not bool(routing_ui.interaction_safety_state().get(
			"route_undo_visible",
			true,
		)),
		"Undo should restore the prior route once and retire itself instead of becoming Redo",
		failures,
	)
	var lane_after_undo := simulation.workers[0].assigned_lane
	if undo_button != null:
		undo_button.pressed.emit()
	_check(
		simulation.workers[0].assigned_lane == lane_after_undo,
		"a stale or repeated Undo input must not issue a duplicate routing command",
		failures,
	)

	# Irreversible claimant paths stage exact terms. Cancel/Escape-equivalent
	# changes no money or claim state; only explicit confirmation can file once.
	simulation.set_worker_at_workstation(0, true)
	for attempt in 3:
		if simulation.workers[0].current_claim != null:
			break
		simulation.advance_tick()
	await process_frame
	routing_ui.set_focus(0)
	routing_ui.call("_on_dossier_tab_pressed", &"claim")
	await process_frame
	var settle_button := office.find_child(
		"ClaimResolution_settle",
		true,
		false,
	) as Button
	var claim_confirmation := office.find_child(
		"ClaimResolutionConfirmation",
		true,
		false,
	) as ConfirmationDialog
	var claim_before := simulation.workers[0].current_claim
	var claim_id_before := claim_before.id if claim_before != null else -1
	var fund_before_claim := simulation.revenue_cents
	_check(
		claim_before != null
		and settle_button != null
		and not settle_button.disabled
		and claim_confirmation != null,
		"an eligible active claim should expose a staged settlement confirmation",
		failures,
	)
	root.size = Vector2i(390, 844)
	await process_frame
	if settle_button != null:
		settle_button.pressed.emit()
	await process_frame
	_check(
		claim_confirmation != null
		and claim_confirmation.visible
		and simulation.revenue_cents == fund_before_claim
		and simulation.workers[0].current_claim != null
		and not simulation.workers[0].current_claim.resolution_locked
		and bool(routing_ui.interaction_safety_state().get(
			"claim_confirmation_visible",
			false,
		)),
		"opening claimant confirmation must not spend or mutate the authoritative file",
		failures,
	)
	_check(
		_popup_fits_viewport(claim_confirmation, root.size),
		"claimant confirmation should fit within 390x844 portrait",
		failures,
	)
	if claim_confirmation != null:
		claim_confirmation.canceled.emit()
	await process_frame
	_check(
		not claim_confirmation.visible
		and simulation.revenue_cents == fund_before_claim
		and simulation.workers[0].current_claim != null
		and simulation.workers[0].current_claim.id == claim_id_before
		and not simulation.workers[0].current_claim.resolution_locked,
		"cancel should preserve the exact claimant file and Feed Fund",
		failures,
	)
	if settle_button != null:
		settle_button.pressed.emit()
	if claim_confirmation != null:
		claim_confirmation.confirmed.emit()
	await process_frame
	var fund_after_claim := simulation.revenue_cents
	_check(
		fund_after_claim == fund_before_claim - 120
		and simulation.workers[0].current_claim != null
		and simulation.workers[0].current_claim.resolution_locked
		and simulation.workers[0].current_claim.resolution_path == &"settle",
		"explicit confirmation should file the disclosed $1.20 settlement exactly once",
		failures,
	)
	if claim_confirmation != null:
		claim_confirmation.confirmed.emit()
	_check(
		simulation.revenue_cents == fund_after_claim,
		"repeated confirmation input must not double-charge a locked claimant path",
		failures,
	)

	# Separation is equally deliberate. The selected hen and exact cost remain
	# unchanged through cancel; confirmation reaches Office authority once.
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	simulation.pending_decision.clear()
	simulation.revenue_cents = 50_000
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	var release_selector := office.find_child(
		"ReleaseWorkerSelector",
		true,
		false,
	) as OptionButton
	var release_button := office.find_child(
		"ReleaseWorkerButton",
		true,
		false,
	) as Button
	var release_confirmation := office.find_child(
		"StaffReleaseConfirmation",
		true,
		false,
	) as ConfirmationDialog
	var release_index := _option_index_for_metadata(release_selector, 1)
	if release_selector != null and release_index >= 0:
		release_selector.select(release_index)
		release_selector.item_selected.emit(release_index)
	await process_frame
	var release_cost := simulation.workers[1].release_cost_cents()
	var fund_before_release := simulation.revenue_cents
	_check(
		release_button != null
		and not release_button.disabled
		and release_confirmation != null,
		"an eligible employed hen should expose a danger-styled staged release",
		failures,
	)
	root.size = Vector2i(844, 390)
	await process_frame
	if release_button != null:
		release_button.pressed.emit()
	await process_frame
	_check(
		release_confirmation != null
		and release_confirmation.visible
		and simulation.workers[1].employed
		and simulation.revenue_cents == fund_before_release
		and int(staffing_ui.interaction_safety_state().get(
			"release_worker_id",
			-1,
		)) == 1,
		"opening release confirmation must preserve employment and Feed Fund",
		failures,
	)
	_check(
		_popup_fits_viewport(release_confirmation, root.size),
		"release confirmation should fit within 844x390 short landscape",
		failures,
	)
	if release_confirmation != null:
		release_confirmation.canceled.emit()
	await process_frame
	_check(
		not release_confirmation.visible
		and simulation.workers[1].employed
		and simulation.revenue_cents == fund_before_release,
		"cancel should keep the selected hen employed with no separation charge",
		failures,
	)
	if release_button != null:
		release_button.pressed.emit()
	if release_confirmation != null:
		release_confirmation.confirmed.emit()
	await process_frame
	var fund_after_release := simulation.revenue_cents
	_check(
		not simulation.workers[1].employed
		and fund_after_release == fund_before_release - release_cost,
		"explicit confirmation should file one exact separation and its disclosed cost",
		failures,
	)
	if release_confirmation != null:
		release_confirmation.confirmed.emit()
	_check(
		simulation.revenue_cents == fund_after_release,
		"repeated release confirmation input must not duplicate the transaction",
		failures,
	)

	_finish(office, store, failures)


func _option_index_for_metadata(selector: OptionButton, metadata: Variant) -> int:
	if selector == null:
		return -1
	for index in selector.item_count:
		if selector.get_item_metadata(index) == metadata:
			return index
	return -1


func _popup_fits_viewport(popup: Window, viewport_size: Vector2i) -> bool:
	if popup == null:
		return false
	return (
		popup.size.x <= viewport_size.x
		and popup.size.y <= viewport_size.y
	)


func _finish(
	office: Office,
	store,
	failures: Array[String],
) -> void:
	if office != null:
		root.remove_child(office)
		office.free()
	store.delete()
	if not failures.is_empty():
		for failure in failures:
			push_error("INTERACTION_SAFETY_CONTRACT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print(
		"INTERACTION_SAFETY_CONTRACT_TEST_PASSED "
		+ "undo=one-level claimant=cancel+confirm-once release=cancel+confirm-once",
	)
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
