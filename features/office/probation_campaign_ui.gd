class_name ProbationCampaignUI
extends Control

## Standalone presentation layer for the five-shift management probation.
##
## The component owns no campaign rules or persistence. Call [apply_snapshot]
## with a plain Dictionary and connect the intent signals below. Supported views
## are `title`, `active`, `between_shift`, `contract_board`, and `final`.

signal continue_campaign
signal new_campaign
signal abandon_campaign
signal challenge_contract_changed(contract_id: StringName)
signal title_intake_phase_changed(phase: StringName)
signal milestone_choice(choice_id: StringName)
signal presentation_state_changed
signal career_sponsorship_requested(worker_id: int, lane_id: StringName)
signal market_contract_sign_requested(offer_id: StringName, clause_id: StringName)
signal market_contract_decline_requested

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")
const CareerSponsorshipUIScript := preload("res://features/office/career_sponsorship_ui.gd")
const FarmMutualContractBoardUIScript := preload("res://features/office/farm_mutual_contract_board_ui.gd")

const VIEW_TITLE := &"title"
const VIEW_ACTIVE := &"active"
const VIEW_REPORT := &"between_shift"
const VIEW_CONTRACT_BOARD := &"contract_board"
const VIEW_FINAL := &"final"
const TITLE_PHASE_RESUME := &"resume"
const TITLE_PHASE_NEW_FILE := &"new_file"
const DEFAULT_TOTAL_DAYS := 5
const PROBATION_SCORE_LIMIT := 100
const PROBATION_PASS_THRESHOLD := 60
const MAX_BADGE_ORDER_SEGMENTS := 3
const DEFAULT_CHALLENGE_CONTRACT_ID: StringName = &"standard_filing"
const DEFAULT_CHALLENGE_CONTRACT := {
	"id": "standard_filing",
	"label": "STANDARD FILING",
	"short_label": "STANDARD",
	"difficulty": "standard",
	"difficulty_label": "STANDARD",
	"difficulty_guidance": "The recommended authored balance for a first complete probation file.",
	"description": "The authored probation contract with the shipped balance of flock care, compliance, favor, and shell quality.",
	"criteria": {
		"minimum_score": PROBATION_PASS_THRESHOLD,
		"minimum_welfare": 45,
		"minimum_compliance": 55,
		"minimum_farmer_favor": 50,
		"maximum_crack_rate_basis_points": 2500,
	},
}

const INK := Color("e9edf0")
const MUTED := Color("9eabb5")
const NAVY := Color("172630")
const NAVY_RAISED := Color("223541")
const BRASS := Color("d1a650")
const CREAM := Color("f4df9d")
const TEAL := Color("73b5a7")
const RUST := Color("c96f59")

var _snapshot: Dictionary = {
	"view": VIEW_ACTIVE,
	"day": 1,
	"total_days": DEFAULT_TOTAL_DAYS,
}
var _view: StringName = VIEW_ACTIVE
var _selected_milestone := &""
var _pending_milestone_confirmation := &""
var _selected_challenge_contract_id: StringName = DEFAULT_CHALLENGE_CONTRACT_ID
var _challenge_selector_syncing := false
var _title_new_file_setup := false
var _title_contract_terms_expanded := false

var _day_badge: PanelContainer
var _active_badge_top := 120.0
var _badge_suppressed := false
var _status_label: Label
var _day_label: Label
var _order_progress_row: HBoxContainer
var _order_progress_label: Label
var _order_progress_segments: Array[PanelContainer] = []
var _live_orders_on_track := -1
var _live_orders_total := 0
var _live_order_context: StringName = &""
var _order_progress_seeded := false
var _order_progress_tween: Tween
var _reduced_motion := false
var _modal_host: Control
var _modal_scroll: ScrollContainer
var _modal_center: CenterContainer
var _title_panel: PanelContainer
var _report_panel: PanelContainer
var _final_panel: PanelContainer
var _title_heading: Label
var _title_description: Label
var _title_profile_card: PanelContainer
var _title_probation_summary: PanelContainer
var _title_actions: HFlowContainer
var _title_resume_card: PanelContainer
var _title_resume_heading: Label
var _title_resume_details: Label
var _title_challenge_card: PanelContainer
var _title_challenge_selector: OptionButton
var _title_challenge_summary: Label
var _title_challenge_terms_toggle: Button
var _title_challenge_detail: Label
var _title_new_button: Button
var _title_back_button: Button
var _report_score_row: HFlowContainer
var _report_heading_stack: VBoxContainer
var _report_story_row: HFlowContainer
var _report_ledger_row: HFlowContainer
var _report_actions: HFlowContainer
var _final_metrics: HFlowContainer
var _final_ledger_row: HFlowContainer
var _final_actions: HFlowContainer
var _final_sticky_action_bar: PanelContainer
var _final_sticky_primary_button: Button
var _final_sticky_leave_button: Button

var _continue_title_button: Button
var _report_continue_button: Button
var _report_day_label: Label
var _report_heading_label: Label
var _report_heading_note: Label
var _report_ledger_section_label: Label
var _report_score_label: Label
var _report_shift_delta_label: Label
var _report_rank_label: Label
var _report_ledger_labels: Array[Dictionary] = []
var _report_safeguard_panel: PanelContainer
var _report_safeguard_summary: Label
var _report_safeguard_grid: GridContainer
var _report_safeguard_rows: Array[Label] = []
var _credit_memo_card: PanelContainer
var _credit_memo_label: Label
var _hen_highlight_card: PanelContainer
var _hen_highlight_eyebrow: Label
var _hen_highlight_headline: Label
var _hen_highlight_body: Label
var _hen_highlight_metric: Label
var _objective_title_label: Label
var _objective_body_label: Label
var _objective_progress_label: Label
var _milestone_section: VBoxContainer
var _milestone_section_label: Label
var _milestone_buttons_host: HFlowContainer
var _milestone_hint_label: Label
var _milestone_buttons: Dictionary[StringName, Button] = {}
var _career_sponsorship_ui: CareerSponsorshipUI
var _contract_board_ui: FarmMutualContractBoardUI

var _final_verdict_label: Label
var _final_score_label: Label
var _final_rank_label: Label
var _final_message_label: Label
var _final_ledger_labels: Array[Dictionary] = []
var _final_safeguard_panel: PanelContainer
var _final_safeguard_summary: Label
var _final_safeguard_grid: GridContainer
var _final_safeguard_rows: Array[Label] = []
var _final_continue_button: Button
var _final_new_button: Button

var _replacement_confirmation_host: Control
var _replacement_confirmation_panel: PanelContainer
var _replacement_confirmation_title: Label
var _replacement_confirmation_body: Label
var _replacement_confirmation_confirm: Button
var _replacement_confirmation_cancel: Button
var _replacement_confirmation_origin: Control


func _ready() -> void:
	name = "ProbationCampaignUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = ManagementTheme.create_theme()
	_build_day_badge()
	_build_modal_host()
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_refresh()


## Replaces all presentation data. This method never mutates the caller's data.
func apply_snapshot(snapshot: Dictionary) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_snapshot = snapshot.duplicate(true)
	_view = _read_view(_snapshot)
	if _view == VIEW_TITLE:
		_title_new_file_setup = not _snapshot_continue_available()
		_title_contract_terms_expanded = false
	if _snapshot.has("selected_new_challenge_contract_id"):
		_selected_challenge_contract_id = StringName(String(
			_snapshot.get("selected_new_challenge_contract_id", DEFAULT_CHALLENGE_CONTRACT_ID)
		))
	elif _view != VIEW_TITLE:
		var active_contract := _challenge_contract_from_value(_snapshot.get("challenge_contract", {}))
		if not active_contract.is_empty():
			_selected_challenge_contract_id = StringName(String(active_contract.get(
				"id",
				DEFAULT_CHALLENGE_CONTRACT_ID,
			)))
	_selected_milestone = StringName(_snapshot.get(
		"selected_milestone",
		_snapshot.get("milestone_selected", &""),
	))
	_refresh()


## Shows the first-load campaign card. Continue remains visibly disabled when
## no resumable campaign exists.
func show_title(continue_available: bool = false) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_snapshot["view"] = VIEW_TITLE
	_snapshot["continue_available"] = continue_available
	_view = VIEW_TITLE
	_selected_milestone = &""
	_title_new_file_setup = not continue_available
	_title_contract_terms_expanded = false
	_refresh()


## Returns to the office while retaining the compact probation badge.
func show_active_campaign(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_ACTIVE
	_view = VIEW_ACTIVE
	_refresh()


## Opens the intentional between-shift report modal.
func show_between_shift_report(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_REPORT
	_view = VIEW_REPORT
	_selected_milestone = StringName(_snapshot.get(
		"selected_milestone",
		_snapshot.get("milestone_selected", &""),
	))
	_refresh()


## Opens the sequential Farm Mutual planning file after the closing report and
## before the morning directive. The child consumes the canonical board snapshot.
func show_contract_board(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_CONTRACT_BOARD
	_view = VIEW_CONTRACT_BOARD
	if _contract_board_ui != null:
		_contract_board_ui.apply_snapshot(_snapshot)
	_refresh()


## Opens the final pass/fail campaign review.
func show_final_review(snapshot: Dictionary = {}) -> void:
	_hide_campaign_replacement(false)
	_pending_milestone_confirmation = &""
	_merge_snapshot(snapshot)
	_snapshot["view"] = VIEW_FINAL
	_view = VIEW_FINAL
	_refresh()


func hide_modal() -> void:
	show_active_campaign()


func is_modal_open() -> bool:
	return _view != VIEW_ACTIVE


func modal_state() -> StringName:
	return _view


func selected_milestone_id() -> StringName:
	return _selected_milestone


## Presentation-only new-file choice. The authoritative campaign owner reads
## this stable ID when the unchanged zero-argument new_campaign signal fires.
func selected_challenge_contract_id() -> StringName:
	return _selected_challenge_contract_id


func title_intake_phase() -> StringName:
	if _view != VIEW_TITLE:
		return &""
	return TITLE_PHASE_NEW_FILE if _title_new_file_setup else TITLE_PHASE_RESUME


func campaign_snapshot() -> Dictionary:
	var result := _snapshot.duplicate(true)
	var confirmation := _pending_milestone_confirmation_snapshot()
	if not confirmation.is_empty():
		result["pending_milestone_confirmation"] = confirmation
	return result


## Updates only the presentation badge from an authoritative live projection.
## A new day/quarter seeds quietly; later aggregate changes return their signed
## delta so Office can play one semantic cue without duplicating campaign rules.
func set_live_order_progress(on_track: int, total: int, context: StringName) -> int:
	var sanitized_total := clampi(total, 0, MAX_BADGE_ORDER_SEGMENTS)
	var sanitized_on_track := clampi(on_track, 0, sanitized_total)
	if sanitized_total <= 0:
		_live_orders_on_track = -1
		_live_orders_total = 0
		_live_order_context = context
		_order_progress_seeded = false
		_snapshot["live_orders_on_track"] = 0
		_snapshot["live_orders_total"] = 0
		_snapshot["live_order_context"] = String(context)
		_refresh_live_order_badge()
		return 0
	var same_context := _order_progress_seeded and context == _live_order_context
	var delta := sanitized_on_track - _live_orders_on_track if same_context else 0
	var changed := (
		not same_context
		or sanitized_on_track != _live_orders_on_track
		or sanitized_total != _live_orders_total
	)
	_live_orders_on_track = sanitized_on_track
	_live_orders_total = sanitized_total
	_live_order_context = context
	_order_progress_seeded = true
	_snapshot["live_orders_on_track"] = sanitized_on_track
	_snapshot["live_orders_total"] = sanitized_total
	_snapshot["live_order_context"] = String(context)
	if changed:
		_refresh_live_order_badge()
		if delta != 0 and _view == VIEW_ACTIVE:
			_pulse_live_order_badge(delta > 0)
	return delta


func live_order_progress() -> Dictionary:
	return {
		"on_track": maxi(0, _live_orders_on_track),
		"total": _live_orders_total,
		"context": String(_live_order_context),
		"visible": _order_progress_row != null and _order_progress_row.visible,
	}


func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _reduced_motion and _order_progress_tween != null and _order_progress_tween.is_valid():
		_order_progress_tween.kill()
	if _day_badge != null:
		_day_badge.modulate = Color.WHITE


func contract_board_ui() -> FarmMutualContractBoardUI:
	return _contract_board_ui


## Keeps the compact active-file badge aligned with Office's adaptive HUD and
## lets focused drawers/modals suppress it without changing campaign state.
func set_badge_presentation(active_top: float, suppressed: bool) -> void:
	var sanitized_top := maxf(0.0, active_top)
	if is_equal_approx(_active_badge_top, sanitized_top) and _badge_suppressed == suppressed:
		return
	_active_badge_top = sanitized_top
	_badge_suppressed = suppressed
	if _day_badge != null:
		_day_badge.visible = not suppressed
		_position_badge(_view != VIEW_ACTIVE)


func active_badge_top() -> float:
	return _active_badge_top


func is_badge_suppressed() -> bool:
	return _badge_suppressed


func _merge_snapshot(snapshot: Dictionary) -> void:
	for key: Variant in snapshot:
		_snapshot[key] = snapshot[key]


func _build_day_badge() -> void:
	_day_badge = PanelContainer.new()
	_day_badge.name = "ProbationDayBadge"
	_day_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_day_badge.offset_left = -490.0
	_day_badge.offset_top = 120.0
	_day_badge.offset_right = -268.0
	_day_badge.offset_bottom = 164.0
	_day_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_day_badge.z_index = 20
	_day_badge.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("16242d"), Color("9e824d"), 8, 1),
	)
	add_child(_day_badge)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	_day_badge.add_child(margin)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 1)
	margin.add_child(stack)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)
	_status_label = _make_label("PROBATION", 11, BRASS)
	_status_label.name = "ProbationStatusLabel"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_status_label)
	_day_label = _make_label("DAY 1 / 5", 15, CREAM)
	_day_label.name = "ProbationDayLabel"
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_day_label)
	_order_progress_row = HBoxContainer.new()
	_order_progress_row.name = "ProbationOrderProgressRow"
	_order_progress_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_order_progress_row.add_theme_constant_override("separation", 4)
	stack.add_child(_order_progress_row)
	_order_progress_label = _make_label("ORDERS 0 / 3", 9, MUTED)
	_order_progress_label.name = "ProbationOrderProgressLabel"
	_order_progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_order_progress_row.add_child(_order_progress_label)
	for index in range(MAX_BADGE_ORDER_SEGMENTS):
		var segment := PanelContainer.new()
		segment.name = "ProbationOrderStamp%d" % (index + 1)
		segment.custom_minimum_size = Vector2(24.0, 5.0)
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_order_progress_row.add_child(segment)
		_order_progress_segments.append(segment)
	_refresh_live_order_badge()


