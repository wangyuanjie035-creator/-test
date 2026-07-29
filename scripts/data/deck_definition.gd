@tool
extends Resource
class_name DeckDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var card_ids: PackedStringArray = PackedStringArray()


func size() -> int:
	return card_ids.size()


func count_card(card_id: StringName) -> int:
	var count := 0
	for current_id in card_ids:
		if current_id == String(card_id):
			count += 1
	return count
