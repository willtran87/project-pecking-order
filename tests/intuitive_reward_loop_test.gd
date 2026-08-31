extends SceneTree

const DirectorScript := preload("res://core/experience/gameplay_pulse_director.gd")
const PresenceScript := preload("res://features/management/management_presence.gd")
const FeedbackScript := preload("res://features/office/workstation_feedback.gd")
const AudioScript := preload("res://features/office/office_audio_feedback.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var simulation := DepartmentSimulation.new(260829, 4)
	for worker_id in simulation.workers.size():
		simulation.set_worker_at_workstation(worker_id, true)
	simulation.select_directive(&"record_harvest")
	simulation.perform_playbook_action(&"preset", &"safe", 0)
	var playbook := simulation.playbook_snapshot(0)
	var pulse := DirectorScript.new().compose({
		"simulation": simulation.snapshot(),
		"next_action": {"action_id": "route", "visible_label": "ROUTE FILE", "actionable": true},
		"focused_worker_id": 0,
		"active_playbook": playbook,
		"action_feedback": {
			"visible": true,
			"title": "BEST FIT",
			"entries": [{"detail": "Mabel receives the file; quality improves."}],
		},
	})
	var layer := pulse.get("intuitive_reward_loop", {}) as Dictionary
	var expected_items := [
		"physical_manager_intervention_station",
		"three_second_cause_effect_sequence",
		"visually_distinct_case_folders",
		"physical_morning_plan_draft",
		"why_this_matters_previews",
		"clear_tension_release_rhythm",
		"expressive_chicken_reactions",
		"personal_chicken_goals",
		"hero_file_per_shift",
		"stronger_combo_anticipation",
		"transformative_upgrades",
		"visible_reward_destination",
		"one_more_shift_tease",
		"better_setback_recovery",
		"mastery_feedback",
		"exception_only_automation_visualization",
		"rival_office_presence",
		"shorter_action_language",
		"recognizable_sound_families",
		"comprehension_driven_playtesting",
	]
	_check(
		int(pulse.get("version", 0)) == 18
		and int(layer.get("item_count", 0)) == 20
		and int(layer.get("resolved_count", 0)) == 20
		and bool(layer.get("all_resolved", false))
		and not bool(layer.get("authoritative", true))
		and not bool(layer.get("adds_default_panel", true))
		and (layer.get("items", {}) as Dictionary).keys().all(func(key): return String(key) in expected_items),
		"the professional intuition layer should resolve the exact twenty approved items",
		failures,
	)
	var station_projection := layer.get("manager_station", {}) as Dictionary
	_check(
		bool(station_projection.get("physical", false))
		and int(station_projection.get("choice_count", 0)) == 3
		and String(station_projection.get("selected_plan_id", "")) == "safe"
		and (station_projection.get("sequence", []) as Array) == ["CALL", "FLOCK", "RESULT"]
		and not bool(station_projection.get("adds_collision", true)),
		"the manager station should physically express plan, intervention, and result without blocking routes",
		failures,
	)
	_check(
		int((layer.get("cause_effect", {}) as Dictionary).get("beat_count", 0)) == 3
		and not bool((layer.get("case_folders", {}) as Dictionary).get("color_only", true))
		and int((layer.get("sound_families", {}) as Dictionary).get("count", 0)) == 5
		and bool((layer.get("automation", {}) as Dictionary).get("exception_only", false))
		and bool((layer.get("comprehension", {}) as Dictionary).get("real_participants_required", false))
		and bool((layer.get("comprehension", {}) as Dictionary).get("results_never_fabricated", false)),
		"cause/effect, folder shapes, sounds, automation, and evidence boundaries should stay explicit",
		failures,
	)

	var fixture := Node3D.new()
	root.add_child(fixture)
	var presence := PresenceScript.new()
	fixture.add_child(presence)
	await process_frame
	presence.apply_command_station_state(station_projection)
	var station_snapshot := presence.command_station_snapshot()
	_check(
		bool(station_snapshot.get("physical", false))
		and int(station_snapshot.get("choice_count", 0)) == 3
		and int(station_snapshot.get("plan_count", 0)) == 3
		and String(station_snapshot.get("selected_plan_id", "")) == "safe"
		and not bool(station_snapshot.get("adds_collision", true)),
		"the physical command station should contain three readable plans and three intervention objects",
		failures,
	)
	presence.play_manager_intervention(&"ring_bell")
	await create_timer(0.05).timeout
	station_snapshot = presence.command_station_snapshot()
	_check(
		int(station_snapshot.get("sequence_serial", 0)) == 1
		and String(station_snapshot.get("last_intervention_id", "")) == "ring_bell"
		and (station_snapshot.get("sequence", []) as Array) == ["CALL", "FLOCK", "RESULT"],
		"an accepted manager call should play exactly one visual three-beat sequence",
		failures,
	)
	presence.apply_consolidated_loop_state(pulse.get("consolidated_game_loop", {}) as Dictionary)
	presence.play_core_loop_sequence(&"route", &"best_fit")
	await create_timer(0.05).timeout
	station_snapshot = presence.command_station_snapshot()
	_check(
		int(station_snapshot.get("sequence_serial", 0)) == 2
		and String(station_snapshot.get("last_action_id", "")) == "route"
		and bool(station_snapshot.get("canonical_loop", false)),
		"ordinary accepted routes should use the same physical three-beat station language",
		failures,
	)

	var folder_feedback := FeedbackScript.new()
	fixture.add_child(folder_feedback)
	var expected_folder_shapes := {
		&"nest_damage": &"shield",
		&"predator_loss": &"diamond",
		&"appeals": &"split_stamp",
	}
	for lane_shape in expected_folder_shapes:
		var folder := Node3D.new()
		fixture.add_child(folder)
		var shape: StringName = folder_feedback.call(
			"_add_dispatch_lane_marker",
			folder,
			lane_shape,
			Color("55aabb"),
		)
		_check(
			shape == StringName(expected_folder_shapes[lane_shape]),
			"each lane folder should have a unique raised silhouette",
			failures,
		)

	var audio := AudioScript.new()
	fixture.add_child(audio)
	await process_frame
	for intervention_id in [&"ring_bell", &"coffee_run", &"emergency_review"]:
		_check(bool(audio.call("play_manager_intervention", intervention_id)), "each manager intervention should have a playable semantic sound", failures)
	var audio_snapshot := audio.call("feedback_snapshot") as Dictionary
	_check(
		String(audio_snapshot.get("last_cue", "")) == "manager_review"
		and int(audio_snapshot.get("voice_count", 0)) == 8,
		"intervention sounds should remain inside the fixed pooled audio budget",
		failures,
	)

	fixture.queue_free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("INTUITIVE_REWARD_LOOP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("INTUITIVE_REWARD_LOOP_TEST_PASSED items=20 station=3+3 cause=3 folders=3 sounds=3 panel=false")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
