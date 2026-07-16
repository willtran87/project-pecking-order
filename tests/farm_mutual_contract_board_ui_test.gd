extends SceneTree

const ContractBoardUIScript := preload("res://features/office/farm_mutual_contract_board_ui.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var harness := Control.new()
	harness.name = "FarmMutualContractBoardUITestHarness"
	harness.size = Vector2(1280.0, 720.0)
	root.add_child(harness)

	var ui = ContractBoardUIScript.new()
	harness.add_child(ui)
	var selected: Array[StringName] = []
	var sign_requests: Array[Dictionary] = []
	var observed := {
		"decline_requests": 0,
		"continue_requests": 0,
	}
	ui.contract_selected.connect(func(offer_id: StringName) -> void: selected.append(offer_id))
	ui.contract_sign_requested.connect(func(offer_id: StringName, clause_id: StringName) -> void:
		sign_requests.append({"offer_id": offer_id, "clause_id": clause_id})
	)
	ui.decline_requested.connect(func() -> void: observed["decline_requests"] += 1)
	ui.continue_requested.connect(func() -> void: observed["continue_requests"] += 1)
	await process_frame
	await process_frame

	ui.apply_snapshot(_planning_snapshot())
	await process_frame
	await process_frame

	var panel := ui.find_child("FarmMutualContractBoardPanel", true, false) as PanelContainer
	var scroll := ui.find_child("ContractBoardScroll", true, false) as ScrollContainer
	var offer_buttons := ui.find_children("ContractFolder_*", "Button", true, false)
	var sign_button := ui.find_child("SignContractButton", true, false) as Button
	var continue_button := ui.find_child("OpenContractShiftButton", true, false) as Button
	var decline_button := ui.find_child("DeclineContractButton", true, false) as Button
	var terms_card := ui.find_child("ContractTermsCard", true, false) as PanelContainer
	var receipt_card := ui.find_child("ContractSignedReceiptCard", true, false) as PanelContainer
	var target_day := ui.find_child("ContractBoardTargetDay", true, false) as Label
	var season_strip := ui.find_child("ContractSeasonStrip", true, false) as PanelContainer
	var season_label := ui.find_child("ContractSeasonLabel", true, false) as Label
	var season_summary := ui.find_child("ContractSeasonSummary", true, false) as Label
	var accreditation_card := ui.find_child("ContractAccreditationCard", true, false) as PanelContainer
	var standing_rank := ui.find_child("ContractStandingRank", true, false) as Label
	var standing_points := ui.find_child("ContractStandingPoints", true, false) as Label
	var standing_next := ui.find_child("ContractStandingNextThreshold", true, false) as Label
	var standing_streak := ui.find_child("ContractStandingCleanStreak", true, false) as Label
	var service_coop := ui.find_child("ContractServiceCoopStatus", true, false) as Label
	var standing_seals := ui.find_children("ContractStandingSeal*", "PanelContainer", true, false)
	var planning_columns := ui.find_child("ContractPlanningColumns", true, false) as HFlowContainer
	var action_rail := ui.find_child("ContractBoardActionRail", true, false) as CenterContainer
	var negotiation_toggle := ui.find_child("ContractNegotiationToggle", true, false) as Button
	var negotiation_drawer := ui.find_child("ContractNegotiationDrawer", true, false) as PanelContainer

	_check(panel != null and panel.is_visible_in_tree(), "planning snapshot should reveal the Farm Mutual panel", failures)
	_check(scroll != null and scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "board should own an automatic vertical scroll path", failures)
	_check(scroll != null and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "responsive board should never depend on horizontal scrolling", failures)
	_check(target_day != null and target_day.text == "DAY 3", "board should name the exact next shift", failures)
	_check(season_strip != null and season_strip.is_visible_in_tree(), "seasonal planning should reveal one compact season strip", failures)
	_check(season_label != null and _contains_all(season_label.text, ["season", "hawk migration"]), "season strip should name the canonical current season", failures)
	_check(season_summary != null and _contains_all(season_summary.text, ["predator", "rush"]), "season strip should state its concise authored effect", failures)
	_check(accreditation_card != null and accreditation_card.is_visible_in_tree(), "accreditation standing should remain visible before a folder is opened", failures)
	_check(standing_rank != null and _contains_all(standing_rank.text, ["unlisted", "0 standing"]), "level 0 should print its exact unlisted rank and standing", failures)
	_check(standing_points != null and standing_points.text == "FARM MUTUAL STANDING  0", "standing should print its exact current points without a vague meter", failures)
	_check(standing_next != null and _contains_all(standing_next.text, ["next seal at 2", "2 more standing"]), "unlisted standing should disclose the exact Bronze threshold and remaining points", failures)
	_check(standing_streak != null and _contains_all(standing_streak.text, ["streak  0", "best 0"]), "accreditation should retain current and best clean binder streaks", failures)
	_check(standing_seals.size() == 3, "accreditation should render exactly three physical seal indicators", failures)
	_check(service_coop != null and _contains_all(service_coop.text, ["service coop", "0 / 3", "+0%", "success-only"]), "level 0 should disclose that no success-only Service Coop bonus is installed", failures)
	_check(offer_buttons.size() == 3, "board should render exactly three deterministic folders", failures)
	_check(sign_button != null and sign_button.disabled, "no folder selection should leave Sign disabled", failures)
	_check(continue_button != null and continue_button.disabled, "Continue should require an authoritative receipt", failures)
	_check(decline_button != null and not decline_button.visible, "decline should remain absent unless explicitly enabled", failures)
	_check(terms_card != null and not terms_card.visible, "exact terms should remain folded until one client folder is selected", failures)
	_check(receipt_card != null and not receipt_card.visible, "unsigned planning should not invent a receipt", failures)
	_check(planning_columns != null, "board should compose one responsive master/detail planning container", failures)
	_check(action_rail != null and action_rail.is_visible_in_tree(), "filing actions should live in one fixed in-panel rail", failures)
	_check(scroll != null and sign_button != null and not scroll.is_ancestor_of(sign_button), "Sign must remain outside the terms scroll surface", failures)
	_check(negotiation_toggle != null and not negotiation_toggle.visible and _shortcut_has_key(negotiation_toggle, KEY_N), "negotiation should remain contextual until a binder is opened", failures)
	_check(negotiation_drawer != null and not negotiation_drawer.visible, "negotiation details should stay folded until requested", failures)

	for index: int in range(offer_buttons.size()):
		var button := offer_buttons[index] as Button
		_check(button != null and button.focus_mode == Control.FOCUS_ALL, "folder %d should be keyboard focusable" % (index + 1), failures)
		_check(button != null and button.custom_minimum_size.y >= 116.0, "folder %d should keep a generous selection target" % (index + 1), failures)
		_check(button != null and _shortcut_has_key(button, [KEY_1, KEY_2, KEY_3][index]), "folder %d should retain its deterministic numeric shortcut" % (index + 1), failures)
	_check(
		_contains_all((offer_buttons[0] as Button).text, ["homestead binder", "nest 4", "rush 1", "+$10.00", "-$5.00"]),
		"folder summary should expose lane mix, rush volume, premium, and breach without opening it",
		failures,
	)

	# Numeric selection is presentation-only. It opens the complete terms and moves
	# Enter focus to the explicit signature action without signing on selection.
	_press_key(KEY_2)
	await process_frame
	await process_frame
	var terms_title := ui.find_child("ContractTermsTitle", true, false) as Label
	var lane_mix := ui.find_child("ContractLaneMix", true, false) as Label
	var arrivals := ui.find_child("ContractRushSchedule", true, false) as Label
	var success := ui.find_child("ContractSuccessCondition", true, false) as Label
	var premium := ui.find_child("ContractPremium", true, false) as Label
	var breach := ui.find_child("ContractBreachCharge", true, false) as Label
	var reserve := ui.find_child("ContractBreachReserve", true, false) as Label
	var capacity := ui.find_child("ContractCapacityFit", true, false) as Label
	var reason := ui.find_child("ContractTermReason", true, false) as Label
	_check(selected == [&"predator_watch_pool"], "2 should select only the second stable offer ID", failures)
	_check(sign_requests.is_empty(), "numeric folder selection must never authorize a liability", failures)
	_check(terms_card != null and terms_card.visible, "selection should open one complete Terms card", failures)
	_check(sign_button != null and not sign_button.disabled and _shortcut_has_key(sign_button, KEY_ENTER), "selected affordable folder should enable explicit Enter signing", failures)
	_check(negotiation_toggle != null and negotiation_toggle.visible, "an opened binder with authored clauses should reveal its N negotiation control", failures)
	_check(root.gui_get_focus_owner() == sign_button, "selection should hand focus to Sign for the safe second step", failures)
	_check(terms_title != null and terms_title.text == "PREDATOR WATCH POOL", "Terms card should retain the full binder name", failures)
	_check(lane_mix != null and _contains_all(lane_mix.text, ["nest 1", "predator 5"]), "Terms card should disclose the exact lane mix", failures)
	_check(arrivals != null and _contains_all(arrivals.text, ["8:00 am", "10:00 am", "rush", "due 12:00 pm"]), "Terms card should disclose exact physical arrival and deadline times", failures)
	_check(success != null and _contains_all(success.text, ["5 sound or golden", "service windows"]), "Terms card should print the authoritative success condition", failures)
	_check(premium != null and _contains_all(premium.text, ["base $16.00", "service coop l0 $0.00", "total $16.00"]), "Terms card should itemize the level-0 premium instead of hiding it in one total", failures)
	_check(breach != null and breach.text == "-$8.00", "Terms card should print the signed negative breach charge", failures)
	_check(reserve != null and _contains_all(reserve.text, ["$8.00 held", "$42.00 spendable"]), "Terms card should explain the liability reserve's post-signing fund", failures)
	_check(capacity != null and _contains_all(capacity.text, ["12 open", "24 roosts", "6 folders", "need 24", "flock fit", "5 active hens", "need 5", "ready"]), "Terms card should connect both archive and staffing fit to the binder", failures)
	_check(terms_card != null and _contains_all(terms_card.tooltip_text, ["predator watch pool", "base $16.00", "total $16.00", "-$8.00", "10:00 am", "5 active hens", "5 required"]), "Terms tooltip should repeat every economic and staffing commitment", failures)

	# N progressively discloses full effective rider preflights. Space selects only
	# the focused rider, while R deterministically restores the standard variant.
	_press_key(KEY_N)
	await process_frame
	await process_frame
	var expedited := ui.find_child("ContractClause_expedited_hatch_rider", true, false) as Button
	var specialist := ui.find_child("ContractClause_specialist_roost_endorsement", true, false) as Button
	var effective_summary := ui.find_child("ContractEffectiveTermsSummary", true, false) as Label
	_check(negotiation_drawer != null and negotiation_drawer.visible, "N should open the selected binder's negotiation drawer", failures)
	_check(expedited != null and expedited.focus_mode == Control.FOCUS_ALL, "expedited rider should be keyboard focusable", failures)
	_check(specialist != null and _contains_all(specialist.text, ["specialist roost", "premium", "breach"]), "every rider card should disclose its full effective economics", failures)
	if expedited != null:
		expedited.grab_focus()
		_press_key(KEY_SPACE)
		await process_frame
		await process_frame
	_check(ui.presentation_state().get("selected_clause_id", "") == "expedited_hatch_rider", "Space should select exactly the focused negotiated rider", failures)
	_check(premium != null and _contains_all(premium.text, ["season", "rider", "total $20.00"]), "selected rider should replace the detail pane with its authoritative premium breakdown", failures)
	_check(breach != null and breach.text == "-$12.00", "selected rider should replace the breach total with its effective value", failures)
	_check(effective_summary != null and _contains_all(effective_summary.text, ["files 6", "rush 3", "premium $20.00", "breach -$12.00"]), "drawer should summarize the exact selected effective preflight", failures)
	var selected_effective := ui.presentation_state().get("effective_terms", {}) as Dictionary
	_check(StringName(selected_effective.get("clause_id", &"")) == &"expedited_hatch_rider" and int(selected_effective.get("total_claims", 0)) == 6, "presentation diagnostics should publish the selected full effective terms", failures)
	_press_key(KEY_R)
	await process_frame
	await process_frame
	_check(ui.presentation_state().get("selected_clause_id", "") == "standard_terms", "R should restore the standard variant without changing binders", failures)
	_check(premium != null and _contains_all(premium.text, ["base $16.00", "total $16.00"]), "standard reset should restore the base selected terms", failures)

	_press_key(KEY_ENTER)
	await process_frame
	await process_frame
	_check(
		sign_requests == [{"offer_id": &"predator_watch_pool", "clause_id": &"standard_terms"}],
		"Enter should emit exactly one authoritative offer-and-clause sign intent",
		failures,
	)
	_check(sign_button != null and sign_button.disabled and "AWAITING RECEIPT" in sign_button.text, "sign intent should lock against replay while awaiting authority", failures)
	_check(continue_button != null and continue_button.disabled, "sign intent alone must not unlock Continue", failures)
	_press_key(KEY_ENTER)
	await process_frame
	_check(sign_requests.size() == 1, "repeated Enter before a receipt must not emit a duplicate signature", failures)

	# Applying the canonical signed active contract is the only standard path that
	# produces a receipt and unlocks the separate C continuation action.
	var signed_snapshot := _planning_snapshot()
	var signed_board := signed_snapshot["contract_board"] as Dictionary
	signed_board["active"] = _signed_predator_contract()
	signed_board["offers"] = _planning_offers_after_signature()
	ui.apply_snapshot(signed_snapshot)
	await process_frame
	await process_frame
	var receipt_title := ui.find_child("ContractSignedReceiptTitle", true, false) as Label
	var receipt_body := ui.find_child("ContractSignedReceiptBody", true, false) as Label
	_check(receipt_card != null and receipt_card.visible, "signed active contract should reveal an explicit receipt", failures)
	_check(receipt_title != null and _contains_all(receipt_title.text, ["bound", "predator pool", "signed receipt"]), "receipt should identify the bound term", failures)
	_check(receipt_body != null and _contains_all(receipt_body.text, ["fm-0003", "base $16.00", "service coop l0 $0.00", "total $16.00", "archive fit", "12 open of 24", "flock fit", "5 active hens", "need 5", "ready", "$8.00", "5 of 6"]), "receipt should preserve ID and itemize premium, archive fit, staffing fit, reserve, and target", failures)
	_check(sign_button != null and not sign_button.visible, "signed receipt should retire the signature action", failures)
	_check(continue_button != null and not continue_button.disabled and "OPEN DAY 3 BRIEFING" in continue_button.text, "only a signed receipt should enable explicit continuation", failures)
	_check(root.gui_get_focus_owner() == continue_button, "signed receipt should focus the next safe action", failures)
	_press_key(KEY_C)
	await process_frame
	_check(int(observed["continue_requests"]) == 1, "C should emit one continuation only after the receipt exists", failures)

	# Earned Bronze and Service Coop level 1 must remain discrete, exact, and
	# economic: one physical seal and a success-only 50% premium line item.
	var bronze_snapshot := _bronze_planning_snapshot()
	ui.apply_snapshot(bronze_snapshot)
	await process_frame
	_press_key(KEY_2)
	await process_frame
	_check(standing_rank != null and _contains_all(standing_rank.text, ["bronze", "2 standing"]), "earned Bronze should replace UNLISTED with the exact standing rank", failures)
	_check(standing_next != null and _contains_all(standing_next.text, ["next seal at 6", "4 more standing"]), "Bronze should disclose the exact Silver threshold and points remaining", failures)
	_check(standing_streak != null and _contains_all(standing_streak.text, ["streak  1", "best 2"]), "Bronze should preserve current and best clean streaks", failures)
	_check(
		standing_seals.size() == 3
		and _contains_all(_descendant_copy(standing_seals[0]), ["sealed", "bronze"])
		and _contains_all(_descendant_copy(standing_seals[1]), ["open", "silver", "6"])
		and _contains_all(_descendant_copy(standing_seals[2]), ["open", "gold", "12"]),
		"Bronze should fill one physical seal while Silver and Gold remain exact open thresholds",
		failures,
	)
	_check(service_coop != null and _contains_all(service_coop.text, ["service coop", "1 / 3", "+50%", "success-only"]), "installed Service Coop level 1 should show its exact success-only bonus", failures)
	_check(premium != null and _contains_all(premium.text, ["base $16.00", "service coop l1 $8.00", "total $24.00"]), "Bronze selected terms should itemize base plus Service Coop bonus into the total", failures)

	var bronze_signed_snapshot := _bronze_planning_snapshot()
	var bronze_signed_board := bronze_signed_snapshot["contract_board"] as Dictionary
	bronze_signed_board["active"] = _signed_predator_contract(true)
	bronze_signed_board["offers"] = _planning_offers_after_signature(true)
	ui.apply_snapshot(bronze_signed_snapshot)
	await process_frame
	_check(receipt_body != null and _contains_all(receipt_body.text, ["base $16.00", "service coop l1 $8.00", "total $24.00", "archive fit", "flock fit", "5 active hens", "ready"]), "signed Bronze receipt should freeze the exact premium, archive fit, and staffing fit", failures)

	# A client cooldown is an authoritative preflight failure, not a generic
	# capacity hold, and must state both the day and supplied reason.
	var cooldown_snapshot := _bronze_planning_snapshot()
	var cooldown_board := cooldown_snapshot["contract_board"] as Dictionary
	var cooldown_offer := (cooldown_board["offers"] as Array)[1] as Dictionary
	cooldown_offer["can_sign"] = false
	cooldown_offer["on_cooldown"] = true
	cooldown_offer["cooldown_until_day"] = 4
	cooldown_offer["reason"] = "Red Comb Agricultural is cooling its client file through Day 4 after a breached term."
	ui.apply_snapshot(cooldown_snapshot)
	await process_frame
	_press_key(KEY_2)
	await process_frame
	var cooldown_folder := ui.find_child("ContractFolder_predator_watch_pool", true, false) as Button
	_check(sign_button != null and sign_button.disabled, "authoritative client cooldown should keep the signature action disabled", failures)
	_check(reason != null and _contains_all(reason.text, ["client cooldown", "day 4", "red comb", "breached term"]), "selected cooldown should print its authoritative day and reason", failures)
	_check(cooldown_folder != null and _contains_all(cooldown_folder.text, ["client cooldown", "through day 4"]), "closed client folder should advertise cooldown before selection", failures)
	_check(cooldown_folder != null and _contains_all(cooldown_folder.tooltip_text, ["client cooldown", "day 4", "red comb", "breached term"]), "keyboard focus should expose the same authoritative cooldown reason", failures)

	# Unavailable folders remain inspectable: selection prints the hold reason but
	# never makes Sign focusable. This avoids hiding exact terms from keyboard use.
	ui.apply_snapshot(_planning_snapshot())
	await process_frame
	_press_key(KEY_3)
	await process_frame
	reason = ui.find_child("ContractTermReason", true, false) as Label
	_check(ui.selected_contract_id() == &"exceptions_retention_covenant", "3 should still inspect an unavailable folder", failures)
	_check(sign_button != null and sign_button.disabled, "held offer should not become signable", failures)
	_check(reason != null and _contains_all(reason.text, ["signature held", "2 more empty file roosts"]), "held offer should print its authoritative reason", failures)

	var closed_snapshot := _planning_snapshot()
	(closed_snapshot["contract_board"] as Dictionary)["planning_open"] = false
	ui.apply_snapshot(closed_snapshot)
	await process_frame
	_press_key(KEY_1)
	await process_frame
	_check(sign_button != null and sign_button.disabled, "top-level closed planning should fail closed even if an embedded offer is stale-signable", failures)
	_check(reason != null and _contains_all(reason.text, ["signature held", "planning window is not open"]), "closed planning should explain the top-level hold", failures)

	# Decline is an opt-in caller capability. Requesting it does not itself unlock
	# Continue; an explicit accepted decline receipt would be required.
	var decline_snapshot := _planning_snapshot()
	(decline_snapshot["contract_board"] as Dictionary)["decline_available"] = true
	ui.apply_snapshot(decline_snapshot)
	await process_frame
	await process_frame
	_check(decline_button != null and decline_button.visible and not decline_button.disabled, "explicit decline capability should reveal one clear secondary action", failures)
	decline_button.pressed.emit()
	await process_frame
	_check(int(observed["decline_requests"]) == 1, "decline button should emit one caller intent", failures)
	_check(continue_button != null and continue_button.disabled, "decline intent should await its own accepted receipt", failures)

	# A surveyed but unbuilt negotiation room keeps optional riders inspectable and
	# fail-closed. Standard terms remain available even if stale data says otherwise.
	var locked_snapshot := _planning_snapshot()
	var locked_board := locked_snapshot["contract_board"] as Dictionary
	locked_board["negotiation_room"] = {
		"owned": false,
		"unlocked": false,
		"reason": "Reach Gold standing and commission the negotiation room.",
		"max_clause_slots": 1,
	}
	for offer_value: Variant in locked_board["offers"] as Array:
		var locked_offer := offer_value as Dictionary
		for option_value: Variant in locked_offer.get("clause_options", []) as Array:
			var option := option_value as Dictionary
			if StringName(option.get("clause_id", &"")) == &"standard_terms":
				option["clause_available"] = false # Standard must ignore stale false data.
				continue
			option["clause_available"] = false
			option["can_sign"] = false
			option["reason"] = "Commission the Farm Mutual Negotiation Room before signing this clause."
	ui.apply_snapshot(locked_snapshot)
	await process_frame
	_press_key(KEY_2)
	await process_frame
	_press_key(KEY_N)
	await process_frame
	expedited = ui.find_child("ContractClause_expedited_hatch_rider", true, false) as Button
	if expedited != null:
		expedited.grab_focus()
		_press_key(KEY_SPACE)
		await process_frame
	_check(ui.presentation_state().get("selected_clause_id", "") == "standard_terms", "locked optional riders must not replace the always-available standard draft", failures)
	_check(sign_button != null and not sign_button.disabled, "standard terms should remain signable when the optional room is held", failures)

	# Older saves have neither a season nor authored clause options. They retain the
	# original one-folder/one-signature flow and never expose an empty drawer.
	var legacy_snapshot := _planning_snapshot()
	var legacy_board := legacy_snapshot["contract_board"] as Dictionary
	legacy_board.erase("season")
	legacy_board.erase("negotiation_room")
	for offer_value: Variant in legacy_board["offers"] as Array:
		(offer_value as Dictionary).erase("clause_options")
	ui.apply_snapshot(legacy_snapshot)
	await process_frame
	_press_key(KEY_1)
	await process_frame
	var legacy_state := ui.presentation_state()
	_check(season_strip != null and not season_strip.visible, "legacy snapshots should not invent a seasonal strip", failures)
	_check(negotiation_toggle != null and not negotiation_toggle.visible and not negotiation_drawer.visible, "legacy snapshots should not invent negotiation controls", failures)
	_check(legacy_state.get("selected_clause_id", "") == "standard_terms" and not bool(legacy_state.get("negotiation_open", true)), "legacy selection should deterministically normalize to closed standard terms", failures)
	_check(premium != null and _contains_all(premium.text, ["base $10.00", "total $10.00"]), "legacy folders should preserve their original exact economics", failures)

	# The component owns its ScrollContainer and recomputes panel/card minima from
	# the available viewport, so every supported wrapper size remains contained.
	for viewport_size: Vector2 in [
		Vector2(2560.0, 1600.0),
		Vector2(1440.0, 900.0),
		Vector2(390.0, 844.0),
	]:
		harness.size = viewport_size
		await process_frame
		await process_frame
		var panel_rect := panel.get_global_rect() if panel != null else Rect2()
		_check(panel_rect.position.x >= -0.5, "%s panel should not clip left" % viewport_size, failures)
		_check(panel_rect.end.x <= viewport_size.x + 0.5, "%s panel should not clip right (rect %s)" % [viewport_size, panel_rect], failures)
		_check(scroll != null and scroll.get_h_scroll_bar().max_value <= scroll.size.x + 0.5, "%s board should not create horizontal overflow" % viewport_size, failures)
		if viewport_size.x < 720.0:
			_check(panel != null and panel.custom_minimum_size.x <= viewport_size.x - 52.0 + 0.5, "portrait panel should preserve the scrollbar gutter", failures)
			_check(scroll != null and scroll.get_v_scroll_bar().max_value > scroll.size.y, "portrait board should expose vertical scrolling for complete terms", failures)

	ui.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("FARM_MUTUAL_CONTRACT_BOARD_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARM_MUTUAL_CONTRACT_BOARD_UI_TEST_PASSED folders=3 season=compact clauses=N+Space+R terms=effective sign=offer+clause receipt=continue-gate legacy=standard responsive=2560+1440+390")
	quit(0)


func _planning_snapshot() -> Dictionary:
	return {
		"contract_board": {
			"unlocked": true,
			"planning_open": true,
			"target_day": 3,
			"claim_capacity": 24,
			"claims_outstanding": 12,
			"active_staff_count": 5,
			"season": {
				"id": &"summer_hawk_migration",
				"label": "SUMMER HAWK MIGRATION",
				"summary": "Predator folders arrive in tighter rush windows.",
				"effects": {
					"predator_loss_demand_basis_points": 2500,
					"rush_window_minutes_delta": -60,
				},
			},
			"negotiation_room": {
				"owned": true,
				"unlocked": true,
				"reason": "",
				"max_clause_slots": 1,
				"clause_limit": 1,
			},
			"standing": _standing_record(0, &"unlisted", "UNLISTED", 2, 2, 0, 0),
			"accreditation": _accreditation_record(0, 0),
			"offers": _planning_offers(),
			"active": {},
			"last_result": {},
		}
	}


func _bronze_planning_snapshot() -> Dictionary:
	var snapshot := _planning_snapshot()
	var board := snapshot["contract_board"] as Dictionary
	board["standing"] = _standing_record(2, &"bronze", "BRONZE", 6, 4, 1, 2)
	board["accreditation"] = _accreditation_record(1, 5000)
	for offer_value: Variant in board["offers"] as Array:
		var offer := offer_value as Dictionary
		_apply_test_service_coop(offer, 1, 5000)
		var options_value: Variant = offer.get("clause_options", [])
		if options_value is Array:
			for option_value: Variant in options_value as Array:
				if option_value is Dictionary:
					_apply_test_service_coop(option_value as Dictionary, 1, 5000)
	return snapshot


func _standing_record(
	points: int,
	rank: StringName,
	rank_label: String,
	next_threshold: int,
	points_to_next: int,
	clean_streak: int,
	best_clean_streak: int,
) -> Dictionary:
	return {
		"points": points,
		"rank": rank,
		"rank_label": rank_label,
		"next_threshold": next_threshold,
		"points_to_next": points_to_next,
		"clean_streak": clean_streak,
		"best_clean_streak": best_clean_streak,
		"seals": [
			{"id": &"bronze", "label": "BRONZE CLIENT SEAL", "threshold": 2, "earned": points >= 2},
			{"id": &"silver", "label": "SILVER SERVICE SEAL", "threshold": 6, "earned": points >= 6},
			{"id": &"gold", "label": "GOLD ACCOUNT SEAL", "threshold": 12, "earned": points >= 12},
		],
	}


func _accreditation_record(level: int, bonus_basis_points: int) -> Dictionary:
	return {
		"facility_id": &"farm_mutual_service_coop",
		"level": level,
		"max_level": 3,
		"premium_bonus_basis_points": bonus_basis_points,
		"premium_bonus_percent": roundi(bonus_basis_points / 100.0),
		"current_maintenance_cents": level * 300,
		"next_level": mini(3, level + 1),
		"next_required_standing": [2, 6, 12][mini(2, level)],
		"next_required_claim_capacity": [24, 30, 36][mini(2, level)],
		"next_required_active_staff": [4, 5, 6][mini(2, level)],
		"status": {},
	}


func _planning_offers() -> Array[Dictionary]:
	var offers: Array[Dictionary] = [
		_offer(
			&"homestead_stability_binder",
			"HOMESTEAD STABILITY BINDER",
			"HOMESTEAD BINDER",
			"LOW FENCE FARM MUTUAL",
			{"nest_damage": 4, "predator_loss": 1},
			[
				_batch("8:00 AM", "10:00 AM", {"nest_damage": 3}, false),
				_batch("10:00 AM", "12:00 PM", {"nest_damage": 1, "predator_loss": 1}, true),
			],
			1,
			4,
			5,
			1000,
			500,
			500,
			4500,
			true,
			"",
		),
		_offer(
			&"predator_watch_pool",
			"PREDATOR WATCH POOL",
			"PREDATOR POOL",
			"RED COMB AGRICULTURAL",
			{"nest_damage": 1, "predator_loss": 5},
			[
				_batch("8:00 AM", "10:00 AM", {"predator_loss": 3}, false),
				_batch("10:00 AM", "12:00 PM", {"nest_damage": 1, "predator_loss": 2}, true),
			],
			2,
			5,
			6,
			1600,
			800,
			800,
			4200,
			true,
			"",
		),
		_offer(
			&"exceptions_retention_covenant",
			"EXCEPTIONS RETENTION COVENANT",
			"EXCEPTIONS COVENANT",
			"GILT NEST UNDERWRITERS",
			{"nest_damage": 1, "predator_loss": 1, "appeals": 4},
			[
				_batch("8:00 AM", "12:00 PM", {"appeals": 3}, false),
				_batch("1:00 PM", "5:00 PM", {"nest_damage": 1, "predator_loss": 1, "appeals": 1}, true),
			],
			3,
			5,
			6,
			2400,
			1200,
			1200,
			3800,
			false,
			"2 more empty file roosts required before these folders can be reserved.",
		),
	]
	for offer in offers:
		offer["clause_options"] = _test_clause_options(offer)
	return offers


func _planning_offers_after_signature(bronze: bool = false) -> Array[Dictionary]:
	var offers := (
		((_bronze_planning_snapshot()["contract_board"] as Dictionary)["offers"] as Array).duplicate(true)
		if bronze else
		_planning_offers()
	)
	for offer in offers:
		offer["can_sign"] = false
		offer["reason"] = "One Farm Mutual binder is already signed for Day 3."
		var options_value: Variant = offer.get("clause_options", [])
		if options_value is Array:
			for option_value: Variant in options_value as Array:
				if option_value is Dictionary:
					var option := option_value as Dictionary
					option["can_sign"] = false
					option["reason"] = offer["reason"]
	return offers


func _offer(
	id: StringName,
	name: String,
	short_name: String,
	client: String,
	lane_mix: Dictionary,
	arrival_batches: Array[Dictionary],
	rush_claims: int,
	required_completed: int,
	total_claims: int,
	premium_cents: int,
	breach_cents: int,
	breach_reserve_cents: int,
	spendable_after_reserve_cents: int,
	can_sign: bool,
	reason: String,
) -> Dictionary:
	return {
		"id": id,
		"offer_id": id,
		"name": name,
		"short_name": short_name,
		"client": client,
		"tagline": "Disclosed farm-insurance work with deadlines that management calls opportunity.",
		"target_day": 3,
		"deadline_day": 3,
		"required_claim_capacity": 24,
		"required_completed": required_completed,
		"total_claims": total_claims,
		"rush_claims": rush_claims,
		"base_premium_cents": premium_cents,
		"service_coop_level_at_signing": 0,
		"service_coop_bonus_cents": 0,
		"premium_bonus_basis_points": 0,
		"premium_cents": premium_cents,
		"breach_cents": breach_cents,
		"breach_reserve_cents": breach_reserve_cents,
		"spendable_after_reserve_cents": spendable_after_reserve_cents,
		"available_claim_slots": 12,
		"required_active_staff": 4 if id == &"homestead_stability_binder" else 5 if id == &"predator_watch_pool" else 6,
		"active_staff_count": 5,
		"active_staff_shortfall": 0 if id != &"exceptions_retention_covenant" else 1,
		"staffing_ready": id != &"exceptions_retention_covenant",
		"on_cooldown": false,
		"cooldown_until_day": 0,
		"lane_mix": lane_mix,
		"arrival_batches": arrival_batches,
		"success_required": "%d sound or golden folders delivered inside their disclosed service windows." % required_completed,
		"can_sign": can_sign,
		"reason": reason,
	}


func _test_clause_options(offer: Dictionary) -> Array[Dictionary]:
	var standard := offer.duplicate(true)
	standard.erase("clause_options")
	standard.merge({
		"clause_id": &"standard_terms",
		"clause_label": "STANDARD TERMS",
		"clause_summary": "Keep Farm Mutual's seasonal binder exactly as quoted.",
		"clause_category": &"standard",
		"clause_available": true,
		"season_premium_delta_cents": 0,
		"clause_premium_delta_cents": 0,
		"market_premium_cents": int(standard.get("base_premium_cents", 0)),
	}, true)

	var expedited := standard.duplicate(true)
	var expedited_market_premium := _basis_point_total(
		int(standard.get("market_premium_cents", standard.get("premium_cents", 0))),
		2500,
	)
	var expedited_breach := _basis_point_total(int(standard.get("breach_cents", 0)), 5000)
	expedited.merge({
		"clause_id": &"expedited_hatch_rider",
		"clause_label": "EXPEDITED HATCH RIDER",
		"clause_summary": "Tighten every service window by one hour and mark one additional standard folder as rush work.",
		"clause_category": &"schedule",
		"clause_available": true,
		"rush_claims": mini(
			int(standard.get("total_claims", 0)),
			int(standard.get("rush_claims", 0)) + 1,
		),
		"service_window_minutes_delta": -60,
		"clause_premium_delta_cents": expedited_market_premium - int(standard.get("market_premium_cents", 0)),
		"market_premium_cents": expedited_market_premium,
		"premium_cents": expedited_market_premium,
		"breach_cents": expedited_breach,
		"breach_reserve_cents": expedited_breach,
		"spendable_after_reserve_cents": _test_fund_before_reserve(standard) - expedited_breach,
	}, true)

	var specialist := standard.duplicate(true)
	var specialist_market_premium := _basis_point_total(
		int(standard.get("market_premium_cents", standard.get("premium_cents", 0))),
		3500,
	)
	var specialist_breach := _basis_point_total(int(standard.get("breach_cents", 0)), 2500)
	specialist.merge({
		"clause_id": &"specialist_roost_endorsement",
		"clause_label": "SPECIALIST ROOST ENDORSEMENT",
		"clause_summary": "Convert every folder to this binder's dominant claim lane.",
		"clause_category": &"routing",
		"clause_available": true,
		"lane_mix": _dominant_lane_mix(standard.get("lane_mix", {}) as Dictionary),
		"clause_premium_delta_cents": specialist_market_premium - int(standard.get("market_premium_cents", 0)),
		"market_premium_cents": specialist_market_premium,
		"premium_cents": specialist_market_premium,
		"breach_cents": specialist_breach,
		"breach_reserve_cents": specialist_breach,
		"spendable_after_reserve_cents": _test_fund_before_reserve(standard) - specialist_breach,
	}, true)

	var rested := standard.duplicate(true)
	var rested_market_premium := _basis_point_total(
		int(standard.get("market_premium_cents", standard.get("premium_cents", 0))),
		4000,
	)
	var rested_breach := _basis_point_total(int(standard.get("breach_cents", 0)), 4000)
	rested.merge({
		"clause_id": &"rested_flock_warranty",
		"clause_label": "RESTED FLOCK WARRANTY",
		"clause_summary": "Earn the richer binder only if closing flock welfare is at least 72.",
		"clause_category": &"welfare",
		"clause_available": true,
		"required_welfare": 72,
		"welfare_minimum": 72,
		"welfare_condition": "Close the shift with flock welfare at 72 or above.",
		"clause_premium_delta_cents": rested_market_premium - int(standard.get("market_premium_cents", 0)),
		"market_premium_cents": rested_market_premium,
		"premium_cents": rested_market_premium,
		"breach_cents": rested_breach,
		"breach_reserve_cents": rested_breach,
		"spendable_after_reserve_cents": _test_fund_before_reserve(standard) - rested_breach,
	}, true)
	return [standard, expedited, specialist, rested]


func _apply_test_service_coop(record: Dictionary, level: int, basis_points: int) -> void:
	var market_premium := int(record.get(
		"market_premium_cents",
		record.get("premium_cents", record.get("base_premium_cents", 0)),
	))
	var bonus := roundi(float(market_premium * basis_points) / 10_000.0)
	record["service_coop_level_at_signing"] = level
	record["premium_bonus_basis_points"] = basis_points
	record["service_coop_bonus_cents"] = bonus
	record["premium_cents"] = market_premium + bonus


func _basis_point_total(base_cents: int, delta_basis_points: int) -> int:
	return base_cents + roundi(float(base_cents * delta_basis_points) / 10_000.0)


func _test_fund_before_reserve(record: Dictionary) -> int:
	return int(record.get("spendable_after_reserve_cents", 0)) + int(record.get("breach_cents", 0))


func _dominant_lane_mix(lane_mix: Dictionary) -> Dictionary:
	var dominant_lane := &"nest_damage"
	var dominant_count := -1
	var total := 0
	for lane_value: Variant in lane_mix:
		var count := maxi(0, int(lane_mix[lane_value]))
		total += count
		if count > dominant_count:
			dominant_lane = StringName(lane_value)
			dominant_count = count
	return {dominant_lane: total}


func _batch(time: String, deadline: String, lane_mix: Dictionary, rush: bool) -> Dictionary:
	var count := 0
	for value: Variant in lane_mix.values():
		count += int(value)
	return {
		"time": time,
		"deadline_time": deadline,
		"lane_mix": lane_mix,
		"count": count,
		"rush": rush,
	}


func _signed_predator_contract(bronze: bool = false) -> Dictionary:
	var offers := (
		(_bronze_planning_snapshot()["contract_board"] as Dictionary)["offers"] as Array
		if bronze else
		_planning_offers()
	)
	var offer := offers[1] as Dictionary
	var options := offer.get("clause_options", []) as Array
	var contract := (
		(options[0] as Dictionary).duplicate(true)
		if not options.is_empty() else
		offer.duplicate(true)
	)
	contract.erase("clause_options")
	contract.merge({
		"contract_id": "FM-0003-PREDATOR_WATCH_POOL",
		"offer_id": "predator_watch_pool",
		"id": "predator_watch_pool",
		"clause_id": &"standard_terms",
		"clause_label": "STANDARD TERMS",
		"clause_category": &"standard",
		"season_id": &"summer_hawk_migration",
		"season_label": "SUMMER HAWK MIGRATION",
		"status": "signed",
		"signed_day": 3,
		"target_day": 3,
	}, true)
	return contract


func _press_key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	Input.parse_input_event(event)


func _shortcut_has_key(button: Button, keycode: Key) -> bool:
	if button == null or button.shortcut == null:
		return false
	for event: InputEvent in button.shortcut.events:
		if event is InputEventKey and (event as InputEventKey).keycode == keycode:
			return true
	return false


func _contains_all(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment in fragments:
		if not normalized.contains(fragment.to_lower()):
			return false
	return true


func _descendant_copy(parent: Node) -> String:
	var copy := ""
	for child in parent.find_children("*", "Label", true, false):
		copy += " " + String((child as Label).text)
	return copy


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