func _refresh_live_order_badge() -> void:
	if _order_progress_row == null or _order_progress_label == null:
		return
	var visible_progress := _view == VIEW_ACTIVE and _live_orders_total > 0
	_order_progress_row.visible = visible_progress
	if not visible_progress:
		return
	var on_track := clampi(_live_orders_on_track, 0, _live_orders_total)
	_order_progress_label.text = "ORDERS  %d / %d" % [on_track, _live_orders_total]
	_order_progress_label.add_theme_color_override(
		"font_color",
		TEAL if on_track == _live_orders_total else (RUST if on_track == 0 else CREAM),
	)
	_order_progress_label.tooltip_text = (
		"%d of %d live orders are currently on track. Closing metrics can still move; open Flockwatch for exact targets and rewards."
		% [on_track, _live_orders_total]
	)
	for index in range(_order_progress_segments.size()):
		var segment := _order_progress_segments[index]
		var active := index < on_track
		var relevant := index < _live_orders_total
		segment.visible = relevant
		if not relevant:
			continue
		segment.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("5aa897") if active else Color("263640"),
				Color("b8e2d7") if active else Color("8a5f59"),
				2,
				1,
			),
		)


func _pulse_live_order_badge(improved: bool) -> void:
	if _day_badge == null:
		return
	if _order_progress_tween != null and _order_progress_tween.is_valid():
		_order_progress_tween.kill()
	_day_badge.modulate = Color.WHITE
	if _reduced_motion:
		return
	_day_badge.modulate = Color("c8f0df") if improved else Color("f5c2b5")
	_order_progress_tween = create_tween()
	_order_progress_tween.set_trans(Tween.TRANS_QUAD)
	_order_progress_tween.set_ease(Tween.EASE_OUT)
	_order_progress_tween.tween_property(_day_badge, "modulate", Color.WHITE, 0.48)


func _build_modal_host() -> void:
	_modal_host = Control.new()
	_modal_host.name = "ProbationModalHost"
	_modal_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_host.z_index = 10
	add_child(_modal_host)

	var scrim := ColorRect.new()
	scrim.name = "ProbationModalScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.012, 0.024, 0.033, 0.88)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_host.add_child(scrim)

	_modal_scroll = ScrollContainer.new()
	_modal_scroll.name = "ProbationModalScroll"
	_modal_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_scroll.offset_left = 18.0
	_modal_scroll.offset_top = 66.0
	_modal_scroll.offset_right = -18.0
	_modal_scroll.offset_bottom = -18.0
	_modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_modal_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_modal_host.add_child(_modal_scroll)

	_modal_center = CenterContainer.new()
	_modal_center.name = "ProbationModalCenter"
	_modal_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_center.mouse_filter = Control.MOUSE_FILTER_PASS
	_modal_scroll.add_child(_modal_center)

	_build_title_panel(_modal_center)
	_build_report_panel(_modal_center)
	_build_final_panel(_modal_center)
	_build_final_sticky_action_bar()
	_contract_board_ui = FarmMutualContractBoardUIScript.new() as FarmMutualContractBoardUI
	_contract_board_ui.name = "FarmMutualContractBoardUI"
	_contract_board_ui.visible = false
	_contract_board_ui.contract_sign_requested.connect(_on_market_contract_sign_requested)
	_contract_board_ui.decline_requested.connect(_on_market_contract_decline_requested)
	_contract_board_ui.continue_requested.connect(_on_continue_campaign_pressed)
	_modal_host.add_child(_contract_board_ui)
	_build_replacement_confirmation()


func _build_title_panel(parent: Control) -> void:
	_title_panel = PanelContainer.new()
	_title_panel.name = "CampaignTitlePanel"
	_title_panel.custom_minimum_size = Vector2(760.0, 0.0)
	_title_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(NAVY, Color("ad8a4a"), 15, 2),
	)
	parent.add_child(_title_panel)

	var content := _panel_content(_title_panel, 28, 20, 10)
	var eyebrow := _make_label("CORNFIELDS MUTUAL  //  MANAGEMENT INTAKE", 12, BRASS)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(eyebrow)
	_title_heading = _make_label("FIVE SHIFTS. START BY MEETING MABEL.", 28, CREAM)
	_title_heading.name = "CampaignTitle"
	_title_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_title_heading)
	_title_description = _make_label(
		"Mabel is already at her desk. Every choice you make together shares one permanent coop file.",
		15,
		Color("c4d0d4"),
	)
	_title_description.name = "CampaignTitleDescription"
	_title_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_title_description)

	_title_profile_card = PanelContainer.new()
	_title_profile_card.name = "MabelProfileCard"
	_title_profile_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), Color("48616a"), 9, 1),
	)
	content.add_child(_title_profile_card)
	var profile := _panel_content(_title_profile_card, 18, 11, 4)
	var identity := _make_label("MABEL  //  JUNIOR CLAIMS HEN", 15, CREAM)
	identity.name = "CampaignMabelIdentity"
	identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	identity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile.add_child(identity)
	var traits := _make_label("APPEALS SPECIALIST  //  CREDIT CONSCIOUS", 12, TEAL)
	traits.name = "CampaignMabelTraits"
	traits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile.add_child(traits)
	var quote := _make_label("\"The farmer remembers the basket, not the beak that filled it.\"", 14, INK)
	quote.name = "CampaignMabelQuote"
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile.add_child(quote)

	_title_challenge_card = PanelContainer.new()
	_title_challenge_card.name = "ChallengeContractCard"
	_title_challenge_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1b2d36"), Color("6d8e86"), 9, 1),
	)
	content.add_child(_title_challenge_card)
	var challenge_content := _panel_content(_title_challenge_card, 16, 10, 5)
	var challenge_header := HFlowContainer.new()
	challenge_header.name = "ChallengeContractHeader"
	challenge_header.add_theme_constant_override("h_separation", 12)
	challenge_header.add_theme_constant_override("v_separation", 6)
	challenge_content.add_child(challenge_header)
	var challenge_label := _make_label("DIFFICULTY  //  PERMANENT FIVE-SHIFT TERMS", 11, TEAL)
	challenge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	challenge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	challenge_label.custom_minimum_size.x = 210.0
	challenge_header.add_child(challenge_label)
	_title_challenge_selector = OptionButton.new()
	_title_challenge_selector.name = "ChallengeContractSelector"
	_title_challenge_selector.fit_to_longest_item = false
	_title_challenge_selector.custom_minimum_size = Vector2(250.0, 40.0)
	_title_challenge_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_challenge_selector.focus_mode = Control.FOCUS_ALL
	_title_challenge_selector.theme_type_variation = &"DecisionChoiceButton"
	_title_challenge_selector.item_selected.connect(_on_challenge_contract_selected)
	challenge_header.add_child(_title_challenge_selector)
	_title_challenge_summary = _make_label("", 11, MUTED)
	_title_challenge_summary.name = "ChallengeContractSummary"
	_title_challenge_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_challenge_summary.max_lines_visible = 3
	_title_challenge_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_challenge_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_challenge_summary.mouse_filter = Control.MOUSE_FILTER_STOP
	challenge_content.add_child(_title_challenge_summary)
	_title_challenge_terms_toggle = _make_button(
		"ChallengeContractTermsToggle",
		"VIEW EXACT TERMS  [T]",
		&"DecisionChoiceButton",
	)
	_title_challenge_terms_toggle.custom_minimum_size = Vector2(220.0, 34.0)
	_title_challenge_terms_toggle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_challenge_terms_toggle.toggle_mode = true
	_title_challenge_terms_toggle.shortcut = _shortcut(KEY_T)
	_title_challenge_terms_toggle.pressed.connect(_on_challenge_contract_terms_toggled)
	challenge_content.add_child(_title_challenge_terms_toggle)
	_title_challenge_detail = _make_label("", 11, INK)
	_title_challenge_detail.name = "ChallengeContractDetail"
	_title_challenge_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_challenge_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_challenge_detail.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_challenge_detail.visible = false
	challenge_content.add_child(_title_challenge_detail)

	_title_probation_summary = PanelContainer.new()
	_title_probation_summary.name = "ProbationFiveShiftSummary"
	_title_probation_summary.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1a2932"), Color("665b42"), 7, 1),
	)
	content.add_child(_title_probation_summary)
	var probation_content := _panel_content(_title_probation_summary, 15, 8, 1)
	var probation_heading := _make_label("FIVE-SHIFT PROBATION", 11, BRASS)
	probation_heading.name = "ProbationFiveShiftHeading"
	probation_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	probation_content.add_child(probation_heading)
	var probation_detail := _make_label(
		"One permanent coop file  //  a closing report after each shift  //  final review after Shift 5",
		11,
		Color("d4c38f"),
	)
	probation_detail.name = "ProbationFiveShiftDetail"
	probation_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	probation_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	probation_content.add_child(probation_detail)

	_title_resume_card = PanelContainer.new()
	_title_resume_card.name = "CampaignResumeCard"
	_title_resume_card.visible = false
	_title_resume_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20343d"), Color("6d8e86"), 8, 1),
	)
	content.add_child(_title_resume_card)
	var resume_content := _panel_content(_title_resume_card, 16, 9, 3)
	_title_resume_heading = _make_label("SAVED COOP FILE CANDIDATE", 12, TEAL)
	_title_resume_heading.name = "CampaignResumeHeading"
	_title_resume_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_resume_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_content.add_child(_title_resume_heading)
	_title_resume_details = _make_label("", 11, INK)
	_title_resume_details.name = "CampaignResumeDetails"
	_title_resume_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_resume_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_content.add_child(_title_resume_details)

	_title_actions = HFlowContainer.new()
	_title_actions.name = "CampaignTitleActions"
	_title_actions.alignment = FlowContainer.ALIGNMENT_CENTER
	_title_actions.add_theme_constant_override("h_separation", 12)
	_title_actions.add_theme_constant_override("v_separation", 10)
	content.add_child(_title_actions)
	_continue_title_button = _make_button("ContinueCampaignButton", "CONTINUE SAVED FILE  [C]", &"PrimaryButton")
	_continue_title_button.custom_minimum_size = Vector2(260.0, 48.0)
	_continue_title_button.shortcut = _shortcut(KEY_C)
	_continue_title_button.pressed.connect(_on_continue_campaign_pressed)
	_title_actions.add_child(_continue_title_button)
	_title_new_button = _make_button("NewCampaignButton", "MEET MABEL & OPEN FILE  [N]", &"PrimaryButton")
	_title_new_button.custom_minimum_size = Vector2(270.0, 48.0)
	_title_new_button.shortcut = _shortcut(KEY_N)
	_title_new_button.pressed.connect(_on_new_campaign_pressed)
	_title_actions.add_child(_title_new_button)
	_title_back_button = _make_button(
		"BackToSavedCampaignButton",
		"BACK TO SAVED FILE  [B]",
		&"DecisionChoiceButton",
	)
	_title_back_button.custom_minimum_size = Vector2(230.0, 48.0)
	_title_back_button.shortcut = _shortcut(KEY_B)
	_title_back_button.pressed.connect(_on_title_back_pressed)
	_title_actions.add_child(_title_back_button)


