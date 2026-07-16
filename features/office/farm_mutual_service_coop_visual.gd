class_name FarmMutualServiceCoopVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only Farm Mutual accreditation campus. The coop
## mirrors the two existing east-side annex parcels while leaving the office's
## open service edge and every authored chicken route untouched. It displays
## standing, binder delivery, rush, and settlement records; it never creates or
## settles those records itself.
const FACILITY_ID: StringName = &"farm_mutual_service_coop"
const FACILITY_CENTER := Vector3(15.20, 0.0, 6.00)
const FOCUS_POINT := Vector3(15.20, 1.05, 6.00)
const FOOTPRINT := Rect2(Vector2(12.00, 3.10), Vector2(6.40, 5.80))
const MAX_LEVEL := 3
const MAX_OPAQUE_HEIGHT := 4.25
const MAX_DISPATCH_PACKETS := 6
const STANDING_SEGMENT_COUNT := 12

const LANE_ORDER: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const LANE_COLORS := {
	&"nest_damage": Color("65a993"),
	&"predator_loss": Color("c57e4c"),
	&"appeals": Color("9277a6"),
}

const DEEP_GREEN := Color("1f3835")
const ENAMEL_GREEN := Color("294b45")
const SAGE := Color("63766b")
const CREAM := Color("e5dcc2")
const PAPER := Color("ddd2b7")
const KRAFT := Color("b58d59")
const TIMBER := Color("73543b")
const DARK_TIMBER := Color("4c3b31")
const BRASS := Color("c09b4e")
const GRAPHITE := Color("293235")
const SERVICE_GREY := Color("687477")
const BARN_RED := Color("914a40")
const OXIDE := Color("6b3935")
const AMBER := Color("d2a44a")
const SUCCESS_GREEN := Color("5f8e68")
const GLASS := Color("78999b66")
const BLUEPRINT := Color("537c89")

var locked_marker_root: Node3D
var survey_site_root: Node3D
var level_one_root: Node3D
var level_two_root: Node3D
var level_three_root: Node3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _standing_segments: Array[MeshInstance3D] = []
var _totem_segments: Array[MeshInstance3D] = []
var _dispatch_packets: Array[Node3D] = []
var _standing_label: Label3D
var _dispatch_label: Label3D
var _bonus_label: Label3D
var _active_lamp: MeshInstance3D
var _rush_lamp: MeshInstance3D
var _success_lamp: MeshInstance3D
var _breach_shutter: Node3D

var _built := false
var _has_applied_snapshot := false
var _unlocked := false
var _facility_level := 0
var _standing_score := 0
var _standing_rank: StringName = &"provisional"
var _next_standing_score := 2
var _active_contract: Dictionary = {}
var _last_result: Dictionary = {}
var _result_state: StringName = &"none"
var _timely_completed := 0
var _required_completed := 0
var _rush_active := false
var _service_coop_bonus_cents := 0


func _ready() -> void:
	name = "FarmMutualServiceCoopVisual"
	position = FACILITY_CENTER
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
	_build_locked_marker()
	_build_survey_site()
	_build_level_one()
	_build_level_two()
	_build_level_three()
	_apply_visibility()
	_apply_dynamic_state()


func clear() -> void:
	for visual_root in [
		locked_marker_root,
		survey_site_root,
		level_one_root,
		level_two_root,
		level_three_root,
	]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	locked_marker_root = null
	survey_site_root = null
	level_one_root = null
	level_two_root = null
	level_three_root = null
	_standing_segments.clear()
	_totem_segments.clear()
	_dispatch_packets.clear()
	_standing_label = null
	_dispatch_label = null
	_bonus_label = null
	_active_lamp = null
	_rush_lamp = null
	_success_lamp = null
	_breach_shutter = null
	_material_cache.clear()
	_has_applied_snapshot = false
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	var board := _snapshot_contract_board(snapshot)
	var accreditation := _snapshot_dictionary(board.get("accreditation", {}))
	_facility_level = clampi(_snapshot_facility_level(snapshot, board), 0, MAX_LEVEL)
	var standing := _snapshot_standing_record(board)
	_standing_score = maxi(0, int(standing.get(
		"points",
		standing.get("score", standing.get("standing_score", board.get("standing_score", 0))),
	)))
	_standing_rank = _normalized_rank(StringName(String(standing.get(
		"rank",
		standing.get("standing_rank", board.get("standing_rank", "provisional")),
	))))
	_next_standing_score = maxi(_standing_score, int(standing.get(
		"next_threshold",
		standing.get(
			"next_rank_score",
			standing.get("next_standing_score", board.get("next_standing_score", _default_next_standing_score())),
		),
	)))
	_unlocked = (
		_facility_level > 0
		or _snapshot_catalog_unlocked(snapshot)
		or bool(accreditation.get("unlocked", accreditation.get("available", false)))
		or bool(standing.get("facility_available", standing.get("accreditation_available", false)))
	)
	_active_contract = _snapshot_dictionary(board.get(
		"active",
		board.get("active_contract", {}),
	))
	_last_result = _snapshot_dictionary(board.get("last_result", {}))
	_result_state = _classify_result(_last_result)
	_service_coop_bonus_cents = maxi(0, int(_last_result.get(
		"service_coop_bonus_cents",
		_last_result.get("accreditation_bonus_cents", 0),
	)))
	_timely_completed = maxi(0, int(_active_contract.get(
		"timely_sound_completed",
		_active_contract.get("qualified_completed", 0),
	)))
	_required_completed = maxi(0, int(_active_contract.get(
		"required_completed",
		_active_contract.get("required_deliveries", 0),
	)))
	_rush_active = _snapshot_rush_active(_active_contract)
	_apply_visibility()
	_apply_dynamic_state()
	if _has_applied_snapshot and _facility_level > previous_level and is_inside_tree():
		for revealed_level in range(previous_level + 1, _facility_level + 1):
			_animate_level_reveal(revealed_level)
	_has_applied_snapshot = true


