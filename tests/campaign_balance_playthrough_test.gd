extends SceneTree


const CAMPAIGN_SEED := 1701
const PRODUCTION_HEN_COUNT := 4
const SHIFT_TICK_LIMIT := 360
const PROFILE_IDS: Array[StringName] = [
	&"baseline",
	&"quality_first",
	&"welfare_first",
	&"ruthless",
	&"passive",
	&"steward_hybrid",
	&"balanced_hybrid",
]


class BalanceSimulation:
	extends DepartmentSimulation

	# Production emits a rich presentation snapshot after every two-minute tick.
	# The lab has no snapshot listener, so replacing only that unused signal
	# payload avoids rebuilding the complete late-game UI model thousands of
	# times. All simulation mutations, decisions, RNG, reports, and ledgers still
	# run through DepartmentSimulation unchanged.
	func snapshot() -> Dictionary:
		return {}

	func full_closing_snapshot() -> Dictionary:
		return super.snapshot()


func _init() -> void:
	var failures: Array[String] = []
	var results: Dictionary = {}
	var signatures: Dictionary = {}
	var final_outcomes: Dictionary = {}
	var deep_replay := "--balance-deep-replay" in (
		OS.get_cmdline_user_args() + OS.get_cmdline_args()
	)
	_check_seed_determinism_probe(failures)

	for profile_id in PROFILE_IDS:
		var first_run := _run_profile(profile_id, failures)
		# Full duplicate trajectories are intentionally opt-in because each real
		# five-shift run builds the complete economy snapshot on every tick. The
		# routine gate compares a bounded same-seed trajectory below; tuning sessions
		# can pass --balance-deep-replay for exhaustive profile duplication.
		if deep_replay:
			var replay := _run_profile(profile_id, failures)
			_check(
				JSON.stringify(first_run) == JSON.stringify(replay),
				"%s must replay identically from the fixed campaign seed" % profile_id,
				failures,
			)
		results[String(profile_id)] = first_run
		var signature := String(first_run.get("strategy_signature", ""))
		signatures[signature] = true
		var final := first_run.get("final", {}) as Dictionary
		final_outcomes[
			"%s:%d:%d:%d" % [
				String(final.get("outcome", "")),
				int(final.get("probation_score", 0)),
				int(first_run.get("total_eggs", 0)),
				int(first_run.get("closing_fund_cents", 0)),
			]
		] = true

	_check(
		signatures.size() == PROFILE_IDS.size(),
		"each management profile must execute a distinct authoritative choice signature",
		failures,
	)
	_check(
		final_outcomes.size() >= 3,
		"the strategy profiles should produce at least three materially distinct final ledgers",
		failures,
	)
	var competent_hybrid_passes := 0
	for hybrid_id: StringName in [&"steward_hybrid", &"balanced_hybrid"]:
		var hybrid := results.get(String(hybrid_id), {}) as Dictionary
		var hybrid_final := hybrid.get("final", {}) as Dictionary
		_check(
			int(hybrid_final.get("completed_shifts", 0)) == CampaignState.CAMPAIGN_LENGTH,
			"%s must remain viable through all five probation shifts" % hybrid_id,
			failures,
		)
		if bool(hybrid_final.get("passed", false)):
			competent_hybrid_passes += 1
	_check(
		competent_hybrid_passes >= 1,
		"at least one competent rotating strategy must pass every probation safeguard",
		failures,
	)

	for profile_id in PROFILE_IDS:
		var result := results.get(String(profile_id), {}) as Dictionary
		for ledger_value in result.get("daily_ledgers", []) as Array:
			print("CAMPAIGN_BALANCE_LEDGER %s" % JSON.stringify(ledger_value))
		print("CAMPAIGN_BALANCE_SUMMARY %s" % JSON.stringify({
			"profile": String(profile_id),
			"final": result.get("final", {}),
			"total_eggs": int(result.get("total_eggs", 0)),
			"closing_fund_cents": int(result.get("closing_fund_cents", 0)),
			"first_affordable_upgrade_day": int(result.get("first_affordable_upgrade_day", 0)),
			"first_affordable_facility_day": int(result.get("first_affordable_facility_day", 0)),
			"first_clutch_choice": String(result.get("first_clutch_choice", "")),
			"strategy_signature": String(result.get("strategy_signature", "")),
		}))

	if not failures.is_empty():
		for failure in failures:
			push_error("CAMPAIGN_BALANCE_PLAYTHROUGH_TEST_FAILED: %s" % failure)
		quit(1)
		return

	print("CAMPAIGN_BALANCE_PLAYTHROUGH_TEST_PASSED profiles=%d" % PROFILE_IDS.size())
	quit(0)


