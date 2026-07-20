extends SceneTree


const CampaignSaveStore := preload("res://core/persistence/campaign_save_store.gd")
const SeniorRoostState := preload("res://core/campaign/senior_roost_state.gd")
const TEST_FILENAME := "campaign_save_store_test.json"
const TEST_PATH := "user://%s" % TEST_FILENAME
const PORTABLE_SOURCE_FILENAME := "campaign_portable_source_test.json"
const PORTABLE_TARGET_FILENAME := "campaign_portable_target_test.json"


func _init() -> void:
	var failures: Array[String] = []
	var store := CampaignSaveStore.new(TEST_FILENAME)
	store.delete()
	_test_round_trip_and_backup_recovery(store, failures)
	_test_input_validation_is_atomic(store, failures)
	_test_recovery_candidate_contract(store, failures)
	_test_corrupt_save_fallback(store, failures)
	_test_schema_migration(store, failures)
	_test_future_schema_rejection(store, failures)
	_test_portable_backup_contract(failures)
	_test_filename_isolation(failures)
	store.delete()

	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_SAVE_STORE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_SAVE_STORE_TEST_PASSED schema=%d json=validated+compact backup=recovered+portable candidates=ordered+isolated senior_roost=retained migration=v1-to-v2" % CampaignSaveStore.CURRENT_SCHEMA_VERSION)
	quit(0)


