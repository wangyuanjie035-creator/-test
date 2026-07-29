@tool
extends RefCounted
class_name RouteState

const NODE_KIND_ENCOUNTER := &"encounter"
const NODE_KIND_EVENT := &"event"
const NODE_KIND_BOSS := &"boss"
const POST_MIDTERM_STANDARD_BOSS := &"B003"
const POST_MIDTERM_TRANSFER_EVENT := &"E005"
const POST_TRANSFER_FIRST_ENCOUNTER := &"N005"
const POST_TRANSFER_QUALIFICATION_BOSS := &"B004"
const POST_QUALIFICATION_FIRST_ENCOUNTER := &"N006"
const POST_DOCTOR2_FUNDING_EVENT := &"E006"
const POST_FUNDING_PROJECT_BOSS := &"B005"
const POST_PROJECT_MIDTERM_FIRST_ENCOUNTER := &"N007"
const POST_PREDEFENSE_BOSS := &"B006"
const POST_DOCTORAL_DEFENSE_BOSS := &"B007"
const POST_DOCTORAL_DELAY_REPAIR_EVENT := &"E007"
const POST_DELAY_REPAIR_ENCOUNTER := &"N008"
const POST_SUPPLEMENTARY_DEFENSE_BOSS := &"B008"
const DEFAULT_NODE_IDS := [&"N001", &"E001", &"N002", &"E004", &"N003", &"N004"]
const ROUTE_RNG_MODULUS := 2147483647
const ROUTE_CHOICE_SEED_OFFSET := 911
const DEFAULT_CHOICE_COLUMNS := [
	[&"N001"],
	[&"E001", &"N002", &"N003", &"E003", &"E008", &"N009"],
	[&"N002", &"E003", &"N003", &"E001", &"E004", &"E008", &"N009"],
	[&"E004", &"E003", &"N003", &"N002", &"E001", &"E008", &"N009"],
	[&"N004"],
	[&"B001"],
	[&"B002"],
	[POST_MIDTERM_STANDARD_BOSS, POST_MIDTERM_TRANSFER_EVENT],
]
# E005 作为转博分支事件接入，博士线按 N005 -> B004 -> N006 -> E006 -> B005 -> N007 -> B006 -> B007 逐段追加。
# B007 失败时可追加 E007，作为博士答辩延期后的博四返修入口。
# 博四短路线按 E007 -> N008 -> B008 逐段追加。

var node_ids: Array[StringName] = []
var node_kinds: Dictionary = {}
var completed_node_ids: Array[StringName] = []
var choice_columns: Array = []
var current_index: int = -1
var seed: int = 1


func setup(
	available_encounters: Dictionary,
	route_seed: int = 1,
	planned_node_ids: Array[StringName] = [],
	available_events: Dictionary = {},
	available_bosses: Dictionary = {}
) -> void:
	seed = route_seed
	node_ids.clear()
	node_kinds.clear()
	completed_node_ids.clear()
	choice_columns = _duplicate_choice_columns(DEFAULT_CHOICE_COLUMNS)

	var source_ids: Array = []
	if planned_node_ids.is_empty():
		for node_id: StringName in choice_columns[0]:
			source_ids.append(node_id)
	else:
		for node_id: StringName in planned_node_ids:
			source_ids.append(node_id)

	for raw_id: Variant in source_ids:
		var node_id := StringName(raw_id)
		if available_encounters.has(node_id):
			node_ids.append(node_id)
			node_kinds[node_id] = NODE_KIND_ENCOUNTER
		elif available_events.has(node_id):
			node_ids.append(node_id)
			node_kinds[node_id] = NODE_KIND_EVENT
		elif available_bosses.has(node_id):
			node_ids.append(node_id)
			node_kinds[node_id] = NODE_KIND_BOSS

	if node_ids.is_empty():
		var fallback_ids: Array[String] = []
		for raw_key: Variant in available_encounters.keys():
			fallback_ids.append(String(raw_key))
		for raw_key: Variant in available_events.keys():
			fallback_ids.append(String(raw_key))
		for raw_key: Variant in available_bosses.keys():
			fallback_ids.append(String(raw_key))
		fallback_ids.sort()
		for raw_id: String in fallback_ids:
			var node_id := StringName(raw_id)
			if available_encounters.has(node_id):
				node_ids.append(node_id)
				node_kinds[node_id] = NODE_KIND_ENCOUNTER
			elif available_events.has(node_id):
				node_ids.append(node_id)
				node_kinds[node_id] = NODE_KIND_EVENT
			elif available_bosses.has(node_id):
				node_ids.append(node_id)
				node_kinds[node_id] = NODE_KIND_BOSS

	if node_ids.is_empty():
		current_index = -1
	else:
		current_index = 0


func has_current_node() -> bool:
	return current_index >= 0 and current_index < node_ids.size()


func has_next_node() -> bool:
	return has_current_node() and _get_next_choice_column_index() < choice_columns.size()


func is_route_complete() -> bool:
	return has_current_node() and not has_next_node()


