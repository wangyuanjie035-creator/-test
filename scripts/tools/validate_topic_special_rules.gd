extends SceneTree

const CATALOG: ResearchTopicCatalog = preload(
	"res://data/topic_pool/starter_topic_catalog.tres"
)


func _initialize() -> void:
	if not _validate_rule_propagation():
		return
	if not _validate_action_rules():
		return
	if not _validate_commitment_and_week_rules():
		return
	print("TOPIC_SPECIAL_RULES: PASS")
	quit(0)


func _validate_rule_propagation() -> bool:
	var expected_rules: Dictionary[StringName, bool] = {
		&"reproduction_bonus": true,
		&"negative_result_asset": true,
		&"scarce_data": true,
		&"pipeline_engine": true,
		&"cross_domain": true,
		&"indivisible_hypothesis": true,
		&"multi_source": true,
		&"deployment_exposure": true,
	}
	for archetype in CATALOG.archetypes:
		if archetype.base_reward < 1:
			return _fail("Archetype has an invalid reward: %s." % archetype.id)
		expected_rules.erase(archetype.special_rule)
	if not expected_rules.is_empty():
		return _fail("Catalog is missing one or more required special rules.")
	return true


func _validate_action_rules() -> bool:
	var reproduction := _create_model(&"reproduction_bonus", 101)
	_force_result(reproduction, &"normal")
	reproduction.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	var reproduced := reproduction.perform_action(DualTopicRunModel.ActionType.EXPERIMENT, 0)
	if int(reproduced.get("special_evidence", 0)) != 1:
		return _fail("Reproduction did not reward the first normal experiment.")

	var negative := _create_model(&"negative_result_asset", 102)
	_force_result(negative, &"failed")
	negative.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	var salvaged := negative.perform_action(DualTopicRunModel.ActionType.EXPERIMENT, 0)
	if int(salvaged.get("special_evidence", 0)) != 1:
		return _fail("Negative-result topic did not salvage failed work.")

	var scarce := _create_model(&"scarce_data", 103)
	var investigated := scarce.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	if int(investigated.get("special_evidence", 0)) != 1:
		return _fail("Scarce-data investigation did not create evidence.")

	var pipeline := _create_model(&"pipeline_engine", 104)
	_force_result(pipeline, &"normal")
	pipeline.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	var pipeline_result := pipeline.perform_action(DualTopicRunModel.ActionType.EXPERIMENT, 0)
	if int(pipeline_result.get("special_energy_cost", 0)) != 1:
		return _fail("Early pipeline experiment did not pay its setup cost.")

	var multimodal := _create_model(&"multi_source", 105)
	_force_result(multimodal, &"anomaly")
	multimodal.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	var conflict := multimodal.perform_action(DualTopicRunModel.ActionType.EXPERIMENT, 0)
	if int(conflict.get("special_pressure_cost", 0)) != 1:
		return _fail("Multi-source conflict did not create extra pressure.")
	return true


func _validate_commitment_and_week_rules() -> bool:
	var indivisible := _create_model(&"indivisible_hypothesis", 201)
	if indivisible.topics[0].can_apply_commitment(DualTopicState.Commitment.SPLIT):
		return _fail("Indivisible topic allowed a split commitment.")

	var cross_domain := _create_model(&"cross_domain", 202)
	cross_domain.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	cross_domain.week = 3
	var completion_before: int = cross_domain.topics[0].completion
	var pivot := cross_domain.apply_midterm_commitments(
		[DualTopicState.Commitment.PIVOT]
	)
	if not bool(pivot.get("success", false)):
		return _fail("Cross-domain pivot could not be selected.")
	if cross_domain.topics[0].completion != completion_before:
		return _fail("Cross-domain pivot did not preserve completion.")

	var deployment := _create_model(&"deployment_exposure", 203)
	var pressure_before := deployment.pressure
	deployment.end_week()
	if deployment.pressure != pressure_before + 1:
		return _fail("Deployment topic did not expose unknown-risk pressure.")
	return true


func _create_model(rule: StringName, run_seed: int) -> DualTopicRunModel:
	var risk := DualTopicRiskDefinition.new()
	risk.id = StringName("%s_risk" % rule)
	risk.display_name = "Test risk"
	var definition := DualTopicDefinition.new()
	definition.id = StringName("%s_topic" % rule)
	definition.display_name = "Test topic"
	definition.potential = DualTopicDefinition.Potential.HIGH
	definition.initial_evidence = 1
	definition.initial_completion = 2
	definition.risk_slot_count = 1
	definition.can_receive_excellent = true
	definition.risk_pool = [risk]
	definition.special_rule = rule
	var model := DualTopicRunModel.new()
	var definitions: Array[DualTopicDefinition] = [definition]
	if not model.setup(run_seed, definitions):
		_fail("Could not set up model for %s." % rule)
	return model


func _force_result(model: DualTopicRunModel, outcome: StringName) -> void:
	var results: Array[StringName] = [outcome]
	model.topics[0].risks[0].experiment_results = results


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
