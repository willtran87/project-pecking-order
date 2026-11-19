class_name OfficeFirstClutchCoach
extends RefCounted

## First Clutch induction coaching: steps, snapshots and coach copy.
## Holds no state of its own: every read and write goes through the owning
## Office so behaviour is identical to the original in-class methods.

var office: Office


func _init(owner_node: Office) -> void:
	office = owner_node

func _should_hold_first_clutch_orientation() -> bool:
	return (
		office._campaign_state != null
		and int(office._campaign_state.completed_shifts) == 0
		and office._simulation != null
		and office._simulation.day == 1
		and office._campaign_review_stage == &"active"
		and not bool(office._first_clutch.get("dismissed", true))
		and not bool(office._first_clutch.get("completed", false))
		and office._first_clutch_stage() in [&"inspect", &"specialty_route"]
	)


func _handle_first_clutch_primary_action() -> bool:
	# First Clutch is a guided lesson with one deliberately highlighted answer at
	# these two stages. Enter activates that same production action so keyboard,
	# controller-mapped, and browser-assisted players do not have to hunt a dense
	# dossier for the glowing control. Normal play retains every routing choice.
	if not bool(office._first_clutch.get("dismissed", true)) and not office._peck_assist_input_blocked():
		if office._first_clutch_stage() == &"reinvestment":
			return office._present_first_clutch_reinvestment()
		if office._first_clutch_orders_handoff_pending():
			if bool(office._first_clutch.get("route_first_lesson", false)):
				# The inline coach explains the live quota. Keep the legacy save
				# flag as acknowledgement of that summary; the ledger stays optional.
				office._first_clutch["orders_handoff_acknowledged"] = true
				office._first_clutch_completion_hold_until_msec = 0
				office._refresh_first_clutch_ui(office._simulation.snapshot())
				office._on_speed_button_pressed(1)
				office._save_campaign_checkpoint("first_clutch_shift_continued")
				return true
			office._on_flockwatch_pressed()
			return true
	if not office._first_clutch_tracking_active():
		return false
	var stage := office._first_clutch_stage()
	if stage not in [&"specialty_route", &"check_in"]:
		return false
	var worker_id := int(office._first_clutch.get("target_worker_id", -1))
	var worker := office._first_clutch_worker_snapshot(office._simulation.snapshot(), worker_id)
	if worker.is_empty():
		return false
	if office._camera_controller != null:
		office._camera_controller.focus_worker(worker_id)
	if stage == &"specialty_route":
		var specialty := StringName(worker.get("specialty", &""))
		if specialty == &"":
			return false
		office._on_worker_assignment_requested(worker_id, specialty)
		return true
	var preferred_action := StringName(worker.get("preferred_personnel_action", &""))
	if preferred_action == &"":
		return false
	office._on_personnel_action_requested(worker_id, preferred_action)
	return true


func _make_first_clutch_state(dismissed: bool = true) -> Dictionary:
	return {
		"version": Office.FIRST_CLUTCH_VERSION,
		"dismissed": dismissed,
		"completed": false,
		"target_worker_id": -1,
		"inspected": false,
		"specialty_routed": false,
		"checkin_filed": false,
		"checkin_worker_id": -1,
		"assisted_worker_id": -1,
		"assisted_claim_id": -1,
		"delivery_laid": false,
		"delivery_seen": false,
		"orders_handoff_acknowledged": false,
		"delivered_claim_id": -1,
		"delivered_quality": "",
		"delivered_value_cents": 0,
		"delivered_priority_credit_cents": 0,
		"potential_priority_credit_cents": 0,
		"prior_presentations_pending": 0,
		"reinvestment_grandfathered": false,
	}


func _reset_first_clutch(enabled: bool) -> void:
	office._personal_goal.clear()
	office._personal_goal_offer.clear()
	office._first_reward_ready_msec = 0
	office._upgrade_demonstration.clear()
	office._first_clutch_completion_generation += 1
	office._first_clutch_completion_hold_until_msec = 0
	office._first_clutch = office._make_first_clutch_state(not enabled)
	office._first_clutch["route_first_lesson"] = enabled
	if enabled:
		office._capacity_marker_context_revealed = false
		office._apply_office_capacity_visibility(
			office._office_capacity_from_snapshot(office._simulation.snapshot()),
			false,
		)
	office._refresh_first_clutch_ui(office._simulation.snapshot())