func get_current_node_id() -> StringName:
	if not has_current_node():
		return &""
	return node_ids[current_index]


func get_current_node_kind() -> StringName:
	var node_id := get_current_node_id()
	if node_id == &"":
		return &""
	return node_kinds.get(node_id, &"")


func is_current_encounter_node() -> bool:
	return get_current_node_kind() == NODE_KIND_ENCOUNTER


func is_current_event_node() -> bool:
	return get_current_node_kind() == NODE_KIND_EVENT


func is_current_boss_node() -> bool:
	return get_current_node_kind() == NODE_KIND_BOSS


func get_current_node_number() -> int:
	if current_index < 0:
		return 0
	if current_index >= node_ids.size():
		return node_ids.size()
	return current_index + 1


func get_total_nodes() -> int:
	return max(node_ids.size(), choice_columns.size())


func get_completed_node_count() -> int:
	return completed_node_ids.size()


func get_current_encounter(encounters: Dictionary) -> Variant:
	var node_id := get_current_node_id()
	if node_id == &"":
		return null
	if not is_current_encounter_node():
		return null
	return encounters.get(node_id)


func get_current_event(events: Dictionary) -> Variant:
	var node_id := get_current_node_id()
	if node_id == &"":
		return null
	if not is_current_event_node():
		return null
	return events.get(node_id)


func get_current_boss(bosses: Dictionary) -> Variant:
	var node_id := get_current_node_id()
	if node_id == &"":
		return null
	if not is_current_boss_node():
		return null
	return bosses.get(node_id)


func complete_current_node() -> bool:
	if not has_current_node():
		return false

	var completed_id := get_current_node_id()
	if not completed_node_ids.has(completed_id):
		completed_node_ids.append(completed_id)
	return true


func advance_to_next_node() -> bool:
	if not has_current_node():
		return false

	complete_current_node()

	if current_index + 1 < node_ids.size():
		current_index += 1
		return true

	if not has_next_node():
		current_index = node_ids.size()
	return false


func advance_to_node(node_id: StringName, available_encounters: Dictionary, available_events: Dictionary, available_bosses: Dictionary = {}) -> bool:
	if not has_current_node():
		return false
	if not _is_node_available(node_id, available_encounters, available_events, available_bosses):
		return false
	if completed_node_ids.has(node_id) or node_ids.has(node_id):
		return false

	complete_current_node()
	node_ids.append(node_id)
	node_kinds[node_id] = _get_node_kind_from_catalogs(node_id, available_encounters, available_events, available_bosses)
	current_index = node_ids.size() - 1
	return true


func get_next_node_choices(
	available_encounters: Dictionary,
	available_events: Dictionary,
	available_bosses: Dictionary = {},
	max_choices: int = 3,
	choice_weights: Dictionary = {}
) -> Array[StringName]:
	var choices: Array[StringName] = []
	if not has_next_node():
		return choices

	var column_index: int = _get_next_choice_column_index()
	while column_index < choice_columns.size() and choices.is_empty():
		var candidates: Array[StringName] = _get_available_choice_candidates(column_index, available_encounters, available_events, available_bosses)
		if _should_randomize_choice_candidates(candidates, available_bosses):
			var selection_seed: int = _get_choice_selection_seed(column_index, candidates)
			if _choice_scores_are_equal(candidates, choice_weights):
				candidates = _shuffle_choice_candidates(candidates, selection_seed)
			else:
				candidates = _select_choice_candidates_by_weight(candidates, max_choices, choice_weights, selection_seed)
		for node_id: StringName in candidates:
			if choices.size() < max_choices:
				choices.append(node_id)
		column_index += 1

	return choices


func to_id_strings() -> Array[String]:
	var output: Array[String] = []
	for node_id: StringName in node_ids:
		output.append(String(node_id))
	return output


func to_debug_dict() -> Dictionary:
	return {
		"node_ids": to_id_strings(),
		"node_kinds": _stringify_kind_dict(),
		"completed_node_ids": _stringify_ids(completed_node_ids),
		"current_index": current_index,
		"current_node_id": String(get_current_node_id()),
		"current_node_kind": String(get_current_node_kind()),
		"next_choice_column_index": _get_next_choice_column_index(),
		"has_next_node": has_next_node(),
	}


func _stringify_ids(ids: Array[StringName]) -> Array[String]:
	var output: Array[String] = []
	for id: StringName in ids:
		output.append(String(id))
	return output


func _stringify_kind_dict() -> Dictionary:
	var output: Dictionary = {}
	for node_id: StringName in node_ids:
		output[String(node_id)] = String(node_kinds.get(node_id, &""))
	return output


func _get_next_choice_column_index() -> int:
	return node_ids.size()


