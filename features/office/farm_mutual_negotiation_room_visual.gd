class_name FarmMutualNegotiationRoomVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only negotiation pavilion for Farm Mutual. The room
## occupies its own north expansion parcel and never contributes collision or
## navigation geometry. Empty folios, progress lights, and settlement markers
## remain visually absent until the simulation supplies an authoritative record.
const FACILITY_ID: StringName = &"farm_mutual_negotiation_room"
const FACILITY_CENTER := Vector3(15.20, 0.0, 12.00)
const FOCUS_POINT := Vector3(15.20, 1.18, 12.00)
const FOOTPRINT := Rect2(Vector2(12.00, 9.10), Vector2(6.40, 5.80))
const MAX_LEVEL := 1
const MAX_OPAQUE_HEIGHT := 4.05
const CLAUSE_FOLIO_COUNT := 4
const DELIVERY_PIP_COUNT := 6
const SEAT_PIP_COUNT := 6

const DEEP_GREEN := Color("203a36")
const ENAMEL_GREEN := Color("2b4c45")
const SAGE := Color("778a7b")
const CREAM := Color("e6ddc4")
const PAPER := Color("ddd2b6")
const WALNUT := Color("6d4d35")
const DARK_WALNUT := Color("49362b")
const FELT := Color("335f53")
const BRASS := Color("c39d50")
const GRAPHITE := Color("2c3436")
const SERVICE_GREY := Color("6f7a79")
const BARN_RED := Color("934d43")
const AMBER := Color("d7aa50")
const SUCCESS_GREEN := Color("62906c")
const BREACH_RED := Color("a34e46")
const GLASS := Color("7fa3a366")
const BLUEPRINT := Color("547d89")

var locked_marker_root: Node3D
var construction_prospect_root: Node3D
var owned_room_root: Node3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _chicken_chairs: Array[Node3D] = []
var _farmer_credit_chair: Node3D
var _clause_folios: Array[Node3D] = []
var _delivery_pips: Array[MeshInstance3D] = []
var _seat_pips: Array[MeshInstance3D] = []
var _active_rider_clip: Node3D
var _active_rider_label: Label3D
var _active_category_strip: MeshInstance3D
var _season_medallion: Node3D
var _season_label: Label3D
var _premium_marker: Node3D
var _breach_marker: Node3D
var _premium_label: Label3D
var _breach_label: Label3D
var _pendant_light: OmniLight3D

var _built := false
var _has_applied_snapshot := false
var _unlocked := false
var _facility_level := 0
var _season_key := ""
var _has_season := false
var _active_clause_id: StringName = &""
var _active_clause_label := ""
var _active_clause_category: StringName = &""
var _last_result: Dictionary = {}
var _result_state: StringName = &"none"
var _delivery_completed := 0
var _delivery_required := 0
var _seats_filled := 0
var _seats_required := 0
var _premium_cents := 0
var _breach_cents := 0


func _ready() -> void:
	name = "FarmMutualNegotiationRoomVisual"
	position = FACILITY_CENTER
	set_meta(&"facility_id", FACILITY_ID)
	set_meta(&"visual_only", true)
	set_meta(&"collision_free", true)
	set_meta(&"navigation_free", true)
	set_meta(&"declared_footprint", FOOTPRINT)
	set_meta(&"maximum_visual_height", MAX_OPAQUE_HEIGHT)
	if not _built:
		build()


static func declared_footprint() -> Rect2:
	return FOOTPRINT


static func facility_footprint() -> Rect2:
	return FOOTPRINT


static func facility_focus_point() -> Vector3:
	return FOCUS_POINT


static func maximum_visual_height() -> float:
	return MAX_OPAQUE_HEIGHT


func focus_point_global() -> Vector3:
	return to_global(Vector3(0.0, FOCUS_POINT.y, 0.0))


func build() -> void:
	clear()
	_built = true
	position = FACILITY_CENTER
	_build_locked_marker()
	_build_construction_prospect()
	_build_owned_room()
	_apply_visibility()
	_apply_dynamic_state()
	EnvironmentalSignageScript.set_camera_detail(self, false, FOCUS_POINT, 2.75, false)


func clear() -> void:
	for visual_root in [locked_marker_root, construction_prospect_root, owned_room_root]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	locked_marker_root = null
	construction_prospect_root = null
	owned_room_root = null
	_chicken_chairs.clear()
	_farmer_credit_chair = null
	_clause_folios.clear()
	_delivery_pips.clear()
	_seat_pips.clear()
	_active_rider_clip = null
	_active_rider_label = null
	_active_category_strip = null
	_season_medallion = null
	_season_label = null
	_premium_marker = null
	_breach_marker = null
	_premium_label = null
	_breach_label = null
	_pendant_light = null
	_material_cache.clear()
	_has_applied_snapshot = false
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var board := _snapshot_dictionary(snapshot.get("contract_board", {}))
	var catalog_entry := _catalog_entry(snapshot)
	_facility_level = clampi(_snapshot_facility_level(snapshot, catalog_entry), 0, MAX_LEVEL)
	_unlocked = (
		_facility_level > 0
		or bool(catalog_entry.get(
			"unlocked",
			catalog_entry.get("available", catalog_entry.get("can_purchase", false)),
		))
	)

	var season_variant: Variant = board.get("season", board.get("contract_season", null))
	_has_season = board.has("season") or board.has("contract_season")
	_season_key = _season_copy(season_variant) if _has_season else ""

	var active := _snapshot_dictionary(board.get("active", board.get("active_contract", {})))
	_active_clause_id = StringName(String(active.get(
		"clause_id",
		board.get("clause_id", active.get("id", "")),
	)))
	_active_clause_label = String(active.get(
		"clause_label",
		board.get("clause_label", active.get("label", active.get("name", ""))),
	)).strip_edges()
	_active_clause_category = StringName(String(active.get(
		"clause_category",
		board.get("clause_category", active.get("category", "")),
	)))
	if _active_clause_id == &"" and not _active_clause_label.is_empty():
		_active_clause_id = StringName(_active_clause_label.to_snake_case())

	_delivery_completed = maxi(0, int(active.get(
		"timely_sound_completed",
		active.get("qualified_completed", active.get("completed", 0)),
	)))
	_delivery_required = maxi(0, int(active.get(
		"required_completed",
		active.get("required_deliveries", active.get("delivery_target", 0)),
	)))
	_seats_filled = maxi(0, int(active.get(
		"active_staff",
		active.get("assigned_staff", active.get("staff_count", active.get("seats_filled", 0))),
	)))
	_seats_required = maxi(0, int(active.get(
		"required_active_staff",
		active.get("required_staff", active.get("seat_requirement", 0)),
	)))

	_last_result = _snapshot_dictionary(board.get("last_result", {}))
	_result_state = _classify_result(_last_result)
	_premium_cents = maxi(0, int(_last_result.get(
		"premium_cents",
		_last_result.get("premium_paid_cents", _last_result.get("payout_cents", 0)),
	)))
	_breach_cents = maxi(0, int(_last_result.get(
		"breach_cents",
		_last_result.get("breach_cost_cents", _last_result.get("penalty_cents", 0)),
	)))

	_apply_visibility()
	_apply_dynamic_state()
	if _has_applied_snapshot and _facility_level > previous_level and is_inside_tree():
		_animate_owned_reveal()
	_has_applied_snapshot = true


