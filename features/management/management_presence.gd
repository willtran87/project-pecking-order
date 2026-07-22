class_name ManagementPresence
extends Node3D

## Visual-only management characters for the claims office. This node deliberately
## owns no physics bodies, so its patrol and review sequence cannot block workers.

signal review_finished

const ChickenModel: PackedScene = preload("res://assets/models/chicken_employee.glb")

const ANIMATION_IDLE: StringName = &"Chicken_Idle"
const ANIMATION_WALK: StringName = &"Chicken_Walk"
const MANAGER_PATROL_LEFT := Vector3(2.35, 0.0, -6.55)
const MANAGER_PATROL_RIGHT := Vector3(4.15, 0.0, -6.55)
const MANAGER_SPEED := 1.35
const MANAGER_SCALE := 1.13
const MANAGER_COMB_SCALE := 1.24
const MANAGER_PAUSE_SECONDS := 1.8
const FARMER_OFFSTAGE_POSITION := Vector3(13.8, 0.0, 4.3)
const FARMER_REVIEW_POSITION := Vector3(8.2, 0.0, 4.3)
const FARMER_REVIEW_DURATION := 2.4

const MANAGER_ACCESSORIES: Array[StringName] = [
	&"AccessoryHead_RoundGlasses",
	&"AccessoryHead_SquareGlasses",
	&"AccessoryHead_AccountantVisor",
	&"AccessoryHead_Headset",
	&"AccessoryHead_NewsboyCap",
	&"AccessoryHead_ReadingGlassesChain",
	&"AccessoryHead_Earmuffs",
	&"AccessoryHead_SleepMask",
	&"AccessoryComb_Pencil",
	&"BowTie",
	&"AccessoryNeck_LongTie",
	&"AccessoryNeck_Lanyard",
	&"AccessoryNeck_KnitScarf",
	&"AccessoryNeck_CardiganCollar",
	&"AccessoryNeck_Neckerchief",
	&"AccessoryBody_SweaterVest",
	&"AccessoryBody_PocketProtector",
	&"AccessoryBody_Satchel",
	&"AccessoryBody_TeaMugCharm",
	&"AccessoryBody_QuiltedCapelet",
	&"AccessoryBadge_Nameplate",
	&"AccessoryBadge_GoldenEgg",
	&"AccessoryLeg_Watch",
]
const MANAGER_VISIBLE_ACCESSORIES: Array[StringName] = [
	&"BowTie",
	&"AccessoryBadge_Nameplate",
]

var _manager_root: Node3D
var _manager_model: Node3D
var _manager_accessory_nodes: Dictionary[StringName, Node3D] = {}
var _manager_comb: Node3D
var _manager_comb_crown_anchor_local := Vector3.ZERO
var _manager_comb_crown_anchor_parent := Vector3.ZERO
var _manager_animation_player: AnimationPlayer
var _manager_animation_names: Dictionary[StringName, StringName] = {}
var _active_manager_animation: StringName = &""
var _manager_target := MANAGER_PATROL_RIGHT
var _manager_pause_remaining := 0.0
var _additional_managers: Array[Dictionary] = []
var _visible_roster_ids: Array[StringName] = []

var _farmer_root: Node3D
var _farmer_left_leg: Node3D
var _farmer_right_leg: Node3D
var _farmer_tween: Tween
var _farmer_is_reviewing := false
var _farmer_phase := 0.0


func _ready() -> void:
	name = "ManagementPresence"
	_build_manager()
	_build_farmer()


func _process(delta: float) -> void:
	_update_manager_patrol(delta)
	_update_additional_manager_patrol(delta)
	_update_farmer_walk(delta)


func apply_manager_roster(roster: Array) -> void:
	var roster_ids: Array[StringName] = []
	for manager_value in roster:
		if manager_value is Dictionary:
			roster_ids.append(StringName(String((manager_value as Dictionary).get("id", ""))))
	if roster_ids == _visible_roster_ids:
		return
	_visible_roster_ids = roster_ids
	for record in _additional_managers:
		var old_root := record.get("root") as Node3D
		if old_root != null and is_instance_valid(old_root):
			old_root.queue_free()
	_additional_managers.clear()
	for index in range(1, roster.size()):
		var manager_value: Variant = roster[index]
		if manager_value is Dictionary:
			_additional_managers.append(_build_additional_manager(manager_value as Dictionary, index))


