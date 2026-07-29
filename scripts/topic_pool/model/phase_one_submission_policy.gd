extends RefCounted
class_name PhaseOneSubmissionPolicy


func evaluate(
	topic: DualTopicState,
	minimum_evidence: int,
	minimum_completion: int,
	public_requirement_met: bool
) -> Dictionary:
	if topic == null or topic.is_closed:
		return _failure(&"invalid_topic", &"topic")
	if topic.completion < minimum_completion:
		return _failure(
			&"completion_insufficient",
			&"expression",
			topic.completion,
			minimum_completion
		)
	if topic.evidence < minimum_evidence:
		return _failure(
			&"evidence_insufficient",
			&"evidence",
			topic.evidence,
			minimum_evidence
		)
	for risk: DualTopicRiskState in topic.risks:
		if risk.is_high_unhandled():
			return {
				"grade": &"failed",
				"ready": false,
				"diagnosis": {
					"category": &"risk",
					"reason": &"high_risk_unhandled",
					"risk_id": risk.definition.id,
					"risk_was_known": (
						risk.knowledge_state
						!= DualTopicRiskState.KnowledgeState.UNKNOWN
					),
				},
			}
	if not public_requirement_met:
		return _failure(&"public_requirement_unmet", &"requirement")
	return {
		"grade": &"pass",
		"ready": true,
		"diagnosis": {},
	}


func withdrawal_terms(topic: DualTopicState) -> Dictionary:
	var retained_asset: StringName = &"research_notes"
	if topic != null:
		for risk: DualTopicRiskState in topic.risks:
			if risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN:
				retained_asset = &"risk_insight"
				break
	return {
		"retained_asset": retained_asset,
		"cost": {
			"kind": &"progress",
			"amount": 1,
		},
	}


func _failure(
	reason: StringName,
	category: StringName,
	current: int = 0,
	required: int = 0
) -> Dictionary:
	var diagnosis: Dictionary = {
		"category": category,
		"reason": reason,
	}
	if required > 0:
		diagnosis["current"] = current
		diagnosis["required"] = required
	return {
		"grade": &"failed",
		"ready": false,
		"diagnosis": diagnosis,
	}
