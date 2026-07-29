extends SceneTree

const TEST_SUITE := preload("res://scripts/tools/dual_topic_m5_smoke_test.gd")


func _initialize() -> void:
	var failures: Array[String] = TEST_SUITE.new().run()
	if failures.is_empty():
		print("DUAL_TOPIC_M5: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("DUAL_TOPIC_M5: FAIL (%d)" % failures.size())
	quit(1)
