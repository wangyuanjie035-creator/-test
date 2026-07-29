extends SceneTree

const TEST_SUITES: Array[Script] = [
	preload("res://tests/lab_engine/test_audio_cue_catalog.gd"),
	preload("res://tests/lab_engine/test_content_catalog.gd"),
	preload("res://tests/lab_engine/test_run_state.gd"),
	preload("res://tests/lab_engine/test_profile_store.gd"),
	preload("res://tests/lab_engine/test_settings_store.gd"),
	preload("res://tests/lab_engine/test_cumulative_topic.gd"),
	preload("res://tests/lab_engine/test_candidate_generator.gd"),
	preload("res://tests/lab_engine/test_simulation.gd"),
	preload("res://tests/lab_engine/test_run_controller.gd"),
	preload("res://tests/lab_engine/test_result_analyzer.gd"),
	preload("res://tests/lab_engine/test_day_playback.gd"),
	preload("res://tests/lab_engine/test_day_result_summary.gd"),
	preload("res://tests/lab_engine/test_opening_blind_recorder.gd"),
]

func _init() -> void:
	var failure_count: int = 0
	for suite_script: Script in TEST_SUITES:
		var suite: RefCounted = suite_script.new()
		var failures: Array[String] = suite.run()
		var suite_name: String = suite_script.resource_path.get_file()
		if failures.is_empty():
			print("LAB_TEST: PASS: %s" % suite_name)
			continue
		for failure: String in failures:
			failure_count += 1
			push_error("LAB_TEST: FAIL: %s: %s" % [suite_name, failure])
	if failure_count > 0:
		print("LAB_TEST_SUITE: FAIL (%d)" % failure_count)
		quit(1)
		return
	print("LAB_TEST_SUITE: PASS (%d suites)" % TEST_SUITES.size())
	quit(0)
