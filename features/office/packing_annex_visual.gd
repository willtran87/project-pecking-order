class_name PackingAnnexVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only capital expansion outside the office's east wall.
## Rect2 uses world-local X/Z coordinates so layout tests and future expansion
## modules can reserve the site without reverse-engineering individual meshes.
const FACILITY_ID := &"farmer_brand_packing_annex"
const FACILITY_CENTER := Vector3(15.20, 0.0, -6.00)
const FOOTPRINT := Rect2(Vector2(12.00, -8.90), Vector2(6.40, 5.80))
const MAX_LEVEL := 3
const CARTON_SLOT_COUNT := 6
const MAX_OPAQUE_HEIGHT := 3.60

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

var locked_marker_root: Node3D
var survey_site_root: Node3D
var level_one_root: Node3D
var level_two_root: Node3D
var level_three_root: Node3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _carton_progress_fillers: Array[MeshInstance3D] = []
var _carton_progress_label: Label3D
var _premium_lamp_material: StandardMaterial3D
var _built := false
var _unlocked := false
var _facility_level := 0
var _carton_progress := 0
var _carton_target_progress := 0
var _last_cartons_total := -1
var _carton_completion_holding := false
var _carton_hold_generation := 0
var _has_applied_snapshot := false


func _ready() -> void:
	name = "PackingAnnexVisual"
	position = FACILITY_CENTER
	if not _built:
		build()


static func declared_footprint() -> Rect2:
	return FOOTPRINT


func focus_point_global() -> Vector3:
	## Stable purchase/reveal camera target at the center of the open production floor.
	return to_global(Vector3(0.0, 0.90, 0.0))


func build() -> void:
	clear()
	_built = true
	_build_locked_marker()
	_build_survey_site()
	_build_level_one()
	_build_level_two()
	_build_level_three()
	_remove_decorative_egg_seals()
	_apply_visibility()


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
	_carton_progress_fillers.clear()
	_carton_progress_label = null
	_premium_lamp_material = null
	_carton_hold_generation += 1
	_carton_completion_holding = false
	_carton_target_progress = 0
	_last_cartons_total = -1
	_has_applied_snapshot = false
	_material_cache.clear()
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var previous_level := _facility_level
	_facility_level = clampi(_snapshot_facility_level(snapshot), 0, MAX_LEVEL)
	_unlocked = _facility_level > 0 or _snapshot_catalog_unlocked(snapshot)
	_carton_target_progress = clampi(
		_snapshot_carton_progress(snapshot),
		0,
		CARTON_SLOT_COUNT,
	)
	var cartons_total := _snapshot_cartons_total(snapshot)
	var completed_now := (
		_last_cartons_total >= 0
		and cartons_total > _last_cartons_total
		and _facility_level > 0
	)
	_last_cartons_total = cartons_total
	if completed_now:
		_carton_progress = CARTON_SLOT_COUNT
		_carton_completion_holding = true
		_carton_hold_generation += 1
		_release_completed_carton_after_hold(_carton_hold_generation)
	elif not _carton_completion_holding:
		_carton_progress = _carton_target_progress
	_apply_visibility()
	if _has_applied_snapshot and _facility_level > previous_level:
		for revealed_level in range(previous_level + 1, _facility_level + 1):
			_animate_level_reveal(revealed_level)
	_has_applied_snapshot = true


func visual_state() -> StringName:
	if _facility_level > 0:
		return StringName("level_%d" % _facility_level)
	return &"survey" if _unlocked else &"locked"


func facility_level() -> int:
	return _facility_level


func carton_progress() -> int:
	return _carton_progress


func locked_marker_visible() -> bool:
	return locked_marker_root != null and locked_marker_root.visible


func survey_site_visible() -> bool:
	return survey_site_root != null and survey_site_root.visible


func level_visible(level: int) -> bool:
	match level:
		1:
			return level_one_root != null and level_one_root.visible
		2:
			return level_two_root != null and level_two_root.visible
		3:
			return level_three_root != null and level_three_root.visible
	return false


func visible_carton_progress_slots() -> int:
	var visible_count := 0
	for filler in _carton_progress_fillers:
		if filler != null and filler.visible:
			visible_count += 1
	return visible_count


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
	for slot_index in _carton_progress_fillers.size():
		_carton_progress_fillers[slot_index].visible = slot_index < _carton_progress
	if _carton_progress_label != null:
		_carton_progress_label.text = "CARTON  %d / %d" % [_carton_progress, CARTON_SLOT_COUNT]
		EnvironmentalSignageScript.refit_label(_carton_progress_label)