func _build_report_panel(parent: Control) -> void:
	_report_panel = PanelContainer.new()
	_report_panel.name = "ProbationReportPanel"
	_report_panel.custom_minimum_size = Vector2(1040.0, 0.0)
	_report_panel.focus_mode = Control.FOCUS_ALL
	_report_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(NAVY, Color("ad8a4a"), 15, 2),
	)
	parent.add_child(_report_panel)

	# Reports routinely combine receipts, policy cards, and action controls. A
	# restrained vertical rhythm keeps the complete decision gate visible at the
	# reference 1440x900 Web viewport without removing any authored detail.
	var content := _panel_content(_report_panel, 26, 14, 6)
	_report_day_label = _make_label("CLOSING FILE 3 / 3 · SHIFT 1 OF 5 · PROBATION REPORT", 12, BRASS)
	_report_day_label.name = "ProbationReportDay"
	_report_day_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_report_day_label)

	_report_score_row = HFlowContainer.new()
	_report_score_row.name = "ProbationReportScoreRow"
	_report_score_row.add_theme_constant_override("h_separation", 18)
	_report_score_row.add_theme_constant_override("v_separation", 8)
	content.add_child(_report_score_row)
	_report_heading_stack = VBoxContainer.new()
	_report_heading_stack.custom_minimum_size.x = 390.0
	_report_heading_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_report_heading_stack.add_theme_constant_override("separation", 2)
	_report_score_row.add_child(_report_heading_stack)
	_report_heading_label = _make_label("FARMER'S SHIFT ASSESSMENT", 23, CREAM)
	_report_heading_label.name = "ProbationReportTitle"
	_report_heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_report_heading_stack.add_child(_report_heading_label)
	_report_heading_note = _make_label(
		"Cumulative results follow you through all five shifts.",
		13,
		MUTED,
	)
	_report_heading_note.name = "ReportScoreReceiptSummary"
	_report_heading_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_report_heading_note.mouse_filter = Control.MOUSE_FILTER_STOP
	_report_heading_stack.add_child(_report_heading_note)
	_report_score_label = _make_metric("ReportScore", "0", "SCORE", 132.0)
	_report_score_row.add_child(_metric_panel(_report_score_label))
	_report_shift_delta_label = _make_metric("ReportShiftDelta", "+0", "SHIFT SCORE", 126.0)
	_report_score_row.add_child(_metric_panel(_report_shift_delta_label))
	_report_rank_label = _make_metric("ReportRank", "UNRANKED", "RANK", 236.0, 16, true)
	_report_score_row.add_child(_metric_panel(_report_rank_label))

	content.add_child(HSeparator.new())
	_report_story_row = HFlowContainer.new()
	_report_story_row.name = "ReportShiftStories"
	_report_story_row.add_theme_constant_override("h_separation", 10)
	_report_story_row.add_theme_constant_override("v_separation", 8)
	content.add_child(_report_story_row)
	_credit_memo_card = PanelContainer.new()
	_credit_memo_card.name = "FiledCreditMemoCard"
	_credit_memo_card.custom_minimum_size = Vector2(600.0, 96.0)
	_credit_memo_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_credit_memo_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20333a"), Color("8b7444"), 8, 1),
	)
	_report_story_row.add_child(_credit_memo_card)
	var credit_margin := MarginContainer.new()
	credit_margin.add_theme_constant_override("margin_left", 14)
	credit_margin.add_theme_constant_override("margin_right", 14)
	credit_margin.add_theme_constant_override("margin_top", 8)
	credit_margin.add_theme_constant_override("margin_bottom", 8)
	_credit_memo_card.add_child(credit_margin)
	_credit_memo_label = _make_label("CREDIT MEMO AWAITING FILE", 12, CREAM)
	_credit_memo_label.name = "FiledCreditMemoLabel"
	_credit_memo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credit_memo_label.max_lines_visible = 4
	_credit_memo_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_credit_memo_label.mouse_filter = Control.MOUSE_FILTER_STOP
	credit_margin.add_child(_credit_memo_label)

	_hen_highlight_card = PanelContainer.new()
	_hen_highlight_card.name = "ShiftHenHighlightCard"
	_hen_highlight_card.custom_minimum_size = Vector2(320.0, 96.0)
	_hen_highlight_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_report_story_row.add_child(_hen_highlight_card)
	var highlight_stack := _panel_content(_hen_highlight_card, 14, 8, 1)
	_hen_highlight_eyebrow = _make_label("HEN FILE  //  AWAITING SUBJECT", 9, TEAL)
	_hen_highlight_eyebrow.name = "ShiftHenHighlightEyebrow"
	_hen_highlight_eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	highlight_stack.add_child(_hen_highlight_eyebrow)
	_hen_highlight_headline = _make_label("SHIFT HIGHLIGHT", 14, CREAM)
	_hen_highlight_headline.name = "ShiftHenHighlightHeadline"
	_hen_highlight_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	highlight_stack.add_child(_hen_highlight_headline)
	_hen_highlight_body = _make_label("Awaiting a closing hen file.", 11, INK)
	_hen_highlight_body.name = "ShiftHenHighlightBody"
	_hen_highlight_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hen_highlight_body.max_lines_visible = 3
	_hen_highlight_body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hen_highlight_body.mouse_filter = Control.MOUSE_FILTER_STOP
	highlight_stack.add_child(_hen_highlight_body)
	_hen_highlight_metric = _make_label("0 EGGS", 9, MUTED)
	_hen_highlight_metric.name = "ShiftHenHighlightMetric"
	_hen_highlight_metric.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	highlight_stack.add_child(_hen_highlight_metric)
	_report_ledger_section_label = _section_label("CUMULATIVE PROBATION LEDGERS")
	_report_ledger_section_label.name = "ReportLedgerSectionTitle"
	content.add_child(_report_ledger_section_label)
	_build_ledger_row(content, "Report", _report_ledger_labels)
	var report_safeguards := _build_safeguard_receipt(content, "Report", _report_safeguard_rows)
	_report_safeguard_panel = report_safeguards["panel"] as PanelContainer
	_report_safeguard_summary = report_safeguards["summary"] as Label
	_report_safeguard_grid = report_safeguards["grid"] as GridContainer

	var objective_card := PanelContainer.new()
	objective_card.name = "NextShiftObjectiveCard"
	objective_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20333a"), Color("4c786f"), 8, 1),
	)
	content.add_child(objective_card)
	var objective_content := _panel_content(objective_card, 16, 10, 3)
	_objective_title_label = _make_label("NEXT SHIFT OBJECTIVE", 14, TEAL)
	_objective_title_label.name = "NextShiftObjective"
	_objective_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_content.add_child(_objective_title_label)
	_objective_body_label = _make_label("Awaiting the next quota notice.", 13, INK)
	_objective_body_label.name = "NextShiftObjectiveDescription"
	_objective_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_content.add_child(_objective_body_label)
	_objective_progress_label = _make_label("", 11, Color("a9c8c0"))
	_objective_progress_label.name = "NextShiftObjectiveProgress"
	_objective_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_content.add_child(_objective_progress_label)

	_milestone_section = VBoxContainer.new()
	_milestone_section.name = "MilestoneChoiceSection"
	_milestone_section.add_theme_constant_override("separation", 5)
	content.add_child(_milestone_section)
	_milestone_section_label = _section_label("MILESTONE REQUISITION  //  CHOOSE ONE PERMANENT EDGE")
	_milestone_section_label.name = "MilestoneChoiceSectionTitle"
	_milestone_section.add_child(_milestone_section_label)
	_milestone_buttons_host = HFlowContainer.new()
	_milestone_buttons_host.name = "MilestoneChoiceCards"
	_milestone_buttons_host.add_theme_constant_override("h_separation", 10)
	_milestone_buttons_host.add_theme_constant_override("v_separation", 8)
	_milestone_section.add_child(_milestone_buttons_host)
	_milestone_hint_label = _make_label("Select one card before filing the next-shift plan.", 11, BRASS)
	_milestone_hint_label.name = "MilestoneChoiceHint"
	_milestone_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_milestone_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_milestone_section.add_child(_milestone_hint_label)

	_career_sponsorship_ui = CareerSponsorshipUIScript.new() as CareerSponsorshipUI
	_career_sponsorship_ui.name = "CareerSponsorshipUI"
	_career_sponsorship_ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_career_sponsorship_ui.sponsorship_requested.connect(
		func(worker_id: int, lane_id: StringName) -> void:
			career_sponsorship_requested.emit(worker_id, lane_id)
	)
	content.add_child(_career_sponsorship_ui)

	_report_actions = HFlowContainer.new()
	_report_actions.name = "ProbationReportActions"
	_report_actions.alignment = FlowContainer.ALIGNMENT_END
	_report_actions.add_theme_constant_override("h_separation", 12)
	_report_actions.add_theme_constant_override("v_separation", 8)
	content.add_child(_report_actions)
	var abandon := _make_button("AbandonCampaignButton", "SHELVE & RETURN TO INTAKE  [A]", &"DecisionChoiceButton")
	abandon.custom_minimum_size = Vector2(190.0, 44.0)
	abandon.shortcut = _shortcut(KEY_A)
	abandon.pressed.connect(_on_abandon_campaign_pressed)
	_report_actions.add_child(abandon)
	_report_continue_button = _make_button(
		"ContinueProbationButton",
		"FILE REPORT & PLAN NEXT SHIFT  [C]",
		&"PrimaryButton",
	)
	_report_continue_button.custom_minimum_size = Vector2(310.0, 44.0)
	_report_continue_button.shortcut = _shortcut(KEY_C)
	_report_continue_button.pressed.connect(_on_continue_campaign_pressed)
	_report_actions.add_child(_report_continue_button)


func _build_final_panel(parent: Control) -> void:
	_final_panel = PanelContainer.new()
	_final_panel.name = "FinalProbationReviewPanel"
	_final_panel.custom_minimum_size = Vector2(860.0, 0.0)
	parent.add_child(_final_panel)

	var content := _panel_content(_final_panel, 32, 24, 11)
	var eyebrow := _make_label("CORNFIELDS MUTUAL  //  FINAL MANAGEMENT REVIEW", 12, BRASS)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(eyebrow)
	_final_verdict_label = _make_label("PROBATION REVIEW", 31, CREAM)
	_final_verdict_label.name = "FinalProbationVerdict"
	_final_verdict_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_verdict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_final_verdict_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_final_verdict_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_final_verdict_label)
	_final_message_label = _make_label("Five shifts have been entered into the permanent coop record.", 15, INK)
	_final_message_label.name = "FinalProbationMessage"
	_final_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_final_message_label)

	_final_metrics = HFlowContainer.new()
	_final_metrics.name = "FinalProbationMetrics"
	_final_metrics.alignment = FlowContainer.ALIGNMENT_CENTER
	_final_metrics.add_theme_constant_override("h_separation", 16)
	_final_metrics.add_theme_constant_override("v_separation", 8)
	content.add_child(_final_metrics)
	_final_score_label = _make_metric("FinalScore", "0", "FINAL SCORE", 190.0)
	_final_metrics.add_child(_metric_panel(_final_score_label))
	_final_rank_label = _make_metric("FinalRank", "UNRANKED", "FINAL RANK", 276.0, 16, true)
	_final_metrics.add_child(_metric_panel(_final_rank_label))

	content.add_child(_section_label("FIVE-SHIFT CLOSING LEDGERS"))
	_build_ledger_row(content, "Final", _final_ledger_labels)
	var final_safeguards := _build_safeguard_receipt(content, "Final", _final_safeguard_rows)
	_final_safeguard_panel = final_safeguards["panel"] as PanelContainer
	_final_safeguard_summary = final_safeguards["summary"] as Label
	_final_safeguard_grid = final_safeguards["grid"] as GridContainer

	_final_actions = HFlowContainer.new()
	_final_actions.name = "FinalProbationActions"
	_final_actions.alignment = FlowContainer.ALIGNMENT_CENTER
	_final_actions.add_theme_constant_override("h_separation", 11)
	_final_actions.add_theme_constant_override("v_separation", 8)
	content.add_child(_final_actions)
	var leave := _make_button("FinalAbandonCampaignButton", "SHELVE & RETURN TO INTAKE  [A]", &"DecisionChoiceButton")
	leave.custom_minimum_size = Vector2(190.0, 46.0)
	leave.shortcut = _shortcut(KEY_A)
	leave.pressed.connect(_on_abandon_campaign_pressed)
	_final_actions.add_child(leave)
	_final_new_button = _make_button("FinalNewCampaignButton", "NEW CAMPAIGN  [N]", &"DecisionChoiceButton")
	_final_new_button.custom_minimum_size = Vector2(210.0, 46.0)
	_final_new_button.shortcut = _shortcut(KEY_N)
	_final_new_button.pressed.connect(_on_new_campaign_pressed)
	_final_actions.add_child(_final_new_button)
	_final_continue_button = _make_button("FinalContinueCampaignButton", "ENTER THE SENIOR ROOST  [C]", &"PrimaryButton")
	_final_continue_button.custom_minimum_size = Vector2(260.0, 46.0)
	_final_continue_button.shortcut = _shortcut(KEY_C)
	_final_continue_button.pressed.connect(_on_continue_campaign_pressed)
	_final_actions.add_child(_final_continue_button)


func _build_final_sticky_action_bar() -> void:
	_final_sticky_action_bar = PanelContainer.new()
	_final_sticky_action_bar.name = "FinalStickyActionBar"
	_final_sticky_action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_final_sticky_action_bar.offset_left = 18.0
	_final_sticky_action_bar.offset_top = -78.0
	_final_sticky_action_bar.offset_right = -18.0
	_final_sticky_action_bar.offset_bottom = -14.0
	_final_sticky_action_bar.z_index = 14
	_final_sticky_action_bar.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), Color("8b7444"), 10, 2),
	)
	_modal_host.add_child(_final_sticky_action_bar)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	_final_sticky_action_bar.add_child(margin)
	var actions := HFlowContainer.new()
	actions.name = "FinalStickyActions"
	actions.alignment = FlowContainer.ALIGNMENT_END
	actions.add_theme_constant_override("h_separation", 10)
	actions.add_theme_constant_override("v_separation", 6)
	margin.add_child(actions)
	var next_step := _make_label("NEXT STEP  //  THE FILE IS CLOSED", 11, BRASS)
	next_step.name = "FinalStickyActionLabel"
	next_step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_step.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_step.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions.add_child(next_step)
	_final_sticky_leave_button = _make_button(
		"FinalStickyLeaveButton",
		"SHELVE FILE  [A]",
		&"DecisionChoiceButton",
	)
	_final_sticky_leave_button.custom_minimum_size = Vector2(170.0, 46.0)
	_final_sticky_leave_button.shortcut = _shortcut(KEY_A)
	_final_sticky_leave_button.pressed.connect(_on_abandon_campaign_pressed)
	actions.add_child(_final_sticky_leave_button)
	_final_sticky_primary_button = _make_button(
		"FinalStickyPrimaryButton",
		"RETRY PROBATION  [N]",
		&"PrimaryButton",
	)
	_final_sticky_primary_button.custom_minimum_size = Vector2(250.0, 46.0)
	_final_sticky_primary_button.pressed.connect(_on_final_sticky_primary_pressed)
	actions.add_child(_final_sticky_primary_button)


func _build_safeguard_receipt(
	parent: VBoxContainer,
	prefix: String,
	rows: Array[Label],
) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "%sProbationSafeguardReceipt" % prefix
	panel.visible = false
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1c3038"), Color("6f8e87"), 8, 1),
	)
	parent.add_child(panel)
	var content := _panel_content(panel, 16, 10, 4)
	var heading := _make_label("PROBATION PASS SAFEGUARDS  //  EXACT FILING TERMS", 11, TEAL)
	heading.name = "%sProbationSafeguardHeading" % prefix
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	var summary := _make_label("IF FILED NOW  //  0 / 5 SAFEGUARDS", 14, CREAM)
	summary.name = "%sProbationSafeguardSummary" % prefix
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(summary)
	var grid := GridContainer.new()
	grid.name = "%sProbationSafeguardGrid" % prefix
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 3)
	content.add_child(grid)
	for index: int in range(5):
		var row := _make_label("AWAITING FILE", 11, MUTED)
		row.name = "%sProbationSafeguardRow_%d" % [prefix, index + 1]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(row)
		rows.append(row)
	return {"panel": panel, "summary": summary, "grid": grid}


