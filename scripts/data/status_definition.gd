@tool
extends Resource
class_name StatusDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var trigger: StringName = &"on_draw"
@export_multiline var description: String = ""
@export var effects: Array[EffectDefinition] = []
@export var exhaust_after_trigger: bool = false
@export var playable_cost: int = -1


func can_be_played() -> bool:
	return playable_cost >= 0


func to_debug_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"trigger": trigger,
		"description": description,
		"exhaust_after_trigger": exhaust_after_trigger,
		"playable_cost": playable_cost,
	}
