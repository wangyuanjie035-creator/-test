extends RefCounted

const MODE_PRECISION: StringName = &"precision"
const MODE_AGGRESSIVE: StringName = &"aggressive"
const PRODUCTIVE_SLOTS: int = 5
const PRECISION_INSPIRATION_COST: int = 2
const PRECISION_ENERGY_COST: int = 1
const AGGRESSIVE_DEBT_COST: int = 3

var _settled: bool = false
var _result: Dictionary = {}

func eligible_slots(state: RefCounted) -> Array[int]:
	var result: Array[int] = []
	for slot: int in range(PRODUCTIVE_SLOTS):
		var entry: Dictionary = state.slots.get(slot, {})
		if StringName(entry.get("card_id", &"")) != &"" and int(entry.get("level", 0)) == 1:
			result.append(slot)
	return result

func can_apply(state: RefCounted, slot: int, mode: StringName) -> bool:
	if _settled or not eligible_slots(state).has(slot):
		return false
	match mode:
		MODE_PRECISION:
			# Leave at least one energy so renovation cannot silently force a rest day.
			return state.inspiration >= PRECISION_INSPIRATION_COST and state.energy > PRECISION_ENERGY_COST
		MODE_AGGRESSIVE:
			# The full price must fit; clamping at ten must never discount the cost.
			return state.technical_debt <= 10 - AGGRESSIVE_DEBT_COST
		_:
			return false

func apply(state: RefCounted, slot: int, mode: StringName) -> Dictionary:
	if _settled:
		return _result.duplicate(true)
	if not can_apply(state, slot, mode):
		return {"applied": false, "slot": slot, "mode": mode, "reason": &"invalid_choice"}

	var entry: Dictionary = state.slots[slot].duplicate(true)
	var deltas: Dictionary[StringName, int] = {}
	match mode:
		MODE_PRECISION:
			deltas[&"inspiration"] = state.change_resource(&"inspiration", -PRECISION_INSPIRATION_COST)
			deltas[&"energy"] = state.change_resource(&"energy", -PRECISION_ENERGY_COST)
		MODE_AGGRESSIVE:
			deltas[&"technical_debt"] = state.change_resource(&"technical_debt", AGGRESSIVE_DEBT_COST)
		_:
			return {"applied": false, "slot": slot, "mode": mode, "reason": &"unknown_mode"}

	entry["level"] = 2
	state.slots[slot] = entry
	_settled = true
	_result = {
		"applied": true,
		"slot": slot,
		"mode": mode,
		"card_id": StringName(entry.card_id),
		"instance_id": int(entry.instance_id),
		"deltas": deltas,
		"was_stopped": state.stopped_slot == slot,
	}
	return _result.duplicate(true)

func skip() -> Dictionary:
	if _settled:
		return _result.duplicate(true)
	_settled = true
	_result = {"applied": false, "reason": &"skipped"}
	return _result.duplicate(true)
