class_name FarmMutualContractBoardUI
extends Control

## Standalone presentation layer for the between-shift Farm Mutual board.
##
## The component consumes the canonical `contract_board` entry from a simulation
## snapshot. It owns selection and focus only: signing, declining, persistence,
## and shift transitions remain authoritative intent signals for the caller.

signal contract_selected(offer_id: StringName)
signal contract_sign_requested(offer_id: StringName, clause_id: StringName)
signal decline_requested
signal continue_requested

const ManagementTheme := preload("res://features/office/management_ui_theme.gd")

const INK := Color("e9edf0")
const MUTED := Color("9eabb5")
const ENAMEL_GREEN := Color("294b45")
const DEEP_GREEN := Color("182d2b")
const RAISED_GREEN := Color("213b37")
const PAPER := Color("ddd2b7")
const CREAM := Color("f4df9d")
const BRASS := Color("d1a650")
const TEAL := Color("73b5a7")
const RUST := Color("c96f59")
const GRAPHITE := Color("253137")

const MAX_VISIBLE_OFFERS := 3
const STANDARD_CLAUSE_ID: StringName = &"standard_terms"
const LANE_ORDER: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const LANE_SHORT_NAMES := {
	&"nest_damage": "NEST",
	&"predator_loss": "PREDATOR",
	&"appeals": "APPEALS",
}

var _contract_board: Dictionary = {}
var _selected_offer_id: StringName = &""
var _selected_clause_by_offer: Dictionary = {}
var _negotiation_open := false
var _signature_pending := false
var _decline_pending := false
var _built := false
var _last_target_day := -1

var _scroll: ScrollContainer
var _center: CenterContainer
var _panel: PanelContainer
var _content: VBoxContainer
var _day_stamp_label: Label
var _availability_card: PanelContainer
var _availability_label: Label
var _context_row: HFlowContainer
var _season_card: PanelContainer
var _season_label: Label
var _season_summary_label: Label
var _accreditation_card: PanelContainer
var _standing_rank_label: Label
var _standing_points_label: Label
var _standing_next_label: Label
var _standing_streak_label: Label
var _service_coop_label: Label
var _standing_seal_hosts: Array[PanelContainer] = []
var _standing_seal_labels: Array[Label] = []
var _planning_columns: HFlowContainer
var _offer_section: VBoxContainer
var _offer_cards: HFlowContainer
var _selection_hint: Label
var _offer_buttons: Dictionary[StringName, Button] = {}
var _detail_column: VBoxContainer

var _terms_card: PanelContainer
var _terms_heading: Label
var _terms_client: Label
var _terms_tagline: Label
var _terms_lane_mix: Label
var _terms_rush_schedule: Label
var _terms_success: Label
var _terms_premium: Label
var _terms_breach: Label
var _terms_reserve: Label
var _terms_capacity: Label
var _terms_reason: Label
var _term_metric_cards: Array[PanelContainer] = []
var _negotiation_toggle_button: Button
var _negotiation_card: PanelContainer
var _negotiation_status_label: Label
var _clause_buttons_host: VBoxContainer
var _clause_buttons: Dictionary[StringName, Button] = {}
var _reset_clause_button: Button
var _effective_terms_label: Label

var _receipt_card: PanelContainer
var _receipt_heading: Label
var _receipt_body: Label
var _action_center: CenterContainer
var _action_panel: PanelContainer
var _actions: HFlowContainer
var _decline_button: Button
var _sign_button: Button
var _continue_button: Button


func _ready() -> void:
	name = "FarmMutualContractBoardUI"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = ManagementTheme.create_theme()
	_build()
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_refresh()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_SPACE:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if not focused is Button or not focused.has_meta("clause_id"):
		return
	var clause_id := StringName(focused.get_meta("clause_id", &""))
	if clause_id == &"" or _clause_buttons.get(clause_id) != focused:
		return
	get_viewport().set_input_as_handled()
	_on_clause_pressed(clause_id)


## Replaces all presentation data from a complete simulation snapshot.
func apply_snapshot(snapshot: Dictionary) -> void:
	var board_value: Variant = snapshot.get("contract_board", {})
	_contract_board = (
		(board_value as Dictionary).duplicate(true)
		if board_value is Dictionary else
		{}
	)
	_signature_pending = false
	_decline_pending = false
	_reconcile_selection()
	_reconcile_clause_selection()
	_refresh()


## Convenience entry point for a caller that already extracted the canonical
## `contract_board` dictionary. The stored shape remains identical.
func apply_contract_board(contract_board: Dictionary) -> void:
	apply_snapshot({"contract_board": contract_board})


func selected_contract_id() -> StringName:
	return _selected_offer_id


func contract_board_snapshot() -> Dictionary:
	return _contract_board.duplicate(true)


func presentation_state() -> Dictionary:
	var effective := _selected_effective_offer()
	return {
		"selected_offer_id": String(_selected_offer_id),
		"selected_clause_id": String(_selected_clause_id()),
		"negotiation_open": _negotiation_open,
		"effective_terms": effective.duplicate(true),
		"sign_enabled": _sign_button != null and not _sign_button.disabled,
		"signature_pending": _signature_pending,
		"decline_visible": _decline_button != null and _decline_button.visible,
		"decline_pending": _decline_pending,
		"continue_enabled": _continue_button != null and not _continue_button.disabled,
		"signed_contract": _signed_contract_receipt(),
	}


func _build() -> void:
	if _built:
		return
	_built = true

	_scroll = ScrollContainer.new()
	_scroll.name = "ContractBoardScroll"
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.offset_left = 18.0
	_scroll.offset_top = 66.0
	_scroll.offset_right = -18.0
	# The filing actions live in their own fixed rail below this scroll surface,
	# so exact terms can never push Sign or Continue below the fold.
	_scroll.offset_bottom = -100.0
	_scroll.custom_minimum_size = Vector2(286.0, 240.0)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_scroll)

	_center = CenterContainer.new()
	_center.name = "ContractBoardCenter"
	_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_center.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_center)

	_panel = PanelContainer.new()
	_panel.name = "FarmMutualContractBoardPanel"
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(DEEP_GREEN, BRASS.darkened(0.12), 15, 2),
	)
	_center.add_child(_panel)

	_content = _panel_content(_panel, 28, 22, 11)
	var kicker := _make_label("FARM MUTUAL  //  CONTRACT & INDEMNITY BOARD", 12, BRASS)
	kicker.name = "ContractBoardKicker"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(kicker)

	var heading_row := HFlowContainer.new()
	heading_row.name = "ContractBoardHeadingRow"
	heading_row.alignment = FlowContainer.ALIGNMENT_CENTER
	heading_row.add_theme_constant_override("h_separation", 16)
	heading_row.add_theme_constant_override("v_separation", 8)
	_content.add_child(heading_row)

	var heading_stack := VBoxContainer.new()
	heading_stack.name = "ContractBoardHeadingStack"
	heading_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_stack.add_theme_constant_override("separation", 2)
	heading_row.add_child(heading_stack)
	var title := _make_label("CHOOSE THE OUTSIDE PECKWORK", 27, CREAM)
	title.name = "ContractBoardTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	heading_stack.add_child(title)
	var subtitle := _make_label(
		"Three client folders disclose the work before management signs the flock's name.",
		13,
		INK,
	)
	subtitle.name = "ContractBoardSubtitle"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading_stack.add_child(subtitle)

	var day_stamp := PanelContainer.new()
	day_stamp.name = "ContractBoardDayStamp"
	day_stamp.custom_minimum_size = Vector2(150.0, 58.0)
	day_stamp.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("354940"), BRASS, 7, 1),
	)
	heading_row.add_child(day_stamp)
	var day_stack := _panel_content(day_stamp, 12, 7, 0)
	var day_caption := _make_label("NEXT-SHIFT BINDER", 9, PAPER.darkened(0.14))
	day_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_stack.add_child(day_caption)
	_day_stamp_label = _make_label("DAY --", 19, CREAM)
	_day_stamp_label.name = "ContractBoardTargetDay"
	_day_stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_stack.add_child(_day_stamp_label)

	_availability_card = PanelContainer.new()
	_availability_card.name = "ContractBoardAvailabilityCard"
	_availability_card.add_theme_stylebox_override(
		"panel",
		_panel_style(RAISED_GREEN, Color("587269"), 8, 1),
	)
	_content.add_child(_availability_card)
	var availability_margin := MarginContainer.new()
	availability_margin.add_theme_constant_override("margin_left", 14)
	availability_margin.add_theme_constant_override("margin_right", 14)
	availability_margin.add_theme_constant_override("margin_top", 8)
	availability_margin.add_theme_constant_override("margin_bottom", 8)
	_availability_card.add_child(availability_margin)
	_availability_label = _make_label("CONTRACT BOARD AWAITING THE FARMER'S FILE", 11, TEAL)
	_availability_label.name = "ContractBoardAvailability"
	_availability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_availability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	availability_margin.add_child(_availability_label)

	_context_row = HFlowContainer.new()
	_context_row.name = "ContractBoardContextRow"
	_context_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_context_row.add_theme_constant_override("h_separation", 10)
	_context_row.add_theme_constant_override("v_separation", 8)
	_content.add_child(_context_row)
	_build_season_card(_context_row)
	_build_accreditation_card(_context_row)

	_content.add_child(HSeparator.new())
	_planning_columns = HFlowContainer.new()
	_planning_columns.name = "ContractPlanningColumns"
	_planning_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_planning_columns.add_theme_constant_override("h_separation", 12)
	_planning_columns.add_theme_constant_override("v_separation", 10)
	_content.add_child(_planning_columns)
	_offer_section = VBoxContainer.new()
	_offer_section.name = "ContractFolderSection"
	_offer_section.custom_minimum_size.x = 304.0
	_offer_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_offer_section.add_theme_constant_override("separation", 6)
	_planning_columns.add_child(_offer_section)
	var offer_section_title := _section_label("CLIENT FOLDERS  //  SELECT ONE WITH 1–3")
	offer_section_title.name = "ContractFolderSectionTitle"
	_offer_section.add_child(offer_section_title)
	_offer_cards = HFlowContainer.new()
	_offer_cards.name = "ContractFolderCards"
	_offer_cards.alignment = FlowContainer.ALIGNMENT_CENTER
	_offer_cards.add_theme_constant_override("h_separation", 10)
	_offer_cards.add_theme_constant_override("v_separation", 8)
	_offer_section.add_child(_offer_cards)
	_selection_hint = _make_label(
		"SELECT A FOLDER TO OPEN ITS COMPLETE PREMIUM, RUSH, AND BREACH TERMS.",
		11,
		BRASS,
	)
	_selection_hint.name = "ContractSelectionHint"
	_selection_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_offer_section.add_child(_selection_hint)

	_detail_column = VBoxContainer.new()
	_detail_column.name = "ContractDetailColumn"
	_detail_column.custom_minimum_size.x = 620.0
	_detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_column.add_theme_constant_override("separation", 9)
	_planning_columns.add_child(_detail_column)
	_build_terms_card(_detail_column)
	_build_receipt_card(_detail_column)
	_build_actions()


