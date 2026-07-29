extends "res://tests/lab_engine/lab_test_case.gd"

const PLAYBACK_SCRIPT := preload("res://scripts/lab_engine/ui/lab_day_playback.gd")
const CASHOUT_FEEDBACK_SCRIPT := preload("res://scripts/lab_engine/ui/lab_cashout_feedback.gd")
const FORECAST_VIEW_SCRIPT := preload("res://scripts/lab_engine/ui/lab_chain_forecast_view.gd")

func run() -> Array[String]:
	var playback: Node = PLAYBACK_SCRIPT.new()
	var emergency: Dictionary = playback.cashout_feedback_spec(_cashout_event(true, &"emergency", -1, 24))
	check_equal(emergency.get("kind"), &"emergency", "emergency cashout must select causal feedback")
	check_equal(emergency.get("progress_gained"), 24, "emergency feedback must use event-time progress details")
	var standard: Dictionary = playback.cashout_feedback_spec(_cashout_event(true, &"standard", -2, 16))
	check_equal(standard.get("kind"), &"standard", "standard cashout must select restrained feedback")
	check_equal(standard.get("charts_used"), 2, "standard feedback must use event-time chart details")
	var failed: Dictionary = playback.cashout_feedback_spec(_cashout_event(false, &"emergency", 0, 0, &"no_cashout_resource"))
	check_equal(failed.get("kind"), &"failure", "rejected cashout must not select benefit feedback")
	check(String(failed.get("message", "")).contains("失败") and not String(failed.get("message", "")).contains("+"), "rejected copy must contain no benefit token")
	var held: Dictionary = _cashout_event(false, &"standard", 0, 0, &"awaiting_manual_cashout")
	held.details["charts_held"] = 2
	check(playback.cashout_feedback_spec(held).is_empty(), "holding events must retain the normal restrained holding cue")
	check(CASHOUT_FEEDBACK_SCRIPT.EMERGENCY_TOTAL_DURATION <= 1.4, "emergency feedback duration budget must remain at most 1.4 seconds")
	check(CASHOUT_FEEDBACK_SCRIPT.EMERGENCY_FINAL_SEGMENT_DURATION >= 0.5, "emergency arithmetic segment must remain readable for at least 0.5 seconds")
	var forecast_view: PanelContainer = FORECAST_VIEW_SCRIPT.new()
	var standard_text: String = forecast_view._redemption_text({"cashout_kind": &"standard", "charts_used": 3, "value_per_chart": 10, "progress_gained": 30})
	check(standard_text.contains("3 图 × 10 = +30"), "standard forecast must expose one exact arithmetic line")
	var emergency_text: String = forecast_view._redemption_text({"cashout_kind": &"emergency", "charts_used": 1, "value_per_chart": 10, "progress_gained": 10})
	check(emergency_text.contains("整洁-1 → 临时图1 × 10 = +10"), "emergency forecast must expose resource causality and exact arithmetic")
	var ordinary_text: String = forecast_view._ordinary_summary_text({"daily_progress": 5, "automatic_count": 2, "day_end_debt": 7, "day_end_energy": 4})
	check(ordinary_text.contains("预计论文 +5"), "ordinary forecast must expose expected paper progress")
	check(ordinary_text.contains("日末债 7"), "ordinary forecast must expose end-of-day debt")
	check(ordinary_text.contains("精力 4"), "ordinary forecast must expose end-of-day energy")
	_test_value_comparison_copy(forecast_view)
	forecast_view.free()
	playback.free()
	return failures

func _test_value_comparison_copy(view: PanelContainer) -> void:
	var base := {
		"current_charts_used": 2, "current_total_value": 20, "paper_before": 60, "paper_after": 80,
		"cashout_kind": &"standard", "next_tier_debt": 7, "debt_to_next_tier": 1,
		"same_inventory_hypothetical_total": 24, "delta": 4, "day_end_debt": 6,
	}
	var next_tier: String = view._value_comparison_lines(base)
	check(next_tier.contains("距债7还差1") and next_tier.contains("同样图数该档 +24（多+4）"), "comparison must show the next-tier static value")
	check(next_tier.contains("同样图数静态比较，不保证未来收益") and next_tier.count("\n") == 1, "comparison must remain two lines and carry the non-promise disclaimer")
	var highest := base.duplicate()
	highest["at_highest_tier"] = true
	check(view._value_comparison_lines(highest).begins_with("已到最高档"), "highest-tier status must outrank next-tier copy")
	var final_day := highest.duplicate()
	final_day["is_final_day"] = true
	check(view._value_comparison_lines(final_day).begins_with("第8天兑现"), "day-eight status must outrank highest-tier copy")
	var immediate := final_day.duplicate()
	immediate["immediate_win"] = true
	check(view._value_comparison_lines(immediate).begins_with("可立即完成"), "immediate win must be the highest-priority status")
	var emergency := base.duplicate()
	emergency["cashout_kind"] = &"emergency"
	emergency["current_charts_used"] = 1
	emergency["day_end_debt"] = 8
	var emergency_copy: String = view._value_comparison_lines(emergency)
	check(emergency_copy.contains("应急临时1图") and emergency_copy.contains("日末债8"), "emergency comparison must name its temporary chart and shutdown-band risk")
	check(view._unavailable_reason_text(&"no_cashout_resource").contains("整洁数据"), "unavailable comparison must expose a Chinese resource reason")

func _cashout_event(success: bool, kind: StringName, chart_delta: int, progress: int, reason: StringName = &"") -> Dictionary:
	var details: Dictionary = {
		"cashout_kind": kind,
		"charts_used": absi(chart_delta),
		"progress_gained": progress,
	}
	if reason != &"":
		details["reason"] = reason
	return {
		"chain_id": 1,
		"slot": 4,
		"type": 1,
		"card_id": &"all_nighter",
		"success": success,
		"deltas": {&"charts": chart_delta, &"paper_progress": progress},
		"details": details,
	}
