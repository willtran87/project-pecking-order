extends SceneTree


const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "campaign_return_recap_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var campaign := CampaignState.new()
	_check(
		campaign.select_challenge_contract(CampaignState.CHALLENGE_STANDARD_FILING),
		"fixture should file Standard before saving",
		failures,
	)
	var simulation := DepartmentSimulation.new(1701, 4, 1701)
	var opening := simulation.configure_opening_challenge(
		campaign.challenge_contract_snapshot(),
	)
	_check(bool(opening.get("accepted", false)), "fixture should apply Standard opening terms", failures)
	var payload := {
		"campaign": campaign.to_dictionary(),
		"simulation": simulation.export_save_state(),
		"senior_roost": SeniorRoostState.new().to_dictionary(),
		"session": {
			"review_stage": "active",
			"last_workday_report": {},
			"senior_roost": false,
			"first_clutch": {},
		},
	}
	var metadata := {
		"reason": "new_campaign",
		"day": 1,
		"completed_shifts": 0,
		"probation_score": 50,
		"probation_rank": "probationary",
		"review_stage": "active",
	}
	payload = JSON.parse_string(JSON.stringify(payload)) as Dictionary
	metadata = JSON.parse_string(JSON.stringify(metadata)) as Dictionary
	_check(store.save(payload, metadata), "valid recap fixture should save", failures)
	var before := JSON.stringify(store.load())
	var office := Office.new()
	office.set("_campaign_store", store)
	var summary := office.call("_campaign_resume_summary") as Dictionary
	var recap := summary.get("return_recap", {}) as Dictionary
	var offline_recap := summary.get("offline_recap", {}) as Dictionary
	_check(
		String(recap.get("last_filed_label", "")) == "NEW COOP FILE OPENED"
		and String(recap.get("status_id", "")) == "attention"
		and String(recap.get("status_label", "")) == "FEED COVERAGE"
		and "ration scoops are uncovered" in String(recap.get("status_reason", ""))
		and "Provisions" in String(recap.get("next_action", ""))
		and int(recap.get("feed_fund_cents", -1)) == 5000,
		"resume recap should reuse the saved simulation's authoritative economic briefing",
		failures,
	)
	_check(
		String(offline_recap.get("status_id", "")) == "paused"
		and String(offline_recap.get("status_label", "")) == "ECONOMY PAUSED"
		and "SINCE LAST FILE" in String(offline_recap.get("elapsed_label", ""))
		and "No files advanced" in String(offline_recap.get("detail", ""))
		and "Feed Fund changed" in String(offline_recap.get("detail", "")),
		"return preview should disclose that closed time never advances the economy",
		failures,
	)
	var one_hour_two_minutes := office.call(
		"_campaign_offline_recap",
		1000,
		4720,
	) as Dictionary
	var backward_clock := office.call(
		"_campaign_offline_recap",
		2000,
		1000,
	) as Dictionary
	var capped_age := office.call(
		"_campaign_offline_recap",
		1000,
		1000 + (45 * 24 * 60 * 60),
	) as Dictionary
	_check(
		String(one_hour_two_minutes.get("elapsed_label", ""))
			== "1 HOUR 2 MINUTES SINCE LAST FILE"
		and String(one_hour_two_minutes.get("elapsed_short_label", "")) == "1H 2M"
		and int(one_hour_two_minutes.get("elapsed_seconds", -1)) == 3720
		and String(backward_clock.get("elapsed_label", "")) == "CLOCK MOVED BACKWARD"
		and String(backward_clock.get("elapsed_short_label", "")) == "CLOCK CHANGE"
		and bool(backward_clock.get("clock_anomaly", false))
		and int(backward_clock.get("elapsed_seconds", -1)) == 0
		and String(capped_age.get("elapsed_label", "")) == "30+ DAYS SINCE LAST FILE"
		and String(capped_age.get("elapsed_short_label", "")) == "30D+",
		"snapshot age should be deterministic, bounded, and harmless under clock anomalies",
		failures,
	)
	_check(
		JSON.stringify(store.load()) == before,
		"resume projection must not mutate or replace the saved candidate",
		failures,
	)
	var narrated_recap := String(office.call("_web_return_recap_summary", summary))
	var narrated_offline := String(office.call("_web_offline_recap_summary", summary))
	_check(
		"Last filed: NEW COOP FILE OPENED." in narrated_recap
		and "Unresolved: FEED COVERAGE" in narrated_recap
		and "ration scoops are uncovered" in narrated_recap
		and "Next:" in narrated_recap
		and "Provisions" in narrated_recap
		and ".." not in narrated_recap,
		"assistive title narration should preserve the visible filed action, problem, reason, and recovery",
		failures,
	)
	_check(
		"Offline: ECONOMY PAUSED" in narrated_offline
		and "SINCE LAST FILE" in narrated_offline
		and "No files advanced" in narrated_offline
		and "Feed Fund changed" in narrated_offline,
		"assistive title narration should disclose the no-offline-accrual policy",
		failures,
	)
	_check(
		String(office.call(
			"_resume_checkpoint_action_label",
			"facility_purchased_records_annex",
			2,
			{},
		)) == "FACILITY COMMISSIONED"
		and String(office.call(
			"_resume_checkpoint_action_label",
			"web_lifecycle",
			2,
			{"day": 2},
		)) == "SHIFT 2 RESULTS FILED",
		"checkpoint labels should prefer meaningful filed actions and factual shift fallback",
		failures,
	)

	var malformed_payload := payload.duplicate(true)
	var malformed_simulation := (
		malformed_payload.get("simulation", {}) as Dictionary
	).duplicate(true)
	malformed_simulation["state_version"] = 999
	malformed_payload["simulation"] = malformed_simulation
	metadata["reason"] = "facility_purchased_records_annex"
	_check(store.save(malformed_payload, metadata), "envelope-valid semantic corruption fixture should save", failures)
	var malformed_before := JSON.stringify(store.load())
	var malformed_summary := office.call("_campaign_resume_summary") as Dictionary
	_check(
		(malformed_summary.get("return_recap", {}) as Dictionary).is_empty()
		and JSON.stringify(store.load()) == malformed_before,
		"invalid saved simulation semantics should suppress the recap without mutation",
		failures,
	)
	var detached_clock := office.get("_clock") as Node
	if detached_clock != null:
		detached_clock.free()
		office.set("_clock", null)
	office.free()
	store.delete()
	simulation = null
	campaign = null
	office = null
	store = null
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPAIGN_RETURN_RECAP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_RETURN_RECAP_TEST_PASSED source=saved-simulation action=checkpoint bottleneck=authoritative next=recovery offline=paused+clock-safe mutation=none invalid=suppressed")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
