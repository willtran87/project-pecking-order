extends SceneTree

class CountingSimulation extends DepartmentSimulation:
	var playbook_reads := 0
	var catalog_reads := 0
	func playbook_snapshot(focused_worker_id: int = -1) -> Dictionary:
		playbook_reads += 1
		return super.playbook_snapshot(focused_worker_id)
	func claim_resolution_catalog() -> Array[Dictionary]:
		catalog_reads += 1
		return super.claim_resolution_catalog()

var failures: Array[String] = []

func check(condition: bool, reason: String) -> void:
	if not condition:
		failures.append(reason)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var sim := CountingSimulation.new(20261115, 4)
	var office := Office.new()
	# _ready normally parents this eagerly constructed clock. This unit fixture
	# deliberately stays outside the tree, so take ownership for cleanup here.
	office.add_child(office.get("_clock"))
	office.set("_simulation", sim)
	check(sim.select_directive(&"shell_assurance"), "Fixture enters a real running shift")
	for id in 4:
		sim.set_worker_at_workstation(id, true)
	for phase in 3:
		if phase == 1:
			check(sim.perform_playbook_action(&"preset", &"safe", 0).accepted, "Plan is filed through authority")
		elif phase == 2:
			sim.advance_tick()
		var catalogs_before := sim.catalog_reads
		var publication := sim.snapshot()
		check(sim.catalog_reads == catalogs_before + 1, "Full publication builds one shared choice catalog, not one per hen")
		var frozen := publication.duplicate(true)
		var reads := sim.playbook_reads
		var reused: Dictionary = office.call("_playbook_for_presentation", publication, -1)
		check(sim.playbook_reads == reads, "Unfocused publication must not rebuild its playbook")
		check(reused == sim.playbook_snapshot(), "Reused playbook includes immediate plan/tick changes")
		for id in [-1, 0, 1, 4]:
			var expected := sim.playbook_snapshot(id)
			reads = sim.playbook_reads
			var presented: Dictionary = office.call("_playbook_for_presentation", publication, id)
			check(presented == expected, "Focused options must retain exact hen-specific availability")
			check(sim.playbook_reads == reads + (0 if id < 0 else 1), "Only focused publications require another read")
		check(publication == frozen, "Presentation selection must not mutate the supplied publication")
	var fallback: Dictionary = office.call("_playbook_for_presentation", {}, -1)
	check(fallback == sim.playbook_snapshot(), "Partial publication must still get current playbook")
	for id in [-1, 0, 1, 4, 99]:
		for progress in [0.0, 55.0, 55.1, 99.0]:
			if id >= 0 and id < sim.workers.size():
				sim.workers[id].work_progress = progress
			var complete := sim.claim_resolution_status(id)
			check(complete.has("catalog") and not complete.catalog.is_empty(), "Public status always retains choices")
			complete.erase("catalog")
			var reads := sim.catalog_reads
			check(sim._claim_resolution_status(id) == complete, "Light status preserves cutoff, selected path and rejection reasons")
			check(sim.catalog_reads == reads, "Light status must never build discarded choice catalogs")
	var status := sim.claim_resolution_status(0)
	status.catalog[0].clear()
	check(not sim.claim_resolution_status(0).catalog[0].is_empty(), "Public choice catalogs remain isolated")
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("GAMEPLAY_PUBLICATION_READS_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
