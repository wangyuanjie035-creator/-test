extends SceneTree

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const CANDIDATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_candidate_generator.gd")
const STATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_run_state.gd")
const SIMULATION_SCRIPT := preload("res://scripts/lab_engine/model/lab_simulation.gd")
const TOPIC_SCRIPT := preload("res://scripts/lab_engine/model/lab_cumulative_topic.gd")

const DEFAULT_START_SEED := 243000
const DEFAULT_SAMPLE_COUNT := 20
const DEFAULT_BEAM_WIDTH := 32
const FORMAL_SAMPLE_COUNT := 500
const DAY_COUNT := 8
const EXPERIMENT_SLOT := 1
const AUDITED_SLOTS: Array[int] = [0, 2, 3]

var _cards: Dictionary[StringName, Resource]


func _init() -> void:
	_cards = CATALOG_SCRIPT.new().build_cards()
	var options: Dictionary = _parse_options(OS.get_cmdline_user_args())
	if not bool(options.valid):
		push_error(String(options.error))
		_print_usage()
		quit(2)
		return
	var beam_widths: Array[int] = options.beam_widths
	if not String(options.export_prereg).is_empty() and beam_widths.back() != 512:
		push_error("--export-prereg requires the final beam width to be exactly 512")
		_print_usage()
		quit(2)
		return
	var reports: Array[Dictionary] = []
	for index: int in range(beam_widths.size()):
		reports.append(_run_audit(options, beam_widths[index], index == beam_widths.size() - 1))
	if not String(options.export_prereg).is_empty() and not bool(reports.back().prereg_ok):
		push_error("OPENING_COUNTERFACTUAL preregistration coverage is insufficient")
		quit(2)
		return
	var formal_samples: bool = int(options.samples) >= FORMAL_SAMPLE_COUNT
	var formal_widths: bool = beam_widths.size() >= 2 and beam_widths.front() >= 128 and beam_widths.back() >= 512
	var converged: bool = reports.size() >= 2 and _reports_converged(reports)
	var final_report: Dictionary = reports.back()
	var formal: bool = formal_samples and formal_widths and converged
	var verdict: String = "INCONCLUSIVE"
	if formal:
		verdict = "STRUCTURAL_LOCK" if bool(final_report.structural_lock) else "HEALTHY" if bool(final_report.healthy) else "MIXED"
	print("OPENING_COUNTERFACTUAL verdict=%s formal=%s formal_samples=%s formal_widths=%s converged=%s structural_lock=%s healthy=%s widths=%s" % [
		verdict, formal, formal_samples, formal_widths, converged, final_report.structural_lock, final_report.healthy, beam_widths,
	])
	quit(0)