func _test_round_trip_and_backup_recovery(store: CampaignSaveStore, failures: Array[String]) -> void:
	_check(not store.has_save(), "fresh injected filename should not report a save", failures)
	var first_campaign := {
		"campaign": {
			"schema_id": "pecking_order.probation_campaign",
			"schema_version": 1,
			"campaign_id": "test-coop",
			"completed_shifts": 5,
			"probation_score": 72,
			"fund_cents": 12_345,
			"morale": 75.0,
			"flags": {"tutorial_complete": true},
		},
		"simulation": {
			"state_version": 6,
			"day": 9,
			"minute_of_day": 612,
			"revenue_cents": 12_345,
			"workers": [
				{"worker_id": 0, "name": "Henrietta", "assignment": "appeals"},
				{"worker_id": 1, "name": "Cluckles", "assignment": "nest_damage"},
			],
		},
		"session": {
			"review_stage": "active",
			"last_workday_report": {"day": 8, "eggs": 29, "quota": 24},
			"first_clutch": {"completed": true, "delivered_quality": "golden"},
		},
		"senior_roost": _senior_roost_fixture(failures),
	}
	var first_expected: Dictionary = first_campaign.duplicate(true)
	var first_metadata := {"slot_name": "Test Coop", "play_seconds": 42}
	_check(store.save(first_campaign, first_metadata), "valid JSON campaign should save: %s" % store.last_error, failures)
	var committed_json := FileAccess.get_file_as_string(TEST_PATH)
	var committed_value: Variant = JSON.parse_string(committed_json)
	_check(committed_value is Dictionary, "the compact committed envelope should remain valid JSON", failures)
	_check(
		not committed_json.contains("\n") and not committed_json.contains("\t"),
		"production checkpoint JSON should not spend bytes on indentation or line breaks",
		failures,
	)
	if committed_value is Dictionary:
		var pretty_equivalent := JSON.stringify(committed_value, "\t")
		_check(
			committed_json.to_utf8_buffer().size() < pretty_equivalent.to_utf8_buffer().size(),
			"the committed checkpoint should be smaller than an equivalent pretty-printed envelope",
			failures,
		)
	(first_campaign.get("campaign") as Dictionary)["completed_shifts"] = 99
	((first_campaign.get("campaign") as Dictionary).get("flags") as Dictionary)["tutorial_complete"] = false
	(first_campaign.get("senior_roost") as Dictionary)["roost_marks"] = 999
	_check(store.has_save(), "valid primary should report a save", failures)

	var first_loaded := store.load()
	_check(not first_loaded.is_empty(), "saved campaign should load", failures)
	_check(CampaignSaveStore.CURRENT_SCHEMA_VERSION == 2, "Senior Roost payload must not bump the outer persistence schema", failures)
	_check(int(first_loaded.get("schema_version", -1)) == 2, "composite payload should remain wrapped in schema v2", failures)
	_check(first_loaded.get("campaign", {}) == first_expected, "save should deep-copy caller campaign data", failures)
	var first_loaded_payload := first_loaded.get("campaign", {}) as Dictionary
	var first_loaded_campaign := first_loaded_payload.get("campaign", {}) as Dictionary
	var first_loaded_roost := first_loaded_payload.get("senior_roost", {}) as Dictionary
	_check(typeof(first_loaded_campaign.get("fund_cents")) == TYPE_INT, "integer campaign values should retain their JSON type", failures)
	_check(typeof(first_loaded_campaign.get("morale")) == TYPE_FLOAT, "float campaign values should retain their JSON type", failures)
	_check(first_loaded_roost == first_expected.get("senior_roost", {}), "nested Senior Roost state should round-trip exactly", failures)
	_check(
		typeof(first_loaded_roost.get("total_senior_shifts")) == TYPE_INT
		and (first_loaded_roost.get("current_year_quarters", []) as Array).size() == 1
		and (first_loaded_roost.get("current_quarter_shifts", []) as Array).size() == 1,
		"Senior Roost counters and nested quarter records should retain their JSON shape",
		failures
	)
	_check(int((first_loaded.get("metadata", {}) as Dictionary).get("play_seconds", -1)) == 42, "caller metadata should round-trip", failures)
	_check(int((first_loaded.get("metadata", {}) as Dictionary).get("saved_at_unix", -1)) >= 0, "store should add a save timestamp", failures)
	_check(int((first_loaded.get("metadata", {}) as Dictionary).get("save_revision", -1)) == 1, "first save should have revision one", failures)
	_check(not bool(first_loaded.get("recovered_from_backup", true)), "healthy primary should not be marked recovered", failures)

	var second_campaign := first_expected.duplicate(true)
	(second_campaign.get("campaign") as Dictionary)["fund_cents"] = 13_579
	(second_campaign.get("simulation") as Dictionary)["revenue_cents"] = 13_579
	(second_campaign.get("senior_roost") as Dictionary)["roost_marks"] = int(
		(second_campaign.get("senior_roost") as Dictionary).get("roost_marks", 0)
	) + 7
	_check(store.save(second_campaign, {"slot_name": "Test Coop", "play_seconds": 88}), "overwrite should rotate a valid backup: %s" % store.last_error, failures)
	var second_loaded := store.load()
	_check(second_loaded.get("campaign", {}) == second_campaign, "latest composite primary should load after overwrite", failures)
	_check(int(second_loaded.get("schema_version", -1)) == 2, "overwrite should retain outer schema v2", failures)
	_check(int((second_loaded.get("metadata", {}) as Dictionary).get("save_revision", -1)) == 2, "overwrite should advance revision", failures)

	_write_raw(TEST_PATH, "{ definitely broken", failures)
	var recovered := store.load()
	_check(not recovered.is_empty(), "corrupt primary should recover its valid backup", failures)
	_check(bool(recovered.get("recovered_from_backup", false)), "fallback result should disclose recovery", failures)
	_check(String(recovered.get("recovery_source", "")) == "backup", "fallback should identify the backup source", failures)
	_check(recovered.get("campaign", {}) == first_expected, "rotated backup should retain the previous committed campaign", failures)
	_check(int(recovered.get("schema_version", -1)) == 2, "recovered composite payload should retain outer schema v2", failures)
	var recovered_payload := recovered.get("campaign", {}) as Dictionary
	_check(
		recovered_payload.get("senior_roost", {}) == first_expected.get("senior_roost", {}),
		"backup recovery should retain the complete nested Senior Roost payload",
		failures
	)
	_check(store.last_error.is_empty(), "successful recovery should not leave an error", failures)
	_check(store.has_save(), "recoverable backup should count as a save", failures)


