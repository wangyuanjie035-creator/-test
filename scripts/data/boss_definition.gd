@tool
extends Resource
class_name BossDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var stage: StringName = &"master_1"
@export var target_progress: int = 0
@export var starting_status_cards: PackedStringArray = PackedStringArray()
@export var passive_rules: PackedStringArray = PackedStringArray()
@export var intents: Array[BossIntentDefinition] = []
@export var phase_trigger_progress: int = 0
@export var phase_condition: StringName = &""
@export var phase_success_effects: Array[EffectDefinition] = []
@export var phase_failure_effects: Array[EffectDefinition] = []
@export var phase_event_id: StringName = &""
@export var victory_rewards: PackedStringArray = PackedStringArray()
@export var failure_result: StringName = &""


func get_intent_for_turn(turn_index: int) -> BossIntentDefinition:
	if intents.is_empty():
		return null

	var wrapped_index := turn_index % intents.size()
	return intents[wrapped_index]