func _build_replacement_confirmation() -> void:
	_replacement_confirmation_host = Control.new()
	_replacement_confirmation_host.name = "CampaignReplacementConfirmation"
	_replacement_confirmation_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_replacement_confirmation_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_replacement_confirmation_host.z_index = 100
	_replacement_confirmation_host.visible = false
	_modal_host.add_child(_replacement_confirmation_host)

	var scrim := ColorRect.new()
	scrim.name = "CampaignReplacementConfirmationScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.006, 0.012, 0.018, 0.92)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_replacement_confirmation_host.add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 18.0
	center.offset_top = 18.0
	center.offset_right = -18.0
	center.offset_bottom = -18.0
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_replacement_confirmation_host.add_child(center)

	_replacement_confirmation_panel = PanelContainer.new()
	_replacement_confirmation_panel.name = "CampaignReplacementConfirmationPanel"
	_replacement_confirmation_panel.custom_minimum_size = Vector2(560.0, 0.0)
	_replacement_confirmation_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1a2730"), RUST, 12, 2),
	)
	center.add_child(_replacement_confirmation_panel)
	var content := _panel_content(_replacement_confirmation_panel, 26, 22, 12)
	var eyebrow := _make_label("RECORDS CONTROL  //  DESTRUCTIVE FILING", 11, RUST)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(eyebrow)
	_replacement_confirmation_title = _make_label("REPLACE THE SAVED COOP FILE?", 24, CREAM)
	_replacement_confirmation_title.name = "CampaignReplacementConfirmationTitle"
	_replacement_confirmation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replacement_confirmation_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_replacement_confirmation_title)
	_replacement_confirmation_body = _make_label("", 13, INK)
	_replacement_confirmation_body.name = "CampaignReplacementConfirmationBody"
	_replacement_confirmation_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replacement_confirmation_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_replacement_confirmation_body)
	var actions := HFlowContainer.new()
	actions.name = "CampaignReplacementConfirmationActions"
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("h_separation", 12)
	actions.add_theme_constant_override("v_separation", 8)
	content.add_child(actions)
	_replacement_confirmation_cancel = _make_button(
		"CancelCampaignReplacementButton",
		"KEEP CURRENT FILE  [ESC]",
		&"PrimaryButton",
	)
	_replacement_confirmation_cancel.custom_minimum_size = Vector2(220.0, 48.0)
	_replacement_confirmation_cancel.shortcut = _shortcut(KEY_ESCAPE)
	_replacement_confirmation_cancel.pressed.connect(_cancel_campaign_replacement)
	actions.add_child(_replacement_confirmation_cancel)
	_replacement_confirmation_confirm = _make_button(
		"ConfirmCampaignReplacementButton",
		"REPLACE & START FRESH  [Y]",
		&"DangerButton",
	)
	_replacement_confirmation_confirm.custom_minimum_size = Vector2(240.0, 48.0)
	_replacement_confirmation_confirm.shortcut = _shortcut(KEY_Y)
	_replacement_confirmation_confirm.pressed.connect(_confirm_campaign_replacement)
	actions.add_child(_replacement_confirmation_confirm)


func _refresh() -> void:
	if _day_badge == null:
		return
	var total_days := maxi(1, int(_snapshot.get("total_days", DEFAULT_TOTAL_DAYS)))
	var day := clampi(int(_snapshot.get("day", 1)), 1, total_days)
	var status_text := String(_snapshot.get("status", "PROBATION")).strip_edges().to_upper()
	if status_text.is_empty():
		status_text = "PROBATION"
	var status_tooltip := status_text
	if _view == VIEW_ACTIVE and _snapshot.has("score"):
		var score_text := _format_integer(int(_snapshot.get("score", 0)))
		if status_text == "SENIOR ROOST":
			status_tooltip = "SENIOR ROOST  %s" % score_text
			status_text = "ROOST  %s" % score_text
		else:
			status_text = "SCORE %s / %d" % [score_text, PROBATION_SCORE_LIMIT]
			status_tooltip = _challenge_contract_terms_text(_active_challenge_contract(), true)
	_status_label.text = status_text
	_status_label.tooltip_text = status_tooltip
	_day_label.text = String(_snapshot.get("day_badge_text", "DAY %d / %d" % [day, total_days]))
	_refresh_live_order_badge()

	var modal_open := _view != VIEW_ACTIVE
	_modal_host.visible = modal_open
	_modal_scroll.visible = _view != VIEW_CONTRACT_BOARD
	_title_panel.visible = _view == VIEW_TITLE
	_report_panel.visible = _view == VIEW_REPORT
	_final_panel.visible = _view == VIEW_FINAL
	_final_sticky_action_bar.visible = _view == VIEW_FINAL and size.x >= 720.0
	_contract_board_ui.visible = _view == VIEW_CONTRACT_BOARD
	_apply_responsive_layout()
	if not modal_open:
		return

	match _view:
		VIEW_TITLE:
			_refresh_title()
		VIEW_REPORT:
			_refresh_report(day, total_days)
		VIEW_CONTRACT_BOARD:
			_contract_board_ui.apply_snapshot(_snapshot)
		VIEW_FINAL:
			_refresh_final()


func _refresh_title() -> void:
	_rebuild_challenge_contract_selector()
	var can_continue := _snapshot_continue_available()
	var resume_value: Variant = _snapshot.get("resume_summary", {})
	var resume_summary := resume_value as Dictionary if resume_value is Dictionary else {}
	var resume_details := _format_resume_summary(resume_summary)
	if _title_resume_heading != null:
		_title_resume_heading.text = (
			"RECOVERY COPY FOUND  //  SAVED COOP FILE CANDIDATE"
			if bool(resume_summary.get("recovered_from_backup", false)) else
			"SAVED COOP FILE CANDIDATE"
		)
	if _title_resume_details != null:
		_title_resume_details.text = resume_details
	_continue_title_button.disabled = not can_continue
	_continue_title_button.tooltip_text = (
		"Verify and resume the saved coop file candidate.\n%s" % resume_details
		if can_continue else
		"No saved probation file is available yet."
	)
	_apply_title_hierarchy(can_continue)


func _snapshot_continue_available() -> bool:
	return bool(_snapshot.get(
		"continue_available",
		_snapshot.get("has_continue", false),
	))


func _apply_title_hierarchy(can_continue: bool) -> void:
	# A fresh intake has no landing decision to make, so it opens directly on the
	# compact new-file terms. A valid checkpoint instead receives a resume-first
	# landing with one primary action and an explicit secondary path to setup.
	_title_new_file_setup = _title_new_file_setup or not can_continue
	var setup_visible := _title_new_file_setup
	if _title_heading != null:
		_title_heading.text = (
			"FIVE SHIFTS. START BY MEETING MABEL."
			if setup_visible else
			"YOUR COOP FILE IS READY."
		)
	if _title_description != null:
		_title_description.text = (
			"Mabel is already at her desk. Every choice you make together shares one permanent coop file."
			if setup_visible else
			"Continue the saved filing candidate; it will be verified before the coop opens, or deliberately review a new file."
		)
	if _title_profile_card != null:
		_title_profile_card.visible = setup_visible
	if _title_challenge_card != null:
		_title_challenge_card.visible = setup_visible
	if _title_probation_summary != null:
		_title_probation_summary.visible = setup_visible
	if _title_resume_card != null:
		_title_resume_card.visible = can_continue and not setup_visible

	_continue_title_button.visible = can_continue and not setup_visible
	_continue_title_button.theme_type_variation = &"PrimaryButton"
	_title_new_button.visible = true
	_title_new_button.theme_type_variation = (
		&"PrimaryButton" if setup_visible else &"DecisionChoiceButton"
	)
	_title_new_button.text = (
		"MEET MABEL & OPEN FILE  [N]"
		if setup_visible else
		"REVIEW A NEW FILE  [N]"
	)
	_title_new_button.tooltip_text = (
		"Open a five-shift probation file under %s.%s" % [
			_challenge_contract_label(_selected_challenge_contract(), false),
			" The saved file will remain untouched until replacement is confirmed and verified."
			if can_continue else "",
		]
		if setup_visible else
		"Review Mabel's new-file introduction and immutable challenge terms. The saved file is not changed."
	)
	_title_back_button.visible = can_continue and setup_visible
	_apply_title_contract_disclosure()

	if can_continue and not setup_visible:
		_queue_focus(_continue_title_button)
	elif _title_challenge_selector != null and _title_challenge_selector.visible:
		_queue_focus(_title_challenge_selector)
	else:
		_queue_focus(_title_new_button)


func _format_resume_summary(summary: Dictionary) -> String:
	if summary.is_empty():
		return "A resumable checkpoint candidate is available. Continue verifies its complete filed state before opening."
	var lines: Array[String] = []
	var senior_resume := bool(summary.get("senior_roost", false))
	if senior_resume:
		lines.append("SENIOR YEAR %d  //  %d ROOST MARK%s  //  %d BOARD SEAL%s" % [
			maxi(1, int(summary.get("senior_year", 1))),
			maxi(0, int(summary.get("roost_marks", 0))),
			"" if int(summary.get("roost_marks", 0)) == 1 else "S",
			maxi(0, int(summary.get("mandate_seals", 0))),
			"" if int(summary.get("mandate_seals", 0)) == 1 else "S",
		])
	else:
		lines.append("DAY %d / %d  //  %d SHIFT%s FILED  //  SCORE %d" % [
			clampi(int(summary.get("day", 1)), 1, DEFAULT_TOTAL_DAYS),
			DEFAULT_TOTAL_DAYS,
			maxi(0, int(summary.get("completed_shifts", 0))),
			"" if int(summary.get("completed_shifts", 0)) == 1 else "S",
			clampi(int(summary.get("probation_score", 50)), 0, PROBATION_SCORE_LIMIT),
		])
	if not senior_resume:
		var saved_contract := _challenge_contract_from_value(summary.get("challenge_contract", {}))
		if not saved_contract.is_empty():
			lines.append("SAVED CHALLENGE CONTRACT  //  %s" % _challenge_contract_label(saved_contract, false))
		elif summary.has("challenge_contract_verified") and not bool(summary.get(
			"challenge_contract_verified",
			false,
		)):
			lines.append("SAVED CHALLENGE CONTRACT  //  UNVERIFIED SAVED TERMS")
	var rank_label := String(summary.get("rank_label", "")).strip_edges().to_upper()
	var stage_label := String(summary.get("stage_label", "")).strip_edges().to_upper()
	var context: Array[String] = []
	if not rank_label.is_empty():
		context.append(rank_label)
	if not stage_label.is_empty():
		context.append(stage_label)
	if not context.is_empty():
		lines.append("  //  ".join(context))
	return "\n".join(lines)


func _rebuild_challenge_contract_selector() -> void:
	if _title_challenge_selector == null:
		return
	var catalog := _challenge_contract_catalog()
	var desired_id := _selected_challenge_contract_id
	if _challenge_contract_by_id(desired_id, catalog).is_empty():
		desired_id = _default_challenge_contract_id(catalog)
	_challenge_selector_syncing = true
	_title_challenge_selector.clear()
	var selected_index := 0
	for index: int in range(catalog.size()):
		var contract := catalog[index]
		var contract_id := StringName(String(contract.get("id", "")))
		_title_challenge_selector.add_item(_challenge_contract_selector_label(contract))
		_title_challenge_selector.set_item_metadata(index, String(contract_id))
		if contract_id == desired_id:
			selected_index = index
	_title_challenge_selector.select(selected_index)
	_challenge_selector_syncing = false
	if not catalog.is_empty():
		var selected_contract := catalog[selected_index]
		_selected_challenge_contract_id = StringName(String(selected_contract.get(
			"id",
			DEFAULT_CHALLENGE_CONTRACT_ID,
		)))
		_snapshot["selected_new_challenge_contract_id"] = String(_selected_challenge_contract_id)
		_update_challenge_contract_detail(selected_contract)


func _on_challenge_contract_selected(index: int) -> void:
	if _challenge_selector_syncing or _title_challenge_selector == null:
		return
	if index < 0 or index >= _title_challenge_selector.item_count:
		return
	var contract_id := StringName(String(_title_challenge_selector.get_item_metadata(index)))
	var contract := _challenge_contract_by_id(contract_id, _challenge_contract_catalog())
	if contract.is_empty():
		return
	_selected_challenge_contract_id = contract_id
	_snapshot["selected_new_challenge_contract_id"] = String(contract_id)
	_update_challenge_contract_detail(contract)
	challenge_contract_changed.emit(contract_id)


func _update_challenge_contract_detail(contract: Dictionary) -> void:
	var description := String(contract.get(
		"description",
		"The selected probation filing terms remain fixed for this career.",
	)).strip_edges()
	var terms := _challenge_contract_terms_text(contract, false)
	var route_brief := String(contract.get("route_brief", "")).strip_edges().to_upper()
	var route_guidance := String(contract.get("route_guidance", "")).strip_edges()
	var difficulty_label := _challenge_contract_difficulty_label(contract)
	var difficulty_guidance := String(contract.get("difficulty_guidance", "")).strip_edges()
	if _title_challenge_summary != null:
		_title_challenge_summary.text = "%s DIFFICULTY  //  %s%s" % [
			difficulty_label,
			description,
			(
				"\n%s  //  LOCKS ON OPEN" % route_brief
				if not route_brief.is_empty() else
				"\nLOCKS ON OPEN"
			),
		]
		_title_challenge_summary.tooltip_text = "\n".join([
			"%s DIFFICULTY" % difficulty_label,
			difficulty_guidance,
			description,
			route_guidance,
			terms,
		].filter(func(line: String) -> bool: return not line.is_empty()))
	if _title_challenge_detail != null:
		_title_challenge_detail.text = "%s%s" % [
			terms,
			"\nDIFFICULTY NOTE  //  %s" % difficulty_guidance if not difficulty_guidance.is_empty() else "",
		]
		if not route_guidance.is_empty():
			_title_challenge_detail.text += "\nROUTE NOTE  //  %s" % route_guidance
		_title_challenge_detail.tooltip_text = "%s\n%s\n%s%s" % [
			_challenge_contract_label(contract, false),
			description,
			terms,
			"\n%s" % route_guidance if not route_guidance.is_empty() else "",
		]
	if _title_challenge_terms_toggle != null:
		_title_challenge_terms_toggle.tooltip_text = (
			"Show or hide the exact immutable approval thresholds.\n%s\n%s"
			% [description, _title_challenge_detail.text if _title_challenge_detail != null else terms]
		)
	if _title_challenge_selector != null:
		_title_challenge_selector.tooltip_text = (
			"Choose Learning, Standard, or Expert difficulty for the new coop file. The terms lock when the file opens.\n%s"
			% (_title_challenge_detail.tooltip_text if _title_challenge_detail != null else terms)
		)
	_apply_title_contract_disclosure()