func _snapshot_facility_level(snapshot: Dictionary) -> int:
	var owned_variant: Variant = snapshot.get("owned_facilities", {})
	if owned_variant is Dictionary:
		var owned := owned_variant as Dictionary
		if owned.has(FACILITY_ID) or owned.has(String(FACILITY_ID)):
			return _level_from_variant(owned.get(FACILITY_ID, owned.get(String(FACILITY_ID), 0)))
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


func _snapshot_carton_progress(snapshot: Dictionary) -> int:
	if snapshot.has("packing_carton_progress"):
		return int(snapshot.get("packing_carton_progress", 0))
	var annex_variant: Variant = snapshot.get("packing_annex", {})
	if annex_variant is Dictionary:
		var annex := annex_variant as Dictionary
		return int(annex.get("carton_progress", 0))
	var effects_variant: Variant = snapshot.get("facility_effects", {})
	if effects_variant is Dictionary:
		var effects := effects_variant as Dictionary
		return int(effects.get("packing_carton_progress", 0))
	return 0


func _snapshot_cartons_total(snapshot: Dictionary) -> int:
	if snapshot.has("packing_cartons_total"):
		return maxi(0, int(snapshot.get("packing_cartons_total", 0)))
	var contract_variant: Variant = snapshot.get("packing_contract", {})
	if contract_variant is Dictionary:
		return maxi(0, int((contract_variant as Dictionary).get("cartons_total", 0)))
	var annex_variant: Variant = snapshot.get("packing_annex", {})
	if annex_variant is Dictionary:
		return maxi(0, int((annex_variant as Dictionary).get("cartons_total", 0)))
	return 0


func _release_completed_carton_after_hold(generation: int) -> void:
	await get_tree().create_timer(0.72).timeout
	if (
		generation != _carton_hold_generation
		or not is_inside_tree()
		or not _carton_completion_holding
	):
		return
	_carton_completion_holding = false
	_carton_progress = _carton_target_progress
	_apply_visibility()


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
	revealed_root.scale = Vector3(0.96, 0.06, 0.96)
	var reveal := create_tween().bind_node(revealed_root)
	reveal.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	reveal.tween_property(revealed_root, "scale", Vector3(1.0, 1.04, 1.0), 0.46)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	reveal.tween_property(revealed_root, "scale", Vector3.ONE, 0.12)


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
		var entry_variant: Variant = catalog.get(FACILITY_ID, catalog.get(String(FACILITY_ID), null))
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


func _remove_decorative_egg_seals() -> void:
	# Beam-letter fixtures normally receive a tiny oval bureau logo. The annex's
	# six-slot meter is the only egg-shaped production language allowed here, so
	# room and lease lettering keep their physical beds but omit those seals.
	for seal in find_children("BureauEggSeal", "MeshInstance3D", true, false):
		(seal as MeshInstance3D).free()


func _build_locked_marker() -> void:
	locked_marker_root = Node3D.new()
	locked_marker_root.name = "PackingAnnexLeaseBoundary"
	add_child(locked_marker_root)

	# A surveyed lease outline establishes the expansion without pretending that
	# anything has already been purchased. All rails remain ankle-low.
	for edge_z in [-2.72, 2.72]:
		_add_box(
			locked_marker_root, "LeaseBoundaryRailZ",
			Vector3(6.08, 0.035, 0.055), Vector3(0.0, 0.025, edge_z),
			BRASS.darkened(0.24), 0.72, 0.24
		)
	for edge_x in [-3.02, 3.02]:
		_add_box(
			locked_marker_root, "LeaseBoundaryRailX",
			Vector3(0.055, 0.035, 5.38), Vector3(edge_x, 0.026, 0.0),
			BRASS.darkened(0.24), 0.72, 0.24
		)
	for corner_x in [-3.02, 3.02]:
		for corner_z in [-2.72, 2.72]:
			_add_cylinder(
				locked_marker_root, "LeaseSurveyPin",
				Vector3(corner_x, 0.10, corner_z), 0.055, 0.20,
				BARN_RED, 0.60, 0.12
			)

	var board := Node3D.new()
	board.name = "LeaseBoundaryMarker"
	board.position = Vector3(0.0, 0.0, -2.55)
	locked_marker_root.add_child(board)
	for post_x in [-1.72, 1.72]:
		_add_box(board, "LeaseBoardPost", Vector3(0.11, 1.58, 0.11), Vector3(post_x, 0.79, 0.0), TIMBER, 0.76)
	var board_face := _add_box(
		board, "LeaseBoardFace", Vector3(4.05, 1.20, 0.12),
		Vector3(0.0, 1.34, 0.0), DEEP_SAGE, 0.78
	)
	EnvironmentalSignageScript.add_panel(
		board_face, "PackingAnnexLeaseOption", "LEASE OPTION",
		Vector3(0.0, 0.22, 0.072), Vector2(3.56, 0.44),
		DEEP_SAGE, CREAM, Vector3.ZERO,
		17, 0.0034, &"secondary", &"beam"
	)
	EnvironmentalSignageScript.add_panel(
		board_face, "PackingAnnexBoardApproval", "BOARD APPROVAL REQUIRED",
		Vector3(0.0, -0.31, 0.072), Vector2(3.08, 0.22),
		SAGE.darkened(0.08), Color("e6d6ad"), Vector3.ZERO,
		11, 0.0026, &"secondary", &"stencil"
	)


