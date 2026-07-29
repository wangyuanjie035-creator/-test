extends RefCounted
class_name DualTopicRiskState

enum KnowledgeState {
	UNKNOWN,
	IDENTIFIED,
	VERIFIED,
}

enum RiskTier {
	LOW,
	MEDIUM,
	HIGH,
}

var definition: DualTopicRiskDefinition
var knowledge_state: KnowledgeState = KnowledgeState.UNKNOWN
var tier: int = RiskTier.LOW
var is_controlled: bool = false
var experiment_results: Array[StringName] = []
var experiment_cursor: int = 0


func setup(
	risk_definition: DualTopicRiskDefinition,
	initial_tier: int,
	pregenerated_results: Array[StringName]
) -> void:
	definition = risk_definition
	tier = clampi(initial_tier, RiskTier.LOW, RiskTier.HIGH)
	experiment_results = pregenerated_results.duplicate()
	knowledge_state = KnowledgeState.UNKNOWN
	is_controlled = false
	experiment_cursor = 0


func identify() -> bool:
	if knowledge_state != KnowledgeState.UNKNOWN:
		return false
	knowledge_state = KnowledgeState.IDENTIFIED
	return true


func verify() -> bool:
	if knowledge_state != KnowledgeState.IDENTIFIED:
		return false
	knowledge_state = KnowledgeState.VERIFIED
	return true


func lower_tier() -> bool:
	if knowledge_state == KnowledgeState.UNKNOWN or is_controlled:
		return false
	if tier == RiskTier.LOW:
		is_controlled = true
		return true
	tier = int(tier) - 1
	return true


func control() -> bool:
	if knowledge_state == KnowledgeState.UNKNOWN:
		return false
	knowledge_state = KnowledgeState.VERIFIED
	is_controlled = true
	return true


func consume_experiment_result() -> StringName:
	if experiment_results.is_empty():
		return &"normal"
	var result: StringName = experiment_results[experiment_cursor % experiment_results.size()]
	experiment_cursor += 1
	return result


func is_high_unhandled() -> bool:
	return tier == RiskTier.HIGH and not is_controlled


func to_debug_dict() -> Dictionary:
	return {
		"id": String(definition.id) if definition != null else "",
		"knowledge_state": int(knowledge_state),
		"tier": int(tier),
		"is_controlled": is_controlled,
		"experiment_cursor": experiment_cursor,
		"experiment_results": experiment_results.duplicate(),
	}
