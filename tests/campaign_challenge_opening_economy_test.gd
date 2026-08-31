extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var expected := {
		CampaignState.CHALLENGE_SUPPORTED_FLOCK: [6500, 14, 6, "RECOVERY CUSHION"],
		CampaignState.CHALLENGE_STANDARD_FILING: [5000, 16, 6, "AUTHORED BASELINE"],
		CampaignState.CHALLENGE_EXECUTIVE_AUDIT: [4800, 18, 8, "AUDIT SURGE"],
	}
	for contract_id: StringName in expected:
		_test_contract_opening(contract_id, expected[contract_id] as Array, failures)
	_test_invalid_contracts_reject_atomically(failures)
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPAIGN_CHALLENGE_OPENING_ECONOMY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_CHALLENGE_OPENING_ECONOMY_TEST_PASSED profiles=3 fund=distinct quota=distinct workload=expert persistence=exact validation=atomic")
	quit(0)


func _test_contract_opening(
	contract_id: StringName,
	expected: Array,
	failures: Array[String],
) -> void:
	var simulation := DepartmentSimulation.new(1701, 4, 1701)
	var receipt := simulation.configure_opening_challenge(
		CampaignState.challenge_contract(contract_id),
	)
	var expected_fund := int(expected[0])
	var expected_quota := int(expected[1])
	var expected_live_files := int(expected[2])
	var expected_pressure := String(expected[3])
	_check(
		bool(receipt.get("accepted", false))
		and String(receipt.get("challenge_id", "")) == String(contract_id)
		and String(receipt.get("pressure_label", "")) == expected_pressure
		and int(receipt.get("before_fund_cents", -1)) == 5000
		and int(receipt.get("fund_cents", -1)) == expected_fund
		and int(receipt.get("before_quota", -1)) == 16
		and int(receipt.get("quota_target", -1)) == expected_quota
		and int(receipt.get("before_live_files", -1)) == 6
		and int(receipt.get("live_files", -1)) == expected_live_files,
		"%s should return an exact opening-economy receipt" % contract_id,
		failures,
	)
	var saved := simulation.export_save_state()
	var queue_counts := _queue_counts(saved)
	_check(
		simulation.revenue_cents == expected_fund
		and int(simulation.farm_treasury_snapshot().get("cash_cents", -1)) == expected_fund
		and simulation.quota_target == expected_quota
		and simulation.claims_waiting == expected_live_files
		and _queue_total(queue_counts) == expected_live_files,
		"%s should apply its opening fund, treasury, quota, and workload to simulation authority" % contract_id,
		failures,
	)
	if contract_id == CampaignState.CHALLENGE_EXECUTIVE_AUDIT:
		_check(
			int(queue_counts.get("appeals", 0)) == 3
			and int(queue_counts.get("predator_loss", 0)) == 3
			and int(queue_counts.get("nest_damage", 0)) == 2,
			"Executive Audit should add one disclosed Appeals and Predator Loss file",
			failures,
		)
	var before_duplicate := simulation.export_save_state()
	var duplicate := simulation.configure_opening_challenge(
		CampaignState.challenge_contract(contract_id),
	)
	_check(
		not bool(duplicate.get("accepted", true))
		and simulation.export_save_state() == before_duplicate,
		"%s opening terms should reject a duplicate application atomically" % contract_id,
		failures,
	)
	var restored := DepartmentSimulation.new(9917, 4, 9917)
	_check(
		restored.restore_save_state(saved)
		and restored.revenue_cents == expected_fund
		and int(restored.farm_treasury_snapshot().get("cash_cents", -1)) == expected_fund
		and restored.quota_target == expected_quota
		and restored.claims_waiting == expected_live_files
		and _queue_total(_queue_counts(restored.export_save_state())) == expected_live_files,
		"%s opening economy should survive the authoritative save round trip" % contract_id,
		failures,
	)


func _test_invalid_contracts_reject_atomically(failures: Array[String]) -> void:
	var malformed_contracts: Array[Dictionary] = [
		{},
		{"id": "missing_opening"},
		{
			"id": "unknown_lane",
			"opening_terms": {
				"feed_fund_cents": 5000,
				"quota_target": 16,
				"additional_claim_lanes": [&"not_a_real_lane"],
				"pressure_label": "INVALID",
			},
		},
		{
			"id": "invalid_range",
			"opening_terms": {
				"feed_fund_cents": -1,
				"quota_target": 0,
				"additional_claim_lanes": [],
				"pressure_label": "",
			},
		},
	]
	for contract in malformed_contracts:
		var simulation := DepartmentSimulation.new(1701, 4, 1701)
		var before := simulation.export_save_state()
		var receipt := simulation.configure_opening_challenge(contract)
		_check(
			not bool(receipt.get("accepted", true))
			and simulation.export_save_state() == before,
			"malformed opening contract %s should reject without partial mutation" % String(contract.get("id", "<empty>")),
			failures,
		)


func _queue_counts(saved: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var queues := saved.get("claim_queues", {}) as Dictionary
	for lane: String in ["nest_damage", "predator_loss", "appeals"]:
		var queue_value: Variant = queues.get(lane, [])
		result[lane] = (queue_value as Array).size() if queue_value is Array else -1
	return result


func _queue_total(counts: Dictionary) -> int:
	return (
		int(counts.get("nest_damage", 0))
		+ int(counts.get("predator_loss", 0))
		+ int(counts.get("appeals", 0))
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