func _run_audit(options: Dictionary, beam_width: int, print_details: bool) -> Dictionary:
	var start_seed: int = int(options.start_seed)
	var sample_count: int = int(options.samples)
	var co_offer_count: int = 0
	var experiment_unique_best_count: int = 0
	var non_experiment_locked_count: int = 0
	var non_experiment_near_best_count: int = 0
	var slot_appearances: Dictionary[int, int] = {}
	var slot_near_best: Dictionary[int, int] = {}
	var aggregate: Dictionary[StringName, Dictionary] = {}
	var prereg_entries: Array[Dictionary] = []

	print("OPENING_COUNTERFACTUAL config start_seed=%d samples=%d beam_width=%d formal_minimum=%d details=%s" % [
		start_seed, sample_count, beam_width, FORMAL_SAMPLE_COUNT, print_details,
	])
	for offset: int in range(sample_count):
		var seed: int = start_seed + offset
		var schedule: Array = CANDIDATE_SCRIPT.new().generate_schedule(_cards, seed)
		var day_one: Array[StringName] = _typed_candidates(schedule[0])
		if not _is_co_offer(day_one):
			continue
		co_offer_count += 1
		var branches: Array[Dictionary] = []
		for candidate_index: int in range(day_one.size()):
			var card_id: StringName = day_one[candidate_index]
			var branch: Dictionary = _search_fixed_opening(seed, schedule, candidate_index, beam_width)
			branch["card_id"] = card_id
			branch["slot"] = int(_cards[card_id].slot)
			branches.append(branch)
		var global_best_paper: int = _best_paper(branches)
		var global_can_win: bool = _any_branch_wins(branches)
		var best_branch_count: int = 0
		var experiment_is_best: bool = false
		var all_non_experiment_locked: bool = true
		var has_non_experiment_near_best: bool = false
		var adapted_slots_this_seed: Dictionary[int, bool] = {}
		var near_slots_this_seed: Dictionary[int, bool] = {}
		var near_non_experiment: Array[Dictionary] = []
		for branch: Dictionary in branches:
			var slot: int = int(branch.slot)
			var regret: int = global_best_paper - int(branch.best_paper)
			branch["regret"] = regret
			if regret == 0:
				best_branch_count += 1
				if slot == EXPERIMENT_SLOT:
					experiment_is_best = true
			if slot != EXPERIMENT_SLOT:
				var lost_reachable_win: bool = global_can_win and not bool(branch.can_win)
				if regret <= 10 and not lost_reachable_win:
					all_non_experiment_locked = false
				var near_best: bool = regret <= 5 and bool(branch.can_win) == global_can_win
				var prereg_eligible: bool = regret <= 5 and global_can_win and bool(branch.can_win)
				if near_best:
					has_non_experiment_near_best = true
				if prereg_eligible:
					near_non_experiment.append({
						"card_id": String(branch.card_id),
						"slot": slot,
						"can_win": bool(branch.can_win),
						"best_paper": int(branch.best_paper),
						"regret": regret,
					})
				if AUDITED_SLOTS.has(slot):
					adapted_slots_this_seed[slot] = true
					if near_best:
						near_slots_this_seed[slot] = true
			_accumulate(aggregate, branch)
		for slot: int in adapted_slots_this_seed:
			slot_appearances[slot] = int(slot_appearances.get(slot, 0)) + 1
		for slot: int in near_slots_this_seed:
			slot_near_best[slot] = int(slot_near_best.get(slot, 0)) + 1
		if experiment_is_best and best_branch_count == 1:
			experiment_unique_best_count += 1
		if all_non_experiment_locked:
			non_experiment_locked_count += 1
		if has_non_experiment_near_best:
			non_experiment_near_best_count += 1
			var candidate_ids: Array[String] = []
			for candidate_id: StringName in day_one:
				candidate_ids.append(String(candidate_id))
			prereg_entries.append({
				"seed": seed,
				"topic_id": String(TOPIC_SCRIPT.new(seed).topic_id),
				"candidates": candidate_ids,
				"global_best_paper": global_best_paper,
				"global_can_win": global_can_win,
				"near_non_experiment": near_non_experiment,
			})
		if print_details:
			print("OPENING_COUNTERFACTUAL seed=%d global_best=%d global_win=%s branches=%s" % [
				seed, global_best_paper, global_can_win, _format_branches(branches),
			])

	if print_details:
		_print_aggregate(aggregate)
	var unique_rate: float = _rate(experiment_unique_best_count, co_offer_count)
	var locked_rate: float = _rate(non_experiment_locked_count, co_offer_count)
	var near_rate: float = _rate(non_experiment_near_best_count, co_offer_count)
	var healthy_slots: int = 0
	for slot: int in AUDITED_SLOTS:
		var adapted: int = int(slot_appearances.get(slot, 0))
		var near: int = int(slot_near_best.get(slot, 0))
		var slot_rate: float = _rate(near, adapted)
		if adapted > 0 and slot_rate >= 10.0:
			healthy_slots += 1
		if print_details:
			print("OPENING_COUNTERFACTUAL slot=%d near_best=%d/%d (%.2f%%)" % [slot, near, adapted, slot_rate])
	var structural_lock: bool = unique_rate >= 75.0 and locked_rate >= 80.0
	var healthy: bool = near_rate >= 20.0 and healthy_slots >= 2
	print("OPENING_COUNTERFACTUAL summary width=%d co_offers=%d/%d experiment_unique_best=%d (%.2f%%) non_experiment_locked=%d (%.2f%%) non_experiment_near_best=%d (%.2f%%) healthy_slots=%d" % [
		beam_width, co_offer_count, sample_count, experiment_unique_best_count, unique_rate,
		non_experiment_locked_count, locked_rate, non_experiment_near_best_count, near_rate, healthy_slots,
	])
	var prereg_ok: bool = true
	if print_details and not String(options.export_prereg).is_empty():
		prereg_ok = _write_preregistration(
			String(options.export_prereg),
			prereg_entries,
			int(options.prereg_count),
			start_seed,
			sample_count,
			beam_width
		)
	return {
		"beam_width": beam_width, "co_offers": co_offer_count,
		"experiment_unique_best": experiment_unique_best_count,
		"non_experiment_locked": non_experiment_locked_count,
		"non_experiment_near_best": non_experiment_near_best_count,
		"healthy_slots": healthy_slots, "structural_lock": structural_lock, "healthy": healthy,
		"unique_rate": unique_rate, "locked_rate": locked_rate, "near_rate": near_rate,
		"prereg_ok": prereg_ok,
	}


