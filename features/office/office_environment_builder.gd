class_name OfficeEnvironmentBuilder
extends RefCounted

## Constructs the static office shell, rooms, desks and props.
## Holds no state of its own: every read and write goes through the owning
## Office so behaviour is identical to the original in-class methods.

var office: Office


func _init(owner_node: Office) -> void:
	office = owner_node

func _build_environment() -> void:
	office._environment = Environment.new()
	office._environment.background_mode = Environment.BG_COLOR
	office._environment.background_color = Color("203443")
	office._environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	office._environment.ambient_light_color = Color("c2d5df")
	office._environment.ambient_light_energy = 0.46
	office._environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	office._environment.tonemap_exposure = 0.98
	office._environment.adjustment_enabled = true
	office._environment.adjustment_brightness = 1.02
	office._environment.adjustment_contrast = 1.06
	office._environment.adjustment_saturation = 0.98
	var world_environment := WorldEnvironment.new()
	world_environment.environment = office._environment
	office.add_child(world_environment)

	office._office_sun = DirectionalLight3D.new()
	office._office_sun.name = "OfficeSun"
	office._office_sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	office._office_sun.light_color = Color("ffe8bc")
	office._office_sun.light_energy = 0.88
	office._office_sun.shadow_enabled = true
	office._office_sun.shadow_opacity = 0.64
	office._office_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	office._office_sun.directional_shadow_max_distance = 60.0
	office._office_sun.directional_shadow_blend_splits = true
	office._office_sun.shadow_bias = 0.07
	office._office_sun.shadow_normal_bias = 1.1
	office.add_child(office._office_sun)

	# Compatibility renderer friendly fake GI: a diffuse-only upward bounce plus
	# three tight, shadowless fluorescent pools instead of expensive real-time GI.
	office._bounce_light = DirectionalLight3D.new()
	office._bounce_light.name = "CarpetBounce"
	office._bounce_light.rotation = office._office_sun.rotation + Vector3(PI, 0.0, 0.0)
	office._bounce_light.light_color = Color("b2b9ab")
	office._bounce_light.light_energy = 0.16
	office._bounce_light.light_specular = 0.0
	office._bounce_light.shadow_enabled = false
	office.add_child(office._bounce_light)

	for light_index in 3:
		var fill := OmniLight3D.new()
		fill.name = "FluorescentFill_%d" % light_index
		fill.position = Vector3([-6.0, 0.0, 6.0][light_index], 3.15, -0.5)
		fill.light_color = Color("e8dfc2")
		fill.light_energy = Office.OFFICE_FILL_LIGHT_ENERGY
		fill.light_specular = 0.25
		fill.omni_range = 5.6
		fill.omni_attenuation = 1.45
		fill.shadow_enabled = false
		office.add_child(fill)
		office._office_fill_lights.append(fill)

	office._management_camera = Camera3D.new()
	office._management_camera.name = "ManagementCamera"
	office._management_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	office._management_camera.size = Office.CORE_OVERVIEW_SIZE
	office._management_camera.position = Office.CORE_OVERVIEW_POSITION
	office._management_camera.near = 0.2
	office._management_camera.far = 65.0
	office._management_camera.current = true
	office.add_child(office._management_camera)
	office._management_camera.look_at(Office.CORE_OVERVIEW_TARGET)


func _build_physical_presentation_roots() -> void:
	office._office_physical_presentation = Node3D.new()
	office._office_physical_presentation.name = "OfficePhysicalPresentation"
	office._office_physical_presentation.set_meta(&"visual_only", true)
	office._office_physical_presentation.set_meta(&"collision_free", true)
	office._office_physical_presentation.set_meta(&"navigation_free", true)
	office.add_child(office._office_physical_presentation)

	office._core_office_presentation = _physical_presentation_root("CoreOfficePresentation", true)
	office._dormant_west_presentation = _physical_presentation_root("DormantWestPresentation", false)
	office._west_perch_04_presentation = _physical_presentation_root("WestPerch04Presentation", false)
	office._west_perch_05_presentation = _physical_presentation_root("WestPerch05Presentation", false)
	office._archive_presentation = _physical_presentation_root("ArchivePresentation", false)
	office._intake_presentation = _physical_presentation_root("IntakePresentation", true)
	_build_west_lease_partition()

	# Thin, collision-free floor insets make the generous safe desk clearances read
	# as deliberate commissioned neighborhoods instead of one vacant carpet sea.
	_build_commissioned_floor_inset(
		office._core_office_presentation,
		"OpeningPodFloorInset",
		Vector3(3.25, 0.0, -0.05),
		Vector2(13.10, 12.35),
		Color("35474b"),
	)
	_build_commissioned_floor_inset(
		office._west_perch_04_presentation,
		"WestPerch04FloorInset",
		office.desk_position(4),
		Vector2(5.15, 5.10),
		Color("34464a"),
	)
	_build_commissioned_floor_inset(
		office._west_perch_05_presentation,
		"WestPerch05FloorInset",
		office.desk_position(5),
		Vector2(5.15, 5.10),
		Color("34464a"),
	)
	# Staffing context exposes a quiet brass threshold and the existing boxed
	# authorization marker. It never constructs a fake desk or route obstacle.
	for seam_index in 4:
		var threshold := office._add_box(
			office._dormant_west_presentation,
			"WestAuthorizationThreshold_%02d" % seam_index,
			Vector3(0.07, 0.010, 1.10),
			Vector3(-3.42, 0.017, -4.65 + seam_index * 3.10),
			Color("9b8150"),
		)
		threshold.material_override = office._material(Color("9b8150"), 0.48, 0.28)
		threshold.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_west_lease_partition() -> void:
	# A low, visual-only acoustic partition gives the opening pod a believable
	# occupied boundary. It leaves the main aisle open and is removed as soon as
	# the first west perch is commissioned; no route or collision owns this art.
	office._west_lease_partition = Node3D.new()
	office._west_lease_partition.name = "WestLeasePartition"
	office._west_lease_partition.set_meta(&"visual_only", true)
	office._west_lease_partition.set_meta(&"collision_free", true)
	office._west_lease_partition.set_meta(&"navigation_free", true)
	office._core_office_presentation.add_child(office._west_lease_partition)
	var panel_color := Color("405154")
	var frame_color := Color("26363a")
	var cap_color := Color("9a8252")
	var panel_centers := [-5.00, 4.00]
	for panel_index in panel_centers.size():
		var panel_z: float = panel_centers[panel_index]
		var panel := office._add_box(
			office._west_lease_partition,
			"WestLeasePartitionPanel_%02d" % panel_index,
			Vector3(0.105, 1.58, 2.65),
			Vector3(-3.39, 0.80, panel_z),
			panel_color.lightened(0.025 * float(panel_index % 2)),
		)
		panel.material_override = office._material(
			panel_color.lightened(0.025 * float(panel_index % 2)),
			0.88,
		)
		office._add_box(
			office._west_lease_partition,
			"WestLeasePartitionCap_%02d" % panel_index,
			Vector3(0.15, 0.055, 2.75),
			Vector3(-3.39, 1.61, panel_z),
			cap_color,
		).material_override = office._material(cap_color, 0.58, 0.20)
		for post_index in 2:
			var post_z := -1.0 if post_index == 0 else 1.0
			office._add_box(
				office._west_lease_partition,
				"WestLeasePartitionPost_%02d_%d" % [panel_index, post_index],
				Vector3(0.16, 1.68, 0.075),
				Vector3(-3.39, 0.84, panel_z + post_z * 1.35),
				frame_color,
			).material_override = office._material(frame_color, 0.68, 0.16)
		for foot_index in 2:
			var foot_z := -1.0 if foot_index == 0 else 1.0
			office._add_box(
				office._west_lease_partition,
				"WestLeasePartitionFoot_%02d_%d" % [panel_index, foot_index],
				Vector3(0.62, 0.055, 0.18),
				Vector3(-3.25, 0.035, panel_z + foot_z * 1.16),
				frame_color,
			).material_override = office._material(frame_color, 0.54, 0.24)
	# The divider is temporary, but the records/storage furniture is part of the
	# office's persistent identity. Keep it under the stable core root so opening
	# a commissioned west perch never empties the whole side of the room.
	_build_opening_west_flex_office(office._core_office_presentation)


