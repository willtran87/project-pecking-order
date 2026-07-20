extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame

	var campaign := office.get("_campaign_state") as CampaignState
	_check(campaign != null, "Office should expose the active probation campaign", failures)
	var expected := {
		1: {
			&"record_harvest": [1, 2],
			&"shell_assurance": [1, 1],
			&"sustainable_flock": [1, 1],
		},
		2: {
			&"record_harvest": [2, 0],
			&"shell_assurance": [1, 2],
			&"sustainable_flock": [0, 2],
		},
		3: {
			&"record_harvest": [1, 0],
			&"shell_assurance": [1, 1],
			&"sustainable_flock": [0, 1],
		},
		4: {
			&"record_harvest": [1, 1],
			&"shell_assurance": [2, 1],
			&"sustainable_flock": [0, 1],
		},
		5: {
			&"record_harvest": [1, 1],
			&"shell_assurance": [0, 1],
			&"sustainable_flock": [1, 1],
		},
	}

	if campaign != null:
		for day: int in expected:
			campaign.completed_shifts = day - 1
			var campaign_before := JSON.stringify(campaign.to_dictionary())
			var day_expectations := expected[day] as Dictionary
			for directive_id: StringName in day_expectations:
				var fit := office.call("_directive_order_fit", directive_id) as Dictionary
				var counts := day_expectations[directive_id] as Array
				_check(
					int(fit.get("support_count", -1)) == int(counts[0])
					and int(fit.get("risk_count", -1)) == int(counts[1]),
					"Day %d %s should derive %d supported and %d watched orders" % [
						day, directive_id, int(counts[0]), int(counts[1]),
					],
					failures,
				)
				_check(
					String(fit.get("compact", "")) == "ORDER FIT %d  /  WATCH %d" % [int(counts[0]), int(counts[1])]
					and "directional; closing ledger decides" in String(fit.get("detail", ""))
					and not String(fit.get("long_term", "")).is_empty(),
					"Day %d %s guidance should remain compact, transparent, and strategically grounded" % [day, directive_id],
					failures,
				)
			_check(
				JSON.stringify(campaign.to_dictionary()) == campaign_before,
				"Day %d policy guidance should be a read-only projection with no score, economy, or save mutation" % day,
				failures,
			)

	office.free()
	await process_frame
	if failures.is_empty():
		print("DIRECTIVE_ORDER_FIT_TEST_PASSED days=5 policies=3 guidance=derived+transparent")
		quit(0)
		return
	for failure in failures:
		push_error("DIRECTIVE_ORDER_FIT_TEST_FAILED: %s" % failure)
	quit(1)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
