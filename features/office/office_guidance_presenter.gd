class_name OfficeGuidancePresenter
extends RefCounted

## Contextual guidance strip: next-step hints derived from live state.
## Holds no state of its own: every read and write goes through the owning
## Office so behaviour is identical to the original in-class methods.

var office: Office


func _init(owner_node: Office) -> void:
	office = owner_node

func _flockwatch_context_primary_action_state() -> Dictionary:
	if not office._flockwatch_open or office._flockwatch_navigation == null:
		return {}
	return office._flockwatch_navigation.context_primary_action_state()


func _set_guidance(
	copy: String,
	icon_kind: StringName = &"goal",
	exact_detail: String = "",
	action_id: StringName = &"",
) -> void:
	if office._guidance_label == null:
		return
	# Before PLAN is introduced, playbook prompts become a plain progress cue so
	# the opening shift never points at a control the player cannot see.
	if action_id == &"playbook" and not office._feature_introduced(&"plan_menu"):
		var to_go := maxi(0, office._simulation.quota_target - office._simulation.eggs_today)
		copy = "TARGET MET · HENS AUTO-WORK" if to_go == 0 else "%d EGGS TO GO · HENS AUTO-WORK" % to_go
		exact_detail = "Keep routing files and Priority Pecking. More management tools arrive on later shifts."
		action_id = &""
	# Only optional playbook prompts wait. Decisions, rescue and pause cues bypass
	# this filter, and the player can still open PLAN at any time.
	if action_id == &"playbook" and Time.get_ticks_msec() < office._payoff_quiet_until_msec and office._active_playbook_button != null and String(office._active_playbook_button.get_meta("opportunity", "")) not in ["rescue", "reward"]:
		var remaining := maxi(0, office._simulation.quota_target - office._simulation.eggs_today)
		copy = "TARGET MET · REWARD FILED" if copy.begins_with("TARGET MET") or remaining == 0 else "%d EGGS TO GO · HENS AUTO-WORK" % remaining
		exact_detail = "Your reward is filed. Hens keep working automatically. PLAN remains available whenever you want it."
		action_id = &""
		if office._clock != null and office._clock.speed_index == 0 and not office._blocking_management_surface_open():
			copy = "FILED · RESUME WHEN READY"
			exact_detail = "Your action is filed, but time is still paused. Resume when ready; nothing else must be purchased."
			action_id = &"resume_shift"
	var detail := exact_detail if not exact_detail.is_empty() else copy
	office._guidance_action_id = action_id
	office._guidance_label.text = copy
	# The button owns the available width. Changing copy must not push nearby
	# controls sideways, nor remeasure font strings on every simulation tick.
	office._guidance_label.custom_minimum_size.x = 0.0
	office._guidance_label.tooltip_text = detail
	office._guidance_label.set_meta("accessible_text", detail)
	# Navigation and pause-planning cues are one compact destination, not a
	# consequence receipt. Retire the three-icon outcome strip so its chevron
	# stays visually attached to the action label.
	if office._consequence_icon_host != null:
		if office._compact_physical_hud or office._explain_strip == null or not office._explain_strip.visible or action_id in [&"today", &"resume_shift"]:
			office._consequence_icon_host.visible = false
		else:
			office._consequence_icon_host.visible = int(
				office._consequence_icon_host.get_meta("icon_count", 0),
			) == 3
	if office._guidance_icon != null:
		office._guidance_icon.configure(icon_kind, Color("d9c47d"))
		office._guidance_icon.tooltip_text = detail
		office._guidance_icon.set_meta("semantic_icon", String(icon_kind))
		office._guidance_icon.set_meta("accessible_text", detail)
	if office._guidance_action_button != null:
		var actionable := action_id != &""
		office._guidance_action_button.disabled = not actionable
		office._guidance_action_button.focus_mode = (
			Control.FOCUS_ALL if actionable else Control.FOCUS_NONE
		)
		office._guidance_action_button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if actionable else Control.CURSOR_ARROW
		)
		var activation_contract := _guidance_activation_contract(action_id)
		var activation_hint := String(activation_contract.get("hint", ""))
		office._guidance_action_button.tooltip_text = (
			"%s\n%s" % [detail, activation_hint]
			if actionable else detail
		)
		office._guidance_action_button.set_meta("guidance_action_id", String(action_id))
		office._guidance_action_button.set_meta(
			"activation_behavior",
			String(activation_contract.get("behavior", "none")),
		)
		office._guidance_action_button.set_meta(
			"accessible_text",
			"%s %s" % [
				detail,
				activation_hint if actionable else "",
			],
		)
		if office._guidance_action_chevron != null:
			office._guidance_action_chevron.visible = actionable and not office._compact_physical_hud


