class_name Office
extends Node3D

const ChickenViewScript := preload("res://features/chickens/chicken_view.gd")
const PredatorEncounterScript := preload("res://features/predator/predator_encounter.gd")
const WorkstationScene := preload("res://assets/models/office_workstation.glb")
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
const SettingsUIScript := preload("res://features/office/settings_ui.gd")
const PeckworkRoutingUIScript := preload("res://features/office/peckwork_routing_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")
const PeckingOrderUIScript := preload("res://features/office/pecking_order_ui.gd")
const FlockwatchNavigationScript := preload("res://features/office/flockwatch_navigation.gd")
const FlockwatchDisclosureToggleScript := preload("res://features/office/flockwatch_disclosure_toggle.gd")
const CapitalBlueprintUIScript := preload("res://features/office/capital_blueprint_ui.gd")
const CampusExpansionUIScript := preload("res://features/office/campus_expansion_ui.gd")
const CampusPortfolioUIScript := preload("res://features/office/campus_portfolio_ui.gd")
const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const CampusPortfolioVisualScript := preload("res://features/office/campus_portfolio_visual.gd")
const CommissioningRevealUIScript := preload("res://features/office/commissioning_reveal_ui.gd")
const CampusPortfolioRevealUIScript := preload("res://features/office/campus_portfolio_reveal_ui.gd")
const CampaignStateScript := preload("res://core/campaign/campaign_state.gd")
const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")
const CareerCommendationsScript := preload("res://core/campaign/career_commendations.gd")
const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const CheckpointCoordinatorScript := preload("res://core/persistence/checkpoint_coordinator.gd")
const ProbationCampaignUIScript := preload("res://features/office/probation_campaign_ui.gd")
const FEED_PARTY_STATION_PATH := "res://assets/models/feed_party_station.glb"
const CAMPAIGN_SAVE_FILENAME := "probation_campaign.json"
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
const CAREER_DOCKET_SEEDS := [1701, 4703, 7919, 12011]
const PECK_ASSIST_ACTION: StringName = &"peck_assist"
const PECK_FOCUS_LEAD_PROGRESS := 16.0
const PECK_FOCUS_RESULT_HOLD_MSEC := 2500
const PREDATOR_DEBUG_ARGUMENT := "--enable-predator-debug"
const FIRST_CLUTCH_VERSION := 2
const FIRST_CLUTCH_COMPLETION_HOLD_SECONDS := 5.5
const STATUS_TOAST_HOLD_MSEC := 5500
const STATUS_HISTORY_LIMIT := 18
const CHECKPOINT_ERROR_LIMIT := 240
const WEB_DIAGNOSTIC_INTERVAL_MSEC := 250
const LIVE_HUD_HEIGHT := 92.0
const FIRST_CLUTCH_HUD_HEIGHT := 64.0
const LIVE_ROUTING_TOP := 100.0
const FIRST_CLUTCH_ROUTING_TOP := 72.0
const FIRST_HEN_WORKER_ID := 0
const CAPACITY_COMMISSIONING_HOLD_SECONDS := 0.72
const CAPACITY_COMMISSIONING_REVEAL_SECONDS := 0.34
const CAPACITY_COMMISSIONING_SETTLE_SECONDS := 0.28
const FIRST_CLUTCH_REINVESTMENT_KIND: StringName = &"first_clutch_reinvestment"
const SHIFT_END_FALLBACK_MINUTE := 24 * 60
const CORE_OVERVIEW_TARGET := Vector3(4.75, 0.65, -0.65)
const CORE_OVERVIEW_POSITION := Vector3(22.05, 17.50, 20.85)
const CORE_OVERVIEW_SIZE := 16.0
const FIRST_HEN_FOCUS_SIZE := 6.3
const OFFICE_FILL_LIGHT_ENERGY := 0.24
# Camera bounds are presentation-only. The shell and every mature desk socket
# still exist, while capacity progressively reveals the west wing and its room.
const OPENING_OFFICE_CAMERA_BOUNDS := Rect2(Vector2(-2.0, -8.0), Vector2(13.5, 14.7))
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
		"long_term": "OUTPUT + QUEUE CONTROL",
	},
	&"shell_assurance": {
		"supports": [&"crack_rate_basis_points", &"rework", &"compliance"],
		"risks": [&"eggs", &"quota_met", &"overdue_files"],
		"long_term": "SHELL QUALITY + COMPLIANCE",
	},
	&"sustainable_flock": {
		"supports": [&"welfare"],
		"risks": [&"eggs", &"quota_met", &"overdue_files"],
		"long_term": "FLOCK WELFARE + RECOVERY",
	},
}

var _simulation := DepartmentSimulation.new(1701, INITIAL_CAMPAIGN_STAFF)
var _clock := SimulationClock.new()
var _worker_views: Dictionary[int, ChickenView] = {}
var _departing_worker_views: Dictionary[int, ChickenView] = {}
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
var _dormant_west_presentation: Node3D
var _west_perch_04_presentation: Node3D
var _west_perch_05_presentation: Node3D
var _archive_presentation: Node3D
var _intake_presentation: Node3D
var _egg_layer: Node3D
var _feed_party_station: Node3D
var _feed_party_tween: Tween
var _feed_party_wheels: Array[Node3D] = []
var _feed_party_active: bool = false
var _feed_party_previous_speed: int = 1
var _feed_party_release_scheduled: bool = false
var _feed_party_arrivals: Dictionary[int, bool] = {}
var _feed_party_returns: Dictionary[int, bool] = {}
var _feed_party_expected_attendees: Dictionary[int, bool] = {}
var _campus_worker_assignments: Dictionary[int, StringName] = {}
var _campus_worker_pads: Dictionary[int, StringName] = {}
var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _environment: Environment
var _office_sun: DirectionalLight3D
var _bounce_light: DirectionalLight3D
var _office_fill_lights: Array[OmniLight3D] = []
var _management_camera: Camera3D
var _camera_controller: ManagementCameraController
var _management_presence: ManagementPresence
var _workstation_feedback: WorkstationFeedback
var _office_atmosphere: OfficeAtmosphere
var _office_storytelling: OfficeStorytelling
var _audio_feedback: Node
var _audio_director: Node
var _routing_ui: PeckworkRoutingUI
var _staffing_ui: RoostStaffingUI
var _pecking_order_ui
var _flockwatch_navigation: FlockwatchNavigation
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
var _campaign_state = CampaignStateScript.new()
var _senior_roost_state = SeniorRoostStateScript.new()
var _campaign_store = CampaignSaveStoreScript.new(CAMPAIGN_SAVE_FILENAME)
var _checkpoint_coordinator = CheckpointCoordinatorScript.new()
var _has_campaign_checkpoint_candidate := false
var _has_verified_campaign_checkpoint := false
var _checkpoint_last_error := ""
var _checkpoint_last_saved_reason := ""
var _checkpoint_last_saved_unix_msec: int = 0
var _web_checkpoint_flush_callback
var _web_career_backup_offer_callback
var _web_mobile_action_callback
var _web_focus_pause_callback
var _last_lifecycle_checkpoint_frame: int = -1
var _last_lifecycle_checkpoint_revision: int = -1
var _campaign_session_checkpoint_enabled := false
var _preferences_store = PlayerPreferencesStoreScript.new()
var _web_preferences_mirror = WebPreferencesMirrorScript.new()
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
var _first_clutch_completion_generation: int = 0
var _eggs_in_flight_by_worker: Dictionary[int, int] = {}
# Physical eggs can overlap at high simulation speed. Preserve every completion
# in FIFO order so the basket callback settles the exact assisted claim that
# authored that egg instead of guessing from the worker's newer active file.
var _collection_claim_ids_by_worker: Dictionary[int, Array] = {}
var _collection_cash_by_claim_id: Dictionary[int, int] = {}
var _collection_stocked_by_claim_id: Dictionary[int, bool] = {}
var _first_clutch_global_cued_control: Button
var _first_clutch_global_cue_tween: Tween

var _day_label: Label
var _time_label: Label
var _revenue_label: Label
var _today_workload_label: Label
var _today_clutch_label: Label
var _today_flock_label: Label
var _today_ledger_label: Label
var _campaign_objectives_label: Label
var _campaign_orders_heading_label: Label
var _campaign_doctrine_label: Label
var _campaign_safeguards_label: Label
var _flock_labor_label: Label
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
var _ticker_hide_at_msec: int = 0
var _status_history: Array[String] = []
var _status_history_label: Label
var _status_history_toggle: Button
var _status_history_expanded := false
var _flockwatch_panel: PanelContainer
var _flockwatch_toggle: Button
var _settings_button: Button
var _settings_ui: PeckingOrderSettingsUI
var _settings_previous_speed: int = 0
var _settings_holds_speed: bool = false
var _settings_prior_focus_owner: Control
var _focus_pause_active: bool = false
var _focus_pause_previous_speed: int = 0
var _flockwatch_open: bool = false
var _flockwatch_prior_focus_owner: Control
var _speed_buttons: Array[Button] = []
var _priority_peck_focus_worker_id := -1
var _priority_peck_result_hold_until_msec := 0
var _priority_peck_result_hold_worker_id := -1
var _priority_peck_result_hold_claim_id := -1
var _priority_peck_focus_disarmed_worker_id := -1
var _ui_root: Control
var _top_hud_panel: PanelContainer
var _shift_objective_row: HBoxContainer
var _compact_live_hud_applied := false
var _quota_progress: ProgressBar
var _quota_progress_label: Label
var _quality_streak_label: Label
var _directive_badge: Label
var _guidance_label: Label
var _feed_button: Button
var _upgrade_buttons: Dictionary[StringName, Button] = {}
var _upgrade_disclosure_toggle
var _had_actionable_upgrade := false
var _day_review_panel: PanelContainer
var _day_review_scrim: ColorRect
var _review_title: Label
var _review_summary: Label
var _review_results: Label
var _review_details_toggle: Button
var _review_details_scroll: ScrollContainer
var _review_details_expanded := false
var _review_story: Label
var _continue_shift_button: Button
var _begin_next_shift_button: Button
var _decision_host: Control
var _decision_panel: PanelContainer
var _decision_eyebrow: Label
var _decision_title: Label
var _decision_body: Label
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
var _authoritative_revenue_cents := 0
var _displayed_revenue_cents := -1
var _pending_collection_cents := 0
var _fund_visual_target_cents := -1
var _fund_count_tween: Tween
var _pending_web_diagnostic_snapshot: Dictionary = {}
var _web_diagnostic_dirty := false
var _web_diagnostic_next_allowed_msec := 0
var _pending_simulation_presentation_snapshot: Dictionary = {}
var _presentation_update_count := 0
var _last_presented_tick_revision := 0
var _boot_started_msec := 0
var _boot_timing: Dictionary = {}


func _ready() -> void:
	_boot_started_msec = Time.get_ticks_msec()
	_boot_mark(&"entry")
	name = "CorporateClaimsDivision"
	# Envelope validity is enough to offer Continue, but it is not proof that the
	# nested campaign, simulation, and Senior ledgers can activate together.
	_has_campaign_checkpoint_candidate = _campaign_store != null and _campaign_store.has_save()
	_has_verified_campaign_checkpoint = false
	_install_web_checkpoint_bridge()
	_ensure_peck_assist_input_action()
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
	_office_storytelling.egg_graded.connect(_on_egg_graded)
	_office_storytelling.egg_reached_presentation_detailed.connect(_on_egg_reached_presentation)
	_office_storytelling.optional_visuals_finished.connect(_on_optional_storytelling_finished)
	add_child(_office_storytelling)
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
	_boot_mark(&"ui")
	_apply_player_preferences()

	add_child(_clock)
	_clock.initialize(_simulation)
	_clock.speed_changed.connect(_on_speed_changed)
	_clock.tick_batch_completed.connect(_on_clock_tick_batch_completed)
	_simulation.snapshot_changed.connect(_on_snapshot_changed)
	_simulation.egg_laid_detailed.connect(_on_egg_laid)
	_simulation.announcement_posted.connect(_on_announcement_posted)
	_simulation.feed_party_funded.connect(_on_feed_party_funded)
	_simulation.workday_completed.connect(_on_workday_completed)
	_simulation.upgrade_purchased.connect(_on_upgrade_purchased)
	_simulation.decision_requested.connect(_on_decision_requested)
	_simulation.decision_resolved.connect(_on_decision_resolved)
	_simulation.first_clutch_reinvestment_resolved.connect(_on_first_clutch_reinvestment_resolved)

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
	_boot_mark(&"first_interactive")
	if "--capture-decision" in OS.get_cmdline_user_args() or "--capture-decision" in OS.get_cmdline_args():
		_capture_decision_preview()
	elif "--capture-incident" in OS.get_cmdline_user_args() or "--capture-incident" in OS.get_cmdline_args():
		_capture_incident_preview()
	elif "--capture-petition" in OS.get_cmdline_user_args() or "--capture-petition" in OS.get_cmdline_args():
		_capture_petition_preview()
	elif "--capture-flock-labor" in OS.get_cmdline_user_args() or "--capture-flock-labor" in OS.get_cmdline_args():
		_capture_flock_labor_preview()
	elif "--capture-day-review" in OS.get_cmdline_user_args() or "--capture-day-review" in OS.get_cmdline_args():
		_capture_day_review_preview()
	elif "--capture-ledger" in OS.get_cmdline_user_args() or "--capture-ledger" in OS.get_cmdline_args():
		_capture_ledger_preview()
	elif "--capture-review" in OS.get_cmdline_user_args() or "--capture-review" in OS.get_cmdline_args():
		_capture_review_preview()
	elif "--capture-feed-party" in OS.get_cmdline_user_args() or "--capture-feed-party" in OS.get_cmdline_args():
		_capture_feed_party_preview()
	elif "--capture-routing" in OS.get_cmdline_user_args() or "--capture-routing" in OS.get_cmdline_args():
		_capture_routing_preview()
	elif "--capture-first-clutch" in OS.get_cmdline_user_args() or "--capture-first-clutch" in OS.get_cmdline_args():
		_capture_first_clutch_preview()
	elif "--capture-first-clutch-reinvestment" in OS.get_cmdline_user_args() or "--capture-first-clutch-reinvestment" in OS.get_cmdline_args():
		_capture_first_clutch_reinvestment_preview()
	elif "--capture-first-hen" in OS.get_cmdline_user_args() or "--capture-first-hen" in OS.get_cmdline_args():
		_capture_first_hen_preview()
	elif "--capture-first-hen-policy" in OS.get_cmdline_user_args() or "--capture-first-hen-policy" in OS.get_cmdline_args():
		_capture_first_hen_policy_preview()
	elif "--capture-peck-assist" in OS.get_cmdline_user_args() or "--capture-peck-assist" in OS.get_cmdline_args():
		_capture_peck_assist_preview()
	elif "--capture-restructuring" in OS.get_cmdline_user_args() or "--capture-restructuring" in OS.get_cmdline_args():
		_capture_restructuring_preview()
	elif "--capture-grading" in OS.get_cmdline_user_args() or "--capture-grading" in OS.get_cmdline_args():
		_capture_grading_preview()
	elif "--capture-staffing" in OS.get_cmdline_user_args() or "--capture-staffing" in OS.get_cmdline_args():
		_capture_staffing_preview()
	elif "--capture-capacity-commissioning" in OS.get_cmdline_user_args() or "--capture-capacity-commissioning" in OS.get_cmdline_args():
		_capture_capacity_commissioning_preview()
	elif "--capture-facility" in OS.get_cmdline_user_args() or "--capture-facility" in OS.get_cmdline_args():
		_capture_facility_preview()
	elif "--capture-facility-ui" in OS.get_cmdline_user_args() or "--capture-facility-ui" in OS.get_cmdline_args():
		_capture_facility_ui_preview()
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
	elif "--capture-negotiation-board-ui" in OS.get_cmdline_user_args() or "--capture-negotiation-board-ui" in OS.get_cmdline_args():
		_capture_negotiation_board_ui_preview()
	elif "--capture-wellness-nest" in OS.get_cmdline_user_args() or "--capture-wellness-nest" in OS.get_cmdline_args():
		_capture_wellness_nest_preview()
	elif "--capture-training-roost" in OS.get_cmdline_user_args() or "--capture-training-roost" in OS.get_cmdline_args():
		_capture_training_roost_preview()
	elif "--capture-care-campus" in OS.get_cmdline_user_args() or "--capture-care-campus" in OS.get_cmdline_args():
		_capture_care_campus_preview()
	elif "--capture-farmer-relations-gallery" in OS.get_cmdline_user_args() or "--capture-farmer-relations-gallery" in OS.get_cmdline_args():
		_capture_farmer_relations_gallery_preview()
	elif "--capture-rooster-operations-office" in OS.get_cmdline_user_args() or "--capture-rooster-operations-office" in OS.get_cmdline_args():
		_capture_rooster_operations_office_preview()
	elif "--capture-it-coop" in OS.get_cmdline_user_args() or "--capture-it-coop" in OS.get_cmdline_args():
		_capture_it_coop_preview()
	elif "--capture-operations-campus" in OS.get_cmdline_user_args() or "--capture-operations-campus" in OS.get_cmdline_args():
		_capture_operations_campus_preview()
	elif "--capture-flock-relations" in OS.get_cmdline_user_args() or "--capture-flock-relations" in OS.get_cmdline_args():
		_capture_flock_relations_preview()
	elif "--capture-flock-provisions" in OS.get_cmdline_user_args() or "--capture-flock-provisions" in OS.get_cmdline_args():
		_capture_flock_provisions_preview()
	elif "--capture-governance-campus" in OS.get_cmdline_user_args() or "--capture-governance-campus" in OS.get_cmdline_args():
		_capture_governance_campus_preview()
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
	elif "--capture-expansion-overview" in OS.get_cmdline_user_args() or "--capture-expansion-overview" in OS.get_cmdline_args():
		_capture_expansion_overview_preview()
	elif "--capture-signage-back" in OS.get_cmdline_user_args() or "--capture-signage-back" in OS.get_cmdline_args():
		_capture_signage_preview(Vector3(0.0, 2.15, -7.70), "signage_back.png")
	elif "--capture-signage-left" in OS.get_cmdline_user_args() or "--capture-signage-left" in OS.get_cmdline_args():
		_capture_signage_preview(Vector3(-10.65, 2.05, -0.20), "signage_left.png")
	elif "--capture-signage-desk" in OS.get_cmdline_user_args() or "--capture-signage-desk" in OS.get_cmdline_args():
		_capture_signage_preview(desk_position(0) + Vector3(0.0, 1.20, 0.35), "signage_desk.png")
	elif "--capture-signage-intake" in OS.get_cmdline_user_args() or "--capture-signage-intake" in OS.get_cmdline_args():
		_capture_signage_preview(Vector3(9.55, 1.35, 5.25), "signage_intake.png")
	elif "--capture-campaign-title" in OS.get_cmdline_user_args() or "--capture-campaign-title" in OS.get_cmdline_args():
		_capture_campaign_title_preview()
	elif "--capture-campaign-report" in OS.get_cmdline_user_args() or "--capture-campaign-report" in OS.get_cmdline_args():
		_capture_campaign_report_preview()
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


func boot_timing_snapshot() -> Dictionary:
	var snapshot := _boot_timing.duplicate(true)
	if _office_storytelling != null:
		snapshot["optional_visuals"] = _office_storytelling.optional_visual_build_snapshot()
	return snapshot


func _on_optional_storytelling_finished() -> void:
	# Refresh the browser diagnostic once background campus construction is
	# complete. This remains observability-only; gameplay does not depend on it.
	_publish_web_diagnostic_state(_simulation.snapshot())


func _ensure_peck_assist_input_action() -> void:
	OfficeActionCatalogScript.install_defaults()


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
	if _camera_controller != null:
		_camera_controller.set_reduced_motion(reduced_motion)
		_camera_controller.set_high_contrast(bool(_player_preferences.get("high_contrast", false)))
	if _office_atmosphere != null:
		_office_atmosphere.set_reduced_motion(reduced_motion)
	if _routing_ui != null and _routing_ui.has_method("set_reduced_motion"):
		_routing_ui.call("set_reduced_motion", reduced_motion)
	if _campaign_ui != null and _campaign_ui.has_method("set_reduced_motion"):
		_campaign_ui.call("set_reduced_motion", reduced_motion)
	var color_vision_mode := StringName(String(_player_preferences.get("color_vision_mode", "standard")))
	if _routing_ui != null and _routing_ui.has_method("set_color_vision_mode"):
		_routing_ui.call("set_color_vision_mode", color_vision_mode)
	if _workstation_feedback != null and _workstation_feedback.has_method("set_color_vision_mode"):
		_workstation_feedback.call("set_color_vision_mode", color_vision_mode)
	if _office_storytelling != null and _office_storytelling.has_method("set_color_vision_mode"):
		_office_storytelling.call("set_color_vision_mode", color_vision_mode)
	_apply_visual_quality(StringName(String(_player_preferences.get("visual_quality", "balanced"))))
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
	if _environment != null:
		_environment.adjustment_contrast = 1.16 if high_contrast else 1.08
		_environment.adjustment_saturation = 1.0 if high_contrast else 0.94


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


func _apply_visual_quality(quality: StringName) -> void:
	var viewport := get_viewport()
	match quality:
		&"low":
			viewport.scaling_3d_scale = 0.82
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			if _office_sun != null:
				_office_sun.shadow_enabled = false
			if _office_atmosphere != null:
				_office_atmosphere.set_atmosphere_enabled(false)
		&"high":
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_4X
			if _office_sun != null:
				_office_sun.shadow_enabled = true
				_office_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			if _office_atmosphere != null:
				_office_atmosphere.set_atmosphere_enabled(true)
		_:
			viewport.scaling_3d_scale = 1.0
			viewport.msaa_3d = Viewport.MSAA_DISABLED
			if _office_sun != null:
				_office_sun.shadow_enabled = true
				_office_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
			if _office_atmosphere != null:
				_office_atmosphere.set_atmosphere_enabled(true)


func _current_binding_labels() -> Dictionary:
	var result: Dictionary = {}
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		result[action] = OfficeActionCatalogScript.binding_label(action)
	return result


func _action_hint(action: StringName) -> String:
	return OfficeActionCatalogScript.binding_label(action)


func _refresh_action_prompts() -> void:
	if _settings_button != null:
		_settings_button.text = "SETTINGS  [%s]" % _action_hint(&"open_settings")
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
	if _settings_ui == null:
		return
	if _settings_ui.is_open():
		_on_settings_close_requested()
		return
	_settings_previous_speed = _clock.speed_index if _clock != null else 0
	_settings_holds_speed = true
	_settings_prior_focus_owner = get_viewport().gui_get_focus_owner()
	if _clock != null:
		_clock.set_speed(0)
	_settings_ui.show_settings(
		_player_preferences,
		_current_binding_labels(),
		_campaign_store != null and _has_verified_campaign_checkpoint,
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
	_player_preferences = PlayerPreferencesStoreScript.sanitize(preferences)
	_apply_player_preferences()
	_save_player_preferences("Preference filed and applied.")


func _on_preferences_reset_requested() -> void:
	OfficeActionCatalogScript.reset_all()
	_player_preferences = PlayerPreferencesStoreScript.defaults()
	_apply_player_preferences()
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


func _load_web_player_preferences() -> Dictionary:
	if not OS.has_feature("web"):
		_web_preferences_mirror_status = "not_applicable"
		return {}
	var bridge := JavaScriptBridge.get_interface("__pecking_order_preferences_bridge")
	if bridge == null:
		_web_preferences_mirror_status = "bridge_unavailable"
		return {}
	var payload_value: Variant = bridge.call("load")
	if typeof(payload_value) != TYPE_STRING:
		_web_preferences_mirror_status = "bridge_invalid_result"
		return {}
	var payload := String(payload_value)
	if payload.is_empty():
		_web_preferences_mirror_status = "missing"
		return {}
	var preferences: Dictionary = _web_preferences_mirror.decode(payload)
	if preferences.is_empty():
		_web_preferences_mirror_status = "invalid"
		push_warning(_web_preferences_mirror.last_error)
		return {}
	_web_preferences_mirror_status = "loaded"
	return preferences


func _save_web_player_preferences() -> bool:
	if not OS.has_feature("web"):
		_web_preferences_mirror_status = "not_applicable"
		return true
	var payload: String = _web_preferences_mirror.encode(_player_preferences)
	if payload.is_empty():
		_web_preferences_mirror_status = "failed"
		push_warning(_web_preferences_mirror.last_error)
		return false
	var bridge := JavaScriptBridge.get_interface("__pecking_order_preferences_bridge")
	if bridge == null:
		_web_preferences_mirror_status = "bridge_unavailable"
		return false
	var saved := bool(bridge.call("save", payload))
	_web_preferences_mirror_status = "saved" if saved else "failed"
	return saved


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


func _install_web_checkpoint_bridge() -> void:
	if not OS.has_feature("web"):
		return
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return
	_web_checkpoint_flush_callback = JavaScriptBridge.create_callback(
		_on_web_checkpoint_flush_requested
	)
	window.set("__pecking_order_request_checkpoint", _web_checkpoint_flush_callback)
	_web_career_backup_offer_callback = JavaScriptBridge.create_callback(
		_on_web_career_backup_offered
	)
	window.set("__pecking_order_offer_backup", _web_career_backup_offer_callback)
	_web_mobile_action_callback = JavaScriptBridge.create_callback(
		_on_web_mobile_action_requested
	)
	window.set("__pecking_order_mobile_action", _web_mobile_action_callback)
	_web_focus_pause_callback = JavaScriptBridge.create_callback(
		_on_web_focus_pause_requested
	)
	window.set("__pecking_order_set_focus_paused", _web_focus_pause_callback)


func _on_web_checkpoint_flush_requested(arguments: Array) -> void:
	var reason := "web_lifecycle"
	if not arguments.is_empty():
		var requested_reason := String(arguments[0]).strip_edges()
		if not requested_reason.is_empty():
			reason = requested_reason
	_request_lifecycle_checkpoint(reason)


func _on_web_career_backup_offered(arguments: Array) -> void:
	if _settings_ui == null or not _settings_ui.is_open():
		return
	var json_text := String(arguments[0]) if arguments.size() > 0 else ""
	var source_label := String(arguments[1]) if arguments.size() > 1 else "browser backup"
	var bridge_error := String(arguments[2]).strip_edges() if arguments.size() > 2 else ""
	if not bridge_error.is_empty():
		_settings_ui.complete_career_backup_import(
			false,
			"Career restore held: %s" % bridge_error.substr(0, CHECKPOINT_ERROR_LIMIT),
		)
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	_settings_ui.stage_career_backup_import(json_text, source_label)
	# The Settings surface has paused the floor, so no simulation tick will
	# refresh the wrapper's live/assistive mirror after the browser file arrives.
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_web_mobile_action_requested(arguments: Array) -> void:
	if arguments.is_empty():
		return
	var action := StringName(String(arguments[0]).strip_edges().to_lower())
	# This bridge is deliberately allow-listed. It exposes no arbitrary method,
	# property, file, or expression access to the page.
	match action:
		&"settings":
			_on_settings_requested()
		&"overview":
			if _settings_ui != null and _settings_ui.is_open():
				_on_settings_close_requested()
			elif _flockwatch_open:
				_set_flockwatch_open(false, true)
			elif _camera_controller != null and not _blocking_management_surface_open():
				_camera_controller.show_overview()
		&"flockwatch":
			if (
				(_settings_ui == null or not _settings_ui.is_open())
				and not _blocking_management_surface_open()
			):
				_on_flockwatch_pressed()
		&"zoom_in", &"zoom_out":
			if (
				_camera_controller != null
				and _camera_controller.is_processing_unhandled_input()
				and not _blocking_management_surface_open()
			):
				_camera_controller.request_zoom_step(action == &"zoom_in")
		&"cycle_hen":
			if _flockwatch_open and _flockwatch_navigation != null:
				_flockwatch_navigation.cycle_page(1, true)
			elif (
				_camera_controller != null
				and _camera_controller.is_processing_unhandled_input()
				and not _blocking_management_surface_open()
			):
				_camera_controller.cycle_worker(1)
		&"pause":
			if not _blocking_management_surface_open() and not _flockwatch_open:
				_on_pause_requested()
		&"peck_assist":
			if not _flockwatch_open and not _peck_assist_input_blocked():
				_request_peck_assist_from_input()
		_:
			return
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_web_focus_pause_requested(arguments: Array) -> void:
	if arguments.is_empty() or typeof(arguments[0]) != TYPE_BOOL:
		return
	var unfocused := bool(arguments[0])
	_set_audio_focus_paused(unfocused)
	_set_application_focus_paused(unfocused)
	if unfocused:
		_request_lifecycle_checkpoint("web_focus_out")


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


func _unhandled_input(event: InputEvent) -> void:
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
	if _is_action_press(event, PECK_ASSIST_ACTION):
		if not _peck_assist_input_blocked():
			_request_peck_assist_from_input()
		get_viewport().set_input_as_handled()
		return
	if _is_action_press(event, &"pause_simulation"):
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


func _is_managed_action_press(event: InputEvent) -> bool:
	for action: StringName in OfficeActionCatalogScript.managed_actions():
		if _is_action_press(event, action):
			return true
	return false


func _build_environment() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.background_color = Color("172029")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_color = Color("b9c9c8")
	_environment.ambient_light_energy = 0.52
	_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_environment.tonemap_exposure = 1.08
	_environment.adjustment_enabled = true
	_environment.adjustment_brightness = 1.02
	_environment.adjustment_contrast = 1.08
	_environment.adjustment_saturation = 0.94
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)

	_office_sun = DirectionalLight3D.new()
	_office_sun.name = "OfficeSun"
	_office_sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	_office_sun.light_color = Color("f7eed8")
	_office_sun.light_energy = 0.78
	_office_sun.shadow_enabled = true
	_office_sun.shadow_opacity = 0.48
	_office_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	_office_sun.directional_shadow_max_distance = 60.0
	_office_sun.directional_shadow_blend_splits = true
	_office_sun.shadow_bias = 0.07
	_office_sun.shadow_normal_bias = 1.1
	add_child(_office_sun)

	# Compatibility renderer friendly fake GI: a diffuse-only upward bounce plus
	# three tight, shadowless fluorescent pools instead of expensive real-time GI.
	_bounce_light = DirectionalLight3D.new()
	_bounce_light.name = "CarpetBounce"
	_bounce_light.rotation = _office_sun.rotation + Vector3(PI, 0.0, 0.0)
	_bounce_light.light_color = Color("7f9a91")
	_bounce_light.light_energy = 0.16
	_bounce_light.light_specular = 0.0
	_bounce_light.shadow_enabled = false
	add_child(_bounce_light)

	for light_index in 3:
		var fill := OmniLight3D.new()
		fill.name = "FluorescentFill_%d" % light_index
		fill.position = Vector3([-6.0, 0.0, 6.0][light_index], 3.15, -0.5)
		fill.light_color = Color("e8dfc2")
		fill.light_energy = OFFICE_FILL_LIGHT_ENERGY
		fill.light_specular = 0.25
		fill.omni_range = 5.6
		fill.omni_attenuation = 1.45
		fill.shadow_enabled = false
		add_child(fill)
		_office_fill_lights.append(fill)

	_management_camera = Camera3D.new()
	_management_camera.name = "ManagementCamera"
	_management_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_management_camera.size = CORE_OVERVIEW_SIZE
	_management_camera.position = CORE_OVERVIEW_POSITION
	_management_camera.near = 0.2
	_management_camera.far = 65.0
	_management_camera.current = true
	add_child(_management_camera)
	_management_camera.look_at(CORE_OVERVIEW_TARGET)


func _build_physical_presentation_roots() -> void:
	_office_physical_presentation = Node3D.new()
	_office_physical_presentation.name = "OfficePhysicalPresentation"
	_office_physical_presentation.set_meta(&"visual_only", true)
	_office_physical_presentation.set_meta(&"collision_free", true)
	_office_physical_presentation.set_meta(&"navigation_free", true)
	add_child(_office_physical_presentation)

	_core_office_presentation = _physical_presentation_root("CoreOfficePresentation", true)
	_dormant_west_presentation = _physical_presentation_root("DormantWestPresentation", false)
	_west_perch_04_presentation = _physical_presentation_root("WestPerch04Presentation", false)
	_west_perch_05_presentation = _physical_presentation_root("WestPerch05Presentation", false)
	_archive_presentation = _physical_presentation_root("ArchivePresentation", false)
	_intake_presentation = _physical_presentation_root("IntakePresentation", true)
	_build_west_lease_partition()

	# Thin, collision-free floor insets make the generous safe desk clearances read
	# as deliberate commissioned neighborhoods instead of one vacant carpet sea.
	_build_commissioned_floor_inset(
		_core_office_presentation,
		"OpeningPodFloorInset",
		Vector3(3.25, 0.0, -0.05),
		Vector2(13.10, 12.35),
		Color("35474b"),
	)
	_build_commissioned_floor_inset(
		_west_perch_04_presentation,
		"WestPerch04FloorInset",
		desk_position(4),
		Vector2(5.15, 5.10),
		Color("34464a"),
	)
	_build_commissioned_floor_inset(
		_west_perch_05_presentation,
		"WestPerch05FloorInset",
		desk_position(5),
		Vector2(5.15, 5.10),
		Color("34464a"),
	)
	# Staffing context exposes a quiet brass threshold and the existing boxed
	# authorization marker. It never constructs a fake desk or route obstacle.
	for seam_index in 4:
		var threshold := _add_box(
			_dormant_west_presentation,
			"WestAuthorizationThreshold_%02d" % seam_index,
			Vector3(0.07, 0.010, 1.10),
			Vector3(-3.42, 0.017, -4.65 + seam_index * 3.10),
			Color("9b8150"),
		)
		threshold.material_override = _material(Color("9b8150"), 0.48, 0.28)
		threshold.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_west_lease_partition() -> void:
	# A low, visual-only acoustic partition gives the opening pod a believable
	# occupied boundary. It leaves the main aisle open and is removed as soon as
	# the first west perch is commissioned; no route or collision owns this art.
	_west_lease_partition = Node3D.new()
	_west_lease_partition.name = "WestLeasePartition"
	_west_lease_partition.set_meta(&"visual_only", true)
	_west_lease_partition.set_meta(&"collision_free", true)
	_west_lease_partition.set_meta(&"navigation_free", true)
	_core_office_presentation.add_child(_west_lease_partition)
	var panel_color := Color("405154")
	var frame_color := Color("26363a")
	var cap_color := Color("9a8252")
	var panel_centers := [-5.00, 4.00]
	for panel_index in panel_centers.size():
		var panel_z: float = panel_centers[panel_index]
		var panel := _add_box(
			_west_lease_partition,
			"WestLeasePartitionPanel_%02d" % panel_index,
			Vector3(0.105, 1.58, 2.65),
			Vector3(-3.39, 0.80, panel_z),
			panel_color.lightened(0.025 * float(panel_index % 2)),
		)
		panel.material_override = _material(
			panel_color.lightened(0.025 * float(panel_index % 2)),
			0.88,
		)
		_add_box(
			_west_lease_partition,
			"WestLeasePartitionCap_%02d" % panel_index,
			Vector3(0.15, 0.055, 2.75),
			Vector3(-3.39, 1.61, panel_z),
			cap_color,
		).material_override = _material(cap_color, 0.58, 0.20)
		for post_index in 2:
			var post_z := -1.0 if post_index == 0 else 1.0
			_add_box(
				_west_lease_partition,
				"WestLeasePartitionPost_%02d_%d" % [panel_index, post_index],
				Vector3(0.16, 1.68, 0.075),
				Vector3(-3.39, 0.84, panel_z + post_z * 1.35),
				frame_color,
			).material_override = _material(frame_color, 0.68, 0.16)
		for foot_index in 2:
			var foot_z := -1.0 if foot_index == 0 else 1.0
			_add_box(
				_west_lease_partition,
				"WestLeasePartitionFoot_%02d_%d" % [panel_index, foot_index],
				Vector3(0.62, 0.055, 0.18),
				Vector3(-3.25, 0.035, panel_z + foot_z * 1.16),
				frame_color,
			).material_override = _material(frame_color, 0.54, 0.24)


func _physical_presentation_root(root_name: String, initially_visible: bool) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	root.visible = initially_visible
	root.set_meta(&"visual_only", true)
	root.set_meta(&"collision_free", true)
	root.set_meta(&"navigation_free", true)
	_office_physical_presentation.add_child(root)
	return root


func _build_commissioned_floor_inset(
	parent: Node3D,
	part_name: String,
	center: Vector3,
	size: Vector2,
	color: Color,
) -> void:
	var inset := _add_box(
		parent,
		part_name,
		Vector3(size.x, 0.014, size.y),
		Vector3(center.x, -0.011, center.z),
		color,
	)
	inset.material_override = _material(color, 0.96)
	inset.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var edge_color := Color("766b52")
	for side_z in [-1.0, 1.0]:
		var edge_z := _add_box(
			parent,
			"%sEdge" % part_name,
			Vector3(size.x, 0.009, 0.045),
			Vector3(center.x, 0.001, center.z + side_z * size.y * 0.5),
			edge_color,
		)
		edge_z.material_override = _material(edge_color, 0.58, 0.18)
		edge_z.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side_x in [-1.0, 1.0]:
		var edge_x := _add_box(
			parent,
			"%sEdge" % part_name,
			Vector3(0.045, 0.009, size.y),
			Vector3(center.x + side_x * size.x * 0.5, 0.001, center.z),
			edge_color,
		)
		edge_x.material_override = _material(edge_color, 0.58, 0.18)
		edge_x.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _window_presentation_parent(window_x: float, core_parent: Node3D) -> Node3D:
	if is_equal_approx(window_x, -5.45):
		return _west_perch_04_presentation
	if is_equal_approx(window_x, -9.10):
		return _west_perch_05_presentation
	return core_parent


func _build_office() -> void:
	_build_physical_presentation_roots()
	var shell := Node3D.new()
	shell.name = "OfficeShell"
	_core_office_presentation.add_child(shell)
	_add_box(shell, "Carpet", Vector3(OFFICE_WIDTH, 0.18, OFFICE_DEPTH), Vector3(0.0, -0.11, 0.0), Color("303e44"))
	_add_box(shell, "BackWall", Vector3(OFFICE_WIDTH, 3.65, 0.2), Vector3(0.0, 1.77, -8.9), Color("d0c9b5"))
	_add_box(shell, "LeftWall", Vector3(0.2, 3.65, OFFICE_DEPTH), Vector3(-11.9, 1.77, 0.0), Color("c2bcaa"))
	_add_box(shell, "BaseboardBack", Vector3(23.5, 0.15, 0.12), Vector3(0.0, 0.16, -8.76), Color("48545a"))
	_add_box(shell, "BaseboardLeft", Vector3(0.12, 0.15, 17.5), Vector3(-11.76, 0.16, 0.0), Color("48545a"))
	_add_box(shell, "ExecutiveStrip", Vector3(23.5, 0.09, 0.16), Vector3(0.0, 2.7, -8.74), Color("765540"))
	_add_box(shell, "MainAisleRunner", Vector3(22.6, 0.026, 1.65), Vector3(0.0, 0.005, MAIN_AISLE_Z), Color("465b62"))
	for lane_x in [-7.95, -1.95, 4.05]:
		var lane_parent := _west_perch_04_presentation if is_equal_approx(lane_x, -7.95) else shell
		_add_box(lane_parent, "AccessLane", Vector3(1.3, 0.018, 11.2), Vector3(lane_x, 0.008, 0.55), Color("374b51"))

	var window_batches: Dictionary = {}
	for window_x in [-9.1, -5.45, -1.8, 1.85, 5.5, 9.15]:
		var window_parent := _window_presentation_parent(window_x, shell)
		if not window_batches.has(window_parent):
			window_batches[window_parent] = {
				"frames": [] as Array[Transform3D],
				"blinds": [] as Array[Transform3D],
				"radiator_fins": [] as Array[Transform3D],
			}
		var batches := window_batches[window_parent] as Dictionary
		var frame_transforms := batches["frames"] as Array[Transform3D]
		var blind_transforms := batches["blinds"] as Array[Transform3D]
		var fin_transforms := batches["radiator_fins"] as Array[Transform3D]
		var window_key := int(round((window_x + 12.0) * 10.0))
		_add_box(window_parent, "Window", Vector3(2.75, 1.38, 0.045), Vector3(window_x, 1.83, -8.76), Color("4d7180"))
		frame_transforms.append(_box_batch_transform(Vector3(2.9, 0.075, 0.075), Vector3(window_x, 2.56, -8.70)))
		_add_box(window_parent, "WindowSill", Vector3(2.9, 0.075, 0.18), Vector3(window_x, 1.10, -8.67), Color("e0dac6"))
		frame_transforms.append(_box_batch_transform(Vector3(0.075, 1.46, 0.085), Vector3(window_x - 1.41, 1.83, -8.70)))
		frame_transforms.append(_box_batch_transform(Vector3(0.075, 1.46, 0.085), Vector3(window_x + 1.41, 1.83, -8.70)))
		_add_box(window_parent, "WindowMullion_%d" % window_key, Vector3(0.065, 1.30, 0.075), Vector3(window_x, 1.83, -8.68), Color("34464e"))
		_add_box(window_parent, "BlindValance", Vector3(2.62, 0.13, 0.12), Vector3(window_x, 2.43, -8.62), Color("c0bba9"))
		for blind_y in [2.18, 1.92]:
			blind_transforms.append(_box_batch_transform(Vector3(2.55, 0.045, 0.075), Vector3(window_x, blind_y, -8.63)))
		_add_box(window_parent, "Radiator_%d" % window_key, Vector3(2.25, 0.53, 0.24), Vector3(window_x, 0.59, -8.54), Color("707b7e"))
		for fin_x in [-0.72, -0.36, 0.0, 0.36, 0.72]:
			fin_transforms.append(_box_batch_transform(Vector3(0.075, 0.40, 0.055), Vector3(window_x + fin_x, 0.59, -8.39)))
	for parent_value in window_batches:
		var batch_parent := parent_value as Node3D
		var batches := window_batches[batch_parent] as Dictionary
		_add_box_multimesh(batch_parent, "WindowFrameBatch", batches["frames"] as Array[Transform3D], Color("34464e"))
		_add_box_multimesh(batch_parent, "WindowBlindSlatBatch", batches["blinds"] as Array[Transform3D], Color("b7b5aa"))
		_add_box_multimesh(batch_parent, "WindowRadiatorFinBatch", batches["radiator_fins"] as Array[Transform3D], Color("aab2ae"))

	_build_architecture_detail(shell)
	_build_office_decor(shell)
	_build_window_farm_view(shell)
	_build_floor_story(shell)
	_build_wall_story(_archive_presentation, shell)
	_build_feed_party_station()

	var desks := Node3D.new()
	desks.name = "ClaimsDesks"
	add_child(desks)
	var initial_snapshot := _simulation.snapshot()
	var initial_capacity := _office_capacity_from_snapshot(initial_snapshot)
	for index in MAXIMUM_OFFICE_CAPACITY:
		var position := desk_position(index)
		_desk_positions.append(position)
		_build_workstation(desks, index, position)
		_build_capacity_authorization_marker(desks, index, position)
	_displayed_office_capacity = initial_capacity
	_apply_office_capacity_visibility(initial_capacity, false)
	_workstation_feedback = WorkstationFeedbackScript.new() as WorkstationFeedback
	_workstation_feedback.name = "WorkstationFeedback"
	add_child(_workstation_feedback)
	_workstation_feedback.configure(desks)

	var intake := Node3D.new()
	intake.name = "ClaimIntake"
	_intake_presentation.add_child(intake)
	_add_box(intake, "IntakeCounter", Vector3(2.25, 1.0, 2.2), Vector3(9.55, 0.5, 5.35), Color("735f4d"))
	_add_box(intake, "IntakeTop", Vector3(2.45, 0.14, 2.4), Vector3(9.55, 1.05, 5.35), Color("a58b69"))
	_build_intake_detail(intake)
	var basket := Node3D.new()
	basket.name = "ExecutiveEggBasket"
	_intake_presentation.add_child(basket)
	_add_box(basket, "BasketInterior", Vector3(2.02, 0.42, 1.48), Vector3(9.4, 0.32, -6.85), Color("694833"))
	_add_box(basket, "PresentationPlinth", Vector3(2.7, 0.18, 2.1), Vector3(9.4, 0.10, -6.85), Color("c3ab82"))
	var credit_slip_host := _build_presentation_detail(basket)
	EnvironmentalSignageScript.add_panel(
		credit_slip_host, "PresentationPlaqueText", "FARMER CREDIT",
		Vector3(0.0, 0.0, 0.057), Vector2(0.96, 0.075),
		Color("a87849"), Color("49372a"), Vector3.ZERO,
		11, 0.0021, &"utility", &"stencil"
	)

	_egg_layer = Node3D.new()
	_egg_layer.name = "EggsInTransit"
	add_child(_egg_layer)

	_workers_node = Node3D.new()
	_workers_node.name = "Workers"
	add_child(_workers_node)
	var arrival_order := 0
	for worker_value in initial_snapshot.get("workers", []):
		var worker_data := worker_value as Dictionary
		if not _is_worker_employed(worker_data):
			continue
		_spawn_worker_view(worker_data, arrival_order)
		arrival_order += 1
	_refresh_workstation_nameplates(initial_snapshot)

	_management_presence = ManagementPresenceScript.new() as ManagementPresence
	add_child(_management_presence)
	_management_presence.review_finished.connect(_on_farmer_review_finished)

	_camera_controller = ManagementCameraControllerScript.new() as ManagementCameraController
	_camera_controller.name = "ManagementCameraController"
	add_child(_camera_controller)
	_camera_controller.configure(_management_camera, _worker_views, CORE_OVERVIEW_TARGET)
	_camera_controller.focus_changed.connect(_on_camera_focus_changed)


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
	return Vector3(-10.25 + (index % 2) * 0.65, 0.0, -0.75 + (index / 2) * 0.68)


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
	return [
		Vector3(lane_x, 0.0, chair.z),
		Vector3(lane_x, 0.0, 0.0),
		break_position(index),
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


func _build_architecture_detail(parent: Node3D) -> void:
	_add_box(parent, "CrownMoldingBack", Vector3(23.55, 0.13, 0.16), Vector3(0.0, 3.48, -8.72), Color("e4deca"))
	_add_box(parent, "CrownMoldingLeft", Vector3(0.16, 0.13, 17.55), Vector3(-11.72, 3.48, 0.0), Color("ddd6c3"))
	_add_box(parent, "CableChannelBack", Vector3(23.1, 0.16, 0.13), Vector3(0.0, 0.36, -8.69), Color("657176"))

	# Wall-mounted light boxes add warm depth without floating over or obscuring workers.
	for light_index in 3:
		var light_x: float = [-7.6, 0.0, 7.6][light_index]
		var light_parent := _west_perch_04_presentation if light_index == 0 else parent
		var light_y := 3.44 if light_index == 1 else 3.20
		var fixture_width := 1.75 if light_index == 1 else 3.25
		var lens_width := 1.48 if light_index == 1 else 2.92
		var frame_z := -8.69 if light_index == 1 else -8.63
		var lens_z := -8.665 if light_index == 1 else -8.53
		_add_box(light_parent, "WallLightFrame", Vector3(fixture_width, 0.20, 0.16), Vector3(light_x, light_y, frame_z), Color("425057"))
		var lens := _add_box(light_parent, "WallLightLens_%d" % light_index, Vector3(lens_width, 0.08, 0.08), Vector3(light_x, light_y - 0.01, lens_z), Color("f4dfaa"))
		lens.material_override = _emissive_material(Color("f4dfaa"), 0.55)
		if light_index == 1:
			# The compact center fixture is a deliberate picture light clamped to
			# the bureau fascia, not another floating strip crossing its copy.
			for arm_x in [-0.58, 0.58]:
				var arm_name := "IdentityLightArmLeft" if arm_x < 0.0 else "IdentityLightArmRight"
				_add_box(parent, arm_name, Vector3(0.055, 0.20, 0.055), Vector3(arm_x, 3.36, -8.67), Color("6d6757"))

	EnvironmentalSignageScript.add_architectural_identity(
		parent,
		"BureauIdentity",
		"EGG YIELD BUREAU",
		"CLUTCH INTAKE & CREDIT",
		Vector3(0.0, 3.00, -8.63),
		Vector2(6.40, 0.74)
	)

	var clock_rim := _add_cylinder(parent, "OfficeClockRim", Vector3(9.95, 3.03, -8.57), 0.43, 0.08, Color("39474d"))
	clock_rim.rotation_degrees.x = 90.0
	clock_rim.material_override = _material(Color("39474d"), 0.34, 0.48)
	var clock_face := _add_cylinder(parent, "OfficeClockFace", Vector3(9.95, 3.03, -8.50), 0.36, 0.055, Color("e7e0cd"))
	clock_face.rotation_degrees.x = 90.0
	_add_box(parent, "OfficeClockHourHand", Vector3(0.19, 0.045, 0.035), Vector3(10.02, 3.03, -8.45), Color("343d40"))
	var minute_hand := _add_box(parent, "OfficeClockMinuteHand", Vector3(0.04, 0.25, 0.035), Vector3(9.95, 3.12, -8.44), Color("343d40"))
	minute_hand.rotation_degrees.z = -18.0


func _build_intake_detail(parent: Node3D) -> void:
	var front_inset := _add_box(
		parent,
		"IntakeFrontInset",
		Vector3(1.75, 0.58, 0.06),
		Vector3(9.55, 0.52, 6.48),
		Color("4b4037"),
	)
	EnvironmentalSignageScript.add_panel(
		front_inset,
		"IntakeIdentityPlaque",
		"FARMER COLLECTION",
		Vector3(0.0, -0.15, 0.033),
		Vector2(1.36, 0.16),
		Color("4b4037"),
		Color("d7c99f"),
		Vector3.ZERO,
		16,
		0.0038,
		&"secondary",
		&"stencil",
	)
	for slot_x in [-0.52, 0.0, 0.52]:
		_add_box(parent, "IntakeMailSlot", Vector3(0.38, 0.09, 0.035), Vector3(9.55 + slot_x, 0.58, 6.53), Color("d4b46c"))

	for layer_index in 5:
		var layer_color := Color("dcd7c7") if layer_index % 2 == 0 else Color("c8d2ce")
		_add_box(
			parent,
			"IntakeClaimBundle",
			Vector3(0.86, 0.035, 0.98),
			Vector3(9.50 + layer_index * 0.018, 1.17 + layer_index * 0.038, 5.35 - layer_index * 0.012),
			layer_color
		)
	_add_box(parent, "IntakeBundleBand", Vector3(0.16, 0.24, 1.02), Vector3(9.55, 1.25, 5.35), Color("a3473b"))

	var bell_base := _add_cylinder(parent, "IntakeBellBase", Vector3(10.35, 1.17, 4.77), 0.18, 0.06, Color("735f4d"))
	bell_base.material_override = _material(Color("735f4d"), 0.34, 0.52)
	var bell := _add_sphere(parent, "IntakeServiceBell", Vector3(10.35, 1.25, 4.77), Vector3(0.28, 0.18, 0.28), Color("c49a4b"))
	bell.material_override = _material(Color("c49a4b"), 0.26, 0.72)
	_add_cylinder(parent, "IntakeStampHandle", Vector3(8.76, 1.30, 4.92), 0.08, 0.28, Color("6f3d30"))
	_add_box(parent, "IntakeStampPad", Vector3(0.34, 0.06, 0.30), Vector3(8.76, 1.17, 4.92), Color("2d373b"))

	# A tiny weighing/candling station makes the farmer's review area read as egg
	# logistics rather than a generic reception desk.
	_add_box(parent, "EggScaleBase", Vector3(0.58, 0.12, 0.48), Vector3(10.10, 1.17, 5.73), Color("506269"))
	_add_cylinder(parent, "EggScaleDial", Vector3(10.10, 1.42, 5.79), 0.20, 0.10, Color("e5dfca")).rotation_degrees.x = 90.0
	_add_box(parent, "EggScaleNeedle", Vector3(0.025, 0.15, 0.025), Vector3(10.10, 1.46, 5.73), Color("a4493e")).rotation_degrees.z = -24.0
	_add_cylinder(parent, "EggScalePan", Vector3(10.10, 1.34, 5.46), 0.26, 0.06, Color("b6beb9"))
	_add_cylinder(parent, "CandlingLampStem", Vector3(9.02, 1.42, 5.80), 0.045, 0.48, Color("4d5557"))
	var candling_lamp := _add_sphere(parent, "CandlingLamp", Vector3(9.02, 1.70, 5.80), Vector3(0.25, 0.17, 0.25), Color("e3bd66"))
	candling_lamp.material_override = _emissive_material(Color("e3bd66"), 0.75)

	for carton_index in 2:
		_add_box(parent, "IntakeEggCarton", Vector3(0.72, 0.10, 0.38), Vector3(8.95, 1.16 + carton_index * 0.10, 5.55), Color("aab49f"))
		for cup_index in 3:
			_add_sphere(parent, "CartonCup", Vector3(8.72 + cup_index * 0.23, 1.23 + carton_index * 0.10, 5.55), Vector3(0.09, 0.055, 0.10), Color("859283"))


func _build_presentation_detail(parent: Node3D) -> MeshInstance3D:
	var credit_slip_host: MeshInstance3D = null
	for slat_y in [0.24, 0.42, 0.60]:
		var front_slat := _add_box(parent, "BasketFrontSlat", Vector3(2.22, 0.11, 0.10), Vector3(9.4, slat_y, -5.99), Color("a87849"))
		if is_equal_approx(slat_y, 0.42):
			front_slat.name = "BasketFrontSlatCreditHost"
			credit_slip_host = front_slat
		_add_box(parent, "BasketBackSlat", Vector3(2.22, 0.11, 0.10), Vector3(9.4, slat_y, -7.71), Color("8d623f"))
	for side_x in [8.31, 10.49]:
		for slat_y in [0.24, 0.42, 0.60]:
			_add_box(parent, "BasketSideSlat", Vector3(0.10, 0.11, 1.72), Vector3(side_x, slat_y, -6.85), Color("986b44"))
		_add_box(parent, "BasketHandlePost", Vector3(0.12, 1.08, 0.12), Vector3(side_x, 0.88, -6.85), Color("6f4d36"))
	_add_box(parent, "BasketHandle", Vector3(2.30, 0.13, 0.13), Vector3(9.4, 1.40, -6.85), Color("6f4d36"))
	# The basket begins physically empty. OfficeStorytelling now owns every visible
	# clutch egg and only fills these cups after a real seated-hen delivery lands.
	return credit_slip_host


func _build_office_decor(parent: Node3D) -> void:
	# Decor is kept in perimeter alcoves, leaving every circulation lane unobstructed.
	_add_box(parent, "WellnessRug", Vector3(4.0, 0.03, 4.4), Vector3(-9.8, 0.01, 0.0), Color("54655e"))
	_add_box(parent, "WaterCoolerBase", Vector3(0.68, 0.95, 0.62), Vector3(-11.05, 0.48, -3.15), Color("c7d0cd"))
	_add_cylinder(parent, "WaterJug", Vector3(-11.05, 1.25, -3.15), 0.26, 0.62, Color("73959e"))
	_add_box(parent, "CoolerControlPanel", Vector3(0.45, 0.22, 0.05), Vector3(-11.05, 0.70, -2.82), Color("45565c"))
	_add_box(parent, "CoolerTapCold", Vector3(0.12, 0.10, 0.13), Vector3(-11.18, 0.71, -2.75), Color("477b91"))
	_add_box(parent, "CoolerTapWarm", Vector3(0.12, 0.10, 0.13), Vector3(-10.92, 0.71, -2.75), Color("a45d48"))
	_add_box(parent, "CoolerDripTray", Vector3(0.43, 0.06, 0.20), Vector3(-11.05, 0.49, -2.79), Color("536168"))
	for cup_index in 3:
		_add_cylinder(parent, "PaperCup", Vector3(-10.62, 0.96 + cup_index * 0.10, -3.13), 0.075, 0.12, Color("e2ddce"))
	EnvironmentalSignageScript.add_panel(
		parent, "WellnessZoneLabel", "WELLNESS ROOST\nBREAKS · 7 MIN",
		Vector3(-11.798, 1.72, -3.10), Vector2(1.18, 0.40),
		Color("3d6259"), Color("eadcb6"), Vector3(0.0, 90.0, 0.0),
		15, 0.0044, &"utility", &"room"
	)

	# A wall-mounted visibility board gives the cutaway side of the room a
	# detailed focal point while keeping the wellness/feed floor completely open.
	var pipeline_parent := _west_perch_05_presentation
	_add_box(pipeline_parent, "ClaimsPipelineBoard", Vector3(0.075, 1.65, 3.30), Vector3(-11.70, 2.05, 3.60), Color("2b3a3f"))
	var pipeline_inset := _add_box(
		pipeline_parent,
		"ClaimsPipelineInset",
		Vector3(0.040, 1.38, 3.02),
		Vector3(-11.64, 2.03, 3.60),
		Color("d4ceb9"),
	)
	var pipeline_heights: Array[float] = [0.38, 0.70, 0.50, 0.92, 0.62, 1.08]
	var pipeline_colors: Array[Color] = [Color("477681"), Color("6f8a72"), Color("c39a4c")]
	for bar_index in 6:
		var bar_height: float = pipeline_heights[bar_index]
		var bar_color: Color = pipeline_colors[bar_index % pipeline_colors.size()]
		_add_box(
			pipeline_parent,
			"ClaimsPipelineBar",
			Vector3(0.035, bar_height, 0.25),
			Vector3(-11.60, 1.45 + bar_height * 0.5, 2.72 + bar_index * 0.35),
			bar_color
		)
	EnvironmentalSignageScript.add_panel(
		pipeline_inset, "ClaimsPipelineLabel", "CLUTCH FLOW",
		Vector3(0.024, 0.60, 0.0), Vector2(1.78, 0.32),
		Color("d4ceb9"), Color("34494e"), Vector3(0.0, 90.0, 0.0),
		20, 0.0074, &"secondary", &"chart"
	)

	_add_box(parent, "Copier", Vector3(1.45, 1.18, 0.95), Vector3(10.25, 0.59, 0.0), Color("aeb6b5"))
	_add_box(parent, "CopierLid", Vector3(1.35, 0.18, 0.88), Vector3(10.25, 1.25, -0.08), Color("303a40"))
	_add_box(parent, "CopierPanel", Vector3(0.5, 0.09, 0.3), Vector3(10.25, 1.35, 0.28), Color("54747b"))
	_add_box(parent, "CopierOutputTray", Vector3(0.92, 0.10, 0.60), Vector3(10.25, 0.88, 0.50), Color("3e494e"))
	for paper_index in 4:
		_add_box(parent, "CopierOutputPaper", Vector3(0.78, 0.018, 0.50), Vector3(10.24 + paper_index * 0.012, 0.95 + paper_index * 0.022, 0.52), Color("dedbcc"))
	for button_index in 4:
		var button_color := Color("7db2a2") if button_index == 3 else Color("d0d5ce")
		_add_box(parent, "CopierButton", Vector3(0.075, 0.035, 0.065), Vector3(10.09 + button_index * 0.11, 1.41, 0.29), button_color)
	_add_box(parent, "CopierPaperDrawer", Vector3(1.08, 0.08, 0.055), Vector3(10.25, 0.43, 0.49), Color("667277"))
	_add_box(parent, "CopierPaperDrawer", Vector3(1.08, 0.08, 0.055), Vector3(10.25, 0.23, 0.49), Color("667277"))
	_add_cylinder(parent, "ShredBin", Vector3(11.10, 0.39, 0.58), 0.30, 0.78, Color("3b474b"))
	_add_box(parent, "ShredBinSlot", Vector3(0.38, 0.035, 0.10), Vector3(11.10, 0.80, 0.58), Color("151d20"))
	for cabinet_x in [-9.9, 8.2]:
		var cabinet_parent := _archive_presentation if cabinet_x < 0.0 else parent
		_add_box(cabinet_parent, "FileCabinet", Vector3(0.95, 1.75, 0.78), Vector3(cabinet_x, 0.88, -8.25), Color("647078"))
		for drawer_y in [0.38, 0.78, 1.18]:
			var handle := _add_box(cabinet_parent, "DrawerHandle", Vector3(0.3, 0.045, 0.065), Vector3(cabinet_x, drawer_y, -7.84), Color("c1c8c4"))
			handle.material_override = _material(Color("c1c8c4"), 0.30, 0.58)
			_add_box(cabinet_parent, "DrawerLabel", Vector3(0.34, 0.12, 0.035), Vector3(cabinet_x, drawer_y + 0.13, -7.82), Color("d8d2bd"))
		_add_box(cabinet_parent, "ArchiveBox", Vector3(0.78, 0.48, 0.66), Vector3(cabinet_x, 2.00, -8.23), Color("b99a6d"))
		_add_box(cabinet_parent, "ArchiveBoxLabel", Vector3(0.34, 0.14, 0.035), Vector3(cabinet_x, 2.00, -7.88), Color("e1dac5"))
	for plant_x in [-11.0, 10.7]:
		var plant_parent := _archive_presentation if plant_x < 0.0 else parent
		_add_cylinder(plant_parent, "PlantPot", Vector3(plant_x, 0.30, -7.05), 0.32, 0.6, Color("80513e"))
		_add_cylinder(plant_parent, "PlantStem", Vector3(plant_x, 0.88, -7.05), 0.065, 0.92, Color("355b45"))
		for leaf_index in 5:
			var angle := TAU * leaf_index / 5.0
			var leaf_color := Color("466b51") if leaf_index % 2 == 0 else Color("58785b")
			var leaf := _add_sphere(plant_parent, "PlantLeaf", Vector3(plant_x + cos(angle) * 0.24, 0.94 + (leaf_index % 2) * 0.18, -7.05 + sin(angle) * 0.24), Vector3(0.22, 0.5, 0.16), leaf_color)
			leaf.rotation_degrees.y = rad_to_deg(angle)

	_add_box(parent, "ExtinguisherBracket", Vector3(0.52, 0.14, 0.09), Vector3(6.95, 1.08, -8.55), Color("454c4e"))
	_add_cylinder(parent, "SafetyExtinguisher", Vector3(6.95, 1.15, -8.43), 0.20, 0.72, Color("a3473b"))
	_add_box(parent, "ExtinguisherNozzle", Vector3(0.30, 0.11, 0.12), Vector3(7.15, 1.46, -8.42), Color("282f31"))


func _build_window_farm_view(parent: Node3D) -> void:
	# A continuous low-poly pasture beyond the opaque office glazing. Everything is
	# a paper-thin, non-colliding silhouette behind the mullions, so it adds depth
	# without adding route obstacles or expensive scene geometry.
	var fence_batches: Dictionary = {}
	for window_index in 6:
		var window_x: float = [-9.1, -5.45, -1.8, 1.85, 5.5, 9.15][window_index]
		var window_parent := _window_presentation_parent(window_x, parent)
		if not fence_batches.has(window_parent):
			fence_batches[window_parent] = [] as Array[Transform3D]
		var fence_transforms := fence_batches[window_parent] as Array[Transform3D]
		var pasture := _add_box(window_parent, "WindowPasture_%d" % window_index, Vector3(2.52, 0.43, 0.022), Vector3(window_x, 1.34, -8.665), Color("668268"))
		pasture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var hill := _add_sphere(window_parent, "WindowHill_%d" % window_index, Vector3(window_x - 0.48 + (window_index % 2) * 0.75, 1.63, -8.67), Vector3(1.60, 0.48, 0.04), Color("58745e"))
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for fence_post in 3:
			var post_x := window_x - 0.78 + fence_post * 0.78
			fence_transforms.append(_box_batch_transform(Vector3(0.045, 0.42, 0.028), Vector3(post_x, 1.38, -8.635)))
		fence_transforms.append(_box_batch_transform(Vector3(2.18, 0.045, 0.028), Vector3(window_x, 1.34, -8.63)))
		fence_transforms.append(_box_batch_transform(Vector3(2.18, 0.045, 0.028), Vector3(window_x, 1.52, -8.63)))
	for parent_value in fence_batches:
		var batch_parent := parent_value as Node3D
		_add_box_multimesh(
			batch_parent,
			"PastureFenceBatch",
			fence_batches[batch_parent] as Array[Transform3D],
			Color("dccb9e"),
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		)

	# Repeated windows read as one farm campus through a few landmark silhouettes.
	_add_box(_west_perch_04_presentation, "DistantBarn", Vector3(1.05, 0.55, 0.035), Vector3(-5.45, 1.58, -8.61), Color("8e4f43")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var barn_roof := _add_box(_west_perch_04_presentation, "DistantBarnRoof", Vector3(1.16, 0.16, 0.04), Vector3(-5.45, 1.89, -8.60), Color("493e38"))
	barn_roof.rotation_degrees.z = 8.0
	barn_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_cylinder(parent, "DistantSilo", Vector3(5.18, 1.62, -8.61), 0.23, 0.82, Color("9ca4a0")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_floor_story(parent: Node3D) -> void:
	# Subtle wear, feed kernels, and directional chevrons make the floor feel used.
	# At 2 cm or less, these remain visual decals and cannot affect navigation.
	var scuff_batches: Dictionary = {}
	for lane_index in 3:
		var lane_x: float = [-7.95, -1.95, 4.05][lane_index]
		var lane_parent := _west_perch_04_presentation if lane_index == 0 else parent
		if not scuff_batches.has(lane_parent):
			scuff_batches[lane_parent] = [] as Array[Transform3D]
		var scuff_transforms := scuff_batches[lane_parent] as Array[Transform3D]
		for mark_index in 3:
			var mark_z := -3.6 + mark_index * 3.7
			scuff_transforms.append(_box_batch_transform(
				Vector3(0.72, 0.008, 0.24),
				Vector3(lane_x, 0.022, mark_z),
				Vector3(0.0, -12.0 + lane_index * 8.0, 0.0),
			))
		for chevron_side in [-1.0, 1.0]:
			var chevron := _add_box(lane_parent, "PeckFlowChevron_%d_%d" % [lane_index, int(chevron_side)], Vector3(0.32, 0.010, 0.075), Vector3(lane_x + chevron_side * 0.11, 0.026, 5.68), Color("c59a4d"))
			chevron.rotation_degrees.y = chevron_side * 34.0
			chevron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for parent_value in scuff_batches:
		var batch_parent := parent_value as Node3D
		_add_box_multimesh(
			batch_parent,
			"PeckLaneScuffBatch",
			scuff_batches[batch_parent] as Array[Transform3D],
			Color(0.28, 0.37, 0.38, 0.75),
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		)

	for kernel_index in 12:
		var kernel_x := -11.05 + (kernel_index % 4) * 0.22
		var kernel_z := -1.02 + int(kernel_index / 4) * 0.24
		var kernel := _add_sphere(_west_perch_05_presentation, "StrayFeedKernel_%d" % kernel_index, Vector3(kernel_x, 0.045, kernel_z), Vector3(0.055, 0.025, 0.085), Color("d0a84f"))
		kernel.rotation_degrees.y = kernel_index * 31.0
		kernel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_wall_story(archive_parent: Node3D, safety_parent: Node3D) -> void:
	# Farm-bureau propaganda occupies the unused left-wall strips and stays clear of
	# the wellness zone, pipeline board, and every circulation lane.
	_add_box(archive_parent, "HenOfMonthFrame", Vector3(0.055, 1.56, 1.75), Vector3(-11.68, 2.05, -5.55), Color("584b3c"))
	var hen_of_month_card := _add_box(
		archive_parent,
		"HenOfMonthCard",
		Vector3(0.035, 1.35, 1.54),
		Vector3(-11.63, 2.05, -5.55),
		Color("e4dcc4"),
	)
	var portrait := _add_sphere(archive_parent, "HenOfMonthPortrait", Vector3(-11.59, 2.08, -5.55), Vector3(0.04, 0.43, 0.43), Color("d79b63"))
	portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EnvironmentalSignageScript.add_panel(
		hen_of_month_card, "HenOfMonthLabel", "HEN OF THE MONTH",
		Vector3(0.021, 0.53, 0.0), Vector2(1.28, 0.28),
		Color("e4dcc4"), Color("514135"), Vector3(0.0, 90.0, 0.0),
		17, 0.0058, &"secondary", &"portrait"
	)

	var safety_label := EnvironmentalSignageScript.add_panel(
		safety_parent, "CoopSafetyLabel", "AISLE SAFETY\nKeep wings tucked",
		Vector3(-11.798, 2.25, 6.45), Vector2(0.96, 0.56),
		Color("d8d5c4"), Color("31515b"), Vector3(0.0, 90.0, 0.0),
		14, 0.0038, &"secondary", &"paper"
	)
	var safety_fixture := safety_label.get_parent() as Node3D
	# A permanent folded-wing pictogram keeps the distant sheet recognizable as
	# safety signage even while its close-reading copy is spatially suppressed.
	for wing_side in [-1.0, 1.0]:
		var wing_mark := _add_box(
			safety_fixture,
			"SafetyWingMarkLeft" if wing_side < 0.0 else "SafetyWingMarkRight",
			Vector3(0.24, 0.025, 0.0014),
			Vector3(wing_side * 0.105, -0.255, 0.0053),
			Color("546c69")
		)
		wing_mark.rotation_degrees.z = wing_side * 28.0


func _build_feed_party_station() -> void:
	_feed_party_station = Node3D.new()
	_feed_party_station.name = "FeedPartyStation"
	_feed_party_station.position = FEED_PARTY_STATION_POSITION
	_feed_party_station.visible = false
	add_child(_feed_party_station)

	if ResourceLoader.exists(FEED_PARTY_STATION_PATH):
		var station_scene := load(FEED_PARTY_STATION_PATH) as PackedScene
		if station_scene != null:
			var model := station_scene.instantiate() as Node3D
			model.name = "FeedPartyStationModel"
			model.scale = Vector3.ONE * FEED_PARTY_STATION_SCALE
			_feed_party_station.add_child(model)
			for wheel_name in [
				"TroughCasterWheel_FrontL",
				"TroughCasterWheel_FrontR",
				"TroughCasterWheel_RearL",
				"TroughCasterWheel_RearR",
			]:
				var wheel := model.find_child(wheel_name, true, false) as Node3D
				if wheel == null:
					continue
				wheel.set_meta("feed_party_base_rotation_x", wheel.rotation.x)
				_feed_party_wheels.append(wheel)
	else:
		# Keeps the event testable while the Blender source is being regenerated.
		_add_box(_feed_party_station, "FallbackTrough", Vector3(2.67, 0.55, 0.72), Vector3(0.0, 0.34, 0.0), Color("6f7875"))
		_add_box(_feed_party_station, "FallbackFeed", Vector3(2.48, 0.08, 0.58), Vector3(0.0, 0.65, 0.0), Color("c9a14f"))

	# The Blender-authored trough already carries dimensional FEED PARTY and
	# ATTENDANCE REQUIRED lettering. A second runtime sign made the same prop read
	# like a labeled UI widget, so the model itself now owns its identity.


func _build_workstation(parent: Node3D, index: int, origin: Vector3) -> void:
	var workstation := WorkstationScene.instantiate() as Node3D
	workstation.name = "Workstation_%02d" % index
	workstation.position = origin
	parent.add_child(workstation)
	_workstations_by_index[index] = workstation
	_decorate_workstation(workstation, index)


func _decorate_workstation(workstation: Node3D, index: int) -> void:
	# Deterministic personal details keep the desks distinct without introducing
	# random visual noise or placing anything in chair/access-lane space.
	var accent_colors: Array[Color] = [Color("8ba6a0"), Color("c88b62"), Color("c2a657"), Color("7289a0"), Color("9a7c9d"), Color("718d68")]
	var accent := accent_colors[index % accent_colors.size()]
	var cubicle_back := workstation.find_child("CubicleBack", true, false) as MeshInstance3D
	var nameplate_parent: Node3D = cubicle_back if cubicle_back != null else workstation
	var nameplate_position := (
		Vector3(-0.72, 0.04, 0.052)
		if cubicle_back != null
		else Vector3(-0.82, 1.32, 0.79)
	)
	var nameplate := EnvironmentalSignageScript.add_panel(
		nameplate_parent, "EmployeeNameplateText", "VACANT PERCH\nAUTHORIZED POSITION",
		nameplate_position, Vector2(0.70, 0.24),
		Color("557069"), Color("efe1bd"), Vector3.ZERO,
		15, 0.0037, &"utility", &"partition"
	)
	_workstation_nameplates[index] = nameplate
	var nameplate_fixture := nameplate.get_parent() as Node3D
	_add_box(
		nameplate_fixture,
		"NameplateAccentStripe",
		Vector3(0.018, 0.085, 0.002),
		Vector3(0.315, 0.0, 0.010),
		accent.lerp(Color("65716b"), 0.38)
	)

	_add_box(workstation, "ChickPhotoFrame", Vector3(0.48, 0.46, 0.075), Vector3(0.87, 1.22, 0.39), Color("53493f"))
	_add_box(workstation, "ChickPhoto", Vector3(0.39, 0.35, 0.035), Vector3(0.87, 1.22, 0.44), Color("b9d0ca"))
	_add_sphere(workstation, "ChickPortrait", Vector3(0.87, 1.24, 0.47), Vector3(0.17, 0.15, 0.08), Color("efd078"))

	var pencil_cup := _add_cylinder(workstation, "PencilCup", Vector3(-0.82, 1.10, 0.22), 0.11, 0.24, accent)
	pencil_cup.material_override = _material(accent, 0.50, 0.08)
	for pencil_index in 3:
		var pencil := _add_cylinder(workstation, "Pencil", Vector3(-0.88 + pencil_index * 0.06, 1.30 + (pencil_index % 2) * 0.04, 0.22), 0.015, 0.38, Color("d6ad52"))
		pencil.rotation_degrees.z = -6.0 + pencil_index * 6.0

	if index % 2 == 0:
		_add_cylinder(workstation, "DeskPlantPot", Vector3(1.00, 1.08, -0.20), 0.13, 0.22, Color("835d48"))
		for leaf_index in 3:
			var leaf := _add_sphere(workstation, "DeskPlantLeaf", Vector3(0.91 + leaf_index * 0.09, 1.28 + (leaf_index % 2) * 0.08, -0.20), Vector3(0.12, 0.28, 0.08), Color("52745a"))
			leaf.rotation_degrees.z = -20.0 + leaf_index * 20.0
	else:
		_add_box(workstation, "FeedSnackPacket", Vector3(0.38, 0.12, 0.28), Vector3(0.98, 1.04, -0.18), Color("c1a052"))


func _build_capacity_authorization_marker(parent: Node3D, index: int, origin: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = "CapacityAuthorization_%02d" % index
	marker.position = origin
	parent.add_child(marker)
	_capacity_markers_by_index[index] = marker
	_add_box(marker, "AuthorizationFloorPad_%02d" % index, Vector3(3.05, 0.018, 1.72), Vector3(0.0, 0.014, 0.02), Color("26363b"))
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			var tape := _add_box(
				marker,
				"AuthorizationTape_%02d" % index,
				Vector3(0.66, 0.012, 0.075),
				Vector3(side_x * 1.16, 0.031, side_z * 0.68),
				Color("d0a64c"),
			)
			tape.rotation_degrees.y = side_x * side_z * 18.0
	var boxed_perch := _add_box(marker, "BoxedPerch_%02d" % index, Vector3(0.88, 0.58, 0.72), Vector3(0.68, 0.31, -0.33), Color("9b7a52"))
	boxed_perch.rotation_degrees.y = -8.0 if index % 2 == 0 else 7.0
	_add_box(marker, "BoxBand_%02d" % index, Vector3(0.12, 0.60, 0.74), Vector3(0.68, 0.32, -0.33), Color("54483a"))
	_add_box(marker, "UnpoweredLightHousing_%02d" % index, Vector3(2.72, 0.13, 0.34), Vector3(0.0, 3.17, 0.05), Color("3c464a"))
	_add_box(marker, "UnpoweredLightLens_%02d" % index, Vector3(2.42, 0.035, 0.24), Vector3(0.0, 3.09, 0.05), Color("6c706b"))
	EnvironmentalSignageScript.add_panel(
		boxed_perch,
		"CapacityNotice_%02d" % index,
		"PERCH %d\nON HOLD" % (index + 1),
		Vector3(0.0, 0.07, 0.366),
		Vector2(0.68, 0.28),
		Color("d8caa9"),
		Color("5c4935"),
		Vector3.ZERO,
		13,
		0.0030,
		&"secondary",
		&"shipping",
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
					var reveal := create_tween().bind_node(workstation).set_parallel(true)
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


func office_physical_presentation_snapshot() -> Dictionary:
	return _office_physical_presentation_state(_displayed_office_capacity).duplicate(true)


func capacity_commissioning_snapshot() -> Dictionary:
	return _capacity_commissioning_state.duplicate(true)


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
	_capacity_stage_tween = create_tween().bind_node(self).set_parallel(true)
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
	_capacity_commissioning_tween = create_tween().bind_node(beat)
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
				"role": String(worker.get("career_title", "CLAIMS HEN")).to_upper(),
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
	var filtered := snapshot.duplicate(true)
	var active_workers: Array[Dictionary] = []
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if _is_worker_employed(worker):
			active_workers.append(worker.duplicate(true))
	filtered["workers"] = active_workers
	return filtered


func _workstation_visual_snapshot(active_snapshot: Dictionary) -> Dictionary:
	var visual_snapshot := active_snapshot.duplicate(true)
	var visual_workers: Array = visual_snapshot.get("workers", [])
	var occupied: Dictionary[int, bool] = {}
	for worker_value in visual_workers:
		var worker := worker_value as Dictionary
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


func _spawn_worker_view(worker_data: Dictionary, arrival_order: int = -1) -> ChickenView:
	var worker_id := int(worker_data.get("id", -1))
	var worker_index := int(worker_data.get("desk_index", -1))
	if worker_id < 0 or worker_index < 0 or worker_index >= MAXIMUM_OFFICE_CAPACITY:
		return null
	if _worker_views.has(worker_id):
		var existing: ChickenView = _worker_views[worker_id]
		existing.apply_snapshot(worker_data)
		return existing
	var view := ChickenViewScript.new() as ChickenView
	view.configure(worker_data)
	_workers_node.add_child(view)
	view.feed_party_attendance_ready.connect(_on_feed_party_attendance_ready)
	view.feed_party_attendance_completed.connect(_on_feed_party_attendance_completed)
	view.workstation_presence_changed.connect(_on_worker_workstation_presence_changed)
	view.office_departure_completed.connect(_on_worker_departure_completed.bind(view))
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
	_worker_views[worker_id] = view
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


func _process(_delta: float) -> void:
	_flush_pending_web_diagnostic()
	_flush_due_campaign_checkpoint()
	var blocking_surface_open := _blocking_management_surface_open()
	var first_clutch_compact := (
		not bool(_first_clutch.get("dismissed", true))
		and not bool(_first_clutch.get("completed", false))
	)
	_apply_live_hud_presentation(first_clutch_compact)
	if _campaign_ui != null:
		var campaign_modal_open := _campaign_ui.is_modal_open()
		_campaign_ui.set_badge_presentation(
			FIRST_CLUTCH_ROUTING_TOP if first_clutch_compact else LIVE_ROUTING_TOP,
			_flockwatch_open or (blocking_surface_open and not campaign_modal_open),
		)
	if _top_hud_panel != null:
		_top_hud_panel.visible = not blocking_surface_open
	if _flockwatch_toggle != null:
		_flockwatch_toggle.visible = not blocking_surface_open
	if _routing_ui != null:
		_routing_ui.visible = not blocking_surface_open and not _flockwatch_open
	# Existing systems publish through the stable ticker label. Detect those
	# publications here so legacy callers retain their exact copy and receipts,
	# while the presentation becomes a short-lived toast instead of a permanent
	# fifty-four-pixel wall across the playable floor.
	if _ticker_label == null or _ticker_panel == null:
		return
	var copy := _ticker_label.text.strip_edges()
	var copy_changed := copy != _ticker_last_text
	if copy_changed:
		_record_status_copy(copy)
	if blocking_surface_open or _flockwatch_open:
		_ticker_panel.visible = false
		return
	if copy_changed:
		if not copy.is_empty():
			_ticker_panel.visible = true
			_ticker_hide_at_msec = Time.get_ticks_msec() + STATUS_TOAST_HOLD_MSEC
	elif _ticker_panel.visible and Time.get_ticks_msec() >= _ticker_hide_at_msec:
		_ticker_panel.visible = false


func _record_status_copy(copy: String) -> void:
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
	if _flockwatch_open and _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _on_status_history_toggled(expanded: bool) -> void:
	_status_history_expanded = expanded
	_refresh_status_history_presentation()


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
		lines.append("- %s" % entry)
	_status_history_label.text = "\n".join(lines)


func _blocking_management_surface_open() -> bool:
	return (
		(_campaign_ui != null and _campaign_ui.is_modal_open())
		or (_decision_host != null and _decision_host.visible)
		or (_day_review_scrim != null and _day_review_scrim.visible)
		or (_settings_ui != null and _settings_ui.visible)
		or (_capital_blueprint_ui != null and _capital_blueprint_ui.visible)
		or (_campus_portfolio_ui != null and _campus_portfolio_ui.visible)
		or (_campus_expansion_ui != null and _campus_expansion_ui.visible)
		or (_commissioning_reveal_ui != null and _commissioning_reveal_ui.visible)
		or (_campus_portfolio_reveal_ui != null and _campus_portfolio_reveal_ui.visible)
	)


func _refresh_floor_input_context() -> void:
	var blocked := _flockwatch_open or _blocking_management_surface_open()
	if _camera_controller != null:
		_camera_controller.set_process_input(not blocked)
		_camera_controller.set_process_unhandled_input(not blocked)
		if blocked:
			_camera_controller.call("_clear_navigation_inputs")
	if _routing_ui != null:
		_routing_ui.set_interaction_enabled(
			not blocked
			and _simulation != null
			and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		)


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
	var routing_top := FIRST_CLUTCH_ROUTING_TOP if compact else LIVE_ROUTING_TOP
	if _routing_ui != null:
		_routing_ui.set_top_inset(routing_top)
	if _flockwatch_toggle != null:
		_flockwatch_toggle.offset_top = routing_top
		_flockwatch_toggle.offset_bottom = routing_top + 44.0
	if _flockwatch_panel != null:
		_flockwatch_panel.offset_top = routing_top + 52.0


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
	top_bar.add_theme_constant_override("separation", 12)
	top_stack.add_child(top_bar)
	var title := _make_label("PECKING ORDER", 18, Color("f4d27b"))
	title.tooltip_text = "Egg Yield Bureau management floor"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	_day_label = _make_label("DAY 1", 16)
	_time_label = _make_label("8:00 AM", 16)
	_revenue_label = _make_label("FEED FUND $50.00", 16, Color("9dd9a4"))
	top_bar.add_child(_day_label)
	top_bar.add_child(_time_label)
	top_bar.add_child(_revenue_label)
	_settings_button = Button.new()
	_settings_button.name = "OpenSettingsButton"
	_settings_button.text = "SETTINGS  [F10]"
	_settings_button.custom_minimum_size = Vector2(112.0, 32.0)
	_settings_button.tooltip_text = "Audio, display comfort, accessibility, and remappable controls."
	_settings_button.focus_mode = Control.FOCUS_ALL
	_settings_button.pressed.connect(_on_settings_requested)
	top_bar.add_child(_settings_button)

	var speed_group := HBoxContainer.new()
	speed_group.name = "SimulationSpeedControl"
	speed_group.add_theme_constant_override("separation", 2)
	top_bar.add_child(speed_group)
	for index in 4:
		var button := Button.new()
		button.text = ["PAUSE", "1×", "3×", "10×"][index]
		button.name = "SpeedButton_%d" % index
		button.theme_type_variation = &"SpeedButton"
		button.custom_minimum_size = Vector2(50.0, 32.0)
		button.tooltip_text = ["Pause simulation", "Normal speed", "Fast speed", "Ultra speed"][index]
		button.pressed.connect(_on_speed_button_pressed.bind(index))
		speed_group.add_child(button)
		_speed_buttons.append(button)

	_shift_objective_row = HBoxContainer.new()
	_shift_objective_row.name = "ShiftObjectiveRow"
	_shift_objective_row.add_theme_constant_override("separation", 12)
	top_stack.add_child(_shift_objective_row)
	_shift_objective_row.add_child(_make_label("SHIFT CLUTCH", 13, Color("d9c47d")))
	_quota_progress = ProgressBar.new()
	_quota_progress.name = "ShiftQuotaProgress"
	_quota_progress.custom_minimum_size = Vector2(190.0, 22.0)
	_quota_progress.show_percentage = false
	_shift_objective_row.add_child(_quota_progress)
	_quota_progress_label = _make_label("0 / 24", 14, Color("f3ead1"))
	_quota_progress_label.custom_minimum_size.x = 62.0
	_shift_objective_row.add_child(_quota_progress_label)
	_quality_streak_label = _make_label("CLEAN CLUTCH  ×0", 14, Color("9ccfc2"))
	_quality_streak_label.custom_minimum_size.x = 152.0
	_shift_objective_row.add_child(_quality_streak_label)
	_directive_badge = _make_label("POLICY  ·  UNSET", 13, Color("efb96d"))
	_directive_badge.custom_minimum_size.x = 160.0
	_directive_badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_shift_objective_row.add_child(_directive_badge)
	_guidance_label = _make_label("START HERE: choose 1× when the flock is seated.", 13, Color("b8c3cc"))
	_guidance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guidance_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_shift_objective_row.add_child(_guidance_label)

	_flockwatch_toggle = Button.new()
	_flockwatch_toggle.name = "FlockwatchToggle"
	_flockwatch_toggle.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_flockwatch_toggle.offset_left = -250.0
	_flockwatch_toggle.offset_top = 120.0
	_flockwatch_toggle.offset_right = -18.0
	_flockwatch_toggle.offset_bottom = 164.0
	_flockwatch_toggle.text = "FLOCKWATCH  [V]"
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
	var operations_section := _make_flockwatch_section("FlockwatchOperationsSection")
	var capital_section := _make_flockwatch_section("FlockwatchCapitalSection")
	var records_section := _make_flockwatch_section("FlockwatchRecordsSection")
	for section: VBoxContainer in [
		today_section,
		flock_section,
		operations_section,
		capital_section,
		records_section,
	]:
		side.add_child(section)
	_campaign_orders_heading_label = _make_label("TODAY'S PROBATION ORDERS", 17, Color("73b5a7"))
	_campaign_orders_heading_label.name = "CampaignOrdersHeading"
	today_section.add_child(_campaign_orders_heading_label)
	_campaign_objectives_label = _make_label("Day 1 orders are being stamped.", 13, Color("d7e5df"))
	_campaign_objectives_label.name = "CampaignObjectivesLabel"
	_campaign_objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	today_section.add_child(_campaign_objectives_label)
	_campaign_doctrine_label = _make_label("", 12, Color("9fd3c5"))
	_campaign_doctrine_label.name = "CampaignActiveDoctrine"
	_campaign_doctrine_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	today_section.add_child(_campaign_safeguards_label)
	_flock_labor_label = _make_label("FLOCK VOICE  ·  No binding compact is currently filed.", 13, Color("b9c8cc"))
	_flock_labor_label.name = "FlockLaborStatus"
	_flock_labor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flock_labor_label.tooltip_text = "Named petitions can become next-shift compacts or trigger work-to-rule."
	today_section.add_child(_flock_labor_label)
	today_section.add_child(HSeparator.new())
	_pecking_order_ui = PeckingOrderUIScript.new()
	_pecking_order_ui.worker_selected.connect(_on_pecking_order_worker_selected)
	flock_section.add_child(_pecking_order_ui)
	flock_section.add_child(HSeparator.new())
	_staffing_ui = RoostStaffingUIScript.new() as RoostStaffingUI
	_staffing_ui.capacity_purchase_requested.connect(_on_staff_capacity_purchase_requested)
	_staffing_ui.facility_purchase_requested.connect(_on_facility_purchase_requested)
	_staffing_ui.manager_assignment_requested.connect(_on_manager_assignment_requested)
	_staffing_ui.manager_posture_requested.connect(_on_manager_posture_requested)
	_staffing_ui.manager_recruit_requested.connect(_on_manager_recruit_requested)
	_staffing_ui.flock_relations_action_requested.connect(_on_flock_relations_action_requested)
	_staffing_ui.feed_order_requested.connect(_on_feed_order_requested)
	_staffing_ui.farmgate_dispatch_mandate_requested.connect(
		_on_farmgate_dispatch_mandate_requested
	)
	_staffing_ui.capital_blueprint_requested.connect(_on_capital_blueprint_requested)
	_staffing_ui.farmer_relations_campaign_requested.connect(
		_on_farmer_relations_campaign_requested
	)
	_staffing_ui.hire_requested.connect(_on_staff_hire_requested)
	_staffing_ui.release_requested.connect(_on_staff_release_requested)
	flock_section.add_child(_staffing_ui)
	_upgrade_disclosure_toggle = FlockwatchDisclosureToggleScript.new()
	_upgrade_disclosure_toggle.name = "DeskRequisitionsToggle"
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
		"DESK REQUISITIONS",
		"3 FILES / NONE READY",
		requisition_targets,
		false,
	)
	_continue_shift_button = Button.new()
	_continue_shift_button.name = "ContinueDirectiveButton"
	_continue_shift_button.text = "CONTINUE: CHOOSE MORNING POLICY"
	_continue_shift_button.theme_type_variation = &"PrimaryButton"
	_continue_shift_button.clip_text = true
	_continue_shift_button.custom_minimum_size.y = 44.0
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
	var today_snapshot_heading := _make_label("SHIFT SNAPSHOT", 12, Color("d9c47d"))
	today_snapshot_heading.name = "FlockwatchTodaySnapshotHeading"
	today_snapshot_rows.add_child(today_snapshot_heading)
	_today_workload_label = _make_label("WORKLOAD · 0 / 18 LIVE · 0 OVERDUE · 0 TURNED AWAY", 12)
	_today_workload_label.name = "FlockwatchTodayWorkload"
	_today_clutch_label = _make_label("CLUTCH · 0 / 0 TODAY · 0 CAREER EGGS", 12)
	_today_clutch_label.name = "FlockwatchTodayClutch"
	_today_flock_label = _make_label("FLOCK · 0% SPIRITS · 0% UNITY RISK", 12)
	_today_flock_label.name = "FlockwatchTodayFlock"
	_today_ledger_label = _make_label("LEDGERS · 0% FARMER FAVOR · 0% COOP OBEDIENCE", 12)
	_today_ledger_label.name = "FlockwatchTodayLedgers"
	for label in [
		_today_workload_label,
		_today_clutch_label,
		_today_flock_label,
		_today_ledger_label,
	]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_STOP
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
	var shift_help_toggle = FlockwatchDisclosureToggleScript.new()
	shift_help_toggle.name = "OperationsShiftHelpToggle"
	operations_section.add_child(shift_help_toggle)
	var note := _make_label("TIP: Click a hen to inspect. Tab cycles; Esc returns.\nOne flock check-in is available each shift.\nThe farmer counts the clutch at 5:00 PM.", 13, Color("aeb8c4"))
	note.name = "OperationsShiftHelp"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operations_section.add_child(note)
	var shift_help_targets: Array[Control] = [note]
	shift_help_toggle.configure("SHIFT HELP", "CONTROLS / CLOSING", shift_help_targets, false)
	_commendations_disclosure_toggle = FlockwatchDisclosureToggleScript.new()
	_commendations_disclosure_toggle.name = "CareerCommendationsToggle"
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
	# Move the staffing domains before their containing Flock section enters the
	# navigator. This must also precede adopting the legacy Today scroll because
	# adoption makes the navigator an ancestor of every still-nested domain.
	var staffing_sections := _staffing_ui.navigation_sections()
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
	_ticker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ticker_panel.add_child(_ticker_label)
	_routing_ui = PeckworkRoutingUIScript.new() as PeckworkRoutingUI
	_routing_ui.assignment_requested.connect(_on_worker_assignment_requested)
	_routing_ui.personnel_action_requested.connect(_on_personnel_action_requested)
	_routing_ui.peck_assist_requested.connect(_on_peck_assist_requested)
	_routing_ui.first_clutch_skip_requested.connect(_on_first_clutch_skip_requested)
	_routing_ui.first_clutch_focus_requested.connect(_on_first_clutch_focus_requested)
	_routing_ui.first_clutch_skip_rect_settled.connect(_on_first_clutch_skip_rect_settled)
	_ui_root.add_child(_routing_ui)
	_build_day_review_panel()
	_build_decision_modal()
	_build_capital_planning_surfaces()
	_campaign_ui = ProbationCampaignUIScript.new() as ProbationCampaignUI
	_campaign_ui.continue_campaign.connect(_on_campaign_continue_requested)
	_campaign_ui.new_campaign.connect(_on_campaign_new_requested)
	_campaign_ui.abandon_campaign.connect(_on_campaign_abandon_requested)
	_campaign_ui.challenge_contract_changed.connect(_on_campaign_challenge_contract_changed)
	_campaign_ui.title_intake_phase_changed.connect(_on_campaign_title_intake_phase_changed)
	_campaign_ui.milestone_choice.connect(_on_campaign_milestone_requested)
	_campaign_ui.presentation_state_changed.connect(_on_campaign_presentation_state_changed)
	_campaign_ui.career_sponsorship_requested.connect(_on_career_sponsorship_requested)
	_campaign_ui.market_contract_sign_requested.connect(_on_market_contract_sign_requested)
	_campaign_ui.market_contract_decline_requested.connect(_on_market_contract_decline_requested)
	_ui_root.add_child(_campaign_ui)
	_settings_ui = SettingsUIScript.new() as PeckingOrderSettingsUI
	_settings_ui.preferences_changed.connect(_on_preferences_changed)
	_settings_ui.binding_capture_requested.connect(_on_binding_capture_requested)
	_settings_ui.reset_defaults_requested.connect(_on_preferences_reset_requested)
	_settings_ui.career_backup_export_requested.connect(_on_career_backup_export_requested)
	_settings_ui.career_backup_import_requested.connect(_on_career_backup_import_requested)
	_settings_ui.close_requested.connect(_on_settings_close_requested)
	_ui_root.add_child(_settings_ui)


func _build_day_review_panel() -> void:
	_day_review_scrim = ColorRect.new()
	_day_review_scrim.name = "DayReviewScrim"
	_day_review_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_day_review_scrim.color = Color(0.025, 0.04, 0.055, 0.78)
	_day_review_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_day_review_scrim.z_index = 80
	_day_review_scrim.visible = false
	_ui_root.add_child(_day_review_scrim)

	_day_review_panel = PanelContainer.new()
	_day_review_panel.name = "DayReviewPanel"
	_day_review_panel.set_anchors_preset(Control.PRESET_CENTER)
	_day_review_panel.offset_left = -370.0
	_day_review_panel.offset_top = -310.0
	_day_review_panel.offset_right = 370.0
	_day_review_panel.offset_bottom = 310.0
	_day_review_panel.add_theme_stylebox_override("panel", _panel_style(Color("17232d"), 0.985, 14, 2))
	_day_review_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_day_review_scrim.add_child(_day_review_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_day_review_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	margin.add_child(content)
	_review_title = _make_label("FARMER REVIEW", 26, Color("f4d27b"))
	_review_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_review_title)
	var closing_steps := _make_label(
		"ACCOUNTING  1   /   CREDIT  2   /   DEVELOPMENT  3",
		12,
		Color("d8b667"),
	)
	closing_steps.name = "ClosingFileSteps"
	closing_steps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(closing_steps)
	content.add_child(HSeparator.new())
	_review_summary = _make_label("", 17, Color("e7edf0"))
	_review_summary.name = "FarmerReviewSummary"
	_review_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_review_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_review_summary.custom_minimum_size.y = 62.0
	content.add_child(_review_summary)
	_review_details_toggle = Button.new()
	_review_details_toggle.name = "FarmerReviewDetailsToggle"
	_review_details_toggle.text = "SHOW ACCOUNTING DETAILS"
	_review_details_toggle.custom_minimum_size.y = 32.0
	_review_details_toggle.pressed.connect(_on_review_details_toggled)
	content.add_child(_review_details_toggle)
	_review_details_scroll = ScrollContainer.new()
	_review_details_scroll.name = "FarmerReviewAccountingScroll"
	_review_details_scroll.custom_minimum_size.y = 184.0
	_review_details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_review_details_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_review_details_scroll.visible = false
	content.add_child(_review_details_scroll)
	_review_results = _make_label("", 13, Color("d5dfe2"))
	_review_results.name = "FarmerReviewAccountingDetails"
	_review_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_review_results.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_review_results.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_review_details_scroll.add_child(_review_results)
	_review_story = _make_label("", 14, Color("b8c6cb"))
	_review_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_review_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_review_story.custom_minimum_size.y = 58.0
	_review_story.max_lines_visible = 3
	_review_story.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(_review_story)
	var hint := _make_label("Continue advances the same closing file; requisitions remain optional.", 13, Color("d5bd78"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)
	var buttons := HFlowContainer.new()
	buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)
	var requisitions := Button.new()
	requisitions.name = "ReviewRequisitionsButton"
	requisitions.text = "OPEN REQUISITIONS"
	requisitions.custom_minimum_size = Vector2(180.0, 48.0)
	requisitions.pressed.connect(_on_review_requisitions_pressed)
	buttons.add_child(requisitions)
	var blueprint := Button.new()
	blueprint.name = "ReviewCapitalBlueprintButton"
	blueprint.text = "CAPITAL BLUEPRINT"
	blueprint.theme_type_variation = &"PrimaryButton"
	blueprint.custom_minimum_size = Vector2(190.0, 48.0)
	blueprint.tooltip_text = "Compare every permanent office project on one spatial capital plan."
	blueprint.pressed.connect(_on_review_capital_blueprint_pressed)
	buttons.add_child(blueprint)
	_begin_next_shift_button = Button.new()
	_begin_next_shift_button.name = "BeginNextShiftButton"
	_begin_next_shift_button.text = "CONTINUE CLOSING FILE"
	_begin_next_shift_button.theme_type_variation = &"PrimaryButton"
	_begin_next_shift_button.custom_minimum_size = Vector2(180.0, 48.0)
	_begin_next_shift_button.pressed.connect(_on_begin_next_shift_pressed)
	buttons.add_child(_begin_next_shift_button)


func _on_review_details_toggled() -> void:
	_review_details_expanded = not _review_details_expanded
	if _review_details_scroll != null:
		_review_details_scroll.visible = _review_details_expanded
	if _review_details_toggle != null:
		_review_details_toggle.text = (
			"HIDE ACCOUNTING DETAILS"
			if _review_details_expanded else
			"SHOW ACCOUNTING DETAILS"
		)


func _build_capital_planning_surfaces() -> void:
	_capital_blueprint_ui = CapitalBlueprintUIScript.new() as Control
	_capital_blueprint_ui.name = "CapitalBlueprintUI"
	_capital_blueprint_ui.z_index = 120
	_capital_blueprint_ui.connect(&"close_requested", _on_capital_blueprint_close_requested)
	_capital_blueprint_ui.connect(&"preview_requested", _on_capital_blueprint_preview_requested)
	_capital_blueprint_ui.connect(&"pin_requested", _on_capital_blueprint_pin_requested)
	_capital_blueprint_ui.connect(&"purchase_requested", _on_capital_blueprint_purchase_requested)
	_capital_blueprint_ui.connect(&"campus_expansion_requested", _on_campus_expansion_requested)
	_ui_root.add_child(_capital_blueprint_ui)

	_campus_portfolio_ui = CampusPortfolioUIScript.new() as Control
	_campus_portfolio_ui.name = "CampusPortfolioUI"
	_campus_portfolio_ui.z_index = 124
	_campus_portfolio_ui.connect(&"close_requested", _on_campus_portfolio_close_requested)
	_campus_portfolio_ui.connect(&"deed_requested", _on_campus_portfolio_deed_requested)
	_campus_portfolio_ui.connect(&"project_requested", _on_campus_portfolio_project_requested)
	_campus_portfolio_ui.connect(
		&"staff_assignment_requested",
		_on_campus_portfolio_staff_assignment_requested,
	)
	_campus_portfolio_ui.connect(
		&"staff_unassignment_requested",
		_on_campus_portfolio_staff_unassignment_requested,
	)
	_campus_portfolio_ui.connect(
		&"north_meadow_details_requested",
		_on_campus_portfolio_north_details_requested,
	)
	_ui_root.add_child(_campus_portfolio_ui)
	_campus_portfolio_ui.call("hide_portfolio", false)

	_campus_expansion_ui = CampusExpansionUIScript.new() as Control
	_campus_expansion_ui.name = "CampusExpansionUI"
	_campus_expansion_ui.z_index = 125
	_campus_expansion_ui.connect(&"close_requested", _on_campus_expansion_close_requested)
	_campus_expansion_ui.connect(
		&"purchase_parcel_requested",
		_on_campus_parcel_purchase_requested,
	)
	_campus_expansion_ui.connect(
		&"connect_service_requested",
		_on_campus_service_connect_requested,
	)
	_campus_expansion_ui.connect(&"place_pod_requested", _on_campus_pod_place_requested)
	_campus_expansion_ui.connect(&"relocate_pod_requested", _on_campus_pod_relocate_requested)
	_ui_root.add_child(_campus_expansion_ui)
	_campus_expansion_ui.call("hide_planner", false)

	_commissioning_reveal_ui = CommissioningRevealUIScript.new() as Control
	_commissioning_reveal_ui.name = "CommissioningRevealUI"
	_commissioning_reveal_ui.z_index = 130
	_commissioning_reveal_ui.connect(&"continue_requested", _on_commissioning_continue_requested)
	_commissioning_reveal_ui.connect(
		&"return_to_blueprint_requested",
		_on_commissioning_return_to_blueprint_requested,
	)
	_ui_root.add_child(_commissioning_reveal_ui)

	_campus_portfolio_reveal_ui = CampusPortfolioRevealUIScript.new() as Control
	_campus_portfolio_reveal_ui.name = "CampusPortfolioRevealUI"
	_campus_portfolio_reveal_ui.z_index = 131
	_campus_portfolio_reveal_ui.connect(
		&"continue_requested",
		_on_campus_portfolio_reveal_continue_requested,
	)
	_campus_portfolio_reveal_ui.connect(
		&"return_to_portfolio_requested",
		_on_campus_portfolio_reveal_return_requested,
	)
	_ui_root.add_child(_campus_portfolio_reveal_ui)


func _build_decision_modal() -> void:
	_decision_host = Control.new()
	_decision_host.name = "ManagementDecisionHost"
	_decision_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_decision_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_decision_host.z_index = 100
	_decision_host.visible = false
	_ui_root.add_child(_decision_host)

	var scrim := ColorRect.new()
	scrim.name = "DecisionScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.018, 0.031, 0.043, 0.84)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_decision_host.add_child(scrim)

	var decision_scroll := ScrollContainer.new()
	decision_scroll.name = "DecisionScroll"
	decision_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decision_scroll.offset_left = 18.0
	decision_scroll.offset_top = 18.0
	decision_scroll.offset_right = -18.0
	decision_scroll.offset_bottom = -18.0
	decision_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	decision_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	decision_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_decision_host.add_child(decision_scroll)

	var center := CenterContainer.new()
	center.name = "DecisionCenter"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	decision_scroll.add_child(center)

	_decision_panel = PanelContainer.new()
	_decision_panel.name = "ManagementDecisionCard"
	_decision_panel.custom_minimum_size = Vector2(760.0, 0.0)
	_decision_panel.add_theme_stylebox_override("panel", _panel_style(Color("172630"), 0.995, 16, 2))
	center.add_child(_decision_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_decision_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "DecisionContent"
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	_decision_eyebrow = _make_label("MANAGEMENT DECISION", 13, Color("d8b667"))
	_decision_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_decision_eyebrow)
	_decision_title = _make_label("CHOOSE A RESPONSE", 25, Color("f4e3ae"))
	_decision_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_decision_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_decision_title)
	_decision_body = _make_label("", 16, Color("c4d0d4"))
	_decision_body.name = "DecisionBody"
	_decision_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_decision_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_decision_body)
	content.add_child(HSeparator.new())
	_decision_options = GridContainer.new()
	_decision_options.name = "DecisionOptions"
	_decision_options.columns = 1
	_decision_options.add_theme_constant_override("h_separation", 9)
	_decision_options.add_theme_constant_override("v_separation", 9)
	content.add_child(_decision_options)
	_decision_preview = _make_label("Select a policy card to review its consequences.", 14, Color("efcf83"))
	_decision_preview.name = "DecisionPreview"
	_decision_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_decision_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_decision_preview.custom_minimum_size.y = 34.0
	content.add_child(_decision_preview)

	var actions := HFlowContainer.new()
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	_decision_stay_paused_button = Button.new()
	_decision_stay_paused_button.name = "ResolveStayPausedButton"
	_decision_stay_paused_button.text = "RESOLVE & STAY PAUSED"
	_decision_stay_paused_button.custom_minimum_size = Vector2(220.0, 46.0)
	_decision_stay_paused_button.disabled = true
	_decision_stay_paused_button.pressed.connect(_on_decision_stay_paused_pressed)
	actions.add_child(_decision_stay_paused_button)
	_decision_confirm_button = Button.new()
	_decision_confirm_button.name = "ConfirmDecisionButton"
	_decision_confirm_button.text = "AUTHORIZE"
	_decision_confirm_button.theme_type_variation = &"PrimaryButton"
	_decision_confirm_button.custom_minimum_size = Vector2(250.0, 46.0)
	_decision_confirm_button.disabled = true
	_decision_confirm_button.pressed.connect(_on_decision_confirm_pressed)
	actions.add_child(_decision_confirm_button)


func _on_decision_requested(decision: Dictionary) -> void:
	if decision.is_empty() or _decision_host == null:
		return
	_active_decision = decision.duplicate(true)
	_decision_panel.custom_minimum_size.x = minf(
		760.0,
		maxf(300.0, get_viewport().get_visible_rect().size.x - 52.0),
	)
	_selected_decision_option = &""
	var kind := StringName(decision.get("kind", &"incident"))
	var option_count := (decision.get("options", []) as Array).size()
	_decision_options.columns = (
		3 if kind == &"directive" and option_count <= 3 else
		(2 if option_count <= 4 else 1)
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
	_decision_body.text = String(decision.get("body", "A measurable variance requires management attention."))
	var decision_category := StringName(decision.get("category", &""))
	if kind == &"directive" and _first_hen_policy_context_active():
		var first_hen := _first_clutch_worker_snapshot(
			_simulation.snapshot(),
			int(_first_clutch.get("target_worker_id", FIRST_HEN_WORKER_ID)),
		)
		var first_hen_name := String(first_hen.get("name", "Mabel")).to_upper()
		var case_docket := _simulation.case_docket_snapshot()
		_decision_eyebrow.text = "%s'S FIRST FILE  //  FLOCK POLICY  //  %s" % [
			first_hen_name,
			String(case_docket.get("id", "PO-1701")),
		]
		_decision_title.text = "CHOOSE THE RULE %s — AND EVERY HEN — WORKS UNDER" % first_hen_name
		_decision_body.text = (
			"%s's dossier is open behind this filing. One policy governs her desk and the whole flock today; "
			+ "its exact production, welfare, and shell consequences remain visible before authorization."
		) % first_hen_name.capitalize()
	if kind == &"directive" and not _campaign_senior_roost:
		var filed_orders := _probation_orders_brief()
		if not filed_orders.is_empty():
			_decision_body.text += "\n\nTODAY'S 3 ORDERS\n%s" % filed_orders
	if decision_category == &"flock_petition":
		var sponsor_worker_id := int(decision.get("sponsor_worker_id", -1))
		if _camera_controller != null and sponsor_worker_id >= 0:
			_camera_controller.focus_worker(sponsor_worker_id)
		var petition := decision.get("petition", {}) as Dictionary
		var evidence_lines: Array[String] = []
		for evidence_value in decision.get("evidence", []):
			evidence_lines.append(String(evidence_value))
		_decision_body.text += "\n\nFILED EVIDENCE  ·  %s" % (
			"  /  ".join(evidence_lines)
			if not evidence_lines.is_empty() else
			"The active flock ledger supports the filing."
		)
		_decision_body.text += "\nPROPOSED COMPACT  ·  %s\nFULFILLMENT TEST  ·  %s" % [
			String(petition.get("promise", "A next-shift promise will be binding.")),
			String(petition.get("condition", "The closing ledger determines fulfillment.")),
		]
	_decision_preview.text = String(decision.get(
		"selection_prompt",
		(
			"Each card compares its real effects with today's scored orders. Select one to inspect the exact fit and consequences."
			if kind == &"directive" else
			"Choose a response card. The shift remains safely paused until you authorize it."
		),
	))
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
		var card_label := String(option.get("short_label", label)) if kind == &"directive" else label
		var tagline := String(option.get("tagline", ""))
		var preview := String(option.get("preview", "Consequence pending."))
		var cost_cents := int(option.get("cost_cents", 0))
		var option_available := bool(option.get("can_select", true))
		var order_fit := _directive_order_fit(option_id) if kind == &"directive" else {}
		var order_fit_detail := String(order_fit.get("detail", ""))
		var full_preview := "%s%s%s" % [
			("%s\n" % tagline if not tagline.is_empty() else ""),
			preview,
			("\n\n%s" % order_fit_detail if not order_fit_detail.is_empty() else ""),
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
			(68.0 if decision_category == &"flock_petition" else 58.0)
		)
		button.text = "%d  //  %s\n%s" % [
			option_index + 1,
			card_label,
			String(order_fit.get("compact", "")) if not order_fit.is_empty() else (tagline if not tagline.is_empty() else "Select to review terms below."),
		]
		button.set_meta("option_id", option_id)
		button.set_meta("preview", full_preview)
		button.set_meta("order_fit", order_fit.duplicate(true))
		button.set_meta("cost_cents", cost_cents)
		button.disabled = not option_available or cost_cents > fund_cents
		if button.disabled:
			button.tooltip_text = String(option.get(
				"unavailable_reason",
				"Requires $%.2f Feed Fund; only $%.2f is available." % [cost_cents / 100.0, fund_cents / 100.0],
			))
		else:
			button.tooltip_text = "%s\n%s" % [
				"Select to preview, then authorize below.",
				full_preview,
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
	if is_directive and _should_hold_first_clutch_orientation():
		_decision_confirm_button.text = "AUTHORIZE & REVIEW FLOOR"
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
	var tween := create_tween().set_parallel(true)
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
	var fit := {
		"supports": [],
		"risks": [],
		"support_count": 0,
		"risk_count": 0,
		"compact": "ORDER FIT 0  /  WATCH 0",
		"detail": "No active probation orders are available for comparison.",
		"long_term": "",
	}
	if _campaign_state == null or _campaign_senior_roost or not DIRECTIVE_ORDER_FIT_RULES.has(directive_id):
		return fit
	var rules := DIRECTIVE_ORDER_FIT_RULES[directive_id] as Dictionary
	var supported_metrics := rules.get("supports", []) as Array
	var risk_metrics := rules.get("risks", []) as Array
	var support_titles: Array[String] = []
	var risk_titles: Array[String] = []
	for objective in _campaign_state.current_objectives():
		var metric := StringName(objective.get("metric", &""))
		var title := String(objective.get("title", "Probation order")).to_upper()
		if metric in supported_metrics:
			support_titles.append(title)
		elif metric in risk_metrics:
			risk_titles.append(title)
	var long_term := String(rules.get("long_term", ""))
	fit["supports"] = support_titles
	fit["risks"] = risk_titles
	fit["support_count"] = support_titles.size()
	fit["risk_count"] = risk_titles.size()
	fit["compact"] = "ORDER FIT %d  /  WATCH %d" % [support_titles.size(), risk_titles.size()]
	fit["long_term"] = long_term
	fit["detail"] = "TODAY'S ORDER FIT  //  SUPPORTS: %s  //  WATCH: %s\nFILE EDGE  //  %s  //  directional; closing ledger decides" % [
		", ".join(support_titles) if not support_titles.is_empty() else "NO DIRECT ORDER",
		", ".join(risk_titles) if not risk_titles.is_empty() else "NO DIRECT CONFLICT",
		long_term if not long_term.is_empty() else "GENERAL OPERATIONS",
	]
	return fit


func _select_decision_option_by_index(index: int) -> void:
	if index < 0 or index >= _decision_option_buttons.size():
		return
	var button := _decision_option_buttons[index]
	if button.disabled:
		_decision_preview.text = button.tooltip_text
		return
	_on_decision_option_pressed(StringName(button.get_meta("option_id", &"")))


func _on_decision_option_pressed(option_id: StringName) -> void:
	_selected_decision_option = option_id
	for button in _decision_option_buttons:
		var is_selected := StringName(button.get_meta("option_id", &"")) == option_id
		button.theme_type_variation = &"SelectedChoiceButton" if is_selected else &"DecisionChoiceButton"
		if is_selected:
			_decision_preview.text = "SELECTED  //  %s" % String(button.get_meta("preview", "Consequence pending."))
	_decision_confirm_button.disabled = false
	_decision_stay_paused_button.disabled = false
	# Keyboard authorization is deliberately two-step: 1/2/3 selects a card,
	# then focus moves to Confirm so Enter cannot re-trigger the option button.
	_decision_confirm_button.grab_focus()
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()
	_publish_web_diagnostic_state(_simulation.snapshot())


func _on_decision_stay_paused_pressed() -> void:
	_resume_after_decision = false
	_commit_selected_decision()


func _on_decision_confirm_pressed() -> void:
	_resume_after_decision = true
	_commit_selected_decision()


func _commit_selected_decision() -> void:
	if _selected_decision_option == &"" or _active_decision.is_empty():
		_decision_preview.text = "Select a response card before authorization."
		return
	_decision_confirm_button.disabled = true
	_decision_stay_paused_button.disabled = true
	if StringName(_active_decision.get("kind", &"")) == FIRST_CLUTCH_REINVESTMENT_KIND:
		var result := _simulation.resolve_first_clutch_reinvestment(_selected_decision_option)
		if bool(result.get("accepted", false)):
			# The simulation emits first_clutch_reinvestment_resolved synchronously.
			# Keep this fallback for focused harnesses that substitute a signal-free stub.
			if not _active_decision.is_empty():
				_on_first_clutch_reinvestment_resolved(result)
			return
		_decision_confirm_button.disabled = false
		_decision_stay_paused_button.disabled = false
		_decision_preview.text = "AUTHORIZATION HELD  //  %s" % String(result.get(
			"reason",
			"The requisition no longer matches the authoritative Feed Fund ledger.",
		))
		_decision_confirm_button.grab_focus()
		_publish_web_diagnostic_state(_simulation.snapshot())
		return
	var resolved := _simulation.resolve_decision(
		int(_active_decision.get("serial", -1)),
		_selected_decision_option
	)
	if resolved:
		return
	_decision_confirm_button.disabled = false
	_decision_stay_paused_button.disabled = false
	_decision_preview.text = "AUTHORIZATION FAILED  //  Review the Feed Fund requirement and choose again."


func _should_hold_first_clutch_orientation() -> bool:
	return (
		_campaign_state != null
		and int(_campaign_state.completed_shifts) == 0
		and _simulation != null
		and _simulation.day == 1
		and _campaign_review_stage == &"active"
		and not bool(_first_clutch.get("dismissed", true))
		and not bool(_first_clutch.get("completed", false))
		and _first_clutch_stage() in [&"inspect", &"specialty_route"]
	)


func _on_first_clutch_reinvestment_resolved(result: Dictionary) -> void:
	var presentation := result.duplicate(true)
	presentation["kind"] = FIRST_CLUTCH_REINVESTMENT_KIND
	_on_decision_resolved(presentation)


func _on_decision_resolved(result: Dictionary) -> void:
	var kind := StringName(result.get("kind", &"incident"))
	var restore_farmer_review := _decision_restore_farmer_review
	_decision_host.visible = false
	_active_decision.clear()
	_selected_decision_option = &""
	_decision_restore_farmer_review = false
	_refresh_floor_input_context()
	var outcome := String(result.get("outcome", "Management decision recorded."))
	_ticker_label.text = outcome
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
				if installed and _camera_controller != null:
					_camera_controller.focus_point(
						_workstation_feedback.install_focus_point_global(desk_index),
						"FIRST CLUTCH REINVESTMENT",
						0.42,
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
		_save_campaign_checkpoint("first_clutch_reinvestment_resolved")
		_publish_web_diagnostic_state(reinvestment_snapshot)
		return
	if kind == &"directive":
		if _audio_feedback != null:
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
		if _audio_feedback != null:
			_audio_feedback.play_decision_resolved()
		_clock.set_speed(_decision_previous_speed if _resume_after_decision else 0)
	else:
		if _audio_feedback != null:
			_audio_feedback.play_policy_stamp()
		_clock.set_speed(0)
		_advance_after_closing_credit()
	_refresh_first_clutch_ui(_simulation.snapshot())
	_update_guidance(_simulation.snapshot())
	_save_campaign_checkpoint("decision_resolved")
	_present_first_clutch_reinvestment()


func _on_workday_completed(report: Dictionary) -> void:
	_clock.set_speed(0)
	_last_workday_report = report.duplicate(true)
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
	_show_farmer_review(report)
	_refresh_commendations_from_authority()


func _show_farmer_review(report: Dictionary, animate: bool = true) -> void:
	if _audio_feedback != null:
		if animate:
			_audio_feedback.play_review()
	_set_flockwatch_open(false)
	var met_quota := bool(report.get("met_quota", false))
	var eggs := int(report.get("eggs", 0))
	var quota := int(report.get("quota", 0))
	var cracked := int(report.get("cracked", 0))
	var golden := int(report.get("golden", 0))
	var quota_bonus := int(report.get("quota_bonus_cents", 0))
	var quality_bonus := int(report.get("quality_bonus_cents", 0))
	var market_contract := report.get("market_contract", {}) as Dictionary
	var market_contract_premium := int(report.get(
		"market_contract_premium_cents",
		market_contract.get("premium_cents", 0),
	))
	var market_contract_service_bonus := int(report.get(
		"market_contract_service_coop_bonus_cents",
		market_contract.get(
			"service_coop_bonus_cents",
			market_contract.get("accreditation_bonus_cents", 0),
		),
	))
	var market_contract_base_premium := int(report.get(
		"market_contract_base_premium_cents",
		market_contract.get(
			"authored_base_premium_cents",
			market_contract.get(
				"base_premium_cents",
				maxi(0, market_contract_premium - market_contract_service_bonus),
			),
		),
	))
	var market_contract_season_premium_delta := int(report.get(
		"market_contract_season_premium_delta_cents",
		market_contract.get("season_premium_delta_cents", 0),
	))
	var market_contract_clause_premium_delta := int(report.get(
		"market_contract_clause_premium_delta_cents",
		market_contract.get("clause_premium_delta_cents", 0),
	))
	# Schema-v14 settlements freeze the signed season and rider adjustments even
	# when either adjustment is zero. Older settlement reports do not carry those
	# fields, so keep their compact Base + Coop receipt instead of inventing terms
	# that were never part of the signed binder.
	var market_contract_has_signed_terms := (
		report.has("market_contract_season_premium_delta_cents")
		or report.has("market_contract_clause_premium_delta_cents")
		or market_contract.has("season_premium_delta_cents")
		or market_contract.has("clause_premium_delta_cents")
		or market_contract.has("season_id")
		or market_contract.has("clause_id")
	)
	var market_contract_breach := int(report.get(
		"market_contract_breach_cents",
		market_contract.get("breach_cents", 0),
	))
	var gross_credit := int(report.get("credited_cents", quota_bonus + quality_bonus))
	# Successful Farm Mutual premiums already enter credited_cents at settlement;
	# remove that closing premium before naming the flock's base production. A
	# breach is not negative production and therefore remains a separate charge.
	var production_credit := maxi(
		0,
		gross_credit - quota_bonus - quality_bonus - market_contract_premium,
	)
	var feed_cost := int(report.get("feed_cost_cents", 0))
	var payroll_cost := int(report.get("payroll_cents", 0))
	var hen_payroll_cost := int(report.get("hen_payroll_cents", payroll_cost))
	var supervisor_payroll_cost := int(report.get(
		"supervisor_payroll_cents",
		maxi(0, payroll_cost - hen_payroll_cost),
	))
	var facility_cost := int(report.get("facility_cost_cents", 0))
	var facility_capacity_cost := int(report.get("facility_expansion_cost_cents", facility_cost))
	var facility_maintenance := int(report.get("facility_maintenance_cents", maxi(0, facility_cost - facility_capacity_cost)))
	var packing_contract := report.get("packing_contract", {}) as Dictionary
	var packing_level := int(packing_contract.get("level", 0))
	var packing_cartons := int(report.get(
		"packing_cartons_today",
		packing_contract.get("cartons_today", 0),
	))
	var packing_value_bonus := int(report.get(
		"packing_value_bonus_cents",
		packing_contract.get("value_bonus_today_cents", 0),
	))
	var packing_carton_bonus := int(report.get(
		"packing_carton_bonus_cents",
		packing_contract.get("carton_bonus_today_cents", 0),
	))
	var operating_cost := int(report.get("operating_cost_cents", feed_cost + payroll_cost + facility_cost))
	# Gross credit already contains a successful premium exactly once. Failed
	# contracts debit Feed Fund outside operating obligations, so include that
	# separate charge once when presenting the shift's reconciled net.
	var operating_net := gross_credit - operating_cost - market_contract_breach
	var closing_fund := int(report.get("closing_fund_cents", _simulation.revenue_cents))
	var closing_arrears := int(report.get("wage_arrears_cents", 0))
	var treasury_receipt := report.get("farm_treasury_receipt", {}) as Dictionary
	var treasury_snapshot := report.get("farm_treasury", {}) as Dictionary
	var operating_net_text := "%s$%.2f" % [
		("+" if operating_net >= 0 else "-"),
		absf(float(operating_net)) / 100.0,
	]
	var completed_directive := report.get("directive", {}) as Dictionary
	var directive_name := String(completed_directive.get("short_name", "UNFILED"))
	var incident_count := int(report.get("incidents_resolved", 0))
	var lane_processed := report.get("lane_processed", {}) as Dictionary
	var overdue_files := int(report.get("overdue_claims", 0))
	var rework_files := int(report.get("rework_waiting", 0)) + int(report.get("rework_due_next_shift", 0))
	var outstanding_files := int(report.get("claims_outstanding", 0))
	var claim_capacity := int(report.get("claim_capacity", 18))
	var intake_rejections := int(report.get("intake_rejections_today", report.get("intake_rejections", 0)))
	var intake_missed_value := int(report.get("intake_missed_value_today_cents", report.get("intake_missed_value_cents", 0)))
	var personnel_action := report.get("personnel_action", {}) as Dictionary
	var personnel_actions := report.get("personnel_actions", []) as Array
	var closing_order := report.get("pecking_order", []) as Array
	var closing_leader: Dictionary = (
		closing_order[0] as Dictionary if not closing_order.is_empty() else {}
	)
	var personnel_line := "NOT FILED"
	if not personnel_actions.is_empty():
		var filed_actions: Array[String] = []
		for action_value in personnel_actions:
			var filed_action := action_value as Dictionary
			filed_actions.append("%s / %s" % [
				String(filed_action.get("worker_name", "HEN")).to_upper(),
				String(filed_action.get("action_name", "CHECK-IN")).to_upper(),
			])
		personnel_line = "; ".join(filed_actions)
	elif not personnel_action.is_empty():
		personnel_line = "%s / %s" % [
			String(personnel_action.get("worker_name", "HEN")).to_upper(),
			String(personnel_action.get("action_name", "CHECK-IN")).to_upper(),
		]
	_review_title.text = "CLOSING FILE 1 / 3  ·  DAY %d  ·  FARMER REVIEW" % int(report.get("day", 1))
	_review_details_expanded = false
	if _review_details_scroll != null:
		_review_details_scroll.visible = false
	if _review_details_toggle != null:
		_review_details_toggle.text = "SHOW ACCOUNTING DETAILS"
	if _review_summary != null:
		_review_summary.text = (
			"%s   ·   %d / %d EGGS   ·   %d CRACKED   ·   %d GOLDEN\n"
			+ "NET %s   ·   FEED FUND $%.2f   ·   NEXT TARGET %d"
		) % [
			"TARGET HARVESTED" if met_quota else "TARGET MISSED",
			eggs,
			quota,
			cracked,
			golden,
			operating_net_text,
			float(closing_fund) / 100.0,
			int(report.get("next_quota", quota)),
		]
	_review_results.text = "%s\n%d / %d eggs  ·  %d cracked  ·  %d golden\nPolicy: %s  ·  %d incident%s resolved\nCheck-in: %s  ·  avg trust %d  ·  avg grievance %d\nFiles: N%d  ·  P%d  ·  A%d  ·  %d overdue  ·  %d rework\nArchive: %d / %d live  ·  %d turned away  ·  est. $%.2f file value missed\nIncome: Production credit +$%.2f  ·  Quota bonus +$%.2f  ·  Quality bonus +$%.2f\nCosts: Feed -$%.2f  ·  Payroll -$%.2f  ·  Facilities -$%.2f\nNet operating %s  ·  Closing Feed Fund $%.2f  ·  Wage arrears $%.2f" % [
		("TARGET HARVESTED" if met_quota else "TARGET MISSED"),
		eggs, quota, cracked, golden,
		directive_name, incident_count, ("" if incident_count == 1 else "s"),
		personnel_line,
		int(report.get("average_manager_trust", 0)),
		int(report.get("average_grievance", 0)),
		int(lane_processed.get(&"nest_damage", 0)),
		int(lane_processed.get(&"predator_loss", 0)),
		int(lane_processed.get(&"appeals", 0)),
		overdue_files,
		rework_files,
		outstanding_files,
		claim_capacity,
		intake_rejections,
		float(intake_missed_value) / 100.0,
		production_credit / 100.0, quota_bonus / 100.0, quality_bonus / 100.0,
		feed_cost / 100.0, payroll_cost / 100.0, facility_cost / 100.0,
		operating_net_text, closing_fund / 100.0, closing_arrears / 100.0,
	]
	_review_results.text = _review_results.text.replace("Check-in:", "Check-ins:")
	_review_results.text = _review_results.text.replace(
		"Payroll -$%.2f" % (payroll_cost / 100.0),
		"Payroll -$%.2f (hens $%.2f + roosters $%.2f)" % [
			payroll_cost / 100.0,
			hen_payroll_cost / 100.0,
			supervisor_payroll_cost / 100.0,
		],
	)
	if not treasury_receipt.is_empty():
		var treasury_liabilities := int(treasury_snapshot.get(
			"total_liabilities_cents",
			int(treasury_receipt.get("closing_credit_principal_cents", 0))
			+ int(treasury_receipt.get("closing_vendor_arrears_cents", 0))
			+ int(treasury_receipt.get("closing_interest_arrears_cents", 0)),
		))
		var treasury_line := (
			"\nFarm Treasury: opening $%.2f + inflow $%.2f  ·  vendors due $%.2f / paid $%.2f"
			+ "  ·  interest $%.2f  ·  line draw $%.2f / principal repaid $%.2f"
			+ "  ·  payroll paid $%.2f / promised $%.2f  ·  closing liabilities $%.2f%s"
		) % [
			float(int(treasury_receipt.get("opening_cash_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("inflow_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("total_vendor_due_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("vendor_paid_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("interest_charged_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("credit_draw_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("principal_repaid_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("labor_paid_cents", 0))) / 100.0,
			float(int(treasury_receipt.get("labor_unpaid_cents", 0))) / 100.0,
			float(treasury_liabilities) / 100.0,
			"  ·  CAPITAL FROZEN" if bool(treasury_snapshot.get("capital_frozen", false)) else "",
		]
		_review_results.text = _review_results.text.replace("\nCosts:", treasury_line + "\nCosts:")
	var completed_operations := report.get("operations", {}) as Dictionary
	if not completed_operations.is_empty():
		var completed_supervision := completed_operations.get("supervision", {}) as Dictionary
		var completed_automation := completed_operations.get("automation", {}) as Dictionary
		var rooster_level := int(completed_operations.get("rooster_office_level", 0))
		var it_level := int(completed_operations.get("it_coop_level", 0))
		if rooster_level > 0 or it_level > 0:
			var operations_line := (
				"\nOperations: Rooster L%d / %d of %d check-ins filed / surveillance +%.2f stress per hen; "
				+ "IT L%d / AUTO %d%% / compliance exposure -%.2f"
			) % [
				rooster_level,
				int(completed_supervision.get("actions_used", 0)),
				int(completed_supervision.get("action_limit", 1)),
				float(completed_supervision.get("surveillance_stress_millipoints", 0)) / 1000.0,
				it_level,
				roundi(float(completed_automation.get("work_basis_points", 10_000)) / 100.0),
				float(completed_automation.get("compliance_exposure_millipoints", 0)) / 1000.0,
			]
			_review_results.text = _review_results.text.replace("\nCosts:", operations_line + "\nCosts:")
	var completed_flock_relations := report.get("flock_relations", {}) as Dictionary
	var flock_relations_filings := report.get("flock_relations_filings", []) as Array
	var flock_relations_carry := report.get("flock_relations_carry_effects", []) as Array
	var flock_relations_level := int(completed_flock_relations.get("level", 0))
	if flock_relations_level > 0:
		var relations_line := (
			"\nFlock Relations L%d: %d / %d open cases  ·  %d / %d review authorizations used"
		) % [
			flock_relations_level,
			int(completed_flock_relations.get("open_case_count", 0)),
			int(completed_flock_relations.get("capacity", flock_relations_level)),
			int(completed_flock_relations.get("resolutions_used_today", 0)),
			int(completed_flock_relations.get("resolution_limit", flock_relations_level)),
		]
		if not flock_relations_filings.is_empty():
			var filed_case := flock_relations_filings[0] as Dictionary
			relations_line += "  ·  NEW %s / %s / severity %d" % [
				String(filed_case.get("docket_id", "CASE FILE")).to_upper(),
				String(filed_case.get("worker_name", "HEN")).to_upper(),
				int(filed_case.get("severity", 1)),
			]
		if not flock_relations_carry.is_empty():
			relations_line += "  ·  %d unresolved %s carried" % [
				flock_relations_carry.size(),
				"case" if flock_relations_carry.size() == 1 else "cases",
			]
		_review_results.text = _review_results.text.replace("\nCosts:", relations_line + "\nCosts:")
	var completed_provisions := report.get("feed_procurement", {}) as Dictionary
	var provisions_level := int(completed_provisions.get("level", 0))
	var provisions_prepaid := int(report.get("feed_procurement_spend_cents", 0))
	var provisions_spoiled := int(completed_provisions.get("spoiled_today_scoops", 0))
	if provisions_level > 0 or provisions_prepaid > 0 or provisions_spoiled > 0:
		var provisions_line := (
			"\nFlock Provisions L%d: demand %d scoops  /  stored %d + spot %d  /  closing stock %d / %d  /  prepaid $%.2f  /  spoilage %d"
		) % [
			provisions_level,
			int(completed_provisions.get("consumed_today_scoops", 0)),
			int(completed_provisions.get("consumed_inventory_today_scoops", 0)),
			int(completed_provisions.get("consumed_spot_today_scoops", 0)),
			int(completed_provisions.get("stock_scoops", 0)),
			int(completed_provisions.get("capacity_scoops", 0)),
			float(provisions_prepaid) / 100.0,
			provisions_spoiled,
		]
		_review_results.text = _review_results.text.replace(
			"\nCosts:",
			provisions_line + "\nCosts:",
		)
	if packing_level > 0:
		var packing_line := (
			"\nPacking Annex L%d: %d carton%s  ·  value lift +$%.2f  ·  carton contracts +$%.2f (included in production)"
			% [
				packing_level,
				packing_cartons,
				"" if packing_cartons == 1 else "s",
				float(packing_value_bonus) / 100.0,
				float(packing_carton_bonus) / 100.0,
			]
		)
		_review_results.text = _review_results.text.replace("\nCosts:", packing_line + "\nCosts:")
	if not market_contract.is_empty() or market_contract_premium > 0 or market_contract_breach > 0:
		var contract_name := String(
			market_contract.get("short_name", market_contract.get("name", "FARM MUTUAL BINDER"))
		).to_upper()
		var contract_status := String(market_contract.get(
			"status",
			"fulfilled" if market_contract_premium > 0 else "breached",
		)).to_upper()
		var timely_completed := int(market_contract.get("timely_sound_completed", 0))
		var required_completed := int(market_contract.get("required_completed", 0))
		var season_delta_label := "%s$%.2f" % [
			"+" if market_contract_season_premium_delta >= 0 else "-",
			absf(float(market_contract_season_premium_delta)) / 100.0,
		]
		var clause_delta_label := "%s$%.2f" % [
			"+" if market_contract_clause_premium_delta >= 0 else "-",
			absf(float(market_contract_clause_premium_delta)) / 100.0,
		]
		var settlement_label := "Breach -$%.2f" % (float(market_contract_breach) / 100.0)
		if market_contract_premium > 0:
			if market_contract_has_signed_terms:
				settlement_label = "Authored +$%.2f  +  Season %s  +  Rider %s  +  Coop L%d +$%.2f  =  +$%.2f" % [
					float(market_contract_base_premium) / 100.0,
					season_delta_label,
					clause_delta_label,
					int(market_contract.get("service_coop_level_at_signing", 0)),
					float(market_contract_service_bonus) / 100.0,
					float(market_contract_premium) / 100.0,
				]
			else:
				settlement_label = "Base +$%.2f  +  Coop L%d +$%.2f  =  +$%.2f" % [
					float(market_contract_base_premium) / 100.0,
					int(market_contract.get("service_coop_level_at_signing", 0)),
					float(market_contract_service_bonus) / 100.0,
					float(market_contract_premium) / 100.0,
				]
		var contract_line := "\nFarm Mutual: %s %s  ·  %s" % [
			contract_name,
			contract_status,
			settlement_label,
		]
		if required_completed > 0:
			contract_line += "  ·  %d/%d clean on time" % [
				timely_completed,
				required_completed,
			]
		var standing_value: Variant = report.get(
			"market_accreditation",
			report.get(
				"farm_mutual_standing",
				report.get("market_contract_standing", {}),
			),
		)
		if standing_value is Dictionary and not (standing_value as Dictionary).is_empty():
			var standing := standing_value as Dictionary
			contract_line += "  ·  %s standing %d" % [
				String(standing.get(
					"rank_label",
					standing.get("rank_name", standing.get("rank", "UNLISTED")),
				)).to_upper(),
				int(standing.get("points", standing.get("score", 0))),
			]
			var clean_streak := int(standing.get("clean_streak", 0))
			if clean_streak > 0:
				contract_line += "  ·  %d clean binder streak" % clean_streak
		_review_results.text = _review_results.text.replace(
			"\nCosts:",
			contract_line + "\nCosts:",
		)
	var newly_unlocked_facilities := report.get("new_facility_unlocks", []) as Array
	if not newly_unlocked_facilities.is_empty():
		var unlock_names: Array[String] = []
		for unlock_value in newly_unlocked_facilities:
			var unlock := unlock_value as Dictionary
			unlock_names.append(String(unlock.get("name", "NEW CAPITAL FACILITY")))
		_review_results.text = _review_results.text.replace(
			"\nCosts:",
			"\nCAPITAL FILE UNLOCKED: %s  ·  Resolve closing credit, then open Capital Expansions.\nCosts:"
			% ", ".join(unlock_names),
		)
	_review_results.tooltip_text = (
		"FACILITY COST BREAKDOWN\n"
		+ "Authorized perch overhead  $%.2f\n" % (facility_capacity_cost / 100.0)
		+ "Installed module maintenance  $%.2f\n\n" % (facility_maintenance / 100.0)
		+ "PAYROLL BREAKDOWN\n"
		+ "Hen wages  $%.2f\n" % (hen_payroll_cost / 100.0)
		+ "Rooster supervisor wages  $%.2f\n\n" % (supervisor_payroll_cost / 100.0)
		+ "Net operating uses accrued feed, payroll, and facility obligations. Unpaid payroll remains visible as arrears."
		+ (
			"\n\nFARM TREASURY\nThe filed receipt conserves opening cash, intrashift inflows, vendor payments, interest, labor payments, debt service, and closing cash exactly. The revolving line may cover vendors and interest, but never wages."
			if not treasury_receipt.is_empty() else
			""
		)
		+ "\n\nINTAKE CAPACITY\nTurned-away file value is an opportunity estimate only. It never enters the Feed Fund. More archive space can retain more work, but it can also increase overdue exposure."
		+ (
			"\n\nPACKING CONTRACT\nThe percentage lift and six-good-egg carton settlement are already included in Production credit."
			if packing_level > 0 else
			""
		)
		+ (
			"\n\nFARM MUTUAL SETTLEMENT\nBase premium and the Service Coop accreditation bonus are itemized above, then enter gross credit exactly once as the displayed total. A breach earns neither and is charged once against the Feed Fund. Closing Feed Fund remains the authoritative settled balance."
			if not market_contract.is_empty() or market_contract_premium > 0 or market_contract_breach > 0 else
			""
		)
		+ (
			"\n\nFLOCK RELATIONS\nOpen Requisitions to inspect each named-hen case. Remedy, mediation, PIP, and arbitration terms come directly from the permanent case ledger. Every case left open carries obedience, unity, and grievance pressure into a later closing."
			if flock_relations_level > 0 else
			""
		)
		+ (
			"\n\nFLOCK PROVISIONS\nPrepaid orders leave the Feed Fund when authorized and enter stored inventory. The closing Feed cost is only today's automatic spot shortage, so prepaid grain is never charged a second time. Consumed inventory value and spoilage remain visible as working-capital receipts."
			if provisions_level > 0 or provisions_prepaid > 0 else
			""
		)
	)
	var flock_ledger_entries: Array[String] = []
	var flock_ledger_details: Array[String] = []
	var compact_receipt := report.get("flock_compact_receipt", {}) as Dictionary
	if not compact_receipt.is_empty():
		flock_ledger_entries.append("%s %s" % [
			String(compact_receipt.get("compact_name", "FLOCK COMPACT")).to_upper(),
			String(compact_receipt.get("status", "FILED")).to_upper(),
		])
		flock_ledger_details.append(String(compact_receipt.get("outcome", "Compact receipt filed.")))
	var completed_work_to_rule := report.get("work_to_rule", {}) as Dictionary
	if bool(completed_work_to_rule.get("completed", false)):
		flock_ledger_entries.append("WORK-TO-RULE COMPLETED")
		flock_ledger_details.append("The flock completed one shift of slower, shell-safe written procedure.")
	var next_compact := report.get("next_flock_compact", {}) as Dictionary
	if not next_compact.is_empty():
		flock_ledger_entries.append("%s BINDS DAY %d" % [
			String(next_compact.get("compact_name", "FLOCK COMPACT")).to_upper(),
			int(next_compact.get("effective_day", int(report.get("day", 1)) + 1)),
		])
		flock_ledger_details.append(String(next_compact.get("condition", "Tomorrow's ledger tests the promise.")))
	var next_work_to_rule := report.get("next_work_to_rule", {}) as Dictionary
	if bool(next_work_to_rule.get("active", false)) or bool(next_work_to_rule.get("scheduled", false)):
		flock_ledger_entries.append("WORK-TO-RULE FILED FOR DAY %d" % int(next_work_to_rule.get("day", 0)))
		flock_ledger_details.append("The flock will follow every written procedure: slower throughput, safer shells.")
	if not flock_ledger_entries.is_empty():
		_review_results.text += "\nFlock ledger: %s" % "  ·  ".join(flock_ledger_entries)
		_review_results.tooltip_text += "\n\n" + "\n".join(flock_ledger_details)
	_review_story.text = (
		"The farmer credits decisive leadership and announces tomorrow's improved target: %d eggs."
		if met_quota else
		"The farmer identifies a temporary flock-attitude variance. Tomorrow's adjusted target is %d eggs."
	) % int(report.get("next_quota", quota))
	if not personnel_action.is_empty():
		_review_story.text += "\nPersonnel ledger: %s" % String(personnel_action.get("outcome", "Check-in filed."))
	if not flock_relations_filings.is_empty():
		var story_case := flock_relations_filings[0] as Dictionary
		_review_story.text += "\nFlock Relations: %s filed %s. Open Requisitions to choose whether the Feed Fund pays, management mediates, or the case becomes another performance file." % [
			String(story_case.get("worker_name", "A hen")),
			String(story_case.get("title", "a workplace grievance")).to_lower(),
		]
	if provisions_spoiled > 0:
		_review_story.text += "\nFlock Provisions: %d scoop%s expired; management records the loss as a successful demand forecast rehearsal." % [
			provisions_spoiled,
			"" if provisions_spoiled == 1 else "s",
		]
	if not closing_leader.is_empty():
		_review_story.text += "\nPecking Order #1: %s  ·  %d eggs  ·  $%.2f credited." % [
			String(closing_leader.get("worker_name", "HEN")).to_upper(),
			int(closing_leader.get("eggs", 0)),
			float(int(closing_leader.get("credit_cents", 0))) / 100.0,
		]
	if _begin_next_shift_button != null:
		var memo_kind := StringName(report.get("credit_memo_kind", &""))
		var memo_id := StringName(report.get("credit_memo_id", &""))
		_begin_next_shift_button.text = "CONTINUE CLOSING FILE"
		_begin_next_shift_button.tooltip_text = (
			"Next: restructuring credit file."
			if memo_id == &"flock_restructuring" else
			("Next: golden egg credit dossier."
			if memo_id == &"golden_egg_dossier" else
			("Next: allocate closing credit."
			if bool(report.get("credit_memo_required", false)) else
			"Next: file the shift report and plan the following shift."))
		)
	_day_review_scrim.visible = true
	_refresh_floor_input_context()
	_ticker_label.text = "SHIFT COMPLETE. The farmer has harvested the credit; review the real accounting."
	if animate:
		_day_review_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_day_review_panel.scale = Vector2(0.94, 0.94)
		_day_review_panel.pivot_offset = _day_review_panel.size * 0.5
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_day_review_panel, "modulate:a", 1.0, 0.24)
		tween.tween_property(_day_review_panel, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_day_review_panel.modulate = Color.WHITE
		_day_review_panel.scale = Vector2.ONE


func _on_review_requisitions_pressed() -> void:
	_flockwatch_restore_farmer_review = true
	_day_review_scrim.visible = false
	_open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	_refresh_floor_input_context()
	_guidance_label.text = "REVIEW PAUSED: approve requisitions, then choose tomorrow's policy."
	_ticker_label.text = "Feed Fund purchases are permanent. Costs rise with each approved level."


func _on_review_capital_blueprint_pressed() -> void:
	_open_capital_blueprint(true, false)


func _on_capital_blueprint_requested() -> void:
	_open_capital_blueprint(false, _flockwatch_open)


func _open_capital_blueprint(
	restore_review: bool = false,
	restore_flockwatch: bool = false,
) -> void:
	if _capital_blueprint_ui == null:
		return
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
		_ticker_label.text = String(result.get("reason", "CAPITAL PLAN COULD NOT BE PINNED."))
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


func _on_capital_blueprint_purchase_requested(facility_id: StringName) -> void:
	_on_facility_purchase_requested(facility_id)


func _on_campus_expansion_requested() -> void:
	if _campus_portfolio_ui == null:
		return
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
		_ticker_label.text = String(result.get("reason", "CAMPUS PORTFOLIO FILE HELD FOR REVIEW."))
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
	if receipt.is_empty() or _campus_portfolio_reveal_ui == null:
		return
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
		_ticker_label.text = "PLACEMENT FILE CHANGED. Review the current Egg Routing Pod socket before moving it."
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
		_ticker_label.text = String(result.get("reason", "NORTH MEADOW FILING HELD FOR REVIEW."))
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


func _advance_from_farmer_review() -> void:
	_flockwatch_restore_farmer_review = false
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	var pending := _simulation.pending_decision_snapshot()
	var pending_kind := StringName(pending.get("kind", &""))
	if pending_kind in [&"credit_allocation", &"major_event"]:
		_campaign_review_stage = &"credit"
		_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
		_set_campaign_modal_open(false)
		_simulation.announce_pending_decision()
		_save_campaign_checkpoint("credit_memo_opened")
		return
	_advance_after_closing_credit()


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
	_save_campaign_checkpoint("probation_report")


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
	_guidance_label.text = "CLOSING CREDIT FILED: publish one Gallery campaign or continue to skip."
	_ticker_label.text = "FARMER RELATIONS GALLERY. One public campaign may be hung from this closed shift."
	_publish_web_diagnostic_state(snapshot)
	return true


func _skip_farmer_relations_gallery_campaign() -> bool:
	if not _simulation.has_method("skip_farmer_relations_campaign"):
		_ticker_label.text = "GALLERY FILE HELD. Skip authorization is unavailable."
		return false
	var result_value: Variant = _simulation.call("skip_farmer_relations_campaign")
	var result := result_value as Dictionary if result_value is Dictionary else {}
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get(
			"reason",
			"PUBLIC CAMPAIGN SKIP HELD FOR CLOSING REVIEW.",
		))
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


func _on_worker_assignment_requested(worker_id: int, lane: StringName) -> void:
	if not _simulation.set_worker_assignment(worker_id, lane):
		_ticker_label.text = "ROUTING HELD. Finish the current management action before changing trays."
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
	_first_clutch_record_routing(worker_id, lane)
	_save_campaign_checkpoint("routing_assignment")


func _handle_first_clutch_primary_action() -> bool:
	# First Clutch is a guided lesson with one deliberately highlighted answer at
	# these two stages. Enter activates that same production action so keyboard,
	# controller-mapped, and browser-assisted players do not have to hunt a dense
	# dossier for the glowing control. Normal play retains every routing choice.
	if not _first_clutch_tracking_active():
		return false
	var stage := _first_clutch_stage()
	if stage not in [&"specialty_route", &"check_in"]:
		return false
	var worker_id := int(_first_clutch.get("target_worker_id", -1))
	var worker := _first_clutch_worker_snapshot(_simulation.snapshot(), worker_id)
	if worker.is_empty():
		return false
	if _camera_controller != null:
		_camera_controller.focus_worker(worker_id)
	if stage == &"specialty_route":
		var specialty := StringName(worker.get("specialty", &""))
		if specialty == &"":
			return false
		_on_worker_assignment_requested(worker_id, specialty)
		return true
	var preferred_action := StringName(worker.get("preferred_personnel_action", &""))
	if preferred_action == &"":
		return false
	_on_personnel_action_requested(worker_id, preferred_action)
	return true


func _on_personnel_action_requested(worker_id: int, action_id: StringName) -> void:
	var result := _simulation.perform_personnel_action(worker_id, action_id)
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get("reason", "PERSONNEL ACTION HELD."))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"personnel")
		return
	var preferred_note := "  /  PROFILE MATCH" if bool(result.get("preferred", false)) else ""
	_ticker_label.text = "%s%s" % [String(result.get("outcome", "Personnel action filed.")), preferred_note]
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()
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
	var candidate := _priority_peck_precision_candidate(snapshot)
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
	_refresh_speed_button_copy()
	if not result_hold_active and Time.get_ticks_msec() >= _priority_peck_result_hold_until_msec:
		_priority_peck_result_hold_until_msec = 0
		_priority_peck_result_hold_worker_id = -1
		_priority_peck_result_hold_claim_id = -1


func _refresh_speed_button_copy() -> void:
	if _speed_buttons.is_empty():
		return
	var labels := ["PAUSE", "1×", "3×", "10×"]
	var tooltips := ["Pause simulation", "Normal speed", "Fast speed", "Ultra speed"]
	var limiting := _clock != null and _clock.precision_focus_limiting()
	for index in _speed_buttons.size():
		var button := _speed_buttons[index]
		button.text = labels[index]
		button.tooltip_text = tooltips[index]
		if limiting and index == _clock.speed_index:
			button.text = "%s/1×" % labels[index]
			button.tooltip_text = (
				"%s remains selected. Inspecting this approaching Priority Peck "
				+ "temporarily holds the effective clock at 1×; the selected speed resumes automatically."
			) % labels[index]


func _peck_assist_input_blocked() -> bool:
	return (
		(_campaign_ui != null and _campaign_ui.is_modal_open())
		or (_decision_host != null and _decision_host.visible)
		or (_day_review_scrim != null and _day_review_scrim.visible)
		or _feed_party_active
		or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
	)


func _request_peck_assist_from_input() -> void:
	if _clock.speed_index == 0:
		_ticker_label.text = "PRIORITY PECK HELD. Resume the live clock before stamping the rhythm."
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"clock_paused")
		return
	var worker_id := _routing_ui.focused_worker_id() if _routing_ui != null else -1
	if worker_id < 0 or not bool(_simulation.peck_assist_status(worker_id).get("available", false)):
		worker_id = _simulation.recommended_peck_assist_worker_id()
	if worker_id < 0:
		_ticker_label.text = "PRIORITY PECK: wait for a seated hen's claim meter to enter the gold window."
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"peck_window")
		return
	if _camera_controller != null:
		_camera_controller.focus_worker(worker_id)
	_on_peck_assist_requested(worker_id)


func _on_peck_assist_requested(worker_id: int) -> void:
	if _clock.speed_index == 0:
		_ticker_label.text = "PRIORITY PECK HELD. Resume the live clock before stamping the rhythm."
		return
	var preflight := _simulation.peck_assist_status(worker_id)
	if bool(preflight.get("available", false)):
		_priority_peck_result_hold_until_msec = Time.get_ticks_msec() + PECK_FOCUS_RESULT_HOLD_MSEC
		_priority_peck_result_hold_worker_id = worker_id
		_priority_peck_result_hold_claim_id = int(preflight.get("claim_id", -1))
	var result := _simulation.perform_peck_assist(worker_id)
	if not bool(result.get("accepted", false)):
		_priority_peck_result_hold_until_msec = 0
		_priority_peck_result_hold_worker_id = -1
		_priority_peck_result_hold_claim_id = -1
		_refresh_priority_peck_precision_focus(_simulation.snapshot())
		_ticker_label.text = String(result.get("reason", "PRIORITY PECK HELD."))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"peck_rejected")
		return
	var rating := StringName(result.get("rating", &"steady"))
	_priority_peck_focus_disarmed_worker_id = worker_id
	var worker_name := String(result.get("worker_name", "HEN")).to_upper()
	var progress_gain := int(roundf(float(result.get("progress_gain", 0.0))))
	var quality_points := absf(float(result.get("quality_modifier", 0.0))) * 100.0
	_ticker_label.text = "%s PECK  ·  %s +%d%% FILE  ·  shell risk %s%.1f%%  ·  chain x%d  ·  %d charges left; clean delivery restores 1" % [
		String(rating).to_upper(), worker_name, progress_gain,
		("-" if float(result.get("quality_modifier", 0.0)) <= 0.0 else "+"), quality_points,
		int(result.get("streak", 0)), int(result.get("remaining", 0)),
	]
	var worker_view := _worker_views.get(worker_id) as ChickenView
	if worker_view != null and is_instance_valid(worker_view):
		worker_view.play_peck_assist_feedback(rating)
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
	if _workstation_feedback != null:
		_workstation_feedback.pulse_peck_assist(worker_id, rating)
	if contact_index == 2 and _office_atmosphere != null:
		var worker_view := _worker_views.get(worker_id) as ChickenView
		if worker_view != null and is_instance_valid(worker_view):
			_office_atmosphere.pulse_egg_laid(
				worker_view.global_position + Vector3.UP * 0.9,
				&"golden" if rating == &"perfect" else &"sound",
			)


func _on_work_peck_contact(worker_id: int, contact_serial: int) -> void:
	# Ambient contacts stay visual and allocation-free; the authored three-hit
	# Priority Peck remains the only work action that earns prominent audio/VFX.
	if _workstation_feedback != null:
		_workstation_feedback.pulse_work_contact(worker_id, contact_serial)


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
		_ticker_label.text = String(result.get("reason", "FACILITY REQUISITION HELD FOR REVIEW."))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"facility")
		return
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
		_ticker_label.text = String(result.get(
			"reason",
			"PROVISIONS ORDER HELD FOR REVIEW.",
		))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"provisions")
		return
	# The inventory room, reserve projection, and Flockwatch receipt all reconcile
	# from the same authoritative order before the camera visits the new delivery.
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Provisions order authorized."))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
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
		_ticker_label.text = String(result.get(
			"reason",
			"FARMGATE MANDATE HELD FOR REVIEW.",
		))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"farmgate")
		return
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Farmgate dispatch mandate filed."))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	if _camera_controller != null:
		_camera_controller.show_event_focus(
			FARMGATE_DISPATCH_DEPOT_FOCUS,
			"FARMGATE ROUTE FILED",
			1.35,
			true,
		)
	_save_campaign_checkpoint("farmgate_dispatch_%s" % String(mandate_id))


func _on_farmer_relations_campaign_requested(campaign_id: StringName) -> void:
	if not _simulation.has_method("file_farmer_relations_campaign"):
		_ticker_label.text = "GALLERY FILE HELD. Public-credit authorization is unavailable."
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"gallery_unavailable")
		return
	var result_value: Variant = _simulation.call("file_farmer_relations_campaign", campaign_id)
	var result := result_value as Dictionary if result_value is Dictionary else {}
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get(
			"reason",
			"GALLERY CAMPAIGN HELD FOR CLOSING REVIEW.",
		))
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
	_save_campaign_checkpoint("farmer_relations_campaign_%s" % String(campaign_id))
	_publish_web_diagnostic_state(snapshot)
	if _continue_shift_button != null and _continue_shift_button.is_visible_in_tree():
		_continue_shift_button.call_deferred("grab_focus")


func _on_flock_relations_action_requested(case_id: int, action_id: StringName) -> void:
	var result := _simulation.resolve_flock_relations_case(case_id, action_id)
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get(
			"reason",
			"FLOCK RELATIONS DISPOSITION HELD FOR REVIEW.",
		))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"flock_relations")
		return
	# Keep the player in the existing Flockwatch review flow. The refreshed
	# snapshot removes exactly the resolved case and files the permanent receipt;
	# no additional modal obscures the remaining labor docket.
	_on_snapshot_changed(_simulation.snapshot())
	_ticker_label.text = String(result.get("outcome", "Flock Relations case filed."))
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()
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


func _handle_manager_action_result(result: Dictionary) -> void:
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get("reason", "MANAGEMENT FILE HELD FOR REVIEW."))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"management")
		return
	var snapshot := _simulation.snapshot()
	_on_snapshot_changed(snapshot)
	_ticker_label.text = String(result.get("outcome", "Management instruction filed."))
	if _audio_feedback != null:
		_audio_feedback.play_policy_stamp()
	_save_campaign_checkpoint("manager_instruction_%s" % String(result.get("manager_id", "rooster")))


func _on_staff_release_requested(worker_id: int) -> void:
	var result := _simulation.release_worker(worker_id)
	_handle_staffing_action_result(result, &"worker_released")


func _handle_staffing_action_result(result: Dictionary, checkpoint_reason: StringName) -> void:
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get("reason", "STAFFING FILE HELD FOR REVIEW."))
		if _audio_feedback != null:
			_audio_feedback.play_denied(&"staffing")
		return
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


func _on_campaign_new_requested() -> void:
	# A new file is committed through CampaignSaveStore's verified temporary-file
	# transaction. Keeping the current primary in place until that commit succeeds
	# also lets the store refresh its recovery copy with the previous campaign.
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
	var fresh_simulation := DepartmentSimulation.new(
		1701,
		INITIAL_CAMPAIGN_STAFF,
		_fresh_campaign_seed(),
	)
	if not _simulation.restore_save_state(fresh_simulation.export_save_state()):
		push_error("Could not reset the office simulation for a new probation file.")
		return
	_reset_first_clutch(true)
	if _flockwatch_navigation != null:
		_flockwatch_navigation.reset_discovered_pages()
	_prime_first_hen_prelude()
	_reset_campaign_session_visuals()
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
		_ticker_label.text = (
			"NEW FILE HELD. The replacement checkpoint could not be verified; "
			+ ("the prior valid coop file was restored. " if had_prior_save else "no unverified campaign was opened. ")
			+ save_error
		)
		return
	_campaign_session_checkpoint_enabled = true
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("reset_presentation_filter")
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
	# Annual planning is paused, so selecting a confirmation-first Board Book
	# cannot rely on a later simulation tick to refresh the Web mirror.
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _on_campaign_continue_requested() -> void:
	match _campaign_ui.modal_state():
		ProbationCampaignUI.VIEW_TITLE:
			_load_campaign_checkpoint()
		ProbationCampaignUI.VIEW_REPORT:
			if _campaign_senior_roost:
				_continue_senior_roost_report()
				return
			if _campaign_state.is_milestone_choice_available():
				_ticker_label.text = "MILESTONE REQUIRED. Choose one permanent probation edge before shift three."
				return
			_open_contract_board_or_begin_next_shift()
		ProbationCampaignUI.VIEW_CONTRACT_BOARD:
			_continue_from_contract_board()
		ProbationCampaignUI.VIEW_FINAL:
			if _campaign_state.outcome == CampaignStateScript.OUTCOME_PASSED:
				_enter_senior_roost()


func _on_campaign_abandon_requested() -> void:
	_clock.set_speed(0)
	if not _save_campaign_checkpoint("returned_to_intake"):
		_ticker_label.text = (
			"RETURN TO INTAKE HELD. The current coop file could not be safely shelved: %s"
			% _campaign_store.last_error
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
) -> void:
	var receipt := _simulation.sign_market_contract(offer_id, clause_id)
	_campaign_ui.show_contract_board(_simulation.snapshot())
	_set_campaign_modal_open(true)
	_ticker_label.text = String(receipt.get(
		"outcome",
		receipt.get("reason", "FARM MUTUAL SIGNATURE HELD."),
	))
	if bool(receipt.get("accepted", false)):
		_save_campaign_checkpoint("market_contract_signed")


func _on_market_contract_decline_requested() -> void:
	var receipt := _simulation.decline_market_contract()
	_campaign_ui.show_contract_board(_simulation.snapshot())
	_set_campaign_modal_open(true)
	_ticker_label.text = String(receipt.get(
		"outcome",
		receipt.get("reason", "STANDARD BOOK FILING HELD."),
	))
	if bool(receipt.get("accepted", false)):
		_save_campaign_checkpoint("market_contract_declined")


func _on_campaign_milestone_requested(choice_id: StringName) -> void:
	if _campaign_senior_roost:
		if _senior_roost_state == null:
			_ticker_label.text = "SENIOR FILE HELD. The recurring career ledger is unavailable."
			return
		if _senior_roost_state.requires_annual_mandate():
			var mandate_receipt: Dictionary = _senior_roost_state.select_annual_mandate(
				choice_id,
				_senior_roost_state.current_year_number(),
			)
			if not bool(mandate_receipt.get("accepted", false)):
				_ticker_label.text = "BOARD MANDATE HELD. %s" % String(
					mandate_receipt.get("reason", "Choose one of the three frozen annual books."),
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
			_ticker_label.text = "CAPITAL POLICY HELD. This Senior quarter already has a filed policy."
			return
		var senior_receipt := _simulation.apply_senior_quarter_policy(choice_id)
		if not bool(senior_receipt.get("accepted", false)):
			_ticker_label.text = String(senior_receipt.get("reason", "CAPITAL POLICY HELD. Review the Senior Roost docket."))
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
		_ticker_label.text = "MILESTONE HELD. This requisition is not available for the current file."
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
		_ticker_label.text = "SPONSORSHIP HELD. Career credentials are filed only in Senior Roost."
		return
	var simulation_preflight := _simulation.career_sponsorship_preflight(worker_id, lane_id)
	if not bool(simulation_preflight.get("available", false)):
		_ticker_label.text = "SPONSORSHIP HELD. %s" % String(simulation_preflight.get(
			"reason",
			"The selected hen or claim lane is no longer eligible.",
		))
		_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
		return
	var primary_lane := StringName(String(simulation_preflight.get("primary_specialty", "")))
	var senior_preflight: Dictionary = _senior_roost_state.preflight_sponsorship(
		worker_id,
		primary_lane,
		lane_id,
	)
	if not bool(senior_preflight.get("available", senior_preflight.get("accepted", false))):
		_ticker_label.text = "SPONSORSHIP HELD. %s" % String(senior_preflight.get(
			"reason",
			"Available Roost Marks could not authorize this credential.",
		))
		_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
		return

	# Both authoritative ledgers are preflighted while the campaign report keeps
	# simulation time frozen. The simulation receipt is then the exact evidence
	# committed by the Senior career ledger; no presentation-side currency or mark
	# value is ever edited directly.
	var simulation_receipt := _simulation.authorize_career_sponsorship(worker_id, lane_id)
	if not bool(simulation_receipt.get("accepted", false)):
		_ticker_label.text = "SPONSORSHIP HELD. %s" % String(simulation_receipt.get(
			"reason",
			"The protected Feed Fund changed before authorization.",
		))
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
		_ticker_label.text = "SPONSORSHIP LEDGER ERROR. The accepted training receipt requires recovery review."
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
			_ticker_label.text = "SENIOR ROOST HELD. The career ledger could not be initialized safely."
			return
	_campaign_senior_roost = _senior_roost_state.is_active()
	_show_senior_roost_report("senior_roost_entered")
	_ticker_label.text = "SENIOR ROOST OPEN. Choose one annual Board Mandate, then file the first quarter's capital policy."
	_refresh_commendations_from_authority()


func _continue_senior_roost_report() -> void:
	if _senior_roost_state == null or not _senior_roost_state.is_active():
		_ticker_label.text = "SENIOR ROOST HELD. No active career ledger is available."
		return
	match _senior_roost_state.status:
		SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
			_ticker_label.text = (
				"ANNUAL BOARD MANDATE REQUIRED. Choose one frozen year-long book before Q1 policy."
				if _senior_roost_state.requires_annual_mandate() else
				"CAPITAL POLICY REQUIRED. Choose one available tradeoff before opening the quarter."
			)
			return
		SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
			var passed := bool(_senior_roost_state.last_annual_review.get("passed", false))
			var transition := _simulation.apply_senior_year_transition(passed)
			if not bool(transition.get("accepted", false)):
				_ticker_label.text = String(transition.get("reason", "ANNUAL TRANSITION HELD."))
				return
			if not _senior_roost_state.continue_after_annual(_simulation.snapshot()):
				push_error("Senior annual review could not advance after an accepted transition.")
				return
			_show_senior_roost_report("senior_year_transition")
			_ticker_label.text = String(transition.get("outcome", "NEXT SENIOR YEAR OPEN."))
		SeniorRoostStateScript.STATUS_ACTIVE:
			_open_contract_board_or_begin_next_shift()
		_:
			_ticker_label.text = "SENIOR ROOST HELD. The career ledger is not ready to continue."


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
		_save_campaign_checkpoint("credit_memo_required")
		return
	_campaign_review_stage = &"active"
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
	_set_campaign_modal_open(false)
	if not _simulation.begin_next_shift_briefing():
		_ticker_label.text = "NEXT SHIFT HELD. Finish the farmer review before filing another briefing."
		return
	_update_campaign_objectives_label()
	_save_campaign_checkpoint("next_shift_briefing")


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
	_save_campaign_checkpoint("market_contract_board")


func _continue_from_contract_board() -> void:
	var board := _simulation.market_contract_board_status()
	var active := board.get("active", {}) as Dictionary
	var declined := board.get("decline_receipt", {}) as Dictionary
	if active.is_empty() and declined.is_empty():
		_ticker_label.text = "FARM MUTUAL FILE INCOMPLETE. Sign one disclosed binder or explicitly keep the standard book."
		return
	_begin_next_shift_from_campaign()


func _show_campaign_final_review() -> void:
	_campaign_review_stage = &"final"
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	if _audio_feedback != null and _audio_feedback.has_method("play_campaign_outcome"):
		_audio_feedback.call(
			"play_campaign_outcome",
			_campaign_state.outcome == CampaignStateScript.OUTCOME_PASSED,
		)
	_campaign_ui.show_final_review(_campaign_presentation_snapshot(&"final"))
	_set_campaign_modal_open(true)
	_save_campaign_checkpoint("final_review")


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
		"reward": "Complete all three orders for a +3 score bundle.",
	}
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
	var score_receipt := _campaign_state.latest_score_receipt()
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
		"challenge_contract": challenge_contract,
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
		"probation_safeguard_forecast": safeguard_forecast,
		"hen_highlight": hen_highlight,
		"leadership_record": leadership_record,
		"ending": ending,
		"passed": bool(final_evaluation.get("passed", false)),
		"final_message": final_message,
	}


func _senior_presentation_snapshot(view: StringName) -> Dictionary:
	var state_snapshot: Dictionary = _senior_roost_state.snapshot()
	var status_id: StringName = _senior_roost_state.status
	var annual_review: Dictionary = _senior_roost_state.last_annual_review
	var quarter_review: Dictionary = _senior_roost_state.last_quarter_review
	var active_policy := _senior_roost_state.active_policy()
	var mandate_required := _senior_roost_state.requires_annual_mandate()
	var active_mandate := _senior_roost_state.active_annual_mandate()
	var mandate_progress := _senior_roost_state.current_annual_mandate_progress(
		_campaign_live_metrics(_simulation.snapshot()) if view == &"active" else {}
	)
	var mandate_tier := _senior_roost_state.mandate_tier_eligibility()
	var mandate_mastery := state_snapshot.get("mandate_mastery", {}) as Dictionary
	var year_number := _senior_roost_state.current_year_number()
	var quarter_number := _senior_roost_state.current_quarter_in_year()
	var display_shift := _senior_roost_state.current_shift_in_quarter()
	if status_id == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		year_number = maxi(1, int(annual_review.get("year", _senior_roost_state.completed_years)))
		quarter_number = SeniorRoostStateScript.QUARTERS_PER_YEAR
		display_shift = SeniorRoostStateScript.SHIFTS_PER_QUARTER
	elif status_id == SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
		display_shift = 1
	elif view == &"between_shift" and not _senior_roost_state.current_quarter_shifts.is_empty():
		display_shift = clampi(
			int(_senior_roost_state.last_shift_result.get("shift_in_quarter", 1)),
			1,
			SeniorRoostStateScript.SHIFTS_PER_QUARTER,
		)

	var policy_cards: Array[Dictionary] = []
	if status_id == SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
		policy_cards = (
			_senior_board_mandate_cards()
			if mandate_required else
			_senior_roost_state.policy_catalog(_simulation.spendable_fund_cents())
		)

	var report_heading := "SENIOR ROOST QUARTERLY FILING"
	var report_note := "The permanent career ledger remains open."
	var continue_label := "PLAN NEXT SENIOR SHIFT  [C]"
	var continue_tooltip := "Open the next Senior Roost shift briefing."
	var objective := {
		"title": "FILE A CAPITAL POLICY",
		"description": "Choose how the next three shifts trade money, pressure, and flock trust.",
		"reward": "Every completed quarter awards up to 3 permanent Roost Marks.",
	}
	var secondary_display := "%d / %d" % [
		_senior_roost_state.current_quarter_shifts.size(),
		SeniorRoostStateScript.SHIFTS_PER_QUARTER,
	]
	var secondary_caption := "QUARTER SHIFTS"
	var secondary_tooltip := "Three filed shifts close a Senior Roost quarter."

	if status_id == SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
		if mandate_required:
			report_heading = "YEAR %d · ANNUAL BOARD MANDATE" % year_number
			continue_label = "SELECT A MANDATE BEFORE Q1 POLICY  [C]"
			continue_tooltip = "Choose one frozen twelve-shift Board Mandate; the Standard Board Book never stakes Roost Marks."
			secondary_display = "%d" % int(mandate_tier.get("mandate_seals", 0))
			secondary_caption = "BOARD SEALS"
			secondary_tooltip = _senior_mandate_tier_tooltip(mandate_tier)
			report_note = "Choose the year-long terms before quarterly policy. Harder books stake available Roost Marks; success returns the stake and earns more permanent Board Seals. PORTFOLIO %d / %d MASTERED; first clears advance Coop Commendations." % [
				int(mandate_mastery.get("mastered_count", 0)),
				int(mandate_mastery.get("total_count", SeniorRoostStateScript.MANDATE_IDS.size())),
			]
			if year_number > 1 and not annual_review.is_empty():
				var previous_year_passed := bool(annual_review.get("passed", false))
				var transition_note := (
					"YEAR %d CLEARED  ·  BASELINE +1 FOR THIS YEAR." % (year_number - 1)
					if previous_year_passed else
					"RECOVERY YEAR  ·  BASELINE +2  ·  FARMER FAVOR -5."
				)
				report_note = "%s %s" % [transition_note, report_note]
			objective = {
				"title": "CHOOSE THE YEAR'S TERMS",
				"description": "Compare all three target bundles, reward, failure cost, and stake. The first card is always a valid no-stake fallback.",
				"reward": "%s  /  PORTFOLIO %d / %d" % [
					_senior_mandate_tier_tooltip(mandate_tier),
					int(mandate_mastery.get("mastered_count", 0)),
					int(mandate_mastery.get("total_count", SeniorRoostStateScript.MANDATE_IDS.size())),
				],
			}
		else:
			report_heading = "YEAR %d · QUARTER %d CAPITAL FILING" % [year_number, quarter_number]
			continue_label = "SELECT A POLICY TO OPEN QUARTER  [C]"
			continue_tooltip = "File one available capital policy before the quarter can open."
			secondary_display = (
				"%d / 100" % int(quarter_review.get("score", 0))
				if not quarter_review.is_empty() else
				"OPEN"
			)
			secondary_caption = "LAST QUARTER"
			if quarter_review.is_empty():
				report_note = "Annual terms filed. Choose the irreversible capital policy that governs this three-shift quarter."
			else:
				var available_sponsorship_marks := int(state_snapshot.get(
					"available_roost_marks",
					_senior_roost_state.roost_marks,
				))
				var sponsorship_mark_cost := int(state_snapshot.get(
					"sponsorship_mark_cost",
					SeniorRoostStateScript.SPONSORSHIP_MARK_COST,
				))
				var sponsorship_note := (
					"Optional Career Sponsorship is available below."
					if available_sponsorship_marks >= sponsorship_mark_cost else
					"Sponsorship unlock: %d banked marks (%d available)." % [
						sponsorship_mark_cost,
						available_sponsorship_marks,
					]
				)
				report_note = "Q%d filed at %d / 100 for +%d Roost Mark%s. File one policy. %s" % [
					int(quarter_review.get("quarter_number", 0)),
					int(quarter_review.get("score", 0)),
					int(quarter_review.get("marks_awarded", 0)),
					"" if int(quarter_review.get("marks_awarded", 0)) == 1 else "s",
					sponsorship_note,
				]
				var quarter_breakdown := state_snapshot.get(
					"last_quarter_score_breakdown",
					{},
				) as Dictionary
				var filed_score := int(quarter_review.get("score", 0))
				var marks_awarded := int(quarter_review.get("marks_awarded", 0))
				var credit_leaders: Array[String] = []
				for component_value in quarter_breakdown.get("components", []):
					var component := component_value as Dictionary
					if int(component.get("score", 0)) <= 0:
						continue
					credit_leaders.append("%s %d/%d" % [
						String(component.get("label", "SENIOR CREDIT")),
						int(component.get("score", 0)),
						int(component.get("max_score", 0)),
					])
					if credit_leaders.size() == 3:
						break
				var result_lines: Array[String] = [
					"FILED SCORE  ·  %d / 100  ·  +%d ROOST MARK%s" % [
						filed_score,
						marks_awarded,
						"" if marks_awarded == 1 else "S",
					],
				]
				if not credit_leaders.is_empty():
					result_lines.append("CREDIT LEADERS  ·  %s" % "  ·  ".join(credit_leaders))
				var recoverable := quarter_breakdown.get(
					"largest_recoverable_component",
					{},
				) as Dictionary
				if recoverable.is_empty():
					result_lines.append("TOP MARK TIER  ·  NO RECOVERABLE SENIOR POINTS")
				else:
					result_lines.append("NEXT EDGE  ·  %s  ·  +%d RECOVERABLE" % [
						String(recoverable.get("label", "SENIOR STANDING")),
						int(recoverable.get("recoverable_points", 0)),
					])
					result_lines.append(String(recoverable.get(
						"cause",
						"The closing ledger identifies the next recoverable edge.",
					)))
				objective = {
					"title": "QUARTER %d FILED  ·  REWARD RECEIPT" % int(
						quarter_review.get("quarter_number", 0)
					),
					"description": "\n".join(result_lines),
					"reward": "%d lifetime Roost Mark%s" % [
						_senior_roost_state.roost_marks,
						"" if _senior_roost_state.roost_marks == 1 else "s",
					],
				}
				if not mandate_progress.is_empty():
					var board_status := "BOARD %d / %d TARGETS MET" % [
						int(mandate_progress.get("objectives_met", 0)),
						int(mandate_progress.get("objectives_total", 0)),
					]
					var mandate_blocker := mandate_progress.get(
						"largest_recoverable_blocker",
						{},
					) as Dictionary
					if mandate_blocker.is_empty():
						board_status += "  ·  YEAR BOOK ON TRACK"
					else:
						board_status += "  ·  NEXT %s %d / %d" % [
							String(mandate_blocker.get("label", "ANNUAL TARGET")),
							int(mandate_blocker.get("actual", 0)),
							int(mandate_blocker.get("target", 0)),
						]
					objective["reward"] = "%s  ·  %s" % [
						String(objective.get("reward", "")),
						board_status,
					]
	elif status_id == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		var annual_passed := bool(annual_review.get("passed", false))
		var strategy_recap := SeniorRoostStateScript.annual_strategy_recap(annual_review)
		var mandate_settlement := annual_review.get(
			"mandate_settlement",
			_senior_roost_state.last_mandate_settlement,
		) as Dictionary
		var mandate_succeeded := bool(mandate_settlement.get("success", false))
		var seals_after := int(mandate_settlement.get(
			"mandate_seals_after",
			_senior_roost_state.mandate_seals,
		))
		var seals_before := maxi(
			0,
			seals_after - int(mandate_settlement.get("seal_reward", 0)),
		)
		var mandate_tier_before := SeniorRoostStateScript.mandate_tier_for_seals(seals_before)
		var mandate_tier_after := SeniorRoostStateScript.mandate_tier_for_seals(seals_after)
		var mandate_unlock_note := ""
		if mandate_tier_after > mandate_tier_before:
			mandate_unlock_note = " Advanced mandate tier %d unlocked for Year %d." % [
				mandate_tier_after,
				year_number + 1,
			]
		report_heading = "YEAR %d ANNUAL ROOST REVIEW" % year_number
		report_note = "%s  Annual score %d / 100 · welfare %d%% · obedience %d%% · farmer favor %d%% · shell cracks %.1f%%." % [
			"SAFEGUARDS PASSED." if annual_passed else "PERFORMANCE IMPROVEMENT YEAR REQUIRED.",
			int(annual_review.get("score", 0)),
			int(annual_review.get("welfare", 0)),
			int(annual_review.get("compliance", 0)),
			int(annual_review.get("farmer_favor", 0)),
			float(int(annual_review.get("crack_rate_basis_points", 0))) / 100.0,
		]
		var annual_available_marks := int(state_snapshot.get(
			"available_roost_marks",
			_senior_roost_state.available_roost_marks(),
		))
		var annual_sponsorship_cost := int(state_snapshot.get(
			"sponsorship_mark_cost",
			SeniorRoostStateScript.SPONSORSHIP_MARK_COST,
		))
		report_note += (
			" Career Sponsorship may be filed before Year %d planning." % (year_number + 1)
			if annual_available_marks >= annual_sponsorship_cost else
			" Sponsorship needs %d available marks; %d currently banked." % [
				annual_sponsorship_cost,
				annual_available_marks,
			]
		)
		if not mandate_settlement.is_empty():
			report_note += " %s" % String(mandate_settlement.get(
				"outcome",
				"The annual Board Mandate has been settled.",
			))
			if mandate_succeeded:
				var settled_mandate_id := StringName(String(mandate_settlement.get("mandate_id", "")))
				var mastery_counts := state_snapshot.get("mandate_success_counts", {}) as Dictionary
				var mastery_count := int(mastery_counts.get(settled_mandate_id, 0))
				report_note += " %s / BOARD PORTFOLIO %d / %d." % [
					"NEW BOOK MASTERED" if mastery_count == 1 else "BOOK REFILED x%d" % mastery_count,
					int(mandate_mastery.get("mastered_count", 0)),
					int(mandate_mastery.get("total_count", SeniorRoostStateScript.MANDATE_IDS.size())),
				]
		report_note += mandate_unlock_note
		continue_label = "BEGIN YEAR %d PLANNING  [C]" % (year_number + 1)
		continue_tooltip = (
			"Accept the annual review. Next year's baseline quota rises by one egg."
			if annual_passed else
			"Accept the improvement year. Baseline quota rises by two and farmer favor falls by five."
		)
		objective = {
			"title": "%s · YEAR %d %s" % [
				String(mandate_settlement.get("mandate_name", "BOARD MANDATE")),
				year_number,
				"SEALED" if mandate_succeeded else "HELD",
			],
			"description": (
				"The career continues with a one-egg baseline increase."
				if annual_passed else
				"The career continues under a two-egg quota increase and reduced farmer favor."
			) + (
				" Board Mandate succeeded: +%d permanent seal%s; %d staked mark%s returned."
				% [
					int(mandate_settlement.get("seal_reward", 0)),
					"" if int(mandate_settlement.get("seal_reward", 0)) == 1 else "s",
					int(mandate_settlement.get("stake_returned", 0)),
					"" if int(mandate_settlement.get("stake_returned", 0)) == 1 else "s",
				]
				if mandate_succeeded else
				(" Board Mandate failed: no seal filed; no Roost Marks were at risk."
				if int(mandate_settlement.get("stake_marks", 0)) == 0 else
				" Board Mandate failed: %d staked Roost Mark%s permanently spent."
				% [
					int(mandate_settlement.get("stake_forfeited", 0)),
					"" if int(mandate_settlement.get("stake_forfeited", 0)) == 1 else "s",
				])
			),
			"reward": (
				"+3 annual Roost Marks" if annual_passed else "No annual bonus marks"
			) + " · %d total Board Seals  /  %d / %d BOOKS MASTERED" % [
				seals_after,
				int(mandate_mastery.get("mastered_count", 0)),
				int(mandate_mastery.get("total_count", SeniorRoostStateScript.MANDATE_IDS.size())),
			] + (
				" · MANDATE TIER %d UNLOCKED" % mandate_tier_after
				if mandate_tier_after > mandate_tier_before else
				""
			),
		}
		if not strategy_recap.is_empty():
			var recap_lines := strategy_recap.get("lines", []) as Array
			objective["description"] = "%s\n\nYEAR STRATEGY RECEIPT\n%s" % [
				String(objective.get("description", "")),
				"\n".join(recap_lines),
			]
		secondary_display = "%d / 100" % int(annual_review.get("score", 0))
		secondary_caption = "ANNUAL SCORE"
		secondary_tooltip = "Annual passage requires 60 plus every flock, shell, favor, and solvency safeguard."
	else:
		var shifts_filed: int = _senior_roost_state.current_quarter_shifts.size()
		var policy_title := String(active_policy.get("title", "SENIOR POLICY"))
		if shifts_filed == 0:
			report_heading = "QUARTER %d POLICY FILED" % quarter_number
			report_note = String(_senior_roost_state.active_policy_receipt.get(
				"outcome",
				"%s now governs the next three shifts." % policy_title,
			))
			continue_label = "BEGIN QUARTER %d · SHIFT 1  [C]" % quarter_number
		else:
			report_heading = "QUARTER %d · SHIFT %d FILED" % [quarter_number, display_shift]
			report_note = "%s remains active. %d of %d quarter shifts are now filed." % [
				policy_title,
				shifts_filed,
				SeniorRoostStateScript.SHIFTS_PER_QUARTER,
			]
			continue_label = "PLAN QUARTER %d · SHIFT %d  [C]" % [
				quarter_number,
				_senior_roost_state.current_shift_in_quarter(),
			]
		var objective_rows: Array[Dictionary] = _senior_roost_state.current_objective_progress(
			_campaign_live_metrics(_simulation.snapshot()) if view == &"active" else {}
		)
		if not objective_rows.is_empty():
			var objective_lines: Array[String] = []
			for row in objective_rows:
				objective_lines.append("%s · %s" % [
					"ON TRACK" if bool(row.get("projected_met", false)) else "NEEDS ACTION",
					String(row.get("description", "Quarter safeguard filed.")),
				])
			objective = {
				"title": "YEAR %d · QUARTER %d · %s" % [year_number, quarter_number, policy_title],
				"description": "\n".join(objective_lines),
				"reward": "Score 40+ earns 1 Roost Mark Â· 60+ earns 2 Â· 80+ earns 3.",
			}
		if not mandate_progress.is_empty():
			var mandate_lines := _senior_mandate_progress_lines(mandate_progress)
			objective["description"] = "%s\n\nANNUAL BOARD · %s\n%s" % [
				String(objective.get("description", "Quarter safeguards pending.")),
				String(mandate_progress.get("mandate_name", "BOARD MANDATE")),
				"\n".join(mandate_lines),
			]
			objective["reward"] = "%d / %d annual shifts · %d / %d targets currently met · %d Roost Mark%s staked" % [
				int(mandate_progress.get("shifts_recorded", 0)),
				int(mandate_progress.get("shifts_target", 12)),
				int(mandate_progress.get("objectives_met", 0)),
				int(mandate_progress.get("objectives_total", 0)),
				int(mandate_progress.get("stake_marks", 0)),
				"" if int(mandate_progress.get("stake_marks", 0)) == 1 else "s",
			]

	var policy_receipt: Dictionary = {}
	if status_id == SeniorRoostStateScript.STATUS_ACTIVE and not _senior_roost_state.active_policy_receipt.is_empty():
		policy_receipt = _senior_roost_state.active_policy_receipt.duplicate(true)
		policy_receipt["day"] = display_shift
		policy_receipt["decision_id"] = "senior_quarter_policy"
		policy_receipt["option_id"] = String(_senior_roost_state.active_policy_id)

	var hen_highlight: Dictionary = {}
	# The named-hen story remains on each in-quarter shift receipt. At a quarter
	# or annual boundary the policy/reward filing owns the hierarchy; repeating
	# the previous shift highlight there pushed the actual policy controls below
	# the fold without adding a new decision.
	if (
		_senior_roost_state.total_senior_shifts > 0
		and status_id == SeniorRoostStateScript.STATUS_ACTIVE
	):
		var highlight_value: Variant = _last_workday_report.get("hen_highlight", {})
		if highlight_value is Dictionary:
			hen_highlight = (highlight_value as Dictionary).duplicate(true)
			hen_highlight["day"] = display_shift

	var last_quarter_score := int(quarter_review.get("score", 0))
	var available_roost_marks := int(state_snapshot.get(
		"available_roost_marks",
		_senior_roost_state.roost_marks,
	))
	var invested_roost_marks := int(state_snapshot.get("roost_marks_spent", 0))
	var staked_roost_marks := int(state_snapshot.get("mandate_stake_reserved", 0))
	var forfeited_roost_marks := int(state_snapshot.get("mandate_marks_forfeited", 0))
	var mandate_seals := int(state_snapshot.get("mandate_seals", 0))
	var ledgers: Array[Dictionary] = [
		{
			"label": "Roost Marks",
			"value": _senior_roost_state.roost_marks,
			"detail": "%d AVAILABLE  ·  %d INVESTED  ·  %d STAKED  ·  %d FORFEITED" % [
				available_roost_marks,
				invested_roost_marks,
				staked_roost_marks,
				forfeited_roost_marks,
			],
		},
		{
			"label": "Board Seals",
			"value": mandate_seals,
			"format": "number",
			"detail": "MANDATE TIER %d  ·  %s" % [
				int(mandate_tier.get("eligible_tier", 0)),
				_senior_mandate_tier_tooltip(mandate_tier).to_upper(),
			],
		},
		{
			"label": "Quarter score",
			"value": last_quarter_score,
			"format": "number",
			"detail": "LAST CLOSED QUARTER" if not quarter_review.is_empty() else "FIRST QUARTER OPEN",
		},
		{
			"label": "Spendable Feed Fund",
			"value": _simulation.spendable_fund_cents(),
			"format": "currency_cents",
			"detail": "AFTER OPERATING RESERVE",
		},
	]
	if status_id == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		ledgers[2] = {
			"label": "Annual score",
			"value": int(annual_review.get("score", 0)),
			"format": "number",
			"detail": "PASSED" if bool(annual_review.get("passed", false)) else "IMPROVEMENT YEAR",
		}
		ledgers[3] = {
			"label": "Years passed",
			"value": _senior_roost_state.successful_years,
			"detail": "OF %d REVIEWED" % _senior_roost_state.completed_years,
		}

	return {
		"view": view,
		"career_mode": "senior_roost",
		"status": "SENIOR ROOST",
		"day": display_shift,
		"total_days": SeniorRoostStateScript.SHIFTS_PER_QUARTER,
		"senior_year": year_number,
		"senior_quarter": quarter_number,
		"day_badge_text": (
			"YEAR %d · ANNUAL REVIEW" % year_number
			if status_id == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW else
			("Y%d · ANNUAL MANDATE" % year_number
			if mandate_required else
			("Y%d · Q%d · POLICY" % [year_number, quarter_number]
			if status_id == SeniorRoostStateScript.STATUS_QUARTER_CHOICE else
			"Y%d · Q%d · SHIFT %d / %d" % [year_number, quarter_number, display_shift, SeniorRoostStateScript.SHIFTS_PER_QUARTER]))
		),
		"score": _senior_roost_state.roost_marks,
		"score_caption": "ROOST MARKS",
		"rank": _senior_roost_state.promotion_title(),
		"rank_caption": "CAREER TITLE",
		"secondary_metric_display": secondary_display,
		"secondary_metric_caption": secondary_caption,
		"secondary_metric_tooltip": secondary_tooltip,
		"ledgers": ledgers,
		"ledger_section_title": "SENIOR CAREER LEDGERS",
		"report_kicker": "SENIOR ROOST  //  YEAR %d  //  QUARTER %d" % [year_number, quarter_number],
		"report_heading": report_heading,
		"report_note": report_note,
		"objective_section_title": "ANNUAL BOARD MANDATE" if not active_mandate.is_empty() or mandate_required else "SENIOR OBJECTIVE",
		"next_objective": objective,
		"milestone_choices": policy_cards,
		"selected_milestone": (
			String(active_mandate.get("id", ""))
			if mandate_required else
			String(_senior_roost_state.active_policy_id)
		),
		"choice_required": status_id == SeniorRoostStateScript.STATUS_QUARTER_CHOICE,
		"choice_section_title": (
			"ANNUAL BOARD MANDATE  //  FILE ONE"
			if mandate_required else
			"QUARTERLY CAPITAL POLICY  //  FILE ONE"
		),
		"choice_hint": (
			"One twelve-shift mandate governs the year. Compare targets, seal reward, and any Roost Mark stake."
			if mandate_required else
			(
				"One policy governs three shifts. LAST YEAR shows how each option affects the prior binding safeguard."
				if (
					_senior_roost_state.completed_years > 0
					and _senior_roost_state.current_year_quarters.is_empty()
				) else
				"One irreversible policy governs the next three shifts."
			)
		),
		"continue_label": continue_label,
		"continue_tooltip": continue_tooltip,
		"credit_memo": policy_receipt,
		"score_receipt": {},
		"hen_highlight": hen_highlight,
		"senior_roost": state_snapshot,
		"annual_mandate": active_mandate,
		"annual_mandate_progress": mandate_progress,
		"annual_strategy_recap": (
			SeniorRoostStateScript.annual_strategy_recap(annual_review)
			if status_id == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW else
			{}
		),
		"mandate_tier": mandate_tier,
		"career_sponsorship": _career_sponsorship_presentation_snapshot(),
	}


func _senior_board_mandate_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for offer in _senior_roost_state.annual_mandate_catalog():
		var targets: Array[String] = []
		for objective_value in offer.get("objectives", []) as Array:
			if not objective_value is Dictionary:
				continue
			var target := objective_value as Dictionary
			targets.append("%s %s" % [
				String(target.get("label", "TARGET")),
				_senior_mandate_target_text(
					String(target.get("metric", "")),
					String(target.get("comparison", "minimum")),
					int(target.get("target", 0)),
				),
			])
		var stake := int(offer.get("stake_marks", 0))
		var mastery_text := String(offer.get("mastery_text", "NEW PORTFOLIO CLEAR"))
		var available := bool(offer.get("available", true))
		var unavailable_reason := String(offer.get("unavailable_reason", ""))
		var stake_text := "NO MARK STAKE" if stake <= 0 else "%d ROOST MARK%s STAKED" % [
			stake,
			"" if stake == 1 else "S",
		]
		var effect_text := "TIER %d  /  %s  /  %s  /  +%d SEAL%s\nTARGETS  %s" % [
			int(offer.get("tier", 0)),
			mastery_text,
			stake_text,
			int(offer.get("seal_reward", 1)),
			"" if int(offer.get("seal_reward", 1)) == 1 else "S",
			"  ·  ".join(targets),
		]
		if not available and not unavailable_reason.is_empty():
			effect_text += "\nHELD  ·  %s" % unavailable_reason.to_upper()
		var result_tooltip := (
			unavailable_reason
			if not available else
			"SUCCESS: %s\nFAILURE: %s" % [
				String(offer.get("reward", "Earn permanent Board Seals.")),
				String(offer.get("failure", "No seal is awarded.")),
			]
		)
		result_tooltip = "PORTFOLIO: %s\n%s" % [mastery_text, result_tooltip]
		cards.append({
			"id": String(offer.get("id", "")),
			"title": String(offer.get("name", "ANNUAL BOARD MANDATE")),
			"description": String(offer.get("summary", "Twelve-shift annual performance book.")),
			"effect": effect_text,
			"stake_marks": stake,
			"confirmation_required": stake > 0,
			"confirmation_label": "CONFIRM %d-MARK STAKE  [C]" % stake,
			"confirmation_tooltip": (
				"Confirm the %d-mark career stake. The marks remain reserved for this twelve-shift Book; success returns them, while failure permanently spends them."
				% stake
			),
			"available": available,
			"unavailable_reason": unavailable_reason,
			"tooltip": result_tooltip,
		})
	return cards


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


func _senior_mandate_tier_tooltip(tier: Dictionary) -> String:
	var eligible := int(tier.get("eligible_tier", 0))
	var seals_to_next := int(tier.get("seals_to_next_tier", 0))
	if eligible >= int(tier.get("max_tier", 3)):
		return "Maximum Board Mandate tier unlocked."
	return "%d more Board Seal%s unlock%s mandate tier %d." % [
		seals_to_next,
		"" if seals_to_next == 1 else "s",
		"s" if seals_to_next == 1 else "",
		eligible + 1,
	]


func _career_sponsorship_presentation_snapshot() -> Dictionary:
	if not _campaign_senior_roost or _senior_roost_state == null:
		return {"visible": false}
	var status_id: StringName = _senior_roost_state.status
	var gate_open := status_id in [
		SeniorRoostStateScript.STATUS_QUARTER_CHOICE,
		SeniorRoostStateScript.STATUS_ANNUAL_REVIEW,
	]
	var has_closed_quarter: bool = _senior_roost_state.completed_quarters > 0
	if (
		not gate_open
		or not has_closed_quarter
		or _senior_roost_state.requires_annual_mandate()
	):
		return {"visible": false}

	var simulation_snapshot := _simulation.snapshot()
	var flock_care := simulation_snapshot.get("flock_care", {}) as Dictionary
	var training_terms := flock_care.get("training_terms", {}) as Dictionary
	var senior_snapshot: Dictionary = _senior_roost_state.snapshot()
	var mark_cost := int(senior_snapshot.get(
		"sponsorship_mark_cost",
		SeniorRoostStateScript.SPONSORSHIP_MARK_COST,
	))
	var available_marks := int(senior_snapshot.get(
		"available_roost_marks",
		_senior_roost_state.roost_marks,
	))
	var fund_cost := int(training_terms.get(
		"effective_sponsorship_cost_cents",
		training_terms.get(
			"effective_cost_cents",
			simulation_snapshot.get("career_sponsorship_cost_cents", 1200),
		),
	))
	var spendable_fund := int(simulation_snapshot.get(
		"spendable_fund_cents",
		_simulation.spendable_fund_cents(),
	))
	var planning_open := bool(simulation_snapshot.get(
		"career_sponsorship_planning_open",
		false,
	))
	var sponsorship_filed_this_gate := false
	var sponsorship_history_value: Variant = senior_snapshot.get("sponsorship_history", [])
	if sponsorship_history_value is Array:
		for record_value in sponsorship_history_value as Array:
			if (
				record_value is Dictionary
				and int((record_value as Dictionary).get("career_quarter", -1)) == _senior_roost_state.completed_quarters
			):
				sponsorship_filed_this_gate = true
				break

	var lanes: Array[Dictionary] = []
	for lane_value in _simulation.routing_catalog():
		var lane := lane_value as Dictionary
		lanes.append({
			"id": String(lane.get("id", "")),
			"label": String(lane.get("display_name", lane.get("short_name", "CLAIM LANE"))),
		})

	var eligible_workers: Array[Dictionary] = []
	for worker_value in simulation_snapshot.get("workers", []):
		if worker_value is not Dictionary:
			continue
		var worker := worker_value as Dictionary
		if not _is_worker_employed(worker) or int(worker.get("career_level", 0)) < 1:
			continue
		if bool(worker.get("has_secondary_specialty", false)):
			continue
		if bool(worker.get("cross_training_pending", false)):
			continue
		eligible_workers.append({
			"id": int(worker.get("id", -1)),
			"name": String(worker.get("name", "CLAIMS HEN")),
			"career_title": String(worker.get("career_title", "ACCREDITED LAYER")),
			"primary_specialty": String(worker.get("specialty", "")),
			"primary_specialty_name": String(worker.get("specialty_name", "PRIMARY CLAIM LANE")),
			"secondary_specialty": String(worker.get("secondary_specialty", "")),
			"wage_cents": int(worker.get("daily_wage_cents", 0)),
			"current_daily_wage_cents": int(worker.get("daily_wage_cents", 0)),
		})

	var unavailable_reason := ""
	if sponsorship_filed_this_gate:
		unavailable_reason = "This quarter's career sponsorship has already been filed. Bank remaining marks for the next quarter."
	elif not planning_open:
		unavailable_reason = "Career sponsorships are authorized only while the office is in a closed-shift planning review."
	elif available_marks < mark_cost:
		unavailable_reason = "%d more Roost Mark%s required. Marks may be banked across quarters." % [
			mark_cost - available_marks,
			"" if mark_cost - available_marks == 1 else "s",
		]
	elif spendable_fund < fund_cost:
		unavailable_reason = "$%.2f more protected Feed Fund is required." % (float(fund_cost - spendable_fund) / 100.0)
	elif eligible_workers.is_empty():
		unavailable_reason = "No employed Accredited Layer is currently eligible for a first secondary claim lane."

	# A disabled multi-field form competes with the irreversible quarterly policy
	# choice and pushes its filing action below a typical laptop viewport. The
	# quarter heading already publishes the exact three-mark unlock, so keep this
	# optional surface out of the planning hierarchy until it can be used.
	if available_marks < mark_cost and not sponsorship_filed_this_gate:
		return {
			"visible": false,
			"available_marks": available_marks,
			"mark_cost": mark_cost,
			"unavailable_reason": unavailable_reason,
		}

	return {
		"visible": true,
		"available_marks": available_marks,
		"lifetime_marks": _senior_roost_state.roost_marks,
		"invested_marks": int(senior_snapshot.get("roost_marks_spent", 0)),
		"mark_cost": mark_cost,
		"fund_cost_cents": fund_cost,
		"training_terms": training_terms.duplicate(true),
		"spendable_fund_cents": spendable_fund,
		"eligible_workers": eligible_workers,
		"lanes": lanes,
		"unavailable_reason": unavailable_reason,
	}


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
	var worker_name := String(row.get("worker_name", "A claims hen"))
	var eggs := maxi(0, int(row.get("eggs", 0)))
	var credit_cents := maxi(0, int(row.get("credit_cents", 0)))
	return {
		"version": 1,
		"type": "ledger_leader",
		"day": completed_shift,
		"worker_id": int(row.get("worker_id", -1)),
		"worker_name": worker_name,
		"career_title": "CLAIMS HEN",
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
	_on_announcement_posted(
		"%s'S FILE IS OPEN: choose the policy that will govern her desk and today's clutch."
		% String(worker.get("name", "Mabel")).to_upper()
	)
	_simulation.announce_pending_decision()


func _make_first_clutch_state(dismissed: bool = true) -> Dictionary:
	return {
		"version": FIRST_CLUTCH_VERSION,
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
	_first_clutch_completion_generation += 1
	_first_clutch_completion_hold_until_msec = 0
	_first_clutch = _make_first_clutch_state(not enabled)
	if enabled:
		_capacity_marker_context_revealed = false
		_apply_office_capacity_visibility(
			_office_capacity_from_snapshot(_simulation.snapshot()),
			false,
		)
	_refresh_first_clutch_ui(_simulation.snapshot())


func _normalize_first_clutch_state(value: Dictionary, legacy_missing: bool = false) -> Dictionary:
	if legacy_missing or value.is_empty():
		var missing_state := _make_first_clutch_state(true)
		missing_state["reinvestment_grandfathered"] = true
		return missing_state
	var source_version := int(value.get("version", -1))
	if source_version not in [1, FIRST_CLUTCH_VERSION]:
		var incompatible_state := _make_first_clutch_state(true)
		incompatible_state["reinvestment_grandfathered"] = true
		return incompatible_state
	var legacy_v1 := source_version == 1
	var normalized := _make_first_clutch_state(bool(value.get("dismissed", false)))
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
		and bool(state.get("checkin_filed", false))
		and int(state.get("assisted_worker_id", -1)) == target_worker_id
		and int(state.get("assisted_claim_id", -1)) >= 0
		and bool(state.get("delivery_laid", false))
		and bool(state.get("delivery_seen", false))
	)


func first_clutch_snapshot() -> Dictionary:
	var result := _first_clutch.duplicate(true)
	result["stage"] = String(_first_clutch_stage())
	result["progress"] = _first_clutch_progress()
	result["reinvestment"] = _simulation.first_clutch_reinvestment_status().duplicate(true)
	result["orders_handoff_pending"] = _first_clutch_orders_handoff_pending()
	return result


func _first_clutch_tracking_active() -> bool:
	return (
		not bool(_first_clutch.get("dismissed", true))
		and not bool(_first_clutch.get("completed", false))
		and _campaign_review_stage == &"active"
		and _campaign_state != null
		and _campaign_state.outcome == CampaignStateScript.OUTCOME_IN_PROGRESS
	)


func _first_clutch_orders_handoff_pending() -> bool:
	return (
		not bool(_first_clutch.get("dismissed", true))
		and bool(_first_clutch.get("completed", false))
		and _first_clutch_reinvestment_resolved()
		and not bool(_first_clutch.get("orders_handoff_acknowledged", false))
	)


func _first_clutch_reinvestment_resolved() -> bool:
	if (
		bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("reinvestment_grandfathered", false))
	):
		return true
	var status := _simulation.first_clutch_reinvestment_status()
	return bool(status.get("resolved", false)) or StringName(status.get("status", &"unavailable")) in [
		&"purchased",
		&"banked",
	]


func _first_clutch_worker_snapshot(snapshot: Dictionary, worker_id: int) -> Dictionary:
	if worker_id < 0:
		return {}
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id and _is_worker_employed(worker):
			return worker
	return {}


func _first_clutch_record_inspection(worker_id: int) -> void:
	if (
		not _first_clutch_tracking_active()
		or _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING
		or bool(_first_clutch.get("inspected", false))
	):
		return
	var bound_worker_id := int(_first_clutch.get("target_worker_id", -1))
	if bound_worker_id >= 0 and worker_id != bound_worker_id:
		return
	var snapshot := _simulation.snapshot()
	var worker := _first_clutch_worker_snapshot(snapshot, worker_id)
	if worker.is_empty():
		return
	if bound_worker_id < 0:
		_first_clutch["target_worker_id"] = worker_id
	_first_clutch["inspected"] = true
	if StringName(worker.get("assigned_lane", &"auto")) == StringName(worker.get("specialty", &"")):
		_first_clutch["specialty_routed"] = true
	if (
		int(worker.get("last_personnel_action_day", 0)) == _simulation.day
		and StringName(worker.get("last_personnel_action", &"")) != &""
	):
		_first_clutch["checkin_filed"] = true
		_first_clutch["checkin_worker_id"] = worker_id
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)
	_save_campaign_checkpoint("first_clutch_inspected")


func _first_clutch_record_routing(worker_id: int, lane: StringName) -> void:
	if not _first_clutch_tracking_active() or worker_id != int(_first_clutch.get("target_worker_id", -1)):
		return
	var snapshot := _simulation.snapshot()
	var worker := _first_clutch_worker_snapshot(snapshot, worker_id)
	if not worker.is_empty() and lane == StringName(worker.get("specialty", &"")):
		_first_clutch["specialty_routed"] = true
	_first_clutch_try_complete()
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)


func _first_clutch_record_checkin(worker_id: int) -> void:
	if not _first_clutch_tracking_active() or int(_first_clutch.get("target_worker_id", -1)) < 0:
		return
	_first_clutch["checkin_filed"] = true
	_first_clutch["checkin_worker_id"] = worker_id
	_first_clutch_try_complete()
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)


func _first_clutch_record_assist(result: Dictionary) -> void:
	if not _first_clutch_tracking_active() or not bool(result.get("accepted", false)):
		return
	var worker_id := int(result.get("worker_id", -1))
	if worker_id != int(_first_clutch.get("target_worker_id", -1)):
		return
	_first_clutch["assisted_worker_id"] = worker_id
	_first_clutch["assisted_claim_id"] = int(result.get("claim_id", -1))
	_first_clutch["potential_priority_credit_cents"] = maxi(
		0, int(result.get("potential_priority_credit_cents", 0))
	)
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)


func _first_clutch_record_laid_egg(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	claim_id: int = -1,
	priority_credit_cents: int = -1
) -> void:
	if (
		not _first_clutch_tracking_active()
		or worker_id != int(_first_clutch.get("target_worker_id", -1))
		or worker_id != int(_first_clutch.get("assisted_worker_id", -1))
		or (
			claim_id >= 0
			and claim_id != int(_first_clutch.get("assisted_claim_id", -1))
		)
		or bool(_first_clutch.get("delivery_laid", false))
	):
		return
	_first_clutch["delivery_laid"] = true
	_first_clutch["delivered_claim_id"] = (
		claim_id if claim_id >= 0 else int(_first_clutch.get("assisted_claim_id", -1))
	)
	_first_clutch["delivered_quality"] = String(quality)
	_first_clutch["delivered_value_cents"] = maxi(0, value_cents)
	_first_clutch["delivered_priority_credit_cents"] = maxi(
		0,
		priority_credit_cents
		if priority_credit_cents >= 0 else
		(0 if quality == &"cracked" else int(_first_clutch.get("potential_priority_credit_cents", 0))),
	)
	_first_clutch["prior_presentations_pending"] = maxi(
		0, int(_eggs_in_flight_by_worker.get(worker_id, 0))
	)
	# When the player is actively following the induction hen, hand the shot to
	# the sorter so the promised egg journey is visible. Never steal an unrelated
	# camera focus.
	if (
		_routing_ui != null
		and _camera_controller != null
		and _office_storytelling != null
		and _camera_controller.is_focused()
		and _routing_ui.focused_worker_id() == worker_id
	):
		_camera_controller.show_overview()
		_camera_controller.show_event_focus(
			_office_storytelling.sorting_focus_point_global(),
			"SHELL GRADING",
			1.8,
		)
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)


func _first_clutch_record_presentation(
	worker_id: int,
	claim_id: int,
	quality: StringName,
	value_cents: int
) -> void:
	if (
		bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("completed", false))
		or worker_id != int(_first_clutch.get("target_worker_id", -1))
		or not bool(_first_clutch.get("delivery_laid", false))
	):
		return
	var prior_presentations := int(_first_clutch.get("prior_presentations_pending", 0))
	if prior_presentations > 0:
		_first_clutch["prior_presentations_pending"] = prior_presentations - 1
		return
	if (
		claim_id < 0
		or claim_id != int(_first_clutch.get("assisted_claim_id", -1))
		or claim_id != int(_first_clutch.get("delivered_claim_id", -1))
		or worker_id != int(_first_clutch.get("assisted_worker_id", -1))
		or
		StringName(String(_first_clutch.get("delivered_quality", ""))) != quality
		or int(_first_clutch.get("delivered_value_cents", -1)) != maxi(0, value_cents)
	):
		return
	_first_clutch["delivery_seen"] = true
	_first_clutch["delivered_quality"] = String(quality)
	_first_clutch["delivered_value_cents"] = maxi(0, value_cents)
	if not _first_clutch_try_complete():
		var snapshot := _simulation.snapshot()
		_refresh_first_clutch_ui(snapshot)
		_update_guidance(snapshot)
		_save_campaign_checkpoint("first_clutch_delivery_seen")


func _first_clutch_try_complete() -> bool:
	if (
		bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("completed", false))
		or not _first_clutch_state_has_all_steps(_first_clutch)
	):
		return false
	var reinvestment_offer := _simulation.begin_first_clutch_reinvestment(
		int(_first_clutch.get("target_worker_id", -1)),
		int(_first_clutch.get("delivered_claim_id", -1)),
		StringName(String(_first_clutch.get("delivered_quality", ""))),
		int(_first_clutch.get("delivered_value_cents", 0)),
	)
	if not bool(reinvestment_offer.get("accepted", false)):
		push_error(
			"First Clutch completed physically, but its authoritative reinvestment offer was rejected: %s"
			% String(reinvestment_offer.get("reason", "unknown ledger mismatch"))
		)
		return false
	_first_clutch["completed"] = true
	_first_clutch_completion_generation += 1
	var completion_generation := _first_clutch_completion_generation
	_first_clutch_completion_hold_until_msec = Time.get_ticks_msec() + roundi(
		FIRST_CLUTCH_COMPLETION_HOLD_SECONDS * 1000.0
	)
	var priority_credit := int(_first_clutch.get("delivered_priority_credit_cents", 0))
	_ticker_label.text = "FIRST CLUTCH FILED  /  %s EGG  /  $%.2f CREDIT%s" % [
		String(_first_clutch.get("delivered_quality", "sound")).to_upper(),
		float(int(_first_clutch.get("delivered_value_cents", 0))) / 100.0,
		("  /  +$%.2f PRIORITY" % (float(priority_credit) / 100.0) if priority_credit > 0 else ""),
	]
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
	_refresh_flockwatch_navigation(snapshot)
	_update_guidance(snapshot)
	_save_campaign_checkpoint("first_clutch_completed")
	_present_first_clutch_reinvestment(reinvestment_offer)
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
		var list_cost := maxi(0, int(offered.get("list_cost_cents", 0)))
		var procurement_match := maxi(0, int(offered.get("procurement_match_cents", 0)))
		var net_cost := maxi(0, int(offered.get("net_cost_cents", list_cost - procurement_match)))
		var projected_spendable := maxi(0, int(offered.get("projected_spendable_fund_cents", 0)))
		var can_purchase := bool(offered.get("can_purchase", offered.get("affordable", false)))
		options.append({
			"id": StringName(offered.get("id", &"")),
			"label": "INSTALL %s" % String(offered.get("short_name", offered.get("name", "DESK UPGRADE"))).to_upper(),
			"tagline": "INVOICE $%.2f  -  MATCH $%.2f  =  NET $%.2f" % [
				float(list_cost) / 100.0,
				float(procurement_match) / 100.0,
				float(net_cost) / 100.0,
			],
			"preview": "Level %d -> %d  /  spendable $%.2f -> projected $%.2f. %s" % [
				int(offered.get("level_before", 0)),
				int(offered.get("next_level", 1)),
				float(int(offered.get("spendable_fund_cents", spendable_at_collection))) / 100.0,
				float(projected_spendable) / 100.0,
				String(offered.get("description", "The module becomes visible at Mabel's workstation.")),
			],
			"cost_cents": net_cost,
			"can_select": can_purchase,
			"unavailable_reason": String(offered.get(
				"reason",
				"The protected reserve leaves too little spendable Feed Fund for this invoice.",
			)),
		})
	options.append({
		"id": &"bank_fund",
		"label": "BANK THE FEED FUND",
		"tagline": "NO PURCHASE  /  PROCUREMENT MATCH EXPIRES",
		"preview": "Keep fund $%.2f and spendable $%.2f. The unused $%.2f first-egg match is forfeited." % [
			float(int(status.get("current_fund_cents", fund_at_collection))) / 100.0,
			float(int(status.get("current_spendable_fund_cents", spendable_at_collection))) / 100.0,
			float(match_available) / 100.0,
		],
		"cost_cents": 0,
		"can_select": bool(status.get("can_bank", true)),
		"unavailable_reason": String(status.get("reason", "This Feed Fund decision has already been filed.")),
	})
	return {
		"kind": FIRST_CLUTCH_REINVESTMENT_KIND,
		"category": FIRST_CLUTCH_REINVESTMENT_KIND,
		"eyebrow": "FIRST CLUTCH  5 / 5  //  REINVESTMENT",
		"title": "WHAT SHOULD %s\u2019S FIRST EGG BUILD?" % String(status.get("trigger_worker_name", "Mabel")).to_upper(),
		"body": (
			"%s's first egg created $%.2f. At collection, the Feed Fund held $%.2f; "
			+ "$%.2f is protected operating reserve, leaving $%.2f spendable.\n\n"
			+ "Procurement offers up to $%.2f of purchase-only matching. The farmer keeps the presentation credit; "
			+ "you choose whether the hen's output improves her desk or stays in the fund."
		) % [
			String(status.get("trigger_worker_name", "Mabel")),
			float(created_value) / 100.0,
			float(fund_at_collection) / 100.0,
			float(protected_reserve) / 100.0,
			float(spendable_at_collection) / 100.0,
			float(match_available) / 100.0,
		],
		"selection_prompt": "Choose a requisition or Bank. Every invoice, match, net debit, and projected balance is shown before authorization.",
		"confirm_label": "AUTHORIZE REINVESTMENT",
		"allow_stay_paused": false,
		"options": options,
	}


func _present_first_clutch_reinvestment(status: Dictionary = {}) -> bool:
	if (
		bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("reinvestment_grandfathered", false))
	):
		return false
	if (
		_campaign_review_stage not in [&"active", &"farmer"]
		or (_campaign_ui != null and _campaign_ui.is_modal_open())
	):
		return false
	var active_status := status if not status.is_empty() else _simulation.first_clutch_reinvestment_status()
	if StringName(active_status.get("status", &"unavailable")) != &"offered":
		return false
	if _decision_host != null and _decision_host.visible:
		return StringName(_active_decision.get("kind", &"")) == FIRST_CLUTCH_REINVESTMENT_KIND
	_on_decision_requested(_first_clutch_reinvestment_decision(active_status))
	return true


func _reconcile_first_clutch_reinvestment_after_restore() -> bool:
	if (
		not bool(_first_clutch.get("completed", false))
		or bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("reinvestment_grandfathered", false))
	):
		return false
	var status := _simulation.first_clutch_reinvestment_status()
	if bool(status.get("offered", false)) or bool(status.get("resolved", false)):
		return false
	var receipt := _simulation.begin_first_clutch_reinvestment(
		int(_first_clutch.get("target_worker_id", -1)),
		int(_first_clutch.get("delivered_claim_id", -1)),
		StringName(String(_first_clutch.get("delivered_quality", ""))),
		int(_first_clutch.get("delivered_value_cents", 0)),
	)
	if not bool(receipt.get("accepted", false)):
		push_error("Restored First Clutch could not stage its reinvestment: %s" % String(receipt.get("reason", "unknown ledger mismatch")))
		return false
	_save_campaign_checkpoint("first_clutch_reinvestment_offered")
	return true


func _first_clutch_prepare_for_shift_boundary() -> void:
	if (
		bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("completed", false))
		or int(_first_clutch.get("assisted_claim_id", -1)) < 0
		or bool(_first_clutch.get("delivery_laid", false))
	):
		return
	# DepartmentSimulation returns unfinished claims to the queue and clears their
	# Priority Peck bookkeeping at rollover. Re-open the exact induction step too;
	# the next unrelated egg must never inherit the old stamp or its credit.
	_first_clutch["assisted_worker_id"] = -1
	_first_clutch["assisted_claim_id"] = -1
	_first_clutch["potential_priority_credit_cents"] = 0
	_first_clutch["prior_presentations_pending"] = 0


func _retire_first_clutch_after_hold(completion_generation: int) -> void:
	await get_tree().create_timer(FIRST_CLUTCH_COMPLETION_HOLD_SECONDS).timeout
	if completion_generation != _first_clutch_completion_generation:
		return
	_first_clutch_completion_hold_until_msec = 0
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)


func _on_first_clutch_skip_rect_settled(_rect: Rect2) -> void:
	if (
		not OS.has_feature("web")
		or bool(_first_clutch.get("dismissed", true))
		or bool(_first_clutch.get("completed", false))
	):
		return
	# This one-shot layout fact can arrive while Office itself is paused and thus
	# cannot flush the normal throttled queue. Publish it immediately so the Web
	# accessibility model names the same live target visible on the canvas.
	_web_diagnostic_next_allowed_msec = 0
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


func _first_clutch_stage() -> StringName:
	if bool(_first_clutch.get("completed", false)):
		if not _first_clutch_reinvestment_resolved():
			return &"reinvestment"
		return &"complete"
	if not bool(_first_clutch.get("inspected", false)):
		return &"inspect"
	if not bool(_first_clutch.get("specialty_routed", false)):
		return &"specialty_route"
	if not bool(_first_clutch.get("checkin_filed", false)):
		return &"check_in"
	if int(_first_clutch.get("assisted_claim_id", -1)) < 0:
		return &"priority_peck"
	return &"delivery"


func _first_clutch_progress() -> int:
	if not bool(_first_clutch.get("inspected", false)):
		return 0
	if not bool(_first_clutch.get("specialty_routed", false)):
		return 1
	if not bool(_first_clutch.get("checkin_filed", false)):
		return 2
	if int(_first_clutch.get("assisted_claim_id", -1)) < 0:
		return 3
	if not bool(_first_clutch.get("delivery_seen", false)):
		return 4
	return 5


func _first_clutch_coach_snapshot(snapshot: Dictionary) -> Dictionary:
	var stage := _first_clutch_stage()
	var pre_policy := _first_hen_prelude_pending()
	var orders_handoff_pending := _first_clutch_orders_handoff_pending()
	var completion_holding := (
		bool(_first_clutch.get("completed", false))
		and (
			not _first_clutch_reinvestment_resolved()
			or Time.get_ticks_msec() < _first_clutch_completion_hold_until_msec
		)
	)
	var management_blocked := (
		(_campaign_ui != null and _campaign_ui.is_modal_open())
		or (_decision_host != null and _decision_host.visible)
		or (_day_review_scrim != null and _day_review_scrim.visible)
		or _feed_party_active
	)
	var management_available := (
		_campaign_review_stage == &"active"
		and (
			int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
			== DepartmentSimulation.ShiftPhase.RUNNING
			or pre_policy
		)
		and not management_blocked
	)
	var visible := (
		not bool(_first_clutch.get("dismissed", true))
		and (not bool(_first_clutch.get("completed", false)) or completion_holding)
		and management_available
	)
	var target_worker_id := int(_first_clutch.get("target_worker_id", -1))
	var worker := _first_clutch_worker_snapshot(snapshot, target_worker_id)
	var target_name := String(worker.get("name", "YOUR HEN")).to_upper()
	var specialty_name := String(worker.get("specialty_name", String(worker.get("specialty", "SPECIALTY")).replace("_", " "))).to_upper()
	var specialty_short := String(worker.get("specialty", "SPECIALTY")).replace("_", " ").to_upper()
	var title := "INSPECT ONE HEN"
	var body := (
		"The floor is paused for orientation. Click a hen or press Tab, read her dossier, then choose 1x when ready."
		if _clock.speed_index == 0 else
		"Click a hen on the floor or press Tab. Her real file becomes your induction case."
	)
	var guidance := (
		"Inspect a hen, then choose 1x when you are ready."
		if _clock.speed_index == 0 else
		"Inspect a hen on the floor or press Tab."
	)
	var tone: StringName = &"active"
	if pre_policy:
		title = "OPEN %s'S FIRST FILE" % target_name
		body = (
			"\"Appeals are mine. The farmer remembers the basket, not the beak.\"  "
			+ "APPEALS  /  CREDIT CONSCIOUS"
		)
		guidance = "Open %s's file before choosing the flock policy." % target_name
		tone = &"ready"
	match stage:
		&"specialty_route":
			title = "ROUTE %s TO %s" % [target_name, specialty_name]
			var assignment := StringName(worker.get("assigned_lane", &"auto"))
			var current_name := String(worker.get("assignment_name", "AUTO DISPATCH")).to_upper()
			if assignment != &"auto" and assignment != StringName(worker.get("specialty", &"")):
				body = "%s is currently stamped %s. Match her specialty tray in the dossier; wrong routes remain allowed." % [target_name, current_name]
				tone = &"warning"
			else:
				body = "Press Enter for the highlighted specialty tray, or choose a dossier stamp below. Specialty matching improves speed and shell safety; AUTO stays available later."
			guidance = "Press Enter to route %s to %s, or choose another tray below." % [target_name, specialty_short]
		&"check_in":
			title = "FILE %s'S CHECK-IN" % target_name
			var profile_name := String(worker.get("career_profile_name", "CAREER PROFILE")).to_upper()
			body = "Press Enter for the highlighted PROFILE FIT, or choose one real personnel stamp. The filing is permanent."
			guidance = "Press Enter to file %s's PROFILE FIT check-in, or choose another stamp below." % target_name
		&"priority_peck":
			title = "LAND %s'S PRIORITY PECK" % target_name
			var peck_status := worker.get("peck_assist", {}) as Dictionary
			if bool(peck_status.get("available", false)):
				body = "GOLD WINDOW OPEN. Press %s or use the glowing dossier stamp before this live claim moves on." % _action_hint(PECK_ASSIST_ACTION)
				guidance = "%s is in the gold window—press %s or the dossier stamp now." % [target_name, _action_hint(PECK_ASSIST_ACTION)]
				tone = &"ready"
			elif _clock.speed_index == 0:
				body = "Resume the clock, then watch %s's live file meter. The stamp glows gold in the clean-rhythm window." % target_name
				guidance = "Resume the clock and watch %s's claim meter for gold." % target_name
			elif (worker.get("current_claim", {}) as Dictionary).is_empty():
				body = "Keep %s routed and seated until she pulls a live file. The gold timing window appears during peckwork." % target_name
				guidance = "Wait for %s to pull a live file." % target_name
			else:
				body = "Watch %s's live file meter. A missed window only closes this file; retry on her next one." % target_name
				guidance = "Watch %s's live claim for the gold Priority Peck window." % target_name
		&"delivery":
			if bool(_first_clutch.get("delivery_laid", false)):
				title = "FOLLOW %s'S EGG THROUGH GRADING" % target_name
				body = "The camera has handed off to shell grading. Watch the rail and basket; press Esc only if you want to return to the floor."
				guidance = "Follow %s's egg through grading and into the farmer basket." % target_name
				tone = &"ready"
			else:
				title = "FOLLOW %s'S ASSISTED FILE" % target_name
				body = "Priority Peck landed on claim #%04d. Keep the clock moving and watch %s finish the same real file." % [int(_first_clutch.get("assisted_claim_id", 0)), target_name]
				guidance = "Watch %s finish the assisted claim and lay its egg." % target_name
		&"reinvestment":
			var reinvestment := _simulation.first_clutch_reinvestment_status()
			title = "REINVEST %s'S FIRST EGG" % target_name
			body = "%s created $%.2f. Choose one visible desk requisition or Bank the Feed Fund before today's three orders open." % [
				target_name,
				float(int(reinvestment.get("created_value_cents", _first_clutch.get("delivered_value_cents", 0)))) / 100.0,
			]
			guidance = "Authorize the First Clutch reinvestment; then today's three orders will open."
			tone = &"ready"
		&"complete":
			var quality := String(_first_clutch.get("delivered_quality", "sound")).to_upper()
			var value_cents := int(_first_clutch.get("delivered_value_cents", 0))
			var priority_cents := int(_first_clutch.get("delivered_priority_credit_cents", 0))
			title = "FIRST CLUTCH FILED  /  %s" % quality
			body = "%s's egg landed at $%.2f total value%s. Press V to open today's three probation orders; the score is filed at review." % [
				target_name,
				float(value_cents) / 100.0,
				(" including +$%.2f Priority credit" % (float(priority_cents) / 100.0) if priority_cents > 0 else ""),
			]
			guidance = "%s delivered a %s egg worth $%.2f. Press V to review today's orders." % [target_name, quality, float(value_cents) / 100.0]
			tone = &"complete"
	return {
		"visible": visible,
		"stage": stage,
		"step": stage,
		"progress": _first_clutch_progress(),
		"total": 5,
		"eyebrow": (
			"FIRST CLUTCH  //  ORIENTATION"
			if pre_policy else
			"FIRST CLUTCH  %d / 5" % _first_clutch_progress()
		),
		"title": title,
		"body": body,
		"guidance": guidance,
		"tone": tone,
		"target_worker_id": target_worker_id,
		"worker_id": target_worker_id,
		"target_name": target_name,
		"specialty_name": specialty_name,
		"expected_lane": String(worker.get("specialty", "")),
		"preferred_action": String(worker.get("preferred_personnel_action", "")),
		"resume_required": stage == &"priority_peck" and _clock.speed_index == 0,
		"completion": bool(_first_clutch.get("completed", false)),
		"pre_policy": pre_policy,
		"orders_handoff_pending": orders_handoff_pending,
		"orders_handoff_cue_visible": orders_handoff_pending and management_available,
		"can_skip": stage not in [&"complete", &"reinvestment"] and not pre_policy,
	}


func _refresh_first_clutch_ui(snapshot: Dictionary = {}) -> void:
	if _routing_ui == null:
		_clear_first_clutch_global_cue()
		return
	var active_snapshot := snapshot if not snapshot.is_empty() else _simulation.snapshot()
	if _first_clutch_tracking_active() and int(_first_clutch.get("target_worker_id", -1)) >= 0:
		var target := _first_clutch_worker_snapshot(active_snapshot, int(_first_clutch["target_worker_id"]))
		if target.is_empty():
			_first_clutch = _make_first_clutch_state(false)
	var coach := _first_clutch_coach_snapshot(active_snapshot)
	_routing_ui.call("apply_first_clutch", coach)
	_update_flockwatch_toggle()
	_apply_first_clutch_global_cue(coach)


func _apply_first_clutch_global_cue(coach: Dictionary) -> void:
	var desired: Button
	var cue_tooltip := ""
	if bool(coach.get("orders_handoff_cue_visible", false)) and not _flockwatch_open:
		desired = _flockwatch_toggle
		cue_tooltip = "FIRST CLUTCH COMPLETE: open today's three live probation orders."
	elif bool(coach.get("visible", false)):
		var stage := StringName(coach.get("stage", &""))
		if stage == &"priority_peck" and bool(coach.get("resume_required", false)):
			if _speed_buttons.size() > 1:
				desired = _speed_buttons[1]
				cue_tooltip = "FIRST CLUTCH: resume at normal speed to reach the live Priority Peck window."
	if desired == _first_clutch_global_cued_control:
		return
	_clear_first_clutch_global_cue()
	if desired == null or not is_instance_valid(desired):
		return
	_first_clutch_global_cued_control = desired
	desired.set_meta("first_clutch_original_theme", desired.theme_type_variation)
	desired.set_meta("first_clutch_original_tooltip", desired.tooltip_text)
	desired.set_meta("first_clutch_original_modulate", desired.modulate)
	desired.theme_type_variation = &"SelectedChoiceButton"
	desired.tooltip_text = cue_tooltip
	desired.modulate = Color(1.12, 1.04, 0.78, 1.0)
	_first_clutch_global_cue_tween = create_tween().bind_node(desired).set_loops()
	_first_clutch_global_cue_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_first_clutch_global_cue_tween.tween_property(desired, "modulate", Color.WHITE, 0.55)
	_first_clutch_global_cue_tween.tween_property(
		desired, "modulate", Color(1.12, 1.04, 0.78, 1.0), 0.55
	)


func _clear_first_clutch_global_cue() -> void:
	if _first_clutch_global_cue_tween != null and _first_clutch_global_cue_tween.is_valid():
		_first_clutch_global_cue_tween.kill()
	_first_clutch_global_cue_tween = null
	var control := _first_clutch_global_cued_control
	_first_clutch_global_cued_control = null
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
	}
	var safe_payload := _json_safe_variant(payload) as Dictionary
	var safe_metadata := _json_safe_variant(metadata) as Dictionary
	var saved := _campaign_store.save(safe_payload, safe_metadata)
	if not saved:
		push_warning("Campaign checkpoint failed (%s): %s" % [reason, _campaign_store.last_error])
	return saved


func _checkpoint_diagnostic_state() -> Dictionary:
	var checkpoint: Dictionary = _checkpoint_coordinator.diagnostic_snapshot()
	checkpoint["has_candidate"] = _has_campaign_checkpoint_candidate
	checkpoint["has_checkpoint"] = _has_verified_campaign_checkpoint
	checkpoint["last_error"] = _checkpoint_last_error
	checkpoint["last_saved_reason"] = _checkpoint_last_saved_reason
	checkpoint["last_saved_unix_msec"] = _checkpoint_last_saved_unix_msec
	checkpoint["userfs_persistent_hint"] = (
		OS.is_userfs_persistent() if OS.has_feature("web") else true
	)
	if not _checkpoint_last_error.is_empty():
		checkpoint["status"] = "error"
	elif bool(checkpoint.get("saving", false)):
		checkpoint["status"] = "saving"
	elif bool(checkpoint.get("dirty", false)):
		# Preserve the coordinator's precise pending/due/retry state.
		pass
	elif _has_verified_campaign_checkpoint:
		checkpoint["status"] = "saved"
	else:
		checkpoint["status"] = "not_started"
	return checkpoint


func _bounded_checkpoint_error(message: String) -> String:
	return message.strip_edges().replace("\n", " ").replace("\r", " ").substr(0, CHECKPOINT_ERROR_LIMIT)


func _publish_checkpoint_diagnostic() -> void:
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _load_campaign_checkpoint() -> void:
	var candidates: Array[Dictionary] = _campaign_store.load_recovery_candidates()
	if candidates.is_empty():
		_has_campaign_checkpoint_candidate = false
		_has_verified_campaign_checkpoint = false
		_checkpoint_last_error = _bounded_checkpoint_error(
			"No readable campaign checkpoint is available. %s" % _campaign_store.last_error
		)
		_show_campaign_title(false)
		_set_campaign_modal_open(true)
		_ticker_label.text = "CONTINUE UNAVAILABLE. %s" % _campaign_store.last_error
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
		_ticker_label.text = (
			"SAVE HELD FOR REVIEW. No complete campaign, office, and Senior ledger "
			+ "passed validation%s."
		) % (
			" (%s)" % "; ".join(semantic_errors) if not semantic_errors.is_empty() else ""
		)
		_publish_checkpoint_diagnostic()
		return
	var envelope := activated.get("envelope", {}) as Dictionary
	_checkpoint_coordinator.discard_pending()
	_has_campaign_checkpoint_candidate = true
	_has_verified_campaign_checkpoint = true
	_checkpoint_last_error = ""
	_campaign_session_checkpoint_enabled = true
	for unlock_value in _campaign_state.unlocked_feature_ids:
		_simulation.apply_campaign_unlock(StringName(unlock_value))
	_last_reviewed_day = _simulation.day
	_reset_campaign_session_visuals()
	var recovered_attention := _reconcile_orphaned_peck_assist_deliveries()
	_reconcile_first_clutch_reinvestment_after_restore()
	_restore_campaign_view()
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
		"first_clutch": _normalize_first_clutch_state(
			first_clutch_data,
			not session.has("first_clutch"),
		),
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
	_present_first_clutch_reinvestment()


func _reset_campaign_session_visuals() -> void:
	_clock.set_speed(0)
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
	_authoritative_revenue_cents = _simulation.revenue_cents
	_displayed_revenue_cents = _simulation.revenue_cents
	_fund_visual_target_cents = _simulation.revenue_cents
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
		&"welfare": return "WELFARE"
		&"compliance": return "OBEDIENCE"
		&"farmer_favor": return "FAVOR"
		&"overdue_files": return "OVERDUE"
		&"rework": return "REWORK"
		_: return String(metric).replace("_", " ").to_upper()


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
		return
	var forecast: Dictionary = _campaign_state.probation_safeguard_forecast()
	var criteria := forecast.get("criteria", []) as Array
	_campaign_safeguards_label.visible = not criteria.is_empty()
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
	_campaign_safeguards_label.add_theme_color_override(
		"font_color",
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
			("THIS QUARTER'S SENIOR ORDERS" if senior_mode else "TODAY'S PROBATION ORDERS")
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
		_campaign_objectives_label.tooltip_text = "%s\n\nAcknowledge the annual review to continue the uncapped Senior career. This closed-quarter gate also permits one optional Career Sponsorship." % String(
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
	var lines: Array[String] = []
	var tooltip_lines: Array[String] = []
	var on_track := 0
	var eggs_today := int(live_metrics.get("eggs", 0))
	for objective in objectives:
		var metric := StringName(objective.get("metric", &""))
		var actual := int(objective.get("actual", 0))
		var projected_met := bool(objective.get("projected_met", false))
		if projected_met:
			on_track += 1
		var status := "TRACK" if projected_met else "NEEDS"
		lines.append("%s  ·  %s  ·  %s  ·  +%d" % [
			status,
			_campaign_objective_short_label(metric),
			_campaign_objective_measure_text(
				metric,
				StringName(objective.get("comparison", &"minimum")),
				actual,
				int(objective.get("target", 0)),
				eggs_today,
			),
			int(objective.get("score_award", 0)),
		])
		tooltip_lines.append("%s  ·  %s\n%s" % [
			"ON TRACK" if projected_met else "NEEDS ACTION",
			String(objective.get("title", "Probation order")).to_upper(),
			String(objective.get("description", "Filed against the closing ledger.")),
		])
	_campaign_objectives_label.set_meta("orders_on_track", on_track)
	_campaign_objectives_label.set_meta("orders_total", objectives.size())
	_sync_live_order_badge(on_track, objectives.size(), senior_mode)
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


func _sync_live_order_badge(on_track: int, total: int, senior_mode: bool) -> void:
	if _campaign_ui == null or not _campaign_ui.has_method("set_live_order_progress"):
		return
	var context := StringName("probation:%d" % (_campaign_state.completed_shifts + 1))
	if senior_mode and _senior_roost_state != null:
		context = StringName("senior:%d:%d" % [
			_senior_roost_state.current_year_number(),
			_senior_roost_state.current_quarter_in_year(),
		])
	var delta := int(_campaign_ui.call("set_live_order_progress", on_track, total, context))
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
		_campaign_doctrine_label.set_meta("doctrine_id", "")
		_campaign_doctrine_label.set_meta("milestone_id", "")
		return
	var strengths := _doctrine_terms(doctrine.get("strengths", []))
	var watchouts := _doctrine_terms(doctrine.get("watchouts", []))
	var primary_strength := _doctrine_primary_term(doctrine.get("strengths", []))
	var primary_watchout := _doctrine_primary_term(doctrine.get("watchouts", []))
	_campaign_doctrine_label.text = "DOCTRINE  //  %s%s%s" % [
		String(doctrine.get("label", "PROBATION SPECIALTY")),
		"  //  EDGE %s" % primary_strength if not primary_strength.is_empty() else "",
		"  //  WATCH %s" % primary_watchout if not primary_watchout.is_empty() else "",
	]
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


func _probation_doctrine_snapshot() -> Dictionary:
	if _campaign_senior_roost or _campaign_state == null:
		return {}
	return _campaign_state.active_doctrine()


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
	_flock_labor_label.visible = labor_relevant
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
		accent = Color("df9278")
	if lines.is_empty():
		if not last_petition.is_empty():
			lines.append("LAST FLOCK PETITION  ·  %s" % String(last_petition.get("sponsor_worker_name", "NAMED HEN")).to_upper())
			lines.append(String(last_petition.get("outcome", "Management's response remains in the ledger.")))
		else:
			lines.append("FLOCK VOICE  ·  No binding compact is currently filed.")
		lines.append("Unity risk %d / %d before a denied petition can trigger work-to-rule." % [
			roundi(float(snapshot.get("solidarity", 0.0))),
			roundi(float(work_to_rule.get("threshold", 45.0))),
		])
	_flock_labor_label.text = "\n".join(lines)
	_flock_labor_label.add_theme_color_override("font_color", accent)


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
	_records_archive_label.add_theme_color_override(
		"font_color",
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
	_commendations_snapshot = evaluated.duplicate(true)
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
		if panel != null:
			panel.add_theme_stylebox_override(
				"panel",
				_commendation_earned_style if earned else _commendation_locked_style,
			)
		if mark != null:
			mark.text = "FILED" if earned else "OPEN"
			mark.add_theme_color_override("font_color", Color("f0ca72") if earned else Color("82909a"))
		if title != null:
			title.text = String(row.get("title", "COMMENDATION"))
			title.add_theme_color_override("font_color", Color("f1d58c") if earned else Color("c9d1d5"))
		if progress != null:
			progress.text = String(row.get("progress_label", "OPEN"))
			progress.add_theme_color_override("font_color", Color("d9bf78") if earned else Color("9aa8af"))
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


func _commendations_diagnostic_state() -> Dictionary:
	return CareerCommendationsScript.compact_snapshot(_commendations_snapshot)


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
	var resume_summary := _campaign_resume_summary() if continue_available else {}
	var selected_challenge_id := CampaignStateScript.CHALLENGE_STANDARD_FILING
	if _campaign_ui != null and _campaign_ui.has_method("selected_challenge_contract_id"):
		var ui_selection := StringName(_campaign_ui.call("selected_challenge_contract_id"))
		if not CampaignStateScript.challenge_contract(ui_selection).is_empty():
			selected_challenge_id = ui_selection
	_campaign_ui.apply_snapshot({
		"view": &"title",
		"day": 1,
		"total_days": CampaignStateScript.CAMPAIGN_LENGTH,
		"continue_available": continue_available,
		"resume_summary": resume_summary,
		"challenge_contract_catalog": CampaignStateScript.challenge_contract_catalog(),
		"selected_new_challenge_contract_id": String(selected_challenge_id),
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
		"recovered_from_backup": _resume_boolean(envelope.get("recovered_from_backup"), false),
		"recovery_source": String(envelope.get("recovery_source", "primary")),
	}


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


func _pending_decision_diagnostic_state() -> Dictionary:
	if _decision_host == null or not _decision_host.visible or _active_decision.is_empty():
		return {"visible": false}
	var spendable_cents := _simulation.spendable_fund_cents() if _simulation != null else 0
	var options: Array[Dictionary] = []
	var option_index := 0
	for option_value: Variant in _active_decision.get("options", []):
		if option_index >= 3 or not option_value is Dictionary:
			break
		var option := option_value as Dictionary
		var cost_cents := maxi(0, int(option.get("cost_cents", 0)))
		var authored_available := bool(option.get("can_select", true))
		var available := authored_available and cost_cents <= spendable_cents
		var order_fit := (
			_directive_order_fit(StringName(option.get("id", &"")))
			if StringName(_active_decision.get("kind", &"")) == &"directive" else
			{}
		)
		options.append({
			"index": option_index + 1,
			"id": String(option.get("id", "")),
			"label": String(option.get("label", "RESPONSE")),
			"short_label": String(option.get("short_label", option.get("label", "RESPONSE"))),
			"tagline": String(option.get("tagline", "")),
			"preview": String(option.get("preview", "Consequence pending.")),
			"tone": String(option.get("tone", "")),
			"cost_cents": cost_cents,
			"available": available,
			"order_fit": order_fit.duplicate(true),
			"unavailable_reason": (
				"" if available else String(option.get(
					"unavailable_reason",
					"Requires $%.2f Feed Fund; only $%.2f is available." % [
						cost_cents / 100.0,
						spendable_cents / 100.0,
					],
				))
			),
		})
		option_index += 1
	return {
		"visible": true,
		"serial": int(_active_decision.get("serial", -1)),
		"kind": String(_active_decision.get("kind", "")),
		"id": String(_active_decision.get("id", "")),
		"category": String(_active_decision.get("category", "")),
		"eyebrow": String(_active_decision.get("eyebrow", "")),
		"title": String(_active_decision.get("title", "CHOOSE A RESPONSE")),
		"body": String(_active_decision.get(
			"body",
			"A measurable variance requires management attention.",
		)),
		"prompt": String(_active_decision.get(
			"prompt",
			"Choose a response card, then authorize it.",
		)),
		"selected_option_id": String(_selected_decision_option),
		"confirm_enabled": _decision_confirm_button != null and not _decision_confirm_button.disabled,
		"spendable_fund_cents": spendable_cents,
		"options": options,
	}


func _flockwatch_diagnostic_state() -> Dictionary:
	var current_page := ""
	var current_page_title := ""
	var available_pages: Array[String] = []
	var accessible_copy := ""
	var last_feedback := _ticker_last_text
	if _flockwatch_navigation != null:
		current_page = String(_flockwatch_navigation.current_page_id())
		current_page_title = _flockwatch_navigation.current_page_title()
		for page_id: StringName in _flockwatch_navigation.available_page_ids():
			available_pages.append(String(page_id))
		accessible_copy = _flockwatch_navigation.accessible_text()
		last_feedback = _flockwatch_navigation.last_feedback()
	return {
		"visible": _flockwatch_open,
		"current_page": current_page,
		"current_page_title": current_page_title,
		"available_pages": available_pages,
		"accessible_text": accessible_copy if _flockwatch_open else "",
		"last_feedback": last_feedback,
	}


func _diagnostic_subset(source: Dictionary, keys: Array) -> Dictionary:
	var result: Dictionary = {}
	for key_value: Variant in keys:
		var key := String(key_value)
		if source.has(key):
			result[key] = source[key]
	return result


## Compact engine-health counters for release soak tests and support reports.
## These are sampled only when the already-throttled Web diagnostic is rebuilt;
## they do not add a second timer or perform any allocation-heavy enumeration.
func _runtime_performance_diagnostic() -> Dictionary:
	return {
		"fps": int(round(Performance.get_monitor(Performance.TIME_FPS))),
		"process_usec": int(round(
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000000.0
		)),
		"physics_process_usec": int(round(
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000000.0
		)),
		"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"static_memory_peak_bytes": int(
			Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
		),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphan_node_count": int(
			Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
		),
		"draw_calls": int(
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		),
		"rendered_objects": int(
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		),
		"rendered_primitives": int(
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		),
	}


func _publish_web_diagnostic_state(snapshot: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	var now_msec := Time.get_ticks_msec()
	if now_msec < _web_diagnostic_next_allowed_msec:
		# Web accessibility and automation only need the newest settled frame. At
		# 10x, several authoritative ticks may arrive before the browser can paint;
		# retaining the latest read model avoids serializing ~214 KB for each one.
		_pending_web_diagnostic_snapshot = snapshot
		_web_diagnostic_dirty = true
		return
	var first_clutch := _first_clutch_coach_snapshot(snapshot)
	var reinvestment := _simulation.first_clutch_reinvestment_status()
	var reinvestment_options: Array[Dictionary] = []
	for option_value in reinvestment.get("offered_options", []):
		var option := option_value as Dictionary
		reinvestment_options.append({
			"id": String(option.get("id", "")),
			"list_cost_cents": int(option.get("list_cost_cents", 0)),
			"procurement_match_cents": int(option.get("procurement_match_cents", 0)),
			"net_cost_cents": int(option.get("net_cost_cents", 0)),
			"projected_spendable_fund_cents": int(option.get("projected_spendable_fund_cents", 0)),
			"can_purchase": bool(option.get("can_purchase", false)),
		})
	var decision_rect := Rect2()
	if _decision_panel != null:
		decision_rect = _decision_panel.get_global_rect()
	var first_clutch_skip_rect := Rect2()
	if _routing_ui != null and _routing_ui.has_method("first_clutch_skip_button_rect"):
		first_clutch_skip_rect = _routing_ui.call("first_clutch_skip_button_rect") as Rect2
	var focused_worker_id := -1
	if _routing_ui != null:
		focused_worker_id = _routing_ui.focused_worker_id()
	var focused_worker: Dictionary = {}
	var recommended_peck_assist_worker_id := _simulation.recommended_peck_assist_worker_id()
	var recommended_peck_assist_worker_name := ""
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == focused_worker_id:
			focused_worker = worker
		if int(worker.get("id", -1)) == recommended_peck_assist_worker_id:
			recommended_peck_assist_worker_name = String(worker.get("name", ""))
	var contract_planning: Dictionary = {}
	if _campaign_ui != null:
		var contract_board_ui := _campaign_ui.contract_board_ui()
		if contract_board_ui != null and contract_board_ui.has_method("presentation_state"):
			var planning_value: Variant = contract_board_ui.call("presentation_state")
			if planning_value is Dictionary:
				contract_planning = (planning_value as Dictionary).duplicate(true)
				contract_planning["can_sign"] = bool(contract_planning.get("sign_enabled", false))
				var effective_terms := contract_planning.get("effective_terms", {}) as Dictionary
				contract_planning["hold_reason"] = (
					"" if bool(contract_planning["can_sign"]) else String(effective_terms.get("reason", ""))
				)
	var career_forecast := _senior_career_forecast(snapshot)
	var capital_blueprint_state := {
		"visible": false,
		"selected_facility_id": "",
		"active_filter_id": "all",
		"layout_mode": "desktop",
		"visible_facility_ids": [],
		"inspector_text": "",
	}
	if _capital_blueprint_ui != null:
		capital_blueprint_state = {
			"visible": bool(_capital_blueprint_ui.call("is_open")),
			"selected_facility_id": String(_capital_blueprint_ui.call("selected_facility_id")),
			"active_filter_id": String(_capital_blueprint_ui.call("active_filter_id")),
			"layout_mode": String(_capital_blueprint_ui.call("layout_mode_name")),
			"visible_facility_ids": _capital_blueprint_ui.call("visible_facility_ids"),
			"inspector_text": String(_capital_blueprint_ui.call("inspector_accessible_text")),
		}
	var campus_planner_state := {
		"visible": false,
		"layout_mode": "desktop",
		"selected_socket_id": "meadow_west",
		"accessible_text": "",
	}
	if _campus_expansion_ui != null:
		var campus_planner_visible := bool(_campus_expansion_ui.call("is_open"))
		campus_planner_state["visible"] = campus_planner_visible
		campus_planner_state["layout_mode"] = String(
			_campus_expansion_ui.call("layout_mode_name")
		)
		campus_planner_state["selected_socket_id"] = String(
			_campus_expansion_ui.call("selected_socket_id")
		)
		if campus_planner_visible:
			campus_planner_state["accessible_text"] = String(
				_campus_expansion_ui.call("accessible_text")
			)
	var campus_portfolio_planner_state := {
		"visible": false,
		"layout_mode": "desktop",
		"selected_parcel_id": "",
		"selected_pad_id": "",
		"selected_module_id": "",
		"accessible_text": "",
	}
	if _campus_portfolio_ui != null:
		var portfolio_planner_visible := bool(_campus_portfolio_ui.call("is_open"))
		campus_portfolio_planner_state["visible"] = portfolio_planner_visible
		campus_portfolio_planner_state["layout_mode"] = String(
			_campus_portfolio_ui.call("layout_mode_name")
		)
		campus_portfolio_planner_state["selected_parcel_id"] = String(
			_campus_portfolio_ui.call("selected_parcel_id")
		)
		campus_portfolio_planner_state["selected_pad_id"] = String(
			_campus_portfolio_ui.call("selected_pad_id")
		)
		campus_portfolio_planner_state["selected_module_id"] = String(
			_campus_portfolio_ui.call("selected_module_id")
		)
		if portfolio_planner_visible:
			campus_portfolio_planner_state["accessible_text"] = String(
				_campus_portfolio_ui.call("accessible_text")
			)
	var commissioning_state := {"visible": false, "receipt": {}, "accessible_text": ""}
	if _commissioning_reveal_ui != null:
		commissioning_state = {
			"visible": bool(_commissioning_reveal_ui.call("is_reveal_visible")),
			"receipt": _commissioning_reveal_ui.call("receipt_snapshot"),
			"accessible_text": String(_commissioning_reveal_ui.call("accessible_text")),
		}
	var campus_portfolio_reveal_state := {
		"visible": false,
		"receipt": {},
		"context": {},
		"accessible_text": "",
		"reduced_motion": false,
	}
	if _campus_portfolio_reveal_ui != null:
		var reveal_state_value: Variant = _campus_portfolio_reveal_ui.call("presentation_state")
		if reveal_state_value is Dictionary:
			campus_portfolio_reveal_state = (reveal_state_value as Dictionary).duplicate(true)
	var settings_state := {
		"visible": _settings_ui != null and _settings_ui.is_open(),
		"accessible_text": (
			_settings_ui.accessible_text()
			if _settings_ui != null and _settings_ui.is_open() else ""
		),
		"motion_mode": String(_player_preferences.get("motion_mode", "system")),
		"reduced_motion_active": _prefers_reduced_motion(),
		"ui_scale": float(_player_preferences.get("ui_scale", 1.0)),
		"high_contrast": bool(_player_preferences.get("high_contrast", false)),
		"color_vision_mode": String(_player_preferences.get("color_vision_mode", "standard")),
		"browser_mirror_status": _web_preferences_mirror_status,
		"visual_quality": String(_player_preferences.get("visual_quality", "balanced")),
		"timing_assist": String(_player_preferences.get("timing_assist", "standard")),
		"pause_when_unfocused": bool(_player_preferences.get("pause_when_unfocused", true)),
		"focus_pause_active": _focus_pause_active,
		"focus_pause_restore_speed": _focus_pause_previous_speed,
		"audio": (_player_preferences.get("audio", {}) as Dictionary).duplicate(true),
		"bindings": _current_binding_labels(),
	}
	var challenge_contract: Dictionary = _campaign_state.challenge_contract_snapshot()
	var selected_new_challenge_contract: Dictionary = {}
	var resume_challenge_contract: Dictionary = {}
	var resume_available := false
	var resume_senior_roost := false
	var campaign_intake_phase := ""
	var title_open := (
		_campaign_ui != null
		and _campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
		and _campaign_ui.has_method("selected_challenge_contract_id")
	)
	if title_open:
		campaign_intake_phase = String(_campaign_ui.title_intake_phase())
		var title_contract := CampaignStateScript.challenge_contract(
			StringName(_campaign_ui.call("selected_challenge_contract_id"))
		)
		if not title_contract.is_empty():
			challenge_contract = title_contract
			selected_new_challenge_contract = title_contract.duplicate(true)
		var title_snapshot := _campaign_ui.campaign_snapshot()
		resume_available = _resume_boolean(
			title_snapshot.get("continue_available", title_snapshot.get("has_continue")),
			false,
		)
		var resume_summary := _resume_dictionary(title_snapshot.get("resume_summary"))
		resume_senior_roost = _resume_boolean(resume_summary.get("senior_roost"), false)
		if resume_available and not resume_senior_roost:
			var resume_contract_value := _resume_dictionary(
				resume_summary.get("challenge_contract")
			)
			var resume_contract_id_value: Variant = resume_contract_value.get("id")
			if resume_contract_id_value is String or resume_contract_id_value is StringName:
				resume_challenge_contract = CampaignStateScript.challenge_contract(
					StringName(String(resume_contract_id_value))
				)
	var active_filing_id := (
		_flockwatch_navigation.current_page_id()
		if _flockwatch_open and _flockwatch_navigation != null else
		&""
	)
	var capital_filing_open := active_filing_id == FlockwatchNavigation.PAGE_CAPITAL
	var flock_filing_open := active_filing_id == FlockwatchNavigation.PAGE_FLOCK
	var operations_filing_open := active_filing_id == FlockwatchNavigation.PAGE_OPERATIONS

	var capital_source := snapshot.get("capital_plan", {}) as Dictionary
	var capital_diagnostic := {
		"upgrade_levels": snapshot.get("upgrade_levels", {}),
		"owned_facilities": snapshot.get("owned_facilities", {}),
		"facility_effects": snapshot.get("facility_effects", {}),
		"packing_contract": snapshot.get("packing_contract", {}),
		"capital_plan": capital_source,
		"last_facility_purchase_receipt": snapshot.get("last_facility_purchase_receipt", {}),
		"facility_catalog": (
			snapshot.get("facility_catalog", [])
			if capital_filing_open or bool(capital_blueprint_state.get("visible", false)) else
			[]
		),
	}
	var portfolio_source := snapshot.get("campus_portfolio", {}) as Dictionary
	var portfolio_detailed := (
		capital_filing_open
		or bool(campus_portfolio_planner_state.get("visible", false))
		or bool(campus_portfolio_reveal_state.get("visible", false))
		or int(portfolio_source.get("capital_spend_total_cents", 0)) > 0
		or not (portfolio_source.get("last_receipt", {}) as Dictionary).is_empty()
	)
	var portfolio_diagnostic := (
		portfolio_source.duplicate(true)
		if portfolio_detailed else
		_diagnostic_subset(portfolio_source, [
			"version", "summary", "planning_open", "current_day",
			"capital_spend_total_cents", "daily_cost_cents", "last_receipt",
		])
	)
	var expansion_source := snapshot.get("campus_expansion", {}) as Dictionary
	var expansion_detailed := (
		capital_filing_open
		or bool(campus_planner_state.get("visible", false))
		or bool(expansion_source.get("parcel_owned", false))
		or bool(expansion_source.get("pod_owned", false))
	)
	var expansion_diagnostic := (
		expansion_source.duplicate(true)
		if expansion_detailed else
		_diagnostic_subset(expansion_source, [
			"id", "visible", "summary", "unlock_day", "access_gate_met",
			"access_gate_reason", "parcel", "parcel_quote", "parcel_owned",
			"pod_owned", "pod_operational",
			"claim_capacity_bonus", "farmgate_capacity_bonus_eggs",
			"current_daily_cost_cents", "last_receipt",
		])
	)
	var contract_source := snapshot.get("contract_board", {}) as Dictionary
	var contract_detailed := (
		_campaign_review_stage == &"contract_board"
		or bool(contract_source.get("unlocked", false))
		or not (contract_source.get("active_contract", {}) as Dictionary).is_empty()
	)
	var contract_diagnostic := (
		contract_source.duplicate(true)
		if contract_detailed else
		_diagnostic_subset(contract_source, [
			"unlocked", "unlock_day", "unlock_requirement", "planning_open",
			"active", "active_contract", "last_result", "decline_receipt",
			"market_standing", "market_standing_rank", "season_id", "season_label",
		])
	)
	var care_source := snapshot.get("flock_care", {}) as Dictionary
	var care_detailed := (
		flock_filing_open
		or int(care_source.get("wellness_level", 0)) > 0
		or int(care_source.get("training_roost_level", 0)) > 0
	)
	var care_diagnostic := (
		care_source.duplicate(true)
		if care_detailed else
		_diagnostic_subset(care_source, [
			"version", "active_staff_count", "welfare", "welfare_score",
			"rested_flock_gate", "rested_flock_gate_met", "wellness_level",
			"training_roost_level", "breaks_active", "training_active_count",
			"next_care_action",
		])
	)
	var operations_source := snapshot.get("operations", {}) as Dictionary
	var operations_detailed := (
		operations_filing_open
		or int(operations_source.get("rooster_office_level", 0)) > 0
		or int(operations_source.get("it_coop_level", 0)) > 0
	)
	var operations_diagnostic := (
		operations_source.duplicate(true)
		if operations_detailed else
		_diagnostic_subset(operations_source, [
			"version", "rooster_office_level", "it_coop_level",
			"flock_relations_office_level", "daily_costs", "supervision", "automation",
			"next_operations_action",
		])
	)
	var runtime_performance := _runtime_performance_diagnostic()
	runtime_performance.merge({
		"authoritative_tick_revision": int(snapshot.get("authoritative_tick_revision", 0)),
		"last_presented_tick_revision": _last_presented_tick_revision,
		"presentation_update_count": _presentation_update_count,
		"ticks_advanced_last_frame": _clock.ticks_advanced_last_frame(),
		"pending_tick_count": _clock.pending_tick_count(),
		"diagnostic_interval_msec": WEB_DIAGNOSTIC_INTERVAL_MSEC,
	}, true)
	var diagnostic_directive := snapshot.get("active_directive", {}) as Dictionary
	var active_policy_order_fit := (
		_directive_order_fit(StringName(diagnostic_directive.get("id", &"")))
		if not diagnostic_directive.is_empty() and not _campaign_senior_roost else
		{}
	)
	var senior_diagnostic := {"status": "inactive"}
	if _senior_roost_state != null and _senior_roost_state.is_active():
		senior_diagnostic = _senior_roost_state.snapshot()
		if _senior_roost_state.requires_quarter_policy():
			senior_diagnostic["quarterly_policy_offers"] = (
				_senior_roost_state.policy_catalog(_simulation.spendable_fund_cents())
			)
		if _campaign_ui != null:
			var campaign_presentation := _campaign_ui.campaign_snapshot()
			var pending_mandate_confirmation := campaign_presentation.get(
				"pending_milestone_confirmation",
				{},
			) as Dictionary
			if not pending_mandate_confirmation.is_empty():
				senior_diagnostic["pending_mandate_confirmation"] = (
					pending_mandate_confirmation.duplicate(true)
				)
	var state := {
		"coordinate_system": "Canvas origin is top-left; +x right, +y down; authored stage 1280x720.",
		"mode": "godot_canvas",
		"controls": [
			"click hen",
			"middle-drag, touch-drag, WASD, arrows, or left stick to pan",
			"wheel, pinch, plus/minus, or right stick to zoom",
			"Home, Escape, or right click for office overview",
			"route file",
			"%s priority peck" % _action_hint(PECK_ASSIST_ACTION),
			"1-3 binder or speed",
			"N negotiate",
			"R standard terms",
			"Enter authorize",
			"D standard book",
			"C continue",
			"%s select rider or pause" % _action_hint(&"pause_simulation"),
			"%s Flockwatch" % _action_hint(&"toggle_flockwatch"),
			"%s Feed Party" % _action_hint(&"fund_feed_party"),
			"%s after-hours pecking" % _action_hint(&"toggle_overtime"),
			"%s settings and controls" % _action_hint(&"open_settings"),
		],
		"loaded": true,
		"boot": boot_timing_snapshot(),
		"camera": (
			_camera_controller.navigation_state()
			if _camera_controller != null and _camera_controller.has_method("navigation_state") else
			{}
		),
		"office_presentation": office_physical_presentation_snapshot(),
		"capacity_commissioning": capacity_commissioning_snapshot(),
		"audio": {
			"director": (
				_audio_director.call("mix_snapshot")
				if _audio_director != null and _audio_director.has_method("mix_snapshot") else
				{}
			),
			"feedback": (
				_audio_feedback.call("feedback_snapshot")
				if _audio_feedback != null and _audio_feedback.has_method("feedback_snapshot") else
				{}
			),
		},
		"settings": settings_state,
		"flockwatch": _flockwatch_diagnostic_state(),
		"commendations": _commendations_diagnostic_state(),
		"checkpoint": _checkpoint_diagnostic_state(),
		"campaign_stage": "title" if title_open else String(_campaign_review_stage),
		"campaign_intake_phase": campaign_intake_phase,
		"campaign_day": int(_campaign_state.completed_shifts) + 1,
		"campaign_score": int(_campaign_state.probation_score),
		"case_docket": (snapshot.get("case_docket", {}) as Dictionary).duplicate(true),
		"challenge_contract": challenge_contract,
		"selected_new_challenge_contract": selected_new_challenge_contract,
		"resume_challenge_contract": resume_challenge_contract,
		"resume_available": resume_available,
		"resume_senior_roost": resume_senior_roost,
		"probation_safeguards": _campaign_state.probation_safeguard_forecast(),
		"probation_doctrine": _probation_doctrine_snapshot(),
		"senior_roost": senior_diagnostic,
		"career_forecast": career_forecast.duplicate(true),
		"career_sponsorship": (
			_career_sponsorship_presentation_snapshot()
			if _campaign_senior_roost else
			{"visible": false}
		),
		"flock_care": care_diagnostic,
		"operations": operations_diagnostic,
		"flock_relations": (snapshot.get("flock_relations", {}) as Dictionary).duplicate(true),
		"feed_procurement": (snapshot.get("feed_procurement", {}) as Dictionary).duplicate(true),
		"farm_treasury": (snapshot.get("farm_treasury", {}) as Dictionary).duplicate(true),
		"farmer_relations_gallery": _farmer_relations_gallery_projection(snapshot),
		"farmgate_dispatch": (snapshot.get("farmgate_dispatch", {}) as Dictionary).duplicate(true),
		"campus_expansion": expansion_diagnostic,
			"campus_expansion_planner": campus_planner_state,
			"campus_portfolio": portfolio_diagnostic,
			"campus_portfolio_planner": campus_portfolio_planner_state,
		"capital_plan": (snapshot.get("capital_plan", {}) as Dictionary).duplicate(true),
		"capital_blueprint": capital_blueprint_state,
		"commissioning_reveal": commissioning_state,
		"campus_portfolio_reveal": campus_portfolio_reveal_state,
		"shift_phase": int(snapshot.get("shift_phase", -1)),
		"clock_speed_index": _clock.speed_index,
		"clock_multiplier": SimulationClock.SPEED_MULTIPLIERS[_clock.speed_index],
		"clock_effective_multiplier": _clock.effective_multiplier(),
		"priority_peck_focus": {
			"active": _clock.precision_focus_active(),
			"limiting": _clock.precision_focus_limiting(),
			"worker_id": _priority_peck_focus_worker_id,
			"requested_multiplier": SimulationClock.SPEED_MULTIPLIERS[_clock.speed_index],
			"effective_multiplier": _clock.effective_multiplier(),
			"result_hold_msec_remaining": maxi(0, _priority_peck_result_hold_until_msec - Time.get_ticks_msec()),
			"rearm_required": _priority_peck_focus_disarmed_worker_id >= 0,
		},
		"performance": runtime_performance,
		"pending_decision_kind": String(_active_decision.get("kind", "")),
		"pending_decision": _pending_decision_diagnostic_state(),
		"contract_board": contract_diagnostic,
		"contract_planning": contract_planning,
		"first_clutch": {
			"visible": bool(first_clutch.get("visible", false)),
			"dismissed": bool(_first_clutch.get("dismissed", true)),
			"can_skip": bool(first_clutch.get("can_skip", false)),
			"stage": String(first_clutch.get("stage", "")),
			"progress": int(first_clutch.get("progress", 0)),
			"title": String(first_clutch.get("title", "")),
			"guidance": String(first_clutch.get("guidance", "")),
			"primary_action_shortcut": (
				"Enter"
				if StringName(first_clutch.get("stage", &"")) in [&"specialty_route", &"check_in"] else
				""
			),
			"target_worker_id": int(first_clutch.get("target_worker_id", -1)),
			"first_hen_prelude": bool(first_clutch.get("pre_policy", false)),
			"target_name": String(first_clutch.get("target_name", "")),
			"orders_handoff_pending": bool(first_clutch.get("orders_handoff_pending", false)),
			"orders_handoff_acknowledged": bool(_first_clutch.get("orders_handoff_acknowledged", false)),
			"skip_button_rect": {
				"x": first_clutch_skip_rect.position.x,
				"y": first_clutch_skip_rect.position.y,
				"width": first_clutch_skip_rect.size.x,
				"height": first_clutch_skip_rect.size.y,
			},
			"reinvestment": {
				"status": String(reinvestment.get("status", &"unavailable")),
				"modal_visible": (
					_decision_host != null
					and _decision_host.visible
					and StringName(_active_decision.get("kind", &"")) == FIRST_CLUTCH_REINVESTMENT_KIND
				),
				"selected_choice": String(_selected_decision_option),
				"confirm_enabled": _decision_confirm_button != null and not _decision_confirm_button.disabled,
				"card_rect": {
					"x": decision_rect.position.x,
					"y": decision_rect.position.y,
					"width": decision_rect.size.x,
					"height": decision_rect.size.y,
				},
				"created_value_cents": int(reinvestment.get("created_value_cents", 0)),
				"fund_at_collection_cents": int(reinvestment.get("fund_at_collection_cents", 0)),
				"protected_reserve_cents": int(reinvestment.get("protected_reserve_cents", 0)),
				"spendable_at_collection_cents": int(reinvestment.get("spendable_at_collection_cents", 0)),
				"procurement_match_available_cents": int(reinvestment.get("procurement_match_available_cents", 0)),
				"choice_id": String(reinvestment.get("choice_id", &"")),
				"selected_list_cost_cents": int(reinvestment.get("selected_list_cost_cents", 0)),
				"procurement_match_used_cents": int(reinvestment.get("procurement_match_used_cents", 0)),
				"net_cost_cents": int(reinvestment.get("net_cost_cents", 0)),
				"fund_after_cents": int(reinvestment.get("fund_after_cents", 0)),
				"spendable_after_cents": int(reinvestment.get("spendable_after_cents", 0)),
				"options": reinvestment_options,
			},
		},
		"focused_worker_id": focused_worker_id,
		"economy": {
			"feed_fund_cents": int(snapshot.get("revenue_cents", 0)),
			"spendable_fund_cents": int(snapshot.get("spendable_fund_cents", 0)),
			"daily_operating_cost_cents": int(snapshot.get("daily_operating_cost_cents", 0)),
			"daily_feed_cost_cents": int(snapshot.get("daily_feed_cost_cents", 0)),
			"daily_payroll_cents": int(snapshot.get("daily_payroll_cents", 0)),
			"daily_hen_payroll_cents": int(snapshot.get("daily_hen_payroll_cents", 0)),
			"daily_supervisor_payroll_cents": int(
				snapshot.get("daily_supervisor_payroll_cents", 0)
			),
			"daily_facility_cost_cents": int(snapshot.get("daily_facility_cost_cents", 0)),
			"wage_arrears_cents": int(snapshot.get("wage_arrears_cents", 0)),
		},
		"production": {
			"claims_waiting": int(snapshot.get("claims_waiting", 0)),
			"claims_outstanding": int(snapshot.get("claims_outstanding", 0)),
			"claim_capacity": int(snapshot.get("claim_capacity", 18)),
			"intake_rejections_today": int(snapshot.get("intake_rejections_today", 0)),
			"intake_rejections_total": int(snapshot.get("intake_rejections_total", 0)),
			"intake_missed_value_today_cents": int(snapshot.get("intake_missed_value_today_cents", 0)),
			"intake_missed_value_total_cents": int(snapshot.get("intake_missed_value_total_cents", 0)),
			"focused_claim": (focused_worker.get("current_claim", {}) as Dictionary).duplicate(true),
			"focused_progress": float(focused_worker.get("progress", 0.0)),
			"focused_peck_assist": (focused_worker.get("peck_assist", {}) as Dictionary).duplicate(true),
			"recommended_peck_assist_worker_id": recommended_peck_assist_worker_id,
			"recommended_peck_assist_worker_name": recommended_peck_assist_worker_name,
			"peck_assists_remaining": int(snapshot.get("peck_assists_remaining", 0)),
			"last_peck_assist": (snapshot.get("last_peck_assist", {}) as Dictionary).duplicate(true),
			"feed_party_used_today": bool(snapshot.get("feed_party_used_today", false)),
			"feed_party_active": _feed_party_active,
			"feed_party_expected_attendees": _feed_party_expected_attendees.size(),
			"feed_party_arrivals": _feed_party_arrivals.size(),
			"feed_party_returns": _feed_party_returns.size(),
		},
		"capital": capital_diagnostic,
		"orders": {
			"on_track": int(_campaign_objectives_label.get_meta("orders_on_track", 0)),
			"total": int(_campaign_objectives_label.get_meta("orders_total", 0)),
			"active_policy_fit": active_policy_order_fit.duplicate(true),
		},
		"flock_labor": {
			"compact": (snapshot.get("flock_compact", {}) as Dictionary).duplicate(true),
			"work_to_rule": (snapshot.get("work_to_rule", {}) as Dictionary).duplicate(true),
		},
		"eggs_today": int(snapshot.get("eggs_today", 0)),
		"quota_target": int(snapshot.get("quota_target", 0)),
		"time_label": String(snapshot.get("time_label", "")),
	}
	var window := JavaScriptBridge.get_interface("window")
	if window != null:
		window.set("__pecking_order_state", JSON.stringify(_json_safe_variant(state)))
	_web_diagnostic_next_allowed_msec = now_msec + WEB_DIAGNOSTIC_INTERVAL_MSEC
	_web_diagnostic_dirty = false
	_pending_web_diagnostic_snapshot = {}


func _flush_pending_web_diagnostic() -> void:
	if (
		not _web_diagnostic_dirty
		or Time.get_ticks_msec() < _web_diagnostic_next_allowed_msec
	):
		return
	var pending := _pending_web_diagnostic_snapshot
	_web_diagnostic_dirty = false
	_pending_web_diagnostic_snapshot = {}
	if not pending.is_empty():
		_publish_web_diagnostic_state(pending)


func _update_lighting(snapshot: Dictionary) -> void:
	if _environment == null or _office_sun == null:
		return
	var minute := float(snapshot["minute_of_day"])
	var shift_progress := clampf(inverse_lerp(480.0, 1020.0, minute), 0.0, 1.0)
	var late_day := smoothstep(0.68, 1.0, shift_progress)
	var morning_warmth := 1.0 - smoothstep(0.0, 0.28, shift_progress)
	var overtime_active := bool(snapshot["overtime_enabled"])

	var neutral_light := Color("f4eedc")
	var morning_light := Color("f0cf9f")
	var evening_light := Color("e6a273")
	_office_sun.light_color = neutral_light.lerp(morning_light, morning_warmth).lerp(evening_light, late_day)
	_office_sun.light_energy = lerpf(0.80, 0.56, late_day)
	_environment.ambient_light_color = Color("b9c9c8").lerp(Color("788b91"), late_day)
	_environment.ambient_light_energy = lerpf(0.54, 0.42, late_day)
	_environment.background_color = Color("172029").lerp(Color("101823"), late_day)
	_bounce_light.light_energy = lerpf(0.17, 0.12, late_day)
	for fill in _office_fill_lights:
		fill.light_energy = lerpf(0.22, 0.34, late_day)
		fill.light_color = Color("e8dfc2").lerp(Color("cddbe1"), late_day)

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
	_set_flockwatch_open(opening, not opening)
	if opening:
		_acknowledge_first_clutch_orders_handoff()


func _acknowledge_first_clutch_orders_handoff() -> void:
	if not _flockwatch_open or not _first_clutch_orders_handoff_pending():
		return
	_first_clutch["orders_handoff_acknowledged"] = true
	var snapshot := _simulation.snapshot()
	_update_flockwatch_toggle()
	_refresh_first_clutch_ui(snapshot)
	_update_guidance(snapshot)
	_save_campaign_checkpoint("first_clutch_orders_opened")


func _set_flockwatch_open(is_open: bool, restore_focus: bool = false) -> void:
	var changed := _flockwatch_open != is_open
	var restore_farmer_review := (
		changed
		and not is_open
		and _flockwatch_restore_farmer_review
		and not _last_workday_report.is_empty()
	)
	if changed and is_open:
		var focus_owner := get_viewport().gui_get_focus_owner()
		if (
			focus_owner != null
			and (_flockwatch_panel == null or not _flockwatch_panel.is_ancestor_of(focus_owner))
		):
			_flockwatch_prior_focus_owner = focus_owner
		elif _flockwatch_toggle != null:
			_flockwatch_prior_focus_owner = _flockwatch_toggle
	if _camera_controller != null:
		# Keep the inspected hen and zoom authoritative while reserving screen room
		# for the ledger. The controller shifts the unchanged subject into the safe
		# left-hand region and eases it back when the drawer closes.
		_camera_controller.set_safe_viewport_insets(
			0.0,
			FLOCKWATCH_DRAWER_SAFE_RIGHT if is_open else 0.0,
			0.0,
			0.0,
		)
	_flockwatch_open = is_open
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
	if _flockwatch_toggle != null:
		_flockwatch_toggle.tooltip_text = ("Close the ledger and restore the full coop view." if is_open else "Open the rooster's performance ledger.")
	_update_flockwatch_toggle()
	if _simulation != null:
		var snapshot := _simulation.snapshot()
		_refresh_visible_management_surfaces(snapshot, true)
		if _routing_ui != null and not is_open:
			_routing_ui.apply_snapshot(_snapshot_with_active_workers(snapshot))
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


func _on_flockwatch_page_changed(page_id: StringName) -> void:
	_set_capacity_marker_context_revealed(
		_flockwatch_open
		and page_id in [FlockwatchNavigation.PAGE_FLOCK, FlockwatchNavigation.PAGE_CAPITAL]
	)
	if _flockwatch_open and _simulation != null:
		var snapshot := _simulation.snapshot()
		_refresh_visible_management_surfaces(snapshot, true)
		_publish_web_diagnostic_state(snapshot)


func _on_flockwatch_show_all_filings_changed(_enabled: bool) -> void:
	# The navigator has already settled page availability before this signal is
	# emitted. Publish that presentation-only change immediately so browser
	# diagnostics and assistive tooling never lag behind the visible tab strip.
	if _flockwatch_open and _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


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


func _update_flockwatch_toggle() -> void:
	if _flockwatch_toggle == null:
		return
	var snapshot := _simulation.snapshot()
	var headcount := int(snapshot.get("active_staff_count", _worker_views.size()))
	var capacity := _office_capacity_from_snapshot(snapshot)
	if _flockwatch_open:
		# Keep the control's identity stable. The former rotating copy made one
		# button look like four unrelated systems depending on office state.
		_flockwatch_toggle.text = "FLOCKWATCH  ·  CLOSE  [V]"
		_flockwatch_toggle.tooltip_text = (
			"Close Flockwatch and restore the full coop view.\n"
			+ "Active flock: %d of %d authorized desks." % [headcount, capacity]
		)
		_apply_flockwatch_binding_hint()
		return
	if _first_clutch_orders_handoff_pending():
		_flockwatch_toggle.text = "FLOCKWATCH  ·  3 ACTIONS  [V]"
		_flockwatch_toggle.tooltip_text = (
			"First Clutch complete: open Flockwatch to review the three live probation orders."
		)
		_apply_flockwatch_binding_hint()
		return
	# Capital facilities used to become actionable silently because this compact
	# badge counted only the three desk-upgrade buttons. Give real rooms priority
	# over the historical output summary while a review-time requisition is ready.
	var ready_facilities := 0
	var ready_facility_names: Array[String] = []
	for facility_value in snapshot.get("facility_catalog", []):
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
		_apply_flockwatch_binding_hint()
		return
	if _pecking_order_ui != null:
		var leader_summary: String = String(_pecking_order_ui.call("leader_summary"))
		var has_ranked_output := int(snapshot.get("eggs_today", 0)) > 0
		if not has_ranked_output:
			for row_value in snapshot.get("last_pecking_order", []):
				if int((row_value as Dictionary).get("eggs", 0)) > 0:
					has_ranked_output = true
					break
		if has_ranked_output and not leader_summary.contains("NO ACTIVE RANKING"):
			_flockwatch_toggle.text = "FLOCKWATCH  [V]"
			_flockwatch_toggle.tooltip_text = "%s\nOpen the full credited-output ledger." % leader_summary
			_apply_flockwatch_binding_hint()
			return
	var affordable := 0
	var spendable := int(snapshot.get("spendable_fund_cents", _simulation.revenue_cents))
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
	_apply_flockwatch_binding_hint()


func _apply_flockwatch_binding_hint() -> void:
	if _flockwatch_toggle == null:
		return
	_flockwatch_toggle.text = _flockwatch_toggle.text.replace(
		"[V]",
		"[%s]" % _action_hint(&"toggle_flockwatch"),
	)


func _on_pecking_order_worker_selected(worker_id: int) -> void:
	_set_flockwatch_open(false)
	if _camera_controller != null:
		_camera_controller.focus_worker(worker_id)


func _update_guidance(snapshot: Dictionary) -> void:
	if _guidance_label == null:
		return
	if _campaign_ui != null and _campaign_ui.is_modal_open():
		_guidance_label.text = "%s FILE OPEN: complete the highlighted management action." % (
			"SENIOR ROOST" if _campaign_senior_roost else "PROBATION"
		)
		return
	if _decision_host != null and _decision_host.visible:
		var pending_kind := StringName(_active_decision.get("kind", &"incident"))
		var pending_id := StringName(_active_decision.get("id", &""))
		if pending_kind == &"directive":
			_guidance_label.text = "MORNING BRIEFING: select a policy card, review its cost, then authorize."
		elif pending_id == &"flock_restructuring":
			_guidance_label.text = "RESTRUCTURING FILE: inspect the omitted context before deciding who pays for the ranking."
		elif pending_kind in [&"credit_allocation", &"major_event"]:
			_guidance_label.text = "CLOSING FILE: attribute the flock's work before next-shift planning can continue."
		else:
			_guidance_label.text = "INCIDENT: the shift is auto-paused until management records a response."
		return
	if _day_review_scrim != null and _day_review_scrim.visible:
		_guidance_label.text = "SHIFT COMPLETE: review results and choose how to invest."
		return
	if _farmer_relations_gallery_offer_open(snapshot):
		_guidance_label.text = "CLOSING CREDIT FILED: publish one Gallery campaign or continue to skip."
		return
	var shift_phase := int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
	if shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
		_guidance_label.text = (
			"CREDIT MEMO REQUIRED: review the Pecking Order before tomorrow's policy."
			if bool(snapshot.get("credit_memo_pending", false)) else
			"NEXT: approve requisitions or continue to tomorrow's policy briefing."
		)
		return
	if shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		if _first_hen_prelude_pending():
			var first_hen := _first_clutch_worker_snapshot(
				snapshot,
				int(_first_clutch.get("target_worker_id", FIRST_HEN_WORKER_ID)),
			)
			_guidance_label.text = "FIRST CLUTCH: open %s's file before choosing the flock policy." % String(
				first_hen.get("name", "Mabel")
			).to_upper()
			return
		_guidance_label.text = "MORNING BRIEFING REQUIRED: authorize one policy before the clock can run."
		return
	if shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
		_guidance_label.text = "INCIDENT RESPONSE REQUIRED: the shift clock is safely locked."
		return
	if _feed_party_active:
		_guidance_label.text = "FEED PARTY: production paused while attendance is documented."
		return
	var first_clutch_coach := _first_clutch_coach_snapshot(snapshot)
	if bool(first_clutch_coach.get("visible", false)):
		_guidance_label.text = "FIRST CLUTCH %d/5: %s" % [
			int(first_clutch_coach.get("progress", 0)),
			String(first_clutch_coach.get("guidance", first_clutch_coach.get("title", "Follow the active hen file."))),
		]
		return
	if bool(first_clutch_coach.get("orders_handoff_pending", false)):
		_guidance_label.text = (
			"FIRST CLUTCH 5/5: review today's three probation orders in Flockwatch."
			if _flockwatch_open else
			"FIRST CLUTCH 5/5: press V to open today's three probation orders."
		)
		return
	var eggs := int(snapshot.get("eggs_today", 0))
	var quota := maxi(1, int(snapshot.get("quota_target", 1)))
	var contract_guidance := _active_market_contract_guidance(snapshot)
	if not contract_guidance.is_empty():
		_guidance_label.text = contract_guidance
		return
	if _clock.speed_index == 0:
		_guidance_label.text = "PAUSED: inspect a hen or open Flockwatch before resuming."
		return
	if _clock.precision_focus_limiting():
		var last_assist := snapshot.get("last_peck_assist", {}) as Dictionary
		if (
			Time.get_ticks_msec() < _priority_peck_result_hold_until_msec
			and int(last_assist.get("claim_id", -1)) == _priority_peck_result_hold_claim_id
		):
			_guidance_label.text = "PRIORITY PECK LANDED: %s  ·  +%d%% file  ·  chain x%d  ·  %d× resumes after the result beat" % [
				String(last_assist.get("rating", "steady")).to_upper(),
				int(roundf(float(last_assist.get("progress_gain", 0.0)))),
				int(last_assist.get("streak", 0)),
				int(SimulationClock.SPEED_MULTIPLIERS[_clock.speed_index]),
			]
			return
		var focus := _priority_peck_precision_candidate(snapshot)
		if not focus.is_empty():
			var requested_multiplier := int(SimulationClock.SPEED_MULTIPLIERS[_clock.speed_index])
			if StringName(focus.get("window_state", &"")) == &"open":
				_guidance_label.text = "PRIORITY FOCUS 1×: %s  ·  %s  ·  press %s now; %d× resumes after this file window" % [
					String(focus.get("worker_name", "HEN")).to_upper(),
					String(focus.get("timing_label", "CLEAN RHYTHM")),
					_action_hint(PECK_ASSIST_ACTION),
					requested_multiplier,
				]
			else:
				_guidance_label.text = "PRIORITY FOCUS 1×: %s at %d%%  ·  gold opens at %d%%  ·  %d× remains selected" % [
					String(focus.get("worker_name", "HEN")).to_upper(),
					int(focus.get("progress", 0)),
					int(focus.get("window_start", DepartmentSimulation.PECK_ASSIST_WINDOW_START)),
					requested_multiplier,
				]
			return
	var assist_worker_id := _simulation.recommended_peck_assist_worker_id()
	if assist_worker_id >= 0:
		var assist_worker_name := "HEN %d" % (assist_worker_id + 1)
		var assist_timing := "CLEAN RHYTHM"
		for worker_value in snapshot.get("workers", []):
			var assist_worker := worker_value as Dictionary
			if int(assist_worker.get("id", -1)) != assist_worker_id:
				continue
			assist_worker_name = String(assist_worker.get("name", assist_worker_name)).to_upper()
			assist_timing = String((assist_worker.get("peck_assist", {}) as Dictionary).get("timing_label", assist_timing))
			break
		_guidance_label.text = "PRIORITY PECK READY: %s  ·  %s  ·  press %s or use the gold dossier stamp" % [assist_worker_name, assist_timing, _action_hint(PECK_ASSIST_ACTION)]
		return
	var attention_status := _simulation.peck_assist_delivery_status()
	if (
		int(attention_status.get("charges", 0)) <= 0
		and int(attention_status.get("pending_delivery_count", 0)) > 0
	):
		var pending_attention := int(attention_status.get("pending_delivery_count", 0))
		_guidance_label.text = "PRIORITY PECK RECHARGING: %d clean assisted %s en route to farmer credit." % [
			pending_attention,
			("egg" if pending_attention == 1 else "eggs"),
		]
		return
	if bool(snapshot.get("personnel_action_available", false)):
		_guidance_label.text = "FLOCK CHECK-IN READY: select a hen, then choose credit, coaching, or pressure."
		return
	if eggs >= quota:
		_guidance_label.text = "TARGET MET: protect quality or bank extra Feed Fund."
		return
	var remaining := quota - eggs
	var minutes_left := maxi(0, DepartmentSimulation.SHIFT_END_MINUTE - int(snapshot.get("minute_of_day", 0)))
	var worker_data: Array = []
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if _is_worker_employed(worker):
			worker_data.append(worker)
	var average_stress := 0.0
	for worker_value in worker_data:
		average_stress += float((worker_value as Dictionary).get("stress", 0.0))
	average_stress /= maxf(1.0, float(worker_data.size()))
	if average_stress >= 65.0 and not bool(snapshot.get("feed_party_used_today", false)):
		_guidance_label.text = "FLOCK STRAINED: consider one Feed Party before cracks climb."
	else:
		_guidance_label.text = "%d eggs needed  ·  %dh %02dm left  ·  Overtime trades welfare for speed" % [remaining, minutes_left / 60, minutes_left % 60]


func _active_market_contract_guidance(snapshot: Dictionary) -> String:
	var board_value: Variant = snapshot.get("contract_board", {})
	if not board_value is Dictionary:
		return ""
	var board := board_value as Dictionary
	var active_value: Variant = board.get("active", board.get("active_contract", {}))
	if not active_value is Dictionary or (active_value as Dictionary).is_empty():
		return ""
	var active := active_value as Dictionary
	if StringName(String(active.get("status", ""))) not in [&"signed", &"active"]:
		return ""

	var short_name := String(active.get("short_name", active.get("name", "MUTUAL BINDER"))).to_upper()
	var completed := maxi(0, int(active.get("timely_sound_completed", 0)))
	var required := maxi(1, int(active.get("required_completed", 1)))
	var premium_cents := maxi(0, int(active.get("premium_cents", 0)))
	var timing := _active_market_contract_next_timing(active, int(snapshot.get("minute_of_day", 0)))
	var timing_copy := ""
	if not timing.is_empty():
		timing_copy = "  ·  %s %s" % [
			String(timing.get("label", "NEXT")),
			String(timing.get("time", "")),
		]
	return "FARM MUTUAL  ·  %s  ·  %d/%d CLEAN%s  ·  $%.2f ON FULFILLMENT" % [
		short_name,
		completed,
		required,
		timing_copy,
		float(premium_cents) / 100.0,
	]


func _active_market_contract_next_timing(active: Dictionary, current_minute: int) -> Dictionary:
	var completed_ids: Array = active.get("completed_claim_ids", []) as Array
	var earliest_due := SHIFT_END_FALLBACK_MINUTE
	var earliest_arrival := SHIFT_END_FALLBACK_MINUTE
	var due_time := ""
	var arrival_time := ""
	for schedule_value in active.get("scheduled_claims", []) as Array:
		if not schedule_value is Dictionary:
			continue
		var schedule := schedule_value as Dictionary
		if bool(schedule.get("rejected", false)):
			continue
		var claim_id := int(schedule.get("claim_id", -1))
		var released := bool(schedule.get("released", false))
		var arrival_minute := int(schedule.get("arrival_minute_of_day", SHIFT_END_FALLBACK_MINUTE))
		var deadline_minute := int(schedule.get("deadline_minute_of_day", SHIFT_END_FALLBACK_MINUTE))
		if released and claim_id not in completed_ids and deadline_minute < earliest_due:
			earliest_due = deadline_minute
			due_time = String(schedule.get("deadline_time", _office_clock_label(deadline_minute)))
		elif not released and arrival_minute >= current_minute and arrival_minute < earliest_arrival:
			earliest_arrival = arrival_minute
			arrival_time = String(schedule.get("arrival_time", _office_clock_label(arrival_minute)))
	if not due_time.is_empty():
		return {"label": "NEXT DUE", "time": due_time}
	if not arrival_time.is_empty():
		return {"label": "NEXT ARRIVAL", "time": arrival_time}
	return {}


func _office_clock_label(minute_of_day: int) -> String:
	var normalized := posmod(minute_of_day, 24 * 60)
	var hour_24 := normalized / 60
	var minute := normalized % 60
	var suffix := "AM" if hour_24 < 12 else "PM"
	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12
	return "%d:%02d %s" % [hour_12, minute, suffix]


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


func _on_snapshot_changed(snapshot: Dictionary) -> void:
	if _clock != null and _clock.is_advancing_tick_batch():
		_pending_simulation_presentation_snapshot = snapshot
		return
	_apply_snapshot_presentation(snapshot)


func _on_clock_tick_batch_completed(_tick_count: int) -> void:
	if _pending_simulation_presentation_snapshot.is_empty():
		return
	var latest := _pending_simulation_presentation_snapshot
	_pending_simulation_presentation_snapshot = {}
	_apply_snapshot_presentation(latest)


func _apply_snapshot_presentation(snapshot: Dictionary) -> void:
	_presentation_update_count += 1
	_last_presented_tick_revision = int(snapshot.get("authoritative_tick_revision", 0))
	var active_snapshot := _snapshot_with_active_workers(snapshot)
	_apply_office_capacity_visibility(_office_capacity_from_snapshot(snapshot))
	_reconcile_worker_views(snapshot)
	if _management_presence != null:
		var operations := snapshot.get("operations", {}) as Dictionary
		_management_presence.apply_manager_roster(operations.get("manager_roster", []) as Array)
	_sync_campus_worker_duties(snapshot)
	_refresh_workstation_nameplates(snapshot)
	_update_lighting(snapshot)
	if _office_atmosphere != null:
		_office_atmosphere.update_from_snapshot(active_snapshot)
	if _audio_director != null:
		_audio_director.call("update_from_snapshot", active_snapshot)
	if _office_storytelling != null:
		# Campus presentation is applied immediately below with its authored teaser
		# options; skip the default rebuild here so each snapshot performs it once.
		_office_storytelling.apply_snapshot(active_snapshot, false)
		_office_storytelling.apply_campus_presentation(
			active_snapshot,
			{
				# Day 1 already teases the next perch inside the bureau. Beginning
				# on Day 2, show at most one physical capital hint one shift before
				# its unchanged economic gate.
				"show_next_teaser": int(snapshot.get("day", 1)) >= 2,
				"teaser_window_days": 1,
			},
		)
	_update_campus_world_bounds(snapshot)
	if _workstation_feedback != null:
		_workstation_feedback.apply_snapshot(_workstation_visual_snapshot(active_snapshot))
	_refresh_visible_management_surfaces(snapshot)
	if _routing_ui != null:
		var routing_snapshot := active_snapshot.duplicate(true)
		var routing_workers: Array = routing_snapshot.get("workers", [])
		for worker_value in routing_workers:
			var worker := worker_value as Dictionary
			var worker_id := int(worker.get("id", -1))
			worker["estimated_crack_risk"] = _simulation.estimated_crack_risk(worker_id)
		_routing_ui.apply_snapshot(routing_snapshot)
	_refresh_priority_peck_precision_focus(snapshot)
	_refresh_first_clutch_ui(snapshot)
	_refresh_flockwatch_navigation(snapshot)
	var snapshot_day := int(snapshot["day"])
	if snapshot_day > _last_reviewed_day and _management_presence != null:
		_last_reviewed_day = snapshot_day
		if _office_atmosphere != null:
			_office_atmosphere.pulse_farmer_review()
		_management_presence.play_review()
		if _camera_controller != null:
			_camera_controller.focus_point(_management_presence.review_focus_point(), "FARMER INSPECTION", 0.85)
	_day_label.text = "DAY %d" % int(snapshot["day"])
	_time_label.text = String(snapshot["time_label"])
	_authoritative_revenue_cents = int(snapshot["revenue_cents"])
	var available_to_display := maxi(0, _authoritative_revenue_cents - _pending_collection_cents)
	if _displayed_revenue_cents < 0:
		_displayed_revenue_cents = available_to_display
		_fund_visual_target_cents = available_to_display
	if _fund_count_tween != null and _fund_count_tween.is_valid():
		if available_to_display != _fund_visual_target_cents:
			_tween_fund_to(available_to_display)
	else:
		_displayed_revenue_cents = available_to_display
		_fund_visual_target_cents = available_to_display
		_update_fund_label()
	var eggs_today := int(snapshot["eggs_today"])
	var quota_target := maxi(1, int(snapshot["quota_target"]))
	_quota_progress.max_value = quota_target
	_quota_progress.value = mini(eggs_today, quota_target)
	_quota_progress_label.text = "%d / %d" % [eggs_today, quota_target]
	var quality_streak := int(snapshot.get("quality_streak", 0))
	var packing_status := snapshot.get("packing_contract", {}) as Dictionary
	if bool(packing_status.get("enabled", false)):
		_quality_streak_label.text = "CLEAN ×%d  ·  CARTON %d/6" % [
			quality_streak,
			int(packing_status.get("carton_progress", 0)),
		]
		_quality_streak_label.tooltip_text = (
			"Sound and golden eggs fill the Packing Annex carton. The sixth pays $%.2f at annex level %d."
			% [
				float(packing_status.get("next_carton_bonus_cents", 0)) / 100.0,
				int(packing_status.get("level", 0)),
			]
		)
	else:
		_quality_streak_label.text = "CLEAN CLUTCH  ×%d" % quality_streak
		_quality_streak_label.tooltip_text = "Consecutive sound or golden eggs increase the clean-clutch credit."
	_quality_streak_label.add_theme_color_override(
		"font_color",
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
	var active_directive := snapshot.get("active_directive", {}) as Dictionary
	var directive_text := (
		"POLICY  ·  %s" % String(active_directive.get("short_name", "UNSET"))
		if not active_directive.is_empty() else
		"POLICY  ·  BRIEFING DUE"
	)
	var labor_tooltip := ""
	var active_compact := snapshot.get("flock_compact", {}) as Dictionary
	var work_to_rule := snapshot.get("work_to_rule", {}) as Dictionary
	if bool(work_to_rule.get("active", false)):
		directive_text = "WORK-TO-RULE ACTIVE"
		labor_tooltip = "The flock is following every written step; output is slower and shells are safer."
	elif not active_compact.is_empty():
		directive_text = "COMPACT %s" % String(active_compact.get("status", "active")).to_upper()
		labor_tooltip = "%s: %s" % [
			String(active_compact.get("compact_name", "Binding flock compact")),
			String(active_compact.get("condition", "Closing ledger decides fulfillment.")),
		]
	elif bool(work_to_rule.get("scheduled", false)):
		directive_text = "FLOCK ACTION FILED"
		labor_tooltip = "A work-to-rule shift is scheduled for Day %d." % int(work_to_rule.get("day", 0))
	_directive_badge.text = directive_text
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
	var overdue_claims := int(snapshot.get("overdue_claims", (snapshot.get("routing", {}) as Dictionary).get("overdue_total", 0)))
	_today_workload_label.text = "WORKLOAD · %d / %d LIVE · %d OVERDUE · %d TURNED AWAY" % [
		int(snapshot.get("claims_outstanding", snapshot.get("claims_waiting", 0))),
		int(snapshot.get("claim_capacity", 18)),
		overdue_claims,
		int(snapshot.get("intake_rejections_today", 0)),
	]
	_today_workload_label.tooltip_text = (
		"Live claim files against current intake capacity, including overdue files and claims turned away today."
	)
	_today_clutch_label.text = "CLUTCH · %d / %d TODAY · %d CAREER EGGS" % [
		int(snapshot["eggs_today"]),
		int(snapshot["quota_target"]),
		int(snapshot["eggs_total"]),
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
		int(snapshot["solidarity"]),
	]
	_today_flock_label.tooltip_text = (
		"Average flock morale and the current unity pressure behind labor petitions."
	)
	_today_ledger_label.text = "LEDGERS · %d%% FARMER FAVOR · %d%% COOP OBEDIENCE" % [
		int(snapshot["executive_confidence"]),
		int(snapshot["compliance"]),
	]
	_today_ledger_label.tooltip_text = (
		"Farmer favor affects management confidence; coop obedience measures policy compliance."
	)

	var overtime_active := bool(snapshot["overtime_enabled"])
	_overtime_button.text = "%s  [%s]" % [
		"END AFTER-HOURS PECKING" if overtime_active else "ENABLE AFTER-HOURS PECKING",
		_action_hint(&"toggle_overtime"),
	]
	_overtime_button.button_pressed = overtime_active
	var shift_phase := int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
	var shift_running := shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
	if _routing_ui != null:
		_routing_ui.set_peck_assist_clock_running(_clock.speed_index > 0)
	_refresh_floor_input_context()
	var campaign_modal_open := _campaign_ui != null and _campaign_ui.is_modal_open()
	_overtime_button.disabled = not shift_running or _feed_party_active or campaign_modal_open
	_continue_shift_button.visible = shift_phase == DepartmentSimulation.ShiftPhase.REVIEW
	if _continue_shift_button.visible:
		var pending_memo_id := StringName(snapshot.get("credit_memo_id", &""))
		var gallery := _farmer_relations_gallery_projection(snapshot)
		var gallery_status := StringName(String(gallery.get(
			"campaign_status",
			gallery.get("status", ""),
		)))
		if _farmer_relations_gallery_offer_open(snapshot):
			_continue_shift_button.text = "CONTINUE: SKIP PUBLIC CAMPAIGN"
		elif (
			_campaign_review_stage == &"credit"
			and gallery_status in [&"filed", &"skipped"]
		):
			_continue_shift_button.text = "CONTINUE: FILE SHIFT REPORT"
		else:
			_continue_shift_button.text = (
				"CONTINUE: OPEN RESTRUCTURING FILE"
				if pending_memo_id == &"flock_restructuring" else
				("CONTINUE: OPEN GOLDEN DOSSIER"
				if pending_memo_id == &"golden_egg_dossier" else
				("CONTINUE: FILE CLOSING CREDIT"
				if bool(snapshot.get("credit_memo_pending", false)) else
				"CONTINUE: CHOOSE MORNING POLICY"
				))
			)

	var fund_cents := int(snapshot["revenue_cents"])
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
		button.text = "%s  ·  Lv %d/%d\n%s" % [
			String(upgrade.get("short_name", "UPGRADE")), level, max_level,
			("FULLY APPROVED" if maxed else "$%.2f  ·  %s" % [cost / 100.0, String(upgrade.get("description", ""))]),
		]
		button.disabled = maxed or spendable_fund_cents < cost
		button.tooltip_text = "%s\n%s" % [
			String(upgrade.get("name", "")),
			String(upgrade.get("description", "")),
		]
	_refresh_upgrade_disclosure(snapshot)
	_update_flockwatch_toggle()
	_update_campaign_objectives_label(snapshot)
	_update_flock_labor_label(snapshot)
	_update_records_archive_summary(snapshot)
	_update_guidance(snapshot)
	_update_commendations(snapshot)
	_publish_web_diagnostic_state(snapshot)


func _refresh_visible_management_surfaces(snapshot: Dictionary, force: bool = false) -> void:
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
	if _staffing_ui != null and (force or staffing_filing_visible):
		_staffing_ui.apply_snapshot(snapshot)
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
	if _pecking_order_ui != null and (force or _pecking_order_ui.is_visible_in_tree()):
		_pecking_order_ui.call("apply_snapshot", snapshot)


func _initialize_management_surfaces(snapshot: Dictionary) -> void:
	# Build stable action nodes once behind the campaign title so filters and
	# accessibility retain node identity. Subsequent ticks use visibility gates.
	if _staffing_ui != null:
		_staffing_ui.apply_snapshot(snapshot)
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("apply_snapshot", snapshot)
	if _campus_expansion_ui != null:
		_campus_expansion_ui.call("set_snapshot", snapshot)
	if _campus_portfolio_ui != null:
		_campus_portfolio_ui.call("apply_snapshot", snapshot)
	if _pecking_order_ui != null:
		_pecking_order_ui.call("apply_snapshot", snapshot)


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
		"%d READY / %d COMPLETE" % [ready_count, complete_count]
		if ready_count + complete_count > 0 else
		"%d FILES / NONE READY" % file_count
	)
	var actionable := ready_count > 0
	if actionable and not _had_actionable_upgrade:
		_upgrade_disclosure_toggle.set_expanded(true, false)
	_had_actionable_upgrade = actionable


func _refresh_flockwatch_navigation(snapshot: Dictionary) -> void:
	if _flockwatch_navigation == null:
		return
	var presentation := snapshot.duplicate(true)
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
	var egg := MeshInstance3D.new()
	egg.name = "Egg_%s_%d" % [quality, Time.get_ticks_msec()]
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 18
	mesh.rings = 10
	egg.mesh = mesh
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

	var streak := _simulation.quality_streak
	var streak_bonus := _simulation.last_streak_bonus_cents
	var collection_animated := false
	if _office_storytelling != null:
		collection_animated = _office_storytelling.animate_egg_collection(
			egg, worker_id, quality, true, value_cents, streak_bonus
		)
	if not collection_animated:
		var tween := create_tween()
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
			var streak_tween := create_tween()
			_quality_streak_label.modulate = Color("ffe39a")
			streak_tween.tween_property(_quality_streak_label, "modulate", Color.WHITE, 0.65)
	if quality == &"golden" and _camera_controller != null:
		_camera_controller.show_event_focus(worker_view.global_position + Vector3.UP * 0.82, "GOLDEN EGG", 1.55)
	# The tutorial's first delivery remains a hard recovery point. Once the player
	# is on the ordinary floor, burst production is coalesced instead of forcing a
	# complete verified file transaction for every individual egg.
	if _first_clutch_tracking_active():
		_save_campaign_checkpoint("egg_laid")
	else:
		_queue_campaign_checkpoint("egg_laid")


func _immediate_cash_for_completed_egg(
	claim_id: int,
	quality: StringName,
	value_cents: int,
) -> int:
	if quality == &"cracked":
		return maxi(0, value_cents)
	var dispatch := _simulation.snapshot().get("farmgate_dispatch", {}) as Dictionary
	if not bool(dispatch.get("enabled", false)):
		return maxi(0, value_cents)
	for lot_value: Variant in dispatch.get("lots", []):
		if lot_value is Dictionary and int((lot_value as Dictionary).get("claim_id", -2)) == claim_id:
			return 0
	# A completed sound/golden egg that is absent from a commissioned cold store
	# used the authoritative 90% overflow pickup. Mirror that exact half-up amount
	# so the Feed Fund animation never invents the missing ten percent.
	return (maxi(0, value_cents) * 9_000 + 5_000) / 10_000


func _on_camera_focus_changed(label: String, worker_id: int) -> void:
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
		_set_flockwatch_open(false)
	if _routing_ui != null:
		_routing_ui.set_focus(worker_id if worker_id >= 0 else -1)
	_refresh_priority_peck_precision_focus(_simulation.snapshot())
	if worker_id >= 0:
		var state_label := "ON TASK"
		var progress := 0
		var morale := 0
		var fatigue := 0
		var stress := 0
		for worker_variant in _simulation.snapshot().get("workers", []):
			var worker := worker_variant as Dictionary
			if int(worker.get("id", -1)) == worker_id:
				state_label = String(worker.get("state_label", state_label)).to_upper()
				progress = int(worker.get("progress", 0))
				morale = int(worker.get("morale", 0))
				fatigue = int(worker.get("fatigue", 0))
				stress = int(worker.get("stress", 0))
				break
		_ticker_label.text = "%s  ·  %s %d%%  ·  MORALE %d  ·  FATIGUE %d  ·  STRESS %d  ·  CRACK RISK %d%%" % [
			label.to_upper(), state_label, progress, morale, fatigue, stress,
			int(_simulation.estimated_crack_risk(worker_id) * 100.0),
		]
		_publish_camera_diagnostic()
		return
	_publish_camera_diagnostic()
	if not label.is_empty():
		_ticker_label.text = label
	else:
		_ticker_label.text = "Click a hen to inspect  ·  V opens Flockwatch  ·  Shift objective stays above."


func _publish_camera_diagnostic() -> void:
	# Camera motion remains available while onboarding or Settings owns the
	# simulation clock. Publish through the existing 4 Hz coalescer so visual and
	# assistive camera state cannot stay stale until the next authoritative tick.
	if _simulation != null:
		_publish_web_diagnostic_state(_simulation.snapshot())


func _on_egg_graded(
	_worker_id: int,
	quality: StringName,
	value_cents: int,
	streak_bonus_cents: int,
	_grading_world_position: Vector3
) -> void:
	var base_value := maxi(0, value_cents - streak_bonus_cents)
	if _audio_feedback != null:
		_audio_feedback.play_sorter_clack(quality)
	var dispatch := _simulation.snapshot().get("farmgate_dispatch", {}) as Dictionary
	var destination := (
		"awaiting Farmgate dispatch"
		if bool(dispatch.get("enabled", false)) and quality in [&"sound", &"golden"] else
		"awaiting farmer collection"
	)
	_ticker_label.text = "%s GRADED  ·  $%.2f base%s  ·  %s" % [
		String(quality).to_upper(),
		base_value / 100.0,
		("  +  $%.2f clean-clutch" % (streak_bonus_cents / 100.0) if streak_bonus_cents > 0 else ""),
		destination,
	]


func _on_egg_reached_presentation(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	_streak_bonus_cents: int
) -> void:
	var delivered_claim_id := _take_collection_claim(worker_id)
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
	if bool(attention_receipt.get("accepted", false)):
		_spawn_attention_refund_chip(attention_receipt, quality)
		_ticker_label.text = "%s DELIVERED  ·  +1 PRIORITY PECK  ·  %d/%d attention ready" % [
			String(quality).to_upper(),
			int(attention_receipt.get("charges_after", 0)),
			DepartmentSimulation.PECK_ASSIST_LIMIT,
		]
		_save_campaign_checkpoint("priority_peck_attention_refunded")
	elif stocked_for_dispatch:
		_ticker_label.text = "%s STOCKED  ·  $%.2f lot value  ·  route at shift review" % [
			String(quality).to_upper(),
			float(value_cents) / 100.0,
		]
	_first_clutch_record_presentation(worker_id, delivered_claim_id, quality, value_cents)


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


func _tween_fund_to(target_cents: int) -> void:
	if _fund_count_tween != null and _fund_count_tween.is_valid():
		_fund_count_tween.kill()
	var start_cents := maxi(0, _displayed_revenue_cents)
	_fund_visual_target_cents = target_cents
	var distance := absi(target_cents - start_cents)
	if distance == 0:
		_displayed_revenue_cents = target_cents
		_update_fund_label()
		return
	var duration := clampf(0.22 + distance / 8000.0, 0.22, 0.62)
	_fund_count_tween = create_tween().bind_node(self)
	_fund_count_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_fund_count_tween.tween_method(func(value: float) -> void:
		_displayed_revenue_cents = roundi(value)
		_update_fund_label(), float(start_cents), float(target_cents), duration)
	_fund_count_tween.tween_callback(func() -> void:
		_displayed_revenue_cents = target_cents
		_update_fund_label())


func _update_fund_label() -> void:
	if _revenue_label != null:
		_revenue_label.text = "FEED FUND  $%.2f" % (maxi(0, _displayed_revenue_cents) / 100.0)


func _spawn_fund_credit_chip(value_cents: int, quality: StringName) -> void:
	if _ui_root == null or _revenue_label == null or _management_camera == null:
		_on_fund_credit_chip_arrived(value_cents, quality)
		return
	var chip := PanelContainer.new()
	chip.name = "FundCreditChip"
	chip.custom_minimum_size = Vector2(146.0, 36.0)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent := Color("f1c75f") if quality == &"golden" else Color("8fd1a1")
	if quality == &"cracked":
		accent = Color("d98a72")
	chip.add_theme_stylebox_override("panel", _panel_style(Color("16242d"), 0.96, 7, 1))
	var label := _make_label("+$%.2f FEED FUND" % (maxi(0, value_cents) / 100.0), 15, accent)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	_ui_root.add_child(chip)
	var presentation_point := (
		_office_storytelling.presentation_focus_point_global()
		if _office_storytelling != null else Vector3(9.4, 1.25, -6.85)
	)
	var start := _management_camera.unproject_position(presentation_point)
	chip.position = start - Vector2(73.0, 18.0)
	chip.pivot_offset = Vector2(73.0, 18.0)
	chip.scale = Vector2(0.78, 0.78)
	var target := (
		_revenue_label.get_global_rect().get_center()
		- _ui_root.get_global_rect().position
		- Vector2(73.0, 18.0)
	)
	var tween := create_tween().bind_node(chip).set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(chip, "scale", Vector2.ONE, 0.16)
	tween.tween_property(chip, "position", start - Vector2(73.0, 54.0), 0.16)
	tween.chain().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(chip, "position", target, 0.54)
	tween.parallel().tween_property(chip, "modulate:a", 0.15, 0.28).set_delay(0.26)
	tween.chain().tween_callback(_on_fund_credit_chip_arrived.bind(value_cents, quality))
	tween.chain().tween_callback(chip.queue_free)


func _spawn_farmgate_stock_chip(value_cents: int, quality: StringName) -> void:
	if _ui_root == null or _management_camera == null:
		return
	var chip := PanelContainer.new()
	chip.name = "FarmgateStockChip"
	chip.custom_minimum_size = Vector2(178.0, 38.0)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent := Color("f1c75f") if quality == &"golden" else Color("8fd2c1")
	chip.add_theme_stylebox_override("panel", _panel_style(Color("162b2c"), 0.97, 7, 1))
	var label := _make_label("+1 COLD-STORE LOT  ·  $%.2f" % (
		maxi(0, value_cents) / 100.0
	), 14, accent)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	_ui_root.add_child(chip)
	var presentation_point := (
		_office_storytelling.presentation_focus_point_global()
		if _office_storytelling != null else Vector3(9.4, 1.25, -6.85)
	)
	var start := _management_camera.unproject_position(presentation_point)
	chip.position = start - Vector2(89.0, 19.0)
	chip.pivot_offset = Vector2(89.0, 19.0)
	chip.scale = Vector2(0.76, 0.76)
	var target_control: Control = (
		_flockwatch_toggle if _flockwatch_toggle != null else _today_clutch_label
	)
	var target := (
		target_control.get_global_rect().get_center()
		- _ui_root.get_global_rect().position
		- Vector2(89.0, 19.0)
	)
	var tween := create_tween().bind_node(chip).set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(chip, "scale", Vector2.ONE, 0.16)
	tween.tween_property(chip, "position", start - Vector2(89.0, 56.0), 0.16)
	tween.chain().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(chip, "position", target, 0.58)
	tween.parallel().tween_property(chip, "modulate:a", 0.12, 0.30).set_delay(0.28)
	tween.chain().tween_callback(chip.queue_free)


func _spawn_attention_refund_chip(receipt: Dictionary, quality: StringName) -> void:
	if _ui_root == null or _guidance_label == null or _management_camera == null:
		if _audio_feedback != null:
			_audio_feedback.play_attention_restored()
		return
	var chip := PanelContainer.new()
	chip.name = "PriorityPeckRefundChip"
	chip.custom_minimum_size = Vector2(188.0, 38.0)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var accent := Color("f4d471") if quality == &"golden" else Color("91d4b2")
	chip.add_theme_stylebox_override("panel", _panel_style(Color("16242d"), 0.97, 7, 1))
	var charges := int(receipt.get("charges_after", 0))
	var label := _make_label("+1 PRIORITY PECK  ·  %d/%d" % [
		charges, DepartmentSimulation.PECK_ASSIST_LIMIT,
	], 14, accent)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	_ui_root.add_child(chip)
	var presentation_point := (
		_office_storytelling.presentation_focus_point_global()
		if _office_storytelling != null else Vector3(9.4, 1.25, -6.85)
	)
	var start := _management_camera.unproject_position(presentation_point)
	chip.position = start - Vector2(94.0, 19.0)
	chip.pivot_offset = Vector2(94.0, 19.0)
	chip.scale = Vector2(0.72, 0.72)
	var target := (
		_guidance_label.get_global_rect().get_center()
		- _ui_root.get_global_rect().position
		- Vector2(94.0, 19.0)
	)
	var tween := create_tween().bind_node(chip).set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(chip, "scale", Vector2.ONE, 0.18)
	tween.tween_property(chip, "position", start - Vector2(94.0, 62.0), 0.18)
	tween.chain().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(chip, "position", target, 0.62)
	tween.parallel().tween_property(chip, "modulate:a", 0.12, 0.32).set_delay(0.30)
	tween.chain().tween_callback(func() -> void:
		if _audio_feedback != null:
			_audio_feedback.play_attention_restored()
	)
	tween.chain().tween_callback(chip.queue_free)


func _on_fund_credit_chip_arrived(value_cents: int, quality: StringName) -> void:
	if _audio_feedback != null:
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
		var fleck := _add_sphere(
			_egg_layer,
			"EggFleck",
			origin + Vector3(0.0, 0.10, 0.0),
			Vector3.ONE * (0.09 if quality == &"golden" else 0.07),
			particle_color
		)
		if quality == &"golden":
			fleck.material_override = _emissive_material(particle_color, 0.65)
		var angle := TAU * float(particle_index) / float(particle_count) + worker_id * 0.31
		var distance := 0.38 + (particle_index % 2) * 0.14
		var destination := origin + Vector3(cos(angle) * distance, 0.38 + (particle_index % 3) * 0.10, sin(angle) * distance)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(fleck, "position", destination, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(fleck, "scale", Vector3.ZERO, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(fleck.queue_free)


func _on_announcement_posted(message: String) -> void:
	_ticker_label.text = message
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
		_feed_party_tween = create_tween()
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
		_feed_party_tween = create_tween()
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


func _on_speed_button_pressed(index: int) -> void:
	if _campaign_ui != null and _campaign_ui.is_modal_open():
		return
	if _first_hen_prelude_pending():
		_ticker_label.text = "CLOCK LOCKED. Open Mabel's file before choosing the flock policy."
		return
	if _decision_host != null and _decision_host.visible:
		return
	if _day_review_scrim != null and _day_review_scrim.visible:
		return
	if _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		_ticker_label.text = "CLOCK LOCKED. Complete the current policy or incident card first."
		_simulation.announce_pending_decision()
		return
	if _feed_party_active:
		_ticker_label.text = "CLOCK LOCKED. Feed Party attendance is still in progress."
		return
	_clock.set_speed(index)
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()


func _on_pause_requested() -> void:
	if _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		_on_speed_button_pressed(0)
		return
	_on_speed_button_pressed(1 if _clock.speed_index == 0 else 0)


func _on_speed_changed(speed_index: int, multiplier: float) -> void:
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
	_refresh_speed_button_copy()
	if _routing_ui != null:
		_routing_ui.set_peck_assist_clock_running(speed_index > 0)
	if _simulation != null:
		var snapshot := _simulation.snapshot()
		_refresh_first_clutch_ui(snapshot)
		_update_guidance(snapshot)
	var review_open := _day_review_scrim != null and _day_review_scrim.visible
	var decision_open := _decision_host != null and _decision_host.visible
	if _ticker_label != null and not _feed_party_active and not review_open and not decision_open and not campaign_open:
		if speed_index == 0:
			_ticker_label.text = "SHIFT PAUSED. Inspect the flock, review requisitions, or resume when ready."
		else:
			_ticker_label.text = "SHIFT RUNNING AT %dx. Click a hen to inspect; the clutch target stays above." % int(multiplier)


func _on_feed_pressed() -> void:
	if _campaign_ui != null and _campaign_ui.is_modal_open():
		return
	if _feed_party_active:
		_ticker_label.text = "FEED PARTY ALREADY IN PROGRESS. Additional morale has not been purchased."
		return
	_simulation.fund_feed_party()


func _on_overtime_pressed() -> void:
	if _campaign_ui != null and _campaign_ui.is_modal_open():
		return
	if _simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING or _feed_party_active:
		_ticker_label.text = "AFTER-HOURS REQUEST HELD. Settle the current management action first."
		return
	_simulation.toggle_overtime()
	_save_campaign_checkpoint("overtime_toggled")


func _on_upgrade_pressed(upgrade_id: StringName) -> void:
	_simulation.purchase_upgrade(upgrade_id)


func _on_upgrade_purchased(upgrade_id: StringName, level: int, _cost_cents: int) -> void:
	if _audio_feedback != null:
		_audio_feedback.play_upgrade()
	var button: Button = _upgrade_buttons.get(upgrade_id)
	if button != null:
		button.modulate = Color("f7d77b")
		var tween := create_tween()
		tween.tween_property(button, "modulate", Color.WHITE, 0.70).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _workstation_feedback != null:
		var active_snapshot := _snapshot_with_active_workers(_simulation.snapshot())
		_workstation_feedback.apply_snapshot(_workstation_visual_snapshot(active_snapshot))
	_save_campaign_checkpoint("upgrade_purchased")


func _capture_preview() -> void:
	_prepare_capture_running()
	# Allow the staggered morning walk to resolve so the capture shows seated work animation.
	await get_tree().create_timer(5.5).timeout
	_save_preview("vertical_slice.png")


func _capture_decision_preview() -> void:
	await get_tree().create_timer(0.8).timeout
	_save_preview("morning_directive.png")


func _capture_incident_preview() -> void:
	_prepare_capture_running()
	_simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[0] - DepartmentSimulation.MINUTES_PER_TICK
	_simulation.advance_tick()
	await get_tree().create_timer(0.8).timeout
	_save_preview("incident_decision.png")


func _capture_petition_preview() -> void:
	_prepare_capture_running()
	_simulation.day = 2
	var sponsor_id := 0
	for worker in _simulation.workers:
		if worker.employed and worker.career_profile == &"credit_conscious":
			sponsor_id = worker.id
			break
	_simulation.last_credit_allocation = {
		"day": 1,
		"style_id": "management_innovation",
		"worker_id": sponsor_id,
		"worker_name": _simulation.workers[sponsor_id].display_name,
	}
	_simulation._incident_slot = 1
	_simulation.minute_of_day = DepartmentSimulation.INCIDENT_MINUTES[1] - DepartmentSimulation.MINUTES_PER_TICK
	_simulation.advance_tick()
	await get_tree().create_timer(0.8).timeout
	_save_preview("flock_petition.png")


func _capture_flock_labor_preview() -> void:
	_prepare_capture_running()
	var sponsor = _simulation.workers[0]
	_simulation.active_flock_compact = {
		"compact_id": "CAPTURE-SAFE-PACE",
		"petition_day": 0,
		"effective_day": _simulation.day,
		"status": "active",
		"petition_type": "safe_pace",
		"compact_name": "SAFE PECKING COMPACT",
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"promise": "Keep overtime off and file no quota-pressure check-in.",
		"condition": "Close without overtime or quota pressure.",
	}
	_simulation.solidarity = 58.0
	_simulation.work_to_rule_day = _simulation.day
	_simulation.last_work_to_rule_record = {
		"status": "active",
		"effective_day": _simulation.day,
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"work_multiplier": 0.82,
		"crack_modifier": -0.06,
	}
	_on_snapshot_changed(_simulation.snapshot())
	_open_flockwatch_page(FlockwatchNavigation.PAGE_TODAY)
	await get_tree().create_timer(0.55).timeout
	_save_preview("flockwatch_labor.png")


func _capture_ledger_preview() -> void:
	_prepare_capture_running()
	await get_tree().create_timer(1.0).timeout
	_simulation.purchase_upgrade(&"peckwork_tools")
	_open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	await get_tree().create_timer(0.45).timeout
	_save_preview("requisitions.png")


func _capture_capacity_commissioning_preview() -> void:
	_prepare_capture_running()
	_set_flockwatch_open(false)
	await get_tree().create_timer(0.55).timeout
	var upgrade := _simulation.capacity_upgrade_status()
	_apply_office_capacity_visibility(5, true)
	_begin_capacity_commissioning_beat({
		"office_capacity": 5,
		"cost_cents": int(upgrade.get("cost_cents", 0)),
		"added_daily_operating_cents": int(upgrade.get("added_daily_operating_cents", 0)),
	})
	if _camera_controller != null:
		_camera_controller.focus_point(
			desk_position(4) + Vector3.UP * 1.0,
			"PERCH 5 COMMISSIONED",
			0.32,
			8.8,
		)
	await get_tree().create_timer(0.42).timeout
	_save_preview("capacity_commissioning.png")


func _capture_day_review_preview() -> void:
	_prepare_capture_running()
	await get_tree().create_timer(0.8).timeout
	_simulation.perform_personnel_action(0, &"share_credit")
	_simulation.eggs_today = _simulation.quota_target + 3
	_simulation.cracked_today = 2
	_simulation.golden_today = 1
	_simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	_simulation._incident_slot = DepartmentSimulation.INCIDENT_MINUTES.size()
	_simulation.advance_tick()
	await get_tree().create_timer(0.65).timeout
	_save_preview("day_review.png")


func _capture_feed_party_preview() -> void:
	_prepare_capture_running()
	_simulation.fund_feed_party()
	# Immediate funding queues late arrivals safely behind their morning walk. Wait
	# for the authoritative ready callbacks so the image shows every on-site hen feeding.
	var deadline_msec := Time.get_ticks_msec() + 45000
	while _feed_party_arrivals.size() < _feed_party_expected_attendees.size() and Time.get_ticks_msec() < deadline_msec:
		await get_tree().process_frame
	if _feed_party_arrivals.size() < _feed_party_expected_attendees.size():
		push_warning("Feed-party capture timed out with %d/%d attendees." % [_feed_party_arrivals.size(), _feed_party_expected_attendees.size()])
	if _camera_controller != null:
		_camera_controller.show_event_focus(
			FEED_PARTY_STATION_POSITION + Vector3.UP * 0.72,
			"FEED PARTY ART CHECK",
			2.0,
			true,
		)
	await get_tree().create_timer(0.8).timeout
	_save_preview("feed_party.png")


func _capture_review_preview() -> void:
	_prepare_capture_running()
	await get_tree().process_frame
	if _office_atmosphere != null:
		_office_atmosphere.pulse_farmer_review()
	_management_presence.play_review()
	_camera_controller.focus_point(_management_presence.review_focus_point(), "FARMER INSPECTION", 0.7)
	await get_tree().create_timer(1.65).timeout
	_save_preview("farmer_review.png")


func _capture_predator_preview() -> void:
	_prepare_capture_running()
	# Let the selected worker complete the morning path before the fox enters.
	await get_tree().create_timer(4.5).timeout
	_trigger_predator_debug_encounter()
	var worker_view := _worker_views.get(0) as ChickenView
	if worker_view != null and _camera_controller != null:
		_camera_controller.focus_point(worker_view.global_position + Vector3(0.0, 1.0, 0.0), "PREDATOR LOSS", 0.45)
	# Capture during the rotation/shake portion rather than the approach.
	await get_tree().create_timer(2.55).timeout
	_save_preview("predator_encounter.png")


func _capture_predator_animation() -> void:
	_prepare_capture_running()
	await get_tree().create_timer(4.5).timeout
	_trigger_predator_debug_encounter()
	# The fox now enters through the full employee lane before the bite.
	await get_tree().create_timer(4.4).timeout
	if _predator_encounter != null and _camera_controller != null:
		_camera_controller.focus_point(_predator_encounter.focus_point(), "PREDATOR LOSS", 0.25)
	var capture_directory := ProjectSettings.globalize_path("res://captures/predator_live_frames")
	DirAccess.make_dir_recursive_absolute(capture_directory)
	for frame_index in 30:
		await get_tree().create_timer(0.1).timeout
		var image := get_viewport().get_texture().get_image()
		if image != null:
			image.save_png(capture_directory.path_join("predator_%03d.png" % frame_index))
	get_tree().quit()


func _capture_routing_preview() -> void:
	_prepare_capture_running()
	await get_tree().create_timer(5.5).timeout
	_simulation.set_worker_assignment(0, &"appeals")
	_simulation.set_worker_at_workstation(0, true)
	_simulation.advance_tick()
	_camera_controller.focus_worker(0)
	await get_tree().create_timer(1.0).timeout
	_save_preview("peckwork_routing.png")


func _capture_first_clutch_preview() -> void:
	_reset_first_clutch(true)
	_prepare_capture_running()
	await get_tree().process_frame
	_camera_controller.focus_worker(0)
	var worker_view := _worker_views.get(0) as ChickenView
	var seat_deadline := Time.get_ticks_msec() + 15000
	while (
		worker_view != null
		and not worker_view.is_seated_at_workstation()
		and Time.get_ticks_msec() < seat_deadline
	):
		await get_tree().process_frame
	await get_tree().create_timer(0.55).timeout
	_save_preview("first_clutch_induction.png")


func _capture_first_clutch_reinvestment_preview() -> void:
	_prepare_capture_running()
	var reserve := _simulation.current_daily_operating_cost_cents() + _simulation.wage_arrears_cents
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, reserve + 2000)
	_simulation.eggs_today = maxi(1, _simulation.eggs_today)
	_simulation.eggs_total = maxi(1, _simulation.eggs_total)
	_simulation.workers[FIRST_HEN_WORKER_ID].eggs_laid = maxi(
		1,
		_simulation.workers[FIRST_HEN_WORKER_ID].eggs_laid,
	)
	_first_clutch = _make_first_clutch_state(false)
	_first_clutch.merge({
		"completed": true,
		"target_worker_id": FIRST_HEN_WORKER_ID,
		"inspected": true,
		"specialty_routed": true,
		"checkin_filed": true,
		"checkin_worker_id": FIRST_HEN_WORKER_ID,
		"assisted_worker_id": FIRST_HEN_WORKER_ID,
		"assisted_claim_id": 9001,
		"delivery_laid": true,
		"delivery_seen": true,
		"delivered_claim_id": 9001,
		"delivered_quality": "sound",
		"delivered_value_cents": 425,
	}, true)
	var offer := _simulation.begin_first_clutch_reinvestment(
		FIRST_HEN_WORKER_ID,
		9001,
		&"sound",
		425,
	)
	if not bool(offer.get("accepted", false)):
		push_error("First Clutch reinvestment capture could not stage its offer: %s" % String(offer.get("reason", "unknown error")))
		get_tree().quit(1)
		return
	_present_first_clutch_reinvestment(offer)
	await get_tree().create_timer(0.85).timeout
	_save_preview("first_clutch_reinvestment.png")


func _capture_first_hen_preview() -> void:
	var player_store = _campaign_store
	_campaign_store = CampaignSaveStoreScript.new("first_hen_capture.json")
	_on_campaign_new_requested()
	_campaign_store = player_store
	await get_tree().create_timer(1.1).timeout
	_save_preview("first_hen_prelude.png")


func _capture_first_hen_policy_preview() -> void:
	var player_store = _campaign_store
	_campaign_store = CampaignSaveStoreScript.new("first_hen_policy_capture.json")
	_on_campaign_new_requested()
	_open_first_hen_file(FIRST_HEN_WORKER_ID)
	_campaign_store = player_store
	await get_tree().create_timer(0.85).timeout
	_save_preview("first_hen_policy.png")


func _capture_peck_assist_preview() -> void:
	_prepare_capture_running()
	var worker_view := _worker_views.get(0) as ChickenView
	var seat_deadline := Time.get_ticks_msec() + 15000
	while (
		worker_view != null
		and not worker_view.is_seated_at_workstation()
		and Time.get_ticks_msec() < seat_deadline
	):
		await get_tree().process_frame
	if worker_view == null or not worker_view.is_seated_at_workstation():
		push_error("Priority Peck capture requires Mabel to reach her workstation.")
		get_tree().quit(1)
		return
	_simulation.set_worker_at_workstation(0, true)
	_simulation.advance_tick()
	if _simulation.workers[0].current_claim == null:
		push_error("Priority Peck capture requires an active claim.")
		get_tree().quit(1)
		return
	_simulation.workers[0].work_progress = DepartmentSimulation.PECK_ASSIST_IDEAL_PROGRESS
	_on_snapshot_changed(_simulation.snapshot())
	_routing_ui.set_peck_assist_clock_running(true)
	_camera_controller.focus_worker(0)
	_workstation_feedback.pulse_peck_assist(0, &"perfect")
	worker_view.play_peck_assist_feedback(&"perfect")
	await get_tree().create_timer(0.18).timeout
	_save_preview("peck_assist_ready.png")


func _capture_grading_preview() -> void:
	_prepare_capture_running()
	var worker_view: ChickenView = _worker_views.get(0) as ChickenView
	var seat_deadline := Time.get_ticks_msec() + 15000
	while (
		worker_view != null
		and not worker_view.is_seated_at_workstation()
		and Time.get_ticks_msec() < seat_deadline
	):
		await get_tree().process_frame
	if worker_view == null or not worker_view.is_seated_at_workstation():
		push_error("Grading capture requires Mabel to reach her workstation.")
		get_tree().quit(1)
		return
	_camera_controller.focus_point(Vector3(10.82, 2.48, -5.05), "SHELL GRADING", 0.35)
	_simulation.revenue_cents += 455
	_simulation.eggs_today += 1
	_on_egg_laid(0, &"sound", 455)
	_on_snapshot_changed(_simulation.snapshot())
	await get_tree().create_timer(1.35).timeout
	_save_preview("egg_grading.png")


func _capture_staffing_preview() -> void:
	_prepare_capture_running()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 50000)
	_simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	_simulation._incident_slot = DepartmentSimulation.INCIDENT_MINUTES.size()
	_simulation.advance_tick()
	await get_tree().process_frame
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	_open_flockwatch_page(FlockwatchNavigation.PAGE_FLOCK)
	await get_tree().create_timer(0.55).timeout
	_save_preview("roost_staffing.png")


func _capture_facility_preview() -> void:
	_prepare_capture_running()
	_simulation.apply_campaign_unlock(&"shell_quality_checks")
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.revenue_cents = maxi(
		_simulation.revenue_cents,
		_simulation.current_daily_operating_cost_cents() + 4300,
	)
	var receipt := _simulation.purchase_facility(&"candling_rework_bay")
	if not bool(receipt.get("accepted", false)) and not _simulation.has_facility(&"candling_rework_bay"):
		push_error("Facility art capture could not commission its QA bay: %s" % String(receipt.get("reason", "unknown reason")))
		get_tree().quit(1)
		return
	_on_snapshot_changed(_simulation.snapshot())
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false
	_camera_controller.focus_point(Vector3(10.10, 0.82, 2.30), "FACILITY ART CHECK", 0.35, 3.45)
	await get_tree().create_timer(0.9).timeout
	_save_preview("candling_rework_bay.png")


func _capture_facility_ui_preview() -> void:
	_prepare_capture_running()
	_simulation.apply_campaign_unlock(&"shell_quality_checks")
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.revenue_cents = _simulation.current_daily_operating_cost_cents() + 10_000
	_on_snapshot_changed(_simulation.snapshot())
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	_set_campaign_modal_open(false)
	_open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	await get_tree().process_frame
	var scroll := _flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
	var facility_card := find_child("FacilityCard_candling_rework_bay", true, false) as Control
	if scroll != null and facility_card != null:
		var component_offset := (
			facility_card.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 24.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await get_tree().create_timer(0.65).timeout
	_save_preview("facility_requisition.png")


func _capture_packing_annex_preview() -> void:
	_prepare_capture_running()
	_simulation.day = 3
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = 100_000
	for _level in 3:
		var receipt := _simulation.purchase_facility(&"farmer_brand_packing_annex")
		if not bool(receipt.get("accepted", false)):
			push_error(
				"Packing Annex art capture could not commission a tier: %s" % String(
					receipt.get("reason", "unknown reason")
				)
			)
			get_tree().quit(1)
			return
	for _egg in 5:
		_simulation.call("_apply_packing_contract_value", &"sound", 500)
	_on_snapshot_changed(_simulation.snapshot())
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false
	_camera_controller.focus_point(
		PACKING_ANNEX_FOCUS,
		"PACKING ANNEX ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("packing_annex_level3.png")


func _capture_records_annex_preview() -> void:
	_prepare_capture_running()
	_simulation.day = 3
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = 100_000
	for _level in 3:
		var receipt := _simulation.purchase_facility(&"records_annex")
		if not bool(receipt.get("accepted", false)):
			push_error(
				"Records Annex art capture could not commission a tier: %s" % String(
					receipt.get("reason", "unknown reason")
				)
			)
			get_tree().quit(1)
			return
	var capture_lanes: Array[StringName] = [
		&"nest_damage",
		&"predator_loss",
		&"appeals",
	]
	var intake_index := 0
	while int(_simulation.snapshot().get("claims_outstanding", 0)) < _simulation.current_claim_capacity():
		_simulation.call("_enqueue_new_claim", capture_lanes[intake_index % capture_lanes.size()])
		intake_index += 1
	_simulation.call("_offer_new_claim", &"appeals")
	_on_snapshot_changed(_simulation.snapshot())
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false
	_camera_controller.focus_point(
		RECORDS_ANNEX_FOCUS,
		"RECORDS ANNEX ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("records_annex_level3.png")


func _capture_service_coop_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	for facility_id in [&"records_annex", &"farm_mutual_service_coop"]:
		for _level in 3:
			var receipt := _simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error(
					"Service Coop art capture could not commission %s: %s" % [
						String(facility_id),
						String(receipt.get("reason", "unknown reason")),
					]
				)
				get_tree().quit(1)
				return
	_on_snapshot_changed(_simulation.snapshot())
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false
	_camera_controller.focus_point(
		FARM_MUTUAL_SERVICE_COOP_FOCUS,
		"SERVICE COOP ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("farm_mutual_service_coop_level3.png")


func _capture_service_coop_ui_preview() -> void:
	_prepare_capture_running()
	_simulation.day = 4
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = 100_000
	_simulation.market_contracts_succeeded_total = 1
	_simulation.market_contracts_breached_total = 0
	_simulation.market_clean_contract_streak = 1
	_simulation.best_market_clean_contract_streak = 1
	_simulation.owned_facilities[&"records_annex"] = 1
	_on_snapshot_changed(_simulation.snapshot())
	if _day_review_scrim != null:
		_day_review_scrim.visible = false
	_set_campaign_modal_open(false)
	_open_flockwatch_page(FlockwatchNavigation.PAGE_CAPITAL)
	await get_tree().process_frame
	var scroll := _flockwatch_navigation.page_scroll(FlockwatchNavigation.PAGE_CAPITAL)
	var facility_card := find_child("FacilityCard_farm_mutual_service_coop", true, false) as Control
	if scroll != null and facility_card != null:
		var component_offset := (
			facility_card.global_position.y
			- scroll.global_position.y
			+ float(scroll.scroll_vertical)
			- 24.0
		)
		scroll.scroll_vertical = maxi(0, int(component_offset))
	await get_tree().create_timer(0.65).timeout
	_save_preview("farm_mutual_service_coop_requisition.png")


func _capture_negotiation_room_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	for facility_id in [&"records_annex", &"farm_mutual_service_coop"]:
		var max_level := int(_simulation.facility_status(facility_id).get("max_level", 1))
		for _level in max_level:
			var tier_receipt := _simulation.purchase_facility(facility_id)
			if not bool(tier_receipt.get("accepted", false)):
				push_error("Negotiation Room capture prerequisite held: %s" % String(tier_receipt.get("reason", "unknown reason")))
				get_tree().quit(1)
				return
	var room_receipt := _simulation.purchase_facility(&"farm_mutual_negotiation_room")
	if not bool(room_receipt.get("accepted", false)):
		push_error("Negotiation Room art capture could not commission the room: %s" % String(room_receipt.get("reason", "unknown reason")))
		get_tree().quit(1)
		return
	var rider_receipt := _simulation.sign_market_contract(
		&"predator_watch_pool",
		&"specialist_roost_endorsement",
	)
	if not bool(rider_receipt.get("accepted", false)):
		push_error("Negotiation Room art capture could not bind its rider: %s" % String(rider_receipt.get("reason", "unknown reason")))
		get_tree().quit(1)
		return
	_on_snapshot_changed(_simulation.snapshot())
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false
	_camera_controller.focus_point(
		FARM_MUTUAL_NEGOTIATION_ROOM_FOCUS,
		"GOLD NEGOTIATION ROOM ART CHECK",
		0.35,
		7.4,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("farm_mutual_negotiation_room.png")


func _capture_contract_board_world_preview() -> void:
	_prepare_capture_running()
	_simulation.day = 3
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 100_000)
	_on_snapshot_changed(_simulation.snapshot())
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false
	_camera_controller.focus_point(
		FARM_MUTUAL_BOARD_FOCUS,
		"FARM MUTUAL BOARD ART CHECK",
		0.35,
		4.8,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("farm_mutual_contract_board_world.png")


func _capture_contract_board_ui_preview() -> void:
	_prepare_capture_running()
	_simulation.day = 3
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 100_000)
	_on_snapshot_changed(_simulation.snapshot())
	_campaign_review_stage = &"contract_board"
	_campaign_ui.show_contract_board(_simulation.snapshot())
	_set_campaign_modal_open(true)
	var board_ui := _campaign_ui.contract_board_ui()
	if board_ui != null:
		board_ui.call("_on_offer_pressed", &"homestead_stability_binder")
	await get_tree().create_timer(0.65).timeout
	_save_preview("farm_mutual_contract_board_ui.png")


func _capture_negotiation_board_ui_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	_simulation.day = 9
	for facility_id in [&"records_annex", &"farm_mutual_service_coop", &"farm_mutual_negotiation_room"]:
		var max_level := int(_simulation.facility_status(facility_id).get("max_level", 1))
		for _level in max_level:
			var receipt := _simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error("Negotiated Board capture prerequisite held: %s" % String(receipt.get("reason", "unknown reason")))
				get_tree().quit(1)
				return
	_on_snapshot_changed(_simulation.snapshot())
	_campaign_review_stage = &"contract_board"
	_campaign_ui.show_contract_board(_simulation.snapshot())
	_set_campaign_modal_open(true)
	var board_ui := _campaign_ui.contract_board_ui()
	if board_ui != null:
		board_ui.call("_on_offer_pressed", &"predator_watch_pool")
		board_ui.call("_on_negotiation_toggle_pressed")
		board_ui.call("_on_clause_pressed", &"expedited_hatch_rider")
	await get_tree().create_timer(0.65).timeout
	_save_preview("farm_mutual_negotiated_board_ui.png")


func _capture_wellness_nest_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	for _level in 3:
		var receipt := _simulation.purchase_facility(&"wellness_nest_room")
		if not bool(receipt.get("accepted", false)):
			push_error("Wellness Nest art capture could not commission a tier: %s" % String(receipt.get("reason", "unknown reason")))
			get_tree().quit(1)
			return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		WELLNESS_NEST_FOCUS,
		"WELLNESS NEST ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("wellness_nest_level3.png")


func _capture_training_roost_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	for facility_id in [&"wellness_nest_room", &"training_roost"]:
		for _level in 3:
			var receipt := _simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error(
					"Training Roost art capture could not commission %s: %s" % [
						String(facility_id),
						String(receipt.get("reason", "unknown reason")),
					]
				)
				get_tree().quit(1)
				return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		TRAINING_ROOST_FOCUS,
		"TRAINING ROOST ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("training_roost_level3.png")


func _capture_care_campus_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	for facility_id in [&"wellness_nest_room", &"training_roost"]:
		for _level in 3:
			var receipt := _simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error("Care campus capture could not commission %s: %s" % [String(facility_id), String(receipt.get("reason", "unknown reason"))])
				get_tree().quit(1)
				return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		CARE_CAMPUS_FOCUS,
		"FLOCK CARE CAMPUS",
		0.35,
		14.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("care_campus.png")


func _capture_farmer_relations_gallery_preview() -> void:
	_prepare_capture_running()
	_prepare_farmer_relations_gallery_capture_economy()
	for facility_id in [&"farmer_brand_packing_annex", &"farmer_relations_gallery"]:
		if not _commission_capture_facility(facility_id):
			return
	if not _prepare_farmer_relations_gallery_capture_record():
		return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		FARMER_RELATIONS_GALLERY_FOCUS,
		"HARVEST CREDIT GALLERY ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("harvest_credit_gallery_level3.png")


func _capture_rooster_operations_office_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	if not _commission_capture_facility(&"rooster_operations_office"):
		return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		ROOSTER_OPERATIONS_OFFICE_FOCUS,
		"ROOSTER OPERATIONS ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("rooster_operations_office_level3.png")


func _capture_it_coop_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	for facility_id in [&"records_annex", &"rooster_operations_office", &"it_coop"]:
		if not _commission_capture_facility(facility_id):
			return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		IT_COOP_FOCUS,
		"IT COOP ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("it_coop_level3.png")


func _capture_operations_campus_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	for facility_id in [&"records_annex", &"rooster_operations_office", &"it_coop"]:
		if not _commission_capture_facility(facility_id):
			return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		OPERATIONS_CAMPUS_FOCUS,
		"OPERATIONS CAMPUS",
		0.35,
		11.0,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("operations_campus.png")


func _capture_flock_relations_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	_prepare_operations_campus_capture_economy()
	_prepare_flock_relations_capture_economy()
	for facility_id in [&"wellness_nest_room", &"rooster_operations_office", &"flock_relations_office"]:
		if not _commission_capture_facility(facility_id):
			return
	_prepare_flock_relations_capture_cases()
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		FLOCK_RELATIONS_OFFICE_FOCUS,
		"FLOCK RELATIONS ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("flock_relations_office_level3.png")


func _capture_flock_provisions_preview() -> void:
	_prepare_capture_running()
	_prepare_operations_campus_capture_economy()
	if not _commission_capture_facility(&"feed_procurement_coop"):
		return
	var order := _simulation.authorize_feed_order(&"fixed_future_reserve")
	if not bool(order.get("accepted", false)):
		push_error("Provisions art capture could not file reserve order: %s" % String(
			order.get("reason", "unknown reason"),
		))
		get_tree().quit(1)
		return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		FLOCK_PROVISIONS_COOP_FOCUS,
		"FLOCK PROVISIONS ART CHECK",
		0.35,
		7.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("flock_provisions_coop_level3.png")


func _capture_governance_campus_preview() -> void:
	_prepare_capture_running()
	_prepare_care_campus_capture_economy()
	_prepare_operations_campus_capture_economy()
	_prepare_flock_relations_capture_economy()
	for facility_id in [
		&"wellness_nest_room",
		&"farmer_brand_packing_annex",
		&"farmer_relations_gallery",
		&"records_annex",
		&"rooster_operations_office",
		&"it_coop",
		&"flock_relations_office",
		&"feed_procurement_coop",
	]:
		if not _commission_capture_facility(facility_id):
			return
	if not _prepare_farmer_relations_gallery_capture_record():
		return
	var provisions_order := _simulation.authorize_feed_order(&"fixed_future_reserve")
	if not bool(provisions_order.get("accepted", false)):
		push_error("Governance capture could not file provisions order: %s" % String(
			provisions_order.get("reason", "unknown reason"),
		))
		get_tree().quit(1)
		return
	_prepare_flock_relations_capture_cases()
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		GOVERNANCE_CAMPUS_FOCUS,
		"GOVERNANCE CAMPUS",
		0.35,
		18.2,
	)
	await get_tree().create_timer(0.95).timeout
	_save_preview("governance_campus.png")


func _capture_farmgate_dispatch_preview(target_level: int) -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(target_level):
		return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		FARMGATE_DISPATCH_DEPOT_FOCUS,
		"FARMGATE DISPATCH ART CHECK",
		0.35,
		13.0,
	)
	await get_tree().create_timer(1.0).timeout
	var suffix := "locked" if target_level < 0 else ("survey" if target_level == 0 else "level%d" % target_level)
	_save_preview("farmgate_dispatch_%s.png" % suffix)


func _capture_dispatch_campus_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(3):
		return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.focus_point(
		Vector3(19.15, 1.05, -2.60),
		"PACKING AND DISPATCH CAMPUS",
		0.35,
		19.0,
	)
	await get_tree().create_timer(1.0).timeout
	_save_preview("dispatch_campus.png")


func _capture_capital_blueprint_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(0):
		return
	_on_snapshot_changed(_simulation.snapshot())
	_open_capital_blueprint(false, false)
	if _capital_blueprint_ui != null:
		_capital_blueprint_ui.call("select_facility", &"farmgate_dispatch_depot", false)
	await get_tree().create_timer(0.75).timeout
	_save_preview("capital_blueprint.png")


func _capture_commissioning_reveal_preview() -> void:
	_prepare_capture_running()
	if not _prepare_farmgate_capture_economy(0):
		return
	_on_snapshot_changed(_simulation.snapshot())
	_on_facility_purchase_requested(&"farmgate_dispatch_depot")
	await get_tree().create_timer(1.0).timeout
	_save_preview("farmgate_commissioning_reveal.png")


func _capture_campus_expansion_preview() -> void:
	_prepare_capture_running()
	if not _prepare_campus_expansion_capture_economy():
		return
	var snapshot := _simulation.snapshot()
	_on_snapshot_changed(snapshot)
	_settle_campus_workers_for_capture()
	_hide_world_capture_overlays()
	var art_bounds := CampusExpansionVisualScript.camera_bounds(snapshot)
	var art_focus := art_bounds.get_center()
	art_focus.y = NORTH_MEADOW_FOCUS.y
	var frame_size := maxf(art_bounds.size.x, art_bounds.size.z) + 1.0
	_camera_controller.focus_point(
		art_focus,
		"NORTH MEADOW CAMPUS ART CHECK",
		0.35,
		frame_size,
	)
	await get_tree().create_timer(1.0).timeout
	_save_preview("campus_expansion_operational.png")


func _capture_campus_portfolio_preview() -> void:
	_prepare_capture_running()
	if not _prepare_campus_portfolio_capture_economy():
		return
	var snapshot := _simulation.snapshot()
	_on_snapshot_changed(snapshot)
	_hide_world_capture_overlays()
	var art_bounds := CampusPortfolioVisualScript.camera_bounds(snapshot)
	var art_focus := art_bounds.get_center()
	art_focus.y = CAMPUS_PORTFOLIO_FOCUS.y
	var frame_size := maxf(art_bounds.size.x, art_bounds.size.z) + 1.5
	_camera_controller.focus_point(
		art_focus,
		"CAMPUS PORTFOLIO ART CHECK",
		0.35,
		frame_size,
	)
	await get_tree().create_timer(1.0).timeout
	_save_preview("campus_portfolio_complete.png")


func _settle_campus_workers_for_capture() -> void:
	# Portfolio captures should prove the named staffing promise, not photograph
	# four hens halfway through a long first commute. Large deltas are isolated to
	# this deterministic capture path and still consume every authored waypoint.
	for view_value: Variant in _worker_views.values():
		var view := view_value as ChickenView
		if view == null or not is_instance_valid(view) or not view.has_campus_duty_assignment():
			continue
		for _capture_step in 170:
			if view.is_at_campus_duty_station():
				break
			view.call("_physics_process", 0.75)


func _capture_campus_portfolio_ui_preview() -> void:
	_prepare_capture_running()
	if not _prepare_campus_portfolio_capture_economy():
		return
	_on_snapshot_changed(_simulation.snapshot())
	_on_campus_expansion_requested()
	if _campus_portfolio_ui != null:
		_campus_portfolio_ui.call("select_parcel", &"creekside_yard")
		_campus_portfolio_ui.call("select_pad", &"creekside_east")
		_campus_portfolio_ui.call("select_module", &"creekside_chilling_exchange")
	await get_tree().create_timer(0.75).timeout
	_save_preview("campus_portfolio_ui.png")


func _prepare_campus_portfolio_capture_economy() -> bool:
	if not _prepare_campus_expansion_capture_economy():
		return false
	_simulation._campus_portfolio.begin_day(
		_simulation.day,
		_simulation._campus_portfolio_context(),
	)
	var deed := _simulation.purchase_campus_portfolio_deed(&"orchard_row")
	if not _campus_capture_receipt_accepted(deed, "purchase Orchard Row"):
		return false
	deed = _simulation.purchase_campus_portfolio_deed(&"creekside_yard")
	if not _campus_capture_receipt_accepted(deed, "purchase Creekside Yard"):
		return false
	for project_file: Dictionary in [
		{"module": &"collection_rail_hub", "pad": &"orchard_west"},
		{"module": &"grain_recovery_mill", "pad": &"orchard_east"},
		{"module": &"contractor_roost", "pad": &"creekside_west"},
	]:
		var project := _simulation.authorize_campus_portfolio_project(
			project_file["module"],
			project_file["pad"],
		)
		if not _campus_capture_receipt_accepted(
			project,
			"authorize %s" % String(project_file["module"]).replace("_", " "),
		):
			return false
	for target_day in [16, 19, 21]:
		_simulation.day = target_day
		_simulation._campus_portfolio.begin_day(
			target_day,
			_simulation._campus_portfolio_context(),
		)
	var staffing := _simulation.assign_campus_portfolio_worker(&"contractor_roost", 3)
	if not _campus_capture_receipt_accepted(staffing, "staff Contractor Roost"):
		return false
	var chilling := _simulation.authorize_campus_portfolio_project(
		&"creekside_chilling_exchange",
		&"creekside_east",
	)
	if not _campus_capture_receipt_accepted(chilling, "authorize Creekside Chilling Exchange"):
		return false
	_simulation.day = 24
	_simulation._campus_portfolio.begin_day(
		24,
		_simulation._campus_portfolio_context(),
	)
	for assignment: Dictionary in [
		{"module": &"collection_rail_hub", "worker": 0},
		{"module": &"grain_recovery_mill", "worker": 1},
		{"module": &"creekside_chilling_exchange", "worker": 2},
	]:
		staffing = _simulation.assign_campus_portfolio_worker(
			assignment["module"],
			int(assignment["worker"]),
		)
		if not _campus_capture_receipt_accepted(
			staffing,
			"staff %s" % String(assignment["module"]).replace("_", " "),
		):
			return false
	return true


func _prepare_campus_expansion_capture_economy() -> bool:
	# Establish only the deterministic access and funding fixture directly. Every
	# capital mutation below must pass through the simulation's receipt-producing
	# authorization API so the capture exercises the same rules as live play.
	_simulation.day = 14
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = 1_000_000
	_simulation.market_contracts_succeeded_total = 1
	_simulation.market_contracts_breached_total = 0

	var receipt := _simulation.purchase_campus_parcel(&"north_meadow")
	if not _campus_capture_receipt_accepted(receipt, "purchase North Meadow"):
		return false
	for service_id: StringName in [&"circulation", &"power", &"cold_chain"]:
		receipt = _simulation.commission_campus_service(service_id)
		if not _campus_capture_receipt_accepted(
			receipt,
			"commission %s" % String(service_id).replace("_", " "),
		):
			return false
	receipt = _simulation.place_campus_module(CAMPUS_ROUTING_POD_ID, &"meadow_west")
	if not _campus_capture_receipt_accepted(receipt, "place the Egg Routing Pod"):
		return false

	var campus := _simulation.campus_expansion_snapshot()
	var connected_services: Dictionary[StringName, bool] = {}
	for service_value in campus.get("services", []) as Array:
		if not service_value is Dictionary:
			continue
		var service := service_value as Dictionary
		connected_services[StringName(String(service.get("id", "")))] = bool(
			service.get("connected", false)
		)
	var fixture_is_operational := (
		bool(campus.get("parcel_owned", false))
		and bool(connected_services.get(&"circulation", false))
		and bool(connected_services.get(&"power", false))
		and bool(connected_services.get(&"cold_chain", false))
		and bool(campus.get("pod_operational", false))
		and bool(campus.get("cold_chain_active", false))
		and StringName(String(campus.get("pod_socket_id", ""))) == &"meadow_west"
	)
	if not fixture_is_operational:
		push_error(
			"Campus expansion art capture fixture did not reach its operational state: %s"
			% String(campus.get("summary", "missing campus summary"))
		)
		get_tree().quit(1)
		return false
	return true


func _campus_capture_receipt_accepted(receipt: Dictionary, action_label: String) -> bool:
	if bool(receipt.get("accepted", false)):
		return true
	push_error("Campus expansion art capture could not %s: %s" % [
		action_label,
		String(receipt.get("reason", "unknown reason")),
	])
	get_tree().quit(1)
	return false


func _prepare_farmgate_capture_economy(target_level: int) -> bool:
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 1_000_000)
	if target_level < 0:
		_simulation.day = 1
		_simulation._farmgate_dispatch.begin_day(1)
		return true
	_simulation.day = 14
	_simulation.office_capacity = 6
	for worker_index in mini(6, _simulation.workers.size()):
		var worker = _simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index
	_simulation._harvest_credit.public_standing = 25
	_simulation._farmgate_dispatch.begin_day(14)
	var prerequisite_level := 3 if target_level == 0 else target_level
	for facility_id in [&"farmer_brand_packing_annex", &"farmer_relations_gallery"]:
		while _simulation.facility_level(facility_id) < prerequisite_level:
			var prerequisite := _simulation.purchase_facility(facility_id)
			if not bool(prerequisite.get("accepted", false)):
				push_error("Farmgate capture prerequisite held: %s" % String(
					prerequisite.get("reason", "unknown reason"),
				))
				get_tree().quit(1)
				return false
	while _simulation.facility_level(&"farmgate_dispatch_depot") < target_level:
		var receipt := _simulation.purchase_facility(&"farmgate_dispatch_depot")
		if not bool(receipt.get("accepted", false)):
			push_error("Farmgate capture tier held: %s" % String(
				receipt.get("reason", "unknown reason"),
			))
			get_tree().quit(1)
			return false
	if target_level > 0:
		var lot_count: int = int([0, 5, 11, 18][target_level])
		for lot_index in lot_count:
			_simulation._farmgate_dispatch.store_lot(
				9_000 + lot_index,
				14,
				lot_index % 6,
				"CAPTURE HEN %d" % (lot_index % 6 + 1),
				&"golden" if lot_index % 5 == 0 else &"sound",
				450 + lot_index * 35,
				target_level,
				_simulation._farmgate_shelf_life_shifts(),
				_simulation._farmgate_storage_capacity_eggs(),
			)
	return true


func _capture_expansion_overview_preview() -> void:
	_prepare_capture_running()
	_prepare_service_coop_capture_economy()
	_prepare_care_campus_capture_economy()
	_prepare_operations_campus_capture_economy()
	_prepare_flock_relations_capture_economy()
	_simulation.day = maxi(_simulation.day, 14)
	_simulation._harvest_credit.public_standing = maxi(
		_simulation._harvest_credit.public_standing,
		25,
	)
	_simulation.apply_campaign_unlock(&"shell_quality_checks")
	for facility_id in [
		&"candling_rework_bay",
		&"farmer_brand_packing_annex",
		&"records_annex",
		&"farm_mutual_service_coop",
		&"farm_mutual_negotiation_room",
		&"wellness_nest_room",
		&"training_roost",
		&"farmer_relations_gallery",
		&"rooster_operations_office",
		&"it_coop",
		&"flock_relations_office",
		&"feed_procurement_coop",
		&"farmgate_dispatch_depot",
	]:
		var max_level := int(_simulation.facility_status(facility_id).get("max_level", 1))
		for _level in max_level:
			var receipt := _simulation.purchase_facility(facility_id)
			if not bool(receipt.get("accepted", false)):
				push_error(
					"Expansion overview could not commission %s: %s" % [
						String(facility_id),
						String(receipt.get("reason", "unknown reason")),
					]
				)
				get_tree().quit(1)
				return
	_on_snapshot_changed(_simulation.snapshot())
	_hide_world_capture_overlays()
	_camera_controller.show_overview()
	await get_tree().create_timer(1.0).timeout
	_save_preview("expansion_overview.png")


func _prepare_service_coop_capture_economy() -> void:
	_simulation.day = 7
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = 1_000_000
	_simulation.market_contracts_succeeded_total = 6
	_simulation.market_contracts_breached_total = 0
	_simulation.market_clean_contract_streak = 6
	_simulation.best_market_clean_contract_streak = 6
	_simulation.office_capacity = 6
	for worker_index in mini(6, _simulation.workers.size()):
		var worker = _simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index


func _prepare_care_campus_capture_economy() -> void:
	_simulation.day = maxi(_simulation.day, 10)
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 1_000_000)
	_simulation.office_capacity = 6
	var credential_lanes: Array[StringName] = [&"appeals", &"nest_damage", &"predator_loss"]
	for worker_index in mini(6, _simulation.workers.size()):
		var worker = _simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index
		worker.career_xp = maxi(worker.career_xp, 80)
		if worker_index < 3:
			var credential_lane := credential_lanes[worker_index]
			if credential_lane == worker.specialty:
				credential_lane = credential_lanes[(worker_index + 1) % credential_lanes.size()]
			worker.secondary_specialty = credential_lane
		elif worker_index == 3:
			var training_lane := &"appeals" if worker.specialty != &"appeals" else &"predator_loss"
			worker.cross_training_target = training_lane


func _prepare_operations_campus_capture_economy() -> void:
	_simulation.day = maxi(_simulation.day, 12)
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 1_000_000)
	_simulation.office_capacity = 6
	for worker_index in mini(6, _simulation.workers.size()):
		var worker = _simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index


func _prepare_flock_relations_capture_economy() -> void:
	_simulation.day = maxi(_simulation.day, 13)
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 1_000_000)
	_simulation.office_capacity = 6
	for worker_index in mini(6, _simulation.workers.size()):
		var worker = _simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index
		worker.manager_trust = 72.0
		worker.grievance = 10.0
		worker.stress = 22.0
		worker.fatigue = 16.0


func _prepare_farmer_relations_gallery_capture_economy() -> void:
	_simulation.day = maxi(_simulation.day, 13)
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = maxi(_simulation.revenue_cents, 1_000_000)
	_simulation.office_capacity = 6
	for worker_index in mini(6, _simulation.workers.size()):
		var worker = _simulation.workers[worker_index]
		worker.employed = true
		worker.desk_index = worker_index


func _prepare_farmer_relations_gallery_capture_record() -> bool:
	# Close one authored basket through the real simulation, then file the shared
	# results campaign. The capture therefore cannot invent a hen, payout, standing
	# tier, or attribution receipt that gameplay did not produce.
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	_simulation.pending_decision.clear()
	_simulation.eggs_today = 29
	_simulation.cracked_today = 2
	_simulation.golden_today = 1
	_simulation.eggs_total = maxi(_simulation.eggs_total, 29)
	_simulation.cracked_eggs = maxi(_simulation.cracked_eggs, 2)
	_simulation.golden_eggs = maxi(_simulation.golden_eggs, 1)
	_simulation.quota_target = 24
	_simulation.credited_today_cents = 12_400
	if not _simulation.workers.is_empty():
		var top_row: Dictionary = _simulation._worker_shift_stats[0]
		top_row.merge({
			"eggs": 9,
			"sound": 8,
			"cracked": 1,
			"golden": 1,
			"credit_cents": 4_200,
		}, true)
		_simulation._worker_shift_stats[0] = top_row
	_simulation._complete_workday()
	var campaign := _simulation.file_farmer_relations_campaign(&"clutch_results_board")
	if not bool(campaign.get("accepted", false)):
		push_error("Gallery art capture could not file its results campaign: %s" % String(
			campaign.get("reason", "unknown reason"),
		))
		get_tree().quit(1)
		return false
	return true


func _prepare_flock_relations_capture_cases() -> void:
	# Use the real deterministic filing and resolution APIs so the room never
	# depicts a folder, settlement, or outcome lamp that the economy did not own.
	if _simulation.workers.size() < 3:
		return
	var first_worker = _simulation.workers[0]
	first_worker.manager_trust = 24.0
	first_worker.grievance = 82.0
	first_worker.stress = 76.0
	first_worker.fatigue = 68.0
	_simulation.call("_file_flock_relations_case_after_shift", _simulation.day)
	var first_snapshot := _simulation.flock_relations_snapshot()
	var first_cases := first_snapshot.get("open_cases", []) as Array
	if not first_cases.is_empty():
		var first_case := first_cases[0] as Dictionary
		_simulation.resolve_flock_relations_case(
			int(first_case.get("case_id", 0)),
			&"fund_remedy",
		)
	first_worker.manager_trust = 72.0
	first_worker.grievance = 10.0
	first_worker.stress = 22.0
	first_worker.fatigue = 16.0

	var second_worker = _simulation.workers[1]
	second_worker.manager_trust = 32.0
	second_worker.grievance = 70.0
	second_worker.stress = 68.0
	second_worker.fatigue = 60.0
	_simulation.call("_file_flock_relations_case_after_shift", _simulation.day)

	var third_worker = _simulation.workers[2]
	third_worker.manager_trust = 38.0
	third_worker.grievance = 58.0
	third_worker.stress = 70.0
	third_worker.fatigue = 66.0
	_simulation.call("_file_flock_relations_case_after_shift", _simulation.day)


func _commission_capture_facility(facility_id: StringName) -> bool:
	var max_level := int(_simulation.facility_status(facility_id).get("max_level", 1))
	for _level in max_level:
		var receipt := _simulation.purchase_facility(facility_id)
		if not bool(receipt.get("accepted", false)):
			push_error(
				"Operations art capture could not commission %s: %s" % [
					String(facility_id),
					String(receipt.get("reason", "unknown reason")),
				]
			)
			get_tree().quit(1)
			return false
	return true


func _hide_world_capture_overlays() -> void:
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false


func _capture_signage_preview(focus: Vector3, file_name: String) -> void:
	_prepare_capture_running()
	# Art-review captures need to judge the physical prop, not the management HUD.
	# Keep gameplay captures elsewhere; this route deliberately removes screen UI
	# and actors that otherwise cover the shallow wall and desk fixtures.
	if _ui_root != null:
		_ui_root.visible = false
	if _workers_node != null:
		_workers_node.visible = false
	if _management_presence != null:
		_management_presence.visible = false
	var inspection_size := 5.2
	if file_name.contains("desk"):
		inspection_size = 4.0
	elif file_name.contains("intake"):
		inspection_size = 4.4
	elif file_name.contains("left"):
		inspection_size = 5.6
	_camera_controller.focus_point(focus, "SIGNAGE ART CHECK", 0.35, inspection_size)
	await get_tree().create_timer(0.9).timeout
	_save_preview(file_name)


func _capture_campaign_title_preview() -> void:
	_decision_host.visible = false
	_campaign_ui.show_title(false)
	_set_campaign_modal_open(true)
	await get_tree().create_timer(0.55).timeout
	_save_preview("probation_title.png")


func _capture_campaign_report_preview() -> void:
	_decision_host.visible = false
	_campaign_state = CampaignStateScript.new()
	var report := _campaign_capture_report(1)
	_last_workday_report = report.duplicate(true)
	_campaign_state.record_shift(report, {})
	_simulation.last_credit_allocation = {
		"day": 1,
		"decision_id": "closing_credit_memo",
		"option_id": "share_the_scoop",
		"style_id": "shared_scoop",
		"worker_id": 1,
		"worker_name": "Mabel",
		"cost_cents": 0,
		"outcome": "Mabel's clutch was credited to the flock. The farmer retained management's name on the presentation.",
		"special_event": false,
		"projected": false,
	}
	_campaign_review_stage = &"probation"
	_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
	_set_campaign_modal_open(true)
	await get_tree().create_timer(0.55).timeout
	_save_preview("probation_report.png")


func _capture_career_sponsorship_preview() -> void:
	_decision_host.visible = false
	_campaign_state = CampaignStateScript.new()
	_senior_roost_state = SeniorRoostStateScript.new()
	if not _senior_roost_state.begin(5):
		push_error("Career Sponsorship capture could not open the Senior Roost ledger.")
		get_tree().quit(1)
		return
	var mandate_receipt: Dictionary = _senior_roost_state.select_annual_mandate(
		SeniorRoostStateScript.MANDATE_FALLBACK_ID,
		_senior_roost_state.current_year_number(),
	)
	if not bool(mandate_receipt.get("accepted", false)):
		push_error("Career Sponsorship capture could not file the annual Board fallback.")
		get_tree().quit(1)
		return
	if not _senior_roost_state.record_quarter_policy({
		"accepted": true,
		"policy_id": &"harvest_forecast",
		"style_id": &"management_innovation",
		"outcome": "Harvest Forecast funded one protected planning quarter.",
	}):
		push_error("Career Sponsorship capture could not file its quarterly policy.")
		get_tree().quit(1)
		return
	for day in [6, 7, 8]:
		var shift_result: Dictionary = _senior_roost_state.record_shift(
			_career_sponsorship_capture_report(day, day - 5)
		)
		if not bool(shift_result.get("accepted", false)):
			push_error("Career Sponsorship capture could not close Senior shift %d." % day)
			get_tree().quit(1)
			return

	for worker in _simulation.workers:
		worker.career_xp = 0
		worker.secondary_specialty = &""
		worker.cross_training_target = &""
		worker.cross_training_worked_this_shift = false
	var capture_worker = _simulation.workers[0]
	capture_worker.career_xp = 18
	_simulation.day = 9
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.pending_decision.clear()
	_simulation.revenue_cents = (
		_simulation.current_daily_operating_cost_cents()
		+ _simulation.wage_arrears_cents
		+ 5000
	)
	_last_workday_report = _career_sponsorship_capture_report(8, 3)
	_campaign_senior_roost = true
	_campaign_review_stage = &"senior_quarter"
	_campaign_ui.show_between_shift_report(_senior_presentation_snapshot(&"between_shift"))
	_set_campaign_modal_open(true)
	await get_tree().process_frame
	await get_tree().process_frame

	var sponsorship := _campaign_ui.find_child("CareerSponsorshipUI", true, false) as Control
	var scroll := _campaign_ui.get("_modal_scroll") as ScrollContainer
	if sponsorship == null or scroll == null or not sponsorship.is_visible_in_tree():
		push_error("Career Sponsorship capture requires the authentic visible report component.")
		get_tree().quit(1)
		return
	var component_offset := (
		sponsorship.get_global_rect().position.y
		- scroll.get_global_rect().position.y
		+ float(scroll.scroll_vertical)
		- 14.0
	)
	scroll.scroll_vertical = maxi(0, int(component_offset))
	await get_tree().process_frame
	await get_tree().process_frame
	_save_preview("career_sponsorship.png")


func _capture_campaign_final_preview() -> void:
	_decision_host.visible = false
	_campaign_state = CampaignStateScript.new()
	for shift_number in range(1, CampaignStateScript.CAMPAIGN_LENGTH + 1):
		if shift_number == 3:
			_campaign_state.choose_milestone(&"padded_perches")
		_campaign_state.record_shift(_campaign_capture_report(shift_number), {})
	_simulation.flock_restructuring_resolved = true
	_simulation.flock_restructuring_day = DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT
	_simulation.flock_restructuring_record = {
		"worker_name": "Mabel",
		"option_id": "contest_ranking",
	}
	_campaign_review_stage = &"final"
	_campaign_ui.show_final_review(_campaign_presentation_snapshot(&"final"))
	_set_campaign_modal_open(true)
	await get_tree().create_timer(0.55).timeout
	_save_preview("probation_final.png")


func _capture_restructuring_preview() -> void:
	_clock.set_speed(0)
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
	_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
	_set_campaign_modal_open(false)
	_simulation.pending_decision.clear()
	_simulation.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	_simulation.day = DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT + 1
	var ranking := _simulation.current_pecking_order()
	_simulation._prepare_credit_allocation_decision(
		DepartmentSimulation.FLOCK_RESTRUCTURING_SHIFT,
		ranking,
		0,
	)
	_simulation.announce_pending_decision()
	await get_tree().create_timer(0.65).timeout
	_save_preview("flock_restructuring.png")


func _campaign_capture_report(shift_number: int) -> Dictionary:
	return {
		"day": shift_number,
		"eggs": 28,
		"quota": 24 + shift_number,
		"cracked": 1,
		"overdue_claims": 0,
		"rework_created": 0,
		"credited_cents": 6800,
		"welfare": 78,
		"compliance": 84,
		"farmer_favor": 76,
		"hen_highlight": {
			"version": 1,
			"type": "golden_deliverable",
			"day": shift_number,
			"worker_id": 1,
			"worker_name": "Mabel",
			"career_title": "ACCREDITED LAYER",
			"relationship_label": "WARY",
			"rank": 1,
			"eggs": 8,
			"sound": 7,
			"cracked": 0,
			"golden": 1,
			"credit_cents": 2140,
			"headline": "GOLDEN DELIVERABLE",
			"body": "Mabel laid one golden egg. The farmer congratulated management before collecting it.",
			"metric": "8 EGGS  //  7 SOUND  //  1 GOLDEN  //  $21.40 CREDIT",
			"tone": "gold",
		},
	}


func _career_sponsorship_capture_report(day: int, rework_total: int) -> Dictionary:
	return {
		"day": day,
		"eggs": 30,
		"quota": 24,
		"met_quota": true,
		"cracked": 2,
		"golden": 0,
		"quota_bonus_cents": 0,
		"quality_bonus_cents": 0,
		"feed_cost_cents": 1800,
		"credited_cents": 12_000,
		"welfare": 72,
		"compliance": 76,
		"farmer_favor": 66,
		"wage_arrears_cents": 0,
		"overdue_claims": 0,
		"rework_waiting": 0,
		"rework_due_next_shift": 0,
		"rework_total_created": rework_total,
		"closing_fund_cents": 20_000 + day * 100,
		"credit_memo_required": false,
		"pecking_order": [],
		"hen_highlight": {},
	}


func _prepare_capture_running() -> void:
	if _simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		_simulation.select_directive(&"shell_assurance")
	_clock.set_speed(0)


func _save_preview(file_name: String) -> void:
	var capture_directory := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("Unable to save %s: the active display driver does not provide a render texture." % file_name)
		get_tree().quit(1)
		return
	var error := image.save_png(capture_directory.path_join(file_name))
	if error != OK:
		push_error("Unable to save %s: %s" % [file_name, error_string(error)])
	get_tree().quit()


func _add_box(parent: Node, part_name: String, size: Vector3, part_position: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _box_batch_transform(
	size: Vector3,
	part_position: Vector3,
	rotation_degrees: Vector3 = Vector3.ZERO,
) -> Transform3D:
	var rotation_radians := Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z),
	)
	var basis := Basis.from_euler(rotation_radians) * Basis.from_scale(size)
	return Transform3D(basis, part_position)


func _add_box_multimesh(
	parent: Node,
	part_name: String,
	transforms: Array[Transform3D],
	color: Color,
	shadow_casting: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
) -> MultiMeshInstance3D:
	var unit_box := BoxMesh.new()
	unit_box.size = Vector3.ONE
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = unit_box
	multimesh.instance_count = transforms.size()
	for transform_index in transforms.size():
		multimesh.set_instance_transform(transform_index, transforms[transform_index])
	var instance := MultiMeshInstance3D.new()
	instance.name = part_name
	instance.multimesh = multimesh
	instance.material_override = _material(color)
	instance.cast_shadow = shadow_casting
	parent.add_child(instance)
	return instance


func _add_cylinder(parent: Node, part_name: String, part_position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.88
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_sphere(parent: Node, part_name: String, part_position: Vector3, part_scale: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color)
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
