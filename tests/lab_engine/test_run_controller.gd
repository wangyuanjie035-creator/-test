extends "res://tests/lab_engine/lab_test_case.gd"

const CONTROLLER_SCRIPT := preload("res://scripts/lab_engine/run/lab_run_controller.gd")
const FORECAST_SCRIPT := preload("res://scripts/lab_engine/model/lab_chain_forecast.gd")

func run() -> Array[String]:
	_test_skip_reduces_debt_and_advances_day()
	_test_invalid_choice_does_not_advance()
	_test_stopped_slot_cannot_be_overclocked()
	_test_overclock_costs()
	_test_all_nighter_forecast_is_accurate_and_side_effect_free()
	_test_all_nighter_value_comparison_debt_tiers()
	_test_all_nighter_value_comparison_terminal_states()
	_test_all_nighter_value_comparison_is_pure()
	_test_emergency_cashout_forecast_matches_play()
	_test_selected_cashout_is_atomic_when_event_energy_is_insufficient()
	_test_selected_cashout_accepts_clean_data_when_upstream_preserves_it()
	_test_day_forecast_matches_play_and_is_side_effect_free()
	_test_day_forecast_reports_input_starvation()
	_test_day_forecast_accepts_baseline()
	_test_day_forecast_exposes_redemption_summary()
	_test_forced_rest()
	_test_success_and_day_eight_failure()
	_test_history_preserves_prepared_shutdown_diagnosis()
	return failures

func _test_history_preserves_prepared_shutdown_diagnosis() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.technical_debt = 7
	var preview: Dictionary = controller.begin_day()
	var stopped_slot: int = int(preview.stopped_slot)
	var prevented_slot: int = int(preview.maintenance_prevented_slot)
	var progress_before: int = controller.state.paper_progress
	var result: Dictionary = controller.play_day(-1, -1)
	check_equal(result.stopped_slot, stopped_slot, "history result must preserve the prepared stopped slot")
	check_equal(result.maintenance_prevented_slot, prevented_slot, "history result must preserve the prepared maintenance-prevented slot")
	check_equal(result.progress_before, progress_before, "history result must preserve start-of-day progress")
	check_equal(result.progress_after, controller.state.paper_progress, "history result must preserve end-of-day progress")
	check_equal(controller.history.back(), result, "controller history must retain the complete diagnostic record")

func _test_skip_reduces_debt_and_advances_day() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.technical_debt = 3
	controller.begin_day()
	var result: Dictionary = controller.play_day(-1, -1)
	check(result.valid, "skip must be a valid action")
	check_equal(result.action, "maintenance", "negative-one choice must resolve as maintenance")
	check_equal(controller.state.technical_debt, 2, "maintenance must reduce debt by one")
	check(controller.state.maintenance_ready, "maintenance must bank one shutdown guarantee")
	check_equal(controller.state.day, 2, "valid day must advance the run")
	controller.state.technical_debt = 1
	var second_result: Dictionary = controller.play_day(-1, -1)
	check(second_result.valid, "maintenance with a banked guarantee must remain valid")
	check_equal(controller.state.technical_debt, 0, "maintenance debt reduction must clamp at zero")
	check(controller.state.maintenance_ready, "repeated maintenance must not remove or stack the banked guarantee")

func _test_invalid_choice_does_not_advance() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	var result: Dictionary = controller.play_day(3, -1)
	check(not bool(result.valid), "out-of-range choice must fail")
	check_equal(result.reason, "invalid_choice", "invalid choice must report a stable reason")
	check_equal(controller.state.day, 1, "invalid choice must not advance the run")

func _test_stopped_slot_cannot_be_overclocked() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.technical_debt = 7
	var preview: Dictionary = controller.begin_day()
	var stopped_slot: int = int(preview.stopped_slot)
	var result: Dictionary = controller.play_day(-1, stopped_slot)
	check(not bool(result.valid), "stopped slot overclock must fail")
	check_equal(result.reason, "invalid_overclock", "stopped slot must report invalid overclock")
	check_equal(controller.state.day, 1, "invalid overclock must not advance the run")

func _test_forced_rest() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.energy = 0
	var preview: Dictionary = controller.begin_day()
	check(bool(preview.forced_rest), "zero energy must preview forced rest")
	var result: Dictionary = controller.play_day()
	check(bool(result.forced_rest), "zero energy day must resolve as forced rest")
	check_equal(controller.state.energy, 3, "forced rest must restore three energy")
	check_equal(controller.state.day, 2, "forced rest must consume one day")

func _test_overclock_costs() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.begin_day()
	var result: Dictionary = controller.play_day(-1, 0)
	check(result.valid, "available production slot must accept overclock")
	check_equal(result.overclock_slot, 0, "result must retain selected overclock slot")
	check_equal(controller.state.technical_debt, 2, "overclock must add two technical debt")
	check_equal(controller.state.energy, 7, "overclock must impose one additional energy cost")

