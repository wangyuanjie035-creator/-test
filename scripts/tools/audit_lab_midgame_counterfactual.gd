extends SceneTree

const CONTROLLER_SCRIPT := preload("res://scripts/lab_engine/run/lab_run_controller.gd")

const DEFAULT_START_SEED := 245000
const DEFAULT_SAMPLES := 4
const DEFAULT_BEAM_WIDTH := 16
const PROTOTYPE_REASON := "prototype_requires_controlled_pairs_and_convergence"
const NEAR_PAPER_TOLERANCE := 5
const NEAR_DEBT_TOLERANCE := 2
const ENTRY_POLICIES: Array[StringName] = [&"expansion", &"topic", &"risk"]
const CATEGORIES: Array[StringName] = [&"expansion", &"pursuit", &"risk"]
const TOPIC_SLOT: Dictionary[StringName, int] = {
	&"inspiration": 0, &"raw_data": 1, &"clean_data": 2, &"charts": 3,
}

var _snapshot_results: Array[Dictionary] = []


func _init() -> void:
	var options: Dictionary = _parse_options(OS.get_cmdline_user_args())
	if not bool(options.valid):
		push_error(String(options.error))
		_print_usage()
		quit(2)
		return
	var start_ms: int = Time.get_ticks_msec()
	print("MIDGAME_AUDIT config start_seed=%d samples=%d beam_width=%d near_paper=%d near_debt=%d" % [
		options.start_seed, options.samples, options.beam_width,
		NEAR_PAPER_TOLERANCE, NEAR_DEBT_TOLERANCE,
	])
	for offset: int in range(int(options.samples)):
		var seed: int = int(options.start_seed) + offset
		for policy: StringName in ENTRY_POLICIES:
			for target_day: int in range(3, 6):
				var prefix: Array[Dictionary] = _build_entry_prefix(seed, target_day, policy)
				if prefix.size() != target_day - 1:
					continue
				var result: Dictionary = _audit_snapshot(seed, target_day, policy, prefix, int(options.beam_width))
				if not result.is_empty():
					_snapshot_results.append(result)
					print("MIDGAME_AUDIT snapshot seed=%d day=%d entry=%s debt=%d topic=%s chain=%s stopped=%d best=%s near=%s paper=%d final_debt=%d seq=%s" % [
						seed, target_day, policy, result.debt, result.topic_band, result.chain_closed,
						result.stopped_slot, result.best_category, result.near_categories,
						result.best_paper, result.best_debt, result.best_sequence,
					])
	var report: Dictionary = _summarize(int(options.samples))
	var elapsed_ms: int = Time.get_ticks_msec() - start_ms
	print("MIDGAME_AUDIT elapsed_ms=%d snapshots=%d" % [elapsed_ms, _snapshot_results.size()])
	print("MIDGAME_AUDIT verdict=%s formal=%s reason=%s" % [report.verdict, report.formal, report.reason])
	quit(0)


func _build_entry_prefix(seed: int, target_day: int, policy: StringName) -> Array[Dictionary]:
	var path: Array[Dictionary] = []
	while path.size() < target_day - 1:
		var controller: RefCounted = _replay(seed, path, false)
		if controller == null or controller.finished:
			break
		var preview: Dictionary = controller.begin_day()
		if bool(preview.get("forced_rest", false)):
			path.append({"card_id": &"", "maintenance": false, "forced_rest": true, "overclock": -1})
			continue
		var action: Dictionary = _policy_action(controller, policy)
		if action.is_empty():
			break
		path.append(action)
	return path


