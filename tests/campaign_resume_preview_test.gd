extends SceneTree

const CampaignStateScript := preload("res://core/campaign/campaign_state.gd")


class PreviewStore:
	extends RefCounted

	var envelope: Variant = {}


	func load() -> Variant:
		return envelope


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store := PreviewStore.new()
	var office := Office.new()
	office.set("_campaign_store", store)

	store.envelope = {
		"metadata": ["not", "a", "dictionary"],
		"campaign": {
			"session": "not a dictionary",
			"campaign": 42,
			"senior_roost": null,
		},
		"recovered_from_backup": "not a boolean",
	}
	var malformed_summary := office.call("_campaign_resume_summary") as Dictionary
	_check(
		int(malformed_summary.get("day", -1)) == 1
		and int(malformed_summary.get("completed_shifts", -1)) == 0
		and int(malformed_summary.get("probation_score", -1)) == CampaignStateScript.STARTING_SCORE
		and not bool(malformed_summary.get("challenge_contract_verified", true))
		and (malformed_summary.get("challenge_contract", {}) as Dictionary).is_empty()
		and not bool(malformed_summary.get("recovered_from_backup", true)),
		"malformed nested preview payloads should use bounded defaults without inventing a contract",
		failures,
	)

	store.envelope = _envelope_with_campaign({
		"schema_id": CampaignStateScript.SCHEMA_ID,
		"schema_version": CampaignStateScript.SCHEMA_VERSION,
		"challenge_contract_id": "unknown_contract",
	})
	var unknown_summary := office.call("_campaign_resume_summary") as Dictionary
	_check(
		not bool(unknown_summary.get("challenge_contract_verified", true))
		and (unknown_summary.get("challenge_contract", {}) as Dictionary).is_empty(),
		"an unknown current-schema contract must remain unverified instead of falling back to Standard",
		failures,
	)

	store.envelope = _envelope_with_campaign({
		"schema_id": CampaignStateScript.SCHEMA_ID,
		"schema_version": CampaignStateScript.SCHEMA_VERSION,
		"challenge_contract_id": "SUPPORTED_FLOCK",
	})
	var noncanonical_summary := office.call("_campaign_resume_summary") as Dictionary
	_check(
		not bool(noncanonical_summary.get("challenge_contract_verified", true))
		and (noncanonical_summary.get("challenge_contract", {}) as Dictionary).is_empty(),
		"a normalized but noncanonical current-schema ID must remain unverified",
		failures,
	)

	store.envelope = _envelope_with_campaign({
		"schema_id": CampaignStateScript.SCHEMA_ID,
		"schema_version": CampaignStateScript.SCHEMA_VERSION,
		"challenge_contract_id": CampaignStateScript.CHALLENGE_SUPPORTED_FLOCK,
	})
	var canonical_summary := office.call("_campaign_resume_summary") as Dictionary
	var canonical_contract := canonical_summary.get("challenge_contract", {}) as Dictionary
	_check(
		bool(canonical_summary.get("challenge_contract_verified", false))
		and String(canonical_contract.get("id", "")) == String(CampaignStateScript.CHALLENGE_SUPPORTED_FLOCK),
		"an exact canonical current-schema ID should produce the saved contract preview",
		failures,
	)

	store.envelope = _envelope_with_campaign({
		"schema_id": CampaignStateScript.SCHEMA_ID,
		"schema_version": 1,
		"challenge_contract_id": "smuggled_future_terms",
	})
	var legacy_summary := office.call("_campaign_resume_summary") as Dictionary
	var legacy_contract := legacy_summary.get("challenge_contract", {}) as Dictionary
	_check(
		bool(legacy_summary.get("challenge_contract_verified", false))
		and String(legacy_contract.get("id", "")) == String(CampaignStateScript.CHALLENGE_STANDARD_FILING),
		"recognized schema v1 previews should migrate only to the canonical Standard contract",
		failures,
	)

	store.envelope = _envelope_with_campaign(
		{
			"schema_id": CampaignStateScript.SCHEMA_ID,
			"schema_version": CampaignStateScript.SCHEMA_VERSION,
			"challenge_contract_id": CampaignStateScript.CHALLENGE_EXECUTIVE_AUDIT,
		},
		{"senior_roost": true},
		{"completed_years": 2, "roost_marks": 7, "mandate_seals": 1},
	)
	var senior_summary := office.call("_campaign_resume_summary") as Dictionary
	_check(
		bool(senior_summary.get("senior_roost", false))
		and int(senior_summary.get("senior_year", 0)) == 3
		and (senior_summary.get("challenge_contract", {}) as Dictionary).is_empty(),
		"Senior resume summaries should suppress the completed probation contract",
		failures,
	)

	# Office creates its SimulationClock as an owned field and only adopts it as a
	# child during _ready(). This narrow preview test intentionally never enters
	# the tree, so release that pre-ready node explicitly before quitting.
	var pre_ready_clock := office.get("_clock") as Node
	office.free()
	if is_instance_valid(pre_ready_clock):
		pre_ready_clock.free()
	if failures.is_empty():
		print("CAMPAIGN_RESUME_PREVIEW_TEST_PASSED malformed=safe unknown=unverified noncanonical=unverified legacy=standard senior=suppressed")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _envelope_with_campaign(
	campaign: Variant,
	session: Variant = {},
	senior_roost: Variant = {},
) -> Dictionary:
	return {
		"metadata": {
			"day": 3,
			"completed_shifts": 2,
			"probation_score": 61,
			"probation_rank": "trusted_layer",
			"review_stage": "active",
		},
		"campaign": {
			"session": session,
			"campaign": campaign,
			"senior_roost": senior_roost,
		},
		"recovered_from_backup": false,
		"recovery_source": "primary",
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