func _test_all_nighter_forecast_is_accurate_and_side_effect_free() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.install(controller.cards[&"all_nighter"])
	controller.state.charts = 1
	controller.state.technical_debt = 8
	var before: Dictionary = controller.state.snapshot()
	var forecast: Dictionary = controller.forecast_all_nighter(&"", 4)
	check(bool(forecast.available), "installed all-nighter with charts must produce a forecast")
	check_equal(forecast.value_per_chart, 12, "forecast must include overclock debt crossing into tier ten")
	check_equal(forecast.progress_gained, 12, "forecast must show the exact redemption progress")
	check_equal(forecast.day_end_debt, 7, "forecast must show debt after redemption")
	check_equal(forecast.day_end_energy, 5, "forecast must include overclock, card, rest, and day energy effects")
	check(bool(forecast.automation_locked), "forecast must warn that debt-ten automation lock persists")
	var comparison: Dictionary = forecast.get("value_comparison", {})
	check_equal(comparison.event_time_debt, 10, "comparison must use the simulated event-time debt")
	check_equal(comparison.current_tier_floor, 10, "comparison must identify the highest debt tier")
	check_equal(comparison.current_bonus_per_chart, 6, "comparison must expose the current tier bonus")
	check_equal(comparison.current_total_value, 12, "comparison must preserve the real simulated total")
	check_equal(comparison.next_day_shutdown_band, &"shutdown", "comparison must classify settled day-end debt")
	check_equal(controller.state.snapshot(), before, "forecast must not mutate the live run state")
	controller.state.technical_debt = 4
	controller.state.charts = 1
	var holding_forecast: Dictionary = controller.forecast_all_nighter()
	check_equal(holding_forecast.reason, &"holding", "unselected writing overclock must explicitly forecast holding")
	check_equal(holding_forecast.charts_held, 1, "holding forecast must retain the chart inventory")
	controller.state.technical_debt = 4
	var skip_forecast: Dictionary = controller.forecast_all_nighter(&"", 4, true)
	check_equal(skip_forecast.value_per_chart, 8, "skip then overclock must price redemption after skip reduction and overclock prepayment")
	check_equal(skip_forecast.debt_before, 5, "maintenance forecast must expose the event-time debt used by real execution")
	controller.state.stopped_slot = 4
	var stopped: Dictionary = controller.forecast_all_nighter()
	check(not bool(stopped.available), "stopped writing slot must not forecast a redemption")
	check_equal(stopped.reason, "stopped", "stopped writing slot must explain why redemption is unavailable")
	check_equal(stopped.risk_reason, &"stopped", "blocked forecast must expose its risk reason")
	check(not stopped.has("value_comparison"), "blocked forecast must not invent a value comparison")

func _test_all_nighter_value_comparison_debt_tiers() -> void:
	var cases: Array[Dictionary] = [
		{"debt": 0, "floor": 0, "bonus": 0, "next": 4, "distance": 4, "next_bonus": 2, "value": 8, "delta": 4},
		{"debt": 4, "floor": 4, "bonus": 2, "next": 7, "distance": 3, "next_bonus": 4, "value": 10, "delta": 4},
		{"debt": 7, "floor": 7, "bonus": 4, "next": 10, "distance": 3, "next_bonus": 6, "value": 12, "delta": 4},
		{"debt": 10, "floor": 10, "bonus": 6, "next": 10, "distance": 0, "next_bonus": 6, "value": 12, "delta": 0},
	]
	for case: Dictionary in cases:
		var current_value: int = 6 + int(case.bonus)
		var details: Dictionary = {
			"cashout_kind": &"standard",
			"charts_used": 2,
			"debt_before": int(case.debt),
			"value_per_chart": current_value,
			"progress_gained": current_value * 2,
		}
		var comparison: Dictionary = CONTROLLER_SCRIPT.build_all_nighter_value_comparison(details, {
			"day": 3, "charts_held": 2, "paper_before": 20,
			"charts_used": 2, "progress_gained": current_value * 2, "day_end_debt": 3,
		})
		check_equal(comparison.current_tier_floor, int(case.floor), "comparison must map the current debt tier floor")
		check_equal(comparison.current_bonus_per_chart, int(case.bonus), "comparison must map the current debt bonus")
		check_equal(comparison.next_tier_debt, int(case.next), "comparison must map the next debt threshold")
		check_equal(comparison.debt_to_next_tier, int(case.distance), "comparison must report debt distance to the next tier")
		check_equal(comparison.next_tier_bonus, int(case.next_bonus), "comparison must map the next tier bonus")
		check_equal(comparison.value, int(case.value), "comparison must expose next-tier unit value")
		check_equal(comparison.delta, int(case.delta), "comparison must compare the same chart inventory")
		check_equal(comparison.at_highest_tier, int(case.debt) >= 10, "comparison must identify the highest tier")