## Plays the farmer's collection/review entrance once. Repeated calls while the
## sequence is active are ignored, preventing overlapping tweens and signals.
func play_review() -> void:
	if _farmer_is_reviewing or _farmer_root == null:
		return
	_farmer_is_reviewing = true
	_farmer_phase = 0.0
	_farmer_root.position = FARMER_OFFSTAGE_POSITION
	_farmer_root.visible = true
	_face_local_point(_farmer_root, Vector3(9.55, 0.0, 5.35))
	if _farmer_tween != null and _farmer_tween.is_valid():
		_farmer_tween.kill()
	_farmer_tween = create_tween()
	_farmer_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_farmer_tween.tween_property(_farmer_root, "position", FARMER_REVIEW_POSITION, 1.35)
	_farmer_tween.tween_interval(FARMER_REVIEW_DURATION)
	_farmer_tween.tween_callback(_begin_farmer_exit)
	_farmer_tween.tween_property(_farmer_root, "position", FARMER_OFFSTAGE_POSITION, 1.2)
	_farmer_tween.tween_callback(_finish_review)


## World-space camera target for the visible farmer review position.
func review_focus_point() -> Vector3:
	return to_global(FARMER_REVIEW_POSITION + Vector3(0.0, 1.45, 0.0))


## On-demand verification for the imported manager binding contract. Keeping
## this separate from _process means diagnostics never add frame-time work.
func model_binding_diagnostics() -> Dictionary:
	var visible_accessory_count := 0
	for accessory in _manager_accessory_nodes.values():
		if (accessory as Node3D).visible:
			visible_accessory_count += 1
	return {
		"accessory_nodes_cached": _manager_accessory_nodes.size(),
		"accessory_nodes_expected": MANAGER_ACCESSORIES.size(),
		"visible_accessory_count": visible_accessory_count,
		"visible_accessory_expected": MANAGER_VISIBLE_ACCESSORIES.size(),
		"comb_cached": _manager_comb != null,
		"comb_scale": _manager_comb.scale.x if _manager_comb != null else 0.0,
		"comb_attachment_error": _manager_comb_attachment_error(),
		"animation_player_cached": _manager_animation_player != null,
	}


func _build_manager() -> void:
	_manager_root = Node3D.new()
	_manager_root.name = "RoosterManager"
	_manager_root.position = MANAGER_PATROL_LEFT
	add_child(_manager_root)

	_manager_model = ChickenModel.instantiate() as Node3D
	_manager_model.name = "ManagerModel"
	_manager_model.scale = Vector3.ONE * MANAGER_SCALE
	_manager_root.add_child(_manager_model)
	_cache_manager_model_bindings()
	_recolor_manager_feathers()
	_configure_manager_accessories()
	_cache_manager_animations()
	_build_manager_clipboard()
	_build_manager_badge()


func _cache_manager_model_bindings() -> void:
	_manager_accessory_nodes.clear()
	for descendant in _all_children(_manager_model):
		if descendant is AnimationPlayer and _manager_animation_player == null:
			_manager_animation_player = descendant as AnimationPlayer
		if descendant.name == &"Comb" and descendant is Node3D:
			_manager_comb = descendant as Node3D
		var descendant_name := StringName(descendant.name)
		if descendant_name in MANAGER_ACCESSORIES and descendant is Node3D:
			_manager_accessory_nodes[descendant_name] = descendant as Node3D
	assert(
		_manager_accessory_nodes.size() == MANAGER_ACCESSORIES.size(),
		"Manager model accessory bindings are incomplete: found %d of %d"
			% [_manager_accessory_nodes.size(), MANAGER_ACCESSORIES.size()]
	)

