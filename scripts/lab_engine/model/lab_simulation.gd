class_name LabSimulation
extends RefCounted

enum TriggerType { BASE, OVERCLOCK, AUTOMATIC, END_OF_DAY }

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const SLOT_ORDER := [0, 1, 2, 3, 4, 5]
const DEFAULT_TRIGGER_LIMIT := 12
const GUARDED_TRIGGER_LIMIT := 16

var _cards: Dictionary[StringName, Resource]
var _next_chain_id: int = 1
var _output_totals: Dictionary[int, int] = {}
var _daily_card_triggers: Dictionary[int, int] = {}
var _daily_parameter_batches: Dictionary[int, int] = {}
var _all_nighter_redeemed: bool = false

func _init() -> void:
	_cards = CATALOG_SCRIPT.new().build_cards()

func simulate_day(state: RefCounted, overclock_slot: int = -1) -> Dictionary:
	var start_progress: int = state.paper_progress
	var event_log: Array[Dictionary] = []
	var blocked_events: Array[Dictionary] = []
	var queue: Array[Dictionary] = []
	_output_totals.clear()
	_daily_card_triggers.clear()
	_daily_parameter_batches.clear()
	_all_nighter_redeemed = false
	var trigger_limit: int = trigger_limit_for(state)
	var loop_guard_reduced_debt: bool = false
	var loop_guard_restored_energy: bool = false
	state.automation_locked = state.technical_debt >= 10
	if overclock_slot >= 0 and overclock_slot != state.stopped_slot:
		state.change_resource(&"energy", -1)
		state.change_resource(&"technical_debt", 2)
	for slot: int in SLOT_ORDER:
		if slot == state.stopped_slot:
			continue
		queue.append(_event(slot, TriggerType.BASE, _new_chain_id(), []))
		if slot == overclock_slot:
			queue.append(_event(slot, TriggerType.OVERCLOCK, _new_chain_id(), []))
	var executed: int = 0
	while executed < trigger_limit:
		if queue.is_empty():
			_append_end_of_day_events(state, queue)
			if queue.is_empty():
				break
		var event: Dictionary = queue.pop_front()
		if state.automation_locked and int(event.type) == TriggerType.AUTOMATIC:
			blocked_events.append(event.duplicate(true))
			continue
		var result: Dictionary = _execute_event(state, event)
		executed += 1
		state.total_triggers += 1
		event_log.append(result)
		if bool(result.success):
			_output_totals[int(event.slot)] = int(_output_totals.get(int(event.slot), 0)) + int(result.output_score)
		for child_index: int in range(result.children.size() - 1, -1, -1):
			var child: Dictionary = result.children[child_index]
			if child.is_empty():
				continue
			if state.automation_locked:
				blocked_events.append(child.duplicate(true))
			else:
				queue.push_front(child)
		if _installed_id(state, 5) == &"loop_guard":
			var guard_level: int = int(state.slots[5].level)
			if guard_level >= 2 and executed >= 8 and not loop_guard_restored_energy:
				state.change_resource(&"energy", 1)
				loop_guard_restored_energy = true
			if executed >= 10 and not loop_guard_reduced_debt:
				state.change_resource(&"technical_debt", -2)
				loop_guard_reduced_debt = true
	# Reaching the limit is only a truncation when work really remains.  If the
	# base queue drained on the last allowed trigger, materialize any pending
	# end-of-day work so diagnostics do not report a false positive.
	if executed >= trigger_limit and queue.is_empty():
		_append_end_of_day_events(state, queue)
	var queue_truncated: bool = not queue.is_empty()
	state.change_resource(&"energy", -1)
	if state.technical_debt >= 4 and state.heat >= 3:
		state.change_resource(&"technical_debt", state.heat / 3)
	state.heat = 0
	if state.technical_debt >= 10:
		state.technical_debt = 7
	var daily_progress: int = state.paper_progress - start_progress
	state.highest_daily_progress = maxi(state.highest_daily_progress, daily_progress)
	for event: Dictionary in event_log:
		state.highest_combo = maxi(state.highest_combo, _chain_count(event_log, int(event.chain_id)))
	for slot: int in SLOT_ORDER:
		var entry: Dictionary = state.slots[slot]
		if int(entry.level) > 0:
			entry.days_installed = int(entry.days_installed) + 1
			state.slots[slot] = entry
	return {
		"events": event_log,
		"blocked_events": blocked_events,
		"queue_truncated": queue_truncated,
		"daily_progress": daily_progress,
		"trigger_count": executed,
		"output_totals": _output_totals.duplicate(),
	}