func _build_survey_site() -> void:
	survey_site_root = Node3D.new()
	survey_site_root.name = "PackingAnnexSurveySite"
	add_child(survey_site_root)

	_add_box(
		survey_site_root, "AnnexSurveyFoundation",
		Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0),
		Color("626b68"), 0.94
	)
	_add_box(
		survey_site_root, "AnnexSurveyInset",
		Vector3(6.10, 0.018, 5.50), Vector3(0.0, -0.010, 0.0),
		Color("4f5b58"), 0.96
	)
	for grid_x in [-2.0, 0.0, 2.0]:
		_add_box(survey_site_root, "SurveyChalkLineX", Vector3(0.025, 0.008, 5.20), Vector3(grid_x, 0.004, 0.0), WARM_WHITE.darkened(0.18), 0.98)
	for grid_z in [-1.70, 0.0, 1.70]:
		_add_box(survey_site_root, "SurveyChalkLineZ", Vector3(5.70, 0.008, 0.025), Vector3(0.0, 0.005, grid_z), WARM_WHITE.darkened(0.18), 0.98)
	for stake_x in [-2.85, 2.85]:
		for stake_z in [-2.52, 2.52]:
			_add_box(survey_site_root, "AnnexSurveyStake", Vector3(0.08, 0.62, 0.08), Vector3(stake_x, 0.31, stake_z), TIMBER, 0.78)
			_add_box(survey_site_root, "AnnexSurveyFlag", Vector3(0.34, 0.17, 0.018), Vector3(stake_x + 0.13, 0.50, stake_z), BARN_RED, 0.88)

	var quote_board := _add_box(
		survey_site_root, "AnnexQuoteBoard",
		Vector3(3.35, 0.88, 0.10), Vector3(0.0, 0.78, -2.59),
		DEEP_SAGE, 0.78
	)
	EnvironmentalSignageScript.add_panel(
		quote_board, "PackingAnnexSiteNotice", "PACKING ANNEX SITE\nQUOTES PENDING",
		Vector3(0.0, 0.0, 0.062), Vector2(3.02, 0.60),
		DEEP_SAGE, CREAM, Vector3.ZERO,
		15, 0.0030, &"secondary", &"machine"
	)
	_build_blueprint_table(survey_site_root)


func _build_blueprint_table(parent: Node3D) -> void:
	var table := Node3D.new()
	table.name = "AnnexSurveyBlueprintTable"
	table.position = Vector3(-1.75, 0.0, 1.38)
	parent.add_child(table)
	_add_box(table, "BlueprintTableTop", Vector3(1.70, 0.10, 0.92), Vector3(0.0, 0.84, 0.0), TIMBER, 0.76)
	for leg_x in [-0.70, 0.70]:
		for leg_z in [-0.34, 0.34]:
			_add_box(table, "BlueprintTableLeg", Vector3(0.09, 0.80, 0.09), Vector3(leg_x, 0.40, leg_z), GRAPHITE, 0.56, 0.34)
	var plan := _add_box(table, "RolledOutAnnexPlan", Vector3(1.42, 0.014, 0.70), Vector3(0.0, 0.899, 0.0), BLUEPRINT, 0.96)
	for line_index in 4:
		_add_box(plan, "BlueprintRule", Vector3(1.06 - line_index * 0.10, 0.004, 0.012), Vector3(0.0, 0.011, -0.23 + line_index * 0.15), WARM_WHITE, 0.96)


