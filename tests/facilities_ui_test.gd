extends SceneTree

const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")
const FACILITY_ID := &"candling_rework_bay"
const PACKING_ID := &"farmer_brand_packing_annex"
const SERVICE_COOP_ID := &"farm_mutual_service_coop"
const TRAINING_ROOST_ID := &"training_roost"
const ROOSTER_OPERATIONS_ID := &"rooster_operations_office"
const IT_COOP_ID := &"it_coop"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var harness := Control.new()
	harness.name = "FacilitiesUITestHarness"
	harness.size = Vector2(320.0, 520.0)
	root.add_child(harness)
	var ledger_scroll := ScrollContainer.new()
	ledger_scroll.name = "FacilitiesLedgerScroll"
	ledger_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ledger_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ledger_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	harness.add_child(ledger_scroll)
	var staffing_ui := RoostStaffingUIScript.new() as RoostStaffingUI
	staffing_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ledger_scroll.add_child(staffing_ui)
	await process_frame

	var requested: Array[StringName] = []
	var blueprint_requests := {"count": 0}
	staffing_ui.facility_purchase_requested.connect(
		func(facility_id: StringName) -> void: requested.append(facility_id)
	)
	staffing_ui.capital_blueprint_requested.connect(func() -> void: blueprint_requests["count"] += 1)
	staffing_ui.apply_snapshot(_snapshot_with(_facility_record()))
	await process_frame

	var section := staffing_ui.find_child("FacilitiesSection", true, false) as VBoxContainer
	var inline_toggle := staffing_ui.find_child("InlineCapitalFileToggle", true, false) as Button
	var facility_list := staffing_ui.find_child("FacilityCatalog", true, false) as VBoxContainer
	_check(
		facility_list != null and not facility_list.visible,
		"the long legacy capital card list should stay collapsed behind Capital Blueprint by default",
		failures,
	)
	_check(
		inline_toggle != null and inline_toggle.text == "OPEN",
		"a compact, keyboard-focusable inline fallback should remain available",
		failures,
	)
	if inline_toggle != null:
		inline_toggle.pressed.emit()
	await process_frame
	_check(
		facility_list != null and facility_list.visible,
		"the explicit inline fallback should reveal the legacy capital cards",
		failures,
	)
	var section_title := staffing_ui.find_child("CapitalExpansionsTitle", true, false) as Label
	var card := staffing_ui.find_child("FacilityCard_candling_rework_bay", true, false) as PanelContainer
	var purchase := staffing_ui.find_child("PurchaseFacility_candling_rework_bay", true, false) as Button
	var benefits := staffing_ui.find_child("FacilityBenefits_candling_rework_bay", true, false) as Label
	var projection := staffing_ui.find_child("FacilityProjection_candling_rework_bay", true, false) as Label
	var costs := staffing_ui.find_child("FacilityCosts_candling_rework_bay", true, false) as HFlowContainer
	var status := staffing_ui.find_child("FacilityStatus_candling_rework_bay", true, false) as Label
	var details_toggle := staffing_ui.find_child("FacilityDetailsToggle_candling_rework_bay", true, false) as Button
	var details := staffing_ui.find_child("FacilityDetails_candling_rework_bay", true, false) as VBoxContainer
	var blueprint := staffing_ui.find_child("OpenCapitalBlueprint", true, false) as Button
	var needs_action := staffing_ui.find_child("CapitalNeedsActionHeading", true, false) as Label
	var at_a_glance := staffing_ui.find_child("CapitalAtAGlanceHeading", true, false) as Label
	var capital_details := staffing_ui.find_child("CapitalDetailsHeading", true, false) as Label
	_check(section != null and section.visible, "a non-empty facility catalog should reveal its embedded section", failures)
	_check(section_title != null and section_title.text == "DIRECT REQUISITIONS", "the duplicate inline catalog should identify itself as the compact action fallback", failures)
	_check(
		blueprint != null
		and blueprint.is_visible_in_tree()
		and needs_action != null and needs_action.text == "NEEDS ACTION"
		and at_a_glance != null and at_a_glance.text == "AT A GLANCE"
		and capital_details != null and capital_details.text == "DETAILS",
		"Capital should lead with its canonical Blueprint and a stable Needs Action / At a Glance / Details hierarchy",
		failures,
	)
	if blueprint != null:
		blueprint.pressed.emit()
	_check(int(blueprint_requests["count"]) == 1, "the canonical Blueprint action should retain its original signal route", failures)
	_check(card != null, "Candling & Rework Bay should render as a named facility card", failures)
	_check(purchase != null and not purchase.disabled, "an affordable unlocked review requisition should be actionable", failures)
	_check(purchase != null and purchase.is_visible_in_tree(), "the direct purchase action should remain visible while duplicate comparison details are collapsed", failures)
	_check(details_toggle != null and details != null and details_toggle.focus_mode == Control.FOCUS_ALL and not details.visible, "each direct requisition should begin as a compact focusable summary", failures)
	if details_toggle != null:
		details_toggle.toggled.emit(true)
	await process_frame
	_check(details != null and details.visible and benefits != null and benefits.is_visible_in_tree(), "expanding Details should reveal the existing cost and effect controls", failures)
	var original_benefits := benefits
	if benefits != null:
		benefits.focus_mode = Control.FOCUS_ALL
		benefits.grab_focus()
		await process_frame
		details_toggle.toggled.emit(false)
		await process_frame
	_check(root.gui_get_focus_owner() == details_toggle, "collapsing focused facility details should return focus to its disclosure control", failures)
	if details_toggle != null:
		details_toggle.toggled.emit(true)
	await process_frame
	_check(staffing_ui.find_child("FacilityBenefits_candling_rework_bay", true, false) == original_benefits, "facility disclosure should preserve the exact detailed control identity", failures)
	_check(purchase != null and purchase.focus_mode == Control.FOCUS_ALL, "the facility action should be keyboard focusable", failures)
	_check(purchase != null and _contains_all(purchase.text, ["build", "candling", "$120.00"]), "the action should name the purchase and exact capital cost", failures)
	_check(status != null and status.text == "AVAILABLE", "an actionable facility should advertise its available state", failures)
	_check(costs != null and _contains_all(_descendant_copy(costs), ["capital", "$120.00", "maintenance", "+$5.00/day"]), "capital and added daily maintenance should remain distinct", failures)
	_check(benefits != null and _contains_all(benefits.text, ["economic effects", "cracked eggs", "claim value"]), "the card should make both causal economic benefits visible", failures)
	_check(projection != null and _contains_all(projection.text, ["after build", "$80.00 spendable", "$38.00/day protected reserve"]), "the card should preview post-capital funds and the increased protected reserve", failures)
	_check(purchase != null and _contains_all(purchase.tooltip_text, ["$120.00", "$5.00", "economic effects"]), "the actionable tooltip should summarize cost, maintenance, and consequence", failures)
	if purchase != null:
		purchase.pressed.emit()
	_check(requested == [FACILITY_ID], "pressing the card should emit exactly its stable facility ID", failures)

	var locked := _facility_record()
	locked["unlocked"] = false
	locked["can_purchase"] = false
	locked["reason"] = "Complete three sound shifts to unlock the rework charter."
	staffing_ui.apply_snapshot(_snapshot_with(locked))
	await process_frame
	purchase = staffing_ui.find_child("PurchaseFacility_candling_rework_bay", true, false) as Button
	status = staffing_ui.find_child("FacilityStatus_candling_rework_bay", true, false) as Label
	var reason := staffing_ui.find_child("FacilityReason_candling_rework_bay", true, false) as Label
	_check(purchase != null and purchase.disabled and _contains_all(purchase.text, ["candling", "locked"]), "a locked facility should have a legible disabled action", failures)
	_check(status != null and status.text == "LOCKED", "locked progression should be visible without hovering", failures)
	_check(reason != null and _contains_all(reason.text, ["held", "three sound shifts"]), "the authoritative unlock condition should be printed on the card", failures)
	_check(purchase != null and purchase.tooltip_text.contains("three sound shifts"), "the same unlock condition should remain available to keyboard focus", failures)

	var review_held := _facility_record()
	review_held["planning_open"] = false
	review_held["can_purchase"] = false
	review_held["reason"] = "Facility construction opens during farmer review."
	staffing_ui.apply_snapshot(_snapshot_with(review_held, false))
	await process_frame
	purchase = staffing_ui.find_child("PurchaseFacility_candling_rework_bay", true, false) as Button
	status = staffing_ui.find_child("FacilityStatus_candling_rework_bay", true, false) as Label
	_check(purchase != null and purchase.disabled and purchase.text.begins_with("REVIEW TO BUILD"), "an active-shift facility should point to the correct next interaction", failures)
	_check(status != null and status.text == "REVIEW FILE", "review gating should have a distinct visible state", failures)

	var fund_held := _facility_record()
	fund_held["affordable"] = false
	fund_held["can_purchase"] = false
	fund_held["reason"] = ""
	fund_held["projected_spendable_fund_cents"] = 0
	staffing_ui.apply_snapshot(_snapshot_with(fund_held, true, 4000))
	await process_frame
	purchase = staffing_ui.find_child("PurchaseFacility_candling_rework_bay", true, false) as Button
	status = staffing_ui.find_child("FacilityStatus_candling_rework_bay", true, false) as Label
	reason = staffing_ui.find_child("FacilityReason_candling_rework_bay", true, false) as Label
	_check(purchase != null and purchase.disabled and purchase.text.begins_with("FEED FUND HELD"), "an unaffordable facility should not look actionable", failures)
	_check(status != null and status.text == "FUND HELD", "affordability should have a distinct visible state", failures)
	_check(reason != null and _contains_all(reason.text, ["short by", "$85.00", "protected obligations"]), "the affordability reason should include both capital and the added protected upkeep", failures)

	var installed := _facility_record()
	installed["owned"] = false
	installed["unlocked"] = false
	installed["planning_open"] = false
	installed["affordable"] = false
	installed["can_purchase"] = false
	installed["projected_spendable_fund_cents"] = 9150
	var installed_snapshot := _snapshot_with(installed, false, 9150)
	installed_snapshot["daily_operating_cost_cents"] = 3800
	installed_snapshot["owned_facilities"] = {FACILITY_ID: true}
	staffing_ui.apply_snapshot(installed_snapshot)
	await process_frame
	purchase = staffing_ui.find_child("PurchaseFacility_candling_rework_bay", true, false) as Button
	status = staffing_ui.find_child("FacilityStatus_candling_rework_bay", true, false) as Label
	reason = staffing_ui.find_child("FacilityReason_candling_rework_bay", true, false) as Label
	projection = staffing_ui.find_child("FacilityProjection_candling_rework_bay", true, false) as Label
	_check(purchase != null and purchase.disabled and purchase.text.contains("INSTALLED"), "owned_facilities should authoritatively retire the purchase action", failures)
	_check(status != null and status.text == "INSTALLED", "an owned facility should read as installed even if its old unlock flags are false", failures)
	_check(reason != null and _contains_all(reason.text, ["operating", "benefits active", "protected reserve"]), "the installed state should confirm that benefits and upkeep are active", failures)
	_check(projection != null and _contains_all(projection.text, ["current reserve", "$38.00/day protected", "$91.50 spendable"]), "an installed card should show current rather than hypothetical economics", failures)

	var packing := _packing_annex_record()
	staffing_ui.apply_snapshot(_snapshot_with(packing, true, 20000))
	await process_frame
	var packing_purchase := staffing_ui.find_child("PurchaseFacility_farmer_brand_packing_annex", true, false) as Button
	var packing_status := staffing_ui.find_child("FacilityStatus_farmer_brand_packing_annex", true, false) as Label
	var packing_level := staffing_ui.find_child("FacilityLevel_farmer_brand_packing_annex", true, false) as Label
	var packing_costs := staffing_ui.find_child("FacilityCosts_farmer_brand_packing_annex", true, false) as HFlowContainer
	var packing_benefits := staffing_ui.find_child("FacilityBenefits_farmer_brand_packing_annex", true, false) as Label
	var packing_projection := staffing_ui.find_child("FacilityProjection_farmer_brand_packing_annex", true, false) as Label
	_check(packing_purchase != null and not packing_purchase.disabled, "an installed level 1/3 annex must remain actionable for its next tier", failures)
	_check(packing_status != null and packing_status.text == "UPGRADE READY", "an installed non-maxed facility should advertise an upgrade rather than a terminal state", failures)
	_check(packing_level != null and _contains_all(packing_level.text, ["level 1 / 3", "next tier 2"]), "the card should show installed and next facility tiers at a glance", failures)
	_check(packing_purchase != null and _contains_all(packing_purchase.text, ["authorize packing tier 2", "$95.00"]), "the authoritative tier action and exact next capital cost should be retained", failures)
	_check(packing_costs != null and _contains_all(_descendant_copy(packing_costs), ["next capital", "$95.00", "maintenance", "+$2.00/day", "next upkeep", "$5.00/day"]), "the next capital payment and incremental upkeep should be visually distinct", failures)
	_check(packing_benefits != null and _contains_all(packing_benefits.text, ["economic effects", "+8%", "six sound eggs", "$6.00 carton premium", "operating tradeoffs", "$2.00/day"]), "exact tier returns and recurring tradeoffs should be readable without inference", failures)
	_check(packing_projection != null and _contains_all(packing_projection.text, ["after level 2", "$103.00 spendable", "$35.00/day protected reserve"]), "an upgrade should preview its authoritative post-purchase fund and reserve", failures)
	_check(packing_purchase != null and _contains_all(packing_purchase.tooltip_text, ["upgrade", "level 2", "$95.00", "+$2.00/day", "economic effects"]), "the upgrade tooltip should repeat the tier's exact economic commitment", failures)
	if packing_purchase != null:
		packing_purchase.pressed.emit()
	_check(requested == [FACILITY_ID, PACKING_ID], "multi-level actions should emit the same stable facility signal as legacy builds", failures)

	packing["level"] = 3
	packing["next_level"] = 3
	packing["installed"] = true
	packing["maxed"] = true
	packing["can_purchase"] = false
	packing["current_maintenance_cents"] = 800
	packing["next_maintenance_cents"] = 800
	packing["maintenance_delta_cents"] = 0
	staffing_ui.apply_snapshot(_snapshot_with(packing, true, 20000))
	await process_frame
	packing_purchase = staffing_ui.find_child("PurchaseFacility_farmer_brand_packing_annex", true, false) as Button
	packing_status = staffing_ui.find_child("FacilityStatus_farmer_brand_packing_annex", true, false) as Label
	packing_level = staffing_ui.find_child("FacilityLevel_farmer_brand_packing_annex", true, false) as Label
	_check(packing_purchase != null and packing_purchase.disabled and _contains_all(packing_purchase.text, ["installed", "level 3/3"]), "only the maxed facility should retire its purchase action", failures)
	_check(packing_status != null and packing_status.text == "INSTALLED", "the completed expansion should settle into an installed state", failures)
	_check(packing_level != null and _contains_all(packing_level.text, ["level 3 / 3", "expansion complete"]), "a maxed card should clearly close the tier ladder", failures)

	# The Service Coop uses three simultaneous, exact gates. Level 0 should make
	# every shortfall and the next success-only return visible without hovering.
	var service_coop := _service_coop_record(false)
	staffing_ui.apply_snapshot(_snapshot_with(service_coop, true, 20000))
	await process_frame
	var coop_gate := staffing_ui.find_child("FacilityServiceCoopGate_farm_mutual_service_coop", true, false) as Label
	var coop_purchase := staffing_ui.find_child("PurchaseFacility_farm_mutual_service_coop", true, false) as Button
	var coop_status := staffing_ui.find_child("FacilityStatus_farm_mutual_service_coop", true, false) as Label
	var coop_reason := staffing_ui.find_child("FacilityReason_farm_mutual_service_coop", true, false) as Label
	_check(coop_gate != null and _contains_all(coop_gate.text, ["level 1 gate", "standing  0 / 2", "unlisted", "archive  18 / 24", "active hens  3 / 4", "+0% -> +50%"]), "unlisted Service Coop should print all current/required gates and its next success-only return", failures)
	_check(coop_gate != null and coop_gate.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "narrow Service Coop gate copy should wrap instead of overflowing", failures)
	_check(coop_purchase != null and coop_purchase.disabled, "an unmet standing/archive/staffing gate must keep level 1 locked", failures)
	_check(coop_status != null and coop_status.text == "LOCKED", "unlisted Service Coop should advertise a distinct locked state", failures)
	_check(coop_reason != null and _contains_all(coop_reason.text, ["held", "standing 0 / 2", "archive 18 / 24", "active hens 3 / 4"]), "the card should repeat its authoritative compound gate reason without requiring hover", failures)
	_check(coop_purchase != null and _contains_all(coop_purchase.tooltip_text, ["standing 0 / 2", "archive 18 / 24", "active hens 3 / 4"]), "keyboard focus should expose the same authoritative Service Coop gate reason", failures)

	# Earned Bronze plus exact archive and staffing requirements authorizes the
	# build while retaining the current-to-next premium disclosure.
	service_coop = _service_coop_record(true)
	staffing_ui.apply_snapshot(_snapshot_with(service_coop, true, 20000))
	await process_frame
	coop_gate = staffing_ui.find_child("FacilityServiceCoopGate_farm_mutual_service_coop", true, false) as Label
	coop_purchase = staffing_ui.find_child("PurchaseFacility_farm_mutual_service_coop", true, false) as Button
	coop_status = staffing_ui.find_child("FacilityStatus_farm_mutual_service_coop", true, false) as Label
	_check(coop_gate != null and _contains_all(coop_gate.text, ["level 1 gate", "standing  2 / 2", "bronze", "archive  24 / 24", "active hens  4 / 4", "success-only premium", "+0% -> +50%"]), "earned Bronze Service Coop should show every cleared gate and exact return", failures)
	_check(coop_purchase != null and not coop_purchase.disabled and coop_purchase.focus_mode == Control.FOCUS_ALL, "a fully cleared Service Coop requisition should be keyboard actionable", failures)
	_check(coop_purchase != null and _contains_all(coop_purchase.text, ["service coop", "$75.00"]), "the authorized action should name the Service Coop and exact level-1 capital", failures)
	_check(coop_status != null and coop_status.text == "AVAILABLE", "cleared Bronze gates should expose an available capital state", failures)
	if coop_purchase != null:
		coop_purchase.pressed.emit()
	_check(requested == [FACILITY_ID, PACKING_ID, SERVICE_COOP_ID], "Service Coop should emit its stable facility ID through the shared capital signal", failures)

	# One compact care block connects live welfare, physical recovery capacity,
	# effective training terms, and the next capital decision before the catalog.
	var training_roost := _training_roost_record()
	var care_snapshot := _snapshot_with(training_roost, true, 20000)
	care_snapshot["flock_care"] = _flock_care_record()
	staffing_ui.apply_snapshot(care_snapshot)
	await process_frame
	await process_frame
	var care_section := staffing_ui.find_child("FlockCareSection", true, false) as PanelContainer
	var care_heading := staffing_ui.find_child("FlockCareHeading", true, false) as Label
	var rested_gate := staffing_ui.find_child("FlockCareRestedGate", true, false) as Label
	var wellness_summary := staffing_ui.find_child("FlockCareWellnessSummary", true, false) as Label
	var training_summary := staffing_ui.find_child("FlockCareTrainingSummary", true, false) as Label
	var next_care := staffing_ui.find_child("FlockCareNextAction", true, false) as Label
	var matched_gate := staffing_ui.find_child("FacilityTrainingWellnessGate_training_roost", true, false) as Label
	var training_delta := staffing_ui.find_child("FacilityCareDelta_training_roost", true, false) as Label
	var training_purchase := staffing_ui.find_child("PurchaseFacility_training_roost", true, false) as Button
	_check(care_section != null and care_section.visible, "authoritative flock_care should reveal one compact ledger block", failures)
	_check(care_heading != null and care_heading.text == "FLOCK CARE & TRAINING", "care economics should have one stable information heading", failures)
	_check(rested_gate != null and _contains_all(rested_gate.text, ["74 / 72", "on track"]), "the Rested Flock gate should compare current welfare with its exact threshold", failures)
	_check(wellness_summary != null and _contains_all(wellness_summary.text, ["wellness nest", "l1", "resting 1 / 2", "strain -8%", "recovery +15%"]), "Wellness summary should connect occupied capacity to its exact strain and recovery effects", failures)
	_check(training_summary != null and _contains_all(training_summary.text, ["training roost", "l1", "1 active", "$10.00", "-10%", "+2 xp"]), "Training summary should use authoritative effective sponsorship and coaching terms", failures)
	_check(next_care != null and _contains_all(next_care.text, ["next care file", "wellness nest", "l2", "$90.00", "+$3.00/day"]), "the care block should identify the exact next capital commitment", failures)
	_check(matched_gate != null and _contains_all(matched_gate.text, ["matched care gate", "wellness nest 1 / 1", "cleared"]), "Training Roost should disclose its matching Wellness foundation", failures)
	_check(training_delta != null and _contains_all(training_delta.text, ["next training effect", "$10.00 -> $8.00", "penalty -10% -> -5%", "coaching +2 -> +4 xp"]), "the Training Roost card should show exact current-to-next economics before authorization", failures)
	_check(training_purchase != null and not training_purchase.disabled, "cleared matched-care gates should leave the Training Roost keyboard actionable", failures)

	# Mirror Flockwatch's domain reparenting: the Capital presentation root moves
	# out of the still-live RoostStaffingUI signal owner and into its own page
	# scroll. Snapshot rebuilds must follow that real presentation ancestry.
	var capital_domain := staffing_ui.navigation_sections().get(&"capital") as VBoxContainer
	var capital_page_scroll := ScrollContainer.new()
	capital_page_scroll.name = "FacilitiesCapitalPageScroll"
	capital_page_scroll.position = Vector2.ZERO
	capital_page_scroll.size = Vector2(320.0, 280.0)
	capital_page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	capital_page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	harness.add_child(capital_page_scroll)
	if capital_domain != null:
		capital_domain.reparent(capital_page_scroll, false)
	ledger_scroll.visible = false
	await process_frame
	await process_frame
	_check(
		capital_domain != null
		and staffing_ui.navigation_sections().get(&"capital") == capital_domain
		and capital_page_scroll.is_ancestor_of(training_purchase),
		"Flockwatch-style reparenting should preserve the Capital domain and existing facility controls",
		failures,
	)
	if training_purchase != null:
		training_purchase.grab_focus()
	capital_page_scroll.scroll_vertical = 240
	await process_frame
	var prior_scroll := capital_page_scroll.scroll_vertical
	staffing_ui.apply_snapshot(care_snapshot)
	await process_frame
	await process_frame
	training_purchase = capital_domain.find_child("PurchaseFacility_training_roost", true, false) as Button if capital_domain != null else null
	_check(training_purchase != null and training_purchase.has_focus(), "reparented Capital snapshot rebuilds should restore focus to the same facility action", failures)
	_check(capital_page_scroll.scroll_vertical == prior_scroll and prior_scroll > 0, "reparented Capital snapshot rebuilds should preserve that page's scroll position", failures)
	if training_purchase != null:
		training_purchase.pressed.emit()
	_check(requested == [FACILITY_ID, PACKING_ID, SERVICE_COOP_ID, TRAINING_ROOST_ID], "reparented facility controls should retain the original RoostStaffingUI signal route", failures)
	if capital_domain != null:
		capital_domain.reparent(staffing_ui, false)
	capital_page_scroll.queue_free()
	ledger_scroll.visible = true
	await process_frame

	# The operations block consumes one frozen snapshot: cumulative supervision,
	# AUTO-only support, the next action, and both current-to-next facility deltas.
	var operations_snapshot := _snapshot_with(_rooster_operations_record(), true, 30000)
	operations_snapshot["facility_catalog"] = [
		_rooster_operations_record(),
		_it_coop_record(),
	]
	operations_snapshot["operations"] = _operations_record()
	staffing_ui.apply_snapshot(operations_snapshot)
	await process_frame
	await process_frame
	var operations_section := staffing_ui.find_child("RoosterOperationsSection", true, false) as PanelContainer
	var operations_heading := staffing_ui.find_child("RoosterOperationsHeading", true, false) as Label
	var supervision_summary := staffing_ui.find_child("RoosterOperationsSupervision", true, false) as Label
	var pressure_summary := staffing_ui.find_child("RoosterOperationsPressure", true, false) as Label
	var automation_summary := staffing_ui.find_child("RoosterOperationsAutomation", true, false) as Label
	var exposure_summary := staffing_ui.find_child("RoosterOperationsExposure", true, false) as Label
	var next_operations := staffing_ui.find_child("RoosterOperationsNextAction", true, false) as Label
	var rooster_delta := staffing_ui.find_child("FacilityOperationsDelta_rooster_operations_office", true, false) as Label
	var it_delta := staffing_ui.find_child("FacilityOperationsDelta_it_coop", true, false) as Label
	var it_purchase := staffing_ui.find_child("PurchaseFacility_it_coop", true, false) as Button
	_check(operations_section != null and operations_section.visible, "the frozen operations snapshot should reveal one compact Flockwatch block", failures)
	_check(operations_heading != null and operations_heading.text == "ROOSTER OPERATIONS", "operations economics should have one stable inline heading", failures)
	_check(supervision_summary != null and _contains_all(supervision_summary.text, ["rooster office", "l1", "check-ins", "1 / 2", "1 left", "$5.00/day"]), "supervision should disclose exact action use, remaining allowance, and supervisor payroll", failures)
	_check(pressure_summary != null and _contains_all(pressure_summary.text, ["surveillance / hen", "+0.75 grievance", "+0.5 stress", "flock unity risk", "+0.5 / shift"]), "the compact block should disclose the exact surveillance pressure tradeoff", failures)
	_check(automation_summary != null and _contains_all(automation_summary.text, ["it coop", "l1", "auto +3% pace", "150m specialty grace", "secondary credentials", "recognized"]), "IT Coop should disclose AUTO-only speed, grace, and credential recognition", failures)
	_check(exposure_summary != null and _contains_all(exposure_summary.text, ["compliance exposure", "-1 / shift"]), "IT Coop should disclose its exact compliance exposure", failures)
	_check(next_operations != null and _contains_all(next_operations.text, ["next operations file", "predictive dispatch rack", "l2", "$120.00 capital", "+$6.00/day"]), "the block should identify the exact next operations commitment", failures)
	_check(rooster_delta != null and _contains_all(rooster_delta.text, ["next supervision", "check-ins 2 -> 3", "$5.00 -> $8.00/day", "grievance +0.75 -> +1.25", "flock unity +0.5 -> +1"]), "Rooster Office cards should disclose current-to-next capacity, payroll, and pressure", failures)
	_check(it_delta != null and _contains_all(it_delta.text, ["next auto support", "pace +3% -> +6%", "grace 150m -> 120m", "exposure -1 -> -1.8", "$22.00 -> $26.00"]), "IT Coop cards should disclose current-to-next AUTO support and compliance costs", failures)
	_check(it_purchase != null and not it_purchase.disabled, "an authorized IT Coop tier should remain keyboard actionable beside its exact deltas", failures)
	if it_purchase != null:
		it_purchase.grab_focus()
	ledger_scroll.scroll_vertical = 360
	await process_frame
	prior_scroll = ledger_scroll.scroll_vertical
	staffing_ui.apply_snapshot(operations_snapshot)
	await process_frame
	await process_frame
	it_purchase = staffing_ui.find_child("PurchaseFacility_it_coop", true, false) as Button
	_check(it_purchase != null and it_purchase.has_focus(), "operations snapshot rebuilds should restore focus to the same facility action", failures)
	_check(ledger_scroll.scroll_vertical == prior_scroll and prior_scroll > 0, "operations snapshot rebuilds should preserve the Flockwatch ledger scroll position", failures)

	# Finally consume the real simulation contract so fixture aliases cannot drift
	# away from the authoritative capital and care snapshot.
	var live_simulation := DepartmentSimulation.new(1701, 4)
	staffing_ui.apply_snapshot(live_simulation.snapshot())
	await process_frame
	await process_frame
	rested_gate = staffing_ui.find_child("FlockCareRestedGate", true, false) as Label
	wellness_summary = staffing_ui.find_child("FlockCareWellnessSummary", true, false) as Label
	training_summary = staffing_ui.find_child("FlockCareTrainingSummary", true, false) as Label
	next_care = staffing_ui.find_child("FlockCareNextAction", true, false) as Label
	operations_section = staffing_ui.find_child("RoosterOperationsSection", true, false) as PanelContainer
	supervision_summary = staffing_ui.find_child("RoosterOperationsSupervision", true, false) as Label
	automation_summary = staffing_ui.find_child("RoosterOperationsAutomation", true, false) as Label
	next_operations = staffing_ui.find_child("RoosterOperationsNextAction", true, false) as Label
	_check(rested_gate != null and _contains_all(rested_gate.text, ["/ 72", "on track"]), "real simulation welfare should flow into the Rested Flock threshold", failures)
	_check(wellness_summary != null and _contains_all(wellness_summary.text, ["wellness nest", "l0", "resting 0 / 0", "baseline"]), "real baseline recovery terms should render without presentation inference", failures)
	_check(training_summary != null and _contains_all(training_summary.text, ["training roost", "l0", "$12.00", "-15%", "+0 xp"]), "real baseline training terms should render from flock_care", failures)
	_check(next_care != null and _contains_all(next_care.text, ["next care gate", "wellness nest", "$70.00", "+$5.00/day"]), "real next_care_action should drive the exact first care requisition", failures)
	_check(operations_section != null and operations_section.visible, "the real operations snapshot should reveal the compact Flockwatch block at baseline", failures)
	_check(supervision_summary != null and _contains_all(supervision_summary.text, ["rooster office", "l0", "0 / 1", "1 left", "$0.00/day"]), "real baseline supervision should flow through the exact frozen keys", failures)
	_check(automation_summary != null and _contains_all(automation_summary.text, ["it coop", "l0", "auto local pace", "180m specialty grace", "primary only"]), "real baseline automation should remain clearly local and opt-in", failures)
	_check(next_operations != null and _contains_all(next_operations.text, ["next operations gate", "shift board perch", "l1"]), "real next_operations_action should drive the first operations requisition", failures)

	staffing_ui.apply_snapshot(_snapshot_with({}, true, 20000, false))
	await process_frame
	section = staffing_ui.find_child("FacilitiesSection", true, false) as VBoxContainer
	_check(section != null and not section.visible, "a legacy snapshot without a catalog should leave no empty facilities furniture", failures)

	harness.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FACILITIES_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FACILITIES_UI_TEST_PASSED catalog=responsive economics=causal tiers=upgradeable-maxed states=available-locked-review-fund-owned signal=stable keyboard=focusable")
	quit(0)


