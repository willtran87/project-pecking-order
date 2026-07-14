extends SceneTree

const OfficeAtmosphereScript := preload("res://features/office/office_atmosphere.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures: Array[String] = []
	var atmosphere := OfficeAtmosphereScript.new()
	root.add_child(atmosphere)
	await process_frame

	var dust := atmosphere.find_child("AmbientDustMotes", true, false) as GPUParticles3D
	var feathers := atmosphere.find_child("DriftingFeathers", true, false) as GPUParticles3D
	var accents := atmosphere.find_children("*Accent", "OmniLight3D", true, false)
	var red_bar := atmosphere.find_child("RedAlertStrip", true, false) as MeshInstance3D
	var farmer_spotlight := atmosphere.find_child("FarmerReviewSpotlight", true, false) as SpotLight3D
	_check(dust != null and dust.visibility_aabb.size.length() > 1.0, "dust motes need explicit visibility bounds", failures)
	_check(feathers != null and feathers.visibility_aabb.size.length() > 1.0, "feathers need explicit visibility bounds", failures)
	_check(accents.size() == 3, "atmosphere should keep the accent light budget at three", failures)
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
	})
	atmosphere.pulse_alert(0.8)
	atmosphere.pulse_farmer_review()
	atmosphere.pulse_egg_laid(Vector3.ZERO, &"golden")
	await process_frame
	await process_frame

	var red_material := red_bar.material_override as StandardMaterial3D if red_bar != null else null
	_check(red_material != null and red_material.emission_enabled, "overtime bars should use emissive materials", failures)
	_check(farmer_spotlight != null and farmer_spotlight.light_energy > 0.5, "farmer review should receive a focused golden light cue", failures)
	_check(atmosphere.find_child("EggGatheringPulse*", true, false) != null, "egg events should create a bounded one-shot burst", failures)

	if not failures.is_empty():
		for failure in failures:
			push_error("OFFICE_ATMOSPHERE_TEST_FAILED: %s" % failure)
		quit(1)
		return
	print("OFFICE_ATMOSPHERE_TEST_PASSED particles=bounded lights=3-shadowless overtime=emissive events=burst")
	quit(0)


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
