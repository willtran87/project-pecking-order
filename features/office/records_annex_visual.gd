class_name RecordsAnnexVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only intake-capacity expansion. The annex deliberately
## makes accepted work visible: every occupied folder corresponds to an
## outstanding claim, while the overflow bin records business the bureau could
## not accept. No prop in this module creates claims or modifies the economy.
const FACILITY_ID := &"records_annex"
const FACILITY_CENTER := Vector3(15.20, 0.0, 0.0)
const FOCUS_POINT := Vector3(15.20, 0.90, 0.0)
const FOOTPRINT := Rect2(Vector2(12.00, -2.90), Vector2(6.40, 5.80))
const MAX_LEVEL := 3
const MAX_OPAQUE_HEIGHT := 3.55
const BASE_CLAIM_CAPACITY := 18
const CAPACITY_PER_LEVEL := 6
const MAX_FILE_SLOTS := 36
const OVERFLOW_BUNDLE_SLOT_COUNT := 6

const LANE_ORDER: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const LANE_COLORS := {
	&"nest_damage": Color("65b7a5"),
	&"predator_loss": Color("d69a55"),
	&"appeals": Color("a987bf"),
}

const CREAM := Color("ded5bd")
const WARM_WHITE := Color("eee7d4")
const SAGE := Color("617667")
const DEEP_SAGE := Color("344d45")
const BARN_RED := Color("934e43")
const DARK_RED := Color("663b35")
const TIMBER := Color("795d42")
const KRAFT := Color("b38b58")
const GRAPHITE := Color("293335")
const SERVICE_GREY := Color("687477")
const BRASS := Color("b49551")
const AMBER := Color("d8a744")
const GREEN := Color("71987a")
const BLUEPRINT := Color("537c89")
const OXIDE := Color("8a4c42")
const PAPER := Color("d7c9aa")

var locked_marker_root: Node3D
var survey_site_root: Node3D
var level_one_root: Node3D
var level_two_root: Node3D
var level_three_root: Node3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _folder_slots: Array[Node3D] = []
var _folder_bodies: Array[MeshInstance3D] = []
var _folder_tabs: Array[MeshInstance3D] = []
var _folder_tiers: Array[int] = []
var _overflow_bundles: Array[Node3D] = []
var _gauge_segments: Array[MeshInstance3D] = []
var _lane_lamps: Dictionary[StringName, MeshInstance3D] = {}
var _overdue_lamps: Array[MeshInstance3D] = []
var _capacity_label: Label3D
var _gauge_needle: Node3D

var _built := false
var _unlocked := false
var _facility_level := 0
var _claims_outstanding := 0
var _claim_capacity := BASE_CLAIM_CAPACITY
var _queue_counts: Dictionary = {}
var _overdue_count := 0
var _intake_rejections_today := 0
var _has_applied_snapshot := false


func _ready() -> void:
	name = "RecordsAnnexVisual"
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
	_folder_slots.clear()
	_folder_bodies.clear()
	_folder_tabs.clear()
	_folder_tiers.clear()
	_overflow_bundles.clear()
	_gauge_segments.clear()
	_lane_lamps.clear()
	_overdue_lamps.clear()
	_capacity_label = null
	_gauge_needle = null
	_material_cache.clear()
	_has_applied_snapshot = false
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	_facility_level = clampi(_snapshot_facility_level(snapshot), 0, MAX_LEVEL)
	_unlocked = _facility_level > 0 or _snapshot_catalog_unlocked(snapshot)
	_claim_capacity = maxi(0, _snapshot_claim_capacity(snapshot))
	_claims_outstanding = maxi(0, int(snapshot.get(
		"claims_outstanding",
		snapshot.get("claims_waiting", 0),
	)))
	var queue_variant: Variant = snapshot.get("claim_queue_counts", {})
	_queue_counts = (queue_variant as Dictionary).duplicate() if queue_variant is Dictionary else {}
	_overdue_count = maxi(0, int(snapshot.get(
		"overdue_claims",
		snapshot.get("queued_overdue_claims", 0),
	)))
	_intake_rejections_today = maxi(0, int(snapshot.get("intake_rejections_today", 0)))
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


func tier_visible(level: int) -> bool:
	match level:
		1:
			return level_one_root != null and level_one_root.visible
		2:
			return level_two_root != null and level_two_root.visible
		3:
			return level_three_root != null and level_three_root.visible
	return false


func level_visible(level: int) -> bool:
	return tier_visible(level)


func locked_marker_visible() -> bool:
	return locked_marker_root != null and locked_marker_root.visible


func survey_site_visible() -> bool:
	return survey_site_root != null and survey_site_root.visible


func visible_folder_count() -> int:
	var count := 0
	for slot_index in _folder_slots.size():
		if (
			_folder_slots[slot_index].visible
			and _folder_tiers[slot_index] <= _facility_level
		):
			count += 1
	return count


func visible_file_slots() -> int:
	return visible_folder_count()


func displayed_claim_capacity() -> int:
	return _claim_capacity


func capacity_display_text() -> String:
	if _capacity_label != null:
		return _capacity_label.text
	return _formatted_capacity_text()


func capacity_label_text() -> String:
	return capacity_display_text()


func overdue_active() -> bool:
	return _overdue_count > 0


func overdue_indicator_active() -> bool:
	return overdue_active()


func overflow_bundle_count() -> int:
	var count := 0
	for bundle in _overflow_bundles:
		if bundle.visible and _facility_level > 0:
			count += 1
	return count


