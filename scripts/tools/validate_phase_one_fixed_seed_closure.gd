extends SceneTree

const TOPIC_CATALOG: ResearchTopicCatalog = preload(
	"res://data/topic_pool/starter_topic_catalog.tres"
)
const METHOD_CATALOG: DualTopicMethodCatalog = preload(
	"res://data/dual_topic/methods/starter_method_catalog.tres"
)
const FIXED_SEEDS: Array[int] = [
	240731,
	90177,
	1784352143,
	1784381155,
	1784286511,
	310271,
	442109,
	570013,
	680041,
	791033,
]

var _shared_protocol: DualTopicMethodCardDefinition
var _synthesis_matrix: DualTopicMethodCardDefinition


func _initialize() -> void:
	_shared_protocol = _find_card(&"shared_protocol")
	_synthesis_matrix = _find_card(&"synthesis_matrix")
	if _shared_protocol == null or _synthesis_matrix == null:
		_fail("Required phase-one method cards are missing.")
		return
	for seed: int in FIXED_SEEDS:
		if not _validate_seed(seed):
			return
	print("PHASE_ONE_FIXED_SEED_CLOSURE: PASS (%d seeds, 3 outcomes)" % FIXED_SEEDS.size())
	quit(0)


func _validate_seed(seed: int) -> bool:
	var candidates: Array[ResearchTopicCandidate] = _generate_candidates(seed)
	if candidates.size() != 3:
		return _fail("Seed %d did not generate three topic candidates." % seed)
	var definition: DualTopicDefinition = ResearchTopicCycleAdapter.create_definition(candidates[0])
	if definition == null or not definition.is_valid_definition():
		return _fail("Seed %d could not adapt its first candidate." % seed)
	if not _validate_success(seed, definition):
		return false
	if not _validate_failure(seed, definition):
		return false
	return _validate_withdrawal(seed, definition)


func _validate_success(seed: int, definition: DualTopicDefinition) -> bool:
	var run: DualTopicRunModel = _new_run(seed, definition)
	while run.week <= DualTopicRunModel.MAX_WEEKS:
		if run.week == 3 and not run.midterm_resolved:
			var midterm: Dictionary = run.apply_midterm_commitments(
				[DualTopicState.Commitment.MAINTAIN]
			)
			if not bool(midterm.get("success", false)):
				return _fail("Seed %d could not resolve the midterm." % seed)
		if not _advance_success_route(run):
			return _fail("Seed %d encountered an unusable success route." % seed)
		if run.week == DualTopicRunModel.MAX_WEEKS:
			break
		if not run.end_week():
			return _fail("Seed %d could not advance its week." % seed)
	var topic: DualTopicState = run.topics[0]
	if topic.evidence < 4 or topic.completion < 4:
		return _fail(
			"Seed %d ended under target at evidence %d / completion %d."
			% [seed, topic.evidence, topic.completion]
		)
	for risk: DualTopicRiskState in topic.risks:
		if not risk.is_controlled:
			return _fail("Seed %d left an uncontrolled risk." % seed)
	var result: Dictionary = run.resolve_run(&"submit", 0)
	if result.get("grade", &"") != &"pass":
		return _fail(
			"Seed %d valid route failed submission: %s."
			% [seed, JSON.stringify(result)]
		)
	return true


func _advance_success_route(run: DualTopicRunModel) -> bool:
	var topic: DualTopicState = run.topics[0]
	while run.action_points > 0:
		if _is_submission_ready(topic):
			return true
		var action_result: Dictionary
		if run.energy <= 1:
			action_result = run.perform_action(DualTopicRunModel.ActionType.RECOVER)
		elif _has_risk_state(topic, DualTopicRiskState.KnowledgeState.UNKNOWN):
			action_result = run.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
		elif _has_risk_state(topic, DualTopicRiskState.KnowledgeState.IDENTIFIED):
			if run.energy < 2:
				action_result = run.perform_action(DualTopicRunModel.ActionType.RECOVER)
			else:
				action_result = run.perform_method_card(_shared_protocol, 0)
		elif topic.evidence < 4 or topic.completion < 4:
			action_result = run.perform_method_card(_synthesis_matrix, 0)
		else:
			return true
		if not bool(action_result.get("success", false)):
			return false
	return true


func _validate_failure(seed: int, definition: DualTopicDefinition) -> bool:
	var run: DualTopicRunModel = _new_run(seed, definition)
	if not _advance_without_actions(run):
		return _fail("Seed %d failure route could not reach submission." % seed)
	var result: Dictionary = run.resolve_run(&"submit", 0)
	if result.get("grade", &"") != &"failed":
		return _fail("Seed %d empty route did not fail." % seed)
	var diagnosis: Dictionary = Dictionary(result.get("diagnosis", {}))
	if diagnosis.is_empty() or not diagnosis.has("reason"):
		return _fail("Seed %d failure had no actionable first cause." % seed)
	if run.converted_failure_asset_count != 1:
		return _fail("Seed %d failure did not preserve one asset." % seed)
	return true


func _validate_withdrawal(seed: int, definition: DualTopicDefinition) -> bool:
	var run: DualTopicRunModel = _new_run(seed, definition)
	if not _advance_without_actions(run):
		return _fail("Seed %d withdrawal route could not reach submission." % seed)
	var result: Dictionary = run.resolve_run(&"withdraw", 0)
	if result.get("grade", &"") != &"withdrawn":
		return _fail("Seed %d withdrawal returned the wrong grade." % seed)
	var terms: Dictionary = Dictionary(result.get("withdrawal_terms", {}))
	if not terms.has("retained_asset") or not terms.has("cost"):
		return _fail("Seed %d withdrawal lost its asset or cost." % seed)
	return true


func _advance_without_actions(run: DualTopicRunModel) -> bool:
	while run.week < DualTopicRunModel.MAX_WEEKS:
		if run.week == 3 and not run.midterm_resolved:
			var midterm: Dictionary = run.apply_midterm_commitments(
				[DualTopicState.Commitment.MAINTAIN]
			)
			if not bool(midterm.get("success", false)):
				return false
		if not run.end_week():
			return false
	return true


func _new_run(seed: int, definition: DualTopicDefinition) -> DualTopicRunModel:
	var run := DualTopicRunModel.new()
	assert(run.setup(seed, [definition]))
	run.enable_simplified_submission()
	return run


func _generate_candidates(seed: int) -> Array[ResearchTopicCandidate]:
	var archetypes: Array[ResearchTopicArchetype] = []
	archetypes.assign(TOPIC_CATALOG.archetypes)
	var generator := ResearchTopicGenerator.new()
	generator.setup(seed, 0, archetypes)
	return generator.generate_candidates(3)


func _find_card(card_id: StringName) -> DualTopicMethodCardDefinition:
	for resource: Resource in METHOD_CATALOG.cards:
		var card := resource as DualTopicMethodCardDefinition
		if card.id == card_id:
			return card
	return null


func _has_risk_state(
	topic: DualTopicState,
	knowledge_state: DualTopicRiskState.KnowledgeState
) -> bool:
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state == knowledge_state:
			return true
	return false


func _is_submission_ready(topic: DualTopicState) -> bool:
	if topic.evidence < 4 or topic.completion < 4:
		return false
	for risk: DualTopicRiskState in topic.risks:
		if not risk.is_controlled:
			return false
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
