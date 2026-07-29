class_name LabChainForecastView
extends PanelContainer

var _summary: Label

func _ready() -> void:
	name = "ChainForecast"
	custom_minimum_size.y = 44.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color("162b35")
	style.border_color = Color("315463")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	add_theme_stylebox_override("panel", style)

	_summary = Label.new()
	_summary.name = "ForecastLabel"
	_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_summary.add_theme_font_size_override("font_size", 13)
	_summary.add_theme_color_override("font_color", Color("c8dce5"))
	add_child(_summary)
	show_forecast({})

func set_interaction_enabled(_enabled: bool) -> void:
	# The forecast is informational; day interaction is owned by the sidebar and slots.
	pass

func clear_and_hide() -> void:
	_summary.text = ""
	visible = false

func show_forecast(forecast: Dictionary, slot_names: Array[String] = []) -> void:
	if _summary == null:
		return
	visible = true
	var nodes: Array = forecast.get("nodes", [])
	var node_names: Array[String] = []
	for raw_slot: Variant in nodes.slice(0, 4):
		var slot := int(raw_slot)
		if slot >= 0 and slot < slot_names.size():
			node_names.append(slot_names[slot])
	var has_chain := bool(forecast.get("has_chain", not node_names.is_empty()))
	var first_line := "预计主链：%s" % " → ".join(node_names) if has_chain and not node_names.is_empty() else "预计主链：暂无可触发链路"
	if bool(forecast.get("queue_truncated", false)):
		first_line += " …"
	var redemption: Dictionary = forecast.get("redemption", {})
	var second_line := _redemption_text(redemption) if not redemption.is_empty() else _ordinary_summary_text(forecast)
	var risk_reason := StringName(forecast.get("risk_reason", &""))
	if risk_reason != &"" and redemption.is_empty():
		second_line += "｜首断：%s" % _risk_text(risk_reason, int(forecast.get("risk_slot", -1)), slot_names)
	_summary.text = first_line + "\n" + second_line

func _ordinary_summary_text(forecast: Dictionary) -> String:
	return "预计论文 %+d｜日末债 %d｜精力 %d｜自动 %d 次" % [
		int(forecast.get("daily_progress", 0)),
		int(forecast.get("day_end_debt", 0)),
		int(forecast.get("day_end_energy", 0)),
		int(forecast.get("automatic_count", 0)),
	]

func _redemption_text(redemption: Dictionary) -> String:
	var kind := StringName(redemption.get("cashout_kind", &"standard"))
	var unit_value := int(redemption.get("value_per_chart", 0))
	var gained := int(redemption.get("progress_gained", 0))
	var arithmetic := "整洁-1 → 临时图1 × %d = +%d" % [unit_value, gained] if kind == &"emergency" else "%d 图 × %d = +%d" % [int(redemption.get("charts_used", 0)), unit_value, gained]
	var lock_text := "｜债10锁：本日自动触发取消" if bool(redemption.get("automation_locked", false)) else ""
	return "兑现 %s｜日末债 %d｜精力 %d%s" % [arithmetic, int(redemption.get("day_end_debt", 0)), int(redemption.get("day_end_energy", 0)), lock_text]

func show_value_comparison(forecast: Dictionary) -> void:
	if _summary == null:
		return
	visible = true
	if not bool(forecast.get("available", false)):
		_summary.text = "通宵兑现不可用\n%s" % _unavailable_reason_text(StringName(forecast.get("reason", &"unknown")))
		return
	var comparison: Dictionary = forecast.get("value_comparison", {})
	if comparison.is_empty():
		_summary.text = "通宵兑现预判\n同样图数静态比较，不保证未来收益"
		return
	_summary.text = _value_comparison_lines(comparison)

func _value_comparison_lines(comparison: Dictionary) -> String:
	var used := int(comparison.get("current_charts_used", 0))
	var current := int(comparison.get("current_total_value", 0))
	var before := int(comparison.get("paper_before", 0))
	var after := int(comparison.get("paper_after", before + current))
	var resource := "应急临时1图｜" if StringName(comparison.get("cashout_kind", &"standard")) == &"emergency" else "%d图｜" % used
	var status: String
	if bool(comparison.get("immediate_win", false)):
		status = "可立即完成：%s当前兑现 +%d，论文 %d→%d" % [resource, current, before, after]
	elif bool(comparison.get("is_final_day", false)):
		status = "第8天兑现：%s当前 +%d，论文 %d→%d" % [resource, current, before, after]
	elif bool(comparison.get("at_highest_tier", false)):
		status = "已到最高档：%s当前兑现 +%d" % [resource, current]
	else:
		status = "距债%d还差%d：%s当前 +%d；同样图数该档 +%d（多+%d）" % [int(comparison.get("next_tier_debt", 0)), int(comparison.get("debt_to_next_tier", 0)), resource, current, int(comparison.get("same_inventory_hypothetical_total", current)), int(comparison.get("delta", 0))]
	var risk := "同样图数静态比较，不保证未来收益"
	if bool(comparison.get("writing_stopped_today", false)):
		risk = "风险：写作台今日停机，无法兑现"
	else:
		var end_debt := int(comparison.get("day_end_debt", 0))
		if end_debt >= 7 and end_debt <= 9:
			risk = "风险：日末债%d，次日进入停机区" % end_debt
	return status + "\n" + risk

func _unavailable_reason_text(reason: StringName) -> String:
	match reason:
		&"not_installed": return "尚未安装通宵拼稿"
		&"holding": return "未超频写作台，本日只保留图表"
		&"stopped": return "写作台今日停机，无法兑现"
		&"insufficient_energy": return "精力不足，无法完成兑现"
		&"no_cashout_resource": return "没有库存图表；应急临时1图还需要1份整洁数据"
		_: return "当前无法兑现（%s）" % String(reason)

func _risk_text(reason: StringName, slot: int, slot_names: Array[String]) -> String:
	var slot_name := slot_names[slot] if slot >= 0 and slot < slot_names.size() else "生产线"
	match reason:
		&"input_shortage", &"input_starved", &"insufficient_input", &"missing_input": return "%s输入不足" % slot_name
		&"stopped", &"shutdown": return "%s停机" % slot_name
		&"automation_locked", &"locked": return "%s自动化未解锁" % slot_name
		&"overclock_debt_lock": return "超频使技术债达到10，%s自动触发取消" % slot_name
		&"queue_limit", &"queue_truncated": return "预测队列已截断"
		_: return "%s%s" % [slot_name, String(reason)]
