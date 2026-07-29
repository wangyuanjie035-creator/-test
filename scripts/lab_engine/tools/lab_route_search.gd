class_name LabRouteSearch
extends RefCounted

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const CANDIDATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_candidate_generator.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const SIMULATION_SCRIPT := preload("res://scripts/lab_engine/model/lab_simulation.gd")

const DEFAULT_BEAM_WIDTH := 1200

func search(seed: int = 240731, beam_width: int = DEFAULT_BEAM_WIDTH, schedule_override: Array = []) -> Dictionary:
	var cards: Dictionary[StringName, Resource] = CATALOG_SCRIPT.new().build_cards()
	var schedule: Array = schedule_override.duplicate(true)
	if schedule.is_empty():
		schedule = CANDIDATE_SCRIPT.new().generate_schedule(cards, seed)
	var beam: Array[Dictionary] = [{"state": STATE_SCRIPT.new(), "path": []}]
	for day_index: int in range(8):
		var next_nodes: Array[Dictionary] = []
		var seen: Dictionary[String, float] = {}
		for node: Dictionary in beam:
			var source_state: RefCounted = node.state
			if source_state.energy <= 0:
				var rested: RefCounted = source_state.duplicate_run()
				rested.energy = 3
				rested.day += 1
				_add_node(next_nodes, seen, rested, node.path + [{"choice": -1, "overclock": -1, "forced_rest": true}], beam_width)
				continue
			SIMULATION_SCRIPT.new().determine_shutdown(source_state, seed)
			for choice_index: int in range(-1, 3):
				for overclock_slot: int in range(-1, 5):
					if overclock_slot >= 0 and overclock_slot == source_state.stopped_slot:
						continue
					var child: RefCounted = source_state.duplicate_run()
					var selected_id: StringName = &""
					var action: String = "maintenance"
					if choice_index == -1:
						child.change_resource(&"technical_debt", -1)
						if not child.maintenance_ready:
							child.maintenance_ready = true
					else:
						selected_id = schedule[day_index][choice_index]
						action = child.install(cards[selected_id])
					var result: Dictionary = SIMULATION_SCRIPT.new().simulate_day(child, overclock_slot)
					var step: Dictionary = {
						"choice": choice_index,
						"card_id": selected_id,
						"action": action,
						"overclock": overclock_slot,
						"stopped_slot": child.stopped_slot,
						"progress": child.paper_progress,
						"debt": child.technical_debt,
						"energy": child.energy,
						"combo": child.highest_combo,
						"triggers": result.trigger_count,
					}
					child.day += 1
					var path: Array = node.path.duplicate()
					path.append(step)
					if _is_golden(child):
						return {"found": true, "state": child.snapshot(), "path": path, "schedule": schedule}
					_add_node(next_nodes, seen, child, path, beam_width)
		next_nodes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left.score) > float(right.score))
		if next_nodes.size() > beam_width:
			next_nodes.resize(beam_width)
		beam = next_nodes
	return {"found": false, "best": beam[0] if not beam.is_empty() else {}, "schedule": schedule}

func _add_node(nodes: Array[Dictionary], seen: Dictionary[String, float], state: RefCounted, path: Array, beam_width: int) -> void:
	var score: float = _score(state)
	var signature: String = _signature(state)
	if seen.has(signature) and seen[signature] >= score:
		return
	seen[signature] = score
	nodes.append({"state": state, "path": path, "score": score})

func _score(state: RefCounted) -> float:
	var installed_value: int = 0
	var combo_setup_value: int = 0
	var has_parameter_scan: bool = false
	var has_paper_template: bool = false
	var has_cleaning: bool = false
	var has_batch_experiment: bool = false
	var scheduler_level: int = 0
	for entry: Dictionary in state.slots.values():
		installed_value += int(entry.level)
		match StringName(entry.card_id):
			&"parameter_scan":
				combo_setup_value += 3000 * int(entry.level)
				has_parameter_scan = true
			&"paper_template":
				combo_setup_value += 6000 * int(entry.level)
				has_paper_template = true
			&"scheduler":
				scheduler_level = int(entry.level)
				combo_setup_value += 4000 * scheduler_level
			&"cleaning":
				has_cleaning = true
				combo_setup_value += 5000 * int(entry.level)
			&"batch_experiment":
				has_batch_experiment = true
				combo_setup_value += 5000 * int(entry.level)
	if has_cleaning and has_parameter_scan:
		combo_setup_value += 10000
	if has_batch_experiment and has_cleaning:
		combo_setup_value += 10000
	if has_parameter_scan and has_paper_template and scheduler_level >= 2:
		combo_setup_value += 50000
	return (
		state.paper_progress * 100.0
		+ state.highest_combo * 5000.0
		+ (500.0 if state.had_shutdown else 0.0)
		+ (700.0 if state.reached_debt_ten else 0.0)
		+ state.clean_data * 1500.0
		+ state.charts * 12.0
		+ state.raw_data * 2.0
		+ installed_value * 5.0
		+ combo_setup_value
		+ state.energy * 500.0
	)

func _signature(state: RefCounted) -> String:
	var slot_parts: PackedStringArray = []
	for slot: int in range(6):
		var entry: Dictionary = state.slots[slot]
		slot_parts.append("%s:%s:%s" % [entry.card_id, entry.level, entry.days_installed])
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		state.day, state.inspiration, state.raw_data, state.clean_data, state.charts,
		state.paper_progress, state.energy, state.technical_debt,
		int(state.had_shutdown), int(state.reached_debt_ten), int(state.maintenance_ready), ",".join(slot_parts),
	]

func _is_golden(state: RefCounted) -> bool:
	return state.paper_progress >= 100 and state.had_shutdown and state.reached_debt_ten and state.highest_combo >= 4