func visible_overflow_bundles() -> int:
	return overflow_bundle_count()


func geometry_bounds_inside_footprint() -> bool:
	## Includes hidden tiers, survey props, and sign substrates. This verifies the
	## complete authored build, rather than only whichever tier is currently live.
	var local_half := FOOTPRINT.size * 0.5
	var tolerance := 0.012
	for child in find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		if instance.mesh == null:
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
	var visible_files := mini(
		_claims_outstanding,
		mini(_claim_capacity, MAX_FILE_SLOTS),
	)
	var lane_sequence := _folder_lane_sequence(visible_files)
	for slot_index in _folder_slots.size():
		var slot_visible := (
			slot_index < visible_files
			and _folder_tiers[slot_index] <= _facility_level
		)
		_folder_slots[slot_index].visible = slot_visible
		if not slot_visible:
			continue
		var lane := lane_sequence[slot_index] if slot_index < lane_sequence.size() else &""
		var folder_color: Color = LANE_COLORS.get(lane, PAPER)
		_folder_bodies[slot_index].material_override = _material(folder_color.darkened(0.05), 0.90)
		_folder_tabs[slot_index].material_override = _material(folder_color.lightened(0.10), 0.88)

	var bundle_target := mini(_intake_rejections_today, OVERFLOW_BUNDLE_SLOT_COUNT)
	for bundle_index in _overflow_bundles.size():
		_overflow_bundles[bundle_index].visible = (
			bundle_index < bundle_target
			and _facility_level > 0
		)

	var utilization := 0.0
	if _claim_capacity > 0:
		utilization = clampf(float(_claims_outstanding) / float(_claim_capacity), 0.0, 1.0)
	var lit_segments := ceili(utilization * float(_gauge_segments.size()))
	for segment_index in _gauge_segments.size():
		var segment := _gauge_segments[segment_index]
		var segment_color := GREEN
		if segment_index >= 8:
			segment_color = BARN_RED
		elif segment_index >= 5:
			segment_color = AMBER
		segment.material_override = (
			_emissive_material(segment_color, 0.52)
			if segment_index < lit_segments
			else _material(GRAPHITE.lightened(0.04), 0.72)
		)
	if _gauge_needle != null:
		_gauge_needle.rotation_degrees.z = lerpf(-58.0, 58.0, utilization)
	if _capacity_label != null:
		_capacity_label.text = _formatted_capacity_text()
		EnvironmentalSignageScript.refit_label(_capacity_label)

	for lane in LANE_ORDER:
		var lamp := _lane_lamps.get(lane) as MeshInstance3D
		if lamp == null:
			continue
		var lane_color: Color = LANE_COLORS[lane]
		lamp.material_override = (
			_emissive_material(lane_color, 0.50)
			if _queue_count(lane) > 0
			else _material(GRAPHITE.lightened(0.05), 0.68)
		)
	for lamp in _overdue_lamps:
		lamp.material_override = (
			_emissive_material(Color("ef6e55"), 0.82)
			if overdue_active()
			else _material(DARK_RED.darkened(0.28), 0.62)
		)


func _formatted_capacity_text() -> String:
	return "FILES  %03d / %03d" % [_claims_outstanding, _claim_capacity]


func _folder_lane_sequence(target_count: int) -> Array[StringName]:
	var sequence: Array[StringName] = []
	for lane in LANE_ORDER:
		for _file_index in mini(_queue_count(lane), target_count - sequence.size()):
			sequence.append(lane)
		if sequence.size() >= target_count:
			break
	while sequence.size() < target_count:
		sequence.append(&"")
	return sequence


func _queue_count(lane: StringName) -> int:
	return maxi(0, int(_queue_counts.get(lane, _queue_counts.get(String(lane), 0))))


func _snapshot_facility_level(snapshot: Dictionary) -> int:
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
	return 0


func _snapshot_catalog_unlocked(snapshot: Dictionary) -> bool:
	var entry := _catalog_entry(snapshot)
	if entry.is_empty():
		return false
	return bool(entry.get(
		"unlocked",
		entry.get("available", entry.get("can_purchase", false)),
	)) or int(entry.get("level", 0)) > 0


func _snapshot_claim_capacity(snapshot: Dictionary) -> int:
	for key in [
		"claim_capacity",
		"claims_capacity",
		"claim_queue_capacity",
		"claim_intake_capacity",
		"records_capacity",
	]:
		if snapshot.has(key):
			return maxi(0, int(snapshot[key]))
	var effects_variant: Variant = snapshot.get("facility_effects", {})
	if effects_variant is Dictionary:
		var effects := effects_variant as Dictionary
		for key in ["claim_capacity", "claim_intake_capacity", "records_capacity"]:
			if effects.has(key):
				return maxi(0, int(effects[key]))
	return BASE_CLAIM_CAPACITY + _facility_level * CAPACITY_PER_LEVEL


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


func _level_from_variant(value: Variant) -> int:
	if value is bool:
		return 1 if value else 0
	if value is int or value is float:
		return int(value)
	if value is Dictionary:
		var record := value as Dictionary
		return int(record.get("level", 1 if bool(record.get("owned", false)) else 0))
	return 0