func _normalize_first_clutch_state(value: Dictionary, legacy_missing: bool = false) -> Dictionary:
	if legacy_missing or value.is_empty():
		var missing_state := office._make_first_clutch_state(true)
		missing_state["reinvestment_grandfathered"] = true
		return missing_state
	var source_version := int(value.get("version", -1))
	if source_version not in [1, Office.FIRST_CLUTCH_VERSION]:
		var incompatible_state := office._make_first_clutch_state(true)
		incompatible_state["reinvestment_grandfathered"] = true
		return incompatible_state
	var legacy_v1 := source_version == 1
	var normalized := office._make_first_clutch_state(bool(value.get("dismissed", false)))
	normalized["route_first_lesson"] = bool(value.get("route_first_lesson", false))
	normalized["completed"] = bool(value.get("completed", false))
	normalized["target_worker_id"] = maxi(-1, int(value.get("target_worker_id", -1)))
	for key in ["inspected", "specialty_routed", "checkin_filed", "delivery_laid", "delivery_seen"]:
		normalized[key] = bool(value.get(key, false))
	normalized["checkin_worker_id"] = maxi(-1, int(value.get("checkin_worker_id", -1)))
	normalized["assisted_worker_id"] = maxi(-1, int(value.get("assisted_worker_id", -1)))
	normalized["assisted_claim_id"] = maxi(-1, int(value.get("assisted_claim_id", -1)))
	normalized["delivered_claim_id"] = maxi(-1, int(value.get(
		"delivered_claim_id",
		normalized["assisted_claim_id"] if legacy_v1 else -1,
	)))
	normalized["delivered_value_cents"] = maxi(0, int(value.get("delivered_value_cents", 0)))
	normalized["delivered_priority_credit_cents"] = maxi(
		0, int(value.get("delivered_priority_credit_cents", 0))
	)
	normalized["potential_priority_credit_cents"] = maxi(
		0, int(value.get("potential_priority_credit_cents", 0))
	)
	normalized["prior_presentations_pending"] = maxi(
		0, int(value.get("prior_presentations_pending", 0))
	)
	var quality := StringName(String(value.get("delivered_quality", "")))
	normalized["delivered_quality"] = String(quality) if quality in [&"sound", &"golden", &"cracked"] else ""
	normalized["reinvestment_grandfathered"] = (
		bool(value.get("completed", false))
		if legacy_v1 else
		bool(value.get("reinvestment_grandfathered", false))
	)

	if int(normalized["target_worker_id"]) < 0:
		normalized["inspected"] = false
		normalized["specialty_routed"] = false
		normalized["checkin_filed"] = false
		normalized["checkin_worker_id"] = -1
		normalized["assisted_worker_id"] = -1
		normalized["assisted_claim_id"] = -1
		normalized["delivered_claim_id"] = -1
		normalized["delivery_laid"] = false
		normalized["delivery_seen"] = false
		normalized["completed"] = false
		normalized["prior_presentations_pending"] = 0
	elif int(normalized["assisted_worker_id"]) != int(normalized["target_worker_id"]):
		normalized["assisted_worker_id"] = -1
		normalized["assisted_claim_id"] = -1
		normalized["delivered_claim_id"] = -1
		normalized["delivery_laid"] = false
		normalized["delivery_seen"] = false
		normalized["completed"] = false
		normalized["prior_presentations_pending"] = 0
	if not bool(normalized["checkin_filed"]):
		normalized["checkin_worker_id"] = -1
	if not bool(normalized["delivery_laid"]):
		normalized["delivered_claim_id"] = -1
	elif int(normalized["delivered_claim_id"]) < 0:
		normalized["delivered_claim_id"] = int(normalized["assisted_claim_id"])

	# Collection tweens are presentation-only and are intentionally not in the
	# campaign checkpoint. If a player reloads after the authoritative lay event,
	# treat the basket landing as having finished off-screen instead of deadlocking
	# the last induction step on an animation that no longer exists.
	if (
		not bool(normalized["dismissed"])
		and bool(normalized["delivery_laid"])
		and not bool(normalized["delivery_seen"])
	):
		normalized["delivery_seen"] = true
	normalized["completed"] = (
		not bool(normalized["dismissed"])
		and _first_clutch_state_has_all_steps(normalized)
	)
	normalized["orders_handoff_acknowledged"] = (
		bool(normalized["completed"])
		and bool(value.get("orders_handoff_acknowledged", false))
	)
	return normalized


func _first_clutch_state_has_all_steps(state: Dictionary) -> bool:
	var target_worker_id := int(state.get("target_worker_id", -1))
	return (
		target_worker_id >= 0
		and bool(state.get("inspected", false))
		and bool(state.get("specialty_routed", false))
		and (bool(state.get("checkin_filed", false)) or bool(state.get("route_first_lesson", false)))
		and int(state.get("assisted_worker_id", -1)) == target_worker_id
		and int(state.get("assisted_claim_id", -1)) >= 0
		and bool(state.get("delivery_laid", false))
		and bool(state.get("delivery_seen", false))
	)


func first_clutch_snapshot() -> Dictionary:
	var result := office._first_clutch.duplicate(true)
	result["stage"] = String(office._first_clutch_stage())
	result["progress"] = _first_clutch_progress()
	result["reinvestment"] = office._simulation.first_clutch_reinvestment_status().duplicate(true)
	result["orders_handoff_pending"] = office._first_clutch_orders_handoff_pending()
	return result


func _first_clutch_tracking_active() -> bool:
	return (
		not bool(office._first_clutch.get("dismissed", true))
		and not bool(office._first_clutch.get("completed", false))
		and office._campaign_review_stage == &"active"
		and office._campaign_state != null
		and office._campaign_state.outcome == Office.CampaignStateScript.OUTCOME_IN_PROGRESS
	)


func _first_clutch_can_reopen() -> bool:
	return (
		bool(office._first_clutch.get("dismissed", true))
		and not bool(office._first_clutch.get("completed", false))
		and int(office._first_clutch.get("target_worker_id", -1)) >= 0
		and office._campaign_state != null
		and int(office._campaign_state.completed_shifts) == 0
		and office._campaign_review_stage == &"active"
		and office._simulation != null
		and office._simulation.day == 1
		and not office._first_clutch_worker_snapshot(
			office._simulation.snapshot(),
			int(office._first_clutch.get("target_worker_id", -1)),
		).is_empty()
	)


func _first_clutch_orders_handoff_pending() -> bool:
	return (
		not bool(office._first_clutch.get("dismissed", true))
		and bool(office._first_clutch.get("completed", false))
		and office._first_clutch_reinvestment_resolved()
		and not bool(office._first_clutch.get("orders_handoff_acknowledged", false))
	)


func _first_clutch_reinvestment_resolved() -> bool:
	if (
		bool(office._first_clutch.get("dismissed", true))
		or bool(office._first_clutch.get("reinvestment_grandfathered", false))
	):
		return true
	var status := office._simulation.first_clutch_reinvestment_status()
	return bool(status.get("resolved", false)) or StringName(status.get("status", &"unavailable")) in [
		&"purchased",
		&"banked",
	]


func _first_clutch_worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	if worker_id < 0:
		return {}
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id and office._is_worker_employed(worker):
			return worker
	return {}


func _first_clutch_record_inspection(worker_id: int) -> void:
	if (
		not office._first_clutch_tracking_active()
		or office._simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
		or bool(office._first_clutch.get("inspected", false))
	):
		return
	var bound_worker_id := int(office._first_clutch.get("target_worker_id", -1))
	if bound_worker_id >= 0 and worker_id != bound_worker_id:
		return
	var snapshot := office._simulation.snapshot()
	var worker := office._first_clutch_worker_snapshot(snapshot, worker_id)
	if worker.is_empty():
		return
	if bound_worker_id < 0:
		office._first_clutch["target_worker_id"] = worker_id
	office._first_clutch["inspected"] = true
	if StringName(worker.get("assigned_lane", &"auto")) == StringName(worker.get("specialty", &"")):
		office._first_clutch["specialty_routed"] = true
	if (
		int(worker.get("last_personnel_action_day", 0)) == office._simulation.day
		and StringName(worker.get("last_personnel_action", &"")) != &""
	):
		office._first_clutch["checkin_filed"] = true
		office._first_clutch["checkin_worker_id"] = worker_id
	office._refresh_first_clutch_ui(snapshot)
	office._update_guidance(snapshot)
	office._save_campaign_checkpoint("first_clutch_inspected")