func visual_state() -> StringName:
	if _facility_level > 0:
		return StringName("level_%d" % _facility_level)
	return &"survey" if _unlocked else &"locked"


func current_level() -> int:
	return _facility_level


func facility_level() -> int:
	return _facility_level


func tier_root(level: int) -> Node3D:
	match level:
		1:
			return level_one_root
		2:
			return level_two_root
		3:
			return level_three_root
	return null


func tier_visible(level: int) -> bool:
	var root_for_tier := tier_root(level)
	return root_for_tier != null and root_for_tier.visible


func level_visible(level: int) -> bool:
	return tier_visible(level)


func locked_marker_visible() -> bool:
	return locked_marker_root != null and locked_marker_root.visible


func survey_site_visible() -> bool:
	return survey_site_root != null and survey_site_root.visible


func standing_score() -> int:
	return _standing_score


func standing_rank() -> StringName:
	return _standing_rank


func lit_standing_segment_count() -> int:
	return mini(_standing_score, _standing_segments.size())


func lit_totem_segment_count() -> int:
	return mini(_standing_score, _totem_segments.size())


func visible_dispatch_packet_count() -> int:
	var count := 0
	for packet in _dispatch_packets:
		if packet.visible and _facility_level >= 2:
			count += 1
	return count


func displayed_timely_completed() -> int:
	return _timely_completed


func displayed_required_completed() -> int:
	return _required_completed


func active_contract_id() -> String:
	return String(_active_contract.get(
		"contract_id",
		_active_contract.get("offer_id", _active_contract.get("id", "")),
	))


func rush_beacon_active() -> bool:
	return _rush_active and _facility_level >= 2


func result_state() -> StringName:
	return _result_state


func service_coop_bonus_cents() -> int:
	return _service_coop_bonus_cents


func success_indicator_active() -> bool:
	return _result_state == &"success" and _facility_level >= 3


func breach_shutter_visible() -> bool:
	return (
		_breach_shutter != null
		and _breach_shutter.visible
		and _facility_level >= 3
	)


