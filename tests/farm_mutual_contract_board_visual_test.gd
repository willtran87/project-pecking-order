extends SceneTree

const ContractBoardVisualScript := preload("res://features/office/farm_mutual_contract_board_visual.gd")
const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var board := ContractBoardVisualScript.new() as FarmMutualContractBoardVisual
	root.add_child(board)
	await process_frame

	_check(board.visual_state() == &"locked", "fresh board should preserve its locked state", failures)
	_check(not board.season_medallion_visible(), "locked legacy board should not invent a season medallion", failures)
	_check(not board.active_rider_visible(), "locked legacy board should not invent a rider slip", failures)
	_check(ContractBoardVisualScript.declared_footprint() == Rect2(Vector2(-11.82, -1.66), Vector2(0.46, 3.32)), "board should retain its exact shallow wall parcel", failures)
	_check(board.geometry_bounds_inside_footprint(), "all board hardware should remain inside its original footprint", failures)
	_check(board.find_children("*", "CollisionObject3D", true, false).is_empty(), "board enhancement should remain non-colliding", failures)
	_check(board.find_children("*", "NavigationRegion3D", true, false).is_empty(), "board enhancement should not add navigation regions", failures)
	_check(board.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "board enhancement should not add navigation obstacles", failures)
	_check(board.find_children("FarmMutualActiveRiderSlip", "Node3D", true, false).size() == 1, "board should author exactly one reusable rider slip", failures)

	var offers := _offers()
	board.apply_snapshot({
		"contract_board": {
			"unlocked": true,
			"offers": offers,
			"active": {},
			"last_result": {},
		},
	})
	_check(board.visual_state() == &"open", "legacy unlocked board should preserve its open state", failures)
	_check(board.visible_offer_count() == 3, "legacy open board should preserve all three physical folders", failures)
	_check(not board.season_medallion_visible(), "legacy open snapshot without season should keep the medallion absent", failures)
	_check(not board.active_rider_visible(), "open standard board should keep its rider slip absent", failures)

	var standard_active := offers[0].duplicate(true)
	standard_active["clause_id"] = &"standard_terms"
	standard_active["clause_label"] = "STANDARD TERMS"
	standard_active["clause_category"] = &"standard"
	board.apply_snapshot({
		"contract_board": {
			"unlocked": true,
			"season": {
				"id": &"summer_predator_migration",
				"label": "SUMMER PREDATOR MIGRATION",
			},
			"offers": offers,
			"active": standard_active,
			"last_result": {},
		},
	})
	_check(board.visual_state() == &"active", "standard signed binder should preserve the active board state", failures)
	_check(board.season_medallion_visible(), "authoritative season should reveal one restrained physical medallion", failures)
	_check(board.season_key() == "SUMMER PREDATOR MIGRATION", "season medallion should retain authoritative label copy", failures)
	_check(board.active_clause_id() == &"standard_terms", "board should retain the standard clause id", failures)
	_check(not board.active_rider_visible(), "standard terms must never imply a negotiated rider", failures)

	var negotiated_active := offers[1].duplicate(true)
	negotiated_active["clause_id"] = &"expedited_hatch_rider"
	negotiated_active["clause_label"] = "EXPEDITED HATCH RIDER"
	negotiated_active["clause_category"] = &"schedule"
	board.apply_snapshot({
		"contract_board": {
			"unlocked": true,
			"season": {
				"id": &"summer_predator_migration",
				"label": "SUMMER PREDATOR MIGRATION",
			},
			"offers": offers,
			"active": negotiated_active,
			"last_result": {},
		},
	})
	_check(board.visual_state() == &"active", "negotiated binder should remain in the established active state", failures)
	_check(board.active_contract_id() == &"predator_watch_pool", "rider enhancement should preserve the active base contract id", failures)
	_check(board.active_clause_id() == &"expedited_hatch_rider", "rider slip should retain the exact authoritative clause id", failures)
	_check(board.active_clause_category() == &"schedule", "rider strip should retain the exact authoritative category", failures)
	_check(board.active_rider_visible(), "negotiated clause should reveal exactly one physical rider slip", failures)
	_check(board.find_children("FarmMutualActiveRiderSlip", "Node3D", true, false).size() == 1, "negotiated state must not duplicate the rider hardware", failures)
	var rider_label := board.find_child("ActiveClauseRiderCopy", true, false) as Label3D
	_check(rider_label != null and "EXPEDITED HATCH RIDER" in rider_label.text and "SCHEDULE" in rider_label.text, "rider paper should carry authoritative label and category copy", failures)
	_check(rider_label != null and rider_label.get_parent() != null and bool(rider_label.get_parent().get_meta(&"host_attached", false)), "rider copy should stay physically attached to its paper host", failures)
	_check(rider_label != null and StringName(rider_label.get_meta(&"sign_tier", &"")) == &"utility", "rider copy should remain subordinate utility text", failures)
	EnvironmentalSignageScript.set_camera_detail(board, false, Vector3(INF, INF, INF), 2.75, false)
	_check(rider_label != null and not rider_label.is_visible_in_tree(), "rider microcopy should disappear in overview while its physical slip remains", failures)
	if rider_label != null:
		EnvironmentalSignageScript.set_camera_detail(board, true, rider_label.global_position, 2.75, false)
		_check(rider_label.is_visible_in_tree(), "focused board detail should reveal the hosted rider copy", failures)
	_check(board.geometry_bounds_inside_footprint(), "season and rider hardware should not grow the board footprint", failures)

	board.apply_snapshot({
		"contract_board": {
			"unlocked": true,
			"season": {"label": "AUTUMN APPEAL HARVEST"},
			"offers": offers,
			"active": {},
			"last_result": {"status": "fulfilled", "premium_cents": 9200},
		},
	})
	_check(board.visual_state() == &"success" and board.success_stamp_visible(), "existing success state should remain intact", failures)
	_check(board.season_medallion_visible() and board.season_key() == "AUTUMN APPEAL HARVEST", "result state should retain the authoritative season medallion", failures)
	_check(not board.active_rider_visible(), "cleared active contract should remove the rider slip", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FARM_MUTUAL_CONTRACT_BOARD_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARM_MUTUAL_CONTRACT_BOARD_VISUAL_TEST_PASSED states=preserved season=physical rider=exactly-one standard=none detail=subordinate footprint=unchanged collisions=0")
	quit(0)


func _offers() -> Array[Dictionary]:
	return [
		{
			"id": &"steady_roost_pool",
			"name": "Steady Roost Pool",
			"lane_mix": {&"nest_damage": 3},
			"premium_cents": 7200,
			"breach_cents": 3600,
			"required_completed": 5,
			"deadline_day": 3,
		},
		{
			"id": &"predator_watch_pool",
			"name": "Predator Watch Pool",
			"lane_mix": {&"predator_loss": 3},
			"premium_cents": 8800,
			"breach_cents": 5100,
			"required_completed": 6,
			"deadline_day": 3,
			"rush_claims": 1,
		},
		{
			"id": &"appeal_harvest_pool",
			"name": "Appeal Harvest Pool",
			"lane_mix": {&"appeals": 3},
			"premium_cents": 10300,
			"breach_cents": 6400,
			"required_completed": 7,
			"deadline_day": 3,
		},
	]


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