func _first_clutch_record_routing(worker_id: int, lane: StringName) -> void:
	if not office._first_clutch_tracking_active() or worker_id != int(office._first_clutch.get("target_worker_id", -1)):
		return
	var snapshot := office._simulation.snapshot()
	var worker := office._first_clutch_worker_snapshot(snapshot, worker_id)
	if not worker.is_empty() and lane == StringName(worker.get("specialty", &"")):
		office._first_clutch["specialty_routed"] = true
		if bool(office._first_clutch.get("route_first_lesson", false)):
			office._clock.set_speed(1)
	_first_clutch_try_complete()
	office._refresh_first_clutch_ui(snapshot)
	office._update_guidance(snapshot)


func _first_clutch_record_checkin(worker_id: int) -> void:
	if not office._first_clutch_tracking_active() or int(office._first_clutch.get("target_worker_id", -1)) < 0:
		return
	office._first_clutch["checkin_filed"] = true
	office._first_clutch["checkin_worker_id"] = worker_id
	_first_clutch_try_complete()
	var snapshot := office._simulation.snapshot()
	office._refresh_first_clutch_ui(snapshot)
	office._update_guidance(snapshot)


func _first_clutch_record_assist(result: Dictionary) -> void:
	if not office._first_clutch_tracking_active() or not bool(result.get("accepted", false)):
		return
	var worker_id := int(result.get("worker_id", -1))
	if worker_id != int(office._first_clutch.get("target_worker_id", -1)):
		return
	office._first_clutch["assisted_worker_id"] = worker_id
	office._first_clutch["assisted_claim_id"] = int(result.get("claim_id", -1))
	office._first_clutch["potential_priority_credit_cents"] = maxi(
		0, int(result.get("potential_priority_credit_cents", 0))
	)
	var snapshot := office._simulation.snapshot()
	office._refresh_first_clutch_ui(snapshot)
	office._update_guidance(snapshot)


func _first_clutch_record_laid_egg(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	claim_id: int = -1,
	priority_credit_cents: int = -1
) -> void:
	# New careers teach the production loop before optional personnel/timing.
	# Retain the receipt field names so old saves and collection guards stay valid.
	if (
		office._first_clutch_tracking_active()
		and bool(office._first_clutch.get("route_first_lesson", false))
		and bool(office._first_clutch.get("specialty_routed", false))
		and worker_id == int(office._first_clutch.get("target_worker_id", -1))
		and int(office._first_clutch.get("assisted_claim_id", -1)) < 0
		and claim_id >= 0 and value_cents > 0
	):
		office._first_clutch["assisted_worker_id"] = worker_id
		office._first_clutch["assisted_claim_id"] = claim_id
	if (
		not office._first_clutch_tracking_active()
		or worker_id != int(office._first_clutch.get("target_worker_id", -1))
		or worker_id != int(office._first_clutch.get("assisted_worker_id", -1))
		or (
			claim_id >= 0
			and claim_id != int(office._first_clutch.get("assisted_claim_id", -1))
		)
		or bool(office._first_clutch.get("delivery_laid", false))
	):
		return
	office._first_clutch["delivery_laid"] = true
	office._first_clutch["delivered_claim_id"] = (
		claim_id if claim_id >= 0 else int(office._first_clutch.get("assisted_claim_id", -1))
	)
	office._first_clutch["delivered_quality"] = String(quality)
	office._first_clutch["delivered_value_cents"] = maxi(0, value_cents)
	office._first_clutch["delivered_priority_credit_cents"] = maxi(
		0,
		priority_credit_cents
		if priority_credit_cents >= 0 else
		(0 if quality == &"cracked" else int(office._first_clutch.get("potential_priority_credit_cents", 0))),
	)
	office._first_clutch["prior_presentations_pending"] = maxi(
		0, int(office._eggs_in_flight_by_worker.get(worker_id, 0))
	)
	# When the player is actively following the induction hen, hand the shot to
	# the sorter so the promised egg journey is visible. Never steal an unrelated
	# camera focus.
	if (
		office._routing_ui != null
		and office._camera_controller != null
		and office._office_storytelling != null
		and not bool(office._first_clutch.get("route_first_lesson", false))
		and office._camera_controller.is_focused()
		and office._routing_ui.focused_worker_id() == worker_id
	):
		office._camera_controller.show_overview()
		office._camera_controller.show_event_focus(
			office._office_storytelling.sorting_focus_point_global(),
			"SHELL GRADING",
			1.8,
		)
	var snapshot := office._simulation.snapshot()
	office._refresh_first_clutch_ui(snapshot)
	office._update_guidance(snapshot)


func _first_clutch_record_presentation(
	worker_id: int,
	claim_id: int,
	quality: StringName,
	value_cents: int
) -> void:
	if (
		bool(office._first_clutch.get("dismissed", true))
		or bool(office._first_clutch.get("completed", false))
		or worker_id != int(office._first_clutch.get("target_worker_id", -1))
		or not bool(office._first_clutch.get("delivery_laid", false))
	):
		return
	var prior_presentations := int(office._first_clutch.get("prior_presentations_pending", 0))
	if prior_presentations > 0:
		office._first_clutch["prior_presentations_pending"] = prior_presentations - 1
		return
	if (
		claim_id < 0
		or claim_id != int(office._first_clutch.get("assisted_claim_id", -1))
		or claim_id != int(office._first_clutch.get("delivered_claim_id", -1))
		or worker_id != int(office._first_clutch.get("assisted_worker_id", -1))
		or
		StringName(String(office._first_clutch.get("delivered_quality", ""))) != quality
		or int(office._first_clutch.get("delivered_value_cents", -1)) != maxi(0, value_cents)
	):
		return
	office._first_clutch["delivery_seen"] = true
	office._first_clutch["delivered_quality"] = String(quality)
	office._first_clutch["delivered_value_cents"] = maxi(0, value_cents)
	if not _first_clutch_try_complete():
		var snapshot := office._simulation.snapshot()
		office._refresh_first_clutch_ui(snapshot)
		office._update_guidance(snapshot)
		office._save_campaign_checkpoint("first_clutch_delivery_seen")