func _animate_level_reveal(level: int) -> void:
	var revealed_root: Node3D = null
	match level:
		1:
			revealed_root = level_one_root
		2:
			revealed_root = level_two_root
		3:
			revealed_root = level_three_root
	if revealed_root == null or not is_instance_valid(revealed_root):
		return
	# Construction rises in place. Scaling X/Z made the eased reveal briefly
	# overshoot the audited parcel even though every authored mesh fit inside it.
	revealed_root.scale = Vector3(1.0, 0.06, 1.0)
	var reveal := create_tween().bind_node(revealed_root)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(revealed_root, "scale", Vector3.ONE, 0.52)


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "RecordsAnnexLeaseBoundary"
	add_child(locked_marker_root)

	for edge_z in [-2.72, 2.72]:
		_add_box(
			locked_marker_root, "RecordsLeaseBoundaryZ",
			Vector3(6.08, 0.035, 0.055), Vector3(0.0, 0.025, edge_z),
			BRASS.darkened(0.24), 0.72, 0.24,
		)
	# The west edge is split around z=0 so the office-to-annex service strip is
	# already legible before construction and never becomes a no-clipping trap.
	for side_x in [-3.02, 3.02]:
		for segment_z in [-1.72, 1.72]:
			_add_box(
				locked_marker_root, "RecordsLeaseBoundaryX",
				Vector3(0.055, 0.035, 1.96), Vector3(side_x, 0.026, segment_z),
				BRASS.darkened(0.24), 0.72, 0.24,
			)
	for corner_x in [-3.02, 3.02]:
		for corner_z in [-2.72, 2.72]:
			_add_cylinder(
				locked_marker_root, "RecordsLeaseSurveyPin",
				Vector3(corner_x, 0.10, corner_z), 0.055, 0.20,
				BARN_RED, 0.60, 0.12,
			)

	var board := Node3D.new()
	board.name = "RecordsLeaseMarker"
	board.position = Vector3(0.25, 0.0, -2.54)
	locked_marker_root.add_child(board)
	for post_x in [-1.60, 1.60]:
		_add_box(board, "RecordsLeaseBoardPost", Vector3(0.11, 1.54, 0.11), Vector3(post_x, 0.77, 0.0), TIMBER, 0.76)
	var face := _add_box(
		board, "RecordsLeaseBoardFace", Vector3(3.82, 1.14, 0.12),
		Vector3(0.0, 1.30, 0.0), DEEP_SAGE, 0.78,
	)
	EnvironmentalSignageScript.add_panel(
		face, "RecordsAnnexLeaseOption", "RECORDS PARCEL",
		Vector3(0.0, 0.20, 0.072), Vector2(3.34, 0.40),
		DEEP_SAGE, CREAM, Vector3.ZERO,
		17, 0.0033, &"secondary", &"beam",
	)
	EnvironmentalSignageScript.add_panel(
		face, "RecordsAnnexLeaseCondition", "CAPACITY SUBJECT TO FILING",
		Vector3(0.0, -0.29, 0.072), Vector2(2.92, 0.20),
		SAGE.darkened(0.08), Color("e6d6ad"), Vector3.ZERO,
		10, 0.0023, &"utility", &"stencil",
	)


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "RecordsAnnexSurveySite"
	add_child(survey_site_root)
	_add_box(
		survey_site_root, "RecordsSurveyFoundation",
		Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0),
		Color("626b68"), 0.94,
	)
	_add_box(
		survey_site_root, "RecordsSurveyInset",
		Vector3(6.10, 0.018, 5.50), Vector3(0.0, -0.010, 0.0),
		Color("4f5b58"), 0.96,
	)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(survey_site_root, "RecordsSurveyRuleX", Vector3(0.025, 0.008, 5.20), Vector3(grid_x, 0.004, 0.0), WARM_WHITE.darkened(0.18), 0.98)
	for grid_z in [-1.70, 0.0, 1.70]:
		_add_box(survey_site_root, "RecordsSurveyRuleZ", Vector3(5.70, 0.008, 0.025), Vector3(0.0, 0.005, grid_z), WARM_WHITE.darkened(0.18), 0.98)
	for stake_x in [-2.85, 2.85]:
		for stake_z in [-2.52, 2.52]:
			_add_box(survey_site_root, "RecordsSurveyStake", Vector3(0.08, 0.62, 0.08), Vector3(stake_x, 0.31, stake_z), TIMBER, 0.78)
			_add_box(survey_site_root, "RecordsSurveyFlag", Vector3(0.34, 0.17, 0.018), Vector3(stake_x + 0.13, 0.50, stake_z), BARN_RED, 0.88)
	var quote_board := _add_box(
		survey_site_root, "RecordsQuoteBoard",
		Vector3(3.25, 0.84, 0.10), Vector3(0.38, 0.76, -2.59),
		DEEP_SAGE, 0.78,
	)
	EnvironmentalSignageScript.add_panel(
		quote_board, "RecordsAnnexSiteNotice", "RECORDS ANNEX SITE\nSHELVING QUOTES PENDING",
		Vector3(0.0, 0.0, 0.062), Vector2(2.92, 0.58),
		DEEP_SAGE, CREAM, Vector3.ZERO,
		14, 0.0028, &"secondary", &"machine",
	)
	_build_survey_blueprint_table(survey_site_root)