func _recolor_manager_feathers() -> void:
	var charcoal := _make_material(Color("2d3037"), 0.86)
	var face := _make_material(Color("5a514b"), 0.88)
	var wing := _make_material(Color("181c23"), 0.82)
	for descendant in _all_children(_manager_model):
		if descendant is not MeshInstance3D or not descendant.name.begins_with("Feather_"):
			continue
		var mesh_instance := descendant as MeshInstance3D
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.mesh.surface_get_material(surface_index)
			var zone_name := source_material.resource_name if source_material != null else ""
			var replacement := charcoal
			if "Cream" in zone_name or "Belly" in zone_name or "Face" in zone_name:
				replacement = face
			elif "Wing" in zone_name or "Tail" in zone_name:
				replacement = wing
			mesh_instance.set_surface_override_material(surface_index, replacement)


func _configure_manager_accessories() -> void:
	for accessory_name in MANAGER_ACCESSORIES:
		var accessory := _manager_accessory_nodes.get(accessory_name) as Node3D
		if accessory != null:
			accessory.visible = accessory_name in MANAGER_VISIBLE_ACCESSORIES
	var executive_navy := _make_material(Color("233f59"), 0.48)
	for target_name in MANAGER_VISIBLE_ACCESSORIES:
		var target := _manager_accessory_nodes.get(target_name) as Node3D
		if target == null:
			continue
		for descendant in _all_children(target):
			if descendant is not MeshInstance3D:
				continue
			var mesh_instance := descendant as MeshInstance3D
			for surface_index in mesh_instance.mesh.get_surface_count():
				var source_material := mesh_instance.mesh.surface_get_material(surface_index)
				var material_name := source_material.resource_name if source_material != null else ""
				if "Corporate_Navy" in material_name or "Accessory_Cloth" in material_name:
					mesh_instance.set_surface_override_material(surface_index, executive_navy)
	_scale_manager_comb_from_crown()


func _scale_manager_comb_from_crown() -> void:
	## Imported rigid face pieces keep their mesh vertices in armature space, so
	## scaling the Comb node around its object origin also scales its distance
	## from the head. Preserve the lower-center crown contact point while making
	## the rooster's comb larger, keeping it seated through idle and walk poses.
	if _manager_comb is not MeshInstance3D:
		return
	var comb_mesh := _manager_comb as MeshInstance3D
	var bounds := comb_mesh.get_aabb()
	_manager_comb_crown_anchor_local = Vector3(
		bounds.get_center().x,
		bounds.position.y,
		bounds.get_center().z,
	)
	_manager_comb_crown_anchor_parent = (
		_manager_comb.transform * _manager_comb_crown_anchor_local
	)
	_manager_comb.scale *= MANAGER_COMB_SCALE
	var scaled_anchor_parent := (
		_manager_comb.transform * _manager_comb_crown_anchor_local
	)
	_manager_comb.position += _manager_comb_crown_anchor_parent - scaled_anchor_parent


func _manager_comb_attachment_error() -> float:
	if _manager_comb == null:
		return INF
	return (
		(_manager_comb.transform * _manager_comb_crown_anchor_local)
		.distance_to(_manager_comb_crown_anchor_parent)
	)


func _cache_manager_animations() -> void:
	if _manager_animation_player == null:
		return
	_manager_animation_player.playback_default_blend_time = 0.16
	for available_name in _manager_animation_player.get_animation_list():
		for requested_name in [ANIMATION_IDLE, ANIMATION_WALK]:
			if String(available_name).ends_with(String(requested_name)):
				_manager_animation_names[requested_name] = available_name
	_play_manager_animation(ANIMATION_IDLE)


func _play_manager_animation(requested_name: StringName) -> void:
	if _manager_animation_player == null or not _manager_animation_names.has(requested_name):
		return
	if _active_manager_animation == requested_name and _manager_animation_player.is_playing():
		return
	_active_manager_animation = requested_name
	_manager_animation_player.play(_manager_animation_names[requested_name])


