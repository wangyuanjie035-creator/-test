extends RefCounted

const DIRECTIONS: Array[StringName] = [&"theory", &"empirical", &"engineering"]

func apply_day(state: RefCounted, direction: StringName, result: Dictionary) -> Dictionary:
	match direction:
		&"theory":
			if _positive_output(result, &"inspiration") > 0 and _positive_output(result, &"paper_progress") > 0:
				return _apply(state, direction, &"paper_progress", 5, &"insight_to_writing")
		&"empirical":
			if _positive_output(result, &"clean_data") > 0:
				return _apply(state, direction, &"clean_data", 1, &"cleaning_yield")
		&"engineering":
			if _automatic_count(result) >= 2:
				return _apply(state, direction, &"technical_debt", -1, &"automation_stability")
	return {"applied": false, "direction": direction, "actual": 0, "reason": &"condition_not_met"}

func _apply(state: RefCounted, direction: StringName, resource_id: StringName, amount: int, reason: StringName) -> Dictionary:
	var actual: int = state.change_resource(resource_id, amount)
	return {"applied": true, "direction": direction, "resource": resource_id, "requested": amount, "actual": actual, "reason": reason}

func _positive_output(result: Dictionary, resource_id: StringName) -> int:
	var total: int = 0
	for event: Dictionary in result.get("events", []):
		total += maxi(0, int(event.get("deltas", {}).get(resource_id, 0)))
	return total

func _automatic_count(result: Dictionary) -> int:
	var count: int = 0
	for event: Dictionary in result.get("events", []):
		if int(event.get("type", -1)) == 2 and bool(event.get("success", false)):
			count += 1
	return count