func _senior_roost_fixture(failures: Array[String]) -> Dictionary:
	var senior_roost := SeniorRoostState.new()
	_check(
		senior_roost.begin(5, {"rework_total_created": 2}),
		"Senior Roost fixture should begin after probation day five",
		failures
	)
	_check(
		bool(senior_roost.select_annual_mandate(
			SeniorRoostState.MANDATE_FALLBACK_ID,
			senior_roost.current_year_number(),
		).get("accepted", false)),
		"Senior Roost persistence fixture should file the universal annual mandate fallback",
		failures,
	)
	_check(
		senior_roost.record_quarter_policy({
			"accepted": true,
			"policy_id": "flock_dividend",
			"title": "FLOCK DIVIDEND",
			"cost_cents": 2400,
			"style_id": "shared_scoop",
		}),
		"Senior Roost fixture should file its first quarter policy",
		failures
	)
	var rework_totals: Array[int] = [3, 5, 6]
	for shift_index in 3:
		var result := senior_roost.record_shift(_senior_shift_report(
			6 + shift_index,
			26 + shift_index,
			1 if shift_index != 1 else 2,
			rework_totals[shift_index]
		))
		_check(bool(result.get("accepted", false)), "Senior Roost fixture quarter shift should be accepted", failures)
	_check(senior_roost.requires_quarter_policy(), "completed fixture quarter should require its next policy", failures)
	_check(
		senior_roost.record_quarter_policy({
			"accepted": true,
			"policy_id": "harvest_forecast",
			"title": "EXECUTIVE HARVEST FORECAST",
			"cost_cents": 0,
			"style_id": "management_innovation",
		}),
		"Senior Roost fixture should file its second quarter policy",
		failures
	)
	var active_result := senior_roost.record_shift(_senior_shift_report(9, 30, 1, 8))
	_check(bool(active_result.get("accepted", false)), "Senior Roost fixture active-quarter shift should be accepted", failures)
	var payload := senior_roost.to_dictionary()
	_check(
		SeniorRoostState.validate_dictionary(payload).is_empty(),
		"Senior Roost persistence fixture should satisfy its public schema",
		failures
	)
	return payload


func _senior_shift_report(day: int, eggs: int, cracked: int, rework_total: int) -> Dictionary:
	return {
		"day": day,
		"eggs": eggs,
		"quota": 24,
		"cracked": cracked,
		"overdue_claims": 1 if day % 2 == 0 else 0,
		"rework_total_created": rework_total,
		"credited_cents": 7800 + day * 25,
		"welfare": 71 - (day % 3),
		"compliance": 76 + (day % 4),
		"farmer_favor": 68 + (day % 5),
		"wage_arrears_cents": 0,
		"closing_fund_cents": 13_000 + day * 100,
	}


func _test_input_validation_is_atomic(store: CampaignSaveStore, failures: Array[String]) -> void:
	var good_before := store.load()
	var object_payload := {"day": 5, "forbidden": RefCounted.new()}
	_check(not store.save(object_payload), "object references must be rejected", failures)
	_check(store.last_error.contains("unsupported type"), "object rejection should explain the validation error", failures)
	var after_object := store.load()
	_check(after_object.get("campaign", {}) == good_before.get("campaign", {}), "invalid object save must not modify the last good snapshot", failures)

	var non_string_key := {1: "ambiguous JSON key"}
	_check(not store.save(non_string_key), "non-String Dictionary keys must be rejected", failures)
	_check(store.last_error.contains("non-String key"), "key rejection should be actionable", failures)

	var cyclic: Dictionary = {"day": 5}
	cyclic["self"] = cyclic
	_check(not store.save(cyclic), "cyclic containers must be rejected before JSON serialization", failures)
	_check(store.last_error.contains("cyclic Dictionary"), "cycle rejection should be actionable", failures)


