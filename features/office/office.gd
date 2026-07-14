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
const PeckworkRoutingUIScript := preload("res://features/office/peckwork_routing_ui.gd")
const RoostStaffingUIScript := preload("res://features/office/roost_staffing_ui.gd")
const PeckingOrderUIScript := preload("res://features/office/pecking_order_ui.gd")
const CampaignStateScript := preload("res://core/campaign/campaign_state.gd")
const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")
const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
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
const FEED_PARTY_STATION_POSITION := Vector3(-10.15, 0.0, 0.0)
const FEED_PARTY_STATION_SCALE := 0.78
const FEED_PARTY_DURATION := 5.0
const INITIAL_CAMPAIGN_STAFF := 4
const MAXIMUM_OFFICE_CAPACITY := 6
const PECK_ASSIST_ACTION: StringName = &"peck_assist"
const FIRST_CLUTCH_VERSION := 1
const FIRST_CLUTCH_COMPLETION_HOLD_SECONDS := 5.5
const FIRST_HEN_WORKER_ID := 0

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
var _egg_layer: Node3D
var _feed_party_station: Node3D
var _feed_party_tween: Tween
var _feed_party_active: bool = false
var _feed_party_previous_speed: int = 1
var _feed_party_release_scheduled: bool = false
var _feed_party_arrivals: Dictionary[int, bool] = {}
var _feed_party_returns: Dictionary[int, bool] = {}
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
var _routing_ui: PeckworkRoutingUI
var _staffing_ui: RoostStaffingUI
var _pecking_order_ui
var _last_reviewed_day: int = 1
var _campaign_state = CampaignStateScript.new()
var _senior_roost_state = SeniorRoostStateScript.new()
var _campaign_store = CampaignSaveStoreScript.new(CAMPAIGN_SAVE_FILENAME)
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
	"delivered_quality": "",
	"delivered_value_cents": 0,
	"delivered_priority_credit_cents": 0,
	"potential_priority_credit_cents": 0,
	"prior_presentations_pending": 0,
}
var _first_clutch_completion_hold_until_msec: int = 0
var _first_clutch_completion_generation: int = 0
var _eggs_in_flight_by_worker: Dictionary[int, int] = {}
# Physical eggs can overlap at high simulation speed. Preserve every completion
# in FIFO order so the basket callback settles the exact assisted claim that
# authored that egg instead of guessing from the worker's newer active file.
var _collection_claim_ids_by_worker: Dictionary[int, Array] = {}
var _first_clutch_global_cued_control: Button
var _first_clutch_global_cue_tween: Tween

var _day_label: Label
var _time_label: Label
var _revenue_label: Label
var _claims_label: Label
var _egg_label: Label
var _quota_label: Label
var _confidence_label: Label
var _morale_label: Label
var _compliance_label: Label
var _solidarity_label: Label
var _campaign_objectives_label: Label
var _campaign_orders_heading_label: Label
var _flock_labor_label: Label
var _overtime_button: Button
var _ticker_label: Label
var _flockwatch_panel: PanelContainer
var _flockwatch_toggle: Button
var _flockwatch_open: bool = false
var _speed_buttons: Array[Button] = []
var _ui_root: Control
var _quota_progress: ProgressBar
var _quota_progress_label: Label
var _quality_streak_label: Label
var _directive_badge: Label
var _guidance_label: Label
var _feed_button: Button
var _upgrade_buttons: Dictionary[StringName, Button] = {}
var _day_review_panel: PanelContainer
var _day_review_scrim: ColorRect
var _review_title: Label
var _review_results: Label
var _review_story: Label
var _continue_shift_button: Button
var _begin_next_shift_button: Button
var _decision_host: Control
var _decision_panel: PanelContainer
var _decision_eyebrow: Label
var _decision_title: Label
var _decision_body: Label
var _decision_options: VBoxContainer
var _decision_preview: Label
var _decision_confirm_button: Button
var _decision_stay_paused_button: Button
var _decision_option_buttons: Array[Button] = []
var _active_decision: Dictionary = {}
var _selected_decision_option: StringName = &""
var _decision_previous_speed := 1
var _resume_after_decision := true
var _authoritative_revenue_cents := 0
var _displayed_revenue_cents := -1
var _pending_collection_cents := 0
var _fund_visual_target_cents := -1
var _fund_count_tween: Tween


func _ready() -> void:
	name = "CorporateClaimsDivision"
	_ensure_peck_assist_input_action()
	_build_environment()
	_build_office()
	_predator_encounter = PredatorEncounterScript.new() as PredatorEncounter
	_predator_encounter.victim_carried_away.connect(_on_predator_victim_carried_away)
	add_child(_predator_encounter)
	_office_storytelling = OfficeStorytellingScript.new() as OfficeStorytelling
	_office_storytelling.configure(
		_active_desk_positions(_office_capacity_from_snapshot(_simulation.snapshot())),
		Vector3(9.55, 0.0, 5.35),
		Vector3(9.4, 0.0, -6.85),
	)
	_office_storytelling.egg_graded.connect(_on_egg_graded)
	_office_storytelling.egg_reached_presentation_detailed.connect(_on_egg_reached_presentation)
	add_child(_office_storytelling)
	_office_atmosphere = OfficeAtmosphereScript.new() as OfficeAtmosphere
	add_child(_office_atmosphere)
	EnvironmentalSignageScript.set_camera_detail(
		self, false, Vector3(INF, INF, INF), EnvironmentalSignageScript.FOCUSED_DETAIL_RADIUS, false
	)
	_audio_feedback = OfficeAudioFeedbackScript.new()
	add_child(_audio_feedback)
	_build_ui()

	add_child(_clock)
	_clock.initialize(_simulation)
	_clock.speed_changed.connect(_on_speed_changed)
	_simulation.snapshot_changed.connect(_on_snapshot_changed)
	_simulation.egg_laid_detailed.connect(_on_egg_laid)
	_simulation.announcement_posted.connect(_on_announcement_posted)
	_simulation.feed_party_funded.connect(_on_feed_party_funded)
	_simulation.workday_completed.connect(_on_workday_completed)
	_simulation.upgrade_purchased.connect(_on_upgrade_purchased)
	_simulation.decision_requested.connect(_on_decision_requested)
	_simulation.decision_resolved.connect(_on_decision_resolved)

	_clock.set_speed(0)
	_on_snapshot_changed(_simulation.snapshot())
	if _should_bypass_campaign_title():
		_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
		_on_announcement_posted("MORNING BRIEFING: choose the policy that will govern today's clutch.")
		_simulation.announce_pending_decision()
	else:
		_campaign_review_stage = &"title"
		_show_campaign_title(_campaign_store.has_save())
		_set_campaign_modal_open(true)
		_on_announcement_posted("PROBATION INTAKE OPEN. Begin a new five-shift file or continue a saved one.")
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


func _ensure_peck_assist_input_action() -> void:
	if InputMap.has_action(PECK_ASSIST_ACTION):
		return
	InputMap.add_action(PECK_ASSIST_ACTION, 0.5)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_E
	InputMap.action_add_event(PECK_ASSIST_ACTION, key_event)
	var joy_event := InputEventJoypadButton.new()
	joy_event.button_index = JOY_BUTTON_A
	InputMap.action_add_event(PECK_ASSIST_ACTION, joy_event)


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed(PECK_ASSIST_ACTION)
		and not (event is InputEventKey and event.echo)
	):
		if not _peck_assist_input_blocked():
			_request_peck_assist_from_input()
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
		if _day_review_scrim != null and _day_review_scrim.visible:
			get_viewport().set_input_as_handled()
			return
		match event.keycode:
			KEY_SPACE:
				_on_pause_requested()
			KEY_1:
				_on_speed_button_pressed(1)
			KEY_2:
				_on_speed_button_pressed(2)
			KEY_3:
				_on_speed_button_pressed(3)
			KEY_P:
				_on_feed_pressed()
			KEY_O:
				_on_overtime_pressed()
			KEY_V:
				_on_flockwatch_pressed()
			KEY_F:
				_trigger_predator_debug_encounter()


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
	_office_sun.directional_shadow_max_distance = 48.0
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
		fill.light_energy = 0.24
		fill.light_specular = 0.25
		fill.omni_range = 5.6
		fill.omni_attenuation = 1.45
		fill.shadow_enabled = false
		add_child(fill)
		_office_fill_lights.append(fill)

	_management_camera = Camera3D.new()
	_management_camera.name = "ManagementCamera"
	_management_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_management_camera.size = 20.6
	_management_camera.position = Vector3(16.5, 17.5, 21.5)
	_management_camera.near = 0.2
	_management_camera.far = 65.0
	_management_camera.current = true
	add_child(_management_camera)
	_management_camera.look_at(Vector3(-0.8, 0.65, 0.0))


