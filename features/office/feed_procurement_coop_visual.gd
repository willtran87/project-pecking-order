class_name FeedProcurementCoopVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only provisions room. Equipment is cumulative, while
## grain, lot sacks, offer binders, prices, expiry, and spoilage are rendered
## only from the canonical `feed_procurement` projection.
const FACILITY_ID: StringName = &"feed_procurement_coop"
const FACILITY_CENTER := Vector3(7.30, 0.0, 30.00)
const FOCUS_POINT := Vector3(7.30, 1.50, 30.00)
const FOOTPRINT := Rect2(Vector2(4.10, 27.10), Vector2(6.40, 5.80))
const ENTRANCE_BRIDGE_FOOTPRINT := Rect2(Vector2(10.50, 29.40), Vector2(0.25, 1.20))
const CLEAR_AISLE_FOOTPRINT := Rect2(Vector2(8.20, 29.45), Vector2(2.55, 1.10))
const EAST_DOOR_WIDTH := 1.20
const MAX_LEVEL := 3
const MAX_VISUAL_HEIGHT := 4.05
const MAX_VISIBLE_LOTS := 8
const MAX_VISIBLE_OFFERS := 6
const RESERVE_GAUGE_SEGMENTS := 10

const DEEP_GRAIN_GREEN := Color("30463f")
const ENAMEL_TEAL := Color("426965")
const PALE_TEAL := Color("86a6a0")
const WHEAT := Color("d2aa5f")
const OATMEAL := Color("e3d6b7")
const PAPER := Color("eee4cc")
const GALVANIZED := Color("718184")
const STEEL := Color("536064")
const GRAPHITE := Color("2c3436")
const WALNUT := Color("68503c")
const BRASS := Color("b99a50")
const SAFETY_RUST := Color("a45c47")
const STATUS_GREEN := Color("719777")
const STATUS_AMBER := Color("d0a653")
const STATUS_RED := Color("a8564e")
const GLASS := Color(0.50, 0.64, 0.63, 0.34)

var locked_marker_root: Node3D
var survey_site_root: Node3D
var entrance_bridge_root: Node3D
var owned_room_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _hopper_fills: Array[MeshInstance3D] = []
var _reserve_segments: Array[MeshInstance3D] = []
var _stock_sack_root: Node3D
var _offer_binder_root: Node3D
var _last_order_root: Node3D
var _last_order_label: Label3D
var _status_label: Label3D
var _quote_label: Label3D
var _expiry_label: Label3D
var _expiry_lamp: MeshInstance3D
var _spoilage_lamp: MeshInstance3D

var _built := false
var _has_applied_snapshot := false
var _has_authoritative_procurement := false
var _unlocked := false
var _facility_level := 0
var _capacity_scoops := 0
var _stock_scoops := 0
var _demand_scoops := 0
var _stock_after_demand_scoops := 0
var _spot_shortage_scoops := 0
var _coverage_shifts := 0.0
var _spot_unit_price_cents := 0
var _spot_obligation_cents := 0
var _orders_used_today := 0
var _order_limit := 0
var _spoiled_today_scoops := 0
var _procurement_spend_today_cents := 0
var _season: Dictionary = {}
var _lots: Array[Dictionary] = []
var _offers: Array[Dictionary] = []
var _last_order: Dictionary = {}
var _last_procurement_render_snapshot: Dictionary = {}


func _ready() -> void:
	name = "FeedProcurementCoopVisual"
	position = FACILITY_CENTER
	set_meta(&"visual_only", true)
	set_meta(&"collision_free", true)
	set_meta(&"navigation_free", true)
	set_meta(&"declared_footprint", FOOTPRINT)
	set_meta(&"entrance_bridge_footprint", ENTRANCE_BRIDGE_FOOTPRINT)
	set_meta(&"clear_aisle_footprint", CLEAR_AISLE_FOOTPRINT)
	set_meta(&"facility_focus_point", FOCUS_POINT)
	if not _built:
		build()


static func declared_footprint() -> Rect2:
	return FOOTPRINT


static func facility_footprint() -> Rect2:
	return FOOTPRINT


static func entrance_bridge_footprint() -> Rect2:
	return ENTRANCE_BRIDGE_FOOTPRINT


static func clear_aisle_footprint() -> Rect2:
	return CLEAR_AISLE_FOOTPRINT


static func facility_focus_point() -> Vector3:
	return FOCUS_POINT


static func maximum_visual_height() -> float:
	return MAX_VISUAL_HEIGHT


func focus_point_global() -> Vector3:
	return to_global(Vector3(0.0, FOCUS_POINT.y, 0.0))


func build() -> void:
	clear()
	_built = true
	_build_locked_marker()
	_build_survey_site()
	_build_entrance_bridge()
	_build_owned_shell()
	_build_level_1()
	_build_level_2()
	_build_level_3()
	_apply_visibility()
	_apply_dynamic_state()


