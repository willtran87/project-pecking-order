extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	var desks := Node3D.new()
	host.add_child(desks)
	for index in 2:
		var desk := (load("res://assets/models/office_workstation.glb") as PackedScene).instantiate() as Node3D
		desk.name = "Workstation_%02d" % index
		desks.add_child(desk)
	var feedback := WorkstationFeedback.new()
	host.add_child(feedback)
	feedback.configure(desks)
	feedback.set_process(false)
	var sim := DepartmentSimulation.new(1701, 4)
	sim.select_directive(&"shell_assurance")
	var row := sim.workers[0].snapshot()
	row.desk_index = 0
	feedback.apply_snapshot({"workers": [row], "upgrade_levels": {}})
	var station = feedback.get("_stations_by_worker")[0]
	var initial_mesh: Mesh = station.identity_display.mesh
	check(initial_mesh == HenDeskIdentity.record(0, 0), "New hires have their own keepsake and no earned seals")
	var nodes := host.find_children("*", "", true, false).size()
	for _pass in 100:
		feedback.apply_snapshot({"workers": [row], "upgrade_levels": {}})
	check(station.identity_display.mesh == initial_mesh, "Unchanged ticks must reuse the display mesh")
	check(host.find_children("*", "", true, false).size() == nodes, "Repeated updates cannot grow the scene")
	# Exercise the career authority's XP thresholds, including serialized restore.
	for tier in [1, 2, 3]:
		sim.workers[0].career_xp = ChickenState.CAREER_THRESHOLDS[tier]
		var restored := DepartmentSimulation.new(11, 4)
		check(restored.restore_save_state(JSON.parse_string(JSON.stringify(sim.export_save_state()))), "Career identity survives the existing save boundary")
		row = restored.workers[0].snapshot()
		feedback.apply_snapshot({"workers": [row], "upgrade_levels": {"shell_lamp": tier}})
		check(station.identity_display.mesh == HenDeskIdentity.record(0, tier), "Only earned XP grants the corresponding career seals")
		check(station.hardware_badges[&"shell_lamp"].get_meta("level") == tier, "Hardware level marks follow the installed level")
		check(station.hardware_badges[&"shell_lamp"].mesh.get_surface_count() == 1, "Hardware icon, mount and level marks use one surface")
	var promoted_mesh: Mesh = station.identity_display.mesh
	row.desk_index = 1
	feedback.apply_snapshot({"workers": [row], "upgrade_levels": {"shell_lamp": 3}})
	check(not station.identity_display.visible, "A vacated desk cannot retain another hen's career seals")
	var moved = feedback.get("_stations_by_worker")[0]
	check(moved.identity_display.mesh == promoted_mesh, "Keepsake and earned seals follow the hen when her desk changes")
	feedback.configure(desks)
	check(desks.find_children("PerchCareerDisplay", "", true, false).size() == 2, "Reconfiguration replaces runtime displays without duplication")
	var meshes := {}
	for id in 6:
		var record := HenDeskIdentity.record(id, 0)
		meshes[record.get_instance_id()] = true
		check(record == HenDeskIdentity.record(id + 6, 0), "Identity geometry cache is bounded to six temperaments")
		check(record.get_surface_count() == 1, "Keepsake and seals share one draw")
	check(meshes.size() == 6, "Every temperament has distinct desk art")
	check(OfficeSurfaceFinish.material(&"cloth", Color.WHITE, 8) == OfficeSurfaceFinish.material(&"linen", Color.WHITE, 8), "Clothes reuse the baked linen bank")
	check(ChickenView._identity_finish(&"feather", Color.WHITE, 0.88, 0.24) == ChickenView._identity_finish(&"feather", Color.WHITE, 0.88, 0.24), "Hen materials are shared across instances")
	var feather := ChickenView._identity_finish(&"feather", Color.WHITE, 0.88, 0.24)
	var leather := ChickenView._identity_finish(&"leather", Color("76523b"), 0.60, 0.28)
	check(leather.albedo_texture == null and leather.roughness < feather.roughness, "Smooth leather remains distinct from feathers and woven clothing")
	host.free()
	await process_frame
	for failure in failures: push_error(failure)
	print("HEN_IDENTITY_PROGRESSION_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