func _test_all_nighter_value_comparison_terminal_states() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.install(controller.cards[&"all_nighter"])
	controller.state.day = 8
	controller.state.paper_progress = 90
	controller.state.charts = 0
	controller.state.clean_data = 1
	controller.state.technical_debt = 5
	controller.state.stopped_slot = 3
	var forecast: Dictionary = controller.forecast_all_nighter(&"", 4)
	var comparison: Dictionary = forecast.get("value_comparison", {})
	check_equal(comparison.cashout_kind, &"emergency", "comparison must retain emergency cashout causality")
	check_equal(comparison.charts_held, 0, "emergency comparison must report zero held charts")
	check_equal(comparison.current_charts_used, 1, "emergency comparison must count its temporary chart")
	check_equal(comparison.paper_before, 90, "comparison must expose paper before the simulated cashout")
	check_equal(comparison.paper_after, 100, "comparison must expose paper after the real value is applied")
	check(bool(comparison.immediate_win), "comparison must identify an immediate win")
	check(bool(comparison.is_final_day), "comparison must identify day eight")

func _test_all_nighter_value_comparison_is_pure() -> void:
	var details: Dictionary = {"cashout_kind": &"standard", "charts_used": 3, "debt_before": 7, "value_per_chart": 10, "progress_gained": 30}
	var context: Dictionary = {"day": 5, "charts_held": 3, "paper_before": 40, "charts_used": 3, "progress_gained": 30, "day_end_debt": 4, "writing_stopped_today": false}
	var details_before: Dictionary = details.duplicate(true)
	var context_before: Dictionary = context.duplicate(true)
	var first: Dictionary = CONTROLLER_SCRIPT.build_all_nighter_value_comparison(details, context)
	var second: Dictionary = CONTROLLER_SCRIPT.build_all_nighter_value_comparison(details, context)
	check_equal(first, second, "value comparison builder must be deterministic and stateless")
	check_equal(details, details_before, "value comparison builder must not mutate event details")
	check_equal(context, context_before, "value comparison builder must not mutate context")

func _test_emergency_cashout_forecast_matches_play() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.install(controller.cards[&"all_nighter"])
	controller.state.charts = 0
	controller.state.clean_data = 1
	controller.state.technical_debt = 5
	controller.begin_day()
	controller.state.stopped_slot = 3
	var before: Dictionary = controller.state.snapshot()
	var forecast: Dictionary = controller.forecast_day(-1, 4)
	var redemption: Dictionary = forecast.get("redemption", {})
	check_equal(redemption.cashout_kind, &"emergency", "forecast must identify emergency cashout")
	check_equal(redemption.charts_used, 1, "emergency forecast must include exactly one temporary chart")
	check_equal(redemption.progress_gained, 8, "emergency forecast must use the normal unit value")
	check_equal(controller.state.snapshot(), before, "emergency forecast must not mutate live state")
	var played: Dictionary = controller.play_day(-1, 4)
	var played_redemption: Dictionary = controller._redemption_summary(played, controller.state)
	check_equal(played_redemption, redemption, "emergency forecast and play must resolve identical redemption details")
	check_equal(controller.state.clean_data, 0, "emergency play must consume one clean data")
	check_equal(controller.state.charts, 0, "emergency play must not write its temporary chart to inventory")
	var rejected: RefCounted = CONTROLLER_SCRIPT.new(240731)
	rejected.state.install(rejected.cards[&"all_nighter"])
	rejected.begin_day()
	var rejected_result: Dictionary = rejected.play_day(-1, 4)
	check_equal(rejected_result.reason, &"no_cashout_resource", "cashout without either resource must be rejected")
	check_equal(rejected.state.day, 1, "rejected cashout must not consume a day")

func _test_selected_cashout_is_atomic_when_event_energy_is_insufficient() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.install(controller.cards[&"all_nighter"])
	controller.state.clean_data = 1
	controller.state.charts = 0
	controller.state.energy = 2
	controller.begin_day()
	controller.state.stopped_slot = 3
	var before: Dictionary = controller.state.snapshot()
	var result: Dictionary = controller.play_day(-1, 4)
	check(not bool(result.valid), "cashout must reject when overclock prepayment leaves insufficient event energy")
	check_equal(result.reason, &"insufficient_energy", "atomic rejection must expose the event-time failure")
	check_equal(controller.state.snapshot(), before, "rejected selected cashout must preserve the complete live snapshot")
	check(controller.history.is_empty(), "rejected selected cashout must not append history")

