extends SceneTree

const CONTROLLER_SCRIPT := preload("res://scripts/lab_engine/run/lab_run_controller.gd")

const SAMPLE_COUNT := 60
const START_SEED := 240700
const BASE_SLOT_SCORE: Array[int] = [50, 100, 80, 60, 20, 0]
const TARGET_SLOT: Dictionary[StringName, int] = {
	&"inspiration": 0,
	&"raw_data": 1,
	&"clean_data": 2,
	&"charts": 3,
}

func _init() -> void:
	var changed_runs := 0
	var candidate_changed_runs := 0
	var baseline_achieved := 0
	var responsive_achieved := 0
	var responsive_only := 0
	var baseline_only := 0
	var both_achieved := 0
	var neither_achieved := 0
	var responsive_value_wins := 0
	var baseline_value_wins := 0
	var equal_value := 0
	var baseline_value_total := 0.0
	var responsive_value_total := 0.0
	var responsive_win_seeds := PackedInt32Array()
	var baseline_win_seeds := PackedInt32Array()
	var tie_seeds := PackedInt32Array()
	var strata: Dictionary[String, PackedInt32Array] = {}
	var topic_counts: Dictionary[StringName, int] = {}
	var topic_changes: Dictionary[StringName, int] = {}
	for offset: int in range(SAMPLE_COUNT):
		var seed := START_SEED + offset
		var baseline := _run_opening(seed, false)
		var responsive := _run_opening(seed, true)
		var topic_id: StringName = responsive.topic_id
		topic_counts[topic_id] = int(topic_counts.get(topic_id, 0)) + 1
		if baseline.choices != responsive.choices or baseline.overclocks != responsive.overclocks:
			changed_runs += 1
			topic_changes[topic_id] = int(topic_changes.get(topic_id, 0)) + 1
		if baseline.choices != responsive.choices:
			candidate_changed_runs += 1
		var base_ok := bool(baseline.achieved)
		var response_ok := bool(responsive.achieved)
		baseline_value_total += float(baseline.opening_value)
		responsive_value_total += float(responsive.opening_value)
		if float(responsive.opening_value) > float(baseline.opening_value) + 0.01:
			responsive_value_wins += 1
			_record_stratum(strata, "%s:responsive" % topic_id, seed)
			if responsive_win_seeds.size() < 4:
				responsive_win_seeds.append(seed)
		elif float(baseline.opening_value) > float(responsive.opening_value) + 0.01:
			baseline_value_wins += 1
			_record_stratum(strata, "%s:baseline" % topic_id, seed)
			if baseline_win_seeds.size() < 4:
				baseline_win_seeds.append(seed)
		else:
			equal_value += 1
			_record_stratum(strata, "%s:tie" % topic_id, seed)
			if tie_seeds.size() < 4:
				tie_seeds.append(seed)
		baseline_achieved += int(base_ok)
		responsive_achieved += int(response_ok)
		if base_ok and response_ok:
			both_achieved += 1
		elif response_ok:
			responsive_only += 1
		elif base_ok:
			baseline_only += 1
		else:
			neither_achieved += 1
	print("TOPIC_AUDIT samples=%d changed=%d (%.2f%%)" % [SAMPLE_COUNT, changed_runs, changed_runs * 100.0 / SAMPLE_COUNT])
	print("TOPIC_AUDIT candidate_changed=%d (%.2f%%)" % [candidate_changed_runs, candidate_changed_runs * 100.0 / SAMPLE_COUNT])
	print("TOPIC_AUDIT achieved baseline=%d responsive=%d both=%d responsive_only=%d baseline_only=%d neither=%d" % [baseline_achieved, responsive_achieved, both_achieved, responsive_only, baseline_only, neither_achieved])
	print("TOPIC_AUDIT opening_value baseline=%.2f responsive=%.2f wins=%d/%d ties=%d" % [baseline_value_total / SAMPLE_COUNT, responsive_value_total / SAMPLE_COUNT, baseline_value_wins, responsive_value_wins, equal_value])
	print("TOPIC_AUDIT representative_seeds responsive=%s baseline=%s ties=%s" % [responsive_win_seeds, baseline_win_seeds, tie_seeds])
	for topic_id: StringName in topic_counts:
		print("TOPIC_AUDIT topic=%s changed=%d/%d" % [topic_id, int(topic_changes.get(topic_id, 0)), int(topic_counts[topic_id])])
	for key: String in strata:
		print("TOPIC_AUDIT stratum=%s seeds=%s" % [key, strata[key]])
	var changed_enough := candidate_changed_runs * 100.0 / SAMPLE_COUNT >= 25.0
	var no_complete_dominance := responsive_value_wins * 100.0 / SAMPLE_COUNT <= 60.0 and baseline_value_wins * 100.0 / SAMPLE_COUNT >= 20.0
	var reward_is_reachable := responsive_achieved > baseline_achieved and responsive_achieved < SAMPLE_COUNT
	var passed := changed_enough and no_complete_dominance and reward_is_reachable
	print("TOPIC_AUDIT verdict=%s changed_enough=%s no_complete_dominance=%s reward_is_reachable=%s" % ["CONDITIONAL_PASS" if passed else "FAIL", changed_enough, no_complete_dominance, reward_is_reachable])
	quit(0 if passed else 1)

