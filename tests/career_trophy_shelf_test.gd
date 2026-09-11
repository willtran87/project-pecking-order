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
	var mastery_label := staging.find_child("ScenarioMasteryPlaque", true, false) as Label3D
	var slots: Array[Node] = []
	for slot_index in 12:
		var slot := staging.find_child("CareerTrophy_%02d" % (slot_index + 1), true, false)
		if slot != null:
			slots.append(slot)
	_check(shelf != null and label != null and slots.size() == 12, "the management perch should carry one physical twelve-slot career shelf", failures)
	staging.apply_scenario_mastery({
		"current_scenario_mastery": {
			"earned_count": 2,
			"next_stamp_detail": "Next stamp: pass with a score of 80 or higher.",
		},
	})
	_check(
		mastery_label != null
		and "●●○" in mastery_label.text
		and int(mastery_label.get_meta("earned_count", 0)) == 2,
		"the office should mount the current scenario's derived mastery stamps physically",
		failures,
	)
	staging.apply_career_profile({
		"id": "brass_beak",
		"label": "BRASS BEAK BUREAU",
		"emblem": "BRASS EGG",
		"color": "d1a650",
		"promise": "Every result earns a visible receipt.",
		"ritual": "Every clean clutch receives a brass seal.",
		"prop": "BRASS CLUTCH SEAL",
	})
	var brass_prop := staging.find_child("BrassBeakIdentityProp", true, false) as Node3D
	var nest_prop := staging.find_child("OpenNestIdentityProp", true, false) as Node3D
	_check(
		brass_prop != null and brass_prop.visible and nest_prop != null and not nest_prop.visible,
		"the selected co-op identity should own one distinct physical office signature",
		failures,
	)
	staging.set_commendations_snapshot({"earned_count": 5, "total_count": 12})
	var earned_count := 0
	for slot in slots:
		if bool(slot.get_meta("commendation_earned", false)):
			earned_count += 1
	_check(earned_count == 5 and label.text == "CAREER FILE  /  5 OF 12", "earned commendations should become five visible brass trophies with a compact count", failures)
	staging.set_commendations_snapshot({
		"earned_count": 5,
		"total_count": 12,
		"management_identity": {
			"id": &"shared_scoop",
			"title": "FLOCK STEWARD",
		},
	})
	_check(
		label.text == "FLOCK STEWARD  /  5 OF 12"
		and String(label.get_meta("management_identity", "")) == "shared_scoop",
		"the physical career shelf should visibly adopt the player's earned management identity",
		failures,
	)
	staging.configure(OfficeStorytellingScript.DEFAULT_DESK_POSITIONS)
	var rebuilt_label := staging.find_child("CareerTrophyLabel", true, false) as Label3D
	var rebuilt_earned := 0
	for slot_index in 12:
		var rebuilt_slot := staging.find_child("CareerTrophy_%02d" % (slot_index + 1), true, false)
		if rebuilt_slot != null and bool(rebuilt_slot.get_meta("commendation_earned", false)):
			rebuilt_earned += 1
	_check(rebuilt_label != null and rebuilt_label.text == "FLOCK STEWARD  /  5 OF 12" and rebuilt_earned == 5, "rebuilding the same office between shifts should preserve the authoritative trophy display and identity", failures)
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