func set_camera_detail(focused: bool, focus_position: Vector3 = Vector3(INF, INF, INF)) -> void:
	EnvironmentalSignageScript.set_camera_detail(self, focused, focus_position, 2.75)


func visual_state() -> StringName:
	if _facility_level > 0:
		return &"owned"
	return &"construction_prospect" if _unlocked else &"locked"


func current_level() -> int:
	return _facility_level


func facility_level() -> int:
	return _facility_level


func locked_marker_visible() -> bool:
	return locked_marker_root != null and locked_marker_root.visible


func construction_prospect_visible() -> bool:
	return construction_prospect_root != null and construction_prospect_root.visible


func owned_room_visible() -> bool:
	return owned_room_root != null and owned_room_root.visible


func chicken_perch_chair_count() -> int:
	return _chicken_chairs.size()


func farmer_credit_chair_present() -> bool:
	return _farmer_credit_chair != null and is_instance_valid(_farmer_credit_chair)


func visible_clause_folio_count() -> int:
	var count := 0
	for folio in _clause_folios:
		if is_instance_valid(folio) and folio.visible:
			count += 1
	return count


func active_rider_visible() -> bool:
	return _active_rider_clip != null and _active_rider_clip.visible


func lit_delivery_pip_count() -> int:
	return mini(_delivery_completed, DELIVERY_PIP_COUNT) if not _active_clause_id.is_empty() else 0


func lit_seat_pip_count() -> int:
	return mini(_seats_filled, SEAT_PIP_COUNT) if not _active_clause_id.is_empty() else 0


func premium_marker_visible() -> bool:
	return _premium_marker != null and _premium_marker.visible


func breach_marker_visible() -> bool:
	return _breach_marker != null and _breach_marker.visible


func active_clause_id() -> StringName:
	return _active_clause_id


func active_clause_category() -> StringName:
	return _active_clause_category


func season_key() -> String:
	return _season_key


