extends SceneTree

## Read-only Office presentation profiler. Run with:
## Godot --headless --path . --script tools/profile_office_presentation.gd

const SAMPLE_PASSES := 30


func _init() -> void:
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var simulation := office.get("_simulation") as DepartmentSimulation
	var snapshot := simulation.snapshot(true)
	office.call("_apply_snapshot_presentation", snapshot)
	var active_snapshot := office.call("_snapshot_with_active_workers", snapshot) as Dictionary
	var storytelling := office.get("_office_storytelling") as Node
	var workstation_feedback := office.get("_workstation_feedback") as Node
	var routing_ui := office.get("_routing_ui") as Node
	var flockwatch_navigation := office.get("_flockwatch_navigation") as Node
	var routing_snapshot := office.call("_routing_visual_snapshot", active_snapshot) as Dictionary
	var campaign_state = office.get("_campaign_state")
	var playbook := simulation.playbook_snapshot(-1)
	var components := {
		"active_worker_copy": func() -> void:
			office.call("_snapshot_with_active_workers", snapshot),
		"capacity_visibility": func() -> void:
			office.call("_apply_office_capacity_visibility", simulation.office_capacity),
		"worker_views": func() -> void:
			office.call("_reconcile_worker_views", snapshot),
		"campus_worker_duties": func() -> void:
			office.call("_sync_campus_worker_duties", snapshot),
		"workstation_nameplates": func() -> void:
			office.call("_refresh_workstation_nameplates", snapshot),
		"lighting": func() -> void:
			office.call("_update_lighting", snapshot),
		"storytelling_live": func() -> void:
			storytelling.call("apply_snapshot", active_snapshot, false),
		"campus_bounds": func() -> void:
			office.call("_update_campus_world_bounds", snapshot),
		"workstation_feedback": func() -> void:
			workstation_feedback.call(
				"apply_snapshot",
				office.call("_workstation_visual_snapshot", active_snapshot),
			),
		"visible_management": func() -> void:
			office.call("_refresh_visible_management_surfaces", snapshot),
		"routing": func() -> void:
			routing_ui.call(
				"apply_snapshot",
				office.call("_routing_visual_snapshot", active_snapshot),
			),
		"routing_snapshot_only": func() -> void:
			office.call("_routing_visual_snapshot", active_snapshot),
		"routing_ui_only": func() -> void:
			routing_ui.call("apply_snapshot", routing_snapshot),
		"priority_focus": func() -> void:
			office.call("_refresh_priority_peck_precision_focus", snapshot),
		"input_context": func() -> void:
			office.call("_refresh_floor_input_context", snapshot),
		"break_even_milestone": func() -> void:
			office.call("_update_break_even_milestone", snapshot),
		"hen_snapshots": func() -> void:
			var views: Dictionary = office.get("_worker_views")
			for worker: Dictionary in active_snapshot.get("workers", []):
				if views.has(int(worker.get("id", -1))):
					views[int(worker["id"])].apply_snapshot(worker),
		"policy_fit": func() -> void:
			office.call("_directive_order_fit", &"shell_assurance"),
		"first_clutch": func() -> void:
			office.call("_refresh_first_clutch_ui", snapshot),
		"flockwatch_accessibility": func() -> void:
			flockwatch_navigation.call("apply_accessibility_snapshot", snapshot),
		"campaign_objectives": func() -> void:
			office.call("_update_campaign_objectives_label", snapshot),
		"guidance": func() -> void:
			office.call("_update_guidance", snapshot),
		"gameplay_pulse": func() -> void:
			office.call("_refresh_gameplay_pulse", snapshot),
		"playbook_snapshot": func() -> void:
			simulation.playbook_snapshot(-1),
		"playbook_menu": func() -> void:
			office.call("_refresh_active_playbook_menu", playbook, -1),
		"next_action_diagnostic": func() -> void:
			office.call("_next_action_diagnostic_state"),
		"rival_snapshot": func() -> void:
			simulation.rival_coop_snapshot(campaign_state.get("probation_score"), campaign_state.get("completed_shifts")),
		"campaign_snapshot": func() -> void:
			campaign_state.call("snapshot"),
		"commendations": func() -> void:
			office.call("_update_commendations", snapshot),
	}
	var pulse := office.get("_gameplay_pulse") as Dictionary
	components["professional_polish"] = Callable(office, "_apply_professional_polish_presentation").bind(
		(pulse.get("intuitive_rewarding_completion", {}) as Dictionary).get("professional_polish", {}),
	)
	for layer in ["mastery_replay", "professional_loop", "rewarding_loop", "compelling_loop", "strategic_flow", "tactile_reward_loop", "experiential_management", "intuitive_reward", "consolidated_game_loop", "professional_gameplay_completion", "intuitive_rewarding_completion", "cohesive_game_loop_advancement"]:
		var key: String = layer
		if layer in ["strategic_flow", "experiential_management", "intuitive_reward"]:
			key += "_loop"
		components["apply_" + layer] = Callable(office, "_apply_" + layer + "_presentation").bind(pulse.get(key, {}))
	var component_profiles := {}
	for component_name in components:
		component_profiles[component_name] = _summary(
			_measure(components[component_name] as Callable),
		)

	var samples := _measure(func() -> void: office.call("_apply_snapshot_presentation", snapshot))
	print("OFFICE_PRESENTATION_PROFILE %s" % JSON.stringify({
		"repeated_snapshot": _summary(samples),
		"components": component_profiles,
		"presentation_updates": office.get("_presentation_update_count"),
		"pulse_stages": office.get("_gameplay_pulse_timing"),
	}))
	office.free()
	await process_frame
	quit(0)


func _measure(callable: Callable) -> Array[int]:
	var samples: Array[int] = []
	for _pass in SAMPLE_PASSES:
		var started := Time.get_ticks_usec()
		callable.call()
		samples.append(Time.get_ticks_usec() - started)
	return samples


func _summary(samples: Array[int]) -> Dictionary:
	var sorted := samples.duplicate()
	sorted.sort()
	var total := 0
	for sample in sorted:
		total += sample
	return {
		"count": sorted.size(),
		"average_usec": float(total) / maxf(1.0, float(sorted.size())),
		"median_usec": sorted[sorted.size() / 2],
		"p95_usec": sorted[mini(sorted.size() - 1, floori(sorted.size() * 0.95))],
		"maximum_usec": sorted[-1],
	}