func _check_seed_determinism_probe(failures: Array[String]) -> void:
	var first := BalanceSimulation.new(CAMPAIGN_SEED, PRODUCTION_HEN_COUNT)
	var second := BalanceSimulation.new(CAMPAIGN_SEED, PRODUCTION_HEN_COUNT)
	for simulation in [first, second]:
		for worker in simulation.workers:
			if worker.employed:
				simulation.set_worker_at_workstation(worker.id, true)
		_check(
			simulation.select_directive(&"shell_assurance"),
			"determinism probe must enter a real running shift",
			failures,
		)
	for _tick in 45:
		first.advance_tick()
		second.advance_tick()
	_check(
		JSON.stringify(first.export_save_state()) == JSON.stringify(second.export_save_state()),
		"same-seed four-hen simulations must produce identical authoritative trajectories",
		failures,
	)


func _run_profile(profile_id: StringName, failures: Array[String]) -> Dictionary:
	var simulation := BalanceSimulation.new(CAMPAIGN_SEED, PRODUCTION_HEN_COUNT)
	var campaign := CampaignState.new()
	var profile := _profile(profile_id)
	var egg_observation := {"count": 0, "deliveries": []}
	var first_clutch := {
		"resolved": false,
		"choice_id": "",
		"accepted": false,
	}
	var daily_ledgers: Array[Dictionary] = []
	var directive_history: Array[String] = []
	var closing_history: Array[String] = []
	var personnel_history: Array[String] = []
	var upgrade_history: Array[String] = []
	var overtime_days: Array[int] = []

	simulation.egg_laid_detailed.connect(func(
		worker_id: int,
		quality: StringName,
		value_cents: int,
		claim_id: int,
		_priority_credit_cents: int,
	) -> void:
		egg_observation["count"] = int(egg_observation["count"]) + 1
		(egg_observation["deliveries"] as Array).append({
			"worker_id": worker_id,
			"quality": String(quality),
			"value_cents": value_cents,
			"claim_id": claim_id,
		})
	)

	_check(
		simulation.active_worker_count() == PRODUCTION_HEN_COUNT,
		"%s must start from the shipped four-hen roster" % profile_id,
		failures,
	)
	_check(
		simulation.office_capacity == PRODUCTION_HEN_COUNT,
		"%s must start with exactly four authorized workstations" % profile_id,
		failures,
	)

	for shift_number in CampaignState.CAMPAIGN_LENGTH:
		var expected_day := shift_number + 1
		_check(
			simulation.day == expected_day,
			"%s shift %d must begin on authoritative day %d" % [profile_id, expected_day, expected_day],
			failures,
		)
		_check(
			simulation.shift_phase == DepartmentSimulation.ShiftPhase.AWAITING_DIRECTIVE,
			"%s day %d must begin at the morning directive" % [profile_id, expected_day],
			failures,
		)
		for worker in simulation.workers:
			if worker.employed:
				simulation.set_worker_at_workstation(worker.id, true)

		var directive_id := _directive_for_day(profile, expected_day)
		_check(
			simulation.select_directive(directive_id),
			"%s day %d must authorize %s through the public decision API" % [
				profile_id,
				expected_day,
				directive_id,
			],
			failures,
		)
		directive_history.append(String(directive_id))

		var personnel_action := _personnel_action_for_day(profile, expected_day)
		if personnel_action != &"":
			var worker_id := int(profile.get("personnel_worker_id", 0))
			var personnel_receipt := simulation.perform_personnel_action(
				worker_id,
				personnel_action,
			)
			if bool(personnel_receipt.get("accepted", false)):
				personnel_history.append("%d:%s" % [expected_day, personnel_action])
		if bool(profile.get("overtime", false)) and simulation.toggle_overtime():
			overtime_days.append(expected_day)

		var shift_result := _complete_authoritative_shift(
			simulation,
			profile_id,
			profile,
			egg_observation,
			first_clutch,
			failures,
		)
		var report := shift_result.get("report", {}) as Dictionary
		_check(
			not report.is_empty(),
			"%s day %d must emit one authoritative workday report" % [profile_id, expected_day],
			failures,
		)
		if report.is_empty():
			break
		_check(
			int(report.get("day", 0)) == expected_day,
			"%s report chronology must remain contiguous on day %d" % [profile_id, expected_day],
			failures,
		)
		var campaign_result := campaign.record_shift(
			report,
			simulation.full_closing_snapshot(),
		)
		var campaign_report_accepted := bool(campaign_result.get("accepted", false))
		_check(
			campaign_report_accepted,
			"%s day %d must file its emitted report into CampaignState" % [profile_id, expected_day],
			failures,
		)
		if not campaign_report_accepted:
			break

		if campaign.is_milestone_choice_available():
			var milestone_id := StringName(profile.get("milestone", &"padded_perches"))
			_check(
				campaign.choose_milestone(milestone_id),
				"%s must choose its day-two milestone through CampaignState" % profile_id,
				failures,
			)
			for unlock_id in campaign.unlocked_feature_ids:
				_check(
					simulation.apply_campaign_unlock(unlock_id),
					"%s milestone unlock must enter the authoritative simulation" % profile_id,
					failures,
				)

		var closing_choice := _resolve_closing_decision(
			simulation,
			profile_id,
			failures,
		)
		closing_history.append(closing_choice)
		_resolve_harvest_credit(simulation, profile_id, failures)

		var capital := _capital_affordability(simulation)
		var purchased_upgrade := _purchase_strategy_upgrade(simulation, profile)
		if not purchased_upgrade.is_empty():
			upgrade_history.append("%d:%s" % [expected_day, purchased_upgrade])
		var campaign_data := campaign.to_dictionary()
		var records := campaign_data.get("shift_records", []) as Array
		var record := records[records.size() - 1] as Dictionary if not records.is_empty() else {}
		var ledger := _daily_ledger(
			profile_id,
			report,
			record,
			campaign,
			simulation,
			capital,
			purchased_upgrade,
			shift_result,
		)
		daily_ledgers.append(ledger)

		if campaign.outcome != CampaignState.OUTCOME_IN_PROGRESS:
			break
		if expected_day < CampaignState.CAMPAIGN_LENGTH:
			_check(
				simulation.begin_next_shift_briefing(),
				"%s day %d review must release the next morning briefing" % [
					profile_id,
					expected_day,
				],
				failures,
			)

	_check(
		daily_ledgers.size() == campaign.completed_shifts,
		"%s emitted ledgers must match CampaignState's accepted shift count" % profile_id,
		failures,
	)
	_check(
		campaign.completed_shifts >= 1
		and campaign.completed_shifts <= CampaignState.CAMPAIGN_LENGTH
		and campaign.outcome != CampaignState.OUTCOME_IN_PROGRESS,
		"%s must reach a bounded final CampaignState evaluation" % profile_id,
		failures,
	)
	_check(
		int(egg_observation["count"]) == simulation.eggs_total,
		"%s egg signals must reconcile with the authoritative lifetime total" % profile_id,
		failures,
	)
	var report_egg_total := 0
	for ledger in daily_ledgers:
		report_egg_total += int(ledger.get("eggs", 0))
	_check(
		report_egg_total == simulation.eggs_total,
		"%s daily ledgers must conserve every completed egg" % profile_id,
		failures,
	)

	var final := campaign.final_evaluation()
	var first_affordable_upgrade_day := _first_affordable_day(
		daily_ledgers,
		"affordable_upgrades",
	)
	var first_affordable_facility_day := _first_affordable_day(
		daily_ledgers,
		"affordable_facilities",
	)
	var signature := "%s|%s|%s|%s|%s|%s|%s" % [
		",".join(directive_history),
		String(profile.get("milestone", &"")),
		",".join(personnel_history),
		",".join(upgrade_history),
		str(overtime_days),
		String(first_clutch.get("choice_id", "")),
		",".join(closing_history),
	]
	return {
		"profile": String(profile_id),
		"seed": CAMPAIGN_SEED,
		"initial_active_hens": PRODUCTION_HEN_COUNT,
		"daily_ledgers": daily_ledgers,
		"final": final,
		"total_eggs": simulation.eggs_total,
		"closing_fund_cents": simulation.revenue_cents,
		"first_affordable_upgrade_day": first_affordable_upgrade_day,
		"first_affordable_facility_day": first_affordable_facility_day,
		"first_clutch_choice": String(first_clutch.get("choice_id", "")),
		"closing_history": closing_history,
		"strategy_signature": signature,
	}


