extends "res://tests/lab_engine/lab_test_case.gd"

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const SIMULATION_SCRIPT := preload("res://scripts/lab_engine/model/lab_simulation.gd")

func run() -> Array[String]:
	_test_debt_ten_lock_and_recovery()
	_test_automation_unlocks_on_following_day()
	_test_shutdown_thresholds()
	_test_loop_guard_trigger_limit()
	_test_queue_cap_and_chain()
	_test_all_nighter_debt_redemption()
	_test_all_nighter_energy_thresholds_are_event_atomic()
	_test_level_two_paper_template_value()
	_test_converter_high_debt_batch_size()
	_test_diagnostics_are_reported()
	return failures

func _test_debt_ten_lock_and_recovery() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.change_resource(&"technical_debt", 10)
	var result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(state)
	check(state.reached_debt_ten, "reaching debt ten must be remembered")
	check(state.automation_locked, "debt ten must lock automation for the full day")
	check_equal(state.technical_debt, 7, "debt ten must recover to seven at day end")
	check(int(result.trigger_count) <= 12, "locked day must still respect default trigger cap")

func _test_shutdown_thresholds() -> void:
	var simulation: RefCounted = SIMULATION_SCRIPT.new()
	var state: RefCounted = STATE_SCRIPT.new()
	state.technical_debt = 6
	check_equal(simulation.determine_shutdown(state, 99), -1, "debt below seven must not shut a slot")
	state.technical_debt = 7
	var stopped: int = simulation.determine_shutdown(state, 99)
	check(stopped >= 0 and stopped <= 4, "debt seven to nine must stop a production slot")
	check(state.had_shutdown, "shutdown occurrence must be remembered")
	state.technical_debt = 10
	check_equal(simulation.determine_shutdown(state, 99), -1, "debt ten uses automation lock instead of slot shutdown")
	state.technical_debt = 6
	check_equal(simulation.determine_shutdown(state, 99), -1, "shutdown must clear after debt drops below seven")
	check_equal(state.stopped_slot, -1, "stopped slot must not leak into a later safe day")
	state.maintenance_ready = true
	check_equal(simulation.determine_shutdown(state, 99), -1, "maintenance must remain banked outside shutdown debt")
	check(state.maintenance_ready, "maintenance must not be consumed when no shutdown would occur")
	state.technical_debt = 8
	var expected_state: RefCounted = state.duplicate_run()
	expected_state.maintenance_ready = false
	var expected_slot: int = simulation.determine_shutdown(expected_state, 99)
	check_equal(simulation.determine_shutdown(state, 99), -1, "maintenance must cancel the next deterministic shutdown")
	check(not state.maintenance_ready, "cancelled shutdown must consume maintenance")
	check_equal(state.maintenance_prevented_slot, expected_slot, "maintenance must report the exact deterministic slot it prevented")
	var next_shutdown: int = simulation.determine_shutdown(state, 99)
	check(next_shutdown >= 0, "shutdowns after the consumed guarantee must resolve normally")

func _test_automation_unlocks_on_following_day() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var state: RefCounted = STATE_SCRIPT.new()
	state.install(cards[&"parameter_scan"])
	state.install(cards[&"paper_template"])
	state.clean_data = 6
	state.change_resource(&"technical_debt", 10)
	var simulation: RefCounted = SIMULATION_SCRIPT.new()
	simulation.simulate_day(state)
	check_equal(state.technical_debt, 7, "locked day must settle to debt seven")
	state.clean_data = 6
	var next_day: Dictionary = simulation.simulate_day(state)
	var automatic_count: int = 0
	for event: Dictionary in next_day.events:
		if int(event.type) == 2:
			automatic_count += 1
	check(not state.automation_locked, "automation lock must clear at the start of the next safe day")
	check(automatic_count > 0, "automatic events must execute again after the lock clears")

func _test_queue_cap_and_chain() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var state: RefCounted = STATE_SCRIPT.new()
	state.install(cards[&"parameter_scan"])
	state.install(cards[&"parameter_scan"])
	state.install(cards[&"paper_template"])
	state.install(cards[&"paper_template"])
	state.install(cards[&"scheduler"])
	state.install(cards[&"scheduler"])
	state.clean_data = 6
	var result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(state)
	var chain_sizes: Dictionary[int, int] = {}
	for event: Dictionary in result.events:
		var chain_id: int = int(event.chain_id)
		chain_sizes[chain_id] = int(chain_sizes.get(chain_id, 0)) + 1
	var largest_chain: int = 0
	for size: int in chain_sizes.values():
		largest_chain = maxi(largest_chain, size)
	check(int(result.trigger_count) <= 12, "default queue must stop at twelve executed events")
	check(largest_chain >= 4, "scheduler fixture must retain its natural four-event chain")