func debug_state() -> Dictionary:
	return {
		"facility_id": FACILITY_ID,
		"state": visual_state(),
		"level": _facility_level,
		"unlocked": _unlocked,
		"season": _season_key,
		"has_season": _has_season,
		"active_clause_id": _active_clause_id,
		"active_clause_label": _active_clause_label,
		"active_clause_category": _active_clause_category,
		"delivery_completed": _delivery_completed,
		"delivery_required": _delivery_required,
		"seats_filled": _seats_filled,
		"seats_required": _seats_required,
		"visible_clause_folios": visible_clause_folio_count(),
		"lit_delivery_pips": lit_delivery_pip_count(),
		"lit_seat_pips": lit_seat_pip_count(),
		"result_state": _result_state,
		"premium_cents": _premium_cents,
		"breach_cents": _breach_cents,
		"footprint": FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func geometry_bounds_inside_footprint() -> bool:
	## Audit every state, including hidden construction and owned geometry.
	var local_half := FOOTPRINT.size * 0.5
	var tolerance := 0.012
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := instance.mesh.get_aabb()
		var bounds_end := bounds.position + bounds.size
		for corner_x in [bounds.position.x, bounds_end.x]:
			for corner_y in [bounds.position.y, bounds_end.y]:
				for corner_z in [bounds.position.z, bounds_end.z]:
					var local_corner := to_local(instance.to_global(Vector3(corner_x, corner_y, corner_z)))
					if (
						absf(local_corner.x) > local_half.x + tolerance
						or absf(local_corner.z) > local_half.y + tolerance
						or local_corner.y > MAX_OPAQUE_HEIGHT + tolerance
					):
						return false
	return true


func geometry_bounds_global() -> AABB:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	var found_geometry := false
	for candidate in find_children("*", "MeshInstance3D", true, false):
		var instance := candidate as MeshInstance3D
		if instance == null or instance.mesh == null:
			continue
		var bounds := instance.mesh.get_aabb()
		var bounds_end := bounds.position + bounds.size
		for corner_x in [bounds.position.x, bounds_end.x]:
			for corner_y in [bounds.position.y, bounds_end.y]:
				for corner_z in [bounds.position.z, bounds_end.z]:
					var world_corner := instance.to_global(Vector3(corner_x, corner_y, corner_z))
					minimum = minimum.min(world_corner)
					maximum = maximum.max(world_corner)
					found_geometry = true
	return AABB(minimum, maximum - minimum) if found_geometry else AABB()


func _apply_visibility() -> void:
	if locked_marker_root != null:
		locked_marker_root.visible = not _unlocked and _facility_level <= 0
	if construction_prospect_root != null:
		construction_prospect_root.visible = _unlocked and _facility_level <= 0
	if owned_room_root != null:
		owned_room_root.visible = _facility_level >= 1


func _apply_dynamic_state() -> void:
	var has_clause_record := not _active_clause_id.is_empty()
	var show_folios := _has_season or has_clause_record
	for folio_index in _clause_folios.size():
		var folio := _clause_folios[folio_index]
		folio.visible = show_folios
		folio.set_meta(&"authoritative_record", show_folios)

	if _season_medallion != null:
		_season_medallion.visible = _has_season
	if _season_label != null:
		_season_label.text = _season_key if not _season_key.is_empty() else "SEASON"
		EnvironmentalSignageScript.refit_label(_season_label)

	if _active_rider_clip != null:
		_active_rider_clip.visible = has_clause_record
	if _active_rider_label != null:
		var clause_copy := _active_clause_label
		if clause_copy.is_empty():
			clause_copy = String(_active_clause_id).replace("_", " ").capitalize()
		if clause_copy.is_empty():
			# The authoritative slip stays hidden until a negotiated record exists,
			# but its physically printed fallback must not become an empty signage
			# fixture while the room is idle.
			clause_copy = "ACTIVE RIDER"
		var category_copy := String(_active_clause_category).replace("_", " ").to_upper()
		_active_rider_label.text = (
			"%s\n%s" % [clause_copy.to_upper(), category_copy]
			if not category_copy.is_empty()
			else clause_copy.to_upper()
		)
		EnvironmentalSignageScript.refit_label(_active_rider_label)
	if _active_category_strip != null:
		_active_category_strip.material_override = _material(_category_color(_active_clause_category), 0.62, 0.08)

	var delivery_lit := lit_delivery_pip_count()
	for pip_index in _delivery_pips.size():
		_delivery_pips[pip_index].material_override = (
			_emissive_material(SUCCESS_GREEN, 0.72)
			if pip_index < delivery_lit
			else _material(GRAPHITE.lightened(0.05), 0.70)
		)
	var seats_lit := lit_seat_pip_count()
	for pip_index in _seat_pips.size():
		_seat_pips[pip_index].material_override = (
			_emissive_material(AMBER, 0.62)
			if pip_index < seats_lit
			else _material(GRAPHITE.lightened(0.05), 0.70)
		)

	if _premium_marker != null:
		_premium_marker.visible = _result_state == &"success" and _premium_cents > 0
	if _breach_marker != null:
		_breach_marker.visible = _result_state == &"breach" and _breach_cents > 0
	if _premium_label != null:
		_premium_label.text = "PREMIUM PAID  $%.2f" % (float(_premium_cents) / 100.0)
		EnvironmentalSignageScript.refit_label(_premium_label)
	if _breach_label != null:
		_breach_label.text = "BREACH DUE  $%.2f" % (float(_breach_cents) / 100.0)
		EnvironmentalSignageScript.refit_label(_breach_label)


func _animate_owned_reveal() -> void:
	if owned_room_root == null or not is_instance_valid(owned_room_root):
		return
	owned_room_root.scale = Vector3(1.0, 0.06, 1.0)
	var reveal := create_tween().bind_node(owned_room_root)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(owned_room_root, "scale", Vector3.ONE, 0.56)


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "NegotiationRoomLockedSurvey"
	locked_marker_root.set_meta(&"facility_state", &"locked")
	add_child(locked_marker_root)

	for edge_z in [-2.72, 2.72]:
		_add_box(locked_marker_root, "NegotiationLeaseBoundaryZ", Vector3(6.08, 0.035, 0.055), Vector3(0.0, 0.025, edge_z), BRASS.darkened(0.25), 0.72, 0.24)
	for side_x in [-3.02, 3.02]:
		for segment_z in [-1.70, 1.70]:
			_add_box(locked_marker_root, "NegotiationLeaseBoundaryX", Vector3(0.055, 0.035, 2.00), Vector3(side_x, 0.026, segment_z), BRASS.darkened(0.25), 0.72, 0.24)
	for corner_x in [-3.02, 3.02]:
		for corner_z in [-2.72, 2.72]:
			_add_cylinder(locked_marker_root, "NegotiationSurveyPin", Vector3(corner_x, 0.10, corner_z), 0.055, 0.20, BARN_RED, 0.60, 0.12)

	var marker := Node3D.new()
	marker.name = "NegotiationRoomGoldGateMarker"
	marker.position = Vector3(0.0, 0.0, -2.48)
	locked_marker_root.add_child(marker)
	for post_x in [-1.58, 1.58]:
		_add_box(marker, "NegotiationGatePost", Vector3(0.11, 1.42, 0.11), Vector3(post_x, 0.71, 0.0), WALNUT, 0.76)
	var face := _add_box(marker, "NegotiationGateFace", Vector3(3.82, 1.10, 0.12), Vector3(0.0, 1.22, 0.0), DEEP_GREEN, 0.78)
	EnvironmentalSignageScript.add_panel(face, "NegotiationRoomLeaseOption", "MUTUAL COUNCIL PARCEL", Vector3(0.0, 0.17, 0.072), Vector2(3.34, 0.38), DEEP_GREEN, CREAM, Vector3.ZERO, 17, 0.0033, &"secondary", &"beam")
	EnvironmentalSignageScript.add_panel(face, "NegotiationRoomGoldPending", "GOLD STANDING + COOP III", Vector3(0.0, -0.28, 0.072), Vector2(2.86, 0.18), ENAMEL_GREEN, BRASS, Vector3.ZERO, 10, 0.0022, &"utility", &"stencil")


func _build_construction_prospect() -> void:
	construction_prospect_root = Node3D.new()
	construction_prospect_root.name = "NegotiationRoomConstructionProspect"
	construction_prospect_root.set_meta(&"facility_state", &"construction_prospect")
	add_child(construction_prospect_root)

	_add_box(construction_prospect_root, "NegotiationProspectFoundation", Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0), SERVICE_GREY.darkened(0.10), 0.94)
	_add_box(construction_prospect_root, "NegotiationProspectInset", Vector3(6.08, 0.018, 5.48), Vector3(0.0, -0.010, 0.0), GRAPHITE.lightened(0.10), 0.96)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(construction_prospect_root, "NegotiationProspectRuleX", Vector3(0.024, 0.008, 5.20), Vector3(grid_x, 0.004, 0.0), CREAM.darkened(0.18), 0.98)
	for grid_z in [-1.70, 0.0, 1.70]:
		_add_box(construction_prospect_root, "NegotiationProspectRuleZ", Vector3(5.70, 0.008, 0.024), Vector3(0.0, 0.005, grid_z), CREAM.darkened(0.18), 0.98)
	for stake_x in [-2.84, 2.84]:
		for stake_z in [-2.50, 2.50]:
			_add_box(construction_prospect_root, "NegotiationProspectStake", Vector3(0.08, 0.62, 0.08), Vector3(stake_x, 0.31, stake_z), WALNUT, 0.78)
			_add_box(construction_prospect_root, "NegotiationProspectFlag", Vector3(0.34, 0.17, 0.018), Vector3(stake_x + 0.13, 0.50, stake_z), BARN_RED, 0.88)

	var plan_table := Node3D.new()
	plan_table.name = "NegotiationRoomProspectPlanTable"
	plan_table.position = Vector3(-1.62, 0.0, 1.30)
	construction_prospect_root.add_child(plan_table)
	_add_box(plan_table, "NegotiationProspectPlanTop", Vector3(1.72, 0.10, 0.94), Vector3(0.0, 0.84, 0.0), WALNUT, 0.76)
	for leg_x in [-0.70, 0.70]:
		for leg_z in [-0.35, 0.35]:
			_add_box(plan_table, "NegotiationProspectPlanLeg", Vector3(0.09, 0.80, 0.09), Vector3(leg_x, 0.40, leg_z), GRAPHITE, 0.56, 0.30)
	var plan := _add_box(plan_table, "NegotiationPavilionBlueprint", Vector3(1.44, 0.014, 0.70), Vector3(0.0, 0.899, 0.0), BLUEPRINT, 0.96)
	for line_index in 5:
		_add_box(plan, "NegotiationBlueprintRule", Vector3(1.10 - line_index * 0.08, 0.004, 0.012), Vector3(0.0, 0.011, -0.26 + line_index * 0.13), CREAM, 0.96)

	var notice := _add_box(construction_prospect_root, "NegotiationConstructionNoticeHost", Vector3(3.30, 0.84, 0.11), Vector3(0.20, 0.76, -2.54), DEEP_GREEN, 0.78)
	EnvironmentalSignageScript.add_panel(notice, "NegotiationRoomConstructionNotice", "COUNCIL PAVILION\nFIXTURE QUOTES FILED", Vector3(0.0, 0.0, 0.065), Vector2(2.96, 0.58), DEEP_GREEN, CREAM, Vector3.ZERO, 14, 0.0028, &"secondary", &"machine")

	var crate := Node3D.new()
	crate.name = "UnopenedNegotiationFixtureCrate"
	crate.position = Vector3(1.55, 0.0, 1.18)
	construction_prospect_root.add_child(crate)
	_add_box(crate, "NegotiationFixtureCrateBody", Vector3(1.62, 0.92, 1.12), Vector3(0.0, 0.48, 0.0), Color("b58e5b"), 0.90)
	for slat_y in [0.16, 0.48, 0.80]:
		_add_box(crate, "NegotiationFixtureCrateSlat", Vector3(1.68, 0.09, 1.18), Vector3(0.0, slat_y, 0.0), WALNUT, 0.78)
	_add_box(crate, "NegotiationFixtureCrateBand", Vector3(0.18, 0.96, 1.16), Vector3(0.0, 0.48, 0.0), BRASS.darkened(0.18), 0.62, 0.26)


