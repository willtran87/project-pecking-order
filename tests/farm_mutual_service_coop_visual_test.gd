extends SceneTree

const ServiceCoopVisualScript := preload("res://features/office/farm_mutual_service_coop_visual.gd")
const FACILITY_ID: StringName = &"farm_mutual_service_coop"
const EXPECTED_FOOTPRINT := Rect2(Vector2(12.00, 3.10), Vector2(6.40, 5.80))
const EXPECTED_FOCUS := Vector3(15.20, 1.05, 6.00)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var visual := ServiceCoopVisualScript.new() as FarmMutualServiceCoopVisual
	root.add_child(visual)
	await process_frame

	_check(FarmMutualServiceCoopVisual.declared_footprint() == EXPECTED_FOOTPRINT, "Service Coop should publish the exact northeast parcel", failures)
	_check(FarmMutualServiceCoopVisual.facility_focus_point() == EXPECTED_FOCUS, "Service Coop should publish its stable purchase focus", failures)
	_check(is_equal_approx(FarmMutualServiceCoopVisual.maximum_visual_height(), 4.25), "Service Coop should retain its 4.25m cap", failures)
	_check(visual.focus_point_global().is_equal_approx(EXPECTED_FOCUS), "identity-parented visual should resolve the exact global focus", failures)
	_check(visual.visual_state() == &"locked", "empty authoritative state should expose only the standing-gated lease", failures)
	_check(visual.locked_marker_visible() and not visual.survey_site_visible(), "locked state should not imply a funded survey", failures)
	_check(visual.geometry_bounds_inside_footprint(), "all hidden tiers and prebuild states should fit the declared footprint", failures)
	_check(visual.geometry_bounds_global().has_volume(), "Service Coop should expose non-empty authored geometry bounds", failures)
	_check(visual.find_children("*", "CollisionObject3D", true, false).is_empty(), "visual-only Service Coop should add no collision objects", failures)
	_check(visual.find_children("*", "CollisionShape3D", true, false).is_empty(), "visual-only Service Coop should add no collision shapes", failures)
	_check(visual.find_children("*", "NavigationRegion3D", true, false).is_empty(), "Service Coop should add no navigation regions", failures)
	_check(visual.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "Service Coop should add no navigation obstacles", failures)

	var survey_snapshot := _snapshot(0, {
		"standing": {
			"points": 2,
			"rank": "bronze",
			"next_threshold": 6,
			"facility_available": true,
		},
	})
	visual.apply_snapshot(survey_snapshot)
	_check(visual.visual_state() == &"survey", "authoritative standing availability should reveal the surveyed parcel", failures)
	_check(not visual.locked_marker_visible() and visual.survey_site_visible(), "survey should replace the lease boundary without implying ownership", failures)
	_check(visual.current_level() == 0, "standing availability alone must not invent a purchase", failures)
	var legacy_alias_snapshot := _snapshot(0, {
		"reputation": {
			"score": 5,
			"rank": "bronze",
			"next_rank_score": 6,
			"facility_available": true,
		},
	})
	visual.apply_snapshot(legacy_alias_snapshot)
	_check(visual.standing_score() == 5 and visual.standing_rank() == &"bronze", "legacy score/reputation aliases should remain readable without outranking canonical standing", failures)

	var bronze_snapshot := _snapshot(1, {
		"standing": {
			"points": 2,
			"rank": "bronze",
			"next_threshold": 6,
		},
		"active": {
			"contract_id": "FM-0004-HOMESTEAD",
			"required_completed": 4,
			"timely_sound_completed": 1,
		},
	})
	visual.apply_snapshot(bronze_snapshot)
	_check(visual.visual_state() == &"level_1", "level-one ownership should reveal Bronze Accreditation", failures)
	_check(visual.tier_visible(1) and not visual.tier_visible(2) and not visual.tier_visible(3), "Bronze purchase should reveal only its cumulative base tier", failures)
	_check(visual.tier_root(1) != null and visual.tier_root(1).name == "BronzeAccreditationDeskLevelOne", "tier accessor should return the authored Bronze root", failures)
	_check(visual.find_child("BronzeAccreditationServiceCounter", true, false) != null, "Bronze tier should physically add its service counter", failures)
	_check(visual.find_child("BronzeAccreditationSealPress", true, false) != null, "Bronze tier should physically add its seal press", failures)
	_check(visual.find_child("AuthoritativeStandingCertificateCase", true, false) != null, "Bronze tier should add its hosted standing case", failures)
	_check(visual.find_child("EmptyFarmMutualBinderPigeonholes", true, false) != null, "Bronze tier should add empty binder pigeonholes rather than fake files", failures)
	_check(visual.standing_score() == 2 and visual.standing_rank() == &"bronze", "standing display should consume the authoritative Bronze record", failures)
	_check(visual.lit_standing_segment_count() == 2, "two standing points should illuminate exactly two physical segments", failures)
	_check(visual.active_contract_id() == "FM-0004-HOMESTEAD", "service counter should retain the authoritative active binder identity", failures)
	_check(visual.visible_dispatch_packet_count() == 0, "unbought dispatch tier must not show completion packets", failures)

	var silver_snapshot := _snapshot(2, {
		"standing": {
			"points": 6,
			"rank": "silver",
			"next_threshold": 12,
		},
		"active_contract": {
			"contract_id": "FM-0007-PREDATOR",
			"required_completed": 5,
			"timely_sound_completed": 4,
			"rush_active": true,
		},
	})
	visual.apply_snapshot(silver_snapshot)
	_check(visual.visual_state() == &"level_2", "level-two ownership should reveal Silver Dispatch", failures)
	_check(visual.tier_visible(1) and visual.tier_visible(2) and not visual.tier_visible(3), "Silver purchase should retain Bronze geometry and add only tier two", failures)
	_check(visual.find_child("FarmMutualLaneDispatchTubes", true, false) != null, "Silver tier should add three connected dispatch tubes", failures)
	for lane in [&"nest_damage", &"predator_loss", &"appeals"]:
		_check(visual.find_child("DispatchTube_%s" % lane, true, false) != null, "Silver dispatch should include the %s lane tube" % lane, failures)
	_check(visual.find_child("FarmMutualCourierCage", true, false) != null, "Silver tier should add the grounded courier cage", failures)
	_check(visual.visible_dispatch_packet_count() == 4, "four timely completions should reveal exactly four stamped packets", failures)
	_check(visual.displayed_timely_completed() == 4 and visual.displayed_required_completed() == 5, "dispatch readout should retain the exact 4/5 binder state", failures)
	_check(visual.rush_beacon_active(), "authoritative rush state should power the physical amber beacon", failures)
	_check(visual.standing_rank() == &"silver" and visual.lit_standing_segment_count() == 6, "Silver record should light six standing segments", failures)

	var gold_snapshot := _snapshot(3, {
		"standing": {
			"points": 12,
			"rank": "gold",
			"next_threshold": 12,
		},
		"active": {},
		"last_result": {
			"status": "fulfilled",
			"service_coop_bonus_cents": 2160,
		},
	})
	visual.apply_snapshot(gold_snapshot)
	_check(visual.visual_state() == &"level_3", "level-three ownership should reveal the Gold Seal hall", failures)
	for tier in range(1, 4):
		_check(visual.tier_visible(tier), "Gold purchase should retain cumulative tier %d geometry" % tier, failures)
	_check(visual.find_child("FarmMutualGoldSealArch", true, false) != null, "Gold tier should add the narrow crest arch", failures)
	_check(visual.find_child("AccreditationContractVault", true, false) != null, "Gold tier should add its physical contract vault", failures)
	_check(visual.find_child("FarmMutualReputationTotem", true, false) != null, "Gold tier should add the standing totem", failures)
	_check(visual.find_child("AccreditationAttributionBackdrop", true, false) != null, "Gold tier should add the hosted attribution backdrop", failures)
	_check(visual.result_state() == &"success" and visual.success_indicator_active(), "fulfilled result should illuminate the Gold Seal indicator", failures)
	_check(visual.service_coop_bonus_cents() == 2160, "fulfilled result should consume the exact authoritative Service Coop bonus", failures)
	var bonus_readout := visual.find_child("AccreditationBonusReadout", true, false) as Label3D
	_check(bonus_readout != null and "21.60" in bonus_readout.text, "hosted bonus readout should disclose the exact $21.60 credit", failures)
	_check(not visual.breach_shutter_visible(), "fulfilled result should keep the breach shutter retracted", failures)
	_check(visual.lit_totem_segment_count() == 12, "Gold standing should illuminate all twelve totem segments", failures)
	_check(visual.visible_dispatch_packet_count() == 0, "cleared active binder should empty all authoritative packet slots", failures)

	var breached_snapshot := gold_snapshot.duplicate(true)
	breached_snapshot["contract_board"] = (gold_snapshot["contract_board"] as Dictionary).duplicate(true)
	(breached_snapshot["contract_board"] as Dictionary)["last_result"] = {
		"status": "breached",
		"breach_cents": 1200,
	}
	visual.apply_snapshot(breached_snapshot)
	_check(visual.result_state() == &"breach", "breached result should replace the success state", failures)
	_check(visual.service_coop_bonus_cents() == 0, "breached result should not invent a Service Coop bonus", failures)
	_check(visual.breach_shutter_visible(), "breached result should lower the physical red shutter", failures)
	_check(not visual.success_indicator_active(), "breached result should extinguish the Gold Seal success state", failures)
	_check(visual.geometry_bounds_inside_footprint(), "every cumulative and reactive Gold tier mesh should remain in the parcel", failures)

	var debug := visual.debug_state()
	_check(int(debug.get("facility_level", -1)) == 3, "debug state should disclose authoritative ownership", failures)
	_check(StringName(debug.get("result_state", &"")) == &"breach", "debug state should disclose the current outcome hardware", failures)
	_check(debug.get("footprint", Rect2()) == EXPECTED_FOOTPRINT, "debug state should retain the declared footprint", failures)

	visual.clear()
	visual.build()
	visual.apply_snapshot(gold_snapshot)
	_check(visual.tier_visible(1) and visual.tier_visible(2) and visual.tier_visible(3), "clear/build should safely reconstruct all cumulative roots", failures)
	_check(visual.geometry_bounds_inside_footprint(), "rebuilt visual should preserve its geometry contract", failures)

	visual.free()
	await process_frame
	if not failures.is_empty():
		for failure in failures:
			push_error("FARM_MUTUAL_SERVICE_COOP_VISUAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FARM_MUTUAL_SERVICE_COOP_VISUAL_TEST_PASSED footprint=northeast tiers=cumulative standing=authoritative packets=exact results=reactive collisions=none")
	quit(0)


func _snapshot(level: int, board: Dictionary) -> Dictionary:
	var board_snapshot := board.duplicate(true)
	board_snapshot["accreditation"] = {
		"level": level,
		"installed": level > 0,
		"unlocked": level > 0,
	}
	return {
		"owned_facilities": {String(FACILITY_ID): level},
		"facility_catalog": [{
			"id": String(FACILITY_ID),
			"level": level,
			"installed": level > 0,
			"unlocked": level > 0,
		}],
		"contract_board": board_snapshot,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
