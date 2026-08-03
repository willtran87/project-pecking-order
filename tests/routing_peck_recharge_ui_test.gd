extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	office.call("_prepare_capture_running")
	var simulation := office.get("_simulation") as DepartmentSimulation
	var routing_ui := office.find_child("PeckworkRoutingUI", true, false) as PeckworkRoutingUI
	var feedback := office.get("_workstation_feedback") as WorkstationFeedback
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	var meter := office.find_child("PriorityPeckChargeMeter", true, false) as Control
	_check(simulation != null and routing_ui != null, "Office should expose recharge authority and presentation", failures)
	if simulation == null or routing_ui == null:
		await _finish(office, failures)
		return

	for worker_index in mini(4, simulation.workers.size()):
		simulation.set_worker_at_workstation(worker_index, true)
	simulation.advance_tick()
	simulation.peck_assists_used_today = 1
	simulation.peck_assist_interventions_today = 1
	office.call("_on_snapshot_changed", simulation.snapshot())

	for lane: StringName in [&"nest_damage", &"predator_loss"]:
		var receipt := _best_fit_dispatch(simulation, lane, failures)
		_check(bool(receipt.get("accepted", false)), "%s should build the real route chain" % lane, failures)
	office.call("_on_dispatch_lane_requested", &"appeals")
	await process_frame
	var recharge_worker_id := int(office.get("_dispatch_recommended_worker_id"))
	_check(recharge_worker_id >= 0, "Appeals should expose a ranked x3 worker", failures)
	if recharge_worker_id >= 0 and simulation.workers[recharge_worker_id].assigned_lane == &"appeals":
		simulation.set_worker_assignment(recharge_worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	routing_ui.set_focus(recharge_worker_id)
	var committed := bool(office.call("_commit_dispatch", recharge_worker_id))
	var dispatch := office.get("_dispatch_last_receipt") as Dictionary
	var reward := dispatch.get("reward", {}) as Dictionary
	_check(committed, "the Office path should file the real x3 route", failures)
	_check(
		StringName(reward.get("id", &"")) == &"peck_recharge"
		and bool(reward.get("refilled", false))
		and int(reward.get("charges_before", -1)) == 2
		and int(reward.get("charges_after", -1)) == 3,
		"x3 should retain one exact 2-to-3 charge receipt",
		failures,
	)
	await create_timer(0.86).timeout
	var charge_state := routing_ui.priority_peck_charge_state()
	_check(
		bool(charge_state.get("recharge_active", false))
		and int(charge_state.get("recharge_before", -1)) == 2
		and int(charge_state.get("recharge_after", -1)) == 3
		and int(charge_state.get("recharge_serial", 0)) == 1
		and String(charge_state.get("shape", "")) == "filled_diamond_pips",
		"the landed folder should fill one shape-distinct Priority Peck pip",
		failures,
	)
	_check(
		meter != null
		and int(meter.get_meta("charges", 0)) == 3
		and bool(meter.get_meta("recharge_active", false))
		and "3 of 3" in String(meter.get_meta("accessible_text", "")),
		"the existing timing affordance should expose the restored charge visually and accessibly",
		failures,
	)
	_check(
		feedback != null and feedback.active_routing_reward_burst_count() == 1,
		"the meter refill should synchronize with one desk-local world icon",
		failures,
	)
	_check(
		audio != null and String(audio.feedback_snapshot().get("last_cue", "")) == "attention_restored",
		"the world landing should synchronize one refill confirmation sound",
		failures,
	)
	var recharge_serial := int(charge_state.get("recharge_serial", 0))
	office.call("_on_routing_reward_presented", recharge_worker_id, reward, 3)
	_check(
		int(routing_ui.priority_peck_charge_state().get("recharge_serial", 0)) == recharge_serial,
		"a duplicate world callback must not replay the authoritative refill",
		failures,
	)

	routing_ui.call("_finish_priority_peck_recharge")
	routing_ui.set_reduced_motion(true)
	var reduced_reward := reward.duplicate(true)
	reduced_reward["authority_key"] = String(reward.get("authority_key", "")) + ":reduced"
	_check(
		routing_ui.play_priority_peck_recharge(reduced_reward, 3)
		and not bool(routing_ui.priority_peck_charge_state().get("animated", true))
		and bool(meter.get_meta("recharge_active", false)),
		"reduced motion should preserve the static semantic refill ring",
		failures,
	)
	_check(
		not routing_ui.play_priority_peck_recharge(reduced_reward, 3),
		"the same reduced-motion receipt should remain duplicate-safe",
		failures,
	)
	routing_ui.call("_finish_priority_peck_recharge")
	routing_ui.set_reduced_motion(false)
	await create_timer(1.7).timeout
	_check(
		feedback != null and feedback.active_routing_reward_burst_count() == 0,
		"the live world icon should clean itself up after its bounded hold",
		failures,
	)
	await _finish(office, failures)


func _best_fit_dispatch(
	simulation: DepartmentSimulation,
	lane: StringName,
	failures: Array[String],
) -> Dictionary:
	var candidates := simulation.dispatch_candidates(lane)
	_check(not candidates.is_empty(), "%s should expose a best fit" % lane, failures)
	if candidates.is_empty():
		return {}
	var worker_id := int(candidates[0].get("worker_id", -1))
	if simulation.workers[worker_id].assigned_lane == lane:
		simulation.set_worker_assignment(worker_id, DepartmentSimulation.AUTO_ASSIGNMENT)
	return simulation.dispatch_worker_to_lane(worker_id, lane)


func _finish(office: Office, failures: Array[String]) -> void:
	office.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("ROUTING_PECK_RECHARGE_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ROUTING_PECK_RECHARGE_UI_TEST_PASSED authority=2>3 world=desk meter=pips duplicate=blocked")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
