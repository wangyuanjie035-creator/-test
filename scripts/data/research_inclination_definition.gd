@tool
extends Resource
class_name ResearchInclinationDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rule_text: String = ""
@export var accent_color: Color = Color(0.45, 0.82, 0.72)
@export var remove_card_ids: PackedStringArray = PackedStringArray()
@export var add_card_ids: PackedStringArray = PackedStringArray()


func is_valid_definition() -> bool:
	return (
		id != &""
		and not display_name.is_empty()
		and remove_card_ids.size() == add_card_ids.size()
	)