func clear() -> void:
	for visual_root in [
		locked_marker_root,
		survey_site_root,
		entrance_bridge_root,
		owned_room_root,
	]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	locked_marker_root = null
	survey_site_root = null
	entrance_bridge_root = null
	owned_room_root = null
	level_1_root = null
	level_2_root = null
	level_3_root = null
	_hopper_fills.clear()
	_reserve_segments.clear()
	_stock_sack_root = null
	_offer_binder_root = null
	_last_order_root = null
	_last_order_label = null
	_status_label = null
	_quote_label = null
	_expiry_label = null
	_expiry_lamp = null
	_spoilage_lamp = null
	_material_cache.clear()
	_has_applied_snapshot = false
	_has_authoritative_procurement = false
	_unlocked = false
	_facility_level = 0
	_capacity_scoops = 0
	_stock_scoops = 0
	_lots.clear()
	_offers.clear()
	_last_order.clear()
	_last_procurement_render_snapshot.clear()
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var previous_unlocked := _unlocked
	var procurement := _dictionary(snapshot.get("feed_procurement", {}))
	var catalog_entry := _catalog_entry(snapshot)
	_has_authoritative_procurement = not procurement.is_empty()
	_facility_level = clampi(_snapshot_level(snapshot, procurement, catalog_entry), 0, MAX_LEVEL)
	_unlocked = (
		_facility_level > 0
		or bool(catalog_entry.get("unlocked", catalog_entry.get("available", false)))
		or bool(catalog_entry.get("can_purchase", false))
	)
	_capacity_scoops = maxi(0, int(procurement.get("capacity_scoops", 0)))
	_stock_scoops = maxi(0, int(procurement.get("stock_scoops", 0)))
	_demand_scoops = maxi(0, int(procurement.get("demand_scoops", 0)))
	_stock_after_demand_scoops = maxi(0, int(procurement.get("stock_after_demand_scoops", 0)))
	_spot_shortage_scoops = maxi(0, int(procurement.get("spot_shortage_scoops", 0)))
	_coverage_shifts = maxf(0.0, float(procurement.get("coverage_shifts", 0.0)))
	_spot_unit_price_cents = maxi(0, int(procurement.get("spot_unit_price_cents", 0)))
	_spot_obligation_cents = maxi(0, int(procurement.get("spot_obligation_cents", 0)))
	_orders_used_today = maxi(0, int(procurement.get("orders_used_today", 0)))
	_order_limit = maxi(0, int(procurement.get("order_limit", 0)))
	_spoiled_today_scoops = maxi(0, int(procurement.get("spoiled_today_scoops", 0)))
	_procurement_spend_today_cents = maxi(0, int(procurement.get("procurement_spend_today_cents", 0)))
	_season = _dictionary(procurement.get("season", {})).duplicate(true)
	_lots = _dictionary_array(procurement.get("lots", []))
	_offers = _dictionary_array(procurement.get("offers", []))
	_last_order = _dictionary(procurement.get("last_order", {})).duplicate(true)
	_apply_visibility()
	# Claim progress and worker strain publish Office snapshots much more often
	# than this supply room changes. Rebuild sacks, binders, labels, and materials
	# only when the room's own authoritative projection or construction state moves.
	var procurement_changed := (
		not _has_applied_snapshot
		or procurement != _last_procurement_render_snapshot
		or _facility_level != previous_level
		or _unlocked != previous_unlocked
	)
	if procurement_changed:
		_apply_dynamic_state()
		_last_procurement_render_snapshot = procurement.duplicate(true)
	if _has_applied_snapshot and _facility_level > previous_level and is_inside_tree():
		for revealed_level in range(previous_level + 1, _facility_level + 1):
			_animate_reveal(revealed_level)
	_has_applied_snapshot = true


func visual_state() -> StringName:
	if _facility_level > 0:
		return StringName("level_%d" % _facility_level)
	return &"survey" if _unlocked else &"locked"


func current_level() -> int:
	return _facility_level


func level_visible(level: int) -> bool:
	var root_for_level := _level_root(level)
	return root_for_level != null and root_for_level.visible


func has_authoritative_procurement() -> bool:
	return _has_authoritative_procurement


func stock_scoops() -> int:
	return _stock_scoops


func capacity_scoops() -> int:
	return _capacity_scoops


func stock_fill_ratio() -> float:
	return clampf(float(_stock_scoops) / float(_capacity_scoops), 0.0, 1.0) if _capacity_scoops > 0 else 0.0


func visible_stock_sack_count() -> int:
	return _stock_sack_root.get_child_count() if _stock_sack_root != null else 0


func visible_offer_binder_count() -> int:
	return _offer_binder_root.get_child_count() if _offer_binder_root != null else 0


func lit_reserve_segment_count() -> int:
	return clampi(roundi(stock_fill_ratio() * RESERVE_GAUGE_SEGMENTS), 0, RESERVE_GAUGE_SEGMENTS)


func quote_text() -> String:
	return _quote_label.text if _quote_label != null else ""


func status_text() -> String:
	return _status_label.text if _status_label != null else ""


func expiry_text() -> String:
	return _expiry_label.text if _expiry_label != null else ""


func spoilage_indicator_active() -> bool:
	return _has_authoritative_procurement and _spoiled_today_scoops > 0


func lot_ids() -> Array[int]:
	var result: Array[int] = []
	if _stock_sack_root == null:
		return result
	for sack in _stock_sack_root.get_children():
		result.append(int(sack.get_meta(&"lot_id", -1)))
	return result