func _build_survey_blueprint_table(parent: Node3D) -> void:
	var table := Node3D.new()
	table.name = "RecordsSurveyBlueprintTable"
	table.position = Vector3(1.78, 0.0, 1.42)
	parent.add_child(table)
	_add_box(table, "RecordsBlueprintTop", Vector3(1.68, 0.10, 0.92), Vector3(0.0, 0.84, 0.0), TIMBER, 0.76)
	for leg_x in [-0.69, 0.69]:
		for leg_z in [-0.34, 0.34]:
			_add_box(table, "RecordsBlueprintLeg", Vector3(0.09, 0.80, 0.09), Vector3(leg_x, 0.40, leg_z), GRAPHITE, 0.56, 0.34)
	var plan := _add_box(table, "RecordsAnnexPlan", Vector3(1.42, 0.014, 0.70), Vector3(0.0, 0.899, 0.0), BLUEPRINT, 0.96)
	for line_index in 5:
		_add_box(plan, "RecordsBlueprintRule", Vector3(1.10 - line_index * 0.10, 0.004, 0.012), Vector3(0.0, 0.011, -0.26 + line_index * 0.13), WARM_WHITE, 0.96)


func _build_level_one() -> void:
	level_one_root = Node3D.new()
	level_one_root.name = "RollingRecordsFloorLevelOne"
	add_child(level_one_root)
	_build_annex_shell(level_one_root)
	_build_rolling_shelf_bank(level_one_root, "WestRollingShelf", Vector3(-1.45, 0.0, -1.68), 0)
	_build_rolling_shelf_bank(level_one_root, "CenterRollingShelf", Vector3(0.72, 0.0, -1.68), 12)
	_build_transfer_cart(level_one_root)
	_build_capacity_meter(level_one_root)
	_build_rejected_intake_bin(level_one_root)


func _build_annex_shell(parent: Node3D) -> void:
	_add_box(parent, "RecordsAnnexFloorSlab", Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0), Color("4d5957"), 0.94)
	_add_box(parent, "RecordsAnnexFloorInset", Vector3(6.08, 0.018, 5.48), Vector3(0.0, -0.010, 0.0), Color("3e4948"), 0.96)
	_add_box(parent, "RecordsAnnexBackWall", Vector3(6.20, 3.45, 0.20), Vector3(0.0, 1.725, -2.78), CREAM, 0.88)
	_add_box(parent, "RecordsAnnexBackWallDado", Vector3(6.22, 1.10, 0.06), Vector3(0.0, 0.57, -2.665), SAGE, 0.82)
	_add_box(parent, "RecordsAnnexBarnTrim", Vector3(6.24, 0.14, 0.12), Vector3(0.0, 3.45, -2.64), BARN_RED, 0.72)

	# The camera-facing +Z frontage remains open. Two rear side bays give the
	# annex a believable shell without turning the expansion into a green cage.
	# The west frame's service jamb remains behind z=-0.7, preserving the audited
	# office-to-annex route strip through the center of the parcel.
	for side_x in [-3.08, 3.08]:
		for post_z in [-2.66, -0.95]:
			_add_box(parent, "RecordsAnnexSidePost", Vector3(0.14, 3.34, 0.14), Vector3(side_x, 1.67, post_z), DEEP_SAGE, 0.66, 0.14)
		for rail_y in [0.12, 1.68, 3.30]:
			_add_box(parent, "RecordsAnnexSideRail", Vector3(0.16, 0.12, 1.58), Vector3(side_x, rail_y, -1.805), DEEP_SAGE, 0.66, 0.14)
	_add_box(parent, "RecordsFrontThreshold", Vector3(5.30, 0.07, 0.12), Vector3(0.0, 0.035, 2.68), BRASS.darkened(0.18), 0.70, 0.28)

	var identity_bed := _add_box(
		parent, "RecordsAnnexIdentityBed",
		Vector3(3.05, 0.84, 0.10), Vector3(-0.95, 2.78, -2.655),
		Color("b9b39f"), 0.82, 0.08,
	)
	EnvironmentalSignageScript.add_panel(
		identity_bed, "RecordsAnnexIdentity", "RECORDS ANNEX",
		Vector3(0.0, 0.11, 0.056), Vector2(2.62, 0.40),
		Color("b9b39f"), DEEP_SAGE.darkened(0.16), Vector3.ZERO,
		19, 0.0034, &"primary", &"destination",
	)
	EnvironmentalSignageScript.add_panel(
		identity_bed, "RecordsAnnexIdentitySubtitle", "ROLLING RECORDS FLOOR",
		Vector3(0.0, -0.25, 0.056), Vector2(2.36, 0.18),
		Color("b9b39f"), GRAPHITE, Vector3.ZERO,
		10, 0.0022, &"utility", &"stencil",
	)


func _build_rolling_shelf_bank(parent: Node3D, bank_name: String, bank_position: Vector3, starting_slot: int) -> void:
	var bank := Node3D.new()
	bank.name = bank_name
	bank.position = bank_position
	parent.add_child(bank)
	_add_box(bank, "RollingShelfPlinth", Vector3(1.94, 0.16, 0.76), Vector3(0.0, 0.10, 0.0), GRAPHITE, 0.62, 0.28)
	for rail_x in [-0.68, 0.68]:
		_add_box(bank, "RollingShelfFloorRail", Vector3(0.13, 0.055, 1.02), Vector3(rail_x, 0.028, 0.10), BRASS, 0.48, 0.46)
	for post_x in [-0.90, 0.90]:
		for post_z in [-0.30, 0.30]:
			_add_box(bank, "RollingShelfPost", Vector3(0.08, 2.12, 0.08), Vector3(post_x, 1.12, post_z), DEEP_SAGE, 0.58, 0.20)
	for shelf_y in [0.24, 0.82, 1.40, 2.18]:
		_add_box(bank, "RollingShelfDeck", Vector3(1.90, 0.07, 0.70), Vector3(0.0, shelf_y, 0.0), SERVICE_GREY, 0.62, 0.28)
	_add_box(bank, "RollingShelfCrossBrace", Vector3(1.78, 0.07, 0.06), Vector3(0.0, 2.11, -0.34), BRASS, 0.50, 0.34)
	for local_slot in 12:
		var row := int(local_slot / 6)
		var column := local_slot % 6
		_create_file_folder(
			bank,
			Vector3(-0.68 + column * 0.272, 0.465 + row * 0.58, 0.01),
			starting_slot + local_slot,
			1,
		)


