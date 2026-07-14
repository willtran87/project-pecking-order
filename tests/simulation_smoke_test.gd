extends SceneTree


func _init() -> void:
	var simulation := DepartmentSimulation.new(42)
	var directive_selected := simulation.select_directive(&"shell_assurance")
	var signal_observation := {"eggs": 0}
	simulation.egg_laid.connect(func(_worker_id: int, _quality: StringName, _value_cents: int) -> void:
		signal_observation["eggs"] += 1
	)
	for worker in simulation.workers:
		simulation.set_worker_at_workstation(worker.id, true)

	for _tick in 360:
		simulation.advance_tick()
		_resolve_pending_incident(simulation)

	var failures: Array[String] = []
	_check(directive_selected, "opening directive should authorize the simulation", failures)
	_check(int(signal_observation["eggs"]) > 0, "simulation should produce eggs", failures)
	_check(simulation.eggs_total == int(signal_observation["eggs"]), "egg signal count should match authoritative total", failures)
	_check(simulation.claims_processed == simulation.eggs_total, "each processed claim should create one egg", failures)
	_check(simulation.day >= 2, "simulation should complete at least one workday", failures)
	_check(simulation.revenue_cents >= 0, "budget must never become negative", failures)
	_check(simulation.workers.size() == 6, "vertical slice should initialize six hens", failures)
	var feed_party_simulation := DepartmentSimulation.new(7)
	var feed_party_observation := {"funded": 0}
	feed_party_simulation.feed_party_funded.connect(func() -> void:
		feed_party_observation["funded"] += 1
	)
	_check(feed_party_simulation.select_directive(&"shell_assurance"), "feed-party fixture should authorize its opening directive", failures)
	var protected_operating_fund := (
		feed_party_simulation.current_daily_operating_cost_cents()
		+ feed_party_simulation.wage_arrears_cents
	)
	feed_party_simulation.revenue_cents = protected_operating_fund + 2000
	var fund_before_feed := feed_party_simulation.revenue_cents
	var morale_before_feed := feed_party_simulation.workers[0].morale
	_check(feed_party_simulation.fund_feed_party(), "feed party should be fundable with exactly $20 above protected obligations", failures)
	_check(feed_party_observation["funded"] == 1, "successful funding should emit one authoritative feed-party signal", failures)
	_check(feed_party_simulation.revenue_cents == fund_before_feed - 2000, "feed party should cost exactly $20", failures)
	_check(feed_party_simulation.revenue_cents == protected_operating_fund, "feed party should leave operating obligations fully reserved", failures)
	_check(feed_party_simulation.workers[0].morale > morale_before_feed, "feed party should improve worker morale", failures)
	feed_party_simulation.revenue_cents = 0
	_check(not feed_party_simulation.fund_feed_party(), "feed party should be denied when the budget is empty", failures)
	_check(feed_party_observation["funded"] == 1, "denied funding must not emit the feed-party signal", failures)
	if not failures.is_empty():
		for failure in failures:
			push_error("SIMULATION_SMOKE_TEST_FAILED: %s" % failure)
		quit(1)
		return

	print("SIMULATION_SMOKE_TEST_PASSED eggs=%d day=%d budget=%d" % [
		simulation.eggs_total,
		simulation.day,
		simulation.revenue_cents,
	])
	quit(0)


func _resolve_pending_incident(simulation: DepartmentSimulation) -> void:
	var pending := simulation.pending_decision_snapshot()
	if StringName(pending.get("kind", &"")) != &"incident":
		return
	var serial := int(pending.get("serial", -1))
	for option_value in pending.get("options", []):
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) <= simulation.spendable_fund_cents():
			simulation.resolve_decision(serial, StringName(option.get("id", &"")))
			return


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
