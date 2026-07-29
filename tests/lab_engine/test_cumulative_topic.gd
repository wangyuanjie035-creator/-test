extends "res://tests/lab_engine/lab_test_case.gd"

const TOPIC_SCRIPT := preload("res://scripts/lab_engine/model/lab_cumulative_topic.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const CONTROLLER_SCRIPT := preload("res://scripts/lab_engine/run/lab_run_controller.gd")

func run() -> Array[String]:
	_test_seed_selection_is_deterministic()
	_test_only_positive_target_output_counts_during_first_three_days()
	_test_reward_is_capped_and_settlement_is_idempotent()
	_test_missed_topic_has_no_penalty()
	_test_controller_settles_once_on_day_four_after_preparation()
	_test_forecasts_do_not_change_topic_progress()
	return failures

func _test_seed_selection_is_deterministic() -> void:
	for seed: int in [1, 2, 3, 4, 240731]:
		check_equal(TOPIC_SCRIPT.new(seed).topic_id, TOPIC_SCRIPT.new(seed).topic_id, "same seed must select the same topic")
	check_equal(TOPIC_SCRIPT.new(4).topic_id, &"literature_topic", "seed mapping must remain stable")

func _test_only_positive_target_output_counts_during_first_three_days() -> void:
	var topic: RefCounted = TOPIC_SCRIPT.new(4)
	topic.record_day(1, {"events": [{"deltas": {&"inspiration": 3}}, {"deltas": {&"inspiration": -2}}, {"deltas": {&"raw_data": 9}}]})
	topic.record_day(2, {"events": [{"deltas": {&"inspiration": 2}}]})
	topic.record_day(4, {"events": [{"deltas": {&"inspiration": 99}}]})
	check_equal(topic.progress, 5, "ledger must count positive target output from days one to three only")
	check_equal(topic.today_progress, 0, "out-of-window day must clear today's progress without changing the ledger")
	check_equal(topic.snapshot(3).status, &"achieved_waiting", "reaching the target before day four must wait for settlement")

func _test_reward_is_capped_and_settlement_is_idempotent() -> void:
	var topic: RefCounted = TOPIC_SCRIPT.new(4)
	topic.progress = 5
	var state: RefCounted = STATE_SCRIPT.new()
	state.raw_data = 19
	var first: Dictionary = topic.settle(state)
	var second: Dictionary = topic.settle(state)
	check_equal(state.raw_data, 20, "reward must obey the normal inventory cap")
	check_equal(first.actual, 1, "settlement must report actual stored reward")
	check_equal(first.overflow, 1, "settlement must report overflow")
	check_equal(second, first, "repeated settlement must return the frozen result")

func _test_missed_topic_has_no_penalty() -> void:
	var topic: RefCounted = TOPIC_SCRIPT.new(4)
	var state: RefCounted = STATE_SCRIPT.new()
	var before: Dictionary = state.snapshot()
	var result: Dictionary = topic.settle(state)
	check(not bool(result.achieved), "an unmet target must settle as missed")
	check_equal(state.snapshot(), before, "missing a topic must not change run resources")

func _test_controller_settles_once_on_day_four_after_preparation() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(4)
	controller.state.day = 4
	controller.cumulative_topic.progress = 5
	controller.state.raw_data = 0
	var first: Dictionary = controller.begin_day()
	var second: Dictionary = controller.begin_day()
	check(bool(first.topic_just_settled), "first day-four preparation must settle the topic")
	check(not bool(second.topic_just_settled), "repeated day-four preparation must not settle twice")
	check_equal(controller.state.raw_data, 2, "day-four reward must enter inventory exactly once")
	check_equal(first.topic.settlement.actual, 2, "preview must expose the frozen actual reward")

func _test_forecasts_do_not_change_topic_progress() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(4)
	controller.begin_day()
	var before: Dictionary = controller.topic_snapshot()
	controller.forecast_day(-2, -1)
	controller.forecast_day(-2, 0)
	check_equal(controller.topic_snapshot(), before, "forecasting must never write to the live topic ledger")
