class_name OfficeStorytelling
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")
const SemanticColorPaletteScript := preload("res://core/settings/semantic_color_palette.gd")
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
const FarmgateDispatchDepotVisualScript := preload("res://features/office/farmgate_dispatch_depot_visual.gd")
const CampusExpansionVisualScript := preload("res://features/office/campus_expansion_visual.gd")
const CampusPortfolioVisualScript := preload("res://features/office/campus_portfolio_visual.gd")

## Dense, visual-only office staging for the Egg Yield Bureau. All geometry is
## intentionally non-colliding: substantial props live in perimeter alcoves,
## while anything crossing a worker route is either a floor decal (< 2 cm) or
## an overhead rail (> 2.5 m).

# Kept for the current Office integration. New consumers that need the economy
# payload should connect to egg_reached_presentation_detailed instead.
signal egg_reached_presentation(worker_id: int, quality: StringName)
signal egg_reached_presentation_detailed(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	streak_bonus_cents: int
)
signal egg_graded(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	streak_bonus_cents: int,
	grading_world_position: Vector3
)
signal optional_visuals_finished

const DEFAULT_DESK_POSITIONS: Array[Vector3] = [
	Vector3(-6.0, 0.0, -2.8),
	Vector3(0.0, 0.0, -2.8),
	Vector3(6.0, 0.0, -2.8),
	Vector3(-6.0, 0.0, 3.0),
	Vector3(0.0, 0.0, 3.0),
	Vector3(6.0, 0.0, 3.0),
]
const DEFAULT_INTAKE_POSITION := Vector3(9.55, 0.0, 5.35)
const DEFAULT_PRESENTATION_POSITION := Vector3(9.4, 0.0, -6.85)
const WEST_PERCH_04_POSITION := Vector3(-6.0, 0.0, -2.8)
const WEST_PERCH_05_POSITION := Vector3(-6.0, 0.0, 3.0)
const PERCH_CENTER := Vector3(5.15, 0.0, -8.08)
const COLLECTION_CART_CENTER := Vector3(10.74, 0.0, -3.55)
const COLLECTION_RAIL_HEIGHT := 3.18
const SIDE_MANIFOLD_X := 10.82
const SORTER_ROUTE_INDEX := 4
const SORTER_OFFSET_FROM_PRESENTATION_Z := 1.80
const SORTER_LAMP_IDLE_ENERGY := 0.02
const RAIL_IDLE_ENERGY := 0.0
const RAIL_TRANSIT_ENERGY := 0.46
const RAIL_TRANSIT_AMPLITUDE := 0.12
const GRADING_RECEIPT_SLOT_COUNT := 1
const GRADING_RECEIPT_QUEUE_LIMIT := 6
const GRADING_RECEIPT_SLOT_SPACING := -0.62
const MAX_VISIBLE_CLUTCH_EGGS := 36
const HANDOFF_ECHOES_PER_EGG := 3
const MAX_HANDOFF_ECHOES := 18
const HANDOFF_ECHO_SAMPLE_SECONDS := 0.025
const HANDOFF_ECHO_HISTORY_SAMPLES := 10
const HANDOFF_ECHO_HISTORY_STRIDE := 2
const PRESENTATION_CLUTCH_SLOTS := 24
const CART_CLUTCH_SLOTS := MAX_VISIBLE_CLUTCH_EGGS - PRESENTATION_CLUTCH_SLOTS
const REVIEW_SHIFT_PHASE := 3
const GRADING_RECEIPT_COLORS := {
	&"sound": Color("7eb28f"),
	&"golden": Color("d6a34e"),
	&"cracked": Color("b85c51"),
}
const CARE_CAMPUS_SPINE_FOOTPRINT := Rect2(Vector2(10.75, 8.70), Vector2(1.00, 18.50))
const OPERATIONS_CAMPUS_SPINE_FOOTPRINT := Rect2(Vector2(10.75, 27.20), Vector2(1.00, 12.00))
const CARE_CAMPUS_FIRST_BAY_FOOTPRINT := Rect2(Vector2(10.75, 8.70), Vector2(1.00, 12.40))
const CARE_CAMPUS_SECOND_BAY_FOOTPRINT := Rect2(Vector2(10.75, 21.10), Vector2(1.00, 6.10))
const OPERATIONS_CAMPUS_FIRST_BAY_FOOTPRINT := Rect2(Vector2(10.75, 27.20), Vector2(1.00, 5.90))
const OPERATIONS_CAMPUS_SECOND_BAY_FOOTPRINT := Rect2(Vector2(10.75, 33.10), Vector2(1.00, 6.10))
const OPTIONAL_VISUAL_BUILD_COUNT := 18

# Presentation states are deliberately derived from the authoritative snapshot.
# They are not save data and never alter construction, economy, or unlock state.
const CAMPUS_PRESENTATION_HIDDEN: StringName = &"hidden"
const CAMPUS_PRESENTATION_TEASED: StringName = &"teased"
const CAMPUS_PRESENTATION_OFFERED: StringName = &"offered"
const CAMPUS_PRESENTATION_PINNED: StringName = &"pinned"
const CAMPUS_PRESENTATION_OWNED: StringName = &"owned"

const CANDLING_REWORK_BAY_ID: StringName = &"candling_rework_bay"
const PACKING_ANNEX_ID: StringName = &"farmer_brand_packing_annex"
const RECORDS_ANNEX_ID: StringName = &"records_annex"
const FARM_MUTUAL_SERVICE_COOP_ID: StringName = &"farm_mutual_service_coop"
const FARM_MUTUAL_NEGOTIATION_ROOM_ID: StringName = &"farm_mutual_negotiation_room"
const WELLNESS_NEST_ID: StringName = &"wellness_nest_room"
const TRAINING_ROOST_ID: StringName = &"training_roost"
const ROOSTER_OPERATIONS_OFFICE_ID: StringName = &"rooster_operations_office"
const IT_COOP_ID: StringName = &"it_coop"
const FLOCK_RELATIONS_OFFICE_ID: StringName = &"flock_relations_office"
const FEED_PROCUREMENT_COOP_ID: StringName = &"feed_procurement_coop"
const FARMER_RELATIONS_GALLERY_ID: StringName = &"farmer_relations_gallery"
const FARMGATE_DISPATCH_DEPOT_ID: StringName = &"farmgate_dispatch_depot"
const FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID: StringName = &"farm_mutual_contract_board"
const NORTH_MEADOW_PRESENTATION_ID: StringName = &"north_meadow"
const ORCHARD_ROW_PRESENTATION_ID: StringName = &"orchard_row"
const CREEKSIDE_YARD_PRESENTATION_ID: StringName = &"creekside_yard"
const CARE_CAMPUS_SPINE_PRESENTATION_ID: StringName = &"care_campus_spine"
const OPERATIONS_CAMPUS_SPINE_PRESENTATION_ID: StringName = &"operations_campus_spine"
const PORTFOLIO_SERVICE_TRUNK_PRESENTATION_ID: StringName = &"portfolio_service_trunk"

const CAMPUS_PRESENTATION_FACILITY_ORDER: Array[StringName] = [
	CANDLING_REWORK_BAY_ID,
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
	FLOCK_RELATIONS_OFFICE_ID,
	FEED_PROCUREMENT_COOP_ID,
	FARMER_RELATIONS_GALLERY_ID,
	FARMGATE_DISPATCH_DEPOT_ID,
]
const CARE_CAMPUS_FACILITY_IDS: Array[StringName] = [
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	FARMER_RELATIONS_GALLERY_ID,
]
const OPERATIONS_CAMPUS_FACILITY_IDS: Array[StringName] = [
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
	FLOCK_RELATIONS_OFFICE_ID,
	FEED_PROCUREMENT_COOP_ID,
]
const CAMPUS_PRESENTATION_TEASER_ORDER: Array[StringName] = [
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	FARMER_RELATIONS_GALLERY_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	FEED_PROCUREMENT_COOP_ID,
	IT_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	FARMGATE_DISPATCH_DEPOT_ID,
	FLOCK_RELATIONS_OFFICE_ID,
	NORTH_MEADOW_PRESENTATION_ID,
	ORCHARD_ROW_PRESENTATION_ID,
	CREEKSIDE_YARD_PRESENTATION_ID,
]


class EggHandoffTrail extends RefCounted:
	var egg: Node3D
	var quality: StringName = &"sound"
	var base_scale := Vector3.ONE
	var echoes: Array[MeshInstance3D] = []
	var history: Array[Vector3] = []
	var sample_elapsed: float = 0.0
	var phase_offset: float = 0.0

var management_perch_root: Node3D
var egg_collection_root: Node3D
var zone_markers_root: Node3D
var bureau_satire_root: Node3D
var records_archive_root: Node3D
var shell_quality_lab_visual: ShellQualityLabVisual
var packing_annex_visual: Node3D
var records_annex_visual: Node3D
var farm_mutual_service_coop_visual: Node3D
var farm_mutual_negotiation_room_visual: Node3D
var farm_mutual_contract_board_visual: Node3D
var care_campus_spine_root: Node3D
var care_campus_first_bay_root: Node3D
var care_campus_second_bay_root: Node3D
var wellness_nest_visual: Node3D
var training_roost_visual: Node3D
var farmer_relations_gallery_visual: Node3D
var operations_campus_spine_root: Node3D
var operations_campus_first_bay_root: Node3D
var operations_campus_second_bay_root: Node3D
var rooster_operations_office_visual: Node3D
var it_coop_visual: Node3D
var flock_relations_office_visual: Node3D
var feed_procurement_coop_visual: Node3D
var farmgate_dispatch_depot_visual: Node3D
var campus_expansion_visual: Node3D
var campus_portfolio_visual: Node3D

var _desk_positions: Array[Vector3] = DEFAULT_DESK_POSITIONS.duplicate()
var _intake_position := DEFAULT_INTAKE_POSITION
var _presentation_position := DEFAULT_PRESENTATION_POSITION
var _worker_to_desk: Dictionary[int, int] = {}
var _worker_names: Dictionary[int, String] = {}
var _pickup_points: Array[Vector3] = []
var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _color_vision_mode: StringName = &"standard"
var _zone_glows: Array[MeshInstance3D] = []
var _animated_eggs: Array[Node3D] = []
var _metrics_label: Label3D
var _intake_status_label: Label3D
var _perch_screen_material: StandardMaterial3D
var _rail_glow_material: StandardMaterial3D
var _quality_lamps: Dictionary = {}
var _quality_lamp_materials: Dictionary = {}
var _quality_lamp_tweens: Dictionary = {}
var _grading_receipt_slots: Array = []
var _grading_receipt_queue: Array[Dictionary] = []
var _clutch_slots: Array[Node3D] = []
var _clutch_slot_markers: Array[Dictionary] = []
var _clutch_cup_batches: Array[MultiMeshInstance3D] = []
var _settled_clutch_eggs: Array[Node3D] = []
var _clutch_recoil_tweens: Dictionary = {}
var _presentation_clutch_root: Node3D
var _cart_clutch_root: Node3D
var _collection_cart_basket: MeshInstance3D
var _surplus_marker_root: Node3D
var _surplus_label: Label3D
var _clutch_egg_mesh: Mesh
var _clutch_cup_mesh: CylinderMesh
var _egg_handoff_trails: Dictionary[int, EggHandoffTrail] = {}
var _egg_handoff_echo_pool: Array[MeshInstance3D] = []
var _displayed_clutch_day := -1
var _desired_clutch_counts: Dictionary = {
	&"sound": 0,
	&"golden": 0,
	&"cracked": 0,
}
var _configured := false
var _built := false
var _overtime_active := false
var _phase := 0.0
var _campus_presentation: Dictionary = {}
var _visible_campus_footprints: Array[Rect2] = []
var _visible_campus_bounds := Rect2()
var _last_campus_presentation_source: Dictionary = {}
var _last_campus_presentation_options: Dictionary = {}
var _office_physical_capacity := 6
var _dormant_west_context := false
var _defer_optional_visuals := DisplayServer.get_name() != "headless"
var _lazy_hidden_optional_visuals := false
var _optional_visuals_ready := false
var _optional_visual_build_index := 0
var _optional_visual_instantiated_count := 0
var _optional_visual_built_indices: Dictionary = {}
var _optional_visual_build_generation := 0
var _optional_visual_build_started_msec := 0
var _optional_visual_build_completed_msec := 0
var _optional_visual_build_timings: Dictionary = {}
var _last_snapshot: Dictionary = {}
var _archive_story_content: Node3D
var _intake_story_content: Node3D
var _records_zone: Node3D
var _west_perch_04_zone: Node3D
var _west_perch_05_zone: Node3D


func _ready() -> void:
	name = "OfficeStorytelling"
	if not _built:
		_build_all()


func set_color_vision_mode(mode: StringName) -> void:
	var normalized := SemanticColorPaletteScript.normalize_mode(mode)
	if normalized == _color_vision_mode:
		return
	_color_vision_mode = normalized
	for quality_variant in _quality_lamp_materials:
		var quality := StringName(quality_variant)
		var material := _quality_lamp_materials.get(quality) as StandardMaterial3D
		if material == null:
			continue
		var color := SemanticColorPaletteScript.quality_color(quality, _color_vision_mode)
		material.albedo_color = color.darkened(0.68)
		material.emission = color
	for egg in _animated_eggs + _settled_clutch_eggs:
		if egg == null or not is_instance_valid(egg):
			continue
		_apply_egg_quality_visual(
			egg,
			_normalized_quality(StringName(egg.get_meta("clutch_quality", &"sound"))),
			egg in _animated_eggs,
		)


func color_vision_mode() -> StringName:
	return _color_vision_mode


## Graphical builds stage expensive, initially hidden campus dressing after the
## core office becomes interactive. Tests and callers that need immediate
## construction can opt out before this node enters the tree.
func set_defer_optional_visuals(defer_build: bool) -> void:
	if _built:
		return
	_defer_optional_visuals = defer_build


## Web builds keep undiscovered campus modules out of the live scene tree until
## their authoritative presentation state becomes visible. The underlying
## facilities, prices, saves, and UI projections remain available immediately;
## only thousands of hidden visual nodes are made resident on demand.
func set_lazy_hidden_optional_visuals(lazy_build: bool) -> void:
	if _built:
		return
	_lazy_hidden_optional_visuals = lazy_build


func optional_visual_build_snapshot() -> Dictionary:
	var now_msec := Time.get_ticks_msec()
	var elapsed_msec := 0
	if _optional_visual_build_started_msec > 0:
		elapsed_msec = maxi(
			0,
			(_optional_visual_build_completed_msec if _optional_visuals_ready else now_msec)
			- _optional_visual_build_started_msec,
		)
	return {
		"deferred": _defer_optional_visuals,
		"lazy_hidden": _lazy_hidden_optional_visuals,
		"ready": _optional_visuals_ready,
		"built_count": _optional_visual_instantiated_count,
		"total_count": OPTIONAL_VISUAL_BUILD_COUNT,
		"deferred_count": OPTIONAL_VISUAL_BUILD_COUNT - _optional_visual_instantiated_count,
		"elapsed_msec": elapsed_msec,
		"build_timings_msec": _optional_visual_build_timings.duplicate(true),
	}


func _process(delta: float) -> void:
	_phase += delta
	if _perch_screen_material != null:
		var energy := (1.18 if _overtime_active else 0.78) + sin(_phase * 2.1) * 0.08
		_perch_screen_material.emission_energy_multiplier = energy
	for egg in _animated_eggs.duplicate():
		if is_instance_valid(egg):
			var quality := _normalized_quality(StringName(egg.get_meta("clutch_quality", &"sound")))
			egg.rotation.y += delta * (4.2 if quality == &"golden" else 2.6)
			if quality == &"cracked":
				var wobble_origin := float(egg.get_meta("handoff_wobble_origin", 0.0))
				egg.rotation.z = wobble_origin + sin(_phase * 11.5 + egg.get_instance_id() * 0.013) * 0.13
		else:
			_animated_eggs.erase(egg)
	if _rail_glow_material != null:
		_rail_glow_material.emission_energy_multiplier = (
			RAIL_IDLE_ENERGY
			if _animated_eggs.is_empty() else
			RAIL_TRANSIT_ENERGY + sin(_phase * 5.4) * RAIL_TRANSIT_AMPLITUDE
		)
	_update_egg_handoff_trails(delta)


## Safe to call either before or after add_child(). A second call rebuilds the
## visual module with the new layout. Positions are in this node's local space.
func configure(
	desk_positions: Array[Vector3],
	intake_position: Vector3 = DEFAULT_INTAKE_POSITION,
	presentation_position: Vector3 = DEFAULT_PRESENTATION_POSITION
) -> void:
	_desk_positions = desk_positions.duplicate() if not desk_positions.is_empty() else DEFAULT_DESK_POSITIONS.duplicate()
	_intake_position = intake_position
	_presentation_position = presentation_position
	_configured = true
	if is_inside_tree():
		_clear_built_roots()
		_build_all()


## Presentation-only commissioning state for the internal office. The complete
## archive and satire remain authored and testable; this only determines when
## their mature dressing participates in the live scene.
func set_office_physical_presentation(capacity: int, dormant_west_context: bool = false) -> void:
	_office_physical_capacity = clampi(capacity, 0, 6)
	_dormant_west_context = dormant_west_context and _office_physical_capacity < 6
	_apply_office_physical_presentation_state()


func _apply_office_physical_presentation_state() -> void:
	var full_bureau := _office_physical_capacity >= 6
	if bureau_satire_root != null and is_instance_valid(bureau_satire_root):
		bureau_satire_root.visible = full_bureau
	if _archive_story_content != null and is_instance_valid(_archive_story_content):
		_archive_story_content.visible = full_bureau
	if _intake_story_content != null and is_instance_valid(_intake_story_content):
		_intake_story_content.visible = true
	if _records_zone != null and is_instance_valid(_records_zone):
		_records_zone.visible = full_bureau
	if _west_perch_04_zone != null and is_instance_valid(_west_perch_04_zone):
		_west_perch_04_zone.visible = _office_physical_capacity >= 5
	if _west_perch_05_zone != null and is_instance_valid(_west_perch_05_zone):
		_west_perch_05_zone.visible = full_bureau


## Associates simulation worker IDs with desk indices for collection animation.
## apply_snapshot() also establishes this mapping automatically.
func bind_worker_to_desk(worker_id: int, desk_index: int) -> void:
	if desk_index >= 0 and desk_index < _desk_positions.size():
		_worker_to_desk[worker_id] = desk_index


