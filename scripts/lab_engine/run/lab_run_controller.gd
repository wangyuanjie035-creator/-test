class_name LabRunController
extends RefCounted

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const CANDIDATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_candidate_generator.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const SIMULATION_SCRIPT := preload("res://scripts/lab_engine/model/lab_simulation.gd")
const FORECAST_SCRIPT := preload("res://scripts/lab_engine/model/lab_chain_forecast.gd")
const TOPIC_SCRIPT := preload("res://scripts/lab_engine/model/lab_cumulative_topic.gd")

var seed: int
var state: RefCounted
var cards: Dictionary[StringName, Resource]
var schedule: Array
var history: Array[Dictionary] = []
var finished: bool = false
var won: bool = false
var cumulative_topic: RefCounted

var _simulation: RefCounted
var _prepared_day: int = 0

func _init(run_seed: int = 240731) -> void:
	seed = run_seed
	cards = CATALOG_SCRIPT.new().build_cards()
	state = STATE_SCRIPT.new()
	_simulation = SIMULATION_SCRIPT.new()
	schedule = CANDIDATE_SCRIPT.new().generate_schedule(cards, seed)
	cumulative_topic = TOPIC_SCRIPT.new(seed)

func candidates_for_today() -> Array[StringName]:
	if finished or state.day < 1 or state.day > schedule.size():
		return []
	return schedule[state.day - 1].duplicate()

func begin_day() -> Dictionary:
	if finished:
		return {"valid": false, "reason": "run_finished"}
	var topic_just_settled: bool = _prepare_live_day()
	if state.energy <= 0:
		return {"valid": true, "forced_rest": true, "stopped_slot": -1, "candidates": [], "topic": topic_snapshot(), "topic_just_settled": topic_just_settled}
	return {
		"valid": true,
		"forced_rest": false,
		"stopped_slot": state.stopped_slot,
		"maintenance_prevented_slot": state.maintenance_prevented_slot,
		"candidates": candidates_for_today(),
		"topic": topic_snapshot(),
		"topic_just_settled": topic_just_settled,
	}

func topic_snapshot() -> Dictionary:
	return cumulative_topic.snapshot(state.day)

func _prepare_live_day() -> bool:
	if _prepared_day != state.day:
		_simulation.determine_shutdown(state, seed)
		_prepared_day = state.day
	if state.day == 4 and not cumulative_topic.settled:
		cumulative_topic.settle(state)
		return true
	return false

func forecast_all_nighter(
		pending_card_id: StringName = &"",
		overclock_slot: int = -1,
		skip_debt_reduction: bool = false
) -> Dictionary:
	var forecast_state: RefCounted = state.duplicate_run()
	if skip_debt_reduction:
		forecast_state.change_resource(&"technical_debt", -1)
	if pending_card_id != &"":
		forecast_state.install(cards[pending_card_id])
	if StringName(forecast_state.slots[4].card_id) != &"all_nighter":
		return {"available": false, "reason": &"not_installed", "risk_reason": &"not_installed"}
	var comparison_context: Dictionary = {
		"day": int(forecast_state.day),
		"charts_held": int(forecast_state.charts),
		"paper_before": int(forecast_state.paper_progress),
		"writing_stopped_today": int(forecast_state.stopped_slot) == 4,
	}
	var simulation: RefCounted = SIMULATION_SCRIPT.new()
	var result: Dictionary = simulation.simulate_day(forecast_state, overclock_slot)
	var successful_events: Array[Dictionary] = []
	for event: Dictionary in result.events:
		if StringName(event.card_id) == &"all_nighter" and bool(event.success) and event.has("details"):
			successful_events.append(event.details)
	if successful_events.is_empty():
		var reason: StringName = &"stopped" if state.stopped_slot == 4 else &"holding" if overclock_slot != 4 else _all_nighter_redemption_failure(result)
		return {
			"available": false,
			"reason": reason,
			"risk_reason": reason,
			"charts_held": forecast_state.charts,
			"day_end_debt": forecast_state.technical_debt,
			"day_end_energy": forecast_state.energy,
			"automation_locked": forecast_state.automation_locked,
		}
	var charts_used: int = 0
	var progress_gained: int = 0
	for details: Dictionary in successful_events:
		charts_used += int(details.charts_used)
		progress_gained += int(details.progress_gained)
	comparison_context.merge({
		"day_end_debt": int(forecast_state.technical_debt),
		"charts_used": charts_used,
		"progress_gained": progress_gained,
	})
	return {
		"available": true,
		"cashout_kind": StringName(successful_events[0].cashout_kind),
		"charts_used": charts_used,
		"value_per_chart": int(successful_events[0].value_per_chart),
		"progress_gained": progress_gained,
		"debt_before": int(successful_events[0].debt_before),
		"day_end_debt": forecast_state.technical_debt,
		"day_end_energy": forecast_state.energy,
		"automation_locked": forecast_state.automation_locked,
		"value_comparison": build_all_nighter_value_comparison(successful_events[0], comparison_context),
	}

