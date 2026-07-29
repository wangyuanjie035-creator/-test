class_name LabContentCatalog
extends RefCounted

const EXPECTED_CARD_COUNT := 12
const ALLOWED_BUILD_TAGS: Array[StringName] = [&"stable", &"automation", &"debt_burst"]
const ALLOWED_CANDIDATE_TAGS: Array[StringName] = [&"early_producer", &"mid_automation", &"late_only", &"mid_anchor"]
const CARD_RESOURCES: Array[Resource] = [
	preload("res://data/lab_engine/cards/crawler.tres"),
	preload("res://data/lab_engine/cards/subscription.tres"),
	preload("res://data/lab_engine/cards/batch_experiment.tres"),
	preload("res://data/lab_engine/cards/unattended.tres"),
	preload("res://data/lab_engine/cards/cleaning.tres"),
	preload("res://data/lab_engine/cards/converter.tres"),
	preload("res://data/lab_engine/cards/auto_stats.tres"),
	preload("res://data/lab_engine/cards/parameter_scan.tres"),
	preload("res://data/lab_engine/cards/paper_template.tres"),
	preload("res://data/lab_engine/cards/all_nighter.tres"),
	preload("res://data/lab_engine/cards/scheduler.tres"),
	preload("res://data/lab_engine/cards/loop_guard.tres"),
]

func build_cards() -> Dictionary[StringName, Resource]:
	var errors := validate_definitions(CARD_RESOURCES)
	assert(errors.is_empty(), "Invalid lab card data:\n%s" % "\n".join(errors))
	var cards: Dictionary[StringName, Resource] = {}
	for card: Resource in CARD_RESOURCES:
		var card_id: StringName = card.get(&"id")
		cards[card_id] = card
	return cards

func validate_definitions(definitions: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary[StringName, bool] = {}
	var seen_effects: Dictionary[int, bool] = {}
	var slot_counts: Dictionary[int, int] = {}
	var candidate_tag_counts: Dictionary[StringName, int] = {}
	if definitions.size() != EXPECTED_CARD_COUNT:
		errors.append("catalog must contain %d cards, got %d" % [EXPECTED_CARD_COUNT, definitions.size()])
	for index: int in range(definitions.size()):
		var card: Variant = definitions[index]
		var prefix := "card[%d]" % index
		if not card is LabCardDefinition:
			errors.append("%s is not a LabCardDefinition" % prefix)
			continue
		var card_id: StringName = card.get(&"id")
		if card_id == &"":
			errors.append("%s has an empty id" % prefix)
		elif seen_ids.has(card_id):
			errors.append("%s duplicates id '%s'" % [prefix, card_id])
		else:
			seen_ids[card_id] = true
		if String(card.get(&"display_name")).strip_edges().is_empty():
			errors.append("%s has no display name" % prefix)
		if String(card.get(&"description")).strip_edges().is_empty():
			errors.append("%s has no description" % prefix)
		var slot := int(card.get(&"slot"))
		var effect := int(card.get(&"effect"))
		if slot < 0 or slot >= LabCardDefinition.Slot.size():
			errors.append("%s has invalid slot %s" % [prefix, slot])
		else:
			slot_counts[slot] = int(slot_counts.get(slot, 0)) + 1
		if effect < 0 or effect >= LabCardDefinition.Effect.size():
			errors.append("%s has invalid effect %s" % [prefix, effect])
		elif seen_effects.has(effect):
			errors.append("%s duplicates effect %s" % [prefix, effect])
		else:
			seen_effects[effect] = true
		var score_1 := int(card.get(&"output_score_level_1"))
		var score_2 := int(card.get(&"output_score_level_2"))
		if score_1 <= 0 or score_2 < score_1:
			errors.append("%s has invalid output scores" % prefix)
		var tags: Array = card.get(&"build_tags")
		if tags.is_empty():
			errors.append("%s has no build tags" % prefix)
		var seen_tags: Dictionary[StringName, bool] = {}
		for tag: StringName in tags:
			if tag == &"":
				errors.append("%s has an empty build tag" % prefix)
			elif not ALLOWED_BUILD_TAGS.has(tag):
				errors.append("%s has unknown build tag '%s'" % [prefix, tag])
			elif seen_tags.has(tag):
				errors.append("%s duplicates build tag '%s'" % [prefix, tag])
			else:
				seen_tags[tag] = true
		var candidate_tags: Array = card.get(&"candidate_tags")
		var seen_candidate_tags: Dictionary[StringName, bool] = {}
		for tag: StringName in candidate_tags:
			if not ALLOWED_CANDIDATE_TAGS.has(tag):
				errors.append("%s has unknown candidate tag '%s'" % [prefix, tag])
			elif seen_candidate_tags.has(tag):
				errors.append("%s duplicates candidate tag '%s'" % [prefix, tag])
			else:
				seen_candidate_tags[tag] = true
				candidate_tag_counts[tag] = int(candidate_tag_counts.get(tag, 0)) + 1
	for slot: int in range(LabCardDefinition.Slot.size()):
		if int(slot_counts.get(slot, 0)) != 2:
			errors.append("slot %d must contain exactly 2 cards" % slot)
	if int(candidate_tag_counts.get(&"early_producer", 0)) < 1:
		errors.append("catalog requires at least 1 early_producer card")
	if int(candidate_tag_counts.get(&"mid_automation", 0)) < 2:
		errors.append("catalog requires at least 2 mid_automation cards")
	for tag: StringName in [&"late_only", &"mid_anchor"]:
		if int(candidate_tag_counts.get(tag, 0)) != 1:
			errors.append("catalog requires exactly 1 card for candidate tag '%s'" % tag)
	return errors
