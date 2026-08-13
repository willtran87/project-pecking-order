extends SceneTree

const FunnelScript := preload("res://core/experience/first_session_funnel.gd")


func _init() -> void:
	var failures: Array[String] = []
	var funnel := FunnelScript.new() as FirstSessionFunnel
	funnel.begin_intake(1_000)
	var intake := funnel.snapshot(6_000)
	_check(bool(intake["active"]) and String(intake["mode"]) == "fresh_intake", "intake should start one local funnel", failures)
	_check(String(intake["privacy"]) == "LOCAL SESSION ONLY / NEVER TRANSMITTED", "diagnostics should state the privacy boundary exactly", failures)
	_check(int(intake["reached_count"]) == 1 and String(intake["next_id"]) == "file_started", "intake should expose the next missing player beat", failures)

	funnel.begin_new_file(31_000)
	funnel.observe({}, {"inspected": true}, &"active", 81_000)
	funnel.observe({}, {"inspected": true, "specialty_routed": true, "checkin_filed": true}, &"active", 151_000)
	funnel.observe({}, {"assisted_claim_id": 42}, &"active", 301_000)
	funnel.observe({"eggs_today": 1}, {}, &"active", 451_000)
	funnel.observe({"first_clutch_reinvestment": {"status": &"banked"}}, {}, &"active", 541_000)
	funnel.observe({"shift_phase": 3}, {}, &"farmer", 901_000)
	var complete := funnel.snapshot(901_000)
	_check(bool(complete["complete"]) and int(complete["reached_count"]) == 9, "the complete first-file path should land all nine beats", failures)
	_check(String(complete["next_id"]).is_empty(), "a complete funnel should have no missing next beat", failures)
	var rows := complete["milestones"] as Array
	_check(bool((rows[6] as Dictionary)["inside_budget"]), "a delivered egg inside ten minutes should satisfy the payoff budget", failures)
	_check(is_equal_approx(float((rows[6] as Dictionary)["elapsed_seconds"]), 450.0), "the first egg should retain exact local elapsed time", failures)
	var receipt_text := funnel.export_receipt(901_000)
	var receipt_value: Variant = JSON.parse_string(receipt_text)
	_check(receipt_value is Dictionary, "the opt-in playtest handoff should export bounded JSON", failures)
	var receipt := receipt_value as Dictionary if receipt_value is Dictionary else {}
	_check(String(receipt.get("consent", "")) == "PLAYER REQUESTED LOCAL EXPORT" and not bool(receipt.get("transmitted", true)), "the receipt should state explicit local consent and no transmission", failures)
	_check(not bool(receipt.get("contains_personal_data", true)), "the local receipt should declare its no-personal-data contract", failures)

	# Repeated observation is idempotent, and a resumed career is excluded rather
	# than fabricating a partial first-session record from old authority.
	funnel.observe({"eggs_today": 99}, {"inspected": true}, &"final", 1_901_000)
	_check(funnel.snapshot(1_901_000)["milestones"] == rows, "later observation should not rewrite first-hit timing", failures)
	funnel.begin_resume()
	var resumed := funnel.snapshot(2_000_000)
	_check(not bool(resumed["active"]) and String(resumed["mode"]) == "resumed_file", "resume should opt out of fresh-player timing", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("FIRST_SESSION_FUNNEL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("FIRST_SESSION_FUNNEL_TEST_PASSED privacy=local milestones=9 budgets=explicit export=opt-in+not-transmitted resume=excluded idempotent=true")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
