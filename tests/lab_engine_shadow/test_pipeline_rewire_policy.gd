extends "res://tests/lab_engine/lab_test_case.gd"

const POLICY := preload("res://scripts/lab_engine/shadow/lab_pipeline_rewire_policy.gd")
const STATE := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_only_adjacent_installed_pairs_are_eligible()
	_test_reward_requires_both_ends_to_succeed()
	_test_selection_is_frozen_for_the_run()
	return failures

func _test_only_adjacent_installed_pairs_are_eligible() -> void:
	var state: RefCounted = STATE.new()
	state.slots[1] = _entry(&"experiment")
	state.slots[2] = _entry(&"data")
	state.slots[4] = _entry(&"writing")
	check_equal(POLICY.new().eligible_links(state), [1], "rewire must only offer two adjacent installed productive stations")

func _test_reward_requires_both_ends_to_succeed() -> void:
	var state: RefCounted = STATE.new()
	state.slots[2] = _entry(&"data")
	state.slots[3] = _entry(&"analysis")
	var policy: RefCounted = POLICY.new()
	policy.select_link(state, 2)
	var partial: Dictionary = policy.apply_day(state, {"events": [_event(2, true), _event(3, false)]})
	check(not bool(partial.applied), "a rewire must not reward a broken adjacent link")
	var complete: Dictionary = policy.apply_day(state, {"events": [_event(2, true), _event(3, true)]})
	check(bool(complete.applied), "a rewire must reward a completed adjacent link")
	check_equal(state.charts, 1, "data-analysis rewire must add exactly one chart")

func _test_selection_is_frozen_for_the_run() -> void:
	var state: RefCounted = STATE.new()
	for slot: int in range(3):
		state.slots[slot] = _entry(StringName("slot_%d" % slot))
	var policy: RefCounted = POLICY.new()
	policy.select_link(state, 0)
	var repeated: Dictionary = policy.select_link(state, 1)
	check_equal(repeated.link, 0, "rewire selection must be immutable after settlement")

func _entry(card_id: StringName) -> Dictionary:
	return {"card_id": card_id, "level": 1, "days_installed": 1, "instance_id": 1}

func _event(slot: int, success: bool) -> Dictionary:
	return {"slot": slot, "success": success}