func geometry_bounds_inside_footprint() -> bool:
	var local_half := FOOTPRINT.size * 0.5
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or _is_connector_geometry(instance):
			continue
		for corner in _mesh_corners_in_visual_space(instance):
			if absf(corner.x) > local_half.x + tolerance or absf(corner.z) > local_half.y + tolerance or corner.y > MAX_VISUAL_HEIGHT + tolerance:
				return false
	return true


func connector_geometry_inside_bridge() -> bool:
	var found := false
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or not _is_connector_geometry(instance):
			continue
		found = true
		for corner in _mesh_corners_in_visual_space(instance):
			var world_xz := Vector2(corner.x + FACILITY_CENTER.x, corner.z + FACILITY_CENTER.z)
			if world_xz.x < ENTRANCE_BRIDGE_FOOTPRINT.position.x - tolerance or world_xz.x > ENTRANCE_BRIDGE_FOOTPRINT.end.x + tolerance or world_xz.y < ENTRANCE_BRIDGE_FOOTPRINT.position.y - tolerance or world_xz.y > ENTRANCE_BRIDGE_FOOTPRINT.end.y + tolerance:
				return false
	return found


func circulation_clear() -> bool:
	var aisle_local := Rect2(CLEAR_AISLE_FOOTPRINT.position - Vector2(FACILITY_CENTER.x, FACILITY_CENTER.z), CLEAR_AISLE_FOOTPRINT.size)
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := _mesh_bounds_in_visual_space(instance)
		if bounds.end.y <= 0.08 or bounds.position.y >= 2.45:
			continue
		var xz := Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z))
		if xz.intersects(aisle_local):
			return false
	return true


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "FeedProcurementLockedParcel"
	locked_marker_root.set_meta(&"visual_only", true)
	locked_marker_root.set_meta(&"collision_free", true)
	locked_marker_root.set_meta(&"navigation_free", true)
	add_child(locked_marker_root)
	for z in [-2.72, 2.72]:
		_add_box(locked_marker_root, "ProvisionsLeaseLineZ", Vector3(6.08, 0.035, 0.055), Vector3(0.0, 0.025, z), BRASS.darkened(0.24))
	for x in [-3.02, 3.02]:
		for z in [-1.70, 1.70]:
			_add_box(locked_marker_root, "ProvisionsLeaseLineX", Vector3(0.055, 0.035, 1.94), Vector3(x, 0.025, z), BRASS.darkened(0.24))
	var host := _add_box(locked_marker_root, "ProvisionsLeaseNoticeHost", Vector3(3.50, 0.88, 0.10), Vector3(-0.30, 1.10, 2.56), DEEP_GRAIN_GREEN)
	EnvironmentalSignageScript.add_panel(host, "ProvisionsLeaseNotice", "PROVISIONS PARCEL\nGRAIN CHARTER REQUIRED", Vector3(0.0, 0.0, 0.058), Vector2(3.20, 0.66), DEEP_GRAIN_GREEN, PAPER, Vector3.ZERO, 13, 0.0025, &"secondary", &"paper")


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "FeedProcurementSurveySite"
	survey_site_root.set_meta(&"visual_only", true)
	survey_site_root.set_meta(&"collision_free", true)
	survey_site_root.set_meta(&"navigation_free", true)
	add_child(survey_site_root)
	_add_box(survey_site_root, "ProvisionsSurveyMat", Vector3(6.08, 0.035, 5.48), Vector3.ZERO, GRAPHITE.lightened(0.10))
	for center in [Vector3(-2.10, 0.028, 0.70), Vector3(-0.75, 0.028, 0.70), Vector3(-2.10, 0.028, -1.55)]:
		_add_ring(survey_site_root, "SurveyedHopperRing", center, 0.50, 0.58, WHEAT.darkened(0.22))
	var board := _add_box(survey_site_root, "ProvisionsSurveyBoardHost", Vector3(2.80, 0.82, 0.10), Vector3(-1.10, 1.05, 2.55), ENAMEL_TEAL)
	EnvironmentalSignageScript.add_panel(board, "ProvisionsSurveyBoard", "FLOCK PROVISIONS CO-OP\nRECEIVING PLAN FILED", Vector3(0.0, 0.0, 0.058), Vector2(2.52, 0.60), ENAMEL_TEAL, PAPER, Vector3.ZERO, 13, 0.00245, &"secondary", &"paper")


func _build_entrance_bridge() -> void:
	entrance_bridge_root = Node3D.new()
	entrance_bridge_root.name = "FeedProcurementEntranceBridge"
	entrance_bridge_root.set_meta(&"visual_only", true)
	entrance_bridge_root.set_meta(&"collision_free", true)
	entrance_bridge_root.set_meta(&"navigation_free", true)
	entrance_bridge_root.set_meta(&"campus_connector", true)
	entrance_bridge_root.set_meta(&"declared_footprint", ENTRANCE_BRIDGE_FOOTPRINT)
	add_child(entrance_bridge_root)
	_add_box(entrance_bridge_root, "ProvisionsBridgeDeck", Vector3(0.25, 0.12, 1.18), Vector3(3.325, -0.055, 0.0), GRAPHITE.lightened(0.18))
	for z in [-0.54, 0.54]:
		_add_box(entrance_bridge_root, "ProvisionsBridgeBrassEdge", Vector3(0.23, 0.025, 0.035), Vector3(3.325, 0.015, z), BRASS, 0.48, 0.38)


