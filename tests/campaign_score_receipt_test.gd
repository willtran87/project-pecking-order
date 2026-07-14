extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	_test_empty_and_invalid_lookups(failures)
	_test_exact_positive_components(failures)
	_test_exact_negative_components(failures)
	_test_milestone_chronology_and_score_cap(failures)
	_test_json_round_trip_recomputes_receipts(failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_SCORE_RECEIPT_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_SCORE_RECEIPT_TEST_PASSED grouped=positive+negative cap=reconciled milestone=day2 chronology=shift3 json=derived-only types=stable")
	quit(0)


func _test_empty_and_invalid_lookups(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	_check(campaign.latest_score_receipt().is_empty(), "a new campaign should have no latest score receipt", failures)
	_check(campaign.score_receipt_for_shift(-1).is_empty(), "negative receipt lookup should be rejected", failures)
	_check(campaign.score_receipt_for_shift(0).is_empty(), "shift-zero receipt lookup should be rejected", failures)
	_check(campaign.score_receipt_for_shift(1).is_empty(), "future receipt lookup should be rejected", failures)

	var accepted := campaign.record_shift(_positive_report(1), _positive_snapshot())
	_check(bool(accepted.get("accepted", false)), "positive fixture should record before lookup checks", failures)
	_check(campaign.score_receipt_for_shift(2).is_empty(), "lookup beyond the recorded chronology should be rejected", failures)


func _test_exact_positive_components(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var accepted := campaign.record_shift(_positive_report(1), _positive_snapshot())
	_check(bool(accepted.get("accepted", false)), "positive fixture should be accepted", failures)
	if not bool(accepted.get("accepted", false)):
		return

	var receipt := campaign.latest_score_receipt()
	var expected := {
		"probation_orders": 12,
		"daily_clutch": 3,
		"shell_quality": 2,
		"queue_control": 3,
		"flock_safeguards": 3,
	}
	_check_component_contract(receipt, expected, failures, "positive")
	_check(int(receipt.get("raw_shift_delta", 999)) == 23, "positive groups should sum to exactly +23", failures)
	_check(int(receipt.get("score_before", -1)) == CampaignState.STARTING_SCORE, "positive receipt should start at the campaign opening score", failures)
	_check(int(receipt.get("applied_shift_delta", 999)) == 23, "uncapped positive shift should apply its entire +23", failures)
	_check(int(receipt.get("cap_adjustment", 999)) == 0, "uncapped positive shift should not fabricate a cap adjustment", failures)
	_check(not bool(receipt.get("clamped", true)), "uncapped positive shift should not report clamping", failures)
	_check_receipt_reconciliation(receipt, failures, "positive")


func _test_exact_negative_components(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	var accepted := campaign.record_shift(_negative_report(1), _negative_snapshot())
	_check(bool(accepted.get("accepted", false)), "negative fixture should still produce a review receipt", failures)
	if not bool(accepted.get("accepted", false)):
		return

	var receipt := campaign.latest_score_receipt()
	var expected := {
		"probation_orders": 0,
		"daily_clutch": -5,
		"shell_quality": -3,
		"queue_control": -7,
		"flock_safeguards": -9,
	}
	_check_component_contract(receipt, expected, failures, "negative")
	_check(int(receipt.get("raw_shift_delta", 999)) == -24, "negative groups should sum to exactly -24", failures)
	_check(int(receipt.get("applied_shift_delta", 999)) == -24, "uncapped negative shift should apply its entire -24", failures)
	_check(int(receipt.get("score_after", -1)) == 26, "negative receipt should disclose the resulting score of 26", failures)
	_check_receipt_reconciliation(receipt, failures, "negative")


func _test_milestone_chronology_and_score_cap(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	_check(bool(campaign.record_shift(_positive_report(1), _positive_snapshot()).get("accepted", false)), "chronology fixture shift one should record", failures)
	_check(bool(campaign.record_shift(_positive_report(2), _positive_snapshot()).get("accepted", false)), "chronology fixture shift two should record", failures)
	_check(campaign.choose_milestone(&"shell_quality_lab"), "Day-2 milestone should be selectable before shift three", failures)

	var day_two_receipt := campaign.score_receipt_for_shift(2)
	_check(int(day_two_receipt.get("score_before", -1)) == 73, "Day-2 receipt should begin after shift one's +23", failures)
	_check(int(day_two_receipt.get("score_after_shift", -1)) == 96, "Day-2 base shift should end at 96 before specialization", failures)
	_check(int(day_two_receipt.get("milestone_bonus", -1)) == 2, "Day-2 receipt should disclose the specialization's +2 separately", failures)
	_check(int(day_two_receipt.get("score_after", -1)) == 98, "Day-2 reported score should include the filed milestone", failures)
	_check(int(day_two_receipt.get("score_delta", -1)) == 25, "Day-2 score delta should reconcile +23 shift and +2 milestone", failures)
	_check(String(day_two_receipt.get("milestone_title", "")) == "Shell Quality Lab", "milestone receipt should name the selected specialization", failures)
	var day_two_components := day_two_receipt.get("components", []) as Array
	_check(_component_count(day_two_components, "milestone_bonus") == 1, "milestone should appear as exactly one separate receipt component", failures)
	_check(_component_delta(day_two_components, "milestone_bonus", 999) == 2, "separate milestone component should retain its exact +2", failures)
	_check(_component_delta(day_two_components, "probation_orders", 999) == 12, "milestone bonus must not be folded into probation-order scoring", failures)
	_check_receipt_reconciliation(day_two_receipt, failures, "Day-2 milestone")

	var shift_three_result := campaign.record_shift(_positive_report(3), _positive_snapshot())
	_check(bool(shift_three_result.get("accepted", false)), "chosen milestone should permit chronological shift three", failures)
	if not bool(shift_three_result.get("accepted", false)):
		return
	var shift_three_receipt := campaign.score_receipt_for_shift(3)
	_check(campaign.latest_score_receipt() == shift_three_receipt, "latest receipt should advance to chronological shift three", failures)
	_check(int(shift_three_receipt.get("score_before", -1)) == 98, "shift three should begin after Day-2's separately filed milestone", failures)
	_check(int(shift_three_receipt.get("raw_shift_delta", -1)) == 23, "shift three should retain the full +23 raw performance sum", failures)
	_check(int(shift_three_receipt.get("applied_shift_delta", -1)) == 2, "score ceiling should apply only +2 of shift three's +23", failures)
	_check(int(shift_three_receipt.get("cap_adjustment", 999)) == -21, "score receipt should reconcile the remaining -21 as a cap adjustment", failures)
	_check(bool(shift_three_receipt.get("clamped", false)), "score-ceiling adjustment should be explicitly marked clamped", failures)
	_check(int(shift_three_receipt.get("score_after_shift", -1)) == 100, "capped shift should finish at 100", failures)
	_check(int(shift_three_receipt.get("milestone_bonus", -1)) == 0, "milestone must not be repeated on shift three", failures)
	var shift_three_components := shift_three_receipt.get("components", []) as Array
	_check(_component_count(shift_three_components, "score_cap") == 1, "clamped receipt should expose exactly one score-cap component", failures)
	_check(_component_delta(shift_three_components, "score_cap", 999) == -21, "score-cap component should carry the exact reconciliation delta", failures)
	_check(_component_count(shift_three_components, "milestone_bonus") == 0, "shift-three components should not duplicate the Day-2 milestone", failures)
	_check_receipt_reconciliation(shift_three_receipt, failures, "shift-three cap")


func _test_json_round_trip_recomputes_receipts(failures: Array[String]) -> void:
	var campaign := CampaignState.new()
	campaign.record_shift(_positive_report(1), _positive_snapshot())
	campaign.record_shift(_positive_report(2), _positive_snapshot())
	campaign.choose_milestone(&"padded_perches")
	campaign.record_shift(_positive_report(3), _positive_snapshot())
	var expected_latest := campaign.latest_score_receipt()
	var expected_day_two := campaign.score_receipt_for_shift(2)
	var persisted := campaign.to_dictionary()

	_check(not persisted.has("latest_score_receipt"), "derived latest receipt must remain absent from the persisted schema", failures)
	_check(not persisted.has("score_receipt"), "derived receipt must not become a persisted top-level field", failures)
	for record_value in persisted.get("shift_records", []) as Array:
		var record := record_value as Dictionary
		_check(not record.has("score_receipt") and not record.has("components"), "shift records should persist source facts, not derived receipt presentation", failures)

	var parsed_value: Variant = JSON.parse_string(JSON.stringify(persisted))
	_check(typeof(parsed_value) == TYPE_DICTIONARY, "campaign state should survive primitive JSON parsing", failures)
	if typeof(parsed_value) != TYPE_DICTIONARY:
		return
	var restored := CampaignState.from_dictionary(parsed_value as Dictionary)
	_check(restored != null, "JSON campaign should restore before receipt comparison", failures)
	if restored == null:
		return
	_check(restored.latest_score_receipt() == expected_latest, "derived latest receipt should be identical after JSON round trip", failures)
	_check(restored.score_receipt_for_shift(2) == expected_day_two, "historical milestone receipt should be identical after JSON round trip", failures)
	_check(restored.to_dictionary() == persisted, "receipt queries should not mutate or extend persisted campaign schema", failures)


func _check_component_contract(receipt: Dictionary, expected: Dictionary, failures: Array[String], context: String) -> void:
	var components := receipt.get("components", []) as Array
	_check(components.size() == expected.size(), "%s receipt should expose exactly the expected grouped components" % context, failures)
	var observed_sum := 0
	var observed_ids: Dictionary = {}
	for component_value in components:
		_check(typeof(component_value) == TYPE_DICTIONARY, "%s component should be a Dictionary" % context, failures)
		if typeof(component_value) != TYPE_DICTIONARY:
			continue
		var component := component_value as Dictionary
		var id_value: Variant = component.get("id")
		var label_value: Variant = component.get("label")
		var detail_value: Variant = component.get("detail")
		var delta_value: Variant = component.get("delta")
		var tone_value: Variant = component.get("tone")
		_check(typeof(id_value) == TYPE_STRING, "%s component id should be a primitive String" % context, failures)
		_check(typeof(label_value) == TYPE_STRING and not String(label_value).is_empty(), "%s component label should be a nonempty String" % context, failures)
		_check(typeof(detail_value) == TYPE_STRING and not String(detail_value).is_empty(), "%s component detail should be a nonempty String" % context, failures)
		_check(typeof(delta_value) == TYPE_INT, "%s component delta should be an integer" % context, failures)
		_check(typeof(tone_value) == TYPE_STRING_NAME, "%s component tone should be a typed StringName" % context, failures)
		var component_id := String(id_value)
		_check(not observed_ids.has(component_id), "%s grouped component ids should be unique" % context, failures)
		observed_ids[component_id] = true
		_check(expected.has(component_id), "%s receipt should not expose an unexpected '%s' group" % [context, component_id], failures)
		if expected.has(component_id):
			var expected_delta := int(expected[component_id])
			_check(int(delta_value) == expected_delta, "%s '%s' should contribute exactly %+d" % [context, component_id, expected_delta], failures)
			var expected_tone := &"positive" if expected_delta > 0 else (&"negative" if expected_delta < 0 else &"neutral")
			_check(StringName(tone_value) == expected_tone, "%s '%s' tone should match the delta sign" % [context, component_id], failures)
		observed_sum += int(delta_value)
	for expected_id in expected:
		_check(observed_ids.has(String(expected_id)), "%s receipt should include '%s'" % [context, expected_id], failures)
	_check(observed_sum == int(receipt.get("raw_shift_delta", 999_999)), "%s grouped component sum should equal raw_shift_delta" % context, failures)


func _check_receipt_reconciliation(receipt: Dictionary, failures: Array[String], context: String) -> void:
	for key in [
		"shift_number", "score_before", "raw_shift_delta", "score_delta",
		"applied_shift_delta", "cap_adjustment", "score_after_shift",
		"score_after", "milestone_bonus",
	]:
		_check(typeof(receipt.get(key)) == TYPE_INT, "%s receipt.%s should be an integer" % [context, key], failures)
	_check(typeof(receipt.get("clamped")) == TYPE_BOOL, "%s receipt.clamped should be a bool" % context, failures)
	_check(typeof(receipt.get("rank_after")) == TYPE_STRING, "%s receipt.rank_after should be a primitive String" % context, failures)
	_check(typeof(receipt.get("milestone_title")) == TYPE_STRING, "%s receipt.milestone_title should be a primitive String" % context, failures)
	_check(typeof(receipt.get("components")) == TYPE_ARRAY, "%s receipt.components should be an Array" % context, failures)

	var score_before := int(receipt.get("score_before", 0))
	var raw_delta := int(receipt.get("raw_shift_delta", 0))
	var applied_delta := int(receipt.get("applied_shift_delta", 0))
	var cap_adjustment := int(receipt.get("cap_adjustment", 0))
	var milestone_bonus := int(receipt.get("milestone_bonus", 0))
	var score_delta := int(receipt.get("score_delta", 0))
	var score_after_shift := int(receipt.get("score_after_shift", 0))
	var score_after := int(receipt.get("score_after", 0))
	_check(raw_delta + cap_adjustment == applied_delta, "%s raw delta plus cap adjustment should equal applied shift delta" % context, failures)
	_check(score_before + applied_delta == score_after_shift, "%s score_before plus applied shift delta should equal score_after_shift" % context, failures)
	_check(applied_delta + milestone_bonus == score_delta, "%s applied shift delta plus milestone should equal reported score delta" % context, failures)
	_check(score_before + score_delta == score_after, "%s score_before plus reported delta should equal score_after" % context, failures)
	var component_sum := 0
	for component_value in receipt.get("components", []) as Array:
		if typeof(component_value) == TYPE_DICTIONARY:
			component_sum += int((component_value as Dictionary).get("delta", 0))
	_check(component_sum == score_delta, "%s displayed component sum should equal the reported score delta" % context, failures)


func _component_count(components: Array, component_id: String) -> int:
	var count := 0
	for component_value in components:
		if typeof(component_value) == TYPE_DICTIONARY and String((component_value as Dictionary).get("id", "")) == component_id:
			count += 1
	return count


func _component_delta(components: Array, component_id: String, fallback: int) -> int:
	for component_value in components:
		if typeof(component_value) != TYPE_DICTIONARY:
			continue
		var component := component_value as Dictionary
		if String(component.get("id", "")) == component_id:
			return int(component.get("delta", fallback))
	return fallback


func _positive_report(shift_number: int) -> Dictionary:
	return {
		"day": shift_number,
		"eggs": 26,
		"quota": 24,
		"cracked": 1,
		"overdue_claims": 0,
		"rework_created": 0,
		"credited_cents": 8000,
	}


func _positive_snapshot() -> Dictionary:
	return {
		"welfare": 75,
		"compliance": 82,
		"executive_confidence": 70,
	}


func _negative_report(shift_number: int) -> Dictionary:
	return {
		"day": shift_number,
		"eggs": 1,
		"quota": 24,
		"cracked": 1,
		"overdue_claims": 8,
		"rework_created": 5,
		"credited_cents": 0,
	}


func _negative_snapshot() -> Dictionary:
	return {
		"welfare": 0,
		"compliance": 0,
		"executive_confidence": 0,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