## Global guidance sometimes performs the named action and sometimes only moves
## focus to the safe control that can perform it. Publish that distinction so
## keyboard, controller, browser, and assistive users are never promised a
## mutation when activation only changes focus.
func _guidance_activation_contract(action_id: StringName) -> Dictionary:
	if action_id in [
		&"review",
		&"adaptive_route_recovery",
		&"campaign_milestone",
		&"campaign_report_continue",
		&"campaign_contract_offer",
		&"campaign_contract_sign",
		&"campaign_contract_decline",
		&"campaign_contract_continue",
		&"campaign_final_continue",
		&"campaign_final_retry",
		&"flockwatch_context_action",
		&"feed",
	]:
		return {
			"behavior": "focus_target",
			"hint": "Activate to focus the next safe control; activate that control to continue.",
		}
	match action_id:
		&"":
			return {"behavior": "none", "hint": ""}
		&"peck":
			return {
				"behavior": "execute",
				"hint": "Activate to use Priority Peck now.",
			}
		&"playbook":
			return {
				"behavior": "choose",
				"hint": "Activate to compare Fast, Safe, and Flock plans; no plan is filed until you choose one.",
			}
		&"resume_shift":
			return {
				"behavior": "execute",
				"hint": "Activate to resume at 1× and file any queued routes.",
			}
		&"decision":
			return {
				"behavior": "focus_target",
				"hint": "Activate to focus the next safe decision control; activate that control to continue.",
			}
		&"first_clutch":
			return {
				"behavior": "contextual",
				"hint": "Activate to continue the current First Clutch step.",
			}
		&"campaign_order_driver":
			return {
				"behavior": "navigate",
				"hint": "Activate to open this driver; no choice is filed automatically.",
			}
		&"select_hen":
			return {
				"behavior": "navigate",
				"hint": "Activate to focus the relevant hen.",
			}
		_:
			return {
				"behavior": "navigate",
				"hint": "Activate to open or focus this action.",
			}


func _focus_guidance_hen() -> void:
	if office._flockwatch_open:
		office._set_flockwatch_open(false)
	if office._camera_controller == null:
		return
	var worker_id := office._routing_ui.focused_worker_id() if office._routing_ui != null else -1
	if worker_id >= 0:
		office._camera_controller.focus_worker(worker_id)
	else:
		office._camera_controller.cycle_worker(1)


