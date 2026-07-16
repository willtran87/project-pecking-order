extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_contract_blocker_and_nonmutation(failures)
	_test_exact_pass_boundaries(failures)
	_test_authoritative_current_metrics_and_final_parity(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("PROBATION_SAFEGUARD_FORECAST_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("PROBATION_SAFEGUARD_FORECAST_TEST_PASSED criteria=5 boundaries=exact gaps=signed blocker=normalized current=authoritative pure=yes")
	quit(0)


func _test_contract_blocker_and_nonmutation(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var before := campaign.to_dictionary()
	var forecast := campaign.probation_safeguard_forecast({
		"probation_score": 59,
		"average_welfare": 44,
		"average_compliance": 54,
		"average_farmer_favor": 49,
		"crack_rate_basis_points": 2501,
	})
	var criteria := forecast.get("criteria", []) as Array
	_check(campaign.to_dictionary() == before, "forecast must not mutate persistent CampaignState", failures)
	_check(criteria.size() == 5, "forecast must report all five final safeguards", failures)
	_check(int(forecast.get("criteria_count", 0)) == 5, "forecast summary must disclose five criteria", failures)
	_check(int(forecast.get("pass_count", -1)) == 0, "all-below-boundary projection must pass zero safeguards", failures)
	_check(int(forecast.get("at_risk_count", -1)) == 5, "all-below-boundary projection must flag five risks", failures)
	_check(not bool(forecast.get("all_pass", true)), "all-below-boundary projection cannot be all-pass", failures)

	var expected := [
		["score", "probation_score", "minimum", CampaignState.MIN_PASS_SCORE, "points"],
		["welfare", "average_welfare", "minimum", CampaignState.MIN_PASS_WELFARE, "points"],
		["compliance", "average_compliance", "minimum", CampaignState.MIN_PASS_COMPLIANCE, "points"],
		["farmer_favor", "average_farmer_favor", "minimum", CampaignState.MIN_PASS_FARMER_FAVOR, "points"],
		["crack_rate", "crack_rate_basis_points", "maximum", CampaignState.MAX_PASS_CRACK_RATE_BASIS_POINTS, "basis_points"],
	]
	for index in expected.size():
		var row := criteria[index] as Dictionary
		var contract := expected[index] as Array
		_check(String(row.get("id", "")) == String(contract[0]), "criterion %d must retain deterministic final-ledger order" % index, failures)
		_check(String(row.get("metric", "")) == String(contract[1]), "%s must name its authoritative metric" % String(contract[0]), failures)
		_check(String(row.get("comparison", "")) == String(contract[2]), "%s must disclose its comparison" % String(contract[0]), failures)
		_check(int(row.get("target", -1)) == int(contract[3]), "%s target must come from CampaignState's pass constant" % String(contract[0]), failures)
		_check(String(row.get("unit", "")) == String(contract[4]), "%s must disclose its exact value unit" % String(contract[0]), failures)
		_check(String(row.get("value_source", "")) == "projected", "%s must distinguish projected from current facts" % String(contract[0]), failures)
		_check(not bool(row.get("pass", true)) and bool(row.get("at_risk", false)), "%s must expose complementary pass and at-risk flags" % String(contract[0]), failures)
		_check(String(row.get("status", "")) == "at_risk", "%s must expose a stable at-risk status" % String(contract[0]), failures)
		_check(int(row.get("signed_gap", 0)) == -1, "%s must express a one-unit miss as signed gap -1" % String(contract[0]), failures)
		_check(int(row.get("distance_to_pass", 0)) == 1, "%s must express a one-unit miss as distance 1" % String(contract[0]), failures)

	var blocker := forecast.get("largest_recoverable_blocker", {}) as Dictionary
	_check(
		String(blocker.get("id", "")) == "welfare",
		"normalized one-unit misses must identify the 44/45 welfare gap as the largest recoverable blocker",
		failures,
	)
	_check(bool(blocker.get("recoverable", false)), "active probation blocker must be explicitly recoverable", failures)
	_check(int(blocker.get("distance_basis_points", 0)) == 222, "welfare blocker should normalize 1/45 to 222 basis points", failures)

	var snapshot := campaign.snapshot()
	_check(snapshot.has("probation_safeguard_forecast"), "campaign snapshot must publish the read-only safeguard forecast", failures)
	_check(campaign.to_dictionary() == before, "publishing forecast through snapshot must remain non-mutating", failures)


func _test_exact_pass_boundaries(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var exact_pass := {
		"probation_score": 60,
		"average_welfare": 45,
		"average_compliance": 55,
		"average_farmer_favor": 50,
		"crack_rate_basis_points": 2500,
	}
	var passing := campaign.probation_safeguard_forecast(exact_pass)
	_check(int(passing.get("pass_count", -1)) == 5, "exact boundaries must pass all five safeguards", failures)
	_check(bool(passing.get("all_pass", false)), "exact boundaries must report an all-pass forecast", failures)
	_check((passing.get("largest_recoverable_blocker", {}) as Dictionary).is_empty(), "all-pass forecast must have no blocker", failures)
	for row_value in passing.get("criteria", []) as Array:
		var row := row_value as Dictionary
		_check(bool(row.get("pass", false)) and not bool(row.get("at_risk", true)), "%s exact boundary must pass" % String(row.get("id", "criterion")), failures)
		_check(int(row.get("signed_gap", -1)) == 0, "%s exact boundary must have zero signed gap" % String(row.get("id", "criterion")), failures)
		_check(int(row.get("distance_to_pass", -1)) == 0, "%s exact boundary must need no recovery" % String(row.get("id", "criterion")), failures)

	var boundary_cases := [
		{"id": "score", "metric": "probation_score", "risk": 59, "pass": 60, "label": "score 59/60"},
		{"id": "welfare", "metric": "average_welfare", "risk": 44, "pass": 45, "label": "welfare 44/45"},
		{"id": "compliance", "metric": "average_compliance", "risk": 54, "pass": 55, "label": "compliance 54/55"},
		{"id": "farmer_favor", "metric": "average_farmer_favor", "risk": 49, "pass": 50, "label": "farmer favor 49/50"},
		{"id": "crack_rate", "metric": "crack_rate_basis_points", "risk": 2501, "pass": 2500, "label": "cracks 25.01%/25.00%"},
	]
	for case_value in boundary_cases:
		var boundary := case_value as Dictionary
		var risk_projection := exact_pass.duplicate(true)
		risk_projection[String(boundary["metric"])] = int(boundary["risk"])
		var risk_forecast := campaign.probation_safeguard_forecast(risk_projection)
		var risk_row := _criterion(risk_forecast, String(boundary["id"]))
		_check(not risk_row.is_empty(), "%s must remain present in forecast" % String(boundary["label"]), failures)
		_check(int(risk_row.get("projected_value", -1)) == int(boundary["risk"]), "%s must retain its exact at-risk value" % String(boundary["label"]), failures)
		_check(not bool(risk_row.get("pass", true)) and bool(risk_row.get("at_risk", false)), "%s lower side must be at risk" % String(boundary["label"]), failures)
		_check(int(risk_row.get("signed_gap", 0)) == -1 and int(risk_row.get("distance_to_pass", 0)) == 1, "%s must be exactly one authoritative unit short" % String(boundary["label"]), failures)
		_check(int(risk_forecast.get("pass_count", -1)) == 4, "%s miss must leave exactly four safeguards passing" % String(boundary["label"]), failures)

		var pass_projection := exact_pass.duplicate(true)
		pass_projection[String(boundary["metric"])] = int(boundary["pass"])
		var pass_row := _criterion(campaign.probation_safeguard_forecast(pass_projection), String(boundary["id"]))
		_check(bool(pass_row.get("pass", false)) and not bool(pass_row.get("at_risk", true)), "%s exact target must pass" % String(boundary["label"]), failures)
		_check(int(pass_row.get("signed_gap", -1)) == 0 and int(pass_row.get("distance_to_pass", -1)) == 0, "%s exact target must have zero distance" % String(boundary["label"]), failures)


func _test_authoritative_current_metrics_and_final_parity(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var accepted := campaign.record_shift({
		"day": 1,
		"eggs": 20,
		"quota": 18,
		"cracked": 5,
		"overdue_claims": 0,
		"rework_total_created": 0,
		"credited_cents": 4000,
	}, {
		"welfare": 45,
		"compliance": 55,
		"executive_confidence": 50,
	})
	_check(bool(accepted.get("accepted", false)), "current-metric fixture shift must be accepted through CampaignState", failures)
	var before := campaign.to_dictionary()
	var forecast := campaign.probation_safeguard_forecast()
	var expected_current := {
		"score": campaign.probation_score,
		"welfare": campaign.average_welfare(),
		"compliance": campaign.average_compliance(),
		"farmer_favor": campaign.average_farmer_favor(),
		"crack_rate": campaign.cumulative_crack_rate_basis_points(),
	}
	for id_value in expected_current:
		var id := String(id_value)
		var row := _criterion(forecast, id)
		_check(int(row.get("current_value", -1)) == int(expected_current[id_value]), "%s current value must come from CampaignState's aggregate method" % id, failures)
		_check(int(row.get("projected_value", -1)) == int(expected_current[id_value]), "%s without an override must project its current aggregate" % id, failures)
		_check(String(row.get("value_source", "")) == "current", "%s without an override must identify current facts" % id, failures)

	var final_criteria := campaign.final_evaluation().get("criteria", {}) as Dictionary
	var parity_keys := {
		"score": "score",
		"welfare": "welfare",
		"compliance": "compliance",
		"farmer_favor": "farmer_favor",
		"crack_rate": "shell_quality",
	}
	for id_value in parity_keys:
		var id := String(id_value)
		_check(
			bool(_criterion(forecast, id).get("pass", false)) == bool(final_criteria.get(parity_keys[id_value], false)),
			"%s forecast pass state must equal final_evaluation's authoritative criterion" % id,
			failures,
		)
	_check(campaign.to_dictionary() == before, "current-value forecast and final parity checks must not mutate state", failures)


func _criterion(forecast: Dictionary, criterion_id: String) -> Dictionary:
	for row_value in forecast.get("criteria", []) as Array:
		if row_value is Dictionary and String((row_value as Dictionary).get("id", "")) == criterion_id:
			return (row_value as Dictionary).duplicate(true)
	return {}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
