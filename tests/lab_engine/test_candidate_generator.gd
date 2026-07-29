extends "res://tests/lab_engine/lab_test_case.gd"

const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const CANDIDATE_SCRIPT := preload("res://scripts/lab_engine/model/lab_candidate_generator.gd")
const FROZEN_SEED_240731 := [
	[&"converter", &"unattended", &"parameter_scan"],
	[&"parameter_scan", &"loop_guard", &"batch_experiment"],
	[&"crawler", &"auto_stats", &"paper_template"],
	[&"paper_template", &"subscription", &"batch_experiment"],
	[&"converter", &"cleaning", &"auto_stats"],
	[&"scheduler", &"unattended", &"all_nighter"],
	[&"crawler", &"subscription", &"loop_guard"],
	[&"cleaning", &"scheduler", &"all_nighter"],
]

func run() -> Array[String]:
	var cards: Dictionary = CATALOG_SCRIPT.new().build_cards()
	var reversed_cards: Dictionary = {}
	var ids: Array = cards.keys()
	ids.reverse()
	for id: StringName in ids:
		reversed_cards[id] = cards[id]
	var generator: RefCounted = CANDIDATE_SCRIPT.new()
	var first: Array = generator.generate_schedule(cards, 240731)
	var reordered: Array = generator.generate_schedule(reversed_cards, 240731)
	check_equal(first, reordered, "same seed must ignore input dictionary order")
	check_equal(first, FROZEN_SEED_240731, "resource tags must preserve the frozen candidate schedule")
	check_equal(first.size(), 8, "schedule must contain eight days")
	var early_producers := _cards_with_tag(cards, &"early_producer")
	var mid_automation := _cards_with_tag(cards, &"mid_automation")
	for day_index: int in range(first.size()):
		var choices: Array = first[day_index]
		check_equal(choices.size(), 3, "each day must contain three candidates")
		var unique: Dictionary = {}
		for id: StringName in choices:
			unique[id] = true
		check_equal(unique.size(), 3, "daily candidates must be unique")
		if day_index < 2:
			check(_contains_any(choices, early_producers), "first two days must offer an early producer")
		elif day_index < 5:
			check(_contains_any(choices, mid_automation), "days three to five must offer automation")
	for regression_seed: int in [4806163, 6691285]:
		var recovered: Array = generator.generate_schedule(cards, regression_seed)
		check_equal(recovered.size(), 8, "deterministic retry must recover candidate pacing for known failing seeds")
		check_equal(recovered, generator.generate_schedule(cards, regression_seed), "recovered schedule must remain deterministic")
	return failures

func _cards_with_tag(cards: Dictionary, tag: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in cards:
		if (cards[id].get(&"candidate_tags") as Array).has(tag):
			ids.append(id)
	return ids

func _contains_any(choices: Array, allowed: Array[StringName]) -> bool:
	for id: StringName in choices:
		if allowed.has(id):
			return true
	return false
