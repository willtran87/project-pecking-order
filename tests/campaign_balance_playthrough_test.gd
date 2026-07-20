extends SceneTree


const CAMPAIGN_SEED := 1701
const REPLAY_DOCKET_SEEDS := [4703, 7919, 12011]
const PRODUCTION_HEN_COUNT := 4
const SHIFT_TICK_LIMIT := 360
const VIABLE_DOCTRINES := {
	&"stewardship_doctrine": {
		"milestone": &"padded_perches",
		"first_clutch": &"shell_lamp",
		"required_upgrade": &"nest_cushion",
	},
	&"assurance_doctrine": {
		"milestone": &"shell_quality_lab",
		"first_clutch": &"shell_lamp",
		"required_upgrade": &"nest_cushion",
	},
	&"harvest_doctrine": {
		"milestone": &"farmer_credit_line",
		"first_clutch": &"shell_lamp",
		"required_upgrade": &"peckwork_tools",
	},
}
const CONTROL_FAILURE_EXPECTATIONS := {
	&"baseline": &"score",
	&"quality_first": &"welfare",
	&"welfare_first": &"farmer_favor",
	&"ruthless": &"shell_quality",
	&"passive": &"compliance",
}
const PROFILE_IDS: Array[StringName] = [
	&"baseline",
	&"quality_first",
	&"welfare_first",
	&"ruthless",
	&"passive",
	&"stewardship_doctrine",
	&"assurance_doctrine",
	&"harvest_doctrine",
]
const CHALLENGE_MATRIX_CONTRACT_IDS: Array[StringName] = [
	CampaignState.CHALLENGE_SUPPORTED_FLOCK,
	CampaignState.CHALLENGE_STANDARD_FILING,
	CampaignState.CHALLENGE_EXECUTIVE_AUDIT,
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
	_check_replay_docket_viability(failures)
	_check_supported_guided_no_micro_viability(failures)

	for profile_id in PROFILE_IDS:
		var first_run := _run_profile(profile_id, failures)
		# Every supported doctrine gets a full routine replay. Deep replay extends
		# the same proof to intentionally failing control profiles during tuning.
		if deep_replay or VIABLE_DOCTRINES.has(profile_id):
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
			"%s:%d:%d:%d:%d:%d:%d:%d" % [
				String(final.get("outcome", "")),
				int(final.get("probation_score", 0)),
				int(final.get("average_welfare", 0)),
				int(final.get("average_compliance", 0)),
				int(final.get("average_farmer_favor", 0)),
				int(final.get("crack_rate_basis_points", 0)),
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
	var doctrine_signatures: Dictionary = {}
	var doctrine_results: Array[Dictionary] = []
	for doctrine_id_value in VIABLE_DOCTRINES.keys():
		var doctrine_id := StringName(doctrine_id_value)
		var doctrine_spec := VIABLE_DOCTRINES[doctrine_id] as Dictionary
		var doctrine := results.get(String(doctrine_id), {}) as Dictionary
		var doctrine_final := doctrine.get("final", {}) as Dictionary
		_check(
			int(doctrine_final.get("completed_shifts", 0)) == CampaignState.CAMPAIGN_LENGTH,
			"%s must remain viable through all five probation shifts" % doctrine_id,
			failures,
		)
		_check(bool(doctrine_final.get("passed", false)), "%s must pass probation" % doctrine_id, failures)
		_check(
			_all_criteria_pass(doctrine_final),
			"%s must pass all five unchanged probation safeguards" % doctrine_id,
			failures,
		)
		_check(
			StringName(doctrine_final.get("chosen_milestone_id", &"")) == StringName(doctrine_spec["milestone"]),
			"%s must authoritatively file milestone %s" % [doctrine_id, doctrine_spec["milestone"]],
			failures,
		)
		_check(
			StringName(doctrine.get("first_clutch_choice", &"")) == StringName(doctrine_spec["first_clutch"])
			and bool(doctrine.get("first_clutch_accepted", false)),
			"%s must accept its required First Clutch reinvestment" % doctrine_id,
			failures,
		)
		_check(
			_has_accepted_upgrade(doctrine, StringName(doctrine_spec["required_upgrade"])),
			"%s must authoritatively purchase required upgrade %s" % [doctrine_id, doctrine_spec["required_upgrade"]],
			failures,
		)
		_check(
			_all_intended_personnel_actions_accepted(doctrine),
			"%s must not count rejected personnel actions as strategy" % doctrine_id,
			failures,
		)
		var doctrine_signature := String(doctrine.get("strategy_signature", ""))
		doctrine_signatures[doctrine_signature] = true
		doctrine_results.append(doctrine)
	_check(doctrine_signatures.size() == VIABLE_DOCTRINES.size(), "viable doctrines must execute distinct authoritative strategies", failures)
	_check(
		_doctrine_vectors_are_materially_distinct(doctrine_results),
		"viable doctrines must finish with materially distinct management tradeoffs",
		failures,
	)
	_check(
		_doctrine_route_tradeoffs_are_legible(results),
		"each viable doctrine must express its promised comparative strength in the final ledger",
		failures,
	)

	for control_id_value in CONTROL_FAILURE_EXPECTATIONS.keys():
		var control_id := StringName(control_id_value)
		var control := results.get(String(control_id), {}) as Dictionary
		var control_final := control.get("final", {}) as Dictionary
		var expected_failure := StringName(CONTROL_FAILURE_EXPECTATIONS[control_id])
		_check(not bool(control_final.get("passed", false)), "%s must remain a failing control" % control_id, failures)
		_check(
			not bool((control_final.get("criteria", {}) as Dictionary).get(String(expected_failure), true)),
			"%s must continue to expose its expected %s failure" % [control_id, expected_failure],
			failures,
		)

	_check_challenge_contract_playthroughs(results, failures)
	_emit_challenge_doctrine_matrix(results, failures)
	_check_board_book_strategy_matrix(failures)

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

	print("CAMPAIGN_BALANCE_PLAYTHROUGH_TEST_PASSED profiles=%d challenge_contracts=3 board_books=7 strategy_routes=7 gold_controls=1 senior_dockets=4" % PROFILE_IDS.size())
	quit(0)


func _emit_challenge_doctrine_matrix(
	standard_results: Dictionary,
	failures: Array[String],
) -> void:
	var matrix: Dictionary = {}
	for contract_id in CHALLENGE_MATRIX_CONTRACT_IDS:
		var contract_results: Dictionary = {}
		for doctrine_id_value in VIABLE_DOCTRINES.keys():
			var doctrine_id := StringName(doctrine_id_value)
			var result := (
				standard_results.get(String(doctrine_id), {}) as Dictionary
				if contract_id == CampaignState.CHALLENGE_STANDARD_FILING
				else _run_profile(doctrine_id, failures, contract_id)
			)
			var final := result.get("final", {}) as Dictionary
			contract_results[String(doctrine_id)] = result
			print("CAMPAIGN_BALANCE_MATRIX %s" % JSON.stringify({
				"contract": String(contract_id),
				"profile": String(doctrine_id),
				"passed": bool(final.get("passed", false)),
				"criteria": final.get("criteria", {}),
				"probation_score": int(final.get("probation_score", 0)),
				"average_welfare": int(final.get("average_welfare", 0)),
				"average_compliance": int(final.get("average_compliance", 0)),
				"average_farmer_favor": int(final.get("average_farmer_favor", 0)),
				"crack_rate_basis_points": int(final.get("crack_rate_basis_points", 0)),
				"total_eggs": int(result.get("total_eggs", 0)),
				"closing_fund_cents": int(result.get("closing_fund_cents", 0)),
				"first_affordable_upgrade_day": int(result.get("first_affordable_upgrade_day", 0)),
				"first_affordable_facility_day": int(result.get("first_affordable_facility_day", 0)),
				"strategy_signature": String(result.get("strategy_signature", "")),
			}))
		matrix[String(contract_id)] = contract_results

	var supported := matrix.get(String(CampaignState.CHALLENGE_SUPPORTED_FLOCK), {}) as Dictionary
	var standard := matrix.get(String(CampaignState.CHALLENGE_STANDARD_FILING), {}) as Dictionary
	var executive := matrix.get(String(CampaignState.CHALLENGE_EXECUTIVE_AUDIT), {}) as Dictionary
	_check(
		_count_passing_routes(supported) == VIABLE_DOCTRINES.size(),
		"Supported Flock must preserve all three proven doctrine routes",
		failures,
	)
	_check(
		_count_passing_routes(standard) == VIABLE_DOCTRINES.size(),
		"Standard Filing must preserve all three proven doctrine routes",
		failures,
	)
	_check(
		_count_passing_routes(executive) >= 1
		and bool(((executive.get("harvest_doctrine", {}) as Dictionary).get("final", {}) as Dictionary).get("passed", false)),
		"Executive Audit must retain a proven specialist Harvest Partnership route",
		failures,
	)
	_check(
		_count_passing_routes(executive) < VIABLE_DOCTRINES.size(),
		"Executive Audit must remain a meaningfully stricter specialist replay contract",
		failures,
	)
	for doctrine_id_value in VIABLE_DOCTRINES.keys():
		var doctrine_key := String(doctrine_id_value)
		var standard_result := standard.get(doctrine_key, {}) as Dictionary
		for contract_results_value in [supported, executive]:
			var comparison_result := (contract_results_value as Dictionary).get(doctrine_key, {}) as Dictionary
			_check(
				JSON.stringify(standard_result.get("daily_ledgers", []))
				== JSON.stringify(comparison_result.get("daily_ledgers", [])),
				"%s must keep one authoritative simulation ledger across challenge contracts" % doctrine_key,
				failures,
			)
	_check(
		not _matrix_has_dominant_doctrine(standard),
		"Standard Filing must not contain one doctrine that weakly dominates every alternative",
		failures,
	)


func _count_passing_routes(results: Dictionary) -> int:
	var count := 0
	for result_value in results.values():
		var final := (result_value as Dictionary).get("final", {}) as Dictionary
		if bool(final.get("passed", false)) and _all_criteria_pass(final):
			count += 1
	return count


func _matrix_has_dominant_doctrine(results: Dictionary) -> bool:
	for candidate_key in results.keys():
		var candidate := results[candidate_key] as Dictionary
		var dominates_all := true
		for alternative_key in results.keys():
			if alternative_key == candidate_key:
				continue
			if not _weakly_dominates(candidate, results[alternative_key] as Dictionary):
				dominates_all = false
				break
		if dominates_all:
			return true
	return false


func _weakly_dominates(candidate: Dictionary, alternative: Dictionary) -> bool:
	var first := _doctrine_outcome_vector(candidate)
	var second := _doctrine_outcome_vector(alternative)
	var strictly_better := false
	for metric in [
		"probation_score", "average_welfare", "average_compliance",
		"average_farmer_favor", "closing_fund_cents", "total_eggs",
	]:
		if int(first[metric]) < int(second[metric]):
			return false
		strictly_better = strictly_better or int(first[metric]) > int(second[metric])
	if int(first["crack_rate_basis_points"]) > int(second["crack_rate_basis_points"]):
		return false
	strictly_better = strictly_better or (
		int(first["crack_rate_basis_points"]) < int(second["crack_rate_basis_points"])
	)
	return strictly_better


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


func _check_replay_docket_viability(failures: Array[String]) -> void:
	for docket_seed in REPLAY_DOCKET_SEEDS:
		for doctrine_id_value in VIABLE_DOCTRINES.keys():
			var doctrine_id := StringName(doctrine_id_value)
			var result := _run_profile(
				doctrine_id,
				failures,
				CampaignState.CHALLENGE_STANDARD_FILING,
				docket_seed,
			)
			var final := result.get("final", {}) as Dictionary
			print("CAMPAIGN_REPLAY_DOCKET %s" % JSON.stringify({
				"seed": docket_seed,
				"profile": String(doctrine_id),
				"passed": bool(final.get("passed", false)),
				"criteria": final.get("criteria", {}),
				"score": int(final.get("probation_score", 0)),
				"welfare": int(final.get("average_welfare", 0)),
				"compliance": int(final.get("average_compliance", 0)),
				"favor": int(final.get("average_farmer_favor", 0)),
				"crack_rate_basis_points": int(final.get("crack_rate_basis_points", 0)),
			}))
			_check(
				bool(final.get("passed", false)) and _all_criteria_pass(final),
				"replay docket %d must preserve the viable %s Standard Filing route" % [docket_seed, doctrine_id],
				failures,
			)


func _check_supported_guided_no_micro_viability(failures: Array[String]) -> void:
	# Learning explicitly permits the optional First Clutch coach to be skipped.
	# A player who still follows the care-led policy brief and chooses constructive
	# incident responses must not pass or fail solely because of the authored docket.
	for docket_seed in [CAMPAIGN_SEED] + REPLAY_DOCKET_SEEDS:
		var result := _run_profile(
			&"guided_no_micro",
			failures,
			CampaignState.CHALLENGE_SUPPORTED_FLOCK,
			docket_seed,
		)
		var final := result.get("final", {}) as Dictionary
		print("CAMPAIGN_GUIDED_NO_MICRO %s" % JSON.stringify({
			"seed": docket_seed,
			"passed": bool(final.get("passed", false)),
			"criteria": final.get("criteria", {}),
			"score": int(final.get("probation_score", 0)),
			"welfare": int(final.get("average_welfare", 0)),
			"compliance": int(final.get("average_compliance", 0)),
			"favor": int(final.get("average_farmer_favor", 0)),
			"crack_rate_basis_points": int(final.get("crack_rate_basis_points", 0)),
		}))
		_check(
			bool(final.get("passed", false)) and _all_criteria_pass(final),
			"Supported Flock guided no-micro route must remain viable on docket %d" % docket_seed,
			failures,
		)


func _check_challenge_contract_playthroughs(
	standard_results: Dictionary,
	failures: Array[String],
) -> void:
	var supported := _run_profile(
		&"welfare_first",
		failures,
		CampaignState.CHALLENGE_SUPPORTED_FLOCK,
	)
	var supported_replay := _run_profile(
		&"welfare_first",
		failures,
		CampaignState.CHALLENGE_SUPPORTED_FLOCK,
	)
	_check(
		JSON.stringify(supported) == JSON.stringify(supported_replay),
		"Supported Flock must replay identically from the fixed campaign seed",
		failures,
	)
	_check_contract_result(
		supported,
		CampaignState.CHALLENGE_SUPPORTED_FLOCK,
		{
			"probation_score": 54,
			"average_welfare": 64,
			"average_compliance": 73,
			"average_farmer_favor": 47,
			"crack_rate_basis_points": 2209,
			"total_eggs": 163,
			"closing_fund_cents": 64650,
		},
		failures,
	)

	var executive := _run_profile(
		&"harvest_doctrine",
		failures,
		CampaignState.CHALLENGE_EXECUTIVE_AUDIT,
	)
	var executive_replay := _run_profile(
		&"harvest_doctrine",
		failures,
		CampaignState.CHALLENGE_EXECUTIVE_AUDIT,
	)
	_check(
		JSON.stringify(executive) == JSON.stringify(executive_replay),
		"Executive Audit must replay identically from the fixed campaign seed",
		failures,
	)
	_check_contract_result(
		executive,
		CampaignState.CHALLENGE_EXECUTIVE_AUDIT,
		{
			"probation_score": 68,
			"average_welfare": 50,
			"average_compliance": 79,
			"average_farmer_favor": 55,
			"crack_rate_basis_points": 2244,
			"total_eggs": 156,
			"closing_fund_cents": 64091,
		},
		failures,
	)

	# The contract changes only the disclosed filing standard. It must not alter
	# the shipped simulation ledger for the same doctrine and seed.
	var standard_harvest := standard_results.get("harvest_doctrine", {}) as Dictionary
	_check_contract_result(
		standard_harvest,
		CampaignState.CHALLENGE_STANDARD_FILING,
		{
			"probation_score": 68,
			"average_welfare": 50,
			"average_compliance": 79,
			"average_farmer_favor": 55,
			"crack_rate_basis_points": 2244,
			"total_eggs": 156,
			"closing_fund_cents": 64091,
		},
		failures,
	)
	_check(
		JSON.stringify(standard_harvest.get("daily_ledgers", []))
		== JSON.stringify(executive.get("daily_ledgers", [])),
		"Executive Audit must preserve the Standard Filing harvest ledger",
		failures,
	)


func _check_contract_result(
	result: Dictionary,
	contract_id: StringName,
	expected: Dictionary,
	failures: Array[String],
) -> void:
	var final := result.get("final", {}) as Dictionary
	var contract := final.get("challenge_contract", {}) as Dictionary
	_check(
		StringName(contract.get("id", &"")) == contract_id,
		"%s result must identify its authoritative challenge contract" % contract_id,
		failures,
	)
	_check(bool(final.get("passed", false)), "%s proof doctrine must pass probation" % contract_id, failures)
	_check(_all_criteria_pass(final), "%s proof doctrine must pass every disclosed safeguard" % contract_id, failures)
	for metric in [
		"probation_score",
		"average_welfare",
		"average_compliance",
		"average_farmer_favor",
		"crack_rate_basis_points",
	]:
		_check(
			int(final.get(metric, -1)) == int(expected.get(metric, -2)),
			"%s must preserve the fixed %s ledger" % [contract_id, metric],
			failures,
		)
	for metric in ["total_eggs", "closing_fund_cents"]:
		_check(
			int(result.get(metric, -1)) == int(expected.get(metric, -2)),
			"%s must preserve the fixed %s ledger" % [contract_id, metric],
			failures,
		)


func _run_profile(
	profile_id: StringName,
	failures: Array[String],
	challenge_contract_id: StringName = CampaignState.CHALLENGE_STANDARD_FILING,
	campaign_seed: int = CAMPAIGN_SEED,
	preserve_runtime: bool = false,
) -> Dictionary:
	var simulation := BalanceSimulation.new(CAMPAIGN_SEED, PRODUCTION_HEN_COUNT, campaign_seed)
	var campaign := CampaignState.new()
	_check(
		campaign.select_challenge_contract(challenge_contract_id),
		"%s must file challenge contract %s before the first shift" % [
			profile_id,
			challenge_contract_id,
		],
		failures,
	)
	var profile := _profile(profile_id)
	var egg_observation := {"count": 0, "deliveries": []}
	var first_clutch := {
		"resolved": bool(profile.get("skip_first_clutch", false)),
		"choice_id": "",
		"accepted": false,
	}
	var daily_ledgers: Array[Dictionary] = []
	var directive_history: Array[String] = []
	var closing_history: Array[String] = []
	var personnel_history: Array[String] = []
	var personnel_receipts: Array[Dictionary] = []
	var upgrade_history: Array[String] = []
	var gallery_history: Array[String] = []
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
			var worker_id := _personnel_worker_for_day(profile, expected_day)
			var personnel_receipt := simulation.perform_personnel_action(
				worker_id,
				personnel_action,
			)
			personnel_receipts.append({
				"day": expected_day,
				"action": String(personnel_action),
				"accepted": bool(personnel_receipt.get("accepted", false)),
				"reason": String(personnel_receipt.get("reason", "")),
			})
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
		var gallery_choice := _resolve_harvest_credit(simulation, profile_id, failures)
		if not gallery_choice.is_empty():
			gallery_history.append("%d:%s" % [expected_day, gallery_choice])

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
	var signature := "%s|%s|%s|%s|%s|%s|%s|%s" % [
		",".join(directive_history),
		String(profile.get("milestone", &"")),
		",".join(personnel_history),
		",".join(upgrade_history),
		str(overtime_days),
		String(first_clutch.get("choice_id", "")),
		",".join(closing_history),
		",".join(gallery_history),
	]
	var result := {
		"profile": String(profile_id),
		"challenge_contract_id": String(challenge_contract_id),
		"seed": campaign_seed,
		"initial_active_hens": PRODUCTION_HEN_COUNT,
		"daily_ledgers": daily_ledgers,
		"final": final,
		"total_eggs": simulation.eggs_total,
		"closing_fund_cents": simulation.revenue_cents,
		"first_affordable_upgrade_day": first_affordable_upgrade_day,
		"first_affordable_facility_day": first_affordable_facility_day,
		"first_clutch_choice": String(first_clutch.get("choice_id", "")),
		"first_clutch_accepted": bool(first_clutch.get("accepted", false)),
		"closing_history": closing_history,
		"personnel_receipts": personnel_receipts,
		"upgrade_history": upgrade_history,
		"gallery_history": gallery_history,
		"strategy_signature": signature,
	}
	if preserve_runtime:
		result["_simulation"] = simulation
		result["_campaign"] = campaign
	return result


func _check_board_book_strategy_matrix(failures: Array[String]) -> void:
	## Senior Roost offers are only useful when a disclosed management doctrine
	## can actually close them. These routes continue a legitimately passed
	## probation simulation for up to four complete Senior years, so quotas,
	## funds, workers, incidents, and closing decisions all remain authoritative.
	var routes := [
		{
			"id": &"assurance_books",
			"probation_profile": &"assurance_doctrine",
			"years": [
				{
					"mandate": &"shell_stewardship",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"shell_assurance",
					"capital_targets": {
						"staff": 4,
						"upgrades": {
							"peckwork_tools": 4,
							"shell_lamp": 3,
							"nest_cushion": 2,
						},
						"facilities": {
							"candling_rework_bay": 1,
						},
					},
				},
				{
					"mandate": &"mutual_assurance",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"shell_assurance",
				},
				{
					"mandate": &"rested_flock_covenant",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"sustainable_flock",
					"capital_targets": {
						"staff": 6,
						"upgrades": {
							"peckwork_tools": 5,
							"shell_lamp": 5,
							"nest_cushion": 5,
						},
						"facilities": {
							"candling_rework_bay": 1,
							"wellness_nest_room": 1,
						},
					},
				},
				{
					"mandate": &"gold_standard_book",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"record_harvest",
				},
			],
		},
		{
			"id": &"flock_book",
			"probation_profile": &"stewardship_doctrine",
			"years": [
				{
					"mandate": &"flock_continuity",
					"policies": [&"harvest_forecast", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"sustainable_flock",
				},
			],
		},
		{
			"id": &"executive_book",
			"probation_profile": &"stewardship_doctrine",
			"years": [
				{
					"mandate": &"standard_board_book",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"sustainable_flock",
				},
				{
					"mandate": &"executive_harvest",
					"policies": [&"harvest_forecast", &"harvest_forecast", &"harvest_forecast", &"harvest_forecast"],
					"directive": &"sustainable_flock",
					"decision_profile": &"senior_executive",
				},
			],
		},
		{
			"id": &"unprepared_gold_control",
			"probation_profile": &"assurance_doctrine",
			"years": [
				{
					"mandate": &"shell_stewardship",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"shell_assurance",
				},
				{
					"mandate": &"mutual_assurance",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"shell_assurance",
				},
				{
					"mandate": &"rested_flock_covenant",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"sustainable_flock",
				},
				{
					"mandate": &"gold_standard_book",
					"policies": [&"flock_dividend", &"flock_dividend", &"flock_dividend", &"flock_dividend"],
					"directive": &"record_harvest",
					"expected_success": false,
					"expected_unmet_metrics": [
						"quota_met_shifts",
						"crack_rate_basis_points",
						"compliance_average",
					],
				},
			],
		},
	]
	# The three authored replay dockets must not turn the difficult assurance-to-
	# Gold ladder into incident-order roulette. Clone the complete public strategy
	# so every seed retains its own probation and Senior incident stream.
	var assurance_template := (routes[0] as Dictionary).duplicate(true)
	for docket_seed in REPLAY_DOCKET_SEEDS:
		var replay_route := assurance_template.duplicate(true)
		replay_route["id"] = StringName("assurance_books_docket_%d" % docket_seed)
		replay_route["campaign_seed"] = docket_seed
		routes.append(replay_route)
	var successful_books: Dictionary = {}
	var failed_controls := 0
	for route_value in routes:
		var route := route_value as Dictionary
		var receipts := _run_board_book_route(route, failures)
		for receipt_value in receipts:
			var receipt := receipt_value as Dictionary
			var settlement := receipt.get("settlement", {}) as Dictionary
			var progress := settlement.get("progress", {}) as Dictionary
			var expected_success := bool(receipt.get("expected_success", true))
			print("BOARD_BOOK_STRATEGY_MATRIX %s" % JSON.stringify({
				"route": String(route.get("id", "")),
				"career_seed": int(route.get("campaign_seed", CAMPAIGN_SEED)),
				"year": int(receipt.get("year", 0)),
				"mandate": String(settlement.get("mandate_id", "")),
				"success": bool(settlement.get("success", false)),
				"aggregate": progress.get("aggregate", {}),
				"objectives": progress.get("objectives", []),
			}))
			var actual_success := bool(settlement.get("success", false))
			_check(
				actual_success == expected_success,
				"%s year %d must %s %s through its disclosed strategy; aggregate=%s" % [
					String(route.get("id", "")),
					int(receipt.get("year", 0)),
					"complete" if expected_success else "fail",
					String(settlement.get("mandate_id", "")),
					JSON.stringify(progress.get("aggregate", {})),
				],
				failures,
			)
			if actual_success:
				successful_books[String(settlement.get("mandate_id", ""))] = true
				var mandate_id := String(settlement.get("mandate_id", ""))
				var route_id := String(route.get("id", ""))
				var aggregate := progress.get("aggregate", {}) as Dictionary
				if mandate_id == "mutual_assurance" and route_id.begins_with("assurance_books"):
					_check(
						int(aggregate.get("quota_met_shifts", 0)) >= 9
						and int(aggregate.get("crack_rate_basis_points", 10_000)) <= 1400
						and int(aggregate.get("compliance_average", 0)) >= 90,
						"%s must retain a real advanced-assurance margin across its authored docket" % route_id,
						failures,
					)
				elif mandate_id == "gold_standard_book" and route_id.begins_with("assurance_books"):
					_check(
						int(aggregate.get("quota_met_shifts", 0)) == 12
						and int(aggregate.get("crack_rate_basis_points", 10_000)) <= 900
						and int(aggregate.get("welfare_average", 0)) >= 75
						and int(aggregate.get("compliance_average", 0)) >= 90,
						"%s must retain a real Gold margin across its authored docket" % route_id,
						failures,
					)
			elif not expected_success:
				failed_controls += 1
				_check(
					int(settlement.get("stake_forfeited", 0))
					== int(settlement.get("stake_marks", -1)),
					"%s must forfeit its complete disclosed stake" % route.get("id", ""),
					failures,
				)
				var unmet_metrics: Dictionary = {}
				for objective_value in progress.get("objectives", []) as Array:
					var objective := objective_value as Dictionary
					if not bool(objective.get("met", false)):
						unmet_metrics[String(objective.get("metric", ""))] = true
				for metric_value in receipt.get("expected_unmet_metrics", []) as Array:
					_check(
						unmet_metrics.has(String(metric_value)),
						"%s must preserve the intended unprepared Gold failure on %s" % [
							route.get("id", ""),
							metric_value,
						],
						failures,
					)
	_check(
		successful_books.size() == SeniorRoostState.MANDATE_IDS.size(),
		"the authentic matrix must prove a successful strategy for all seven Board Books",
		failures,
	)
	_check(failed_controls == 1, "the authentic matrix must retain one unprepared Gold failure", failures)


func _run_board_book_route(route: Dictionary, failures: Array[String]) -> Array[Dictionary]:
	var profile_id := StringName(route.get("probation_profile", &"assurance_doctrine"))
	var campaign_seed := int(route.get("campaign_seed", CAMPAIGN_SEED))
	var probation := _run_profile(
		profile_id,
		failures,
		CampaignState.CHALLENGE_STANDARD_FILING,
		campaign_seed,
		true,
	)
	var final := probation.get("final", {}) as Dictionary
	_check(bool(final.get("passed", false)), "%s must earn Senior Roost entry" % profile_id, failures)
	var simulation := probation.get("_simulation") as DepartmentSimulation
	var senior := SeniorRoostState.new()
	var probation_ledgers := probation.get("daily_ledgers", []) as Array
	var last_probation_day := int((probation_ledgers.back() as Dictionary).get("day", 0))
	_check(
		senior.begin(last_probation_day, simulation.full_closing_snapshot()),
		"%s must initialize a Senior Roost ledger" % profile_id,
		failures,
	)
	var egg_observation := {"count": 0, "deliveries": []}
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
	var first_clutch := {"resolved": true, "choice_id": "", "accepted": true}
	var receipts: Array[Dictionary] = []
	var years := route.get("years", []) as Array
	for year_index in years.size():
		var year_plan := years[year_index] as Dictionary
		var mandate_id := StringName(year_plan.get("mandate", &"standard_board_book"))
		var selection := senior.select_annual_mandate(mandate_id, year_index + 1)
		_check(
			bool(selection.get("accepted", false)),
			"%s year %d must be able to file %s" % [profile_id, year_index + 1, mandate_id],
			failures,
		)
		if not bool(selection.get("accepted", false)):
			break
		var policies := year_plan.get("policies", []) as Array
		_check(policies.size() == 4, "%s needs four quarterly policies" % mandate_id, failures)
		for quarter_index in 4:
			var policy_id := StringName(policies[quarter_index])
			var policy_receipt := simulation.apply_senior_quarter_policy(policy_id)
			_check(
				bool(policy_receipt.get("accepted", false)),
				"%s Y%d Q%d policy %s must be affordable and accepted: %s" % [
					profile_id,
					year_index + 1,
					quarter_index + 1,
					policy_id,
					String(policy_receipt.get("reason", "")),
				],
				failures,
			)
			_check(
				senior.record_quarter_policy(policy_receipt),
				"%s Y%d Q%d policy receipt must enter Senior Roost" % [profile_id, year_index + 1, quarter_index + 1],
				failures,
			)
			for _shift_in_quarter in 3:
				var decision_profile_id := StringName(year_plan.get("decision_profile", profile_id))
				_check(
					simulation.begin_next_shift_briefing(),
					"%s must release the next Senior briefing" % profile_id,
					failures,
				)
				for worker in simulation.workers:
					if worker.employed:
						simulation.set_worker_at_workstation(worker.id, true)
				var directive_id := StringName(year_plan.get("directive", &"shell_assurance"))
				_check(
					simulation.select_directive(directive_id),
					"%s Senior day %d must authorize %s" % [profile_id, simulation.day, directive_id],
					failures,
				)
				var shift_result := _complete_authoritative_shift(
					simulation,
					decision_profile_id,
					_profile(profile_id),
					egg_observation,
					first_clutch,
					failures,
				)
				var report := shift_result.get("report", {}) as Dictionary
				var filing := senior.record_shift(report)
				_check(
					bool(filing.get("accepted", false)),
					"%s Senior day %d must file into the annual ledger" % [profile_id, simulation.day],
					failures,
				)
				_resolve_closing_decision(simulation, decision_profile_id, failures)
				_resolve_harvest_credit(simulation, decision_profile_id, failures)
				_purchase_strategy_upgrade(simulation, _profile(profile_id))
				_advance_senior_capital_plan(simulation, year_plan, profile_id, failures)
		var annual := senior.last_annual_review.duplicate(true)
		_check_senior_capital_targets(simulation, year_plan, profile_id, failures)
		receipts.append({
			"year": year_index + 1,
			"expected_success": bool(year_plan.get("expected_success", true)),
			"expected_unmet_metrics": (year_plan.get("expected_unmet_metrics", []) as Array).duplicate(),
			"settlement": (annual.get("mandate_settlement", {}) as Dictionary).duplicate(true),
			"capital": {
				"staff": simulation.active_worker_count(),
				"capacity": simulation.office_capacity,
				"peckwork_tools": simulation.upgrade_level(&"peckwork_tools"),
				"shell_lamp": simulation.upgrade_level(&"shell_lamp"),
				"nest_cushion": simulation.upgrade_level(&"nest_cushion"),
				"candling_rework_bay": simulation.facility_level(&"candling_rework_bay"),
				"wellness_nest_room": simulation.facility_level(&"wellness_nest_room"),
			},
		})
		if year_index + 1 < years.size():
			var transition := simulation.apply_senior_year_transition(bool(annual.get("passed", false)))
			_check(bool(transition.get("accepted", false)), "%s annual transition must apply" % profile_id, failures)
			_check(senior.continue_after_annual(simulation.full_closing_snapshot()), "%s must open the next Senior year" % profile_id, failures)
	return receipts


func _advance_senior_capital_plan(
	simulation: DepartmentSimulation,
	year_plan: Dictionary,
	profile_id: StringName,
	failures: Array[String],
) -> void:
	## Gold Standard is the career capstone, so its proof must use the same
	## permanent office investments available to a player rather than relaxed
	## targets or injected worker stats. Purchases occur only during real reviews.
	var targets := year_plan.get("capital_targets", {}) as Dictionary
	if targets.is_empty():
		return
	var upgrade_targets := targets.get("upgrades", {}) as Dictionary
	for upgrade_key in upgrade_targets.keys():
		var upgrade_id := StringName(String(upgrade_key))
		var target_level := int(upgrade_targets[upgrade_key])
		while simulation.upgrade_level(upgrade_id) < target_level:
			var cost := simulation.upgrade_cost_cents(upgrade_id)
			if cost < 0 or cost > simulation.spendable_fund_cents():
				break
			_check(
				simulation.purchase_upgrade(upgrade_id),
				"%s capital plan must purchase %s level %d" % [
					profile_id,
					upgrade_id,
					simulation.upgrade_level(upgrade_id) + 1,
				],
				failures,
			)
	var facility_targets := targets.get("facilities", {}) as Dictionary
	for facility_key in facility_targets.keys():
		var facility_id := StringName(String(facility_key))
		var target_level := int(facility_targets[facility_key])
		while simulation.facility_level(facility_id) < target_level:
			var status := simulation.facility_status(facility_id)
			if not bool(status.get("can_purchase", false)):
				break
			var receipt := simulation.purchase_facility(facility_id)
			_check(
				bool(receipt.get("accepted", false)),
				"%s capital plan must commission %s" % [profile_id, facility_id],
				failures,
			)
	var staff_target := clampi(int(targets.get("staff", 0)), 0, 6)
	if simulation.office_capacity < staff_target:
		var capacity_receipt := simulation.purchase_staff_capacity()
		_check(
			bool(capacity_receipt.get("accepted", false)),
			"%s capital plan must authorize its next Gold workstation" % profile_id,
			failures,
		)
	if simulation.active_worker_count() < staff_target:
		for worker_value in simulation.staffing_catalog():
			var worker := worker_value as Dictionary
			if not bool(worker.get("can_hire", false)):
				continue
			var hire := simulation.hire_worker(int(worker.get("id", -1)))
			_check(
				bool(hire.get("accepted", false)),
				"%s capital plan must hire an authorized Gold workstation" % profile_id,
				failures,
			)
			break


func _check_senior_capital_targets(
	simulation: DepartmentSimulation,
	year_plan: Dictionary,
	profile_id: StringName,
	failures: Array[String],
) -> void:
	var targets := year_plan.get("capital_targets", {}) as Dictionary
	if targets.is_empty():
		return
	_check(
		simulation.active_worker_count() >= int(targets.get("staff", 0)),
		"%s must finish the preparation year with its planned Gold staffing" % profile_id,
		failures,
	)
	for upgrade_key in (targets.get("upgrades", {}) as Dictionary).keys():
		_check(
			simulation.upgrade_level(StringName(String(upgrade_key)))
			>= int((targets.get("upgrades", {}) as Dictionary)[upgrade_key]),
			"%s must finish the preparation year with %s at its planned level" % [
				profile_id,
				upgrade_key,
			],
			failures,
		)
	for facility_key in (targets.get("facilities", {}) as Dictionary).keys():
		_check(
			simulation.facility_level(StringName(String(facility_key)))
			>= int((targets.get("facilities", {}) as Dictionary)[facility_key]),
			"%s must finish the preparation year with %s commissioned" % [
				profile_id,
				facility_key,
			],
			failures,
		)


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
	if profile_id == &"senior_executive":
		var desired_by_incident := {
			&"wellness_request": &"grant_breaks",
			&"farmer_story": &"polish_story",
			&"flock_petition": &"deny_and_monitor",
			&"ledger_molt": &"patch",
			&"feed_shortfall": &"buy_grain",
		}
		var desired := StringName(desired_by_incident.get(
			StringName(pending.get("id", &"")),
			&"",
		))
		for option_value in options:
			var option := option_value as Dictionary
			if (
				StringName(option.get("id", &"")) == desired
				and int(option.get("cost_cents", 0)) <= simulation.spendable_fund_cents()
			):
				_check(
					simulation.resolve_decision(int(pending.get("serial", -1)), desired),
					"senior executive incident choice %s must resolve authoritatively" % desired,
					failures,
				)
				return desired
	var preferred_tones: Array[StringName] = []
	var paid_choices_allowed := false
	match profile_id:
		&"stewardship_doctrine", &"guided_no_micro":
			preferred_tones.assign([&"care", &"quality", &"danger"])
			paid_choices_allowed = true
		&"assurance_doctrine", &"harvest_doctrine", &"senior_executive":
			preferred_tones.assign([&"quality", &"care", &"danger"])
			paid_choices_allowed = true
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
	var desired := _closing_choice(
		profile_id,
		decision_id,
		int(pending.get("completed_day", simulation.day)),
	)
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
) -> String:
	var gallery := simulation.farmer_relations_gallery_snapshot()
	if StringName(gallery.get("campaign_status", &"")) != &"offer_open":
		return ""
	var campaign_id: StringName = &""
	match profile_id:
		&"stewardship_doctrine":
			campaign_id = &"clutch_results_board"
		&"assurance_doctrine":
			campaign_id = &"layer_profile"
		&"harvest_doctrine":
			campaign_id = &"farmer_method"
		&"senior_executive":
			campaign_id = &"farmer_method"
		&"quality_first":
			campaign_id = &"layer_profile"
		&"welfare_first":
			campaign_id = &"clutch_results_board"
		&"ruthless":
			campaign_id = &"farmer_method"
	if campaign_id == &"":
		var skipped := simulation.skip_farmer_relations_campaign()
		_check(bool(skipped.get("accepted", false)), "%s must release the optional publicity gate" % profile_id, failures)
		return "skip" if bool(skipped.get("accepted", false)) else ""
	var filed := simulation.file_farmer_relations_campaign(campaign_id)
	if bool(filed.get("accepted", false)):
		return String(campaign_id)
	var skipped := simulation.skip_farmer_relations_campaign()
	_check(bool(skipped.get("accepted", false)), "%s must release an unavailable publicity offer" % profile_id, failures)
	return "skip" if bool(skipped.get("accepted", false)) else ""


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


func _personnel_worker_for_day(profile: Dictionary, target_day: int) -> int:
	var schedule := profile.get("personnel_worker_schedule", []) as Array
	if target_day > 0 and target_day <= schedule.size():
		return int(schedule[target_day - 1])
	return int(profile.get("personnel_worker_id", 0))


func _profile(profile_id: StringName) -> Dictionary:
	match profile_id:
		&"guided_no_micro":
			return {
				"directive_schedule": [
					&"sustainable_flock",
					&"sustainable_flock",
					&"shell_assurance",
					&"sustainable_flock",
					&"sustainable_flock",
				],
				"milestone": &"padded_perches",
				"personnel_action": &"",
				"upgrade": &"",
				"peck_assist": false,
				"overtime": false,
				"skip_first_clutch": true,
			}
		&"stewardship_doctrine":
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
					&"career_coaching",
				],
				"personnel_worker_schedule": [0, 3, 1, 0, 3],
				"upgrade": &"nest_cushion",
				"peck_assist": true,
				"overtime": false,
			}
		&"assurance_doctrine":
			return {
				"directive_schedule": [
					&"shell_assurance",
					&"sustainable_flock",
					&"shell_assurance",
					&"sustainable_flock",
					&"sustainable_flock",
				],
				"milestone": &"shell_quality_lab",
				"personnel_schedule": [
					&"share_credit",
					&"share_credit",
					&"career_coaching",
					&"share_credit",
					&"share_credit",
				],
				"personnel_worker_schedule": [0, 3, 1, 0, 3],
				"upgrade": &"nest_cushion",
				"peck_assist": true,
				"overtime": false,
			}
		&"harvest_doctrine":
			return {
				"directive_schedule": [
					&"sustainable_flock",
					&"record_harvest",
					&"sustainable_flock",
					&"shell_assurance",
					&"sustainable_flock",
				],
				"milestone": &"farmer_credit_line",
				"personnel_schedule": [
					&"share_credit",
					&"career_coaching",
					&"share_credit",
					&"share_credit",
					&"share_credit",
				],
				"personnel_worker_schedule": [0, 1, 3, 2, 0],
				"upgrade": &"peckwork_tools",
				"peck_assist": true,
				"overtime": false,
			}
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
		&"stewardship_doctrine", &"assurance_doctrine", &"harvest_doctrine":
			return &"shell_lamp"
		&"quality_first", &"steward_hybrid", &"balanced_hybrid":
			return &"shell_lamp"
		&"ruthless":
			return &"peckwork_tools"
	return &"bank_fund"


