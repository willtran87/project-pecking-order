extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)


func _run() -> void:
	# Compare the focused event read against the public exact read through the
	# actual campaign consumer, including receipts for sound and cracked eggs.
	var office := Office.new()
	var reference := Office.new()
	for day in [5, 6, 12]:
		var sim := DepartmentSimulation.new(8129, 4)
		sim.day = day
		sim.select_directive(&"shell_assurance")
		for worker in sim.workers:
			sim.set_worker_at_workstation(worker.id, true)
		sim.advance_tick(false)
		var board := sim.market_contract_board_status()
		var retained_board := board.duplicate(true)
		check(sim.economic_briefing_snapshot(board) == sim.economic_briefing_snapshot(), "Reusing current contract quotes must preserve the entire economic briefing")
		check(board == retained_board, "Briefing must not mutate borrowed contract data")
		for count in 4:
			sim.eggs_today = count + 1
			sim.cracked_today = count / 2
			sim.workers[0].morale -= 4.5
			sim.workers[0].stress += 8.5
			sim.workers[1].fatigue += 3.0
			sim.workers[0].eggs_laid += 1
			var full := sim.snapshot()
			var cache_before := sim.runtime_projection_cache_diagnostics()
			var narrow := sim.production_reaction_snapshot()
			check(sim.runtime_projection_cache_diagnostics().builds == cache_before.builds, "Production feedback must not rebuild management projections")
			check(office.call("_campaign_live_metrics", full) == office.call("_campaign_live_metrics", narrow), "Every live goal metric must match the exact read on shift %d" % day)
			var worker := (narrow.workers as Array)[0] as Dictionary
			for key in ["id", "name", "assigned_lane", "eggs_laid", "employed", "morale", "stress", "fatigue"]:
				check(worker[key] == full.workers[0][key], "Hen reaction field must remain exact: " + key)
			var previous := narrow.duplicate()
			previous.eggs_today -= 1
			var previous_full := full.duplicate(true)
			previous_full.eggs_today -= 1
			var quality := "cracked" if count % 2 == 1 else "sound"
			if quality == "cracked":
				previous.cracked_today = maxi(0, previous.cracked_today - 1)
				previous_full.cracked_today = maxi(0, previous_full.cracked_today - 1)
			office.call("_record_campaign_order_cause_receipts", previous, narrow, "HEN/LANE", &"routed_egg", quality)
			reference.call("_record_campaign_order_cause_receipts", previous_full, full, "HEN/LANE", &"routed_egg", quality)
			check(office.get("_campaign_order_cause_receipts") == reference.get("_campaign_order_cause_receipts"), "Campaign cause receipts must preserve exact before/after results")
			worker.morale = -999
			check(sim.workers[0].morale >= 0, "Event read must not alias hen authority")
	# These two read-only consumers never enter _ready(), which normally adopts
	# their preconstructed clocks into the tree. Release those fixture nodes.
	(office.get("_clock") as SimulationClock).free()
	(reference.get("_clock") as SimulationClock).free()
	office.free()
	reference.free()

	var probe := preload("res://core/simulation/runtime_cost_probe.gd").new()
	check(probe.begin() == 0 and probe.snapshot().is_empty(), "Cost collection must be disabled in ordinary play")
	probe.finish(&"disabled", 0)
	probe.enabled = true
	for index in 50:
		probe.finish(StringName("stage_%d" % index), Time.get_ticks_usec() - 21000)
	var costs := probe.snapshot()
	check(costs.stages.size() == 32 and costs.spikes.size() == 24, "Opt-in cost history must remain bounded")
	costs.spikes.clear()
	costs.stages.clear()
	check(probe.snapshot().stages.size() == 32 and probe.snapshot().spikes.size() == 24, "Cost readers must not mutate retained diagnostics")

	# Exercise the real camera/ledger handoff after a normal floor publication.
	root.size = Vector2i(1280, 720)
	var live := Office.new()
	root.add_child(live)
	for _frame in 24:
		await process_frame
	var sim := live.get("_simulation") as DepartmentSimulation
	(live.get("_clock") as SimulationClock).set_speed(0)
	var camera := live.get("_camera_controller") as ManagementCameraController
	var snapshot := sim.snapshot(true, true)
	live.call("_apply_snapshot_presentation", snapshot)
	var retained := snapshot.duplicate(true)
	var exact_before := int(sim.runtime_projection_cache_diagnostics().exact_builds)
	camera.show_event_focus(Vector3.ZERO, "GOLDEN EGG", 1.55)
	live.call("_on_camera_focus_changed", "", -1)
	check(int(sim.runtime_projection_cache_diagnostics().exact_builds) == exact_before, "Automatic reward camera beats must not rebuild exact management catalogs")
	live.call("_on_character_dialogue_presented", {"presentation_mode": "ambient", "speaker_id": "mabel"})
	live.call("_on_character_dialogue_dismissed", &"test_ambient")
	check(int(sim.runtime_projection_cache_diagnostics().exact_builds) == exact_before, "Ambient dialogue handoffs must not rebuild exact management catalogs")
	check((live.get("_clock") as SimulationClock).speed_index == 0, "Ambient reactions must preserve the player's pause")
	check(snapshot == retained, "Camera reads must leave the previously published graph immutable")
	check(not bool(live.get("_flockwatch_open")), "Reward camera must preserve the closed ledger")
	# Once a real directive is filed, narrative dialogue must still pause and
	# restore the running shift. Ambient chatter above must never resume it.
	sim.select_directive(&"shell_assurance")
	var clock := live.get("_clock") as SimulationClock
	clock.set_speed(1)
	live.call("_on_character_dialogue_presented", {"presentation_mode": "visual_novel", "speaker_id": "mabel"})
	check(clock.speed_index == 0, "Narrative dialogue must retain its clock hold")
	live.call("_on_character_dialogue_dismissed", &"test_narrative")
	check(clock.speed_index == 1, "Narrative dismissal must restore the running pace")
	live.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("LATER_SHIFT_PRESENTATION_READS_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