## Updates the management KPI board and overtime staging. This method is cheap
## enough to call on every simulation snapshot.
func apply_snapshot(snapshot: Dictionary, refresh_campus_presentation: bool = true) -> void:
	if snapshot.is_empty():
		return
	_last_snapshot = snapshot
	var workers: Array = snapshot.get("workers", []) as Array
	for worker_variant in workers:
		var worker := worker_variant as Dictionary
		var worker_id := int(worker.get("id", -1))
		bind_worker_to_desk(worker_id, int(worker.get("desk_index", -1)))
		if worker_id >= 0:
			_worker_names[worker_id] = String(worker.get("name", "HEN %d" % (worker_id + 1)))
	_reconcile_clutch_from_snapshot(snapshot)
	if shell_quality_lab_visual != null:
		shell_quality_lab_visual.apply_snapshot(snapshot)
	if packing_annex_visual != null:
		packing_annex_visual.call("apply_snapshot", snapshot)
	if records_annex_visual != null:
		records_annex_visual.call("apply_snapshot", snapshot)
	if farm_mutual_service_coop_visual != null:
		farm_mutual_service_coop_visual.call("apply_snapshot", snapshot)
	if farm_mutual_negotiation_room_visual != null:
		farm_mutual_negotiation_room_visual.call("apply_snapshot", snapshot)
	if farm_mutual_contract_board_visual != null:
		farm_mutual_contract_board_visual.call("apply_snapshot", snapshot)
	if wellness_nest_visual != null:
		wellness_nest_visual.call("apply_snapshot", snapshot)
	if training_roost_visual != null:
		training_roost_visual.call("apply_snapshot", snapshot)
	if farmer_relations_gallery_visual != null:
		farmer_relations_gallery_visual.call("apply_snapshot", snapshot)
	if rooster_operations_office_visual != null:
		rooster_operations_office_visual.call("apply_snapshot", snapshot)
	if it_coop_visual != null:
		it_coop_visual.call("apply_snapshot", snapshot)
	if flock_relations_office_visual != null:
		flock_relations_office_visual.call("apply_snapshot", snapshot)
	if feed_procurement_coop_visual != null:
		feed_procurement_coop_visual.call("apply_snapshot", snapshot)
	if farmgate_dispatch_depot_visual != null:
		farmgate_dispatch_depot_visual.call("apply_snapshot", snapshot)
	if campus_expansion_visual != null:
		campus_expansion_visual.call("apply_snapshot", snapshot)
	if campus_portfolio_visual != null:
		campus_portfolio_visual.call("apply_snapshot", snapshot)
	# Child visuals retain their complete locked/survey/owned projections. The
	# presentation layer gates only their parent roots after those projections
	# update, so revealing a site later never requires rebuilding or save data.
	if refresh_campus_presentation:
		_refresh_campus_presentation_source(snapshot)
	if _metrics_label != null:
		var lane_counts := snapshot.get("claim_queue_counts", {}) as Dictionary
		_metrics_label.text = "YIELD  %03d / %03d\nN %02d   P %02d   A %02d\n%s  ·  LIVE" % [
			int(snapshot.get("eggs_today", 0)),
			int(snapshot.get("quota_target", 0)),
			int(lane_counts.get(&"nest_damage", 0)),
			int(lane_counts.get(&"predator_loss", 0)),
			int(lane_counts.get(&"appeals", 0)),
			String(snapshot.get("time_label", "9:00 AM")),
		]
		EnvironmentalSignageScript.refit_label(_metrics_label)
	if _intake_status_label != null:
		_intake_status_label.text = "RECEIVED  %04d\nCREDITED  %04d" % [
			int(snapshot.get("eggs_total", 0)),
			int(snapshot.get("claims_processed", 0)),
		]
		EnvironmentalSignageScript.refit_label(_intake_status_label)
	set_overtime(bool(snapshot.get("overtime_enabled", false)))


## Applies a presentation-only campus reveal derived from the authoritative
## simulation snapshot. `presentation_state` may contain:
## - `offered_ids`: opportunities the current UI has explicitly surfaced;
## - `teaser_id`: one explicit hidden opportunity to preview; or
## - `show_next_teaser` plus `teaser_window_days` (defaults to one day).
##
## The result is intentionally ephemeral. It is safe for old saves because
## owned/offered/pinned state is reconstructed from their current snapshot.
func apply_campus_presentation(
		snapshot: Dictionary,
		presentation_state: Dictionary = {},
) -> Dictionary:
	_last_campus_presentation_options = presentation_state.duplicate(true)
	_refresh_campus_presentation_source(snapshot)
	if _lazy_hidden_optional_visuals and _ensure_required_optional_visuals(snapshot):
		# Re-run the presentation pass after the required roots exist so the same
		# transaction that reveals an opportunity also mounts its finished art.
		_rebuild_campus_presentation()
	return campus_presentation_snapshot()


func _refresh_campus_presentation_source(snapshot: Dictionary) -> Dictionary:
	_last_campus_presentation_source = _campus_presentation_source(snapshot)
	_rebuild_campus_presentation()
	return campus_presentation_snapshot()


## Stable read model for UI, camera, and tests. `entries_by_id` includes hidden
## entries so callers can distinguish an undiscovered site from missing data.
func campus_presentation_snapshot() -> Dictionary:
	return _campus_presentation.duplicate(true)


func campus_presentation_state(presentation_id: StringName) -> StringName:
	var entries := _campus_presentation.get("entries_by_id", {}) as Dictionary
	var entry := entries.get(presentation_id, entries.get(String(presentation_id), {})) as Dictionary
	return StringName(String(entry.get("state", CAMPUS_PRESENTATION_HIDDEN)))


## World-local X/Z footprints for only the roots that are currently presented.
## Office can merge these into its compact base bounds without knowing facility
## implementation classes or accidentally framing undiscovered parcels.
func visible_campus_footprints() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for footprint: Rect2 in _visible_campus_footprints:
		result.append(footprint)
	return result


func visible_campus_bounds() -> Rect2:
	return _visible_campus_bounds


func visible_campus_camera_aabb(
		minimum_y: float = -0.20,
		maximum_y: float = 4.50,
) -> AABB:
	if _visible_campus_bounds.size.x <= 0.0 or _visible_campus_bounds.size.y <= 0.0:
		return AABB()
	return AABB(
		Vector3(_visible_campus_bounds.position.x, minimum_y, _visible_campus_bounds.position.y),
		Vector3(
			_visible_campus_bounds.size.x,
			maxf(0.0, maximum_y - minimum_y),
			_visible_campus_bounds.size.y,
		),
	)


func set_overtime(active: bool) -> void:
	_overtime_active = active
	var glow_color := Color("d05548") if active else Color("d1a94f")
	var glow_energy := 0.90 if active else 0.42
	for glow in _zone_glows:
		if is_instance_valid(glow):
			glow.material_override = _emissive_material(glow_color, glow_energy)


## Returns a route beginning at the supplied real egg socket. This makes it
## straightforward for Office to animate the egg it already spawned, rather
## than generating an egg at an unattended desk.
func collection_route_global(worker_id: int, egg_origin_global: Vector3) -> PackedVector3Array:
	var desk_index := _desk_index_for_worker(worker_id)
	if desk_index < 0 or desk_index >= _pickup_points.size():
		return PackedVector3Array([egg_origin_global, to_global(_presentation_position + Vector3.UP * 1.25)])
	var pickup := _pickup_points[desk_index]
	var lift := Vector3(pickup.x, COLLECTION_RAIL_HEIGHT, pickup.z)
	var manifold := Vector3(SIDE_MANIFOLD_X, COLLECTION_RAIL_HEIGHT, pickup.z)
	var sorter := _sorting_gate_center()
	sorter.y = COLLECTION_RAIL_HEIGHT
	var basket := _presentation_position + Vector3.UP * 1.25
	return PackedVector3Array([
		egg_origin_global,
		to_global(pickup),
		to_global(lift),
		to_global(manifold),
		to_global(sorter),
		to_global(basket),
	])


