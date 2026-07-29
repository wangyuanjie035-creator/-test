extends "res://tests/lab_engine/lab_test_case.gd"

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")

func run() -> Array[String]:
	_test_resource_bounds()
	_test_install_upgrade_replace()
	_test_duplicate_run_is_independent()
	return failures

func _test_resource_bounds() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.change_resource(&"inspiration", 99)
	state.change_resource(&"energy", -99)
	state.change_resource(&"paper_progress", 125)
	check_equal(state.inspiration, 10, "inspiration must clamp to its upper bound")
	check_equal(state.energy, 0, "energy must clamp to zero")
	check_equal(state.paper_progress, 125, "paper progress must not clamp at the win threshold")

func _test_install_upgrade_replace() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var state: RefCounted = STATE_SCRIPT.new()
	check_equal(state.install(cards[&"crawler"]), "install", "empty slot must install")
	var first_instance: int = int(state.slots[0].instance_id)
	check_equal(state.install(cards[&"crawler"]), "upgrade", "same card must upgrade")
	check_equal(state.install(cards[&"crawler"]), "upgrade", "upgrade action must remain stable at level cap")
	check_equal(state.slots[0].level, 2, "card level must cap at two")
	check_equal(state.slots[0].instance_id, first_instance, "upgrade must preserve instance identity")
	check_equal(state.install(cards[&"subscription"]), "install", "different card must replace the slot")
	check_equal(state.slots[0].card_id, &"subscription", "replacement must update card id")
	check(int(state.slots[0].instance_id) != first_instance, "replacement must allocate a new instance identity")

func _test_duplicate_run_is_independent() -> void:
	var state: RefCounted = STATE_SCRIPT.new()
	state.inspiration = 4
	state.maintenance_ready = true
	var copy: RefCounted = state.duplicate_run()
	copy.inspiration = 9
	copy.slots[0].level = 2
	check_equal(state.inspiration, 4, "duplicate resource mutation must not affect source")
	check_equal(state.slots[0].level, 0, "duplicate slot mutation must not affect source")
	check(copy.maintenance_ready, "duplicate run must preserve maintenance guarantee")
