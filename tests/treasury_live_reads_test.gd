extends SceneTree

class CountingTreasury extends FarmTreasuryState:
	var snapshot_reads := 0

	func snapshot(standing_points: int = 0) -> Dictionary:
		snapshot_reads += 1
		return super.snapshot(standing_points)

var failures: Array[String] = []

func check(condition: bool, reason: String) -> void:
	if not condition:
		failures.append(reason)

func _init() -> void:
	var sim := DepartmentSimulation.new(20261114, 4)
	var treasury := CountingTreasury.new()
	sim._farm_treasury = treasury
	# Compare against the complete public report across credit boundaries and
	# immediate state changes; no tick/cache invalidation may be required.
	for rating in [0, 1, 2]:
		treasury.credit_rating = rating
		for standing in [0, 1, 19, 20, 100]:
			var limit := treasury.credit_limit_cents(standing)
			for principal in [0, limit - 1, limit, limit + 1]:
				treasury.credit_principal_cents = principal
				for arrears in [0, 125]:
					treasury.vendor_arrears_cents = arrears
					treasury.interest_arrears_cents = arrears * 2
					var full := treasury.snapshot(standing)
					check(treasury.total_liabilities_cents() == full.total_liabilities_cents, "Scalar debt must match the complete report")
					check(treasury.credit_headroom_cents(standing) == full.credit_headroom_cents, "Scalar headroom must match at every standing/rating boundary")
					check_live_reads(sim, treasury)
	# Use actual conserved receipts to prove cost no longer depends on the
	# campaign archive, and that public/save copies retain their isolation.
	treasury = CountingTreasury.new()
	sim._farm_treasury = treasury
	for day in range(1, 36):
		var receipt := treasury.close_shift(day, 0, {"eggs": 3000}, {"feed": 1200}, 800)
		check(receipt.accepted, "History fixture must use accepted real closes")
	var archive := treasury.to_save_data()
	check(archive.history.size() == FarmTreasuryState.HISTORY_LIMIT, "Fixture must fill the complete bounded archive")
	for repeat in 10:
		check_live_reads(sim, treasury)
	check(treasury.to_save_data() == archive, "Live reads must preserve every filed receipt")
	var isolated := sim.farm_treasury_snapshot()
	isolated.history[0].income_breakdown.clear()
	isolated.last_receipt.clear()
	check(treasury.to_save_data() == archive, "Complete report must still return isolated receipt copies")
	var restored := CountingTreasury.new()
	check(restored.restore_save_data(JSON.parse_string(JSON.stringify(archive))), "Full archive must round-trip through JSON")
	sim._farm_treasury = restored
	check_live_reads(sim, restored)
	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		quit(1)
		return
	print("TREASURY_LIVE_READS_TEST_PASSED boundaries=fresh affordability=exact archive=32 isolated=true full_report_reads=0")
	quit(0)

func check_live_reads(sim: DepartmentSimulation, treasury: CountingTreasury) -> void:
	var report := sim.farm_treasury_snapshot()
	var expected_debt := maxi(0, int(report.total_liabilities_cents))
	var expected_reserve := sim.current_daily_operating_cost_cents() + sim.wage_arrears_cents + sim.current_market_contract_reserve_cents() + expected_debt
	var before_reads := treasury.snapshot_reads
	for cash in [-1, 0, expected_reserve, expected_reserve + 1, 100000]:
		sim.revenue_cents = cash
		check(sim.farm_treasury_liabilities_cents() == expected_debt, "Live liabilities must match the report")
		check(sim.farm_treasury_capital_frozen() == bool(report.capital_frozen), "Live freeze must match the report immediately")
		check(sim.protected_reserve_cents() == expected_reserve, "Reserve must protect every current obligation")
		var expected_spendable := 0 if bool(report.capital_frozen) else maxi(0, cash - expected_reserve)
		check(sim.spendable_fund_cents() == expected_spendable, "Affordability must preserve exact cents and credit freeze")
	check(treasury.snapshot_reads == before_reads, "Live economic checks must not construct or copy the receipt archive")