## Animates an existing, already-authorized egg along the visible collection
## system. The origin remains the hen's egg socket, preserving the seated-only
## production rule. Returns false when the node is invalid.
func animate_egg_collection(
	egg: Node3D,
	worker_id: int,
	quality: StringName,
	free_on_finish: bool = true,
	value_cents: int = 0,
	streak_bonus_cents: int = 0
) -> bool:
	if egg == null or not is_instance_valid(egg) or not is_inside_tree():
		return false
	var route := collection_route_global(worker_id, egg.global_position)
	egg.set_meta("clutch_quality", _normalized_quality(quality))
	# The physical route may outlive a review modal. Retain the launch day's
	# identity so a late arrival cannot populate the next shift's cleared basket.
	egg.set_meta("clutch_day", _displayed_clutch_day)
	_begin_egg_handoff_feedback(egg, quality)
	_animated_eggs.append(egg)
	var tween := create_tween().bind_node(egg)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	var rest_scale := egg.scale
	var has_sorter_waypoint := route.size() > SORTER_ROUTE_INDEX
	var last_route_index := route.size() - 1
	var travel_end := SORTER_ROUTE_INDEX + 1 if has_sorter_waypoint else route.size()
	for point_index in range(1, travel_end):
		var duration := 0.22 if point_index <= 2 else 0.34
		tween.tween_property(egg, "global_position", route[point_index], duration)
		if point_index == SORTER_ROUTE_INDEX:
			tween.tween_callback(_on_egg_graded.bind(
				egg, worker_id, quality, value_cents, streak_bonus_cents
			))
			tween.tween_property(egg, "scale", rest_scale * Vector3(1.12, 0.78, 1.12), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_interval(0.15)
			tween.tween_property(egg, "scale", rest_scale, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if has_sorter_waypoint:
		# The public route remains six stable semantic points for compatibility.
		# These two internal waypoints make the post-grade travel follow the
		# presentation manifold and drop tube before entering the basket.
		var manifold_end := to_global(Vector3(
			SIDE_MANIFOLD_X, COLLECTION_RAIL_HEIGHT, _presentation_position.z
		))
		var drop_point := to_global(Vector3(
			SIDE_MANIFOLD_X, 1.26, _presentation_position.z
		))
		tween.tween_property(egg, "global_position", manifold_end, 0.28)
		tween.tween_property(egg, "global_position", drop_point, 0.24)
		tween.tween_property(egg, "global_position", route[last_route_index], 0.28)
	# Invalid/unbound worker IDs retain the original direct fallback from the
	# shared loop above and still emit an enriched presentation event without
	# inventing a physical gate pass.

	tween.tween_callback(_on_egg_arrived.bind(
		egg, worker_id, quality, free_on_finish, value_cents, streak_bonus_cents
	))
	return true


func presentation_focus_point_global() -> Vector3:
	return to_global(_presentation_position + Vector3(0.0, 1.25, 0.0))


## Public camera waypoint for authored egg journeys. Keeping this derived from
## the sorter geometry prevents tutorial shots from drifting when the office
## layout is tuned.
func sorting_focus_point_global() -> Vector3:
	return to_global(_sorting_gate_center())


func _on_egg_graded(
	egg: Node3D,
	worker_id: int,
	quality: StringName,
	value_cents: int,
	streak_bonus_cents: int
) -> void:
	if egg == null or not is_instance_valid(egg):
		return
	var normalized_quality := _normalized_quality(quality)
	var safe_value := maxi(0, value_cents)
	var safe_bonus := maxi(0, streak_bonus_cents)
	_play_sorter_stamp_feedback(egg, normalized_quality)
	_pulse_quality_lamp(normalized_quality)
	_enqueue_grading_receipt(normalized_quality, safe_value, safe_bonus, worker_id)
	egg_graded.emit(
		worker_id,
		normalized_quality,
		safe_value,
		safe_bonus,
		egg.global_position
	)


func _on_egg_arrived(
	egg: Node3D,
	worker_id: int,
	quality: StringName,
	free_on_finish: bool,
	value_cents: int,
	streak_bonus_cents: int
) -> void:
	_animated_eggs.erase(egg)
	_end_egg_handoff_feedback(egg)
	var normalized_quality := _normalized_quality(quality)
	var safe_value := maxi(0, value_cents)
	var safe_bonus := maxi(0, streak_bonus_cents)
	# The authoritative collection callback remains synchronous with arrival.
	# The retained egg begins its bounded landing animation before the signal, so
	# Office can continue to release Feed Fund credit at this exact gate.
	var retained := false
	var launch_day := int(egg.get_meta("clutch_day", -1)) if is_instance_valid(egg) else -1
	if free_on_finish and is_instance_valid(egg) and launch_day == _displayed_clutch_day:
		retained = _settle_real_egg(egg, normalized_quality)
	egg_reached_presentation_detailed.emit(
		worker_id, normalized_quality, safe_value, safe_bonus
	)
	egg_reached_presentation.emit(worker_id, normalized_quality)
	if free_on_finish and not retained and is_instance_valid(egg):
		egg.queue_free()


func _normalized_quality(quality: StringName) -> StringName:
	return quality if GRADING_RECEIPT_COLORS.has(quality) else &"sound"


func _begin_egg_handoff_feedback(egg: Node3D, quality: StringName) -> void:
	if egg == null or not is_instance_valid(egg):
		return
	_end_egg_handoff_feedback(egg)
	var normalized := _normalized_quality(quality)
	_apply_egg_quality_visual(egg, normalized, true)
	egg.set_meta("handoff_wobble_origin", egg.rotation.z)

	var trail := EggHandoffTrail.new()
	trail.egg = egg
	trail.quality = normalized
	trail.base_scale = egg.scale
	trail.history.append(egg.global_position)
	trail.phase_offset = fmod(float(egg.get_instance_id()) * 0.173, TAU)
	for echo_index in HANDOFF_ECHOES_PER_EGG:
		var echo := _acquire_handoff_echo(normalized, echo_index)
		if echo == null:
			break
		trail.echoes.append(echo)
	if not trail.echoes.is_empty():
		_egg_handoff_trails[egg.get_instance_id()] = trail


func _end_egg_handoff_feedback(egg: Node3D) -> void:
	if egg == null or not is_instance_valid(egg):
		return
	_release_handoff_trail(egg.get_instance_id())
	egg.remove_meta("handoff_wobble_origin")
	var stamp_ring := egg.find_child("EggSorterStampRing", true, false) as MeshInstance3D
	if stamp_ring != null:
		stamp_ring.visible = false


func _update_egg_handoff_trails(delta: float) -> void:
	for trail_id in _egg_handoff_trails.keys():
		var trail: EggHandoffTrail = _egg_handoff_trails.get(trail_id)
		if trail == null or trail.egg == null or not is_instance_valid(trail.egg):
			_release_handoff_trail(trail_id)
			continue
		trail.sample_elapsed += delta
		while trail.sample_elapsed >= HANDOFF_ECHO_SAMPLE_SECONDS:
			trail.sample_elapsed -= HANDOFF_ECHO_SAMPLE_SECONDS
			var current_position := trail.egg.global_position
			if trail.history.is_empty() or current_position.distance_to(trail.history[0]) >= 0.025:
				trail.history.push_front(current_position)
				if trail.history.size() > HANDOFF_ECHO_HISTORY_SAMPLES:
					trail.history.pop_back()

		for echo_index in trail.echoes.size():
			var echo := trail.echoes[echo_index]
			if echo == null or not is_instance_valid(echo):
				continue
			var history_index := (echo_index + 1) * HANDOFF_ECHO_HISTORY_STRIDE
			if history_index >= trail.history.size():
				echo.visible = false
				continue
			echo.visible = true
			echo.global_position = trail.history[history_index]
			echo.global_rotation = trail.egg.global_rotation
			var falloff := 0.38 - echo_index * 0.075
			var pulse := 1.0 + sin(_phase * 8.0 + trail.phase_offset + echo_index) * 0.06
			echo.scale = trail.base_scale * falloff * pulse


func _acquire_handoff_echo(quality: StringName, echo_index: int) -> MeshInstance3D:
	var echo: MeshInstance3D = null
	for candidate in _egg_handoff_echo_pool:
		if is_instance_valid(candidate) and not bool(candidate.get_meta("handoff_in_use", false)):
			echo = candidate
			break
	if echo == null:
		if _egg_handoff_echo_pool.size() >= MAX_HANDOFF_ECHOES:
			return null
		if egg_collection_root == null or not is_instance_valid(egg_collection_root):
			return null
		echo = MeshInstance3D.new()
		echo.name = "PooledEggHandoffEcho_%02d" % _egg_handoff_echo_pool.size()
		echo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		egg_collection_root.add_child(echo)
		_egg_handoff_echo_pool.append(echo)
	echo.set_meta("handoff_in_use", true)
	echo.mesh = _clutch_egg_mesh
	echo.material_override = _handoff_echo_material(quality, echo_index)
	echo.visible = false
	return echo


func _release_handoff_trail(trail_id: int) -> void:
	var trail: EggHandoffTrail = _egg_handoff_trails.get(trail_id)
	if trail == null:
		return
	for echo in trail.echoes:
		if echo == null or not is_instance_valid(echo):
			continue
		echo.visible = false
		echo.set_meta("handoff_in_use", false)
		echo.position = Vector3.ZERO
		echo.rotation = Vector3.ZERO
		echo.scale = Vector3.ONE
	_egg_handoff_trails.erase(trail_id)


func _clear_egg_handoff_feedback() -> void:
	for trail_id in _egg_handoff_trails.keys():
		_release_handoff_trail(trail_id)
	_egg_handoff_trails.clear()
	for echo in _egg_handoff_echo_pool:
		if is_instance_valid(echo):
			echo.visible = false
			echo.set_meta("handoff_in_use", false)
	_egg_handoff_echo_pool.clear()


func _apply_egg_quality_visual(
	egg: Node3D,
	quality: StringName,
	include_transit_cue: bool
) -> void:
	if egg == null or not is_instance_valid(egg):
		return
	if _clutch_egg_mesh == null:
		_clutch_egg_mesh = _build_tapered_egg_mesh()
	var mesh_instance := egg as MeshInstance3D
	if mesh_instance != null:
		mesh_instance.mesh = _clutch_egg_mesh
		mesh_instance.material_override = _egg_quality_material(quality)
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	var existing := egg.get_node_or_null("EggQualityTreatment") as Node3D
	if existing != null:
		existing.free()
	var treatment := Node3D.new()
	treatment.name = "EggQualityTreatment"
	egg.add_child(treatment)

	match quality:
		&"golden":
			_add_golden_egg_treatment(treatment)
		&"cracked":
			_add_cracked_egg_treatment(treatment)
	if include_transit_cue:
		_add_sorter_stamp_ring(treatment, quality)


func _add_golden_egg_treatment(parent: Node3D) -> void:
	var ridge_mesh := TorusMesh.new()
	ridge_mesh.inner_radius = 0.37
	ridge_mesh.outer_radius = 0.405
	ridge_mesh.rings = 20
	ridge_mesh.ring_segments = 8
	var ridge := MeshInstance3D.new()
	ridge.name = "EggGoldenCrownRidge"
	ridge.mesh = ridge_mesh
	ridge.position.y = 0.15
	ridge.material_override = _emissive_material(Color("ffe08a"), 0.55)
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ridge)

	for arm_index in 2:
		var glint := _add_box(
			parent,
			"EggGoldenGlint_%d" % arm_index,
			Vector3(0.25, 0.025, 0.018),
			Vector3(0.0, 0.24, 0.43),
			Color("fff1af"),
			0.24,
			0.45
		)
		glint.rotation_degrees.z = arm_index * 90.0
		glint.material_override = _emissive_material(Color("fff1af"), 0.78)
		glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_cracked_egg_treatment(parent: Node3D) -> void:
	var points: Array[Vector2] = [
		Vector2(-0.19, 0.18),
		Vector2(-0.05, 0.08),
		Vector2(-0.13, -0.02),
		Vector2(0.04, -0.10),
		Vector2(0.17, -0.04),
	]
	for face_sign in [-1.0, 1.0]:
		for segment_index in points.size() - 1:
			var start := points[segment_index]
			var finish := points[segment_index + 1]
			var delta := finish - start
			var segment := _add_box(
				parent,
				"EggCrack_%s_%d" % ["Front" if face_sign > 0.0 else "Back", segment_index],
				Vector3(delta.length(), 0.026, 0.020),
				Vector3((start.x + finish.x) * 0.5, (start.y + finish.y) * 0.5, face_sign * 0.455),
				Color("4f3430"),
				0.98
			)
			segment.rotation.z = atan2(delta.y, delta.x)
			segment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_sorter_stamp_ring(parent: Node3D, quality: StringName) -> void:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.45
	ring_mesh.outer_radius = 0.50
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 8
	var ring := MeshInstance3D.new()
	ring.name = "EggSorterStampRing"
	ring.mesh = ring_mesh
	ring.visible = false
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.material_override = _make_handoff_ring_material(quality)
	parent.add_child(ring)


func _play_sorter_stamp_feedback(egg: Node3D, quality: StringName) -> void:
	if egg == null or not is_instance_valid(egg):
		return
	var ring := egg.find_child("EggSorterStampRing", true, false) as MeshInstance3D
	if ring == null:
		return
	var material := ring.material_override as StandardMaterial3D
	if material == null:
		return
	ring.visible = true
	ring.scale = Vector3.ONE * 0.50
	var ring_color := _egg_quality_color(quality)
	ring_color.a = 0.70
	material.albedo_color = ring_color
	var stamp := create_tween().bind_node(ring).set_parallel(true)
	stamp.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stamp.tween_property(ring, "scale", Vector3.ONE * 1.30, 0.28)
	stamp.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	stamp.tween_property(material, "albedo_color:a", 0.0, 0.28)
	stamp.chain().tween_callback(func() -> void:
		if is_instance_valid(ring):
			ring.visible = false
	)


func _handoff_echo_material(quality: StringName, echo_index: int) -> StandardMaterial3D:
	var normalized := _normalized_quality(quality)
	var key := "egg_handoff_echo_%s_%d" % [String(normalized), echo_index]
	if _material_cache.has(key):
		return _material_cache[key]
	var color := _egg_quality_color(normalized)
	color.a = [0.30, 0.20, 0.12][clampi(echo_index, 0, 2)]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 0.52
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[key] = material
	return material


func _make_handoff_ring_material(quality: StringName) -> StandardMaterial3D:
	var color := _egg_quality_color(quality)
	color.a = 0.86
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 0.78
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.resource_local_to_scene = true
	return material


func _egg_quality_color(quality: StringName) -> Color:
	return SemanticColorPaletteScript.egg_color(_normalized_quality(quality), _color_vision_mode)


func _egg_quality_material(quality: StringName) -> StandardMaterial3D:
	var normalized := _normalized_quality(quality)
	var key := "egg_quality_%s_%s" % [String(normalized), String(_color_vision_mode)]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	var body_color := SemanticColorPaletteScript.egg_color(normalized, _color_vision_mode)
	match normalized:
		&"golden":
			material.albedo_color = body_color
			material.roughness = 0.20
			material.metallic = 0.72
			material.emission_enabled = true
			material.emission = body_color
			material.emission_energy_multiplier = 0.20
		&"cracked":
			material.albedo_color = body_color
			material.roughness = 0.96
		_:
			material.albedo_color = body_color
			material.roughness = 0.78
	_material_cache[key] = material
	return material


func _build_tapered_egg_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_count := 12
	var segment_count := 18
	var bottom := Vector3(0.0, -0.5, 0.0)
	var top := Vector3(0.0, 0.5, 0.0)
	var first_ring_ratio := 1.0 / float(ring_count)
	var last_ring_ratio := float(ring_count - 1) / float(ring_count)
	for segment_index in segment_count:
		var angle0 := TAU * float(segment_index) / float(segment_count)
		var angle1 := TAU * float(segment_index + 1) / float(segment_count)
		var first0 := _egg_surface_point(first_ring_ratio, angle0)
		var first1 := _egg_surface_point(first_ring_ratio, angle1)
		for point in [bottom, first0, first1]:
			surface.add_vertex(point)

	for ring_index in range(1, ring_count - 1):
		var v0 := float(ring_index) / float(ring_count)
		var v1 := float(ring_index + 1) / float(ring_count)
		for segment_index in segment_count:
			var angle0 := TAU * float(segment_index) / float(segment_count)
			var angle1 := TAU * float(segment_index + 1) / float(segment_count)
			var p00 := _egg_surface_point(v0, angle0)
			var p01 := _egg_surface_point(v0, angle1)
			var p10 := _egg_surface_point(v1, angle0)
			var p11 := _egg_surface_point(v1, angle1)
			for point in [p00, p10, p11, p00, p11, p01]:
				surface.add_vertex(point)

	for segment_index in segment_count:
		var angle0 := TAU * float(segment_index) / float(segment_count)
		var angle1 := TAU * float(segment_index + 1) / float(segment_count)
		var last0 := _egg_surface_point(last_ring_ratio, angle0)
		var last1 := _egg_surface_point(last_ring_ratio, angle1)
		for point in [last0, top, last1]:
			surface.add_vertex(point)
	surface.generate_normals()
	surface.index()
	return surface.commit()


func _egg_surface_point(vertical_ratio: float, angle: float) -> Vector3:
	var y := lerpf(-0.5, 0.5, vertical_ratio)
	var roundness := pow(maxf(0.0, sin(PI * vertical_ratio)), 0.78)
	var lower_bulge := 1.08 - vertical_ratio * 0.23
	var radius := 0.5 * roundness * lower_bulge
	return Vector3(cos(angle) * radius, y, sin(angle) * radius)


## Number of real, retained eggs currently occupying the physical clutch.
## Exposed for focused presentation tests and accessibility telemetry.
func visible_clutch_count() -> int:
	_cleanup_invalid_settled_eggs()
	return _settled_clutch_eggs.size()


func visible_clutch_quality_count(quality: StringName) -> int:
	_cleanup_invalid_settled_eggs()
	var normalized := _normalized_quality(quality)
	var count := 0
	for egg in _settled_clutch_eggs:
		if StringName(egg.get_meta("clutch_quality", &"sound")) == normalized:
			count += 1
	return count


func clutch_surplus_count() -> int:
	return maxi(0, _desired_clutch_total() - MAX_VISIBLE_CLUTCH_EGGS)


func _reconcile_clutch_from_snapshot(snapshot: Dictionary) -> void:
	if _clutch_slots.is_empty():
		return
	var source := _authoritative_clutch_source(snapshot)
	var display_day := int(source.get("day", int(snapshot.get("day", 1))))
	if display_day != _displayed_clutch_day:
		_clear_settled_clutch()
		_displayed_clutch_day = display_day

	_desired_clutch_counts = {
		&"sound": maxi(0, int(source.get("sound", 0))),
		&"golden": maxi(0, int(source.get("golden", 0))),
		&"cracked": maxi(0, int(source.get("cracked", 0))),
	}
	var pending_counts := _animated_quality_counts()
	var target_counts := _target_settled_counts(_desired_clutch_counts, pending_counts)
	_reconcile_settled_counts(target_counts)
	_update_surplus_marker(clutch_surplus_count())


func _authoritative_clutch_source(snapshot: Dictionary) -> Dictionary:
	var current_day := maxi(1, int(snapshot.get("day", 1)))
	var eggs := maxi(0, int(snapshot.get("eggs_today", 0)))
	var cracked := clampi(int(snapshot.get("cracked_today", 0)), 0, eggs)
	var golden := clampi(int(snapshot.get("golden_today", 0)), 0, eggs - cracked)
	var phase := int(snapshot.get("shift_phase", -1))

	# DepartmentSimulation advances its calendar before opening REVIEW. The last
	# pecking order is therefore the authoritative completed clutch during review
	# and lets a reloaded save reconstruct the basket instead of displaying zero.
	if phase == REVIEW_SHIFT_PHASE and eggs == 0:
		var review_day := maxi(0, int(snapshot.get("last_pecking_order_day", 0)))
		var review_order: Array = snapshot.get("last_pecking_order", []) as Array
		if review_day > 0 and not review_order.is_empty():
			eggs = 0
			cracked = 0
			golden = 0
			for row_value in review_order:
				if row_value is not Dictionary:
					continue
				var row := row_value as Dictionary
				eggs += maxi(0, int(row.get("eggs", 0)))
				cracked += maxi(0, int(row.get("cracked", 0)))
				golden += maxi(0, int(row.get("golden", 0)))
			cracked = mini(cracked, eggs)
			golden = mini(golden, maxi(0, eggs - cracked))
			current_day = review_day

	return {
		"day": current_day,
		"sound": maxi(0, eggs - cracked - golden),
		"golden": golden,
		"cracked": cracked,
	}


func _animated_quality_counts() -> Dictionary:
	var counts := {&"sound": 0, &"golden": 0, &"cracked": 0}
	for egg in _animated_eggs.duplicate():
		if not is_instance_valid(egg):
			_animated_eggs.erase(egg)
			continue
		var quality := _normalized_quality(StringName(egg.get_meta("clutch_quality", &"sound")))
		counts[quality] = int(counts.get(quality, 0)) + 1
	return counts


func _target_settled_counts(desired: Dictionary, pending: Dictionary) -> Dictionary:
	var pending_total := 0
	for quality in [&"sound", &"golden", &"cracked"]:
		pending_total += maxi(0, int(pending.get(quality, 0)))
	var budget := maxi(0, MAX_VISIBLE_CLUTCH_EGGS - mini(pending_total, MAX_VISIBLE_CLUTCH_EGGS))
	var target := {&"sound": 0, &"golden": 0, &"cracked": 0}
	# Preserve rare outcomes when the physical containers are full. Pending eggs
	# reserve a slot so snapshot reconciliation cannot pre-spawn their duplicate.
	for quality in [&"golden", &"cracked", &"sound"]:
		var available := maxi(0, int(desired.get(quality, 0)) - int(pending.get(quality, 0)))
		var accepted := mini(available, budget)
		target[quality] = accepted
		budget -= accepted
	return target


func _reconcile_settled_counts(target: Dictionary) -> void:
	_cleanup_invalid_settled_eggs()
	var current := _settled_quality_counts()
	for quality in [&"sound", &"cracked", &"golden"]:
		var excess := maxi(0, int(current.get(quality, 0)) - int(target.get(quality, 0)))
		_remove_settled_quality(quality, excess)
	current = _settled_quality_counts()
	for quality in [&"sound", &"cracked", &"golden"]:
		var missing := maxi(0, int(target.get(quality, 0)) - int(current.get(quality, 0)))
		for _egg_index in missing:
			_spawn_reconstructed_egg(quality)


func _settled_quality_counts() -> Dictionary:
	var counts := {&"sound": 0, &"golden": 0, &"cracked": 0}
	for egg in _settled_clutch_eggs:
		var quality := _normalized_quality(StringName(egg.get_meta("clutch_quality", &"sound")))
		counts[quality] = int(counts.get(quality, 0)) + 1
	return counts


func _remove_settled_quality(quality: StringName, count: int) -> void:
	var remaining := count
	for egg_index in range(_settled_clutch_eggs.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var egg := _settled_clutch_eggs[egg_index]
		if StringName(egg.get_meta("clutch_quality", &"sound")) != quality:
			continue
		var slot_index := int(egg.get_meta("clutch_slot", -1))
		_set_slot_occupied(slot_index, false)
		_settled_clutch_eggs.remove_at(egg_index)
		if is_instance_valid(egg):
			egg.queue_free()
		remaining -= 1


func _spawn_reconstructed_egg(quality: StringName) -> void:
	var slot_index := _next_open_clutch_slot()
	if slot_index < 0:
		return
	var slot := _clutch_slots[slot_index]
	var target_root := slot.get_parent() as Node3D
	if target_root == null:
		return
	var egg := MeshInstance3D.new()
	target_root.add_child(egg)
	_configure_settled_egg(egg, quality, slot_index)
	egg.position = slot.position
	egg.rotation = Vector3(0.0, float(slot_index) * 0.43, 0.0)
	_settled_clutch_eggs.append(egg)
	_set_slot_occupied(slot_index, true)


func _settle_real_egg(egg: Node3D, quality: StringName) -> bool:
	_cleanup_invalid_settled_eggs()
	var slot_index := _next_open_clutch_slot()
	if slot_index < 0 or egg == null or not is_instance_valid(egg):
		return false
	var slot := _clutch_slots[slot_index]
	var target_root := slot.get_parent() as Node3D
	if target_root == null:
		return false
	if egg.get_parent() != target_root:
		egg.reparent(target_root, true)
	_configure_settled_egg(egg, quality, slot_index)
	_settled_clutch_eggs.append(egg)
	_set_slot_occupied(slot_index, true)

	var target := slot.position
	var rest_scale := Vector3(0.26, 0.36, 0.26)
	egg.rotation = Vector3(0.0, float(slot_index) * 0.43, 0.0)
	var landing := create_tween().bind_node(egg)
	landing.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	landing.tween_property(egg, "position", target + Vector3.UP * 0.015, 0.11)
	landing.parallel().tween_property(egg, "scale", rest_scale * Vector3(1.18, 0.64, 1.18), 0.11)
	landing.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	landing.tween_property(egg, "position", target + Vector3.UP * 0.095, 0.09)
	landing.parallel().tween_property(egg, "scale", rest_scale * 1.08, 0.09)
	landing.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	landing.tween_property(egg, "position", target, 0.10)
	landing.parallel().tween_property(egg, "scale", rest_scale, 0.10)
	_pulse_clutch_recoil(target_root, slot_index)
	return true


func _configure_settled_egg(egg: Node3D, quality: StringName, slot_index: int) -> void:
	var normalized := _normalized_quality(quality)
	egg.name = "SettledClutchEgg_%02d_%s" % [slot_index, String(normalized)]
	egg.set_meta("clutch_quality", normalized)
	egg.set_meta("clutch_slot", slot_index)
	egg.scale = Vector3(0.26, 0.36, 0.26)
	_apply_egg_quality_visual(egg, normalized, false)


func _next_open_clutch_slot() -> int:
	var occupied: Dictionary[int, bool] = {}
	for egg in _settled_clutch_eggs:
		occupied[int(egg.get_meta("clutch_slot", -1))] = true
	for slot_index in _clutch_slots.size():
		if not occupied.has(slot_index):
			return slot_index
	return -1


func _set_slot_occupied(slot_index: int, occupied: bool) -> void:
	if slot_index < 0 or slot_index >= _clutch_slot_markers.size():
		return
	var marker: Dictionary = _clutch_slot_markers[slot_index]
	var batch := marker.get("batch") as MultiMeshInstance3D
	if batch == null or not is_instance_valid(batch) or batch.multimesh == null:
		return
	marker["occupied"] = occupied
	var visible_index := 0
	for candidate_marker: Dictionary in _clutch_slot_markers:
		if candidate_marker.get("batch") != batch or bool(candidate_marker.get("occupied", false)):
			continue
		var rest_transform: Transform3D = candidate_marker.get("rest_transform", Transform3D.IDENTITY)
		batch.multimesh.set_instance_transform(visible_index, rest_transform)
		visible_index += 1
	batch.multimesh.visible_instance_count = visible_index


func _pulse_clutch_recoil(target_root: Node3D, slot_index: int) -> void:
	if target_root == null:
		return
	var root_id := target_root.get_instance_id()
	var previous := _clutch_recoil_tweens.get(root_id) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	target_root.rotation.z = 0.0
	target_root.scale = Vector3.ONE
	var direction := -1.0 if slot_index % 2 == 0 else 1.0
	var recoil := create_tween().bind_node(target_root).set_parallel(true)
	recoil.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	recoil.tween_property(target_root, "rotation:z", deg_to_rad(1.85) * direction, 0.055)
	recoil.tween_property(target_root, "scale", Vector3(1.028, 0.982, 1.028), 0.055)
	recoil.chain()
	recoil.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	recoil.tween_property(target_root, "rotation:z", 0.0, 0.16)
	recoil.tween_property(target_root, "scale", Vector3.ONE, 0.16)
	_clutch_recoil_tweens[root_id] = recoil


func _cleanup_invalid_settled_eggs() -> void:
	for egg in _settled_clutch_eggs.duplicate():
		if not is_instance_valid(egg):
			_settled_clutch_eggs.erase(egg)


func _clear_settled_clutch() -> void:
	for recoil_value in _clutch_recoil_tweens.values():
		var recoil := recoil_value as Tween
		if recoil != null and recoil.is_valid():
			recoil.kill()
	_clutch_recoil_tweens.clear()
	for egg in _settled_clutch_eggs:
		if is_instance_valid(egg):
			egg.queue_free()
	_settled_clutch_eggs.clear()
	for slot_index in _clutch_slot_markers.size():
		_set_slot_occupied(slot_index, false)
	if _presentation_clutch_root != null:
		_presentation_clutch_root.rotation = Vector3.ZERO
		_presentation_clutch_root.scale = Vector3.ONE
	if _cart_clutch_root != null:
		_cart_clutch_root.rotation = Vector3.ZERO
		_cart_clutch_root.scale = Vector3.ONE


func _desired_clutch_total() -> int:
	return (
		maxi(0, int(_desired_clutch_counts.get(&"sound", 0)))
		+ maxi(0, int(_desired_clutch_counts.get(&"golden", 0)))
		+ maxi(0, int(_desired_clutch_counts.get(&"cracked", 0)))
	)


func _update_surplus_marker(surplus: int) -> void:
	if _surplus_marker_root == null or not is_instance_valid(_surplus_marker_root):
		return
	_surplus_marker_root.visible = surplus > 0
	if _surplus_label != null:
		_surplus_label.text = "SURPLUS  +%02d" % maxi(0, surplus)
		EnvironmentalSignageScript.refit_label(_surplus_label)


func _sorting_gate_center() -> Vector3:
	return Vector3(
		SIDE_MANIFOLD_X,
		2.48,
		_presentation_position.z + SORTER_OFFSET_FROM_PRESENTATION_Z
	)


func _pulse_quality_lamp(quality: StringName) -> void:
	var lamp := _quality_lamps.get(quality) as MeshInstance3D
	var material := _quality_lamp_materials.get(quality) as StandardMaterial3D
	if lamp == null or material == null or not is_instance_valid(lamp):
		return
	var previous_tween := _quality_lamp_tweens.get(quality) as Tween
	if previous_tween != null and previous_tween.is_valid():
		previous_tween.kill()
	material.emission_energy_multiplier = SORTER_LAMP_IDLE_ENERGY
	var tween := create_tween().bind_node(lamp)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "emission_energy_multiplier", 2.25, 0.08)
	tween.tween_interval(0.16)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(material, "emission_energy_multiplier", SORTER_LAMP_IDLE_ENERGY, 0.36)
	_quality_lamp_tweens[quality] = tween


func _enqueue_grading_receipt(
	quality: StringName,
	value_cents: int,
	streak_bonus_cents: int,
	worker_id: int = -1
) -> void:
	var request := {
		"quality": quality,
		"value_cents": value_cents,
		"streak_bonus_cents": streak_bonus_cents,
		"worker_id": worker_id,
	}
	var open_slot := _first_open_receipt_slot()
	if open_slot >= 0:
		_spawn_grading_receipt(open_slot, request)
		return
	if _grading_receipt_queue.size() >= GRADING_RECEIPT_QUEUE_LIMIT:
		_grading_receipt_queue.pop_front()
	_grading_receipt_queue.append(request)


func _first_open_receipt_slot() -> int:
	for slot_index in _grading_receipt_slots.size():
		var receipt := _grading_receipt_slots[slot_index] as Node3D
		if receipt == null or not is_instance_valid(receipt):
			return slot_index
	return -1


func _spawn_grading_receipt(slot_index: int, request: Dictionary) -> void:
	if egg_collection_root == null or not is_instance_valid(egg_collection_root):
		return
	if slot_index < 0 or slot_index >= _grading_receipt_slots.size():
		return
	var quality := _normalized_quality(StringName(request.get("quality", &"sound")))
	var value_cents := maxi(0, int(request.get("value_cents", 0)))
	var streak_bonus_cents := maxi(0, int(request.get("streak_bonus_cents", 0)))
	var worker_id := int(request.get("worker_id", -1))
	var base_value_cents := maxi(0, value_cents - streak_bonus_cents)
	var quality_color := SemanticColorPaletteScript.quality_color(quality, _color_vision_mode)
	var receipt := Node3D.new()
	receipt.name = "GradingReceipt_%d" % slot_index
	var receipt_rest_position := _sorting_gate_center() + Vector3(
		-0.62,
		-0.12 + slot_index * GRADING_RECEIPT_SLOT_SPACING,
		0.385
	)
	# The receipt pivots at its top edge so it visibly feeds from the fixed slot.
	receipt.position = receipt_rest_position
	receipt.scale = Vector3(1.0, 0.10, 1.0)
	egg_collection_root.add_child(receipt)
	_grading_receipt_slots[slot_index] = receipt

	_add_box(
		receipt,
		"ReceiptShadow",
		Vector3(0.48, 0.35, 0.016),
		Vector3(0.012, -0.172, -0.010),
		Color("20282b"),
		0.94
	)
	_add_box(
		receipt,
		"ReceiptBackplate",
		Vector3(0.48, 0.050, 0.024),
		Vector3(0.0, -0.020, 0.002),
		Color("304047"),
		0.58
	)
	_add_box(
		receipt,
		"ReceiptPaper",
		Vector3(0.46, 0.33, 0.012),
		Vector3(0.0, -0.165, 0.016),
		Color("ddd5ba"),
		0.98
	)
	_add_box(
		receipt,
		"ReceiptQualityStripe",
		Vector3(0.025, 0.27, 0.008),
		Vector3(-0.205, -0.165, 0.026),
		quality_color,
		0.76
	)
	_add_box(
		receipt,
		"ReceiptTearBar",
		Vector3(0.40, 0.018, 0.014),
		Vector3(0.0, -0.323, 0.027),
		Color("8c8b7c"),
		0.44,
		0.30
	)
	# Retain the established part names as small, connected feed guides.
	_add_box(
		receipt,
		"ReceiptMountArm",
		Vector3(0.10, 0.035, 0.030),
		Vector3(0.17, -0.020, -0.004),
		Color("56666a"),
		0.40,
		0.35
	)
	_add_box(
		receipt,
		"ReceiptMountHinge",
		Vector3(0.055, 0.055, 0.040),
		Vector3(0.215, -0.020, -0.004),
		Color("b08a4d"),
		0.32,
		0.52
	)

	var receipt_text := SemanticColorPaletteScript.marked_quality_name(
		String(quality).to_upper(),
		quality,
		_color_vision_mode,
	)
	if value_cents > 0:
		receipt_text += "  $%.2f" % (base_value_cents / 100.0)
	if streak_bonus_cents > 0:
		receipt_text += "\n+$%.2f clean-clutch" % (streak_bonus_cents / 100.0)
	if worker_id >= 0:
		var worker_name := String(_worker_names.get(worker_id, "HEN %d" % (worker_id + 1))).to_upper()
		receipt_text += "\nLAID BY %s  /  CREDIT TO FARMER" % worker_name
	var label := Label3D.new()
	label.name = "ReceiptText"
	label.text = receipt_text
	label.position = Vector3(0.025, -0.165, 0.032)
	label.font_size = 14 if worker_id >= 0 else 16
	label.pixel_size = 0.0021
	label.width = 185
	label.line_spacing = -2
	label.outline_size = 0
	label.modulate = quality_color.darkened(0.42)
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.no_depth_test = false
	label.fixed_size = false
	label.shaded = true
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	EnvironmentalSignageScript.apply_house_type(label, &"paper_notice", true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	receipt.add_child(label)

	var tween := create_tween().bind_node(receipt)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(receipt, "scale", Vector3.ONE, 0.18)
	tween.tween_interval(1.22)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(receipt, "scale:y", 0.10, 0.28)
	tween.tween_callback(_finish_grading_receipt.bind(receipt, slot_index))


func _finish_grading_receipt(receipt: Node3D, slot_index: int) -> void:
	if slot_index >= 0 and slot_index < _grading_receipt_slots.size():
		if _grading_receipt_slots[slot_index] == receipt:
			_grading_receipt_slots[slot_index] = null
	if receipt != null and is_instance_valid(receipt):
		# Release the public slot name before a queued docket is added in the same
		# frame; otherwise Godot gives the successor an opaque duplicate name.
		receipt.name = "RetiringGradingReceipt_%d" % slot_index
		receipt.queue_free()
	if not _grading_receipt_queue.is_empty():
		var next_request: Dictionary = _grading_receipt_queue.pop_front()
		_spawn_grading_receipt(slot_index, next_request)


func _desk_index_for_worker(worker_id: int) -> int:
	if _worker_to_desk.has(worker_id):
		return _worker_to_desk[worker_id]
	# Current simulation IDs are one-based; this fallback keeps the module useful
	# before the first snapshot arrives without silently accepting a bad index.
	var fallback := worker_id - 1
	return fallback if fallback >= 0 and fallback < _desk_positions.size() else -1


func _campus_presentation_source(snapshot: Dictionary) -> Dictionary:
	var source: Dictionary = {}
	for key: String in [
		"day",
		"owned_facilities",
		"facility_catalog",
		"pinned_capital_plan_id",
		"capital_plan",
		"contract_board",
		"campus_expansion",
		"campus_portfolio",
	]:
		if not snapshot.has(key):
			continue
		var value: Variant = snapshot.get(key)
		if value is Dictionary:
			source[key] = (value as Dictionary).duplicate(true)
		elif value is Array:
			source[key] = (value as Array).duplicate(true)
		else:
			source[key] = value
	return source


func _rebuild_campus_presentation() -> void:
	var source := _last_campus_presentation_source
	var options := _last_campus_presentation_options
	var entries: Dictionary = {}
	var offered_ids := _presentation_id_set(options.get("offered_ids", []))
	var facility_records := _presentation_records_by_id(source.get("facility_catalog", []), "id")
	var owned_value: Variant = source.get("owned_facilities", {})
	var owned_facilities := owned_value as Dictionary if owned_value is Dictionary else {}
	var pinned_id := _presentation_pinned_facility_id(source)

	for facility_id: StringName in CAMPUS_PRESENTATION_FACILITY_ORDER:
		var facility := facility_records.get(facility_id, {}) as Dictionary
		var owned_level := _presentation_level(owned_facilities.get(
			facility_id,
			owned_facilities.get(String(facility_id), 0),
		))
		var catalog_level := _presentation_level(facility.get(
			"level",
			facility.get("owned_level", 1 if bool(facility.get("installed", false)) else 0),
		))
		var owned := (
			maxi(owned_level, catalog_level) > 0
			or bool(facility.get("owned", facility.get("installed", false)))
		)
		var offered := (
			bool(facility.get(
				"unlocked",
				facility.get("available", facility.get("can_purchase", false)),
			))
			or offered_ids.has(facility_id)
		)
		var state := CAMPUS_PRESENTATION_HIDDEN
		if owned:
			state = CAMPUS_PRESENTATION_OWNED
		elif pinned_id == facility_id:
			state = CAMPUS_PRESENTATION_PINNED
		elif offered:
			state = CAMPUS_PRESENTATION_OFFERED
		entries[facility_id] = _campus_presentation_entry(
			facility_id,
			state,
			_facility_root_name(facility_id),
			_facility_footprint(facility_id),
			&"facility",
			int(facility.get("unlock_day", facility.get("next_unlock_day", 0))),
		)

	var contract_board_value: Variant = source.get("contract_board", {})
	var contract_board := contract_board_value as Dictionary if contract_board_value is Dictionary else {}
	var active_contract_value: Variant = contract_board.get(
		"active_contract",
		contract_board.get("active", {}),
	)
	var contract_active := active_contract_value is Dictionary and not (active_contract_value as Dictionary).is_empty()
	var contract_offered := (
		bool(contract_board.get("unlocked", false))
		or contract_active
		or int(contract_board.get("contracts_signed_total", 0)) > 0
		or offered_ids.has(FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID)
	)
	entries[FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID] = _campus_presentation_entry(
		FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID,
		CAMPUS_PRESENTATION_OFFERED if contract_offered else CAMPUS_PRESENTATION_HIDDEN,
		"FarmMutualContractBoardVisual",
		FarmMutualContractBoardVisualScript.declared_footprint(),
		&"governance",
		int(contract_board.get("unlock_day", 0)),
	)

	var expansion_value: Variant = source.get("campus_expansion", {})
	var expansion := expansion_value as Dictionary if expansion_value is Dictionary else {}
	var north_parcel_value: Variant = expansion.get("parcel", {})
	var north_parcel := north_parcel_value as Dictionary if north_parcel_value is Dictionary else {}
	var north_owned := bool(expansion.get(
		"parcel_owned",
		north_parcel.get("owned", false),
	))
	var north_offered := (
		bool(expansion.get("access_gate_met", false))
		or bool(north_parcel.get("can_purchase", false))
		or offered_ids.has(NORTH_MEADOW_PRESENTATION_ID)
	)
	var north_state := CAMPUS_PRESENTATION_HIDDEN
	if north_owned:
		north_state = CAMPUS_PRESENTATION_OWNED
	elif north_offered:
		north_state = CAMPUS_PRESENTATION_OFFERED
	entries[NORTH_MEADOW_PRESENTATION_ID] = _campus_presentation_entry(
		NORTH_MEADOW_PRESENTATION_ID,
		north_state,
		"CampusExpansionVisual",
		CampusExpansionVisualScript.declared_footprint(),
		&"parcel",
		int(expansion.get("unlock_day", 0)),
	)

	var portfolio_value: Variant = source.get("campus_portfolio", {})
	var portfolio := portfolio_value as Dictionary if portfolio_value is Dictionary else {}
	var parcel_records := _presentation_records_by_id(portfolio.get("parcels", []), "id")
	var current_day := int(source.get("day", portfolio.get("current_day", 1)))
	var any_portfolio_owned := false
	for parcel_id: StringName in [ORCHARD_ROW_PRESENTATION_ID, CREEKSIDE_YARD_PRESENTATION_ID]:
		var parcel := parcel_records.get(parcel_id, {}) as Dictionary
		var parcel_owned := _presentation_parcel_owned(parcel)
		any_portfolio_owned = any_portfolio_owned or parcel_owned
		var unlock_day := int(parcel.get("unlock_day", 0))
		var parcel_offered := (
			not parcel.is_empty()
			and (
				bool(parcel.get("can_purchase", false))
				or (unlock_day > 0 and current_day >= unlock_day)
			)
		) or offered_ids.has(parcel_id)
		var parcel_state := CAMPUS_PRESENTATION_HIDDEN
		if parcel_owned:
			parcel_state = CAMPUS_PRESENTATION_OWNED
		elif parcel_offered:
			parcel_state = CAMPUS_PRESENTATION_OFFERED
		entries[parcel_id] = _campus_presentation_entry(
			parcel_id,
			parcel_state,
			"%sParcel" % String(parcel_id).to_pascal_case(),
			CampusPortfolioVisualScript.declared_footprint(parcel_id),
			&"parcel",
			unlock_day,
		)

	var teaser_id := _select_campus_teaser(entries, current_day, options)
	if teaser_id != &"":
		var teaser := (entries.get(teaser_id, {}) as Dictionary).duplicate(true)
		teaser["state"] = CAMPUS_PRESENTATION_TEASED
		teaser["visible"] = true
		entries[teaser_id] = teaser

	entries[CARE_CAMPUS_SPINE_PRESENTATION_ID] = _campus_presentation_entry(
		CARE_CAMPUS_SPINE_PRESENTATION_ID,
		_presentation_support_state(entries, CARE_CAMPUS_FACILITY_IDS),
		"CareCampusSpine",
		_care_spine_presentation_footprint(entries),
		&"infrastructure",
	)
	entries[OPERATIONS_CAMPUS_SPINE_PRESENTATION_ID] = _campus_presentation_entry(
		OPERATIONS_CAMPUS_SPINE_PRESENTATION_ID,
		_presentation_support_state(entries, OPERATIONS_CAMPUS_FACILITY_IDS),
		"OperationsCampusSpine",
		_operations_spine_presentation_footprint(entries),
		&"infrastructure",
	)
	var trunk_developed := any_portfolio_owned or _portfolio_has_development(portfolio)
	entries[PORTFOLIO_SERVICE_TRUNK_PRESENTATION_ID] = _campus_presentation_entry(
		PORTFOLIO_SERVICE_TRUNK_PRESENTATION_ID,
		CAMPUS_PRESENTATION_OWNED if trunk_developed else CAMPUS_PRESENTATION_HIDDEN,
		"PortfolioSharedInfrastructure",
		CampusPortfolioVisualScript.protected_trunk_footprint(),
		&"infrastructure",
	)

	_apply_campus_presentation_entries(entries)
	var visible_ids: Array[StringName] = []
	var visible_footprints: Array[Rect2] = []
	var has_bounds := false
	var bounds := Rect2()
	for presentation_id: StringName in _campus_presentation_entry_order():
		var entry := entries.get(presentation_id, {}) as Dictionary
		if not bool(entry.get("visible", false)):
			continue
		# On constrained Web runtimes, teased and generally available projects
		# stay in the planning/read-model layer. Mounting several multi-room
		# facilities as soon as their catalog cards unlock caused Day 3 to sprawl
		# and allocated tens of megabytes before the player chose a project.
		# Pinning or owning a site still makes its finished art physical immediately.
		if (
			_lazy_hidden_optional_visuals
			and StringName(String(entry.get("state", CAMPUS_PRESENTATION_HIDDEN))) in [
				CAMPUS_PRESENTATION_TEASED,
				CAMPUS_PRESENTATION_OFFERED,
			]
		):
			continue
		visible_ids.append(presentation_id)
		var footprint := entry.get("footprint", Rect2()) as Rect2
		if footprint.size.x <= 0.0 or footprint.size.y <= 0.0:
			continue
		if footprint not in visible_footprints:
			visible_footprints.append(footprint)
		bounds = bounds.merge(footprint) if has_bounds else footprint
		has_bounds = true
	_visible_campus_footprints = visible_footprints
	_visible_campus_bounds = bounds if has_bounds else Rect2()
	_campus_presentation = {
		"entries_by_id": entries.duplicate(true),
		"visible_ids": visible_ids.duplicate(),
		"teaser_id": teaser_id,
		"visible_footprints": visible_footprints.duplicate(),
		"visible_bounds": _visible_campus_bounds,
	}


func _campus_presentation_entry(
		presentation_id: StringName,
		state: StringName,
		root_name: String,
		footprint: Rect2,
		category: StringName,
		unlock_day: int = 0,
) -> Dictionary:
	return {
		"id": presentation_id,
		"state": state,
		"visible": state != CAMPUS_PRESENTATION_HIDDEN,
		"root_name": root_name,
		"footprint": footprint,
		"category": category,
		"unlock_day": maxi(0, unlock_day),
	}


func _select_campus_teaser(
		entries: Dictionary,
		current_day: int,
		options: Dictionary,
) -> StringName:
	var explicit_id := StringName(String(options.get("teaser_id", "")))
	if explicit_id != &"" and entries.has(explicit_id):
		var explicit_entry := entries.get(explicit_id, {}) as Dictionary
		if StringName(String(explicit_entry.get("state", CAMPUS_PRESENTATION_HIDDEN))) == CAMPUS_PRESENTATION_HIDDEN:
			return explicit_id
	if not bool(options.get("show_next_teaser", false)):
		return &""
	var window_days := clampi(int(options.get("teaser_window_days", 1)), 0, 30)
	var selected_id: StringName = &""
	var selected_day := 2_147_483_647
	for candidate_id: StringName in CAMPUS_PRESENTATION_TEASER_ORDER:
		var entry := entries.get(candidate_id, {}) as Dictionary
		if StringName(String(entry.get("state", CAMPUS_PRESENTATION_HIDDEN))) != CAMPUS_PRESENTATION_HIDDEN:
			continue
		var unlock_day := int(entry.get("unlock_day", 0))
		if unlock_day <= current_day or unlock_day > current_day + window_days:
			continue
		if unlock_day < selected_day:
			selected_day = unlock_day
			selected_id = candidate_id
	return selected_id


func _presentation_support_state(entries: Dictionary, served_ids: Array[StringName]) -> StringName:
	for candidate_state: StringName in [
		CAMPUS_PRESENTATION_OWNED,
		CAMPUS_PRESENTATION_PINNED,
		CAMPUS_PRESENTATION_OFFERED,
	]:
		for presentation_id: StringName in served_ids:
			var entry := entries.get(presentation_id, {}) as Dictionary
			if StringName(String(entry.get("state", CAMPUS_PRESENTATION_HIDDEN))) == candidate_state:
				return candidate_state
	return CAMPUS_PRESENTATION_HIDDEN


func _care_spine_presentation_footprint(entries: Dictionary) -> Rect2:
	var first_state := _presentation_support_state(entries, CARE_CAMPUS_FACILITY_IDS)
	if first_state == CAMPUS_PRESENTATION_HIDDEN:
		return Rect2()
	var second_state := _presentation_support_state(entries, [
		TRAINING_ROOST_ID,
		FARMER_RELATIONS_GALLERY_ID,
	])
	return (
		CARE_CAMPUS_SPINE_FOOTPRINT
		if second_state != CAMPUS_PRESENTATION_HIDDEN else
		CARE_CAMPUS_FIRST_BAY_FOOTPRINT
	)


func _operations_spine_presentation_footprint(entries: Dictionary) -> Rect2:
	var first_state := _presentation_support_state(entries, OPERATIONS_CAMPUS_FACILITY_IDS)
	if first_state == CAMPUS_PRESENTATION_HIDDEN:
		return Rect2()
	var second_state := _presentation_support_state(entries, [
		IT_COOP_ID,
		FLOCK_RELATIONS_OFFICE_ID,
	])
	return (
		OPERATIONS_CAMPUS_SPINE_FOOTPRINT
		if second_state != CAMPUS_PRESENTATION_HIDDEN else
		OPERATIONS_CAMPUS_FIRST_BAY_FOOTPRINT
	)


func _apply_campus_presentation_entries(entries: Dictionary) -> void:
	for facility_id: StringName in CAMPUS_PRESENTATION_FACILITY_ORDER:
		_apply_presentation_to_root(
			_facility_root(facility_id),
			facility_id,
			_entry_presentation_state(entries, facility_id),
		)
	_apply_presentation_to_root(
		farm_mutual_contract_board_visual,
		FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID,
		_entry_presentation_state(entries, FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID),
	)
	_apply_presentation_to_root(
		care_campus_spine_root,
		CARE_CAMPUS_SPINE_PRESENTATION_ID,
		_entry_presentation_state(entries, CARE_CAMPUS_SPINE_PRESENTATION_ID),
	)
	var care_first_state := _presentation_support_state(entries, CARE_CAMPUS_FACILITY_IDS)
	var care_second_state := _presentation_support_state(entries, [
		TRAINING_ROOST_ID,
		FARMER_RELATIONS_GALLERY_ID,
	])
	_apply_presentation_to_root(care_campus_first_bay_root, &"care_campus_first_bay", care_first_state)
	_apply_presentation_to_root(care_campus_second_bay_root, &"care_campus_second_bay", care_second_state)
	_apply_presentation_to_root(
		operations_campus_spine_root,
		OPERATIONS_CAMPUS_SPINE_PRESENTATION_ID,
		_entry_presentation_state(entries, OPERATIONS_CAMPUS_SPINE_PRESENTATION_ID),
	)
	var operations_first_state := _presentation_support_state(entries, OPERATIONS_CAMPUS_FACILITY_IDS)
	var operations_second_state := _presentation_support_state(entries, [
		IT_COOP_ID,
		FLOCK_RELATIONS_OFFICE_ID,
	])
	_apply_presentation_to_root(
		operations_campus_first_bay_root,
		&"operations_campus_first_bay",
		operations_first_state,
	)
	_apply_presentation_to_root(
		operations_campus_second_bay_root,
		&"operations_campus_second_bay",
		operations_second_state,
	)
	_apply_presentation_to_root(
		campus_expansion_visual,
		NORTH_MEADOW_PRESENTATION_ID,
		_entry_presentation_state(entries, NORTH_MEADOW_PRESENTATION_ID),
	)

	var orchard_state := _entry_presentation_state(entries, ORCHARD_ROW_PRESENTATION_ID)
	var creekside_state := _entry_presentation_state(entries, CREEKSIDE_YARD_PRESENTATION_ID)
	var trunk_state := _entry_presentation_state(entries, PORTFOLIO_SERVICE_TRUNK_PRESENTATION_ID)
	if campus_portfolio_visual != null and is_instance_valid(campus_portfolio_visual):
		var orchard_root := campus_portfolio_visual.find_child("OrchardRowParcel", true, false) as Node3D
		var creekside_root := campus_portfolio_visual.find_child("CreeksideYardParcel", true, false) as Node3D
		var trunk_root := campus_portfolio_visual.find_child("PortfolioSharedInfrastructure", true, false) as Node3D
		_apply_presentation_to_root(orchard_root, ORCHARD_ROW_PRESENTATION_ID, orchard_state)
		_apply_presentation_to_root(creekside_root, CREEKSIDE_YARD_PRESENTATION_ID, creekside_state)
		_apply_presentation_to_root(trunk_root, PORTFOLIO_SERVICE_TRUNK_PRESENTATION_ID, trunk_state)
		var portfolio_state := _strongest_presentation_state([
			orchard_state,
			creekside_state,
			trunk_state,
		])
		_apply_presentation_to_root(campus_portfolio_visual, &"campus_portfolio", portfolio_state)


func _apply_presentation_to_root(
		root_node: Node3D,
		presentation_id: StringName,
		state: StringName,
) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	root_node.visible = state != CAMPUS_PRESENTATION_HIDDEN
	root_node.set_meta(&"presentation_id", presentation_id)
	root_node.set_meta(&"presentation_state", state)
	root_node.set_meta(&"presentation_visible", root_node.visible)


func _entry_presentation_state(entries: Dictionary, presentation_id: StringName) -> StringName:
	var entry := entries.get(presentation_id, {}) as Dictionary
	return StringName(String(entry.get("state", CAMPUS_PRESENTATION_HIDDEN)))


func _strongest_presentation_state(states: Array[StringName]) -> StringName:
	for candidate: StringName in [
		CAMPUS_PRESENTATION_OWNED,
		CAMPUS_PRESENTATION_PINNED,
		CAMPUS_PRESENTATION_OFFERED,
		CAMPUS_PRESENTATION_TEASED,
	]:
		if candidate in states:
			return candidate
	return CAMPUS_PRESENTATION_HIDDEN


func _presentation_pinned_facility_id(source: Dictionary) -> StringName:
	var pinned_id := StringName(String(source.get("pinned_capital_plan_id", "")))
	if pinned_id != &"":
		return pinned_id
	var capital_value: Variant = source.get("capital_plan", {})
	if capital_value is not Dictionary:
		return &""
	var capital_plan := capital_value as Dictionary
	return StringName(String(capital_plan.get(
		"pinned_capital_plan_id",
		capital_plan.get("facility_id", capital_plan.get("pinned_facility_id", "")),
	)))


func _presentation_level(value: Variant) -> int:
	if value is Dictionary:
		var record := value as Dictionary
		return maxi(0, int(record.get(
			"level",
			record.get("owned_level", 1 if bool(record.get("installed", false)) else 0),
		)))
	if value is bool:
		return 1 if bool(value) else 0
	if value is int or value is float:
		return maxi(0, int(value))
	return 0


func _presentation_parcel_owned(parcel: Dictionary) -> bool:
	if bool(parcel.get("owned", parcel.get("parcel_owned", false))):
		return true
	return StringName(String(parcel.get("status", parcel.get("stage", ""))).to_lower()) in [
		&"owned",
		&"surveyed",
		&"building",
		&"operational",
		&"complete",
	]


func _portfolio_has_development(portfolio: Dictionary) -> bool:
	var projects_value: Variant = portfolio.get("projects", [])
	if projects_value is Array and not (projects_value as Array).is_empty():
		return true
	if projects_value is Dictionary and not (projects_value as Dictionary).is_empty():
		return true
	var modules_value: Variant = portfolio.get("modules", portfolio.get("module_catalog", []))
	var modules := _presentation_records_by_id(modules_value, "id")
	for module_value: Variant in modules.values():
		if module_value is Dictionary:
			var module := module_value as Dictionary
			if bool(module.get("installed", module.get("built", false))):
				return true
	return false


func _presentation_records_by_id(value: Variant, id_key: String) -> Dictionary:
	var records: Dictionary = {}
	if value is Array:
		for record_value: Variant in value as Array:
			if record_value is not Dictionary:
				continue
			var record := record_value as Dictionary
			var record_id := StringName(String(record.get(id_key, "")))
			if record_id != &"":
				records[record_id] = record.duplicate(true)
	elif value is Dictionary:
		for key: Variant in (value as Dictionary).keys():
			var record_value: Variant = (value as Dictionary).get(key)
			if record_value is not Dictionary:
				continue
			var record := (record_value as Dictionary).duplicate(true)
			if not record.has(id_key):
				record[id_key] = String(key)
			var record_id := StringName(String(record.get(id_key, "")))
			if record_id != &"":
				records[record_id] = record
	return records


func _presentation_id_set(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Array:
		for id_value: Variant in value as Array:
			var presentation_id := StringName(String(id_value))
			if presentation_id != &"":
				result[presentation_id] = true
	elif value is PackedStringArray:
		for id_value: String in value as PackedStringArray:
			var presentation_id := StringName(id_value)
			if presentation_id != &"":
				result[presentation_id] = true
	elif value is Dictionary:
		for key: Variant in (value as Dictionary).keys():
			if bool((value as Dictionary).get(key, false)):
				result[StringName(String(key))] = true
	return result


func _campus_presentation_entry_order() -> Array[StringName]:
	var order: Array[StringName] = CAMPUS_PRESENTATION_FACILITY_ORDER.duplicate()
	order.append_array([
		FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID,
		NORTH_MEADOW_PRESENTATION_ID,
		ORCHARD_ROW_PRESENTATION_ID,
		CREEKSIDE_YARD_PRESENTATION_ID,
		CARE_CAMPUS_SPINE_PRESENTATION_ID,
		OPERATIONS_CAMPUS_SPINE_PRESENTATION_ID,
		PORTFOLIO_SERVICE_TRUNK_PRESENTATION_ID,
	])
	return order


func _facility_root(facility_id: StringName) -> Node3D:
	match facility_id:
		CANDLING_REWORK_BAY_ID:
			return shell_quality_lab_visual
		PACKING_ANNEX_ID:
			return packing_annex_visual
		RECORDS_ANNEX_ID:
			return records_annex_visual
		FARM_MUTUAL_SERVICE_COOP_ID:
			return farm_mutual_service_coop_visual
		FARM_MUTUAL_NEGOTIATION_ROOM_ID:
			return farm_mutual_negotiation_room_visual
		WELLNESS_NEST_ID:
			return wellness_nest_visual
		TRAINING_ROOST_ID:
			return training_roost_visual
		ROOSTER_OPERATIONS_OFFICE_ID:
			return rooster_operations_office_visual
		IT_COOP_ID:
			return it_coop_visual
		FLOCK_RELATIONS_OFFICE_ID:
			return flock_relations_office_visual
		FEED_PROCUREMENT_COOP_ID:
			return feed_procurement_coop_visual
		FARMER_RELATIONS_GALLERY_ID:
			return farmer_relations_gallery_visual
		FARMGATE_DISPATCH_DEPOT_ID:
			return farmgate_dispatch_depot_visual
	return null


func _facility_root_name(facility_id: StringName) -> String:
	var root_node := _facility_root(facility_id)
	return String(root_node.name) if root_node != null else String(facility_id)


func _facility_footprint(facility_id: StringName) -> Rect2:
	match facility_id:
		CANDLING_REWORK_BAY_ID:
			return ShellQualityLabVisualScript.declared_footprint()
		PACKING_ANNEX_ID:
			return PackingAnnexVisualScript.declared_footprint()
		RECORDS_ANNEX_ID:
			return RecordsAnnexVisualScript.declared_footprint()
		FARM_MUTUAL_SERVICE_COOP_ID:
			return FarmMutualServiceCoopVisualScript.declared_footprint()
		FARM_MUTUAL_NEGOTIATION_ROOM_ID:
			return FarmMutualNegotiationRoomVisualScript.declared_footprint()
		WELLNESS_NEST_ID:
			return WellnessNestVisualScript.declared_footprint()
		TRAINING_ROOST_ID:
			return TrainingRoostVisualScript.declared_footprint()
		ROOSTER_OPERATIONS_OFFICE_ID:
			return RoosterOperationsOfficeVisualScript.declared_footprint()
		IT_COOP_ID:
			return ITCoopVisualScript.declared_footprint()
		FLOCK_RELATIONS_OFFICE_ID:
			return FlockRelationsOfficeVisualScript.declared_footprint()
		FEED_PROCUREMENT_COOP_ID:
			return FeedProcurementCoopVisualScript.declared_footprint()
		FARMER_RELATIONS_GALLERY_ID:
			return FarmerRelationsGalleryVisualScript.declared_footprint()
		FARMGATE_DISPATCH_DEPOT_ID:
			return FarmgateDispatchDepotVisualScript.declared_footprint()
	return Rect2()


func _build_all() -> void:
	_built = true
	_optional_visual_build_generation += 1
	_optional_visual_build_index = 0
	_optional_visual_instantiated_count = 0
	_optional_visual_built_indices.clear()
	_optional_visuals_ready = false
	_optional_visual_build_started_msec = Time.get_ticks_msec()
	_optional_visual_build_completed_msec = 0
	_optional_visual_build_timings.clear()
	_build_management_perch()
	_build_egg_collection_chain()
	_build_zone_markers()
	_build_bureau_satire()
	_build_records_and_intake_story()
	_rebuild_campus_presentation()
	_apply_office_physical_presentation_state()
	if _defer_optional_visuals and is_inside_tree():
		call_deferred(&"_build_optional_visuals_staged", _optional_visual_build_generation)
	else:
		_build_optional_visuals_immediately()
		_rebuild_campus_presentation()


func _build_optional_visuals_immediately() -> void:
	if _lazy_hidden_optional_visuals:
		_optional_visual_build_index = OPTIONAL_VISUAL_BUILD_COUNT
		_optional_visuals_ready = true
		_optional_visual_build_completed_msec = Time.get_ticks_msec()
		return
	while _optional_visual_build_index < OPTIONAL_VISUAL_BUILD_COUNT:
		_build_optional_visual(_optional_visual_build_index)
		_optional_visual_build_index += 1
	_optional_visuals_ready = true
	_optional_visual_build_completed_msec = Time.get_ticks_msec()


func _build_optional_visuals_staged(generation: int) -> void:
	# Let Office finish its UI, title card, and first diagnostic snapshot before
	# consuming another frame. Each later facility is an independent frame so a
	# mature campus never creates one multi-second main-thread stall.
	await get_tree().process_frame
	if _lazy_hidden_optional_visuals:
		if generation != _optional_visual_build_generation or not is_inside_tree():
			return
		_optional_visual_build_index = OPTIONAL_VISUAL_BUILD_COUNT
		_optional_visuals_ready = true
		_optional_visual_build_completed_msec = Time.get_ticks_msec()
		optional_visuals_finished.emit()
		return
	while (
		generation == _optional_visual_build_generation
		and is_inside_tree()
		and _optional_visual_build_index < OPTIONAL_VISUAL_BUILD_COUNT
	):
		var build_index := _optional_visual_build_index
		_build_optional_visual(build_index)
		_optional_visual_build_index += 1
		_apply_latest_snapshot_to_optional_visual(build_index)
		_rebuild_campus_presentation()
		await get_tree().process_frame
	if generation != _optional_visual_build_generation or not is_inside_tree():
		return
	_optional_visuals_ready = true
	_optional_visual_build_completed_msec = Time.get_ticks_msec()
	_apply_office_physical_presentation_state()
	optional_visuals_finished.emit()


func _build_optional_visual(build_index: int) -> void:
	if _optional_visual_built_indices.has(build_index):
		return
	var started_msec := Time.get_ticks_msec()
	var timing_name := "unknown_%d" % build_index
	match build_index:
		0:
			timing_name = "shell_quality_lab"
			_build_shell_quality_lab_visual()
		1:
			timing_name = "packing_annex"
			_build_packing_annex_visual()
		2:
			timing_name = "records_annex"
			_build_records_annex_visual()
		3:
			timing_name = "farm_mutual_service_coop"
			_build_farm_mutual_service_coop_visual()
		4:
			timing_name = "farm_mutual_negotiation_room"
			_build_farm_mutual_negotiation_room_visual()
		5:
			timing_name = "farm_mutual_contract_board"
			_build_farm_mutual_contract_board_visual()
		6:
			timing_name = "care_campus_spine"
			_build_care_campus_spine()
		7:
			timing_name = "wellness_nest"
			_build_wellness_nest_visual()
		8:
			timing_name = "training_roost"
			_build_training_roost_visual()
		9:
			timing_name = "farmer_relations_gallery"
			_build_farmer_relations_gallery_visual()
		10:
			timing_name = "operations_campus_spine"
			_build_operations_campus_spine()
		11:
			timing_name = "rooster_operations_office"
			_build_rooster_operations_office_visual()
		12:
			timing_name = "it_coop"
			_build_it_coop_visual()
		13:
			timing_name = "flock_relations_office"
			_build_flock_relations_office_visual()
		14:
			timing_name = "feed_procurement_coop"
			_build_feed_procurement_coop_visual()
		15:
			timing_name = "farmgate_dispatch_depot"
			_build_farmgate_dispatch_depot_visual()
		16:
			timing_name = "campus_expansion"
			_build_campus_expansion_visual()
		17:
			timing_name = "campus_portfolio"
			_build_campus_portfolio_visual()
	_optional_visual_build_timings[timing_name] = maxi(
		0,
		Time.get_ticks_msec() - started_msec,
	)
	_optional_visual_built_indices[build_index] = true
	_optional_visual_instantiated_count += 1


func _ensure_required_optional_visuals(snapshot: Dictionary) -> bool:
	var built_any := false
	for build_index in OPTIONAL_VISUAL_BUILD_COUNT:
		if (
			_optional_visual_built_indices.has(build_index)
			or not _optional_visual_required(build_index)
		):
			continue
		_build_optional_visual(build_index)
		_apply_latest_snapshot_to_optional_visual(build_index)
		built_any = true
	if built_any:
		_optional_visual_build_completed_msec = Time.get_ticks_msec()
		# Lazy residency can grow after the initial boot gate; republish the
		# observability signal without changing the gate's ready state.
		optional_visuals_finished.emit()
	return built_any


func _optional_visual_required(build_index: int) -> bool:
	var entries := _campus_presentation.get("entries_by_id", {}) as Dictionary
	var presentation_ids: Array[StringName] = []
	match build_index:
		0: presentation_ids = [CANDLING_REWORK_BAY_ID]
		1: presentation_ids = [PACKING_ANNEX_ID]
		2: presentation_ids = [RECORDS_ANNEX_ID]
		3: presentation_ids = [FARM_MUTUAL_SERVICE_COOP_ID]
		4: presentation_ids = [FARM_MUTUAL_NEGOTIATION_ROOM_ID]
		5: presentation_ids = [FARM_MUTUAL_CONTRACT_BOARD_PRESENTATION_ID]
		6: presentation_ids = [CARE_CAMPUS_SPINE_PRESENTATION_ID]
		7: presentation_ids = [WELLNESS_NEST_ID]
		8: presentation_ids = [TRAINING_ROOST_ID]
		9: presentation_ids = [FARMER_RELATIONS_GALLERY_ID]
		10: presentation_ids = [OPERATIONS_CAMPUS_SPINE_PRESENTATION_ID]
		11: presentation_ids = [ROOSTER_OPERATIONS_OFFICE_ID]
		12: presentation_ids = [IT_COOP_ID]
		13: presentation_ids = [FLOCK_RELATIONS_OFFICE_ID]
		14: presentation_ids = [FEED_PROCUREMENT_COOP_ID]
		15: presentation_ids = [FARMGATE_DISPATCH_DEPOT_ID]
		16: presentation_ids = [NORTH_MEADOW_PRESENTATION_ID]
		17:
			presentation_ids = [
				ORCHARD_ROW_PRESENTATION_ID,
				CREEKSIDE_YARD_PRESENTATION_ID,
				PORTFOLIO_SERVICE_TRUNK_PRESENTATION_ID,
			]
	for presentation_id: StringName in presentation_ids:
		var entry := entries.get(presentation_id, entries.get(String(presentation_id), {})) as Dictionary
		var state := StringName(String(entry.get("state", CAMPUS_PRESENTATION_HIDDEN)))
		if state in [
			CAMPUS_PRESENTATION_PINNED,
			CAMPUS_PRESENTATION_OWNED,
		]:
			return true
	return false


func _apply_latest_snapshot_to_optional_visual(build_index: int) -> void:
	if _last_snapshot.is_empty():
		return
	var root_node: Node = null
	match build_index:
		0: root_node = shell_quality_lab_visual
		1: root_node = packing_annex_visual
		2: root_node = records_annex_visual
		3: root_node = farm_mutual_service_coop_visual
		4: root_node = farm_mutual_negotiation_room_visual
		5: root_node = farm_mutual_contract_board_visual
		7: root_node = wellness_nest_visual
		8: root_node = training_roost_visual
		9: root_node = farmer_relations_gallery_visual
		11: root_node = rooster_operations_office_visual
		12: root_node = it_coop_visual
		13: root_node = flock_relations_office_visual
		14: root_node = feed_procurement_coop_visual
		15: root_node = farmgate_dispatch_depot_visual
		16: root_node = campus_expansion_visual
		17: root_node = campus_portfolio_visual
	if root_node != null and root_node.has_method(&"apply_snapshot"):
		root_node.call(&"apply_snapshot", _last_snapshot)


func _clear_built_roots() -> void:
	_optional_visual_build_generation += 1
	_clear_egg_handoff_feedback()
	for tween_value in _quality_lamp_tweens.values():
		var lamp_tween := tween_value as Tween
		if lamp_tween != null and lamp_tween.is_valid():
			lamp_tween.kill()
	for recoil_value in _clutch_recoil_tweens.values():
		var recoil := recoil_value as Tween
		if recoil != null and recoil.is_valid():
			recoil.kill()
	if shell_quality_lab_visual != null and is_instance_valid(shell_quality_lab_visual):
		shell_quality_lab_visual.clear()
	if packing_annex_visual != null and is_instance_valid(packing_annex_visual):
		packing_annex_visual.call("clear")
	if records_annex_visual != null and is_instance_valid(records_annex_visual):
		records_annex_visual.call("clear")
	if farm_mutual_service_coop_visual != null and is_instance_valid(farm_mutual_service_coop_visual):
		farm_mutual_service_coop_visual.call("clear")
	if farm_mutual_negotiation_room_visual != null and is_instance_valid(farm_mutual_negotiation_room_visual):
		farm_mutual_negotiation_room_visual.call("clear")
	if farm_mutual_contract_board_visual != null and is_instance_valid(farm_mutual_contract_board_visual):
		farm_mutual_contract_board_visual.call("clear")
	if wellness_nest_visual != null and is_instance_valid(wellness_nest_visual):
		wellness_nest_visual.call("clear")
	if training_roost_visual != null and is_instance_valid(training_roost_visual):
		training_roost_visual.call("clear")
	if farmer_relations_gallery_visual != null and is_instance_valid(farmer_relations_gallery_visual):
		farmer_relations_gallery_visual.call("clear")
	if rooster_operations_office_visual != null and is_instance_valid(rooster_operations_office_visual):
		rooster_operations_office_visual.call("clear")
	if it_coop_visual != null and is_instance_valid(it_coop_visual):
		it_coop_visual.call("clear")
	if flock_relations_office_visual != null and is_instance_valid(flock_relations_office_visual):
		flock_relations_office_visual.call("clear")
	if feed_procurement_coop_visual != null and is_instance_valid(feed_procurement_coop_visual):
		feed_procurement_coop_visual.call("clear")
	if farmgate_dispatch_depot_visual != null and is_instance_valid(farmgate_dispatch_depot_visual):
		farmgate_dispatch_depot_visual.call("clear")
	if campus_expansion_visual != null and is_instance_valid(campus_expansion_visual):
		campus_expansion_visual.call("clear")
	if campus_portfolio_visual != null and is_instance_valid(campus_portfolio_visual):
		campus_portfolio_visual.call("clear")
	for built_root in [management_perch_root, egg_collection_root, zone_markers_root, bureau_satire_root, records_archive_root, shell_quality_lab_visual, packing_annex_visual, records_annex_visual, farm_mutual_service_coop_visual, farm_mutual_negotiation_room_visual, farm_mutual_contract_board_visual, care_campus_spine_root, wellness_nest_visual, training_roost_visual, farmer_relations_gallery_visual, operations_campus_spine_root, rooster_operations_office_visual, it_coop_visual, flock_relations_office_visual, feed_procurement_coop_visual, farmgate_dispatch_depot_visual, campus_expansion_visual, campus_portfolio_visual]:
		if built_root != null and is_instance_valid(built_root):
			built_root.free()
	management_perch_root = null
	egg_collection_root = null
	zone_markers_root = null
	bureau_satire_root = null
	records_archive_root = null
	shell_quality_lab_visual = null
	packing_annex_visual = null
	records_annex_visual = null
	farm_mutual_service_coop_visual = null
	farm_mutual_negotiation_room_visual = null
	farm_mutual_contract_board_visual = null
	care_campus_spine_root = null
	care_campus_first_bay_root = null
	care_campus_second_bay_root = null
	wellness_nest_visual = null
	training_roost_visual = null
	farmer_relations_gallery_visual = null
	operations_campus_spine_root = null
	operations_campus_first_bay_root = null
	operations_campus_second_bay_root = null
	rooster_operations_office_visual = null
	it_coop_visual = null
	flock_relations_office_visual = null
	feed_procurement_coop_visual = null
	farmgate_dispatch_depot_visual = null
	campus_expansion_visual = null
	campus_portfolio_visual = null
	_metrics_label = null
	_intake_status_label = null
	_perch_screen_material = null
	_rail_glow_material = null
	_quality_lamps.clear()
	_quality_lamp_materials.clear()
	_quality_lamp_tweens.clear()
	_grading_receipt_slots.clear()
	_grading_receipt_queue.clear()
	_clutch_slots.clear()
	_clutch_slot_markers.clear()
	_clutch_cup_batches.clear()
	_settled_clutch_eggs.clear()
	_clutch_recoil_tweens.clear()
	_presentation_clutch_root = null
	_cart_clutch_root = null
	_collection_cart_basket = null
	_surplus_marker_root = null
	_surplus_label = null
	_archive_story_content = null
	_intake_story_content = null
	_records_zone = null
	_west_perch_04_zone = null
	_west_perch_05_zone = null
	_clutch_egg_mesh = null
	_clutch_cup_mesh = null
	_displayed_clutch_day = -1
	_desired_clutch_counts = {&"sound": 0, &"golden": 0, &"cracked": 0}
	_pickup_points.clear()
	_zone_glows.clear()
	_built = false


func _build_shell_quality_lab_visual() -> void:
	shell_quality_lab_visual = ShellQualityLabVisualScript.new() as ShellQualityLabVisual
	shell_quality_lab_visual.name = "ShellQualityLabVisual"
	add_child(shell_quality_lab_visual)
	shell_quality_lab_visual.build()


func _build_packing_annex_visual() -> void:
	packing_annex_visual = PackingAnnexVisualScript.new() as Node3D
	packing_annex_visual.name = "PackingAnnexVisual"
	add_child(packing_annex_visual)
	packing_annex_visual.call("build")


func _build_records_annex_visual() -> void:
	records_annex_visual = RecordsAnnexVisualScript.new() as Node3D
	records_annex_visual.name = "RecordsAnnexVisual"
	add_child(records_annex_visual)
	records_annex_visual.call("build")


func _build_farm_mutual_service_coop_visual() -> void:
	farm_mutual_service_coop_visual = FarmMutualServiceCoopVisualScript.new() as Node3D
	farm_mutual_service_coop_visual.name = "FarmMutualServiceCoopVisual"
	add_child(farm_mutual_service_coop_visual)
	farm_mutual_service_coop_visual.call("build")


func _build_farm_mutual_negotiation_room_visual() -> void:
	farm_mutual_negotiation_room_visual = FarmMutualNegotiationRoomVisualScript.new() as Node3D
	farm_mutual_negotiation_room_visual.name = "FarmMutualNegotiationRoomVisual"
	add_child(farm_mutual_negotiation_room_visual)
	farm_mutual_negotiation_room_visual.call("build")


func _build_farm_mutual_contract_board_visual() -> void:
	farm_mutual_contract_board_visual = FarmMutualContractBoardVisualScript.new() as Node3D
	farm_mutual_contract_board_visual.name = "FarmMutualContractBoardVisual"
	add_child(farm_mutual_contract_board_visual)
	farm_mutual_contract_board_visual.call("build")


func _build_campus_spine_bay(
		parent: Node3D,
		bay_name: String,
		footprint: Rect2,
		walk_name: String,
		edge_name: String,
		walk_color: Color,
		edge_color: Color,
		walk_roughness: float,
) -> Node3D:
	var bay_root := Node3D.new()
	bay_root.name = bay_name
	bay_root.set_meta(&"visual_only", true)
	bay_root.set_meta(&"collision_free", true)
	bay_root.set_meta(&"navigation_free", true)
	bay_root.set_meta(&"declared_footprint", footprint)
	parent.add_child(bay_root)
	var center := Vector3(footprint.get_center().x, -0.055, footprint.get_center().y)
	_add_box(
		bay_root,
		walk_name,
		Vector3(footprint.size.x, 0.12, footprint.size.y),
		center,
		walk_color,
		walk_roughness,
	)
	for edge_x: float in [footprint.position.x + 0.08, footprint.end.x - 0.08]:
		_add_box(
			bay_root,
			edge_name,
			Vector3(0.035, 0.018, maxf(0.0, footprint.size.y - 0.10)),
			Vector3(edge_x, 0.014, center.z),
			edge_color,
			0.48,
			0.42,
		)
	return bay_root


func _build_care_campus_spine() -> void:
	care_campus_spine_root = Node3D.new()
	care_campus_spine_root.name = "CareCampusSpine"
	care_campus_spine_root.set_meta(&"visual_only", true)
	care_campus_spine_root.set_meta(&"collision_free", true)
	care_campus_spine_root.set_meta(&"navigation_free", true)
	care_campus_spine_root.set_meta(&"declared_footprint", CARE_CAMPUS_SPINE_FOOTPRINT)
	care_campus_spine_root.set_meta(
		&"serves_facilities",
		[&"wellness_nest_room", &"training_roost", &"farmer_relations_gallery"],
	)
	add_child(care_campus_spine_root)
	care_campus_first_bay_root = _build_campus_spine_bay(
		care_campus_spine_root,
		"CareCampusFirstBay",
		CARE_CAMPUS_FIRST_BAY_FOOTPRINT,
		"CareCampusConnectedWalk",
		"CareCampusBrassEdge",
		Color("58625e"),
		Color("b6944c"),
		0.94,
	)
	care_campus_second_bay_root = _build_campus_spine_bay(
		care_campus_spine_root,
		"CareCampusSecondBay",
		CARE_CAMPUS_SECOND_BAY_FOOTPRINT,
		"CareCampusConnectedWalk",
		"CareCampusBrassEdge",
		Color("58625e"),
		Color("b6944c"),
		0.94,
	)
	for bay_index in 6:
		var bay_z := 10.95 + bay_index * 3.0
		var bay_root := (
			care_campus_first_bay_root
			if CARE_CAMPUS_FIRST_BAY_FOOTPRINT.has_point(Vector2(10.80, bay_z)) else
			care_campus_second_bay_root
		)
		_add_box(
			bay_root,
			"CareCampusWayfindingInlay_%02d" % (bay_index + 1),
			Vector3(0.54, 0.018, 0.055),
			Vector3(CARE_CAMPUS_SPINE_FOOTPRINT.get_center().x, 0.015, bay_z),
			Color("d7ccb0"),
			0.92,
		)


func _build_wellness_nest_visual() -> void:
	wellness_nest_visual = WellnessNestVisualScript.new() as Node3D
	wellness_nest_visual.name = "WellnessNestVisual"
	add_child(wellness_nest_visual)
	wellness_nest_visual.call("build")


func _build_training_roost_visual() -> void:
	training_roost_visual = TrainingRoostVisualScript.new() as Node3D
	training_roost_visual.name = "TrainingRoostVisual"
	add_child(training_roost_visual)
	training_roost_visual.call("build")


func _build_farmer_relations_gallery_visual() -> void:
	farmer_relations_gallery_visual = FarmerRelationsGalleryVisualScript.new() as Node3D
	farmer_relations_gallery_visual.name = "FarmerRelationsGalleryVisual"
	add_child(farmer_relations_gallery_visual)
	farmer_relations_gallery_visual.call("build")


func _build_operations_campus_spine() -> void:
	operations_campus_spine_root = Node3D.new()
	operations_campus_spine_root.name = "OperationsCampusSpine"
	operations_campus_spine_root.set_meta(&"visual_only", true)
	operations_campus_spine_root.set_meta(&"collision_free", true)
	operations_campus_spine_root.set_meta(&"navigation_free", true)
	operations_campus_spine_root.set_meta(&"declared_footprint", OPERATIONS_CAMPUS_SPINE_FOOTPRINT)
	operations_campus_spine_root.set_meta(&"connects_from", &"care_campus_spine")
	operations_campus_spine_root.set_meta(
		&"serves_facilities",
		[&"rooster_operations_office", &"it_coop", &"flock_relations_office", &"feed_procurement_coop"],
	)
	add_child(operations_campus_spine_root)
	operations_campus_first_bay_root = _build_campus_spine_bay(
		operations_campus_spine_root,
		"OperationsCampusFirstBay",
		OPERATIONS_CAMPUS_FIRST_BAY_FOOTPRINT,
		"OperationsCampusConnectedWalk",
		"OperationsCampusBrassEdge",
		Color("46565a"),
		Color("ad904d"),
		0.91,
	)
	operations_campus_second_bay_root = _build_campus_spine_bay(
		operations_campus_spine_root,
		"OperationsCampusSecondBay",
		OPERATIONS_CAMPUS_SECOND_BAY_FOOTPRINT,
		"OperationsCampusConnectedWalk",
		"OperationsCampusBrassEdge",
		Color("46565a"),
		Color("ad904d"),
		0.91,
	)
	# This transverse brass threshold makes the care-to-operations seam legible
	# as one continuous campus walk instead of two disconnected floor slabs.
	_add_box(
		operations_campus_first_bay_root,
		"CareOperationsThreshold",
		Vector3(0.78, 0.022, 0.045),
		Vector3(
			OPERATIONS_CAMPUS_SPINE_FOOTPRINT.get_center().x,
			0.017,
			OPERATIONS_CAMPUS_SPINE_FOOTPRINT.position.y + 0.025,
		),
		Color("c5a45b"),
		0.42,
		0.48,
	)
	for inlay_index in 4:
		var inlay_z := 29.95 + inlay_index * 3.0
		var bay_root := (
			operations_campus_first_bay_root
			if OPERATIONS_CAMPUS_FIRST_BAY_FOOTPRINT.has_point(Vector2(10.80, inlay_z)) else
			operations_campus_second_bay_root
		)
		_add_box(
			bay_root,
			"OperationsCampusWayfindingInlay_%02d" % (inlay_index + 1),
			Vector3(0.54, 0.018, 0.055),
			Vector3(OPERATIONS_CAMPUS_SPINE_FOOTPRINT.get_center().x, 0.015, inlay_z),
			Color("d3c8aa"),
			0.92,
		)


func _build_rooster_operations_office_visual() -> void:
	rooster_operations_office_visual = RoosterOperationsOfficeVisualScript.new() as Node3D
	rooster_operations_office_visual.name = "RoosterOperationsOfficeVisual"
	add_child(rooster_operations_office_visual)
	rooster_operations_office_visual.call("build")


func _build_it_coop_visual() -> void:
	it_coop_visual = ITCoopVisualScript.new() as Node3D
	it_coop_visual.name = "ITCoopVisual"
	add_child(it_coop_visual)
	it_coop_visual.call("build")


func _build_flock_relations_office_visual() -> void:
	flock_relations_office_visual = FlockRelationsOfficeVisualScript.new() as Node3D
	flock_relations_office_visual.name = "FlockRelationsOfficeVisual"
	add_child(flock_relations_office_visual)
	flock_relations_office_visual.call("build")


func _build_feed_procurement_coop_visual() -> void:
	feed_procurement_coop_visual = FeedProcurementCoopVisualScript.new() as Node3D
	feed_procurement_coop_visual.name = "FeedProcurementCoopVisual"
	add_child(feed_procurement_coop_visual)
	feed_procurement_coop_visual.call("build")


func _build_farmgate_dispatch_depot_visual() -> void:
	farmgate_dispatch_depot_visual = FarmgateDispatchDepotVisualScript.new() as Node3D
	farmgate_dispatch_depot_visual.name = "FarmgateDispatchDepotVisual"
	add_child(farmgate_dispatch_depot_visual)
	farmgate_dispatch_depot_visual.call("build")


func _build_campus_expansion_visual() -> void:
	campus_expansion_visual = CampusExpansionVisualScript.new() as Node3D
	campus_expansion_visual.name = "CampusExpansionVisual"
	add_child(campus_expansion_visual)
	campus_expansion_visual.call("build")


func _build_campus_portfolio_visual() -> void:
	campus_portfolio_visual = CampusPortfolioVisualScript.new() as Node3D
	campus_portfolio_visual.name = "CampusPortfolioVisual"
	add_child(campus_portfolio_visual)
	campus_portfolio_visual.call("build")


func _build_management_perch() -> void:
	management_perch_root = Node3D.new()
	management_perch_root.name = "RoosterManagementPerch"
	add_child(management_perch_root)

	_add_box(management_perch_root, "PerchRaisedFoundation", Vector3(4.35, 0.22, 1.42), PERCH_CENTER + Vector3(0.0, 0.11, 0.0), Color("3f494c"), 0.72)
	_add_box(management_perch_root, "PerchBrassEdge", Vector3(4.46, 0.10, 0.10), PERCH_CENTER + Vector3(0.0, 0.27, 0.73), Color("b28b45"), 0.32, 0.52)
	var glass_post_positions: Array[Vector3] = []
	for post_x in [-2.08, 0.0, 2.08]:
		glass_post_positions.append(PERCH_CENTER + Vector3(post_x, 1.48, 0.70))
	_add_box_multimesh(management_perch_root, "PerchGlassPostBatch", Vector3(0.09, 2.46, 0.09), glass_post_positions, Color("48575b"), 0.40, 0.52)
	_add_glass_box(management_perch_root, "PerchGlassFrontLeft", Vector3(2.00, 2.20, 0.035), PERCH_CENTER + Vector3(-1.04, 1.46, 0.69))
	_add_glass_box(management_perch_root, "PerchGlassFrontRight", Vector3(2.00, 2.20, 0.035), PERCH_CENTER + Vector3(1.04, 1.46, 0.69))
	for side_x in [-2.10, 2.10]:
		_add_glass_box(management_perch_root, "PerchGlassSide", Vector3(0.035, 2.20, 1.32), PERCH_CENTER + Vector3(side_x, 1.46, 0.0))

	# A luxurious desk with conspicuously little actual paperwork.
	_add_box(management_perch_root, "ExecutivePerchDesk", Vector3(2.55, 0.15, 0.72), PERCH_CENTER + Vector3(0.0, 1.02, 0.05), Color("6f4f39"), 0.58)
	var desk_leg_positions: Array[Vector3] = []
	for leg_x in [-1.12, 1.12]:
		desk_leg_positions.append(PERCH_CENTER + Vector3(leg_x, 0.57, 0.05))
	_add_box_multimesh(management_perch_root, "ExecutiveDeskLegBatch", Vector3(0.13, 0.84, 0.54), desk_leg_positions, Color("4f3d32"), 0.72)
	var monitor_frame_positions: Array[Vector3] = []
	var monitor_screen_positions: Array[Vector3] = []
	for monitor_x in [-0.65, 0.0, 0.65]:
		monitor_frame_positions.append(PERCH_CENTER + Vector3(monitor_x, 1.40, 0.02))
		monitor_screen_positions.append(PERCH_CENTER + Vector3(monitor_x, 1.40, 0.057))
	_add_box_multimesh(
		management_perch_root, "FlockwatchMonitorFrameBatch",
		Vector3(0.56, 0.43, 0.06),
		monitor_frame_positions,
		Color("20292e"), 0.46
	)
	if _perch_screen_material == null:
		_perch_screen_material = _make_emissive_material(Color("77b5a8"), 0.78)
	var monitor_screen_batch := _add_box_multimesh(
		management_perch_root, "FlockwatchMonitorScreenBatch",
		Vector3(0.48, 0.35, 0.018),
		monitor_screen_positions,
		Color("4e8884"), 0.42
	)
	monitor_screen_batch.material_override = _perch_screen_material
	_add_box(management_perch_root, "ExecutiveRoostSeat", Vector3(0.82, 0.16, 0.62), PERCH_CENTER + Vector3(0.0, 0.68, -0.43), Color("283c4d"), 0.66)
	var executive_back := _add_box(management_perch_root, "ExecutiveRoostBack", Vector3(0.94, 1.18, 0.18), PERCH_CENTER + Vector3(0.0, 1.24, -0.67), Color("2d4558"), 0.62)
	executive_back.rotation_degrees.x = -5.0
	_add_cylinder(management_perch_root, "ExecutiveRoostColumn", PERCH_CENTER + Vector3(0.0, 0.36, -0.43), 0.08, 0.54, Color("4f5b5e"), 0.38)
	_add_box(management_perch_root, "ExecutiveRoostFoot", Vector3(0.78, 0.08, 0.12), PERCH_CENTER + Vector3(0.0, 0.10, -0.43), Color("4f5b5e"), 0.38, 0.38)

	var golden_egg := _add_egg(management_perch_root, "ExecutiveGoldenEgg", PERCH_CENTER + Vector3(1.56, 0.75, 0.08), Color("e0b34f"))
	golden_egg.material_override = _material(Color("e0b34f"), 0.24, 0.42)
	_add_cylinder(management_perch_root, "GoldenEggPlinth", PERCH_CENTER + Vector3(1.56, 0.38, 0.08), 0.31, 0.30, Color("67503b"), 0.62)

	# Clamp the dashboard to the perch structure. The former screen had a real
	# frame but no visible support, so its otherwise physical copy still hovered.
	var display_rail_positions: Array[Vector3] = []
	var display_clamp_positions: Array[Vector3] = []
	for support_side in [-1.0, 1.0]:
		display_rail_positions.append(PERCH_CENTER + Vector3(support_side * 1.23, 2.61, 0.705))
		display_clamp_positions.append(PERCH_CENTER + Vector3(support_side * 1.43, 3.02, 0.705))
	_add_box_multimesh(management_perch_root, "FlockwatchDisplayRailBatch", Vector3(0.075, 1.18, 0.075), display_rail_positions, Color("4c5b5b"), 0.46, 0.34)
	_add_box_multimesh(management_perch_root, "FlockwatchDisplayClampBatch", Vector3(0.48, 0.075, 0.085), display_clamp_positions, Color("4c5b5b"), 0.46, 0.34)
	_metrics_label = _add_mounted_label(
		management_perch_root,
		"ManagementYieldBoard",
		"YIELD  000 / 000\nN 02   P 02   A 02\n9:00 AM  ·  LIVE",
		PERCH_CENTER + Vector3(-0.08, 2.63, 0.76),
		Vector2(2.34, 0.82), Color("274447"), Color("c8ddc8"), Vector3.ZERO,
		20, 0.0044, &"secondary", &"screen", true
	)
	var perch_header_beam := _add_box(
		management_perch_root,
		"PerchDepartmentHeaderBeam",
		Vector3(2.56, 0.22, 0.105),
		PERCH_CENTER + Vector3(0.0, 3.25, 0.70),
		Color("3f5152"),
		0.74
	)
	_add_mounted_label(
		perch_header_beam, "PerchTitle", "FLOCKWATCH",
		Vector3(0.0, 0.0, 0.062), Vector2(2.24, 0.16),
		Color("3f5152"), Color("e5dcc3"), Vector3.ZERO,
		16, 0.0062, &"primary", &"destination"
	)

	# Camera and ledger reinforce the surveillance/credit-taking silhouette.
	_add_box(management_perch_root, "FlockSurveillanceArm", Vector3(0.62, 0.07, 0.07), PERCH_CENTER + Vector3(-1.76, 2.70, 0.94), Color("515c60"), 0.40, 0.48)
	var camera := _add_box(management_perch_root, "FlockSurveillanceCamera", Vector3(0.34, 0.25, 0.32), PERCH_CENTER + Vector3(-2.02, 2.61, 1.02), Color("2d373b"), 0.45)
	camera.rotation_degrees.x = -14.0
	_add_cylinder(management_perch_root, "FlockSurveillanceLens", PERCH_CENTER + Vector3(-2.02, 2.55, 1.20), 0.09, 0.12, Color("bd3d37"), 0.26).rotation_degrees.x = 90.0


func _build_egg_collection_chain() -> void:
	egg_collection_root = Node3D.new()
	egg_collection_root.name = "VisibleEggCollectionChain"
	add_child(egg_collection_root)
	_quality_lamps.clear()
	_quality_lamp_materials.clear()
	_quality_lamp_tweens.clear()
	_grading_receipt_slots.clear()
	_grading_receipt_slots.resize(GRADING_RECEIPT_SLOT_COUNT)
	_grading_receipt_slots.fill(null)
	_grading_receipt_queue.clear()
	_rail_glow_material = _make_emissive_material(Color("d8b761"), RAIL_IDLE_ENERGY)
	_rail_glow_material.albedo_color = Color("3f4746")
	_rail_glow_material.roughness = 0.72
	_rail_glow_material.metallic = 0.12

	var row_zs: Array[float] = []
	var tray_rail_positions: Array[Vector3] = []
	for desk_index in _desk_positions.size():
		var desk := _desk_positions[desk_index]
		var pickup := desk + Vector3(1.33, 1.12, 0.70)
		_pickup_points.append(pickup)
		if not row_zs.has(pickup.z):
			row_zs.append(pickup.z)

		# Desktop-side collection nests stay opposite the chair approach.
		_add_box(egg_collection_root, "DeskEggTray_%02d" % desk_index, Vector3(0.76, 0.10, 0.48), pickup, Color("8e6946"), 0.72)
		for rail_x in [-0.33, 0.33]:
			tray_rail_positions.append(pickup + Vector3(rail_x, 0.10, 0.0))
		_add_cylinder(egg_collection_root, "EggLiftTube_%02d" % desk_index, Vector3(pickup.x, (pickup.y + COLLECTION_RAIL_HEIGHT) * 0.5, pickup.z), 0.055, COLLECTION_RAIL_HEIGHT - pickup.y, Color("9aa7a4"), 0.38)
		var status_lamp := _add_sphere(egg_collection_root, "CollectionStatusLamp_%02d" % desk_index, Vector3(pickup.x, COLLECTION_RAIL_HEIGHT, pickup.z), Vector3(0.15, 0.15, 0.15), Color("d7b45e"), 8, 4)
		status_lamp.material_override = _rail_glow_material
	_add_box_multimesh(
		egg_collection_root, "DeskTrayRailBatch", Vector3(0.06, 0.24, 0.50),
		tray_rail_positions, Color("82745a"), 0.64, 0.12
	)

	row_zs.sort()
	for row_index in row_zs.size():
		var row_z := row_zs[row_index]
		# Each row begins at its own westernmost authorized pickup. A fifth-perch
		# purchase therefore extends one rail branch; the sixth completes the pair.
		var start_x := INF
		for pickup: Vector3 in _pickup_points:
			if is_equal_approx(pickup.z, row_z):
				start_x = minf(start_x, pickup.x)
		if is_inf(start_x):
			continue
		_add_rail_segment(egg_collection_root, "OverheadRowRail_%02d" % row_index, Vector3(start_x, COLLECTION_RAIL_HEIGHT, row_z), Vector3(SIDE_MANIFOLD_X, COLLECTION_RAIL_HEIGHT, row_z))

	var forward_z := row_zs.max() as float if not row_zs.is_empty() else 3.70
	_add_rail_segment(egg_collection_root, "EggQualityManifold", Vector3(SIDE_MANIFOLD_X, COLLECTION_RAIL_HEIGHT, forward_z), Vector3(SIDE_MANIFOLD_X, COLLECTION_RAIL_HEIGHT, _presentation_position.z))
	_add_cylinder(egg_collection_root, "PresentationDropTube", Vector3(SIDE_MANIFOLD_X, 1.95, _presentation_position.z), 0.075, 1.38, Color("9aa7a4"), 0.38)
	_add_rail_segment(egg_collection_root, "FarmerCreditRail", Vector3(SIDE_MANIFOLD_X, 1.26, _presentation_position.z), _presentation_position + Vector3.UP * 1.26)

	# Empty carrier collars describe the pneumatic route without pre-populating
	# the office with eggs the flock has not actually laid.
	for carrier_index in 4:
		var carrier_position := Vector3(SIDE_MANIFOLD_X, COLLECTION_RAIL_HEIGHT, 1.10 - carrier_index * 1.70)
		var carrier := _add_cylinder(
			egg_collection_root,
			"EmptyTransitCarrier_%02d" % carrier_index,
			carrier_position,
			0.13,
			0.28,
			Color("667477"),
			0.38
		)
		carrier.rotation_degrees.x = 90.0
		var carrier_lamp := _add_sphere(
			egg_collection_root,
			"TransitCarrierLamp_%02d" % carrier_index,
			carrier_position + Vector3(0.0, 0.14, 0.0),
			Vector3.ONE * 0.055,
			Color("d0aa53"),
			8,
			4
		)
		carrier_lamp.material_override = _rail_glow_material

	_build_sorting_gate()
	_build_collection_cart()
	_build_living_clutch()
	# Tubes, empty carriers, gate lamps, and destination cups explain the chain.
	# Only eggs emitted by the authoritative simulation ever occupy it.


func _build_sorting_gate() -> void:
	var center := _sorting_gate_center()
	var gate := _add_box(egg_collection_root, "ShellIntegrityGate", Vector3(0.62, 0.62, 0.16), center, Color("42575c"), 0.48)
	# A fixed printer body makes the transient grading docket part of the gate.
	_add_box(
		egg_collection_root, "GradingReceiptPrinterMount",
		Vector3(0.20, 0.30, 0.20), center + Vector3(-0.34, 0.02, 0.11),
		Color("56666a"), 0.42, 0.30
	)
	_add_box(
		egg_collection_root, "GradingReceiptPrinterBody",
		Vector3(0.56, 0.45, 0.28), center + Vector3(-0.62, 0.02, 0.20),
		Color("34464a"), 0.48, 0.22
	)
	_add_box(
		egg_collection_root, "GradingReceiptPrinterFace",
		Vector3(0.52, 0.36, 0.026), center + Vector3(-0.62, 0.01, 0.352),
		Color("677579"), 0.58, 0.18
	)
	_add_box(
		egg_collection_root, "GradingReceiptPrinterSlot",
		Vector3(0.48, 0.042, 0.028), center + Vector3(-0.62, -0.12, 0.370),
		Color("14191b"), 0.96
	)
	_add_box(
		egg_collection_root, "GradingReceiptPrinterLip",
		Vector3(0.50, 0.030, 0.055), center + Vector3(-0.62, -0.155, 0.378),
		Color("8a8f8b"), 0.46, 0.28
	)
	var quality_order: Array[StringName] = [&"sound", &"golden", &"cracked"]
	for lamp_index in quality_order.size():
		var quality := quality_order[lamp_index]
		var lamp_color := SemanticColorPaletteScript.quality_color(quality, _color_vision_mode)
		var lamp := _add_sphere(
			egg_collection_root,
			"QualityGateLamp_%d" % lamp_index,
			center + Vector3(-0.19 + lamp_index * 0.19, -0.12, 0.11),
			Vector3.ONE * 0.11,
			lamp_color,
			8,
			4
		)
		var lamp_material := _make_emissive_material(lamp_color, SORTER_LAMP_IDLE_ENERGY)
		lamp.material_override = lamp_material
		_quality_lamps[quality] = lamp
		_quality_lamp_materials[quality] = lamp_material
	_add_mounted_label(
		gate, "ShellIntegrityLabel", "GRADE  /  CREDIT",
		Vector3(0.0, 0.17, 0.087), Vector2(0.52, 0.18),
		Color("34494e"), Color("e7ddc2"), Vector3.ZERO,
		11, 0.0026, &"utility", &"machine"
	)


func _build_collection_cart() -> void:
	var cart_center := COLLECTION_CART_CENTER
	_collection_cart_basket = _add_box(egg_collection_root, "EggCollectionCartBasket", Vector3(0.85, 0.55, 1.05), cart_center + Vector3(0.0, 0.66, 0.0), Color("a07449"), 0.72)
	_add_box(egg_collection_root, "EggCollectionCartHandle", Vector3(0.72, 0.08, 0.08), cart_center + Vector3(0.0, 1.22, -0.56), Color("555f60"), 0.42, 0.38)
	var wheel_transforms: Array[Transform3D] = []
	for wheel_z in [-0.39, 0.39]:
		for wheel_x in [-0.36, 0.36]:
			wheel_transforms.append(Transform3D(
				Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(90.0))),
				cart_center + Vector3(wheel_x, 0.26, wheel_z)
			))
	_add_cylinder_multimesh(
		egg_collection_root, "EggCartWheelBatch", 0.14, 0.08,
		wheel_transforms, Color("202628"), 0.90
	)


func _build_living_clutch() -> void:
	_clutch_slots.clear()
	_clutch_slot_markers.clear()
	_clutch_cup_batches.clear()
	_settled_clutch_eggs.clear()
	_clutch_recoil_tweens.clear()
	_displayed_clutch_day = -1
	_desired_clutch_counts = {&"sound": 0, &"golden": 0, &"cracked": 0}

	_clutch_egg_mesh = _build_tapered_egg_mesh()
	_clutch_cup_mesh = CylinderMesh.new()
	_clutch_cup_mesh.top_radius = 0.15
	_clutch_cup_mesh.bottom_radius = 0.17
	_clutch_cup_mesh.height = 0.025
	_clutch_cup_mesh.radial_segments = 10

	_presentation_clutch_root = Node3D.new()
	_presentation_clutch_root.name = "PresentationLivingClutch"
	_presentation_clutch_root.position = _presentation_position
	egg_collection_root.add_child(_presentation_clutch_root)
	var presentation_cup_batch := _add_clutch_cup_batch(
		_presentation_clutch_root,
		"EmptyClutchCupBatchPresentation",
		PRESENTATION_CLUTCH_SLOTS
	)
	_add_box(
		_presentation_clutch_root,
		"PresentationNestInsert",
		Vector3(1.96, 0.075, 1.28),
		Vector3(0.0, 0.565, 0.0),
		Color("80603f"),
		0.96
	)
	for row in 4:
		for column in 6:
			_add_clutch_slot(
				_presentation_clutch_root,
				Vector3(-0.85 + column * 0.34, 0.76 + row * 0.012, -0.50 + row * 0.33),
				presentation_cup_batch,
				row * 6 + column
			)

	_cart_clutch_root = Node3D.new()
	_cart_clutch_root.name = "CollectionCartLivingClutch"
	_cart_clutch_root.position = COLLECTION_CART_CENTER
	egg_collection_root.add_child(_cart_clutch_root)
	var cart_cup_batch := _add_clutch_cup_batch(
		_cart_clutch_root,
		"EmptyClutchCupBatchCart",
		CART_CLUTCH_SLOTS
	)
	_add_box(
		_cart_clutch_root,
		"CartNestInsert",
		Vector3(0.72, 0.055, 0.88),
		Vector3(0.0, 0.885, 0.0),
		Color("77593b"),
		0.96
	)
	for row in 4:
		for column in 3:
			_add_clutch_slot(
				_cart_clutch_root,
				Vector3(-0.26 + column * 0.26, 1.055 + row * 0.010, -0.36 + row * 0.24),
				cart_cup_batch,
				row * 3 + column
			)

	assert(_clutch_slots.size() == MAX_VISIBLE_CLUTCH_EGGS)
	assert(PRESENTATION_CLUTCH_SLOTS + CART_CLUTCH_SLOTS == MAX_VISIBLE_CLUTCH_EGGS)

	# The overflow counter is painted onto the cart basket. Parent the fixture to
	# that mesh so it inherits any future cart movement instead of hovering in
	# front of a world-space approximation of the basket face.
	assert(_collection_cart_basket != null)
	_surplus_label = _add_mounted_label(
		_collection_cart_basket,
		"ClutchSurplusLabel",
		"SURPLUS  +00",
		Vector3(0.0, 0.02, 0.528),
		Vector2(0.70, 0.25),
		Color("a07449"),
		Color("e7c968"),
		Vector3.ZERO,
		11,
		0.0026,
		&"secondary",
		&"stencil"
	)
	_surplus_marker_root = _surplus_label.get_parent() as Node3D
	_surplus_marker_root.name = "ClutchSurplusMarker"
	# Unlike decorative equipment captions, this is authoritative inventory data.
	# Keep the mechanical counter readable in overview while its surrounding cart
	# copy still follows the normal spatial-detail hierarchy.
	if _surplus_marker_root != null:
		_surplus_marker_root.set_meta(&"overview_anchor", true)
	_surplus_marker_root.visible = false


func _add_clutch_cup_batch(parent: Node3D, batch_name: String, instance_count: int) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _clutch_cup_mesh
	multimesh.instance_count = instance_count
	var batch := MultiMeshInstance3D.new()
	batch.name = batch_name
	batch.multimesh = multimesh
	batch.material_override = _material(Color("493b31"), 0.98)
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(batch)
	_clutch_cup_batches.append(batch)
	return batch


func _add_clutch_slot(
	parent: Node3D,
	egg_center: Vector3,
	cup_batch: MultiMeshInstance3D,
	cup_batch_index: int
) -> void:
	var slot_index := _clutch_slots.size()
	var slot := Node3D.new()
	slot.name = "AuthoritativeClutchSlot_%02d" % slot_index
	slot.position = egg_center
	parent.add_child(slot)
	_clutch_slots.append(slot)

	assert(cup_batch != null and cup_batch.multimesh != null)
	assert(cup_batch_index >= 0 and cup_batch_index < cup_batch.multimesh.instance_count)
	var cup_transform := Transform3D(
		Basis.from_scale(Vector3(1.0, 1.0, 0.88)),
		egg_center + Vector3(0.0, -0.19, 0.0)
	)
	cup_batch.multimesh.set_instance_transform(cup_batch_index, cup_transform)
	_clutch_slot_markers.append({
		"batch": cup_batch,
		"instance_index": cup_batch_index,
		"rest_transform": cup_transform,
		"occupied": false,
	})


func _build_zone_markers() -> void:
	zone_markers_root = Node3D.new()
	zone_markers_root.name = "FarmBureauZoneMarkers"
	add_child(zone_markers_root)
	# The opening flock occupies the commissioned center/east pod. The former
	# 17.8 m outline made the dormant west carpet look complete on Day 1.
	_build_zone("MainLayingFloor", Vector3(3.25, 0.0, -0.05), Vector2(13.1, 12.35), Color("719a8e"))
	_west_perch_04_zone = _build_zone(
		"WestPerch04",
		WEST_PERCH_04_POSITION,
		Vector2(5.15, 5.10),
		Color("719a8e"),
	)
	_west_perch_05_zone = _build_zone(
		"WestPerch05",
		WEST_PERCH_05_POSITION,
		Vector2(5.15, 5.10),
		Color("719a8e"),
	)
	_build_zone("PeckworkIntake", _intake_position, Vector2(3.0, 3.0), Color("d2a14e"))
	_records_zone = _build_zone("RecordsRetention", Vector3(-7.35, 0.0, -8.08), Vector2(2.65, 1.42), Color("8da1a0"))
	_build_zone("FarmerPresentation", _presentation_position, Vector2(3.20, 2.50), Color("c89a4a"))


func _build_zone(zone_name: String, center: Vector3, size: Vector2, color: Color) -> Node3D:
	var zone := Node3D.new()
	zone.name = "Zone_%s" % zone_name
	zone_markers_root.add_child(zone)
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	var corner_length := minf(0.62, minf(half_x, half_z) * 0.55)
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			var x_line := _add_box(zone, "ZoneMarkerGlow", Vector3(corner_length, 0.010, 0.055), center + Vector3(side_x * (half_x - corner_length * 0.5), 0.021, side_z * half_z), color, 0.52)
			var z_line := _add_box(zone, "ZoneMarkerGlow", Vector3(0.055, 0.010, corner_length), center + Vector3(side_x * half_x, 0.022, side_z * (half_z - corner_length * 0.5)), color, 0.52)
			x_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			z_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_zone_glows.append(x_line)
			_zone_glows.append(z_line)
	return zone


func _build_bureau_satire() -> void:
	bureau_satire_root = Node3D.new()
	bureau_satire_root.name = "FarmBureauSatire"
	add_child(bureau_satire_root)

	# Cluster policy satire on one corkboard. At overview distance it reads as a
	# believable notice center instead of three isolated UI cards spread across
	# the wall; camera focus still reveals each joke.
	var bulletin := Node3D.new()
	bulletin.name = "BureauBulletinBoard"
	bulletin.position = Vector3(-11.695, 2.28, -0.15)
	bulletin.rotation_degrees.y = 90.0
	bureau_satire_root.add_child(bulletin)
	_add_box(bulletin, "BulletinBoardShadow", Vector3(3.58, 2.05, 0.055), Vector3(0.035, -0.035, -0.075), Color("2f2a25"), 0.96)
	_add_box(bulletin, "BulletinBoardFrame", Vector3(3.52, 2.00, 0.090), Vector3.ZERO, Color("5b4937"), 0.72)
	_add_box(bulletin, "BulletinBoardCork", Vector3(3.30, 1.78, 0.045), Vector3(0.0, 0.0, 0.060), Color("917153"), 0.92)
	_add_mounted_label(
		bulletin, "FreeRangePermitLabel", "FREE-RANGE PASS\nFORM 17-B / APPROVAL",
		Vector3(-0.88, 0.37, 0.085), Vector2(1.40, 0.68),
		Color("ddd3b6"), Color("42606b"), Vector3(0.0, 0.0, -2.2),
		15, 0.0053, &"secondary", &"paper"
	)
	_add_mounted_label(
		bulletin, "NestClassificationLabel", "NEST STATUS\nTEMPORARY / PENDING",
		Vector3(0.86, 0.31, 0.085), Vector2(1.36, 0.72),
		Color("ddd5c0"), Color("6b4b3e"), Vector3(0.0, 0.0, 1.6),
		15, 0.0053, &"secondary", &"paper"
	)
	_add_mounted_label(
		bulletin, "EveryEggMattersLabel", "EVERY EGG COUNTS\nCREDIT MAY VARY",
		Vector3(0.02, -0.58, 0.085), Vector2(2.18, 0.50),
		Color("e2d3ae"), Color("965742"), Vector3(0.0, 0.0, -0.6),
		15, 0.0053, &"secondary", &"paper"
	)

	var suggestion_center := Vector3(-11.52, 1.10, 1.42)
	var suggestion_box := _add_box(bureau_satire_root, "OpenBeakSuggestionBox", Vector3(0.23, 0.74, 0.96), suggestion_center, Color("5c7478"), 0.72)
	_add_box(bureau_satire_root, "SuggestionSlot", Vector3(0.05, 0.08, 0.48), suggestion_center + Vector3(0.13, 0.17, 0.0), Color("171e20"), 0.88)
	_add_mounted_label(
		suggestion_box, "SuggestionBoxLabel", "OPEN BEAK\nComments become bedding",
		Vector3(0.121, -0.05, 0.0), Vector2(0.74, 0.44),
		Color("557074"), Color("eee3c9"), Vector3(0.0, 90.0, 0.0),
		10, 0.0025, &"utility", &"stencil"
	)

	# Badge-only feed dispenser: intentionally mounted against the perimeter.
	var dispenser := Vector3(-11.54, 0.88, 7.65)
	_add_box(bureau_satire_root, "BadgeFeedDispenser", Vector3(0.34, 1.50, 0.82), dispenser, Color("586a69"), 0.74)
	_add_box(bureau_satire_root, "FeedDispenserWindow", Vector3(0.08, 0.44, 0.48), dispenser + Vector3(0.19, 0.28, 0.0), Color("c89d47"), 0.54)
	var reader := _add_box(bureau_satire_root, "FeedBadgeReader", Vector3(0.08, 0.32, 0.30), dispenser + Vector3(0.19, -0.28, 0.0), Color("324348"), 0.42)
	reader.material_override = _emissive_material(Color("75a891"), 0.46)
	# A corn kernel emblem and the existing lit badge reader replace tiny floating
	# instructions on the dispenser.
	for kernel_index in 3:
		_add_sphere(
			bureau_satire_root, "FeedBenefitKernel_%d" % kernel_index,
			dispenser + Vector3(0.20, 0.48 + kernel_index * 0.13, -0.12 + kernel_index * 0.12),
			Vector3(0.06, 0.10, 0.05), Color("e0b64f"), 8, 4
		)


func _build_records_and_intake_story() -> void:
	records_archive_root = Node3D.new()
	records_archive_root.name = "ArchiveAndIntakeStory"
	add_child(records_archive_root)
	_archive_story_content = Node3D.new()
	_archive_story_content.name = "ArchiveStoryPresentation"
	records_archive_root.add_child(_archive_story_content)
	_intake_story_content = Node3D.new()
	_intake_story_content.name = "IntakeStoryPresentation"
	records_archive_root.add_child(_intake_story_content)

	var shelf_center := Vector3(-7.35, 0.0, -8.17)
	for post_x in [-1.15, 1.15]:
		_add_box(_archive_story_content, "ArchiveShelfPost", Vector3(0.10, 2.32, 0.48), shelf_center + Vector3(post_x, 1.18, 0.0), Color("596467"), 0.48, 0.36)
	for shelf_y in [0.18, 0.92, 1.66, 2.34]:
		_add_box(_archive_story_content, "ArchiveShelf", Vector3(2.42, 0.09, 0.55), shelf_center + Vector3(0.0, shelf_y, 0.0), Color("687477"), 0.50, 0.30)
	for box_index in 7:
		var tier := int(box_index / 3)
		var column := box_index % 3
		var box_position := shelf_center + Vector3(-0.75 + column * 0.74, 0.55 + tier * 0.74, 0.0)
		_add_box(_archive_story_content, "LifetimeEggRecordBox_%02d" % box_index, Vector3(0.61, 0.46, 0.44), box_position, Color("b39768") if box_index % 2 == 0 else Color("9e8664"), 0.90)
		_add_box(_archive_story_content, "RecordBoxLabel", Vector3(0.31, 0.13, 0.025), box_position + Vector3(0.0, 0.0, 0.23), Color("e3dcc5"), 0.92)
	var archive_header := _add_box(
		_archive_story_content, "ArchiveHeaderBeam", Vector3(2.42, 0.42, 0.12),
		shelf_center + Vector3(0.0, 2.62, 0.0), Color("4e5c5f"), 0.62, 0.24
	)
	_add_mounted_label(
		archive_header, "ArchiveRetentionLabel", "LAYING ARCHIVE\nPermanent record",
		Vector3(0.0, 0.0, 0.067), Vector2(2.24, 0.36),
		Color("4e5c5f"), Color("ead9ae"), Vector3.ZERO,
		14, 0.0030, &"secondary", &"stencil"
	)

	# Intake paperwork sits on the existing counter footprint, so it enriches that
	# prop rather than adding another floor obstruction.
	for form_index in 5:
		_add_box(_intake_story_content, "IntakeForm_%02d" % form_index, Vector3(0.72, 0.025, 0.50), _intake_position + Vector3(-0.40 + form_index * 0.018, 1.18 + form_index * 0.027, 0.18 - form_index * 0.01), Color("e3ddc9") if form_index % 2 == 0 else Color("cad5cf"), 0.96)
	_add_box(_intake_story_content, "RejectedShellStamp", Vector3(0.22, 0.31, 0.22), _intake_position + Vector3(0.45, 1.32, 0.22), Color("8f493e"), 0.66)
	_add_box(_intake_story_content, "FarmerCreditLedger", Vector3(0.72, 0.11, 0.52), _intake_position + Vector3(0.42, 1.21, -0.42), Color("4e6b71"), 0.72)
	_intake_status_label = _add_mounted_label(
		_intake_story_content, "IntakeStatusLedger", "RECEIVED  0000\nCREDITED  0000",
		_intake_position + Vector3(0.0, 1.56, 0.60), Vector2(1.42, 0.52),
		Color("2b4542"), Color("c8d9b6"), Vector3.ZERO,
		14, 0.0030, &"utility", &"screen", true
	)
	# A deep terminal hood and counter base make this a piece of intake hardware,
	# not a second management billboard balanced on thin poles.
	_add_box(
		_intake_story_content, "IntakeLedgerTerminalHood",
		Vector3(1.58, 0.66, 0.18),
		_intake_position + Vector3(0.0, 1.56, 0.47),
		Color("3d4b49"), 0.66, 0.12
	)
	_add_box(
		_intake_story_content, "IntakeLedgerTerminalBase",
		Vector3(1.26, 0.10, 0.46),
		_intake_position + Vector3(0.0, 1.22, 0.43),
		Color("59635d"), 0.62, 0.18
	)
	for support_x in [-0.52, 0.52]:
		_add_box(
			_intake_story_content, "IntakeLedgerSupport",
			Vector3(0.055, 0.32, 0.060),
			_intake_position + Vector3(support_x, 1.38, 0.52),
			Color("59676a"), 0.38, 0.42
		)
	_add_box(
		_intake_story_content, "IntakeLedgerCrossbar",
		Vector3(1.16, 0.065, 0.065),
		_intake_position + Vector3(0.0, 1.23, 0.52),
		Color("59676a"), 0.38, 0.42
	)


func _add_rail_segment(parent: Node3D, part_name: String, start: Vector3, finish: Vector3) -> MeshInstance3D:
	var offset := finish - start
	var length := offset.length()
	var rail := _add_box(parent, part_name, Vector3(0.095, 0.095, length), start.lerp(finish, 0.5), Color("687674"), 0.58, 0.28)
	rail.set_meta(&"segment_start", start)
	rail.set_meta(&"segment_finish", finish)
	if length > 0.001:
		rail.look_at(finish, Vector3.UP)
	var glow := _add_box(parent, "%sGlow" % part_name, Vector3(0.025, 0.026, length * 0.98), start.lerp(finish, 0.5) + Vector3.UP * 0.058, Color("d9bd70"), 0.42)
	if length > 0.001:
		glow.look_at(finish, Vector3.UP)
	glow.material_override = _rail_glow_material
	return rail


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


func _add_box_multimesh(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	positions: Array[Vector3],
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0
) -> MultiMeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = positions.size()
	for instance_index in positions.size():
		multimesh.set_instance_transform(instance_index, Transform3D(Basis.IDENTITY, positions[instance_index]))
	var instance := MultiMeshInstance3D.new()
	instance.name = part_name
	instance.multimesh = multimesh
	instance.material_override = _material(color, roughness, metallic)
	instance.set_meta("authored_positions", positions.duplicate())
	parent.add_child(instance)
	return instance


func _add_glass_box(parent: Node3D, part_name: String, size: Vector3, part_position: Vector3) -> MeshInstance3D:
	var glass := _add_box(parent, part_name, size, part_position, Color(0.52, 0.72, 0.74, 0.23), 0.18, 0.08)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glass


func _add_cylinder(
	parent: Node3D,
	part_name: String,
	part_position: Vector3,
	radius: float,
	height: float,
	color: Color,
	roughness: float = 0.82
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.material_override = _material(color, roughness)
	parent.add_child(instance)
	return instance


func _add_cylinder_multimesh(
	parent: Node3D,
	part_name: String,
	radius: float,
	height: float,
	transforms: Array[Transform3D],
	color: Color,
	roughness: float = 0.82
) -> MultiMeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for instance_index in transforms.size():
		multimesh.set_instance_transform(instance_index, transforms[instance_index])
	var instance := MultiMeshInstance3D.new()
	instance.name = part_name
	instance.multimesh = multimesh
	instance.material_override = _material(color, roughness)
	instance.set_meta("authored_transforms", transforms.duplicate())
	parent.add_child(instance)
	return instance


func _add_sphere(
	parent: Node3D,
	part_name: String,
	part_position: Vector3,
	part_scale: Vector3,
	color: Color,
	radial_segments: int = 12,
	rings: int = 6
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = radial_segments
	mesh.rings = rings
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance


func _add_egg(parent: Node3D, part_name: String, part_position: Vector3, color: Color) -> MeshInstance3D:
	return _add_sphere(parent, part_name, part_position, Vector3(0.24, 0.34, 0.24), color, 12, 7)


func _add_mounted_label(
	parent: Node3D,
	label_name: String,
	text: String,
	position: Vector3,
	panel_size: Vector2,
	panel_color: Color,
	ink_color: Color,
	rotation_degrees: Vector3,
	font_size: int,
	pixel_size: float,
	tier: StringName,
	mount_kind: StringName,
	is_screen: bool = false
) -> Label3D:
	return EnvironmentalSignageScript.add_panel(
		parent, label_name, text, position, panel_size,
		panel_color, ink_color, rotation_degrees,
		font_size, pixel_size, tier, mount_kind, is_screen
	)


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
		material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED
	_material_cache[key] = material
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var key := "emissive_%s_%.2f" % [color.to_html(true), energy]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := _make_emissive_material(color, energy)
	_material_cache[key] = material
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.42)
	material.roughness = 0.42
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.resource_local_to_scene = true
	return material