func _build_owned_room() -> void:
	owned_room_root = Node3D.new()
	owned_room_root.name = "FarmMutualNegotiationPavilion"
	owned_room_root.set_meta(&"facility_state", &"owned")
	owned_room_root.set_meta(&"physical_records_only", true)
	add_child(owned_room_root)
	_build_pavilion_shell(owned_room_root)
	_build_negotiation_table(owned_room_root)
	_build_negotiation_seating(owned_room_root)
	_build_clause_folios(owned_room_root)
	_build_signing_station(owned_room_root)
	_build_settlement_trays(owned_room_root)
	_build_season_medallion(owned_room_root)
	_build_progress_pips(owned_room_root)
	_build_pendant(owned_room_root)


func _build_pavilion_shell(parent: Node3D) -> void:
	# The management camera approaches from positive X / positive Z. Treat the
	# north and east faces as an intentional isometric cutaway so the table,
	# chairs, folios, and settlement hardware remain legible during overview and
	# purchase-focus shots.
	parent.set_meta(&"management_camera_cutaway", true)
	_add_box(parent, "NegotiationRoomConnectedPad", Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0), Color("505a58"), 0.94)
	_add_box(parent, "NegotiationRoomFloorInset", Vector3(6.08, 0.018, 5.48), Vector3(0.0, -0.010, 0.0), Color("3e4947"), 0.96)
	_add_box(parent, "NegotiationRoomEntryThreshold", Vector3(4.80, 0.07, 0.13), Vector3(0.0, 0.035, -2.68), BRASS.darkened(0.18), 0.70, 0.28)

	# The south face stays completely open to the office. Slender posts, high
	# ties, and reeded side glass create a room without adding route blockers.
	for post_x in [-3.06, 3.06]:
		for post_z in [-2.63, 2.63]:
			_add_box(parent, "NegotiationPavilionPost", Vector3(0.14, 3.48, 0.14), Vector3(post_x, 1.74, post_z), DEEP_GREEN, 0.66, 0.16)
	for beam_z in [-2.62, 2.62]:
		_add_box(parent, "NegotiationPavilionCrossBeam", Vector3(6.04, 0.15, 0.15), Vector3(0.0, 3.48, beam_z), DEEP_GREEN, 0.64, 0.18)
	for tie_x in [-2.56, 0.0, 2.56]:
		_add_box(parent, "NegotiationPavilionRoofTie", Vector3(0.12, 0.12, 5.08), Vector3(tie_x, 3.49, 0.0), ENAMEL_GREEN, 0.64, 0.16)
	for slat_x in [-2.70, -1.80, -0.90, 0.0, 0.90, 1.80, 2.70]:
		_add_box(parent, "NegotiationPavilionCeilingSlat", Vector3(0.32, 0.08, 4.84), Vector3(slat_x, 3.65, 0.0), WALNUT.darkened(0.05), 0.70)

	# A low dado and two narrow glazed wings define the north boundary without
	# recreating the opaque slab that previously hid nearly the entire room from
	# the stable management-camera basis. The 3.24 m central opening is clear
	# from the brass sill to the suspended identity header.
	_add_box(parent, "NegotiationRoomNorthCutawayDado", Vector3(6.12, 0.46, 0.12), Vector3(0.0, 0.24, 2.71), SAGE, 0.82)
	_add_box(parent, "NegotiationRoomNorthCutawayCap", Vector3(6.12, 0.07, 0.18), Vector3(0.0, 0.505, 2.70), BRASS.darkened(0.12), 0.56, 0.34)
	var cutaway_header := _add_box(parent, "NegotiationRoomNorthCutawayHeader", Vector3(6.12, 0.15, 0.16), Vector3(0.0, 2.52, 2.70), DEEP_GREEN, 0.64, 0.18)
	cutaway_header.set_meta(&"camera_facing_cutaway", true)
	for wing_record in [
		{"suffix": "West", "x": -2.40},
		{"suffix": "East", "x": 2.40},
	]:
		var suffix := String(wing_record.get("suffix", "Wing"))
		var wing_x := float(wing_record.get("x", 0.0))
		var north_glass := _add_glass_box(
			parent,
			"NegotiationRoomNorthReededGlass%s" % suffix,
			Vector3(1.12, 1.82, 0.045),
			Vector3(wing_x, 1.49, 2.69),
		)
		north_glass.set_meta(&"restrained_reeded_glass", true)
		north_glass.set_meta(&"cutaway_wing", true)
		for frame_offset in [-0.58, 0.58]:
			_add_box(
				parent,
				"NegotiationRoomNorthGlassFrame%s" % suffix,
				Vector3(0.075, 1.94, 0.075),
				Vector3(wing_x + frame_offset, 1.49, 2.69),
				ENAMEL_GREEN,
				0.64,
				0.16,
			)
		for reed_offset in [-0.36, 0.0, 0.36]:
			_add_box(
				parent,
				"NegotiationRoomNorthGlassReed%s" % suffix,
				Vector3(0.025, 1.70, 0.056),
				Vector3(wing_x + reed_offset, 1.49, 2.685),
				CREAM.darkened(0.22),
				0.62,
				0.12,
			)

	# Keep the room identity architectural, but lift it above the sightline. The
	# brass hangers visually connect it to the roof frame instead of leaving a
	# floating sign over the cutaway.
	for hanger_x in [-1.30, 1.30]:
		_add_box(parent, "NegotiationRoomIdentityHanger", Vector3(0.055, 0.78, 0.055), Vector3(hanger_x, 3.05, 2.69), BRASS.darkened(0.10), 0.52, 0.42)
	var identity_bed := _add_box(parent, "NegotiationRoomIdentityBed", Vector3(3.38, 0.50, 0.10), Vector3(0.0, 3.02, 2.625), ENAMEL_GREEN, 0.76, 0.08)
	identity_bed.set_meta(&"suspended_cutaway_header", true)
	# The identity faces positive Z, toward the management camera and the public
	# approach, so the lifted fascia reads as signage instead of a blank panel.
	EnvironmentalSignageScript.add_panel(identity_bed, "FarmMutualNegotiationIdentity", "FARM MUTUAL COUNCIL ROOM\nCLAUSE & CREDIT TABLE", Vector3(0.0, 0.0, 0.058), Vector2(3.08, 0.36), ENAMEL_GREEN, CREAM, Vector3.ZERO, 14, 0.0028, &"primary", &"destination")

	for side_x in [-2.99, 2.99]:
		var glass := _add_glass_box(parent, "NegotiationRoomReededGlass", Vector3(0.045, 2.30, 2.36), Vector3(side_x, 1.63, 0.34))
		glass.set_meta(&"restrained_reeded_glass", true)
		for reed_z in [-0.92, -0.46, 0.0, 0.46, 0.92]:
			_add_box(parent, "NegotiationGlassReed", Vector3(0.058, 2.20, 0.025), Vector3(side_x, 1.63, 0.34 + reed_z), CREAM.darkened(0.22), 0.62, 0.12)


