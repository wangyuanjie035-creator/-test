extends SceneTree

const CONTROLLER_SCRIPT := preload("res://scripts/lab_engine/run/lab_run_controller.gd")

const START_SEED := 241000
const SAMPLE_COUNT := 96
const CONTROLLED_DEBTS: Array[int] = [6, 7, 8]
const BASE_SLOT_SCORE: Array[int] = [50, 100, 80, 60, 20, 0]
const TARGET_SLOT: Dictionary[StringName, int] = {
	&"inspiration": 0,
	&"raw_data": 1,
	&"clean_data": 2,
	&"charts": 3,
}

func _init() -> void:
	var total_cases := 0
	var credible_counts := {&"maintenance": 0, &"topic": 0, &"expansion": 0}
	var sole_winner_counts := {&"maintenance": 0, &"topic": 0, &"expansion": 0}
	var maintenance_selected_value := 0
	var topic_selected_value := 0
	var expansion_selected_value := 0
	var diverse_cases := 0
	var maintenance_cases := PackedStringArray()
	var topic_cases := PackedStringArray()
	var expansion_cases := PackedStringArray()
	for offset: int in range(SAMPLE_COUNT):
		var seed := START_SEED + offset
		for controlled_debt: int in CONTROLLED_DEBTS:
			var outcomes := _compare_branches(seed, controlled_debt)
			if outcomes.is_empty():
				continue
			total_cases += 1
			var best_value := -99999.0
			for outcome: Dictionary in outcomes:
				best_value = maxf(best_value, float(outcome.value))
			var credible := 0
			var sole_winner: StringName = &""
			for outcome: Dictionary in outcomes:
				# A route is credible if it is within one ordinary writing trigger of the best result.
				if float(outcome.value) >= best_value - 5.0:
					credible += 1
					credible_counts[outcome.route] = int(credible_counts[outcome.route]) + 1
					sole_winner = outcome.route
			if credible >= 2:
				diverse_cases += 1
			elif credible == 1:
				sole_winner_counts[sole_winner] = int(sole_winner_counts[sole_winner]) + 1
			var best_route: StringName = StringName(outcomes[0].route)
			for outcome: Dictionary in outcomes:
				if float(outcome.value) > float(_find_route(outcomes, best_route).value):
					best_route = outcome.route
			match best_route:
				&"maintenance":
					maintenance_selected_value += 1
					_record_case(maintenance_cases, seed, controlled_debt, outcomes)
				&"topic":
					topic_selected_value += 1
					_record_case(topic_cases, seed, controlled_debt, outcomes)
				&"expansion":
					expansion_selected_value += 1
					_record_case(expansion_cases, seed, controlled_debt, outcomes)
	print("TRADEOFF_AUDIT cases=%d diverse=%d (%.2f%%)" % [total_cases, diverse_cases, diverse_cases * 100.0 / max(1, total_cases)])
	print("TRADEOFF_AUDIT credible maintenance=%d topic=%d expansion=%d" % [credible_counts.maintenance, credible_counts.topic, credible_counts.expansion])
	print("TRADEOFF_AUDIT sole_winner maintenance=%d topic=%d expansion=%d" % [sole_winner_counts.maintenance, sole_winner_counts.topic, sole_winner_counts.expansion])
	print("TRADEOFF_AUDIT top_value maintenance=%d topic=%d expansion=%d" % [maintenance_selected_value, topic_selected_value, expansion_selected_value])
	print("TRADEOFF_AUDIT examples maintenance=%s" % maintenance_cases)
	print("TRADEOFF_AUDIT examples topic=%s" % topic_cases)
	print("TRADEOFF_AUDIT examples expansion=%s" % expansion_cases)
	var maintenance_exists: bool = int(credible_counts.maintenance) * 100.0 / maxi(1, total_cases) >= 10.0
	var topic_exists: bool = int(credible_counts.topic) * 100.0 / maxi(1, total_cases) >= 10.0
	var expansion_exists: bool = int(credible_counts.expansion) * 100.0 / maxi(1, total_cases) >= 10.0
	var no_single_solution: bool = diverse_cases * 100.0 / maxi(1, total_cases) >= 25.0
	var passed: bool = maintenance_exists and topic_exists and expansion_exists and no_single_solution
	print("TRADEOFF_AUDIT verdict=%s maintenance=%s topic=%s expansion=%s no_single_solution=%s" % ["PASS" if passed else "FAIL", maintenance_exists, topic_exists, expansion_exists, no_single_solution])
	quit(0 if passed else 1)

func _compare_branches(seed: int, controlled_debt: int) -> Array[Dictionary]:
	var probe := _build_day_three(seed, controlled_debt)
	var preview: Dictionary = probe.begin_day()
	if bool(preview.get("forced_rest", false)):
		return []
	var candidates: Array[StringName] = probe.candidates_for_today()
	if candidates.is_empty():
		return []
	var topic_choice := _topic_choice(probe)
	var expansion_choice := _expansion_choice(probe, topic_choice)
	return [
		_run_branch(seed, controlled_debt, &"maintenance", -1, -1),
		_run_branch(seed, controlled_debt, &"topic", topic_choice, _topic_target_slot(probe)),
		_run_branch(seed, controlled_debt, &"expansion", expansion_choice, _best_overclock_slot(probe)),
	]

