extends "res://tests/lab_engine/lab_test_case.gd"

const POLICY_SCRIPT := preload("res://scripts/lab_engine/shadow/lab_day_four_renovation_policy.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_only_installed_level_one_productive_slots_are_eligible()
	_test_precision_payment_is_atomic_and_preserves_instance_state()
	_test_precision_rejects_unaffordable_choice_without_mutation()
	_test_aggressive_requires_the_full_uncapped_price()
	_test_repeated_application_is_idempotent()
	_test_stopped_station_remains_stopped()
	return failures

func _test_only_installed_level_one_productive_slots_are_eligible() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.slots[0] = _entry(&"literature", 1, 3)
	state.slots[1] = _entry(&"experiment", 2, 4)
	state.slots[5] = _entry(&"rest", 1, 5)
	check_equal(POLICY_SCRIPT.new().eligible_slots(state), [0], "renovation must only offer installed Lv1 productive stations")

func _test_precision_payment_is_atomic_and_preserves_instance_state() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.inspiration = 4
	state.energy = 5
	state.slots[2] = {"card_id": &"data", "level": 1, "days_installed": 3, "instance_id": 17}
	var result: Dictionary = POLICY_SCRIPT.new().apply(state, 2, &"precision")
	check(bool(result.applied), "precision renovation must apply when affordable")
	check_equal(state.inspiration, 2, "precision renovation must spend two inspiration")
	check_equal(state.energy, 4, "precision renovation must spend one energy")
	check_equal(state.slots[2].level, 2, "precision renovation must raise the selected station to Lv2")
	check_equal(state.slots[2].days_installed, 3, "renovation must preserve installation age")
	check_equal(state.slots[2].instance_id, 17, "renovation must preserve the installed instance")

func _test_precision_rejects_unaffordable_choice_without_mutation() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.inspiration = 1
	state.energy = 8
	state.slots[0] = _entry(&"literature", 1, 7)
	var before: Dictionary = state.snapshot()
	check(not bool(POLICY_SCRIPT.new().apply(state, 0, &"precision").applied), "precision renovation must reject insufficient resources")
	check_equal(state.snapshot(), before, "a rejected renovation must not mutate run state")

func _test_aggressive_requires_the_full_uncapped_price() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.technical_debt = 8
	state.slots[3] = _entry(&"analysis", 1, 8)
	check(not bool(POLICY_SCRIPT.new().apply(state, 3, &"aggressive").applied), "aggressive renovation must not receive a capped debt discount")
	check_equal(state.technical_debt, 8, "a rejected aggressive renovation must not change debt")
	check_equal(state.slots[3].level, 1, "a rejected aggressive renovation must not upgrade")

func _test_repeated_application_is_idempotent() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.technical_debt = 2
	state.slots[4] = _entry(&"writing", 1, 9)
	var policy: RefCounted = POLICY_SCRIPT.new()
	var first: Dictionary = policy.apply(state, 4, &"aggressive")
	var second: Dictionary = policy.apply(state, 4, &"aggressive")
	check_equal(second, first, "repeated settlement must return the frozen renovation result")
	check_equal(state.technical_debt, 5, "repeated settlement must not charge twice")

func _test_stopped_station_remains_stopped() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.inspiration = 3
	state.energy = 4
	state.stopped_slot = 1
	state.slots[1] = _entry(&"experiment", 1, 10)
	var result: Dictionary = POLICY_SCRIPT.new().apply(state, 1, &"precision")
	check(bool(result.was_stopped), "renovation result must report a stopped target")
	check_equal(state.stopped_slot, 1, "renovation must not repair or replace the stopped instance")

func _entry(card_id: StringName, level: int, instance_id: int) -> Dictionary:
	return {"card_id": card_id, "level": level, "days_installed": 2, "instance_id": instance_id}
