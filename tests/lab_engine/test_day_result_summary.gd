extends "res://tests/lab_engine/lab_test_case.gd"

const SUMMARY_SCRIPT := preload("res://scripts/lab_engine/ui/lab_day_result_summary.gd")

func run() -> Array[String]:
	_test_key_output_prefers_downstream_resource()
	_test_failure_summary_counts_the_main_bottleneck()
	_test_holding_is_not_reported_as_a_failure()
	return failures

func _test_key_output_prefers_downstream_resource() -> void:
	var result := {
		"events": [
			{"slot": 1, "success": true, "deltas": {&"raw_data": 8}},
			{"slot": 4, "success": true, "deltas": {&"paper_progress": 5}},
		]
	}
	var lines: PackedStringArray = SUMMARY_SCRIPT.new().summarize(result, _slot_names())
	check(lines[0].contains("写作台") and lines[0].contains("论文进度 +5"), "summary must prefer the furthest downstream output")

func _test_failure_summary_counts_the_main_bottleneck() -> void:
	var result := {
		"events": [
			{"slot": 2, "success": false, "deltas": {}},
			{"slot": 2, "success": false, "deltas": {}},
			{"slot": 3, "success": false, "deltas": {}},
		]
	}
	var lines: PackedStringArray = SUMMARY_SCRIPT.new().summarize(result, _slot_names())
	check(lines[0].contains("数据台空转 2 次"), "summary must name the most frequent failed workstation")

func _test_holding_is_not_reported_as_a_failure() -> void:
	var result := {
		"events": [{"slot": 4, "success": false, "deltas": {}, "details": {"reason": &"awaiting_manual_cashout"}}]
	}
	var lines: PackedStringArray = SUMMARY_SCRIPT.new().summarize(result, _slot_names())
	check(lines.is_empty(), "intentional chart holding must not be described as a bottleneck")

func _slot_names() -> Array[String]:
	return ["文献台", "实验台", "数据台", "分析台", "写作台", "休息区"]
