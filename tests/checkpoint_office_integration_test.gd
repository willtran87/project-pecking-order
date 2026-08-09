extends SceneTree


class CountingCampaignStore:
	extends RefCounted

	var last_error := ""
	var save_calls := 0
	var failures_remaining := 0
	var last_payload: Dictionary = {}
	var last_metadata: Dictionary = {}


	func has_save() -> bool:
		return save_calls > 0


	func save(payload: Dictionary, metadata: Dictionary) -> bool:
		save_calls += 1
		if failures_remaining > 0:
			failures_remaining -= 1
			last_error = "simulated browser storage failure"
			return false
		last_payload = payload.duplicate(true)
		last_metadata = metadata.duplicate(true)
		last_error = ""
		return true


class FailingNewCampaignStore:
	extends RefCounted

	var last_error := "simulated verified-write failure"
	var save_calls := 0


	func has_save() -> bool:
		return false


	func save(_payload: Dictionary, _metadata: Dictionary) -> bool:
		save_calls += 1
		last_error = "simulated verified-write failure"
		return false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var store := CountingCampaignStore.new()
	var office := Office.new()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	root.add_child(office)
	await process_frame
	await process_frame
	_check(
		not bool(office.call("_request_lifecycle_checkpoint", "web_visibility_hidden"))
		and store.save_calls == 0,
		"hiding the untouched intake must not fabricate a default resumable campaign",
		failures,
	)

	office.call("_on_campaign_new_requested")
	_check(store.save_calls == 1, "new campaign should retain its immediate verified checkpoint", failures)
	_check(
		String(store.last_metadata.get("reason", "")) == "new_campaign",
		"the baseline checkpoint should retain its exact transaction reason",
		failures,
	)

	var coordinator = office.get("_checkpoint_coordinator")
	coordinator.configure(60_000, 60_000, 1_000)
	var first_clutch := office.get("_first_clutch") as Dictionary
	first_clutch["dismissed"] = true
	first_clutch["completed"] = true
	office.set("_first_clutch", first_clutch)
	var worker_views := office.get("_worker_views") as Dictionary
	var mabel := worker_views.get(0) as ChickenView
	if mabel != null:
		mabel.stage_at_workstation_for_introduction()
	_check(mabel != null and mabel.is_seated_at_workstation(), "fixture should stage Mabel at her authored chair", failures)

	for claim_id in range(700, 705):
		office.call("_on_egg_laid", 0, &"sound", 125, claim_id, -1)
	_check(
		store.save_calls == 1,
		"five ordinary eggs in one burst must not create five synchronous full-file writes",
		failures,
	)
	var pending: Dictionary = office.call("_checkpoint_diagnostic_state")
	_check(
		bool(pending.get("dirty", false))
		and String(pending.get("status", "")) == "pending"
		and String(pending.get("reason", "")) == "egg_laid",
		"the burst should remain visibly pending behind one bounded coordinator generation",
		failures,
	)

	coordinator.configure(0, 0, 1_000)
	_check(bool(office.call("_flush_due_campaign_checkpoint")), "a due production burst should flush successfully", failures)
	_check(
		store.save_calls == 2
		and String(store.last_metadata.get("reason", "")) == "egg_laid",
		"the entire five-egg burst should settle through exactly one production checkpoint",
		failures,
	)
	var settled: Dictionary = office.call("_checkpoint_diagnostic_state")
	_check(
		not bool(settled.get("dirty", true))
		and String(settled.get("status", "")) == "saved"
		and int(settled.get("write_success_count", 0)) == 2,
		"settled diagnostics should expose a verified clean checkpoint and exact write count",
		failures,
	)

	coordinator.configure(60_000, 60_000, 1_000)
	office.call("_on_egg_laid", 0, &"sound", 125, 705, -1)
	_check(store.save_calls == 2, "a new routine egg should wait behind the quiet window", failures)
	_check(
		bool(office.call("_request_lifecycle_checkpoint", "web_visibility_hidden")),
		"a lifecycle request should synchronously subsume pending production",
		failures,
	)
	_check(
		store.save_calls == 3
		and String(store.last_metadata.get("reason", "")) == "web_visibility_hidden"
		and not coordinator.is_dirty(),
		"visibility loss should produce one immediate latest-state checkpoint without a redundant egg write",
		failures,
	)
	var calls_after_hidden := store.save_calls
	var hidden_simulation := store.last_payload.get("simulation", {}) as Dictionary
	var hidden_revision := int(hidden_simulation.get("tick_count", -1))
	var simulation := office.get("_simulation") as DepartmentSimulation
	# The isolated fixture has not selected its morning directive, so explicitly
	# enter the normal running phase before exercising a real authoritative tick.
	simulation.shift_phase = DepartmentSimulation.ShiftPhase.RUNNING
	simulation.advance_tick()
	var advanced_revision := simulation.checkpoint_revision()
	_check(
		bool(office.call("_request_lifecycle_checkpoint", "web_pagehide"))
		and store.save_calls == calls_after_hidden + 1
		and advanced_revision > hidden_revision
		and int((store.last_payload.get("simulation", {}) as Dictionary).get("tick_count", -1)) == advanced_revision,
		"a tick between same-frame lifecycle signals must force a second latest-state checkpoint",
		failures,
	)

	coordinator.configure(60_000, 60_000, 1_000)
	office.call("_on_egg_laid", 0, &"sound", 125, 706, -1)
	store.failures_remaining = 1
	var calls_before_failure := store.save_calls
	_check(
		not bool(office.call("_request_lifecycle_checkpoint", "web_visibility_hidden"))
		and store.save_calls == calls_before_failure + 1
		and coordinator.is_dirty(),
		"a failed hidden-page checkpoint should remain dirty and report failure",
		failures,
	)
	_check(
		bool(office.call("_request_lifecycle_checkpoint", "web_pagehide"))
		and store.save_calls == calls_before_failure + 2
		and not coordinator.is_dirty(),
		"a second lifecycle signal must retry immediately instead of falsely deduplicating the failure",
		failures,
	)

	first_clutch = office.call("_make_first_clutch_state", false) as Dictionary
	office.set("_first_clutch", first_clutch)
	office.call("_on_egg_laid", 0, &"sound", 125, 707, -1)
	_check(
		store.save_calls == calls_before_failure + 3
		and String(store.last_metadata.get("reason", "")) == "egg_laid",
		"the tutorial's first-clutch recovery egg must remain an immediate checkpoint",
		failures,
	)

	root.remove_child(office)
	office.free()

	# A failed first verified write must stay on intake, expose one compact
	# recovery action on the owning campaign surface, and retain the exact reason
	# in narration. The unverified in-memory replacement is never presented as a
	# playable or resumable campaign.
	var failing_store := FailingNewCampaignStore.new()
	var failing_office := Office.new()
	failing_office.set("_campaign_store", failing_store)
	failing_office.set("_allow_automated_campaign_saves", true)
	root.add_child(failing_office)
	await process_frame
	await process_frame
	failing_office.call("_show_campaign_title", false)
	await process_frame
	failing_office.call("_on_campaign_new_requested")
	await process_frame
	await process_frame
	var failing_ui := failing_office.get("_campaign_ui") as ProbationCampaignUI
	var failing_status := failing_office.find_child(
		"ProbationStatusLabel",
		true,
		false,
	) as Label
	var failing_ticker := failing_office.get("_ticker_label") as Label
	var failing_checkpoint := failing_office.call("_checkpoint_diagnostic_state") as Dictionary
	var failing_announcement := failing_office.call(
		"_web_accessibility_announcement",
		(failing_office.get("_simulation") as DepartmentSimulation).snapshot(),
	) as Dictionary
	_check(
		failing_store.save_calls == 1
		and failing_ui != null
		and failing_ui.modal_state() == ProbationCampaignUI.VIEW_TITLE
		and failing_ticker != null
		and failing_ticker.text == "NEW FILE HELD  ·  RETRY SAVE"
		and failing_status != null
		and failing_status.text == "NEW FILE HELD  ·  RETRY SAVE"
		and "no unverified campaign was opened" in String(
			failing_status.get_meta("accessible_text", "")
		).to_lower()
		and String(failing_announcement.get("kind", "")) == "career_intake"
		and "New campaign held" in String(failing_announcement.get("text", ""))
		and "simulated verified-write failure" in String(
			failing_announcement.get("text", "")
		)
		and String(failing_checkpoint.get("status", "")) == "error"
		and not bool(failing_checkpoint.get("has_checkpoint", true))
		and not bool(failing_office.get("_campaign_session_checkpoint_enabled")),
		"failed new-file verification should stay on intake with one visible, narrated retry hold and no resumable authority",
		failures,
	)
	root.remove_child(failing_office)
	failing_office.free()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CHECKPOINT_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CHECKPOINT_OFFICE_INTEGRATION_TEST_PASSED burst=5x1 lifecycle=subsumes+revision+retry tutorial=immediate intake=no-fabrication+visible-save-hold diagnostics=truthful")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
