extends "res://tests/lab_engine/lab_test_case.gd"

const POLICY_SCRIPT := preload("res://scripts/lab_engine/shadow/lab_cumulative_topic_policy.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_topic_selection_is_deterministic()
	_test_ledger_counts_only_positive_production()
	_test_each_target_boundary()
	_test_each_reward_advances_one_link()
	_test_reward_requires_achievement()
	_test_reward_reports_inventory_overflow()
	return failures

func _test_topic_selection_is_deterministic() -> void:
	var policy: RefCounted = POLICY_SCRIPT.new()
	check_equal(policy.topic_for_seed(240731), policy.topic_for_seed(240731), "same seed must select the same topic")
	check_equal(policy.topic_for_seed(0), &"literature_topic", "topic mapping must start with literature")
	check_equal(policy.topic_for_seed(3), &"chart_topic", "topic mapping must cover charts")

func _test_ledger_counts_only_positive_production() -> void:
	var policy: RefCounted = POLICY_SCRIPT.new()
	var ledger: Dictionary[StringName, int] = policy.empty_ledger()
	policy.record_day(ledger, {
		"events": [
			{"deltas": {&"inspiration": 3, &"raw_data": -2}},
			{"deltas": {&"raw_data": 6, &"clean_data": 1, &"paper_progress": 10}},
		]
	})
	check_equal(ledger.inspiration, 3, "ledger must count produced inspiration")
	check_equal(ledger.raw_data, 6, "ledger must ignore consumed raw data")
	check_equal(ledger.clean_data, 1, "ledger must count produced clean data")
	check_equal(ledger.charts, 0, "ledger must leave absent resources unchanged")

func _test_each_target_boundary() -> void:
	var policy: RefCounted = POLICY_SCRIPT.new()
	for topic_id: StringName in policy.TOPIC_IDS:
		var ledger: Dictionary[StringName, int] = policy.empty_ledger()
		var resource_id: StringName = policy.target_resource(topic_id)
		var amount: int = policy.target_amount(topic_id)
		ledger[resource_id] = amount - 1
		check(not policy.is_achieved(topic_id, ledger), "%s must reject one below its target" % topic_id)
		ledger[resource_id] = amount
		check(policy.is_achieved(topic_id, ledger), "%s must accept its exact target" % topic_id)

func _test_each_reward_advances_one_link() -> void:
	var policy: RefCounted = POLICY_SCRIPT.new()
	var expected: Dictionary[StringName, Dictionary] = {
		&"literature_topic": {&"raw_data": 2},
		&"experiment_topic": {&"clean_data": 1},
		&"clean_data_topic": {&"charts": 1},
		&"chart_topic": {&"paper_progress": 5},
	}
	for topic_id: StringName in expected:
		var state: RefCounted = STATE_SCRIPT.new()
		var result: Dictionary = policy.apply_reward(state, topic_id, true)
		check(bool(result.applied), "%s reward must apply after achievement" % topic_id)
		for resource_id: StringName in expected[topic_id]:
			check_equal(state.get(resource_id), expected[topic_id][resource_id], "%s must advance its downstream resource" % topic_id)

func _test_reward_requires_achievement() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	var result: Dictionary = POLICY_SCRIPT.new().apply_reward(state, &"chart_topic", false)
	check(not bool(result.applied), "unachieved topic must not grant a reward")
	check_equal(state.paper_progress, 0, "unachieved reward must not mutate state")

func _test_reward_reports_inventory_overflow() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.raw_data = 19
	var result: Dictionary = POLICY_SCRIPT.new().apply_reward(state, &"literature_topic", true)
	check_equal(state.raw_data, 20, "reward must respect the existing resource cap")
	check_equal(result.actual[&"raw_data"], 1, "reward must report the actual applied amount")
	check_equal(result.overflow[&"raw_data"], 1, "reward must report discarded overflow")