func _build_negotiation_table(parent: Node3D) -> void:
	var table := Node3D.new()
	table.name = "WalnutOvalNegotiationTable"
	table.position = Vector3(0.0, 0.0, 0.18)
	table.set_meta(&"negotiation_surface", true)
	parent.add_child(table)
	_add_box(table, "NegotiationTableCentralTop", Vector3(2.62, 0.14, 1.48), Vector3(0.0, 0.94, 0.0), WALNUT, 0.66)
	_add_cylinder(table, "NegotiationTableOvalEndWest", Vector3(-1.31, 0.94, 0.0), 0.74, 0.14, WALNUT, 0.66)
	_add_cylinder(table, "NegotiationTableOvalEndEast", Vector3(1.31, 0.94, 0.0), 0.74, 0.14, WALNUT, 0.66)
	_add_box(table, "NegotiationTableFeltCenter", Vector3(2.34, 0.025, 1.10), Vector3(0.0, 1.022, 0.0), FELT, 0.92)
	_add_cylinder(table, "NegotiationTableFeltWest", Vector3(-1.17, 1.022, 0.0), 0.55, 0.025, FELT, 0.92)
	_add_cylinder(table, "NegotiationTableFeltEast", Vector3(1.17, 1.022, 0.0), 0.55, 0.025, FELT, 0.92)
	_add_cylinder(table, "NegotiationTablePedestal", Vector3(0.0, 0.49, 0.0), 0.30, 0.86, DARK_WALNUT, 0.68, 0.04)
	_add_box(table, "NegotiationTablePedestalFoot", Vector3(1.42, 0.12, 0.62), Vector3(0.0, 0.10, 0.0), GRAPHITE, 0.58, 0.28)
	for edge_x in [-1.96, 1.96]:
		_add_box(table, "NegotiationTableBrassCap", Vector3(0.05, 0.12, 0.72), Vector3(edge_x, 0.95, 0.0), BRASS, 0.42, 0.52)