func _test_loop_guard_trigger_limit() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var state: RefCounted = STATE_SCRIPT.new()
	var simulation: RefCounted = SIMULATION_SCRIPT.new()
	check_equal(simulation.trigger_limit_for(state), 12, "default production line must cap at twelve triggers")
	state.install(cards[&"loop_guard"])
	check_equal(simulation.trigger_limit_for(state), 16, "loop guard must raise the trigger cap to sixteen")

func _test_all_nighter_debt_redemption() -> void:
	var cases: Array[Array] = [
		[1, 6, 0], [2, 8, 1], [4, 8, 3],
		[5, 10, 4], [7, 10, 6], [8, 12, 7],
	]
	for values: Array in cases:
		var state := _all_nighter_state(int(values[0]), 1, 1)
		SIMULATION_SCRIPT.new().simulate_day(state, 4)
		check_equal(state.paper_progress, values[1], "all-nighter value must follow event-time debt tier after prepayment")
		check_equal(state.technical_debt, values[2], "level-one redemption must reduce event-time debt by three")
	var multi_chart := _all_nighter_state(5, 3, 1)
	SIMULATION_SCRIPT.new().simulate_day(multi_chart, 4)
	check_equal(multi_chart.paper_progress, 30, "all-nighter must apply the debt-tier value to every chart")
	var held := _all_nighter_state(7, 3, 1)
	var held_result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(held)
	check_equal(held.charts, 3, "base all-nighter trigger must keep every chart for manual cashout")
	check_equal(held.paper_progress, 0, "base all-nighter trigger must not create progress")
	var writing_event: Dictionary = held_result.events[4]
	check_equal(writing_event.details.reason, &"awaiting_manual_cashout", "held charts must expose a neutral waiting reason")
	var no_charts := _all_nighter_state(7, 0, 1)
	SIMULATION_SCRIPT.new().simulate_day(no_charts, 4)
	check_equal(no_charts.technical_debt, 9, "empty all-nighter must not reduce debt")
	check_equal(no_charts.energy, 7, "empty cashout must pay generic overclock and normal day energy only")
	var overclocked := _all_nighter_state(8, 1, 1)
	SIMULATION_SCRIPT.new().simulate_day(overclocked, 4)
	check_equal(overclocked.paper_progress, 12, "overclock prepayment must move debt eight into the debt-ten value tier")
	check_equal(overclocked.technical_debt, 7, "debt-ten redemption must reduce debt after using the higher tier")
	check(overclocked.automation_locked, "reaching debt ten must keep automation locked after redemption")
	check_equal(overclocked.energy, 5, "energy settlement must include overclock, all-nighter, rest, and normal day effects")
	var upgraded := _all_nighter_state(10, 1, 2)
	upgraded.technical_debt = 8
	SIMULATION_SCRIPT.new().simulate_day(upgraded, 4)
	check_equal(upgraded.paper_progress, 14, "level-two all-nighter must retain its higher base value")
	check_equal(upgraded.technical_debt, 6, "level-two redemption must reduce debt by four")
	var emergency := _all_nighter_state(5, 0, 1)
	emergency.clean_data = 1
	emergency.stopped_slot = 3
	var emergency_result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(emergency, 4)
	check_equal(emergency.charts, 0, "emergency cashout must not add its temporary chart to inventory")
	check_equal(emergency.clean_data, 0, "emergency cashout must consume one clean data")
	check_equal(emergency.paper_progress, 10, "emergency cashout must use the normal event-time unit value")
	check_equal(emergency.technical_debt, 4, "emergency cashout must retain the normal level-one debt reduction")
	check_equal(emergency.energy, 5, "emergency cashout must use the common two-energy card cost")
	var emergency_details: Dictionary = {}
	for event: Dictionary in emergency_result.events:
		if bool(event.success) and StringName(event.card_id) == &"all_nighter":
			emergency_details = event.details
	check_equal(emergency_details.get("cashout_kind", &""), &"emergency", "details must identify emergency cashout")
	check_equal(emergency_details.get("clean_used", 0), 1, "emergency details must expose clean-data consumption")
	check_equal(emergency_details.get("value", 0), 10, "details must expose the event-time unit value")
	check_equal(emergency_details.get("progress", 0), 10, "details must expose the exact progress gain")
	var rejected := _all_nighter_state(5, 0, 1)
	var rejected_result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(rejected, 4)
	check_equal(rejected.paper_progress, 0, "cashout without charts or clean data must not grant progress")
	var rejection_found: bool = false
	for event: Dictionary in rejected_result.events:
		if StringName(event.get("failure_reason", &"")) == &"no_cashout_resource":
			rejection_found = true
	check(rejection_found, "rejected cashout must expose its missing resource")
	_test_all_nighter_automatic_triggers_only_hold_charts()