func _build_season_card(parent: Container) -> void:
	_season_card = PanelContainer.new()
	_season_card.name = "ContractSeasonStrip"
	_season_card.custom_minimum_size = Vector2(304.0, 78.0)
	_season_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_season_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("263e38"), BRASS.darkened(0.12), 8, 1),
	)
	parent.add_child(_season_card)
	var content := _panel_content(_season_card, 13, 8, 3)
	_season_label = _make_label("SEASON  //  STANDARD BOOK", 12, BRASS)
	_season_label.name = "ContractSeasonLabel"
	_season_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_season_label)
	_season_summary_label = _make_label("No seasonal rider is filed.", 11, INK)
	_season_summary_label.name = "ContractSeasonSummary"
	_season_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_season_summary_label)


func _build_accreditation_card(parent: Container) -> void:
	_accreditation_card = PanelContainer.new()
	_accreditation_card.name = "ContractAccreditationCard"
	_accreditation_card.custom_minimum_size = Vector2(620.0, 78.0)
	_accreditation_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_accreditation_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("203632"), Color("6c887d"), 8, 1),
	)
	parent.add_child(_accreditation_card)
	var content := _panel_content(_accreditation_card, 13, 8, 3)

	var heading := HFlowContainer.new()
	heading.name = "ContractAccreditationHeading"
	heading.add_theme_constant_override("h_separation", 12)
	heading.add_theme_constant_override("v_separation", 3)
	content.add_child(heading)
	var title := _make_label("FARM MUTUAL ACCREDITATION", 11, BRASS)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	_standing_rank_label = _make_label("UNLISTED", 13, MUTED)
	_standing_rank_label.name = "ContractStandingRank"
	_standing_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heading.add_child(_standing_rank_label)

	var seals := HFlowContainer.new()
	seals.name = "ContractStandingSeals"
	seals.alignment = FlowContainer.ALIGNMENT_CENTER
	seals.add_theme_constant_override("h_separation", 8)
	seals.add_theme_constant_override("v_separation", 5)
	content.add_child(seals)
	_standing_seal_hosts.clear()
	_standing_seal_labels.clear()
	for index in 3:
		var seal := PanelContainer.new()
		seal.name = "ContractStandingSeal%d" % (index + 1)
		seal.custom_minimum_size = Vector2(116.0, 26.0)
		seal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seals.add_child(seal)
		var seal_label := _make_label("OPEN SEAL", 10, MUTED)
		seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seal.add_child(seal_label)
		_standing_seal_hosts.append(seal)
		_standing_seal_labels.append(seal_label)

	var facts := HFlowContainer.new()
	facts.name = "ContractStandingFacts"
	facts.add_theme_constant_override("h_separation", 16)
	facts.add_theme_constant_override("v_separation", 3)
	content.add_child(facts)
	_standing_points_label = _make_label("STANDING 0", 11, INK)
	_standing_points_label.name = "ContractStandingPoints"
	_standing_points_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standing_points_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.add_child(_standing_points_label)
	_standing_next_label = _make_label("NEXT SEAL AT 2", 11, PAPER)
	_standing_next_label.name = "ContractStandingNextThreshold"
	_standing_next_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standing_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.add_child(_standing_next_label)
	_standing_streak_label = _make_label("CLEAN BINDER STREAK 0  //  BEST 0", 11, TEAL)
	_standing_streak_label.name = "ContractStandingCleanStreak"
	_standing_streak_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_standing_streak_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	facts.add_child(_standing_streak_label)

	_service_coop_label = _make_label("SERVICE COOP 0 / 3  //  +0% SUCCESS-ONLY PREMIUM", 11, BRASS)
	_service_coop_label.name = "ContractServiceCoopStatus"
	_service_coop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_service_coop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_service_coop_label)


func _build_terms_card(parent: Container) -> void:
	_terms_card = PanelContainer.new()
	_terms_card.name = "ContractTermsCard"
	_terms_card.add_theme_stylebox_override(
		"panel",
		_panel_style(GRAPHITE, Color("7d6b49"), 10, 1),
	)
	parent.add_child(_terms_card)
	var terms := _panel_content(_terms_card, 18, 13, 7)
	var terms_kicker := _make_label("OPEN BINDER  //  EXACT TERMS", 10, BRASS)
	terms_kicker.name = "ContractTermsKicker"
	terms.add_child(terms_kicker)
	_terms_heading = _make_label("SELECT A CLIENT FOLDER", 19, CREAM)
	_terms_heading.name = "ContractTermsTitle"
	_terms_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_terms_heading.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	terms.add_child(_terms_heading)
	_terms_client = _make_label("FARM MUTUAL CLIENT AWAITING SELECTION", 11, TEAL)
	_terms_client.name = "ContractTermsClient"
	_terms_client.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terms.add_child(_terms_client)
	_terms_tagline = _make_label("Select one of the three disclosed binders above.", 12, INK)
	_terms_tagline.name = "ContractTermsTagline"
	_terms_tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terms.add_child(_terms_tagline)

	var metrics := HFlowContainer.new()
	metrics.name = "ContractTermMetrics"
	metrics.alignment = FlowContainer.ALIGNMENT_CENTER
	metrics.add_theme_constant_override("h_separation", 9)
	metrics.add_theme_constant_override("v_separation", 7)
	terms.add_child(metrics)
	_terms_lane_mix = _build_term_metric(metrics, "ContractLaneMix", "LANE MIX", "AWAITING FILE", TEAL)
	_terms_premium = _build_term_metric(metrics, "ContractPremium", "FULFILLMENT PREMIUM", "+$0.00", TEAL)
	_terms_breach = _build_term_metric(metrics, "ContractBreachCharge", "BREACH CHARGE", "-$0.00", RUST)

	_terms_rush_schedule = _make_label("ARRIVAL SCHEDULE  //  AWAITING FILE", 12, PAPER)
	_terms_rush_schedule.name = "ContractRushSchedule"
	_terms_rush_schedule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_terms_rush_schedule.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	terms.add_child(_terms_rush_schedule)
	_terms_success = _make_label("SUCCESS CONDITION  //  AWAITING FILE", 12, INK)
	_terms_success.name = "ContractSuccessCondition"
	_terms_success.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terms.add_child(_terms_success)
	_terms_reserve = _make_label("INDEMNITY RESERVE  //  AWAITING FILE", 11, BRASS)
	_terms_reserve.name = "ContractBreachReserve"
	_terms_reserve.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terms.add_child(_terms_reserve)
	_terms_capacity = _make_label("ARCHIVE FIT  //  AWAITING FILE", 11, MUTED)
	_terms_capacity.name = "ContractCapacityFit"
	_terms_capacity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terms.add_child(_terms_capacity)
	_terms_reason = _make_label("No binder has been selected.", 11, MUTED)
	_terms_reason.name = "ContractTermReason"
	_terms_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terms.add_child(_terms_reason)
	_build_negotiation_drawer(terms)


