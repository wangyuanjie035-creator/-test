extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/lab_engine/lab_workbench.tscn"
const MEASURED_PLAYBACKS := 4
const SETTLE_SECONDS := 0.8

class FrameSampler extends Node:
	var collecting := false
	var deltas: Array[float] = []

	func _process(delta: float) -> void:
		if collecting:
			deltas.append(delta)

	func begin() -> void:
		deltas.clear()
		collecting = true

	func finish() -> Array[float]:
		collecting = false
		return deltas.duplicate()

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(MAIN_SCENE_PATH) as PackedScene
	_check(packed != null, "main scene must load")
	if packed == null:
		_finish([])
		return
	var scene := packed.instantiate()
	scene.set("profile_persistence_enabled", false)
	scene.set("settings_persistence_enabled", false)
	scene.set("settings_application_enabled", false)
	root.add_child(scene)
	var sampler := FrameSampler.new()
	root.add_child(sampler)
	await process_frame
	await process_frame
	await _play_one_day(scene, sampler, 240731, false)
	var all_deltas: Array[float] = []
	for cycle: int in range(MEASURED_PLAYBACKS):
		var samples := await _play_one_day(scene, sampler, 240731, true)
		all_deltas.append_array(samples)
	scene.queue_free()
	sampler.queue_free()
	await process_frame
	await process_frame
	_finish(all_deltas)

func _play_one_day(scene: Node, sampler: FrameSampler, seed: int, measured: bool) -> Array[float]:
	scene.call("_start_new_run", seed)
	var help := scene.find_child("HelpOverlay", true, false)
	if help != null:
		help.call("close_help")
	scene.call("_select_candidate", 0)
	if measured:
		sampler.begin()
	await scene.call("_run_day")
	await create_timer(SETTLE_SECONDS).timeout
	if measured:
		return sampler.finish()
	var empty_samples: Array[float] = []
	return empty_samples

func _finish(deltas: Array[float]) -> void:
	if _failed:
		quit(1)
		return
	_check(not deltas.is_empty(), "rendered playback must collect frame samples")
	if deltas.is_empty():
		quit(1)
		return
	var sorted := deltas.duplicate()
	sorted.sort()
	var total := 0.0
	for delta: float in deltas:
		total += delta
	var average_ms := total / float(deltas.size()) * 1000.0
	var p95_index := mini(sorted.size() - 1, int(ceil(float(sorted.size()) * 0.95)) - 1)
	var p95_ms: float = float(sorted[p95_index]) * 1000.0
	var worst_ms: float = float(sorted[-1]) * 1000.0
	var over_budget := 0
	for delta: float in deltas:
		if delta > 1.0 / 60.0:
			over_budget += 1
	_check(p95_ms <= 16.67, "P95 frame time exceeds the 60 FPS budget: %.3f ms" % p95_ms)
	_check(worst_ms <= 50.0, "worst frame exceeds the hitch budget: %.3f ms" % worst_ms)
	_check(over_budget <= ceili(float(deltas.size()) * 0.01), "more than 1%% of frames exceed 16.67 ms: %d/%d" % [over_budget, deltas.size()])
	if _failed:
		quit(1)
		return
	print("LAB_UI_BENCHMARK: PASS playbacks=%d frames=%d average_ms=%.3f p95_ms=%.3f worst_ms=%.3f over_16_67ms=%d" % [MEASURED_PLAYBACKS, deltas.size(), average_ms, p95_ms, worst_ms, over_budget])
	quit(0)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("LAB_UI_BENCHMARK: %s" % message)
