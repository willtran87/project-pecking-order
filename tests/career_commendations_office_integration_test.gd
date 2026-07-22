extends SceneTree

const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "career_commendations_office_integration_test.json"


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

	var simulation := office.get("_simulation") as DepartmentSimulation
	var audio := office.get("_audio_feedback") as OfficeAudioFeedback
	var summary := office.find_child("CareerCommendationsSummary", true, false) as Label
	var toggle := office.find_child("CareerCommendationsToggle", true, false) as FlockwatchDisclosureToggle
	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	var initial := office.commendations_snapshot()
	_check(int(initial.get("earned_count", -1)) == 0, "fresh production Office should seed a zero-stamp archive", failures)
	_check(summary != null and "0 OF 12 FILED" in summary.text, "Records should expose a concise opening commendation summary", failures)
	_check(toggle != null and "0 / 12 FILED" in toggle.text, "collapsed disclosure should publish the exact archive count", failures)

	var cue_serial_before := int(audio.feedback_snapshot().get("cue_serial", -1))
	simulation.eggs_total = 1
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	var earned := office.commendations_snapshot()
	var audio_after := audio.feedback_snapshot()
	_check(int(earned.get("earned_count", -1)) == 1, "first cumulative egg should file one permanent commendation", failures)
	_check(summary != null and "1 OF 12 FILED" in summary.text and "DOCTRINE STAMPED" in summary.text, "summary should advance to the next authored stamp", failures)
	_check(String(audio_after.get("last_cue", "")) == "commendation", "new permanent recognition should play its dedicated semantic cadence", failures)
	_check(int(audio_after.get("cue_serial", -1)) == cue_serial_before + 1, "accepted achievement should advance audio feedback exactly once", failures)
	_check("COMMENDATION FILED" in String((office.get("_ticker_label") as Label).text), "achievement should produce a visible non-modal notice", failures)

	# Re-presenting the same authoritative facts must neither duplicate recognition
	# nor replay its fanfare.
	var serial_after_first := int(audio_after.get("cue_serial", -1))
	office.call("_on_snapshot_changed", simulation.snapshot())
	await process_frame
	_check(int(audio.feedback_snapshot().get("cue_serial", -1)) == serial_after_first, "unchanged snapshots should not replay commendation feedback", failures)
	await create_timer(0.7).timeout

	# Board Book mastery is derived from authoritative annual success counts. A
	# first clear of the third distinct Book should refresh the archive once even
	# though the overall stamp order still points to the unfinished doctrine.
	var senior := office.get("_senior_roost_state") as SeniorRoostState
	senior.mandate_success_counts[SeniorRoostState.MANDATE_FALLBACK_ID] = 2
	senior.mandate_success_counts[&"shell_stewardship"] = 1
	senior.mandate_success_counts[&"flock_continuity"] = 1
	var serial_before_portfolio := int(audio.feedback_snapshot().get("cue_serial", -1))
	office.call("_refresh_commendations_from_authority")
	await process_frame
	var portfolio := office.commendations_snapshot()
	_check(bool(_row(portfolio, &"board_portfolio").get("earned", false)), "three distinct annual successes should file the portfolio commendation in production Office", failures)
	_check(int(portfolio.get("earned_count", -1)) == 2, "out-of-order portfolio mastery should coexist with the earlier first-egg stamp", failures)
	_check(int(audio.feedback_snapshot().get("cue_serial", -1)) == serial_before_portfolio + 1, "new Board Book mastery should play one permanent-recognition cadence", failures)
	_check("THREE BOOKS, ONE ROOST" in String((office.get("_ticker_label") as Label).text), "portfolio mastery should publish its authored visible notice", failures)
	office.call("_refresh_commendations_from_authority")
	await process_frame
	_check(int(audio.feedback_snapshot().get("cue_serial", -1)) == serial_before_portfolio + 1, "unchanged Book counts should not replay portfolio recognition", failures)

	if navigation != null:
		navigation.set_show_all_filings(true)
		navigation.open_page(FlockwatchNavigation.PAGE_GOVERNANCE_RECORDS)
		office.call("_set_flockwatch_open", true)
	await process_frame
	_check(summary != null and summary.is_visible_in_tree(), "Records page should keep the compact achievement summary visible", failures)
	_check(toggle != null and toggle.is_visible_in_tree() and not toggle.is_expanded(), "full achievement list should begin collapsed to preserve menu hierarchy", failures)
	if toggle != null:
		toggle.set_expanded(true)
	await process_frame
	var panels := office.find_children("CareerCommendation_*", "PanelContainer", true, false)
	var first_mark := office.find_child("CareerCommendationMark_first_egg", true, false) as Label
	var next_mark := office.find_child("CareerCommendationMark_doctrine_filed", true, false) as Label
	_check(panels.size() == 12, "expanded Records disclosure should contain exactly twelve stable cards", failures)
	_check(first_mark != null and first_mark.is_visible_in_tree() and first_mark.text == "FILED", "earned card should remain visibly stamped", failures)
	_check(next_mark != null and next_mark.is_visible_in_tree() and next_mark.text == "OPEN", "next unearned card should remain visibly open", failures)

	office.free()
	await process_frame
	store.delete()
	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_COMMENDATIONS_OFFICE_INTEGRATION_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_COMMENDATIONS_OFFICE_INTEGRATION_TEST_PASSED records=collapsed+12 cards unlock=visual+audio portfolio=distinct duplicate=none")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _row(snapshot: Dictionary, id: StringName) -> Dictionary:
	for value: Variant in snapshot.get("rows", []):
		if value is Dictionary and StringName((value as Dictionary).get("id", &"")) == id:
			return value as Dictionary
	return {}