func _test_recovery_candidate_contract(store: CampaignSaveStore, failures: Array[String]) -> void:
	_check(store.delete(), "candidate fixture should start from an empty save set", failures)
	_write_candidate_envelope(TEST_PATH, "primary", 2, failures)
	_write_candidate_envelope("%s.bak" % TEST_PATH, "backup", 4, failures)
	_write_candidate_envelope("%s.tmp" % TEST_PATH, "temporary", 4, failures)
	_write_candidate_envelope("%s.bak.tmp" % TEST_PATH, "backup_temporary", 3, failures)

	var candidates: Array[Dictionary] = store.load_recovery_candidates()
	_check(candidates.size() == 4, "candidate API should return every envelope-valid artifact", failures)
	_check(
		_candidate_sources(candidates) == ["primary", "backup", "temporary", "backup_temporary"],
		"candidate order should keep primary first, then revision-descending recoveries with stable source ties",
		failures
	)
	var expected_revisions: Array[int] = [2, 4, 4, 3]
	for index in candidates.size():
		var candidate := candidates[index]
		var metadata := candidate.get("metadata", {}) as Dictionary
		var is_recovery := index > 0
		_check(
			int(candidate.get("schema_version", -1)) == CampaignSaveStore.CURRENT_SCHEMA_VERSION,
			"candidate should expose the migrated outer schema",
			failures
		)
		_check(
			int(candidate.get("save_revision", -1)) == expected_revisions[index]
			and int(metadata.get("save_revision", -1)) == expected_revisions[index],
			"candidate should disclose one canonical top-level and metadata revision",
			failures
		)
		_check(
			bool(candidate.get("is_recovery", not is_recovery)) == is_recovery
			and bool(candidate.get("recovered_from_backup", not is_recovery)) == is_recovery,
			"candidate should distinguish primary from every recovery artifact",
			failures
		)
	_check(store.last_error.is_empty(), "valid candidate discovery should clear artifact errors", failures)

	var legacy_load := store.load()
	_check(
		String((legacy_load.get("campaign", {}) as Dictionary).get("marker", "")) == "primary",
		"legacy load should still prefer an envelope-valid primary over newer recovery revisions",
		failures
	)
	_check(
		not legacy_load.has("save_revision") and not legacy_load.has("is_recovery"),
		"legacy load should preserve its existing public envelope shape",
		failures
	)

	var mutated_campaign := candidates[0].get("campaign", {}) as Dictionary
	mutated_campaign["marker"] = "caller-mutated"
	(mutated_campaign.get("shared", {}) as Dictionary)["token"] = "caller-mutated"
	(candidates[0].get("metadata", {}) as Dictionary)["save_revision"] = 999
	candidates[0]["save_revision"] = 999
	_check(
		String(((candidates[1].get("campaign", {}) as Dictionary).get("shared", {}) as Dictionary).get("token", "")) == "original",
		"mutating one returned candidate must not alias another candidate",
		failures
	)
	var fresh_candidates: Array[Dictionary] = store.load_recovery_candidates()
	_check(
		String((fresh_candidates[0].get("campaign", {}) as Dictionary).get("marker", "")) == "primary"
		and String(((fresh_candidates[0].get("campaign", {}) as Dictionary).get("shared", {}) as Dictionary).get("token", "")) == "original"
		and int(fresh_candidates[0].get("save_revision", -1)) == 2
		and int((fresh_candidates[0].get("metadata", {}) as Dictionary).get("save_revision", -1)) == 2,
		"candidate results must be deep-isolated from later calls and persisted envelopes",
		failures
	)

	_write_raw("%s.bak.tmp" % TEST_PATH, "{ malformed backup transaction", failures)
	var filtered: Array[Dictionary] = store.load_recovery_candidates()
	_check(
		_candidate_sources(filtered) == ["primary", "backup", "temporary"],
		"malformed artifacts should be excluded without hiding valid candidates",
		failures
	)
	_check(store.last_error.is_empty(), "excluded malformed artifacts should not poison successful discovery", failures)

	_write_raw(TEST_PATH, "{ malformed primary", failures)
	var recovery_only: Array[Dictionary] = store.load_recovery_candidates()
	_check(
		_candidate_sources(recovery_only) == ["backup", "temporary"]
		and bool(recovery_only[0].get("is_recovery", false)),
		"without a valid primary, recovery candidates should retain deterministic revision/source order",
		failures
	)
	var recovered_load := store.load()
	_check(
		String(recovered_load.get("recovery_source", "")) == "backup"
		and bool(recovered_load.get("recovered_from_backup", false)),
		"legacy load should select the first ordered recovery candidate",
		failures
	)
	_check(store.delete(), "candidate fixture cleanup should remove every artifact", failures)