func _record_stratum(strata: Dictionary[String, PackedInt32Array], key: String, seed: int) -> void:
	if not strata.has(key):
		strata[key] = PackedInt32Array()
	if strata[key].size() < 2:
		strata[key].append(seed)

func _run_opening(seed: int, responsive: bool) -> Dictionary:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(seed)
	var choices := PackedStringArray()
	var overclocks := PackedInt32Array()
	for _day: int in range(3):
		var preview: Dictionary = controller.begin_day()
		if bool(preview.get("forced_rest", false)):
			controller.play_day(-1, -1)
			choices.append("rest")
			overclocks.append(-1)
			continue
		var choice := _choose_candidate(controller, responsive)
		var candidates: Array[StringName] = controller.candidates_for_today()
		choices.append(String(candidates[choice]))
		var overclock := _choose_overclock(controller, responsive)
		overclocks.append(overclock)
		controller.play_day(choice, overclock)
	var snapshot: Dictionary = controller.topic_snapshot()
	controller.begin_day()
	return {
		"topic_id": snapshot.topic_id,
		"achieved": int(snapshot.progress) >= int(snapshot.target),
		"progress": int(snapshot.progress),
		"choices": choices,
		"overclocks": overclocks,
		"opening_value": _opening_value(controller.state),
	}

func _opening_value(state: RefCounted) -> float:
	return (
		float(state.paper_progress)
		+ float(state.charts) * 6.0
		+ float(state.clean_data) * 2.5
		+ float(state.raw_data) * 0.75
		+ float(state.inspiration) * 0.35
		+ float(state.energy) * 1.5
		- float(state.technical_debt) * 1.25
	)

func _choose_candidate(controller: RefCounted, responsive: bool) -> int:
	var candidates: Array[StringName] = controller.candidates_for_today()
	var target_slot := _topic_target_slot(controller) if responsive else -1
	var best_index := 0
	var best_score := -1
	for index: int in range(candidates.size()):
		var card: Resource = controller.cards[candidates[index]]
		var slot := int(card.slot)
		var score := BASE_SLOT_SCORE[slot] + int(card.output_score_level_1)
		if slot == target_slot:
			score += 100
		elif slot == target_slot - 1:
			score += 45
		if score > best_score:
			best_score = score
			best_index = index
	return best_index

func _choose_overclock(controller: RefCounted, responsive: bool) -> int:
	if not responsive:
		return 1
	return _topic_target_slot(controller)

func _topic_target_slot(controller: RefCounted) -> int:
	return int(TARGET_SLOT.get(controller.cumulative_topic.target_resource(), 1))