func _build_level_one() -> void:
	level_one_root = Node3D.new()
	level_one_root.name = "FarmerBrandPackingAnnexLevelOne"
	add_child(level_one_root)
	_build_annex_shell(level_one_root)
	_build_manual_line(level_one_root)
	_build_carton_rack(level_one_root)
	_build_label_printer(level_one_root)
	_build_status_tower(level_one_root)
	_build_carton_progress_meter(level_one_root)


func _build_annex_shell(parent: Node3D) -> void:
	_add_box(
		parent, "PackingAnnexFloorSlab",
		Vector3(6.40, 0.18, 5.80), Vector3(0.0, -0.11, 0.0),
		Color("4d5957"), 0.94
	)
	_add_box(
		parent, "PackingAnnexFloorInset",
		Vector3(6.08, 0.018, 5.48), Vector3(0.0, -0.010, 0.0),
		Color("3e4948"), 0.96
	)
	_add_box(
		parent, "PackingAnnexBackWall",
		Vector3(6.20, 3.65, 0.20), Vector3(0.0, 1.77, -2.78),
		CREAM, 0.88
	)
	_add_box(parent, "PackingAnnexBackWallDado", Vector3(6.22, 1.12, 0.06), Vector3(0.0, 0.58, -2.665), SAGE, 0.82)
	_add_box(parent, "PackingAnnexBarnTrim", Vector3(6.24, 0.16, 0.12), Vector3(0.0, 3.43, -2.64), BARN_RED, 0.72)

	# Segmented side glazing and roof beams frame the building but the +Z face is
	# deliberately open to the office camera and to future interaction staging.
	for side_x in [-3.08, 3.08]:
		for post_z in [-2.66, -1.02, 0.62, 2.42]:
			_add_box(parent, "PackingAnnexSidePost", Vector3(0.14, 3.48, 0.14), Vector3(side_x, 1.72, post_z), DEEP_SAGE, 0.66, 0.14)
		for rail_y in [0.12, 1.72, 3.37]:
			_add_box(parent, "PackingAnnexSideRail", Vector3(0.16, 0.12, 5.22), Vector3(side_x, rail_y, -0.10), DEEP_SAGE, 0.66, 0.14)
		for bay_z in [-1.84, -0.20, 1.52]:
			_add_glass_box(parent, "PackingAnnexSideGlass", Vector3(0.035, 1.45, 1.46), Vector3(side_x, 2.52, bay_z))
	for beam_z in [-2.62, -0.86, 0.90, 2.42]:
		_add_box(parent, "PackingAnnexRoofBeam", Vector3(6.14, 0.14, 0.14), Vector3(0.0, 3.43, beam_z), DEEP_SAGE, 0.64, 0.18)

	# Room identity belongs to its wall beam, while the bureau retains the sole
	# primary architectural landmark. A smooth die-cut-style wordmark keeps the
	# annex readable without repeating the bureau's ceremonial identity plaque.
	var identity_beam := _add_box(
		parent, "PackingAnnexIdentityBeam",
		Vector3(4.96, 0.90, 0.10), Vector3(0.0, 2.72, -2.655),
		Color("b9b39f"), 0.82, 0.08
	)
	EnvironmentalSignageScript.add_panel(
		identity_beam, "FarmerBrandAnnexIdentity", "FARMER BRAND",
		Vector3(0.0, 0.12, 0.056), Vector2(4.18, 0.42),
		Color("b9b39f"), DEEP_SAGE.darkened(0.16), Vector3.ZERO,
		20, 0.0035, &"primary", &"destination"
	)
	EnvironmentalSignageScript.add_panel(
		identity_beam, "PackingAnnexIdentitySubtitle", "PACKING ANNEX",
		Vector3(0.0, -0.27, 0.056), Vector2(2.62, 0.19),
		Color("b9b39f"), GRAPHITE, Vector3.ZERO,
		11, 0.0024, &"utility", &"stencil"
	)