func _update_manager_patrol(delta: float) -> void:
	if _manager_root == null:
		return
	if _manager_pause_remaining > 0.0:
		_manager_pause_remaining = maxf(0.0, _manager_pause_remaining - delta)
		_play_manager_animation(ANIMATION_IDLE)
		return

	var offset := _manager_target - _manager_root.position
	offset.y = 0.0
	if offset.length() <= 0.04:
		_manager_root.position = _manager_target
		_manager_target = MANAGER_PATROL_LEFT if _manager_target == MANAGER_PATROL_RIGHT else MANAGER_PATROL_RIGHT
		_manager_pause_remaining = MANAGER_PAUSE_SECONDS
		_play_manager_animation(ANIMATION_IDLE)
		return

	var direction := offset.normalized()
	_manager_root.position += direction * minf(MANAGER_SPEED * delta, offset.length())
	_manager_root.rotation.y = lerp_angle(
		_manager_root.rotation.y,
		atan2(direction.x, direction.z),
		minf(1.0, delta * 8.0)
	)
	_play_manager_animation(ANIMATION_WALK)


func _build_additional_manager(manager: Dictionary, index: int) -> Dictionary:
	var route_z := -5.62 if index >= 2 else -6.55
	var route_column := index % 2
	var left := Vector3(4.65 + route_column * 2.25, 0.0, route_z)
	var right := left + Vector3(1.35, 0.0, 0.0)
	var root := Node3D.new()
	root.name = "RoosterManager_%s" % String(manager.get("id", index))
	root.position = left
	add_child(root)
	var model := ChickenModel.instantiate() as Node3D
	model.name = "ManagerModel"
	model.scale = Vector3.ONE * (MANAGER_SCALE - 0.03 + 0.02 * float(index % 2))
	root.add_child(model)
	var accessory_name := StringName(String(manager.get("accessory", "BowTie")))
	var player: AnimationPlayer = null
	var animation_names: Dictionary[StringName, StringName] = {}
	for descendant in _all_children(model):
		if descendant is AnimationPlayer and player == null:
			player = descendant as AnimationPlayer
		var descendant_name := StringName(descendant.name)
		if descendant_name in MANAGER_ACCESSORIES and descendant is Node3D:
			(descendant as Node3D).visible = descendant_name in [accessory_name, &"AccessoryBadge_Nameplate"]
		if descendant.name == &"Comb" and descendant is MeshInstance3D:
			_scale_comb_from_crown(descendant as MeshInstance3D)
	_recolor_manager_model(model, Color(String(manager.get("color", "343941"))))
	if player != null:
		player.playback_default_blend_time = 0.16
		for available_name in player.get_animation_list():
			for requested_name in [ANIMATION_IDLE, ANIMATION_WALK]:
				if String(available_name).ends_with(String(requested_name)):
					animation_names[requested_name] = available_name
		if animation_names.has(ANIMATION_IDLE):
			player.play(animation_names[ANIMATION_IDLE])
	_build_roster_clipboard(root, index)
	return {
		"root": root,
		"player": player,
		"animations": animation_names,
		"active_animation": ANIMATION_IDLE,
		"left": left,
		"right": right,
		"target": right,
		"pause": float(index) * 0.35,
	}


func _recolor_manager_model(model: Node3D, base_color: Color) -> void:
	var charcoal := _make_material(base_color, 0.86)
	var face := _make_material(base_color.lightened(0.24), 0.88)
	var wing := _make_material(base_color.darkened(0.30), 0.82)
	for descendant in _all_children(model):
		if descendant is not MeshInstance3D or not descendant.name.begins_with("Feather_"):
			continue
		var mesh_instance := descendant as MeshInstance3D
		for surface_index in mesh_instance.mesh.get_surface_count():
			var source_material := mesh_instance.mesh.surface_get_material(surface_index)
			var zone_name := source_material.resource_name if source_material != null else ""
			var replacement := charcoal
			if "Cream" in zone_name or "Belly" in zone_name or "Face" in zone_name:
				replacement = face
			elif "Wing" in zone_name or "Tail" in zone_name:
				replacement = wing
			mesh_instance.set_surface_override_material(surface_index, replacement)


