class_name FarmgateDispatchDepotVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only output yard. The module deliberately avoids the
## campus glass-office kit: it grows from a low farmstand canopy into a cold dock
## and finally a truck yard with a tall dispatch landmark. Stock, route terms,
## aging, overflow, spoilage, and the last manifest only mirror an authoritative
## compact projection; construction never invents an egg or packed case.
const FACILITY_ID: StringName = &"farmgate_dispatch_depot"
const DISPLAY_NAME := "FARMGATE DISPATCH DEPOT"
const FACILITY_CENTER := Vector3(23.05, 0.0, -3.00)
const FOCUS_POINT := Vector3(23.05, 1.25, -3.00)
const FOOTPRINT := Rect2(Vector2(18.65, -8.90), Vector2(8.80, 11.80))
const ENTRANCE_BRIDGE_FOOTPRINT := Rect2(Vector2(18.40, -6.60), Vector2(0.25, 1.20))
const CLEAR_AISLE_FOOTPRINT := Rect2(Vector2(18.40, -6.55), Vector2(3.10, 1.10))
const VEHICLE_LANE_FOOTPRINT := Rect2(Vector2(23.70, -8.55), Vector2(3.35, 10.90))
const MAX_LEVEL := 3
const MAX_VISUAL_HEIGHT := 5.55
const LEVEL_ONE_STORAGE_CELLS := 12
const LEVEL_TWO_STORAGE_CELLS := 24
const LEVEL_THREE_STORAGE_CELLS := 42

const WEATHERED_CONCRETE := Color("686c66")
const DARK_CONCRETE := Color("454b48")
const BARN_RED := Color("934c3e")
const DEEP_BARN_RED := Color("65372f")
const BOARD_RED := Color("a65b48")
const TIMBER := Color("77563a")
const DARK_TIMBER := Color("4d392c")
const CREAM_CANVAS := Color("e4d7b7")
const OATMEAL := Color("d6c59e")
const KRAFT := Color("ad8250")
const DARK_KRAFT := Color("795a39")
const GALVANIZED := Color("7e8988")
const PALE_GALVANIZED := Color("a8b0ac")
const COLD_STEEL := Color("536365")
const GRAPHITE := Color("293234")
const BLACK_RUBBER := Color("1f2424")
const STRAW := Color("d2a64d")
const BRASS := Color("bd9a4e")
const PAPER := Color("eee3c7")
const ROUTE_GREEN := Color("496d5b")
const STATUS_GREEN := Color("78a47a")
const STATUS_AMBER := Color("d2a34e")
const STATUS_RED := Color("b45145")
const REFRIGERATOR_WHITE := Color("d8ddd2")

var locked_marker_root: Node3D
var survey_site_root: Node3D
var entrance_bridge_root: Node3D
var owned_site_root: Node3D
var level_1_root: Node3D
var level_2_root: Node3D
var level_3_root: Node3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _case_crates: Array[MeshInstance3D] = []
var _case_tags: Array[Label3D] = []
var _aging_lamps: Array[MeshInstance3D] = []
var _route_label: Label3D
var _stock_label: Label3D
var _condition_label: Label3D
var _manifest_label: Label3D
var _manifest_root: Node3D
var _scale_needle: MeshInstance3D
var _overflow_lamp: MeshInstance3D
var _spoilage_lamp: MeshInstance3D
var _truck_root: Node3D

var _built := false
var _has_applied_snapshot := false
var _has_authoritative_projection := false
var _unlocked := false
var _facility_level := 0
var _capacity_cases := 0
var _stock_cases := 0
var _overflow_cases := 0
var _spoiled_cases := 0
var _season_label := "NO SEASON FILED"
var _mandate: Dictionary = {}
var _last_receipt: Dictionary = {}
var _expanded_cases: Array[Dictionary] = []


func _ready() -> void:
	name = "FarmgateDispatchDepotVisual"
	position = FACILITY_CENTER
	if not _built:
		build()


static func declared_footprint() -> Rect2:
	return FOOTPRINT


static func entrance_bridge_footprint() -> Rect2:
	return ENTRANCE_BRIDGE_FOOTPRINT


static func clear_aisle_footprint() -> Rect2:
	return CLEAR_AISLE_FOOTPRINT


static func vehicle_lane_footprint() -> Rect2:
	return VEHICLE_LANE_FOOTPRINT


static func facility_focus_point() -> Vector3:
	return FOCUS_POINT


static func maximum_visual_height() -> float:
	return MAX_VISUAL_HEIGHT


func focus_point_global() -> Vector3:
	return to_global(FOCUS_POINT - FACILITY_CENTER)


func build() -> void:
	clear()
	_built = true
	_build_entrance_bridge()
	_build_locked_marker()
	_build_survey_site()
	_build_owned_site()
	_build_level_one()
	_build_level_two()
	_build_level_three()
	_apply_visibility()
	_update_evidence_visuals()


func clear() -> void:
	for root_to_free in [entrance_bridge_root, locked_marker_root, survey_site_root, owned_site_root]:
		if root_to_free != null and is_instance_valid(root_to_free):
			root_to_free.free()
	entrance_bridge_root = null
	locked_marker_root = null
	survey_site_root = null
	owned_site_root = null
	level_1_root = null
	level_2_root = null
	level_3_root = null
	_case_crates.clear()
	_case_tags.clear()
	_aging_lamps.clear()
	_route_label = null
	_stock_label = null
	_condition_label = null
	_manifest_label = null
	_manifest_root = null
	_scale_needle = null
	_overflow_lamp = null
	_spoilage_lamp = null
	_truck_root = null
	_material_cache.clear()
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var projection := _projection_from_snapshot(snapshot)
	_has_authoritative_projection = not projection.is_empty()
	_facility_level = clampi(_snapshot_facility_level(snapshot, projection), 0, MAX_LEVEL)
	_unlocked = _facility_level > 0 or _snapshot_unlocked(snapshot, projection)
	_capacity_cases = maxi(0, int(projection.get(
		"capacity_cases",
		projection.get(
			"storage_capacity_eggs",
			projection.get("capacity", _default_capacity_for_level(_facility_level)),
		),
	)))
	_expanded_cases = _expand_case_lots(projection)
	_stock_cases = _expanded_cases.size()
	_overflow_cases = maxi(0, int(projection.get(
		"overflow_cases",
		projection.get(
			"overflow_eggs",
			(_dictionary_value(projection.get("last_settlement_receipt", {}))).get(
				"overflow_eggs",
				projection.get("overflow", 0),
			),
		),
	)))
	_spoiled_cases = maxi(0, int(projection.get(
		"spoiled_cases",
		projection.get(
			"spoiled_eggs",
			(_dictionary_value(projection.get("last_settlement_receipt", {}))).get(
				"expired_eggs",
				projection.get("spoilage", projection.get("spoiled", 0)),
			),
		),
	)))
	_mandate = _dictionary_value(projection.get(
		"mandate",
		projection.get("active_mandate", projection.get("route", {})),
	))
	_last_receipt = _dictionary_value(projection.get(
		"last_receipt",
		projection.get(
			"last_settlement_receipt",
			projection.get("last_dispatch", projection.get("receipt", {})),
		),
	))
	_season_label = _projection_season_label(projection)
	_apply_visibility()
	_update_evidence_visuals()
	if _has_applied_snapshot and _facility_level > previous_level:
		for revealed_level in range(previous_level + 1, _facility_level + 1):
			_animate_level_reveal(revealed_level)
	_has_applied_snapshot = true