func trigger_limit_for(state: RefCounted) -> int:
	return GUARDED_TRIGGER_LIMIT if _installed_id(state, 5) == &"loop_guard" else DEFAULT_TRIGGER_LIMIT

func _append_end_of_day_events(state: RefCounted, queue: Array[Dictionary]) -> void:
	if bool(_daily_card_triggers.get(-1, false)):
		return
	_daily_card_triggers[-1] = 1
	if _installed_id(state, 1) == &"unattended" and state.energy > 0 and state.stopped_slot != 1:
		queue.append(_event(1, TriggerType.END_OF_DAY, _new_chain_id(), []))
	if _installed_id(state, 5) == &"scheduler":
		queue.append(_event(5, TriggerType.END_OF_DAY, _new_chain_id(), []))

func determine_shutdown(state: RefCounted, seed: int) -> int:
	state.maintenance_prevented_slot = -1
	if state.technical_debt < 7 or state.technical_debt >= 10:
		state.stopped_slot = -1
		return -1
	var candidates: Array[int] = [0, 1, 2, 3, 4]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed + state.day * 7919
	var selected_slot: int = candidates[rng.randi_range(0, candidates.size() - 1)]
	if state.maintenance_ready:
		state.maintenance_ready = false
		state.maintenance_prevented_slot = selected_slot
		state.stopped_slot = -1
		return -1
	state.stopped_slot = selected_slot
	state.had_shutdown = true
	return state.stopped_slot

func _execute_event(state: RefCounted, event: Dictionary) -> Dictionary:
	var slot: int = int(event.slot)
	var entry: Dictionary = state.slots[slot]
	var card_id: StringName = entry.card_id
	var instance_id: int = int(entry.instance_id)
	var level: int = int(entry.level)
	var success: bool = false
	var children: Array[Dictionary] = []
	var deltas: Dictionary[StringName, int] = {}
	var output_score: int = 0
	var card_result: Dictionary = {}
	if card_id == &"":
		success = _execute_default(state, slot, deltas)
		output_score = [2, 4, 4, 5, 6, 1][slot] if success else 0
	else:
		var card: Resource = _cards[card_id]
		var trigger_count: int = int(_daily_card_triggers.get(instance_id, 0))
		if card_id == &"paper_template" and trigger_count >= 3:
			return {"chain_id": event.chain_id, "slot": slot, "type": event.type, "card_id": card_id, "success": false, "failure_reason": &"card_trigger_limit", "deltas": deltas, "output_score": 0, "children": children}
		_daily_card_triggers[instance_id] = trigger_count + 1
		card_result = _execute_card(state, card, level, int(event.type), event)
		success = bool(card_result.success)
		deltas = card_result.deltas
		children = card_result.children
		output_score = card.output_score(level) if success else 0
	if int(event.type) == TriggerType.AUTOMATIC and state.technical_debt >= 4 and state.technical_debt <= 6:
		state.heat += 1
	var event_result := {"chain_id": event.chain_id, "slot": slot, "type": event.type, "card_id": card_id, "success": success, "deltas": deltas, "output_score": output_score, "children": children}
	if card_result.has("details"):
		event_result["details"] = card_result.details
	if not success:
		if card_result.has("failure_reason"):
			event_result["failure_reason"] = card_result.failure_reason
		elif card_result.has("details") and card_result.details.has("reason"):
			event_result["failure_reason"] = card_result.details.reason
		else:
			event_result["failure_reason"] = &"input_shortage"
	return event_result

func _execute_default(state: RefCounted, slot: int, deltas: Dictionary[StringName, int]) -> bool:
	match slot:
		0: _change(state, deltas, &"inspiration", 1); return true
		1:
			if state.inspiration < 1: return false
			_change(state, deltas, &"inspiration", -1); _change(state, deltas, &"raw_data", 2); return true
		2:
			if state.raw_data < 4: return false
			_change(state, deltas, &"raw_data", -4); _change(state, deltas, &"clean_data", 1); return true
		3:
			if state.clean_data < 1: return false
			_change(state, deltas, &"clean_data", -1); _change(state, deltas, &"charts", 1); return true
		4:
			if state.charts < 1: return false
			_change(state, deltas, &"charts", -1); _change(state, deltas, &"paper_progress", 5); return true
		5: _change(state, deltas, &"energy", 1); return true
	return false