func _build_opening_west_flex_office(parent: Node3D) -> void:
	# The west bay is a persistent shared records and supply nook. Only the exact
	# footprint required by the sixth workstation is convertible; perimeter
	# storage and visitor furnishings remain stable for the life of the office.
	var furnishings := Node3D.new()
	furnishings.name = "OpeningWestOfficeFurnishings"
	furnishings.set_meta(&"visual_only", true)
	furnishings.set_meta(&"collision_free", true)
	furnishings.set_meta(&"navigation_free", true)
	furnishings.set_meta(&"persistent_across_shifts", true)
	furnishings.set_meta(&"retired_at_capacity", -1)
	parent.add_child(furnishings)
	office._west_second_perch_flex_furnishings = Node3D.new()
	office._west_second_perch_flex_furnishings.name = "WestSecondPerchFlexFurnishings"
	office._west_second_perch_flex_furnishings.set_meta(&"visual_only", true)
	office._west_second_perch_flex_furnishings.set_meta(&"collision_free", true)
	office._west_second_perch_flex_furnishings.set_meta(&"navigation_free", true)
	office._west_second_perch_flex_furnishings.set_meta(&"converted_at_capacity", Office.MAXIMUM_OFFICE_CAPACITY)
	furnishings.add_child(office._west_second_perch_flex_furnishings)

	var timber := Color("9c7448")
	var timber_edge := Color("584838")
	var dark_metal := Color("344448")
	var cabinet_green := Color("50635e")
	var paper := Color("e1dccb")
	var kraft := Color("b99a69")
	var teal := Color("668b88")
	var ochre := Color("c09b4f")
	var brick := Color("a8654e")
	var folder_colors: Array[Color] = [teal, ochre, brick, Color("7b8297")]

	# A substantial back-wall supply cabinet replaces the two dormant west
	# windows with an intentional opening-day silhouette. Open shelves and varied
	# contents read clearly from the ordinary isometric camera.
	var cabinet := Node3D.new()
	cabinet.name = "WestFlexSupplyCabinet"
	# Pull the cabinet off the back wall far enough to remain legible below the
	# persistent management HUD while still leaving the feed and wellness lanes.
	cabinet.position = Vector3(0.0, 0.0, 1.08)
	furnishings.add_child(cabinet)
	office._add_box(cabinet, "WestFlexSupplyCabinetCarcassBack", Vector3(2.55, 2.25, 0.12), Vector3(-5.82, 1.18, -8.37), cabinet_green)
	for side_index in 2:
		var side_x := -7.12 if side_index == 0 else -4.52
		office._add_box(cabinet, "WestFlexSupplyCabinetCarcassSide_%d" % side_index, Vector3(0.14, 2.30, 0.56), Vector3(side_x, 1.18, -8.10), dark_metal)
	for shelf_index in 4:
		var shelf_y := 0.10 + shelf_index * 0.69
		office._add_box(cabinet, "WestFlexSupplyCabinetCarcassShelf_%d" % shelf_index, Vector3(2.74, 0.12, 0.62), Vector3(-5.82, shelf_y, -8.08), dark_metal)
	# Banker boxes, paper reams, and upright binders build a compact visual story
	# with no additional instructional copy.
	for box_index in 3:
		var box_x := -6.65 + box_index * 0.82
		office._add_box(cabinet, "WestFlexBankerBox_%d" % box_index, Vector3(0.66, 0.43, 0.42), Vector3(box_x, 0.39, -8.02), kraft.lightened(0.035 * box_index))
		office._add_box(cabinet, "WestFlexBankerBoxLabel_%d" % box_index, Vector3(0.28, 0.12, 0.025), Vector3(box_x, 0.41, -7.79), paper)
	for binder_index in 7:
		var binder_x := -6.83 + binder_index * 0.32
		var binder_height := 0.46 + float(binder_index % 3) * 0.055
		office._add_box(cabinet, "WestFlexBinder_%02d" % binder_index, Vector3(0.22, binder_height, 0.34), Vector3(binder_x, 0.86 + binder_height * 0.5, -8.00), folder_colors[binder_index % folder_colors.size()])
		office._add_box(cabinet, "WestFlexBinderSpine_%02d" % binder_index, Vector3(0.09, 0.055, 0.024), Vector3(binder_x, 0.87, -7.82), paper)
	for ream_index in 3:
		office._add_box(cabinet, "WestFlexPaperReam_%d" % ream_index, Vector3(0.72, 0.13, 0.40), Vector3(-6.62, 1.55 + ream_index * 0.14, -8.00), paper.darkened(0.025 * ream_index))
	office._add_box(cabinet, "WestFlexArchiveTray", Vector3(0.83, 0.10, 0.42), Vector3(-5.28, 1.54, -8.00), brick)
	office._add_box(cabinet, "WestFlexArchiveFolder", Vector3(0.72, 0.075, 0.34), Vector3(-5.28, 1.66, -7.99), ochre)
	office._add_box(cabinet, "WestFlexSupplyCrate", Vector3(0.94, 0.49, 0.44), Vector3(-5.15, 2.13, -8.00), timber)
	for slat_index in 3:
		office._add_box(cabinet, "WestFlexSupplyCrateSlat_%d" % slat_index, Vector3(0.10, 0.36, 0.025), Vector3(-5.49 + slat_index * 0.34, 2.13, -7.76), timber_edge)

	# Shared mailroom table: pigeonholes, trays, and a task lamp make the broad
	# front-left floor read as practical office support space at a glance.
	var mail_table := Node3D.new()
	mail_table.name = "WestFlexMailTable"
	mail_table.position = Vector3(0.0, 0.0, 1.35)
	office._west_second_perch_flex_furnishings.add_child(mail_table)
	office._add_box(mail_table, "WestFlexMailTableTop", Vector3(2.62, 0.16, 1.08), Vector3(-5.82, 0.86, 4.39), timber).material_override = office._material(timber, 0.57, 0.12)
	office._add_box(mail_table, "WestFlexMailTableApron", Vector3(2.42, 0.28, 0.10), Vector3(-5.82, 0.69, 4.89), timber_edge)
	for leg_index in 4:
		var leg_x := -6.91 if leg_index % 2 == 0 else -4.73
		var leg_z := 4.02 if leg_index < 2 else 4.76
		office._add_box(mail_table, "WestFlexMailTableLeg_%d" % leg_index, Vector3(0.14, 0.75, 0.14), Vector3(leg_x, 0.40, leg_z), dark_metal)
	office._add_box(mail_table, "WestFlexMailTableLowerShelf", Vector3(2.18, 0.09, 0.64), Vector3(-5.82, 0.27, 4.38), cabinet_green)
	for parcel_index in 2:
		office._add_box(mail_table, "WestFlexLowerParcel_%d" % parcel_index, Vector3(0.70, 0.30 + parcel_index * 0.08, 0.48), Vector3(-6.35 + parcel_index * 1.06, 0.48, 4.38), kraft.darkened(0.035 * parcel_index))

	var sorter := Node3D.new()
	sorter.name = "WestFlexMailSorter"
	mail_table.add_child(sorter)
	office._add_box(sorter, "WestFlexMailSorterBack", Vector3(1.54, 0.78, 0.10), Vector3(-5.92, 1.32, 4.77), cabinet_green.darkened(0.06))
	for horizontal_index in 3:
		office._add_box(sorter, "WestFlexMailSorterShelf_%d" % horizontal_index, Vector3(1.60, 0.065, 0.43), Vector3(-5.92, 0.96 + horizontal_index * 0.36, 4.56), timber_edge)
	for divider_index in 5:
		office._add_box(sorter, "WestFlexMailSorterDivider_%d" % divider_index, Vector3(0.055, 0.70, 0.42), Vector3(-6.70 + divider_index * 0.39, 1.32, 4.56), timber_edge)
	for file_index in 6:
		var file_row := file_index / 3
		var file_column := file_index % 3
		office._add_box(sorter, "WestFlexSortedFolder_%d" % file_index, Vector3(0.28, 0.07, 0.31), Vector3(-6.48 + file_column * 0.50, 1.08 + file_row * 0.36, 4.30), folder_colors[file_index % folder_colors.size()])
		office._add_box(sorter, "WestFlexMailPacket_%d" % file_index, Vector3(0.27, 0.14, 0.035), Vector3(-6.48 + file_column * 0.50, 1.11 + file_row * 0.36, 4.12), paper.darkened(0.025 * float(file_index % 3)))

	for tray_index in 2:
		var tray_z := 4.20 + tray_index * 0.30
		office._add_box(mail_table, "WestFlexDeskTrayBase_%d" % tray_index, Vector3(0.58, 0.055, 0.26), Vector3(-4.77, 0.98, tray_z), dark_metal)
		office._add_box(mail_table, "WestFlexDeskTrayPaper_%d" % tray_index, Vector3(0.48, 0.035, 0.20), Vector3(-4.77, 1.02, tray_z), paper)
	# Rectilinear lamp stays within the box-only staging contract.
	office._add_box(mail_table, "WestFlexTaskLampBase", Vector3(0.34, 0.06, 0.26), Vector3(-4.83, 0.98, 4.68), dark_metal)
	office._add_box(mail_table, "WestFlexTaskLampStem", Vector3(0.07, 0.50, 0.07), Vector3(-4.83, 1.24, 4.68), dark_metal)
	office._add_box(mail_table, "WestFlexTaskLampShade", Vector3(0.42, 0.18, 0.28), Vector3(-4.83, 1.52, 4.59), ochre).material_override = office._material(ochre, 0.48, 0.18)
	office._add_box(mail_table, "WestFlexTaskLampGlow", Vector3(0.28, 0.025, 0.18), Vector3(-4.83, 1.42, 4.58), Color("f3d58a")).material_override = office._emissive_material(Color("f3d58a"), 0.62)

	# A low mobile file cart adds a second scale and a recognizable office prop,
	# positioned beside rather than inside the main aisle.
	var file_cart := Node3D.new()
	file_cart.name = "WestFlexFileCart"
	file_cart.position = Vector3(0.0, 0.0, 1.35)
	office._west_second_perch_flex_furnishings.add_child(file_cart)
	office._add_box(file_cart, "WestFlexFileCartBody", Vector3(1.05, 0.72, 0.74), Vector3(-7.55, 0.55, 4.48), cabinet_green)
	office._add_box(file_cart, "WestFlexFileCartTopRail", Vector3(1.12, 0.08, 0.80), Vector3(-7.55, 0.95, 4.48), dark_metal)
	for folder_index in 4:
		office._add_box(file_cart, "WestFlexCartFolder_%d" % folder_index, Vector3(0.16, 0.44 - 0.035 * folder_index, 0.56), Vector3(-7.87 + folder_index * 0.22, 0.90, 4.48), folder_colors[folder_index])
	office._add_box(file_cart, "WestFlexFileCartHandle", Vector3(0.12, 0.55, 0.84), Vector3(-8.12, 0.76, 4.48), dark_metal)
	for caster_index in 4:
		var caster_x := -7.94 if caster_index % 2 == 0 else -7.16
		var caster_z := 4.20 if caster_index < 2 else 4.76
		office._add_box(file_cart, "WestFlexFileCartCaster_%d" % caster_index, Vector3(0.16, 0.14, 0.16), Vector3(caster_x, 0.12, caster_z), Color("202a2d"))

	# A compact stand and personal traces keep the nook from feeling showroom
	# perfect while preserving a broad visual corridor through its center.
	var coat_stand := Node3D.new()
	coat_stand.name = "WestFlexCoatStand"
	office._west_second_perch_flex_furnishings.add_child(coat_stand)
	office._add_box(coat_stand, "WestFlexCoatStandBase", Vector3(0.60, 0.08, 0.60), Vector3(-4.25, 0.08, 5.18), dark_metal)
	office._add_box(coat_stand, "WestFlexCoatStandPost", Vector3(0.11, 1.70, 0.11), Vector3(-4.25, 0.88, 5.18), dark_metal)
	office._add_box(coat_stand, "WestFlexCoatStandCrossbar", Vector3(0.70, 0.09, 0.09), Vector3(-4.25, 1.68, 5.18), dark_metal)
	office._add_box(coat_stand, "WestFlexCoatStandHook", Vector3(0.09, 0.09, 0.62), Vector3(-4.25, 1.57, 5.18), dark_metal)
	office._add_box(coat_stand, "WestFlexRaincoat", Vector3(0.48, 0.74, 0.12), Vector3(-4.39, 1.24, 5.21), teal.darkened(0.10))
	office._add_box(coat_stand, "WestFlexUmbrella", Vector3(0.10, 0.82, 0.10), Vector3(-4.54, 0.49, 5.36), ochre)

	# The broad center-left patch remains a legible circulation pocket, but a
	# compact project-review station gives its rear half a clear office purpose.
	# It occupies the safe band between the feed lane and the supply cabinet and
	# converts only when its exact footprint is needed by the sixth perch.
	var project_station := Node3D.new()
	project_station.name = "WestFlexProjectStation"
	project_station.position = Vector3(0.0, 0.0, 7.80)
	office._west_second_perch_flex_furnishings.add_child(project_station)

	# A shallow inset visually gathers the table, stools, and board without
	# introducing a wall or collision boundary.
	office._add_box(project_station, "WestFlexProjectMat", Vector3(4.05, 0.016, 1.75), Vector3(-5.72, -0.005, -4.45), Color("3b4d50"))
	for mat_stripe_index in 3:
		office._add_box(
			project_station,
			"WestFlexProjectMatStripe_%d" % mat_stripe_index,
			Vector3(0.075, 0.012, 1.42),
			Vector3(-7.20 + mat_stripe_index * 1.48, 0.007, -4.45),
			Color("66746e").darkened(0.04 * mat_stripe_index),
		)

	var project_table := Node3D.new()
	project_table.name = "WestFlexProjectTable"
	project_station.add_child(project_table)
	office._add_box(project_table, "WestFlexProjectTableTop", Vector3(2.44, 0.15, 0.94), Vector3(-5.72, 0.84, -4.16), timber.lightened(0.035)).material_override = office._material(timber.lightened(0.035), 0.54, 0.14)
	office._add_box(project_table, "WestFlexProjectTableApronFront", Vector3(2.20, 0.22, 0.09), Vector3(-5.72, 0.68, -3.73), timber_edge)
	office._add_box(project_table, "WestFlexProjectTableApronBack", Vector3(2.20, 0.22, 0.09), Vector3(-5.72, 0.68, -4.59), timber_edge)
	for project_leg_index in 4:
		var project_leg_x := -6.72 if project_leg_index % 2 == 0 else -4.72
		var project_leg_z := -4.48 if project_leg_index < 2 else -3.84
		office._add_box(project_table, "WestFlexProjectTableLeg_%d" % project_leg_index, Vector3(0.15, 0.73, 0.15), Vector3(project_leg_x, 0.41, project_leg_z), dark_metal)
	office._add_box(project_table, "WestFlexProjectTableStretcher", Vector3(1.94, 0.10, 0.10), Vector3(-5.72, 0.30, -4.16), dark_metal)

	# A spread of active work conveys collaboration through objects rather than
	# labels: plans, a ruler, swatches, a file, and two clipped packets.
	office._add_box(project_table, "WestFlexProjectPlanLarge", Vector3(0.98, 0.026, 0.58), Vector3(-6.18, 0.94, -4.17), Color("a9c3bf"))
	for grid_line_index in 4:
		office._add_box(project_table, "WestFlexProjectPlanGrid_%d" % grid_line_index, Vector3(0.035, 0.012, 0.48), Vector3(-6.52 + grid_line_index * 0.22, 0.958, -4.17), Color("54736f"))
	office._add_box(project_table, "WestFlexProjectRuler", Vector3(0.74, 0.045, 0.075), Vector3(-5.78, 0.975, -4.08), ochre)
	office._add_box(project_table, "WestFlexProjectFile", Vector3(0.64, 0.075, 0.46), Vector3(-5.02, 0.95, -4.25), brick)
	office._add_box(project_table, "WestFlexProjectFilePaper", Vector3(0.52, 0.035, 0.37), Vector3(-5.02, 1.005, -4.25), paper)
	for swatch_index in 3:
		office._add_box(project_table, "WestFlexProjectSwatch_%d" % swatch_index, Vector3(0.18, 0.035, 0.18), Vector3(-5.42 + swatch_index * 0.20, 0.99 + swatch_index * 0.008, -3.91), folder_colors[swatch_index])
	office._add_box(project_table, "WestFlexProjectPencilCup", Vector3(0.24, 0.28, 0.24), Vector3(-4.69, 1.03, -3.93), cabinet_green)
	for pencil_index in 3:
		office._add_box(project_table, "WestFlexProjectPencil_%d" % pencil_index, Vector3(0.035, 0.36 - pencil_index * 0.04, 0.035), Vector3(-4.76 + pencil_index * 0.07, 1.26, -3.93), folder_colors[pencil_index])

	# Two compact task stools add recognizable seating without suggesting a new
	# staffed perch or intruding into the authored lanes.
	for stool_index in 2:
		var stool_x := -7.22 if stool_index == 0 else -4.18
		var stool_color := teal.darkened(0.06) if stool_index == 0 else Color("7d8794")
		var stool := Node3D.new()
		stool.name = "WestFlexProjectStool_%d" % stool_index
		project_station.add_child(stool)
		office._add_box(stool, "WestFlexProjectStoolSeat_%d" % stool_index, Vector3(0.67, 0.14, 0.62), Vector3(stool_x, 0.56, -3.88), stool_color)
		office._add_box(stool, "WestFlexProjectStoolBack_%d" % stool_index, Vector3(0.67, 0.58, 0.13), Vector3(stool_x, 0.88, -4.17), stool_color.darkened(0.06))
		for stool_leg_index in 2:
			var stool_leg_x := stool_x - 0.22 + stool_leg_index * 0.44
			office._add_box(stool, "WestFlexProjectStoolLeg_%d_%d" % [stool_index, stool_leg_index], Vector3(0.10, 0.49, 0.10), Vector3(stool_leg_x, 0.28, -3.88), dark_metal)
		office._add_box(stool, "WestFlexProjectStoolFoot_%d" % stool_index, Vector3(0.56, 0.08, 0.10), Vector3(stool_x, 0.18, -3.88), dark_metal)

	# A freestanding board gives the rear of the bay vertical rhythm and makes the
	# project table read as a review point. Abstract cards preserve the game's
	# low-text visual language.
	var planning_board := Node3D.new()
	planning_board.name = "WestFlexPlanningBoard"
	project_station.add_child(planning_board)
	office._add_box(planning_board, "WestFlexPlanningBoardPanel", Vector3(2.45, 1.32, 0.10), Vector3(-5.72, 1.52, -5.30), Color("d5d3c7"))
	office._add_box(planning_board, "WestFlexPlanningBoardTopFrame", Vector3(2.62, 0.09, 0.16), Vector3(-5.72, 2.22, -5.30), dark_metal)
	office._add_box(planning_board, "WestFlexPlanningBoardBottomFrame", Vector3(2.62, 0.09, 0.16), Vector3(-5.72, 0.82, -5.30), dark_metal)
	for board_side_index in 2:
		var board_side_x := -7.00 if board_side_index == 0 else -4.44
		office._add_box(planning_board, "WestFlexPlanningBoardSideFrame_%d" % board_side_index, Vector3(0.09, 1.48, 0.16), Vector3(board_side_x, 1.52, -5.30), dark_metal)
		office._add_box(planning_board, "WestFlexPlanningBoardStand_%d" % board_side_index, Vector3(0.11, 0.72, 0.11), Vector3(board_side_x, 0.44, -5.30), dark_metal)
		office._add_box(planning_board, "WestFlexPlanningBoardFoot_%d" % board_side_index, Vector3(0.54, 0.08, 0.50), Vector3(board_side_x, 0.08, -5.22), dark_metal)
	for board_column_index in 3:
		office._add_box(planning_board, "WestFlexPlanningBoardRail_%d" % board_column_index, Vector3(0.045, 1.02, 0.025), Vector3(-6.42 + board_column_index * 0.70, 1.50, -5.23), Color("8a918b"))
	for board_card_index in 7:
		var board_card_column := board_card_index % 3
		var board_card_row := board_card_index / 3
		var card_width := 0.42 if board_card_index % 2 == 0 else 0.34
		office._add_box(
			planning_board,
			"WestFlexPlanningCard_%d" % board_card_index,
			Vector3(card_width, 0.22, 0.035),
			Vector3(-6.70 + board_card_column * 0.73, 1.88 - board_card_row * 0.38, -5.21),
			folder_colors[board_card_index % folder_colors.size()].lightened(0.08),
		)
	office._add_box(planning_board, "WestFlexPlanningBoardClipRail", Vector3(1.98, 0.07, 0.06), Vector3(-5.72, 1.02, -5.20), timber)

	# The west cutaway wall has a safe bay between the wellness room and entry
	# aisle. A compact administrative waiting nook makes that wall read as an
	# office frontage rather than an empty boundary. It stays against the perimeter
	# as the west perches are commissioned, preserving the room's visual identity.
	var visitor_nook := Node3D.new()
	visitor_nook.name = "WestVisitorOfficeNook"
	furnishings.add_child(visitor_nook)
	office._add_box(visitor_nook, "WestVisitorBaseboard", Vector3(0.10, 0.20, 3.62), Vector3(-11.76, 0.12, 4.48), cabinet_green.darkened(0.08))

	var visitor_bench := Node3D.new()
	visitor_bench.name = "WestVisitorBench"
	visitor_nook.add_child(visitor_bench)
	office._add_box(visitor_bench, "WestVisitorBenchSeat", Vector3(0.82, 0.18, 2.12), Vector3(-11.22, 0.52, 4.62), teal.darkened(0.05)).material_override = office._material(teal.darkened(0.05), 0.82)
	office._add_box(visitor_bench, "WestVisitorBenchBack", Vector3(0.20, 0.92, 2.12), Vector3(-11.59, 0.94, 4.62), cabinet_green)
	office._add_box(visitor_bench, "WestVisitorBenchFrontRail", Vector3(0.14, 0.25, 1.94), Vector3(-10.78, 0.37, 4.62), dark_metal)
	for visitor_arm_index in 2:
		var visitor_arm_z := 3.52 if visitor_arm_index == 0 else 5.72
		office._add_box(visitor_bench, "WestVisitorBenchArm_%d" % visitor_arm_index, Vector3(0.72, 0.48, 0.16), Vector3(-11.20, 0.72, visitor_arm_z), cabinet_green.darkened(0.07))
		office._add_box(visitor_bench, "WestVisitorBenchLeg_%d" % visitor_arm_index, Vector3(0.15, 0.38, 0.15), Vector3(-11.20, 0.22, visitor_arm_z), timber_edge)
	for visitor_cushion_index in 2:
		var visitor_cushion_z := 4.12 + visitor_cushion_index * 1.00
		var visitor_cushion_color := ochre.darkened(0.05) if visitor_cushion_index == 0 else brick.lightened(0.03)
		office._add_box(visitor_bench, "WestVisitorBenchCushion_%d" % visitor_cushion_index, Vector3(0.18, 0.48, 0.78), Vector3(-10.90, 0.90, visitor_cushion_z), visitor_cushion_color).rotation_degrees.z = -8.0 if visitor_cushion_index == 0 else 6.0
	for visitor_button_index in 3:
		office._add_box(visitor_bench, "WestVisitorBenchButton_%d" % visitor_button_index, Vector3(0.035, 0.07, 0.07), Vector3(-10.78, 1.02, 4.02 + visitor_button_index * 0.60), Color("314b48"))

	# A lateral file cabinet doubles as the waiting-area side table. Drawer faces,
	# label cards, an inbox, and a small plant create office-scale detail.
	var visitor_files := Node3D.new()
	visitor_files.name = "WestVisitorFileCredenza"
	visitor_nook.add_child(visitor_files)
	office._add_box(visitor_files, "WestVisitorFileCredenzaBody", Vector3(0.72, 0.78, 0.92), Vector3(-11.32, 0.41, 2.82), Color("68767a"))
	office._add_box(visitor_files, "WestVisitorFileCredenzaTop", Vector3(0.84, 0.10, 1.04), Vector3(-11.26, 0.85, 2.82), timber.lightened(0.04)).material_override = office._material(timber.lightened(0.04), 0.55, 0.10)
	for visitor_drawer_index in 2:
		var visitor_drawer_y := 0.31 + visitor_drawer_index * 0.34
		office._add_box(visitor_files, "WestVisitorFileDrawer_%d" % visitor_drawer_index, Vector3(0.045, 0.25, 0.76), Vector3(-10.94, visitor_drawer_y, 2.82), Color("78878a"))
		office._add_box(visitor_files, "WestVisitorFileHandle_%d" % visitor_drawer_index, Vector3(0.035, 0.055, 0.30), Vector3(-10.90, visitor_drawer_y, 2.82), Color("d0c7ac")).material_override = office._material(Color("d0c7ac"), 0.32, 0.52)
		office._add_box(visitor_files, "WestVisitorFileLabel_%d" % visitor_drawer_index, Vector3(0.030, 0.11, 0.28), Vector3(-10.89, visitor_drawer_y + 0.09, 2.82), paper)
	office._add_box(visitor_files, "WestVisitorInboxBase", Vector3(0.32, 0.055, 0.55), Vector3(-10.98, 0.96, 3.00), dark_metal)
	office._add_box(visitor_files, "WestVisitorInboxPaper", Vector3(0.28, 0.035, 0.46), Vector3(-10.98, 1.00, 3.00), paper)
	office._add_box(visitor_files, "WestVisitorPlantPot", Vector3(0.27, 0.27, 0.27), Vector3(-11.22, 1.00, 2.50), brick.darkened(0.06))
	for visitor_leaf_index in 4:
		var visitor_leaf := office._add_box(visitor_files, "WestVisitorPlantLeaf_%d" % visitor_leaf_index, Vector3(0.08, 0.42, 0.16), Vector3(-11.22, 1.30 + visitor_leaf_index * 0.035, 2.50), Color("55765c").lightened(0.035 * visitor_leaf_index))
		visitor_leaf.rotation_degrees = Vector3(12.0, visitor_leaf_index * 90.0, -22.0 + visitor_leaf_index * 14.0)

	# A physical wall records fixture and forms rack provide vertical density with
	# colored artifacts instead of another paragraph of instructional signage.
	var visitor_wall := Node3D.new()
	visitor_wall.name = "WestVisitorWallRecords"
	visitor_nook.add_child(visitor_wall)
	office._add_box(visitor_wall, "WestVisitorWallBoard", Vector3(0.07, 1.18, 2.18), Vector3(-11.66, 2.02, 4.62), Color("d6d1bd"))
	for visitor_frame_y_index in 2:
		var visitor_frame_y := 1.39 if visitor_frame_y_index == 0 else 2.65
		office._add_box(visitor_wall, "WestVisitorWallFrameHorizontal_%d" % visitor_frame_y_index, Vector3(0.12, 0.10, 2.34), Vector3(-11.60, visitor_frame_y, 4.62), timber_edge)
	for visitor_frame_z_index in 2:
		var visitor_frame_z := 3.48 if visitor_frame_z_index == 0 else 5.76
		office._add_box(visitor_wall, "WestVisitorWallFrameVertical_%d" % visitor_frame_z_index, Vector3(0.12, 1.36, 0.10), Vector3(-11.60, 2.02, visitor_frame_z), timber_edge)
	for visitor_card_index in 6:
		var visitor_card_column := visitor_card_index % 3
		var visitor_card_row := visitor_card_index / 3
		var visitor_card_color := folder_colors[visitor_card_index % folder_colors.size()].lightened(0.13)
		office._add_box(visitor_wall, "WestVisitorWallRecord_%d" % visitor_card_index, Vector3(0.035, 0.30, 0.48), Vector3(-11.55, 2.30 - visitor_card_row * 0.48, 3.96 + visitor_card_column * 0.66), visitor_card_color)
		office._add_box(visitor_wall, "WestVisitorWallRecordLine_%d" % visitor_card_index, Vector3(0.025, 0.035, 0.30), Vector3(-11.52, 2.31 - visitor_card_row * 0.48, 3.96 + visitor_card_column * 0.66), Color("65706d"))

	office._add_box(visitor_wall, "WestVisitorFormsRackBack", Vector3(0.08, 0.62, 0.82), Vector3(-11.65, 1.10, 3.16), dark_metal)
	for visitor_pocket_index in 3:
		var visitor_pocket_z := 2.88 + visitor_pocket_index * 0.28
		office._add_box(visitor_wall, "WestVisitorFormsPocket_%d" % visitor_pocket_index, Vector3(0.18, 0.23, 0.24), Vector3(-11.51, 1.05, visitor_pocket_z), cabinet_green)
		office._add_box(visitor_wall, "WestVisitorFormsPacket_%d" % visitor_pocket_index, Vector3(0.05, 0.30, 0.18), Vector3(-11.39, 1.19, visitor_pocket_z), paper.darkened(0.035 * visitor_pocket_index))

	# A warm rectilinear sconce and square office clock finish the wall silhouette
	# while retaining the lease root's box-only route-audit contract.
	office._add_box(visitor_wall, "WestVisitorSconcePlate", Vector3(0.08, 0.42, 0.32), Vector3(-11.65, 2.90, 5.94), timber_edge)
	office._add_box(visitor_wall, "WestVisitorSconceArm", Vector3(0.30, 0.07, 0.07), Vector3(-11.46, 2.90, 5.94), timber_edge)
	office._add_box(visitor_wall, "WestVisitorSconceShade", Vector3(0.30, 0.25, 0.42), Vector3(-11.26, 2.84, 5.94), ochre).material_override = office._material(ochre, 0.48, 0.16)
	office._add_box(visitor_wall, "WestVisitorSconceGlow", Vector3(0.035, 0.16, 0.28), Vector3(-11.09, 2.80, 5.94), Color("f1d487")).material_override = office._emissive_material(Color("f1d487"), 0.72)
	office._add_box(visitor_wall, "WestVisitorClockFrame", Vector3(0.08, 0.72, 0.72), Vector3(-11.66, 2.76, 2.82), dark_metal)
	office._add_box(visitor_wall, "WestVisitorClockFace", Vector3(0.035, 0.58, 0.58), Vector3(-11.60, 2.76, 2.82), Color("e2dcc8"))
	office._add_box(visitor_wall, "WestVisitorClockHourHand", Vector3(0.025, 0.20, 0.035), Vector3(-11.57, 2.82, 2.82), Color("384649")).rotation_degrees.x = 22.0
	office._add_box(visitor_wall, "WestVisitorClockMinuteHand", Vector3(0.025, 0.035, 0.25), Vector3(-11.56, 2.76, 2.89), Color("384649")).rotation_degrees.x = -32.0


