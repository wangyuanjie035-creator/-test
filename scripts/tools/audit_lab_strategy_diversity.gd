extends SceneTree

const CONTROLLER_SCRIPT := preload("res://scripts/lab_engine/run/lab_run_controller.gd")

const START_SEED := 242000
const SAMPLE_COUNT := 120
const POLICIES: Array[StringName] = [&"pipeline", &"topic", &"cashout"]
const TOPIC_SLOT: Dictionary[StringName, int] = {
	&"inspiration": 0,
	&"raw_data": 1,
	&"clean_data": 2,
	&"charts": 3,
}

func _init() -> void:
	var first_slots: Dictionary[int, int] = {}
	var opening_counts: Dictionary[String, int] = {}
	var policy_wins: Dictionary[StringName, int] = {}
	var policy_paper: Dictionary[StringName, int] = {}
	var total_runs := 0
	for policy: StringName in POLICIES:
		for offset: int in range(SAMPLE_COUNT):
			var outcome := _run_policy(START_SEED + offset, policy)
			total_runs += 1
			var first_slot: int = int(outcome.first_slot)
			first_slots[first_slot] = int(first_slots.get(first_slot, 0)) + 1
			var opening: String = String(outcome.opening)
			opening_counts[opening] = int(opening_counts.get(opening, 0)) + 1
			policy_wins[policy] = int(policy_wins.get(policy, 0)) + int(outcome.won)
			policy_paper[policy] = int(policy_paper.get(policy, 0)) + int(outcome.paper)
	var top_first := _largest_count(first_slots)
	var top_opening := _largest_count(opening_counts)
	var proxy_credible := _golden_proxy_wins()
	for policy: StringName in POLICIES:
		print("DIVERSITY_AUDIT policy=%s wins=%d/%d (%.2f%%) mean_paper=%.2f" % [
			policy,
			int(policy_wins[policy]),
			SAMPLE_COUNT,
			int(policy_wins[policy]) * 100.0 / SAMPLE_COUNT,
			int(policy_paper[policy]) * 1.0 / SAMPLE_COUNT,
		])
	print("DIVERSITY_AUDIT first_slots=%s top=%d/%d (%.2f%%)" % [first_slots, top_first, total_runs, top_first * 100.0 / total_runs])
	print("DIVERSITY_AUDIT unique_openings=%d top=%d/%d (%.2f%%)" % [opening_counts.size(), top_opening, total_runs, top_opening * 100.0 / total_runs])
	var no_forced_first := top_first * 100.0 / total_runs <= 70.0
	var no_universal_script := top_opening * 100.0 / total_runs <= 50.0
	var passed := no_forced_first and no_universal_script and proxy_credible
	print("DIVERSITY_AUDIT verdict=%s no_forced_first=%s no_universal_script=%s proxy_credible=%s heuristic_wins_are_diagnostic_only=true" % [
		"PASS" if passed else "FAIL", no_forced_first, no_universal_script, proxy_credible,
	])
	quit(0 if passed else 1)

func _run_policy(seed: int, policy: StringName) -> Dictionary:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(seed)
	var opening := PackedStringArray()
	var first_slot := -1
	while not controller.finished:
		var preview: Dictionary = controller.begin_day()
		if bool(preview.get("forced_rest", false)):
			controller.play_day(-1, -1)
			if opening.size() < 4:
				opening.append("rest")
			continue
		var choice := _choose_candidate(controller, policy)
		var candidates: Array[StringName] = controller.candidates_for_today()
		var card: Resource = controller.cards[candidates[choice]]
		if first_slot < 0:
			first_slot = int(card.slot)
		if opening.size() < 4:
			opening.append(str(card.slot))
		var overclock := _choose_overclock(controller, policy)
		var result: Dictionary = controller.play_day(choice, overclock)
		if not bool(result.get("valid", false)):
			controller.play_day(choice, -1)
	return {
		"first_slot": first_slot,
		"opening": ",".join(opening),
		"won": controller.won,
		"paper": controller.state.paper_progress,
	}

func _choose_candidate(controller: RefCounted, policy: StringName) -> int:
	var candidates: Array[StringName] = controller.candidates_for_today()
	var best_index := 0
	var best_score := -99999.0
	for index: int in range(candidates.size()):
		var card: Resource = controller.cards[candidates[index]]
		var slot := int(card.slot)
		var score := float(card.output_score_level_1)
		match policy:
			&"pipeline":
				score += float([90, 110, 100, 75, 45, 0][slot])
				if StringName(controller.state.slots[slot].card_id) == &"":
					score += 35.0
			&"topic":
				var target_slot := int(TOPIC_SLOT.get(controller.cumulative_topic.target_resource(), 1))
				score += 150.0 if slot == target_slot else 55.0 if slot == target_slot - 1 else 0.0
			&"cashout":
				score += float([35, 55, 75, 105, 140, 0][slot])
				if slot == 4 and controller.state.charts > 0:
					score += 80.0
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

func _choose_overclock(controller: RefCounted, policy: StringName) -> int:
	if controller.state.energy <= 1 or controller.state.technical_debt >= 7:
		return -1
	if policy == &"topic":
		var topic_slot := int(TOPIC_SLOT.get(controller.cumulative_topic.target_resource(), 1))
		return topic_slot if topic_slot != controller.state.stopped_slot else -1
	for slot: int in ([4, 3, 2, 1, 0] if policy == &"cashout" else [1, 2, 3, 0, 4]):
		if slot != controller.state.stopped_slot:
			return slot
	return -1

func _largest_count(counts: Dictionary) -> int:
	var largest := 0
	for value: Variant in counts.values():
		largest = maxi(largest, int(value))
	return largest

func _golden_proxy_wins() -> bool:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(240731)
	var route: Array[StringName] = [
		&"parameter_scan", &"batch_experiment", &"paper_template", &"batch_experiment",
		&"cleaning", &"scheduler", &"", &"scheduler",
	]
	var overclocks: Array[int] = [0, -1, 0, 1, 1, -1, -1, -1]
	for day_index: int in range(route.size()):
		controller.begin_day()
		var choice := -1
		if route[day_index] != &"":
			choice = controller.candidates_for_today().find(route[day_index])
			if choice < 0:
				print("DIVERSITY_AUDIT proxy_missing_card day=%d card=%s" % [day_index + 1, route[day_index]])
				return false
		var result: Dictionary = controller.play_day(choice, overclocks[day_index])
		if not bool(result.get("valid", false)):
			print("DIVERSITY_AUDIT proxy_invalid_day day=%d" % (day_index + 1))
			return false
	print("DIVERSITY_AUDIT proxy seed=240731 won=%s paper=%d" % [controller.won, controller.state.paper_progress])
	return controller.won