func _build_transfer_cart(parent: Node3D) -> void:
	var cart := Node3D.new()
	cart.name = "ConnectedRecordsTransferCart"
	cart.position = Vector3(-0.55, 0.0, 1.62)
	parent.add_child(cart)
	_add_box(cart, "TransferCartLowerDeck", Vector3(1.58, 0.10, 0.82), Vector3(0.0, 0.35, 0.0), SERVICE_GREY, 0.54, 0.34)
	_add_box(cart, "TransferCartUpperDeck", Vector3(1.58, 0.10, 0.82), Vector3(0.0, 1.00, 0.0), SERVICE_GREY, 0.54, 0.34)
	for post_x in [-0.70, 0.70]:
		for post_z in [-0.32, 0.32]:
			_add_box(cart, "TransferCartPost", Vector3(0.07, 0.94, 0.07), Vector3(post_x, 0.67, post_z), SERVICE_GREY, 0.50, 0.38)
	_add_box(cart, "TransferCartHandleUpright", Vector3(0.08, 1.28, 0.08), Vector3(-0.82, 0.72, -0.32), GRAPHITE, 0.50, 0.34)
	_add_box(cart, "TransferCartHandle", Vector3(0.08, 0.08, 0.72), Vector3(-0.82, 1.34, 0.0), GRAPHITE, 0.50, 0.34)
	for wheel_x in [-0.60, 0.60]:
		for wheel_z in [-0.27, 0.27]:
			var wheel := _add_cylinder(cart, "TransferCartWheel", Vector3(wheel_x, 0.16, wheel_z), 0.13, 0.08, GRAPHITE, 0.66, 0.12)
			wheel.rotation_degrees.z = 90.0
	for tray_index in 3:
		_add_box(cart, "TransferCartFileTray", Vector3(0.38, 0.22, 0.58), Vector3(-0.48 + tray_index * 0.48, 0.78, 0.0), KRAFT.darkened(0.04 * tray_index), 0.90)


func _build_capacity_meter(parent: Node3D) -> void:
	var meter := Node3D.new()
	meter.name = "AuthoritativeRecordsCapacityMeter"
	# The compact meter crowns the retention-vault bay. This keeps the live count
	# readable at every tier without closing the camera-facing frontage.
	meter.position = Vector3(2.05, 2.82, -2.655)
	parent.add_child(meter)
	var housing := _add_box(meter, "RecordsCapacityHousing", Vector3(1.60, 0.96, 0.12), Vector3.ZERO, DEEP_SAGE, 0.62, 0.12)
	EnvironmentalSignageScript.add_panel(
		housing, "RecordsCapacityCaption", "AUTHORIZED FILE CAPACITY",
		Vector3(0.0, 0.34, 0.072), Vector2(1.36, 0.15),
		DEEP_SAGE, CREAM, Vector3.ZERO,
		8, 0.0018, &"utility", &"stencil",
	)
	for segment_index in 10:
		var segment := _add_box(
			meter, "CapacitySegment_%02d" % segment_index,
			Vector3(0.095, 0.15, 0.032),
			Vector3(-0.54 + segment_index * 0.12, 0.10, 0.083),
			GRAPHITE.lightened(0.04), 0.72,
		)
		_gauge_segments.append(segment)
	_gauge_needle = Node3D.new()
	_gauge_needle.name = "CapacityGaugeNeedlePivot"
	_gauge_needle.position = Vector3(0.0, -0.10, 0.102)
	meter.add_child(_gauge_needle)
	_add_cylinder(_gauge_needle, "CapacityGaugeHub", Vector3.ZERO, 0.075, 0.045, BRASS, 0.38, 0.48).rotation_degrees.x = 90.0
	_add_box(_gauge_needle, "CapacityGaugeNeedle", Vector3(0.045, 0.36, 0.030), Vector3(0.0, 0.16, 0.0), AMBER, 0.38, 0.22)
	_capacity_label = EnvironmentalSignageScript.add_panel(
		housing, "RecordsCapacityReadout", "FILES  000 / 018",
		Vector3(0.0, -0.36, 0.072), Vector2(1.16, 0.16),
		Color("293427"), Color("d9c96c"), Vector3.ZERO,
		9, 0.0019, &"utility", &"screen", true,
	)
	var overdue_lamp := _add_cylinder(meter, "LevelOneOverdueLamp", Vector3(0.66, -0.35, 0.105), 0.07, 0.045, DARK_RED, 0.40, 0.20)
	overdue_lamp.rotation_degrees.x = 90.0
	_overdue_lamps.append(overdue_lamp)