func _complete_authoritative_shift(
	simulation: DepartmentSimulation,
	profile_id: StringName,
	profile: Dictionary,
	egg_observation: Dictionary,
	first_clutch: Dictionary,
	failures: Array[String],
) -> Dictionary:
	var report_box := {"report": {}}
	var shift_state := {
		"incident_choices": [],
		"assists": 0,
		"assisted_claim_ids": {},
		"delivery_cursor": (egg_observation["deliveries"] as Array).size(),
	}
	simulation.workday_completed.connect(func(report: Dictionary) -> void:
		report_box["report"] = report.duplicate(true)
	, CONNECT_ONE_SHOT)

	var safety := 0
	while (report_box["report"] as Dictionary).is_empty() and safety < SHIFT_TICK_LIMIT:
		match simulation.shift_phase:
			DepartmentSimulation.ShiftPhase.RUNNING:
				simulation.advance_tick()
				_process_completed_deliveries(
					simulation,
					profile_id,
					egg_observation,
					first_clutch,
					shift_state,
					failures,
				)
				if bool(profile.get("peck_assist", false)) and int(shift_state["assists"]) < 3:
					var worker_id := simulation.recommended_peck_assist_worker_id()
					if worker_id >= 0:
						var assist := simulation.perform_peck_assist(worker_id)
						if bool(assist.get("accepted", false)):
							shift_state["assists"] = int(shift_state["assists"]) + 1
							(shift_state["assisted_claim_ids"] as Dictionary)[
								int(assist.get("claim_id", -1))
							] = true
			DepartmentSimulation.ShiftPhase.AWAITING_INCIDENT:
				var chosen := _resolve_incident(simulation, profile_id, failures)
				(shift_state["incident_choices"] as Array).append(String(chosen))
			DepartmentSimulation.ShiftPhase.REVIEW:
				break
			_:
				failures.append(
					"%s entered an unexpected phase while completing day %d" % [
						profile_id,
						simulation.day,
					]
				)
				break
		safety += 1

	_check(
		safety < SHIFT_TICK_LIMIT,
		"%s workday must close within the bounded authoritative tick budget" % profile_id,
		failures,
	)
	return {
		"report": (report_box["report"] as Dictionary).duplicate(true),
		"incident_choices": (shift_state["incident_choices"] as Array).duplicate(),
		"assists": int(shift_state["assists"]),
	}


