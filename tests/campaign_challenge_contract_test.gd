extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_catalog_and_exact_thresholds(failures)
	_test_pristine_selection_and_locking(failures)
	_test_contract_drives_final_outcome(failures)
	_test_round_trip_validation_and_legacy_migration(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_CHALLENGE_CONTRACT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_CHALLENGE_CONTRACT_TEST_PASSED contracts=3 immutable=pre-shift thresholds=exact outcomes=derived migration=v1-standard")
	quit(0)


func _test_catalog_and_exact_thresholds(failures: Array[String]) -> void:
	var catalog := CampaignState.challenge_contract_catalog()
	_check(catalog.size() == 3, "challenge catalog should contain exactly three stable contracts", failures)
	var expected := {
		"supported_flock": [35, 45, 55, 45, 3000],
		"standard_filing": [60, 45, 55, 50, 2500],
		"executive_audit": [65, 48, 65, 53, 2300],
	}
	var expected_difficulties := {
		"supported_flock": "learning",
		"standard_filing": "standard",
		"executive_audit": "expert",
	}
	var observed_ids: Array[String] = []
	for contract in catalog:
		var contract_id := String(contract.get("id", ""))
		observed_ids.append(contract_id)
		_check(expected.has(contract_id), "%s should be a supported challenge contract" % contract_id, failures)
		_check(
			not String(contract.get("label", "")).is_empty()
			and not String(contract.get("short_label", "")).is_empty()
			and not String(contract.get("description", "")).is_empty()
			and String(contract.get("difficulty", "")) == String(expected_difficulties.get(contract_id, ""))
			and not String(contract.get("difficulty_label", "")).is_empty()
			and not String(contract.get("difficulty_guidance", "")).is_empty()
			and not String(contract.get("route_brief", "")).is_empty()
			and not String(contract.get("route_guidance", "")).is_empty(),
			"%s should expose complete identity, explicit difficulty, and evidence-backed route guidance" % contract_id,
			failures,
		)
		if expected.has(contract_id):
			var criteria := contract.get("criteria", {}) as Dictionary
			var values := expected[contract_id] as Array
			_check(
				int(criteria.get("minimum_score", -1)) == int(values[0])
				and int(criteria.get("minimum_welfare", -1)) == int(values[1])
				and int(criteria.get("minimum_compliance", -1)) == int(values[2])
				and int(criteria.get("minimum_farmer_favor", -1)) == int(values[3])
				and int(criteria.get("maximum_crack_rate_basis_points", -1)) == int(values[4]),
				"%s should expose its exact five safeguard thresholds" % contract_id,
				failures,
			)
	_check(
		observed_ids == ["supported_flock", "standard_filing", "executive_audit"],
		"challenge catalog order should remain stable for presentation controls",
		failures,
	)

	# Catalog consumers receive copies rather than writable references to the
	# authoritative contract definitions.
	(catalog[0].get("criteria", {}) as Dictionary)["minimum_score"] = 999
	_check(
		int((CampaignState.challenge_contract(CampaignState.CHALLENGE_SUPPORTED_FLOCK).get("criteria", {}) as Dictionary).get("minimum_score", -1)) == 35,
		"mutating a catalog copy must not change the authoritative thresholds",
		failures,
	)
	_check(
		CampaignState.challenge_contract(&"unknown_contract").is_empty(),
		"unknown contract IDs should not receive a fallback profile",
		failures,
	)

	for contract_id in [
		CampaignState.CHALLENGE_SUPPORTED_FLOCK,
		CampaignState.CHALLENGE_STANDARD_FILING,
		CampaignState.CHALLENGE_EXECUTIVE_AUDIT,
	]:
		var campaign := CampaignState.new()
		_check(campaign.select_challenge_contract(contract_id), "%s should be selectable on a pristine campaign" % contract_id, failures)
		var contract := campaign.challenge_contract_snapshot()
		var criteria := contract.get("criteria", {}) as Dictionary
		var forecast := campaign.probation_safeguard_forecast({
			"probation_score": int(criteria["minimum_score"]),
			"average_welfare": int(criteria["minimum_welfare"]),
			"average_compliance": int(criteria["minimum_compliance"]),
			"average_farmer_favor": int(criteria["minimum_farmer_favor"]),
			"crack_rate_basis_points": int(criteria["maximum_crack_rate_basis_points"]),
		})
		_check(bool(forecast.get("all_pass", false)), "%s exact boundaries should all pass" % contract_id, failures)
		_check(
			String((forecast.get("challenge_contract", {}) as Dictionary).get("id", "")) == String(contract_id),
			"%s safeguard forecast should retain its authoritative contract identity" % contract_id,
			failures,
		)

	var supported_recovery := CampaignState.new()
	_check(
		supported_recovery.select_challenge_contract(CampaignState.CHALLENGE_SUPPORTED_FLOCK),
		"Supported recovery fixture should file its learning contract",
		failures,
	)
	var recovery_metrics := {
		"probation_score": 35,
		"average_welfare": 45,
		"average_compliance": 55,
		"average_farmer_favor": 45,
		"crack_rate_basis_points": 3000,
	}
	_check(
		bool(supported_recovery.probation_safeguard_forecast(recovery_metrics).get("all_pass", false)),
		"Supported Flock should preserve a bounded score-recovery route at 35",
		failures,
	)
	recovery_metrics["probation_score"] = 34
	_check(
		not bool(supported_recovery.probation_safeguard_forecast(recovery_metrics).get("all_pass", true)),
		"Supported Flock should still reject a score below its disclosed 35-point floor",
		failures,
	)


func _test_pristine_selection_and_locking(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	_check(
		campaign.challenge_contract_id == CampaignState.CHALLENGE_STANDARD_FILING,
		"an unconfigured campaign should safely default to Standard Filing",
		failures,
	)
	campaign.challenge_contract_id = CampaignState.CHALLENGE_EXECUTIVE_AUDIT
	_check(
		campaign.challenge_contract_id == CampaignState.CHALLENGE_STANDARD_FILING,
		"public assignment must not bypass pristine challenge selection",
		failures,
	)
	var before_invalid := campaign.to_dictionary()
	_check(not campaign.select_challenge_contract(&"automatic_win"), "unknown selection should reject", failures)
	_check(campaign.to_dictionary() == before_invalid, "unknown selection should reject atomically", failures)
	_check(
		campaign.select_challenge_contract(CampaignState.CHALLENGE_SUPPORTED_FLOCK),
		"the first valid pristine selection should be accepted",
		failures,
	)
	_check(
		campaign.challenge_contract_id == CampaignState.CHALLENGE_SUPPORTED_FLOCK,
		"accepted selection should become authoritative",
		failures,
	)
	var after_selection := campaign.to_dictionary()
	campaign.challenge_contract_id = CampaignState.CHALLENGE_EXECUTIVE_AUDIT
	_check(
		campaign.challenge_contract_id == CampaignState.CHALLENGE_SUPPORTED_FLOCK
		and campaign.to_dictionary() == after_selection,
		"public assignment must not replace an explicitly filed contract",
		failures,
	)
	_check(
		not campaign.select_challenge_contract(CampaignState.CHALLENGE_EXECUTIVE_AUDIT),
		"a second pre-shift selection should not replace the filed contract",
		failures,
	)
	_check(campaign.to_dictionary() == after_selection, "repeat selection should reject atomically", failures)

	var started := CampaignState.new()
	_check(
		bool(started.record_shift(_report(1), _snapshot(64, 73, 47)).get("accepted", false)),
		"locking fixture should accept its first Standard shift",
		failures,
	)
	var started_before := started.to_dictionary()
	started.challenge_contract_id = CampaignState.CHALLENGE_SUPPORTED_FLOCK
	_check(
		started.challenge_contract_id == CampaignState.CHALLENGE_STANDARD_FILING
		and started.to_dictionary() == started_before,
		"public assignment must not change the contract after accepted work",
		failures,
	)
	_check(
		not started.select_challenge_contract(CampaignState.CHALLENGE_SUPPORTED_FLOCK),
		"accepted work should lock the default Standard contract",
		failures,
	)
	_check(started.to_dictionary() == started_before, "post-shift selection should reject atomically", failures)

	var restored := CampaignState.from_dictionary(CampaignState.new().to_dictionary())
	_check(restored != null, "zero-shift persisted campaign should restore", failures)
	if restored != null:
		_check(
			not restored.select_challenge_contract(CampaignState.CHALLENGE_SUPPORTED_FLOCK),
			"a restored file should treat its persisted Standard contract as locked",
			failures,
		)


func _test_contract_drives_final_outcome(failures: Array[String]) -> void:
	# This same humane ledger deliberately lands below Standard farmer favor. It
	# passes Supported Flock because that contract alone lowers the favor floor.
	var supported := _complete_campaign(CampaignState.CHALLENGE_SUPPORTED_FLOCK, 64, 73, 47, failures)
	var standard := _complete_campaign(CampaignState.CHALLENGE_STANDARD_FILING, 64, 73, 47, failures)
	_check(supported.outcome == CampaignState.OUTCOME_PASSED, "Supported Flock should pass the 47-favor fixture", failures)
	_check(standard.outcome == CampaignState.OUTCOME_FAILED, "Standard Filing should reject the same 47-favor fixture", failures)
	_check(
		not bool((standard.final_evaluation().get("criteria", {}) as Dictionary).get("farmer_favor", true)),
		"Standard failure should identify farmer favor rather than changing simulation work",
		failures,
	)
	_check(
		String((supported.final_evaluation().get("challenge_contract", {}) as Dictionary).get("id", "")) == "supported_flock",
		"final evaluation should expose the filed Supported contract",
		failures,
	)

	var executive := _complete_campaign(CampaignState.CHALLENGE_EXECUTIVE_AUDIT, 80, 82, 70, failures)
	_check(executive.outcome == CampaignState.OUTCOME_PASSED, "a genuinely strong ledger should pass Executive Audit", failures)
	_check(
		bool(executive.probation_safeguard_forecast().get("all_pass", false)),
		"Executive final outcome should derive from all five tighter thresholds",
		failures,
	)


func _test_round_trip_validation_and_legacy_migration(failures: Array[String]) -> void:
	var original := CampaignState.new()
	_check(
		original.select_challenge_contract(CampaignState.CHALLENGE_EXECUTIVE_AUDIT),
		"round-trip fixture should select Executive Audit",
		failures,
	)
	original.record_shift(_report(1), _snapshot(80, 82, 70))
	var encoded := JSON.stringify(original.to_dictionary())
	var parsed_value: Variant = JSON.parse_string(encoded)
	_check(parsed_value is Dictionary, "challenge campaign should remain primitive JSON", failures)
	if not parsed_value is Dictionary:
		return
	var parsed := parsed_value as Dictionary
	_check(int(parsed.get("schema_version", -1)) == 2, "challenge persistence should advance campaign schema to v2", failures)
	_check(String(parsed.get("challenge_contract_id", "")) == "executive_audit", "save should persist the exact contract ID", failures)
	_check(CampaignState.validate_dictionary(parsed).is_empty(), "valid v2 challenge file should pass strict validation", failures)
	var restored := CampaignState.from_dictionary(parsed)
	_check(restored != null, "valid v2 challenge file should restore", failures)
	if restored != null:
		_check(restored.to_dictionary() == original.to_dictionary(), "challenge round trip should preserve exact primitive state", failures)
		_check(restored.challenge_contract_id == CampaignState.CHALLENGE_EXECUTIVE_AUDIT, "round trip should retain typed contract identity", failures)
		_check(
			not restored.select_challenge_contract(CampaignState.CHALLENGE_SUPPORTED_FLOCK),
			"restored contract should remain immutable",
			failures,
		)

	var legacy := CampaignState.new().to_dictionary()
	legacy["schema_version"] = 1
	legacy.erase("challenge_contract_id")
	_check(CampaignState.validate_dictionary(legacy).is_empty(), "valid v1 file should migrate during validation", failures)
	var migrated := CampaignState.from_dictionary(legacy)
	_check(migrated != null, "valid v1 file should migrate during restore", failures)
	if migrated != null:
		_check(migrated.challenge_contract_id == CampaignState.CHALLENGE_STANDARD_FILING, "v1 migration should file Standard", failures)
		_check(int(migrated.to_dictionary().get("schema_version", -1)) == 2, "migrated save should emit current schema", failures)
		_check(
			not migrated.select_challenge_contract(CampaignState.CHALLENGE_SUPPORTED_FLOCK),
			"migrated legacy authority should lock to Standard",
			failures,
		)

	var forged_legacy := legacy.duplicate(true)
	forged_legacy["challenge_contract_id"] = "executive_audit"
	var sanitized_legacy := CampaignState.from_dictionary(forged_legacy)
	_check(
		sanitized_legacy != null
		and sanitized_legacy.challenge_contract_id == CampaignState.CHALLENGE_STANDARD_FILING,
		"v1 migration should ignore a challenge field the legacy schema never owned",
		failures,
	)

	var unknown := original.to_dictionary()
	unknown["challenge_contract_id"] = "automatic_win"
	_check(not CampaignState.validate_dictionary(unknown).is_empty(), "unknown v2 contract should fail closed", failures)
	_check(CampaignState.from_dictionary(unknown) == null, "unknown v2 contract should not restore", failures)
	var noncanonical := original.to_dictionary()
	noncanonical["challenge_contract_id"] = "EXECUTIVE_AUDIT"
	var noncanonical_errors := CampaignState.validate_dictionary(noncanonical)
	_check(
		not noncanonical_errors.is_empty()
		and "challenge_contract_id must use its canonical stable ID" in noncanonical_errors,
		"mixed-case v2 contract authority should fail canonical validation",
		failures,
	)
	_check(
		CampaignState.from_dictionary(noncanonical) == null,
		"mixed-case v2 contract authority must not hydrate or persist",
		failures,
	)
	var missing := original.to_dictionary()
	missing.erase("challenge_contract_id")
	_check(not CampaignState.validate_dictionary(missing).is_empty(), "missing v2 contract authority should fail closed", failures)


func _complete_campaign(
	contract_id: StringName,
	welfare: int,
	compliance: int,
	farmer_favor: int,
	failures: Array[String],
) -> CampaignState:
	var campaign := CampaignState.new()
	_check(campaign.select_challenge_contract(contract_id), "%s fixture should file its contract" % contract_id, failures)
	for shift_number in range(1, CampaignState.CAMPAIGN_LENGTH + 1):
		if shift_number == 3:
			_check(campaign.choose_milestone(&"padded_perches"), "%s fixture should clear the milestone gate" % contract_id, failures)
		var result := campaign.record_shift(
			_report(shift_number),
			_snapshot(welfare, compliance, farmer_favor),
		)
		_check(bool(result.get("accepted", false)), "%s shift %d should be accepted" % [contract_id, shift_number], failures)
	return campaign


func _report(shift_number: int) -> Dictionary:
	return {
		"day": shift_number,
		"eggs": 26,
		"quota": 24,
		"cracked": 1,
		"feed_cost_cents": 1800,
		"overdue_claims": 0,
		"rework_total_created": 0,
		"closing_fund_cents": 10_000 + shift_number * 1000,
		"credited_cents": 2800,
	}


func _snapshot(welfare: int, compliance: int, farmer_favor: int) -> Dictionary:
	return {
		"welfare": welfare,
		"compliance": compliance,
		"executive_confidence": farmer_favor,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
