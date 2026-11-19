extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	var desks := Node3D.new()
	fixture.add_child(desks)
	var desk := (load("res://assets/models/office_workstation.glb") as PackedScene).instantiate() as Node3D
	desk.name = "Workstation_00"
	desks.add_child(desk)
	var feedback := WorkstationFeedback.new()
	fixture.add_child(feedback)
	feedback.configure(desks)
	feedback.set_process(false)
	var worker := {"id": 7, "name": "Test Hen", "desk_index": 0, "state": 1, "progress": 70.0, "stress": 15.0, "at_workstation": true, "current_claim": {"id": 1, "lane": "nest_damage", "minutes_until_deadline": 150}}
	feedback.apply_snapshot({"workers": [worker], "upgrade_levels": {}})
	var station = feedback.get("_stations_by_worker")[7]
	var nodes := fixture.find_children("*", "", true, false).size()
	for serial in 100:
		check(feedback.pulse_work_contact(7, serial), "occupied working contact accepted")
		feedback._process(0.05)
	check(fixture.find_children("*", "", true, false).size() == nodes, "frequent contacts cannot grow scene tree")
	check(station.peck_contact_disc.mesh == OfficeDeskDetails.contact_ring(), "contact ring is shared")
	for paper in station.activity_papers:
		check(paper.mesh.get_surface_count() == 1, "file print retains one draw surface")
		check(paper.material_override == OfficeDeskDetails.portrait_material(), "paper finishes shared across desks")
	check(OfficeDeskDetails.work_file(0) == OfficeDeskDetails.work_file(3), "file variants cached")
	check(OfficeDeskDetails.desk_inlay() == OfficeDeskDetails.desk_inlay(), "desk inlay cached")
	var bounds := OfficeDeskDetails.desk_inlay().get_aabb()
	check(bounds.position.z > -0.625 and bounds.end.z < 0.625, "writing pad and coaster stay inside desktop")
	for i in 10: feedback._process(0.05)
	check(not station.peck_contact_root.visible, "contact ripple retires between beats")
	var normal_energy := float(station.screen_material.emission_energy_multiplier)
	feedback.pulse_peck_assist(7, &"perfect", false)
	check(is_zero_approx(float(station.completion_boost)), "intermediate peck contact cannot prematurely celebrate")
	feedback.pulse_peck_assist(7, &"perfect")
	await create_timer(0.18).timeout
	feedback._process(0.05)
	check(station.screen_material.emission_energy_multiplier > normal_energy + 0.25, "earned response distinct from resting work")
	check(station.screen_material.emission_energy_multiplier < 1.15, "reward retains colored screen detail instead of bleaching")
	feedback.set_reduced_motion(true)
	var held := float(station.completion_boost)
	await create_timer(0.18).timeout
	feedback._process(0.05)
	check(is_equal_approx(float(station.completion_boost), held), "mid-reward reduced motion holds static feedback")
	var paper_y := float(station.activity_papers[0].position.y)
	feedback.pulse_work_contact(7, 101)
	feedback._process(0.05)
	check(is_equal_approx(float(station.activity_papers[0].position.y), paper_y), "reduced motion has no paper kick")
	await create_timer(0.55).timeout
	check(is_zero_approx(float(station.completion_boost)), "static reward still expires")
	worker.at_workstation = false
	feedback.apply_snapshot({"workers": [worker], "upgrade_levels": {}})
	check(not feedback.pulse_work_contact(7, 102), "unattended desk cannot invent a work event")
	fixture.free()
	await process_frame
	for failure in failures: push_error(failure)
	print("OFFICE_VISUAL_POLISH_TEST_PASSED resources=shared contact=bounded rewards=readable motion=accessible" if failures.is_empty() else "OFFICE_VISUAL_POLISH_TEST_FAILED")
	quit(0 if failures.is_empty() else 1)