func _facility_record() -> Dictionary:
	return {
		"id": FACILITY_ID,
		"name": "Candling & Rework Bay",
		"short_name": "Candling Bay",
		"description": "A warm inspection bench that catches shell defects before farmer presentation.",
		"cost_cents": 12000,
		"daily_maintenance_cents": 500,
		"benefits": [
			"Recover value from cracked eggs routed through rework.",
			"Increase sound-claim value after candling inspection.",
		],
		"owned": false,
		"unlocked": true,
		"planning_open": true,
		"affordable": true,
		"can_purchase": true,
		"reason": "",
		"projected_spendable_fund_cents": 8000,
	}


func _packing_annex_record() -> Dictionary:
	return {
		"id": PACKING_ID,
		"display_name": "Farmer Brand Packing Annex",
		"short_name": "Packing Annex",
		"description": "A farm-office packing line that turns sound eggs into credited cartons.",
		"level": 1,
		"max_level": 3,
		"installed": true,
		"maxed": false,
		"unlocked": true,
		"planning_open": true,
		"can_purchase": true,
		"next_level": 2,
		"next_level_cost_cents": 9500,
		"current_maintenance_cents": 300,
		"next_maintenance_cents": 500,
		"maintenance_delta_cents": 200,
		"required_spendable_cents": 9700,
		"projected_spendable_fund_cents": 10300,
		"projected_protected_reserve_cents": 3500,
		"effects": [
			"Level 2 adds +8% value to sound and golden eggs.",
			"Every six sound eggs releases a $6.00 carton premium.",
		],
		"benefits": ["Packing progress remains visible on the annex line."],
		"tradeoffs": ["Adds $2.00/day to protected annex upkeep."],
		"purchase_label": "Authorize Packing Tier 2",
		"action_reason": "",
	}


