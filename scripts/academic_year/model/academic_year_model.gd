extends RefCounted
class_name AcademicYearModel

const MAX_CYCLES := 3
const MAX_PRESSURE := 5

var seed: int = 1
var cycle_index: int = 0
var carried_pressure: int = 0
var accepted_papers: int = 0
var excellent_papers: int = 0
var failed_submissions: int = 0
var withdrawals: int = 0
var total_prestige: int = 0
var route_counts: Dictionary[StringName, int] = {
	&"single": 0,
	&"synergy": 0,
	&"conflict": 0,
}
var windows: Array[ResearchWindowDefinition] = []
var cycle_history: Array[Dictionary] = []
var active_legacy: Dictionary = {}
var _cycle_recorded: bool = false


func setup(run_seed: int, window_definitions: Array[ResearchWindowDefinition]) -> bool:
	if window_definitions.size() != MAX_CYCLES:
		push_error("AcademicYearModel requires exactly three research windows.")
		return false
	for definition: ResearchWindowDefinition in window_definitions:
		if definition == null or not definition.is_valid_definition():
			push_error("AcademicYearModel received an invalid research window.")
			return false
	seed = maxi(1, run_seed)
	cycle_index = 0
	carried_pressure = 0
	accepted_papers = 0
	excellent_papers = 0
	failed_submissions = 0
	withdrawals = 0
	total_prestige = 0
	route_counts = {
		&"single": 0,
		&"synergy": 0,
		&"conflict": 0,
	}
	windows = window_definitions.duplicate()
	cycle_history.clear()
	active_legacy.clear()
	_cycle_recorded = false
	return true


func get_current_window() -> ResearchWindowDefinition:
	if is_finished():
		return null
	return windows[cycle_index]


func get_cycle_start_pressure() -> int:
	var window := get_current_window()
	if window == null:
		return carried_pressure
	return mini(MAX_PRESSURE, carried_pressure + window.pressure_on_entry)


func add_transition_pressure(amount: int) -> int:
	carried_pressure = clampi(carried_pressure + maxi(0, amount), 0, MAX_PRESSURE)
	return carried_pressure


func get_growth_rank() -> int:
	return clampi(cycle_index, 0, 2)


func get_topic_slot_capacity() -> int:
	return 1 if get_growth_rank() == 0 else 2


func record_cycle_result(result: Dictionary, final_pressure: int) -> Dictionary:
	if is_finished():
		return {"success": false, "reason": &"year_finished"}
	if _cycle_recorded:
		return {"success": false, "reason": &"cycle_already_recorded"}
	if not bool(result.get("success", false)):
		return {"success": false, "reason": &"invalid_cycle_result"}
	var grade: StringName = StringName(result.get("grade", &""))
	if grade not in [&"pass", &"excellent", &"failed", &"withdrawn"]:
		return {"success": false, "reason": &"invalid_grade"}
	var route_id: StringName = StringName(result.get("route_id", &"single"))
	if route_id not in [&"single", &"synergy", &"conflict"]:
		return {"success": false, "reason": &"invalid_route"}

	var window := get_current_window()
	var prestige_gained: int = 0
	match grade:
		&"pass":
			accepted_papers += 1
			prestige_gained = window.prestige
		&"excellent":
			accepted_papers += 1
			excellent_papers += 1
			prestige_gained = window.prestige + 1
		&"failed":
			failed_submissions += 1
		&"withdrawn":
			withdrawals += 1
	if grade == &"pass" or grade == &"excellent":
		if route_id == &"synergy":
			prestige_gained += 1
		elif route_id == &"conflict":
			prestige_gained += 2
	total_prestige += prestige_gained
	route_counts[route_id] = route_counts.get(route_id, 0) + 1

	carried_pressure = _calculate_next_pressure(final_pressure, grade)
	if route_id == &"single":
		carried_pressure = maxi(0, carried_pressure - 1)
	active_legacy = Dictionary(result.get("legacy", {})).duplicate(true)
	var record := {
		"cycle": cycle_index + 1,
		"window_id": window.id,
		"window_name": window.display_name,
		"grade": grade,
		"route_id": route_id,
		"ending_pressure": clampi(final_pressure, 0, MAX_PRESSURE),
		"next_pressure": carried_pressure,
		"prestige_gained": prestige_gained,
		"legacy": active_legacy.duplicate(true),
	}
	cycle_history.append(record)
	_cycle_recorded = true
	return {"success": true, "record": record.duplicate(true)}


