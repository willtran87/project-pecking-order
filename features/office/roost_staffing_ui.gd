class_name RoostStaffingUI
extends VBoxContainer

## Compact staffing controls hosted inside the existing Flockwatch ledger.
##
## The surface deliberately reuses the ledger's ScrollContainer instead of
## creating another permanent overlay. Every disabled action retains the
## authoritative simulation reason in its tooltip.

signal capacity_purchase_requested
signal hire_requested(worker_id: int)
signal release_requested(worker_id: int)
signal facility_purchase_requested(facility_id: StringName)
signal flock_relations_action_requested(case_id: int, action_id: StringName)
signal feed_order_requested(order_id: StringName)
signal farmer_relations_campaign_requested(campaign_id: StringName)
signal farmgate_dispatch_mandate_requested(mandate_id: StringName)
signal capital_blueprint_requested

const FlockRelationsCaseUIScript := preload("res://features/office/flock_relations_case_ui.gd")
const FeedProcurementUIScript := preload("res://features/office/feed_procurement_ui.gd")
const FarmerRelationsGalleryUIScript := preload("res://features/office/farmer_relations_gallery_ui.gd")
const FarmgateDispatchUIScript := preload("res://features/office/farmgate_dispatch_ui.gd")

const COLOR_BRASS := Color("e7c56e")
const COLOR_TEAL := Color("73b5a7")
const COLOR_MUTED := Color("aeb8c4")
const COLOR_RUST := Color("d68a68")
const COLOR_MULBERRY := Color("9d7890")

var _snapshot: Dictionary = {}
var _interface_built := false
var _flock_domain: VBoxContainer
var _operations_domain: VBoxContainer
var _capital_domain: VBoxContainer
var _governance_domain: VBoxContainer
var _headcount_label: Label
var _costs_label: Label
var _treasury_label: Label
var _arrears_label: Label
var _capital_blueprint_button: Button
var _capital_plan_label: Label
var _farmer_relations_gallery_ui: VBoxContainer
var _farmgate_dispatch_ui: FarmgateDispatchUI
var _feed_procurement_ui: FeedProcurementUI
var _planning_label: Label
var _capacity_button: Button
var _operations_section: PanelContainer
var _operations_supervision_label: Label
var _operations_pressure_label: Label
var _operations_automation_label: Label
var _operations_exposure_label: Label
var _operations_next_action_label: Label
var _flock_relations_ui: VBoxContainer
var _care_section: PanelContainer
var _care_gate_label: Label
var _care_wellness_label: Label
var _care_training_label: Label
var _care_next_action_label: Label
var _facilities_section: VBoxContainer
var _facility_list: VBoxContainer
var _inline_facilities_toggle: Button
var _inline_facilities_open := false
var _applicant_list: VBoxContainer
var _release_selector: OptionButton
var _release_button: Button
var _last_action_label: Label
var _selected_release_worker_id := -1
var _facility_refresh_serial := 0


func _ready() -> void:
	name = "RoostStaffingUI"
	add_theme_constant_override("separation", 7)
	_ensure_interface()
	_refresh()


func apply_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	_ensure_interface()
	_refresh()


func navigation_sections() -> Dictionary:
	# Flockwatch may reparent these presentation roots into progressive pages.
	# All simulation references and signals remain owned by this component.
	_ensure_interface()
	return {
		&"flock": _flock_domain,
		&"operations": _operations_domain,
		&"capital": _capital_domain,
		&"records": _governance_domain,
	}


func _ensure_interface() -> void:
	if _interface_built:
		return
	_interface_built = true
	_build_interface()


func _build_interface() -> void:
	_flock_domain = _new_domain_root("StaffingFlockDomain")
	_operations_domain = _new_domain_root("StaffingOperationsDomain")
	_capital_domain = _new_domain_root("StaffingCapitalDomain")
	_governance_domain = _new_domain_root("StaffingGovernanceDomain")
	for domain: VBoxContainer in [
		_flock_domain,
		_operations_domain,
		_capital_domain,
		_governance_domain,
	]:
		add_child(domain)
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 8)
	_flock_domain.add_child(heading_row)
	var heading := _make_label("ROOST STAFFING", 17, COLOR_BRASS)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	_headcount_label = _make_label("4 / 4", 14, COLOR_TEAL)
	_headcount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading_row.add_child(_headcount_label)

	_costs_label = _make_label("Operating reserve is being calculated.", 12, COLOR_MUTED)
	_costs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flock_domain.add_child(_costs_label)
	_treasury_label = _make_label("TREASURY  awaiting first filed close", 11, COLOR_TEAL)
	_treasury_label.name = "FarmTreasurySummary"
	_treasury_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_capital_domain.add_child(_treasury_label)
	_arrears_label = _make_label("", 12, COLOR_RUST)
	_arrears_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_arrears_label.visible = false
	_capital_domain.add_child(_arrears_label)

	_capital_blueprint_button = Button.new()
	_capital_blueprint_button.name = "OpenCapitalBlueprint"
	_capital_blueprint_button.text = "OPEN CAPITAL BLUEPRINT"
	_capital_blueprint_button.theme_type_variation = &"PrimaryButton"
	_capital_blueprint_button.custom_minimum_size.y = 44.0
	_capital_blueprint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_capital_blueprint_button.focus_mode = Control.FOCUS_ALL
	_capital_blueprint_button.tooltip_text = "Compare every campus parcel, pin one capital plan, and inspect exact reserve consequences."
	_capital_blueprint_button.pressed.connect(func() -> void: capital_blueprint_requested.emit())
	_capital_domain.add_child(_capital_blueprint_button)
	_capital_plan_label = _make_label("No capital plan pinned.", 10, COLOR_MUTED)
	_capital_plan_label.name = "CapitalPlanSummary"
	_capital_plan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_capital_domain.add_child(_capital_plan_label)

	_farmer_relations_gallery_ui = FarmerRelationsGalleryUIScript.new() as VBoxContainer
	_farmer_relations_gallery_ui.campaign_requested.connect(
		func(campaign_id: StringName) -> void:
			farmer_relations_campaign_requested.emit(campaign_id)
	)
	_governance_domain.add_child(_farmer_relations_gallery_ui)

	_farmgate_dispatch_ui = FarmgateDispatchUIScript.new() as FarmgateDispatchUI
	_farmgate_dispatch_ui.mandate_requested.connect(
		func(mandate_id: StringName) -> void:
			farmgate_dispatch_mandate_requested.emit(mandate_id)
	)
	_operations_domain.add_child(_farmgate_dispatch_ui)

	_feed_procurement_ui = FeedProcurementUIScript.new() as FeedProcurementUI
	_feed_procurement_ui.feed_order_requested.connect(
		func(order_id: StringName) -> void: feed_order_requested.emit(order_id)
	)
	_operations_domain.add_child(_feed_procurement_ui)

	_capacity_button = Button.new()
	_capacity_button.name = "PurchaseStaffCapacity"
	_capacity_button.theme_type_variation = &"PrimaryButton"
	_capacity_button.custom_minimum_size.y = 40.0
	_capacity_button.pressed.connect(func() -> void: capacity_purchase_requested.emit())
	_capital_domain.add_child(_capacity_button)

	_build_operations_section()
	_flock_relations_ui = FlockRelationsCaseUIScript.new() as VBoxContainer
	_flock_relations_ui.action_requested.connect(
		func(case_id: int, action_id: StringName) -> void:
			flock_relations_action_requested.emit(case_id, action_id)
	)
	_governance_domain.add_child(_flock_relations_ui)
	_build_flock_care_section()

	_facilities_section = VBoxContainer.new()
	_facilities_section.name = "FacilitiesSection"
	_facilities_section.add_theme_constant_override("separation", 6)
	_capital_domain.add_child(_facilities_section)
	var facilities_heading := HBoxContainer.new()
	facilities_heading.add_theme_constant_override("separation", 8)
	_facilities_section.add_child(facilities_heading)
	var facilities_title := _make_label("CAPITAL EXPANSIONS", 12, COLOR_BRASS)
	facilities_title.name = "CapitalExpansionsTitle"
	facilities_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	facilities_heading.add_child(facilities_title)
	_inline_facilities_toggle = Button.new()
	_inline_facilities_toggle.name = "InlineCapitalFileToggle"
	_inline_facilities_toggle.text = "SHOW"
	_inline_facilities_toggle.custom_minimum_size = Vector2(74.0, 30.0)
	_inline_facilities_toggle.tooltip_text = "Open the legacy card list without leaving Flockwatch."
	_inline_facilities_toggle.pressed.connect(_on_inline_facilities_toggle_pressed)
	facilities_heading.add_child(_inline_facilities_toggle)
	_facility_list = VBoxContainer.new()
	_facility_list.name = "FacilityCatalog"
	_facility_list.add_theme_constant_override("separation", 7)
	_facility_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_facility_list.visible = false
	_facilities_section.add_child(_facility_list)

	_planning_label = _make_label("STAFFING FILE", 12, COLOR_BRASS)
	_flock_domain.add_child(_planning_label)
	_applicant_list = VBoxContainer.new()
	_applicant_list.name = "StaffingApplicants"
	_applicant_list.add_theme_constant_override("separation", 6)
	_flock_domain.add_child(_applicant_list)

	var release_title := _make_label("ACTIVE ROOST", 12, COLOR_BRASS)
	_flock_domain.add_child(release_title)
	var release_row := HBoxContainer.new()
	release_row.add_theme_constant_override("separation", 6)
	_flock_domain.add_child(release_row)
	_release_selector = OptionButton.new()
	_release_selector.name = "ReleaseWorkerSelector"
	_release_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_release_selector.custom_minimum_size.y = 38.0
	_release_selector.clip_text = true
	_release_selector.item_selected.connect(_on_release_selection_changed)
	release_row.add_child(_release_selector)
	_release_button = Button.new()
	_release_button.name = "ReleaseWorkerButton"
	_release_button.theme_type_variation = &"DangerButton"
	_release_button.custom_minimum_size = Vector2(92.0, 38.0)
	_release_button.pressed.connect(_on_release_pressed)
	release_row.add_child(_release_button)

	_last_action_label = _make_label("", 12, Color("d7c17d"))
	_last_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_last_action_label.visible = false
	_flock_domain.add_child(_last_action_label)


func _new_domain_root(node_name: String) -> VBoxContainer:
	var domain := VBoxContainer.new()
	domain.name = node_name
	domain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	domain.add_theme_constant_override("separation", 7)
	return domain