func _write_preregistration(path: String, entries: Array[Dictionary], requested_count: int, start_seed: int, sample_count: int, beam_width: int) -> bool:
	var selected: Array[Dictionary] = _select_preregistration(entries, requested_count)
	var slot_exposures: Dictionary[int, int] = {0: 0, 2: 0, 3: 0}
	var unique_seeds: Dictionary[int, bool] = {}
	for entry: Dictionary in selected:
		unique_seeds[int(entry.seed)] = true
		var seen_slots: Dictionary[int, bool] = {}
		for branch: Dictionary in entry.near_non_experiment:
			var slot: int = int(branch.slot)
			if slot_exposures.has(slot):
				seen_slots[slot] = true
		for slot: int in seen_slots:
			slot_exposures[slot] += 1
	var coverage_ok: bool = (
		requested_count == 16
		and selected.size() == requested_count
		and unique_seeds.size() == requested_count
	)
	for slot: int in AUDITED_SLOTS:
		coverage_ok = coverage_ok and int(slot_exposures[slot]) >= 4
	if not coverage_ok:
		push_error("Preregistration selection does not satisfy 16 unique seeds and four exposures per audited slot")
		return false
	var payload: Dictionary = {
		"schema_version": 1,
		"generated_by": "audit_lab_opening_counterfactual.gd",
		"start_seed": start_seed,
		"samples": sample_count,
		"beam_width": beam_width,
		"requested_count": requested_count,
		"selection_rule": "ascending seeds; first fill each audited slot to four near-best exposures, then fill remaining seats ascending",
		"eligibility": "co-offer; global_can_win=true; non-experiment can_win=true; regret <= 5",
		"slot_exposures": slot_exposures,
		"coverage_ok": coverage_ok,
		"selected": selected,
	}
	if not _is_safe_project_json_path(path):
		push_error("Unsafe preregistration path: %s" % path)
		return false
	var absolute_path: String = ProjectSettings.globalize_path(path).simplify_path()
	var error: Error = DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if error != OK:
		push_error("Cannot create preregistration directory: %s" % error_string(error))
		return false
	var json_text: String = JSON.stringify(payload, "\t")
	if JSON.parse_string(json_text) == null:
		push_error("Generated preregistration JSON failed validation")
		return false
	var temporary_path: String = absolute_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write preregistration file: %s" % path)
		return false
	file.store_string(json_text)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		push_error("Cannot complete preregistration write: %s" % error_string(write_error))
		return false
	var written_text: String = FileAccess.get_file_as_string(temporary_path)
	if written_text != json_text or JSON.parse_string(written_text) == null:
		DirAccess.remove_absolute(temporary_path)
		push_error("Preregistration write verification failed")
		return false
	var backup_path: String = absolute_path + ".bak"
	DirAccess.remove_absolute(backup_path)
	if FileAccess.file_exists(absolute_path):
		error = DirAccess.rename_absolute(absolute_path, backup_path)
		if error != OK:
			DirAccess.remove_absolute(temporary_path)
			push_error("Cannot stage previous preregistration file: %s" % error_string(error))
			return false
	error = DirAccess.rename_absolute(temporary_path, absolute_path)
	if error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, absolute_path)
		push_error("Cannot publish preregistration file: %s" % error_string(error))
		return false
	DirAccess.remove_absolute(backup_path)
	print("OPENING_COUNTERFACTUAL preregistration selected=%d requested=%d slots=%s coverage_ok=%s path=%s" % [
		selected.size(), requested_count, slot_exposures, coverage_ok, path,
	])
	return coverage_ok