static func build_all_nighter_value_comparison(details: Dictionary, context: Dictionary) -> Dictionary:
	var event_time_debt: int = int(details.get("debt_before", 0))
	var current_bonus: int = _all_nighter_bonus_for_debt(event_time_debt)
	var current_value: int = int(details.get("value_per_chart", details.get("value", 0)))
	var charts_used: int = int(context.get("charts_used", details.get("charts_used", 0)))
	var current_total: int = int(context.get("progress_gained", details.get("progress_gained", charts_used * current_value)))
	var paper_before: int = int(context.get("paper_before", 0))
	var next_tier_debt: int = _next_all_nighter_tier_debt(event_time_debt)
	var at_highest_tier: bool = event_time_debt >= 10
	var next_bonus: int = _all_nighter_bonus_for_debt(next_tier_debt)
	var next_value: int = current_value - current_bonus + next_bonus
	var hypothetical_total: int = charts_used * next_value
	var day_end_debt: int = int(context.get("day_end_debt", event_time_debt))
	return {
		"day": int(context.get("day", 1)),
		"charts_held": int(context.get("charts_held", 0)),
		"paper_before": paper_before,
		"cashout_kind": StringName(details.get("cashout_kind", &"standard")),
		"event_time_debt": event_time_debt,
		"current_tier_floor": _all_nighter_tier_floor(event_time_debt),
		"current_bonus_per_chart": current_bonus,
		"current_value_per_chart": current_value,
		"current_charts_used": charts_used,
		"current_total_value": current_total,
		"paper_after": paper_before + current_total,
		"immediate_win": paper_before + current_total >= 100,
		"next_tier_debt": next_tier_debt,
		"debt_to_next_tier": maxi(0, next_tier_debt - event_time_debt),
		"next_tier_bonus": next_bonus,
		"value": next_value,
		"same_inventory_hypothetical_total": hypothetical_total,
		"delta": hypothetical_total - current_total,
		"at_highest_tier": at_highest_tier,
		"is_final_day": int(context.get("day", 1)) == 8,
		"writing_stopped_today": bool(context.get("writing_stopped_today", false)),
		"day_end_debt": day_end_debt,
		"next_day_shutdown_band": _shutdown_band_for_debt(day_end_debt),
	}

static func _all_nighter_tier_floor(debt: int) -> int:
	if debt >= 10:
		return 10
	if debt >= 7:
		return 7
	if debt >= 4:
		return 4
	return 0

static func _next_all_nighter_tier_debt(debt: int) -> int:
	for threshold: int in [4, 7, 10]:
		if debt < threshold:
			return threshold
	return 10

static func _all_nighter_bonus_for_debt(debt: int) -> int:
	if debt >= 10:
		return 6
	if debt >= 7:
		return 4
	if debt >= 4:
		return 2
	return 0

static func _shutdown_band_for_debt(debt: int) -> StringName:
	if debt >= 10:
		return &"automation_lock"
	if debt >= 7:
		return &"shutdown"
	return &"safe"