func _audit_snapshot(seed: int, day: int, entry_policy: StringName, prefix: Array[Dictionary], beam_width: int) -> Dictionary:
	var prepared: RefCounted = _replay(seed, prefix, true)
	if prepared == null or prepared.finished or int(prepared.state.day) != day:
		return {}
	var snapshot: Dictionary = _snapshot_descriptor(prepared)
	var legal_actions: Array[Dictionary] = _legal_actions(seed, prefix)
	if legal_actions.is_empty():
		return {}
	var outcomes: Array[Dictionary] = []
	for action: Dictionary in legal_actions:
		var terminal: Dictionary = _search_continuation(seed, prefix + [action], beam_width)
		if terminal.is_empty():
			continue
		terminal["first_category"] = action.category
		terminal["first_action"] = action
		outcomes.append(terminal)
	if outcomes.is_empty():
		return {}
	outcomes.sort_custom(_outcome_better)
	var best: Dictionary = outcomes[0]
	var near_categories: Array[StringName] = []
	var near_sequences: Array[String] = []
	for outcome: Dictionary in outcomes:
		if not _is_near(outcome, best):
			continue
		var category: StringName = outcome.first_category
		if not near_categories.has(category):
			near_categories.append(category)
		var sequence: String = String(outcome.sequence)
		if not near_sequences.has(sequence):
			near_sequences.append(sequence)
	near_categories.sort()
	near_sequences.sort()
	var fixed: Dictionary = _fixed_result(seed, prefix)
	return {
		"seed": seed, "day": day, "entry_policy": entry_policy, "prefix": prefix,
		"debt": snapshot.debt, "debt_band": snapshot.debt_band,
		"topic_band": snapshot.topic_band, "chain_closed": snapshot.chain_closed,
		"charts_ready": snapshot.charts_ready, "maintenance_ready": snapshot.maintenance_ready,
		"stopped_slot": snapshot.stopped_slot, "offers": snapshot.offers,
		"best_category": best.first_category, "near_categories": near_categories,
		"best_paper": best.paper, "best_debt": best.debt, "best_win": best.win,
		"best_sequence": best.sequence, "near_sequences": near_sequences,
		"fixed_paper": fixed.get("paper", 0),
		"fixed_debt": fixed.get("debt", 10),
	}


func _search_continuation(seed: int, initial_path: Array, beam_width: int) -> Dictionary:
	var beam: Array[Dictionary] = [{"path": initial_path, "score": 0.0}]
	var terminals: Array[Dictionary] = []
	while not beam.is_empty():
		var next_nodes: Array[Dictionary] = []
		var seen: Dictionary[String, float] = {}
		for node: Dictionary in beam:
			var node_controller: RefCounted = _replay(seed, node.path, false)
			if node_controller == null:
				continue
			if node_controller.finished:
				terminals.append(_terminal_outcome(node_controller, node.path))
				continue
			var actions: Array[Dictionary] = _legal_actions(seed, node.path)
			for action: Dictionary in actions:
				var path: Array = node.path.duplicate(true)
				path.append(action)
				var controller: RefCounted = _replay(seed, path, false)
				if controller == null:
					continue
				var signature: String = _controller_signature(controller)
				var score: float = _beam_score(controller)
				if seen.has(signature) and seen[signature] >= score:
					continue
				seen[signature] = score
				next_nodes.append({"path": path, "score": score})
		next_nodes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
			if float(left.score) == float(right.score):
				return _path_key(left.path) < _path_key(right.path)
			return float(left.score) > float(right.score)
		)
		if next_nodes.size() > beam_width:
			next_nodes.resize(beam_width)
		beam = next_nodes
	if terminals.is_empty():
		return {}
	terminals.sort_custom(_outcome_better)
	return terminals[0]


func _legal_actions(seed: int, prefix: Array) -> Array[Dictionary]:
	var prepared: RefCounted = _replay(seed, prefix, true)
	if prepared == null or prepared.finished:
		return []
	if prepared.state.energy <= 0:
		return [{"card_id": &"", "maintenance": false, "forced_rest": true, "overclock": -1, "category": &"risk"}]
	var candidates: Array[StringName] = prepared.candidates_for_today()
	var scored: Array[Dictionary] = []
	for choice: int in range(-1, candidates.size()):
		for overclock: int in range(-1, 5):
			if overclock >= 0 and overclock == prepared.state.stopped_slot:
				continue
			var card_id: StringName = &"" if choice < 0 else candidates[choice]
			var action: Dictionary = {
				"card_id": card_id, "maintenance": choice < 0, "forced_rest": false,
				"overclock": overclock,
			}
			action["category"] = _categorize(prepared, action)
			var forecast: Dictionary = prepared.forecast_day(choice, overclock)
			if not bool(forecast.get("valid", false)):
				continue
			var card_score: int = 0 if choice < 0 else int(prepared.cards[candidates[choice]].output_score_level_1)
			scored.append({
				"action": action,
				"score": int(forecast.get("daily_progress", 0)) * 100 + int(forecast.get("trigger_count", 0)) * 2 + card_score,
			})
	scored.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		if int(left.score) == int(right.score):
			return _path_key([left.action]) < _path_key([right.action])
		return int(left.score) > int(right.score)
	)
	# The audit compares decision categories.  Retaining the strongest legal
	# representative of each category prevents card/overclock micro-variants
	# from consuming the entire continuation beam.
	var selected: Array[Dictionary] = []
	var selected_categories: Dictionary[StringName, bool] = {}
	for entry: Dictionary in scored:
		var action: Dictionary = entry.action
		var category: StringName = action.category
		if selected_categories.has(category):
			continue
		var trial_path: Array = prefix.duplicate(true)
		trial_path.append(action)
		if _replay(seed, trial_path, false) == null:
			continue
		selected_categories[category] = true
		selected.append(action)
	return selected