func _process_completed_deliveries(
	simulation: DepartmentSimulation,
	profile_id: StringName,
	egg_observation: Dictionary,
	first_clutch: Dictionary,
	shift_state: Dictionary,
	failures: Array[String],
) -> void:
	var deliveries := egg_observation["deliveries"] as Array
	var cursor := int(shift_state["delivery_cursor"])
	while cursor < deliveries.size():
		var delivery := deliveries[cursor] as Dictionary
		var claim_id := int(delivery.get("claim_id", -1))
		if (shift_state["assisted_claim_ids"] as Dictionary).has(claim_id):
			var settlement := simulation.settle_peck_assist_delivery(
				claim_id,
				StringName(delivery.get("quality", &"")),
			)
			if StringName(delivery.get("quality", &"")) in [&"sound", &"golden"]:
				_check(
					bool(settlement.get("accepted", false)),
					"%s assisted clean delivery must settle through the farmer handoff API" % profile_id,
					failures,
				)
			(shift_state["assisted_claim_ids"] as Dictionary).erase(claim_id)

		if not bool(first_clutch["resolved"]) and int(delivery.get("worker_id", -1)) == 0:
			var offer := simulation.begin_first_clutch_reinvestment(
				0,
				claim_id,
				StringName(delivery.get("quality", &"")),
				int(delivery.get("value_cents", 0)),
			)
			_check(
				bool(offer.get("accepted", false)),
				"%s must open First Clutch reinvestment from Mabel's real egg" % profile_id,
				failures,
			)
			if bool(offer.get("accepted", false)):
				var choice_id := _first_clutch_choice(profile_id)
				var receipt := simulation.resolve_first_clutch_reinvestment(choice_id)
				_check(
					bool(receipt.get("accepted", false)),
					"%s must resolve the First Clutch offer through its public API" % profile_id,
					failures,
				)
				first_clutch["resolved"] = true
				first_clutch["choice_id"] = String(choice_id)
				first_clutch["accepted"] = bool(receipt.get("accepted", false))
		cursor += 1
	shift_state["delivery_cursor"] = cursor


