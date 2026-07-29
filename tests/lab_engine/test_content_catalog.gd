extends "res://tests/lab_engine/lab_test_case.gd"

const CARD_SCRIPT := preload("res://scripts/lab_engine/data/lab_card_definition.gd")
const CATALOG_SCRIPT := preload("res://scripts/lab_engine/data/lab_content_catalog.gd")
const LEGACY_MANIFEST := {
	&"crawler": ["文献爬虫", 0, 0, 2, 3, true],
	&"subscription": ["关键词订阅", 0, 1, 2, 3, false],
	&"batch_experiment": ["批量实验脚本", 1, 2, 4, 5, true],
	&"unattended": ["夜间无人值守", 1, 3, 5, 6, true],
	&"cleaning": ["自动清洗管线", 2, 4, 4, 5, true],
	&"converter": ["祖传转换脚本", 2, 5, 5, 6, true],
	&"auto_stats": ["自动统计", 3, 6, 5, 6, true],
	&"parameter_scan": ["参数扫描", 3, 7, 6, 7, true],
	&"paper_template": ["自动论文模板", 4, 8, 6, 7, true],
	&"all_nighter": ["通宵拼稿", 4, 9, 7, 8, false],
	&"scheduler": ["祖传调度器", 5, 10, 1, 2, true],
	&"loop_guard": ["无限循环保护器", 5, 11, 1, 2, true],
}
const FROZEN_CANDIDATE_TAGS := {
	&"crawler": [&"early_producer"],
	&"subscription": [&"early_producer"],
	&"batch_experiment": [&"early_producer"],
	&"unattended": [&"early_producer"],
	&"cleaning": [&"mid_automation"],
	&"converter": [&"mid_automation"],
	&"auto_stats": [&"mid_automation"],
	&"parameter_scan": [&"mid_automation"],
	&"paper_template": [&"mid_automation", &"mid_anchor"],
	&"all_nighter": [],
	&"scheduler": [&"mid_automation", &"late_only"],
	&"loop_guard": [&"mid_automation"],
}

func run() -> Array[String]:
	var catalog: RefCounted = CATALOG_SCRIPT.new()
	var cards: Dictionary = catalog.build_cards()
	check_equal(cards.size(), 12, "catalog must load all card resources")
	check_equal(_sorted_ids(cards), _sorted_ids(LEGACY_MANIFEST), "catalog ids must match the frozen legacy set")
	var effects: Dictionary[int, bool] = {}
	var slots: Dictionary[int, int] = {}
	for id: StringName in cards:
		var card: Resource = cards[id]
		var expected: Array = LEGACY_MANIFEST[id]
		check_equal(card.get(&"id"), id, "catalog key must match resource id")
		check_equal(card.get(&"display_name"), expected[0], "%s title must preserve the legacy value" % id)
		check(not String(card.get(&"description")).is_empty(), "%s must have a description" % id)
		check(not (card.get(&"build_tags") as Array).is_empty(), "%s must have build tags" % id)
		var effect := int(card.get(&"effect"))
		var slot := int(card.get(&"slot"))
		check_equal(slot, expected[1], "%s slot must preserve the legacy value" % id)
		check_equal(effect, expected[2], "%s effect must preserve the legacy value" % id)
		check_equal(card.get(&"output_score_level_1"), expected[3], "%s level-one score must preserve the legacy value" % id)
		check_equal(card.get(&"output_score_level_2"), expected[4], "%s level-two score must preserve the legacy value" % id)
		check_equal(card.get(&"automation_card"), expected[5], "%s automation flag must preserve the legacy value" % id)
		check_equal(card.get(&"candidate_tags"), FROZEN_CANDIDATE_TAGS[id], "%s candidate tags must preserve the frozen pacing role" % id)
		check(not effects.has(effect), "effect %d must be unique" % effect)
		effects[effect] = true
		slots[slot] = int(slots.get(slot, 0)) + 1
	check_equal(effects.size(), 12, "all effect enum values must be represented once")
	for slot: int in range(6):
		check_equal(slots.get(slot, 0), 2, "each slot must contain two cards")
	_test_invalid_definitions(catalog)
	return failures

func _test_invalid_definitions(catalog: RefCounted) -> void:
	var invalid: Resource = CARD_SCRIPT.new()
	invalid.id = &""
	invalid.display_name = ""
	invalid.description = ""
	invalid.slot = 99
	invalid.effect = 99
	invalid.output_score_level_1 = 0
	invalid.output_score_level_2 = -1
	var unknown_tags: Array[StringName] = [&"unknown", &"stable", &"stable"]
	invalid.build_tags = unknown_tags
	var invalid_candidate_tags: Array[StringName] = [&"unknown", &"early_producer", &"early_producer"]
	invalid.candidate_tags = invalid_candidate_tags
	var duplicate: Resource = CARD_SCRIPT.new()
	duplicate.id = &"duplicate"
	duplicate.display_name = "重复"
	duplicate.description = "测试重复效果"
	duplicate.slot = 0
	duplicate.effect = 0
	duplicate.output_score_level_1 = 1
	duplicate.output_score_level_2 = 1
	var stable_tags: Array[StringName] = [&"stable"]
	duplicate.build_tags = stable_tags
	var errors: PackedStringArray = catalog.validate_definitions([invalid, duplicate, duplicate])
	var combined := "\n".join(errors)
	for expected: String in ["empty id", "no display name", "no description", "invalid slot", "invalid effect", "invalid output scores", "unknown build tag", "duplicates build tag", "unknown candidate tag", "duplicates candidate tag", "duplicates id", "duplicates effect"]:
		check(combined.contains(expected), "validator must reject %s" % expected)

func _sorted_ids(dictionary: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in dictionary:
		ids.append(id)
	ids.sort()
	return ids