func debug_state() -> Dictionary:
	return {
		"visual_state": visual_state(),
		"facility_level": _facility_level,
		"unlocked": _unlocked,
		"standing_score": _standing_score,
		"standing_rank": _standing_rank,
		"next_standing_score": _next_standing_score,
		"lit_standing_segments": lit_standing_segment_count(),
		"lit_totem_segments": lit_totem_segment_count(),
		"active_contract_id": active_contract_id(),
		"timely_completed": _timely_completed,
		"required_completed": _required_completed,
		"visible_dispatch_packets": visible_dispatch_packet_count(),
		"rush_active": rush_beacon_active(),
		"result_state": _result_state,
		"service_coop_bonus_cents": _service_coop_bonus_cents,
		"success_indicator_active": success_indicator_active(),
		"breach_shutter_visible": breach_shutter_visible(),
		"footprint": FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func geometry_bounds_inside_footprint() -> bool:
	## Includes every hidden tier and pre-construction state. Purchases can reveal
	## no mesh that was not already audited against the declared parcel.
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
					var local_corner := to_local(instance.to_global(Vector3(
						corner_x,
						corner_y,
						corner_z,
					)))
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
	if not found_geometry:
		return AABB()
	return AABB(minimum, maximum - minimum)


func _apply_visibility() -> void:
	if locked_marker_root != null:
		locked_marker_root.visible = not _unlocked and _facility_level <= 0
	if survey_site_root != null:
		survey_site_root.visible = _unlocked and _facility_level <= 0
	if level_one_root != null:
		level_one_root.visible = _facility_level >= 1
	if level_two_root != null:
		level_two_root.visible = _facility_level >= 2
	if level_three_root != null:
		level_three_root.visible = _facility_level >= 3


func _apply_dynamic_state() -> void:
	var lit_segments := mini(_standing_score, STANDING_SEGMENT_COUNT)
	for segment_index in _standing_segments.size():
		var segment := _standing_segments[segment_index]
		var accent := _standing_accent(segment_index)
		segment.material_override = (
			_emissive_material(accent, 0.52)
			if segment_index < lit_segments
			else _material(GRAPHITE.lightened(0.05), 0.72)
		)
	for segment_index in _totem_segments.size():
		var segment := _totem_segments[segment_index]
		var accent := _standing_accent(segment_index)
		segment.material_override = (
			_emissive_material(accent, 0.64)
			if segment_index < lit_segments
			else _material(DEEP_GREEN.darkened(0.12), 0.70)
		)

	if _standing_label != null:
		_standing_label.text = "%s STANDING  %02d / %02d" % [
			String(_standing_rank).to_upper(),
			_standing_score,
			maxi(_standing_score, _next_standing_score),
		]
		EnvironmentalSignageScript.refit_label(_standing_label)

	var visible_packets := mini(_timely_completed, MAX_DISPATCH_PACKETS)
	for packet_index in _dispatch_packets.size():
		_dispatch_packets[packet_index].visible = (
			packet_index < visible_packets
			and _facility_level >= 2
		)
	if _dispatch_label != null:
		_dispatch_label.text = (
			"SEALED  %02d / %02d" % [_timely_completed, _required_completed]
			if not _active_contract.is_empty()
			else "DISPATCH IDLE"
		)
		EnvironmentalSignageScript.refit_label(_dispatch_label)

	if _active_lamp != null:
		_active_lamp.material_override = (
			_emissive_material(SUCCESS_GREEN, 0.58)
			if not _active_contract.is_empty()
			else _material(GRAPHITE.lightened(0.04), 0.64)
		)
	if _rush_lamp != null:
		_rush_lamp.material_override = (
			_emissive_material(AMBER, 0.92)
			if _rush_active
			else _material(OXIDE.darkened(0.18), 0.62)
		)
	if _success_lamp != null:
		_success_lamp.material_override = (
			_emissive_material(BRASS.lightened(0.10), 0.86)
			if _result_state == &"success"
			else _material(DARK_TIMBER, 0.62, 0.18)
		)
	if _breach_shutter != null:
		_breach_shutter.visible = _result_state == &"breach"
	if _bonus_label != null:
		_bonus_label.text = (
			"SERVICE BONUS  $%.2f" % (float(_service_coop_bonus_cents) / 100.0)
			if _result_state == &"success" and _service_coop_bonus_cents > 0
			else "SERVICE BONUS  --"
		)
		EnvironmentalSignageScript.refit_label(_bonus_label)


func _standing_accent(segment_index: int) -> Color:
	if segment_index >= 11:
		return BRASS.lightened(0.10)
	if segment_index >= 5:
		return Color("b7bec2")
	return Color("b6784f")


func _snapshot_facility_level(snapshot: Dictionary, board: Dictionary = {}) -> int:
	var owned_variant: Variant = snapshot.get("owned_facilities", {})
	if owned_variant is Dictionary:
		var owned := owned_variant as Dictionary
		if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
			return _level_from_variant(owned.get(
				FACILITY_ID,
				owned.get(String(FACILITY_ID), 0),
			))
	var entry := _catalog_entry(snapshot)
	if not entry.is_empty():
		var level := int(entry.get("level", entry.get("owned_level", 0)))
		if level > 0:
			return level
		if bool(entry.get("installed", entry.get("owned", false))):
			return 1
	var accreditation := _snapshot_dictionary(board.get("accreditation", {}))
	if not accreditation.is_empty():
		return _level_from_variant(accreditation)
	return 0


func _snapshot_catalog_unlocked(snapshot: Dictionary) -> bool:
	var entry := _catalog_entry(snapshot)
	if entry.is_empty():
		return false
	return bool(entry.get(
		"unlocked",
		entry.get("available", entry.get("can_purchase", false)),
	)) or int(entry.get("level", 0)) > 0


func _catalog_entry(snapshot: Dictionary) -> Dictionary:
	var catalog_variant: Variant = snapshot.get("facility_catalog", [])
	if catalog_variant is Array:
		for entry_variant in catalog_variant as Array:
			if entry_variant is Dictionary:
				var entry := entry_variant as Dictionary
				if StringName(entry.get("id", &"")) == FACILITY_ID:
					return entry
	elif catalog_variant is Dictionary:
		var catalog := catalog_variant as Dictionary
		var entry_variant: Variant = catalog.get(
			FACILITY_ID,
			catalog.get(String(FACILITY_ID), null),
		)
		if entry_variant is Dictionary:
			return entry_variant as Dictionary
	return {}


func _snapshot_contract_board(snapshot: Dictionary) -> Dictionary:
	return _snapshot_dictionary(snapshot.get(
		"contract_board",
		snapshot.get("farm_mutual_contract_board", {}),
	))


func _snapshot_standing_record(board: Dictionary) -> Dictionary:
	# `standing` is the canonical reputation record. `reputation` and the former
	# overloaded `accreditation` record remain read-only compatibility aliases.
	for key in ["standing", "reputation", "accreditation"]:
		var value: Variant = board.get(key, null)
		if value is Dictionary:
			return (value as Dictionary).duplicate(true)
	return {}


func _snapshot_dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _snapshot_rush_active(active: Dictionary) -> bool:
	for key in ["rush_active", "contract_rush_active"]:
		if active.has(key):
			return bool(active[key])
	if int(active.get("pending_rush_claims", 0)) > 0:
		return true
	var completed_ids := active.get("completed_claim_ids", []) as Array
	for schedule_value in active.get("scheduled_claims", []):
		if schedule_value is not Dictionary:
			continue
		var schedule := schedule_value as Dictionary
		var claim_id := int(schedule.get("claim_id", -1))
		if (
			bool(schedule.get("rush", false))
			and bool(schedule.get("released", false))
			and not bool(schedule.get("rejected", false))
			and claim_id not in completed_ids
		):
			return true
	return false


func _level_from_variant(value: Variant) -> int:
	if value is bool:
		return 1 if value else 0
	if value is int or value is float:
		return int(value)
	if value is Dictionary:
		var record := value as Dictionary
		return int(record.get("level", 1 if bool(record.get("owned", false)) else 0))
	return 0


func _normalized_rank(rank: StringName) -> StringName:
	var normalized := StringName(String(rank).strip_edges().to_lower())
	return normalized if normalized in [&"provisional", &"bronze", &"silver", &"gold"] else &"provisional"


func _default_next_standing_score() -> int:
	match _standing_rank:
		&"bronze":
			return 6
		&"silver":
			return 12
		&"gold":
			return _standing_score
	return 2


func _classify_result(result: Dictionary) -> StringName:
	var status := StringName(String(result.get("status", "")).to_lower())
	if status in [&"fulfilled", &"success", &"paid"]:
		return &"success"
	if status in [&"breached", &"breach", &"failed", &"failure"]:
		return &"breach"
	return &"none"


func _animate_level_reveal(level: int) -> void:
	var revealed_root := tier_root(level)
	if revealed_root == null or not is_instance_valid(revealed_root):
		return
	revealed_root.scale = Vector3(1.0, 0.06, 1.0)
	var reveal := create_tween().bind_node(revealed_root)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(revealed_root, "scale", Vector3.ONE, 0.52)


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "FarmMutualServiceLeaseBoundary"
	add_child(locked_marker_root)

	for edge_z in [-2.72, 2.72]:
		_add_box(
			locked_marker_root, "ServiceCoopLeaseBoundaryZ",
			Vector3(6.08, 0.035, 0.055), Vector3(0.0, 0.025, edge_z),
			BRASS.darkened(0.24), 0.72, 0.24,
		)
	for side_x in [-3.02, 3.02]:
		for segment_z in [-1.72, 1.72]:
			_add_box(
				locked_marker_root, "ServiceCoopLeaseBoundaryX",
				Vector3(0.055, 0.035, 1.96), Vector3(side_x, 0.026, segment_z),
				BRASS.darkened(0.24), 0.72, 0.24,
			)
	for corner_x in [-3.02, 3.02]:
		for corner_z in [-2.72, 2.72]:
			_add_cylinder(
				locked_marker_root, "ServiceCoopLeaseSurveyPin",
				Vector3(corner_x, 0.10, corner_z), 0.055, 0.20,
				BARN_RED, 0.60, 0.12,
			)

	var marker := Node3D.new()
	marker.name = "FarmMutualStandingMarker"
	marker.position = Vector3(-0.15, 0.0, -2.52)
	locked_marker_root.add_child(marker)
	for post_x in [-1.58, 1.58]:
		_add_box(marker, "ServiceCoopLeasePost", Vector3(0.11, 1.48, 0.11), Vector3(post_x, 0.74, 0.0), TIMBER, 0.76)
	var face := _add_box(marker, "ServiceCoopLeaseFace", Vector3(3.78, 1.12, 0.12), Vector3(0.0, 1.27, 0.0), DEEP_GREEN, 0.78)
	EnvironmentalSignageScript.add_panel(
		face, "FarmMutualServiceParcel", "MUTUAL SERVICE PARCEL",
		Vector3(0.0, 0.17, 0.072), Vector2(3.30, 0.38),
		DEEP_GREEN, CREAM, Vector3.ZERO,
		17, 0.0033, &"secondary", &"beam",
	)
	EnvironmentalSignageScript.add_panel(
		face, "FarmMutualStandingPending", "STANDING PENDING",
		Vector3(0.0, -0.29, 0.072), Vector2(2.70, 0.18),
		ENAMEL_GREEN, BRASS, Vector3.ZERO,
		10, 0.0022, &"utility", &"stencil",
	)


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "FarmMutualServiceSurveySite"
	add_child(survey_site_root)
	_add_box(survey_site_root, "ServiceCoopSurveyFoundation", Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0), Color("626b68"), 0.94)
	_add_box(survey_site_root, "ServiceCoopSurveyInset", Vector3(6.10, 0.018, 5.50), Vector3(0.0, -0.010, 0.0), Color("4f5b58"), 0.96)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(survey_site_root, "ServiceCoopSurveyRuleX", Vector3(0.025, 0.008, 5.20), Vector3(grid_x, 0.004, 0.0), CREAM.darkened(0.18), 0.98)
	for grid_z in [-1.70, 0.0, 1.70]:
		_add_box(survey_site_root, "ServiceCoopSurveyRuleZ", Vector3(5.70, 0.008, 0.025), Vector3(0.0, 0.005, grid_z), CREAM.darkened(0.18), 0.98)
	for stake_x in [-2.85, 2.85]:
		for stake_z in [-2.52, 2.52]:
			_add_box(survey_site_root, "ServiceCoopSurveyStake", Vector3(0.08, 0.62, 0.08), Vector3(stake_x, 0.31, stake_z), TIMBER, 0.78)
			_add_box(survey_site_root, "ServiceCoopSurveyFlag", Vector3(0.34, 0.17, 0.018), Vector3(stake_x + 0.13, 0.50, stake_z), BARN_RED, 0.88)
	var notice := _add_box(survey_site_root, "ServiceCoopQuoteBoard", Vector3(3.20, 0.82, 0.10), Vector3(-0.15, 0.74, -2.56), DEEP_GREEN, 0.78)
	EnvironmentalSignageScript.add_panel(
		notice, "ServiceCoopSiteNotice", "ACCREDITATION SITE\nFIXTURE QUOTES FILED",
		Vector3(0.0, 0.0, 0.062), Vector2(2.86, 0.56),
		DEEP_GREEN, CREAM, Vector3.ZERO,
		14, 0.0028, &"secondary", &"machine",
	)
	_build_survey_blueprint_table(survey_site_root)
	_build_accreditation_crate(survey_site_root)