func _apply_title_contract_disclosure() -> void:
	if _title_challenge_detail != null:
		_title_challenge_detail.visible = (
			_title_new_file_setup and _title_contract_terms_expanded
		)
	if _title_challenge_terms_toggle != null:
		_title_challenge_terms_toggle.button_pressed = _title_contract_terms_expanded
		_title_challenge_terms_toggle.text = (
			"HIDE EXACT TERMS  [T]"
			if _title_contract_terms_expanded else
			"VIEW EXACT TERMS  [T]"
		)


func _on_challenge_contract_terms_toggled() -> void:
	if _title_challenge_terms_toggle == null or not _title_new_file_setup:
		return
	_title_contract_terms_expanded = _title_challenge_terms_toggle.button_pressed
	_apply_title_contract_disclosure()


func _on_title_back_pressed() -> void:
	if not _snapshot_continue_available() or not _title_new_file_setup:
		return
	_title_new_file_setup = false
	_title_contract_terms_expanded = false
	_refresh_title()
	title_intake_phase_changed.emit(title_intake_phase())


func _challenge_contract_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var catalog_value: Variant = _snapshot.get("challenge_contract_catalog", [])
	if catalog_value is Array:
		for contract_value: Variant in catalog_value as Array:
			if not contract_value is Dictionary:
				continue
			var contract := _normalized_challenge_contract(contract_value as Dictionary)
			if contract.is_empty() or not _challenge_contract_by_id(
				StringName(String(contract.get("id", ""))),
				result,
			).is_empty():
				continue
			result.append(contract)
	if result.is_empty():
		result.append(_normalized_challenge_contract(DEFAULT_CHALLENGE_CONTRACT))
	return result


func _challenge_contract_from_value(value: Variant) -> Dictionary:
	if value is Dictionary:
		return _normalized_challenge_contract(value as Dictionary)
	if value is String or value is StringName:
		return _challenge_contract_by_id(StringName(String(value)), _challenge_contract_catalog())
	return {}


func _normalized_challenge_contract(source: Dictionary) -> Dictionary:
	var contract_id := String(source.get("id", "")).strip_edges().to_lower()
	if contract_id.is_empty():
		return {}
	var result := source.duplicate(true)
	result["id"] = contract_id
	var fallback_label := contract_id.replace("_", " ").to_upper()
	var label := String(result.get("label", fallback_label)).strip_edges().to_upper()
	if label.is_empty():
		label = fallback_label
	result["label"] = label
	var short_label := String(result.get("short_label", label)).strip_edges().to_upper()
	result["short_label"] = label if short_label.is_empty() else short_label
	result["description"] = String(result.get(
		"description",
		"The selected probation filing terms remain fixed for this career.",
	)).strip_edges()
	var difficulty := String(result.get("difficulty", "")).strip_edges().to_lower()
	if difficulty not in ["learning", "standard", "expert"]:
		difficulty = _challenge_contract_fallback_difficulty(contract_id)
	result["difficulty"] = difficulty
	result["difficulty_label"] = String(result.get(
		"difficulty_label",
		difficulty.to_upper(),
	)).strip_edges().to_upper()
	result["difficulty_guidance"] = String(result.get(
		"difficulty_guidance",
		"These terms remain fixed for the five-shift probation file.",
	)).strip_edges()
	result["criteria"] = _challenge_contract_criteria(result)
	return result


func _challenge_contract_fallback_difficulty(contract_id: String) -> String:
	match contract_id:
		"supported_flock":
			return "learning"
		"executive_audit":
			return "expert"
		_:
			return "standard"


func _challenge_contract_by_id(
	contract_id: StringName,
	catalog: Array[Dictionary],
) -> Dictionary:
	var normalized_id := StringName(String(contract_id).strip_edges().to_lower())
	for contract: Dictionary in catalog:
		if StringName(String(contract.get("id", ""))) == normalized_id:
			return contract.duplicate(true)
	return {}


func _default_challenge_contract_id(catalog: Array[Dictionary]) -> StringName:
	if not _challenge_contract_by_id(DEFAULT_CHALLENGE_CONTRACT_ID, catalog).is_empty():
		return DEFAULT_CHALLENGE_CONTRACT_ID
	for contract: Dictionary in catalog:
		if "STANDARD" in _challenge_contract_label(contract, false):
			return StringName(String(contract.get("id", DEFAULT_CHALLENGE_CONTRACT_ID)))
	return (
		StringName(String(catalog[0].get("id", DEFAULT_CHALLENGE_CONTRACT_ID)))
		if not catalog.is_empty() else
		DEFAULT_CHALLENGE_CONTRACT_ID
	)


func _selected_challenge_contract() -> Dictionary:
	var catalog := _challenge_contract_catalog()
	var contract := _challenge_contract_by_id(_selected_challenge_contract_id, catalog)
	if contract.is_empty():
		contract = _challenge_contract_by_id(_default_challenge_contract_id(catalog), catalog)
	return contract if not contract.is_empty() else _normalized_challenge_contract(DEFAULT_CHALLENGE_CONTRACT)


func _active_challenge_contract() -> Dictionary:
	var contract := _challenge_contract_from_value(_snapshot.get("challenge_contract", {}))
	if contract.is_empty():
		var forecast_value: Variant = _snapshot.get("probation_safeguard_forecast", {})
		if forecast_value is Dictionary:
			contract = _challenge_contract_from_value(
				(forecast_value as Dictionary).get("challenge_contract", {})
			)
	if contract.is_empty():
		contract = _normalized_challenge_contract(DEFAULT_CHALLENGE_CONTRACT)
	return contract


func _challenge_contract_criteria(contract: Dictionary) -> Dictionary:
	var defaults := (DEFAULT_CHALLENGE_CONTRACT.get("criteria", {}) as Dictionary).duplicate(true)
	var criteria_value: Variant = contract.get("criteria", {})
	if not criteria_value is Dictionary:
		return defaults
	var criteria := criteria_value as Dictionary
	defaults["minimum_score"] = clampi(_criterion_integer(
		criteria,
		["minimum_score", "score", "min_score", "probation_score"],
		int(defaults["minimum_score"]),
	), 0, PROBATION_SCORE_LIMIT)
	defaults["minimum_welfare"] = clampi(_criterion_integer(
		criteria,
		["minimum_welfare", "welfare", "min_welfare"],
		int(defaults["minimum_welfare"]),
	), 0, 100)
	defaults["minimum_compliance"] = clampi(_criterion_integer(
		criteria,
		["minimum_compliance", "compliance", "min_compliance"],
		int(defaults["minimum_compliance"]),
	), 0, 100)
	defaults["minimum_farmer_favor"] = clampi(_criterion_integer(
		criteria,
		["minimum_farmer_favor", "farmer_favor", "min_farmer_favor"],
		int(defaults["minimum_farmer_favor"]),
	), 0, 100)
	defaults["maximum_crack_rate_basis_points"] = clampi(_criterion_integer(
		criteria,
		[
			"maximum_crack_rate_basis_points", "max_crack_rate_basis_points",
			"crack_rate_basis_points", "maximum_crack_rate", "max_crack_rate",
		],
		int(defaults["maximum_crack_rate_basis_points"]),
	), 0, 10000)
	return defaults


func _criterion_integer(source: Dictionary, keys: Array[String], fallback: int) -> int:
	for key: String in keys:
		if not source.has(key):
			continue
		var value: Variant = source[key]
		if value is Dictionary:
			value = (value as Dictionary).get("target", fallback)
		if value is int or value is float:
			return int(value)
	return fallback


func _challenge_contract_label(contract: Dictionary, compact: bool) -> String:
	var label_key := "short_label" if compact else "label"
	var label := String(contract.get(label_key, contract.get("label", "STANDARD FILING")))
	return label.strip_edges().to_upper() if not label.strip_edges().is_empty() else "STANDARD FILING"


func _challenge_contract_difficulty_label(contract: Dictionary) -> String:
	var normalized := _normalized_challenge_contract(contract)
	var label := String(normalized.get("difficulty_label", "STANDARD")).strip_edges().to_upper()
	return label if not label.is_empty() else "STANDARD"


func _challenge_contract_selector_label(contract: Dictionary) -> String:
	return "[%s] %s" % [
		_challenge_contract_difficulty_label(contract),
		_challenge_contract_label(contract, false),
	]


func _challenge_contract_terms_text(contract: Dictionary, include_heading: bool) -> String:
	var criteria := _challenge_contract_criteria(contract)
	var terms := (
		"PASS FILE  //  SCORE >= %d / %d  //  WELFARE >= %d  //  COMPLIANCE >= %d"
		+ "  //  FARMER FAVOR >= %d  //  CRACK RATE <= %.2f%%"
	) % [
		int(criteria["minimum_score"]),
		PROBATION_SCORE_LIMIT,
		int(criteria["minimum_welfare"]),
		int(criteria["minimum_compliance"]),
		int(criteria["minimum_farmer_favor"]),
		float(criteria["maximum_crack_rate_basis_points"]) / 100.0,
	]
	if include_heading:
		return "CHALLENGE CONTRACT  //  %s DIFFICULTY  //  %s\n%s" % [
			_challenge_contract_difficulty_label(contract),
			_challenge_contract_label(contract, false),
			terms,
		]
	return terms


func _refresh_report(day: int, total_days: int) -> void:
	var senior := _is_senior_snapshot()
	_report_day_label.text = String(_snapshot.get(
		"report_kicker",
		(
			"SENIOR ROOST  //  YEAR %d  //  QUARTER %d  //  SHIFT %d OF %d" % [
				maxi(1, int(_snapshot.get("senior_year", 1))),
				maxi(1, int(_snapshot.get("senior_quarter", 1))),
				day,
				total_days,
			]
			if senior else
			"CLOSING FILE 3 / 3 · SHIFT %d OF %d · PROBATION REPORT" % [day, total_days]
		),
	))
	_report_heading_label.text = String(_snapshot.get(
		"report_heading",
		"SENIOR ROOST QUARTERLY FILING" if senior else "FARMER'S SHIFT ASSESSMENT",
	)).to_upper()
	_report_ledger_section_label.text = String(_snapshot.get(
		"ledger_section_title",
		"SENIOR CAREER LEDGERS" if senior else "CUMULATIVE PROBATION LEDGERS",
	)).to_upper()
	_milestone_section_label.text = String(_snapshot.get(
		"choice_section_title",
		"QUARTERLY CAPITAL POLICY  //  FILE ONE" if senior else "MILESTONE REQUISITION  //  CHOOSE ONE PERMANENT EDGE",
	)).to_upper()
	_report_continue_button.text = String(_snapshot.get(
		"continue_label",
		"FILE POLICY & OPEN QUARTER  [C]" if senior else "FILE REPORT & PLAN NEXT SHIFT  [C]",
	))
	_report_score_label.text = _format_integer(int(_snapshot.get("score", 0)))
	_report_rank_label.text = String(_snapshot.get("rank", "UNRANKED")).to_upper()
	_update_score_receipt(day)
	_set_metric_caption(_report_score_label, String(_snapshot.get("score_caption", "SCORE")))
	_set_metric_caption(_report_shift_delta_label, String(_snapshot.get("secondary_metric_caption", "SHIFT SCORE")))
	_set_metric_caption(_report_rank_label, String(_snapshot.get("rank_caption", "RANK")))
	if _snapshot.has("secondary_metric_display"):
		_report_shift_delta_label.text = String(_snapshot["secondary_metric_display"])
		_report_shift_delta_label.add_theme_color_override("font_color", CREAM)
		_report_shift_delta_label.tooltip_text = String(_snapshot.get("secondary_metric_tooltip", ""))
	_update_credit_memo(day)
	_update_hen_highlight(day)
	_update_ledger_labels(_report_ledger_labels)
	_refresh_probation_safeguard_receipt(
		_report_safeguard_panel,
		_report_safeguard_summary,
		_report_safeguard_rows,
		false,
	)
	_update_objective()
	_rebuild_milestone_choices()
	if _career_sponsorship_ui != null:
		var sponsorship_value: Variant = _snapshot.get("career_sponsorship", {})
		_career_sponsorship_ui.apply_snapshot(
			sponsorship_value as Dictionary if sponsorship_value is Dictionary else {}
		)
	# Open every report at its causal summary. Keyboard users can then tab into
	# the milestone/action controls without the ScrollContainer hiding the score.
	_queue_focus(_report_panel)
	call_deferred("_reset_report_scroll")


