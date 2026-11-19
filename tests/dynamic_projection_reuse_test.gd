extends SceneTree

const Director := preload("res://core/experience/gameplay_pulse_director.gd")


func _init() -> void:
	var failures: Array[String] = []
	var director := Director.new()
	var simulation := DepartmentSimulation.new(1701, 4)
	simulation.select_directive(&"shell_assurance")
	var previous: Dictionary = {}
	var previous_copy: Dictionary = {}
	for stage in 6:
		simulation.eggs_today = stage * 3
		simulation.quality_streak = stage
		simulation.day = 1 + stage / 2
		var focus := stage % 4
		var context := {
			"simulation": simulation.snapshot(),
			"active_playbook": simulation.playbook_snapshot(focus),
			"focused_worker_id": focus,
			"next_action": {"action_id": "route" if stage % 2 == 0 else "review", "visible_label": "ACTION %d" % stage, "actionable": true},
			"action_feedback": {"visible": stage % 2 == 1, "title": "REWARD %d" % stage, "entries": [{"copy": "EGG", "detail": "DELIVERED"}]},
			"routing_lifecycle": {"active_stage": "peck" if stage % 2 == 0 else "egg"},
			"rival": {"difference": stage - 3, "name": "Golden Comb"},
		}
		var original := context.duplicate(true)
		var public_pulse := director.compose(context)
		var shared := director.compose(context, true, true)
		_check(public_pulse == shared, "all dynamic values must match independent projection at stage %d" % stage, failures)
		_check(context == original, "composing shared graphs must not mutate source data", failures)
		_check(previous == previous_copy, "later publications must leave retained graphs unchanged", failures)
		_check(shared["focus_mode"]["copy"] == "ACTION %d" % stage, "action changes must publish immediately", failures)
		_check(is_same(shared["mastery_replay"]["supporting_complete_loop"], shared["complete_game_loop"]), "the complete loop must be shared within one live publication", failures)
		_check(is_same(shared["professional_loop"]["supporting_physical_loop"], shared["physical_loop"]), "the physical loop must be shared within one live publication", failures)
		_check(is_same(shared["guided_loop"]["visible_shift_journey"], shared["shift_journey"]), "the current journey must be shared within one live publication", failures)
		_check(not is_same(public_pulse["mastery_replay"]["supporting_complete_loop"], public_pulse["complete_game_loop"]), "public nested branches must retain copy isolation", failures)
		shared["rival_pulse"]["hud_visible"] = true
		_check(not shared["mastery_replay"]["rival_action"]["pulse"].has("hud_visible"), "the mutable root rival visibility annotation must remain isolated", failures)
		public_pulse["mastery_replay"]["supporting_complete_loop"]["external_edit"] = true
		_check(not public_pulse["complete_game_loop"].has("external_edit") and not shared["complete_game_loop"].has("external_edit"), "external edits must not cross public branches or contaminate live data", failures)
		# The optimization only borrows locally composed branches. It must not
		# introduce references to mutable authoritative inputs.
		var saved := shared.duplicate(true)
		context["action_feedback"]["entries"][0]["copy"] = "MUTATED"
		context["active_playbook"]["contract"]["progress"] = -100
		context["simulation"]["workers"][0]["hen_intent"] = {"detail": "MUTATED"}
		_check(shared == saved, "source mutation must not alter the retained optimized projection", failures)
		previous = shared
		previous_copy = saved
	for failure in failures:
		push_error(failure)
	print("DYNAMIC_PROJECTION_REUSE_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