func _resolve_incident(
	simulation: DepartmentSimulation,
	profile_id: StringName,
	failures: Array[String],
) -> StringName:
	var pending := simulation.pending_decision_snapshot()
	var options := pending.get("options", []) as Array
	var preferred_tones: Array[StringName] = []
	var paid_choices_allowed := false
	match profile_id:
		&"steward_hybrid":
			preferred_tones.assign([&"care", &"quality", &"danger"])
			paid_choices_allowed = true
		&"balanced_hybrid":
			preferred_tones.assign(
				[&"care", &"quality", &"danger"]
				if simulation.day <= 2 else
				[&"quality", &"care", &"danger"]
			)
			paid_choices_allowed = true
		&"quality_first":
			preferred_tones.assign([&"quality", &"care", &"danger"])
			paid_choices_allowed = true
		&"welfare_first":
			preferred_tones.assign([&"care", &"quality", &"danger"])
			paid_choices_allowed = true
		&"ruthless":
			preferred_tones.assign([&"danger", &"quality", &"care"])
		&"baseline":
			preferred_tones.assign([&"quality", &"care", &"danger"])
		&"passive":
			preferred_tones.assign([&"danger", &"quality", &"care"])
	var chosen := _affordable_option(
		options,
		preferred_tones,
		simulation.spendable_fund_cents(),
		paid_choices_allowed,
	)
	_check(chosen != &"", "%s incident must expose an affordable resolution" % profile_id, failures)
	if chosen != &"":
		_check(
			simulation.resolve_decision(int(pending.get("serial", -1)), chosen),
			"%s incident choice %s must resolve authoritatively" % [profile_id, chosen],
			failures,
		)
	return chosen


func _resolve_closing_decision(
	simulation: DepartmentSimulation,
	profile_id: StringName,
	failures: Array[String],
) -> String:
	var pending := simulation.pending_decision_snapshot()
	if pending.is_empty():
		return ""
	var decision_id := StringName(pending.get("id", &""))
	var desired := _closing_choice(profile_id, decision_id)
	var chosen: StringName = &""
	var options := pending.get("options", []) as Array
	for option_value in options:
		var option := option_value as Dictionary
		if (
			StringName(option.get("id", &"")) == desired
			and int(option.get("cost_cents", 0)) <= simulation.spendable_fund_cents()
		):
			chosen = desired
			break
	if chosen == &"":
		chosen = _affordable_option(
			options,
			[] as Array[StringName],
			simulation.spendable_fund_cents(),
			profile_id != &"passive",
		)
	_check(chosen != &"", "%s closing review must expose an affordable filing" % profile_id, failures)
	if chosen != &"":
		_check(
			simulation.resolve_decision(int(pending.get("serial", -1)), chosen),
			"%s closing choice %s must resolve authoritatively" % [profile_id, chosen],
			failures,
		)
	return String(chosen)


func _resolve_harvest_credit(
	simulation: DepartmentSimulation,
	profile_id: StringName,
	failures: Array[String],
) -> void:
	var gallery := simulation.farmer_relations_gallery_snapshot()
	if StringName(gallery.get("campaign_status", &"")) != &"offer_open":
		return
	var campaign_id: StringName = &""
	match profile_id:
		&"quality_first":
			campaign_id = &"layer_profile"
		&"welfare_first":
			campaign_id = &"clutch_results_board"
		&"ruthless":
			campaign_id = &"farmer_method"
	if campaign_id == &"":
		var skipped := simulation.skip_farmer_relations_campaign()
		_check(bool(skipped.get("accepted", false)), "%s must release the optional publicity gate" % profile_id, failures)
		return
	var filed := simulation.file_farmer_relations_campaign(campaign_id)
	if not bool(filed.get("accepted", false)):
		var skipped := simulation.skip_farmer_relations_campaign()
		_check(bool(skipped.get("accepted", false)), "%s must release an unavailable publicity offer" % profile_id, failures)