func _build_owned_shell() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "FeedProcurementOwnedRoom"
	owned_room_root.set_meta(&"visual_only", true)
	owned_room_root.set_meta(&"collision_free", true)
	owned_room_root.set_meta(&"navigation_free", true)
	add_child(owned_room_root)
	_add_box(owned_room_root, "ProvisionsFoundation", Vector3(6.16, 0.16, 5.56), Vector3(0.0, -0.08, 0.0), GRAPHITE.lightened(0.06))
	_add_box(owned_room_root, "ProvisionsFloorInset", Vector3(5.90, 0.035, 5.30), Vector3(0.0, 0.018, 0.0), DEEP_GRAIN_GREEN.lightened(0.08))
	_add_box(owned_room_root, "ReceivingApron", Vector3(2.24, 0.025, 1.02), Vector3(1.96, 0.024, 0.0), GALVANIZED.darkened(0.12))
	for x in [-3.02, 3.02]:
		for z in [-2.70, 2.70]:
			_add_box(owned_room_root, "ProvisionsStructuralPost", Vector3(0.12, 3.20, 0.12), Vector3(x, 1.60, z), DEEP_GRAIN_GREEN)
	# Split the east wall around the exact 1.20m route opening.
	for z in [-1.66, 1.66]:
		_add_glass_box(owned_room_root, "ProvisionsEastGlassWing", Vector3(0.035, 2.18, 1.88), Vector3(3.00, 1.20, z))
	_add_box(owned_room_root, "ProvisionsEastDoorHeader", Vector3(0.14, 0.15, EAST_DOOR_WIDTH + 0.18), Vector3(3.00, 2.58, 0.0), BRASS.darkened(0.10), 0.48, 0.30)
	# East-facing, host-integrated destination identity remains readable from the spine.
	var identity_host := _add_box(owned_room_root, "FeedProcurementIdentityHost", Vector3(0.10, 0.58, 4.80), Vector3(3.01, 2.86, 0.0), DEEP_GRAIN_GREEN)
	EnvironmentalSignageScript.add_panel(identity_host, "FeedProcurementIdentity", "FLOCK PROVISIONS CO-OP\nFEED PROCUREMENT & RESERVE", Vector3(0.058, 0.0, 0.0), Vector2(4.48, 0.42), DEEP_GRAIN_GREEN, PAPER, Vector3(0.0, 90.0, 0.0), 14, 0.0027, &"primary", &"destination")


func _build_level_1() -> void:
	level_1_root = Node3D.new()
	level_1_root.name = "ReceivingHopperTier"
	level_1_root.set_meta(&"facility_level", 1)
	owned_room_root.add_child(level_1_root)
	_build_hopper(level_1_root, "ReceivingHopper", Vector3(-2.18, 0.0, 0.78), 1, 2.12)
	var desk := _add_box(level_1_root, "ReceivingDesk", Vector3(1.48, 0.76, 0.72), Vector3(-0.15, 0.38, -2.02), WALNUT)
	_add_box(level_1_root, "ReceivingDeskTop", Vector3(1.66, 0.11, 0.84), Vector3(-0.15, 0.82, -2.02), OATMEAL)
	var plate := _add_box(desk, "ReceivingDeskPlateHost", Vector3(1.14, 0.23, 0.045), Vector3(0.0, 0.05, 0.386), DEEP_GRAIN_GREEN)
	EnvironmentalSignageScript.add_panel(plate, "ReceivingHopperTierPlate", "RECEIVING HOPPER", Vector3(0.0, 0.0, 0.030), Vector2(1.02, 0.15), DEEP_GRAIN_GREEN, PAPER, Vector3.ZERO, 10, 0.0019, &"utility", &"machine")
	_add_box(level_1_root, "ReceivingScaleDeck", Vector3(1.36, 0.12, 0.90), Vector3(-0.42, 0.09, -0.90), GALVANIZED, 0.62, 0.22)
	_add_box(level_1_root, "ReceivingScaleColumn", Vector3(0.16, 1.06, 0.16), Vector3(-0.92, 0.61, -0.90), STEEL, 0.54, 0.30)
	var status_host := _add_box(level_1_root, "ProcurementStatusHost", Vector3(1.52, 0.72, 0.10), Vector3(-0.10, 1.48, -2.54), GRAPHITE)
	_status_label = EnvironmentalSignageScript.add_panel(status_host, "ProcurementStatusScreen", "AWAITING FEED BOOK", Vector3(0.0, 0.0, 0.058), Vector2(1.36, 0.56), GRAPHITE, PALE_TEAL, Vector3.ZERO, 11, 0.0021, &"utility", &"screen", true)
	_stock_sack_root = Node3D.new()
	_stock_sack_root.name = "AuthoritativeGrainLotSacks"
	_stock_sack_root.position = Vector3(-0.10, 0.0, 2.03)
	level_1_root.add_child(_stock_sack_root)