func _refresh() -> void:
	if _headcount_label == null:
		return
	var active_count := int(_snapshot.get("active_staff_count", _employed_workers().size()))
	var capacity := int(_snapshot.get("office_capacity", maxi(active_count, 4)))
	var maximum := int(_snapshot.get("maximum_staff_capacity", maxi(capacity, 6)))
	var planning_open := bool(_snapshot.get("staffing_planning_open", false))
	var payroll := int(_snapshot.get("daily_payroll_cents", 0))
	var facility := int(_snapshot.get("daily_facility_cost_cents", 0))
	var operating := int(_snapshot.get("daily_operating_cost_cents", payroll + facility))
	var spendable := int(_snapshot.get("spendable_fund_cents", _snapshot.get("revenue_cents", 0)))
	var arrears := int(_snapshot.get("wage_arrears_cents", 0))
	var treasury := _snapshot.get("farm_treasury", {}) as Dictionary
	var treasury_principal := int(treasury.get("credit_principal_cents", 0))
	var treasury_vendor := int(treasury.get("vendor_arrears_cents", 0))
	var treasury_interest := int(treasury.get("interest_arrears_cents", 0))
	var treasury_liabilities := int(treasury.get(
		"total_liabilities_cents",
		treasury_principal + treasury_vendor + treasury_interest,
	))
	var treasury_limit := int(treasury.get("credit_limit_cents", 0))
	var treasury_headroom := int(treasury.get("credit_headroom_cents", 0))
	var treasury_rate := float(treasury.get(
		"interest_percent",
		float(int(treasury.get("interest_basis_points", 0))) / 100.0,
	))
	var treasury_frozen := bool(treasury.get("capital_frozen", false))

	_headcount_label.text = "%d / %d  ·  MAX %d" % [active_count, capacity, maximum]
	_headcount_label.add_theme_color_override("font_color", COLOR_RUST if active_count > capacity else COLOR_TEAL)
	_costs_label.text = "RESERVED  $%.2f/day  ·  payroll $%.2f  ·  facility $%.2f\nSPENDABLE FEED FUND  $%.2f" % [
		operating / 100.0,
		payroll / 100.0,
		facility / 100.0,
		spendable / 100.0,
	]
	_treasury_label.text = (
		"TREASURY  %s  |  LINE $%.2f / $%.2f  |  HEADROOM $%.2f  |  %.2f%% / SHIFT"
		% [
			String(treasury.get("rating_label", "FIELD FILE")),
			treasury_principal / 100.0,
			treasury_limit / 100.0,
			treasury_headroom / 100.0,
			treasury_rate,
		]
	)
	_treasury_label.add_theme_color_override(
		"font_color",
		COLOR_RUST if treasury_liabilities > 0 else COLOR_TEAL,
	)
	_treasury_label.tooltip_text = "The Farm Treasury files immutable shift-close receipts. Credit can pay vendors and interest, never wages."
	_arrears_label.visible = arrears + treasury_liabilities > 0
	_arrears_label.text = (
		"%sWAGE ARREARS  $%.2f  |  CREDIT $%.2f  |  VENDORS $%.2f  |  INTEREST $%.2f"
		% [
			"CAPITAL FROZEN\n" if treasury_frozen else "",
			arrears / 100.0,
			treasury_principal / 100.0,
			treasury_vendor / 100.0,
			treasury_interest / 100.0,
		]
	)
	_farmer_relations_gallery_ui.apply_snapshot(_snapshot)
	_farmgate_dispatch_ui.apply_snapshot(_snapshot)
	_feed_procurement_ui.apply_snapshot(_snapshot)
	_refresh_capital_plan()
	_planning_label.text = "SCREENED APPLICANTS" if planning_open else "SCREENED APPLICANTS  ·  FILE LOCKED"
	_planning_label.tooltip_text = (
		"Staffing changes are available while the planning file is open."
		if planning_open else
		"Pause during an active shift or enter a planning review to change headcount."
	)

	_refresh_capacity_button(capacity, maximum, spendable, planning_open)
	_refresh_operations()
	_flock_relations_ui.apply_snapshot(_snapshot)
	_refresh_flock_care()
	_refresh_facilities(spendable, operating, planning_open)
	_refresh_applicants(spendable, planning_open)
	_refresh_release_controls(spendable, planning_open)
	_refresh_last_action()


func _refresh_capital_plan() -> void:
	if _capital_blueprint_button == null or _capital_plan_label == null:
		return
	var plan_value: Variant = _snapshot.get("capital_plan", {})
	var plan := plan_value as Dictionary if plan_value is Dictionary else {}
	var facility_id := StringName(String(plan.get(
		"pinned_capital_plan_id",
		plan.get("facility_id", plan.get("id", "")),
	)))
	var pinned_status_value: Variant = plan.get("facility", plan)
	var facility_plan := pinned_status_value as Dictionary if pinned_status_value is Dictionary else plan
	var ready_count := 0
	for facility_value in _snapshot.get("facility_catalog", []):
		if facility_value is Dictionary:
			var facility := facility_value as Dictionary
			if not bool(facility.get("maxed", false)) and bool(facility.get("can_purchase", false)):
				ready_count += 1
	_capital_blueprint_button.text = (
		"OPEN CAPITAL BLUEPRINT  /  %d READY" % ready_count
		if ready_count > 0 else
		"OPEN CAPITAL BLUEPRINT"
	)
	if facility_id == &"":
		_capital_plan_label.text = "NO PLAN PINNED  /  Compare exact benefits, gates, capital, and daily liability."
		_capital_plan_label.add_theme_color_override("font_color", COLOR_MUTED)
		return
	var display_name := String(facility_plan.get(
		"short_name", facility_plan.get("display_name", facility_plan.get("name", String(facility_id).replace("_", " ")))
	)).to_upper()
	var ready := bool(facility_plan.get("ready", facility_plan.get("can_purchase", false)))
	var shortfall := maxi(0, int(facility_plan.get("fund_shortfall_cents", facility_plan.get("shortfall_cents", 0))))
	var gate_current := maxi(0, int(facility_plan.get("gates_met", facility_plan.get("completed_gates", 0))))
	var gate_total := maxi(gate_current, int(facility_plan.get("gate_count", facility_plan.get("total_gates", gate_current))))
	_capital_plan_label.text = (
		"PINNED  /  %s  /  READY TO COMMISSION" % display_name
		if ready else
		"PINNED  /  %s  /  GATES %d/%d%s" % [
			display_name,
			gate_current,
			gate_total,
			"  /  $%.2f SHORT" % (float(shortfall) / 100.0) if shortfall > 0 else "",
		]
	)
	_capital_plan_label.add_theme_color_override("font_color", COLOR_TEAL if ready else COLOR_BRASS)


func _build_operations_section() -> void:
	_operations_section = PanelContainer.new()
	_operations_section.name = "RoosterOperationsSection"
	_operations_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operations_section.add_theme_stylebox_override("panel", _facility_card_style(true, false, true))
	_operations_section.visible = false
	_operations_domain.add_child(_operations_section)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_operations_section.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(column)

	var heading := _make_label("ROOSTER OPERATIONS", 12, COLOR_BRASS)
	heading.name = "RoosterOperationsHeading"
	column.add_child(heading)
	_operations_supervision_label = _make_label("", 11, COLOR_TEAL)
	_operations_supervision_label.name = "RoosterOperationsSupervision"
	_operations_supervision_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_operations_supervision_label)
	_operations_pressure_label = _make_label("", 10, COLOR_MUTED)
	_operations_pressure_label.name = "RoosterOperationsPressure"
	_operations_pressure_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_operations_pressure_label)
	_operations_automation_label = _make_label("", 11, COLOR_TEAL)
	_operations_automation_label.name = "RoosterOperationsAutomation"
	_operations_automation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_operations_automation_label)
	_operations_exposure_label = _make_label("", 10, COLOR_MUTED)
	_operations_exposure_label.name = "RoosterOperationsExposure"
	_operations_exposure_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_operations_exposure_label)
	_operations_next_action_label = _make_label("", 10, Color("d7c17d"))
	_operations_next_action_label.name = "RoosterOperationsNextAction"
	_operations_next_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_operations_next_action_label)


func _refresh_operations() -> void:
	var operations := _operations_snapshot()
	_operations_section.visible = not operations.is_empty()
	if operations.is_empty():
		return

	var supervision := operations.get("supervision", {}) as Dictionary
	var rooster_level := maxi(0, int(operations.get(
		"rooster_office_level",
		supervision.get("level", 0),
	)))
	var action_limit := maxi(1, int(supervision.get("action_limit", supervision.get("limit", 1))))
	var actions_used := clampi(
		int(supervision.get("actions_used", supervision.get("used", 0))),
		0,
		action_limit,
	)
	var actions_remaining := clampi(
		int(supervision.get(
			"actions_remaining",
			supervision.get("remaining", action_limit - actions_used),
		)),
		0,
		action_limit,
	)
	var supervisor_payroll := maxi(0, int(supervision.get("supervisor_payroll_cents", 0)))
	_operations_supervision_label.text = (
		"ROOSTER OFFICE  L%d  /  CHECK-INS  %d / %d  /  %d LEFT\nSUPERVISOR PAYROLL  $%.2f/day"
		% [rooster_level, actions_used, action_limit, actions_remaining, float(supervisor_payroll) / 100.0]
	)
	_operations_supervision_label.tooltip_text = (
		"The Rooster Operations Office raises the flock-wide check-in allowance. "
		+ "A named hen may still receive at most one personnel action per shift."
	)

	var grievance_mp := maxi(0, int(supervision.get("surveillance_grievance_millipoints", 0)))
	var stress_mp := maxi(0, int(supervision.get("surveillance_stress_millipoints", 0)))
	var solidarity_mp := maxi(0, int(supervision.get("surveillance_solidarity_millipoints", 0)))
	_operations_pressure_label.text = (
		"SURVEILLANCE / HEN  +%s grievance  /  +%s stress\nFLOCK UNITY RISK  +%s / shift"
		% [
			_millipoints_copy(grievance_mp),
			_millipoints_copy(stress_mp),
			_millipoints_copy(solidarity_mp),
		]
	)
	_operations_pressure_label.add_theme_color_override(
		"font_color",
		COLOR_RUST if grievance_mp + stress_mp + solidarity_mp > 0 else COLOR_MUTED,
	)
	_operations_pressure_label.tooltip_text = "These once-per-shift pressure values come directly from the authoritative operations ledger."

	var automation := operations.get("automation", {}) as Dictionary
	var it_level := maxi(0, int(operations.get("it_coop_level", automation.get("level", 0))))
	var automation_enabled := bool(automation.get("enabled", it_level > 0))
	var work_basis_points := maxi(0, int(automation.get("work_basis_points", 10_000)))
	var work_bonus_percent := snappedf(float(work_basis_points - 10_000) / 100.0, 0.1)
	var specialty_grace := maxi(0, int(automation.get("specialty_grace_minutes", 180)))
	var recognizes_secondary := bool(automation.get("recognizes_secondary_specialties", false))
	_operations_automation_label.text = (
		"IT COOP  L%d  /  AUTO %s  /  %dm SPECIALTY GRACE\nSECONDARY CREDENTIALS  %s"
		% [
			it_level,
			("+%s%% PACE" % _compact_number(work_bonus_percent)) if automation_enabled else "LOCAL PACE",
			specialty_grace,
			"RECOGNIZED" if recognizes_secondary else "PRIMARY ONLY",
		]
	)
	_operations_automation_label.tooltip_text = (
		"IT support applies only while an employed hen is assigned AUTO. "
		+ "A manual NEST, PREDATOR, or APPEALS route is an explicit override."
	)

	var compliance_mp := maxi(0, int(automation.get("compliance_exposure_millipoints", 0)))
	_operations_exposure_label.text = (
		"COMPLIANCE EXPOSURE  -%s / shift"
		% _millipoints_copy(compliance_mp)
		if compliance_mp > 0 else
		"COMPLIANCE EXPOSURE  NONE"
	)
	_operations_exposure_label.add_theme_color_override(
		"font_color",
		COLOR_RUST if compliance_mp > 0 else COLOR_MUTED,
	)
	_operations_exposure_label.tooltip_text = "The exposure settles once per shift; it is not inferred from the visible compliance meter."

	var next_action := operations.get("next_operations_action", {}) as Dictionary
	_operations_next_action_label.visible = not next_action.is_empty()
	if not next_action.is_empty():
		_operations_next_action_label.text = _operations_action_copy(next_action)
		_operations_next_action_label.tooltip_text = String(next_action.get(
			"reason",
			next_action.get("action_reason", "The next operations requisition is listed in Capital Expansions below."),
		))


