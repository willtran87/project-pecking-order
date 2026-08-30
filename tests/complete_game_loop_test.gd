extends SceneTree

const FunnelScript := preload("res://core/experience/first_session_funnel.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var funnel := FunnelScript.new() as FirstSessionFunnel
	funnel.begin_intake(1_000)
	funnel.begin_new_file(2_000)
	funnel.observe({}, {"inspected": true, "specialty_routed": true}, &"active", 12_000)
	funnel.observe({}, {"assisted_claim_id": 7}, &"active", 22_000)
	funnel.observe({"eggs_today": 1}, {}, &"active", 32_000)
	var funnel_snapshot := funnel.snapshot(32_000)
	var micro := funnel_snapshot.get("micro_shift", {}) as Dictionary
	_check(
		int(micro.get("budget_seconds", 0)) == 60
		and int(micro.get("beat_count", 0)) == 4
		and int(micro.get("completed_count", 0)) == 4
		and bool(micro.get("complete", false))
		and int(micro.get("retired_label_count", 0)) == 4,
		"the local first-session funnel should resolve plan, route, react, and reward inside one 60-second micro-shift contract",
		failures,
	)

	var director := GameplayPulseDirector.new()
	var playbook := {
		"authoritative": true,
		"strategy_preset_id": "safe",
		"strategy_preset": {"label": "SAFE PLAN", "gain": "SHELL RISK -4%", "cost": "PACE -3%", "risk": "SMALLER BUFFER"},
		"recommended_preset_id": "safe",
		"contract": {"id": "clean_carton", "label": "CLEAN CARTON", "progress": 2, "target": 3, "complete": false},
		"combo": {"label": "SHELL SEAL", "progress": 1, "target": 2, "active": true},
		"combo_recipe": {"label": "SHELL SEAL", "completed_steps": 1, "total_steps": 2, "effect": "SHELL RISK -1.5%"},
		"strategy_mastery": {"tier": "TAKING SHAPE", "marks": 1},
		"dominant_objective": {"single": true, "label": "ROUTE THE APPEAL", "ghost_path": ["FILE", "HEN", "RESULT"]},
		"display_sockets": [],
		"next_shift_preview": {"one_more_shift": true, "label": "THE LATE CARTON"},
		"relationship_echo": {"last_move": "TEAM LIFT"},
		"shift_journey": [
			{"id": "plan", "label": "PLAN", "icon": "goal", "state": "complete"},
			{"id": "work", "label": "WORK", "icon": "route", "state": "current"},
			{"id": "respond", "label": "RESPOND", "icon": "shield", "state": "upcoming"},
			{"id": "reward", "label": "REWARD", "icon": "egg", "state": "upcoming"},
		],
		"options": [],
		"choice_budget": {"major": 1, "optional": 1, "surprise": 1},
	}
	var simulation := {
		"day": 2,
		"shift_phase": 1,
		"minute_of_day": 950,
		"eggs_today": 6,
		"quota_target": 8,
		"claims_processed": 4,
		"cracked_today": 0,
		"credited_today_cents": 840,
		"quality_streak": 3,
		"routing_momentum": {"chain": 2, "next_milestone": 3, "next_reward": "GOLDEN WINDOW"},
		"workers": [{
			"id": 0,
			"name": "Mabel",
			"employed": true,
			"morale": 78.0,
			"stress": 36.0,
			"preferred_personnel_action": &"share_credit",
			"flock_bond": {"partner_id": 1, "partner_name": "Pip", "score": 76, "label": "TRUSTED", "summary": "They cover one another's perch."},
			"hen_intent": {"urgency": 2, "label": "FINISH THE APPEAL"},
			"personal_mastery": {"stage": "TRUSTED LAYER"},
		}],
		"personnel_catalog": [],
	}
	var pulse := director.compose({
		"simulation": simulation,
		"next_action": {"action_id": "route", "copy": "ROUTE THE APPEAL", "visible_label": "ROUTE APPEAL", "actionable": true},
		"routing_lifecycle": {},
		"action_feedback": {"visible": true, "title": "SAFE PLAN FILED", "entries": [{"copy": "RISK -4%"}]},
		"momentum_brief": {},
		"rival": {"name": "BARN EAST", "difference": -2, "standing": "behind"},
		"first_session_funnel": funnel_snapshot,
		"adaptive": {},
		"chapter": {},
		"order_pulse": {"on_track": 2, "total": 3},
		"focused_worker_id": 0,
		"active_playbook": playbook,
	})
	var complete_loop := pulse.get("complete_game_loop", {}) as Dictionary
	var rhythm := complete_loop.get("shift_rhythm", {}) as Dictionary
	var explain := complete_loop.get("explain_mode", {}) as Dictionary
	var story := complete_loop.get("emergent_story", {}) as Dictionary
	_check(
		int(pulse.get("version", 0)) == 11
		and int(complete_loop.get("item_count", 0)) == 24
		and bool(complete_loop.get("all_resolved", false))
		and String(rhythm.get("stage", "")) == "final_push"
		and bool(rhythm.get("one_primary_pulse", false)),
		"the complete loop should resolve all 24 findings and publish one readable final-push urgency signal",
		failures,
	)
	_check(
		int(explain.get("chip_count", 0)) == 4
		and bool(explain.get("pauses_while_held", false))
		and (explain.get("chips", []) as Array).size() == 4
		and int(story.get("beat_count", 0)) == 3
		and String(story.get("worker_name", "")) == "MABEL",
		"hold-to-explain and the emergent worker episode should stay compact, physical, and personal",
		failures,
	)

	var report := director.compose_report({
		"eggs": 9,
		"quota": 8,
		"met_quota": true,
		"cracked": 1,
		"credited_cents": 1200,
		"operating_cost_cents": 760,
		"next_quota": 10,
	})
	_check(
		int(report.get("card_count", 0)) == 3
		and (report.get("cards", []) as Array).size() == 3
		and String(((report.get("cards", []) as Array)[0] as Dictionary).get("label", "")) == "WHAT WORKED"
		and String(((report.get("cards", []) as Array)[1] as Dictionary).get("label", "")) == "CLOSE CALL"
		and String(((report.get("cards", []) as Array)[2] as Dictionary).get("label", "")) == "WHAT CHANGED"
		and int(report.get("next_target", 0)) == 10,
		"the folded shift report should communicate worked, close call, changed, and next without duplicating the accounting ledger",
		failures,
	)

	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var explain_strip := office.find_child("HoldToExplainStrip", true, false) as PanelContainer
	var review_panel := office.find_child("DayReviewPanel", true, false) as PanelContainer
	var replay_button := office.find_child("ReviewReplayHighlightButton", true, false) as Button
	var remix_button := office.find_child("ReviewRemixNextButton", true, false) as Button
	var office_simulation := office.get("_simulation") as DepartmentSimulation
	var workstation_feedback := office.get("_workstation_feedback") as WorkstationFeedback
	var replay_authority_before := office_simulation.export_save_state()
	office.set("_dispatch_last_receipt", {
		"worker_id": 0,
		"worker_name": office_simulation.workers[0].display_name,
		"lane": "appeals",
		"recommended": true,
		"momentum_chain": 1,
	})
	office.call("_play_last_cause_replay")
	await process_frame
	var live_cause_replay := office.get("_last_cause_replay") as Dictionary
	_check(
		bool(live_cause_replay.get("available", false))
		and bool(live_cause_replay.get("presentation_only", false))
		and bool(live_cause_replay.get("files_nothing", false))
		and workstation_feedback.active_dispatch_delivery_count() == 1
		and office_simulation.export_save_state() == replay_authority_before,
		"the live H replay path should launch one presentation-only folder without filing authority",
		failures,
	)
	await create_timer(0.9).timeout
	_check(
		workstation_feedback.active_dispatch_delivery_count() == 0
		and office_simulation.export_save_state() == replay_authority_before,
		"the presentation-only replay folder should clean itself up",
		failures,
	)
	office.call("_show_farmer_review", {
		"day": 1, "eggs": 9, "quota": 8, "met_quota": true,
		"cracked": 1, "golden": 0, "credited_cents": 1200,
		"operating_cost_cents": 760, "closing_fund_cents": 5440,
		"next_quota": 10, "pecking_order": [],
	}, false)
	var worked_caption := office.find_child("FarmerReviewEggsCaption", true, false) as Label
	var changed_caption := office.find_child("FarmerReviewNetCaption", true, false) as Label
	var call_caption := office.find_child("FarmerReviewFundCaption", true, false) as Label
	_check(
		explain_strip != null
		and bool(explain_strip.get_meta("hold_to_explain", false))
		and office.find_children("ExplainChip_*", "PanelContainer", true, false).size() == 4
		and InputMap.has_action(&"explain_mode"),
		"Office should build one hidden four-chip explain strip with a real H input action",
		failures,
	)
	_check(
		review_panel != null
		and int((review_panel.get_meta("three_card_report", {}) as Dictionary).get("card_count", 0)) == 3
		and worked_caption != null and worked_caption.text == "WHAT WORKED"
		and changed_caption != null and changed_caption.text == "WHAT CHANGED"
		and call_caption != null and call_caption.text == "CLOSE CALL"
		and replay_button != null and remix_button != null,
		"the actual farmer review should expose the three-card hierarchy and immediate replay/remix actions",
		failures,
	)
	office.queue_free()
	await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error("COMPLETE_GAME_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("COMPLETE_GAME_LOOP_TEST_PASSED first_shift=60s rhythm=6-stage explain=4-chip trails=world stories=3-beat report=3-card replay=fast items=24")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
