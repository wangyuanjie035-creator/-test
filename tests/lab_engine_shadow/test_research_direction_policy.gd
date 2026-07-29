extends "res://tests/lab_engine/lab_test_case.gd"

const POLICY_SCRIPT := preload("res://scripts/lab_engine/shadow/lab_research_direction_policy.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_theory_requires_both_outputs()
	_test_empirical_rewards_clean_output_once()
	_test_engineering_counts_automatic_events()
	return failures

func _test_theory_requires_both_outputs() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	var policy: RefCounted = POLICY_SCRIPT.new()
	var result := {"events": [{"type": 0, "deltas": {&"inspiration": 1}}, {"type": 0, "deltas": {&"paper_progress": 5}}]}
	check(bool(policy.apply_day(state, &"theory", result).applied), "theory must reward a same-day inspiration and writing loop")
	check_equal(state.paper_progress, 5, "theory reward must add five paper progress")
	check(not bool(policy.apply_day(STATE_SCRIPT.new(), &"theory", {"events": [result.events[0]]}).applied), "theory must not reward only one side of the loop")

func _test_empirical_rewards_clean_output_once() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	var result := {"events": [{"type": 0, "deltas": {&"clean_data": 2}}, {"type": 0, "deltas": {&"clean_data": -1}}]}
	var applied: Dictionary = POLICY_SCRIPT.new().apply_day(state, &"empirical", result)
	check_equal(applied.actual, 1, "empirical direction must grant one clean data per resolved day")

func _test_engineering_counts_automatic_events() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.technical_debt = 4
	var result := {"events": [{"type": 2, "success": true, "deltas": {}}, {"type": 2, "success": true, "deltas": {}}, {"type": 0, "success": true, "deltas": {}}]}
	var applied: Dictionary = POLICY_SCRIPT.new().apply_day(state, &"engineering", result)
	check(bool(applied.applied), "engineering must trigger at two automatic events")
	check_equal(state.technical_debt, 3, "engineering must reduce technical debt by one")