func _service_coop_record(earned_bronze: bool) -> Dictionary:
	return {
		"id": SERVICE_COOP_ID,
		"display_name": "Farm Mutual Service Coop",
		"short_name": "Service Coop",
		"description": "An accredited service roost for successful outside Farm Mutual binders.",
		"level": 0,
		"max_level": 3,
		"installed": false,
		"maxed": false,
		"unlocked": earned_bronze,
		"planning_open": true,
		"affordable": true,
		"can_purchase": earned_bronze,
		"next_level": 1,
		"next_level_cost_cents": 7500,
		"current_maintenance_cents": 0,
		"next_maintenance_cents": 300,
		"maintenance_delta_cents": 300,
		"required_spendable_cents": 7800,
		"projected_spendable_fund_cents": 12500,
		"projected_protected_reserve_cents": 3600,
		"market_standing": 2 if earned_bronze else 0,
		"market_standing_rank": &"bronze" if earned_bronze else &"unlisted",
		"market_standing_rank_label": "BRONZE" if earned_bronze else "UNLISTED",
		"required_market_standing": 2,
		"market_standing_shortfall": 0 if earned_bronze else 2,
		"current_claim_capacity": 24 if earned_bronze else 18,
		"required_claim_capacity": 24,
		"claim_capacity_shortfall": 0 if earned_bronze else 6,
		"active_staff_count": 4 if earned_bronze else 3,
		"required_active_staff": 4,
		"active_staff_shortfall": 0 if earned_bronze else 1,
		"premium_bonus_basis_points": 0,
		"next_premium_bonus_basis_points": 5000,
		"effects": ["Level 1 adds +50% to successfully fulfilled Farm Mutual premiums."],
		"tradeoffs": ["Adds $3.00/day to protected Service Coop upkeep."],
		"purchase_label": "Build Service Coop Level 1",
		"action_reason": "" if earned_bronze else "Standing 0 / 2, archive 18 / 24, and active hens 3 / 4 are required for the Bronze coop charter.",
	}