func forecast_day(choice_index: int = -1, overclock_slot: int = -1) -> Dictionary:
	if finished:
		return {"valid": false, "reason": &"run_finished"}
	if state.energy <= 0:
		return {"valid": true, "forced_rest": true, "nodes": [], "has_chain": false, "automatic_count": 0, "risk_reason": &"", "risk_slot": -1, "queue_truncated": false, "daily_progress": 0, "trigger_count": 0}
	if _prepared_day != state.day:
		return {"valid": false, "reason": &"day_not_prepared"}
	var choices: Array[StringName] = candidates_for_today()
	if choice_index < -2 or choice_index >= choices.size():
		return {"valid": false, "reason": &"invalid_choice"}
	var forecast_state: RefCounted = state.duplicate_run()
	if overclock_slot < -1 or overclock_slot > 4 or (overclock_slot >= 0 and overclock_slot == forecast_state.stopped_slot):
		return {"valid": false, "reason": &"invalid_overclock", "overclock_slot": overclock_slot, "stopped_slot": forecast_state.stopped_slot}
	var selected_id: StringName = &""
	var action: String = "baseline"
	var resolution: Dictionary = _resolve_day_on(forecast_state, choice_index, choices, overclock_slot)
	selected_id = resolution.selected_id
	action = resolution.action
	var debt_before_simulation: int = resolution.debt_before_simulation
	var result: Dictionary = resolution.result
	var summary: Dictionary = FORECAST_SCRIPT.new().summarize(result)
	var redemption: Dictionary = _redemption_summary(result, forecast_state)
	if not redemption.is_empty():
		summary["redemption"] = redemption
	if overclock_slot >= 0 and debt_before_simulation < 10 and debt_before_simulation + 2 >= 10:
		summary.risk_reason = &"overclock_debt_lock"
		summary.risk_slot = int(result.get("blocked_events", [{}])[0].get("slot", -1)) if not result.get("blocked_events", []).is_empty() else -1
	elif state.stopped_slot >= 0:
		summary.risk_reason = &"shutdown"
		summary.risk_slot = state.stopped_slot
	summary.merge({
		"valid": true,
		"forced_rest": false,
		"choice_index": choice_index,
		"selected_id": selected_id,
		"action": action,
		"overclock_slot": overclock_slot,
		"stopped_slot": forecast_state.stopped_slot,
		"day_end_debt": forecast_state.technical_debt,
		"day_end_energy": forecast_state.energy,
	})
	return summary

func _redemption_summary(result: Dictionary, forecast_state: RefCounted) -> Dictionary:
	for event: Dictionary in result.get("events", []):
		if StringName(event.get("card_id", &"")) != &"all_nighter" or not bool(event.get("success", false)):
			continue
		var details: Dictionary = event.get("details", {})
		if not details.has("charts_used"):
			continue
		return {
			"cashout_kind": StringName(details.cashout_kind),
			"charts_used": int(details.charts_used),
			"value_per_chart": int(details.value_per_chart),
			"progress_gained": int(details.progress_gained),
			"day_end_debt": int(forecast_state.technical_debt),
			"day_end_energy": int(forecast_state.energy),
			"automation_locked": bool(forecast_state.automation_locked),
		}
	return {}

