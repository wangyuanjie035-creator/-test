extends SceneTree

const TEST_SUITES: Array[Script] = [
	preload("res://tests/lab_engine_shadow/test_midterm_review_policy.gd"),
	preload("res://tests/lab_engine_shadow/test_cumulative_topic_policy.gd"),
	preload("res://tests/lab_engine_shadow/test_research_direction_policy.gd"),
	preload("res://tests/lab_engine_shadow/test_day_four_renovation_policy.gd"),
	preload("res://tests/lab_engine_shadow/test_pipeline_rewire_policy.gd"),
	preload("res://tests/lab_engine_shadow/test_zero_sum_rewire_policy.gd"),
	preload("res://tests/lab_engine_shadow/test_manual_dispatch_policy.gd"),
]

func _init() -> void:
	var failure_count: int = 0
	for suite_script: Script in TEST_SUITES:
		var suite: RefCounted = suite_script.new()
		var failures: Array[String] = suite.run()
		var suite_name: String = suite_script.resource_path.get_file()
		if failures.is_empty():
			print("LAB_SHADOW_TEST: PASS: %s" % suite_name)
			continue
		for failure: String in failures:
			failure_count += 1
			push_error("LAB_SHADOW_TEST: FAIL: %s: %s" % [suite_name, failure])
	if failure_count > 0:
		print("LAB_SHADOW_TEST_SUITE: FAIL (%d)" % failure_count)
		quit(1)
		return
	print("LAB_SHADOW_TEST_SUITE: PASS (%d suites)" % TEST_SUITES.size())
	quit(0)
