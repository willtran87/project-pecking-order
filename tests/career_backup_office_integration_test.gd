extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const SOURCE_FILENAME := "career_backup_office_source_test.json"
const TARGET_FILENAME := "career_backup_office_target_test.json"
const SOURCE_FUND_CENTS := 12_345


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var source_store = CampaignSaveStoreScript.new(SOURCE_FILENAME)
	var target_store = CampaignSaveStoreScript.new(TARGET_FILENAME)
	source_store.delete()
	target_store.delete()
	_check(
		source_store.save({"structural_only": true}, {"fixture": "unverified"}),
		"fixture should begin with an envelope-valid but semantically unverified candidate",
		failures,
	)

	var source_office := Office.new()
	source_office.set("_campaign_store", source_store)
	source_office.set("_allow_automated_campaign_saves", true)
	root.add_child(source_office)
	await process_frame
	await process_frame
	var source_settings := source_office.get("_settings_ui") as PeckingOrderSettingsUI
	source_office.call("_on_settings_requested")
	await process_frame
	var cold_export_button := source_settings.find_child(
		"CareerBackupExportButton",
		true,
		false,
	) as Button
	_check(
		cold_export_button != null and cold_export_button.disabled,
		"an unverified intake must not describe a structural save candidate as export-ready",
		failures,
	)
	source_office.call("_on_settings_close_requested")
	await process_frame
	source_office.call("_on_campaign_new_requested")
	var source_simulation := source_office.get("_simulation") as DepartmentSimulation
	source_simulation.revenue_cents = SOURCE_FUND_CENTS
	_check(
		bool(source_office.call("_save_campaign_checkpoint", "portable_source_fixture")),
		"source Office should file the exact campaign before export",
		failures,
	)
	var portable_json: String = source_store.export_portable_backup()
	_check(not portable_json.is_empty(), "source Office should produce a portable campaign envelope", failures)
	root.remove_child(source_office)
	source_office.free()
	await process_frame

	var target_office := Office.new()
	target_office.set("_campaign_store", target_store)
	target_office.set("_allow_automated_campaign_saves", true)
	root.add_child(target_office)
	await process_frame
	await process_frame
	target_office.call("_on_campaign_new_requested")
	var target_simulation := target_office.get("_simulation") as DepartmentSimulation
	var prior_fund := target_simulation.revenue_cents
	_check(prior_fund != SOURCE_FUND_CENTS, "fixture careers should be visibly distinct", failures)

	var settings := target_office.get("_settings_ui") as PeckingOrderSettingsUI
	var campaign_ui := target_office.get("_campaign_ui") as ProbationCampaignUI
	var clock := target_office.get("_clock") as SimulationClock
	var ticker := target_office.get("_ticker_label") as Label
	target_office.call("_on_settings_requested")
	await process_frame
	var export_button := settings.find_child("CareerBackupExportButton", true, false) as Button
	var export_dialog := settings.find_child("CareerBackupExportDialog", true, false) as FileDialog
	var settings_status := settings.find_child("SettingsStatus", true, false) as Label
	var confirmation := settings.find_child(
		"CareerBackupImportConfirmation",
		true,
		false,
	) as ConfirmationDialog
	_check(
		settings.is_open() and export_button != null and not export_button.disabled,
		"Settings should disclose portable export once a verified checkpoint exists",
		failures,
	)
	if export_button != null:
		export_button.pressed.emit()
	await process_frame
	_check(
		export_dialog != null and export_dialog.visible
		and settings_status != null and "Choose where to save" in settings_status.text,
		"host-owned export should checkpoint first, then offer the verified portable file",
		failures,
	)
	if export_dialog != null:
		export_dialog.hide()
	_check(
		_signal_routes_to(
			settings,
			&"career_backup_import_requested",
			target_office,
			&"_on_career_backup_import_requested",
		),
		"Settings restore confirmation should route to Office's semantic authority",
		failures,
	)
	target_office.call(
		"_on_web_career_backup_offered",
		[portable_json, "source-career.json", ""],
	)
	_check(
		confirmation != null and confirmation.visible
		and settings_status != null and "Career backup staged" in settings_status.text,
		"the browser callback should stage bounded source text and refresh Settings",
		failures,
	)
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	await process_frame
	var continue_button := target_office.find_child(
		"ContinueCampaignButton",
		true,
		false,
	) as Button
	_check(
		not settings.is_open()
		and campaign_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
		and continue_button != null and not continue_button.disabled
		and clock.speed_index == 0,
		"accepted restore should return to paused intake with one truthful Continue route",
		failures,
	)
	_check(
		"PORTABLE CAREER FILED" in ticker.text
		and "prior local file remains the recovery copy" in ticker.text,
		"accepted restore should explain activation and rollback behavior",
		failures,
	)
	var imported_envelope: Dictionary = target_store.load()
	var imported_payload := imported_envelope.get("campaign", {}) as Dictionary
	var imported_simulation := imported_payload.get("simulation", {}) as Dictionary
	_check(
		int(imported_simulation.get("revenue_cents", -1)) == SOURCE_FUND_CENTS,
		"transactional import should commit the source campaign before activation",
		failures,
	)
	var candidates: Array[Dictionary] = target_store.load_recovery_candidates()
	var recovery_payload := candidates[1].get("campaign", {}) as Dictionary if candidates.size() > 1 else {}
	var recovery_simulation := recovery_payload.get("simulation", {}) as Dictionary
	_check(
		candidates.size() > 1
		and int(recovery_simulation.get("revenue_cents", -1)) == prior_fund,
		"the displaced target career should survive as the verified recovery candidate",
		failures,
	)

	target_office.call("_on_campaign_continue_requested")
	await process_frame
	await process_frame
	target_simulation = target_office.get("_simulation") as DepartmentSimulation
	_check(
		campaign_ui.modal_state() == ProbationCampaignUI.VIEW_ACTIVE
		and target_simulation.revenue_cents == SOURCE_FUND_CENTS,
		"Continue should activate the exact imported campaign through the ordinary recovery loader",
		failures,
	)

	# A structurally valid envelope with a semantically impossible simulation
	# version must fail before the current imported primary rotates again.
	var semantic_value: Variant = JSON.parse_string(portable_json)
	if semantic_value is Dictionary:
		var envelope := semantic_value as Dictionary
		var campaign_payload := envelope.get("campaign", {}) as Dictionary
		var simulation_payload := campaign_payload.get("simulation", {}) as Dictionary
		simulation_payload["state_version"] = 999
	var semantic_json := JSON.stringify(semantic_value)
	var before_rejection: Dictionary = target_store.load()
	target_office.call("_on_settings_requested")
	await process_frame
	settings.stage_career_backup_import(semantic_json, "invalid-ledger.json")
	if confirmation != null:
		confirmation.confirmed.emit()
	await process_frame
	_check(
		settings.is_open()
		and settings_status != null and "Career restore held" in settings_status.text,
		"semantic rejection should remain in Settings with an actionable status",
		failures,
	)
	_check(
		target_store.load().get("campaign", {}) == before_rejection.get("campaign", {}),
		"semantic rejection must not replace or rotate the current imported career",
		failures,
	)

	root.remove_child(target_office)
	target_office.free()
	await process_frame
	source_store.delete()
	target_store.delete()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAREER_BACKUP_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_BACKUP_OFFICE_INTEGRATION_TEST_PASSED export=latest restore=confirmed+staged+paused rollback=prior-primary reject=semantic+atomic")
	quit(0)


func _signal_routes_to(
	source: Object,
	signal_name: StringName,
	target: Object,
	method_name: StringName,
) -> bool:
	for connection: Dictionary in source.get_signal_connection_list(signal_name):
		var callable := connection.get("callable") as Callable
		if callable.get_object() == target and callable.get_method() == method_name:
			return true
	return false


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