func _build_flock_care_section() -> void:
	_care_section = PanelContainer.new()
	_care_section.name = "FlockCareSection"
	_care_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_care_section.add_theme_stylebox_override("panel", _facility_card_style(true, false, true))
	_care_section.visible = false
	_flock_domain.add_child(_care_section)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_care_section.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(column)

	var heading := _make_label("FLOCK CARE & TRAINING", 12, COLOR_BRASS)
	heading.name = "FlockCareHeading"
	column.add_child(heading)
	_care_gate_label = _make_label("RESTED FLOCK", 11, COLOR_TEAL)
	_care_gate_label.name = "FlockCareRestedGate"
	_care_gate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_care_gate_label)
	_care_wellness_label = _make_label("", 11, COLOR_MUTED)
	_care_wellness_label.name = "FlockCareWellnessSummary"
	_care_wellness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_care_wellness_label)
	_care_training_label = _make_label("", 11, COLOR_MUTED)
	_care_training_label.name = "FlockCareTrainingSummary"
	_care_training_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_care_training_label)
	_care_next_action_label = _make_label("", 10, Color("d7c17d"))
	_care_next_action_label.name = "FlockCareNextAction"
	_care_next_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_care_next_action_label)


func _refresh_flock_care() -> void:
	var care := _flock_care_snapshot()
	_care_section.visible = not care.is_empty()
	if care.is_empty():
		return

	var rested := care.get("rested_flock", {}) as Dictionary
	var welfare := roundi(float(care.get("welfare", care.get("welfare_score", 0.0))))
	var gate := maxi(0, int(care.get("rested_flock_gate", rested.get("minimum", 72))))
	var margin := int(care.get("welfare_delta_to_gate", rested.get("margin", welfare - gate)))
	var gate_met := bool(rested.get("met", margin >= 0))
	_care_gate_label.text = "RESTED FLOCK  %d / %d  /  %s" % [
		welfare,
		gate,
		"ON TRACK" if gate_met else "%d SHORT" % absi(margin),
	]
	_care_gate_label.add_theme_color_override("font_color", COLOR_TEAL if gate_met else COLOR_RUST)
	_care_gate_label.tooltip_text = (
		"Current flock welfare clears the Rested Flock rider's settlement gate."
		if gate_met else
		"Current flock welfare is %d point%s below the Rested Flock settlement gate." % [
			absi(margin),
			"" if absi(margin) == 1 else "s",
		]
	)

	var recovery := care.get("recovery_effects", care.get("effects", {})) as Dictionary
	var wellness_level := maxi(0, int(care.get(
		"wellness_level",
		(care.get("wellness_nest", {}) as Dictionary).get("level", 0),
	)))
	var breaks_active := maxi(0, int(care.get("breaks_active", care.get("active_breaks", 0))))
	var recovery_perches := maxi(0, int(care.get(
		"recovery_perch_count",
		recovery.get("recovery_perch_count", recovery.get("break_capacity", 0)),
	)))
	var strain_multiplier := float(recovery.get(
		"strain_multiplier",
		recovery.get("wellness_strain_gain_multiplier", 1.0),
	))
	var break_multiplier := float(recovery.get(
		"break_recovery_multiplier",
		recovery.get("wellness_break_recovery_multiplier", 1.0),
	))
	_care_wellness_label.text = (
		"WELLNESS NEST  L%d  /  RESTING %d / %d\nSTRAIN %s  /  BREAK RECOVERY %s"
		% [
			wellness_level,
			breaks_active,
			recovery_perches,
			_multiplier_delta_copy(strain_multiplier),
			_multiplier_delta_copy(break_multiplier),
		]
	)
	_care_wellness_label.tooltip_text = _wellness_care_tooltip(recovery)

	var training_terms := care.get("training_terms", {}) as Dictionary
	var training_level := maxi(0, int(care.get(
		"training_roost_level",
		(care.get("training_roost", {}) as Dictionary).get("level", 0),
	)))
	var training_value: Variant = care.get("training_active", [])
	var training_active := 0
	if training_value is Array:
		training_active = (training_value as Array).size()
	else:
		training_active = maxi(0, int(training_value))
	var effective_cost := maxi(0, int(training_terms.get(
		"effective_sponsorship_cost_cents",
		training_terms.get("effective_cost_cents", 1200),
	)))
	var work_penalty := _training_work_penalty(training_terms)
	var coaching_bonus := maxi(0, int(training_terms.get("coaching_xp_bonus", 0)))
	_care_training_label.text = (
		"TRAINING ROOST  L%d  /  %d ACTIVE\nSPONSORSHIP $%.2f  /  TRAINING %s  /  COACHING +%d XP"
		% [
			training_level,
			training_active,
			float(effective_cost) / 100.0,
			"FULL SPEED" if work_penalty <= 0.05 else "-%s%%" % _compact_number(work_penalty),
			coaching_bonus,
		]
	)
	_care_training_label.tooltip_text = _training_care_tooltip(training_terms)

	var next_action := care.get("next_care_action", {}) as Dictionary
	_care_next_action_label.visible = not next_action.is_empty()
	if not next_action.is_empty():
		_care_next_action_label.text = _care_action_copy(next_action)
		_care_next_action_label.tooltip_text = String(next_action.get(
			"reason",
			next_action.get("action_reason", "The next flock-care requisition is listed in Capital Expansions below."),
		))


func _refresh_capacity_button(capacity: int, maximum: int, spendable: int, planning_open: bool) -> void:
	var upgrade := _snapshot.get("capacity_upgrade", {}) as Dictionary
	var cost := int(upgrade.get("cost_cents", upgrade.get("cost", 0)))
	var next_capacity := int(upgrade.get("next_capacity", mini(maximum, capacity + 1)))
	var maxed := bool(upgrade.get("maxed", capacity >= maximum)) or capacity >= maximum
	var authoritative_can_purchase := bool(upgrade.get("can_purchase", upgrade.get("available", not maxed)))
	var affordable := spendable >= cost
	var enabled := planning_open and not maxed and authoritative_can_purchase and affordable
	_capacity_button.text = (
		"ROOST CAPACITY FULL  ·  %d PERCHES" % maximum
		if maxed else
		"AUTHORIZE PERCH %d  ·  $%.2f" % [next_capacity, cost / 100.0]
	)
	_capacity_button.disabled = not enabled
	var reason := String(upgrade.get("reason", ""))
	if reason.is_empty() and not planning_open:
		reason = "The staffing file is locked until management pauses for planning."
	elif reason.is_empty() and maxed:
		reason = "Every approved workstation is already authorized."
	elif reason.is_empty() and not affordable:
		reason = "Spendable Feed Fund is short by $%.2f." % ((cost - spendable) / 100.0)
	elif reason.is_empty() and not authoritative_can_purchase:
		reason = "This capacity requisition is not currently authorized."
	_capacity_button.tooltip_text = (
		"Spend $%.2f to reveal one staffed workstation without touching reserved operating costs." % (cost / 100.0)
		if enabled else
		"CAPACITY HELD: %s" % reason
	)


func _refresh_facilities(spendable: int, operating: int, planning_open: bool) -> void:
	# Flockwatch reparents each domain root into its own page. Capture navigation
	# from the Capital presentation branch itself; `self` remains the signal owner
	# but is no longer an ancestor of these cards or their page scroll.
	var presentation_anchor := _facility_presentation_anchor()
	var focused_facility_id := _focused_facility_id(presentation_anchor)
	var ledger_scroll := _ancestor_scroll_container(presentation_anchor)
	var prior_scroll := ledger_scroll.scroll_vertical if ledger_scroll != null else -1
	_facility_refresh_serial += 1
	var refresh_serial := _facility_refresh_serial
	_clear_children(_facility_list)
	var catalog := _facility_entries()
	_facilities_section.visible = not catalog.is_empty()
	_facility_list.visible = _inline_facilities_open and not catalog.is_empty()
	if _inline_facilities_toggle != null:
		_inline_facilities_toggle.text = "HIDE" if _inline_facilities_open else "SHOW"
		_inline_facilities_toggle.tooltip_text = (
			"Collapse the inline card list and return to the compact ledger."
			if _inline_facilities_open else
			"Open the legacy card list here; Capital Blueprint is the clearer comparison view."
		)
	if catalog.is_empty():
		_restore_facility_navigation.call_deferred(
			refresh_serial, ledger_scroll, prior_scroll, focused_facility_id
		)
		return
	for facility in catalog:
		_build_facility_card(facility, spendable, operating, planning_open)
	_restore_facility_navigation.call_deferred(
		refresh_serial, ledger_scroll, prior_scroll, focused_facility_id
	)


func _on_inline_facilities_toggle_pressed() -> void:
	_inline_facilities_open = not _inline_facilities_open
	_facility_list.visible = _inline_facilities_open
	_inline_facilities_toggle.text = "HIDE" if _inline_facilities_open else "SHOW"


