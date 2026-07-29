extends RefCounted
class_name DualTopicMethodDeck

var draw_pile: Array[DualTopicMethodCardDefinition] = []
var discard_pile: Array[DualTopicMethodCardDefinition] = []
var hand: Array[DualTopicMethodCardDefinition] = []
var deck_cards: Array[DualTopicMethodCardDefinition] = []
var build_changes: int = 0
var resolved_build_weeks: Array[int] = []
var _run_seed: int = 1
var _build_offers: Dictionary[int, Array] = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(run_seed: int, starting_cards: Array[Resource]) -> bool:
	if starting_cards.size() != 15:
		push_error("DualTopicMethodDeck requires exactly 15 starting cards.")
		return false
	var validated_cards: Array[DualTopicMethodCardDefinition] = []
	for resource: Resource in starting_cards:
		if not resource is DualTopicMethodCardDefinition:
			push_error("DualTopicMethodDeck received a non-card resource.")
			return false
		var card: DualTopicMethodCardDefinition = resource as DualTopicMethodCardDefinition
		if not card.is_valid_definition():
			push_error("DualTopicMethodDeck received an invalid card.")
			return false
		validated_cards.append(card)
	_run_seed = max(1, run_seed)
	_rng.seed = _run_seed
	deck_cards = validated_cards.duplicate()
	draw_pile = validated_cards.duplicate()
	discard_pile.clear()
	hand.clear()
	build_changes = 0
	resolved_build_weeks.clear()
	_build_offers.clear()
	_shuffle(draw_pile)
	return true


func get_build_offer(
	week: int,
	candidate_cards: Array[Resource]
) -> Array[DualTopicMethodCardDefinition]:
	if week != 2 and week != 4:
		return []
	if build_changes >= 2 or resolved_build_weeks.has(week):
		return []
	if _build_offers.has(week):
		return _typed_offer(_build_offers[week])
	var candidates: Array[DualTopicMethodCardDefinition] = _validate_candidates(candidate_cards)
	if candidates.size() < 3:
		return []
	var offer_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	offer_rng.seed = _run_seed ^ (week * 104729)
	_shuffle_with_rng(candidates, offer_rng)
	var offer: Array[DualTopicMethodCardDefinition] = candidates.slice(0, 3)
	_build_offers[week] = offer
	return offer.duplicate()


func apply_build_choice(
	week: int,
	choice_index: int,
	replace_card_id: StringName = &""
) -> Dictionary:
	if build_changes >= 2:
		return {"success": false, "reason": &"change_limit_reached"}
	if resolved_build_weeks.has(week):
		return {"success": false, "reason": &"week_already_resolved"}
	if not _build_offers.has(week):
		return {"success": false, "reason": &"offer_not_generated"}
	var offer: Array[DualTopicMethodCardDefinition] = _typed_offer(_build_offers[week])
	if choice_index < 0 or choice_index >= offer.size():
		return {"success": false, "reason": &"invalid_choice"}
	var chosen: DualTopicMethodCardDefinition = offer[choice_index]
	var mode: StringName = &"add"
	if replace_card_id.is_empty():
		deck_cards.append(chosen)
		discard_pile.append(chosen)
	else:
		if replace_card_id == chosen.id:
			return {"success": false, "reason": &"same_card_replacement"}
		if not _replace_card(replace_card_id, chosen):
			return {"success": false, "reason": &"replace_card_not_found"}
		mode = &"replace"
	build_changes += 1
	resolved_build_weeks.append(week)
	_build_offers.erase(week)
	return {
		"success": true,
		"week": week,
		"mode": mode,
		"chosen_card_id": chosen.id,
		"replaced_card_id": replace_card_id,
		"deck_size": deck_cards.size(),
		"changes_used": build_changes,
	}


func draw_week_hand(draw_count: int = 5) -> Array[DualTopicMethodCardDefinition]:
	discard_hand()
	for index: int in range(maxi(0, draw_count)):
		if draw_pile.is_empty():
			_recycle_discard()
		if draw_pile.is_empty():
			break
		hand.append(draw_pile.pop_back())
	return hand.duplicate()


