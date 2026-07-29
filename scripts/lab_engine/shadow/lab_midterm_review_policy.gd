extends RefCounted

const REVIEW_IDS: Array[StringName] = [
	&"literature_briefing",
	&"raw_data_audit",
	&"chart_preview",
	&"process_safety",
]

const DEFINITIONS: Dictionary[StringName, Dictionary] = {
	&"literature_briefing": {
		"cost": {&"inspiration": 3},
		"reward": {&"paper_progress": 10, &"energy": 1},
		"maintenance": false,
	},
	&"raw_data_audit": {
		"cost": {&"raw_data": 8},
		"reward": {&"clean_data": 2},
		"maintenance": true,
	},
	&"chart_preview": {
		"cost": {&"charts": 2},
		"reward": {&"paper_progress": 18, &"technical_debt": -1},
		"maintenance": false,
	},
	&"process_safety": {
		"cost": {&"clean_data": 2},
		"reward": {&"technical_debt": -3},
		"maintenance": true,
	},
}

func review_for_seed(seed: int) -> StringName:
	var index: int = posmod(seed, REVIEW_IDS.size())
	return REVIEW_IDS[index]

func can_submit(state: RefCounted, review_id: StringName) -> bool:
	if not DEFINITIONS.has(review_id):
		return false
	var definition: Dictionary = DEFINITIONS[review_id]
	var costs: Dictionary = definition.get("cost", {})
	for resource_id: StringName in costs:
		if int(state.get(resource_id)) < int(costs[resource_id]):
			return false
	return true

func apply_submission(state: RefCounted, review_id: StringName) -> Dictionary:
	if not can_submit(state, review_id):
		return {"applied": false, "review_id": review_id, "reason": &"insufficient_resources"}
	var definition: Dictionary = DEFINITIONS[review_id]
	var deltas: Dictionary[StringName, int] = {}
	var costs: Dictionary = definition.get("cost", {})
	for resource_id: StringName in costs:
		deltas[resource_id] = state.change_resource(resource_id, -int(costs[resource_id]))
	var rewards: Dictionary = definition.get("reward", {})
	for resource_id: StringName in rewards:
		deltas[resource_id] = int(deltas.get(resource_id, 0)) + state.change_resource(resource_id, int(rewards[resource_id]))
	var maintenance_granted: bool = bool(definition.get("maintenance", false)) and not state.maintenance_ready
	if bool(definition.get("maintenance", false)):
		state.maintenance_ready = true
	return {
		"applied": true,
		"review_id": review_id,
		"deltas": deltas,
		"maintenance_granted": maintenance_granted,
	}
