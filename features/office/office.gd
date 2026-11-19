class_name Office
extends Node3D

const ChickenViewScript := preload("res://features/chickens/chicken_view.gd")
const PredatorEncounterScript := preload("res://features/predator/predator_encounter.gd")
const WorkstationScene := preload("res://assets/models/office_workstation.glb")
const SurfaceFinish := preload("res://features/office/office_surface_finish.gd")
const ManagementCameraControllerScript := preload("res://features/office/management_camera_controller.gd")
const ManagementPresenceScript := preload("res://features/management/management_presence.gd")
const WorkstationFeedbackScript := preload("res://features/office/workstation_feedback.gd")
const OfficeAtmosphereScript := preload("res://features/office/office_atmosphere.gd")
const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")
const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")
const ManagementUIThemeScript := preload("res://features/office/management_ui_theme.gd")
const OfficeAudioFeedbackScript := preload("res://features/office/office_audio_feedback.gd")
const OfficeAudioDirectorScript := preload("res://features/office/office_audio_director.gd")
const OfficeActionCatalogScript := preload("res://core/settings/office_action_catalog.gd")
const PlayerPreferencesStoreScript := preload("res://core/settings/player_preferences_store.gd")
const WebPreferencesMirrorScript := preload("res://core/settings/web_preferences_mirror.gd")
const FirstSessionFunnelScript := preload("res://core/experience/first_session_funnel.gd")
const ShiftContinuityScript := preload("res://core/experience/shift_continuity.gd")
const GameplayPulseDirectorScript := preload("res://core/experience/gameplay_pulse_director.gd")
const TacticalRoutePlannerScript := preload("res://core/experience/tactical_route_planner.gd")
const SettingsUIScript := "res://features/office/settings_ui.gd"
const PeckworkRoutingUIScript := preload("res://features/office/peckwork_routing_ui.gd")
const OpeningEggSlotsScript := preload("res://features/office/opening_egg_slots.gd")
const LoopReadability := preload("res://core/experience/loop_readability.gd")
const RoostStaffingUIScript := "res://features/office/roost_staffing_ui.gd"
const PeckingOrderUIScript := preload("res://features/office/pecking_order_ui.gd")
const FlockwatchNavigationScript := preload("res://features/office/flockwatch_navigation.gd")
const FlockwatchDisclosureToggleScript := preload("res://features/office/flockwatch_disclosure_toggle.gd")
const FlockwatchIconBadgeScript := preload("res://features/office/flockwatch_icon_badge.gd")
const EconomicBriefingUIScript := preload("res://features/office/economic_briefing_ui.gd")
const CapitalBlueprintModelScript := preload("res://features/office/capital_blueprint_model.gd")
const CapitalBlueprintUIScript := "res://features/office/capital_blueprint_ui.gd"
const CampusExpansionUIScript := "res://features/office/campus_expansion_ui.gd"
const CampusPortfolioUIScript := "res://features/office/campus_portfolio_ui.gd"
const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const CampusPortfolioVisualScript := preload("res://features/office/campus_portfolio_visual.gd")
const CommissioningRevealUIScript := "res://features/office/commissioning_reveal_ui.gd"
const CampusPortfolioRevealUIScript := "res://features/office/campus_portfolio_reveal_ui.gd"
const CampaignStateScript := preload("res://core/campaign/campaign_state.gd")
const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")
const CareerCommendationsScript := preload("res://core/campaign/career_commendations.gd")
const CareerRunArchiveScript := preload("res://core/campaign/career_run_archive.gd")
const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const CareerPortfolioStoreScript := preload("res://core/persistence/career_portfolio_store.gd")
const CheckpointCoordinatorScript := preload("res://core/persistence/checkpoint_coordinator.gd")
const ProbationCampaignUIScript := preload("res://features/office/probation_campaign_ui.gd")
const CharacterDialogueUIScript := preload("res://features/office/character_dialogue_ui.gd")
const HenSocialDirectorScript := preload("res://features/office/hen_social_director.gd")
const HenSocialUIScript := preload("res://features/office/hen_social_ui.gd")
const CharacterDialogueCatalogScript := preload("res://features/office/character_dialogue_catalog.gd")
const FEED_PARTY_STATION_PATH := "res://assets/models/feed_party_station.glb"
const CAMPAIGN_SAVE_FILENAME := "probation_campaign.json"
const CAMPAIGN_INTERFACE_CONTEXT_VERSION := 2
const OFFICE_WIDTH := 24.0
const OFFICE_DEPTH := 18.0
const MAIN_AISLE_Z := 7.15
const ACCESS_LANE_OFFSET := -1.95
const CHAIR_OFFSET_Z := -1.03
const DESK_COLUMNS := [-6.0, 0.0, 6.0]
const DESK_ROWS := [-2.8, 3.0]
# Simulation desk indices remain stable, but their physical sockets are ordered
# as a complete center/east pod before the two west-wing expansion perches. This
# lets the opening flock read as one team without migrating worker IDs or saves.
const DESK_SOCKET_ORDER := [
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(0, 0),
	Vector2i(0, 1),
]
const FEED_PARTY_STATION_POSITION := Vector3(-9.80, 0.0, 0.0)
const FEED_PARTY_STATION_SCALE := 0.78
const FEED_PARTY_DURATION := 5.0
const FEED_PARTY_ROLL_OFFSET := Vector3(0.0, 0.0, -2.35)
const FEED_PARTY_ROLL_DURATION := 0.82
const FEED_PARTY_WHEEL_TURNS := 3.0
const INITIAL_CAMPAIGN_STAFF := 4
const MAXIMUM_OFFICE_CAPACITY := 6
const WORKSTATION_STRUCTURAL_SHADOW_HOSTS := [
	"CubicleBack",
	"CubicleWing_L",
	"DeskSurface",
	"DrawerPedestal",
	"Monitor",
	"ChairSeat",
]
const CORE_OFFICE_STRUCTURAL_SHADOW_HOSTS := [
	"WaterCoolerBase",
	"WaterJug",
	"BreakroomKitchenCounter",
	"BreakroomSofaSeat",
	"Copier",
	"CopierLid",
	"ShredBin",
	"FileCabinet",
	"ArchiveBox",
	"PlantPot",
	"PlantStem",
	"SafetyExtinguisher",
]
const WEST_LEASE_STRUCTURAL_SHADOW_PREFIXES := [
	"WestLeasePartitionPanel_",
	"WestLeasePartitionPost_",
	"WestFlexMailTableTop",
	"WestFlexSupplyCabinetCarcass",
	"WestFlexFileCartBody",
	"WestFlexProjectTableTop",
	"WestFlexPlanningBoardPanel",
	"WestVisitorBenchSeat",
	"WestVisitorFileCredenzaBody",
]
const INTAKE_STRUCTURAL_SHADOW_HOSTS := [
	"IntakeCounter",
	"IntakeTop",
	"IntakeFrontInset",
	"EggScaleBase",
	"CandlingLampStem",
	"BasketInterior",
	"PresentationPlinth",
	"BasketFrontSlat",
	"BasketFrontSlatCreditHost",
	"BasketBackSlat",
	"BasketSideSlat",
	"BasketHandle",
	"BasketHandlePost",
]
const COLLECTION_STRUCTURAL_SHADOW_PREFIXES := [
	"DeskEggTray_",
	"EggLiftTube_",
	"OverheadRowRail_",
	"FarmerCreditRail",
	"PresentationDropTube",
	"EggQualityManifold",
	"EmptyTransitCarrier_",
	"ShellIntegrityGate",
	"GradingReceiptPrinterBody",
	"GradingReceiptPrinterMount",
	"EggCollectionCartBasket",
	"EggCollectionCartHandle",
]
const CAREER_DOCKET_SEEDS := [1701, 4703, 7919, 12011, 15013, 18041, 24029]
const PECK_ASSIST_ACTION: StringName = &"peck_assist"
const NEXT_MOMENT_ACTION: StringName = &"next_moment"
const CLUTCH_REWARD_THRESHOLDS := [2, 4, 8]
const CLUTCH_REWARD_LABELS := ["STEADY", "ROLLING", "GOLDEN RUN"]
const PECK_FOCUS_LEAD_PROGRESS := 16.0
const PECK_FOCUS_RESULT_HOLD_MSEC := 2500
const PECK_FOCUS_MISSED_HOLD_MSEC := 2500
const ADAPTIVE_ROUTE_MISS_THRESHOLD := 2
const ADAPTIVE_ROUTE_RECOVERY_HOLD_MSEC := 9000
const PREDATOR_DEBUG_ARGUMENT := "--enable-predator-debug"
const FIRST_CLUTCH_VERSION := 2
const FIRST_CLUTCH_COMPLETION_HOLD_SECONDS := 5.5
const STATUS_TOAST_HOLD_MSEC := 5500
const STATUS_HISTORY_LIMIT := 18
const DISPATCH_INTAKE_SOURCE := Vector3(9.45, 1.46, 5.05)
const CHECKPOINT_ERROR_LIMIT := 240
const WEB_DIAGNOSTIC_PAYLOAD_LIMIT_BYTES := 64 * 1024
const CAMPUS_PRESENTATION_REFRESH_MSEC := 500
const LIVE_HUD_HEIGHT := 92.0
const FIRST_CLUTCH_HUD_HEIGHT := 64.0
const LIVE_ROUTING_TOP := 100.0
const FIRST_CLUTCH_ROUTING_TOP := 72.0
const FIRST_HEN_WORKER_ID := 0
const CAPACITY_COMMISSIONING_HOLD_SECONDS := 0.72
const CAPACITY_COMMISSIONING_REVEAL_SECONDS := 0.34
const CAPACITY_COMMISSIONING_SETTLE_SECONDS := 0.28
const LOW_DIRECTIONAL_SHADOW_ATLAS_SIZE := 1024
const BALANCED_DIRECTIONAL_SHADOW_ATLAS_SIZE := 2048
const HIGH_DIRECTIONAL_SHADOW_ATLAS_SIZE := 4096
const LOW_WORKER_PRESENTATION_RATE_HZ := 20.0
const BALANCED_WORKER_PRESENTATION_RATE_HZ := 30.0
const HIGH_WORKER_PRESENTATION_RATE_HZ := 0.0
const EGG_FLECK_POOL_SIZE := 30
const EGG_FLECK_DURATION_SECONDS := 0.52
const FUND_CREDIT_CHIP_POOL_SIZE := 8
const FUND_CREDIT_CHIP_RISE_SECONDS := 0.16
const FUND_CREDIT_CHIP_TRAVEL_SECONDS := 0.54
const FUND_CREDIT_CHIP_MERGE_SECONDS := 0.12
const FUND_CREDIT_CHIP_SIZE := Vector2(224.0, 36.0)
const AUXILIARY_SETTLEMENT_CHIP_POOL_SIZE := 6
const AUXILIARY_SETTLEMENT_CHIP_RISE_SECONDS := 0.18
const AUXILIARY_SETTLEMENT_CHIP_TRAVEL_SECONDS := 0.62
const AUXILIARY_SETTLEMENT_CHIP_MERGE_SECONDS := 0.12
const AUXILIARY_SETTLEMENT_CHIP_SIZE := Vector2(224.0, 38.0)
const SETTLEMENT_FEEDBACK_EDGE_MARGIN := 18.0
const SETTLEMENT_FEEDBACK_SURFACE_GAP := 12.0
const SETTLEMENT_FEEDBACK_STACK_TOP_OFFSET := 141.0
const SETTLEMENT_FEEDBACK_STACK_BOTTOM_OFFSET := 18.0
const SETTLEMENT_FEEDBACK_MAX_DEFER_SECONDS := 9.0
const SETTLEMENT_ROUTE_HANDOFF_TIMEOUT_SECONDS := 2.4
const SETTLEMENT_DESTINATION_ACK_POOL_SIZE := 3
const SETTLEMENT_DESTINATION_ACK_IN_SECONDS := 0.16
const SETTLEMENT_DESTINATION_ACK_HOLD_SECONDS := 0.22
const SETTLEMENT_DESTINATION_ACK_OUT_SECONDS := 0.24
const SETTLEMENT_DESTINATION_ACK_MARGIN := 5.0
const FUND_DEBIT_CHIP_POOL_SIZE := 3
const FUND_DEBIT_CHIP_SIZE := Vector2(112.0, 32.0)
const FUND_DEBIT_LIFT_SECONDS := 0.14
const FUND_DEBIT_TRAVEL_SECONDS := 0.28
const FUND_DEBIT_HOLD_SECONDS := 0.12
const FUND_DEBIT_FADE_SECONDS := 0.18
const FIRST_CLUTCH_REINVESTMENT_KIND: StringName = &"first_clutch_reinvestment"
const SHIFT_END_FALLBACK_MINUTE := 24 * 60
const CORE_OVERVIEW_TARGET := Vector3(2.00, 0.65, -0.65)
# A slightly steeper management view exposes desk surfaces and seated bodies
# behind the fixed partitions. Home and inspection share this one orientation.
const CORE_OVERVIEW_POSITION := Vector3(19.30, 23.50, 20.85)
const CORE_OVERVIEW_SIZE := 19.0
const FIRST_HEN_FOCUS_SIZE := 6.3
const INSPECTED_CUBICLE_TRANSPARENCY := 0.58
const OFFICE_FILL_LIGHT_ENERGY := 0.24
# Camera bounds are presentation-only. The shell and every mature desk socket
# still exist, while capacity progressively reveals the west wing and its room.
const OPENING_OFFICE_CAMERA_BOUNDS := Rect2(Vector2(-7.5, -8.0), Vector2(19.0, 14.7))
const FIFTH_PERCH_CAMERA_BOUNDS := Rect2(Vector2(-8.4, -8.0), Vector2(19.9, 14.7))
const FIFTH_PERCH_OVERVIEW_SIZE := 20.75
const FULL_OFFICE_OVERVIEW_SIZE := 23.5
# The base frame is deliberately only the occupied bureau. Expansion visuals
# merge their own discovered/commissioned footprints into this rectangle later;
# an unopened parcel must never make a fresh file look like a mature campus.
const BASE_CAMPUS_BOUNDS := Rect2(Vector2(-12.0, -9.0), Vector2(24.0, 18.0))
const CAMPUS_PRESENTATION_MARGIN_RATIO := 1.10
const FLOCKWATCH_DRAWER_SAFE_RIGHT := 438.0
const EXPANDED_OVERVIEW_TARGET := Vector3(7.72, 0.65, 15.10)
const PACKING_ANNEX_FOCUS := Vector3(15.20, 0.90, -6.00)
const RECORDS_ANNEX_FOCUS := Vector3(15.20, 0.90, 0.00)
const FARM_MUTUAL_SERVICE_COOP_FOCUS := Vector3(15.20, 1.05, 6.00)
const FARM_MUTUAL_NEGOTIATION_ROOM_FOCUS := Vector3(15.20, 1.10, 12.00)
const FARM_MUTUAL_BOARD_FOCUS := Vector3(-11.46, 2.08, 0.00)
const WELLNESS_NEST_FOCUS := Vector3(15.20, 1.05, 18.00)
const TRAINING_ROOST_FOCUS := Vector3(15.20, 1.05, 24.00)
const CARE_CAMPUS_FOCUS := Vector3(15.20, 1.05, 21.00)
const FARMER_RELATIONS_GALLERY_FOCUS := Vector3(7.30, 1.50, 24.00)
const ROOSTER_OPERATIONS_OFFICE_FOCUS := Vector3(15.20, 1.05, 30.00)
const IT_COOP_FOCUS := Vector3(15.20, 1.05, 36.00)
const OPERATIONS_CAMPUS_FOCUS := Vector3(15.20, 1.05, 33.00)
const FLOCK_RELATIONS_OFFICE_FOCUS := Vector3(7.30, 1.05, 36.00)
const FLOCK_PROVISIONS_COOP_FOCUS := Vector3(7.30, 1.50, 30.00)
const GOVERNANCE_CAMPUS_FOCUS := Vector3(11.25, 1.05, 30.00)
const FARMGATE_DISPATCH_DEPOT_FOCUS := Vector3(23.05, 1.25, -3.00)
const NORTH_MEADOW_FOCUS := Vector3(25.05, 1.15, 9.00)
const CAMPUS_PORTFOLIO_FOCUS := Vector3(25.05, 1.30, 27.00)
const ORCHARD_ROW_FOCUS := Vector3(25.05, 1.20, 21.00)
const CREEKSIDE_YARD_FOCUS := Vector3(25.05, 1.20, 33.00)
const CAMPUS_ROUTING_POD_ID: StringName = &"egg_routing_pod"
const CAMPUS_COMMUTE_SPINE_X := 11.25
const CAMPUS_COMMUTE_SPINE_ENTRY_Z := 8.70
const CAMPUS_COMMUTE_NORTH_BYPASS_Z := 39.65
const CAMPUS_COMMUTE_EAST_BYPASS_X := 32.15
const CAMPUS_COMMUTE_ORCHARD_ROUTE_Z := 16.40
const CAMPUS_COMMUTE_CREEKSIDE_ROUTE_Z := 28.40
const DIRECTIVE_ORDER_FIT_RULES := {
	&"record_harvest": {
		"supports": [&"eggs", &"quota_met", &"overdue_files"],
		"risks": [&"crack_rate_basis_points", &"welfare"],
		"long_term": "MORE EGGS + FEWER WAITING FILES",
	},
	&"shell_assurance": {
		"supports": [&"crack_rate_basis_points", &"rework", &"compliance"],
		"risks": [&"eggs", &"quota_met", &"overdue_files"],
		"long_term": "FEWER CRACKS + BETTER COMPLIANCE",
	},
	&"sustainable_flock": {
		"supports": [&"welfare"],
		"risks": [&"eggs", &"quota_met", &"overdue_files"],
		"long_term": "CALMER HENS + FASTER RECOVERY",
	},
}


class EggFleckVisual extends RefCounted:
	var node: MeshInstance3D
	var active := false
	var origin := Vector3.ZERO
	var destination := Vector3.ZERO
	var start_scale := Vector3.ONE
	var elapsed := 0.0


class FundCreditChipVisual extends RefCounted:
	var panel: PanelContainer
	var label: Label
	var pool_index := -1
	var active := false
	var start_position := Vector2.ZERO
	var rise_position := Vector2.ZERO
	var target_position := Vector2.ZERO
	var value_cents := 0
	var quality: StringName = &"sound"
	var quality_counts: Dictionary = {}
	var egg_count := 0
	var elapsed := 0.0
	var capture_staged := false
	var desired_source_center := Vector2.ZERO
	var safe_source_center := Vector2.ZERO
	var placement_clamped := false
	var deferred := false
	var deferred_elapsed := 0.0
	var deferred_reason: StringName = &""
	var released_after_defer := false
	var release_serial := 0


class AuxiliarySettlementChipVisual extends RefCounted:
	var panel: PanelContainer
	var label: Label
	var pool_index := -1
	var active := false
	var kind: StringName = &"stock"
	var start_position := Vector2.ZERO
	var rise_position := Vector2.ZERO
	var target_position := Vector2.ZERO
	var value_cents := 0
	var item_count := 0
	var charges_after := 0
	var quality: StringName = &"sound"
	var quality_counts: Dictionary = {}
	var elapsed := 0.0
	var capture_staged := false
	var desired_source_center := Vector2.ZERO
	var safe_source_center := Vector2.ZERO
	var placement_clamped := false
	var deferred := false
	var deferred_elapsed := 0.0
	var deferred_reason: StringName = &""
	var released_after_defer := false
	var release_serial := 0


class SettlementDestinationAckVisual extends RefCounted:
	var panel: Panel
	var glyph: Label
	var pool_index := -1
	var kind: StringName = &""
	var active := false
	var serial := 0
	var merge_count := 0
	var item_count := 0
	var value_cents := 0
	var charges_after := 0
	var release_serial := 0
	var target_id: StringName = &""
	var target_name := ""
	var target_rect := Rect2()
	var accessible_text := ""
	var capture_staged := false
	var tween: Tween


class FundDebitChipVisual extends RefCounted:
	var panel: PanelContainer
	var label: Label
	var pool_index := -1
	var active := false
	var serial := 0
	var merge_count := 0
	var cost_cents := 0
	var transaction_kind: StringName = &""
	var target_id: StringName = &""
	var target_name := ""
	var source_center := Vector2.ZERO
	var target_center := Vector2.ZERO
	var capture_staged := false
	var accessible_text := ""
	var tween: Tween


var _simulation := DepartmentSimulation.new(1701, INITIAL_CAMPAIGN_STAFF)
var _clock := SimulationClock.new()
var _worker_views: Dictionary[int, ChickenView] = {}
var _departing_worker_views: Dictionary[int, ChickenView] = {}
var _intent_focus_worker_id := -1
var _predator_removed_worker_ids: Dictionary[int, bool] = {}
var _predator_encounter: PredatorEncounter
var _desk_positions: Array[Vector3] = []
var _workers_node: Node3D
var _workstations_by_index: Dictionary[int, Node3D] = {}
var _capacity_markers_by_index: Dictionary[int, Node3D] = {}
var _workstation_nameplates: Dictionary[int, Label3D] = {}
var _displayed_office_capacity := -1
var _capacity_commissioning_root: Node3D
var _capacity_commissioning_tween: Tween
var _capacity_stage_tween: Tween
var _capacity_commissioning_state: Dictionary = {
	"active": false,
	"phase": &"idle",
	"capacity": 0,
	"perch_index": -1,
	"cost_cents": 0,
	"added_daily_operating_cents": 0,
	"reduced_motion": false,
}
var _workstation_nameplate_fingerprint := -1
var _campus_bounds_fingerprint := -1
var _capacity_marker_context_revealed := false
var _office_physical_presentation: Node3D
var _core_office_presentation: Node3D
var _west_lease_partition: Node3D
var _west_second_perch_flex_furnishings: Node3D
var _dormant_west_presentation: Node3D
var _west_perch_04_presentation: Node3D
var _west_perch_05_presentation: Node3D
var _archive_presentation: Node3D
var _intake_presentation: Node3D
var _egg_layer: Node3D
var _egg_fleck_pool: Array[EggFleckVisual] = []
var _active_egg_flecks: Array[EggFleckVisual] = []
var _fund_credit_chip_pool: Array[FundCreditChipVisual] = []
var _active_fund_credit_chips: Array[FundCreditChipVisual] = []
var _fund_credit_batch_serial := 0
var _auxiliary_settlement_chip_pool: Array[AuxiliarySettlementChipVisual] = []
var _active_auxiliary_settlement_chips: Array[AuxiliarySettlementChipVisual] = []
var _auxiliary_settlement_batch_serial := 0
var _stock_chip_style: StyleBoxFlat
var _refund_chip_style: StyleBoxFlat
var _last_settlement_feedback_placement: Dictionary = {}
var _settlement_feedback_deferred_total := 0
var _settlement_feedback_released_total := 0
var _settlement_feedback_suppressed_total := 0
var _settlement_feedback_last_suppressed: Array[Dictionary] = []
var _settlement_feedback_release_serial := 0
var _settlement_feedback_release_cue_count := 0
var _settlement_feedback_last_release: Dictionary = {}
var _settlement_feedback_route_handoff_serial := 0
var _settlement_feedback_route_handoff: Dictionary = {}
var _settlement_feedback_last_route_handoff: Dictionary = {}
var _settlement_destination_ack_pool: Array[SettlementDestinationAckVisual] = []
var _settlement_destination_ack_by_kind: Dictionary[StringName, SettlementDestinationAckVisual] = {}
var _settlement_destination_ack_styles: Dictionary[StringName, StyleBoxFlat] = {}
var _settlement_destination_ack_serial := 0
var _settlement_destination_ack_total := 0
var _settlement_destination_ack_merged_total := 0
var _settlement_destination_ack_last_by_kind: Dictionary = {}
var _fund_debit_chip_pool: Array[FundDebitChipVisual] = []
var _fund_debit_serial := 0
var _fund_debit_started_total := 0
var _fund_debit_merged_total := 0
var _fund_debit_recycled_total := 0
var _fund_debit_last_receipt: Dictionary = {}
var _feed_party_station: Node3D
var _feed_party_tween: Tween
var _feed_party_wheels: Array[Node3D] = []
var _feed_party_active: bool = false
var _feed_party_previous_speed: int = 1
var _feed_party_release_scheduled: bool = false
var _feed_party_arrivals: Dictionary[int, bool] = {}
var _feed_party_returns: Dictionary[int, bool] = {}
var _feed_party_expected_attendees: Dictionary[int, bool] = {}
var _breakroom_life_elapsed := 0.0
var _breakroom_cooler_bubbles: Array[Node3D] = []
var _breakroom_coffee_steam: Array[Node3D] = []
var _breakroom_plant_leaves: Array[Node3D] = []
var _breakroom_plant_leaf_rest_rotations: Array[Vector3] = []
var _breakroom_pinned_notes: Array[Node3D] = []
var _breakroom_lounge_pouf: Node3D
var _breakroom_lounge_pouf_rest_y := 0.14
var _breakroom_magazine: Node3D
var _breakroom_magazine_pages: Node3D
var _campus_worker_assignments: Dictionary[int, StringName] = {}
var _campus_worker_pads: Dictionary[int, StringName] = {}
var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _environment: Environment
var _office_sun: DirectionalLight3D
var _bounce_light: DirectionalLight3D
var _office_fill_lights: Array[OmniLight3D] = []
var _directional_shadow_atlas_size := HIGH_DIRECTIONAL_SHADOW_ATLAS_SIZE
var _worker_presentation_rate_hz := HIGH_WORKER_PRESENTATION_RATE_HZ
var _management_camera: Camera3D
var _camera_controller: ManagementCameraController
var _management_presence: ManagementPresence
var _workstation_feedback: WorkstationFeedback
var _office_atmosphere: OfficeAtmosphere
var _office_storytelling: OfficeStorytelling
var _audio_feedback: Node
var _audio_director: Node
var _routing_ui: PeckworkRoutingUI
var _routing_assignment_undo: Dictionary = {}
var _tactical_route_planner = TacticalRoutePlannerScript.new()
var _adaptive_route_miss_streak := 0
var _adaptive_route_last_miss_at_msec := 0
var _adaptive_route_recovery: Dictionary = {}
var _dispatch_lane: StringName = &""
var _dispatch_candidates: Array[Dictionary] = []
var _dispatch_file_preview: Dictionary = {}
var _dispatch_recommended_worker_id := -1
var _dispatch_momentum_chain := 0
var _dispatch_last_day := -1
var _dispatch_last_receipt: Dictionary = {}
var _last_cause_replay: Dictionary = {}
var _cause_replay_serial := 0
var _dispatch_reward_label := ""
var _last_team_lift_authority_key := ""
var _last_team_lift_presentation: Dictionary = {}
var _last_routing_mastery_authority_key := ""
var _last_routing_mastery_presentation: Dictionary = {}
var _routing_mastery_presentation_serial := 0
var _routing_return_cue: Dictionary = {}
var _routing_return_cue_serial := 0
var _last_routing_return_cue_dismissal: Dictionary = {}
var _staffing_ui: Variant
var _defer_management_ui := OS.has_feature("web")
var _pecking_order_ui
var _flockwatch_navigation: FlockwatchNavigation
var _economic_briefing_ui
var _capital_blueprint_ui: Control
var _campus_portfolio_ui: Control
var _campus_expansion_ui: Control
var _commissioning_reveal_ui: Control
var _campus_portfolio_reveal_ui: Control
var _capital_blueprint_restore_review := false
var _capital_blueprint_restore_flockwatch := false
var _campus_expansion_restore_portfolio := false
var _capital_modal_previous_speed := 0
var _capital_modal_holds_speed := false
var _pending_campus_portfolio_reveals: Array[Dictionary] = []
var _last_reviewed_day: int = 1
var _campaign_state: CampaignStateScript = CampaignStateScript.new()
var _senior_roost_state: SeniorRoostStateScript = SeniorRoostStateScript.new()
var _campaign_store = CampaignSaveStoreScript.new(CAMPAIGN_SAVE_FILENAME)
var _career_portfolio_store = CareerPortfolioStoreScript.new()
var _active_career_slot: StringName = &"roost_a"
var _career_profile: Dictionary = CareerPortfolioStoreScript.identity(&"open_nest")
var _selected_replay_scenario_id: StringName = &"baseline_book"
var _career_run_archive = CareerRunArchiveScript.new()
var _current_campaign_run_id := ""
var _checkpoint_coordinator: CheckpointCoordinatorScript = CheckpointCoordinatorScript.new()
var _has_campaign_checkpoint_candidate := false
var _has_verified_campaign_checkpoint := false
var _checkpoint_last_error := ""
var _checkpoint_last_saved_reason := ""
var _checkpoint_last_saved_unix_msec: int = 0
var _web_checkpoint_flush_callback
var _web_career_backup_offer_callback
var _web_mobile_action_callback
var _web_focus_pause_callback
var _web_diagnostic_request_callback
var _web_accessibility_request_callback
var _first_session_funnel: FirstSessionFunnelScript = FirstSessionFunnelScript.new()
var _gameplay_pulse_director: GameplayPulseDirectorScript = GameplayPulseDirectorScript.new()
var _gameplay_pulse_timing: Dictionary = {}
var _preview_runner: RefCounted
var _defer_capital_planning := OS.has_feature("web")
var _gameplay_pulse: Dictionary = {}
var _last_lifecycle_checkpoint_frame: int = -1
var _last_lifecycle_checkpoint_revision: int = -1
var _campaign_session_checkpoint_enabled := false
var _applying_campaign_interface_context := false
var _preferences_store = PlayerPreferencesStoreScript.new()
var _web_preferences_mirror: WebPreferencesMirrorScript = WebPreferencesMirrorScript.new()
var _web_preferences_mirror_status := "not_applicable"
var _player_preferences: Dictionary = {}
var _campaign_ui: ProbationCampaignUI
var _campaign_review_stage: StringName = &"active"
var _last_workday_report: Dictionary = {}
var _campaign_senior_roost: bool = false
var _allow_automated_campaign_saves: bool = false
var _first_clutch: Dictionary = {
	"version": FIRST_CLUTCH_VERSION,
	"dismissed": true,
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
	"delivered_claim_id": -1,
	"delivered_quality": "",
	"delivered_value_cents": 0,
	"delivered_priority_credit_cents": 0,
	"potential_priority_credit_cents": 0,
	"prior_presentations_pending": 0,
	"reinvestment_grandfathered": false,
}
var _first_clutch_completion_hold_until_msec: int = 0
var _first_reward_ready_msec: int = 0
var _first_clutch_completion_generation: int = 0
var _eggs_in_flight_by_worker: Dictionary[int, int] = {}
# Physical eggs can overlap at high simulation speed. Preserve every completion
# in FIFO order so the basket callback settles the exact assisted claim that
# authored that egg instead of guessing from the worker's newer active file.
var _collection_claim_ids_by_worker: Dictionary[int, Array] = {}
var _collection_cash_by_claim_id: Dictionary[int, int] = {}
var _collection_stocked_by_claim_id: Dictionary[int, bool] = {}
var _egg_journey_receipts: Array[Dictionary] = []
var _egg_journey_receipt_serial := 0
var _first_clutch_global_cued_control: Button
var _first_clutch_global_cue_tween: Tween

var _day_label: Label
var _time_label: Label
var _revenue_label: Label
var _today_workload_label: Label
var _today_clutch_label: Label
var _today_flock_label: Label
var _today_ledger_label: Label
var _today_glance_grid: GridContainer
var _today_workload_glance: Label
var _today_clutch_glance: Label
var _today_flock_glance: Label
var _today_cash_glance: Label
var _break_even_tracker_day := -1
var _break_even_previous_margin_cents := 0
var _break_even_tracker_seeded := false
var _break_even_cleared_day := -1
var _today_precedent_label: Label
var _campaign_objectives_label: Label
var _campaign_orders_heading_label: Label
var _campaign_orders_glance_grid: GridContainer
var _campaign_order_glances: Array[Label] = []
var _focused_campaign_order_id: StringName = &""
var _campaign_order_focus_serial := 0
var _campaign_order_driver_button: Button
var _campaign_order_driver_icon: FlockwatchIconBadge
var _campaign_order_driver_label: Label
var _campaign_order_driver_action: Dictionary = {}
var _campaign_order_driver_activation_serial := 0
var _last_campaign_order_driver_result: Dictionary = {}
var _campaign_order_page_arrival_target: Control
var _campaign_order_page_arrival_target_name := ""
var _campaign_order_page_arrival_page_id: StringName = &""
var _campaign_order_page_arrival_serial := 0
var _campaign_order_page_arrival_active := false
var _campaign_order_page_arrival_animated := false
var _campaign_order_page_arrival_reduced_motion := false
var _campaign_order_page_arrival_pinned := false
var _campaign_order_page_arrival_tween: Tween
var _campaign_order_page_arrival_original_style: StyleBox
var _campaign_order_page_arrival_had_panel_override := false
var _campaign_order_return_cue: Dictionary = {}
var _campaign_order_return_serial := 0
var _campaign_order_return_activation_serial := 0
var _last_campaign_order_return_result: Dictionary = {}
var _campaign_order_cause_receipts: Dictionary = {}
var _campaign_order_cause_serial := 0
var _campaign_order_cause_activation_serial := 0
var _last_campaign_order_cause_focus_result: Dictionary = {}
var _campaign_order_pointer_armed_id: StringName = &""
var _campaign_doctrine_label: Label
var _campaign_safeguards_label: Label
var _campaign_safeguard_glance: Label
var _flock_labor_label: Label
var _flock_labor_glance_grid: GridContainer
var _flock_compact_glance: Label
var _work_to_rule_glance: Label
var _records_archive_label: Label
var _commendations_disclosure_toggle
var _commendations_summary_label: Label
var _commendation_rows: Dictionary[StringName, Dictionary] = {}
var _commendation_earned_style: StyleBoxFlat
var _commendation_locked_style: StyleBoxFlat
var _commendations_snapshot: Dictionary = {}
var _commendations_source_fingerprint := -1
var _commendations_seeded := false
var _known_commendation_ids: Dictionary[StringName, bool] = {}
var _overtime_button: Button
var _ticker_label: Label
var _ticker_panel: PanelContainer
var _ticker_last_text := ""
var _ticker_last_accessible_text := ""
var _ticker_last_publish_msec := -1
var _ticker_visible_copy := ""
var _ticker_visible_accessible_text := ""
var _ticker_hide_at_msec: int = 0
var _ticker_shown_at_msec: int = 0
var _status_history: Array[String] = []
var _status_history_label: Label
var _status_history_toggle: Button
var _status_history_expanded := false
var _flockwatch_panel: PanelContainer
var _flockwatch_toggle: Button
var _settings_button: Button
var _settings_ui: Variant
var _settings_previous_speed: int = 0
var _settings_holds_speed: bool = false
var _settings_prior_focus_owner: Control
var _focus_pause_active: bool = false
var _focus_pause_previous_speed: int = 0
var _character_dialogue_previous_speed: int = -1
var _flockwatch_open: bool = false
var _flockwatch_prior_focus_owner: Control
var _speed_control: HBoxContainer
var _speed_buttons: Array[Button] = []
var _next_moment_button: Button
var _next_moment_active := false
var _next_moment_previous_speed := 1
var _next_moment_stop_reason := ""
var _priority_peck_focus_worker_id := -1
var _priority_peck_result_hold_until_msec := 0
var _priority_peck_result_hold_worker_id := -1
var _priority_peck_result_hold_claim_id := -1
var _priority_peck_result_hold_kind: StringName = &""
var _priority_peck_focus_disarmed_worker_id := -1
var _priority_peck_result_audio_pending: Dictionary[int, Dictionary] = {}
var _priority_peck_opportunity_audio_key := ""
var _priority_peck_opportunity_audio_state: StringName = &""
var _last_work_progress_action: Dictionary = {}
var _work_progress_context_suppressed_worker_id := -1
var _ui_root: Control
var _shift_challenge_ui: ShiftChallengeUI
var _celebrated_shift_challenge := ""
var _show_other_playbook_actions := false
var _character_dialogue_ui: CharacterDialogueUIScript
var _hen_social := HenSocialDirectorScript.new()
var _hen_social_ui: HenSocialUI
var _flock_ties_ui: FlockTiesUI
var _hen_social_workers: Array = []
var _character_dialogue_previous_snapshot: Dictionary = {}
var _top_hud_panel: PanelContainer
var _shift_objective_row: HBoxContainer
var _compact_live_hud_applied := false
var _compact_physical_hud := false
var _hud_measure_elapsed := 0.5
var _hud_canvas_ratio := 1.0
var _hud_layout_key := ""
var _hud_top_bar: HBoxContainer
var _hud_controls_row: HBoxContainer
var _compact_speed_menu: MenuButton
var _shift_clock_status_host: HBoxContainer
var _shift_clock_status_icon: FlockwatchIconBadge
var _fund_status_host: HBoxContainer
var _fund_status_icon: FlockwatchIconBadge
var _shift_goal_status_host: HBoxContainer
var _shift_goal_status_icon: FlockwatchIconBadge
var _shift_egg_goal_label: Label
var _quota_progress: ProgressBar
var _quota_progress_label: Label
var _opening_egg_slots: Control
var _opening_header_goal: HBoxContainer
var _opening_header_slots: Control
var _opening_header_label: Label
var _live_title_label: Label
var _upgrade_demonstration: Dictionary = {}
var _payoff_quiet_until_msec: int = 0
var _quality_streak_label: Label
var _clutch_carton_host: HBoxContainer
var _clutch_carton_icons: Array[FlockwatchIconBadge] = []
var _directive_badge_host: HBoxContainer
var _directive_badge_icon: FlockwatchIconBadge
var _directive_badge: Label
var _core_loop_host: HBoxContainer
var _core_loop_icons: Array[FlockwatchIconBadge] = []
var _reward_loop_host: HBoxContainer
var _reward_loop_icons: Dictionary[StringName, FlockwatchIconBadge] = {}
var _active_playbook_button: MenuButton
var _active_playbook_menu_map: Dictionary[int, Dictionary] = {}
var _active_playbook_menu_state: Array = []
var _active_playbook_menu_build_count := 0
var _active_playbook_focused_worker_id := -1
var _rival_pulse_label: Label
var _guidance_action_button: Button
var _guidance_icon: FlockwatchIconBadge
var _guidance_label: Label
var _consequence_icon_host: HBoxContainer
var _consequence_icons: Array[FlockwatchIconBadge] = []
var _guidance_action_chevron: Label
var _guidance_action_id: StringName = &""
var _explain_strip: PanelContainer
var _explain_chip_labels: Array[Label] = []
var _explain_mode_active := false
var _explain_previous_speed := 0
var _last_shift_rhythm_stage: StringName = &""
var _decision_before_snapshot: Dictionary = {}
var _latest_action_outcome_receipt: Dictionary = {}
var _active_action_outcome_panels: Array[Control] = []
var _latest_notification_handoff: Dictionary = {}
var _feed_button: Button
var _upgrade_buttons: Dictionary[StringName, Button] = {}
var _upgrade_disclosure_toggle
var _shift_help_disclosure_toggle
var _had_actionable_upgrade := false
var _day_review_panel: PanelContainer
var _day_review_scrim: ColorRect
var _held_confirmation_scrim: ColorRect
var _review_title: Label
var _review_summary: Label
var _review_eggs_value: Label
var _review_net_value: Label
var _review_fund_value: Label
var _review_next_value: Label
var _shift_continuity: Dictionary = {}
var _review_next_hint: Label
var _personal_goal_button: Button
var _personal_goal: Dictionary = {}
var _personal_goal_offer: Dictionary = {}
var _context_hover_copy := ""
var _context_hover_previous := ""
var _last_optional_floor_beat_msec := -8000
const PersonalShiftGoal := preload("res://core/experience/personal_shift_goal.gd")
var _review_results: Label
var _review_details_toggle: Button
var _review_details_scroll: ScrollContainer
var _review_details_expanded := false
var _review_story: Label
var _review_replay_button: Button
var _review_remix_button: Button
var _review_remix_index := -1
var _continue_shift_button: Button
var _begin_next_shift_button: Button
var _decision_host: Control
var _decision_panel: PanelContainer
var _decision_eyebrow: Label
var _decision_title: Label
var _decision_body: Label
var _decision_petition_glance: GridContainer
var _decision_petition_tiles: Array[PanelContainer] = []
var _decision_petition_values: Array[Label] = []
var _decision_petition_captions: Array[Label] = []
var _decision_petition_semantics: Label
var _decision_order_heading: Label
var _decision_order_glance: GridContainer
var _decision_order_tiles: Array[PanelContainer] = []
var _decision_order_values: Array[Label] = []
var _decision_order_captions: Array[Label] = []
var _decision_options: GridContainer
var _decision_preview: Label
var _decision_confirm_button: Button
var _decision_stay_paused_button: Button
var _decision_option_buttons: Array[Button] = []
var _active_decision: Dictionary = {}
var _selected_decision_option: StringName = &""
var _decision_previous_speed := 1
var _resume_after_decision := true
var _decision_restore_farmer_review := false
var _flockwatch_restore_farmer_review := false
var _flockwatch_restore_campaign_report := false
var _authoritative_revenue_cents := 0
var _displayed_revenue_cents := -1
var _pending_collection_cents := 0
var _fund_visual_target_cents := -1
var _fund_counter_active := false
var _fund_counter_start_cents := 0
var _fund_counter_duration := 0.0
var _fund_counter_elapsed := 0.0
var _animation_speed_multiplier := 1.0
var _pending_web_diagnostic_snapshot: Dictionary = {}
var _web_diagnostic_dirty := false
var _pending_simulation_presentation_snapshot: Dictionary = {}
var _presentation_update_count := 0
var _snapshot_presentation_usec := 0
var _snapshot_presentation_timing: Dictionary = {}
var _last_presented_tick_revision := 0
var _campus_presentation_fingerprint := 0
var _staffing_presentation_fingerprint := 0
var _next_campus_presentation_refresh_msec := 0
var _boot_started_msec := 0
var _boot_timing: Dictionary = {}
var _web_bridge: OfficeWebBridge = OfficeWebBridge.new(self)
var _environment_builder: OfficeEnvironmentBuilder = OfficeEnvironmentBuilder.new(self)
var _review_presenter: OfficeReviewPresenter = OfficeReviewPresenter.new(self)
var _first_clutch_coach: OfficeFirstClutchCoach = OfficeFirstClutchCoach.new(self)
var _pulse_presenter: OfficePulsePresenter = OfficePulsePresenter.new(self)
var _decision_presenter: OfficeDecisionPresenter = OfficeDecisionPresenter.new(self)
var _guidance_presenter: OfficeGuidancePresenter = OfficeGuidancePresenter.new(self)


func _ready() -> void:
	_boot_started_msec = Time.get_ticks_msec()
	_boot_mark(&"entry")
	name = "CorporateClaimsDivision"
	# Focused persistence tests inject an isolated save store before entering the
	# tree. Preserve that explicit authority instead of silently switching them to
	# a player roost; ordinary native/Web launches always load the portfolio.
	if not (_allow_automated_campaign_saves and DisplayServer.get_name() == "headless"):
		_load_career_portfolio()
	# Envelope validity is enough to offer Continue, but it is not proof that the
	# nested campaign, simulation, and Senior ledgers can activate together.
	_has_campaign_checkpoint_candidate = _campaign_store != null and _campaign_store.has_save()
	_has_verified_campaign_checkpoint = false
	_install_web_checkpoint_bridge()
	_ensure_peck_assist_input_action()
	_ensure_explain_input_action()
	_ensure_manager_power_input_action()
	_load_player_preferences()
	_boot_mark(&"preferences")
	_build_environment()
	_boot_mark(&"environment")
	_build_office()
	_boot_mark(&"office")
	_predator_encounter = PredatorEncounterScript.new() as PredatorEncounter
	_predator_encounter.victim_carried_away.connect(_on_predator_victim_carried_away)
	_predator_encounter.victim_captured.connect(_on_predator_victim_captured)
	add_child(_predator_encounter)
	_office_storytelling = OfficeStorytellingScript.new() as OfficeStorytelling
	_office_storytelling.set_lazy_hidden_optional_visuals(OS.has_feature("web"))
	_office_storytelling.set_office_physical_presentation(
		_office_capacity_from_snapshot(_simulation.snapshot()),
		_capacity_marker_context_revealed,
	)
	_office_storytelling.configure(
		_active_desk_positions(_office_capacity_from_snapshot(_simulation.snapshot())),
		Vector3(9.55, 0.0, 5.35),
		Vector3(9.4, 0.0, -6.85),
	)
	_office_storytelling.apply_career_profile(_career_profile)
	_office_storytelling.apply_scenario_mastery(_career_run_archive.comparison())
	_office_storytelling.egg_graded.connect(_on_egg_graded)
	_office_storytelling.egg_reached_presentation_detailed.connect(_on_egg_reached_presentation)
	_office_storytelling.optional_visuals_finished.connect(_on_optional_storytelling_finished)
	add_child(_office_storytelling)
	_apply_opening_story_shadow_budget()
	var animated_decor: Array[Node3D] = []
	animated_decor.append_array(_breakroom_cooler_bubbles)
	animated_decor.append_array(_breakroom_coffee_steam)
	animated_decor.append_array(_breakroom_plant_leaves)
	animated_decor.append_array(_breakroom_pinned_notes)
	for moving_prop in [_breakroom_lounge_pouf, _breakroom_magazine, _breakroom_magazine_pages, _west_lease_partition]:
		if moving_prop != null:
			animated_decor.append(moving_prop)
	set_meta("static_office_batch", StaticOfficeBatch.build(_core_office_presentation, animated_decor))
	_boot_mark(&"storytelling")
	_office_atmosphere = OfficeAtmosphereScript.new() as OfficeAtmosphere
	add_child(_office_atmosphere)
	EnvironmentalSignageScript.set_camera_detail(
		self, false, Vector3(INF, INF, INF), EnvironmentalSignageScript.FOCUSED_DETAIL_RADIUS, false
	)
	_audio_feedback = OfficeAudioFeedbackScript.new()
	add_child(_audio_feedback)
	_audio_director = OfficeAudioDirectorScript.new()
	add_child(_audio_director)
	_boot_mark(&"audio")
	_build_ui()
	_build_fund_credit_chip_pool()
	_build_auxiliary_settlement_chip_pool()
	_build_settlement_destination_ack_pool()
	_build_fund_debit_chip_pool()
	_boot_mark(&"ui")
	_apply_player_preferences()

	add_child(_clock)
	if OS.has_feature("web"):
		_simulation.cost_probe.enabled = bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('profile_costs') === '1'"))
	_clock.initialize(_simulation)
	_clock.speed_changed.connect(_on_speed_changed)
	_clock.tick_batch_completed.connect(_on_clock_tick_batch_completed)
	_simulation.snapshot_changed.connect(_on_snapshot_changed)
	_simulation.egg_laid_detailed.connect(_on_egg_laid)
	_simulation.announcement_posted.connect(_on_announcement_posted)
	_simulation.pair_reward_earned.connect(_on_pair_reward_earned)
	_simulation.feed_party_funded.connect(_on_feed_party_funded)
	_simulation.workday_completed.connect(_on_workday_completed)
	_simulation.market_contract_settled.connect(_on_market_contract_settled_dialogue)
	_simulation.upgrade_purchased.connect(_on_upgrade_purchased)
	_simulation.decision_requested.connect(_on_decision_requested)
	_simulation.decision_resolved.connect(_on_decision_resolved)
	_simulation.first_clutch_reinvestment_resolved.connect(_on_first_clutch_reinvestment_resolved)
	_simulation.peck_assist_missed.connect(_on_peck_assist_missed)
	_simulation.routing_momentum_broken.connect(_on_routing_momentum_broken)
	_simulation.routing_momentum_recovered.connect(_on_routing_momentum_recovered)

	_clock.set_speed(0)
	_initialize_management_surfaces(_simulation.snapshot())
	_boot_mark(&"management_surfaces")
	_on_snapshot_changed(_simulation.snapshot())
	_boot_mark(&"first_snapshot")
	if _should_bypass_campaign_title():
		_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
		_on_announcement_posted("MORNING BRIEFING: choose the policy that will govern today's clutch.")
		_simulation.announce_pending_decision()
	else:
		_campaign_review_stage = &"title"
		_show_campaign_title(_has_campaign_checkpoint_candidate)
		_set_campaign_modal_open(true)
		_on_announcement_posted("PROBATION INTAKE OPEN. Begin a new five-shift file or continue a saved one.")
	# Opening the title must not render every hidden roster, settings and review
	# surface first. Their controls are already built; render each when opened.
	# On slower WebGL devices the old warm-up stalled the entire loading screen.
	_boot_mark(&"first_interactive")
	if "--capture-action-feedback" in OS.get_cmdline_user_args() or "--capture-action-feedback" in OS.get_cmdline_args():
		_capture_action_feedback_preview()
	elif "--capture-decision" in OS.get_cmdline_user_args() or "--capture-decision" in OS.get_cmdline_args():
		_capture_decision_preview()
	elif "--capture-incident-selected" in OS.get_cmdline_user_args() or "--capture-incident-selected" in OS.get_cmdline_args():
		_capture_incident_preview(true)
	elif "--capture-incident" in OS.get_cmdline_user_args() or "--capture-incident" in OS.get_cmdline_args():
		_capture_incident_preview()
	elif "--capture-petition" in OS.get_cmdline_user_args() or "--capture-petition" in OS.get_cmdline_args():
		_capture_petition_preview()
	elif "--capture-flock-labor" in OS.get_cmdline_user_args() or "--capture-flock-labor" in OS.get_cmdline_args():
		_capture_flock_labor_preview()
	elif "--capture-economic-break-even" in OS.get_cmdline_user_args() or "--capture-economic-break-even" in OS.get_cmdline_args():
		_capture_economic_break_even_preview()
	elif "--capture-day-review" in OS.get_cmdline_user_args() or "--capture-day-review" in OS.get_cmdline_args():
		_capture_day_review_preview()
	elif "--capture-day-review-details" in OS.get_cmdline_user_args() or "--capture-day-review-details" in OS.get_cmdline_args():
		_capture_day_review_preview(true)
	elif "--capture-day-review-max-scale" in OS.get_cmdline_user_args() or "--capture-day-review-max-scale" in OS.get_cmdline_args():
		_capture_day_review_preview(false, true)
	elif "--capture-ledger" in OS.get_cmdline_user_args() or "--capture-ledger" in OS.get_cmdline_args():
		_capture_ledger_preview()
	elif "--capture-review" in OS.get_cmdline_user_args() or "--capture-review" in OS.get_cmdline_args():
		_capture_review_preview()
	elif "--capture-feed-party" in OS.get_cmdline_user_args() or "--capture-feed-party" in OS.get_cmdline_args():
		_capture_feed_party_preview()
	elif "--capture-adaptive-routing-guidance" in OS.get_cmdline_user_args() or "--capture-adaptive-routing-guidance" in OS.get_cmdline_args():
		_capture_adaptive_routing_guidance_preview()
	elif "--capture-adaptive-routing-success" in OS.get_cmdline_user_args() or "--capture-adaptive-routing-success" in OS.get_cmdline_args():
		_capture_adaptive_routing_success_preview()
	elif "--capture-core-action-hold" in OS.get_cmdline_user_args() or "--capture-core-action-hold" in OS.get_cmdline_args():
		_capture_core_action_hold_preview()
	elif "--capture-economic-action-hold" in OS.get_cmdline_user_args() or "--capture-economic-action-hold" in OS.get_cmdline_args():
		_capture_economic_action_hold_preview()
	elif "--capture-strategic-action-hold" in OS.get_cmdline_user_args() or "--capture-strategic-action-hold" in OS.get_cmdline_args():
		_capture_strategic_action_hold_preview()
	elif "--capture-save-recovery-hold" in OS.get_cmdline_user_args() or "--capture-save-recovery-hold" in OS.get_cmdline_args():
		_capture_save_recovery_hold_preview()
	elif "--capture-routing" in OS.get_cmdline_user_args() or "--capture-routing" in OS.get_cmdline_args():
		_capture_routing_preview()
	elif "--capture-routing-peck-recharge" in OS.get_cmdline_user_args() or "--capture-routing-peck-recharge" in OS.get_cmdline_args():
		_capture_routing_peck_recharge_preview()
	elif "--capture-routing-golden" in OS.get_cmdline_user_args() or "--capture-routing-golden" in OS.get_cmdline_args():
		_capture_routing_golden_preview()
	elif "--capture-routing-team-lift" in OS.get_cmdline_user_args() or "--capture-routing-team-lift" in OS.get_cmdline_args():
		_capture_routing_team_lift_preview()
	elif "--capture-routing-mastery" in OS.get_cmdline_user_args() or "--capture-routing-mastery" in OS.get_cmdline_args():
		_capture_routing_mastery_preview()
	elif "--capture-routing-review" in OS.get_cmdline_user_args() or "--capture-routing-review" in OS.get_cmdline_args():
		_capture_routing_review_preview()
	elif "--capture-routing-return" in OS.get_cmdline_user_args() or "--capture-routing-return" in OS.get_cmdline_args():
		_capture_routing_return_preview()
	elif "--capture-routing-work-start" in OS.get_cmdline_user_args() or "--capture-routing-work-start" in OS.get_cmdline_args():
		_capture_routing_return_cue_preview(true, false, true)
	elif "--capture-work-progress" in OS.get_cmdline_user_args() or "--capture-work-progress" in OS.get_cmdline_args():
		_capture_work_progress_preview()
	elif "--capture-office-props" in OS.get_cmdline_user_args() or "--capture-office-props" in OS.get_cmdline_args():
		_capture_office_props_preview()
	elif "--capture-collection-detail" in OS.get_cmdline_user_args() or "--capture-collection-detail" in OS.get_cmdline_args():
		_capture_collection_detail_preview()
	elif "--capture-flock-ties" in OS.get_cmdline_user_args() or "--capture-flock-ties" in OS.get_cmdline_args():
		_capture_flock_ties_preview()
	elif "--capture-pair-rewards" in OS.get_cmdline_user_args() or "--capture-pair-rewards" in OS.get_cmdline_args():
		_ensure_preview_runner()
		_preview_runner.call("_capture_flock_ties_preview", true)
	elif "--capture-hen-social" in OS.get_cmdline_user_args() or "--capture-hen-social" in OS.get_cmdline_args():
		_capture_hen_social_preview()
	elif "--capture-hen-expression" in OS.get_cmdline_user_args() or "--capture-hen-expression" in OS.get_cmdline_args():
		_capture_hen_expression_preview()
	elif "--capture-workshop-tactics" in OS.get_cmdline_user_args() or "--capture-workshop-tactics" in OS.get_cmdline_args():
		_capture_career_workshop_preview(true)
	elif "--capture-career-workshop" in OS.get_cmdline_user_args() or "--capture-career-workshop" in OS.get_cmdline_args():
		_capture_career_workshop_preview()
	elif "--capture-routing-landing" in OS.get_cmdline_user_args() or "--capture-routing-landing" in OS.get_cmdline_args():
		_capture_routing_return_cue_preview(true, true)
	elif "--capture-routing-return-cue-cleared" in OS.get_cmdline_user_args() or "--capture-routing-return-cue-cleared" in OS.get_cmdline_args():
		_capture_routing_return_cue_preview(true)
	elif "--capture-routing-return-cue" in OS.get_cmdline_user_args() or "--capture-routing-return-cue" in OS.get_cmdline_args():
		_capture_routing_return_cue_preview()
	elif "--capture-routing-pace" in OS.get_cmdline_user_args() or "--capture-routing-pace" in OS.get_cmdline_args():
		_capture_routing_pace_preview()
	elif "--capture-dispatch-recovery" in OS.get_cmdline_user_args() or "--capture-dispatch-recovery" in OS.get_cmdline_args():
		_capture_dispatch_recovery_preview()
	elif "--capture-dispatch-break" in OS.get_cmdline_user_args() or "--capture-dispatch-break" in OS.get_cmdline_args():
		_capture_dispatch_break_preview()
	elif "--capture-dispatch" in OS.get_cmdline_user_args() or "--capture-dispatch" in OS.get_cmdline_args():
		_capture_dispatch_preview()
	elif "--capture-hen-intents" in OS.get_cmdline_user_args() or "--capture-hen-intents" in OS.get_cmdline_args():
		_capture_hen_intents_preview()
	elif "--capture-first-clutch-checkin" in OS.get_cmdline_user_args() or "--capture-first-clutch-checkin" in OS.get_cmdline_args():
		_capture_first_clutch_preview(true)
	elif "--capture-first-clutch" in OS.get_cmdline_user_args() or "--capture-first-clutch" in OS.get_cmdline_args():
		_capture_first_clutch_preview()
	elif "--capture-first-clutch-orders-open" in OS.get_cmdline_user_args() or "--capture-first-clutch-orders-open" in OS.get_cmdline_args():
		_capture_first_clutch_reinvestment_preview(true, true)
	elif "--capture-first-clutch-orders" in OS.get_cmdline_user_args() or "--capture-first-clutch-orders" in OS.get_cmdline_args():
		_capture_first_clutch_reinvestment_preview(true)
	elif "--capture-first-clutch-reinvestment" in OS.get_cmdline_user_args() or "--capture-first-clutch-reinvestment" in OS.get_cmdline_args():
		_capture_first_clutch_reinvestment_preview()
	elif "--capture-first-hen" in OS.get_cmdline_user_args() or "--capture-first-hen" in OS.get_cmdline_args():
		_capture_first_hen_preview()
	elif "--capture-first-hen-policy-selected" in OS.get_cmdline_user_args() or "--capture-first-hen-policy-selected" in OS.get_cmdline_args():
		_capture_first_hen_policy_preview(true)
	elif "--capture-first-hen-policy" in OS.get_cmdline_user_args() or "--capture-first-hen-policy" in OS.get_cmdline_args():
		_capture_first_hen_policy_preview()
	elif "--capture-peck-delivery" in OS.get_cmdline_user_args() or "--capture-peck-delivery" in OS.get_cmdline_args():
		_capture_peck_assist_preview(true, true)
	elif "--capture-peck-assist-missed" in OS.get_cmdline_user_args() or "--capture-peck-assist-missed" in OS.get_cmdline_args():
		_capture_peck_assist_preview(false, false, true)
	elif "--capture-peck-assist-result" in OS.get_cmdline_user_args() or "--capture-peck-assist-result" in OS.get_cmdline_args():
		_capture_peck_assist_preview(true)
	elif "--capture-peck-assist" in OS.get_cmdline_user_args() or "--capture-peck-assist" in OS.get_cmdline_args():
		_capture_peck_assist_preview()
	elif "--capture-restructuring" in OS.get_cmdline_user_args() or "--capture-restructuring" in OS.get_cmdline_args():
		_capture_restructuring_preview()
	elif "--capture-grading" in OS.get_cmdline_user_args() or "--capture-grading" in OS.get_cmdline_args():
		_capture_grading_preview()
	elif "--capture-egg-journey" in OS.get_cmdline_user_args() or "--capture-egg-journey" in OS.get_cmdline_args():
		_capture_egg_journey_preview()
	elif "--capture-egg-delivery-ack" in OS.get_cmdline_user_args() or "--capture-egg-delivery-ack" in OS.get_cmdline_args():
		_capture_egg_delivery_ack_preview()
	elif "--capture-payout-burst" in OS.get_cmdline_user_args() or "--capture-payout-burst" in OS.get_cmdline_args():
		_capture_payout_burst_preview()
	elif "--capture-settlement-priority" in OS.get_cmdline_user_args() or "--capture-settlement-priority" in OS.get_cmdline_args():
		_capture_mixed_settlement_preview(true, true)
	elif "--capture-settlement-release" in OS.get_cmdline_user_args() or "--capture-settlement-release" in OS.get_cmdline_args():
		_capture_mixed_settlement_preview(true, true, true)
	elif "--capture-settlement-destination" in OS.get_cmdline_user_args() or "--capture-settlement-destination" in OS.get_cmdline_args():
		_capture_mixed_settlement_preview(true, true, true, true)
	elif "--capture-fund-debit" in OS.get_cmdline_user_args() or "--capture-fund-debit" in OS.get_cmdline_args():
		_capture_fund_debit_preview()
	elif "--capture-procurement-debit" in OS.get_cmdline_user_args() or "--capture-procurement-debit" in OS.get_cmdline_args():
		_capture_procurement_debit_preview()
	elif "--capture-intern-debit" in OS.get_cmdline_user_args() or "--capture-intern-debit" in OS.get_cmdline_args():
		_capture_intern_debit_preview()
	elif "--capture-mixed-settlement-focused" in OS.get_cmdline_user_args() or "--capture-mixed-settlement-focused" in OS.get_cmdline_args():
		_capture_mixed_settlement_preview(true)
	elif "--capture-mixed-settlement" in OS.get_cmdline_user_args() or "--capture-mixed-settlement" in OS.get_cmdline_args():
		_capture_mixed_settlement_preview()
	elif "--capture-staffing" in OS.get_cmdline_user_args() or "--capture-staffing" in OS.get_cmdline_args():
		_capture_staffing_preview()
	elif "--capture-internship-ui" in OS.get_cmdline_user_args() or "--capture-internship-ui" in OS.get_cmdline_args():
		_capture_internship_ui_preview()
	elif "--capture-internship-review-ui" in OS.get_cmdline_user_args() or "--capture-internship-review-ui" in OS.get_cmdline_args():
		_capture_internship_review_ui_preview()
	elif "--capture-internship-fellow-ui" in OS.get_cmdline_user_args() or "--capture-internship-fellow-ui" in OS.get_cmdline_args():
		_capture_internship_fellow_ui_preview()
	elif "--capture-intern-dialogue" in OS.get_cmdline_user_args() or "--capture-intern-dialogue" in OS.get_cmdline_args():
		_capture_intern_dialogue_preview()
	elif "--capture-capacity-commissioning" in OS.get_cmdline_user_args() or "--capture-capacity-commissioning" in OS.get_cmdline_args():
		_capture_capacity_commissioning_preview()
	elif "--capture-facility" in OS.get_cmdline_user_args() or "--capture-facility" in OS.get_cmdline_args():
		_capture_facility_preview()
	elif "--capture-facility-ui" in OS.get_cmdline_user_args() or "--capture-facility-ui" in OS.get_cmdline_args():
		_capture_facility_ui_preview()
	elif "--capture-economic-briefing-ui" in OS.get_cmdline_user_args() or "--capture-economic-briefing-ui" in OS.get_cmdline_args():
		_capture_economic_briefing_ui_preview()
	elif "--capture-feed-procurement-ui" in OS.get_cmdline_user_args() or "--capture-feed-procurement-ui" in OS.get_cmdline_args():
		_capture_feed_procurement_ui_preview()
	elif "--capture-packing-annex" in OS.get_cmdline_user_args() or "--capture-packing-annex" in OS.get_cmdline_args():
		_capture_packing_annex_preview()
	elif "--capture-records-annex" in OS.get_cmdline_user_args() or "--capture-records-annex" in OS.get_cmdline_args():
		_capture_records_annex_preview()
	elif "--capture-service-coop" in OS.get_cmdline_user_args() or "--capture-service-coop" in OS.get_cmdline_args():
		_capture_service_coop_preview()
	elif "--capture-service-coop-ui" in OS.get_cmdline_user_args() or "--capture-service-coop-ui" in OS.get_cmdline_args():
		_capture_service_coop_ui_preview()
	elif "--capture-negotiation-room" in OS.get_cmdline_user_args() or "--capture-negotiation-room" in OS.get_cmdline_args():
		_capture_negotiation_room_preview()
	elif "--capture-contract-board-world" in OS.get_cmdline_user_args() or "--capture-contract-board-world" in OS.get_cmdline_args():
		_capture_contract_board_world_preview()
	elif "--capture-contract-board-ui" in OS.get_cmdline_user_args() or "--capture-contract-board-ui" in OS.get_cmdline_args():
		_capture_contract_board_ui_preview()
	elif "--capture-contract-pricing-access-ui" in OS.get_cmdline_user_args() or "--capture-contract-pricing-access-ui" in OS.get_cmdline_args():
		_capture_contract_pricing_ui_preview(true)
	elif "--capture-contract-pricing-ui" in OS.get_cmdline_user_args() or "--capture-contract-pricing-ui" in OS.get_cmdline_args():
		_capture_contract_pricing_ui_preview()
	elif "--capture-negotiation-board-ui" in OS.get_cmdline_user_args() or "--capture-negotiation-board-ui" in OS.get_cmdline_args():
		_capture_negotiation_board_ui_preview()
	elif "--capture-wellness-nest" in OS.get_cmdline_user_args() or "--capture-wellness-nest" in OS.get_cmdline_args():
		_capture_wellness_nest_preview()
	elif "--capture-training-roost" in OS.get_cmdline_user_args() or "--capture-training-roost" in OS.get_cmdline_args():
		_capture_training_roost_preview()
	elif "--capture-care-campus" in OS.get_cmdline_user_args() or "--capture-care-campus" in OS.get_cmdline_args():
		_capture_care_campus_preview()
	elif "--capture-flock-care-ui" in OS.get_cmdline_user_args() or "--capture-flock-care-ui" in OS.get_cmdline_args():
		_capture_flock_care_ui_preview()
	elif "--capture-farmer-relations-ui" in OS.get_cmdline_user_args() or "--capture-farmer-relations-ui" in OS.get_cmdline_args():
		_capture_farmer_relations_ui_preview()
	elif "--capture-farmer-relations-gallery" in OS.get_cmdline_user_args() or "--capture-farmer-relations-gallery" in OS.get_cmdline_args():
		_capture_farmer_relations_gallery_preview()
	elif "--capture-rooster-operations-office" in OS.get_cmdline_user_args() or "--capture-rooster-operations-office" in OS.get_cmdline_args():
		_capture_rooster_operations_office_preview()
	elif "--capture-rooster-operations-ui" in OS.get_cmdline_user_args() or "--capture-rooster-operations-ui" in OS.get_cmdline_args():
		_capture_rooster_operations_ui_preview()
	elif "--capture-it-coop" in OS.get_cmdline_user_args() or "--capture-it-coop" in OS.get_cmdline_args():
		_capture_it_coop_preview()
	elif "--capture-operations-campus" in OS.get_cmdline_user_args() or "--capture-operations-campus" in OS.get_cmdline_args():
		_capture_operations_campus_preview()
	elif "--capture-flock-relations-ui" in OS.get_cmdline_user_args() or "--capture-flock-relations-ui" in OS.get_cmdline_args():
		_capture_flock_relations_ui_preview()
	elif "--capture-flock-relations" in OS.get_cmdline_user_args() or "--capture-flock-relations" in OS.get_cmdline_args():
		_capture_flock_relations_preview()
	elif "--capture-flock-provisions" in OS.get_cmdline_user_args() or "--capture-flock-provisions" in OS.get_cmdline_args():
		_capture_flock_provisions_preview()
	elif "--capture-governance-campus" in OS.get_cmdline_user_args() or "--capture-governance-campus" in OS.get_cmdline_args():
		_capture_governance_campus_preview()
	elif "--capture-farmgate-ui" in OS.get_cmdline_user_args() or "--capture-farmgate-ui" in OS.get_cmdline_args():
		_capture_farmgate_dispatch_ui_preview()
	elif "--capture-farmgate-filing" in OS.get_cmdline_user_args() or "--capture-farmgate-filing" in OS.get_cmdline_args():
		_capture_farmgate_filing_preview()
	elif "--capture-settings-handoff" in OS.get_cmdline_user_args() or "--capture-settings-handoff" in OS.get_cmdline_args():
		_capture_settings_handoff_preview()
	elif "--capture-first-clutch-playbook" in OS.get_cmdline_user_args() or "--capture-first-clutch-playbook" in OS.get_cmdline_args():
		_capture_first_clutch_playbook_preview()
	elif "--capture-confirmation-handoff" in OS.get_cmdline_user_args() or "--capture-confirmation-handoff" in OS.get_cmdline_args():
		_capture_confirmation_handoff_preview()
	elif "--capture-staff-release-confirmation" in OS.get_cmdline_user_args() or "--capture-staff-release-confirmation" in OS.get_cmdline_args():
		_capture_staff_release_confirmation_preview()
	elif "--capture-manager-succession-confirmation" in OS.get_cmdline_user_args() or "--capture-manager-succession-confirmation" in OS.get_cmdline_args():
		_capture_manager_succession_confirmation_preview()
	elif "--capture-farmgate-locked" in OS.get_cmdline_user_args() or "--capture-farmgate-locked" in OS.get_cmdline_args():
		_capture_farmgate_dispatch_preview(-1)
	elif "--capture-farmgate-survey" in OS.get_cmdline_user_args() or "--capture-farmgate-survey" in OS.get_cmdline_args():
		_capture_farmgate_dispatch_preview(0)
	elif "--capture-farmgate-l1" in OS.get_cmdline_user_args() or "--capture-farmgate-l1" in OS.get_cmdline_args():
		_capture_farmgate_dispatch_preview(1)
	elif "--capture-farmgate-l2" in OS.get_cmdline_user_args() or "--capture-farmgate-l2" in OS.get_cmdline_args():
		_capture_farmgate_dispatch_preview(2)
	elif "--capture-farmgate-l3" in OS.get_cmdline_user_args() or "--capture-farmgate-l3" in OS.get_cmdline_args() or "--capture-farmgate-dispatch" in OS.get_cmdline_user_args() or "--capture-farmgate-dispatch" in OS.get_cmdline_args():
		_capture_farmgate_dispatch_preview(3)
	elif "--capture-dispatch-campus" in OS.get_cmdline_user_args() or "--capture-dispatch-campus" in OS.get_cmdline_args():
		_capture_dispatch_campus_preview()
	elif "--capture-capital-blueprint" in OS.get_cmdline_user_args() or "--capture-capital-blueprint" in OS.get_cmdline_args():
		_capture_capital_blueprint_preview()
	elif "--capture-commissioning-reveal" in OS.get_cmdline_user_args() or "--capture-commissioning-reveal" in OS.get_cmdline_args():
		_capture_commissioning_reveal_preview()
	elif "--capture-campus-expansion" in OS.get_cmdline_user_args() or "--capture-campus-expansion" in OS.get_cmdline_args():
		_capture_campus_expansion_preview()
	elif "--capture-campus-portfolio" in OS.get_cmdline_user_args() or "--capture-campus-portfolio" in OS.get_cmdline_args():
		_capture_campus_portfolio_preview()
	elif "--capture-campus-portfolio-ui" in OS.get_cmdline_user_args() or "--capture-campus-portfolio-ui" in OS.get_cmdline_args():
		_capture_campus_portfolio_ui_preview()
	elif "--capture-campus-portfolio-reveal" in OS.get_cmdline_user_args() or "--capture-campus-portfolio-reveal" in OS.get_cmdline_args():
		_capture_campus_portfolio_reveal_preview()
	elif "--capture-expansion-overview" in OS.get_cmdline_user_args() or "--capture-expansion-overview" in OS.get_cmdline_args():
		_capture_expansion_overview_preview()
	elif "--capture-signage-back" in OS.get_cmdline_user_args() or "--capture-signage-back" in OS.get_cmdline_args():
		_capture_signage_preview(Vector3(0.0, 2.15, -7.70), "signage_back.png")
	elif "--capture-signage-left" in OS.get_cmdline_user_args() or "--capture-signage-left" in OS.get_cmdline_args():
		_capture_signage_preview(Vector3(-10.65, 2.05, -0.20), "signage_left.png")
	elif "--capture-breakroom" in OS.get_cmdline_user_args() or "--capture-breakroom" in OS.get_cmdline_args():
		_capture_breakroom_preview()
	elif "--capture-career-trophies" in OS.get_cmdline_user_args() or "--capture-career-trophies" in OS.get_cmdline_args():
		_capture_career_trophies_preview()
	elif "--capture-signage-desk" in OS.get_cmdline_user_args() or "--capture-signage-desk" in OS.get_cmdline_args():
		_capture_signage_preview(desk_position(0) + Vector3(0.0, 1.20, 0.35), "signage_desk.png")
	elif "--capture-signage-intake" in OS.get_cmdline_user_args() or "--capture-signage-intake" in OS.get_cmdline_args():
		_capture_signage_preview(Vector3(9.55, 1.35, 5.25), "signage_intake.png")
	elif "--capture-campaign-title" in OS.get_cmdline_user_args() or "--capture-campaign-title" in OS.get_cmdline_args():
		_capture_campaign_title_preview()
	elif "--capture-goal-cause-locator" in OS.get_cmdline_user_args() or "--capture-goal-cause-locator" in OS.get_cmdline_args():
		_capture_campaign_goal_cause_locator_preview()
	elif "--capture-goal-cause-fallback" in OS.get_cmdline_user_args() or "--capture-goal-cause-fallback" in OS.get_cmdline_args():
		_capture_campaign_goal_cause_locator_preview(true)
	elif "--capture-goal-driver-route-handoff" in OS.get_cmdline_user_args() or "--capture-goal-driver-route-handoff" in OS.get_cmdline_args():
		_capture_campaign_goal_driver_route_preview(true)
	elif "--capture-goal-driver-route" in OS.get_cmdline_user_args() or "--capture-goal-driver-route" in OS.get_cmdline_args():
		_capture_campaign_goal_driver_route_preview()
	elif "--capture-goal-driver-flock-care" in OS.get_cmdline_user_args() or "--capture-goal-driver-flock-care" in OS.get_cmdline_args():
		_capture_campaign_goal_driver_flock_care_preview()
	elif "--capture-goal-driver-farmer-standing" in OS.get_cmdline_user_args() or "--capture-goal-driver-farmer-standing" in OS.get_cmdline_args():
		_capture_campaign_goal_driver_farmer_standing_preview()
	elif "--capture-goal-driver-coop-controls" in OS.get_cmdline_user_args() or "--capture-goal-driver-coop-controls" in OS.get_cmdline_args():
		_capture_campaign_goal_driver_coop_controls_preview()
	elif "--capture-goal-driver-live-files" in OS.get_cmdline_user_args() or "--capture-goal-driver-live-files" in OS.get_cmdline_args():
		_capture_campaign_goal_driver_live_files_preview()
	elif "--capture-goal-driver-live-files-empty" in OS.get_cmdline_user_args() or "--capture-goal-driver-live-files-empty" in OS.get_cmdline_args():
		_capture_campaign_goal_driver_live_files_preview(true)
	elif "--capture-campaign-promotion-tracker" in OS.get_cmdline_user_args() or "--capture-campaign-promotion-tracker" in OS.get_cmdline_args():
		_capture_campaign_promotion_tracker_preview()
	elif "--capture-campaign-promotion-tracker-max-scale" in OS.get_cmdline_user_args() or "--capture-campaign-promotion-tracker-max-scale" in OS.get_cmdline_args():
		_capture_campaign_promotion_tracker_preview(false, true, true)
	elif "--capture-campaign-promotion-ready" in OS.get_cmdline_user_args() or "--capture-campaign-promotion-ready" in OS.get_cmdline_args():
		_capture_campaign_promotion_tracker_preview(true)
	elif "--capture-campaign-report" in OS.get_cmdline_user_args() or "--capture-campaign-report" in OS.get_cmdline_args():
		_capture_campaign_promotion_opportunity_preview()
	elif "--capture-campaign-report-opportunity" in OS.get_cmdline_user_args() or "--capture-campaign-report-opportunity" in OS.get_cmdline_args():
		_capture_campaign_promotion_opportunity_preview()
	elif "--capture-campaign-report-risk" in OS.get_cmdline_user_args() or "--capture-campaign-report-risk" in OS.get_cmdline_args():
		_capture_campaign_report_preview(true)
	elif "--capture-senior-board-delta" in OS.get_cmdline_user_args() or "--capture-senior-board-delta" in OS.get_cmdline_args():
		_capture_senior_policy_receipt_preview(true)
	elif "--capture-senior-policy-receipt" in OS.get_cmdline_user_args() or "--capture-senior-policy-receipt" in OS.get_cmdline_args():
		_capture_senior_policy_receipt_preview()
	elif "--capture-career-sponsorship-confirmation" in OS.get_cmdline_user_args() or "--capture-career-sponsorship-confirmation" in OS.get_cmdline_args():
		_capture_career_sponsorship_confirmation_preview()
	elif "--capture-career-sponsorship" in OS.get_cmdline_user_args() or "--capture-career-sponsorship" in OS.get_cmdline_args():
		_capture_career_sponsorship_preview()
	elif "--capture-campaign-final" in OS.get_cmdline_user_args() or "--capture-campaign-final" in OS.get_cmdline_args():
		_capture_campaign_final_preview()
	elif "--capture-predator" in OS.get_cmdline_user_args() or "--capture-predator" in OS.get_cmdline_args():
		_capture_predator_preview()
	elif "--capture-predator-animation" in OS.get_cmdline_user_args() or "--capture-predator-animation" in OS.get_cmdline_args():
		_capture_predator_animation()
	elif "--capture" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_args():
		_capture_preview()
	_boot_mark(&"ready")


func _boot_mark(label: StringName) -> void:
	if _boot_started_msec <= 0:
		return
	_boot_timing[String(label)] = maxi(0, Time.get_ticks_msec() - _boot_started_msec)


# --- OfficeWebBridge delegators: implementation lives in office_web_bridge.gd ---
func _load_web_player_preferences() -> Dictionary:
	return _web_bridge._load_web_player_preferences()


func _save_web_player_preferences() -> bool:
	return _web_bridge._save_web_player_preferences()


func _install_web_checkpoint_bridge() -> void:
	_web_bridge._install_web_checkpoint_bridge()


func _on_web_diagnostic_requested(arguments: Array) -> void:
	_web_bridge._on_web_diagnostic_requested(arguments)


func _on_web_career_backup_offered(arguments: Array) -> void:
	_web_bridge._on_web_career_backup_offered(arguments)


func _on_web_mobile_action_requested(arguments: Array) -> void:
	_web_bridge._on_web_mobile_action_requested(arguments)


func _on_career_backup_settings_requested() -> void:
	_web_bridge._on_career_backup_settings_requested()


func office_physical_presentation_snapshot() -> Dictionary:
	return _web_bridge.office_physical_presentation_snapshot()


func capacity_commissioning_snapshot() -> Dictionary:
	return _web_bridge.capacity_commissioning_snapshot()


# --- OfficeReviewPresenter delegators: implementation lives in office_review_presenter.gd ---
func _review_bottleneck_readout() -> String:
	return _review_presenter._review_bottleneck_readout()


func _build_day_review_panel() -> void:
	_review_presenter._build_day_review_panel()


func _apply_physical_review_layout() -> void:
	_review_presenter._apply_physical_review_layout()


func _set_review_details_expanded(expanded: bool) -> void:
	_review_presenter._set_review_details_expanded(expanded)


func _routing_review_receipt(
	report: Dictionary,
	previous_report: Dictionary = {},
) -> Dictionary:
	return _review_presenter._routing_review_receipt(report, previous_report)


func _show_farmer_review(report: Dictionary, animate: bool = true) -> void:
	_review_presenter._show_farmer_review(report, animate)


func _review_has_pending_credit() -> bool:
	return _review_presenter._review_has_pending_credit()


func _review_handoff_hint(optional_copy: String) -> String:
	return _review_presenter._review_handoff_hint(optional_copy)


func _apply_three_card_review(report: Dictionary) -> void:
	_review_presenter._apply_three_card_review(report)


func _review_progression_action(snapshot: Dictionary = {}) -> Dictionary:
	return _review_presenter._review_progression_action(snapshot)


func _apply_review_progression_action(snapshot: Dictionary = {}) -> Dictionary:
	return _review_presenter._apply_review_progression_action(snapshot)


func _advance_from_farmer_review() -> void:
	_review_presenter._advance_from_farmer_review()


func _senior_presentation_snapshot(view: StringName) -> Dictionary:
	return _review_presenter._senior_presentation_snapshot(view)


func _career_sponsorship_presentation_snapshot() -> Dictionary:
	return _review_presenter._career_sponsorship_presentation_snapshot()


func _capture_day_review_preview(expand_details := false, max_interface_scale := false) -> void:
	await _review_presenter._capture_day_review_preview(expand_details, max_interface_scale)


func _capture_review_preview() -> void:
	await _review_presenter._capture_review_preview()


func _capture_routing_review_preview() -> void:
	await _review_presenter._capture_routing_review_preview()


func _capture_internship_review_ui_preview() -> void:
	await _review_presenter._capture_internship_review_ui_preview()


func _next_moment_diagnostic_state(snapshot: Dictionary = {}) -> Dictionary:
	return _web_bridge._next_moment_diagnostic_state(snapshot)


func _checkpoint_diagnostic_state() -> Dictionary:
	return _web_bridge._checkpoint_diagnostic_state()


func _probation_doctrine_snapshot() -> Dictionary:
	return _web_bridge._probation_doctrine_snapshot()


func _routing_return_cue_diagnostic_state() -> Dictionary:
	return _web_bridge._routing_return_cue_diagnostic_state()


# --- OfficeDecisionPresenter delegators: implementation lives in office_decision_presenter.gd ---
func _pending_decision_diagnostic_state() -> Dictionary:
	return _decision_presenter._pending_decision_diagnostic_state()


func _build_decision_modal() -> void:
	_decision_presenter._build_decision_modal()


func _set_decision_petition_glance_visible(visible: bool) -> void:
	_decision_presenter._set_decision_petition_glance_visible(visible)


func _decision_petition_glance_column_count(panel_width: float) -> int:
	return _decision_presenter._decision_petition_glance_column_count(panel_width)


func _decision_petition_option_column_count(panel_width: float) -> int:
	return _decision_presenter._decision_petition_option_column_count(panel_width)


func _decision_option_column_count(
	kind: StringName,
	decision_category: StringName,
	option_count: int,
	panel_width: float,
) -> int:
	return _decision_presenter._decision_option_column_count(kind, decision_category, option_count, panel_width)


func _configure_decision_petition_glance(decision: Dictionary) -> void:
	_decision_presenter._configure_decision_petition_glance(decision)


func _set_decision_order_glance_visible(visible: bool) -> void:
	_decision_presenter._set_decision_order_glance_visible(visible)


func _configure_decision_order_glance() -> void:
	_decision_presenter._configure_decision_order_glance()


func _apply_decision_order_fit_visuals(order_fit: Dictionary) -> void:
	_decision_presenter._apply_decision_order_fit_visuals(order_fit)


func _mount_decision_effect_chips(
	button: Button,
	option_id: StringName,
	effect_chips: Array,
) -> void:
	_decision_presenter._mount_decision_effect_chips(button, option_id, effect_chips)


func _select_decision_option_by_index(index: int) -> void:
	_decision_presenter._select_decision_option_by_index(index)


func _commit_selected_decision() -> void:
	_decision_presenter._commit_selected_decision()


func _spawn_decision_consequence_receipts(
	before: Dictionary,
	after: Dictionary,
	result: Dictionary,
) -> void:
	_decision_presenter._spawn_decision_consequence_receipts(before, after, result)


func _decision_consequence_entries(before: Dictionary, after: Dictionary) -> Array[Dictionary]:
	return _decision_presenter._decision_consequence_entries(before, after)


func _decision_primary_action_state() -> Dictionary:
	return _decision_presenter._decision_primary_action_state()


func _focus_decision_primary_action() -> bool:
	return _decision_presenter._focus_decision_primary_action()


func _capture_decision_preview() -> void:
	await _decision_presenter._capture_decision_preview()


func _flockwatch_diagnostic_state() -> Dictionary:
	return _web_bridge._flockwatch_diagnostic_state()


func _notification_diagnostic_state() -> Dictionary:
	return _web_bridge._notification_diagnostic_state()


func _compact_facility_catalog_diagnostic(source_value: Variant) -> Array[Dictionary]:
	return _web_bridge._compact_facility_catalog_diagnostic(source_value)


func _compact_capital_plan_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_capital_plan_diagnostic(source)


func _compact_operations_diagnostic(
		source: Dictionary,
		include_staffing_details: bool = true,
) -> Dictionary:
	return _web_bridge._compact_operations_diagnostic(source, include_staffing_details)


func _operations_staffing_details_visible(
		operations_filing_open: bool,
		held_confirmation_surface: StringName,
) -> bool:
	return _web_bridge._operations_staffing_details_visible(operations_filing_open, held_confirmation_surface)


func _compact_interaction_safety_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_interaction_safety_diagnostic(source)


func _compact_work_progress_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_work_progress_diagnostic(source)


func _compact_probation_safeguards_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_probation_safeguards_diagnostic(source)


func _compact_flock_care_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_flock_care_diagnostic(source)


func _compact_egg_journey_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_egg_journey_diagnostic(source)


func _compact_contract_offer_diagnostic(
		source: Dictionary,
		include_schedule_details: bool = true,
) -> Dictionary:
	return _web_bridge._compact_contract_offer_diagnostic(source, include_schedule_details)


func _compact_contract_board_diagnostic(
		source: Dictionary,
		include_offer_index: bool,
) -> Dictionary:
	return _web_bridge._compact_contract_board_diagnostic(source, include_offer_index)


func _compact_campus_portfolio_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_campus_portfolio_diagnostic(source)


func _compact_campus_expansion_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_campus_expansion_diagnostic(source)


func _runtime_performance_diagnostic() -> Dictionary:
	return _web_bridge._runtime_performance_diagnostic()


func _publish_web_diagnostic_state(snapshot: Dictionary) -> void:
	_web_bridge._publish_web_diagnostic_state(snapshot)


func _dispatch_diagnostic_state() -> Dictionary:
	return _web_bridge._dispatch_diagnostic_state()


func _web_accessibility_summary(snapshot: Dictionary) -> String:
	return _web_bridge._web_accessibility_summary(snapshot)


func _web_accessibility_announcement(snapshot: Dictionary, summary := "") -> Dictionary:
	return _web_bridge._web_accessibility_announcement(snapshot, summary)


func _web_return_recap_summary(resume_summary: Dictionary) -> String:
	return _web_bridge._web_return_recap_summary(resume_summary)


func _web_offline_recap_summary(resume_summary: Dictionary) -> String:
	return _web_bridge._web_offline_recap_summary(resume_summary)


# --- OfficePulsePresenter delegators: implementation lives in office_pulse_presenter.gd ---
func _compact_gameplay_pulse_diagnostic(source: Dictionary) -> Dictionary:
	return _pulse_presenter._compact_gameplay_pulse_diagnostic(source)


func _campaign_pulse_projection() -> Dictionary:
	return _pulse_presenter._campaign_pulse_projection()


func _playbook_for_presentation(snapshot: Dictionary, focused_worker_id: int) -> Dictionary:
	return _pulse_presenter._playbook_for_presentation(snapshot, focused_worker_id)


func _refresh_gameplay_pulse(snapshot: Dictionary) -> void:
	_pulse_presenter._refresh_gameplay_pulse(snapshot)


func _apply_readable_loop_hud(snapshot: Dictionary, playbook: Dictionary) -> void:
	_pulse_presenter._apply_readable_loop_hud(snapshot, playbook)


func _apply_professional_polish_presentation(layer: Dictionary) -> void:
	_pulse_presenter._apply_professional_polish_presentation(layer)


func _refresh_active_playbook_menu(playbook: Dictionary, focused_worker_id: int) -> void:
	_pulse_presenter._refresh_active_playbook_menu(playbook, focused_worker_id)


func _next_action_diagnostic_state() -> Dictionary:
	return _pulse_presenter._next_action_diagnostic_state()


func _pulse_action_target(target: Control) -> void:
	_pulse_presenter._pulse_action_target(target)


func _compact_first_session_funnel_diagnostic(source: Dictionary) -> Dictionary:
	return _web_bridge._compact_first_session_funnel_diagnostic(source)


func _live_hud_diagnostic_state() -> Dictionary:
	return _web_bridge._live_hud_diagnostic_state()


func _serialize_web_diagnostic_state(snapshot: Dictionary) -> void:
	_web_bridge._serialize_web_diagnostic_state(snapshot)


func settlement_destination_ack_snapshot() -> Dictionary:
	return _web_bridge.settlement_destination_ack_snapshot()


func fund_debit_feedback_snapshot() -> Dictionary:
	return _web_bridge.fund_debit_feedback_snapshot()


func fund_credit_batch_snapshot() -> Dictionary:
	return _web_bridge.fund_credit_batch_snapshot()


func auxiliary_settlement_snapshot() -> Dictionary:
	return _web_bridge.auxiliary_settlement_snapshot()


func settlement_feedback_arbitration_snapshot() -> Dictionary:
	return _web_bridge.settlement_feedback_arbitration_snapshot()


func settlement_feedback_placement_snapshot() -> Dictionary:
	return _web_bridge.settlement_feedback_placement_snapshot()


func _on_optional_storytelling_finished() -> void:
	# Refresh the browser diagnostic once background campus construction is
	# complete. This remains observability-only; gameplay does not depend on it.
	_publish_web_diagnostic_state(_simulation.snapshot())


func _ensure_peck_assist_input_action() -> void:
	OfficeActionCatalogScript.install_defaults()


func _ensure_explain_input_action() -> void:
	if not InputMap.has_action(&"explain_mode"):
		InputMap.add_action(&"explain_mode")
	if not InputMap.action_get_events(&"explain_mode").is_empty():
		return
	var explain_key := InputEventKey.new()
	explain_key.physical_keycode = KEY_H
	InputMap.action_add_event(&"explain_mode", explain_key)


func _ensure_manager_power_input_action() -> void:
	if not InputMap.has_action(&"manager_power"):
		InputMap.add_action(&"manager_power")
	if not InputMap.action_get_events(&"manager_power").is_empty():
		return
	var power_key := InputEventKey.new()
	power_key.physical_keycode = KEY_Q
	InputMap.action_add_event(&"manager_power", power_key)


func _load_player_preferences() -> void:
	var loaded_preferences: Dictionary = _preferences_store.load_preferences()
	var mirrored_preferences := _load_web_player_preferences()
	if not mirrored_preferences.is_empty():
		loaded_preferences = mirrored_preferences
	_player_preferences = PlayerPreferencesStoreScript.sanitize(loaded_preferences)
	var binding_result: Dictionary = OfficeActionCatalogScript.apply_bindings(
		_player_preferences.get("input_bindings", {}) as Dictionary
	)
	if not bool(binding_result.get("accepted", false)):
		push_warning(
			"Saved control bindings were held: %s" % String(binding_result.get(
				"reason",
				"conflicting bindings",
			))
		)
		OfficeActionCatalogScript.reset_all()
		_player_preferences["input_bindings"] = {}
	# These two exits are deliberately non-remappable in the in-game UI, and are
	# reasserted even if a hand-edited preference file tries to remove the safe
	# path back into settings or the office overview.
	OfficeActionCatalogScript.reset_action(&"open_settings")
	OfficeActionCatalogScript.reset_action(&"office_overview")
	var safe_bindings := (_player_preferences.get("input_bindings", {}) as Dictionary).duplicate(true)
	safe_bindings.erase("open_settings")
	safe_bindings.erase("office_overview")
	_player_preferences["input_bindings"] = safe_bindings
	_simulation.set_peck_assist_timing_profile(
		StringName(String(_player_preferences.get("timing_assist", "standard")))
	)


func _apply_player_preferences() -> void:
	_player_preferences = PlayerPreferencesStoreScript.sanitize(_player_preferences)
	PlayerPreferencesStoreScript.apply_audio(_player_preferences)
	_apply_ambient_audio_preference()
	_simulation.set_peck_assist_timing_profile(
		StringName(String(_player_preferences.get("timing_assist", "standard")))
	)
	var reduced_motion := _prefers_reduced_motion()
	_animation_speed_multiplier = PlayerPreferencesStoreScript.animation_speed_multiplier(
		String(_player_preferences.get("animation_speed", "standard"))
	)
	ProjectSettings.set_setting(
		"gui/timers/tooltip_delay_sec",
		PlayerPreferencesStoreScript.tooltip_delay_seconds(
			String(_player_preferences.get("tooltip_delay", "standard"))
		),
	)
	if _camera_controller != null:
		_camera_controller.set_reduced_motion(reduced_motion)
		_camera_controller.set_camera_motion_level(
			StringName(String(_player_preferences.get("camera_motion", "full")))
		)
		_camera_controller.set_input_sensitivity(
			StringName(String(_player_preferences.get("camera_sensitivity", "standard")))
		)
		_camera_controller.set_high_contrast(bool(_player_preferences.get("high_contrast", false)))
		_camera_controller.set_animation_speed_multiplier(_animation_speed_multiplier)
	if _office_atmosphere != null:
		_office_atmosphere.set_reduced_motion(reduced_motion)
		_office_atmosphere.set_animation_speed_multiplier(_animation_speed_multiplier)
		_office_atmosphere.set_effect_level(
			StringName(String(_player_preferences.get("effect_level", "full")))
		)
		_office_atmosphere.set_particle_level(
			StringName(String(_player_preferences.get("particle_level", "full")))
		)
	if _audio_feedback != null and _audio_feedback.has_method("set_haptics_enabled"):
		_audio_feedback.call(
			"set_haptics_enabled",
			bool(_player_preferences.get("haptics_enabled", true)),
		)
	if _routing_ui != null and _routing_ui.has_method("set_reduced_motion"):
		_routing_ui.call("set_reduced_motion", reduced_motion)
	if _campaign_ui != null and _campaign_ui.has_method("set_reduced_motion"):
		_campaign_ui.call("set_reduced_motion", reduced_motion)
	if _character_dialogue_ui != null:
		_character_dialogue_ui.set_reduced_motion(reduced_motion)
	for view_value: Variant in _worker_views.values():
		var worker_view := view_value as ChickenView
		if worker_view != null:
			worker_view.set_reduced_motion(reduced_motion)
	for view_value: Variant in _departing_worker_views.values():
		var departing_view := view_value as ChickenView
		if departing_view != null:
			departing_view.set_reduced_motion(reduced_motion)
	var color_vision_mode := StringName(String(_player_preferences.get("color_vision_mode", "standard")))
	if _routing_ui != null and _routing_ui.has_method("set_color_vision_mode"):
		_routing_ui.call("set_color_vision_mode", color_vision_mode)
	if _workstation_feedback != null and _workstation_feedback.has_method("set_color_vision_mode"):
		_workstation_feedback.call("set_color_vision_mode", color_vision_mode)
	if _workstation_feedback != null:
		_workstation_feedback.set_reduced_motion(reduced_motion)
		_workstation_feedback.set_animation_speed_multiplier(_animation_speed_multiplier)
	if _management_presence != null:
		_management_presence.set_animation_speed_multiplier(_animation_speed_multiplier)
	for reveal_ui: Control in [_commissioning_reveal_ui, _campus_portfolio_reveal_ui]:
		if reveal_ui != null and reveal_ui.has_method("set_animation_speed_multiplier"):
			reveal_ui.call("set_animation_speed_multiplier", _animation_speed_multiplier)
	if _office_storytelling != null and _office_storytelling.has_method("set_color_vision_mode"):
		_office_storytelling.call("set_color_vision_mode", color_vision_mode)
	_apply_visual_quality(StringName(String(_player_preferences.get("visual_quality", "balanced"))))
	if (
		_ticker_panel != null
		and String(_player_preferences.get("notice_level", "all")) == "archive_only"
	):
		_ticker_panel.visible = false
		_ticker_visible_copy = ""
		if _ticker_label != null and not _ticker_last_text.is_empty():
			_ticker_label.text = _ticker_last_text
	_apply_management_ui_preferences()
	_refresh_action_prompts()
	if _settings_ui != null:
		_settings_ui.refresh_preferences(_player_preferences)
		_settings_ui.refresh_binding_labels(_current_binding_labels())


func _apply_ambient_audio_preference() -> void:
	var audio := _player_preferences.get("audio", {}) as Dictionary
	var ambient := audio.get("ambient", {}) as Dictionary
	var ambient_index := AudioServer.get_bus_index(&"Ambient")
	if ambient_index < 0:
		return
	var volume := clampf(float(ambient.get("volume", 0.65)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(ambient_index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(ambient_index, bool(ambient.get("muted", false)))


func _apply_management_ui_preferences() -> void:
	if _ui_root == null:
		return
	var scale := float(_player_preferences.get("ui_scale", 1.0))
	var high_contrast := bool(_player_preferences.get("high_contrast", false))
	_ui_root.theme = ManagementUIThemeScript.create_theme(high_contrast, scale)
	_apply_explicit_font_scale(_ui_root, scale)
	_apply_live_policy_scale(scale)
	_apply_flockwatch_toggle_scale(scale)
	_refresh_flockwatch_toggle_layout()
	_apply_settings_button_scale(scale)
	_apply_shift_status_scale(scale)
	if _routing_ui != null:
		_routing_ui.set_interface_scale(scale)
	if _campaign_ui != null:
		_campaign_ui.set_interface_scale(scale)
	if _day_review_panel != null:
		_set_review_details_expanded(_review_details_expanded)
	if _environment != null:
		_environment.adjustment_contrast = 1.16 if high_contrast else 1.08
		_environment.adjustment_saturation = 1.0 if high_contrast else 0.94
	_hud_layout_key = ""
	_measure_live_hud_canvas()


func _apply_explicit_font_scale(root_control: Control, scale: float) -> void:
	var controls: Array[Node] = [root_control]
	controls.append_array(root_control.find_children("*", "Control", true, false))
	for node_value: Node in controls:
		var control := node_value as Control
		if control == null or not control.has_theme_font_size_override("font_size"):
			continue
		if not control.has_meta(&"preference_base_font_size"):
			control.set_meta(
				&"preference_base_font_size",
				control.get_theme_font_size("font_size"),
			)
		var base_size := int(control.get_meta(&"preference_base_font_size", 14))
		control.add_theme_font_size_override("font_size", maxi(10, roundi(base_size * scale)))
		# Propagate live font-size changes through parent container layout before
		# the next frame is drawn.
		control.update_minimum_size()
		control.queue_redraw()


func _apply_visual_quality(quality: StringName) -> void:
	var viewport := get_viewport()
	match quality:
		&"low":
			viewport.scaling_3d_scale = 0.82
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			_set_worker_presentation_rate_hz(LOW_WORKER_PRESENTATION_RATE_HZ)
			_set_directional_shadow_atlas_size(LOW_DIRECTIONAL_SHADOW_ATLAS_SIZE)
			if _office_sun != null:
				_office_sun.shadow_enabled = false
			if _office_atmosphere != null:
				_office_atmosphere.set_atmosphere_enabled(false)
		&"high":
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_4X
			_set_worker_presentation_rate_hz(HIGH_WORKER_PRESENTATION_RATE_HZ)
			_set_directional_shadow_atlas_size(HIGH_DIRECTIONAL_SHADOW_ATLAS_SIZE)
			if _office_sun != null:
				_office_sun.shadow_enabled = true
				_office_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			if _office_atmosphere != null:
				_office_atmosphere.set_atmosphere_enabled(true)
		_:
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			# The authored chicken clips are sampled at a film-like 30 Hz while
			# route movement, peck contacts, lay release, and the economy retain
			# their full physics cadence. This removes duplicate Web skeleton and
			# accessory writes without changing simulation responsiveness.
			_set_worker_presentation_rate_hz(BALANCED_WORKER_PRESENTATION_RATE_HZ)
			# The 4096 atlas is valuable for High's four showcase cascades. The
			# bounded orthographic office needs one 2048 map at Balanced, matching
			# Godot's own mobile atlas default while retaining every grounding
			# shadow and avoiding an extra scaled-composite pass on WebGL.
			_set_directional_shadow_atlas_size(BALANCED_DIRECTIONAL_SHADOW_ATLAS_SIZE)
			if _office_sun != null:
				_office_sun.shadow_enabled = true
				# The management camera is orthographic and the playable office
				# fits inside one bounded shadow volume. A second cascade renders
				# the same dense desk/signage scene again without contributing
				# perspective-distance detail. Balanced keeps one authored
				# shadow map; High retains the four-split showcase treatment.
				_office_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			if _office_atmosphere != null:
				_office_atmosphere.set_atmosphere_enabled(true)


func _set_worker_presentation_rate_hz(rate_hz: float) -> void:
	_worker_presentation_rate_hz = maxf(0.0, rate_hz)
	for view_value: Variant in _worker_views.values():
		var worker_view := view_value as ChickenView
		if worker_view != null:
			worker_view.set_presentation_update_rate_hz(_worker_presentation_rate_hz)
	for view_value: Variant in _departing_worker_views.values():
		var departing_view := view_value as ChickenView
		if departing_view != null:
			departing_view.set_presentation_update_rate_hz(_worker_presentation_rate_hz)


func _set_directional_shadow_atlas_size(size: int) -> void:
	_directional_shadow_atlas_size = maxi(0, size)
	RenderingServer.directional_shadow_atlas_set_size(
		_directional_shadow_atlas_size,
		true,
	)


func _current_binding_labels() -> Dictionary:
	var result: Dictionary = {}
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		result[action] = OfficeActionCatalogScript.binding_label(action)
	return result


func _action_hint(action: StringName) -> String:
	return OfficeActionCatalogScript.binding_label(action)


func _update_settings_button_prompt() -> void:
	if _settings_button == null:
		return
	var binding_hint := _action_hint(&"open_settings")
	var primary_hint := binding_hint.split(" / ", false)[0]
	var full_text := "SETTINGS  [%s]" % binding_hint
	var compact_text := "SETTINGS  [%s]" % primary_hint
	var detail := "Audio, display comfort, accessibility, and remappable controls.\nBinding: %s." % binding_hint
	_settings_button.set_meta("full_text", full_text)
	_settings_button.set_meta("compact_text", compact_text)
	_settings_button.tooltip_text = detail
	_settings_button.accessibility_name = "%s. %s" % [full_text, detail]
	_settings_button.set_meta("accessible_text", _settings_button.accessibility_name)
	_apply_settings_button_scale(float(_player_preferences.get("ui_scale", 1.0)))


## The persistent cog carries Settings identity at every scale. Keep only the
## primary safety key visible; the complete keyboard/controller binding remains
## in tooltip and assistive copy.
func _apply_settings_button_scale(scale: float) -> void:
	if _settings_button == null:
		return
	var sanitized_scale := clampf(scale, 1.0, 1.5)
	_settings_button.set_meta("interface_scale", sanitized_scale)
	_settings_button.set_meta("compact_action_mark", true)
	_settings_button.set_meta("icon_led_action_mark", true)
	_settings_button.text = String(_settings_button.get_meta(
		"compact_text",
		_settings_button.text,
	))


func _update_shift_status_copy(day: int, time_copy: String, fund_cents: int) -> void:
	_update_shift_clock_copy(day, time_copy)
	_update_fund_status_copy(fund_cents)


func _update_shift_clock_copy(day: int, time_copy: String) -> void:
	if _day_label == null or _time_label == null:
		return
	var day_copy := "DAY %d" % day
	_day_label.set_meta("full_text", day_copy)
	_day_label.set_meta("compact_text", day_copy)
	_time_label.set_meta("full_text", time_copy)
	_time_label.set_meta("compact_text", time_copy)
	_time_label.set_meta("clock_text", time_copy)
	_time_label.set_meta("clock_day", day)
	_refresh_clock_accessibility()
	_apply_shift_status_scale(float(_player_preferences.get("ui_scale", 1.0)))


func _sync_authoritative_clock_display() -> void:
	if _simulation == null:
		return
	var display_clock := _clock_stamp_for_snapshot({
		"day": _simulation.day,
		"time_label": _office_clock_label(_simulation.minute_of_day),
		"shift_phase": _simulation.shift_phase,
	})
	_update_shift_clock_copy(
		int(display_clock.get("day", _simulation.day)),
		String(display_clock.get("time_label", "8:00 AM")),
	)


func _sync_authoritative_shift_objective_display() -> void:
	if _simulation == null or _quota_progress == null or _quota_progress_label == null:
		return
	var eggs := maxi(0, _simulation.eggs_today)
	var quota := maxi(1, _simulation.quota_target)
	var guided := (
		not bool(_first_clutch.get("dismissed", true))
		and not (
			bool(_first_clutch.get("route_first_lesson", false))
			and _first_clutch_reinvestment_resolved()
		)
		and _simulation.day == 1
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and eggs <= 3
	)
	var first_egg := (
		guided
		and bool(_first_clutch.get("route_first_lesson", false))
		and not _first_clutch_reinvestment_resolved()
	)
	var opening_clutch_complete := guided and not first_egg and eggs >= 3
	var count := eggs
	var target := quota
	var label := "QUOTA  ·  %d / %d" % [eggs, quota]
	var accessible := (
		"Shift quota met: %d of %d eggs laid. Flockwatch score goals are tracked separately."
		% [eggs, quota]
		if eggs >= quota else
		"Shift quota: %d of %d eggs laid; %d remaining. This operating target is separate from Flockwatch score goals, which may be higher."
		% [eggs, quota, quota - eggs]
	)
	if first_egg:
		count = int(bool(_first_clutch.get("delivery_laid", false)))
		target = 1
		label = "FIRST EGG · %d/1" % count
	elif guided:
		if not opening_clutch_complete:
			count = eggs
			target = 3
			label = "FILE 3 EGGS · %d/3" % count
	if first_egg or (guided and not opening_clutch_complete):
		accessible = "Opening goal: %d of %d eggs laid. Each egg travels to grading and the basket. More goals appear after this reward." % [count, target]
	elif opening_clutch_complete:
		accessible = "First clutch complete. Shift quota: %d of %d eggs laid; %d remaining before 5:00 PM." % [eggs, quota, maxi(0, quota - eggs)]
	_quota_progress.max_value = target
	_quota_progress.value = mini(count, target)
	_quota_progress_label.text = label
	_quota_progress.tooltip_text = accessible
	_quota_progress.accessibility_name = accessible
	_quota_progress_label.tooltip_text = accessible
	_quota_progress_label.accessibility_name = accessible
	if _shift_egg_goal_label != null:
		_shift_egg_goal_label.text = "%d LEFT" % maxi(0, target - count) if count < target else "READY"
		_shift_egg_goal_label.tooltip_text = accessible
		_shift_egg_goal_label.accessibility_name = accessible
	if _shift_goal_status_icon != null:
		_shift_goal_status_icon.tooltip_text = accessible
		_shift_goal_status_icon.set_meta("accessible_text", accessible)
	if _shift_goal_status_host != null:
		_shift_goal_status_host.set_meta("accessible_text", accessible)
		_shift_goal_status_host.set_meta("laid", count)
		_shift_goal_status_host.set_meta("target", target)
		_shift_goal_status_host.set_meta("remaining", maxi(0, target - count))


func _refresh_clock_accessibility() -> void:
	if _day_label == null or _time_label == null:
		return
	var day := int(_time_label.get_meta("clock_day", 1))
	var time_copy := String(_time_label.get_meta("clock_text", "8:00 AM"))
	var clock_accessible := "Shift clock: Day %d at %s. Closing bell: 5:00 PM." % [day, time_copy]
	var pause_context := _pause_context_state()
	if bool(pause_context.get("active", false)):
		clock_accessible += " " + String(pause_context.get("accessible_text", "Time is paused."))
	else:
		var pace := _clock.effective_multiplier() if _clock != null else 1.0
		clock_accessible += " Work and ordinary hen routes advance together at %d×. One work beat is two game minutes." % int(pace)
	_day_label.tooltip_text = clock_accessible
	_day_label.accessibility_name = clock_accessible
	_time_label.tooltip_text = clock_accessible
	_time_label.accessibility_name = clock_accessible
	if _shift_clock_status_host != null:
		_shift_clock_status_host.set_meta("accessible_text", clock_accessible)
	if _shift_clock_status_icon != null:
		_shift_clock_status_icon.tooltip_text = clock_accessible
		_shift_clock_status_icon.set_meta("accessible_text", clock_accessible)


func _update_fund_status_copy(fund_cents: int) -> void:
	if _revenue_label == null:
		return
	var safe_fund_cents := maxi(0, fund_cents)
	var amount_copy := "$%.2f" % (float(safe_fund_cents) / 100.0)
	var full_copy := "FEED FUND  %s" % amount_copy
	var fund_accessible := "Feed Fund available: %s." % amount_copy
	_revenue_label.set_meta("full_text", full_copy)
	_revenue_label.set_meta("compact_text", amount_copy)
	_revenue_label.tooltip_text = fund_accessible
	_revenue_label.accessibility_name = fund_accessible
	if _fund_status_host != null:
		_fund_status_host.set_meta("accessible_text", fund_accessible)
	if _fund_status_icon != null:
		_fund_status_icon.tooltip_text = fund_accessible
		_fund_status_icon.set_meta("accessible_text", fund_accessible)
	_apply_shift_status_scale(float(_player_preferences.get("ui_scale", 1.0)))


## Stable clock and cash marks carry the two permanent status categories at
## every scale. Exact values and full Feed Fund terminology remain in assistive
## copy while only the redundant visual prefix is removed.
func _apply_shift_status_scale(scale: float) -> void:
	if _day_label == null or _time_label == null or _revenue_label == null:
		return
	var sanitized_scale := clampf(scale, 1.0, 1.5)
	for label: Label in [_day_label, _time_label, _revenue_label]:
		label.text = String(label.get_meta(
			"compact_text",
			label.text,
		))
	if _shift_clock_status_host != null:
		_shift_clock_status_host.add_theme_constant_override("separation", 5)
		_shift_clock_status_host.set_meta("interface_scale", sanitized_scale)
		_shift_clock_status_host.set_meta("compact_status_marks", true)
		_shift_clock_status_host.set_meta("icon_led_status_marks", true)
	if _fund_status_host != null:
		_fund_status_host.add_theme_constant_override("separation", 5)
		_fund_status_host.set_meta("interface_scale", sanitized_scale)
		_fund_status_host.set_meta("compact_status_marks", true)
		_fund_status_host.set_meta("icon_led_status_marks", true)
	if _shift_clock_status_icon != null:
		_shift_clock_status_icon.visible = true
	if _fund_status_icon != null:
		_fund_status_icon.visible = true


func _refresh_action_prompts() -> void:
	if _settings_button != null:
		_update_settings_button_prompt()
	if _flockwatch_toggle != null:
		_update_flockwatch_toggle()
	if _feed_button != null and not _feed_party_active:
		if _feed_button.text.begins_with("FUND FEED PARTY"):
			_feed_button.text = "FUND FEED PARTY  ($20)  [%s]" % _action_hint(&"fund_feed_party")
		_feed_button.tooltip_text = (
			"Once per shift: +10 morale, -8 stress, +2 farmer favor. Production pauses for attendance. Binding: %s."
			% _action_hint(&"fund_feed_party")
		)
	if _overtime_button != null:
		if "AFTER-HOURS PECKING" in _overtime_button.text:
			_overtime_button.text = "%s  [%s]" % [
				"END AFTER-HOURS PECKING" if _overtime_button.button_pressed else "ENABLE AFTER-HOURS PECKING",
				_action_hint(&"toggle_overtime"),
			]
		_overtime_button.tooltip_text = (
			"+22%% output; sharply increases fatigue, stress, morale loss, and crack risk. Resets next shift. Binding: %s."
			% _action_hint(&"toggle_overtime")
		)
	if _routing_ui != null and _routing_ui.has_method("set_peck_assist_binding_label"):
		_routing_ui.call("set_peck_assist_binding_label", _action_hint(PECK_ASSIST_ACTION))


func _on_settings_requested() -> void:
	_build_settings_surface()
	if _settings_ui.is_open():
		_on_settings_close_requested()
		return
	_first_session_funnel.observe_signal(&"settings_opened")
	# Settings is the non-remappable safety and reading surface above every other
	# modal. Preserve the structured action result, but retire its lower-priority
	# global cards before the settings sheet claims the screen.
	_yield_transient_feedback_to(&"settings")
	_settings_previous_speed = _clock.speed_index if _clock != null else 0
	_settings_holds_speed = true
	_settings_prior_focus_owner = get_viewport().gui_get_focus_owner()
	if _clock != null:
		_clock.set_speed(0)
	_settings_ui.show_settings(
		_player_preferences,
		_current_binding_labels(),
		_campaign_store != null and _has_verified_campaign_checkpoint,
		_first_clutch_can_reopen(),
	)
	_refresh_floor_input_context()
	if _audio_feedback != null and _audio_feedback.has_method("play_ui_tick"):
		_audio_feedback.call("play_ui_tick")
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_settings_close_requested() -> void:
	if _settings_ui == null or not _settings_ui.is_open():
		return
	_settings_ui.hide_settings()
	var another_modal := _settings_other_modal_open()
	_refresh_floor_input_context()
	if _settings_holds_speed and not another_modal and _clock != null:
		_clock.set_speed(_settings_previous_speed)
	_settings_holds_speed = false
	if (
		_settings_prior_focus_owner != null
		and is_instance_valid(_settings_prior_focus_owner)
		and _settings_prior_focus_owner.is_visible_in_tree()
	):
		_settings_prior_focus_owner.call_deferred("grab_focus")
	elif not another_modal and _settings_button != null and _settings_button.is_visible_in_tree():
		_settings_button.call_deferred("grab_focus")
	_settings_prior_focus_owner = null
	_publish_web_diagnostic_state(_simulation.snapshot())


func _settings_other_modal_open() -> bool:
	return (
		(_campaign_ui != null and _campaign_ui.is_modal_open())
		or (_decision_host != null and _decision_host.visible)
		or (_day_review_scrim != null and _day_review_scrim.visible)
		or _capital_modal_holds_speed
	)


func _on_preferences_changed(preferences: Dictionary) -> void:
	var previous_guidance_mode := String(_player_preferences.get("guidance_mode", "full"))
	_player_preferences = PlayerPreferencesStoreScript.sanitize(preferences)
	_apply_player_preferences()
	_save_player_preferences("Preference filed and applied.")
	var guidance_mode := String(_player_preferences.get("guidance_mode", "full"))
	if guidance_mode == "off":
		_clear_adaptive_route_recovery()
	if guidance_mode == "off" and _first_clutch_tracking_active():
		_on_first_clutch_skip_requested()
	elif guidance_mode != previous_guidance_mode:
		var snapshot := _simulation.snapshot()
		_refresh_first_clutch_ui(snapshot)
		_update_guidance(snapshot)
	if _settings_ui != null:
		_settings_ui.set_first_clutch_replay_available(_first_clutch_can_reopen())


func _on_first_clutch_replay_requested() -> void:
	if not _first_clutch_can_reopen():
		if _settings_ui != null:
			_settings_ui.set_status("First Clutch replay is available only after hiding an unfinished first-shift coach.")
		return
	_player_preferences["guidance_mode"] = "full"
	_player_preferences = PlayerPreferencesStoreScript.sanitize(_player_preferences)
	_first_clutch["dismissed"] = false
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
	_refresh_flockwatch_navigation(snapshot)
	_update_guidance(snapshot)
	_save_player_preferences("Full First Clutch guidance restored and saved.")
	_save_campaign_checkpoint("first_clutch_reopened")
	if _settings_ui != null:
		_settings_ui.refresh_preferences(_player_preferences)
		_settings_ui.set_first_clutch_replay_available(false)
		_settings_ui.set_status("First Clutch restored at its saved step. Return to the floor when ready.")


func _on_preferences_reset_requested() -> void:
	OfficeActionCatalogScript.reset_all()
	_player_preferences = PlayerPreferencesStoreScript.defaults()
	_apply_player_preferences()
	if _settings_ui != null and _settings_ui.is_open():
		_settings_ui.refresh_preferences(_player_preferences)
		_settings_ui.refresh_binding_labels(_current_binding_labels())
	_save_player_preferences("Settings defaults restored and saved.")


func _on_career_backup_export_requested() -> void:
	if _settings_ui == null or _campaign_store == null:
		return
	# Export is a deliberate durability boundary. Active play must first commit
	# the latest authoritative ledgers so the portable file cannot lag behind the
	# state the player can currently see.
	if _campaign_session_checkpoint_enabled and not _save_campaign_checkpoint(
		"portable_backup_export"
	):
		_settings_ui.set_status(
			"Career backup held: the latest campaign checkpoint could not be verified."
		)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	if not _has_verified_campaign_checkpoint:
		_settings_ui.set_status(
			"Career backup held: continue the local career so every ledger can be verified first."
		)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	var json_text: String = _campaign_store.export_portable_backup()
	if json_text.is_empty():
		_settings_ui.set_status(
			"Career backup held: %s" % _bounded_checkpoint_error(_campaign_store.last_error)
		)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	_settings_ui.present_career_backup(json_text)
	_settings_ui.set_career_backup_available(true)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_playtest_receipt_export_requested() -> void:
	if _settings_ui == null or _simulation == null:
		return
	_settings_ui.present_playtest_receipt(_first_session_funnel.export_receipt())
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_legacy_card_requested() -> void:
	if _campaign_state == null or _simulation == null or _campaign_state.completed_shifts < CampaignStateScript.CAMPAIGN_LENGTH:
		_publish_economic_action_hold(
			"LEGACY CARD",
			"FINISH THE FILE",
			"The shareable legacy card opens only after the five-shift final review.",
			"Legacy card",
		)
		return
	var evaluation := _campaign_state.final_evaluation()
	var leadership := _simulation.leadership_record_snapshot()
	var scenario := _simulation.scenario_identity_snapshot()
	var hearing := _simulation.final_hearing_snapshot()
	var rival := _simulation.rival_coop_snapshot(
		_campaign_state.probation_score,
		_campaign_state.completed_shifts,
	)
	var card := {
		"format": "pecking_order_legacy_card",
		"version": 1,
		"privacy": "No personal data. Created locally and never transmitted by the game.",
		"coop": String(_career_profile.get("label", "OPEN NEST CO-OP")),
		"emblem": String(_career_profile.get("emblem", "OPEN WING")),
		"scenario": String(scenario.get("name", "BASELINE BOOK")),
		"difficulty": String(_campaign_state.challenge_contract_snapshot().get("label", "STANDARD FILING")),
		"score": _campaign_state.probation_score,
		"rank": CampaignStateScript.rank_display_name(_campaign_state.probation_rank),
		"passed": bool(evaluation.get("passed", false)),
		"legacy": String(leadership.get("title", "UNFILED ROOST")),
		"final_hearing": String(hearing.get("option_label", "STANDARD RECORD")),
		"rival": String(rival.get("name", "GOLDEN COMB GROUP")),
		"rival_margin": int(rival.get("difference", 0)),
		"run_count": int(_career_run_archive.comparison().get("run_count", 0)),
	}
	var json_text := JSON.stringify(card, "  ")
	var filename := "pecking-order-%s-legacy.json" % String(_career_profile.get("id", "open_nest"))
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(json_text.to_utf8_buffer(), filename, "application/json")
	else:
		DisplayServer.clipboard_set(json_text)
	_ticker_label.text = "LEGACY CARD READY. %s" % (
		"Downloaded locally; nothing was transmitted."
		if OS.has_feature("web") else
		"Copied to the clipboard; nothing was transmitted."
	)
	_ticker_panel.visible = true


func _on_career_backup_import_requested(json_text: String) -> void:
	if _settings_ui == null or _campaign_store == null:
		return
	# Envelope validation rejects oversized, malformed, future-schema, cyclic, or
	# non-primitive content. Composite staging then proves every domain ledger on
	# disposable objects before the transactional store is allowed to rotate the
	# current primary into its recovery copy.
	var envelope: Dictionary = _campaign_store.inspect_portable_backup(json_text)
	if envelope.is_empty():
		_settings_ui.complete_career_backup_import(
			false,
			"Career restore held: %s" % _bounded_checkpoint_error(_campaign_store.last_error),
		)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	var staged: Dictionary = _stage_campaign_checkpoint(envelope)
	if not bool(staged.get("ok", false)):
		_settings_ui.complete_career_backup_import(
			false,
			"Career restore held: %s" % _bounded_checkpoint_error(String(staged.get(
				"error",
				"the campaign ledger failed validation",
			))),
		)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	if not _campaign_store.import_portable_backup(json_text):
		_settings_ui.complete_career_backup_import(
			false,
			"Career restore held: %s" % _bounded_checkpoint_error(_campaign_store.last_error),
		)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return

	# Do not activate a replacement behind Settings. Return to the intake with a
	# truthful Continue route, while disabling session autosaves so the displaced
	# in-memory career cannot overwrite the newly imported checkpoint.
	_checkpoint_coordinator.discard_pending()
	_has_campaign_checkpoint_candidate = true
	_has_verified_campaign_checkpoint = true
	_checkpoint_last_error = ""
	_checkpoint_last_saved_reason = "portable_backup_import"
	_checkpoint_last_saved_unix_msec = int(Time.get_unix_time_from_system() * 1000.0)
	_campaign_session_checkpoint_enabled = false
	_settings_ui.complete_career_backup_import(
		true,
		"Portable career verified and filed. Continue opens the imported checkpoint.",
	)
	_settings_ui.hide_settings()
	_settings_holds_speed = false
	_settings_prior_focus_owner = null
	_clock.set_speed(0)
	_show_campaign_title(true)
	_set_campaign_modal_open(true)
	_ticker_label.text = (
		"PORTABLE CAREER FILED. Continue opens the imported checkpoint; the prior local file remains the recovery copy."
	)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_binding_capture_requested(action: StringName, event: InputEvent) -> void:
	var previous_preferences := _player_preferences.duplicate(true)
	var previous_events: Array[InputEvent] = []
	for existing: InputEvent in InputMap.action_get_events(action):
		previous_events.append(existing.duplicate(true) as InputEvent)
	var next_events: Array[InputEvent] = []
	for existing: InputEvent in previous_events:
		if _same_binding_family(existing, event):
			continue
		next_events.append(existing)
	next_events.append(event)
	var result: Dictionary = OfficeActionCatalogScript.rebind_action(action, next_events)
	if not bool(result.get("accepted", false)):
		var rejection_message := "Binding held: %s Choose a different key or button." % String(result.get(
			"reason",
			"that input is already in use",
		))
		if _settings_ui != null:
			_settings_ui.acknowledge_binding_capture(action, false, rejection_message)
		if _simulation != null:
			_publish_web_diagnostic_state(_simulation.snapshot())
		return
	_player_preferences["input_bindings"] = OfficeActionCatalogScript.export_bindings()
	_player_preferences = PlayerPreferencesStoreScript.sanitize(_player_preferences)
	_refresh_action_prompts()
	if not _preferences_store.save_preferences(_player_preferences):
		# A binding is not real until the independent preferences transaction is
		# verified. Restore both runtime input and the prior preference snapshot so
		# a failed browser/desktop write cannot masquerade as a successful change.
		InputMap.action_erase_events(action)
		for previous_event: InputEvent in previous_events:
			InputMap.action_add_event(action, previous_event)
		_player_preferences = previous_preferences
		_refresh_action_prompts()
		var failure_message := "Binding not filed: %s Choose another input or try again." % String(
			_preferences_store.last_error
		)
		push_warning(failure_message)
		if _settings_ui != null:
			_settings_ui.acknowledge_binding_capture(action, false, failure_message)
		if _simulation != null:
			_publish_web_diagnostic_state(_simulation.snapshot())
		return
	var browser_mirror_saved := _save_web_player_preferences()
	if _settings_ui != null:
		_settings_ui.acknowledge_binding_capture(
			action,
			true,
			(
				"Control binding filed and saved."
				if browser_mirror_saved else
				"Control binding applied; browser durability could not be verified."
			),
			_current_binding_labels(),
		)
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _same_binding_family(first: InputEvent, second: InputEvent) -> bool:
	return (
		(first is InputEventKey and second is InputEventKey)
		or (first is InputEventJoypadButton and second is InputEventJoypadButton)
	)


func _save_player_preferences(success_message: String) -> void:
	if _preferences_store.save_preferences(_player_preferences):
		var browser_mirror_saved := _save_web_player_preferences()
		if _settings_ui != null:
			_settings_ui.set_status(
				success_message
				if browser_mirror_saved else
				"Preference applied; browser durability could not be verified."
			)
	else:
		var message := "Preference save held: %s" % _preferences_store.last_error
		push_warning(message)
		if _settings_ui != null:
			_settings_ui.set_status(message)
	# Settings intentionally pause the floor, so there may be no simulation tick
	# to refresh the browser's accessible mirror. Publish every saved (or rejected)
	# preference action immediately while the panel is still open.
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_audio_focus_paused(true)
		_set_application_focus_paused(true)
		_request_lifecycle_checkpoint("application_focus_out")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_set_audio_focus_paused(false)
		_set_application_focus_paused(false)
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		_request_lifecycle_checkpoint("application_paused")
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_request_lifecycle_checkpoint("window_close_requested")


func _exit_tree() -> void:
	_request_lifecycle_checkpoint("scene_exit")


func _request_lifecycle_checkpoint(reason: String) -> bool:
	# The title surface owns only a staged/default in-memory campaign. Writing it
	# before New/Continue would fabricate a resumable file or replace a valid one.
	# Return to Intake has already shelved synchronously, so it is safe to skip too.
	if (
		not _campaign_session_checkpoint_enabled
		or _campaign_ui == null
		or _campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
	):
		return false
	var process_frame := Engine.get_process_frames()
	var simulation_revision := _simulation.checkpoint_revision() if _simulation != null else -1
	if (
		process_frame == _last_lifecycle_checkpoint_frame
		and simulation_revision == _last_lifecycle_checkpoint_revision
		and not _checkpoint_coordinator.is_dirty()
	):
		return true
	var saved := _save_campaign_checkpoint(reason)
	if saved:
		_last_lifecycle_checkpoint_frame = process_frame
		_last_lifecycle_checkpoint_revision = simulation_revision
	return saved


func _set_audio_focus_paused(paused: bool) -> void:
	if _audio_feedback != null and _audio_feedback.has_method("set_focus_paused"):
		_audio_feedback.call("set_focus_paused", paused)
	if _audio_director != null and _audio_director.has_method("set_focus_paused"):
		_audio_director.call("set_focus_paused", paused)


func _set_application_focus_paused(unfocused: bool) -> void:
	if unfocused:
		if (
			_focus_pause_active
			or not is_node_ready()
			or not bool(_player_preferences.get("pause_when_unfocused", true))
			or _clock == null
			or _clock.speed_index <= 0
			or _simulation == null
			or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
		):
			return
		_focus_pause_previous_speed = _clock.speed_index
		_focus_pause_active = true
		_clock.set_speed(0)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	if not _focus_pause_active:
		return
	var restore_speed := _focus_pause_previous_speed
	_focus_pause_active = false
	_focus_pause_previous_speed = 0
	var can_restore := (
		restore_speed > 0
		and _clock != null
		and _simulation != null
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not _feed_party_active
		and not _blocking_management_surface_open()
	)
	if can_restore:
		_clock.set_speed(restore_speed)
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


static func predator_debug_shortcut_enabled_for_environment(
	debug_build: bool,
	user_arguments: PackedStringArray,
	engine_arguments: PackedStringArray,
) -> bool:
	if not debug_build:
		return false
	return (
		PREDATOR_DEBUG_ARGUMENT in user_arguments
		or PREDATOR_DEBUG_ARGUMENT in engine_arguments
	)


func _predator_debug_shortcut_enabled() -> bool:
	return predator_debug_shortcut_enabled_for_environment(
		OS.is_debug_build(),
		OS.get_cmdline_user_args(),
		OS.get_cmdline_args(),
	)


func _input(event: InputEvent) -> void:
	# Space is the floor's pause shortcut, even when closing a drawer restored
	# focus to its button. Consume it before GUI accept can reopen that drawer.
	if (
		_simulation != null
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not _flockwatch_open
		and not _blocking_management_surface_open()
		and not _peck_assist_input_blocked()
		and _is_action_press(event, &"pause_simulation")
	):
		_on_pause_requested()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"explain_mode") and not (event is InputEventKey and event.echo):
		_begin_explain_mode()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_released(&"explain_mode"):
		_end_explain_mode()
		get_viewport().set_input_as_handled()
		return
	if (
		_settings_ui != null
		and _settings_ui.is_open()
		and (event is InputEventKey or event is InputEventJoypadButton)
	):
		get_viewport().set_input_as_handled()
		return
	# Settings is the non-remappable safety surface. It must outrank campaign,
	# decision, review, Flockwatch, and capital input contexts so F10/Guide can
	# always reach audio, comfort, controls, and recovery tools.
	if _is_action_press(event, &"open_settings"):
		_on_settings_requested()
		get_viewport().set_input_as_handled()
		return
	if _flock_ties_ui != null and _flock_ties_ui.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_ESCAPE, KEY_B]:
				_close_flock_ties()
			elif event.keycode in [KEY_1, KEY_2, KEY_3]:
				var pair := _flock_ties_ui.snapshot()
				if bool(pair.contest_available if event.keycode == KEY_3 else pair.break_available if event.keycode == KEY_1 else pair.repair_available):
					_on_flock_ties_action(int(pair.worker_id), int(pair.partner_id), "friendly_contest" if event.keycode == KEY_3 else "shared_break" if event.keycode == KEY_1 else "clear_air")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B and not _blocking_management_surface_open():
		_open_flock_ties()
		get_viewport().set_input_as_handled()
		return
	if _character_dialogue_ui != null and _character_dialogue_ui.is_blocking():
		var dialogue_accept: bool = (
			_is_action_press(event, &"ui_accept")
			or (
				event is InputEventKey
				and event.pressed
				and not event.echo
				and event.keycode in [KEY_ENTER, KEY_KP_ENTER]
			)
		)
		if dialogue_accept:
			_character_dialogue_ui.dismiss_current()
		if (
			event is InputEventKey
			or event is InputEventJoypadButton
			or _is_managed_action_press(event)
		):
			get_viewport().set_input_as_handled()
		return
	if (
		_dispatch_lane != &""
		and (_is_action_press(event, &"office_overview") or event.is_action_pressed(&"ui_cancel"))
	):
		_clear_dispatch_mode(true)
		_publish_status_copy("TRAY RETURNED TO INTAKE.", false)
		get_viewport().set_input_as_handled()
		return
	# Flockwatch is an input context, not just a visible overlay. Its existing
	# semantic bindings become ledger navigation while the drawer owns focus;
	# every other floor shortcut is swallowed before the camera can see it.
	if _flockwatch_open:
		if _is_action_press(event, &"toggle_flockwatch") or _is_action_press(event, &"office_overview"):
			_set_flockwatch_open(false, true)
			get_viewport().set_input_as_handled()
			return
		if _is_action_press(event, &"cycle_hen"):
			var direction := -1 if event is InputEventKey and (event as InputEventKey).shift_pressed else 1
			if _flockwatch_navigation != null:
				_flockwatch_navigation.cycle_page(direction, true)
			get_viewport().set_input_as_handled()
			return
		if _is_managed_action_press(event):
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if (
			_first_hen_prelude_pending()
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER]
		):
			_open_first_hen_file(int(_first_clutch.get("target_worker_id", -1)))
			get_viewport().set_input_as_handled()
			return
		if _campaign_ui != null and _campaign_ui.is_modal_open():
			get_viewport().set_input_as_handled()
			return
		if _decision_host != null and _decision_host.visible:
			match event.keycode:
				KEY_1:
					_select_decision_option_by_index(0)
				KEY_2:
					_select_decision_option_by_index(1)
				KEY_3:
					_select_decision_option_by_index(2)
				KEY_ENTER, KEY_KP_ENTER:
					_on_decision_confirm_pressed()
			get_viewport().set_input_as_handled()
			return
		if (
			event.keycode in [KEY_ENTER, KEY_KP_ENTER]
			and _handle_first_clutch_primary_action()
		):
			get_viewport().set_input_as_handled()
			return
		if _day_review_scrim != null and _day_review_scrim.visible:
			get_viewport().set_input_as_handled()
			return
	# Full-screen management surfaces own their input before Office reaches
	# `_unhandled_input`. Swallow any remaining floor shortcut here so opening a
	# Blueprint, Portfolio, expansion file, or reveal can never operate the live
	# office behind it. Modal-owned Escape/F10 handlers still run first.
	if _blocking_management_surface_open() and _is_managed_action_press(event):
		get_viewport().set_input_as_handled()
		return
	if _is_action_press(event, &"manager_power"):
		_open_manager_power_playbook()
		get_viewport().set_input_as_handled()
		return
	if _is_action_press(event, PECK_ASSIST_ACTION):
		if not _peck_assist_input_blocked():
			_request_peck_assist_from_input()
		get_viewport().set_input_as_handled()
		return
	if _is_action_press(event, NEXT_MOMENT_ACTION):
		_on_next_moment_pressed()
	elif _is_action_press(event, &"pause_simulation"):
		_on_pause_requested()
	elif _is_action_press(event, &"speed_normal"):
		_on_speed_button_pressed(1)
	elif _is_action_press(event, &"speed_fast"):
		_on_speed_button_pressed(2)
	elif _is_action_press(event, &"speed_ultra"):
		_on_speed_button_pressed(3)
	elif _is_action_press(event, &"fund_feed_party"):
		_on_feed_pressed()
	elif _is_action_press(event, &"toggle_overtime"):
		_on_overtime_pressed()
	elif _is_action_press(event, &"toggle_flockwatch"):
		_on_flockwatch_pressed()
	elif (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_F
		and _predator_debug_shortcut_enabled()
	):
		_trigger_predator_debug_encounter()
	else:
		return
	get_viewport().set_input_as_handled()


func _is_action_press(event: InputEvent, action: StringName) -> bool:
	return event.is_action_pressed(action) and not (event is InputEventKey and event.echo)


func _open_manager_power_playbook() -> void:
	if (
		_simulation == null
		or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
		or _active_playbook_button == null
		or not _active_playbook_button.visible
		or _active_playbook_button.disabled
		or _blocking_management_surface_open()
		or _flockwatch_open
		or _settings_ui != null and _settings_ui.is_open()
	):
		return
	_active_playbook_button.grab_focus()
	_active_playbook_button.show_popup()
	_pulse_action_target(_active_playbook_button)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _begin_explain_mode() -> void:
	if (
		_explain_mode_active
		or _explain_strip == null
		or _blocking_management_surface_open()
		or _flockwatch_open
		or _settings_ui != null and _settings_ui.is_open()
	):
		return
	_explain_mode_active = true
	_explain_previous_speed = _clock.speed_index if _clock != null else 0
	if _clock != null and _explain_previous_speed > 0:
		_clock.set_speed(0)
	_explain_strip.visible = true
	_explain_strip.modulate = Color.WHITE
	_explain_strip.set_meta("active", true)
	_explain_strip.set_meta("paused_previous_speed", _explain_previous_speed)
	_on_guidance_preview_entered()
	_play_last_cause_replay()
	if not _prefers_reduced_motion():
		_explain_strip.modulate.a = 0.0
		_explain_strip.scale = Vector2(0.97, 0.97)
		_explain_strip.pivot_offset = _explain_strip.size * 0.5
		var tween := _presentation_tween(_explain_strip).set_parallel(true)
		tween.tween_property(_explain_strip, "modulate:a", 1.0, 0.12)
		tween.tween_property(_explain_strip, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _end_explain_mode() -> void:
	if not _explain_mode_active:
		return
	_explain_mode_active = false
	if not _last_cause_replay.is_empty():
		_last_cause_replay["active"] = false
	if _explain_strip != null:
		_explain_strip.visible = false
		_explain_strip.modulate = Color.WHITE
		_explain_strip.scale = Vector2.ONE
		_explain_strip.set_meta("active", false)
	_on_guidance_preview_exited()
	var restore_speed := _explain_previous_speed
	_explain_previous_speed = 0
	if (
		restore_speed > 0
		and _clock != null
		and _simulation != null
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not _blocking_management_surface_open()
		and not _feed_party_active
	):
		_clock.set_speed(restore_speed)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _is_managed_action_press(event: InputEvent) -> bool:
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		if _is_action_press(event, action):
			return true
	return false


func _play_last_cause_replay() -> void:
	if _dispatch_last_receipt.is_empty() or _workstation_feedback == null:
		_last_cause_replay = {
			"available": false,
			"active": false,
			"input": "H",
			"files_nothing": true,
			"presentation_only": true,
		}
		return
	var worker_id := int(_dispatch_last_receipt.get("worker_id", -1))
	var lane := StringName(_dispatch_last_receipt.get("lane", &""))
	if worker_id < 0 or lane == &"" or not _worker_views.has(worker_id):
		return
	_cause_replay_serial += 1
	var started := _workstation_feedback.play_dispatch_delivery(
		worker_id,
		lane,
		to_global(DISPATCH_INTAKE_SOURCE),
		bool(_dispatch_last_receipt.get("recommended", false)),
		int(_dispatch_last_receipt.get("momentum_chain", 0)),
		0.62,
		&"",
		{
			"presentation_only": true,
			"cause_replay_serial": _cause_replay_serial,
		},
	)
	if not started:
		return
	var worker_name := String(_dispatch_last_receipt.get("worker_name", "HEN"))
	var result_label := _dispatch_reward_label
	if result_label.is_empty():
		result_label = "BEST FIT" if bool(_dispatch_last_receipt.get("recommended", false)) else "ROUTE FILED"
	_last_cause_replay = {
		"available": true,
		"active": true,
		"replayed": true,
		"serial": _cause_replay_serial,
		"worker_id": worker_id,
		"worker_name": worker_name,
		"lane": String(lane),
		"file_label": String(lane).replace("_", " ").to_upper(),
		"result_label": result_label,
		"path": ["FILE", "HEN", "RESULT"],
		"input": "H",
		"files_nothing": true,
		"presentation_only": true,
	}
	var worker_view := _worker_views.get(worker_id) as ChickenView
	if worker_view != null and is_instance_valid(worker_view):
		worker_view.play_short_bark("THAT DID IT!", &"success")


# --- OfficeEnvironmentBuilder delegators: implementation lives in office_environment_builder.gd ---
func _build_environment() -> void:
	_environment_builder._build_environment()


func _build_office() -> void:
	_environment_builder._build_office()


func _build_feed_party_station() -> void:
	_environment_builder._build_feed_party_station()


func _build_staffing_surface(parent: Node = null) -> void:
	_environment_builder._build_staffing_surface(parent)


func _build_settings_surface() -> void:
	_environment_builder._build_settings_surface()


func _build_held_confirmation_scrim() -> void:
	_environment_builder._build_held_confirmation_scrim()


func _build_explain_strip() -> void:
	_environment_builder._build_explain_strip()


func _build_capital_planning_surfaces() -> void:
	_environment_builder._build_capital_planning_surfaces()


func _sync_work_progress_interactions() -> void:
	_environment_builder._sync_work_progress_interactions()


func _build_settlement_destination_ack_pool() -> void:
	_environment_builder._build_settlement_destination_ack_pool()


func _build_fund_debit_chip_pool() -> void:
	_environment_builder._build_fund_debit_chip_pool()


func _build_fund_credit_chip_pool() -> void:
	_environment_builder._build_fund_credit_chip_pool()


func _build_auxiliary_settlement_chip_pool() -> void:
	_environment_builder._build_auxiliary_settlement_chip_pool()


func _add_box_multimesh(
	parent: Node,
	part_name: String,
	transforms: Array[Transform3D],
	color: Color,
	shadow_casting: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
) -> MultiMeshInstance3D:
	return _environment_builder._add_box_multimesh(parent, part_name, transforms, color, shadow_casting)


func _add_cylinder(parent: Node, part_name: String, part_position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	return _environment_builder._add_cylinder(parent, part_name, part_position, radius, height, color)


func _add_sphere(parent: Node, part_name: String, part_position: Vector3, part_scale: Vector3, color: Color) -> MeshInstance3D:
	return _environment_builder._add_sphere(parent, part_name, part_position, part_scale, color)


static func desk_position(index: int) -> Vector3:
	var socket: Vector2i = DESK_SOCKET_ORDER[index]
	return Vector3(
		float(DESK_COLUMNS[socket.x]),
		0.0,
		float(DESK_ROWS[socket.y]),
	)


## Presentation footprint for the currently authorized internal office. The
## authoritative campus footprint remains unchanged; this only determines what
## the ordinary management camera needs to show at each capacity milestone.
static func office_camera_bounds(capacity: int) -> Rect2:
	match clampi(capacity, 0, MAXIMUM_OFFICE_CAPACITY):
		MAXIMUM_OFFICE_CAPACITY:
			return BASE_CAMPUS_BOUNDS
		5:
			return FIFTH_PERCH_CAMERA_BOUNDS
		_:
			return OPENING_OFFICE_CAMERA_BOUNDS


static func office_overview_minimum_size(capacity: int) -> float:
	match clampi(capacity, 0, MAXIMUM_OFFICE_CAPACITY):
		MAXIMUM_OFFICE_CAPACITY:
			return FULL_OFFICE_OVERVIEW_SIZE
		5:
			return FIFTH_PERCH_OVERVIEW_SIZE
		_:
			return CORE_OVERVIEW_SIZE


static func chair_position(index: int) -> Vector3:
	return desk_position(index) + Vector3(0.0, 0.0, CHAIR_OFFSET_Z)


static func entry_position(index: int) -> Vector3:
	return Vector3(-10.65 + index * 0.95, 0.0, MAIN_AISLE_Z)


static func break_position(index: int) -> Vector3:
	var stations: Array[Vector3] = [
		Vector3(-10.58, 0.0, -3.12), # water cooler
		Vector3(-10.58, 0.0, -1.82), # coffee counter
		Vector3(-10.68, 0.0, 1.18), # sofa-side pouf
		Vector3(-8.18, 0.0, 1.58), # cafe table
		Vector3(-10.58, 0.0, -0.12), # pinboard
		Vector3(-9.42, 0.0, 0.76), # social companion
	]
	return stations[posmod(index, stations.size())]


static func break_interaction_kind(index: int) -> StringName:
	var interactions: Array[StringName] = [
		&"water",
		&"coffee",
		&"lounge",
		&"browse",
		&"bulletin",
		&"chat",
	]
	return interactions[posmod(index, interactions.size())]


static func break_interaction_face_point(index: int) -> Vector3:
	var face_points: Array[Vector3] = [
		Vector3(-11.05, 0.95, -3.12),
		Vector3(-11.02, 1.10, -1.82),
		Vector3(-10.10, 0.85, 1.18),
		Vector3(-8.82, 0.60, 1.55),
		Vector3(-11.64, 2.05, -0.02),
		Vector3(-11.08, 0.90, 1.18),
	]
	return face_points[posmod(index, face_points.size())]


static func access_lane_x(index: int) -> float:
	return desk_position(index).x + ACCESS_LANE_OFFSET


static func arrival_route(index: int) -> Array[Vector3]:
	var chair := chair_position(index)
	var lane_x := access_lane_x(index)
	return [
		Vector3(lane_x, 0.0, MAIN_AISLE_Z),
		Vector3(lane_x, 0.0, chair.z),
		chair,
	]


static func departure_route(index: int) -> Array[Vector3]:
	var chair := chair_position(index)
	var lane_x := access_lane_x(index)
	return [
		Vector3(lane_x, 0.0, chair.z),
		Vector3(lane_x, 0.0, MAIN_AISLE_Z),
		entry_position(index),
		Vector3(-11.25, 0.0, MAIN_AISLE_Z),
	]


static func wellness_route(index: int) -> Array[Vector3]:
	var chair := chair_position(index)
	var lane_x := access_lane_x(index)
	var destination := break_position(index)
	return [
		Vector3(lane_x, 0.0, chair.z),
		Vector3(lane_x, 0.0, 0.0),
		Vector3(-7.95, 0.0, 0.0),
		destination,
	]


static func feed_party_attendance_position(index: int) -> Vector3:
	var column := index % 3
	# Puffy employee silhouettes need more than agent-radius separation while
	# leaning and pecking. These match the Blender sockets and keep accessories,
	# wings, and faces from crossing neighboring bodies in the feeding pose.
	var side_z := -1.34 if index < 3 else 1.34
	var local_socket := Vector3([-1.55, 0.0, 1.55][column], 0.0, side_z)
	return FEED_PARTY_STATION_POSITION + local_socket * FEED_PARTY_STATION_SCALE


static func feed_party_route(index: int) -> Array[Vector3]:
	var chair := chair_position(index)
	var lane_x := access_lane_x(index)
	var attendance := feed_party_attendance_position(index)
	var bypass_z := -1.55 if attendance.z < 0.0 else 1.55
	var route: Array[Vector3] = [
		Vector3(lane_x, 0.0, chair.z),
		Vector3(lane_x, 0.0, 0.0),
		Vector3(lane_x, 0.0, bypass_z),
		Vector3(attendance.x, 0.0, bypass_z),
	]
	route.append(attendance)
	return route


static func feed_party_return_route(index: int) -> Array[Vector3]:
	var route := feed_party_route(index)
	route.reverse()
	route.append(chair_position(index))
	return route


## Campus workers use the same authored office lanes as every other hen, then
## take the connected care/operations spine and the campus exterior perimeter.
## Keeping this route deterministic makes staffed modules readable without
## introducing a second navigation authority or shortcutting through art.
static func campus_duty_position(pad_id: StringName) -> Vector3:
	match pad_id:
		&"orchard_west":
			return Vector3(20.90, 0.0, CAMPUS_COMMUTE_ORCHARD_ROUTE_Z)
		&"orchard_east":
			return Vector3(25.05, 0.0, CAMPUS_COMMUTE_ORCHARD_ROUTE_Z)
		&"creekside_west":
			return Vector3(20.90, 0.0, CAMPUS_COMMUTE_CREEKSIDE_ROUTE_Z)
		&"creekside_east":
			return Vector3(25.05, 0.0, CAMPUS_COMMUTE_CREEKSIDE_ROUTE_Z)
	return Vector3(INF, INF, INF)


static func campus_duty_face_point(pad_id: StringName) -> Vector3:
	var duty := campus_duty_position(pad_id)
	if not duty.is_finite():
		return duty
	return duty + Vector3(0.0, 0.65, 2.85)


static func campus_duty_commute_bounds() -> Rect2:
	const VISUAL_CLEARANCE := 0.70
	var start := Vector2(
		CAMPUS_COMMUTE_SPINE_X - VISUAL_CLEARANCE,
		MAIN_AISLE_Z - VISUAL_CLEARANCE,
	)
	var finish := Vector2(
		CAMPUS_COMMUTE_EAST_BYPASS_X + VISUAL_CLEARANCE,
		CAMPUS_COMMUTE_NORTH_BYPASS_Z + VISUAL_CLEARANCE,
	)
	return Rect2(start, finish - start)


static func campus_duty_outbound_route(index: int, pad_id: StringName) -> Array[Vector3]:
	var duty := campus_duty_position(pad_id)
	if not duty.is_finite():
		return []
	var chair := chair_position(index)
	var lane_x := access_lane_x(index)
	var route: Array[Vector3] = [
		Vector3(lane_x, 0.0, chair.z),
		Vector3(lane_x, 0.0, MAIN_AISLE_Z),
		Vector3(CAMPUS_COMMUTE_SPINE_X, 0.0, MAIN_AISLE_Z),
		Vector3(CAMPUS_COMMUTE_SPINE_X, 0.0, CAMPUS_COMMUTE_SPINE_ENTRY_Z),
		Vector3(CAMPUS_COMMUTE_SPINE_X, 0.0, CAMPUS_COMMUTE_NORTH_BYPASS_Z),
		Vector3(CAMPUS_COMMUTE_EAST_BYPASS_X, 0.0, CAMPUS_COMMUTE_NORTH_BYPASS_Z),
		Vector3(CAMPUS_COMMUTE_EAST_BYPASS_X, 0.0, duty.z),
	]
	route.append(duty)
	return route


static func campus_duty_return_route(index: int, pad_id: StringName) -> Array[Vector3]:
	var route := campus_duty_outbound_route(index, pad_id)
	if route.is_empty():
		return route
	route.reverse()
	route.append(chair_position(index))
	return route


func _apply_opening_story_shadow_budget() -> void:
	if _office_storytelling == null:
		return
	var archive_story := _office_storytelling.find_child("ArchiveAndIntakeStory", true, false)
	if archive_story != null:
		_apply_shadow_allowlist(archive_story, [])
	var collection_chain := _office_storytelling.find_child("VisibleEggCollectionChain", true, false)
	if collection_chain != null:
		_apply_shadow_allowlist(collection_chain, [], COLLECTION_STRUCTURAL_SHADOW_PREFIXES)
	var management_perch := _office_storytelling.find_child("RoosterManagementPerch", true, false)
	if management_perch != null:
		_apply_shadow_allowlist(
			management_perch,
			[
				"PerchRaisedFoundation",
				"ExecutivePerchDesk",
				"ExecutiveDeskLegBatch",
				"ExecutiveRoostSeat",
				"ExecutiveRoostBack",
				"ExecutiveRoostColumn",
				"ExecutiveGoldenEgg",
				"GoldenEggPlinth",
				"FlockSurveillanceCamera",
			],
		)


func _apply_shadow_allowlist(
	root_node: Node,
	exact_names: Array,
	name_prefixes: Array = [],
) -> void:
	for candidate in root_node.find_children("*", "GeometryInstance3D", true, false):
		var geometry := candidate as GeometryInstance3D
		if geometry == null:
			continue
		var geometry_name := String(geometry.name)
		var casts_shadow := geometry_name in exact_names
		if not casts_shadow:
			for prefix_value in name_prefixes:
				if geometry_name.begins_with(String(prefix_value)):
					casts_shadow = not geometry_name.ends_with("Glow")
					break
		geometry.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if casts_shadow
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)


func _office_capacity_from_snapshot(snapshot: Dictionary) -> int:
	return clampi(
		int(snapshot.get("office_capacity", MAXIMUM_OFFICE_CAPACITY)),
		0,
		MAXIMUM_OFFICE_CAPACITY,
	)


func _active_desk_positions(capacity: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for index in mini(clampi(capacity, 0, MAXIMUM_OFFICE_CAPACITY), _desk_positions.size()):
		result.append(_desk_positions[index])
	return result


func _apply_office_capacity_visibility(capacity: int, animate_reveal: bool = true) -> void:
	capacity = clampi(capacity, 0, MAXIMUM_OFFICE_CAPACITY)
	var previous_capacity := _displayed_office_capacity
	if previous_capacity == capacity and animate_reveal:
		return
	for index in MAXIMUM_OFFICE_CAPACITY:
		var workstation: Node3D = _workstations_by_index.get(index)
		var marker: Node3D = _capacity_markers_by_index.get(index)
		var active := index < capacity
		var newly_active := active and index >= previous_capacity
		if workstation != null:
			workstation.visible = active
			if active:
				workstation.position.y = 0.0
				workstation.scale = Vector3.ONE
				if animate_reveal and newly_active and previous_capacity >= 0:
					workstation.position.y = -0.30
					workstation.scale = Vector3(0.96, 0.96, 0.96)
					var reveal := _presentation_tween(workstation).set_parallel(true)
					reveal.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					reveal.tween_property(workstation, "position:y", 0.0, 0.62)
					reveal.tween_property(workstation, "scale", Vector3.ONE, 0.62)
		if marker != null:
			# The next construction crate is useful only after staffing has become a
			# live question. Orientation therefore begins with the working pod alone.
			marker.visible = _capacity_marker_should_be_visible(capacity, index)
	_displayed_office_capacity = capacity
	_apply_office_physical_presentation(capacity)
	if animate_reveal and previous_capacity >= 0 and capacity > previous_capacity:
		# The authority changes immediately, while the presentation handoff is
		# deferred until the current snapshot has also refreshed lighting and labels.
		# This avoids a one-frame flash of the mature west wing before commissioning.
		_animate_capacity_stage_handoff.call_deferred(previous_capacity, capacity)
	if _office_storytelling != null and previous_capacity != capacity:
		# Rebuilding from the active prefix visually extends the collection rail as
		# each capacity requisition is approved; hidden desks never leave floating
		# trays behind.
		_office_storytelling.configure(
			_active_desk_positions(capacity),
			Vector3(9.55, 0.0, 5.35),
			Vector3(9.4, 0.0, -6.85),
		)


func _apply_office_physical_presentation(capacity: int) -> void:
	capacity = clampi(capacity, 0, MAXIMUM_OFFICE_CAPACITY)
	var dormant_visible := (
		_capacity_marker_context_revealed
		and capacity < MAXIMUM_OFFICE_CAPACITY
		and not _first_clutch_tracking_active()
	)
	if _office_physical_presentation != null:
		_office_physical_presentation.visible = true
	if _core_office_presentation != null:
		_core_office_presentation.visible = true
	if _west_lease_partition != null:
		_west_lease_partition.visible = capacity < 5
	if _west_second_perch_flex_furnishings != null:
		_west_second_perch_flex_furnishings.visible = capacity < MAXIMUM_OFFICE_CAPACITY
	if _dormant_west_presentation != null:
		_dormant_west_presentation.visible = dormant_visible
	if _west_perch_04_presentation != null:
		_west_perch_04_presentation.visible = capacity >= 5
	if _west_perch_05_presentation != null:
		_west_perch_05_presentation.visible = capacity >= MAXIMUM_OFFICE_CAPACITY
	if _archive_presentation != null:
		_archive_presentation.visible = capacity >= MAXIMUM_OFFICE_CAPACITY
	if _intake_presentation != null:
		_intake_presentation.visible = true
	_apply_office_fill_light_stage(capacity)
	if _office_storytelling != null:
		_office_storytelling.set_office_physical_presentation(capacity, dormant_visible)
	set_meta(&"office_physical_presentation", _office_physical_presentation_state(capacity))


func _apply_office_fill_light_stage(capacity: int) -> void:
	# FluorescentFill_0 sits over the west wing. Its geometry remains authored,
	# but an uncommissioned wing should not cast a mature pool of light. Visibility
	# owns the capacity gate; _update_lighting() remains the sole energy/color owner.
	if _office_fill_lights.is_empty():
		return
	_office_fill_lights[0].visible = capacity >= 5


func _office_physical_presentation_state(capacity: int) -> Dictionary:
	capacity = clampi(capacity, 0, MAXIMUM_OFFICE_CAPACITY)
	var stage: StringName = &"core"
	if capacity >= MAXIMUM_OFFICE_CAPACITY:
		stage = &"full_bureau"
	elif capacity >= 5:
		stage = &"west_front"
	var dormant_visible := (
		_dormant_west_presentation != null
		and _dormant_west_presentation.visible
	)
	return {
		"capacity": capacity,
		"stage": stage,
		"core_visible": _core_office_presentation != null and _core_office_presentation.visible,
		"west_partition_visible": _west_lease_partition != null and _west_lease_partition.visible,
		"dormant_west_visible": dormant_visible,
		"west_perch_04_visible": _west_perch_04_presentation != null and _west_perch_04_presentation.visible,
		"west_perch_05_visible": _west_perch_05_presentation != null and _west_perch_05_presentation.visible,
		"archive_visible": _archive_presentation != null and _archive_presentation.visible,
		"intake_visible": _intake_presentation != null and _intake_presentation.visible,
		"next_perch_index": capacity if dormant_visible and capacity < MAXIMUM_OFFICE_CAPACITY else -1,
	}


func _animate_capacity_stage_handoff(previous_capacity: int, capacity: int) -> void:
	if previous_capacity < 0 or capacity <= previous_capacity or not is_inside_tree():
		return
	if _capacity_stage_tween != null:
		_capacity_stage_tween.kill()
	_capacity_stage_tween = null

	var staged_roots: Array[Node3D] = []
	if previous_capacity < 5 and capacity >= 5 and _west_perch_04_presentation != null:
		staged_roots.append(_west_perch_04_presentation)
	if previous_capacity < MAXIMUM_OFFICE_CAPACITY and capacity >= MAXIMUM_OFFICE_CAPACITY:
		if _west_perch_05_presentation != null:
			staged_roots.append(_west_perch_05_presentation)
		if _archive_presentation != null:
			staged_roots.append(_archive_presentation)
	if staged_roots.is_empty():
		return

	# Reduced motion keeps the same final state and transient receipt, but avoids
	# moving architecture or ramping the fluorescent fixture.
	if _prefers_reduced_motion():
		return
	_capacity_stage_tween = _presentation_tween(self).set_parallel(true)
	_capacity_stage_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for stage_root: Node3D in staged_roots:
		var final_position := stage_root.position
		stage_root.position = final_position + Vector3(0.0, -0.22, 0.0)
		stage_root.scale = Vector3(0.985, 0.92, 0.985)
		_capacity_stage_tween.tween_property(
			stage_root, "position", final_position, CAPACITY_COMMISSIONING_REVEAL_SECONDS,
		).set_delay(0.12)
		_capacity_stage_tween.tween_property(
			stage_root, "scale", Vector3.ONE, CAPACITY_COMMISSIONING_REVEAL_SECONDS,
		).set_delay(0.12)

	if previous_capacity < 5 and capacity >= 5 and _west_lease_partition != null:
		var partition_home := _west_lease_partition.position
		_west_lease_partition.visible = true
		_west_lease_partition.position = partition_home
		_capacity_stage_tween.tween_property(
			_west_lease_partition,
			"position",
			partition_home + Vector3(0.0, -0.62, 0.0),
			CAPACITY_COMMISSIONING_REVEAL_SECONDS,
		).set_delay(0.04)
		_capacity_stage_tween.tween_callback(
			func() -> void:
				if _west_lease_partition != null:
					_west_lease_partition.visible = false
					_west_lease_partition.position = partition_home
		).set_delay(CAPACITY_COMMISSIONING_REVEAL_SECONDS + 0.05)
	if previous_capacity < 5 and capacity >= 5 and not _office_fill_lights.is_empty():
		var west_fill := _office_fill_lights[0]
		west_fill.light_energy = 0.0
		_capacity_stage_tween.tween_property(
			west_fill,
			"light_energy",
			OFFICE_FILL_LIGHT_ENERGY,
			CAPACITY_COMMISSIONING_REVEAL_SECONDS + 0.20,
		).set_delay(0.16)


func _begin_capacity_commissioning_beat(result: Dictionary) -> void:
	_stop_capacity_commissioning_beat()
	var capacity := clampi(
		int(result.get("office_capacity", _displayed_office_capacity)),
		1,
		MAXIMUM_OFFICE_CAPACITY,
	)
	var perch_index := capacity - 1
	var cost_cents := maxi(0, int(result.get("cost_cents", 0)))
	var daily_cents := maxi(0, int(result.get("added_daily_operating_cents", 0)))
	var reduced_motion := _prefers_reduced_motion()
	_capacity_commissioning_state = {
		"active": true,
		"phase": &"commissioning",
		"capacity": capacity,
		"perch_index": perch_index,
		"cost_cents": cost_cents,
		"added_daily_operating_cents": daily_cents,
		"reduced_motion": reduced_motion,
	}

	var beat := Node3D.new()
	beat.name = "CapacityCommissioningBeat"
	beat.position = desk_position(perch_index)
	beat.set_meta(&"visual_only", true)
	beat.set_meta(&"collision_free", true)
	beat.set_meta(&"navigation_free", true)
	add_child(beat)
	_capacity_commissioning_root = beat

	var filed_color := Color("6ccfba")
	var filed_material := StandardMaterial3D.new()
	filed_material.albedo_color = filed_color.darkened(0.46)
	filed_material.roughness = 0.42
	filed_material.emission_enabled = true
	filed_material.emission = filed_color
	filed_material.emission_energy_multiplier = 1.7
	for side_z in [-1.0, 1.0]:
		var rail_z := _add_box(
			beat,
			"CommissioningRailZ",
			Vector3(2.78, 0.035, 0.07),
			Vector3(0.0, 0.052, side_z * 0.79),
			filed_color,
		)
		rail_z.material_override = filed_material
		rail_z.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side_x in [-1.0, 1.0]:
		var rail_x := _add_box(
			beat,
			"CommissioningRailX",
			Vector3(0.07, 0.035, 1.58),
			Vector3(side_x * 1.39, 0.052, 0.0),
			filed_color,
		)
		rail_x.material_override = filed_material
		rail_x.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var filed_label := Label3D.new()
	filed_label.name = "CapacityCommissioningLabel"
	filed_label.text = "PERCH %d  /  COMMISSIONED\n$%.2f FILED  •  +$%.2f / SHIFT" % [
		capacity,
		float(cost_cents) / 100.0,
		float(daily_cents) / 100.0,
	]
	filed_label.position = Vector3(0.0, 2.52, 0.72)
	filed_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	filed_label.fixed_size = false
	filed_label.pixel_size = 0.012
	filed_label.font_size = 24
	filed_label.outline_size = 5
	filed_label.modulate = Color("e9f5df")
	filed_label.outline_modulate = Color("173138")
	filed_label.no_depth_test = true
	beat.add_child(filed_label)

	beat.scale = Vector3.ONE if reduced_motion else Vector3(0.84, 0.84, 0.84)
	_capacity_commissioning_tween = _presentation_tween(beat)
	if not reduced_motion:
		_capacity_commissioning_tween.tween_property(
			beat,
			"scale",
			Vector3.ONE,
			CAPACITY_COMMISSIONING_REVEAL_SECONDS,
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_capacity_commissioning_tween.tween_interval(CAPACITY_COMMISSIONING_HOLD_SECONDS)
	if not reduced_motion:
		_capacity_commissioning_tween.tween_property(
			beat,
			"scale",
			Vector3(1.035, 0.90, 1.035),
			CAPACITY_COMMISSIONING_SETTLE_SECONDS,
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_capacity_commissioning_tween.tween_callback(_complete_capacity_commissioning_beat)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _complete_capacity_commissioning_beat() -> void:
	_capacity_commissioning_state["active"] = false
	_capacity_commissioning_state["phase"] = &"complete"
	if _capacity_commissioning_root != null and is_instance_valid(_capacity_commissioning_root):
		_capacity_commissioning_root.queue_free()
	_capacity_commissioning_root = null
	_capacity_commissioning_tween = null
	_publish_web_diagnostic_state(_simulation.snapshot())


func _stop_capacity_commissioning_beat() -> void:
	if _capacity_commissioning_tween != null:
		_capacity_commissioning_tween.kill()
	_capacity_commissioning_tween = null
	if _capacity_commissioning_root != null and is_instance_valid(_capacity_commissioning_root):
		_capacity_commissioning_root.free()
	_capacity_commissioning_root = null
	if bool(_capacity_commissioning_state.get("active", false)):
		_capacity_commissioning_state["active"] = false
		_capacity_commissioning_state["phase"] = &"interrupted"


func _capacity_marker_should_be_visible(capacity: int, index: int) -> bool:
	if capacity >= MAXIMUM_OFFICE_CAPACITY or index != capacity:
		return false
	if _first_clutch_tracking_active():
		return false
	return _capacity_marker_context_revealed


func _set_capacity_marker_context_revealed(revealed: bool) -> void:
	if revealed and _first_clutch_tracking_active():
		revealed = false
	if _capacity_marker_context_revealed == revealed or _simulation == null:
		return
	_capacity_marker_context_revealed = revealed
	_apply_office_capacity_visibility(
		_office_capacity_from_snapshot(_simulation.snapshot()),
		false,
	)


func _reveal_capacity_marker_context() -> void:
	_set_capacity_marker_context_revealed(true)


func _refresh_workstation_nameplates(snapshot: Dictionary) -> void:
	var fingerprint_parts: Array = [_office_capacity_from_snapshot(snapshot)]
	for worker_value in snapshot.get("workers", []):
		var fingerprint_worker := worker_value as Dictionary
		if not _is_worker_employed(fingerprint_worker):
			continue
		fingerprint_parts.append([
			int(fingerprint_worker.get("id", -1)),
			int(fingerprint_worker.get("desk_index", -1)),
			String(fingerprint_worker.get("name", fingerprint_worker.get("display_name", ""))),
			String(fingerprint_worker.get("career_title", "")),
		])
	var fingerprint := hash(fingerprint_parts)
	if fingerprint == _workstation_nameplate_fingerprint:
		return
	_workstation_nameplate_fingerprint = fingerprint
	var occupants: Dictionary[int, Dictionary] = {}
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if not _is_worker_employed(worker):
			continue
		var desk_index := int(worker.get("desk_index", -1))
		if desk_index >= 0 and desk_index < MAXIMUM_OFFICE_CAPACITY:
			occupants[desk_index] = {
				"name": String(worker.get("name", worker.get("display_name", "HEN %d" % (desk_index + 1)))).to_upper(),
				"role": String(worker.get("career_title", "PECKWORK HEN")).to_upper(),
			}
	var capacity := _office_capacity_from_snapshot(snapshot)
	for index in MAXIMUM_OFFICE_CAPACITY:
		var label: Label3D = _workstation_nameplates.get(index)
		if label == null:
			continue
		var occupant: Dictionary = occupants.get(index, {})
		label.text = String(occupant.get(
			"name", "VACANT PERCH" if index < capacity else "PERCH PENDING"
		))
		EnvironmentalSignageScript.refit_label(label)
		var body := label.get_parent().find_child("EmployeeNameplateTextBody", false, false) as Label3D
		if body != null:
			body.text = String(occupant.get(
				"role", "AUTHORIZED POSITION" if index < capacity else "CAPACITY HOLD"
			))
			EnvironmentalSignageScript.refit_label(body)


func _is_worker_employed(worker: Dictionary) -> bool:
	if worker.has("employed"):
		return bool(worker.get("employed", false))
	var status := StringName(String(worker.get("employment_status", "employed")))
	return int(worker.get("desk_index", -1)) >= 0 and status not in [&"applicant", &"released", &"inactive"]


func _snapshot_with_active_workers(snapshot: Dictionary) -> Dictionary:
	# The authoritative read model is already a disposable value object. Only the
	# worker rows are filtered or enriched here, so deep-copying every facility,
	# campus quote, history row, and economic filing on every tick is wasted work.
	var filtered := snapshot.duplicate()
	var active_workers: Array[Dictionary] = []
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if _is_worker_employed(worker):
			# Presentation consumers treat authoritative worker rows as immutable.
			# The filtered array is new, so retaining row references avoids cloning
			# every nested claim, temperament, bond, and action receipt each tick.
			active_workers.append(worker)
	filtered["workers"] = active_workers
	return filtered


func _workstation_visual_snapshot(active_snapshot: Dictionary) -> Dictionary:
	# WorkstationFeedback reads only this compact visual state. Returning the complete
	# economy made its presentation call retain dozens of unrelated projections.
	var visual_snapshot := {
		"strategy_id": String((active_snapshot.get("active_playbook", {}) as Dictionary).get("strategy_preset_id", "")),
		"upgrade_levels": (
			active_snapshot.get("upgrade_levels", {}) as Dictionary
		).duplicate(true),
		"routing_momentum": (
			active_snapshot.get("routing_momentum", {}) as Dictionary
		).duplicate(true),
	}
	# Feedback consumes these rows synchronously and reads them without mutation.
	var visual_workers: Array = []
	var occupied: Dictionary[int, bool] = {}
	for worker_value in active_snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		visual_workers.append(worker)
		occupied[int(worker.get("desk_index", -1))] = true
	var capacity := _office_capacity_from_snapshot(active_snapshot)
	for desk_index in capacity:
		if occupied.has(desk_index):
			continue
		visual_workers.append({
			"id": -1000 - desk_index,
			"desk_index": desk_index,
			"state": ChickenState.WorkState.IDLE,
			"progress": 0.0,
			"stress": 0.0,
			"at_workstation": false,
			"assigned_lane": &"auto",
		})
	visual_snapshot["workers"] = visual_workers
	return visual_snapshot


func _routing_visual_snapshot(active_snapshot: Dictionary) -> Dictionary:
	# Build one UI-owned projection limited to dossier, queue, and personnel
	# fields. Campus, capital, contract, and economic briefing projections never
	# belong in the per-tick routing payload.
	var routing_snapshot: Dictionary = {}
	for key: String in [
		"day",
		"shift_phase",
		"routing",
		"routing_catalog",
		"claim_queue_counts",
		"claim_queue_overdue_counts",
		"claim_queue_items",
		"overdue_claims",
		"last_peck_assist",
		"peck_assists_remaining",
		"peck_assist_pending_delivery_count",
		"peck_assist_limit",
		"routing_momentum",
		"personnel_action_status",
		"personnel_action_used",
		"personnel_action_available",
		"spendable_fund_cents",
		"revenue_cents",
		"operations",
		"flock_care",
		"training_terms",
		"personnel_catalog",
		"claim_resolution_catalog",
	]:
		if active_snapshot.has(key):
			routing_snapshot[key] = active_snapshot[key]
	var routing_workers: Array[Dictionary] = []
	for worker_value in active_snapshot.get("workers", []):
		# Only estimated_crack_risk is enriched here. A shallow row copy protects
		# the authoritative row while reusing immutable nested claim/profile data.
		var worker := (worker_value as Dictionary).duplicate()
		var worker_id := int(worker.get("id", -1))
		worker["estimated_crack_risk"] = _simulation.estimated_crack_risk(worker_id)
		routing_workers.append(worker)
	routing_snapshot["workers"] = routing_workers
	routing_snapshot["egg_journey_receipts"] = _egg_journey_receipt_snapshot()
	var assignment_undo := _validated_routing_assignment_undo(active_snapshot)
	if not assignment_undo.is_empty():
		routing_snapshot["assignment_undo"] = assignment_undo
	return routing_snapshot


func _spawn_worker_view(worker_data: Dictionary, arrival_order: int = -1) -> ChickenView:
	var worker_id := int(worker_data.get("id", -1))
	var worker_index := int(worker_data.get("desk_index", -1))
	if worker_id < 0 or worker_index < 0 or worker_index >= MAXIMUM_OFFICE_CAPACITY:
		return null
	if _worker_views.has(worker_id):
		var existing: ChickenView = _worker_views[worker_id]
		existing.apply_snapshot(worker_data)
		return existing
	# A worker ID must own at most one visible ChickenView across both lifecycle
	# registries. This defensive edge covers a restore or rapid roster reversal
	# arriving before the old departure route has emitted its completion signal.
	if _departing_worker_views.has(worker_id):
		var stale_departure := _departing_worker_views.get(worker_id) as ChickenView
		_departing_worker_views.erase(worker_id)
		if stale_departure != null and is_instance_valid(stale_departure):
			stale_departure.visible = false
			stale_departure.set_physics_process(false)
			stale_departure.queue_free()
	var view := ChickenViewScript.new() as ChickenView
	view.set_reduced_motion(_prefers_reduced_motion())
	view.configure(worker_data)
	_workers_node.add_child(view)
	view.set_presentation_update_rate_hz(_worker_presentation_rate_hz)
	view.set_route_progress_held(_worker_routes_should_hold())
	view.feed_party_attendance_ready.connect(_on_feed_party_attendance_ready)
	view.feed_party_attendance_completed.connect(_on_feed_party_attendance_completed)
	view.workstation_presence_changed.connect(_on_worker_workstation_presence_changed)
	view.office_departure_completed.connect(_on_worker_departure_completed.bind(view))
	view.management_selection_requested.connect(_on_world_worker_selected)
	view.work_peck_contact.connect(_on_work_peck_contact)
	view.priority_peck_contact.connect(_on_priority_peck_contact)
	view.lay_release_reached.connect(_on_lay_release_reached)
	view.assign_office_route(
		entry_position(worker_index),
		chair_position(worker_index),
		break_position(worker_index),
		arrival_route(worker_index),
		wellness_route(worker_index),
		_worker_views.size() if arrival_order < 0 else arrival_order,
	)
	view.configure_break_interaction(
		break_interaction_kind(worker_index),
		break_interaction_face_point(worker_index),
	)
	_worker_views[worker_id] = view
	view.set_management_focus(
		worker_id == _intent_focus_worker_id,
		_intent_focus_worker_id >= 0,
	)
	if _dispatch_lane != &"":
		view.set_dispatch_candidate(
		_dispatch_candidate_for(worker_id).size() > 0,
		worker_id == _dispatch_recommended_worker_id,
		_dispatch_lane,
		)
	_simulation.set_worker_at_workstation(worker_id, view.is_seated_at_workstation())
	if _camera_controller != null:
		_camera_controller.register_worker(worker_id, view)
	return view


func _reconcile_worker_views(snapshot: Dictionary) -> void:
	var employed_by_id: Dictionary[int, Dictionary] = {}
	var arrival_order := 0
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if not _is_worker_employed(worker):
			continue
		var worker_id := int(worker.get("id", -1))
		if _predator_removed_worker_ids.has(worker_id):
			continue
		employed_by_id[worker_id] = worker
		if not _worker_views.has(worker_id):
			_spawn_worker_view(worker, arrival_order)
		arrival_order += 1
	for worker_id in _worker_views.keys().duplicate():
		if not employed_by_id.has(worker_id):
			_begin_worker_departure(int(worker_id))


func _begin_worker_departure(worker_id: int) -> void:
	var view: ChickenView = _worker_views.get(worker_id)
	_campus_worker_assignments.erase(worker_id)
	_campus_worker_pads.erase(worker_id)
	if view == null or not is_instance_valid(view):
		_worker_views.erase(worker_id)
		return
	_worker_views.erase(worker_id)
	_departing_worker_views[worker_id] = view
	_simulation.set_worker_at_workstation(worker_id, false)
	if _camera_controller != null:
		_camera_controller.unregister_worker(worker_id)
	view.depart_office(departure_route(view.desk_index))


func _on_worker_departure_completed(worker_id: int, view: ChickenView) -> void:
	_departing_worker_views.erase(worker_id)
	if view != null and is_instance_valid(view):
		view.queue_free()


## Debug showcase: press F once the office has active employees. It exercises
## the live ChickenView asset and leaves normal simulation pacing unchanged
## until explicitly requested.
func _trigger_predator_debug_encounter() -> void:
	if _predator_encounter == null:
		return
	for worker_id in _worker_views.keys():
		var worker_view := _worker_views[worker_id] as ChickenView
		if (
			worker_view != null
			and is_instance_valid(worker_view)
			and not worker_view.has_campus_duty_assignment()
		):
			var desk_index := worker_view.desk_index
			if _predator_encounter.play(
				worker_view,
				entry_position(desk_index),
				arrival_route(desk_index),
				departure_route(desk_index),
			):
				return


func _on_predator_victim_carried_away(worker_id: int) -> void:
	_predator_removed_worker_ids[worker_id] = true
	_worker_views.erase(worker_id)
	_campus_worker_assignments.erase(worker_id)
	_campus_worker_pads.erase(worker_id)
	_simulation.set_worker_at_workstation(worker_id, false)
	if _camera_controller != null:
		_camera_controller.unregister_worker(worker_id)


func _on_predator_victim_captured(worker_id: int, threat_origin: Vector3) -> void:
	# The victim is already clamped to the fox; every remaining live employee
	# gets its own deterministic scatter route away from that point.
	for remaining_worker_id in _worker_views.keys():
		if remaining_worker_id == worker_id:
			continue
		var worker_view := _worker_views[remaining_worker_id] as ChickenView
		if worker_view != null and is_instance_valid(worker_view):
			worker_view.begin_predator_panic(threat_origin)


func _process(delta: float) -> void:
	_hud_measure_elapsed += delta
	if _hud_measure_elapsed >= 0.5:
		_hud_measure_elapsed = 0.0
		_measure_live_hud_canvas()
	if _first_reward_ready_msec > 0 and Time.get_ticks_msec() >= _first_reward_ready_msec:
		if _first_clutch_reinvestment_resolved() or _present_first_clutch_reinvestment():
			_first_reward_ready_msec = 0
	# Browsers can occasionally swallow a key-up when focus moves outside the
	# canvas. Never leave the explain hold or its temporary pause latched.
	if _explain_mode_active and not Input.is_action_pressed(&"explain_mode"):
		_end_explain_mode()
	_sync_held_confirmation_presentation()
	_process_breakroom_life(delta)
	_process_hen_social(delta)
	_process_fund_counter(delta)
	_process_route_settlement_handoff(delta)
	_process_fund_credit_chip_pool(delta)
	_process_auxiliary_settlement_chip_pool(delta)
	_process_egg_fleck_pool(delta)
	_flush_due_campaign_checkpoint()
	if (
		_character_dialogue_ui != null
		and _character_dialogue_ui.has_blocking_dialogue()
	):
		_hold_clock_for_character_dialogue()
	else:
		_try_restore_character_dialogue_clock()
	_sync_worker_route_progress_hold()
	var blocking_surface_open := _blocking_management_surface_open()
	var opening_task_only := _first_hen_prelude_pending()
	var first_clutch_compact := (
		not bool(_first_clutch.get("dismissed", true))
		and not bool(_first_clutch.get("completed", false))
	)
	_apply_live_hud_presentation(first_clutch_compact)
	if _campaign_ui != null:
		var campaign_modal_open := _campaign_ui.is_modal_open()
		_campaign_ui.set_badge_presentation(
			_live_hud_routing_top(),
			first_clutch_compact or _flockwatch_open or (_simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING and not _explain_strip.visible) or (blocking_surface_open and not campaign_modal_open),
		)
	if _top_hud_panel != null:
		_top_hud_panel.visible = not blocking_surface_open
	if _speed_control != null:
		_speed_control.visible = not opening_task_only
	if _flockwatch_toggle != null:
		_flockwatch_toggle.visible = not blocking_surface_open and not opening_task_only
	if _routing_ui != null:
		_routing_ui.visible = not blocking_surface_open and not _flockwatch_open
	if _character_dialogue_ui != null:
		# A Priority Peck result is a brief, player-caused consequence beat. Queue
		# ambient floor chat behind it so the dossier and world response remain the
		# only competing signals; the unchanged aside resumes as soon as the bounded
		# hold ends.
		var priority_result_visible := (
			_priority_peck_result_hold_worker_id >= 0
			and Time.get_ticks_msec() < _priority_peck_result_hold_until_msec
		)
		_character_dialogue_ui.set_suspended(
			blocking_surface_open or _flockwatch_open or priority_result_visible
		)
	# Existing systems publish through the stable ticker label. Detect those
	# publications here so legacy callers retain their exact copy and receipts,
	# while the presentation becomes a short-lived toast instead of a permanent
	# fifty-four-pixel wall across the playable floor.
	if _ticker_label == null or _ticker_panel == null:
		return
	var copy := _ticker_label.text.strip_edges()
	var now_msec := Time.get_ticks_msec()
	var restored_priority_display := (
		_ticker_panel.visible
		and not _ticker_visible_copy.is_empty()
		and copy == _ticker_visible_copy
		and copy != _ticker_last_text
	)
	var copy_changed := copy != _ticker_last_text
	if copy_changed and not restored_priority_display:
		_ticker_last_accessible_text = copy
		_ticker_last_publish_msec = now_msec
		_record_status_copy(copy)
	if _character_dialogue_ui != null and _character_dialogue_ui.is_presenting():
		# A character aside gets the player's reading attention. Preserve every
		# exact system receipt in Shift Record/Flockwatch, but avoid stacking a
		# second prose surface over the playable floor at the same time.
		_ticker_panel.visible = false
		_ticker_visible_copy = ""
		_ticker_visible_accessible_text = ""
		if not _ticker_last_text.is_empty():
			_ticker_label.text = _ticker_last_text
		return
	if blocking_surface_open or _flockwatch_open:
		_ticker_panel.visible = false
		_ticker_visible_copy = ""
		_ticker_visible_accessible_text = ""
		if not _ticker_last_text.is_empty():
			_ticker_label.text = _ticker_last_text
		return
	if restored_priority_display:
		if now_msec >= _ticker_hide_at_msec:
			_ticker_panel.visible = false
			_ticker_visible_copy = ""
			_ticker_visible_accessible_text = ""
			_ticker_label.text = _ticker_last_text
			return
		return
	if copy_changed:
		if _should_preserve_priority_toast(copy, now_msec):
			# Archive the incoming lower-priority publication while the player still
			# needs the held action or milestone. Restoring the visible copy keeps
			# legacy publishers from stealing the only urgent reading surface.
			_ticker_label.text = _ticker_visible_copy
		elif not copy.is_empty() and _should_present_status_toast(copy):
			var starts_new_toast := (
				not _ticker_panel.visible
				or _ticker_visible_copy != copy
			)
			_ticker_panel.visible = true
			_ticker_visible_copy = copy
			_ticker_visible_accessible_text = copy
			if starts_new_toast:
				_ticker_shown_at_msec = now_msec
				_ticker_hide_at_msec = now_msec + _status_toast_hold_msec()
		else:
			_ticker_panel.visible = false
			_ticker_visible_copy = ""
			_ticker_visible_accessible_text = ""
	elif _ticker_panel.visible and now_msec >= _ticker_hide_at_msec:
		_ticker_panel.visible = false
		_ticker_visible_copy = ""
		_ticker_visible_accessible_text = ""


func _process_hen_social(delta: float, capture_start: bool = false) -> void:
	if _hen_social_ui == null or _management_camera == null:
		return
	for view_value in _worker_views.values():
		(view_value as ChickenView).set_social_attention(Vector3.ZERO, 0.0, false)
	var blocked := _blocking_management_surface_open() or _flockwatch_open or _first_hen_prelude_pending()
	blocked = blocked or (_character_dialogue_ui != null and _character_dialogue_ui.is_presenting())
	blocked = blocked or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
	if blocked:
		_hen_social_ui.hide()
		return
	var eligible: Array[Dictionary] = []
	var extent := get_viewport().get_visible_rect().size
	for value in _hen_social_workers:
		var worker := value as Dictionary
		var view := _worker_views.get(int(worker.id)) as ChickenView
		if not bool(worker.get("employed", false)) or view == null or not view.social_present():
			continue
		var point := view.global_position + Vector3.UP
		var in_conversation := not _hen_social.current.is_empty() and int(worker.id) in [int(_hen_social.current.first_id), int(_hen_social.current.second_id)]
		if _management_camera.is_position_behind(point) and not in_conversation:
			continue
		var screen := _management_camera.unproject_position(point)
		if not in_conversation and not Rect2(Vector2(0.0, 130.0), extent - Vector2(0.0, 240.0)).has_point(screen):
			continue
		eligible.append({"id": worker.id, "name": worker.name, "stress": worker.get("stress", 0.0), "position": view.global_position, "ready": view.social_available(), "relationships": worker.get("relationships", []), "partner_id": worker.get("partnership_partner_id", -1)})
	var advancing := _clock.speed_index > 0
	_hen_social.advance(delta if advancing else 0.0, eligible, advancing or capture_start)
	if _hen_social.current.is_empty():
		_hen_social_ui.hide()
		return
	var beat := _hen_social.current
	var first := _worker_views.get(int(beat.first_id)) as ChickenView
	var second := _worker_views.get(int(beat.second_id)) as ChickenView
	var replying := _hen_social.elapsed >= HenSocialDirector.REPLY_AT
	var envelope := smoothstep(0.0, 0.4, _hen_social.elapsed) * (1.0 - smoothstep(7.5, 8.0, _hen_social.elapsed))
	first.set_social_attention(second.global_position, envelope if first.social_available() else 0.0, not replying)
	second.set_social_attention(first.global_position, envelope if second.social_available() else 0.0, replying)
	var speaker := second if replying else first
	var speaker_point := speaker.global_position + Vector3.UP * 1.7
	var speaker_screen := _management_camera.unproject_position(speaker_point)
	# Camera/layout transitions may briefly project a perch outside the screen.
	# Hide its caption, but keep the bounded exchange and paused reading position.
	if _management_camera.is_position_behind(speaker_point) or not Rect2(Vector2.ZERO, extent).has_point(speaker_screen):
		_hen_social_ui.hide()
		return
	var avoid := _flockwatch_toggle.get_global_rect() if _flockwatch_toggle != null and _flockwatch_toggle.visible else Rect2()
	_hen_social_ui.present(beat, replying, speaker_screen, extent, avoid)


func _process_breakroom_life(delta: float) -> void:
	if (
		_breakroom_cooler_bubbles.is_empty()
		and _breakroom_coffee_steam.is_empty()
		and _breakroom_lounge_pouf == null
	):
		return
	var reduced_motion := _prefers_reduced_motion()
	if not reduced_motion:
		_breakroom_life_elapsed += delta * _animation_speed_multiplier

	var water_active := _breakroom_activity_active(0, &"water")
	var coffee_active := _breakroom_activity_active(1, &"coffee")
	var lounge_active := _breakroom_activity_active(2, &"lounge")
	var browse_active := _breakroom_activity_active(3, &"browse")
	var bulletin_active := _breakroom_activity_active(4, &"bulletin")

	# The jug is never visually frozen: slow bubbles establish that it contains
	# water, while an active visit adds a small acceleration at the dispenser.
	for bubble_index in _breakroom_cooler_bubbles.size():
		var bubble := _breakroom_cooler_bubbles[bubble_index]
		if bubble == null or not is_instance_valid(bubble):
			continue
		var bubble_progress := fmod(
			_breakroom_life_elapsed * (0.13 if not water_active else 0.24)
			+ bubble_index * 0.24,
			1.0,
		)
		bubble.position.y = 1.04 + bubble_progress * 0.43
		bubble.position.x = -11.05 + sin(_breakroom_life_elapsed * 0.66 + bubble_index) * 0.055
		var bubble_scale := 0.70 + bubble_progress * 0.38
		bubble.scale = Vector3(0.045, 0.055, 0.045) * bubble_scale

	for steam_index in _breakroom_coffee_steam.size():
		var steam := _breakroom_coffee_steam[steam_index]
		if steam == null or not is_instance_valid(steam):
			continue
		steam.visible = coffee_active
		if not coffee_active:
			continue
		var steam_progress := fmod(
			_breakroom_life_elapsed * 0.31 + steam_index * 0.34,
			1.0,
		)
		steam.position = Vector3(
			-10.98 + sin(_breakroom_life_elapsed * 0.72 + steam_index) * 0.055,
			1.70 + steam_progress * 0.48,
			-2.35 + cos(_breakroom_life_elapsed * 0.48 + steam_index) * 0.025,
		)
		var steam_scale := 0.58 + steam_progress * 0.62
		steam.scale = Vector3(
			0.055 * steam_scale,
			0.14 * (0.72 + steam_progress),
			0.055 * steam_scale,
		)

	if _breakroom_lounge_pouf != null and is_instance_valid(_breakroom_lounge_pouf):
		var pouf_target_y := (
			0.78 + sin(_breakroom_life_elapsed * 1.45) * 0.018
			if lounge_active else
			1.0
		)
		_breakroom_lounge_pouf.scale.y = lerpf(
			_breakroom_lounge_pouf.scale.y,
			pouf_target_y,
			minf(1.0, delta * 4.8),
		)
		var pouf_compression := 1.0 - _breakroom_lounge_pouf.scale.y
		_breakroom_lounge_pouf.scale.x = 1.0 + pouf_compression * 0.11
		_breakroom_lounge_pouf.scale.z = 1.0 + pouf_compression * 0.11
		_breakroom_lounge_pouf.position.y = (
			_breakroom_lounge_pouf_rest_y - pouf_compression * 0.055
		)

	# Once Dot picks up the magazine, the table copy disappears. Returning it on
	# departure makes the interaction read as a complete prop lifecycle.
	if _breakroom_magazine != null:
		_breakroom_magazine.visible = not browse_active
	if _breakroom_magazine_pages != null:
		_breakroom_magazine_pages.visible = not browse_active

	for leaf_index in _breakroom_plant_leaves.size():
		var leaf := _breakroom_plant_leaves[leaf_index]
		if leaf == null or not is_instance_valid(leaf):
			continue
		var rest_rotation := _breakroom_plant_leaf_rest_rotations[leaf_index]
		leaf.rotation = rest_rotation
		if not reduced_motion:
			leaf.rotation.z += sin(_breakroom_life_elapsed * 0.72 + leaf_index * 0.84) * 0.025

	for note_index in _breakroom_pinned_notes.size():
		var note := _breakroom_pinned_notes[note_index]
		if note == null or not is_instance_valid(note):
			continue
		note.rotation.x = 0.0
		if bulletin_active and not reduced_motion:
			note.rotation.x = sin(_breakroom_life_elapsed * 1.35 + note_index * 0.72) * 0.018


func _breakroom_activity_active(worker_id: int, activity_kind: StringName) -> bool:
	if not _worker_views.has(worker_id):
		return false
	var worker_view := _worker_views[worker_id] as ChickenView
	return (
		worker_view != null
		and is_instance_valid(worker_view)
		and worker_view.break_interaction_kind_name() == activity_kind
		and worker_view.break_interaction_active()
	)


func _record_status_copy(copy: String, publish_flockwatch_diagnostic := true) -> void:
	_ticker_last_text = copy
	if copy.is_empty():
		return
	if _status_history.is_empty() or _status_history[0] != copy:
		_status_history.push_front(copy)
		if _status_history.size() > STATUS_HISTORY_LIMIT:
			_status_history.resize(STATUS_HISTORY_LIMIT)
	_refresh_status_history_presentation()
	if _flockwatch_navigation != null:
		_flockwatch_navigation.set_last_feedback(copy)
	if publish_flockwatch_diagnostic and _flockwatch_open and _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _publish_status_copy(
	copy: String,
	publish_flockwatch_diagnostic := true,
	accessible_copy := "",
) -> void:
	if _ticker_label == null or _ticker_panel == null:
		return
	var incoming_semantic := accessible_copy if not accessible_copy.is_empty() else copy
	var now_msec := Time.get_ticks_msec()
	_ticker_label.text = copy
	_ticker_label.tooltip_text = incoming_semantic
	_ticker_label.accessibility_name = incoming_semantic
	_ticker_label.set_meta("accessible_text", incoming_semantic)
	_ticker_last_accessible_text = incoming_semantic
	_ticker_last_publish_msec = now_msec
	_record_status_copy(copy, publish_flockwatch_diagnostic)
	if _blocking_management_surface_open() or _flockwatch_open:
		_ticker_panel.visible = false
		_ticker_visible_copy = ""
		_ticker_visible_accessible_text = ""
		return
	var semantic_copy := incoming_semantic
	if _should_preserve_priority_toast(copy, now_msec):
		_ticker_label.text = _ticker_visible_copy
		semantic_copy = (
			_ticker_visible_accessible_text
			if not _ticker_visible_accessible_text.is_empty() else
			_ticker_visible_copy
		)
	elif not copy.is_empty() and _should_present_status_toast(copy):
		_ticker_panel.visible = true
		_ticker_visible_copy = copy
		_ticker_visible_accessible_text = incoming_semantic
		_ticker_shown_at_msec = now_msec
		_ticker_hide_at_msec = now_msec + _status_toast_hold_msec()
	else:
		_ticker_panel.visible = false
		_ticker_visible_copy = ""
		_ticker_visible_accessible_text = ""
	_ticker_label.tooltip_text = semantic_copy
	_ticker_label.accessibility_name = semantic_copy
	_ticker_label.set_meta("accessible_text", semantic_copy)


func _publish_economic_action_hold(
	visible_scope: String,
	next_action: String,
	reason: String,
	accessible_scope := "",
) -> void:
	var normalized_scope := visible_scope.strip_edges().to_upper()
	if normalized_scope.is_empty():
		normalized_scope = "ACTION"
	var normalized_action := next_action.strip_edges().to_upper()
	if normalized_action.is_empty():
		normalized_action = "REVIEW TERMS"
	var semantic_scope := accessible_scope.strip_edges()
	if semantic_scope.is_empty():
		semantic_scope = normalized_scope.to_lower().capitalize()
	var semantic_reason := reason.strip_edges()
	if semantic_reason.is_empty():
		semantic_reason = "Review the current terms and choose an available action."
	var semantic_copy := "%s held. %s" % [semantic_scope, semantic_reason]
	if semantic_reason.to_lower().begins_with(("%s held" % semantic_scope).to_lower()):
		semantic_copy = semantic_reason
	var compact_copy := "%s HELD  ·  %s" % [normalized_scope, normalized_action]
	_present_management_action_hold(compact_copy, semantic_copy)
	_publish_status_copy(
		compact_copy,
		true,
		semantic_copy,
	)


func _present_management_action_hold(copy: String, detail: String) -> void:
	if _held_confirmation_open() or _flockwatch_open:
		return
	if _capital_blueprint_ui != null and bool(_capital_blueprint_ui.call("is_open")):
		_capital_blueprint_ui.call("present_action_hold", copy, detail)
	elif _campus_expansion_ui != null and bool(_campus_expansion_ui.call("is_open")):
		_campus_expansion_ui.call("present_action_hold", copy, detail)
	elif _campus_portfolio_ui != null and bool(_campus_portfolio_ui.call("is_open")):
		_campus_portfolio_ui.call("present_action_hold", copy, detail)
	elif _campaign_ui != null and _campaign_ui.is_modal_open():
		_campaign_ui.present_action_hold(copy, detail)


func _yield_transient_feedback_to(surface: StringName) -> void:
	var toast_visible := (
		_ticker_panel != null
		and _ticker_panel.visible
		and not _ticker_visible_copy.is_empty()
	)
	var toast_copy := _ticker_visible_copy if toast_visible else ""
	if _ticker_panel != null:
		_ticker_panel.visible = false
	_ticker_visible_copy = ""
	if _ticker_label != null and not _ticker_last_text.is_empty():
		_ticker_label.text = _ticker_last_text
	var action_feedback_visible := (
		not _active_action_outcome_panels.is_empty()
		or bool(_latest_action_outcome_receipt.get("visible", false))
	)
	var retired_action_panels := (
		_retire_action_outcome_receipts(surface, false)
		if action_feedback_visible else
		0
	)
	_latest_notification_handoff = {
		"surface": String(surface),
		"toast_retired": toast_visible,
		"toast_copy": toast_copy,
		"toast_priority": (
			String(_status_priority(toast_copy))
			if not toast_copy.is_empty() else
			""
		),
		"action_feedback_retired": action_feedback_visible,
		"retired_action_panel_count": retired_action_panels,
	}


func _on_status_history_toggled(expanded: bool) -> void:
	_status_history_expanded = expanded
	_refresh_status_history_presentation()
	_on_campaign_interface_context_changed()


func _refresh_status_history_presentation() -> void:
	if _status_history_label == null or _status_history_toggle == null:
		return
	var recent_count := mini(5, _status_history.size())
	var can_expand := recent_count > 0
	_status_history_toggle.disabled = not can_expand
	_status_history_toggle.set_pressed_no_signal(_status_history_expanded and can_expand)
	if not can_expand:
		_status_history_toggle.text = "SHIFT RECORD · EMPTY"
	elif _status_history_expanded:
		_status_history_toggle.text = "HIDE SHIFT RECORD · %d" % recent_count
	else:
		_status_history_toggle.text = "SHOW SHIFT RECORD · %d" % recent_count
	_status_history_label.visible = _status_history_expanded and can_expand
	var lines: Array[String] = ["RECENT SHIFT RECORD"]
	for entry: String in _status_history.slice(0, recent_count):
		lines.append("- [%s] %s" % [_status_priority_label(entry), entry])
	_status_history_label.text = "\n".join(lines)


func _status_priority(copy: String) -> StringName:
	var normalized := copy.to_upper()
	for marker: String in [
		"HELD", "LOCKED", "UNAVAILABLE", "REQUIRED", "INCOMPLETE", "FAILED",
		"ERROR", "OVERDUE", "DEFICIT", "ARREARS", "WARNING",
		"CRACKED", "INCIDENT", "RECOVERY",
	]:
		if marker in normalized:
			return &"action"
	for marker: String in [
		"SHIFT COMPLETE", "MILESTONE", "COMMENDATION", " APPROVED",
		"BREAK EVEN",
		" AUTHORIZED", " COMMISSIONED", " FILED", " INSTALLED", " PURCHASED",
		" FUNDED", " RECRUITED", " DELIVERED", " COLLECTED", " STOCKED",
		"INSPECTION COMPLETE", " RESTORED", "FIRST CLUTCH",
	]:
		if marker in normalized:
			return &"milestone"
	return &"routine"


func _status_priority_label(copy: String) -> String:
	match _status_priority(copy):
		&"action":
			return "ACTION"
		&"milestone":
			return "MILESTONE"
		_:
			return "ROUTINE"


func _status_priority_rank(copy: String) -> int:
	match _status_priority(copy):
		&"action":
			return 3
		&"milestone":
			return 2
		_:
			return 1


func _should_present_status_toast(copy: String) -> bool:
	# Pause and speed state already have authoritative, always-visible controls in
	# the top HUD. Repeating them in the floor toast creates a second reading
	# target without adding information. They are still recorded in Shift Record
	# and exposed through the live HUD/accessibility summary.
	if _status_is_hud_clock_echo(copy):
		return false
	match String(_player_preferences.get("notice_level", "all")):
		"priority":
			return _status_priority(copy) != &"routine"
		"archive_only":
			return false
		_:
			return true


func _status_is_hud_clock_echo(copy: String) -> bool:
	var normalized := copy.strip_edges().to_upper()
	return (
		normalized.begins_with("SHIFT PAUSED.")
		or normalized.begins_with("SHIFT RUNNING AT ")
	)


func _status_toast_hold_msec() -> int:
	match String(_player_preferences.get("notice_duration", "standard")):
		"brief":
			return 2800
		"extended":
			return 9000
		_:
			return STATUS_TOAST_HOLD_MSEC


func _should_preserve_priority_toast(incoming_copy: String, now_msec: int) -> bool:
	var current_rank := _status_priority_rank(_ticker_visible_copy)
	var incoming_rank := _status_priority_rank(incoming_copy)
	return (
		_ticker_panel != null
		and _ticker_panel.visible
		and not _ticker_visible_copy.is_empty()
		and now_msec < _ticker_hide_at_msec
		and (
			current_rank > incoming_rank
			# Give one earned receipt time to read. New warnings still interrupt;
			# overlapping rewards remain in the record and on their actual desks.
			or (current_rank == 2 and incoming_rank == 2
				and now_msec - _ticker_shown_at_msec < 1800)
		)
	)


func _blocking_management_surface_open() -> bool:
	return _nonconfirmation_management_surface_open() or _held_confirmation_open()


func _worker_routes_should_hold() -> bool:
	# Art captures deliberately stage routes against a stopped simulation clock,
	# and Feed Party deliberately owns its own real-time attendance sequence.
	if _is_capture_launch() or _feed_party_active:
		return false
	return (
		_clock != null
		and (_clock.speed_index == 0 or _clock.interaction_hold_active())
	)


func _sync_worker_route_progress_hold() -> void:
	var held := _worker_routes_should_hold()
	var shift_pace := (
		maxf(1.0, _clock.effective_multiplier())
		if _clock != null and not _is_capture_launch() and not _feed_party_active
		else 1.0
	)
	if _office_storytelling != null:
		_office_storytelling.set_collection_time_scale(shift_pace)
	for view_value: Variant in _worker_views.values():
		var worker_view := view_value as ChickenView
		if worker_view != null and is_instance_valid(worker_view):
			worker_view.set_route_progress_held(held)
			worker_view.set_route_time_scale(shift_pace)
	for view_value: Variant in _departing_worker_views.values():
		var departing_view := view_value as ChickenView
		if departing_view != null and is_instance_valid(departing_view):
			departing_view.set_route_progress_held(held)
			departing_view.set_route_time_scale(shift_pace)


func _nonconfirmation_management_surface_open() -> bool:
	return (
		(_campaign_ui != null and _campaign_ui.is_modal_open())
		or (_shift_challenge_ui != null and _shift_challenge_ui.visible)
		or (_flock_ties_ui != null and _flock_ties_ui.visible)
		or (_decision_host != null and _decision_host.visible)
		or (_day_review_scrim != null and _day_review_scrim.visible)
		or (_settings_ui != null and _settings_ui.visible)
		or (_capital_blueprint_ui != null and _capital_blueprint_ui.visible)
		or (_campus_portfolio_ui != null and _campus_portfolio_ui.visible)
		or (_campus_expansion_ui != null and _campus_expansion_ui.visible)
		or (_commissioning_reveal_ui != null and _commissioning_reveal_ui.visible)
		or (_campus_portfolio_reveal_ui != null and _campus_portfolio_reveal_ui.visible)
	)


func _held_confirmation_open() -> bool:
	if get_tree() == null:
		return false
	for node: Node in get_tree().get_nodes_in_group(&"held_confirmation_dialogs"):
		var dialog := node as ConfirmationDialog
		if dialog != null and is_ancestor_of(dialog) and dialog.visible:
			return true
	return false


## A held confirmation deliberately makes its non-destructive return the global
## action. The irreversible filing remains visible beside it, but a remote or
## assistive "activate next" request may never confirm a permanent choice.
func _active_held_confirmation_primary_action_state() -> Dictionary:
	if get_tree() == null:
		return {}
	for node: Node in get_tree().get_nodes_in_group(&"held_confirmation_dialogs"):
		var dialog := node as ConfirmationDialog
		if dialog == null or not is_ancestor_of(dialog) or not dialog.visible:
			continue
		var safe_return := dialog.get_cancel_button()
		if safe_return == null or not safe_return.is_visible_in_tree():
			return {}
		var copy := safe_return.text.strip_edges()
		return {
			"copy": copy,
			"visible_label": copy,
			"action_id": "held_confirmation_safe_return",
			"actionable": not safe_return.disabled,
			"semantic_icon": String(safe_return.get_meta(
				"semantic_icon",
				"safe_return_arrow",
			)),
			"icon_visible": safe_return.icon != null,
			"accessible_text": (
				"Safe return: %s. No change occurs; the permanent filing remains unconfirmed."
				% copy
			),
		}
	return {}


func _focus_active_held_confirmation_safe_return() -> bool:
	if get_tree() == null:
		return false
	for node: Node in get_tree().get_nodes_in_group(&"held_confirmation_dialogs"):
		var dialog := node as ConfirmationDialog
		if dialog == null or not is_ancestor_of(dialog) or not dialog.visible:
			continue
		var safe_return := dialog.get_cancel_button()
		if (
			safe_return == null
			or safe_return.disabled
			or not safe_return.is_visible_in_tree()
		):
			return false
		safe_return.grab_focus()
		_pulse_action_target(safe_return)
		return true
	return false


func _sync_held_confirmation_presentation() -> void:
	if _held_confirmation_scrim == null:
		return
	if _held_confirmation_scrim.visible == _held_confirmation_open():
		return
	_on_interaction_safety_presentation_changed()


func _routing_confirmation_open() -> bool:
	return (
		_routing_ui != null
		and _routing_ui.has_method("has_held_confirmation")
		and bool(_routing_ui.call("has_held_confirmation"))
	)


func _refresh_floor_input_context(snapshot: Dictionary = {}) -> void:
	var nonconfirmation_surface_blocked := (
		_flockwatch_open or _nonconfirmation_management_surface_open()
	)
	var routing_confirmation_open := _routing_confirmation_open()
	var surface_blocked := (
		nonconfirmation_surface_blocked or _held_confirmation_open()
	)
	if _character_dialogue_ui != null:
		_character_dialogue_ui.set_suspended(surface_blocked)
	var dialogue_blocked: bool = (
		_character_dialogue_ui != null
		and _character_dialogue_ui.is_blocking()
	)
	var blocked: bool = surface_blocked or dialogue_blocked
	if _camera_controller != null:
		_camera_controller.set_process_input(not blocked)
		_camera_controller.set_process_unhandled_input(not blocked)
		if blocked:
			_camera_controller.call("_clear_navigation_inputs")
			_camera_controller.clear_context_hover()
	if _routing_ui != null:
		_routing_ui.set_interaction_enabled(
			not dialogue_blocked
			and not nonconfirmation_surface_blocked
			and (not surface_blocked or routing_confirmation_open)
			and _simulation != null
			and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		)
	# Surface visibility can change after the clock signal has already fired. Keep
	# the global clock's pause owner and next action synchronized with the surface
	# that currently owns input.
	_refresh_speed_button_copy(snapshot)


func _apply_live_hud_presentation(compact: bool) -> void:
	if _compact_live_hud_applied == compact:
		return
	_compact_live_hud_applied = compact
	if _top_hud_panel != null:
		_top_hud_panel.offset_bottom = (
			FIRST_CLUTCH_HUD_HEIGHT if compact else LIVE_HUD_HEIGHT
		)
	if _shift_objective_row != null:
		_shift_objective_row.visible = not compact
	if _opening_header_goal != null:
		_opening_header_goal.visible = compact and _opening_egg_slots.visible
		_live_title_label.visible = not _opening_header_goal.visible
	var routing_top := FIRST_CLUTCH_ROUTING_TOP if compact else LIVE_ROUTING_TOP
	if _routing_ui != null:
		_routing_ui.set_top_inset(routing_top)
	if _flockwatch_panel != null:
		_flockwatch_panel.offset_top = routing_top + 52.0
	if _camera_controller != null and _intent_focus_worker_id >= 0:
		_camera_controller.set_safe_viewport_insets(
			0.0,
			FLOCKWATCH_DRAWER_SAFE_RIGHT if _flockwatch_open else 0.0,
			maxf(104.0, _live_hud_routing_top() + 8.0),
			300.0 if compact else 250.0,
		)
	_refresh_flockwatch_toggle_layout()
	_apply_physical_hud_layout()


func _measure_live_hud_canvas() -> void:
	if _top_hud_panel == null:
		return
	# Canvas-items stretch can letterbox the physical window. UI geometry uses
	# the logical visible rect, not the root viewport's render-target pixels.
	var viewport_size := get_viewport().get_visible_rect().size
	var physical_size := Vector2(DisplayServer.window_get_size())
	if DisplayServer.get_name() == "headless":
		physical_size = viewport_size
	if OS.has_feature("web"):
		var css_size: Variant = JavaScriptBridge.eval("(() => { const c = document.querySelector('canvas'); if (!c) return ''; const r = c.getBoundingClientRect(); return JSON.stringify([r.width, r.height]); })()", true)
		if css_size is String and not css_size.is_empty():
			var dimensions: Variant = JSON.parse_string(css_size)
			if dimensions is Array and dimensions.size() == 2:
				physical_size = Vector2(float(dimensions[0]), float(dimensions[1]))
	var ratio := minf(physical_size.x / maxf(1.0, viewport_size.x), physical_size.y / maxf(1.0, viewport_size.y))
	var is_compact := physical_size.x < 1100.0 or ratio < 0.82
	var layout_key := "%d|%d|%d|%d|%.2f|%s" % [roundi(physical_size.x), roundi(physical_size.y), roundi(viewport_size.x), roundi(viewport_size.y), float(_player_preferences.get("ui_scale", 1.0)), str(_compact_live_hud_applied)]
	if layout_key == _hud_layout_key:
		return
	_hud_layout_key = layout_key
	_hud_canvas_ratio = clampf(ratio, 0.4, 2.0)
	_compact_physical_hud = is_compact
	_apply_physical_hud_layout()


func _live_hud_routing_top() -> float:
	return _top_hud_panel.offset_bottom + 8.0 if _compact_physical_hud and _top_hud_panel != null else (FIRST_CLUTCH_ROUTING_TOP if _compact_live_hud_applied else LIVE_ROUTING_TOP)


func _apply_physical_hud_layout() -> void:
	if _top_hud_panel == null or _shift_objective_row == null:
		return
	var compact := _compact_physical_hud
	var first_clutch := _compact_live_hud_applied
	var interface_scale := float(_player_preferences.get("ui_scale", 1.0))
	var readable_scale := interface_scale / _hud_canvas_ratio if compact else interface_scale
	var target_height := ceilf(44.0 / _hud_canvas_ratio) if compact else 32.0
	if _hud_controls_row != null and _hud_top_bar != null:
		_hud_controls_row.visible = compact
		var controls_parent := _hud_controls_row if compact else _hud_top_bar
		if _speed_control.get_parent() != controls_parent:
			_settings_button.reparent(controls_parent, false)
			_speed_control.reparent(controls_parent, false)
			if compact:
				controls_parent.move_child(_speed_control, 0)
		_speed_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	_top_hud_panel.offset_bottom = (
		((84.0 if first_clutch else 128.0) + 36.0 * (interface_scale - 1.0)) / _hud_canvas_ratio if compact else
		(FIRST_CLUTCH_HUD_HEIGHT if first_clutch else LIVE_HUD_HEIGHT)
	)
	_shift_objective_row.visible = not first_clutch
	if _opening_header_goal != null:
		_opening_header_goal.visible = first_clutch and _opening_egg_slots.visible
	if _live_title_label != null:
		_live_title_label.visible = not compact and not (first_clutch and _opening_egg_slots.visible)
	for control: Control in [
		_day_label, _time_label, _revenue_label, _quota_progress_label,
		_quality_streak_label, _guidance_label, _opening_header_label, _active_playbook_button,
	]:
		if control == null:
			continue
		if not control.has_meta("hud_base_font"):
			control.set_meta("hud_base_font", control.get_meta("preference_base_font_size", control.get_theme_font_size("font_size")))
		var base_font := int(control.get_meta("hud_base_font"))
		control.add_theme_font_size_override(
			"font_size",
			roundi((maxi(16, base_font) if compact else base_font) * readable_scale),
		)
	if _settings_button != null:
		_settings_button.text = "" if compact else String(_settings_button.get_meta("compact_text", "SETTINGS  [F10]"))
		_settings_button.custom_minimum_size = Vector2(target_height if compact else 148.0, target_height)
	for index in range(1, _speed_buttons.size()):
		_speed_buttons[index].visible = not compact
	if not _speed_buttons.is_empty():
		_speed_buttons[0].custom_minimum_size = Vector2(90.0 / _hud_canvas_ratio if compact else 50.0, target_height)
	if _compact_speed_menu != null:
		_compact_speed_menu.visible = compact
		_compact_speed_menu.custom_minimum_size = Vector2(100.0 / _hud_canvas_ratio, target_height)
	if _next_moment_button != null:
		_next_moment_button.custom_minimum_size = Vector2(130.0 / _hud_canvas_ratio if compact else 130.0, target_height)
	for button: Button in [_speed_buttons[0], _compact_speed_menu, _next_moment_button]:
		button.add_theme_font_size_override("font_size", roundi(14.0 * readable_scale))
	for secondary: Control in [
		_clutch_carton_host, _directive_badge_host,
		_core_loop_host, _reward_loop_host, _rival_pulse_label,
		_consequence_icon_host, _guidance_action_chevron,
	]:
		if secondary == null:
			continue
		if compact:
			if not secondary.has_meta("hud_precompact_visible"):
				secondary.set_meta("hud_precompact_visible", secondary.visible)
			secondary.visible = false
		elif secondary.has_meta("hud_precompact_visible"):
			secondary.visible = bool(secondary.get_meta("hud_precompact_visible"))
			secondary.remove_meta("hud_precompact_visible")
	if _quota_progress != null:
		_quota_progress.custom_minimum_size.x = 158.0 if compact else 190.0
		_quota_progress.visible = not compact
	if _active_playbook_button != null:
		_active_playbook_button.custom_minimum_size.y = target_height
	if _guidance_action_button != null:
		_guidance_action_button.custom_minimum_size.y = target_height if compact else 30.0
	var routing_top := _live_hud_routing_top()
	if _routing_ui != null:
		_routing_ui.set_top_inset(routing_top)
	if _flockwatch_panel != null:
		_flockwatch_panel.offset_top = routing_top + 52.0
	_refresh_flockwatch_toggle_layout()
	_apply_physical_review_layout()


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "ManagementInterface"
	add_child(ui)
	_ui_root = Control.new()
	_ui_root.name = "ManagementUIRoot"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# This full-viewport host is only a layout parent. Interactive descendants
	# keep their own STOP/PASS filters, while uncovered office pixels must reach
	# the management camera for selection, wheel zoom, and middle-drag panning.
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_root.theme = ManagementUIThemeScript.create_theme()
	ui.add_child(_ui_root)

	_top_hud_panel = PanelContainer.new()
	_top_hud_panel.name = "LiveShiftHUD"
	_top_hud_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_hud_panel.offset_bottom = LIVE_HUD_HEIGHT
	_top_hud_panel.add_theme_stylebox_override("panel", _panel_style(Color("1c2633"), 0.94, 0, 0))
	_ui_root.add_child(_top_hud_panel)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 18)
	top_margin.add_theme_constant_override("margin_right", 18)
	top_margin.add_theme_constant_override("margin_top", 6)
	top_margin.add_theme_constant_override("margin_bottom", 6)
	_top_hud_panel.add_child(top_margin)
	var top_stack := VBoxContainer.new()
	top_stack.add_theme_constant_override("separation", 4)
	top_margin.add_child(top_stack)
	var top_bar := HBoxContainer.new()
	_hud_top_bar = top_bar
	top_bar.add_theme_constant_override("separation", 12)
	top_stack.add_child(top_bar)
	var title := _make_label("PECKING ORDER", 18, Color("f4d27b"))
	title.tooltip_text = "Egg Yield Bureau management floor"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	_live_title_label = title
	_opening_header_goal = HBoxContainer.new()
	_opening_header_goal.name = "OpeningHeaderGoal"
	_opening_header_goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opening_header_goal.add_theme_constant_override("separation", 8)
	_opening_header_goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_opening_header_goal.visible = false
	top_bar.add_child(_opening_header_goal)
	_opening_header_label = _make_label("FIRST 3 EGGS", 15, Color("f4d27b"))
	_opening_header_goal.add_child(_opening_header_label)
	_opening_header_slots = OpeningEggSlotsScript.new()
	_opening_header_slots.custom_minimum_size = Vector2(78, 24)
	_opening_header_slots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_opening_header_goal.add_child(_opening_header_slots)
	_day_label = _make_label("DAY 1", 16)
	_time_label = _make_label("8:00 AM", 16)
	_revenue_label = _make_label("FEED FUND $50.00", 16, Color("9dd9a4"))
	_shift_clock_status_host = HBoxContainer.new()
	_shift_clock_status_host.name = "ShiftClockStatus"
	_shift_clock_status_host.add_theme_constant_override("separation", 12)
	top_bar.add_child(_shift_clock_status_host)
	_shift_clock_status_icon = FlockwatchIconBadgeScript.new()
	_shift_clock_status_icon.name = "ShiftClockStatusIcon"
	_shift_clock_status_icon.set_badge_size(18.0)
	_shift_clock_status_icon.configure(&"clock", Color("b8c3cc"))
	_shift_clock_status_icon.visible = false
	_shift_clock_status_icon.set_meta("semantic_icon", "clock")
	_shift_clock_status_host.add_child(_shift_clock_status_icon)
	_shift_clock_status_host.add_child(_day_label)
	_shift_clock_status_host.add_child(_time_label)
	_fund_status_host = HBoxContainer.new()
	_fund_status_host.name = "FundStatus"
	_fund_status_host.add_theme_constant_override("separation", 5)
	top_bar.add_child(_fund_status_host)
	_fund_status_icon = FlockwatchIconBadgeScript.new()
	_fund_status_icon.name = "FundStatusIcon"
	_fund_status_icon.set_badge_size(18.0)
	_fund_status_icon.configure(&"cash", Color("9dd9a4"))
	_fund_status_icon.visible = false
	_fund_status_icon.set_meta("semantic_icon", "cash")
	_fund_status_host.add_child(_fund_status_icon)
	_fund_status_host.add_child(_revenue_label)
	_update_shift_status_copy(1, "8:00 AM", 5000)
	_settings_button = Button.new()
	_settings_button.name = "OpenSettingsButton"
	_settings_button.text = "SETTINGS  [F10]"
	_settings_button.custom_minimum_size = Vector2(148.0, 32.0)
	_settings_button.icon = ManagementUIThemeScript.action_icon(&"settings")
	_settings_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_settings_button.add_theme_constant_override("icon_separation", 3)
	_settings_button.set_meta("semantic_icon", "settings_cog")
	_settings_button.tooltip_text = "Audio, display comfort, accessibility, and remappable controls."
	_settings_button.focus_mode = Control.FOCUS_ALL
	_settings_button.pressed.connect(_on_settings_requested)
	top_bar.add_child(_settings_button)
	_update_settings_button_prompt()

	_speed_control = HBoxContainer.new()
	_speed_control.name = "SimulationSpeedControl"
	_speed_control.add_theme_constant_override("separation", 2)
	top_bar.add_child(_speed_control)
	for index in 4:
		var button := Button.new()
		button.text = ["PAUSE", "1×", "3×", "10×"][index]
		button.name = "SpeedButton_%d" % index
		button.theme_type_variation = &"SpeedButton"
		button.custom_minimum_size = Vector2(50.0, 32.0)
		button.tooltip_text = ["Pause simulation", "Normal speed", "Fast speed", "Ultra speed"][index]
		if index == 0:
			button.pressed.connect(_on_pause_requested)
		else:
			button.pressed.connect(_on_speed_button_pressed.bind(index))
		_speed_control.add_child(button)
		_speed_buttons.append(button)
	_compact_speed_menu = MenuButton.new()
	_compact_speed_menu.name = "CompactSpeedMenu"
	_compact_speed_menu.text = "PACE"
	_compact_speed_menu.custom_minimum_size = Vector2(78.0, 44.0)
	_compact_speed_menu.tooltip_text = "Choose normal, fast, or ultra speed."
	_compact_speed_menu.accessibility_name = _compact_speed_menu.tooltip_text
	_compact_speed_menu.visible = false
	for speed_index in range(1, 4):
		_compact_speed_menu.get_popup().add_item(["1× NORMAL", "3× FAST", "10× ULTRA"][speed_index - 1], speed_index)
	_compact_speed_menu.get_popup().id_pressed.connect(_on_compact_speed_selected)
	_speed_control.add_child(_compact_speed_menu)
	_next_moment_button = Button.new()
	_next_moment_button.name = "NextMomentButton"
	_next_moment_button.text = "NEXT  [4]"
	_next_moment_button.theme_type_variation = &"SpeedButton"
	_next_moment_button.custom_minimum_size = Vector2(130.0, 32.0)
	_next_moment_button.tooltip_text = "Advance safely at 10× until the next decision, shift review, or open Priority Peck window."
	_next_moment_button.accessibility_name = "%s Binding: %s." % [
		_next_moment_button.tooltip_text,
		_action_hint(NEXT_MOMENT_ACTION),
	]
	_next_moment_button.pressed.connect(_on_next_moment_pressed)
	_speed_control.add_child(_next_moment_button)
	_hud_controls_row = HBoxContainer.new()
	_hud_controls_row.name = "CompactClockControls"
	_hud_controls_row.add_theme_constant_override("separation", 12)
	_hud_controls_row.visible = false
	top_stack.add_child(_hud_controls_row)

	_shift_objective_row = HBoxContainer.new()
	_shift_objective_row.name = "ShiftObjectiveRow"
	_shift_objective_row.add_theme_constant_override("separation", 10)
	top_stack.add_child(_shift_objective_row)
	_shift_goal_status_host = HBoxContainer.new()
	_shift_goal_status_host.name = "ShiftEggGoalStatus"
	_shift_goal_status_host.add_theme_constant_override("separation", 0)
	_shift_goal_status_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shift_goal_status_host.set_meta("semantic_icon", "egg")
	_shift_goal_status_host.set_meta("shape_language", "egg=shift quota")
	_shift_objective_row.add_child(_shift_goal_status_host)
	_shift_goal_status_icon = FlockwatchIconBadgeScript.new()
	_shift_goal_status_icon.name = "ShiftEggGoalIcon"
	_shift_goal_status_icon.set_badge_size(22.0)
	_shift_goal_status_icon.configure(&"egg", Color("d9c47d"))
	_shift_goal_status_icon.set_meta("semantic_icon", "egg")
	_shift_goal_status_host.add_child(_shift_goal_status_icon)
	# Retain the named label node for compatibility and assistive semantics, but
	# let the stable egg silhouette and exact count carry the visible category.
	_shift_egg_goal_label = _make_label("", 13, Color("d9c47d"))
	_shift_egg_goal_label.name = "ShiftEggGoalLabel"
	_shift_egg_goal_label.visible = false
	_shift_egg_goal_label.tooltip_text = "Eggs laid toward this shift's goal."
	_shift_egg_goal_label.accessibility_name = "Egg goal for this shift"
	_shift_goal_status_host.add_child(_shift_egg_goal_label)
	_quota_progress = ProgressBar.new()
	_quota_progress.name = "ShiftQuotaProgress"
	_quota_progress.custom_minimum_size = Vector2(190.0, 22.0)
	_quota_progress.show_percentage = false
	_shift_objective_row.add_child(_quota_progress)
	_opening_egg_slots = OpeningEggSlotsScript.new()
	_opening_egg_slots.name = "OpeningEggSlots"
	_quota_progress.add_child(_opening_egg_slots)
	_opening_egg_slots.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_opening_egg_slots.visible = false
	_quota_progress_label = _make_label("QUOTA  ·  0 / 24", 14, Color("f3ead1"))
	_quota_progress_label.name = "ShiftQuotaReadout"
	_quota_progress_label.custom_minimum_size.x = 128.0
	_shift_objective_row.add_child(_quota_progress_label)
	_quality_streak_label = _make_label("CLEAN CLUTCH  ×0", 14, Color("9ccfc2"))
	_quality_streak_label.name = "CleanClutchCount"
	_quality_streak_label.custom_minimum_size.x = 30.0
	_shift_objective_row.add_child(_quality_streak_label)
	_clutch_carton_host = HBoxContainer.new()
	_clutch_carton_host.name = "ClutchCartonPulse"
	_clutch_carton_host.custom_minimum_size.x = 55.0
	_clutch_carton_host.add_theme_constant_override("separation", 1)
	_clutch_carton_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clutch_carton_host.tooltip_text = "Clean-clutch reward track: 2 / 4 / 8."
	_shift_objective_row.add_child(_clutch_carton_host)
	for threshold in [2, 4, 8]:
		var clutch_icon := FlockwatchIconBadgeScript.new()
		clutch_icon.name = "ClutchReward_%d" % threshold
		clutch_icon.set_badge_size(16.0)
		clutch_icon.configure(&"egg", Color("53636c"))
		clutch_icon.set_meta("threshold", threshold)
		clutch_icon.set_meta("semantic_icon", "egg")
		_clutch_carton_host.add_child(clutch_icon)
		_clutch_carton_icons.append(clutch_icon)
	_directive_badge_host = HBoxContainer.new()
	_directive_badge_host.name = "LivePolicyBadge"
	_directive_badge_host.custom_minimum_size.x = 138.0
	_directive_badge_host.add_theme_constant_override("separation", 3)
	_directive_badge_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shift_objective_row.add_child(_directive_badge_host)
	_directive_badge_icon = FlockwatchIconBadgeScript.new()
	_directive_badge_icon.name = "LivePolicyIcon"
	_directive_badge_icon.set_badge_size(18.0)
	_directive_badge_icon.configure(&"goal", Color("efb96d"))
	_directive_badge_icon.visible = true
	_directive_badge_icon.set_meta("semantic_icon", "goal")
	_directive_badge_host.add_child(_directive_badge_icon)
	_directive_badge = _make_label("POLICY  ·  UNSET", 13, Color("efb96d"))
	_directive_badge.name = "LivePolicyLabel"
	_directive_badge.custom_minimum_size.x = 0.0
	_directive_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_directive_badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_directive_badge.set_meta("full_text", "POLICY  ·  UNSET")
	_directive_badge.set_meta("compact_text", "BRIEFING")
	_directive_badge_host.add_child(_directive_badge)
	_core_loop_host = HBoxContainer.new()
	_core_loop_host.name = "CoreLoopPulse"
	_core_loop_host.custom_minimum_size.x = 86.0
	_core_loop_host.add_theme_constant_override("separation", 3)
	_core_loop_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_core_loop_host.tooltip_text = "PLAN → WORK → RESPOND → REWARD"
	_core_loop_host.set_meta("shape_language", "goal=plan; route=work; shield=respond; egg=reward")
	_shift_objective_row.add_child(_core_loop_host)
	for definition in GameplayPulseDirectorScript.SHIFT_JOURNEY_STEPS:
		var loop_icon := FlockwatchIconBadgeScript.new()
		loop_icon.name = "CoreLoop_%s" % String(definition.get("id", "step")).capitalize()
		loop_icon.set_badge_size(16.0)
		loop_icon.configure(
			StringName(definition.get("icon", &"goal")),
			Color("667780"),
		)
		loop_icon.set_meta("loop_step_id", String(definition.get("id", "")))
		loop_icon.set_meta("semantic_icon", String(definition.get("icon", "goal")))
		_core_loop_host.add_child(loop_icon)
		_core_loop_icons.append(loop_icon)
	_reward_loop_host = HBoxContainer.new()
	_reward_loop_host.name = "RewardLoopPulse"
	_reward_loop_host.custom_minimum_size.x = 76.0
	_reward_loop_host.add_theme_constant_override("separation", 3)
	_reward_loop_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reward_loop_host.tooltip_text = "Signature · optional contract · named combo · next reward"
	_reward_loop_host.set_meta("authoritative", false)
	_shift_objective_row.add_child(_reward_loop_host)
	for definition in GameplayPulseDirectorScript.REWARD_LOOP_ICONS:
		var reward_icon := FlockwatchIconBadgeScript.new()
		var reward_id := StringName(definition.get("id", &"reward"))
		reward_icon.name = "RewardLoop_%s" % String(reward_id).to_pascal_case()
		reward_icon.set_badge_size(16.0)
		reward_icon.configure(StringName(definition.get("icon", &"goal")), Color("53636c"))
		reward_icon.set_meta("reward_loop_id", String(reward_id))
		reward_icon.set_meta("semantic_icon", String(definition.get("icon", "goal")))
		_reward_loop_host.add_child(reward_icon)
		_reward_loop_icons[reward_id] = reward_icon
	_active_playbook_button = MenuButton.new()
	_active_playbook_button.name = "ActivePlaybookButton"
	_active_playbook_button.text = "PLAN"
	_active_playbook_button.icon = ManagementUIThemeScript.action_icon(&"ledger")
	_active_playbook_button.theme_type_variation = &"SpeedButton"
	_active_playbook_button.custom_minimum_size = Vector2(86.0, 30.0)
	_active_playbook_button.focus_mode = Control.FOCUS_ALL
	_active_playbook_button.tooltip_text = "Open the active shift playbook. Every choice shows gain, cost, and risk before filing."
	_active_playbook_button.accessibility_name = _active_playbook_button.tooltip_text
	_active_playbook_button.about_to_popup.connect(_on_active_playbook_about_to_popup)
	_active_playbook_button.get_popup().id_pressed.connect(_on_active_playbook_item_pressed)
	_active_playbook_button.get_popup().popup_hide.connect(_on_active_playbook_popup_hide)
	_shift_objective_row.add_child(_active_playbook_button)
	_rival_pulse_label = _make_label("RIVAL ±0", 12, Color("b8c3cc"))
	_rival_pulse_label.name = "RivalPulseLabel"
	_rival_pulse_label.custom_minimum_size.x = 82.0
	_rival_pulse_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_rival_pulse_label.visible = false
	_shift_objective_row.add_child(_rival_pulse_label)
	_guidance_action_button = Button.new()
	_guidance_action_button.name = "GuidanceActionButton"
	_guidance_action_button.flat = true
	_guidance_action_button.focus_mode = Control.FOCUS_ALL
	_guidance_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guidance_action_button.custom_minimum_size.y = 30.0
	_guidance_action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_guidance_action_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_guidance_action_button.add_theme_stylebox_override(
		"hover",
		_panel_style(Color("263944"), 0.78, 7, 1),
	)
	_guidance_action_button.add_theme_stylebox_override(
		"pressed",
		_panel_style(Color("314650"), 0.92, 7, 1),
	)
	_guidance_action_button.add_theme_stylebox_override(
		"focus",
		_panel_style(Color("24343e"), 0.78, 7, 2),
	)
	_guidance_action_button.pressed.connect(_on_guidance_action_pressed)
	_guidance_action_button.mouse_entered.connect(_on_guidance_preview_entered)
	_guidance_action_button.mouse_exited.connect(_on_guidance_preview_exited)
	_guidance_action_button.focus_entered.connect(_on_guidance_preview_entered)
	_guidance_action_button.focus_exited.connect(_on_guidance_preview_exited)
	_shift_objective_row.add_child(_guidance_action_button)
	var guidance_content := HBoxContainer.new()
	guidance_content.name = "GuidanceActionContent"
	guidance_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guidance_content.offset_left = 5.0
	guidance_content.offset_right = -5.0
	guidance_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_content.add_theme_constant_override("separation", 8)
	_guidance_action_button.add_child(guidance_content)
	_guidance_icon = FlockwatchIconBadgeScript.new()
	_guidance_icon.name = "GuidanceIcon"
	_guidance_icon.configure(&"clipboard", Color("d9c47d"))
	guidance_content.add_child(_guidance_icon)
	_guidance_label = _make_label("NEXT: START AT 1×", 13, Color("b8c3cc"))
	# Let the existing button own the available width, so changing instructions
	# cannot displace the quota or nearby controls.
	_guidance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guidance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_guidance_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_guidance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_content.add_child(_guidance_label)
	_consequence_icon_host = HBoxContainer.new()
	_consequence_icon_host.name = "ConsequenceIconStrip"
	_consequence_icon_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_consequence_icon_host.add_theme_constant_override("separation", 1)
	for definition in [
		{"name": "BenefitIcon", "icon": &"egg", "accent": Color("9ccfc2")},
		{"name": "CostIcon", "icon": &"cash", "accent": Color("d9c47d")},
		{"name": "RiskIcon", "icon": &"shield", "accent": Color("efaa84")},
	]:
		var consequence_icon := FlockwatchIconBadgeScript.new()
		consequence_icon.name = String(definition.get("name", "ConsequenceIcon"))
		consequence_icon.set_badge_size(20.0)
		consequence_icon.configure(
			StringName(definition.get("icon", &"goal")),
			definition.get("accent", Color("dce7e8")) as Color,
		)
		_consequence_icon_host.add_child(consequence_icon)
		_consequence_icons.append(consequence_icon)
	guidance_content.add_child(_consequence_icon_host)
	_guidance_action_chevron = _make_label("›", 19, Color("d9c47d"))
	_guidance_action_chevron.name = "GuidanceActionChevron"
	_guidance_action_chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_guidance_action_chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guidance_content.add_child(_guidance_action_chevron)

	_flockwatch_toggle = Button.new()
	_flockwatch_toggle.name = "FlockwatchToggle"
	_flockwatch_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_flockwatch_toggle.offset_left = -250.0
	_flockwatch_toggle.offset_top = 120.0
	_flockwatch_toggle.offset_right = -18.0
	_flockwatch_toggle.offset_bottom = 164.0
	_flockwatch_toggle.z_index = 5
	_flockwatch_toggle.text = "FLOCKWATCH  [V]"
	_flockwatch_toggle.icon = ManagementUIThemeScript.action_icon(&"ledger")
	_flockwatch_toggle.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_flockwatch_toggle.add_theme_constant_override("icon_separation", 3)
	_flockwatch_toggle.set_meta("semantic_icon", "flockwatch_ledger")
	_flockwatch_toggle.tooltip_text = "Open the rooster's performance ledger."
	_flockwatch_toggle.pressed.connect(_on_flockwatch_pressed)
	_ui_root.add_child(_flockwatch_toggle)

	_flockwatch_panel = PanelContainer.new()
	_flockwatch_panel.name = "FlockwatchLedger"
	_flockwatch_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_flockwatch_panel.offset_left = -438.0
	_flockwatch_panel.offset_top = 172.0
	_flockwatch_panel.offset_right = -18.0
	_flockwatch_panel.offset_bottom = -18.0
	_flockwatch_panel.add_theme_stylebox_override("panel", _panel_style(Color("202936"), 0.96, 12, 1))
	_ui_root.add_child(_flockwatch_panel)
	var side_margin := MarginContainer.new()
	side_margin.add_theme_constant_override("margin_left", 16)
	side_margin.add_theme_constant_override("margin_right", 16)
	side_margin.add_theme_constant_override("margin_top", 14)
	side_margin.add_theme_constant_override("margin_bottom", 14)
	_flockwatch_panel.add_child(side_margin)
	var side_scroll := ScrollContainer.new()
	side_scroll.name = "FlockwatchScroll"
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	side_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_margin.add_child(side_scroll)
	var side := VBoxContainer.new()
	side.name = "FlockwatchLegacyContent"
	side.add_theme_constant_override("separation", 8)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.add_child(side)
	var today_section := _make_flockwatch_section("FlockwatchTodaySection")
	var flock_section := _make_flockwatch_section("FlockwatchFlockSection")
	var ties_button := Button.new()
	ties_button.text = "FLOCK TIES [B] · FRIENDSHIPS & RIVALRIES"
	ties_button.custom_minimum_size.y = 48
	ties_button.pressed.connect(_open_flock_ties)
	flock_section.add_child(ties_button)
	var operations_section := _make_flockwatch_section("FlockwatchOperationsSection")
	var economic_briefing_section := _make_flockwatch_section(
		"FlockwatchEconomicBriefingSection"
	)
	var capital_section := _make_flockwatch_section("FlockwatchCapitalSection")
	var records_section := _make_flockwatch_section("FlockwatchRecordsSection")
	for section: VBoxContainer in [
		today_section,
		flock_section,
		operations_section,
		economic_briefing_section,
		capital_section,
		records_section,
	]:
		side.add_child(section)
	_campaign_orders_heading_label = _make_label("TODAY'S GOALS", 17, Color("73b5a7"))
	_campaign_orders_heading_label.name = "CampaignOrdersHeading"
	today_section.add_child(_campaign_orders_heading_label)
	_campaign_orders_glance_grid = _make_flockwatch_glance_grid(
		"CampaignOrdersGlanceGrid",
		3,
	)
	today_section.add_child(_campaign_orders_glance_grid)
	for glance_index in range(3):
		var order_glance := _add_flockwatch_glance_tile(
			_campaign_orders_glance_grid,
			"CampaignOrderGlance%d" % (glance_index + 1),
			"ORDER\nAWAITING FILE",
			&"goal",
		)
		order_glance.focus_mode = Control.FOCUS_ALL
		order_glance.focus_entered.connect(
			_on_campaign_order_glance_focus_changed.bind(order_glance, true)
		)
		order_glance.focus_exited.connect(
			_on_campaign_order_glance_focus_changed.bind(order_glance, false)
		)
		order_glance.gui_input.connect(
			_on_campaign_order_glance_gui_input.bind(order_glance)
		)
		_campaign_order_glances.append(order_glance)
	_campaign_order_driver_button = Button.new()
	_campaign_order_driver_button.name = "CampaignOrderDriverAction"
	_campaign_order_driver_button.flat = true
	_campaign_order_driver_button.visible = false
	_campaign_order_driver_button.focus_mode = Control.FOCUS_ALL
	_campaign_order_driver_button.custom_minimum_size.y = 30.0
	_campaign_order_driver_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_campaign_order_driver_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_campaign_order_driver_button.pressed.connect(_on_campaign_order_driver_pressed)
	today_section.add_child(_campaign_order_driver_button)
	var order_driver_content := HBoxContainer.new()
	order_driver_content.name = "CampaignOrderDriverContent"
	order_driver_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	order_driver_content.offset_left = 7.0
	order_driver_content.offset_right = -7.0
	order_driver_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_driver_content.add_theme_constant_override("separation", 7)
	_campaign_order_driver_button.add_child(order_driver_content)
	_campaign_order_driver_icon = FlockwatchIconBadgeScript.new()
	_campaign_order_driver_icon.name = "CampaignOrderDriverIcon"
	_campaign_order_driver_icon.set_badge_size(20.0)
	order_driver_content.add_child(_campaign_order_driver_icon)
	_campaign_order_driver_label = _make_label("SHOW DRIVER", 11, Color("dce7e8"))
	_campaign_order_driver_label.name = "CampaignOrderDriverLabel"
	_campaign_order_driver_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_order_driver_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_campaign_order_driver_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_campaign_order_driver_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_driver_content.add_child(_campaign_order_driver_label)
	var order_driver_chevron := _make_label("›", 18, Color("d9c47d"))
	order_driver_chevron.name = "CampaignOrderDriverChevron"
	order_driver_chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	order_driver_chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	order_driver_content.add_child(order_driver_chevron)
	_campaign_objectives_label = _make_label("Day 1 orders are being stamped.", 13, Color("d7e5df"))
	_campaign_objectives_label.name = "CampaignObjectivesLabel"
	_campaign_objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campaign_objectives_label.visible = false
	today_section.add_child(_campaign_objectives_label)
	_campaign_doctrine_label = _make_label("", 12, Color("9fd3c5"))
	_campaign_doctrine_label.name = "CampaignActiveDoctrine"
	_campaign_doctrine_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_campaign_doctrine_label.clip_text = true
	_campaign_doctrine_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_campaign_doctrine_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_campaign_doctrine_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_campaign_doctrine_label.visible = false
	today_section.add_child(_campaign_doctrine_label)
	_campaign_safeguards_label = _make_label(
		"PROBATION SAFEGUARDS  //  AWAITING FILE",
		12,
		Color("d9c58a"),
	)
	_campaign_safeguards_label.name = "CampaignSafeguardForecast"
	_campaign_safeguards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_campaign_safeguards_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_campaign_safeguards_label.visible = false
	today_section.add_child(_campaign_safeguards_label)
	var safeguard_glance_grid := _make_flockwatch_glance_grid(
		"CampaignSafeguardGlanceGrid",
		1,
	)
	today_section.add_child(safeguard_glance_grid)
	_campaign_safeguard_glance = _add_flockwatch_glance_tile(
		safeguard_glance_grid,
		"CampaignSafeguardGlance",
		"SAFEGUARD\nAWAITING FILE",
		&"shield",
	)
	_flock_labor_label = _make_label("FLOCK VOICE  ·  No binding compact is currently filed.", 13, Color("b9c8cc"))
	_flock_labor_label.name = "FlockLaborStatus"
	_flock_labor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flock_labor_label.tooltip_text = "Named petitions can become next-shift compacts or trigger work-to-rule."
	_flock_labor_label.visible = false
	today_section.add_child(_flock_labor_label)
	_flock_labor_glance_grid = _make_flockwatch_glance_grid(
		"FlockLaborGlanceGrid",
		2,
	)
	today_section.add_child(_flock_labor_glance_grid)
	_flock_compact_glance = _add_flockwatch_glance_tile(
		_flock_labor_glance_grid,
		"FlockCompactGlance",
		"COMPACT\nNONE FILED",
		&"compact",
	)
	_work_to_rule_glance = _add_flockwatch_glance_tile(
		_flock_labor_glance_grid,
		"WorkToRuleGlance",
		"WORK-RULE\nINACTIVE",
		&"pause",
	)
	_flock_labor_glance_grid.visible = false
	today_section.add_child(HSeparator.new())
	_pecking_order_ui = PeckingOrderUIScript.new()
	_pecking_order_ui.worker_selected.connect(_on_pecking_order_worker_selected)
	flock_section.add_child(_pecking_order_ui)
	flock_section.add_child(HSeparator.new())
	if not _defer_management_ui:
		_build_staffing_surface(flock_section)
	_economic_briefing_ui = EconomicBriefingUIScript.new()
	_economic_briefing_ui.economic_watch_requested.connect(
		_on_economic_watch_requested
	)
	_economic_briefing_ui.economic_watch_open_requested.connect(
		_on_economic_watch_open_requested
	)
	_economic_briefing_ui.presentation_context_changed.connect(
		_on_campaign_interface_context_changed
	)
	economic_briefing_section.add_child(_economic_briefing_ui)
	_upgrade_disclosure_toggle = FlockwatchDisclosureToggleScript.new()
	_upgrade_disclosure_toggle.name = "DeskRequisitionsToggle"
	_upgrade_disclosure_toggle.disclosure_changed.connect(
		func(_expanded: bool) -> void: _on_campaign_interface_context_changed()
	)
	capital_section.add_child(_upgrade_disclosure_toggle)
	var requisitions_heading := _make_label("COOP REQUISITIONS", 17, Color("f4d27b"))
	requisitions_heading.name = "DeskRequisitionsHeading"
	capital_section.add_child(requisitions_heading)
	var requisition_targets: Array[Control] = [requisitions_heading]
	for upgrade in _simulation.upgrade_catalog():
		var upgrade_id := StringName(upgrade["id"])
		var upgrade_button := Button.new()
		upgrade_button.name = "Upgrade_%s" % String(upgrade_id)
		upgrade_button.theme_type_variation = &"UpgradeButton"
		upgrade_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		upgrade_button.clip_text = true
		upgrade_button.custom_minimum_size.y = 52.0
		upgrade_button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		capital_section.add_child(upgrade_button)
		requisition_targets.append(upgrade_button)
		_upgrade_buttons[upgrade_id] = upgrade_button
	_upgrade_disclosure_toggle.configure(
		"FILES",
		"3 FILES",
		requisition_targets,
		false,
	)
	_continue_shift_button = Button.new()
	_continue_shift_button.name = "ContinueDirectiveButton"
	_continue_shift_button.text = "CONTINUE: FILE SHIFT RESULTS"
	_continue_shift_button.theme_type_variation = &"PrimaryButton"
	_continue_shift_button.clip_text = true
	_continue_shift_button.custom_minimum_size.y = 44.0
	_continue_shift_button.tooltip_text = (
		"File this shift's results, then choose the next morning policy."
	)
	_continue_shift_button.accessibility_name = _continue_shift_button.tooltip_text
	_continue_shift_button.set_meta("accessible_text", _continue_shift_button.tooltip_text)
	_continue_shift_button.visible = false
	_continue_shift_button.pressed.connect(_on_continue_directive_pressed)
	today_section.add_child(_continue_shift_button)
	var today_snapshot_panel := PanelContainer.new()
	today_snapshot_panel.name = "FlockwatchTodaySnapshot"
	var today_snapshot_style := StyleBoxFlat.new()
	today_snapshot_style.bg_color = Color("18232f")
	today_snapshot_style.border_color = Color("485b68")
	today_snapshot_style.set_border_width_all(1)
	today_snapshot_style.set_corner_radius_all(7)
	today_snapshot_style.content_margin_left = 10.0
	today_snapshot_style.content_margin_right = 10.0
	today_snapshot_style.content_margin_top = 8.0
	today_snapshot_style.content_margin_bottom = 8.0
	today_snapshot_panel.add_theme_stylebox_override("panel", today_snapshot_style)
	today_section.add_child(today_snapshot_panel)
	var today_snapshot_rows := VBoxContainer.new()
	today_snapshot_rows.name = "FlockwatchTodaySnapshotRows"
	today_snapshot_rows.add_theme_constant_override("separation", 3)
	today_snapshot_panel.add_child(today_snapshot_rows)
	var today_snapshot_heading := _make_label("NOW", 12, Color("d9c47d"))
	today_snapshot_heading.name = "FlockwatchTodaySnapshotHeading"
	today_snapshot_rows.add_child(today_snapshot_heading)
	_today_glance_grid = _make_flockwatch_glance_grid("FlockwatchTodayGlanceGrid", 2)
	today_snapshot_rows.add_child(_today_glance_grid)
	_today_workload_glance = _add_flockwatch_glance_tile(
		_today_glance_grid,
		"FlockwatchTodayCasesGlance",
		"0 / 18\n0 LATE",
		&"files",
	)
	_today_clutch_glance = _add_flockwatch_glance_tile(
		_today_glance_grid,
		"FlockwatchTodayEggsGlance",
		"0 / 0\n0 TOTAL",
		&"egg",
	)
	_today_flock_glance = _add_flockwatch_glance_tile(
		_today_glance_grid,
		"FlockwatchTodayFlockGlance",
		"0%\nRISK 0",
		&"flock",
	)
	_today_cash_glance = _add_flockwatch_glance_tile(
		_today_glance_grid,
		"FlockwatchTodayCashGlance",
		"$0\nREADY",
		&"cash",
	)
	_today_workload_label = _make_label("WORKLOAD · 0 / 18 LIVE · 0 OVERDUE · 0 TURNED AWAY", 12)
	_today_workload_label.name = "FlockwatchTodayWorkload"
	_today_clutch_label = _make_label("CLUTCH · 0 / 0 TODAY · 0 CAREER EGGS", 12)
	_today_clutch_label.name = "FlockwatchTodayClutch"
	_today_flock_label = _make_label("FLOCK · 0% SPIRITS · 0% UNITY RISK", 12)
	_today_flock_label.name = "FlockwatchTodayFlock"
	_today_ledger_label = _make_label("LEDGERS · 0% FARMER FAVOR · 0% COOP OBEDIENCE", 12)
	_today_ledger_label.name = "FlockwatchTodayLedgers"
	_today_precedent_label = _make_label("", 12, Color("e2cb88"))
	_today_precedent_label.name = "FlockwatchTodayPrecedent"
	_today_precedent_label.visible = false
	for label in [
		_today_workload_label,
		_today_clutch_label,
		_today_flock_label,
		_today_ledger_label,
		_today_precedent_label,
	]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		if label != _today_precedent_label:
			label.visible = false
		today_snapshot_rows.add_child(label)
	_status_history_label = _make_label("SHIFT RECORD  /  No notices filed yet.", 12, Color("aeb8c4"))
	_status_history_label.name = "FlockwatchStatusHistory"
	_status_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	today_section.add_child(HSeparator.new())
	_status_history_toggle = Button.new()
	_status_history_toggle.name = "FlockwatchStatusHistoryToggle"
	_status_history_toggle.text = "SHIFT RECORD · EMPTY"
	_status_history_toggle.tooltip_text = "Show or hide the five most recent Flockwatch notices."
	_status_history_toggle.toggle_mode = true
	_status_history_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status_history_toggle.custom_minimum_size.y = 34.0
	_status_history_toggle.focus_mode = Control.FOCUS_ALL
	_status_history_toggle.toggled.connect(_on_status_history_toggled)
	today_section.add_child(_status_history_toggle)
	today_section.add_child(_status_history_label)
	_refresh_status_history_presentation()
	var initiatives := _make_label("ROOSTER DIRECTIVES", 17, Color("efb96d"))
	operations_section.add_child(initiatives)
	_feed_button = Button.new()
	_feed_button.name = "FeedPartyButton"
	_feed_button.theme_type_variation = &"PrimaryButton"
	_feed_button.text = "FUND FEED PARTY  ($20)  [P]"
	_feed_button.tooltip_text = "Once per shift: +10 morale, -8 stress, +2 farmer favor. Production pauses for attendance."
	_feed_button.clip_text = true
	_feed_button.custom_minimum_size.y = 42.0
	_feed_button.pressed.connect(_on_feed_pressed)
	operations_section.add_child(_feed_button)
	_overtime_button = Button.new()
	_overtime_button.name = "OvertimeToggleButton"
	_overtime_button.text = "ENABLE AFTER-HOURS PECKING  [O]"
	_overtime_button.tooltip_text = "+22% output; sharply increases fatigue, stress, morale loss, and crack risk. Resets next shift."
	_overtime_button.clip_text = true
	_overtime_button.custom_minimum_size.y = 42.0
	_overtime_button.theme_type_variation = &"DangerButton"
	_overtime_button.toggle_mode = true
	_overtime_button.pressed.connect(_on_overtime_pressed)
	operations_section.add_child(_overtime_button)
	_shift_help_disclosure_toggle = FlockwatchDisclosureToggleScript.new()
	_shift_help_disclosure_toggle.name = "OperationsShiftHelpToggle"
	_shift_help_disclosure_toggle.disclosure_changed.connect(
		func(_expanded: bool) -> void: _on_campaign_interface_context_changed()
	)
	operations_section.add_child(_shift_help_disclosure_toggle)
	var note := _make_label("TIP: Click a hen to inspect. Tab cycles; Esc returns.\nOne flock check-in is available each shift.\nThe farmer counts the clutch at 5:00 PM.", 13, Color("aeb8c4"))
	note.name = "OperationsShiftHelp"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operations_section.add_child(note)
	var shift_help_targets: Array[Control] = [note]
	_shift_help_disclosure_toggle.configure(
		"SHIFT HELP",
		"CONTROLS / CLOSING",
		shift_help_targets,
		false,
	)
	_commendations_disclosure_toggle = FlockwatchDisclosureToggleScript.new()
	_commendations_disclosure_toggle.name = "CareerCommendationsToggle"
	_commendations_disclosure_toggle.disclosure_changed.connect(
		func(_expanded: bool) -> void: _on_campaign_interface_context_changed()
	)
	records_section.add_child(_commendations_disclosure_toggle)
	var commendation_total := CareerCommendationsScript.IDS.size()
	_commendations_summary_label = _make_label(
		"COOP COMMENDATIONS  /  0 OF %d FILED\nNEXT STAMP  /  FIRST EGG, FULL CREDIT  /  0 / 1 EGG" % commendation_total,
		12,
		Color("e2cb88"),
	)
	_commendations_summary_label.name = "CareerCommendationsSummary"
	_commendations_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_commendations_summary_label.tooltip_text = (
		"Commendations are permanent recognition derived from the saved career ledger. "
		+ "They never hide an economy bonus or punish a missed session."
	)
	records_section.add_child(_commendations_summary_label)
	_commendation_earned_style = _panel_style(Color("293629"), 0.98, 7, 1)
	_commendation_earned_style.border_color = Color("b99a52")
	_commendation_locked_style = _panel_style(Color("17212a"), 0.82, 7, 1)
	_commendation_locked_style.border_color = Color("42515d")
	var commendation_targets: Array[Control] = []
	for definition: Dictionary in CareerCommendationsScript.definitions():
		var commendation_id := StringName(definition.get("id", &""))
		var commendation_panel := PanelContainer.new()
		commendation_panel.name = "CareerCommendation_%s" % String(commendation_id)
		commendation_panel.custom_minimum_size.y = 64.0
		commendation_panel.add_theme_stylebox_override("panel", _commendation_locked_style)
		records_section.add_child(commendation_panel)
		commendation_targets.append(commendation_panel)
		var commendation_margin := MarginContainer.new()
		commendation_margin.add_theme_constant_override("margin_left", 9)
		commendation_margin.add_theme_constant_override("margin_right", 9)
		commendation_margin.add_theme_constant_override("margin_top", 7)
		commendation_margin.add_theme_constant_override("margin_bottom", 7)
		commendation_panel.add_child(commendation_margin)
		var commendation_row := VBoxContainer.new()
		commendation_row.add_theme_constant_override("separation", 2)
		commendation_margin.add_child(commendation_row)
		var commendation_heading_row := HBoxContainer.new()
		commendation_heading_row.add_theme_constant_override("separation", 8)
		commendation_row.add_child(commendation_heading_row)
		var commendation_mark := _make_label("OPEN", 11, Color("82909a"))
		commendation_mark.name = "CareerCommendationMark_%s" % String(commendation_id)
		commendation_mark.custom_minimum_size.x = 42.0
		commendation_heading_row.add_child(commendation_mark)
		var commendation_title := _make_label(String(definition.get("title", "COMMENDATION")), 13, Color("c9d1d5"))
		commendation_title.name = "CareerCommendationTitle_%s" % String(commendation_id)
		commendation_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		commendation_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		commendation_heading_row.add_child(commendation_title)
		var commendation_progress := _make_label("0 / 1", 11, Color("9aa8af"))
		commendation_progress.name = "CareerCommendationProgress_%s" % String(commendation_id)
		commendation_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		commendation_heading_row.add_child(commendation_progress)
		var commendation_detail := _make_label(
			"%s  /  RECOGNITION: %s" % [
				String(definition.get("description", "")),
				String(definition.get("recognition", "Archive stamp")),
			],
			11,
			Color("93a1a8"),
		)
		commendation_detail.name = "CareerCommendationDetail_%s" % String(commendation_id)
		commendation_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		commendation_row.add_child(commendation_detail)
		_commendation_rows[commendation_id] = {
			"panel": commendation_panel,
			"mark": commendation_mark,
			"title": commendation_title,
			"progress": commendation_progress,
			"detail": commendation_detail,
			"earned": false,
		}
	_commendations_disclosure_toggle.configure(
		"COOP COMMENDATIONS",
		"0 / %d FILED" % commendation_total,
		commendation_targets,
		false,
	)
	records_section.add_child(HSeparator.new())
	var records_heading := _make_label("COOP RECORDS ARCHIVE", 17, Color("d8b88a"))
	records_heading.name = "FlockwatchRecordsArchiveHeading"
	records_section.add_child(records_heading)
	_records_archive_label = _make_label(
		"FARM MUTUAL / NO ACTIVE BINDER\nFLOCK LABOR / QUIET\nRECEIPTS / NONE FILED",
		11,
		Color("b9c8cc"),
	)
	_records_archive_label.name = "FlockwatchRecordsArchiveSummary"
	_records_archive_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_records_archive_label.tooltip_text = "Compact archive status; detailed actionable files remain above on this Records page."
	records_section.add_child(_records_archive_label)

	_flockwatch_navigation = FlockwatchNavigationScript.new() as FlockwatchNavigation
	side_margin.add_child(_flockwatch_navigation)
	_flockwatch_navigation.page_changed.connect(_on_flockwatch_page_changed)
	_flockwatch_navigation.show_all_filings_changed.connect(_on_flockwatch_show_all_filings_changed)
	_flockwatch_navigation.adopt_context_action(_continue_shift_button)
	_register_staffing_sections()
	_flockwatch_navigation.adopt_page_scroll(
		FlockwatchNavigation.PAGE_TODAY,
		side_scroll,
		side,
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_TODAY, today_section, &"today", 10
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_FLOCK, flock_section, &"flock", 10
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_OPERATIONS, operations_section, &"operations", 10
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_CAPITAL,
		economic_briefing_section,
		&"economic_briefing",
		5,
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_CAPITAL, capital_section, &"capital", 20
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS, records_section, &"records", 20
	)
	_set_flockwatch_open(false)

	_ticker_panel = PanelContainer.new()
	_ticker_panel.name = "StatusToast"
	_ticker_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_ticker_panel.offset_left = -390.0
	_ticker_panel.offset_top = -49.0
	_ticker_panel.offset_right = 390.0
	_ticker_panel.offset_bottom = -8.0
	_ticker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker_panel.add_theme_stylebox_override("panel", _panel_style(Color("523c2e"), 0.96, 9, 1))
	_ticker_panel.visible = false
	_ui_root.add_child(_ticker_panel)
	_ticker_label = _make_label("", 17, Color("fff0ca"))
	_ticker_label.name = "StatusToastLabel"
	_ticker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ticker_panel.add_child(_ticker_label)
	_character_dialogue_ui = CharacterDialogueUIScript.new()
	_character_dialogue_ui.name = "CharacterDialogueLayer"
	_character_dialogue_ui.z_index = 40
	_character_dialogue_ui.dialogue_presented.connect(
		_on_character_dialogue_presented
	)
	_character_dialogue_ui.dialogue_dismissed.connect(
		_on_character_dialogue_dismissed
	)
	_ui_root.add_child(_character_dialogue_ui)
	_hen_social_ui = HenSocialUIScript.new()
	_hen_social_ui.name = "PerchsideConversation"
	_ui_root.add_child(_hen_social_ui)
	_routing_ui = PeckworkRoutingUIScript.new() as PeckworkRoutingUI
	_routing_ui.assignment_requested.connect(_on_worker_assignment_requested)
	_routing_ui.dispatch_lane_requested.connect(_on_dispatch_lane_requested)
	_routing_ui.dispatch_drag_started.connect(_on_dispatch_drag_started)
	_routing_ui.dispatch_drag_released.connect(_on_dispatch_drag_released)
	_routing_ui.dispatch_drag_canceled.connect(_on_dispatch_drag_canceled)
	_routing_ui.assignment_undo_requested.connect(
		_on_worker_assignment_undo_requested
	)
	_routing_ui.claim_resolution_requested.connect(_on_claim_resolution_requested)
	_routing_ui.personnel_action_requested.connect(_on_personnel_action_requested)
	_routing_ui.peck_assist_requested.connect(_on_peck_assist_requested)
	_routing_ui.first_clutch_skip_requested.connect(_on_first_clutch_skip_requested)
	_routing_ui.first_clutch_action_requested.connect(_on_first_clutch_action_requested)
	_routing_ui.first_clutch_focus_requested.connect(_on_first_clutch_focus_requested)
	_routing_ui.first_clutch_skip_rect_settled.connect(_on_first_clutch_skip_rect_settled)
	_routing_ui.interaction_safety_changed.connect(
		_on_interaction_safety_presentation_changed
	)
	_ui_root.add_child(_routing_ui)
	_build_explain_strip()
	_build_held_confirmation_scrim()
	_build_day_review_panel()
	_build_decision_modal()
	if not _defer_capital_planning:
		_build_capital_planning_surfaces()
	_campaign_ui = ProbationCampaignUIScript.new() as ProbationCampaignUI
	_campaign_ui.set("_defer_review_surfaces", _defer_management_ui)
	_campaign_ui.review_surface_built.connect(_on_campaign_review_surface_built)
	_campaign_ui.continue_campaign.connect(_on_campaign_continue_requested)
	_campaign_ui.new_campaign.connect(_on_campaign_new_requested)
	_campaign_ui.abandon_campaign.connect(_on_campaign_abandon_requested)
	_campaign_ui.review_requisitions.connect(_on_campaign_review_requisitions_requested)
	_campaign_ui.challenge_contract_changed.connect(_on_campaign_challenge_contract_changed)
	_campaign_ui.career_slot_changed.connect(_on_career_slot_changed)
	_campaign_ui.career_identity_changed.connect(_on_career_identity_changed)
	_campaign_ui.replay_scenario_changed.connect(_on_replay_scenario_changed)
	_campaign_ui.legacy_card_requested.connect(_on_legacy_card_requested)
	_campaign_ui.title_intake_phase_changed.connect(_on_campaign_title_intake_phase_changed)
	_campaign_ui.milestone_choice.connect(_on_campaign_milestone_requested)
	_campaign_ui.presentation_state_changed.connect(_on_campaign_presentation_state_changed)
	_campaign_ui.report_filing_settled.connect(_on_campaign_report_filing_settled)
	_campaign_ui.live_order_mark_requested.connect(_on_campaign_live_order_mark_requested)
	_campaign_ui.career_sponsorship_requested.connect(_on_career_sponsorship_requested)
	_campaign_ui.market_contract_sign_requested.connect(_on_market_contract_sign_requested)
	_campaign_ui.market_contract_decline_requested.connect(_on_market_contract_decline_requested)
	_ui_root.add_child(_campaign_ui)
	if not _defer_management_ui:
		_build_settings_surface()


func _on_campaign_review_surface_built(surface: Control) -> void:
	_apply_explicit_font_scale(surface, float(_player_preferences.get("ui_scale", 1.0)))


func _register_staffing_sections() -> void:
	if _staffing_ui == null or _flockwatch_navigation == null:
		return
	var staffing_sections: Dictionary = _staffing_ui.navigation_sections()
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_FLOCK,
		staffing_sections.get(&"flock") as Control,
		&"staffing_flock",
		20,
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_OPERATIONS,
		staffing_sections.get(&"operations") as Control,
		&"staffing_operations",
		20,
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_CAPITAL,
		staffing_sections.get(&"capital") as Control,
		&"staffing_capital",
		10,
	)
	_flockwatch_navigation.register_section(
		FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS,
		staffing_sections.get(&"records") as Control,
		&"staffing_records",
		10,
	)


func _on_personal_goal_toggled() -> void:
	if _personal_goal_offer.is_empty() or not _day_review_scrim.visible:
		return
	_personal_goal = {} if _personal_goal == _personal_goal_offer else _personal_goal_offer.duplicate(true)
	_personal_goal_button.text = "GOAL ACCEPTED · CANCEL" if not _personal_goal.is_empty() else "TRY NEXT SHIFT · " + PersonalShiftGoal.label(_personal_goal_offer)
	_save_campaign_checkpoint("personal_goal_chosen")
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_review_details_toggled() -> void:
	_set_review_details_expanded(not _review_details_expanded)


func _on_decision_requested(decision: Dictionary) -> void:
	if decision.is_empty() or _decision_host == null:
		return
	_last_optional_floor_beat_msec = Time.get_ticks_msec()
	_character_dialogue_ui.hold_ambient(4.0)
	# Restore the player's prior pace before the decision captures its resume
	# speed; the temporary 10× seek is never allowed to leak past the moment.
	_finish_next_moment("NEXT MOMENT REACHED  ·  DECISION READY", false)
	_decision_before_snapshot = _simulation.snapshot().duplicate(true)
	_active_decision = decision.duplicate(true)
	var decision_panel_width := minf(
		760.0,
		maxf(300.0, get_viewport().get_visible_rect().size.x - 52.0),
	)
	_decision_panel.custom_minimum_size.x = decision_panel_width
	if _decision_petition_glance != null:
		_decision_petition_glance.columns = _decision_petition_glance_column_count(
			decision_panel_width
		)
	_selected_decision_option = &""
	var kind := StringName(decision.get("kind", &"incident"))
	if kind == &"directive":
		decision_panel_width = minf(
			940.0,
			maxf(300.0, get_viewport().get_visible_rect().size.x - 52.0),
		)
		_decision_panel.custom_minimum_size.x = decision_panel_width
	var decision_category := StringName(decision.get("category", &""))
	var option_count := (decision.get("options", []) as Array).size()
	_decision_options.columns = _decision_option_column_count(
		kind,
		decision_category,
		option_count,
		decision_panel_width,
	)
	_decision_restore_farmer_review = false
	if kind == FIRST_CLUTCH_REINVESTMENT_KIND:
		_decision_previous_speed = _clock.speed_index
		_decision_restore_farmer_review = (
			_campaign_review_stage == &"farmer"
			or (_day_review_scrim != null and _day_review_scrim.visible)
		)
		if _audio_feedback != null:
			_audio_feedback.play_decision_alert()
		if _office_atmosphere != null:
			_office_atmosphere.pulse_alert(0.42)
	elif kind == &"incident":
		_decision_previous_speed = _clock.speed_index if _clock.speed_index > 0 else 1
		if _audio_feedback != null:
			_audio_feedback.play_decision_alert()
		if _office_atmosphere != null:
			_office_atmosphere.pulse_alert(0.75)
	elif kind == &"directive":
		_decision_previous_speed = 1
	else:
		_decision_previous_speed = 0
		if _audio_feedback != null:
			_audio_feedback.play_decision_alert()
		if _office_atmosphere != null:
			_office_atmosphere.pulse_alert(0.55)
	_clock.set_speed(0)
	_set_flockwatch_open(false)
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	_refresh_first_clutch_ui(_simulation.snapshot())

	_decision_eyebrow.text = String(decision.get("eyebrow", "MANAGEMENT DECISION"))
	if kind in [&"credit_allocation", &"major_event"] and _campaign_review_stage == &"credit":
		_decision_eyebrow.text = "CLOSING FILE 2 / 3  ·  %s" % _decision_eyebrow.text
	_decision_title.text = String(decision.get("title", "CHOOSE A RESPONSE"))
	_decision_title.visible = true
	_decision_body.text = String(decision.get("body", "A measurable variance requires management attention."))
	_decision_body.visible = true
	_decision_preview.visible = true
	_decision_body.set_meta("accessible_text", String(decision.get(
		"accessible_body", _decision_body.text,
	)))
	_set_decision_petition_glance_visible(false)
	if _decision_petition_semantics != null:
		_decision_petition_semantics.text = ""
	_set_decision_order_glance_visible(false)
	var case_memory := decision.get("case_memory", {}) as Dictionary
	if kind == &"incident" and not case_memory.is_empty():
		_decision_body.text += "\n\n%s // %s\n%s" % [
			String(case_memory.get("strategy_label", "PIVOT OPPORTUNITY")),
			String(case_memory.get("label", "PRIOR CASE FILE")),
			String(case_memory.get("summary", "A prior response changes this case.")),
		]
	var opening_policy := (
		kind == &"directive"
		and not _campaign_senior_roost
		and _campaign_state != null
		and int(_campaign_state.completed_shifts) == 0
	)
	var first_hen_policy := opening_policy and _first_hen_policy_context_active()
	if first_hen_policy:
		var first_hen := _first_clutch_worker_snapshot(
			_simulation.snapshot(),
			int(_first_clutch.get("target_worker_id", FIRST_HEN_WORKER_ID)),
		)
		var first_hen_name := String(first_hen.get("name", "Mabel")).to_upper()
		var case_docket := _simulation.case_docket_snapshot()
		_decision_eyebrow.text = "%s'S FIRST FILE  //  DAY 1  //  %s" % [
			first_hen_name,
			String(case_docket.get("id", "PO-1701")),
		]
	if opening_policy:
		_decision_title.text = "PICK TODAY'S FLOCK RULE"
		_decision_body.text = "You manage the flock. Choose a rule, route work, and support the hens."
		_decision_body.set_meta(
			"accessible_text",
			"Choose one rule for the whole flock. Compare each rule with today's three scored goals, then authorize the shift.",
		)
		_configure_decision_order_glance()
	if kind == &"directive" and not _campaign_senior_roost and not opening_policy:
		_shift_continuity = _compose_shift_continuity(_simulation.day)
		_decision_title.text = "PLAN SHIFT %d" % _simulation.day
		_decision_body.text = String(_shift_continuity.get("briefing", ""))
		_decision_body.set_meta("accessible_text", _decision_body.text)
		_configure_decision_order_glance()
	if decision_category == &"flock_petition":
		var sponsor_worker_id := int(decision.get("sponsor_worker_id", -1))
		if _camera_controller != null and sponsor_worker_id >= 0:
			_camera_controller.focus_worker(sponsor_worker_id)
		_configure_decision_petition_glance(decision)
	_decision_preview.text = String(decision.get(
		"selection_prompt",
		(
			"PICK A RULE. ITS GOAL FIT WILL LIGHT UP ABOVE."
			if opening_policy else
			"Each card compares its real effects with today's scored orders. Select one to inspect the exact fit and consequences."
			if kind == &"directive" else
			"Choose a response card. The shift remains safely paused until you authorize it."
		),
	))
	if opening_policy:
		_decision_preview.visible = false
	for child in _decision_options.get_children():
		_decision_options.remove_child(child)
		child.queue_free()
	_decision_option_buttons.clear()
	var option_index := 0
	var fund_cents := _simulation.spendable_fund_cents()
	for option_value in decision.get("options", []):
		var option := option_value as Dictionary
		var option_id := StringName(option.get("id", &""))
		var label := String(option.get("label", "RESPONSE"))
		var card_label := String(option.get("short_label", label))
		var tagline := String(option.get("tagline", ""))
		var preview := String(option.get("preview", "Consequence pending."))
		var visible_incident_preview := preview
		var accessible_preview := String(option.get("accessible_preview", preview))
		if bool(option.get("case_memory_active", false)):
			var active_pivot_label := String(option.get(
				"case_memory_label",
				"PIVOT OPPORTUNITY",
			))
			preview = "%s // ACTIVE\n%s" % [
				active_pivot_label,
				preview,
			]
			accessible_preview = "%s // ACTIVE\n%s" % [
				active_pivot_label,
				accessible_preview,
			]
			visible_incident_preview = "ACTIVE BONUS · %s" % visible_incident_preview
		var precedent := option.get("precedent", {}) as Dictionary
		var precedent_preview := ""
		if not precedent.is_empty():
			precedent_preview = "\n\n%s // %s\n%s" % [
				String(precedent.get("strategy_label", "PIVOT OPPORTUNITY")),
				String(precedent.get("target_label", "NEXT RELATED CASE")),
				String(precedent.get("summary", "This response changes the next related case.")),
			]
			visible_incident_preview += "\nNEXT CLAIM · %s" % String(precedent.get("summary", "This response changes the next related claim."))
		var cost_cents := int(option.get("cost_cents", 0))
		var option_available := bool(option.get("can_select", true))
		var order_fit := _directive_order_fit(option_id) if kind == &"directive" else {}
		var order_fit_detail := String(order_fit.get("detail", ""))
		var full_preview := "%s%s%s%s" % [
			("%s\n" % tagline if not tagline.is_empty() else ""),
			preview,
			("\n\n%s" % order_fit_detail if not order_fit_detail.is_empty() else ""),
			precedent_preview,
		]
		var button := Button.new()
		button.name = "DecisionOption_%s" % String(option_id)
		button.theme_type_variation = &"DecisionChoiceButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.focus_mode = Control.FOCUS_ALL
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = (
			72.0 if kind == FIRST_CLUTCH_REINVESTMENT_KIND else
			(82.0 if decision_category == &"flock_petition" else 58.0)
		)
		var option_glance := (
			"HELPS %d  ·  RISKS %d" % [
				int(order_fit.get("support_count", 0)),
				int(order_fit.get("risk_count", 0)),
			]
			if opening_policy and not order_fit.is_empty() else
			String(order_fit.get("compact", ""))
			if kind == &"directive" else
			""
		)
		var authored_glance := String(option.get("glance", ""))
		if kind == &"incident" and not authored_glance.is_empty():
			var cost_glance := (
				"FREE"
				if cost_cents <= 0 else
				"$%d" % (cost_cents / 100)
				if decision_category == &"flock_petition" and cost_cents % 100 == 0 else
				"$%.2f" % (float(cost_cents) / 100.0)
				if decision_category == &"flock_petition" else
				"$%d COST" % (cost_cents / 100)
				if cost_cents % 100 == 0 else
				"$%.2f COST" % (float(cost_cents) / 100.0)
			)
			option_glance = "%s  /  %s" % [cost_glance, authored_glance]
		button.text = ("%d  %s\n%s" if opening_policy else "%d  //  %s\n%s") % [
			option_index + 1,
			card_label,
			option_glance if not option_glance.is_empty() else (tagline if not tagline.is_empty() else "Select to review terms below."),
		]
		var effect_chips := option.get("effect_chips", []) as Array
		if not effect_chips.is_empty():
			button.text += "\n\n"
			_mount_decision_effect_chips(button, option_id, effect_chips)
		button.set_meta("base_text", button.text)
		button.set_meta("option_id", option_id)
		button.set_meta("card_label", card_label)
		button.set_meta("opening_policy", opening_policy)
		button.set_meta("preview", full_preview)
		button.set_meta("visible_incident_preview", visible_incident_preview)
		button.set_meta("accessible_text", "%s. %s" % [label, accessible_preview])
		button.set_meta("confirm_label", String(option.get("confirm_label", "")))
		button.set_meta("order_fit", order_fit.duplicate(true))
		button.set_meta("cost_cents", cost_cents)
		button.disabled = not option_available or cost_cents > fund_cents
		if button.disabled:
			button.tooltip_text = String(option.get(
				"unavailable_reason",
				"Requires $%.2f Feed Fund; only $%.2f is available." % [cost_cents / 100.0, fund_cents / 100.0],
			))
		else:
			button.tooltip_text = "%s\n%s\n%s" % [
				label,
				"Select to preview, then authorize below.",
				accessible_preview,
			]
		button.pressed.connect(_on_decision_option_pressed.bind(option_id))
		_decision_options.add_child(button)
		_decision_option_buttons.append(button)
		option_index += 1
	var is_directive := kind == &"directive"
	var allow_stay_paused := bool(decision.get("allow_stay_paused", kind == &"incident"))
	_decision_stay_paused_button.visible = allow_stay_paused
	_decision_stay_paused_button.custom_minimum_size.y = 46.0
	_decision_stay_paused_button.disabled = true
	_decision_confirm_button.disabled = true
	_decision_confirm_button.custom_minimum_size.y = (
		66.0 if kind == FIRST_CLUTCH_REINVESTMENT_KIND else 46.0
	)
	_decision_confirm_button.text = String(decision.get(
		"confirm_label",
		(
			"AUTHORIZE & START SHIFT"
			if is_directive else
			"RESOLVE & RESUME %d×" % int(SimulationClock.SPEED_MULTIPLIERS[_decision_previous_speed])
		),
	))
	if opening_policy:
		_decision_confirm_button.text = "SELECT A RULE ABOVE"
	_decision_host.visible = true
	_refresh_floor_input_context()
	# Visibility itself is part of the coach's management-blocked predicate. Refresh
	# after mounting the card so a restored reinvestment never renders underneath it.
	_refresh_first_clutch_ui(_simulation.snapshot())
	# The Web/assistive contract must match the card as soon as it is visible;
	# waiting for the first option click leaves nonvisual players one interaction
	# behind the rendered decision.
	_publish_web_diagnostic_state(_simulation.snapshot())
	_decision_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_decision_panel.scale = Vector2(0.96, 0.96)
	await get_tree().process_frame
	if not is_instance_valid(_decision_panel) or not _decision_host.visible:
		return
	_decision_panel.pivot_offset = _decision_panel.size * 0.5
	var tween := _presentation_tween().set_parallel(true)
	tween.tween_property(_decision_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(_decision_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for button in _decision_option_buttons:
		if not button.disabled:
			button.grab_focus()
			break
	_update_guidance(_simulation.snapshot())


func _probation_orders_brief() -> String:
	if _campaign_state == null:
		return ""
	var lines: Array[String] = []
	for objective in _campaign_state.current_objectives():
		lines.append("• %s  ·  %s  ·  +%d SCORE" % [
			String(objective.get("title", "PROBATION ORDER")).to_upper(),
			String(objective.get("description", "Filed against the closing ledger.")),
			int(objective.get("score_award", 0)),
		])
	return "\n".join(lines)


func _directive_order_fit(directive_id: StringName) -> Dictionary:
	return _directive_order_fit_for_objectives(
		directive_id,
		_campaign_state.current_objectives() if _campaign_state != null else [],
	)


func _directive_order_fit_for_objectives(
	directive_id: StringName,
	objectives: Array[Dictionary],
) -> Dictionary:
	var fit := {
		"supports": [],
		"risks": [],
		"support_ids": [],
		"risk_ids": [],
		"support_count": 0,
		"risk_count": 0,
		"compact": "HELPS 0  ·  RISKS 0",
		"detail": "No active probation orders are available for comparison.",
		"long_term": "",
	}
	if _campaign_senior_roost or not DIRECTIVE_ORDER_FIT_RULES.has(directive_id):
		return fit
	var rules := DIRECTIVE_ORDER_FIT_RULES[directive_id] as Dictionary
	var supported_metrics := rules.get("supports", []) as Array
	var risk_metrics := rules.get("risks", []) as Array
	var support_titles: Array[String] = []
	var risk_titles: Array[String] = []
	var support_ids: Array[String] = []
	var risk_ids: Array[String] = []
	for objective in objectives:
		var metric := StringName(objective.get("metric", &""))
		var objective_id := String(objective.get("id", ""))
		var title := String(objective.get("title", "Probation order")).to_upper()
		if metric in supported_metrics:
			support_titles.append(title)
			support_ids.append(objective_id)
		elif metric in risk_metrics:
			risk_titles.append(title)
			risk_ids.append(objective_id)
	var long_term := String(rules.get("long_term", ""))
	fit["supports"] = support_titles
	fit["risks"] = risk_titles
	fit["support_ids"] = support_ids
	fit["risk_ids"] = risk_ids
	fit["support_count"] = support_titles.size()
	fit["risk_count"] = risk_titles.size()
	fit["compact"] = "HELPS %d  ·  RISKS %d" % [support_titles.size(), risk_titles.size()]
	fit["long_term"] = long_term
	fit["detail"] = "TODAY'S ORDER FIT  //  SUPPORTS: %s  //  RISKS: %s\nLONG-TERM STRENGTH  //  %s  //  directional; closing ledger decides" % [
		", ".join(support_titles) if not support_titles.is_empty() else "NO DIRECT ORDER",
		", ".join(risk_titles) if not risk_titles.is_empty() else "NO DIRECT CONFLICT",
		long_term if not long_term.is_empty() else "GENERAL OPERATIONS",
	]
	return fit


func _campaign_strategy_receipt(completed_shift: int) -> Dictionary:
	if (
		_campaign_senior_roost
		or _campaign_state == null
		or completed_shift < 1
		or completed_shift > _campaign_state.shift_records.size()
	):
		return {}
	var directive := _last_workday_report.get("directive", {}) as Dictionary
	var directive_id := StringName(directive.get("id", &""))
	if directive_id == &"" or not DIRECTIVE_ORDER_FIT_RULES.has(directive_id):
		return {}
	var objectives := _campaign_state.objectives_for_shift(completed_shift)
	var fit := _directive_order_fit_for_objectives(directive_id, objectives)
	var support_ids := fit.get("support_ids", []) as Array
	var risk_ids := fit.get("risk_ids", []) as Array
	var record: CampaignShiftRecord = _campaign_state.shift_records[completed_shift - 1]
	var results_by_id: Dictionary = {}
	for result in record.objective_results:
		results_by_id[String(result.get("id", ""))] = bool(result.get("completed", false))
	var supported_met := 0
	var risks_covered := 0
	var neutral_met := 0
	var neutral_total := 0
	var evidence: Array[Dictionary] = []
	for objective in objectives:
		var objective_id := String(objective.get("id", ""))
		var completed := bool(results_by_id.get(objective_id, false))
		var relation := &"neutral"
		if objective_id in support_ids:
			relation = &"support"
			if completed:
				supported_met += 1
		elif objective_id in risk_ids:
			relation = &"risk"
			if completed:
				risks_covered += 1
		else:
			neutral_total += 1
			if completed:
				neutral_met += 1
		evidence.append({
			"id": objective_id,
			"title": String(objective.get("title", "PROBATION ORDER")).to_upper(),
			"relation": String(relation),
			"completed": completed,
		})
	var support_total := support_ids.size()
	var risk_total := risk_ids.size()
	var risks_landed := maxi(0, risk_total - risks_covered)
	var status := &"no_direct_bet"
	var headline := "NO DIRECT BET"
	var tone := &"neutral"
	if support_total > 0 or risk_total > 0:
		if supported_met == support_total and risks_landed == 0:
			status = &"held"
			headline = "PLAN HELD"
			tone = &"positive"
		elif supported_met > 0 or risks_covered > 0:
			status = &"mixed"
			headline = "MIXED RESULT"
			tone = &"warning"
		else:
			status = &"pivot"
			headline = "PIVOT NEEDED"
			tone = &"negative"
	var policy_name := String(directive.get(
		"short_name",
		directive.get("name", String(directive_id).replace("_", " ")),
	)).to_upper()
	var forecast := "HELPS %d / RISKS %d" % [support_total, risk_total]
	var actual := "%d/%d HELP / %d/%d RISKS COVERED" % [
		supported_met,
		support_total,
		risks_covered,
		risk_total,
	]
	var evidence_lines: Array[String] = []
	for row in evidence:
		evidence_lines.append("%s / %s / %s" % [
			"MET" if bool(row.get("completed", false)) else "MISSED",
			String(row.get("relation", "neutral")).to_upper(),
			String(row.get("title", "PROBATION ORDER")),
		])
	return {
		"day": completed_shift,
		"directive_id": String(directive_id),
		"policy_name": policy_name,
		"semantic_icon": String(_live_policy_icon(directive_id)),
		"status": String(status),
		"tone": String(tone),
		"headline": headline,
		"forecast": forecast,
		"actual": actual,
		"support_total": support_total,
		"support_met": supported_met,
		"risk_total": risk_total,
		"risk_covered": risks_covered,
		"risk_landed": risks_landed,
		"neutral_total": neutral_total,
		"neutral_met": neutral_met,
		"evidence": evidence,
		"detail": "MORNING PLAN / %s\nFORECAST / %s\nCLOSING RESULT / %s\n%s" % [
			policy_name,
			forecast,
			actual,
			"\n".join(evidence_lines),
		],
	}


func _on_decision_option_pressed(option_id: StringName) -> void:
	_selected_decision_option = option_id
	for button in _decision_option_buttons:
		var is_selected := StringName(button.get_meta("option_id", &"")) == option_id
		var opening_policy := bool(button.get_meta("opening_policy", false))
		var incident_choice := StringName(_active_decision.get("kind", &"")) == &"incident"
		button.theme_type_variation = &"SelectedChoiceButton" if is_selected else &"DecisionChoiceButton"
		button.text = String(button.get_meta("base_text", button.text))
		if opening_policy:
			button.modulate = Color.WHITE if is_selected else Color(1.0, 1.0, 1.0, 0.64)
			button.set_meta("selection_visual_role", &"selected" if is_selected else &"alternative")
			if is_selected:
				button.text = "> %s" % button.text
		elif incident_choice:
			# Cost-gated and unavailable incident responses already carry deliberate
			# warning contrast. Recede only another actionable choice so selection
			# hierarchy never makes a disabled warning harder to read.
			button.modulate = (
				Color.WHITE
				if is_selected or button.disabled else
				Color(1.0, 1.0, 1.0, 0.72)
			)
			button.set_meta(
				"selection_visual_role",
				&"selected" if is_selected else (&"unavailable" if button.disabled else &"alternative"),
			)
			if is_selected:
				button.text = "> %s" % button.text
		else:
			button.modulate = Color.WHITE
			button.set_meta("selection_visual_role", &"peer")
		if is_selected:
			var full_preview := String(button.get_meta("preview", "Consequence pending."))
			var order_fit := button.get_meta("order_fit", {}) as Dictionary
			if opening_policy and not order_fit.is_empty():
				_decision_title.visible = false
				_decision_body.visible = false
				_apply_decision_order_fit_visuals(order_fit)
				_decision_preview.visible = true
				_decision_preview.text = "SELECTED  ·  %s  ·  BEST FOR %s" % [
					String(button.get_meta("card_label", "RULE")),
					String(order_fit.get("long_term", "GENERAL OPERATIONS")),
				]
				_decision_confirm_button.text = "START SHIFT  ·  %s" % String(
					button.get_meta("card_label", "RULE")
				)
			elif incident_choice:
				# Once a compact player commits to one of the still-reversible cards,
				# retire the already-read setup paragraph and show a terse receipt.
				# The exact authored prose remains attached as accessible text below.
				if _decision_panel.custom_minimum_size.x < 500.0:
					_decision_body.visible = false
				_decision_preview.text = "NOW · %s" % String(button.get_meta("visible_incident_preview", full_preview))
			else:
				_decision_preview.text = "SELECTED  ·  %s" % full_preview
				if StringName(_active_decision.get("kind", &"")) == FIRST_CLUTCH_REINVESTMENT_KIND:
					var confirm_label := String(button.get_meta("confirm_label", ""))
					if not confirm_label.is_empty():
						_decision_confirm_button.text = confirm_label
			_decision_preview.set_meta("accessible_text", full_preview)
	_decision_confirm_button.disabled = false
	_decision_stay_paused_button.disabled = false
	# Keyboard authorization is deliberately two-step: 1/2/3 selects a card,
	# then focus moves to Confirm so Enter cannot re-trigger the option button.
	_decision_confirm_button.grab_focus()
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_update_guidance(_simulation.snapshot())
	_refresh_speed_button_copy()
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_decision_stay_paused_pressed() -> void:
	_resume_after_decision = false
	_commit_selected_decision()


func _on_decision_confirm_pressed() -> void:
	_resume_after_decision = true
	_commit_selected_decision()


# --- OfficeFirstClutchCoach delegators: implementation lives in office_first_clutch_coach.gd ---
func _should_hold_first_clutch_orientation() -> bool:
	return _first_clutch_coach._should_hold_first_clutch_orientation()


func _handle_first_clutch_primary_action() -> bool:
	return _first_clutch_coach._handle_first_clutch_primary_action()


func _make_first_clutch_state(dismissed: bool = true) -> Dictionary:
	return _first_clutch_coach._make_first_clutch_state(dismissed)


func _reset_first_clutch(enabled: bool) -> void:
	_first_clutch_coach._reset_first_clutch(enabled)


func _normalize_first_clutch_state(value: Dictionary, legacy_missing: bool = false) -> Dictionary:
	return _first_clutch_coach._normalize_first_clutch_state(value, legacy_missing)


func first_clutch_snapshot() -> Dictionary:
	return _first_clutch_coach.first_clutch_snapshot()


func _first_clutch_tracking_active() -> bool:
	return _first_clutch_coach._first_clutch_tracking_active()


func _first_clutch_can_reopen() -> bool:
	return _first_clutch_coach._first_clutch_can_reopen()


func _first_clutch_orders_handoff_pending() -> bool:
	return _first_clutch_coach._first_clutch_orders_handoff_pending()


func _first_clutch_reinvestment_resolved() -> bool:
	return _first_clutch_coach._first_clutch_reinvestment_resolved()


func _first_clutch_worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	return _first_clutch_coach._first_clutch_worker_snapshot(snapshot, worker_id)


func _first_clutch_record_inspection(worker_id: int) -> void:
	_first_clutch_coach._first_clutch_record_inspection(worker_id)


func _first_clutch_record_routing(worker_id: int, lane: StringName) -> void:
	_first_clutch_coach._first_clutch_record_routing(worker_id, lane)


func _first_clutch_record_checkin(worker_id: int) -> void:
	_first_clutch_coach._first_clutch_record_checkin(worker_id)


func _first_clutch_record_assist(result: Dictionary) -> void:
	_first_clutch_coach._first_clutch_record_assist(result)


func _first_clutch_record_laid_egg(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	claim_id: int = -1,
	priority_credit_cents: int = -1
) -> void:
	_first_clutch_coach._first_clutch_record_laid_egg(worker_id, quality, value_cents, claim_id, priority_credit_cents)


func _first_clutch_record_presentation(
	worker_id: int,
	claim_id: int,
	quality: StringName,
	value_cents: int
) -> void:
	_first_clutch_coach._first_clutch_record_presentation(worker_id, claim_id, quality, value_cents)


func _present_first_clutch_reinvestment(status: Dictionary = {}) -> bool:
	return _first_clutch_coach._present_first_clutch_reinvestment(status)


func _reconcile_first_clutch_reinvestment_after_restore() -> bool:
	return _first_clutch_coach._reconcile_first_clutch_reinvestment_after_restore()


func _first_clutch_prepare_for_shift_boundary() -> void:
	_first_clutch_coach._first_clutch_prepare_for_shift_boundary()


func _first_clutch_stage() -> StringName:
	return _first_clutch_coach._first_clutch_stage()


func _first_clutch_coach_snapshot(snapshot: Dictionary) -> Dictionary:
	return _first_clutch_coach._first_clutch_coach_snapshot(snapshot)


func _refresh_first_clutch_ui(snapshot: Dictionary = {}) -> void:
	_first_clutch_coach._refresh_first_clutch_ui(snapshot)


func _clear_first_clutch_global_cue() -> void:
	_first_clutch_coach._clear_first_clutch_global_cue()


func _acknowledge_first_clutch_orders_handoff() -> void:
	_first_clutch_coach._acknowledge_first_clutch_orders_handoff()


func _capture_first_clutch_preview(check_in := false) -> void:
	await _first_clutch_coach._capture_first_clutch_preview(check_in)


func _capture_first_clutch_reinvestment_preview(
	show_orders_handoff := false,
	open_orders_dashboard := false,
) -> void:
	await _first_clutch_coach._capture_first_clutch_reinvestment_preview(show_orders_handoff, open_orders_dashboard)


func _capture_first_clutch_playbook_preview() -> void:
	await _first_clutch_coach._capture_first_clutch_playbook_preview()


func _on_first_clutch_reinvestment_resolved(result: Dictionary) -> void:
	var presentation := result.duplicate(true)
	presentation["kind"] = FIRST_CLUTCH_REINVESTMENT_KIND
	_on_decision_resolved(presentation)


func _on_action_outcome_receipt_finished(panel: Control, is_last: bool) -> void:
	_active_action_outcome_panels.erase(panel)
	if panel != null and is_instance_valid(panel):
		panel.queue_free()
	if is_last and not _latest_action_outcome_receipt.is_empty():
		_latest_action_outcome_receipt["visible"] = false
		_latest_action_outcome_receipt["dismissed_by"] = "settled"
		_publish_web_diagnostic_state(_simulation.snapshot())


func _retire_action_outcome_receipts(reason: StringName, publish_state := true) -> int:
	var retired_count := 0
	for panel in _active_action_outcome_panels:
		if panel != null and is_instance_valid(panel):
			panel.queue_free()
			retired_count += 1
	_active_action_outcome_panels.clear()
	if not _latest_action_outcome_receipt.is_empty():
		_latest_action_outcome_receipt["visible"] = false
		_latest_action_outcome_receipt["dismissed_by"] = String(reason)
		_latest_action_outcome_receipt["retired_panel_count"] = retired_count
	if publish_state and _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())
	return retired_count


func _on_decision_resolved(result: Dictionary) -> void:
	_begin_payoff_breath()
	var resolved_snapshot := _simulation.snapshot()
	_spawn_decision_consequence_receipts(
		_decision_before_snapshot,
		resolved_snapshot,
		result,
	)
	_decision_before_snapshot = {}
	var kind := StringName(result.get("kind", &"incident"))
	var restore_farmer_review := _decision_restore_farmer_review
	_decision_host.visible = false
	_active_decision.clear()
	_selected_decision_option = &""
	_decision_restore_farmer_review = false
	_refresh_floor_input_context()
	var outcome := String(
		result.get(
			"resolution_summary",
			result.get("outcome", "Management decision recorded."),
		)
	)
	_ticker_label.text = outcome
	var decision_dialogue := CharacterDialogueCatalogScript.beat_for_decision_result(result, _simulation.day)
	if kind == &"directive" and bool(_first_clutch.get("route_first_lesson", false)):
		# Flavor should not insert another blocking click between policy and work.
		decision_dialogue = decision_dialogue.duplicate(true)
		decision_dialogue["presentation_mode"] = "ambient"
		_character_dialogue_ui.hold_ambient(3.0)
	_queue_character_dialogue(decision_dialogue)
	if kind == FIRST_CLUTCH_REINVESTMENT_KIND:
		var purchased := bool(result.get("purchased", false))
		if purchased:
			var worker_id := int(result.get("trigger_worker_id", FIRST_HEN_WORKER_ID))
			var desk_index := -1
			var active_snapshot := _snapshot_with_active_workers(_simulation.snapshot())
			var worker := _first_clutch_worker_snapshot(active_snapshot, worker_id)
			if not worker.is_empty():
				desk_index = int(worker.get("desk_index", -1))
			if _workstation_feedback != null:
				_workstation_feedback.apply_snapshot(_workstation_visual_snapshot(active_snapshot))
				var installed := _workstation_feedback.play_reinvestment_install(
					worker_id,
					desk_index,
					StringName(result.get("choice_id", &"")),
					int(result.get("selected_level", 0)),
				)
				if installed and _camera_controller != null and not bool(_first_clutch.get("route_first_lesson", false)):
					# The installation is a brief payoff, not a permanent camera mode.
					# Event focus returns to overview unless the player pans, zooms,
					# or selects another subject during the reveal.
					_camera_controller.show_overview()
					_camera_controller.show_event_focus(
						_workstation_feedback.install_focus_point_global(desk_index),
						"FIRST CLUTCH REINVESTMENT",
						1.5,
						true,
					)
		elif _audio_feedback != null:
			_audio_feedback.play_policy_stamp()
		if restore_farmer_review and not _last_workday_report.is_empty():
			_clock.set_speed(0)
			_show_farmer_review(_last_workday_report, false)
		else:
			_clock.set_speed(_decision_previous_speed)
		_decision_restore_farmer_review = false
		var reinvestment_snapshot := _simulation.snapshot()
		_refresh_first_clutch_ui(reinvestment_snapshot)
		_refresh_flockwatch_navigation(reinvestment_snapshot)
		_update_guidance(reinvestment_snapshot)
		var reward_copy := "FEED FUND SAVED · READY FOR THE SHIFT"
		if purchased:
			var kit := DepartmentSimulation.UPGRADE_DEFINITIONS.get(StringName(result.get("choice_id", "")), {}) as Dictionary
			reward_copy = "%s INSTALLED · WATCH YOUR NEXT EGGS" % String(kit.get("short_name", "NEW KIT")).to_upper()
		_publish_status_copy(reward_copy, false, outcome + " Optional check-in lesson is available in the plan menu. Opening it spends nothing.")
		_save_campaign_checkpoint("first_clutch_reinvestment_resolved")
		_publish_web_diagnostic_state(reinvestment_snapshot)
		return
	if kind == &"directive":
		if _audio_feedback != null:
			var scenario := result.get("scenario", {}) as Dictionary
			if bool(result.get("scenario_fit", false)):
				_audio_feedback.play_scenario_fit(StringName(scenario.get("id", &"")))
			else:
				_audio_feedback.play_policy_stamp()
		var hold_for_first_clutch := _should_hold_first_clutch_orientation()
		_clock.set_speed(0 if hold_for_first_clutch else 1)
		if hold_for_first_clutch:
			var target_worker_id := int(_first_clutch.get("target_worker_id", -1))
			if bool(_first_clutch.get("inspected", false)) and target_worker_id >= 0:
				var worker := _first_clutch_worker_snapshot(_simulation.snapshot(), target_worker_id)
				var target_name := String(worker.get("name", "Mabel")).to_upper()
				var specialty := String(
					worker.get(
						"specialty_name",
						String(worker.get("specialty", "appeals")).replace("_", " "),
					)
				).to_upper()
				_ticker_label.text = "%s'S FIRST FILE. Route her to %s, then choose 1x when ready." % [
					target_name,
					specialty,
				]
				if _camera_controller != null:
					_camera_controller.focus_worker(target_worker_id)
			else:
				_ticker_label.text = "FIRST CLUTCH ORIENTATION. Inspect a hen, then choose 1x when ready."
	elif kind == &"incident":
		var pivot_mastery := result.get("case_pivot_mastery", {}) as Dictionary
		var completed_adaptive_casework := bool(pivot_mastery.get("complete", false))
		var case_pivot := result.get("case_pivot", {}) as Dictionary
		if _audio_feedback != null:
			if completed_adaptive_casework:
				# The snapshot-driven commendation refresh owns the one semantic cue.
				# Avoid layering the ordinary precedent stamp beneath it.
				pass
			elif not case_pivot.is_empty():
				_audio_feedback.play_case_pivot(int(pivot_mastery.get("mastered_count", 1)))
			elif not (result.get("filed_precedent", {}) as Dictionary).is_empty():
				_audio_feedback.play_precedent_filed()
			else:
				_audio_feedback.play_decision_resolved()
		_clock.set_speed(_decision_previous_speed if _resume_after_decision else 0)
	else:
		if _audio_feedback != null:
			_audio_feedback.play_policy_stamp()
		_clock.set_speed(0)
		_advance_after_closing_credit()
	_refresh_first_clutch_ui(_simulation.snapshot())
	_update_guidance(_simulation.snapshot())
	# First Clutch decisions remain hard recovery points. Ordinary production,
	# incident, directive, and closing-credit decisions are durable through the
	# bounded coordinator window; a lifecycle exit flushes that newest generation
	# synchronously. This lets adjacent review filings share one verified Web
	# transaction instead of freezing a frame for every modal step.
	if _first_clutch_tracking_active():
		_save_campaign_checkpoint("decision_resolved")
	else:
		_queue_campaign_checkpoint("decision_resolved")
	if not bool(_first_clutch.get("route_first_lesson", false)):
		_present_first_clutch_reinvestment()
	# Guidance and onboarding refreshes may publish their own next-step copy in
	# the same synchronous resolution chain. A filed precedent is the rarer,
	# durable consequence, so let its exact receipt own the final toast; the
	# ordinary ticker watcher records it in the existing Shift Record.
	var completed_case_mastery := bool(
		(result.get("case_pivot_mastery", {}) as Dictionary).get("complete", false)
	)
	if (
		not (result.get("filed_precedent", {}) as Dictionary).is_empty()
		and not completed_case_mastery
	):
		# Publish after clock restoration so later dialogue-pause bookkeeping sees
		# and preserves this higher-priority filed consequence.
		_publish_status_copy(outcome)


func _on_workday_completed(report: Dictionary) -> void:
	var previous_goal_status := String(_personal_goal.get("status", ""))
	_personal_goal = PersonalShiftGoal.finish(_personal_goal, report)
	if previous_goal_status == "active" and String(_personal_goal.get("status", "")) == "complete":
		_audio_feedback.play_decision_resolved()
		_office_atmosphere.pulse_strategy_reward()
		report["personal_goal_result"] = "PERSONAL BEST · " + PersonalShiftGoal.label(_personal_goal)
	_finish_next_moment("NEXT MOMENT REACHED  ·  SHIFT REVIEW READY", true)
	_clock.set_speed(0)
	var filed_report := report.duplicate(true)
	if not filed_report.has("routing_momentum"):
		filed_report["routing_momentum"] = _simulation.routing_momentum_snapshot()
	var routing_review := _routing_review_receipt(filed_report, _last_workday_report)
	if not routing_review.is_empty():
		filed_report["routing_review"] = routing_review
	report = filed_report
	_last_workday_report = report.duplicate(true)
	_queue_character_dialogue(CharacterDialogueCatalogScript.shift_review_beat(report))
	_queue_character_dialogues(
		CharacterDialogueCatalogScript.beats_for_internship_transitions(report)
	)
	_queue_campus_portfolio_progress_reveals(report)
	_first_clutch_prepare_for_shift_boundary()
	# Art captures close authored shifts through the real simulation so their
	# Gallery evidence is canonical. They are not campaign playthroughs, however,
	# and the staged late-game day is intentionally outside First Clutch's range.
	# Keep the capture from trying to file that unrelated probation record.
	if _is_capture_launch():
		pass
	elif _campaign_senior_roost and _senior_roost_state != null:
		var senior_result: Dictionary = _senior_roost_state.record_shift(report)
		if not bool(senior_result.get("accepted", false)):
			push_error("Senior Roost shift could not be recorded: %s" % str(senior_result.get("errors", [])))
	elif _campaign_state.outcome == CampaignStateScript.OUTCOME_IN_PROGRESS:
		var campaign_result := _campaign_state.record_shift(report, _simulation.snapshot())
		if not bool(campaign_result.get("accepted", false)):
			push_error("Probation shift could not be recorded: %s" % str(campaign_result.get("errors", [])))
	_campaign_review_stage = &"farmer"
	_save_campaign_checkpoint("workday_completed")
	_play_shift_highlight_replay(report)
	_show_farmer_review(report)
	_refresh_commendations_from_authority()


func _play_shift_highlight_replay(report: Dictionary) -> void:
	var highlight := report.get("hen_highlight", {}) as Dictionary
	var replay := highlight.get("highlight_replay", {}) as Dictionary
	var worker_id := int(highlight.get("worker_id", -1))
	if replay.is_empty() or worker_id < 0:
		return
	var worker_view := _worker_views.get(worker_id) as ChickenView
	if worker_view == null:
		return
	var label := "%s  ·  %d EGGS" % [
		String(highlight.get("worker_name", "HEN")).to_upper(),
		int(highlight.get("eggs", 0)),
	]
	if _camera_controller != null:
		_camera_controller.show_event_focus(
			worker_view.global_position + Vector3.UP * 0.82,
			label,
			float(replay.get("duration_seconds", 3.0)),
		)
	worker_view.play_short_bark("MY SHIFT!", &"team")
	if _office_atmosphere != null:
		_office_atmosphere.pulse_strategy_reward()


func _on_review_replay_highlight_pressed() -> void:
	if _last_workday_report.is_empty() or _day_review_scrim == null:
		return
	_day_review_scrim.visible = false
	_refresh_floor_input_context()
	_play_shift_highlight_replay(_last_workday_report)
	_publish_status_copy("REPLAYING THE SHIFT'S HEN HIGHLIGHT.", false)
	await get_tree().create_timer(2.4).timeout
	if (
		_simulation != null
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW
		and not _blocking_management_surface_open()
	):
		_day_review_scrim.visible = true
		_refresh_floor_input_context()
		if _review_replay_button != null:
			_review_replay_button.grab_focus()


func _on_review_remix_pressed() -> void:
	if _review_story == null:
		return
	var alternatives := PersonalShiftGoal.choices(_last_workday_report)
	var current_index := alternatives.find(_personal_goal_offer)
	_personal_goal_offer = alternatives[(current_index + 1) % alternatives.size()]
	_personal_goal_button.text = "GOAL ACCEPTED · CANCEL" if _personal_goal == _personal_goal_offer else "TRY NEXT SHIFT · " + PersonalShiftGoal.label(_personal_goal_offer)
	var idea := PersonalShiftGoal.strategy(_personal_goal_offer)
	_review_next_hint.text = _review_handoff_hint(String(idea.get("copy", "NEXT IDEA")))
	_review_next_hint.accessibility_name = _review_next_hint.text + ". Preview only. Accept the goal separately."
	_review_story.set_meta("remix_strategy_id", String(idea.get("id", "")))
	if _review_remix_button != null:
		_review_remix_button.text = "OTHER GOAL"
		_review_remix_button.tooltip_text = "Browse another goal. %s\nPreview only; accept separately." % String(idea.get("copy", "NEXT IDEA"))
		_review_remix_button.set_meta("preview_only", true)
		_review_remix_button.set_meta("strategy_id", String(idea.get("id", "")))
	_publish_web_diagnostic_state(_simulation.snapshot())
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()


func _on_review_requisitions_pressed() -> void:
	_flockwatch_restore_farmer_review = true
	_day_review_scrim.visible = false
	_open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	_refresh_floor_input_context()
	var snapshot := _simulation.snapshot()
	_apply_review_progression_action(snapshot)
	_update_guidance(snapshot)
	_ticker_label.text = "Feed Fund purchases are permanent. Costs rise with each approved level."


func _on_review_capital_blueprint_pressed() -> void:
	_open_capital_blueprint(true, false)


func _on_capital_blueprint_requested() -> void:
	_open_capital_blueprint(false, _flockwatch_open)


func _open_capital_blueprint(
	restore_review: bool = false,
	restore_flockwatch: bool = false,
) -> void:
	_build_capital_planning_surfaces()
	var restore_focus := get_viewport().gui_get_focus_owner()
	if restore_focus == null:
		restore_focus = _flockwatch_toggle
	_begin_capital_modal_hold()
	_capital_blueprint_restore_review = restore_review
	_capital_blueprint_restore_flockwatch = restore_flockwatch
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	if _commissioning_reveal_ui != null:
		_commissioning_reveal_ui.call("hide_reveal")
	if _campus_portfolio_reveal_ui != null:
		_campus_portfolio_reveal_ui.call("hide_reveal")
	_clear_campus_portfolio_reveal_target()
	_capital_blueprint_ui.call("set_restore_focus", restore_focus)
	_capital_blueprint_ui.call("show_blueprint", _simulation.snapshot())
	_set_capital_modal_interaction(true)
	_ticker_label.text = "CAPITAL BLUEPRINT OPEN. Compare permanent rooms, obligations, and unlock gates."
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_capital_blueprint_close_requested() -> void:
	# Restore the originating surface first so CapitalBlueprintUI can verify that
	# its recorded focus target is visible before deferring grab_focus(). Both
	# operations complete in this input turn, so the office is never exposed.
	_restore_capital_origin()
	if (
		_capital_blueprint_ui != null
		and bool(_capital_blueprint_ui.call("is_open"))
	):
		_capital_blueprint_ui.call("hide_blueprint", true)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_capital_blueprint_preview_requested(facility_id: StringName) -> void:
	var focus := _facility_focus_file(facility_id)
	if focus.is_empty() or _camera_controller == null:
		return
	_camera_controller.focus_point(
		focus.get("point", EXPANDED_OVERVIEW_TARGET) as Vector3,
		String(focus.get("label", "CAPITAL PARCEL")),
		0.35,
		float(focus.get("size", 11.5)),
	)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_capital_blueprint_pin_requested(facility_id: StringName) -> void:
	var result := _simulation.pin_capital_plan(facility_id)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"CAPITAL PLAN",
			"REVIEW FACILITY",
			String(result.get("reason", "The selected facility could not be pinned.")),
			"Capital plan",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"capital_plan")
		return
	var snapshot := _simulation.snapshot()
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("apply_snapshot", snapshot)
	if _staffing_ui != null:
		_staffing_ui.apply_snapshot(snapshot)
	_ticker_label.text = "CAPITAL PLAN PINNED. Flockwatch will keep this parcel visible."
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	_save_campaign_checkpoint("capital_plan_pinned_%s" % String(facility_id))


func _on_economic_watch_requested(watch_id: StringName) -> void:
	var result := _simulation.pin_economic_watch(watch_id)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"WATCH",
			"REVIEW METRIC",
			String(result.get(
				"reason",
				"The selected management metric could not be pinned.",
			)),
			"Management watch",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"economic_watch")
		return
	var watch := (
		_simulation.economic_briefing_snapshot().get("management_watch", {})
		as Dictionary
	).get("selected", {}) as Dictionary
	_ticker_label.text = "MANAGEMENT WATCH PINNED / %s. %s" % [
		String(watch.get("label", watch_id)).to_upper(),
		String(watch.get("status_label", "FILED")).to_upper(),
	]
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_save_campaign_checkpoint("economic_watch_pinned_%s" % String(watch_id))


func _on_economic_watch_open_requested(page_id: StringName) -> void:
	_open_flockwatch_page(page_id)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_capital_blueprint_purchase_requested(facility_id: StringName) -> void:
	_on_facility_purchase_requested(facility_id)


func _on_campus_expansion_requested() -> void:
	_build_capital_planning_surfaces()
	_begin_capital_modal_hold()
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("hide_blueprint", false)
	if _commissioning_reveal_ui != null:
		_commissioning_reveal_ui.call("hide_reveal")
	if _campus_portfolio_reveal_ui != null:
		_campus_portfolio_reveal_ui.call("hide_reveal")
	_clear_campus_portfolio_reveal_target()
	var restore_button: Control = null
	if _capital_blueprint_ui != null:
		restore_button = _capital_blueprint_ui.find_child(
			"CapitalBlueprintCampusExpansionButton", true, false
		) as Control
	_campus_portfolio_ui.call("set_restore_focus", restore_button)
	var presented_pending_reveal := _present_pending_campus_portfolio_reveal()
	if not presented_pending_reveal:
		_campus_portfolio_ui.call("show_portfolio", _simulation.snapshot())
	_set_capital_modal_interaction(true)
	if _camera_controller != null and not presented_pending_reveal:
		_camera_controller.focus_point(CAMPUS_PORTFOLIO_FOCUS, "CAMPUS PORTFOLIO", 0.35, 19.5)
	if not presented_pending_reveal:
		_ticker_label.text = "CAMPUS PORTFOLIO OPEN. Compare three deeds, four modules, contractor capacity, utilities, and named campus duty."
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campus_portfolio_close_requested() -> void:
	if _campus_portfolio_ui != null:
		_campus_portfolio_ui.call("hide_portfolio", false)
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("show_blueprint", _simulation.snapshot())
	_set_capital_modal_interaction(true)
	if _camera_controller != null:
		_camera_controller.show_overview()
	_ticker_label.text = "CAPITAL BLUEPRINT OPEN. The campus portfolio remains filed with every permanent project."
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campus_portfolio_north_details_requested() -> void:
	if _campus_portfolio_ui == null or _campus_expansion_ui == null:
		return
	_campus_expansion_restore_portfolio = true
	var restore_button := _campus_portfolio_ui.find_child(
		"CampusPortfolioNorthMeadowDetailsButton",
		true,
		false,
	) as Control
	_campus_portfolio_ui.call("hide_portfolio", false)
	_campus_expansion_ui.call("set_restore_focus", restore_button)
	_campus_expansion_ui.call("show_planner", _simulation.snapshot())
	_set_capital_modal_interaction(true)
	if _camera_controller != null:
		_camera_controller.focus_point(NORTH_MEADOW_FOCUS, "NORTH MEADOW", 0.35, 13.5)
	_ticker_label.text = "NORTH MEADOW DETAILS OPEN. File the shared routes, power trunk, cold loop, and routing pod."
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campus_expansion_close_requested() -> void:
	if (
		_campus_expansion_ui != null
		and bool(_campus_expansion_ui.call("is_open"))
	):
		_campus_expansion_ui.call("hide_planner", false)
	if _campus_expansion_restore_portfolio:
		_campus_expansion_restore_portfolio = false
		if _campus_portfolio_ui != null:
			_campus_portfolio_ui.call("show_portfolio", _simulation.snapshot())
		_set_capital_modal_interaction(true)
		if _camera_controller != null:
			_camera_controller.focus_point(CAMPUS_PORTFOLIO_FOCUS, "CAMPUS PORTFOLIO", 0.35, 19.5)
		_ticker_label.text = "CAMPUS PORTFOLIO OPEN. North Meadow utilities now feed every filed parcel."
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("show_blueprint", _simulation.snapshot())
	_set_capital_modal_interaction(true)
	if _camera_controller != null:
		_camera_controller.show_overview()
	_ticker_label.text = "CAPITAL BLUEPRINT OPEN. North Meadow remains filed with the permanent campus plan."
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campus_portfolio_deed_requested(parcel_id: StringName) -> void:
	_resolve_campus_portfolio_action(
		_simulation.purchase_campus_portfolio_deed(parcel_id),
		"campus_portfolio_deed_%s" % String(parcel_id),
		parcel_id,
	)


func _on_campus_portfolio_project_requested(
	module_id: StringName,
	pad_id: StringName,
) -> void:
	var parcel_id := (
		&"creekside_yard" if String(pad_id).begins_with("creekside") else &"orchard_row"
	)
	_resolve_campus_portfolio_action(
		_simulation.authorize_campus_portfolio_project(module_id, pad_id),
		"campus_portfolio_project_%s_%s" % [String(module_id), String(pad_id)],
		parcel_id,
	)


func _on_campus_portfolio_staff_assignment_requested(
	module_id: StringName,
	worker_id: Variant,
) -> void:
	_resolve_campus_portfolio_action(
		_simulation.assign_campus_portfolio_worker(module_id, int(worker_id)),
		"campus_portfolio_staff_%s_%d" % [String(module_id), int(worker_id)],
		_campus_portfolio_module_parcel(module_id),
	)


func _on_campus_portfolio_staff_unassignment_requested(module_id: StringName) -> void:
	_resolve_campus_portfolio_action(
		_simulation.unassign_campus_portfolio_worker(module_id),
		"campus_portfolio_unstaff_%s" % String(module_id),
		_campus_portfolio_module_parcel(module_id),
	)


func _campus_portfolio_module_parcel(module_id: StringName) -> StringName:
	for module_value: Variant in _simulation.campus_portfolio_snapshot().get("modules", []) as Array:
		if module_value is Dictionary and StringName(String((module_value as Dictionary).get("id", ""))) == module_id:
			return StringName(String((module_value as Dictionary).get("parcel_id", "")))
	return &""


func _campus_portfolio_worker_posts(snapshot: Dictionary) -> Dictionary[int, Dictionary]:
	var result: Dictionary[int, Dictionary] = {}
	var projection_value: Variant = snapshot.get("campus_portfolio", {})
	if not projection_value is Dictionary:
		return result
	for module_value: Variant in (projection_value as Dictionary).get("modules", []) as Array:
		if not module_value is Dictionary:
			continue
		var module := module_value as Dictionary
		var worker_id := int(module.get("worker_id", -1))
		var module_id := StringName(String(module.get("id", "")))
		var pad_id := StringName(String(module.get("pad_id", "")))
		if (
			worker_id < 0
			or module_id == &""
			or pad_id == &""
			or not bool(module.get("installed", false))
			or not campus_duty_position(pad_id).is_finite()
		):
			continue
		result[worker_id] = {
			"module_id": module_id,
			"pad_id": pad_id,
		}
	return result


func _sync_campus_worker_duties(snapshot: Dictionary) -> void:
	var desired := _campus_portfolio_worker_posts(snapshot)
	for worker_id_value: Variant in _campus_worker_assignments.keys().duplicate():
		var worker_id := int(worker_id_value)
		var desired_post: Dictionary = desired.get(worker_id, {})
		var desired_module := StringName(String(desired_post.get("module_id", "")))
		var desired_pad := StringName(String(desired_post.get("pad_id", "")))
		if (
			desired_module == _campus_worker_assignments.get(worker_id, &"")
			and desired_pad == _campus_worker_pads.get(worker_id, &"")
		):
			continue
		var old_pad: StringName = _campus_worker_pads.get(worker_id, &"")
		var view := _worker_views.get(worker_id) as ChickenView
		if view != null and is_instance_valid(view) and old_pad != &"":
			view.return_from_campus_duty(campus_duty_return_route(view.desk_index, old_pad))
		_campus_worker_assignments.erase(worker_id)
		_campus_worker_pads.erase(worker_id)

	for worker_id: int in desired:
		var post: Dictionary = desired[worker_id]
		var module_id := StringName(String(post.get("module_id", "")))
		var pad_id := StringName(String(post.get("pad_id", "")))
		var view := _worker_views.get(worker_id) as ChickenView
		if view == null or not is_instance_valid(view):
			continue
		if (
			_campus_worker_assignments.get(worker_id, &"") == module_id
			and _campus_worker_pads.get(worker_id, &"") == pad_id
			and view.has_campus_duty_assignment()
		):
			continue
		var outbound := campus_duty_outbound_route(view.desk_index, pad_id)
		if outbound.is_empty():
			continue
		_campus_worker_assignments[worker_id] = module_id
		_campus_worker_pads[worker_id] = pad_id
		view.assign_campus_duty(
			outbound,
			campus_duty_position(pad_id),
			campus_duty_face_point(pad_id),
		)


func _resolve_campus_portfolio_action(
	result: Dictionary,
	checkpoint_reason: String,
	parcel_id: StringName,
) -> void:
	var snapshot := _simulation.snapshot()
	if (
		_campus_portfolio_ui != null
		and bool(_campus_portfolio_ui.call("is_open"))
	):
		_campus_portfolio_ui.call("apply_snapshot", snapshot)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"CAMPUS FILE",
			"REVIEW PROJECT",
			String(result.get(
				"reason",
				"Review the parcel, project dependencies, and available campus duty.",
			)),
			"Campus portfolio file",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"campus_portfolio")
		_publish_web_diagnostic_state(snapshot)
		return
	_ticker_label.text = String(result.get("outcome", "CAMPUS PORTFOLIO FILE AUTHORIZED."))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	var receipt_value: Variant = result.get("receipt", {})
	var receipt := receipt_value as Dictionary if receipt_value is Dictionary else {}
	for started_value: Variant in result.get("started", []) as Array:
		if started_value is Dictionary:
			_enqueue_campus_portfolio_progress_reveal(started_value as Dictionary)
	if not receipt.is_empty():
		if _campus_portfolio_ui != null:
			_campus_portfolio_ui.call("hide_portfolio", false)
		_show_campus_portfolio_reveal(receipt, result, snapshot)
	elif _camera_controller != null:
		var fallback_focus := ORCHARD_ROW_FOCUS if parcel_id == &"orchard_row" else CREEKSIDE_YARD_FOCUS
		_camera_controller.focus_point(fallback_focus, "CAMPUS FILE ALREADY CURRENT", 0.30, 14.5)
	_save_campaign_checkpoint(checkpoint_reason)
	_publish_web_diagnostic_state(snapshot)


func _queue_campus_portfolio_progress_reveals(report: Dictionary) -> void:
	var progress_value: Variant = report.get("campus_portfolio_progress", {})
	if not progress_value is Dictionary:
		return
	var progress := progress_value as Dictionary
	# Completions are the strongest day-boundary result and should be the first
	# thing the player sees on returning to campus planning. A newly mobilized
	# queued project follows it without interrupting the Farmer Review.
	for completed_value: Variant in progress.get("completed", []) as Array:
		if completed_value is Dictionary:
			_enqueue_campus_portfolio_progress_reveal(completed_value as Dictionary)
	for started_value: Variant in progress.get("started", []) as Array:
		if started_value is Dictionary:
			_enqueue_campus_portfolio_progress_reveal(started_value as Dictionary)


func _enqueue_campus_portfolio_progress_reveal(progress_record: Dictionary) -> void:
	var receipt_value: Variant = progress_record.get("receipt", progress_record)
	if not receipt_value is Dictionary:
		return
	var receipt := (receipt_value as Dictionary).duplicate(true)
	if receipt.is_empty():
		return
	var receipt_id := int(receipt.get("receipt_id", 0))
	var project_id := int(receipt.get("project_id", 0))
	var action_id := StringName(String(receipt.get("action_id", "")))
	for pending: Dictionary in _pending_campus_portfolio_reveals:
		var pending_receipt := pending.get("receipt", {}) as Dictionary
		if receipt_id > 0 and int(pending_receipt.get("receipt_id", 0)) == receipt_id:
			return
	if action_id == &"complete_project" and project_id > 0:
		for pending_index in range(_pending_campus_portfolio_reveals.size() - 1, -1, -1):
			var pending_receipt := (
				_pending_campus_portfolio_reveals[pending_index].get("receipt", {}) as Dictionary
			)
			if (
				int(pending_receipt.get("project_id", 0)) == project_id
				and StringName(String(pending_receipt.get("action_id", ""))) == &"start_project"
			):
				_pending_campus_portfolio_reveals.remove_at(pending_index)
	_pending_campus_portfolio_reveals.append({
		"receipt": receipt,
		"progress": progress_record.duplicate(true),
	})


func _present_pending_campus_portfolio_reveal() -> bool:
	if _pending_campus_portfolio_reveals.is_empty():
		return false
	var envelope := _pending_campus_portfolio_reveals.pop_front() as Dictionary
	var receipt_value: Variant = envelope.get("receipt", {})
	if not receipt_value is Dictionary or (receipt_value as Dictionary).is_empty():
		return _present_pending_campus_portfolio_reveal()
	_show_campus_portfolio_reveal(
		receipt_value as Dictionary,
		envelope.get("progress", {}) as Dictionary,
		_simulation.snapshot(),
	)
	return true


func _show_campus_portfolio_reveal(
		receipt: Dictionary,
		result: Dictionary,
		snapshot: Dictionary,
) -> void:
	if receipt.is_empty():
		return
	_build_capital_planning_surfaces()
	# A campus receipt is the new blocking authority. Retire any decision-result
	# cards before they can float above the exposed world and compete with the
	# parcel marker, while retaining their semantic history in the archived receipt.
	_yield_transient_feedback_to(&"campus_portfolio_reveal")
	_begin_capital_modal_hold()
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("hide_blueprint", false)
	if _campus_portfolio_ui != null:
		_campus_portfolio_ui.call("hide_portfolio", false)
	if _commissioning_reveal_ui != null:
		_commissioning_reveal_ui.call("hide_reveal")
	var context := _campus_portfolio_reveal_context(receipt, result, snapshot)
	_focus_campus_portfolio_reveal(receipt, context)
	_campus_portfolio_reveal_ui.call(
		"show_reveal",
		receipt,
		context,
		_prefers_reduced_motion(),
	)
	_set_capital_modal_interaction(true)
	_ticker_label.text = String(receipt.get(
		"outcome",
		"CAMPUS RECORD FILED. Inspect the marked world result, then continue or return to the portfolio.",
	))


func _campus_portfolio_reveal_context(
		receipt: Dictionary,
		result: Dictionary,
		snapshot: Dictionary,
) -> Dictionary:
	var portfolio_value: Variant = snapshot.get("campus_portfolio", {})
	var portfolio := portfolio_value as Dictionary if portfolio_value is Dictionary else {}
	var parcel_id := StringName(String(receipt.get("parcel_id", "")))
	var module_id := StringName(String(receipt.get("module_id", "")))
	var pad_id := StringName(String(receipt.get("pad_id", "")))
	var worker_id := int(receipt.get("worker_id", -1))
	var parcel: Dictionary = {}
	var pad: Dictionary = {}
	for parcel_value: Variant in portfolio.get("parcels", []) as Array:
		if not parcel_value is Dictionary:
			continue
		var candidate := parcel_value as Dictionary
		if StringName(String(candidate.get("id", ""))) != parcel_id:
			continue
		parcel = candidate
		for pad_value: Variant in candidate.get("pads", []) as Array:
			if (
				pad_value is Dictionary
				and StringName(String((pad_value as Dictionary).get("id", ""))) == pad_id
			):
				pad = pad_value as Dictionary
				break
		break
	var module: Dictionary = {}
	for module_value: Variant in portfolio.get("modules", []) as Array:
		if (
			module_value is Dictionary
			and StringName(String((module_value as Dictionary).get("id", ""))) == module_id
		):
			module = module_value as Dictionary
			break
	var worker_name := String(module.get("worker_name", "")).strip_edges()
	if worker_id >= 0:
		for worker_value: Variant in snapshot.get("workers", []) as Array:
			if worker_value is Dictionary and int((worker_value as Dictionary).get("id", -1)) == worker_id:
				worker_name = String((worker_value as Dictionary).get("name", worker_name))
				break
		if worker_name.is_empty():
			for assignment_value: Variant in portfolio.get("workers", []) as Array:
				if (
					assignment_value is Dictionary
					and int((assignment_value as Dictionary).get("worker_id", -1)) == worker_id
				):
					worker_name = String((assignment_value as Dictionary).get("worker_name", ""))
					break
	var effect_lines: Array = []
	if not module.is_empty():
		effect_lines = (module.get("benefits", []) as Array).duplicate(true)
	elif not parcel.is_empty():
		effect_lines = (parcel.get("benefit_lines", []) as Array).duplicate(true)
	return {
		"parcel_name": String(parcel.get("name", _campus_portfolio_title(parcel_id))),
		"module_name": String(module.get("name", _campus_portfolio_title(module_id))),
		"pad_name": String(pad.get("name", _campus_portfolio_title(pad_id))),
		"worker_name": worker_name,
		"effect_lines": effect_lines,
		"outcome": String(receipt.get("outcome", result.get("outcome", "Campus receipt filed."))),
		"has_fund_before": result.has("fund_before_cents") and result.has("fund_after_cents"),
		"fund_before_cents": int(result.get("fund_before_cents", 0)),
		"fund_after_cents": int(result.get("fund_after_cents", 0)),
		"has_spendable_after": result.has("projected_spendable_fund_cents"),
		"spendable_after_cents": int(result.get("projected_spendable_fund_cents", 0)),
	}


func _campus_portfolio_title(id: StringName) -> String:
	return String(id).replace("_", " ").capitalize() if id != &"" else ""


func _focus_campus_portfolio_reveal(receipt: Dictionary, context: Dictionary) -> void:
	var parcel_id := StringName(String(receipt.get("parcel_id", "")))
	var pad_id := StringName(String(receipt.get("pad_id", "")))
	var action_id := StringName(String(receipt.get("action_id", "")))
	var footprint := (
		CampusPortfolioVisualScript.declared_pad_footprint(pad_id)
		if pad_id != &"" else
		CampusPortfolioVisualScript.declared_footprint(parcel_id)
	)
	var visual: Node3D = null
	if _office_storytelling != null:
		visual = _office_storytelling.campus_portfolio_visual
	if visual == null:
		visual = find_child("CampusPortfolioVisual", true, false) as Node3D
	if visual != null and visual.has_method("show_reveal_target"):
		visual.call("show_reveal_target", parcel_id, pad_id, action_id)
	if _camera_controller == null or footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
		return
	var center := footprint.get_center()
	var label_parts: Array[String] = []
	var module_name := String(context.get("module_name", "")).strip_edges()
	var pad_name := String(context.get("pad_name", "")).strip_edges()
	var parcel_name := String(context.get("parcel_name", "CAMPUS PARCEL")).strip_edges()
	if not module_name.is_empty():
		label_parts.append(module_name.to_upper())
	if not pad_name.is_empty():
		label_parts.append(pad_name.to_upper())
	if label_parts.is_empty():
		label_parts.append(parcel_name.to_upper())
	_camera_controller.focus_point(
		Vector3(center.x, 1.10, center.y),
		" / ".join(label_parts),
		0.32,
		clampf(maxf(footprint.size.x, footprint.size.y) * 1.38, 10.5, 16.5),
	)


func _clear_campus_portfolio_reveal_target() -> void:
	var visual: Node3D = null
	if _office_storytelling != null:
		visual = _office_storytelling.campus_portfolio_visual
	if visual == null:
		visual = find_child("CampusPortfolioVisual", true, false) as Node3D
	if visual != null and visual.has_method("hide_reveal_target"):
		visual.call("hide_reveal_target")


func _on_campus_portfolio_reveal_continue_requested() -> void:
	if _campus_portfolio_reveal_ui != null:
		_campus_portfolio_reveal_ui.call("hide_reveal")
	_clear_campus_portfolio_reveal_target()
	if _present_pending_campus_portfolio_reveal():
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	_restore_capital_origin()
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campus_portfolio_reveal_return_requested() -> void:
	if _campus_portfolio_reveal_ui != null:
		_campus_portfolio_reveal_ui.call("hide_reveal")
	_clear_campus_portfolio_reveal_target()
	if _campus_portfolio_ui != null:
		_campus_portfolio_ui.call("show_portfolio", _simulation.snapshot())
	_set_capital_modal_interaction(true)
	_ticker_label.text = "CAMPUS PORTFOLIO OPEN. The filed result remains permanent in the live campus and receipt archive."
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campus_parcel_purchase_requested(parcel_id: StringName) -> void:
	_resolve_campus_authorization(
		_simulation.purchase_campus_parcel(parcel_id),
		"campus_parcel_%s" % String(parcel_id),
	)


func _on_campus_service_connect_requested(service_id: StringName) -> void:
	_resolve_campus_authorization(
		_simulation.commission_campus_service(service_id),
		"campus_service_%s" % String(service_id),
	)


func _on_campus_pod_place_requested(socket_id: StringName) -> void:
	_resolve_campus_authorization(
		_simulation.place_campus_module(CAMPUS_ROUTING_POD_ID, socket_id),
		"campus_pod_place_%s" % String(socket_id),
	)


func _on_campus_pod_relocate_requested(
		from_socket_id: StringName,
		to_socket_id: StringName,
) -> void:
	var campus := _simulation.campus_expansion_snapshot()
	if StringName(String(campus.get("pod_socket_id", ""))) != from_socket_id:
		_publish_economic_action_hold(
			"POD MOVE",
			"REFRESH SOCKET",
			"The placement file changed. Review the current Egg Routing Pod socket before moving it.",
			"Egg Routing Pod move",
		)
		if _campus_expansion_ui != null:
			_campus_expansion_ui.call("set_snapshot", _simulation.snapshot())
		return
	_resolve_campus_authorization(
		_simulation.relocate_campus_module(CAMPUS_ROUTING_POD_ID, to_socket_id),
		"campus_pod_relocate_%s_to_%s" % [String(from_socket_id), String(to_socket_id)],
	)


func _resolve_campus_authorization(result: Dictionary, checkpoint_reason: String) -> void:
	var snapshot := _simulation.snapshot()
	if _campus_expansion_ui != null:
		_campus_expansion_ui.call("set_snapshot", snapshot)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"MEADOW FILE",
			"REVIEW GATE",
			String(result.get(
				"reason",
				"Review North Meadow ownership, services, capacity, and placement terms.",
			)),
			"North Meadow filing",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"campus_authorization")
		_publish_web_diagnostic_state(snapshot)
		return
	_ticker_label.text = String(result.get("outcome", "NORTH MEADOW FILING COMMISSIONED."))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	if _camera_controller != null:
		_camera_controller.focus_point(NORTH_MEADOW_FOCUS, "NORTH MEADOW FILED", 0.30, 13.5)
	_save_campaign_checkpoint(checkpoint_reason)
	_publish_web_diagnostic_state(snapshot)


func _begin_capital_modal_hold() -> void:
	if _capital_modal_holds_speed:
		return
	_capital_modal_previous_speed = _clock.speed_index if _clock != null else 0
	_capital_modal_holds_speed = true
	if _clock != null:
		_clock.set_speed(0)


func _set_capital_modal_interaction(is_open: bool) -> void:
	# Modal visibility is authoritative; this parameter remains for API
	# compatibility with the existing capital return paths.
	_refresh_floor_input_context()


func _restore_capital_origin() -> void:
	var restore_review := _capital_blueprint_restore_review
	var restore_flockwatch := _capital_blueprint_restore_flockwatch
	_capital_blueprint_restore_review = false
	_capital_blueprint_restore_flockwatch = false
	if _camera_controller != null:
		_camera_controller.show_overview()
	if restore_review and _day_review_scrim != null:
		_day_review_scrim.visible = true
		_set_capital_modal_interaction(true)
	elif restore_flockwatch:
		_set_capital_modal_interaction(false)
		_set_flockwatch_open(true)
	else:
		_set_capital_modal_interaction(false)
	if _capital_modal_holds_speed:
		var can_restore_speed := (
			not restore_review
			and (_campaign_ui == null or not _campaign_ui.is_modal_open())
			and (_decision_host == null or not _decision_host.visible)
			and (_day_review_scrim == null or not _day_review_scrim.visible)
		)
		if can_restore_speed and _clock != null:
			_clock.set_speed(_capital_modal_previous_speed)
		_capital_modal_holds_speed = false


func _on_commissioning_continue_requested() -> void:
	if _commissioning_reveal_ui != null:
		_commissioning_reveal_ui.call("hide_reveal")
	_restore_capital_origin()
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_commissioning_return_to_blueprint_requested() -> void:
	if _commissioning_reveal_ui != null:
		_commissioning_reveal_ui.call("hide_reveal")
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("show_blueprint", _simulation.snapshot())
	_set_capital_modal_interaction(true)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _presentation_tween(bound_node: Node = null) -> Tween:
	var tween := create_tween()
	if bound_node != null:
		tween.bind_node(bound_node)
	tween.set_speed_scale(_animation_speed_multiplier)
	return tween


func _prefers_reduced_motion() -> bool:
	var motion_mode := String(_player_preferences.get("motion_mode", "system"))
	if motion_mode == "reduced":
		return true
	if motion_mode == "full":
		return false
	if not OS.has_feature("web"):
		return false
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return false
	# JavaScriptObject.has_method() inspects methods on the Godot wrapper, not
	# properties on window, so it reports false for the browser's matchMedia API.
	# All supported browsers expose matchMedia; call the interface directly so
	# commissioning reveals actually honor the player's OS preference.
	var query: Variant = window.matchMedia("(prefers-reduced-motion: reduce)")
	return query != null and bool(query.matches)


func _on_begin_next_shift_pressed() -> void:
	_advance_from_farmer_review()


func _on_continue_directive_pressed() -> void:
	if _farmer_relations_gallery_offer_open():
		if not _skip_farmer_relations_gallery_campaign():
			return
	_advance_from_farmer_review()


func _advance_after_closing_credit() -> void:
	if _present_farmer_relations_gallery_review():
		return
	if _campaign_senior_roost:
		_show_senior_roost_report()
		return
	if _campaign_state.outcome != CampaignStateScript.OUTCOME_IN_PROGRESS:
		_show_campaign_final_review()
		return
	_campaign_review_stage = &"probation"
	_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
	_set_campaign_modal_open(true)
	_queue_campaign_checkpoint("probation_report")


func _farmer_relations_gallery_projection(snapshot: Dictionary = {}) -> Dictionary:
	var source := snapshot if not snapshot.is_empty() else _simulation.snapshot()
	var nested_value: Variant = source.get("farmer_relations_gallery", {})
	if nested_value is Dictionary and not (nested_value as Dictionary).is_empty():
		return (nested_value as Dictionary).duplicate(true)
	if _simulation.has_method("farmer_relations_gallery_snapshot"):
		var projection_value: Variant = _simulation.call("farmer_relations_gallery_snapshot")
		if projection_value is Dictionary:
			return (projection_value as Dictionary).duplicate(true)
	return {}


func _farmer_relations_gallery_offer_open(snapshot: Dictionary = {}) -> bool:
	var gallery := _farmer_relations_gallery_projection(snapshot)
	var status := StringName(String(gallery.get(
		"campaign_status",
		gallery.get("status", ""),
	)))
	return (
		int(gallery.get("level", 0)) > 0
		and bool(gallery.get("review_open", true))
		and status in [&"offer_open", &"open", &"ready"]
	)


func _present_farmer_relations_gallery_review() -> bool:
	var snapshot := _simulation.snapshot()
	if not _farmer_relations_gallery_offer_open(snapshot):
		return false
	_campaign_review_stage = &"credit"
	_clock.set_speed(0)
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	if _campaign_ui != null:
		_set_campaign_modal_open(false)
	_open_flockwatch_page(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
	_refresh_floor_input_context()
	_set_guidance(
		"CREDIT: PUBLISH A CAMPAIGN / OR SKIP",
		&"cash",
		"Closing credit filed: publish one Gallery campaign or continue to skip.",
		&"records",
	)
	_ticker_label.text = "FARMER RELATIONS GALLERY. One public campaign may be hung from this closed shift."
	_publish_web_diagnostic_state(snapshot)
	return true


func _skip_farmer_relations_gallery_campaign() -> bool:
	if not _simulation.has_method("skip_farmer_relations_campaign"):
		_publish_economic_action_hold(
			"GALLERY CLOSE",
			"REVIEW CAMPAIGN",
			"Skip authorization is unavailable. Review the public-campaign filing.",
			"Gallery closing file",
		)
		return false
	var result_value: Variant = _simulation.call("skip_farmer_relations_campaign")
	var result := result_value as Dictionary if result_value is Dictionary else {}
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"GALLERY CLOSE",
			"REVIEW CAMPAIGN",
			String(result.get(
				"reason",
				"The public-campaign skip is unavailable during this closing review.",
			)),
			"Gallery closing file",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"gallery_skip")
		return false
	var snapshot := _simulation.snapshot()
	_on_snapshot_changed(snapshot)
	_ticker_label.text = String(result.get(
		"outcome",
		"No public campaign was filed for this closed shift.",
	))
	_save_campaign_checkpoint("farmer_relations_campaign_skipped")
	_publish_web_diagnostic_state(snapshot)
	return true


func _on_dispatch_lane_requested(lane: StringName) -> void:
	if lane not in PeckworkRoutingUI.LANE_ORDER:
		return
	if _dispatch_lane == lane:
		_clear_dispatch_mode(true)
		_publish_status_copy("%s TRAY RETURNED TO INTAKE." % _dispatch_lane_label(lane), false)
		return
	_dispatch_file_preview = _simulation.dispatch_file_preview(lane)
	_dispatch_candidates = _simulation.dispatch_candidates(lane)
	if _dispatch_candidates.is_empty():
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		_publish_status_copy("NO EMPLOYED HEN CAN TAKE THIS TRAY.", false)
		return
	_dispatch_lane = lane
	_dispatch_recommended_worker_id = int(_dispatch_candidates[0].get("worker_id", -1))
	var recommended_name := String(_dispatch_candidates[0].get("worker_name", ""))
	_apply_dispatch_candidate_markers()
	var recommended_view := _worker_views.get(_dispatch_recommended_worker_id) as ChickenView
	if recommended_view != null:
		recommended_view.play_dispatch_recommendation_handoff(lane)
	if _routing_ui != null:
		_routing_ui.set_dispatch_state(
			_dispatch_lane,
			_dispatch_momentum_chain,
			recommended_name,
			_dispatch_reward_label,
			_dispatch_file_preview,
		)
	_publish_status_copy(
		"%s %s  •  PICK A HEN  •  %s IS THE BEST FIT"
		% [
			String(_dispatch_file_preview.get("symbol", "")),
			String(_dispatch_file_preview.get("label", _dispatch_lane_label(lane))),
			recommended_name.to_upper(),
		],
		false,
	)
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _dispatch_candidate_for(worker_id: int) -> Dictionary:
	for candidate in _dispatch_candidates:
		if int(candidate.get("worker_id", -1)) == worker_id:
			return candidate
	return {}


func _apply_dispatch_candidate_markers() -> void:
	for worker_id in _worker_views:
		var view := _worker_views.get(worker_id) as ChickenView
		if view == null:
			continue
		var candidate := _dispatch_candidate_for(int(worker_id))
		view.set_dispatch_candidate(
			not candidate.is_empty(),
			int(worker_id) == _dispatch_recommended_worker_id,
			_dispatch_lane,
			bool(candidate.get("specialty_match", false)),
			bool(candidate.get("ready", false)),
			candidate,
		)


func _on_dispatch_drag_started(lane: StringName) -> void:
	if lane != _dispatch_lane:
		_on_dispatch_lane_requested(lane)
	_publish_status_copy("DRAG %s FILE  •  DROP ON A HEN" % _dispatch_lane_label(lane), false)


func _on_dispatch_drag_released(lane: StringName, viewport_position: Vector2) -> void:
	if lane != _dispatch_lane:
		_clear_dispatch_mode(true)
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_clear_dispatch_mode(true)
		return
	var ray_from := camera.project_ray_origin(viewport_position)
	var ray_to := ray_from + camera.project_ray_normal(viewport_position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1 << 19)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var collider := hit.get("collider") as Node
	var worker_view: ChickenView
	if collider != null and collider.get_parent() is ChickenView:
		worker_view = collider.get_parent() as ChickenView
	if worker_view != null and _commit_dispatch(worker_view.worker_id):
		return
	_clear_dispatch_mode(true)
	_publish_status_copy("TRAY RETURNED  •  DROP ON A MARKED HEN", false)
	if _audio_feedback != null:
		_audio_feedback.play_denied(&"routing")


func _on_dispatch_drag_canceled(_lane: StringName) -> void:
	# A pointer release below the drag threshold is an ordinary tray click; the
	# Button's pressed signal remains the sole activation edge for that gesture.
	pass


func _clear_dispatch_mode(keep_momentum: bool = true) -> void:
	_dispatch_lane = &""
	_dispatch_candidates.clear()
	_dispatch_file_preview.clear()
	_dispatch_recommended_worker_id = -1
	if not keep_momentum:
		_dispatch_momentum_chain = 0
		_dispatch_reward_label = ""
	for view_value in _worker_views.values():
		var view := view_value as ChickenView
		if view != null:
			view.set_dispatch_candidate(false)
	if _routing_ui != null:
		_routing_ui.set_dispatch_state(&"", _dispatch_momentum_chain, "", _dispatch_reward_label, {})


func _on_routing_momentum_broken(receipt: Dictionary) -> void:
	var broken_chain := int(receipt.get("broken_chain", 0))
	if broken_chain <= 0:
		return
	if _routing_ui != null:
		_routing_ui.play_dispatch_break(receipt)
	if _audio_feedback != null:
		_audio_feedback.play_denied(&"routing_flow")
	# Poor-fit dispatch publishes after its valid route receipt below. Other
	# sources have no direct player action callback, so retain one compact toast
	# while the exact cause lives in the queue tooltip and accessibility name.
	if StringName(String(receipt.get("source", ""))) != &"poor_fit":
		_publish_status_copy("FLOW x%d  >  0  ·  NEXT FIT  x1" % broken_chain, false)
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _on_routing_momentum_recovered(receipt: Dictionary) -> void:
	if int(receipt.get("recovered_chain", 0)) != 1:
		return
	if _routing_ui != null:
		_routing_ui.play_dispatch_recovery(receipt)
	# The physical folder delivery and ordinary route status already acknowledge
	# this click. Keep recovery closure in the queue strip instead of stacking a
	# second toast or another sound over the same action.
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _commit_dispatch(worker_id: int) -> bool:
	if _dispatch_lane == &"":
		return false
	var candidate := _dispatch_candidate_for(worker_id)
	if candidate.is_empty():
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		return false
	var lane := _dispatch_lane
	var recommended := worker_id == _dispatch_recommended_worker_id
	var fit_tier := StringName(String(candidate.get("fit_tier", "risky")))
	var before_snapshot := _simulation.snapshot()
	var worker_before := _worker_record(before_snapshot, worker_id)
	var previous_lane := StringName(worker_before.get("assigned_lane", &""))
	var prior_undo := _routing_assignment_undo.duplicate(true)
	if not worker_before.is_empty() and previous_lane != lane:
		_routing_assignment_undo = {
			"day": int(before_snapshot.get("day", 0)),
			"worker_id": worker_id,
			"worker_name": String(worker_before.get("name", "HEN %d" % (worker_id + 1))),
			"previous_lane": previous_lane,
			"current_lane": lane,
		}
	var receipt := _simulation.dispatch_worker_to_lane(worker_id, lane)
	if not bool(receipt.get("accepted", false)):
		_routing_assignment_undo = prior_undo
		_publish_status_copy(String(receipt.get("reason", "ROUTING HELD.")), false)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		return false
	_dispatch_momentum_chain = int(receipt.get("momentum_chain", 0))
	var reward := receipt.get("reward", {}) as Dictionary
	var break_receipt := receipt.get("break", {}) as Dictionary
	var recovery_receipt := receipt.get("recovery", {}) as Dictionary
	var reward_id := StringName(String(reward.get("id", "")))
	_dispatch_reward_label = String(reward.get("label", ""))
	if _dispatch_reward_label.is_empty():
		var momentum := receipt.get("momentum", {}) as Dictionary
		if int(momentum.get("golden_charges", 0)) > 0:
			_dispatch_reward_label = (
				"* GOLD #%04d" % int(momentum.get("golden_target_claim_id", 0))
				if bool(momentum.get("golden_target_bound", false)) else
				"* GOLD READY"
			)
		elif int(momentum.get("peck_recharge_bank", 0)) > 0:
			_dispatch_reward_label = "PECK +1"
		elif bool(momentum.get("pace_active", false)):
			_dispatch_reward_label = "PACE +15%"
	var worker_name := String(candidate.get("worker_name", "HEN %d" % (worker_id + 1)))
	var worker_view := _worker_views.get(worker_id) as ChickenView
	if worker_view != null:
		worker_view.play_short_bark(
			"FLOW LINKED!" if recommended else "FLOW HELD." if fit_tier == &"safe" else "GAMBIT FILED.",
			&"success" if recommended else &"neutral" if fit_tier == &"safe" else &"risk",
		)
	_dispatch_last_receipt = receipt.duplicate(true)
	_last_cause_replay = {
		"available": true,
		"active": false,
		"replayed": false,
		"worker_id": worker_id,
		"worker_name": worker_name,
		"lane": String(lane),
		"file_label": String(_dispatch_file_preview.get("label", String(lane).replace("_", " ").to_upper())),
		"result_label": _dispatch_reward_label if not _dispatch_reward_label.is_empty() else ("BEST FIT" if recommended else "ROUTE FILED"),
		"path": ["FILE", "HEN", "RESULT"],
		"input": "H",
		"files_nothing": true,
		"presentation_only": true,
	}
	var delivery_started := false
	if _workstation_feedback != null:
		delivery_started = _workstation_feedback.play_dispatch_delivery(
			worker_id,
			lane,
			to_global(DISPATCH_INTAKE_SOURCE),
			recommended,
			_dispatch_momentum_chain,
			0.78,
			reward_id,
			reward,
		)
	if delivery_started and _management_presence != null:
		_management_presence.play_core_loop_sequence(
			&"route",
			reward_id if reward_id != &"" else &"filed",
		)
	_clear_dispatch_mode(true)
	if reward_id != &"":
		if (
			reward_id not in [&"team_lift", &"mastery_record"]
			and _routing_ui != null
			and _routing_ui.has_method("play_dispatch_reward")
		):
			_routing_ui.call("play_dispatch_reward", reward_id, _dispatch_momentum_chain, reward)
		if _audio_feedback != null:
			match reward_id:
				&"peck_recharge":
					# The physical folder landing owns this cue so the world burst,
					# charge meter, and sound refill at the same readable moment.
					pass
				&"golden_file":
					_audio_feedback.play_commendation()
				&"team_lift":
					# The folder landing owns the flock markers, compact receipt,
					# and audio cue so every channel resolves on one causal beat.
					pass
				&"mastery_record":
					# Like Team Lift, the physical record folder owns the beat.
					pass
				_:
					_audio_feedback.play_upgrade()
	if not break_receipt.is_empty():
		_publish_status_copy(
			"FLOW x%d  >  0  ·  NEXT FIT  x1" % int(break_receipt.get("broken_chain", 0)),
			false,
		)
	elif not recovery_receipt.is_empty():
		_publish_status_copy(
			"FIT LINKED  x1  ·  %s FROM %s" % [worker_name.to_upper(), _dispatch_lane_label(lane)],
			false,
		)
	else:
		var route_result_copy := (
			"FLOW +1 · FIT %d" % _dispatch_momentum_chain
			if recommended else
			"FLOW HELD" if fit_tier == &"safe" else "FLOW RESET"
		)
		var reward_copy := "  •  %s" % _dispatch_reward_label if not _dispatch_reward_label.is_empty() else ""
		var route_status_copy := "%s > %s  •  %s%s  •  NEXT FILE READY" % [
			worker_name.to_upper(),
			_dispatch_lane_label(lane),
			route_result_copy,
			reward_copy,
		]
		var route_accessible_copy := "%s route filed: %s to %s." % [
			"Best-fit flow" if recommended else "Safe hold" if fit_tier == &"safe" else "Risky gambit",
			worker_name,
			_dispatch_lane_label(lane).to_lower(),
		]
		if recommended:
			route_accessible_copy += " Best-fit streak %d." % _dispatch_momentum_chain
		if not _dispatch_reward_label.is_empty():
			route_accessible_copy += " Reward: %s." % _dispatch_reward_label
		route_accessible_copy += " The next file is ready."
		_publish_status_copy(route_status_copy, false)
		if _ticker_label != null and _ticker_label.text == route_status_copy:
			_ticker_label.tooltip_text = route_accessible_copy
			_ticker_label.accessibility_name = route_accessible_copy
	_first_clutch_record_routing(worker_id, lane)
	_dismiss_routing_return_cue(receipt, delivery_started)
	_save_campaign_checkpoint("routing_dispatch")
	_publish_web_diagnostic_state(_simulation.snapshot(true))
	return true


func _on_routing_reward_presented(
	_worker_id: int,
	reward: Dictionary,
	chain: int,
) -> void:
	var reward_id := StringName(String(reward.get("id", "")))
	_begin_payoff_breath()
	match reward_id:
		&"peck_recharge":
			var presented := (
				_routing_ui != null
				and _routing_ui.play_priority_peck_recharge(reward, chain)
			)
			if presented and _audio_feedback != null:
				_audio_feedback.play_attention_restored()
		&"team_lift":
			var authority_key := String(reward.get("authority_key", ""))
			if authority_key.is_empty():
				authority_key = "%d:%d" % [chain, int(reward.get("worker_id", -1))]
			if authority_key == _last_team_lift_authority_key:
				return
			_last_team_lift_authority_key = authority_key
			var presented_worker_ids: Array[int] = []
			for affected_value in reward.get("affected_workers", []):
				var affected := affected_value as Dictionary
				var affected_worker_id := int(affected.get("worker_id", -1))
				var affected_view := _worker_views.get(affected_worker_id) as ChickenView
				if affected_view == null or not is_instance_valid(affected_view):
					continue
				var worker_receipt := affected.duplicate(true)
				worker_receipt["authority_key"] = authority_key
				if affected_view.play_team_lift_feedback(worker_receipt):
					presented_worker_ids.append(affected_worker_id)
			_last_team_lift_presentation = {
				"authority_key": authority_key,
				"chain": chain,
				"presented_worker_ids": presented_worker_ids,
				"presented_count": presented_worker_ids.size(),
				"affected_count": int(reward.get("affected_count", 0)),
				"accessible_text": String(reward.get("accessible_text", "")),
			}
			if _routing_ui != null and _routing_ui.has_method("play_dispatch_reward"):
				_routing_ui.call("play_dispatch_reward", reward_id, chain, reward)
			if _audio_feedback != null and not presented_worker_ids.is_empty():
				_audio_feedback.play_commendation()
		&"mastery_record":
			var authority_key := String(reward.get("authority_key", ""))
			if authority_key.is_empty():
				authority_key = "%d:%d" % [chain, int(reward.get("worker_id", -1))]
			if authority_key == _last_routing_mastery_authority_key:
				return
			_last_routing_mastery_authority_key = authority_key
			_routing_mastery_presentation_serial += 1
			_last_routing_mastery_presentation = {
				"serial": _routing_mastery_presentation_serial,
				"authority_key": authority_key,
				"chain": chain,
				"worker_id": int(reward.get("worker_id", -1)),
				"record_before": int(reward.get("record_before", 0)),
				"record_after": int(reward.get("record_after", chain)),
				"accessible_text": String(reward.get("accessible_text", "")),
			}
			if _routing_ui != null and _routing_ui.has_method("play_dispatch_reward"):
				_routing_ui.call("play_dispatch_reward", reward_id, chain, reward)
			if _audio_feedback != null:
				_audio_feedback.play_commendation()
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _on_dispatch_landing_presented(
	worker_id: int,
	receipt: Dictionary,
) -> void:
	var linked_settlement := _accept_route_settlement_landing(worker_id, receipt)
	var released_on_landing := false
	if linked_settlement:
		released_on_landing = _release_deferred_settlement_feedback_if_ready()
	if not released_on_landing and _audio_feedback != null:
		_audio_feedback.play_dispatch_landing(bool(receipt.get("recommended", false)))
	if linked_settlement and not released_on_landing:
		# Another genuine attention owner can still delay the financial fan. Keep
		# the physical folder audible now and record that its later receipt release
		# must not claim to have replaced this cue.
		_settlement_feedback_route_handoff["physical_landing_cue_played"] = true
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _on_dispatch_work_started_presented(
	_worker_id: int,
	receipt: Dictionary,
) -> void:
	if _audio_feedback != null:
		_audio_feedback.play_dispatch_work_started(
			bool(receipt.get("recommended", false)),
		)
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _dispatch_lane_label(lane: StringName) -> String:
	match lane:
		&"nest_damage":
			return "NEST"
		&"predator_loss":
			return "PREDATOR"
		&"appeals":
			return "APPEALS"
	return String(lane).replace("_", " ").to_upper()


func _on_worker_assignment_requested(worker_id: int, lane: StringName) -> void:
	var before_snapshot := _simulation.snapshot()
	var worker_before := _worker_record(before_snapshot, worker_id)
	var previous_lane := StringName(worker_before.get("assigned_lane", &""))
	# Induction deliberately holds the clock. Its one featured assignment must
	# file now, not disappear into a pause-plan the player has not learned yet.
	var induction_route := (
		_first_clutch_tracking_active()
		and _first_clutch_stage() == &"specialty_route"
		and worker_id == int(_first_clutch.get("target_worker_id", -1))
	)
	if (
		_clock != null
		and _clock.speed_index == 0
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not induction_route
	):
		_queue_tactical_route_assignment(worker_before, lane)
		return
	var assignment_changed := not worker_before.is_empty() and previous_lane != lane
	var prior_undo := _routing_assignment_undo.duplicate(true)
	if (
		not worker_before.is_empty()
		and previous_lane != lane
		and previous_lane in PeckworkRoutingUI.ASSIGNMENT_ORDER
		and lane in PeckworkRoutingUI.ASSIGNMENT_ORDER
	):
		# Install the one-level command before simulation emits its synchronous
		# snapshot, keeping the visible Undo control in the same settled frame.
		_routing_assignment_undo = {
			"day": int(before_snapshot.get("day", 0)),
			"worker_id": worker_id,
			"worker_name": String(worker_before.get(
				"name",
				"HEN %d" % (worker_id + 1),
			)),
			"previous_lane": previous_lane,
			"current_lane": lane,
		}
	if not _simulation.set_worker_assignment(worker_id, lane):
		_routing_assignment_undo = prior_undo
		_publish_status_copy(
			"ROUTE HELD  ·  PICK ACTIVE HEN",
			true,
			"Route held. That hen or tray is no longer active. Reopen Flockwatch Flock and choose a current employed hen.",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		return
	var worker_name := "HEN %d" % (worker_id + 1)
	for worker_value in _simulation.snapshot().get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			worker_name = String(worker.get("name", worker_name))
			break
	var lane_label := "AUTO SORT" if lane == &"auto" else String(lane).replace("_", " ").to_upper()
	_ticker_label.text = "%s ROUTED TO %s. Current files finish before the new tray applies." % [worker_name.to_upper(), lane_label]
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_record_adaptive_route_outcome(worker_before, lane, assignment_changed)
	_first_clutch_record_routing(worker_id, lane)
	if assignment_changed and lane == StringName(worker_before.get("specialty", &"")):
		var hen := _worker_views.get(worker_id) as ChickenView
		if hen != null:
			hen.play_short_bark("MY SPECIALTY!", &"success")
		_publish_status_copy("SPECIALTY MATCH · FASTER WORK ON MATCHING FILES", false)
	_update_guidance(_simulation.snapshot())
	_save_campaign_checkpoint("routing_assignment")


func _queue_tactical_route_assignment(worker: Dictionary, lane: StringName) -> void:
	if (
		worker.is_empty()
		or lane not in PeckworkRoutingUI.ASSIGNMENT_ORDER
		or not bool(worker.get("employed", int(worker.get("desk_index", -1)) >= 0))
	):
		_publish_status_copy(
			"PLAN HELD  ·  PICK ACTIVE HEN",
			true,
			"No route was filed. Choose a current employed hen and an available intake tray.",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		return
	var worker_id := int(worker.get("id", -1))
	var worker_name := String(worker.get("name", "HEN %d" % (worker_id + 1)))
	var current_lane := StringName(worker.get("assigned_lane", &"auto"))
	var result := _tactical_route_planner.queue_route(
		worker_id,
		worker_name,
		lane,
		current_lane,
	)
	_apply_tactical_route_plan_preview()
	if not bool(result.get("accepted", false)):
		var reason := String(result.get("reason", "PLAN HELD"))
		var detail := (
			"This hen already uses that tray; any unfiled preview for her was removed."
			if reason == "ALREADY FILED" else
			"The pause plan holds three hens. Resume to file it, or undo a queued hen before adding another."
		)
		_publish_status_copy("%s  ·  NOTHING FILED" % reason, true, detail)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		_update_guidance(_simulation.snapshot())
		return
	var plan := result.get("plan", {}) as Dictionary
	var lane_label := "AUTO" if lane == &"auto" else _dispatch_lane_label(lane)
	_ticker_label.text = "PLAN %d/%d  ·  %s → %s  ·  RESUME TO FILE" % [
		int(plan.get("count", 0)),
		int(plan.get("capacity", TacticalRoutePlannerScript.CAPACITY)),
		worker_name.to_upper(),
		lane_label,
	]
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_update_guidance(_simulation.snapshot())


func _commit_tactical_route_plan() -> void:
	if _tactical_route_planner == null or _tactical_route_planner.is_empty():
		return
	var commands := _tactical_route_planner.drain()
	var filed_labels: Array[String] = []
	var held_count := 0
	for command in commands:
		var worker_id := int(command.get("worker_id", -1))
		var lane := StringName(command.get("lane", ""))
		var before_snapshot := _simulation.snapshot()
		var worker_before := _worker_record(before_snapshot, worker_id)
		var previous_lane := StringName(worker_before.get("assigned_lane", &""))
		if worker_before.is_empty() or lane not in PeckworkRoutingUI.ASSIGNMENT_ORDER:
			held_count += 1
			continue
		if not _simulation.set_worker_assignment(worker_id, lane):
			held_count += 1
			continue
		var worker_name := String(command.get("worker_name", "HEN %d" % (worker_id + 1)))
		var lane_label := "AUTO" if lane == &"auto" else _dispatch_lane_label(lane)
		filed_labels.append("%s → %s" % [worker_name.to_upper(), lane_label])
		_routing_assignment_undo = {
			"day": int(before_snapshot.get("day", 0)),
			"worker_id": worker_id,
			"worker_name": worker_name,
			"previous_lane": previous_lane,
			"current_lane": lane,
		}
		_record_adaptive_route_outcome(worker_before, lane, previous_lane != lane)
		_first_clutch_record_routing(worker_id, lane)
	_apply_tactical_route_plan_preview()
	if not filed_labels.is_empty():
		var title := "PLAN FILED  ·  %d ROUTE%s" % [
			filed_labels.size(),
			"" if filed_labels.size() == 1 else "S",
		]
		var detail := "%s. Current files finish before each new tray applies." % "; ".join(filed_labels)
		if held_count > 0:
			detail += " %d stale route%s held safely." % [held_count, " was" if held_count == 1 else "s were"]
		_publish_status_copy(title, true, detail)
		_save_campaign_checkpoint("tactical_route_plan")
	elif held_count > 0:
		_publish_status_copy(
			"PLAN HELD  ·  NOTHING FILED",
			true,
			"The queued hens or trays were no longer active. Review the current flock before planning again.",
		)


func _cancel_tactical_route_plan_for_worker(worker_id: int) -> bool:
	if _tactical_route_planner == null:
		return false
	var result := _tactical_route_planner.cancel_route(worker_id)
	if not bool(result.get("accepted", false)):
		return false
	var removed := result.get("entry", {}) as Dictionary
	_apply_tactical_route_plan_preview()
	_publish_status_copy(
		"PLANNED ROUTE REMOVED  ·  NOTHING FILED",
		true,
		"%s's pause preview was removed. Existing work and the filed route are unchanged."
		% String(removed.get("worker_name", "That hen")),
	)
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_update_guidance(_simulation.snapshot())
	return true


func _tactical_route_plan_snapshot() -> Dictionary:
	if _tactical_route_planner == null:
		return {
			"count": 0,
			"capacity": TacticalRoutePlannerScript.CAPACITY,
			"queued": [],
			"files_nothing": true,
			"commits_on_resume": true,
		}
	return _tactical_route_planner.snapshot()


func _apply_tactical_route_plan_preview() -> void:
	var plan := _tactical_route_plan_snapshot()
	if _routing_ui != null:
		_routing_ui.set_meta("tactical_route_plan", plan.duplicate(true))
	if _top_hud_panel != null:
		_top_hud_panel.set_meta("tactical_route_plan", plan.duplicate(true))


func _record_adaptive_route_outcome(
	worker_before: Dictionary,
	lane: StringName,
	assignment_changed: bool,
) -> void:
	# Manual out-of-specialty routing is a valid strategy, so one choice never
	# triggers coaching. Only two consecutive changed assignments establish a
	# useful pattern, and the resulting HUD cue remains optional and temporary.
	if (
		not assignment_changed
		or worker_before.is_empty()
		or String(_player_preferences.get("guidance_mode", "full")) == "off"
	):
		return
	var specialty := StringName(String(worker_before.get("specialty", "")))
	var secondary := StringName(String(worker_before.get("secondary_specialty", "")))
	var credentialed := (
		lane == &"auto"
		or lane == specialty
		or (secondary != &"" and lane == secondary)
	)
	if credentialed:
		var now_msec := Time.get_ticks_msec()
		var corrected_coached_hen := (
			bool(_adaptive_route_recovery.get("active", false))
			and now_msec < int(_adaptive_route_recovery.get("expires_at_msec", 0))
			and int(_adaptive_route_recovery.get("worker_id", -1))
			== int(worker_before.get("id", -2))
		)
		_clear_adaptive_route_recovery()
		if corrected_coached_hen:
			_publish_adaptive_route_success(worker_before, lane)
		return
	var now_msec := Time.get_ticks_msec()
	if (
		_adaptive_route_last_miss_at_msec > 0
		and now_msec - _adaptive_route_last_miss_at_msec
		> ADAPTIVE_ROUTE_RECOVERY_HOLD_MSEC
	):
		_clear_adaptive_route_recovery()
	_adaptive_route_miss_streak += 1
	_first_session_funnel.observe_signal(&"route_miss")
	_adaptive_route_last_miss_at_msec = now_msec
	if _adaptive_route_miss_streak < ADAPTIVE_ROUTE_MISS_THRESHOLD:
		_adaptive_route_recovery.clear()
		return
	var worker_id := int(worker_before.get("id", -1))
	var worker_name := String(worker_before.get(
		"name",
		"HEN %d" % (worker_id + 1),
	)).strip_edges()
	if worker_name.is_empty():
		worker_name = "HEN %d" % (worker_id + 1)
	_adaptive_route_recovery = {
		"active": true,
		"worker_id": worker_id,
		"worker_name": worker_name,
		"specialty": String(specialty),
		"specialty_label": _dispatch_lane_label(specialty),
		"last_lane": String(lane),
		"miss_streak": _adaptive_route_miss_streak,
		"expires_at_msec": now_msec + ADAPTIVE_ROUTE_RECOVERY_HOLD_MSEC,
	}


func _publish_adaptive_route_success(worker: Dictionary, lane: StringName) -> void:
	# This is the newest consequence of a deliberate player action. Retire any
	# older decision receipt so the browser live region announces the recovery
	# while its bounded toast is still visible.
	_retire_action_outcome_receipts(&"adaptive_route_recovery", false)
	var worker_id := int(worker.get("id", -1))
	var worker_name := String(worker.get(
		"name",
		"HEN %d" % (worker_id + 1),
	)).strip_edges()
	if worker_name.is_empty():
		worker_name = "HEN %d" % (worker_id + 1)
	var lane_label := "AUTO" if lane == &"auto" else _dispatch_lane_label(lane)
	var exact_detail := (
		"Routing fit restored. %s now uses Auto, which favors filed specialties and urgent deadlines. The repeated out-of-fit pattern is cleared."
		% worker_name
		if lane == &"auto" else
		"Routing fit restored. %s now uses %s, one of this hen's filed specialties. The repeated out-of-fit pattern is cleared."
		% [worker_name, lane_label]
	)
	_publish_status_copy(
		"FIT RESTORED  ·  %s  >  %s" % [worker_name.to_upper(), lane_label],
		true,
		exact_detail,
	)
	if _audio_feedback != null:
		_audio_feedback.play_attention_restored()


func _clear_adaptive_route_recovery() -> void:
	_adaptive_route_miss_streak = 0
	_adaptive_route_last_miss_at_msec = 0
	_adaptive_route_recovery.clear()


func _adaptive_route_recovery_diagnostic_state() -> Dictionary:
	var state := _adaptive_route_recovery.duplicate(true)
	var remaining := maxi(
		0,
		int(state.get("expires_at_msec", 0)) - Time.get_ticks_msec(),
	)
	var visible := (
		bool(state.get("active", false))
		and remaining > 0
		and String(_player_preferences.get("guidance_mode", "full")) != "off"
	)
	state["active"] = visible
	state["miss_streak"] = _adaptive_route_miss_streak
	state["remaining_msec"] = remaining
	state.erase("expires_at_msec")
	state["guidance_mode"] = String(_player_preferences.get("guidance_mode", "full"))
	return state


func _focus_adaptive_route_recovery() -> void:
	var recovery := _adaptive_route_recovery_diagnostic_state()
	if not bool(recovery.get("active", false)):
		return
	var worker_id := int(recovery.get("worker_id", -1))
	if worker_id < 0 or _routing_ui == null:
		return
	if _flockwatch_open:
		_set_flockwatch_open(false)
	if _camera_controller != null:
		_camera_controller.focus_worker(worker_id)
	_routing_ui.visible = not _blocking_management_surface_open()
	var target := _routing_ui.focus_hen_dossier(worker_id)
	if target != null:
		target.grab_focus()
		_pulse_action_target(target)


func _on_worker_assignment_undo_requested(worker_id: int) -> void:
	if _cancel_tactical_route_plan_for_worker(worker_id):
		return
	var snapshot := _simulation.snapshot()
	var undo := _validated_routing_assignment_undo(snapshot)
	if undo.is_empty() or int(undo.get("worker_id", -1)) != worker_id:
		_publish_status_copy(
			"UNDO HELD  ·  CHOOSE NEW ROUTE",
			true,
			"Routing undo held. The prior tray is no longer current. Choose a new route from this hen's dossier.",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		return
	var previous_lane := StringName(undo.get("previous_lane", &""))
	var current_lane := StringName(undo.get("current_lane", &""))
	var worker := _worker_record(snapshot, worker_id)
	if StringName(worker.get("assigned_lane", &"")) != current_lane:
		_publish_status_copy(
			"UNDO HELD  ·  REVIEW CURRENT ROUTE",
			true,
			"Routing undo held. This hen's route changed again, so the old one-level undo is stale. Review the current tray before filing another route.",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		return
	# Clear before the authoritative mutation emits its synchronous snapshot so
	# the one-level Undo action cannot turn itself into an accidental Redo.
	_routing_assignment_undo.clear()
	if not _simulation.set_worker_assignment(worker_id, previous_lane):
		_routing_assignment_undo = undo
		_publish_status_copy(
			"UNDO HELD  ·  REVIEW FLOCK",
			true,
			"Routing undo held. The hen or prior tray is no longer available. Review the current Flock filing before choosing another route.",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"routing")
		return
	var worker_name := String(undo.get("worker_name", "HEN %d" % (worker_id + 1)))
	var lane_label := (
		"AUTO SORT"
		if previous_lane == &"auto" else
		String(previous_lane).replace("_", " ").to_upper()
	)
	_ticker_label.text = (
		"%s'S NEXT TRAY RESTORED TO %s. Completed file work was not rolled back."
		% [worker_name.to_upper(), lane_label]
	)
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_save_campaign_checkpoint("routing_assignment_undo")


func _worker_record(snapshot: Dictionary, worker_id: int) -> Dictionary:
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _validated_routing_assignment_undo(snapshot: Dictionary) -> Dictionary:
	if _routing_assignment_undo.is_empty():
		return {}
	if int(_routing_assignment_undo.get("day", -1)) != int(snapshot.get("day", -2)):
		return {}
	var worker_id := int(_routing_assignment_undo.get("worker_id", -1))
	var worker := _worker_record(snapshot, worker_id)
	var previous_lane := StringName(_routing_assignment_undo.get("previous_lane", &""))
	var current_lane := StringName(_routing_assignment_undo.get("current_lane", &""))
	if (
		worker.is_empty()
		or not bool(worker.get("employed", int(worker.get("desk_index", -1)) >= 0))
		or previous_lane not in PeckworkRoutingUI.ASSIGNMENT_ORDER
		or current_lane not in PeckworkRoutingUI.ASSIGNMENT_ORDER
		or StringName(worker.get("assigned_lane", &"")) != current_lane
	):
		return {}
	return _routing_assignment_undo.duplicate(true)


func _on_claim_resolution_requested(worker_id: int, path_id: StringName) -> void:
	var before_snapshot := _simulation.snapshot()
	var source_worker := _worker_record(before_snapshot, worker_id)
	var source_claim := source_worker.get("current_claim", {}) as Dictionary
	var result := _simulation.set_claim_resolution(worker_id, path_id)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"CLAIMANT FILE",
			"REVIEW PATH",
			String(result.get("reason", "Review the current claimant-path terms.")),
			"Claimant file",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"claim_resolution")
		return
	_ticker_label.text = String(result.get(
		"outcome",
		"Claimant path filed.",
	))
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()
	var path_label := String(path_id).replace("_", " ").to_upper()
	match path_id:
		&"humane_settlement": path_label = "HUMANE"
		&"fast_denial": path_label = "DENIAL"
		&"coverage_exception": path_label = "EXCEPTION"
	_record_campaign_order_cause_receipts(
		before_snapshot,
		_simulation.snapshot(),
		path_label,
		&"claim_path",
		"",
		{
			"source_kind": "worker_file",
			"source_label": String(source_worker.get("name", "HEN")),
			"worker_id": worker_id,
			"claim_id": int(source_claim.get("id", -1)),
		},
	)
	_save_campaign_checkpoint("claim_resolution")


func _on_first_clutch_action_requested() -> void:
	var coach := _first_clutch_coach_snapshot(_simulation.snapshot())
	if not bool(coach.get("visible", false)) or _peck_assist_input_blocked():
		return
	var worker_id := int(coach.get("target_worker_id", -1))
	if bool(coach.get("resume_required", false)):
		_on_speed_button_pressed(1)
	elif String(coach.get("stage", "")) == "priority_peck":
		_on_peck_assist_requested(worker_id)
	elif not _handle_first_clutch_primary_action():
		_on_first_clutch_focus_requested(worker_id)


func _on_personnel_action_requested(worker_id: int, action_id: StringName) -> void:
	var before_snapshot := _simulation.snapshot()
	var source_worker := _worker_record(before_snapshot, worker_id)
	var result := _simulation.perform_personnel_action(worker_id, action_id)
	_routing_ui.complete_care_lesson(worker_id, result, source_worker, _worker_record(_simulation.snapshot(), worker_id))
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"CHECK-IN",
			"REVIEW HEN",
			String(result.get("reason", "Review this hen's current personnel filing.")),
			"Personnel check-in",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"personnel")
		return
	var preferred_note := "  /  PROFILE MATCH" if bool(result.get("preferred", false)) else ""
	_begin_payoff_breath()
	var cared_hen := _worker_views.get(worker_id) as ChickenView
	if cared_hen != null and is_instance_valid(cared_hen):
		var reaction := "I'LL TRY THAT."
		if action_id == &"quota_pressure":
			reaction = "THAT'S A LOT TO ASK."
		elif float(source_worker.get("stress", 0.0)) >= 25.0:
			reaction = "THANKS FOR NOTICING."
		elif bool(result.get("preferred", false)):
			reaction = "THAT MEANS A LOT."
		elif action_id == &"share_credit":
			reaction = "WE DID THAT TOGETHER."
		cared_hen.play_short_bark(reaction, &"neutral" if action_id == &"quota_pressure" else &"team")
	_ticker_label.text = "%s%s" % [String(result.get("outcome", "Personnel action filed.")), preferred_note]
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()
	_record_campaign_order_cause_receipts(
		before_snapshot,
		_simulation.snapshot(),
		"CHECK-IN",
		&"personnel",
		"",
		{
			"source_kind": "worker_personnel",
			"source_label": String(source_worker.get("name", "HEN")),
			"worker_id": worker_id,
			"action_id": String(action_id),
		},
	)
	_first_clutch_record_checkin(worker_id)
	_save_campaign_checkpoint("personnel_action")


func _priority_peck_precision_candidate(snapshot: Dictionary) -> Dictionary:
	if (
		_clock == null
		or _routing_ui == null
		or int(snapshot.get("shift_phase", -1)) != DepartmentSimulation.ShiftPhase.RUNNING
	):
		return {}
	var focused_worker_id := _routing_ui.focused_worker_id()
	if focused_worker_id < 0:
		return {}
	if focused_worker_id == _priority_peck_focus_disarmed_worker_id:
		return {}
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) != focused_worker_id:
			continue
		var claim := worker.get("current_claim", {}) as Dictionary
		var assist := worker.get("peck_assist", {}) as Dictionary
		var state := StringName(assist.get("window_state", &"locked"))
		if claim.is_empty() or state not in [&"not_ready", &"open"]:
			return {}
		var progress := float(worker.get("progress", 0.0))
		var window_start := float(assist.get(
			"window_start",
			DepartmentSimulation.PECK_ASSIST_WINDOW_START,
		))
		if state == &"not_ready" and progress < maxf(0.0, window_start - PECK_FOCUS_LEAD_PROGRESS):
			return {}
		return {
			"worker_id": focused_worker_id,
			"worker_name": String(worker.get("name", "HEN %d" % (focused_worker_id + 1))),
			"claim_id": int(claim.get("id", -1)),
			"progress": progress,
			"window_start": window_start,
			"window_state": state,
			"timing_label": String(assist.get("timing_label", "")),
		}
	return {}


func _refresh_priority_peck_precision_focus(snapshot: Dictionary) -> void:
	if _clock == null:
		return
	_refresh_priority_peck_opportunity_audio(snapshot)
	var candidate := _priority_peck_precision_candidate(snapshot)
	if _next_moment_active and StringName(candidate.get("window_state", &"")) == &"open":
		var reached_worker_id := int(candidate.get("worker_id", -1))
		_finish_next_moment("NEXT MOMENT REACHED  ·  PRIORITY PECK READY", true)
		# The moment must be understandable without hunting around the office.
		# Center the authored hen target after the temporary seek relinquishes clock
		# ownership; focusing the already-selected hen is safe and idempotent.
		if reached_worker_id >= 0 and _camera_controller != null:
			_camera_controller.focus_worker(reached_worker_id)
	var result_hold_active := (
		Time.get_ticks_msec() < _priority_peck_result_hold_until_msec
		and _priority_peck_result_hold_worker_id >= 0
		and _priority_peck_result_hold_claim_id >= 0
		and int(snapshot.get("shift_phase", -1)) == DepartmentSimulation.ShiftPhase.RUNNING
	)
	_priority_peck_focus_worker_id = (
		_priority_peck_result_hold_worker_id
		if result_hold_active else
		int(candidate.get("worker_id", -1))
	)
	_clock.set_precision_focus_active(result_hold_active or not candidate.is_empty())
	_refresh_speed_button_copy(snapshot)
	if not result_hold_active and Time.get_ticks_msec() >= _priority_peck_result_hold_until_msec:
		_priority_peck_result_hold_until_msec = 0
		_priority_peck_result_hold_worker_id = -1
		_priority_peck_result_hold_claim_id = -1
		_priority_peck_result_hold_kind = &""


## A newly focused claim establishes a silent baseline. Only that same claim
## subsequently crossing into OPEN earns the opportunity cue, so clicking an
## already-open hen and repeated simulation snapshots never create alert spam.
func _refresh_priority_peck_opportunity_audio(snapshot: Dictionary) -> void:
	if (
		_audio_feedback == null
		or _routing_ui == null
		or int(snapshot.get("shift_phase", -1)) != DepartmentSimulation.ShiftPhase.RUNNING
	):
		_priority_peck_opportunity_audio_key = ""
		_priority_peck_opportunity_audio_state = &""
		return
	# A visual-novel aside owns the player's attention and pauses the floor. Keep
	# the prior observation intact so the same transition can announce itself once
	# the player files the aside away; ambient chatter never suppresses the cue.
	if (
		_character_dialogue_ui != null
		and _character_dialogue_ui.has_blocking_dialogue()
	):
		return
	var focused_worker_id := _routing_ui.focused_worker_id()
	if focused_worker_id < 0:
		_priority_peck_opportunity_audio_key = ""
		_priority_peck_opportunity_audio_state = &""
		return
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) != focused_worker_id:
			continue
		var claim := worker.get("current_claim", {}) as Dictionary
		var assist := worker.get("peck_assist", {}) as Dictionary
		if claim.is_empty() or assist.is_empty():
			break
		var observation_key := "%d|%d" % [focused_worker_id, int(claim.get("id", -1))]
		var window_state := StringName(String(assist.get("window_state", "locked")))
		if observation_key != _priority_peck_opportunity_audio_key:
			_priority_peck_opportunity_audio_key = observation_key
			_priority_peck_opportunity_audio_state = window_state
			return
		if (
			window_state == &"open"
			and _priority_peck_opportunity_audio_state != &"open"
		):
			_audio_feedback.play_priority_peck_ready()
			var worker_view := _worker_views.get(focused_worker_id) as ChickenView
			if worker_view != null and is_instance_valid(worker_view):
				worker_view.play_priority_peck_ready_feedback()
		_priority_peck_opportunity_audio_state = window_state
		return
	_priority_peck_opportunity_audio_key = ""
	_priority_peck_opportunity_audio_state = &""


## The simulation emits this once at the authoritative closing boundary. Only a
## claim whose opening was observed under the current inspection earns the
## retreat, preventing off-screen misses and synthetic refocuses from becoming
## noisy failure alerts.
func _on_peck_assist_missed(worker_id: int, claim_id: int) -> void:
	if _routing_ui == null or _routing_ui.focused_worker_id() != worker_id:
		return
	var observation_key := "%d|%d" % [worker_id, claim_id]
	if (
		observation_key != _priority_peck_opportunity_audio_key
		or _priority_peck_opportunity_audio_state != &"open"
	):
		return
	# Retire the observed opening before presentation so even a duplicate external
	# signal cannot replay this single-fire consequence.
	_priority_peck_opportunity_audio_state = &"missed"
	_priority_peck_result_hold_until_msec = Time.get_ticks_msec() + PECK_FOCUS_MISSED_HOLD_MSEC
	_priority_peck_result_hold_worker_id = worker_id
	_priority_peck_result_hold_claim_id = claim_id
	_priority_peck_result_hold_kind = &"missed"
	_priority_peck_focus_worker_id = worker_id
	if _clock != null:
		_clock.set_precision_focus_active(true)
		_refresh_speed_button_copy()
	var worker_view := _worker_views.get(worker_id) as ChickenView
	if worker_view != null and is_instance_valid(worker_view):
		worker_view.play_priority_peck_missed_feedback()
	_routing_ui.play_peck_assist_missed(worker_id)


## Derives one truthful pause explanation from authoritative clock state and the
## currently visible input owner. This is presentation-only: it never changes
## clock speed, simulation phase, or a surface's continuation rules.
func _pause_context_state() -> Dictionary:
	if _clock == null:
		return {"active": false}
	var clock_stopped := _clock.speed_index == 0 or _clock.interaction_hold_active()
	if not clock_stopped:
		return {"active": false}

	var owner_id: StringName = &"player"
	var owner_label := "PLAYER"
	var reason := "You paused the running shift."
	var next_action := "RESUME 1×"
	var resume_behavior := "manual"
	var speed_button_actionable: bool = (
		_simulation != null
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not _feed_party_active
		and not _blocking_management_surface_open()
		and (_character_dialogue_ui == null or not _character_dialogue_ui.is_blocking())
		and not _focus_pause_active
	)

	if _focus_pause_active:
		owner_id = &"window_focus"
		owner_label = "WINDOW"
		reason = "The game paused because another window or tab has focus."
		next_action = "RETURN TO GAME"
		resume_behavior = "automatic"
		speed_button_actionable = false
	else:
		var held_action := _active_held_confirmation_primary_action_state()
		if not held_action.is_empty():
			owner_id = &"held_confirmation"
			owner_label = "FILING REVIEW"
			reason = "An irreversible filing is held for confirmation; no change has occurred."
			next_action = String(held_action.get("visible_label", "SAFE RETURN")).strip_edges()
			resume_behavior = "confirmation"
			speed_button_actionable = false
		elif _settings_ui != null and _settings_ui.is_open():
			var settings_action: Dictionary = _settings_ui.primary_action_state()
			owner_id = &"settings"
			owner_label = "SETTINGS"
			reason = "Settings owns input while the floor remains safely stopped."
			next_action = String(settings_action.get("visible_label", "RETURN TO THE FLOOR")).strip_edges()
			resume_behavior = "return"
			speed_button_actionable = false
		else:
			var management_action := _management_overlay_primary_action_state()
			if not management_action.is_empty():
				owner_id = &"management_file"
				owner_label = "MANAGEMENT FILE"
				reason = "A management filing owns input while authoritative time is held."
				next_action = String(management_action.get("visible_label", management_action.get("copy", "CONTINUE"))).strip_edges()
				resume_behavior = "confirmation"
				speed_button_actionable = false
			elif _decision_host != null and _decision_host.visible:
				var decision_action := _decision_primary_action_state()
				var pending_kind := StringName(_active_decision.get("kind", &"incident"))
				match pending_kind:
					&"incident":
						owner_id = &"incident"
						owner_label = "INCIDENT"
						reason = "An incident auto-paused the shift before any response was filed."
					FIRST_CLUTCH_REINVESTMENT_KIND:
						owner_id = &"first_egg"
						owner_label = "FIRST EGG"
						reason = "The first-egg filing paused progression until its reward is recorded."
					&"directive":
						owner_id = &"flock_rule"
						owner_label = "FLOCK RULE"
						reason = "The morning rule must be filed before the shift can run."
					&"credit_allocation", &"major_event":
						owner_id = &"closing_file"
						owner_label = "CLOSING FILE"
						reason = "The closing file holds time until the flock's work is attributed."
					_:
						owner_id = &"decision"
						owner_label = "DECISION"
						reason = "A management decision holds time until a response is filed."
				next_action = String(decision_action.get("visible_label", decision_action.get("copy", "CHOOSE A RESPONSE"))).strip_edges()
				resume_behavior = "confirmation"
				speed_button_actionable = false
			elif _campaign_ui != null and _campaign_ui.is_modal_open():
				var campaign_action := _campaign_modal_primary_action_state()
				owner_id = &"campaign_record"
				owner_label = _campaign_modal_accessibility_name().to_upper()
				reason = "The campaign record owns progression while the office clock is safe."
				next_action = String(campaign_action.get("visible_label", campaign_action.get("copy", "CONTINUE"))).strip_edges()
				resume_behavior = "confirmation"
				speed_button_actionable = false
			elif _day_review_scrim != null and _day_review_scrim.visible:
				owner_id = &"shift_review"
				owner_label = "SHIFT REVIEW"
				reason = "The completed shift is frozen while its results and next plan are reviewed."
				if _begin_next_shift_button != null and _begin_next_shift_button.is_visible_in_tree():
					next_action = _begin_next_shift_button.text.strip_edges()
				elif _continue_shift_button != null and _continue_shift_button.is_visible_in_tree():
					next_action = _continue_shift_button.text.strip_edges()
				else:
					next_action = "CONTINUE REVIEW"
				resume_behavior = "confirmation"
				speed_button_actionable = false
			elif _character_dialogue_ui != null and _character_dialogue_ui.is_blocking():
				var dialogue_button := _character_dialogue_ui.find_child("CharacterDialogueDismiss", true, false) as Button
				owner_id = &"flock_message"
				owner_label = "FLOCK MESSAGE"
				reason = "A flock message paused the shift so its consequence is not missed."
				next_action = dialogue_button.text.strip_edges() if dialogue_button != null else "FILE AWAY"
				resume_behavior = "automatic"
				speed_button_actionable = false
			elif _feed_party_active:
				owner_id = &"feed_party"
				owner_label = "FEED PARTY"
				reason = "Feed Party attendance temporarily owns the clock."
				next_action = "WAIT FOR RETURN"
				resume_behavior = "automatic" if _feed_party_previous_speed > 0 else "manual"
				speed_button_actionable = false

	if owner_id == &"player" and not _next_moment_stop_reason.is_empty():
		owner_id = &"next_moment"
		owner_label = "NEXT MOMENT"
		reason = _next_moment_stop_reason
		next_action = "PECK OR RESUME" if "PECK" in reason else "CONTINUE"
	if owner_id == &"player" and _first_clutch_tracking_active() and not bool(_first_clutch.get("specialty_routed", false)):
		owner_id = &"opening_route"
		owner_label = "READY TO ROUTE"
		reason = "The first route has not started. Route and Start begins automatic work."
		next_action = "ROUTE & START"
	if next_action.is_empty():
		next_action = "CONTINUE"
	var compact_action := next_action.to_upper().replace("  ", " ")
	if ":" in compact_action:
		compact_action = compact_action.get_slice(":", compact_action.get_slice_count(":") - 1).strip_edges()
	if compact_action.length() > 28:
		compact_action = compact_action.left(27).rstrip(" ,.;:") + "…"
	var accessible_text := "Pause owner: %s. %s Time and route progress are safe. Next action: %s." % [
		owner_label.capitalize(),
		reason,
		next_action.replace("  ", " "),
	]
	return {
		"active": true,
		"owner_id": String(owner_id),
		"owner_label": owner_label,
		"reason": reason,
		"next_action": next_action,
		"resume_behavior": resume_behavior,
		"speed_button_actionable": speed_button_actionable,
		"compact_copy": "PAUSED  ·  %s  ·  %s" % [owner_label, compact_action],
		"accessible_text": accessible_text,
	}


func _refresh_speed_button_copy(snapshot: Dictionary = {}) -> void:
	if _speed_buttons.is_empty():
		return
	var pause_context := _pause_context_state()
	var paused := bool(pause_context.get("active", false))
	var resume_available := paused and bool(pause_context.get("speed_button_actionable", false))
	var controls_available: bool = (
		_simulation != null
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not _feed_party_active
		and not _blocking_management_surface_open()
		and (_character_dialogue_ui == null or not _character_dialogue_ui.is_blocking())
		and not _focus_pause_active
	)
	var pause_label := "RESUME" if resume_available else "PAUSED"
	if _time_label != null:
		var clock_copy := String(_time_label.get_meta("clock_text", "8:00 AM"))
		_time_label.set_meta("full_text", clock_copy)
		_time_label.set_meta("compact_text", clock_copy)
		_time_label.text = clock_copy
		_refresh_clock_accessibility()
	var labels := [pause_label if paused else "PAUSE", "1×", "3×", "10×"]
	var pause_tooltip := String(pause_context.get(
		"accessible_text",
		"Resume simulation at normal 1× speed.",
	))
	var tooltips := [
		pause_tooltip if paused else "Pause simulation.",
		"Run simulation at normal 1× speed.",
		"Run simulation at fast 3× speed.",
		"Run simulation at ultra 10× speed.",
	]
	var limiting := _clock != null and _clock.precision_focus_limiting()
	for index in _speed_buttons.size():
		var button := _speed_buttons[index]
		button.disabled = not controls_available
		button.text = labels[index]
		button.tooltip_text = tooltips[index]
		button.accessibility_name = (
			"%s Press Space." % tooltips[index]
			if index == 0
			else tooltips[index]
		)
		if index == 0:
			button.set_meta("clock_action", &"resume" if resume_available else (&"blocked" if paused else &"pause"))
			button.set_meta("pause_owner_id", StringName(String(pause_context.get("owner_id", ""))))
			button.set_meta("pause_context", pause_context.duplicate(true))
		if limiting and index == _clock.speed_index:
			button.text = "%s/1×" % labels[index]
			button.tooltip_text = (
				"%s remains selected. Inspecting this approaching Priority Peck "
				+ "temporarily holds the effective clock at 1×; the selected speed resumes automatically."
			) % labels[index]
	if _compact_speed_menu != null:
		_compact_speed_menu.disabled = not controls_available
		_compact_speed_menu.text = (
			"PACE" if _clock == null or paused else
			["PACE", "1× PACE", "3× PACE", "10× PACE"][_clock.speed_index]
		)
	if _next_moment_button != null:
		var next_hint := _action_hint(NEXT_MOMENT_ACTION)
		var primary_hint := next_hint.split(" / ", false)[0]
		var target_state := _next_moment_target_state(snapshot)
		var target_label := String(target_state.get(
			"label",
			"DECISION / PECK / REVIEW",
		))
		_next_moment_button.text = (
			"STOP  [%s]" % primary_hint
			if _next_moment_active else
		"NEXT  [%s]" % primary_hint
		)
		_next_moment_button.disabled = not controls_available and not _next_moment_active
		_next_moment_button.theme_type_variation = (
			&"ActiveSpeedButton" if _next_moment_active else &"SpeedButton"
		)
		_next_moment_button.tooltip_text = (
			"Seeking %s. Stop advancing and return to the speed selected before Next Moment."
			% target_label.to_lower()
			if _next_moment_active else
			String(target_state.get(
				"detail",
				"Advance safely at 10× until the next decision, shift review, or open Priority Peck window.",
			))
		)
		_next_moment_button.accessibility_name = "%s Binding: %s." % [
			_next_moment_button.tooltip_text,
			next_hint,
		]


func _on_next_moment_pressed() -> void:
	if _next_moment_active:
		_finish_next_moment("NEXT MOMENT CANCELED  ·  MANUAL PACE RESTORED", false)
		return
	if (
		_simulation == null
		or _clock == null
		or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
		or _feed_party_active
		or _blocking_management_surface_open()
		or (_character_dialogue_ui != null and _character_dialogue_ui.is_blocking())
	):
		_publish_status_copy(
			"NEXT MOMENT HELD  ·  FINISH THE OPEN FILE",
			true,
			"Next Moment is available during an active shift after the current management file is closed.",
		)
		return
	_first_session_funnel.observe_signal(&"next_moment_used")
	_next_moment_previous_speed = _clock.speed_index if _clock.speed_index > 0 else 1
	_next_moment_stop_reason = ""
	_next_moment_active = true
	_clock.set_speed(3)
	_refresh_speed_button_copy()
	var target_state := _next_moment_target_state()
	_publish_status_copy(
		"NEXT MOMENT  ·  SEEKING %s" % String(target_state.get(
			"label",
			"DECISION / PECK / REVIEW",
		)).to_upper(),
		true,
		String(target_state.get(
			"detail",
			"Advancing safely at ten times speed. The clock will stop at the next decision, shift review, or open Priority Peck window.",
		)),
	)


func _finish_next_moment(copy: String, pause_at_moment: bool) -> void:
	if not _next_moment_active:
		return
	var restore_speed := clampi(_next_moment_previous_speed, 1, 3)
	_next_moment_active = false
	_next_moment_previous_speed = 1
	_next_moment_stop_reason = copy if pause_at_moment else ""
	if _clock != null:
		_clock.set_speed(0 if pause_at_moment else restore_speed)
	_refresh_speed_button_copy()
	if not copy.is_empty():
		_publish_status_copy(copy)


func _next_moment_target_state(snapshot: Dictionary = {}) -> Dictionary:
	var source := snapshot
	if source.is_empty() and _simulation != null:
		source = _simulation.snapshot(true, true)
	var candidate := _priority_peck_precision_candidate(source)
	if not candidate.is_empty():
		var worker_name := String(candidate.get("worker_name", "HEN")).to_upper()
		return {
			"id": "priority_peck",
			"label": "%s'S PRIORITY PECK" % worker_name,
			"worker_id": int(candidate.get("worker_id", -1)),
			"detail": (
				"Advance safely at 10× to %s's next Priority Peck window. "
				+ "The clock will pause and the camera will center the ready hen."
			) % worker_name.capitalize(),
		}
	return {
		"id": "next_management_moment",
		"label": "DECISION / PECK / REVIEW",
		"worker_id": -1,
		"detail": (
			"Advance safely at 10× until the next decision, shift review, or open "
			+ "Priority Peck window. The clock stops before player input is required."
		),
	}


func _clutch_reward_ladder_snapshot(streak: int) -> Dictionary:
	var safe_streak := maxi(0, streak)
	var tier_index := -1
	for index in CLUTCH_REWARD_THRESHOLDS.size():
		if safe_streak >= int(CLUTCH_REWARD_THRESHOLDS[index]):
			tier_index = index
	var next_threshold := 0
	var next_label := ""
	for index in CLUTCH_REWARD_THRESHOLDS.size():
		if safe_streak < int(CLUTCH_REWARD_THRESHOLDS[index]):
			next_threshold = int(CLUTCH_REWARD_THRESHOLDS[index])
			next_label = String(CLUTCH_REWARD_LABELS[index])
			break
	var tier_label := String(CLUTCH_REWARD_LABELS[tier_index]) if tier_index >= 0 else "BUILDING"
	var milestone_label := ""
	for index in CLUTCH_REWARD_THRESHOLDS.size():
		if safe_streak == int(CLUTCH_REWARD_THRESHOLDS[index]):
			milestone_label = String(CLUTCH_REWARD_LABELS[index])
			break
	var compact := "CLEAN ×%d" % safe_streak
	if next_threshold > 0 and milestone_label.is_empty():
		compact += "  → %d" % next_threshold
	else:
		compact += "  ·  %s" % tier_label
	return {
		"streak": safe_streak,
		"tier_index": tier_index,
		"tier_label": tier_label,
		"milestone_label": milestone_label,
		"next_threshold": next_threshold,
		"next_label": next_label,
		"complete": next_threshold == 0,
		"current_bonus_cents": mini(safe_streak, 8) * 35,
		"compact": compact,
		"accessible_text": (
			"Clean clutch %d. Maximum streak credit reached at $%.2f per egg."
			% [safe_streak, float(mini(safe_streak, 8) * 35) / 100.0]
			if next_threshold == 0 else
			"Clean clutch %d. Current streak credit is $%.2f per egg. Reach %d clean eggs for the %s milestone."
			% [safe_streak, float(mini(safe_streak, 8) * 35) / 100.0, next_threshold, next_label.capitalize()]
		),
	}


func _peck_assist_input_blocked() -> bool:
	return (
		(_campaign_ui != null and _campaign_ui.is_modal_open())
		or (_decision_host != null and _decision_host.visible)
		or (_day_review_scrim != null and _day_review_scrim.visible)
		or (_character_dialogue_ui != null and _character_dialogue_ui.is_blocking())
		or _feed_party_active
		or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
	)


func _publish_priority_peck_hold(status: Dictionary, reason_override := "") -> void:
	var state := StringName(String(status.get("window_state", "locked")))
	var visible_copy := "PECK HELD  ·  NOT READY"
	match state:
		&"spent":
			visible_copy = "PECK HELD  ·  0 CHARGES  >  DELIVER"
		&"waiting":
			visible_copy = "PECK HELD  ·  WAIT FOR WORK"
		&"used":
			visible_copy = "PECK HELD  ·  TRY NEXT FILE"
		&"missed", &"passed":
			visible_copy = "PECK HELD  ·  TRY NEXT FILE"
		&"not_ready":
			visible_copy = "PECK HELD  ·  BUILD TO %d%%" % int(status.get(
				"window_start",
				DepartmentSimulation.PECK_ASSIST_WINDOW_START,
			))
	var reason := reason_override.strip_edges()
	if reason.is_empty():
		reason = String(status.get(
			"reason",
			"Wait for the next available gold window, then try Priority Peck again.",
		)).strip_edges()
	if reason.is_empty():
		reason = "Wait for the next available gold window, then try Priority Peck again."
	_publish_status_copy(
		visible_copy,
		true,
		"Priority Peck held. %s" % reason,
	)


func _request_peck_assist_from_input() -> void:
	var worker_id := _routing_ui.focused_worker_id() if _routing_ui != null else -1
	# Selection is an input promise. Never spend a charge on a different hen
	# just because the selected file is early, finished, or already stamped.
	if worker_id >= 0:
		var selected_status := _simulation.peck_assist_status(worker_id)
		if not bool(selected_status.get("available", false)):
			_publish_priority_peck_hold(selected_status)
			if _audio_feedback != null:
				_audio_feedback.play_denied(&"peck_window")
			return
	else:
		worker_id = _simulation.recommended_peck_assist_worker_id()
	if worker_id < 0:
		_publish_status_copy(
			"PECK HELD  ·  WAIT FOR GOLD",
			true,
			"Priority Peck held. Wait for a seated hen's file meter to enter the gold window, then press E or A.",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"peck_window")
		return
	if _camera_controller != null:
		_camera_controller.focus_worker(worker_id)
	if _routing_ui != null:
		_routing_ui.arm_peck_result_focus_handoff(worker_id)
	_on_peck_assist_requested(worker_id)


func _on_peck_assist_requested(worker_id: int) -> void:
	if _peck_assist_input_blocked():
		if _routing_ui != null:
			_routing_ui.cancel_peck_result_focus_handoff("management_moment_blocked")
		_publish_status_copy(
			"PECK HELD  ·  FINISH OPEN FILE",
			true,
			"Priority Peck held. Finish or safely close the open management file, then return to the selected hen.",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"peck_rejected")
		return
	var preflight := _simulation.peck_assist_status(worker_id)
	if not bool(preflight.get("available", false)):
		if _routing_ui != null:
			_routing_ui.cancel_peck_result_focus_handoff("assist_unavailable")
		_publish_priority_peck_hold(preflight)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"peck_rejected")
		return
	var resumed_from_pause := _clock.speed_index == 0
	if resumed_from_pause:
		# Retain every ordinary speed guard and refresh. Preflight happens first, so
		# a stale or invalid shortcut can never start the simulation.
		_on_speed_button_pressed(1)
		if _clock.speed_index == 0:
			if _routing_ui != null:
				_routing_ui.cancel_peck_result_focus_handoff("clock_resume_failed")
			_publish_status_copy(
				"PECK HELD  ·  CLOCK PAUSED",
				true,
				"Priority Peck held. The live clock could not resume. Close the current reading surface or choose Resume, then try again.",
			)
			return
	_priority_peck_result_hold_until_msec = Time.get_ticks_msec() + PECK_FOCUS_RESULT_HOLD_MSEC
	_priority_peck_result_hold_worker_id = worker_id
	_priority_peck_result_hold_claim_id = int(preflight.get("claim_id", -1))
	_priority_peck_result_hold_kind = &"landed"
	var result := _simulation.perform_peck_assist(worker_id)
	if not bool(result.get("accepted", false)):
		if _routing_ui != null:
			_routing_ui.cancel_peck_result_focus_handoff("assist_rejected")
		if resumed_from_pause:
			_clock.set_speed(0)
		_priority_peck_result_audio_pending.erase(worker_id)
		_priority_peck_result_hold_until_msec = 0
		_priority_peck_result_hold_worker_id = -1
		_priority_peck_result_hold_claim_id = -1
		_priority_peck_result_hold_kind = &""
		_refresh_priority_peck_precision_focus(_simulation.snapshot())
		_publish_priority_peck_hold(
			_simulation.peck_assist_status(worker_id),
			String(result.get("reason", "Priority Peck could not be filed. Try the next gold window.")),
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"peck_rejected")
		return
	var rating := StringName(result.get("rating", &"steady"))
	if (
		int(_last_work_progress_action.get("worker_id", -1)) == worker_id
		and int(_last_work_progress_action.get("claim_id", -1)) == int(result.get("claim_id", -2))
	):
		# Complete the browser/debug cause -> outcome record without changing what
		# the rail click itself means. It remains false until this accepted action.
		_last_work_progress_action["economic_action_committed"] = true
		_last_work_progress_action["committed_action"] = "peck"
		_last_work_progress_action["result_rating"] = String(rating)
		_last_work_progress_action["result_progress_gain"] = float(result.get("progress_gain", 0.0))
		if _routing_ui != null:
			_last_work_progress_action["focus_handoff"] = _routing_ui.peck_result_focus_handoff_state()
	_priority_peck_focus_disarmed_worker_id = worker_id
	var worker_name := String(result.get("worker_name", "HEN")).to_upper()
	var progress_gain := int(roundf(float(result.get("progress_gain", 0.0))))
	var quality_points := absf(float(result.get("quality_modifier", 0.0))) * 100.0
	_ticker_label.text = "%s%s PECK  ·  %s  ·  FILE +%d%%  ·  RISK %s%.1f%%  ·  CHAIN x%d" % [
		("RESUMED  ·  " if resumed_from_pause else ""), String(rating).to_upper(), worker_name, progress_gain,
		("-" if float(result.get("quality_modifier", 0.0)) <= 0.0 else "+"), quality_points,
		int(result.get("streak", 0)),
	]
	if not String(result.get("workshop_effect", "")).is_empty():
		_ticker_label.text = "%s PECK · %s · FILE +%d%% · %s" % [String(rating).to_upper(), worker_name, progress_gain, String(result.workshop_effect)]
	var worker_view := _worker_views.get(worker_id) as ChickenView
	_priority_peck_result_audio_pending[worker_id] = {
		"rating": rating,
		"streak": int(result.get("streak", 0)),
	}
	if worker_view != null and is_instance_valid(worker_view):
		worker_view.play_peck_assist_feedback(rating)
	elif _audio_feedback != null:
		# Headless or departing-worker fallback still receives one semantic result
		# receipt even when no physical contact timeline can complete.
		_audio_feedback.play_peck_assist(rating, int(result.get("streak", 0)))
		_priority_peck_result_audio_pending.erase(worker_id)
	if _routing_ui != null:
		_routing_ui.play_peck_assist_result(worker_id, rating)
	_refresh_priority_peck_precision_focus(_simulation.snapshot())
	_first_clutch_record_assist(result)
	# A full Web save serializes the complete career and flushes browser storage.
	# Performing that work inside the semantic input callback made the E press
	# appear to hang on larger offices. The coordinator still bounds this routine
	# checkpoint to five seconds, while focus-out/close lifecycle saves remain
	# immediate. Native builds retain the original synchronous durability point.
	if OS.has_feature("web"):
		_queue_campaign_checkpoint("peck_assist")
	else:
		_save_campaign_checkpoint("peck_assist")


func _on_priority_peck_contact(
	worker_id: int,
	contact_index: int,
	rating: StringName
) -> void:
	if _audio_feedback != null:
		_audio_feedback.play_peck_contact(contact_index, rating)
		if contact_index == 2 and _priority_peck_result_audio_pending.has(worker_id):
			var pending := _priority_peck_result_audio_pending[worker_id]
			_audio_feedback.play_peck_assist(
				StringName(String(pending.get("rating", rating))),
				int(pending.get("streak", 0)),
			)
			_priority_peck_result_audio_pending.erase(worker_id)
	if _workstation_feedback != null:
		_workstation_feedback.pulse_peck_assist(worker_id, rating, contact_index == 2)
	if contact_index == 2 and _office_atmosphere != null:
		var worker_view := _worker_views.get(worker_id) as ChickenView
		if worker_view != null and is_instance_valid(worker_view):
			_office_atmosphere.pulse_egg_laid(
				worker_view.global_position + Vector3.UP * 0.9,
				&"golden" if rating == &"perfect" else &"sound",
			)


func _on_work_peck_contact(worker_id: int, contact_serial: int) -> bool:
	# Ambient contacts stay visual and allocation-free; the authored three-hit
	# Priority Peck remains the only work action that earns prominent audio/VFX.
	if _workstation_feedback != null:
		return _workstation_feedback.pulse_work_contact(worker_id, contact_serial)
	return false


func _on_lay_release_reached(_worker_id: int) -> void:
	if _audio_feedback != null:
		_audio_feedback.play_lay_release(&"sound")


func _on_staff_capacity_purchase_requested() -> void:
	_set_capacity_marker_context_revealed(true)
	var result := _simulation.purchase_staff_capacity()
	_handle_staffing_action_result(result, &"capacity_expanded")


func _on_facility_purchase_requested(facility_id: StringName) -> void:
	var result := _simulation.purchase_facility(facility_id)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"BUILD",
			"REVIEW GATE",
			String(result.get("reason", "Review the facility's cost, obligation, and unlock gate.")),
			"Facility requisition",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"facility")
		return
	_build_capital_planning_surfaces()
	# Reconcile the protected reserve and physical room from the same authoritative
	# mutation before holding the exact commissioning receipt over that room.
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Facility requisition installed."))
	if _audio_feedback != null:
		_audio_feedback.play_upgrade()
	_begin_capital_modal_hold()
	var blueprint_was_open := (
		_capital_blueprint_ui != null and bool(_capital_blueprint_ui.call("is_open"))
	)
	if not blueprint_was_open:
		_capital_blueprint_restore_flockwatch = _flockwatch_open
	_set_flockwatch_open(false)
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("hide_blueprint", false)
	var focus := _facility_focus_file(facility_id)
	if _camera_controller != null and not focus.is_empty():
		var focus_point_value: Vector3 = focus.get("point", EXPANDED_OVERVIEW_TARGET)
		_camera_controller.focus_point(
			focus_point_value,
			String(focus.get("label", "FACILITY COMMISSIONED")),
			0.45,
			float(focus.get("size", 11.5)),
		)
	var receipt := result.get("commissioning_receipt", result) as Dictionary
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_facility_purchase(
			result,
			_simulation.day,
		)
	)
	if _commissioning_reveal_ui != null:
		_commissioning_reveal_ui.call(
			"show_reveal",
			receipt,
			_prefers_reduced_motion(),
		)
	_set_capital_modal_interaction(true)
	_publish_web_diagnostic_state(_simulation.snapshot())
	_save_campaign_checkpoint("facility_purchased_%s" % String(facility_id))


func _facility_focus_file(facility_id: StringName) -> Dictionary:
	match facility_id:
		&"candling_rework_bay":
			return {"point": Vector3(10.10, 0.85, 2.30), "label": "CANDLING & REWORK BAY", "size": 9.5}
		&"farmer_brand_packing_annex":
			return {"point": PACKING_ANNEX_FOCUS, "label": "FARMER BRAND PACKING ANNEX", "size": 11.5}
		&"records_annex":
			return {"point": RECORDS_ANNEX_FOCUS, "label": "LAYING RECORDS ANNEX", "size": 11.5}
		&"farmgate_dispatch_depot":
			return {"point": FARMGATE_DISPATCH_DEPOT_FOCUS, "label": "FARMGATE DISPATCH DEPOT", "size": 13.0}
		&"farm_mutual_service_coop":
			return {"point": FARM_MUTUAL_SERVICE_COOP_FOCUS, "label": "FARM MUTUAL SERVICE COOP", "size": 11.5}
		&"farm_mutual_negotiation_room":
			return {"point": FARM_MUTUAL_NEGOTIATION_ROOM_FOCUS, "label": "GOLD NEGOTIATION ROOM", "size": 11.5}
		&"wellness_nest_room":
			return {"point": WELLNESS_NEST_FOCUS, "label": "WELLNESS NEST", "size": 11.5}
		&"training_roost":
			return {"point": TRAINING_ROOST_FOCUS, "label": "TRAINING ROOST", "size": 11.5}
		&"farmer_relations_gallery":
			return {"point": FARMER_RELATIONS_GALLERY_FOCUS, "label": "HARVEST CREDIT GALLERY", "size": 12.5}
		&"rooster_operations_office":
			return {"point": ROOSTER_OPERATIONS_OFFICE_FOCUS, "label": "ROOSTER OPERATIONS OFFICE", "size": 11.5}
		&"it_coop":
			return {"point": IT_COOP_FOCUS, "label": "IT COOP", "size": 11.5}
		&"flock_relations_office":
			return {"point": FLOCK_RELATIONS_OFFICE_FOCUS, "label": "FLOCK RELATIONS OFFICE", "size": 11.5}
		&"feed_procurement_coop":
			return {"point": FLOCK_PROVISIONS_COOP_FOCUS, "label": "FLOCK PROVISIONS CO-OP", "size": 11.5}
	return {}


func _on_feed_order_requested(order_id: StringName) -> void:
	var result := _simulation.authorize_feed_order(order_id)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"PROVISIONS",
			"REVIEW LOT",
			String(result.get("reason", "Review the lot price, capacity, and timing.")),
			"Provisions order",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"provisions")
		return
	var order_target := find_child(
		"FeedProcurementOrder_%s" % String(order_id),
		true,
		false,
	) as Control
	_play_fund_debit_from_result(
		result,
		&"feed_procurement",
		StringName("feed_order_%s" % String(order_id)),
		order_target,
	)
	# The inventory room, reserve projection, and Flockwatch receipt all reconcile
	# from the same authoritative order before the camera visits the new delivery.
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Provisions order authorized."))
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_feed_order(result, _simulation.day)
	)
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	# The stock receipt is already durable in Operations; now reveal the physical
	# consequence. Collapse only that inline ledger so the delivered sacks and
	# hopper change are readable, without introducing a second modal or input mode.
	if _flockwatch_open:
		_set_flockwatch_open(false)
	if _camera_controller != null:
		_camera_controller.show_event_focus(
			FLOCK_PROVISIONS_COOP_FOCUS,
			"PROVISIONS DELIVERY FILED",
			1.35,
			true,
		)
	_save_campaign_checkpoint("feed_order_%s" % String(order_id))


func _on_farmgate_dispatch_mandate_requested(mandate_id: StringName) -> void:
	var result := _simulation.authorize_farmgate_dispatch(mandate_id)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"FARMGATE",
			"REVIEW MANDATE",
			String(result.get("reason", "Review the current dispatch mandate and inventory.")),
			"Farmgate mandate",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"farmgate")
		return
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Farmgate dispatch mandate filed."))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	# Filing happens inside the Farmgate ledger. Keep that reading context stable;
	# the depot camera remains useful only for authorizations made from the floor.
	if _camera_controller != null and not _flockwatch_open:
		_camera_controller.show_event_focus(
			FARMGATE_DISPATCH_DEPOT_FOCUS,
			"FARMGATE ROUTE FILED",
			1.35,
			true,
		)
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_farmgate_dispatch(result, _simulation.day)
	)
	_save_campaign_checkpoint("farmgate_dispatch_%s" % String(mandate_id))


func _on_farmer_relations_campaign_requested(campaign_id: StringName) -> void:
	if not _simulation.has_method("file_farmer_relations_campaign"):
		_publish_economic_action_hold(
			"GALLERY",
			"REVIEW CAMPAIGN",
			"Public-credit authorization is unavailable for the current filing.",
			"Gallery campaign",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"gallery_unavailable")
		return
	var result_value: Variant = _simulation.call("file_farmer_relations_campaign", campaign_id)
	var result := result_value as Dictionary if result_value is Dictionary else {}
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"GALLERY",
			"REVIEW CAMPAIGN",
			String(result.get("reason", "Review the closed-shift public-credit terms.")),
			"Gallery campaign",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"gallery_campaign")
		return
	# Keep the player in Flockwatch. The three authored cards are persistent
	# controls, so applying the compact projection preserves ledger scroll while
	# replacing the open offer with its permanent receipt.
	var snapshot := _simulation.snapshot()
	_on_snapshot_changed(snapshot)
	_ticker_label.text = String(result.get("outcome", "Public campaign filed in the Gallery."))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	# Filing happens inside the ledger. Do not pull the camera away (which also
	# closes Flockwatch) while the player is reading the permanent receipt.
	if _camera_controller != null and not _flockwatch_open:
		_camera_controller.show_event_focus(
			FARMER_RELATIONS_GALLERY_FOCUS,
			"PUBLIC CREDIT HUNG",
			1.35,
		)
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_farmer_relations_campaign(
			result,
			_simulation.day,
		)
	)
	_save_campaign_checkpoint("farmer_relations_campaign_%s" % String(campaign_id))
	_publish_web_diagnostic_state(snapshot)
	if _continue_shift_button != null and _continue_shift_button.is_visible_in_tree():
		_continue_shift_button.call_deferred("grab_focus")


func _on_flock_relations_action_requested(case_id: int, action_id: StringName) -> void:
	var result := _simulation.resolve_flock_relations_case(case_id, action_id)
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"FLOCK CASE",
			"REVIEW TERMS",
			String(result.get("reason", "Review the current labor-case terms and available actions.")),
			"Flock Relations case",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"flock_relations")
		return
	_play_fund_debit_from_result(
		result,
		&"flock_relations",
		StringName("flock_relations_%d_%s" % [case_id, String(action_id)]),
		find_child("FlockRelationsLastResolution", true, false) as Control,
	)
	# Keep the player in the existing Flockwatch review flow. The refreshed
	# snapshot removes exactly the resolved case and files the permanent receipt;
	# no additional modal obscures the remaining labor docket.
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Flock Relations case filed."))
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_flock_relations_result(
			result,
			_simulation.day,
		)
	)
	_save_campaign_checkpoint("flock_relations_%s_case_%d" % [String(action_id), case_id])


func _on_staff_hire_requested(worker_id: int) -> void:
	var result := _simulation.hire_worker(worker_id)
	_handle_staffing_action_result(result, &"worker_hired")


func _on_manager_assignment_requested(manager_id: StringName, assignment_id: StringName) -> void:
	_handle_manager_action_result(_simulation.set_manager_assignment(manager_id, assignment_id))


func _on_manager_posture_requested(manager_id: StringName, posture_id: StringName) -> void:
	_handle_manager_action_result(_simulation.set_manager_posture(manager_id, posture_id))


func _on_manager_recruit_requested(candidate_id: StringName) -> void:
	_handle_manager_action_result(_simulation.recruit_manager(candidate_id))


func _on_intern_onboard_requested(candidate_id: StringName) -> void:
	_handle_internship_action_result(_simulation.onboard_intern(candidate_id))


func _on_intern_assignment_requested(
	candidate_id: StringName,
	assignment_id: StringName,
) -> void:
	_handle_internship_action_result(
		_simulation.assign_intern(candidate_id, assignment_id)
	)


func _on_intern_review_requested(
	candidate_id: StringName,
	resolution_id: StringName,
) -> void:
	_handle_internship_action_result(
		_simulation.resolve_intern_review(candidate_id, resolution_id)
	)


func _handle_internship_action_result(result: Dictionary) -> void:
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"ROTATION",
			"REVIEW CANDIDATE",
			String(result.get("reason", "Review the candidate, assignment, and available seat.")),
			"Internship rotation",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"internship")
		return
	var internship_action := StringName(String(result.get("action_id", "filing")))
	var candidate_id := StringName(String(result.get("candidate_id", "intern")))
	var internship_target_id := StringName(
		"%s_%s" % [String(internship_action), String(candidate_id)]
	)
	if internship_action == &"intern_review":
		internship_target_id = StringName("intern_review_%s_%s" % [
			String(candidate_id),
			String(result.get("resolution_id", "review")),
		])
	_play_fund_debit_from_result(
		result,
		&"internship",
		internship_target_id,
		find_child("InternCard_%s" % String(candidate_id), true, false) as Control,
	)
	var snapshot := _simulation.snapshot()
	_on_snapshot_changed(snapshot)
	_ticker_label.text = String(result.get("outcome", "Internship filing completed."))
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_internship_action(result)
	)
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	_save_campaign_checkpoint(
		"internship_%s_%s" % [
			String(result.get("action_id", "filing")),
			String(result.get("candidate_id", "intern")),
		]
	)


func _handle_manager_action_result(result: Dictionary) -> void:
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"MANAGEMENT",
			"REVIEW DIRECTIVE",
			String(result.get("reason", "Review the manager, posture, and available instruction.")),
			"Management filing",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"management")
		return
	var manager_action := StringName(String(result.get("action_id", "instruction")))
	var manager_id := StringName(String(result.get("manager_id", "rooster")))
	_play_fund_debit_from_result(
		result,
		&"management",
		StringName("%s_%s" % [String(manager_action), String(manager_id)]),
		find_child("ManagerRosterToggle", true, false) as Control,
	)
	var snapshot := _simulation.snapshot()
	_on_snapshot_changed(snapshot)
	_ticker_label.text = String(result.get("outcome", "Management instruction filed."))
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_manager_instruction(
			result,
			_simulation.day,
		)
	)
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	_save_campaign_checkpoint("manager_instruction_%s" % String(result.get("manager_id", "rooster")))


func _on_staff_release_requested(worker_id: int) -> void:
	var result := _simulation.release_worker(worker_id)
	_handle_staffing_action_result(result, &"worker_released")


func _handle_staffing_action_result(result: Dictionary, checkpoint_reason: StringName) -> void:
	if not bool(result.get("accepted", false)):
		_publish_economic_action_hold(
			"STAFFING",
			"REVIEW ROSTER",
			String(result.get("reason", "Review the roster, capacity, and available Feed Fund.")),
			"Staffing filing",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"staffing")
		return
	var debit_target: Control = null
	var debit_target_id := checkpoint_reason
	match checkpoint_reason:
		&"capacity_expanded":
			debit_target = find_child("PurchaseStaffCapacity", true, false) as Control
		&"worker_hired":
			var worker_id := int(result.get("worker_id", -1))
			debit_target_id = StringName("hire_worker_%d" % worker_id)
			debit_target = find_child("HireWorker_%d" % worker_id, true, false) as Control
		&"worker_released":
			debit_target_id = StringName(
				"release_worker_%d" % int(result.get("worker_id", -1))
			)
			debit_target = find_child("ReleaseWorkerButton", true, false) as Control
	_play_fund_debit_from_result(
		result,
		&"staffing",
		debit_target_id,
		debit_target,
	)
	# Reconcile immediately even when a future simulation implementation elects
	# not to emit a redundant snapshot for an already-paused planning action.
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Staffing file approved."))
	if _audio_feedback != null:
		match checkpoint_reason:
			&"capacity_expanded":
				_audio_feedback.play_upgrade()
			&"worker_hired":
				_audio_feedback.play_policy_stamp()
			_:
				_audio_feedback.play_decision_resolved()
	if checkpoint_reason == &"capacity_expanded" and _camera_controller != null:
		var capacity := _office_capacity_from_snapshot(_simulation.snapshot())
		if capacity > 0:
			_camera_controller.show_event_focus(
				desk_position(capacity - 1) + Vector3.UP * 1.0,
				"PERCH %d COMMISSIONED" % capacity,
				1.40,
				true,
			)
	if checkpoint_reason == &"capacity_expanded":
		_begin_capacity_commissioning_beat(result)
	_save_campaign_checkpoint(String(checkpoint_reason))


func _fresh_campaign_seed() -> int:
	# Native headless tests keep their canonical authored docket. Interactive
	# careers choose from a small, exhaustively testable set instead of an opaque
	# unbounded random seed, so replay variety remains fair and reproducible.
	if DisplayServer.get_name() == "headless":
		return int(CAREER_DOCKET_SEEDS[0])
	var docket_rng := RandomNumberGenerator.new()
	docket_rng.randomize()
	return int(CAREER_DOCKET_SEEDS[docket_rng.randi_range(0, CAREER_DOCKET_SEEDS.size() - 1)])


func _load_career_portfolio() -> void:
	if _career_portfolio_store == null:
		_career_portfolio_store = CareerPortfolioStoreScript.new()
	_career_portfolio_store.load_portfolio()
	_active_career_slot = _career_portfolio_store.active_slot_id()
	_career_profile = _career_portfolio_store.profile_for_slot(_active_career_slot)
	_campaign_store = CampaignSaveStoreScript.new(
		CareerPortfolioStoreScript.filename_for_slot(_active_career_slot)
	)


func _on_career_slot_changed(slot_id: StringName) -> void:
	if _campaign_ui == null or _campaign_ui.modal_state() != ProbationCampaignUI.VIEW_TITLE:
		return
	if not _career_portfolio_store.activate_slot(slot_id):
		_ticker_label.text = "ROOST HELD. %s" % _career_portfolio_store.last_error
		return
	_checkpoint_coordinator.discard_pending()
	_campaign_session_checkpoint_enabled = false
	_active_career_slot = slot_id
	_career_profile = _career_portfolio_store.profile_for_slot(slot_id)
	_campaign_store = CampaignSaveStoreScript.new(CareerPortfolioStoreScript.filename_for_slot(slot_id))
	_has_campaign_checkpoint_candidate = _campaign_store.has_save()
	_has_verified_campaign_checkpoint = false
	_show_campaign_title(_has_campaign_checkpoint_candidate)
	_set_campaign_modal_open(true)


func _on_career_identity_changed(identity_id: StringName) -> void:
	if not _career_portfolio_store.set_identity(_active_career_slot, identity_id):
		_ticker_label.text = "COOP IDENTITY HELD. %s" % _career_portfolio_store.last_error
		return
	_career_profile = _career_portfolio_store.profile_for_slot(_active_career_slot)
	if _office_storytelling != null:
		_office_storytelling.apply_career_profile(_career_profile)
	_show_campaign_title(_campaign_store.has_save())


func _on_replay_scenario_changed(scenario_id: StringName) -> void:
	_selected_replay_scenario_id = scenario_id
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _new_campaign_run_id(career_seed: int) -> String:
	return "run-%d-%d-%d" % [
		career_seed,
		int(Time.get_unix_time_from_system() * 1000.0),
		Time.get_ticks_usec(),
	]


func _legacy_campaign_run_id(campaign, simulation_data: Dictionary) -> String:
	# Older checkpoints did not carry an explicit campaign nonce. Their completed
	# authority is still stable across repeated final-review openings, so use a
	# deterministic migration identity until the next genuinely new file.
	return "legacy-%d-%s-%d-%d-%d" % [
		int(simulation_data.get("career_seed", 1701)),
		String(campaign.challenge_contract_id),
		int(campaign.total_eggs),
		int(campaign.total_credited_cents),
		int(campaign.completed_shifts),
	]


func _on_campaign_new_requested() -> void:
	# A new file is committed through CampaignSaveStore's verified temporary-file
	# transaction. Keeping the current primary in place until that commit succeeds
	# also lets the store refresh its recovery copy with the previous campaign.
	_routing_assignment_undo.clear()
	_tactical_route_planner.clear()
	_clear_adaptive_route_recovery()
	var had_prior_save := _campaign_store.has_save()
	var selected_challenge_id := CampaignStateScript.CHALLENGE_STANDARD_FILING
	if _campaign_ui != null and _campaign_ui.has_method("selected_challenge_contract_id"):
		selected_challenge_id = StringName(_campaign_ui.call("selected_challenge_contract_id"))
	var fresh_campaign = CampaignStateScript.new()
	if not fresh_campaign.select_challenge_contract(selected_challenge_id):
		push_error("Could not file the selected probation challenge contract: %s" % String(selected_challenge_id))
		return
	_campaign_state = fresh_campaign
	_senior_roost_state = SeniorRoostStateScript.new()
	_campaign_review_stage = &"active"
	_campaign_senior_roost = false
	_last_workday_report.clear()
	_character_dialogue_previous_snapshot.clear()
	if _character_dialogue_ui != null:
		_character_dialogue_ui.clear_session()
	var fresh_seed := DepartmentSimulation.replay_scenario_seed(_selected_replay_scenario_id)
	if fresh_seed not in CAREER_DOCKET_SEEDS:
		fresh_seed = _fresh_campaign_seed()
	var fresh_simulation := DepartmentSimulation.new(
		1701,
		INITIAL_CAMPAIGN_STAFF,
		fresh_seed,
	)
	var opening_result := fresh_simulation.configure_opening_challenge(
		fresh_campaign.challenge_contract_snapshot(),
	)
	if not bool(opening_result.get("accepted", false)):
		push_error(
			"Could not apply the selected opening economy: %s"
			% String(opening_result.get("reason", "unknown validation error"))
		)
		return
	if not _simulation.restore_save_state(fresh_simulation.export_save_state()):
		push_error("Could not reset the office simulation for a new probation file.")
		return
	_current_campaign_run_id = _new_campaign_run_id(fresh_seed)
	_reset_first_clutch(String(_player_preferences.get("guidance_mode", "full")) != "off")
	_prime_first_hen_prelude()
	_reset_campaign_session_visuals()
	_restore_campaign_interface_context(_default_campaign_interface_context())
	if not _save_campaign_checkpoint("new_campaign"):
		var save_error: String = _campaign_store.last_error
		# The fresh in-memory file is abandoned below. Do not let the coordinator
		# later retry it after the prior verified campaign has been restored.
		_checkpoint_coordinator.discard_pending()
		if had_prior_save:
			_load_campaign_checkpoint()
		else:
			_show_campaign_title(false)
			_set_campaign_modal_open(true)
		_publish_economic_action_hold(
			"NEW FILE",
			"RETRY SAVE",
			(
				"The replacement checkpoint could not be verified; "
				+ ("the prior valid coop file was restored. " if had_prior_save else "no unverified campaign was opened. ")
				+ save_error
			),
			"New campaign",
		)
		return
	_campaign_session_checkpoint_enabled = true
	_first_session_funnel.begin_new_file()
	_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
	_set_campaign_modal_open(false)
	_present_first_hen_prelude()


func _on_campaign_challenge_contract_changed(_contract_id: StringName) -> void:
	# Intake holds the simulation clock, so no snapshot tick will refresh the Web
	# accessibility mirror after an OptionButton change. Publish the presentation
	# choice immediately; CampaignState remains untouched until New is confirmed.
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campaign_title_intake_phase_changed(_phase: StringName) -> void:
	# Resume/new-file staging changes which controls and terms actually exist on
	# screen, so republish immediately while the paused intake has no simulation tick.
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campaign_presentation_state_changed() -> void:
	# Between-shift planning is paused, so choosing a milestone or reviewing a
	# confirmation-first Board Book cannot rely on a later simulation tick to
	# refresh either the visible global action or the Web mirror.
	if _simulation != null:
		var snapshot := _simulation.snapshot()
		_update_guidance(snapshot)
		_publish_web_diagnostic_state(snapshot)


func _on_campaign_report_filing_settled(_reveal_key: String, _instant: bool) -> void:
	# ProbationCampaignUI owns visual timing; the pooled audio layer owns mix,
	# limiter, autoplay, and focus behavior. Keeping the handoff semantic prevents
	# report snapshots from allocating players or layering duplicate cues.
	if _audio_feedback != null and _campaign_ui.modal_state() == ProbationCampaignUI.VIEW_REPORT:
		_audio_feedback.play_report_filed()


func _on_interaction_safety_presentation_changed() -> void:
	# A held irreversible filing is a reading pause, not merely a visual layer.
	# Preserve the player's selected pace while stopping authoritative ticks and
	# route progress until the choice is filed or safely canceled.
	var confirmation_open := _held_confirmation_open()
	if _clock != null:
		_clock.set_interaction_hold_active(confirmation_open or (_shift_challenge_ui != null and _shift_challenge_ui.visible) or (_flock_ties_ui != null and _flock_ties_ui.visible))
	if _held_confirmation_scrim != null:
		_held_confirmation_scrim.visible = confirmation_open
	if confirmation_open:
		_yield_transient_feedback_to(&"confirmation")
	_refresh_floor_input_context()
	if _simulation == null:
		return
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _on_campaign_continue_requested() -> void:
	match _campaign_ui.modal_state():
		ProbationCampaignUI.VIEW_TITLE:
			_load_campaign_checkpoint()
		ProbationCampaignUI.VIEW_REPORT:
			if _campaign_senior_roost:
				_continue_senior_roost_report()
				return
			if _campaign_state.is_milestone_choice_available():
				_publish_economic_action_hold(
					"NEXT SHIFT",
					"CHOOSE EDGE",
					"Choose one permanent probation edge before filing shift three.",
					"Next-shift filing",
				)
				return
			_open_contract_board_or_begin_next_shift()
		ProbationCampaignUI.VIEW_CONTRACT_BOARD:
			_continue_from_contract_board()
		ProbationCampaignUI.VIEW_FINAL:
			if _campaign_state.outcome == CampaignStateScript.OUTCOME_PASSED:
				_enter_senior_roost()


func _on_campaign_review_requisitions_requested() -> void:
	if (
		_campaign_ui == null
		or _campaign_ui.modal_state() != ProbationCampaignUI.VIEW_REPORT
		or _simulation == null
	):
		return
	var snapshot := _simulation.snapshot()
	if not bool(snapshot.get("staffing_planning_open", false)):
		_publish_economic_action_hold(
			"REQUISITIONS",
			"FINISH CREDIT",
			"Resolve every closing-credit file before changing the flock.",
			"Roost requisitions",
		)
		return
	_flockwatch_restore_campaign_report = true
	_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
	_set_campaign_modal_open(false)
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	_open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	_refresh_floor_input_context()
	_set_guidance(
		"NEXT: REVIEW REQUESTS / CLOSE FLOCKWATCH",
		&"files",
		"Report paused: review roost requisitions, then close Flockwatch to restore the filing.",
		&"capital",
	)
	_ticker_label.text = "ROOST REQUISITIONS OPEN. Perch, hire, and release decisions are permanent for this shift."


func _on_campaign_abandon_requested() -> void:
	_clock.set_speed(0)
	if not _save_campaign_checkpoint("returned_to_intake"):
		_publish_economic_action_hold(
			"RETURN",
			"RETRY SAVE",
			"The current coop file could not be safely shelved: %s" % _campaign_store.last_error,
			"Return to intake",
		)
		return
	_campaign_session_checkpoint_enabled = false
	_day_review_scrim.visible = false
	_decision_host.visible = false
	_set_flockwatch_open(false)
	_show_campaign_title(true)
	_set_campaign_modal_open(true)
	_ticker_label.text = "COOP FILE SAFELY SHELVED. Continue resumes the exact checkpoint; New Campaign requires confirmation."


func _on_market_contract_sign_requested(
	offer_id: StringName,
	clause_id: StringName = &"standard_terms",
	pricing_id: StringName = &"mutual_rate",
) -> void:
	var receipt := _simulation.sign_market_contract(offer_id, clause_id, pricing_id)
	_campaign_ui.show_contract_board(_simulation.snapshot())
	_set_campaign_modal_open(true)
	if not bool(receipt.get("accepted", false)):
		_publish_economic_action_hold(
			"BINDER",
			"REVIEW TERMS",
			String(receipt.get("reason", "The Farm Mutual binder could not be signed.")),
			"Farm Mutual binder",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"market_contract")
		return
	_ticker_label.text = String(receipt.get("outcome", "FARM MUTUAL BINDER SIGNED."))
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_market_contract_signed(
			receipt,
			_simulation.day,
		)
	)
	_queue_campaign_checkpoint("market_contract_signed")


func _on_market_contract_decline_requested() -> void:
	var receipt := _simulation.decline_market_contract()
	_campaign_ui.show_contract_board(_simulation.snapshot())
	_set_campaign_modal_open(true)
	if not bool(receipt.get("accepted", false)):
		_publish_economic_action_hold(
			"STANDARD BOOK",
			"REVIEW BOARD",
			String(receipt.get("reason", "The standard-book filing is unavailable.")),
			"Standard-book filing",
		)
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"market_contract")
		return
	_ticker_label.text = String(receipt.get("outcome", "STANDARD BOOK RETAINED."))
	_queue_campaign_checkpoint("market_contract_declined")


func _on_market_contract_settled_dialogue(result: Dictionary) -> void:
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.beat_for_market_contract_result(
			result,
			int(result.get("day", _simulation.day)),
		)
	)


func _on_campaign_milestone_requested(choice_id: StringName) -> void:
	if _campaign_senior_roost:
		if _senior_roost_state == null:
			_publish_economic_action_hold(
				"SENIOR FILE",
				"RETURN REVIEW",
				"The recurring career ledger is unavailable.",
				"Senior Roost filing",
			)
			return
		if _senior_roost_state.requires_annual_mandate():
			var mandate_receipt: Dictionary = _senior_roost_state.select_annual_mandate(
				choice_id,
				_senior_roost_state.current_year_number(),
			)
			if not bool(mandate_receipt.get("accepted", false)):
				_publish_economic_action_hold(
					"BOARD MANDATE",
					"REVIEW BOOK",
					String(mandate_receipt.get(
						"reason",
						"Choose one of the three frozen annual books.",
					)),
					"Board mandate",
				)
				_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
				return
			_campaign_review_stage = &"senior_quarter"
			_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
			_update_campaign_objectives_label()
			_save_campaign_checkpoint("senior_annual_mandate_selected")
			_ticker_label.text = "%s Choose this quarter's capital policy next." % String(
				mandate_receipt.get("outcome", "ANNUAL BOARD MANDATE FILED."),
			)
			if _audio_feedback != null:
				_audio_feedback.play_policy_stamp()
			return
		if not _senior_roost_state.requires_quarter_policy():
			_publish_economic_action_hold(
				"CAPITAL POLICY",
				"REVIEW QUARTER",
				"This Senior quarter already has a filed policy.",
				"Capital policy",
			)
			return
		var senior_receipt := _simulation.apply_senior_quarter_policy(choice_id)
		if not bool(senior_receipt.get("accepted", false)):
			_publish_economic_action_hold(
				"CAPITAL POLICY",
				"REVIEW DOCKET",
				String(senior_receipt.get(
					"reason",
					"Review the Senior Roost docket and choose an available policy.",
				)),
				"Capital policy",
			)
			_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
			return
		if not _senior_roost_state.record_quarter_policy(senior_receipt):
			push_error("Authoritative Senior policy receipt could not be recorded.")
			return
		_campaign_review_stage = &"senior_quarter"
		_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
		_update_campaign_objectives_label()
		_save_campaign_checkpoint("senior_quarter_policy")
		_ticker_label.text = String(senior_receipt.get("outcome", "SENIOR CAPITAL POLICY FILED."))
		return
	if not _campaign_state.choose_milestone(choice_id):
		_publish_economic_action_hold(
			"MILESTONE",
			"REVIEW EDGE",
			"This permanent requisition is not available for the current probation file.",
			"Probation milestone",
		)
		# The report may have optimistically highlighted a card before this
		# authoritative guard ran. Re-publish CampaignState immediately so a
		# stale, repeated, or scripted request can never masquerade as the filed
		# permanent milestone in presentation state.
		_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
		_update_campaign_objectives_label()
		return
	for unlock_value in _campaign_state.unlocked_feature_ids:
		_simulation.apply_campaign_unlock(StringName(unlock_value))
	_campaign_review_stage = &"probation"
	_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
	_update_campaign_objectives_label()
	_save_campaign_checkpoint("milestone_selected")
	_ticker_label.text = "MILESTONE APPROVED: %s is now permanent for this probation file." % String(choice_id).replace("_", " ").to_upper()
	_refresh_commendations_from_authority()


func _on_career_sponsorship_requested(worker_id: int, lane_id: StringName) -> void:
	if not _campaign_senior_roost or _senior_roost_state == null:
		_publish_economic_action_hold(
			"SPONSORSHIP",
			"OPEN SENIOR ROOST",
			"Career credentials are filed only in Senior Roost.",
			"Sponsorship",
		)
		return
	var simulation_preflight := _simulation.career_sponsorship_preflight(worker_id, lane_id)
	if not bool(simulation_preflight.get("available", false)):
		_publish_economic_action_hold(
			"SPONSORSHIP",
			"REVIEW HEN",
			String(simulation_preflight.get(
				"reason",
				"The selected hen or training tray is no longer eligible.",
			)),
			"Sponsorship",
		)
		_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
		return
	var primary_lane := StringName(String(simulation_preflight.get("primary_specialty", "")))
	var senior_preflight: Dictionary = _senior_roost_state.preflight_sponsorship(
		worker_id,
		primary_lane,
		lane_id,
	)
	if not bool(senior_preflight.get("available", senior_preflight.get("accepted", false))):
		_publish_economic_action_hold(
			"SPONSORSHIP",
			"REVIEW MARKS",
			String(senior_preflight.get(
				"reason",
				"Available Roost Marks could not authorize this credential.",
			)),
			"Sponsorship",
		)
		_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
		return

	# Both authoritative ledgers are preflighted while the campaign report keeps
	# simulation time frozen. The simulation receipt is then the exact evidence
	# committed by the Senior career ledger; no presentation-side currency or mark
	# value is ever edited directly.
	var simulation_receipt := _simulation.authorize_career_sponsorship(worker_id, lane_id)
	if not bool(simulation_receipt.get("accepted", false)):
		_publish_economic_action_hold(
			"SPONSORSHIP",
			"REVIEW FUND",
			String(simulation_receipt.get(
				"reason",
				"The protected Feed Fund changed before authorization.",
			)),
			"Sponsorship",
		)
		_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
		return
	var career_receipt := simulation_receipt.duplicate(true)
	career_receipt["primary_lane"] = String(career_receipt.get("primary_specialty", primary_lane))
	career_receipt["secondary_lane"] = String(career_receipt.get("target_lane", lane_id))
	career_receipt["fund_cost_cents"] = int(career_receipt.get("cost_cents", 0))
	var senior_commit: Dictionary = _senior_roost_state.commit_sponsorship(
		senior_preflight,
		career_receipt,
	)
	if not bool(senior_commit.get("accepted", false)):
		push_error("Career sponsorship simulation receipt could not be committed to the preflighted Senior ledger.")
		_publish_economic_action_hold(
			"SPONSORSHIP",
			"REVIEW RECOVERY",
			"The accepted training receipt could not enter the Senior ledger safely.",
			"Sponsorship ledger",
		)
		return

	_on_snapshot_changed(_simulation.snapshot())
	_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	if _camera_controller != null and _worker_views.has(worker_id):
		var worker_view := _worker_views[worker_id] as ChickenView
		if worker_view != null and is_instance_valid(worker_view):
			_camera_controller.show_event_focus(
				worker_view.global_position + Vector3.UP * 0.95,
				"CAREER SPONSORSHIP FILED",
				0.95,
			)
	_ticker_label.text = String(simulation_receipt.get(
		"outcome",
		"CAREER SPONSORSHIP FILED. One training shift precedes the permanent credential.",
	))
	_save_campaign_checkpoint("career_sponsorship_authorized")


func _enter_senior_roost() -> void:
	if _senior_roost_state == null:
		_senior_roost_state = SeniorRoostStateScript.new()
	if not _senior_roost_state.is_active():
		var last_completed_day := int(_last_workday_report.get(
			"day",
			maxi(0, _simulation.day - 1),
		))
		if not _senior_roost_state.begin(last_completed_day, _simulation.snapshot()):
			_publish_economic_action_hold(
				"SENIOR ROOST",
				"RETRY REVIEW",
				"The career ledger could not be initialized safely.",
				"Senior Roost",
			)
			return
	_campaign_senior_roost = _senior_roost_state.is_active()
	_show_senior_roost_report("senior_roost_entered")
	_ticker_label.text = "SENIOR ROOST OPEN. Choose one annual Board Mandate, then file the first quarter's capital policy."
	_refresh_commendations_from_authority()


func _continue_senior_roost_report() -> void:
	if _senior_roost_state == null or not _senior_roost_state.is_active():
		_publish_economic_action_hold(
			"SENIOR ROOST",
			"RETURN REVIEW",
			"No active career ledger is available.",
			"Senior Roost",
		)
		return
	match _senior_roost_state.status:
		SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
			if _senior_roost_state.requires_annual_mandate():
				_publish_economic_action_hold(
					"NEXT QUARTER",
					"CHOOSE MANDATE",
					"Choose one frozen year-long book before filing the Q1 policy.",
					"Next-quarter filing",
				)
			else:
				_publish_economic_action_hold(
					"NEXT QUARTER",
					"CHOOSE POLICY",
					"Choose one available capital tradeoff before opening the quarter.",
					"Next-quarter filing",
				)
			return
		SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
			var passed := bool(_senior_roost_state.last_annual_review.get("passed", false))
			var transition := _simulation.apply_senior_year_transition(passed)
			if not bool(transition.get("accepted", false)):
				_publish_economic_action_hold(
					"ANNUAL FILE",
					"REVIEW CLOSE",
					String(transition.get(
						"reason",
						"Review the annual settlement before opening the next Senior year.",
					)),
					"Senior annual transition",
				)
				return
			if not _senior_roost_state.continue_after_annual(_simulation.snapshot()):
				push_error("Senior annual review could not advance after an accepted transition.")
				return
			_show_senior_roost_report("senior_year_transition")
			_ticker_label.text = String(transition.get("outcome", "NEXT SENIOR YEAR OPEN."))
		SeniorRoostStateScript.STATUS_ACTIVE:
			_open_contract_board_or_begin_next_shift()
		_:
			_publish_economic_action_hold(
				"SENIOR ROOST",
				"REVIEW CAREER",
				"The career ledger is not ready to continue.",
				"Senior Roost",
			)


func _show_senior_roost_report(checkpoint_reason: String = "senior_roost_report") -> void:
	_campaign_review_stage = (
		&"senior_annual"
		if _senior_roost_state != null and _senior_roost_state.status == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW else
		&"senior_quarter"
	)
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
	_set_campaign_modal_open(true)
	_update_campaign_objectives_label()
	_save_campaign_checkpoint(checkpoint_reason)


func _begin_next_shift_from_campaign() -> void:
	var pending := _simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) in [&"credit_allocation", &"major_event"]:
		_campaign_review_stage = &"credit"
		_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
		_set_campaign_modal_open(false)
		_simulation.announce_pending_decision()
		_queue_campaign_checkpoint("credit_memo_required")
		return
	_campaign_review_stage = &"active"
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
	_set_campaign_modal_open(false)
	if not _simulation.begin_next_shift_briefing():
		_publish_economic_action_hold(
			"NEXT SHIFT",
			"FINISH REVIEW",
			"Finish the farmer review before filing another morning briefing.",
			"Next-shift filing",
		)
		return
	_update_campaign_objectives_label()
	_queue_campaign_checkpoint("next_shift_briefing")


func _open_contract_board_or_begin_next_shift() -> void:
	var board := _simulation.market_contract_board_status()
	if not bool(board.get("unlocked", false)):
		_begin_next_shift_from_campaign()
		return
	_campaign_review_stage = &"contract_board"
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	_campaign_ui.show_contract_board(_simulation.snapshot())
	_set_campaign_modal_open(true)
	_update_campaign_objectives_label()
	_queue_campaign_checkpoint("market_contract_board")


func _continue_from_contract_board() -> void:
	var board := _simulation.market_contract_board_status()
	var active := board.get("active", {}) as Dictionary
	var declined := board.get("decline_receipt", {}) as Dictionary
	if active.is_empty() and declined.is_empty():
		_publish_economic_action_hold(
			"FARM MUTUAL",
			"CHOOSE BINDER",
			"Sign one disclosed binder or explicitly keep the standard book.",
			"Farm Mutual filing",
		)
		return
	_begin_next_shift_from_campaign()


func _show_campaign_final_review() -> void:
	_campaign_review_stage = &"final"
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	_archive_current_campaign_run()
	if _office_storytelling != null:
		_office_storytelling.apply_scenario_mastery(_career_run_archive.comparison())
	if _audio_feedback != null and _audio_feedback.has_method("play_campaign_outcome"):
		_audio_feedback.call(
			"play_campaign_outcome",
			_campaign_state.outcome == CampaignStateScript.OUTCOME_PASSED,
		)
	_campaign_ui.show_final_review(_campaign_presentation_snapshot(&"final"))
	_set_campaign_modal_open(true)
	_save_campaign_checkpoint("final_review")


func _archive_current_campaign_run() -> bool:
	if _campaign_state == null or _campaign_state.outcome == CampaignStateScript.OUTCOME_IN_PROGRESS:
		return false
	var scenario := _simulation.scenario_identity_snapshot()
	var hearing := _simulation.final_hearing_snapshot()
	var contract := _campaign_state.challenge_contract_snapshot()
	var doctrine := _campaign_state.active_doctrine()
	var mastery := _simulation.incident_pivot_mastery_snapshot()
	if _current_campaign_run_id.is_empty():
		_current_campaign_run_id = _legacy_campaign_run_id(
			_campaign_state,
			_simulation.export_save_state(),
		)
	return _career_run_archive.record({
		"run_id": _current_campaign_run_id,
		"scenario_id": String(scenario.get("id", "baseline_book")),
		"scenario_label": String(scenario.get("name", "BASELINE BOOK")),
		"contract_id": String(contract.get("id", "standard_filing")),
		"contract_label": String(contract.get("short_label", "STANDARD")),
		"doctrine_id": String(_campaign_state.chosen_milestone_id),
		"doctrine_label": String(doctrine.get("label", "UNFILED ROOST")),
		"hearing_choice_id": String(hearing.get("option_id", "unfiled")),
		"hearing_choice_label": String(hearing.get("option_label", "UNFILED")),
		"score": _campaign_state.probation_score,
		"welfare": _campaign_state.average_welfare(),
		"compliance": _campaign_state.average_compliance(),
		"farmer_favor": _campaign_state.average_farmer_favor(),
		"crack_rate_basis_points": _campaign_state.cumulative_crack_rate_basis_points(),
		"mastered_pairs": int(mastery.get("mastered_count", 0)),
		"passed": _campaign_state.outcome == CampaignStateScript.OUTCOME_PASSED,
	})


## A compact, derived epilogue for the organization itself. Endings already
## settle the farmer and flock ledgers; this makes the lasting office change
## legible without creating another save field or another management screen.
func _campaign_future_snapshot(
	ending: Dictionary,
	leadership_record: Dictionary,
	flock_epilogue: Array,
) -> Dictionary:
	var ending_id := StringName(ending.get("id", &""))
	var title := "OFFICE FUTURE"
	var value := "FILE REOPENS"
	var detail := "The bureau remains operational, but the next rooster inherits every unresolved filing."
	match ending_id:
		&"farmer_favorite":
			value = "QUOTAS EXPAND"
			detail = "Farm Mutual adds capacity and a harder target. The clean deck becomes the new baseline."
		&"benevolent_rooster":
			value = "CARE ENDURES"
			detail = "Recovery time and support stay in the operating plan, even after their cost enters the permanent record."
		&"collective_bargaining":
			value = "FLOCK HAS LEVERAGE"
			detail = "The hens keep a voice in future rankings, credit filings, and working conditions."
		&"probation_terminated":
			value = "DESKS REMEMBER"
			detail = "The badge changes hands, but the flock keeps the record of what happened under this rooster."
		&"probationary_rooster":
			value = "SCRUTINY RISES"
			detail = "The bureau continues under a tighter review and an unfinished leadership file."
		_:
			if bool(ending.get("passed", false)):
				value = "SENIOR ROOST OPENS"
				detail = "This management record now shapes a larger office with more expensive consequences."
	var leadership_title := String(leadership_record.get("title", "")).strip_edges()
	if not leadership_title.is_empty():
		detail += " Leadership record: %s." % leadership_title
	if not flock_epilogue.is_empty() and flock_epilogue[0] is Dictionary:
		var first_hen := flock_epilogue[0] as Dictionary
		var worker_name := String(first_hen.get("worker_name", "")).strip_edges()
		if not worker_name.is_empty():
			detail += " %s will carry that consequence forward." % worker_name
	return {
		"title": title,
		"value": value,
		"detail": detail,
	}


func _campaign_market_forecast(visible: bool) -> Dictionary:
	if _simulation == null:
		return {"visible": false}
	var briefing := _simulation.economic_briefing_snapshot()
	var market := briefing.get("market", {}) as Dictionary
	var current := market.get("current", {}) as Dictionary
	var next := market.get("next", {}) as Dictionary
	if market.is_empty() or current.is_empty():
		return {"visible": false}
	# Keep the campaign presentation bounded. The simulation remains the sole
	# authority for market timing and prices; the report only receives the facts
	# needed for one glance row plus its assistive explanation.
	return {
		"visible": visible,
		"day": int(briefing.get("day", _simulation.day)),
		"season_label": String(current.get("label", "BASELINE NEUTRAL BOOK")),
		"season_short_label": String(current.get("short_label", "BASELINE BOOK")),
		"days_remaining": int(market.get("current_days_remaining", 0)),
		"cause": String(market.get("current_cause", current.get("summary", "Farm Mutual's filed calendar sets demand."))),
		"certainty": String(market.get("forecast_certainty", "FILED CALENDAR")),
		"uncertainty": String(market.get("forecast_uncertainty", "Individual file intake can still vary.")),
		"opportunity_lane_id": String(market.get("opportunity_lane_id", "")),
		"opportunity_lane_label": String(market.get("opportunity_lane_label", "FILES")),
		"opportunity_demand_basis_points": int(market.get("opportunity_demand_basis_points", 0)),
		"feed_spot_unit_price_cents": int(market.get("feed_spot_unit_price_cents", 0)),
		"next_market_day": int(market.get("next_market_day", 0)),
		"next_season_label": String(next.get("label", "BASELINE NEUTRAL BOOK")),
		"next_season_short_label": String(next.get("short_label", "BASELINE BOOK")),
		"next_opportunity_lane_label": String(market.get("next_opportunity_lane_label", "FILES")),
		"next_opportunity_demand_basis_points": int(market.get("next_opportunity_demand_basis_points", 0)),
		"next_feed_spot_unit_price_cents": int(market.get("next_feed_spot_unit_price_cents", 0)),
	}


func _compose_shift_continuity(day: int) -> Dictionary:
	return ShiftContinuityScript.compose(
		_last_workday_report, day, _simulation.quota_target,
		CampaignStateScript.shift_chapter(day), _campaign_state.active_doctrine(), _personal_goal,
	)


func _campaign_presentation_snapshot(view: StringName) -> Dictionary:
	if _campaign_senior_roost and _senior_roost_state != null and _senior_roost_state.is_active():
		return _senior_presentation_snapshot(view)
	var completed := int(_campaign_state.completed_shifts)
	var campaign_day := clampi(completed + 1, 1, CampaignStateScript.CAMPAIGN_LENGTH)
	var next_campaign_day := campaign_day
	if view == &"between_shift":
		campaign_day = clampi(completed, 1, CampaignStateScript.CAMPAIGN_LENGTH)
		next_campaign_day = clampi(completed + 1, 1, CampaignStateScript.CAMPAIGN_LENGTH)
	elif view == &"final":
		campaign_day = clampi(completed, 1, CampaignStateScript.CAMPAIGN_LENGTH)
		next_campaign_day = campaign_day
	var objectives: Array[Dictionary] = _campaign_state.current_objectives()
	var objective_lines: Array[String] = []
	for objective in objectives:
		objective_lines.append("- %s: %s" % [
			String(objective.get("title", "Order")),
			String(objective.get("description", "Awaiting a measurable target.")),
		])
	var next_objective := {
		"title": (
			"Day %d probation orders" % next_campaign_day
			if not objectives.is_empty() else
			"Probation file complete"
		),
		"description": (
			"\n".join(objective_lines)
			if not objective_lines.is_empty() else
			"The permanent coop record is ready for final review."
		),
		"orders": objectives.duplicate(true),
		"reward_score": 3,
		"reward": "Complete all three orders for a +3 score bundle.",
		"promotion_opportunity": CampaignStateScript.promotion_opportunity_for_reward(
			_campaign_state.probation_score,
			3,
		),
	}
	if view == &"between_shift" and completed < CampaignStateScript.CAMPAIGN_LENGTH:
		_shift_continuity = _compose_shift_continuity(next_campaign_day)
		next_objective["title"] = _shift_continuity["title"]
		next_objective["continuity"] = _shift_continuity["summary"]
	var raw_milestones: Array = []
	if completed == CampaignStateScript.MILESTONE_AFTER_SHIFT and view == &"between_shift":
		raw_milestones = _campaign_state.milestone_catalog()
	else:
		raw_milestones = _campaign_state.available_milestone_choices()
	var milestone_cards: Array[Dictionary] = []
	for milestone in raw_milestones:
		var doctrine := milestone.get("doctrine", {}) as Dictionary
		milestone_cards.append({
			"id": String(milestone.get("id", "")),
			"title": String(milestone.get("title", "Milestone")),
			"description": String(milestone.get("description", "Permanent probation benefit.")),
			"effect": _milestone_effect_text(milestone.get("effects", {}) as Dictionary),
			"doctrine": doctrine.duplicate(true),
		})
	var final_evaluation := _campaign_state.final_evaluation()
	var safeguard_forecast := _campaign_state.probation_safeguard_forecast()
	var challenge_contract: Dictionary = _campaign_state.challenge_contract_snapshot()
	var active_doctrine: Dictionary = _campaign_state.active_doctrine()
	var leadership_record := _simulation.leadership_record_snapshot()
	var ending := _simulation.campaign_ending_snapshot(bool(final_evaluation.get("passed", false)))
	var flock_epilogue: Array = _simulation.campaign_flock_epilogue()
	var chapter := CampaignStateScript.shift_chapter(campaign_day)
	var momentum_brief := _campaign_state.momentum_brief()
	var replay_recommendation := _campaign_state.replay_recommendation()
	var final_hearing := _simulation.final_hearing_snapshot()
	var run_history := _career_run_archive.comparison()
	var rival_coop := _simulation.rival_coop_snapshot(_campaign_state.probation_score, completed)
	var legacy_title := String(active_doctrine.get(
		"label",
		leadership_record.get("title", "UNFILED ROOST"),
	)).to_upper()
	var legacy_detail := String(active_doctrine.get(
		"summary",
		leadership_record.get(
			"description",
			"The permanent record could not identify one consistent management style.",
		),
	))
	var campaign_legacy := {
		"title": legacy_title,
		"detail": legacy_detail,
		"doctrine_id": String(_campaign_state.chosen_milestone_id),
		"leadership_id": String(leadership_record.get("id", "unfiled")),
	}
	var score_receipt := _campaign_state.latest_score_receipt()
	var strategy_receipt := (
		_campaign_strategy_receipt(completed)
		if view in [&"between_shift", &"final"] else
		{}
	)
	var hen_highlight := _campaign_hen_highlight(completed)
	var final_message := String(final_evaluation.get("reason", _campaign_state.final_reason))
	if view == &"final":
		final_message = "%s\n\n%s\n\nFARMER'S EVALUATION\n%s" % [
			String(ending.get("coda", "The final ledger has been filed.")),
			String(ending.get("consequence", "")),
			final_message,
		]
		if StringName(leadership_record.get("id", &"unfiled")) != &"unfiled":
			final_message += "\n\nLEADERSHIP RECORD  //  %s\n%s" % [
				String(leadership_record.get("title", "UNFILED STYLE")),
				String(leadership_record.get("description", "")),
			]
	return {
		"view": view,
		"status": "SENIOR ROOST" if _campaign_senior_roost else "PROBATION",
		"day": campaign_day,
		"total_days": CampaignStateScript.CAMPAIGN_LENGTH,
		"score": _campaign_state.probation_score,
		"rank": CampaignStateScript.rank_display_name(_campaign_state.probation_rank),
		"rank_progress": CampaignStateScript.rank_progress_for_score(
			_campaign_state.probation_score,
		),
		"challenge_contract": challenge_contract,
		"chapter": chapter,
		"momentum_brief": momentum_brief,
		"replay_recommendation": replay_recommendation,
		"final_hearing": final_hearing,
		"run_history": run_history,
		"rival_coop": rival_coop,
		"career_profile": _career_profile.duplicate(true),
		"active_career_slot": String(_active_career_slot),
		"campaign_legacy": campaign_legacy,
		"flock_epilogue": flock_epilogue,
		"campaign_future": _campaign_future_snapshot(ending, leadership_record, flock_epilogue),
		"ledgers": [
			{
				"label": "Flock welfare",
				"value": _campaign_state.average_welfare(),
				"format": "percent",
				"detail": "FIVE-SHIFT AVERAGE",
			},
			{
				"label": "Coop obedience",
				"value": _campaign_state.average_compliance(),
				"format": "percent",
				"detail": "FIVE-SHIFT AVERAGE",
			},
			{
				"label": "Farmer favor",
				"value": _campaign_state.average_farmer_favor(),
				"format": "percent",
				"detail": "$%.2f CREDIT HARVESTED" % (_campaign_state.total_credited_cents / 100.0),
			},
		],
		"next_objective": next_objective,
		"milestone_choices": milestone_cards,
		"selected_milestone": String(_campaign_state.chosen_milestone_id),
		"active_doctrine": active_doctrine,
		"credit_memo": _simulation.last_credit_allocation.duplicate(true),
		"score_receipt": score_receipt,
		"strategy_receipt": strategy_receipt,
		"market_forecast": _campaign_market_forecast(
			view == &"between_shift"
			and completed < CampaignStateScript.CAMPAIGN_LENGTH
		),
		"probation_safeguard_forecast": safeguard_forecast,
		"hen_highlight": hen_highlight,
		"leadership_record": leadership_record,
		"ending": ending,
		"staffing_planning_open": bool(
			_simulation.snapshot().get("staffing_planning_open", false)
		),
		"passed": bool(final_evaluation.get("passed", false)),
		"final_message": final_message,
	}


func _senior_mandate_target_text(metric: String, comparison: String, value: int) -> String:
	var operator := "≥" if comparison == "minimum" else "≤"
	if metric.ends_with("basis_points"):
		return "%s %.1f%%" % [operator, float(value) / 100.0]
	if metric.ends_with("_cents") or metric == "credited_cents":
		return "%s $%.2f" % [operator, float(value) / 100.0]
	return "%s %d" % [operator, value]


func _senior_mandate_progress_lines(progress: Dictionary) -> Array[String]:
	var lines: Array[String] = [
		"%d / %d shifts · %d / %d targets met · %d quarterly checkpoint%s filed" % [
			int(progress.get("shifts_recorded", 0)),
			int(progress.get("shifts_target", 12)),
			int(progress.get("objectives_met", 0)),
			int(progress.get("objectives_total", 0)),
			int(progress.get("quarter_checkpoints_filed", 0)),
			"" if int(progress.get("quarter_checkpoints_filed", 0)) == 1 else "s",
		],
	]
	for row_value in progress.get("objectives", []) as Array:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		lines.append("%s · %s  %s ACTUAL %s" % [
			"MET" if bool(row.get("met", false)) else "NEEDS ACTION",
			String(row.get("label", "BOARD TARGET")),
			_senior_mandate_target_text(
				String(row.get("metric", "")),
				String(row.get("comparison", "minimum")),
				int(row.get("target", 0)),
			),
			_senior_mandate_progress_value_text(
				String(row.get("metric", "")),
				int(row.get("actual", 0)),
			),
		])
	var blocker := progress.get("largest_recoverable_blocker", {}) as Dictionary
	if not blocker.is_empty():
		lines.append("LARGEST RECOVERABLE BLOCKER · %s · gap %s" % [
			String(blocker.get("label", "BOARD TARGET")),
			_senior_mandate_progress_value_text(
				String(blocker.get("metric", "")),
				int(blocker.get("gap", 0)),
			),
		])
	return lines


func _senior_mandate_progress_value_text(metric: String, value: int) -> String:
	if metric.ends_with("basis_points"):
		return "%.1f%%" % (float(value) / 100.0)
	if metric.ends_with("_cents") or metric == "credited_cents":
		return "$%.2f" % (float(value) / 100.0)
	return str(value)


func _campaign_hen_highlight(completed_shift: int) -> Dictionary:
	var report_day := int(_last_workday_report.get("day", 0))
	var highlight_value: Variant = _last_workday_report.get("hen_highlight", {})
	if report_day == completed_shift and highlight_value is Dictionary:
		var highlight := highlight_value as Dictionary
		if not highlight.is_empty():
			return highlight.duplicate(true)
	# Old session checkpoints already contain the closing pecking order, so they
	# can still show a factual leader card without changing campaign save schema.
	var raw_order: Variant = _last_workday_report.get("pecking_order", [])
	var closing_order: Array = raw_order as Array if raw_order is Array else []
	if closing_order.is_empty() and _simulation.last_pecking_order_day == completed_shift:
		closing_order = _simulation.last_pecking_order
	if report_day != 0 and report_day != completed_shift:
		return {}
	if closing_order.is_empty() or not closing_order[0] is Dictionary:
		return {}
	var row := closing_order[0] as Dictionary
	var worker_name := String(row.get("worker_name", "A peckwork hen"))
	var eggs := maxi(0, int(row.get("eggs", 0)))
	var credit_cents := maxi(0, int(row.get("credit_cents", 0)))
	return {
		"version": 1,
		"type": "ledger_leader",
		"day": completed_shift,
		"worker_id": int(row.get("worker_id", -1)),
		"worker_name": worker_name,
		"career_title": "PECKWORK HEN",
		"relationship_label": "CLOSING LEADER",
		"rank": maxi(1, int(row.get("rank", 1))),
		"eggs": eggs,
		"sound": maxi(0, int(row.get("sound", 0))),
		"cracked": maxi(0, int(row.get("cracked", 0))),
		"golden": maxi(0, int(row.get("golden", 0))),
		"credit_cents": credit_cents,
		"headline": "TODAY'S MODEL EMPLOYEE",
		"body": (
			"With every tray empty, employee number made %s #1. The ranking remained decisive."
			% worker_name
			if eggs == 0 else
			"%s finished #1 with $%.2f in credited output. The farmer praised the system that happened to contain her."
			% [worker_name, float(credit_cents) / 100.0]
		),
		"metric": "%d EGGS  //  %d SOUND  //  %d CRACKED  //  $%.2f CREDIT" % [
			eggs,
			maxi(0, int(row.get("sound", 0))),
			maxi(0, int(row.get("cracked", 0))),
			float(credit_cents) / 100.0,
		],
		"tone": "quality",
	}


func _milestone_effect_text(effects: Dictionary) -> String:
	var lines: Array[String] = []
	if effects.has("stress_gain_percent"):
		lines.append("Stress gain %d%%" % int(effects["stress_gain_percent"]))
	if effects.has("fatigue_gain_percent"):
		lines.append("Fatigue gain %d%%" % int(effects["fatigue_gain_percent"]))
	if effects.has("crack_risk_basis_points"):
		lines.append("Crack risk %.1f%%" % (int(effects["crack_risk_basis_points"]) / 100.0))
	if effects.has("egg_value_bonus_cents"):
		lines.append("+$%.2f per egg" % (int(effects["egg_value_bonus_cents"]) / 100.0))
	return "  /  ".join(lines)


func _first_hen_prelude_pending() -> bool:
	return (
		_campaign_state != null
		and int(_campaign_state.completed_shifts) == 0
		and _campaign_review_stage == &"active"
		and _simulation != null
		and _simulation.day == 1
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE
		and not bool(_first_clutch.get("dismissed", true))
		and not bool(_first_clutch.get("completed", false))
		and int(_first_clutch.get("target_worker_id", -1)) >= 0
		and not bool(_first_clutch.get("inspected", false))
	)


func _first_hen_policy_context_active() -> bool:
	return (
		_campaign_state != null
		and int(_campaign_state.completed_shifts) == 0
		and _campaign_review_stage == &"active"
		and _simulation != null
		and _simulation.day == 1
		and not bool(_first_clutch.get("dismissed", true))
		and int(_first_clutch.get("target_worker_id", -1)) >= 0
		and bool(_first_clutch.get("inspected", false))
	)


func _prime_first_hen_prelude() -> void:
	var snapshot := _simulation.snapshot()
	var featured_worker_id := FIRST_HEN_WORKER_ID
	if _first_clutch_worker_snapshot(snapshot, featured_worker_id).is_empty():
		featured_worker_id = -1
		for worker_value in snapshot.get("workers", []):
			var worker := worker_value as Dictionary
			if _is_worker_employed(worker):
				featured_worker_id = int(worker.get("id", -1))
				break
	if featured_worker_id < 0:
		return
	_first_clutch["target_worker_id"] = featured_worker_id


func _present_first_hen_prelude() -> void:
	if not _first_hen_prelude_pending():
		return
	var target_worker_id := int(_first_clutch.get("target_worker_id", FIRST_HEN_WORKER_ID))
	var snapshot := _simulation.snapshot()
	var worker := _first_clutch_worker_snapshot(snapshot, target_worker_id)
	if worker.is_empty():
		return
	var target_name := String(worker.get("name", "Mabel"))
	if _camera_controller != null:
		var worker_view := _worker_views.get(target_worker_id) as ChickenView
		if worker_view != null and is_instance_valid(worker_view):
			worker_view.stage_at_workstation_for_introduction()
			_camera_controller.focus_point(
				worker_view.global_position + Vector3.UP * 0.82,
				"%s // FIRST FILE" % target_name.to_upper(),
				0.42,
				FIRST_HEN_FOCUS_SIZE,
			)
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)
	_ticker_label.text = "%s is already at her desk. Open her file before choosing the flock policy." % target_name
	_publish_web_diagnostic_state(snapshot)


func _open_first_hen_file(worker_id: int, focus_camera: bool = true) -> void:
	if not _first_hen_prelude_pending():
		return
	var target_worker_id := int(_first_clutch.get("target_worker_id", -1))
	if worker_id != target_worker_id:
		return
	var snapshot := _simulation.snapshot()
	var worker := _first_clutch_worker_snapshot(snapshot, target_worker_id)
	if worker.is_empty():
		return
	_first_clutch["inspected"] = true
	if StringName(worker.get("assigned_lane", &"auto")) == StringName(worker.get("specialty", &"")):
		_first_clutch["specialty_routed"] = true
	if (
		int(worker.get("last_personnel_action_day", 0)) == _simulation.day
		and StringName(worker.get("last_personnel_action", &"")) != &""
	):
		_first_clutch["checkin_filed"] = true
		_first_clutch["checkin_worker_id"] = target_worker_id
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)
	_save_campaign_checkpoint("first_hen_file_opened")
	_publish_web_diagnostic_state(snapshot)
	if focus_camera and _camera_controller != null:
		_camera_controller.focus_worker(target_worker_id)
	if not bool(_first_clutch.get("route_first_lesson", false)):
		_queue_character_dialogue(CharacterDialogueCatalogScript.opening_beat(_simulation.day))
	_on_announcement_posted(
		"%s'S FILE IS OPEN: choose the policy that will govern her desk and today's clutch."
		% String(worker.get("name", "Mabel")).to_upper()
	)
	_simulation.announce_pending_decision()


func _on_first_clutch_skip_rect_settled(_rect: Rect2) -> void:
	if (
		not OS.has_feature("web")
		or bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("completed", false))
	):
		return
	# This one-shot layout fact can arrive while Office itself is paused. Retain
	# it immediately so the next browser request names the visible canvas target.
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_first_clutch_skip_requested() -> void:
	if bool(_first_clutch.get("dismissed", true)) or bool(_first_clutch.get("completed", false)):
		return
	_first_clutch["dismissed"] = true
	_first_clutch_completion_generation += 1
	_first_clutch_completion_hold_until_msec = 0
	_ticker_label.text = "FIRST CLUTCH COACH FILED AWAY. Every management control remains available."
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
	# The coach's Skip button may have owned GUI focus. Re-evaluate the live-floor
	# context immediately so camera navigation resumes in the same interaction.
	_refresh_floor_input_context()
	_refresh_flockwatch_navigation(snapshot)
	_update_guidance(snapshot)
	_save_campaign_checkpoint("first_clutch_skipped")
	_refresh_gameplay_pulse(snapshot)


func _on_first_clutch_focus_requested(worker_id: int) -> void:
	if _first_hen_prelude_pending():
		_open_first_hen_file(worker_id)
		return
	if (
		_camera_controller == null
		or bool(_first_clutch.get("dismissed", true))
		or worker_id != int(_first_clutch.get("target_worker_id", -1))
		or _first_clutch_worker_snapshot(_simulation.snapshot(), worker_id).is_empty()
	):
		return
	_set_flockwatch_open(false)
	_camera_controller.focus_worker(worker_id)
	_ticker_label.text = "INDUCTION FILE RESTORED. Continue with this hen's live dossier."


func _queue_campaign_checkpoint(reason: String) -> bool:
	# Ordinary production can mutate several times in one visual beat. Marking it
	# routine preserves a short quiet window while the hard maximum in the
	# coordinator still bounds potential loss during continuous production.
	if _should_bypass_campaign_title() and not _allow_automated_campaign_saves:
		return true
	if _campaign_state == null or _campaign_store == null:
		return false
	var was_dirty: bool = _checkpoint_coordinator.is_dirty()
	_checkpoint_coordinator.mark_routine(reason)
	if not was_dirty:
		_publish_checkpoint_diagnostic()
	return true


func _save_campaign_checkpoint(reason: String) -> bool:
	# Decisions, review transitions, onboarding safety points, and lifecycle exits
	# remain immediate. Headless regressions and art-capture launches still bypass
	# the player's native campaign unless a focused test supplies an isolated file.
	if _should_bypass_campaign_title() and not _allow_automated_campaign_saves:
		return true
	if _campaign_state == null or _campaign_store == null:
		return false
	_checkpoint_coordinator.mark_immediate(reason)
	return _flush_due_campaign_checkpoint()


func _flush_due_campaign_checkpoint() -> bool:
	var request: Dictionary = _checkpoint_coordinator.claim_due_save()
	if request.is_empty():
		return false
	_publish_checkpoint_diagnostic()
	var reason := String(request.get("reason", "unspecified"))
	var saved := _write_campaign_checkpoint(reason)
	_checkpoint_coordinator.complete_save(saved)
	if saved:
		_has_campaign_checkpoint_candidate = true
		_has_verified_campaign_checkpoint = true
		_checkpoint_last_error = ""
		_checkpoint_last_saved_reason = reason
		_checkpoint_last_saved_unix_msec = int(Time.get_unix_time_from_system() * 1000.0)
	else:
		_checkpoint_last_error = String(_campaign_store.last_error).strip_edges()
	_publish_checkpoint_diagnostic()
	return saved


func _write_campaign_checkpoint(reason: String) -> bool:
	var payload := {
		"campaign": _campaign_state.to_dictionary(),
		"simulation": _simulation.export_save_state(),
		"senior_roost": _senior_roost_state.to_dictionary(),
		"session": {
			"review_stage": String(_campaign_review_stage),
			"last_workday_report": _last_workday_report.duplicate(true),
			"senior_roost": _senior_roost_state.is_active(),
			"first_clutch": _first_clutch.duplicate(true),
			"personal_goal": _personal_goal.duplicate(true),
			"interface_context": _campaign_interface_context(),
			"run_archive": _career_run_archive.entries(),
			"current_run_id": _current_campaign_run_id,
			"career_profile": _career_profile.duplicate(true),
			"career_slot": String(_active_career_slot),
		},
	}
	var metadata := {
		"reason": reason,
		"day": _simulation.day,
		"completed_shifts": _campaign_state.completed_shifts,
		"probation_score": _campaign_state.probation_score,
		"probation_rank": String(_campaign_state.probation_rank),
		"challenge_contract_id": String(_campaign_state.challenge_contract_id),
		"review_stage": String(_campaign_review_stage),
		"senior_years": _senior_roost_state.completed_years,
		"roost_marks": _senior_roost_state.roost_marks,
		"career_slot": String(_active_career_slot),
		"career_identity_id": String(_career_profile.get("id", "open_nest")),
	}
	var safe_payload := _json_safe_variant(payload) as Dictionary
	var safe_metadata := _json_safe_variant(metadata) as Dictionary
	var saved := _campaign_store.save(safe_payload, safe_metadata)
	if not saved:
		push_warning("Campaign checkpoint failed (%s): %s" % [reason, _campaign_store.last_error])
	return saved


func _default_campaign_interface_context() -> Dictionary:
	return {
		"version": CAMPAIGN_INTERFACE_CONTEXT_VERSION,
		"flockwatch_page_id": String(FlockwatchNavigation.PAGE_TODAY),
		"show_all_filings": false,
		"capital_filter_id": String(CapitalBlueprintModelScript.FILTER_READY),
		"capital_facility_id": "",
		"status_history_expanded": false,
		"shift_help_expanded": false,
		"desk_requisitions_expanded": false,
		"commendations_expanded": false,
		"economic_details_expanded": false,
		"feed_offers_expanded": false,
		"farmgate_mandate_expanded": false,
		"farmgate_mandate_id": "farmer_pickup",
		"flock_relations_cases_expanded": false,
		"farmer_campaigns_expanded": false,
		"inline_facilities_expanded": false,
		"internship_program_expanded": false,
	}


func _campaign_interface_context() -> Dictionary:
	var context := _default_campaign_interface_context()
	if _flockwatch_navigation != null:
		context["flockwatch_page_id"] = String(_flockwatch_navigation.current_page_id())
		context["show_all_filings"] = _flockwatch_navigation.is_showing_all_filings()
	if _capital_blueprint_ui != null:
		context["capital_filter_id"] = String(
			_capital_blueprint_ui.call("active_filter_id")
		)
		context["capital_facility_id"] = String(
			_capital_blueprint_ui.call("selected_facility_id")
		)
	context["status_history_expanded"] = _status_history_expanded
	if _shift_help_disclosure_toggle != null:
		context["shift_help_expanded"] = _shift_help_disclosure_toggle.is_expanded()
	if _upgrade_disclosure_toggle != null:
		context["desk_requisitions_expanded"] = (
			_upgrade_disclosure_toggle.is_expanded()
		)
	if _commendations_disclosure_toggle != null:
		context["commendations_expanded"] = (
			_commendations_disclosure_toggle.is_expanded()
		)
	if _economic_briefing_ui != null:
		context["economic_details_expanded"] = bool(
			_economic_briefing_ui.call("details_expanded")
		)
	if _staffing_ui != null:
		var staffing_context: Dictionary = _staffing_ui.presentation_context()
		for field: String in [
			"feed_offers_expanded",
			"farmgate_mandate_expanded",
			"farmgate_mandate_id",
			"flock_relations_cases_expanded",
			"farmer_campaigns_expanded",
			"inline_facilities_expanded",
			"internship_program_expanded",
		]:
			context[field] = staffing_context.get(field, context.get(field))
	return context


func _validated_campaign_interface_context(value: Dictionary) -> Dictionary:
	var context := _default_campaign_interface_context()
	if value.has("version"):
		if typeof(value.get("version")) != TYPE_INT:
			return {"ok": false, "error": "session.interface_context.version must be an int"}
		if int(value.get("version")) not in [1, CAMPAIGN_INTERFACE_CONTEXT_VERSION]:
			return {"ok": false, "error": "session.interface_context.version is unsupported"}
	for field: String in [
		"show_all_filings",
		"status_history_expanded",
		"shift_help_expanded",
		"desk_requisitions_expanded",
		"commendations_expanded",
		"economic_details_expanded",
		"feed_offers_expanded",
		"farmgate_mandate_expanded",
		"flock_relations_cases_expanded",
		"farmer_campaigns_expanded",
		"inline_facilities_expanded",
		"internship_program_expanded",
	]:
		if not value.has(field):
			continue
		if typeof(value.get(field)) != TYPE_BOOL:
			return {
				"ok": false,
				"error": "session.interface_context.%s must be a bool" % field,
			}
		context[field] = bool(value.get(field))
	for field: String in [
		"flockwatch_page_id",
		"capital_filter_id",
		"capital_facility_id",
		"farmgate_mandate_id",
	]:
		if not value.has(field):
			continue
		if typeof(value.get(field)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {
				"ok": false,
				"error": "session.interface_context.%s must be a string" % field,
			}

	var page_id := StringName(String(value.get(
		"flockwatch_page_id",
		FlockwatchNavigation.PAGE_TODAY,
	)))
	if page_id in FlockwatchNavigation.PAGE_ORDER:
		context["flockwatch_page_id"] = String(page_id)
	var filter_id := StringName(String(value.get(
		"capital_filter_id",
		CapitalBlueprintModelScript.FILTER_READY,
	)))
	if filter_id in CapitalBlueprintModelScript.FILTER_ORDER:
		context["capital_filter_id"] = String(filter_id)
	var facility_id := StringName(String(value.get("capital_facility_id", "")))
	if facility_id == &"" or facility_id in CapitalBlueprintModelScript.FACILITY_ORDER:
		context["capital_facility_id"] = String(facility_id)
	var mandate_id := StringName(String(value.get(
		"farmgate_mandate_id",
		"farmer_pickup",
	)))
	if mandate_id in FarmgateDispatchUI.MANDATE_ORDER:
		context["farmgate_mandate_id"] = String(mandate_id)
	return {"ok": true, "error": "", "context": context}


func _restore_campaign_interface_context(context: Dictionary) -> void:
	var validated := _validated_campaign_interface_context(context)
	var restored := (
		validated.get("context", _default_campaign_interface_context()) as Dictionary
	)
	_applying_campaign_interface_context = true
	# A restored selection needs its controls; fresh default files stay lazy.
	if (
		String(restored.get("capital_filter_id", "ready")) != String(CapitalBlueprintModelScript.FILTER_READY)
		or not String(restored.get("capital_facility_id", "")).is_empty()
	):
		_build_capital_planning_surfaces()
	if _flockwatch_navigation != null:
		# Discovery belongs to the restored career, never to the disposable boot
		# simulation or a previously shelved career in this process.
		_flockwatch_navigation.reset_discovered_pages()
		_flockwatch_navigation.set_show_all_filings(
			bool(restored.get("show_all_filings", false))
		)
		var page_id := StringName(String(restored.get(
			"flockwatch_page_id",
			FlockwatchNavigation.PAGE_TODAY,
		)))
		if not _flockwatch_navigation.open_page(page_id):
			_flockwatch_navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("apply_snapshot", _simulation.snapshot())
		var filter_id := StringName(String(restored.get(
			"capital_filter_id",
			CapitalBlueprintModelScript.FILTER_READY,
		)))
		_capital_blueprint_ui.call("set_filter", filter_id)
		var facility_id := StringName(String(restored.get("capital_facility_id", "")))
		var visible_ids: Array = _capital_blueprint_ui.call("visible_facility_ids")
		if facility_id != &"" and facility_id in visible_ids:
			_capital_blueprint_ui.call("select_facility", facility_id, false)
	_on_status_history_toggled(bool(restored.get(
		"status_history_expanded",
		false,
	)))
	if _shift_help_disclosure_toggle != null:
		_shift_help_disclosure_toggle.set_expanded(
			bool(restored.get("shift_help_expanded", false))
		)
	if _upgrade_disclosure_toggle != null:
		_upgrade_disclosure_toggle.set_expanded(
			bool(restored.get("desk_requisitions_expanded", false))
		)
	if _commendations_disclosure_toggle != null:
		_commendations_disclosure_toggle.set_expanded(
			bool(restored.get("commendations_expanded", false))
		)
	if _economic_briefing_ui != null:
		_economic_briefing_ui.call(
			"set_details_expanded",
			bool(restored.get("economic_details_expanded", false)),
		)
	var defaults := _default_campaign_interface_context()
	for field: String in ["feed_offers_expanded", "farmgate_mandate_expanded", "farmgate_mandate_id",
		"flock_relations_cases_expanded", "farmer_campaigns_expanded", "inline_facilities_expanded", "internship_program_expanded"]:
		if restored.get(field) != defaults.get(field):
			_build_staffing_surface()
			break
	if _staffing_ui != null:
		_staffing_ui.restore_presentation_context(restored)
	_applying_campaign_interface_context = false


func _bounded_checkpoint_error(message: String) -> String:
	return message.strip_edges().replace("\n", " ").replace("\r", " ").substr(0, CHECKPOINT_ERROR_LIMIT)


func _publish_checkpoint_diagnostic() -> void:
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot(true))


func _load_campaign_checkpoint() -> void:
	_routing_assignment_undo.clear()
	_tactical_route_planner.clear()
	_clear_adaptive_route_recovery()
	var candidates: Array[Dictionary] = _campaign_store.load_recovery_candidates()
	if candidates.is_empty():
		_has_campaign_checkpoint_candidate = false
		_has_verified_campaign_checkpoint = false
		_checkpoint_last_error = _bounded_checkpoint_error(
			"No readable campaign checkpoint is available. %s" % _campaign_store.last_error
		)
		_show_campaign_title(false)
		_set_campaign_modal_open(true)
		_publish_economic_action_hold(
			"CONTINUE",
			"REVIEW RECOVERY",
			"No readable campaign checkpoint is available. %s" % _campaign_store.last_error,
			"Campaign continue",
		)
		_publish_checkpoint_diagnostic()
		return
	_has_campaign_checkpoint_candidate = true
	var semantic_errors: Array[String] = []
	var activated: Dictionary = {}
	for envelope: Dictionary in candidates:
		var staged := _stage_campaign_checkpoint(envelope)
		if not bool(staged.get("ok", false)):
			semantic_errors.append("%s: %s" % [
				String(envelope.get("recovery_source", "candidate")),
				String(staged.get("error", "composite validation failed")),
			])
			continue
		if not _activate_staged_campaign_checkpoint(staged):
			semantic_errors.append("%s: live simulation activation failed closed" % String(
				envelope.get("recovery_source", "candidate")
			))
			continue
		# Restored facts are a baseline, not new events. Activation emits a
		# snapshot, so clear any transition beats inferred against the disposable
		# boot simulation, then seed the dialogue observer from the verified live
		# state before presenting the one authored return beat below.
		if _character_dialogue_ui != null:
			_character_dialogue_ui.clear_session()
		_character_dialogue_previous_snapshot = _character_dialogue_projection(
			_simulation.snapshot()
		)
		activated = staged
		break
	if activated.is_empty():
		_has_campaign_checkpoint_candidate = false
		_has_verified_campaign_checkpoint = false
		_checkpoint_last_error = _bounded_checkpoint_error(
			"No complete campaign, office, and Senior ledger passed validation%s."
			% (" (%s)" % "; ".join(semantic_errors) if not semantic_errors.is_empty() else "")
		)
		_show_campaign_title(false)
		_set_campaign_modal_open(true)
		_publish_economic_action_hold(
			"SAVE",
			"REVIEW RECOVERY",
			_checkpoint_last_error,
			"Career recovery",
		)
		_publish_checkpoint_diagnostic()
		return
	var envelope := activated.get("envelope", {}) as Dictionary
	_checkpoint_coordinator.discard_pending()
	_has_campaign_checkpoint_candidate = true
	_has_verified_campaign_checkpoint = true
	_checkpoint_last_error = ""
	_campaign_session_checkpoint_enabled = true
	_first_session_funnel.begin_resume()
	for unlock_value in _campaign_state.unlocked_feature_ids:
		_simulation.apply_campaign_unlock(StringName(unlock_value))
	_last_reviewed_day = _simulation.day
	_reset_campaign_session_visuals()
	_restore_campaign_interface_context(
		activated.get("interface_context", {}) as Dictionary
	)
	var recovered_attention := _reconcile_orphaned_peck_assist_deliveries()
	_reconcile_first_clutch_reinvestment_after_restore()
	_restore_campaign_view()
	var resumed_payload := _resume_dictionary(envelope.get("campaign"))
	var resumed_metadata := _resume_dictionary(envelope.get("metadata"))
	var resumed_session := _resume_dictionary(resumed_payload.get("session"))
	var resumed_return_recap := _campaign_return_recap(
		resumed_payload,
		resumed_metadata,
		resumed_session,
	)
	_arm_routing_return_cue(resumed_return_recap)
	_update_guidance(_simulation.snapshot())
	var resumed_offline_recap := _campaign_offline_recap(
		_resume_integer(resumed_metadata.get("saved_at_unix"), 0),
	)
	_queue_character_dialogue(
		CharacterDialogueCatalogScript.return_beat(
			resumed_return_recap,
			resumed_offline_recap,
			_simulation.day,
		)
	)
	if recovered_attention > 0:
		_save_campaign_checkpoint("priority_peck_delivery_recovered")
		_ticker_label.text = "RECOVERY LEDGER: %d clean assisted %s completed off-screen; attention restored." % [
			recovered_attention,
			("delivery" if recovered_attention == 1 else "deliveries"),
		]
	if bool(envelope.get("recovered_from_backup", false)):
		_ticker_label.text = "%s RESTORED FROM RECOVERY COPY. The last valid coop ledger is active." % (
			"SENIOR ROOST" if _campaign_senior_roost else "PROBATION"
		)


func _stage_campaign_checkpoint(envelope: Dictionary) -> Dictionary:
	# Every component is decoded into disposable staging objects first. A candidate
	# can therefore fail Campaign, simulation, Senior, or session validation without
	# touching the currently playable Office state.
	var payload_value: Variant = envelope.get("campaign", {})
	if not payload_value is Dictionary:
		return {"ok": false, "error": "campaign payload is not a Dictionary"}
	var payload := payload_value as Dictionary
	var campaign_data_value: Variant = payload.get("campaign", {})
	var simulation_data_value: Variant = payload.get("simulation", {})
	if not campaign_data_value is Dictionary:
		return {"ok": false, "error": "probation ledger is not a Dictionary"}
	if not simulation_data_value is Dictionary:
		return {"ok": false, "error": "office simulation is not a Dictionary"}
	var restored_campaign = CampaignStateScript.from_dictionary(
		campaign_data_value as Dictionary
	)
	if restored_campaign == null:
		return {"ok": false, "error": "probation ledger failed semantic validation"}
	var staged_simulation := DepartmentSimulation.new(1701, INITIAL_CAMPAIGN_STAFF)
	if not staged_simulation.restore_save_state(simulation_data_value as Dictionary):
		return {"ok": false, "error": "office simulation failed semantic validation"}

	var session_value: Variant = payload.get("session", {})
	if not session_value is Dictionary:
		return {"ok": false, "error": "session ledger is not a Dictionary"}
	var session := session_value as Dictionary
	if session.has("senior_roost") and typeof(session.get("senior_roost")) != TYPE_BOOL:
		return {"ok": false, "error": "session.senior_roost must be a bool"}
	var last_report_value: Variant = session.get("last_workday_report", {})
	if not last_report_value is Dictionary:
		return {"ok": false, "error": "session.last_workday_report is not a Dictionary"}
	var first_clutch_value: Variant = session.get("first_clutch", {})
	if session.has("first_clutch") and not first_clutch_value is Dictionary:
		return {"ok": false, "error": "session.first_clutch is not a Dictionary"}
	var interface_context_value: Variant = session.get("interface_context", {})
	if session.has("interface_context") and not interface_context_value is Dictionary:
		return {"ok": false, "error": "session.interface_context is not a Dictionary"}
	var interface_context_validation := _validated_campaign_interface_context(
		interface_context_value as Dictionary
	)
	if not bool(interface_context_validation.get("ok", false)):
		return {
			"ok": false,
			"error": String(interface_context_validation.get(
				"error",
				"session.interface_context failed validation",
			)),
		}
	var staged_run_archive = CareerRunArchiveScript.new()
	if not staged_run_archive.restore(session.get("run_archive", [])):
		return {"ok": false, "error": "session.run_archive failed validation"}
	var current_run_id_value: Variant = session.get("current_run_id", "")
	if typeof(current_run_id_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return {"ok": false, "error": "session.current_run_id must be a string"}
	var current_run_id := String(current_run_id_value).strip_edges()
	if current_run_id.length() > 120 or "\n" in current_run_id or "\r" in current_run_id:
		return {"ok": false, "error": "session.current_run_id is outside supported limits"}
	if current_run_id.is_empty():
		current_run_id = _legacy_campaign_run_id(
			restored_campaign,
			simulation_data_value as Dictionary,
		)
	var career_profile := CareerPortfolioStoreScript.normalize_profile(
		session.get("career_profile", _career_profile)
	)
	var review_stage_value: Variant = session.get("review_stage", "active")
	if typeof(review_stage_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return {"ok": false, "error": "session.review_stage must be a string"}
	var review_stage := StringName(String(review_stage_value))
	var allowed_review_stages: Array[StringName] = [
		&"active", &"farmer", &"credit", &"probation", &"contract_board",
		&"final", &"senior_quarter", &"senior_annual",
	]
	if review_stage not in allowed_review_stages:
		return {"ok": false, "error": "session.review_stage is unsupported"}

	var senior_data_value: Variant = payload.get("senior_roost", {})
	if payload.has("senior_roost") and not senior_data_value is Dictionary:
		return {"ok": false, "error": "Senior Roost ledger is not a Dictionary"}
	var restored_senior = null
	var migrated_legacy_senior := false
	if senior_data_value is Dictionary and not (senior_data_value as Dictionary).is_empty():
		restored_senior = SeniorRoostStateScript.from_dictionary(
			senior_data_value as Dictionary
		)
		if restored_senior == null:
			return {"ok": false, "error": "Senior Roost ledger failed semantic validation"}
	else:
		restored_senior = SeniorRoostStateScript.new()
		if bool(session.get("senior_roost", false)):
			var legacy_last_report := last_report_value as Dictionary
			if not restored_senior.begin(
				int(legacy_last_report.get("day", maxi(0, staged_simulation.day - 1))),
				staged_simulation.snapshot(),
			):
				return {"ok": false, "error": "legacy Senior Roost migration failed"}
			migrated_legacy_senior = true
			review_stage = &"senior_quarter"
	var senior_active: bool = bool(restored_senior.is_active())
	if not senior_active and review_stage in [&"senior_quarter", &"senior_annual"]:
		review_stage = &"active"
	var first_clutch_data := (
		(first_clutch_value as Dictionary).duplicate(true)
		if first_clutch_value is Dictionary else
		{}
	)
	return {
		"ok": true,
		"error": "",
		"envelope": envelope.duplicate(true),
		"campaign_state": restored_campaign,
		"simulation_data": (simulation_data_value as Dictionary).duplicate(true),
		"senior_state": restored_senior,
		"review_stage": review_stage,
		"last_workday_report": (last_report_value as Dictionary).duplicate(true),
		"senior_active": senior_active,
		"migrated_legacy_senior": migrated_legacy_senior,
		"interface_context": (
			interface_context_validation.get("context", {}) as Dictionary
		).duplicate(true),
		"first_clutch": _normalize_first_clutch_state(
			first_clutch_data,
			not session.has("first_clutch"),
		),
		"personal_goal": PersonalShiftGoal.reconcile(session.get("personal_goal", {}), staged_simulation.day, staged_simulation.quota_target, last_report_value as Dictionary),
		"run_archive": staged_run_archive,
		"current_run_id": current_run_id,
		"career_profile": career_profile,
	}


func _activate_staged_campaign_checkpoint(staged: Dictionary) -> bool:
	var simulation_data := staged.get("simulation_data", {}) as Dictionary
	if not _simulation.restore_save_state(simulation_data):
		return false
	_campaign_state = staged.get("campaign_state")
	_senior_roost_state = staged.get("senior_state")
	_campaign_review_stage = StringName(staged.get("review_stage", &"active"))
	_last_workday_report = (
		staged.get("last_workday_report", {}) as Dictionary
	).duplicate(true)
	_campaign_senior_roost = bool(staged.get("senior_active", false))
	_first_clutch = (staged.get("first_clutch", {}) as Dictionary).duplicate(true)
	_personal_goal = PersonalShiftGoal.normalize(staged.get("personal_goal", {}))
	_career_run_archive = staged.get("run_archive", CareerRunArchiveScript.new())
	_current_campaign_run_id = String(staged.get("current_run_id", ""))
	_career_profile = (
		staged.get("career_profile", _career_profile) as Dictionary
	).duplicate(true)
	if _office_storytelling != null:
		_office_storytelling.apply_career_profile(_career_profile)
		_office_storytelling.apply_scenario_mastery(_career_run_archive.comparison())
	return true


func _restore_campaign_view() -> void:
	match _campaign_review_stage:
		&"farmer":
			_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
			_set_campaign_modal_open(false)
			if _last_workday_report.is_empty():
				if _campaign_senior_roost:
					_show_senior_roost_report("senior_restore_missing_farmer_report")
				else:
					_campaign_review_stage = &"probation"
					_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
					_set_campaign_modal_open(true)
			else:
				_show_farmer_review(_last_workday_report, false)
		&"probation":
			_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
			_set_campaign_modal_open(true)
		&"contract_board":
			var board := _simulation.market_contract_board_status()
			if not bool(board.get("unlocked", false)):
				_campaign_review_stage = &"probation"
				_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
			else:
				_campaign_ui.show_contract_board(_simulation.snapshot())
			_set_campaign_modal_open(true)
		&"senior_quarter", &"senior_annual":
			_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
			_set_campaign_modal_open(true)
		&"credit":
			_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
			_set_campaign_modal_open(false)
			var pending := _simulation.pending_decision_snapshot()
			if StringName(pending.get("kind", &"")) in [&"credit_allocation", &"major_event"]:
				_simulation.announce_pending_decision()
			else:
				_advance_after_closing_credit()
		&"final":
			_campaign_ui.show_final_review(_campaign_presentation_snapshot(&"final"))
			_set_campaign_modal_open(true)
		_:
			_campaign_review_stage = &"active"
			_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
			_set_campaign_modal_open(false)
			if _first_hen_prelude_pending():
				_present_first_hen_prelude()
			elif _simulation.shift_phase in [DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE, DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT]:
				_simulation.announce_pending_decision()
			else:
				_ticker_label.text = "%s RESTORED. The shift is paused at %s." % [
					"SENIOR ROOST" if _campaign_senior_roost else "PROBATION",
					String(_simulation.snapshot().get("time_label", "the saved time")),
				]
	_update_campaign_objectives_label()
	if not bool(_first_clutch.get("route_first_lesson", false)):
		_present_first_clutch_reinvestment()


func _reset_campaign_session_visuals() -> void:
	_first_reward_ready_msec = 0
	_clock.set_speed(0)
	_clear_adaptive_route_recovery()
	_routing_return_cue.clear()
	_last_routing_return_cue_dismissal.clear()
	if _routing_ui != null and _routing_ui.has_method("reset_return_cue_focus_state"):
		_routing_ui.reset_return_cue_focus_state()
	# A genuinely new or restored career establishes its existing archive without
	# replaying old commendation fanfare. Later permanent source changes are the
	# only events that produce a new-stamp notice.
	_commendations_seeded = false
	_known_commendation_ids.clear()
	_commendations_source_fingerprint = -1
	_feed_party_active = false
	_feed_party_release_scheduled = false
	_feed_party_arrivals.clear()
	_feed_party_returns.clear()
	if _feed_party_station != null:
		_feed_party_station.visible = false
	_decision_host.visible = false
	_day_review_scrim.visible = false
	_active_decision.clear()
	_selected_decision_option = &""
	_decision_restore_farmer_review = false
	_pending_collection_cents = 0
	_eggs_in_flight_by_worker.clear()
	_collection_claim_ids_by_worker.clear()
	_collection_cash_by_claim_id.clear()
	_collection_stocked_by_claim_id.clear()
	_egg_journey_receipts.clear()
	_egg_journey_receipt_serial = 0
	_authoritative_revenue_cents = _simulation.revenue_cents
	_displayed_revenue_cents = _simulation.revenue_cents
	_fund_visual_target_cents = _simulation.revenue_cents
	_fund_counter_active = false
	_last_reviewed_day = _simulation.day
	_sync_worker_presence()
	_on_snapshot_changed(_simulation.snapshot())


func _sync_worker_presence() -> void:
	for worker_id in _worker_views:
		var worker_view := _worker_views[worker_id] as ChickenView
		_simulation.set_worker_at_workstation(
			worker_id,
			worker_view != null and worker_view.is_seated_at_workstation(),
		)


func _reconcile_orphaned_peck_assist_deliveries() -> int:
	# Collection tweens are presentation-only and are intentionally absent from
	# campaign saves. Treat any clean delivery token restored from an egg-lay
	# checkpoint exactly like the First Clutch's off-screen basket reconciliation.
	var status := _simulation.peck_assist_delivery_status()
	var recovered := 0
	for delivery_value in status.get("pending_deliveries", []):
		var delivery := delivery_value as Dictionary
		var receipt := _simulation.settle_peck_assist_delivery(
			int(delivery.get("claim_id", -1)),
			StringName(String(delivery.get("quality", ""))),
		)
		if bool(receipt.get("accepted", false)):
			recovered += 1
	return recovered


func _campaign_live_metrics(snapshot: Dictionary) -> Dictionary:
	var eggs := maxi(0, int(snapshot.get("eggs_today", 0)))
	var quota := maxi(1, int(snapshot.get("quota_target", 1)))
	var cracked := maxi(0, int(snapshot.get("cracked_today", 0)))
	var rework_cursor: int = (
		_senior_roost_state.last_rework_total_created
		if _campaign_senior_roost and _senior_roost_state != null else
		_campaign_state.last_source_rework_total()
	)
	var welfare_total := 0
	var welfare_count := 0
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if not _is_worker_employed(worker):
			continue
		welfare_total += clampi(
			roundi(float(worker.get("morale", 0.0))) + 20
			- roundi(float(worker.get("stress", 0.0)) / 3.0)
			- roundi(float(worker.get("fatigue", 0.0)) / 5.0),
			0,
			100,
		)
		welfare_count += 1
	return {
		"eggs": eggs,
		"quota": quota,
		"quota_met": 1 if eggs >= quota else 0,
		"cracked": cracked,
		"crack_rate_basis_points": roundi(
			float(cracked)
			/ maxf(1.0, float(eggs)) * 10000.0
		),
		"welfare": roundi(float(welfare_total) / float(maxi(1, welfare_count))),
		"compliance": roundi(float(snapshot.get("compliance", 0.0))),
		"farmer_favor": roundi(float(snapshot.get("executive_confidence", 0.0))),
		"overdue_files": int(snapshot.get(
			"overdue_claims",
			(snapshot.get("routing", {}) as Dictionary).get("overdue_total", 0),
		)),
		"rework": maxi(
			0,
			int(snapshot.get("rework_total_created", 0))
			- rework_cursor,
		),
		"credited_cents": maxi(0, int(snapshot.get("credited_today_cents", 0))),
		"wage_arrears_cents": maxi(0, int(snapshot.get("wage_arrears_cents", 0))),
		"closing_fund_cents": maxi(0, int(snapshot.get("revenue_cents", 0))),
	}


func _campaign_objective_measure_text(
	metric: StringName,
	comparison: StringName,
	actual: int,
	target: int,
	eggs_today: int
) -> String:
	match metric:
		&"eggs":
			return "%d/%d EGGS" % [actual, target]
		&"crack_rate_basis_points":
			return "%s/%.1f%% CAP" % [
				"PEND" if eggs_today == 0 else "%.1f%%" % (float(actual) / 100.0),
				float(target) / 100.0,
			]
		&"quota_met":
			return "MET" if actual == 1 else "OPEN"
		&"quota_shifts":
			return "%d/%d SHIFTS" % [actual, target]
		&"quarter_score":
			return "%d/%d FLOOR" % [actual, target]
		&"welfare", &"compliance", &"farmer_favor":
			return "%d/%d%% FLOOR" % [actual, target]
		_:
			return "%d/%d %s" % [actual, target, "CAP" if comparison == &"maximum" else "FLOOR"]


func _campaign_objective_short_label(metric: StringName) -> String:
	match metric:
		&"eggs": return "CLUTCH"
		&"crack_rate_basis_points": return "SHELLS"
		&"quota_met": return "QUOTA"
		&"quota_shifts": return "QUOTA"
		&"quarter_score": return "STANDING"
		&"welfare", &"average_welfare": return "WELFARE"
		&"probation_score": return "SCORE"
		&"compliance": return "OBEDIENCE"
		&"farmer_favor": return "FAVOR"
		&"overdue_files": return "OVERDUE"
		&"rework": return "REWORK"
		_: return String(metric).replace("_", " ").to_upper()


func _campaign_objective_icon(metric: StringName) -> StringName:
	match metric:
		&"eggs", &"quota_met", &"quota_shifts": return &"egg"
		&"welfare", &"average_welfare": return &"flock"
		&"crack_rate_basis_points", &"compliance": return &"shield"
		&"farmer_favor": return &"cash"
		&"overdue_files", &"rework": return &"files"
		_: return &"goal"


func _senior_career_forecast(snapshot: Dictionary = {}) -> Dictionary:
	## Keep the forecast scoped to the playable Senior floor. At farmer, credit,
	## policy, and annual gates the recorded review owns the truth instead, which
	## also prevents a closing shift from being projected a second time.
	if (
		not _campaign_senior_roost
		or _senior_roost_state == null
		or _senior_roost_state.status != SeniorRoostStateScript.STATUS_ACTIVE
		or _campaign_review_stage != &"active"
	):
		return {"visible": false}
	var active_snapshot := snapshot if not snapshot.is_empty() else _simulation.snapshot()
	var forecast: Dictionary = _senior_roost_state.current_career_forecast(
		_campaign_live_metrics(active_snapshot)
	)
	if forecast.is_empty():
		return {"visible": false}
	forecast["annual_mandate_progress"] = _senior_roost_state.current_annual_mandate_progress(
		_campaign_live_metrics(active_snapshot)
	)
	forecast["visible"] = true
	return forecast


func _apply_senior_career_forecast_label(forecast: Dictionary) -> void:
	var projected_score := int(forecast.get("projected_score", 0))
	var score_max := maxi(1, int(forecast.get("score_max", 100)))
	var projected_marks := maxi(0, int(forecast.get("projected_marks", 0)))
	var next_threshold := int(forecast.get("next_mark_threshold", -1))
	var next_copy := (
		"  /  NEXT %d" % next_threshold
		if next_threshold >= 0 else
		"  /  TOP MARK TIER"
	)
	var lines: Array[String] = [
		"IF FILED NOW  /  %d / %d  /  +%d MARK%s%s" % [
			projected_score,
			score_max,
			projected_marks,
			"" if projected_marks == 1 else "S",
			next_copy,
		],
	]
	var largest := forecast.get("largest_recoverable_component", {}) as Dictionary
	if largest.is_empty():
		lines.append("FULL CREDIT  /  NO RECOVERABLE SENIOR POINTS")
	else:
		lines.append("RECOVERABLE  /  %s  /  +%d" % [
			String(largest.get("label", "SENIOR STANDING")),
			int(largest.get("recoverable_points", 0)),
		])
		lines.append(String(largest.get("cause", "The closing ledger still has recoverable points.")))
	var mandate_progress := forecast.get("annual_mandate_progress", {}) as Dictionary
	if not mandate_progress.is_empty():
		lines.append("YEAR BOOK  /  %d / %d SHIFTS  /  %d / %d TARGETS" % [
			int(mandate_progress.get("shifts_recorded", 0)),
			int(mandate_progress.get("shifts_target", 12)),
			int(mandate_progress.get("objectives_met", 0)),
			int(mandate_progress.get("objectives_total", 0)),
		])
		var mandate_blocker := mandate_progress.get("largest_recoverable_blocker", {}) as Dictionary
		if not mandate_blocker.is_empty():
			lines.append("BOARD BLOCKER  /  %s  /  %s ACTUAL %s" % [
				String(mandate_blocker.get("label", "ANNUAL TARGET")),
				_senior_mandate_target_text(
					String(mandate_blocker.get("metric", "")),
					String(mandate_blocker.get("comparison", "minimum")),
					int(mandate_blocker.get("target", 0)),
				),
				_senior_mandate_progress_value_text(
					String(mandate_blocker.get("metric", "")),
					int(mandate_blocker.get("actual", 0)),
				),
			])
	_campaign_objectives_label.text = "\n".join(lines)
	_campaign_objectives_label.set_meta("career_forecast_visible", true)
	_campaign_objectives_label.set_meta("career_forecast_score", projected_score)
	_campaign_objectives_label.set_meta("career_forecast_marks", projected_marks)

	var tooltip_lines: Array[String] = [
		"SENIOR CAREER FORECAST  //  IF FILED NOW",
		"Projected score %d / %d  //  +%d Roost Mark%s" % [
			projected_score,
			score_max,
			projected_marks,
			"" if projected_marks == 1 else "s",
		],
	]
	if next_threshold >= 0:
		tooltip_lines.append("Next mark tier: %d (%d points away)." % [
			next_threshold,
			int(forecast.get("points_to_next_mark", 0)),
		])
	else:
		tooltip_lines.append("The projected quarter is already in the three-mark tier.")
	for component_value in forecast.get("components", []):
		var component := component_value as Dictionary
		tooltip_lines.append("%s  //  %d / %d\n%s" % [
			String(component.get("label", "SENIOR COMPONENT")),
			int(component.get("score", 0)),
			int(component.get("max_score", 0)),
			String(component.get("cause", "Filed against the closing ledger.")),
		])
	if not mandate_progress.is_empty():
		tooltip_lines.append(
			"ANNUAL BOARD MANDATE\n" + "\n".join(
				_senior_mandate_progress_lines(mandate_progress)
			)
		)
	tooltip_lines.append("Live measures can still move until the quarter is filed.")
	_campaign_objectives_label.tooltip_text = "\n\n".join(tooltip_lines)


func _update_probation_safeguard_label() -> void:
	if _campaign_safeguards_label == null or _campaign_state == null:
		return
	if _campaign_senior_roost:
		_campaign_safeguards_label.visible = false
		if _campaign_safeguard_glance != null:
			_flockwatch_glance_tile(_campaign_safeguard_glance).visible = false
		return
	var forecast: Dictionary = _campaign_state.probation_safeguard_forecast()
	var criteria := forecast.get("criteria", []) as Array
	_campaign_safeguards_label.visible = false
	if _campaign_safeguard_glance != null:
		_flockwatch_glance_tile(_campaign_safeguard_glance).visible = not criteria.is_empty()
	if criteria.is_empty():
		return
	var pass_count := int(forecast.get("pass_count", 0))
	var completed := int(forecast.get("completed_shifts", 0))
	var required := int(forecast.get("required_shifts", CampaignStateScript.CAMPAIGN_LENGTH))
	var all_pass := bool(forecast.get("all_pass", false))
	var challenge_contract: Dictionary = _campaign_state.challenge_contract_snapshot()
	var challenge_label := String(challenge_contract.get(
		"short_label",
		challenge_contract.get("label", "STANDARD FILING"),
	)).strip_edges().to_upper()
	var blocker := forecast.get("largest_recoverable_blocker", {}) as Dictionary
	if blocker.is_empty() and not all_pass:
		for row_value: Variant in criteria:
			if row_value is Dictionary and not bool((row_value as Dictionary).get("pass", false)):
				blocker = (row_value as Dictionary).duplicate(true)
				break
	var status_copy := "ON TRACK"
	if not all_pass and not blocker.is_empty():
		var compact_gap := _probation_safeguard_office_gap_text(blocker)
		compact_gap = compact_gap.replace(" POINTS", "").replace(" POINT", "").replace(" PTS", "")
		status_copy = "RISK %s %s" % [
			String(blocker.get("label", "SAFEGUARD")).to_upper(),
			compact_gap,
		]
	_campaign_safeguards_label.text = (
		"%s · SAFE %d/%d · SHIFTS %d/%d · %s" % [
			challenge_label,
			pass_count,
			criteria.size(),
			completed,
			required,
			status_copy,
		]
	)
	_set_hud_font_color(
		_campaign_safeguards_label,
		Color("a7dbc9") if all_pass else Color("f0aa95"),
	)
	var tooltip_lines: Array[String] = [
		"%s  //  PROBATION FINAL TERMS  //  EXACT THRESHOLDS" % challenge_label,
		String(challenge_contract.get("description", "The selected filing standard remains permanent for this career.")),
		"The file passes only after five shifts and only when all five rows pass.",
	]
	for row_value: Variant in criteria:
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		var metric := String(row.get("metric", ""))
		var comparison := String(row.get("comparison", "minimum"))
		tooltip_lines.append("%s  //  %s  //  %s %s %s  //  %s" % [
			"PASS" if bool(row.get("pass", false)) else "AT RISK",
			String(row.get("label", "SAFEGUARD")).to_upper(),
			_probation_safeguard_office_value_text(metric, int(row.get("projected_value", 0))),
			">=" if comparison == "minimum" else "<=",
			_probation_safeguard_office_value_text(metric, int(row.get("target", 0))),
			_probation_safeguard_office_gap_text(row),
		])
	_campaign_safeguards_label.tooltip_text = "\n".join(tooltip_lines)
	_campaign_safeguards_label.set_meta(
		"accessible_text",
		"%s\n%s" % [
			_campaign_safeguards_label.text,
			_campaign_safeguards_label.tooltip_text,
		],
	)
	if _campaign_safeguard_glance != null:
		var glance_status := "READY FOR REVIEW"
		if not all_pass and not blocker.is_empty():
			var glance_gap := absi(int(blocker.get("signed_gap", 0)))
			var glance_gap_text := str(glance_gap)
			if StringName(blocker.get("metric", &"")) == &"crack_rate_basis_points":
				glance_gap_text = "%.1f PTS" % (float(glance_gap) / 100.0)
			glance_status = "%s NEEDS %s" % [
				_campaign_objective_short_label(StringName(blocker.get("metric", &""))),
				glance_gap_text,
			]
		_campaign_safeguard_glance.text = "%d / %d SAFE\n%s" % [
			pass_count,
			criteria.size(),
			glance_status,
		]
		_campaign_safeguard_glance.tooltip_text = _campaign_safeguards_label.tooltip_text
		_flockwatch_glance_tile(_campaign_safeguard_glance).tooltip_text = (
			_campaign_safeguards_label.tooltip_text
		)
		_campaign_safeguard_glance.set_meta(
			"accessible_text",
			"%s\nSAFEGUARD\n%s" % [
				_campaign_safeguard_glance.text,
				String(_campaign_safeguards_label.get_meta("accessible_text", "")),
			],
		)
		_set_hud_font_color(
			_campaign_safeguard_glance,
			Color("a7dbc9") if all_pass else Color("f0aa95"),
		)
		_set_flockwatch_glance_icon(
			_campaign_safeguard_glance,
			&"shield",
			Color("a7dbc9") if all_pass else Color("f0aa95"),
		)
	_campaign_safeguards_label.set_meta("safeguards_pass", pass_count)
	_campaign_safeguards_label.set_meta("safeguards_total", criteria.size())
	_campaign_safeguards_label.set_meta(
		"challenge_contract_id",
		String(challenge_contract.get("id", CampaignStateScript.CHALLENGE_STANDARD_FILING)),
	)
	_campaign_safeguards_label.set_meta(
		"largest_blocker_id",
		String(blocker.get("id", "")),
	)


func _probation_safeguard_office_value_text(metric: String, value: int) -> String:
	if metric == "crack_rate_basis_points":
		return "%.2f%%" % (float(value) / 100.0)
	return str(value)


func _probation_safeguard_office_gap_text(row: Dictionary) -> String:
	var gap := int(row.get("signed_gap", 0))
	if String(row.get("metric", "")) == "crack_rate_basis_points":
		return "%s%.2f PTS" % ["+" if gap > 0 else "", float(gap) / 100.0]
	return "%s%d POINT%s" % [
		"+" if gap > 0 else "",
		gap,
		"" if absi(gap) == 1 else "S",
	]


func _update_campaign_objectives_label(snapshot: Dictionary = {}) -> void:
	if _campaign_objectives_label == null or _campaign_state == null:
		return
	_set_campaign_orders_glance_visible(false)
	var active_snapshot := snapshot if not snapshot.is_empty() else _simulation.snapshot()
	var live_metrics := _campaign_live_metrics(active_snapshot)
	var senior_mode: bool = _campaign_senior_roost and _senior_roost_state != null and _senior_roost_state.is_active()
	_update_campaign_doctrine_label(senior_mode)
	_update_probation_safeguard_label()
	var career_forecast := _senior_career_forecast(active_snapshot)
	_campaign_objectives_label.set_meta("career_forecast_visible", false)
	_campaign_objectives_label.set_meta("career_forecast_score", 0)
	_campaign_objectives_label.set_meta("career_forecast_marks", 0)
	if _campaign_orders_heading_label != null:
		_campaign_orders_heading_label.text = (
			"SENIOR CAREER + BOARD FORECAST"
			if bool(career_forecast.get("visible", false)) else
			("THIS QUARTER'S SENIOR ORDERS" if senior_mode else "TODAY'S GOALS")
		)
		_campaign_orders_heading_label.tooltip_text = ""
		_campaign_orders_heading_label.set_meta(
			"accessible_text",
			_campaign_orders_heading_label.text,
		)
	if senior_mode and _senior_roost_state.status == SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
		_sync_live_order_badge(0, 0, senior_mode)
		if _senior_roost_state.requires_annual_mandate():
			var mandate_tier: Dictionary = _senior_roost_state.mandate_tier_eligibility()
			_campaign_objectives_label.text = "ANNUAL MANDATE REQUIRED  ·  3 FROZEN BOOKS  ·  %d SEAL%s  ·  TIER %d" % [
				int(mandate_tier.get("mandate_seals", 0)),
				"" if int(mandate_tier.get("mandate_seals", 0)) == 1 else "S",
				int(mandate_tier.get("eligible_tier", 0)),
			]
			_campaign_objectives_label.tooltip_text = "Choose the twelve-shift annual Board Mandate before Q1 policy. The Standard Board Book never stakes marks; harder tiers disclose their targets, reward, and failure cost."
			_campaign_objectives_label.set_meta("orders_on_track", 0)
			_campaign_objectives_label.set_meta("orders_total", 1)
			return
		var sponsorship_window: bool = (
			_senior_roost_state.completed_quarters > 0
			and bool(_senior_roost_state.snapshot().get("sponsorship_available_this_gate", true))
		)
		_campaign_objectives_label.text = (
			"POLICY REQUIRED  ·  SPONSORSHIP OPTIONAL  ·  BANK OR INVEST MARKS"
			if sponsorship_window else
			"POLICY  ·  REQUIRED  ·  FILE ONE QUARTER TRADEOFF"
		)
		_campaign_objectives_label.tooltip_text = (
			"File one capital policy. The optional Career Sponsorship below it can invest three available Roost Marks in one accredited hen before this quarter opens."
			if sponsorship_window else
			"Every three-shift Senior quarter begins with Merit Grants, a Flock Dividend, or an Executive Harvest Forecast."
		)
		_campaign_objectives_label.set_meta("orders_on_track", 0)
		_campaign_objectives_label.set_meta("orders_total", 1)
		return
	if senior_mode and _senior_roost_state.status == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		_sync_live_order_badge(0, 0, senior_mode)
		var annual_passed := bool(_senior_roost_state.last_annual_review.get("passed", false))
		var mandate_settlement: Dictionary = _senior_roost_state.last_mandate_settlement
		_campaign_objectives_label.text = "ANNUAL  ·  %s  ·  %d / 100  ·  BOARD %s  ·  %d SEAL%s" % [
			"PASSED" if annual_passed else "IMPROVEMENT YEAR",
			int(_senior_roost_state.last_annual_review.get("score", 0)),
			"SEALED" if bool(mandate_settlement.get("success", false)) else "HELD",
			int(mandate_settlement.get("seal_reward", 0)),
			"" if int(mandate_settlement.get("seal_reward", 0)) == 1 else "S",
		]
		_campaign_objectives_label.tooltip_text = "%s\n\nAcknowledge the annual review to continue the optional post-campaign Senior file. The authored probation ending is already preserved; this closed-quarter gate also permits one optional Career Sponsorship." % String(
			mandate_settlement.get("outcome", "The annual Board Mandate has settled."),
		)
		_campaign_objectives_label.set_meta("orders_on_track", 1 if annual_passed else 0)
		_campaign_objectives_label.set_meta("orders_total", 1)
		return
	var objectives: Array[Dictionary] = (
		_senior_roost_state.current_objective_progress(live_metrics)
		if senior_mode else
		_campaign_state.current_objective_progress(live_metrics)
	)
	if objectives.is_empty():
		_sync_live_order_badge(0, 0, senior_mode)
		_campaign_objectives_label.text = (
			"Senior quarter awaiting its first filed shift."
			if senior_mode else
			"Probation file closed. Final ledgers determine the roost."
		)
		_campaign_objectives_label.set_meta("orders_on_track", 0)
		_campaign_objectives_label.set_meta("orders_total", 0)
		return
	if not senior_mode and _campaign_orders_heading_label != null:
		var available_score := 0
		for objective: Dictionary in objectives:
			available_score += maxi(0, int(objective.get("score_award", 0)))
		_campaign_orders_heading_label.text = "%d ACTIVE GOAL%s  ·  +%d SCORE" % [
			objectives.size(),
			"" if objectives.size() == 1 else "S",
			available_score,
		]
		_campaign_orders_heading_label.tooltip_text = (
			"All %d goal%s are active. Together they award +%d score; a clean sweep adds +3 more. Select any goal card to inspect its strongest live driver. The top HUD quota is a separate operating target."
			% [
				objectives.size(),
				"" if objectives.size() == 1 else "s",
				available_score,
			]
		)
		_campaign_orders_heading_label.set_meta(
			"accessible_text",
			"%s. %s" % [
				_campaign_orders_heading_label.text,
				_campaign_orders_heading_label.tooltip_text,
			],
		)
	var lines: Array[String] = []
	var tooltip_lines: Array[String] = []
	var live_order_states: Array[Dictionary] = []
	var on_track := 0
	var eggs_today := int(live_metrics.get("eggs", 0))
	for objective in objectives:
		var metric := StringName(objective.get("metric", &""))
		var actual := int(objective.get("actual", 0))
		var projected_met := bool(objective.get("projected_met", false))
		if projected_met:
			on_track += 1
		var status := "TRACK" if projected_met else "NEEDS"
		var measure_text := _campaign_objective_measure_text(
			metric,
			StringName(objective.get("comparison", &"minimum")),
			actual,
			int(objective.get("target", 0)),
			eggs_today,
		)
		lines.append("%s  ·  %s  ·  %s  ·  +%d" % [
			status,
			_campaign_objective_short_label(metric),
			measure_text,
			int(objective.get("score_award", 0)),
		])
		if not senior_mode:
			live_order_states.append({
				"id": String(objective.get("id", "order_%d" % (live_order_states.size() + 1))),
				"label": String(objective.get("title", "Probation order")),
				"metric": String(metric),
				"icon": String(_campaign_objective_icon(metric)),
				"on_track": projected_met,
				"detail": "%s  //  %s  //  %s" % [
					"ON TRACK" if projected_met else "NEEDS ACTION",
					String(objective.get("title", "Probation order")).to_upper(),
					measure_text,
				],
			})
		tooltip_lines.append("%s  ·  %s\n%s" % [
			"ON TRACK" if projected_met else "NEEDS ACTION",
			String(objective.get("title", "Probation order")).to_upper(),
			String(objective.get("description", "Filed against the closing ledger.")),
		])
	_campaign_objectives_label.set_meta("orders_on_track", on_track)
	_campaign_objectives_label.set_meta("orders_total", objectives.size())
	_sync_live_order_badge(on_track, objectives.size(), senior_mode, live_order_states)
	if bool(career_forecast.get("visible", false)):
		_apply_senior_career_forecast_label(career_forecast)
		return
	tooltip_lines.append(
		"Filed at quarter close; live measures can still move. A 60+ quarter earns promotion progress."
		if senior_mode else
		"Filed at review; live measures can still move. Each completed order pays its listed score, and a clean sweep adds +3."
	)
	_campaign_objectives_label.tooltip_text = "\n\n".join(tooltip_lines)
	_campaign_objectives_label.text = "\n".join(lines)
	_campaign_objectives_label.set_meta(
		"accessible_text",
		"%s\n\n%s" % [
			_campaign_objectives_label.text,
			_campaign_objectives_label.tooltip_text,
		],
	)
	if not senior_mode:
		_apply_campaign_orders_glance(objectives, eggs_today)


func _set_campaign_orders_glance_visible(visible: bool) -> void:
	if _campaign_orders_glance_grid != null:
		_campaign_orders_glance_grid.visible = visible
	if _campaign_objectives_label != null:
		_campaign_objectives_label.visible = not visible


func _apply_campaign_orders_glance(
	objectives: Array[Dictionary],
	eggs_today: int,
) -> void:
	_set_campaign_orders_glance_visible(not objectives.is_empty())
	var active_objective_ids: Array[StringName] = []
	for index in range(_campaign_order_glances.size()):
		var glance := _campaign_order_glances[index]
		var tile := _flockwatch_glance_tile(glance)
		var has_order := index < objectives.size()
		if tile != null:
			tile.visible = has_order
		if not has_order:
			var removed_objective_id := StringName(glance.get_meta("objective_id", &""))
			if glance.has_focus():
				glance.release_focus()
			if _focused_campaign_order_id == removed_objective_id:
				_focused_campaign_order_id = &""
				_clear_campaign_order_driver_action()
			glance.focus_mode = Control.FOCUS_NONE
			glance.set_meta("objective_id", "")
			glance.set_meta("cause_receipt", {})
			glance.set_meta("cause_source_available", false)
			glance.mouse_default_cursor_shape = Control.CURSOR_ARROW
			continue
		var objective := objectives[index]
		var objective_id := StringName(objective.get("id", "order_%d" % (index + 1)))
		active_objective_ids.append(objective_id)
		var metric := StringName(objective.get("metric", &""))
		var comparison := StringName(objective.get("comparison", &"minimum"))
		var actual := int(objective.get("actual", 0))
		var target := int(objective.get("target", 0))
		var on_track := bool(objective.get("projected_met", false))
		var pending_first_egg := metric == &"crack_rate_basis_points" and eggs_today == 0
		var accent := (
			Color("efcf83")
			if pending_first_egg else
			(Color("a7dbc9") if on_track else Color("f0aa95"))
		)
		var glance_copy := _campaign_objective_action_glance(
			metric,
			comparison,
			actual,
			target,
			eggs_today,
			on_track,
		)
		if objective_id == &"opening_clutch":
			# This score award is a stretch target, separate from the daily quota.
			glance_copy = glance_copy.replace("LAY %d EGGS" % target, "BONUS AT %d" % target)
		var cause_receipt := (
			_campaign_order_cause_receipts.get(objective_id, {}) as Dictionary
		).duplicate(true)
		var cause_source_available := _campaign_order_cause_source_available(cause_receipt)
		if not cause_receipt.is_empty():
			var cause_copy := String(cause_receipt.get("copy", "CHANGE FILED"))
			if cause_source_available and StringName(cause_receipt.get("cause_kind", &"")) == &"routed_egg":
				var source_label := String(
					(cause_receipt.get("source", {}) as Dictionary).get("source_label", "HEN")
				).strip_edges().to_upper()
				cause_copy = cause_copy.replace(
					String(cause_receipt.get("cause_label", source_label)),
					source_label,
				)
			glance_copy += "\n%s%s" % [
				cause_copy,
				"  ↗" if cause_source_available else "",
			]
		glance.text = glance_copy
		glance.max_lines_visible = 3 if not cause_receipt.is_empty() else 2
		glance.custom_minimum_size.y = 52.0 if not cause_receipt.is_empty() else 40.0
		_set_hud_font_color(glance, accent)
		_set_flockwatch_glance_icon(glance, _campaign_objective_icon(metric), accent)
		var detail := "%s  ·  %s\n%s" % [
			(
				"PENDING FIRST EGG"
				if pending_first_egg else
				("ON TRACK" if on_track else "NEEDS ACTION")
			),
			String(objective.get("title", "PROBATION ORDER")).to_upper(),
			String(objective.get("description", "Filed against the closing ledger.")),
		]
		if not cause_receipt.is_empty():
			detail += "\nLATEST CAUSE  ·  %s" % String(cause_receipt.get(
				"detail",
				"A filed action changed this live goal.",
			))
			if cause_source_available:
				detail += "\nACTIVATE AGAIN  ·  FIND %s  ·  NO ACTION FILED" % String(
					(cause_receipt.get("source", {}) as Dictionary).get(
						"source_label",
						"SOURCE HEN",
					)
				).to_upper()
		glance.tooltip_text = detail
		glance.focus_mode = Control.FOCUS_ALL
		glance.set_meta("objective_id", String(objective_id))
		glance.set_meta("objective_title", String(objective.get("title", "PROBATION ORDER")))
		glance.set_meta("metric", String(metric))
		glance.set_meta("on_track", on_track)
		glance.set_meta("focus_accent", accent)
		glance.set_meta("cause_receipt", cause_receipt)
		glance.set_meta("cause_source_available", cause_source_available)
		# Every order is a real navigation affordance: the first activation exposes
		# its driver, while a later cause receipt can still be activated directly.
		glance.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if tile != null:
			tile.tooltip_text = detail
			tile.set_meta("objective_id", String(glance.get_meta("objective_id", "")))
			tile.set_meta("cause_receipt", cause_receipt)
			tile.set_meta("cause_source_available", cause_source_available)
		glance.set_meta("accessible_text", "%s\n%s" % [glance.text, detail])
		_refresh_campaign_order_glance_focus_style(glance)
		if glance.has_focus():
			_configure_campaign_order_driver_action(glance)
	if objectives.is_empty():
		_clear_campaign_order_driver_action()
		_campaign_order_return_cue.clear()
		_campaign_order_cause_receipts.clear()
	elif not _campaign_order_return_cue.is_empty():
		var return_objective_id := StringName(_campaign_order_return_cue.get("objective_id", &""))
		var return_goal_exists := false
		for objective in objectives:
			if StringName(objective.get("id", &"")) == return_objective_id:
				return_goal_exists = true
				break
		if not return_goal_exists:
			_campaign_order_return_cue.clear()
	for receipt_id_value in _campaign_order_cause_receipts.keys():
		var receipt_id := StringName(receipt_id_value)
		if receipt_id not in active_objective_ids:
			_campaign_order_cause_receipts.erase(receipt_id_value)


func _record_campaign_order_cause_receipts(
	before_snapshot: Dictionary,
	after_snapshot: Dictionary,
	cause_label: String,
	cause_kind: StringName,
	event_label: String = "",
	source: Dictionary = {},
) -> int:
	if (
		_campaign_state == null
		or _campaign_senior_roost
		or before_snapshot.is_empty()
		or after_snapshot.is_empty()
	):
		return 0
	var before_metrics := _campaign_live_metrics(before_snapshot)
	var after_metrics := _campaign_live_metrics(after_snapshot)
	var before_rows: Array[Dictionary] = _campaign_state.current_objective_progress(
		before_metrics
	)
	var after_rows: Array[Dictionary] = _campaign_state.current_objective_progress(
		after_metrics
	)
	if before_rows.is_empty() or after_rows.is_empty():
		return 0
	var before_by_id: Dictionary = {}
	for before_row: Dictionary in before_rows:
		before_by_id[StringName(before_row.get("id", &""))] = before_row
	var compact_cause := _compact_campaign_order_cause_label(cause_label)
	var changed_count := 0
	for after_row: Dictionary in after_rows:
		var objective_id := StringName(after_row.get("id", &""))
		var before_row := before_by_id.get(objective_id, {}) as Dictionary
		if objective_id == &"" or before_row.is_empty():
			continue
		var metric := StringName(after_row.get("metric", &""))
		var actual_before := int(before_row.get("actual", 0))
		var actual_after := int(after_row.get("actual", actual_before))
		var status_changed := (
			bool(before_row.get("projected_met", false))
			!= bool(after_row.get("projected_met", false))
		)
		var first_shell_result := (
			metric == &"crack_rate_basis_points"
			and int(before_metrics.get("eggs", 0)) == 0
			and int(after_metrics.get("eggs", 0)) > 0
		)
		if actual_before == actual_after and not status_changed and not first_shell_result:
			continue
		_campaign_order_cause_serial += 1
		var comparison := StringName(after_row.get("comparison", &"minimum"))
		var target := int(after_row.get("target", 0))
		var before_measure := _campaign_objective_measure_text(
			metric,
			comparison,
			actual_before,
			target,
			int(before_metrics.get("eggs", 0)),
		)
		var after_measure := _campaign_objective_measure_text(
			metric,
			comparison,
			actual_after,
			target,
			int(after_metrics.get("eggs", 0)),
		)
		_campaign_order_cause_receipts[objective_id] = {
			"serial": _campaign_order_cause_serial,
			"objective_id": String(objective_id),
			"metric": String(metric),
			"cause_kind": String(cause_kind),
			"cause_label": compact_cause,
			"copy": _campaign_order_cause_copy(
				metric,
				actual_before,
				actual_after,
				compact_cause,
				event_label,
			),
			"before": actual_before,
			"after": actual_after,
			"on_track_before": bool(before_row.get("projected_met", false)),
			"on_track_after": bool(after_row.get("projected_met", false)),
			"detail": "%s changed %s from %s to %s." % [
				compact_cause,
				String(after_row.get("title", "this goal")),
				before_measure,
				after_measure,
			],
			"source": source.duplicate(true),
		}
		changed_count += 1
	if changed_count > 0:
		_update_campaign_objectives_label(after_snapshot)
	return changed_count


func _compact_campaign_order_cause_label(cause_label: String) -> String:
	var compact := cause_label.strip_edges().to_upper()
	if compact.is_empty():
		compact = "FILED ACTION"
	if compact.length() > 16:
		compact = "%s…" % compact.left(15).strip_edges()
	return compact


func _campaign_order_cause_copy(
	metric: StringName,
	actual_before: int,
	actual_after: int,
	cause_label: String,
	event_label: String,
) -> String:
	if metric == &"quota_met":
		return "%s · %s" % ["MET" if actual_after > 0 else "OPEN", cause_label]
	if metric == &"crack_rate_basis_points" and not event_label.is_empty():
		return "%s %s" % [
			"!" if event_label.strip_edges().to_lower() == "cracked" else "✓",
			cause_label,
		]
	var delta := actual_after - actual_before
	var delta_copy := "%s%d" % ["+" if delta > 0 else "", delta]
	if metric == &"crack_rate_basis_points":
		delta_copy = "%s%.1fPT" % [
			"+" if delta > 0 else "",
			float(delta) / 100.0,
		]
	return "%s · %s" % [delta_copy, cause_label]


func _campaign_order_cause_source_available(receipt: Dictionary) -> bool:
	if receipt.is_empty():
		return false
	var source := receipt.get("source", {}) as Dictionary
	var worker_id := int(source.get("worker_id", -1))
	if worker_id < 0 or not _worker_views.has(worker_id):
		return false
	var worker_view := _worker_views.get(worker_id) as ChickenView
	return worker_view != null and is_instance_valid(worker_view) and worker_view.is_visible_in_tree()


func _activate_campaign_order_cause_source(glance: Label) -> bool:
	if glance == null or not is_instance_valid(glance):
		return false
	var receipt := glance.get_meta("cause_receipt", {}) as Dictionary
	if not _campaign_order_cause_source_available(receipt):
		return false
	var source := receipt.get("source", {}) as Dictionary
	var worker_id := int(source.get("worker_id", -1))
	var worker_view := _worker_views.get(worker_id) as ChickenView
	if worker_view == null or not is_instance_valid(worker_view):
		return false
	var source_label := String(source.get("source_label", "HEN")).strip_edges().to_upper()
	var objective_id := StringName(glance.get_meta("objective_id", &""))
	var objective_title := String(
		glance.get_meta("objective_title", "TODAY'S GOAL")
	).strip_edges().to_upper()
	var metric := StringName(glance.get_meta("metric", &""))
	var order_index := _campaign_order_glances.find(glance)
	_campaign_order_cause_activation_serial += 1
	if _flockwatch_open:
		_set_flockwatch_open(false)
	# A landmark focus deliberately emits worker_id = -1, so an armed dispatch tray
	# can never interpret this locator as a route filing. The dossier focus is then
	# applied independently as presentation state.
	if _camera_controller != null:
		_camera_controller.focus_point(
			worker_view.global_position + Vector3.UP * 0.82,
			"%s · LATEST CAUSE" % source_label,
			0.32,
		)
	var requested_claim_id := int(source.get("claim_id", -1))
	var claim_available := false
	var focus_target: Control
	if _routing_ui != null:
		_routing_ui.set_focus(worker_id)
		if requested_claim_id >= 0:
			focus_target = _routing_ui.focus_claim_file(requested_claim_id)
			claim_available = focus_target != null
		if not claim_available and _routing_ui.has_method("focus_hen_dossier"):
			focus_target = _routing_ui.focus_hen_dossier(worker_id)
	var handoff_kind := &"claim_file" if claim_available else &"hen_dossier"
	_set_campaign_order_return_cue({
		"objective_id": String(objective_id),
		"objective_title": objective_title,
		"order_index": order_index,
		"metric": String(metric),
		"icon_kind": "files" if claim_available else "flock",
		"handoff_kind": String(handoff_kind),
		"source_label": source_label,
	})
	_last_campaign_order_cause_focus_result = {
		"serial": _campaign_order_cause_activation_serial,
		"source_serial": int(receipt.get("serial", 0)),
		"objective_id": String(objective_id),
		"order_index": order_index,
		"worker_id": worker_id,
		"worker_name": source_label,
		"source_kind": String(source.get("source_kind", "worker")),
		"claim_id": requested_claim_id,
		"claim_available": claim_available,
		"target_kind": String(handoff_kind),
		"dossier_tab": (
			String(_routing_ui.active_dossier_tab()) if _routing_ui != null else ""
		),
		"focus_target": String(focus_target.name) if focus_target != null else "",
		"target_available": focus_target != null,
		"filed_choice": false,
	}
	_publish_status_copy("LATEST CAUSE  ·  %s" % source_label, false)
	if _simulation != null:
		var snapshot := _simulation.snapshot()
		_update_guidance(snapshot)
		_publish_web_diagnostic_state(snapshot)
	return true


func _on_campaign_order_glance_focus_changed(glance: Label, focused: bool) -> void:
	if glance == null or not is_instance_valid(glance):
		return
	if focused:
		_focused_campaign_order_id = StringName(glance.get_meta("objective_id", &""))
		_campaign_order_focus_serial += 1
		_configure_campaign_order_driver_action(glance)
		# Pointer focus must publish the same global action contract as live-mark,
		# keyboard, and controller focus. The shift is commonly paused here, so no
		# later simulation snapshot can be relied on to repair stale HUD guidance.
		if _simulation != null:
			var snapshot := _simulation.snapshot()
			_update_guidance(snapshot)
			_publish_web_diagnostic_state(snapshot)
	elif _focused_campaign_order_id == StringName(glance.get_meta("objective_id", &"")):
		_focused_campaign_order_id = &""
	_refresh_campaign_order_glance_focus_style(glance)


func _on_campaign_order_glance_gui_input(event: InputEvent, glance: Label) -> void:
	if glance == null or not is_instance_valid(glance):
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var objective_id := StringName(glance.get_meta("objective_id", &""))
			var was_pointer_armed := (
				objective_id != &"" and _campaign_order_pointer_armed_id == objective_id
			)
			_campaign_order_pointer_armed_id = objective_id
			glance.grab_focus()
			if was_pointer_armed:
				_activate_campaign_order_cause_source(glance)
			glance.accept_event()
		return
	if not event.is_action_pressed(&"ui_accept"):
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	glance.accept_event()
	if _activate_campaign_order_cause_source(glance):
		return
	_configure_campaign_order_driver_action(glance)
	_on_campaign_order_driver_pressed()


func _configure_campaign_order_driver_action(glance: Label) -> void:
	if _campaign_order_driver_button == null or glance == null:
		return
	var objective_id := StringName(glance.get_meta("objective_id", &""))
	var metric := StringName(glance.get_meta("metric", &""))
	if objective_id == &"" or metric == &"":
		_clear_campaign_order_driver_action()
		return
	var driver := _campaign_order_driver_for_metric(metric)
	driver["objective_id"] = String(objective_id)
	driver["objective_title"] = String(glance.get_meta("objective_title", "PROBATION ORDER"))
	driver["metric"] = String(metric)
	driver["on_track"] = bool(glance.get_meta("on_track", false))
	driver["order_index"] = _campaign_order_glances.find(glance)
	_campaign_order_driver_action = driver
	var accent: Color = glance.get_meta("focus_accent", Color("d9c47d"))
	var label := String(driver.get("label", "SHOW DRIVER"))
	var title := String(driver.get("objective_title", "PROBATION ORDER")).to_upper()
	var exact_detail := (
		"%s  //  %s\nShows the live control that most directly affects this goal. "
		+ "No choice is filed automatically."
	) % [title, label]
	_campaign_order_driver_button.visible = true
	_campaign_order_driver_button.tooltip_text = exact_detail
	_campaign_order_driver_button.set_meta("objective_id", String(objective_id))
	_campaign_order_driver_button.set_meta("metric", String(metric))
	_campaign_order_driver_button.set_meta("driver_action_id", String(driver.get("action_id", "")))
	_campaign_order_driver_button.set_meta("accessible_text", exact_detail)
	_campaign_order_driver_label.text = label
	_set_hud_font_color(_campaign_order_driver_label, accent)
	_campaign_order_driver_icon.configure(StringName(driver.get("icon_kind", &"goal")), accent)
	# The live label/action above must stay current even when its paint is unchanged.
	if _campaign_order_driver_button.has_meta("paint_accent") and _campaign_order_driver_button.get_meta("paint_accent") == accent:
		return
	_campaign_order_driver_button.set_meta("paint_accent", accent)
	_campaign_order_driver_button.begin_bulk_theme_override()
	var normal_style := _panel_style(Color("17252f"), 0.82, 6, 1)
	normal_style.border_color = Color(accent, 0.34)
	var hover_style := _panel_style(Color("22343f"), 0.96, 6, 1)
	hover_style.border_color = Color(accent, 0.72)
	var focus_style := _panel_style(Color("22343f"), 0.98, 6, 2)
	focus_style.border_color = accent
	_campaign_order_driver_button.add_theme_stylebox_override("normal", normal_style)
	_campaign_order_driver_button.add_theme_stylebox_override("hover", hover_style)
	_campaign_order_driver_button.add_theme_stylebox_override("pressed", hover_style)
	_campaign_order_driver_button.add_theme_stylebox_override("focus", focus_style)
	_campaign_order_driver_button.end_bulk_theme_override()


func _clear_campaign_order_driver_action() -> void:
	_campaign_order_driver_action.clear()
	if _campaign_order_driver_button == null:
		return
	if _campaign_order_driver_button.has_focus():
		_campaign_order_driver_button.release_focus()
	_campaign_order_driver_button.visible = false
	_campaign_order_driver_button.set_meta("objective_id", "")
	_campaign_order_driver_button.set_meta("metric", "")
	_campaign_order_driver_button.set_meta("driver_action_id", "")


func _campaign_order_driver_for_metric(metric: StringName) -> Dictionary:
	match metric:
		&"quota_met", &"eggs":
			return {
				"label": "SHOW HEN ROUTES",
				"action_id": "hen_routes",
				"icon_kind": "egg",
			}
		&"rework", &"overdue_files", &"crack_rate_basis_points":
			return {
				"label": "SHOW LIVE FILES",
				"action_id": "file_trays",
				"icon_kind": "files",
			}
		&"welfare", &"average_welfare":
			return {
				"label": "SHOW FLOCK CARE",
				"action_id": "flock_care",
				"icon_kind": "flock",
			}
		&"farmer_favor", &"average_farmer_favor":
			return {
				"label": "SHOW FARMER STANDING",
				"action_id": "farmer_standing",
				"icon_kind": "cash",
			}
		&"compliance", &"average_compliance":
			return {
				"label": "SHOW COMPLIANCE EXPOSURE",
				"action_id": "coop_controls",
				"icon_kind": "shield",
			}
	return {
		"label": "SHOW TODAY'S DRIVER",
		"action_id": "today_driver",
		"icon_kind": "goal",
	}


func _on_campaign_order_driver_pressed() -> void:
	if _campaign_order_driver_action.is_empty():
		return
	var driver := _campaign_order_driver_action.duplicate(true)
	var action_id := StringName(driver.get("action_id", &""))
	_campaign_order_driver_activation_serial += 1
	var target_name := ""
	var target_available := false
	var live_file_available := true
	match action_id:
		&"hen_routes":
			_focus_guidance_hen()
			var route_target: Control
			if _routing_ui != null:
				var worker_id := _routing_ui.focused_worker_id()
				if worker_id >= 0 and _routing_ui.has_method("focus_hen_dossier"):
					route_target = _routing_ui.focus_hen_dossier(worker_id)
			target_name = String(route_target.name) if route_target != null else ""
			target_available = (
				route_target != null
				and _camera_controller != null
				and _camera_controller.is_focused()
			)
		&"file_trays":
			if _flockwatch_open:
				_set_flockwatch_open(false)
			if _routing_ui != null:
				# `_process` normally restores this surface after the drawer closes,
				# but this handoff resolves in the same input frame. Make the promised
				# trays visible before selecting an exact live target.
				_routing_ui.visible = not _blocking_management_surface_open()
				var tray := _routing_ui.focus_priority_dispatch_tray()
				if tray != null:
					target_name = String(tray.name)
					target_available = true
					live_file_available = bool(
						_routing_ui.return_cue_focus_state().get("available", false)
					)
		&"flock_care":
			var care_target := _open_campaign_order_driver_page(
				FlockwatchNavigation.PAGE_FLOCK,
				PackedStringArray(["FlockCareSection", "FlockwatchFlockSection"]),
			)
			target_name = String(care_target.name) if care_target != null else ""
			target_available = care_target != null
		&"farmer_standing":
			var standing_target := _open_campaign_order_driver_page(
				FlockwatchNavigation.PAGE_TODAY,
				PackedStringArray(["FlockwatchTodayCashGlanceTile"]),
			)
			target_name = String(standing_target.name) if standing_target != null else ""
			target_available = standing_target != null
		&"coop_controls":
			var operations_target := _open_campaign_order_driver_page(
				FlockwatchNavigation.PAGE_OPERATIONS,
				PackedStringArray([
					"RoosterOperationsExposureGlancePanel",
					"RoosterOperationsSection",
					"FlockwatchOperationsSection",
				]),
			)
			target_name = (
				String(operations_target.name) if operations_target != null else ""
			)
			target_available = operations_target != null
		_:
			var today_target := _open_campaign_order_driver_page(
				FlockwatchNavigation.PAGE_TODAY,
				PackedStringArray(["CampaignOrdersHeading", "FlockwatchTodaySection"]),
			)
			target_name = String(today_target.name) if today_target != null else ""
			target_available = today_target != null
	if target_available:
		_set_campaign_order_return_cue(driver)
		_update_flockwatch_toggle()
	_last_campaign_order_driver_result = {
		"serial": _campaign_order_driver_activation_serial,
		"objective_id": String(driver.get("objective_id", "")),
		"metric": String(driver.get("metric", "")),
		"action_id": String(action_id),
		"target": target_name,
		"target_available": target_available,
		"live_file_available": live_file_available,
		"filed_choice": false,
	}
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	if _simulation != null:
		var snapshot := _simulation.snapshot()
		_update_guidance(snapshot)
		_publish_web_diagnostic_state(snapshot)


func _set_campaign_order_return_cue(driver: Dictionary) -> void:
	var objective_id := StringName(driver.get("objective_id", &""))
	if objective_id == &"":
		return
	_campaign_order_return_serial += 1
	var title := String(driver.get("objective_title", "TODAY'S GOAL")).strip_edges().to_upper()
	var icon_kind := StringName(driver.get("icon_kind", &"goal"))
	var handoff_kind := StringName(driver.get("handoff_kind", &""))
	var source_label := String(driver.get("source_label", "")).strip_edges().to_upper()
	var handoff_context := ""
	match handoff_kind:
		&"claim_file":
			handoff_context = " Returning from %s's exact file." % source_label
		&"hen_dossier":
			handoff_context = " Returning from %s's hen dossier." % source_label
	_campaign_order_return_cue = {
		"serial": _campaign_order_return_serial,
		"objective_id": String(objective_id),
		"objective_title": title,
		"order_index": int(driver.get("order_index", -1)),
		"metric": String(driver.get("metric", "")),
		"icon_kind": String(icon_kind),
		"driver_action_id": String(driver.get("action_id", "")),
		"handoff_kind": String(handoff_kind),
		"copy": "RETURN: %s" % title,
		"accessible_text": (
			"Return to Flockwatch Today and focus %s.%s "
			+ "This only restores context; no gameplay choice is filed."
		) % [title, handoff_context],
	}


func _activate_campaign_order_return_cue() -> void:
	if _campaign_order_return_cue.is_empty():
		return
	_clear_campaign_order_page_arrival()
	if _routing_ui != null and _routing_ui.has_method("clear_dispatch_tray_arrival"):
		_routing_ui.clear_dispatch_tray_arrival()
	var cue := _campaign_order_return_cue.duplicate(true)
	var objective_id := StringName(cue.get("objective_id", &""))
	var order_index := int(cue.get("order_index", -1))
	_campaign_order_return_activation_serial += 1
	_campaign_order_return_cue.clear()
	_open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	var target_available := false
	for glance in _campaign_order_glances:
		if (
			StringName(glance.get_meta("objective_id", &"")) == objective_id
			and glance.is_visible_in_tree()
		):
			target_available = true
			break
	_last_campaign_order_return_result = {
		"serial": _campaign_order_return_activation_serial,
		"source_serial": int(cue.get("serial", 0)),
		"objective_id": String(objective_id),
		"order_index": order_index,
		"icon_kind": String(cue.get("icon_kind", "goal")),
		"handoff_kind": String(cue.get("handoff_kind", "")),
		"target_available": target_available,
		"filed_choice": false,
	}
	call_deferred("_focus_campaign_order_glance", objective_id, order_index)
	if _simulation != null:
		_update_guidance(_simulation.snapshot())


func _open_campaign_order_driver_page(
	page_id: StringName,
	target_names: PackedStringArray,
) -> Control:
	_open_flockwatch_page(page_id)
	if _flockwatch_navigation == null or _flockwatch_navigation.current_page_id() != page_id:
		return null
	var target: Control
	for target_name: String in target_names:
		var candidate := find_child(target_name, true, false) as Control
		if candidate != null and candidate.is_visible_in_tree():
			target = candidate
			break
	if target == null:
		return null
	var scroll := _flockwatch_navigation.page_scroll(page_id)
	if scroll != null:
		# A large section can already intersect the viewport while its meaningful
		# heading remains far above it, causing ensure_control_visible() to retain
		# stale reading context. Land the exact driver target at the reading edge.
		var component_offset := (
			target.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 8.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	_flockwatch_navigation.focus_current_tab()
	_acknowledge_campaign_order_page_arrival(target, page_id)
	return target


func _acknowledge_campaign_order_page_arrival(
	target: Control,
	page_id: StringName,
) -> void:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return
	_clear_campaign_order_page_arrival()
	_campaign_order_page_arrival_serial += 1
	_campaign_order_page_arrival_target = target
	_campaign_order_page_arrival_target_name = String(target.name)
	_campaign_order_page_arrival_page_id = page_id
	_campaign_order_page_arrival_active = true
	_campaign_order_page_arrival_reduced_motion = _prefers_reduced_motion()
	_campaign_order_page_arrival_animated = not _campaign_order_page_arrival_reduced_motion
	if target is PanelContainer:
		_campaign_order_page_arrival_had_panel_override = target.has_theme_stylebox_override(
			"panel"
		)
		_campaign_order_page_arrival_original_style = target.get_theme_stylebox("panel")
		if _campaign_order_page_arrival_original_style != null:
			var arrival_style := (
				_campaign_order_page_arrival_original_style.duplicate() as StyleBox
			)
			if arrival_style is StyleBoxFlat:
				var arrival_flat := arrival_style as StyleBoxFlat
				arrival_flat.border_color = Color("f4d27b")
				arrival_flat.set_border_width_all(2)
				target.add_theme_stylebox_override("panel", arrival_flat)
	target.modulate = Color("fff0bd")
	var arrival_serial := _campaign_order_page_arrival_serial
	if not _campaign_order_page_arrival_reduced_motion:
		_campaign_order_page_arrival_tween = _presentation_tween(target)
		_campaign_order_page_arrival_tween.tween_interval(0.12)
		_campaign_order_page_arrival_tween.tween_property(
			target,
			"modulate",
			Color.WHITE,
			0.42,
		)
	get_tree().create_timer(0.62).timeout.connect(
		_settle_campaign_order_page_arrival.bind(arrival_serial)
	)


func _settle_campaign_order_page_arrival(arrival_serial: int) -> void:
	if (
		arrival_serial != _campaign_order_page_arrival_serial
		or not _campaign_order_page_arrival_active
	):
		return
	if (
		_campaign_order_page_arrival_target is PanelContainer
		and _campaign_order_page_arrival_original_style is StyleBoxFlat
	):
		if (
			_campaign_order_page_arrival_tween != null
			and _campaign_order_page_arrival_tween.is_valid()
		):
			_campaign_order_page_arrival_tween.kill()
		_campaign_order_page_arrival_tween = null
		_campaign_order_page_arrival_target.modulate = Color.WHITE
		var pinned_style := (
			_campaign_order_page_arrival_original_style.duplicate() as StyleBoxFlat
		)
		var pinned_border := Color("d9c47d")
		pinned_border.a = 0.72
		pinned_style.border_color = pinned_border
		if (
			pinned_style.border_width_left
			+ pinned_style.border_width_top
			+ pinned_style.border_width_right
			+ pinned_style.border_width_bottom
			== 0
		):
			pinned_style.set_border_width_all(1)
		_campaign_order_page_arrival_target.add_theme_stylebox_override(
			"panel",
			pinned_style,
		)
		_campaign_order_page_arrival_active = false
		_campaign_order_page_arrival_pinned = true
		return
	_clear_campaign_order_page_arrival()


func _clear_campaign_order_page_arrival() -> void:
	if (
		_campaign_order_page_arrival_tween != null
		and _campaign_order_page_arrival_tween.is_valid()
	):
		_campaign_order_page_arrival_tween.kill()
	_campaign_order_page_arrival_tween = null
	if (
		_campaign_order_page_arrival_target != null
		and is_instance_valid(_campaign_order_page_arrival_target)
	):
		if _campaign_order_page_arrival_target is PanelContainer:
			if (
				_campaign_order_page_arrival_had_panel_override
				and _campaign_order_page_arrival_original_style != null
			):
				_campaign_order_page_arrival_target.add_theme_stylebox_override(
					"panel",
					_campaign_order_page_arrival_original_style,
				)
			else:
				_campaign_order_page_arrival_target.remove_theme_stylebox_override(
					"panel"
				)
		_campaign_order_page_arrival_target.modulate = Color.WHITE
	_campaign_order_page_arrival_target = null
	_campaign_order_page_arrival_original_style = null
	_campaign_order_page_arrival_had_panel_override = false
	_campaign_order_page_arrival_active = false
	_campaign_order_page_arrival_pinned = false


func _refresh_campaign_order_glance_focus_style(glance: Label) -> void:
	var tile := _flockwatch_glance_tile(glance)
	if tile == null:
		return
	var accent: Color = glance.get_meta("focus_accent", Color("71838b"))
	var focused := (
		glance.has_focus()
		or _focused_campaign_order_id == StringName(glance.get_meta("objective_id", &""))
	)
	# Goal counts change every tick; the panel only changes with focus or status.
	if tile.has_meta("paint_accent") and tile.get_meta("paint_accent") == accent and bool(tile.get_meta("direct_focus", false)) == focused:
		return
	tile.set_meta("paint_accent", accent)
	var style := _panel_style(Color("182530"), 0.96, 6, 2 if focused else 1)
	style.border_color = Color(accent, 0.96 if focused else 0.34)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	tile.add_theme_stylebox_override("panel", style)
	tile.set_meta("direct_focus", focused)


func _campaign_objective_action_glance(
	metric: StringName,
	comparison: StringName,
	actual: int,
	target: int,
	eggs_today: int,
	on_track: bool,
) -> String:
	match metric:
		&"eggs":
			var remaining := maxi(0, target - actual)
			return "LAY %d EGGS\n%d / %d  ·  %s" % [
				target,
				actual,
				target,
				"DONE" if remaining == 0 else "%d LEFT" % remaining,
			]
		&"crack_rate_basis_points":
			if eggs_today == 0:
				return "CRACKS ≤ %.0f%%\nEGG 1 PENDING" % (float(target) / 100.0)
			return "CRACKS ≤ %.0f%%\n%.1f%%  ·  %s" % [
				float(target) / 100.0,
				float(actual) / 100.0,
				"SAFE" if on_track else "OVER",
			]
		&"welfare", &"average_welfare":
			return "WELFARE %d+\n%d NOW  ·  %s" % [
				target,
				actual,
				"SAFE" if on_track else "NEED %d" % maxi(0, target - actual),
			]
		&"farmer_favor", &"average_farmer_favor":
			return "FAVOR %d+\n%d  ·  %s" % [
				target,
				actual,
				"SAFE" if on_track else "NEED %d" % maxi(0, target - actual),
			]
	var label := _campaign_objective_short_label(metric)
	var difference := (
		maxi(0, actual - target)
		if comparison == &"maximum" else
		maxi(0, target - actual)
	)
	return "%s %s %d\n%d NOW  ·  %s" % [
		label,
		"≤" if comparison == &"maximum" else "≥",
		target,
		actual,
		"SAFE" if on_track else ("OVER %d" if comparison == &"maximum" else "NEED %d") % difference,
	]


func _sync_live_order_badge(
	on_track: int,
	total: int,
	senior_mode: bool,
	order_states: Array[Dictionary] = [],
) -> void:
	if _campaign_ui == null or not _campaign_ui.has_method("set_live_order_progress"):
		return
	var context := StringName("probation:%d" % (_campaign_state.completed_shifts + 1))
	if senior_mode and _senior_roost_state != null:
		context = StringName("senior:%d:%d" % [
			_senior_roost_state.current_year_number(),
			_senior_roost_state.current_quarter_in_year(),
		])
	var delta := int(_campaign_ui.call(
		"set_live_order_progress",
		on_track,
		total,
		context,
		order_states,
	))
	if delta == 0 or _audio_feedback == null:
		return
	if delta > 0:
		_audio_feedback.play_policy_stamp()
	else:
		_audio_feedback.play_shift_alert(0.28)


func _update_campaign_doctrine_label(senior_mode: bool) -> void:
	if _campaign_doctrine_label == null or _campaign_state == null:
		return
	var doctrine: Dictionary = _campaign_state.active_doctrine()
	_campaign_doctrine_label.visible = not senior_mode and not doctrine.is_empty()
	if not _campaign_doctrine_label.visible:
		_campaign_doctrine_label.text = ""
		_campaign_doctrine_label.tooltip_text = ""
		_campaign_doctrine_label.set_meta("accessible_text", "")
		_campaign_doctrine_label.set_meta("doctrine_id", "")
		_campaign_doctrine_label.set_meta("milestone_id", "")
		return
	var strengths := _doctrine_terms(doctrine.get("strengths", []))
	var watchouts := _doctrine_terms(doctrine.get("watchouts", []))
	var primary_strength := _doctrine_primary_term(doctrine.get("strengths", []))
	var primary_watchout := _doctrine_primary_term(doctrine.get("watchouts", []))
	var doctrine_name := String(doctrine.get("label", "PROBATION SPECIALTY"))
	_campaign_doctrine_label.text = "%s%s%s" % [
		doctrine_name,
		(
			"  ·  +%s" % _doctrine_compact_term(primary_strength)
			if not primary_strength.is_empty() else
			""
		),
		(
			"  ·  WATCH %s" % _doctrine_compact_term(primary_watchout)
			if not primary_watchout.is_empty() else
			""
		),
	]
	_campaign_doctrine_label.set_meta(
		"accessible_text",
		"ACTIVE DOCTRINE  //  %s  //  FULL EDGE  //  %s  //  WATCH  //  %s" % [
			doctrine_name,
			strengths,
			watchouts,
		],
	)
	_campaign_doctrine_label.tooltip_text = "%s\n\nPLAYBOOK  //  %s" % [
		String(doctrine.get("summary", "This specialization remains active for the probation file.")),
		"%s\n\nFULL EDGE  //  %s\nWATCH  //  %s" % [
			String(doctrine.get("playbook", "Use the safeguard ledger to cover this doctrine's obligations.")),
			strengths,
			watchouts,
		],
	]
	_campaign_doctrine_label.set_meta("doctrine_id", String(doctrine.get("milestone_id", "")))
	_campaign_doctrine_label.set_meta("milestone_id", String(doctrine.get("milestone_id", "")))


## The live policy is a high-frequency status, so its directive-specific shape
## replaces the repeated POLICY prefix at every scale. Exact filed terminology
## and consequences remain in tooltip and assistive copy.
func _apply_live_policy_scale(scale: float) -> void:
	if _directive_badge_host == null or _directive_badge == null:
		return
	var sanitized_scale := clampf(scale, 1.0, 1.5)
	var icon_led := true
	_directive_badge_host.custom_minimum_size.x = 150.0 if sanitized_scale >= 1.25 else 138.0
	_directive_badge_host.set_meta("interface_scale", sanitized_scale)
	_directive_badge_host.set_meta("compact_policy_mark", icon_led)
	_directive_badge_host.set_meta("icon_led_policy_mark", icon_led)
	_directive_badge.custom_minimum_size.x = 0.0
	_directive_badge.text = String(_directive_badge.get_meta(
		"compact_text",
		_directive_badge.text,
	))
	if _directive_badge_icon != null:
		_directive_badge_icon.visible = true


func _live_policy_icon(directive_id: StringName) -> StringName:
	match directive_id:
		&"record_harvest": return &"egg"
		&"shell_assurance": return &"shield"
		&"sustainable_flock": return &"flock"
	return &"goal"


func _live_policy_accent(icon_kind: StringName) -> Color:
	match icon_kind:
		&"egg": return Color("e99479")
		&"shield": return Color("9ccfc2")
		&"flock": return Color("9dd9a4")
		&"compact": return Color("d9c47d")
		&"pause": return Color("efb96d")
	return Color("efb96d")


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
		return ""
	return String((value as Array)[0]).strip_edges().to_upper()


func _doctrine_compact_term(term: String) -> String:
	const COMPACT_TERMS := {
		"FARMER FAVOR": "FAVOR",
		"FLOCK WELFARE": "WELFARE",
		"SHELL QUALITY": "QUALITY",
		"FEED FUND": "FUND",
		"RECOVERY DAYS": "RECOVERY",
		"QUOTA PRESSURE": "QUOTA",
		"SHELL SUPPORT": "SHELLS",
	}
	var normalized := term.strip_edges().to_upper()
	return String(COMPACT_TERMS.get(normalized, normalized))


func _update_flock_labor_label(snapshot: Dictionary) -> void:
	if _flock_labor_label == null:
		return
	var compact := snapshot.get("flock_compact", {}) as Dictionary
	var work_to_rule := snapshot.get("work_to_rule", {}) as Dictionary
	var last_petition := snapshot.get("flock_petition", {}) as Dictionary
	var labor_relevant := (
		not compact.is_empty()
		or bool(work_to_rule.get("active", false))
		or bool(work_to_rule.get("scheduled", false))
		or not last_petition.is_empty()
	)
	_flock_labor_label.visible = false
	if _flock_labor_glance_grid != null:
		_flock_labor_glance_grid.visible = labor_relevant
	if _flock_compact_glance != null:
		_flockwatch_glance_tile(_flock_compact_glance).visible = false
	if _work_to_rule_glance != null:
		_flockwatch_glance_tile(_work_to_rule_glance).visible = false
	if not labor_relevant:
		_flock_labor_label.text = ""
		_flock_labor_label.tooltip_text = (
			"Flock labor filings appear here when a petition, compact, or work-to-rule is active."
		)
		return
	var lines: Array[String] = []
	var accent := Color("b9c8cc")
	if not compact.is_empty():
		var compact_status := String(compact.get("status", "scheduled")).to_upper()
		lines.append("BINDING COMPACT  ·  %s" % String(compact.get("compact_name", "FLOCK COMPACT")))
		lines.append("%s  ·  %s FOR DAY %d" % [
			String(compact.get("sponsor_worker_name", "NAMED HEN")).to_upper(),
			compact_status,
			int(compact.get("effective_day", int(snapshot.get("day", 1)))),
		])
		lines.append("TEST  ·  %s" % String(compact.get("condition", "Closing ledger decides fulfillment.")))
		if _flock_compact_glance != null:
			_flockwatch_glance_tile(_flock_compact_glance).visible = true
			_flock_compact_glance.text = "COMPACT\n%s" % compact_status
		accent = Color("efcf83") if compact_status == "SCHEDULED" else Color("8fd1a1")
	var work_record := work_to_rule.get("record", {}) as Dictionary
	if bool(work_to_rule.get("active", false)) or bool(work_to_rule.get("scheduled", false)):
		var work_day := int(work_to_rule.get("day", int(snapshot.get("day", 1))))
		var work_multiplier := float(work_record.get("work_multiplier", 0.82))
		var crack_modifier := float(work_record.get("crack_modifier", -0.06))
		lines.append("WORK-TO-RULE  ·  %s DAY %d" % [
			"ACTIVE" if bool(work_to_rule.get("active", false)) else "SCHEDULED",
			work_day,
		])
		lines.append("Every written step  ·  throughput -%d%%  ·  crack risk %.0f pts" % [
			roundi((1.0 - work_multiplier) * 100.0),
			crack_modifier * 100.0,
		])
		if _work_to_rule_glance != null:
			_flockwatch_glance_tile(_work_to_rule_glance).visible = true
			_work_to_rule_glance.text = "WORK-RULE\nPACE -%d%%  SHELL %.0f" % [
				roundi((1.0 - work_multiplier) * 100.0),
				crack_modifier * 100.0,
			]
		accent = Color("df9278")
	if lines.is_empty():
		if not last_petition.is_empty():
			lines.append("LAST FLOCK PETITION  ·  %s" % String(last_petition.get("sponsor_worker_name", "NAMED HEN")).to_upper())
			lines.append(String(last_petition.get("outcome", "Management's response remains in the ledger.")))
			if _flock_compact_glance != null:
				_flockwatch_glance_tile(_flock_compact_glance).visible = true
				_flock_compact_glance.text = "PETITION\n%s  ·  FILED" % String(
					last_petition.get("sponsor_worker_name", "NAMED HEN")
				).to_upper()
		else:
			lines.append("FLOCK VOICE  ·  No binding compact is currently filed.")
		lines.append("Unity risk %d / %d before a denied petition can trigger work-to-rule." % [
			roundi(float(snapshot.get("solidarity", 0.0))),
			roundi(float(work_to_rule.get("threshold", 45.0))),
		])
	_flock_labor_label.text = "\n".join(lines)
	_flock_labor_label.tooltip_text = _flock_labor_label.text
	_flock_labor_label.set_meta("accessible_text", _flock_labor_label.text)
	_set_hud_font_color(_flock_labor_label, accent)
	for glance: Label in [_flock_compact_glance, _work_to_rule_glance]:
		if glance == null or not _flockwatch_glance_tile(glance).visible:
			continue
		glance.tooltip_text = _flock_labor_label.text
		_flockwatch_glance_tile(glance).tooltip_text = _flock_labor_label.text
		glance.set_meta("accessible_text", _flock_labor_label.text)
		_set_hud_font_color(glance, accent)
		_set_flockwatch_glance_icon(
			glance,
			StringName(glance.get_meta("icon_kind", &"goal")),
			accent,
		)


func _set_hud_font_color(control: Control, color: Color) -> void:
	# Reapplying an identical override still queues Godot theme/layout work.
	# Keep the actual override authoritative so external changes are repaired too.
	if not control.has_theme_color_override("font_color") or control.get_theme_color("font_color") != color:
		control.add_theme_color_override("font_color", color)


func _sync_flockwatch_glance(
	glance: Label,
	exact_label: Label,
	copy: String,
	accent: Color,
) -> void:
	if glance == null or exact_label == null:
		return
	var detail := "%s\n%s" % [exact_label.text, exact_label.tooltip_text]
	exact_label.set_meta("accessible_text", detail)
	glance.text = copy
	glance.tooltip_text = detail
	_flockwatch_glance_tile(glance).tooltip_text = detail
	glance.set_meta("accessible_text", detail)
	_set_hud_font_color(glance, accent)
	_set_flockwatch_glance_icon(
		glance,
		StringName(glance.get_meta("icon_kind", &"goal")),
		accent,
	)


func _compact_flockwatch_currency(cents: int) -> String:
	return str(cents / 100) if cents % 100 == 0 else "%.2f" % (float(cents) / 100.0)


func _signed_flockwatch_currency(cents: int) -> String:
	return "%s$%s" % [
		"+" if cents >= 0 else "-",
		_compact_flockwatch_currency(absi(cents)),
	]


func _update_break_even_milestone(snapshot: Dictionary) -> void:
	var briefing_value: Variant = snapshot.get("economic_briefing", {})
	if not briefing_value is Dictionary:
		return
	var cash_value: Variant = (briefing_value as Dictionary).get("cash", {})
	if not cash_value is Dictionary or (cash_value as Dictionary).is_empty():
		return
	var cash := cash_value as Dictionary
	var day := int(snapshot.get("day", 1))
	var margin_cents := int(cash.get("secured_operating_margin_cents", 0))
	if not _break_even_tracker_seeded or day != _break_even_tracker_day:
		_break_even_tracker_day = day
		_break_even_previous_margin_cents = margin_cents
		_break_even_tracker_seeded = true
		return
	if (
		_break_even_cleared_day != day
		and _break_even_previous_margin_cents < 0
		and margin_cents >= 0
	):
		_break_even_cleared_day = day
		var visible_copy := "BREAK EVEN CLEARED · NET %s" % _signed_flockwatch_currency(margin_cents)
		var accessible_copy := (
			"%s. Secured income now covers today's complete filed operating cost. "
			+ "Later income or obligations can still change the margin. Open Capital for the exact ledger."
		) % visible_copy
		_publish_status_copy(visible_copy, true, accessible_copy)
		if _audio_feedback != null and _audio_feedback.has_method("play_commendation"):
			_audio_feedback.call("play_commendation")
		if _today_cash_glance != null and _today_cash_glance.is_visible_in_tree():
			_pulse_action_target(_flockwatch_glance_tile(_today_cash_glance))
	_break_even_previous_margin_cents = margin_cents


func _update_records_archive_summary(snapshot: Dictionary) -> void:
	if _records_archive_label == null:
		return
	var board_value: Variant = snapshot.get("contract_board", {})
	var board := board_value as Dictionary if board_value is Dictionary else {}
	var active_value: Variant = board.get("active_contract", board.get("active", {}))
	var active_contract := active_value as Dictionary if active_value is Dictionary else {}
	var contract_line := "FARM MUTUAL / NO ACTIVE BINDER"
	if not active_contract.is_empty():
		var contract_name := String(active_contract.get(
			"short_name",
			active_contract.get("name", active_contract.get("label", "ACTIVE BINDER")),
		)).strip_edges().to_upper()
		var contract_status := String(active_contract.get("status", "ACTIVE")).strip_edges().to_upper()
		var target_day := maxi(0, int(active_contract.get("target_day", 0)))
		contract_line = "FARM MUTUAL / %s / %s%s" % [
			contract_name,
			contract_status,
			" DAY %d" % target_day if target_day > 0 else "",
		]

	var compact_value: Variant = snapshot.get("flock_compact", {})
	var compact := compact_value as Dictionary if compact_value is Dictionary else {}
	var petition_value: Variant = snapshot.get("flock_petition", {})
	var petition := petition_value as Dictionary if petition_value is Dictionary else {}
	var work_value: Variant = snapshot.get("work_to_rule", {})
	var work_to_rule := work_value as Dictionary if work_value is Dictionary else {}
	var labor_line := "FLOCK LABOR / QUIET"
	var labor_urgent := false
	if bool(work_to_rule.get("active", false)) or bool(work_to_rule.get("scheduled", false)):
		labor_urgent = true
		labor_line = "FLOCK LABOR / WORK-TO-RULE / %s" % (
			"ACTIVE" if bool(work_to_rule.get("active", false)) else "SCHEDULED"
		)
	elif not compact.is_empty():
		labor_line = "FLOCK LABOR / %s / %s" % [
			String(compact.get("compact_name", "BINDING COMPACT")).strip_edges().to_upper(),
			String(compact.get("status", "FILED")).strip_edges().to_upper(),
		]
	elif not petition.is_empty():
		labor_line = "FLOCK LABOR / PETITION / %s" % String(
			petition.get("sponsor_worker_name", "NAMED HEN")
		).strip_edges().to_upper()

	var receipt_parts: Array[String] = []
	var contract_receipt_value: Variant = board.get("last_result", board.get("decline_receipt", {}))
	var contract_receipt := (
		contract_receipt_value as Dictionary
		if contract_receipt_value is Dictionary else
		{}
	)
	if not contract_receipt.is_empty():
		receipt_parts.append("MUTUAL %s" % String(
			contract_receipt.get("status", "FILED")
		).strip_edges().to_upper())
	var compact_receipt_value: Variant = snapshot.get("flock_compact_receipt", {})
	var compact_receipt := (
		compact_receipt_value as Dictionary
		if compact_receipt_value is Dictionary else
		{}
	)
	if not compact_receipt.is_empty():
		receipt_parts.append("COMPACT %s" % String(
			compact_receipt.get("status", "FILED")
		).strip_edges().to_upper())
	var receipt_line := (
		"RECEIPTS / %s" % " / ".join(receipt_parts)
		if not receipt_parts.is_empty() else
		"RECEIPTS / NONE FILED"
	)
	_records_archive_label.text = "\n".join([contract_line, labor_line, receipt_line])
	_set_hud_font_color(
		_records_archive_label,
		Color("d68a68") if labor_urgent else Color("b9c8cc"),
	)


func commendations_snapshot() -> Dictionary:
	return _commendations_snapshot.duplicate(true)


func _update_commendations(snapshot: Dictionary, force: bool = false) -> void:
	var source_fingerprint := _commendations_fingerprint(snapshot)
	if not force and source_fingerprint == _commendations_source_fingerprint:
		return
	_commendations_source_fingerprint = source_fingerprint
	var campaign_snapshot: Dictionary = _campaign_state.snapshot() if _campaign_state != null else {}
	var senior_snapshot: Dictionary = _senior_roost_state.snapshot() if _senior_roost_state != null else {}
	var evaluated: Dictionary = CareerCommendationsScript.evaluate(
		snapshot,
		campaign_snapshot,
		senior_snapshot,
	)
	evaluated["management_identity"] = _simulation.leadership_record_snapshot()
	_commendations_snapshot = evaluated.duplicate(true)
	if _office_storytelling != null and _office_storytelling.has_method("set_commendations_snapshot"):
		_office_storytelling.call("set_commendations_snapshot", evaluated)
	var earned_count := int(evaluated.get("earned_count", 0))
	var total_count := int(evaluated.get("total_count", CareerCommendationsScript.IDS.size()))
	var next_value: Variant = evaluated.get("next", {})
	var next_stamp := next_value as Dictionary if next_value is Dictionary else {}
	if _commendations_disclosure_toggle != null:
		_commendations_disclosure_toggle.set_summary("%d / %d FILED" % [earned_count, total_count])
	if _commendations_summary_label != null:
		if bool(evaluated.get("complete", false)):
			_commendations_summary_label.text = (
				"COOP COMMENDATIONS  /  %d OF %d FILED\n"
				+ "ARCHIVE COMPLETE  /  EVERY STAMP IS PERMANENT RECOGNITION"
			) % [earned_count, total_count]
		else:
			_commendations_summary_label.text = (
				"COOP COMMENDATIONS  /  %d OF %d FILED\nNEXT STAMP  /  %s  /  %s"
			) % [
				earned_count,
				total_count,
				String(next_stamp.get("title", "CAREER FILE")),
				String(next_stamp.get("progress_label", "OPEN")),
			]

	var newly_earned: Array[Dictionary] = []
	var current_earned_ids: Dictionary[StringName, bool] = {}
	for row_value: Variant in evaluated.get("rows", []):
		if not row_value is Dictionary:
			continue
		var row := row_value as Dictionary
		var commendation_id := StringName(row.get("id", &""))
		var earned := bool(row.get("earned", false))
		if earned:
			current_earned_ids[commendation_id] = true
			if _commendations_seeded and not _known_commendation_ids.has(commendation_id):
				newly_earned.append(row)
		var bindings := _commendation_rows.get(commendation_id, {}) as Dictionary
		if bindings.is_empty():
			continue
		var panel := bindings.get("panel") as PanelContainer
		var mark := bindings.get("mark") as Label
		var title := bindings.get("title") as Label
		var progress := bindings.get("progress") as Label
		var detail := bindings.get("detail") as Label
		var row_style := _commendation_earned_style if earned else _commendation_locked_style
		if panel != null and panel.get_theme_stylebox("panel") != row_style:
			panel.add_theme_stylebox_override(
				"panel",
				row_style,
			)
		if mark != null:
			mark.text = "FILED" if earned else "OPEN"
			_set_hud_font_color(mark, Color("f0ca72") if earned else Color("82909a"))
		if title != null:
			title.text = String(row.get("title", "COMMENDATION"))
			_set_hud_font_color(title, Color("f1d58c") if earned else Color("c9d1d5"))
		if progress != null:
			progress.text = String(row.get("progress_label", "OPEN"))
			_set_hud_font_color(progress, Color("d9bf78") if earned else Color("9aa8af"))
		if detail != null:
			detail.text = "%s  /  RECOGNITION: %s" % [
				String(row.get("description", "")),
				String(row.get("recognition", "Archive stamp")),
			]
		bindings["earned"] = earned

	_known_commendation_ids = current_earned_ids
	if not _commendations_seeded:
		_commendations_seeded = true
		return
	if newly_earned.is_empty():
		return
	var primary := newly_earned[0]
	_ticker_label.text = "COMMENDATION FILED  /  %s  /  %d OF %d%s" % [
		String(primary.get("title", "CAREER STAMP")),
		earned_count,
		total_count,
		"  /  +%d MORE" % (newly_earned.size() - 1) if newly_earned.size() > 1 else "",
	]
	if _audio_feedback != null and _audio_feedback.has_method("play_commendation"):
		_audio_feedback.call("play_commendation")


func _commendations_fingerprint(snapshot: Dictionary) -> int:
	var facility_tiers := 0
	var owned_value: Variant = snapshot.get("owned_facilities", {})
	if owned_value is Dictionary:
		for level_value: Variant in (owned_value as Dictionary).values():
			facility_tiers += maxi(0, int(level_value))
	var mandate_mastery_counts: Array[int] = []
	if _senior_roost_state != null:
		for mandate_id in SeniorRoostStateScript.MANDATE_IDS:
			mandate_mastery_counts.append(maxi(
				0,
				int(_senior_roost_state.mandate_success_counts.get(mandate_id, 0)),
			))
	return hash([
		int(snapshot.get("eggs_total", 0)),
		int(snapshot.get("best_quality_streak", 0)),
		int(snapshot.get("market_contracts_succeeded_total", 0)),
		int((snapshot.get("incident_pivot_mastery", {}) as Dictionary).get("mastered_count", 0)),
		int(snapshot.get("office_capacity", 4)),
		facility_tiers,
		String(_campaign_state.chosen_milestone_id) if _campaign_state != null else "",
		int(_campaign_state.completed_shifts) if _campaign_state != null else 0,
		String(_campaign_state.outcome) if _campaign_state != null else "in_progress",
		String(_senior_roost_state.status) if _senior_roost_state != null else "inactive",
		int(_senior_roost_state.total_senior_shifts) if _senior_roost_state != null else 0,
		int(_senior_roost_state.mandate_seals) if _senior_roost_state != null else 0,
		mandate_mastery_counts,
	])


func _refresh_commendations_from_authority() -> void:
	if _simulation == null:
		return
	var snapshot := _simulation.snapshot()
	_update_commendations(snapshot)
	_publish_web_diagnostic_state(snapshot)


func _set_campaign_modal_open(is_open: bool) -> void:
	if is_open:
		_clock.set_speed(0)
		_set_flockwatch_open(false)
	_refresh_floor_input_context()
	_on_speed_changed(_clock.speed_index, SimulationClock.SPEED_MULTIPLIERS[_clock.speed_index])
	_refresh_first_clutch_ui(_simulation.snapshot())


func _show_campaign_title(continue_available: bool) -> void:
	_campaign_session_checkpoint_enabled = false
	_first_session_funnel.begin_intake()
	# Intake owns the screen. Recovery, portable import, and fresh-title paths can
	# arrive while an in-memory morning decision or closing review still exists;
	# retire those underlying surfaces here so they cannot steal focus or
	# assistive priority from the visible title card.
	if _decision_host != null:
		_decision_host.visible = false
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	var resume_summary := _campaign_resume_summary() if continue_available else {}
	var selected_challenge_id := CampaignStateScript.CHALLENGE_STANDARD_FILING
	if _campaign_ui != null and _campaign_ui.has_method("selected_challenge_contract_id"):
		var ui_selection := StringName(_campaign_ui.call("selected_challenge_contract_id"))
		if not CampaignStateScript.challenge_contract(ui_selection).is_empty():
			selected_challenge_id = ui_selection
	if _campaign_ui != null and _campaign_ui.has_method("selected_replay_scenario_id"):
		_selected_replay_scenario_id = StringName(_campaign_ui.call("selected_replay_scenario_id"))
	var slot_catalog := CareerPortfolioStoreScript.slot_catalog()
	for slot: Dictionary in slot_catalog:
		var slot_store = CampaignSaveStoreScript.new(String(slot.get("filename", CAMPAIGN_SAVE_FILENAME)))
		var occupied := slot_store.has_save()
		slot["occupied"] = occupied
		slot["label"] = "%s%s" % [
			String(slot.get("label", "ROOST")),
			"  •  SAVED" if occupied else "  •  OPEN",
		]
	_campaign_ui.apply_snapshot({
		"view": &"title",
		"day": 1,
		"total_days": CampaignStateScript.CAMPAIGN_LENGTH,
		"chapter": CampaignStateScript.shift_chapter(1),
		"continue_available": continue_available,
		"resume_summary": resume_summary,
		"challenge_contract_catalog": CampaignStateScript.challenge_contract_catalog(),
		"selected_new_challenge_contract_id": String(selected_challenge_id),
		"active_career_slot": String(_active_career_slot),
		"career_profile": _career_profile.duplicate(true),
		"career_slot_catalog": slot_catalog,
		"career_identity_catalog": CareerPortfolioStoreScript.identity_catalog(),
		"replay_scenario_catalog": DepartmentSimulation.replay_scenario_catalog(),
		"selected_replay_scenario_id": String(_selected_replay_scenario_id),
	})
	_campaign_ui.show_title(continue_available)


func _campaign_resume_summary() -> Dictionary:
	if _campaign_store == null:
		return {}
	var envelope_value: Variant = _campaign_store.load()
	if not envelope_value is Dictionary:
		return {}
	var envelope := envelope_value as Dictionary
	if envelope.is_empty():
		return {}
	# Continue is intentionally offered from an envelope candidate before the full
	# campaign is activated. Treat every nested preview payload as untrusted so a
	# malformed candidate cannot crash intake or invent authoritative save copy.
	var metadata := _resume_dictionary(envelope.get("metadata"))
	var payload := _resume_dictionary(envelope.get("campaign"))
	var session := _resume_dictionary(payload.get("session"))
	var campaign_ledger := _resume_dictionary(payload.get("campaign"))
	var senior_data := _resume_dictionary(payload.get("senior_roost"))
	var return_recap := _campaign_return_recap(payload, metadata, session)
	var offline_recap := _campaign_offline_recap(
		_resume_integer(metadata.get("saved_at_unix"), 0),
	)
	var senior_active := _resume_boolean(session.get("senior_roost"), false)
	var rank_id := StringName(String(metadata.get("probation_rank", "probationary")))
	var stage := StringName(String(metadata.get("review_stage", "active")))
	var stage_label := "SHIFT IN PROGRESS"
	var campaign_schema := _resume_integer(campaign_ledger.get("schema_version"), -1)
	var campaign_schema_id := String(campaign_ledger.get("schema_id", ""))
	var saved_challenge: Dictionary = {}
	var challenge_contract_verified := false
	if campaign_schema_id == CampaignStateScript.SCHEMA_ID and campaign_schema == 1:
		# Campaign schema v1 predates selection and migrates canonically to Standard.
		saved_challenge = CampaignStateScript.challenge_contract(
			CampaignStateScript.CHALLENGE_STANDARD_FILING
		)
		challenge_contract_verified = not saved_challenge.is_empty()
	elif (
		campaign_schema_id == CampaignStateScript.SCHEMA_ID
		and campaign_schema == CampaignStateScript.SCHEMA_VERSION
	):
		var challenge_id_value: Variant = campaign_ledger.get("challenge_contract_id")
		if challenge_id_value is String or challenge_id_value is StringName:
			var persisted_challenge_id := String(challenge_id_value)
			var saved_challenge_id := StringName(persisted_challenge_id)
			saved_challenge = CampaignStateScript.challenge_contract(saved_challenge_id)
			challenge_contract_verified = (
				not saved_challenge.is_empty()
				and persisted_challenge_id == String(saved_challenge.get("id", ""))
			)
			if not challenge_contract_verified:
				saved_challenge.clear()
	match stage:
		&"farmer":
			stage_label = "FARMER REVIEW"
		&"credit":
			stage_label = "CREDIT MEMO"
		&"probation":
			stage_label = "PROBATION REPORT"
		&"contract_board":
			stage_label = "MORNING CONTRACT BOARD"
		&"final":
			stage_label = "FINAL REVIEW"
		&"senior_quarter":
			stage_label = "SENIOR QUARTER"
		&"senior_annual":
			stage_label = "SENIOR ANNUAL REVIEW"
	return {
		"day": maxi(1, _resume_integer(metadata.get("day"), 1)),
		"completed_shifts": maxi(0, _resume_integer(metadata.get("completed_shifts"), 0)),
		"probation_score": clampi(
			_resume_integer(
				metadata.get("probation_score"),
				CampaignStateScript.STARTING_SCORE,
			),
			0,
			100,
		),
		"rank_label": CampaignStateScript.rank_display_name(rank_id),
		"stage_label": stage_label,
		"challenge_contract": {} if senior_active else saved_challenge,
		"challenge_contract_verified": challenge_contract_verified,
		"senior_roost": senior_active,
		"senior_year": maxi(1, _resume_integer(senior_data.get("completed_years"), 0) + 1),
		"roost_marks": maxi(0, _resume_integer(senior_data.get("roost_marks"), 0)),
		"mandate_seals": maxi(0, _resume_integer(senior_data.get("mandate_seals"), 0)),
		"return_recap": return_recap,
		"offline_recap": offline_recap,
		"recovered_from_backup": _resume_boolean(envelope.get("recovered_from_backup"), false),
		"recovery_source": String(envelope.get("recovery_source", "primary")),
	}


func _campaign_offline_recap(saved_at_unix: int, now_unix: int = -1) -> Dictionary:
	## Pecking Order deliberately has no idle accrual. The saved timestamp is used
	## only to disclose snapshot age; it never feeds production or finance. Clock
	## anomalies therefore change this label, not the authoritative economy.
	var observed_now := (
		int(Time.get_unix_time_from_system())
		if now_unix < 0 else
		now_unix
	)
	var elapsed_seconds := observed_now - saved_at_unix
	var elapsed_label := "SAVE TIME NOT FILED"
	var elapsed_short_label := "TIME UNKNOWN"
	var clock_anomaly := false
	if saved_at_unix > 0:
		if elapsed_seconds < 0:
			elapsed_seconds = 0
			elapsed_label = "CLOCK MOVED BACKWARD"
			elapsed_short_label = "CLOCK CHANGE"
			clock_anomaly = true
		else:
			elapsed_label = _offline_elapsed_label(elapsed_seconds)
			elapsed_short_label = _offline_elapsed_short_label(elapsed_seconds)
	return {
		"version": 1,
		"status_id": "paused",
		"status_label": "ECONOMY PAUSED",
		"elapsed_seconds": maxi(0, elapsed_seconds),
		"elapsed_label": elapsed_label,
		"elapsed_short_label": elapsed_short_label,
		"clock_anomaly": clock_anomaly,
		"detail": (
			"No files advanced, eggs were laid, costs posted, or Feed Fund changed "
			+ "while the terminal was closed."
		),
	}


func _offline_elapsed_label(elapsed_seconds: int) -> String:
	var bounded_seconds := maxi(0, elapsed_seconds)
	if bounded_seconds < 60:
		return "UNDER 1 MINUTE SINCE LAST FILE"
	var total_minutes := bounded_seconds / 60
	if total_minutes < 60:
		return "%d MINUTE%s SINCE LAST FILE" % [
			total_minutes,
			"" if total_minutes == 1 else "S",
		]
	var total_hours := total_minutes / 60
	var remaining_minutes := total_minutes % 60
	if total_hours < 24:
		var hour_label := "%d HOUR%s" % [
			total_hours,
			"" if total_hours == 1 else "S",
		]
		if remaining_minutes > 0:
			hour_label += " %d MINUTE%s" % [
				remaining_minutes,
				"" if remaining_minutes == 1 else "S",
			]
		return "%s SINCE LAST FILE" % hour_label
	var total_days := total_hours / 24
	if total_days >= 30:
		return "30+ DAYS SINCE LAST FILE"
	var remaining_hours := total_hours % 24
	var day_label := "%d DAY%s" % [
		total_days,
		"" if total_days == 1 else "S",
	]
	if remaining_hours > 0:
		day_label += " %d HOUR%s" % [
			remaining_hours,
			"" if remaining_hours == 1 else "S",
		]
	return "%s SINCE LAST FILE" % day_label


func _offline_elapsed_short_label(elapsed_seconds: int) -> String:
	var bounded_seconds := maxi(0, elapsed_seconds)
	if bounded_seconds < 60:
		return "<1M"
	var total_minutes := bounded_seconds / 60
	if total_minutes < 60:
		return "%dM" % total_minutes
	var total_hours := total_minutes / 60
	if total_hours < 24:
		var remaining_minutes := total_minutes % 60
		return (
			"%dH" % total_hours
			if remaining_minutes == 0 else
			"%dH %dM" % [total_hours, remaining_minutes]
		)
	var total_days := total_hours / 24
	if total_days >= 30:
		return "30D+"
	var remaining_hours := total_hours % 24
	return (
		"%dD" % total_days
		if remaining_hours == 0 else
		"%dD %dH" % [total_days, remaining_hours]
	)


func _campaign_return_recap(
	payload: Dictionary,
	metadata: Dictionary,
	session: Dictionary,
) -> Dictionary:
	## The title must not activate an envelope candidate merely to describe it.
	## Restore an isolated simulation instead, then reuse the same authoritative
	## economic briefing that drives Capital. Invalid semantic state simply earns
	## no economic preview and remains subject to the ordinary Continue verifier.
	var simulation_data := _resume_dictionary(payload.get("simulation"))
	if simulation_data.is_empty():
		return {}
	var preview_simulation := DepartmentSimulation.new(1701)
	if not preview_simulation.restore_save_state(simulation_data):
		return {}
	var briefing := preview_simulation.economic_briefing_snapshot()
	var bottleneck_values: Variant = briefing.get("bottlenecks", [])
	if not bottleneck_values is Array or (bottleneck_values as Array).is_empty():
		return {}
	var bottleneck_value: Variant = (bottleneck_values as Array)[0]
	if not bottleneck_value is Dictionary:
		return {}
	var bottleneck := bottleneck_value as Dictionary
	var severity := clampi(int(bottleneck.get("severity", 0)), 0, 4)
	var checkpoint_reason := String(metadata.get("reason", "")).strip_edges()
	var last_report := _resume_dictionary(session.get("last_workday_report"))
	var completed_shifts := maxi(0, _resume_integer(metadata.get("completed_shifts"), 0))
	var routing_review := _resume_dictionary(last_report.get("routing_review"))
	if routing_review.is_empty():
		var routing_report := last_report.duplicate(true)
		if not routing_report.has("routing_momentum"):
			routing_report["routing_momentum"] = preview_simulation.routing_momentum_snapshot()
		routing_review = _routing_review_receipt(routing_report)
	return {
		"version": 2,
		"last_filed_label": _resume_checkpoint_action_label(
			checkpoint_reason,
			completed_shifts,
			last_report,
		),
		"status_id": "clear" if severity <= 0 else "attention",
		"status_label": String(bottleneck.get(
			"label",
			"NO CRITICAL BOTTLENECK",
		)).strip_edges().to_upper(),
		"status_reason": String(bottleneck.get(
			"reason",
			"Current systems remain inside their filed limits.",
		)).strip_edges(),
		"next_action": String(bottleneck.get(
			"action",
			"Compare the next disclosed tradeoff.",
		)).strip_edges(),
		"feed_fund_cents": maxi(0, int(
			(briefing.get("cash", {}) as Dictionary).get("feed_fund_cents", 0)
		)),
		"spendable_fund_cents": maxi(0, int(
			(briefing.get("cash", {}) as Dictionary).get("spendable_fund_cents", 0)
		)),
		"routing_mastery": routing_review,
	}


func _arm_routing_return_cue(return_recap: Dictionary) -> bool:
	_routing_return_cue.clear()
	if _routing_ui != null and _routing_ui.has_method("reset_return_cue_focus_state"):
		_routing_ui.reset_return_cue_focus_state()
	var mastery := _resume_dictionary(return_recap.get("routing_mastery"))
	var best_chain := maxi(0, int(mastery.get("best_chain", 0)))
	var next_record := maxi(0, int(mastery.get("next_record", 0)))
	if (
		best_chain < DepartmentSimulation.ROUTING_MOMENTUM_CELEBRATION_MILESTONE
		or next_record <= best_chain
		or String(mastery.get("target_kind", "")) != "record"
	):
		return false
	_routing_return_cue_serial += 1
	_routing_return_cue = {
		"version": 1,
		"serial": _routing_return_cue_serial,
		"best_chain": best_chain,
		"next_record": next_record,
		"copy": "ROUTING RECORD  x%d  /  CHASE  x%d" % [best_chain, next_record],
		"accessible_text": (
			"Welcome back. Your best-fit routing record is %d consecutive recommended "
			+ "tray assignments. The next mastery record is %d. Activate to focus the "
			+ "most urgent intake tray; you still choose the best-fit hen."
		) % [best_chain, next_record],
		"armed_day": _simulation.day if _simulation != null else 0,
		"source": "verified_return_recap",
	}
	return true


func _dismiss_routing_return_cue(
	route_receipt: Dictionary,
	delivery_started := false,
) -> bool:
	if _routing_return_cue.is_empty() or not bool(route_receipt.get("accepted", false)):
		return false
	var focus_state := (
		_routing_ui.return_cue_focus_state()
		if _routing_ui != null and _routing_ui.has_method("return_cue_focus_state") else
		{}
	) as Dictionary
	var retired_resolved_alert := _retire_resolved_routing_action_toast(route_receipt)
	var settlement_handoff_armed := (
		_arm_route_settlement_handoff(route_receipt)
		if delivery_started else
		false
	)
	_last_routing_return_cue_dismissal = {
		"serial": int(_routing_return_cue.get("serial", 0)),
		"best_chain": int(_routing_return_cue.get("best_chain", 0)),
		"next_record": int(_routing_return_cue.get("next_record", 0)),
		"day": _simulation.day if _simulation != null else 0,
		"worker_id": int(route_receipt.get("worker_id", -1)),
		"lane": String(route_receipt.get("lane", "")),
		"focus_target_lane": String(focus_state.get("lane", "")),
		"focus_reason": String(focus_state.get("reason", "")),
		"reason": "first_accepted_route",
		"resolved_action_toast_retired": retired_resolved_alert,
		"settlement_handoff_armed": settlement_handoff_armed,
	}
	_routing_return_cue.clear()
	if _routing_ui != null and _routing_ui.has_method("clear_dispatch_tray_focus_fallback"):
		_routing_ui.clear_dispatch_tray_focus_fallback()
	_update_guidance(_simulation.snapshot())
	return true


func _arm_route_settlement_handoff(route_receipt: Dictionary) -> bool:
	var deferred_batch_count := _deferred_settlement_feedback_batch_count()
	if deferred_batch_count <= 0:
		return false
	_settlement_feedback_route_handoff_serial += 1
	var now_msec := Time.get_ticks_msec()
	_settlement_feedback_route_handoff = {
		"serial": _settlement_feedback_route_handoff_serial,
		"status": "awaiting_folder_landing",
		"worker_id": int(route_receipt.get("worker_id", -1)),
		"lane": String(route_receipt.get("lane", "")),
		"deferred_batch_count": deferred_batch_count,
		"armed_at_msec": now_msec,
		"elapsed_seconds": 0.0,
		"timeout_seconds": SETTLEMENT_ROUTE_HANDOFF_TIMEOUT_SECONDS,
		"physical_landing_cue_played": false,
		"causal_path": "accepted_route>folder_landing>receipt_fan",
	}
	return true


func _deferred_settlement_feedback_batch_count() -> int:
	var count := 0
	for visual in _active_fund_credit_chips:
		if visual.active and visual.deferred:
			count += 1
	for visual in _active_auxiliary_settlement_chips:
		if visual.active and visual.deferred:
			count += 1
	return count


func _accept_route_settlement_landing(worker_id: int, receipt: Dictionary) -> bool:
	if (
		_settlement_feedback_route_handoff.is_empty()
		or String(_settlement_feedback_route_handoff.get("status", ""))
		!= "awaiting_folder_landing"
		or worker_id != int(_settlement_feedback_route_handoff.get("worker_id", -1))
	):
		return false
	var expected_lane := String(_settlement_feedback_route_handoff.get("lane", ""))
	if not expected_lane.is_empty() and String(receipt.get("lane", "")) != expected_lane:
		return false
	var landing_world_point := Vector3.ZERO
	if (
		_workstation_feedback != null
		and _workstation_feedback.has_method("dispatch_landing_point_global")
	):
		landing_world_point = _workstation_feedback.dispatch_landing_point_global(worker_id)
	_settlement_feedback_route_handoff["status"] = "folder_landed"
	_settlement_feedback_route_handoff["landing_receipt_serial"] = int(receipt.get("serial", 0))
	_settlement_feedback_route_handoff["landing_world_point"] = landing_world_point
	_settlement_feedback_route_handoff["landing_screen_center"] = (
		_management_camera.unproject_position(landing_world_point)
		if _management_camera != null else
		Vector2.ZERO
	)
	_settlement_feedback_route_handoff["landed_at_msec"] = Time.get_ticks_msec()
	return true


func _expire_route_settlement_handoff_if_needed() -> bool:
	if (
		_settlement_feedback_route_handoff.is_empty()
		or String(_settlement_feedback_route_handoff.get("status", ""))
		!= "awaiting_folder_landing"
		or float(_settlement_feedback_route_handoff.get("elapsed_seconds", 0.0))
		< SETTLEMENT_ROUTE_HANDOFF_TIMEOUT_SECONDS
	):
		return false
	_settlement_feedback_route_handoff["status"] = "landing_timeout_fallback"
	_settlement_feedback_route_handoff["timed_out_at_msec"] = Time.get_ticks_msec()
	_settlement_feedback_last_route_handoff = (
		_settlement_feedback_route_handoff.duplicate(true)
	)
	_settlement_feedback_route_handoff.clear()
	return true


func _process_route_settlement_handoff(delta: float) -> void:
	if (
		_settlement_feedback_route_handoff.is_empty()
		or String(_settlement_feedback_route_handoff.get("status", ""))
		!= "awaiting_folder_landing"
	):
		return
	_settlement_feedback_route_handoff["elapsed_seconds"] = (
		float(_settlement_feedback_route_handoff.get("elapsed_seconds", 0.0))
		+ maxf(0.0, delta)
	)


func _retire_resolved_routing_action_toast(route_receipt: Dictionary) -> bool:
	if (
		not bool(route_receipt.get("accepted", false))
		or _ticker_panel == null
		or not _ticker_panel.visible
		or _status_priority(_ticker_visible_copy) != &"action"
	):
		return false
	var normalized := _ticker_visible_copy.to_upper()
	# Only retire a routing deadline the accepted route actually resolves. Other
	# action alerts keep their full hold and continue to arbitrate routine cards.
	if "OVERDUE" not in normalized or "ROUTE" not in normalized:
		return false
	var routed_lane := String(route_receipt.get("lane", "")).replace("_", " ").to_upper()
	if not routed_lane.is_empty() and routed_lane not in normalized:
		return false
	_ticker_panel.visible = false
	_ticker_visible_copy = ""
	_ticker_hide_at_msec = Time.get_ticks_msec()
	# A lower-priority route receipt may already be the archived latest record
	# even though priority preservation restored the old alert into the label.
	# Reconcile the legacy publisher surface so _process cannot resurrect the
	# resolved warning on its next frame.
	if _ticker_label != null and not _ticker_last_text.is_empty():
		_ticker_label.text = _ticker_last_text
	return true


func _resume_checkpoint_action_label(
	reason: String,
	completed_shifts: int,
	last_report: Dictionary,
) -> String:
	var normalized := reason.strip_edges().to_lower()
	if normalized.begins_with("facility_purchased_"):
		return "FACILITY COMMISSIONED"
	if normalized.begins_with("feed_order_"):
		return "PROVISIONS ORDER FILED"
	if normalized.begins_with("farmgate_dispatch_"):
		return "FARMGATE ROUTE FILED"
	if normalized.begins_with("farmer_relations_campaign_"):
		return "PUBLIC-CREDIT CAMPAIGN FILED"
	if normalized.begins_with("flock_relations_"):
		return "FLOCK RELATIONS CASE FILED"
	if normalized.begins_with("manager_instruction_"):
		return "MANAGEMENT INSTRUCTION FILED"
	if normalized.begins_with("capital_plan_pinned_"):
		return "CAPITAL PLAN PINNED"
	if normalized.begins_with("economic_watch_pinned_"):
		return "MANAGEMENT WATCH PINNED"
	if normalized.begins_with("campus_"):
		return "CAMPUS CAPITAL FILED"
	match normalized:
		"new_campaign":
			return "NEW COOP FILE OPENED"
		"returned_to_intake":
			return "COOP FILE SAFELY SHELVED"
		"workday_completed":
			return "SHIFT %d CLOSED" % maxi(1, completed_shifts)
		"decision_resolved":
			return "MANAGEMENT DECISION FILED"
		"credit_memo_opened", "credit_memo_required":
			return "CLOSING CREDIT MEMO OPENED"
		"probation_report":
			return "PROBATION REPORT FILED"
		"market_contract_signed":
			return "MUTUAL BINDER SIGNED"
		"market_contract_declined":
			return "STANDARD BOOK FILED"
		"market_contract_board":
			return "MORNING CONTRACT BOARD OPENED"
		"milestone_selected":
			return "PERMANENT MILESTONE FILED"
		"routing_assignment":
			return "ROUTING PLAN FILED"
		"routing_assignment_undo":
			return "ROUTING CHANGE UNDONE"
		"claim_resolution":
			return "CLAIMANT RESOLUTION FILED"
		"personnel_action":
			return "HEN SUPPORT ACTION FILED"
		"peck_assist":
			return "PRIORITY PECK FILED"
		"feed_party_funded":
			return "FEED PARTY FUNDED"
		"overtime_toggled":
			return "AFTER-HOURS POLICY FILED"
		"upgrade_purchased":
			return "WORKSTATION UPGRADE FILED"
		"worker_hired":
			return "NEW HEN HIRED"
		"worker_released":
			return "HEN RELEASE FILED"
		"capacity_expanded":
			return "NEW WORKSTATION COMMISSIONED"
		"first_clutch_completed":
			return "FIRST CLUTCH COMPLETED"
		"first_clutch_skipped":
			return "FIRST CLUTCH GUIDANCE SKIPPED"
		"senior_annual_mandate_selected":
			return "ANNUAL BOARD MANDATE FILED"
		"senior_quarter_policy":
			return "SENIOR CAPITAL POLICY FILED"
		"career_sponsorship_authorized":
			return "CAREER SPONSORSHIP FILED"
		"senior_roost_entered":
			return "SENIOR ROOST OPENED"
		"senior_year_transition":
			return "NEXT SENIOR YEAR OPENED"
		"final_review":
			return "FINAL REVIEW FILED"
	if not last_report.is_empty():
		var report_day := maxi(1, _resume_integer(
			last_report.get("day"),
			maxi(1, completed_shifts),
		))
		return "SHIFT %d RESULTS FILED" % report_day
	return "CURRENT COOP FILE VERIFIED"


func _resume_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _resume_integer(value: Variant, fallback: int) -> int:
	if value is int:
		return int(value)
	if value is float:
		var numeric := float(value)
		if not is_nan(numeric) and not is_inf(numeric) and floor(numeric) == numeric:
			return int(numeric)
	return fallback


func _resume_boolean(value: Variant, fallback: bool) -> bool:
	return bool(value) if value is bool else fallback


func _should_bypass_campaign_title() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	return _is_capture_launch()


func _is_capture_launch() -> bool:
	for argument in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if String(argument).begins_with("--capture"):
			return true
	return false


func _json_safe_variant(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var safe_dictionary: Dictionary = {}
			for key: Variant in value as Dictionary:
				safe_dictionary[String(key)] = _json_safe_variant((value as Dictionary)[key])
			return safe_dictionary
		TYPE_ARRAY:
			var safe_array: Array = []
			for item: Variant in value as Array:
				safe_array.append(_json_safe_variant(item))
			return safe_array
		TYPE_STRING_NAME:
			return String(value)
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return value
		_:
			return str(value)


func _campaign_modal_primary_action_state() -> Dictionary:
	if _campaign_ui == null or not _campaign_ui.is_modal_open():
		return {}
	match _campaign_ui.modal_state():
		ProbationCampaignUI.VIEW_TITLE:
			return _campaign_ui.title_primary_action_state()
		ProbationCampaignUI.VIEW_REPORT:
			return _campaign_ui.report_primary_action_state()
		ProbationCampaignUI.VIEW_CONTRACT_BOARD:
			return _campaign_ui.contract_board_primary_action_state()
		ProbationCampaignUI.VIEW_FINAL:
			return _campaign_ui.final_primary_action_state()
	return {}


func _campaign_modal_accessibility_name() -> String:
	if _campaign_ui == null:
		return "Campaign record"
	match _campaign_ui.modal_state():
		ProbationCampaignUI.VIEW_REPORT:
			return "Campaign report"
		ProbationCampaignUI.VIEW_CONTRACT_BOARD:
			return "Farm Mutual contract board"
		ProbationCampaignUI.VIEW_FINAL:
			return "Campaign final review"
	return "Campaign record"


func _on_active_playbook_item_pressed(item_id: int) -> void:
	if _simulation == null or not _active_playbook_menu_map.has(item_id):
		return
	var option := _active_playbook_menu_map[item_id] as Dictionary
	var kind := StringName(option.get("kind", &""))
	var choice_id := StringName(option.get("id", &""))
	if kind == &"learn_care":
		if _blocking_management_surface_open():
			return
		var lesson_worker_id := maxi(0, _active_playbook_focused_worker_id)
		_camera_controller.focus_worker(lesson_worker_id)
		_routing_ui.set_focus(lesson_worker_id)
		_routing_ui.begin_care_lesson()
		_publish_status_copy("OPTIONAL CHECK-IN · Try the highlighted choice, or Later.", false)
		return
	var before_playbook_snapshot := _simulation.snapshot()
	var result := _simulation.perform_playbook_action(
		kind,
		choice_id,
		_active_playbook_focused_worker_id,
	)
	var outcome := String(result.get("outcome", result.get("reason", "Playbook action unavailable.")))
	_publish_status_copy(outcome, true, outcome)
	if not bool(result.get("accepted", false)):
		return
	if String(result.get("playbook_kind", "")) == "teamwork":
		_begin_payoff_breath()
		for teammate_id in [int(result.get("worker_id", -1)), int(result.get("partner_id", -1))]:
			var teammate := _worker_views.get(teammate_id) as ChickenView
			if teammate != null:
				teammate.play_short_bark("TOGETHER!", &"team")
	if kind == &"preset":
		_begin_payoff_breath()
		var plan_hen := _worker_views.get(maxi(0, _active_playbook_focused_worker_id)) as ChickenView
		_character_dialogue_ui.hold_ambient(3.0)
		if plan_hen != null:
			plan_hen.play_short_bark("QUICK FILES, CAREFUL SHELLS!" if choice_id == &"fast" else "SHELL SAFETY FIRST!" if choice_id == &"safe" else "BREAKS ARE PART OF THE PLAN!", &"team")
		if _office_atmosphere != null:
			_office_atmosphere.pulse_strategy_reward()
	if String(result.get("playbook_kind", "")) == "partnership":
		for teammate_id in [int(result.get("worker_id", -1)), int(result.get("partner_id", -1))]:
			var teammate := _worker_views.get(teammate_id) as ChickenView
			if teammate != null:
				teammate.play_short_bark("OUR MOVE!", &"team")
		if _camera_controller != null and int(result.get("worker_id", -1)) >= 0:
			_camera_controller.focus_worker(int(result.get("worker_id", -1)))
		if _office_atmosphere != null:
			_office_atmosphere.pulse_strategy_reward()
	if String(result.get("playbook_kind", "")) in ["proposal", "toy", "rescue", "intervention"]:
		_character_dialogue_ui.hold_ambient(3.0)
		var reaction_worker_id := int(result.get("worker_id", _active_playbook_focused_worker_id))
		var reaction_worker := _worker_views.get(reaction_worker_id) as ChickenView
		if reaction_worker != null:
			var reaction_copy := (
				"MY IDEA!" if kind == &"proposal" else
				"BACK AT IT!" if kind == &"rescue" else
				("ON IT!" if choice_id == &"ring_bell" else "COFFEE!" if choice_id == &"coffee_run" else "CHECKING!") if kind == &"intervention" else
				"BOK!"
			)
			reaction_worker.play_short_bark(reaction_copy, &"team")
	if kind == &"hero_case":
		var hero_worker := _worker_views.get(int(result.get("worker_id", -1))) as ChickenView
		if hero_worker != null:
			hero_worker.play_short_bark("FILED!", &"team")
		if _office_atmosphere != null:
			_office_atmosphere.pulse_strategy_reward()
	if kind in [&"toy", &"episode", &"display", &"modifier", &"intervention"] and _office_atmosphere != null:
		_office_atmosphere.pulse_strategy_reward()
	if kind == &"intervention" and _management_presence != null:
		_management_presence.play_manager_intervention(choice_id)
	elif _management_presence != null:
		_management_presence.play_core_loop_sequence(kind, choice_id)
	if kind == &"challenge":
		DisplayServer.clipboard_set(String(result.get("code", "")))
	if String(result.get("playbook_kind", "")) == "reward" and _office_atmosphere != null:
		_office_atmosphere.pulse_strategy_reward()
	var receipt_label := String(result.get("label", option.get("label", "PLAY FILED"))).to_upper()
	if kind == &"preset":
		receipt_label = LoopReadability.strategy_copy(String(choice_id))
	_latest_action_outcome_receipt = {
		"visible": true,
		"title": receipt_label,
		"entries": [{
			"id": String(kind),
			"icon": String(option.get("icon", "goal")),
			"copy": receipt_label,
			"detail": outcome,
		}],
		"accessible_text": "%s. %s" % [receipt_label, outcome],
	}
	var after_playbook_snapshot := _simulation.snapshot()
	if kind == &"reward":
		for worker_value in after_playbook_snapshot.get("workers", []):
			var reward_worker := worker_value as Dictionary
			if not bool(reward_worker.get("employed", false)):
				continue
			var reward_worker_id := int(reward_worker.get("id", -1))
			if choice_id == &"mastery" and int(reward_worker.get("career_xp", 0)) <= int(_worker_record(before_playbook_snapshot, reward_worker_id).get("career_xp", 0)):
				continue
			var reward_view := _worker_views.get(reward_worker_id) as ChickenView
			if reward_view != null:
				reward_view.play_emotion(&"relief" if choice_id == &"recovery" else &"proud", "reward:%d:%d" % [int(after_playbook_snapshot.get("day", 0)), int(result.get("receipt_serial", 0))])
	if not _decision_consequence_entries(
		before_playbook_snapshot,
		after_playbook_snapshot,
	).is_empty():
		var prior_decision := _active_decision
		_active_decision = {"options": [option.duplicate(true)]}
		_spawn_decision_consequence_receipts(
			before_playbook_snapshot,
			after_playbook_snapshot,
			{"option_id": String(choice_id)},
		)
		_active_decision = prior_decision
	_active_playbook_menu_state.clear()
	if _audio_feedback != null:
		if kind == &"intervention" and _audio_feedback.has_method("play_manager_intervention"):
			_audio_feedback.call("play_manager_intervention", choice_id)
		elif kind in [&"reward", &"teamwork", &"partnership"]:
			_audio_feedback.play_commendation()
		else:
			_audio_feedback.play_decision_resolved()
	if kind == &"preset":
		_pulse_action_target(_active_playbook_button)
	if kind == &"signature":
		var signature_worker_id := int(result.get("worker_id", _active_playbook_focused_worker_id))
		var signature_view := _worker_views.get(signature_worker_id) as ChickenView
		if signature_view != null and is_instance_valid(signature_view):
			signature_view.play_signature_feedback(StringName(result.get("action_id", &"")))
		if _camera_controller != null and signature_worker_id >= 0:
			_camera_controller.focus_worker(signature_worker_id)
	if kind == &"teamwork":
		var authority_key := "playbook:%d" % int(result.get("receipt_serial", 0))
		for teammate_id in [int(result.get("worker_id", -1)), int(result.get("partner_id", -1))]:
			var teammate_view := _worker_views.get(teammate_id) as ChickenView
			if teammate_view == null or not is_instance_valid(teammate_view):
				continue
			teammate_view.play_team_lift_feedback({
				"authority_key": authority_key,
				"worker_id": teammate_id,
				"morale_delta": 6.0,
				"stress_delta": -4.0,
				"fatigue_delta": 0.0,
			})
		if _camera_controller != null and int(result.get("worker_id", -1)) >= 0:
			_camera_controller.focus_worker(int(result.get("worker_id", -1)))
	if kind == &"reward" and _office_atmosphere != null:
		_office_atmosphere.pulse_farmer_review()
	if not bool(result.get("practice", false)):
		_save_campaign_checkpoint("active_playbook_%s" % String(kind))
	var refreshed_snapshot := _simulation.snapshot()
	_refresh_gameplay_pulse(refreshed_snapshot)
	_publish_web_diagnostic_state(refreshed_snapshot)


func _on_active_playbook_popup_hide() -> void:
	if _simulation == null or _active_playbook_button == null:
		return
	call_deferred(
		"_refresh_active_playbook_menu",
		_simulation.playbook_snapshot(_active_playbook_focused_worker_id),
		_active_playbook_focused_worker_id,
	)


func _on_active_playbook_about_to_popup() -> void:
	# MenuButton computes a position below PLAN, which covers the hen this menu
	# is meant to help manage. Re-anchor its own PopupMenu after that placement.
	call_deferred("_place_active_playbook_popup")


func _place_active_playbook_popup() -> void:
	if _active_playbook_button == null:
		return
	var popup := _active_playbook_button.get_popup()
	if not popup.visible:
		return
	var show_other_actions := _show_other_playbook_actions
	_show_other_playbook_actions = false
	if not show_other_actions and _open_shift_challenge_choices():
		popup.hide()
		return
	var hud_bottom := _top_hud_panel.offset_bottom if _top_hud_panel != null else LIVE_HUD_HEIGHT
	popup.position = Vector2i(16, roundi(hud_bottom + 10.0))
	popup.set_meta("scene_safe_anchor", true)


func _open_shift_challenge_choices(requested_mode: String = "") -> bool:
	if _simulation == null or _blocking_management_surface_open():
		return false
	var playbook := _simulation.playbook_snapshot(_active_playbook_focused_worker_id)
	var mode := ""
	var choices: Array[Dictionary] = []
	for candidate_mode in ["reward", "preset"]:
		var any_available := false
		for value: Dictionary in playbook.get("options", []):
			if String(value.get("kind", "")) == candidate_mode:
				choices.append(value)
				any_available = any_available or bool(value.get("available", false))
		if any_available:
			mode = candidate_mode
			break
		choices.clear()
	if mode.is_empty():
		mode = "workshop"
	if requested_mode == "workshop":
		mode = "workshop"
	if mode == "workshop":
		choices = _simulation.career_workshop.catalog(_simulation.day, _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING and _simulation.pending_decision.is_empty())
	if _shift_challenge_ui == null:
		_shift_challenge_ui = ShiftChallengeUI.new()
		_shift_challenge_ui.name = "ShiftChallengeUI"
		_ui_root.add_child(_shift_challenge_ui)
		_shift_challenge_ui.confirmed.connect(_on_shift_challenge_confirmed)
		_shift_challenge_ui.canceled.connect(_close_shift_challenge_choices)
		_shift_challenge_ui.more_actions_requested.connect(_open_other_playbook_actions)
		_shift_challenge_ui.workshop_requested.connect(_open_career_workshop)
	var worker_name := "YOUR HEN"
	for worker in _simulation.workers:
		if worker.employed:
			worker_name = worker.display_name
			break
	if _active_playbook_focused_worker_id >= 0 and _active_playbook_focused_worker_id < _simulation.workers.size() and _simulation.workers[_active_playbook_focused_worker_id].employed:
		worker_name = _simulation.workers[_active_playbook_focused_worker_id].display_name
	_shift_challenge_ui.show_choices(mode, choices, worker_name, playbook.get("contract", {}) as Dictionary, playbook.get("workshop", {}) as Dictionary)
	_on_interaction_safety_presentation_changed()
	return true


func _close_shift_challenge_choices() -> void:
	if _shift_challenge_ui != null:
		_shift_challenge_ui.hide()
	_on_interaction_safety_presentation_changed()
	if _active_playbook_button != null and _active_playbook_button.is_visible_in_tree():
		_active_playbook_button.grab_focus()


func _on_shift_challenge_confirmed(option: Dictionary) -> void:
	_close_shift_challenge_choices()
	# Reuse the authoritative action and its normal receipt, audio, and checkpoint.
	_active_playbook_menu_map[-100] = option
	_on_active_playbook_item_pressed(-100)
	_active_playbook_menu_map.erase(-100)


func _open_other_playbook_actions() -> void:
	_close_shift_challenge_choices()
	_show_other_playbook_actions = true
	_active_playbook_button.show_popup()


func _open_flock_ties() -> void:
	if _first_hen_prelude_pending() or (_character_dialogue_ui != null and _character_dialogue_ui.is_blocking()):
		return
	if _flock_ties_ui == null:
		_flock_ties_ui = FlockTiesUI.new()
		_flock_ties_ui.name = "FlockTies"
		_ui_root.add_child(_flock_ties_ui)
		_flock_ties_ui.closed.connect(_close_flock_ties)
		_flock_ties_ui.pair_selected.connect(func(a: int, b: int) -> void: _flock_ties_ui.present(_simulation.relationship_panel_snapshot(a, b)))
		_flock_ties_ui.action_requested.connect(_on_flock_ties_action)
	var worker_id := _routing_ui.focused_worker_id() if _routing_ui != null else 0
	if worker_id < 0:
		worker_id = 0
	var partner_id := int(_simulation._worker_flock_bond_snapshot(_simulation.workers[worker_id]).get("partner_id", -1))
	if partner_id < 0:
		partner_id = 1 if worker_id == 0 else 0
	_set_flockwatch_open(false, false)
	_flock_ties_ui.present(_simulation.relationship_panel_snapshot(worker_id, partner_id))
	_on_interaction_safety_presentation_changed()


func _close_flock_ties() -> void:
	if _flock_ties_ui != null:
		_flock_ties_ui.hide()
	_on_interaction_safety_presentation_changed()


func _on_flock_ties_action(a: int, b: int, action: String) -> void:
	var result := _simulation.perform_relationship_action(a, b, action)
	if bool(result.get("accepted", false)):
		_hen_social.reflect_pair(a, b)
		for id in [a, b]:
			var view := _worker_views.get(id) as ChickenView
			if view != null:
				view.play_emotion(&"proud" if action == "friendly_contest" else &"relief", "ties:%d:%d" % [_simulation.day, int(result.get("receipt_serial", 0))])
		_save_campaign_checkpoint("flock_shared_moment")
	_flock_ties_ui.present(_simulation.relationship_panel_snapshot(a, b), String(result.get("outcome", result.get("reason", ""))))
	_publish_web_diagnostic_state(_simulation.snapshot(true))


func _on_pair_reward_earned(receipt: Dictionary) -> void:
	_hen_social.reflect_pair(int(receipt.worker_id), int(receipt.partner_id), receipt)
	for id in [int(receipt.worker_id), int(receipt.partner_id)]:
		var view := _worker_views.get(id) as ChickenView
		if view != null:
			view.play_emotion(&"proud", "pair:%d:%s" % [int(receipt.day), FlockRelationships.key(int(receipt.worker_id), int(receipt.partner_id))])


func _open_career_workshop() -> void:
	_close_shift_challenge_choices()
	_open_shift_challenge_choices("workshop")


func _management_overlay_primary_action_state() -> Dictionary:
	# Highest visual layer first. Each surface derives its contract from the real
	# enabled Button currently rendered in its fixed action rail.
	for overlay: Control in [
		_shift_challenge_ui,
		_campus_portfolio_reveal_ui,
		_commissioning_reveal_ui,
		_campus_expansion_ui,
		_campus_portfolio_ui,
		_capital_blueprint_ui,
	]:
		if overlay == null or not overlay.has_method("primary_action_state"):
			continue
		var state := overlay.call("primary_action_state") as Dictionary
		if not state.is_empty():
			return state
	return {}


func _focus_management_overlay_primary_action() -> bool:
	for overlay: Control in [
		_shift_challenge_ui,
		_campus_portfolio_reveal_ui,
		_commissioning_reveal_ui,
		_campus_expansion_ui,
		_campus_portfolio_ui,
		_capital_blueprint_ui,
	]:
		if overlay == null or not overlay.has_method("focus_primary_action"):
			continue
		if bool(overlay.call("focus_primary_action")):
			return true
	return false


# --- OfficeGuidancePresenter delegators: implementation lives in office_guidance_presenter.gd ---
func _flockwatch_context_primary_action_state() -> Dictionary:
	return _guidance_presenter._flockwatch_context_primary_action_state()


func _set_guidance(
	copy: String,
	icon_kind: StringName = &"goal",
	exact_detail: String = "",
	action_id: StringName = &"",
) -> void:
	_guidance_presenter._set_guidance(copy, icon_kind, exact_detail, action_id)


func _focus_guidance_hen() -> void:
	_guidance_presenter._focus_guidance_hen()


func _update_guidance(snapshot: Dictionary) -> void:
	_guidance_presenter._update_guidance(snapshot)


func _capture_adaptive_routing_guidance_preview() -> void:
	await _guidance_presenter._capture_adaptive_routing_guidance_preview()


func _update_lighting(snapshot: Dictionary) -> void:
	if _environment == null or _office_sun == null:
		return
	var minute := float(snapshot["minute_of_day"])
	var shift_progress := clampf(inverse_lerp(480.0, 1020.0, minute), 0.0, 1.0)
	var late_day := smoothstep(0.68, 1.0, shift_progress)
	var morning_warmth := 1.0 - smoothstep(0.0, 0.28, shift_progress)
	var overtime_active := bool(snapshot["overtime_enabled"])

	var neutral_light := Color("f4eedc")
	var morning_light := Color("ffe9d1")
	var evening_light := Color("e6a273")
	_office_sun.light_color = neutral_light.lerp(morning_light, morning_warmth).lerp(evening_light, late_day)
	_office_sun.light_energy = lerpf(0.68, 0.52, late_day)
	_environment.ambient_light_color = Color("a9c5d7").lerp(Color("8396aa"), late_day)
	_environment.ambient_light_energy = lerpf(0.36, 0.38, late_day)
	_environment.background_color = Color("172029").lerp(Color("101823"), late_day)
	_bounce_light.light_energy = lerpf(0.18, 0.16, late_day)
	for fill in _office_fill_lights:
		fill.light_energy = lerpf(0.18, 0.30, late_day)
		fill.light_color = Color("e5e4d5").lerp(Color("cddbe1"), late_day)

	if overtime_active:
		_office_sun.light_energy *= 0.72
		_environment.ambient_light_energy *= 0.82
		_environment.background_color = Color("0b111a")
		for fill in _office_fill_lights:
			fill.light_energy = 0.44
			fill.light_color = Color("bed7e0")
	_apply_office_fill_light_stage(_displayed_office_capacity)


func _on_flockwatch_pressed() -> void:
	var opening := not _flockwatch_open
	if opening and _first_hen_prelude_pending():
		return
	if opening and not _campaign_order_return_cue.is_empty():
		_activate_campaign_order_return_cue()
		return
	var spotlight_first_orders := opening and _first_clutch_orders_handoff_pending()
	_set_flockwatch_open(opening, not opening)
	if opening:
		_acknowledge_first_clutch_orders_handoff()
		if spotlight_first_orders:
			call_deferred("_focus_first_actionable_campaign_order")


func _focus_first_actionable_campaign_order() -> void:
	# Flockwatch's page navigator settles its tab focus after the drawer opens.
	# Defer the settled lookup instead of retaining a coroutine on Office; a scene
	# teardown between these frames then cancels cleanly with the node.
	call_deferred("_focus_first_actionable_campaign_order_settled")


func _focus_first_actionable_campaign_order_settled() -> void:
	if not _flockwatch_open:
		return
	var target_index := -1
	for index in range(_campaign_order_glances.size()):
		var glance := _campaign_order_glances[index]
		if glance == null or not glance.is_visible_in_tree():
			continue
		if target_index < 0:
			target_index = index
		if not bool(glance.get_meta("on_track", false)):
			target_index = index
			break
	if target_index < 0:
		return
	var target := _campaign_order_glances[target_index]
	_focus_campaign_order_glance(
		StringName(target.get_meta("objective_id", &"")),
		target_index,
		&"orders_handoff",
	)


func _on_campaign_live_order_mark_requested(
	objective_id: StringName,
	order_index: int,
) -> void:
	if objective_id == &"" or order_index < 0:
		return
	_open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	_acknowledge_first_clutch_orders_handoff()
	call_deferred("_focus_campaign_order_glance", objective_id, order_index)


func _focus_campaign_order_glance(
	objective_id: StringName,
	order_index: int,
	entry_source: StringName = &"live_mark",
) -> void:
	if not _flockwatch_open or _flockwatch_navigation == null:
		return
	var target: Label
	for glance in _campaign_order_glances:
		if StringName(glance.get_meta("objective_id", &"")) == objective_id:
			target = glance
			break
	if target == null and order_index >= 0 and order_index < _campaign_order_glances.size():
		target = _campaign_order_glances[order_index]
	if target == null or not target.is_visible_in_tree():
		return
	# Revealing the driver changes the Today stack's height. Stabilize that layout
	# before focus lands so ScrollContainer reflow cannot discard keyboard focus.
	_configure_campaign_order_driver_action(target)
	target.set_meta("opened_from_live_mark", entry_source == &"live_mark")
	target.set_meta("opened_from_orders_handoff", entry_source == &"orders_handoff")
	var tile := _flockwatch_glance_tile(target)
	var scroll := _flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_TODAY)
	if scroll != null and tile != null:
		scroll.ensure_control_visible(tile)
	if entry_source != &"orders_handoff":
		target.grab_focus()
	_focused_campaign_order_id = StringName(target.get_meta("objective_id", objective_id))
	_refresh_campaign_order_glance_focus_style(target)
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	if _simulation != null:
		var snapshot := _simulation.snapshot()
		_update_guidance(snapshot)
		_publish_web_diagnostic_state(snapshot)


func _refresh_flockwatch_camera_insets(is_open: bool) -> void:
	if _camera_controller != null:
		# Keep the inspected hen and zoom authoritative while reserving screen room
		# for the ledger. The controller shifts the unchanged subject into the safe
		# left-hand region and eases it back when the drawer closes.
		_camera_controller.set_safe_viewport_insets(
			0.0,
			FLOCKWATCH_DRAWER_SAFE_RIGHT if is_open else 0.0,
			maxf(104.0, _live_hud_routing_top() + 8.0) if _intent_focus_worker_id >= 0 else 0.0,
			(300.0 if _compact_physical_hud else 250.0) if _intent_focus_worker_id >= 0 else 0.0,
		)

func _set_flockwatch_open(is_open: bool, restore_focus: bool = false) -> void:
	if is_open:
		_build_staffing_surface()
	var changed := _flockwatch_open != is_open
	if changed and is_open:
		_first_session_funnel.observe_signal(&"ledger_opened")
	var restore_farmer_review := (
		changed
		and not is_open
		and _flockwatch_restore_farmer_review
		and not _last_workday_report.is_empty()
	)
	var restore_campaign_report := (
		changed
		and not is_open
		and _flockwatch_restore_campaign_report
		and _campaign_ui != null
	)
	if changed and is_open:
		# Flockwatch is a player-authored reading surface. Archive the semantic
		# receipt but remove its global transient cards before they can overlap the
		# ledger; the filing itself remains available through its durable systems.
		_retire_action_outcome_receipts(&"flockwatch", false)
		var focus_owner := get_viewport().gui_get_focus_owner()
		if (
			focus_owner != null
			and (_flockwatch_panel == null or not _flockwatch_panel.is_ancestor_of(focus_owner))
		):
			_flockwatch_prior_focus_owner = focus_owner
		elif _flockwatch_toggle != null:
			_flockwatch_prior_focus_owner = _flockwatch_toggle
	_refresh_flockwatch_camera_insets(is_open)
	_flockwatch_open = is_open
	_refresh_flockwatch_toggle_layout()
	if not is_open:
		_focused_campaign_order_id = &""
		_campaign_order_pointer_armed_id = &""
		_clear_campaign_order_driver_action()
	var marker_context_page := (
		_flockwatch_navigation.current_page_id()
		if _flockwatch_navigation != null else
		FlockwatchNavigation.PAGE_TODAY
	)
	_set_capacity_marker_context_revealed(
		is_open
		and marker_context_page in [
			FlockwatchNavigation.PAGE_FLOCK,
			FlockwatchNavigation.PAGE_CAPITAL,
		]
	)
	if _flockwatch_panel != null:
		_flockwatch_panel.visible = is_open
		_flockwatch_panel.mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE
	var another_surface_open := _blocking_management_surface_open()
	_refresh_floor_input_context()
	var settled_snapshot: Dictionary = (
		_simulation.snapshot()
		if _simulation != null else
		{}
	)
	if _flockwatch_toggle != null:
		_flockwatch_toggle.tooltip_text = ("Close the ledger and restore the full coop view." if is_open else "Open the rooster's performance ledger.")
	_update_flockwatch_toggle(settled_snapshot)
	if _simulation != null:
		var snapshot := settled_snapshot
		if is_open:
			_refresh_flockwatch_navigation(snapshot)
		_refresh_visible_management_surfaces(snapshot)
		if _routing_ui != null and not is_open:
			# Closing the ledger must restore the same routing projection used by
			# live ticks. Applying the broad simulation snapshot here silently
			# discarded presentation-only receipts such as LAST EGG.
			_routing_ui.apply_snapshot(
				_routing_visual_snapshot(_snapshot_with_active_workers(snapshot))
			)
		_refresh_first_clutch_ui(snapshot)
		_update_guidance(snapshot)
		_publish_web_diagnostic_state(snapshot)
	if changed and is_open and _flockwatch_navigation != null:
		_flockwatch_navigation.focus_current_tab()
	elif changed and not is_open:
		var focus_target := _flockwatch_prior_focus_owner
		_flockwatch_prior_focus_owner = null
		if (
			restore_focus
			and not another_surface_open
			and focus_target != null
			and is_instance_valid(focus_target)
			and focus_target.is_visible_in_tree()
		):
			focus_target.call_deferred("grab_focus")
		elif (
			restore_focus
			and not another_surface_open
			and _flockwatch_toggle != null
			and _flockwatch_toggle.is_visible_in_tree()
		):
			_flockwatch_toggle.call_deferred("grab_focus")
	if restore_farmer_review:
		_flockwatch_restore_farmer_review = false
		_show_farmer_review(_last_workday_report, false)
	elif restore_campaign_report:
		_flockwatch_restore_campaign_report = false
		_campaign_ui.show_between_shift_report(
			_campaign_presentation_snapshot(&"between_shift")
		)
		_set_campaign_modal_open(true)


func _on_flockwatch_page_changed(page_id: StringName) -> void:
	_set_capacity_marker_context_revealed(
		_flockwatch_open
		and page_id in [FlockwatchNavigation.PAGE_FLOCK, FlockwatchNavigation.PAGE_CAPITAL]
	)
	_on_campaign_interface_context_changed()
	if _flockwatch_open and _simulation != null:
		var snapshot := _simulation.snapshot()
		_refresh_visible_management_surfaces(snapshot)
		_publish_web_diagnostic_state(snapshot)


func _on_flockwatch_show_all_filings_changed(_enabled: bool) -> void:
	# The navigator has already settled page availability before this signal is
	# emitted. Publish that presentation-only change immediately so browser
	# diagnostics and assistive tooling never lag behind the visible tab strip.
	_on_campaign_interface_context_changed()
	if _flockwatch_open and _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campaign_interface_context_changed() -> void:
	if _applying_campaign_interface_context or not _campaign_session_checkpoint_enabled:
		return
	_queue_campaign_checkpoint("interface_context_changed")


func _open_flockwatch_page(page_id: StringName) -> void:
	if _flockwatch_navigation != null:
		_refresh_flockwatch_navigation(_simulation.snapshot())
		if not _flockwatch_navigation.is_page_available(page_id):
			# Deep links from authored review flows make their own filing relevant;
			# this discovers one page without exposing every future filing.
			var presentation := _simulation.snapshot().duplicate(true)
			presentation["first_clutch_active"] = false
			presentation["relevant_flockwatch_pages"] = [page_id]
			_flockwatch_navigation.apply_snapshot(presentation)
	_set_flockwatch_open(true)
	if _flockwatch_navigation != null:
		_flockwatch_navigation.open_page(page_id, true)


func _update_flockwatch_toggle(snapshot: Dictionary = {}) -> void:
	if _flockwatch_toggle == null:
		return
	var active_snapshot := (
		snapshot
		if not snapshot.is_empty() else
		_simulation.snapshot()
	)
	var headcount := int(active_snapshot.get("active_staff_count", _worker_views.size()))
	var capacity := _office_capacity_from_snapshot(active_snapshot)
	if _flockwatch_open:
		# Once open, the stable launcher becomes a compact action inside the
		# ledger header instead of repeating the drawer name above the panel.
		_flockwatch_toggle.text = "CLOSE  [V]"
		_flockwatch_toggle.tooltip_text = (
			"Close Flockwatch and restore the full coop view.\n"
			+ "Active flock: %d of %d authorized desks." % [headcount, capacity]
		)
		_apply_flockwatch_binding_hint("CLOSE")
		return
	if _first_clutch_orders_handoff_pending():
		if bool(_first_clutch.get("route_first_lesson", false)):
			_flockwatch_toggle.text = "GOAL DETAILS  [V]"
			_flockwatch_toggle.tooltip_text = "Optional: review today's quota, quality and flock goals. Continue Shift resumes work directly from the goal summary."
			_apply_flockwatch_binding_hint("GOAL DETAILS")
			return
		_flockwatch_toggle.text = "TODAY'S 3 ORDERS  [V]"
		_flockwatch_toggle.tooltip_text = (
			"First Clutch complete: open the Flockwatch Today page to review three live probation orders."
		)
		_apply_flockwatch_binding_hint("3 ORDERS")
		return
	if not _campaign_order_return_cue.is_empty():
		_flockwatch_toggle.text = "RETURN TO GOAL  [V]"
		_flockwatch_toggle.tooltip_text = String(_campaign_order_return_cue.get(
			"accessible_text",
			"Return to the exact Today goal that opened this gameplay driver.",
		))
		_apply_flockwatch_binding_hint("RETURN")
		return
	# Capital facilities used to become actionable silently because this compact
	# badge counted only the three desk-upgrade buttons. Give real rooms priority
	# over the historical output summary while a review-time requisition is ready.
	var ready_facilities := 0
	var ready_facility_names: Array[String] = []
	for facility_value in active_snapshot.get("facility_catalog", []):
		if facility_value is not Dictionary:
			continue
		var facility := facility_value as Dictionary
		if bool(facility.get("maxed", false)) or not bool(facility.get("can_purchase", false)):
			continue
		ready_facilities += 1
		ready_facility_names.append(String(facility.get(
			"short_name", facility.get("display_name", facility.get("name", "CAPITAL PROJECT"))
		)))
	if ready_facilities > 0:
		_flockwatch_toggle.text = "FLOCKWATCH  ·  %d ACTION%s  [V]" % [
			ready_facilities,
			"" if ready_facilities == 1 else "S",
		]
		_flockwatch_toggle.tooltip_text = "%s\nOpen the capital file to compare exact benefits, liabilities, and reserve effects." % (
			", ".join(ready_facility_names)
		)
		_apply_flockwatch_binding_hint("FLOCKWATCH  %d" % ready_facilities)
		return
	if _pecking_order_ui != null:
		var leader_summary: String = String(_pecking_order_ui.call("leader_summary"))
		var has_ranked_output := int(active_snapshot.get("eggs_today", 0)) > 0
		if not has_ranked_output:
			for row_value in active_snapshot.get("last_pecking_order", []):
				if int((row_value as Dictionary).get("eggs", 0)) > 0:
					has_ranked_output = true
					break
		if has_ranked_output and not leader_summary.contains("NO ACTIVE RANKING"):
			_flockwatch_toggle.text = "FLOCKWATCH  [V]"
			_flockwatch_toggle.tooltip_text = "%s\nOpen the full credited-output ledger." % leader_summary
			_apply_flockwatch_binding_hint()
			return
	var affordable := 0
	var spendable := int(active_snapshot.get(
		"spendable_fund_cents",
		_simulation.revenue_cents,
	))
	for upgrade in _simulation.upgrade_catalog():
		if not bool(upgrade.get("maxed", false)) and spendable >= int(upgrade.get("cost_cents", 0)):
			affordable += 1
	_flockwatch_toggle.text = (
		"FLOCKWATCH  ·  %d ACTION%s  [V]" % [
			affordable,
			"" if affordable == 1 else "S",
		]
		if affordable > 0 else
		"FLOCKWATCH  [V]"
	)
	_flockwatch_toggle.tooltip_text = (
		"Open the rooster's performance ledger.\n"
		+ "Active flock: %d of %d authorized desks." % [headcount, capacity]
	)
	_apply_flockwatch_binding_hint(
		"FLOCKWATCH  %d" % affordable
		if affordable > 0 else
		"FLOCKWATCH"
	)


func _refresh_flockwatch_toggle_layout() -> void:
	if _flockwatch_toggle == null:
		return
	var routing_top := _live_hud_routing_top()
	if _flockwatch_open and _flockwatch_navigation != null:
		_flockwatch_navigation.adopt_header_action(_flockwatch_toggle)
		# The visible mark is intentionally terse inside the ledger header. The
		# complete action name and alternate bindings remain in accessibility_name
		# and the tooltip, so the header does not surrender a tab-width to "Close".
		_flockwatch_toggle.custom_minimum_size = Vector2(132.0, 34.0)
		_flockwatch_toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
		_flockwatch_toggle.z_index = 0
		return
	if _ui_root != null and _flockwatch_toggle.get_parent() != _ui_root:
		_flockwatch_toggle.reparent(_ui_root, false)
	_flockwatch_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_flockwatch_toggle.custom_minimum_size = Vector2.ZERO
	_flockwatch_toggle.size_flags_horizontal = Control.SIZE_FILL
	_flockwatch_toggle.z_index = 5
	_flockwatch_toggle.offset_left = (
		-238.0
		if float(_flockwatch_toggle.get_meta("interface_scale", 1.0)) >= 1.25 else
		-218.0
	)
	_flockwatch_toggle.offset_top = routing_top
	_flockwatch_toggle.offset_right = -18.0
	_flockwatch_toggle.offset_bottom = routing_top + 44.0


func _apply_flockwatch_binding_hint(compact_label: String = "FLOCKWATCH") -> void:
	if _flockwatch_toggle == null:
		return
	var binding_hint := _action_hint(&"toggle_flockwatch")
	var full_text := _flockwatch_toggle.text.replace(
		"[V]",
		"[%s]" % binding_hint,
	)
	var primary_hint := binding_hint.split(" / ", false)[0]
	var compact_text := "%s  [%s]" % [compact_label, primary_hint]
	_flockwatch_toggle.set_meta("full_text", full_text)
	_flockwatch_toggle.set_meta("compact_text", compact_text)
	if not _flockwatch_toggle.tooltip_text.contains("Binding:"):
		_flockwatch_toggle.tooltip_text += "\nBinding: %s." % binding_hint
	_flockwatch_toggle.accessibility_name = "%s. %s" % [
		full_text,
		_flockwatch_toggle.tooltip_text,
	]
	_flockwatch_toggle.set_meta("accessible_text", _flockwatch_toggle.accessibility_name)
	_apply_flockwatch_toggle_scale(float(_player_preferences.get("ui_scale", 1.0)))


## The bound-ledger mark keeps Flockwatch recognizable at every scale. Preserve
## only the primary binding on the permanent action; the full secondary route
## remains in tooltip and assistive copy.
func _apply_flockwatch_toggle_scale(scale: float) -> void:
	if _flockwatch_toggle == null:
		return
	var sanitized_scale := clampf(scale, 1.0, 1.5)
	_flockwatch_toggle.set_meta("interface_scale", sanitized_scale)
	_flockwatch_toggle.set_meta("compact_action_mark", true)
	_flockwatch_toggle.set_meta("icon_led_action_mark", true)
	_flockwatch_toggle.text = String(_flockwatch_toggle.get_meta(
		"compact_text",
		_flockwatch_toggle.text,
	))


func _on_pecking_order_worker_selected(worker_id: int) -> void:
	_set_flockwatch_open(false)
	if _camera_controller != null:
		_camera_controller.focus_worker(worker_id)


func _on_world_worker_selected(worker_id: int) -> void:
	# The camera-focus handler is already the single route commit edge. Reusing
	# it means tray -> physical hen produces the same folder travel, undo receipt,
	# and authoritative simulation command as selecting the dossier entry.
	_on_pecking_order_worker_selected(worker_id)


func _on_guidance_preview_entered() -> void:
	if _guidance_action_button == null or _guidance_action_button.disabled:
		return
	var target := _guidance_action_button.get_meta("world_target", {}) as Dictionary
	var target_worker_id := int(target.get("worker_id", -1))
	if target_worker_id < 0:
		return
	var view := _worker_views.get(target_worker_id) as ChickenView
	if view != null and is_instance_valid(view):
		view.set_consequence_preview(true, _guidance_action_id)


func _on_guidance_preview_exited() -> void:
	if (
		_guidance_action_button != null
		and (_guidance_action_button.is_hovered() or _guidance_action_button.has_focus())
	):
		return
	for view_value: Variant in _worker_views.values():
		var view := view_value as ChickenView
		if view != null and is_instance_valid(view):
			view.set_consequence_preview(false)


func _on_guidance_action_pressed() -> void:
	_first_session_funnel.observe_signal(&"guidance_used")
	# Covered HUD guidance can receive a browser or test activation even while a
	# higher modal owns the canvas. Always route that request to the visible safe
	# action before consulting the underlying floor action id.
	if _focus_active_held_confirmation_safe_return():
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	if _settings_ui != null and _settings_ui.focus_primary_action():
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	if _focus_management_overlay_primary_action():
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	if _guidance_action_id == &"":
		return
	match _guidance_action_id:
		&"playbook":
			if _active_playbook_button != null:
				_active_playbook_button.visible = true
				_active_playbook_button.disabled = false
				_active_playbook_button.grab_focus()
				_active_playbook_button.show_popup()
		&"decision":
			_focus_decision_primary_action()
		&"review":
			var review_target: Control = (
				_review_details_toggle
				if _review_details_toggle != null and _review_details_toggle.is_visible_in_tree() else
				_begin_next_shift_button
			)
			if review_target != null:
				review_target.grab_focus()
			_pulse_action_target(_day_review_panel)
		&"today":
			_open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
			_acknowledge_first_clutch_orders_handoff()
		&"campaign_order_return":
			_activate_campaign_order_return_cue()
		&"campaign_order_driver":
			_on_campaign_order_driver_pressed()
		&"resume_shift":
			_on_speed_button_pressed(1)
		&"adaptive_route_recovery":
			_focus_adaptive_route_recovery()
		&"records":
			_open_flockwatch_page(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
		&"routing_chase":
			if _flockwatch_open:
				_set_flockwatch_open(false)
			if _routing_ui != null and _routing_ui.has_method("focus_priority_dispatch_tray"):
				_routing_ui.visible = not _blocking_management_surface_open()
				_routing_ui.focus_priority_dispatch_tray()
		&"capital":
			_open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
		&"first_hen":
			_open_first_hen_file(int(_first_clutch.get("target_worker_id", -1)))
		&"first_clutch":
			if not _handle_first_clutch_primary_action():
				_focus_guidance_hen()
		&"campaign_milestone", &"campaign_report_continue":
			if _campaign_ui != null:
				_campaign_ui.focus_report_primary_action()
		&"campaign_contract_offer", &"campaign_contract_sign", &"campaign_contract_decline", &"campaign_contract_continue":
			if _campaign_ui != null:
				_campaign_ui.focus_contract_board_primary_action()
		&"campaign_final_continue", &"campaign_final_retry":
			if _campaign_ui != null:
				_campaign_ui.focus_final_primary_action()
		&"flockwatch_context_action":
			if _flockwatch_navigation != null:
				_flockwatch_navigation.focus_context_primary_action()
		&"select_hen":
			_focus_guidance_hen()
		&"peck":
			_request_peck_assist_from_input()
		&"feed":
			if _feed_button != null:
				_feed_button.grab_focus()
				_pulse_action_target(_feed_button)
	_publish_web_diagnostic_state(_simulation.snapshot())


func _office_clock_label(minute_of_day: int) -> String:
	var normalized := posmod(minute_of_day, 24 * 60)
	var hour_24 := normalized / 60
	var minute := normalized % 60
	var suffix := "AM" if hour_24 < 12 else "PM"
	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	return "%d:%02d %s" % [hour_12, minute, suffix]


func _clock_stamp_for_snapshot(snapshot: Dictionary) -> Dictionary:
	var presented_day := int(snapshot.get("day", 1))
	var presented_time := String(snapshot.get("time_label", "8:00 AM"))
	var completed_day := int(_last_workday_report.get("day", 0))
	if (
		int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
		== DepartmentSimulation.ShiftPhase.REVIEW
		and completed_day > 0
		and completed_day == presented_day - 1
	):
		# Authority prepares tomorrow's 8:00 AM state before the closing review.
		# Keep the visible clock on the day the player is actually reviewing.
		presented_day = completed_day
		presented_time = _office_clock_label(DepartmentSimulation.SHIFT_END_MINUTE)
	return {"day": presented_day, "time_label": presented_time}


func _update_campus_world_bounds(snapshot: Dictionary) -> void:
	var campus := snapshot.get("campus_expansion", {}) as Dictionary
	var parcel := campus.get("parcel", {}) as Dictionary
	var parcel_owned := bool(parcel.get("owned", campus.get("parcel_owned", false)))
	var portfolio := snapshot.get("campus_portfolio", {}) as Dictionary
	var office_capacity := _office_capacity_from_snapshot(snapshot)
	var bounds_fingerprint_parts: Array = [
		office_capacity,
		parcel_owned,
		portfolio.get("parcels", []),
		_campus_worker_assignments,
		_campus_worker_pads,
	]
	if _office_storytelling != null:
		bounds_fingerprint_parts.append(_office_storytelling.visible_campus_footprints())
		bounds_fingerprint_parts.append(_office_storytelling.visible_campus_camera_aabb())
	var next_bounds_fingerprint := hash(bounds_fingerprint_parts)
	if next_bounds_fingerprint == _campus_bounds_fingerprint:
		return
	_campus_bounds_fingerprint = next_bounds_fingerprint
	var commissioned_bounds := BASE_CAMPUS_BOUNDS
	var camera_bounds := office_camera_bounds(office_capacity)
	var navigation_footprint := Rect2()
	var navigation_footprints: Array[Rect2] = []
	var maximum_height := 4.0
	if _office_storytelling != null:
		for footprint: Rect2 in _office_storytelling.visible_campus_footprints():
			if footprint.size.x > 0.0 and footprint.size.y > 0.0:
				commissioned_bounds = commissioned_bounds.merge(footprint)
				camera_bounds = camera_bounds.merge(footprint)
		var presentation_aabb := _office_storytelling.visible_campus_camera_aabb()
		if presentation_aabb.size.y > 0.0:
			maximum_height = maxf(maximum_height, presentation_aabb.end.y)
	if parcel_owned:
		commissioned_bounds = commissioned_bounds.merge(
			CampusExpansionVisualScript.declared_footprint()
		)
		camera_bounds = camera_bounds.merge(CampusExpansionVisualScript.declared_footprint())
		navigation_footprint = CampusExpansionVisualScript.navigation_footprint(snapshot)
		navigation_footprints.append(navigation_footprint)
		var visual_bounds := CampusExpansionVisualScript.camera_bounds(snapshot)
		maximum_height = maxf(maximum_height, visual_bounds.end.y)
	var portfolio_parcels: Dictionary = {}
	var portfolio_parcel_value: Variant = portfolio.get("parcels", [])
	if portfolio_parcel_value is Dictionary:
		for raw_id: Variant in (portfolio_parcel_value as Dictionary):
			var record_value: Variant = (portfolio_parcel_value as Dictionary)[raw_id]
			if record_value is Dictionary:
				portfolio_parcels[StringName(String(raw_id))] = record_value
	elif portfolio_parcel_value is Array:
		for record_value: Variant in portfolio_parcel_value as Array:
			if record_value is Dictionary:
				var record := record_value as Dictionary
				portfolio_parcels[StringName(String(record.get("id", "")))] = record
	var has_owned_portfolio_parcel := false
	for portfolio_parcel in CampusPortfolioVisualScript.parcel_catalog():
		var parcel_id := StringName(String((portfolio_parcel as Dictionary).get("id", "")))
		var record := portfolio_parcels.get(parcel_id, {}) as Dictionary
		if not bool(record.get("owned", record.get("purchased", false))):
			continue
		has_owned_portfolio_parcel = true
		commissioned_bounds = commissioned_bounds.merge(
			CampusPortfolioVisualScript.declared_footprint(parcel_id)
		)
		camera_bounds = camera_bounds.merge(
			CampusPortfolioVisualScript.declared_footprint(parcel_id)
		)
	if has_owned_portfolio_parcel:
		for route: Rect2 in CampusPortfolioVisualScript.navigation_footprints(snapshot):
			navigation_footprints.append(route)
		var portfolio_bounds := CampusPortfolioVisualScript.camera_bounds(snapshot)
		maximum_height = maxf(maximum_height, portfolio_bounds.end.y)
	if not _campus_worker_assignments.is_empty():
		commissioned_bounds = commissioned_bounds.merge(campus_duty_commute_bounds())
		camera_bounds = camera_bounds.merge(campus_duty_commute_bounds())
	set_meta(&"commissioned_campus_bounds", commissioned_bounds)
	set_meta(&"active_office_camera_bounds", camera_bounds)
	set_meta(&"campus_navigation_footprint", navigation_footprint)
	set_meta(&"campus_navigation_footprints", navigation_footprints)
	if _office_storytelling != null:
		set_meta(
			&"campus_presentation",
			_office_storytelling.campus_presentation_snapshot(),
		)
	if _camera_controller != null:
		_camera_controller.set_overview_bounds(
			camera_bounds,
			maximum_height,
			CAMPUS_PRESENTATION_MARGIN_RATIO,
			office_overview_minimum_size(office_capacity),
		)


func _campus_presentation_state_fingerprint(snapshot: Dictionary) -> int:
	var facility_states: Array = []
	for facility_value in snapshot.get("facility_catalog", []):
		if facility_value is not Dictionary:
			continue
		var facility := facility_value as Dictionary
		facility_states.append([
			String(facility.get("id", "")),
			int(facility.get("current_level", facility.get("level", 0))),
			bool(facility.get("unlocked", facility.get("available", false))),
			bool(facility.get("can_purchase", false)),
			bool(facility.get("maxed", false)),
		])
	var expansion := snapshot.get("campus_expansion", {}) as Dictionary
	var portfolio := snapshot.get("campus_portfolio", {}) as Dictionary
	return hash([
		int(snapshot.get("day", 0)),
		int(snapshot.get("shift_phase", 0)),
		snapshot.get("owned_facilities", {}),
		snapshot.get("pinned_capital_plan_id", ""),
		facility_states,
		bool(expansion.get("parcel_owned", false)),
		bool(expansion.get("pod_owned", false)),
		bool(expansion.get("pod_operational", false)),
		int(portfolio.get("capital_spend_total_cents", 0)),
		portfolio.get("parcels", []),
		portfolio.get("projects", []),
	])


func _queue_character_dialogue(entry: Dictionary) -> bool:
	if _character_dialogue_ui == null or entry.is_empty():
		return false
	# Keep the introductory route -> egg -> reward loop in the player's hands.
	# Reactions still appear, but only actual management choices take over input.
	if (
		bool(_first_clutch.get("route_first_lesson", false))
		and not bool(_first_clutch.get("dismissed", false))
		and not bool(_first_clutch.get("orders_handoff_acknowledged", false))
	):
		entry = entry.duplicate(true)
		entry["presentation_mode"] = "ambient"
	var accepted: bool = _character_dialogue_ui.enqueue_dialogue(entry)
	if accepted and _ticker_panel != null:
		_ticker_panel.visible = false
		_ticker_visible_copy = ""
	return accepted


func _on_character_dialogue_presented(entry: Dictionary) -> void:
	if _audio_feedback != null:
		_audio_feedback.play_dialogue_cutout(StringName(String(
			entry.get("speaker_id", "")
		)))
	if StringName(String(entry.get("presentation_mode", &"visual_novel"))) != &"ambient":
		_hold_clock_for_character_dialogue()
	_refresh_character_dialogue_input_context()


func _on_character_dialogue_dismissed(_entry_id: StringName) -> void:
	_try_restore_character_dialogue_clock()
	_refresh_character_dialogue_input_context()


func _refresh_character_dialogue_input_context() -> void:
	# Ambient dialogue may dismiss and present in the same frame. Its input
	# ownership changes, not the economy: share one current read for both the
	# Next Moment hint and Priority Peck focus instead of rebuilding catalogs.
	var snapshot := _simulation.snapshot(true, true) if _simulation != null else {}
	_refresh_floor_input_context(snapshot)
	if _simulation != null:
		_refresh_priority_peck_precision_focus(snapshot)


func _hold_clock_for_character_dialogue() -> void:
	if _character_dialogue_previous_speed >= 0:
		if _clock != null and _clock.speed_index > 0:
			_clock.set_speed(0)
		return
	if (
		_clock == null
		or _clock.speed_index <= 0
		or _simulation == null
		or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
	):
		return
	_character_dialogue_previous_speed = _clock.speed_index
	_clock.set_speed(0)


func _try_restore_character_dialogue_clock() -> void:
	if _character_dialogue_previous_speed < 0:
		return
	if (
		_character_dialogue_ui != null
		and _character_dialogue_ui.has_blocking_dialogue()
	):
		return
	if (
		_clock == null
		or _simulation == null
		or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
	):
		_character_dialogue_previous_speed = -1
		return
	if (
		_focus_pause_active
		or _feed_party_active
		or _flockwatch_open
		or _blocking_management_surface_open()
	):
		return
	var restore_speed := _character_dialogue_previous_speed
	_character_dialogue_previous_speed = -1
	_clock.set_speed(restore_speed)


func _queue_character_dialogues(entries: Array[Dictionary]) -> int:
	var accepted := 0
	for entry in entries:
		if _queue_character_dialogue(entry):
			accepted += 1
	return accepted


func _character_dialogue_projection(snapshot: Dictionary) -> Dictionary:
	# Keep the event comparison tiny. The simulation can publish many snapshots
	# at accelerated speed; dialogue only needs threshold crossings, not a deep
	# copy of the full economy and campus filings.
	var workers: Array[Dictionary] = []
	for worker_value in snapshot.get("workers", []):
		if not worker_value is Dictionary:
			continue
		var worker := worker_value as Dictionary
		workers.append({
			"id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "")),
			"employed": bool(worker.get("employed", true)),
			"stress": float(worker.get("stress", 0.0)),
			"morale": float(worker.get("morale", 0.0)),
			"career_level": int(worker.get("career_level", 0)),
			"career_title": String(worker.get("career_title", "")),
		})
	var operations := snapshot.get("operations", {}) as Dictionary
	return {
		"day": int(snapshot.get("day", 1)),
		"eggs_today": int(snapshot.get("eggs_today", 0)),
		"first_clutch_tracking": _first_clutch_tracking_active(),
		"cracked_today": int(snapshot.get("cracked_today", 0)),
		"wage_arrears_cents": int(snapshot.get("wage_arrears_cents", 0)),
		"overtime_enabled": bool(snapshot.get("overtime_enabled", false)),
		"feed_party_used_today": bool(snapshot.get("feed_party_used_today", false)),
		"workers": workers,
		"operations": {
			"manager_roster": (
				operations.get("manager_roster", []) as Array
			).duplicate(true),
		},
	}


func _on_snapshot_changed(snapshot: Dictionary) -> void:
	_hen_social.observe(snapshot)
	_hen_social_workers = snapshot.get("workers", [])
	if _clock != null and _clock.is_advancing_tick_batch():
		_pending_simulation_presentation_snapshot = snapshot
		return
	_apply_snapshot_presentation(snapshot)


func _on_clock_tick_batch_completed(_tick_count: int) -> void:
	if not _pending_simulation_presentation_snapshot.is_empty():
		var latest := _pending_simulation_presentation_snapshot
		_pending_simulation_presentation_snapshot = {}
		_apply_snapshot_presentation(latest)
	# The heavy presentation read model may be throttled or delayed on Web, but
	# the visible clock must always describe the authoritative ticks just filed.
	_sync_authoritative_clock_display()
	_sync_authoritative_shift_objective_display()


func _apply_snapshot_presentation(snapshot: Dictionary) -> void:
	var presentation_started := Time.get_ticks_usec()
	_presentation_update_count += 1
	_last_presented_tick_revision = int(snapshot.get("authoritative_tick_revision", 0))
	if (
		_tactical_route_planner != null
		and int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
		!= DepartmentSimulation.ShiftPhase.RUNNING
		and not _tactical_route_planner.is_empty()
	):
		_tactical_route_planner.clear()
		_apply_tactical_route_plan_preview()
	var presented_day := int(snapshot.get("day", 1))
	if _dispatch_last_day < 0:
		_dispatch_last_day = presented_day
	elif presented_day != _dispatch_last_day:
		_dispatch_last_day = presented_day
		_clear_dispatch_mode(true)
	var routing_momentum := snapshot.get("routing_momentum", {}) as Dictionary
	_dispatch_momentum_chain = int(routing_momentum.get("chain", 0))
	if int(routing_momentum.get("golden_charges", 0)) > 0:
		_dispatch_reward_label = (
			"* GOLD #%04d" % int(routing_momentum.get("golden_target_claim_id", 0))
			if bool(routing_momentum.get("golden_target_bound", false)) else
			"* GOLD READY"
		)
	elif int(routing_momentum.get("peck_recharge_bank", 0)) > 0:
		_dispatch_reward_label = "PECK +1"
	elif bool(routing_momentum.get("pace_active", false)):
		_dispatch_reward_label = "PACE +15%"
	else:
		_dispatch_reward_label = ""
	if _routing_ui != null:
		var recommended_name := ""
		if not _dispatch_candidates.is_empty():
			recommended_name = String(_dispatch_candidates[0].get("worker_name", ""))
		_routing_ui.set_dispatch_state(
			_dispatch_lane,
			_dispatch_momentum_chain,
			recommended_name,
			_dispatch_reward_label,
			_dispatch_file_preview,
		)
	var dialogue_projection := _character_dialogue_projection(snapshot)
	if not _character_dialogue_previous_snapshot.is_empty():
		_queue_character_dialogues(
			CharacterDialogueCatalogScript.beats_for_snapshot(
				_character_dialogue_previous_snapshot,
				dialogue_projection,
			)
		)
	_character_dialogue_previous_snapshot = dialogue_projection
	var active_snapshot := _snapshot_with_active_workers(snapshot)
	_first_session_funnel.observe(
		active_snapshot,
		_first_clutch,
		_campaign_review_stage,
	)
	var scene_started := Time.get_ticks_usec()
	_apply_office_capacity_visibility(_office_capacity_from_snapshot(snapshot))
	_reconcile_worker_views(snapshot)
	if _management_presence != null:
		var operations := snapshot.get("operations", {}) as Dictionary
		_management_presence.apply_manager_roster(operations.get("manager_roster", []) as Array)
	var duties_started := Time.get_ticks_usec()
	_sync_campus_worker_duties(snapshot)
	_refresh_workstation_nameplates(snapshot)
	var atmosphere_started := Time.get_ticks_usec()
	_update_lighting(snapshot)
	if _office_atmosphere != null:
		_office_atmosphere.update_from_snapshot(active_snapshot)
	if _audio_director != null:
		_audio_director.call("update_from_snapshot", active_snapshot)
	var story_started := Time.get_ticks_usec()
	var campus_started := story_started
	if _office_storytelling != null:
		# Campus presentation is applied immediately below with its authored teaser
		# options; skip the default rebuild here. The campus filing changes on
		# purchases and planning beats, not every worker-progress tick, so coalesce
		# unchanged presentation work while keeping live clutch signage immediate.
		_office_storytelling.apply_snapshot(active_snapshot, false, _simulation.cost_probe)
		campus_started = Time.get_ticks_usec()
		var campus_fingerprint := _campus_presentation_state_fingerprint(snapshot)
		var campus_now_msec := Time.get_ticks_msec()
		if (
			campus_fingerprint != _campus_presentation_fingerprint
			or campus_now_msec >= _next_campus_presentation_refresh_msec
		):
			_campus_presentation_fingerprint = campus_fingerprint
			_next_campus_presentation_refresh_msec = (
				campus_now_msec + CAMPUS_PRESENTATION_REFRESH_MSEC
			)
			_office_storytelling.update_campus_presentation(
				active_snapshot,
				{
					# Day 1 already teases the next perch inside the bureau. Beginning
					# on Day 2, show at most one physical capital hint one shift before
					# its unchanged economic gate.
					"show_next_teaser": int(snapshot.get("day", 1)) >= 2,
					"teaser_window_days": 1,
				},
			)
	var bounds_started := Time.get_ticks_usec()
	_update_campus_world_bounds(snapshot)
	var feedback_started := Time.get_ticks_usec()
	if _workstation_feedback != null:
		_workstation_feedback.apply_snapshot(_workstation_visual_snapshot(active_snapshot))
	var surfaces_started := Time.get_ticks_usec()
	_refresh_visible_management_surfaces(snapshot)
	var routing_started := Time.get_ticks_usec()
	if _routing_ui != null:
		_routing_ui.apply_snapshot(_routing_visual_snapshot(active_snapshot))
	var coach_started := Time.get_ticks_usec()
	_refresh_priority_peck_precision_focus(snapshot)
	_refresh_first_clutch_ui(snapshot)
	_update_break_even_milestone(snapshot)
	if _flockwatch_open:
		_refresh_flockwatch_navigation(snapshot)
	elif _flockwatch_navigation != null:
		_flockwatch_navigation.apply_accessibility_snapshot(snapshot)
		_flockwatch_navigation.set_first_clutch_active(
			not bool(_first_clutch.get("dismissed", true))
			and not bool(_first_clutch.get("completed", false))
		)
	var snapshot_day := int(snapshot.get("day", presented_day))
	if snapshot_day > _last_reviewed_day and _management_presence != null:
		_last_reviewed_day = snapshot_day
		if _office_atmosphere != null:
			_office_atmosphere.pulse_farmer_review()
		_management_presence.play_review()
		if _camera_controller != null:
			_camera_controller.focus_point(_management_presence.review_focus_point(), "FARMER INSPECTION", 0.85)
	var display_clock := _clock_stamp_for_snapshot(snapshot)
	_update_shift_clock_copy(
		int(display_clock.get("day", snapshot_day)),
		String(display_clock.get("time_label", "")),
	)
	_authoritative_revenue_cents = int(snapshot.get("revenue_cents", 0))
	var available_to_display := maxi(0, _authoritative_revenue_cents - _pending_collection_cents)
	if _displayed_revenue_cents < 0:
		_displayed_revenue_cents = available_to_display
		_fund_visual_target_cents = available_to_display
	if _fund_counter_active:
		if available_to_display != _fund_visual_target_cents:
			_tween_fund_to(available_to_display)
	else:
		_displayed_revenue_cents = available_to_display
		_fund_visual_target_cents = available_to_display
		_update_fund_label()
	var eggs_today := int(snapshot.get("eggs_today", 0))
	var quota_target := maxi(1, int(snapshot.get("quota_target", 1)))
	_quota_progress.max_value = quota_target
	_quota_progress.value = mini(eggs_today, quota_target)
	_quota_progress_label.text = "QUOTA  ·  %d / %d" % [eggs_today, quota_target]
	var eggs_remaining := maxi(0, quota_target - eggs_today)
	var quota_accessible := (
		"Shift quota met: %d of %d eggs laid. Flockwatch score goals are tracked separately."
		% [eggs_today, quota_target]
		if eggs_remaining == 0 else
		"Shift quota: %d of %d eggs laid; %d remaining. This operating target is separate from Flockwatch score goals, which may be higher." % [
			eggs_today,
			quota_target,
			eggs_remaining,
		]
	)
	_quota_progress.tooltip_text = quota_accessible
	_quota_progress.accessibility_name = quota_accessible
	_quota_progress_label.tooltip_text = quota_accessible
	_quota_progress_label.accessibility_name = quota_accessible
	if _shift_egg_goal_label != null:
		_shift_egg_goal_label.tooltip_text = quota_accessible
		_shift_egg_goal_label.accessibility_name = quota_accessible
	if _shift_goal_status_icon != null:
		_shift_goal_status_icon.tooltip_text = quota_accessible
		_shift_goal_status_icon.set_meta("accessible_text", quota_accessible)
	if _shift_goal_status_host != null:
		_shift_goal_status_host.set_meta("accessible_text", quota_accessible)
		_shift_goal_status_host.set_meta("laid", eggs_today)
		_shift_goal_status_host.set_meta("target", quota_target)
		_shift_goal_status_host.set_meta("remaining", eggs_remaining)
	var quality_streak := int(snapshot.get("quality_streak", 0))
	var reward_ladder := _clutch_reward_ladder_snapshot(quality_streak)
	var packing_status := snapshot.get("packing_contract", {}) as Dictionary
	if bool(packing_status.get("enabled", false)):
		_quality_streak_label.text = "×%d" % quality_streak
		_quality_streak_label.tooltip_text = "%s\n%s" % [
			"Sound and golden eggs fill the Packing Annex carton. The sixth pays $%.2f at annex level %d."
			% [
				float(packing_status.get("next_carton_bonus_cents", 0)) / 100.0,
				int(packing_status.get("level", 0)),
			],
			String(reward_ladder.get("accessible_text", "")),
		]
	else:
		_quality_streak_label.text = "×%d" % quality_streak
		_quality_streak_label.tooltip_text = String(reward_ladder.get(
			"accessible_text",
			"Consecutive sound or golden eggs increase the clean-clutch credit.",
		))
	_quality_streak_label.accessibility_name = _quality_streak_label.tooltip_text
	_quality_streak_label.set_meta("reward_ladder", reward_ladder.duplicate(true))
	_set_hud_font_color(
		_quality_streak_label,
		Color("f4cd66")
		if quality_streak >= 4 or int(packing_status.get("carton_progress", 0)) >= 5 else
		Color("9ccfc2")
	)
	# The Today filing owns the complete quality ledger. Keep the live rail quiet
	# until the streak or Packing Annex state is actionable.
	_quality_streak_label.visible = (
		quality_streak > 0
		or int(packing_status.get("carton_progress", 0)) > 0
	)
	var policy_started := Time.get_ticks_usec()
	var active_directive := snapshot.get("active_directive", {}) as Dictionary
	var directive_text := (
		"POLICY  ·  %s" % String(active_directive.get("short_name", "UNSET"))
		if not active_directive.is_empty() else
		"POLICY  ·  BRIEFING DUE"
	)
	var directive_compact_text := (
		String(active_directive.get("short_name", "BRIEFING"))
		if not active_directive.is_empty() else
		"BRIEFING"
	)
	var directive_icon_kind := _live_policy_icon(StringName(active_directive.get("id", &"")))
	var labor_tooltip := ""
	var active_compact := snapshot.get("flock_compact", {}) as Dictionary
	var work_to_rule := snapshot.get("work_to_rule", {}) as Dictionary
	if bool(work_to_rule.get("active", false)):
		directive_text = "WORK-TO-RULE ACTIVE"
		directive_compact_text = "WORK-TO-RULE"
		directive_icon_kind = &"pause"
		labor_tooltip = "The flock is following every written step; output is slower and shells are safer."
	elif not active_compact.is_empty():
		directive_text = "COMPACT %s" % String(active_compact.get("status", "active")).to_upper()
		directive_compact_text = "COMPACT"
		directive_icon_kind = &"compact"
		labor_tooltip = "%s: %s" % [
			String(active_compact.get("compact_name", "Binding flock compact")),
			String(active_compact.get("condition", "Closing ledger decides fulfillment.")),
		]
	elif bool(work_to_rule.get("scheduled", false)):
		directive_text = "FLOCK ACTION FILED"
		directive_compact_text = "ACTION FILED"
		directive_icon_kind = &"pause"
		labor_tooltip = "A work-to-rule shift is scheduled for Day %d." % int(work_to_rule.get("day", 0))
	_directive_badge.set_meta("full_text", directive_text)
	_directive_badge.set_meta("compact_text", directive_compact_text)
	_directive_badge.set_meta("semantic_icon", String(directive_icon_kind))
	var directive_accent := _live_policy_accent(directive_icon_kind)
	_set_hud_font_color(_directive_badge, directive_accent)
	if _directive_badge_icon != null:
		_directive_badge_icon.configure(
			directive_icon_kind,
			directive_accent,
		)
		_directive_badge_icon.set_meta("semantic_icon", String(directive_icon_kind))
	_apply_live_policy_scale(float(_player_preferences.get("ui_scale", 1.0)))
	_directive_badge.tooltip_text = String(active_directive.get(
		"preview",
		"Choose a morning policy to begin the shift.",
	))
	if not active_directive.is_empty() and not _campaign_senior_roost:
		var active_order_fit := _directive_order_fit(StringName(active_directive.get("id", &"")))
		var active_fit_detail := String(active_order_fit.get("detail", ""))
		if not active_fit_detail.is_empty():
			_directive_badge.tooltip_text += "\n\n%s" % active_fit_detail
	if not labor_tooltip.is_empty():
		_directive_badge.tooltip_text += "\n%s" % labor_tooltip
	var exact_policy_name := String(active_directive.get(
		"name",
		directive_text.replace("  ·  ", " "),
	))
	_directive_badge.accessibility_name = "%s. %s" % [
		exact_policy_name,
		_directive_badge.tooltip_text,
	]
	_directive_badge.set_meta("accessible_text", _directive_badge.accessibility_name)
	if _directive_badge_host != null:
		_directive_badge_host.set_meta("full_text", directive_text)
		_directive_badge_host.set_meta("compact_text", directive_compact_text)
		_directive_badge_host.set_meta("semantic_icon", String(directive_icon_kind))
		_directive_badge_host.set_meta("accessible_text", _directive_badge.accessibility_name)
	var overdue_claims := int(snapshot.get("overdue_claims", (snapshot.get("routing", {}) as Dictionary).get("overdue_total", 0)))
	var ledger_started := Time.get_ticks_usec()
	_today_workload_label.text = "WORKLOAD · %d / %d LIVE · %d OVERDUE · %d TURNED AWAY" % [
		int(snapshot.get("claims_outstanding", snapshot.get("claims_waiting", 0))),
		int(snapshot.get("claim_capacity", 18)),
		overdue_claims,
		int(snapshot.get("intake_rejections_today", 0)),
	]
	_today_workload_label.tooltip_text = (
		"Live files against current intake capacity, including overdue files and files turned away today."
	)
	_today_clutch_label.text = "CLUTCH · %d / %d TODAY · %d CAREER EGGS" % [
		int(snapshot.get("eggs_today", 0)),
		int(snapshot.get("quota_target", 0)),
		int(snapshot.get("eggs_total", 0)),
	]
	_today_clutch_label.tooltip_text = (
		"Today's gathered eggs against the clutch target, followed by the career egg total."
	)

	var morale_total := 0.0
	var worker_data: Array = active_snapshot.get("workers", [])
	for worker_snapshot in worker_data:
		morale_total += float(worker_snapshot["morale"])
		var worker_id := int(worker_snapshot["id"])
		if _worker_views.has(worker_id):
			_worker_views[worker_id].apply_snapshot(worker_snapshot)
	_today_flock_label.text = "FLOCK · %d%% SPIRITS · %d%% UNITY RISK" % [
		int(morale_total / maxf(1.0, float(worker_data.size()))),
		int(snapshot.get("solidarity", 0)),
	]
	_today_flock_label.tooltip_text = (
		"Average flock morale and the current unity pressure behind labor petitions."
	)
	var economic_briefing := snapshot.get("economic_briefing", {}) as Dictionary
	var economic_cash := economic_briefing.get("cash", {}) as Dictionary
	var spendable_cents := int(economic_cash.get(
		"spendable_fund_cents",
		snapshot.get("spendable_fund_cents", 0),
	))
	var secured_margin_cents := int(economic_cash.get("secured_operating_margin_cents", 0))
	var break_even_remaining_cents := int(economic_cash.get("break_even_remaining_cents", 0))
	_today_ledger_label.text = (
		"LEDGER · FUND $%.2f · RESERVED $%.2f · FREE $%.2f\n"
		+ "NET %s · NEED $%.2f · STANDING %d · %d%% FARMER FAVOR · %d%% COOP OBEDIENCE"
	) % [
		float(int(economic_cash.get(
			"feed_fund_cents",
			snapshot.get("revenue_cents", 0),
		))) / 100.0,
		float(int(economic_cash.get(
			"protected_reserve_cents",
			snapshot.get("protected_reserve_cents", 0),
		))) / 100.0,
		float(spendable_cents) / 100.0,
		_signed_flockwatch_currency(secured_margin_cents),
		float(break_even_remaining_cents) / 100.0,
		int(snapshot.get("market_contract_standing", 0)),
		int(snapshot.get("executive_confidence", 0)),
		int(snapshot.get("compliance", 0)),
	]
	_today_ledger_label.tooltip_text = (
		"Feed Fund minus protected payroll, feed, upkeep, breach, arrears, and debt "
		+ "equals discretionary money. Secured net is credited income minus today's complete "
		+ "filed operating cost; NEED is the remaining credit required to break even. "
		+ "Open Capital for the exact run rate, market, "
		+ "bottleneck, five-close trend, resource map, and recovery file."
	)
	_sync_flockwatch_glance(
		_today_workload_glance,
		_today_workload_label,
		"%d / %d\n%d LATE" % [
			int(snapshot.get("claims_outstanding", snapshot.get("claims_waiting", 0))),
			int(snapshot.get("claim_capacity", 18)),
			overdue_claims,
		],
		Color("f0aa95") if overdue_claims > 0 else Color("dce7e8"),
	)
	_sync_flockwatch_glance(
		_today_clutch_glance,
		_today_clutch_label,
		"%d / %d\n%d TOTAL" % [
			int(snapshot.get("eggs_today", 0)),
			int(snapshot.get("quota_target", 0)),
			int(snapshot.get("eggs_total", 0)),
		],
		Color("dce7e8"),
	)
	var average_morale := int(morale_total / maxf(1.0, float(worker_data.size())))
	_sync_flockwatch_glance(
		_today_flock_glance,
		_today_flock_label,
		"%d%%\nRISK %d" % [
			average_morale,
			int(snapshot.get("solidarity", 0)),
		],
		Color("f0aa95") if int(snapshot.get("solidarity", 0)) >= 45 else Color("dce7e8"),
	)
	_sync_flockwatch_glance(
		_today_cash_glance,
		_today_ledger_label,
		"FREE $%s\nNET %s" % [
			_compact_flockwatch_currency(spendable_cents),
			_signed_flockwatch_currency(secured_margin_cents),
		],
		Color("f0aa95") if secured_margin_cents < 0 else Color("73b5a7"),
	)
	_today_cash_glance.set_meta("spendable_fund_cents", spendable_cents)
	_today_cash_glance.set_meta("secured_operating_margin_cents", secured_margin_cents)
	_today_cash_glance.set_meta("break_even_remaining_cents", break_even_remaining_cents)
	_today_cash_glance.set_meta(
		"margin_state",
		&"deficit" if secured_margin_cents < 0 else &"cleared",
	)
	var case_docket := snapshot.get("case_docket", {}) as Dictionary
	var active_precedents: Array[Dictionary] = []
	for precedent_value: Variant in case_docket.get("active_precedents", []):
		if precedent_value is Dictionary:
			active_precedents.append((precedent_value as Dictionary).duplicate(true))
	if active_precedents.is_empty():
		var legacy_active_precedent := case_docket.get("active_precedent", {}) as Dictionary
		if not legacy_active_precedent.is_empty():
			active_precedents.append(legacy_active_precedent.duplicate(true))
	var pivot_mastery := case_docket.get("pivot_mastery", {}) as Dictionary
	var pivot_mastered_count := int(pivot_mastery.get("mastered_count", 0))
	var pivot_total_count := int(pivot_mastery.get("total_count", 3))
	_today_precedent_label.visible = not active_precedents.is_empty() or pivot_mastered_count > 0
	if _today_precedent_label.visible:
		var precedent_lines: Array[String] = []
		var precedent_tooltips: Array[String] = []
		if pivot_mastered_count > 0:
			precedent_lines.append("ADAPTIVE CASEWORK · %d / %d PAIRS%s" % [
				pivot_mastered_count,
				pivot_total_count,
				" · COMMENDATION FILED" if bool(pivot_mastery.get("complete", false)) else "",
			])
		if active_precedents.size() > 1:
			precedent_lines.append("OPEN PRECEDENTS · %d" % active_precedents.size())
		for active_precedent: Dictionary in active_precedents:
			precedent_lines.append("%s%s // %s · %s" % [
				"OPEN PRECEDENT · " if active_precedents.size() == 1 else "- ",
				String(active_precedent.get("strategy_label", "PIVOT OPPORTUNITY")),
				String(active_precedent.get("target_label", "NEXT RELATED CASE")),
				String(active_precedent.get("summary", "A prior response changes the next related case.")),
			])
			precedent_tooltips.append("Day %d / %s" % [
				int(active_precedent.get("source_day", 0)),
				String(active_precedent.get("source_summary", "incident response")),
			])
		_today_precedent_label.text = "\n".join(precedent_lines)
		_today_precedent_label.tooltip_text = "Master each pair by filing its highlighted pivot."
		if not precedent_tooltips.is_empty():
			_today_precedent_label.tooltip_text += (
				" Open until each next related case. " + "; ".join(precedent_tooltips)
			)
	else:
		_today_precedent_label.text = ""
		_today_precedent_label.tooltip_text = ""

	var controls_started := Time.get_ticks_usec()
	var overtime_active := bool(snapshot.get("overtime_enabled", false))
	_overtime_button.text = "%s  [%s]" % [
		"END AFTER-HOURS PECKING" if overtime_active else "ENABLE AFTER-HOURS PECKING",
		_action_hint(&"toggle_overtime"),
	]
	_overtime_button.button_pressed = overtime_active
	var shift_phase := int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
	var shift_running := shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
	if _routing_ui != null:
		_routing_ui.set_peck_assist_clock_running(_clock.speed_index > 0)
	# Reuse the clock's settled read model. An exact snapshot here rebuilds all
	# management projections and invalidates the live cache on every tick.
	_refresh_floor_input_context(snapshot)
	var campaign_modal_open := _campaign_ui != null and _campaign_ui.is_modal_open()
	_overtime_button.disabled = not shift_running or _feed_party_active or campaign_modal_open
	_continue_shift_button.visible = shift_phase == DepartmentSimulation.ShiftPhase.REVIEW
	if _continue_shift_button.visible:
		_apply_review_progression_action(snapshot)

	var fund_cents := int(snapshot.get("revenue_cents", 0))
	var spendable_fund_cents := int(snapshot.get("spendable_fund_cents", fund_cents))
	var feed_used := bool(snapshot.get("feed_party_used_today", false))
	if campaign_modal_open:
		_feed_button.text = "FEED PARTY HELD DURING %s REVIEW" % (
			"SENIOR ROOST" if _campaign_senior_roost else "PROBATION"
		)
		_feed_button.disabled = true
	elif not shift_running:
		_feed_button.text = "FEED PARTY UNAVAILABLE DURING REVIEW"
		_feed_button.disabled = true
	elif _feed_party_active:
		_feed_button.text = "FEED PARTY IN PROGRESS"
		_feed_button.disabled = true
	elif feed_used:
		_feed_button.text = "FEED PARTY USED THIS SHIFT"
		_feed_button.disabled = true
	else:
		_feed_button.text = "FUND FEED PARTY  ($20)  [%s]" % _action_hint(&"fund_feed_party")
		_feed_button.disabled = spendable_fund_cents < 2000

	for upgrade_value in snapshot.get("upgrade_catalog", []):
		var upgrade := upgrade_value as Dictionary
		var upgrade_id := StringName(upgrade.get("id", &""))
		var button: Button = _upgrade_buttons.get(upgrade_id)
		if button == null:
			continue
		var level := int(upgrade.get("level", 0))
		var max_level := int(upgrade.get("max_level", 5))
		var cost := int(upgrade.get("cost_cents", 0))
		var maxed := bool(upgrade.get("maxed", false))
		var benefit_names := {&"peckwork_tools": "TOOLS · FASTER WORK", &"shell_lamp": "LAMP · SAFER SHELLS", &"nest_cushion": "CUSHION · LESS STRAIN"}
		button.text = "%s · %d/%d\n%s" % [
			String(benefit_names.get(upgrade_id, upgrade.get("short_name", "UPGRADE"))), level, max_level,
			("FULLY APPROVED" if maxed else "$%.2f · $%.2f %s" % [cost / 100.0, absf(float(spendable_fund_cents - cost)) / 100.0, "LEFT" if spendable_fund_cents >= cost else "SHORT"]),
		]
		button.disabled = maxed or spendable_fund_cents < cost
		button.tooltip_text = "%s\n%s\n%s\nSpends the fund now; changes future work rates or odds, not a guaranteed result." % [
			String(upgrade.get("name", "")),
			String(upgrade.get("description", "")),
			_upgrade_effect_comparison(upgrade_id, level + 1) if not maxed else "MAXIMUM LEVEL",
		]
	_refresh_upgrade_disclosure(snapshot)
	_update_flockwatch_toggle(snapshot)
	var goals_started := Time.get_ticks_usec()
	_update_campaign_objectives_label(snapshot)
	_update_flock_labor_label(snapshot)
	_update_records_archive_summary(snapshot)
	_update_guidance(snapshot)
	var pulse_started := Time.get_ticks_usec()
	_refresh_gameplay_pulse(snapshot)
	var finish_started := Time.get_ticks_usec()
	_update_commendations(snapshot)
	_publish_web_diagnostic_state(snapshot)
	_snapshot_presentation_usec = Time.get_ticks_usec() - presentation_started

	_snapshot_presentation_timing = {
		"presentation_usec": scene_started - presentation_started,
		"scene_usec": routing_started - scene_started,
		"roster_usec": duties_started - scene_started,
		"duties_usec": atmosphere_started - duties_started,
		"atmosphere_usec": story_started - atmosphere_started,
		"story_usec": bounds_started - story_started,
		"story_live_usec": campus_started - story_started,
		"campus_usec": bounds_started - campus_started,
		"bounds_usec": feedback_started - bounds_started,
		"feedback_usec": surfaces_started - feedback_started,
		"surfaces_usec": routing_started - surfaces_started,
		"routing_usec": coach_started - routing_started,
		"coach_usec": policy_started - coach_started,
		"policy_usec": ledger_started - policy_started,
		"ledger_usec": controls_started - ledger_started,
		"controls_usec": goals_started - controls_started,
		"goals_usec": pulse_started - goals_started,
		"pulse_usec": finish_started - pulse_started,
		"finish_usec": Time.get_ticks_usec() - finish_started,
	}


func _refresh_visible_management_surfaces(
	snapshot: Dictionary,
	_force_legacy_hidden_refresh: bool = false
) -> void:
	# Full-screen planners receive a fresh snapshot when opened. While hidden,
	# rebuilding their card trees on every accelerated tick creates allocations
	# the player can neither see nor act on.
	var active_filing := (
		_flockwatch_navigation.current_page_id()
		if _flockwatch_navigation != null else
		FlockwatchNavigation.PAGE_TODAY
	)
	var staffing_filing_visible := (
		_flockwatch_open
		and active_filing in [
			FlockwatchNavigation.PAGE_FLOCK,
			FlockwatchNavigation.PAGE_OPERATIONS,
			FlockwatchNavigation.PAGE_CAPITAL,
			FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS,
		]
	)
	var staffing_fingerprint := _staffing_presentation_state_fingerprint(snapshot)
	var staffing_semantics_changed := (
		staffing_fingerprint != _staffing_presentation_fingerprint
	)
	if _staffing_ui != null and (staffing_filing_visible or staffing_semantics_changed):
		_staffing_ui.apply_snapshot(snapshot)
		_staffing_presentation_fingerprint = staffing_fingerprint
	if (
		_economic_briefing_ui != null
		and _flockwatch_open
		and active_filing == FlockwatchNavigation.PAGE_CAPITAL
	):
		_economic_briefing_ui.apply_snapshot(snapshot)
	if (
		_capital_blueprint_ui != null
		and _capital_blueprint_ui.visible
		and _capital_blueprint_ui.has_method("apply_snapshot")
	):
		_capital_blueprint_ui.call("apply_snapshot", snapshot)
	if _campus_expansion_ui != null and _campus_expansion_ui.visible:
		_campus_expansion_ui.call("set_snapshot", snapshot)
	if _campus_portfolio_ui != null and _campus_portfolio_ui.visible:
		_campus_portfolio_ui.call("apply_snapshot", snapshot)
	if _pecking_order_ui != null and _pecking_order_ui.is_visible_in_tree():
		_pecking_order_ui.call("apply_snapshot", snapshot)


func _initialize_management_surfaces(snapshot: Dictionary) -> void:
	# Build stable action nodes once behind the campaign title so filters and
	# accessibility retain node identity. Subsequent ticks use visibility gates.
	if _staffing_ui != null:
		_staffing_ui.apply_snapshot(snapshot)
		_staffing_presentation_fingerprint = _staffing_presentation_state_fingerprint(snapshot)
	if _economic_briefing_ui != null:
		_economic_briefing_ui.apply_snapshot(snapshot)
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("apply_snapshot", snapshot)
	if _campus_expansion_ui != null:
		_campus_expansion_ui.call("set_snapshot", snapshot)
	if _campus_portfolio_ui != null:
		_campus_portfolio_ui.call("apply_snapshot", snapshot)
	if _pecking_order_ui != null:
		_pecking_order_ui.call("apply_snapshot", snapshot)


func _staffing_presentation_state_fingerprint(snapshot: Dictionary) -> int:
	var capacity := snapshot.get("capacity_upgrade", {}) as Dictionary
	var pending := snapshot.get("pending_decision", {}) as Dictionary
	return hash([
		bool(snapshot.get("staffing_planning_open", false)),
		int(snapshot.get("shift_phase", 0)),
		String(snapshot.get("pending_decision_kind", pending.get("kind", ""))),
		int(snapshot.get("active_staff_count", 0)),
		int(snapshot.get("office_capacity", 0)),
		int(capacity.get("next_capacity", 0)),
		bool(capacity.get("can_purchase", capacity.get("available", false))),
		String(capacity.get("reason", "")),
		snapshot.get("last_staffing_action", {}),
		snapshot.get("internship_program", {}),
	])


func _refresh_upgrade_disclosure(snapshot: Dictionary) -> void:
	if _upgrade_disclosure_toggle == null:
		return
	var ready_count := 0
	var complete_count := 0
	var file_count := 0
	for upgrade_value: Variant in snapshot.get("upgrade_catalog", []):
		if not upgrade_value is Dictionary:
			continue
		var upgrade := upgrade_value as Dictionary
		var upgrade_id := StringName(String(upgrade.get("id", "")))
		var button: Button = _upgrade_buttons.get(upgrade_id)
		if button == null:
			continue
		file_count += 1
		if bool(upgrade.get("maxed", false)):
			complete_count += 1
		elif not button.disabled:
			ready_count += 1
	_upgrade_disclosure_toggle.set_summary(
		"%d READY" % ready_count if ready_count > 0 else "%d FILES" % file_count,
		"Desk requisitions: %d total, %d ready, %d complete." % [
			file_count,
			ready_count,
			complete_count,
		],
	)
	var actionable := ready_count > 0
	if actionable and not _had_actionable_upgrade:
		_upgrade_disclosure_toggle.set_expanded(true, false)
	_had_actionable_upgrade = actionable


func _refresh_flockwatch_navigation(snapshot: Dictionary) -> void:
	if _flockwatch_navigation == null:
		return
	# Flockwatch owns the one defensive deep copy it retains. This wrapper only
	# adds top-level presentation keys, so a shallow copy avoids duplicating the
	# complete economy twice whenever the visible ledger refreshes.
	var presentation := snapshot.duplicate()
	var first_clutch_active := (
		not bool(_first_clutch.get("dismissed", true))
		and not bool(_first_clutch.get("completed", false))
	)
	var orientation_resolved := (
		bool(_first_clutch.get("completed", false))
		or (
			bool(_first_clutch.get("dismissed", false))
			and int(_first_clutch.get("target_worker_id", -1)) >= 0
		)
		or int(snapshot.get("day", 1)) > 1
	)
	var relevance := {
		&"operations": orientation_resolved,
		&"capital": orientation_resolved or int(snapshot.get(
			"shift_phase", DepartmentSimulation.ShiftPhase.RUNNING
		)) == DepartmentSimulation.ShiftPhase.REVIEW,
		&"governance_records": _campaign_senior_roost,
	}
	presentation["first_clutch_active"] = first_clutch_active
	presentation["flockwatch_relevance"] = relevance
	presentation["pause_context"] = _pause_context_state()
	_flockwatch_navigation.apply_snapshot(presentation)


func _on_worker_workstation_presence_changed(worker_id: int, is_present: bool) -> void:
	_simulation.set_worker_at_workstation(worker_id, is_present)


func _on_egg_laid(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	claim_id: int = -1,
	priority_credit_cents: int = -1
) -> void:
	var probe_started := _simulation.cost_probe.begin()
	var worker_view: ChickenView = _worker_views.get(worker_id) as ChickenView
	if worker_view == null or not is_instance_valid(worker_view) or not worker_view.is_seated_at_workstation():
		push_error("Blocked egg spawn for worker %d because the hen is not seated at her workstation." % worker_id)
		return
	# The simulation has now completed the exact assisted active claim. Record this
	# before the existing egg checkpoint; the physical presentation callback below
	# is still required before the induction can celebrate completion.
	_first_clutch_record_laid_egg(
		worker_id, quality, value_cents, claim_id, priority_credit_cents
	)
	_eggs_in_flight_by_worker[worker_id] = int(_eggs_in_flight_by_worker.get(worker_id, 0)) + 1
	_queue_collection_claim(worker_id, claim_id)
	if _workstation_feedback != null:
		_workstation_feedback.pulse_completion(worker_id, quality)
	if not _upgrade_demonstration.is_empty() and not _upgrade_demonstration.has("claim_id") and claim_id >= 0:
		_upgrade_demonstration["claim_id"] = claim_id
		_upgrade_demonstration["worker_id"] = worker_id
	var presentation_cash_cents := _immediate_cash_for_completed_egg(
		claim_id,
		quality,
		value_cents,
	)
	_collection_cash_by_claim_id[claim_id] = presentation_cash_cents
	_collection_stocked_by_claim_id[claim_id] = presentation_cash_cents == 0 and quality in [
		&"sound", &"golden",
	]
	_pending_collection_cents += presentation_cash_cents
	_begin_egg_journey_receipt(
		worker_id,
		claim_id,
		quality,
		value_cents,
		presentation_cash_cents,
		priority_credit_cents,
	)
	var egg := MeshInstance3D.new()
	egg.name = "Egg_%s_%d" % [quality, Time.get_ticks_msec()]
	egg.mesh = ProceduralPrimitiveCache.sphere(0.5, 1.0, 18, 10)
	egg.scale = Vector3(0.32, 0.43, 0.32)
	egg.position = _egg_layer.to_local(worker_view.egg_lay_origin_global())
	var egg_color := Color("e9e2c8")
	if quality == &"cracked":
		egg_color = Color("b98f7b")
	elif quality == &"golden":
		egg_color = Color("f4c95d")
	egg.material_override = _material(egg_color)
	_egg_layer.add_child(egg)
	_spawn_egg_vfx(egg.position, quality, worker_id)
	if _office_atmosphere != null:
		_office_atmosphere.pulse_egg_laid(worker_view.egg_lay_origin_global(), quality)
	# The reaction and cause receipt describe the same completed egg. Build its
	# exact production counters without rebuilding unrelated management catalogs.
	var after_snapshot := _simulation.production_reaction_snapshot()
	var worker_after := _worker_record(after_snapshot, worker_id)
	var lifetime_eggs := int(worker_after.get("eggs_laid", 0))
	if int(_upgrade_demonstration.get("claim_id", -2)) == claim_id:
		worker_view.play_short_bark("NEW KIT, FIRST EGG!", &"team")
	elif lifetime_eggs in [10, 25, 50, 100]:
		worker_view.play_short_bark("THAT'S MY %dTH EGG!" % lifetime_eggs, &"success")
	else:
		worker_view.play_short_bark(
			"GOLDEN FILE!" if quality == &"golden" else "NEEDS REWORK." if quality == &"cracked" else "CLEAN SHELL!",
			&"success" if quality in [&"sound", &"golden"] else &"risk",
		)

	var streak := _simulation.quality_streak
	var streak_bonus := _simulation.last_streak_bonus_cents
	var collection_animated := false
	if _office_storytelling != null:
		collection_animated = _office_storytelling.animate_egg_collection(
			egg, worker_id, quality, true, value_cents, streak_bonus
		)
	if not collection_animated:
		var tween := _presentation_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(egg, "position", Vector3(9.4, 1.25, -6.85), 1.45)
		tween.parallel().tween_property(egg, "rotation_degrees:y", 540.0, 1.45)
		tween.tween_callback(_on_egg_graded.bind(
			worker_id, quality, value_cents, streak_bonus, egg.global_position
		))
		tween.tween_interval(0.18)
		tween.tween_callback(_on_egg_reached_presentation.bind(
			worker_id, quality, value_cents, streak_bonus
		))
		tween.tween_callback(egg.queue_free)
	if quality == &"cracked":
		_ticker_label.text = "CRACKED EGG ENTERED GRADING  ·  clean-clutch chain broken"
	else:
		var attention_suffix := (
			"  ·  PRIORITY CHARGE RETURNS AT FARMER"
			if priority_credit_cents > 0 else
			""
		)
		_ticker_label.text = "%s EGG ENTERED GRADING  ·  CLEAN CLUTCH ×%d%s" % [
			String(quality).to_upper(), streak, attention_suffix,
		]
		if _quality_streak_label != null:
			var streak_tween := _presentation_tween()
			_quality_streak_label.modulate = Color("ffe39a")
			streak_tween.tween_property(_quality_streak_label, "modulate", Color.WHITE, 0.65)
	if quality == &"golden" and _camera_controller != null:
		_camera_controller.show_event_focus(worker_view.global_position + Vector3.UP * 0.82, "GOLDEN EGG", 1.55)
	var before_snapshot := after_snapshot.duplicate()
	before_snapshot["eggs_today"] = maxi(
		0,
		int(after_snapshot.get("eggs_today", 0)) - 1,
	)
	if quality == &"cracked":
		before_snapshot["cracked_today"] = maxi(
			0,
			int(after_snapshot.get("cracked_today", 0)) - 1,
		)
	var worker_name := String(worker_after.get("name", "HEN %d" % (worker_id + 1)))
	var lane_label := _dispatch_lane_label(StringName(worker_after.get("assigned_lane", &"auto")))
	_record_campaign_order_cause_receipts(
		before_snapshot,
		after_snapshot,
		"%s/%s" % [worker_name, lane_label],
		&"routed_egg",
		String(quality),
		{
			"source_kind": "worker_file",
			"source_label": worker_name,
			"worker_id": worker_id,
			"claim_id": int(worker_after.get("last_completed_claim_id", -1)),
		},
	)
	# The tutorial's first delivery remains a hard recovery point. Once the player
	# is on the ordinary floor, burst production is coalesced instead of forcing a
	# complete verified file transaction for every individual egg.
	if _first_clutch_tracking_active():
		_save_campaign_checkpoint("egg_laid")
	else:
		_queue_campaign_checkpoint("egg_laid")

	_simulation.cost_probe.finish(&"egg_laid", probe_started)


func _immediate_cash_for_completed_egg(
	claim_id: int,
	quality: StringName,
	value_cents: int,
) -> int:
	if quality == &"cracked":
		return maxi(0, value_cents)
	# Egg completion is a high-frequency production event. Reading the focused
	# dispatch projection avoids rebuilding the entire authoritative economy for
	# a boolean and a handful of refrigerated lots.
	var dispatch := _simulation.farmgate_dispatch_snapshot()
	if not bool(dispatch.get("enabled", false)):
		return maxi(0, value_cents)
	for lot_value: Variant in dispatch.get("lots", []):
		if lot_value is Dictionary and int((lot_value as Dictionary).get("claim_id", -2)) == claim_id:
			return 0
	# A completed sound/golden egg that is absent from a commissioned cold store
	# used the authoritative 90% overflow pickup. Mirror that exact half-up amount
	# so the Feed Fund animation never invents the missing ten percent.
	return (maxi(0, value_cents) * 9_000 + 5_000) / 10_000


func _on_management_context_hover_changed(
	worker_id: int,
	context_id: StringName,
	hovered: bool,
) -> void:
	if context_id not in [&"work_progress", &"equipment", &"hen_intent"] or _workstation_feedback == null:
		return
	if hovered and (_blocking_management_surface_open() or _first_clutch_tracking_active()):
		return
	_workstation_feedback.set_work_progress_hover(worker_id if hovered else -1)
	if hovered:
		_context_hover_previous = _ticker_label.text
		# Hover copy needs only the current name, not an exact economic snapshot.
		# Read by ID so desk moves and renamed/restored hens remain correct.
		var worker_name := "HEN"
		if context_id == &"hen_intent":
			for worker in _simulation.workers:
				if worker.id == worker_id:
					worker_name = worker.display_name
					break
		_context_hover_copy = "VIEW UPGRADES" if context_id == &"equipment" else "HELP %s" % worker_name.to_upper() if context_id == &"hen_intent" else "VIEW FILE"
		_ticker_label.text = _context_hover_copy
	elif _ticker_label.text == _context_hover_copy:
		_ticker_label.text = _context_hover_previous


func _on_work_progress_context_selected(worker_id: int, context_id: StringName) -> void:
	if context_id not in [&"work_progress", &"hen_intent", &"equipment"] or _routing_ui == null:
		return
	if context_id != &"work_progress" and (_blocking_management_surface_open() or _first_clutch_tracking_active()):
		return
	if context_id == &"equipment":
		_open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
		_upgrade_disclosure_toggle.set_expanded(true, false)
		var upgrade := _upgrade_buttons.get(&"peckwork_tools") as Button
		if upgrade != null:
			upgrade.call_deferred("grab_focus")
			_pulse_action_target(upgrade)
		_publish_status_copy("DESK UPGRADES · Compare price and benefit. Select a purchase only when ready.", false)
		return
	if worker_id == _work_progress_context_suppressed_worker_id:
		_work_progress_context_suppressed_worker_id = -1
		return
	var snapshot := _simulation.snapshot()
	var worker := _worker_record(snapshot, worker_id)
	var claim := worker.get("current_claim", {}) as Dictionary
	var intent := worker.get("hen_intent", {}) as Dictionary
	if worker.is_empty() or (claim.is_empty() and context_id == &"work_progress") or intent.is_empty():
		return
	# Do not depend on focus_changed signal ordering: the physical rail owns an
	# explicit worker-to-dossier handoff even when invoked by touch, restore, or a
	# future input adapter.
	_routing_ui.set_focus(worker_id)
	var action_id := StringName(intent.get("action_id", &"claim"))
	var target := _routing_ui.focus_intent_action(action_id)
	var rail_status := "working"
	if _workstation_feedback != null:
		for desk_value in _workstation_feedback.work_progress_snapshot().get("desks", []):
			var desk := desk_value as Dictionary
			if int(desk.get("worker_id", -1)) == worker_id:
				rail_status = String(desk.get("status", rail_status))
				break
	_last_work_progress_action = {
		"worker_id": worker_id,
		"worker_name": String(worker.get("name", "HEN")),
		"claim_id": int(claim.get("id", -1)),
		"rail_status": rail_status,
		"intent_id": String(intent.get("id", &"")),
		"action_id": String(action_id),
		"action_label": String(intent.get("action_label", "OPEN FILE")),
		"target": target.name if target != null else "",
		"economic_action_committed": false,
	}
	_publish_status_copy(
		"%s  ·  %s  ·  %s READY" % [
			String(worker.get("name", "HEN")).to_upper(),
			String(intent.get("action_label", "OPEN FILE")).to_upper(),
			String(target.name).replace("_", " ").to_upper() if target != null else "FILE",
		],
		false,
	)
	_pulse_action_target(target)
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_publish_web_diagnostic_state(snapshot)


func _set_inspected_cubicle_cutaway(worker_id: int) -> void:
	var focused_view := _worker_views.get(worker_id) as ChickenView
	var focused_desk := focused_view.desk_index if focused_view != null and is_instance_valid(focused_view) else -1
	if _office_storytelling != null:
		_office_storytelling.set_inspection_collection_cutaway(focused_desk)
	for desk_index in _workstations_by_index:
		var workstation := _workstations_by_index[desk_index] as Node3D
		if workstation == null or not is_instance_valid(workstation):
			continue
		var cutaway := int(desk_index) == focused_desk
		for partition_name in ["CubicleBack", "CubicleWing_L", "PanelTopTrim", "Monitor", "Screen", "ScreenHeader", "ScreenAlert"]:
			var partition := workstation.find_child(partition_name, true, false) as MeshInstance3D
			if partition == null:
				continue
			# A true cutaway survives GL Compatibility's opaque imported material.
			# The monitor occupies the hen's body in this camera angle. It joins
			# the inspection-only cutaway; authored desk, collision and navigation
			# remain in place and all furniture returns in overview.
			partition.visible = not cutaway
			partition.transparency = INSPECTED_CUBICLE_TRANSPARENCY if cutaway else 0.0
			partition.cast_shadow = (
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if cutaway else
				GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			)
		for line in workstation.find_children("ScreenLine_*", "MeshInstance3D", true, false):
			(line as MeshInstance3D).visible = not cutaway


func _on_camera_focus_changed(label: String, worker_id: int) -> void:
	var dispatch_committed := false
	_intent_focus_worker_id = worker_id
	_set_inspected_cubicle_cutaway(worker_id)
	for view_worker_id in _worker_views:
		var intent_view := _worker_views.get(view_worker_id) as ChickenView
		if intent_view != null and is_instance_valid(intent_view):
			intent_view.set_management_focus(
				int(view_worker_id) == worker_id,
				worker_id >= 0,
			)
	if _workstation_feedback != null:
		_workstation_feedback.set_work_progress_selected(worker_id)
	# Every explicit camera selection is a fresh management inspection and may
	# arm one new precision intervention, including clicking the same hen again.
	_priority_peck_focus_disarmed_worker_id = -1
	# A deliberate focus change dismisses the prior claim's result beat. The new
	# selected hen should own precision timing immediately, and overview/facility
	# navigation should restore the player's requested speed without stale drag.
	if _priority_peck_result_hold_worker_id >= 0 and worker_id != _priority_peck_result_hold_worker_id:
		_priority_peck_result_hold_until_msec = 0
		_priority_peck_result_hold_worker_id = -1
		_priority_peck_result_hold_claim_id = -1
		_priority_peck_result_hold_kind = &""
	var focused := worker_id >= 0 or not label.is_empty()
	var focus_position := Vector3(INF, INF, INF)
	if focused and _camera_controller != null:
		focus_position = _camera_controller.focus_world_position()
	EnvironmentalSignageScript.set_camera_detail(self, focused, focus_position)
	# The Gallery is a compact exhibit room with four related evidence surfaces.
	# When its own landmark is focused, reveal that coherent group together instead
	# of applying the office-wide microcopy radius and leaving the attribution wall blank.
	if (
		_office_storytelling != null
		and _office_storytelling.farmer_relations_gallery_visual != null
		and _office_storytelling.farmer_relations_gallery_visual.has_method("set_camera_detail")
	):
		_office_storytelling.farmer_relations_gallery_visual.call(
			"set_camera_detail", focused, focus_position,
		)
	if worker_id >= 0 and _dispatch_lane != &"" and (_camera_controller == null or _camera_controller.active_selection_context() in [&"", &"work_progress"]):
		dispatch_committed = _commit_dispatch(worker_id)
		if (
			dispatch_committed
			and _camera_controller != null
			and _camera_controller.active_selection_context() == &"work_progress"
		):
			_work_progress_context_suppressed_worker_id = worker_id
	if worker_id >= 0:
		if (
			_first_hen_prelude_pending()
			and worker_id == int(_first_clutch.get("target_worker_id", -1))
		):
			_open_first_hen_file(worker_id, false)
		_first_clutch_record_inspection(worker_id)
	if _ticker_label == null:
		_publish_camera_diagnostic()
		return
	if worker_id >= 0 or not label.is_empty():
		if _flockwatch_open:
			_set_flockwatch_open(false)
		else:
			_refresh_flockwatch_camera_insets(false)
	if _routing_ui != null:
		_routing_ui.set_focus(worker_id if worker_id >= 0 else -1)
	# Camera reactions are read-only; retain exact live workers and reuse the
	# same immutable management projections as the clock.
	var focus_snapshot := _simulation.snapshot(true, true)
	_refresh_priority_peck_precision_focus(focus_snapshot)
	if dispatch_committed:
		_publish_camera_diagnostic(focus_snapshot)
		return
	if worker_id >= 0:
		var state_label := "ON TASK"
		var progress := 0
		var morale := 0
		var fatigue := 0
		var stress := 0
		for worker_variant in focus_snapshot.get("workers", []):
			var worker := worker_variant as Dictionary
			if int(worker.get("id", -1)) == worker_id:
				state_label = String(worker.get("state_label", state_label)).to_upper()
				progress = int(worker.get("progress", 0))
				morale = int(worker.get("morale", 0))
				fatigue = int(worker.get("fatigue", 0))
				stress = int(worker.get("stress", 0))
				break
		var crack_risk := int(_simulation.estimated_crack_risk(worker_id) * 100.0)
		_publish_status_copy(
			"%s  •  ♥ %d  •  Zz %d  •  ! %d  •  CRACK %d%%" % [
				label.to_upper(), morale, fatigue, stress, crack_risk,
			],
			true,
			"%s. %s, %d percent complete. Morale %d. Fatigue %d. Stress %d. Estimated shell crack risk %d percent." % [
				label, state_label.to_lower(), progress, morale, fatigue, stress, crack_risk,
			],
		)
		_ticker_label.set_meta("presentation_role", &"worker_vitals")
		_publish_camera_diagnostic(focus_snapshot)
		return
	if not label.is_empty():
		_publish_status_copy(label, false)
	else:
		_publish_status_copy(
			"Click a hen to inspect  ·  V opens Flockwatch  ·  Shift objective stays above.",
			false,
		)
	_publish_camera_diagnostic(focus_snapshot)


func _publish_camera_diagnostic(snapshot: Dictionary = {}) -> void:
	# Camera motion remains available while onboarding or Settings owns the
	# simulation clock. Retain the supplied immutable read for the on-demand
	# assistive mirror without creating another full management snapshot.
	if _simulation != null:
		_publish_web_diagnostic_state(snapshot if not snapshot.is_empty() else _simulation.snapshot(true, true))


func _on_egg_graded(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	streak_bonus_cents: int,
	_grading_world_position: Vector3
) -> void:
	if quality == &"cracked":
		var graded_hen := _worker_views.get(worker_id) as ChickenView
		if graded_hen != null:
			graded_hen.play_emotion(&"disappointed", "grade:%d" % _peek_collection_claim(worker_id))
	_update_egg_journey_receipt(
		worker_id,
		_peek_collection_claim(worker_id),
		{"stage": &"graded"},
	)
	var base_value := maxi(0, value_cents - streak_bonus_cents)
	if _audio_feedback != null:
		_audio_feedback.play_sorter_clack(quality)
	var dispatch := _simulation.farmgate_dispatch_snapshot()
	var destination := (
		"FARMGATE STOCK"
		if bool(dispatch.get("enabled", false)) and quality in [&"sound", &"golden"] else
		"FARMER"
	)
	_ticker_label.text = "%s GRADED  ·  $%.2f%s  →  %s" % [
		String(quality).to_upper(),
		base_value / 100.0,
		(" + $%.2f CLUTCH" % (streak_bonus_cents / 100.0) if streak_bonus_cents > 0 else ""),
		destination,
	]
	var reward_ladder := _clutch_reward_ladder_snapshot(_simulation.quality_streak)
	var milestone_label := String(reward_ladder.get("milestone_label", ""))
	if quality in [&"sound", &"golden"] and not milestone_label.is_empty():
		_ticker_label.text += "  ·  %s" % milestone_label


func _on_egg_reached_presentation(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	_streak_bonus_cents: int
) -> void:
	var delivered_claim_id := _take_collection_claim(worker_id)
	if quality in [&"sound", &"golden"]:
		_hen_social.celebrate(worker_id, "egg:%d" % delivered_claim_id)
	var rewarded_hen := _worker_views.get(worker_id) as ChickenView
	if rewarded_hen != null and quality in [&"sound", &"golden"]:
		rewarded_hen.play_emotion(&"golden" if quality == &"golden" else &"proud", "egg:%d" % delivered_claim_id)
	var presentation_cash_cents := int(_collection_cash_by_claim_id.get(
		delivered_claim_id,
		maxi(0, value_cents),
	))
	var stocked_for_dispatch := bool(_collection_stocked_by_claim_id.get(
		delivered_claim_id,
		false,
	))
	_collection_cash_by_claim_id.erase(delivered_claim_id)
	_collection_stocked_by_claim_id.erase(delivered_claim_id)
	var remaining_in_flight := maxi(0, int(_eggs_in_flight_by_worker.get(worker_id, 0)) - 1)
	if remaining_in_flight > 0:
		_eggs_in_flight_by_worker[worker_id] = remaining_in_flight
	else:
		_eggs_in_flight_by_worker.erase(worker_id)
	_pending_collection_cents = maxi(0, _pending_collection_cents - presentation_cash_cents)
	if _audio_feedback != null:
		_audio_feedback.play_basket_thunk(quality)
	_tween_fund_to(maxi(0, _authoritative_revenue_cents - _pending_collection_cents))
	if presentation_cash_cents > 0:
		_spawn_fund_credit_chip(presentation_cash_cents, quality)
	elif stocked_for_dispatch:
		_spawn_farmgate_stock_chip(value_cents, quality)
	if _office_atmosphere != null and _office_storytelling != null:
		_office_atmosphere.pulse_egg_laid(_office_storytelling.presentation_focus_point_global(), quality)
	var attention_receipt := _simulation.settle_peck_assist_delivery(delivered_claim_id, quality)
	var hen_name := "HEN"
	for worker in _simulation.workers:
		if worker.id == worker_id:
			hen_name = worker.display_name.to_upper()
			break
	var receipt_copy := ""
	if bool(attention_receipt.get("accepted", false)):
		_spawn_attention_refund_chip(attention_receipt, quality)
		receipt_copy = "%s · %s DELIVERED · +$%.2f FUND · +1 PECK · %d/%d READY" % [
			hen_name, String(quality).to_upper(),
			float(presentation_cash_cents) / 100.0,
			int(attention_receipt.get("charges_after", 0)),
			DepartmentSimulation.PECK_ASSIST_LIMIT,
		]
		_save_campaign_checkpoint("priority_peck_attention_refunded")
	elif stocked_for_dispatch:
		receipt_copy = "%s · %s STOCKED · $%.2f LOT · ROUTE AT REVIEW" % [
			hen_name, String(quality).to_upper(),
			float(value_cents) / 100.0,
		]
	else:
		receipt_copy = "%s · %s DELIVERED · +$%.2f FEED FUND" % [
			hen_name, String(quality).to_upper(),
			float(presentation_cash_cents) / 100.0,
		]
	if _streak_bonus_cents > 0:
		receipt_copy += " · INCLUDES $%.2f CLEAN BONUS" % (float(_streak_bonus_cents) / 100.0)
	_publish_status_copy(receipt_copy, false)
	if _workstation_feedback != null:
		_workstation_feedback.play_egg_delivery_ack(
			worker_id,
			delivered_claim_id,
			quality,
			presentation_cash_cents,
			stocked_for_dispatch,
			bool(attention_receipt.get("accepted", false)),
		)
	_update_egg_journey_receipt(
		worker_id,
		delivered_claim_id,
		{
			"stage": &"stocked" if stocked_for_dispatch else &"delivered",
			"cash_cents": presentation_cash_cents,
			"stocked": stocked_for_dispatch,
			"priority_refunded": bool(attention_receipt.get("accepted", false)),
			"charges_after": int(attention_receipt.get("charges_after", 0)),
		},
	)
	_first_clutch_record_presentation(worker_id, delivered_claim_id, quality, value_cents)
	if not _upgrade_demonstration.is_empty() and int(_upgrade_demonstration.get("claim_id", -2)) == delivered_claim_id:
		var upgrade_id := StringName(_upgrade_demonstration.get("id", ""))
		var upgrade := DepartmentSimulation.UPGRADE_DEFINITIONS.get(upgrade_id, {}) as Dictionary
		var level := int(_upgrade_demonstration.get("level", 1))
		var comparison := _upgrade_effect_comparison(upgrade_id, level)
		var kit_copy := "%s · %s" % [String(upgrade.get("short_name", "NEW KIT")), comparison]
		_publish_status_copy(kit_copy, false)
		_latest_action_outcome_receipt = {
			"visible": true, "title": kit_copy,
			"entries": [{"id": "upgrade_first_delivery", "icon": "egg", "copy": kit_copy,
				"detail": "First delivery after purchase. %s. The upgrade changes the odds or rate; it does not guarantee a clean egg." % String(upgrade.get("description", ""))}],
		}
		_upgrade_demonstration.clear()


func _upgrade_effect_comparison(upgrade_id: StringName, level: int) -> String:
	var before := maxi(0, level - 1)
	match upgrade_id:
		&"peckwork_tools": return "KIT SPEED +%d%% > +%d%%" % [before * 8, level * 8]
		&"shell_lamp": return "RISK REDUCTION %.1f > %.1f POINTS" % [before * 2.5, level * 2.5]
		&"nest_cushion": return "STRAIN REDUCTION %d%% > %d%%" % [mini(before * 10, 50), mini(level * 10, 50)]
	return "UPGRADE INSTALLED"


func _queue_collection_claim(worker_id: int, claim_id: int) -> void:
	var queue: Array = _collection_claim_ids_by_worker.get(worker_id, []) as Array
	queue.append(claim_id)
	_collection_claim_ids_by_worker[worker_id] = queue


func _take_collection_claim(worker_id: int) -> int:
	var queue: Array = _collection_claim_ids_by_worker.get(worker_id, []) as Array
	if queue.is_empty():
		return -1
	var claim_id := int(queue.pop_front())
	if queue.is_empty():
		_collection_claim_ids_by_worker.erase(worker_id)
	else:
		_collection_claim_ids_by_worker[worker_id] = queue
	return claim_id


func _peek_collection_claim(worker_id: int) -> int:
	var queue: Array = _collection_claim_ids_by_worker.get(worker_id, []) as Array
	return int(queue[0]) if not queue.is_empty() else -1


func _begin_egg_journey_receipt(
	worker_id: int,
	claim_id: int,
	quality: StringName,
	value_cents: int,
	cash_cents: int,
	priority_credit_cents: int,
) -> void:
	# Keep every in-flight egg, but only the latest settled outcome per hen. This
	# remains bounded at flock size plus physical overlap and never enters save data.
	for index in range(_egg_journey_receipts.size() - 1, -1, -1):
		var prior := _egg_journey_receipts[index]
		if (
			int(prior.get("worker_id", -1)) == worker_id
			and StringName(String(prior.get("stage", ""))) in [&"delivered", &"stocked"]
		):
			_egg_journey_receipts.remove_at(index)
	_egg_journey_receipt_serial += 1
	var refund_expected := false
	for pending_value in _simulation.peck_assist_delivery_status().get("pending_deliveries", []):
		var pending := pending_value as Dictionary
		if int(pending.get("claim_id", -2)) == claim_id:
			refund_expected = true
			break
	var worker_name := "HEN"
	for worker in _simulation.workers:
		if worker.id == worker_id:
			worker_name = worker.display_name
			break
	var stocked := bool(_collection_stocked_by_claim_id.get(claim_id, false))
	_egg_journey_receipts.append({
		"serial": _egg_journey_receipt_serial,
		"worker_id": worker_id,
		"worker_name": worker_name,
		"claim_id": claim_id,
		"stage": &"grading",
		"quality": quality,
		"value_cents": maxi(0, value_cents),
		"cash_cents": maxi(0, cash_cents),
		"stocked": stocked,
		"destination": &"farmgate" if stocked else &"farmer",
		"priority_refund_expected": refund_expected,
		"priority_refunded": false,
		"priority_credit_cents": maxi(0, priority_credit_cents),
		"charges_after": 0,
	})
	_publish_egg_journey_receipts()


func _update_egg_journey_receipt(
	worker_id: int,
	claim_id: int,
	changes: Dictionary,
) -> void:
	var receipt_index := -1
	for index in _egg_journey_receipts.size():
		var receipt := _egg_journey_receipts[index]
		if int(receipt.get("worker_id", -1)) != worker_id:
			continue
		var stage := StringName(String(receipt.get("stage", "")))
		if stage in [&"delivered", &"stocked"]:
			continue
		if claim_id < 0 or int(receipt.get("claim_id", -2)) == claim_id:
			receipt_index = index
			break
	if receipt_index < 0:
		return
	var receipt := _egg_journey_receipts[receipt_index]
	for key in changes:
		receipt[key] = changes[key]
	_egg_journey_receipts[receipt_index] = receipt
	_publish_egg_journey_receipts()


func _egg_journey_receipt_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for receipt in _egg_journey_receipts:
		result.append(receipt.duplicate(true))
	return result


func _publish_egg_journey_receipts() -> void:
	if _routing_ui != null and _routing_ui.has_method("set_egg_journey_receipts"):
		_routing_ui.set_egg_journey_receipts(_egg_journey_receipt_snapshot())


func _tween_fund_to(target_cents: int) -> void:
	var start_cents := maxi(0, _displayed_revenue_cents)
	_fund_visual_target_cents = target_cents
	var distance := absi(target_cents - start_cents)
	if distance == 0:
		_fund_counter_active = false
		_displayed_revenue_cents = target_cents
		_update_fund_label()
		return
	_fund_counter_start_cents = start_cents
	_fund_counter_duration = clampf(0.22 + distance / 8000.0, 0.22, 0.62)
	_fund_counter_elapsed = 0.0
	_fund_counter_active = true


func _process_fund_counter(delta: float) -> void:
	if not _fund_counter_active:
		return
	_fund_counter_elapsed += delta * _animation_speed_multiplier
	var progress := clampf(
		_fund_counter_elapsed / _fund_counter_duration,
		0.0,
		1.0,
	)
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	_displayed_revenue_cents = roundi(lerpf(
		float(_fund_counter_start_cents),
		float(_fund_visual_target_cents),
		eased,
	))
	_update_fund_label()
	if progress >= 1.0:
		_fund_counter_active = false
		_displayed_revenue_cents = _fund_visual_target_cents
		_update_fund_label()


func _update_fund_label() -> void:
	if _revenue_label != null:
		_update_fund_status_copy(_displayed_revenue_cents)


func _settlement_feedback_attention_state() -> Dictionary:
	var blockers: Array[Dictionary] = []
	var now_msec := Time.get_ticks_msec()
	if _blocking_management_surface_open():
		blockers.append({
			"id": "management_surface",
			"priority": "action",
			"accessible_text": "A management decision owns the reading surface.",
		})
	if _character_dialogue_ui != null and _character_dialogue_ui.is_presenting():
		blockers.append({
			"id": "character_dialogue",
			"priority": "action",
			"accessible_text": "A character moment owns the reading surface.",
		})
	if _flockwatch_open:
		blockers.append({
			"id": "flockwatch",
			"priority": "action",
			"accessible_text": "Flockwatch is open for management review.",
		})
	if (
		_ticker_panel != null
		and _ticker_panel.visible
		and not _ticker_visible_copy.is_empty()
		and now_msec < _ticker_hide_at_msec
		and _status_priority(_ticker_visible_copy) != &"routine"
	):
		blockers.append({
			"id": "status_toast",
			"priority": String(_status_priority(_ticker_visible_copy)),
			"copy": _ticker_visible_copy,
			"accessible_text": _ticker_visible_copy,
		})
	if not _routing_return_cue.is_empty() and _guidance_action_id == &"routing_chase":
		blockers.append({
			"id": "routing_return",
			"priority": "action",
			"copy": String(_routing_return_cue.get("copy", "ROUTING RECORD")),
			"accessible_text": String(_routing_return_cue.get(
				"accessible_text",
				"Choose an intake tray before reviewing routine receipts.",
			)),
		})
	if (
		not _settlement_feedback_route_handoff.is_empty()
		and String(_settlement_feedback_route_handoff.get("status", ""))
		== "awaiting_folder_landing"
	):
		blockers.append({
			"id": "routing_delivery",
			"priority": "routine",
			"copy": "ACCEPTED FOLDER CROSSING TO DESK",
			"accessible_text": (
				"The accepted folder is crossing to its desk. Consolidated routine "
				+ "receipts will follow its physical landing."
			),
		})
	if (
		_priority_peck_result_hold_worker_id >= 0
		and now_msec < _priority_peck_result_hold_until_msec
	):
		blockers.append({
			"id": "priority_peck_result",
			"priority": "milestone",
			"accessible_text": "A Priority Peck outcome is still being presented.",
		})
	var primary := {} if blockers.is_empty() else blockers[0].duplicate(true)
	return {
		"active": not blockers.is_empty(),
		"primary_id": String(primary.get("id", "")),
		"accessible_text": String(primary.get("accessible_text", "")),
		"blockers": blockers,
	}


func _settlement_feedback_safe_placement(desired_center: Vector2) -> Dictionary:
	if _ui_root == null:
		return {
			"desired_center": desired_center,
			"safe_center": desired_center,
			"clamped": false,
		}
	var root_rect := _ui_root.get_global_rect()
	var root_size := root_rect.size
	var top_boundary := 0.0
	var top_surfaces: Array[Dictionary] = []
	for surface_value in [
		{"id": "live_hud", "control": _top_hud_panel},
		{"id": "flockwatch_toggle", "control": _flockwatch_toggle},
	]:
		var surface := surface_value as Dictionary
		var control := surface.get("control") as Control
		if control == null or not control.visible:
			continue
		var local_rect := control.get_global_rect()
		local_rect.position -= root_rect.position
		top_boundary = maxf(top_boundary, local_rect.end.y)
		top_surfaces.append({
			"id": String(surface.get("id", "")),
			"rect": local_rect,
		})
	if _routing_ui != null and _routing_ui.has_method("settlement_feedback_top_rect"):
		var routing_top_rect := _routing_ui.settlement_feedback_top_rect()
		if routing_top_rect.size != Vector2.ZERO:
			routing_top_rect.position -= root_rect.position
			top_boundary = maxf(top_boundary, routing_top_rect.end.y)
			top_surfaces.append({"id": "routing_queue", "rect": routing_top_rect})
	var bottom_boundary := root_size.y
	var bottom_surface := {}
	if _routing_ui != null and _routing_ui.has_method("settlement_feedback_bottom_rect"):
		var routing_bottom_rect := _routing_ui.settlement_feedback_bottom_rect()
		if routing_bottom_rect.size != Vector2.ZERO:
			routing_bottom_rect.position -= root_rect.position
			bottom_boundary = minf(bottom_boundary, routing_bottom_rect.position.y)
			bottom_surface = {"id": "focused_dossier", "rect": routing_bottom_rect}
	var half_width := maxf(
		FUND_CREDIT_CHIP_SIZE.x,
		AUXILIARY_SETTLEMENT_CHIP_SIZE.x,
	) * 0.5
	var safe_min := Vector2(
		SETTLEMENT_FEEDBACK_EDGE_MARGIN + half_width,
		top_boundary
		+ SETTLEMENT_FEEDBACK_SURFACE_GAP
		+ SETTLEMENT_FEEDBACK_STACK_TOP_OFFSET,
	)
	var safe_max := Vector2(
		root_size.x - SETTLEMENT_FEEDBACK_EDGE_MARGIN - half_width,
		bottom_boundary
		- SETTLEMENT_FEEDBACK_SURFACE_GAP
		+ SETTLEMENT_FEEDBACK_STACK_BOTTOM_OFFSET,
	)
	# On an impossible tiny layout, collapse that axis to the available midpoint;
	# cards remain on-screen and diagnostics explicitly expose the constraint.
	var constrained_axes: Array[String] = []
	if safe_max.x < safe_min.x:
		var midpoint_x := root_size.x * 0.5
		safe_min.x = midpoint_x
		safe_max.x = midpoint_x
		constrained_axes.append("horizontal")
	if safe_max.y < safe_min.y:
		var midpoint_y := (top_boundary + bottom_boundary) * 0.5
		safe_min.y = midpoint_y
		safe_max.y = midpoint_y
		constrained_axes.append("vertical")
	var safe_center := Vector2(
		clampf(desired_center.x, safe_min.x, safe_max.x),
		clampf(desired_center.y, safe_min.y, safe_max.y),
	)
	var placement := {
		"desired_center": desired_center,
		"safe_center": safe_center,
		"clamped": not safe_center.is_equal_approx(desired_center),
		"safe_center_rect": Rect2(safe_min, safe_max - safe_min),
		"top_boundary": top_boundary,
		"bottom_boundary": bottom_boundary,
		"top_surfaces": top_surfaces,
		"bottom_surface": bottom_surface,
		"constrained_axes": constrained_axes,
		"root_size": root_size,
	}
	_last_settlement_feedback_placement = placement.duplicate(true)
	return placement


func _settlement_feedback_source_center() -> Vector2:
	if (
		not _settlement_feedback_route_handoff.is_empty()
		and String(_settlement_feedback_route_handoff.get("status", ""))
		== "folder_landed"
		and _management_camera != null
	):
		var landing_point_value: Variant = _settlement_feedback_route_handoff.get(
			"landing_world_point",
			Vector3.ZERO,
		)
		if landing_point_value is Vector3:
			return _management_camera.unproject_position(landing_point_value as Vector3)
	var presentation_point := (
		_office_storytelling.presentation_focus_point_global()
		if _office_storytelling != null else Vector3(9.4, 1.25, -6.85)
	)
	return _management_camera.unproject_position(presentation_point)


func _configure_fund_credit_chip_path(visual: FundCreditChipVisual) -> void:
	var desired_source_center := _settlement_feedback_source_center()
	var placement := _settlement_feedback_safe_placement(desired_source_center)
	var safe_source_center: Vector2 = placement.get("safe_center", desired_source_center)
	var chip_half_size := FUND_CREDIT_CHIP_SIZE * 0.5
	visual.desired_source_center = desired_source_center
	visual.safe_source_center = safe_source_center
	visual.placement_clamped = bool(placement.get("clamped", false))
	visual.start_position = safe_source_center - chip_half_size
	visual.rise_position = safe_source_center - chip_half_size - Vector2(0.0, 36.0)
	visual.target_position = (
		_settlement_destination_target_center(&"fund")
		- chip_half_size
	)


func _configure_auxiliary_settlement_chip_path(
	visual: AuxiliarySettlementChipVisual,
) -> void:
	var desired_source_center := _settlement_feedback_source_center()
	var placement := _settlement_feedback_safe_placement(desired_source_center)
	var safe_source_center: Vector2 = placement.get("safe_center", desired_source_center)
	var chip_half_size := AUXILIARY_SETTLEMENT_CHIP_SIZE * 0.5
	var lane_offset := 86.0 if visual.kind == &"refund" else 42.0
	visual.desired_source_center = desired_source_center
	visual.safe_source_center = safe_source_center
	visual.placement_clamped = bool(placement.get("clamped", false))
	visual.start_position = safe_source_center - chip_half_size - Vector2(0.0, lane_offset)
	visual.rise_position = visual.start_position - Vector2(0.0, 36.0)
	visual.target_position = (
		_settlement_destination_target_center(visual.kind)
		- chip_half_size
	)


func _settlement_destination_target(kind: StringName) -> Control:
	match kind:
		&"fund":
			return _revenue_label
		&"stock":
			return _flockwatch_toggle if _flockwatch_toggle != null else _today_clutch_label
		&"refund":
			if (
				_routing_ui != null
				and _routing_ui.has_method("settlement_feedback_peck_target")
			):
				var peck_target := _routing_ui.call("settlement_feedback_peck_target") as Control
				if peck_target != null:
					return peck_target
			return _flockwatch_toggle if _flockwatch_toggle != null else _guidance_label
	return _guidance_label


func _settlement_destination_target_id(kind: StringName, target: Control) -> StringName:
	if kind == &"fund":
		return &"feed_fund_counter"
	if kind == &"stock":
		return &"flockwatch_inventory_ledger"
	if (
		kind == &"refund"
		and target != null
		and String(target.name) == "PriorityPeckChargeMeter"
	):
		return &"priority_peck_meter"
	return &"flockwatch_resource_ledger"


func _settlement_destination_target_rect(kind: StringName) -> Rect2:
	var target := _settlement_destination_target(kind)
	if target == null or _ui_root == null:
		return Rect2()
	var target_rect := target.get_global_rect()
	target_rect.position -= _ui_root.get_global_rect().position
	return target_rect


func _settlement_destination_target_center(kind: StringName) -> Vector2:
	var target_rect := _settlement_destination_target_rect(kind)
	if target_rect.size != Vector2.ZERO:
		return target_rect.get_center()
	return _ui_root.get_global_rect().size * 0.5 if _ui_root != null else Vector2.ZERO


func _play_settlement_destination_ack(
	kind: StringName,
	item_count: int,
	value_cents: int,
	charges_after: int,
	release_serial: int,
) -> bool:
	var visual := _settlement_destination_ack_by_kind.get(kind) as SettlementDestinationAckVisual
	var target := _settlement_destination_target(kind)
	if visual == null or visual.panel == null or target == null or _ui_root == null:
		return false
	var merged := visual.active
	if visual.tween != null and visual.tween.is_valid():
		visual.tween.kill()
	if merged:
		_settlement_destination_ack_merged_total += 1
		visual.merge_count += 1
	else:
		visual.merge_count = 0
	visual.active = true
	visual.capture_staged = false
	if merged:
		visual.item_count += maxi(1, item_count)
		visual.value_cents += maxi(0, value_cents)
		visual.charges_after = maxi(visual.charges_after, charges_after)
		visual.release_serial = maxi(visual.release_serial, release_serial)
	else:
		visual.item_count = maxi(1, item_count)
		visual.value_cents = maxi(0, value_cents)
		visual.charges_after = maxi(0, charges_after)
		visual.release_serial = maxi(0, release_serial)
	_settlement_destination_ack_serial += 1
	_settlement_destination_ack_total += 1
	visual.serial = _settlement_destination_ack_serial
	visual.target_id = _settlement_destination_target_id(kind, target)
	visual.target_name = String(target.name)
	visual.target_rect = _settlement_destination_target_rect(kind).grow(
		SETTLEMENT_DESTINATION_ACK_MARGIN
	)
	visual.accessible_text = _settlement_destination_accessible_text(visual)
	var panel := visual.panel
	panel.position = visual.target_rect.position
	panel.size = visual.target_rect.size
	panel.pivot_offset = panel.size * 0.5
	panel.add_theme_stylebox_override("panel", _settlement_destination_ack_styles[kind])
	panel.set_meta("kind", kind)
	panel.set_meta("serial", visual.serial)
	panel.set_meta("target_id", visual.target_id)
	panel.set_meta("accessible_text", visual.accessible_text)
	panel.visible = true
	panel.modulate = Color.WHITE
	var reduced_motion := _prefers_reduced_motion()
	panel.scale = Vector2.ONE if reduced_motion else Vector2(0.84, 0.84)
	var receipt := _settlement_destination_ack_receipt(visual, reduced_motion)
	_settlement_destination_ack_last_by_kind[String(kind)] = receipt
	_record_completed_settlement_destination_handoff(release_serial)
	var tween := _presentation_tween(panel)
	visual.tween = tween
	if reduced_motion:
		tween.tween_interval(
			SETTLEMENT_DESTINATION_ACK_IN_SECONDS
			+ SETTLEMENT_DESTINATION_ACK_HOLD_SECONDS
		)
		tween.tween_property(
			panel,
			"modulate:a",
			0.0,
			SETTLEMENT_DESTINATION_ACK_OUT_SECONDS,
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(
			panel,
			"scale",
			Vector2.ONE,
			SETTLEMENT_DESTINATION_ACK_IN_SECONDS,
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(
			panel,
			"modulate:a",
			1.0,
			SETTLEMENT_DESTINATION_ACK_IN_SECONDS,
		)
		tween.tween_interval(SETTLEMENT_DESTINATION_ACK_HOLD_SECONDS)
		tween.tween_property(
			panel,
			"scale",
			Vector2(1.06, 1.06),
			SETTLEMENT_DESTINATION_ACK_OUT_SECONDS,
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(
			panel,
			"modulate:a",
			0.0,
			SETTLEMENT_DESTINATION_ACK_OUT_SECONDS,
		)
	tween.tween_callback(
		_finish_settlement_destination_ack.bind(visual, visual.serial)
	)
	return true


func _record_completed_settlement_destination_handoff(release_serial: int) -> void:
	if (
		release_serial <= 0
		or int(_settlement_feedback_last_release.get("serial", 0)) != release_serial
	):
		return
	var acknowledged: Array[String] = []
	for kind in [&"fund", &"stock", &"refund"]:
		var receipt := _settlement_destination_ack_last_by_kind.get(
			String(kind),
			{},
		) as Dictionary
		if int(receipt.get("release_serial", 0)) == release_serial:
			acknowledged.append(String(receipt.get("target_id", "")))
	if acknowledged.size() != 3:
		return
	_settlement_feedback_last_release["destination_status"] = "acknowledged"
	_settlement_feedback_last_release["destination_acknowledgment_count"] = 3
	_settlement_feedback_last_release["acknowledged_destination_ids"] = acknowledged
	_settlement_feedback_last_release["completed_causal_path"] = (
		"%s>destination_surfaces"
		% String(_settlement_feedback_last_release.get(
			"causal_path",
			"settlement>receipt_fan",
		))
	)


func _settlement_destination_accessible_text(
	visual: SettlementDestinationAckVisual,
) -> String:
	match visual.kind:
		&"fund":
			return "Feed Fund counter acknowledged %d eggs worth $%.2f." % [
				visual.item_count,
				float(visual.value_cents) / 100.0,
			]
		&"stock":
			return "Flockwatch inventory acknowledged %d stored eggs worth $%.2f." % [
				visual.item_count,
				float(visual.value_cents) / 100.0,
			]
		&"refund":
			return "Priority Peck meter acknowledged %d restored charges; %d of %d are ready." % [
				visual.item_count,
				visual.charges_after,
				DepartmentSimulation.PECK_ASSIST_LIMIT,
			]
	return "Settlement destination acknowledged."


func _settlement_destination_ack_receipt(
	visual: SettlementDestinationAckVisual,
	reduced_motion: bool,
) -> Dictionary:
	return {
		"serial": visual.serial,
		"kind": String(visual.kind),
		"target_id": String(visual.target_id),
		"target_name": visual.target_name,
		"target_rect": visual.target_rect,
		"item_count": visual.item_count,
		"value_cents": visual.value_cents,
		"charges_after": visual.charges_after,
		"release_serial": visual.release_serial,
		"merge_count": visual.merge_count,
		"active": visual.active,
		"animated": not reduced_motion,
		"reduced_motion": reduced_motion,
		"capture_staged": visual.capture_staged,
		"symbol": visual.glyph.text if visual.glyph != null else "",
		"motion": "target_outline_pulse",
		"causal_path": "receipt_card>%s" % String(visual.target_id),
		"accessible_text": visual.accessible_text,
	}


func _finish_settlement_destination_ack(
	visual: SettlementDestinationAckVisual,
	serial: int,
) -> void:
	if visual == null or visual.serial != serial or visual.capture_staged:
		return
	visual.active = false
	visual.tween = null
	if visual.panel != null and is_instance_valid(visual.panel):
		visual.panel.visible = false
		visual.panel.modulate = Color.WHITE
		visual.panel.scale = Vector2.ONE
	var receipt := _settlement_destination_ack_last_by_kind.get(
		String(visual.kind),
		{},
	) as Dictionary
	if int(receipt.get("serial", -1)) == serial:
		receipt["active"] = false
		receipt["status"] = "settled"
		_settlement_destination_ack_last_by_kind[String(visual.kind)] = receipt


func stage_settlement_destination_ack_capture() -> int:
	var staged := 0
	for visual in _settlement_destination_ack_pool:
		if not visual.active or visual.panel == null:
			continue
		if visual.tween != null and visual.tween.is_valid():
			visual.tween.kill()
		visual.tween = null
		visual.capture_staged = true
		visual.panel.scale = Vector2.ONE
		visual.panel.modulate = Color.WHITE
		visual.panel.visible = true
		var receipt := _settlement_destination_ack_receipt(
			visual,
			_prefers_reduced_motion(),
		)
		_settlement_destination_ack_last_by_kind[String(visual.kind)] = receipt
		staged += 1
	return staged


func _fund_debit_control_center(control: Control) -> Vector2:
	if control == null or _ui_root == null:
		return Vector2.ZERO
	var rect := control.get_global_rect()
	return rect.get_center() - _ui_root.get_global_rect().position


func _fund_debit_target(preferred: Control) -> Control:
	if (
		preferred != null
		and is_instance_valid(preferred)
		and preferred.is_visible_in_tree()
		and preferred.get_global_rect().size != Vector2.ZERO
		and _fund_debit_control_is_actually_visible(preferred)
	):
		return preferred
	if (
		_flockwatch_toggle != null
		and _flockwatch_toggle.is_visible_in_tree()
		and _flockwatch_toggle.get_global_rect().size != Vector2.ZERO
	):
		return _flockwatch_toggle
	return preferred


func _fund_debit_control_is_actually_visible(control: Control) -> bool:
	if control == null or _ui_root == null:
		return false
	var center := control.get_global_rect().get_center()
	if not _ui_root.get_global_rect().grow(1.0).has_point(center):
		return false
	var ancestor := control.get_parent()
	while ancestor != null and ancestor != _ui_root:
		if (
			ancestor is ScrollContainer
			and not (ancestor as ScrollContainer).get_global_rect().grow(1.0).has_point(center)
		):
			return false
		ancestor = ancestor.get_parent()
	return true


func _acquire_fund_debit_chip(target_id: StringName) -> FundDebitChipVisual:
	for visual in _fund_debit_chip_pool:
		if visual.active and visual.target_id == target_id:
			_fund_debit_merged_total += 1
			visual.merge_count += 1
			return visual
	for visual in _fund_debit_chip_pool:
		if not visual.active:
			visual.merge_count = 0
			return visual
	var oldest: FundDebitChipVisual = null
	for visual in _fund_debit_chip_pool:
		if oldest == null or visual.serial < oldest.serial:
			oldest = visual
	if oldest != null:
		_fund_debit_recycled_total += 1
		oldest.merge_count = 0
	return oldest


func _play_fund_debit_feedback(
	cost_cents: int,
	transaction_kind: StringName,
	target_id: StringName,
	preferred_target: Control,
) -> bool:
	var target := _fund_debit_target(preferred_target)
	if (
		cost_cents <= 0
		or _ui_root == null
		or _revenue_label == null
		or target == null
	):
		return false
	var visual := _acquire_fund_debit_chip(target_id)
	if visual == null or visual.panel == null:
		return false
	var merged := visual.active and visual.target_id == target_id
	if visual.tween != null and visual.tween.is_valid():
		visual.tween.kill()
	visual.active = true
	visual.capture_staged = false
	visual.cost_cents = visual.cost_cents + cost_cents if merged else cost_cents
	visual.transaction_kind = transaction_kind
	visual.target_id = target_id
	visual.target_name = String(target.name)
	visual.source_center = _fund_debit_control_center(_revenue_label)
	visual.target_center = _fund_debit_control_center(target)
	visual.accessible_text = "$%.2f left the Feed Fund for %s." % [
		float(visual.cost_cents) / 100.0,
		String(target_id).replace("_", " "),
	]
	_fund_debit_serial += 1
	_fund_debit_started_total += 1
	visual.serial = _fund_debit_serial
	visual.label.text = "-$%.2f  >" % (float(visual.cost_cents) / 100.0)
	var panel := visual.panel
	panel.set_meta("transaction_kind", transaction_kind)
	panel.set_meta("target_id", target_id)
	panel.set_meta("accessible_text", visual.accessible_text)
	panel.size = FUND_DEBIT_CHIP_SIZE
	panel.pivot_offset = FUND_DEBIT_CHIP_SIZE * 0.5
	panel.modulate = Color.WHITE
	panel.visible = true
	var start_position := visual.source_center - FUND_DEBIT_CHIP_SIZE * 0.5
	var target_position := visual.target_center - FUND_DEBIT_CHIP_SIZE * 0.5
	var reduced_motion := _prefers_reduced_motion()
	panel.position = target_position if reduced_motion else start_position
	panel.scale = Vector2.ONE if reduced_motion else Vector2(0.82, 0.82)
	_fund_debit_last_receipt = _fund_debit_receipt(visual, reduced_motion)
	var tween := _presentation_tween(panel)
	visual.tween = tween
	if reduced_motion:
		panel.modulate.a = 0.0
		tween.tween_property(panel, "modulate:a", 1.0, FUND_DEBIT_LIFT_SECONDS)
		tween.tween_interval(FUND_DEBIT_HOLD_SECONDS + FUND_DEBIT_TRAVEL_SECONDS)
	else:
		var midpoint := start_position.lerp(target_position, 0.34) + Vector2(0.0, -18.0)
		tween.tween_property(
			panel,
			"position",
			midpoint,
			FUND_DEBIT_LIFT_SECONDS,
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(
			panel,
			"scale",
			Vector2(0.92, 0.92),
			FUND_DEBIT_LIFT_SECONDS,
		)
		tween.tween_property(
			panel,
			"position",
			target_position,
			FUND_DEBIT_TRAVEL_SECONDS,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(
			panel,
			"scale",
			Vector2(1.05, 1.05),
			FUND_DEBIT_TRAVEL_SECONDS,
		)
		tween.tween_property(panel, "scale", Vector2.ONE, FUND_DEBIT_HOLD_SECONDS)
	tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		FUND_DEBIT_FADE_SECONDS,
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish_fund_debit_feedback.bind(visual, visual.serial))
	return true


func _play_fund_debit_from_result(
	result: Dictionary,
	transaction_kind: StringName,
	target_id: StringName,
	preferred_target: Control,
) -> bool:
	if not bool(result.get("accepted", false)):
		return false
	var cost_cents := 0
	for field in [
		"net_cost_cents",
		"total_cost_cents",
		"cost_cents",
		"capital_cost_cents",
	]:
		if result.has(field):
			cost_cents = maxi(0, int(result.get(field, 0)))
			break
	return _play_fund_debit_feedback(
		cost_cents,
		transaction_kind,
		target_id,
		preferred_target,
	)


func _fund_debit_receipt(
	visual: FundDebitChipVisual,
	reduced_motion: bool,
) -> Dictionary:
	return {
		"serial": visual.serial,
		"pool_index": visual.pool_index,
		"active": visual.active,
		"cost_cents": visual.cost_cents,
		"transaction_kind": String(visual.transaction_kind),
		"source_id": "feed_fund_counter",
		"target_id": String(visual.target_id),
		"target_name": visual.target_name,
		"source_center": visual.source_center,
		"target_center": visual.target_center,
		"merge_count": visual.merge_count,
		"capture_staged": visual.capture_staged,
		"animated": not reduced_motion,
		"reduced_motion": reduced_motion,
		"symbol": visual.label.text if visual.label != null else "",
		"motion": "counter_to_purchase" if not reduced_motion else "destination_pulse",
		"shape": "clipped_debit_docket",
		"audio_cue_owned": false,
		"accessible_text": visual.accessible_text,
	}


func _finish_fund_debit_feedback(
	visual: FundDebitChipVisual,
	serial: int,
) -> void:
	if visual == null or visual.serial != serial or visual.capture_staged:
		return
	visual.active = false
	visual.tween = null
	if visual.panel != null and is_instance_valid(visual.panel):
		visual.panel.visible = false
		visual.panel.modulate = Color.WHITE
		visual.panel.scale = Vector2.ONE
	if int(_fund_debit_last_receipt.get("serial", -1)) == serial:
		_fund_debit_last_receipt["active"] = false
		_fund_debit_last_receipt["status"] = "settled"


func stage_fund_debit_feedback_capture() -> bool:
	for visual in _fund_debit_chip_pool:
		if not visual.active or visual.panel == null:
			continue
		if visual.tween != null and visual.tween.is_valid():
			visual.tween.kill()
		visual.tween = null
		visual.capture_staged = true
		visual.panel.position = (
			visual.source_center.lerp(visual.target_center, 0.62)
			- FUND_DEBIT_CHIP_SIZE * 0.5
		)
		visual.panel.scale = Vector2.ONE
		visual.panel.modulate = Color.WHITE
		visual.panel.visible = true
		_fund_debit_last_receipt = _fund_debit_receipt(
			visual,
			_prefers_reduced_motion(),
		)
		return true
	return false


func _spawn_fund_credit_chip(value_cents: int, quality: StringName) -> void:
	if _ui_root == null or _revenue_label == null or _management_camera == null:
		_on_fund_credit_chip_arrived(value_cents, quality)
		return
	var merge_target := _mergeable_fund_credit_chip()
	if merge_target != null:
		merge_target.value_cents += maxi(0, value_cents)
		merge_target.egg_count += 1
		var quality_key := String(quality)
		merge_target.quality_counts[quality_key] = int(
			merge_target.quality_counts.get(quality_key, 0)
		) + 1
		merge_target.quality = _fund_credit_batch_quality(merge_target.quality_counts)
		_update_fund_credit_chip_copy(merge_target)
		return
	var visual := _acquire_fund_credit_chip()
	if visual == null:
		_on_fund_credit_chip_arrived(value_cents, quality)
		return
	var chip := visual.panel
	var chip_half_size := FUND_CREDIT_CHIP_SIZE * 0.5
	_configure_fund_credit_chip_path(visual)
	visual.value_cents = maxi(0, value_cents)
	visual.quality = quality
	visual.quality_counts = {String(quality): 1}
	visual.egg_count = 1
	visual.elapsed = 0.0
	visual.capture_staged = false
	visual.deferred_elapsed = 0.0
	visual.released_after_defer = false
	visual.release_serial = 0
	var attention_state := _settlement_feedback_attention_state()
	visual.deferred = bool(attention_state.get("active", false))
	visual.deferred_reason = StringName(String(attention_state.get("primary_id", "")))
	if visual.deferred:
		_settlement_feedback_deferred_total += 1
	_fund_credit_batch_serial += 1
	chip.set_meta("batch_serial", _fund_credit_batch_serial)
	chip.set_meta("capture_staged", false)
	_update_fund_credit_chip_copy(visual)
	chip.position = visual.rise_position if _prefers_reduced_motion() else visual.start_position
	chip.pivot_offset = chip_half_size
	chip.scale = Vector2.ONE if _prefers_reduced_motion() else Vector2(0.78, 0.78)
	chip.modulate = Color.WHITE
	chip.visible = not visual.deferred


func _mergeable_fund_credit_chip() -> FundCreditChipVisual:
	for active_index in range(_active_fund_credit_chips.size() - 1, -1, -1):
		var visual := _active_fund_credit_chips[active_index]
		if (
			visual.active
			and not visual.capture_staged
			and visual.elapsed <= FUND_CREDIT_CHIP_MERGE_SECONDS
		):
			return visual
	return null


func _fund_credit_batch_quality(quality_counts: Dictionary) -> StringName:
	if quality_counts.size() != 1:
		return &"mixed"
	return StringName(String(quality_counts.keys()[0]))


func _update_fund_credit_chip_copy(visual: FundCreditChipVisual) -> void:
	if visual == null or visual.panel == null or visual.label == null:
		return
	var accent := Color("8fd1a1")
	match visual.quality:
		&"golden":
			accent = Color("f1c75f")
		&"cracked":
			accent = Color("d98a72")
		&"mixed":
			accent = Color("b9d9ee")
	var dense_layout := float(_player_preferences.get("ui_scale", 1.0)) >= 1.25
	visual.label.text = (
		"+$%.2f  >  FUND" % (visual.value_cents / 100.0)
		if visual.egg_count <= 1 else
		"x%d  |  +$%.2f  >  FUND" % [
			visual.egg_count,
			visual.value_cents / 100.0,
		]
		if dense_layout else
		"x%d EGGS  |  +$%.2f  >  FUND" % [
			visual.egg_count,
			visual.value_cents / 100.0,
		]
	)
	visual.label.add_theme_color_override("font_color", accent)
	var accessible_text := (
		"One egg added $%.2f to the Feed Fund." % (visual.value_cents / 100.0)
		if visual.egg_count <= 1 else
		"%d eggs added $%.2f total to the Feed Fund." % [
			visual.egg_count,
			visual.value_cents / 100.0,
		]
	)
	visual.panel.set_meta("egg_count", visual.egg_count)
	visual.panel.set_meta("value_cents", visual.value_cents)
	visual.panel.set_meta("quality", visual.quality)
	visual.panel.set_meta("quality_counts", visual.quality_counts.duplicate(true))
	visual.panel.set_meta("accessible_text", accessible_text)
	visual.label.tooltip_text = accessible_text


func stage_fund_credit_batch_capture() -> bool:
	if _active_fund_credit_chips.is_empty():
		return false
	var visual: FundCreditChipVisual = _active_fund_credit_chips.back()
	if visual == null or not visual.active:
		return false
	visual.elapsed = FUND_CREDIT_CHIP_RISE_SECONDS
	visual.capture_staged = true
	if visual.deferred:
		visual.panel.visible = false
	else:
		visual.panel.position = visual.rise_position
		visual.panel.scale = Vector2.ONE
		visual.panel.modulate = Color.WHITE
		visual.panel.visible = true
	visual.panel.set_meta("capture_staged", true)
	return true


func _acquire_fund_credit_chip() -> FundCreditChipVisual:
	var selected: FundCreditChipVisual
	for visual in _fund_credit_chip_pool:
		if visual.active:
			continue
		selected = visual
		break
	if selected == null:
		if _active_fund_credit_chips.is_empty():
			return null
		selected = _active_fund_credit_chips[0]
		for visual in _active_fund_credit_chips:
			if visual.elapsed > selected.elapsed:
				selected = visual
		# Preserve the semantic payout confirmation if an impossible burst
		# exceeds the bounded presentation capacity.
		_on_fund_credit_chip_arrived(
			selected.value_cents,
			selected.quality,
			false,
			selected.egg_count,
			selected.release_serial,
		)
	else:
		selected.active = true
		_active_fund_credit_chips.append(selected)
	var exact_name_available := _ui_root.find_child(
		"FundCreditChip",
		false,
		false,
	) == null
	selected.panel.name = (
		"FundCreditChip"
		if exact_name_available else
		"FundCreditChipActive_%02d" % selected.pool_index
	)
	return selected


func _process_fund_credit_chip_pool(delta: float) -> void:
	if _active_fund_credit_chips.is_empty():
		return
	_release_deferred_settlement_feedback_if_ready()
	var scaled_delta := delta * _animation_speed_multiplier
	var total_duration := FUND_CREDIT_CHIP_RISE_SECONDS + FUND_CREDIT_CHIP_TRAVEL_SECONDS
	for active_index in range(_active_fund_credit_chips.size() - 1, -1, -1):
		var visual := _active_fund_credit_chips[active_index]
		if visual.panel == null or not is_instance_valid(visual.panel):
			visual.active = false
			_active_fund_credit_chips.remove_at(active_index)
			continue
		if visual.deferred:
			visual.panel.visible = false
			if visual.capture_staged:
				continue
			visual.deferred_elapsed += maxf(0.0, delta)
			var attention_state := _settlement_feedback_attention_state()
			if bool(attention_state.get("active", false)):
				if visual.deferred_elapsed < SETTLEMENT_FEEDBACK_MAX_DEFER_SECONDS:
					continue
				_record_settlement_feedback_suppression(
					&"fund",
					visual.egg_count,
					visual.value_cents,
					String(visual.panel.get_meta("accessible_text", "")),
					visual.deferred_reason,
				)
				visual.active = false
				visual.deferred = false
				visual.panel.name = "FundCreditChipPool_%02d" % visual.pool_index
				_active_fund_credit_chips.remove_at(active_index)
				continue
			continue
		if visual.capture_staged:
			continue
		visual.elapsed += scaled_delta
		if _prefers_reduced_motion():
			visual.panel.position = visual.rise_position
			visual.panel.scale = Vector2.ONE
			visual.panel.modulate = Color.WHITE
		elif visual.elapsed < FUND_CREDIT_CHIP_RISE_SECONDS:
			var rise_progress := clampf(
				visual.elapsed / FUND_CREDIT_CHIP_RISE_SECONDS,
				0.0,
				1.0,
			)
			var rise_eased := (
				_ease_cubic_in_out(rise_progress)
				if visual.released_after_defer else
				_ease_back_out(rise_progress)
			)
			var entry_scale := Vector2(0.88, 0.88) if visual.released_after_defer else Vector2(0.78, 0.78)
			visual.panel.position = visual.start_position.lerp(
				visual.rise_position,
				rise_eased,
			)
			visual.panel.scale = entry_scale.lerp(Vector2.ONE, rise_eased)
		else:
			var travel_elapsed := visual.elapsed - FUND_CREDIT_CHIP_RISE_SECONDS
			var travel_progress := clampf(
				travel_elapsed / FUND_CREDIT_CHIP_TRAVEL_SECONDS,
				0.0,
				1.0,
			)
			visual.panel.position = visual.rise_position.lerp(
				visual.target_position,
				_ease_cubic_in_out(travel_progress),
			)
			visual.panel.scale = Vector2.ONE
			var fade_progress := clampf(
				(travel_elapsed - 0.26) / 0.28,
				0.0,
				1.0,
			)
			visual.panel.modulate.a = lerpf(
				1.0,
				0.15,
				_ease_cubic_in_out(fade_progress),
			)
		if visual.elapsed < total_duration:
			continue
		_on_fund_credit_chip_arrived(
			visual.value_cents,
			visual.quality,
			visual.released_after_defer,
			visual.egg_count,
			visual.release_serial,
		)
		visual.active = false
		visual.panel.visible = false
		visual.panel.modulate = Color.WHITE
		visual.panel.name = "FundCreditChipPool_%02d" % visual.pool_index
		visual.capture_staged = false
		visual.panel.set_meta("capture_staged", false)
		_active_fund_credit_chips.remove_at(active_index)


func _ease_back_out(value: float) -> float:
	var shifted := value - 1.0
	return 1.0 + 2.70158 * shifted * shifted * shifted + 1.70158 * shifted * shifted


func _ease_cubic_in_out(value: float) -> float:
	if value < 0.5:
		return 4.0 * value * value * value
	return 1.0 - pow(-2.0 * value + 2.0, 3.0) * 0.5


func _spawn_farmgate_stock_chip(value_cents: int, quality: StringName) -> void:
	_spawn_auxiliary_settlement_chip(&"stock", value_cents, quality, {})


func _spawn_attention_refund_chip(receipt: Dictionary, quality: StringName) -> void:
	_spawn_auxiliary_settlement_chip(&"refund", 0, quality, receipt)


func _spawn_auxiliary_settlement_chip(
	kind: StringName,
	value_cents: int,
	quality: StringName,
	receipt: Dictionary,
) -> void:
	if (
		_ui_root == null
		or _management_camera == null
		or (kind == &"refund" and _guidance_label == null)
	):
		if kind == &"refund" and _audio_feedback != null:
			_audio_feedback.play_attention_restored()
		return
	var merge_target := _mergeable_auxiliary_settlement_chip(kind)
	if merge_target != null:
		merge_target.item_count += 1
		merge_target.value_cents += maxi(0, value_cents)
		merge_target.charges_after = maxi(
			merge_target.charges_after,
			int(receipt.get("charges_after", 0)),
		)
		var quality_key := String(quality)
		merge_target.quality_counts[quality_key] = int(
			merge_target.quality_counts.get(quality_key, 0)
		) + 1
		merge_target.quality = _fund_credit_batch_quality(merge_target.quality_counts)
		_update_auxiliary_settlement_chip_copy(merge_target)
		return
	var visual := _acquire_auxiliary_settlement_chip()
	if visual == null:
		if kind == &"refund" and _audio_feedback != null:
			_audio_feedback.play_attention_restored()
		return
	visual.kind = kind
	visual.value_cents = maxi(0, value_cents)
	visual.item_count = 1
	visual.charges_after = int(receipt.get("charges_after", 0))
	visual.quality = quality
	visual.quality_counts = {String(quality): 1}
	visual.elapsed = 0.0
	visual.capture_staged = false
	visual.deferred_elapsed = 0.0
	visual.released_after_defer = false
	visual.release_serial = 0
	var attention_state := _settlement_feedback_attention_state()
	visual.deferred = bool(attention_state.get("active", false))
	visual.deferred_reason = StringName(String(attention_state.get("primary_id", "")))
	if visual.deferred:
		_settlement_feedback_deferred_total += 1
	_auxiliary_settlement_batch_serial += 1
	var chip := visual.panel
	chip.add_theme_stylebox_override(
		"panel",
		_refund_chip_style if kind == &"refund" else _stock_chip_style,
	)
	chip.name = _available_auxiliary_settlement_chip_name(kind, visual.pool_index)
	chip.set_meta("batch_serial", _auxiliary_settlement_batch_serial)
	chip.set_meta("capture_staged", false)
	var chip_half_size := AUXILIARY_SETTLEMENT_CHIP_SIZE * 0.5
	_configure_auxiliary_settlement_chip_path(visual)
	_update_auxiliary_settlement_chip_copy(visual)
	chip.position = visual.rise_position if _prefers_reduced_motion() else visual.start_position
	chip.pivot_offset = chip_half_size
	chip.scale = Vector2.ONE if _prefers_reduced_motion() else Vector2(0.74, 0.74)
	chip.modulate = Color.WHITE
	chip.visible = not visual.deferred


func _mergeable_auxiliary_settlement_chip(
	kind: StringName,
) -> AuxiliarySettlementChipVisual:
	for active_index in range(_active_auxiliary_settlement_chips.size() - 1, -1, -1):
		var visual := _active_auxiliary_settlement_chips[active_index]
		if (
			visual.active
			and visual.kind == kind
			and not visual.capture_staged
			and visual.elapsed <= AUXILIARY_SETTLEMENT_CHIP_MERGE_SECONDS
		):
			return visual
	return null


func _acquire_auxiliary_settlement_chip() -> AuxiliarySettlementChipVisual:
	var selected: AuxiliarySettlementChipVisual
	for visual in _auxiliary_settlement_chip_pool:
		if visual.active:
			continue
		selected = visual
		break
	if selected == null:
		if _active_auxiliary_settlement_chips.is_empty():
			return null
		selected = _active_auxiliary_settlement_chips[0]
		for visual in _active_auxiliary_settlement_chips:
			if visual.elapsed > selected.elapsed:
				selected = visual
		_on_auxiliary_settlement_chip_arrived(selected)
	else:
		selected.active = true
		_active_auxiliary_settlement_chips.append(selected)
	return selected


func _available_auxiliary_settlement_chip_name(kind: StringName, pool_index: int) -> String:
	var exact_name := "PriorityPeckRefundChip" if kind == &"refund" else "FarmgateStockChip"
	if _ui_root.find_child(exact_name, false, false) == null:
		return exact_name
	return "%sActive_%02d" % [exact_name, pool_index]


func _update_auxiliary_settlement_chip_copy(
	visual: AuxiliarySettlementChipVisual,
) -> void:
	if visual == null or visual.panel == null or visual.label == null:
		return
	var accent := Color("8fd2c1")
	if visual.kind == &"refund":
		accent = Color("f4d471") if visual.quality == &"golden" else Color("91d4b2")
	elif visual.quality == &"golden":
		accent = Color("f1c75f")
	elif visual.quality == &"mixed":
		accent = Color("b9d9ee")
	var dense_layout := float(_player_preferences.get("ui_scale", 1.0)) >= 1.25
	if visual.kind == &"refund":
		visual.label.text = (
			"+1 PECK  |  %d/%d READY" % [
				visual.charges_after, DepartmentSimulation.PECK_ASSIST_LIMIT,
			]
			if visual.item_count <= 1 else
			"+%d PECKS  |  %d/%d" % [
				visual.item_count,
				visual.charges_after,
				DepartmentSimulation.PECK_ASSIST_LIMIT,
			]
			if dense_layout else
			"+%d PECKS  |  %d/%d READY" % [
				visual.item_count,
				visual.charges_after,
				DepartmentSimulation.PECK_ASSIST_LIMIT,
			]
		)
	else:
		visual.label.text = (
			"+1 LOT  |  $%.2f  >  STORE" % (visual.value_cents / 100.0)
			if visual.item_count <= 1 else
			"x%d  |  $%.2f  >  STORE" % [
				visual.item_count,
				visual.value_cents / 100.0,
			]
			if dense_layout else
			"x%d LOTS  |  $%.2f  >  STORE" % [
				visual.item_count,
				visual.value_cents / 100.0,
			]
		)
	visual.label.add_theme_color_override("font_color", accent)
	var accessible_text := (
		"%d Priority Pecks restored; %d of %d charges are ready." % [
			visual.item_count,
			visual.charges_after,
			DepartmentSimulation.PECK_ASSIST_LIMIT,
		]
		if visual.kind == &"refund" else
		"%d eggs added to cold storage, worth $%.2f total." % [
			visual.item_count,
			visual.value_cents / 100.0,
		]
	)
	visual.panel.set_meta("kind", visual.kind)
	visual.panel.set_meta("item_count", visual.item_count)
	visual.panel.set_meta("value_cents", visual.value_cents)
	visual.panel.set_meta("charges_after", visual.charges_after)
	visual.panel.set_meta("quality", visual.quality)
	visual.panel.set_meta("quality_counts", visual.quality_counts.duplicate(true))
	visual.panel.set_meta("accessible_text", accessible_text)
	visual.label.tooltip_text = accessible_text


func _release_deferred_settlement_feedback_if_ready() -> bool:
	_expire_route_settlement_handoff_if_needed()
	if bool(_settlement_feedback_attention_state().get("active", false)):
		return false
	var fund_batches: Array[FundCreditChipVisual] = []
	var auxiliary_batches: Array[AuxiliarySettlementChipVisual] = []
	var item_count := 0
	var total_value_cents := 0
	var pecks_restored := 0
	for visual in _active_fund_credit_chips:
		if visual.active and visual.deferred:
			fund_batches.append(visual)
			item_count += visual.egg_count
			total_value_cents += visual.value_cents
	for visual in _active_auxiliary_settlement_chips:
		if not visual.active or not visual.deferred:
			continue
		auxiliary_batches.append(visual)
		if visual.kind == &"refund":
			pecks_restored += visual.item_count
		else:
			item_count += visual.item_count
			total_value_cents += visual.value_cents
	var batch_count := fund_batches.size() + auxiliary_batches.size()
	if batch_count <= 0:
		return false
	var route_linked := (
		not _settlement_feedback_route_handoff.is_empty()
		and String(_settlement_feedback_route_handoff.get("status", "")) == "folder_landed"
	)
	var source_kind := "dispatch_landing" if route_linked else "presentation_counter"
	var source_worker_id := int(_settlement_feedback_route_handoff.get("worker_id", -1))
	var source_lane := String(_settlement_feedback_route_handoff.get("lane", ""))
	var source_world_point: Variant = _settlement_feedback_route_handoff.get(
		"landing_world_point",
		Vector3.ZERO,
	)
	var physical_landing_cue_played := bool(
		_settlement_feedback_route_handoff.get("physical_landing_cue_played", false)
	)
	_settlement_feedback_release_serial += 1
	for visual in fund_batches:
		visual.deferred = false
		visual.released_after_defer = true
		visual.release_serial = _settlement_feedback_release_serial
		visual.elapsed = 0.0
		_settlement_feedback_released_total += 1
		_configure_fund_credit_chip_path(visual)
		visual.panel.position = visual.rise_position if _prefers_reduced_motion() else visual.start_position
		visual.panel.scale = Vector2.ONE if _prefers_reduced_motion() else Vector2(0.88, 0.88)
		visual.panel.modulate = Color.WHITE
		visual.panel.visible = true
	for visual in auxiliary_batches:
		visual.deferred = false
		visual.released_after_defer = true
		visual.release_serial = _settlement_feedback_release_serial
		visual.elapsed = 0.0
		_settlement_feedback_released_total += 1
		_configure_auxiliary_settlement_chip_path(visual)
		visual.panel.position = visual.rise_position if _prefers_reduced_motion() else visual.start_position
		visual.panel.scale = Vector2.ONE if _prefers_reduced_motion() else Vector2(0.88, 0.88)
		visual.panel.modulate = Color.WHITE
		visual.panel.visible = true
	var cue_played := false
	if _audio_feedback != null:
		cue_played = _audio_feedback.play_settlement_release(
			batch_count,
			total_value_cents,
			pecks_restored,
		)
	if cue_played:
		_settlement_feedback_release_cue_count += 1
	_settlement_feedback_last_release = {
		"serial": _settlement_feedback_release_serial,
		"batch_count": batch_count,
		"item_count": item_count,
		"total_value_cents": total_value_cents,
		"pecks_restored": pecks_restored,
		"cue": "settlement_release" if cue_played else "",
		"cue_played": cue_played,
		"motion": "synchronized_calm_fan",
		"source": source_kind,
		"source_worker_id": source_worker_id,
		"source_lane": source_lane,
		"source_world_point": source_world_point,
		"source_screen_center": _settlement_feedback_source_center(),
		"route_handoff_serial": int(
			_settlement_feedback_route_handoff.get("serial", 0)
		),
		"causal_path": (
			"accepted_route>folder_landing>receipt_fan"
			if route_linked else
			"settlement>receipt_fan"
		),
		"physical_landing_cue_suppressed": (
			route_linked and not physical_landing_cue_played
		),
		"destination_ids": [
			"feed_fund_counter",
			"flockwatch_inventory_ledger",
			"priority_peck_meter",
		],
	}
	if route_linked:
		_settlement_feedback_route_handoff["status"] = "receipts_released"
		_settlement_feedback_route_handoff["release_serial"] = (
			_settlement_feedback_release_serial
		)
		_settlement_feedback_route_handoff["physical_landing_cue_suppressed"] = (
			not physical_landing_cue_played
		)
		_settlement_feedback_route_handoff["released_at_msec"] = Time.get_ticks_msec()
		_settlement_feedback_last_route_handoff = (
			_settlement_feedback_route_handoff.duplicate(true)
		)
		_settlement_feedback_route_handoff.clear()
	return true


func _record_settlement_feedback_suppression(
	kind: StringName,
	item_count: int,
	value_cents: int,
	accessible_text: String,
	reason: StringName,
) -> void:
	_settlement_feedback_suppressed_total += 1
	_settlement_feedback_last_suppressed.push_front({
		"kind": String(kind),
		"item_count": item_count,
		"value_cents": value_cents,
		"reason": String(reason),
		"accessible_text": accessible_text,
		"receipt_recoverable": true,
	})
	if _settlement_feedback_last_suppressed.size() > 3:
		_settlement_feedback_last_suppressed.resize(3)


func stage_auxiliary_settlement_capture() -> bool:
	if _active_auxiliary_settlement_chips.is_empty():
		return false
	for visual in _active_auxiliary_settlement_chips:
		if not visual.active:
			continue
		visual.elapsed = AUXILIARY_SETTLEMENT_CHIP_RISE_SECONDS
		visual.capture_staged = true
		if visual.deferred:
			visual.panel.visible = false
		else:
			visual.panel.position = visual.rise_position
			visual.panel.scale = Vector2.ONE
			visual.panel.modulate = Color.WHITE
			visual.panel.visible = true
		visual.panel.set_meta("capture_staged", true)
	return true


func _process_auxiliary_settlement_chip_pool(delta: float) -> void:
	if _active_auxiliary_settlement_chips.is_empty():
		return
	_release_deferred_settlement_feedback_if_ready()
	var scaled_delta := delta * _animation_speed_multiplier
	var total_duration := (
		AUXILIARY_SETTLEMENT_CHIP_RISE_SECONDS
		+ AUXILIARY_SETTLEMENT_CHIP_TRAVEL_SECONDS
	)
	for active_index in range(_active_auxiliary_settlement_chips.size() - 1, -1, -1):
		var visual := _active_auxiliary_settlement_chips[active_index]
		if visual.panel == null or not is_instance_valid(visual.panel):
			visual.active = false
			_active_auxiliary_settlement_chips.remove_at(active_index)
			continue
		if visual.deferred:
			visual.panel.visible = false
			if visual.capture_staged:
				continue
			visual.deferred_elapsed += maxf(0.0, delta)
			var attention_state := _settlement_feedback_attention_state()
			if bool(attention_state.get("active", false)):
				if visual.deferred_elapsed < SETTLEMENT_FEEDBACK_MAX_DEFER_SECONDS:
					continue
				_record_settlement_feedback_suppression(
					visual.kind,
					visual.item_count,
					visual.value_cents,
					String(visual.panel.get_meta("accessible_text", "")),
					visual.deferred_reason,
				)
				visual.active = false
				visual.deferred = false
				visual.panel.name = "AuxiliarySettlementChipPool_%02d" % visual.pool_index
				_active_auxiliary_settlement_chips.remove_at(active_index)
				continue
			continue
		if visual.capture_staged:
			continue
		visual.elapsed += scaled_delta
		if _prefers_reduced_motion():
			visual.panel.position = visual.rise_position
			visual.panel.scale = Vector2.ONE
			visual.panel.modulate = Color.WHITE
		elif visual.elapsed < AUXILIARY_SETTLEMENT_CHIP_RISE_SECONDS:
			var rise_progress := clampf(
				visual.elapsed / AUXILIARY_SETTLEMENT_CHIP_RISE_SECONDS,
				0.0,
				1.0,
			)
			var rise_eased := (
				_ease_cubic_in_out(rise_progress)
				if visual.released_after_defer else
				_ease_back_out(rise_progress)
			)
			var entry_scale := Vector2(0.88, 0.88) if visual.released_after_defer else Vector2(0.74, 0.74)
			visual.panel.position = visual.start_position.lerp(visual.rise_position, rise_eased)
			visual.panel.scale = entry_scale.lerp(Vector2.ONE, rise_eased)
		else:
			var travel_elapsed := visual.elapsed - AUXILIARY_SETTLEMENT_CHIP_RISE_SECONDS
			var travel_progress := clampf(
				travel_elapsed / AUXILIARY_SETTLEMENT_CHIP_TRAVEL_SECONDS,
				0.0,
				1.0,
			)
			visual.panel.position = visual.rise_position.lerp(
				visual.target_position,
				_ease_cubic_in_out(travel_progress),
			)
			visual.panel.scale = Vector2.ONE
			var fade_progress := clampf((travel_elapsed - 0.30) / 0.32, 0.0, 1.0)
			visual.panel.modulate.a = lerpf(
				1.0,
				0.12,
				_ease_cubic_in_out(fade_progress),
			)
		if visual.elapsed < total_duration:
			continue
		_on_auxiliary_settlement_chip_arrived(visual, visual.released_after_defer)
		visual.active = false
		visual.capture_staged = false
		visual.panel.visible = false
		visual.panel.modulate = Color.WHITE
		visual.panel.name = "AuxiliarySettlementChipPool_%02d" % visual.pool_index
		visual.panel.set_meta("capture_staged", false)
		_active_auxiliary_settlement_chips.remove_at(active_index)


func _on_auxiliary_settlement_chip_arrived(
	visual: AuxiliarySettlementChipVisual,
	suppress_audio := false,
) -> void:
	if visual == null:
		return
	_play_settlement_destination_ack(
		visual.kind,
		visual.item_count,
		visual.value_cents,
		visual.charges_after,
		visual.release_serial,
	)
	if visual.kind == &"refund" and not suppress_audio and _audio_feedback != null:
		_audio_feedback.play_attention_restored()


func _on_fund_credit_chip_arrived(
	value_cents: int,
	quality: StringName,
	suppress_audio := false,
	item_count := 1,
	release_serial := 0,
) -> void:
	_play_settlement_destination_ack(
		&"fund",
		item_count,
		value_cents,
		0,
		release_serial,
	)
	if not suppress_audio and _audio_feedback != null:
		_audio_feedback.play_payout_confirmation(value_cents, quality)


func _on_farmer_review_finished() -> void:
	if _camera_controller != null:
		_camera_controller.show_overview()
	_ticker_label.text = "FARMER INSPECTION COMPLETE. Credit has been successfully harvested."


func _spawn_egg_vfx(origin: Vector3, quality: StringName, worker_id: int) -> void:
	var particle_count := 7 if quality == &"golden" else 4
	var particle_color := Color("f4c95d") if quality == &"golden" else Color("f3ead2")
	if quality == &"cracked":
		particle_color = Color("c38f7b")
	for particle_index in particle_count:
		var fleck := _acquire_egg_fleck()
		if fleck == null:
			return
		var angle := TAU * float(particle_index) / float(particle_count) + worker_id * 0.31
		var distance := 0.38 + (particle_index % 2) * 0.14
		fleck.origin = origin + Vector3(0.0, 0.10, 0.0)
		fleck.destination = origin + Vector3(
			cos(angle) * distance,
			0.38 + (particle_index % 3) * 0.10,
			sin(angle) * distance,
		)
		fleck.start_scale = Vector3.ONE * (0.09 if quality == &"golden" else 0.07)
		fleck.elapsed = 0.0
		fleck.node.position = fleck.origin
		fleck.node.scale = fleck.start_scale
		fleck.node.material_override = (
			_emissive_material(particle_color, 0.65)
			if quality == &"golden" else
			_material(particle_color)
		)
		fleck.node.visible = true


func _acquire_egg_fleck() -> EggFleckVisual:
	for fleck in _egg_fleck_pool:
		if fleck.active:
			continue
		fleck.active = true
		_active_egg_flecks.append(fleck)
		return fleck
	# Extreme 10x bursts recycle the oldest bounded slot rather than allocating
	# another node and Tween on the main thread.
	if _active_egg_flecks.is_empty():
		return null
	var oldest := _active_egg_flecks[0]
	for fleck in _active_egg_flecks:
		if fleck.elapsed > oldest.elapsed:
			oldest = fleck
	return oldest


func _process_egg_fleck_pool(delta: float) -> void:
	if _active_egg_flecks.is_empty():
		return
	var scaled_delta := delta * _animation_speed_multiplier
	for active_index in range(_active_egg_flecks.size() - 1, -1, -1):
		var fleck := _active_egg_flecks[active_index]
		if fleck.node == null or not is_instance_valid(fleck.node):
			fleck.active = false
			_active_egg_flecks.remove_at(active_index)
			continue
		fleck.elapsed += scaled_delta
		var progress := clampf(
			fleck.elapsed / EGG_FLECK_DURATION_SECONDS,
			0.0,
			1.0,
		)
		var position_progress := 1.0 - (1.0 - progress) * (1.0 - progress)
		var back_progress := progress * progress * (2.70158 * progress - 1.70158)
		fleck.node.position = fleck.origin.lerp(fleck.destination, position_progress)
		fleck.node.scale = fleck.start_scale * maxf(0.0, 1.0 - back_progress)
		if progress < 1.0:
			continue
		fleck.active = false
		fleck.node.visible = false
		fleck.node.scale = Vector3.ZERO
		_active_egg_flecks.remove_at(active_index)


func _on_announcement_posted(message: String) -> void:
	_publish_status_copy(message)
	var lowered := message.to_lower()
	var urgent := (
		lowered.contains("missed")
		or lowered.contains("denied")
		or lowered.contains("breach")
		or lowered.contains("overdue")
		or lowered.contains("incident")
	)
	if _office_atmosphere != null and urgent:
		_office_atmosphere.pulse_alert(0.8)
	if _audio_feedback != null and urgent:
		_audio_feedback.play_shift_alert(0.78)


func _on_feed_party_funded() -> void:
	if _feed_party_active:
		return
	_build_feed_party_station()
	_play_fund_debit_feedback(2000, &"feed_party", &"feed_party", _feed_button)
	_feed_party_active = true
	# The event temporarily owns the clock but never owns the player's pause
	# intent. Preserve the exact authored speed index, including 0x, so funding a
	# morale break cannot silently start production afterward.
	_feed_party_previous_speed = _clock.speed_index
	_clock.set_speed(0)
	if _audio_feedback != null:
		_audio_feedback.play_feed_party()
	if _camera_controller != null:
		# Funding is an explicit transaction, so a brief reversible event shot may
		# interrupt the current inspection. The camera controller restores the
		# player's exact previous pan, zoom, and focus after the cart settles.
		_camera_controller.show_event_focus(
			FEED_PARTY_STATION_POSITION + Vector3.UP * 0.72,
			"FEED PARTY ARRIVAL",
			2.6,
			true,
		)
	_feed_party_release_scheduled = false
	_feed_party_arrivals.clear()
	_feed_party_returns.clear()
	_feed_party_expected_attendees.clear()

	var attendance_targets: Dictionary[int, Vector3] = {}
	for worker_id in _worker_views:
		var worker_view := _worker_views[worker_id] as ChickenView
		if (
			worker_view == null
			or not is_instance_valid(worker_view)
			or worker_view.has_campus_duty_assignment()
		):
			continue
		attendance_targets[worker_id] = _feed_party_attendance_target(worker_id)
		_feed_party_expected_attendees[worker_id] = true

	_feed_party_station.visible = true
	_feed_party_station.position = FEED_PARTY_STATION_POSITION + FEED_PARTY_ROLL_OFFSET
	_reset_feed_party_wheels()
	if _feed_party_tween != null and _feed_party_tween.is_valid():
		_feed_party_tween.kill()
	if _prefers_reduced_motion():
		_feed_party_station.position = FEED_PARTY_STATION_POSITION
		_on_feed_party_station_arrived()
	else:
		_feed_party_tween = _presentation_tween()
		_feed_party_tween.set_parallel(true)
		_feed_party_tween.tween_property(
			_feed_party_station,
			"position",
			FEED_PARTY_STATION_POSITION,
			FEED_PARTY_ROLL_DURATION,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		for wheel in _feed_party_wheels:
			var base_rotation := float(wheel.get_meta("feed_party_base_rotation_x", wheel.rotation.x))
			_feed_party_tween.tween_property(
				wheel,
				"rotation:x",
				base_rotation + TAU * FEED_PARTY_WHEEL_TURNS,
				FEED_PARTY_ROLL_DURATION,
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_feed_party_tween.chain().tween_callback(_on_feed_party_station_arrived)

	for worker_id in _feed_party_expected_attendees:
		var attendance: Vector3 = attendance_targets[worker_id]
		var worker_view: ChickenView = _worker_views[worker_id]
		var desk_index := worker_view.desk_index
		var outbound := feed_party_route(desk_index)
		outbound[outbound.size() - 2].x = attendance.x
		outbound[outbound.size() - 1] = attendance
		var return_route := outbound.duplicate()
		return_route.reverse()
		return_route.append(chair_position(desk_index))
		worker_view.attend_feed_party(
			outbound,
			return_route,
			attendance,
			FEED_PARTY_STATION_POSITION
		)
	if _feed_party_expected_attendees.is_empty():
		_feed_party_release_scheduled = true
		_release_feed_party_after_delay()
	_save_campaign_checkpoint("feed_party_funded")


func _feed_party_attendance_target(worker_id: int) -> Vector3:
	var worker_view: ChickenView = _worker_views.get(worker_id)
	var desk_index := worker_view.desk_index if worker_view != null else worker_id
	var socket := _feed_party_station.find_child("AttendanceSocket_%d" % desk_index, true, false) as Node3D
	if socket == null:
		return feed_party_attendance_position(desk_index)
	var target := socket.global_position
	target.y = 0.0
	return target


func _on_feed_party_station_arrived() -> void:
	if not _feed_party_active:
		return
	if _office_atmosphere != null:
		# The existing bounded one-shot now fires where the grain actually stops,
		# rather than at the cart's destination before it has rolled into view.
		_office_atmosphere.pulse_feed_party(
			FEED_PARTY_STATION_POSITION + Vector3.UP * 0.72
		)


func _on_feed_party_attendance_ready(worker_id: int) -> void:
	if not _feed_party_active or not _feed_party_expected_attendees.has(worker_id):
		return
	_feed_party_arrivals[worker_id] = true
	if _audio_feedback != null:
		_audio_feedback.play_feed_nibble(worker_id)
	if _feed_party_arrivals.size() == _feed_party_expected_attendees.size() and not _feed_party_release_scheduled:
		_feed_party_release_scheduled = true
		_release_feed_party_after_delay()


func _release_feed_party_after_delay() -> void:
	await get_tree().create_timer(FEED_PARTY_DURATION).timeout
	if not _feed_party_active:
		return
	if _feed_party_expected_attendees.is_empty():
		_complete_feed_party_visual()
		return
	for worker_id: int in _feed_party_expected_attendees:
		var view := _worker_views.get(worker_id) as ChickenView
		if view != null and is_instance_valid(view):
			view.return_from_feed_party()
		else:
			_feed_party_returns[worker_id] = true
	if _feed_party_returns.size() >= _feed_party_expected_attendees.size():
		_complete_feed_party_visual()


func _on_feed_party_attendance_completed(worker_id: int) -> void:
	if not _feed_party_active or not _feed_party_expected_attendees.has(worker_id):
		return
	_feed_party_returns[worker_id] = true
	if _feed_party_returns.size() < _feed_party_expected_attendees.size():
		return
	_complete_feed_party_visual()


func _complete_feed_party_visual() -> void:
	_feed_party_active = false
	_feed_party_release_scheduled = false
	_feed_party_expected_attendees.clear()
	if _feed_party_tween != null and _feed_party_tween.is_valid():
		_feed_party_tween.kill()
	if _prefers_reduced_motion():
		_hide_feed_party_station()
	else:
		_feed_party_tween = _presentation_tween()
		_feed_party_tween.set_parallel(true)
		_feed_party_tween.tween_property(
			_feed_party_station,
			"position",
			FEED_PARTY_STATION_POSITION + FEED_PARTY_ROLL_OFFSET,
			FEED_PARTY_ROLL_DURATION * 0.82,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		for wheel in _feed_party_wheels:
			var base_rotation := float(wheel.get_meta("feed_party_base_rotation_x", wheel.rotation.x))
			_feed_party_tween.tween_property(
				wheel,
				"rotation:x",
				base_rotation,
				FEED_PARTY_ROLL_DURATION * 0.82,
			).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_feed_party_tween.chain().tween_callback(_hide_feed_party_station)
	# Defer to the same modal authority that owns floor input. This keeps an
	# arriving settings, campaign, decision, review, or capital file from being
	# undermined by the event's remembered clock speed.
	var can_restore_speed := (
		_simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not _blocking_management_surface_open()
		and not _capital_modal_holds_speed
	)
	var restored_speed := _feed_party_previous_speed if can_restore_speed else 0
	_clock.set_speed(restored_speed)
	if not can_restore_speed:
		_ticker_label.text = (
			"FEED PARTY COMPLETE. Production remains paused while a management file is open."
		)
	elif restored_speed == 0:
		_ticker_label.text = "FEED PARTY COMPLETE. Production remains paused; attendance has been archived."
	else:
		var restored_multiplier := int(SimulationClock.SPEED_MULTIPLIERS[restored_speed])
		_ticker_label.text = (
			"FEED PARTY COMPLETE. Production resumes at %dx; attendance has been archived."
			% restored_multiplier
		)


func _hide_feed_party_station() -> void:
	_feed_party_station.visible = false
	_feed_party_station.position = FEED_PARTY_STATION_POSITION
	_reset_feed_party_wheels()


func _reset_feed_party_wheels() -> void:
	for wheel in _feed_party_wheels:
		if wheel != null and is_instance_valid(wheel):
			wheel.rotation.x = float(
				wheel.get_meta("feed_party_base_rotation_x", wheel.rotation.x)
			)


func _on_compact_speed_selected(index: int) -> void:
	if index >= 1 and index <= 3:
		_on_speed_button_pressed(index)


func _on_speed_button_pressed(index: int) -> void:
	if _campaign_ui != null and _campaign_ui.is_modal_open():
		return
	if _first_hen_prelude_pending():
		_publish_status_copy("CLOCK LOCKED. Open Mabel's file before choosing the flock policy.")
		return
	if _decision_host != null and _decision_host.visible:
		return
	if _day_review_scrim != null and _day_review_scrim.visible:
		return
	if _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		_publish_status_copy("CLOCK LOCKED. Complete the current policy or incident card first.")
		_simulation.announce_pending_decision()
		return
	if _feed_party_active:
		_publish_status_copy("CLOCK LOCKED. Feed Party attendance is still in progress.")
		return
	# A direct pace choice takes ownership from the temporary seek without first
	# restoring its older pace.
	if _next_moment_active:
		_next_moment_active = false
		_next_moment_previous_speed = 1
	if index > 0:
		_commit_tactical_route_plan()
	_clock.set_speed(index)
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()


func _on_pause_requested() -> void:
	if _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		_on_speed_button_pressed(0)
		return
	_on_speed_button_pressed(1 if _clock.speed_index == 0 else 0)


func _on_speed_changed(speed_index: int, multiplier: float) -> void:
	if speed_index > 0:
		_next_moment_stop_reason = ""
	_sync_worker_route_progress_hold()
	# Speed controls own their active styling. Restore any tutorial overlay first,
	# then re-apply the currently relevant coach cue after the speed state settles.
	_clear_first_clutch_global_cue()
	var campaign_open := _campaign_ui != null and _campaign_ui.is_modal_open()
	var controls_available := (
		_simulation != null
		and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and not _feed_party_active
		and (_decision_host == null or not _decision_host.visible)
		and (_day_review_scrim == null or not _day_review_scrim.visible)
		and not campaign_open
	)
	for index in _speed_buttons.size():
		_speed_buttons[index].disabled = not controls_available
		_speed_buttons[index].theme_type_variation = &"ActiveSpeedButton" if index == speed_index else &"SpeedButton"
	_sync_authoritative_clock_display()
	_sync_authoritative_shift_objective_display()
	_refresh_speed_button_copy()
	if _routing_ui != null:
		_routing_ui.set_peck_assist_clock_running(speed_index > 0)
	if _simulation != null:
		var snapshot := _simulation.snapshot(true)
		_refresh_first_clutch_ui(snapshot)
		_update_guidance(snapshot)
	var review_open := _day_review_scrim != null and _day_review_scrim.visible
	var decision_open := _decision_host != null and _decision_host.visible
	if _ticker_label != null and not _feed_party_active and not review_open and not decision_open and not campaign_open:
		var tactical_plan := _tactical_route_plan_snapshot()
		var clock_copy := (
			"PLAN %d/%d  ·  CHOOSE HEN ROUTES  ·  RESUME TO FILE" % [
				int(tactical_plan.get("count", 0)),
				int(tactical_plan.get("capacity", TacticalRoutePlannerScript.CAPACITY)),
			]
			if speed_index == 0 and int(tactical_plan.get("count", 0)) > 0 else
			"SHIFT PAUSED. Inspect the flock, plan up to three routes, or resume when ready."
			if speed_index == 0 else
			"SHIFT RUNNING AT %dx. Click a hen to inspect; the clutch target stays above." % int(multiplier)
		)
		if _should_preserve_priority_toast(clock_copy, Time.get_ticks_msec()):
			_ticker_label.text = _ticker_visible_copy
		else:
			_ticker_label.text = clock_copy


func _on_feed_pressed() -> void:
	if _campaign_ui != null and _campaign_ui.is_modal_open():
		return
	if _feed_party_active:
		_publish_status_copy(
			"FEED PARTY ALREADY IN PROGRESS. No second morale debit was charged."
		)
		return
	_simulation.fund_feed_party()


func _on_overtime_pressed() -> void:
	if _campaign_ui != null and _campaign_ui.is_modal_open():
		return
	if _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING or _feed_party_active:
		_publish_status_copy(
			"AFTER-HOURS REQUEST HELD. Settle the current management action first."
		)
		return
	_simulation.toggle_overtime()
	_save_campaign_checkpoint("overtime_toggled")


func _on_upgrade_pressed(upgrade_id: StringName) -> void:
	_simulation.purchase_upgrade(upgrade_id)


func _begin_payoff_breath() -> void:
	_payoff_quiet_until_msec = Time.get_ticks_msec() + 6000
	if _guidance_action_id == &"playbook" and _guidance_label != null:
		_set_guidance(_guidance_label.text, &"goal", _guidance_label.tooltip_text, &"playbook")
	if _character_dialogue_ui != null:
		_character_dialogue_ui.hold_ambient(6.0)


func _on_upgrade_purchased(upgrade_id: StringName, level: int, cost_cents: int) -> void:
	_begin_payoff_breath()
	_character_dialogue_ui.hold_ambient(3.0)
	_upgrade_demonstration = {"id": String(upgrade_id), "level": level, "day": _simulation.day}
	_play_fund_debit_feedback(
		cost_cents,
		&"upgrade",
		upgrade_id,
		_upgrade_buttons.get(upgrade_id) as Button,
	)
	if _audio_feedback != null:
		_audio_feedback.play_upgrade()
	var button: Button = _upgrade_buttons.get(upgrade_id)
	if button != null:
		button.modulate = Color("f7d77b")
		var tween := _presentation_tween()
		tween.tween_property(button, "modulate", Color.WHITE, 0.70).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _workstation_feedback != null:
		var active_snapshot := _snapshot_with_active_workers(_simulation.snapshot())
		_workstation_feedback.apply_snapshot(_workstation_visual_snapshot(active_snapshot))
	_save_campaign_checkpoint("upgrade_purchased")


func _ensure_preview_runner() -> void:
	if _preview_runner == null:
		_preview_runner = (load("res://features/office/office_preview_runner.gd") as Script).new(self)


func _capture_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_preview")


func _capture_action_feedback_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_action_feedback_preview")


func _capture_incident_preview(selected := false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_incident_preview", selected)


func _capture_petition_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_petition_preview")


func _capture_flock_labor_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_flock_labor_preview")


func _capture_economic_break_even_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_economic_break_even_preview")


func _capture_ledger_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_ledger_preview")


func _capture_capacity_commissioning_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_capacity_commissioning_preview")


func _capture_feed_party_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_feed_party_preview")


func _capture_fund_debit_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_fund_debit_preview")


func _capture_procurement_debit_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_procurement_debit_preview")


func _capture_intern_debit_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_intern_debit_preview")


func _capture_predator_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_predator_preview")


func _capture_predator_animation() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_predator_animation")


func _capture_routing_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_preview")


func _capture_adaptive_routing_success_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_adaptive_routing_success_preview")


func _capture_core_action_hold_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_core_action_hold_preview")


func _capture_economic_action_hold_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_economic_action_hold_preview")


func _capture_strategic_action_hold_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_strategic_action_hold_preview")


func _capture_save_recovery_hold_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_save_recovery_hold_preview")


func _capture_dispatch_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_dispatch_preview")


func _capture_routing_pace_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_pace_preview")


func _capture_career_workshop_preview(advanced := false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_career_workshop_preview", advanced)


func _capture_flock_ties_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_flock_ties_preview")


func _capture_hen_social_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_hen_social_preview")


func _capture_hen_expression_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_hen_expression_preview")


func _capture_collection_detail_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_collection_detail_preview")


func _capture_office_props_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_office_props_preview")


func _capture_work_progress_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_work_progress_preview")


func _capture_routing_peck_recharge_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_peck_recharge_preview")


func _capture_routing_golden_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_golden_preview")


func _capture_routing_team_lift_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_team_lift_preview")


func _capture_routing_mastery_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_mastery_preview")


func _capture_routing_return_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_return_preview")


func _capture_routing_return_cue_preview(
	clear_with_route := false,
	stage_landing := false,
	stage_work_start := false,
) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_routing_return_cue_preview", clear_with_route, stage_landing, stage_work_start)


func _capture_dispatch_break_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_dispatch_break_preview")


func _capture_dispatch_recovery_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_dispatch_recovery_preview")


func _capture_hen_intents_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_hen_intents_preview")


func _capture_first_hen_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_first_hen_preview")


func _capture_first_hen_policy_preview(selected := false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_first_hen_policy_preview", selected)


func _capture_peck_assist_preview(
	show_result := false,
	show_delivery := false,
	show_missed := false,
) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_peck_assist_preview", show_result, show_delivery, show_missed)


func _capture_grading_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_grading_preview")


func _capture_egg_journey_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_egg_journey_preview")


func _capture_egg_delivery_ack_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_egg_delivery_ack_preview")


func _capture_payout_burst_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_payout_burst_preview")


func _capture_mixed_settlement_preview(
	focused := false,
	priority_contention := false,
	release_after_route := false,
	capture_destination := false,
) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_mixed_settlement_preview", focused, priority_contention, release_after_route, capture_destination)


func _capture_staffing_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_staffing_preview")


func _capture_internship_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_internship_ui_preview")


func _capture_internship_fellow_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_internship_fellow_ui_preview")


func _capture_intern_dialogue_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_intern_dialogue_preview")


func _capture_facility_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_facility_preview")


func _capture_facility_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_facility_ui_preview")


func _capture_economic_briefing_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_economic_briefing_ui_preview")


func _capture_feed_procurement_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_feed_procurement_ui_preview")


func _capture_packing_annex_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_packing_annex_preview")


func _capture_records_annex_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_records_annex_preview")


func _capture_service_coop_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_service_coop_preview")


func _capture_service_coop_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_service_coop_ui_preview")


func _capture_negotiation_room_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_negotiation_room_preview")


func _capture_contract_board_world_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_contract_board_world_preview")


func _capture_contract_board_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_contract_board_ui_preview")


func _capture_contract_pricing_ui_preview(access_rate := false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_contract_pricing_ui_preview", access_rate)


func _capture_negotiation_board_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_negotiation_board_ui_preview")


func _capture_wellness_nest_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_wellness_nest_preview")


func _capture_training_roost_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_training_roost_preview")


func _capture_care_campus_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_care_campus_preview")


func _capture_flock_care_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_flock_care_ui_preview")


func _capture_farmer_relations_gallery_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_farmer_relations_gallery_preview")


func _capture_farmer_relations_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_farmer_relations_ui_preview")


func _capture_rooster_operations_office_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_rooster_operations_office_preview")


func _capture_rooster_operations_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_rooster_operations_ui_preview")


func _capture_it_coop_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_it_coop_preview")


func _capture_operations_campus_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_operations_campus_preview")


func _capture_flock_relations_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_flock_relations_preview")


func _capture_flock_relations_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_flock_relations_ui_preview")


func _capture_flock_provisions_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_flock_provisions_preview")


func _capture_governance_campus_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_governance_campus_preview")


func _capture_farmgate_dispatch_preview(target_level: int) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_farmgate_dispatch_preview", target_level)


func _capture_farmgate_dispatch_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_farmgate_dispatch_ui_preview")


func _capture_farmgate_filing_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_farmgate_filing_preview")


func _capture_settings_handoff_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_settings_handoff_preview")


func _capture_confirmation_handoff_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_confirmation_handoff_preview")


func _capture_staff_release_confirmation_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_staff_release_confirmation_preview")


func _capture_manager_succession_confirmation_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_manager_succession_confirmation_preview")


func _capture_dispatch_campus_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_dispatch_campus_preview")


func _capture_capital_blueprint_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_capital_blueprint_preview")


func _capture_commissioning_reveal_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_commissioning_reveal_preview")


func _capture_campus_expansion_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campus_expansion_preview")


func _capture_campus_portfolio_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campus_portfolio_preview")


func _capture_campus_portfolio_reveal_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campus_portfolio_reveal_preview")


func _settle_campus_workers_for_capture() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_settle_campus_workers_for_capture")


func _capture_campus_portfolio_ui_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campus_portfolio_ui_preview")


func _prepare_campus_portfolio_capture_economy() -> bool:
	_ensure_preview_runner()
	return _preview_runner.call("_prepare_campus_portfolio_capture_economy")


func _prepare_campus_expansion_capture_economy() -> bool:
	_ensure_preview_runner()
	return _preview_runner.call("_prepare_campus_expansion_capture_economy")


func _campus_capture_receipt_accepted(receipt: Dictionary, action_label: String) -> bool:
	_ensure_preview_runner()
	return _preview_runner.call("_campus_capture_receipt_accepted", receipt, action_label)


func _prepare_farmgate_capture_economy(target_level: int) -> bool:
	_ensure_preview_runner()
	return _preview_runner.call("_prepare_farmgate_capture_economy", target_level)


func _capture_expansion_overview_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_expansion_overview_preview")


func _prepare_service_coop_capture_economy() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_service_coop_capture_economy")


func _prepare_care_campus_capture_economy() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_care_campus_capture_economy")


func _prepare_operations_campus_capture_economy() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_operations_campus_capture_economy")


func _prepare_flock_relations_capture_economy() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_flock_relations_capture_economy")


func _prepare_farmer_relations_gallery_capture_economy() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_farmer_relations_gallery_capture_economy")


func _prepare_farmer_relations_gallery_capture_record() -> bool:
	_ensure_preview_runner()
	return _preview_runner.call("_prepare_farmer_relations_gallery_capture_record")


func _prepare_farmer_relations_gallery_capture_offer() -> bool:
	_ensure_preview_runner()
	return _preview_runner.call("_prepare_farmer_relations_gallery_capture_offer")


func _prepare_flock_relations_capture_cases() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_flock_relations_capture_cases")


func _prepare_flock_relations_ui_capture_case() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_flock_relations_ui_capture_case")


func _commission_capture_facility(facility_id: StringName) -> bool:
	_ensure_preview_runner()
	return _preview_runner.call("_commission_capture_facility", facility_id)


func _hide_world_capture_overlays() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_hide_world_capture_overlays")


func _capture_signage_preview(focus: Vector3, file_name: String) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_signage_preview", focus, file_name)


func _capture_breakroom_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_breakroom_preview")


func _capture_career_trophies_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_career_trophies_preview")


func _capture_campaign_title_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_title_preview")


func _capture_campaign_report_preview(at_risk: bool = false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_report_preview", at_risk)


func _capture_campaign_promotion_opportunity_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_promotion_opportunity_preview")


func _capture_campaign_promotion_tracker_preview(
	promotion_ready: bool = false,
	save_capture: bool = true,
	max_interface_scale: bool = false,
) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_promotion_tracker_preview", promotion_ready, save_capture, max_interface_scale)


func _capture_campaign_goal_cause_locator_preview(stale_receipt: bool = false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_goal_cause_locator_preview", stale_receipt)


func _capture_campaign_goal_driver_route_preview(show_handoff: bool = false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_goal_driver_route_preview", show_handoff)


func _capture_campaign_goal_driver_flock_care_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_goal_driver_flock_care_preview")


func _capture_campaign_goal_driver_farmer_standing_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_goal_driver_farmer_standing_preview")


func _capture_campaign_goal_driver_coop_controls_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_goal_driver_coop_controls_preview")


func _capture_campaign_goal_driver_live_files_preview(empty_intake: bool = false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_goal_driver_live_files_preview", empty_intake)


func _capture_senior_policy_receipt_preview(with_shift_delta: bool = false) -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_senior_policy_receipt_preview", with_shift_delta)


func _capture_career_sponsorship_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_career_sponsorship_preview")


func _capture_career_sponsorship_confirmation_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_career_sponsorship_confirmation_preview")


func _capture_campaign_final_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_campaign_final_preview")


func _capture_restructuring_preview() -> void:
	_ensure_preview_runner()
	await _preview_runner.call("_capture_restructuring_preview")


func _campaign_capture_report(shift_number: int) -> Dictionary:
	_ensure_preview_runner()
	return _preview_runner.call("_campaign_capture_report", shift_number)


func _career_sponsorship_capture_report(day: int, rework_total: int) -> Dictionary:
	_ensure_preview_runner()
	return _preview_runner.call("_career_sponsorship_capture_report", day, rework_total)


func _prepare_capture_running() -> void:
	_ensure_preview_runner()
	_preview_runner.call("_prepare_capture_running")


func _save_preview(file_name: String) -> void:
	_ensure_preview_runner()
	_preview_runner.call("_save_preview", file_name)


func _add_box(parent: Node, part_name: String, size: Vector3, part_position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = ProceduralPrimitiveCache.box(size)
	if part_name.begins_with("Basket") or part_name == "PresentationPlinth":
		instance.mesh = OfficePropGeometry.rounded_box(size, 0.02)
	if part_name in ["Copier", "CopierLid", "CopierPanel", "CopierOutputTray", "CopierBase", "CopierRecessedPull", "FileCabinet", "ArchiveBox", "FeedSnackPacket", "ChickPhotoFrame"]:
		instance.mesh = OfficePropGeometry.rounded_box(size, 0.045 if part_name == "Copier" else 0.025)
	instance.position = part_position
	instance.material_override = _material(color)
	if part_name.begins_with("Basket"):
		instance.material_override = SurfaceFinish.material(&"wood", color, 1.7)
	parent.add_child(instance)
	return instance


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var cache_key := "%s_%.2f_%.2f" % [color.to_html(), roughness, metallic]
	if _material_cache.has(cache_key):
		return _material_cache[cache_key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	# This cached solid palette is immutable; static siblings may bake its color
	# into vertices. Textured, emissive and animated props use separate paths.
	material.set_meta(&"static_office_solid", true)
	_material_cache[cache_key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var cache_key := "emissive_%s_%.2f" % [color.to_html(), energy]
	if _material_cache.has(cache_key):
		return _material_cache[cache_key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	_material_cache[cache_key] = material
	return material


func _make_flockwatch_section(node_name: String) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.name = node_name
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 8)
	return section


func _make_flockwatch_glance_grid(node_name: String, columns: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.name = node_name
	grid.columns = maxi(1, columns)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	return grid


func _add_flockwatch_glance_tile(
	parent: GridContainer,
	node_name: String,
	copy: String,
	icon_kind: StringName = &"goal",
) -> Label:
	var tile := PanelContainer.new()
	tile.name = "%sTile" % node_name
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := _panel_style(Color("182530"), 0.96, 6, 1)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	tile.add_theme_stylebox_override("panel", style)
	parent.add_child(tile)
	var row := HBoxContainer.new()
	row.name = "%sRow" % node_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	tile.add_child(row)
	var icon := FlockwatchIconBadgeScript.new()
	icon.name = "%sIcon" % node_name
	icon.configure(icon_kind)
	row.add_child(icon)
	var label := _make_label(copy, 10, Color("dce7e8"))
	label.name = node_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 40.0)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.set_meta("icon_kind", icon_kind)
	row.add_child(label)
	return label


func _set_flockwatch_glance_icon(
	glance: Label,
	icon_kind: StringName,
	accent: Color,
) -> void:
	if glance == null:
		return
	glance.set_meta("icon_kind", icon_kind)
	var icon := glance.get_parent().find_child("%sIcon" % glance.name, false, false)
	if icon != null and icon.has_method("configure"):
		icon.call("configure", icon_kind, accent)


func _flockwatch_glance_tile(glance: Label) -> Control:
	if glance == null:
		return null
	var row := glance.get_parent() as Control
	if row != null and row.get_parent() is Control:
		return row.get_parent() as Control
	return row


func _make_label(text: String, font_size: int, color: Color = Color("eef1f5")) -> Label:
	var label := Label.new()
	label.text = text
	label.set_meta(&"preference_base_font_size", font_size)
	var scale := float(_player_preferences.get("ui_scale", 1.0))
	label.add_theme_font_size_override("font_size", maxi(10, roundi(font_size * scale)))
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style(color: Color, opacity: float, corner_radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	color.a = opacity
	style.bg_color = color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = Color("5c6d7f")
	return style