func _replay(seed: int, path: Array, prepare_next_day: bool) -> RefCounted:
	var controller: RefCounted = CONTROLLER_SCRIPT.new(seed)
	for step: Dictionary in path:
		if controller.finished:
			return null
		var preview: Dictionary = controller.begin_day()
		var result: Dictionary
		if bool(preview.get("forced_rest", false)):
			if not bool(step.get("forced_rest", false)):
				return null
			result = controller.play_day(-1, -1)
		else:
			var choice: int = -1
			if not bool(step.get("maintenance", false)):
				var card_id: StringName = StringName(step.get("card_id", &""))
				choice = controller.candidates_for_today().find(card_id)
				if choice < 0:
					return null
			result = controller.play_day(choice, int(step.get("overclock", -1)))
		if not bool(result.get("valid", false)):
			return null
	if prepare_next_day and not controller.finished:
		controller.begin_day()
	return controller


func _policy_action(controller: RefCounted, policy: StringName) -> Dictionary:
	var candidates: Array[StringName] = controller.candidates_for_today()
	if candidates.is_empty():
		return {}
	if policy == &"risk" and controller.state.technical_debt >= 6:
		return {"card_id": &"", "maintenance": true, "forced_rest": false, "overclock": -1, "category": &"risk"}
	var best_id: StringName = candidates[0]
	var best_score: int = -9999
	var target_slot: int = int(TOPIC_SLOT.get(controller.cumulative_topic.target_resource(), 1))
	for card_id: StringName in candidates:
		var card: Resource = controller.cards[card_id]
		var score: int = int(card.output_score_level_1) * 10
		if policy == &"topic" and (int(card.slot) == target_slot or int(card.slot) == 4):
			score += 100
		elif policy == &"expansion" and int(card.slot) in [0, 1, 2, 3]:
			score += 60
		elif policy == &"risk" and not bool(card.automation_card):
			score += 60
		if score > best_score:
			best_score = score
			best_id = card_id
	var overclock: int = -1
	if controller.state.energy >= 3 and controller.state.technical_debt <= 5:
		overclock = target_slot if policy == &"topic" else 1
		if overclock == controller.state.stopped_slot:
			overclock = -1
	var action: Dictionary = {"card_id": best_id, "maintenance": false, "forced_rest": false, "overclock": overclock}
	action["category"] = _categorize(controller, action)
	return action


func _categorize(controller: RefCounted, action: Dictionary) -> StringName:
	if bool(action.get("maintenance", false)) or bool(action.get("forced_rest", false)):
		return &"risk"
	var card_id: StringName = StringName(action.card_id)
	var card: Resource = controller.cards[card_id]
	var target_slot: int = int(TOPIC_SLOT.get(controller.cumulative_topic.target_resource(), -1))
	if int(card.slot) == 4 or (not controller.cumulative_topic.settled and int(card.slot) == target_slot):
		return &"pursuit"
	return &"expansion"


func _fixed_result(seed: int, prefix: Array) -> Dictionary:
	var path: Array = prefix.duplicate(true)
	while true:
		var controller: RefCounted = _replay(seed, path, true)
		if controller == null:
			return {}
		if controller.finished:
			return {"paper": controller.state.paper_progress, "debt": controller.state.technical_debt}
		if controller.state.energy <= 0:
			path.append({"card_id": &"", "maintenance": false, "forced_rest": true, "overclock": -1, "category": &"risk"})
			continue
		var legal: Array[Dictionary] = _legal_actions(seed, path)
		if legal.is_empty():
			return {}
		var action: Dictionary = legal[0]
		for candidate: Dictionary in legal:
			if StringName(candidate.category) == &"expansion":
				action = candidate
				break
		path.append(action)
	return {}