func _build_survey_blueprint_table(parent: Node3D) -> void:
	var table := Node3D.new()
	table.name = "ServiceCoopSurveyBlueprintTable"
	table.position = Vector3(-1.72, 0.0, 1.42)
	parent.add_child(table)
	_add_box(table, "ServiceCoopBlueprintTop", Vector3(1.62, 0.10, 0.92), Vector3(0.0, 0.84, 0.0), TIMBER, 0.76)
	for leg_x in [-0.66, 0.66]:
		for leg_z in [-0.34, 0.34]:
			_add_box(table, "ServiceCoopBlueprintLeg", Vector3(0.09, 0.80, 0.09), Vector3(leg_x, 0.40, leg_z), GRAPHITE, 0.56, 0.34)
	var plan := _add_box(table, "ServiceCoopAccreditationPlan", Vector3(1.36, 0.014, 0.70), Vector3(0.0, 0.899, 0.0), BLUEPRINT, 0.96)
	for line_index in 5:
		_add_box(plan, "ServiceCoopBlueprintRule", Vector3(1.04 - line_index * 0.09, 0.004, 0.012), Vector3(0.0, 0.011, -0.26 + line_index * 0.13), CREAM, 0.96)


func _build_accreditation_crate(parent: Node3D) -> void:
	var crate := Node3D.new()
	crate.name = "UnopenedAccreditationFixtureCrate"
	crate.position = Vector3(1.52, 0.0, 1.24)
	parent.add_child(crate)
	_add_box(crate, "AccreditationCrateBody", Vector3(1.56, 0.92, 1.12), Vector3(0.0, 0.48, 0.0), KRAFT, 0.90)
	for slat_y in [0.16, 0.48, 0.80]:
		_add_box(crate, "AccreditationCrateSlat", Vector3(1.62, 0.09, 1.18), Vector3(0.0, slat_y, 0.0), TIMBER, 0.78)
	_add_box(crate, "AccreditationCrateBand", Vector3(0.18, 0.96, 1.16), Vector3.ZERO + Vector3(0.0, 0.48, 0.0), BRASS.darkened(0.18), 0.62, 0.26)


func _build_level_one() -> void:
	level_one_root = Node3D.new()
	level_one_root.name = "BronzeAccreditationDeskLevelOne"
	add_child(level_one_root)
	_build_service_coop_shell(level_one_root)
	_build_accreditation_counter(level_one_root)
	_build_standing_case(level_one_root)
	_build_empty_binder_pigeonholes(level_one_root)