func set_preview_level(level: int, unlocked: bool = true) -> void:
	var preview_level := clampi(level, 0, MAX_LEVEL)
	apply_snapshot({
		"facility_catalog": [{
			"id": FACILITY_ID,
			"unlocked": unlocked,
			"level": preview_level,
		}],
		"farmgate_dispatch_depot": {
			"level": preview_level,
			"status": "preview",
			"capacity_cases": _default_capacity_for_level(preview_level),
			"lots": [],
			"mandate": {},
			"season": {},
			"last_receipt": {},
			"overflow_cases": 0,
			"spoiled_cases": 0,
		},
	})


func visual_state() -> StringName:
	if _facility_level > 0:
		return StringName("level_%d" % _facility_level)
	return &"survey" if _unlocked else &"locked"


func facility_level() -> int:
	return _facility_level


func has_authoritative_projection() -> bool:
	return _has_authoritative_projection


func stock_case_count() -> int:
	return _stock_cases


func visible_case_count() -> int:
	var count := 0
	for crate in _case_crates:
		if crate != null and crate.visible:
			count += 1
	return count


func locked_marker_visible() -> bool:
	return locked_marker_root != null and locked_marker_root.visible


func survey_site_visible() -> bool:
	return survey_site_root != null and survey_site_root.visible


func level_visible(level: int) -> bool:
	match level:
		1:
			return level_1_root != null and level_1_root.visible
		2:
			return level_2_root != null and level_2_root.visible
		3:
			return level_3_root != null and level_3_root.visible
	return false


func route_text() -> String:
	return _route_label.text if _route_label != null else ""


func condition_text() -> String:
	return _condition_label.text if _condition_label != null else ""


func manifest_text() -> String:
	return _manifest_label.text if _manifest_label != null else ""


func manifest_visible() -> bool:
	return _manifest_root != null and _manifest_root.visible


func truck_visible() -> bool:
	return _truck_root != null and _truck_root.is_visible_in_tree()


func overflow_indicator_active() -> bool:
	return _overflow_cases > 0


func spoilage_indicator_active() -> bool:
	return _spoiled_cases > 0


func evidence_snapshot() -> Dictionary:
	return {
		"facility_id": FACILITY_ID,
		"level": _facility_level,
		"state": visual_state(),
		"authoritative": _has_authoritative_projection,
		"capacity_cases": _capacity_cases,
		"stock_cases": _stock_cases,
		"visible_cases": visible_case_count(),
		"overflow_cases": _overflow_cases,
		"spoiled_cases": _spoiled_cases,
		"season_label": _season_label,
		"route_text": route_text(),
		"manifest_visible": manifest_visible(),
		"manifest_text": manifest_text(),
	}


func geometry_bounds_inside_footprint() -> bool:
	var local_half := FOOTPRINT.size * 0.5
	var tolerance := 0.015
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or _is_connector_geometry(instance):
			continue
		for corner in _mesh_corners_in_visual_space(instance):
			if (
				absf(corner.x) > local_half.x + tolerance
				or absf(corner.z) > local_half.y + tolerance
				or corner.y > MAX_VISUAL_HEIGHT + tolerance
			):
				return false
	return true


func connector_geometry_inside_bridge() -> bool:
	var found := false
	var tolerance := 0.015
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or not _is_connector_geometry(instance):
			continue
		found = true
		for corner in _mesh_corners_in_visual_space(instance):
			var world_xz := Vector2(corner.x + FACILITY_CENTER.x, corner.z + FACILITY_CENTER.z)
			if (
				world_xz.x < ENTRANCE_BRIDGE_FOOTPRINT.position.x - tolerance
				or world_xz.x > ENTRANCE_BRIDGE_FOOTPRINT.end.x + tolerance
				or world_xz.y < ENTRANCE_BRIDGE_FOOTPRINT.position.y - tolerance
				or world_xz.y > ENTRANCE_BRIDGE_FOOTPRINT.end.y + tolerance
			):
				return false
	return found


func circulation_clear() -> bool:
	var aisle_local := Rect2(
		CLEAR_AISLE_FOOTPRINT.position - Vector2(FACILITY_CENTER.x, FACILITY_CENTER.z),
		CLEAR_AISLE_FOOTPRINT.size,
	)
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := _mesh_bounds_in_visual_space(instance)
		if bounds.end.y <= 0.08 or bounds.position.y >= 2.55:
			continue
		var xz := Rect2(
			Vector2(bounds.position.x, bounds.position.z),
			Vector2(bounds.size.x, bounds.size.z),
		)
		if xz.intersects(aisle_local):
			return false
	return true


func vehicle_geometry_inside_lane() -> bool:
	var found := false
	var tolerance := 0.015
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or not _is_authorized_vehicle_geometry(instance):
			continue
		found = true
		for corner in _mesh_corners_in_visual_space(instance):
			var world_xz := Vector2(corner.x + FACILITY_CENTER.x, corner.z + FACILITY_CENTER.z)
			if (
				world_xz.x < VEHICLE_LANE_FOOTPRINT.position.x - tolerance
				or world_xz.x > VEHICLE_LANE_FOOTPRINT.end.x + tolerance
				or world_xz.y < VEHICLE_LANE_FOOTPRINT.position.y - tolerance
				or world_xz.y > VEHICLE_LANE_FOOTPRINT.end.y + tolerance
			):
				return false
	return found


func vehicle_lane_clear_of_unauthorized_geometry() -> bool:
	return unauthorized_vehicle_lane_geometry_names().is_empty()


func unauthorized_vehicle_lane_geometry_names() -> PackedStringArray:
	var intrusions := PackedStringArray()
	var lane_local := Rect2(
		VEHICLE_LANE_FOOTPRINT.position - Vector2(FACILITY_CENTER.x, FACILITY_CENTER.z),
		VEHICLE_LANE_FOOTPRINT.size,
	)
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if (
			instance == null
			or instance.mesh == null
			or _is_authorized_vehicle_geometry(instance)
			or _is_authorized_lane_overhead_geometry(instance)
		):
			continue
		var bounds := _mesh_bounds_in_visual_space(instance)
		if bounds.end.y <= 0.08 or bounds.position.y >= 3.25:
			continue
		var xz := Rect2(
			Vector2(bounds.position.x, bounds.position.z),
			Vector2(bounds.size.x, bounds.size.z),
		)
		if xz.intersects(lane_local):
			intrusions.append(instance.name)
	return intrusions


func cumulative_silhouette_height(level: int) -> float:
	var clamped_level := clampi(level, 0, MAX_LEVEL)
	# Reveal tweens briefly squash a newly purchased root. Silhouette evidence is
	# an authored construction contract, so measure the unanimated transforms and
	# restore the live reveal state before returning.
	var tier_roots: Array[Node3D] = [level_1_root, level_2_root, level_3_root]
	var prior_scales: Array[Vector3] = []
	for tier_root in tier_roots:
		prior_scales.append(tier_root.scale if tier_root != null else Vector3.ONE)
		if tier_root != null:
			tier_root.scale = Vector3.ONE
	var maximum := 0.0
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null or _is_connector_geometry(instance):
			continue
		if not _mesh_belongs_to_cumulative_level(instance, clamped_level):
			continue
		maximum = maxf(maximum, _mesh_bounds_in_visual_space(instance).end.y)
	for index in tier_roots.size():
		if tier_roots[index] != null:
			tier_roots[index].scale = prior_scales[index]
	return maximum