func _closing_choice(
	profile_id: StringName,
	decision_id: StringName,
	_decision_day: int = 0,
) -> StringName:
	match decision_id:
		&"golden_egg_dossier":
			match profile_id:
				&"welfare_first", &"assurance_doctrine":
					return &"flock_owned_patent"
				&"ruthless", &"passive", &"senior_executive":
					return &"patent_rooster_method"
			return &"name_the_layer"
		&"flock_restructuring":
			match profile_id:
				&"welfare_first":
					return &"contest_ranking"
				&"ruthless", &"passive", &"senior_executive":
					return &"nominate_variance"
			return &"fund_redeployment"
	match profile_id:
		&"welfare_first", &"steward_hybrid", &"assurance_doctrine", &"harvest_doctrine":
			return &"share_feed_credit"
		&"ruthless", &"passive", &"senior_executive":
			return &"claim_management_innovation"
	return &"reward_top_layer"


func _first_affordable_day(ledgers: Array[Dictionary], key: String) -> int:
	for ledger in ledgers:
		if not (ledger.get(key, []) as Array).is_empty():
			return int(ledger.get("day", 0))
	return 0


func _all_criteria_pass(final: Dictionary) -> bool:
	var criteria := final.get("criteria", {}) as Dictionary
	var expected := ["score", "welfare", "compliance", "farmer_favor", "shell_quality"]
	if criteria.size() != expected.size():
		return false
	for criterion in expected:
		if not bool(criteria.get(criterion, false)):
			return false
	return true