func _select_preregistration(entries: Array[Dictionary], requested_count: int) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	var selected_seeds: Dictionary[int, bool] = {}
	var slot_counts: Dictionary[int, int] = {0: 0, 2: 0, 3: 0}
	for entry: Dictionary in entries:
		if selected_seeds.has(int(entry.seed)):
			continue
		var contributing_slots: Array[int] = []
		for branch: Dictionary in entry.near_non_experiment:
			var slot: int = int(branch.slot)
			if slot_counts.has(slot) and int(slot_counts[slot]) < 4 and not contributing_slots.has(slot):
				contributing_slots.append(slot)
		if contributing_slots.is_empty():
			continue
		selected.append(entry)
		selected_seeds[int(entry.seed)] = true
		for slot: int in contributing_slots:
			slot_counts[slot] += 1
		if selected.size() >= requested_count:
			return selected
		var quotas_filled: bool = true
		for slot: int in AUDITED_SLOTS:
			quotas_filled = quotas_filled and int(slot_counts[slot]) >= 4
		if quotas_filled:
			break
	for entry: Dictionary in entries:
		if selected.size() >= requested_count:
			break
		if selected_seeds.has(int(entry.seed)):
			continue
		selected.append(entry)
		selected_seeds[int(entry.seed)] = true
	selected.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.seed) < int(right.seed)
	)
	return selected


func _is_safe_project_json_path(path: String) -> bool:
	if not path.begins_with("res://") or not path.ends_with(".json"):
		return false
	if path.trim_prefix("res://").split("/").has(".."):
		return false
	var project_root: String = ProjectSettings.globalize_path("res://").simplify_path().replace("\\", "/").trim_suffix("/")
	var absolute_path: String = ProjectSettings.globalize_path(path).simplify_path().replace("\\", "/")
	return absolute_path.begins_with(project_root + "/")


