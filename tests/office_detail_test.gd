extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame

	var required_details := [
		"BureauIdentity",
		"IdentityFascia",
		"OfficeClockFace",
		"ClaimsPipelineBoard",
		"CopierOutputTray",
		"ArchiveBox",
		"SafetyExtinguisher",
		"IntakeClaimBundle",
		"IntakeServiceBell",
		"EggScaleBase",
		"CandlingLamp",
		"BasketFrontSlat",
		"BasketHandle",
		"PresentationPlaqueTextFixture",
	]
	for detail_name in required_details:
		_check(office.find_child(detail_name, true, false) != null, "office should include %s" % detail_name, failures)

	_check(office.find_children("WindowMullion*", "MeshInstance3D", true, false).size() == 6, "every window should have a center mullion", failures)
	_check(office.find_children("Radiator_*", "MeshInstance3D", true, false).size() == 6, "every window bay should have modeled lower-wall depth", failures)
	_check(office.find_children("WallLightLens*", "MeshInstance3D", true, false).size() == 3, "office should include three wall light fixtures", failures)
	_check(office.find_children("PresentationEgg*", "MeshInstance3D", true, false).is_empty(), "farmer basket should start without decorative fake eggs", failures)
	_check(office.find_children("AuthoritativeClutchSlot_*", "Node3D", true, false).size() == 36, "farmer presentation should expose the authoritative living-clutch cups", failures)
	var window_pastures := office.find_children("WindowPasture*", "MeshInstance3D", true, false)
	_check(window_pastures.size() == 6, "every window should show the farm beyond the office (found %d)" % window_pastures.size(), failures)
	_check(office.find_children("EmployeeNameplateTextFixture", "Node3D", true, false).size() == 6, "every workstation should have a physically mounted nameplate", failures)
	var floor_chevrons := office.find_children("PeckFlowChevron*", "MeshInstance3D", true, false)
	_check(floor_chevrons.size() == 6, "access lanes should include floor storytelling (found %d)" % floor_chevrons.size(), failures)
	_check(office.find_child("HenOfMonthFrame", true, false) != null, "office should include farm-bureau wall storytelling", failures)
	var ledger := office.find_child("FlockwatchLedger", true, false) as Control
	_check(ledger != null and not ledger.visible, "Flockwatch ledger should default closed so it cannot obscure the office", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_DETAIL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_DETAIL_TEST_PASSED windows=6 personalized_desks=6 farm_story=expanded ledger=collapsed")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