func _build_facility_card(
	facility: Dictionary,
	spendable: int,
	operating: int,
	default_planning_open: bool
) -> void:
	var facility_id := StringName(String(facility.get("id", "")))
	var node_suffix := _safe_node_suffix(String(facility_id))
	var display_name := String(facility.get("display_name", facility.get("name", facility.get("short_name", "UNFILED FACILITY"))))
	var short_name := String(facility.get("short_name", display_name))
	var description := String(facility.get("description", "A proposed addition to the claims floor."))
	var level := _facility_level(facility_id, facility)
	var max_level := maxi(1, int(facility.get("max_level", 1)))
	var installed := bool(facility.get("installed", level > 0 or _facility_is_owned(facility_id, facility)))
	if installed and level <= 0:
		level = 1
	var maxed := bool(facility.get("maxed", level >= max_level))
	# A legacy `owned` record represented a one-and-done facility. Preserve that
	# contract, while explicit level/max_level records remain upgradeable.
	if not facility.has("level") and not facility.has("max_level") and _facility_is_owned(facility_id, facility):
		maxed = true
	var next_level := mini(max_level, int(facility.get("next_level", level + 1)))
	var capital_cost := int(facility.get(
		"next_level_cost_cents",
		facility.get("cost_cents", facility.get("capital_cost_cents", 0)),
	))
	var legacy_maintenance := int(facility.get("daily_maintenance_cents", facility.get("maintenance_cents", 0)))
	var current_maintenance := int(facility.get("current_maintenance_cents", legacy_maintenance if installed else 0))
	var next_maintenance := int(facility.get("next_maintenance_cents", current_maintenance + (0 if installed else legacy_maintenance)))
	var maintenance_delta := int(facility.get("maintenance_delta_cents", next_maintenance - current_maintenance))
	var required_spendable := int(facility.get("required_spendable_cents", capital_cost + maxi(0, maintenance_delta)))
	var unlocked := bool(facility.get("unlocked", true))
	var planning_open := bool(facility.get("planning_open", default_planning_open))
	var affordable := bool(facility.get("affordable", spendable >= required_spendable))
	var authoritative_can_purchase := bool(facility.get("can_purchase", true))
	var has_identity := not String(facility_id).is_empty()
	var enabled := (
		has_identity
		and not maxed
		and unlocked
		and planning_open
		and affordable
		and authoritative_can_purchase
	)

	var card := PanelContainer.new()
	card.name = "FacilityCard_%s" % node_suffix
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _facility_card_style(installed, enabled, unlocked))
	_facility_list.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 9)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(column)

	# Stack identity and status so the card remains genuinely narrow inside the
	# live Flockwatch ledger. A horizontal header made the panel claim nearly
	# twice its authored width once a long facility name entered the catalog.
	var heading_row := VBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 3)
	column.add_child(heading_row)
	var name_label := _make_label(display_name.to_upper(), 14, Color("eef1df"))
	name_label.name = "FacilityName_%s" % node_suffix
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading_row.add_child(name_label)
	var status_label := _make_label(
		_facility_status(installed, maxed, unlocked, planning_open, affordable, authoritative_can_purchase),
		10,
		_facility_status_color(installed, enabled, unlocked, affordable),
	)
	status_label.name = "FacilityStatus_%s" % node_suffix
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	status_label.custom_minimum_size.y = 22.0
	status_label.add_theme_stylebox_override("normal", _facility_status_style(installed, enabled, unlocked, affordable))
	status_label.tooltip_text = _facility_reason(
		facility,
		installed,
		maxed,
		unlocked,
		planning_open,
		affordable,
		authoritative_can_purchase,
		required_spendable,
		spendable,
		has_identity,
		level,
		max_level,
	)
	heading_row.add_child(status_label)

	var level_label := _make_label(
		"LEVEL %d / %d  ·  NEXT TIER %d" % [level, max_level, next_level]
		if not maxed else
		"LEVEL %d / %d  ·  EXPANSION COMPLETE" % [level, max_level],
		10,
		COLOR_TEAL if installed else COLOR_MUTED,
	)
	level_label.name = "FacilityLevel_%s" % node_suffix
	level_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading_row.add_child(level_label)

	var description_label := _make_label(description, 11, COLOR_MUTED)
	description_label.name = "FacilityDescription_%s" % node_suffix
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description_label)

	var cost_flow := HFlowContainer.new()
	cost_flow.name = "FacilityCosts_%s" % node_suffix
	cost_flow.add_theme_constant_override("h_separation", 12)
	cost_flow.add_theme_constant_override("v_separation", 2)
	cost_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(cost_flow)
	var capital_copy := (
		"CAPITAL COMPLETE"
		if maxed else
		"NEXT CAPITAL  $%.2f" % (capital_cost / 100.0)
		if installed else
		"BUILD CAPITAL  $%.2f" % (capital_cost / 100.0)
	)
	cost_flow.add_child(_make_label(capital_copy, 11, COLOR_BRASS))
	var maintenance_copy := (
		"UPKEEP  $%.2f/day" % (current_maintenance / 100.0)
		if maxed else
		"MAINTENANCE Δ  %s$%.2f/day" % ["+" if maintenance_delta >= 0 else "−", absf(maintenance_delta / 100.0)]
	)
	cost_flow.add_child(_make_label(maintenance_copy, 11, COLOR_RUST if maintenance_delta > 0 else COLOR_MUTED))
	if not maxed:
		cost_flow.add_child(_make_label("NEXT UPKEEP  $%.2f/day" % (next_maintenance / 100.0), 10, COLOR_MUTED))
	if facility_id == &"records_annex":
		var current_claim_capacity := int(facility.get("current_claim_capacity", 18))
		var next_claim_capacity := int(facility.get("next_claim_capacity", current_claim_capacity))
		var capacity_copy := (
			"LIVE FILE ROOSTS  %d" % current_claim_capacity
			if maxed else
			"LIVE FILE ROOSTS  %d → %d" % [current_claim_capacity, next_claim_capacity]
		)
		cost_flow.add_child(_make_label(capacity_copy, 11, COLOR_TEAL))
	if facility_id == &"farm_mutual_service_coop":
		var service_gate := _make_label(
			_service_coop_gate_copy(facility, next_level, maxed),
			11,
			_service_coop_gate_color(facility, maxed),
		)
		service_gate.name = "FacilityServiceCoopGate_%s" % node_suffix
		service_gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		service_gate.tooltip_text = (
			"Every listed standing, live-file archive, and active-hen requirement must clear before the next Service Coop tier can be commissioned. "
			+ "Its premium bonus applies only when a signed Farm Mutual binder succeeds."
		)
		column.add_child(service_gate)
	if facility_id == &"farm_mutual_negotiation_room":
		var negotiation_gate := _make_label(
			_negotiation_room_gate_copy(facility, maxed),
			11,
			_negotiation_room_gate_color(facility, maxed),
		)
		negotiation_gate.name = "FacilityNegotiationRoomGate_%s" % node_suffix
		negotiation_gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		negotiation_gate.tooltip_text = (
			"Gold Farm Mutual standing and the completed Service Coop are structural prerequisites. "
			+ "Once built, the room remains commissioned and unlocks one disclosed rider per binder."
		)
		column.add_child(negotiation_gate)
	if facility_id == &"training_roost" and _has_training_wellness_gate(facility):
		var training_gate := _make_label(
			_training_wellness_gate_copy(facility),
			11,
			_training_wellness_gate_color(facility),
		)
		training_gate.name = "FacilityTrainingWellnessGate_%s" % node_suffix
		training_gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		training_gate.tooltip_text = "Training Roost tiers require a matching Wellness Nest tier so coaching capacity never outruns recovery capacity."
		column.add_child(training_gate)
	if facility_id in [&"wellness_nest_room", &"training_roost"]:
		var care_delta := _make_label(_care_facility_delta_copy(facility_id, facility, maxed), 11, COLOR_TEAL)
		care_delta.name = "FacilityCareDelta_%s" % node_suffix
		care_delta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		care_delta.tooltip_text = "Current and next-tier values come directly from the facilities ledger."
		column.add_child(care_delta)
	if facility_id in [&"rooster_operations_office", &"it_coop"]:
		var operations_delta := _make_label(
			_operations_facility_delta_copy(facility_id, facility, maxed),
			11,
			COLOR_TEAL,
		)
		operations_delta.name = "FacilityOperationsDelta_%s" % node_suffix
		operations_delta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		operations_delta.tooltip_text = (
			"Current and next-tier supervision or AUTO-support values come directly from the facilities ledger."
		)
		column.add_child(operations_delta)
	if facility_id == &"flock_relations_office":
		var relations_gate := _make_label(
			_flock_relations_gate_copy(facility),
			11,
			_flock_relations_gate_color(facility),
		)
		relations_gate.name = "FacilityFlockRelationsGate_%s" % node_suffix
		relations_gate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		relations_gate.tooltip_text = (
			"A matching Rooster Operations tier supplies authority; a matching Wellness Nest tier supplies an actual remedy path. "
			+ "Both permanent dependencies must be commissioned before the next labor-case tier."
		)
		column.add_child(relations_gate)
		var relations_delta := _make_label(
			_flock_relations_delta_copy(facility, maxed),
			11,
			COLOR_MULBERRY,
		)
		relations_delta.name = "FacilityFlockRelationsDelta_%s" % node_suffix
		relations_delta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		relations_delta.tooltip_text = (
			"Case slots hold unresolved named-hen files. Review authorizations limit how many real cases management may resolve before the next shift."
		)
		column.add_child(relations_delta)
	if facility_id == &"feed_procurement_coop":
		var provisions_delta := _make_label(
			_feed_procurement_delta_copy(facility, maxed),
			11,
			COLOR_TEAL,
		)
		provisions_delta.name = "FacilityFeedProcurementDelta_%s" % node_suffix
		provisions_delta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		provisions_delta.tooltip_text = (
			"Bin capacity and supplier access come directly from the facility ledger. "
			+ "Stored lots still expire, and uncovered demand remains a seasonal spot obligation."
		)
		column.add_child(provisions_delta)

	var benefits_label := _make_label(_facility_benefits_copy(facility), 11, COLOR_TEAL)
	benefits_label.name = "FacilityBenefits_%s" % node_suffix
	benefits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	benefits_label.tooltip_text = "These are the economic effects activated when %s is installed." % display_name
	column.add_child(benefits_label)

	var projected_spendable := int(facility.get("projected_spendable_fund_cents", spendable - required_spendable))
	var projected_reserve := int(facility.get(
		"projected_protected_reserve_cents",
		facility.get("projected_daily_operating_cost_cents", operating if maxed else operating + maintenance_delta),
	))
	var projection_label := _make_label(
		"CURRENT RESERVE  $%.2f/day protected  ·  $%.2f spendable" % [operating / 100.0, spendable / 100.0]
		if maxed else
		"AFTER LEVEL %d  $%.2f spendable  ·  $%.2f/day protected reserve" % [next_level, projected_spendable / 100.0, projected_reserve / 100.0]
		if installed else
		"AFTER BUILD  $%.2f spendable  ·  $%.2f/day protected reserve" % [projected_spendable / 100.0, projected_reserve / 100.0],
		11,
		Color("d7c17d"),
	)
	projection_label.name = "FacilityProjection_%s" % node_suffix
	projection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	projection_label.tooltip_text = "The protected reserve covers projected payroll, feed, and facility obligations before discretionary spending."
	column.add_child(projection_label)

	var reason := _facility_reason(
		facility,
		installed,
		maxed,
		unlocked,
		planning_open,
		affordable,
		authoritative_can_purchase,
		required_spendable,
		spendable,
		has_identity,
		level,
		max_level,
	)
	var purchase_button := Button.new()
	purchase_button.name = "PurchaseFacility_%s" % node_suffix
	purchase_button.theme_type_variation = &"PrimaryButton"
	purchase_button.custom_minimum_size.y = 50.0
	purchase_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	purchase_button.focus_mode = Control.FOCUS_ALL
	purchase_button.set_meta("facility_id", facility_id)
	purchase_button.text = _facility_button_copy(
		facility,
		short_name,
		capital_cost,
		installed,
		maxed,
		unlocked,
		planning_open,
		affordable,
		authoritative_can_purchase,
		next_level,
		level,
		max_level,
	)
	purchase_button.disabled = not enabled
	purchase_button.tooltip_text = (
		"%s %s to level %d for $%.2f. Maintenance changes by %s$%.2f/day; the listed economic effects activate immediately." % [
			"Upgrade" if installed else "Build",
			display_name,
			next_level,
			capital_cost / 100.0,
			"+" if maintenance_delta >= 0 else "−",
			absf(maintenance_delta / 100.0),
		]
		if enabled else
		"FACILITY HELD: %s" % reason
	)
	purchase_button.pressed.connect(func() -> void: facility_purchase_requested.emit(facility_id))
	column.add_child(purchase_button)

	if not enabled:
		var reason_label := _make_label(
			"OPERATING  ·  Level %d/%d benefits active; upkeep is in the protected reserve." % [level, max_level]
			if maxed else
			"HELD  ·  %s" % reason,
			10,
			COLOR_TEAL if maxed else COLOR_RUST,
		)
		reason_label.name = "FacilityReason_%s" % node_suffix
		reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(reason_label)