func _training_roost_record() -> Dictionary:
	return {
		"id": TRAINING_ROOST_ID,
		"display_name": "Training Roost",
		"short_name": "Training Roost",
		"description": "A supervised farm-office roost for alternate lane accreditation.",
		"level": 1,
		"max_level": 3,
		"installed": true,
		"maxed": false,
		"unlocked": true,
		"planning_open": true,
		"affordable": true,
		"can_purchase": true,
		"next_level": 2,
		"next_level_cost_cents": 10000,
		"current_maintenance_cents": 400,
		"next_maintenance_cents": 700,
		"maintenance_delta_cents": 300,
		"required_spendable_cents": 10300,
		"projected_spendable_fund_cents": 9700,
		"projected_protected_reserve_cents": 4000,
		"wellness_level": 1,
		"required_wellness_level": 1,
		"current_career_sponsorship_cost_cents": 1000,
		"next_career_sponsorship_cost_cents": 800,
		"current_training_work_basis_points": 9000,
		"next_training_work_basis_points": 9500,
		"current_career_coaching_xp_bonus": 2,
		"next_career_coaching_xp_bonus": 4,
		"effects": ["Level 2 reduces training drag to five percent."],
		"tradeoffs": ["Adds $3.00/day to protected coaching upkeep."],
	}