func _build_rejected_intake_bin(parent: Node3D) -> void:
	var bin := Node3D.new()
	bin.name = "RejectedIntakeOverflowBin"
	bin.position = Vector3(2.42, 0.0, 1.72)
	parent.add_child(bin)
	_add_box(bin, "OverflowBinBase", Vector3(1.18, 0.12, 0.88), Vector3(0.0, 0.08, 0.0), GRAPHITE, 0.72, 0.20)
	_add_box(bin, "OverflowBinBack", Vector3(1.18, 0.72, 0.10), Vector3(0.0, 0.46, -0.39), OXIDE, 0.74, 0.10)
	for side_x in [-0.54, 0.54]:
		_add_box(bin, "OverflowBinSide", Vector3(0.10, 0.72, 0.78), Vector3(side_x, 0.46, 0.0), OXIDE, 0.74, 0.10)
	var front := _add_box(bin, "OverflowBinFront", Vector3(1.18, 0.48, 0.10), Vector3(0.0, 0.34, 0.39), DARK_RED, 0.74, 0.10)
	EnvironmentalSignageScript.add_panel(
		front, "RejectedIntakeBinPlate", "INTAKE RETURNED",
		Vector3(0.0, 0.0, 0.062), Vector2(0.94, 0.18),
		DARK_RED, CREAM, Vector3.ZERO,
		9, 0.0019, &"utility", &"machine",
	)
	for bundle_index in OVERFLOW_BUNDLE_SLOT_COUNT:
		var bundle := Node3D.new()
		bundle.name = "RejectedIntakeBundle_%02d" % bundle_index
		bundle.position = Vector3(
			-0.30 + (bundle_index % 2) * 0.60,
			0.205 + int(bundle_index / 2) * 0.135,
			-0.05 + (bundle_index % 3) * 0.04,
		)
		bin.add_child(bundle)
		_add_box(bundle, "ReturnedFileStack", Vector3(0.48, 0.13, 0.56), Vector3.ZERO, PAPER.darkened(0.03 * bundle_index), 0.94)
		_add_box(bundle, "ReturnedFileBand", Vector3(0.09, 0.145, 0.58), Vector3.ZERO, BARN_RED.darkened(0.04 * bundle_index), 0.82)
		_overflow_bundles.append(bundle)


func _build_level_two() -> void:
	level_two_root = Node3D.new()
	level_two_root.name = "PneumaticTriageLevelTwo"
	add_child(level_two_root)
	_build_pneumatic_triage_spine(level_two_root)
	_build_triage_staging_rack(level_two_root)
	_build_powered_file_rail(level_two_root)


func _build_pneumatic_triage_spine(parent: Node3D) -> void:
	var triage := Node3D.new()
	triage.name = "PneumaticTriageSpine"
	triage.position = Vector3(1.92, 0.0, 0.18)
	parent.add_child(triage)
	_add_box(triage, "TriageConsolePlinth", Vector3(1.58, 0.16, 1.02), Vector3(0.0, 0.10, 0.0), GRAPHITE, 0.62, 0.24)
	_add_box(triage, "TriageConsoleCabinet", Vector3(1.46, 0.78, 0.92), Vector3(0.0, 0.55, 0.0), SAGE, 0.66, 0.12)
	var console_face := _add_box(triage, "TriageConsoleFace", Vector3(1.24, 0.50, 0.08), Vector3(0.0, 0.62, 0.50), GRAPHITE, 0.54, 0.22)
	EnvironmentalSignageScript.add_panel(
		console_face, "TriageConsolePlate", "PNEUMATIC TRIAGE",
		Vector3(0.0, 0.17, 0.050), Vector2(1.02, 0.15),
		GRAPHITE, CREAM, Vector3.ZERO,
		9, 0.0019, &"utility", &"machine",
	)
	for lane_index in LANE_ORDER.size():
		var lane := LANE_ORDER[lane_index]
		var lane_x := -0.42 + lane_index * 0.42
		var lane_color: Color = LANE_COLORS[lane]
		var chute := _add_cylinder(
			triage, "TriageChute_%s" % lane,
			Vector3(lane_x, 1.38, -0.08), 0.17, 0.94,
			SERVICE_GREY, 0.42, 0.44,
		)
		_add_cylinder(triage, "TriageChuteCollar_%s" % lane, Vector3(lane_x, 0.96, -0.08), 0.23, 0.11, BRASS, 0.38, 0.50)
		var lamp := _add_cylinder(triage, "TriageLaneLamp_%s" % lane, Vector3(lane_x, 0.56, 0.555), 0.08, 0.04, lane_color, 0.38, 0.16)
		lamp.rotation_degrees.x = 90.0
		_lane_lamps[lane] = lamp
		var header_y := 2.78 + lane_index * 0.13
		var rise_bottom := 1.82
		_add_cylinder(
			triage, "PneumaticRise_%s" % lane,
			Vector3(lane_x, (rise_bottom + header_y) * 0.5, -0.08),
			0.075, header_y - rise_bottom,
			SERVICE_GREY.lightened(0.10), 0.34, 0.52,
		)
		var service_mast_x := -1.02
		var run_length := lane_x - service_mast_x
		var tube_run := _add_cylinder(
			triage, "PneumaticHeaderRun_%s" % lane,
			Vector3((lane_x + service_mast_x) * 0.5, header_y, -0.08),
			0.075, run_length,
			SERVICE_GREY.lightened(0.10), 0.34, 0.52,
		)
		tube_run.rotation_degrees.z = 90.0
		_add_cylinder(triage, "PneumaticHeaderJoint_%s" % lane, Vector3(lane_x, header_y, -0.08), 0.11, 0.12, BRASS, 0.36, 0.48)
	# One grounded service mast ties the overhead runs to the cabinet so the tubes
	# read as machinery, not floating decoration.
	_add_box(triage, "PneumaticServiceMast", Vector3(0.16, 3.24, 0.16), Vector3(-1.02, 1.62, -0.08), DEEP_SAGE, 0.56, 0.22)
	_add_box(triage, "PneumaticHeaderBeam", Vector3(2.18, 0.14, 0.14), Vector3(0.0, 3.18, -0.08), DEEP_SAGE, 0.54, 0.24)