func _facility_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for facility_value in _snapshot.get("facility_catalog", []):
		if facility_value is Dictionary:
			result.append((facility_value as Dictionary).duplicate(true))
	return result


func _operations_snapshot() -> Dictionary:
	var operations_value: Variant = _snapshot.get("operations", {})
	if operations_value is Dictionary and not (operations_value as Dictionary).is_empty():
		return (operations_value as Dictionary).duplicate(true)
	return {}


func _flock_care_snapshot() -> Dictionary:
	var care_value: Variant = _snapshot.get("flock_care", {})
	if care_value is Dictionary and not (care_value as Dictionary).is_empty():
		return (care_value as Dictionary).duplicate(true)
	# Legacy fixtures predate the compact presentation contract. Keep their live
	# welfare readable without reconstructing facility economics in the UI.
	if _snapshot.has("flock_welfare"):
		var welfare := roundi(float(_snapshot.get("flock_welfare", 0.0)))
		return {
			"welfare": welfare,
			"rested_flock_gate": int(_snapshot.get("rested_flock_gate", 72)),
			"welfare_delta_to_gate": int(_snapshot.get(
				"welfare_delta_to_gate",
				welfare - int(_snapshot.get("rested_flock_gate", 72)),
			)),
			"wellness_level": int(_snapshot.get("wellness_level", 0)),
			"training_roost_level": int(_snapshot.get("training_roost_level", 0)),
			"breaks_active": int(_snapshot.get("breaks_active", 0)),
			"recovery_perch_count": int(_snapshot.get("recovery_perch_count", 0)),
			"recovery_effects": (_snapshot.get("recovery_effects", {}) as Dictionary).duplicate(true),
			"training_terms": (_snapshot.get("training_terms", {}) as Dictionary).duplicate(true),
		}
	return {}


func _multiplier_delta_copy(multiplier: float) -> String:
	var delta := snappedf((multiplier - 1.0) * 100.0, 0.1)
	if absf(delta) <= 0.05:
		return "BASELINE"
	return "%s%s%%" % ["+" if delta > 0.0 else "-", _compact_number(absf(delta))]


func _compact_number(value: float) -> String:
	var rounded := snappedf(value, 0.1)
	return str(roundi(rounded)) if is_equal_approx(rounded, float(roundi(rounded))) else "%.1f" % rounded


func _millipoints_copy(value: int) -> String:
	var points := snappedf(float(value) / 1000.0, 0.01)
	if is_equal_approx(points, float(roundi(points))):
		return str(roundi(points))
	if is_equal_approx(points * 10.0, float(roundi(points * 10.0))):
		return "%.1f" % points
	return "%.2f" % points


func _operations_action_copy(action: Dictionary) -> String:
	if bool(action.get("complete", false)):
		return String(action.get("label", "OPERATIONS CAMPUS FULLY COMMISSIONED")).to_upper()
	var facility_id := String(action.get("facility_id", action.get("id", "operations_expansion")))
	var level_name := String(action.get(
		"next_level_name",
		action.get("display_name", facility_id.replace("_", " ").capitalize()),
	)).to_upper()
	var next_level := maxi(1, int(action.get("next_level", action.get("level", 1))))
	var capital_cost := maxi(0, int(action.get(
		"cost_cents",
		action.get("capital_cost_cents", action.get("next_level_cost_cents", 0)),
	)))
	var daily_delta := int(action.get(
		"added_daily_operating_cents",
		int(action.get("maintenance_delta_cents", 0))
		+ int(action.get("supervisor_payroll_delta_cents", 0)),
	))
	var ready := bool(action.get("can_purchase", action.get("available", false)))
	return "%s  %s L%d  /  $%.2f CAPITAL  /  %s$%.2f/DAY" % [
		"NEXT OPERATIONS FILE" if ready else "NEXT OPERATIONS GATE",
		level_name,
		next_level,
		float(capital_cost) / 100.0,
		"+" if daily_delta >= 0 else "-",
		absf(float(daily_delta) / 100.0),
	]


func _training_work_penalty(training_terms: Dictionary) -> float:
	if training_terms.has("work_penalty_percent"):
		return maxf(0.0, float(training_terms.get("work_penalty_percent", 0.0)))
	var multiplier := float(training_terms.get(
		"effective_work_multiplier",
		training_terms.get("pending_work_multiplier", 0.85),
	))
	return maxf(0.0, snappedf((1.0 - multiplier) * 100.0, 0.1))


func _wellness_care_tooltip(recovery: Dictionary) -> String:
	var fatigue_bonus := maxi(0, int(recovery.get(
		"overnight_fatigue_recovery_bonus",
		recovery.get("overnight_fatigue_bonus", 0),
	)))
	var stress_bonus := maxi(0, int(recovery.get(
		"overnight_stress_recovery_bonus",
		recovery.get("overnight_stress_bonus", 0),
	)))
	var morale_gain := float(recovery.get(
		"break_morale_gain",
		recovery.get("break_morale_per_tick", recovery.get("break_morale", 0.0)),
	))
	return "Wellness Nest equipment changes worked-shift strain and recovery at the physical break perches. Overnight recovery adds +%d fatigue and +%d stress points above baseline%s." % [
		fatigue_bonus,
		stress_bonus,
		"; occupied perches also restore %s morale per recovery tick" % _compact_number(morale_gain) if morale_gain > 0.0 else "",
	]


func _training_care_tooltip(training_terms: Dictionary) -> String:
	var base_cost := maxi(0, int(training_terms.get(
		"base_sponsorship_cost_cents",
		training_terms.get("base_cost_cents", 1200),
	)))
	var effective_cost := maxi(0, int(training_terms.get(
		"effective_sponsorship_cost_cents",
		training_terms.get("effective_cost_cents", base_cost),
	)))
	var discount := maxi(0, int(training_terms.get(
		"sponsorship_discount_cents",
		training_terms.get("savings_cents", base_cost - effective_cost),
	)))
	var wage_bonus := maxi(0, int(training_terms.get("wage_bonus_cents", 100)))
	return "Training Roost coaching reduces the $%.2f base sponsorship by $%.2f. A completed secondary accreditation adds $%.2f/day to payroll." % [
		float(base_cost) / 100.0,
		float(discount) / 100.0,
		float(wage_bonus) / 100.0,
	]


func _care_action_copy(action: Dictionary) -> String:
	if bool(action.get("complete", false)):
		return String(action.get("label", "FLOCK CARE PROGRAM FULLY COMMISSIONED")).to_upper()
	var facility_id := String(action.get("facility_id", action.get("id", "care_expansion")))
	var display_name := String(action.get(
		"display_name",
		action.get("name", facility_id.replace("_room", "").replace("_", " ").capitalize()),
	)).to_upper()
	var next_level := maxi(1, int(action.get("next_level", action.get("level", 1))))
	var capital_cost := maxi(0, int(action.get(
		"capital_cost_cents",
		action.get("next_level_cost_cents", action.get("cost_cents", 0)),
	)))
	var upkeep_delta := int(action.get(
		"maintenance_delta_cents",
		action.get("upkeep_delta_cents", 0),
	))
	var ready := bool(action.get("can_purchase", action.get("available", false)))
	return "%s  %s L%d  /  $%.2f CAPITAL  /  %s$%.2f/DAY" % [
		"NEXT CARE FILE" if ready else "NEXT CARE GATE",
		display_name,
		next_level,
		float(capital_cost) / 100.0,
		"+" if upkeep_delta >= 0 else "-",
		absf(float(upkeep_delta) / 100.0),
	]


func _facility_presentation_anchor() -> Control:
	var viewport := get_viewport()
	var focus_owner := viewport.gui_get_focus_owner() if viewport != null else null
	if (
		focus_owner != null
		and _capital_domain != null
		and (focus_owner == _capital_domain or _capital_domain.is_ancestor_of(focus_owner))
	):
		return focus_owner
	if _capital_domain != null and is_instance_valid(_capital_domain):
		return _capital_domain
	return self


func _focused_facility_id(presentation_anchor: Control = null) -> StringName:
	var focus_owner := presentation_anchor
	if (
		focus_owner == null
		or _facility_list == null
		or not is_instance_valid(_facility_list)
		or (
			focus_owner != _facility_list
			and not _facility_list.is_ancestor_of(focus_owner)
		)
	):
		return &""
	var candidate: Node = focus_owner
	while candidate != null and candidate != _facility_list:
		var facility_id := StringName(String(candidate.get_meta("facility_id", "")))
		if facility_id != &"":
			return facility_id
		candidate = candidate.get_parent()
	return &""


func _ancestor_scroll_container(presentation_anchor: Node = null) -> ScrollContainer:
	var ancestor := presentation_anchor if presentation_anchor != null else self
	while ancestor != null:
		if ancestor is ScrollContainer:
			return ancestor as ScrollContainer
		ancestor = ancestor.get_parent()
	return null


