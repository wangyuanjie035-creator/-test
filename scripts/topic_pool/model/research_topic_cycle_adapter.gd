extends RefCounted
class_name ResearchTopicCycleAdapter


static func create_definition(candidate: ResearchTopicCandidate) -> DualTopicDefinition:
	if candidate == null or candidate.archetype == null:
		return null
	var definition := DualTopicDefinition.new()
	definition.id = candidate.candidate_id
	definition.display_name = candidate.archetype.display_name
	definition.premise = candidate.archetype.premise
	definition.potential = mini(DualTopicDefinition.Potential.HIGH, candidate.potential)
	definition.initial_evidence = 1 if candidate.potential == 0 else 0
	definition.initial_completion = 1 if candidate.potential == 0 else 0
	definition.risk_slot_count = mini(2, candidate.risks.size())
	definition.can_receive_excellent = candidate.potential >= 2
	definition.risk_pool = candidate.risks.duplicate()
	definition.special_rule = candidate.special_rule
	definition.reward_value = candidate.reward
	definition.discipline = candidate.archetype.discipline
	definition.synergy_tags = candidate.archetype.tags.duplicate()
	return definition