func _build_negotiation_seating(parent: Node3D) -> void:
	var seats := [
		{"position": Vector3(-0.82, 0.0, -1.04), "rotation": 0.0},
		{"position": Vector3(0.82, 0.0, -1.04), "rotation": 0.0},
		{"position": Vector3(-0.82, 0.0, 1.40), "rotation": 180.0},
		{"position": Vector3(0.82, 0.0, 1.40), "rotation": 180.0},
		{"position": Vector3(-2.24, 0.0, 0.18), "rotation": -90.0},
		{"position": Vector3(2.24, 0.0, 0.18), "rotation": 90.0},
	]
	for seat_index in seats.size():
		var seat_record := seats[seat_index] as Dictionary
		var chair := _build_chicken_perch_chair(
			parent,
			seat_index,
			seat_record.get("position", Vector3.ZERO) as Vector3,
			float(seat_record.get("rotation", 0.0)),
		)
		_chicken_chairs.append(chair)

	_farmer_credit_chair = Node3D.new()
	_farmer_credit_chair.name = "FarmerCreditChair"
	_farmer_credit_chair.position = Vector3(0.0, 0.0, 2.18)
	_farmer_credit_chair.rotation_degrees.y = 180.0
	_farmer_credit_chair.set_meta(&"farmer_credit_chair", true)
	_farmer_credit_chair.set_meta(&"intentionally_empty", true)
	parent.add_child(_farmer_credit_chair)
	_add_box(_farmer_credit_chair, "FarmerChairSeat", Vector3(1.06, 0.18, 0.78), Vector3(0.0, 0.67, 0.0), DARK_WALNUT, 0.68)
	_add_box(_farmer_credit_chair, "FarmerChairSeatCushion", Vector3(0.94, 0.14, 0.68), Vector3(0.0, 0.82, -0.01), ENAMEL_GREEN, 0.82)
	for leg_x in [-0.43, 0.43]:
		for leg_z in [-0.27, 0.27]:
			_add_box(_farmer_credit_chair, "FarmerChairLeg", Vector3(0.12, 0.66, 0.12), Vector3(leg_x, 0.33, leg_z), GRAPHITE, 0.58, 0.24)
	_add_box(_farmer_credit_chair, "FarmerChairTallBack", Vector3(1.12, 1.18, 0.16), Vector3(0.0, 1.33, 0.31), DARK_WALNUT, 0.66)
	_add_box(_farmer_credit_chair, "FarmerChairBackInset", Vector3(0.90, 0.88, 0.07), Vector3(0.0, 1.34, 0.215), FELT, 0.86)
	_add_box(_farmer_credit_chair, "FarmerChairCreditCrest", Vector3(0.62, 0.16, 0.20), Vector3(0.0, 1.98, 0.31), BRASS, 0.46, 0.50)


func _build_chicken_perch_chair(parent: Node3D, seat_index: int, chair_position: Vector3, rotation_y: float) -> Node3D:
	var chair := Node3D.new()
	chair.name = "ChickenPerchChair_%02d" % (seat_index + 1)
	chair.position = chair_position
	chair.rotation_degrees.y = rotation_y
	chair.set_meta(&"negotiation_seat_index", seat_index)
	chair.set_meta(&"chicken_perch_chair", true)
	parent.add_child(chair)
	_add_box(chair, "PerchChairSeat", Vector3(0.68, 0.14, 0.54), Vector3(0.0, 0.56, 0.0), WALNUT, 0.70)
	_add_box(chair, "PerchChairCushion", Vector3(0.60, 0.10, 0.48), Vector3(0.0, 0.67, -0.01), SAGE, 0.88)
	for leg_x in [-0.25, 0.25]:
		for leg_z in [-0.19, 0.19]:
			_add_box(chair, "PerchChairLeg", Vector3(0.08, 0.54, 0.08), Vector3(leg_x, 0.27, leg_z), GRAPHITE, 0.58, 0.24)
	_add_box(chair, "PerchChairBack", Vector3(0.70, 0.66, 0.10), Vector3(0.0, 0.93, 0.23), DARK_WALNUT, 0.72)
	var perch := _add_cylinder(chair, "ChickenChairPerchRail", Vector3(0.0, 0.78, -0.02), 0.055, 0.58, BRASS.darkened(0.08), 0.54, 0.38)
	perch.rotation_degrees.z = 90.0
	return chair


func _build_clause_folios(parent: Node3D) -> void:
	var folio_x := [-1.22, -0.41, 0.41, 1.22]
	for folio_index in CLAUSE_FOLIO_COUNT:
		var folio := Node3D.new()
		folio.name = "AuthoritativeClauseFolio_%02d" % (folio_index + 1)
		folio.position = Vector3(folio_x[folio_index], 1.065, 0.03)
		folio.rotation_degrees.y = -4.0 + folio_index * 2.7
		folio.set_meta(&"clause_slot", folio_index)
		folio.set_meta(&"authoritative_record", false)
		parent.add_child(folio)
		_add_box(folio, "ClauseFolioCover", Vector3(0.58, 0.035, 0.40), Vector3.ZERO, [DEEP_GREEN, BARN_RED, BLUEPRINT, DARK_WALNUT][folio_index], 0.82)
		_add_box(folio, "ClauseFolioSpine", Vector3(0.07, 0.052, 0.42), Vector3(-0.27, 0.01, 0.0), BRASS.darkened(0.12), 0.58, 0.26)
		_add_box(folio, "ClauseFolioTab", Vector3(0.18, 0.025, 0.08), Vector3(0.14, 0.030, -0.21), PAPER, 0.94)
		_clause_folios.append(folio)


func _build_signing_station(parent: Node3D) -> void:
	var station := Node3D.new()
	station.name = "NegotiationSigningPressStation"
	station.position = Vector3(1.50, 1.04, 0.43)
	parent.add_child(station)
	_add_box(station, "SigningPressBase", Vector3(0.54, 0.10, 0.42), Vector3(0.0, 0.05, 0.0), GRAPHITE, 0.52, 0.44)
	_add_box(station, "SigningPressColumn", Vector3(0.10, 0.46, 0.10), Vector3(0.18, 0.27, 0.12), BRASS.darkened(0.08), 0.48, 0.52)
	var handle := _add_cylinder(station, "SigningPressHandle", Vector3(-0.02, 0.44, 0.12), 0.035, 0.42, DARK_WALNUT, 0.60)
	handle.rotation_degrees.z = 90.0
	_add_cylinder(station, "SigningPressSeal", Vector3(-0.04, 0.13, 0.0), 0.12, 0.08, BRASS, 0.42, 0.62)
	for seal_index in 3:
		_add_cylinder(station, "NegotiationWaxSeal_%02d" % (seal_index + 1), Vector3(-0.43 + seal_index * 0.20, 0.035, 0.16), 0.07, 0.035, [BARN_RED, ENAMEL_GREEN, AMBER][seal_index], 0.72)

	_active_rider_clip = Node3D.new()
	_active_rider_clip.name = "AuthoritativeActiveRiderClip"
	_active_rider_clip.position = Vector3(-0.28, 1.064, -0.43)
	_active_rider_clip.set_meta(&"authoritative_record_only", true)
	parent.add_child(_active_rider_clip)
	var rider_host := _add_box(_active_rider_clip, "ActiveRiderPaper", Vector3(2.14, 0.035, 0.46), Vector3(0.0, 0.0, 0.0), PAPER, 0.96)
	_add_box(_active_rider_clip, "ActiveRiderBrassClip", Vector3(0.32, 0.08, 0.12), Vector3(0.0, 0.045, -0.18), BRASS, 0.42, 0.58)
	_active_category_strip = _add_box(_active_rider_clip, "ActiveRiderCategoryStrip", Vector3(0.08, 0.055, 0.40), Vector3(-1.00, 0.02, 0.0), SAGE, 0.68)
	_active_rider_label = EnvironmentalSignageScript.add_panel(rider_host, "NegotiationActiveRiderCopy", "ACTIVE RIDER", Vector3(0.0, 0.026, 0.0), Vector2(1.84, 0.32), PAPER, GRAPHITE, Vector3(-90.0, 0.0, 0.0), 11, 0.0022, &"utility", &"paper")