func _terminal_outcome(controller: RefCounted, path: Array) -> Dictionary:
	var categories: PackedStringArray = []
	for index: int in range(2, mini(5, path.size())):
		categories.append(String(path[index].get("category", &"risk")))
	return {
		"win": controller.won, "paper": controller.state.paper_progress,
		"debt": controller.state.technical_debt, "energy": controller.state.energy,
		"sequence": ">".join(categories), "path": path,
	}


func _snapshot_descriptor(controller: RefCounted) -> Dictionary:
	var topic: Dictionary = controller.topic_snapshot()
	var remaining: int = maxi(0, int(topic.target) - int(topic.progress))
	var topic_band: StringName = &"settled" if bool(topic.settled) else &"ahead" if remaining == 0 else &"close" if remaining <= 2 else &"behind"
	var offers: PackedStringArray = []
	for id: StringName in controller.candidates_for_today():
		offers.append(String(id))
	return {
		"debt": controller.state.technical_debt,
		"debt_band": &"high" if controller.state.technical_debt >= 7 else &"medium" if controller.state.technical_debt >= 4 else &"low",
		"topic_band": topic_band,
		"chain_closed": _chain_closed(controller.state),
		"charts_ready": controller.state.charts > 0,
		"maintenance_ready": controller.state.maintenance_ready,
		"stopped_slot": controller.state.stopped_slot,
		"offers": offers,
	}


func _chain_closed(state: RefCounted) -> bool:
	for slot: int in range(5):
		if int(state.slots[slot].level) <= 0:
			return false
	return true


func _controller_signature(controller: RefCounted) -> String:
	return JSON.stringify({"state": controller.state.snapshot(), "topic": controller.topic_snapshot()})


func _beam_score(controller: RefCounted) -> float:
	return float(controller.state.paper_progress) * 1000.0 + float(controller.state.charts) * 80.0 + float(controller.state.clean_data) * 30.0 + float(controller.state.raw_data) * 8.0 + float(controller.state.energy) * 10.0 - float(controller.state.technical_debt) * 4.0


func _outcome_better(left: Dictionary, right: Dictionary) -> bool:
	if bool(left.win) != bool(right.win):
		return bool(left.win)
	if int(left.paper) != int(right.paper):
		return int(left.paper) > int(right.paper)
	if int(left.debt) != int(right.debt):
		return int(left.debt) < int(right.debt)
	return String(left.sequence) < String(right.sequence)


func _is_near(outcome: Dictionary, best: Dictionary) -> bool:
	return bool(outcome.win) == bool(best.win) and int(outcome.paper) >= int(best.paper) - NEAR_PAPER_TOLERANCE and int(outcome.debt) <= int(best.debt) + NEAR_DEBT_TOLERANCE


func _path_key(path: Array) -> String:
	var parts: PackedStringArray = []
	for step: Dictionary in path:
		parts.append("%s:%s:%s" % [step.get("card_id", &""), step.get("maintenance", false), step.get("overclock", -1)])
	return "|".join(parts)


