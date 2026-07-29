extends SceneTree

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const CANDIDATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_candidate_generator.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const SIMULATION_SCRIPT := preload("res://scripts/lab_engine/model/lab_simulation.gd")

var _failed: bool = false

func _init() -> void:
	_validate_candidates()
	_validate_queue_semantics()
	_validate_seed_240731_e2e()
	if _failed:
		quit(1)
		return
	print("LAB_ENGINE_VALIDATION: PASS")
	quit(0)

func _validate_candidates() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var generator: RefCounted = CANDIDATE_SCRIPT.new()
	var first: Array = generator.generate_schedule(cards, 240731)
	var second: Array = generator.generate_schedule(cards, 240731)
	_check(first == second, "same seed must generate the same schedule")
	_check(first.size() == 8, "schedule must contain eight days")
	for choices: Array in first:
		_check(choices.size() == 3, "every day must contain three candidates")

func _validate_queue_semantics() -> void:
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
	_check(largest_chain >= 4, "scheduler route must naturally create a four-event chain")
	_check(int(result.trigger_count) <= 12, "default daily trigger cap must be enforced")
	_check(state.paper_progress > 0, "queue fixture must produce paper progress")

func _validate_seed_240731_e2e() -> void:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var schedule: Array = CANDIDATE_SCRIPT.new().generate_schedule(cards, 240731)
	var route: Array[StringName] = [
		&"parameter_scan", &"batch_experiment", &"paper_template", &"batch_experiment",
		&"cleaning", &"scheduler", &"", &"scheduler",
	]
	var overclocks: Array[int] = [0, -1, 0, 1, 1, -1, -1, -1]
	var state: RefCounted = STATE_SCRIPT.new()
	for day_index: int in range(8):
		var simulation: RefCounted = SIMULATION_SCRIPT.new()
		simulation.determine_shutdown(state, 240731)
		var selected_id: StringName = route[day_index]
		if selected_id == &"":
			state.change_resource(&"technical_debt", -1)
			if not state.maintenance_ready:
				state.maintenance_ready = true
		else:
			_check(schedule[day_index].has(selected_id), "golden card must exist in that day's candidates")
			state.install(cards[selected_id])
		simulation.simulate_day(state, overclocks[day_index])
		state.day += 1
	_check(state.paper_progress == 130, "golden route paper progress must remain exactly 130")
	_check(state.had_shutdown, "golden route must experience a shutdown")
	_check(state.reached_debt_ten, "golden route must reach technical debt 10")
	_check(state.technical_debt == 9, "golden route final technical debt must remain exactly 9")
	_check(state.energy == 2, "golden route final energy must remain exactly 2")
	_check(state.total_triggers == 59, "golden route total triggers must remain exactly 59")
	_check(state.highest_daily_progress == 35, "golden route highest daily progress must remain exactly 35")
	_check(state.highest_combo == 4, "golden route maximum combo must remain exactly 4")

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("LAB_ENGINE_VALIDATION: %s" % message)