func _all_intended_personnel_actions_accepted(result: Dictionary) -> bool:
	var receipts := result.get("personnel_receipts", []) as Array
	if receipts.is_empty():
		return false
	for receipt_value in receipts:
		var receipt := receipt_value as Dictionary
		if not bool(receipt.get("accepted", false)):
			return false
	return true


func _has_accepted_upgrade(result: Dictionary, upgrade_id: StringName) -> bool:
	for purchase_value in result.get("upgrade_history", []) as Array:
		if String(purchase_value).ends_with(":" + String(upgrade_id)):
			return true
	return false


func _doctrine_vectors_are_materially_distinct(results: Array[Dictionary]) -> bool:
	if results.size() != VIABLE_DOCTRINES.size():
		return false
	var thresholds := {
		"probation_score": 1,
		"average_welfare": 2,
		"average_compliance": 2,
		"average_farmer_favor": 2,
		"crack_rate_basis_points": 50,
		"closing_fund_cents": 1000,
		"total_eggs": 3,
	}
	for first_index in results.size():
		for second_index in range(first_index + 1, results.size()):
			var first := _doctrine_outcome_vector(results[first_index])
			var second := _doctrine_outcome_vector(results[second_index])
			var material_axes := 0
			for metric in thresholds:
				if abs(int(first[metric]) - int(second[metric])) >= int(thresholds[metric]):
					material_axes += 1
			if material_axes < 2:
				return false
	return true


