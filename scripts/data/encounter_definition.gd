@tool
extends Resource
class_name EncounterDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var stage: StringName = &"master_1"
@export var target_progress: int = 40
@export var pressure_per_turn: int = 6
@export var intent_name: String = "普通压力"
@export_multiline var description: String = ""
@export var victory_rewards: PackedStringArray = PackedStringArray()


func get_intent_text() -> String:
	return "%s：造成 %d 压力" % [intent_name, pressure_per_turn]
