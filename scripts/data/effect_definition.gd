@tool
extends Resource
class_name EffectDefinition

@export var effect_type: StringName = &""
@export var amount: int = 0
@export var resource: StringName = &""
@export var target: StringName = &"self"
@export var card_id: StringName = &""
@export var tag_filter: StringName = &""
@export var condition: StringName = &""


func is_empty() -> bool:
	return effect_type == &""


func to_debug_dict() -> Dictionary:
	return {
		"effect_type": effect_type,
		"amount": amount,
		"resource": resource,
		"target": target,
		"card_id": card_id,
		"tag_filter": tag_filter,
		"condition": condition,
	}
