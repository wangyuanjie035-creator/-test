@tool
extends Resource
class_name DualTopicDefinition

enum Potential {
	LOW,
	MEDIUM,
	HIGH,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var premise: String = ""
@export var potential: Potential = Potential.LOW
@export_range(0, 5, 1) var initial_evidence: int = 0
@export_range(0, 5, 1) var initial_completion: int = 0
@export_range(0, 2, 1) var risk_slot_count: int = 0
@export var can_receive_excellent: bool = false
@export var risk_pool: Array[DualTopicRiskDefinition] = []
@export var special_rule: StringName = &""
@export_range(1, 5, 1) var reward_value: int = 1
@export var discipline: StringName = &"general"
@export var synergy_tags: PackedStringArray = []


func is_valid_definition() -> bool:
	return (
		id != &""
		and not display_name.is_empty()
		and initial_evidence >= 0
		and initial_evidence <= 5
		and initial_completion >= 0
		and initial_completion <= 5
		and risk_slot_count >= 0
		and risk_slot_count <= 2
		and risk_pool.size() >= risk_slot_count
	)