func _first_clutch_try_complete() -> bool:
	if (
		bool(office._first_clutch.get("dismissed", true))
		or bool(office._first_clutch.get("completed", false))
		or not _first_clutch_state_has_all_steps(office._first_clutch)
	):
		return false
	var reinvestment_offer := office._simulation.begin_first_clutch_reinvestment(
		int(office._first_clutch.get("target_worker_id", -1)),
		int(office._first_clutch.get("delivered_claim_id", -1)),
		StringName(String(office._first_clutch.get("delivered_quality", ""))),
		int(office._first_clutch.get("delivered_value_cents", 0)),
	)
	if not bool(reinvestment_offer.get("accepted", false)):
		push_error(
			"First Clutch completed physically, but its authoritative reinvestment offer was rejected: %s"
			% String(reinvestment_offer.get("reason", "unknown ledger mismatch"))
		)
		return false
	office._first_clutch["completed"] = true
	office._first_clutch_completion_generation += 1
	var completion_generation := office._first_clutch_completion_generation
	office._first_clutch_completion_hold_until_msec = Time.get_ticks_msec() + roundi(
		Office.FIRST_CLUTCH_COMPLETION_HOLD_SECONDS * 1000.0
	)
	var priority_credit := int(office._first_clutch.get("delivered_priority_credit_cents", 0))
	office._ticker_label.text = "FIRST CLUTCH FILED  /  %s EGG  /  $%.2f CREDIT%s" % [
		String(office._first_clutch.get("delivered_quality", "sound")).to_upper(),
		float(int(office._first_clutch.get("delivered_value_cents", 0))) / 100.0,
		("  /  +$%.2f PRIORITY" % (float(priority_credit) / 100.0) if priority_credit > 0 else ""),
	]
	if office._audio_feedback != null:
		office._audio_feedback.play_decision_resolved()
	var snapshot := office._simulation.snapshot()
	office._refresh_first_clutch_ui(snapshot)
	office._refresh_flockwatch_navigation(snapshot)
	office._update_guidance(snapshot)
	office._save_campaign_checkpoint("first_clutch_completed")
	if bool(office._first_clutch.get("route_first_lesson", false)):
		office._clock.set_speed(0)
		office._character_dialogue_ui.hold_ambient(3.0)
		# Hold the earned result until the player chooses to open the upgrade.
		office._first_reward_ready_msec = 0
	else:
		office._present_first_clutch_reinvestment(reinvestment_offer)
	_retire_first_clutch_after_hold(completion_generation)
	return true


func _first_clutch_reinvestment_decision(status: Dictionary) -> Dictionary:
	var created_value := maxi(0, int(status.get("created_value_cents", 0)))
	var fund_at_collection := maxi(0, int(status.get("fund_at_collection_cents", 0)))
	var protected_reserve := maxi(0, int(status.get("protected_reserve_cents", 0)))
	var spendable_at_collection := maxi(0, int(status.get("spendable_at_collection_cents", 0)))
	var match_available := maxi(0, int(status.get("procurement_match_available_cents", 0)))
	var options: Array[Dictionary] = []
	var offered_options := status.get("offered_options", []) as Array
	for option_index in mini(2, offered_options.size()):
		var offered := offered_options[option_index] as Dictionary
		var option_id := StringName(offered.get("id", &""))
		var list_cost := maxi(0, int(offered.get("list_cost_cents", 0)))
		var procurement_match := maxi(0, int(offered.get("procurement_match_cents", 0)))
		var net_cost := maxi(0, int(offered.get("net_cost_cents", list_cost - procurement_match)))
		var projected_spendable := maxi(0, int(offered.get("projected_spendable_fund_cents", 0)))
		var can_purchase := bool(offered.get("can_purchase", offered.get("affordable", false)))
		var effect_label := String(
			offered.get("description", "Visible workstation improvement")
		).replace(" / level", "").to_upper()
		var benefit_label := "IMPROVE DESK"
		var benefit_glance := effect_label
		match option_id:
			&"peckwork_tools":
				benefit_label = "BETTER KEYS"
				benefit_glance = "+8% SPEED"
			&"shell_lamp":
				benefit_label = "SAFER SHELLS"
				benefit_glance = "RISK -2.5pt"
			&"nest_cushion":
				benefit_label = "SOFTER NEST"
				benefit_glance = "LESS STRAIN"
		var exact_preview := (
			"MABEL'S DESK  //  %s  //  LEVEL %d -> %d\n"
			+ "EXACT RECEIPT  //  $%.2f LIST  -  $%.2f MATCH  =  $%.2f FEED FUND\n"
			+ "SPENDABLE  //  $%.2f -> $%.2f"
		) % [
			effect_label,
			int(offered.get("level_before", 0)),
			int(offered.get("next_level", 1)),
			float(list_cost) / 100.0,
			float(procurement_match) / 100.0,
			float(net_cost) / 100.0,
			float(int(offered.get("spendable_fund_cents", spendable_at_collection))) / 100.0,
			float(projected_spendable) / 100.0,
		]
		options.append({
			"id": option_id,
			"label": benefit_label,
			"tagline": "%s  ·  PAY $%.2f" % [
				benefit_glance,
				float(net_cost) / 100.0,
			],
			"preview": "%s  ·  PAY $%.2f\n$%.2f SPENDABLE  >  $%.2f" % [
				benefit_glance,
				float(net_cost) / 100.0,
				float(int(offered.get("spendable_fund_cents", spendable_at_collection))) / 100.0,
				float(projected_spendable) / 100.0,
			],
			"accessible_preview": exact_preview,
			"confirm_label": "INSTALL %s  ·  $%.2f" % [
				benefit_label,
				float(net_cost) / 100.0,
			],
			"cost_cents": net_cost,
			"can_select": can_purchase,
			"unavailable_reason": String(offered.get(
				"reason",
				"The protected reserve leaves too little spendable Feed Fund for this invoice.",
			)),
		})
	var bank_exact_preview := (
		"MABEL'S DESK  //  UNCHANGED\n"
		+ "EXACT RECEIPT  //  $0.00 SPENT  //  $%.2f MATCH EXPIRES\n"
		+ "FEED FUND  //  $%.2f  //  SPENDABLE $%.2f"
	) % [
		float(match_available) / 100.0,
		float(int(status.get("current_fund_cents", fund_at_collection))) / 100.0,
		float(int(status.get("current_spendable_fund_cents", spendable_at_collection))) / 100.0,
	]
	options.append({
		"id": &"bank_fund",
		"label": "BANK THE FUND",
		"tagline": "KEEP $%.2f  ·  MATCH EXPIRES" % (
			float(int(status.get("current_spendable_fund_cents", spendable_at_collection))) / 100.0
		),
		"preview": "KEEP $%.2f SPENDABLE\nNO UPGRADE · UNUSED DESK MATCH EXPIRES" % (
			float(int(status.get("current_spendable_fund_cents", spendable_at_collection))) / 100.0
		),
		"accessible_preview": bank_exact_preview,
		"confirm_label": "BANK $%.2f" % (
			float(int(status.get("current_spendable_fund_cents", spendable_at_collection))) / 100.0
		),
		"cost_cents": 0,
		"can_select": bool(status.get("can_bank", true)),
		"unavailable_reason": String(status.get("reason", "This Feed Fund decision has already been filed.")),
	})
	var exact_body := (
		"%s's first egg created $%.2f. The farmer kept the presentation credit.\n\n"
		+ "$%.2f is spendable after the $%.2f protected reserve. "
		+ "Procurement matches up to $%.2f only if her desk improves."
	) % [
		String(status.get("trigger_worker_name", "Mabel")),
		float(created_value) / 100.0,
		float(spendable_at_collection) / 100.0,
		float(protected_reserve) / 100.0,
		float(match_available) / 100.0,
	]
	return {
		"kind": Office.FIRST_CLUTCH_REINVESTMENT_KIND,
		"category": Office.FIRST_CLUTCH_REINVESTMENT_KIND,
		"eyebrow": "FIRST EGG DELIVERED  ·  $%.2f" % (float(created_value) / 100.0),
		"title": "REWARD %s OR BANK THE FUND?" % String(status.get("trigger_worker_name", "Mabel")).to_upper(),
		"body": "YOU CAN SPEND $%.2f · PRICES INCLUDE YOUR MATCH" % (float(spendable_at_collection) / 100.0),
		"accessible_body": exact_body,
		"selection_prompt": "CHOOSE WHERE THE FIRST EGG GOES",
		"confirm_label": "PICK AN OPTION",
		"allow_stay_paused": false,
		"options": options,
	}