func _build_level_2() -> void:
	level_2_root = Node3D.new()
	level_2_root.name = "DryGrainReserveTier"
	level_2_root.set_meta(&"facility_level", 2)
	owned_room_root.add_child(level_2_root)
	_build_hopper(level_2_root, "DryReserveHopper", Vector3(-0.82, 0.0, 0.86), 2, 2.58)
	# The auger stays entirely above the 2.45m circulation volume.
	_add_cylinder(level_2_root, "DryReserveAugerTube", Vector3(-1.48, 2.78, 0.82), 0.13, 2.08, GALVANIZED, 0.46, 0.32).rotation_degrees.z = 90.0
	_add_cylinder(level_2_root, "DryReserveAugerMotor", Vector3(-0.42, 2.78, 0.82), 0.27, 0.42, ENAMEL_TEAL, 0.52, 0.22).rotation_degrees.x = 90.0
	var cabinet := _add_box(level_2_root, "SupplierBinderCabinet", Vector3(0.72, 1.70, 0.52), Vector3(0.32, 0.85, 2.18), STEEL)
	var plate := _add_box(cabinet, "DryReservePlateHost", Vector3(0.60, 0.25, 0.04), Vector3(0.0, 0.55, -0.282), DEEP_GRAIN_GREEN)
	EnvironmentalSignageScript.add_panel(plate, "DryGrainReserveTierPlate", "DRY GRAIN RESERVE", Vector3(0.0, 0.0, -0.028), Vector2(0.52, 0.17), DEEP_GRAIN_GREEN, PAPER, Vector3(0.0, 180.0, 0.0), 9, 0.0017, &"utility", &"machine")
	_offer_binder_root = Node3D.new()
	_offer_binder_root.name = "AuthoritativeFeedOfferBinders"
	_offer_binder_root.position = Vector3(0.32, 0.0, 1.88)
	level_2_root.add_child(_offer_binder_root)
	var expiry_host := _add_box(level_2_root, "ExpiryRailHost", Vector3(1.52, 0.38, 0.08), Vector3(-0.40, 2.12, -2.57), GRAPHITE)
	_expiry_label = EnvironmentalSignageScript.add_panel(expiry_host, "FeedExpiryRail", "EXPIRY --", Vector3(0.0, 0.0, 0.050), Vector2(1.34, 0.27), GRAPHITE, STATUS_AMBER, Vector3.ZERO, 10, 0.0019, &"utility", &"screen", true)
	_expiry_lamp = _add_box(level_2_root, "FeedExpiryLamp", Vector3(0.18, 0.18, 0.08), Vector3(-1.26, 2.12, -2.56), GRAPHITE)
	_spoilage_lamp = _add_box(level_2_root, "FeedSpoilageLamp", Vector3(0.18, 0.18, 0.08), Vector3(0.46, 2.12, -2.56), GRAPHITE)


func _build_level_3() -> void:
	level_3_root = Node3D.new()
	level_3_root.name = "FeedFuturesDeskTier"
	level_3_root.set_meta(&"facility_level", 3)
	owned_room_root.add_child(level_3_root)
	_build_reserve_silo(level_3_root)
	var climate := _add_box(level_3_root, "GrainClimateCabinet", Vector3(0.90, 1.68, 0.62), Vector3(0.16, 0.84, 1.32), ENAMEL_TEAL)
	for vent in 3:
		_add_box(climate, "ClimateVent_%02d" % (vent + 1), Vector3(0.66, 0.08, 0.035), Vector3(0.0, 0.36 - vent * 0.20, -0.328), GALVANIZED)
	var futures_desk := _add_box(level_3_root, "FeedFuturesDesk", Vector3(1.38, 0.74, 0.70), Vector3(0.05, 0.37, -1.46), WALNUT)
	_add_box(level_3_root, "FeedFuturesDeskTop", Vector3(1.54, 0.10, 0.82), Vector3(0.05, 0.79, -1.46), OATMEAL)
	var plate := _add_box(futures_desk, "FeedFuturesPlateHost", Vector3(1.12, 0.23, 0.045), Vector3(0.0, 0.05, 0.376), DEEP_GRAIN_GREEN)
	EnvironmentalSignageScript.add_panel(plate, "FeedFuturesDeskTierPlate", "FEED FUTURES DESK", Vector3(0.0, 0.0, 0.030), Vector2(1.00, 0.15), DEEP_GRAIN_GREEN, PAPER, Vector3.ZERO, 9, 0.0018, &"utility", &"machine")
	var quote_host := _add_box(level_3_root, "FeedFuturesQuoteHost", Vector3(2.20, 0.82, 0.10), Vector3(0.00, 1.65, -2.55), GRAPHITE)
	_quote_label = EnvironmentalSignageScript.add_panel(quote_host, "FeedFuturesQuoteScreen", "SPOT QUOTE --", Vector3(0.0, 0.0, 0.058), Vector2(2.02, 0.66), GRAPHITE, PALE_TEAL, Vector3.ZERO, 11, 0.0021, &"utility", &"screen", true)
	_last_order_root = Node3D.new()
	_last_order_root.name = "AuthoritativeLastFeedOrder"
	_last_order_root.position = Vector3(0.78, 0.92, -1.38)
	level_3_root.add_child(_last_order_root)
	var order_host := _add_box(_last_order_root, "LastFeedOrderReceiptHost", Vector3(0.74, 0.52, 0.045), Vector3.ZERO, PAPER)
	_last_order_label = EnvironmentalSignageScript.add_panel(order_host, "LastFeedOrderReceipt", "NO ORDER FILED", Vector3(0.0, 0.0, 0.030), Vector2(0.66, 0.43), PAPER, DEEP_GRAIN_GREEN, Vector3.ZERO, 8, 0.0015, &"utility", &"paper")


