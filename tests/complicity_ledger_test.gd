extends SceneTree

const LedgerScript := preload("res://core/experience/complicity_ledger.gd")
const SimulationScript := preload("res://core/simulation/department_simulation.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []

	var empty := LedgerScript.compose([])
	_check(empty["id"] == &"unfiled" and int(empty["total"]) == 0, "an empty file has no verdict", failures)

	var company := LedgerScript.compose([
		{"source": "incident", "label": "BADGE SCAN", "side": &"company", "day": 1},
		{"source": "credit", "label": "CREDIT MEMO", "side": &"company", "day": 1},
		{"source": "incident", "label": "WELLNESS", "side": &"flock", "day": 2},
		{"source": "restructuring", "label": "RESTRUCTURING", "side": &"company", "weight": 2, "day": 4},
	])
	_check(
		company["id"] == &"company_bird" and int(company["company"]) == 4 and int(company["flock"]) == 1,
		"weighted company choices should read as COMPANY BIRD",
		failures,
	)
	_check((company["receipts"] as Array).size() == 4, "every act keeps a receipt", failures)

	var close := LedgerScript.compose([
		{"source": "incident", "label": "A", "side": &"company"},
		{"source": "incident", "label": "B", "side": &"flock"},
		{"source": "incident", "label": "C", "side": &"flock"},
	])
	_check(close["id"] == &"both_ledgers", "a one-choice lead is not yet a settled direction", failures)

	var flock := LedgerScript.compose([
		{"source": "petition", "label": "PETITION", "side": &"flock"},
		{"source": "incident", "label": "B", "side": &"flock"},
		{"source": "incident", "label": "C", "side": &"neutral"},
	])
	_check(
		flock["id"] == &"flock_first" and int(flock["neutral"]) == 1,
		"consistent solidarity should read as FLOCK FIRST and neutral acts stay separate",
		failures,
	)

	_check(
		LedgerScript.witness_stake(&"danger", "Mabel") == "MABEL PAYS FOR THIS"
		and LedgerScript.witness_stake(&"care", "Mabel") == "COVERS FOR MABEL"
		and LedgerScript.witness_stake(&"quality", "Mabel").is_empty(),
		"the card stake names the hen only when a side is taken",
		failures,
	)

	# Every authored incident response must classify, so no choice silently
	# falls outside the ledger.
	for incident_id: StringName in SimulationScript.INCIDENT_DEFINITIONS:
		var definition := SimulationScript.INCIDENT_DEFINITIONS[incident_id] as Dictionary
		for choice: Dictionary in definition.get("choices", []):
			var tone := StringName(choice.get("tone", &""))
			_check(
				LedgerScript.INCIDENT_TONE_SIDES.has(tone),
				"%s/%s has unclassified tone %s" % [incident_id, choice.get("id", ""), tone],
				failures,
			)

	# Live simulation: the ledger is derived from already-persisted records.
	var simulation := SimulationScript.new(42) as DepartmentSimulation
	var fresh := simulation.complicity_ledger_snapshot()
	_check(fresh["id"] == &"unfiled", "a new file starts with an empty ledger", failures)
	simulation.credit_choice_counts[&"management_innovation"] = 2
	simulation.credit_choice_counts[&"shared_scoop"] = 0
	var after_memos := simulation.complicity_ledger_snapshot()
	_check(
		int(after_memos["company"]) == 2 and after_memos["id"] == &"company_bird",
		"closing credit memos claimed for management count for the company",
		failures,
	)
	var ending := simulation.campaign_ending_snapshot(true)
	_check(
		(ending.get("ledger", {}) as Dictionary).get("id", &"") == &"company_bird",
		"the campaign ending carries the ledger verdict",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("COMPLICITY_LEDGER_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("COMPLICITY_LEDGER_TEST_PASSED")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
