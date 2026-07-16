extends SceneTree


const GALLERY := DepartmentSimulation.FARMER_RELATIONS_GALLERY_ID
const PACKING := DepartmentSimulation.PACKING_ANNEX_ID


func _init() -> void:
	var failures: Array[String] = []
	_test_facility_tiers_and_dependencies(failures)
	_test_authored_quotes_and_standing(failures)
	_test_review_campaign_effects_and_atomicity(failures)
	_test_explicit_skip(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("HARVEST_CREDIT_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("HARVEST_CREDIT_ECONOMY_TEST_PASSED tiers=exact evidence=frozen offers=three payouts=exact effects=causal atomic=yes skip=explicit")
	quit(0)


func _test_facility_tiers_and_dependencies(failures: Array[String]) -> void:
	var sim := DepartmentSimulation.new(19_001, 6)
	sim.shift_phase = DepartmentSimulation.ShiftPhase.REVIEW
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	var costs := [9_000, 15_000, 24_000]
	var upkeep := [500, 900, 1_500]
	var days := [5, 9, 13]
	for index in 3:
		sim.day = days[index]
		var blocked := sim.facility_status(GALLERY)
		_check(int(blocked.get("required_packing_annex_level", -1)) == index + 1, "Gallery tier %d should require the matching Packing Annex" % (index + 1), failures)
		_check(not bool(blocked.get("can_purchase", true)), "Gallery tier %d should reject before its Packing dependency" % (index + 1), failures)
		sim.owned_facilities[PACKING] = index + 1
		var ready := sim.facility_status(GALLERY)
		_check(int(ready.get("cost_cents", -1)) == costs[index], "Gallery tier %d should expose its exact capital cost" % (index + 1), failures)
		_check(int(ready.get("next_maintenance_cents", -1)) == upkeep[index], "Gallery tier %d should expose cumulative upkeep" % (index + 1), failures)
		_check(bool(ready.get("can_purchase", false)), "funded Gallery tier %d should pass its authored gates" % (index + 1), failures)
		var receipt := sim.purchase_facility(GALLERY)
		_check(bool(receipt.get("accepted", false)), "Gallery tier %d purchase should be accepted" % (index + 1), failures)
	_check(sim.facility_catalog().size() == 13, "the fixed facility catalog should contain exactly thirteen facilities", failures)


func _test_authored_quotes_and_standing(failures: Array[String]) -> void:
	var evidence := _evidence(5, 10, 8, 2, 1)
	var state := HarvestCreditState.new()
	_check(state.stage_review(evidence, 1, false), "tier-one evidence should open a review", failures)
	var layer := state.campaign_quote(&"layer_profile")
	var clutch := state.campaign_quote(&"clutch_results_board")
	var farmer := state.campaign_quote(&"farmer_method")
	_check(int(layer.get("base_payout_cents", -1)) == 260, "tier-one Layer Profile should pay 8x20 + 1x100 cents", failures)
	_check(int(clutch.get("base_payout_cents", -1)) == 195, "tier-one Clutch Board should pay 8x15 + 1x75 cents", failures)
	_check(int(farmer.get("base_payout_cents", -1)) == 480, "tier-one Farmer Method should pay 8x35 + 1x200 cents", failures)
	_check(int(layer.get("public_standing_delta", -1)) == 3, "Layer reach should include base, quota, and one golden point", failures)
	_check(int(farmer.get("public_standing_delta", -1)) == 5, "Farmer reach should include base, quota, and one golden point", failures)
	var first := state.commit_campaign(&"farmer_method", "Filed")
	_check(int(first.get("public_standing_after", -1)) == 5, "first campaign should reach Roadside Notice standing", failures)
	_check(HarvestCreditState.standing_label_for(5) == "ROADSIDE NOTICE", "standing labels should change at five points", failures)

	_check(state.stage_review(_evidence(6, 10, 8, 2, 1), 2, false), "next completed shift should replace the review", failures)
	farmer = state.campaign_quote(&"farmer_method")
	_check(int(farmer.get("base_payout_cents", -1)) == 660, "tier-two Farmer Method should pay 8x45 + 1x300 cents", failures)
	_check(int(farmer.get("standing_bonus_basis_points", -1)) == 250, "five prior standing should add exactly 250 basis points", failures)
	_check(int(farmer.get("payout_cents", -1)) == 677, "standing-adjusted payout should use deterministic half-up cents", failures)
	_check(int(farmer.get("public_standing_delta", -1)) == 6, "tier two should add one reach point without changing the choice set", failures)


func _test_review_campaign_effects_and_atomicity(failures: Array[String]) -> void:
	var sim := _completed_shift_fixture(19_101, 1)
	var gallery := sim.farmer_relations_gallery_snapshot()
	_check(StringName(gallery.get("campaign_status", &"")) == &"offer_open", "completed Day 5 should open one Gallery campaign", failures)
	_check((gallery.get("offers", []) as Array).size() == 3, "all three authored campaigns should be available from level one", failures)
	_check(int((gallery.get("shift_evidence", {}) as Dictionary).get("sound", -1)) == 8, "Gallery evidence should freeze eggs minus cracks", failures)
	var fund_before := sim.revenue_cents
	var trust_before := sim.workers[0].manager_trust
	var grievance_before := sim.workers[0].grievance
	var stress_before := sim.workers[0].stress
	var favor_before := sim.executive_confidence
	var compliance_before := sim.compliance
	var solidarity_before := sim.solidarity
	var quota_before := sim.quota_target
	var result := sim.file_farmer_relations_campaign(&"farmer_method")
	_check(bool(result.get("accepted", false)), "valid review-time Farmer Method should file", failures)
	_check(int(result.get("payout_cents", -1)) == 480 and sim.revenue_cents == fund_before + 480, "campaign payout should credit exactly once", failures)
	_check(is_equal_approx(sim.workers[0].manager_trust, trust_before - 4.0), "Farmer Method should lower every active hen's trust by four", failures)
	_check(is_equal_approx(sim.workers[0].grievance, grievance_before + 5.0), "Farmer Method should add five grievance", failures)
	_check(is_equal_approx(sim.workers[0].stress, stress_before + 2.0), "Farmer Method should add two stress", failures)
	_check(is_equal_approx(sim.executive_confidence, favor_before + 6.0), "Farmer Method should add six farmer favor", failures)
	_check(is_equal_approx(sim.compliance, compliance_before - 2.0), "Farmer Method should lower compliance by two", failures)
	_check(is_equal_approx(sim.solidarity, solidarity_before + 4.0), "Farmer Method should add four solidarity", failures)
	_check(sim.quota_target == quota_before + 1, "Farmer Method should add one next-shift file", failures)
	var after := JSON.stringify(sim.export_save_state())
	var duplicate := sim.file_farmer_relations_campaign(&"farmer_method")
	_check(not bool(duplicate.get("accepted", true)), "a second campaign from one shift should reject", failures)
	_check(JSON.stringify(sim.export_save_state()) == after, "duplicate campaign rejection should be atomic", failures)

	var wrong_phase := _completed_shift_fixture(19_102, 1)
	wrong_phase.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	var before_wrong := JSON.stringify(wrong_phase.export_save_state())
	_check(not bool(wrong_phase.file_farmer_relations_campaign(&"layer_profile").get("accepted", true)), "campaigns should reject outside review", failures)
	_check(JSON.stringify(wrong_phase.export_save_state()) == before_wrong, "wrong-phase rejection should preserve the checkpoint", failures)


func _test_explicit_skip(failures: Array[String]) -> void:
	var sim := _completed_shift_fixture(19_201, 1)
	var fund_before := sim.revenue_cents
	var trust_before := sim.workers[0].manager_trust
	var result := sim.skip_farmer_relations_campaign()
	_check(bool(result.get("accepted", false)), "open review should permit an explicit no-release filing", failures)
	_check(StringName(result.get("status", &"")) == &"skipped", "skip receipt should carry skipped status", failures)
	_check(sim.revenue_cents == fund_before and is_equal_approx(sim.workers[0].manager_trust, trust_before), "skip should change neither cash nor worker state", failures)
	_check(sim.begin_next_shift_briefing(), "an explicitly skipped campaign should never softlock the next briefing", failures)


func _completed_shift_fixture(seed: int, level: int) -> DepartmentSimulation:
	var sim := DepartmentSimulation.new(seed, 6)
	sim.day = 5
	sim.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	sim.pending_decision.clear()
	sim.revenue_cents = 1_000_000
	sim.owned_facilities[PACKING] = level
	sim.owned_facilities[GALLERY] = level
	sim.eggs_today = 10
	sim.cracked_today = 2
	sim.golden_today = 1
	sim.eggs_total = 10
	sim.cracked_eggs = 2
	sim.golden_eggs = 1
	sim.quota_target = 8
	var row := sim._worker_shift_stats[0]
	row.merge({
		"eggs": 10,
		"sound": 7,
		"cracked": 2,
		"golden": 1,
		"credit_cents": 2_600,
	}, true)
	sim._worker_shift_stats[0] = row
	sim._complete_workday()
	return sim


func _evidence(day: int, eggs: int, quota: int, cracked: int, golden: int) -> Dictionary:
	return {
		"day": day,
		"eggs": eggs,
		"quota": quota,
		"sound": maxi(0, eggs - cracked),
		"cracked": cracked,
		"golden": golden,
		"met_quota": eggs >= quota,
		"top_worker_id": 0,
		"top_worker_name": "Mabel",
		"hen_highlight": {"day": day, "worker_id": 0, "worker_name": "Mabel"},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
