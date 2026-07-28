extends SceneTree

## Read-only projection profiler. Run with:
## Godot --headless --path . --script tools/profile_runtime_projections.gd

const SAMPLE_PASSES := 30


func _init() -> void:
	var simulation := DepartmentSimulation.new(290719)
	simulation.select_directive(&"shell_assurance")
	for worker in simulation.workers:
		if worker.employed:
			simulation.set_worker_at_workstation(worker.id, true)

	var projections := {
		"contract_board": func() -> Variant: return simulation.market_contract_board_status(),
		"service_coop": func() -> Variant: return simulation.farm_mutual_service_coop_status(),
		"negotiation_room": func() -> Variant: return simulation.farm_mutual_negotiation_room_status(),
		"economic_briefing": func() -> Variant: return simulation.economic_briefing_snapshot(),
		"feed_procurement": func() -> Variant: return simulation.feed_procurement_snapshot(),
		"campus_expansion": func() -> Variant: return simulation.campus_expansion_snapshot(),
		"campus_portfolio": func() -> Variant:
			return simulation.campus_portfolio_snapshot(simulation.campus_expansion_snapshot()),
		"staffing_catalog": func() -> Variant: return simulation.staffing_catalog(),
		"facility_catalog": func() -> Variant: return simulation.facility_catalog(),
		"flock_care": func() -> Variant: return simulation.flock_care_snapshot(),
		"operations": func() -> Variant: return simulation.operations_snapshot(),
		"current_pecking_order": func() -> Variant: return simulation.current_pecking_order(),
		"case_docket": func() -> Variant: return simulation.case_docket_snapshot(),
		"incident_pivot_mastery": func() -> Variant: return simulation.incident_pivot_mastery_snapshot(),
		"claim_resolution_catalog": func() -> Variant: return simulation.claim_resolution_catalog(),
		"queue_snapshot": func() -> Variant: return simulation.call("_queue_snapshot"),
		"farm_treasury": func() -> Variant: return simulation.farm_treasury_snapshot(),
		"farmer_relations_gallery": func() -> Variant: return simulation.farmer_relations_gallery_snapshot(),
		"farmgate_dispatch": func() -> Variant: return simulation.farmgate_dispatch_snapshot(),
		"facility_effects": func() -> Variant: return simulation.facility_effects(),
		"capital_plan": func() -> Variant: return simulation.capital_plan_snapshot(),
		"flock_relations": func() -> Variant: return simulation.flock_relations_snapshot(),
		"packing_contract": func() -> Variant: return simulation.packing_contract_status(),
		"leadership_record": func() -> Variant: return simulation.leadership_record_snapshot(),
		"work_to_rule": func() -> Variant: return simulation.work_to_rule_snapshot(),
		"active_directive": func() -> Variant: return simulation.active_directive_snapshot(),
		"pending_decision": func() -> Variant: return simulation.pending_decision_snapshot(),
		"incident_responses": func() -> Variant: return simulation.incident_responses_for_day(simulation.day),
		"upgrade_catalog": func() -> Variant: return simulation.upgrade_catalog(),
		"first_clutch_reinvestment": func() -> Variant: return simulation.first_clutch_reinvestment_status(),
		"routing_catalog": func() -> Variant: return simulation.routing_catalog(),
		"campaign_unlock_effects": func() -> Variant: return simulation.campaign_unlock_effects(),
		"personnel_status": func() -> Variant: return simulation.personnel_action_status(),
		"personnel_catalog": func() -> Variant: return simulation.personnel_action_catalog(),
		"worker_base_snapshots": func() -> Variant:
			var rows: Array = []
			var now := int(simulation.call("_current_operational_minute"))
			for worker in simulation.workers:
				rows.append(worker.snapshot(now))
			return rows,
		"worker_flock_bonds": func() -> Variant:
			var rows: Array = []
			for worker in simulation.workers:
				rows.append(simulation.call("_worker_flock_bond_snapshot", worker))
			return rows,
		"worker_temperaments": func() -> Variant:
			var rows: Array = []
			for worker in simulation.workers:
				rows.append(simulation.call("_worker_temperament_effect", worker))
			return rows,
		"worker_peck_assists": func() -> Variant:
			var rows: Array = []
			for worker in simulation.workers:
				rows.append(simulation.peck_assist_status(worker.id))
			return rows,
		"worker_resolution_statuses": func() -> Variant:
			var rows: Array = []
			for worker in simulation.workers:
				rows.append(simulation.claim_resolution_status(worker.id))
			return rows,
		"worker_welfare_scores": func() -> Variant:
			var rows: Array = []
			for worker in simulation.workers:
				rows.append(simulation.call("_worker_welfare_score", worker))
			return rows,
	}
	var result := {}
	for projection_name in projections:
		var callable := projections[projection_name] as Callable
		var samples: Array[int] = []
		for _pass in SAMPLE_PASSES:
			var started := Time.get_ticks_usec()
			callable.call()
			samples.append(Time.get_ticks_usec() - started)
		result[projection_name] = _summary(samples)
	print("RUNTIME_PROJECTION_PROFILE %s" % JSON.stringify(result))
	quit(0)


func _summary(samples: Array[int]) -> Dictionary:
	var sorted := samples.duplicate()
	sorted.sort()
	var total := 0
	for sample in sorted:
		total += sample
	return {
		"average_usec": float(total) / maxf(1.0, float(sorted.size())),
		"median_usec": sorted[sorted.size() / 2],
		"p95_usec": sorted[mini(sorted.size() - 1, floori(sorted.size() * 0.95))],
		"maximum_usec": sorted[-1],
	}