func _build_manual_line(parent: Node3D) -> void:
	var line := Node3D.new()
	line.name = "ManualPackingConveyor"
	line.position = Vector3(-0.35, 0.0, 0.20)
	parent.add_child(line)
	_add_box(line, "ManualLineFrame", Vector3(3.78, 0.16, 0.98), Vector3(0.0, 0.72, 0.0), SERVICE_GREY, 0.52, 0.34)
	_add_box(line, "ManualLineBelt", Vector3(3.60, 0.055, 0.80), Vector3(0.0, 0.84, 0.0), GRAPHITE, 0.74)
	for roller_index in 9:
		var roller := _add_cylinder(
			line, "ManualLineRoller",
			Vector3(-1.58 + roller_index * 0.395, 0.885, 0.0),
			0.055, 0.76, SERVICE_GREY, 0.42, 0.44
		)
		roller.rotation_degrees.x = 90.0
	for leg_x in [-1.62, -0.55, 0.55, 1.62]:
		for leg_z in [-0.36, 0.36]:
			_add_box(line, "ManualLineConnectedLeg", Vector3(0.09, 0.70, 0.09), Vector3(leg_x, 0.35, leg_z), SERVICE_GREY, 0.52, 0.34)
	_add_box(line, "ManualLineFrontApron", Vector3(3.72, 0.34, 0.08), Vector3(0.0, 0.62, 0.47), SAGE, 0.72, 0.06)


func _build_carton_rack(parent: Node3D) -> void:
	var rack := Node3D.new()
	rack.name = "CartonRack"
	rack.position = Vector3(-2.28, 0.0, -1.65)
	parent.add_child(rack)
	for post_x in [-0.58, 0.58]:
		for post_z in [-0.24, 0.24]:
			_add_box(rack, "CartonRackPost", Vector3(0.08, 1.82, 0.08), Vector3(post_x, 0.91, post_z), DEEP_SAGE, 0.58, 0.20)
	for shelf_y in [0.18, 0.72, 1.26, 1.78]:
		_add_box(rack, "CartonRackShelf", Vector3(1.30, 0.07, 0.62), Vector3(0.0, shelf_y, 0.0), SERVICE_GREY, 0.62, 0.28)
	for carton_index in 6:
		var column := carton_index % 2
		var row := int(carton_index / 2)
		_add_box(
			rack, "FoldedCartonStock",
			Vector3(0.48, 0.08, 0.44),
			Vector3(-0.27 + column * 0.54, 0.29 + row * 0.54, 0.0),
			KRAFT.darkened(row * 0.035), 0.92
		)


func _build_label_printer(parent: Node3D) -> void:
	var printer := Node3D.new()
	printer.name = "AnnexLabelPrinter"
	printer.position = Vector3(2.10, 0.0, 0.05)
	parent.add_child(printer)
	_add_box(printer, "LabelPrinterCabinet", Vector3(1.10, 0.82, 0.90), Vector3(0.0, 0.43, 0.0), SAGE, 0.68, 0.10)
	_add_box(printer, "LabelPrinterTop", Vector3(1.18, 0.10, 0.98), Vector3(0.0, 0.88, 0.0), CREAM, 0.64)
	var head := _add_box(printer, "LabelPrinterHead", Vector3(0.72, 0.54, 0.48), Vector3(0.0, 1.18, -0.14), GRAPHITE, 0.54, 0.22)
	_add_box(printer, "LabelPrinterOutputSlot", Vector3(0.48, 0.055, 0.030), Vector3(0.0, 1.14, 0.115), Color("182224"), 0.92)
	EnvironmentalSignageScript.add_panel(
		head, "AnnexPrinterPlate", "FARMER BRAND\nLABEL OFFICE",
		Vector3(0.0, 0.0, 0.248), Vector2(0.58, 0.30),
		GRAPHITE, CREAM, Vector3.ZERO,
		11, 0.0022, &"utility", &"machine"
	)


func _build_status_tower(parent: Node3D) -> void:
	var tower := Node3D.new()
	tower.name = "PackingStatusTower"
	tower.position = Vector3(2.68, 0.0, -1.48)
	parent.add_child(tower)
	_add_box(tower, "PackingTowerBase", Vector3(0.44, 0.22, 0.44), Vector3(0.0, 0.11, 0.0), GRAPHITE, 0.58, 0.26)
	_add_cylinder(tower, "PackingTowerStem", Vector3(0.0, 0.84, 0.0), 0.045, 1.48, SERVICE_GREY, 0.44, 0.44)
	for lamp_index in 3:
		var lamp_color := [GREEN, AMBER, BARN_RED][lamp_index] as Color
		var lamp := _add_cylinder(tower, "PackingStatusLamp_%d" % lamp_index, Vector3(0.0, 1.47 + lamp_index * 0.18, 0.0), 0.095, 0.15, lamp_color, 0.34, 0.10)
		lamp.material_override = _emissive_material(lamp_color, 0.24 if lamp_index == 0 else 0.08)


