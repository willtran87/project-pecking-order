extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(8135)
	var lanes: Array[StringName] = [&"nest_damage", &"predator_loss", &"appeals"]
	var record_reward: Dictionary = {}
	for dispatch_index in 15:
		var receipt := _best_fit_dispatch(simulation, lanes[dispatch_index % lanes.size()], failures)
		if dispatch_index == 14:
			record_reward = receipt.get("reward", {}) as Dictionary
	_check(StringName(record_reward.get("id", &"")) == &"mastery_record", "fixture should reach the real x15 record", failures)

	var routing_ui := PeckworkRoutingUI.new()
	root.add_child(routing_ui)
	await process_frame
	routing_ui.apply_snapshot(simulation.snapshot())
	routing_ui.set_dispatch_state(&"", 15, "", String(record_reward.get("label", "")))
	var momentum_label := routing_ui.find_child("DispatchMomentum", true, false) as Label
	_check(
		momentum_label != null and "RECORD x15" in momentum_label.text,
		"the existing routing strip should carry the record without a new panel",
		failures,
	)
	var mastery := routing_ui.routing_mastery_state()
	_check(
		bool(mastery.get("active", false))
		and int(mastery.get("best_chain", 0)) == 15
		and int(mastery.get("next_milestone", 0)) == 20
		and StringName(mastery.get("target_kind", &"")) == &"record",
		"the strip should expose the persistent x20 horizon",
		failures,
	)

	var office := Office.new()
	office.set("_routing_ui", routing_ui)
	office.call(
		"_on_routing_reward_presented",
		int(record_reward.get("worker_id", -1)),
		record_reward,
		15,
	)
	var presentation := office.get("_last_routing_mastery_presentation") as Dictionary
	_check(
		int(presentation.get("serial", 0)) == 1
		and int(presentation.get("record_before", 0)) == 14
		and int(presentation.get("record_after", 0)) == 15,
		"the folder landing should file one exact 14-to-15 presentation receipt",
		failures,
	)
	_check(
		momentum_label != null
		and String(momentum_label.get_meta("reward_id", "")) == "mastery_record"
		and "15 consecutive" in String(momentum_label.get_meta("accessible_text", "")),
		"the record celebration should remain compact visually and exact accessibly",
		failures,
	)
	office.call(
		"_on_routing_reward_presented",
		int(record_reward.get("worker_id", -1)),
		record_reward,
		15,
	)
	_check(
		int((office.get("_last_routing_mastery_presentation") as Dictionary).get("serial", 0)) == 1,
		"a duplicate landing callback must not replay the record",
		failures,
	)

	var feedback := WorkstationFeedback.new()
	var medal_texture := feedback.call("_routing_reward_texture", &"mastery_record") as Texture2D
	_check(medal_texture != null, "the desk source should own a shape-distinct mastery medal", failures)
	feedback.free()
	routing_ui.set_reduced_motion(true)
	var reduced_reward := record_reward.duplicate(true)
	reduced_reward["authority_key"] = String(record_reward.get("authority_key", "")) + ":reduced"
	office.call(
		"_on_routing_reward_presented",
		int(reduced_reward.get("worker_id", -1)),
		reduced_reward,
		15,
	)
	_check(
		int((office.get("_last_routing_mastery_presentation") as Dictionary).get("serial", 0)) == 2
		and String(momentum_label.get_meta("reward_id", "")) == "mastery_record",
		"reduced motion should retain the static semantic record without losing authority",
		failures,
	)

	office.set("_routing_ui", null)
	var isolated_clock := office.get("_clock") as SimulationClock
	if isolated_clock != null and not isolated_clock.is_inside_tree():
		isolated_clock.free()
	office.free()
	routing_ui.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("ROUTING_MASTERY_UI_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("ROUTING_MASTERY_UI_TEST_PASSED authority=x15 horizon=x20 source=medal duplicate=blocked reduced=static")
	quit(0)


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
	var receipt := simulation.dispatch_worker_to_lane(worker_id, lane)
	_check(bool(receipt.get("accepted", false)), "%s should file a real route" % lane, failures)
	return receipt


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