func _doctrine_outcome_vector(result: Dictionary) -> Dictionary:
	var final := result.get("final", {}) as Dictionary
	return {
		"probation_score": int(final.get("probation_score", 0)),
		"average_welfare": int(final.get("average_welfare", 0)),
		"average_compliance": int(final.get("average_compliance", 0)),
		"average_farmer_favor": int(final.get("average_farmer_favor", 0)),
		"crack_rate_basis_points": int(final.get("crack_rate_basis_points", 0)),
		"closing_fund_cents": int(result.get("closing_fund_cents", 0)),
		"total_eggs": int(result.get("total_eggs", 0)),
	}


func _doctrine_route_tradeoffs_are_legible(results: Dictionary) -> bool:
	var stewardship := results.get("stewardship_doctrine", {}) as Dictionary
	var assurance := results.get("assurance_doctrine", {}) as Dictionary
	var harvest := results.get("harvest_doctrine", {}) as Dictionary
	var stewardship_final := stewardship.get("final", {}) as Dictionary
	var assurance_final := assurance.get("final", {}) as Dictionary
	var harvest_final := harvest.get("final", {}) as Dictionary
	return (
		int(stewardship_final.get("average_welfare", 0))
			> int(assurance_final.get("average_welfare", 0))
		and int(stewardship_final.get("average_farmer_favor", 0))
			> int(assurance_final.get("average_farmer_favor", 0))
		and int(assurance_final.get("average_compliance", 0))
			> int(stewardship_final.get("average_compliance", 0))
		and int(assurance_final.get("average_compliance", 0))
			> int(harvest_final.get("average_compliance", 0))
		and int(harvest_final.get("probation_score", 0))
			> int(stewardship_final.get("probation_score", 0))
		and int(harvest.get("total_eggs", 0)) > int(stewardship.get("total_eggs", 0))
		and int(harvest.get("total_eggs", 0)) > int(assurance.get("total_eggs", 0))
		and int(harvest.get("closing_fund_cents", 0))
			> int(stewardship.get("closing_fund_cents", 0))
		and int(harvest.get("closing_fund_cents", 0))
			> int(assurance.get("closing_fund_cents", 0))
	)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
