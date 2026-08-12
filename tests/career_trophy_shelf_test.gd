extends SceneTree

const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var staging := OfficeStorytellingScript.new() as OfficeStorytelling
	staging.set_defer_optional_visuals(false)
	root.add_child(staging)
	var shelf := staging.find_child("CareerTrophyShelf", true, false)
	var label := staging.find_child("CareerTrophyLabel", true, false) as Label3D
	var slots: Array[Node] = []
	for slot_index in 12:
		var slot := staging.find_child("CareerTrophy_%02d" % (slot_index + 1), true, false)
		if slot != null:
			slots.append(slot)
	_check(shelf != null and label != null and slots.size() == 12, "the management perch should carry one physical twelve-slot career shelf", failures)
	staging.set_commendations_snapshot({"earned_count": 5, "total_count": 12})
	var earned_count := 0
	for slot in slots:
		if bool(slot.get_meta("commendation_earned", false)):
			earned_count += 1
	_check(earned_count == 5 and label.text == "CAREER FILE  /  5 OF 12", "earned commendations should become five visible brass trophies with a compact count", failures)
	staging.configure(OfficeStorytellingScript.DEFAULT_DESK_POSITIONS)
	var rebuilt_label := staging.find_child("CareerTrophyLabel", true, false) as Label3D
	var rebuilt_earned := 0
	for slot_index in 12:
		var rebuilt_slot := staging.find_child("CareerTrophy_%02d" % (slot_index + 1), true, false)
		if rebuilt_slot != null and bool(rebuilt_slot.get_meta("commendation_earned", false)):
			rebuilt_earned += 1
	_check(rebuilt_label != null and rebuilt_label.text == "CAREER FILE  /  5 OF 12" and rebuilt_earned == 5, "rebuilding the same office between shifts should preserve the authoritative trophy display", failures)
	staging.queue_free()

	if failures.is_empty():
		print("CAREER_TROPHY_SHELF_TEST_PASSED slots=12 earned=5 rebuild=consistent furnishing=physical")
		quit(0)
		return
	for failure in failures:
		push_error("CAREER_TROPHY_SHELF_TEST_FAILED: %s" % failure)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
