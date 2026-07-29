extends SceneTree

const MAIN_SCENE := preload("res://scenes/lab_engine/lab_workbench.tscn")
const RECORD_PATH := "res://docs/playtests/phase12/sessions/_phase12_e2e_smoke.jsonl"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_remove_record_artifacts()
	var scene: Node = MAIN_SCENE.instantiate()
	scene.set("profile_persistence_enabled", false)
	scene.set("settings_persistence_enabled", false)
	scene.set("settings_application_enabled", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	var recorder: Node = scene.find_child("OpeningBlindRecorder", true, false)
	_check(recorder != null, "main scene must expose the Phase 12 recorder")
	if recorder == null:
		_finish(scene)
		return
	var armed: bool = recorder.arm_with_configuration({
		"test_id": "P12-E2E-SMOKE",
		"participant_id": "anon-e2e-smoke",
		"sample_type": "test_fixture",
		"record_path": RECORD_PATH,
		"expected_seed": 244002,
	})
	_check(armed, "valid preregistered configuration must arm")
	var help_overlay := scene.find_child("HelpOverlay", true, false) as Control
	if help_overlay != null:
		help_overlay.call("close_help")
	var ready_deadline: int = Time.get_ticks_msec() + 5000
	while int(recorder.get("_interface_ready_ticks")) <= 0 and Time.get_ticks_msec() < ready_deadline:
		await process_frame
	_check(int(recorder.get("_interface_ready_ticks")) > 0, "recorder must reach an unobstructed choice screen")
	await process_frame
	await process_frame
	var candidate_box := scene.find_child("CandidateBox", true, false) as Control
	var run_button := scene.find_child("RunButton", true, false) as Button
	_check(candidate_box != null and candidate_box.get_child_count() == 3, "preregistered Seed must show three candidates")
	_check(run_button != null, "Day 1 submission requires the run button")
	if candidate_box != null and run_button != null:
		(candidate_box.get_child(0) as Button).pressed.emit()
		run_button.pressed.emit()
	var record_deadline: int = Time.get_ticks_msec() + 10000
	while not FileAccess.file_exists(RECORD_PATH) and Time.get_ticks_msec() < record_deadline:
		await process_frame
	_check(FileAccess.file_exists(RECORD_PATH), "Day 1 submission must produce a JSONL record")
	if FileAccess.file_exists(RECORD_PATH):
		var file: FileAccess = FileAccess.open(RECORD_PATH, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_line()) if file != null else null
		if file != null:
			file.close()
		_check(parsed is Dictionary, "record must be parseable JSON")
		if parsed is Dictionary:
			_check_equal(String(parsed.get("test_id", "")), "P12-E2E-SMOKE", "record must retain test ID")
			_check_equal(int(parsed.get("seed", 0)), 244002, "record must retain preregistered Seed")
			_check(not String(parsed.get("topic_id", "")).is_empty(), "record must retain topic_id")
			_check_equal(Array(parsed.get("candidate_ids", [])).size(), 3, "record must freeze three candidates")
			_check(int(parsed.get("timing", {}).get("decision_ms", 0)) >= 0, "record must contain automatic timing")
			_check_equal(int(parsed.get("actual_day_one_result", {}).get("day", 0)), 1, "record must capture Day 1")
			_check_equal(String(parsed.get("unprompted", {}).get("choice_kind", "")), "candidate", "record must classify first candidate choice")
	var playback_deadline: int = Time.get_ticks_msec() + 5000
	while bool(scene.get("_is_playing_day")) and Time.get_ticks_msec() < playback_deadline:
		await process_frame
	_check(not bool(scene.get("_is_playing_day")), "Day 1 playback must release before teardown")
	# Non-blocking feedback tweens intentionally outlive the playback coroutine.
	# Let their longest hold/fade tail finish before checking teardown ownership.
	await create_timer(1.0).timeout
	_finish(scene)

func _finish(scene: Node) -> void:
	current_scene = null
	if is_instance_valid(scene):
		scene.queue_free()
	await process_frame
	await process_frame
	_remove_record_artifacts()
	if _failed:
		quit(1)
		return
	print("PHASE12_BLIND_RECORDER_SMOKE: PASS")
	quit(0)

func _remove_record_artifacts() -> void:
	for suffix: String in ["", ".tmp", ".bak"]:
		var path: String = ProjectSettings.globalize_path(RECORD_PATH + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("PHASE12_BLIND_RECORDER_SMOKE: %s" % message)

func _check_equal(actual: Variant, expected: Variant, message: String) -> void:
	_check(actual == expected, "%s (expected=%s actual=%s)" % [message, expected, actual])
