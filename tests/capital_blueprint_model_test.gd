extends SceneTree

const CapitalBlueprintModelScript := preload("res://features/office/capital_blueprint_model.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var model := CapitalBlueprintModelScript.new() as CapitalBlueprintModel
	var snapshot := _snapshot()
	model.apply_snapshot(snapshot)

	_check(model.has_complete_catalog(), "the complete authoritative 13-facility catalog should be recognized", failures)
	_check(model.stable_facility_ids() == CapitalBlueprintModel.FACILITY_ORDER, "stable facility order should match the authored capital schedule", failures)
	_check(_facility_ids(model.facilities()) == CapitalBlueprintModel.FACILITY_ORDER, "ALL should preserve stable authored order", failures)
	_check(model.categories().size() == 3, "blueprint should expose exactly three legible office zones", failures)
	_check(_category_ids(model, &"production").size() == 4, "Production should contain Candling, Packing, Records, and Farmgate", failures)
	_check(_category_ids(model, &"flock").size() == 3, "Flock should contain Wellness, Training, and Relations", failures)
	_check(_category_ids(model, &"governance").size() == 6, "Governance should contain Service, Negotiation, Rooster, IT, Provisions, and Gallery", failures)

	var counts := model.filter_counts()
	_check(int(counts.get(&"all", 0)) == 13, "ALL count should be 13", failures)
	_check(int(counts.get(&"ready", 0)) == 2, "READY should use authoritative can_purchase only", failures)
	_check(int(counts.get(&"owned", 0)) == 2, "OWNED should include installed facilities even when an upgrade is held", failures)
	_check(int(counts.get(&"blocked", 0)) == 10, "BLOCKED should exclude ready and fully commissioned facilities", failures)
	_check(
		_facility_ids(model.facilities(&"ready")) == [&"candling_rework_bay", &"training_roost"],
		"READY filtering should retain stable schedule order",
		failures,
	)
	_check(
		_facility_ids(model.facilities(&"owned")) == [&"farmer_brand_packing_annex", &"records_annex"],
		"OWNED should show both an installed upgrade path and a maxed facility",
		failures,
	)
	_check(
		&"farmer_brand_packing_annex" in _facility_ids(model.facilities(&"blocked")),
		"an installed but currently held upgrade should remain visible under BLOCKED",
		failures,
	)

	_check(model.pinned_facility_id() == &"farmer_brand_packing_annex", "capital_plan.pinned_capital_plan_id should be authoritative", failures)
	var pinned := model.facility(&"farmer_brand_packing_annex")
	_check(bool(pinned.get("pinned", false)), "the canonical pinned parcel should carry visible plan state", failures)
	var ready := model.facility(&"candling_rework_bay")
	_check(int(ready.get("capital_cost_cents", 0)) == 12_000, "capital cost should be copied exactly", failures)
	_check(int(ready.get("maintenance_delta_cents", 0)) == 500, "maintenance delta should be copied exactly", failures)
	_check(int(ready.get("supervisor_payroll_delta_cents", 0)) == 250, "payroll delta should be copied exactly", failures)
	_check(int(ready.get("projected_spendable_fund_cents", 0)) == 8_000, "post-build spendable fund should be copied exactly", failures)
	_check(int(ready.get("projected_protected_reserve_cents", 0)) == 3_800, "post-build protected reserve should be copied exactly", failures)
	_check(String(ready.get("why_now", "")) == "Shell losses are holding the current review.", "WHY NOW should preserve authored copy", failures)
	_check((ready.get("benefit_lines", []) as Array).size() == 2, "YOU GET should preserve every authored effect line", failures)
	_check((ready.get("tradeoff_lines", []) as Array).size() == 1, "YOU OWE should preserve authored tradeoffs", failures)
	_check((ready.get("gate_lines", []) as Array).size() == 1, "GATES should preserve exact authored conditions", failures)

	var receipt := model.last_purchase_receipt()
	_check(StringName(receipt.get("facility_id", &"")) == &"records_annex", "last purchase receipt should be exposed without reinterpretation", failures)
	receipt["facility_id"] = &"mutated"
	_check(StringName(model.last_purchase_receipt().get("facility_id", &"")) == &"records_annex", "returned receipts should be defensive copies", failures)
	ready["capital_cost_cents"] = 1
	_check(int(model.facility(&"candling_rework_bay").get("capital_cost_cents", 0)) == 12_000, "returned facility records should be defensive copies", failures)
	(snapshot["facility_catalog"] as Array)[0]["cost_cents"] = 2
	_check(int(model.facility(&"candling_rework_bay").get("capital_cost_cents", 0)) == 12_000, "the model should not retain mutable snapshot aliases", failures)

	model.apply_snapshot({"facility_catalog": [_facility_record(&"candling_rework_bay", 0)]})
	_check(not model.has_complete_catalog(), "an incomplete catalog should remain visibly incomplete instead of inventing facilities", failures)
	_check(model.facilities().size() == 1, "missing authoritative catalog entries should not be fabricated", failures)

	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAPITAL_BLUEPRINT_MODEL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAPITAL_BLUEPRINT_MODEL_TEST_PASSED catalog=13 zones=4+3+6 filters=authoritative copies=defensive")
	quit(0)


func _snapshot() -> Dictionary:
	var catalog: Array[Dictionary] = []
	for facility_id: StringName in CapitalBlueprintModel.FACILITY_ORDER:
		catalog.append(_facility_record(facility_id, catalog.size()))
	return {
		"facility_catalog": catalog,
		"capital_plan": {
			"has_pinned_plan": true,
			"pinned_capital_plan_id": &"farmer_brand_packing_annex",
		},
		"last_facility_purchase_receipt": {
			"accepted": true,
			"facility_id": &"records_annex",
			"cost_cents": 9000,
		},
	}


func _facility_record(facility_id: StringName, index: int) -> Dictionary:
	var level := 0
	var max_level := 3
	var maxed := false
	var can_purchase := facility_id in [&"candling_rework_bay", &"training_roost"]
	if facility_id == &"farmer_brand_packing_annex":
		level = 1
	if facility_id == &"records_annex":
		level = 3
		maxed = true
	return {
		"id": facility_id,
		"name": String(facility_id).replace("_", " ").capitalize(),
		"short_name": "PARCEL %02d" % (index + 1),
		"level": level,
		"next_level": mini(max_level, level + 1),
		"max_level": max_level,
		"owned": level > 0,
		"installed": level > 0,
		"maxed": maxed,
		"can_purchase": can_purchase,
		"purchase_label": "AUTHORIZE PARCEL %02d" % (index + 1),
		"reason": "Await the exact authored capital gate.",
		"why_now": "Shell losses are holding the current review." if facility_id == &"candling_rework_bay" else "Await the exact authored capital gate.",
		"benefits": ["Reduce cracked egg losses.", "Raise sound-egg claim value."],
		"tradeoffs": ["Adds one recurring cleaning file."],
		"gates": ["Farmer review must be open."],
		"cost_cents": 12_000 + index * 100,
		"maintenance_delta_cents": 500,
		"supervisor_payroll_delta_cents": 250,
		"projected_spendable_fund_cents": 8_000,
		"projected_protected_reserve_cents": 3_800,
	}


func _facility_ids(entries: Array[Dictionary]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in entries:
		ids.append(StringName(String(entry.get("id", ""))))
	return ids


func _category_ids(model: CapitalBlueprintModel, category_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for category: Dictionary in model.categories():
		if StringName(String(category.get("id", ""))) != category_id:
			continue
		for facility_id: Variant in category.get("facility_ids", []):
			result.append(StringName(String(facility_id)))
	return result


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