func _restore_facility_navigation(
	refresh_serial: int,
	ledger_scroll: ScrollContainer,
	prior_scroll: int,
	focused_facility_id: StringName
) -> void:
	if refresh_serial != _facility_refresh_serial:
		return
	if ledger_scroll != null and is_instance_valid(ledger_scroll) and prior_scroll >= 0:
		ledger_scroll.scroll_vertical = prior_scroll
	if focused_facility_id == &"":
		return
	var search_root: Node = (
		_facility_list
		if _facility_list != null and is_instance_valid(_facility_list) else
		_capital_domain
		if _capital_domain != null and is_instance_valid(_capital_domain) else
		self
	)
	var button := search_root.find_child(
		"PurchaseFacility_%s" % _safe_node_suffix(String(focused_facility_id)),
		true,
		false,
	) as Button
	if button != null and button.is_visible_in_tree():
		button.grab_focus()


func _facility_is_owned(facility_id: StringName, facility: Dictionary) -> bool:
	if facility.has("installed"):
		return bool(facility.get("installed", false))
	if int(facility.get("level", 0)) > 0:
		return true
	if bool(facility.get("owned", false)):
		return true
	var owned_value: Variant = _facility_owned_value(facility_id)
	if owned_value is Dictionary:
		var owned_record := owned_value as Dictionary
		return bool(owned_record.get("installed", owned_record.get("owned", int(owned_record.get("level", 1)) > 0)))
	return bool(owned_value) if owned_value != null else false


func _facility_level(facility_id: StringName, facility: Dictionary) -> int:
	if facility.has("level"):
		return maxi(0, int(facility.get("level", 0)))
	var owned_value: Variant = _facility_owned_value(facility_id)
	if owned_value is Dictionary:
		var owned_record := owned_value as Dictionary
		return maxi(0, int(owned_record.get("level", 1 if bool(owned_record.get("owned", true)) else 0)))
	if owned_value is int or owned_value is float:
		return maxi(0, int(owned_value))
	if owned_value != null and bool(owned_value):
		return 1
	return 1 if bool(facility.get("owned", false)) else 0


func _facility_owned_value(facility_id: StringName) -> Variant:
	var owned_facilities := _snapshot.get("owned_facilities", {}) as Dictionary
	if owned_facilities.has(facility_id):
		return owned_facilities.get(facility_id)
	if owned_facilities.has(String(facility_id)):
		return owned_facilities.get(String(facility_id))
	return null


func _facility_benefits_copy(facility: Dictionary) -> String:
	var benefits := _facility_copy_lines(facility.get("effects", []))
	for benefit in _facility_copy_lines(facility.get("benefits", [])):
		if not benefits.has(benefit):
			benefits.append(benefit)
	if benefits.is_empty():
		benefits.append("Benefits pending facilities review.")
	var copy := "ECONOMIC EFFECTS\n• %s" % "\n• ".join(benefits)
	var tradeoffs := _facility_copy_lines(facility.get("tradeoffs", []))
	if not tradeoffs.is_empty():
		copy += "\nOPERATING TRADEOFFS\n• %s" % "\n• ".join(tradeoffs)
	return copy


func _service_coop_gate_copy(facility: Dictionary, next_level: int, maxed: bool) -> String:
	var standing := maxi(0, int(facility.get("market_standing", 0)))
	var standing_rank := String(facility.get("market_standing_rank_label", facility.get(
		"market_standing_rank",
		"UNLISTED",
	))).to_upper()
	var required_standing := maxi(0, int(facility.get("required_market_standing", standing)))
	var claim_capacity := maxi(0, int(facility.get("current_claim_capacity", 0)))
	var required_capacity := maxi(0, int(facility.get("required_claim_capacity", claim_capacity)))
	var active_staff := maxi(0, int(facility.get("active_staff_count", 0)))
	var required_staff := maxi(0, int(facility.get("required_active_staff", active_staff)))
	var current_bonus := maxi(0, roundi(float(facility.get("premium_bonus_basis_points", 0)) / 100.0))
	var next_bonus := maxi(current_bonus, roundi(float(facility.get(
		"next_premium_bonus_basis_points",
		facility.get("premium_bonus_basis_points", 0),
	)) / 100.0))
	var gate_heading := (
		"SERVICE COOP FULLY COMMISSIONED"
		if maxed else
		"SERVICE COOP LEVEL %d GATE" % next_level
	)
	return "%s\nSTANDING  %d / %d  (%s)  //  ARCHIVE  %d / %d\nACTIVE HENS  %d / %d  //  SUCCESS-ONLY PREMIUM  +%d%% -> +%d%%" % [
		gate_heading,
		standing,
		required_standing,
		standing_rank,
		claim_capacity,
		required_capacity,
		active_staff,
		required_staff,
		current_bonus,
		next_bonus,
	]


func _service_coop_gate_color(facility: Dictionary, maxed: bool) -> Color:
	if maxed:
		return COLOR_TEAL
	var standing_ready := int(facility.get("market_standing", 0)) >= int(facility.get("required_market_standing", 0))
	var capacity_ready := int(facility.get("current_claim_capacity", 0)) >= int(facility.get("required_claim_capacity", 0))
	var staffing_ready := int(facility.get("active_staff_count", 0)) >= int(facility.get("required_active_staff", 0))
	return COLOR_TEAL if standing_ready and capacity_ready and staffing_ready else COLOR_RUST


func _negotiation_room_gate_copy(facility: Dictionary, maxed: bool) -> String:
	var standing := maxi(0, int(facility.get("market_standing", 0)))
	var required_standing := maxi(0, int(facility.get("required_market_standing", 12)))
	var standing_rank := String(facility.get(
		"market_standing_rank_label",
		facility.get("market_standing_rank", "UNLISTED"),
	)).to_upper()
	var coop_level := maxi(0, int(facility.get("service_coop_level", 0)))
	var required_coop := maxi(0, int(facility.get("required_service_coop_level", 3)))
	return "%s\nGOLD STANDING  %d / %d  (%s)  //  SERVICE COOP  %d / %d\nSIGNED BENEFIT  //  ONE SCHEDULE, SPECIALIST, OR WELFARE RIDER PER BINDER" % [
		"NEGOTIATION ROOM COMMISSIONED" if maxed else "NEGOTIATION ROOM GATE",
		standing,
		required_standing,
		standing_rank,
		coop_level,
		required_coop,
	]


func _negotiation_room_gate_color(facility: Dictionary, maxed: bool) -> Color:
	if maxed:
		return COLOR_TEAL
	var standing_ready := int(facility.get("market_standing", 0)) >= int(
		facility.get("required_market_standing", 12)
	)
	var coop_ready := int(facility.get("service_coop_level", 0)) >= int(
		facility.get("required_service_coop_level", 3)
	)
	return COLOR_TEAL if standing_ready and coop_ready else COLOR_RUST


func _has_training_wellness_gate(facility: Dictionary) -> bool:
	return (
		facility.has("required_wellness_level")
		or facility.has("required_wellness_nest_level")
		or facility.has("matching_wellness_level")
	)


func _training_wellness_gate_copy(facility: Dictionary) -> String:
	var care := _flock_care_snapshot()
	var current_level := maxi(0, int(facility.get(
		"wellness_level",
		facility.get(
			"wellness_nest_level",
			care.get(
				"wellness_level",
				(care.get("wellness_nest", {}) as Dictionary).get("level", 0),
			),
		),
	)))
	var required_level := maxi(0, int(facility.get(
		"required_wellness_level",
		facility.get("required_wellness_nest_level", facility.get("matching_wellness_level", 0)),
	)))
	return "MATCHED CARE GATE  /  WELLNESS NEST %d / %d  /  %s" % [
		current_level,
		required_level,
		"CLEARED" if current_level >= required_level else "%d TIER%s SHORT" % [
			required_level - current_level,
			"" if required_level - current_level == 1 else "S",
		],
	]


func _training_wellness_gate_color(facility: Dictionary) -> Color:
	var care := _flock_care_snapshot()
	var current_level := maxi(0, int(facility.get(
		"wellness_level",
		facility.get(
			"wellness_nest_level",
			care.get(
				"wellness_level",
				(care.get("wellness_nest", {}) as Dictionary).get("level", 0),
			),
		),
	)))
	var required_level := maxi(0, int(facility.get(
		"required_wellness_level",
		facility.get("required_wellness_nest_level", facility.get("matching_wellness_level", 0)),
	)))
	return COLOR_TEAL if current_level >= required_level else COLOR_RUST


func _operations_facility_delta_copy(
	facility_id: StringName,
	facility: Dictionary,
	maxed: bool,
) -> String:
	if facility_id == &"rooster_operations_office":
		var current_limit := maxi(1, int(facility.get("current_personnel_action_limit", 1)))
		var next_limit := maxi(current_limit, int(facility.get(
			"next_personnel_action_limit",
			current_limit,
		)))
		var current_payroll := maxi(0, int(facility.get("current_supervisor_payroll_cents", 0)))
		var next_payroll := maxi(current_payroll, int(facility.get(
			"next_supervisor_payroll_cents",
			current_payroll,
		)))
		var current_grievance := maxi(0, int(facility.get(
			"current_surveillance_grievance_millipoints",
			0,
		)))
		var next_grievance := maxi(current_grievance, int(facility.get(
			"next_surveillance_grievance_millipoints",
			current_grievance,
		)))
		var current_stress := maxi(0, int(facility.get(
			"current_surveillance_stress_millipoints",
			0,
		)))
		var next_stress := maxi(current_stress, int(facility.get(
			"next_surveillance_stress_millipoints",
			current_stress,
		)))
		var current_solidarity := maxi(0, int(facility.get(
			"current_surveillance_solidarity_millipoints",
			0,
		)))
		var next_solidarity := maxi(current_solidarity, int(facility.get(
			"next_surveillance_solidarity_millipoints",
			current_solidarity,
		)))
		if maxed:
			return (
				"ACTIVE SUPERVISION  /  %d CHECK-INS  /  $%.2f SUPERVISOR/DAY\n"
				+ "SURVEILLANCE / HEN  +%s GRIEVANCE  /  +%s STRESS  /  FLOCK UNITY +%s"
			) % [
				current_limit,
				float(current_payroll) / 100.0,
				_millipoints_copy(current_grievance),
				_millipoints_copy(current_stress),
				_millipoints_copy(current_solidarity),
			]
		return (
			"NEXT SUPERVISION  /  CHECK-INS %d -> %d  /  SUPERVISOR $%.2f -> $%.2f/DAY\n"
			+ "SURVEILLANCE / HEN  GRIEVANCE +%s -> +%s  /  STRESS +%s -> +%s\n"
			+ "FLOCK UNITY +%s -> +%s / SHIFT"
		) % [
			current_limit,
			next_limit,
			float(current_payroll) / 100.0,
			float(next_payroll) / 100.0,
			_millipoints_copy(current_grievance),
			_millipoints_copy(next_grievance),
			_millipoints_copy(current_stress),
			_millipoints_copy(next_stress),
			_millipoints_copy(current_solidarity),
			_millipoints_copy(next_solidarity),
		]

	var current_work := maxi(10_000, int(facility.get("current_automation_work_basis_points", 10_000)))
	var next_work := maxi(current_work, int(facility.get(
		"next_automation_work_basis_points",
		current_work,
	)))
	var current_grace := maxi(0, int(facility.get(
		"current_automation_specialty_grace_minutes",
		180,
	)))
	var next_grace := maxi(0, int(facility.get(
		"next_automation_specialty_grace_minutes",
		current_grace,
	)))
	var current_exposure := maxi(0, int(facility.get(
		"current_automation_compliance_exposure_millipoints",
		0,
	)))
	var next_exposure := maxi(current_exposure, int(facility.get(
		"next_automation_compliance_exposure_millipoints",
		current_exposure,
	)))
	var current_patch := maxi(0, int(facility.get("current_ledger_molt_patch_cost_cents", 1800)))
	var next_patch := maxi(0, int(facility.get(
		"next_ledger_molt_patch_cost_cents",
		current_patch,
	)))
	var current_level := maxi(0, int(facility.get("level", 0)))
	var next_level := maxi(current_level, int(facility.get("next_level", current_level)))
	var current_work_percent := float(current_work - 10_000) / 100.0
	var next_work_percent := float(next_work - 10_000) / 100.0
	if maxed:
		return (
			"ACTIVE AUTO SUPPORT  /  +%s%% PACE  /  %dM SPECIALTY GRACE  /  SECONDARY RECOGNIZED\n"
			+ "COMPLIANCE EXPOSURE -%s/SHIFT  /  LEDGER PATCH $%.2f"
		) % [
			_compact_number(current_work_percent),
			current_grace,
			_millipoints_copy(current_exposure),
			float(current_patch) / 100.0,
		]
	return (
		"NEXT AUTO SUPPORT  /  PACE +%s%% -> +%s%%  /  GRACE %dM -> %dM\n"
		+ "SECONDARY %s -> %s  /  EXPOSURE -%s -> -%s/SHIFT\n"
		+ "LEDGER PATCH $%.2f -> $%.2f"
	) % [
		_compact_number(current_work_percent),
		_compact_number(next_work_percent),
		current_grace,
		next_grace,
		"RECOGNIZED" if current_level > 0 else "PRIMARY ONLY",
		"RECOGNIZED" if next_level > 0 else "PRIMARY ONLY",
		_millipoints_copy(current_exposure),
		_millipoints_copy(next_exposure),
		float(current_patch) / 100.0,
		float(next_patch) / 100.0,
	]