func _build_hopper(parent: Node3D, prefix: String, center: Vector3, required_level: int, height: float) -> void:
	var hopper := Node3D.new()
	hopper.name = prefix
	hopper.position = center
	parent.add_child(hopper)
	_add_cylinder(hopper, "%sShell" % prefix, Vector3(0.0, 1.02, 0.0), 0.57, 1.46, GLASS, 0.24, 0.05)
	_add_cylinder(hopper, "%sTopBand" % prefix, Vector3(0.0, 1.75, 0.0), 0.62, 0.12, GALVANIZED, 0.44, 0.38)
	_add_cylinder(hopper, "%sBottomBand" % prefix, Vector3(0.0, 0.30, 0.0), 0.62, 0.12, GALVANIZED, 0.44, 0.38)
	var cone := _add_cylinder(hopper, "%sDischargeCone" % prefix, Vector3(0.0, 0.14, 0.0), 0.42, 0.30, WHEAT.darkened(0.26), 0.76)
	cone.scale = Vector3(1.0, 1.0, 1.0)
	for angle in [45.0, 135.0, 225.0, 315.0]:
		var radians := deg_to_rad(angle)
		_add_box(hopper, "%sLeg" % prefix, Vector3(0.08, 0.72, 0.08), Vector3(cos(radians) * 0.45, 0.36, sin(radians) * 0.45), STEEL, 0.50, 0.30)
	var fill := _add_cylinder(hopper, "%sAuthoritativeFill" % prefix, Vector3(0.0, 0.34, 0.0), 0.48, 1.34, WHEAT, 0.92)
	fill.visible = false
	fill.set_meta(&"fill_bottom", 0.34)
	fill.set_meta(&"fill_height", 1.34)
	fill.set_meta(&"required_level", required_level)
	_hopper_fills.append(fill)
	# A height-specific crown lets level two read taller without a duplicate roof grid.
	if height > 2.2:
		_add_cylinder(hopper, "%sCrown" % prefix, Vector3(0.0, 1.94, 0.0), 0.42, height - 2.0, ENAMEL_TEAL, 0.58, 0.12)


func _build_reserve_silo(parent: Node3D) -> void:
	var silo := Node3D.new()
	silo.name = "StrategicReserveSilo"
	silo.position = Vector3(-2.14, 0.0, -1.56)
	parent.add_child(silo)
	_add_cylinder(silo, "ReserveSiloBody", Vector3(0.0, 1.80, 0.0), 0.70, 3.18, GALVANIZED, 0.46, 0.32)
	_add_cylinder(silo, "ReserveSiloCrown", Vector3(0.0, 3.45, 0.0), 0.60, 0.30, ENAMEL_TEAL, 0.52, 0.18)
	_add_cylinder(silo, "ReserveSiloCap", Vector3(0.0, 3.66, 0.0), 0.36, 0.14, BRASS, 0.46, 0.42)
	for y in [0.42, 1.30, 2.18, 3.06]:
		_add_ring(silo, "ReserveSiloBand", Vector3(0.0, y, 0.0), 0.68, 0.75, BRASS.darkened(0.08))
	for rung in 7:
		_add_box(silo, "ReserveSiloLadderRung_%02d" % (rung + 1), Vector3(0.44, 0.045, 0.055), Vector3(-0.54, 0.62 + rung * 0.38, 0.0), STEEL, 0.48, 0.32)
	for x in [-0.76, -0.32]:
		_add_box(silo, "ReserveSiloLadderRail", Vector3(0.055, 2.78, 0.055), Vector3(x, 1.76, 0.0), STEEL, 0.48, 0.32)
	var fill := _add_cylinder(silo, "ReserveSiloAuthoritativeFill", Vector3(0.0, 0.28, 0.0), 0.61, 2.96, WHEAT, 0.92)
	fill.visible = false
	fill.set_meta(&"fill_bottom", 0.28)
	fill.set_meta(&"fill_height", 2.96)
	fill.set_meta(&"required_level", 3)
	_hopper_fills.append(fill)
	var gauge_host := _add_box(silo, "ReserveGaugeHost", Vector3(0.34, 2.50, 0.10), Vector3(0.72, 1.72, 0.0), GRAPHITE)
	for segment in RESERVE_GAUGE_SEGMENTS:
		var marker := _add_box(gauge_host, "ReserveGaugeSegment_%02d" % (segment + 1), Vector3(0.20, 0.17, 0.035), Vector3(0.0, -1.03 + segment * 0.22, 0.068), GRAPHITE.darkened(0.08))
		_reserve_segments.append(marker)


func _apply_visibility() -> void:
	if locked_marker_root != null:
		locked_marker_root.visible = not _unlocked and _facility_level <= 0
	if survey_site_root != null:
		survey_site_root.visible = _unlocked and _facility_level <= 0
	if entrance_bridge_root != null:
		entrance_bridge_root.visible = _unlocked or _facility_level > 0
	if owned_room_root != null:
		owned_room_root.visible = _facility_level > 0
	if level_1_root != null:
		level_1_root.visible = _facility_level >= 1
	if level_2_root != null:
		level_2_root.visible = _facility_level >= 2
	if level_3_root != null:
		level_3_root.visible = _facility_level >= 3


