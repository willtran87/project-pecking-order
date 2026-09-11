extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	var worker_views := office.get("_worker_views") as Dictionary
	_check(
		simulation != null and campaign_ui != null and feedback != null,
		"delivery acknowledgment fixture should expose production systems",
		failures,
	)
	if campaign_ui != null:
		campaign_ui.show_title(false)
	if simulation != null and simulation.shift_phase != DepartmentSimulation.ShiftPhase.RUNNING:
		_check(simulation.select_directive(&"shell_assurance"), "fixture should enter a running shift", failures)
	for worker_id in [0, 1]:
		var worker_view := worker_views.get(worker_id) as ChickenView
		if worker_view != null:
			worker_view.stage_at_workstation_for_introduction()
		if simulation != null:
			simulation.set_worker_at_workstation(worker_id, true)
	if simulation != null:
		office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame

	var marker_roots := office.find_children(
		"EggDeliveryAcknowledgment", "Node3D", true, false,
	)
	_check(marker_roots.size() == 6, "every workstation should own exactly one pooled delivery marker", failures)
	for marker_value in marker_roots:
		var marker := marker_value as Node3D
		_check(
			marker != null
			and marker.find_children("*", "Label3D", true, false).is_empty()
			and marker.find_children("*", "Area3D", true, false).is_empty(),
			"world payout markers should add neither text nor collision targets",
			failures,
		)

	var save_before := simulation.export_save_state() if simulation != null else {}
	feedback.set_animation_speed_multiplier(2.0)
	_check(
		feedback.play_egg_delivery_ack(0, 101, &"sound", 455, false, true),
		"cash delivery should reuse the exact worker's marker",
		failures,
	)
	var cash_state := feedback.egg_delivery_ack_snapshot()
	var cash_acknowledgments := cash_state.get("acknowledgments", []) as Array
	var cash_ack := cash_acknowledgments[0] as Dictionary if cash_acknowledgments.size() == 1 else {}
	_check(
		int(cash_state.get("pooled_marker_count", 0)) == 6
		and int(cash_state.get("active_count", 0)) == 1
		and is_equal_approx(float(cash_state.get("animation_speed_multiplier", 0.0)), 2.0)
		and int(cash_ack.get("worker_id", -1)) == 0
		and int(cash_ack.get("claim_id", -1)) == 101
		and int(cash_ack.get("cash_cents", -1)) == 455
		and bool(cash_ack.get("priority_refunded", false))
		and String(cash_ack.get("shape", "")) == "coin_up_arrow"
		and "$4.55" in String(cash_ack.get("accessible_text", ""))
		and "detailed history" in String(cash_ack.get("accessible_text", "")),
		"cash marker should expose exact, accessible payout causality without world text",
		failures,
	)
	feedback.set_color_vision_mode(&"color_blind_safe")
	var color_safe_acknowledgments := (
		feedback.egg_delivery_ack_snapshot().get("acknowledgments", []) as Array
	)
	var color_safe_ack := (
		color_safe_acknowledgments[0] as Dictionary
		if color_safe_acknowledgments.size() == 1 else
		{}
	)
	_check(
		String(color_safe_ack.get("shape", "")) == "coin_up_arrow",
		"color-vision changes must retain the cash marker's non-color shape",
		failures,
	)
	if simulation != null:
		var remapped_snapshot := simulation.snapshot(true).duplicate(true)
		var remapped_workers := remapped_snapshot.get("workers", []) as Array
		if remapped_workers.size() >= 2:
			(remapped_workers[0] as Dictionary)["desk_index"] = 1
			(remapped_workers[1] as Dictionary)["desk_index"] = 0
			feedback.apply_snapshot(remapped_snapshot)
			var remapped_acknowledgments := (
				feedback.egg_delivery_ack_snapshot().get("acknowledgments", []) as Array
			)
			var remapped_ack := (
				remapped_acknowledgments[0] as Dictionary
				if remapped_acknowledgments.size() == 1 else
				{}
			)
			_check(
				int(remapped_ack.get("worker_id", -1)) == 0
				and String(remapped_ack.get("worker_name", "")) == "Mabel",
				"a desk remap during the hold must not rewrite the delivering hen's identity",
				failures,
			)
			feedback.apply_snapshot(simulation.snapshot(true))
	var first_serial := int(cash_ack.get("serial", 0))
	_check(
		feedback.play_egg_delivery_ack(0, 102, &"golden", 875, false, false),
		"a rapid same-desk payout should replace rather than stack",
		failures,
	)
	var replaced_state := feedback.egg_delivery_ack_snapshot()
	var replaced_acknowledgments := replaced_state.get("acknowledgments", []) as Array
	var replaced_ack := replaced_acknowledgments[0] as Dictionary if replaced_acknowledgments.size() == 1 else {}
	_check(
		int(replaced_state.get("active_count", 0)) == 1
		and int(replaced_ack.get("serial", 0)) > first_serial
		and int(replaced_ack.get("claim_id", -1)) == 102
		and marker_roots.size() == office.find_children(
			"EggDeliveryAcknowledgment", "Node3D", true, false,
		).size(),
		"rapid delivery should preserve the six-node pool and newest exact claim",
		failures,
	)
	_check(
		feedback.play_egg_delivery_ack(1, 201, &"sound", 0, true, false),
		"Farmgate delivery should reuse a second desk marker",
		failures,
	)
	var stock_state := feedback.egg_delivery_ack_snapshot()
	var stock_found := false
	for acknowledgment_value in stock_state.get("acknowledgments", []):
		var acknowledgment := acknowledgment_value as Dictionary
		if int(acknowledgment.get("claim_id", -1)) != 201:
			continue
		stock_found = (
			String(acknowledgment.get("kind", "")) == "stock"
			and String(acknowledgment.get("shape", "")) == "crate_egg"
			and "Farmgate stock" in String(acknowledgment.get("accessible_text", ""))
		)
	_check(
		int(stock_state.get("active_count", 0)) == 2 and stock_found,
		"simultaneous hens should remain distinguishable while Farmgate uses a non-cash shape",
		failures,
	)

	feedback.set_reduced_motion(true)
	var reduced_state := feedback.egg_delivery_ack_snapshot()
	var all_static := true
	for acknowledgment_value in reduced_state.get("acknowledgments", []):
		all_static = all_static and not bool((acknowledgment_value as Dictionary).get("animated", true))
	_check(
		bool(reduced_state.get("reduced_motion", false)) and all_static,
		"reduced motion should convert every visible marker to a static semantic hold",
		failures,
	)
	_check(
		feedback.stage_egg_delivery_ack_capture(1),
		"the pooled Farmgate marker should support deterministic visual inspection",
		failures,
	)
	var staged_state := feedback.egg_delivery_ack_snapshot()
	_check(
		int(staged_state.get("capture_staged_count", 0)) == 1,
		"capture staging should pause exactly one real pooled marker",
		failures,
	)
	_check(
		simulation != null and simulation.export_save_state() == save_before,
		"world delivery acknowledgments must remain neutral to authoritative save data",
		failures,
	)
	_check(
		feedback.play_egg_delivery_ack(1, 202, &"sound", 0, true, false, 0.72),
		"a new reduced-motion receipt should release a capture-staged marker safely",
		failures,
	)
	await create_timer(0.95).timeout
	_check(
		int(feedback.egg_delivery_ack_snapshot().get("active_count", -1)) == 0
		and office.find_children(
			"EggDeliveryAcknowledgment", "Node3D", true, false,
		).size() == 6,
		"2x reduced-motion holds should retire cleanly without shrinking or growing the pool",
		failures,
	)

	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("EGG_DELIVERY_ACK_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("EGG_DELIVERY_ACK_TEST_PASSED pool=6 cash=coin stock=crate overlap=bounded reduced=static save=neutral")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
