extends SceneTree

const ADAPTER := preload(
	"res://scripts/academic_year/model/academic_opportunity_effect_adapter.gd"
)
const TOPIC: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/bold_topic_b.tres"
)
const CATALOG: DualTopicMethodCatalog = preload(
	"res://data/dual_topic/methods/starter_method_catalog.tres"
)


func _initialize() -> void:
	if not _validate_collaboration_rule():
		return
	if not _validate_industry_rule():
		return
	if not _validate_prototype_rule():
		return
	print("PHASE_THREE_PERSISTENT_RULES: PASS")
	quit(0)


func _validate_collaboration_rule() -> bool:
	var model: DualTopicRunModel = _model(&"cooperation_opening")
	var card: DualTopicMethodCardDefinition = _card(&"evidence_ledger")
	var before: int = model.action_points
	var first: Dictionary = model.perform_method_card(card, 0)
	if int(first.get("academic_rule_action_refund", 0)) != 1:
		return _fail("Collaboration did not refund the first qualifying action.")
	if model.action_points != before:
		return _fail("Collaboration refund did not preserve the weekly action budget.")
	var second: Dictionary = model.perform_method_card(card, 0)
	return _expect(
		int(second.get("academic_rule_action_refund", 0)) == 0,
		"Collaboration triggered more than once in one week."
	)


func _validate_industry_rule() -> bool:
	var model: DualTopicRunModel = _model(&"industry_window")
	var topic: DualTopicState = model.topics[0]
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state == DualTopicRiskState.KnowledgeState.UNKNOWN:
			risk.identify()
			break
	var before: int = topic.completion
	var result: Dictionary = model.perform_method_card(_card(&"pilot_study"), 0)
	return _expect(
		int(result.get("academic_rule_completion", 0)) == 1
		and topic.completion == before + 1,
		"Industry milestone did not reward a controlled experiment."
	)


func _validate_prototype_rule() -> bool:
	var model: DualTopicRunModel = _model(&"failure_asset_pilot")
	var topic: DualTopicState = model.topics[0]
	var before_evidence: int = topic.evidence
	var before_completion: int = topic.completion
	var result: Dictionary = model.perform_method_card(_card(&"pilot_study"), 0)
	return _expect(
		StringName(result.get("outcome", &"")) == &"blind_probe"
		and int(result.get("academic_rule_evidence", 0)) == 1
		and int(result.get("academic_rule_completion", 0)) == 1
		and topic.evidence == before_evidence + 1
		and topic.completion == before_completion + 1,
		"Prototype learning did not convert a blind probe into playable progress."
	)


func _model(effect_id: StringName) -> DualTopicRunModel:
	var model := DualTopicRunModel.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC]
	if not model.setup(240731, definitions):
		_fail("Could not configure research model.")
	var decision: Dictionary = {"accepted": true, "effect_id": effect_id}
	var modifier: Dictionary = ADAPTER.to_opening_modifier(decision)
	if not bool(model.apply_opening_modifier(modifier).get("success", false)):
		_fail("Could not apply persistent academic rule.")
	return model


func _card(card_id: StringName) -> DualTopicMethodCardDefinition:
	for resource: Resource in CATALOG.cards:
		var card: DualTopicMethodCardDefinition = resource as DualTopicMethodCardDefinition
		if card != null and card.id == card_id:
			return card
	_fail("Required method card was not found.")
	return null


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	return _fail(message)


func _fail(message: String) -> bool:
	push_error("PHASE_THREE_PERSISTENT_RULES: %s" % message)
	quit(1)
	return false
