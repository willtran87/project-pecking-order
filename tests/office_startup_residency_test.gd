extends SceneTree

const OfficeScript := preload("res://features/office/office.gd")
const PREVIEWS := "res://features/office/office_preview_runner.gd"
const BLUEPRINT := "res://features/office/capital_blueprint_ui.gd"
const STAFFING := "res://features/office/roost_staffing_ui.gd"
const SETTINGS := "res://features/office/settings_ui.gd"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	assert(not ResourceLoader.has_cached(PREVIEWS), "Office loading must not compile preview scenarios")
	assert(not ResourceLoader.has_cached(BLUEPRINT), "Office loading must not compile unopened capital UI")
	assert(not ResourceLoader.has_cached(STAFFING), "Office loading must not compile unopened staffing UI")
	assert(not ResourceLoader.has_cached(SETTINGS), "Office loading must not compile unopened settings UI")
	var office := OfficeScript.new() as Office
	office.set("_defer_capital_planning", true)
	office.set("_defer_management_ui", true)
	root.add_child(office)
	await process_frame
	var campaign_ui := office.get("_campaign_ui") as ProbationCampaignUI
	assert(campaign_ui.get("_report_panel") == null and campaign_ui.get("_final_panel") == null)
	assert(office.get("_capital_blueprint_ui") == null)
	assert(not ResourceLoader.has_cached(PREVIEWS))
	assert(not ResourceLoader.has_cached(BLUEPRINT))
	assert(not ResourceLoader.has_cached(STAFFING))
	assert(not ResourceLoader.has_cached(SETTINGS))
	assert(office.get("_staffing_ui") == null and office.get("_settings_ui") == null)
	office.call("_restore_campaign_interface_context", office.call("_default_campaign_interface_context"))
	assert(office.get("_capital_blueprint_ui") == null, "Default career context must stay lazy")
	assert(office.get("_staffing_ui") == null, "Default staffing context must stay lazy")
	office.call("_set_campaign_modal_open", false)
	var preferences := office.get("_player_preferences") as Dictionary
	preferences["ui_scale"] = 1.25
	office.call("_on_settings_requested")
	var settings: Control = office.get("_settings_ui")
	assert(settings != null and bool(settings.call("is_open")))
	office.call("_on_settings_close_requested")
	office.call("_on_career_backup_settings_requested")
	assert(office.get("_settings_ui") == settings, "Settings and backup routes must reuse the surface")
	office.call("_on_settings_close_requested")
	var saved_context: Dictionary = office.call("_default_campaign_interface_context")
	saved_context["capital_filter_id"] = "all"
	saved_context["feed_offers_expanded"] = true
	office.call("_restore_campaign_interface_context", saved_context)
	var staffing: Control = office.get("_staffing_ui")
	assert(staffing != null and ResourceLoader.has_cached(STAFFING))
	assert(bool((staffing.call("presentation_context") as Dictionary).get("feed_offers_expanded")))
	var navigator: Control = office.get("_flockwatch_navigation")
	var sections: Dictionary = navigator.get("_sections")
	for section_id in [&"staffing_flock", &"staffing_operations", &"staffing_capital", &"staffing_records"]:
		assert(sections.has(section_id), "Late staffing must register every navigation section")
		assert(navigator.is_ancestor_of(sections[section_id]["control"]))
	office.call("_set_flockwatch_open", true)
	assert(office.get("_staffing_ui") == staffing)
	office.call("_set_flockwatch_open", false)
	var restored_blueprint := office.get("_capital_blueprint_ui") as Control
	assert(restored_blueprint != null and not bool(restored_blueprint.call("is_open")))
	assert(String(restored_blueprint.call("active_filter_id")) == "all", "Saved selections survive lazy construction")
	office.call("_open_capital_blueprint", false, false)
	var blueprint := office.get("_capital_blueprint_ui") as Control
	assert(blueprint != null and bool(blueprint.call("is_open")))
	assert(ResourceLoader.has_cached(BLUEPRINT))
	var title := blueprint.get("_inspector_title") as Label
	assert(title.get_theme_font_size("font_size") == roundi(float(title.get_meta("preference_base_font_size")) * 1.25))
	office.call("_on_capital_blueprint_close_requested")
	assert(not bool(blueprint.call("is_open")))
	office.call("_open_capital_blueprint", false, false)
	assert(office.get("_capital_blueprint_ui") == blueprint, "Reopening must reuse controls and signal connections")
	var report: Dictionary = office.call("_campaign_capture_report", 3)
	assert(report.day == 3 and report.quota == 27)
	assert(ResourceLoader.has_cached(PREVIEWS))
	var runner: RefCounted = office.get("_preview_runner")
	assert(runner.get("office") == office, "Preview scenarios must use the existing office")
	office.call("_prepare_capture_running")
	assert(office.get("_preview_runner") == runner)
	assert((office.get("_simulation") as DepartmentSimulation).pending_decision.is_empty())
	campaign_ui.show_between_shift_report({"day": 3, "report": report})
	var report_panel: Control = campaign_ui.get("_report_panel")
	assert(report_panel != null and report_panel.visible)
	assert(campaign_ui.get("_final_panel") == null, "A shift report must not construct the final review")
	var report_title := campaign_ui.get("_report_heading_label") as Label
	assert(report_title.get_theme_font_size("font_size") == roundi(float(report_title.get_meta("preference_base_font_size")) * 1.25))
	campaign_ui.show_title()
	campaign_ui.show_between_shift_report({"day": 3, "report": report})
	assert(campaign_ui.get("_report_panel") == report_panel, "Repeat reports must reuse controls and connections")
	campaign_ui.show_final_review({"passed": true, "score": 80})
	var final_panel: Control = campaign_ui.get("_final_panel")
	assert(final_panel != null and final_panel.visible)
	var verdict := campaign_ui.get("_final_verdict_label") as Label
	assert(verdict.get_theme_font_size("font_size") == roundi(float(verdict.get_meta("preference_base_font_size")) * 1.25))
	office.free()
	await process_frame
	print("OFFICE_STARTUP_RESIDENCY_TEST_PASSED unopened=unloaded controls=reused previews=on-demand")
	quit()
