extends RefCounted
class_name DualTopicState

enum Commitment {
	UNDECIDED,
	MAINTAIN,
	DOUBLE_DOWN,
	PIVOT,
	SPLIT,
	STOPPED,
}

var definition: DualTopicDefinition
var potential: int = DualTopicDefinition.Potential.LOW
var evidence: int = 0
var completion: int = 0
var risks: Array[DualTopicRiskState] = []
var commitment: Commitment = Commitment.UNDECIDED
var is_closed: bool = false
var archive_entries: Array[Dictionary] = []


func setup(topic_definition: DualTopicDefinition, generated_risks: Array[DualTopicRiskState]) -> void:
	definition = topic_definition
	potential = topic_definition.potential
	evidence = topic_definition.initial_evidence
	completion = topic_definition.initial_completion
	risks = generated_risks.duplicate()
	commitment = Commitment.UNDECIDED
	is_closed = false
	archive_entries.clear()


func add_evidence(amount: int, source_id: StringName = &"") -> int:
	if is_closed:
		return 0
	var previous := evidence
	evidence = clampi(evidence + max(0, amount), 0, 5)
	_record_change(&"evidence", evidence - previous, source_id)
	return evidence - previous


func spend_evidence(amount: int, source_id: StringName = &"") -> int:
	if is_closed or amount <= 0:
		return 0
	var previous := evidence
	evidence = maxi(0, evidence - amount)
	_record_change(&"evidence", evidence - previous, source_id)
	return previous - evidence


func add_completion(amount: int, source_id: StringName = &"") -> int:
	if is_closed:
		return 0
	var previous := completion
	completion = clampi(completion + max(0, amount), 0, 5)
	_record_change(&"completion", completion - previous, source_id)
	return completion - previous


func has_high_unhandled_risk() -> bool:
	for risk: DualTopicRiskState in risks:
		if risk.is_high_unhandled():
			return true
	return false


func meets_submission_minimum() -> bool:
	return not is_closed and completion >= 4 and evidence >= 3 and not has_high_unhandled_risk()


func meets_excellent_minimum() -> bool:
	if definition == null or not definition.can_receive_excellent:
		return false
	if completion < 5 or evidence < 4:
		return false
	for risk: DualTopicRiskState in risks:
		if not risk.is_controlled:
			return false
	return true


func can_apply_commitment(choice: Commitment) -> bool:
	if is_closed or commitment != Commitment.UNDECIDED:
		return false
	match choice:
		Commitment.MAINTAIN, Commitment.DOUBLE_DOWN, Commitment.STOPPED:
			return true
		Commitment.PIVOT:
			return completion > 0 and get_first_revealed_risk_index() >= 0
		Commitment.SPLIT:
			return (
				potential > DualTopicDefinition.Potential.LOW
				and not risks.is_empty()
				and definition.special_rule != &"indivisible_hypothesis"
			)
		_:
			return false


func apply_commitment(choice: Commitment) -> bool:
	if not can_apply_commitment(choice):
		return false
	match choice:
		Commitment.MAINTAIN:
			commitment = choice
		Commitment.DOUBLE_DOWN:
			commitment = choice
		Commitment.PIVOT:
			completion -= 1
			commitment = choice
		Commitment.SPLIT:
			potential = int(potential) - 1
			completion = clampi(completion + 1, 0, 5)
			risks.remove_at(risks.size() - 1)
			commitment = choice
		Commitment.STOPPED:
			commitment = choice
			is_closed = true
		_:
			return false
	_record_change(&"commitment", int(choice), &"midterm")
	return true


func archive_early(source_id: StringName = &"early_archive") -> bool:
	if is_closed:
		return false
	is_closed = true
	commitment = Commitment.STOPPED
	_record_change(&"commitment", int(Commitment.STOPPED), source_id)
	return true


func replace_revealed_risk(new_risk: DualTopicRiskState) -> bool:
	if new_risk == null:
		return false
	var index: int = get_first_revealed_risk_index()
	if index < 0:
		return false
	var previous_id: StringName = risks[index].definition.id
	risks[index] = new_risk
	archive_entries.append({
		"kind": "risk_replaced",
		"previous_id": String(previous_id),
		"new_id": String(new_risk.definition.id),
		"source_id": "midterm_pivot",
	})
	return true


func get_first_revealed_risk_index() -> int:
	for index: int in range(risks.size()):
		if risks[index].knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN:
			return index
	return -1


func _record_change(kind: StringName, amount: int, source_id: StringName) -> void:
	if amount == 0:
		return
	archive_entries.append({
		"kind": String(kind),
		"amount": amount,
		"source_id": String(source_id),
	})


func to_debug_dict() -> Dictionary:
	var risk_data: Array[Dictionary] = []
	for risk: DualTopicRiskState in risks:
		risk_data.append(risk.to_debug_dict())
	return {
		"id": String(definition.id) if definition != null else "",
		"potential": int(potential),
		"evidence": evidence,
		"completion": completion,
		"commitment": int(commitment),
		"is_closed": is_closed,
		"risks": risk_data,
		"archive_entries": archive_entries.duplicate(true),
	}