func _apply_visibility() -> void:
	if locked_marker_root != null:
		locked_marker_root.visible = not _unlocked and _facility_level <= 0
	if survey_site_root != null:
		survey_site_root.visible = _unlocked and _facility_level <= 0
	if entrance_bridge_root != null:
		entrance_bridge_root.visible = _facility_level > 0
	if owned_site_root != null:
		owned_site_root.visible = _facility_level > 0
	if level_1_root != null:
		level_1_root.visible = _facility_level >= 1
	if level_2_root != null:
		level_2_root.visible = _facility_level >= 2
	if level_3_root != null:
		level_3_root.visible = _facility_level >= 3
	var cell_limit := mini(_visual_cell_limit_for_level(_facility_level), _case_crates.size())
	var visible_limit := mini(_stock_cases, mini(_capacity_cases, cell_limit))
	for index in _case_crates.size():
		_case_crates[index].visible = index < visible_limit
	if _manifest_root != null:
		_manifest_root.visible = _facility_level >= 3 and not _last_receipt.is_empty()


func _update_evidence_visuals() -> void:
	_update_case_rack()
	_update_route_board()
	_update_scale()
	_update_condition_hardware()
	_update_manifest()
	_apply_visibility()


func _update_case_rack() -> void:
	for tag in _case_tags:
		var index := int(tag.get_meta(&"dispatch_case_index", -1))
		if index >= 0 and index < _expanded_cases.size():
			var record := _expanded_cases[index]
			var lot_label := String(record.get("lot_id", "--")).to_upper()
			var packed_day := int(record.get("packed_day", 0))
			tag.text = "PACKED BY THE FLOCK\n%s · D%02d" % [lot_label, packed_day]
		else:
			tag.text = "PACKED BY THE FLOCK\nEMPTY CASE CELL"
		EnvironmentalSignageScript.refit_label(tag)


func _update_route_board() -> void:
	if _route_label == null:
		return
	if not _has_authoritative_projection:
		_route_label.text = "NO DISPATCH LEDGER\nROADSIDE SHED STANDING BY"
	elif _mandate.is_empty():
		_route_label.text = "NO ROUTE FILED\n%s · %02d/%02d CASES" % [
			_season_label,
			_stock_cases,
			_capacity_cases,
		]
	else:
		var route_name := String(_mandate.get(
			"label",
			_mandate.get(
				"route_label",
				_mandate_display_name(StringName(_mandate.get(
					"mandate_id",
					_mandate.get("id", &""),
				))),
			),
		)).to_upper()
		var committed_cases := maxi(0, int(_mandate.get(
			"case_count",
			_mandate.get(
				"dispatch_limit",
				_mandate.get("cases", _mandate.get("quantity", 0)),
			),
		)))
		_route_label.text = "%s\n%s · %02d CASES" % [route_name, _season_label, committed_cases]
	EnvironmentalSignageScript.refit_label(_route_label)


func _update_scale() -> void:
	if _stock_label != null:
		_stock_label.text = "CASES  %02d / %02d" % [_stock_cases, _capacity_cases]
		EnvironmentalSignageScript.refit_label(_stock_label)
	if _scale_needle != null:
		var ratio := 0.0
		if _capacity_cases > 0:
			ratio = clampf(float(_stock_cases) / float(_capacity_cases), 0.0, 1.0)
		_scale_needle.rotation_degrees.z = lerpf(-52.0, 52.0, ratio)


func _update_condition_hardware() -> void:
	var nearest_expiry := 99
	for record in _expanded_cases:
		var expires_in := int(record.get("expires_in", 99))
		nearest_expiry = mini(nearest_expiry, expires_in)
	var age_state := 0
	if _stock_cases > 0:
		age_state = 1 if nearest_expiry <= 1 else 0
	if _spoiled_cases > 0:
		age_state = 2
	for index in _aging_lamps.size():
		var color: Color = [STATUS_GREEN, STATUS_AMBER, STATUS_RED][index] as Color
		_aging_lamps[index].material_override = (
			_emissive_material(color, 1.25)
			if index == age_state and _stock_cases > 0
			else _material(color.darkened(0.64), 0.66, 0.04)
		)
	if _overflow_lamp != null:
		_overflow_lamp.material_override = (
			_emissive_material(STATUS_AMBER, 1.20)
			if _overflow_cases > 0
			else _material(STATUS_AMBER.darkened(0.66), 0.66, 0.04)
		)
	if _spoilage_lamp != null:
		_spoilage_lamp.material_override = (
			_emissive_material(STATUS_RED, 1.35)
			if _spoiled_cases > 0
			else _material(STATUS_RED.darkened(0.66), 0.66, 0.04)
		)
	if _condition_label != null:
		_condition_label.text = "OVERFLOW %02d\nSPOILED %02d" % [
			_overflow_cases,
			_spoiled_cases,
		]
		EnvironmentalSignageScript.refit_label(_condition_label)


func _update_manifest() -> void:
	if _manifest_label == null:
		return
	if _last_receipt.is_empty():
		_manifest_label.text = "NO ROUTE RECEIPT"
		return
	var route_name := String(_last_receipt.get(
		"route_label",
		_last_receipt.get(
			"label",
			_mandate_display_name(StringName(_last_receipt.get(
				"mandate_id",
				_last_receipt.get("route_id", &""),
			))),
		),
	)).to_upper()
	var day := maxi(0, int(_last_receipt.get("day", 0)))
	var cases := maxi(0, int(_last_receipt.get(
		"case_count",
		_last_receipt.get(
			"sold_eggs",
			_last_receipt.get("cases", _last_receipt.get("quantity", 0)),
		),
	)))
	var net_cents := int(_last_receipt.get(
		"net_cents",
		_last_receipt.get(
			"settlement_cash_delta_cents",
			_last_receipt.get("payout_cents", _last_receipt.get("margin_cents", 0)),
		),
	))
	_manifest_label.text = "DAY %02d · %s\n%02d CASES · NET %s" % [
		day,
		route_name,
		cases,
		_format_money(net_cents),
	]
	EnvironmentalSignageScript.refit_label(_manifest_label)


func _projection_from_snapshot(snapshot: Dictionary) -> Dictionary:
	for key in [
		&"farmgate_dispatch",
		"farmgate_dispatch",
		FACILITY_ID,
		String(FACILITY_ID),
		&"dispatch_depot",
		"dispatch_depot",
	]:
		var value: Variant = snapshot.get(key, null)
		if value is Dictionary:
			var projection := (value as Dictionary).duplicate(true)
			if not projection.has("day") and snapshot.has("day"):
				projection["day"] = int(snapshot.get("day", 0))
			return projection
	return {}


func _snapshot_facility_level(snapshot: Dictionary, projection: Dictionary) -> int:
	var owned_value: Variant = snapshot.get("owned_facilities", {})
	if owned_value is Dictionary:
		var owned := owned_value as Dictionary
		if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
			return _level_from_variant(owned.get(FACILITY_ID, owned.get(String(FACILITY_ID), 0)))
	if not projection.is_empty():
		return int(projection.get("level", projection.get("owned_level", 0)))
	var entry := _catalog_entry(snapshot)
	return int(entry.get("level", entry.get("owned_level", 0)))


func _snapshot_unlocked(snapshot: Dictionary, projection: Dictionary) -> bool:
	if not projection.is_empty():
		var status := String(projection.get("status", "")).to_lower()
		if bool(projection.get("unlocked", false)) or status in ["survey", "available", "preview", "owned", "operating"]:
			return true
	var entry := _catalog_entry(snapshot)
	return bool(entry.get(
		"unlocked",
		entry.get("available", entry.get("can_purchase", false)),
	)) or int(entry.get("level", 0)) > 0


