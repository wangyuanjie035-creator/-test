extends "res://tests/lab_engine/lab_test_case.gd"

const POLICY := preload("res://scripts/lab_engine/shadow/lab_zero_sum_rewire_policy.gd")
const STATE := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_conversion_spends_real_stock_at_baseline_ratio()
	_test_incomplete_link_does_not_convert()
	_test_output_clamp_cannot_destroy_input()
	return failures

func _test_conversion_spends_real_stock_at_baseline_ratio() -> void:
	var state: RefCounted = _state_with_link(1)
	state.raw_data = 7
	var policy: RefCounted = POLICY.new()
	policy.select_link(state, 1)
	var result: Dictionary = policy.apply_day(state, _completed_link(1))
	check(bool(result.applied), "zero-sum rewire must apply to a completed funded link")
	check_equal(state.raw_data, 3, "data rewire must spend four raw data")
	check_equal(state.clean_data, 1, "data rewire must create one clean data")

func _test_incomplete_link_does_not_convert() -> void:
	var state: RefCounted = _state_with_link(2)
	state.clean_data = 2
	var policy: RefCounted = POLICY.new()
	policy.select_link(state, 2)
	check(not bool(policy.apply_day(state, {"events": [{"slot": 2, "success": true}]}).applied), "broken link must not consume stock")
	check_equal(state.clean_data, 2, "broken link must preserve its input")

func _test_output_clamp_cannot_destroy_input() -> void:
	var state: RefCounted = _state_with_link(2)
	state.clean_data = 2
	state.charts = 10
	var policy: RefCounted = POLICY.new()
	policy.select_link(state, 2)
	check(not bool(policy.apply_day(state, _completed_link(2)).applied), "a clamped output must reject the whole conversion")
	check_equal(state.clean_data, 2, "rejected conversion must not consume input")

func _state_with_link(link: int) -> RefCounted:
	var state: RefCounted = STATE.new()
	for slot: int in [link, link + 1]:
		state.slots[slot] = {"card_id": StringName("slot_%d" % slot), "level": 1, "days_installed": 1, "instance_id": slot + 1}
	return state

func _completed_link(link: int) -> Dictionary:
	return {"events": [{"slot": link, "success": true}, {"slot": link + 1, "success": true}]}