func _build_negotiation_drawer(parent: VBoxContainer) -> void:
	_negotiation_toggle_button = _make_button(
		"ContractNegotiationToggle",
		"NEGOTIATE TERMS  [N]",
		&"DecisionChoiceButton",
	)
	_negotiation_toggle_button.custom_minimum_size.y = 42.0
	_negotiation_toggle_button.shortcut = _shortcut(KEY_N)
	_negotiation_toggle_button.tooltip_text = "Open one optional negotiated rider. Space selects the focused rider; R restores standard terms."
	_negotiation_toggle_button.pressed.connect(_on_negotiation_toggle_pressed)
	parent.add_child(_negotiation_toggle_button)

	_negotiation_card = PanelContainer.new()
	_negotiation_card.name = "ContractNegotiationDrawer"
	_negotiation_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1d302e"), Color("5e7d72"), 8, 1),
	)
	parent.add_child(_negotiation_card)
	var drawer := _panel_content(_negotiation_card, 13, 9, 6)
	_negotiation_status_label = _make_label(
		"NEGOTIATION ROOM  //  STANDARD TERMS FILED",
		10,
		BRASS,
	)
	_negotiation_status_label.name = "ContractNegotiationStatus"
	_negotiation_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drawer.add_child(_negotiation_status_label)

	_clause_buttons_host = VBoxContainer.new()
	_clause_buttons_host.name = "ContractClauseChoices"
	_clause_buttons_host.add_theme_constant_override("separation", 5)
	drawer.add_child(_clause_buttons_host)

	_effective_terms_label = _make_label("EFFECTIVE DRAFT  //  AWAITING BINDER", 11, TEAL)
	_effective_terms_label.name = "ContractEffectiveTermsSummary"
	_effective_terms_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	drawer.add_child(_effective_terms_label)

	_reset_clause_button = _make_button(
		"ResetContractClauseButton",
		"RESTORE STANDARD TERMS  [R]",
		&"DecisionChoiceButton",
	)
	_reset_clause_button.custom_minimum_size.y = 40.0
	_reset_clause_button.shortcut = _shortcut(KEY_R)
	_reset_clause_button.pressed.connect(_on_reset_clause_pressed)
	drawer.add_child(_reset_clause_button)


func _build_receipt_card(parent: Container) -> void:
	_receipt_card = PanelContainer.new()
	_receipt_card.name = "ContractSignedReceiptCard"
	_receipt_card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("29453d"), TEAL, 9, 2),
	)
	parent.add_child(_receipt_card)
	var receipt := _panel_content(_receipt_card, 18, 12, 4)
	_receipt_heading = _make_label("BOUND  //  SIGNED MUTUAL TERM", 15, CREAM)
	_receipt_heading.name = "ContractSignedReceiptTitle"
	_receipt_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	receipt.add_child(_receipt_heading)
	_receipt_body = _make_label("The authoritative signature receipt will appear here.", 11, INK)
	_receipt_body.name = "ContractSignedReceiptBody"
	_receipt_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	receipt.add_child(_receipt_body)


func _build_actions() -> void:
	_action_center = CenterContainer.new()
	_action_center.name = "ContractBoardActionRail"
	_action_center.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_action_center.offset_left = 18.0
	_action_center.offset_top = -82.0
	_action_center.offset_right = -18.0
	_action_center.offset_bottom = -18.0
	_action_center.mouse_filter = Control.MOUSE_FILTER_PASS
	_action_center.z_index = 3
	add_child(_action_center)

	_action_panel = PanelContainer.new()
	_action_panel.name = "ContractBoardActionPanel"
	_action_panel.custom_minimum_size = Vector2(1040.0, 64.0)
	_action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_panel.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("142725"), BRASS.darkened(0.10), 9, 2),
	)
	_action_center.add_child(_action_panel)
	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 12)
	action_margin.add_theme_constant_override("margin_right", 12)
	action_margin.add_theme_constant_override("margin_top", 7)
	action_margin.add_theme_constant_override("margin_bottom", 7)
	_action_panel.add_child(action_margin)

	_actions = HFlowContainer.new()
	_actions.name = "ContractBoardActions"
	_actions.alignment = FlowContainer.ALIGNMENT_END
	_actions.add_theme_constant_override("h_separation", 10)
	_actions.add_theme_constant_override("v_separation", 8)
	action_margin.add_child(_actions)

	_decline_button = _make_button(
		"DeclineContractButton",
		"KEEP THE STANDARD BOOK  [D]",
		&"DangerButton",
	)
	_decline_button.custom_minimum_size = Vector2(238.0, 48.0)
	_decline_button.shortcut = _shortcut(KEY_D)
	_decline_button.tooltip_text = "Proceed without an outside Farm Mutual binder. This action is available only when the caller explicitly permits it."
	_decline_button.pressed.connect(_on_decline_pressed)
	_actions.add_child(_decline_button)

	_sign_button = _make_button(
		"SignContractButton",
		"SELECT A BINDER TO SIGN  [ENTER]",
		&"PrimaryButton",
	)
	_sign_button.custom_minimum_size = Vector2(262.0, 48.0)
	_sign_button.shortcut = _shortcut([KEY_ENTER, KEY_KP_ENTER])
	_sign_button.pressed.connect(_on_sign_pressed)
	_actions.add_child(_sign_button)

	_continue_button = _make_button(
		"OpenContractShiftButton",
		"SIGNED RECEIPT REQUIRED",
		&"PrimaryButton",
	)
	_continue_button.custom_minimum_size = Vector2(274.0, 48.0)
	_continue_button.shortcut = _shortcut(KEY_C)
	_continue_button.pressed.connect(_on_continue_pressed)
	_actions.add_child(_continue_button)


func _refresh() -> void:
	if not _built:
		return
	var unlocked := bool(_contract_board.get("unlocked", false))
	var planning_open := bool(_contract_board.get("planning_open", false))
	var target_day := maxi(1, int(_contract_board.get("target_day", 1)))
	var should_reset_scroll := _last_target_day != target_day
	_last_target_day = target_day
	_day_stamp_label.text = "DAY %d" % target_day

	var signed := _signed_contract_receipt()
	var declined := _decline_receipt()
	if not unlocked:
		_availability_label.text = "SEALED  //  %s" % String(_contract_board.get(
			"unlock_requirement",
			"Complete two shifts before Farm Mutual opens its contract folders.",
		)).to_upper()
		_availability_label.add_theme_color_override("font_color", MUTED)
	elif not signed.is_empty():
		_availability_label.text = "BOUND  //  %s IS RESERVED FOR DAY %d" % [
			String(signed.get("short_name", signed.get("name", "MUTUAL TERM"))).to_upper(),
			target_day,
		]
		_availability_label.add_theme_color_override("font_color", TEAL)
	elif not declined.is_empty():
		_availability_label.text = "STANDARD BOOK FILED  //  NO OUTSIDE MUTUAL TERM"
		_availability_label.add_theme_color_override("font_color", BRASS)
	elif planning_open:
		_availability_label.text = "PLANNING OPEN  //  A SIGNATURE RESERVES THE DISCLOSED BREACH CHARGE, NOT THE PREMIUM"
		_availability_label.add_theme_color_override("font_color", TEAL)
	else:
		_availability_label.text = "BOARD HELD  //  CLOSE THE SHIFT AND FILE CREDIT BEFORE SIGNING OUTSIDE PECKWORK"
		_availability_label.add_theme_color_override("font_color", RUST)

	_refresh_season()
	_refresh_accreditation()
	_rebuild_offer_cards(unlocked)
	_refresh_selection()
	_refresh_receipt(signed, declined)
	_refresh_actions(signed, declined)
	_apply_responsive_layout()
	if should_reset_scroll:
		call_deferred("_reset_scroll")