func _present_first_clutch_reinvestment(status: Dictionary = {}) -> bool:
	if (
		bool(office._first_clutch.get("dismissed", true))
		or bool(office._first_clutch.get("reinvestment_grandfathered", false))
	):
		return false
	if (
		office._campaign_review_stage not in [&"active", &"farmer"]
		or (office._campaign_ui != null and office._campaign_ui.is_modal_open())
	):
		return false
	var active_status := status if not status.is_empty() else office._simulation.first_clutch_reinvestment_status()
	if StringName(active_status.get("status", &"unavailable")) != &"offered":
		return false
	if office._decision_host != null and office._decision_host.visible:
		return StringName(office._active_decision.get("kind", &"")) == Office.FIRST_CLUTCH_REINVESTMENT_KIND
	office._on_decision_requested(_first_clutch_reinvestment_decision(active_status))
	return true


func _reconcile_first_clutch_reinvestment_after_restore() -> bool:
	if (
		not bool(office._first_clutch.get("completed", false))
		or bool(office._first_clutch.get("dismissed", true))
		or bool(office._first_clutch.get("reinvestment_grandfathered", false))
	):
		return false
	var status := office._simulation.first_clutch_reinvestment_status()
	if bool(status.get("offered", false)) or bool(status.get("resolved", false)):
		return false
	var receipt := office._simulation.begin_first_clutch_reinvestment(
		int(office._first_clutch.get("target_worker_id", -1)),
		int(office._first_clutch.get("delivered_claim_id", -1)),
		StringName(String(office._first_clutch.get("delivered_quality", ""))),
		int(office._first_clutch.get("delivered_value_cents", 0)),
	)
	if not bool(receipt.get("accepted", false)):
		push_error("Restored First Clutch could not stage its reinvestment: %s" % String(receipt.get("reason", "unknown ledger mismatch")))
		return false
	office._save_campaign_checkpoint("first_clutch_reinvestment_offered")
	return true


func _first_clutch_prepare_for_shift_boundary() -> void:
	if (
		bool(office._first_clutch.get("dismissed", true))
		or bool(office._first_clutch.get("completed", false))
		or int(office._first_clutch.get("assisted_claim_id", -1)) < 0
		or bool(office._first_clutch.get("delivery_laid", false))
	):
		return
	# DepartmentSimulation returns unfinished claims to the queue and clears their
	# Priority Peck bookkeeping at rollover. Re-open the exact induction step too;
	# the next unrelated egg must never inherit the old stamp or its credit.
	office._first_clutch["assisted_worker_id"] = -1
	office._first_clutch["assisted_claim_id"] = -1
	office._first_clutch["potential_priority_credit_cents"] = 0
	office._first_clutch["prior_presentations_pending"] = 0


func _retire_first_clutch_after_hold(completion_generation: int) -> void:
	await office.get_tree().create_timer(Office.FIRST_CLUTCH_COMPLETION_HOLD_SECONDS).timeout
	if completion_generation != office._first_clutch_completion_generation:
		return
	office._first_clutch_completion_hold_until_msec = 0
	var snapshot := office._simulation.snapshot()
	office._refresh_first_clutch_ui(snapshot)
	office._update_guidance(snapshot)


func _first_clutch_stage() -> StringName:
	if bool(office._first_clutch.get("completed", false)):
		if not office._first_clutch_reinvestment_resolved():
			return &"reinvestment"
		return &"complete"
	if not bool(office._first_clutch.get("inspected", false)):
		return &"inspect"
	if not bool(office._first_clutch.get("specialty_routed", false)):
		return &"specialty_route"
	if bool(office._first_clutch.get("route_first_lesson", false)):
		return &"delivery"
	if not bool(office._first_clutch.get("checkin_filed", false)):
		return &"check_in"
	if int(office._first_clutch.get("assisted_claim_id", -1)) < 0:
		return &"priority_peck"
	return &"delivery"


