extends SceneTree

const OfficeAtmosphereScript := preload("res://features/office/office_atmosphere.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var atmosphere := OfficeAtmosphereScript.new()
	root.add_child(atmosphere)
	await process_frame
	atmosphere.set_animation_speed_multiplier(1.5)

	var dust := atmosphere.find_child("AmbientDustMotes", true, false) as GPUParticles3D
	var feathers := atmosphere.find_child("DriftingFeathers", true, false) as GPUParticles3D
	var accents := atmosphere.find_children("*Accent", "OmniLight3D", true, false)
	var red_bar := atmosphere.find_child("RedAlertStrip", true, false) as MeshInstance3D
	var farmer_spotlight := atmosphere.find_child("FarmerReviewSpotlight", true, false) as SpotLight3D
	var event_bursts := atmosphere.find_child("EventBursts", true, false) as Node3D
	var strategy_shelf := atmosphere.find_child("StrategyRewardShelf", true, false) as Node3D
	_check(dust != null and dust.visibility_aabb.size.length() > 1.0, "dust motes need explicit visibility bounds", failures)
	_check(feathers != null and feathers.visibility_aabb.size.length() > 1.0, "feathers need explicit visibility bounds", failures)
	_check(accents.size() == 3, "atmosphere should keep the accent light budget at three", failures)
	_check(event_bursts != null and event_bursts.get_child_count() == 8, "event particles should use the bounded eight-slot pool", failures)
	_check(strategy_shelf != null and strategy_shelf.find_children("StrategyEgg_*", "MeshInstance3D", true, false).size() == 3, "the office should physically display the plan, contract, and reward beats", failures)
	if event_bursts != null:
		for burst_value in event_bursts.get_children():
			var burst := burst_value as GPUParticles3D
			var quad := burst.draw_pass_1 as QuadMesh if burst != null else null
			var material := quad.material as StandardMaterial3D if quad != null else null
			_check(burst != null and burst.global_position.y > 0.0, "particle warm-up must remain inside the opening camera frustum", failures)
			_check(material != null and is_zero_approx(material.albedo_color.a), "particle warm-up must remain invisible", failures)
	for accent_value in accents:
		var accent := accent_value as OmniLight3D
		_check(accent != null and not accent.shadow_enabled, "accent lights must remain shadowless", failures)
	_check(farmer_spotlight != null and not farmer_spotlight.shadow_enabled, "farmer review spotlight should remain Web-friendly and shadowless", failures)

	atmosphere.update_from_snapshot({
		"minute_of_day": 950,
		"overtime_enabled": true,
		"eggs_today": 3,
		"quota_target": 12,
		"workers": [{"stress": 82.0}],
		"active_playbook": {
			"strategy_preset_id": "safe",
			"contract": {"complete": true, "reward_claimed": true},
		},
	})
	atmosphere.pulse_alert(0.8)
	atmosphere.pulse_farmer_review()
	atmosphere.pulse_strategy_reward()
	atmosphere.pulse_egg_laid(Vector3.ZERO, &"golden")
	await process_frame
	await process_frame

	var red_material := red_bar.material_override as StandardMaterial3D if red_bar != null else null
	_check(red_material != null and red_material.emission_enabled, "overtime bars should use emissive materials", failures)
	_check(farmer_spotlight != null and farmer_spotlight.light_energy > 0.5, "farmer review should receive a focused golden light cue", failures)
	_check(atmosphere.find_child("EggGatheringPulse*", true, false) != null, "egg events should create a bounded one-shot burst", failures)
	var strategy_snapshot := atmosphere.effect_snapshot()
	_check(
		String(strategy_snapshot.get("strategy_identity", "")) == "safe"
		and int(strategy_snapshot.get("visible_reward_eggs", 0)) == 3
		and not String(strategy_snapshot.get("pacing_stage", "")).is_empty(),
		"strategy identity, visible rewards, and the authored tension beat should be inspectable",
		failures,
	)
	_check(event_bursts != null and event_bursts.get_child_count() == 8, "egg events must reuse the resident particle pool", failures)
	atmosphere.set_particle_level(&"reduced")
	var particle_reduced_snapshot := atmosphere.effect_snapshot()
	_check(
		String(particle_reduced_snapshot.get("level", "")) == "full"
		and String(particle_reduced_snapshot.get("particle_level", "")) == "reduced"
		and not bool(particle_reduced_snapshot.get("ambient_particles", true))
		and bool(particle_reduced_snapshot.get("event_bursts", false))
		and accents.all(func(light: Node) -> bool: return (light as OmniLight3D).visible),
		"reduced particles should stop ambient emitters without disabling independent lighting",
		failures,
	)
	atmosphere.set_particle_level(&"off")
	var particle_off_snapshot := atmosphere.effect_snapshot()
	_check(
		not bool(particle_off_snapshot.get("event_bursts", true))
		and accents.all(func(light: Node) -> bool: return (light as OmniLight3D).visible),
		"particle off should suppress bursts without becoming a hidden master-effects switch",
		failures,
	)
	atmosphere.set_particle_level(&"full")
	atmosphere.set_effect_level(&"reduced")
	var reduced_snapshot := atmosphere.effect_snapshot()
	atmosphere.pulse_egg_laid(Vector3(1.0, 0.0, 0.0), &"sound")
	await process_frame
	_check(
		String(reduced_snapshot.get("level", "")) == "reduced"
		and is_equal_approx(float(reduced_snapshot.get("animation_speed_multiplier", 0.0)), 1.5)
		and bool(reduced_snapshot.get("ambient_particles", false))
		and bool(reduced_snapshot.get("event_bursts", false))
		and dust.emitting and feathers.emitting,
		"reduced lighting and celebration emphasis should not silently alter the independent particle choice",
		failures,
	)
	atmosphere.set_effect_level(&"off")
	var off_snapshot := atmosphere.effect_snapshot()
	_check(
		String(off_snapshot.get("level", "")) == "off"
		and bool(off_snapshot.get("ambient_particles", false))
		and bool(off_snapshot.get("event_bursts", false))
		and accents.all(func(light: Node) -> bool: return not (light as OmniLight3D).visible)
		and red_bar != null and not red_bar.get_parent().visible
		and farmer_spotlight != null and is_zero_approx(farmer_spotlight.light_energy),
		"essential-only emphasis should remove decorative lighting without overriding particle density",
		failures,
	)
	atmosphere.set_particle_level(&"off")
	var all_off_snapshot := atmosphere.effect_snapshot()
	_check(
		not bool(all_off_snapshot.get("ambient_particles", true))
		and not bool(all_off_snapshot.get("event_bursts", true)),
		"turning both independent controls off should remove decorative lighting and particles",
		failures,
	)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_ATMOSPHERE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_ATMOSPHERE_TEST_PASSED particles=bounded+pooled+prewarmed+independent lights=3-shadowless overtime=emissive events=full+reduced+off animation-speed=live")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