func _build_settlement_trays(parent: Node3D) -> void:
	var tray_root := Node3D.new()
	tray_root.name = "NegotiationSettlementTrays"
	tray_root.position = Vector3(0.0, 0.0, 2.48)
	parent.add_child(tray_root)
	for tray_x in [-1.58, 1.58]:
		_add_box(tray_root, "SettlementTrayShelf", Vector3(1.62, 0.10, 0.42), Vector3(tray_x, 1.18, -0.18), DARK_WALNUT, 0.68)
		_add_box(tray_root, "SettlementTrayBack", Vector3(1.62, 0.46, 0.08), Vector3(tray_x, 1.37, 0.0), WALNUT, 0.72)
	_add_box(tray_root, "PremiumTrayEdge", Vector3(1.50, 0.11, 0.08), Vector3(-1.58, 1.27, -0.39), SUCCESS_GREEN, 0.64, 0.08)
	_add_box(tray_root, "BreachTrayEdge", Vector3(1.50, 0.11, 0.08), Vector3(1.58, 1.27, -0.39), BREACH_RED, 0.64, 0.08)

	var premium_host := _add_box(tray_root, "PremiumTrayPlaqueHost", Vector3(1.36, 0.24, 0.05), Vector3(-1.58, 1.43, -0.052), DEEP_GREEN, 0.76)
	EnvironmentalSignageScript.add_panel(premium_host, "PremiumTrayIdentity", "PREMIUM TRAY", Vector3(0.0, 0.0, -0.030), Vector2(1.18, 0.15), DEEP_GREEN, CREAM, Vector3(0.0, 180.0, 0.0), 9, 0.0020, &"utility", &"stencil")
	var breach_host := _add_box(tray_root, "BreachTrayPlaqueHost", Vector3(1.36, 0.24, 0.05), Vector3(1.58, 1.43, -0.052), DEEP_GREEN, 0.76)
	EnvironmentalSignageScript.add_panel(breach_host, "BreachTrayIdentity", "BREACH TRAY", Vector3(0.0, 0.0, -0.030), Vector2(1.18, 0.15), DEEP_GREEN, CREAM, Vector3(0.0, 180.0, 0.0), 9, 0.0020, &"utility", &"stencil")

	_premium_marker = Node3D.new()
	_premium_marker.name = "AuthoritativePremiumSettlementMarker"
	_premium_marker.position = Vector3(-1.58, 1.29, -0.19)
	_premium_marker.set_meta(&"authoritative_record_only", true)
	tray_root.add_child(_premium_marker)
	var premium_receipt := _add_box(_premium_marker, "PremiumSettlementReceipt", Vector3(1.22, 0.035, 0.30), Vector3.ZERO, PAPER, 0.96)
	_add_cylinder(_premium_marker, "PremiumSettlementSeal", Vector3(0.47, 0.055, 0.0), 0.09, 0.04, SUCCESS_GREEN, 0.64)
	_premium_label = EnvironmentalSignageScript.add_panel(premium_receipt, "PremiumSettlementCopy", "PREMIUM PAID", Vector3(-0.08, 0.026, 0.0), Vector2(0.92, 0.20), PAPER, GRAPHITE, Vector3(-90.0, 0.0, 0.0), 9, 0.0018, &"utility", &"paper")

	_breach_marker = Node3D.new()
	_breach_marker.name = "AuthoritativeBreachSettlementMarker"
	_breach_marker.position = Vector3(1.58, 1.29, -0.19)
	_breach_marker.set_meta(&"authoritative_record_only", true)
	tray_root.add_child(_breach_marker)
	var breach_receipt := _add_box(_breach_marker, "BreachSettlementReceipt", Vector3(1.22, 0.035, 0.30), Vector3.ZERO, PAPER.darkened(0.05), 0.96)
	_add_cylinder(_breach_marker, "BreachSettlementSeal", Vector3(0.47, 0.055, 0.0), 0.09, 0.04, BREACH_RED, 0.64)
	_breach_label = EnvironmentalSignageScript.add_panel(breach_receipt, "BreachSettlementCopy", "BREACH DUE", Vector3(-0.08, 0.026, 0.0), Vector2(0.92, 0.20), PAPER, GRAPHITE, Vector3(-90.0, 0.0, 0.0), 9, 0.0018, &"utility", &"paper")


func _build_season_medallion(parent: Node3D) -> void:
	_season_medallion = Node3D.new()
	_season_medallion.name = "AuthoritativeSeasonMedallion"
	_season_medallion.position = Vector3(-2.18, 2.08, 2.59)
	_season_medallion.rotation_degrees.x = 90.0
	_season_medallion.set_meta(&"authoritative_record_only", true)
	parent.add_child(_season_medallion)
	_add_cylinder(_season_medallion, "SeasonMedallionBrassRim", Vector3.ZERO, 0.43, 0.08, BRASS, 0.42, 0.62)
	var face := _add_cylinder(_season_medallion, "SeasonMedallionEnamelFace", Vector3(0.0, 0.046, 0.0), 0.35, 0.035, DEEP_GREEN, 0.70, 0.10)
	_season_label = EnvironmentalSignageScript.add_panel(face, "NegotiationSeasonCopy", "SEASON", Vector3(0.0, 0.024, 0.0), Vector2(0.56, 0.20), DEEP_GREEN, CREAM, Vector3(-90.0, 0.0, 0.0), 9, 0.0018, &"secondary", &"machine")


