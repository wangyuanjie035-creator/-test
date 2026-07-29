@tool
extends Resource
class_name EventDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var stage_min: StringName = &"master_1"
@export var stage_max: StringName = &""
@export_multiline var description: String = ""
@export var choices: Array[EventChoiceDefinition] = []
@export var tags: PackedStringArray = PackedStringArray()


func has_tag(tag: StringName) -> bool:
	return tags.has(String(tag))
