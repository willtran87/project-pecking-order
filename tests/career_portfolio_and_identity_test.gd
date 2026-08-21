extends SceneTree

const PortfolioScript := preload("res://core/persistence/career_portfolio_store.gd")
const SimulationScript := preload("res://core/simulation/department_simulation.gd")

const TEST_FILENAME := "career_portfolio_test.json"
const TEST_PATH := "user://career_portfolio_test.json"


func _init() -> void:
	var failures: Array[String] = []
	_cleanup()
	var store = PortfolioScript.new(TEST_FILENAME)
	var first := store.load_portfolio()
	_check(String(first.get("active_slot", "")) == "roost_a", "a fresh portfolio should start in Roost A", failures)
	_check(store.activate_slot(&"roost_b"), "a player should be able to activate Roost B", failures)
	_check(store.set_identity(&"roost_b", &"field_union"), "each roost should retain an independent coop identity", failures)
	var restored = PortfolioScript.new(TEST_FILENAME)
	restored.load_portfolio()
	_check(restored.active_slot_id() == &"roost_b", "the active career roost should persist", failures)
	_check(String(restored.profile_for_slot(&"roost_b").get("id", "")) == "field_union", "the coop identity should persist with its roost", failures)
	var identity_profile := restored.profile_for_slot(&"roost_b")
	_check(
		not String(identity_profile.get("promise", "")).is_empty()
		and not String(identity_profile.get("ritual", "")).is_empty()
		and not String(identity_profile.get("prop", "")).is_empty(),
		"each cosmetic co-op identity should communicate a promise, ritual, and physical signature",
		failures,
	)
	_check(PortfolioScript.filename_for_slot(&"roost_a") != PortfolioScript.filename_for_slot(&"roost_b"), "career roosts must use isolated campaign files", failures)
	var catalog := SimulationScript.replay_scenario_catalog()
	_check(catalog.size() == 7, "the intake should offer baseline plus six authored replay files", failures)
	var ids := {}
	var seeds := {}
	for entry_value: Variant in catalog:
		var entry := entry_value as Dictionary
		ids[String(entry.get("id", ""))] = true
		seeds[int(entry.get("seed", 0))] = true
		_check(not String(entry.get("opening_rule", "")).is_empty(), "every replay file should communicate one opening rule", failures)
	_check(ids.size() == 7 and seeds.size() == 7, "replay identities and seeds should be unique", failures)
	_cleanup()
	if not failures.is_empty():
		for failure in failures:
			push_error("CAREER_PORTFOLIO_AND_IDENTITY_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAREER_PORTFOLIO_AND_IDENTITY_TEST_PASSED slots=3 identities=3 scenarios=baseline+6 persistence=isolated")
	quit(0)


func _cleanup() -> void:
	for suffix in ["", ".tmp"]:
		var path: String = TEST_PATH + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
