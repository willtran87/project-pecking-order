extends SceneTree


const CampaignSaveStoreScript := preload("res://core/persistence/campaign_save_store.gd")
const TEST_SAVE_FILENAME := "flockwatch_diagnostic_freshness_test.json"

var _stage := "boot"


class DiagnosticOffice:
	extends Office

	var diagnostic_publish_count := 0
	var captured_flockwatch: Dictionary = {}


	func _publish_web_diagnostic_state(_snapshot: Dictionary) -> void:
		diagnostic_publish_count += 1
		captured_flockwatch = _flockwatch_diagnostic_state().duplicate(true)


func _init() -> void:
	create_timer(60.0).timeout.connect(_on_watchdog_timeout)
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var store = CampaignSaveStoreScript.new(TEST_SAVE_FILENAME)
	store.delete()
	var office := DiagnosticOffice.new()
	office.set("_campaign_store", store)
	root.add_child(office)
	await process_frame
	await process_frame
	await process_frame

	var navigation := office.get("_flockwatch_navigation") as FlockwatchNavigation
	_check(navigation != null, "Office should compose the Flockwatch navigator", failures)
	if navigation == null:
		await _finish(office, store, failures)
		return

	_stage = "opening filtered filings"
	office.call("_set_flockwatch_open", true)
	navigation.open_page(FlockwatchNavigation.PAGE_TODAY)
	await process_frame
	var filtered_publish_count := office.diagnostic_publish_count

	_stage = "showing all filings"
	navigation.set_show_all_filings(true)
	await process_frame
	var all_filings_state := office.captured_flockwatch
	_check(
		office.diagnostic_publish_count == filtered_publish_count + 1,
		"Showing all filings should publish exactly one settled diagnostic update",
		failures,
	)
	_check(
		String(all_filings_state.get("current_page", "")) == "today",
		"Changing filing availability should not move the current page",
		failures,
	)
	_check(
		all_filings_state.get("available_pages", []) == [
			"today",
			"flock",
			"operations",
			"capital",
			"governance_records",
		],
		"The published diagnostic should expose all five visible filing tabs immediately",
		failures,
	)
	_check(
		"All filings shown" in String(all_filings_state.get("accessible_text", "")),
		"The published accessibility copy should describe the expanded filing set",
		failures,
	)

	_stage = "returning to relevant filings"
	var expanded_publish_count := office.diagnostic_publish_count
	navigation.set_show_all_filings(false)
	await process_frame
	var filtered_state := office.captured_flockwatch
	_check(
		office.diagnostic_publish_count == expanded_publish_count + 1,
		"Filtering filings should publish exactly one settled diagnostic update",
		failures,
	)
	_check(
		filtered_state.get("available_pages", []) == ["today", "flock"],
		"A fresh First Clutch file should return to its two relevant filing tabs",
		failures,
	)
	_check(
		"All filings filtered by relevance" in String(filtered_state.get("accessible_text", "")),
		"The published accessibility copy should describe the filtered filing set",
		failures,
	)

	await _finish(office, store, failures)


func _finish(office: DiagnosticOffice, store: Variant, failures: Array[String]) -> void:
	office.free()
	await process_frame
	store.delete()
	if not failures.is_empty():
		for failure: String in failures:
			push_error("FLOCKWATCH_DIAGNOSTIC_FRESHNESS_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FLOCKWATCH_DIAGNOSTIC_FRESHNESS_TEST_PASSED availability=immediate accessibility=fresh page=stable")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("%s [stage=%s]" % [message, _stage])


func _on_watchdog_timeout() -> void:
	push_error("FLOCKWATCH_DIAGNOSTIC_FRESHNESS_TEST_TIMEOUT stage=%s" % _stage)
	quit(1)