func _execute_card(state: RefCounted, card: Resource, level: int, trigger_type: int, event: Dictionary) -> Dictionary:
	var deltas: Dictionary[StringName, int] = {}
	var children: Array[Dictionary] = []
	var success: bool = true
	match int(card.effect):
		0:
			var inspiration_gain: int = 3 if level >= 2 else 2
			if trigger_type == TriggerType.AUTOMATIC:
				inspiration_gain += 1
			_change(state, deltas, &"inspiration", inspiration_gain)
			_change(state, deltas, &"technical_debt", 1)
		1:
			var days: int = int(state.slots[0].days_installed)
			_change(state, deltas, &"inspiration", mini(3, (2 if level >= 2 else 1) + days / 2))
		2:
			if state.inspiration < 1: success = false
			else: _change(state, deltas, &"inspiration", -1); _change(state, deltas, &"raw_data", (3 if trigger_type == TriggerType.AUTOMATIC else 4) + (1 if level >= 2 else 0)); _change(state, deltas, &"technical_debt", 1)
		3:
			if state.inspiration < 2: success = false
			else:
				_change(state, deltas, &"inspiration", -2); _change(state, deltas, &"raw_data", 6 if level >= 2 else 5)
				if trigger_type == TriggerType.END_OF_DAY: _change(state, deltas, &"technical_debt", 2)
		4: success = _process_batches(state, deltas, 3 if level >= 2 else 4, 2, false, level)
		5:
			var converter_batch_size: int = 2 if state.technical_debt >= 7 and state.technical_debt <= 9 else 4
			success = _process_batches(state, deltas, converter_batch_size, 99, true, level)
		6:
			if state.clean_data < 1: success = false
			else: _change(state, deltas, &"clean_data", -1); _change(state, deltas, &"charts", (3 if level >= 2 else 2) + (1 if trigger_type == TriggerType.AUTOMATIC else 0))
		7:
			var instance_id: int = int(state.slots[int(event.slot)].instance_id)
			var batches: int
			if trigger_type == TriggerType.AUTOMATIC:
				batches = int(_daily_parameter_batches.get(instance_id, 0))
			else:
				batches = mini(3, state.clean_data)
			if batches == 0: success = false
			else:
				if trigger_type != TriggerType.AUTOMATIC:
					_change(state, deltas, &"clean_data", -batches)
					_daily_parameter_batches[instance_id] = batches
				_change(state, deltas, &"charts", batches + (batches / 2 if level >= 2 else 0))
				if batches >= 2:
					children.append(_child_event(4, event, card.id))
		8:
			if trigger_type == TriggerType.AUTOMATIC:
				_change(state, deltas, &"paper_progress", 12 if level >= 2 else 10)
			elif state.charts < 1: success = false
			else: _change(state, deltas, &"charts", -1); _change(state, deltas, &"paper_progress", 19 if level >= 2 else 15)
		9:
			if trigger_type != TriggerType.OVERCLOCK:
				return {
					"success": false,
					"deltas": deltas,
					"children": children,
					"details": {
						"reason": &"awaiting_manual_cashout",
						"charts_held": state.charts,
					},
				}
			if _all_nighter_redeemed:
				return {
					"success": false,
					"deltas": deltas,
					"children": children,
					"details": {"reason": &"already_redeemed_today"},
				}
			var required_energy: int = 2
			if state.energy < required_energy:
				return {
					"success": false,
					"deltas": deltas,
					"children": children,
					"details": {
						"reason": &"insufficient_energy",
						"required_energy": required_energy,
						"available_energy": state.energy,
					},
				}
			if state.charts < 1 and state.clean_data < 1:
				return {
					"success": false,
					"deltas": deltas,
					"children": children,
					"details": {"reason": &"no_cashout_resource"},
				}
			else:
				var emergency: bool = state.charts == 0
				var used: int = 1 if emergency else state.charts
				var debt_before: int = state.technical_debt
				var value_per_chart: int = (8 if level >= 2 else 6) + all_nighter_debt_bonus(debt_before)
				_change(state, deltas, &"charts", -state.charts)
				if emergency:
					_change(state, deltas, &"clean_data", -1)
				_change(state, deltas, &"paper_progress", used * value_per_chart)
				_change(state, deltas, &"energy", -2)
				_change(state, deltas, &"technical_debt", -4 if level >= 2 else -3)
				_all_nighter_redeemed = true
				var details: Dictionary = {
					"cashout_kind": &"emergency" if emergency else &"standard",
					"charts_used": used,
					"debt_before": debt_before,
					"value": value_per_chart,
					"value_per_chart": value_per_chart,
					"progress": used * value_per_chart,
					"progress_gained": used * value_per_chart,
					"debt_reduced": debt_before - state.technical_debt,
				}
				if emergency:
					details["clean_used"] = 1
				return {
					"success": true,
					"deltas": deltas,
					"children": children,
					"details": details,
				}
		10:
			if trigger_type != TriggerType.END_OF_DAY:
				return {"success": false, "failure_reason": &"expected_noop", "deltas": deltas, "children": children}
			var targets: Array[int] = _scheduler_targets(state, level)
			if targets.is_empty(): success = false
			else:
				for target: int in targets: children.append(_child_event(target, event, card.id))
				if level < 2:
					_change(state, deltas, &"technical_debt", 1)
				else:
					_change(state, deltas, &"energy", 1)
		11:
			success = true
		_:
			success = false
	return {"success": success, "deltas": deltas, "children": children}

