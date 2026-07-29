@tool
extends Resource
class_name CardDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var card_type: StringName = &"action"
@export var rarity: StringName = &"common"
@export var cost: int = 1
@export var tags: PackedStringArray = PackedStringArray()
@export_multiline var description: String = ""
@export_multiline var upgraded_description: String = ""
@export var effects: Array[EffectDefinition] = []
@export var upgraded_effects: Array[EffectDefinition] = []
@export var exhausts: bool = false
@export var temporary: bool = false
@export var status_id_to_add: StringName = &""
@export var unlock_id: StringName = &""


func has_tag(tag: StringName) -> bool:
	return tags.has(String(tag))


func is_status_card() -> bool:
	return card_type == &"status"


func get_effects(upgraded: bool = false) -> Array[EffectDefinition]:
	if upgraded and not upgraded_effects.is_empty():
		return upgraded_effects
	return effects


func get_description(upgraded: bool = false) -> String:
	if upgraded and not upgraded_description.is_empty():
		return upgraded_description
	return description


func to_debug_dict() -> Dictionary:
	var effect_data: Array[Dictionary] = []
	for effect in effects:
		if effect != null:
			effect_data.append(effect.to_debug_dict())

	return {
		"id": id,
		"display_name": display_name,
		"card_type": card_type,
		"rarity": rarity,
		"cost": cost,
		"tags": tags,
		"description": description,
		"effects": effect_data,
		"exhausts": exhausts,
		"temporary": temporary,
		"unlock_id": unlock_id,
	}