func _catalog_entry(snapshot: Dictionary) -> Dictionary:
	var catalog_value: Variant = snapshot.get("facility_catalog", [])
	if catalog_value is Array:
		for entry_value in catalog_value as Array:
			if entry_value is Dictionary:
				var entry := entry_value as Dictionary
				if StringName(entry.get("id", &"")) == FACILITY_ID:
					return entry
	elif catalog_value is Dictionary:
		var catalog := catalog_value as Dictionary
		var entry_value: Variant = catalog.get(FACILITY_ID, catalog.get(String(FACILITY_ID), null))
		if entry_value is Dictionary:
			return entry_value as Dictionary
	return {}


func _expand_case_lots(projection: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var lots_value: Variant = projection.get("stock_lots", projection.get("lots", []))
	if not (lots_value is Array):
		return result
	for lot_value in lots_value as Array:
		if not (lot_value is Dictionary):
			continue
		var lot := lot_value as Dictionary
		var count := 1
		if lot.has("cases_remaining"):
			count = maxi(0, int(lot.get("cases_remaining", 0)))
		elif lot.has("case_count"):
			count = maxi(0, int(lot.get("case_count", 0)))
		elif lot.has("quantity"):
			count = maxi(0, int(lot.get("quantity", 0)))
		for _case_index in mini(count, LEVEL_THREE_STORAGE_CELLS - result.size()):
			result.append({
				"lot_id": str(lot.get("lot_id", lot.get("case_id", "LOT"))),
				"packed_day": maxi(0, int(lot.get(
					"packed_day",
					lot.get("laying_day", lot.get("day", 0)),
				))),
				"expires_in": _lot_expires_in(lot, projection),
			})
		if result.size() >= LEVEL_THREE_STORAGE_CELLS:
			break
	return result


func _lot_expires_in(lot: Dictionary, projection: Dictionary) -> int:
	if lot.has("expires_in"):
		return int(lot.get("expires_in", 99))
	var current_day := int(projection.get("day", 0))
	if lot.has("expires_day") and current_day > 0:
		return int(lot.get("expires_day", current_day + 99)) - current_day
	return 99


func _projection_season_label(projection: Dictionary) -> String:
	var season_value: Variant = projection.get("season", {})
	if season_value is Dictionary:
		var season := season_value as Dictionary
		return String(season.get("label", season.get("id", "NO SEASON FILED"))).to_upper()
	if season_value is String or season_value is StringName:
		var label := String(season_value).strip_edges()
		return label.to_upper() if not label.is_empty() else "NO SEASON FILED"
	return "NO SEASON FILED"


func _mandate_display_name(mandate_id: StringName) -> String:
	match mandate_id:
		&"farmer_pickup":
			return "FARMER PICKUP"
		&"county_auction":
			return "COUNTY AUCTION"
		&"regional_showcase":
			return "REGIONAL SHOWCASE"
		&"hold_basket":
			return "HOLD BASKET"
		# Retained for the authored visual fixture used by the isolated art test.
		&"county_coop":
			return "COUNTY CO-OP"
	return "ROUTE FILED"


func _dictionary_value(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _level_from_variant(value: Variant) -> int:
	if value is bool:
		return 1 if value else 0
	if value is int or value is float:
		return int(value)
	if value is Dictionary:
		var record := value as Dictionary
		return int(record.get("level", 1 if bool(record.get("owned", false)) else 0))
	return 0


func _default_capacity_for_level(level: int) -> int:
	return [0, LEVEL_ONE_STORAGE_CELLS, LEVEL_TWO_STORAGE_CELLS, LEVEL_THREE_STORAGE_CELLS][clampi(level, 0, MAX_LEVEL)]


func _visual_cell_limit_for_level(level: int) -> int:
	return _default_capacity_for_level(level)


func _format_money(cents: int) -> String:
	var absolute := absi(cents)
	return "%s$%d.%02d" % ["-" if cents < 0 else "", int(absolute / 100), absolute % 100]


func _animate_level_reveal(level: int) -> void:
	var revealed_root: Node3D = [null, level_1_root, level_2_root, level_3_root][clampi(level, 0, MAX_LEVEL)]
	if revealed_root == null or not is_instance_valid(revealed_root) or not revealed_root.is_inside_tree():
		return
	revealed_root.scale = Vector3(0.96, 0.08, 0.96)
	var reveal := revealed_root.create_tween().bind_node(revealed_root)
	reveal.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(revealed_root, "scale", Vector3(1.0, 1.03, 1.0), 0.42)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	reveal.tween_property(revealed_root, "scale", Vector3.ONE, 0.10)


func _build_entrance_bridge() -> void:
	entrance_bridge_root = Node3D.new()
	entrance_bridge_root.name = "FarmgateDispatchEntranceBridge"
	entrance_bridge_root.set_meta(&"visual_only", true)
	entrance_bridge_root.set_meta(&"collision_free", true)
	entrance_bridge_root.set_meta(&"navigation_free", true)
	entrance_bridge_root.set_meta(&"campus_connector", true)
	entrance_bridge_root.set_meta(&"declared_footprint", ENTRANCE_BRIDGE_FOOTPRINT)
	add_child(entrance_bridge_root)
	_add_box(
		entrance_bridge_root,
		"DispatchBridgeDeck",
		Vector3(0.25, 0.10, 1.20),
		Vector3(-4.525, -0.055, -3.00),
		WEATHERED_CONCRETE,
	)
	for edge_z in [-3.54, -2.46]:
		_add_box(
			entrance_bridge_root,
			"DispatchBridgeSafetyEdge",
			Vector3(0.22, 0.018, 0.035),
			Vector3(-4.525, 0.005, edge_z),
			STRAW,
			0.58,
			0.12,
		)


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "FarmgateDispatchLockedParcel"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)
	for edge_z in [-5.74, 5.74]:
		_add_box(locked_marker_root, "DispatchLeaseLineZ", Vector3(8.48, 0.030, 0.045), Vector3(0.0, 0.020, edge_z), BRASS.darkened(0.28))
	for edge_x in [-4.24, 4.24]:
		_add_box(locked_marker_root, "DispatchLeaseLineX", Vector3(0.045, 0.030, 11.42), Vector3(edge_x, 0.020, 0.0), BRASS.darkened(0.28))
	# Keep the locked-parcel copy on its own surveyed boundary instead of using a
	# billboard-sized destination slab along the shared North Meadow edge. The
	# compact permit board is visibly carried by timber stakes and sits on the
	# depot's south lease line, so it cannot visually merge with the meadow gate.
	var notice_mount := Node3D.new()
	notice_mount.name = "DispatchLeasePermitMount"
	notice_mount.position = Vector3(-1.55, 0.0, -5.54)
	notice_mount.set_meta(&"ground_supported", true)
	notice_mount.set_meta(&"support_kind", &"survey_stakes")
	locked_marker_root.add_child(notice_mount)
	for stake_index in 2:
		var stake_x: float = -0.86 if stake_index == 0 else 0.86
		_add_box(
			notice_mount,
			"DispatchLeaseNoticeStake_%02d" % stake_index,
			Vector3(0.13, 1.36, 0.13),
			Vector3(stake_x, 0.68, 0.0),
			DARK_TIMBER,
		)
	var notice_host := _add_box(
		notice_mount,
		"DispatchLeaseNoticeHost",
		Vector3(2.15, 0.72, 0.10),
		Vector3(0.0, 1.03, 0.0),
		DEEP_BARN_RED,
	)
	notice_host.set_meta(&"visible_support_count", 2)
	notice_host.set_meta(&"boundary_permit_board", true)
	EnvironmentalSignageScript.add_panel(
		notice_host,
		"DispatchLeaseNotice",
		"FARMGATE PARCEL\nLEASE FILE REQUIRED",
		Vector3(0.0, 0.0, 0.058),
		Vector2(1.82, 0.50),
		PAPER,
		DEEP_BARN_RED,
		Vector3.ZERO,
		12,
		0.0022,
		&"secondary",
		&"paper",
	)


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "FarmgateDispatchSurveySite"
	survey_site_root.set_meta(&"facility_state", &"survey")
	add_child(survey_site_root)
	_add_box(survey_site_root, "DispatchSurveyGrade", Vector3(8.54, 0.035, 11.54), Vector3.ZERO, DARK_CONCRETE)
	for x in [-3.10, -1.10, 0.90, 2.90]:
		_add_box(survey_site_root, "DispatchSurveyGridX", Vector3(0.025, 0.010, 10.85), Vector3(x, 0.025, 0.20), OATMEAL.darkened(0.24))
	for z in [-4.30, -1.70, 0.90, 3.50]:
		_add_box(survey_site_root, "DispatchSurveyGridZ", Vector3(7.95, 0.010, 0.025), Vector3(0.05, 0.026, z), OATMEAL.darkened(0.24))
	for corner in [Vector3(-4.05, 0.32, -5.50), Vector3(4.05, 0.32, -5.50), Vector3(-4.05, 0.32, 5.50), Vector3(4.05, 0.32, 5.50)]:
		_add_box(survey_site_root, "DispatchSurveyStake", Vector3(0.08, 0.64, 0.08), corner, TIMBER)
		_add_box(survey_site_root, "DispatchSurveyFlag", Vector3(0.36, 0.18, 0.020), corner + Vector3(0.14, 0.18, 0.0), BARN_RED)
	var board_host := _add_box(
		survey_site_root,
		"DispatchSurveyBoardHost",
		Vector3(4.54, 0.96, 0.12),
		Vector3(-1.50, 1.17, 5.50),
		BARN_RED,
	)
	EnvironmentalSignageScript.add_panel(
		board_host,
		"DispatchSurveyBoard",
		"DEPOT SURVEY / COLD-CHAIN PLAN FILED",
		Vector3(0.0, 0.0, 0.068),
		Vector2(4.18, 0.70),
		BARN_RED,
		PAPER,
		Vector3.ZERO,
		15,
		0.0028,
		&"secondary",
		&"destination",
	)
	var plan_table := _add_box(survey_site_root, "DispatchSurveyPlanTable", Vector3(1.90, 0.10, 1.06), Vector3(-2.85, 0.82, 2.95), TIMBER)
	for leg_x in [-0.76, 0.76]:
		for leg_z in [-0.38, 0.38]:
			_add_box(plan_table, "DispatchPlanTableLeg", Vector3(0.08, 0.78, 0.08), Vector3(leg_x, -0.44, leg_z), DARK_TIMBER)
	_add_box(plan_table, "DispatchBlueprint", Vector3(1.58, 0.018, 0.78), Vector3(0.0, 0.06, 0.0), Color("4e7480"))


func _build_owned_site() -> void:
	owned_site_root = Node3D.new()
	owned_site_root.name = "FarmgateDispatchOwnedSite"
	owned_site_root.set_meta(&"visual_only", true)
	owned_site_root.set_meta(&"collision_free", true)
	owned_site_root.set_meta(&"navigation_free", true)
	owned_site_root.set_meta(&"declared_footprint", FOOTPRINT)
	add_child(owned_site_root)
	_add_box(owned_site_root, "DispatchYardFoundation", Vector3(8.80, 0.16, 11.80), Vector3(0.0, -0.08, 0.0), DARK_CONCRETE)
	_add_box(owned_site_root, "WeatheredLoadingApron", Vector3(5.05, 0.035, 11.40), Vector3(-1.75, 0.018, 0.05), WEATHERED_CONCRETE)
	_add_box(owned_site_root, "VehicleLaneAsphalt", Vector3(3.35, 0.030, 10.90), Vector3(2.325, 0.018, -0.10), GRAPHITE)
	for lane_z in [-4.72, -2.72, -0.72, 1.28, 3.28]:
		_add_box(owned_site_root, "VehicleLaneCenterDash", Vector3(0.055, 0.012, 0.88), Vector3(2.325, 0.040, lane_z), STRAW)
	for edge_x in [0.70, 3.95]:
		_add_box(owned_site_root, "VehicleLaneEdge", Vector3(0.045, 0.014, 10.60), Vector3(edge_x, 0.041, -0.10), OATMEAL.darkened(0.08))
	for straw_index in 10:
		var straw_x := -4.03 + float(straw_index % 2) * 0.18
		var straw_z := -4.60 + float(straw_index) * 0.94
		var straw := _add_box(owned_site_root, "YardStraw", Vector3(0.24, 0.018, 0.035), Vector3(straw_x, 0.043, straw_z), STRAW.darkened(0.12))
		straw.rotation_degrees.y = -24.0 + straw_index * 17.0


func _build_level_one() -> void:
	level_1_root = Node3D.new()
	level_1_root.name = "RoadsideLoadingShedLevelOne"
	level_1_root.set_meta(&"facility_level", 1)
	owned_site_root.add_child(level_1_root)

	# Low open-sided farmstand canopy: no glass walls or office-room box.
	for post_x in [-4.00, 0.05]:
		for post_z in [-2.05, 1.65]:
			_add_box(level_1_root, "RoadsideCanopyPost", Vector3(0.14, 2.58, 0.14), Vector3(post_x, 1.29, post_z), TIMBER)
	for rail_z in [-2.05, 1.65]:
		_add_box(level_1_root, "RoadsideCanopyHeader", Vector3(4.18, 0.18, 0.16), Vector3(-1.98, 2.50, rail_z), DARK_TIMBER)
	for canvas_x in [-3.00, -0.96]:
		var canvas := _add_box(level_1_root, "CreamCanvasAwning", Vector3(2.15, 0.075, 3.84), Vector3(canvas_x, 2.72, -0.20), CREAM_CANVAS)
		canvas.rotation_degrees.z = -5.0 if canvas_x < -2.0 else 5.0
	var identity_host := _add_box(
		level_1_root,
		"FarmgateDispatchIdentityHost",
		Vector3(4.28, 0.66, 0.15),
		Vector3(-1.98, 2.53, 1.72),
		DEEP_BARN_RED,
	)
	_add_box(identity_host, "DispatchIdentityTopCap", Vector3(4.34, 0.045, 0.18), Vector3(0.0, 0.30, 0.0), BRASS.darkened(0.14), 0.52, 0.36)
	_add_box(identity_host, "DispatchIdentityBottomCap", Vector3(4.34, 0.035, 0.18), Vector3(0.0, -0.30, 0.0), BRASS.darkened(0.22), 0.52, 0.34)
	EnvironmentalSignageScript.add_panel(
		identity_host,
		"FarmgateDispatchDepotIdentity",
		DISPLAY_NAME,
		Vector3(0.0, 0.0, 0.086),
		Vector2(3.88, 0.44),
		DEEP_BARN_RED,
		BRASS.lightened(0.14),
		Vector3.ZERO,
		19,
		0.0030,
		&"primary",
		&"destination",
	)

	_build_manual_scale()
	_build_split_flap_slate()
	_build_storage_bank(level_1_root, "RoadsideColdBasket", 0, 4, 3, Vector3(-2.83, 0.0, 3.72))


func _build_manual_scale() -> void:
	var scale_root := Node3D.new()
	scale_root.name = "RoadsideManualScale"
	scale_root.position = Vector3(-3.02, 0.0, -0.45)
	level_1_root.add_child(scale_root)
	_add_box(scale_root, "ManualScalePlinth", Vector3(1.12, 0.82, 0.82), Vector3(0.0, 0.41, 0.0), DARK_TIMBER)
	_add_box(scale_root, "ManualScaleDeck", Vector3(1.38, 0.12, 1.02), Vector3(0.0, 0.88, 0.0), GALVANIZED, 0.44, 0.30)
	var dial := _add_cylinder(scale_root, "ManualScaleDial", Vector3(0.0, 1.36, 0.38), 0.36, 0.10, PAPER, 0.58, 0.08)
	dial.rotation_degrees.x = 90.0
	_scale_needle = _add_box(scale_root, "ManualScaleNeedle", Vector3(0.035, 0.29, 0.025), Vector3(0.0, 1.36, 0.445), BARN_RED)
	var stock_host := _add_box(scale_root, "ScaleCaseCounterHost", Vector3(0.92, 0.30, 0.055), Vector3(0.0, 0.46, 0.438), GRAPHITE)
	_stock_label = EnvironmentalSignageScript.add_panel(
		stock_host,
		"ScaleCaseCounter",
		"CASES  00 / 00",
		Vector3(0.0, 0.0, 0.034),
		Vector2(0.80, 0.20),
		GRAPHITE,
		PAPER,
		Vector3.ZERO,
		10,
		0.0018,
		&"utility",
		&"machine",
	)
	_add_sphere(scale_root, "BrassSaleBell", Vector3(0.48, 1.05, -0.18), Vector3(0.28, 0.18, 0.28), BRASS, 0.34)
	_add_cylinder(scale_root, "SaleBellBase", Vector3(0.48, 0.94, -0.18), 0.22, 0.06, DARK_TIMBER, 0.56, 0.18)


func _build_split_flap_slate() -> void:
	var slate_host := _add_box(
		level_1_root,
		"SplitFlapRouteBoardHost",
		Vector3(2.26, 0.88, 0.14),
		Vector3(-1.04, 1.32, 1.55),
		GRAPHITE,
		0.48,
		0.18,
	)
	for flap_index in 8:
		_add_box(slate_host, "MechanicalRouteFlap", Vector3(0.22, 0.28, 0.025), Vector3(-0.87 + flap_index * 0.25, 0.16, 0.088), ROUTE_GREEN.darkened(0.18))
	_route_label = EnvironmentalSignageScript.add_panel(
		slate_host,
		"SplitFlapRouteBoard",
		"NO DISPATCH LEDGER\nROADSIDE SHED STANDING BY",
		Vector3(0.0, -0.13, 0.080),
		Vector2(2.02, 0.50),
		GRAPHITE,
		STATUS_AMBER,
		Vector3.ZERO,
		11,
		0.0019,
		&"secondary",
		&"machine",
	)
	var lamp_rail := _add_box(level_1_root, "CaseAgingLampRail", Vector3(1.40, 0.24, 0.18), Vector3(-2.82, 2.52, 3.34), DARK_TIMBER)
	for lamp_index in 3:
		var lamp_color: Color = [STATUS_GREEN, STATUS_AMBER, STATUS_RED][lamp_index] as Color
		var lamp := _add_sphere(lamp_rail, "CaseAgingLamp_%d" % lamp_index, Vector3(-0.42 + lamp_index * 0.42, 0.0, 0.12), Vector3(0.20, 0.20, 0.10), lamp_color.darkened(0.64))
		_aging_lamps.append(lamp)


func _build_level_two() -> void:
	level_2_root = Node3D.new()
	level_2_root.name = "ChilledCountyDockLevelTwo"
	level_2_root.set_meta(&"facility_level", 2)
	owned_site_root.add_child(level_2_root)

	# A board-and-galvanized cold shed wraps the existing basket rack. Repeated
	# pitched teeth create a middle-height industrial silhouette.
	_add_box(level_2_root, "ColdShedWestWall", Vector3(0.16, 3.78, 3.86), Vector3(-4.18, 1.89, 3.55), GALVANIZED, 0.58, 0.30)
	_add_box(level_2_root, "ColdShedBackWall", Vector3(4.62, 3.78, 0.16), Vector3(-1.88, 1.89, 5.48), COLD_STEEL, 0.58, 0.28)
	_add_box(level_2_root, "ColdShedEastReturn", Vector3(0.16, 3.12, 2.74), Vector3(0.35, 1.56, 4.10), GALVANIZED, 0.58, 0.30)
	for batten_x in [-3.72, -3.00, -2.28, -1.56, -0.84, -0.12]:
		_add_box(level_2_root, "ColdShedBoardBatten", Vector3(0.055, 3.20, 0.035), Vector3(batten_x, 1.68, 5.585), PALE_GALVANIZED.darkened(0.10), 0.54, 0.26)
	var sawtooth_bays: Array[float] = [-3.62, -2.52, -1.42, -0.32]
	for bay_index in sawtooth_bays.size():
		var bay_x := sawtooth_bays[bay_index]
		var roof_panel := _add_box(level_2_root, "SawtoothColdRoof_%02d" % bay_index, Vector3(1.18, 0.10, 3.72), Vector3(bay_x, 3.92, 3.58), PALE_GALVANIZED, 0.42, 0.34)
		roof_panel.rotation_degrees.z = -18.0
		_add_box(level_2_root, "SawtoothClerestory_%02d" % bay_index, Vector3(0.075, 0.46, 3.66), Vector3(bay_x + 0.49, 4.05, 3.58), COLD_STEEL, 0.50, 0.26)
	var condenser := _add_box(level_2_root, "ColdChainCondenser", Vector3(1.38, 0.94, 0.32), Vector3(-3.02, 2.56, 5.33), GALVANIZED, 0.48, 0.34)
	var fan := _add_cylinder(condenser, "CondenserFan", Vector3(0.0, 0.0, 0.19), 0.34, 0.08, GRAPHITE, 0.56, 0.12)
	fan.rotation_degrees.x = 90.0
	for blade_rotation in [0.0, 60.0, 120.0]:
		var blade := _add_box(condenser, "CondenserFanBlade", Vector3(0.10, 0.56, 0.035), Vector3(0.0, 0.0, 0.245), PALE_GALVANIZED)
		blade.rotation_degrees.z = blade_rotation

	_add_box(level_2_root, "RaisedCountyDock", Vector3(1.30, 0.44, 2.72), Vector3(-0.36, 0.22, -0.04), GALVANIZED, 0.62, 0.20)
	_add_box(level_2_root, "CountyDockSafetyNose", Vector3(0.16, 0.16, 2.72), Vector3(0.32, 0.40, -0.04), STATUS_AMBER, 0.58, 0.12)
	var conveyor_root := Node3D.new()
	conveyor_root.name = "CountyCaseConveyor"
	conveyor_root.position = Vector3(-1.70, 1.02, 0.06)
	level_2_root.add_child(conveyor_root)
	_add_box(conveyor_root, "CountyConveyorFrame", Vector3(2.72, 0.12, 0.84), Vector3(0.0, 0.0, 0.0), COLD_STEEL, 0.48, 0.30)
	for roller_index in 9:
		var roller := _add_cylinder(conveyor_root, "CountyConveyorRoller", Vector3(-1.12 + roller_index * 0.28, 0.10, 0.0), 0.07, 0.72, PALE_GALVANIZED, 0.38, 0.38)
		roller.rotation_degrees.x = 90.0
	for fixture_x in [-3.65, -2.10, -0.55]:
		var housing := _add_box(level_2_root, "ColdChainLightHousing", Vector3(0.72, 0.14, 0.20), Vector3(fixture_x, 3.40, 5.30), GRAPHITE)
		var light_face := _add_box(housing, "ColdChainAmberFixture", Vector3(0.58, 0.08, 0.035), Vector3(0.0, 0.0, 0.12), STATUS_AMBER)
		light_face.material_override = _emissive_material(STATUS_AMBER, 0.74)

	_build_storage_bank(level_2_root, "CountyColdRack", LEVEL_ONE_STORAGE_CELLS, 4, 3, Vector3(-0.55, 0.0, 3.72))
	_build_condition_panel()


func _build_condition_panel() -> void:
	var panel_host := _add_box(level_2_root, "ColdChainConditionPanelHost", Vector3(1.30, 0.78, 0.14), Vector3(-3.42, 1.46, 5.33), GRAPHITE)
	_overflow_lamp = _add_sphere(panel_host, "DispatchOverflowLamp", Vector3(-0.43, 0.24, 0.10), Vector3(0.16, 0.16, 0.08), STATUS_AMBER.darkened(0.66))
	_spoilage_lamp = _add_sphere(panel_host, "DispatchSpoilageLamp", Vector3(0.43, 0.24, 0.10), Vector3(0.16, 0.16, 0.08), STATUS_RED.darkened(0.66))
	_condition_label = EnvironmentalSignageScript.add_panel(
		panel_host,
		"ColdChainConditionLedger",
		"OVERFLOW 00\nSPOILED 00",
		Vector3(0.0, -0.15, 0.080),
		Vector2(1.10, 0.42),
		GRAPHITE,
		PAPER,
		Vector3.ZERO,
		10,
		0.0018,
		&"utility",
		&"machine",
	)


func _build_level_three() -> void:
	level_3_root = Node3D.new()
	level_3_root.name = "RegionalRouteFleetLevelThree"
	level_3_root.set_meta(&"facility_level", 3)
	owned_site_root.add_child(level_3_root)

	_build_dispatch_tower()
	_build_loading_mast()
	_build_refrigerated_truck()
	_build_storage_bank(level_3_root, "RegionalPalletArchive", LEVEL_TWO_STORAGE_CELLS, 6, 3, Vector3(-1.82, 0.0, 4.88))
	_build_sale_showcase()


func _build_dispatch_tower() -> void:
	var tower := Node3D.new()
	tower.name = "BarnRedDispatchTower"
	tower.position = Vector3(-3.62, 0.0, 0.42)
	level_3_root.add_child(tower)
	_add_box(tower, "DispatchTowerBody", Vector3(1.12, 4.72, 1.28), Vector3(0.0, 2.36, 0.0), BARN_RED)
	for batten_x in [-0.42, -0.14, 0.14, 0.42]:
		_add_box(tower, "DispatchTowerBatten", Vector3(0.045, 4.38, 0.035), Vector3(batten_x, 2.32, 0.66), DEEP_BARN_RED)
	for side in [-1.0, 1.0]:
		var roof := _add_box(tower, "DispatchTowerGableRoof", Vector3(0.82, 0.10, 1.50), Vector3(side * 0.30, 4.93, 0.0), DARK_TIMBER)
		roof.rotation_degrees.z = side * 34.0
	var tower_clock_host := _add_box(tower, "DispatchTowerClockHost", Vector3(0.74, 0.74, 0.08), Vector3(0.0, 3.75, 0.67), DEEP_BARN_RED)
	EnvironmentalSignageScript.add_panel(
		tower_clock_host,
		"RegionalDispatchTowerPlate",
		"REGIONAL ROUTES\nFARMER CREDIT OFFICE",
		Vector3(0.0, 0.0, 0.050),
		Vector2(0.62, 0.54),
		DEEP_BARN_RED,
		BRASS,
		Vector3.ZERO,
		9,
		0.00165,
		&"utility",
		&"stencil",
	)


func _build_loading_mast() -> void:
	var mast := Node3D.new()
	mast.name = "RegionalLoadingMast"
	mast.position = Vector3(0.28, 0.0, 0.28)
	mast.set_meta(&"authorized_vehicle_lane_overhead", true)
	level_3_root.add_child(mast)
	_add_box(mast, "LoadingMastColumn", Vector3(0.20, 5.18, 0.20), Vector3(0.0, 2.59, 0.0), GALVANIZED, 0.46, 0.42)
	_add_box(mast, "LoadingMastArm", Vector3(2.34, 0.18, 0.18), Vector3(1.07, 5.10, 0.0), GALVANIZED, 0.46, 0.42)
	_add_cylinder(mast, "LoadingCable", Vector3(2.02, 4.20, 0.0), 0.025, 1.70, GRAPHITE)
	_add_box(mast, "LoadingManifestHook", Vector3(0.38, 0.12, 0.18), Vector3(2.02, 3.34, 0.0), BRASS, 0.44, 0.38)
	var mast_lamp := _add_sphere(mast, "LoadingMastBeacon", Vector3(0.0, 5.34, 0.0), Vector3(0.28, 0.22, 0.28), STATUS_AMBER)
	mast_lamp.material_override = _emissive_material(STATUS_AMBER, 0.95)


func _build_refrigerated_truck() -> void:
	_truck_root = Node3D.new()
	_truck_root.name = "FarmerBrandRefrigeratedTruck"
	_truck_root.position = Vector3(2.35, 0.0, 0.55)
	_truck_root.set_meta(&"authorized_vehicle", true)
	_truck_root.set_meta(&"vehicle_lane", VEHICLE_LANE_FOOTPRINT)
	level_3_root.add_child(_truck_root)
	_add_box(_truck_root, "TruckChassis", Vector3(2.24, 0.20, 4.92), Vector3(0.0, 0.46, 0.0), GRAPHITE, 0.44, 0.34)
	_add_box(_truck_root, "TruckCab", Vector3(2.12, 1.54, 1.46), Vector3(0.0, 1.18, -1.62), BARN_RED)
	_add_box(_truck_root, "TruckWindshield", Vector3(1.72, 0.54, 0.035), Vector3(0.0, 1.48, -2.37), Color("42575a"), 0.22, 0.12)
	_add_box(_truck_root, "TruckHood", Vector3(1.86, 0.44, 0.72), Vector3(0.0, 0.88, -2.20), BOARD_RED)
	var cargo_box := _add_box(_truck_root, "RefrigeratedCargoBox", Vector3(2.08, 2.32, 3.18), Vector3(0.0, 1.72, 0.92), REFRIGERATOR_WHITE, 0.66, 0.08)
	_add_box(_truck_root, "TruckRefrigerationUnit", Vector3(1.70, 0.78, 0.28), Vector3(0.0, 2.32, -0.82), GALVANIZED, 0.42, 0.34)
	for vent_x in [-0.56, -0.28, 0.0, 0.28, 0.56]:
		_add_box(_truck_root, "TruckRefrigerationVent", Vector3(0.12, 0.42, 0.035), Vector3(vent_x, 2.32, -0.975), COLD_STEEL)
	for wheel_x in [-1.08, 1.08]:
		for wheel_z in [-1.55, 1.58]:
			var wheel := _add_cylinder(_truck_root, "TruckWheel", Vector3(wheel_x, 0.43, wheel_z), 0.39, 0.16, BLACK_RUBBER, 0.92, 0.0)
			wheel.rotation_degrees.z = 90.0
			_add_cylinder(_truck_root, "TruckWheelHub", Vector3(wheel_x + (0.09 if wheel_x > 0.0 else -0.09), 0.43, wheel_z), 0.16, 0.05, GALVANIZED, 0.42, 0.38).rotation_degrees.z = 90.0
	EnvironmentalSignageScript.add_panel(
		cargo_box,
		"FarmerBrandTruckLivery",
		"FARMER BRAND EGGS",
		Vector3(1.050, 0.12, 0.0),
		Vector2(2.48, 0.62),
		REFRIGERATOR_WHITE,
		DEEP_BARN_RED,
		Vector3(0.0, 90.0, 0.0),
		19,
		0.0030,
		&"secondary",
		&"stencil",
	)
	_manifest_root = Node3D.new()
	_manifest_root.name = "AuthoritativeTruckManifest"
	_manifest_root.position = Vector3(0.0, 1.62, 2.54)
	_manifest_root.set_meta(&"authoritative_record", true)
	_truck_root.add_child(_manifest_root)
	var manifest_host := _add_box(_manifest_root, "TruckManifestClipboardHost", Vector3(1.16, 0.78, 0.08), Vector3.ZERO, DARK_KRAFT)
	_manifest_label = EnvironmentalSignageScript.add_panel(
		manifest_host,
		"TruckRouteManifest",
		"NO ROUTE RECEIPT",
		Vector3(0.0, 0.0, 0.050),
		Vector2(1.02, 0.62),
		DARK_KRAFT,
		PAPER,
		Vector3.ZERO,
		9,
		0.00165,
		&"utility",
		&"paper",
	)


func _build_sale_showcase() -> void:
	var showcase := Node3D.new()
	showcase.name = "RegionalSaleBellShowcase"
	showcase.position = Vector3(-0.20, 0.0, 4.82)
	level_3_root.add_child(showcase)
	_add_box(showcase, "SaleShowcasePlinth", Vector3(0.96, 0.88, 0.84), Vector3(0.0, 0.44, 0.0), DARK_TIMBER)
	_add_box(showcase, "SaleShowcaseBrassTop", Vector3(1.08, 0.10, 0.96), Vector3(0.0, 0.93, 0.0), BRASS, 0.36, 0.52)
	_add_sphere(showcase, "RegionalSaleBell", Vector3(0.0, 1.18, 0.0), Vector3(0.42, 0.28, 0.42), BRASS, 0.32)
	_add_cylinder(showcase, "RegionalSaleBellButton", Vector3(0.0, 1.42, 0.0), 0.10, 0.16, DEEP_BARN_RED)


func _build_storage_bank(
	parent: Node3D,
	bank_name: String,
	start_index: int,
	columns: int,
	rows: int,
	bank_position: Vector3,
) -> void:
	var bank := Node3D.new()
	bank.name = bank_name
	bank.position = bank_position
	bank.set_meta(&"storage_start_index", start_index)
	bank.set_meta(&"storage_cell_count", columns * rows)
	parent.add_child(bank)
	var width := float(columns) * 0.52 + 0.18
	var height := float(rows) * 0.46 + 0.28
	_add_box(bank, "%sBack" % bank_name, Vector3(width, height, 0.12), Vector3(0.0, height * 0.5 + 0.24, -0.22), COLD_STEEL)
	for shelf_index in rows + 1:
		_add_box(bank, "%sShelf" % bank_name, Vector3(width, 0.075, 0.62), Vector3(0.0, 0.26 + shelf_index * 0.46, 0.0), GALVANIZED, 0.48, 0.32)
	for post_index in columns + 1:
		_add_box(bank, "%sPost" % bank_name, Vector3(0.065, height, 0.58), Vector3(-width * 0.5 + 0.09 + post_index * 0.52, height * 0.5 + 0.24, 0.0), GALVANIZED, 0.48, 0.32)
	for row in rows:
		for column in columns:
			var cell_index := start_index + row * columns + column
			var cell_position := Vector3(
				-width * 0.5 + 0.35 + column * 0.52,
				0.49 + row * 0.46,
				0.08,
			)
			var crate := _add_box(bank, "DispatchCase_%02d" % cell_index, Vector3(0.40, 0.30, 0.42), cell_position, KRAFT)
			crate.set_meta(&"dispatch_case_cell", cell_index)
			_add_box(crate, "CaseTimberBand", Vector3(0.08, 0.32, 0.44), Vector3(0.0, 0.0, 0.0), DARK_KRAFT)
			_case_crates.append(crate)
			# One canonical case tag per rack bank is enough to communicate lot
			# identity at inspection distance. Typesetting all 42 cells would create
			# dozens of high-resolution glyph textures for copy too small to read.
			if row == 0 and column == 0:
				var tag := EnvironmentalSignageScript.add_panel(
					crate,
					"DispatchCaseTag_%02d" % cell_index,
					"PACKED BY THE FLOCK\nEMPTY CASE CELL",
					Vector3(0.0, 0.0, 0.220),
					Vector2(0.34, 0.20),
					KRAFT,
					GRAPHITE,
					Vector3.ZERO,
					8,
					0.00125,
					&"utility",
					&"shipping",
				)
				tag.set_meta(&"dispatch_case_index", cell_index)
				_case_tags.append(tag)


func _mesh_belongs_to_cumulative_level(instance: MeshInstance3D, level: int) -> bool:
	if level <= 0:
		return false
	if owned_site_root != null and owned_site_root.is_ancestor_of(instance):
		if level_3_root != null and level_3_root.is_ancestor_of(instance):
			return level >= 3
		if level_2_root != null and level_2_root.is_ancestor_of(instance):
			return level >= 2
		if level_1_root != null and level_1_root.is_ancestor_of(instance):
			return level >= 1
		return true
	return false


func _is_connector_geometry(instance: MeshInstance3D) -> bool:
	var cursor: Node = instance
	while cursor != null and cursor != self:
		if bool(cursor.get_meta(&"campus_connector", false)):
			return true
		cursor = cursor.get_parent()
	return false


func _is_authorized_vehicle_geometry(instance: MeshInstance3D) -> bool:
	var cursor: Node = instance
	while cursor != null and cursor != self:
		if bool(cursor.get_meta(&"authorized_vehicle", false)):
			return true
		cursor = cursor.get_parent()
	return false


func _is_authorized_lane_overhead_geometry(instance: MeshInstance3D) -> bool:
	var cursor: Node = instance
	while cursor != null and cursor != self:
		if bool(cursor.get_meta(&"authorized_vehicle_lane_overhead", false)):
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


func _add_box(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	part_position: Vector3,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0,
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_cylinder(
	parent: Node3D,
	part_name: String,
	part_position: Vector3,
	radius: float,
	height: float,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0,
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_sphere(
	parent: Node3D,
	part_name: String,
	part_position: Vector3,
	part_scale: Vector3,
	color: Color,
	roughness: float = 0.82,
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color, roughness)
	parent.add_child(instance)
	return instance


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.3f|%.3f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive|%s|%.3f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.34)
	material.roughness = 0.44
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	_material_cache[key] = material
	return material
