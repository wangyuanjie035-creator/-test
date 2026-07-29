extends SceneTree

const TEST_SUITE := preload("res://scripts/tools/dual_topic_m3_smoke_test.gd")


func _initialize() -> void:
	var failures: Array[String] = TEST_SUITE.new().run()
	if failures.is_empty():
		print("DUAL_TOPIC_M3: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("DUAL_TOPIC_M3: FAIL (%d)" % failures.size())
	quit(1)
