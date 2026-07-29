extends Resource
class_name DualTopicMethodCatalog

@export var cards: Array[DualTopicMethodCardDefinition] = []


func is_valid_catalog() -> bool:
	if cards.size() != 15:
		return false
	var seen_ids: Dictionary[StringName, bool] = {}
	for card: DualTopicMethodCardDefinition in cards:
		if card == null or not card.is_valid_definition() or seen_ids.has(card.id):
			return false
		seen_ids[card.id] = true
	return true
