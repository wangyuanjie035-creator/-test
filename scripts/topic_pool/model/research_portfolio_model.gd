extends RefCounted
class_name ResearchPortfolioModel

var slot_capacity: int = 1
var candidates: Array[ResearchTopicCandidate] = []
var active_topics: Array[ResearchTopicCandidate] = []
var archive: Array[Dictionary] = []


func setup(
	candidate_topics: Array[ResearchTopicCandidate],
	initial_slot_capacity: int = 1
) -> bool:
	if candidate_topics.is_empty() or initial_slot_capacity <= 0:
		return false
	slot_capacity = initial_slot_capacity
	candidates = candidate_topics.duplicate()
	active_topics.clear()
	archive.clear()
	return true


func select_candidate(candidate_id: StringName) -> Dictionary:
	if active_topics.size() >= slot_capacity:
		return {"success": false, "reason": &"no_free_slot"}
	var candidate_index: int = _find_candidate_index(candidate_id)
	if candidate_index < 0:
		return {"success": false, "reason": &"candidate_not_found"}
	var selected: ResearchTopicCandidate = candidates.pop_at(candidate_index)
	active_topics.append(selected)
	return {
		"success": true,
		"candidate_id": selected.candidate_id,
		"active_count": active_topics.size(),
		"free_slots": get_free_slot_count(),
	}


func deselect_candidate(candidate_id: StringName) -> Dictionary:
	var active_index: int = _find_active_index(candidate_id)
	if active_index < 0:
		return {"success": false, "reason": &"active_topic_not_found"}
	var deselected: ResearchTopicCandidate = active_topics.pop_at(active_index)
	candidates.append(deselected)
	return {
		"success": true,
		"candidate_id": deselected.candidate_id,
		"active_count": active_topics.size(),
		"free_slots": get_free_slot_count(),
	}


func archive_active_topic(candidate_id: StringName, result: Dictionary) -> Dictionary:
	var active_index: int = _find_active_index(candidate_id)
	if active_index < 0:
		return {"success": false, "reason": &"active_topic_not_found"}
	var topic: ResearchTopicCandidate = active_topics.pop_at(active_index)
	var record: Dictionary = {
		"candidate": topic.to_debug_dict(),
		"result": result.duplicate(true),
	}
	archive.append(record)
	return {
		"success": true,
		"record": record.duplicate(true),
		"free_slots": get_free_slot_count(),
	}


func increase_slot_capacity(amount: int = 1) -> bool:
	if amount <= 0:
		return false
	slot_capacity += amount
	return true


func get_free_slot_count() -> int:
	return maxi(0, slot_capacity - active_topics.size())


func _find_candidate_index(candidate_id: StringName) -> int:
	for index: int in range(candidates.size()):
		if candidates[index].candidate_id == candidate_id:
			return index
	return -1


func _find_active_index(candidate_id: StringName) -> int:
	for index: int in range(active_topics.size()):
		if active_topics[index].candidate_id == candidate_id:
			return index
	return -1