func _first_clutch_progress() -> int:
	if bool(office._first_clutch.get("route_first_lesson", false)):
		return 3 if bool(office._first_clutch.get("delivery_seen", false)) else 2 if bool(office._first_clutch.get("specialty_routed", false)) else 1 if bool(office._first_clutch.get("inspected", false)) else 0
	if not bool(office._first_clutch.get("inspected", false)):
		return 0
	if not bool(office._first_clutch.get("specialty_routed", false)):
		return 1
	if not bool(office._first_clutch.get("checkin_filed", false)):
		return 2
	if int(office._first_clutch.get("assisted_claim_id", -1)) < 0:
		return 3
	if not bool(office._first_clutch.get("delivery_seen", false)):
		return 4
	return 5


func _first_clutch_coach_snapshot(snapshot: Dictionary) -> Dictionary:
	var stage := office._first_clutch_stage()
	var pre_policy := office._first_hen_prelude_pending()
	var orders_handoff_pending := office._first_clutch_orders_handoff_pending()
	var completion_holding := (
		bool(office._first_clutch.get("completed", false))
		and (
			not office._first_clutch_reinvestment_resolved()
			or orders_handoff_pending
			or Time.get_ticks_msec() < office._first_clutch_completion_hold_until_msec
		)
	)
	var management_blocked := (
		(office._campaign_ui != null and office._campaign_ui.is_modal_open())
		or (office._decision_host != null and office._decision_host.visible)
		or (office._day_review_scrim != null and office._day_review_scrim.visible)
		or office._feed_party_active
	)
	var management_available := (
		office._campaign_review_stage == &"active"
		and (
			int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
			== DepartmentSimulation.ShiftPhase.RUNNING
			or pre_policy
		)
		and not management_blocked
	)
	var visible := (
		not bool(office._first_clutch.get("dismissed", true))
		and (not bool(office._first_clutch.get("completed", false)) or completion_holding)
		and management_available
	)
	var guidance_mode := String(office._player_preferences.get("guidance_mode", "full"))
	var target_worker_id := int(office._first_clutch.get("target_worker_id", -1))
	var worker := office._first_clutch_worker_snapshot(snapshot, target_worker_id)
	var target_name := String(worker.get("name", "YOUR HEN")).to_upper()
	var specialty_name := String(worker.get("specialty_name", String(worker.get("specialty", "SPECIALTY")).replace("_", " "))).to_upper()
	var specialty_short := String(worker.get("specialty", "SPECIALTY")).replace("_", " ").to_upper()
	var title := "INSPECT ONE HEN"
	var visual_title := ""
	var visual_body := ""
	var primary_label := ""
	var primary_action_shortcut := ""
	var body := (
		"The floor is paused for orientation. Click a hen or press Tab, read her dossier, then choose 1x when ready."
		if office._clock.speed_index == 0 else
		"Click a hen on the floor or press Tab. Her real file becomes your induction case."
	)
	var guidance := (
		"Inspect a hen, then choose 1x when you are ready."
		if office._clock.speed_index == 0 else
		"Inspect a hen on the floor or press Tab."
	)
	var tone: StringName = &"active"
	if pre_policy:
		title = "OPEN %s'S FIRST FILE" % target_name
		body = (
			"\"Appeals are mine. The farmer remembers the basket, not the beak.\"  "
			+ "APPEALS  /  CREDIT CONSCIOUS"
		)
		visual_title = "MEET %s" % target_name
		visual_body = "APPEALS SPECIALIST  ·  BASKET FIRST, BEAK SECOND."
		guidance = "Open %s's file before choosing the flock policy." % target_name
		tone = &"ready"
	match stage:
		&"specialty_route":
			primary_label = "ROUTE TO %s" % specialty_short
			primary_action_shortcut = "Enter"
			title = "ROUTE %s TO %s" % [target_name, specialty_name]
			visual_title = "CHOOSE %s" % specialty_short
			var assignment := StringName(worker.get("assigned_lane", &"auto"))
			var current_name := String(worker.get("assignment_name", "AUTO DISPATCH")).to_upper()
			if assignment != &"auto" and assignment != StringName(worker.get("specialty", &"")):
				visual_title = "MATCH %s'S TRAY" % target_name
				body = "%s is currently stamped %s. Match her specialty tray in the dossier; wrong routes remain allowed." % [target_name, current_name]
				tone = &"warning"
			else:
				body = "Press Enter for the highlighted specialty tray, or choose a dossier stamp below. Specialty matching improves speed and shell safety; AUTO stays available later."
				visual_body = "FIT = FASTER + SAFER"
			guidance = "Press Enter to route %s to %s, or choose another tray below." % [target_name, specialty_short]
		&"check_in":
			primary_label = "FILE CHECK-IN"
			visual_title = "HELP %s SETTLE IN" % target_name
			visual_body = "RECOGNITION → TRUST → BETTER WORK"
			primary_action_shortcut = "Enter"
			title = "FILE %s'S CHECK-IN" % target_name
			body = "Press Enter to FILE CHECK-IN with the recommended personnel action, or choose another action below. The filing is permanent."
			guidance = "Press Enter to FILE CHECK-IN for %s, or choose another personnel action below." % target_name
		&"priority_peck":
			title = "LAND %s'S PRIORITY PECK" % target_name
			var peck_status := worker.get("peck_assist", {}) as Dictionary
			if bool(peck_status.get("available", false)) and office._clock.speed_index > 0:
				primary_label = "PECK NOW"
				visual_body = "GOLD WINDOW → BONUS ON DELIVERY"
				primary_action_shortcut = office._action_hint(Office.PECK_ASSIST_ACTION)
				visual_title = "PECK NOW  [%s]" % primary_action_shortcut
				body = "GOLD WINDOW OPEN. Press %s or use the glowing dossier stamp before this live file moves on." % office._action_hint(Office.PECK_ASSIST_ACTION)
				guidance = "%s is in the gold window—press %s or the dossier stamp now." % [target_name, office._action_hint(Office.PECK_ASSIST_ACTION)]
				tone = &"ready"
			elif office._clock.speed_index == 0:
				primary_label = "RESUME SHIFT" if office._simulation.minute_of_day > DepartmentSimulation.SHIFT_START_MINUTE else "START WORK"
				visual_body = "FILE > HEN > EGG > REWARD"
				primary_action_shortcut = "1"
				visual_title = "RESUME AT 1x"
				body = "Resume the clock, then watch %s's live file meter. The stamp glows gold in the clean-rhythm window." % target_name
				guidance = "Resume the clock and watch %s's file meter for gold." % target_name
			elif (worker.get("current_claim", {}) as Dictionary).is_empty():
				visual_body = "YOUR HEN PULLS FILES AUTOMATICALLY"
				visual_title = "WAIT FOR %s'S FILE" % target_name
				body = "Keep %s routed and seated until she pulls a live file. The gold timing window appears during peckwork." % target_name
				guidance = "Wait for %s to pull a live file." % target_name
			else:
				visual_title = "WATCH FOR GOLD"
				visual_body = "PECK WHEN GOLD · MISSED IT? TRY THE NEXT FILE"
				body = "Watch %s's live file meter. A missed window only closes this file; retry on her next one." % target_name
				guidance = "Watch %s's live file for the gold Priority Peck window." % target_name
		&"delivery":
			if bool(office._first_clutch.get("delivery_laid", false)):
				title = "FOLLOW %s'S EGG THROUGH GRADING" % target_name
				visual_title = "FOLLOW THE EGG"
				body = "The camera has handed off to shell grading. Watch the rail and basket; press Esc only if you want to return to the floor."
				visual_body = "GRADING  >  FARMER BASKET  >  FEED FUND"
				guidance = "Follow %s's egg through grading and into the farmer basket." % target_name
				tone = &"ready"
			else:
				title = "FOLLOW %s'S ASSISTED FILE" % target_name
				visual_title = "WATCH %s FINISH" % target_name
				body = "Priority Peck landed on file #%04d. Keep the clock moving and watch %s finish the same real file." % [int(office._first_clutch.get("assisted_claim_id", 0)), target_name]
				visual_body = "PECK LANDED  >  FINISH FILE  >  LAY EGG"
				guidance = "Watch %s finish the assisted file and lay its egg." % target_name
		&"reinvestment":
			primary_label = "CHOOSE UPGRADE"
			primary_action_shortcut = "Enter"
			visual_title = "MAKE YOUR FIRST UPGRADE"
			visual_body = "CHOOSE EQUIPMENT · WATCH IT WORK"
			var reinvestment := office._simulation.first_clutch_reinvestment_status()
			title = "REINVEST %s'S FIRST EGG" % target_name
			body = "%s created $%.2f. Choose one visible desk requisition or Bank the Feed Fund before today's three orders open." % [
				target_name,
				float(int(reinvestment.get("created_value_cents", office._first_clutch.get("delivered_value_cents", 0)))) / 100.0,
			]
			guidance = "Choose where Mabel's first egg goes, then authorize; today's three orders will open."
			tone = &"ready"
		&"complete":
			var quality := String(office._first_clutch.get("delivered_quality", "sound")).to_upper()
			var value_cents := int(office._first_clutch.get("delivered_value_cents", 0))
			var priority_cents := int(office._first_clutch.get("delivered_priority_credit_cents", 0))
			title = "FIRST CLUTCH FILED  /  %s" % quality
			if orders_handoff_pending:
				primary_label = "SEE SHIFT GOALS"
				primary_action_shortcut = office._action_hint(&"toggle_flockwatch")
				visual_title = "OPEN TODAY'S ORDERS  [%s]" % primary_action_shortcut
				visual_body = "FIRST EGG FILED  >  3 LIVE GOALS"
			body = "%s's egg landed at $%.2f total value%s. Press V to open today's three probation orders; the score is filed at review." % [
				target_name,
				float(value_cents) / 100.0,
				(" including +$%.2f Priority credit" % (float(priority_cents) / 100.0) if priority_cents > 0 else ""),
			]
			guidance = "%s delivered a %s egg worth $%.2f. Press V to review today's orders." % [target_name, quality, float(value_cents) / 100.0]
			tone = &"complete"
	var route_first := bool(office._first_clutch.get("route_first_lesson", false))
	if route_first:
		if stage == &"specialty_route":
			primary_label = "ROUTE & START"
			guidance = "Route %s to her specialty and start work. She will pull and finish files automatically." % target_name
			body = guidance
		elif stage == &"delivery" and not bool(office._first_clutch.get("delivery_laid", false)):
			title = "WATCH %s WORK" % target_name
			visual_title = title
			visual_body = "NO EXTRA CLICKS  ·  NEXT: EGG"
			body = "No extra click is required. Check-ins and timed Pecks are optional improvements after this first delivery."
			guidance = body
			if office._clock.speed_index == 0:
				primary_label = "RESUME SHIFT" if office._simulation.minute_of_day > DepartmentSimulation.SHIFT_START_MINUTE else "START WORK"
		elif stage == &"delivery":
			visual_title = "%s LAID AN EGG" % target_name
			visual_body = "EGG → BASKET → FEED FUND"
			body = "Her egg is travelling to the basket. Payment arrives when it lands; your camera stays where you put it."
			guidance = body
		elif stage == &"reinvestment":
			visual_title = "%s EARNED $%.2f" % [target_name, float(int(office._first_clutch.get("delivered_value_cents", 0))) / 100.0]
			title = visual_title
			visual_body = "SHIFT PAUSED · CHOOSE AN UPGRADE OR SAVE THE MONEY"
			guidance = "Your first egg paid into the Feed Fund. Choose an upgrade when ready; the shift is paused."
		elif stage == &"complete" and orders_handoff_pending:
			var quota := maxi(1, int(snapshot.get("quota_target", 1)))
			var eggs := maxi(0, int(snapshot.get("eggs_today", 0)))
			primary_label = "CONTINUE SHIFT"
			primary_action_shortcut = "Enter"
			visual_title = "SHIFT GOAL: %d EGGS" % quota
			title = visual_title
			visual_body = "%d / %d LAID · BY 5:00 PM\nHens work automatically. Help when needed." % [eggs, quota]
			body = "Earn eggs before 5:00 PM. Route files to each hen's specialty and help when she needs it. Review results and reinvest at the end of the shift. Full goals: %s." % office._action_hint(&"toggle_flockwatch")
			guidance = "Continue at 1×: %d more eggs to reach today's quota. Full goals remain in Flockwatch; opening it is optional." % maxi(0, quota - eggs)
	return {
		"visible": visible,
		"stage": stage,
		"step": stage,
		"progress": ([&"inspect", &"specialty_route", &"delivery", &"reinvestment", &"complete"].find(stage) if route_first else _first_clutch_progress()),
		"total": 5,
		"route_first_lesson": route_first,
		"eyebrow": (
			"YOUR FIRST EGG" if route_first else
			"FIRST CLUTCH  //  ORIENTATION"
			if pre_policy else
			"FIRST CLUTCH  %d / 5" % _first_clutch_progress()
		),
		"title": title,
		"visual_title": visual_title if not visual_title.is_empty() else title,
		"body": body,
		"visual_body": visual_body if not visual_body.is_empty() else body,
		"guidance": guidance,
		"essential_only": guidance_mode == "essential",
		"tone": tone,
		"target_worker_id": target_worker_id,
		"worker_id": target_worker_id,
		"target_name": target_name,
		"specialty_name": specialty_name,
		"expected_lane": String(worker.get("specialty", "")),
		"preferred_action": String(worker.get("preferred_personnel_action", "")),
		"primary_action_shortcut": primary_action_shortcut,
		"primary_label": primary_label,
		"resume_required": (stage == &"priority_peck" or (route_first and stage == &"delivery")) and office._clock.speed_index == 0,
		"assisted_claim_id": int(office._first_clutch.get("assisted_claim_id", -1)),
		"delivery_laid": bool(office._first_clutch.get("delivery_laid", false)),
		"completion": bool(office._first_clutch.get("completed", false)),
		"pre_policy": pre_policy,
		"orders_handoff_pending": orders_handoff_pending,
		"orders_handoff_cue_visible": orders_handoff_pending and management_available,
		"can_skip": stage not in [&"complete", &"reinvestment"] and not pre_policy,
	}