func _build_service_coop_shell(parent: Node3D) -> void:
	_add_box(parent, "ServiceCoopFloorSlab", Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0), Color("4d5957"), 0.94)
	_add_box(parent, "ServiceCoopFloorInset", Vector3(6.08, 0.018, 5.48), Vector3(0.0, -0.010, 0.0), Color("3e4948"), 0.96)
	_add_box(parent, "ServiceCoopBackWall", Vector3(6.20, 3.45, 0.20), Vector3(0.0, 1.725, -2.78), CREAM, 0.88)
	_add_box(parent, "ServiceCoopBackWallDado", Vector3(6.22, 1.10, 0.06), Vector3(0.0, 0.57, -2.665), SAGE, 0.82)
	_add_box(parent, "ServiceCoopBarnTrim", Vector3(6.24, 0.14, 0.12), Vector3(0.0, 3.45, -2.64), BARN_RED, 0.72)
	# The camera-facing +X/+Z sides remain open. The west frame is split around
	# the office doorway, and only narrow beams rise above the service floor.
	for post_z in [-2.58, -1.42, 1.42, 2.58]:
		_add_box(parent, "ServiceCoopWestJamb", Vector3(0.14, 3.30, 0.14), Vector3(-3.08, 1.65, post_z), DEEP_GREEN, 0.66, 0.14)
	for beam_z in [-2.56, 2.56]:
		_add_box(parent, "ServiceCoopOpenTrussBeam", Vector3(6.06, 0.13, 0.13), Vector3(0.0, 3.30, beam_z), DEEP_GREEN, 0.62, 0.18)
	for truss_x in [-2.55, 0.0, 2.55]:
		_add_box(parent, "ServiceCoopOpenTrussTie", Vector3(0.12, 0.12, 5.00), Vector3(truss_x, 3.30, 0.0), DEEP_GREEN, 0.62, 0.18)
	_add_box(parent, "ServiceCoopFrontThreshold", Vector3(5.30, 0.07, 0.12), Vector3(0.0, 0.035, 2.68), BRASS.darkened(0.18), 0.70, 0.28)

	var identity_bed := _add_box(parent, "ServiceCoopIdentityBed", Vector3(3.70, 0.88, 0.10), Vector3(0.36, 2.78, -2.655), ENAMEL_GREEN, 0.76, 0.08)
	EnvironmentalSignageScript.add_panel(
		identity_bed, "FarmMutualServiceCoopIdentity", "FARM MUTUAL SERVICE COOP\nACCREDITATION & DISPATCH",
		Vector3(0.0, 0.0, 0.056), Vector2(3.34, 0.64),
		ENAMEL_GREEN, CREAM, Vector3.ZERO,
		18, 0.0032, &"primary", &"destination",
	)


func _build_accreditation_counter(parent: Node3D) -> void:
	var counter := Node3D.new()
	counter.name = "BronzeAccreditationServiceCounter"
	counter.position = Vector3(-0.38, 0.0, 0.15)
	parent.add_child(counter)
	_add_box(counter, "AccreditationCounterBody", Vector3(2.84, 0.92, 1.18), Vector3(0.0, 0.48, 0.0), TIMBER, 0.78)
	_add_box(counter, "AccreditationCounterInset", Vector3(2.48, 0.58, 0.06), Vector3(0.0, 0.50, 0.62), ENAMEL_GREEN, 0.70, 0.10)
	_add_box(counter, "AccreditationCounterTop", Vector3(3.02, 0.14, 1.32), Vector3(0.0, 1.00, 0.0), CREAM.darkened(0.06), 0.70)
	for slat_x in [-0.90, -0.30, 0.30, 0.90]:
		_add_box(counter, "AccreditationCounterSlat", Vector3(0.09, 0.48, 0.045), Vector3(slat_x, 0.50, 0.655), BRASS.darkened(0.12), 0.54, 0.30)

	var press := Node3D.new()
	press.name = "BronzeAccreditationSealPress"
	press.position = Vector3(-0.78, 1.08, 0.02)
	counter.add_child(press)
	_add_box(press, "SealPressBase", Vector3(0.54, 0.10, 0.48), Vector3.ZERO, GRAPHITE, 0.56, 0.28)
	_add_cylinder(press, "BronzeSealDie", Vector3(0.0, 0.18, 0.0), 0.16, 0.22, BRASS, 0.34, 0.62)
	_add_cylinder(press, "SealPressStem", Vector3(0.0, 0.48, -0.14), 0.055, 0.68, SERVICE_GREY, 0.44, 0.46)
	var lever := _add_box(press, "SealPressLever", Vector3(0.72, 0.07, 0.07), Vector3(0.24, 0.76, -0.14), DARK_TIMBER, 0.64, 0.10)
	lever.rotation_degrees.z = -24.0
	_add_sphere(press, "SealPressHandle", Vector3(0.57, 0.91, -0.14), Vector3(0.18, 0.18, 0.18), BARN_RED, 0.48)

	_add_cylinder(counter, "AccreditationServiceBellBase", Vector3(0.72, 1.12, 0.10), 0.18, 0.06, DARK_TIMBER, 0.34, 0.50)
	_add_sphere(counter, "AccreditationServiceBell", Vector3(0.72, 1.22, 0.10), Vector3(0.30, 0.20, 0.30), BRASS, 0.28)
	_active_lamp = _add_cylinder(counter, "ActiveBinderLamp", Vector3(1.12, 1.12, -0.32), 0.09, 0.05, GRAPHITE, 0.38, 0.24)


