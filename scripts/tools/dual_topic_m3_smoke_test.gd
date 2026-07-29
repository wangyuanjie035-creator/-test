extends RefCounted
class_name DualTopicM3SmokeTest

const RUN_MODEL := preload("res://scripts/dual_topic/model/dual_topic_run_model.gd")
const DECK_MODEL := preload("res://scripts/dual_topic/model/dual_topic_method_deck.gd")
const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")
const CATALOG := preload("res://data/dual_topic/methods/starter_method_catalog.tres")


func run() -> Array[String]:
	var failures: Array[String] = []
	_expect(CATALOG.is_valid_catalog(), "The 15-card catalog is invalid.", failures)
	_test_deterministic_draw(failures)
	_test_target_rules(failures)
	_test_distinct_method_routes(failures)
	_test_build_choices(failures)
	return failures


func _test_deterministic_draw(failures: Array[String]) -> void:
	var first: DualTopicMethodDeck = DECK_MODEL.new()
	var second: DualTopicMethodDeck = DECK_MODEL.new()
	var cards: Array[Resource] = _cards_as_resources()
	_expect(first.setup(240731, cards), "First deck setup failed.", failures)
	_expect(second.setup(240731, cards), "Second deck setup failed.", failures)
	first.draw_week_hand()
	second.draw_week_hand()
	_expect(
		JSON.stringify(first.to_debug_dict()) == JSON.stringify(second.to_debug_dict()),
		"Same seed should produce the same method-card order.",
		failures
	)


func _test_target_rules(failures: Array[String]) -> void:
	var deck: DualTopicMethodDeck = DECK_MODEL.new()
	deck.setup(240731, _cards_as_resources())
	deck.hand = [_card(&"targeted_reading")]
	var run: DualTopicRunModel = _new_run()
	var missing_target: Dictionary = deck.play_card(0, run)
	_expect(
		not bool(missing_target.get("success", false))
		and missing_target.get("reason", &"") == &"topic_target_required",
		"Topic cards must reject a missing target.",
		failures
	)
	_expect(deck.hand.size() == 1, "Rejected cards must remain in hand.", failures)


func _test_distinct_method_routes(failures: Array[String]) -> void:
	var investigation_run: DualTopicRunModel = _new_run()
	var investigation_topic: DualTopicState = investigation_run.topics[1]
	var wide_scan: Dictionary = investigation_run.perform_method_card(
		_card(&"cross_source_scan"),
		1
	)
	_expect(bool(wide_scan.get("success", false)), "Wide scan failed.", failures)
	_expect(
		_count_revealed(investigation_topic) == 2,
		"Investigation route should reveal both risk slots quickly.",
		failures
	)
	_expect(
		investigation_topic.evidence == 0,
		"Investigation route should reveal information without free evidence.",
		failures
	)

	var experiment_run: DualTopicRunModel = _new_run()
	var experiment_topic: DualTopicState = experiment_run.topics[1]
	experiment_run.perform_method_card(_card(&"targeted_reading"), 1)
	var experiment: Dictionary = experiment_run.perform_method_card(_card(&"stress_test"), 1)
	_expect(bool(experiment.get("success", false)), "Experiment route failed.", failures)
	_expect(
		experiment_topic.evidence > investigation_topic.evidence,
		"Experiment route should convert revealed uncertainty into evidence.",
		failures
	)
	_expect(
		_count_revealed(experiment_topic) == 1,
		"Experiment route should know less breadth than the wide investigation route.",
		failures
	)


func _test_build_choices(failures: Array[String]) -> void:
	var first: DualTopicMethodDeck = DECK_MODEL.new()
	var second: DualTopicMethodDeck = DECK_MODEL.new()
	var candidates: Array[Resource] = _cards_as_resources()
	first.setup(240731, candidates)
	second.setup(240731, candidates)
	var first_offer: Array[DualTopicMethodCardDefinition] = first.get_build_offer(2, candidates)
	var second_offer: Array[DualTopicMethodCardDefinition] = second.get_build_offer(2, candidates)
	_expect(first_offer.size() == 3, "Week two should offer three methods.", failures)
	_expect(
		_card_ids(first_offer) == _card_ids(second_offer),
		"Same seed should produce the same build offer.",
		failures
	)
	var add_result: Dictionary = first.apply_build_choice(2, 0)
	_expect(bool(add_result.get("success", false)), "Adding a method copy failed.", failures)
	_expect(first.deck_cards.size() == 16, "Adding should increase deck size to 16.", failures)
	_expect(
		first.get_build_offer(2, candidates).is_empty(),
		"A resolved build week must not offer again.",
		failures
	)

	var week_four_offer: Array[DualTopicMethodCardDefinition] = first.get_build_offer(4, candidates)
	var replacement_id: StringName = _find_replacement_id(
		first.deck_cards,
		week_four_offer[0].id
	)
	var replace_result: Dictionary = first.apply_build_choice(4, 0, replacement_id)
	_expect(bool(replace_result.get("success", false)), "Replacing a method failed.", failures)
	_expect(first.deck_cards.size() == 16, "Replacing must preserve deck size.", failures)
	_expect(first.build_changes == 2, "Exactly two build changes should be recorded.", failures)
	_expect(
		first.get_build_offer(4, candidates).is_empty(),
		"The two-change cap should close further offers.",
		failures
	)


func _new_run() -> DualTopicRunModel:
	var run: DualTopicRunModel = RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	run.setup(240731, definitions)
	return run


func _card(id: StringName) -> DualTopicMethodCardDefinition:
	for resource: Resource in CATALOG.cards:
		var card: DualTopicMethodCardDefinition = resource as DualTopicMethodCardDefinition
		if card.id == id:
			return card
	return null


func _cards_as_resources() -> Array[Resource]:
	var resources: Array[Resource] = []
	for card: Resource in CATALOG.cards:
		resources.append(card)
	return resources


func _card_ids(cards: Array[DualTopicMethodCardDefinition]) -> Array[String]:
	var result: Array[String] = []
	for card: DualTopicMethodCardDefinition in cards:
		result.append(String(card.id))
	return result


func _find_replacement_id(
	cards: Array[DualTopicMethodCardDefinition],
	excluded_id: StringName
) -> StringName:
	for card: DualTopicMethodCardDefinition in cards:
		if card.id != excluded_id:
			return card.id
	return &""


func _count_revealed(topic: DualTopicState) -> int:
	var result: int = 0
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN:
			result += 1
	return result


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
