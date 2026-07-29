extends "res://tests/lab_engine/lab_test_case.gd"

const REVIEW_SCRIPT := preload("res://scripts/lab_engine/shadow/lab_midterm_review_policy.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_seed_selection_is_deterministic()
	_test_submission_rejects_missing_resources()
	_test_literature_briefing()
	_test_raw_data_audit()
	_test_chart_preview()
	_test_process_safety()
	return failures

func _test_seed_selection_is_deterministic() -> void:
	var reviews: RefCounted = REVIEW_SCRIPT.new()
	check_equal(reviews.review_for_seed(240731), reviews.review_for_seed(240731), "same seed must select the same review")
	check_equal(reviews.review_for_seed(0), &"literature_briefing", "seed mapping must start with the first review")
	check_equal(reviews.review_for_seed(3), &"process_safety", "seed mapping must cover the fourth review")

func _test_submission_rejects_missing_resources() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	var result: Dictionary = REVIEW_SCRIPT.new().apply_submission(state, &"chart_preview")
	check(not bool(result.applied), "submission must fail when its cost is unavailable")
	check_equal(state.paper_progress, 0, "failed submission must not mutate progress")

func _test_literature_briefing() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.inspiration = 3
	state.energy = 6
	var result: Dictionary = REVIEW_SCRIPT.new().apply_submission(state, &"literature_briefing")
	check(bool(result.applied), "literature briefing must apply with three inspiration")
	check_equal(state.inspiration, 0, "literature briefing must consume three inspiration")
	check_equal(state.paper_progress, 10, "literature briefing must grant ten progress")
	check_equal(state.energy, 7, "literature briefing must restore one energy")

func _test_raw_data_audit() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.raw_data = 8
	var result: Dictionary = REVIEW_SCRIPT.new().apply_submission(state, &"raw_data_audit")
	check(bool(result.applied), "raw data audit must apply with eight raw data")
	check_equal(state.raw_data, 0, "raw data audit must consume eight raw data")
	check_equal(state.clean_data, 2, "raw data audit must grant two clean data")
	check(state.maintenance_ready, "raw data audit must grant maintenance protection")

func _test_chart_preview() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.charts = 2
	state.technical_debt = 4
	var result: Dictionary = REVIEW_SCRIPT.new().apply_submission(state, &"chart_preview")
	check(bool(result.applied), "chart preview must apply with two charts")
	check_equal(state.charts, 0, "chart preview must consume two charts")
	check_equal(state.paper_progress, 18, "chart preview must grant eighteen progress")
	check_equal(state.technical_debt, 3, "chart preview must reduce debt by one")

func _test_process_safety() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.clean_data = 2
	state.technical_debt = 7
	var result: Dictionary = REVIEW_SCRIPT.new().apply_submission(state, &"process_safety")
	check(bool(result.applied), "process safety must apply with two clean data")
	check_equal(state.clean_data, 0, "process safety must consume two clean data")
	check_equal(state.technical_debt, 4, "process safety must reduce debt by three")
	check(state.maintenance_ready, "process safety must grant maintenance protection")