func _scale_comb_from_crown(comb: MeshInstance3D) -> void:
	var bounds := comb.get_aabb()
	var anchor_local := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	var anchor_parent := comb.transform * anchor_local
	comb.scale *= MANAGER_COMB_SCALE
	comb.position += anchor_parent - comb.transform * anchor_local


func _build_roster_clipboard(root: Node3D, index: int) -> void:
	var clipboard := Node3D.new()
	clipboard.name = "ManagerReportFolder"
	clipboard.position = Vector3(-0.58 if index % 2 == 0 else 0.58, 1.03, 0.28)
	clipboard.rotation_degrees = Vector3(-8.0, 5.0, -10.0 if index % 2 == 0 else 10.0)
	root.add_child(clipboard)
	_add_box(clipboard, "ReportFolder", Vector3(0.34, 0.46, 0.05), Vector3.ZERO, Color("786044"), 0.74)
	_add_box(clipboard, "ReportPaper", Vector3(0.28, 0.35, 0.015), Vector3(0.0, 0.01, 0.034), Color("ede5d2"), 0.94)


func _update_additional_manager_patrol(delta: float) -> void:
	for record in _additional_managers:
		var root := record.get("root") as Node3D
		if root == null or not is_instance_valid(root):
			continue
		var pause := float(record.get("pause", 0.0))
		if pause > 0.0:
			record["pause"] = maxf(0.0, pause - delta)
			_play_roster_animation(record, ANIMATION_IDLE)
			continue
		var target := record.get("target", root.position) as Vector3
		var offset := target - root.position
		offset.y = 0.0
		if offset.length() <= 0.04:
			root.position = target
			var left := record.get("left", root.position) as Vector3
			var right := record.get("right", root.position) as Vector3
			record["target"] = left if target.distance_to(right) < 0.05 else right
			record["pause"] = MANAGER_PAUSE_SECONDS + float(_additional_managers.find(record)) * 0.25
			_play_roster_animation(record, ANIMATION_IDLE)
			continue
		var direction := offset.normalized()
		root.position += direction * minf((MANAGER_SPEED - 0.08) * delta, offset.length())
		root.rotation.y = lerp_angle(root.rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))
		_play_roster_animation(record, ANIMATION_WALK)


func _play_roster_animation(record: Dictionary, requested_name: StringName) -> void:
	var player := record.get("player") as AnimationPlayer
	var animations := record.get("animations", {}) as Dictionary
	if player == null or not animations.has(requested_name):
		return
	if StringName(record.get("active_animation", &"")) == requested_name and player.is_playing():
		return
	record["active_animation"] = requested_name
	player.play(StringName(animations[requested_name]))


func _build_manager_clipboard() -> void:
	var clipboard := Node3D.new()
	clipboard.name = "ManagerClipboard"
	clipboard.position = Vector3(-0.62, 1.05, 0.34)
	clipboard.rotation_degrees = Vector3(-12.0, 5.0, -13.0)
	_manager_root.add_child(clipboard)
	_add_box(clipboard, "ClipboardBoard", Vector3(0.38, 0.52, 0.055), Vector3.ZERO, Color("8b6944"), 0.72)
	_add_box(clipboard, "ClipboardPaper", Vector3(0.31, 0.40, 0.018), Vector3(0.0, 0.015, 0.038), Color("f0ead9"), 0.94)
	_add_box(clipboard, "ClipboardClip", Vector3(0.13, 0.075, 0.035), Vector3(0.0, 0.24, 0.064), Color("b7b9b8"), 0.28, 0.72)
	for line_y in [-0.10, 0.0, 0.10]:
		_add_box(clipboard, "ClaimLine", Vector3(0.22, 0.018, 0.012), Vector3(0.0, line_y, 0.058), Color("75838a"), 0.78)


func _build_manager_badge() -> void:
	var badge := Node3D.new()
	badge.name = "ManagerAuthorityBadge"
	badge.position = Vector3(0.33, 1.13, 0.53)
	badge.rotation_degrees = Vector3(0.0, 0.0, -4.0)
	_manager_root.add_child(badge)
	_add_box(badge, "BadgeCard", Vector3(0.31, 0.20, 0.035), Vector3.ZERO, Color("e6dcc5"), 0.66)
	_add_box(badge, "BadgeStripe", Vector3(0.25, 0.045, 0.012), Vector3(0.0, 0.045, 0.026), Color("8b2735"), 0.46)


