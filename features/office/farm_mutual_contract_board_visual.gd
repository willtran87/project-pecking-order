class_name FarmMutualContractBoardVisual
extends Node3D

const EnvironmentalSignageScript := preload("res://features/office/environmental_signage.gd")

## Snapshot-driven, visual-only contract fixture. The board occupies the unused
## center bay of the office's left wall, above the feed-party station and between
## the wellness plaque and Claims Pipeline board. It never mutates the economy,
## creates offers, or adds collision/navigation objects.
const BOARD_ORIGIN := Vector3(-11.70, 0.0, 0.0)
const BOARD_ROTATION := Vector3(0.0, 90.0, 0.0)
const FOCUS_POINT := Vector3(-11.46, 2.08, 0.0)
# Tight physical bounds preserve 3.6 cm beyond the imported standing chicken's
# audited 32.9 cm lateral radius at the nearest feed-party attendance socket.
const FOOTPRINT := Rect2(Vector2(-11.82, -1.66), Vector2(0.46, 3.32))
const MAX_OPAQUE_HEIGHT := 3.30
const OFFER_SLOT_COUNT := 3
# Host-attached print sits just proud of its physical face so it reads as ink
# and shallow hardware rather than a floating UI card.
const HOST_SIGN_CLEARANCE := 0.008

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

const ENAMEL_GREEN := Color("294b45")
const DEEP_GREEN := Color("1f3835")
const SAGE := Color("63766b")
const CREAM := Color("e5dcc2")
const PAPER := Color("ddd2b7")
const KRAFT := Color("b58d59")
const TIMBER := Color("73543b")
const DARK_TIMBER := Color("4c3b31")
const BRASS := Color("c09b4e")
const GRAPHITE := Color("293235")
const BARN_RED := Color("914a40")
const OXIDE := Color("6b3935")
const SUCCESS_GREEN := Color("5f8e68")
const SUCCESS_INK := Color("dce9cc")
const AMBER := Color("d2a44a")

var _board_shell_root: Node3D
var _locked_root: Node3D
var _open_root: Node3D
var _idle_terms_root: Node3D
var _active_summary_root: Node3D
var _season_medallion_root: Node3D
var _active_rider_root: Node3D
var _success_root: Node3D
var _breach_root: Node3D

var _offer_folder_roots: Array[Node3D] = []
var _offer_name_labels: Array[Label3D] = []
var _offer_terms_labels: Array[Label3D] = []
var _offer_rush_roots: Array[Node3D] = []
var _offer_rush_labels: Array[Label3D] = []
var _offer_risk_labels: Array[Label3D] = []
var _offer_active_clips: Array[Node3D] = []
var _premium_coins_by_slot: Dictionary[int, Array] = {}
var _lane_tokens_by_slot: Dictionary[int, Dictionary] = {}
var _active_summary_label: Label3D
var _season_label: Label3D
var _active_rider_label: Label3D
var _active_rider_category_strip: MeshInstance3D
var _success_detail_label: Label3D
var _breach_detail_label: Label3D

var _material_cache: Dictionary[String, StandardMaterial3D] = {}
var _built := false
var _unlocked := false
var _offers: Array[Dictionary] = []
var _active: Dictionary = {}
var _season_key := ""
var _has_season := false
var _active_clause_id: StringName = &""
var _active_clause_label := ""
var _active_clause_category: StringName = &""
var _last_result: Variant = null
var _result_state: StringName = &"none"


func _ready() -> void:
	name = "FarmMutualContractBoardVisual"
	_apply_authored_transform()
	if not _built:
		build()


static func declared_footprint() -> Rect2:
	return FOOTPRINT


static func facility_footprint() -> Rect2:
	return FOOTPRINT


static func board_focus_point() -> Vector3:
	return FOCUS_POINT


static func facility_focus_point() -> Vector3:
	return FOCUS_POINT


static func maximum_visual_height() -> float:
	return MAX_OPAQUE_HEIGHT


func focus_point_global() -> Vector3:
	# The office composes this module directly beneath its identity transform.
	# Keeping the focus point authored in world coordinates makes camera purchase
	# focus stable even before the first snapshot has reached the board.
	if get_parent_node_3d() == null:
		return FOCUS_POINT
	return get_parent_node_3d().to_global(FOCUS_POINT)


func build() -> void:
	clear()
	_apply_authored_transform()
	_built = true
	_build_board_shell()
	_build_locked_cover()
	_build_open_board()
	_build_result_hardware()
	_apply_visual_state()


func clear() -> void:
	for visual_root in [
		_board_shell_root,
		_locked_root,
		_open_root,
		_active_summary_root,
		_success_root,
		_breach_root,
	]:
		if visual_root != null and is_instance_valid(visual_root):
			visual_root.free()
	_board_shell_root = null
	_locked_root = null
	_open_root = null
	_idle_terms_root = null
	_active_summary_root = null
	_season_medallion_root = null
	_active_rider_root = null
	_success_root = null
	_breach_root = null
	_offer_folder_roots.clear()
	_offer_name_labels.clear()
	_offer_terms_labels.clear()
	_offer_rush_roots.clear()
	_offer_rush_labels.clear()
	_offer_risk_labels.clear()
	_offer_active_clips.clear()
	_premium_coins_by_slot.clear()
	_lane_tokens_by_slot.clear()
	_active_summary_label = null
	_season_label = null
	_active_rider_label = null
	_active_rider_category_strip = null
	_success_detail_label = null
	_breach_detail_label = null
	_material_cache.clear()
	_built = false