func _flock_relations_gate_copy(facility: Dictionary) -> String:
	var rooster := maxi(0, int(facility.get("rooster_operations_office_level", 0)))
	var required_rooster := maxi(0, int(facility.get(
		"required_rooster_operations_office_level",
		maxi(1, int(facility.get("next_level", 1))),
	)))
	var wellness := maxi(0, int(facility.get("wellness_nest_level", 0)))
	var required_wellness := maxi(0, int(facility.get(
		"required_wellness_nest_level",
		maxi(1, int(facility.get("next_level", 1))),
	)))
	return (
		"CASE AUTHORITY GATE | ROOSTER OFFICE %d / %d | %s\n"
		+ "REMEDY GATE | WELLNESS NEST %d / %d | %s"
	) % [
		rooster,
		required_rooster,
		"CLEARED" if rooster >= required_rooster else "%d TIER%s SHORT" % [
			required_rooster - rooster,
			"" if required_rooster - rooster == 1 else "S",
		],
		wellness,
		required_wellness,
		"CLEARED" if wellness >= required_wellness else "%d TIER%s SHORT" % [
			required_wellness - wellness,
			"" if required_wellness - wellness == 1 else "S",
		],
	]


func _flock_relations_gate_color(facility: Dictionary) -> Color:
	return (
		COLOR_TEAL
		if (
			int(facility.get("rooster_operations_office_level", 0))
			>= int(facility.get("required_rooster_operations_office_level", 1))
			and int(facility.get("wellness_nest_level", 0))
			>= int(facility.get("required_wellness_nest_level", 1))
		) else
		COLOR_RUST
	)


func _flock_relations_delta_copy(facility: Dictionary, maxed: bool) -> String:
	var current_capacity := maxi(0, int(facility.get(
		"current_flock_relations_case_capacity",
		int(facility.get("level", 0)),
	)))
	var next_capacity := maxi(current_capacity, int(facility.get(
		"next_flock_relations_case_capacity",
		current_capacity,
	)))
	var current_limit := maxi(0, int(facility.get(
		"current_flock_relations_resolution_limit",
		int(facility.get("level", 0)),
	)))
	var next_limit := maxi(current_limit, int(facility.get(
		"next_flock_relations_resolution_limit",
		current_limit,
	)))
	return (
		"ACTIVE CASE OFFICE | %d OPEN FILE SLOTS | %d REVIEW AUTHORIZATIONS"
		if maxed else
		"NEXT CASE OFFICE | OPEN FILE SLOTS %d -> %d\nREVIEW AUTHORIZATIONS %d -> %d"
	) % (
		[current_capacity, current_limit]
		if maxed else
		[current_capacity, next_capacity, current_limit, next_limit]
	)


func _feed_procurement_delta_copy(facility: Dictionary, maxed: bool) -> String:
	var current_capacity := maxi(0, int(facility.get("current_feed_capacity_scoops", 0)))
	var next_capacity := maxi(current_capacity, int(facility.get(
		"next_feed_capacity_scoops",
		current_capacity,
	)))
	var next_level := maxi(1, int(facility.get("next_level", 1)))
	var suppliers: Array[String] = [
		"LOCAL WHOLE GRAIN",
		"INSPIRATIONAL BULK MASH",
		"FIXED FUTURE RESERVE",
	]
	var supplier: String = suppliers[clampi(next_level - 1, 0, 2)]
	return (
		"ACTIVE GRAIN RESERVE  /  %d SCOOPS  /  ALL SUPPLIER FILES OPEN"
		if maxed else
		"NEXT GRAIN RESERVE  /  %d -> %d SCOOPS\nUNLOCKS  /  %s"
	) % (
		[current_capacity]
		if maxed else
		[current_capacity, next_capacity, supplier]
	)


func _care_facility_delta_copy(
	facility_id: StringName,
	facility: Dictionary,
	maxed: bool,
) -> String:
	if facility_id == &"wellness_nest_room":
		var current_strain := float(facility.get("current_strain_gain_basis_points", 10_000)) / 100.0
		var next_strain := float(facility.get("next_strain_gain_basis_points", current_strain * 100.0)) / 100.0
		var current_break := float(facility.get("current_break_recovery_basis_points", 10_000)) / 100.0
		var next_break := float(facility.get("next_break_recovery_basis_points", current_break * 100.0)) / 100.0
		var current_level := maxi(0, int(facility.get("level", 0)))
		var next_level := maxi(current_level, int(facility.get("next_level", current_level)))
		return (
			"ACTIVE CARE  /  STRAIN -%s%%  /  BREAK +%s%%  /  %d PERCHES"
			if maxed else
			"NEXT CARE EFFECT  /  STRAIN -%s%% -> -%s%%\nBREAK +%s%% -> +%s%%  /  PERCHES %d -> %d"
		) % (
			[
				_compact_number(maxf(0.0, 100.0 - current_strain)),
				_compact_number(maxf(0.0, current_break - 100.0)),
				current_level * 2,
			]
			if maxed else
			[
				_compact_number(maxf(0.0, 100.0 - current_strain)),
				_compact_number(maxf(0.0, 100.0 - next_strain)),
				_compact_number(maxf(0.0, current_break - 100.0)),
				_compact_number(maxf(0.0, next_break - 100.0)),
				current_level * 2,
				next_level * 2,
			]
		)

	var current_cost := maxi(0, int(facility.get("current_career_sponsorship_cost_cents", 1200)))
	var next_cost := maxi(0, int(facility.get("next_career_sponsorship_cost_cents", current_cost)))
	var current_work_basis := int(facility.get("current_training_work_basis_points", 8500))
	var next_work_basis := int(facility.get("next_training_work_basis_points", current_work_basis))
	var current_penalty := maxf(0.0, (10_000.0 - float(current_work_basis)) / 100.0)
	var next_penalty := maxf(0.0, (10_000.0 - float(next_work_basis)) / 100.0)
	var current_coaching := maxi(0, int(facility.get("current_career_coaching_xp_bonus", 0)))
	var next_coaching := maxi(current_coaching, int(facility.get("next_career_coaching_xp_bonus", current_coaching)))
	return (
		"ACTIVE TRAINING  /  $%.2f  /  -%s%%  /  +%d COACHING XP"
		if maxed else
		"NEXT TRAINING EFFECT  /  $%.2f -> $%.2f\nPENALTY -%s%% -> -%s%%  /  COACHING +%d -> +%d XP"
	) % (
		[
			float(current_cost) / 100.0,
			_compact_number(current_penalty),
			current_coaching,
		]
		if maxed else
		[
			float(current_cost) / 100.0,
			float(next_cost) / 100.0,
			_compact_number(current_penalty),
			_compact_number(next_penalty),
			current_coaching,
			next_coaching,
		]
	)


func _facility_copy_lines(source: Variant) -> Array[String]:
	var lines: Array[String] = []
	if source is Array:
		for value in source:
			var line := String(value).strip_edges()
			if not line.is_empty():
				lines.append(line)
	elif source is String:
		var line := String(source).strip_edges()
		if not line.is_empty():
			lines.append(line)
	return lines


func _facility_status(
	installed: bool,
	maxed: bool,
	unlocked: bool,
	planning_open: bool,
	affordable: bool,
	can_purchase: bool
) -> String:
	if maxed:
		return "INSTALLED" if installed else "MAX LEVEL"
	if not unlocked:
		return "LOCKED"
	if not planning_open:
		return "REVIEW FILE"
	if not affordable:
		return "FUND HELD"
	if can_purchase:
		return "UPGRADE READY" if installed else "AVAILABLE"
	return "ON HOLD"


func _facility_status_color(owned: bool, enabled: bool, unlocked: bool, affordable: bool) -> Color:
	if owned or enabled:
		return COLOR_TEAL
	if unlocked and not affordable:
		return COLOR_RUST
	return COLOR_MUTED


func _facility_reason(
	facility: Dictionary,
	installed: bool,
	maxed: bool,
	unlocked: bool,
	planning_open: bool,
	affordable: bool,
	can_purchase: bool,
	required_spendable: int,
	spendable: int,
	has_identity: bool,
	level: int,
	max_level: int
) -> String:
	var authoritative_reason := String(facility.get("action_reason", "")).strip_edges()
	if authoritative_reason.is_empty():
		authoritative_reason = String(facility.get("reason", facility.get("disabled_reason", ""))).strip_edges()
	if maxed:
		return "This expansion is operating at level %d/%d; all listed benefits are active and upkeep is protected." % [level, max_level]
	if not authoritative_reason.is_empty():
		return authoritative_reason
	if not has_identity:
		return "This facilities record is missing its requisition ID."
	if not unlocked:
		return "Complete the listed management requirement to unlock this facility."
	if not planning_open:
		return "Capital construction can be authorized during a farmer review."
	if not affordable:
		return "Spendable Feed Fund is short by $%.2f after protected obligations." % (maxi(0, required_spendable - spendable) / 100.0)
	if not can_purchase:
		return "This facility requisition is not currently authorized."
	return "Ready to authorize level %d construction." % (level + 1 if installed else 1)


