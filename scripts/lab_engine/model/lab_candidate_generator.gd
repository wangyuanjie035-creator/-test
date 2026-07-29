class_name LabCandidateGenerator
extends RefCounted

func generate_schedule(cards: Dictionary, seed: int) -> Array:
	var stable_ids: Array[StringName] = []
	for id: StringName in cards:
		stable_ids.append(id)
	stable_ids.sort_custom(func(left: StringName, right: StringName) -> bool:
		return String(left) < String(right)
	)
	var early_producers := _ids_with_candidate_tag(cards, &"early_producer")
	var mid_automation := _ids_with_candidate_tag(cards, &"mid_automation")
	var late_only := _single_id_with_candidate_tag(cards, &"late_only")
	var mid_anchor := _single_id_with_candidate_tag(cards, &"mid_anchor")
	assert(not early_producers.is_empty(), "candidate catalog requires early_producer tags")
	assert(not mid_automation.is_empty(), "candidate catalog requires mid_automation tags")
	var canonical_pool: Array[StringName] = []
	for id: StringName in stable_ids:
		canonical_pool.append(id)
		canonical_pool.append(id)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = maxi(1, seed)
	for _attempt: int in range(32):
		var pool: Array[StringName] = canonical_pool.duplicate()
		_shuffle(pool, rng)
		for _pass: int in range(4):
			_repair_daily_duplicates(pool)
			_ensure_days(pool, 0, 2, early_producers)
			_ensure_days(pool, 2, 5, mid_automation)
			_delay_card(pool, late_only)
			_pace_card(pool, mid_anchor)
			_repair_daily_duplicates(pool)
		if not _pool_is_valid(cards, pool, late_only, mid_anchor):
			continue
		return _schedule_from_pool(pool)
	assert(false, "candidate pacing could not be satisfied after deterministic retries")
	return []

func _pool_is_valid(cards: Dictionary, pool: Array[StringName], late_only: StringName, mid_anchor: StringName) -> bool:
	if not _days_have_tagged_card(cards, pool, 0, 2, &"early_producer"):
		return false
	if not _days_have_tagged_card(cards, pool, 2, 5, &"mid_automation"):
		return false
	if not _card_absent_from_days(pool, late_only, 0, 5):
		return false
	if not _days_have_card(pool, mid_anchor, [2, 3]):
		return false
	for day_index: int in range(8):
		var base: int = day_index * 3
		if pool[base] == pool[base + 1] or pool[base] == pool[base + 2] or pool[base + 1] == pool[base + 2]:
			return false
	return true

func _schedule_from_pool(pool: Array[StringName]) -> Array:
	var schedule: Array = []
	for day_index: int in range(8):
		var choices: Array[StringName] = []
		for offset: int in range(3):
			choices.append(pool[day_index * 3 + offset])
		schedule.append(choices)
	return schedule

func _ids_with_candidate_tag(cards: Dictionary, tag: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in cards:
		var tags: Array = cards[id].get(&"candidate_tags")
		if tags.has(tag):
			ids.append(id)
	ids.sort()
	return ids

func _single_id_with_candidate_tag(cards: Dictionary, tag: StringName) -> StringName:
	var ids := _ids_with_candidate_tag(cards, tag)
	assert(ids.size() == 1, "candidate tag '%s' requires exactly one card" % tag)
	return ids[0]

func _days_have_tagged_card(cards: Dictionary, pool: Array[StringName], start_day: int, end_day: int, tag: StringName) -> bool:
	for day_index: int in range(start_day, end_day):
		var base := day_index * 3
		var found := false
		for offset: int in range(3):
			var tags: Array = cards[pool[base + offset]].get(&"candidate_tags")
			if tags.has(tag):
				found = true
				break
		if not found:
			return false
	return true

func _card_absent_from_days(pool: Array[StringName], id: StringName, start_day: int, end_day: int) -> bool:
	for day_index: int in range(start_day, end_day):
		if _day_has(pool, day_index * 3, id):
			return false
	return true

func _days_have_card(pool: Array[StringName], id: StringName, days: Array) -> bool:
	for day_index: int in days:
		if not _day_has(pool, day_index * 3, id):
			return false
	return true

func _ensure_days(pool: Array[StringName], start_day: int, end_day: int, allowed: Array[StringName]) -> void:
	for day_index: int in range(start_day, end_day):
		var base: int = day_index * 3
		if allowed.has(pool[base]) or allowed.has(pool[base + 1]) or allowed.has(pool[base + 2]):
			continue
		for search_index: int in range((day_index + 1) * 3, pool.size()):
			if allowed.has(pool[search_index]) and not _day_has(pool, base, pool[search_index]):
				var temporary: StringName = pool[base]
				pool[base] = pool[search_index]
				pool[search_index] = temporary
				break

func _day_has(pool: Array[StringName], base: int, id: StringName) -> bool:
	return pool[base] == id or pool[base + 1] == id or pool[base + 2] == id

func _repair_daily_duplicates(pool: Array[StringName]) -> void:
	for day_index: int in range(8):
		var base: int = day_index * 3
		for offset: int in range(1, 3):
			var index: int = base + offset
			if not _has_elsewhere_in_day(pool, index, pool[index]):
				continue
			for swap_index: int in range(index + 1, pool.size()):
				if swap_index / 3 == day_index:
					continue
				if _has_elsewhere_in_day(pool, index, pool[swap_index]):
					continue
				if _has_elsewhere_in_day(pool, swap_index, pool[index]):
					continue
				var temporary: StringName = pool[index]
				pool[index] = pool[swap_index]
				pool[swap_index] = temporary
				break

func _has_elsewhere_in_day(pool: Array[StringName], index: int, id: StringName) -> bool:
	var base: int = (index / 3) * 3
	for candidate_index: int in range(base, base + 3):
		if candidate_index != index and pool[candidate_index] == id:
			return true
	return false

func _delay_card(pool: Array[StringName], delayed_id: StringName) -> void:
	var early_indices: Array[int] = []
	for index: int in range(15):
		if pool[index] == delayed_id:
			early_indices.append(index)
	for early_index: int in early_indices:
		for swap_index: int in range(15, pool.size()):
			if pool[swap_index] == delayed_id:
				continue
			if _has_elsewhere_in_day(pool, early_index, pool[swap_index]):
				continue
			if _has_elsewhere_in_day(pool, swap_index, delayed_id):
				continue
			var temporary: StringName = pool[early_index]
			pool[early_index] = pool[swap_index]
			pool[swap_index] = temporary
			break

func _pace_card(pool: Array[StringName], anchor_id: StringName) -> void:
	var target_days: Array[int] = [2, 3]
	for target_day: int in target_days:
		var target_base: int = target_day * 3
		if _day_has(pool, target_base, anchor_id):
			continue
		for source_index: int in range(pool.size()):
			if pool[source_index] != anchor_id or source_index / 3 in target_days:
				continue
			for target_offset: int in range(2, -1, -1):
				var target_index: int = target_base + target_offset
				if _has_elsewhere_in_day(pool, source_index, pool[target_index]):
					continue
				var temporary: StringName = pool[target_index]
				pool[target_index] = pool[source_index]
				pool[source_index] = temporary
				break
			break

func _shuffle(pool: Array[StringName], rng: RandomNumberGenerator) -> void:
	for index: int in range(pool.size() - 1, 0, -1):
		var target: int = rng.randi_range(0, index)
		var temporary: StringName = pool[index]
		pool[index] = pool[target]
		pool[target] = temporary