func _summarize(_sample_count: int) -> Dictionary:
	var count: int = _snapshot_results.size()
	var nonfixed: int = 0
	var category_coverage: Dictionary[StringName, int] = {&"expansion": 0, &"pursuit": 0, &"risk": 0}
	var best_category_counts: Dictionary[StringName, int] = {&"expansion": 0, &"pursuit": 0, &"risk": 0}
	var sequence_counts: Dictionary[String, int] = {}
	var paper_deltas: Array[int] = []
	var debt_deltas: Array[int] = []
	for result: Dictionary in _snapshot_results:
		nonfixed += int(result.near_categories.size() >= 2)
		best_category_counts[result.best_category] = int(best_category_counts[result.best_category]) + 1
		for category: StringName in result.near_categories:
			category_coverage[category] = int(category_coverage[category]) + 1
		sequence_counts[result.best_sequence] = int(sequence_counts.get(result.best_sequence, 0)) + 1
		paper_deltas.append(int(result.best_paper) - int(result.fixed_paper))
		debt_deltas.append(int(result.fixed_debt) - int(result.best_debt))
	var contrasts: Dictionary = _observational_matched_contrasts()
	var contrast_rate: float = _rate(int(contrasts.changed), int(contrasts.valid))
	var nonfixed_rate: float = _rate(nonfixed, count)
	var top_sequence: int = _largest(sequence_counts)
	var top_sequence_rate: float = _rate(top_sequence, count)
	var top_day_rate: float = _rate(_largest(best_category_counts), count)
	var diagnostic_coverage_target_met: bool = true
	for category: StringName in CATEGORIES:
		var rate: float = _rate(int(category_coverage[category]), count)
		diagnostic_coverage_target_met = diagnostic_coverage_target_met and rate >= 15.0
		print("MIDGAME_AUDIT category=%s near_coverage=%d/%d (%.2f%%) best=%d" % [category, category_coverage[category], count, rate, best_category_counts[category]])
	var median_paper: int = _median(paper_deltas)
	var median_debt: int = _median(debt_deltas)
	print("MIDGAME_AUDIT summary observational_contrasts_changed=%d/%d (%.2f%%) observational_only=true causal_claim=false nonfixed=%d/%d (%.2f%%) top_sequence=%.2f%% top_day=%.2f%% median_paper_delta=%d median_debt_improvement=%d diagnostic_coverage_target_met=%s" % [
		contrasts.changed, contrasts.valid, contrast_rate, nonfixed, count, nonfixed_rate,
		top_sequence_rate, top_day_rate, median_paper, median_debt, diagnostic_coverage_target_met,
	])
	print("MIDGAME_AUDIT prototype formal=false reason=%s" % PROTOTYPE_REASON)
	return {"verdict": "INCONCLUSIVE", "formal": false, "reason": PROTOTYPE_REASON}


## These are naturally observed, descriptor-matched snapshots. They are useful for
## exploration but are not controlled pairs and cannot support a causal claim.
func _observational_matched_contrasts() -> Dictionary:
	var valid: int = 0
	var changed: int = 0
	for left_index: int in range(_snapshot_results.size()):
		var left: Dictionary = _snapshot_results[left_index]
		for right_index: int in range(left_index + 1, _snapshot_results.size()):
			var right: Dictionary = _snapshot_results[right_index]
			if int(left.seed) != int(right.seed) or int(left.day) != int(right.day) or left.offers != right.offers:
				continue
			var differences: int = 0
			for key: StringName in [&"debt_band", &"topic_band", &"chain_closed", &"charts_ready", &"maintenance_ready", &"stopped_slot"]:
				differences += int(left[key] != right[key])
			if differences != 1:
				continue
			valid += 1
			changed += int(left.near_categories != right.near_categories)
	return {"valid": valid, "changed": changed}


func _largest(counts: Dictionary) -> int:
	var result: int = 0
	for value: Variant in counts.values():
		result = maxi(result, int(value))
	return result


func _median(values: Array[int]) -> int:
	if values.is_empty():
		return 0
	values.sort()
	return values[values.size() / 2]


func _rate(numerator: int, denominator: int) -> float:
	return 0.0 if denominator <= 0 else numerator * 100.0 / denominator


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {"valid": true, "error": "", "start_seed": DEFAULT_START_SEED, "samples": DEFAULT_SAMPLES, "beam_width": DEFAULT_BEAM_WIDTH}
	for argument: String in arguments:
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() != 2 or not parts[1].is_valid_int():
			return {"valid": false, "error": "invalid argument: %s" % argument}
		var value: int = int(parts[1])
		match parts[0]:
			"--start-seed": options.start_seed = value
			"--samples": options.samples = value
			"--beam-width": options.beam_width = value
			_: return {"valid": false, "error": "unknown argument: %s" % argument}
	if int(options.start_seed) < 1 or int(options.samples) < 1 or int(options.beam_width) < 4:
		return {"valid": false, "error": "start-seed/samples must be >=1 and beam-width >=4"}
	return options


func _print_usage() -> void:
	print("Usage: godot --headless --path <project> --script res://scripts/tools/audit_lab_midgame_counterfactual.gd -- [--start-seed=N] [--samples=N] [--beam-width=N]")
