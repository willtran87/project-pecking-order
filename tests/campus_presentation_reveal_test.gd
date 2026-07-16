extends SceneTree

const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")
const DepartmentSimulationScript := preload("res://core/simulation/department_simulation.gd")
const PackingAnnexVisualScript := preload("res://features/office/packing_annex_visual.gd")
const TrainingRoostVisualScript := preload("res://features/office/training_roost_visual.gd")
const ITCoopVisualScript := preload("res://features/office/it_coop_visual.gd")
const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const CampusPortfolioVisualScript := preload("res://features/office/campus_portfolio_visual.gd")

const FACILITY_IDS: Array[StringName] = [
	&"candling_rework_bay",
	&"farmer_brand_packing_annex",
	&"records_annex",
	&"farm_mutual_service_coop",
	&"farm_mutual_negotiation_room",
	&"wellness_nest_room",
	&"training_roost",
	&"rooster_operations_office",
	&"it_coop",
	&"flock_relations_office",
	&"feed_procurement_coop",
	&"farmer_relations_gallery",
	&"farmgate_dispatch_depot",
]

const FUTURE_ROOT_NAMES: Array[String] = [
	"ShellQualityLabVisual",
	"PackingAnnexVisual",
	"RecordsAnnexVisual",
	"FarmMutualServiceCoopVisual",
	"FarmMutualNegotiationRoomVisual",
	"FarmMutualContractBoardVisual",
	"WellnessNestVisual",
	"TrainingRoostVisual",
	"FarmerRelationsGalleryVisual",
	"RoosterOperationsOfficeVisual",
	"ITCoopVisual",
	"FlockRelationsOfficeVisual",
	"FeedProcurementCoopVisual",
	"FarmgateDispatchDepotVisual",
	"CampusExpansionVisual",
	"CampusPortfolioVisual",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var staging := OfficeStorytellingScript.new() as OfficeStorytelling
	root.add_child(staging)
	await process_frame

	_assert_fresh_campaign(staging, failures)
	_assert_authoritative_fresh_campaign(staging, failures)
	_assert_pinned_plan(staging, failures)
	_assert_progressive_spine_bays(staging, failures)
	_assert_single_teaser(staging, failures)
	_assert_offered_and_owned_sites(staging, failures)
	_assert_later_save_reconstruction(staging, failures)

	staging.free()
	await process_frame
	if not failures.is_empty():
		for failure: String in failures:
			push_error("CAMPUS_PRESENTATION_REVEAL_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("CAMPUS_PRESENTATION_REVEAL_TEST_PASSED fresh=compact offered=visible pinned=visible teaser=one later=restored bounds=published")
	quit(0)


func _assert_fresh_campaign(staging: OfficeStorytelling, failures: Array[String]) -> void:
	var fresh := _fresh_snapshot(1)
	var pristine := fresh.duplicate(true)
	var projection := staging.apply_campus_presentation(fresh)
	_check(fresh == pristine, "presentation derivation must not mutate authoritative snapshot data", failures)
	for root_name: String in FUTURE_ROOT_NAMES:
		_check(not _root_visible(staging, root_name), "fresh campaign should hide %s" % root_name, failures)
	_check(not _root_visible(staging, "CareCampusSpine"), "fresh campaign should hide unused Care campus spine", failures)
	_check(not _root_visible(staging, "OperationsCampusSpine"), "fresh campaign should hide unused Operations campus spine", failures)
	_check(not _root_visible(staging, "PortfolioSharedInfrastructure"), "fresh campaign should hide unused portfolio service trunk", failures)
	_check(not _root_visible(staging, "OrchardRowParcel"), "fresh campaign should hide Orchard Row deed geometry", failures)
	_check(not _root_visible(staging, "CreeksideYardParcel"), "fresh campaign should hide Creekside deed geometry", failures)
	_check((projection.get("visible_ids", []) as Array).is_empty(), "fresh campaign should publish no future campus footprint", failures)
	_check((projection.get("visible_footprints", []) as Array).is_empty(), "fresh camera integration should receive no future footprint", failures)
	_check(staging.visible_campus_bounds() == Rect2(), "fresh campus bounds should be empty so Office can frame only its base floor", failures)
	_check(StringName(projection.get("teaser_id", &"")) == &"", "fresh campaign should not tease a future site by default", failures)


func _assert_authoritative_fresh_campaign(staging: OfficeStorytelling, failures: Array[String]) -> void:
	var simulation := DepartmentSimulationScript.new(1701, DepartmentSimulationScript.MINIMUM_STAFF_COUNT) as DepartmentSimulation
	var snapshot := simulation.snapshot()
	_check(int(snapshot.get("day", 0)) == 1, "authoritative fresh simulation fixture should begin on Day 1", failures)
	staging.apply_snapshot(snapshot)
	for root_name: String in FUTURE_ROOT_NAMES:
		_check(not _root_visible(staging, root_name), "production Day 1 snapshot should hide %s" % root_name, failures)
	_check(not _root_visible(staging, "CareCampusSpine"), "production Day 1 snapshot should hide the unused Care campus spine", failures)
	_check(not _root_visible(staging, "OperationsCampusSpine"), "production Day 1 snapshot should hide the unused Operations campus spine", failures)
	_check(not _root_visible(staging, "PortfolioSharedInfrastructure"), "production Day 1 snapshot should hide the unused portfolio service trunk", failures)
	_check(staging.visible_campus_footprints().is_empty(), "production Day 1 snapshot should publish no future campus footprint", failures)
	_check(staging.visible_campus_bounds() == Rect2(), "production Day 1 snapshot should leave campus camera bounds empty", failures)


func _assert_pinned_plan(staging: OfficeStorytelling, failures: Array[String]) -> void:
	var pinned := _fresh_snapshot(1)
	pinned["pinned_capital_plan_id"] = &"training_roost"
	pinned["capital_plan"] = {
		"pinned_capital_plan_id": &"training_roost",
		"has_pinned_plan": true,
	}
	staging.apply_campus_presentation(pinned)
	_check(_root_visible(staging, "TrainingRoostVisual"), "a pinned facility should become physically legible before purchase", failures)
	_check(staging.campus_presentation_state(&"training_roost") == &"pinned", "pinned facility should publish pinned presentation state", failures)
	_check(_root_visible(staging, "CareCampusSpine"), "a pinned care facility should reveal its necessary approach spine", failures)
	_check(_root_visible(staging, "CareCampusFirstBay") and _root_visible(staging, "CareCampusSecondBay"), "a pinned far care bay should reveal both approach segments", failures)
	_check(not _root_visible(staging, "OperationsCampusSpine"), "unrelated Operations spine should remain hidden for a care plan", failures)
	var footprints := staging.visible_campus_footprints()
	_check(TrainingRoostVisualScript.declared_footprint() in footprints, "camera footprint list should include the pinned Training Roost", failures)
	_check(OfficeStorytellingScript.CARE_CAMPUS_SPINE_FOOTPRINT in footprints, "camera footprint list should include the pinned facility's approach", failures)


func _assert_progressive_spine_bays(staging: OfficeStorytelling, failures: Array[String]) -> void:
	var wellness := _fresh_snapshot(3)
	wellness["facility_catalog"] = [
		{"id": &"wellness_nest_room", "level": 0, "unlocked": true, "unlock_day": 3},
	]
	staging.apply_campus_presentation(wellness)
	_check(_root_visible(staging, "CareCampusFirstBay"), "first care offer should extend the approach only to Wellness", failures)
	_check(not _root_visible(staging, "CareCampusSecondBay"), "first care offer should not prebuild the Training and Gallery corridor", failures)
	var care_footprints := staging.visible_campus_footprints()
	_check(OfficeStorytellingScript.CARE_CAMPUS_FIRST_BAY_FOOTPRINT in care_footprints, "camera should receive only the first care approach footprint", failures)
	_check(OfficeStorytellingScript.CARE_CAMPUS_SPINE_FOOTPRINT not in care_footprints, "camera should not frame the unrevealed far care bay", failures)

	var rooster := _fresh_snapshot(5)
	rooster["facility_catalog"] = [
		{"id": &"rooster_operations_office", "level": 0, "unlocked": true, "unlock_day": 5},
	]
	staging.apply_campus_presentation(rooster)
	_check(_root_visible(staging, "OperationsCampusFirstBay"), "first operations offer should reveal its near approach", failures)
	_check(not _root_visible(staging, "OperationsCampusSecondBay"), "first operations offer should not expose the IT and Relations corridor", failures)
	var operations_footprints := staging.visible_campus_footprints()
	_check(OfficeStorytellingScript.OPERATIONS_CAMPUS_FIRST_BAY_FOOTPRINT in operations_footprints, "camera should receive only the first operations approach footprint", failures)
	_check(OfficeStorytellingScript.OPERATIONS_CAMPUS_SPINE_FOOTPRINT not in operations_footprints, "camera should not frame the unrevealed far operations bay", failures)


func _assert_single_teaser(staging: OfficeStorytelling, failures: Array[String]) -> void:
	var day_two := _fresh_snapshot(2)
	var projection := staging.apply_campus_presentation(day_two, {
		"show_next_teaser": true,
		"teaser_window_days": 1,
	})
	_check(StringName(projection.get("teaser_id", &"")) == &"farmer_brand_packing_annex", "the authored order should choose Packing as the sole Day 3 teaser", failures)
	_check(_root_visible(staging, "PackingAnnexVisual"), "selected teaser should reveal its restrained locked marker", failures)
	_check(not _root_visible(staging, "RecordsAnnexVisual"), "a second same-day opportunity must not become another teaser", failures)
	var teased_count := 0
	var entries := projection.get("entries_by_id", {}) as Dictionary
	for entry_value: Variant in entries.values():
		if entry_value is Dictionary and StringName((entry_value as Dictionary).get("state", &"")) == &"teased":
			teased_count += 1
	_check(teased_count == 1, "presentation should publish at most one next teaser", failures)
	day_two["workers"] = []
	day_two["claim_queue_counts"] = {}
	staging.apply_snapshot(day_two)
	_check(staging.campus_presentation_state(&"farmer_brand_packing_annex") == &"teased", "ordinary simulation snapshots should preserve the active presentation options", failures)


func _assert_offered_and_owned_sites(staging: OfficeStorytelling, failures: Array[String]) -> void:
	var snapshot := _fresh_snapshot(6)
	snapshot["owned_facilities"] = {&"it_coop": 2}
	snapshot["facility_catalog"] = [
		{"id": &"farmer_brand_packing_annex", "level": 0, "unlocked": true, "unlock_day": 3},
		{"id": &"it_coop", "level": 2, "owned": true, "unlocked": true, "unlock_day": 9},
	]
	snapshot["campus_expansion"] = {
		"visible": true,
		"unlock_day": 1,
		"access_gate_met": true,
		"parcel_owned": false,
		"parcel": {"id": &"north_meadow", "owned": false, "can_purchase": false},
		"construction_stage": &"access",
	}
	snapshot["campus_portfolio"] = {
		"current_day": 6,
		"parcels": [
			{"id": &"orchard_row", "owned": false, "unlock_day": 6, "can_purchase": false},
			{"id": &"creekside_yard", "owned": false, "unlock_day": 9, "can_purchase": false},
		],
		"projects": [],
		"modules": [],
	}
	staging.apply_campus_presentation(snapshot)
	_check(_root_visible(staging, "PackingAnnexVisual"), "an authoritative unlocked facility should be presented as offered", failures)
	_check(staging.campus_presentation_state(&"farmer_brand_packing_annex") == &"offered", "Packing should publish offered state", failures)
	_check(_root_visible(staging, "ITCoopVisual"), "an owned later facility must remain visible", failures)
	_check(staging.campus_presentation_state(&"it_coop") == &"owned", "owned facility should outrank its later unlock record", failures)
	_check(_root_visible(staging, "OperationsCampusSpine"), "owned IT Coop should reveal the Operations approach spine", failures)
	_check(_root_visible(staging, "CampusExpansionVisual"), "North Meadow should appear once its authoritative access gate is met", failures)
	_check(staging.campus_presentation_state(&"north_meadow") == &"offered", "accessible unowned North Meadow should publish offered state", failures)
	_check(_root_visible(staging, "OrchardRowParcel"), "Day 6 Orchard Row should become an offered deed", failures)
	_check(not _root_visible(staging, "CreeksideYardParcel"), "Day 9 Creekside should remain undiscovered on Day 6", failures)
	_check(not _root_visible(staging, "PortfolioSharedInfrastructure"), "unowned Orchard offer should not reveal the long unused service trunk", failures)
	var footprints := staging.visible_campus_footprints()
	_check(PackingAnnexVisualScript.declared_footprint() in footprints, "offered Packing footprint should be camera-visible", failures)
	_check(ITCoopVisualScript.declared_footprint() in footprints, "owned IT footprint should be camera-visible", failures)
	_check(CampusExpansionVisualScript.declared_footprint() in footprints, "offered North Meadow footprint should be camera-visible", failures)
	_check(CampusPortfolioVisualScript.declared_footprint(&"orchard_row") in footprints, "offered Orchard footprint should be camera-visible", failures)


func _assert_later_save_reconstruction(staging: OfficeStorytelling, failures: Array[String]) -> void:
	var owned: Dictionary = {}
	for facility_id: StringName in FACILITY_IDS:
		owned[facility_id] = 1
	var later := {
		"day": 12,
		"owned_facilities": owned,
		"facility_catalog": [],
		"pinned_capital_plan_id": &"",
		"capital_plan": {},
		"contract_board": {"unlocked": true, "unlock_day": 3},
		"campus_expansion": {
			"unlock_day": 1,
			"access_gate_met": true,
			"parcel_owned": true,
			"parcel": {"id": &"north_meadow", "owned": true},
			"construction_stage": &"operational",
		},
		"campus_portfolio": {
			"current_day": 12,
			"parcels": [
				{"id": &"orchard_row", "owned": true, "unlock_day": 6},
				{"id": &"creekside_yard", "owned": true, "unlock_day": 9},
			],
			"projects": [],
			"modules": [],
		},
		"workers": [],
		"claim_queue_counts": {},
	}
	staging.apply_snapshot(later)
	for root_name: String in FUTURE_ROOT_NAMES:
		_check(_root_visible(staging, root_name), "later save should reconstruct visible %s without reveal save data" % root_name, failures)
	_check(_root_visible(staging, "CareCampusSpine"), "later owned care campus should retain its spine", failures)
	_check(_root_visible(staging, "OperationsCampusSpine"), "later owned operations campus should retain its spine", failures)
	_check(_root_visible(staging, "PortfolioSharedInfrastructure"), "owned portfolio should reveal its used shared service trunk", failures)
	_check(_root_visible(staging, "OrchardRowParcel") and _root_visible(staging, "CreeksideYardParcel"), "owned portfolio deeds should both remain visible", failures)
	_check(staging.campus_presentation_state(&"north_meadow") == &"owned", "later North Meadow should reconstruct as owned", failures)
	_check(staging.campus_presentation_state(&"creekside_yard") == &"owned", "later Creekside should reconstruct as owned", failures)
	var bounds := staging.visible_campus_bounds()
	_check(bounds.position.is_equal_approx(Vector2(-11.82, -8.90)), "published later bounds should include the west board and south Packing edge", failures)
	_check(bounds.end.is_equal_approx(Vector2(31.45, 39.20)), "published later bounds should include the complete owned campus and Operations approach", failures)
	var camera_aabb := staging.visible_campus_camera_aabb()
	_check(camera_aabb.position.is_equal_approx(Vector3(-11.82, -0.20, -8.90)), "camera AABB should map X/Z presentation bounds without changing coordinates", failures)
	_check(camera_aabb.end.is_equal_approx(Vector3(31.45, 4.50, 39.20)), "camera AABB should publish a stable authored vertical envelope", failures)

	# Capacity changes rebuild this module in production. Presentation must survive
	# that rebuild using the last derived authoritative source, not a save field.
	staging.configure(
		OfficeStorytellingScript.DEFAULT_DESK_POSITIONS,
		OfficeStorytellingScript.DEFAULT_INTAKE_POSITION,
		OfficeStorytellingScript.DEFAULT_PRESENTATION_POSITION,
	)
	_check(_root_visible(staging, "ITCoopVisual") and _root_visible(staging, "CreeksideYardParcel"), "layout rebuild should retain reconstructed later-save visibility", failures)
	_check(staging.campus_presentation_state(&"it_coop") == &"owned", "layout rebuild should retain derived state read model", failures)


func _fresh_snapshot(day: int) -> Dictionary:
	return {
		"day": day,
		"owned_facilities": {},
		"facility_catalog": [
			{"id": &"farmer_brand_packing_annex", "level": 0, "unlocked": false, "unlock_day": 3},
			{"id": &"records_annex", "level": 0, "unlocked": false, "unlock_day": 3},
			{"id": &"wellness_nest_room", "level": 0, "unlocked": false, "unlock_day": 3},
			{"id": &"training_roost", "level": 0, "unlocked": false, "unlock_day": 4},
			{"id": &"farmer_relations_gallery", "level": 0, "unlocked": false, "unlock_day": 5},
			{"id": &"rooster_operations_office", "level": 0, "unlocked": false, "unlock_day": 5},
			{"id": &"it_coop", "level": 0, "unlocked": false, "unlock_day": 6},
			{"id": &"farm_mutual_negotiation_room", "level": 0, "unlocked": false, "unlock_day": 6},
			{"id": &"farmgate_dispatch_depot", "level": 0, "unlocked": false, "unlock_day": 6},
			{"id": &"flock_relations_office", "level": 0, "unlocked": false, "unlock_day": 7},
		],
		"pinned_capital_plan_id": &"",
		"capital_plan": {},
		"contract_board": {"unlocked": false, "unlock_day": 3},
		"campus_expansion": {
			"visible": true,
			"unlock_day": 1,
			"access_gate_met": false,
			"parcel_owned": false,
			"parcel": {"id": &"north_meadow", "owned": false, "can_purchase": false},
			"construction_stage": &"access",
		},
		"campus_portfolio": {
			"current_day": day,
			"parcels": [
				{"id": &"orchard_row", "owned": false, "unlock_day": 6, "can_purchase": false},
				{"id": &"creekside_yard", "owned": false, "unlock_day": 9, "can_purchase": false},
			],
			"projects": [],
			"modules": [],
		},
	}


func _root_visible(staging: Node, root_name: String) -> bool:
	var candidate := staging.find_child(root_name, true, false) as Node3D
	return candidate != null and candidate.visible


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition and message not in failures:
		failures.append(message)