func _refresh_season() -> void:
	var value: Variant = _contract_board.get("season", {})
	var season := value as Dictionary if value is Dictionary else {}
	_season_card.visible = not season.is_empty()
	if season.is_empty():
		return
	var label := String(season.get("label", season.get("name", season.get("id", "SEASONAL BOOK"))))
	var summary := String(season.get("summary", "Seasonal terms alter this planning book."))
	_season_label.text = "SEASON  //  %s" % label.to_upper()
	_season_summary_label.text = summary
	# New snapshots may publish authored effects directly; the live economy keeps
	# the same information in its lane-demand basis-point ledger.
	var has_authored_effects := season.has("effects")
	var effects_value: Variant = season.get(
		"effects",
		season.get("lane_demand_basis_points", {}),
	)
	var effects := effects_value as Dictionary if effects_value is Dictionary else {}
	var tooltip_lines: Array[String] = [
		"%s // %s" % [label.to_upper(), summary],
	]
	for key: Variant in effects:
		var effect_label := String(key).replace("_", " ").to_upper()
		var effect_value: Variant = effects[key]
		var demand_percent := float(effect_value) / 100.0 if effect_value is int else 0.0
		tooltip_lines.append(
			"%s: %s%.1f%% DEMAND" % [
				effect_label,
				"+" if demand_percent >= 0.0 else "",
				demand_percent,
			]
			if not has_authored_effects and effect_value is int else
			"%s: %s" % [effect_label, str(effect_value)]
		)
	var tooltip := "\n".join(tooltip_lines)
	_season_card.tooltip_text = tooltip
	_season_label.tooltip_text = tooltip
	_season_summary_label.tooltip_text = tooltip


func _refresh_accreditation() -> void:
	var standing := _standing_snapshot()
	var accreditation := _accreditation_snapshot()
	var points := maxi(0, int(standing.get("points", _contract_board.get("standing_points", 0))))
	var rank := StringName(String(standing.get(
		"rank",
		_contract_board.get("standing_rank", &"unlisted"),
	)).to_lower())
	if rank not in [&"unlisted", &"bronze", &"silver", &"gold"]:
		rank = &"unlisted"
	var rank_label := String(standing.get("rank_label", String(rank))).to_upper()
	_standing_rank_label.text = "%s  //  %d STANDING" % [rank_label, points]
	_standing_rank_label.add_theme_color_override("font_color", _standing_rank_color(rank))
	_standing_points_label.text = "FARM MUTUAL STANDING  %d" % points

	var next_threshold := maxi(0, int(standing.get(
		"next_threshold",
		_contract_board.get("next_standing_threshold", 2),
	)))
	var points_to_next := maxi(0, int(standing.get(
		"points_to_next",
		maxi(0, next_threshold - points),
	)))
	_standing_next_label.text = (
		"ALL THREE ACCREDITATION SEALS FILED  //  GOLD THRESHOLD %d" % next_threshold
		if rank == &"gold" and points_to_next == 0 else
		"NEXT SEAL AT %d  //  %d MORE STANDING" % [next_threshold, points_to_next]
	)
	var clean_streak := maxi(0, int(standing.get(
		"clean_streak",
		_contract_board.get("clean_contract_streak", 0),
	)))
	var best_clean_streak := maxi(clean_streak, int(standing.get(
		"best_clean_streak",
		_contract_board.get("best_clean_contract_streak", clean_streak),
	)))
	_standing_streak_label.text = "CLEAN BINDER STREAK  %d  //  BEST %d" % [
		clean_streak,
		best_clean_streak,
	]

	var seals := _standing_seals(standing, points)
	for index in _standing_seal_hosts.size():
		var seal := seals[index] as Dictionary
		var earned := bool(seal.get("earned", false))
		var seal_label := String(seal.get("label", "SEAL %d" % (index + 1))).to_upper()
		var threshold := maxi(0, int(seal.get("threshold", 0)))
		_standing_seal_labels[index].text = (
			"SEALED  //  %s" % seal_label
			if earned else
			"OPEN  //  %s AT %d" % [seal_label, threshold]
		)
		_standing_seal_labels[index].add_theme_color_override(
			"font_color",
			_standing_rank_color(StringName(String(seal.get("id", "unlisted")))) if earned else MUTED,
		)
		_standing_seal_hosts[index].add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color("354940") if earned else Color("1c292e"),
				_standing_rank_color(StringName(String(seal.get("id", "unlisted")))) if earned else Color("536168"),
				16,
				2 if earned else 1,
			),
		)

	var coop_level := clampi(int(accreditation.get(
		"level",
		_contract_board.get("service_coop_level", 0),
	)), 0, maxi(1, int(accreditation.get("max_level", 3))))
	var coop_max := maxi(1, int(accreditation.get("max_level", 3)))
	var bonus_percent := maxi(0, int(accreditation.get(
		"premium_bonus_percent",
		roundi(float(accreditation.get(
			"premium_bonus_basis_points",
			_contract_board.get("service_coop_bonus_basis_points", 0),
		)) / 100.0),
	)))
	_service_coop_label.text = "SERVICE COOP  %d / %d  //  +%d%% SUCCESS-ONLY PREMIUM" % [
		coop_level,
		coop_max,
		bonus_percent,
	]
	var accreditation_tooltip := (
		"Farm Mutual standing changes only when a signed binder settles. Each named seal is a discrete accreditation threshold; no percentage meter is used.\n"
		+ "Current standing: %d (%s). Next threshold: %d; %d required. Clean binder streak: %d; best: %d.\n" % [
			points,
			rank_label,
			next_threshold,
			points_to_next,
			clean_streak,
			best_clean_streak,
		]
		+ "Service Coop level %d/%d adds %d%% only to successfully fulfilled Farm Mutual premiums." % [
			coop_level,
			coop_max,
			bonus_percent,
		]
	)
	_accreditation_card.tooltip_text = accreditation_tooltip
	for label in [
		_standing_rank_label,
		_standing_points_label,
		_standing_next_label,
		_standing_streak_label,
		_service_coop_label,
	]:
		(label as Control).tooltip_text = accreditation_tooltip