func play_day(choice_index: int = -1, overclock_slot: int = -1) -> Dictionary:
	if finished:
		return {"valid": false, "reason": "run_finished"}
	if state.energy <= 0:
		return _resolve_forced_rest()
	_prepare_live_day()
	var prepared_state: RefCounted = state.duplicate_run()
	var prepared_stopped_slot: int = prepared_state.stopped_slot
	var prepared_prevented_slot: int = prepared_state.maintenance_prevented_slot
	var validation_state: RefCounted = prepared_state.duplicate_run()
	var progress_before: int = state.paper_progress
	var choices: Array[StringName] = candidates_for_today()
	if choice_index < -1 or choice_index >= choices.size():
		return {"valid": false, "reason": "invalid_choice"}
	var invalid_overclock: bool = overclock_slot < -1 or overclock_slot > 4
	if overclock_slot >= 0 and overclock_slot == validation_state.stopped_slot:
		invalid_overclock = true
	if invalid_overclock:
		return {
			"valid": false,
			"reason": "invalid_overclock",
			"overclock_slot": overclock_slot,
			"stopped_slot": validation_state.stopped_slot,
		}
	var dry_run: Dictionary = _resolve_day_on(validation_state, choice_index, choices, overclock_slot)
	if _requires_all_nighter_redemption(validation_state, overclock_slot):
		var redemption_failure: StringName = _all_nighter_redemption_failure(dry_run.result)
		if redemption_failure != &"":
			return {"valid": false, "reason": redemption_failure}
	var live_resolution: Dictionary = _resolve_day_on(state, choice_index, choices, overclock_slot)
	var action: String = live_resolution.action
	var selected_id: StringName = live_resolution.selected_id
	var result: Dictionary = live_resolution.result
	result.merge({
		"valid": true,
		"day": state.day,
		"choice_index": choice_index,
		"selected_id": selected_id,
		"action": action,
		"overclock_slot": overclock_slot,
		"forced_rest": false,
		"stopped_slot": prepared_stopped_slot,
		"maintenance_prevented_slot": prepared_prevented_slot,
		"progress_before": progress_before,
		"progress_after": state.paper_progress,
	})
	cumulative_topic.record_day(state.day, result)
	result["topic"] = topic_snapshot()
	_finish_day(result)
	return result

func _resolve_day_on(target_state: RefCounted, choice_index: int, choices: Array[StringName], overclock_slot: int) -> Dictionary:
	var action: String = "skip"
	var selected_id: StringName = &""
	if choice_index == -2:
		action = "baseline"
	elif choice_index == -1:
		target_state.change_resource(&"technical_debt", -1)
		if not target_state.maintenance_ready:
			target_state.maintenance_ready = true
			action = "maintenance"
	else:
		selected_id = choices[choice_index]
		action = target_state.install(cards[selected_id])
	var debt_before_simulation: int = target_state.technical_debt
	return {
		"action": action,
		"selected_id": selected_id,
		"debt_before_simulation": debt_before_simulation,
		"result": SIMULATION_SCRIPT.new().simulate_day(target_state, overclock_slot),
	}

func _requires_all_nighter_redemption(target_state: RefCounted, overclock_slot: int) -> bool:
	return overclock_slot == 4 and StringName(target_state.slots[4].card_id) == &"all_nighter"

func _all_nighter_redemption_failure(result: Dictionary) -> StringName:
	for event: Dictionary in result.get("events", []):
		if int(event.get("slot", -1)) != 4 or int(event.get("type", -1)) != 1 or StringName(event.get("card_id", &"")) != &"all_nighter":
			continue
		if bool(event.get("success", false)):
			return &""
		return StringName(event.get("failure_reason", event.get("details", {}).get("reason", &"cashout_failed")))
	return &"cashout_not_resolved"
func _resolve_forced_rest() -> Dictionary:
	var progress_before: int = state.paper_progress
	state.energy = 3
	state.stopped_slot = -1
	var result: Dictionary = {
		"valid": true,
		"day": state.day,
		"choice_index": -1,
		"selected_id": &"",
		"action": "forced_rest",
		"overclock_slot": -1,
		"forced_rest": true,
		"events": [],
		"daily_progress": 0,
		"trigger_count": 0,
		"stopped_slot": -1,
		"maintenance_prevented_slot": -1,
		"progress_before": progress_before,
		"progress_after": state.paper_progress,
	}
	cumulative_topic.record_day(state.day, result)
	result["topic"] = topic_snapshot()
	_finish_day(result)
	return result

func _finish_day(result: Dictionary) -> void:
	history.append(result)
	if state.paper_progress >= 100:
		finished = true
		won = true
	elif state.day >= 8:
		finished = true
		won = false
	else:
		state.day += 1