func _rooster_operations_record() -> Dictionary:
	return {
		"id": ROOSTER_OPERATIONS_ID,
		"display_name": "Rooster Operations Office",
		"short_name": "Rooster Office",
		"description": "A supervised perch for flock check-ins and surveillance files.",
		"level": 1,
		"max_level": 3,
		"installed": true,
		"maxed": false,
		"unlocked": true,
		"planning_open": true,
		"affordable": true,
		"can_purchase": true,
		"next_level": 2,
		"next_level_name": "Glass Supervision Pod",
		"next_level_cost_cents": 11000,
		"current_maintenance_cents": 300,
		"next_maintenance_cents": 500,
		"maintenance_delta_cents": 200,
		"current_supervisor_payroll_cents": 500,
		"next_supervisor_payroll_cents": 800,
		"current_personnel_action_limit": 2,
		"next_personnel_action_limit": 3,
		"current_surveillance_grievance_millipoints": 750,
		"next_surveillance_grievance_millipoints": 1250,
		"current_surveillance_stress_millipoints": 500,
		"next_surveillance_stress_millipoints": 1000,
		"current_surveillance_solidarity_millipoints": 500,
		"next_surveillance_solidarity_millipoints": 1000,
		"required_spendable_cents": 11700,
		"projected_spendable_fund_cents": 18300,
		"projected_protected_reserve_cents": 4600,
		"effects": ["Adds one flock check-in each shift."],
		"tradeoffs": ["Adds supervisor payroll and once-per-shift surveillance pressure."],
		"purchase_label": "Authorize Rooster Office Tier 2",
	}