func _apply_dynamic_state() -> void:
	var ratio := stock_fill_ratio() if _has_authoritative_procurement else 0.0
	for fill in _hopper_fills:
		var required_level := int(fill.get_meta(&"required_level", 1))
		var height := float(fill.get_meta(&"fill_height", 1.0))
		var bottom := float(fill.get_meta(&"fill_bottom", 0.0))
		fill.visible = _has_authoritative_procurement and _facility_level >= required_level and ratio > 0.001
		fill.scale.y = maxf(0.001, ratio)
		fill.position.y = bottom + height * ratio * 0.5
	for segment_index in _reserve_segments.size():
		_reserve_segments[segment_index].material_override = _emissive_material(WHEAT, 0.64) if segment_index < lit_reserve_segment_count() and _has_authoritative_procurement else _material(GRAPHITE.darkened(0.08), 0.70)
	_rebuild_stock_sacks()
	_rebuild_offer_binders()
	_update_labels()


func _update_labels() -> void:
	if _status_label != null:
		_status_label.text = (
			"STOCK %02d/%02d  DEMAND %02d\nAFTER %02d  SPOT %02d  COVER %.1f" % [_stock_scoops, _capacity_scoops, _demand_scoops, _stock_after_demand_scoops, _spot_shortage_scoops, _coverage_shifts]
			if _has_authoritative_procurement else "AWAITING FEED BOOK"
		)
		EnvironmentalSignageScript.refit_label(_status_label)
	if _quote_label != null:
		var season_label := String(_season.get("label", "UNFILED")).to_upper()
		_quote_label.text = (
			"%s  SPOT $%.2f/SCOOP\nOBLIGATION $%.2f  ORDERS %d/%d" % [season_label, float(_spot_unit_price_cents) / 100.0, float(_spot_obligation_cents) / 100.0, _orders_used_today, _order_limit]
			if _has_authoritative_procurement else "SPOT QUOTE --"
		)
		EnvironmentalSignageScript.refit_label(_quote_label)
	var next_expiry := _next_expiry_day()
	if _expiry_label != null:
		_expiry_label.text = (
			("NEXT EXP D%02d  /  SPOILED %02d" % [next_expiry, _spoiled_today_scoops])
			if _has_authoritative_procurement and next_expiry >= 0 else
			("NO ACTIVE LOTS  /  SPOILED %02d" % _spoiled_today_scoops if _has_authoritative_procurement else "EXPIRY --")
		)
		EnvironmentalSignageScript.refit_label(_expiry_label)
	if _expiry_lamp != null:
		_expiry_lamp.material_override = _emissive_material(STATUS_AMBER, 0.70) if _has_authoritative_procurement and next_expiry >= 0 else _material(GRAPHITE, 0.70)
	if _spoilage_lamp != null:
		_spoilage_lamp.material_override = _emissive_material(STATUS_RED, 0.88) if spoilage_indicator_active() else _material(GRAPHITE, 0.70)
	if _last_order_root != null:
		_last_order_root.visible = _facility_level >= 3 and _has_authoritative_procurement and not _last_order.is_empty()
	if _last_order_label != null and not _last_order.is_empty():
		var label := String(_last_order.get("label", _last_order.get("offer_label", _last_order.get("offer_id", "FEED ORDER")))).to_upper()
		var scoops := maxi(0, int(_last_order.get("scoops", _last_order.get("scoops_ordered", 0))))
		var cost := maxi(0, int(_last_order.get("total_cost_cents", _last_order.get("cost_cents", 0))))
		_last_order_label.text = "%s\n%02d SCOOPS / $%.2f" % [label, scoops, float(cost) / 100.0]
		EnvironmentalSignageScript.refit_label(_last_order_label)


func _rebuild_stock_sacks() -> void:
	if _stock_sack_root == null:
		return
	for child in _stock_sack_root.get_children():
		child.free()
	if not _has_authoritative_procurement or _facility_level < 1:
		return
	var visible_lots: Array[Dictionary] = []
	for lot in _lots:
		if int(lot.get("scoops_remaining", 0)) > 0:
			visible_lots.append(lot)
		if visible_lots.size() >= MAX_VISIBLE_LOTS:
			break
	for index in visible_lots.size():
		var lot := visible_lots[index]
		var sack := Node3D.new()
		sack.name = "AuthoritativeGrainLotSack_%02d" % (index + 1)
		sack.position = Vector3(-1.14 + (index % 4) * 0.72, 0.38 + int(index / 4) * 0.72, 0.0)
		sack.set_meta(&"authoritative_record", true)
		for key in ["lot_id", "offer_id", "ordered_day", "expires_day", "scoops_initial", "scoops_remaining", "unit_cost_cents", "total_cost_cents"]:
			sack.set_meta(StringName(key), lot.get(key))
		_stock_sack_root.add_child(sack)
		var body := _add_sphere(sack, "GrainLotSackBody", Vector3.ZERO, Vector3(0.48, 0.58, 0.25), OATMEAL, 0.96)
		_add_cylinder(sack, "GrainLotSackTie", Vector3(0.0, 0.34, 0.0), 0.08, 0.16, WALNUT, 0.82)
		EnvironmentalSignageScript.add_panel(body, "GrainLotSackLabel_%02d" % (index + 1), "LOT %03d\nEXP D%02d" % [maxi(0, int(lot.get("lot_id", 0))), maxi(0, int(lot.get("expires_day", 0)))], Vector3(0.0, 0.0, 0.27), Vector2(0.36, 0.24), OATMEAL, DEEP_GRAIN_GREEN, Vector3.ZERO, 8, 0.0015, &"utility", &"shipping")


