extends SceneTree

const OfficeStorytellingScript := preload("res://features/office/office_storytelling.gd")
const ShellQualityLabVisualScript := preload("res://features/office/shell_quality_lab_visual.gd")
const PackingAnnexVisualScript := preload("res://features/office/packing_annex_visual.gd")
const RecordsAnnexVisualScript := preload("res://features/office/records_annex_visual.gd")
const FarmMutualServiceCoopVisualScript := preload("res://features/office/farm_mutual_service_coop_visual.gd")
const FarmMutualNegotiationRoomVisualScript := preload("res://features/office/farm_mutual_negotiation_room_visual.gd")
const FarmMutualContractBoardVisualScript := preload("res://features/office/farm_mutual_contract_board_visual.gd")
const WellnessNestVisualScript := preload("res://features/office/wellness_nest_visual.gd")
const TrainingRoostVisualScript := preload("res://features/office/training_roost_visual.gd")
const FarmerRelationsGalleryVisualScript := preload("res://features/office/farmer_relations_gallery_visual.gd")
const RoosterOperationsOfficeVisualScript := preload("res://features/office/rooster_operations_office_visual.gd")
const ITCoopVisualScript := preload("res://features/office/it_coop_visual.gd")
const FlockRelationsOfficeVisualScript := preload("res://features/office/flock_relations_office_visual.gd")
const FeedProcurementCoopVisualScript := preload("res://features/office/feed_procurement_coop_visual.gd")