func apply_snapshot(snapshot: Dictionary) -> void:
	if not _built:
		build()
	var board_variant: Variant = snapshot.get("contract_board", {})
	var board := board_variant as Dictionary if board_variant is Dictionary else {}
	_unlocked = bool(board.get("unlocked", false))
	_offers = _normalize_offers(board.get("offers", []))
	_active = _normalize_contract(board.get("active", board.get("active_contract", {})))
	var season_variant: Variant = board.get("season", board.get("contract_season", null))
	_has_season = board.has("season") or board.has("contract_season")
	_season_key = _season_copy(season_variant) if _has_season else ""
	_active_clause_id = StringName(String(_active.get("clause_id", "")))
	_active_clause_label = String(_active.get("clause_label", _active.get("label", ""))).strip_edges()
	_active_clause_category = StringName(String(_active.get(
		"clause_category",
		_active.get("category", ""),
	)))
	_last_result = board.get("last_result", null)
	_result_state = _classify_result(_last_result)
	_apply_visual_state()


func visual_state() -> StringName:
	if not _unlocked:
		return &"locked"
	if not _active.is_empty():
		return &"active"
	if _result_state in [&"success", &"breach"]:
		return _result_state
	return &"open"


func is_unlocked() -> bool:
	return _unlocked


func visible_offer_count() -> int:
	var count := 0
	for folder in _offer_folder_roots:
		if folder.visible and _unlocked:
			count += 1
	return count


func offer_folder_visible(slot_index: int) -> bool:
	return (
		slot_index >= 0
		and slot_index < _offer_folder_roots.size()
		and _offer_folder_roots[slot_index].visible
		and _unlocked
	)