func _update_score_receipt(report_day: int) -> void:
	var receipt_value: Variant = _snapshot.get("score_receipt", {})
	var receipt := receipt_value as Dictionary if receipt_value is Dictionary else {}
	var valid := not receipt.is_empty() and int(receipt.get("shift_number", 0)) == report_day
	if not valid:
		_report_shift_delta_label.text = "--"
		_report_shift_delta_label.add_theme_color_override("font_color", MUTED)
		_report_shift_delta_label.tooltip_text = "No shift score receipt is available."
		_report_heading_note.text = String(_snapshot.get(
			"report_note",
			"Career results and quarterly safeguards remain on the permanent coop record."
			if _is_senior_snapshot() else
			"Cumulative results follow you through all five shifts.",
		))
		_report_heading_note.add_theme_font_size_override("font_size", 13)
		_report_heading_note.tooltip_text = _report_heading_note.text
		_metric_panel(_report_shift_delta_label).add_theme_stylebox_override(
			"panel",
			_panel_style(Color("1d3039"), Color("53656d"), 8, 1),
		)
		return
	var score_before := int(receipt.get("score_before", 0))
	var score_after := int(receipt.get("score_after", score_before))
	var score_delta := int(receipt.get("score_delta", score_after - score_before))
	_report_shift_delta_label.text = _format_signed_delta(score_delta)
	var delta_color := TEAL if score_delta > 0 else (RUST if score_delta < 0 else MUTED)
	_report_shift_delta_label.add_theme_color_override("font_color", delta_color)
	var raw_components: Variant = receipt.get("components", [])
	var components: Array = raw_components as Array if raw_components is Array else []
	var compact_parts: Array[String] = []
	var detail_lines: Array[String] = [
		"SHIFT %d SCORE RECEIPT" % report_day,
		"Score %d to %d (%s)" % [score_before, score_after, _format_signed_delta(score_delta)],
	]
	for component_value: Variant in components:
		if not component_value is Dictionary:
			continue
		var component := component_value as Dictionary
		var component_delta := int(component.get("delta", 0))
		var short_label := _receipt_component_short_label(StringName(component.get("id", &"")))
		compact_parts.append("%s %s" % [short_label, _format_signed_delta(component_delta)])
		detail_lines.append("%s  %s  //  %s" % [
			String(component.get("label", short_label)),
			_format_signed_delta(component_delta),
			String(component.get("detail", "Filed in the permanent career ledger.")),
		])
	_report_heading_note.add_theme_font_size_override("font_size", 11)
	_report_heading_note.text = "RECEIPT  %d -> %d  //  %s" % [
		score_before,
		score_after,
		"  /  ".join(compact_parts),
	]
	_report_heading_note.tooltip_text = "\n".join(detail_lines)
	_report_shift_delta_label.tooltip_text = _report_heading_note.tooltip_text
	_report_shift_delta_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_metric_panel(_report_shift_delta_label).add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), delta_color.darkened(0.12), 8, 1),
	)


func _update_credit_memo(report_day: int) -> void:
	var memo_value: Variant = _snapshot.get("credit_memo", {})
	var memo := memo_value as Dictionary if memo_value is Dictionary else {}
	var visible := not memo.is_empty() and int(memo.get("day", 0)) == report_day
	_credit_memo_card.visible = visible
	if not visible:
		_sync_report_story_visibility()
		return
	var option_name := String(memo.get("option_id", "credit_filed")).replace("_", " ").to_upper()
	var subject_name := String(memo.get("worker_name", "")).to_upper()
	var decision_id := StringName(String(memo.get("decision_id", "")))
	var prefix := "CREDIT FILED"
	if decision_id == &"flock_restructuring":
		prefix = "FLOCK RESTRUCTURING FILED"
	elif decision_id == &"golden_egg_dossier":
		prefix = "GOLDEN DOSSIER FILED"
	elif decision_id == &"senior_quarter_policy":
		prefix = "SENIOR CAPITAL POLICY FILED"
	_credit_memo_label.text = "%s  //  %s%s\n%s" % [
		prefix,
		option_name,
		("  //  %s" % subject_name if not subject_name.is_empty() else ""),
		String(memo.get("outcome", "The closing attribution is now part of the permanent coop record.")),
	]
	_credit_memo_label.tooltip_text = _credit_memo_label.text
	_sync_report_story_visibility()


func _update_hen_highlight(report_day: int) -> void:
	var highlight_value: Variant = _snapshot.get("hen_highlight", {})
	var highlight := highlight_value as Dictionary if highlight_value is Dictionary else {}
	var visible := not highlight.is_empty() and int(highlight.get("day", 0)) == report_day
	_hen_highlight_card.visible = visible
	if not visible:
		_sync_report_story_visibility()
		return
	var worker_name := String(highlight.get("worker_name", "CLAIMS HEN")).to_upper()
	var career_title := String(highlight.get("career_title", "CLAIMS HEN")).to_upper()
	var relationship := String(highlight.get("relationship_label", "UNFILED")).to_upper()
	var body := String(highlight.get("body", "The flock closed another shift."))
	var metric := String(highlight.get("metric", "%d EGGS" % int(highlight.get("eggs", 0))))
	_hen_highlight_eyebrow.text = "HEN FILE  //  %s  //  %s" % [worker_name, relationship]
	_hen_highlight_headline.text = String(highlight.get("headline", "SHIFT HIGHLIGHT")).to_upper()
	_hen_highlight_body.text = body
	_hen_highlight_metric.text = metric
	var tooltip := "%s  //  %s  //  %s\n%s\n%s" % [
		worker_name,
		career_title,
		relationship,
		body,
		metric,
	]
	_hen_highlight_body.tooltip_text = tooltip
	_hen_highlight_card.tooltip_text = tooltip
	var accent := _highlight_tone_color(StringName(highlight.get("tone", &"quality")))
	_hen_highlight_eyebrow.add_theme_color_override("font_color", accent)
	_hen_highlight_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("20333a"), accent.darkened(0.1), 8, 1),
	)
	_sync_report_story_visibility()


func _sync_report_story_visibility() -> void:
	if _report_story_row == null or _credit_memo_card == null or _hen_highlight_card == null:
		return
	_report_story_row.visible = _credit_memo_card.visible or _hen_highlight_card.visible


func _receipt_component_short_label(component_id: StringName) -> String:
	match component_id:
		&"probation_orders":
			return "ORDERS"
		&"daily_clutch":
			return "CLUTCH"
		&"shell_quality":
			return "SHELLS"
		&"queue_control":
			return "QUEUES"
		&"flock_safeguards":
			return "FLOCK"
		&"score_cap":
			return "CAP"
		&"milestone_bonus":
			return "SPECIALTY"
	return String(component_id).replace("_", " ").to_upper()


func _format_signed_delta(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)


func _refresh_probation_safeguard_receipt(
	panel: PanelContainer,
	summary: Label,
	rows: Array[Label],
	final_receipt: bool,
) -> void:
	if panel == null or summary == null:
		return
	# Presentation snapshots intentionally merge across sequential career views.
	# A Senior filing must never inherit the completed probation receipt left in
	# that shared UI state, even if an older caller omitted the key entirely.
	if _is_senior_snapshot():
		panel.visible = false
		return
	var forecast_value: Variant = _snapshot.get("probation_safeguard_forecast", {})
	var forecast := forecast_value as Dictionary if forecast_value is Dictionary else {}
	var criteria_value: Variant = forecast.get("criteria", [])
	var criteria := criteria_value as Array if criteria_value is Array else []
	panel.visible = not criteria.is_empty()
	if criteria.is_empty():
		return
	var pass_count := clampi(int(forecast.get("pass_count", 0)), 0, criteria.size())
	var all_pass := bool(forecast.get("all_pass", false))
	var summary_prefix := "FINAL RESULT" if final_receipt else "CURRENT FORECAST"
	var active_contract := _active_challenge_contract()
	var contract_label := _challenge_contract_label(active_contract, false)
	var summary_status := (
		"ALL SAFEGUARDS PASS"
		if all_pass else
		("FILE HELD" if final_receipt else "ACTION REQUIRED")
	)
	var shift_progress := "" if final_receipt else "  //  %d / %d SHIFTS FILED" % [
		maxi(0, int(forecast.get("completed_shifts", 0))),
		maxi(1, int(forecast.get("required_shifts", DEFAULT_TOTAL_DAYS))),
	]
	summary.text = "%s  //  %s  //  %d / %d SAFEGUARDS%s  //  %s" % [
		summary_prefix,
		contract_label,
		pass_count,
		criteria.size(),
		shift_progress,
		summary_status,
	]
	summary.add_theme_color_override("font_color", TEAL if all_pass else RUST)
	var tooltip_lines: Array[String] = [
		summary.text,
		_challenge_contract_terms_text(active_contract, false),
	]
	for index: int in range(rows.size()):
		var label := rows[index]
		if label == null:
			continue
		label.visible = index < criteria.size()
		if not label.visible:
			continue
		var criterion_value: Variant = criteria[index]
		if not criterion_value is Dictionary:
			label.text = "HELD  //  INVALID SAFEGUARD ROW"
			label.add_theme_color_override("font_color", RUST)
			continue
		var criterion := criterion_value as Dictionary
		label.text = _probation_safeguard_row_text(criterion, final_receipt)
		label.add_theme_color_override(
			"font_color",
			Color("a7dbc9") if bool(criterion.get("pass", false)) else Color("f0aa95"),
		)
		tooltip_lines.append(label.text)
	var blocker := forecast.get("largest_recoverable_blocker", {}) as Dictionary
	if not blocker.is_empty() and not final_receipt:
		var blocker_line := "LARGEST RECOVERABLE GAP  //  %s  //  %s" % [
			String(blocker.get("label", "SAFEGUARD")).to_upper(),
			_probation_safeguard_gap_text(blocker),
		]
		summary.text += "\n" + blocker_line
		tooltip_lines.append(blocker_line)
	panel.tooltip_text = "\n".join(tooltip_lines)


func _probation_safeguard_row_text(criterion: Dictionary, final_receipt: bool) -> String:
	var passed := bool(criterion.get("pass", false))
	var status := "PASS" if passed else ("HELD" if final_receipt else "AT RISK")
	var comparison := String(criterion.get("comparison", "minimum"))
	var metric := String(criterion.get("metric", ""))
	return "%s  //  %s  //  %s %s %s  //  %s" % [
		status,
		String(criterion.get("label", "SAFEGUARD")).to_upper(),
		_probation_safeguard_value_text(metric, int(criterion.get("projected_value", 0))),
		">=" if comparison == "minimum" else "<=",
		_probation_safeguard_value_text(metric, int(criterion.get("target", 0))),
		_probation_safeguard_gap_text(criterion),
	]


func _probation_safeguard_value_text(metric: String, value: int) -> String:
	if metric == "crack_rate_basis_points":
		return "%.2f%%" % (float(value) / 100.0)
	return str(value)


func _probation_safeguard_gap_text(criterion: Dictionary) -> String:
	var metric := String(criterion.get("metric", ""))
	var gap := int(criterion.get("signed_gap", 0))
	if metric == "crack_rate_basis_points":
		return "%s%.2f PTS" % ["+" if gap > 0 else "", float(gap) / 100.0]
	return "%s%d POINT%s" % [
		"+" if gap > 0 else "",
		gap,
		"" if absi(gap) == 1 else "S",
	]


func _highlight_tone_color(tone: StringName) -> Color:
	match tone:
		&"danger":
			return RUST
		&"gold":
			return BRASS
		&"care":
			return Color("d99472")
		&"neutral":
			return Color("8e9aa2")
	return TEAL


func _reset_report_scroll() -> void:
	if _modal_scroll != null and _view == VIEW_REPORT:
		_modal_scroll.scroll_vertical = 0


func _refresh_final() -> void:
	var passed := _campaign_passed()
	var ending_value: Variant = _snapshot.get("ending", {})
	var ending := ending_value as Dictionary if ending_value is Dictionary else {}
	var accent := TEAL if passed else RUST
	_final_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(NAVY, accent, 15, 3),
	)
	_final_verdict_label.text = String(ending.get(
		"title",
		"PROBATION PASSED" if passed else "PROBATION FAILED",
	)).to_upper()
	_final_verdict_label.add_theme_color_override("font_color", Color("b9e6d7") if passed else Color("f0aa95"))
	_final_message_label.text = String(_snapshot.get(
		"final_message",
		(
			"Your rooster badge has been approved. The senior roost expects even larger clutches."
			if passed else
			"The farmer has reclaimed the badge. Your file may be reopened for another five-shift probation."
		),
	))
	_final_score_label.text = _format_integer(int(_snapshot.get("score", 0)))
	var final_rank := String(_snapshot.get("rank", "UNRANKED")).strip_edges().to_upper()
	if passed and final_rank == "PROBATIONARY MANAGER":
		# Supported Flock can legitimately pass below the score-only Trusted Layer
		# band. The closing receipt must describe that successful outcome instead of
		# contradicting the approved rooster badge with a probationary title.
		final_rank = "QUALIFIED ROOSTER"
	_final_rank_label.text = final_rank
	_update_ledger_labels(_final_ledger_labels)
	_refresh_probation_safeguard_receipt(
		_final_safeguard_panel,
		_final_safeguard_summary,
		_final_safeguard_rows,
		true,
	)
	_final_continue_button.visible = passed
	_final_new_button.text = "NEW CAMPAIGN  [N]" if passed else "RETRY PROBATION  [N]"
	_final_sticky_primary_button.text = (
		"ENTER THE SENIOR ROOST  [C]" if passed else "RETRY PROBATION  [N]"
	)
	_final_sticky_primary_button.shortcut = _shortcut(KEY_C if passed else KEY_N)
	_final_sticky_primary_button.tooltip_text = (
		"Continue this approved file into the uncapped Senior Roost."
		if passed else
		"Open a replacement confirmation before starting a fresh five-shift probation file."
	)
	_queue_focus(
		_final_sticky_primary_button
		if _final_sticky_action_bar.is_visible_in_tree() else
		(_final_continue_button if passed else _final_new_button)
	)


func _update_objective() -> void:
	var objective_value: Variant = _snapshot.get(
		"next_objective",
		_snapshot.get("objective", {}),
	)
	var objective := objective_value as Dictionary if objective_value is Dictionary else {}
	var title := String(objective.get("title", objective.get("label", "AWAITING QUOTA NOTICE")))
	var description := String(objective.get(
		"description",
		objective.get("detail", "The farmer has not filed the next clutch target."),
	))
	_objective_title_label.text = "%s  //  %s" % [
		String(_snapshot.get(
			"objective_section_title",
			"QUARTER OBJECTIVE" if _is_senior_snapshot() else "NEXT SHIFT OBJECTIVE",
		)).to_upper(),
		title.to_upper(),
	]
	_objective_body_label.text = description
	if objective.has("progress") or objective.has("target"):
		_objective_progress_label.text = "PROGRESS CARRIED FORWARD  %s / %s" % [
			str(objective.get("progress", 0)),
			str(objective.get("target", "—")),
		]
	else:
		_objective_progress_label.text = String(objective.get("reward", ""))