func _get_available_choice_candidates(column_index: int, available_encounters: Dictionary, available_events: Dictionary, available_bosses: Dictionary = {}) -> Array[StringName]:
	var candidates: Array[StringName] = []
	if column_index < 0 or column_index >= choice_columns.size():
		return candidates

	for raw_id: Variant in choice_columns[column_index]:
		var node_id := StringName(raw_id)
		if not _is_node_available(node_id, available_encounters, available_events, available_bosses):
			continue
		if completed_node_ids.has(node_id) or node_ids.has(node_id):
			continue
		candidates.append(node_id)
	return candidates


func _should_randomize_choice_candidates(candidates: Array[StringName], available_bosses: Dictionary = {}) -> bool:
	if candidates.size() <= 1:
		return false
	for node_id: StringName in candidates:
		if available_bosses.has(node_id):
			return false
	return true


func _shuffle_choice_candidates(candidates: Array[StringName], selection_seed: int) -> Array[StringName]:
	var shuffled: Array[StringName] = []
	for node_id: StringName in candidates:
		shuffled.append(node_id)
	if shuffled.size() <= 1:
		return shuffled

	var rng_seed: int = max(1, selection_seed)
	for index in range(shuffled.size() - 1, 0, -1):
		rng_seed = _mix_route_seed(rng_seed, index + 1)
		var swap_index: int = int(rng_seed % (index + 1))
		var current: StringName = shuffled[index]
		shuffled[index] = shuffled[swap_index]
		shuffled[swap_index] = current
	return shuffled


func _choice_scores_are_equal(candidates: Array[StringName], choice_weights: Dictionary) -> bool:
	if candidates.size() <= 1:
		return true

	var first_score: int = _get_choice_candidate_score(candidates[0], choice_weights)
	for node_id: StringName in candidates:
		if _get_choice_candidate_score(node_id, choice_weights) != first_score:
			return false
	return true


func _select_choice_candidates_by_weight(candidates: Array[StringName], max_count: int, choice_weights: Dictionary, selection_seed: int) -> Array[StringName]:
	var selectable: Array[StringName] = []
	for node_id: StringName in candidates:
		selectable.append(node_id)

	var selected: Array[StringName] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = max(1, selection_seed)

	while selected.size() < max_count and not selectable.is_empty():
		var total_weight: int = 0
		for node_id: StringName in selectable:
			total_weight += _get_choice_candidate_weight(node_id, choice_weights)

		var roll: int = rng.randi_range(1, max(1, total_weight))
		var accumulated: int = 0
		var selected_index: int = selectable.size() - 1
		for index in range(selectable.size()):
			accumulated += _get_choice_candidate_weight(selectable[index], choice_weights)
			if roll <= accumulated:
				selected_index = index
				break

		selected.append(selectable[selected_index])
		selectable.remove_at(selected_index)

	return selected


func _get_choice_candidate_weight(node_id: StringName, choice_weights: Dictionary) -> int:
	var score: int = _get_choice_candidate_score(node_id, choice_weights)
	return score * score


func _get_choice_candidate_score(node_id: StringName, choice_weights: Dictionary) -> int:
	var bonus: int = int(choice_weights.get(node_id, choice_weights.get(String(node_id), 0)))
	return max(1, 10 + max(0, bonus))


func _get_choice_selection_seed(column_index: int, candidates: Array[StringName]) -> int:
	var output: int = _mix_route_seed(seed, ROUTE_CHOICE_SEED_OFFSET + column_index)
	for node_id: StringName in node_ids:
		output = _mix_route_seed(output, _hash_route_text(String(node_id)))
	for node_id: StringName in candidates:
		output = _mix_route_seed(output, _hash_route_text(String(node_id)))
	return output


func _mix_route_seed(base_seed: int, salt: int) -> int:
	var mixed: int = int(base_seed) ^ int(salt * 1103515245)
	mixed = int((mixed * 1664525 + 1013904223) % ROUTE_RNG_MODULUS)
	if mixed < 0:
		mixed += ROUTE_RNG_MODULUS
	return max(1, mixed)


func _hash_route_text(text: String) -> int:
	var value: int = 2166136261
	for index in range(text.length()):
		value = int((value ^ text.unicode_at(index)) * 16777619) % ROUTE_RNG_MODULUS
	return max(1, value)


func _is_node_available(node_id: StringName, available_encounters: Dictionary, available_events: Dictionary, available_bosses: Dictionary = {}) -> bool:
	return available_encounters.has(node_id) or available_events.has(node_id) or available_bosses.has(node_id)


func _get_node_kind_from_catalogs(node_id: StringName, available_encounters: Dictionary, available_events: Dictionary, available_bosses: Dictionary = {}) -> StringName:
	if available_encounters.has(node_id):
		return NODE_KIND_ENCOUNTER
	if available_events.has(node_id):
		return NODE_KIND_EVENT
	if available_bosses.has(node_id):
		return NODE_KIND_BOSS
	return &""


func _duplicate_choice_columns(columns: Array) -> Array:
	var output: Array = []
	for column: Array in columns:
		var copied_column: Array[StringName] = []
		for raw_id: Variant in column:
			copied_column.append(StringName(raw_id))
		output.append(copied_column)
	return output
