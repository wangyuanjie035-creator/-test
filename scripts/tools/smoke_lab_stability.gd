extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/lab_engine/lab_workbench.tscn"
const RESTART_CYCLES := 40
const REINSTANCE_CYCLES := 8
const COMPLETE_RUN_CYCLES := 12
const WARMUP_COMPLETE_RUNS := 4
const MODAL_CYCLES := 24
const UI_PLAYBACK_CYCLES := 4
const MEMORY_TOLERANCE_BYTES := 512 * 1024
const OBJECT_TOLERANCE := 32
const GOLDEN_ROUTE: Array[StringName] = [
	&"parameter_scan", &"batch_experiment", &"paper_template", &"batch_experiment",
	&"cleaning", &"scheduler", &"", &"scheduler",
]
const GOLDEN_OVERCLOCKS: Array[int] = [0, -1, 0, 1, 1, -1, -1, -1]

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	_check(packed != null, "main scene must load")
	if packed == null:
		_finish()
		return
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var buses_before := AudioServer.bus_count
	var scene := await _instantiate(packed)
	if scene == null:
		_finish()
		return
	for warmup: int in range(WARMUP_COMPLETE_RUNS):
		await _exercise_complete_run(scene, 240731)
	await _exercise_ui_day(scene, 240731)
	await _exercise_modals(scene)
	var stable_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var stable_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var stable_memory := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var stable_tweens := get_processed_tweens().size()
	var peak_nodes := stable_nodes
	for cycle: int in range(RESTART_CYCLES):
		scene.call("_start_new_run", 240731 + cycle)
		await process_frame
		await process_frame
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	var nodes_after_restarts := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var midpoint_objects := stable_objects
	var midpoint_memory := stable_memory
	for cycle: int in range(COMPLETE_RUN_CYCLES):
		await _exercise_complete_run(scene, 240731)
		if cycle == COMPLETE_RUN_CYCLES / 2 - 1:
			midpoint_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
			midpoint_memory = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var objects_after_complete_runs := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory_after_complete_runs := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var ui_midpoint_objects := objects_after_complete_runs
	var ui_midpoint_memory := memory_after_complete_runs
	for cycle: int in range(UI_PLAYBACK_CYCLES):
		await _exercise_ui_day(scene, 240731)
		if cycle == UI_PLAYBACK_CYCLES / 2 - 1:
			ui_midpoint_objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
			ui_midpoint_memory = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	await _exercise_modals(scene)
	var nodes_after_interactions := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var objects_after_interactions := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var memory_after_interactions := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var tweens_after_restarts := get_processed_tweens().size()
	_check(nodes_after_restarts <= stable_nodes + 2, "restarts must not retain nodes: baseline=%d final=%d peak=%d" % [stable_nodes, nodes_after_restarts, peak_nodes])
	_check(nodes_after_interactions <= stable_nodes + 2, "complete interactions must not retain nodes: baseline=%d final=%d" % [stable_nodes, nodes_after_interactions])
	_check(objects_after_interactions <= stable_objects + OBJECT_TOLERANCE, "complete runs and modals must not retain objects: baseline=%d final=%d" % [stable_objects, objects_after_interactions])
	_check(memory_after_interactions <= stable_memory + MEMORY_TOLERANCE_BYTES, "complete runs and modals must not keep growing static memory: baseline=%d final=%d" % [stable_memory, memory_after_interactions])
	_check(objects_after_complete_runs <= midpoint_objects + 4, "complete-run object count must plateau: midpoint=%d final=%d" % [midpoint_objects, objects_after_complete_runs])
	_check(memory_after_complete_runs <= midpoint_memory + 256 * 1024, "complete-run static memory must plateau: midpoint=%d final=%d" % [midpoint_memory, memory_after_complete_runs])
	_check(objects_after_interactions <= ui_midpoint_objects + 4, "UI-playback object count must plateau: midpoint=%d final=%d" % [ui_midpoint_objects, objects_after_interactions])
	_check(memory_after_interactions <= ui_midpoint_memory + 256 * 1024, "UI-playback static memory must plateau: midpoint=%d final=%d" % [ui_midpoint_memory, memory_after_interactions])
	_check(tweens_after_restarts <= stable_tweens, "restarts must not retain processed tweens: baseline=%d final=%d" % [stable_tweens, tweens_after_restarts])
	scene.queue_free()
	await process_frame
	await process_frame
	for cycle: int in range(REINSTANCE_CYCLES):
		var instance := await _instantiate(packed)
		if instance == null:
			break
		instance.queue_free()
		await process_frame
		await process_frame
	var nodes_after_instances := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_check(nodes_after_instances <= nodes_before + 2, "repeated scene instances must release nodes: before=%d after=%d" % [nodes_before, nodes_after_instances])
	_check(AudioServer.bus_count <= buses_before + 1, "repeated scene instances must not duplicate audio buses: before=%d after=%d" % [buses_before, AudioServer.bus_count])
	_finish()

