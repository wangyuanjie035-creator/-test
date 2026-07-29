class_name LabResultAnalyzer
extends RefCounted

const SLOT_NAMES: Array[String] = ["文献台", "实验台", "数据台", "分析台", "写作台", "休息区"]
const BREAKTHROUGH_PROGRESS: int = 20
const LOW_ENTRY_PROGRESS: int = 70

func analyze(state: RefCounted, history: Array[Dictionary]) -> Dictionary:
	var gap: int = maxi(0, 100 - int(state.paper_progress))
	var last_day: Dictionary = history.back() if not history.is_empty() else {}
	var daily_progress: int = int(last_day.get("daily_progress", 0))
	var progress_after: int = int(last_day.get("progress_after", state.paper_progress))
	var progress_before: int = int(last_day.get("progress_before", progress_after - daily_progress))
	var stopped_slot: int = _latest_real_shutdown(history)
	var cashout_failure: StringName = _last_cashout_failure(last_day)
	var cause: String
	var advice: String
	if cashout_failure != &"":
		cause = _cashout_failure_cause(cashout_failure)
		advice = _cashout_failure_advice(cashout_failure)
	elif daily_progress >= BREAKTHROUGH_PROGRESS and progress_before < LOW_ENTRY_PROGRESS:
		cause = "最后一天虽爆发，但入日仅有 %d 进度；主要问题是前期积累不足。" % progress_before
		advice = "下局前 4 天优先让生产链稳定产出，并在中期至少完成一次写作兑现。"
	elif stopped_slot >= 0:
		cause = "真实停机发生在%s，生产链因此丢失了关键产能。" % _slot_name(stopped_slot)
		advice = "技术债进入 7 以上前安排维护，并减少无必要的超频。"
	elif int(state.energy) <= 0:
		cause = "精力耗尽，关键回合无法完整运转生产链。"
		advice = "保留至少 1 点精力余量，避免连续超频导致被迫休息。"
	elif int(state.raw_data) >= 4 and int(state.clean_data) == 0:
		cause = "原始数据堆积，清洗能力没有跟上产出。"
		advice = "优先升级数据台，或减少继续制造原始数据的操作。"
	elif int(state.clean_data) > 0 and int(state.charts) == 0:
		cause = "整洁数据没有及时转化成图表。"
		advice = "下一局中期优先保障分析台在线并获得至少 1 张图表。"
	elif int(state.charts) > 0:
		cause = "已有图表未能在 DDL 前充分写入论文。"
		advice = "最后两天前准备写作兑现，并为写作台保留一次超频机会。"
	else:
		cause = "生产链形成闭环过晚，前期资源未转化为论文进度。"
		advice = "先打通灵感→实验→数据→图表→写作，再考虑扩大单点产能。"
	return {
		"title": "距离目标还差 %d" % gap,
		"last_day_line": "最后日 +%d（%d → %d）" % [daily_progress, progress_before, progress_after],
		"cause": cause,
		"advice": advice,
		"stopped_slot": stopped_slot,
	}

func _last_cashout_failure(last_day: Dictionary) -> StringName:
	for event_value: Variant in last_day.get("events", []):
		var event: Dictionary = event_value
		if StringName(event.get("card_id", &"")) != &"all_nighter" or bool(event.get("success", false)):
			continue
		var reason := StringName(event.get("failure_reason", event.get("details", {}).get("reason", &"")))
		if reason in [&"no_cashout_resource", &"insufficient_energy"]:
			return reason
	return &""

func _cashout_failure_cause(reason: StringName) -> String:
	match reason:
		&"no_cashout_resource": return "最后日兑现时没有库存图表，也没有整洁数据生成临时图，写作台未能转化论文进度。"
		&"insufficient_energy": return "最后日兑现时精力不足，通宵写作未能启动。"
		_: return "最后日应急补图条件不满足，兑现未能启动。"

func _cashout_failure_advice(reason: StringName) -> String:
	match reason:
		&"no_cashout_resource": return "提前生产库存图表；若需应急补图，则预留 1 整洁数据与足够精力。"
		&"insufficient_energy": return "兑现前保留足够的日初精力，避免此前连续超频。"
		_: return "提前准备库存图表，或补齐应急补图所需的整洁数据与精力。"

func analyze_victory(state: RefCounted, history: Array[Dictionary]) -> Dictionary:
	var last_day: Dictionary = history.back() if not history.is_empty() else {}
	var daily_progress: int = int(last_day.get("daily_progress", 0))
	var day_number: int = int(last_day.get("day", history.size()))
	var progress_after: int = int(last_day.get("progress_after", state.paper_progress))
	var progress_before: int = int(last_day.get("progress_before", progress_after - daily_progress))
	var cashout: Dictionary = _successful_last_day_cashout(last_day)
	var maintenance_slot: int = int(last_day.get("maintenance_prevented_slot", -1))
	return {
		"last_day_line": "第 %d 天 +%d（%d → %d）" % [day_number, daily_progress, progress_before, progress_after],
		"cashout_line": _cashout_line(cashout),
		"maintenance_line": "维护保障：%s免于停机" % _slot_name(maintenance_slot) if maintenance_slot >= 0 else "",
		"has_cashout": not cashout.is_empty(),
	}

func _successful_last_day_cashout(last_day: Dictionary) -> Dictionary:
	for event_value: Variant in last_day.get("events", []):
		var event: Dictionary = event_value
		if bool(event.get("success", false)) and StringName(event.get("card_id", &"")) == &"all_nighter":
			var details: Dictionary = event.get("details", {})
			if int(details.get("charts_used", 0)) > 0:
				return details
	return {}

func _cashout_line(cashout: Dictionary) -> String:
	if cashout.is_empty():
		return ""
	var kind: StringName = StringName(cashout.get("cashout_kind", &"standard"))
	var mode_text: String = "应急补图" if kind == &"emergency" else "通宵兑现"
	return "%s：%d 图 × %d = 论文 +%d" % [
		mode_text,
		int(cashout.get("charts_used", 0)),
		int(cashout.get("value_per_chart", 0)),
		int(cashout.get("progress_gained", 0)),
	]

func _latest_real_shutdown(history: Array[Dictionary]) -> int:
	for index: int in range(history.size() - 1, -1, -1):
		var stopped_slot: int = int(history[index].get("stopped_slot", -1))
		if stopped_slot >= 0:
			return stopped_slot
	return -1

func _slot_name(slot: int) -> String:
	return SLOT_NAMES[slot] if slot >= 0 and slot < SLOT_NAMES.size() else "未知工位"