func _refresh_first_clutch_ui(snapshot: Dictionary = {}) -> void:
	if office._routing_ui == null:
		office._clear_first_clutch_global_cue()
		return
	var active_snapshot := snapshot if not snapshot.is_empty() else office._simulation.snapshot()
	if office._first_clutch_tracking_active() and int(office._first_clutch.get("target_worker_id", -1)) >= 0:
		var target := office._first_clutch_worker_snapshot(active_snapshot, int(office._first_clutch["target_worker_id"]))
		if target.is_empty():
			office._first_clutch = office._make_first_clutch_state(false)
	var coach := office._first_clutch_coach_snapshot(active_snapshot)
	office._routing_ui.call("apply_first_clutch", coach)
	office._update_flockwatch_toggle(active_snapshot)
	_apply_first_clutch_global_cue(coach)


func _apply_first_clutch_global_cue(coach: Dictionary) -> void:
	var desired: Button
	var cue_tooltip := ""
	if bool(coach.get("orders_handoff_cue_visible", false)) and not bool(coach.get("route_first_lesson", false)) and not office._flockwatch_open:
		desired = office._flockwatch_toggle
		cue_tooltip = "FIRST CLUTCH COMPLETE: open today's three live probation orders."
	elif bool(coach.get("visible", false)):
		var stage := StringName(coach.get("stage", &""))
		if stage == &"priority_peck" and bool(coach.get("resume_required", false)):
			if office._speed_buttons.size() > 1:
				desired = office._speed_buttons[1]
				cue_tooltip = "FIRST CLUTCH: resume at normal speed to reach the live Priority Peck window."
	if desired == office._first_clutch_global_cued_control:
		return
	office._clear_first_clutch_global_cue()
	if desired == null or not is_instance_valid(desired):
		return
	office._first_clutch_global_cued_control = desired
	desired.set_meta("first_clutch_original_theme", desired.theme_type_variation)
	desired.set_meta("first_clutch_original_tooltip", desired.tooltip_text)
	desired.set_meta("first_clutch_original_modulate", desired.modulate)
	desired.theme_type_variation = &"SelectedChoiceButton"
	desired.tooltip_text = cue_tooltip
	desired.modulate = Color(1.12, 1.04, 0.78, 1.0)
	office._first_clutch_global_cue_tween = office._presentation_tween(desired).set_loops()
	office._first_clutch_global_cue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	office._first_clutch_global_cue_tween.tween_property(desired, "modulate", Color.WHITE, 0.55)
	office._first_clutch_global_cue_tween.tween_property(
		desired, "modulate", Color(1.12, 1.04, 0.78, 1.0), 0.55
	)


