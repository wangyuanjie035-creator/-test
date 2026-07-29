@tool
extends Resource
class_name BossIntentDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var intent_type: StringName = &"pressure"
@export var pressure: int = 0
@export var effects: Array[EffectDefinition] = []
@export var condition: StringName = &""
@export var success_effects: Array[EffectDefinition] = []
@export var failure_effects: Array[EffectDefinition] = []


func has_condition() -> bool:
	return condition != &""