func _build_carton_progress_meter(parent: Node3D) -> void:
	var meter := Node3D.new()
	meter.name = "AuthoritativeCartonProgressMeter"
	meter.position = Vector3(1.28, 1.48, -2.655)
	parent.add_child(meter)
	var housing := _add_box(meter, "CartonMeterHousing", Vector3(2.74, 0.82, 0.12), Vector3.ZERO, DEEP_SAGE, 0.64, 0.10)
	EnvironmentalSignageScript.add_panel(
		housing, "CartonMeterCaption", "SIX-SHELL CARTON",
		Vector3(0.0, 0.245, 0.072), Vector2(2.25, 0.19),
		DEEP_SAGE, CREAM, Vector3.ZERO,
		10, 0.0021, &"utility", &"stencil"
	)
	for slot_index in CARTON_SLOT_COUNT:
		var slot_x := -1.02 + slot_index * 0.408
		_add_box(meter, "CartonProgressSlot_%d" % slot_index, Vector3(0.28, 0.22, 0.045), Vector3(slot_x, -0.03, 0.085), Color("1f292a"), 0.62)
		var filler := _add_box(meter, "CartonProgressFill_%d" % slot_index, Vector3(0.22, 0.16, 0.030), Vector3(slot_x, -0.03, 0.116), AMBER, 0.38, 0.10)
		filler.material_override = _emissive_material(AMBER, 0.48)
		_carton_progress_fillers.append(filler)
	_carton_progress_label = EnvironmentalSignageScript.add_panel(
		housing, "CartonProgressReadout", "CARTON  0 / 6",
		Vector3(0.0, -0.285, 0.072), Vector2(1.44, 0.16),
		Color("403b27"), Color("e0bd58"), Vector3.ZERO,
		10, 0.0020, &"utility", &"screen", true
	)


func _build_level_two() -> void:
	level_two_root = Node3D.new()
	level_two_root.name = "FarmerBrandPackingAnnexLevelTwo"
	add_child(level_two_root)
	_build_automated_sealer(level_two_root)
	_build_second_belt(level_two_root)
	_build_weighing_head(level_two_root)
	_build_branded_pallet(level_two_root)


func _build_automated_sealer(parent: Node3D) -> void:
	var sealer := Node3D.new()
	sealer.name = "AutomatedSealer"
	sealer.position = Vector3(0.42, 0.0, -0.52)
	parent.add_child(sealer)
	for post_x in [-0.68, 0.68]:
		_add_box(sealer, "SealerPortalPost", Vector3(0.12, 1.58, 0.14), Vector3(post_x, 1.08, 0.0), DARK_RED, 0.58, 0.22)
	_add_box(sealer, "SealerPortalHeader", Vector3(1.52, 0.32, 0.46), Vector3(0.0, 1.86, 0.0), BARN_RED, 0.56, 0.16)
	_add_box(sealer, "SealingHead", Vector3(0.82, 0.18, 0.62), Vector3(0.0, 1.54, 0.0), GRAPHITE, 0.48, 0.36)
	_add_box(sealer, "SealingHeadGuard", Vector3(0.92, 0.08, 0.72), Vector3(0.0, 1.41, 0.0), BRASS, 0.42, 0.44)


func _build_second_belt(parent: Node3D) -> void:
	var belt := Node3D.new()
	belt.name = "SecondPackingBelt"
	belt.position = Vector3(-0.48, 0.0, 1.72)
	parent.add_child(belt)
	_add_box(belt, "SecondBeltFrame", Vector3(4.10, 0.15, 0.72), Vector3(0.0, 0.68, 0.0), SERVICE_GREY, 0.50, 0.36)
	_add_box(belt, "SecondBeltSurface", Vector3(3.94, 0.06, 0.58), Vector3(0.0, 0.79, 0.0), GRAPHITE, 0.70)
	for leg_x in [-1.76, -0.58, 0.58, 1.76]:
		for leg_z in [-0.26, 0.26]:
			_add_box(belt, "SecondBeltLeg", Vector3(0.08, 0.66, 0.08), Vector3(leg_x, 0.33, leg_z), SERVICE_GREY, 0.50, 0.36)