func _capital_affordability(simulation: DepartmentSimulation) -> Dictionary:
	var spendable := simulation.spendable_fund_cents()
	var affordable_upgrades: Array[String] = []
	for upgrade in simulation.upgrade_catalog():
		if not bool(upgrade.get("maxed", false)) and int(upgrade.get("cost_cents", 0)) <= spendable:
			affordable_upgrades.append(String(upgrade.get("id", "")))
	var affordable_facilities: Array[String] = []
	var unlocked_facilities: Array[String] = []
	var nearest_shortfall := 2_000_000_000
	for facility in simulation.facility_catalog():
		if bool(facility.get("unlocked", false)):
			unlocked_facilities.append(String(facility.get("id", "")))
			nearest_shortfall = mini(
				nearest_shortfall,
				maxi(0, int(facility.get("required_spendable_cents", 0)) - spendable),
			)
		if bool(facility.get("can_purchase", false)):
			affordable_facilities.append(String(facility.get("id", "")))
	return {
		"spendable_fund_cents": spendable,
		"affordable_upgrades": affordable_upgrades,
		"unlocked_facilities": unlocked_facilities,
		"affordable_facilities": affordable_facilities,
		"nearest_unlocked_facility_shortfall_cents": 0 if nearest_shortfall == 2_000_000_000 else nearest_shortfall,
	}


func _purchase_strategy_upgrade(simulation: DepartmentSimulation, profile: Dictionary) -> String:
	var upgrade_id := StringName(profile.get("upgrade", &""))
	if upgrade_id == &"" or simulation.upgrade_level(upgrade_id) > 0:
		return ""
	var cost := simulation.upgrade_cost_cents(upgrade_id)
	if cost < 0 or cost > simulation.spendable_fund_cents():
		return ""
	return String(upgrade_id) if simulation.purchase_upgrade(upgrade_id) else ""


func _daily_ledger(
	profile_id: StringName,
	report: Dictionary,
	record: Dictionary,
	campaign: CampaignState,
	simulation: DepartmentSimulation,
	capital: Dictionary,
	purchased_upgrade: String,
	shift_result: Dictionary,
) -> Dictionary:
	var eggs := int(report.get("eggs", 0))
	var cracked := int(report.get("cracked", 0))
	var treasury := report.get("farm_treasury", {}) as Dictionary
	return {
		"profile": String(profile_id),
		"day": int(report.get("day", 0)),
		"directive": String((report.get("directive", {}) as Dictionary).get("id", "")),
		"eggs": eggs,
		"quota": int(report.get("quota", 0)),
		"met_quota": bool(report.get("met_quota", false)),
		"cracked": cracked,
		"crack_rate_basis_points": roundi(float(cracked) * 10000.0 / maxf(1.0, float(eggs))),
		"overdue_claims": int(report.get("overdue_claims", 0)),
		"rework": int(record.get("rework", 0)),
		"welfare": int(report.get("welfare", 0)),
		"compliance": int(report.get("compliance", 0)),
		"farmer_favor": int(report.get("farmer_favor", 0)),
		"credited_cents": int(report.get("credited_cents", 0)),
		"closing_fund_cents": int(report.get("closing_fund_cents", 0)),
		"review_fund_cents": simulation.revenue_cents,
		"treasury_liabilities_cents": int(treasury.get("total_liabilities_cents", 0)),
		"campaign_score": campaign.probation_score,
		"campaign_rank": String(campaign.probation_rank),
		"affordable_upgrades": capital.get("affordable_upgrades", []),
		"unlocked_facilities": capital.get("unlocked_facilities", []),
		"affordable_facilities": capital.get("affordable_facilities", []),
		"spendable_fund_cents": int(capital.get("spendable_fund_cents", 0)),
		"nearest_unlocked_facility_shortfall_cents": int(capital.get("nearest_unlocked_facility_shortfall_cents", 0)),
		"purchased_upgrade": purchased_upgrade,
		"incident_choices": shift_result.get("incident_choices", []),
		"peck_assists": int(shift_result.get("assists", 0)),
	}


func _affordable_option(
	options: Array,
	preferred_tones: Array[StringName],
	spendable_cents: int,
	paid_choices_allowed: bool,
) -> StringName:
	for tone in preferred_tones:
		for option_value in options:
			var option := option_value as Dictionary
			var cost := int(option.get("cost_cents", 0))
			if (
				StringName(option.get("tone", &"")) == tone
				and cost <= spendable_cents
				and (paid_choices_allowed or cost == 0)
			):
				return StringName(option.get("id", &""))
	for option_value in options:
		var option := option_value as Dictionary
		if int(option.get("cost_cents", 0)) == 0:
			return StringName(option.get("id", &""))
	if paid_choices_allowed:
		for option_value in options:
			var option := option_value as Dictionary
			if int(option.get("cost_cents", 0)) <= spendable_cents:
				return StringName(option.get("id", &""))
	return &""