func offer_label_text(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= _offer_name_labels.size():
		return ""
	return _offer_name_labels[slot_index].text


func active_contract_id() -> StringName:
	return StringName(_active.get("id", &""))


func season_medallion_visible() -> bool:
	return _season_medallion_root != null and _season_medallion_root.visible


func season_key() -> String:
	return _season_key


func active_rider_visible() -> bool:
	return _active_rider_root != null and _active_rider_root.visible


func active_clause_id() -> StringName:
	return _active_clause_id


func active_clause_category() -> StringName:
	return _active_clause_category


func result_state() -> StringName:
	return _result_state


func active_stamp_visible() -> bool:
	return _active_summary_root != null and _active_summary_root.visible


func success_stamp_visible() -> bool:
	return _success_root != null and _success_root.visible


func breach_stamp_visible() -> bool:
	return _breach_root != null and _breach_root.visible


func debug_state() -> Dictionary:
	return {
		"visual_state": visual_state(),
		"unlocked": _unlocked,
		"offer_count": _offers.size(),
		"visible_offer_count": visible_offer_count(),
		"active_contract_id": active_contract_id(),
		"season": _season_key,
		"has_season": _has_season,
		"season_medallion_visible": season_medallion_visible(),
		"active_clause_id": _active_clause_id,
		"active_clause_label": _active_clause_label,
		"active_clause_category": _active_clause_category,
		"active_rider_visible": active_rider_visible(),
		"result_state": _result_state,
		"active_stamp_visible": active_stamp_visible(),
		"success_stamp_visible": success_stamp_visible(),
		"breach_stamp_visible": breach_stamp_visible(),
		"footprint": FOOTPRINT,
		"focus_point": FOCUS_POINT,
	}


func geometry_bounds_inside_footprint() -> bool:
	## Audits every authored tier, including currently hidden shutters and stamps.
	## The footprint is a thin wall parcel, so this catches accidental prop depth
	## that could otherwise enter the feed-party circulation space.
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
					var world_corner := instance.to_global(Vector3(
						corner_x,
						corner_y,
						corner_z,
					))
					if (
						world_corner.x < FOOTPRINT.position.x - tolerance
						or world_corner.x > FOOTPRINT.end.x + tolerance
						or world_corner.z < FOOTPRINT.position.y - tolerance
						or world_corner.z > FOOTPRINT.end.y + tolerance
						or world_corner.y > MAX_OPAQUE_HEIGHT + tolerance
					):
						return false
	return true


func geometry_bounds_global() -> AABB:
	## Debug aid for layout/integration tests. Includes hidden state geometry so an
	## authored shutter or outcome stamp cannot silently exceed the wall parcel.
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


func _apply_authored_transform() -> void:
	position = BOARD_ORIGIN
	rotation_degrees = BOARD_ROTATION


func _apply_visual_state() -> void:
	if _locked_root != null:
		_locked_root.visible = not _unlocked
	if _open_root != null:
		_open_root.visible = _unlocked
	if _season_medallion_root != null:
		_season_medallion_root.visible = _unlocked and _has_season
	if _season_label != null:
		_season_label.text = _season_key if not _season_key.is_empty() else "SEASON"
		EnvironmentalSignageScript.refit_label(_season_label)
	var negotiated_rider := _has_negotiated_rider()
	if _active_rider_root != null:
		_active_rider_root.visible = _unlocked and not _active.is_empty() and negotiated_rider
	if _active_rider_label != null:
		_active_rider_label.text = _active_rider_copy()
		EnvironmentalSignageScript.refit_label(_active_rider_label)
	if _active_rider_category_strip != null:
		_active_rider_category_strip.material_override = _material(
			_clause_category_color(_active_clause_category), 0.60, 0.10
		)

	var active_id := active_contract_id()
	for slot_index in _offer_folder_roots.size():
		var has_offer := _unlocked and slot_index < _offers.size()
		var offer := _offers[slot_index] if has_offer else {}
		_offer_folder_roots[slot_index].visible = has_offer
		if not has_offer:
			_offer_active_clips[slot_index].visible = false
			continue
		_apply_offer(slot_index, offer, active_id)

	if _active_summary_root != null:
		_active_summary_root.visible = _unlocked and not _active.is_empty()
	if _idle_terms_root != null:
		_idle_terms_root.visible = (
			_unlocked
			and _active.is_empty()
			and _result_state == &"none"
		)
	if _active_summary_label != null:
		_active_summary_label.text = _active_summary_text()
		EnvironmentalSignageScript.refit_label(_active_summary_label)
	if _success_root != null:
		_success_root.visible = (
			_unlocked
			and _active.is_empty()
			and _result_state == &"success"
		)
	if _breach_root != null:
		_breach_root.visible = (
			_unlocked
			and _active.is_empty()
			and _result_state == &"breach"
		)
	if _success_detail_label != null:
		_success_detail_label.text = _result_detail_text(true)
		EnvironmentalSignageScript.refit_label(_success_detail_label)
	if _breach_detail_label != null:
		_breach_detail_label.text = _result_detail_text(false)
		EnvironmentalSignageScript.refit_label(_breach_detail_label)


func _apply_offer(slot_index: int, offer: Dictionary, active_id: StringName) -> void:
	var offer_id := StringName(offer.get("id", &""))
	var offer_name := String(offer.get("name", "MUTUAL TERM %d" % (slot_index + 1)))
	_offer_name_labels[slot_index].text = offer_name.to_upper()
	EnvironmentalSignageScript.refit_label(_offer_name_labels[slot_index])

	var required := maxi(0, int(offer.get("required_completed", 0)))
	var deadline := maxi(0, int(offer.get("deadline_day", 0)))
	var premium := maxi(0, int(offer.get("premium_cents", 0)))
	_offer_terms_labels[slot_index].text = "%02d FILES  ·  D%02d\nPREM %s" % [
		required,
		deadline,
		_money_compact(premium),
	]
	EnvironmentalSignageScript.refit_label(_offer_terms_labels[slot_index])

	var breach := maxi(0, int(offer.get("breach_cents", 0)))
	_offer_risk_labels[slot_index].text = "RISK %s" % _money_compact(breach)
	EnvironmentalSignageScript.refit_label(_offer_risk_labels[slot_index])

	var rush_claims := maxi(0, int(offer.get("rush_claims", 0)))
	_offer_rush_roots[slot_index].visible = rush_claims > 0
	_offer_rush_labels[slot_index].text = "RUSH %d" % rush_claims
	EnvironmentalSignageScript.refit_label(_offer_rush_labels[slot_index])

	_offer_active_clips[slot_index].visible = (
		not active_id.is_empty()
		and not offer_id.is_empty()
		and offer_id == active_id
	)
	_apply_lane_tokens(slot_index, offer.get("lane_mix", {}))
	_apply_premium_coins(slot_index, premium)


func _apply_lane_tokens(slot_index: int, lane_mix_variant: Variant) -> void:
	var lane_mix := lane_mix_variant as Dictionary if lane_mix_variant is Dictionary else {}
	var tokens: Dictionary = _lane_tokens_by_slot.get(slot_index, {})
	for lane in LANE_ORDER:
		var token := tokens.get(lane) as MeshInstance3D
		if token == null:
			continue
		var count := maxi(0, int(lane_mix.get(lane, lane_mix.get(String(lane), 0))))
		token.visible = count > 0
		token.scale.x = clampf(0.72 + float(count) * 0.12, 0.72, 1.32)


func _apply_premium_coins(slot_index: int, premium_cents: int) -> void:
	var coins: Array = _premium_coins_by_slot.get(slot_index, [])
	var visible_coins := (
		clampi(ceili(float(premium_cents) / 4000.0), 1, coins.size())
		if premium_cents > 0
		else 0
	)
	for coin_index in coins.size():
		var coin := coins[coin_index] as Node3D
		if coin != null:
			coin.visible = coin_index < visible_coins


func _build_board_shell() -> void:
	_board_shell_root = Node3D.new()
	_board_shell_root.name = "FarmMutualContractBoardShell"
	add_child(_board_shell_root)

	# Shallow cleats visibly tie the fixture to the masonry without entering the
	# usable floor. The authored +Z face points into the room after root rotation.
	for cleat_x in [-1.22, 1.22]:
		_add_box(
			_board_shell_root, "ContractBoardWallCleat",
			Vector3(0.16, 1.74, 0.08), Vector3(cleat_x, 2.05, -0.075),
			DARK_TIMBER, 0.70, 0.10,
		)
	_add_box(
		_board_shell_root, "ContractBoardBack",
		Vector3(3.18, 2.18, 0.12), Vector3(0.0, 2.08, 0.0),
		DEEP_GREEN, 0.80, 0.06,
	)
	_add_box(
		_board_shell_root, "ContractBoardCorkInset",
		Vector3(2.92, 1.92, 0.035), Vector3(0.0, 2.03, 0.079),
		Color("8a7659"), 0.96,
	)
	for frame_x in [-1.58, 1.58]:
		_add_box(
			_board_shell_root, "ContractBoardSideFrame",
			Vector3(0.14, 2.30, 0.16), Vector3(frame_x, 2.08, 0.055),
			TIMBER, 0.70, 0.12,
		)
	for frame_y in [0.93, 3.23]:
		_add_box(
			_board_shell_root, "ContractBoardTopBottomFrame",
			Vector3(3.30, 0.14, 0.16), Vector3(0.0, frame_y, 0.055),
			TIMBER, 0.70, 0.12,
		)
	var header_host := _add_box(
		_board_shell_root, "FarmMutualHeaderHost",
		Vector3(2.76, 0.44, 0.075), Vector3(0.0, 2.94, 0.105),
		ENAMEL_GREEN, 0.68, 0.12,
	)
	EnvironmentalSignageScript.add_panel(
		header_host, "FarmMutualContractBoardHeader",
		"FARM MUTUAL\nCONTRACT & INDEMNITY BOARD",
		Vector3(0.0, 0.0, 0.0375 + HOST_SIGN_CLEARANCE), Vector2(2.48, 0.35),
		ENAMEL_GREEN, CREAM, Vector3.ZERO,
		17, 0.0032, &"secondary", &"board_header",
	)
	_build_season_medallion(_board_shell_root)
	for rivet_x in [-1.45, 1.45]:
		for rivet_y in [1.04, 3.12]:
			var rivet := _add_cylinder(
				_board_shell_root, "ContractBoardFrameRivet",
				Vector3(rivet_x, rivet_y, 0.145), 0.035, 0.022,
				BRASS, 0.36, 0.56,
			)
			rivet.rotation_degrees.x = 90.0


func _build_locked_cover() -> void:
	_locked_root = Node3D.new()
	_locked_root.name = "FarmMutualContractBoardLocked"
	add_child(_locked_root)

	for shutter_index in 2:
		var shutter_x := -0.76 + shutter_index * 1.52
		var shutter := _add_box(
			_locked_root, "ContractBoardClosedShutter_%d" % shutter_index,
			Vector3(1.42, 1.56, 0.09), Vector3(shutter_x, 1.98, 0.135),
			SAGE.darkened(0.06), 0.74, 0.08,
		)
		for slat_index in 5:
			_add_box(
				shutter, "ContractShutterSlat",
				Vector3(1.20, 0.045, 0.025),
				Vector3(0.0, -0.55 + slat_index * 0.27, 0.060),
				DEEP_GREEN.lightened(0.08), 0.68,
			)
	var lock_plate := _add_box(
		_locked_root, "ContractBoardLockPlate",
		Vector3(1.48, 0.54, 0.10), Vector3(0.0, 1.95, 0.225),
		GRAPHITE, 0.54, 0.26,
	)
	EnvironmentalSignageScript.add_panel(
		lock_plate, "ContractBoardLockedNotice",
		"MUTUAL TERMS SEALED\nBOARD AUTHORIZATION PENDING",
		Vector3(0.0, 0.0, 0.050 + HOST_SIGN_CLEARANCE), Vector2(1.24, 0.40),
		GRAPHITE, CREAM, Vector3.ZERO,
		12, 0.0026, &"secondary", &"machine",
	)
	var lock := _add_box(
		_locked_root, "ContractBoardBrassLock",
		Vector3(0.28, 0.32, 0.12), Vector3(0.0, 1.45, 0.230),
		BRASS, 0.34, 0.62,
	)
	_add_cylinder(
		lock, "ContractBoardKeyhole",
		Vector3(0.0, 0.0, 0.075), 0.044, 0.026,
		GRAPHITE, 0.48, 0.12,
	).rotation_degrees.x = 90.0
	# Two linked bars make the lock hardware read as a deliberate physical seal.
	for link_side in [-1.0, 1.0]:
		var chain := _add_cylinder(
			_locked_root, "ContractBoardSealLink",
			Vector3(link_side * 0.38, 1.59, 0.245), 0.035, 0.72,
			BRASS.darkened(0.12), 0.38, 0.56,
		)
		chain.rotation_degrees.z = link_side * 58.0


func _build_open_board() -> void:
	_open_root = Node3D.new()
	_open_root.name = "FarmMutualContractBoardOpen"
	add_child(_open_root)

	for slot_index in OFFER_SLOT_COUNT:
		_build_offer_slot(_open_root, slot_index)
	_idle_terms_root = Node3D.new()
	_idle_terms_root.name = "FarmMutualOpenTermsRail"
	_open_root.add_child(_idle_terms_root)
	var terms_host := _add_box(
		_idle_terms_root, "ContractTermsRail",
		Vector3(2.84, 0.40, 0.075), Vector3(0.0, 1.18, 0.112),
		ENAMEL_GREEN.darkened(0.04), 0.66, 0.14,
	)
	EnvironmentalSignageScript.add_panel(
		terms_host, "ContractTermsRailCaption",
		"PREMIUM IN · INDEMNITY OUT · DEADLINES ARE BINDING",
		Vector3(0.0, 0.0, 0.0375 + HOST_SIGN_CLEARANCE), Vector2(2.56, 0.22),
		ENAMEL_GREEN, CREAM, Vector3.ZERO,
		9, 0.0019, &"utility", &"stencil",
	)


func _build_offer_slot(parent: Node3D, slot_index: int) -> void:
	var slot_x := -0.98 + slot_index * 0.98
	var pocket := Node3D.new()
	pocket.name = "ContractOfferPocket_%d" % slot_index
	pocket.position = Vector3(slot_x, 0.0, 0.0)
	parent.add_child(pocket)

	# Permanent galvanized pockets prove that the board has exactly three terms,
	# even when fewer offers are currently posted.
	_add_box(
		pocket, "ContractFolderPocketBack",
		Vector3(0.86, 0.90, 0.055), Vector3(0.0, 2.04, 0.108),
		SAGE.darkened(0.10), 0.72, 0.18,
	)
	_add_box(
		pocket, "ContractFolderPocketLip",
		Vector3(0.86, 0.24, 0.09), Vector3(0.0, 1.66, 0.170),
		SAGE, 0.66, 0.22,
	)
	for pocket_side in [-1.0, 1.0]:
		_add_box(
			pocket, "ContractFolderPocketSide",
			Vector3(0.055, 0.88, 0.10), Vector3(pocket_side * 0.405, 2.04, 0.155),
			SAGE, 0.66, 0.22,
		)
	var slot_host := _add_box(
		pocket, "ContractSlotNumberHost",
		Vector3(0.28, 0.16, 0.04), Vector3(0.0, 1.55, 0.225),
		GRAPHITE, 0.58, 0.16,
	)
	EnvironmentalSignageScript.add_panel(
		slot_host, "ContractSlotNumber_%d" % slot_index,
		"TERM %s" % String.chr(65 + slot_index),
		Vector3(0.0, 0.0, 0.020 + HOST_SIGN_CLEARANCE), Vector2(0.23, 0.09),
		GRAPHITE, CREAM, Vector3.ZERO,
		8, 0.0015, &"utility", &"machine",
	)

	var folder := Node3D.new()
	folder.name = "FarmMutualOfferFolder_%d" % slot_index
	folder.position = Vector3(0.0, 0.0, 0.0)
	pocket.add_child(folder)
	_offer_folder_roots.append(folder)
	var folder_body := _add_box(
		folder, "ContractOfferFolderBody",
		Vector3(0.74, 0.82, 0.075), Vector3(0.0, 2.12, 0.205),
		KRAFT.lightened(0.02 * slot_index), 0.92,
	)
	_add_box(
		folder, "ContractOfferFolderTab",
		Vector3(0.33, 0.12, 0.085), Vector3(-0.18, 2.58, 0.205),
		KRAFT.lightened(0.09), 0.90,
	)
	_offer_name_labels.append(EnvironmentalSignageScript.add_panel(
		folder_body, "ContractOfferName_%d" % slot_index,
		"MUTUAL TERM %d" % (slot_index + 1),
		Vector3(0.0, 0.22, 0.0375 + HOST_SIGN_CLEARANCE), Vector2(0.62, 0.18),
		PAPER, GRAPHITE, Vector3.ZERO,
		10, 0.0020, &"secondary", &"shipping",
	))
	_offer_terms_labels.append(EnvironmentalSignageScript.add_panel(
		folder_body, "ContractOfferTerms_%d" % slot_index,
		"00 FILES  ·  D00\nPREM $0",
		Vector3(0.0, -0.03, 0.0375 + HOST_SIGN_CLEARANCE), Vector2(0.60, 0.27),
		PAPER, GRAPHITE, Vector3.ZERO,
		9, 0.0018, &"utility", &"paper",
	))
	_offer_risk_labels.append(EnvironmentalSignageScript.add_panel(
		folder_body, "ContractOfferRisk_%d" % slot_index,
		"RISK $0",
		Vector3(0.0, -0.29, 0.0375 + HOST_SIGN_CLEARANCE), Vector2(0.54, 0.13),
		BARN_RED, CREAM, Vector3.ZERO,
		8, 0.0016, &"utility", &"stencil",
	))

	var rush_root := Node3D.new()
	rush_root.name = "ContractRushTag_%d" % slot_index
	rush_root.position = Vector3(0.31, 2.48, 0.275)
	folder.add_child(rush_root)
	var rush_host := _add_box(
		rush_root, "ContractRushTagHost",
		Vector3(0.28, 0.16, 0.035), Vector3.ZERO,
		BARN_RED, 0.76,
	)
	_offer_rush_labels.append(EnvironmentalSignageScript.add_panel(
		rush_host, "ContractRushTagText_%d" % slot_index,
		"RUSH 0",
		Vector3(0.0, 0.0, 0.0175 + HOST_SIGN_CLEARANCE), Vector2(0.24, 0.10),
		BARN_RED, CREAM, Vector3.ZERO,
		8, 0.0015, &"utility", &"stencil",
	))
	_offer_rush_roots.append(rush_root)

	var active_clip := Node3D.new()
	active_clip.name = "ActiveContractClip_%d" % slot_index
	active_clip.position = Vector3(0.0, 2.68, 0.250)
	folder.add_child(active_clip)
	_add_box(active_clip, "ActiveClipJaw", Vector3(0.42, 0.10, 0.08), Vector3.ZERO, BRASS, 0.38, 0.58)
	_add_box(active_clip, "ActiveClipHandle", Vector3(0.18, 0.18, 0.07), Vector3(0.0, 0.11, 0.0), GRAPHITE, 0.52, 0.22)
	_offer_active_clips.append(active_clip)

	var tokens: Dictionary = {}
	for lane_index in LANE_ORDER.size():
		var lane := LANE_ORDER[lane_index]
		var lane_token := _add_box(
			folder, "ContractLaneToken_%s" % lane,
			Vector3(0.16, 0.065, 0.035),
			Vector3(-0.21 + lane_index * 0.21, 1.67, 0.275),
			LANE_COLORS[lane], 0.58, 0.10,
		)
		tokens[lane] = lane_token
	_lane_tokens_by_slot[slot_index] = tokens

	var coins: Array = []
	for coin_index in 3:
		var coin := _add_cylinder(
			folder, "ContractPremiumCoin_%d" % coin_index,
			Vector3(0.22 + coin_index * 0.075, 1.74 + coin_index * 0.035, 0.295),
			0.072, 0.026, BRASS, 0.34, 0.62,
		)
		coin.rotation_degrees.x = 90.0
		coins.append(coin)
	_premium_coins_by_slot[slot_index] = coins


func _build_result_hardware() -> void:
	_active_summary_root = Node3D.new()
	_active_summary_root.name = "FarmMutualActiveContractStamp"
	add_child(_active_summary_root)
	var active_host := _add_box(
		_active_summary_root, "ActiveContractSummaryHost",
		Vector3(2.48, 0.34, 0.075), Vector3(0.0, 1.18, 0.190),
		BRASS.darkened(0.22), 0.54, 0.34,
	)
	_active_summary_label = EnvironmentalSignageScript.add_panel(
		active_host, "ActiveContractSummary",
		"BOUND · ACTIVE MUTUAL TERM",
		Vector3(0.0, 0.0, 0.0375 + HOST_SIGN_CLEARANCE), Vector2(2.18, 0.20),
		ENAMEL_GREEN, CREAM, Vector3.ZERO,
		10, 0.0020, &"secondary", &"machine",
	)
	for clip_x in [-1.12, 1.12]:
		_add_box(
			_active_summary_root, "ActiveSummaryBinderClip",
			Vector3(0.12, 0.42, 0.09), Vector3(clip_x, 1.18, 0.220),
			BRASS, 0.36, 0.62,
		)
	_build_active_rider_slip(_open_root)

	_success_root = Node3D.new()
	_success_root.name = "FarmMutualSuccessStamp"
	add_child(_success_root)
	var success_host := _add_box(
		_success_root, "ContractSuccessStampHost",
		Vector3(1.62, 0.42, 0.090), Vector3(0.0, 1.18, 0.225),
		SUCCESS_GREEN, 0.70, 0.08,
	)
	EnvironmentalSignageScript.add_panel(
		success_host, "ContractSuccessStampTitle",
		"MUTUAL PAID",
		Vector3(0.0, 0.08, 0.045 + HOST_SIGN_CLEARANCE), Vector2(1.34, 0.16),
		SUCCESS_GREEN, SUCCESS_INK, Vector3.ZERO,
		11, 0.0022, &"secondary", &"stencil",
	)
	_success_detail_label = EnvironmentalSignageScript.add_panel(
		success_host, "ContractSuccessStampDetail",
		"TERM SATISFIED",
		Vector3(0.0, -0.10, 0.045 + HOST_SIGN_CLEARANCE), Vector2(1.26, 0.12),
		SUCCESS_GREEN, SUCCESS_INK, Vector3.ZERO,
		8, 0.0016, &"utility", &"stencil",
	)
	_build_rubber_stamp(_success_root, Vector3(1.12, 1.48, 0.245), SUCCESS_GREEN.darkened(0.18))

	_breach_root = Node3D.new()
	_breach_root.name = "FarmMutualBreachStamp"
	add_child(_breach_root)
	var breach_host := _add_box(
		_breach_root, "ContractBreachStampHost",
		Vector3(1.62, 0.42, 0.090), Vector3(0.0, 1.18, 0.225),
		BARN_RED, 0.72, 0.06,
	)
	EnvironmentalSignageScript.add_panel(
		breach_host, "ContractBreachStampTitle",
		"TERM BREACHED",
		Vector3(0.0, 0.08, 0.045 + HOST_SIGN_CLEARANCE), Vector2(1.34, 0.16),
		BARN_RED, CREAM, Vector3.ZERO,
		11, 0.0022, &"secondary", &"stencil",
	)
	_breach_detail_label = EnvironmentalSignageScript.add_panel(
		breach_host, "ContractBreachStampDetail",
		"INDEMNITY DUE",
		Vector3(0.0, -0.10, 0.045 + HOST_SIGN_CLEARANCE), Vector2(1.26, 0.12),
		BARN_RED, CREAM, Vector3.ZERO,
		8, 0.0016, &"utility", &"stencil",
	)
	_build_rubber_stamp(_breach_root, Vector3(-1.12, 1.48, 0.245), OXIDE)


func _build_season_medallion(parent: Node3D) -> void:
	## The brass disk remains legible as physical season hardware in overview;
	## its long-form copy is utility-tier ink and appears only in detail views.
	_season_medallion_root = Node3D.new()
	_season_medallion_root.name = "FarmMutualSeasonMedallion"
	_season_medallion_root.set_meta(&"authoritative_record_only", true)
	parent.add_child(_season_medallion_root)
	var rim := _add_cylinder(
		_season_medallion_root, "FarmMutualSeasonMedallionRim",
		Vector3(1.31, 2.94, 0.205), 0.205, 0.035,
		BRASS, 0.38, 0.62,
	)
	rim.rotation_degrees.x = 90.0
	var face := _add_cylinder(
		_season_medallion_root, "FarmMutualSeasonMedallionFace",
		Vector3(1.31, 2.94, 0.229), 0.164, 0.022,
		ENAMEL_GREEN, 0.68, 0.12,
	)
	face.rotation_degrees.x = 90.0
	var copy_host := _add_box(
		_season_medallion_root, "FarmMutualSeasonCopyHost",
		Vector3(0.31, 0.12, 0.022), Vector3(1.31, 2.94, 0.247),
		ENAMEL_GREEN, 0.70, 0.10,
	)
	_season_label = EnvironmentalSignageScript.add_panel(
		copy_host, "FarmMutualSeasonCopy", "SEASON",
		Vector3(0.0, 0.0, 0.011 + HOST_SIGN_CLEARANCE), Vector2(0.27, 0.09),
		ENAMEL_GREEN, CREAM, Vector3.ZERO,
		8, 0.0014, &"utility", &"machine",
	)


func _build_active_rider_slip(parent: Node3D) -> void:
	## Exactly one rider slip exists. It is hidden for legacy and standard-term
	## binders, preventing a base contract from looking contractually modified.
	_active_rider_root = Node3D.new()
	_active_rider_root.name = "FarmMutualActiveRiderSlip"
	_active_rider_root.position = Vector3(0.78, 1.40, 0.258)
	_active_rider_root.rotation_degrees.z = -3.0
	_active_rider_root.set_meta(&"authoritative_record_only", true)
	parent.add_child(_active_rider_root)
	var paper_host := _add_box(
		_active_rider_root, "ActiveClauseRiderPaper",
		Vector3(1.04, 0.29, 0.025), Vector3.ZERO,
		PAPER, 0.96,
	)
	_active_rider_category_strip = _add_box(
		_active_rider_root, "ActiveClauseCategoryStrip",
		Vector3(0.075, 0.25, 0.036), Vector3(-0.475, 0.0, 0.018),
		SAGE, 0.60, 0.10,
	)
	_add_box(
		_active_rider_root, "ActiveClauseRiderClip",
		Vector3(0.22, 0.10, 0.055), Vector3(-0.31, 0.15, 0.034),
		BRASS, 0.36, 0.62,
	)
	_active_rider_label = EnvironmentalSignageScript.add_panel(
		paper_host, "ActiveClauseRiderCopy", "RIDER",
		Vector3(0.035, -0.005, 0.0125 + HOST_SIGN_CLEARANCE), Vector2(0.86, 0.21),
		PAPER, GRAPHITE, Vector3.ZERO,
		9, 0.0017, &"utility", &"paper",
	)


func _build_rubber_stamp(parent: Node3D, stamp_position: Vector3, color: Color) -> void:
	var stamp := Node3D.new()
	stamp.name = "PhysicalContractRubberStamp"
	stamp.position = stamp_position
	stamp.rotation_degrees.z = -9.0
	parent.add_child(stamp)
	_add_box(stamp, "RubberStampFoot", Vector3(0.38, 0.10, 0.18), Vector3.ZERO, color, 0.82)
	_add_box(stamp, "RubberStampStem", Vector3(0.13, 0.28, 0.13), Vector3(0.0, 0.16, -0.02), DARK_TIMBER, 0.72)
	_add_box(stamp, "RubberStampHandle", Vector3(0.34, 0.13, 0.14), Vector3(0.0, 0.32, -0.02), TIMBER, 0.66)


func _normalize_offers(value: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if value is Array:
		for entry_variant in value as Array:
			if entry_variant is Dictionary and normalized.size() < OFFER_SLOT_COUNT:
				normalized.append((entry_variant as Dictionary).duplicate(true))
	elif value is Dictionary:
		var keys := (value as Dictionary).keys()
		keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
		for key in keys:
			var entry_variant: Variant = (value as Dictionary).get(key)
			if entry_variant is Dictionary and normalized.size() < OFFER_SLOT_COUNT:
				var entry := (entry_variant as Dictionary).duplicate(true)
				if not entry.has("id"):
					entry["id"] = StringName(key)
				normalized.append(entry)
	return normalized


func _normalize_contract(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is String or value is StringName:
		var contract_id := StringName(value)
		for offer in _offers:
			if StringName(offer.get("id", &"")) == contract_id:
				return offer.duplicate(true)
		return {"id": contract_id, "name": String(value)}
	return {}


func _season_copy(value: Variant) -> String:
	if value is Dictionary:
		var season := value as Dictionary
		var label := String(season.get(
			"label",
			season.get("name", season.get("id", "")),
		)).strip_edges()
		return label.to_upper() if not label.is_empty() else "SEASON"
	if value is int or value is float:
		return "SEASON %02d" % int(value)
	var text := String(value).strip_edges()
	return text.to_upper() if not text.is_empty() else "SEASON"


func _has_negotiated_rider() -> bool:
	return _active_clause_id != &"" and _active_clause_id != &"standard_terms"


func _active_rider_copy() -> String:
	var label := _active_clause_label
	if label.is_empty() and _active_clause_id != &"":
		label = String(_active_clause_id).replace("_", " ").capitalize()
	if label.is_empty():
		return "RIDER"
	var category := String(_active_clause_category).replace("_", " ").to_upper()
	return (
		"%s\n%s" % [label.to_upper(), category]
		if not category.is_empty() and _active_clause_category != &"standard"
		else label.to_upper()
	)


func _clause_category_color(category: StringName) -> Color:
	match category:
		&"schedule", &"delivery", &"throughput":
			return AMBER
		&"routing", &"specialist", &"quality":
			return Color("6f88a2")
		&"welfare", &"rest", &"staffing":
			return SUCCESS_GREEN
		&"risk", &"breach", &"compliance":
			return BARN_RED
	return SAGE


func _classify_result(value: Variant) -> StringName:
	if value == null:
		return &"none"
	if value is Dictionary:
		var result := value as Dictionary
		if bool(result.get("breached", false)) or bool(result.get("failed", false)):
			return &"breach"
		if bool(result.get("success", false)) or bool(result.get("completed", false)):
			return &"success"
		for key in ["status", "result", "outcome", "kind"]:
			if result.has(key):
				var classified := _classify_result(String(result[key]))
				if classified != &"none":
					return classified
		return &"none"
	var normalized := String(value).strip_edges().to_lower()
	for breach_word in ["breach", "failed", "failure", "default", "missed", "lost"]:
		if breach_word in normalized:
			return &"breach"
	for success_word in ["success", "completed", "complete", "paid", "fulfilled", "renewed", "won"]:
		if success_word in normalized:
			return &"success"
	return &"none"


func _active_summary_text() -> String:
	if _active.is_empty():
		return "BOUND · ACTIVE MUTUAL TERM"
	var name_text := String(_active.get("name", _active.get("id", "MUTUAL TERM"))).to_upper()
	var deadline := maxi(0, int(_active.get("deadline_day", 0)))
	return "BOUND · %s · D%02d" % [name_text, deadline]


func _result_detail_text(success: bool) -> String:
	var result := _last_result as Dictionary if _last_result is Dictionary else {}
	var name_text := String(result.get("name", result.get("contract_name", "TERM SATISFIED" if success else "INDEMNITY DUE"))).to_upper()
	if success:
		var payout := maxi(0, int(result.get("premium_cents", result.get("payout_cents", 0))))
		return "%s  %s" % [name_text, _money_compact(payout)] if payout > 0 else name_text
	var breach := maxi(0, int(result.get("breach_cents", result.get("penalty_cents", 0))))
	return "%s  %s" % [name_text, _money_compact(breach)] if breach > 0 else name_text


func _money_compact(cents: int) -> String:
	var safe_cents := maxi(0, cents)
	if safe_cents % 100 == 0:
		return "$%d" % int(safe_cents / 100)
	return "$%d.%02d" % [int(safe_cents / 100), safe_cents % 100]


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


func _material(
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0
) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f" % [color.to_html(true), roughness, metallic]
	if _material_cache.has(key):
		return _material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_material_cache[key] = material
	return material
