extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var started := Time.get_ticks_msec()
	var scene_path := "res://features/office/office.tscn"
	var scene := load(scene_path) as PackedScene
	var loaded := Time.get_ticks_msec()
	var office := scene.instantiate()
	var instantiated := Time.get_ticks_msec()
	add_child(office)
	var ready := Time.get_ticks_msec()
	var timings := {"entry_ms":started,"load_ms":loaded-started,"instantiate_ms":instantiated-loaded,"ready_ms":ready-instantiated}
	print("ENGINE_INIT_PHASE " + JSON.stringify(timings))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__engineInitProbe=" + JSON.stringify(timings),true)