func cycle_hand_card(hand_index: int) -> Dictionary:
	if hand_index < 0 or hand_index >= hand.size():
		return {"success": false, "reason": &"invalid_hand_index"}
	if draw_pile.is_empty():
		_recycle_discard()
	if draw_pile.is_empty():
		return {"success": false, "reason": &"no_replacement_card"}
	var removed: DualTopicMethodCardDefinition = hand[hand_index]
	var drawn: DualTopicMethodCardDefinition = draw_pile.pop_back()
	hand[hand_index] = drawn
	discard_pile.append(removed)
	return {
		"success": true,
		"removed_card_id": removed.id,
		"removed_title": removed.title,
		"drawn_card_id": drawn.id,
		"drawn_title": drawn.title,
	}


func add_legacy_card(card: DualTopicMethodCardDefinition) -> bool:
	if card == null or not card.is_valid_definition():
		return false
	deck_cards.append(card)
	draw_pile.append(card)
	_shuffle(draw_pile)
	return true


func play_card(
	hand_index: int,
	run_model: DualTopicRunModel,
	topic_index: int = -1
) -> Dictionary:
	if hand_index < 0 or hand_index >= hand.size():
		return {"success": false, "reason": &"invalid_hand_index"}
	var card: DualTopicMethodCardDefinition = hand[hand_index]
	if card.target_scope == DualTopicMethodCardDefinition.TargetScope.TOPIC and topic_index < 0:
		return {"success": false, "reason": &"topic_target_required"}
	if card.target_scope == DualTopicMethodCardDefinition.TargetScope.SELF:
		topic_index = -1
	var result: Dictionary = run_model.perform_method_card(card, topic_index)
	if bool(result.get("success", false)):
		hand.remove_at(hand_index)
		discard_pile.append(card)
	return result


func discard_hand() -> void:
	discard_pile.append_array(hand)
	hand.clear()


func to_debug_dict() -> Dictionary:
	return {
		"draw": _ids(draw_pile),
		"discard": _ids(discard_pile),
		"hand": _ids(hand),
		"deck": _ids(deck_cards),
		"build_changes": build_changes,
		"resolved_build_weeks": resolved_build_weeks.duplicate(),
	}


func _recycle_discard() -> void:
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	_shuffle(draw_pile)


func _shuffle(cards: Array[DualTopicMethodCardDefinition]) -> void:
	_shuffle_with_rng(cards, _rng)


func _shuffle_with_rng(
	cards: Array[DualTopicMethodCardDefinition],
	rng: RandomNumberGenerator
) -> void:
	for index: int in range(cards.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current: DualTopicMethodCardDefinition = cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = current


func _validate_candidates(resources: Array[Resource]) -> Array[DualTopicMethodCardDefinition]:
	var candidates: Array[DualTopicMethodCardDefinition] = []
	var seen_ids: Dictionary[StringName, bool] = {}
	for resource: Resource in resources:
		if not resource is DualTopicMethodCardDefinition:
			continue
		var card: DualTopicMethodCardDefinition = resource as DualTopicMethodCardDefinition
		if card.is_valid_definition() and not seen_ids.has(card.id):
			candidates.append(card)
			seen_ids[card.id] = true
	return candidates


func _replace_card(
	old_card_id: StringName,
	new_card: DualTopicMethodCardDefinition
) -> bool:
	var deck_index: int = _find_card_index(deck_cards, old_card_id)
	if deck_index < 0:
		return false
	deck_cards[deck_index] = new_card
	if _replace_in_zone(hand, old_card_id, new_card):
		return true
	if _replace_in_zone(draw_pile, old_card_id, new_card):
		return true
	if _replace_in_zone(discard_pile, old_card_id, new_card):
		return true
	push_error("DualTopicMethodDeck composition and runtime piles diverged.")
	return false


func _replace_in_zone(
	zone: Array[DualTopicMethodCardDefinition],
	old_card_id: StringName,
	new_card: DualTopicMethodCardDefinition
) -> bool:
	var index: int = _find_card_index(zone, old_card_id)
	if index < 0:
		return false
	zone[index] = new_card
	return true


func _find_card_index(
	cards: Array[DualTopicMethodCardDefinition],
	card_id: StringName
) -> int:
	for index: int in range(cards.size()):
		if cards[index].id == card_id:
			return index
	return -1


func _typed_offer(value: Array) -> Array[DualTopicMethodCardDefinition]:
	var offer: Array[DualTopicMethodCardDefinition] = []
	for card: DualTopicMethodCardDefinition in value:
		offer.append(card)
	return offer


func _ids(cards: Array[DualTopicMethodCardDefinition]) -> Array[String]:
	var ids: Array[String] = []
	for card: DualTopicMethodCardDefinition in cards:
		ids.append(String(card.id))
	return ids