func _it_coop_record() -> Dictionary:
	return {
		"id": IT_COOP_ID,
		"display_name": "IT Coop",
		"short_name": "IT Coop",
		"description": "A farm-office dispatch rack that supports opt-in AUTO peckwork.",
		"level": 1,
		"max_level": 3,
		"installed": true,
		"maxed": false,
		"unlocked": true,
		"planning_open": true,
		"affordable": true,
		"can_purchase": true,
		"next_level": 2,
		"next_level_name": "Predictive Dispatch Rack",
		"next_level_cost_cents": 12000,
		"current_maintenance_cents": 400,
		"next_maintenance_cents": 700,
		"maintenance_delta_cents": 300,
		"current_automation_work_basis_points": 10300,
		"next_automation_work_basis_points": 10600,
		"current_automation_specialty_grace_minutes": 150,
		"next_automation_specialty_grace_minutes": 120,
		"current_automation_compliance_exposure_millipoints": 1000,
		"next_automation_compliance_exposure_millipoints": 1800,
		"current_ledger_molt_patch_cost_cents": 2200,
		"next_ledger_molt_patch_cost_cents": 2600,
		"required_spendable_cents": 12300,
		"projected_spendable_fund_cents": 17700,
		"projected_protected_reserve_cents": 4700,
		"effects": ["AUTO work runs three percent faster and recognizes secondary credentials."],
		"tradeoffs": ["Adds compliance exposure and a larger Ledger Molt patch."],
		"purchase_label": "Authorize IT Coop Tier 2",
	}