func advance_cycle() -> Dictionary:
	if is_finished():
		return {"success": false, "reason": &"year_finished"}
	if not _cycle_recorded:
		return {"success": false, "reason": &"cycle_not_recorded"}
	cycle_index += 1
	_cycle_recorded = false
	return {
		"success": true,
		"year_finished": is_finished(),
		"cycle": cycle_index + 1,
		"carried_pressure": carried_pressure,
		"legacy": active_legacy.duplicate(true),
	}


func is_finished() -> bool:
	return cycle_index >= MAX_CYCLES


func get_year_ending() -> Dictionary:
	if not is_finished():
		return {"ready": false, "reason": &"year_in_progress"}
	var ending_id: StringName
	var title: String
	if accepted_papers == 0:
		ending_id = &"unfinished_foundation"
		title = "尚未发表，但留下了研究档案"
	elif carried_pressure >= 4:
		ending_id = &"costly_progress"
		title = "成果到手，代价仍在累积"
	elif excellent_papers >= 1 and accepted_papers >= 2:
		ending_id = &"breakthrough_year"
		title = "形成了自己的研究方向"
	else:
		ending_id = &"steady_year"
		title = "站稳脚跟的一学年"
	return {
		"ready": true,
		"id": ending_id,
		"title": title,
		"accepted_papers": accepted_papers,
		"excellent_papers": excellent_papers,
		"failed_submissions": failed_submissions,
		"withdrawals": withdrawals,
		"prestige": total_prestige,
		"ending_pressure": carried_pressure,
		"route_id": _get_dominant_route(),
		"route_title": _get_route_title(_get_dominant_route()),
		"route_summary": _get_route_summary(_get_dominant_route()),
		"route_counts": route_counts.duplicate(true),
		"history": cycle_history.duplicate(true),
	}


func _calculate_next_pressure(final_pressure: int, grade: StringName) -> int:
	var bounded := clampi(final_pressure, 0, MAX_PRESSURE)
	match grade:
		&"excellent":
			return maxi(0, bounded - 2)
		&"pass":
			return maxi(0, bounded - 1)
		&"withdrawn":
			return maxi(0, bounded - 2)
		&"failed":
			return mini(MAX_PRESSURE, bounded + 1)
		_:
			return bounded


func _get_dominant_route() -> StringName:
	var dominant: StringName = &"single"
	var highest: int = -1
	var highest_count: int = 0
	for route_id: StringName in [&"single", &"synergy", &"conflict"]:
		var count: int = route_counts.get(route_id, 0)
		if count > highest:
			highest = count
			dominant = route_id
			highest_count = 1
		elif count == highest:
			highest_count += 1
	if highest_count > 1:
		return &"mixed"
	return dominant


func _get_route_title(route_id: StringName) -> String:
	match route_id:
		&"single":
			return "专注型研究者"
		&"synergy":
			return "协同型研究者"
		&"conflict":
			return "高压并行研究者"
		&"mixed":
			return "多元探索型研究者"
		_:
			return "尚在寻找方向"


func _get_route_summary(route_id: StringName) -> String:
	match route_id:
		&"single":
			return "你多次集中资源解决一个问题，用更低的压力换取稳定积累。"
		&"synergy":
			return "你善于寻找课题间的共同方法，让一份证据服务于多条研究线。"
		&"conflict":
			return "你承担了并行方向的注意力成本，并用更高风险争取更大影响。"
		&"mixed":
			return "你在专注、协同与冒险之间切换，尚未定型，但建立了更宽的研究视野。"
		_:
			return "这一年的选择尚未形成稳定的研究风格。"