func _facility_button_copy(
	facility: Dictionary,
	short_name: String,
	capital_cost: int,
	installed: bool,
	maxed: bool,
	unlocked: bool,
	planning_open: bool,
	affordable: bool,
	can_purchase: bool,
	next_level: int,
	level: int,
	max_level: int
) -> String:
	if maxed:
		return "%s\nINSTALLED · LEVEL %d/%d" % [short_name.to_upper(), level, max_level]
	if not unlocked:
		return "%s\nLOCKED" % short_name.to_upper()
	if not planning_open:
		return "REVIEW TO %s\n$%.2f" % ["UPGRADE" if installed else "BUILD", capital_cost / 100.0]
	if not affordable:
		return "FEED FUND HELD\n$%.2f" % (capital_cost / 100.0)
	if not can_purchase:
		return "REQUISITION ON HOLD"
	var authored_label := String(facility.get("purchase_label", "")).strip_edges()
	if not authored_label.is_empty():
		return "%s\n$%.2f" % [authored_label.to_upper(), capital_cost / 100.0]
	if installed:
		return "UPGRADE %s · LEVEL %d\n$%.2f" % [short_name.to_upper(), next_level, capital_cost / 100.0]
	return "BUILD %s · LEVEL 1\n$%.2f" % [short_name.to_upper(), capital_cost / 100.0]


func _safe_node_suffix(raw_id: String) -> String:
	var normalized := raw_id.strip_edges().to_lower()
	for character in [" ", "-", "/", "\\", ".", ":"]:
		normalized = normalized.replace(character, "_")
	return normalized if not normalized.is_empty() else "unfiled"


func _refresh_applicants(spendable: int, planning_open: bool) -> void:
	_clear_children(_applicant_list)
	var applicants := _applicant_entries()
	if applicants.is_empty():
		var empty := _make_label("No screened applicants remain in the hiring file.", 12, COLOR_MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_applicant_list.add_child(empty)
		return
	for applicant in applicants:
		_build_applicant_card(applicant, spendable, planning_open)


func _build_applicant_card(applicant: Dictionary, spendable: int, planning_open: bool) -> void:
	var worker_id := _worker_id(applicant)
	var display_name := String(applicant.get("name", applicant.get("display_name", "APPLICANT %d" % worker_id)))
	var specialty := String(applicant.get("specialty_name", applicant.get("specialty", "GENERAL PECKWORK"))).replace("_", " ").to_upper()
	var profile := String(applicant.get("career_profile_name", applicant.get("profile_name", "UNFILED PROFILE"))).to_upper()
	var wage := int(applicant.get("daily_wage_cents", 0))
	var hire_cost := int(applicant.get("hire_cost_cents", applicant.get("cost_cents", 0)))
	var can_hire := bool(applicant.get("can_hire", true))
	var affordable := spendable >= hire_cost
	var enabled := planning_open and can_hire and affordable and worker_id >= 0

	var card := PanelContainer.new()
	card.name = "StaffingApplicant_%d" % worker_id
	card.add_theme_stylebox_override("panel", _card_style())
	_applicant_list.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	margin.add_child(row)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.custom_minimum_size.x = 0.0
	identity.add_theme_constant_override("separation", 1)
	row.add_child(identity)
	var name_label := _make_label(display_name.to_upper(), 14, Color("eef1df"))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.clip_text = true
	identity.add_child(name_label)
	var fit_label := _make_label("%s  ·  %s" % [profile, specialty], 10, COLOR_MUTED)
	fit_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fit_label.clip_text = true
	fit_label.tooltip_text = "%s specializes in %s files." % [display_name, specialty]
	identity.add_child(fit_label)
	identity.add_child(_make_label("WAGE $%.2f/day" % (wage / 100.0), 11, Color("d7c17d")))

	var hire_button := Button.new()
	hire_button.name = "HireWorker_%d" % worker_id
	hire_button.theme_type_variation = &"PrimaryButton"
	hire_button.custom_minimum_size = Vector2(94.0, 42.0)
	hire_button.text = "HIRE\n$%.2f" % (hire_cost / 100.0)
	hire_button.disabled = not enabled
	var reason := String(applicant.get("reason", applicant.get("disabled_reason", "")))
	if reason.is_empty() and not planning_open:
		reason = "The staffing file is locked."
	elif reason.is_empty() and not affordable:
		reason = "Spendable Feed Fund is short by $%.2f." % ((hire_cost - spendable) / 100.0)
	elif reason.is_empty() and not can_hire:
		reason = "No authorized perch is available for this applicant."
	hire_button.tooltip_text = (
		"Hire %s for $%.2f; adds $%.2f to daily payroll." % [display_name, hire_cost / 100.0, wage / 100.0]
		if enabled else
		"HIRE HELD: %s" % reason
	)
	hire_button.pressed.connect(func() -> void: hire_requested.emit(worker_id))
	row.add_child(hire_button)


func _refresh_release_controls(spendable: int, planning_open: bool) -> void:
	var employed := _employed_workers()
	var previous_selection := _selected_release_worker_id
	_release_selector.clear()
	for worker in employed:
		var worker_id := _worker_id(worker)
		var display_name := String(worker.get("name", worker.get("display_name", "HEN %d" % (worker_id + 1))))
		var wage := int(worker.get("daily_wage_cents", 0))
		_release_selector.add_item("%s  ·  $%.2f/d" % [display_name.to_upper(), wage / 100.0])
		var item_index := _release_selector.item_count - 1
		_release_selector.set_item_metadata(item_index, worker_id)
		if worker_id == previous_selection:
			_release_selector.select(item_index)
	if _release_selector.item_count == 0:
		_selected_release_worker_id = -1
		_release_selector.add_item("NO ACTIVE HENS")
		_release_selector.disabled = true
		_release_button.text = "RELEASE"
		_release_button.disabled = true
		_release_button.tooltip_text = "No active employment record can be released."
		return
	_release_selector.disabled = not planning_open
	if _release_selector.selected < 0:
		_release_selector.select(0)
	_selected_release_worker_id = int(_release_selector.get_item_metadata(_release_selector.selected))
	var selected := _staffing_record(_selected_release_worker_id)
	var release_cost := int(selected.get("release_cost_cents", 0))
	var can_release := bool(selected.get("can_release", true))
	var affordable := spendable >= release_cost
	var enabled := planning_open and can_release and affordable
	_release_button.text = "RELEASE\n$%.2f" % (release_cost / 100.0)
	_release_button.disabled = not enabled
	var reason := String(selected.get("release_reason", selected.get("disabled_reason", "")))
	if reason.is_empty() and not planning_open:
		reason = "The staffing file is locked."
	elif reason.is_empty() and not affordable:
		reason = "Spendable Feed Fund is short by $%.2f." % ((release_cost - spendable) / 100.0)
	elif reason.is_empty() and not can_release:
		reason = "At least one active hen must remain on the claim floor."
	_release_button.tooltip_text = (
		"Release this hen for an exact separation cost of $%.2f." % (release_cost / 100.0)
		if enabled else
		"RELEASE HELD: %s" % reason
	)


func _refresh_last_action() -> void:
	var last_action := _snapshot.get("last_staffing_action", {}) as Dictionary
	var outcome := String(last_action.get("outcome", last_action.get("reason", "")))
	_last_action_label.visible = not outcome.is_empty()
	_last_action_label.text = "LAST FILE  ·  %s" % outcome if not outcome.is_empty() else ""
	_last_action_label.tooltip_text = outcome


func _on_release_selection_changed(index: int) -> void:
	if index < 0 or index >= _release_selector.item_count:
		return
	var metadata: Variant = _release_selector.get_item_metadata(index)
	if metadata == null:
		return
	_selected_release_worker_id = int(metadata)
	_refresh_release_controls(
		int(_snapshot.get("spendable_fund_cents", _snapshot.get("revenue_cents", 0))),
		bool(_snapshot.get("staffing_planning_open", false)),
	)


func _on_release_pressed() -> void:
	if _selected_release_worker_id >= 0:
		release_requested.emit(_selected_release_worker_id)


func _applicant_entries() -> Array[Dictionary]:
	var workers_by_id: Dictionary[int, Dictionary] = {}
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		workers_by_id[_worker_id(worker)] = worker
	var result: Array[Dictionary] = []
	for entry_value in _snapshot.get("staffing_catalog", []):
		var entry := (entry_value as Dictionary).duplicate(true)
		var worker_id := _worker_id(entry)
		if workers_by_id.has(worker_id):
			entry.merge(workers_by_id[worker_id], true)
		if not _is_employed(entry):
			result.append(entry)
	if result.is_empty():
		for worker in workers_by_id.values():
			if not _is_employed(worker):
				result.append(worker.duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _worker_id(a) < _worker_id(b))
	return result


func _employed_workers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if _is_employed(worker):
			result.append(worker)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("desk_index", 999)) < int(b.get("desk_index", 999))
	)
	return result


func _worker_snapshot(worker_id: int) -> Dictionary:
	for worker_value in _snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if _worker_id(worker) == worker_id:
			return worker
	return {}


func _staffing_record(worker_id: int) -> Dictionary:
	var result := _worker_snapshot(worker_id).duplicate(true)
	for entry_value in _snapshot.get("staffing_catalog", []):
		var entry := entry_value as Dictionary
		if _worker_id(entry) == worker_id:
			result.merge(entry, true)
			break
	return result


func _is_employed(worker: Dictionary) -> bool:
	if worker.has("employed"):
		return bool(worker.get("employed", false))
	var status := StringName(String(worker.get("employment_status", "employed")))
	return int(worker.get("desk_index", -1)) >= 0 and status not in [&"applicant", &"released", &"inactive"]


func _worker_id(worker: Dictionary) -> int:
	return int(worker.get("id", worker.get("worker_id", -1)))


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _make_label(copy: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172832")
	style.border_color = Color("50616d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	return style


func _facility_card_style(owned: bool, enabled: bool, unlocked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("152b2c") if owned else Color("182a35")
	style.border_color = (
		Color("6ba99a")
		if owned or enabled else
		Color("59646b")
		if unlocked else
		Color("3d4951")
	)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


func _facility_status_style(owned: bool, enabled: bool, unlocked: bool, affordable: bool) -> StyleBoxFlat:
	var accent := _facility_status_color(owned, enabled, unlocked, affordable)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, 0.12)
	style.border_color = Color(accent, 0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style