func _build_standing_case(parent: Node3D) -> void:
	var standing_case := Node3D.new()
	standing_case.name = "AuthoritativeStandingCertificateCase"
	standing_case.position = Vector3(-1.48, 0.0, -2.655)
	parent.add_child(standing_case)
	_add_box(standing_case, "StandingCaseFrame", Vector3(2.24, 1.32, 0.12), Vector3(0.0, 1.88, 0.0), DARK_TIMBER, 0.68, 0.08)
	var glass := _add_box(standing_case, "StandingCaseGlass", Vector3(2.02, 1.10, 0.045), Vector3(0.0, 1.88, 0.085), GLASS, 0.22)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label_host := _add_box(standing_case, "StandingReadoutHost", Vector3(1.84, 0.34, 0.055), Vector3(0.0, 2.12, 0.125), ENAMEL_GREEN, 0.68, 0.12)
	_standing_label = EnvironmentalSignageScript.add_panel(
		label_host, "ServiceCoopStandingReadout", "PROVISIONAL STANDING  00 / 02",
		Vector3(0.0, 0.0, 0.039), Vector2(1.62, 0.20),
		ENAMEL_GREEN, CREAM, Vector3.ZERO,
		9, 0.0018, &"utility", &"screen", true,
	)
	for segment_index in STANDING_SEGMENT_COUNT:
		var row := int(segment_index / 6)
		var column := segment_index % 6
		var segment := _add_box(
			standing_case, "StandingSegment_%02d" % segment_index,
			Vector3(0.22, 0.16, 0.035),
			Vector3(-0.72 + column * 0.29, 1.70 - row * 0.25, 0.135),
			GRAPHITE.lightened(0.05), 0.72,
		)
		_standing_segments.append(segment)
	_add_box(standing_case, "StandingCertificatePaper", Vector3(1.78, 0.24, 0.025), Vector3(0.0, 1.28, 0.125), PAPER, 0.92)


func _build_empty_binder_pigeonholes(parent: Node3D) -> void:
	var rack := Node3D.new()
	rack.name = "EmptyFarmMutualBinderPigeonholes"
	rack.position = Vector3(1.78, 0.0, -1.78)
	parent.add_child(rack)
	_add_box(rack, "BinderPigeonholeBack", Vector3(2.18, 1.56, 0.10), Vector3(0.0, 1.02, -0.32), DEEP_GREEN, 0.66, 0.16)
	for post_x in [-1.02, -0.34, 0.34, 1.02]:
		_add_box(rack, "BinderPigeonholeDivider", Vector3(0.07, 1.42, 0.72), Vector3(post_x, 1.02, 0.0), SERVICE_GREY, 0.60, 0.26)
	for shelf_y in [0.32, 0.98, 1.72]:
		_add_box(rack, "BinderPigeonholeShelf", Vector3(2.10, 0.07, 0.72), Vector3(0.0, shelf_y, 0.0), SERVICE_GREY, 0.60, 0.26)
	# The cubbies remain physically empty until the Level 2 authoritative packet
	# rack displays real clean-and-timely contract completions.


func _build_level_two() -> void:
	level_two_root = Node3D.new()
	level_two_root.name = "SilverDispatchLineLevelTwo"
	add_child(level_two_root)
	_build_dispatch_tube_bank(level_two_root)
	_build_authoritative_packet_rack(level_two_root)
	_build_courier_cage(level_two_root)
	_build_rush_beacon(level_two_root)


func _build_dispatch_tube_bank(parent: Node3D) -> void:
	var bank := Node3D.new()
	bank.name = "FarmMutualLaneDispatchTubes"
	bank.position = Vector3(1.42, 0.0, -0.65)
	parent.add_child(bank)
	_add_box(bank, "DispatchTubeConsoleBase", Vector3(1.78, 0.16, 1.08), Vector3(0.0, 0.10, 0.0), GRAPHITE, 0.62, 0.24)
	_add_box(bank, "DispatchTubeConsole", Vector3(1.64, 0.82, 0.96), Vector3(0.0, 0.58, 0.0), ENAMEL_GREEN, 0.64, 0.16)
	var console_face := _add_box(bank, "DispatchTubeConsoleFace", Vector3(1.40, 0.48, 0.08), Vector3(0.0, 0.62, 0.52), GRAPHITE, 0.54, 0.22)
	_dispatch_label = EnvironmentalSignageScript.add_panel(
		console_face, "ServiceCoopDispatchReadout", "DISPATCH IDLE",
		Vector3(0.0, 0.0, 0.051), Vector2(1.16, 0.18),
		GRAPHITE, CREAM, Vector3.ZERO,
		9, 0.0019, &"utility", &"screen", true,
	)
	for lane_index in LANE_ORDER.size():
		var lane := LANE_ORDER[lane_index]
		var lane_x := -0.42 + lane_index * 0.42
		var lane_color: Color = LANE_COLORS[lane]
		_add_cylinder(bank, "DispatchTube_%s" % lane, Vector3(lane_x, 1.88, -0.08), 0.16, 2.10, SERVICE_GREY.lightened(0.08), 0.38, 0.48)
		_add_cylinder(bank, "DispatchTubeCollar_%s" % lane, Vector3(lane_x, 0.94, -0.08), 0.22, 0.11, BRASS, 0.34, 0.54)
		_add_cylinder(bank, "DispatchLaneBand_%s" % lane, Vector3(lane_x, 1.24, -0.08), 0.18, 0.14, lane_color, 0.42, 0.10)
		var header_x := -1.04
		var run_length := lane_x - header_x
		var header := _add_cylinder(bank, "DispatchHeader_%s" % lane, Vector3((lane_x + header_x) * 0.5, 2.95 + lane_index * 0.11, -0.08), 0.075, run_length, SERVICE_GREY.lightened(0.08), 0.36, 0.50)
		header.rotation_degrees.z = 90.0
	_add_box(bank, "DispatchHeaderMast", Vector3(0.15, 3.18, 0.15), Vector3(-1.04, 1.59, -0.08), DEEP_GREEN, 0.56, 0.22)
	_add_box(bank, "DispatchHeaderBeam", Vector3(2.20, 0.14, 0.14), Vector3(0.0, 3.20, -0.08), DEEP_GREEN, 0.54, 0.24)