func _build_triage_staging_rack(parent: Node3D) -> void:
	var rack := Node3D.new()
	rack.name = "TriageStagingRack"
	rack.position = Vector3(2.44, 0.0, -1.55)
	parent.add_child(rack)
	_add_box(rack, "TriageRackPlinth", Vector3(1.02, 0.14, 0.70), Vector3(0.0, 0.09, 0.0), GRAPHITE, 0.62, 0.24)
	for post_x in [-0.46, 0.46]:
		for post_z in [-0.27, 0.27]:
			_add_box(rack, "TriageRackPost", Vector3(0.07, 1.72, 0.07), Vector3(post_x, 0.93, post_z), DEEP_SAGE, 0.58, 0.20)
	for shelf_y in [0.22, 0.84, 1.50, 1.80]:
		_add_box(rack, "TriageRackDeck", Vector3(1.00, 0.065, 0.64), Vector3(0.0, shelf_y, 0.0), SERVICE_GREY, 0.60, 0.28)
	for local_slot in 6:
		var row := int(local_slot / 3)
		var column := local_slot % 3
		_create_file_folder(
			rack,
			Vector3(-0.28 + column * 0.28, 0.445 + row * 0.62, 0.0),
			24 + local_slot,
			2,
		)


func _build_powered_file_rail(parent: Node3D) -> void:
	var rail := Node3D.new()
	rail.name = "PoweredFileTransferRail"
	rail.position = Vector3(0.30, 0.0, -0.72)
	parent.add_child(rail)
	_add_box(rail, "PoweredRailBeam", Vector3(3.66, 0.13, 0.20), Vector3(0.0, 2.34, 0.0), SERVICE_GREY, 0.48, 0.38)
	for support_x in [-1.68, 1.68]:
		_add_box(rail, "PoweredRailSupport", Vector3(0.11, 2.34, 0.11), Vector3(support_x, 1.17, 0.0), DEEP_SAGE, 0.60, 0.20)
		_add_box(rail, "PoweredRailFoot", Vector3(0.34, 0.10, 0.42), Vector3(support_x, 0.05, 0.0), GRAPHITE, 0.64, 0.24)
	for carrier_index in 4:
		var carrier_x := -1.20 + carrier_index * 0.80
		_add_box(rail, "PoweredRailCarrier", Vector3(0.24, 0.17, 0.34), Vector3(carrier_x, 2.18, 0.0), BRASS, 0.44, 0.44)
		_add_box(rail, "PoweredRailFilePouch", Vector3(0.34, 0.46, 0.28), Vector3(carrier_x, 1.85, 0.0), KRAFT.darkened(0.04 * carrier_index), 0.88)


func _build_level_three() -> void:
	level_three_root = Node3D.new()
	level_three_root.name = "PermanentRetentionVaultLevelThree"
	add_child(level_three_root)
	_build_retention_vault(level_three_root)
	_build_retention_carousel(level_three_root)
	_build_overdue_beacon(level_three_root)
	_build_retention_ledger(level_three_root)


func _build_retention_vault(parent: Node3D) -> void:
	var vault := Node3D.new()
	vault.name = "PermanentRetentionVault"
	vault.position = Vector3(2.18, 0.0, -1.82)
	parent.add_child(vault)
	_add_box(vault, "RetentionVaultBody", Vector3(1.46, 2.38, 1.12), Vector3(0.0, 1.19, 0.0), DEEP_SAGE, 0.56, 0.24)
	var door := _add_box(vault, "RetentionVaultDoor", Vector3(1.20, 2.08, 0.10), Vector3(0.0, 1.20, 0.61), SERVICE_GREY, 0.48, 0.40)
	for rib_y in [0.38, 0.88, 1.38, 1.88]:
		_add_box(vault, "RetentionVaultDoorRib", Vector3(1.04, 0.055, 0.035), Vector3(0.0, rib_y, 0.68), GRAPHITE, 0.58, 0.28)
	_add_cylinder(vault, "RetentionVaultWheel", Vector3(0.0, 1.20, 0.69), 0.25, 0.07, BRASS, 0.36, 0.54).rotation_degrees.x = 90.0
	EnvironmentalSignageScript.add_panel(
		door, "RetentionVaultPlate", "PERMANENT RETENTION",
		Vector3(0.0, 0.73, 0.062), Vector2(0.94, 0.18),
		SERVICE_GREY, CREAM, Vector3.ZERO,
		9, 0.0019, &"utility", &"machine",
	)