func _operations_record() -> Dictionary:
	return {
		"version": 1,
		"rooster_office_level": 1,
		"it_coop_level": 1,
		"supervision": {
			"action_limit": 2,
			"actions_used": 1,
			"actions_remaining": 1,
			"actions": [{"day": 4, "worker_id": 0, "action_id": "share_credit"}],
			"supervisor_payroll_cents": 500,
			"surveillance_grievance_millipoints": 750,
			"surveillance_stress_millipoints": 500,
			"surveillance_solidarity_millipoints": 500,
		},
		"automation": {
			"enabled": true,
			"work_basis_points": 10300,
			"work_multiplier": 1.03,
			"specialty_grace_minutes": 150,
			"recognizes_secondary_specialties": true,
			"compliance_exposure_millipoints": 1000,
			"ledger_patch_cost_cents": 2200,
		},
		"next_operations_action": {
			"facility_id": IT_COOP_ID,
			"next_level": 2,
			"next_level_name": "Predictive Dispatch Rack",
			"can_purchase": true,
			"cost_cents": 12000,
			"maintenance_delta_cents": 300,
			"supervisor_payroll_delta_cents": 0,
			"added_daily_operating_cents": 600,
		},
	}


func _flock_care_record() -> Dictionary:
	return {
		"welfare": 74,
		"rested_flock_gate": 72,
		"welfare_delta_to_gate": 2,
		"wellness_level": 1,
		"training_roost_level": 1,
		"breaks_active": 1,
		"recovery_perch_count": 2,
		"training_active": [{"worker_id": 3, "lane_id": "appeals"}],
		"recovery_effects": {
			"strain_multiplier": 0.92,
			"break_recovery_multiplier": 1.15,
			"overnight_fatigue_recovery_bonus": 3,
			"overnight_stress_recovery_bonus": 2,
		},
		"training_terms": {
			"base_sponsorship_cost_cents": 1200,
			"effective_sponsorship_cost_cents": 1000,
			"sponsorship_discount_cents": 200,
			"effective_work_multiplier": 0.90,
			"work_penalty_percent": 10,
			"coaching_xp_bonus": 2,
			"wage_bonus_cents": 100,
		},
		"next_care_action": {
			"facility_id": "wellness_nest_room",
			"display_name": "Wellness Nest",
			"next_level": 2,
			"capital_cost_cents": 9000,
			"maintenance_delta_cents": 300,
			"can_purchase": true,
		},
	}


func _snapshot_with(
	facility: Dictionary,
	planning_open: bool = true,
	spendable: int = 20000,
	include_catalog: bool = true
) -> Dictionary:
	return {
		"workers": [],
		"staffing_catalog": [],
		"active_staff_count": 0,
		"office_capacity": 4,
		"maximum_staff_capacity": 6,
		"staffing_planning_open": planning_open,
		"daily_payroll_cents": 2800,
		"daily_facility_cost_cents": 500,
		"daily_operating_cost_cents": 3300,
		"spendable_fund_cents": spendable,
		"capacity_upgrade": {"maxed": true, "reason": "Capacity fixture is closed."},
		"facility_catalog": [facility] if include_catalog else [],
		"owned_facilities": {},
	}


func _descendant_copy(parent: Node) -> String:
	var copy := ""
	for child in parent.find_children("*", "Label", true, false):
		copy += " " + String((child as Label).text)
	return copy


func _contains_all(copy: String, fragments: Array[String]) -> bool:
	var normalized := copy.to_lower()
	for fragment in fragments:
		if not normalized.contains(fragment.to_lower()):
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