func _build_farmer() -> void:
	_farmer_root = Node3D.new()
	_farmer_root.name = "FarmerReviewer"
	_farmer_root.position = FARMER_OFFSTAGE_POSITION
	_farmer_root.visible = false
	add_child(_farmer_root)

	_farmer_left_leg = _build_farmer_leg("LeftLeg", -0.32)
	_farmer_right_leg = _build_farmer_leg("RightLeg", 0.32)

	var torso := Node3D.new()
	torso.name = "FarmerTorso"
	torso.position = Vector3(0.0, 2.05, 0.0)
	_farmer_root.add_child(torso)
	var shirt := _add_sphere(torso, "PlaidShirt", 0.72, Vector3.ZERO, Color("8c3e35"), 0.86)
	shirt.scale = Vector3(1.08, 0.92, 0.72)
	_add_box(torso, "ShirtPlaidVerticalL", Vector3(0.08, 1.04, 0.035), Vector3(-0.43, 0.02, 0.55), Color("b95b47"), 0.88)
	_add_box(torso, "ShirtPlaidVerticalR", Vector3(0.08, 1.04, 0.035), Vector3(0.43, 0.02, 0.55), Color("b95b47"), 0.88)
	for stripe_y in [-0.34, 0.05, 0.42]:
		_add_box(torso, "ShirtPlaidHorizontal", Vector3(1.12, 0.07, 0.035), Vector3(0.0, stripe_y, 0.56), Color("6f302b"), 0.88)
	_add_box(torso, "OverallBib", Vector3(0.82, 0.96, 0.13), Vector3(0.0, -0.03, 0.61), Color("3e6075"), 0.82)
	_add_box(torso, "OverallPocket", Vector3(0.40, 0.29, 0.06), Vector3(0.0, -0.05, 0.71), Color("52768b"), 0.80)
	_add_box(torso, "LeftStrap", Vector3(0.16, 0.82, 0.075), Vector3(-0.34, 0.27, 0.68), Color("36586d"), 0.78)
	_add_box(torso, "RightStrap", Vector3(0.16, 0.82, 0.075), Vector3(0.34, 0.27, 0.68), Color("36586d"), 0.78)
	_add_sphere(torso, "LeftButton", 0.075, Vector3(-0.34, 0.56, 0.75), Color("d7b04f"), 0.36, 0.68)
	_add_sphere(torso, "RightButton", 0.075, Vector3(0.34, 0.56, 0.75), Color("d7b04f"), 0.36, 0.68)
	for side in [-1.0, 1.0]:
		var sleeve := _add_sphere(torso, "ShirtSleeve", 0.30, Vector3(side * 0.72, 0.20, 0.02), Color("9f493d"), 0.86)
		sleeve.scale = Vector3(0.82, 1.05, 0.82)
		var arm := _add_box(torso, "FarmerArm", Vector3(0.28, 0.88, 0.34), Vector3(side * 0.79, -0.31, 0.32), Color("bd7f5c"), 0.88)
		arm.rotation_degrees.z = side * -8.0
		_add_sphere(torso, "FarmerHand", 0.19, Vector3(side * 0.73, -0.76, 0.61), Color("c98e68"), 0.88)
	_add_box(torso, "ReviewLedger", Vector3(1.34, 0.64, 0.08), Vector3(0.0, -0.56, 0.78), Color("e5dcc5"), 0.88)
	_add_box(torso, "ReviewLedgerBand", Vector3(0.16, 0.66, 0.04), Vector3(0.0, -0.56, 0.83), Color("a3473b"), 0.62)

	var head := Node3D.new()
	head.name = "FarmerHead"
	head.position = Vector3(0.0, 3.12, 0.0)
	_farmer_root.add_child(head)
	_add_sphere(head, "Head", 0.53, Vector3.ZERO, Color("c98e68"), 0.88)
	_add_sphere(head, "LeftEye", 0.075, Vector3(-0.18, 0.08, 0.49), Color("161719"), 0.20)
	_add_sphere(head, "RightEye", 0.075, Vector3(0.18, 0.08, 0.49), Color("161719"), 0.20)
	_add_sphere(head, "Nose", 0.12, Vector3(0.0, -0.04, 0.55), Color("b87858"), 0.82)
	var moustache_left := _add_sphere(head, "MoustacheL", 0.13, Vector3(-0.09, -0.16, 0.52), Color("5a3928"), 0.92)
	moustache_left.scale = Vector3(1.15, 0.42, 0.48)
	var moustache_right := _add_sphere(head, "MoustacheR", 0.13, Vector3(0.09, -0.16, 0.52), Color("5a3928"), 0.92)
	moustache_right.scale = Vector3(1.15, 0.42, 0.48)
	_add_box(head, "HatBrim", Vector3(1.48, 0.10, 0.88), Vector3(0.0, 0.47, 0.0), Color("b78b48"), 0.82)
	_add_cylinder(head, "HatCrown", 0.43, 0.52, Vector3(0.0, 0.69, 0.0), Color("c59a55"), 0.82)
	_add_box(head, "HatBand", Vector3(0.88, 0.13, 0.88), Vector3(0.0, 0.55, 0.0), Color("584538"), 0.72)

