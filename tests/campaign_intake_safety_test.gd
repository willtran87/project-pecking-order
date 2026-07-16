extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "campaign_intake_safety_test.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()

	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame

	var blueprint := office.get("_capital_blueprint_ui") as CapitalBlueprintUI
	_check(
		blueprint != null and blueprint.set_filter(&"all"),
		"campaign fixture should be able to stage a retained ALL PLANS presentation filter",
		failures,
	)
	office.call("_on_campaign_new_requested")
	await process_frame
	var baseline := store.load()
	_check(not baseline.is_empty(), "new campaign should establish a verified baseline", failures)
	_check(
		String((baseline.get("metadata", {}) as Dictionary).get("reason", "")) == "new_campaign",
		"baseline checkpoint should identify the new campaign transaction",
		failures,
	)
	_check(
		blueprint != null
		and blueprint.active_filter_id() == &"ready"
		and blueprint.set_filter(&"all")
		and blueprint.visible_facility_ids().size() == 13,
		"New Campaign should reset Blueprint presentation to READY without removing the complete ALL PLANS catalog",
		failures,
	)
	var baseline_payload := (baseline.get("campaign", {}) as Dictionary).duplicate(true)

	# Returning to intake is a navigation action, not deletion. The exact payload is
	# checkpointed first and Continue remains available from the title surface.
	office.call("_on_campaign_abandon_requested")
	await process_frame
	await process_frame
	var shelved := store.load()
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	var continue_button := office.find_child("ContinueCampaignButton", true, false) as Button
	_check(not shelved.is_empty() and store.has_save(), "return to intake must preserve a loadable campaign", failures)
	_check(
		(shelved.get("campaign", {}) as Dictionary) == baseline_payload,
		"shelving should preserve the exact campaign, simulation, Senior, and tutorial payload",
		failures,
	)
	_check(
		String((shelved.get("metadata", {}) as Dictionary).get("reason", "")) == "returned_to_intake",
		"safe return should file an explicit checkpoint reason",
		failures,
	)
	_check(
		campaign_ui != null and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
		and continue_button != null and not continue_button.disabled,
		"safe return should open intake with Continue available",
		failures,
	)

	office.call("_on_campaign_continue_requested")
	await process_frame
	await process_frame
	_check(
		campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE,
		"Continue should restore the safely shelved active checkpoint",
		failures,
	)

	# Replacement must leave the preceding valid primary as the recovery copy.
	# Removing the new primary simulates a failed/lost final commit and proves the
	# old file remains recoverable instead of being deleted up front.
	office.call("_on_campaign_new_requested")
	await process_frame
	var replacement := store.load()
	_check(
		String((replacement.get("metadata", {}) as Dictionary).get("reason", "")) == "new_campaign",
		"confirmed replacement should commit a fresh verified primary",
		failures,
	)
	var primary_path := String(store.get("_primary_path"))
	_check(FileAccess.file_exists(primary_path), "replacement primary should exist before recovery probe", failures)
	var remove_error := DirAccess.remove_absolute(primary_path)
	_check(remove_error == OK, "test should be able to simulate loss of the replacement primary", failures)
	var recovered := store.load()
	_check(
		not recovered.is_empty()
		and bool(recovered.get("recovered_from_backup", false))
		and String((recovered.get("metadata", {}) as Dictionary).get("reason", "")) == "returned_to_intake",
		"replacement should retain the prior shelved file as a verified recovery copy",
		failures,
	)

	root.remove_child(office)
	office.free()
	var cleanup_succeeded := store.delete()
	_check(cleanup_succeeded, "isolated campaign safety files should clean up", failures)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPAIGN_INTAKE_SAFETY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPAIGN_INTAKE_SAFETY_TEST_PASSED return=shelved+resumable replacement=confirmed+transactional recovery=prior-primary")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
