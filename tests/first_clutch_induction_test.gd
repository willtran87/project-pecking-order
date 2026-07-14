extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const MAIN_SAVE_FILENAME := "first_clutch_induction_test.json"
const INFLIGHT_SAVE_FILENAME := "first_clutch_induction_inflight_test.json"
const PERSISTED_FIELDS: Array[String] = [
	"version",
	"dismissed",
	"completed",
	"target_worker_id",
	"inspected",
	"specialty_routed",
	"checkin_filed",
	"checkin_worker_id",
	"assisted_worker_id",
	"assisted_claim_id",
	"delivery_laid",
	"delivery_seen",
	"orders_handoff_acknowledged",
	"delivered_quality",
	"delivered_value_cents",
	"delivered_priority_credit_cents",
	"potential_priority_credit_cents",
	"prior_presentations_pending",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(MAIN_SAVE_FILENAME)
	var inflight_store = CampaignSaveStoreScript.new(INFLIGHT_SAVE_FILENAME)
	store.delete()
	inflight_store.delete()

	var office: Office = await _spawn_office(store)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var coach := office.find_child("FirstClutchCoach", true, false) as PanelContainer
	_check(
		office != null and simulation != null and clock != null and campaign_ui != null and routing_ui != null,
		"Office should boot every authoritative collaborator used by induction",
		failures,
	)

	# Use the same title-card action as a player. Headless Office otherwise starts
	# an uncoached fixture campaign so unrelated tests never overwrite player data.
	campaign_ui.show_title(false)
	await process_frame
	_check(_press(office.find_child("NewCampaignButton", true, false) as Button), "New Campaign should be actionable", failures)
	await process_frame
	await process_frame
	var state := office.first_clutch_snapshot()
	var decision_host := office.find_child("ManagementDecisionHost", true, false) as Control
	var prelude_button := office.find_child("FirstClutchReturnToHen", true, false) as Button
	_check(not bool(state.get("dismissed", true)), "a real new campaign should opt into First Clutch", failures)
	_check(not bool(state.get("completed", true)), "new induction should start incomplete", failures)
	_check(int(state.get("target_worker_id", -2)) == 0, "new induction should feature stable worker zero without counting an inspection", failures)
	_check(StringName(state.get("stage", "")) == &"inspect" and int(state.get("progress", -1)) == 0, "new induction should begin at inspect, zero of five", failures)
	var prelude_coach := _coach_snapshot(office, simulation)
	_check(
		clock.speed_index == 0
		and simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE
		and decision_host != null
		and not decision_host.visible,
		"Mabel's pre-policy file should hold the authoritative morning gate at clock zero",
		failures,
	)
	_check(
		coach != null
		and coach.is_visible_in_tree()
		and bool(prelude_coach.get("pre_policy", false))
		and "MABEL" in String(prelude_coach.get("title", ""))
		and "remembers the basket" in String(prelude_coach.get("body", "")),
		"new campaign should reveal Mabel's compact authored orientation before any policy card",
		failures,
	)
	_check(
		prelude_button != null
		and prelude_button.is_visible_in_tree()
		and "OPEN MABEL'S FILE" in prelude_button.text,
		"pre-policy orientation should expose one explicit Mabel file action",
		failures,
	)
	var opening_worker_views := office.get("_worker_views") as Dictionary
	var opening_mabel := opening_worker_views.get(0) as ChickenView
	_check(
		opening_mabel != null and opening_mabel.is_seated_at_workstation(),
		"instant New Campaign should stage Mabel at her real chair instead of framing the entrance flock",
		failures,
	)
	_check(_checkpoint_reason(store) == "new_campaign", "new induction should be present in the initial resumable checkpoint", failures)

	# The public snapshot must be an observation seam, not a mutation back door.
	var detached := office.first_clutch_snapshot()
	detached["dismissed"] = true
	detached["target_worker_id"] = 999
	state = office.first_clutch_snapshot()
	_check(not bool(state.get("dismissed", true)) and int(state.get("target_worker_id", -2)) == 0, "public snapshots should be deep detached from Office state", failures)

	# Speed controls must not use their generic pending-decision fallback to bypass
	# the character-led opening.
	office.call("_on_speed_button_pressed", 1)
	await process_frame
	_check(
		simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE
		and clock.speed_index == 0
		and decision_host != null
		and not decision_host.visible,
		"speed input should leave Mabel's prelude intact instead of announcing policy early",
		failures,
	)

	# Continue from the earliest checkpoint must reconstruct the same camera-safe
	# prelude and must not announce the already-pending policy behind it.
	var expected_prelude := state.duplicate(true)
	office.free()
	await process_frame
	await process_frame
	office = await _spawn_office(store)
	simulation = office.get("_simulation") as DepartmentSimulation
	clock = office.get("_clock") as SimulationClock
	campaign_ui = office.get("_campaign_ui") as ProbationCampaignUI
	routing_ui = office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	coach = office.find_child("FirstClutchCoach", true, false) as PanelContainer
	campaign_ui.show_title(true)
	await process_frame
	_check(
		_press(office.find_child("ContinueCampaignButton", true, false) as Button),
		"fresh Mabel prelude checkpoint should be resumable through Continue",
		failures,
	)
	await process_frame
	await process_frame
	state = office.first_clutch_snapshot()
	decision_host = office.find_child("ManagementDecisionHost", true, false) as Control
	prelude_button = office.find_child("FirstClutchReturnToHen", true, false) as Button
	_check(_same_persisted_state(state, expected_prelude), "Continue should restore every persisted pre-policy First Clutch field", failures)
	_check(
		simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE
		and clock.speed_index == 0
		and coach != null
		and coach.is_visible_in_tree()
		and decision_host != null
		and not decision_host.visible
		and prelude_button != null
		and prelude_button.is_visible_in_tree(),
		"Continue should restore Mabel's actionable prelude with the policy still hidden",
		failures,
	)

	_check(_press(prelude_button), "Open Mabel's File should be actionable through the production coach", failures)
	await process_frame
	await process_frame
	state = office.first_clutch_snapshot()
	_check(
		bool(state.get("inspected", false))
		and int(state.get("target_worker_id", -1)) == 0
		and StringName(state.get("stage", "")) == &"specialty_route"
		and int(state.get("progress", -1)) == 1,
		"opening Mabel's file should advance the existing First Clutch record exactly once",
		failures,
	)
	_check(decision_host != null and decision_host.visible, "Mabel's file action should reveal the mandatory three-card policy", failures)
	var decision_title := office.get("_decision_title") as Label
	_check(decision_title != null and "MABEL" in decision_title.text, "opening policy should explain that its rule applies to Mabel and the flock", failures)
	_check(_checkpoint_reason(store) == "first_hen_file_opened", "Mabel's file should checkpoint before policy authorization", failures)

	var expected_open_file := state.duplicate(true)
	office.free()
	await process_frame
	await process_frame
	office = await _spawn_office(store)
	simulation = office.get("_simulation") as DepartmentSimulation
	clock = office.get("_clock") as SimulationClock
	campaign_ui = office.get("_campaign_ui") as ProbationCampaignUI
	routing_ui = office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	coach = office.find_child("FirstClutchCoach", true, false) as PanelContainer
	campaign_ui.show_title(true)
	await process_frame
	_check(
		_press(office.find_child("ContinueCampaignButton", true, false) as Button),
		"opened Mabel file checkpoint should remain resumable before policy authorization",
		failures,
	)
	await process_frame
	await process_frame
	state = office.first_clutch_snapshot()
	decision_host = office.find_child("ManagementDecisionHost", true, false) as Control
	decision_title = office.get("_decision_title") as Label
	_check(_same_persisted_state(state, expected_open_file), "Continue should restore Mabel at exactly one of five", failures)
	_check(
		simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE
		and decision_host != null
		and decision_host.visible
		and decision_title != null
		and "MABEL" in decision_title.text
		and coach != null
		and not coach.visible,
		"post-file Continue should reopen policy without replaying Mabel's prelude",
		failures,
	)

	await _authorize_opening_policy(office, failures)
	state = office.first_clutch_snapshot()
	_check(simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING, "opening policy should start the real shift", failures)
	_check(
		simulation.day == 1
		and StringName(state.get("stage", "")) == &"specialty_route"
		and int(state.get("progress", -1)) == 1
		and clock.speed_index == 0,
		"genuine coached Day 1 authorization should return to Mabel's exact next action at clock zero",
		failures,
	)
	var inspect_coach := _coach_snapshot(office, simulation)
	_check(
		StringName(inspect_coach.get("stage", "")) == &"specialty_route"
		and "MABEL" in String(inspect_coach.get("title", "")),
		"post-policy coach should preserve Mabel as the active induction case",
		failures,
	)
	_check(coach != null and coach.is_visible_in_tree(), "Mabel route coach should appear once management is unblocked", failures)

	# Later camera selection must never retarget the authored first file.
	var target_worker_id := 0
	var camera := office.get("_camera_controller") as ManagementCameraController
	_check(camera != null, "Office should expose its production management camera", failures)
	if camera != null:
		camera.focus_worker(1)
	await process_frame
	state = office.first_clutch_snapshot()
	_check(int(state.get("target_worker_id", -1)) == target_worker_id, "inspecting another hen should not replace Mabel's first file", failures)
	if camera != null:
		camera.focus_worker(target_worker_id)
	await process_frame
	state = office.first_clutch_snapshot()
	var target_worker := _worker_snapshot(simulation, target_worker_id)
	var specialty := StringName(target_worker.get("specialty", &""))
	var preferred_action := StringName(target_worker.get("preferred_personnel_action", &""))
	_check(bool(state.get("inspected", false)) and int(state.get("target_worker_id", -1)) == target_worker_id, "Mabel should remain the bound first hen", failures)
	_check(StringName(state.get("stage", "")) == &"specialty_route" and int(state.get("progress", -1)) == 1, "camera refocus should not add tutorial progress", failures)
	var specialty_button := office.find_child("Assign_%s" % String(specialty), true, false) as Button
	_check(specialty_button != null and bool(specialty_button.get_meta("first_clutch_cue", false)), "coach should cue the target hen's exact specialty tray", failures)

	# A valid check-in filed early is remembered. Progress remains sequential until
	# the missing route is corrected, preventing the one-check-in-per-day rule from
	# deadlocking this induction.
	var checkin_button := office.find_child("PersonnelAction_%s" % String(preferred_action), true, false) as Button
	_check(_press(checkin_button), "the focused hen's profile-fit check-in should be actionable", failures)
	await process_frame
	state = office.first_clutch_snapshot()
	_check(bool(state.get("checkin_filed", false)), "an early valid check-in should be remembered", failures)
	_check(not bool(state.get("specialty_routed", false)), "an early check-in must not fabricate specialty routing", failures)
	_check(StringName(state.get("stage", "")) == &"specialty_route" and int(state.get("progress", -1)) == 1, "out-of-order check-in should retain sequential coach progress", failures)

	var wrong_lane := _different_lane(specialty)
	var wrong_route_button := office.find_child("Assign_%s" % String(wrong_lane), true, false) as Button
	_check(_press(wrong_route_button), "a non-specialty tray should remain a valid management choice", failures)
	await process_frame
	state = office.first_clutch_snapshot()
	_check(not bool(state.get("specialty_routed", false)) and StringName(state.get("stage", "")) == &"specialty_route", "wrong routing should not satisfy the specialty lesson", failures)
	_check(_press(specialty_button), "the cued specialty tray should remain actionable after a wrong route", failures)
	await process_frame
	state = office.first_clutch_snapshot()
	_check(bool(state.get("specialty_routed", false)) and bool(state.get("checkin_filed", false)), "correct routing should preserve the already-filed check-in", failures)
	_check(StringName(state.get("stage", "")) == &"priority_peck" and int(state.get("progress", -1)) == 3, "correcting the missing route should advance past the remembered check-in", failures)
	var paused_priority_coach := _coach_snapshot(office, simulation)
	_check(
		clock.speed_index == 0
		and StringName(paused_priority_coach.get("stage", "")) == &"priority_peck"
		and bool(paused_priority_coach.get("resume_required", false)),
		"paused Priority stage coach snapshot should explicitly require a clock resume",
		failures,
	)
	_check(_checkpoint_reason(store) == "routing_assignment", "route state should be written before the production routing checkpoint", failures)
	_check(_saved_first_clutch(store).get("checkin_filed", false) == true, "saved route checkpoint should include the earlier check-in", failures)

	# Continue from disk at the most consequential mid-tutorial boundary.
	var expected_before_continue := state.duplicate(true)
	clock.set_speed(0)
	office.free()
	await process_frame
	await process_frame
	office = await _spawn_office(store)
	simulation = office.get("_simulation") as DepartmentSimulation
	clock = office.get("_clock") as SimulationClock
	campaign_ui = office.get("_campaign_ui") as ProbationCampaignUI
	routing_ui = office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	coach = office.find_child("FirstClutchCoach", true, false) as PanelContainer
	campaign_ui.show_title(true)
	await process_frame
	_check(_press(office.find_child("ContinueCampaignButton", true, false) as Button), "Continue should be actionable for the induction checkpoint", failures)
	await process_frame
	await process_frame
	state = office.first_clutch_snapshot()
	_check(_same_persisted_state(state, expected_before_continue), "Continue should restore every persisted First Clutch field without drift", failures)
	_check(StringName(state.get("stage", "")) == &"priority_peck" and int(state.get("progress", -1)) == 3, "Continue should resume at the exact next action", failures)

	# Restored camera framing is presentation-only, so focus the persisted target
	# again, wait for her physical chair arrival, and build a real claim rhythm.
	camera = office.get("_camera_controller") as ManagementCameraController
	if camera != null:
		camera.focus_worker(target_worker_id)
	await process_frame
	var seated := await _wait_until_worker_seated(office, target_worker_id, 720)
	_check(seated, "restored target hen should physically reach her workstation", failures)
	clock.set_speed(0)
	var assist_available := _advance_until_assist_available(simulation, target_worker_id, 64)
	await process_frame
	_check(assist_available, "target hen should enter a real Priority Peck timing window", failures)
	clock.set_speed(1)
	await process_frame
	var running_priority_coach := _coach_snapshot(office, simulation)
	var assist_button := office.find_child("PeckAssistButton", true, false) as Button
	_check(
		not bool(running_priority_coach.get("resume_required", true))
		and assist_button != null
		and bool(assist_button.get_meta("first_clutch_cue", false)),
		"resuming 1x should clear resume_required and cue the production dossier stamp",
		failures,
	)
	var assisted_claim_id := int(simulation.peck_assist_status(target_worker_id).get("claim_id", -1))
	_check(_press(assist_button), "open Priority Peck window should accept the dossier stamp", failures)
	await process_frame
	clock.set_speed(0)
	var assist_result := simulation.last_peck_assist.duplicate(true)
	state = office.first_clutch_snapshot()
	_check(bool(assist_result.get("accepted", false)), "dossier stamp should reach the authoritative assist system", failures)
	_check(int(state.get("assisted_worker_id", -1)) == target_worker_id and int(state.get("assisted_claim_id", -1)) == assisted_claim_id, "induction should retain the exact assisted worker and claim", failures)
	_check(int(state.get("potential_priority_credit_cents", -1)) == int(assist_result.get("potential_priority_credit_cents", -2)), "induction should retain the assist's authoritative potential credit", failures)
	_check(StringName(state.get("stage", "")) == &"delivery" and int(state.get("progress", -1)) == 4, "accepted Priority Peck should advance to physical delivery", failures)
	_check(_checkpoint_reason(store) == "peck_assist", "accepted assist should checkpoint its exact claim", failures)

	# The final step must use the normal seated simulation, egg signal, grading rail,
	# and farmer-basket callback. Capture the laid-but-not-presented checkpoint for
	# a separate recovery boot before allowing the live animation to finish.
	var laid := _advance_until_delivery_laid(office, simulation, 80)
	state = office.first_clutch_snapshot()
	_check(laid and bool(state.get("delivery_laid", false)), "assisted claim should lay through the normal seated production loop", failures)
	_check(not bool(state.get("delivery_seen", true)) and not bool(state.get("completed", true)), "laying alone should not celebrate before farmer presentation", failures)
	_check(StringName(state.get("delivered_quality", &"")) in [&"sound", &"golden", &"cracked"], "laid delivery should retain its real shell grade", failures)
	_check(int(state.get("delivered_value_cents", 0)) > 0, "laid delivery should retain its real credited value", failures)
	var expected_priority_credit := 0 if StringName(state.get("delivered_quality", &"")) == &"cracked" else int(state.get("potential_priority_credit_cents", 0))
	_check(int(state.get("delivered_priority_credit_cents", -1)) == expected_priority_credit, "clean deliveries should retain potential Priority credit and cracked eggs should forfeit it", failures)
	var laid_state := state.duplicate(true)
	var inflight_envelope := store.load()
	_check(_checkpoint_reason(store) == "egg_laid", "laid-but-unpresented delivery should be restart safe", failures)
	_check(
		inflight_store.save(
			inflight_envelope.get("campaign", {}) as Dictionary,
			inflight_envelope.get("metadata", {}) as Dictionary,
		),
		"test should preserve an isolated copy of the in-flight checkpoint",
		failures,
	)

	var completed := await _wait_until_first_clutch_completed(office, 8.0)
	state = office.first_clutch_snapshot()
	_check(completed and bool(state.get("delivery_seen", false)) and bool(state.get("completed", false)), "farmer-basket arrival should complete induction", failures)
	_check(StringName(state.get("stage", "")) == &"complete" and int(state.get("progress", -1)) == 5, "completed induction should report five of five", failures)
	_check(not bool(state.get("orders_handoff_acknowledged", true)) and bool(state.get("orders_handoff_pending", false)), "completion should retain an unacknowledged objectives handoff", failures)
	_check(String(state.get("delivered_quality", "")) == String(laid_state.get("delivered_quality", "")) and int(state.get("delivered_value_cents", -1)) == int(laid_state.get("delivered_value_cents", -2)), "presentation should close the same quality/value delivery that was laid", failures)
	_check(_checkpoint_reason(store) == "first_clutch_completed", "farmer presentation should write a permanent completion checkpoint", failures)
	var completion_title := office.find_child("FirstClutchActionTitle", true, false) as Label
	var completion_body := office.find_child("FirstClutchActionBody", true, false) as Label
	var completion_coach := _coach_snapshot(office, simulation)
	_check(coach != null and coach.visible and completion_title != null and "FIRST CLUTCH FILED" in completion_title.text, "completion should hold a brief visible receipt before retiring", failures)
	_check(
		completion_body != null
		and "Press V" in completion_body.text
		and "three probation orders" in completion_body.text.to_lower()
		and "Press V" in String(completion_coach.get("body", ""))
		and "probation orders" in String(completion_coach.get("body", "")).to_lower(),
		"completion receipt should bridge directly into Flockwatch's probation orders",
		failures,
	)
	await create_timer(5.6).timeout
	_check(coach != null and not coach.visible, "completion receipt should retire without disabling management controls", failures)
	completion_coach = _coach_snapshot(office, simulation)
	state = office.first_clutch_snapshot()
	var flockwatch_toggle := office.find_child("FlockwatchToggle", true, false) as Button
	var guidance := office.get("_guidance_label") as Label
	_check(
		bool(state.get("orders_handoff_pending", false))
		and bool(completion_coach.get("orders_handoff_pending", false))
		and bool(completion_coach.get("orders_handoff_cue_visible", false)),
		"retiring the full receipt must preserve its compact objectives handoff for arbitrary elapsed time",
		failures,
	)
	_check(
		flockwatch_toggle != null
		and flockwatch_toggle.text == "OPEN TODAY'S 3 ORDERS  [V]"
		and "first clutch complete" in flockwatch_toggle.tooltip_text.to_lower(),
		"expired receipt should leave a compact, explicit Flockwatch orders cue (text=%s tooltip=%s)" % [
			flockwatch_toggle.text if flockwatch_toggle != null else "<missing>",
			flockwatch_toggle.tooltip_text if flockwatch_toggle != null else "<missing>",
		],
		failures,
	)
	_check(
		guidance != null
		and "FIRST CLUTCH 5/5" in guidance.text
		and "three probation orders" in guidance.text.to_lower(),
		"expired receipt should keep durable objectives guidance",
		failures,
	)

	# The unacknowledged handoff is campaign state, not a transient timer. Continue
	# must restore the compact cue; only a real player-opened Flockwatch view clears it.
	office.free()
	await process_frame
	await process_frame
	office = await _spawn_office(store)
	simulation = office.get("_simulation") as DepartmentSimulation
	campaign_ui = office.get("_campaign_ui") as ProbationCampaignUI
	campaign_ui.show_title(true)
	await process_frame
	_check(_press(office.find_child("ContinueCampaignButton", true, false) as Button), "completed induction checkpoint should remain loadable through Continue", failures)
	await process_frame
	await process_frame
	state = office.first_clutch_snapshot()
	coach = office.find_child("FirstClutchCoach", true, false) as PanelContainer
	flockwatch_toggle = office.find_child("FlockwatchToggle", true, false) as Button
	guidance = office.get("_guidance_label") as Label
	_check(
		bool(state.get("completed", false))
		and not bool(state.get("orders_handoff_acknowledged", true))
		and bool(state.get("orders_handoff_pending", false))
		and coach != null
		and not coach.visible,
		"Continue should restore the compact handoff without resurrecting the full completion receipt",
		failures,
	)
	_check(
		flockwatch_toggle != null
		and flockwatch_toggle.text == "OPEN TODAY'S 3 ORDERS  [V]"
		and guidance != null
		and "three probation orders" in guidance.text.to_lower(),
		"Continue should restore both the Flockwatch cue and its objectives guidance",
		failures,
	)
	_check(_press(flockwatch_toggle), "player should be able to acknowledge the handoff by opening Flockwatch", failures)
	await process_frame
	state = office.first_clutch_snapshot()
	var flockwatch_panel := office.find_child("FlockwatchLedger", true, false) as PanelContainer
	_check(
		flockwatch_panel != null
		and flockwatch_panel.visible
		and bool(state.get("orders_handoff_acknowledged", false))
		and not bool(state.get("orders_handoff_pending", true)),
		"opening the real orders view should acknowledge and clear the durable handoff",
		failures,
	)
	_check(
		_checkpoint_reason(store) == "first_clutch_orders_opened"
		and bool(_saved_first_clutch(store).get("orders_handoff_acknowledged", false)),
		"orders-view acknowledgment should checkpoint immediately",
		failures,
	)
	_check(
		flockwatch_toggle.text.begins_with("CLOSE LEDGER")
		and flockwatch_toggle.tooltip_text == "Close the ledger and restore the full coop view."
		and guidance != null
		and "FIRST CLUTCH 5/5" not in guidance.text,
		"acknowledgment should retire the tutorial cue while leaving the ledger open",
		failures,
	)

	# Collection tweens are intentionally not serialized. Continuing from the exact
	# in-flight save must normalize it to complete instead of waiting forever for a
	# presentation node that no longer exists.
	office.free()
	await process_frame
	await process_frame
	office = await _spawn_office(inflight_store)
	campaign_ui = office.get("_campaign_ui") as ProbationCampaignUI
	campaign_ui.show_title(true)
	await process_frame
	_check(_press(office.find_child("ContinueCampaignButton", true, false) as Button), "in-flight checkpoint should remain loadable through Continue", failures)
	await process_frame
	await process_frame
	state = office.first_clutch_snapshot()
	coach = office.find_child("FirstClutchCoach", true, false) as PanelContainer
	_check(bool(state.get("completed", false)) and bool(state.get("delivery_seen", false)), "in-flight restore should reconcile its missing presentation animation", failures)
	_check(StringName(state.get("stage", "")) == &"complete" and int(state.get("progress", -1)) == 5, "reconciled restore should never deadlock at delivery", failures)
	_check(String(state.get("delivered_quality", "")) == String(laid_state.get("delivered_quality", "")) and int(state.get("delivered_value_cents", -1)) == int(laid_state.get("delivered_value_cents", -2)), "in-flight reconciliation should preserve the laid egg receipt", failures)
	_check(coach != null and not coach.visible, "reconciled completion should not resurrect a stale completion hold", failures)
	_check(bool(state.get("orders_handoff_pending", false)), "reconciled in-flight completion should still require the durable orders handoff", failures)

	# Skip is optional and uses the same persisted session field. Reuse this Office
	# for a clean campaign so the focused test covers the production button route.
	campaign_ui.show_title(false)
	await process_frame
	_check(_press(office.find_child("NewCampaignButton", true, false) as Button), "a clean campaign should remain available after reconciliation", failures)
	await process_frame
	_check(
		_press(office.find_child("FirstClutchReturnToHen", true, false) as Button),
		"skip fixture should first open Mabel's file",
		failures,
	)
	await process_frame
	await _authorize_opening_policy(office, failures)
	var skip_button := office.find_child("FirstClutchSkip", true, false) as Button
	_check(skip_button != null and skip_button.is_visible_in_tree(), "active coach should expose its optional Skip action", failures)
	_check(_press(skip_button), "Skip should be actionable through the production coach", failures)
	await process_frame
	state = office.first_clutch_snapshot()
	coach = office.find_child("FirstClutchCoach", true, false) as PanelContainer
	_check(bool(state.get("dismissed", false)) and not bool(state.get("completed", true)), "Skip should dismiss without fabricating completion", failures)
	_check(coach != null and not coach.visible, "dismissed coach should leave the full management surface unobstructed", failures)
	_check(_checkpoint_reason(inflight_store) == "first_clutch_skipped" and bool(_saved_first_clutch(inflight_store).get("dismissed", false)), "Skip should persist immediately in the campaign session", failures)

	# Focused lifecycle regressions use clean campaigns on the already-booted
	# Office. This keeps their save and UI wiring real while avoiding repeated 3D
	# asset boots and makes each boundary independent from the prior assertion.
	await _test_non_target_global_checkin(office, failures)
	await _test_out_of_order_delivery_gating(office, inflight_store, failures)
	await _test_presentation_after_farmer_review(office, inflight_store, failures)
	await _test_unlaid_assist_shift_boundary(office, inflight_store, failures)

	var final_envelope := store.load()
	var final_first_clutch := _saved_first_clutch(store)
	var parser := JSON.new()
	var json_error := parser.parse(JSON.stringify(final_first_clutch))
	_check(not final_envelope.is_empty() and json_error == OK and typeof(parser.data) == TYPE_DICTIONARY, "persisted First Clutch state should remain primitive JSON", failures)

	var final_clock := office.get("_clock") as SimulationClock
	if final_clock != null:
		final_clock.set_speed(0)
	office.free()
	await process_frame
	var main_cleaned := store.delete()
	var inflight_cleaned := inflight_store.delete()
	_check(main_cleaned and inflight_cleaned and not store.has_save() and not inflight_store.has_save(), "isolated induction checkpoints should be cleaned up", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FIRST_CLUTCH_INDUCTION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FIRST_CLUTCH_INDUCTION_TEST_PASSED path=Mabel-prelude-policy-route-checkin-continue-assist-lay-present restore=prelude+open-file+priority coach=resume-required+durable-orders-handoff recovery=inflight+handoff-persistence edges=speed-gate+retarget+global-checkin+ordered-completion+review-presentation+rollover-claim skip=persisted json=round-trip")
	quit(0)


func _test_non_target_global_checkin(office: Office, failures: Array[String]) -> void:
	await _start_new_coached_campaign(office, failures)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var camera := office.get("_camera_controller") as ManagementCameraController
	var target_worker_id := 0
	var checkin_worker_id := 1
	if camera != null:
		camera.focus_worker(target_worker_id)
	await process_frame
	if camera != null:
		camera.focus_worker(checkin_worker_id)
	await process_frame
	var checkin_worker := _worker_snapshot(simulation, checkin_worker_id)
	var checkin_action := StringName(checkin_worker.get("preferred_personnel_action", &""))
	var checkin_button := office.find_child(
		"PersonnelAction_%s" % String(checkin_action), true, false
	) as Button
	_check(_press(checkin_button), "non-target hen's accepted global check-in should remain actionable", failures)
	await process_frame
	var state := office.first_clutch_snapshot()
	_check(
		bool(state.get("checkin_filed", false))
		and int(state.get("checkin_worker_id", -1)) == checkin_worker_id,
		"accepted global check-in should count even when it was filed for another hen",
		failures,
	)
	if camera != null:
		camera.focus_worker(target_worker_id)
	await process_frame
	_check(
		await _route_target_to_specialty(office, simulation, target_worker_id),
		"target specialty route should remain actionable after a non-target check-in",
		failures,
	)
	state = office.first_clutch_snapshot()
	_check(
		StringName(state.get("stage", "")) == &"priority_peck"
		and int(state.get("progress", -1)) == 3,
		"global check-in should avoid the once-per-day deadlock and advance to Priority Peck",
		failures,
	)


func _test_out_of_order_delivery_gating(
	office: Office,
	store: CampaignSaveStore,
	failures: Array[String]
) -> void:
	await _start_new_coached_campaign(office, failures)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var camera := office.get("_camera_controller") as ManagementCameraController
	var target_worker_id := 0
	if camera != null:
		camera.focus_worker(target_worker_id)
	await process_frame
	_check(
		await _wait_until_worker_seated(office, target_worker_id, 720),
		"out-of-order fixture target should reach her real chair",
		failures,
	)
	var assist_result := await _perform_target_priority_peck(
		office, simulation, clock, target_worker_id, failures, "out-of-order"
	)
	var state := office.first_clutch_snapshot()
	_check(
		bool(assist_result.get("accepted", false))
		and int(state.get("assisted_claim_id", -1)) >= 0,
		"Priority Peck should remain a valid global control before coached route/check-in",
		failures,
	)
	_check(
		not bool(state.get("specialty_routed", false))
		and not bool(state.get("checkin_filed", false))
		and StringName(state.get("stage", "")) == &"specialty_route",
		"early assist must not skip the first missing coached action",
		failures,
	)
	_check(
		_advance_until_delivery_laid(office, simulation, 80),
		"out-of-order assisted claim should still lay through production",
		failures,
	)
	_check(
		await _wait_until_first_clutch_field(office, &"delivery_seen", 8.0),
		"out-of-order assisted egg should still reach farmer presentation",
		failures,
	)
	state = office.first_clutch_snapshot()
	_check(
		bool(state.get("delivery_seen", false))
		and not bool(state.get("completed", true))
		and StringName(state.get("stage", "")) == &"specialty_route",
		"assist plus delivery must not complete while route and check-in are missing",
		failures,
	)
	_check(
		_checkpoint_reason(store) == "first_clutch_delivery_seen",
		"incomplete out-of-order presentation should checkpoint its remembered delivery",
		failures,
	)
	_check(
		await _route_target_to_specialty(office, simulation, target_worker_id),
		"missing specialty route should remain completable after delivery",
		failures,
	)
	state = office.first_clutch_snapshot()
	_check(
		not bool(state.get("completed", true))
		and StringName(state.get("stage", "")) == &"check_in",
		"remembered delivery should still wait for its final missing check-in",
		failures,
	)
	_check(
		await _file_worker_checkin(office, simulation, target_worker_id),
		"missing target check-in should remain actionable after delivery",
		failures,
	)
	state = office.first_clutch_snapshot()
	_check(
		bool(state.get("completed", false))
		and StringName(state.get("stage", "")) == &"complete"
		and int(state.get("progress", -1)) == 5,
		"remembered out-of-order actions should complete only when all five steps exist",
		failures,
	)
	_check(
		bool(_saved_first_clutch(store).get("completed", false)),
		"late prerequisite completion should remain persisted despite the outer action checkpoint",
		failures,
	)


func _test_presentation_after_farmer_review(
	office: Office,
	store: CampaignSaveStore,
	failures: Array[String]
) -> void:
	await _start_new_coached_campaign(office, failures)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var camera := office.get("_camera_controller") as ManagementCameraController
	var target_worker_id := 0
	if camera != null:
		camera.focus_worker(target_worker_id)
	await process_frame
	_check(
		await _route_target_to_specialty(office, simulation, target_worker_id),
		"review-presentation fixture should file the target specialty route",
		failures,
	)
	_check(
		await _file_worker_checkin(office, simulation, target_worker_id),
		"review-presentation fixture should file its check-in",
		failures,
	)
	_check(
		await _wait_until_worker_seated(office, target_worker_id, 240),
		"review-presentation fixture target should remain physically seated",
		failures,
	)
	var assist_result := await _perform_target_priority_peck(
		office, simulation, clock, target_worker_id, failures, "review-presentation"
	)
	_check(bool(assist_result.get("accepted", false)), "review-presentation assist should be accepted", failures)
	_check(
		_advance_until_delivery_laid(office, simulation, 80),
		"review-presentation assisted claim should lay before closing time",
		failures,
	)
	var state := office.first_clutch_snapshot()
	_check(
		bool(state.get("delivery_laid", false)) and not bool(state.get("delivery_seen", true)),
		"farmer-review boundary should begin with a real egg still in flight",
		failures,
	)
	_check(_force_workday_boundary(simulation), "fixture should enter authoritative farmer review", failures)
	_check(
		StringName(office.get("_campaign_review_stage")) == &"farmer"
		and simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW,
		"egg should still be travelling after campaign review becomes authoritative",
		failures,
	)
	_check(
		await _wait_until_first_clutch_completed(office, 8.0),
		"authorized farmer-basket arrival during review should complete induction",
		failures,
	)
	state = office.first_clutch_snapshot()
	_check(
		bool(state.get("delivery_seen", false))
		and bool(state.get("completed", false))
		and StringName(state.get("stage", "")) == &"complete",
		"review-state presentation should retain the final receipt and completion",
		failures,
	)
	_check(
		_checkpoint_reason(store) == "first_clutch_completed",
		"presentation arriving after workday checkpoint should supersede it with completion",
		failures,
	)


func _test_unlaid_assist_shift_boundary(
	office: Office,
	store: CampaignSaveStore,
	failures: Array[String]
) -> void:
	await _start_new_coached_campaign(office, failures)
	var simulation := office.get("_simulation") as DepartmentSimulation
	var clock := office.get("_clock") as SimulationClock
	var camera := office.get("_camera_controller") as ManagementCameraController
	var target_worker_id := 0
	if camera != null:
		camera.focus_worker(target_worker_id)
	await process_frame
	_check(
		await _route_target_to_specialty(office, simulation, target_worker_id),
		"rollover fixture should file the target specialty route",
		failures,
	)
	_check(
		await _file_worker_checkin(office, simulation, target_worker_id),
		"rollover fixture should file its check-in",
		failures,
	)
	_check(
		await _wait_until_worker_seated(office, target_worker_id, 240),
		"rollover fixture target should remain physically seated",
		failures,
	)
	var assist_result := await _perform_target_priority_peck(
		office, simulation, clock, target_worker_id, failures, "rollover"
	)
	var stale_claim_id := int(assist_result.get("claim_id", -1))
	var state := office.first_clutch_snapshot()
	_check(
		stale_claim_id >= 0
		and int(state.get("assisted_claim_id", -1)) == stale_claim_id
		and not bool(state.get("delivery_laid", false)),
		"rollover fixture should hold one exact assisted but unlaid claim",
		failures,
	)
	_check(_force_workday_boundary(simulation), "assisted-unlaid fixture should reach workday rollover", failures)
	state = office.first_clutch_snapshot()
	_check(
		int(state.get("assisted_worker_id", -2)) == -1
		and int(state.get("assisted_claim_id", -2)) == -1
		and int(state.get("potential_priority_credit_cents", -1)) == 0
		and not bool(state.get("delivery_laid", true)),
		"workday rollover should erase the stale assist before any later egg can claim it",
		failures,
	)
	_check(
		StringName(state.get("stage", "")) == &"priority_peck"
		and int(state.get("progress", -1)) == 3,
		"assisted-unlaid rollover should reopen Priority Peck rather than delivery",
		failures,
	)
	var saved_boundary := _saved_first_clutch(store)
	_check(
		int(saved_boundary.get("assisted_claim_id", -2)) == -1
		and not bool(saved_boundary.get("delivery_laid", true)),
		"workday checkpoint should persist the cleared assist atomically",
		failures,
	)
	_check(
		await _resume_next_shift(office, simulation, failures),
		"rollover fixture should resume a real second shift",
		failures,
	)
	_check(
		await _wait_until_worker_seated(office, target_worker_id, 240),
		"target should still be seated for the next unassisted claim",
		failures,
	)
	var eggs_before := int(_worker_snapshot(simulation, target_worker_id).get("eggs_laid", 0))
	_check(
		_advance_until_worker_egg_count(simulation, target_worker_id, eggs_before + 1, 96),
		"target should complete a later unassisted claim after rollover",
		failures,
	)
	state = office.first_clutch_snapshot()
	_check(
		int(state.get("assisted_claim_id", -2)) == -1
		and not bool(state.get("delivery_laid", true))
		and StringName(state.get("stage", "")) == &"priority_peck",
		"next unassisted egg must not inherit or deliver the stale rollover claim",
		failures,
	)


func _start_new_coached_campaign(office: Office, failures: Array[String]) -> void:
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	campaign_ui.show_title(false)
	await process_frame
	_check(
		_press(office.find_child("NewCampaignButton", true, false) as Button),
		"regression fixture should open a clean campaign",
		failures,
	)
	await process_frame
	await process_frame
	var prelude_button := office.find_child("FirstClutchReturnToHen", true, false) as Button
	_check(
		_press(prelude_button),
		"regression fixture should open Mabel's pre-policy file",
		failures,
	)
	await process_frame
	await process_frame
	await _authorize_opening_policy(office, failures)
	var clock := office.get("_clock") as SimulationClock
	if clock != null:
		clock.set_speed(0)
	var state := office.first_clutch_snapshot()
	_check(
		not bool(state.get("dismissed", true))
		and int(state.get("target_worker_id", -1)) == 0
		and bool(state.get("inspected", false))
		and StringName(state.get("stage", "")) == &"specialty_route",
		"regression fixture should start with a fresh active induction",
		failures,
	)


func _route_target_to_specialty(
	office: Office,
	simulation: DepartmentSimulation,
	worker_id: int
) -> bool:
	var camera := office.get("_camera_controller") as ManagementCameraController
	if camera != null:
		camera.focus_worker(worker_id)
	await process_frame
	var worker := _worker_snapshot(simulation, worker_id)
	var specialty := StringName(worker.get("specialty", &""))
	var button := office.find_child("Assign_%s" % String(specialty), true, false) as Button
	var pressed := _press(button)
	await process_frame
	return pressed


func _file_worker_checkin(
	office: Office,
	simulation: DepartmentSimulation,
	worker_id: int
) -> bool:
	var camera := office.get("_camera_controller") as ManagementCameraController
	if camera != null:
		camera.focus_worker(worker_id)
	await process_frame
	var worker := _worker_snapshot(simulation, worker_id)
	var action_id := StringName(worker.get("preferred_personnel_action", &""))
	var button := office.find_child(
		"PersonnelAction_%s" % String(action_id), true, false
	) as Button
	var pressed := _press(button)
	await process_frame
	return pressed


func _perform_target_priority_peck(
	office: Office,
	simulation: DepartmentSimulation,
	clock: SimulationClock,
	worker_id: int,
	failures: Array[String],
	fixture_name: String
) -> Dictionary:
	if clock != null:
		clock.set_speed(0)
	var available := _advance_until_assist_available(simulation, worker_id, 64)
	await process_frame
	_check(available, "%s fixture should reach a Priority Peck window" % fixture_name, failures)
	var button := office.find_child("PeckAssistButton", true, false) as Button
	if clock != null:
		clock.set_speed(1)
	await process_frame
	_check(_press(button), "%s fixture should stamp its open Priority Peck" % fixture_name, failures)
	await process_frame
	if clock != null:
		clock.set_speed(0)
	return simulation.last_peck_assist.duplicate(true)


func _force_workday_boundary(simulation: DepartmentSimulation) -> bool:
	simulation.minute_of_day = DepartmentSimulation.SHIFT_END_MINUTE - DepartmentSimulation.MINUTES_PER_TICK
	# Both scheduled incident slots may open before the workday completion check.
	# Resolve them through the authoritative decision API, then let the next tick
	# cross the same boundary naturally.
	for _tick in 5:
		if simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
			return true
		_advance_authoritative_tick(simulation)
	return simulation.shift_phase == DepartmentSimulation.ShiftPhase.REVIEW


func _resume_next_shift(
	office: Office,
	simulation: DepartmentSimulation,
	failures: Array[String]
) -> bool:
	var next_button := office.find_child("BeginNextShiftButton", true, false) as Button
	if not _press(next_button):
		return false
	await process_frame
	var reward := office.find_child("DecisionOption_reward_top_layer", true, false) as Button
	var confirm := office.find_child("ConfirmDecisionButton", true, false) as Button
	_check(_press(reward), "closing credit memo should expose its free reward branch", failures)
	_check(_press(confirm), "closing credit memo should be fileable", failures)
	await process_frame
	await process_frame
	var continue_button := office.find_child("ContinueProbationButton", true, false) as Button
	if not _press(continue_button):
		return false
	await process_frame
	await process_frame
	if simulation.shift_phase != DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		return false
	await _authorize_opening_policy(office, failures)
	var clock := office.get("_clock") as SimulationClock
	if clock != null:
		clock.set_speed(0)
	return simulation.shift_phase == DepartmentSimulation.ShiftPhase.RUNNING


func _advance_until_worker_egg_count(
	simulation: DepartmentSimulation,
	worker_id: int,
	target_count: int,
	tick_limit: int
) -> bool:
	for _tick in tick_limit:
		if int(_worker_snapshot(simulation, worker_id).get("eggs_laid", 0)) >= target_count:
			return true
		_advance_authoritative_tick(simulation)
	return int(_worker_snapshot(simulation, worker_id).get("eggs_laid", 0)) >= target_count


func _wait_until_first_clutch_field(
	office: Office,
	field: StringName,
	timeout_seconds: float
) -> bool:
	var elapsed := 0.0
	while elapsed < timeout_seconds:
		if bool(office.first_clutch_snapshot().get(field, false)):
			return true
		await create_timer(0.05).timeout
		elapsed += 0.05
	return bool(office.first_clutch_snapshot().get(field, false))


func _spawn_office(store: CampaignSaveStore) -> Office:
	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame
	return office


func _authorize_opening_policy(office: Office, failures: Array[String]) -> void:
	var policy_button := office.find_child("DecisionOption_shell_assurance", true, false) as Button
	var confirm_button := office.find_child("ConfirmDecisionButton", true, false) as Button
	_check(policy_button != null and confirm_button != null, "opening directive controls should exist", failures)
	_check(_press(policy_button), "Shell Assurance directive should be selectable", failures)
	_check(_press(confirm_button), "selected opening directive should be confirmable", failures)
	await process_frame
	await process_frame


func _wait_until_worker_seated(office: Office, worker_id: int, frame_limit: int) -> bool:
	var worker_views := office.get("_worker_views") as Dictionary
	var worker_view := worker_views.get(worker_id) as ChickenView
	if worker_view == null:
		return false
	for _frame in frame_limit:
		if worker_view.is_seated_at_workstation():
			return true
		await physics_frame
	return worker_view.is_seated_at_workstation()


func _advance_until_assist_available(
	simulation: DepartmentSimulation,
	worker_id: int,
	tick_limit: int
) -> bool:
	for _tick in tick_limit:
		if bool(simulation.peck_assist_status(worker_id).get("available", false)):
			return true
		_advance_authoritative_tick(simulation)
	return bool(simulation.peck_assist_status(worker_id).get("available", false))


func _advance_until_delivery_laid(
	office: Office,
	simulation: DepartmentSimulation,
	tick_limit: int
) -> bool:
	for _tick in tick_limit:
		if bool(office.first_clutch_snapshot().get("delivery_laid", false)):
			return true
		_advance_authoritative_tick(simulation)
	return bool(office.first_clutch_snapshot().get("delivery_laid", false))


func _advance_authoritative_tick(simulation: DepartmentSimulation) -> void:
	simulation.advance_tick()
	if simulation.shift_phase != DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
		return
	var pending := simulation.pending_decision_snapshot()
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) <= simulation.spendable_fund_cents():
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _wait_until_first_clutch_completed(office: Office, timeout_seconds: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout_seconds:
		if bool(office.first_clutch_snapshot().get("completed", false)):
			return true
		await create_timer(0.05).timeout
		elapsed += 0.05
	return bool(office.first_clutch_snapshot().get("completed", false))


func _worker_snapshot(simulation: DepartmentSimulation, worker_id: int) -> Dictionary:
	for worker_value in simulation.snapshot().get("workers", []):
		var worker := worker_value as Dictionary
		if int(worker.get("id", -1)) == worker_id:
			return worker
	return {}


func _coach_snapshot(office: Office, simulation: DepartmentSimulation) -> Dictionary:
	return office.call("_first_clutch_coach_snapshot", simulation.snapshot()) as Dictionary


func _different_lane(specialty: StringName) -> StringName:
	for lane in [&"nest_damage", &"predator_loss", &"appeals"]:
		if lane != specialty:
			return lane
	return &"auto"


func _saved_first_clutch(store: CampaignSaveStore) -> Dictionary:
	var envelope := store.load()
	var payload := envelope.get("campaign", {}) as Dictionary
	var session := payload.get("session", {}) as Dictionary
	return (session.get("first_clutch", {}) as Dictionary).duplicate(true)


func _checkpoint_reason(store: CampaignSaveStore) -> String:
	return String((store.load().get("metadata", {}) as Dictionary).get("reason", ""))


func _same_persisted_state(actual: Dictionary, expected: Dictionary) -> bool:
	for field in PERSISTED_FIELDS:
		if actual.get(field) != expected.get(field):
			return false
	return true


func _press(button: Button) -> bool:
	if button == null or button.disabled:
		return false
	button.pressed.emit()
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