func _search_fixed_opening(seed: int, schedule: Array, candidate_index: int, beam_width: int) -> Dictionary:
	var card_id: StringName = StringName(schedule[0][candidate_index])
	# LabSimulation resets its per-day mutable buffers inside simulate_day(). Reuse one
	# instance per fixed-opening search so the card catalog is not rebuilt per branch.
	var simulation: RefCounted = SIMULATION_SCRIPT.new()
	var best_day_one_nodes: Array[Dictionary] = []
	for overclock_slot: int in range(-1, 5):
		var state: RefCounted = STATE_SCRIPT.new()
		var topic: RefCounted = TOPIC_SCRIPT.new(seed)
		state.install(_cards[card_id])
		var result: Dictionary = simulation.simulate_day(state, overclock_slot)
		if _all_nighter_redemption_failed(state, overclock_slot, result):
			continue
		var cold_start: StringName = _cold_start_reason(result, state)
		topic.record_day(state.day, result)
		state.day += 1
		best_day_one_nodes.append({
			"state": state,
			"topic": topic,
			"path": [{"choice": candidate_index, "card_id": card_id, "overclock": overclock_slot}],
			"d4": {},
			"cold_start": cold_start,
			"diagnostics": _updated_diagnostics({}, result, state, false, false),
		})
	var beam: Array[Dictionary] = _prune(best_day_one_nodes, beam_width)
	for day_index: int in range(1, DAY_COUNT):
		var next_nodes: Array[Dictionary] = []
		for node: Dictionary in beam:
			var source_state: RefCounted = node.state.duplicate_run()
			var source_topic: RefCounted = _duplicate_topic(node.topic, seed)
			if source_state.day == 4 and not source_topic.settled:
				source_topic.settle(source_state)
			simulation.determine_shutdown(source_state, seed)
			if source_state.energy <= 0:
				var rested: RefCounted = source_state
				var rest_result: Dictionary = {"events": []}
				source_topic.record_day(rested.day, rest_result)
				rested.energy = 3
				rested.day += 1
				next_nodes.append(_advanced_node(node, rested, source_topic, {"forced_rest": true}, day_index, rest_result, true, true))
				continue
			for choice_index: int in range(-1, 3):
				for overclock_slot: int in range(-1, 5):
					if overclock_slot >= 0 and overclock_slot == source_state.stopped_slot:
						continue
					var child: RefCounted = source_state.duplicate_run()
					var selected_id: StringName = &""
					if choice_index == -1:
						child.change_resource(&"technical_debt", -1)
						if not child.maintenance_ready:
							child.maintenance_ready = true
					else:
						selected_id = StringName(schedule[day_index][choice_index])
						child.install(_cards[selected_id])
					var result: Dictionary = simulation.simulate_day(child, overclock_slot)
					if _all_nighter_redemption_failed(child, overclock_slot, result):
						continue
					var child_topic: RefCounted = _duplicate_topic(source_topic, seed)
					child_topic.record_day(child.day, result)
					child.day += 1
					next_nodes.append(_advanced_node(node, child, child_topic, {
						"choice": choice_index, "card_id": selected_id, "overclock": overclock_slot,
					}, day_index, result, false, choice_index == -1))
		beam = _prune(next_nodes, beam_width)
	var best: Dictionary = _best_terminal(beam)
	var best_state: RefCounted = best.state
	return {
		"can_win": _beam_can_win(beam),
		"best_paper": int(best_state.paper_progress),
		"d4": best.d4,
		"cold_start": best.cold_start,
		"diagnostics": best.diagnostics,
		"path": best.path,
	}


func _advanced_node(parent: Dictionary, state: RefCounted, topic: RefCounted, step: Dictionary, day_index: int, result: Dictionary, forced_rest: bool, maintenance: bool) -> Dictionary:
	var path: Array = parent.path.duplicate()
	path.append(step)
	var d4: Dictionary = parent.d4.duplicate(true)
	if day_index == 3:
		d4 = _resource_snapshot(state)
	return {
		"state": state, "topic": topic, "path": path, "d4": d4, "cold_start": parent.cold_start,
		"diagnostics": _updated_diagnostics(parent.diagnostics, result, state, forced_rest, maintenance),
	}


func _prune(nodes: Array[Dictionary], beam_width: int) -> Array[Dictionary]:
	var best_by_signature: Dictionary[String, Dictionary] = {}
	for node: Dictionary in nodes:
		var signature: String = _signature(node.state, node.topic)
		var score: float = _node_score(node)
		node["_audit_signature"] = signature
		node["_audit_score"] = score
		if not best_by_signature.has(signature) or score > float(best_by_signature[signature]._audit_score):
			best_by_signature[signature] = node
	var unique_nodes: Array[Dictionary] = []
	for node: Dictionary in best_by_signature.values():
		unique_nodes.append(node)
	unique_nodes.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_score: float = float(left._audit_score)
		var right_score: float = float(right._audit_score)
		if left_score == right_score:
			return String(left._audit_signature) < String(right._audit_signature)
		return left_score > right_score
	)
	if unique_nodes.size() > beam_width:
		unique_nodes.resize(beam_width)
	return unique_nodes