func _clear_first_clutch_global_cue() -> void:
	if office._first_clutch_global_cue_tween != null and office._first_clutch_global_cue_tween.is_valid():
		office._first_clutch_global_cue_tween.kill()
	office._first_clutch_global_cue_tween = null
	var control := office._first_clutch_global_cued_control
	office._first_clutch_global_cued_control = null
	if control == null or not is_instance_valid(control):
		return
	if control.has_meta("first_clutch_original_theme"):
		control.theme_type_variation = StringName(control.get_meta("first_clutch_original_theme"))
		control.remove_meta("first_clutch_original_theme")
	if control.has_meta("first_clutch_original_tooltip"):
		control.tooltip_text = String(control.get_meta("first_clutch_original_tooltip"))
		control.remove_meta("first_clutch_original_tooltip")
	if control.has_meta("first_clutch_original_modulate"):
		control.modulate = control.get_meta("first_clutch_original_modulate")
		control.remove_meta("first_clutch_original_modulate")


func _acknowledge_first_clutch_orders_handoff() -> void:
	if not office._flockwatch_open or not office._first_clutch_orders_handoff_pending():
		return
	office._first_clutch["orders_handoff_acknowledged"] = true
	var snapshot := office._simulation.snapshot()
	office._update_flockwatch_toggle()
	office._refresh_first_clutch_ui(snapshot)
	office._update_guidance(snapshot)
	office._save_campaign_checkpoint("first_clutch_orders_opened")


func _capture_first_clutch_preview(check_in := false) -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_first_clutch_preview", check_in)


func _capture_first_clutch_reinvestment_preview(
	show_orders_handoff := false,
	open_orders_dashboard := false,
) -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_first_clutch_reinvestment_preview", show_orders_handoff, open_orders_dashboard)


func _capture_first_clutch_playbook_preview() -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_first_clutch_playbook_preview")