func _build_progress_pips(parent: Node3D) -> void:
	var board := Node3D.new()
	board.name = "NegotiationDeliveryAndSeatPips"
	board.position = Vector3(2.12, 1.93, 2.58)
	parent.add_child(board)
	var host := _add_box(board, "NegotiationPipBoardHost", Vector3(1.74, 0.82, 0.09), Vector3.ZERO, DEEP_GREEN, 0.76)
	EnvironmentalSignageScript.add_panel(host, "NegotiationPipBoardHeading", "DELIVERIES / SEATS", Vector3(0.0, 0.28, -0.052), Vector2(1.46, 0.16), DEEP_GREEN, CREAM, Vector3(0.0, 180.0, 0.0), 9, 0.0019, &"utility", &"stencil")
	for pip_index in DELIVERY_PIP_COUNT:
		var x := -0.62 + pip_index * 0.25
		var delivery := _add_cylinder(board, "AuthoritativeDeliveryPip_%02d" % (pip_index + 1), Vector3(x, 0.08, -0.08), 0.065, 0.035, GRAPHITE, 0.70)
		delivery.rotation_degrees.x = 90.0
		_delivery_pips.append(delivery)
		var seat := _add_cylinder(board, "AuthoritativeSeatPip_%02d" % (pip_index + 1), Vector3(x, -0.17, -0.08), 0.065, 0.035, GRAPHITE, 0.70)
		seat.rotation_degrees.x = 90.0
		_seat_pips.append(seat)


func _build_pendant(parent: Node3D) -> void:
	var pendant := Node3D.new()
	pendant.name = "NegotiationWarmPendant"
	pendant.position = Vector3(0.0, 0.0, 0.15)
	parent.add_child(pendant)
	_add_cylinder(pendant, "PendantCeilingRose", Vector3(0.0, 3.61, 0.0), 0.20, 0.08, BRASS.darkened(0.12), 0.42, 0.52)
	_add_cylinder(pendant, "PendantStem", Vector3(0.0, 3.24, 0.0), 0.025, 0.70, GRAPHITE, 0.46, 0.42)
	var shade_mesh := CylinderMesh.new()
	shade_mesh.top_radius = 0.18
	shade_mesh.bottom_radius = 0.48
	shade_mesh.height = 0.34
	shade_mesh.radial_segments = 20
	var shade := MeshInstance3D.new()
	shade.name = "PendantWarmEnamelShade"
	shade.mesh = shade_mesh
	shade.position = Vector3(0.0, 2.84, 0.0)
	shade.material_override = _material(CREAM, 0.70, 0.08)
	pendant.add_child(shade)
	_add_cylinder(pendant, "PendantWarmDiffuser", Vector3(0.0, 2.64, 0.0), 0.30, 0.035, Color("f2cf82aa"), 0.56)
	_pendant_light = OmniLight3D.new()
	_pendant_light.name = "NegotiationWarmPendantLight"
	_pendant_light.position = Vector3(0.0, 2.56, 0.0)
	_pendant_light.light_color = Color("ffd795")
	_pendant_light.light_energy = 1.05
	_pendant_light.omni_range = 5.8
	_pendant_light.shadow_enabled = false
	pendant.add_child(_pendant_light)


func _snapshot_facility_level(snapshot: Dictionary, catalog_entry: Dictionary) -> int:
	var owned_variant: Variant = snapshot.get("owned_facilities", {})
	if owned_variant is Dictionary:
		var owned := owned_variant as Dictionary
		if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
			return _level_from_variant(owned.get(FACILITY_ID, owned.get(String(FACILITY_ID), 0)))
	if not catalog_entry.is_empty():
		var level := int(catalog_entry.get("level", catalog_entry.get("owned_level", 0)))
		if level > 0:
			return level
		if bool(catalog_entry.get("installed", catalog_entry.get("owned", false))):
			return 1
	return 0


func _catalog_entry(snapshot: Dictionary) -> Dictionary:
	var catalog_variant: Variant = snapshot.get("facility_catalog", [])
	if catalog_variant is Array:
		for entry_variant in catalog_variant as Array:
			if entry_variant is Dictionary:
				var entry := entry_variant as Dictionary
				if StringName(String(entry.get("id", ""))) == FACILITY_ID:
					return entry
	elif catalog_variant is Dictionary:
		var catalog := catalog_variant as Dictionary
		var entry_variant: Variant = catalog.get(FACILITY_ID, catalog.get(String(FACILITY_ID), {}))
		if entry_variant is Dictionary:
			return entry_variant as Dictionary
	return {}


func _level_from_variant(value: Variant) -> int:
	if value is Dictionary:
		var record := value as Dictionary
		return int(record.get("level", record.get("owned_level", 1 if bool(record.get("owned", false)) else 0)))
	if value is bool:
		return 1 if bool(value) else 0
	return int(value)


func _snapshot_dictionary(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _season_copy(value: Variant) -> String:
	if value is Dictionary:
		var season := value as Dictionary
		var label := String(season.get("label", season.get("name", season.get("id", "")))).strip_edges()
		return label.to_upper() if not label.is_empty() else "SEASON"
	if value is int or value is float:
		return "SEASON %02d" % int(value)
	var text := String(value).strip_edges()
	return text.to_upper() if not text.is_empty() else "SEASON"


func _classify_result(result: Dictionary) -> StringName:
	if result.is_empty():
		return &"none"
	if bool(result.get("success", false)):
		return &"success"
	if bool(result.get("breached", false)):
		return &"breach"
	var status := StringName(String(result.get("status", result.get("outcome", ""))).to_lower())
	if status in [&"fulfilled", &"success", &"paid", &"completed"]:
		return &"success"
	if status in [&"breached", &"breach", &"failed", &"failure"]:
		return &"breach"
	return &"none"


func _category_color(category: StringName) -> Color:
	match category:
		&"delivery", &"quota", &"throughput":
			return SUCCESS_GREEN
		&"staffing", &"attendance", &"roster":
			return AMBER
		&"risk", &"breach", &"compliance":
			return BREACH_RED
		&"quality", &"grading":
			return BLUEPRINT
	return SAGE


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
	mesh.top_radius = radius * 0.96
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, GLASS, 0.24, 0.04)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glass


func _material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive_%s_%.2f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.42)
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	_material_cache[key] = material
	return material