func _build_authoritative_packet_rack(parent: Node3D) -> void:
	var rack := Node3D.new()
	rack.name = "AuthoritativeStampedPacketRack"
	rack.position = Vector3(-1.42, 0.0, 1.52)
	parent.add_child(rack)
	_add_box(rack, "StampedPacketRackBack", Vector3(2.18, 1.52, 0.10), Vector3(0.0, 0.94, -0.34), DEEP_GREEN, 0.62, 0.18)
	for post_x in [-1.02, -0.34, 0.34, 1.02]:
		_add_box(rack, "StampedPacketRackDivider", Vector3(0.07, 1.42, 0.76), Vector3(post_x, 0.94, 0.0), SERVICE_GREY, 0.58, 0.28)
	for shelf_y in [0.25, 0.88, 1.65]:
		_add_box(rack, "StampedPacketRackShelf", Vector3(2.10, 0.07, 0.76), Vector3(0.0, shelf_y, 0.0), SERVICE_GREY, 0.58, 0.28)
	for packet_index in MAX_DISPATCH_PACKETS:
		var row := int(packet_index / 3)
		var column := packet_index % 3
		var packet := Node3D.new()
		packet.name = "AuthoritativeDispatchPacket_%02d" % packet_index
		packet.position = Vector3(-0.68 + column * 0.68, 0.56 + row * 0.63, 0.02)
		rack.add_child(packet)
		_add_box(packet, "DispatchPacketBody", Vector3(0.48, 0.38, 0.50), Vector3.ZERO, PAPER, 0.92)
		_add_box(packet, "DispatchPacketBand", Vector3(0.11, 0.40, 0.52), Vector3.ZERO, BRASS.darkened(0.04 * packet_index), 0.58, 0.24)
		_add_cylinder(packet, "DispatchPacketSeal", Vector3(0.0, 0.0, 0.275), 0.09, 0.035, BRASS, 0.34, 0.58).rotation_degrees.x = 90.0
		packet.visible = false
		_dispatch_packets.append(packet)


func _build_courier_cage(parent: Node3D) -> void:
	var cart := Node3D.new()
	cart.name = "FarmMutualCourierCage"
	cart.position = Vector3(1.54, 0.0, 1.58)
	parent.add_child(cart)
	_add_box(cart, "CourierCageLowerDeck", Vector3(1.42, 0.11, 0.88), Vector3(0.0, 0.34, 0.0), SERVICE_GREY, 0.52, 0.36)
	_add_box(cart, "CourierCageUpperRail", Vector3(1.42, 0.08, 0.88), Vector3(0.0, 1.25, 0.0), BRASS, 0.44, 0.46)
	for post_x in [-0.64, 0.64]:
		for post_z in [-0.36, 0.36]:
			_add_box(cart, "CourierCagePost", Vector3(0.07, 1.04, 0.07), Vector3(post_x, 0.78, post_z), SERVICE_GREY, 0.48, 0.40)
	_add_box(cart, "CourierCageHandle", Vector3(0.08, 0.08, 1.08), Vector3(-0.80, 1.24, 0.0), GRAPHITE, 0.50, 0.34)
	for wheel_x in [-0.54, 0.54]:
		for wheel_z in [-0.28, 0.28]:
			var wheel := _add_cylinder(cart, "CourierCageWheel", Vector3(wheel_x, 0.15, wheel_z), 0.13, 0.08, GRAPHITE, 0.66, 0.12)
			wheel.rotation_degrees.z = 90.0


func _build_rush_beacon(parent: Node3D) -> void:
	var beacon := Node3D.new()
	beacon.name = "FarmMutualContractRushBeacon"
	beacon.position = Vector3(2.62, 0.0, -2.34)
	parent.add_child(beacon)
	_add_box(beacon, "ContractRushBeaconFoot", Vector3(0.44, 0.16, 0.44), Vector3(0.0, 0.08, 0.0), GRAPHITE, 0.60, 0.28)
	_add_cylinder(beacon, "ContractRushBeaconStem", Vector3(0.0, 1.66, 0.0), 0.045, 3.00, SERVICE_GREY, 0.44, 0.44)
	_add_cylinder(beacon, "ContractRushBeaconHousing", Vector3(0.0, 3.22, 0.0), 0.22, 0.30, OXIDE, 0.52, 0.18)
	_rush_lamp = _add_sphere(beacon, "ContractRushBeaconLamp", Vector3(0.0, 3.22, 0.0), Vector3(0.31, 0.25, 0.31), AMBER, 0.30)


func _build_level_three() -> void:
	level_three_root = Node3D.new()
	level_three_root.name = "GoldSealServiceHallLevelThree"
	add_child(level_three_root)
	_build_gold_seal_arch(level_three_root)
	_build_contract_vault(level_three_root)
	_build_reputation_totem(level_three_root)
	_build_result_hardware(level_three_root)


func _build_gold_seal_arch(parent: Node3D) -> void:
	var arch := Node3D.new()
	arch.name = "FarmMutualGoldSealArch"
	arch.position = Vector3(-2.36, 0.0, -1.82)
	parent.add_child(arch)
	for post_x in [-0.48, 0.48]:
		_add_box(arch, "GoldSealArchPost", Vector3(0.14, 3.28, 0.14), Vector3(post_x, 1.64, 0.0), DEEP_GREEN, 0.54, 0.24)
		_add_box(arch, "GoldSealArchFoot", Vector3(0.38, 0.12, 0.42), Vector3(post_x, 0.06, 0.0), GRAPHITE, 0.60, 0.24)
	var left_truss := _add_box(arch, "GoldSealArchLeftTruss", Vector3(0.96, 0.12, 0.14), Vector3(-0.25, 3.48, 0.0), BRASS.darkened(0.08), 0.46, 0.48)
	left_truss.rotation_degrees.z = 36.0
	var right_truss := _add_box(arch, "GoldSealArchRightTruss", Vector3(0.96, 0.12, 0.14), Vector3(0.25, 3.48, 0.0), BRASS.darkened(0.08), 0.46, 0.48)
	right_truss.rotation_degrees.z = -36.0
	_add_cylinder(arch, "GoldSealCrestCollar", Vector3(0.0, 3.77, 0.0), 0.31, 0.12, BRASS, 0.34, 0.58)
	_add_sphere(arch, "FarmMutualGoldSealCrest", Vector3(0.0, 3.92, 0.0), Vector3(0.44, 0.58, 0.18), BRASS.lightened(0.08), 0.26)