func _exercise_complete_run(scene: Node, seed: int) -> void:
	scene.call("_start_new_run", seed)
	var controller: RefCounted = scene.get("_controller")
	_check(controller != null, "complete run requires a controller")
	if controller == null:
		return
	for day_index: int in range(8):
		var choices: Array[StringName] = controller.candidates_for_today()
		var selected_id: StringName = GOLDEN_ROUTE[day_index]
		var choice_index := -1 if selected_id == &"" else choices.find(selected_id)
		_check(choice_index >= 0 or selected_id == &"", "golden route card must exist on day %d" % (day_index + 1))
		controller.play_day(choice_index, GOLDEN_OVERCLOCKS[day_index])
		if day_index < 7:
			controller.begin_day()
	var overlay := scene.find_child("ResultOverlay", true, false)
	_check(overlay != null, "complete run requires the result overlay")
	if overlay != null:
		overlay.call("present", controller.state, controller.won, seed, controller.history, controller.topic_snapshot())
		await process_frame
		overlay.call("reset")
	await process_frame
	await process_frame

func _exercise_modals(scene: Node) -> void:
	var help := scene.find_child("HelpOverlay", true, false)
	var settings := scene.find_child("SettingsOverlay", true, false)
	_check(help != null and settings != null, "modal cycle requires help and settings overlays")
	if help == null or settings == null:
		return
	for cycle: int in range(MODAL_CYCLES):
		help.call("open_help")
		help.call("close_help")
		settings.call("open_settings", {"master_volume": 0.8, "window_mode": "windowed"})
		settings.call("close_settings")
	await process_frame
	await process_frame

func _exercise_ui_day(scene: Node, seed: int) -> void:
	scene.call("_start_new_run", seed)
	var help := scene.find_child("HelpOverlay", true, false)
	if help != null:
		help.call("close_help")
	scene.call("_select_candidate", 0)
	await scene.call("_run_day")
	await create_timer(0.8).timeout
	await process_frame
	await process_frame

func _instantiate(packed: PackedScene) -> Node:
	var scene := packed.instantiate()
	_check(scene != null, "main scene must instantiate")
	if scene == null:
		return null
	scene.set("profile_persistence_enabled", false)
	scene.set("settings_persistence_enabled", false)
	scene.set("settings_application_enabled", false)
	root.add_child(scene)
	await process_frame
	await process_frame
	var help := scene.find_child("HelpOverlay", true, false)
	if help != null:
		help.call("close_help")
	await process_frame
	return scene

func _finish() -> void:
	if _failed:
		quit(1)
		return
	print("LAB_STABILITY_SMOKE: PASS (%d restarts, %d complete runs, %d UI playbacks, %d modal cycles, %d reinstantiations)" % [RESTART_CYCLES, COMPLETE_RUN_CYCLES, UI_PLAYBACK_CYCLES, MODAL_CYCLES, REINSTANCE_CYCLES])
	quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("LAB_STABILITY_SMOKE: %s" % message)
