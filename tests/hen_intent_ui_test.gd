extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260801)
	_assert_intent_priorities(simulation, failures)
	_check(
		simulation.select_directive(&"shell_assurance"),
		"fixture should enter a running shift",
		failures,
	)
	var snapshot := simulation.snapshot()
	var workers := snapshot.get("workers", []) as Array
	_check(not workers.is_empty(), "running snapshot should include hens", failures)
	for worker_value in workers:
		var worker := worker_value as Dictionary
		if bool(worker.get("employed", false)):
			_check(
				not (worker.get("hen_intent", {}) as Dictionary).is_empty(),
				"every employed hen should publish one glanceable intent",
				failures,
			)

	var first_worker := (workers[0] as Dictionary).duplicate(true)
	first_worker["hen_intent"] = _intent(&"ready", &"ready", &"route", "SET ROUTE", 1)
	first_worker["progress"] = 44.0
	first_worker["current_claim"] = {"id": 88, "lane": &"nest_damage"}
	first_worker["flock_bond"] = {
		"partner_id": 1,
		"partner_name": "Pip",
		"score": 78,
		"label": "CLUTCHMATES",
	}
	var chicken := ChickenView.new()
	chicken.configure(first_worker)
	root.add_child(chicken)
	await process_frame
	var marker := chicken.find_child("HenIntentMarker", true, false) as Sprite3D
	var focus_halo := chicken.find_child("ManagementFocusHalo", true, false) as Sprite3D
	_check(
		marker != null and marker.visible and marker.texture != null,
		"ChickenView should render the authored no-text intent marker above the hen",
		failures,
	)
	_check(
		int(marker.get_meta("progress_bucket", -1)) == 3,
		"the world intent marker should communicate live file progress in five glanceable ring steps",
		failures,
	)
	_check(
		bool(marker.get_meta("compact", false))
		and is_equal_approx(marker.pixel_size, ChickenView.HEN_INTENT_READY_PIXEL_SIZE)
		and StringName(marker.get_meta("focus_role", &"")) == &"peer"
		and StringName(marker.get_meta("semantic_shape", &"")) == &"route_pin"
		and StringName(marker.get_meta("intent_id", &"")) == &"ready"
		and String(marker.get_meta("action_label", "")) == "SET ROUTE",
		"a low-urgency ready pin should use a slightly larger route-specific presentation while preserving its action semantics [compact=%s size=%.6f expected=%.6f intent=%s action=%s]" % [
			str(marker.get_meta("compact", false)),
			marker.pixel_size,
			ChickenView.HEN_INTENT_READY_PIXEL_SIZE,
			String(marker.get_meta("intent_id", &"")),
			String(marker.get_meta("action_label", "")),
		],
		failures,
	)
	chicken.set_management_focus(false, true)
	var peer_marker_height := marker.position.y
	_check(
		StringName(marker.get_meta("focus_role", &"")) == &"background"
		and is_equal_approx(
			marker.pixel_size,
			ChickenView.HEN_INTENT_READY_PIXEL_SIZE * ChickenView.HEN_INTENT_BACKGROUND_SCALE,
		)
		and is_equal_approx(marker.modulate.a, ChickenView.HEN_INTENT_BACKGROUND_ALPHA),
		"an unselected hen's routine pin should recede while another hen owns management focus",
		failures,
	)
	chicken.set_management_focus(true, true)
	_check(
		StringName(marker.get_meta("focus_role", &"")) == &"selected"
		and is_equal_approx(marker.pixel_size, ChickenView.HEN_INTENT_READY_PIXEL_SIZE)
		and is_equal_approx(marker.modulate.a, 1.0),
		"the selected hen's pin should retain full size and contrast",
		failures,
	)
	_check(
		is_equal_approx(
			marker.position.y,
			peer_marker_height + ChickenView.HEN_INTENT_SELECTED_HEIGHT_LIFT,
		),
		"the selected world pin should lift above the hen silhouette instead of covering her face",
		failures,
	)
	_check(
		focus_halo != null
		and focus_halo.visible
		and focus_halo.texture != null
		and is_equal_approx(focus_halo.position.y, marker.position.y)
		and focus_halo.pixel_size > marker.pixel_size
		and StringName(focus_halo.get_meta("semantic_role", &"")) == &"selected_hen"
		and int(focus_halo.get_meta("selected_worker_id", -1)) == int(first_worker.get("id", -2))
		and bool(marker.get_meta("selection_halo_visible", false)),
		"the selected hen should own one persistent no-text focus bracket behind her route pin",
		failures,
	)
	chicken.set_management_focus(false, false)
	_check(
		StringName(marker.get_meta("focus_role", &"")) == &"peer"
		and is_equal_approx(marker.pixel_size, ChickenView.HEN_INTENT_READY_PIXEL_SIZE)
		and is_equal_approx(marker.modulate.a, 1.0)
		and focus_halo != null and not focus_halo.visible
		and not bool(marker.get_meta("selection_halo_visible", true)),
		"office overview should restore equal pin weight across the flock",
		failures,
	)
	var second_worker := (workers[1] as Dictionary).duplicate(true)
	second_worker["hen_intent"] = _intent(&"ready", &"ready", &"route", "SET ROUTE", 1)
	second_worker["current_claim"] = {}
	var second_chicken := ChickenView.new()
	second_chicken.configure(second_worker)
	root.add_child(second_chicken)
	await process_frame
	var second_marker := second_chicken.find_child("HenIntentMarker", true, false) as Sprite3D
	_check(
		second_marker != null
		and second_marker.visible
		and second_marker.position.y > marker.position.y + 0.09
		and float(second_marker.get_meta("height_offset", -1.0)) > 0.0,
		"adjacent flock pins should use deterministic height staggering so clustered hens remain attributable",
		failures,
	)
	var bond_marker := chicken.find_child("FlockBondMarker", true, false) as Sprite3D
	_check(
		bond_marker != null
		and bond_marker.visible
		and bond_marker.texture != null
		and StringName(bond_marker.get_meta("signal_kind", &"")) == &"clutchmates",
		"a strong named perchmate bond should render as a separate no-text floor signal",
		failures,
	)
	_check(
		chicken.hen_intent_world_position().y > chicken.global_position.y + 1.5,
		"world marker should expose its own selection anchor above the hen",
		failures,
	)
	_check(
		StringName(chicken.hen_intent_snapshot().get("id", &"")) == &"ready",
		"ChickenView should expose the exact authoritative intent it renders",
		failures,
	)
	var world_transition_serial := int(marker.get_meta("intent_transition_serial", 0))
	first_worker["progress"] = 65.0
	chicken.apply_snapshot(first_worker)
	await process_frame
	_check(
		int(marker.get_meta("intent_transition_serial", 0)) == world_transition_serial,
		"progress-ring updates should not replay the semantic world-pin handoff",
		failures,
	)
	first_worker["hen_intent"] = _intent(&"sync", &"sync", &"peck", "SYNC PECK", 3)
	chicken.apply_snapshot(first_worker)
	await process_frame
	_check(
		int(marker.get_meta("intent_transition_serial", 0)) > world_transition_serial
		and StringName(marker.get_meta("semantic_shape", &"")) == &"work_dial"
		and bool(marker.get_meta("intent_transition_animated", false))
		and "ready" in String(marker.get_meta("intent_transition_from", ""))
		and "sync" in String(marker.get_meta("intent_transition_to", ""))
		and (
			not marker.scale.is_equal_approx(Vector3.ONE)
			or not marker.modulate.is_equal_approx(Color.WHITE)
		),
		"a same-hen semantic change should animate the world pin once with explicit old and new meaning (shape=%s serial=%d before=%d animated=%s from=%s to=%s scale=%s modulate=%s)" % [
			String(marker.get_meta("semantic_shape", &"")),
			int(marker.get_meta("intent_transition_serial", 0)),
			world_transition_serial,
			str(marker.get_meta("intent_transition_animated", false)),
			String(marker.get_meta("intent_transition_from", "")),
			String(marker.get_meta("intent_transition_to", "")),
			str(marker.scale),
			str(marker.modulate),
		],
		failures,
	)
	await create_timer(0.36).timeout
	_check(
		marker.scale.is_equal_approx(Vector3.ONE)
		and marker.modulate.is_equal_approx(Color.WHITE),
		"the world-pin handoff should settle fully without leaving scale or color residue",
		failures,
	)
	first_worker["hen_intent"] = _intent(&"delivery", &"delivery", &"route", "TRACK EGG", 1)
	first_worker["progress"] = 100.0
	chicken.apply_snapshot(first_worker)
	await process_frame
	_check(
		StringName(marker.get_meta("semantic_shape", &"")) == &"egg_receipt"
		and StringName(marker.get_meta("intent_id", &"")) == &"delivery"
		and String(marker.get_meta("action_label", "")) == "TRACK EGG"
		and is_equal_approx(marker.pixel_size, ChickenView.HEN_INTENT_DELIVERY_PIXEL_SIZE)
		and marker.texture != null,
		"laying should replace the work dial with one distinct egg receipt silhouette",
		failures,
	)
	first_worker["hen_intent"] = _intent(&"sync", &"sync", &"peck", "SYNC PECK", 3)
	first_worker["progress"] = 65.0
	chicken.apply_snapshot(first_worker)
	await process_frame
	var ready_halo := chicken.find_child("PriorityPeckReadyHalo", true, false) as Sprite3D
	var ready_serial := int(marker.get_meta("priority_peck_ready_serial", 0))
	_check(
		chicken.play_priority_peck_ready_feedback(),
		"an active hen pin should accept one world-space Priority Peck opportunity pulse",
		failures,
	)
	await process_frame
	_check(
		ready_halo != null
		and ready_halo.visible
		and int(marker.get_meta("priority_peck_ready_serial", 0)) == ready_serial + 1
		and bool(marker.get_meta("priority_peck_ready_animated", false))
		and bool(marker.get_meta("priority_peck_ready_active", false))
		and ready_halo.scale.x > 0.88,
		"the opportunity should expand one restrained gold halo behind the existing no-text pin",
		failures,
	)
	await create_timer(0.46).timeout
	_check(
		ready_halo != null
		and not ready_halo.visible
		and not bool(marker.get_meta("priority_peck_ready_active", true)),
		"the opportunity halo should retire completely after its bounded pulse",
		failures,
	)
	_check(
		chicken.stage_priority_peck_ready_capture()
		and ready_halo != null
		and ready_halo.visible
		and bool(marker.get_meta("priority_peck_ready_capture_staged", false)),
		"the screenshot fixture should hold the authored halo midpoint without changing live timing",
		failures,
	)
	var missed_serial := int(marker.get_meta("priority_peck_missed_serial", 0))
	_check(
		chicken.play_priority_peck_missed_feedback(),
		"an observed closing boundary should accept one world-space missed-window retreat",
		failures,
	)
	await process_frame
	_check(
		ready_halo != null
		and ready_halo.visible
		and int(marker.get_meta("priority_peck_missed_serial", 0)) == missed_serial + 1
		and bool(marker.get_meta("priority_peck_missed_animated", false))
		and bool(marker.get_meta("priority_peck_missed_active", false))
		and ready_halo.scale.x < 1.34,
		"the missed opportunity should contract one broken ring behind the existing pin",
		failures,
	)
	await create_timer(0.50).timeout
	_check(
		ready_halo != null
		and not ready_halo.visible
		and not bool(marker.get_meta("priority_peck_missed_active", true)),
		"the missed-window retreat should settle completely without residue",
		failures,
	)
	_check(
		chicken.stage_priority_peck_missed_capture()
		and ready_halo != null
		and ready_halo.visible
		and bool(marker.get_meta("priority_peck_missed_capture_staged", false)),
		"the screenshot fixture should hold the real broken-ring retreat midpoint",
		failures,
	)
	chicken.set_reduced_motion(true)
	ready_serial = int(marker.get_meta("priority_peck_ready_serial", 0))
	_check(
		not chicken.play_priority_peck_ready_feedback()
		and int(marker.get_meta("priority_peck_ready_serial", 0)) == ready_serial + 1
		and not bool(marker.get_meta("priority_peck_ready_animated", true))
		and ready_halo != null
		and not ready_halo.visible,
		"reduced motion should retain the urgent sync icon without animating its opportunity halo",
		failures,
	)
	missed_serial = int(marker.get_meta("priority_peck_missed_serial", 0))
	_check(
		not chicken.play_priority_peck_missed_feedback()
		and int(marker.get_meta("priority_peck_missed_serial", 0)) == missed_serial + 1
		and not bool(marker.get_meta("priority_peck_missed_animated", true))
		and ready_halo != null
		and not ready_halo.visible,
		"reduced motion should preserve the stable missed state without animating the retreat",
		failures,
	)
	first_worker["hen_intent"] = _intent(&"care", &"care", &"support", "CHECK IN", 2)
	chicken.apply_snapshot(first_worker)
	await process_frame
	_check(
		not bool(marker.get_meta("intent_transition_animated", true))
		and marker.scale.is_equal_approx(Vector3.ONE)
		and marker.modulate.is_equal_approx(Color.WHITE),
		"reduced motion should preserve the world-pin semantic swap without animating it",
		failures,
	)
	chicken.set_reduced_motion(false)
	first_worker["hen_intent"] = {}
	first_worker["flock_bond"] = {"score": 50, "label": "PROFESSIONAL"}
	chicken.apply_snapshot(first_worker)
	_check(marker != null and not marker.visible, "empty intent should hide the world marker", failures)
	_check(
		bond_marker != null and not bond_marker.visible,
		"ordinary professional bonds should stay quiet instead of cluttering the floor",
		failures,
	)

	var routing_ui := PeckworkRoutingUI.new()
	root.add_child(routing_ui)
	await process_frame
	var ui_snapshot := snapshot.duplicate(true)
	var ui_workers := (workers as Array).duplicate(true)
	var ui_worker := (ui_workers[0] as Dictionary).duplicate(true)
	ui_worker["hen_intent"] = _intent(&"care", &"care", &"support", "CHECK IN", 2)
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	routing_ui.call("_on_dossier_tab_pressed", &"route")
	routing_ui.apply_snapshot(ui_snapshot)
	routing_ui.set_focus(int(ui_worker.get("id", 0)))
	await process_frame
	var intent_button := routing_ui.find_child("HenIntentAction", true, false) as Button
	_check(
		intent_button != null
		and intent_button.is_visible_in_tree()
		and intent_button.icon != null
		and "CHECK IN" in intent_button.text
		and not intent_button.text.begins_with("+")
		and StringName(intent_button.get_meta("intent_icon", &"")) == &"care"
		and _contains_all(
			String(intent_button.get_meta("accessible_text", "")),
			["CHECK IN", "needs attention"],
		)
		and "needs attention" in intent_button.tooltip_text,
		"selected dossier should expose one icon-led short action while preserving its full explanation",
		failures,
	)
	if intent_button != null:
		intent_button.pressed.emit()
	await process_frame
	_check(
		routing_ui.active_dossier_tab() == &"support",
		"care intent should open the existing safe Support actions without auto-filing one",
		failures,
	)
	var intent_variants: Array[Dictionary] = [
		_intent(&"sync", &"sync", &"peck", "SYNC PECK", 3),
		_intent(&"deadline", &"urgent", &"claim", "OPEN FILE", 3),
		_intent(&"care", &"care", &"support", "CHECK IN", 2),
		_intent(&"choice", &"choice", &"claim", "CHOOSE OUTCOME", 2),
		_intent(&"match", &"match", &"claim", "GOOD MATCH", 1),
		_intent(&"ready", &"ready", &"route", "SET ROUTE", 1),
		_intent(&"steady", &"steady", &"claim", "TRACK FILE", 1),
		_intent(&"delivery", &"delivery", &"route", "TRACK EGG", 1),
	]
	var presented_texture_ids: Dictionary[int, bool] = {}
	for variant: Dictionary in intent_variants:
		ui_worker["hen_intent"] = variant
		ui_workers[0] = ui_worker
		ui_snapshot["workers"] = ui_workers
		routing_ui.apply_snapshot(ui_snapshot)
		routing_ui.set_focus(int(ui_worker.get("id", 0)))
		await process_frame
		var presented_icon := intent_button.icon if intent_button != null else null
		if presented_icon != null:
			presented_texture_ids[presented_icon.get_instance_id()] = true
		var expected_visual_label := (
			"OUTCOME <55%"
			if StringName(variant.get("id", &"")) == &"choice" else
			String(variant.get("action_label", ""))
		)
		_check(
			intent_button != null
			and presented_icon != null
			and StringName(intent_button.get_meta("intent_icon", &"")) == StringName(variant.get("icon", &""))
			and expected_visual_label in intent_button.text
			and (
				"CHOOSE OUTCOME" in String(intent_button.get_meta("accessible_text", ""))
				and int(intent_button.get_meta("outcome_cutoff_progress", -1)) == 55
				and intent_button.get_theme_font_size("font_size") == 9
				if StringName(variant.get("id", &"")) == &"choice" else
				true
			)
			and not _has_ascii_intent_prefix(intent_button.text),
			"every dossier intent should reuse its authored pin icon without an ASCII prefix [variant=%s text=%s]" % [
				str(variant),
				intent_button.text if intent_button != null else "missing",
			],
			failures,
		)
	_check(
		presented_texture_ids.size() == intent_variants.size(),
		"all eight dossier intents should retain visually distinct authored textures",
		failures,
	)
	var emitted_pecks: Array[int] = []
	var emitted_paths: Array[StringName] = []
	routing_ui.peck_assist_requested.connect(
		func(worker_id: int) -> void: emitted_pecks.append(worker_id)
	)
	routing_ui.claim_resolution_requested.connect(
		func(_worker_id: int, path_id: StringName) -> void: emitted_paths.append(path_id)
	)
	ui_worker["hen_intent"] = intent_variants[0]
	ui_worker["current_claim"] = {"id": 707, "lane": &"nest_damage"}
	ui_worker["peck_assist"] = {
		"available": true,
		"window_state": &"open",
		"remaining": 3,
		"limit": 3,
	}
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	routing_ui.set_peck_assist_clock_running(false)
	routing_ui.apply_snapshot(ui_snapshot)
	routing_ui.set_focus(int(ui_worker.get("id", 0)))
	var peck_target := routing_ui.focus_intent_action(&"peck")
	await process_frame
	var peck_context := routing_ui.context_action_state()
	_check(
		peck_target != null and peck_target.name == "PeckAssistButton"
		and routing_ui.active_dossier_tab() == &"route"
		and String(peck_context.get("action_id", "")) == "peck"
		and String(peck_context.get("target", "")) == "PeckAssistButton"
		and root.gui_get_focus_owner() == peck_target
		and not (peck_target as Button).disabled
		and bool((peck_target as Button).get_meta("resume_required", false))
		and "RESUME + PECK" in (peck_target as Button).text
		and emitted_pecks.is_empty(),
		"a paused rail handoff should focus explicit recovery without resuming or spending it",
		failures,
	)
	routing_ui.set_peck_assist_clock_running(true)
	_check(
		routing_ui.arm_peck_result_focus_handoff(int(ui_worker.get("id", 0))),
		"the focused live peck control should arm its narrow disabled-focus repair",
		failures,
	)
	ui_worker["hen_intent"] = intent_variants[1]
	(ui_worker["peck_assist"] as Dictionary)["available"] = false
	(ui_worker["peck_assist"] as Dictionary)["window_state"] = &"used"
	ui_worker["claim_resolution_status"] = {"available": true}
	(ui_worker["current_claim"] as Dictionary)["resolution_locked"] = false
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	ui_snapshot["last_peck_assist"] = {
		"worker_id": int(ui_worker.get("id", 0)),
		"claim_id": 707,
		"rating": &"strong",
	}
	routing_ui.set_reduced_motion(true)
	routing_ui.apply_snapshot(ui_snapshot)
	await process_frame
	var result_handoff := routing_ui.peck_result_focus_handoff_state()
	_check(
		root.gui_get_focus_owner() == intent_button
		and String(result_handoff.get("status", "")) == "completed"
		and String(result_handoff.get("action_id", "")) == "claim"
		and bool(routing_ui.get("_reduced_motion"))
		and emitted_pecks.is_empty()
		and emitted_paths.is_empty(),
		"a committed result should repair disabled focus to the next intent without activating it",
		failures,
	)
	routing_ui.set_reduced_motion(false)
	var claim_target := routing_ui.focus_intent_action(&"claim")
	await process_frame
	_check(
		claim_target != null and String(claim_target.name).begins_with("ClaimResolution_")
		and routing_ui.active_dossier_tab() == &"claim"
		and root.gui_get_focus_owner() == claim_target
		and emitted_paths.is_empty(),
		"an urgent file handoff should open its claimant choices without filing a path",
		failures,
	)
	# The repair must retire if the player changes worker context or a modal-style
	# interaction lock arrives before an accepted result snapshot.
	ui_worker["hen_intent"] = intent_variants[0]
	ui_worker["peck_assist"] = {
		"available": true,
		"window_state": &"open",
		"remaining": 2,
		"limit": 3,
	}
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	ui_snapshot["last_peck_assist"] = {}
	routing_ui.apply_snapshot(ui_snapshot)
	routing_ui.set_focus(int(ui_worker.get("id", 0)))
	routing_ui.focus_intent_action(&"peck")
	await process_frame
	_check(routing_ui.arm_peck_result_focus_handoff(0), "worker-change guard should begin from a focused peck", failures)
	routing_ui.set_focus(-1)
	var worker_cancel := routing_ui.peck_result_focus_handoff_state()
	_check(
		String(worker_cancel.get("status", "")) == "cancelled"
		and String(worker_cancel.get("reason", "")) == "worker_focus_changed",
		"changing the selected worker should cancel the pending focus repair",
		failures,
	)
	routing_ui.set_focus(int(ui_worker.get("id", 0)))
	routing_ui.focus_intent_action(&"peck")
	await process_frame
	_check(routing_ui.arm_peck_result_focus_handoff(0), "interaction guard should begin from a focused peck", failures)
	routing_ui.set_interaction_enabled(false)
	var modal_cancel := routing_ui.peck_result_focus_handoff_state()
	_check(
		String(modal_cancel.get("status", "")) == "cancelled"
		and String(modal_cancel.get("reason", "")) == "interaction_blocked",
		"a modal interaction lock should cancel the pending focus repair",
		failures,
	)
	routing_ui.set_interaction_enabled(true)
	# Restore the loop's last steady state before exercising the existing
	# steady-to-sync semantic transition assertion below.
	ui_worker["hen_intent"] = intent_variants[6]
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	routing_ui.apply_snapshot(ui_snapshot)
	await process_frame
	var transition_serial_before := int(intent_button.get_meta("intent_transition_serial", 0)) if intent_button != null else -1
	ui_worker["hen_intent"] = intent_variants[0]
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	routing_ui.apply_snapshot(ui_snapshot)
	await process_frame
	_check(
		intent_button != null
		and int(intent_button.get_meta("intent_transition_serial", 0)) > transition_serial_before
		and bool(intent_button.get_meta("intent_transition_animated", false))
		and "steady" in String(intent_button.get_meta("intent_transition_from", ""))
		and "sync" in String(intent_button.get_meta("intent_transition_to", "")),
		"a same-hen intent change should animate once with explicit old and new semantics",
		failures,
	)
	await create_timer(0.36).timeout
	_check(
		intent_button != null
		and intent_button.scale.is_equal_approx(Vector2.ONE)
		and intent_button.self_modulate.is_equal_approx(Color.WHITE),
		"the intent handoff should settle fully instead of leaving the control tinted or scaled",
		failures,
	)
	ui_worker["state_label"] = "PECKING"
	ui_worker["progress"] = 62.0
	ui_worker["current_claim"] = {"id": 707, "lane": &"nest_damage"}
	ui_worker["peck_assist"] = {
		"available": true,
		"window_state": &"open",
		"timing_label": "GOLDEN RHYTHM",
		"window_start": 28.0,
		"window_end": 76.0,
		"gold_start": 58.0,
		"gold_end": 66.0,
		"ideal_progress": 62.0,
		"remaining": 3,
		"limit": 3,
	}
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	routing_ui.call("_on_dossier_tab_pressed", &"route")
	routing_ui.apply_snapshot(ui_snapshot)
	await process_frame
	var missed_link := routing_ui.find_child("PriorityPeckIntentLink", true, false) as Control
	var dossier_missed_serial := int(routing_ui.get_meta("peck_missed_link_serial", 0))
	_check(
		routing_ui.play_peck_assist_missed(int(ui_worker.get("id", 0))),
		"the selected dossier should accept one broken reverse-link missed-window retreat",
		failures,
	)
	await process_frame
	_check(
		missed_link != null
		and missed_link.visible
		and bool(missed_link.get_meta("confirmation", false))
		and StringName(missed_link.get_meta("rating", &"")) == &"missed"
		and int(routing_ui.get_meta("peck_missed_link_serial", 0)) == dossier_missed_serial + 1
		and bool(routing_ui.get_meta("peck_missed_link_animated", false)),
		"the dossier should render a shape-distinct broken connector instead of another sentence [link=%s visible=%s confirmation=%s rating=%s serial=%d animated=%s]" % [
			str(missed_link != null),
			str(missed_link.visible if missed_link != null else false),
			str(bool(missed_link.get_meta("confirmation", false)) if missed_link != null else false),
			String(missed_link.get_meta("rating", &"")) if missed_link != null else "missing",
			int(routing_ui.get_meta("peck_missed_link_serial", 0)),
			str(bool(routing_ui.get_meta("peck_missed_link_animated", false))),
		],
		failures,
	)
	ui_worker["hen_intent"] = intent_variants[6]
	ui_worker["peck_assist"] = (ui_worker["peck_assist"] as Dictionary).duplicate(true)
	(ui_worker["peck_assist"] as Dictionary)["available"] = false
	(ui_worker["peck_assist"] as Dictionary)["window_state"] = &"missed"
	(ui_worker["peck_assist"] as Dictionary)["reason"] = "The next claim can restart the chain."
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	routing_ui.apply_snapshot(ui_snapshot)
	await process_frame
	var missed_button := routing_ui.find_child("PeckAssistButton", true, false) as Button
	var missed_label := routing_ui.find_child("PriorityPeckTimingLabel", true, false) as Label
	_check(
		missed_button != null
		and missed_button.text == "MISSED"
		and missed_label != null
		and missed_label.text == "NEXT FILE  •  TRY AGAIN"
		and "window missed" in missed_label.accessibility_name
		and "next file" in missed_label.accessibility_name.to_lower(),
		"the settled dossier should keep one terse failure word and one explicit recovery path",
		failures,
	)
	await create_timer(0.64).timeout
	_check(
		missed_link != null and not missed_link.visible,
		"the dossier missed connector should retire after its bounded retreat",
		failures,
	)
	_check(
		routing_ui.stage_peck_assist_missed_capture(int(ui_worker.get("id", 0)))
		and bool(routing_ui.get_meta("peck_missed_capture_staged", false)),
		"the browser fixture should hold the real broken dossier connector midpoint",
		failures,
	)
	routing_ui.set_reduced_motion(true)
	dossier_missed_serial = int(routing_ui.get_meta("peck_missed_link_serial", 0))
	_check(
		not routing_ui.play_peck_assist_missed(int(ui_worker.get("id", 0)))
		and int(routing_ui.get_meta("peck_missed_link_serial", 0)) == dossier_missed_serial + 1
		and not bool(routing_ui.get_meta("peck_missed_link_animated", true)),
		"reduced motion should keep the dossier's stable MISSED / NEXT FILE recovery state without a link animation",
		failures,
	)
	ui_worker["hen_intent"] = intent_variants[1]
	ui_workers[0] = ui_worker
	ui_snapshot["workers"] = ui_workers
	routing_ui.apply_snapshot(ui_snapshot)
	await process_frame
	_check(
		intent_button != null
		and not bool(intent_button.get_meta("intent_transition_animated", true))
		and intent_button.scale.is_equal_approx(Vector2.ONE)
		and intent_button.self_modulate.is_equal_approx(Color.WHITE),
		"reduced motion should swap intent semantics immediately without a visual pop tween",
		failures,
	)
	routing_ui.set_reduced_motion(false)
	routing_ui.apply_first_clutch({"visible": true, "stage": &"inspect"})
	await process_frame
	_check(
		intent_button != null and not intent_button.visible,
		"intent shortcut should stay out of the authored First Clutch coach",
		failures,
	)
	routing_ui.apply_first_clutch({"visible": false, "stage": &"normal"})
	await process_frame
	_check(
		intent_button != null and intent_button.visible,
		"intent shortcut should return after the coach",
		failures,
	)

	chicken.queue_free()
	second_chicken.queue_free()
	routing_ui.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("HEN_INTENT_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("HEN_INTENT_UI_TEST_PASSED priorities=8 progress_ring=5 lifecycle_shapes=route+work+egg pins=compact+staggered+semantic bond=thresholded dossier=icon-parity+contextual coach=protected")
	quit(0)


func _assert_intent_priorities(simulation: DepartmentSimulation, failures: Array[String]) -> void:
	var base := {
		"employed": true,
		"name": "Mabel",
		"state_label": "PECKING",
		"stress": 10.0,
		"fatigue": 10.0,
		"morale": 90.0,
		"progress": 30.0,
		"current_claim": {},
		"claim_resolution_status": {},
		"peck_assist": {},
	}
	var sync := base.duplicate(true)
	sync["peck_assist"] = {"available": true}
	_check(_intent_id(simulation, sync) == &"sync", "live peck window should be highest priority", failures)
	var deadline := base.duplicate(true)
	deadline["current_claim"] = {"minutes_until_deadline": -8, "overdue": true}
	var deadline_intent := simulation.call("_worker_hen_intent_snapshot", deadline) as Dictionary
	_check(
		StringName(deadline_intent.get("id", &"")) == &"deadline"
		and StringName(deadline_intent.get("action_id", &"")) == &"claim",
		"overdue file should publish a direct live-claim intent",
		failures,
	)
	var laying := deadline.duplicate(true)
	laying["state_label"] = "LAYING"
	laying["progress"] = 100.0
	laying["claim_resolution_status"] = {"available": true}
	(laying["current_claim"] as Dictionary)["resolution_locked"] = false
	var laying_intent := simulation.call("_worker_hen_intent_snapshot", laying) as Dictionary
	_check(
		StringName(laying_intent.get("id", &"")) == &"delivery"
		and StringName(laying_intent.get("icon", &"")) == &"delivery"
		and StringName(laying_intent.get("action_id", &"")) == &"route"
		and String(laying_intent.get("action_label", "")) == "TRACK EGG"
		and "grading" in String(laying_intent.get("detail", "")).to_lower()
		and "returns 1 Priority Peck charge" in String(laying_intent.get("detail", "")),
		"laying should replace expired deadline and claimant choices with the downstream egg receipt",
		failures,
	)
	var care := base.duplicate(true)
	care["stress"] = 72.0
	_check(_intent_id(simulation, care) == &"care", "high strain should publish care intent", failures)
	var choice := base.duplicate(true)
	choice["current_claim"] = {"minutes_until_deadline": 180, "resolution_locked": false}
	choice["claim_resolution_status"] = {"available": true, "cutoff_progress": 55.0}
	var choice_intent := simulation.call("_worker_hen_intent_snapshot", choice) as Dictionary
	_check(
		StringName(choice_intent.get("id", &"")) == &"choice"
		and String(choice_intent.get("action_label", "")) == "CHOOSE OUTCOME"
		and int(choice_intent.get("cutoff_progress", -1)) == 55
		and "care, pace, risk, and cost" in String(choice_intent.get("detail", ""))
		and "CHOOSE PATH" not in String(choice_intent.get("action_label", "")),
		"open claimant resolution should use outcome language that cannot be confused with tray routing",
		failures,
	)
	var steady := base.duplicate(true)
	steady["current_claim"] = {"minutes_until_deadline": 180, "resolution_locked": true}
	var steady_intent := simulation.call("_worker_hen_intent_snapshot", steady) as Dictionary
	_check(
		StringName(steady_intent.get("id", &"")) == &"steady"
		and StringName(steady_intent.get("action_id", &"")) == &"claim",
		"ordinary live work should drill directly into the live claim",
		failures,
	)
	var matched := base.duplicate(true)
	matched["current_claim"] = {
		"minutes_until_deadline": 180,
		"resolution_locked": true,
		"specialty_match": true,
	}
	_check(_intent_id(simulation, matched) == &"match", "specialty work should publish the gold good-match intent", failures)
	_check(_intent_id(simulation, base) == &"ready", "idle hen should publish routing intent", failures)


func _intent_id(simulation: DepartmentSimulation, worker: Dictionary) -> StringName:
	return StringName((simulation.call("_worker_hen_intent_snapshot", worker) as Dictionary).get("id", &""))


func _intent(id: StringName, icon: StringName, action_id: StringName, label: String, urgency: int) -> Dictionary:
	return {
		"id": id,
		"icon": icon,
		"action_id": action_id,
		"action_label": label,
		"detail": "Mabel needs attention. Open the useful action.",
		"urgency": urgency,
		"actionable": true,
	}


func _has_ascii_intent_prefix(copy: String) -> bool:
	for prefix: String in [">>", "!", "+", "Y ", "*", "O ", "=", "> "]:
		if copy.begins_with(prefix):
			return true
	return false


func _contains_all(copy: String, needles: Array[String]) -> bool:
	for needle: String in needles:
		if needle not in copy:
			return false
	return true


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