func _standing_snapshot() -> Dictionary:
	var value: Variant = _contract_board.get("standing", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _accreditation_snapshot() -> Dictionary:
	var value: Variant = _contract_board.get("accreditation", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _standing_seals(standing: Dictionary, points: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source: Variant = standing.get("seals", [])
	if source is Array:
		for value: Variant in source as Array:
			if value is Dictionary and result.size() < 3:
				result.append((value as Dictionary).duplicate(true))
	var defaults: Array[Dictionary] = [
		{"id": &"bronze", "label": "BRONZE CLIENT SEAL", "threshold": 2},
		{"id": &"silver", "label": "SILVER SERVICE SEAL", "threshold": 6},
		{"id": &"gold", "label": "GOLD ACCOUNT SEAL", "threshold": 12},
	]
	while result.size() < 3:
		result.append(defaults[result.size()].duplicate(true))
	for index in result.size():
		var seal := result[index]
		var threshold := maxi(0, int(seal.get("threshold", defaults[index]["threshold"])))
		seal["earned"] = bool(seal.get("earned", points >= threshold))
		seal["threshold"] = threshold
		seal["id"] = StringName(String(seal.get("id", defaults[index]["id"])))
		seal["label"] = String(seal.get("label", defaults[index]["label"]))
	return result


func _standing_rank_color(rank: StringName) -> Color:
	match rank:
		&"bronze":
			return Color("d29562")
		&"silver":
			return Color("cbd2d1")
		&"gold":
			return CREAM
	return MUTED


func _rebuild_offer_cards(unlocked: bool) -> void:
	for child: Node in _offer_cards.get_children():
		_offer_cards.remove_child(child)
		child.queue_free()
	_offer_buttons.clear()

	var offers := _offers()
	_offer_section.visible = unlocked and not offers.is_empty()
	var index := 0
	for offer in offers:
		if index >= MAX_VISIBLE_OFFERS:
			break
		var offer_id := StringName(offer.get("id", offer.get("offer_id", "offer_%d" % index)))
		if offer_id == &"" or _offer_buttons.has(offer_id):
			continue
		var button := _make_button(
			"ContractFolder_%s" % _safe_node_suffix(String(offer_id)),
			_offer_card_text(offer, index),
			&"DecisionChoiceButton",
		)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.custom_minimum_size = Vector2(285.0, 116.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.shortcut = _shortcut([KEY_1, KEY_2, KEY_3][index])
		button.tooltip_text = _offer_tooltip(offer)
		button.set_meta("offer_id", offer_id)
		button.set_meta("can_sign", bool(offer.get("can_sign", false)))
		button.pressed.connect(_on_offer_pressed.bind(offer_id))
		_offer_cards.add_child(button)
		_offer_buttons[offer_id] = button
		index += 1

	if _offer_buttons.is_empty():
		_offer_section.visible = false


func _refresh_selection() -> void:
	for offer_id in _offer_buttons:
		var button := _offer_buttons[offer_id] as Button
		button.theme_type_variation = (
			&"SelectedChoiceButton"
			if offer_id == _selected_offer_id else
			&"DecisionChoiceButton"
		)

	var offer := _selected_offer()
	var effective := _selected_effective_offer()
	_terms_card.visible = not effective.is_empty()
	if effective.is_empty():
		_selection_hint.text = "SELECT A FOLDER TO OPEN ITS COMPLETE PREMIUM, RUSH, AND BREACH TERMS."
		_refresh_negotiation_drawer({}, {})
		return

	var short_name := String(effective.get("short_name", effective.get("name", "MUTUAL TERM"))).to_upper()
	_selection_hint.text = "SELECTED  //  %s  //  ENTER SIGNS ONLY AFTER THE EXACT TERMS BELOW ARE OPEN" % short_name
	_terms_heading.text = String(effective.get("name", short_name)).to_upper()
	_terms_client.text = "CLIENT  //  %s" % String(effective.get("client", "FARM MUTUAL")).to_upper()
	_terms_tagline.text = String(effective.get("tagline", "Outside peckwork with disclosed terms."))
	_terms_lane_mix.text = _lane_mix_label(effective.get("lane_mix", {}) as Dictionary)
	_terms_premium.text = _premium_breakdown(effective)
	_terms_breach.text = "-%s" % _money(int(effective.get("breach_cents", 0)))
	_terms_rush_schedule.text = "ARRIVAL SCHEDULE  //\n%s" % _arrival_schedule(effective)
	_terms_success.text = "SUCCESS CONDITION  //  %s" % String(effective.get(
		"success_required",
		"Deliver %d qualifying folders inside their disclosed service windows." % int(
			effective.get("required_completed", 0)
		),
	))
	var reserve := int(effective.get("breach_reserve_cents", effective.get("breach_cents", 0)))
	var spendable_after := int(effective.get(
		"spendable_after_reserve_cents",
		effective.get("projected_spendable_after_signing_cents", 0),
	))
	_terms_reserve.text = "INDEMNITY RESERVE  //  %s HELD  //  %s SPENDABLE AFTER SIGNATURE" % [
		_money(reserve),
		_money(spendable_after),
	]
	_terms_capacity.text = _fit_breakdown(effective)
	var can_sign := _effective_offer_can_sign(offer, effective)
	var reason := String(effective.get("reason", offer.get("reason", "")))
	_terms_reason.text = (
		"SIGNATURE PREFLIGHT CLEAR  //  ENTER AUTHORIZES %s." % _selected_clause_label(effective).to_upper()
		if can_sign else
		"CLIENT COOLDOWN THROUGH DAY %d  //  %s" % [
			int(effective.get("cooldown_until_day", offer.get("cooldown_until_day", _contract_board.get("target_day", 1)))),
			reason if not reason.is_empty() else "Farm Mutual has held this client file after a breached term.",
		]
		if bool(effective.get("on_cooldown", offer.get("on_cooldown", false))) else
		"SIGNATURE HELD  //  %s" % (
			reason
			if not reason.is_empty() else
			"The Farm Mutual planning window is not open."
			if not bool(_contract_board.get("planning_open", false)) else
			"The authoritative preflight did not clear."
		)
	)
	_terms_reason.add_theme_color_override("font_color", TEAL if can_sign else RUST)
	_refresh_negotiation_drawer(offer, effective)
	var tooltip := _offer_tooltip(effective)
	_terms_card.tooltip_text = tooltip
	for label in [
		_terms_heading,
		_terms_client,
		_terms_tagline,
		_terms_lane_mix,
		_terms_rush_schedule,
		_terms_success,
		_terms_premium,
		_terms_breach,
		_terms_reserve,
		_terms_capacity,
		_terms_reason,
	]:
		(label as Control).tooltip_text = tooltip


func _refresh_negotiation_drawer(offer: Dictionary, effective: Dictionary) -> void:
	for child: Node in _clause_buttons_host.get_children():
		_clause_buttons_host.remove_child(child)
		child.queue_free()
	_clause_buttons.clear()

	var options := _clause_options(offer)
	var room := _negotiation_room()
	var has_authored_negotiation := not options.is_empty()
	_negotiation_toggle_button.visible = has_authored_negotiation
	_negotiation_card.visible = has_authored_negotiation and _negotiation_open
	if not has_authored_negotiation:
		return

	var room_unlocked := bool(room.get("unlocked", room.get("owned", false)))
	var max_slots := maxi(1, int(room.get("max_clause_slots", 1)))
	var room_reason := String(room.get(
		"reason",
		"Commission the negotiation room to file optional riders.",
	))
	_negotiation_status_label.text = (
		"NEGOTIATION ROOM  //  OPEN  //  CHOOSE ONE OF %d RIDER SLOT%s" % [
			max_slots,
			"" if max_slots == 1 else "S",
		]
		if room_unlocked else
		"NEGOTIATION ROOM  //  HELD  //  %s" % room_reason.to_upper()
	)
	_negotiation_status_label.add_theme_color_override("font_color", TEAL if room_unlocked else RUST)

	var selected_clause := _selected_clause_id()
	for option in options:
		var clause_id := StringName(option.get("clause_id", option.get("id", STANDARD_CLAUSE_ID)))
		if clause_id == &"":
			continue
		var selected := clause_id == selected_clause
		var available := _clause_is_available(option)
		var can_sign := _effective_offer_can_sign(offer, option)
		var button := _make_button(
			"ContractClause_%s" % _safe_node_suffix(String(clause_id)),
			_clause_card_text(option, selected, available, can_sign),
			&"SelectedChoiceButton" if selected else &"DecisionChoiceButton",
		)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0.0, 62.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = _clause_tooltip(option, available, can_sign)
		button.set_meta("clause_id", clause_id)
		button.set_meta("clause_available", available)
		button.pressed.connect(_on_clause_pressed.bind(clause_id))
		_clause_buttons_host.add_child(button)
		_clause_buttons[clause_id] = button

	_effective_terms_label.text = _effective_terms_summary(effective)
	_reset_clause_button.disabled = selected_clause == STANDARD_CLAUSE_ID
	_reset_clause_button.tooltip_text = (
		"Standard terms are already selected."
		if _reset_clause_button.disabled else
		"Discard the optional rider and restore the standard seasonal preflight."
	)
	_negotiation_toggle_button.text = (
		"CLOSE NEGOTIATION  [N]"
		if _negotiation_open else
		"NEGOTIATE TERMS  [N]  //  %s" % _selected_clause_label(effective).to_upper()
	)


func _clause_card_text(
	option: Dictionary,
	selected: bool,
	available: bool,
	can_sign: bool,
) -> String:
	var label := _selected_clause_label(option).to_upper()
	var summary := String(option.get("clause_summary", "Use the disclosed effective terms."))
	var status := "SELECTED" if selected else "AVAILABLE" if available and can_sign else "HELD"
	return "%s  //  %s\n%s\nFILES %d  //  RUSH %d  //  PREMIUM %s  //  BREACH -%s" % [
		status,
		label,
		summary,
		maxi(0, int(option.get("total_claims", 0))),
		maxi(0, int(option.get("rush_claims", 0))),
		_money(_premium_total_cents(option)),
		_money(int(option.get("breach_cents", 0))),
	]


func _clause_tooltip(option: Dictionary, available: bool, can_sign: bool) -> String:
	var reason := String(option.get("reason", ""))
	return "%s\n%s\n%s\n%s" % [
		_selected_clause_label(option).to_upper(),
		String(option.get("clause_summary", "Disclosed effective terms.")),
		_effective_terms_summary(option),
		"SPACE SELECTS THIS RIDER. ENTER SIGNS THE SELECTED DRAFT."
		if available and can_sign else
		"HELD // %s" % (reason if not reason.is_empty() else "This rider is not available."),
	]


func _effective_terms_summary(record: Dictionary) -> String:
	return "EFFECTIVE  //  FILES %d  //  RUSH %d  //  NEED %d  //  PREMIUM %s  //  BREACH -%s" % [
		maxi(0, int(record.get("total_claims", 0))),
		maxi(0, int(record.get("rush_claims", 0))),
		maxi(0, int(record.get("required_completed", 0))),
		_money(_premium_total_cents(record)),
		_money(int(record.get("breach_cents", 0))),
	]


func _refresh_receipt(signed: Dictionary, declined: Dictionary) -> void:
	_receipt_card.visible = not signed.is_empty() or not declined.is_empty()
	if not signed.is_empty():
		var name := String(signed.get("short_name", signed.get("name", "MUTUAL TERM"))).to_upper()
		var clause_label := _selected_clause_label(signed).to_upper()
		var season := _season_snapshot()
		var season_label := String(signed.get(
			"season_label",
			season.get("label", "STANDARD SEASON"),
		)).to_upper()
		_receipt_heading.text = "BOUND  //  %s  //  %s  //  SIGNED RECEIPT" % [name, clause_label]
		_receipt_body.text = "%s  //  DAY %d  //  %s\n%s\n%s\n%s breach reserve held  //  %d of %d clean, timely folders required." % [
			String(signed.get("contract_id", "FARM MUTUAL TERM")),
			int(signed.get("target_day", _contract_board.get("target_day", 1))),
			season_label,
			_premium_breakdown(signed),
			_fit_breakdown(signed),
			_money(int(signed.get("breach_cents", 0))),
			int(signed.get("required_completed", 0)),
			int(signed.get("total_claims", 0)),
		]
		_receipt_card.tooltip_text = _offer_tooltip(signed)
	elif not declined.is_empty():
		_receipt_heading.text = "STANDARD BOOK  //  DECLINE RECEIPT FILED"
		_receipt_body.text = String(declined.get(
			"outcome",
			"No outside Farm Mutual term was signed for the next shift.",
		))
		_receipt_card.tooltip_text = _receipt_body.text


func _refresh_actions(signed: Dictionary, declined: Dictionary) -> void:
	var complete := not signed.is_empty() or not declined.is_empty()
	var planning_open := (
		bool(_contract_board.get("unlocked", false))
		and bool(_contract_board.get("planning_open", false))
	)
	var allow_decline := bool(_contract_board.get("decline_available", false)) and planning_open
	var offer := _selected_offer()
	var effective := _selected_effective_offer()
	var can_sign := (
		not complete
		and not _signature_pending
		and not _decline_pending
		and not effective.is_empty()
		and _effective_offer_can_sign(offer, effective)
	)

	_decline_button.visible = allow_decline and not complete
	_decline_button.disabled = _signature_pending or _decline_pending
	_sign_button.visible = not complete
	_sign_button.disabled = not can_sign
	_sign_button.text = (
		"SIGNATURE SENT  //  AWAITING RECEIPT"
		if _signature_pending else
		"SIGN %s  //  %s  [ENTER]" % [
			String(effective.get("short_name", effective.get("name", "SELECTED BINDER"))).to_upper(),
			_selected_clause_label(effective).to_upper(),
		]
		if not effective.is_empty() else
		"SELECT A BINDER TO SIGN  [ENTER]"
	)
	_sign_button.tooltip_text = (
		"Awaiting the authoritative Farm Mutual signature receipt."
		if _signature_pending else
		_offer_tooltip(effective)
		if not effective.is_empty() else
		"Select one inspectable client folder before signing."
	)

	_continue_button.disabled = not complete
	var target_day := maxi(1, int(_contract_board.get("target_day", 1)))
	_continue_button.text = (
		"OPEN DAY %d BRIEFING  [C]" % target_day
		if complete else
		"SIGNED RECEIPT REQUIRED"
	)
	_continue_button.tooltip_text = (
		"File this planning receipt and open the next morning briefing."
		if complete else
		"Continue becomes available only after an authoritative signature or explicit decline receipt."
	)

	if complete:
		_queue_focus(_continue_button)
	elif _selected_offer_id == &"":
		_queue_focus(_first_offer_button())


func _on_offer_pressed(offer_id: StringName) -> void:
	if not _offer_buttons.has(offer_id):
		return
	_selected_offer_id = offer_id
	if not _selected_clause_by_offer.has(offer_id):
		_selected_clause_by_offer[offer_id] = STANDARD_CLAUSE_ID
	_signature_pending = false
	_refresh_selection()
	_refresh_actions(_signed_contract_receipt(), _decline_receipt())
	contract_selected.emit(offer_id)
	if _sign_button != null and not _sign_button.disabled:
		_queue_focus(_sign_button)


func _on_sign_pressed() -> void:
	if _signature_pending or _selected_offer_id == &"":
		return
	var offer := _selected_offer()
	var effective := _selected_effective_offer()
	if effective.is_empty() or not _effective_offer_can_sign(offer, effective):
		return
	_signature_pending = true
	_refresh_actions({}, {})
	contract_sign_requested.emit(_selected_offer_id, _selected_clause_id())


func _on_negotiation_toggle_pressed() -> void:
	if _selected_offer_id == &"" or _clause_options(_selected_offer()).is_empty():
		return
	_negotiation_open = not _negotiation_open
	_refresh_selection()
	_apply_responsive_layout()
	if _negotiation_open:
		var selected_button := _clause_buttons.get(_selected_clause_id()) as Button
		_queue_focus(selected_button)
	elif _sign_button != null and not _sign_button.disabled:
		_queue_focus(_sign_button)


func _on_clause_pressed(clause_id: StringName) -> void:
	if _selected_offer_id == &"" or not _clause_buttons.has(clause_id):
		return
	var option := _find_clause_option(_selected_offer(), clause_id)
	if option.is_empty() or not _clause_is_available(option):
		return
	_selected_clause_by_offer[_selected_offer_id] = clause_id
	_signature_pending = false
	_refresh_selection()
	_refresh_actions(_signed_contract_receipt(), _decline_receipt())
	if _sign_button != null and not _sign_button.disabled:
		_queue_focus(_sign_button)


func _on_reset_clause_pressed() -> void:
	if _selected_offer_id == &"":
		return
	_selected_clause_by_offer[_selected_offer_id] = STANDARD_CLAUSE_ID
	_signature_pending = false
	_refresh_selection()
	_refresh_actions(_signed_contract_receipt(), _decline_receipt())
	if _sign_button != null and not _sign_button.disabled:
		_queue_focus(_sign_button)


func _on_decline_pressed() -> void:
	if (
		_decline_pending
		or not bool(_contract_board.get("decline_available", false))
		or not bool(_contract_board.get("unlocked", false))
		or not bool(_contract_board.get("planning_open", false))
		or not _signed_contract_receipt().is_empty()
	):
		return
	_decline_pending = true
	_refresh_actions({}, {})
	decline_requested.emit()


func _on_continue_pressed() -> void:
	if _signed_contract_receipt().is_empty() and _decline_receipt().is_empty():
		return
	continue_requested.emit()


func _reconcile_selection() -> void:
	var signed := _signed_contract_receipt()
	if not signed.is_empty():
		_selected_offer_id = StringName(signed.get("offer_id", signed.get("id", &"")))
		_selected_clause_by_offer[_selected_offer_id] = StringName(signed.get(
			"clause_id",
			STANDARD_CLAUSE_ID,
		))
		_negotiation_open = false
		return
	if _selected_offer_id != &"" and _find_offer(_selected_offer_id).is_empty():
		_selected_clause_by_offer.erase(_selected_offer_id)
		_selected_offer_id = &""
		_negotiation_open = false


func _reconcile_clause_selection() -> void:
	var valid_offer_ids: Dictionary = {}
	for offer in _offers():
		var offer_id := StringName(offer.get("id", offer.get("offer_id", &"")))
		if offer_id == &"":
			continue
		valid_offer_ids[offer_id] = true
		var selected := StringName(_selected_clause_by_offer.get(offer_id, STANDARD_CLAUSE_ID))
		if _find_clause_option(offer, selected).is_empty():
			_selected_clause_by_offer[offer_id] = STANDARD_CLAUSE_ID
	for stored_offer: Variant in _selected_clause_by_offer.keys():
		if not valid_offer_ids.has(stored_offer):
			_selected_clause_by_offer.erase(stored_offer)
	if _selected_offer_id != &"" and _clause_options(_selected_offer()).is_empty():
		_negotiation_open = false


func _signed_contract_receipt() -> Dictionary:
	var active_value: Variant = _contract_board.get(
		"active",
		_contract_board.get("active_contract", {}),
	)
	if not active_value is Dictionary:
		return {}
	var active := active_value as Dictionary
	if active.is_empty():
		return {}
	if StringName(active.get("status", &"")) != &"signed":
		return {}
	if String(active.get("contract_id", "")).strip_edges().is_empty():
		return {}
	var target_day := int(_contract_board.get("target_day", 0))
	if target_day > 0 and int(active.get("target_day", -1)) != target_day:
		return {}
	return active.duplicate(true)


func _decline_receipt() -> Dictionary:
	var receipt_value: Variant = _contract_board.get("decline_receipt", {})
	if not receipt_value is Dictionary:
		return {}
	var receipt := receipt_value as Dictionary
	if not bool(receipt.get("accepted", false)):
		return {}
	var target_day := int(_contract_board.get("target_day", 0))
	if receipt.has("target_day") and int(receipt.get("target_day", -1)) != target_day:
		return {}
	return receipt.duplicate(true)


func _offers() -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	var offers_value: Variant = _contract_board.get("offers", [])
	if not offers_value is Array:
		return normalized
	for offer_value: Variant in offers_value as Array:
		if offer_value is Dictionary:
			normalized.append((offer_value as Dictionary).duplicate(true))
	return normalized


func _selected_offer() -> Dictionary:
	return _find_offer(_selected_offer_id)


func _selected_clause_id() -> StringName:
	if _selected_offer_id == &"":
		return STANDARD_CLAUSE_ID
	return StringName(_selected_clause_by_offer.get(_selected_offer_id, STANDARD_CLAUSE_ID))


func _selected_effective_offer() -> Dictionary:
	var offer := _selected_offer()
	if offer.is_empty():
		return {}
	var effective := _find_clause_option(offer, _selected_clause_id())
	if effective.is_empty():
		effective = offer.duplicate(true)
		effective["clause_id"] = STANDARD_CLAUSE_ID
		effective["clause_label"] = "STANDARD TERMS"
		effective["clause_available"] = true
	# Board-level offer preflights remain the authority for capacity, cooldown,
	# planning-window, and already-signed holds even when an authored rider was
	# priced earlier. A clause can narrow eligibility but can never widen it.
	for key in [
		"on_cooldown", "cooldown_until_day", "available_claim_slots",
		"active_staff_count", "active_staff_shortfall", "staffing_ready",
	]:
		if offer.has(key):
			effective[key] = offer[key]
	if not bool(offer.get("can_sign", false)):
		effective["can_sign"] = false
		if not String(offer.get("reason", "")).is_empty():
			effective["reason"] = offer["reason"]
	return effective


func _clause_options(offer: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var value: Variant = offer.get("clause_options", [])
	if value is Array:
		for option_value: Variant in value as Array:
			if option_value is Dictionary:
				result.append((option_value as Dictionary).duplicate(true))
	return result


func _find_clause_option(offer: Dictionary, clause_id: StringName) -> Dictionary:
	for option in _clause_options(offer):
		if StringName(option.get("clause_id", option.get("id", &""))) == clause_id:
			return option
	return {}


func _negotiation_room() -> Dictionary:
	var value: Variant = _contract_board.get("negotiation_room", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _season_snapshot() -> Dictionary:
	var value: Variant = _contract_board.get("season", {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _selected_clause_label(record: Dictionary) -> String:
	return String(record.get(
		"clause_label",
		"STANDARD TERMS" if StringName(record.get("clause_id", STANDARD_CLAUSE_ID)) == STANDARD_CLAUSE_ID else "NEGOTIATED RIDER",
	))


func _effective_offer_can_sign(offer: Dictionary, effective: Dictionary) -> bool:
	return (
		_offer_can_sign(offer)
		and not effective.is_empty()
		and _clause_is_available(effective)
		and bool(effective.get("can_sign", false))
	)


func _clause_is_available(option: Dictionary) -> bool:
	var clause_id := StringName(option.get("clause_id", option.get("id", STANDARD_CLAUSE_ID)))
	return clause_id == STANDARD_CLAUSE_ID or bool(option.get("clause_available", false))


func _find_offer(offer_id: StringName) -> Dictionary:
	if offer_id == &"":
		return {}
	for offer in _offers():
		if StringName(offer.get("id", offer.get("offer_id", &""))) == offer_id:
			return offer
	return {}


func _offer_can_sign(offer: Dictionary) -> bool:
	return (
		not offer.is_empty()
		and bool(_contract_board.get("unlocked", false))
		and bool(_contract_board.get("planning_open", false))
		and bool(offer.get("can_sign", false))
	)


func _first_offer_button() -> Button:
	for child: Node in _offer_cards.get_children():
		if child is Button:
			return child as Button
	return null


func _offer_card_text(offer: Dictionary, index: int) -> String:
	var name := String(offer.get("short_name", offer.get("name", "MUTUAL TERM"))).to_upper()
	var client := String(offer.get("client", "FARM MUTUAL")).to_upper()
	var mix := _lane_mix_label(offer.get("lane_mix", {}) as Dictionary)
	var rush_claims := maxi(0, int(offer.get("rush_claims", 0)))
	var availability := ""
	if bool(offer.get("on_cooldown", false)):
		availability = "\nCLIENT COOLDOWN  //  THROUGH DAY %d" % int(offer.get(
			"cooldown_until_day",
			_contract_board.get("target_day", 1),
		))
	return "%d  //  %s\n%s\n%s\nRUSH %d  //  +%s TOTAL  //  -%s BREACH%s" % [
		index + 1,
		name,
		client,
		mix,
		rush_claims,
		_money(_premium_total_cents(offer)),
		_money(int(offer.get("breach_cents", 0))),
		availability,
	]


func _offer_tooltip(offer: Dictionary) -> String:
	if offer.is_empty():
		return "Select a Farm Mutual client folder to inspect its complete terms."
	var lines: Array[String] = [
		String(offer.get("name", "FARM MUTUAL BINDER")).to_upper(),
		"CLIENT  //  %s" % String(offer.get("client", "FARM MUTUAL")).to_upper(),
		"LANE MIX  //  %s" % _lane_mix_label(offer.get("lane_mix", {}) as Dictionary),
		"ARRIVALS  //\n%s" % _arrival_schedule(offer),
		"SUCCESS  //  %s" % String(offer.get(
			"success_required",
			"Deliver %d qualifying folders on time." % int(offer.get("required_completed", 0)),
		)),
		"PREMIUM  //  %s" % _premium_breakdown(offer),
		"BREACH  //  -%s" % _money(int(offer.get("breach_cents", 0))),
		"RESERVE AFTER SIGNING  //  %s SPENDABLE" % _money(int(offer.get("spendable_after_reserve_cents", 0))),
		"FLOCK FIT  //  %d ACTIVE HENS  //  %d REQUIRED  //  %s" % [
			maxi(0, int(offer.get("active_staff_count", _contract_board.get("active_staff_count", 0)))),
			maxi(0, int(offer.get("required_active_staff", 0))),
			"READY" if bool(offer.get("staffing_ready", false)) else "HELD",
		],
	]
	var reason := String(offer.get("reason", ""))
	if not reason.is_empty():
		lines.append(
			"CLIENT COOLDOWN THROUGH DAY %d  //  %s" % [
				int(offer.get("cooldown_until_day", _contract_board.get("target_day", 1))),
				reason,
			]
			if bool(offer.get("on_cooldown", false)) else
			"SIGNATURE HELD  //  %s" % reason
		)
	return "\n".join(lines)


func _premium_base_cents(record: Dictionary) -> int:
	var bonus := maxi(0, int(record.get("service_coop_bonus_cents", 0)))
	return maxi(0, int(record.get(
		"base_premium_cents",
		maxi(0, int(record.get("premium_cents", 0)) - bonus),
	)))


func _premium_bonus_cents(record: Dictionary) -> int:
	return maxi(0, int(record.get("service_coop_bonus_cents", 0)))


func _premium_total_cents(record: Dictionary) -> int:
	return maxi(0, int(record.get(
		"premium_cents",
		_premium_base_cents(record) + _premium_bonus_cents(record),
	)))


func _premium_breakdown(record: Dictionary) -> String:
	var base := _premium_base_cents(record)
	var bonus := _premium_bonus_cents(record)
	var total := _premium_total_cents(record)
	var coop_level := maxi(0, int(record.get("service_coop_level_at_signing", 0)))
	var breakdown_value: Variant = record.get("premium_breakdown", {})
	var breakdown := breakdown_value as Dictionary if breakdown_value is Dictionary else {}
	var season_delta := int(record.get(
		"season_premium_delta_cents",
		record.get("season_premium_bonus_cents", breakdown.get("season_delta_cents", 0)),
	))
	var clause_delta := int(record.get(
		"clause_premium_delta_cents",
		record.get("clause_premium_bonus_cents", breakdown.get("clause_delta_cents", 0)),
	))
	if season_delta != 0 or clause_delta != 0:
		return "BASE %s  //  SEASON %s  //  RIDER %s  //  COOP L%d +%s  =  TOTAL %s" % [
			_money(base),
			_money_signed(season_delta),
			_money_signed(clause_delta),
			coop_level,
			_money(bonus),
			_money(total),
		]
	return "BASE %s  +  SERVICE COOP L%d %s  =  TOTAL %s" % [
		_money(base),
		coop_level,
		_money(bonus),
		_money(total),
	]


func _fit_breakdown(record: Dictionary) -> String:
	var capacity := maxi(0, int(_contract_board.get("claim_capacity", 0)))
	var outstanding := maxi(0, int(_contract_board.get("claims_outstanding", 0)))
	var slots := maxi(0, int(record.get("available_claim_slots", maxi(0, capacity - outstanding))))
	var required_capacity := maxi(0, int(record.get("required_claim_capacity", 0)))
	var total_claims := maxi(0, int(record.get("total_claims", 0)))
	var active_staff := maxi(0, int(record.get(
		"active_staff_count",
		_contract_board.get("active_staff_count", 0),
	)))
	var required_staff := maxi(0, int(record.get("required_active_staff", 0)))
	var staffing_ready := bool(record.get("staffing_ready", active_staff >= required_staff))
	return "ARCHIVE FIT  //  %d OPEN OF %d ROOSTS  //  %d FOLDERS  //  NEED %d\nFLOCK FIT  //  %d ACTIVE HENS  //  NEED %d  //  %s" % [
		slots,
		capacity,
		total_claims,
		required_capacity,
		active_staff,
		required_staff,
		"READY" if staffing_ready else "HELD",
	]


func _lane_mix_label(mix: Dictionary) -> String:
	var parts: Array[String] = []
	for lane in LANE_ORDER:
		var count := int(mix.get(String(lane), mix.get(lane, 0)))
		if count > 0:
			parts.append("%s %d" % [String(LANE_SHORT_NAMES[lane]), count])
	return "  //  ".join(parts) if not parts.is_empty() else "NO FOLDERS"


func _arrival_schedule(offer: Dictionary) -> String:
	var batches_value: Variant = offer.get("arrival_batches", [])
	var lines: Array[String] = []
	if batches_value is Array:
		for batch_value: Variant in batches_value as Array:
			if not batch_value is Dictionary:
				continue
			var batch := batch_value as Dictionary
			var mix_value: Variant = batch.get("lane_mix", {})
			var mix := mix_value as Dictionary if mix_value is Dictionary else {}
			lines.append("%s  //  %s  //  %s  //  DUE %s" % [
				String(batch.get("time", "TIME HELD")),
				_lane_mix_label(mix),
				"RUSH" if bool(batch.get("rush", false)) else "STANDARD",
				String(batch.get("deadline_time", "SHIFT CLOSE")),
			])
	if not lines.is_empty():
		return "\n".join(lines)
	var schedule := String(offer.get("arrival_schedule", "")).strip_edges()
	return schedule if not schedule.is_empty() else "No arrival batches were disclosed."


func _build_term_metric(
	parent: HFlowContainer,
	node_name: String,
	caption: String,
	value: String,
	accent: Color,
) -> Label:
	var card := PanelContainer.new()
	card.name = "%sCard" % node_name
	card.custom_minimum_size = Vector2(210.0, 68.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		_panel_style(Color("1c292e"), accent.darkened(0.15), 7, 1),
	)
	parent.add_child(card)
	_term_metric_cards.append(card)
	var stack := _panel_content(card, 12, 7, 1)
	var caption_label := _make_label(caption, 9, MUTED)
	stack.add_child(caption_label)
	var value_label := _make_label(value, 16, accent)
	value_label.name = node_name
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	stack.add_child(value_label)
	return value_label


func _apply_responsive_layout() -> void:
	if not _built or _panel == null or _center == null:
		return
	var viewport_size := size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = get_viewport_rect().size
	var panel_width := maxf(286.0, viewport_size.x - 52.0)
	var narrow := viewport_size.x < 720.0
	var compact := viewport_size.x < 1100.0
	var action_height := 178.0 if narrow else 74.0
	var content_height := maxf(240.0, viewport_size.y - action_height - 92.0)
	_scroll.offset_bottom = -(action_height + 8.0)
	_action_center.offset_top = -(action_height + 4.0)
	_action_center.offset_bottom = -18.0
	_center.custom_minimum_size = Vector2(panel_width, content_height)
	_panel.custom_minimum_size.x = minf(1040.0, panel_width)
	_action_panel.custom_minimum_size = Vector2(minf(1040.0, panel_width), action_height - 12.0)

	var available_inner_width := maxf(234.0, minf(1040.0, panel_width) - 76.0)
	_offer_section.custom_minimum_size.x = available_inner_width if compact else 304.0
	_detail_column.custom_minimum_size.x = available_inner_width if compact else 620.0
	_season_card.custom_minimum_size.x = available_inner_width if compact else 304.0
	_accreditation_card.custom_minimum_size.x = available_inner_width if compact else 620.0

	var folder_width := maxf(220.0, available_inner_width - 8.0) if compact else 292.0
	for button_value: Variant in _offer_buttons.values():
		var button := button_value as Button
		if button != null:
			button.custom_minimum_size.x = folder_width
	for card in _term_metric_cards:
		# Metric cards sit inside the Terms card, which itself sits inside the
		# board's padded enamel panel. Keep the portrait minimum small enough for
		# both real layers of paper/enamel margin rather than forcing x overflow.
		card.custom_minimum_size.x = 200.0 if narrow else 210.0
	_decline_button.custom_minimum_size.x = 260.0 if narrow else 238.0
	_sign_button.custom_minimum_size.x = 260.0 if narrow else 262.0
	_continue_button.custom_minimum_size.x = 260.0 if narrow else 274.0


func _reset_scroll() -> void:
	if _scroll != null:
		_scroll.scroll_vertical = 0


func _queue_focus(control: Control) -> void:
	if control == null or not control.is_visible_in_tree():
		return
	if control is BaseButton and (control as BaseButton).disabled:
		return
	call_deferred("_grab_focus_if_available", control)


func _grab_focus_if_available(control: Control) -> void:
	if control == null or not is_instance_valid(control) or not control.is_inside_tree():
		return
	if not control.is_visible_in_tree():
		return
	if control is BaseButton and (control as BaseButton).disabled:
		return
	control.grab_focus()


func _make_button(node_name: String, text: String, variation: StringName) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	return button


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _section_label(text: String) -> Label:
	var label := _make_label(text, 11, BRASS)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


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
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", separation)
	margin.add_child(stack)
	return stack


func _panel_style(
	background: Color,
	border: Color,
	radius: int,
	border_width: int,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _shortcut(keys: Variant) -> Shortcut:
	var shortcut := Shortcut.new()
	var normalized_keys: Array = keys if keys is Array else [keys]
	for key_value: Variant in normalized_keys:
		var event := InputEventKey.new()
		event.keycode = key_value as Key
		shortcut.events.append(event)
	return shortcut


func _safe_node_suffix(value: String) -> String:
	var safe := ""
	for character in value.to_lower():
		if character in "abcdefghijklmnopqrstuvwxyz0123456789_":
			safe += character
		else:
			safe += "_"
	return safe


func _money(cents: int) -> String:
	return "$%.2f" % (float(maxi(0, cents)) / 100.0)


func _money_signed(cents: int) -> String:
	return "%s$%.2f" % ["+" if cents >= 0 else "-", absf(float(cents)) / 100.0]
