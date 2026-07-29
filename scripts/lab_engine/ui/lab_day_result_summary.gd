class_name LabDayResultSummary
extends RefCounted

const RESOURCE_NAMES: Dictionary[StringName, String] = {
	&"inspiration": "灵感",
	&"raw_data": "原始数据",
	&"clean_data": "整洁数据",
	&"charts": "图表",
	&"paper_progress": "论文进度",
}

const RESOURCE_PRIORITY: Dictionary[StringName, int] = {
	&"inspiration": 1,
	&"raw_data": 2,
	&"clean_data": 3,
	&"charts": 4,
	&"paper_progress": 5,
}

func summarize(result: Dictionary, slot_names: Array[String]) -> PackedStringArray:
	var best_output: Dictionary = {}
	var failure_counts: Dictionary[int, int] = {}
	for event: Dictionary in result.get("events", []):
		if _is_holding_event(event):
			continue
		var slot := int(event.get("slot", -1))
		if not bool(event.get("success", false)):
			failure_counts[slot] = int(failure_counts.get(slot, 0)) + 1
			continue
		for resource_id: StringName in event.get("deltas", {}):
			var amount := int(event.deltas[resource_id])
			if amount <= 0 or not RESOURCE_PRIORITY.has(resource_id):
				continue
			var score := int(RESOURCE_PRIORITY[resource_id]) * 1000 + amount
			if best_output.is_empty() or score > int(best_output.score):
				best_output = {"slot": slot, "resource": resource_id, "amount": amount, "score": score}
	var lines := PackedStringArray()
	if not best_output.is_empty():
		var slot := int(best_output.slot)
		var slot_name := slot_names[slot] if slot >= 0 and slot < slot_names.size() else "生产线"
		lines.append("关键产出：%s带来%s +%d" % [slot_name, RESOURCE_NAMES[best_output.resource], int(best_output.amount)])
	var worst_slot := -1
	var worst_count := 0
	for slot: int in failure_counts:
		var count := int(failure_counts[slot])
		if count > worst_count:
			worst_slot = slot
			worst_count = count
	if worst_slot >= 0:
		var slot_name := slot_names[worst_slot] if worst_slot < slot_names.size() else "生产线"
		lines.append("主要断点：%s空转 %d 次（缺少输入）" % [slot_name, worst_count])
	return lines

func _is_holding_event(event: Dictionary) -> bool:
	return (
		event.has("details")
		and StringName(event.details.get("reason", &"")) == &"awaiting_manual_cashout"
	)