func all_nighter_debt_bonus(technical_debt: int) -> int:
	if technical_debt >= 10:
		return 6
	if technical_debt >= 7:
		return 4
	if technical_debt >= 4:
		return 2
	return 0

func _process_batches(state: RefCounted, deltas: Dictionary[StringName, int], batch_size: int, max_batches: int, legacy: bool, level: int) -> bool:
	var batches: int = mini(max_batches, state.raw_data / batch_size)
	if batches <= 0: return false
	_change(state, deltas, &"raw_data", -batches * batch_size)
	_change(state, deltas, &"clean_data", batches)
	var debt: int = (ceili(batches / 2.0) if legacy and level >= 2 else batches if legacy else 1)
	_change(state, deltas, &"technical_debt", debt)
	return true

func _scheduler_targets(state: RefCounted, level: int) -> Array[int]:
	var candidates: Array[int] = []
	for slot: int in [0, 1, 3, 4]:
		if slot != state.stopped_slot and int(_output_totals.get(slot, 0)) > 0:
			candidates.append(slot)
	candidates.sort_custom(func(left: int, right: int) -> bool:
		var left_score: int = int(_output_totals.get(left, 0))
		var right_score: int = int(_output_totals.get(right, 0))
		return left < right if left_score == right_score else left_score > right_score
	)
	return candidates.slice(0, 2 if level >= 2 else 1)

func _event(slot: int, type: int, chain_id: int, visited: Array) -> Dictionary:
	return {"slot": slot, "type": type, "chain_id": chain_id, "visited": visited.duplicate()}

func _child_event(slot: int, parent: Dictionary, source_id: StringName) -> Dictionary:
	var visited: Array = parent.visited.duplicate()
	var source_slot: int = int(parent.slot)
	var source_instance_id: String = "%s:%s" % [source_slot, source_id]
	if visited.has(source_instance_id): return {}
	visited.append(source_instance_id)
	return _event(slot, TriggerType.AUTOMATIC, int(parent.chain_id), visited)

func _new_chain_id() -> int:
	var value: int = _next_chain_id
	_next_chain_id += 1
	return value

func _change(state: RefCounted, deltas: Dictionary[StringName, int], id: StringName, amount: int) -> void:
	var applied: int = state.change_resource(id, amount)
	deltas[id] = int(deltas.get(id, 0)) + applied

func _installed_id(state: RefCounted, slot: int) -> StringName:
	return state.slots[slot].card_id

func _chain_count(events: Array[Dictionary], chain_id: int) -> int:
	var count: int = 0
	for event: Dictionary in events:
		if int(event.chain_id) == chain_id: count += 1
	return count
