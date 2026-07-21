extends SceneTree

const SeniorRoostStateScript := preload("res://core/campaign/senior_roost_state.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	root.size = Vector2i(1280, 720)
	var failed_review := _review(false)
	var failed_recap := SeniorRoostStateScript.annual_strategy_recap(failed_review)
	var failed_lines := "\n".join(failed_recap.get("lines", []) as Array)
	_check(
		"FLOCK DIVIDEND 2" in failed_lines
		and "MERIT GRANTS 1" in failed_lines
		and "EXECUTIVE HARVEST FORECAST 1" in failed_lines,
		"annual recap should summarize the actual four-quarter policy mix",
		failures,
	)
	_check(
		int(failed_recap.get("policy_cost_cents", -1)) == 6000
		and int(failed_recap.get("policy_fund_delta_cents", -1)) == 0,
		"annual recap should preserve exact integer policy cost and net cash facts",
		failures,
	)
	_check(
		"BEST QUARTER  /  Q3  /  FLOCK DIVIDEND  /  82 / 100" in failed_lines,
		"annual recap should identify the strongest filed quarter and its policy",
		failures,
	)
	_check(
		String(failed_recap.get("focus_id", "")) == "welfare"
		and "HELD BACK  /  FLOCK WELFARE 17% / 45%" in failed_lines,
		"a failed year should identify the largest normalized safeguard miss",
		failures,
	)
	_check(
		"Flock Dividend" in String(failed_recap.get("recommendation", ""))
		and "Wellness Nest" in String(failed_recap.get("recommendation", "")),
		"the recommendation should connect the failed safeguard to named player actions",
		failures,
	)

	var passed_review := _review(true)
	var passed_recap := SeniorRoostStateScript.annual_strategy_recap(passed_review)
	_check(
		String(passed_recap.get("focus_id", "")) == "farmer_favor"
		and bool(passed_recap.get("focus_passed", false)),
		"a passed year should identify its narrowest cleared safeguard instead of inventing a failure",
		failures,
	)
	_check(
		"NARROWEST CLEAR  /  FARMER FAVOR 58% / 50%" in "\n".join(passed_recap.get("lines", []) as Array),
		"the passed recap should disclose the exact thinnest margin",
		failures,
	)
	_check(
		SeniorRoostStateScript.annual_strategy_recap({"year": 1, "passed": true}).is_empty(),
		"legacy annual receipts without frozen quarters should remain valid and omit invented analysis",
		failures,
	)

	var office := Office.new()
	root.add_child(office)
	await process_frame
	await process_frame
	var senior := SeniorRoostStateScript.new()
	senior.status = SeniorRoostStateScript.STATUS_ANNUAL_REVIEW
	senior.completed_years = 1
	senior.completed_quarters = 4
	senior.successful_years = 0
	senior.last_annual_review = failed_review.duplicate(true)
	_check(
		(senior.snapshot().get("annual_strategy_recap", {}) as Dictionary) == failed_recap,
		"the runtime diagnostic snapshot should expose the annual strategy recap to assistive clients",
		failures,
	)
	office.set("_campaign_senior_roost", true)
	office.set("_senior_roost_state", senior)
	var snapshot := office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary
	var objective := snapshot.get("next_objective", {}) as Dictionary
	_check(
		"YEAR STRATEGY RECEIPT" in String(objective.get("description", ""))
		and "NEXT MOVE" in String(objective.get("description", "")),
		"the existing annual report should carry the strategy recap without a new menu",
		failures,
	)
	_check(
		(snapshot.get("annual_strategy_recap", {}) as Dictionary) == failed_recap,
		"the assistive presentation snapshot should expose the same recap shown on screen",
		failures,
	)
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	(office.get("_decision_host") as Control).visible = false
	_check(
		senior.continue_after_annual({}),
		"accepting the annual receipt should open the next year's mandate gate",
		failures,
	)
	var mandate_selection := senior.select_annual_mandate(
		SeniorRoostStateScript.MANDATE_FALLBACK_ID,
		senior.current_year_number(),
	)
	_check(
		bool(mandate_selection.get("accepted", false)),
		"the no-stake Board Book should open the next-year Q1 policy comparison",
		failures,
	)
	var next_year_policies := senior.policy_catalog(10_000)
	var merit_fit := _policy_fit(next_year_policies, &"merit_grants")
	var dividend_fit := _policy_fit(next_year_policies, &"flock_dividend")
	var forecast_fit := _policy_fit(next_year_policies, &"harvest_forecast")
	_check(
		String(merit_fit.get("fit_label", "")) == "NO DIRECT EDGE"
		and String(dividend_fit.get("fit_label", "")) == "RECOVERY EDGE"
		and String(forecast_fit.get("fit_label", "")) == "RECOVERY RISK",
		"the three Q1 cards should distinguish indirect, repairing, and risky responses to last year's welfare miss",
		failures,
	)
	_check(
		String(dividend_fit.get("focus_detail", "")) == "FLOCK WELFARE 17% / 45%"
		and "morale and strain relief" in String(dividend_fit.get("fit_detail", "")),
		"the best-fit policy should preserve the exact prior safeguard and explain its causal edge",
		failures,
	)
	var next_year_snapshot := office.call("_senior_presentation_snapshot", &"between_shift") as Dictionary
	_check(
		"LAST YEAR" in String(next_year_snapshot.get("choice_hint", "")),
		"next-year Q1 planning should teach the meaning of the comparison row",
		failures,
	)
	campaign_ui.show_between_shift_report(next_year_snapshot)
	await process_frame
	await process_frame
	var dividend_button := office.find_child("MilestoneChoice_flock_dividend", true, false) as Button
	var forecast_button := office.find_child("MilestoneChoice_harvest_forecast", true, false) as Button
	_check(
		dividend_button != null
		and "LAST YEAR  //  RECOVERY EDGE  /  FLOCK WELFARE 17% / 45%" in dividend_button.text,
		"the existing Dividend card should show its exact prior-year recovery fit",
		failures,
	)
	_check(
		forecast_button != null
		and "LAST YEAR  //  RECOVERY RISK  /  FLOCK WELFARE 17% / 45%" in forecast_button.text,
		"the existing Forecast card should disclose that it risks the prior welfare miss",
		failures,
	)
	_check(
		dividend_button != null
		and "Flock-wide morale and strain relief" in dividend_button.tooltip_text,
		"the policy tooltip should explain why its prior-year fit is directional rather than a promised outcome",
		failures,
	)
	_save_visual_capture(failures, "next-year-policy-fit.png")

	var passed_senior := SeniorRoostStateScript.new()
	passed_senior.status = SeniorRoostStateScript.STATUS_ANNUAL_REVIEW
	passed_senior.completed_years = 1
	passed_senior.completed_quarters = 4
	passed_senior.successful_years = 1
	passed_senior.last_annual_review = passed_review.duplicate(true)
	passed_senior.continue_after_annual({})
	passed_senior.select_annual_mandate(
		SeniorRoostStateScript.MANDATE_FALLBACK_ID,
		passed_senior.current_year_number(),
	)
	var protect_fit := _policy_fit(passed_senior.policy_catalog(10_000), &"harvest_forecast")
	_check(
		String(protect_fit.get("fit_label", "")) == "PROTECTS MARGIN"
		and String(protect_fit.get("focus_detail", "")) == "FARMER FAVOR 58% / 50%",
		"a passed year should frame the matching policy as margin protection rather than failure recovery",
		failures,
	)
	senior.current_year_quarters.append({"quarter_number": 1})
	_check(
		_policy_fit(senior.policy_catalog(10_000), &"flock_dividend").is_empty(),
		"the prior-year comparison should retire after Q1 instead of permanently cluttering every policy gate",
		failures,
	)
	senior.current_year_quarters.clear()
	campaign_ui.show_between_shift_report(snapshot)
	await process_frame
	await process_frame
	var objective_label := office.find_child("NextShiftObjectiveDescription", true, false) as Label
	_check(
		objective_label != null
		and objective_label.is_visible_in_tree()
		and "HELD BACK" in objective_label.text
		and "Wellness Nest" in objective_label.text,
		"the rendered annual receipt should display the diagnosis and actionable recommendation",
		failures,
	)
	_save_visual_capture(failures, "annual-strategy-receipt.png")
	var portrait_harness := Control.new()
	portrait_harness.name = "AnnualStrategyPortraitHarness"
	portrait_harness.size = Vector2(390.0, 844.0)
	root.add_child(portrait_harness)
	var portrait_ui := ProbationCampaignUI.new()
	portrait_harness.add_child(portrait_ui)
	await process_frame
	portrait_ui.show_between_shift_report(snapshot)
	await process_frame
	await process_frame
	var report_panel := portrait_ui.find_child("ProbationReportPanel", true, false) as PanelContainer
	var report_scroll := portrait_ui.find_child("ProbationModalScroll", true, false) as ScrollContainer
	var report_rect := report_panel.get_global_rect() if report_panel != null else Rect2()
	_check(
		report_panel != null
		and report_rect.position.x >= -0.5
		and report_rect.end.x <= 390.5,
		"the strategy receipt should remain contained at 390px portrait width (rect=%s)" % report_rect,
		failures,
	)
	_check(
		report_scroll != null
		and report_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"the strategy receipt should remain vertically scrollable without horizontal scrolling",
		failures,
	)
	portrait_harness.free()
	(office.get("_clock") as SimulationClock).set_speed(0)
	if "--capture-annual-strategy" in OS.get_cmdline_user_args():
		# Let the production Office finish its staged optional-visual coroutine
		# before this short-lived renderer fixture releases the scene tree.
		await create_timer(0.5).timeout
	office.free()
	await process_frame

	if not failures.is_empty():
		for failure in failures:
			push_error("SENIOR_ANNUAL_STRATEGY_RECAP_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("SENIOR_ANNUAL_STRATEGY_RECAP_TEST_PASSED mix=exact cash=integer best=quarter diagnosis=actionable ui=existing-report")
	quit(0)


func _review(passed: bool) -> Dictionary:
	var quarters: Array[Dictionary] = [
		_quarter(1, &"flock_dividend", "FLOCK DIVIDEND", 68, 2400, -2400),
		_quarter(2, &"merit_grants", "MERIT GRANTS", 74, 1200, -1200),
		_quarter(3, &"flock_dividend", "FLOCK DIVIDEND", 82, 2400, -2400),
		_quarter(4, &"harvest_forecast", "EXECUTIVE HARVEST FORECAST", 62, 0, 6000),
	]
	return {
		"year": 1,
		"passed": passed,
		"score": 72 if passed else 38,
		"welfare": 61 if passed else 17,
		"compliance": 76 if passed else 79,
		"farmer_favor": 58 if passed else 26,
		"crack_rate_basis_points": 1800 if passed else 3170,
		"closing_wage_arrears_cents": 0,
		"quarters": quarters,
		"mandate_settlement": {
			"mandate_name": "STANDARD BOARD BOOK",
			"success": passed,
			"stake_marks": 0,
			"stake_returned": 0,
			"stake_forfeited": 0,
			"seal_reward": 1 if passed else 0,
			"mandate_seals_after": 1 if passed else 0,
		},
	}


func _quarter(
	quarter_number: int,
	policy_id: StringName,
	policy_title: String,
	score: int,
	cost_cents: int,
	fund_delta_cents: int,
) -> Dictionary:
	return {
		"quarter_number": quarter_number,
		"quarter_in_year": quarter_number,
		"policy_id": String(policy_id),
		"policy_title": policy_title,
		"score": score,
		"policy_receipt": {
			"cost_cents": cost_cents,
			"fund_delta_cents": fund_delta_cents,
		},
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _policy_fit(policies: Array[Dictionary], policy_id: StringName) -> Dictionary:
	for policy in policies:
		if StringName(String(policy.get("id", ""))) != policy_id:
			continue
		var strategy := policy.get("strategy", {}) as Dictionary
		var fit := strategy.get("prior_year_fit", {}) as Dictionary
		return fit.duplicate(true)
	return {}


func _save_visual_capture(failures: Array[String], filename: String) -> void:
	if "--capture-annual-strategy" not in OS.get_cmdline_user_args():
		return
	var capture_directory := ProjectSettings.globalize_path(
		"res://output/web-game/senior-annual-strategy-recap-v1"
	)
	DirAccess.make_dir_recursive_absolute(capture_directory)
	var image := root.get_texture().get_image()
	_check(image != null, "annual strategy capture should expose a rendered viewport", failures)
	if image == null:
		return
	var save_error := image.save_png(capture_directory.path_join(filename))
	_check(save_error == OK, "annual strategy receipt should save successfully", failures)