func _build_farmer_leg(leg_name: String, x_position: float) -> Node3D:
	var leg := Node3D.new()
	leg.name = leg_name
	leg.position = Vector3(x_position, 1.12, 0.0)
	_farmer_root.add_child(leg)
	_add_box(leg, "DenimLeg", Vector3(0.52, 1.44, 0.58), Vector3(0.0, 0.0, 0.0), Color("35596e"), 0.86)
	_add_box(leg, "WorkBoot", Vector3(0.67, 0.40, 0.92), Vector3(0.0, -0.83, 0.16), Color("4a3328"), 0.72)
	_add_box(leg, "BootSole", Vector3(0.71, 0.10, 0.96), Vector3(0.0, -1.02, 0.17), Color("211c1a"), 0.90)
	return leg


func _update_farmer_walk(delta: float) -> void:
	if _farmer_root == null or _farmer_left_leg == null or _farmer_right_leg == null:
		return
	if not _farmer_is_reviewing:
		return
	_farmer_phase += delta * 7.2
	var stride := sin(_farmer_phase) * 0.24
	_farmer_left_leg.rotation.x = stride
	_farmer_right_leg.rotation.x = -stride


func _begin_farmer_exit() -> void:
	if _farmer_root != null:
		_face_local_point(_farmer_root, FARMER_OFFSTAGE_POSITION)


func _finish_review() -> void:
	_farmer_is_reviewing = false
	if _farmer_root != null:
		_farmer_root.position = FARMER_OFFSTAGE_POSITION
		_farmer_root.visible = false
	if _farmer_left_leg != null:
		_farmer_left_leg.rotation.x = 0.0
	if _farmer_right_leg != null:
		_farmer_right_leg.rotation.x = 0.0
	review_finished.emit()


func _face_local_point(subject: Node3D, point: Vector3) -> void:
	var direction := point - subject.position
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		subject.rotation.y = atan2(direction.x, direction.z)


func _add_box(
	parent: Node3D,
	mesh_name: String,
	size: Vector3,
	position: Vector3,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _make_material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_sphere(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	position: Vector3,
	color: Color,
	roughness: float = 0.82,
	metallic: float = 0.0
) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _make_material(color, roughness, metallic)
	parent.add_child(instance)
	return instance


func _add_cylinder(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	height: float,
	position: Vector3,
	color: Color,
	roughness: float = 0.82
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _make_material(color, roughness)
	parent.add_child(instance)
	return instance


func _make_material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _all_children(parent: Node) -> Array[Node]:
	var results: Array[Node] = []
	for child in parent.get_children():
		results.append(child)
		results.append_array(_all_children(child))
	return results
