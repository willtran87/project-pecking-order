extends SceneTree

class HoverOffice extends Office:
	var testing_hover := false
	func _blocking_management_surface_open() -> bool:
		return false if testing_hover else super._blocking_management_surface_open()
	func _first_clutch_tracking_active() -> bool:
		return false if testing_hover else super._first_clutch_tracking_active()

class CountingSimulation extends DepartmentSimulation:
	var reads := 0
	func snapshot(cached: bool = false, trusted: bool = false) -> Dictionary:
		reads += 1
		return super.snapshot(cached, trusted)

class CountingStory extends OfficeStorytelling:
	var reads := 0
	func campus_presentation_snapshot() -> Dictionary:
		reads += 1
		return super.campus_presentation_snapshot()

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var story := CountingStory.new()
	var source := {"day": 1, "owned_facilities": {}, "facility_catalog": []}
	story.update_campus_presentation(source)
	check(story.reads == 0, "Scene-only campus updates must not construct discarded public snapshots")
	var first := story.apply_campus_presentation(source)
	check(story.reads == 1 and not first.is_empty(), "Public campus updates must return one complete snapshot")
	var frozen := first.duplicate(true)
	for day in [2, 3, 5, 6]:
		source.day = day
		story.update_campus_presentation(source, {"show_next_teaser": true})
	check(story.reads == 1 and first == frozen, "New scene states must not mutate retained projections or make unused copies")
	first.clear()
	check(not story.campus_presentation_snapshot().is_empty(), "Public campus snapshots must remain isolated from callers")
	story.free()
	root.size = Vector2i(1280, 720)
	var office := HoverOffice.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var clock := office.get("_clock") as SimulationClock
	clock.set_process(false)
	clock.set_speed(0)
	office.set_process(false)
	office.testing_hover = true
	var original: DepartmentSimulation = office.get("_simulation")
	var simulation := CountingSimulation.new()
	office.set("_simulation", simulation)
	var ticker := office.get("_ticker_label") as Label
	ticker.text = "ORIGINAL STATUS"
	var hen := simulation.workers[0]
	hen.display_name = "Renamed Hen"
	for context in [&"equipment", &"work_progress", &"hen_intent"]:
		office.call("_on_management_context_hover_changed", hen.id, context, true)
		var expected := "VIEW UPGRADES" if context == &"equipment" else "VIEW FILE" if context == &"work_progress" else "HELP RENAMED HEN"
		check(ticker.text == expected, "Pointer hints must retain current action and hen identity")
		office.call("_on_management_context_hover_changed", hen.id, context, false)
		check(ticker.text == "ORIGINAL STATUS", "Leaving a target must restore its previous status")
	check(simulation.reads == 0, "Hovering scene targets must not rebuild exact economic snapshots")
	office.set("_simulation", original)
	office.free()
	await process_frame
	for failure in failures:
		push_error(failure)
	print("SCENE_INTERACTION_READS_TEST_%s" % ("PASSED" if failures.is_empty() else "FAILED"))
	quit(0 if failures.is_empty() else 1)