func _update_guidance(snapshot: Dictionary) -> void:
	if office._guidance_label == null:
		return
	if office._campaign_ui != null and office._campaign_ui.is_modal_open():
		var campaign_action := office._campaign_modal_primary_action_state()
		if not campaign_action.is_empty():
			office._set_guidance(
				String(campaign_action.get("copy", "NEXT: CHOOSE DIFFICULTY")),
				StringName(String(campaign_action.get("semantic_icon", "goal"))),
				String(campaign_action.get(
					"accessible_text",
					"Complete the highlighted campaign action.",
				)),
				StringName(String(campaign_action.get("action_id", ""))),
			)
			return
		var open_file := "%s FILE OPEN: complete the highlighted management action." % (
			"SENIOR ROOST" if office._campaign_senior_roost else "PROBATION"
		)
		office._set_guidance("DECIDE: FINISH THE HIGHLIGHTED ACTION", &"goal", open_file)
		return
	var flockwatch_action := office._flockwatch_context_primary_action_state()
	if not flockwatch_action.is_empty():
		office._set_guidance(
			String(flockwatch_action.get("copy", "CONTINUE")),
			StringName(String(flockwatch_action.get("semantic_icon", "advance_arrow"))),
			String(flockwatch_action.get(
				"accessible_text",
				"Complete the required Flockwatch filing when ready.",
			)),
			&"flockwatch_context_action",
		)
		return
	if office._decision_host != null and office._decision_host.visible:
		var decision_action := office._decision_primary_action_state()
		office._set_guidance(
			String(decision_action.get("copy", "CHOOSE A RESPONSE")),
			StringName(String(decision_action.get("semantic_icon", "shield"))),
			String(decision_action.get(
				"accessible_text",
				"Review one response, then authorize it.",
			)),
			&"decision",
		)
		return
	if office._day_review_scrim != null and office._day_review_scrim.visible:
		office._set_guidance(
			"REVIEW: RESULTS, THEN REINVEST",
			&"files",
			"Shift complete: review the exact results and choose how to invest.",
			&"review",
		)
		return
	if office._farmer_relations_gallery_offer_open(snapshot):
		office._set_guidance(
			"CREDIT: PUBLISH A CAMPAIGN / OR SKIP",
			&"cash",
			"Closing credit filed: publish one Gallery campaign or continue to skip.",
			&"records",
		)
		return
	var shift_phase := int(snapshot.get("shift_phase", DepartmentSimulation.ShiftPhase.RUNNING))
	if shift_phase == DepartmentSimulation.ShiftPhase.REVIEW:
		var review_action := office._apply_review_progression_action(snapshot)
		office._set_guidance(
			String(review_action.get("guidance_copy", "NEXT: REQUISITION OR SHIFT RESULTS")),
			&"flock" if bool(snapshot.get("credit_memo_pending", false)) else &"goal",
			String(review_action.get(
				"guidance_detail",
				"Approve any requisitions, then file this shift's results before tomorrow's policy.",
			)),
			&"records" if bool(snapshot.get("credit_memo_pending", false)) else &"capital",
		)
		return
	if shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE:
		if office._first_hen_prelude_pending():
			var first_hen := office._first_clutch_worker_snapshot(
				snapshot,
				int(office._first_clutch.get("target_worker_id", Office.FIRST_HEN_WORKER_ID)),
			)
			var first_hen_name := String(first_hen.get("name", "Mabel")).to_upper()
			office._set_guidance(
				"OPEN %s'S FILE" % first_hen_name,
				&"files",
				"First Clutch: open %s's file before choosing the flock policy." % first_hen_name,
				&"first_hen",
			)
			return
		office._set_guidance(
			"DECIDE: CHOOSE ONE MORNING POLICY",
			&"goal",
			"Authorize one morning policy before the shift clock can run.",
			&"decision",
		)
		return
	if shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
		office._set_guidance(
			"INCIDENT: CHOOSE A RESPONSE",
			&"shield",
			"Incident response required: the shift clock is safely locked.",
			&"decision",
		)
		return
	if office._feed_party_active:
		office._set_guidance(
			"FEED PARTY IN PROGRESS",
			&"flock",
			"Production is paused while Feed Party attendance is documented.",
		)
		return
	var first_clutch_coach := office._first_clutch_coach_snapshot(snapshot)
	if bool(first_clutch_coach.get("visible", false)):
		var coach_title := String(first_clutch_coach.get("title", "FOLLOW THE ACTIVE HEN"))
		var coach_detail := String(first_clutch_coach.get("guidance", coach_title))
		office._set_guidance(
			String(first_clutch_coach.get("visual_title", coach_title)).to_upper(),
			&"egg",
			coach_detail,
			&"first_clutch",
		)
		return
	if bool(first_clutch_coach.get("orders_handoff_pending", false)):
		var orders_detail := (
			"First Clutch complete: review today's three probation orders in Flockwatch."
			if office._flockwatch_open else
			"First Clutch complete: press %s to open today's three probation orders." % office._action_hint(&"toggle_flockwatch")
		)
		office._set_guidance(
			(
				"ORDERS READY  >  REVIEW TODAY"
				if office._flockwatch_open else
				"ORDERS READY  >  OPEN  [%s]" % office._action_hint(&"toggle_flockwatch")
			),
			&"goal",
			orders_detail,
			&"today",
		)
		return
	var tactical_plan := office._tactical_route_plan_snapshot()
	if (
		shift_phase == DepartmentSimulation.ShiftPhase.RUNNING
		and office._clock != null
		and office._clock.speed_index == 0
		and int(tactical_plan.get("count", 0)) > 0
	):
		office._set_guidance(
			"PLAN %d/%d  >  RESUME TO FILE" % [
				int(tactical_plan.get("count", 0)),
				int(tactical_plan.get("capacity", Office.TacticalRoutePlannerScript.CAPACITY)),
			],
			&"route",
			"Queued routes are previews only. Resume at 1×, 3×, or 10× to file the batch; use a queued hen's Undo action to remove her preview.",
			&"resume_shift",
		)
		return
	if shift_phase == DepartmentSimulation.ShiftPhase.RUNNING and not office._routing_return_cue.is_empty():
		office._set_guidance(
			String(office._routing_return_cue.get("copy", "ROUTING RECORD")),
			&"files",
			String(office._routing_return_cue.get("accessible_text", "Choose an intake tray to resume routing.")),
			&"routing_chase",
		)
		return
	if not office._campaign_order_return_cue.is_empty():
		if (
			StringName(office._campaign_order_return_cue.get("driver_action_id", &"")) == &"hen_routes"
			and office._routing_ui != null
			and office._routing_ui.active_dossier_tab() == &"route"
		):
			var route_worker_id := office._routing_ui.focused_worker_id()
			var route_worker := office._worker_record(snapshot, route_worker_id)
			var route_worker_name := String(route_worker.get("name", "HEN")).to_upper()
			var route_fit := office._dispatch_lane_label(StringName(route_worker.get(
				"specialty",
				&"auto",
			)))
			var route_undo := office._validated_routing_assignment_undo(snapshot)
			var route_was_set := (
				not route_undo.is_empty()
				and int(route_undo.get("worker_id", -1)) == route_worker_id
			)
			if route_was_set:
				var current_lane := StringName(route_undo.get("current_lane", &"auto"))
				var current_route := (
					"AUTO"
					if current_lane == &"auto" else
					office._dispatch_lane_label(current_lane)
				)
				var route_set_detail := (
					"%s's next tray is now %s. Current files finish before the new tray applies. "
					+ "Undo restores the prior route without rolling back completed work. "
					+ "Press %s or activate Return to Goal to restore the exact Today order."
				) % [
					route_worker_name,
					current_route,
					office._action_hint(&"toggle_flockwatch"),
				]
				office._set_guidance(
					(
						"%s SET  >  RESUME 1×" % current_route
						if office._clock != null and office._clock.speed_index == 0 else
						"%s SET  >  WATCH NEXT FILE" % current_route
					),
					&"files",
					route_set_detail,
					&"resume_shift" if office._clock != null and office._clock.speed_index == 0 else &"",
				)
				return
			office._set_guidance(
				"ROUTE %s  >  %s FIT / AUTO" % [route_worker_name, route_fit],
				&"files",
				(
					"Choose %s's route from the visible dossier. %s is her specialty fit for faster, safer work; Auto favors specialty and deadlines. "
					+ "Press %s or activate Return to Goal to restore the exact Today order; no route is filed by returning."
				) % [route_worker_name, route_fit, office._action_hint(&"toggle_flockwatch")],
			)
			return
		office._set_guidance(
			String(office._campaign_order_return_cue.get("copy", "RETURN: TODAY'S GOAL")),
			StringName(office._campaign_order_return_cue.get("icon_kind", &"goal")),
			String(office._campaign_order_return_cue.get(
				"accessible_text",
				"Return to the originating Flockwatch goal without filing a choice.",
			)),
			&"campaign_order_return",
		)
		return
	if (
		office._flockwatch_open
		and office._flockwatch_navigation != null
		and office._flockwatch_navigation.current_page_id() == FlockwatchNavigation.PAGE_TODAY
		and office._campaign_order_driver_button != null
		and office._campaign_order_driver_button.is_visible_in_tree()
		and not office._campaign_order_driver_action.is_empty()
	):
		var driver_label := String(office._campaign_order_driver_action.get(
			"label",
			"SHOW DRIVER",
		)).to_upper()
		office._set_guidance(
			"ORDER PICKED  >  %s" % driver_label,
			StringName(office._campaign_order_driver_action.get("icon_kind", &"goal")),
			String(office._campaign_order_driver_button.get_meta(
				"accessible_text",
				"The selected order now exposes the live control that most directly affects it.",
			)),
			&"campaign_order_driver",
		)
		return
	var eggs := int(snapshot.get("eggs_today", 0))
	var quota := maxi(1, int(snapshot.get("quota_target", 1)))
	# Optional contracts and route advice cannot conceal the action needed to
	# restart production. Explicit goal-return and tactical-plan cues stay above.
	if office._clock.speed_index == 0:
		office._set_guidance(
			"SELECT A HEN" if office._flockwatch_open else "RESUME SHIFT  ·  %s" % office._action_hint(&"pause_simulation"),
			&"pause",
			"While paused, close Flockwatch and inspect a hen before resuming." if office._flockwatch_open else "Resume to let hens finish files and collect eggs automatically. You can adjust routes while paused.",
			&"select_hen" if office._flockwatch_open else &"resume_shift",
		)
		return
	var contract_guidance := _active_market_contract_guidance(snapshot)
	if not contract_guidance.is_empty():
		office._set_guidance(contract_guidance, &"goal", contract_guidance, &"records")
		return
	var adaptive_route := office._adaptive_route_recovery_diagnostic_state()
	if bool(adaptive_route.get("active", false)):
		var recovery_worker := String(adaptive_route.get("worker_name", "HEN")).to_upper()
		var recovery_specialty := String(adaptive_route.get("specialty_label", "FIT")).to_upper()
		var recovery_detail := (
			"Two consecutive manual routes were outside filed specialties. "
			+ "Open %s's route and choose %s or Auto if that was unintended; deliberate routes remain valid."
		) % [recovery_worker, recovery_specialty]
		office._set_guidance(
			(
				"RESTORE %s'S FIT  >  %s" % [recovery_worker, recovery_specialty]
				if String(adaptive_route.get("guidance_mode", "full")) == "essential" else
				"OUT-OF-FIT x%d  >  REVIEW %s" % [
					int(adaptive_route.get("miss_streak", Office.ADAPTIVE_ROUTE_MISS_THRESHOLD)),
					recovery_worker,
				]
			),
			&"files",
			recovery_detail,
			&"adaptive_route_recovery",
		)
		return
	if office._clock.precision_focus_limiting():
		var last_assist := snapshot.get("last_peck_assist", {}) as Dictionary
		if (
			office._priority_peck_result_hold_kind == &"missed"
			and Time.get_ticks_msec() < office._priority_peck_result_hold_until_msec
		):
			office._set_guidance(
				"MISSED  ·  NEXT FILE",
				&"urgent",
				"Priority Peck closed on this file. The next file restarts the chain; %d× resumes after this brief result beat." % int(SimulationClock.SPEED_MULTIPLIERS[office._clock.speed_index]),
			)
			return
		if (
			Time.get_ticks_msec() < office._priority_peck_result_hold_until_msec
			and int(last_assist.get("claim_id", -1)) == office._priority_peck_result_hold_claim_id
		):
			var landed_detail := "Priority Peck landed: %s  ·  +%d%% file  ·  chain x%d  ·  %d× resumes after the result beat" % [
				String(last_assist.get("rating", "steady")).to_upper(),
				int(roundf(float(last_assist.get("progress_gain", 0.0)))),
				int(last_assist.get("streak", 0)),
				int(SimulationClock.SPEED_MULTIPLIERS[office._clock.speed_index]),
			]
			office._set_guidance(
				"PECK LANDED: +%d%%  CHAIN ×%d" % [
					int(roundf(float(last_assist.get("progress_gain", 0.0)))),
					int(last_assist.get("streak", 0)),
				],
				&"egg",
				landed_detail,
			)
			return
		var focus := office._priority_peck_precision_candidate(snapshot)
		if not focus.is_empty():
			var requested_multiplier := int(SimulationClock.SPEED_MULTIPLIERS[office._clock.speed_index])
			if StringName(focus.get("window_state", &"")) == &"open":
				var open_detail := "Priority Focus 1×: %s  ·  %s  ·  press %s now; %d× resumes after this file window" % [
					String(focus.get("worker_name", "HEN")).to_upper(),
					String(focus.get("timing_label", "CLEAN RHYTHM")),
					office._action_hint(Office.PECK_ASSIST_ACTION),
					requested_multiplier,
				]
				office._set_guidance(
					"PRIORITY FOCUS 1×: %s  ·  PRESS %s" % [
						String(focus.get("worker_name", "HEN")).to_upper(),
						office._action_hint(Office.PECK_ASSIST_ACTION),
					],
					&"egg",
					open_detail,
					&"peck",
				)
			else:
				var waiting_detail := "Priority Focus 1×: %s at %d%%  ·  gold opens at %d%%  ·  %d× remains selected" % [
					String(focus.get("worker_name", "HEN")).to_upper(),
					int(focus.get("progress", 0)),
					int(focus.get("window_start", DepartmentSimulation.PECK_ASSIST_WINDOW_START)),
					requested_multiplier,
				]
				office._set_guidance(
					"PRIORITY FOCUS 1×: %s %d%%  ·  GOLD %d%%" % [
						String(focus.get("worker_name", "HEN")).to_upper(),
						int(focus.get("progress", 0)),
						int(focus.get("window_start", DepartmentSimulation.PECK_ASSIST_WINDOW_START)),
					],
					&"egg",
					waiting_detail,
				)
			return
	# Optional Peck windows stay in the hen dossier; they must not replace the shift goal.
	if eggs >= quota:
		if String(office._simulation.active_playbook.get("push_luck_id", "")).is_empty():
			office._set_guidance("TARGET MET · BANK OR CHASE", &"egg", "Your quota is met. Bank for safer shells or chase higher clean-egg value. Open Plan to compare and choose; this choice is optional.", &"playbook")
			return
		office._set_guidance(
			"TARGET MET: PROTECT SHELLS OR BANK FUND",
			&"shield",
			"The clutch target is met. Protect shell quality or bank extra Feed Fund.",
			&"today",
		)
		return
	var remaining := quota - eggs
	var minutes_left := maxi(0, DepartmentSimulation.SHIFT_END_MINUTE - int(snapshot.get("minute_of_day", 0)))
	var worker_data: Array = []
	for worker_value in snapshot.get("workers", []):
		var worker := worker_value as Dictionary
		if office._is_worker_employed(worker):
			worker_data.append(worker)
	var average_stress := 0.0
	for worker_value in worker_data:
		average_stress += float((worker_value as Dictionary).get("stress", 0.0))
	average_stress /= maxf(1.0, float(worker_data.size()))
	if average_stress >= 65.0 and not bool(snapshot.get("feed_party_used_today", false)):
		office._set_guidance(
			"FLOCK TIRED: CONSIDER A FEED PARTY",
			&"flock",
			"Flock strain is high. Consider one Feed Party before cracks climb.",
			&"feed",
		)
	else:
		office._set_guidance(
			"%d EGGS TO GO  ·  HENS AUTO-WORK" % remaining,
			&"egg",
			"Hens finish routed files and collect eggs automatically. %d eggs needed; %dh %02dm left. Optional: use Plan to trade speed, shell quality, or welfare." % [remaining, minutes_left / 60, minutes_left % 60],
		)


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
	var earliest_due := Office.SHIFT_END_FALLBACK_MINUTE
	var earliest_arrival := Office.SHIFT_END_FALLBACK_MINUTE
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
		var arrival_minute := int(schedule.get("arrival_minute_of_day", Office.SHIFT_END_FALLBACK_MINUTE))
		var deadline_minute := int(schedule.get("deadline_minute_of_day", Office.SHIFT_END_FALLBACK_MINUTE))
		if released and claim_id not in completed_ids and deadline_minute < earliest_due:
			earliest_due = deadline_minute
			due_time = String(schedule.get("deadline_time", office._office_clock_label(deadline_minute)))
		elif not released and arrival_minute >= current_minute and arrival_minute < earliest_arrival:
			earliest_arrival = arrival_minute
			arrival_time = String(schedule.get("arrival_time", office._office_clock_label(arrival_minute)))
	if not due_time.is_empty():
		return {"label": "NEXT DUE", "time": due_time}
	if not arrival_time.is_empty():
		return {"label": "NEXT ARRIVAL", "time": arrival_time}
	return {}


func _capture_adaptive_routing_guidance_preview() -> void:
	office._ensure_preview_runner()
	await office._preview_runner.call("_capture_adaptive_routing_guidance_preview")