func _build_office() -> void:
	var shell := Node3D.new()
	shell.name = "OfficeShell"
	add_child(shell)
	_add_box(shell, "Carpet", Vector3(OFFICE_WIDTH, 0.18, OFFICE_DEPTH), Vector3(0.0, -0.11, 0.0), Color("303e44"))
	_add_box(shell, "BackWall", Vector3(OFFICE_WIDTH, 3.65, 0.2), Vector3(0.0, 1.77, -8.9), Color("d0c9b5"))
	_add_box(shell, "LeftWall", Vector3(0.2, 3.65, OFFICE_DEPTH), Vector3(-11.9, 1.77, 0.0), Color("c2bcaa"))
	_add_box(shell, "BaseboardBack", Vector3(23.5, 0.15, 0.12), Vector3(0.0, 0.16, -8.76), Color("48545a"))
	_add_box(shell, "BaseboardLeft", Vector3(0.12, 0.15, 17.5), Vector3(-11.76, 0.16, 0.0), Color("48545a"))
	_add_box(shell, "ExecutiveStrip", Vector3(23.5, 0.09, 0.16), Vector3(0.0, 2.7, -8.74), Color("765540"))
	_add_box(shell, "MainAisleRunner", Vector3(22.6, 0.026, 1.65), Vector3(0.0, 0.005, MAIN_AISLE_Z), Color("465b62"))
	for lane_x in [-7.95, -1.95, 4.05]:
		_add_box(shell, "AccessLane", Vector3(1.3, 0.018, 11.2), Vector3(lane_x, 0.008, 0.55), Color("374b51"))

	for window_x in [-9.1, -5.45, -1.8, 1.85, 5.5, 9.15]:
		var window_key := int(round((window_x + 12.0) * 10.0))
		_add_box(shell, "Window", Vector3(2.75, 1.38, 0.045), Vector3(window_x, 1.83, -8.76), Color("4d7180"))
		_add_box(shell, "WindowTopFrame", Vector3(2.9, 0.075, 0.075), Vector3(window_x, 2.56, -8.70), Color("34464e"))
		_add_box(shell, "WindowSill", Vector3(2.9, 0.075, 0.18), Vector3(window_x, 1.10, -8.67), Color("e0dac6"))
		_add_box(shell, "WindowFrameL", Vector3(0.075, 1.46, 0.085), Vector3(window_x - 1.41, 1.83, -8.70), Color("34464e"))
		_add_box(shell, "WindowFrameR", Vector3(0.075, 1.46, 0.085), Vector3(window_x + 1.41, 1.83, -8.70), Color("34464e"))
		_add_box(shell, "WindowMullion_%d" % window_key, Vector3(0.065, 1.30, 0.075), Vector3(window_x, 1.83, -8.68), Color("34464e"))
		_add_box(shell, "BlindValance", Vector3(2.62, 0.13, 0.12), Vector3(window_x, 2.43, -8.62), Color("c0bba9"))
		for blind_y in [2.18, 1.92]:
			_add_box(shell, "BlindSlat", Vector3(2.55, 0.045, 0.075), Vector3(window_x, blind_y, -8.63), Color("b7b5aa"))
		_add_box(shell, "Radiator_%d" % window_key, Vector3(2.25, 0.53, 0.24), Vector3(window_x, 0.59, -8.54), Color("707b7e"))
		for fin_x in [-0.72, -0.36, 0.0, 0.36, 0.72]:
			_add_box(shell, "RadiatorFin", Vector3(0.075, 0.40, 0.055), Vector3(window_x + fin_x, 0.59, -8.39), Color("aab2ae"))

	_build_architecture_detail(shell)
	_build_office_decor(shell)
	_build_window_farm_view(shell)
	_build_floor_story(shell)
	_build_wall_story(shell)
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
	add_child(intake)
	_add_box(intake, "IntakeCounter", Vector3(2.25, 1.0, 2.2), Vector3(9.55, 0.5, 5.35), Color("735f4d"))
	_add_box(intake, "IntakeTop", Vector3(2.45, 0.14, 2.4), Vector3(9.55, 1.05, 5.35), Color("a58b69"))
	_build_intake_detail(intake)
	var basket := Node3D.new()
	basket.name = "ExecutiveEggBasket"
	add_child(basket)
	_add_box(basket, "BasketInterior", Vector3(2.02, 0.42, 1.48), Vector3(9.4, 0.32, -6.85), Color("694833"))
	_add_box(basket, "PresentationPlinth", Vector3(2.7, 0.18, 2.1), Vector3(9.4, 0.10, -6.85), Color("c3ab82"))
	var credit_slip_host := _build_presentation_detail(basket)
	EnvironmentalSignageScript.add_panel(
		credit_slip_host, "PresentationPlaqueText", "FARMER'S CREDIT",
		Vector3(0.0, 0.06, 0.057), Vector2(1.08, 0.24),
		Color("a87849"), Color("49372a"), Vector3.ZERO,
		15, 0.0028, &"utility", &"stencil"
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
	_camera_controller.configure(_management_camera, _worker_views, Vector3(-0.8, 0.65, 0.0))
	_camera_controller.focus_changed.connect(_on_camera_focus_changed)


static func desk_position(index: int) -> Vector3:
	var row := int(index / 3)
	var column := index % 3
	return Vector3(float(DESK_COLUMNS[column]), 0.0, float(DESK_ROWS[row]))


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
	var side_z := -0.97 if index < 3 else 0.98
	var local_socket := Vector3([-1.08, 0.0, 1.08][column], 0.0, side_z)
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


func _build_architecture_detail(parent: Node3D) -> void:
	_add_box(parent, "CrownMoldingBack", Vector3(23.55, 0.13, 0.16), Vector3(0.0, 3.48, -8.72), Color("e4deca"))
	_add_box(parent, "CrownMoldingLeft", Vector3(0.16, 0.13, 17.55), Vector3(-11.72, 3.48, 0.0), Color("ddd6c3"))
	_add_box(parent, "CableChannelBack", Vector3(23.1, 0.16, 0.13), Vector3(0.0, 0.36, -8.69), Color("657176"))

	# Wall-mounted light boxes add warm depth without floating over or obscuring workers.
	for light_index in 3:
		var light_x: float = [-7.6, 0.0, 7.6][light_index]
		var light_y := 3.44 if light_index == 1 else 3.20
		var fixture_width := 1.75 if light_index == 1 else 3.25
		var lens_width := 1.48 if light_index == 1 else 2.92
		_add_box(parent, "WallLightFrame", Vector3(fixture_width, 0.20, 0.16), Vector3(light_x, light_y, -8.63), Color("425057"))
		var lens := _add_box(parent, "WallLightLens_%d" % light_index, Vector3(lens_width, 0.08, 0.08), Vector3(light_x, light_y - 0.01, -8.53), Color("f4dfaa"))
		lens.material_override = _emissive_material(Color("f4dfaa"), 0.55)
		if light_index == 1:
			# The compact center fixture is a deliberate picture light clamped to
			# the bureau fascia, not another floating strip crossing its copy.
			for arm_x in [-0.58, 0.58]:
				var arm_name := "IdentityLightArmLeft" if arm_x < 0.0 else "IdentityLightArmRight"
				_add_box(parent, arm_name, Vector3(0.055, 0.20, 0.055), Vector3(arm_x, 3.36, -8.60), Color("6d6757"))

	EnvironmentalSignageScript.add_architectural_identity(
		parent,
		"BureauIdentity",
		"EGG YIELD BUREAU",
		"LAYING & CREDIT HARVEST",
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
	_add_box(parent, "IntakeFrontInset", Vector3(1.75, 0.58, 0.06), Vector3(9.55, 0.52, 6.48), Color("4b4037"))
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
		parent, "WellnessZoneLabel", "WELLNESS ROOST\nBreak room · 7 min.",
		Vector3(-11.798, 1.78, -3.10), Vector2(1.52, 0.52),
		Color("536c64"), Color("eee4c9"), Vector3(0.0, 90.0, 0.0),
		15, 0.0042, &"utility", &"room"
	)

	# A wall-mounted visibility board gives the cutaway side of the room a
	# detailed focal point while keeping the wellness/feed floor completely open.
	_add_box(parent, "ClaimsPipelineBoard", Vector3(0.075, 1.65, 3.30), Vector3(-11.70, 2.05, 3.60), Color("2b3a3f"))
	_add_box(parent, "ClaimsPipelineInset", Vector3(0.040, 1.38, 3.02), Vector3(-11.64, 2.03, 3.60), Color("d4ceb9"))
	var pipeline_heights: Array[float] = [0.38, 0.70, 0.50, 0.92, 0.62, 1.08]
	var pipeline_colors: Array[Color] = [Color("477681"), Color("6f8a72"), Color("c39a4c")]
	for bar_index in 6:
		var bar_height: float = pipeline_heights[bar_index]
		var bar_color: Color = pipeline_colors[bar_index % pipeline_colors.size()]
		_add_box(
			parent,
			"ClaimsPipelineBar",
			Vector3(0.035, bar_height, 0.25),
			Vector3(-11.60, 1.45 + bar_height * 0.5, 2.72 + bar_index * 0.35),
			bar_color
		)
	EnvironmentalSignageScript.add_panel(
		parent, "ClaimsPipelineLabel", "YIELD PIPELINE",
		Vector3(-11.615, 2.63, 3.60), Vector2(2.20, 0.36),
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
		_add_box(parent, "FileCabinet", Vector3(0.95, 1.75, 0.78), Vector3(cabinet_x, 0.88, -8.25), Color("647078"))
		for drawer_y in [0.38, 0.78, 1.18]:
			var handle := _add_box(parent, "DrawerHandle", Vector3(0.3, 0.045, 0.065), Vector3(cabinet_x, drawer_y, -7.84), Color("c1c8c4"))
			handle.material_override = _material(Color("c1c8c4"), 0.30, 0.58)
			_add_box(parent, "DrawerLabel", Vector3(0.34, 0.12, 0.035), Vector3(cabinet_x, drawer_y + 0.13, -7.82), Color("d8d2bd"))
		_add_box(parent, "ArchiveBox", Vector3(0.78, 0.48, 0.66), Vector3(cabinet_x, 2.00, -8.23), Color("b99a6d"))
		_add_box(parent, "ArchiveBoxLabel", Vector3(0.34, 0.14, 0.035), Vector3(cabinet_x, 2.00, -7.88), Color("e1dac5"))
	for plant_x in [-11.0, 10.7]:
		_add_cylinder(parent, "PlantPot", Vector3(plant_x, 0.30, -7.05), 0.32, 0.6, Color("80513e"))
		_add_cylinder(parent, "PlantStem", Vector3(plant_x, 0.88, -7.05), 0.065, 0.92, Color("355b45"))
		for leaf_index in 5:
			var angle := TAU * leaf_index / 5.0
			var leaf_color := Color("466b51") if leaf_index % 2 == 0 else Color("58785b")
			var leaf := _add_sphere(parent, "PlantLeaf", Vector3(plant_x + cos(angle) * 0.24, 0.94 + (leaf_index % 2) * 0.18, -7.05 + sin(angle) * 0.24), Vector3(0.22, 0.5, 0.16), leaf_color)
			leaf.rotation_degrees.y = rad_to_deg(angle)

	_add_box(parent, "ExtinguisherBracket", Vector3(0.52, 0.14, 0.09), Vector3(6.95, 1.08, -8.55), Color("454c4e"))
	_add_cylinder(parent, "SafetyExtinguisher", Vector3(6.95, 1.15, -8.43), 0.20, 0.72, Color("a3473b"))
	_add_box(parent, "ExtinguisherNozzle", Vector3(0.30, 0.11, 0.12), Vector3(7.15, 1.46, -8.42), Color("282f31"))


func _build_window_farm_view(parent: Node3D) -> void:
	# A continuous low-poly pasture beyond the opaque office glazing. Everything is
	# a paper-thin, non-colliding silhouette behind the mullions, so it adds depth
	# without adding route obstacles or expensive scene geometry.
	for window_index in 6:
		var window_x: float = [-9.1, -5.45, -1.8, 1.85, 5.5, 9.15][window_index]
		var pasture := _add_box(parent, "WindowPasture_%d" % window_index, Vector3(2.52, 0.43, 0.022), Vector3(window_x, 1.34, -8.665), Color("668268"))
		pasture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var hill := _add_sphere(parent, "WindowHill_%d" % window_index, Vector3(window_x - 0.48 + (window_index % 2) * 0.75, 1.63, -8.67), Vector3(1.60, 0.48, 0.04), Color("58745e"))
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for fence_post in 3:
			var post_x := window_x - 0.78 + fence_post * 0.78
			_add_box(parent, "PastureFencePost_%d_%d" % [window_index, fence_post], Vector3(0.045, 0.42, 0.028), Vector3(post_x, 1.38, -8.635), Color("dccb9e")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add_box(parent, "PastureFenceRail_%d_Low" % window_index, Vector3(2.18, 0.045, 0.028), Vector3(window_x, 1.34, -8.63), Color("dccb9e")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add_box(parent, "PastureFenceRail_%d_High" % window_index, Vector3(2.18, 0.045, 0.028), Vector3(window_x, 1.52, -8.63), Color("dccb9e")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Repeated windows read as one farm campus through a few landmark silhouettes.
	_add_box(parent, "DistantBarn", Vector3(1.05, 0.55, 0.035), Vector3(-5.45, 1.58, -8.61), Color("8e4f43")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var barn_roof := _add_box(parent, "DistantBarnRoof", Vector3(1.16, 0.16, 0.04), Vector3(-5.45, 1.89, -8.60), Color("493e38"))
	barn_roof.rotation_degrees.z = 8.0
	barn_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_cylinder(parent, "DistantSilo", Vector3(5.18, 1.62, -8.61), 0.23, 0.82, Color("9ca4a0")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_floor_story(parent: Node3D) -> void:
	# Subtle wear, feed kernels, and directional chevrons make the floor feel used.
	# At 2 cm or less, these remain visual decals and cannot affect navigation.
	for lane_index in 3:
		var lane_x: float = [-7.95, -1.95, 4.05][lane_index]
		for mark_index in 3:
			var mark_z := -3.6 + mark_index * 3.7
			var scuff := _add_box(parent, "PeckLaneScuff_%d_%d" % [lane_index, mark_index], Vector3(0.72, 0.008, 0.24), Vector3(lane_x, 0.022, mark_z), Color(0.28, 0.37, 0.38, 0.75))
			scuff.rotation_degrees.y = -12.0 + lane_index * 8.0
			scuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for chevron_side in [-1.0, 1.0]:
			var chevron := _add_box(parent, "PeckFlowChevron_%d_%d" % [lane_index, int(chevron_side)], Vector3(0.32, 0.010, 0.075), Vector3(lane_x + chevron_side * 0.11, 0.026, 5.68), Color("c59a4d"))
			chevron.rotation_degrees.y = chevron_side * 34.0
			chevron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	for kernel_index in 12:
		var kernel_x := -11.05 + (kernel_index % 4) * 0.22
		var kernel_z := -1.02 + int(kernel_index / 4) * 0.24
		var kernel := _add_sphere(parent, "StrayFeedKernel_%d" % kernel_index, Vector3(kernel_x, 0.045, kernel_z), Vector3(0.055, 0.025, 0.085), Color("d0a84f"))
		kernel.rotation_degrees.y = kernel_index * 31.0
		kernel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_wall_story(parent: Node3D) -> void:
	# Farm-bureau propaganda occupies the unused left-wall strips and stays clear of
	# the wellness zone, pipeline board, and every circulation lane.
	_add_box(parent, "HenOfMonthFrame", Vector3(0.055, 1.56, 1.75), Vector3(-11.68, 2.05, -5.55), Color("584b3c"))
	_add_box(parent, "HenOfMonthCard", Vector3(0.035, 1.35, 1.54), Vector3(-11.63, 2.05, -5.55), Color("e4dcc4"))
	var portrait := _add_sphere(parent, "HenOfMonthPortrait", Vector3(-11.59, 2.08, -5.55), Vector3(0.04, 0.43, 0.43), Color("d79b63"))
	portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	EnvironmentalSignageScript.add_panel(
		parent, "HenOfMonthLabel", "HEN OF THE MONTH",
		Vector3(-11.615, 2.58, -5.55), Vector2(1.48, 0.34),
		Color("e4dcc4"), Color("514135"), Vector3(0.0, 90.0, 0.0),
		18, 0.0068, &"secondary", &"portrait"
	)

	var safety_label := EnvironmentalSignageScript.add_panel(
		parent, "CoopSafetyLabel", "AISLE SAFETY\nKeep wings tucked",
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
	var nameplate := EnvironmentalSignageScript.add_panel(
		workstation, "EmployeeNameplateText", "VACANT PERCH\nAUTHORIZED POSITION",
		Vector3(-0.82, 1.32, 0.79), Vector2(0.56, 0.21),
		Color("c9c5b5"), Color("334742"), Vector3.ZERO,
		14, 0.0034, &"utility", &"partition"
	)
	_workstation_nameplates[index] = nameplate
	var nameplate_fixture := nameplate.get_parent() as Node3D
	_add_box(
		nameplate_fixture,
		"NameplateAccentStripe",
		Vector3(0.022, 0.10, 0.002),
		Vector3(0.238, 0.0, 0.013),
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
			marker.visible = not active
	_displayed_office_capacity = capacity
	if _office_storytelling != null and previous_capacity != capacity:
		# Rebuilding from the active prefix visually extends the collection rail as
		# each capacity requisition is approved; hidden desks never leave floating
		# trays behind.
		_office_storytelling.configure(
			_active_desk_positions(capacity),
			Vector3(9.55, 0.0, 5.35),
			Vector3(9.4, 0.0, -6.85),
		)


func _refresh_workstation_nameplates(snapshot: Dictionary) -> void:
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
		if worker_view != null and is_instance_valid(worker_view):
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
	_simulation.set_worker_at_workstation(worker_id, false)
	if _camera_controller != null:
		_camera_controller.unregister_worker(worker_id)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "ManagementInterface"
	add_child(ui)
	_ui_root = Control.new()
	_ui_root.name = "ManagementUIRoot"
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.theme = ManagementUIThemeScript.create_theme()
	ui.add_child(_ui_root)

	var top_panel := PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_bottom = 112.0
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color("1c2633"), 0.94, 0, 0))
	_ui_root.add_child(top_panel)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 22)
	top_margin.add_theme_constant_override("margin_right", 22)
	top_margin.add_theme_constant_override("margin_top", 9)
	top_margin.add_theme_constant_override("margin_bottom", 9)
	top_panel.add_child(top_margin)
	var top_stack := VBoxContainer.new()
	top_stack.add_theme_constant_override("separation", 7)
	top_margin.add_child(top_stack)
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	top_stack.add_child(top_bar)
	var title := _make_label("PECKING ORDER  //  EGG YIELD BUREAU", 20, Color("f4d27b"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	_day_label = _make_label("DAY 1", 16)
	_time_label = _make_label("8:00 AM", 16)
	_revenue_label = _make_label("FEED FUND $50.00", 16, Color("9dd9a4"))
	top_bar.add_child(_day_label)
	top_bar.add_child(_time_label)
	top_bar.add_child(_revenue_label)

	for index in 4:
		var button := Button.new()
		button.text = ["PAUSE", "1×", "3×", "10×"][index]
		button.name = "SpeedButton_%d" % index
		button.theme_type_variation = &"SpeedButton"
		button.custom_minimum_size = Vector2(60.0, 36.0)
		button.tooltip_text = ["Pause simulation", "Normal speed", "Fast speed", "Ultra speed"][index]
		button.pressed.connect(_on_speed_button_pressed.bind(index))
		top_bar.add_child(button)
		_speed_buttons.append(button)

	var objective_row := HBoxContainer.new()
	objective_row.name = "ShiftObjectiveRow"
	objective_row.add_theme_constant_override("separation", 12)
	top_stack.add_child(objective_row)
	objective_row.add_child(_make_label("SHIFT CLUTCH", 13, Color("d9c47d")))
	_quota_progress = ProgressBar.new()
	_quota_progress.name = "ShiftQuotaProgress"
	_quota_progress.custom_minimum_size = Vector2(240.0, 24.0)
	_quota_progress.show_percentage = false
	objective_row.add_child(_quota_progress)
	_quota_progress_label = _make_label("0 / 24", 14, Color("f3ead1"))
	_quota_progress_label.custom_minimum_size.x = 62.0
	objective_row.add_child(_quota_progress_label)
	_quality_streak_label = _make_label("CLEAN CLUTCH  ×0", 14, Color("9ccfc2"))
	_quality_streak_label.custom_minimum_size.x = 154.0
	objective_row.add_child(_quality_streak_label)
	_directive_badge = _make_label("POLICY  ·  UNSET", 13, Color("efb96d"))
	_directive_badge.custom_minimum_size.x = 180.0
	_directive_badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_row.add_child(_directive_badge)
	_guidance_label = _make_label("START HERE: choose 1× when the flock is seated.", 13, Color("b8c3cc"))
	_guidance_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_guidance_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_row.add_child(_guidance_label)

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
	_flockwatch_panel.offset_left = -300.0
	_flockwatch_panel.offset_top = 172.0
	_flockwatch_panel.offset_right = -18.0
	_flockwatch_panel.offset_bottom = -70.0
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
	side.add_theme_constant_override("separation", 8)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_scroll.add_child(side)
	side.add_child(_make_label("FLOCKWATCH LEDGER", 18, Color("f4d27b")))
	side.add_child(HSeparator.new())
	_campaign_orders_heading_label = _make_label("TODAY'S PROBATION ORDERS", 17, Color("73b5a7"))
	_campaign_orders_heading_label.name = "CampaignOrdersHeading"
	side.add_child(_campaign_orders_heading_label)
	_campaign_objectives_label = _make_label("Day 1 orders are being stamped.", 13, Color("d7e5df"))
	_campaign_objectives_label.name = "CampaignObjectivesLabel"
	_campaign_objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_campaign_objectives_label)
	_flock_labor_label = _make_label("FLOCK VOICE  ·  No binding compact is currently filed.", 13, Color("b9c8cc"))
	_flock_labor_label.name = "FlockLaborStatus"
	_flock_labor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_flock_labor_label.tooltip_text = "Named petitions can become next-shift compacts or trigger work-to-rule."
	side.add_child(_flock_labor_label)
	side.add_child(HSeparator.new())
	_pecking_order_ui = PeckingOrderUIScript.new()
	_pecking_order_ui.worker_selected.connect(_on_pecking_order_worker_selected)
	side.add_child(_pecking_order_ui)
	side.add_child(HSeparator.new())
	_staffing_ui = RoostStaffingUIScript.new() as RoostStaffingUI
	_staffing_ui.capacity_purchase_requested.connect(_on_staff_capacity_purchase_requested)
	_staffing_ui.hire_requested.connect(_on_staff_hire_requested)
	_staffing_ui.release_requested.connect(_on_staff_release_requested)
	side.add_child(_staffing_ui)
	side.add_child(HSeparator.new())
	side.add_child(_make_label("COOP REQUISITIONS", 17, Color("f4d27b")))
	for upgrade in _simulation.upgrade_catalog():
		var upgrade_id := StringName(upgrade["id"])
		var upgrade_button := Button.new()
		upgrade_button.name = "Upgrade_%s" % String(upgrade_id)
		upgrade_button.theme_type_variation = &"UpgradeButton"
		upgrade_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		upgrade_button.custom_minimum_size.y = 52.0
		upgrade_button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
		side.add_child(upgrade_button)
		_upgrade_buttons[upgrade_id] = upgrade_button
	_continue_shift_button = Button.new()
	_continue_shift_button.name = "ContinueDirectiveButton"
	_continue_shift_button.text = "CONTINUE: CHOOSE MORNING POLICY"
	_continue_shift_button.theme_type_variation = &"PrimaryButton"
	_continue_shift_button.custom_minimum_size.y = 44.0
	_continue_shift_button.visible = false
	_continue_shift_button.pressed.connect(_on_continue_directive_pressed)
	side.add_child(_continue_shift_button)
	side.add_child(HSeparator.new())
	_claims_label = _make_label("Peckwork queued: 0", 15)
	_egg_label = _make_label("Eggs gathered: 0", 15)
	_quota_label = _make_label("Daily clutch: 0 / 0", 15)
	_confidence_label = _make_label("Farmer favor: 0%", 15)
	_morale_label = _make_label("Flock spirits: 0%", 15)
	_compliance_label = _make_label("Coop obedience: 0%", 15)
	_solidarity_label = _make_label("Flock unity risk: 0%", 15)
	for label in [_claims_label, _egg_label, _quota_label, _confidence_label, _morale_label, _compliance_label, _solidarity_label]:
		side.add_child(label)
	side.add_child(HSeparator.new())
	var initiatives := _make_label("ROOSTER DIRECTIVES", 17, Color("efb96d"))
	side.add_child(initiatives)
	_feed_button = Button.new()
	_feed_button.name = "FeedPartyButton"
	_feed_button.theme_type_variation = &"PrimaryButton"
	_feed_button.text = "FUND FEED PARTY  ($20)  [P]"
	_feed_button.tooltip_text = "Once per shift: +10 morale, -8 stress, +2 farmer favor. Production pauses for attendance."
	_feed_button.custom_minimum_size.y = 42.0
	_feed_button.pressed.connect(_on_feed_pressed)
	side.add_child(_feed_button)
	_overtime_button = Button.new()
	_overtime_button.text = "ENABLE AFTER-HOURS PECKING  [O]"
	_overtime_button.tooltip_text = "+22% output; sharply increases fatigue, stress, morale loss, and crack risk. Resets next shift."
	_overtime_button.custom_minimum_size.y = 42.0
	_overtime_button.theme_type_variation = &"DangerButton"
	_overtime_button.toggle_mode = true
	_overtime_button.pressed.connect(_on_overtime_pressed)
	side.add_child(_overtime_button)
	var note := _make_label("TIP: Click a hen to inspect. Tab cycles; Esc returns.\nOne flock check-in is available each shift.\nThe farmer counts the clutch at 5:00 PM.", 13, Color("aeb8c4"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(note)
	_set_flockwatch_open(false)

	var ticker_panel := PanelContainer.new()
	ticker_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ticker_panel.offset_top = -54.0
	ticker_panel.add_theme_stylebox_override("panel", _panel_style(Color("523c2e"), 0.98, 0, 0))
	_ui_root.add_child(ticker_panel)
	_ticker_label = _make_label("", 17, Color("fff0ca"))
	_ticker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ticker_panel.add_child(_ticker_label)
	_routing_ui = PeckworkRoutingUIScript.new() as PeckworkRoutingUI
	_routing_ui.assignment_requested.connect(_on_worker_assignment_requested)
	_routing_ui.personnel_action_requested.connect(_on_personnel_action_requested)
	_routing_ui.peck_assist_requested.connect(_on_peck_assist_requested)
	_routing_ui.first_clutch_skip_requested.connect(_on_first_clutch_skip_requested)
	_routing_ui.first_clutch_focus_requested.connect(_on_first_clutch_focus_requested)
	_ui_root.add_child(_routing_ui)
	_build_day_review_panel()
	_build_decision_modal()
	_campaign_ui = ProbationCampaignUIScript.new() as ProbationCampaignUI
	_campaign_ui.continue_campaign.connect(_on_campaign_continue_requested)
	_campaign_ui.new_campaign.connect(_on_campaign_new_requested)
	_campaign_ui.abandon_campaign.connect(_on_campaign_abandon_requested)
	_campaign_ui.milestone_choice.connect(_on_campaign_milestone_requested)
	_campaign_ui.career_sponsorship_requested.connect(_on_career_sponsorship_requested)
	_ui_root.add_child(_campaign_ui)


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
	_day_review_panel.offset_left = -330.0
	_day_review_panel.offset_top = -230.0
	_day_review_panel.offset_right = 330.0
	_day_review_panel.offset_bottom = 230.0
	_day_review_panel.add_theme_stylebox_override("panel", _panel_style(Color("17232d"), 0.985, 14, 2))
	_day_review_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_day_review_scrim.add_child(_day_review_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_day_review_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	_review_title = _make_label("FARMER REVIEW", 26, Color("f4d27b"))
	_review_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_review_title)
	content.add_child(HSeparator.new())
	_review_results = _make_label("", 18, Color("e7edf0"))
	_review_results.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_review_results)
	_review_story = _make_label("", 16, Color("b8c6cb"))
	_review_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_review_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_review_story.custom_minimum_size.y = 82.0
	content.add_child(_review_story)
	var hint := _make_label("Invest the Feed Fund now, or bank it for a stronger requisition later.", 14, Color("d5bd78"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)
	var requisitions := Button.new()
	requisitions.name = "ReviewRequisitionsButton"
	requisitions.text = "OPEN REQUISITIONS"
	requisitions.custom_minimum_size = Vector2(210.0, 48.0)
	requisitions.pressed.connect(_on_review_requisitions_pressed)
	buttons.add_child(requisitions)
	_begin_next_shift_button = Button.new()
	_begin_next_shift_button.name = "BeginNextShiftButton"
	_begin_next_shift_button.text = "PLAN NEXT SHIFT"
	_begin_next_shift_button.theme_type_variation = &"PrimaryButton"
	_begin_next_shift_button.custom_minimum_size = Vector2(210.0, 48.0)
	_begin_next_shift_button.pressed.connect(_on_begin_next_shift_pressed)
	buttons.add_child(_begin_next_shift_button)


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
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	decision_scroll.add_child(center)

	_decision_panel = PanelContainer.new()
	_decision_panel.name = "ManagementDecisionCard"
	_decision_panel.custom_minimum_size = Vector2(760.0, 0.0)
	_decision_panel.add_theme_stylebox_override("panel", _panel_style(Color("172630"), 0.995, 16, 2))
	center.add_child(_decision_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_decision_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "DecisionContent"
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	_decision_eyebrow = _make_label("MANAGEMENT DECISION", 13, Color("d8b667"))
	_decision_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_decision_eyebrow)
	_decision_title = _make_label("CHOOSE A RESPONSE", 25, Color("f4e3ae"))
	_decision_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_decision_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_decision_title)
	_decision_body = _make_label("", 16, Color("c4d0d4"))
	_decision_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_decision_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_decision_body)
	content.add_child(HSeparator.new())
	_decision_options = VBoxContainer.new()
	_decision_options.name = "DecisionOptions"
	_decision_options.add_theme_constant_override("separation", 9)
	content.add_child(_decision_options)
	_decision_preview = _make_label("Select a policy card to review its consequences.", 14, Color("efcf83"))
	_decision_preview.name = "DecisionPreview"
	_decision_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_decision_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_decision_preview.custom_minimum_size.y = 42.0
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
	if kind == &"incident":
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
	if _camera_controller != null:
		_camera_controller.set_process_unhandled_input(false)
	if _routing_ui != null:
		_routing_ui.set_interaction_enabled(false)
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
		_decision_eyebrow.text = "%s'S FIRST FILE  //  FLOCK POLICY" % first_hen_name
		_decision_title.text = "CHOOSE THE RULE %s — AND EVERY HEN — WORKS UNDER" % first_hen_name
		_decision_body.text = (
			"%s's dossier is open behind this filing. One policy governs her desk and the whole flock today; "
			+ "its exact production, welfare, and shell consequences remain visible before authorization."
		) % first_hen_name.capitalize()
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
			"Choose one policy card. The full consequence is shown before authorization."
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
		var tagline := String(option.get("tagline", ""))
		var preview := String(option.get("preview", "Consequence pending."))
		var cost_cents := int(option.get("cost_cents", 0))
		var button := Button.new()
		button.name = "DecisionOption_%s" % String(option_id)
		button.theme_type_variation = &"DecisionChoiceButton"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = (
			82.0 if decision_category == &"flock_petition" else
			(62.0 if tagline.is_empty() else 72.0)
		)
		button.text = "%d  //  %s\n%s%s" % [
			option_index + 1,
			label,
			("%s\n" % tagline if not tagline.is_empty() else ""),
			preview,
		]
		button.set_meta("option_id", option_id)
		button.set_meta("preview", preview)
		button.set_meta("cost_cents", cost_cents)
		button.disabled = cost_cents > fund_cents
		if button.disabled:
			button.tooltip_text = "Requires $%.2f Feed Fund; only $%.2f is available." % [cost_cents / 100.0, fund_cents / 100.0]
		else:
			button.tooltip_text = "Select to preview, then authorize below."
		button.pressed.connect(_on_decision_option_pressed.bind(option_id))
		_decision_options.add_child(button)
		_decision_option_buttons.append(button)
		option_index += 1

	var is_directive := kind == &"directive"
	var allow_stay_paused := bool(decision.get("allow_stay_paused", kind == &"incident"))
	_decision_stay_paused_button.visible = allow_stay_paused
	_decision_stay_paused_button.disabled = true
	_decision_confirm_button.disabled = true
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
	_decision_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_decision_panel.scale = Vector2(0.96, 0.96)
	await get_tree().process_frame
	if not is_instance_valid(_decision_panel) or not _decision_host.visible:
		return
	_decision_panel.pivot_offset = _decision_panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_decision_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(_decision_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_update_guidance(_simulation.snapshot())


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
	if _audio_feedback != null:
		_audio_feedback.play_ui_tick()


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


func _on_decision_resolved(result: Dictionary) -> void:
	var kind := StringName(result.get("kind", &"incident"))
	_decision_host.visible = false
	_active_decision.clear()
	_selected_decision_option = &""
	if _camera_controller != null:
		_camera_controller.set_process_unhandled_input(true)
	if _routing_ui != null:
		_routing_ui.set_interaction_enabled(true)
	var outcome := String(result.get("outcome", "Management decision recorded."))
	_ticker_label.text = outcome
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


func _on_workday_completed(report: Dictionary) -> void:
	_clock.set_speed(0)
	_last_workday_report = report.duplicate(true)
	_first_clutch_prepare_for_shift_boundary()
	if _campaign_senior_roost and _senior_roost_state != null:
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
	var feed_cost := int(report.get("feed_cost_cents", 0))
	var completed_directive := report.get("directive", {}) as Dictionary
	var directive_name := String(completed_directive.get("short_name", "UNFILED"))
	var incident_count := int(report.get("incidents_resolved", 0))
	var lane_processed := report.get("lane_processed", {}) as Dictionary
	var overdue_files := int(report.get("overdue_claims", 0))
	var rework_files := int(report.get("rework_waiting", 0)) + int(report.get("rework_due_next_shift", 0))
	var personnel_action := report.get("personnel_action", {}) as Dictionary
	var closing_order := report.get("pecking_order", []) as Array
	var closing_leader: Dictionary = (
		closing_order[0] as Dictionary if not closing_order.is_empty() else {}
	)
	var personnel_line := "NOT FILED"
	if not personnel_action.is_empty():
		personnel_line = "%s / %s" % [
			String(personnel_action.get("worker_name", "HEN")).to_upper(),
			String(personnel_action.get("action_name", "CHECK-IN")).to_upper(),
		]
	_review_title.text = "CLOSING FILE 1 / 3  ·  DAY %d  ·  FARMER REVIEW" % int(report.get("day", 1))
	_review_results.text = "%s\n%d / %d eggs  ·  %d cracked  ·  %d golden\nPolicy: %s  ·  %d incident%s resolved\nCheck-in: %s  ·  avg trust %d  ·  avg grievance %d\nFiles: N%d  ·  P%d  ·  A%d  ·  %d overdue  ·  %d rework\nQuota bonus $%.2f  ·  Quality bonus $%.2f  ·  Daily feed -$%.2f" % [
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
		quota_bonus / 100.0, quality_bonus / 100.0, feed_cost / 100.0,
	]
	_review_results.tooltip_text = ""
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
		_review_results.tooltip_text = "\n".join(flock_ledger_details)
	_review_story.text = (
		"The farmer credits decisive leadership and announces tomorrow's improved target: %d eggs."
		if met_quota else
		"The farmer identifies a temporary flock-attitude variance. Tomorrow's adjusted target is %d eggs."
	) % int(report.get("next_quota", quota))
	if not personnel_action.is_empty():
		_review_story.text += "\nPersonnel ledger: %s" % String(personnel_action.get("outcome", "Check-in filed."))
	if not closing_leader.is_empty():
		_review_story.text += "\nPecking Order #1: %s  ·  %d eggs  ·  $%.2f credited." % [
			String(closing_leader.get("worker_name", "HEN")).to_upper(),
			int(closing_leader.get("eggs", 0)),
			float(int(closing_leader.get("credit_cents", 0))) / 100.0,
		]
	if _begin_next_shift_button != null:
		var memo_kind := StringName(report.get("credit_memo_kind", &""))
		var memo_id := StringName(report.get("credit_memo_id", &""))
		_begin_next_shift_button.text = (
			"OPEN RESTRUCTURING FILE"
			if memo_id == &"flock_restructuring" else
			("OPEN GOLDEN DOSSIER"
			if memo_id == &"golden_egg_dossier" else
			("ALLOCATE SHIFT CREDIT" if bool(report.get("credit_memo_required", false)) else "PLAN NEXT SHIFT")
			)
		)
	_day_review_scrim.visible = true
	if _camera_controller != null:
		_camera_controller.set_process_unhandled_input(false)
	if _routing_ui != null:
		_routing_ui.set_interaction_enabled(false)
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
	_day_review_scrim.visible = false
	if _camera_controller != null:
		_camera_controller.set_process_unhandled_input(true)
	if _routing_ui != null:
		_routing_ui.set_interaction_enabled(false)
	_set_flockwatch_open(true)
	_guidance_label.text = "REVIEW PAUSED: approve requisitions, then choose tomorrow's policy."
	_ticker_label.text = "Feed Fund purchases are permanent. Costs rise with each approved level."


func _on_begin_next_shift_pressed() -> void:
	_advance_from_farmer_review()


func _on_continue_directive_pressed() -> void:
	_advance_from_farmer_review()


func _advance_from_farmer_review() -> void:
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


func _on_worker_assignment_requested(worker_id: int, lane: StringName) -> void:
	if not _simulation.set_worker_assignment(worker_id, lane):
		_ticker_label.text = "ROUTING HELD. Finish the current management action before changing trays."
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


func _on_personnel_action_requested(worker_id: int, action_id: StringName) -> void:
	var result := _simulation.perform_personnel_action(worker_id, action_id)
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get("reason", "PERSONNEL ACTION HELD."))
		return
	var preferred_note := "  /  PROFILE MATCH" if bool(result.get("preferred", false)) else ""
	_ticker_label.text = "%s%s" % [String(result.get("outcome", "Personnel action filed.")), preferred_note]
	if _audio_feedback != null:
		_audio_feedback.play_decision_resolved()
	_first_clutch_record_checkin(worker_id)
	_save_campaign_checkpoint("personnel_action")


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
			_audio_feedback.play_ui_tick()
		return
	var worker_id := _routing_ui.focused_worker_id() if _routing_ui != null else -1
	if worker_id < 0 or not bool(_simulation.peck_assist_status(worker_id).get("available", false)):
		worker_id = _simulation.recommended_peck_assist_worker_id()
	if worker_id < 0:
		_ticker_label.text = "PRIORITY PECK: wait for a seated hen's claim meter to enter the gold window."
		if _audio_feedback != null:
			_audio_feedback.play_ui_tick()
		return
	if _camera_controller != null:
		_camera_controller.focus_worker(worker_id)
	_on_peck_assist_requested(worker_id)


func _on_peck_assist_requested(worker_id: int) -> void:
	if _clock.speed_index == 0:
		_ticker_label.text = "PRIORITY PECK HELD. Resume the live clock before stamping the rhythm."
		return
	var result := _simulation.perform_peck_assist(worker_id)
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get("reason", "PRIORITY PECK HELD."))
		if _audio_feedback != null:
			_audio_feedback.play_ui_tick()
		return
	var rating := StringName(result.get("rating", &"steady"))
	var worker_name := String(result.get("worker_name", "HEN")).to_upper()
	var progress_gain := int(roundf(float(result.get("progress_gain", 0.0))))
	var quality_points := absf(float(result.get("quality_modifier", 0.0))) * 100.0
	_ticker_label.text = "%s PECK  ·  %s +%d%% FILE  ·  shell risk %s%.1f%%  ·  chain x%d  ·  %d stamps left" % [
		String(rating).to_upper(), worker_name, progress_gain,
		("-" if float(result.get("quality_modifier", 0.0)) <= 0.0 else "+"), quality_points,
		int(result.get("streak", 0)), int(result.get("remaining", 0)),
	]
	var worker_view := _worker_views.get(worker_id) as ChickenView
	if worker_view != null and is_instance_valid(worker_view):
		worker_view.play_peck_assist_feedback(rating)
	_first_clutch_record_assist(result)
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


func _on_lay_release_reached(_worker_id: int) -> void:
	if _audio_feedback != null:
		_audio_feedback.play_lay_release(&"sound")


func _on_staff_capacity_purchase_requested() -> void:
	var result := _simulation.purchase_staff_capacity()
	_handle_staffing_action_result(result, &"capacity_expanded")


func _on_staff_hire_requested(worker_id: int) -> void:
	var result := _simulation.hire_worker(worker_id)
	_handle_staffing_action_result(result, &"worker_hired")


func _on_staff_release_requested(worker_id: int) -> void:
	var result := _simulation.release_worker(worker_id)
	_handle_staffing_action_result(result, &"worker_released")


func _handle_staffing_action_result(result: Dictionary, checkpoint_reason: StringName) -> void:
	if not bool(result.get("accepted", false)):
		_ticker_label.text = String(result.get("reason", "STAFFING FILE HELD FOR REVIEW."))
		if _audio_feedback != null:
			_audio_feedback.play_ui_tick()
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
			_camera_controller.show_event_focus(desk_position(capacity - 1) + Vector3.UP * 1.0, "ROOST EXPANDED", 1.15)
	_save_campaign_checkpoint(String(checkpoint_reason))


func _on_campaign_new_requested() -> void:
	_campaign_store.delete()
	_campaign_state = CampaignStateScript.new()
	_senior_roost_state = SeniorRoostStateScript.new()
	_campaign_review_stage = &"active"
	_campaign_senior_roost = false
	_last_workday_report.clear()
	var fresh_simulation := DepartmentSimulation.new(1701, INITIAL_CAMPAIGN_STAFF)
	if not _simulation.restore_save_state(fresh_simulation.export_save_state()):
		push_error("Could not reset the office simulation for a new probation file.")
		return
	_reset_first_clutch(true)
	_prime_first_hen_prelude()
	_reset_campaign_session_visuals()
	_campaign_ui.show_active_campaign(_campaign_presentation_snapshot(&"active"))
	_set_campaign_modal_open(false)
	_present_first_hen_prelude()
	_save_campaign_checkpoint("new_campaign")


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
			_begin_next_shift_from_campaign()
		ProbationCampaignUI.VIEW_FINAL:
			if _campaign_state.outcome == CampaignStateScript.OUTCOME_PASSED:
				_enter_senior_roost()


func _on_campaign_abandon_requested() -> void:
	_clock.set_speed(0)
	_campaign_store.delete()
	_campaign_review_stage = &"title"
	_campaign_senior_roost = false
	_senior_roost_state = SeniorRoostStateScript.new()
	_reset_first_clutch(false)
	_day_review_scrim.visible = false
	_decision_host.visible = false
	_set_flockwatch_open(false)
	_show_campaign_title(false)
	_set_campaign_modal_open(true)
	_ticker_label.text = "PROBATION FILE CLOSED. A clean five-shift file may be opened at any time."


func _on_campaign_milestone_requested(choice_id: StringName) -> void:
	if _campaign_senior_roost:
		if _senior_roost_state == null or not _senior_roost_state.requires_quarter_policy():
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
		return
	for unlock_value in _campaign_state.unlocked_feature_ids:
		_simulation.apply_campaign_unlock(StringName(unlock_value))
	_campaign_review_stage = &"probation"
	_campaign_ui.show_between_shift_report(_campaign_presentation_snapshot(&"between_shift"))
	_update_campaign_objectives_label()
	_save_campaign_checkpoint("milestone_selected")
	_ticker_label.text = "MILESTONE APPROVED: %s is now permanent for this probation file." % String(choice_id).replace("_", " ").to_upper()


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
	_ticker_label.text = "SENIOR ROOST OPEN. File a capital policy before beginning the first three-shift quarter."


func _continue_senior_roost_report() -> void:
	if _senior_roost_state == null or not _senior_roost_state.is_active():
		_ticker_label.text = "SENIOR ROOST HELD. No active career ledger is available."
		return
	match _senior_roost_state.status:
		SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
			_ticker_label.text = "CAPITAL POLICY REQUIRED. Choose one available tradeoff before opening the quarter."
			return
		SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
			var passed := bool(_senior_roost_state.last_annual_review.get("passed", false))
			var transition := _simulation.apply_senior_year_transition(passed)
			if not bool(transition.get("accepted", false)):
				_ticker_label.text = String(transition.get("reason", "ANNUAL TRANSITION HELD."))
				return
			if not _senior_roost_state.continue_after_annual():
				push_error("Senior annual review could not advance after an accepted transition.")
				return
			_show_senior_roost_report("senior_year_transition")
			_ticker_label.text = String(transition.get("outcome", "NEXT SENIOR YEAR OPEN."))
		SeniorRoostStateScript.STATUS_ACTIVE:
			_begin_next_shift_from_campaign()
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


func _show_campaign_final_review() -> void:
	_campaign_review_stage = &"final"
	_day_review_scrim.visible = false
	_set_flockwatch_open(false)
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
		milestone_cards.append({
			"id": String(milestone.get("id", "")),
			"title": String(milestone.get("title", "Milestone")),
			"description": String(milestone.get("description", "Permanent probation benefit.")),
			"effect": _milestone_effect_text(milestone.get("effects", {}) as Dictionary),
		})
	var final_evaluation := _campaign_state.final_evaluation()
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
		"credit_memo": _simulation.last_credit_allocation.duplicate(true),
		"score_receipt": score_receipt,
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
		policy_cards = _senior_roost_state.policy_catalog(_simulation.spendable_fund_cents())

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
			report_note = "Promotion unlocked. Senior quarters last three shifts; each begins with one irreversible capital policy."
		else:
			report_note = "Quarter %d closed at %d / 100 and awarded +%d Roost Mark%s. File the next tradeoff; one optional Career Sponsorship may invest banked marks below." % [
				int(quarter_review.get("quarter_number", 0)),
				int(quarter_review.get("score", 0)),
				int(quarter_review.get("marks_awarded", 0)),
				"" if int(quarter_review.get("marks_awarded", 0)) == 1 else "s",
			]
	elif status_id == SeniorRoostStateScript.STATUS_ANNUAL_REVIEW:
		var annual_passed := bool(annual_review.get("passed", false))
		report_heading = "YEAR %d ANNUAL ROOST REVIEW" % year_number
		report_note = "%s  Annual score %d / 100 · welfare %d%% · obedience %d%% · farmer favor %d%% · shell cracks %.1f%%." % [
			"SAFEGUARDS PASSED." if annual_passed else "PERFORMANCE IMPROVEMENT YEAR REQUIRED.",
			int(annual_review.get("score", 0)),
			int(annual_review.get("welfare", 0)),
			int(annual_review.get("compliance", 0)),
			int(annual_review.get("farmer_favor", 0)),
			float(int(annual_review.get("crack_rate_basis_points", 0))) / 100.0,
		]
		report_note += " One optional Career Sponsorship remains available before Year %d planning." % (year_number + 1)
		continue_label = "BEGIN YEAR %d PLANNING  [C]" % (year_number + 1)
		continue_tooltip = (
			"Accept the annual review. Next year's baseline quota rises by one egg."
			if annual_passed else
			"Accept the improvement year. Baseline quota rises by two and farmer favor falls by five."
		)
		objective = {
			"title": "YEAR %d %s" % [year_number, "PASSED" if annual_passed else "HELD"],
			"description": (
				"The career continues with a one-egg baseline increase."
				if annual_passed else
				"The career continues under a two-egg quota increase and reduced farmer favor."
			),
			"reward": "+3 annual Roost Marks" if annual_passed else "No annual bonus marks",
		}
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
				"reward": "Quarter score 60+ earns promotion progress.",
			}

	var policy_receipt: Dictionary = {}
	if status_id == SeniorRoostStateScript.STATUS_ACTIVE and not _senior_roost_state.active_policy_receipt.is_empty():
		policy_receipt = _senior_roost_state.active_policy_receipt.duplicate(true)
		policy_receipt["day"] = display_shift
		policy_receipt["decision_id"] = "senior_quarter_policy"
		policy_receipt["option_id"] = String(_senior_roost_state.active_policy_id)

	var hen_highlight: Dictionary = {}
	if _senior_roost_state.total_senior_shifts > 0:
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
	var ledgers: Array[Dictionary] = [
		{
			"label": "Roost Marks",
			"value": _senior_roost_state.roost_marks,
			"detail": "%d AVAILABLE  ·  %d INVESTED" % [available_roost_marks, invested_roost_marks],
		},
		{
			"label": "Quarter score",
			"value": last_quarter_score,
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
		ledgers[1] = {
			"label": "Annual score",
			"value": int(annual_review.get("score", 0)),
			"detail": "PASSED" if bool(annual_review.get("passed", false)) else "IMPROVEMENT YEAR",
		}
		ledgers[2] = {
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
			("Y%d · Q%d · POLICY" % [year_number, quarter_number]
			if status_id == SeniorRoostStateScript.STATUS_QUARTER_CHOICE else
			"Y%d · Q%d · SHIFT %d / %d" % [year_number, quarter_number, display_shift, SeniorRoostStateScript.SHIFTS_PER_QUARTER])
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
		"objective_section_title": "SENIOR OBJECTIVE",
		"next_objective": objective,
		"milestone_choices": policy_cards,
		"selected_milestone": String(_senior_roost_state.active_policy_id),
		"choice_required": status_id == SeniorRoostStateScript.STATUS_QUARTER_CHOICE,
		"choice_section_title": "QUARTERLY CAPITAL POLICY  //  FILE ONE",
		"choice_hint": "One irreversible policy governs the next three shifts.",
		"continue_label": continue_label,
		"continue_tooltip": continue_tooltip,
		"credit_memo": policy_receipt,
		"score_receipt": {},
		"hen_highlight": hen_highlight,
		"senior_roost": state_snapshot,
		"career_sponsorship": _career_sponsorship_presentation_snapshot(),
	}


func _career_sponsorship_presentation_snapshot() -> Dictionary:
	if not _campaign_senior_roost or _senior_roost_state == null:
		return {"visible": false}
	var status_id: StringName = _senior_roost_state.status
	var gate_open := status_id in [
		SeniorRoostStateScript.STATUS_QUARTER_CHOICE,
		SeniorRoostStateScript.STATUS_ANNUAL_REVIEW,
	]
	var has_closed_quarter: bool = _senior_roost_state.completed_quarters > 0
	if not gate_open or not has_closed_quarter:
		return {"visible": false}

	var simulation_snapshot := _simulation.snapshot()
	var senior_snapshot: Dictionary = _senior_roost_state.snapshot()
	var mark_cost := int(senior_snapshot.get(
		"sponsorship_mark_cost",
		SeniorRoostStateScript.SPONSORSHIP_MARK_COST,
	))
	var available_marks := int(senior_snapshot.get(
		"available_roost_marks",
		_senior_roost_state.roost_marks,
	))
	var fund_cost := int(simulation_snapshot.get("career_sponsorship_cost_cents", 1200))
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

	return {
		"visible": true,
		"available_marks": available_marks,
		"lifetime_marks": _senior_roost_state.roost_marks,
		"invested_marks": int(senior_snapshot.get("roost_marks_spent", 0)),
		"mark_cost": mark_cost,
		"fund_cost_cents": fund_cost,
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
		"delivered_quality": "",
		"delivered_value_cents": 0,
		"delivered_priority_credit_cents": 0,
		"potential_priority_credit_cents": 0,
		"prior_presentations_pending": 0,
	}


func _reset_first_clutch(enabled: bool) -> void:
	_first_clutch_completion_generation += 1
	_first_clutch_completion_hold_until_msec = 0
	_first_clutch = _make_first_clutch_state(not enabled)
	_refresh_first_clutch_ui(_simulation.snapshot())


func _normalize_first_clutch_state(value: Dictionary, legacy_missing: bool = false) -> Dictionary:
	if legacy_missing or value.is_empty() or int(value.get("version", -1)) != FIRST_CLUTCH_VERSION:
		return _make_first_clutch_state(true)
	var normalized := _make_first_clutch_state(bool(value.get("dismissed", false)))
	normalized["completed"] = bool(value.get("completed", false))
	normalized["target_worker_id"] = maxi(-1, int(value.get("target_worker_id", -1)))
	for key in ["inspected", "specialty_routed", "checkin_filed", "delivery_laid", "delivery_seen"]:
		normalized[key] = bool(value.get(key, false))
	normalized["checkin_worker_id"] = maxi(-1, int(value.get("checkin_worker_id", -1)))
	normalized["assisted_worker_id"] = maxi(-1, int(value.get("assisted_worker_id", -1)))
	normalized["assisted_claim_id"] = maxi(-1, int(value.get("assisted_claim_id", -1)))
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

	if int(normalized["target_worker_id"]) < 0:
		normalized["inspected"] = false
		normalized["specialty_routed"] = false
		normalized["checkin_filed"] = false
		normalized["checkin_worker_id"] = -1
		normalized["assisted_worker_id"] = -1
		normalized["assisted_claim_id"] = -1
		normalized["delivery_laid"] = false
		normalized["delivery_seen"] = false
		normalized["completed"] = false
		normalized["prior_presentations_pending"] = 0
	elif int(normalized["assisted_worker_id"]) != int(normalized["target_worker_id"]):
		normalized["assisted_worker_id"] = -1
		normalized["assisted_claim_id"] = -1
		normalized["delivery_laid"] = false
		normalized["delivery_seen"] = false
		normalized["completed"] = false
		normalized["prior_presentations_pending"] = 0
	if not bool(normalized["checkin_filed"]):
		normalized["checkin_worker_id"] = -1

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
		and not bool(_first_clutch.get("orders_handoff_acknowledged", false))
	)


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


func _first_clutch_record_presentation(worker_id: int, quality: StringName, value_cents: int) -> void:
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
	_update_guidance(snapshot)
	_save_campaign_checkpoint("first_clutch_completed")
	_retire_first_clutch_after_hold(completion_generation)
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


func _on_first_clutch_skip_requested() -> void:
	if bool(_first_clutch.get("dismissed", true)) or bool(_first_clutch.get("completed", false)):
		return
	_first_clutch["dismissed"] = true
	_first_clutch_completion_generation += 1
	_first_clutch_completion_hold_until_msec = 0
	_ticker_label.text = "FIRST CLUTCH COACH FILED AWAY. Every management control remains available."
	var snapshot := _simulation.snapshot()
	_refresh_first_clutch_ui(snapshot)
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
		and Time.get_ticks_msec() < _first_clutch_completion_hold_until_msec
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
				body = "Use the dossier tray stamps below. Specialty matching improves speed and shell safety; AUTO stays available later."
			guidance = "Route %s to %s in her dossier." % [target_name, specialty_short]
		&"check_in":
			title = "FILE %s'S CHECK-IN" % target_name
			var profile_name := String(worker.get("career_profile_name", "CAREER PROFILE")).to_upper()
			body = "Choose one real personnel stamp. PROFILE FIT marks the choice that best matches %s's %s." % [target_name, profile_name]
			guidance = "Choose one check-in stamp for %s; PROFILE FIT is her preferred option." % target_name
		&"priority_peck":
			title = "LAND %s'S PRIORITY PECK" % target_name
			var peck_status := worker.get("peck_assist", {}) as Dictionary
			if bool(peck_status.get("available", false)):
				body = "GOLD WINDOW OPEN. Press E or use the glowing dossier stamp before this live claim moves on."
				guidance = "%s is in the gold window—press E or the dossier stamp now." % target_name
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
		"completion": stage == &"complete",
		"pre_policy": pre_policy,
		"orders_handoff_pending": orders_handoff_pending,
		"orders_handoff_cue_visible": orders_handoff_pending and management_available,
		"can_skip": stage != &"complete" and not pre_policy,
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


func _save_campaign_checkpoint(reason: String) -> bool:
	# Headless regressions and art-capture launches bypass the player-facing title
	# and must never overwrite a real native campaign. The focused persistence
	# integration test explicitly opts into an isolated filename.
	if _should_bypass_campaign_title() and not _allow_automated_campaign_saves:
		return true
	if _campaign_state == null or _campaign_store == null:
		return false
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


func _load_campaign_checkpoint() -> void:
	var envelope := _campaign_store.load()
	if envelope.is_empty():
		_show_campaign_title(false)
		_ticker_label.text = "CONTINUE UNAVAILABLE. %s" % _campaign_store.last_error
		return
	var payload := envelope.get("campaign", {}) as Dictionary
	var campaign_data := payload.get("campaign", {}) as Dictionary
	var simulation_data := payload.get("simulation", {}) as Dictionary
	var senior_data_value: Variant = payload.get("senior_roost", {})
	var restored_campaign = CampaignStateScript.from_dictionary(campaign_data)
	if restored_campaign == null or not _simulation.restore_save_state(simulation_data):
		_show_campaign_title(_campaign_store.has_save())
		_ticker_label.text = "SAVE HELD FOR REVIEW. The office could not safely restore this probation file."
		return
	_campaign_state = restored_campaign
	var session := payload.get("session", {}) as Dictionary
	var restored_senior = null
	var migrated_legacy_senior := false
	if senior_data_value is Dictionary and not (senior_data_value as Dictionary).is_empty():
		restored_senior = SeniorRoostStateScript.from_dictionary(senior_data_value as Dictionary)
		if restored_senior == null:
			_show_campaign_title(_campaign_store.has_save())
			_ticker_label.text = "SAVE HELD FOR REVIEW. The Senior Roost career ledger did not pass validation."
			return
	else:
		restored_senior = SeniorRoostStateScript.new()
		if bool(session.get("senior_roost", false)):
			var legacy_last_report := session.get("last_workday_report", {}) as Dictionary
			restored_senior.begin(
				int(legacy_last_report.get("day", maxi(0, _simulation.day - 1))),
				_simulation.snapshot(),
			)
			migrated_legacy_senior = true
	_senior_roost_state = restored_senior
	_campaign_review_stage = StringName(String(session.get("review_stage", "active")))
	if migrated_legacy_senior:
		_campaign_review_stage = &"senior_quarter"
	if _campaign_review_stage not in [&"active", &"farmer", &"credit", &"probation", &"final", &"senior_quarter", &"senior_annual"]:
		_campaign_review_stage = &"active"
	_last_workday_report = (session.get("last_workday_report", {}) as Dictionary).duplicate(true)
	_campaign_senior_roost = _senior_roost_state.is_active()
	if not _campaign_senior_roost and _campaign_review_stage in [&"senior_quarter", &"senior_annual"]:
		_campaign_review_stage = &"active"
	# Older campaign files predate induction. Grandfather them instead of placing a
	# tutorial over an already-understood or mid-shift office. Fresh files opt in
	# explicitly through _on_campaign_new_requested().
	var first_clutch_data: Dictionary = {}
	var first_clutch_value: Variant = session.get("first_clutch", {})
	if first_clutch_value is Dictionary:
		first_clutch_data = first_clutch_value as Dictionary
	_first_clutch = _normalize_first_clutch_state(
		first_clutch_data,
		not session.has("first_clutch"),
	)
	for unlock_value in _campaign_state.unlocked_feature_ids:
		_simulation.apply_campaign_unlock(StringName(unlock_value))
	_last_reviewed_day = _simulation.day
	_reset_campaign_session_visuals()
	var recovered_attention := _reconcile_orphaned_peck_assist_deliveries()
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


func _reset_campaign_session_visuals() -> void:
	_clock.set_speed(0)
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


func _update_campaign_objectives_label(snapshot: Dictionary = {}) -> void:
	if _campaign_objectives_label == null or _campaign_state == null:
		return
	var active_snapshot := snapshot if not snapshot.is_empty() else _simulation.snapshot()
	var live_metrics := _campaign_live_metrics(active_snapshot)
	var senior_mode: bool = _campaign_senior_roost and _senior_roost_state != null and _senior_roost_state.is_active()
	if _campaign_orders_heading_label != null:
		_campaign_orders_heading_label.text = (
			"THIS QUARTER'S SENIOR ORDERS" if senior_mode else "TODAY'S PROBATION ORDERS"
		)
	if senior_mode and _senior_roost_state.status == SeniorRoostStateScript.STATUS_QUARTER_CHOICE:
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
		var annual_passed := bool(_senior_roost_state.last_annual_review.get("passed", false))
		_campaign_objectives_label.text = "ANNUAL  ·  %s  ·  %d / 100" % [
			"PASSED" if annual_passed else "IMPROVEMENT YEAR",
			int(_senior_roost_state.last_annual_review.get("score", 0)),
		]
		_campaign_objectives_label.tooltip_text = "Acknowledge the annual review to continue the uncapped Senior career. This closed-quarter gate also permits one optional Career Sponsorship."
		_campaign_objectives_label.set_meta("orders_on_track", 1 if annual_passed else 0)
		_campaign_objectives_label.set_meta("orders_total", 1)
		return
	var objectives: Array[Dictionary] = (
		_senior_roost_state.current_objective_progress(live_metrics)
		if senior_mode else
		_campaign_state.current_objective_progress(live_metrics)
	)
	if objectives.is_empty():
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
	tooltip_lines.append(
		"Filed at quarter close; live measures can still move. A 60+ quarter earns promotion progress."
		if senior_mode else
		"Filed at review; live measures can still move. Each completed order pays its listed score, and a clean sweep adds +3."
	)
	_campaign_objectives_label.tooltip_text = "\n\n".join(tooltip_lines)
	_campaign_objectives_label.text = "\n".join(lines)


func _update_flock_labor_label(snapshot: Dictionary) -> void:
	if _flock_labor_label == null:
		return
	var compact := snapshot.get("flock_compact", {}) as Dictionary
	var work_to_rule := snapshot.get("work_to_rule", {}) as Dictionary
	var last_petition := snapshot.get("flock_petition", {}) as Dictionary
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


func _set_campaign_modal_open(is_open: bool) -> void:
	if is_open:
		_clock.set_speed(0)
		_set_flockwatch_open(false)
	if _camera_controller != null:
		var another_modal := (
			(_decision_host != null and _decision_host.visible)
			or (_day_review_scrim != null and _day_review_scrim.visible)
		)
		_camera_controller.set_process_unhandled_input(not is_open and not another_modal)
	if _routing_ui != null:
		var can_route := (
			not is_open
			and _simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
			and (_decision_host == null or not _decision_host.visible)
			and (_day_review_scrim == null or not _day_review_scrim.visible)
		)
		_routing_ui.set_interaction_enabled(can_route)
	_on_speed_changed(_clock.speed_index, SimulationClock.SPEED_MULTIPLIERS[_clock.speed_index])
	_refresh_first_clutch_ui(_simulation.snapshot())


func _show_campaign_title(continue_available: bool) -> void:
	_campaign_ui.apply_snapshot({
		"view": &"title",
		"day": 1,
		"total_days": CampaignStateScript.CAMPAIGN_LENGTH,
		"continue_available": continue_available,
	})
	_campaign_ui.show_title(continue_available)


func _should_bypass_campaign_title() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
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


func _publish_web_diagnostic_state(snapshot: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	var first_clutch := _first_clutch_coach_snapshot(snapshot)
	var focused_worker_id := -1
	if _routing_ui != null:
		focused_worker_id = _routing_ui.focused_worker_id()
	var state := {
		"loaded": true,
		"campaign_stage": String(_campaign_review_stage),
		"campaign_day": int(_campaign_state.completed_shifts) + 1,
		"campaign_score": int(_campaign_state.probation_score),
		"senior_roost": (
			_senior_roost_state.snapshot()
			if _senior_roost_state != null and _senior_roost_state.is_active() else
			{"status": "inactive"}
		),
		"career_sponsorship": (
			_career_sponsorship_presentation_snapshot()
			if _campaign_senior_roost else
			{"visible": false}
		),
		"shift_phase": int(snapshot.get("shift_phase", -1)),
		"clock_speed_index": _clock.speed_index,
		"clock_multiplier": SimulationClock.SPEED_MULTIPLIERS[_clock.speed_index],
		"pending_decision_kind": String(_active_decision.get("kind", "")),
		"first_clutch": {
			"visible": bool(first_clutch.get("visible", false)),
			"stage": String(first_clutch.get("stage", "")),
			"progress": int(first_clutch.get("progress", 0)),
			"target_worker_id": int(first_clutch.get("target_worker_id", -1)),
			"first_hen_prelude": bool(first_clutch.get("pre_policy", false)),
			"target_name": String(first_clutch.get("target_name", "")),
			"orders_handoff_pending": bool(first_clutch.get("orders_handoff_pending", false)),
			"orders_handoff_acknowledged": bool(_first_clutch.get("orders_handoff_acknowledged", false)),
		},
		"focused_worker_id": focused_worker_id,
		"orders": {
			"on_track": int(_campaign_objectives_label.get_meta("orders_on_track", 0)),
			"total": int(_campaign_objectives_label.get_meta("orders_total", 0)),
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


func _on_flockwatch_pressed() -> void:
	var opening := not _flockwatch_open
	_set_flockwatch_open(opening)
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


func _set_flockwatch_open(is_open: bool) -> void:
	if is_open and _camera_controller != null and _camera_controller.is_focused():
		_camera_controller.show_overview()
	_flockwatch_open = is_open
	if _flockwatch_panel != null:
		_flockwatch_panel.visible = is_open
		_flockwatch_panel.mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE
	if _flockwatch_toggle != null:
		_flockwatch_toggle.tooltip_text = ("Close the ledger and restore the full coop view." if is_open else "Open the rooster's performance ledger.")
	_update_flockwatch_toggle()
	if _simulation != null:
		var snapshot := _simulation.snapshot()
		_refresh_first_clutch_ui(snapshot)
		_update_guidance(snapshot)


func _update_flockwatch_toggle() -> void:
	if _flockwatch_toggle == null:
		return
	var snapshot := _simulation.snapshot()
	var headcount := int(snapshot.get("active_staff_count", _worker_views.size()))
	var capacity := _office_capacity_from_snapshot(snapshot)
	if _flockwatch_open:
		_flockwatch_toggle.text = "CLOSE LEDGER  ·  %d/%d  [V]" % [headcount, capacity]
		_flockwatch_toggle.tooltip_text = "Close the ledger and restore the full coop view."
		return
	if _first_clutch_orders_handoff_pending():
		_flockwatch_toggle.text = "OPEN TODAY'S 3 ORDERS  [V]"
		_flockwatch_toggle.tooltip_text = "First Clutch complete: open the three live probation orders."
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
			var compact_summary: String = leader_summary.replace("LAST SHIFT // ", "LAST  ·  ")
			compact_summary = compact_summary.replace(" // ", "  ·  ")
			_flockwatch_toggle.text = "%s  [V]" % compact_summary
			_flockwatch_toggle.tooltip_text = "%s\nOpen the full credited-output ledger." % leader_summary
			return
	var affordable := 0
	var spendable := int(snapshot.get("spendable_fund_cents", _simulation.revenue_cents))
	for upgrade in _simulation.upgrade_catalog():
		if not bool(upgrade.get("maxed", false)) and spendable >= int(upgrade.get("cost_cents", 0)):
			affordable += 1
	_flockwatch_toggle.text = (
		"FLOCK %d/%d  ·  %d READY  [V]" % [headcount, capacity, affordable]
		if affordable > 0 else
		"FLOCKWATCH  ·  %d/%d  [V]" % [headcount, capacity]
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
	if _clock.speed_index == 0:
		_guidance_label.text = "PAUSED: inspect a hen or open Flockwatch before resuming."
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
		_guidance_label.text = "PRIORITY PECK READY: %s  ·  %s  ·  press E or use the gold dossier stamp" % [assist_worker_name, assist_timing]
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


func _on_snapshot_changed(snapshot: Dictionary) -> void:
	var active_snapshot := _snapshot_with_active_workers(snapshot)
	_apply_office_capacity_visibility(_office_capacity_from_snapshot(snapshot))
	_reconcile_worker_views(snapshot)
	_refresh_workstation_nameplates(snapshot)
	_update_lighting(snapshot)
	if _office_atmosphere != null:
		_office_atmosphere.update_from_snapshot(active_snapshot)
	if _office_storytelling != null:
		_office_storytelling.apply_snapshot(active_snapshot)
	if _workstation_feedback != null:
		_workstation_feedback.apply_snapshot(_workstation_visual_snapshot(active_snapshot))
	if _staffing_ui != null:
		_staffing_ui.apply_snapshot(snapshot)
	if _pecking_order_ui != null:
		_pecking_order_ui.call("apply_snapshot", snapshot)
	if _routing_ui != null:
		var routing_snapshot := active_snapshot.duplicate(true)
		var routing_workers: Array = routing_snapshot.get("workers", [])
		for worker_value in routing_workers:
			var worker := worker_value as Dictionary
			var worker_id := int(worker.get("id", -1))
			worker["estimated_crack_risk"] = _simulation.estimated_crack_risk(worker_id)
		_routing_ui.apply_snapshot(routing_snapshot)
	_refresh_first_clutch_ui(snapshot)
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
	_quality_streak_label.text = "CLEAN CLUTCH  ×%d" % quality_streak
	_quality_streak_label.add_theme_color_override(
		"font_color",
		Color("f4cd66") if quality_streak >= 4 else Color("9ccfc2")
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
	if not labor_tooltip.is_empty():
		_directive_badge.tooltip_text += "\n%s" % labor_tooltip
	var overdue_claims := int(snapshot.get("overdue_claims", (snapshot.get("routing", {}) as Dictionary).get("overdue_total", 0)))
	_claims_label.text = "Peckwork queued:  %d  ·  overdue: %d" % [int(snapshot["claims_waiting"]), overdue_claims]
	_egg_label.text = "Eggs gathered:  %d" % int(snapshot["eggs_total"])
	_quota_label.text = "Daily clutch:  %d / %d" % [int(snapshot["eggs_today"]), int(snapshot["quota_target"])]
	_confidence_label.text = "Farmer favor:  %d%%" % int(snapshot["executive_confidence"])
	_compliance_label.text = "Coop obedience:  %d%%" % int(snapshot["compliance"])
	_solidarity_label.text = "Flock unity risk:  %d%%" % int(snapshot["solidarity"])

	var morale_total := 0.0
	var worker_data: Array = active_snapshot.get("workers", [])
	for worker_snapshot in worker_data:
		morale_total += float(worker_snapshot["morale"])
		var worker_id := int(worker_snapshot["id"])
		if _worker_views.has(worker_id):
			_worker_views[worker_id].apply_snapshot(worker_snapshot)
	_morale_label.text = "Flock spirits:  %d%%" % int(morale_total / maxf(1.0, float(worker_data.size())))

	var overtime_active := bool(snapshot["overtime_enabled"])
	_overtime_button.text = ("END AFTER-HOURS PECKING  [O]" if overtime_active else "ENABLE AFTER-HOURS PECKING  [O]")
	_overtime_button.button_pressed = overtime_active
	var shift_phase := int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
	var shift_running := shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
	if _routing_ui != null:
		var management_modal_open := (
			(_decision_host != null and _decision_host.visible)
			or (_day_review_scrim != null and _day_review_scrim.visible)
			or (_campaign_ui != null and _campaign_ui.is_modal_open())
		)
		_routing_ui.set_interaction_enabled(shift_running and not management_modal_open)
		_routing_ui.set_peck_assist_clock_running(_clock.speed_index > 0)
	var campaign_modal_open := _campaign_ui != null and _campaign_ui.is_modal_open()
	_overtime_button.disabled = not shift_running or _feed_party_active or campaign_modal_open
	_continue_shift_button.visible = shift_phase == DepartmentSimulation.ShiftPhase.REVIEW
	if _continue_shift_button.visible:
		var pending_memo_id := StringName(snapshot.get("credit_memo_id", &""))
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
		_feed_button.text = "FUND FEED PARTY  ($20)  [P]"
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
	_update_flockwatch_toggle()
	_update_campaign_objectives_label(snapshot)
	_update_flock_labor_label(snapshot)
	_update_guidance(snapshot)
	_publish_web_diagnostic_state(snapshot)


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
	_pending_collection_cents += maxi(0, value_cents)
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
		_ticker_label.text = "%s EGG ENTERED GRADING  ·  CLEAN CLUTCH ×%d" % [String(quality).to_upper(), streak]
		if _quality_streak_label != null:
			var streak_tween := create_tween()
			_quality_streak_label.modulate = Color("ffe39a")
			streak_tween.tween_property(_quality_streak_label, "modulate", Color.WHITE, 0.65)
	if quality == &"golden" and _camera_controller != null:
		_camera_controller.show_event_focus(worker_view.global_position + Vector3.UP * 0.82, "GOLDEN EGG", 1.55)
	_save_campaign_checkpoint("egg_laid")


func _on_camera_focus_changed(label: String, worker_id: int) -> void:
	var focused := worker_id >= 0 or not label.is_empty()
	var focus_position := Vector3(INF, INF, INF)
	if focused and _camera_controller != null:
		focus_position = _camera_controller.focus_world_position()
	EnvironmentalSignageScript.set_camera_detail(self, focused, focus_position)
	if worker_id >= 0:
		if (
			_first_hen_prelude_pending()
			and worker_id == int(_first_clutch.get("target_worker_id", -1))
		):
			_open_first_hen_file(worker_id, false)
		_first_clutch_record_inspection(worker_id)
	if _ticker_label == null:
		return
	if worker_id >= 0 or not label.is_empty():
		_set_flockwatch_open(false)
	if _routing_ui != null:
		_routing_ui.set_focus(worker_id if worker_id >= 0 else -1)
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
		return
	if not label.is_empty():
		_ticker_label.text = label
	else:
		_ticker_label.text = "Click a hen to inspect  ·  V opens Flockwatch  ·  Shift objective stays above."


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
	_ticker_label.text = "%s GRADED  ·  $%.2f base%s  ·  awaiting farmer collection" % [
		String(quality).to_upper(),
		base_value / 100.0,
		("  +  $%.2f clean-clutch" % (streak_bonus_cents / 100.0) if streak_bonus_cents > 0 else ""),
	]


func _on_egg_reached_presentation(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	_streak_bonus_cents: int
) -> void:
	var delivered_claim_id := _take_collection_claim(worker_id)
	var remaining_in_flight := maxi(0, int(_eggs_in_flight_by_worker.get(worker_id, 0)) - 1)
	if remaining_in_flight > 0:
		_eggs_in_flight_by_worker[worker_id] = remaining_in_flight
	else:
		_eggs_in_flight_by_worker.erase(worker_id)
	_pending_collection_cents = maxi(0, _pending_collection_cents - maxi(0, value_cents))
	if _audio_feedback != null:
		_audio_feedback.play_basket_thunk(quality)
	_tween_fund_to(maxi(0, _authoritative_revenue_cents - _pending_collection_cents))
	_spawn_fund_credit_chip(value_cents, quality)
	if _office_atmosphere != null and _office_storytelling != null:
		_office_atmosphere.pulse_egg_laid(_office_storytelling.presentation_focus_point_global(), quality)
	var attention_receipt := _simulation.settle_peck_assist_delivery(delivered_claim_id, quality)
	if bool(attention_receipt.get("accepted", false)):
		_spawn_attention_refund_chip(attention_receipt, quality)
		_ticker_label.text = "%s DELIVERED  Â·  +1 PRIORITY PECK  Â·  %d/%d attention ready" % [
			String(quality).to_upper(),
			int(attention_receipt.get("charges_after", 0)),
			DepartmentSimulation.PECK_ASSIST_LIMIT,
		]
		_save_campaign_checkpoint("priority_peck_attention_refunded")
	_first_clutch_record_presentation(worker_id, quality, value_cents)


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
	if _office_atmosphere != null and (message.to_lower().contains("missed") or message.to_lower().contains("denied")):
		_office_atmosphere.pulse_alert(0.8)


func _on_feed_party_funded() -> void:
	if _feed_party_active:
		return
	_feed_party_active = true
	_feed_party_previous_speed = _clock.speed_index if _clock.speed_index > 0 else 1
	_clock.set_speed(0)
	if _audio_feedback != null:
		_audio_feedback.play_feed_party()
	if _office_atmosphere != null:
		_office_atmosphere.pulse_feed_party(FEED_PARTY_STATION_POSITION + Vector3.UP * 0.72)
	_feed_party_release_scheduled = false
	_feed_party_arrivals.clear()
	_feed_party_returns.clear()

	var attendance_targets: Dictionary[int, Vector3] = {}
	for worker_id in _worker_views:
		attendance_targets[worker_id] = _feed_party_attendance_target(worker_id)

	_feed_party_station.visible = true
	_feed_party_station.position = FEED_PARTY_STATION_POSITION + Vector3(0.0, -0.42, 0.0)
	if _feed_party_tween != null and _feed_party_tween.is_valid():
		_feed_party_tween.kill()
	_feed_party_tween = create_tween()
	_feed_party_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_feed_party_tween.tween_property(_feed_party_station, "position:y", FEED_PARTY_STATION_POSITION.y, 0.7)

	for worker_id in _worker_views:
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


func _on_feed_party_attendance_ready(worker_id: int) -> void:
	if not _feed_party_active:
		return
	_feed_party_arrivals[worker_id] = true
	if _feed_party_arrivals.size() == _worker_views.size() and not _feed_party_release_scheduled:
		_feed_party_release_scheduled = true
		_release_feed_party_after_delay()


func _release_feed_party_after_delay() -> void:
	await get_tree().create_timer(FEED_PARTY_DURATION).timeout
	if not _feed_party_active:
		return
	for view in _worker_views.values():
		view.return_from_feed_party()


func _on_feed_party_attendance_completed(worker_id: int) -> void:
	if not _feed_party_active:
		return
	_feed_party_returns[worker_id] = true
	if _feed_party_returns.size() < _worker_views.size():
		return
	_feed_party_active = false
	_feed_party_release_scheduled = false
	if _feed_party_tween != null and _feed_party_tween.is_valid():
		_feed_party_tween.kill()
	_feed_party_tween = create_tween()
	_feed_party_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_feed_party_tween.tween_property(_feed_party_station, "position:y", -0.42, 0.55)
	_feed_party_tween.tween_callback(_hide_feed_party_station)
	var can_resume := (
		_simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and (_decision_host == null or not _decision_host.visible)
		and (_day_review_scrim == null or not _day_review_scrim.visible)
	)
	_clock.set_speed(_feed_party_previous_speed if can_resume else 0)
	_ticker_label.text = (
		"FEED PARTY COMPLETE. Production resumes; attendance has been archived."
		if can_resume else
		"FEED PARTY COMPLETE. The flock remains paused for management review."
	)


func _hide_feed_party_station() -> void:
	_feed_party_station.visible = false
	_feed_party_station.position = FEED_PARTY_STATION_POSITION


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
	_set_flockwatch_open(true)
	await get_tree().create_timer(0.55).timeout
	_save_preview("flockwatch_labor.png")


func _capture_ledger_preview() -> void:
	_prepare_capture_running()
	await get_tree().create_timer(1.0).timeout
	_simulation.purchase_upgrade(&"peckwork_tools")
	_set_flockwatch_open(true)
	await get_tree().create_timer(0.45).timeout
	_save_preview("requisitions.png")


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
	# for the authoritative ready callbacks so the image shows all six hens feeding.
	var deadline_msec := Time.get_ticks_msec() + 45000
	while _feed_party_arrivals.size() < _worker_views.size() and Time.get_ticks_msec() < deadline_msec:
		await get_tree().process_frame
	if _feed_party_arrivals.size() < _worker_views.size():
		push_warning("Feed-party capture timed out with %d/%d attendees." % [_feed_party_arrivals.size(), _worker_views.size()])
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
	_set_flockwatch_open(true)
	await get_tree().create_timer(0.55).timeout
	_save_preview("roost_staffing.png")


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


func _make_label(text: String, font_size: int, color: Color = Color("eef1f5")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
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