const RAIL_IDLE_MAX_ENERGY := 0.08


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var staging := OfficeStorytellingScript.new() as OfficeStorytelling
	root.add_child(staging)
	await process_frame

	# Exercise the supported post-add_child configuration path used by Office.
	var desk_positions: Array[Vector3] = [
		Vector3(-6.0, 0.0, -2.8), Vector3(0.0, 0.0, -2.8), Vector3(6.0, 0.0, -2.8),
		Vector3(-6.0, 0.0, 3.0), Vector3(0.0, 0.0, 3.0), Vector3(6.0, 0.0, 3.0),
	]
	staging.configure(desk_positions, Vector3(9.55, 0.0, 5.35), Vector3(9.4, 0.0, -6.85))

	for root_name in [
		"RoosterManagementPerch",
		"VisibleEggCollectionChain",
		"FarmBureauZoneMarkers",
		"FarmBureauSatire",
		"ArchiveAndIntakeStory",
		"ShellQualityLabVisual",
		"PackingAnnexVisual",
		"RecordsAnnexVisual",
		"FarmMutualServiceCoopVisual",
		"FarmMutualNegotiationRoomVisual",
		"FarmMutualContractBoardVisual",
		"CareCampusSpine",
		"WellnessNestVisual",
		"TrainingRoostVisual",
		"FarmerRelationsGalleryVisual",
		"OperationsCampusSpine",
		"RoosterOperationsOfficeVisual",
		"ITCoopVisual",
		"FlockRelationsOfficeVisual",
		"FeedProcurementCoopVisual",
	]:
		_check(staging.find_child(root_name, true, false) != null, "staging should expose %s" % root_name, failures)
	_check(staging.find_children("FarmMutualContractBoardVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one contract-board root", failures)
	_check(staging.find_children("FarmMutualServiceCoopVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one Service Coop root", failures)
	_check(staging.find_children("FarmMutualNegotiationRoomVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one negotiation-room root", failures)
	_check(staging.find_children("CareCampusSpine", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one care-campus spine", failures)
	_check(staging.find_children("WellnessNestVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one Wellness Nest root", failures)
	_check(staging.find_children("TrainingRoostVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one Training Roost root", failures)
	_check(staging.find_children("FarmerRelationsGalleryVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one Farmer Relations Gallery root", failures)
	_check(staging.find_children("OperationsCampusSpine", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one operations-campus spine", failures)
	_check(staging.find_children("RoosterOperationsOfficeVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one Rooster Operations root", failures)
	_check(staging.find_children("ITCoopVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one IT Coop root", failures)
	_check(staging.find_children("FlockRelationsOfficeVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one Flock Relations root", failures)
	_check(staging.find_children("FeedProcurementCoopVisual", "Node3D", true, false).size() == 1, "post-add configuration should rebuild exactly one Feed Procurement root", failures)

	_check(staging.find_children("DeskEggTray_*", "MeshInstance3D", true, false).size() == 6, "every desk should have a visible collection tray", failures)
	_check(staging.find_children("EggLiftTube_*", "MeshInstance3D", true, false).size() == 6, "every desk should connect to the overhead collection rail", failures)
	_check(staging.find_children("EggInTransit_*", "MeshInstance3D", true, false).is_empty(), "collection manifold should never contain decorative fake eggs", failures)
	_check(staging.find_children("EmptyTransitCarrier_*", "MeshInstance3D", true, false).size() == 4, "collection manifold should expose four visibly empty carrier collars", failures)
	var row_rail := staging.find_child("OverheadRowRail_00", true, false) as MeshInstance3D
	var row_glow := staging.find_child("OverheadRowRail_00Glow", true, false) as MeshInstance3D
	var desk_status_lamp := staging.find_child("CollectionStatusLamp_00", true, false) as MeshInstance3D
	var carrier_lamp := staging.find_child("TransitCarrierLamp_00", true, false) as MeshInstance3D
	var shared_rail_material := (
		row_glow.material_override as StandardMaterial3D
		if row_glow != null else
		null
	)
	_check(
		row_rail != null
		and row_glow != null
		and desk_status_lamp != null
		and carrier_lamp != null
		and shared_rail_material != null,
		"collection rails should retain their physical body, indicator strip, desk lamp, and carrier lamp",
		failures,
	)
	_check(
		shared_rail_material != null
		and desk_status_lamp.material_override == shared_rail_material
		and carrier_lamp.material_override == shared_rail_material,
		"rail strips, desk status lamps, and carrier lamps should reuse one bounded indicator material",
		failures,
	)
	await process_frame
	_check(
		shared_rail_material != null
		and shared_rail_material.emission_energy_multiplier <= RAIL_IDLE_MAX_ENERGY,
		"an empty collection chain should keep its shared rail indicators low-contrast (energy %.3f)" % (
			shared_rail_material.emission_energy_multiplier if shared_rail_material != null else -1.0
		),
		failures,
	)
	var row_start := (
		row_rail.get_meta(&"segment_start", Vector3(INF, INF, INF)) as Vector3
		if row_rail != null else
		Vector3(INF, INF, INF)
	)
	var row_finish := (
		row_rail.get_meta(&"segment_finish", Vector3(INF, INF, INF)) as Vector3
		if row_rail != null else
		Vector3(INF, INF, INF)
	)
	_check(
		is_equal_approx(row_start.y, OfficeStorytelling.COLLECTION_RAIL_HEIGHT)
		and is_equal_approx(row_finish.y, OfficeStorytelling.COLLECTION_RAIL_HEIGHT)
		and is_equal_approx(row_finish.x, OfficeStorytelling.SIDE_MANIFOLD_X)
		and row_rail != null
		and row_rail.position.is_equal_approx(row_start.lerp(row_finish, 0.5)),
		"the visual-only treatment must preserve authored rail height, manifold endpoint, and segment metadata",
		failures,
	)
	_check(staging.find_children("AuthoritativeClutchSlot_*", "Node3D", true, false).size() == 36, "basket and cart should expose a bounded 36-slot living clutch", failures)
	_check(staging.find_children("CartonEgg", "MeshInstance3D", true, false).is_empty(), "collection cart should start without decorative eggs", failures)
	_check(_multimesh_instance_total(staging, "DeskTrayRailBatch") == 12, "collection batching should preserve both tray rails at all six desks", failures)
	_check(_multimesh_instance_total(staging, "EggCartWheelBatch") == 4, "collection batching should preserve all four rotated cart wheels", failures)
	_check(staging.find_children("DeskTrayRail", "MeshInstance3D", true, false).is_empty(), "collection rails should not regress to individual renderer nodes", failures)
	_check(staging.find_children("EggCartWheel", "MeshInstance3D", true, false).is_empty(), "cart wheels should not regress to individual renderer nodes", failures)
	var tray_rail_batch := _find_multimesh_batch(staging, "DeskTrayRailBatch")
	var authored_rail_positions: Array = tray_rail_batch.get_meta("authored_positions", []) if tray_rail_batch != null else []
	var tray_rail_index := 0
	for desk_position: Vector3 in desk_positions:
		var pickup_position := desk_position + Vector3(1.33, 1.12, 0.70)
		for rail_x in [-0.33, 0.33]:
			var rail_position: Vector3 = authored_rail_positions[tray_rail_index] if tray_rail_index < authored_rail_positions.size() else Vector3.ZERO
			_check(
				rail_position.is_equal_approx(pickup_position + Vector3(rail_x, 0.10, 0.0)),
				"batched tray rail %d should retain its authored desk-relative position (actual=%s expected=%s)" % [tray_rail_index, rail_position, pickup_position + Vector3(rail_x, 0.10, 0.0)],
				failures,
			)
			tray_rail_index += 1
	var cart_wheel_batch := _find_multimesh_batch(staging, "EggCartWheelBatch")
	var authored_wheel_transforms: Array = cart_wheel_batch.get_meta("authored_transforms", []) if cart_wheel_batch != null else []
	var expected_wheel_basis := Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(90.0)))
	var wheel_index := 0
	for wheel_z in [-0.39, 0.39]:
		for wheel_x in [-0.36, 0.36]:
			var wheel_transform: Transform3D = authored_wheel_transforms[wheel_index] if wheel_index < authored_wheel_transforms.size() else Transform3D.IDENTITY
			_check(
				wheel_transform.origin.is_equal_approx(OfficeStorytelling.COLLECTION_CART_CENTER + Vector3(wheel_x, 0.26, wheel_z))
				and wheel_transform.basis.is_equal_approx(expected_wheel_basis),
				"batched cart wheel %d should retain its authored position and axle rotation (actual=%s expected=%s)" % [wheel_index, wheel_transform.origin, OfficeStorytelling.COLLECTION_CART_CENTER + Vector3(wheel_x, 0.26, wheel_z)],
				failures,
			)
			wheel_index += 1
	_check(staging.find_child("ManagementYieldBoard", true, false) != null, "management perch should expose live yield metrics", failures)
	_check(_multimesh_instance_total(staging, "PerchGlassPostBatch") == 3, "management perch batching should preserve all three opaque glass posts", failures)
	_check(_multimesh_instance_total(staging, "ExecutiveDeskLegBatch") == 2, "management perch batching should preserve both executive desk legs", failures)
	_check(_multimesh_instance_total(staging, "FlockwatchMonitorFrameBatch") == 3, "management perch batching should preserve all three monitor frames", failures)
	_check(_multimesh_instance_total(staging, "FlockwatchMonitorScreenBatch") == 3, "management perch batching should preserve all three monitor screens", failures)
	_check(_multimesh_instance_total(staging, "FlockwatchDisplayRailBatch") == 2, "management perch batching should preserve both display rails", failures)
	_check(_multimesh_instance_total(staging, "FlockwatchDisplayClampBatch") == 2, "management perch batching should preserve both display clamps", failures)
	var monitor_screen_batch := staging.find_child("FlockwatchMonitorScreenBatch", true, false) as MultiMeshInstance3D
	var monitor_screen_material := (
		monitor_screen_batch.material_override as StandardMaterial3D
		if monitor_screen_batch != null else null
	)
	_check(
		monitor_screen_material != null
		and monitor_screen_material.emission_enabled
		and monitor_screen_material.emission_energy_multiplier >= 0.60,
		"all three management monitors should share the live pulsing screen material",
		failures,
	)
	_check(staging.find_child("OpenBeakSuggestionBox", true, false) != null, "bureau should include satirical farm-office props", failures)
	_check(staging.find_child("ArchiveRetentionLabel", true, false) != null, "archive should communicate lifetime retention satire", failures)
	_check(staging.find_child("IntakeStatusLedger", true, false) != null, "intake should expose shell/credit storytelling", failures)
	_check(staging.find_children("*", "CollisionObject3D", true, false).is_empty(), "storytelling geometry must remain non-colliding", failures)

	var shell_lab := staging.find_child("ShellQualityLabVisual", true, false) as ShellQualityLabVisual
	_check(shell_lab != null, "storytelling should compose the dedicated shell-quality facility visual", failures)
	if shell_lab != null:
		_check(shell_lab.visual_state() == &"locked", "shell-quality footprint should remain visually quiet before its campaign unlock", failures)
		_check(not shell_lab.construction_pad_visible(), "locked shell-quality facility should not show construction staging", failures)
		_check(not shell_lab.owned_bay_visible(), "locked shell-quality facility should not imply an unpurchased benefit", failures)
		var footprint := ShellQualityLabVisualScript.declared_footprint()
		_check(footprint.position.is_equal_approx(Vector2(9.05, 1.40)), "shell-quality footprint should publish its authored X/Z minimum", failures)
		_check(footprint.end.is_equal_approx(Vector2(11.15, 3.20)), "shell-quality footprint should publish its authored X/Z maximum", failures)

	var packing_annex: Variant = staging.find_child("PackingAnnexVisual", true, false)
	_check(packing_annex != null, "storytelling should compose the external packing-annex facility visual", failures)
	if packing_annex != null:
		_check(packing_annex.visual_state() == &"locked", "packing annex should begin as a restrained lease option", failures)
		_check(packing_annex.locked_marker_visible(), "locked annex should expose its physical lease boundary marker", failures)
		_check(not packing_annex.survey_site_visible(), "locked annex must not imply that construction is funded", failures)
		var annex_footprint := PackingAnnexVisualScript.declared_footprint()
		_check(annex_footprint.position.is_equal_approx(Vector2(12.00, -8.90)), "packing-annex footprint should publish its exact X/Z minimum", failures)
		_check(annex_footprint.size.is_equal_approx(Vector2(6.40, 5.80)), "packing-annex footprint should publish its authored 6.4m by 5.8m envelope", failures)
		_check(packing_annex.focus_point_global().is_equal_approx(Vector3(15.20, 0.90, -6.00)), "packing annex should expose a stable purchase-reveal camera target", failures)
		var lease_letters := packing_annex.find_child("PackingAnnexLeaseOption", true, false) as Node
		_check(lease_letters != null and bool(lease_letters.get_meta(&"host_embossed_copy", false)), "lease marker should use smooth host-embossed environmental lettering", failures)

	var service_coop: Variant = staging.find_child("FarmMutualServiceCoopVisual", true, false)
	_check(service_coop != null, "storytelling should compose the northeast Farm Mutual Service Coop", failures)
	if service_coop != null:
		_check(service_coop.visual_state() == &"locked", "fresh Service Coop parcel should show only its standing-gated lease", failures)
		_check(service_coop.locked_marker_visible() and not service_coop.survey_site_visible(), "locked Service Coop must not imply funded construction", failures)
		_check(FarmMutualServiceCoopVisualScript.declared_footprint() == Rect2(Vector2(12.0, 3.1), Vector2(6.4, 5.8)), "Service Coop should publish its exact northeast parcel", failures)
		_check(service_coop.focus_point_global().is_equal_approx(Vector3(15.2, 1.05, 6.0)), "Service Coop should expose its stable purchase-reveal focus", failures)
		_check(service_coop.geometry_bounds_inside_footprint(), "all Service Coop tiers should stay inside their declared parcel", failures)

	var negotiation_room: Variant = staging.find_child("FarmMutualNegotiationRoomVisual", true, false)
	_check(negotiation_room != null, "storytelling should compose the north-parcel Farm Mutual negotiation room", failures)
	if negotiation_room != null:
		_check(negotiation_room.visual_state() == &"locked", "fresh negotiation parcel should show only its standing-gated survey", failures)
		_check(negotiation_room.locked_marker_visible() and not negotiation_room.construction_prospect_visible(), "locked negotiation room must not imply funded construction", failures)
		_check(FarmMutualNegotiationRoomVisualScript.declared_footprint() == Rect2(Vector2(12.0, 9.1), Vector2(6.4, 5.8)), "negotiation room should publish its exact north parcel", failures)
		_check(negotiation_room.focus_point_global().is_equal_approx(Vector3(15.2, 1.18, 12.0)), "negotiation room should expose its stable purchase-reveal focus", failures)
		_check(negotiation_room.geometry_bounds_inside_footprint(), "all negotiation-room states should stay inside their declared parcel", failures)
		_check(negotiation_room.chicken_perch_chair_count() == 6, "owned pavilion should author six chicken perch chairs", failures)
		_check(negotiation_room.farmer_credit_chair_present(), "owned pavilion should retain the oversized empty farmer-credit chair", failures)
		_check(negotiation_room.visible_clause_folio_count() == 0 and not negotiation_room.active_rider_visible(), "empty negotiation snapshots must not invent clause folders or riders", failures)
		_check(not negotiation_room.premium_marker_visible() and not negotiation_room.breach_marker_visible(), "empty negotiation snapshots must not invent money records", failures)
		_check(negotiation_room.find_children("*", "CollisionObject3D", true, false).is_empty(), "negotiation room should remain visual-only", failures)
		_check(negotiation_room.find_children("*", "NavigationRegion3D", true, false).is_empty(), "negotiation room should not add navigation regions", failures)

	var wellness_nest: Variant = staging.find_child("WellnessNestVisual", true, false)
	_check(wellness_nest != null, "storytelling should compose the east-campus Wellness Nest", failures)
	if wellness_nest != null:
		_check(wellness_nest.visual_state() == &"locked" and wellness_nest.locked_marker_visible(), "fresh Wellness Nest should begin as a gated parcel", failures)
		_check(WellnessNestVisualScript.declared_footprint() == Rect2(Vector2(12.0, 15.1), Vector2(6.4, 5.8)), "Wellness Nest should publish its exact east-campus parcel", failures)
		_check(wellness_nest.focus_point_global().is_equal_approx(Vector3(15.2, 1.05, 18.0)), "Wellness Nest should expose its stable purchase-reveal focus", failures)
		_check(wellness_nest.geometry_bounds_inside_footprint(), "all Wellness Nest tiers should remain inside their declared parcel", failures)

	var training_roost: Variant = staging.find_child("TrainingRoostVisual", true, false)
	_check(training_roost != null, "storytelling should compose the east-campus Training Roost", failures)
	if training_roost != null:
		_check(training_roost.visual_state() == &"locked" and training_roost.locked_marker_visible(), "fresh Training Roost should begin as a gated parcel", failures)
		_check(TrainingRoostVisualScript.declared_footprint() == Rect2(Vector2(12.0, 21.1), Vector2(6.4, 5.8)), "Training Roost should publish its exact east-campus parcel", failures)
		_check(training_roost.focus_point_global().is_equal_approx(Vector3(15.2, 1.05, 24.0)), "Training Roost should expose its stable purchase-reveal focus", failures)
		_check(training_roost.geometry_bounds_inside_footprint(), "all Training Roost tiers should remain inside their declared parcel", failures)
		_check(training_roost.visible_credential_count() == 0, "empty Training snapshots must not invent credentials", failures)

	var farmer_relations_gallery: Variant = staging.find_child("FarmerRelationsGalleryVisual", true, false)
	_check(farmer_relations_gallery != null, "storytelling should compose the west care-campus Farmer Relations Gallery", failures)
	if farmer_relations_gallery != null:
		_check(farmer_relations_gallery.visual_state() == &"locked" and farmer_relations_gallery.locked_marker_visible(), "fresh Farmer Relations Gallery should begin as a gated parcel", failures)
		_check(FarmerRelationsGalleryVisualScript.declared_footprint() == Rect2(Vector2(4.10, 21.10), Vector2(6.40, 5.80)), "Farmer Relations Gallery should publish its exact west care-campus parcel", failures)
		_check(FarmerRelationsGalleryVisualScript.entrance_bridge_footprint() == Rect2(Vector2(10.50, 23.40), Vector2(0.25, 1.20)), "Farmer Relations Gallery should publish its exact care-spine bridge", failures)
		_check(farmer_relations_gallery.focus_point_global().is_equal_approx(Vector3(7.30, 1.50, 24.0)), "Farmer Relations Gallery should expose its stable purchase-reveal focus", failures)
		_check(farmer_relations_gallery.geometry_bounds_inside_footprint() and farmer_relations_gallery.connector_geometry_inside_bridge(), "Farmer Relations Gallery room and bridge should stay inside their declared envelopes", failures)
		_check(farmer_relations_gallery.circulation_clear(), "Farmer Relations Gallery should preserve its 1.10m east-entry aisle", failures)
		_check(not farmer_relations_gallery.evidence_profile_visible() and not farmer_relations_gallery.last_receipt_visible(), "empty Farmer Relations Gallery must not invent people or publicity records", failures)

	var rooster_operations: Variant = staging.find_child("RoosterOperationsOfficeVisual", true, false)
	_check(rooster_operations != null, "storytelling should compose the east-campus Rooster Operations office", failures)
	if rooster_operations != null:
		_check(rooster_operations.visual_state() == &"locked" and rooster_operations.locked_marker_visible(), "fresh Rooster Operations should begin as a gated parcel", failures)
		_check(RoosterOperationsOfficeVisualScript.declared_footprint() == Rect2(Vector2(12.0, 27.1), Vector2(6.4, 5.8)), "Rooster Operations should publish its exact east-campus parcel", failures)
		_check(rooster_operations.focus_point_global().is_equal_approx(Vector3(15.2, 1.05, 30.0)), "Rooster Operations should expose its stable purchase-reveal focus", failures)
		_check(rooster_operations.geometry_bounds_inside_footprint(), "all Rooster Operations tiers should remain inside their declared parcel", failures)
		_check(rooster_operations.visible_assignment_token_count() == 0, "empty operations snapshots must not invent worker assignments", failures)

	var it_coop: Variant = staging.find_child("ITCoopVisual", true, false)
	_check(it_coop != null, "storytelling should compose the east-campus IT Coop", failures)
	if it_coop != null:
		_check(it_coop.visual_state() == &"locked" and it_coop.locked_marker_visible(), "fresh IT Coop should begin as a gated parcel", failures)
		_check(ITCoopVisualScript.declared_footprint() == Rect2(Vector2(12.0, 33.1), Vector2(6.4, 5.8)), "IT Coop should publish its exact east-campus parcel", failures)
		_check(it_coop.focus_point_global().is_equal_approx(Vector3(15.2, 1.05, 36.0)), "IT Coop should expose its stable purchase-reveal focus", failures)
		_check(it_coop.geometry_bounds_inside_footprint(), "all IT Coop tiers should remain inside their declared parcel", failures)
		_check(it_coop.visible_auto_worker_jack_count() == 0 and not it_coop.patch_invoice_visible(), "empty IT snapshots must not invent workers or invoices", failures)

	var flock_relations: Variant = staging.find_child("FlockRelationsOfficeVisual", true, false)
	_check(flock_relations != null, "storytelling should compose the west-campus Flock Relations office", failures)
	if flock_relations != null:
		_check(flock_relations.visual_state() == &"locked" and flock_relations.locked_marker_visible(), "fresh Flock Relations should begin as a gated parcel", failures)
		_check(FlockRelationsOfficeVisualScript.declared_footprint() == Rect2(Vector2(4.10, 33.10), Vector2(6.40, 5.80)), "Flock Relations should publish its exact west-campus parcel", failures)
		_check(FlockRelationsOfficeVisualScript.entrance_bridge_footprint() == Rect2(Vector2(10.50, 35.40), Vector2(0.25, 1.20)), "Flock Relations should publish its exact operations-spine bridge", failures)
		_check(flock_relations.focus_point_global().is_equal_approx(Vector3(7.30, 1.05, 36.0)), "Flock Relations should expose its stable purchase-reveal focus", failures)
		_check(flock_relations.geometry_bounds_inside_footprint() and flock_relations.connector_geometry_inside_bridge(), "Flock Relations room and bridge geometry should stay inside their declared envelopes", failures)
		_check(flock_relations.circulation_clear(), "Flock Relations should preserve its 1.10m east-entry aisle", failures)
		_check(flock_relations.visible_case_folder_count() == 0 and not flock_relations.resolution_docket_visible(), "empty Flock Relations snapshots must not invent cases or outcomes", failures)

	var feed_procurement: Variant = staging.find_child("FeedProcurementCoopVisual", true, false)
	_check(feed_procurement != null, "storytelling should compose the southwest-campus Feed Procurement co-op", failures)
	if feed_procurement != null:
		_check(feed_procurement.visual_state() == &"locked", "fresh Feed Procurement should begin as a gated parcel", failures)
		_check(FeedProcurementCoopVisualScript.declared_footprint() == Rect2(Vector2(4.10, 27.10), Vector2(6.40, 5.80)), "Feed Procurement should publish its exact southwest-campus parcel", failures)
		_check(FeedProcurementCoopVisualScript.entrance_bridge_footprint() == Rect2(Vector2(10.50, 29.40), Vector2(0.25, 1.20)), "Feed Procurement should publish its exact operations-spine bridge", failures)
		_check(feed_procurement.focus_point_global().is_equal_approx(Vector3(7.30, 1.50, 30.0)), "Feed Procurement should expose its stable purchase-reveal focus", failures)
		_check(feed_procurement.geometry_bounds_inside_footprint() and feed_procurement.connector_geometry_inside_bridge(), "Feed Procurement room and bridge should stay inside their declared envelopes", failures)
		_check(feed_procurement.circulation_clear(), "Feed Procurement should preserve its 1.10m east-entry aisle", failures)
		_check(feed_procurement.visible_stock_sack_count() == 0 and feed_procurement.visible_offer_binder_count() == 0, "empty Feed Procurement snapshots must not invent lots or offers", failures)

	var operations_spine := staging.find_child("OperationsCampusSpine", true, false) as Node3D
	_check(operations_spine != null and operations_spine.get_meta(&"declared_footprint", Rect2()) == OfficeStorytellingScript.OPERATIONS_CAMPUS_SPINE_FOOTPRINT, "operations campus should publish its connected spine parcel", failures)
	_check(operations_spine != null and bool(operations_spine.get_meta(&"collision_free", false)) and bool(operations_spine.get_meta(&"navigation_free", false)), "operations spine should remain visual-only and route-neutral", failures)
	_check(operations_spine != null and operations_spine.get_meta(&"serves_facilities", []) == [&"rooster_operations_office", &"it_coop", &"flock_relations_office", &"feed_procurement_coop"], "operations spine should publish its exact four-facility service contract", failures)

	var contract_board := staging.find_child("FarmMutualContractBoardVisual", true, false) as FarmMutualContractBoardVisual
	_check(contract_board != null, "storytelling should compose the physical Farm Mutual contract board", failures)
	var contract_offers: Array[Dictionary] = [
		{"id": &"steady_roost", "name": "Steady Roost Mutual", "lane_mix": {&"nest_damage": 3}, "rush_claims": 0, "premium_cents": 7200, "breach_cents": 3600, "required_completed": 5, "deadline_day": 3},
		{"id": &"fox_watch", "name": "Fox Watch Binder", "lane_mix": {&"predator_loss": 2}, "rush_claims": 1, "premium_cents": 8800, "breach_cents": 5100, "required_completed": 6, "deadline_day": 3},
		{"id": &"appeal_harvest", "name": "Appeal Harvest", "lane_mix": {&"appeals": 2}, "rush_claims": 2, "premium_cents": 10300, "breach_cents": 6400, "required_completed": 7, "deadline_day": 3},
	]
	if contract_board != null:
		_check(contract_board.visual_state() == &"locked", "fresh campaign should keep Farm Mutual's folders sealed", failures)
		_check(contract_board.focus_point_global().is_equal_approx(Vector3(-11.46, 2.08, 0.0)), "contract board should expose its audited left-wall camera target", failures)
		_check(FarmMutualContractBoardVisualScript.declared_footprint() == Rect2(Vector2(-11.82, -1.66), Vector2(0.46, 3.32)), "contract board should publish its exact shallow wall parcel", failures)
		_check(contract_board.geometry_bounds_inside_footprint(), "locked, open, and result hardware should stay inside the declared wall parcel", failures)
		_check(contract_board.find_children("*", "CollisionObject3D", true, false).is_empty(), "contract board should remain visual-only", failures)

	staging.apply_snapshot({
		"campaign_unlocks": {"shell_quality_checks": true},
		"owned_facilities": {"candling_rework_bay": 0, "farmer_brand_packing_annex": 0, "records_annex": 0, "farm_mutual_service_coop": 0, "farm_mutual_negotiation_room": 0, "wellness_nest_room": 0, "training_roost": 0, "farmer_relations_gallery": 0, "rooster_operations_office": 0, "it_coop": 0, "flock_relations_office": 0, "feed_procurement_coop": 0},
		"farmer_relations_gallery": {"level": 0, "public_standing": 0, "standing_rank": "UNLISTED", "source_digest": {}, "attribution": {}, "last_receipt": {}},
		"operations": {"rooster_office_level": 0, "it_coop_level": 0, "flock_relations_office_level": 0},
		"flock_relations": {"level": 0, "capacity": 0, "resolution_limit": 0, "resolutions_used_today": 0, "open_case_count": 0, "open_cases": [], "resolved_total": 0, "denied_total": 0, "settlement_spend_total_cents": 0, "last_resolution": {}},
		"feed_procurement": _feed_procurement_snapshot(0, true),
		"facility_catalog": [
			{"id": "candling_rework_bay", "owned": true},
			{"id": "farmer_brand_packing_annex", "unlocked": true, "level": 0},
			{"id": "records_annex", "unlocked": true, "level": 0},
			{"id": "farm_mutual_service_coop", "unlocked": true, "level": 0},
			{"id": "farm_mutual_negotiation_room", "unlocked": true, "level": 0},
			{"id": "wellness_nest_room", "unlocked": true, "level": 0},
			{"id": "training_roost", "unlocked": true, "level": 0},
			{"id": "farmer_relations_gallery", "unlocked": true, "level": 0},
			{"id": "rooster_operations_office", "unlocked": true, "level": 0},
			{"id": "it_coop", "unlocked": true, "level": 0},
			{"id": "flock_relations_office", "unlocked": true, "level": 0},
			{"id": "feed_procurement_coop", "unlocked": true, "level": 0},
		],
		"contract_board": {"unlocked": true, "standing": {"points": 2, "rank": "bronze", "next_threshold": 6}, "offers": contract_offers, "active": {}, "last_result": {}},
	})
	if shell_lab != null:
		_check(shell_lab.visual_state() == &"construction_pad", "campaign unlock should reveal the reserved shell-QA utility pad", failures)
		_check(shell_lab.construction_pad_visible(), "unpurchased facility should show tasteful construction staging", failures)
		_check(not shell_lab.owned_bay_visible(), "construction staging must not show completed equipment", failures)
		_check(shell_lab.find_child("ReservedUtilityPad", true, false) != null, "construction state should include a connected utility pad", failures)
		_check(shell_lab.find_children("*", "CollisionObject3D", true, false).is_empty(), "shell-quality facility must remain non-colliding in every state", failures)
		_check(_visible_meshes_fit_lab_envelope(shell_lab), "construction staging should stay inside the declared low-profile footprint", failures)
	if packing_annex != null:
		_check(packing_annex.visual_state() == &"survey", "unlock should replace the lease marker with the surveyed annex foundation", failures)
		_check(not packing_annex.locked_marker_visible(), "available annex should retire the board-approval marker", failures)
		_check(packing_annex.survey_site_visible(), "available annex should expose its surveyed construction site", failures)
		_check(packing_annex.find_child("AnnexSurveyFoundation", true, false) != null, "survey state should reserve the exact external foundation", failures)
		_check(_visible_meshes_fit_annex_envelope(packing_annex), "survey staging should stay inside the declared annex footprint", failures)
	if contract_board != null:
		_check(contract_board.visual_state() == &"open", "canonical unlock snapshot should open the mounted contract board", failures)
		_check(contract_board.visible_offer_count() == 3, "canonical offer catalog should populate exactly three physical folders", failures)
	if service_coop != null:
		_check(service_coop.visual_state() == &"survey", "earned Bronze standing should reveal the unpurchased Service Coop survey", failures)
		_check(service_coop.survey_site_visible() and not service_coop.locked_marker_visible(), "Service Coop survey should replace its locked boundary", failures)
	if negotiation_room != null:
		_check(negotiation_room.visual_state() == &"construction_prospect", "earned facility unlock should reveal the unpurchased council-room prospect", failures)
		_check(negotiation_room.construction_prospect_visible() and not negotiation_room.locked_marker_visible(), "negotiation construction prospect should replace its locked survey", failures)
		_check(not negotiation_room.owned_room_visible(), "unpurchased negotiation room must not imply installed economic benefits", failures)
	if wellness_nest != null:
		_check(wellness_nest.visual_state() == &"survey" and wellness_nest.survey_site_visible(), "earned Wellness unlock should reveal its recovery survey", failures)
	if training_roost != null:
		_check(training_roost.visual_state() == &"survey" and training_roost.survey_site_visible(), "earned Training unlock should reveal its credential survey", failures)
	if farmer_relations_gallery != null:
		_check(farmer_relations_gallery.visual_state() == &"survey" and farmer_relations_gallery.survey_site_visible(), "earned Farmer Relations unlock should reveal its publicity survey", failures)
		_check(farmer_relations_gallery.has_authoritative_gallery(), "Farmer Relations Gallery should recognize its canonical neutral projection", failures)
		_check(not farmer_relations_gallery.evidence_profile_visible() and not farmer_relations_gallery.last_receipt_visible(), "neutral Farmer Relations snapshot must remain visibly empty", failures)
	if rooster_operations != null:
		_check(rooster_operations.visual_state() == &"survey" and rooster_operations.survey_site_visible(), "earned Rooster Operations unlock should reveal its supervision survey", failures)
	if it_coop != null:
		_check(it_coop.visual_state() == &"survey" and it_coop.survey_site_visible(), "earned IT unlock should reveal its systems survey", failures)
	if flock_relations != null:
		_check(flock_relations.visual_state() == &"survey" and flock_relations.survey_site_visible(), "earned Flock Relations unlock should reveal its case-intake survey", failures)
		_check(flock_relations.has_authoritative_relations(), "Flock Relations should recognize the canonical neutral snapshot", failures)
		_check(flock_relations.visible_case_folder_count() == 0 and not flock_relations.resolution_docket_visible(), "neutral Flock Relations snapshot must remain visibly empty", failures)
	if feed_procurement != null:
		_check(feed_procurement.visual_state() == &"survey", "earned Feed Procurement unlock should reveal its surveyed receiving parcel", failures)
		_check(feed_procurement.has_authoritative_procurement(), "Feed Procurement should recognize the canonical neutral snapshot", failures)
		_check(feed_procurement.visible_stock_sack_count() == 0 and feed_procurement.visible_offer_binder_count() == 0, "neutral Feed Procurement snapshot must remain visibly empty", failures)

	# Rails crossing the open office must stay safely over chicken head-height;
	# floor zoning must remain decal-thin.
	for rail in staging.find_children("OverheadRowRail_*", "MeshInstance3D", true, false):
		_check((rail as MeshInstance3D).position.y >= 2.60, "%s should remain overhead" % rail.name, failures)
	for marker in staging.find_children("ZoneMarkerGlow", "MeshInstance3D", true, false):
		_check((marker as MeshInstance3D).position.y <= 0.03, "%s should remain a floor decal" % marker.name, failures)

	var active_mutual := contract_offers[1].duplicate(true)
	active_mutual["contract_id"] = "FM-0003-FOX_WATCH"
	active_mutual["timely_sound_completed"] = 4
	active_mutual["required_completed"] = 6
	active_mutual["clause_id"] = &"staffed_roost_rider"
	active_mutual["clause_label"] = "Staffed Roost Rider"
	active_mutual["clause_category"] = &"staffing"
	active_mutual["active_staff"] = 4
	active_mutual["required_active_staff"] = 5
	active_mutual["rush_active"] = true
	var flock_relations_snapshot := {
		"level": 3,
		"capacity": 6,
		"resolution_limit": 3,
		"resolutions_used_today": 1,
		"open_case_count": 2,
		"open_cases": [
			{"case_id": 701, "docket_id": "FR-D3-H41-701", "worker_id": 41, "worker_name": "Mabel", "case_type": &"pay_dispute", "title": "MISSING SCRATCH PREMIUM", "severity": 3, "filed_day": 3, "status": &"open", "evidence_summary": "Risk 63 | Grievance 71.0 | Stress 58.0 | Fatigue 44.0 | Trust 29.0"},
			{"case_id": 702, "docket_id": "FR-D3-H52-702", "worker_id": 52, "worker_name": "Penny", "case_type": &"surveillance", "title": "NEST CAMERA RETENTION", "severity": 2, "filed_day": 3, "status": &"open", "evidence_summary": "Risk 48 | Grievance 54.0 | Stress 61.0 | Fatigue 37.0 | Trust 33.0"},
		],
		"resolved_total": 4,
		"denied_total": 1,
		"settlement_spend_total_cents": 1850,
		"last_resolution": {"case_id": 699, "worker_id": 44, "worker_name": "Henrietta", "type": &"schedule_dispute", "title": "MANDATORY ROOST OVERTIME", "severity": 3, "filed_day": 2, "resolved_day": 3, "action_id": &"file_pip", "action_label": "FILE PIP", "cost_cents": 0, "outcome": "File Pip closed Henrietta's mandatory roost overtime file for $0.00."},
	}
	var feed_procurement_snapshot := _feed_procurement_snapshot(3)
	var snapshot := {
		"day": 3,
		"time_label": "6:15 PM",
		"eggs_today": 19,
		"eggs_total": 42,
		"quota_target": 24,
		"claims_waiting": 7,
		"claims_processed": 38,
		"overtime_enabled": true,
		"campaign_unlocks": {&"shell_quality_checks": true},
		"owned_facilities": {&"candling_rework_bay": 1, &"farmer_brand_packing_annex": 2, &"records_annex": 0, &"farm_mutual_service_coop": 2, &"farm_mutual_negotiation_room": 1, &"wellness_nest_room": 3, &"training_roost": 3, &"farmer_relations_gallery": 3, &"rooster_operations_office": 3, &"it_coop": 3, &"flock_relations_office": 3, &"feed_procurement_coop": 3},
		"facility_catalog": [
			{"id": &"farmer_brand_packing_annex", "unlocked": true, "level": 2},
			{"id": &"records_annex", "unlocked": true, "level": 0},
			{"id": &"farm_mutual_service_coop", "unlocked": true, "level": 2},
			{"id": &"farm_mutual_negotiation_room", "unlocked": true, "level": 1},
			{"id": &"wellness_nest_room", "unlocked": true, "level": 3},
			{"id": &"training_roost", "unlocked": true, "level": 3},
			{"id": &"rooster_operations_office", "unlocked": true, "level": 3},
			{"id": &"it_coop", "unlocked": true, "level": 3},
			{"id": &"flock_relations_office", "unlocked": true, "level": 3},
			{"id": &"feed_procurement_coop", "unlocked": true, "level": 3},
		],
		"operations": {
			"rooster_office_level": 3,
			"it_coop_level": 3,
			"flock_relations_office_level": 3,
			"supervision": {"action_limit": 4, "actions_used": 1, "actions_remaining": 3, "supervisor_payroll_cents": 1200, "surveillance_grievance_millipoints": 2000, "surveillance_stress_millipoints": 1500, "surveillance_solidarity_millipoints": 1500, "quota_pressure_actions_today": 1, "shift_pressure_applied": true},
			"automation": {"enabled": true, "work_basis_points": 11000, "work_multiplier": 1.1, "specialty_grace_minutes": 60, "recognizes_secondary_specialties": true, "compliance_exposure_millipoints": 2800, "ledger_patch_cost_cents": 3000, "spreadsheet_compliance_loss_millipoints": 12000, "spreadsheet_crack_basis_points": 400, "auto_enrolled_workers": 1, "active_auto_claims": 1, "shift_exposure_applied": true},
		},
		"flock_relations": flock_relations_snapshot,
		"feed_procurement": feed_procurement_snapshot,
		"facility_effects": {
			"wellness_nest_level": 3,
			"wellness_strain_gain_basis_points": 7600,
			"wellness_break_recovery_basis_points": 15000,
			"training_roost_level": 3,
			"career_sponsorship_cost_cents": 600,
			"cross_training_work_basis_points": 10000,
			"career_coaching_xp_bonus": 6,
		},
		"packing_carton_progress": 4,
		"claim_queue_counts": {&"nest_damage": 3, &"predator_loss": 2, &"appeals": 1},
		"active_directive": {"id": &"quota_rush", "name": "Quota Rush"},
		"contract_board": {"unlocked": true, "season": {"label": "Harvest 03"}, "standing": {"points": 6, "rank": "silver", "next_threshold": 12}, "offers": contract_offers, "active": active_mutual, "active_contract": active_mutual, "last_result": {}},
		"workers": [{"id": 41, "desk_index": 2, "display_name": "Mabel", "employed": true, "assigned_lane": &"auto", "assignment_name": "Auto Dispatch", "secondary_specialty_name": "APPEALS & EXCEPTIONS"}],
	}
	staging.apply_snapshot(snapshot)
	if shell_lab != null:
		_check(shell_lab.visual_state() == &"owned", "owned facility snapshot should replace the pad with the completed bay", failures)
		_check(not shell_lab.construction_pad_visible(), "owned facility must retire its construction staging", failures)
		_check(shell_lab.owned_bay_visible(), "owned facility should expose its physical economic purchase", failures)
		for required_part in [
			"ConnectedQABenchTop",
			"EnclosedCandlingHood",
			"ShellThicknessGauge",
			"CalibrationWeightRack",
			"RejectReworkPaperworkTray",
			"QACalibrationTerminal",
			"RestrainedQAStatusTower",
			"ShellQAEnamelPlate",
		]:
			_check(shell_lab.find_child(required_part, true, false) != null, "completed shell-QA bay should include %s" % required_part, failures)
		_check(shell_lab.find_children("*Egg*", "", true, false).is_empty(), "shell-QA bay must not invent decorative eggs", failures)
		_check(_visible_meshes_fit_lab_envelope(shell_lab), "completed shell-QA meshes should stay inside the declared low-profile footprint", failures)
	if packing_annex != null:
		_check(packing_annex.visual_state() == &"level_2", "level-two ownership should reveal both cumulative operating tiers", failures)
		_check(packing_annex.level_visible(1), "annex level two must retain the commissioned manual line", failures)
		_check(packing_annex.level_visible(2), "annex level two should expose its automation equipment", failures)
		_check(not packing_annex.level_visible(3), "annex level two must not imply premium dispatch benefits", failures)
		_check(packing_annex.visible_carton_progress_slots() == 4, "six-slot meter should display only authoritative carton progress", failures)
		for required_part in [
			"ManualPackingConveyor",
			"CartonRack",
			"AnnexLabelPrinter",
			"PackingStatusTower",
			"AuthoritativeCartonProgressMeter",
			"AutomatedSealer",
			"SecondPackingBelt",
			"AnnexWeighingHead",
			"BrandedPallet",
		]:
			_check(packing_annex.find_child(required_part, true, false) != null, "level-two packing annex should include %s" % required_part, failures)
		_check(packing_annex.find_children("*Egg*", "", true, false).is_empty(), "packing annex must never invent decorative eggs", failures)
		_check(packing_annex.find_children("*", "CollisionObject3D", true, false).is_empty(), "packing annex should remain non-colliding visual staging", failures)
		_check(_visible_meshes_fit_annex_envelope(packing_annex), "commissioned packing-annex meshes should stay inside their declared footprint", failures)
		staging.apply_snapshot({
			"day": 3,
			"time_label": "6:15 PM",
			"eggs_today": 19,
			"eggs_total": 42,
			"quota_target": 24,
			"claims_waiting": 7,
			"claims_processed": 38,
			"overtime_enabled": true,
			"campaign_unlocks": {&"shell_quality_checks": true},
			"owned_facilities": {&"candling_rework_bay": 1, &"farmer_brand_packing_annex": 3, &"records_annex": 0, &"farm_mutual_service_coop": 2, &"farm_mutual_negotiation_room": 1, &"wellness_nest_room": 3, &"training_roost": 3, &"farmer_relations_gallery": 3, &"rooster_operations_office": 3, &"it_coop": 3, &"flock_relations_office": 3, &"feed_procurement_coop": 3},
			"operations": {
				"rooster_office_level": 3,
				"it_coop_level": 3,
				"flock_relations_office_level": 3,
				"supervision": {"action_limit": 4, "actions_used": 1, "actions_remaining": 3, "supervisor_payroll_cents": 1200, "surveillance_grievance_millipoints": 2000, "surveillance_stress_millipoints": 1500, "surveillance_solidarity_millipoints": 1500, "quota_pressure_actions_today": 1, "shift_pressure_applied": true},
				"automation": {"enabled": true, "work_basis_points": 11000, "work_multiplier": 1.1, "specialty_grace_minutes": 60, "recognizes_secondary_specialties": true, "compliance_exposure_millipoints": 2800, "ledger_patch_cost_cents": 3000, "spreadsheet_compliance_loss_millipoints": 12000, "spreadsheet_crack_basis_points": 400, "auto_enrolled_workers": 1, "active_auto_claims": 1, "shift_exposure_applied": true},
			},
			"flock_relations": flock_relations_snapshot,
			"feed_procurement": feed_procurement_snapshot,
			"facility_effects": {
				"wellness_nest_level": 3,
				"wellness_strain_gain_basis_points": 7600,
				"wellness_break_recovery_basis_points": 15000,
				"training_roost_level": 3,
				"career_sponsorship_cost_cents": 600,
				"cross_training_work_basis_points": 10000,
				"career_coaching_xp_bonus": 6,
			},
			"packing_carton_progress": 6,
			"contract_board": {"unlocked": true, "season": {"label": "Harvest 03"}, "standing": {"points": 6, "rank": "silver", "next_threshold": 12}, "offers": contract_offers, "active": active_mutual, "active_contract": active_mutual, "last_result": {}},
			"claim_queue_counts": {&"nest_damage": 3, &"predator_loss": 2, &"appeals": 1},
			"active_directive": {"id": &"quota_rush", "name": "Quota Rush"},
			"workers": [{"id": 41, "desk_index": 2, "display_name": "Mabel", "employed": true, "assigned_lane": &"auto", "assignment_name": "Auto Dispatch", "secondary_specialty_name": "APPEALS & EXCEPTIONS"}],
		})
		_check(packing_annex.visual_state() == &"level_3", "third annex purchase should reveal premium dispatch staging", failures)
		_check(packing_annex.visible_carton_progress_slots() == 6, "full authoritative carton should illuminate all six mechanical slots", failures)
		for required_part in ["DispatchBoard", "ContractVault", "LoadingHatch", "PalletJack", "PremiumIndicator"]:
			_check(packing_annex.find_child(required_part, true, false) != null, "level-three packing annex should include %s" % required_part, failures)
		_check(_visible_meshes_fit_annex_envelope(packing_annex), "premium packing-annex staging should stay inside the declared footprint", failures)
	if service_coop != null:
		_check(service_coop.visual_state() == &"level_2", "Silver Service Coop ownership should retain Bronze and add dispatch hardware", failures)
		_check(service_coop.level_visible(1) and service_coop.level_visible(2) and not service_coop.level_visible(3), "Service Coop levels should reveal cumulatively", failures)
		_check(service_coop.standing_score() == 6 and service_coop.standing_rank() == &"silver", "Service Coop should consume the authoritative standing record", failures)
		_check(service_coop.visible_dispatch_packet_count() == 4, "Service Coop should materialize exactly four authoritative timely packets", failures)
		_check(service_coop.rush_beacon_active(), "active rush binder should illuminate the Silver dispatch beacon", failures)
	if contract_board != null:
		_check(contract_board.visual_state() == &"active", "canonical active contract should replace the idle terms rail with a bound strip", failures)
		_check(contract_board.active_contract_id() == &"fox_watch", "bound folder should retain the authoritative offer id", failures)
		_check(contract_board.active_stamp_visible(), "active contract should reveal its physical binding hardware", failures)
	if negotiation_room != null:
		_check(negotiation_room.visual_state() == &"owned" and negotiation_room.owned_room_visible(), "one-tier purchase should reveal the completed negotiation pavilion", failures)
		_check(negotiation_room.visible_clause_folio_count() == 4, "authoritative contract season should place four physical clause folios on the table", failures)
		_check(negotiation_room.active_clause_id() == &"staffed_roost_rider", "active rider clip should retain the authoritative clause id", failures)
		_check(negotiation_room.active_clause_category() == &"staffing", "active rider clip should retain the authoritative clause category", failures)
		_check(negotiation_room.active_rider_visible(), "authoritative active clause should reveal its hosted rider clip", failures)
		_check(negotiation_room.lit_delivery_pip_count() == 4 and negotiation_room.lit_seat_pip_count() == 4, "delivery and staffing pips should reflect snapshot values", failures)
		_check(not negotiation_room.premium_marker_visible() and not negotiation_room.breach_marker_visible(), "active contract without a result should keep both settlement trays empty", failures)
	if wellness_nest != null:
		_check(wellness_nest.visual_state() == &"level_3" and wellness_nest.visible_nest_count() == 6, "level-three Wellness purchase should retain all six recovery nests", failures)
		_check("STRAIN 76%" in wellness_nest.care_status_text() and "REST 150%" in wellness_nest.care_status_text(), "Wellness console should consume authoritative facility effects", failures)
	if training_roost != null:
		_check(training_roost.visual_state() == &"level_3" and training_roost.visible_terminal_count() == 3, "level-three Training purchase should retain all three practice terminals", failures)
		_check(training_roost.visible_credential_count() == 1, "Training gallery should show exactly the one authoritative earned specialty", failures)
	if rooster_operations != null:
		_check(rooster_operations.visual_state() == &"level_3" and rooster_operations.visible_supervisor_station_count() == 3, "level-three Rooster Operations should retain all three supervision stations", failures)
		_check(rooster_operations.assignment_worker_ids() == [41], "operations assignment rail should show exactly the authoritative worker", failures)
		_check(rooster_operations.active_directive_id() == &"quota_rush", "command gallery should retain the authoritative active directive", failures)
	if it_coop != null:
		_check(it_coop.visual_state() == &"level_3" and it_coop.visible_systems_unit_count() == 3, "level-three IT Coop should retain all three systems units", failures)
		_check(it_coop.auto_worker_ids() == [41], "IT patch bay should show exactly the authoritative AUTO worker", failures)
		_check(it_coop.patch_invoice_visible(), "IT tier three should show the authoritative ledger patch invoice", failures)
	if flock_relations != null:
		_check(flock_relations.visual_state() == &"level_3" and flock_relations.level_visible(1) and flock_relations.level_visible(2) and flock_relations.level_visible(3), "level-three Flock Relations should retain intake, mediation, and arbitration tiers", failures)
		_check(flock_relations.visible_case_folder_count() == 2 and flock_relations.open_case_ids() == [701, 702], "Flock Relations pigeonholes should materialize exactly the authoritative open case IDs", failures)
		_check(flock_relations.open_case_worker_ids() == [41, 52], "Flock Relations case folders should retain their authoritative worker IDs", failures)
		_check(flock_relations.resolution_docket_visible() and flock_relations.last_resolution_id() == &"file_pip", "Flock Relations tribunal should materialize only the authoritative last resolution", failures)
		_check(flock_relations.illuminated_outcome() == &"pip", "FILE PIP should illuminate only the PIP outcome lamp", failures)
		_check("OPEN 02/06" in flock_relations.relations_status_text() and "RESOLVED 004" in flock_relations.relations_status_text(), "Flock Relations console should consume the canonical aggregate counters", failures)
	if feed_procurement != null:
		_check(feed_procurement.visual_state() == &"level_3" and feed_procurement.level_visible(1) and feed_procurement.level_visible(2) and feed_procurement.level_visible(3), "level-three Feed Procurement should retain receiving, reserve, and futures tiers", failures)
		_check(feed_procurement.visible_stock_sack_count() == 2 and feed_procurement.lot_ids() == [301, 302], "Feed Procurement should materialize exactly the two authoritative active lots", failures)
		_check(feed_procurement.visible_offer_binder_count() == 2, "Feed Procurement should materialize exactly the two authoritative feed offers", failures)
		_check(is_equal_approx(feed_procurement.stock_fill_ratio(), 0.75) and feed_procurement.lit_reserve_segment_count() == 8, "Feed Procurement fill and reserve gauge should mirror authoritative stock", failures)
		_check("AUTUMN" in feed_procurement.quote_text() and "$2.20" in feed_procurement.quote_text(), "Feed Futures screen should consume the canonical season and quote", failures)
		_check(feed_procurement.spoilage_indicator_active(), "authoritative spoilage should illuminate the Feed Procurement warning", failures)
	_check(staging.visible_clutch_count() == 19, "snapshot reconciliation should materialize the authoritative current clutch", failures)
	var metrics := staging.find_child("ManagementYieldBoard", true, false) as Label3D
	_check(
		metrics != null
		and metrics.text.begins_with("YIELD")
		and "019 / 024" in metrics.text
		and "6:15 PM" in metrics.text,
		"yield board should reflect the current snapshot in its restrained live-display format",
		failures
	)

	var real_socket_origin := Vector3(6.0, 0.72, -3.75)
	var route := staging.collection_route_global(41, real_socket_origin)
	_check(route.size() == 6, "bound worker should receive a complete collection route", failures)
	_check(route[0].is_equal_approx(real_socket_origin), "egg route must begin at the real hen socket", failures)
	_check(
		route.size() == 6
		and is_equal_approx(route[2].y, OfficeStorytelling.COLLECTION_RAIL_HEIGHT)
		and is_equal_approx(route[3].y, OfficeStorytelling.COLLECTION_RAIL_HEIGHT)
		and is_equal_approx(route[4].y, OfficeStorytelling.COLLECTION_RAIL_HEIGHT),
		"pickup lift, row manifold, and grading approach should retain the exact overhead rail height",
		failures,
	)
	_check(route[route.size() - 1].is_equal_approx(Vector3(9.4, 1.25, -6.85)), "egg route should terminate in the farmer presentation basket", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_STORYTELLING_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_STORYTELLING_TEST_PASSED roots=20 desks=6 shell_qa=pad-to-owned packing_annex=lease-to-l3 records_annex=composed care_campus=locked-to-l3 farmer_relations=locked-to-l3 operations_campus=locked-to-l3 flock_relations=locked-to-l3 feed_procurement=locked-to-l3 contract_board=locked-to-active route=socket-to-farmer collisions=0")
	quit(0)


func _feed_procurement_snapshot(level: int, empty: bool = false) -> Dictionary:
	return {
		"facility_id": &"feed_procurement_coop",
		"level": level,
		"capacity_scoops": 40,
		"stock_scoops": 0 if empty else 30,
		"demand_scoops": 0 if empty else 4,
		"stock_after_demand_scoops": 0 if empty else 26,
		"spot_shortage_scoops": 0,
		"coverage_shifts": 0.0 if empty else 7.5,
		"season": {"id": &"autumn", "label": "Autumn", "start_day": 1, "end_day": 6, "days_remaining": 3, "price_basis_points": 11000},
		"charter": {"length_shifts": 3, "renewal_day": 4, "renewal_due": false},
		"base_spot_unit_price_cents": 200,
		"spot_unit_price_cents": 220,
		"spot_obligation_cents": 0,
		"order_limit": 1,
		"orders_used_today": 0 if empty else 1,
		"planning_open": true,
		"offers": [] if empty else [
			{"offer_id": &"barn_bulk", "label": "Barn Bulk"},
			{"offer_id": &"field_forward", "label": "Field Forward"},
		],
		"lots": [] if empty else [
			{"lot_id": 301, "offer_id": &"barn_bulk", "ordered_day": 1, "expires_day": 4, "scoops_initial": 12, "scoops_remaining": 7, "unit_cost_cents": 190, "total_cost_cents": 2280},
			{"lot_id": 302, "offer_id": &"field_forward", "ordered_day": 2, "expires_day": 6, "scoops_initial": 24, "scoops_remaining": 23, "unit_cost_cents": 205, "total_cost_cents": 4920},
		],
		"procurement_spend_today_cents": 0 if empty else 4920,
		"procurement_spend_total_cents": 0 if empty else 7200,
		"spot_spend_today_cents": 0,
		"spot_spend_total_cents": 0,
		"spoiled_today_scoops": 0 if empty else 2,
		"spoiled_total_scoops": 0 if empty else 2,
		"consumed_today_scoops": 0,
		"consumed_inventory_today_scoops": 0,
		"consumed_spot_today_scoops": 0,
		"consumed_value_today_cents": 0,
		"active_ration": {},
		"last_order": {} if empty else {"offer_id": &"field_forward", "label": "Field Forward", "scoops": 24, "total_cost_cents": 4920},
		"last_consumption": {},
	}


func _visible_meshes_fit_lab_envelope(shell_lab: ShellQualityLabVisual) -> bool:
	var footprint := ShellQualityLabVisualScript.declared_footprint()
	for node in shell_lab.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance.is_visible_in_tree() or mesh_instance.mesh == null:
			continue
		var bounds := mesh_instance.global_transform * mesh_instance.mesh.get_aabb()
		if bounds.position.x < footprint.position.x - 0.002:
			return false
		if bounds.end.x > footprint.end.x + 0.002:
			return false
		if bounds.position.z < footprint.position.y - 0.002:
			return false
		if bounds.end.z > footprint.end.y + 0.002:
			return false
		if bounds.end.y > ShellQualityLabVisualScript.MAX_OPAQUE_HEIGHT + 0.002:
			return false
	return true


func _visible_meshes_fit_annex_envelope(packing_annex: Node3D) -> bool:
	var footprint := PackingAnnexVisualScript.declared_footprint()
	for node in packing_annex.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance.is_visible_in_tree() or mesh_instance.mesh == null:
			continue
		var bounds := mesh_instance.global_transform * mesh_instance.mesh.get_aabb()
		if bounds.position.x < footprint.position.x - 0.002:
			return false
		if bounds.end.x > footprint.end.x + 0.002:
			return false
		if bounds.position.z < footprint.position.y - 0.002:
			return false
		if bounds.end.z > footprint.end.y + 0.002:
			return false
		if bounds.end.y > PackingAnnexVisualScript.MAX_OPAQUE_HEIGHT + 0.002:
			return false
	return true


func _multimesh_instance_total(root_node: Node, batch_name: String) -> int:
	var total := 0
	for candidate in root_node.find_children(batch_name, "MultiMeshInstance3D", true, false):
		var batch := candidate as MultiMeshInstance3D
		if batch != null and batch.multimesh != null:
			total += batch.multimesh.instance_count
	return total


func _find_multimesh_batch(root_node: Node, batch_name: String) -> MultiMeshInstance3D:
	var matches := root_node.find_children(batch_name, "MultiMeshInstance3D", true, false)
	return matches[0] as MultiMeshInstance3D if not matches.is_empty() else null


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