func _test_corrupt_save_fallback(store: CampaignSaveStore, failures: Array[String]) -> void:
	_write_raw(TEST_PATH, "not-json", failures)
	_write_raw("%s.bak" % TEST_PATH, "also-not-json", failures)
	_write_raw("%s.tmp" % TEST_PATH, "still-not-json", failures)
	_write_raw("%s.bak.tmp" % TEST_PATH, "broken-too", failures)
	var loaded := store.load()
	_check(loaded.is_empty(), "fully corrupt save set should gracefully return an empty Dictionary", failures)
	_check(not store.last_error.is_empty(), "fully corrupt save set should expose last_error", failures)
	_check(not store.has_save(), "fully corrupt save set should not report a valid save", failures)
	store.delete()


func _test_schema_migration(store: CampaignSaveStore, failures: Array[String]) -> void:
	var version_one := {
		"schema_version": 1,
		"payload": {"campaign_id": "legacy-coop", "day": 7, "fund_cents": 999},
		"meta": {"slot_name": "Legacy", "saved_at_unix": 123, "save_revision": 5},
	}
	_write_raw(TEST_PATH, JSON.stringify(version_one), failures)
	var migrated := store.load()
	_check(not migrated.is_empty(), "supported legacy schema should migrate", failures)
	_check(int(migrated.get("schema_version", -1)) == CampaignSaveStore.CURRENT_SCHEMA_VERSION, "migration should return the current schema", failures)
	_check(String((migrated.get("campaign", {}) as Dictionary).get("campaign_id", "")) == "legacy-coop", "migration should preserve campaign payload", failures)
	_check(int((migrated.get("metadata", {}) as Dictionary).get("migrated_from_schema_version", -1)) == 1, "migration should record its source schema", failures)
	_check(int((migrated.get("metadata", {}) as Dictionary).get("save_revision", -1)) == 5, "migration should preserve revision metadata", failures)
	store.delete()


func _test_future_schema_rejection(store: CampaignSaveStore, failures: Array[String]) -> void:
	var future := {
		"format": CampaignSaveStore.SAVE_FORMAT,
		"schema_version": CampaignSaveStore.CURRENT_SCHEMA_VERSION + 1,
		"campaign": {"day": 500},
		"metadata": {"saved_at_unix": 0, "save_revision": 1},
	}
	_write_raw(TEST_PATH, JSON.stringify(future), failures)
	_check(store.load().is_empty(), "future schema must be rejected instead of guessed", failures)
	_check(store.last_error.contains("newer than supported"), "future schema rejection should be actionable", failures)
	_check(store.delete(), "delete should remove primary and recovery artifacts", failures)
	_check(not store.has_save(), "delete should leave no valid save", failures)


