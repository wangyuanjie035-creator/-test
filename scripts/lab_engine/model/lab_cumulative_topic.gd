class_name LabCumulativeTopic
extends RefCounted

const TOPIC_IDS: Array[StringName] = [
	&"literature_topic", &"experiment_topic", &"clean_data_topic", &"chart_topic",
]
const DEFINITIONS: Dictionary[StringName, Dictionary] = {
	&"literature_topic": {"title": "文献积累", "resource": &"inspiration", "target": 5, "reward_resource": &"raw_data", "reward": 2},
	&"experiment_topic": {"title": "实验积累", "resource": &"raw_data", "target": 12, "reward_resource": &"clean_data", "reward": 1},
	&"clean_data_topic": {"title": "数据清洗", "resource": &"clean_data", "target": 3, "reward_resource": &"charts", "reward": 1},
	&"chart_topic": {"title": "图表积累", "resource": &"charts", "target": 3, "reward_resource": &"paper_progress", "reward": 5},
}
const RESOURCE_NAMES: Dictionary[StringName, String] = {
	&"inspiration": "灵感", &"raw_data": "原始数据", &"clean_data": "整洁数据",
	&"charts": "图表", &"paper_progress": "论文进度",
}

var topic_id: StringName
var progress: int = 0
var today_progress: int = 0
var settled: bool = false
var settlement: Dictionary = {}

func _init(seed: int = 1) -> void:
	topic_id = TOPIC_IDS[posmod(seed, TOPIC_IDS.size())]

func record_day(day: int, day_result: Dictionary) -> void:
	today_progress = 0
	if settled or day < 1 or day > 3:
		return
	var resource_id: StringName = target_resource()
	for event: Dictionary in day_result.get("events", []):
		var amount: int = int(event.get("deltas", {}).get(resource_id, 0))
		if amount > 0:
			today_progress += amount
	progress += today_progress

func settle(state: RefCounted) -> Dictionary:
	if settled:
		return settlement.duplicate(true)
	settled = true
	var achieved: bool = progress >= target_amount()
	var requested: int = reward_amount() if achieved else 0
	var actual: int = state.change_resource(reward_resource(), requested) if requested > 0 else 0
	settlement = {
		"settled": true,
		"achieved": achieved,
		"requested": requested,
		"actual": actual,
		"overflow": requested - actual,
		"reward_resource": reward_resource(),
	}
	return settlement.duplicate(true)

func snapshot(day: int) -> Dictionary:
	var definition: Dictionary = DEFINITIONS[topic_id]
	var status: StringName = &"active"
	if settled:
		status = &"rewarded" if bool(settlement.get("achieved", false)) else &"missed"
	elif progress >= target_amount():
		status = &"achieved_waiting"
	return {
		"topic_id": topic_id,
		"title": String(definition.title),
		"day": day,
		"resource": target_resource(),
		"resource_name": resource_name(target_resource()),
		"progress": progress,
		"today_progress": today_progress,
		"target": target_amount(),
		"reward_resource": reward_resource(),
		"reward_resource_name": resource_name(reward_resource()),
		"reward": reward_amount(),
		"status": status,
		"settled": settled,
		"settlement": settlement.duplicate(true),
	}

func target_resource() -> StringName:
	return StringName(DEFINITIONS[topic_id].resource)

func target_amount() -> int:
	return int(DEFINITIONS[topic_id].target)

func reward_resource() -> StringName:
	return StringName(DEFINITIONS[topic_id].reward_resource)

func reward_amount() -> int:
	return int(DEFINITIONS[topic_id].reward)

static func resource_name(resource_id: StringName) -> String:
	return RESOURCE_NAMES.get(resource_id, String(resource_id))