func _rebuild_milestone_choices() -> void:
	for child: Node in _milestone_buttons_host.get_children():
		_milestone_buttons_host.remove_child(child)
		child.queue_free()
	_milestone_buttons.clear()
	var raw_choices: Variant = _snapshot.get(
		"milestone_choices",
		_snapshot.get("milestones", []),
	)
	var choices: Array = raw_choices as Array if raw_choices is Array else []
	_milestone_hint_label.text = String(_snapshot.get(
		"choice_hint",
		"Select one capital policy before opening the quarter."
		if _is_senior_snapshot() else
		"Select one card before filing the next-shift plan.",
	))
	_milestone_section.visible = not choices.is_empty()
	if choices.is_empty():
		_pending_milestone_confirmation = &""
		_report_continue_button.disabled = false
		_report_continue_button.tooltip_text = String(_snapshot.get(
			"continue_tooltip",
			"Acknowledge this career review and continue."
			if _is_senior_snapshot() else
			"File this report and begin next-shift planning.",
		))
		_queue_focus(_report_continue_button)
		return

	var index := 0
	for choice_value: Variant in choices:
		if index >= 3 or not choice_value is Dictionary:
			break
		var choice := choice_value as Dictionary
		var choice_id := StringName(choice.get("id", "milestone_%d" % index))
		var title := String(choice.get("title", choice.get("label", "MILESTONE")))
		var description := String(choice.get("description", choice.get("detail", "Permanent campaign benefit.")))
		var effect := String(choice.get("effect", choice.get("preview", "")))
		var doctrine := choice.get("doctrine", {}) as Dictionary
		var doctrine_label := String(doctrine.get("label", "")).strip_edges().to_upper()
		var strengths := _doctrine_terms(doctrine.get("strengths", []))
		var watchouts := _doctrine_terms(doctrine.get("watchouts", []))
		var primary_strength := _doctrine_primary_term(doctrine.get("strengths", []))
		var primary_watchout := _doctrine_primary_term(doctrine.get("watchouts", []))
		var strategy := choice.get("strategy", {}) as Dictionary
		var available := bool(choice.get("available", true))
		var locked_by_filed_choice := (
			_selected_milestone != &""
			and choice_id != _selected_milestone
		)
		var button_copy := "%d  //  %s\n%s%s" % [
			index + 1,
			title.to_upper(),
			description,
			("\n%s" % effect if not effect.is_empty() else ""),
		]
		if not doctrine.is_empty():
			button_copy = "%d  //  %s\n%s%s\nEDGE %s  //  WATCH %s" % [
				index + 1,
				doctrine_label,
				title.to_upper(),
				("  //  %s" % effect if not effect.is_empty() else ""),
				primary_strength,
				primary_watchout,
			]
		elif not strategy.is_empty():
			button_copy = "%d  //  %s\n%s\nSCORE  //  EDGE %s  /  WATCH %s\nBOARD  //  %s" % [
				index + 1,
				title.to_upper(),
				effect,
				String(strategy.get("score_edge", "QUARTER TRADEOFF")),
				String(strategy.get("score_watch", "CLOSING LEDGER")),
				String(strategy.get("board_fit", "FILE THE ANNUAL BOARD MANDATE FIRST")),
			]
			var prior_year_fit := strategy.get("prior_year_fit", {}) as Dictionary
			if bool(prior_year_fit.get("visible", false)):
				button_copy += "\nLAST YEAR  //  %s  /  %s" % [
					String(prior_year_fit.get("fit_label", "NO DIRECT EDGE")),
					String(prior_year_fit.get("focus_detail", "ANNUAL SAFEGUARD")),
				]
		var button := _make_button(
			"MilestoneChoice_%s" % _safe_node_suffix(String(choice_id)),
			button_copy,
			&"DecisionChoiceButton",
		)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(
			0.0,
			146.0 if not strategy.is_empty() else (108.0 if not doctrine.is_empty() else 88.0),
		)
		if not strategy.is_empty():
			button.add_theme_font_size_override("font_size", 12)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.shortcut = _shortcut([KEY_1, KEY_2, KEY_3][index])
		# A selected milestone in the incoming snapshot is authoritative. Keep
		# its card readable, but lock every alternative so a later click cannot
		# visually replace the permanent filing while the domain rejects it.
		button.disabled = not available or locked_by_filed_choice
		var default_tooltip := String(choice.get(
			"tooltip",
			choice.get(
				"unavailable_reason",
				"File %s as this quarter's capital policy." % title
				if _is_senior_snapshot() else
				"Choose %s as the permanent probation milestone." % title,
			),
		))
		if not doctrine.is_empty():
			default_tooltip = "%s\n\n%s\n%s\n\nFULL EDGE  //  %s\nWATCH  //  %s\n\nPLAYBOOK  //  %s" % [
				default_tooltip,
				description,
				String(doctrine.get("summary", "This doctrine remains permanent for probation.")),
				strengths,
				watchouts,
				String(doctrine.get("playbook", "Use the safeguard forecast to cover its obligations.")),
			]
		elif not strategy.is_empty():
			default_tooltip = "%s\n\n%s\n%s\n\nSCORE EDGE  //  %s\nSCORE WATCH  //  %s\n%s  //  %s" % [
				default_tooltip,
				description,
				effect,
				String(strategy.get("score_edge", "QUARTER TRADEOFF")),
				String(strategy.get("score_watch", "CLOSING LEDGER")),
				String(strategy.get("board_name", "ANNUAL BOARD MANDATE")).to_upper(),
				String(strategy.get("board_fit", "FILE THE ANNUAL BOARD MANDATE FIRST")),
			]
			var prior_year_fit := strategy.get("prior_year_fit", {}) as Dictionary
			if bool(prior_year_fit.get("visible", false)):
				default_tooltip += "\n\nLAST YEAR  //  %s  //  %s\n%s" % [
					String(prior_year_fit.get("fit_label", "NO DIRECT EDGE")),
					String(prior_year_fit.get("focus_detail", "ANNUAL SAFEGUARD")),
					String(prior_year_fit.get("fit_detail", "Use the annual receipt to cover this safeguard.")),
				]
		if locked_by_filed_choice:
			default_tooltip = "LOCKED  //  %s is already the permanent filing for this review." % (
				String(_selected_milestone).replace("_", " ").to_upper()
			)
		button.tooltip_text = default_tooltip
		button.set_meta("choice_id", choice_id)
		button.set_meta(
			"choice_title",
			"%s  //  %s" % [doctrine_label, title.to_upper()]
			if not doctrine_label.is_empty() else
			title.to_upper(),
		)
		button.set_meta("doctrine_id", String(choice_id) if not doctrine.is_empty() else "")
		button.set_meta("confirmation_required", bool(choice.get("confirmation_required", false)))
		button.set_meta("confirmation_label", String(choice.get(
			"confirmation_label",
			"CONFIRM PERMANENT FILING  [C]",
		)))
		button.set_meta("confirmation_tooltip", String(choice.get(
			"confirmation_tooltip",
			"Confirm this irreversible filing.",
		)))
		button.set_meta("confirmation_stake_marks", maxi(0, int(choice.get("stake_marks", 0))))
		button.pressed.connect(_on_milestone_pressed.bind(choice_id))
		_milestone_buttons_host.add_child(button)
		_milestone_buttons[choice_id] = button
		index += 1
	if (
		_selected_milestone != &""
		and (
			not _milestone_buttons.has(_selected_milestone)
			or (_milestone_buttons[_selected_milestone] as Button).disabled
		)
	):
		_selected_milestone = &""
		_snapshot.erase("selected_milestone")
	if (
		_pending_milestone_confirmation != &""
		and not _milestone_buttons.has(_pending_milestone_confirmation)
	):
		_pending_milestone_confirmation = &""
	_update_milestone_selection()
	var needs_choice := (
		bool(_snapshot.get("choice_required", true))
		and (
			_selected_milestone == &""
			or not _milestone_buttons.has(_selected_milestone)
			or (_milestone_buttons[_selected_milestone] as Button).disabled
		)
	)
	_report_continue_button.disabled = needs_choice
	_report_continue_button.tooltip_text = (
		String(_snapshot.get(
			"choice_required_tooltip",
			"Choose one available capital policy before continuing."
			if _is_senior_snapshot() else
			"Choose one milestone card before continuing.",
		))
		if needs_choice else
		String(_snapshot.get("continue_tooltip", "File this report with the selected choice."))
	)
	_apply_pending_milestone_confirmation()
	_apply_responsive_layout()
	if needs_choice:
		var first_available: Button = null
		for button_value: Variant in _milestone_buttons.values():
			var candidate := button_value as Button
			if candidate != null and not candidate.disabled:
				first_available = candidate
				break
		_queue_focus(first_available if first_available != null else _report_panel)
	else:
		_queue_focus(_report_continue_button)


func _doctrine_terms(value: Variant) -> String:
	if not value is Array:
		return ""
	var terms: Array[String] = []
	for item: Variant in value as Array:
		var term := String(item).strip_edges().to_upper()
		if not term.is_empty():
			terms.append(term)
	return " // ".join(terms)


func _doctrine_primary_term(value: Variant) -> String:
	if not value is Array or (value as Array).is_empty():
		return "UNLISTED"
	return String((value as Array)[0]).strip_edges().to_upper()


func _update_milestone_selection() -> void:
	for choice_id: StringName in _milestone_buttons:
		var button := _milestone_buttons[choice_id]
		button.theme_type_variation = (
			&"SelectedChoiceButton"
			if choice_id == _selected_milestone else
			&"DecisionChoiceButton"
		)
	_milestone_hint_label.text = (
		_pending_milestone_confirmation_hint()
		if _pending_milestone_confirmation != &"" else
		"SELECTED  //  %s" % String(
			(_milestone_buttons[_selected_milestone] as Button).get_meta(
				"choice_title",
				String(_selected_milestone).replace("_", " ").to_upper(),
			)
		)
		if _selected_milestone != &"" else
		String(_snapshot.get(
			"choice_hint",
			"Select one capital policy before opening the quarter."
			if _is_senior_snapshot() else
			"Select one card before filing the next-shift plan.",
		))
	)


func _apply_pending_milestone_confirmation() -> void:
	if (
		_pending_milestone_confirmation == &""
		or not _milestone_buttons.has(_pending_milestone_confirmation)
	):
		return
	var button := _milestone_buttons[_pending_milestone_confirmation] as Button
	if button == null or button.disabled:
		return
	_report_continue_button.text = String(button.get_meta(
		"confirmation_label",
		"CONFIRM PERMANENT FILING  [C]",
	))
	_report_continue_button.tooltip_text = String(button.get_meta(
		"confirmation_tooltip",
		"Confirm this irreversible filing.",
	))
	_report_continue_button.disabled = false
	_queue_focus(_report_continue_button)


func _pending_milestone_confirmation_hint() -> String:
	if not _milestone_buttons.has(_pending_milestone_confirmation):
		return ""
	var button := _milestone_buttons[_pending_milestone_confirmation] as Button
	if button == null:
		return ""
	var title := String(button.get_meta(
		"choice_title",
		String(_pending_milestone_confirmation).replace("_", " ").to_upper(),
	))
	var stake := maxi(0, int(button.get_meta("confirmation_stake_marks", 0)))
	return "REVIEWED  //  %s  //  PRESS C TO CONFIRM %d-MARK STAKE" % [title, stake]


func _pending_milestone_confirmation_snapshot() -> Dictionary:
	if not _milestone_buttons.has(_pending_milestone_confirmation):
		return {}
	var button := _milestone_buttons[_pending_milestone_confirmation] as Button
	if button == null or button.disabled:
		return {}
	return {
		"id": String(_pending_milestone_confirmation),
		"title": String(button.get_meta(
			"choice_title",
			String(_pending_milestone_confirmation).replace("_", " ").to_upper(),
		)),
		"stake_marks": maxi(0, int(button.get_meta("confirmation_stake_marks", 0))),
		"confirmation_label": String(button.get_meta("confirmation_label", "")),
		"confirmation_tooltip": String(button.get_meta("confirmation_tooltip", "")),
	}


func _update_ledger_labels(targets: Array[Dictionary]) -> void:
	var ledgers := _normalized_ledgers()
	for index: int in range(3):
		var target: Dictionary = targets[index]
		var ledger: Dictionary = ledgers[index]
		var title_label := target["title"] as Label
		var value_label := target["value"] as Label
		var detail_label := target["detail"] as Label
		title_label.text = String(ledger.get("label", "LEDGER %d" % (index + 1))).to_upper()
		value_label.text = _ledger_display_value(ledger)
		detail_label.text = String(ledger.get("detail", "CUMULATIVE"))
		detail_label.tooltip_text = detail_label.text


func _normalized_ledgers() -> Array[Dictionary]:
	var defaults: Array[Dictionary] = [
		{"label": "EGGS FILED", "value": 0, "detail": "CUMULATIVE"},
		{"label": "FEED FUND", "value": 0, "format": "currency_cents", "detail": "BANKED"},
		{"label": "SHELL INTEGRITY", "value": 100, "format": "percent", "detail": "CAMPAIGN QUALITY"},
	]
	var source: Variant = _snapshot.get(
		"ledgers",
		_snapshot.get("cumulative_ledgers", []),
	)
	if source is Array:
		var source_array := source as Array
		for index: int in range(mini(3, source_array.size())):
			if source_array[index] is Dictionary:
				for key: Variant in source_array[index]:
					defaults[index][key] = source_array[index][key]
			else:
				defaults[index]["value"] = source_array[index]
	elif source is Dictionary:
		var source_dict := source as Dictionary
		var known: Array[Dictionary] = [
			{"keys": ["eggs_total", "eggs", "eggs_filed"], "label": "EGGS FILED"},
			{"keys": ["feed_fund_cents", "fund_cents", "revenue_cents"], "label": "FEED FUND", "format": "currency_cents"},
			{"keys": ["shell_integrity", "quality_percent", "quality"], "label": "SHELL INTEGRITY", "format": "percent"},
		]
		for index: int in range(3):
			var descriptor: Dictionary = known[index]
			for key: String in descriptor["keys"]:
				if source_dict.has(key):
					defaults[index]["value"] = source_dict[key]
					defaults[index]["label"] = descriptor["label"]
					if descriptor.has("format"):
						defaults[index]["format"] = descriptor["format"]
					break
	return defaults


func _ledger_display_value(ledger: Dictionary) -> String:
	if ledger.has("display"):
		return String(ledger["display"])
	var value: Variant = ledger.get("value", ledger.get("value_cents", 0))
	match String(ledger.get("format", "number")):
		"currency", "currency_cents":
			return "$%.2f" % (float(value) / 100.0)
		"percent":
			return "%d%%" % int(value)
	return _format_integer(int(value)) if value is int or value is float else String(value)


