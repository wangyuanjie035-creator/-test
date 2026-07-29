extends "res://tests/lab_engine/lab_test_case.gd"

const POLICY := preload("res://scripts/lab_engine/shadow/lab_manual_dispatch_policy.gd")
const STATE := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_dispatch_is_unavailable_before_day_four()
	_test_dispatch_converts_stock_once()
	_test_invalid_execution_is_atomic_and_does_not_consume_token()
	return failures

func _test_dispatch_is_unavailable_before_day_four() -> void:
	var state: RefCounted = _ready_state(1)
	check(POLICY.new().available_links(state).is_empty(), "manual dispatch must not unlock before day four")

func _test_dispatch_converts_stock_once() -> void:
	var state: RefCounted = _ready_state(4)
	state.raw_data = 8
	var policy: RefCounted = POLICY.new()
	var first: Dictionary = policy.execute(state, 1)
	var repeated: Dictionary = policy.execute(state, 2)
	check(bool(first.applied), "funded manual dispatch must apply")
	check_equal(state.raw_data, 4, "manual dispatch must spend its upstream stock")
	check_equal(state.clean_data, 1, "manual dispatch must create the baseline downstream amount")
	check_equal(repeated, first, "manual dispatch token must settle idempotently")

func _test_invalid_execution_is_atomic_and_does_not_consume_token() -> void:
	var state: RefCounted = _ready_state(4)
	state.raw_data = 3
	var policy: RefCounted = POLICY.new()
	check(not bool(policy.execute(state, 1).applied), "unfunded dispatch must fail")
	state.raw_data = 4
	check(bool(policy.execute(state, 1).applied), "failed preview must not consume the one-time token")

func _ready_state(day: int) -> RefCounted:
	var state: RefCounted = STATE.new()
	state.day = day
	for slot: int in range(4):
		state.slots[slot] = {"card_id": StringName("slot_%d" % slot), "level": 1, "days_installed": 1, "instance_id": slot + 1}
	return state