func _test_all_nighter_energy_thresholds_are_event_atomic() -> void:
	var rejected: RefCounted = _all_nighter_state(4, 1, 1)
	rejected.energy = 2
	var rejected_result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(rejected, 4)
	check_equal(_all_nighter_overclock_reason(rejected_result), &"insufficient_energy", "cashout must require two event-time energy after overclock prepayment")
	check_equal(rejected.paper_progress, 0, "energy rejection must not grant progress")
	check_equal(rejected.charts, 1, "energy rejection must not consume charts")
	var standard_success: RefCounted = _all_nighter_state(4, 1, 1)
	standard_success.energy = 3
	check_equal(_all_nighter_overclock_reason(SIMULATION_SCRIPT.new().simulate_day(standard_success, 4)), &"", "standard cashout must succeed with three day-start energy")
	var emergency_success: RefCounted = _all_nighter_state(4, 0, 1)
	emergency_success.energy = 3
	emergency_success.clean_data = 1
	emergency_success.stopped_slot = 3
	check_equal(_all_nighter_overclock_reason(SIMULATION_SCRIPT.new().simulate_day(emergency_success, 4)), &"", "emergency cashout uses the same energy threshold")

func _all_nighter_overclock_reason(result: Dictionary) -> StringName:
	for event: Dictionary in result.events:
		if int(event.slot) == 4 and int(event.type) == 1 and StringName(event.card_id) == &"all_nighter":
			return &"" if bool(event.success) else StringName(event.get("failure_reason", &""))
	return &"missing_event"

func _test_level_two_paper_template_value() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var state: RefCounted = STATE_SCRIPT.new()
	state.install(cards[&"paper_template"])
	state.install(cards[&"paper_template"])
	state.charts = 1
	SIMULATION_SCRIPT.new().simulate_day(state)
	check_equal(state.paper_progress, 19, "level-two paper template base trigger must grant nineteen progress")

func _test_converter_high_debt_batch_size() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var high_debt: RefCounted = STATE_SCRIPT.new()
	high_debt.install(cards[&"converter"])
	high_debt.raw_data = 1
	high_debt.technical_debt = 7
	var high_result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(high_debt)
	var high_converter: Dictionary = high_result.events[2]
	check_equal(high_converter.deltas.get(&"raw_data", 0), -2, "converter must use two raw data per batch at debt seven to nine")
	var low_debt: RefCounted = STATE_SCRIPT.new()
	low_debt.install(cards[&"converter"])
	low_debt.raw_data = 1
	var low_result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(low_debt)
	var low_converter: Dictionary = low_result.events[2]
	check(not bool(low_converter.success), "converter must still require four raw data outside the high-debt window")

func _test_all_nighter_automatic_triggers_only_hold_charts() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var state: RefCounted = STATE_SCRIPT.new()
	state.install(cards[&"parameter_scan"])
	state.install(cards[&"all_nighter"])
	state.install(cards[&"scheduler"])
	state.install(cards[&"scheduler"])
	state.clean_data = 2
	state.technical_debt = 9
	var result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(state, 4)
	var reductions: Array[int] = []
	var held_events: int = 0
	for event: Dictionary in result.events:
		if StringName(event.card_id) != &"all_nighter":
			continue
		if bool(event.success):
			reductions.append(int(event.details.debt_reduced))
		elif event.has("details") and StringName(event.details.get("reason", &"")) == &"awaiting_manual_cashout":
			held_events += 1
	check_equal(reductions, [3], "only the explicit writing overclock may redeem and reduce debt")
	check(held_events >= 1, "automatic or base writing triggers before cashout must hold charts without redeeming")

func _all_nighter_state(debt: int, charts: int, level: int) -> RefCounted:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var state: RefCounted = STATE_SCRIPT.new()
	state.install(cards[&"all_nighter"])
	if level >= 2:
		state.install(cards[&"all_nighter"])
	state.technical_debt = debt
	state.charts = charts
	return state

func _test_diagnostics_are_reported() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var locked_state: RefCounted = STATE_SCRIPT.new()
	locked_state.install(cards[&"parameter_scan"])
	locked_state.install(cards[&"paper_template"])
	locked_state.clean_data = 3
	locked_state.technical_debt = 10
	var locked_result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(locked_state)
	check(locked_result.has("blocked_events"), "simulation must always expose blocked-event diagnostics")
	check(locked_result.has("queue_truncated"), "simulation must always expose queue truncation diagnostics")
	check(not locked_result.blocked_events.is_empty(), "debt-ten lock must report discarded automatic events")
