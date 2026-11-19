extends SceneTree

func _init() -> void:
	var feedback := OfficeAudioFeedback.new()
	feedback._initialize_sound_bank(true)
	var streams := {}
	for field in OfficeAudioFeedback.SOUND_FIELDS:
		streams[field] = feedback.get(field)
	var bank := Resource.new()
	bank.set_meta("streams", streams)
	var error := ResourceSaver.save(bank, OfficeAudioFeedback.SOUND_BANK_PATH, ResourceSaver.FLAG_COMPRESS)
	feedback.free()
	if error != OK:
		push_error("Could not bake office feedback: %s" % error_string(error))
		quit(1)
	else:
		print("OFFICE_FEEDBACK_BAKED streams=%d" % streams.size())
		quit()
