class_name LabChainForecast
extends RefCounted

const MAX_NODES: int = 4
const AUTOMATIC_TYPE: int = 2

func summarize(result: Dictionary) -> Dictionary:
	var events: Array = result.get("events", [])
	var blocked_events: Array = result.get("blocked_events", [])
	var main_chain: Array[Dictionary] = _select_main_chain(events, blocked_events)
	var nodes: Array[int] = []
	var automatic_count: int = 0
	for value: Variant in main_chain:
		var event: Dictionary = value
		if nodes.size() < MAX_NODES:
			nodes.append(int(event.get("slot", -1)))
		if int(event.get("type", -1)) == AUTOMATIC_TYPE and not bool(event.get("blocked", false)):
			automatic_count += 1
	var risk: Dictionary = _primary_risk(result)
	return {
		"nodes": nodes,
		"has_chain": not nodes.is_empty(),
		"automatic_count": automatic_count,
		"queue_truncated": bool(result.get("queue_truncated", false)),
		"risk_reason": StringName(risk.get("reason", &"")),
		"risk_slot": int(risk.get("slot", -1)),
		"daily_progress": int(result.get("daily_progress", 0)),
		"trigger_count": int(result.get("trigger_count", 0)),
	}

func _select_main_chain(events: Array, blocked_events: Array) -> Array[Dictionary]:
	var chains: Dictionary = {}
	var chain_order: Array[int] = []
	for raw_event: Variant in events:
		_append_to_chain(chains, chain_order, raw_event, false)
	for raw_event: Variant in blocked_events:
		_append_to_chain(chains, chain_order, raw_event, true)
	var best_chain: Array[Dictionary] = []
	var best_score: Array[int] = [-1, -1, -1, -1]
	for chain_id: int in chain_order:
		var chain: Array[Dictionary] = chains[chain_id]
		var paper_progress: int = 0
		var automatic_events: int = 0
		for event: Dictionary in chain:
			paper_progress += int(event.get("deltas", {}).get(&"paper_progress", 0))
			if int(event.get("type", -1)) == AUTOMATIC_TYPE:
				automatic_events += 1
		# A forecast exists to expose causality. Prefer a real automatic edge
		# (including a blocked one) over an unrelated high-output base event.
		var score: Array[int] = [int(automatic_events > 0), paper_progress, automatic_events, chain.size()]
		if _score_is_better(score, best_score):
			best_score = score
			best_chain = chain
	return best_chain

func _append_to_chain(chains: Dictionary, chain_order: Array[int], raw_event: Variant, blocked: bool) -> void:
	var event: Dictionary = (raw_event as Dictionary).duplicate(true)
	var chain_id: int = int(event.get("chain_id", -1))
	if not chains.has(chain_id):
		chains[chain_id] = [] as Array[Dictionary]
		chain_order.append(chain_id)
	event["blocked"] = blocked
	var chain: Array[Dictionary] = chains[chain_id]
	chain.append(event)
	chains[chain_id] = chain

func _score_is_better(left: Array[int], right: Array[int]) -> bool:
	for index: int in range(left.size()):
		if left[index] != right[index]:
			return left[index] > right[index]
	return false

func _primary_risk(result: Dictionary) -> Dictionary:
	if bool(result.get("queue_truncated", false)):
		return {"reason": &"queue_truncated"}
	var blocked_events: Array = result.get("blocked_events", [])
	if not blocked_events.is_empty():
		return {"reason": &"automation_locked", "slot": int(blocked_events[0].get("slot", -1))}
	for value: Variant in result.get("events", []):
		var event: Dictionary = value
		if not bool(event.get("success", false)) and StringName(event.get("failure_reason", &"")) == &"input_shortage":
			return {"reason": &"input_shortage", "slot": int(event.get("slot", -1))}
	return {}