func _build_contract_vault(parent: Node3D) -> void:
	var vault := Node3D.new()
	vault.name = "AccreditationContractVault"
	vault.position = Vector3(1.92, 0.0, 1.08)
	parent.add_child(vault)
	_add_box(vault, "AccreditationVaultBody", Vector3(1.44, 2.24, 1.08), Vector3(0.0, 1.12, 0.0), DEEP_GREEN, 0.54, 0.26)
	var door := _add_box(vault, "AccreditationVaultDoor", Vector3(1.18, 1.96, 0.10), Vector3(0.0, 1.12, 0.59), SERVICE_GREY, 0.46, 0.42)
	for rib_y in [0.38, 0.84, 1.30, 1.76]:
		_add_box(vault, "AccreditationVaultDoorRib", Vector3(1.00, 0.055, 0.035), Vector3(0.0, rib_y, 0.66), GRAPHITE, 0.56, 0.30)
	_add_cylinder(vault, "AccreditationVaultWheel", Vector3(0.0, 1.12, 0.67), 0.24, 0.07, BRASS, 0.34, 0.56).rotation_degrees.x = 90.0
	EnvironmentalSignageScript.add_panel(
		door, "AccreditationVaultPlate", "GOLD SEAL FILES",
		Vector3(0.0, 0.68, 0.062), Vector2(0.92, 0.18),
		SERVICE_GREY, CREAM, Vector3.ZERO,
		9, 0.0019, &"utility", &"machine",
	)
	# A visibly empty tray avoids inventing premium income. Settlement hardware
	# changes state only when last_result supplies an authoritative outcome.
	_add_box(vault, "AccreditationPremiumTray", Vector3(0.86, 0.10, 0.52), Vector3(0.0, 0.32, 0.80), DARK_TIMBER, 0.66, 0.12)
	var bonus_host := _add_box(vault, "AccreditationBonusReadoutHost", Vector3(1.02, 0.30, 0.06), Vector3(0.0, 0.64, 0.73), GRAPHITE, 0.56, 0.24)
	_bonus_label = EnvironmentalSignageScript.add_panel(
		bonus_host, "AccreditationBonusReadout", "SERVICE BONUS  --",
		Vector3(0.0, 0.0, 0.041), Vector2(0.86, 0.16),
		GRAPHITE, BRASS.lightened(0.10), Vector3.ZERO,
		8, 0.0017, &"utility", &"screen", true,
	)


func _build_reputation_totem(parent: Node3D) -> void:
	var totem := Node3D.new()
	totem.name = "FarmMutualReputationTotem"
	totem.position = Vector3(-2.56, 0.0, 1.60)
	parent.add_child(totem)
	_add_box(totem, "ReputationTotemFoot", Vector3(0.62, 0.16, 0.62), Vector3(0.0, 0.08, 0.0), GRAPHITE, 0.60, 0.26)
	_add_box(totem, "ReputationTotemSpine", Vector3(0.32, 2.80, 0.32), Vector3(0.0, 1.48, 0.0), ENAMEL_GREEN, 0.58, 0.20)
	for segment_index in STANDING_SEGMENT_COUNT:
		var segment := _add_box(
			totem, "ReputationTotemSegment_%02d" % segment_index,
			Vector3(0.34, 0.14, 0.055),
			Vector3(0.0, 0.34 + segment_index * 0.20, 0.19),
			DEEP_GREEN.darkened(0.12), 0.70,
		)
		_totem_segments.append(segment)
	_add_cylinder(totem, "ReputationTotemCrown", Vector3(0.0, 3.00, 0.0), 0.24, 0.18, BRASS, 0.34, 0.56)


func _build_result_hardware(parent: Node3D) -> void:
	var hardware := Node3D.new()
	hardware.name = "FarmMutualSettlementHardware"
	hardware.position = Vector3(0.52, 0.0, -2.655)
	parent.add_child(hardware)
	var backdrop := _add_box(hardware, "AccreditationAttributionBackdrop", Vector3(2.34, 1.42, 0.11), Vector3(0.0, 1.64, 0.0), ENAMEL_GREEN, 0.62, 0.16)
	EnvironmentalSignageScript.add_panel(
		backdrop, "ServiceCoopAttribution", "FLOCK CERTIFIED\nFARMER ENDORSED",
		Vector3(0.0, 0.30, 0.064), Vector2(1.98, 0.52),
		ENAMEL_GREEN, CREAM, Vector3.ZERO,
		14, 0.0027, &"secondary", &"board_header",
	)
	_success_lamp = _add_cylinder(hardware, "GoldSealFulfilledIndicator", Vector3(0.0, 1.30, 0.105), 0.24, 0.07, DARK_TIMBER, 0.48, 0.36)
	_success_lamp.rotation_degrees.x = 90.0
	_breach_shutter = Node3D.new()
	_breach_shutter.name = "ContractBreachResultShutter"
	_breach_shutter.position = Vector3(0.0, 1.29, 0.14)
	hardware.add_child(_breach_shutter)
	_add_box(_breach_shutter, "BreachShutterFace", Vector3(1.72, 0.56, 0.08), Vector3.ZERO, BARN_RED, 0.68, 0.10)
	for slash_x in [-0.52, 0.0, 0.52]:
		var slash := _add_box(_breach_shutter, "BreachShutterSlash", Vector3(0.62, 0.075, 0.035), Vector3(slash_x, 0.0, 0.06), CREAM.darkened(0.15), 0.72)
		slash.rotation_degrees.z = -28.0
	_breach_shutter.visible = false


func _add_box(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	part_position: Vector3,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0
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
	metallic: float = 0.0
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.94
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
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
	roughness: float = 0.82
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color, roughness)
	parent.add_child(instance)
	return instance


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
