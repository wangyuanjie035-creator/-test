@tool
extends Resource
class_name EventChoiceDefinition

@export var id: StringName = &""
@export var label: String = ""
@export var requirement: StringName = &""
@export var preview: String = ""
@export var effects: Array[EffectDefinition] = []
@export_range(0, 3, 1) var risk_level: int = 0


func is_always_available() -> bool:
	return requirement == &""
