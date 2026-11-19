extends SceneTree

func _init() -> void:
	_profile.call_deferred()

func _profile() -> void:
	var paths := [
		"res://core/simulation/department_simulation.gd",
		"res://features/chickens/chicken_view.gd",
		"res://features/predator/predator_encounter.gd",
		"res://features/office/office_surface_finish.gd",
		"res://features/office/management_camera_controller.gd",
		"res://features/management/management_presence.gd",
		"res://features/office/workstation_feedback.gd",
		"res://features/office/office_atmosphere.gd",
		"res://features/office/office_storytelling.gd",
		"res://features/office/environmental_signage.gd",
		"res://features/office/management_ui_theme.gd",
		"res://features/office/office_audio_feedback.gd",
		"res://features/office/office_audio_director.gd",
		"res://core/settings/office_action_catalog.gd",
		"res://core/settings/player_preferences_store.gd",
		"res://core/settings/web_preferences_mirror.gd",
		"res://core/experience/first_session_funnel.gd",
		"res://core/experience/gameplay_pulse_director.gd",
		"res://core/experience/tactical_route_planner.gd",
		"res://features/office/settings_ui.gd",
		"res://features/office/peckwork_routing_ui.gd",
		"res://features/office/opening_egg_slots.gd",
		"res://core/experience/loop_readability.gd",
		"res://features/office/roost_staffing_ui.gd",
		"res://features/office/pecking_order_ui.gd",
		"res://features/office/flockwatch_navigation.gd",
		"res://features/office/flockwatch_disclosure_toggle.gd",
		"res://features/office/flockwatch_icon_badge.gd",
		"res://features/office/economic_briefing_ui.gd",
		"res://features/office/capital_blueprint_model.gd",
		"res://features/office/capital_blueprint_ui.gd",
		"res://features/office/campus_expansion_ui.gd",
		"res://features/office/campus_portfolio_ui.gd",
		"res://features/office/campus_expansion_visual.gd",
		"res://features/office/campus_portfolio_visual.gd",
		"res://features/office/commissioning_reveal_ui.gd",
		"res://features/office/campus_portfolio_reveal_ui.gd",
		"res://core/campaign/campaign_state.gd",
		"res://core/campaign/senior_roost_state.gd",
		"res://core/campaign/career_commendations.gd",
		"res://core/campaign/career_run_archive.gd",
		"res://core/persistence/campaign_save_store.gd",
		"res://core/persistence/career_portfolio_store.gd",
		"res://core/persistence/checkpoint_coordinator.gd",
		"res://features/office/probation_campaign_ui.gd",
		"res://features/office/character_dialogue_ui.gd",
		"res://features/office/hen_social_director.gd",
		"res://features/office/hen_social_ui.gd",
		"res://features/office/character_dialogue_catalog.gd",
		"res://core/experience/personal_shift_goal.gd",
	]
	var retained: Array[Resource] = []
	# Dependency attribution warms the cache; default mode measures a cold scene.
	if "--dependencies" in OS.get_cmdline_user_args():
		for path in paths:
			var before := Time.get_ticks_msec()
			retained.append(load(path))
			print("RESOURCE_LOAD %s %dms" % [path, Time.get_ticks_msec() - before])
	var start := Time.get_ticks_msec()
	var scene := load("res://features/office/office.tscn") as PackedScene
	var loaded := Time.get_ticks_msec()
	var office := scene.instantiate()
	var instantiated := Time.get_ticks_msec()
	root.add_child(office)
	var ready := Time.get_ticks_msec()
	print("OFFICE_LOAD_PROFILE %s" % JSON.stringify({"load_ms": loaded - start, "instantiate_ms": instantiated - loaded, "ready_ms": ready - instantiated}))
	office.queue_free()
	await process_frame
	quit()