func _build_weighing_head(parent: Node3D) -> void:
	var scale := Node3D.new()
	scale.name = "AnnexWeighingHead"
	scale.position = Vector3(-1.46, 0.0, 1.72)
	parent.add_child(scale)
	_add_box(scale, "WeighingArchLeft", Vector3(0.10, 1.20, 0.10), Vector3(-0.52, 1.10, 0.0), SAGE, 0.56, 0.20)
	_add_box(scale, "WeighingArchRight", Vector3(0.10, 1.20, 0.10), Vector3(0.52, 1.10, 0.0), SAGE, 0.56, 0.20)
	_add_box(scale, "WeighingArchTop", Vector3(1.14, 0.12, 0.12), Vector3(0.0, 1.70, 0.0), SAGE, 0.56, 0.20)
	var head := _add_box(scale, "WeighingSensorHead", Vector3(0.52, 0.26, 0.46), Vector3(0.0, 1.48, 0.0), GRAPHITE, 0.44, 0.34)
	EnvironmentalSignageScript.add_panel(
		head, "WeighingHeadPlate", "NET / GROSS",
		Vector3(0.0, 0.0, 0.242), Vector2(0.40, 0.13),
		GRAPHITE, Color("d1c875"), Vector3.ZERO,
		9, 0.0018, &"utility", &"machine"
	)


func _build_branded_pallet(parent: Node3D) -> void:
	var pallet := Node3D.new()
	pallet.name = "BrandedPallet"
	pallet.position = Vector3(2.25, 0.0, 1.62)
	parent.add_child(pallet)
	for slat_index in 5:
		_add_box(pallet, "PalletTimberSlat", Vector3(1.32, 0.10, 0.18), Vector3(0.0, 0.10, -0.46 + slat_index * 0.23), TIMBER, 0.88)
	for carton_index in 4:
		var column := carton_index % 2
		var row := int(carton_index / 2)
		var carton := _add_box(
			pallet, "SealedBrandedCarton_%d" % carton_index,
			Vector3(0.58, 0.44, 0.68),
			Vector3(-0.31 + column * 0.62, 0.38 + row * 0.46, 0.0),
			KRAFT.darkened(row * 0.04), 0.90
		)
		EnvironmentalSignageScript.add_panel(
			carton, "FarmerBrandCartonLabel_%d" % carton_index, "FARMER BRAND",
			Vector3(0.0, 0.0, 0.352), Vector2(0.45, 0.13),
			Color("d1b27c"), DARK_RED, Vector3.ZERO,
			8, 0.0017, &"utility", &"shipping"
		)


func _build_level_three() -> void:
	level_three_root = Node3D.new()
	level_three_root.name = "FarmerBrandPackingAnnexLevelThree"
	add_child(level_three_root)
	_build_dispatch_board(level_three_root)
	_build_contract_vault(level_three_root)
	_build_loading_hatch(level_three_root)
	_build_pallet_jack(level_three_root)
	_build_premium_indicator(level_three_root)


func _build_dispatch_board(parent: Node3D) -> void:
	var board := _add_box(parent, "DispatchBoard", Vector3(2.18, 1.18, 0.10), Vector3(1.72, 1.62, -2.655), GRAPHITE, 0.60, 0.10)
	EnvironmentalSignageScript.add_panel(
		board, "DispatchBoardHeader", "FARM GATE DISPATCH",
		Vector3(0.0, 0.41, 0.062), Vector2(1.86, 0.22),
		DARK_RED, CREAM, Vector3.ZERO,
		11, 0.0022, &"secondary", &"board_header"
	)
	for row_index in 4:
		_add_box(board, "DispatchLedgerRule", Vector3(1.68, 0.022, 0.015), Vector3(0.0, 0.16 - row_index * 0.20, 0.070), SERVICE_GREY.lightened(0.18), 0.78)
		_add_box(board, "DispatchStatusPeg", Vector3(0.16 + row_index * 0.08, 0.07, 0.025), Vector3(-0.64, 0.16 - row_index * 0.20, 0.082), GREEN if row_index < 3 else AMBER, 0.54)


func _build_contract_vault(parent: Node3D) -> void:
	var vault := Node3D.new()
	vault.name = "ContractVault"
	vault.position = Vector3(2.43, 0.0, -1.34)
	parent.add_child(vault)
	_add_box(vault, "ContractVaultBody", Vector3(1.02, 1.45, 0.88), Vector3(0.0, 0.73, 0.0), DEEP_SAGE, 0.58, 0.22)
	var door := _add_box(vault, "ContractVaultDoor", Vector3(0.82, 1.20, 0.08), Vector3(0.0, 0.74, 0.48), SERVICE_GREY, 0.48, 0.38)
	_add_cylinder(vault, "ContractVaultWheel", Vector3(0.0, 0.77, 0.55), 0.20, 0.07, BRASS, 0.38, 0.52).rotation_degrees.x = 90.0
	EnvironmentalSignageScript.add_panel(
		door, "ContractVaultPlate", "CONTRACTS",
		Vector3(0.0, 0.41, 0.050), Vector2(0.64, 0.16),
		SERVICE_GREY, CREAM, Vector3.ZERO,
		9, 0.0019, &"utility", &"machine"
	)


