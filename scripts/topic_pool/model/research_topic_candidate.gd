extends RefCounted
class_name ResearchTopicCandidate

var candidate_id: StringName = &""
var archetype: ResearchTopicArchetype
var potential: int = 0
var reward: int = 0
var deadline_weeks: int = 6
var risks: Array[DualTopicRiskDefinition] = []
var special_rule: StringName = &""


func setup(
	id_value: StringName,
	source: ResearchTopicArchetype,
	potential_value: int,
	reward_value: int,
	deadline_value: int,
	risk_values: Array[DualTopicRiskDefinition]
) -> bool:
	if source == null or not source.is_valid_definition() or risk_values.is_empty():
		return false
	candidate_id = id_value
	archetype = source
	potential = clampi(potential_value, 0, 3)
	reward = maxi(1, reward_value)
	deadline_weeks = clampi(deadline_value, 3, 8)
	risks = risk_values.duplicate()
	special_rule = source.special_rule
	return true


func to_debug_dict() -> Dictionary:
	var risk_ids: Array[StringName] = []
	for risk: DualTopicRiskDefinition in risks:
		risk_ids.append(risk.id)
	return {
		"candidate_id": candidate_id,
		"archetype_id": archetype.id,
		"display_name": archetype.display_name,
		"difficulty_tier": int(archetype.difficulty_tier),
		"potential": potential,
		"reward": reward,
		"deadline_weeks": deadline_weeks,
		"risk_ids": risk_ids,
		"special_rule": special_rule,
	}