func _run_branch(seed: int, controlled_debt: int, route: StringName, choice: int, overclock: int) -> Dictionary:
	var controller := _build_day_three(seed, controlled_debt)
	controller.begin_day()
	var day_three: Dictionary = _play_valid_day(controller, choice, overclock)
	while not controller.finished:
		var preview: Dictionary = controller.begin_day()
		if bool(preview.get("forced_rest", false)):
			controller.play_day(-1, -1)
			continue
		var next_choice := _followup_choice(controller)
		var next_overclock := -1
		if controller.state.technical_debt <= 5 and controller.state.energy >= 2:
			next_overclock = _best_overclock_slot(controller)
		_play_valid_day(controller, next_choice, next_overclock)
	var topic: Dictionary = controller.topic_snapshot()
	var shutdowns := 0
	var protections := 0
	for day: Dictionary in controller.history:
		shutdowns += int(int(day.get("stopped_slot", -1)) >= 0)
		protections += int(int(day.get("maintenance_prevented_slot", -1)) >= 0)
	var value := float(controller.state.paper_progress)
	value += 18.0 if controller.won else 0.0
	value += 5.0 if StringName(topic.get("status", &"active")) == &"achieved" else 0.0
	value += float(controller.state.energy) * 0.5
	value -= float(controller.state.technical_debt) * 0.75
	value -= float(shutdowns) * 3.0
	return {
		"route": route,
		"value": value,
		"paper": controller.state.paper_progress,
		"won": controller.won,
		"topic": StringName(topic.get("status", &"active")) == &"achieved",
		"debt": controller.state.technical_debt,
		"shutdowns": shutdowns,
		"protections": protections,
		"day_three_progress": int(day_three.get("daily_progress", 0)),
	}

func _play_valid_day(controller: RefCounted, choice: int, overclock: int) -> Dictionary:
	var result: Dictionary = controller.play_day(choice, overclock)
	if bool(result.get("valid", false)):
		return result
	result = controller.play_day(choice, -1)
	if bool(result.get("valid", false)):
		return result
	return controller.play_day(-1, -1)

func _build_day_three(seed: int, controlled_debt: int) -> RefCounted:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(seed)
	for _day: int in range(2):
		var preview: Dictionary = controller.begin_day()
		if bool(preview.get("forced_rest", false)):
			controller.play_day(-1, -1)
		else:
			controller.play_day(_baseline_choice(controller), -1)
	controller.state.technical_debt = controlled_debt
	return controller

func _baseline_choice(controller: RefCounted) -> int:
	return _best_choice(controller, -1, false)

func _topic_choice(controller: RefCounted) -> int:
	return _best_choice(controller, _topic_target_slot(controller), true)

func _expansion_choice(controller: RefCounted, excluded: int) -> int:
	var best := _best_choice(controller, -1, false, excluded)
	return excluded if best < 0 else best

func _best_choice(controller: RefCounted, preferred_slot: int, prefer_target: bool, excluded: int = -1) -> int:
	var candidates: Array[StringName] = controller.candidates_for_today()
	var best_index := -1
	var best_score := -99999
	for index: int in range(candidates.size()):
		if index == excluded:
			continue
		var card: Resource = controller.cards[candidates[index]]
		var slot := int(card.slot)
		var score := BASE_SLOT_SCORE[slot] + int(card.output_score_level_1)
		if prefer_target and slot == preferred_slot:
			score += 100
		elif prefer_target and slot == preferred_slot - 1:
			score += 40
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

func _followup_choice(controller: RefCounted) -> int:
	if controller.state.technical_debt >= 7 and not controller.state.maintenance_ready:
		return -1
	return _baseline_choice(controller)

func _best_overclock_slot(controller: RefCounted) -> int:
	for slot: int in [4, 3, 2, 1, 0]:
		if slot != controller.state.stopped_slot:
			return slot
	return -1

func _topic_target_slot(controller: RefCounted) -> int:
	return int(TARGET_SLOT.get(controller.cumulative_topic.target_resource(), 1))

func _find_route(outcomes: Array[Dictionary], route: StringName) -> Dictionary:
	for outcome: Dictionary in outcomes:
		if StringName(outcome.route) == route:
			return outcome
	return outcomes[0]

func _record_case(target: PackedStringArray, seed: int, debt: int, outcomes: Array[Dictionary]) -> void:
	if target.size() >= 4:
		return
	var parts := PackedStringArray()
	for outcome: Dictionary in outcomes:
		parts.append("%s=%.1f/p%d/t%s/s%d" % [outcome.route, outcome.value, outcome.paper, outcome.topic, outcome.shutdowns])
	target.append("%d@d%d[%s]" % [seed, debt, ",".join(parts)])