func _campaign_passed() -> bool:
	if _snapshot.has("passed"):
		return bool(_snapshot["passed"])
	return String(_snapshot.get("result", "fail")).to_lower() in ["pass", "passed", "success"]


func _read_view(snapshot: Dictionary) -> StringName:
	if bool(snapshot.get("first_load", false)):
		return VIEW_TITLE
	if bool(snapshot.get("final", false)):
		return VIEW_FINAL
	if bool(snapshot.get("between_shifts", false)):
		return VIEW_REPORT
	var raw := String(snapshot.get(
		"view",
		snapshot.get("campaign_view", snapshot.get("screen", VIEW_ACTIVE)),
	)).to_lower()
	match raw:
		"title", "first_load", "new_game":
			return VIEW_TITLE
		"between_shift", "between_shifts", "report", "shift_report":
			return VIEW_REPORT
		"contract_board", "farm_mutual", "market_contract":
			return VIEW_CONTRACT_BOARD
		"final", "complete", "campaign_review":
			return VIEW_FINAL
	return VIEW_ACTIVE


func _apply_responsive_layout() -> void:
	if _modal_scroll == null or _modal_center == null:
		return
	var viewport_size := size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = get_viewport_rect().size
	# Leave a narrow gutter for the vertical scrollbar when portrait content
	# wraps into several rows; otherwise a full-width panel loses its right edge.
	var panel_width := maxf(286.0, viewport_size.x - 52.0)
	var modal_height := maxf(240.0, viewport_size.y - 84.0)
	var narrow := viewport_size.x < 720.0
	var compact := viewport_size.x < 1100.0
	var sticky_final_actions := _view == VIEW_FINAL and not narrow
	if _final_sticky_action_bar != null:
		_final_sticky_action_bar.visible = sticky_final_actions
	_modal_scroll.offset_bottom = -92.0 if sticky_final_actions else -18.0
	if _report_safeguard_grid != null:
		_report_safeguard_grid.columns = 1 if narrow else 2
	if _final_safeguard_grid != null:
		_final_safeguard_grid.columns = 1 if narrow else 2

	_modal_center.custom_minimum_size = Vector2(panel_width, modal_height)
	_title_panel.custom_minimum_size = Vector2(minf(760.0, panel_width), 0.0)
	_report_panel.custom_minimum_size = Vector2(minf(1040.0, panel_width), 0.0)
	_final_panel.custom_minimum_size = Vector2(minf(860.0, panel_width), 0.0)
	if _replacement_confirmation_panel != null:
		_replacement_confirmation_panel.custom_minimum_size = Vector2(minf(560.0, panel_width), 0.0)
	if _title_challenge_selector != null:
		_title_challenge_selector.custom_minimum_size.x = 220.0 if narrow else 250.0
	_report_heading_stack.custom_minimum_size.x = 0.0 if compact else 390.0

	var report_score_panel := _metric_panel(_report_score_label)
	var report_shift_panel := _metric_panel(_report_shift_delta_label)
	var report_rank_panel := _metric_panel(_report_rank_label)
	var final_score_panel := _metric_panel(_final_score_label)
	var final_rank_panel := _metric_panel(_final_rank_label)
	report_score_panel.custom_minimum_size.x = 132.0
	report_shift_panel.custom_minimum_size.x = 126.0
	report_rank_panel.custom_minimum_size.x = 260.0 if narrow else 236.0
	final_score_panel.custom_minimum_size.x = 190.0
	final_rank_panel.custom_minimum_size.x = 260.0 if narrow else 276.0

	var ledger_width := 260.0 if narrow else 220.0
	for row in [_report_ledger_row, _final_ledger_row]:
		if row == null:
			continue
		for child in row.get_children():
			if child is PanelContainer:
				(child as PanelContainer).custom_minimum_size.x = ledger_width

	if _credit_memo_card != null:
		_credit_memo_card.custom_minimum_size.x = 260.0 if narrow else 600.0
	if _hen_highlight_card != null:
		_hen_highlight_card.custom_minimum_size.x = 260.0 if narrow else 320.0

	var milestone_width := 260.0 if narrow else 285.0
	for button_value in _milestone_buttons.values():
		var milestone_button := button_value as Button
		if milestone_button != null:
			milestone_button.custom_minimum_size.x = milestone_width

	if _report_continue_button != null:
		_report_continue_button.custom_minimum_size.x = 270.0 if narrow else 310.0
	if _final_continue_button != null:
		_final_continue_button.custom_minimum_size.x = 260.0

	_position_badge(_view != VIEW_ACTIVE)


func _position_badge(modal_open: bool) -> void:
	var available_width := size.x if size.x > 1.0 else get_viewport_rect().size.x
	if modal_open or available_width < 720.0:
		# Senior reports pair a full career-mode label with year/quarter context.
		# Give both labels enough room instead of ellipsizing the mode at 1280x720.
		_day_badge.offset_left = -318.0
		_day_badge.offset_top = 14.0
		_day_badge.offset_right = -18.0
		_day_badge.offset_bottom = 58.0
	else:
		# This slot sits between the routing strip and Flockwatch button in the
		# 1280x720 office HUD, so the badge never covers hens or workstations.
		_day_badge.offset_left = -490.0
		_day_badge.offset_top = _active_badge_top
		_day_badge.offset_right = -268.0
		_day_badge.offset_bottom = _active_badge_top + 44.0


func _on_final_sticky_primary_pressed() -> void:
	if _campaign_passed():
		_on_continue_campaign_pressed()
	else:
		_on_new_campaign_pressed()


func _on_milestone_pressed(choice_id: StringName) -> void:
	if not _milestone_buttons.has(choice_id):
		return
	var pressed_button := _milestone_buttons[choice_id] as Button
	if pressed_button == null or pressed_button.disabled:
		return
	_selected_milestone = choice_id
	_snapshot["selected_milestone"] = choice_id
	if bool(pressed_button.get_meta("confirmation_required", false)):
		# Permanent-risk Board Books are inspected first and filed only through
		# the existing report action. A stray click or number-key press can never
		# reserve career marks by itself.
		_pending_milestone_confirmation = choice_id
		_update_milestone_selection()
		_apply_pending_milestone_confirmation()
		# This review state exists only in the presentation layer while the
		# simulation is paused. Let Office refresh its Web/accessibility mirror so
		# automation and assistive surfaces see the same uncommitted stake as the
		# player without mutating the authoritative Senior ledger.
		presentation_state_changed.emit()
		return
	_pending_milestone_confirmation = &""
	_update_milestone_selection()
	_report_continue_button.disabled = false
	_report_continue_button.tooltip_text = String(_snapshot.get(
		"continue_tooltip",
		"File this report with the selected choice.",
	))
	milestone_choice.emit(choice_id)


func _is_senior_snapshot() -> bool:
	return (
		String(_snapshot.get("status", "")).strip_edges().to_upper() == "SENIOR ROOST"
		or String(_snapshot.get("career_mode", "")).to_lower() == "senior_roost"
	)


func _on_continue_campaign_pressed() -> void:
	if (
		_pending_milestone_confirmation != &""
		and _milestone_buttons.has(_pending_milestone_confirmation)
	):
		var choice_id := _pending_milestone_confirmation
		var button := _milestone_buttons[choice_id] as Button
		if button != null and not button.disabled:
			_pending_milestone_confirmation = &""
			milestone_choice.emit(choice_id)
			return
	continue_campaign.emit()


func _on_market_contract_sign_requested(offer_id: StringName, clause_id: StringName) -> void:
	market_contract_sign_requested.emit(offer_id, clause_id)


func _on_market_contract_decline_requested() -> void:
	market_contract_decline_requested.emit()


func _on_new_campaign_pressed() -> void:
	if _view == VIEW_TITLE and _snapshot_continue_available() and not _title_new_file_setup:
		_title_new_file_setup = true
		_title_contract_terms_expanded = false
		_refresh_title()
		title_intake_phase_changed.emit(title_intake_phase())
		return
	if _campaign_replacement_requires_confirmation():
		_show_campaign_replacement_confirmation()
		return
	new_campaign.emit()


func _on_abandon_campaign_pressed() -> void:
	abandon_campaign.emit()


func _campaign_replacement_requires_confirmation() -> bool:
	if _view == VIEW_FINAL:
		return true
	return (
		_view == VIEW_TITLE
		and bool(_snapshot.get("continue_available", _snapshot.get("has_continue", false)))
	)


func _show_campaign_replacement_confirmation() -> void:
	if _replacement_confirmation_host == null:
		return
	_replacement_confirmation_origin = (
		_final_new_button
		if _view == VIEW_FINAL else
		find_child("NewCampaignButton", true, false) as Control
	)
	var resume_value: Variant = _snapshot.get("resume_summary", {})
	var resume_summary := resume_value as Dictionary if resume_value is Dictionary else {}
	var current_file := _format_resume_summary(resume_summary)
	if _view == VIEW_FINAL and resume_summary.is_empty():
		current_file = "DAY 5 / 5  //  SCORE %d  //  %s" % [
			clampi(int(_snapshot.get("score", 0)), 0, PROBATION_SCORE_LIMIT),
			String(_snapshot.get("rank", "FILE CLOSED")).to_upper(),
		]
	var selected_contract := _selected_challenge_contract()
	var selected_contract_line := "NEW CHALLENGE CONTRACT  //  %s" % _challenge_contract_label(
		selected_contract,
		false,
	)
	_replacement_confirmation_body.text = (
		"Starting fresh replaces the resumable coop file shown below.\n\n%s\n\n%s\n\n"
		+ "The current file remains untouched until the new checkpoint has been written and verified. "
		+ "Choose Keep Current File to return without changing anything."
	) % [current_file, selected_contract_line]
	_replacement_confirmation_host.visible = true
	_queue_focus(_replacement_confirmation_cancel)


func _cancel_campaign_replacement() -> void:
	_hide_campaign_replacement(true)


func _confirm_campaign_replacement() -> void:
	_hide_campaign_replacement(false)
	new_campaign.emit()


func _hide_campaign_replacement(restore_focus: bool) -> void:
	if _replacement_confirmation_host == null or not _replacement_confirmation_host.visible:
		return
	_replacement_confirmation_host.visible = false
	if restore_focus and _replacement_confirmation_origin != null and is_instance_valid(_replacement_confirmation_origin):
		_queue_focus(_replacement_confirmation_origin)
	_replacement_confirmation_origin = null


func _queue_focus(control: Control) -> void:
	if control == null:
		return
	if control is BaseButton and (control as BaseButton).disabled:
		return
	control.call_deferred("grab_focus")


func _panel_content(
	panel: PanelContainer,
	horizontal_margin: int,
	vertical_margin: int,
	separation: int,
) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", horizontal_margin)
	margin.add_theme_constant_override("margin_right", horizontal_margin)
	margin.add_theme_constant_override("margin_top", vertical_margin)
	margin.add_theme_constant_override("margin_bottom", vertical_margin)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", separation)
	margin.add_child(content)
	return content


func _build_ledger_row(parent: VBoxContainer, prefix: String, targets: Array[Dictionary]) -> void:
	var row := HFlowContainer.new()
	row.name = "%sCumulativeLedgers" % prefix
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 8)
	parent.add_child(row)
	if prefix == "Report":
		_report_ledger_row = row
	else:
		_final_ledger_row = row
	for index: int in range(3):
		var card := PanelContainer.new()
		card.name = "%sCumulativeLedger%d" % [prefix, index + 1]
		card.custom_minimum_size = Vector2(220.0, 73.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override(
			"panel",
			_panel_style(NAVY_RAISED, Color("4a5d66"), 8, 1),
		)
		row.add_child(card)
		var stack := _panel_content(card, 13, 8, 0)
		var title_label := _make_label("LEDGER", 10, MUTED)
		title_label.name = "%sLedgerTitle%d" % [prefix, index + 1]
		stack.add_child(title_label)
		var value_label := _make_label("0", 19, CREAM)
		value_label.name = "%sLedgerValue%d" % [prefix, index + 1]
		stack.add_child(value_label)
		var detail_label := _make_label("CUMULATIVE", 9, Color("82939d"))
		detail_label.name = "%sLedgerDetail%d" % [prefix, index + 1]
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.max_lines_visible = 2
		detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		stack.add_child(detail_label)
		targets.append({
			"title": title_label,
			"value": value_label,
			"detail": detail_label,
		})


func _make_metric(
	label_name: String,
	value: String,
	caption: String,
	width: float = 150.0,
	value_font_size: int = 20,
	wrap_value: bool = false,
) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 68.0 if wrap_value else 60.0)
	panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d3039"), Color("53656d"), 8, 1),
	)
	var stack := _panel_content(panel, 13, 7, 0)
	var caption_label := _make_label(caption, 9, MUTED)
	caption_label.name = "%sCaption" % label_name
	stack.add_child(caption_label)
	var value_label := _make_label(value, value_font_size, CREAM)
	value_label.name = label_name
	if wrap_value:
		value_label.custom_minimum_size.y = 34.0
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		value_label.max_lines_visible = 2
		value_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	else:
		value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(value_label)
	return value_label


func _metric_panel(value_label: Label) -> PanelContainer:
	return value_label.get_parent().get_parent().get_parent() as PanelContainer


func _set_metric_caption(value_label: Label, caption: String) -> void:
	if value_label == null:
		return
	var caption_label := value_label.get_parent().get_node_or_null("%sCaption" % value_label.name) as Label
	if caption_label != null:
		caption_label.text = caption.to_upper()


func _section_label(text: String) -> Label:
	var label := _make_label(text, 11, Color("d0b269"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(node_name: String, text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_ALL
	return button


func _shortcut(keycode: Key) -> Shortcut:
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()
	event.keycode = keycode
	shortcut.events = [event]
	return shortcut


func _panel_style(color: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _format_integer(value: int) -> String:
	var digits := str(absi(value))
	var formatted := ""
	for index: int in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			formatted += ","
		formatted += digits[index]
	return ("-" if value < 0 else "") + formatted


func _safe_node_suffix(value: String) -> String:
	return value.strip_edges().replace(" ", "_").replace("-", "_").replace("/", "_")