func _directive_for_day(profile: Dictionary, target_day: int) -> StringName:
	var schedule := profile.get("directive_schedule", []) as Array
	if target_day > 0 and target_day <= schedule.size():
		return StringName(schedule[target_day - 1])
	return StringName(profile.get("directive", &"shell_assurance"))


func _personnel_action_for_day(profile: Dictionary, target_day: int) -> StringName:
	var schedule := profile.get("personnel_schedule", []) as Array
	if target_day > 0 and target_day <= schedule.size():
		return StringName(schedule[target_day - 1])
	return StringName(profile.get("personnel_action", &""))


func _profile(profile_id: StringName) -> Dictionary:
	match profile_id:
		&"steward_hybrid":
			return {
				"directive_schedule": [
					&"sustainable_flock",
					&"sustainable_flock",
					&"shell_assurance",
					&"sustainable_flock",
					&"sustainable_flock",
				],
				"milestone": &"padded_perches",
				"personnel_schedule": [
					&"share_credit",
					&"share_credit",
					&"career_coaching",
					&"share_credit",
					&"share_credit",
				],
				"personnel_worker_id": 1,
				"upgrade": &"nest_cushion",
				"peck_assist": true,
				"overtime": false,
			}
		&"balanced_hybrid":
			return {
				"directive_schedule": [
					&"sustainable_flock",
					&"sustainable_flock",
					&"shell_assurance",
					&"sustainable_flock",
					&"sustainable_flock",
				],
				"milestone": &"padded_perches",
				"personnel_schedule": [
					&"share_credit",
					&"share_credit",
					&"career_coaching",
					&"share_credit",
					&"share_credit",
				],
				"personnel_worker_id": 0,
				"upgrade": &"nest_cushion",
				"peck_assist": true,
				"overtime": false,
			}
		&"quality_first":
			return {
				"directive": &"shell_assurance",
				"milestone": &"shell_quality_lab",
				"personnel_action": &"career_coaching",
				"personnel_worker_id": 1,
				"upgrade": &"shell_lamp",
				"peck_assist": true,
				"overtime": false,
			}
		&"welfare_first":
			return {
				"directive": &"sustainable_flock",
				"milestone": &"padded_perches",
				"personnel_action": &"share_credit",
				"personnel_worker_id": 0,
				"upgrade": &"nest_cushion",
				"peck_assist": false,
				"overtime": false,
			}
		&"ruthless":
			return {
				"directive": &"record_harvest",
				"milestone": &"farmer_credit_line",
				"personnel_action": &"quota_pressure",
				"personnel_worker_id": 2,
				"upgrade": &"peckwork_tools",
				"peck_assist": false,
				"overtime": true,
			}
		&"passive":
			return {
				"directive": &"record_harvest",
				"milestone": &"padded_perches",
				"personnel_action": &"",
				"upgrade": &"",
				"peck_assist": false,
				"overtime": false,
			}
	return {
		"directive": &"shell_assurance",
		"milestone": &"farmer_credit_line",
		"personnel_action": &"",
		"upgrade": &"peckwork_tools",
		"peck_assist": false,
		"overtime": false,
	}


func _first_clutch_choice(profile_id: StringName) -> StringName:
	match profile_id:
		&"quality_first", &"steward_hybrid", &"balanced_hybrid":
			return &"shell_lamp"
		&"ruthless":
			return &"peckwork_tools"
	return &"bank_fund"


func _closing_choice(profile_id: StringName, decision_id: StringName) -> StringName:
	match decision_id:
		&"golden_egg_dossier":
			match profile_id:
				&"welfare_first":
					return &"flock_owned_patent"
				&"ruthless", &"passive":
					return &"patent_rooster_method"
			return &"name_the_layer"
		&"flock_restructuring":
			match profile_id:
				&"welfare_first":
					return &"contest_ranking"
				&"ruthless", &"passive":
					return &"nominate_variance"
			return &"fund_redeployment"
	match profile_id:
		&"welfare_first", &"steward_hybrid":
			return &"share_feed_credit"
		&"ruthless", &"passive":
			return &"claim_management_innovation"
	return &"reward_top_layer"


func _first_affordable_day(ledgers: Array[Dictionary], key: String) -> int:
	for ledger in ledgers:
		if not (ledger.get(key, []) as Array).is_empty():
			return int(ledger.get("day", 0))
	return 0


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
