extends SceneTree

const SAMPLE_PASSES := 12
const PROFILE_FILENAME := "profile_campaign_checkpoint.json"


func _init() -> void:
	_profile.call_deferred()


func _profile() -> void:
	root.size = Vector2i(1280, 720)
	var office := Office.new()
	root.add_child(office)
	for _frame in 24:
		await process_frame
	var store := CampaignSaveStore.new(PROFILE_FILENAME)
	store.delete()
	office.set("_campaign_store", store)
	office.set("_allow_automated_campaign_saves", true)
	office.set("_campaign_session_checkpoint_enabled", true)
	var campaign_state := office.get("_campaign_state") as CampaignState
	var simulation := office.get("_simulation") as DepartmentSimulation
	var senior_state := office.get("_senior_roost_state") as SeniorRoostState
	var payload := {
		"campaign": campaign_state.to_dictionary(),
		"simulation": simulation.export_save_state(),
		"senior_roost": senior_state.to_dictionary(),
		"session": {
			"review_stage": String(office.get("_campaign_review_stage")),
			"last_workday_report": (office.get("_last_workday_report") as Dictionary).duplicate(true),
			"senior_roost": senior_state.is_active(),
			"first_clutch": (office.get("_first_clutch") as Dictionary).duplicate(true),
		},
	}
	var metadata := {
		"reason": "profile",
		"day": simulation.day,
		"completed_shifts": campaign_state.completed_shifts,
		"probation_score": campaign_state.probation_score,
		"probation_rank": String(campaign_state.probation_rank),
		"challenge_contract_id": String(campaign_state.challenge_contract_id),
		"review_stage": String(office.get("_campaign_review_stage")),
		"senior_years": senior_state.completed_years,
		"roost_marks": senior_state.roost_marks,
	}
	var safe_payload := office.call("_json_safe_variant", payload) as Dictionary
	var safe_metadata := office.call("_json_safe_variant", metadata) as Dictionary
	var diagnostic_envelope := {
		"format": CampaignSaveStore.SAVE_FORMAT,
		"schema_version": CampaignSaveStore.CURRENT_SCHEMA_VERSION,
		"campaign": safe_payload,
		"metadata": safe_metadata,
	}
	var integer_offsets := store.call("_collect_integer_offsets", diagnostic_envelope) as Array
	diagnostic_envelope["integer_offsets"] = integer_offsets
	var samples: Array[int] = []
	var capture_samples: Array[int] = []
	var json_safe_samples: Array[int] = []
	var store_samples: Array[int] = []
	for sample_index in SAMPLE_PASSES:
		var started := Time.get_ticks_usec()
		var sample_payload := {
			"campaign": campaign_state.to_dictionary(),
			"simulation": simulation.export_save_state(),
			"senior_roost": senior_state.to_dictionary(),
			"session": {
				"review_stage": String(office.get("_campaign_review_stage")),
				"last_workday_report": (office.get("_last_workday_report") as Dictionary).duplicate(true),
				"senior_roost": senior_state.is_active(),
				"first_clutch": (office.get("_first_clutch") as Dictionary).duplicate(true),
			},
		}
		var sample_metadata := metadata.duplicate(true)
		sample_metadata["reason"] = "profile_%d" % sample_index
		var captured := Time.get_ticks_usec()
		var sample_safe_payload := office.call("_json_safe_variant", sample_payload) as Dictionary
		var sample_safe_metadata := office.call("_json_safe_variant", sample_metadata) as Dictionary
		var made_safe := Time.get_ticks_usec()
		var saved := store.save(sample_safe_payload, sample_safe_metadata)
		var stored := Time.get_ticks_usec()
		var elapsed := Time.get_ticks_usec() - started
		if not saved:
			push_error("PROFILE_CHECKPOINT_SAVE_FAILED %s" % store.last_error)
			store.delete()
			office.free()
			quit(1)
			return
		samples.append(elapsed)
		capture_samples.append(captured - started)
		json_safe_samples.append(made_safe - captured)
		store_samples.append(stored - made_safe)
	var primary_path := "user://%s" % PROFILE_FILENAME
	var bytes := FileAccess.get_file_as_bytes(primary_path).size()
	print("CAMPAIGN_CHECKPOINT_PROFILE %s" % JSON.stringify({
		"bytes": bytes,
		"payload_json_bytes": JSON.stringify(safe_payload).to_utf8_buffer().size(),
		"integer_offset_count": integer_offsets.size(),
		"integer_offsets_json_bytes": JSON.stringify(integer_offsets).to_utf8_buffer().size(),
		"envelope_json_bytes": JSON.stringify(diagnostic_envelope).to_utf8_buffer().size(),
		"samples": _summary(samples),
		"capture": _summary(capture_samples),
		"json_safe": _summary(json_safe_samples),
		"store": _summary(store_samples),
	}))
	store.delete()
	office.free()
	await process_frame
	quit(0)


func _summary(samples: Array[int]) -> Dictionary:
	var sorted := samples.duplicate()
	sorted.sort()
	var total := 0
	for sample in sorted:
		total += sample
	return {
		"count": sorted.size(),
		"average_usec": float(total) / maxf(1.0, float(sorted.size())),
		"median_usec": sorted[sorted.size() / 2],
		"p95_usec": sorted[mini(sorted.size() - 1, floori(sorted.size() * 0.95))],
		"maximum_usec": sorted[-1],
	}