func _test_portable_backup_contract(failures: Array[String]) -> void:
	var source := CampaignSaveStore.new(PORTABLE_SOURCE_FILENAME)
	var target := CampaignSaveStore.new(PORTABLE_TARGET_FILENAME)
	source.delete()
	target.delete()
	var portable_campaign := {
		"campaign": {"campaign_id": "portable-coop", "completed_shifts": 3},
		"simulation": {"day": 4, "revenue_cents": 12_345, "morale": 71.5},
		"session": {"review_stage": "active", "first_clutch": {"completed": true}},
		"senior_roost": {},
	}
	_check(
		source.save(portable_campaign, {"reason": "portable_fixture", "day": 4}),
		"portable source should commit before export",
		failures,
	)
	var portable_json: String = source.export_portable_backup()
	_check(
		not portable_json.is_empty()
		and not portable_json.contains("recovered_from_backup")
		and not portable_json.contains("recovery_source"),
		"portable export should be a compact machine envelope without local recovery presentation",
		failures,
	)
	var inspected: Dictionary = source.inspect_portable_backup(portable_json)
	_check(
		inspected.get("campaign", {}) == portable_campaign
		and typeof(((inspected.get("campaign", {}) as Dictionary).get("simulation", {}) as Dictionary).get("revenue_cents")) == TYPE_INT,
		"portable inspection should preserve the complete isolated payload and integer map",
		failures,
	)
	_check(
		target.save({"marker": "previous-local-career"}, {"reason": "pre_import"}),
		"portable target should begin with a valid local career",
		failures,
	)
	_check(
		target.import_portable_backup(portable_json),
		"valid portable backup should commit through the verified transaction: %s" % target.last_error,
		failures,
	)
	var imported: Dictionary = target.load()
	_check(
		imported.get("campaign", {}) == portable_campaign
		and int((imported.get("metadata", {}) as Dictionary).get("save_revision", -1)) == 2,
		"portable import should become the newest local revision without changing its campaign",
		failures,
	)
	var recovery_candidates: Array[Dictionary] = target.load_recovery_candidates()
	_check(
		recovery_candidates.size() >= 2
		and String((recovery_candidates[1].get("campaign", {}) as Dictionary).get("marker", "")) == "previous-local-career",
		"portable import should retain the displaced valid local career as recovery",
		failures,
	)

	var before_rejection: Dictionary = target.load()
	_check(
		not target.import_portable_backup("{ malformed portable backup"),
		"malformed portable JSON must be rejected",
		failures,
	)
	_check(
		target.load().get("campaign", {}) == before_rejection.get("campaign", {}),
		"rejected portable input must not modify the current campaign",
		failures,
	)
	var future_value: Variant = JSON.parse_string(portable_json)
	if future_value is Dictionary:
		(future_value as Dictionary)["schema_version"] = CampaignSaveStore.CURRENT_SCHEMA_VERSION + 1
	_check(
		target.inspect_portable_backup(JSON.stringify(future_value)).is_empty()
		and target.last_error.contains("newer than supported"),
		"future portable schemas must fail closed with an actionable reason",
		failures,
	)
	var oversized := "x".repeat(CampaignSaveStore.MAX_FILE_BYTES + 1)
	_check(
		target.inspect_portable_backup(oversized).is_empty()
		and target.last_error.contains("size limit"),
		"oversized portable input must be rejected before JSON parsing",
		failures,
	)
	source.delete()
	target.delete()


func _test_filename_isolation(failures: Array[String]) -> void:
	var invalid := CampaignSaveStore.new("../campaign.json")
	_check(not invalid.save({"day": 1}), "injected filename must not escape user:// root", failures)
	_check(invalid.last_error.contains("filename"), "unsafe filename should expose a configuration error", failures)


func _write_raw(path: String, contents: String, failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("test fixture could not write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(contents)
	file.close()


func _write_candidate_envelope(
	path: String,
	marker: String,
	revision: int,
	failures: Array[String]
) -> void:
	var envelope := {
		"format": CampaignSaveStore.SAVE_FORMAT,
		"schema_version": CampaignSaveStore.CURRENT_SCHEMA_VERSION,
		"campaign": {
			"marker": marker,
			"counter": revision,
			"shared": {"token": "original"},
		},
		"metadata": {
			"fixture_source": marker,
			"saved_at_unix": 1000 + revision,
			"save_revision": revision,
		},
		"integer_paths": [
			"/campaign/counter",
			"/metadata/saved_at_unix",
			"/metadata/save_revision",
		],
	}
	_write_raw(path, JSON.stringify(envelope), failures)


func _candidate_sources(candidates: Array[Dictionary]) -> Array[String]:
	var sources: Array[String] = []
	for candidate in candidates:
		sources.append(String(candidate.get("recovery_source", "")))
	return sources


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