func _rebuild_offer_binders() -> void:
	if _offer_binder_root == null:
		return
	for child in _offer_binder_root.get_children():
		child.free()
	if not _has_authoritative_procurement or _facility_level < 2:
		return
	for index in mini(_offers.size(), MAX_VISIBLE_OFFERS):
		var offer := _offers[index]
		var binder := Node3D.new()
		binder.name = "AuthoritativeFeedOfferBinder_%02d" % (index + 1)
		binder.position = Vector3(-0.20 + (index % 2) * 0.40, 0.34 + int(index / 2) * 0.42, 0.0)
		binder.set_meta(&"authoritative_record", true)
		binder.set_meta(&"offer_id", StringName(String(offer.get("offer_id", offer.get("id", "")))))
		binder.set_meta(&"source_record", offer.duplicate(true))
		_offer_binder_root.add_child(binder)
		_add_box(binder, "FeedOfferBinderCover", Vector3(0.30, 0.34, 0.055), Vector3.ZERO, [ENAMEL_TEAL, WHEAT.darkened(0.18), SAFETY_RUST.darkened(0.10)][index % 3])


func _next_expiry_day() -> int:
	var result := -1
	for lot in _lots:
		if int(lot.get("scoops_remaining", 0)) <= 0:
			continue
		var day := int(lot.get("expires_day", -1))
		if day >= 0 and (result < 0 or day < result):
			result = day
	return result


func _snapshot_level(snapshot: Dictionary, procurement: Dictionary, catalog_entry: Dictionary) -> int:
	if procurement.has("level"):
		return int(procurement.get("level", 0))
	var owned := _dictionary(snapshot.get("owned_facilities", {}))
	if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
		return int(owned.get(FACILITY_ID, owned.get(String(FACILITY_ID), 0)))
	return int(catalog_entry.get("level", catalog_entry.get("owned_level", 0)))


func _catalog_entry(snapshot: Dictionary) -> Dictionary:
	var catalog: Variant = snapshot.get("facility_catalog", [])
	if catalog is Array:
		for value in catalog as Array:
			if value is Dictionary and StringName(String((value as Dictionary).get("id", ""))) == FACILITY_ID:
				return value as Dictionary
	elif catalog is Dictionary:
		var entry: Variant = (catalog as Dictionary).get(FACILITY_ID, (catalog as Dictionary).get(String(FACILITY_ID), {}))
		if entry is Dictionary:
			return entry as Dictionary
	return {}


func _dictionary(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item in value as Array:
			if item is Dictionary:
				result.append((item as Dictionary).duplicate(true))
	return result


func _level_root(level: int) -> Node3D:
	match level:
		1: return level_1_root
		2: return level_2_root
		3: return level_3_root
	return null


func _animate_reveal(level: int) -> void:
	var root := _level_root(level)
	if root == null:
		return
	root.scale = Vector3(1.0, 0.08, 1.0)
	var tween := create_tween().bind_node(root)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "scale", Vector3.ONE, 0.46)


func _is_connector_geometry(instance: MeshInstance3D) -> bool:
	var cursor: Node = instance
	while cursor != null and cursor != self:
		if bool(cursor.get_meta(&"campus_connector", false)):
			return true
		cursor = cursor.get_parent()
	return false


func _mesh_corners_in_visual_space(instance: MeshInstance3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var bounds := instance.mesh.get_aabb()
	for x in [bounds.position.x, bounds.end.x]:
		for y in [bounds.position.y, bounds.end.y]:
			for z in [bounds.position.z, bounds.end.z]:
				result.append(to_local(instance.to_global(Vector3(x, y, z))))
	return result


func _mesh_bounds_in_visual_space(instance: MeshInstance3D) -> AABB:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for corner in _mesh_corners_in_visual_space(instance):
		minimum = minimum.min(corner)
		maximum = maximum.max(corner)
	return AABB(minimum, maximum - minimum)


func _add_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3, color: Color, roughness: float = 0.82, metallic: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_cylinder(parent: Node3D, part_name: String, part_position: Vector3, radius: float, height: float, color: Color, roughness: float = 0.82, metallic: float = 0.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_sphere(parent: Node3D, part_name: String, part_position: Vector3, part_scale: Vector3, color: Color, roughness: float = 0.82) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 20
	mesh.rings = 12
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color, roughness)
	parent.add_child(instance)
	return instance


func _add_ring(parent: Node3D, part_name: String, part_position: Vector3, inner_radius: float, outer_radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 32
	mesh.ring_segments = 8
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, 0.68, 0.18)
	parent.add_child(instance)
	return instance


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, GLASS, 0.22, 0.02)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glass


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.3f|%.3f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive|%s|%.3f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.34)
	material.roughness = 0.46
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	_material_cache[key] = material
	return material
