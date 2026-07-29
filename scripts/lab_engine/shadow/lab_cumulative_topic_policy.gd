extends RefCounted

const TOPIC_IDS: Array[StringName] = [
	&"literature_topic",
	&"experiment_topic",
	&"clean_data_topic",
	&"chart_topic",
]

const TARGETS: Dictionary[StringName, Dictionary] = {
	&"literature_topic": {&"inspiration": 5},
	&"experiment_topic": {&"raw_data": 12},
	&"clean_data_topic": {&"clean_data": 3},
	&"chart_topic": {&"charts": 3},
}

const REWARDS: Dictionary[StringName, Dictionary] = {
	&"literature_topic": {&"raw_data": 2},
	&"experiment_topic": {&"clean_data": 1},
	&"clean_data_topic": {&"charts": 1},
	&"chart_topic": {&"paper_progress": 5},
}

func topic_for_seed(seed: int) -> StringName:
	return TOPIC_IDS[posmod(seed, TOPIC_IDS.size())]

func empty_ledger() -> Dictionary[StringName, int]:
	return {
		&"inspiration": 0,
		&"raw_data": 0,
		&"clean_data": 0,
		&"charts": 0,
	}

func record_day(ledger: Dictionary[StringName, int], day_result: Dictionary) -> void:
	for event: Dictionary in day_result.get("events", []):
		var deltas: Dictionary = event.get("deltas", {})
		for resource_id: StringName in ledger:
			var amount: int = int(deltas.get(resource_id, 0))
			if amount > 0:
				ledger[resource_id] += amount

func is_achieved(topic_id: StringName, ledger: Dictionary[StringName, int]) -> bool:
	if not TARGETS.has(topic_id):
		return false
	var target: Dictionary = TARGETS[topic_id]
	for resource_id: StringName in target:
		if int(ledger.get(resource_id, 0)) < int(target[resource_id]):
			return false
	return true

func target_resource(topic_id: StringName) -> StringName:
	if not TARGETS.has(topic_id):
		return &""
	var target: Dictionary = TARGETS[topic_id]
	for resource_id: StringName in target:
		return resource_id
	return &""

func target_amount(topic_id: StringName) -> int:
	var resource_id: StringName = target_resource(topic_id)
	return int(TARGETS.get(topic_id, {}).get(resource_id, 0))

func apply_reward(state: RefCounted, topic_id: StringName, achieved: bool) -> Dictionary:
	if not achieved or not REWARDS.has(topic_id):
		return {"applied": false, "topic_id": topic_id, "reason": &"topic_not_achieved"}
	var requested: Dictionary = REWARDS[topic_id]
	var actual: Dictionary[StringName, int] = {}
	var overflow: Dictionary[StringName, int] = {}
	for resource_id: StringName in requested:
		var amount: int = int(requested[resource_id])
		var applied: int = state.change_resource(resource_id, amount)
		actual[resource_id] = applied
		overflow[resource_id] = amount - applied
	return {
		"applied": true,
		"topic_id": topic_id,
		"requested": requested.duplicate(true),
		"actual": actual,
		"overflow": overflow,
		"total_actual": _sum_values(actual),
		"total_overflow": _sum_values(overflow),
	}

func _sum_values(values: Dictionary[StringName, int]) -> int:
	var total: int = 0
	for resource_id: StringName in values:
		total += values[resource_id]
	return total