func _build_retention_carousel(parent: Node3D) -> void:
	var carousel := Node3D.new()
	carousel.name = "RetentionFileCarousel"
	carousel.position = Vector3(1.12, 0.0, -0.30)
	parent.add_child(carousel)
	_add_cylinder(carousel, "CarouselFloorPlinth", Vector3(0.0, 0.10, 0.0), 0.92, 0.20, GRAPHITE, 0.58, 0.30)
	_add_cylinder(carousel, "CarouselLowerRing", Vector3(0.0, 0.64, 0.0), 0.78, 0.10, SERVICE_GREY, 0.46, 0.42)
	_add_cylinder(carousel, "CarouselUpperRing", Vector3(0.0, 1.58, 0.0), 0.78, 0.10, SERVICE_GREY, 0.46, 0.42)
	_add_cylinder(carousel, "CarouselCentralColumn", Vector3(0.0, 0.90, 0.0), 0.13, 1.62, BRASS, 0.40, 0.52)
	for local_slot in 6:
		var angle := TAU * float(local_slot) / 6.0
		var radial := Vector3(cos(angle) * 0.56, 0.0, sin(angle) * 0.56)
		var tray := _add_box(carousel, "CarouselRadialTray", Vector3(0.46, 0.07, 0.34), radial + Vector3(0.0, 0.78, 0.0), SERVICE_GREY, 0.50, 0.38)
		tray.rotation.y = -angle
		var folder := _create_file_folder(
			carousel,
			radial + Vector3(0.0, 1.00, 0.0),
			30 + local_slot,
			3,
		)
		folder.rotation.y = -angle
	for spoke_index in 6:
		var angle := TAU * float(spoke_index) / 6.0
		var spoke := _add_box(carousel, "CarouselConnectedSpoke", Vector3(0.70, 0.07, 0.10), Vector3(cos(angle) * 0.30, 0.64, sin(angle) * 0.30), BRASS, 0.46, 0.48)
		spoke.rotation.y = -angle


func _build_overdue_beacon(parent: Node3D) -> void:
	var beacon := Node3D.new()
	beacon.name = "OverdueRetentionBeacon"
	beacon.position = Vector3(2.78, 0.0, -2.30)
	parent.add_child(beacon)
	_add_box(beacon, "OverdueBeaconFoot", Vector3(0.46, 0.16, 0.46), Vector3(0.0, 0.08, 0.0), GRAPHITE, 0.60, 0.28)
	_add_cylinder(beacon, "OverdueBeaconStem", Vector3(0.0, 1.66, 0.0), 0.045, 3.00, SERVICE_GREY, 0.44, 0.44)
	var housing := _add_cylinder(beacon, "OverdueBeaconHousing", Vector3(0.0, 3.22, 0.0), 0.22, 0.30, DARK_RED, 0.52, 0.18)
	var lamp := _add_sphere(beacon, "OverdueBeaconLamp", Vector3(0.0, 3.22, 0.0), Vector3(0.31, 0.25, 0.31), Color("ef6e55"), 0.30)
	_overdue_lamps.append(lamp)
	EnvironmentalSignageScript.add_panel(
		housing, "OverdueBeaconPlate", "OVERDUE",
		Vector3(0.0, -0.24, 0.225), Vector2(0.42, 0.11),
		DARK_RED, CREAM, Vector3.ZERO,
		8, 0.0016, &"utility", &"machine",
	)


func _build_retention_ledger(parent: Node3D) -> void:
	var board := _add_box(parent, "RetentionLedgerBoard", Vector3(1.72, 1.04, 0.10), Vector3(-2.05, 1.55, -2.655), GRAPHITE, 0.60, 0.10)
	EnvironmentalSignageScript.add_panel(
		board, "RetentionLedgerHeader", "RETENTION LEDGER",
		Vector3(0.0, 0.35, 0.062), Vector2(1.44, 0.20),
		DARK_RED, CREAM, Vector3.ZERO,
		10, 0.0021, &"secondary", &"board_header",
	)
	for row_index in 4:
		_add_box(board, "RetentionLedgerRule", Vector3(1.34, 0.020, 0.015), Vector3(0.0, 0.10 - row_index * 0.19, 0.070), SERVICE_GREY.lightened(0.18), 0.78)
		_add_box(board, "RetentionLedgerPeg", Vector3(0.13 + row_index * 0.06, 0.06, 0.025), Vector3(-0.50, 0.10 - row_index * 0.19, 0.082), AMBER if row_index < 3 else BARN_RED, 0.54)


func _create_file_folder(parent: Node3D, folder_position: Vector3, slot_index: int, tier: int) -> Node3D:
	var folder := Node3D.new()
	folder.name = "AuthoritativeFileFolder_%02d" % slot_index
	folder.position = folder_position
	parent.add_child(folder)
	var body := _add_box(folder, "FileFolderBody", Vector3(0.19, 0.38, 0.38), Vector3(0.0, 0.0, 0.0), PAPER, 0.90)
	var tab := _add_box(folder, "FileFolderTab", Vector3(0.11, 0.08, 0.40), Vector3(-0.035, 0.22, 0.0), PAPER.lightened(0.10), 0.88)
	_add_box(folder, "FileFolderSpine", Vector3(0.025, 0.34, 0.405), Vector3(-0.085, -0.01, 0.0), KRAFT.darkened(0.12), 0.88)
	_folder_slots.append(folder)
	_folder_bodies.append(body)
	_folder_tabs.append(tab)
	_folder_tiers.append(tier)
	return folder


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