func _test_selected_cashout_accepts_clean_data_when_upstream_preserves_it() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.install(controller.cards[&"all_nighter"])
	controller.state.clean_data = 1
	controller.state.energy = 4
	controller.begin_day()
	controller.state.stopped_slot = 3
	var result: Dictionary = controller.play_day(-1, 4)
	check(bool(result.valid), "emergency cashout must succeed when upstream preserves clean data")
	check_equal(controller.state.day, 2, "successful selected cashout must advance exactly one day")
	check_equal(controller.history.size(), 1, "successful selected cashout must append exactly one history entry")

func _test_success_and_day_eight_failure() -> void:
	var winning: RefCounted = CONTROLLER_SCRIPT.new(240731)
	winning.state.paper_progress = 99
	winning.state.charts = 1
	winning.begin_day()
	winning.play_day(-1, -1)
	check(winning.finished and winning.won, "paper threshold reached during settlement must win")
	check(winning.state.paper_progress > 100, "winning settlement must finish the complete production queue")
	var failing: RefCounted = CONTROLLER_SCRIPT.new(240731)
	failing.state.day = 8
	failing.begin_day()
	failing.play_day(-1, -1)
	check(failing.finished and not failing.won, "day eight below target must end in failure")

func _test_day_forecast_matches_play_and_is_side_effect_free() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.begin_day()
	var before: Dictionary = controller.state.snapshot()
	var forecast: Dictionary = controller.forecast_day(-1, 0)
	check_equal(controller.state.snapshot(), before, "day forecast must never mutate live state")
	var played: Dictionary = controller.play_day(-1, 0)
	var played_summary: Dictionary = FORECAST_SCRIPT.new().summarize(played)
	check_equal(forecast.nodes, played_summary.nodes, "forecast and play must share the same core event fingerprint")
	check_equal(forecast.automatic_count, played_summary.automatic_count, "forecast and play must agree on automatic trigger count")
	check_equal(forecast.queue_truncated, played_summary.queue_truncated, "forecast and play must agree on queue truncation")
	check_equal(forecast.daily_progress, played_summary.daily_progress, "forecast and play must agree on progress")
	check_equal(forecast.day_end_debt, controller.state.technical_debt, "forecast must expose the simulated day-end debt")
	check_equal(forecast.day_end_energy, controller.state.energy, "forecast must expose the simulated day-end energy")
	check(forecast.nodes.size() <= 4, "forecast DTO must contain at most four nodes")

func _test_day_forecast_reports_input_starvation() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.begin_day()
	var forecast: Dictionary = controller.forecast_day(-1, -1)
	check_equal(forecast.risk_reason, &"input_shortage", "an empty pipeline must report its first input-starved slot")
	check_equal(int(forecast.risk_slot), 2, "input-starvation risk must identify the first blocked production slot")

func _test_day_forecast_accepts_baseline() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	var unprepared: Dictionary = controller.forecast_day(-2, -1)
	check_equal(unprepared.reason, &"day_not_prepared", "forecast API must not prepare or mutate a live day implicitly")
	controller.begin_day()
	var before: Dictionary = controller.state.snapshot()
	var forecast: Dictionary = controller.forecast_day(-2, -1)
	check(bool(forecast.valid), "baseline forecast must be accepted before choosing a daily action")
	check_equal(forecast.action, "baseline", "baseline forecast must not apply maintenance or a candidate")
	check_equal(controller.state.day, 1, "one-time forecast preparation must not advance the day")
	check_equal(controller.state.snapshot(), before, "baseline forecast must not mutate any prepared live-state field")

func _test_day_forecast_exposes_redemption_summary() -> void:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	controller.state.install(controller.cards[&"all_nighter"])
	controller.state.charts = 2
	controller.state.technical_debt = 8
	controller.begin_day()
	var forecast: Dictionary = controller.forecast_day(-2, 4)
	var redemption: Dictionary = forecast.get("redemption", {})
	check_equal(redemption.cashout_kind, &"standard", "inventory redemption must be identified as standard cashout")
	check_equal(redemption.charts_used, 2, "day forecast must expose redeemed chart count")
	check_equal(redemption.value_per_chart, 12, "day forecast must expose event-time value per chart")
	check_equal(redemption.progress_gained, 24, "day forecast must expose exact redemption progress")
	check_equal(redemption.day_end_debt, 7, "day forecast must expose end-of-day debt")
	check_equal(redemption.day_end_energy, 5, "day forecast must expose end-of-day energy")
	check(bool(redemption.automation_locked), "day forecast must expose the debt-ten automation lock")
	check_equal(forecast.risk_reason, &"overclock_debt_lock", "debt-ten lock must outrank ordinary input shortages")