func _node_score(node: Dictionary) -> float:
	var state: RefCounted = node.state
	var installed_levels: int = 0
	for entry: Dictionary in state.slots.values():
		installed_levels += int(entry.level)
	return (
		state.paper_progress * 1000.0 + state.charts * 90.0 + state.clean_data * 45.0
		+ state.raw_data * 12.0 + state.inspiration * 4.0 + state.energy * 18.0
		- state.technical_debt * 5.0 + installed_levels * 20.0
	)


func _signature(state: RefCounted, topic: RefCounted) -> String:
	var slot_parts: PackedStringArray = []
	for slot: int in range(6):
		var entry: Dictionary = state.slots[slot]
		slot_parts.append("%s:%s:%s" % [entry.card_id, entry.level, entry.days_installed])
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|topic:%s:%s:%s:%s" % [
		state.day, state.inspiration, state.raw_data, state.clean_data, state.charts,
		state.paper_progress, state.energy, state.technical_debt, state.stopped_slot,
		int(state.maintenance_ready), ",".join(slot_parts), topic.topic_id, topic.progress,
		topic.today_progress, int(topic.settled),
	]


func _best_terminal(beam: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = beam[0]
	for node: Dictionary in beam:
		var state: RefCounted = node.state
		var best_state: RefCounted = best.state
		if state.paper_progress > best_state.paper_progress:
			best = node
		elif state.paper_progress == best_state.paper_progress and _node_score(node) > _node_score(best):
			best = node
	return best


func _beam_can_win(beam: Array[Dictionary]) -> bool:
	for node: Dictionary in beam:
		if int(node.state.paper_progress) >= 100:
			return true
	return false


func _cold_start_reason(result: Dictionary, state: RefCounted) -> StringName:
	var successes: int = 0
	var first_failed_slot: int = -1
	for event: Dictionary in result.events:
		if bool(event.success):
			successes += 1
		elif first_failed_slot < 0 and StringName(event.get("failure_reason", &"")) == &"input_shortage":
			first_failed_slot = int(event.slot)
	if first_failed_slot >= 0:
		return StringName("resource_break_slot_%d" % first_failed_slot)
	if successes <= 2:
		return &"cold_idle"
	if state.technical_debt >= 4 or state.energy <= 4:
		return &"debt_energy_cost"
	return &"candidate_timing"


func _resource_snapshot(state: RefCounted) -> Dictionary:
	return {
		"inspiration": state.inspiration, "raw": state.raw_data, "clean": state.clean_data,
		"charts": state.charts, "paper": state.paper_progress, "debt": state.technical_debt,
		"energy": state.energy,
	}


func _is_co_offer(candidates: Array[StringName]) -> bool:
	var has_experiment: bool = false
	var has_non_experiment: bool = false
	for card_id: StringName in candidates:
		if int(_cards[card_id].slot) == EXPERIMENT_SLOT:
			has_experiment = true
		else:
			has_non_experiment = true
	return has_experiment and has_non_experiment


func _typed_candidates(source: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in source:
		result.append(StringName(value))
	return result


func _best_paper(branches: Array[Dictionary]) -> int:
	var result: int = 0
	for branch: Dictionary in branches:
		result = maxi(result, int(branch.best_paper))
	return result


func _any_branch_wins(branches: Array[Dictionary]) -> bool:
	for branch: Dictionary in branches:
		if bool(branch.can_win):
			return true
	return false


func _format_branches(branches: Array[Dictionary]) -> String:
	var parts: PackedStringArray = []
	for branch: Dictionary in branches:
		var d4: Dictionary = branch.d4
		parts.append("%s(slot=%d win=%s paper=%d regret=%d d4=%s cold=%s eight_day=%s)" % [
			branch.card_id, branch.slot, branch.can_win, branch.best_paper, branch.regret, d4,
			branch.cold_start, _diagnostic_summary(branch.diagnostics),
		])
	return "; ".join(parts)


func _accumulate(aggregate: Dictionary[StringName, Dictionary], branch: Dictionary) -> void:
	var card_id: StringName = branch.card_id
	var values: Dictionary = aggregate.get(card_id, {
		"runs": 0, "wins": 0, "paper": 0, "regret": 0,
		"resource_breaks": 0, "debt_energy_days": 0, "candidate_gaps": 0,
	})
	values.runs = int(values.runs) + 1
	values.wins = int(values.wins) + int(bool(branch.can_win))
	values.paper = int(values.paper) + int(branch.best_paper)
	values.regret = int(values.regret) + int(branch.regret)
	values.resource_breaks = int(values.resource_breaks) + int(branch.diagnostics.resource_breaks)
	values.debt_energy_days = int(values.debt_energy_days) + int(branch.diagnostics.debt_energy_days)
	values.candidate_gaps = int(values.candidate_gaps) + int(branch.diagnostics.candidate_gaps)
	aggregate[card_id] = values


func _print_aggregate(aggregate: Dictionary[StringName, Dictionary]) -> void:
	var ids: Array[StringName] = aggregate.keys()
	ids.sort()
	for card_id: StringName in ids:
		var values: Dictionary = aggregate[card_id]
		var runs: int = int(values.runs)
		print("OPENING_COUNTERFACTUAL candidate=%s slot=%d wins=%d/%d mean_paper=%.2f mean_regret=%.2f resource_breaks=%d debt_energy_days=%d candidate_gaps=%d" % [
			card_id, int(_cards[card_id].slot), int(values.wins), runs,
			int(values.paper) * 1.0 / runs, int(values.regret) * 1.0 / runs,
			int(values.resource_breaks), int(values.debt_energy_days), int(values.candidate_gaps),
		])


func _rate(numerator: int, denominator: int) -> float:
	return 0.0 if denominator <= 0 else numerator * 100.0 / denominator


func _duplicate_topic(source: RefCounted, seed: int) -> RefCounted:
	var copy: RefCounted = TOPIC_SCRIPT.new(seed)
	copy.topic_id = source.topic_id
	copy.progress = source.progress
	copy.today_progress = source.today_progress
	copy.settled = source.settled
	copy.settlement = source.settlement.duplicate(true)
	return copy


func _all_nighter_redemption_failed(state: RefCounted, overclock_slot: int, result: Dictionary) -> bool:
	if overclock_slot != 4 or StringName(state.slots[4].card_id) != &"all_nighter":
		return false
	for event: Dictionary in result.get("events", []):
		if int(event.get("slot", -1)) == 4 and int(event.get("type", -1)) == 1 and StringName(event.get("card_id", &"")) == &"all_nighter":
			return not bool(event.get("success", false))
	return true


func _updated_diagnostics(source: Dictionary, result: Dictionary, state: RefCounted, forced_rest: bool, maintenance: bool) -> Dictionary:
	var diagnostics: Dictionary = source.duplicate(true)
	if diagnostics.is_empty():
		diagnostics = {"resource_breaks": 0, "debt_energy_days": 0, "candidate_gaps": 0, "idle_triggers": 0}
	var successful_events: int = 0
	for event: Dictionary in result.get("events", []):
		if bool(event.get("success", false)):
			successful_events += 1
		elif StringName(event.get("failure_reason", &"")) == &"input_shortage":
			diagnostics.resource_breaks = int(diagnostics.resource_breaks) + 1
		diagnostics.idle_triggers = int(diagnostics.idle_triggers) + (0 if bool(event.get("success", false)) else 1)
	if state.technical_debt >= 7 or state.energy <= 1:
		diagnostics.debt_energy_days = int(diagnostics.debt_energy_days) + 1
	if forced_rest or maintenance or successful_events <= 2:
		diagnostics.candidate_gaps = int(diagnostics.candidate_gaps) + 1
	return diagnostics


func _diagnostic_summary(diagnostics: Dictionary) -> String:
	var resource_breaks: int = int(diagnostics.get("resource_breaks", 0))
	var debt_energy: int = int(diagnostics.get("debt_energy_days", 0))
	var candidate_gaps: int = int(diagnostics.get("candidate_gaps", 0))
	var main_reason: String = "resource_break" if resource_breaks >= maxi(debt_energy, candidate_gaps) and resource_breaks > 0 else "debt_energy" if debt_energy >= candidate_gaps and debt_energy > 0 else "candidate_gap" if candidate_gaps > 0 else "none"
	return "%s(resource=%d idle=%d debt_energy=%d candidate_gap=%d)" % [
		main_reason, resource_breaks, int(diagnostics.get("idle_triggers", 0)), debt_energy, candidate_gaps,
	]


func _reports_converged(reports: Array[Dictionary]) -> bool:
	var baseline: Dictionary = reports.back()
	for report: Dictionary in reports:
		if int(report.co_offers) != int(baseline.co_offers):
			return false
		if bool(report.structural_lock) != bool(baseline.structural_lock) or bool(report.healthy) != bool(baseline.healthy):
			return false
		for key: StringName in [&"unique_rate", &"locked_rate", &"near_rate"]:
			if absf(float(report[key]) - float(baseline[key])) > 2.0:
				return false
	return true


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {
		"start_seed": DEFAULT_START_SEED,
		"samples": DEFAULT_SAMPLE_COUNT,
		"beam_widths": [DEFAULT_BEAM_WIDTH] as Array[int],
		"valid": true,
		"error": "",
		"export_prereg": "",
		"prereg_count": 16,
	}
	var saw_single_width: bool = false
	var saw_multiple_widths: bool = false
	for argument: String in arguments:
		if argument == "--help":
			options.valid = false
			options.error = "usage requested"
			return options
		var parts: PackedStringArray = argument.split("=", true, 1)
		if parts.size() != 2 or parts[1].is_empty():
			options.valid = false
			options.error = "invalid argument syntax: %s" % argument
			return options
		if parts[0] == "--export-prereg":
			if not _is_safe_project_json_path(parts[1]):
				options.valid = false
				options.error = "--export-prereg must be a res:// JSON path"
				return options
			options.export_prereg = parts[1]
			continue
		if parts[0] == "--beam-widths":
			if saw_single_width:
				options.valid = false
				options.error = "--beam-width and --beam-widths are mutually exclusive"
				return options
			var widths: Array[int] = []
			for value: String in parts[1].split(","):
				if not value.is_valid_int() or int(value) < 8:
					options.valid = false
					options.error = "beam widths must be integers >= 8"
					return options
				var width: int = int(value)
				if not widths.has(width):
					widths.append(width)
			widths.sort()
			options.beam_widths = widths
			saw_multiple_widths = true
			continue
		if not parts[1].is_valid_int():
			options.valid = false
			options.error = "argument value must be an integer: %s" % argument
			return options
		var value: int = int(parts[1])
		match parts[0]:
			"--start-seed":
				if value < 1: options.valid = false
				else: options.start_seed = value
			"--samples":
				if value < 1: options.valid = false
				else: options.samples = value
			"--beam-width":
				if saw_multiple_widths or value < 8:
					options.valid = false
				else:
					options.beam_widths = [value] as Array[int]
					saw_single_width = true
			"--prereg-count":
				if value != 16:
					options.valid = false
				else:
					options.prereg_count = value
			_:
				options.valid = false
		if not bool(options.valid):
			options.error = "unknown or invalid argument: %s" % argument
			return options
	return options


func _print_usage() -> void:
	print("Usage: godot --headless --path <project> --script res://scripts/tools/audit_lab_opening_counterfactual.gd -- [--start-seed=N] [--samples=N] [--beam-width=N | --beam-widths=N,N] [--export-prereg=res://path.json] [--prereg-count=N]")