func _build_loading_hatch(parent: Node3D) -> void:
	var hatch := Node3D.new()
	hatch.name = "LoadingHatch"
	hatch.position = Vector3(-1.72, 1.10, -2.655)
	parent.add_child(hatch)
	_add_box(hatch, "LoadingHatchFrame", Vector3(2.26, 1.70, 0.12), Vector3.ZERO, DARK_RED, 0.62, 0.12)
	var hatch_door := _add_box(hatch, "LoadingHatchDoor", Vector3(1.98, 1.44, 0.07), Vector3(0.0, 0.0, 0.08), SERVICE_GREY, 0.70, 0.24)
	for rib_index in 4:
		_add_box(hatch, "LoadingHatchRib", Vector3(1.84, 0.055, 0.035), Vector3(0.0, -0.50 + rib_index * 0.33, 0.13), GRAPHITE, 0.60, 0.26)
	EnvironmentalSignageScript.add_panel(
		hatch_door, "LoadingHatchStencil", "FARM GATE 03",
		Vector3(0.0, -0.62, 0.040), Vector2(1.34, 0.18),
		SERVICE_GREY, CREAM, Vector3.ZERO,
		10, 0.0020, &"utility", &"stencil"
	)


func _build_pallet_jack(parent: Node3D) -> void:
	var jack := Node3D.new()
	jack.name = "PalletJack"
	jack.position = Vector3(-2.08, 0.0, 2.18)
	parent.add_child(jack)
	for fork_x in [-0.24, 0.24]:
		_add_box(jack, "PalletJackFork", Vector3(0.16, 0.10, 1.28), Vector3(fork_x, 0.15, -0.25), AMBER, 0.56, 0.30)
	_add_box(jack, "PalletJackCrossbar", Vector3(0.72, 0.20, 0.28), Vector3(0.0, 0.23, 0.45), AMBER, 0.56, 0.30)
	_add_box(jack, "PalletJackHandleStem", Vector3(0.10, 1.10, 0.10), Vector3(0.0, 0.77, 0.54), GRAPHITE, 0.48, 0.38).rotation_degrees.x = -12.0
	_add_box(jack, "PalletJackHandle", Vector3(0.74, 0.12, 0.12), Vector3(0.0, 1.31, 0.42), GRAPHITE, 0.48, 0.38)
	for wheel_x in [-0.27, 0.27]:
		var wheel := _add_cylinder(jack, "PalletJackWheel", Vector3(wheel_x, 0.13, 0.48), 0.13, 0.09, GRAPHITE, 0.68, 0.10)
		wheel.rotation_degrees.z = 90.0


func _build_premium_indicator(parent: Node3D) -> void:
	var indicator := Node3D.new()
	indicator.name = "PremiumIndicator"
	indicator.position = Vector3(2.58, 2.78, -2.655)
	parent.add_child(indicator)
	var housing := _add_box(indicator, "PremiumIndicatorHousing", Vector3(0.82, 0.66, 0.12), Vector3.ZERO, DARK_RED, 0.58, 0.16)
	_add_box(indicator, "PremiumIndicatorInset", Vector3(0.58, 0.40, 0.035), Vector3(0.0, 0.0, 0.083), GRAPHITE, 0.62)
	var lamp := _add_cylinder(indicator, "PremiumContractLamp", Vector3(0.0, 0.03, 0.13), 0.12, 0.055, BRASS, 0.30, 0.34)
	lamp.rotation_degrees.x = 90.0
	_premium_lamp_material = _emissive_material(Color("efd277"), 0.72)
	lamp.material_override = _premium_lamp_material
	EnvironmentalSignageScript.add_panel(
		housing, "PremiumIndicatorPlate", "PREMIUM",
		Vector3(0.0, -0.23, 0.072), Vector2(0.64, 0.13),
		DARK_RED, CREAM, Vector3.ZERO,
		9, 0.0018, &"utility", &"machine"
	)


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


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, Color(0.50, 0.70, 0.69, 0.20), 0.18, 0.08)
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
