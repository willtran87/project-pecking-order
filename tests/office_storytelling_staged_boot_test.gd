extends SceneTree

const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")

const OPTIONAL_ROOT_NAMES: Array[String] = [
	"ShellQualityLabVisual",
	"PackingAnnexVisual",
	"RecordsAnnexVisual",
	"FarmMutualServiceCoopVisual",
	"FarmMutualNegotiationRoomVisual",
	"FarmMutualContractBoardVisual",
	"CareCampusSpine",
	"WellnessNestVisual",
	"TrainingRoostVisual",
	"FarmerRelationsGalleryVisual",
	"OperationsCampusSpine",
	"RoosterOperationsOfficeVisual",
	"ITCoopVisual",
	"FlockRelationsOfficeVisual",
	"FeedProcurementCoopVisual",
	"FarmgateDispatchDepotVisual",
	"CampusExpansionVisual",
	"CampusPortfolioVisual",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var staging := OfficeStorytellingScript.new() as OfficeStorytelling
	staging.set_defer_optional_visuals(true)
	root.add_child(staging)

	_check(staging.find_child("RoosterManagementPerch", true, false) != null, "core management perch should exist immediately", failures)
	_check(staging.find_child("ArchiveAndIntakeStory", true, false) != null, "core intake story should exist immediately", failures)
	_check(staging.find_child("PackingAnnexVisual", true, false) == null, "optional campus should not block the core ready path", failures)
	var initial := staging.optional_visual_build_snapshot()
	_check(not bool(initial.get("ready", true)), "staged campus should initially report pending", failures)
	_check(int(initial.get("built_count", -1)) == 0, "staged campus should start at zero optional roots", failures)

	var snapshot := {
		"day": 8,
		"workers": [],
		"owned_facilities": {&"farmer_brand_packing_annex": 1},
		"facility_catalog": [
			{"id": &"farmer_brand_packing_annex", "level": 1, "owned": true},
		],
		"claim_queue_counts": {},
		"eggs_today": 0,
		"quota_target": 12,
		"eggs_total": 0,
		"claims_processed": 0,
	}
	staging.apply_snapshot(snapshot, false)
	staging.apply_campus_presentation(snapshot)

	var frame_budget := 80
	while not bool(staging.optional_visual_build_snapshot().get("ready", false)) and frame_budget > 0:
		await process_frame
		frame_budget -= 1
	var completed := staging.optional_visual_build_snapshot()
	_check(bool(completed.get("ready", false)), "staged campus should finish within the frame budget", failures)
	_check(int(completed.get("built_count", -1)) == OPTIONAL_ROOT_NAMES.size(), "every optional root should be accounted for", failures)
	_check((completed.get("build_timings_msec", {}) as Dictionary).size() == OPTIONAL_ROOT_NAMES.size(), "every staged root should publish a construction timing", failures)
	for root_name: String in OPTIONAL_ROOT_NAMES:
		_check(staging.find_children(root_name, "Node3D", true, false).size() == 1, "%s should be built exactly once" % root_name, failures)
	var packing := staging.find_child("PackingAnnexVisual", true, false) as Node3D
	_check(packing != null and packing.visible, "an owned facility should reconcile visibly after its deferred build", failures)
	var records := staging.find_child("RecordsAnnexVisual", true, false) as Node3D
	_check(records != null and not records.visible, "an unowned facility should remain hidden after its deferred build", failures)

	staging.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("OFFICE_STORYTELLING_STAGED_BOOT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_STORYTELLING_STAGED_BOOT_TEST_PASSED core=immediate optional=18 snapshot=reconciled duplicates=none")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
