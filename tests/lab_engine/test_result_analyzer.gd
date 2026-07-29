extends "res://tests/lab_engine/lab_test_case.gd"

const ANALYZER_SCRIPT := preload("res://scripts/lab_engine/ui/lab_result_analyzer.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_prevented_shutdown_is_not_reported_as_real()
	_test_real_shutdown_names_the_exact_slot()
	_test_last_day_breakthrough_prioritizes_early_accumulation()
	_test_victory_summary_reports_emergency_cashout_and_maintenance()
	_test_victory_summary_reports_standard_cashout()
	_test_victory_summary_has_no_cashout_fallback_claim()
	_test_failed_cashout_produces_specific_advice()
	return failures

func _test_prevented_shutdown_is_not_reported_as_real() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 61
	state.technical_debt = 7
	var history: Array[Dictionary] = [{
		"daily_progress": 6,
		"progress_before": 55,
		"progress_after": 61,
		"stopped_slot": -1,
		"maintenance_prevented_slot": 3,
	}]
	var diagnosis: Dictionary = ANALYZER_SCRIPT.new().analyze(state, history)
	check_equal(diagnosis.stopped_slot, -1, "maintenance prevention must not be diagnosed as a real shutdown")
	check(not String(diagnosis.cause).contains("停机发生"), "prevented shutdown must not produce shutdown wording")

func _test_real_shutdown_names_the_exact_slot() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 61
	state.technical_debt = 7
	var history: Array[Dictionary] = [{
		"daily_progress": 6,
		"progress_before": 55,
		"progress_after": 61,
		"stopped_slot": 3,
		"maintenance_prevented_slot": -1,
	}]
	var diagnosis: Dictionary = ANALYZER_SCRIPT.new().analyze(state, history)
	check_equal(diagnosis.stopped_slot, 3, "real shutdown must retain its prepared slot")
	check(String(diagnosis.cause).contains("分析台"), "real shutdown diagnosis must name the stopped workstation")

func _test_last_day_breakthrough_prioritizes_early_accumulation() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 61
	state.technical_debt = 7
	var history: Array[Dictionary] = [{
		"daily_progress": 36,
		"progress_before": 25,
		"progress_after": 61,
		"stopped_slot": 4,
		"maintenance_prevented_slot": -1,
	}]
	var diagnosis: Dictionary = ANALYZER_SCRIPT.new().analyze(state, history)
	check_equal(diagnosis.last_day_line, "最后日 +36（25 → 61）", "failure panel must expose last-day gain and progress range")
	check(String(diagnosis.cause).contains("前期积累不足"), "last-day breakthrough from a low entry point must identify early accumulation")
	check(String(diagnosis.advice).contains("前 4 天"), "breakthrough diagnosis must include one executable next-run action")

func _test_victory_summary_reports_emergency_cashout_and_maintenance() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 106
	var history: Array[Dictionary] = [{
		"day": 8, "daily_progress": 36, "progress_before": 70, "progress_after": 106,
		"maintenance_prevented_slot": 4,
		"events": [{"success": true, "card_id": &"all_nighter", "details": {
			"cashout_kind": &"emergency", "charts_used": 1, "value_per_chart": 12, "progress_gained": 12,
		}}],
	}]
	var summary: Dictionary = ANALYZER_SCRIPT.new().analyze_victory(state, history)
	check_equal(summary.last_day_line, "第 8 天 +36（70 → 106）", "victory summary must expose the actual winning day and progress range")
	check_equal(summary.cashout_line, "应急补图：1 图 × 12 = 论文 +12", "victory summary must name emergency cashout and its arithmetic")
	check_equal(summary.maintenance_line, "维护保障：写作台免于停机", "victory summary must state only the protected workstation")

func _test_victory_summary_reports_standard_cashout() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 120
	var history: Array[Dictionary] = [{"day": 7, "daily_progress": 30, "progress_before": 90, "progress_after": 120, "events": [{
		"success": true, "card_id": &"all_nighter", "details": {"cashout_kind": &"standard", "charts_used": 3, "value_per_chart": 10, "progress_gained": 30},
	}]}]
	var summary: Dictionary = ANALYZER_SCRIPT.new().analyze_victory(state, history)
	check_equal(summary.cashout_line, "通宵兑现：3 图 × 10 = 论文 +30", "victory summary must name standard cashout")

func _test_victory_summary_has_no_cashout_fallback_claim() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 101
	var summary: Dictionary = ANALYZER_SCRIPT.new().analyze_victory(state, [{"day": 6, "daily_progress": 5, "progress_before": 96, "progress_after": 101, "events": []}])
	check_equal(summary.cashout_line, "", "victory without a successful final-day cashout must not invent one")
	check_equal(summary.last_day_line, "第 6 天 +5（96 → 101）", "early victory must name its actual winning day")

func _test_failed_cashout_produces_specific_advice() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.paper_progress = 82
	var history: Array[Dictionary] = [{"daily_progress": 0, "progress_before": 82, "progress_after": 82, "events": [{
		"success": false, "card_id": &"all_nighter", "details": {"reason": &"no_cashout_resource"},
	}]}]
	var diagnosis: Dictionary = ANALYZER_SCRIPT.new().analyze(state, history)
	check(String(diagnosis.cause).contains("没有库存图表"), "failed cashout evidence must identify the exact cause")
	check(String(diagnosis.advice).contains("应急补图"), "no-chart failure must explain emergency preparation")