func _physical_presentation_root(root_name: String, initially_visible: bool) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	root.visible = initially_visible
	root.set_meta(&"visual_only", true)
	root.set_meta(&"collision_free", true)
	root.set_meta(&"navigation_free", true)
	office._office_physical_presentation.add_child(root)
	return root


func _build_commissioned_floor_inset(
	parent: Node3D,
	part_name: String,
	center: Vector3,
	size: Vector2,
	color: Color,
) -> void:
	var inset := office._add_box(
		parent,
		part_name,
		Vector3(size.x, 0.014, size.y),
		Vector3(center.x, -0.011, center.z),
		color,
	)
	inset.material_override = office._material(color, 0.96)
	inset.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var edge_color := Color("766b52")
	for side_z in [-1.0, 1.0]:
		var edge_z := office._add_box(
			parent,
			"%sEdge" % part_name,
			Vector3(size.x, 0.009, 0.045),
			Vector3(center.x, 0.001, center.z + side_z * size.y * 0.5),
			edge_color,
		)
		edge_z.material_override = office._material(edge_color, 0.58, 0.18)
		edge_z.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side_x in [-1.0, 1.0]:
		var edge_x := office._add_box(
			parent,
			"%sEdge" % part_name,
			Vector3(0.045, 0.009, size.y),
			Vector3(center.x + side_x * size.x * 0.5, 0.001, center.z),
			edge_color,
		)
		edge_x.material_override = office._material(edge_color, 0.58, 0.18)
		edge_x.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _window_presentation_parent(window_x: float, core_parent: Node3D) -> Node3D:
	if is_equal_approx(window_x, -5.45):
		return office._west_perch_04_presentation
	if is_equal_approx(window_x, -9.10):
		return office._west_perch_05_presentation
	return core_parent


func _build_office() -> void:
	_build_physical_presentation_roots()
	var shell := Node3D.new()
	shell.name = "OfficeShell"
	office._core_office_presentation.add_child(shell)
	var carpet := office._add_box(shell, "Carpet", Vector3(Office.OFFICE_WIDTH, 0.18, Office.OFFICE_DEPTH), Vector3(0.0, -0.11, 0.0), Color("293f4d"))
	carpet.material_override = Office.SurfaceFinish.material(&"tile", Color("344956"), 0.32)
	# A finished cutaway base frames the diorama without covering the walking floor.
	office._add_box(shell, "DioramaFoundation", Vector3(Office.OFFICE_WIDTH + 0.12, 0.36, Office.OFFICE_DEPTH + 0.12), Vector3(0.0, -0.36, 0.0), Color("192b37"))
	office._add_box(shell, "FoundationFrontInlay", Vector3(Office.OFFICE_WIDTH - 0.12, 0.025, 0.012), Vector3(0.0, -0.24, Office.OFFICE_DEPTH * 0.5 + 0.065), Color("af8d51"))
	office._add_box(shell, "FoundationSideInlay", Vector3(0.012, 0.025, Office.OFFICE_DEPTH - 0.12), Vector3(Office.OFFICE_WIDTH * 0.5 + 0.065, -0.24, 0.0), Color("af8d51"))
	office._add_box(shell, "BackWall", Vector3(Office.OFFICE_WIDTH, 3.65, 0.2), Vector3(0.0, 1.77, -8.9), Color("d0c9b5"))
	office._add_box(shell, "LeftWall", Vector3(0.2, 3.65, Office.OFFICE_DEPTH), Vector3(-11.9, 1.77, 0.0), Color("c2bcaa"))
	office._add_box(shell, "BaseboardBack", Vector3(23.5, 0.15, 0.12), Vector3(0.0, 0.16, -8.76), Color("48545a"))
	office._add_box(shell, "BaseboardLeft", Vector3(0.12, 0.15, 17.5), Vector3(-11.76, 0.16, 0.0), Color("48545a"))
	office._add_box(shell, "ExecutiveStrip", Vector3(23.5, 0.09, 0.16), Vector3(0.0, 2.7, -8.74), Color("765540"))
	var runner := office._add_box(shell, "MainAisleRunner", Vector3(22.6, 0.026, 1.65), Vector3(0.0, 0.005, Office.MAIN_AISLE_Z), Color("516f7c"))
	runner.material_override = Office.SurfaceFinish.material(&"linen", Color("476573"), 1.0)
	for runner_side in [-1.0, 1.0]:
		office._add_box(shell, "RunnerBinding", Vector3(22.5, 0.006, 0.035), Vector3(0.0, 0.021, Office.MAIN_AISLE_Z + runner_side * 0.76), Color("b2a379"))
	for lane_x in [-7.95, -1.95, 4.05]:
		var lane_parent := office._west_perch_04_presentation if is_equal_approx(lane_x, -7.95) else shell
		office._add_box(lane_parent, "AccessLane", Vector3(1.3, 0.018, 11.2), Vector3(lane_x, 0.008, 0.55), Color("3c5966"))

	var window_batches: Dictionary = {}
	for window_x in [-9.1, -5.45, -1.8, 1.85, 5.5, 9.15]:
		var window_parent := _window_presentation_parent(window_x, shell)
		if not window_batches.has(window_parent):
			window_batches[window_parent] = {
				"frames": [] as Array[Transform3D],
				"blinds": [] as Array[Transform3D],
				"radiator_fins": [] as Array[Transform3D],
			}
		var batches := window_batches[window_parent] as Dictionary
		var frame_transforms := batches["frames"] as Array[Transform3D]
		var blind_transforms := batches["blinds"] as Array[Transform3D]
		var fin_transforms := batches["radiator_fins"] as Array[Transform3D]
		var window_key := int(round((window_x + 12.0) * 10.0))
		var glazing := office._add_box(window_parent, "Window", Vector3(2.75, 1.38, 0.045), Vector3(window_x, 1.83, -8.76), Color("4d7180"))
		glazing.mesh = OfficeDeskDetails.window_glazing()
		glazing.material_override = OfficeDeskDetails.portrait_material()
		frame_transforms.append(_box_batch_transform(Vector3(2.9, 0.075, 0.075), Vector3(window_x, 2.56, -8.70)))
		office._add_box(window_parent, "WindowSill", Vector3(2.9, 0.075, 0.18), Vector3(window_x, 1.10, -8.67), Color("e0dac6"))
		frame_transforms.append(_box_batch_transform(Vector3(0.075, 1.46, 0.085), Vector3(window_x - 1.41, 1.83, -8.70)))
		frame_transforms.append(_box_batch_transform(Vector3(0.075, 1.46, 0.085), Vector3(window_x + 1.41, 1.83, -8.70)))
		office._add_box(window_parent, "WindowMullion_%d" % window_key, Vector3(0.065, 1.30, 0.075), Vector3(window_x, 1.83, -8.68), Color("34464e"))
		office._add_box(window_parent, "BlindValance", Vector3(2.62, 0.13, 0.12), Vector3(window_x, 2.43, -8.62), Color("c0bba9"))
		for blind_y in [2.18, 1.92]:
			blind_transforms.append(_box_batch_transform(Vector3(2.55, 0.045, 0.075), Vector3(window_x, blind_y, -8.63)))
		office._add_box(window_parent, "Radiator_%d" % window_key, Vector3(2.25, 0.53, 0.24), Vector3(window_x, 0.59, -8.54), Color("707b7e"))
		for fin_x in [-0.72, -0.36, 0.0, 0.36, 0.72]:
			fin_transforms.append(_box_batch_transform(Vector3(0.075, 0.40, 0.055), Vector3(window_x + fin_x, 0.59, -8.39)))
	for parent_value in window_batches:
		var batch_parent := parent_value as Node3D
		var batches := window_batches[batch_parent] as Dictionary
		_add_box_multimesh(batch_parent, "WindowFrameBatch", batches["frames"] as Array[Transform3D], Color("34464e"))
		_add_box_multimesh(batch_parent, "WindowBlindSlatBatch", batches["blinds"] as Array[Transform3D], Color("b7b5aa"))
		_add_box_multimesh(batch_parent, "WindowRadiatorFinBatch", batches["radiator_fins"] as Array[Transform3D], Color("aab2ae"))

	_build_architecture_detail(shell)
	_build_office_decor(shell)
	_build_window_farm_view(shell)
	_build_floor_story(shell)
	_build_wall_story(office._archive_presentation, shell)
	office._apply_shadow_allowlist(shell, Office.CORE_OFFICE_STRUCTURAL_SHADOW_HOSTS)
	office._apply_shadow_allowlist(
		office._west_lease_partition,
		[],
		Office.WEST_LEASE_STRUCTURAL_SHADOW_PREFIXES,
	)

	var desks := Node3D.new()
	desks.name = "ClaimsDesks"
	office.add_child(desks)
	var initial_snapshot := office._simulation.snapshot()
	var initial_capacity := office._office_capacity_from_snapshot(initial_snapshot)
	for index in Office.MAXIMUM_OFFICE_CAPACITY:
		var position := office.desk_position(index)
		office._desk_positions.append(position)
		_build_workstation(desks, index, position)
		_build_capacity_authorization_marker(desks, index, position)
	office._displayed_office_capacity = initial_capacity
	office._apply_office_capacity_visibility(initial_capacity, false)
	office._workstation_feedback = Office.WorkstationFeedbackScript.new() as WorkstationFeedback
	office._workstation_feedback.name = "WorkstationFeedback"
	office.add_child(office._workstation_feedback)
	office._workstation_feedback.configure(desks)
	office._workstation_feedback.routing_reward_presented.connect(office._on_routing_reward_presented)
	office._workstation_feedback.dispatch_landing_presented.connect(office._on_dispatch_landing_presented)
	office._workstation_feedback.dispatch_work_started_presented.connect(
		office._on_dispatch_work_started_presented
	)
	office._workstation_feedback.work_progress_interactions_changed.connect(
		office._sync_work_progress_interactions
	)

	var intake := Node3D.new()
	intake.name = "ClaimIntake"
	office._intake_presentation.add_child(intake)
	office._add_box(intake, "IntakeCounter", Vector3(2.25, 1.0, 2.2), Vector3(9.55, 0.5, 5.35), Color("735f4d"))
	office._add_box(intake, "IntakeTop", Vector3(2.45, 0.14, 2.4), Vector3(9.55, 1.05, 5.35), Color("a58b69"))
	_build_intake_detail(intake)
	var basket := Node3D.new()
	basket.name = "ExecutiveEggBasket"
	office._intake_presentation.add_child(basket)
	office._add_box(basket, "BasketInterior", Vector3(2.02, 0.42, 1.48), Vector3(9.4, 0.32, -6.85), Color("694833"))
	office._add_box(basket, "PresentationPlinth", Vector3(2.7, 0.18, 2.1), Vector3(9.4, 0.10, -6.85), Color("c3ab82"))
	var credit_slip_host := _build_presentation_detail(basket)
	Office.EnvironmentalSignageScript.add_panel(
		credit_slip_host, "PresentationPlaqueText", "FARMER CREDIT",
		Vector3(0.0, 0.0, 0.057), Vector2(0.96, 0.075),
		Color("a87849"), Color("49372a"), Vector3.ZERO,
		11, 0.0021, &"utility", &"stencil"
	)
	office._apply_shadow_allowlist(office._intake_presentation, Office.INTAKE_STRUCTURAL_SHADOW_HOSTS)

	office._egg_layer = Node3D.new()
	office._egg_layer.name = "EggsInTransit"
	office.add_child(office._egg_layer)
	_build_egg_fleck_pool()

	office._workers_node = Node3D.new()
	office._workers_node.name = "Workers"
	office.add_child(office._workers_node)
	var arrival_order := 0
	for worker_value in initial_snapshot.get("workers", []):
		var worker_data := worker_value as Dictionary
		if not office._is_worker_employed(worker_data):
			continue
		office._spawn_worker_view(worker_data, arrival_order)
		arrival_order += 1
	office._refresh_workstation_nameplates(initial_snapshot)

	office._management_presence = Office.ManagementPresenceScript.new() as ManagementPresence
	office.add_child(office._management_presence)
	office._management_presence.review_finished.connect(office._on_farmer_review_finished)

	office._camera_controller = Office.ManagementCameraControllerScript.new() as ManagementCameraController
	office._camera_controller.name = "ManagementCameraController"
	office.add_child(office._camera_controller)
	office._camera_controller.configure(office._management_camera, office._worker_views, Office.CORE_OVERVIEW_TARGET)
	office._camera_controller.focus_changed.connect(office._on_camera_focus_changed)
	office._camera_controller.context_action_selected.connect(office._on_work_progress_context_selected)
	office._camera_controller.context_hover_changed.connect(office._on_management_context_hover_changed)
	_sync_work_progress_interactions()


func _build_architecture_detail(parent: Node3D) -> void:
	# Paneled lower walls give the large cream shell a more crafted farm-office feel.
	office._add_box(parent, "WainscotBack", Vector3(23.5, 0.86, 0.055), Vector3(0.0, 0.76, -8.775), Color("3f5a58"))
	office._add_box(parent, "WainscotLeft", Vector3(0.055, 0.86, 17.5), Vector3(-11.775, 0.76, 0.0), Color("3f5a58"))
	office._add_box(parent, "WainscotCapBack", Vector3(23.5, 0.055, 0.095), Vector3(0.0, 1.21, -8.745), Color("b49b70"))
	office._add_box(parent, "WainscotCapLeft", Vector3(0.095, 0.055, 17.5), Vector3(-11.745, 1.21, 0.0), Color("b49b70"))
	var battens: Array[Transform3D] = []
	for panel_index in 16:
		battens.append(_box_batch_transform(Vector3(0.035, 0.78, 0.025), Vector3(-11.4 + panel_index * 1.5, 0.76, -8.73)))
	for panel_index in 12:
		battens.append(_box_batch_transform(Vector3(0.025, 0.78, 0.035), Vector3(-11.73, 0.76, -8.4 + panel_index * 1.5)))
	_add_box_multimesh(parent, "WainscotBattenBatch", battens, Color("60746a"), GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	office._add_box(parent, "CrownMoldingBack", Vector3(23.55, 0.13, 0.16), Vector3(0.0, 3.48, -8.72), Color("e4deca"))
	office._add_box(parent, "CrownMoldingLeft", Vector3(0.16, 0.13, 17.55), Vector3(-11.72, 3.48, 0.0), Color("ddd6c3"))
	office._add_box(parent, "CableChannelBack", Vector3(23.1, 0.16, 0.13), Vector3(0.0, 0.36, -8.69), Color("657176"))

	# Wall-mounted light boxes add warm depth without floating over or obscuring workers.
	for light_index in 3:
		var light_x: float = [-7.6, 0.0, 7.6][light_index]
		var light_parent := office._west_perch_04_presentation if light_index == 0 else parent
		var light_y := 3.44 if light_index == 1 else 3.20
		var fixture_width := 1.75 if light_index == 1 else 3.25
		var lens_width := 1.48 if light_index == 1 else 2.92
		var frame_z := -8.69 if light_index == 1 else -8.63
		var lens_z := -8.665 if light_index == 1 else -8.53
		office._add_box(light_parent, "WallLightFrame", Vector3(fixture_width, 0.20, 0.16), Vector3(light_x, light_y, frame_z), Color("425057"))
		var lens := office._add_box(light_parent, "WallLightLens_%d" % light_index, Vector3(lens_width, 0.08, 0.08), Vector3(light_x, light_y - 0.01, lens_z), Color("f4dfaa"))
		lens.material_override = office._emissive_material(Color("f4dfaa"), 0.55)
		if light_index == 1:
			# The compact center fixture is a deliberate picture light clamped to
			# the bureau fascia, not another floating strip crossing its copy.
			for arm_x in [-0.58, 0.58]:
				var arm_name := "IdentityLightArmLeft" if arm_x < 0.0 else "IdentityLightArmRight"
				office._add_box(parent, arm_name, Vector3(0.055, 0.20, 0.055), Vector3(arm_x, 3.36, -8.67), Color("6d6757"))

	Office.EnvironmentalSignageScript.add_architectural_identity(
		parent,
		"BureauIdentity",
		"EGG YIELD BUREAU",
		"CLUTCH INTAKE & CREDIT",
		Vector3(0.0, 3.00, -8.63),
		Vector2(6.40, 0.74)
	)

	var clock_rim := _add_cylinder(parent, "OfficeClockRim", Vector3(9.95, 3.03, -8.57), 0.43, 0.08, Color("39474d"))
	clock_rim.rotation_degrees.x = 90.0
	clock_rim.material_override = office._material(Color("39474d"), 0.34, 0.48)
	var clock_face := _add_cylinder(parent, "OfficeClockFace", Vector3(9.95, 3.03, -8.50), 0.36, 0.055, Color("e7e0cd"))
	clock_face.rotation_degrees.x = 90.0
	office._add_box(parent, "OfficeClockHourHand", Vector3(0.19, 0.045, 0.035), Vector3(10.02, 3.03, -8.45), Color("343d40"))
	var minute_hand := office._add_box(parent, "OfficeClockMinuteHand", Vector3(0.04, 0.25, 0.035), Vector3(9.95, 3.12, -8.44), Color("343d40"))
	minute_hand.rotation_degrees.z = -18.0


func _build_intake_detail(parent: Node3D) -> void:
	var front_inset := office._add_box(
		parent,
		"IntakeFrontInset",
		Vector3(1.75, 0.58, 0.06),
		Vector3(9.55, 0.52, 6.48),
		Color("4b4037"),
	)
	Office.EnvironmentalSignageScript.add_panel(
		front_inset,
		"IntakeIdentityPlaque",
		"FARMER COLLECTION",
		Vector3(0.0, -0.15, 0.033),
		Vector2(1.36, 0.16),
		Color("4b4037"),
		Color("d7c99f"),
		Vector3.ZERO,
		16,
		0.0038,
		&"secondary",
		&"stencil",
	)
	for slot_x in [-0.52, 0.0, 0.52]:
		office._add_box(parent, "IntakeMailSlot", Vector3(0.38, 0.09, 0.035), Vector3(9.55 + slot_x, 0.58, 6.53), Color("d4b46c"))

	for layer_index in 5:
		var layer_color := Color("dcd7c7") if layer_index % 2 == 0 else Color("c8d2ce")
		office._add_box(
			parent,
			"IntakeClaimBundle",
			Vector3(0.86, 0.035, 0.98),
			Vector3(9.50 + layer_index * 0.018, 1.17 + layer_index * 0.038, 5.35 - layer_index * 0.012),
			layer_color
		)
	office._add_box(parent, "IntakeBundleBand", Vector3(0.16, 0.24, 1.02), Vector3(9.55, 1.25, 5.35), Color("a3473b"))

	var bell_base := _add_cylinder(parent, "IntakeBellBase", Vector3(10.35, 1.17, 4.77), 0.18, 0.06, Color("735f4d"))
	bell_base.material_override = office._material(Color("735f4d"), 0.34, 0.52)
	var bell := _add_sphere(parent, "IntakeServiceBell", Vector3(10.35, 1.25, 4.77), Vector3(0.28, 0.18, 0.28), Color("c49a4b"))
	bell.material_override = office._material(Color("c49a4b"), 0.26, 0.72)
	_add_cylinder(parent, "IntakeStampHandle", Vector3(8.76, 1.30, 4.92), 0.08, 0.28, Color("6f3d30"))
	office._add_box(parent, "IntakeStampPad", Vector3(0.34, 0.06, 0.30), Vector3(8.76, 1.17, 4.92), Color("2d373b"))

	# A tiny weighing/candling station makes the farmer's review area read as egg
	# logistics rather than a generic reception desk.
	office._add_box(parent, "EggScaleBase", Vector3(0.58, 0.12, 0.48), Vector3(10.10, 1.17, 5.73), Color("506269"))
	_add_cylinder(parent, "EggScaleDial", Vector3(10.10, 1.42, 5.79), 0.20, 0.10, Color("e5dfca")).rotation_degrees.x = 90.0
	office._add_box(parent, "EggScaleNeedle", Vector3(0.025, 0.15, 0.025), Vector3(10.10, 1.46, 5.73), Color("a4493e")).rotation_degrees.z = -24.0
	_add_cylinder(parent, "EggScalePan", Vector3(10.10, 1.34, 5.46), 0.26, 0.06, Color("b6beb9"))
	_add_cylinder(parent, "CandlingLampStem", Vector3(9.02, 1.42, 5.80), 0.045, 0.48, Color("4d5557"))
	var candling_lamp := _add_sphere(parent, "CandlingLamp", Vector3(9.02, 1.70, 5.80), Vector3(0.25, 0.17, 0.25), Color("e3bd66"))
	candling_lamp.material_override = office._emissive_material(Color("e3bd66"), 0.75)

	for carton_index in 2:
		office._add_box(parent, "IntakeEggCarton", Vector3(0.72, 0.10, 0.38), Vector3(8.95, 1.16 + carton_index * 0.10, 5.55), Color("aab49f"))
		for cup_index in 3:
			_add_sphere(parent, "CartonCup", Vector3(8.72 + cup_index * 0.23, 1.23 + carton_index * 0.10, 5.55), Vector3(0.09, 0.055, 0.10), Color("859283"))


func _build_presentation_detail(parent: Node3D) -> MeshInstance3D:
	var credit_slip_host: MeshInstance3D = null
	for slat_y in [0.24, 0.42, 0.60]:
		var front_slat := office._add_box(parent, "BasketFrontSlat", Vector3(2.22, 0.11, 0.10), Vector3(9.4, slat_y, -5.99), Color("a87849"))
		if is_equal_approx(slat_y, 0.42):
			front_slat.name = "BasketFrontSlatCreditHost"
			credit_slip_host = front_slat
		office._add_box(parent, "BasketBackSlat", Vector3(2.22, 0.11, 0.10), Vector3(9.4, slat_y, -7.71), Color("8d623f"))
	for side_x in [8.31, 10.49]:
		for slat_y in [0.24, 0.42, 0.60]:
			office._add_box(parent, "BasketSideSlat", Vector3(0.10, 0.11, 1.72), Vector3(side_x, slat_y, -6.85), Color("986b44"))
		office._add_box(parent, "BasketHandlePost", Vector3(0.12, 1.08, 0.12), Vector3(side_x, 0.88, -6.85), Color("6f4d36"))
	office._add_box(parent, "BasketHandle", Vector3(2.30, 0.13, 0.13), Vector3(9.4, 1.40, -6.85), Color("6f4d36"))
	var corner_fittings: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		for end in [-1.0, 1.0]:
			corner_fittings.append(_box_batch_transform(Vector3(0.13, 0.52, 0.025), Vector3(9.4 + side * 1.095, 0.42, -6.85 + end * 0.925)))
			corner_fittings.append(_box_batch_transform(Vector3(0.025, 0.52, 0.13), Vector3(9.4 + side * 1.15, 0.42, -6.85 + end * 0.86)))
	var fittings := _add_box_multimesh(parent, "BasketCornerFittings", corner_fittings, Color("5e6965"), GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	fittings.material_override = office._material(Color("5e6965"), 0.58, 0.0)
	# The basket begins physically empty. OfficeStorytelling now owns every visible
	# clutch egg and only fills these cups after a real seated-hen delivery lands.
	return credit_slip_host


func _build_baseline_breakroom(parent: Node3D) -> void:
	# This is visual-only perimeter dressing. The open center remains the authored
	# six-hen wellness destination and the access lane at x=-7.95 stays clear.
	var breakroom := Node3D.new()
	breakroom.name = "BaselineBreakroom"
	breakroom.set_meta(&"visual_only", true)
	breakroom.set_meta(&"collision_free", true)
	breakroom.set_meta(&"navigation_free", true)
	breakroom.set_meta(&"wellness_routes_clear", true)
	parent.add_child(breakroom)

	# A continuous baseboard and two warm wall lights visually claim this corner
	# as a room rather than a loose group of props placed on the office floor.
	office._add_box(
		breakroom,
		"BreakroomWallBaseboard",
		Vector3(0.10, 0.22, 6.25),
		Vector3(-11.77, 0.12, -0.38),
		Color("52645e"),
	)
	for sconce_index in 2:
		var sconce_z := -2.72 + sconce_index * 4.48
		_add_cylinder(
			breakroom,
			"BreakroomSconceMount_%02d" % sconce_index,
			Vector3(-11.64, 2.92, sconce_z),
			0.16,
			0.10,
			Color("775e42"),
		).rotation_degrees.z = 90.0
		office._add_box(
			breakroom,
			"BreakroomSconceArm_%02d" % sconce_index,
			Vector3(0.25, 0.055, 0.055),
			Vector3(-11.49, 2.92, sconce_z),
			Color("775e42"),
		)
		var sconce_glow := _add_sphere(
			breakroom,
			"BreakroomSconceGlow_%02d" % sconce_index,
			Vector3(-11.32, 2.86, sconce_z),
			Vector3(0.22, 0.19, 0.22),
			Color("efcd83"),
		)
		sconce_glow.material_override = office._emissive_material(Color("efcd83"), 0.88)
		sconce_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# Layered low-poly ovals give the rug a bound edge and woven center instead
	# of reading as a highlighted gameplay square.
	var rug_binding := _add_cylinder(
		breakroom,
		"BreakroomRugBinding",
		Vector3(-9.80, 0.018, 0.0),
		2.04,
		0.036,
		Color("c1a15b"),
	)
	rug_binding.scale.z = 1.06
	var wellness_rug := _add_cylinder(
		breakroom,
		"WellnessRug",
		Vector3(-9.80, 0.041, 0.0),
		1.91,
		0.030,
		Color("79765f"),
	)
	wellness_rug.scale.z = 1.06
	var rug_medallion := _add_cylinder(
		breakroom,
		"BreakroomRugMedallion",
		Vector3(-9.80, 0.062, 0.0),
		1.16,
		0.014,
		Color("a0a88a"),
	)
	rug_medallion.scale.z = 0.72
	# The overhead room name stays legible in the management overview. It is
	# mounted to the perimeter wall, so the six wellness destinations and lane
	# below remain exactly where their routes expect them.
	Office.EnvironmentalSignageScript.add_panel(
		breakroom, "BreakroomOverviewSign", "BREAK ROOM",
		Vector3(-11.50, 2.92, 0.02), Vector2(2.35, 0.32),
		Color("475e55"), Color("f0dfac"), Vector3(0.0, 90.0, 0.0),
		24, 0.0080, &"primary", &"room"
	)
	for stripe_index in 5:
		var stripe_z := -0.54 + stripe_index * 0.27
		var stripe := office._add_box(
			breakroom,
			"BreakroomRugWeave_%02d" % stripe_index,
			Vector3(1.42 - absf(stripe_z) * 0.58, 0.008, 0.035),
			Vector3(-9.80, 0.072, stripe_z),
			Color("a9b39a") if stripe_index % 2 == 0 else Color("b58f5b"),
		)
		stripe.rotation_degrees.y = -8.0

	# Compact kitchenette beside the existing cooler: cabinets, counter, coffee,
	# snacks, mugs, and a microwave create a familiar silhouette from overview.
	office._add_box(
		breakroom,
		"BreakroomKitchenCabinet",
		Vector3(0.62, 0.88, 1.62),
		Vector3(-11.39, 0.45, -1.92),
		Color("6e8179"),
	)
	office._add_box(
		breakroom,
		"BreakroomKitchenCounter",
		Vector3(0.78, 0.12, 1.78),
		Vector3(-11.31, 0.94, -1.92),
		Color("d0bd91"),
	).material_override = office._material(Color("d0bd91"), 0.55, 0.05)
	office._add_box(
		breakroom,
		"BreakroomCabinetToeKick",
		Vector3(0.10, 0.14, 1.48),
		Vector3(-11.04, 0.10, -1.92),
		Color("344a44"),
	)
	office._add_box(
		breakroom,
		"BreakroomTileBacksplash",
		Vector3(0.045, 0.65, 1.72),
		Vector3(-11.67, 1.30, -1.92),
		Color("d8d3c3"),
	)
	for grout_z in [-2.48, -1.92, -1.36]:
		office._add_box(
			breakroom,
			"BreakroomTileGrout",
			Vector3(0.018, 0.61, 0.025),
			Vector3(-11.64, 1.30, grout_z),
			Color("87908a"),
		)
	for grout_y in [1.10, 1.35, 1.60]:
		office._add_box(
			breakroom,
			"BreakroomTileGrout",
			Vector3(0.018, 0.022, 1.66),
			Vector3(-11.64, grout_y, -1.92),
			Color("87908a"),
		)
	for door_z in [-2.28, -1.56]:
		office._add_box(
			breakroom,
			"BreakroomCabinetDoor",
			Vector3(0.035, 0.65, 0.60),
			Vector3(-11.06, 0.46, door_z),
			Color("50675f"),
		)
		office._add_box(
			breakroom,
			"BreakroomCabinetHandle",
			Vector3(0.045, 0.05, 0.20),
			Vector3(-11.03, 0.65, door_z),
			Color("c6a45d"),
		)
	office._add_box(
		breakroom,
		"BreakroomUpperShelf",
		Vector3(0.42, 0.10, 1.70),
		Vector3(-11.53, 1.76, -1.92),
		Color("806849"),
	)
	for bracket_z in [-2.54, -1.30]:
		office._add_box(
			breakroom,
			"BreakroomShelfBracket",
			Vector3(0.28, 0.34, 0.055),
			Vector3(-11.52, 1.57, bracket_z),
			Color("5b4a37"),
		)
	_add_cylinder(
		breakroom,
		"BreakroomCoffeeUrn",
		Vector3(-10.99, 1.30, -2.35),
		0.24,
		0.60,
		Color("52646a"),
	).material_override = office._material(Color("52646a"), 0.36, 0.55)
	_add_cylinder(
		breakroom,
		"BreakroomCoffeeUrnLid",
		Vector3(-10.99, 1.63, -2.35),
		0.255,
		0.06,
		Color("9ca8a6"),
	).material_override = office._material(Color("9ca8a6"), 0.30, 0.65)
	office._add_box(
		breakroom,
		"BreakroomCoffeeSightGlass",
		Vector3(0.035, 0.28, 0.055),
		Vector3(-10.77, 1.34, -2.18),
		Color("9c633d"),
	)
	_add_sphere(
		breakroom,
		"BreakroomCoffeeReadyLight",
		Vector3(-10.75, 1.43, -2.48),
		Vector3(0.055, 0.055, 0.055),
		Color("82c192"),
	).material_override = office._emissive_material(Color("82c192"), 1.5)
	for steam_index in 3:
		var steam := _add_sphere(
			breakroom,
			"BreakroomCoffeeSteam_%02d" % steam_index,
			Vector3(-10.98, 1.72 + steam_index * 0.13, -2.35),
			Vector3(0.055, 0.14, 0.055),
			Color("e9e2cf"),
		)
		steam.visible = false
		steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		office._breakroom_coffee_steam.append(steam)
	office._add_box(
		breakroom,
		"BreakroomCoffeeSpout",
		Vector3(0.18, 0.09, 0.08),
		Vector3(-10.77, 1.18, -2.35),
		Color("252f33"),
	)
	office._add_box(
		breakroom,
		"BreakroomCoffeeDripTray",
		Vector3(0.28, 0.035, 0.30),
		Vector3(-10.77, 1.04, -2.35),
		Color("313c40"),
	)
	office._add_box(
		breakroom,
		"BreakroomMicrowave",
		Vector3(0.48, 0.48, 0.62),
		Vector3(-11.18, 1.25, -1.48),
		Color("a8b0aa"),
	)
	office._add_box(
		breakroom,
		"BreakroomMicrowaveDoor",
		Vector3(0.035, 0.32, 0.39),
		Vector3(-10.92, 1.25, -1.53),
		Color("29383c"),
	)
	for microwave_button_y in [1.18, 1.31]:
		_add_sphere(
			breakroom,
			"BreakroomMicrowaveButton",
			Vector3(-10.90, microwave_button_y, -1.26),
			Vector3(0.050, 0.050, 0.050),
			Color("c8a45b"),
		)
	_add_sphere(
		breakroom,
		"BreakroomSnackTin",
		Vector3(-10.95, 1.09, -1.94),
		Vector3(0.30, 0.16, 0.30),
		Color("bb7a4f"),
	)
	_add_cylinder(
		breakroom,
		"BreakroomSugarJar",
		Vector3(-10.98, 1.14, -1.10),
		0.12,
		0.24,
		Color("d9d2bd"),
	)
	_add_sphere(
		breakroom,
		"BreakroomSugarJarLid",
		Vector3(-10.98, 1.28, -1.10),
		Vector3(0.14, 0.055, 0.14),
		Color("a78a5b"),
	)
	for mug_index in 3:
		var mug_color: Color = [Color("d9d0b8"), Color("bd8062"), Color("6f9285")][mug_index]
		_add_cylinder(
			breakroom,
			"BreakroomMug_%02d" % mug_index,
			Vector3(-11.28, 1.88, -2.35 + mug_index * 0.40),
			0.105,
			0.20,
			mug_color,
		)
		office._add_box(
			breakroom,
			"BreakroomMugHandle_%02d" % mug_index,
			Vector3(0.11, 0.085, 0.045),
			Vector3(-11.15, 1.88, -2.35 + mug_index * 0.40),
			mug_color,
		)

	# A soft bench and a low café table frame the far edge without entering any
	# of the central break positions. Warm cushions make the recovery use obvious.
	office._add_box(
		breakroom,
		"BreakroomSofaBack",
		Vector3(0.20, 1.15, 1.86),
		Vector3(-11.62, 0.82, 1.18),
		Color("576f68"),
	)
	office._add_box(
		breakroom,
		"BreakroomSofaSeat",
		Vector3(0.70, 0.28, 1.72),
		Vector3(-11.31, 0.36, 1.18),
		Color("718a7d"),
	)
	office._add_box(
		breakroom,
		"BreakroomSofaFrontRail",
		Vector3(0.12, 0.18, 1.66),
		Vector3(-10.92, 0.29, 1.18),
		Color("3f5751"),
	)
	for leg_z in [0.46, 1.90]:
		_add_cylinder(
			breakroom,
			"BreakroomSofaLeg",
			Vector3(-11.25, 0.12, leg_z),
			0.075,
			0.24,
			Color("594a3c"),
		)
	for arm_z in [0.28, 2.08]:
		office._add_box(
			breakroom,
			"BreakroomSofaArm",
			Vector3(0.62, 0.52, 0.18),
			Vector3(-11.32, 0.56, arm_z),
			Color("4c635d"),
		)
	for cushion_index in 2:
		_add_sphere(
			breakroom,
			"BreakroomSofaCushion",
			Vector3(-11.16, 0.78, 0.80 + cushion_index * 0.76),
			Vector3(0.24, 0.50, 0.64),
			Color("c08a5c") if cushion_index == 0 else Color("c4aa65"),
		)
	office._add_box(
		breakroom,
		"BreakroomThrowBlanket",
		Vector3(0.035, 0.55, 0.72),
		Vector3(-10.94, 0.54, 1.58),
		Color("b65f4f"),
	).rotation_degrees.x = -16.0
	for fringe_index in 4:
		office._add_box(
			breakroom,
			"BreakroomThrowFringe_%02d" % fringe_index,
			Vector3(0.025, 0.16, 0.025),
			Vector3(-10.90, 0.30, 1.31 + fringe_index * 0.18),
			Color("e2c47b"),
		).rotation_degrees.z = -12.0
	for tuft_z in [0.62, 1.18, 1.74]:
		_add_sphere(
			breakroom,
			"BreakroomSofaTuft",
			Vector3(-11.50, 1.02, tuft_z),
			Vector3(0.045, 0.045, 0.045),
			Color("304944"),
		)
	office._breakroom_lounge_pouf = _add_cylinder(
		breakroom,
		"BreakroomLoungePouf",
		Vector3(-10.68, 0.14, 1.18),
		0.33,
		0.28,
		Color("b98158"),
	)
	office._breakroom_lounge_pouf_rest_y = office._breakroom_lounge_pouf.position.y
	_add_cylinder(
		breakroom,
		"BreakroomLoungePoufPiping",
		Vector3(-10.68, 0.285, 1.18),
		0.345,
		0.025,
		Color("6e543d"),
	)
	_add_cylinder(
		breakroom,
		"BreakroomSideTablePedestal",
		Vector3(-8.82, 0.29, 1.55),
		0.12,
		0.56,
		Color("625342"),
	)
	_add_cylinder(
		breakroom,
		"BreakroomSideTable",
		Vector3(-8.82, 0.60, 1.55),
		0.38,
		0.10,
		Color("b7915e"),
	)
	_add_cylinder(
		breakroom,
		"BreakroomSideTableRim",
		Vector3(-8.82, 0.655, 1.55),
		0.405,
		0.035,
		Color("6b5138"),
	)
	office._breakroom_magazine_pages = office._add_box(
		breakroom,
		"BreakroomMagazinePages",
		Vector3(0.38, 0.022, 0.29),
		Vector3(-8.80, 0.690, 1.54),
		Color("e4dec8"),
	)
	office._breakroom_magazine_pages.rotation_degrees.y = 14.0
	office._breakroom_magazine = office._add_box(
		breakroom,
		"BreakroomMagazine",
		Vector3(0.34, 0.025, 0.25),
		Vector3(-8.80, 0.706, 1.54),
		Color("c8684c"),
	)
	office._breakroom_magazine.rotation_degrees.y = 14.0
	_add_cylinder(
		breakroom,
		"BreakroomTableCoaster",
		Vector3(-8.54, 0.690, 1.78),
		0.12,
		0.018,
		Color("6b8b7d"),
	)
	_add_cylinder(
		breakroom,
		"BreakroomTableCup",
		Vector3(-8.54, 0.785, 1.78),
		0.075,
		0.18,
		Color("d6c9a6"),
	)

	# A physical corkboard fills the blank wall with communal, colorful artifacts.
	office._add_box(
		breakroom,
		"BreakroomCorkboard",
		Vector3(0.055, 1.10, 2.28),
		Vector3(-11.68, 2.18, 0.02),
		Color("9b754e"),
	)
	office._add_box(
		breakroom,
		"BreakroomCorkboardInset",
		Vector3(0.035, 0.92, 2.04),
		Vector3(-11.64, 2.18, 0.02),
		Color("c7a66d"),
	)
	var corkboard_frame_y := [1.61, 2.75]
	for frame_index in corkboard_frame_y.size():
		office._add_box(
			breakroom,
			"BreakroomCorkboardFrameHorizontal_%02d" % frame_index,
			Vector3(0.10, 0.09, 2.38),
			Vector3(-11.60, corkboard_frame_y[frame_index], 0.02),
			Color("6a4933"),
		)
	var corkboard_frame_z := [-1.14, 1.18]
	for frame_index in corkboard_frame_z.size():
		office._add_box(
			breakroom,
			"BreakroomCorkboardFrameVertical_%02d" % frame_index,
			Vector3(0.10, 1.22, 0.09),
			Vector3(-11.60, 2.18, corkboard_frame_z[frame_index]),
			Color("6a4933"),
		)
	var note_layout := [
		[2.38, -0.64, 0.34, 0.40, Color("e6d6a4")],
		[2.08, -0.16, 0.30, 0.48, Color("9eb8af")],
		[2.42, 0.33, 0.34, 0.38, Color("d49371")],
		[1.93, 0.73, 0.28, 0.35, Color("d8cfb9")],
	]
	for note_index in note_layout.size():
		var note := note_layout[note_index] as Array
		var note_color: Color = note[4]
		var pinned_note := office._add_box(
			breakroom,
			"BreakroomPinnedNote_%02d" % note_index,
			Vector3(0.022, float(note[2]), float(note[3])),
			Vector3(-11.61, float(note[0]), float(note[1])),
			note_color,
		)
		office._breakroom_pinned_notes.append(pinned_note)
		_add_sphere(
			breakroom,
			"BreakroomPushPin_%02d" % note_index,
			Vector3(-11.59, float(note[0]) + float(note[2]) * 0.32, float(note[1])),
			Vector3(0.055, 0.055, 0.055),
			Color("8e3f35"),
		)

	# A slatted recycling bin and a small counter plant finish the lived-in edge.
	_add_cylinder(
		breakroom,
		"BreakroomRecycleBin",
		Vector3(-11.18, 0.34, -0.72),
		0.27,
		0.68,
		Color("3f696c"),
	)
	office._add_box(
		breakroom,
		"BreakroomRecycleSlot",
		Vector3(0.32, 0.035, 0.12),
		Vector3(-11.18, 0.70, -0.72),
		Color("17282b"),
	)
	_add_cylinder(
		breakroom,
		"BreakroomPlantPot",
		Vector3(-11.34, 1.13, -1.08),
		0.16,
		0.28,
		Color("b8704d"),
	)
	for leaf_index in 5:
		var leaf := _add_sphere(
			breakroom,
			"BreakroomPlantLeaf_%02d" % leaf_index,
			Vector3(-11.34, 1.36 + leaf_index * 0.035, -1.08),
			Vector3(0.11, 0.34, 0.08),
			Color("4f785c").lightened(0.035 * leaf_index),
		)
		leaf.rotation_degrees = Vector3(18.0, leaf_index * 72.0, -24.0 + leaf_index * 12.0)
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		office._breakroom_plant_leaves.append(leaf)
		office._breakroom_plant_leaf_rest_rotations.append(leaf.rotation)


func _build_office_decor(parent: Node3D) -> void:
	# Decor is kept in perimeter alcoves, leaving every circulation lane unobstructed.
	_build_baseline_breakroom(parent)
	office._add_box(parent, "WaterCoolerBase", Vector3(0.68, 0.95, 0.62), Vector3(-11.05, 0.48, -3.15), Color("c7d0cd"))
	_add_cylinder(parent, "WaterJug", Vector3(-11.05, 1.25, -3.15), 0.26, 0.62, Color("73959e"))
	for bubble_index in 4:
		var bubble := _add_sphere(
			parent,
			"BreakroomCoolerBubble_%02d" % bubble_index,
			Vector3(-11.05, 1.06 + bubble_index * 0.11, -3.15),
			Vector3(0.045, 0.055, 0.045),
			Color("b9dde0"),
		)
		bubble.material_override = office._emissive_material(Color("8bbfc6"), 0.34)
		bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		office._breakroom_cooler_bubbles.append(bubble)
	office._add_box(parent, "CoolerControlPanel", Vector3(0.45, 0.22, 0.05), Vector3(-11.05, 0.70, -2.82), Color("45565c"))
	office._add_box(parent, "CoolerTapCold", Vector3(0.12, 0.10, 0.13), Vector3(-11.18, 0.71, -2.75), Color("477b91"))
	office._add_box(parent, "CoolerTapWarm", Vector3(0.12, 0.10, 0.13), Vector3(-10.92, 0.71, -2.75), Color("a45d48"))
	office._add_box(parent, "CoolerDripTray", Vector3(0.43, 0.06, 0.20), Vector3(-11.05, 0.49, -2.79), Color("536168"))
	for cup_index in 3:
		_add_cylinder(parent, "PaperCup", Vector3(-10.62, 0.96 + cup_index * 0.10, -3.13), 0.075, 0.12, Color("e2ddce"))
	Office.EnvironmentalSignageScript.add_panel(
		parent, "WellnessZoneLabel", "WELLNESS ROOST\nBREAKS · 7 MIN",
		Vector3(-11.798, 1.72, -3.10), Vector2(1.18, 0.40),
		Color("3d6259"), Color("eadcb6"), Vector3(0.0, 90.0, 0.0),
		15, 0.0044, &"utility", &"room"
	)

	# A wall-mounted visibility board gives the cutaway side of the room a
	# detailed focal point while keeping the wellness/feed floor completely open.
	var pipeline_parent := office._west_perch_05_presentation
	office._add_box(pipeline_parent, "ClaimsPipelineBoard", Vector3(0.075, 1.65, 3.30), Vector3(-11.70, 2.05, 3.60), Color("2b3a3f"))
	var pipeline_inset := office._add_box(
		pipeline_parent,
		"ClaimsPipelineInset",
		Vector3(0.040, 1.38, 3.02),
		Vector3(-11.64, 2.03, 3.60),
		Color("d4ceb9"),
	)
	var pipeline_heights: Array[float] = [0.38, 0.70, 0.50, 0.92, 0.62, 1.08]
	var pipeline_colors: Array[Color] = [Color("477681"), Color("6f8a72"), Color("c39a4c")]
	for bar_index in 6:
		var bar_height: float = pipeline_heights[bar_index]
		var bar_color: Color = pipeline_colors[bar_index % pipeline_colors.size()]
		office._add_box(
			pipeline_parent,
			"ClaimsPipelineBar",
			Vector3(0.035, bar_height, 0.25),
			Vector3(-11.60, 1.45 + bar_height * 0.5, 2.72 + bar_index * 0.35),
			bar_color
		)
	Office.EnvironmentalSignageScript.add_panel(
		pipeline_inset, "ClaimsPipelineLabel", "CLUTCH FLOW",
		Vector3(0.024, 0.60, 0.0), Vector2(1.78, 0.32),
		Color("d4ceb9"), Color("34494e"), Vector3(0.0, 90.0, 0.0),
		20, 0.0074, &"secondary", &"chart"
	)

	office._add_box(parent, "Copier", Vector3(1.45, 1.18, 0.95), Vector3(10.25, 0.59, 0.0), Color("aeb6b5"))
	office._add_box(parent, "CopierLid", Vector3(1.35, 0.18, 0.88), Vector3(10.25, 1.25, -0.08), Color("303a40"))
	office._add_box(parent, "CopierPanel", Vector3(0.5, 0.09, 0.3), Vector3(10.25, 1.35, 0.28), Color("54747b"))
	office._add_box(parent, "CopierOutputTray", Vector3(0.92, 0.10, 0.60), Vector3(10.25, 0.88, 0.50), Color("3e494e"))
	for paper_index in 4:
		office._add_box(parent, "CopierOutputPaper", Vector3(0.78, 0.018, 0.50), Vector3(10.24 + paper_index * 0.012, 0.95 + paper_index * 0.022, 0.52), Color("dedbcc"))
	for button_index in 4:
		var button_color := Color("7db2a2") if button_index == 3 else Color("d0d5ce")
		office._add_box(parent, "CopierButton", Vector3(0.045, 0.035, 0.045), Vector3(10.28 + button_index * 0.06, 1.41, 0.29), button_color)
	office._add_box(parent, "CopierPaperDrawer", Vector3(1.08, 0.08, 0.055), Vector3(10.25, 0.43, 0.49), Color("667277"))
	office._add_box(parent, "CopierPaperDrawer", Vector3(1.08, 0.08, 0.055), Vector3(10.25, 0.23, 0.49), Color("667277"))
	# Recesses and service details make the copier read as a built machine.
	office._add_box(parent, "CopierBase", Vector3(1.40, 0.13, 0.91), Vector3(10.25, 0.08, 0), Color("33454a"))
	office._add_box(parent, "CopierOutputMouth", Vector3(0.82, 0.13, 0.03), Vector3(10.25, 1.02, 0.485), Color("18292c"))
	var copier_screen := office._add_box(parent, "CopierStatusGlass", Vector3(0.19, 0.014, 0.17), Vector3(10.12, 1.405, 0.27), Color("28494c"))
	copier_screen.material_override = office._material(Color("28494c"), 0.25)
	office._add_box(parent, "CopierStatusLine", Vector3(0.12, 0.005, 0.018), Vector3(10.12, 1.415, 0.27), Color("a5c9ab"))
	var vents: Array[Transform3D] = []
	for index in 7:
		vents.append(_box_batch_transform(Vector3(0.014, 0.022, 0.38), Vector3(10.98, 0.44 + index * 0.048, -0.08)))
	_add_box_multimesh(parent, "CopierVentBatch", vents, Color("465b5e"), GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	for drawer_y in [0.28, 0.48]:
		office._add_box(parent, "CopierRecessedPull", Vector3(0.34, 0.035, 0.045), Vector3(10.25, drawer_y, 0.49), Color("d6d7c9"))
	_add_cylinder(parent, "ShredBin", Vector3(11.10, 0.39, 0.58), 0.30, 0.78, Color("3b474b"))
	office._add_box(parent, "ShredBinSlot", Vector3(0.38, 0.035, 0.10), Vector3(11.10, 0.80, 0.58), Color("151d20"))
	for cabinet_x in [-9.9, 8.2]:
		var cabinet_parent := office._archive_presentation if cabinet_x < 0.0 else parent
		office._add_box(cabinet_parent, "FileCabinet", Vector3(0.95, 1.75, 0.78), Vector3(cabinet_x, 0.88, -8.25), Color("647078"))
		for drawer_y in [0.38, 0.78, 1.18]:
			var handle := office._add_box(cabinet_parent, "DrawerHandle", Vector3(0.3, 0.045, 0.065), Vector3(cabinet_x, drawer_y, -7.84), Color("c1c8c4"))
			handle.material_override = office._material(Color("c1c8c4"), 0.30, 0.58)
			office._add_box(cabinet_parent, "DrawerLabel", Vector3(0.34, 0.12, 0.035), Vector3(cabinet_x, drawer_y + 0.13, -7.82), Color("d8d2bd"))
		office._add_box(cabinet_parent, "ArchiveBox", Vector3(0.78, 0.48, 0.66), Vector3(cabinet_x, 2.00, -8.23), Color("b99a6d"))
		office._add_box(cabinet_parent, "ArchiveBoxLabel", Vector3(0.34, 0.14, 0.035), Vector3(cabinet_x, 2.00, -7.88), Color("e1dac5"))
	for plant_x in [-11.0, 10.7]:
		var plant_parent := office._archive_presentation if plant_x < 0.0 else parent
		# Keep the east planter behind the collection drop tube and its moving eggs.
		var plant_z := -7.8 if plant_x > 0.0 else -7.05
		var pot := _add_cylinder(plant_parent, "PlantPot", Vector3(plant_x, 0.30, plant_z), 0.32, 0.6, Color("80513e"))
		var pot_mesh := ProceduralPrimitiveCache.cylinder(0.32, 0.24, 0.6, 24).duplicate() as CylinderMesh
		pot_mesh.cap_top = false
		pot.mesh = pot_mesh
		_add_planter_finish(plant_parent, Vector3(plant_x, 0.60, plant_z), 0.32)
		_add_cylinder(plant_parent, "PlantStem", Vector3(plant_x, 0.88, plant_z), 0.065, 0.92, Color("355b45"))
		for leaf_index in 5:
			var angle := TAU * leaf_index / 5.0
			var leaf_color := Color("466b51") if leaf_index % 2 == 0 else Color("58785b")
			var leaf := MeshInstance3D.new()
			leaf.name = "PlantLeaf"
			leaf.mesh = OfficePropGeometry.leaf()
			leaf.position = Vector3(plant_x, 0.73 + (leaf_index % 2) * 0.17, plant_z)
			leaf.scale = Vector3(1.5, 0.75 + (leaf_index % 2) * 0.10, 1.5)
			leaf.rotation = Vector3(deg_to_rad(28.0 + leaf_index * 5.0), angle, 0)
			leaf.material_override = office._material(leaf_color, 0.63)
			plant_parent.add_child(leaf)

	office._add_box(parent, "ExtinguisherBracket", Vector3(0.52, 0.14, 0.09), Vector3(6.95, 1.08, -8.55), Color("454c4e"))
	_add_cylinder(parent, "SafetyExtinguisher", Vector3(6.95, 1.15, -8.43), 0.20, 0.72, Color("a3473b"))
	office._add_box(parent, "ExtinguisherNozzle", Vector3(0.30, 0.11, 0.12), Vector3(7.15, 1.46, -8.42), Color("282f31"))


func _build_window_farm_view(parent: Node3D) -> void:
	# A continuous low-poly pasture beyond the opaque office glazing. Everything is
	# a paper-thin, non-colliding silhouette behind the mullions, so it adds depth
	# without adding route obstacles or expensive scene geometry.
	var fence_batches: Dictionary = {}
	for window_index in 6:
		var window_x: float = [-9.1, -5.45, -1.8, 1.85, 5.5, 9.15][window_index]
		var window_parent := _window_presentation_parent(window_x, parent)
		if not fence_batches.has(window_parent):
			fence_batches[window_parent] = [] as Array[Transform3D]
		var fence_transforms := fence_batches[window_parent] as Array[Transform3D]
		var pasture := office._add_box(window_parent, "WindowPasture_%d" % window_index, Vector3(2.52, 0.43, 0.022), Vector3(window_x, 1.34, -8.665), Color("668268"))
		pasture.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var hill := _add_sphere(window_parent, "WindowHill_%d" % window_index, Vector3(window_x - 0.48 + (window_index % 2) * 0.75, 1.63, -8.67), Vector3(1.60, 0.48, 0.04), Color("58745e"))
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for fence_post in 3:
			var post_x := window_x - 0.78 + fence_post * 0.78
			fence_transforms.append(_box_batch_transform(Vector3(0.045, 0.42, 0.028), Vector3(post_x, 1.38, -8.635)))
		fence_transforms.append(_box_batch_transform(Vector3(2.18, 0.045, 0.028), Vector3(window_x, 1.34, -8.63)))
		fence_transforms.append(_box_batch_transform(Vector3(2.18, 0.045, 0.028), Vector3(window_x, 1.52, -8.63)))
	for parent_value in fence_batches:
		var batch_parent := parent_value as Node3D
		_add_box_multimesh(
			batch_parent,
			"PastureFenceBatch",
			fence_batches[batch_parent] as Array[Transform3D],
			Color("dccb9e"),
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		)

	# Repeated windows read as one farm campus through a few landmark silhouettes.
	office._add_box(office._west_perch_04_presentation, "DistantBarn", Vector3(1.05, 0.55, 0.035), Vector3(-5.45, 1.58, -8.61), Color("8e4f43")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var barn_roof := office._add_box(office._west_perch_04_presentation, "DistantBarnRoof", Vector3(1.16, 0.16, 0.04), Vector3(-5.45, 1.89, -8.60), Color("493e38"))
	barn_roof.rotation_degrees.z = 8.0
	barn_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_cylinder(parent, "DistantSilo", Vector3(5.18, 1.62, -8.61), 0.23, 0.82, Color("9ca4a0")).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_floor_story(parent: Node3D) -> void:
	# Subtle wear, feed kernels, and directional chevrons make the floor feel used.
	# At 2 cm or less, these remain visual decals and cannot affect navigation.
	var scuff_batches: Dictionary = {}
	for lane_index in 3:
		var lane_x: float = [-7.95, -1.95, 4.05][lane_index]
		var lane_parent := office._west_perch_04_presentation if lane_index == 0 else parent
		if not scuff_batches.has(lane_parent):
			scuff_batches[lane_parent] = [] as Array[Transform3D]
		var scuff_transforms := scuff_batches[lane_parent] as Array[Transform3D]
		for mark_index in 3:
			var mark_z := -3.6 + mark_index * 3.7
			scuff_transforms.append(_box_batch_transform(
				Vector3(0.72, 0.008, 0.24),
				Vector3(lane_x, 0.022, mark_z),
				Vector3(0.0, -12.0 + lane_index * 8.0, 0.0),
			))
		for chevron_side in [-1.0, 1.0]:
			var chevron := office._add_box(lane_parent, "PeckFlowChevron_%d_%d" % [lane_index, int(chevron_side)], Vector3(0.32, 0.010, 0.075), Vector3(lane_x + chevron_side * 0.11, 0.026, 5.68), Color("c59a4d"))
			chevron.rotation_degrees.y = chevron_side * 34.0
			chevron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for parent_value in scuff_batches:
		var batch_parent := parent_value as Node3D
		_add_box_multimesh(
			batch_parent,
			"PeckLaneScuffBatch",
			scuff_batches[batch_parent] as Array[Transform3D],
			Color(0.28, 0.37, 0.38, 0.75),
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		)

	for kernel_index in 12:
		var kernel_x := -11.05 + (kernel_index % 4) * 0.22
		var kernel_z := -1.02 + int(kernel_index / 4) * 0.24
		var kernel := _add_sphere(office._west_perch_05_presentation, "StrayFeedKernel_%d" % kernel_index, Vector3(kernel_x, 0.045, kernel_z), Vector3(0.055, 0.025, 0.085), Color("d0a84f"))
		kernel.rotation_degrees.y = kernel_index * 31.0
		kernel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_wall_story(archive_parent: Node3D, safety_parent: Node3D) -> void:
	# Farm-bureau propaganda occupies the unused left-wall strips and stays clear of
	# the wellness zone, pipeline board, and every circulation lane.
	office._add_box(archive_parent, "HenOfMonthFrame", Vector3(0.055, 1.56, 1.75), Vector3(-11.68, 2.05, -5.55), Color("584b3c"))
	var hen_of_month_card := office._add_box(
		archive_parent,
		"HenOfMonthCard",
		Vector3(0.035, 1.35, 1.54),
		Vector3(-11.63, 2.05, -5.55),
		Color("e4dcc4"),
	)
	var portrait := _add_sphere(archive_parent, "HenOfMonthPortrait", Vector3(-11.59, 2.08, -5.55), Vector3(0.04, 0.43, 0.43), Color("d79b63"))
	portrait.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Office.EnvironmentalSignageScript.add_panel(
		hen_of_month_card, "HenOfMonthLabel", "HEN OF THE MONTH",
		Vector3(0.021, 0.53, 0.0), Vector2(1.28, 0.28),
		Color("e4dcc4"), Color("514135"), Vector3(0.0, 90.0, 0.0),
		17, 0.0058, &"secondary", &"portrait"
	)

	var safety_label := Office.EnvironmentalSignageScript.add_panel(
		safety_parent, "CoopSafetyLabel", "AISLE SAFETY\nKeep wings tucked",
		Vector3(-11.798, 2.25, 6.45), Vector2(0.96, 0.56),
		Color("d8d5c4"), Color("31515b"), Vector3(0.0, 90.0, 0.0),
		14, 0.0038, &"secondary", &"paper"
	)
	var safety_fixture := safety_label.get_parent() as Node3D
	# A permanent folded-wing pictogram keeps the distant sheet recognizable as
	# safety signage even while its close-reading copy is spatially suppressed.
	for wing_side in [-1.0, 1.0]:
		var wing_mark := office._add_box(
			safety_fixture,
			"SafetyWingMarkLeft" if wing_side < 0.0 else "SafetyWingMarkRight",
			Vector3(0.24, 0.025, 0.0014),
			Vector3(wing_side * 0.105, -0.255, 0.0053),
			Color("546c69")
		)
		wing_mark.rotation_degrees.z = wing_side * 28.0


func _build_feed_party_station() -> void:
	if office._feed_party_station != null:
		return
	office._feed_party_station = Node3D.new()
	office._feed_party_station.name = "FeedPartyStation"
	office._feed_party_station.position = Office.FEED_PARTY_STATION_POSITION
	office._feed_party_station.visible = false
	office.add_child(office._feed_party_station)

	if ResourceLoader.exists(Office.FEED_PARTY_STATION_PATH):
		var station_scene := load(Office.FEED_PARTY_STATION_PATH) as PackedScene
		if station_scene != null:
			var model := station_scene.instantiate() as Node3D
			model.name = "FeedPartyStationModel"
			model.scale = Vector3.ONE * Office.FEED_PARTY_STATION_SCALE
			office._feed_party_station.add_child(model)
			for wheel_name in [
				"TroughCasterWheel_FrontL",
				"TroughCasterWheel_FrontR",
				"TroughCasterWheel_RearL",
				"TroughCasterWheel_RearR",
			]:
				var wheel := model.find_child(wheel_name, true, false) as Node3D
				if wheel == null:
					continue
				wheel.set_meta("feed_party_base_rotation_x", wheel.rotation.x)
				office._feed_party_wheels.append(wheel)
	else:
		# Keeps the event testable while the Blender source is being regenerated.
		office._add_box(office._feed_party_station, "FallbackTrough", Vector3(2.67, 0.55, 0.72), Vector3(0.0, 0.34, 0.0), Color("6f7875"))
		office._add_box(office._feed_party_station, "FallbackFeed", Vector3(2.48, 0.08, 0.58), Vector3(0.0, 0.65, 0.0), Color("c9a14f"))

	# The Blender-authored trough already carries dimensional FEED PARTY and
	# ATTENDANCE REQUIRED lettering. A second runtime sign made the same prop read
	# like a labeled UI widget, so the model itself now owns its identity.


func _build_workstation(parent: Node3D, index: int, origin: Vector3) -> void:
	var workstation := Office.WorkstationScene.instantiate() as Node3D
	workstation.name = "Workstation_%02d" % index
	workstation.position = origin
	parent.add_child(workstation)
	office._workstations_by_index[index] = workstation
	# Shared finishes preserve imported meshes and every interaction mounting point.
	var partition_colors: Array[Color] = [Color("577e78"), Color("9a7058"), Color("98874f"), Color("586f87"), Color("826985"), Color("668060")]
	for partition_name in ["CubicleBack", "CubicleWing_L"]:
		var partition := workstation.find_child(partition_name, true, false) as MeshInstance3D
		if partition != null:
			partition.material_override = Office.SurfaceFinish.material(&"linen", partition_colors[index % partition_colors.size()], 2.0)
	for wood_name in ["DeskSurface", "DeskFrontTrim"]:
		var wood := workstation.find_child(wood_name, true, false) as MeshInstance3D
		if wood != null:
			wood.material_override = Office.SurfaceFinish.material(&"wood", Color("b38b5d"), 0.8)
	var top_trim := workstation.find_child("PanelTopTrim", true, false) as MeshInstance3D
	if top_trim != null:
		top_trim.material_override = office._material(Color("31474d"), 0.72)
	_decorate_workstation(workstation, index)
	_apply_workstation_shadow_budget(workstation)


func _apply_workstation_shadow_budget(workstation: Node3D) -> void:
	# One authored workstation contains 24 imported meshes plus small personal
	# props. Preserve grounding shadows on its actual furniture and partitions,
	# while paper, screens, controls, stationery, and decorative accents receive
	# those shadows instead of submitting a second invisible depth pass.
	for candidate in workstation.find_children("*", "GeometryInstance3D", true, false):
		var geometry := candidate as GeometryInstance3D
		if geometry == null:
			continue
		geometry.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if String(geometry.name) in Office.WORKSTATION_STRUCTURAL_SHADOW_HOSTS
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)


func _decorate_workstation(workstation: Node3D, index: int) -> void:
	# Deterministic personal details keep the desks distinct without introducing
	# random visual noise or placing anything in chair/access-lane space.
	var accent_colors: Array[Color] = [Color("8ba6a0"), Color("c88b62"), Color("c2a657"), Color("7289a0"), Color("9a7c9d"), Color("718d68")]
	var accent := accent_colors[index % accent_colors.size()]
	var inlay := workstation.find_child("DeskMat", true, false) as MeshInstance3D
	if inlay != null:
		# Replace the floating imported slab in its existing draw slot. The mesh
		# includes the coaster and is authored in workstation-local coordinates.
		inlay.mesh = OfficeDeskDetails.desk_inlay()
		inlay.transform = Transform3D.IDENTITY
		inlay.material_override = OfficeDeskDetails.portrait_material()
		inlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mug := workstation.find_child("CoffeeMug", true, false) as MeshInstance3D
	if mug != null:
		# The imported material does not enable the authored ceramic/coffee colors.
		mug.material_override = OfficeDeskDetails.ceramic_material()
		mug.position.y += 0.009
	var chair := workstation.find_child("ChairSeat", true, false) as MeshInstance3D
	if chair != null:
		for surface_index in chair.mesh.get_surface_count():
			var source := chair.mesh.surface_get_material(surface_index)
			if source != null and source.resource_name == "Desk mat":
				chair.set_surface_override_material(surface_index, Office.SurfaceFinish.material(&"linen", accent.darkened(0.28), 5.0))
	# A bounded textile island gives each perch a readable footprint. It belongs
	# to the desk so unbuilt perches hide it and it never changes navigation.
	var rug := office._add_box(workstation, "PerchRug", Vector3(3.42, 0.012, 3.32), Vector3(0.0, 0.018, 0.30), accent.darkened(0.48))
	rug.material_override = Office.SurfaceFinish.material(&"linen", accent.darkened(0.42), 1.35)
	rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side in [-1.0, 1.0]:
		var seam := office._add_box(workstation, "RugSeam", Vector3(0.025, 0.006, 3.10), Vector3(side * 1.58, 0.028, 0.30), accent.darkened(0.15))
		seam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var edge := office._add_box(workstation, "RugFrontSeam", Vector3(3.18, 0.006, 0.025), Vector3(0.0, 0.028, 1.85), accent.darkened(0.15))
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Double woven borders and a diamond at each corner read at overview distance.
	var rug_inlays: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		rug_inlays.append(_box_batch_transform(Vector3(0.018, 0.006, 2.88), Vector3(side * 1.46, 0.029, 0.30)))
		rug_inlays.append(_box_batch_transform(Vector3(2.92, 0.006, 0.018), Vector3(0.0, 0.029, 0.30 + side * 1.44)))
		for end in [-1.0, 1.0]:
			rug_inlays.append(_box_batch_transform(Vector3(0.13, 0.006, 0.13), Vector3(side * 1.45, 0.030, 0.30 + end * 1.38), Vector3(0.0, 45.0, 0.0)))
	_add_box_multimesh(workstation, "RugWovenInlay", rug_inlays, accent.lightened(0.12), GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var cubicle_back := workstation.find_child("CubicleBack", true, false) as MeshInstance3D
	var nameplate_parent: Node3D = cubicle_back if cubicle_back != null else workstation
	var nameplate_position := (
		Vector3(-0.72, 0.04, 0.052)
		if cubicle_back != null
		else Vector3(-0.82, 1.32, 0.79)
	)
	var nameplate := Office.EnvironmentalSignageScript.add_panel(
		nameplate_parent, "EmployeeNameplateText", "VACANT PERCH\nAUTHORIZED POSITION",
		nameplate_position, Vector2(0.70, 0.24),
		Color("557069"), Color("efe1bd"), Vector3.ZERO,
		15, 0.0037, &"utility", &"partition"
	)
	office._workstation_nameplates[index] = nameplate
	var nameplate_fixture := nameplate.get_parent() as Node3D
	office._add_box(
		nameplate_fixture,
		"NameplateAccentStripe",
		Vector3(0.018, 0.085, 0.002),
		Vector3(0.315, 0.0, 0.010),
		accent.lerp(Color("65716b"), 0.38)
	)

	office._add_box(workstation, "ChickPhotoFrame", Vector3(0.48, 0.46, 0.075), Vector3(0.87, 1.22, 0.39), Color("53493f"))
	office._add_box(workstation, "PhotoEaselFoot", Vector3(0.12, 0.13, 0.12), Vector3(0.87, 0.945, 0.39), Color("53493f"))
	office._add_box(workstation, "ChickPhoto", Vector3(0.39, 0.35, 0.035), Vector3(0.87, 1.22, 0.44), Color("b9d0ca"))
	var portrait := MeshInstance3D.new()
	portrait.name = "ChickPortrait"
	portrait.mesh = OfficeDeskDetails.portrait(index)
	portrait.material_override = OfficeDeskDetails.portrait_material()
	portrait.position = Vector3(0.87, 1.22, 0.47)
	workstation.add_child(portrait)
	# A slim mat and rounded frame keep the miniature visibly mounted.
	var frame_inlay: Array[Transform3D] = []
	for side in [-1.0, 1.0]:
		frame_inlay.append(_box_batch_transform(Vector3(0.012, 0.37, 0.006), Vector3(0.87 + side * 0.202, 1.22, 0.463)))
		frame_inlay.append(_box_batch_transform(Vector3(0.414, 0.012, 0.006), Vector3(0.87, 1.22 + side * 0.181, 0.463)))
	_add_box_multimesh(workstation, "PhotoFrameInlay", frame_inlay, Color("d7c295"), GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)

	var pencil_cup := _add_cylinder(workstation, "PencilCup", Vector3(-1.10, 1.00, 0.47), 0.11, 0.24, accent)
	pencil_cup.material_override = office._material(accent, 0.50)
	var pencil_mesh := (pencil_cup.mesh as CylinderMesh).duplicate() as CylinderMesh
	pencil_mesh.cap_top = false
	pencil_cup.mesh = pencil_mesh
	var pencil_rim := MeshInstance3D.new()
	pencil_rim.name = "PencilCupRolledRim"
	pencil_rim.mesh = OfficePropGeometry.pot_rim()
	pencil_rim.scale = Vector3.ONE * 0.11
	pencil_rim.position = Vector3(-1.10, 1.12, 0.47)
	pencil_rim.material_override = office._material(accent.lightened(0.18), 0.46)
	workstation.add_child(pencil_rim)
	_add_cylinder(workstation, "PencilCupInterior", Vector3(-1.10, 1.095, 0.47), 0.099, 0.012, accent.darkened(0.7))
	for pencil_index in 3:
		var pencil := _add_cylinder(workstation, "Pencil", Vector3(-1.16 + pencil_index * 0.06, 1.20 + (pencil_index % 2) * 0.04, 0.47), 0.015, 0.38, Color("d6ad52"))
		pencil.rotation_degrees.z = -6.0 + pencil_index * 6.0
		pencil.mesh = OfficeDeskDetails.pencil()
		pencil.material_override = OfficeDeskDetails.portrait_material()

	if index % 2 == 0:
		var pot := _add_cylinder(workstation, "DeskPlantPot", Vector3(1.00, 1.08, -0.20), 0.13, 0.22, Color("835d48"))
		var pot_mesh := ProceduralPrimitiveCache.cylinder(0.13, 0.095, 0.22, 20).duplicate() as CylinderMesh
		pot_mesh.cap_top = false
		pot.mesh = pot_mesh
		_add_planter_finish(workstation, Vector3(1.0, 1.19, -0.20), 0.13)
		for leaf_index in 3:
			var leaf := MeshInstance3D.new()
			leaf.name = "DeskPlantLeaf"
			leaf.mesh = OfficePropGeometry.leaf()
			leaf.position = Vector3(1.0, 1.19, -0.20)
			leaf.scale = Vector3(0.55, 0.35 + leaf_index * 0.035, 0.55)
			leaf.rotation = Vector3(deg_to_rad(32), leaf_index * TAU / 3.0, 0)
			leaf.material_override = office._material(Color("52745a") if leaf_index != 1 else Color("75945e"), 0.63)
			workstation.add_child(leaf)
	else:
		office._add_box(workstation, "FeedSnackPacket", Vector3(0.38, 0.12, 0.28), Vector3(0.98, 1.04, -0.18), Color("c1a052"))


func _add_planter_finish(parent: Node3D, top: Vector3, radius: float) -> void:
	var rim := MeshInstance3D.new()
	rim.name = "PlanterRolledLip"
	rim.mesh = OfficePropGeometry.pot_rim()
	rim.scale = Vector3.ONE * radius
	rim.position = top - Vector3.UP * radius * 0.06
	rim.material_override = office._material(Color("ac7859"), 0.76)
	parent.add_child(rim)
	_add_cylinder(parent, "PlanterSoil", top - Vector3.UP * radius * 0.15, radius * 0.88, radius * 0.08, Color("3d3830"))


func _build_capacity_authorization_marker(parent: Node3D, index: int, origin: Vector3) -> void:
	var marker := Node3D.new()
	marker.name = "CapacityAuthorization_%02d" % index
	marker.position = origin
	parent.add_child(marker)
	office._capacity_markers_by_index[index] = marker
	office._add_box(marker, "AuthorizationFloorPad_%02d" % index, Vector3(3.05, 0.018, 1.72), Vector3(0.0, 0.014, 0.02), Color("26363b"))
	for side_x in [-1.0, 1.0]:
		for side_z in [-1.0, 1.0]:
			var tape := office._add_box(
				marker,
				"AuthorizationTape_%02d" % index,
				Vector3(0.66, 0.012, 0.075),
				Vector3(side_x * 1.16, 0.031, side_z * 0.68),
				Color("d0a64c"),
			)
			tape.rotation_degrees.y = side_x * side_z * 18.0
	var boxed_perch := office._add_box(marker, "BoxedPerch_%02d" % index, Vector3(0.88, 0.58, 0.72), Vector3(0.68, 0.31, -0.33), Color("9b7a52"))
	boxed_perch.rotation_degrees.y = -8.0 if index % 2 == 0 else 7.0
	office._add_box(marker, "BoxBand_%02d" % index, Vector3(0.12, 0.60, 0.74), Vector3(0.68, 0.32, -0.33), Color("54483a"))
	office._add_box(marker, "UnpoweredLightHousing_%02d" % index, Vector3(2.72, 0.13, 0.34), Vector3(0.0, 3.17, 0.05), Color("3c464a"))
	office._add_box(marker, "UnpoweredLightLens_%02d" % index, Vector3(2.42, 0.035, 0.24), Vector3(0.0, 3.09, 0.05), Color("6c706b"))
	Office.EnvironmentalSignageScript.add_panel(
		boxed_perch,
		"CapacityNotice_%02d" % index,
		"PERCH %d\nON HOLD" % (index + 1),
		Vector3(0.0, 0.07, 0.366),
		Vector2(0.68, 0.28),
		Color("d8caa9"),
		Color("5c4935"),
		Vector3.ZERO,
		13,
		0.0030,
		&"secondary",
		&"shipping",
	)


func _build_staffing_surface(parent: Node = null) -> void:
	if office._staffing_ui != null:
		return
	# Late sections must start outside the navigator: it rejects nested adopted
	# descendants to protect its page ownership and restoration contracts.
	var host := parent if parent != null else office._ui_root
	office._staffing_ui = (load(Office.RoostStaffingUIScript) as Script).new()
	office._staffing_ui.capacity_purchase_requested.connect(office._on_staff_capacity_purchase_requested)
	office._staffing_ui.facility_purchase_requested.connect(office._on_facility_purchase_requested)
	office._staffing_ui.manager_assignment_requested.connect(office._on_manager_assignment_requested)
	office._staffing_ui.manager_posture_requested.connect(office._on_manager_posture_requested)
	office._staffing_ui.manager_recruit_requested.connect(office._on_manager_recruit_requested)
	office._staffing_ui.intern_onboard_requested.connect(office._on_intern_onboard_requested)
	office._staffing_ui.intern_assignment_requested.connect(office._on_intern_assignment_requested)
	office._staffing_ui.intern_review_requested.connect(office._on_intern_review_requested)
	office._staffing_ui.flock_relations_action_requested.connect(office._on_flock_relations_action_requested)
	office._staffing_ui.feed_order_requested.connect(office._on_feed_order_requested)
	office._staffing_ui.farmgate_dispatch_mandate_requested.connect(
		office._on_farmgate_dispatch_mandate_requested
	)
	office._staffing_ui.capital_blueprint_requested.connect(office._on_capital_blueprint_requested)
	office._staffing_ui.farmer_relations_campaign_requested.connect(
		office._on_farmer_relations_campaign_requested
	)
	office._staffing_ui.hire_requested.connect(office._on_staff_hire_requested)
	office._staffing_ui.release_requested.connect(office._on_staff_release_requested)
	office._staffing_ui.interaction_safety_changed.connect(
		office._on_interaction_safety_presentation_changed
	)
	office._staffing_ui.presentation_context_changed.connect(
		office._on_campaign_interface_context_changed
	)
	host.add_child(office._staffing_ui)
	if office._flockwatch_navigation != null:
		office._staffing_ui.apply_snapshot(office._simulation.snapshot())
		office._apply_explicit_font_scale(office._staffing_ui, float(office._player_preferences.get("ui_scale", 1.0)))
		office._register_staffing_sections()


func _build_settings_surface() -> void:
	if office._settings_ui != null:
		return
	office._settings_ui = (load(Office.SettingsUIScript) as Script).new()
	office._settings_ui.preferences_changed.connect(office._on_preferences_changed)
	office._settings_ui.binding_capture_requested.connect(office._on_binding_capture_requested)
	office._settings_ui.reset_defaults_requested.connect(office._on_preferences_reset_requested)
	office._settings_ui.career_backup_export_requested.connect(office._on_career_backup_export_requested)
	office._settings_ui.career_backup_import_requested.connect(office._on_career_backup_import_requested)
	office._settings_ui.playtest_receipt_export_requested.connect(office._on_playtest_receipt_export_requested)
	office._settings_ui.first_clutch_replay_requested.connect(office._on_first_clutch_replay_requested)
	office._settings_ui.close_requested.connect(office._on_settings_close_requested)
	office._ui_root.add_child(office._settings_ui)
	office._apply_explicit_font_scale(office._settings_ui, float(office._player_preferences.get("ui_scale", 1.0)))


func _build_held_confirmation_scrim() -> void:
	office._held_confirmation_scrim = ColorRect.new()
	office._held_confirmation_scrim.name = "HeldConfirmationScrim"
	office._held_confirmation_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Keep the office legible as context while letting the small decision ledger
	# own attention. ConfirmationDialog windows render above this canvas control.
	office._held_confirmation_scrim.color = Color(0.012, 0.024, 0.034, 0.58)
	office._held_confirmation_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	office._held_confirmation_scrim.z_index = 72
	office._held_confirmation_scrim.visible = false
	office._held_confirmation_scrim.set_meta(
		"accessible_text",
		"Decision in progress. Background management controls are unavailable.",
	)
	office._ui_root.add_child(office._held_confirmation_scrim)


func _build_explain_strip() -> void:
	office._explain_strip = PanelContainer.new()
	office._explain_strip.name = "HoldToExplainStrip"
	office._explain_strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	office._explain_strip.offset_left = -388.0
	office._explain_strip.offset_top = -112.0
	office._explain_strip.offset_right = 388.0
	office._explain_strip.offset_bottom = -22.0
	office._explain_strip.z_index = 46
	office._explain_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office._explain_strip.add_theme_stylebox_override(
		"panel",
		office._panel_style(Color("16242d"), 0.985, 12, 2),
	)
	office._explain_strip.visible = false
	office._explain_strip.set_meta("input", "H")
	office._explain_strip.set_meta("hold_to_explain", true)
	office._explain_strip.set_meta("replays_last_cause", true)
	office._explain_strip.set_meta("files_nothing", true)
	office._explain_strip.tooltip_text = "Hold H to pause and replay the latest file path. The replay changes nothing."
	office._explain_strip.accessibility_name = office._explain_strip.tooltip_text
	office._ui_root.add_child(office._explain_strip)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	office._explain_strip.add_child(margin)
	var chips := HBoxContainer.new()
	chips.name = "ExplainChips"
	chips.add_theme_constant_override("separation", 8)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(chips)
	for definition in [
		{"id": "objective", "icon": &"goal", "copy": "DO  ·  NEXT ACTION"},
		{"id": "target", "icon": &"route", "copy": "HERE  ·  WORLD TARGET"},
		{"id": "danger", "icon": &"shield", "copy": "WATCH  ·  RISK"},
		{"id": "reward", "icon": &"egg", "copy": "EARNS  ·  PAYOFF"},
	]:
		var chip := PanelContainer.new()
		chip.name = "ExplainChip_%s" % String(definition.get("id", "chip")).capitalize()
		chip.custom_minimum_size = Vector2(176.0, 56.0)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override(
			"panel",
			office._panel_style(Color("20333d"), 0.98, 8, 1),
		)
		chips.add_child(chip)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(row)
		var icon := Office.FlockwatchIconBadgeScript.new()
		icon.set_badge_size(20.0)
		icon.configure(StringName(definition.get("icon", &"goal")), Color("f0ce78"))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var label := office._make_label(String(definition.get("copy", "EXPLAIN")), 11, Color("e7edf0"))
		label.name = "ExplainValue_%s" % String(definition.get("id", "chip")).capitalize()
		label.custom_minimum_size = Vector2(108.0, 38.0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.max_lines_visible = 2
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		office._explain_chip_labels.append(label)


func _build_day_review_panel() -> void:
	office._day_review_scrim = ColorRect.new()
	office._day_review_scrim.name = "DayReviewScrim"
	office._day_review_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	office._day_review_scrim.color = Color(0.025, 0.04, 0.055, 0.78)
	office._day_review_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	office._day_review_scrim.z_index = 80
	office._day_review_scrim.visible = false
	office._ui_root.add_child(office._day_review_scrim)

	office._day_review_panel = PanelContainer.new()
	office._day_review_panel.name = "DayReviewPanel"
	office._day_review_panel.set_anchors_preset(Control.PRESET_CENTER)
	office._day_review_panel.offset_left = -370.0
	office._day_review_panel.offset_top = -310.0
	office._day_review_panel.offset_right = 370.0
	office._day_review_panel.offset_bottom = 310.0
	office._day_review_panel.add_theme_stylebox_override("panel", office._panel_style(Color("17232d"), 0.985, 14, 2))
	office._day_review_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	office._day_review_scrim.add_child(office._day_review_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	office._day_review_panel.add_child(margin)
	var review_stack := VBoxContainer.new()
	review_stack.add_theme_constant_override("separation", 9)
	margin.add_child(review_stack)
	var review_body_scroll := ScrollContainer.new()
	review_body_scroll.name = "FarmerReviewBodyScroll"
	review_body_scroll.custom_minimum_size.y = 80.0
	review_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	review_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	review_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	review_body_scroll.follow_focus = true
	review_stack.add_child(review_body_scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 9)
	review_body_scroll.add_child(content)
	office._review_title = office._make_label("FARMER REVIEW", 26, Color("f4d27b"))
	office._review_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(office._review_title)
	var closing_steps := office._make_label(
		"1  RESULT   >   2  CREDIT   >   3  BUILD",
		12,
		Color("d8b667"),
	)
	closing_steps.name = "ClosingFileSteps"
	closing_steps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(closing_steps)
	content.add_child(HSeparator.new())
	var glance_grid := GridContainer.new()
	glance_grid.name = "FarmerReviewGlanceGrid"
	glance_grid.columns = 4
	glance_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glance_grid.add_theme_constant_override("h_separation", 8)
	content.add_child(glance_grid)
	office._review_eggs_value = _add_review_stat_tile(
		glance_grid,
		"FarmerReviewEggs",
		"EGGS / TARGET",
		Color("8fd9b7"),
	)
	office._review_net_value = _add_review_stat_tile(
		glance_grid,
		"FarmerReviewNet",
		"NET",
		Color("f4d27b"),
	)
	office._review_fund_value = _add_review_stat_tile(
		glance_grid,
		"FarmerReviewFund",
		"FEED FUND",
		Color("9fc9d8"),
	)
	office._review_next_value = _add_review_stat_tile(
		glance_grid,
		"FarmerReviewNext",
		"NEXT TARGET",
		Color("c7b5e8"),
	)
	office._review_summary = office._make_label("", 14, Color("e7edf0"))
	office._review_summary.name = "FarmerReviewSummary"
	office._review_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	office._review_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	office._review_summary.custom_minimum_size.y = 24.0
	content.add_child(office._review_summary)
	office._review_details_toggle = Button.new()
	office._review_details_toggle.name = "FarmerReviewDetailsToggle"
	office._review_details_toggle.text = "DETAILS"
	office._review_details_toggle.custom_minimum_size.y = 32.0
	office._review_details_toggle.pressed.connect(office._on_review_details_toggled)
	content.add_child(office._review_details_toggle)
	office._review_details_scroll = ScrollContainer.new()
	office._review_details_scroll.name = "FarmerReviewAccountingScroll"
	office._review_details_scroll.custom_minimum_size.y = 184.0
	office._review_details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	office._review_details_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	office._review_details_scroll.visible = false
	content.add_child(office._review_details_scroll)
	office._review_results = office._make_label("", 13, Color("d5dfe2"))
	office._review_results.name = "FarmerReviewAccountingDetails"
	office._review_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	office._review_results.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	office._review_results.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	office._review_details_scroll.add_child(office._review_results)
	office._review_story = office._make_label("", 14, Color("b8c6cb"))
	office._review_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	office._review_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	office._review_story.custom_minimum_size.y = 30.0
	office._review_story.max_lines_visible = 2
	office._review_story.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	content.add_child(office._review_story)
	var hint := office._make_label("OPTIONAL: STAFF OR BUILD", 12, Color("d5bd78"))
	office._review_next_hint = hint
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Keep the next required step beside its action, even while results scroll.
	review_stack.add_child(hint)
	office._personal_goal_button = Button.new()
	office._personal_goal_button.name = "AcceptPersonalGoal"
	office._personal_goal_button.custom_minimum_size.y = 36.0
	office._personal_goal_button.pressed.connect(office._on_personal_goal_toggled)
	review_stack.add_child(office._personal_goal_button)
	var buttons := HFlowContainer.new()
	buttons.name = "FarmerReviewActions"
	buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	review_stack.add_child(buttons)
	office._review_replay_button = Button.new()
	office._review_replay_button.name = "ReviewReplayHighlightButton"
	office._review_replay_button.icon = Office.ManagementUIThemeScript.action_icon(&"review_play")
	office._review_replay_button.custom_minimum_size = Vector2(44.0, 48.0)
	office._review_replay_button.tooltip_text = "Replay the shift's strongest physical hen highlight. No state changes."
	office._review_replay_button.accessibility_name = "Replay shift highlight. No state changes."
	office._review_replay_button.pressed.connect(office._on_review_replay_highlight_pressed)
	buttons.add_child(office._review_replay_button)
	office._review_remix_button = Button.new()
	office._review_remix_button.name = "ReviewRemixNextButton"
	office._review_remix_button.text = "OTHER GOAL"
	office._review_remix_button.icon = Office.ManagementUIThemeScript.action_icon(&"review_remix")
	office._review_remix_button.custom_minimum_size = Vector2(140.0, 48.0)
	office._review_remix_button.tooltip_text = "Browse another goal: more eggs, safer shells, or happier hens. Accept separately; browsing changes nothing."
	office._review_remix_button.accessibility_name = "Browse another next-shift goal. Accept separately; browsing changes nothing."
	office._review_remix_button.pressed.connect(office._on_review_remix_pressed)
	buttons.add_child(office._review_remix_button)
	var requisitions := Button.new()
	requisitions.name = "ReviewRequisitionsButton"
	requisitions.text = "STAFF / CASES"
	requisitions.custom_minimum_size = Vector2(136.0, 48.0)
	requisitions.tooltip_text = "Review staffing, training, and named-hen workplace cases."
	requisitions.pressed.connect(office._on_review_requisitions_pressed)
	buttons.add_child(requisitions)
	var blueprint := Button.new()
	blueprint.name = "ReviewCapitalBlueprintButton"
	blueprint.text = "BUILD"
	blueprint.custom_minimum_size = Vector2(100.0, 48.0)
	blueprint.tooltip_text = "Compare every permanent office project on one spatial capital plan."
	blueprint.pressed.connect(office._on_review_capital_blueprint_pressed)
	buttons.add_child(blueprint)
	office._begin_next_shift_button = Button.new()
	office._begin_next_shift_button.name = "BeginNextShiftButton"
	office._begin_next_shift_button.text = "CONTINUE  >"
	office._begin_next_shift_button.theme_type_variation = &"PrimaryButton"
	office._begin_next_shift_button.custom_minimum_size = Vector2(180.0, 48.0)
	office._begin_next_shift_button.pressed.connect(office._on_begin_next_shift_pressed)
	buttons.add_child(office._begin_next_shift_button)


func _add_review_stat_tile(
	parent: GridContainer,
	node_name: String,
	caption: String,
	accent: Color,
) -> Label:
	var tile := PanelContainer.new()
	tile.name = "%sTile" % node_name
	tile.custom_minimum_size = Vector2(150.0, 78.0)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override(
		"panel",
		office._panel_style(Color("20313b"), 0.98, 8, 1),
	)
	parent.add_child(tile)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	tile.add_child(stack)
	var value_label := office._make_label("—", 22, accent)
	value_label.name = "%sValue" % node_name
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(value_label)
	var caption_label := office._make_label(caption, 11, Color("9fb0b7"))
	caption_label.name = "%sCaption" % node_name
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(caption_label)
	return value_label


func _build_capital_planning_surfaces() -> void:
	if office._capital_blueprint_ui != null:
		return
	office._capital_blueprint_ui = (load(Office.CapitalBlueprintUIScript) as Script).new() as Control
	office._capital_blueprint_ui.name = "CapitalBlueprintUI"
	office._capital_blueprint_ui.z_index = 120
	office._capital_blueprint_ui.connect(&"close_requested", office._on_capital_blueprint_close_requested)
	office._capital_blueprint_ui.connect(&"preview_requested", office._on_capital_blueprint_preview_requested)
	office._capital_blueprint_ui.connect(
		&"presentation_context_changed",
		office._on_campaign_interface_context_changed,
	)
	office._capital_blueprint_ui.connect(&"pin_requested", office._on_capital_blueprint_pin_requested)
	office._capital_blueprint_ui.connect(&"purchase_requested", office._on_capital_blueprint_purchase_requested)
	office._capital_blueprint_ui.connect(&"campus_expansion_requested", office._on_campus_expansion_requested)
	office._ui_root.add_child(office._capital_blueprint_ui)

	office._campus_portfolio_ui = (load(Office.CampusPortfolioUIScript) as Script).new() as Control
	office._campus_portfolio_ui.name = "CampusPortfolioUI"
	office._campus_portfolio_ui.z_index = 124
	office._campus_portfolio_ui.connect(&"close_requested", office._on_campus_portfolio_close_requested)
	office._campus_portfolio_ui.connect(&"deed_requested", office._on_campus_portfolio_deed_requested)
	office._campus_portfolio_ui.connect(&"project_requested", office._on_campus_portfolio_project_requested)
	office._campus_portfolio_ui.connect(
		&"staff_assignment_requested",
		office._on_campus_portfolio_staff_assignment_requested,
	)
	office._campus_portfolio_ui.connect(
		&"staff_unassignment_requested",
		office._on_campus_portfolio_staff_unassignment_requested,
	)
	office._campus_portfolio_ui.connect(
		&"north_meadow_details_requested",
		office._on_campus_portfolio_north_details_requested,
	)
	office._ui_root.add_child(office._campus_portfolio_ui)
	office._campus_portfolio_ui.call("hide_portfolio", false)

	office._campus_expansion_ui = (load(Office.CampusExpansionUIScript) as Script).new() as Control
	office._campus_expansion_ui.name = "CampusExpansionUI"
	office._campus_expansion_ui.z_index = 125
	office._campus_expansion_ui.connect(&"close_requested", office._on_campus_expansion_close_requested)
	office._campus_expansion_ui.connect(
		&"purchase_parcel_requested",
		office._on_campus_parcel_purchase_requested,
	)
	office._campus_expansion_ui.connect(
		&"connect_service_requested",
		office._on_campus_service_connect_requested,
	)
	office._campus_expansion_ui.connect(&"place_pod_requested", office._on_campus_pod_place_requested)
	office._campus_expansion_ui.connect(&"relocate_pod_requested", office._on_campus_pod_relocate_requested)
	office._ui_root.add_child(office._campus_expansion_ui)
	office._campus_expansion_ui.call("hide_planner", false)

	office._commissioning_reveal_ui = (load(Office.CommissioningRevealUIScript) as Script).new() as Control
	office._commissioning_reveal_ui.name = "CommissioningRevealUI"
	office._commissioning_reveal_ui.z_index = 130
	office._commissioning_reveal_ui.connect(&"continue_requested", office._on_commissioning_continue_requested)
	office._commissioning_reveal_ui.connect(
		&"return_to_blueprint_requested",
		office._on_commissioning_return_to_blueprint_requested,
	)
	office._ui_root.add_child(office._commissioning_reveal_ui)

	office._campus_portfolio_reveal_ui = (load(Office.CampusPortfolioRevealUIScript) as Script).new() as Control
	office._campus_portfolio_reveal_ui.name = "CampusPortfolioRevealUI"
	office._campus_portfolio_reveal_ui.z_index = 131
	office._campus_portfolio_reveal_ui.connect(
		&"continue_requested",
		office._on_campus_portfolio_reveal_continue_requested,
	)
	office._campus_portfolio_reveal_ui.connect(
		&"return_to_portfolio_requested",
		office._on_campus_portfolio_reveal_return_requested,
	)
	office._ui_root.add_child(office._campus_portfolio_reveal_ui)
	# Deferred controls must receive the same saved scale and animation settings
	# as controls present during the initial preference pass.
	for surface: Control in [
		office._capital_blueprint_ui, office._campus_portfolio_ui, office._campus_expansion_ui,
		office._commissioning_reveal_ui, office._campus_portfolio_reveal_ui,
	]:
		office._apply_explicit_font_scale(surface, float(office._player_preferences.get("ui_scale", 1.0)))
		if surface.has_method("set_animation_speed_multiplier"):
			surface.call("set_animation_speed_multiplier", office._animation_speed_multiplier)


func _build_decision_modal() -> void:
	office._decision_host = Control.new()
	office._decision_host.name = "ManagementDecisionHost"
	office._decision_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	office._decision_host.mouse_filter = Control.MOUSE_FILTER_STOP
	office._decision_host.z_index = 100
	office._decision_host.visible = false
	office._ui_root.add_child(office._decision_host)

	var scrim := ColorRect.new()
	scrim.name = "DecisionScrim"
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.018, 0.031, 0.043, 0.84)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	office._decision_host.add_child(scrim)

	var decision_scroll := ScrollContainer.new()
	decision_scroll.name = "DecisionScroll"
	decision_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	decision_scroll.offset_left = 18.0
	decision_scroll.offset_top = 18.0
	decision_scroll.offset_right = -18.0
	decision_scroll.offset_bottom = -18.0
	decision_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	decision_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	decision_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	office._decision_host.add_child(decision_scroll)

	var center := CenterContainer.new()
	center.name = "DecisionCenter"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	decision_scroll.add_child(center)

	office._decision_panel = PanelContainer.new()
	office._decision_panel.name = "ManagementDecisionCard"
	office._decision_panel.custom_minimum_size = Vector2(760.0, 0.0)
	office._decision_panel.add_theme_stylebox_override("panel", office._panel_style(Color("172630"), 0.995, 16, 2))
	center.add_child(office._decision_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	office._decision_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "DecisionContent"
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	office._decision_eyebrow = office._make_label("MANAGEMENT DECISION", 13, Color("d8b667"))
	office._decision_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(office._decision_eyebrow)
	office._decision_title = office._make_label("CHOOSE A RESPONSE", 25, Color("f4e3ae"))
	office._decision_title.name = "DecisionTitle"
	office._decision_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	office._decision_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(office._decision_title)
	office._decision_body = office._make_label("", 16, Color("c4d0d4"))
	office._decision_body.name = "DecisionBody"
	office._decision_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	office._decision_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(office._decision_body)
	office._decision_petition_glance = GridContainer.new()
	office._decision_petition_glance.name = "DecisionPetitionGlance"
	office._decision_petition_glance.columns = 5
	office._decision_petition_glance.add_theme_constant_override("h_separation", 7)
	office._decision_petition_glance.add_theme_constant_override("v_separation", 7)
	office._decision_petition_glance.visible = false
	content.add_child(office._decision_petition_glance)
	for petition_tile_index in 5:
		_add_decision_petition_tile(petition_tile_index)
	office._decision_petition_semantics = office._make_label("", 1, Color.TRANSPARENT)
	office._decision_petition_semantics.name = "DecisionPetitionSemantics"
	office._decision_petition_semantics.visible = false
	content.add_child(office._decision_petition_semantics)
	office._decision_order_heading = office._make_label("TODAY'S GOALS", 11, Color("d8b667"))
	office._decision_order_heading.name = "DecisionOrderHeading"
	office._decision_order_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	office._decision_order_heading.visible = false
	content.add_child(office._decision_order_heading)
	office._decision_order_glance = GridContainer.new()
	office._decision_order_glance.name = "DecisionOrderGlance"
	office._decision_order_glance.columns = 3
	office._decision_order_glance.add_theme_constant_override("h_separation", 8)
	office._decision_order_glance.visible = false
	content.add_child(office._decision_order_glance)
	for order_index in 3:
		_add_decision_order_tile(order_index)
	content.add_child(HSeparator.new())
	office._decision_options = GridContainer.new()
	office._decision_options.name = "DecisionOptions"
	office._decision_options.columns = 1
	office._decision_options.add_theme_constant_override("h_separation", 9)
	office._decision_options.add_theme_constant_override("v_separation", 9)
	content.add_child(office._decision_options)
	office._decision_preview = office._make_label("Select a policy card to review its consequences.", 14, Color("efcf83"))
	office._decision_preview.name = "DecisionPreview"
	office._decision_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	office._decision_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	office._decision_preview.custom_minimum_size.y = 34.0
	content.add_child(office._decision_preview)

	var actions := HFlowContainer.new()
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	office._decision_stay_paused_button = Button.new()
	office._decision_stay_paused_button.name = "ResolveStayPausedButton"
	office._decision_stay_paused_button.text = "RESOLVE & STAY PAUSED"
	office._decision_stay_paused_button.custom_minimum_size = Vector2(220.0, 46.0)
	office._decision_stay_paused_button.disabled = true
	office._decision_stay_paused_button.pressed.connect(office._on_decision_stay_paused_pressed)
	actions.add_child(office._decision_stay_paused_button)
	office._decision_confirm_button = Button.new()
	office._decision_confirm_button.name = "ConfirmDecisionButton"
	office._decision_confirm_button.text = "AUTHORIZE"
	office._decision_confirm_button.theme_type_variation = &"PrimaryButton"
	office._decision_confirm_button.custom_minimum_size = Vector2(250.0, 46.0)
	office._decision_confirm_button.disabled = true
	office._decision_confirm_button.pressed.connect(office._on_decision_confirm_pressed)
	actions.add_child(office._decision_confirm_button)


func _add_decision_petition_tile(tile_index: int) -> void:
	var tile := PanelContainer.new()
	tile.name = "DecisionPetitionTile_%d" % tile_index
	tile.custom_minimum_size.y = 66.0
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.mouse_filter = Control.MOUSE_FILTER_PASS
	tile.add_theme_stylebox_override(
		"panel",
		office._panel_style(Color("20313b"), 0.98, 8, 1),
	)
	office._decision_petition_glance.add_child(tile)
	office._decision_petition_tiles.append(tile)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(stack)
	var value := office._make_label("-", 16, Color("f1cf79"))
	value.name = "DecisionPetitionValue_%d" % tile_index
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(value)
	office._decision_petition_values.append(value)
	var caption := office._make_label("FILE", 9, Color("9fb0b7"))
	caption.name = "DecisionPetitionCaption_%d" % tile_index
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(caption)
	office._decision_petition_captions.append(caption)


func _add_decision_order_tile(order_index: int) -> void:
	var tile := PanelContainer.new()
	tile.name = "DecisionOrderTile_%d" % order_index
	tile.custom_minimum_size.y = 70.0
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override(
		"panel",
		office._panel_style(Color("20313b"), 0.98, 8, 1),
	)
	office._decision_order_glance.add_child(tile)
	office._decision_order_tiles.append(tile)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	tile.add_child(stack)
	var value := office._make_label("-", 19, Color("f1cf79"))
	value.name = "DecisionOrderValue_%d" % order_index
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(value)
	office._decision_order_values.append(value)
	var caption := office._make_label("ORDER", 10, Color("9fb0b7"))
	caption.name = "DecisionOrderCaption_%d" % order_index
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(caption)
	office._decision_order_captions.append(caption)


func _sync_work_progress_interactions() -> void:
	if office._camera_controller == null:
		return
	office._camera_controller.clear_worker_context_points()
	if office._workstation_feedback == null:
		return
	var roots := office._workstation_feedback.work_progress_interaction_roots()
	for worker_id: int in roots:
		office._camera_controller.register_worker_equipment_point(worker_id, office._workstation_feedback.equipment_interaction_root(worker_id))
		office._camera_controller.register_worker_context_point(
			worker_id,
			roots[worker_id] as Node3D,
			&"work_progress",
		)
	office._camera_controller.refresh_context_hover()


func _build_settlement_destination_ack_pool() -> void:
	office._settlement_destination_ack_pool.clear()
	office._settlement_destination_ack_by_kind.clear()
	office._settlement_destination_ack_styles.clear()
	var kinds: Array[StringName] = [&"fund", &"stock", &"refund"]
	var accents := {
		&"fund": Color("8fd1a1"),
		&"stock": Color("8fd2c1"),
		&"refund": Color("f4d471"),
	}
	var glyphs := {&"fund": "$", &"stock": "▦", &"refund": "◆"}
	for pool_index in mini(Office.SETTLEMENT_DESTINATION_ACK_POOL_SIZE, kinds.size()):
		var kind := kinds[pool_index]
		var accent := accents[kind] as Color
		var style := StyleBoxFlat.new()
		style.bg_color = Color(accent, 0.055)
		style.border_color = accent
		style.set_border_width_all(2)
		style.set_corner_radius_all(8 if kind != &"refund" else 4)
		office._settlement_destination_ack_styles[kind] = style
		var panel := Panel.new()
		panel.name = "SettlementDestinationAck_%s" % String(kind).capitalize()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.z_index = 120
		panel.visible = false
		panel.add_theme_stylebox_override("panel", style)
		var glyph := office._make_label(String(glyphs[kind]), 15, accent)
		glyph.name = "DestinationGlyph"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		glyph.offset_left = -22.0
		glyph.offset_top = -8.0
		glyph.offset_right = 0.0
		glyph.offset_bottom = 14.0
		panel.add_child(glyph)
		office._ui_root.add_child(panel)
		var visual := Office.SettlementDestinationAckVisual.new()
		visual.panel = panel
		visual.glyph = glyph
		visual.pool_index = pool_index
		visual.kind = kind
		office._settlement_destination_ack_pool.append(visual)
		office._settlement_destination_ack_by_kind[kind] = visual


func _build_fund_debit_chip_pool() -> void:
	office._fund_debit_chip_pool.clear()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2c2023")
	style.border_color = Color("ef9a72")
	style.set_border_width_all(2)
	# Opposing tight/wide corners make spending read as a clipped docket tab,
	# distinct in silhouette from the soft green settlement receipts.
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 9
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	for pool_index in Office.FUND_DEBIT_CHIP_POOL_SIZE:
		var panel := PanelContainer.new()
		panel.name = "FundDebitChip_%d" % pool_index
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Stay above ordinary ledgers while yielding to character, decision, review,
		# and commissioning surfaces. A purchase docket must never cross dialogue.
		panel.z_index = 35
		panel.visible = false
		panel.size = Office.FUND_DEBIT_CHIP_SIZE
		panel.custom_minimum_size = Office.FUND_DEBIT_CHIP_SIZE
		panel.add_theme_stylebox_override("panel", style)
		var label := office._make_label("-$0.00  >", 14, Color("ffd2b4"))
		label.name = "DebitGlyph"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		office._ui_root.add_child(panel)
		var visual := Office.FundDebitChipVisual.new()
		visual.panel = panel
		visual.label = label
		visual.pool_index = pool_index
		office._fund_debit_chip_pool.append(visual)


func _build_fund_credit_chip_pool() -> void:
	office._fund_credit_chip_pool.clear()
	office._active_fund_credit_chips.clear()
	var panel_style := office._panel_style(Color("16242d"), 0.96, 7, 1)
	for pool_index in Office.FUND_CREDIT_CHIP_POOL_SIZE:
		var panel := PanelContainer.new()
		panel.name = "FundCreditChipPool_%02d" % pool_index
		panel.custom_minimum_size = Office.FUND_CREDIT_CHIP_SIZE
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", panel_style)
		panel.visible = false
		var label := office._make_label("", 15, Color("8fd1a1"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		panel.add_child(label)
		office._ui_root.add_child(panel)
		var visual := Office.FundCreditChipVisual.new()
		visual.panel = panel
		visual.label = label
		visual.pool_index = pool_index
		office._fund_credit_chip_pool.append(visual)


func _build_auxiliary_settlement_chip_pool() -> void:
	office._auxiliary_settlement_chip_pool.clear()
	office._active_auxiliary_settlement_chips.clear()
	office._stock_chip_style = office._panel_style(Color("162b2c"), 0.97, 7, 1)
	office._refund_chip_style = office._panel_style(Color("16242d"), 0.97, 7, 1)
	for pool_index in Office.AUXILIARY_SETTLEMENT_CHIP_POOL_SIZE:
		var panel := PanelContainer.new()
		panel.name = "AuxiliarySettlementChipPool_%02d" % pool_index
		panel.custom_minimum_size = Office.AUXILIARY_SETTLEMENT_CHIP_SIZE
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", office._stock_chip_style)
		panel.visible = false
		var label := office._make_label("", 14, Color("8fd2c1"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		panel.add_child(label)
		office._ui_root.add_child(panel)
		var visual := Office.AuxiliarySettlementChipVisual.new()
		visual.panel = panel
		visual.label = label
		visual.pool_index = pool_index
		office._auxiliary_settlement_chip_pool.append(visual)


func _build_egg_fleck_pool() -> void:
	office._egg_fleck_pool.clear()
	office._active_egg_flecks.clear()
	for pool_index in Office.EGG_FLECK_POOL_SIZE:
		var node := MeshInstance3D.new()
		node.name = "EggFleckPool_%02d" % pool_index
		node.mesh = ProceduralPrimitiveCache.sphere(0.5, 1.0, 12, 6)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.visible = false
		node.scale = Vector3.ZERO
		node.material_override = office._material(Color("f3ead2"))
		office._egg_layer.add_child(node)
		var fleck := Office.EggFleckVisual.new()
		fleck.node = node
		office._egg_fleck_pool.append(fleck)


func _box_batch_transform(
	size: Vector3,
	part_position: Vector3,
	rotation_degrees: Vector3 = Vector3.ZERO,
) -> Transform3D:
	var rotation_radians := Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z),
	)
	var basis := Basis.from_euler(rotation_radians) * Basis.from_scale(size)
	return Transform3D(basis, part_position)


func _add_box_multimesh(
	parent: Node,
	part_name: String,
	transforms: Array[Transform3D],
	color: Color,
	shadow_casting: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = ProceduralPrimitiveCache.box(Vector3.ONE)
	multimesh.instance_count = transforms.size()
	for transform_index in transforms.size():
		multimesh.set_instance_transform(transform_index, transforms[transform_index])
	var instance := MultiMeshInstance3D.new()
	instance.name = part_name
	instance.multimesh = multimesh
	instance.material_override = office._material(color)
	instance.cast_shadow = shadow_casting
	parent.add_child(instance)
	return instance


func _add_cylinder(parent: Node, part_name: String, part_position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = ProceduralPrimitiveCache.cylinder(radius * 0.88, radius, height, 16)
	instance.position = part_position
	instance.material_override = office._material(color)
	parent.add_child(instance)
	return instance


func _add_sphere(parent: Node, part_name: String, part_position: Vector3, part_scale: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = ProceduralPrimitiveCache.sphere(0.5, 1.0, 12, 6)
	instance.position = part_position
	instance.scale = part_scale
	instance.material_override = office._material(color)
	parent.add_child(instance)
	return instance
