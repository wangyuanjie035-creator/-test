extends SceneTree


func _initialize() -> void:
	if not _test_tendency_classification():
		return
	if not _test_asset_recovery_bonus():
		return
	print("PHASE_TWO_BUILD_TENDENCIES: PASS")
	quit(0)


func _test_tendency_classification() -> bool:
	var model := _model([_definition(&"profile")], 7201)
	if model.get_build_tendency_profile().get("id", &"") != &"stable_replication":
		return _fail("The opening tendency was not stable replication.")
	model.method_category_uses = [1, 3, 0, 0, 0]
	if model.get_build_tendency_profile().get("id", &"") != &"risky_exploration":
		return _fail("Experiment investment did not form risky exploration.")
	model.method_category_uses = [1, 2, 3, 0, 0]
	if model.get_build_tendency_profile().get("id", &"") != &"asset_recovery":
		return _fail("Organization investment did not form asset recovery.")
	return true


func _test_asset_recovery_bonus() -> bool:
	var definitions: Array[DualTopicDefinition] = [
		_definition(&"main"),
		_definition(&"archive"),
	]
	var baseline := _model(definitions, 7202)
	var recovery := _model(definitions, 7202)
	for model: DualTopicRunModel in [baseline, recovery]:
		model.week = 3
		var choices: Array[DualTopicState.Commitment] = [
			DualTopicState.Commitment.MAINTAIN,
			DualTopicState.Commitment.MAINTAIN,
		]
		if not bool(model.apply_midterm_commitments(choices).get("success", false)):
			return _fail("Could not prepare a midterm archive.")
		model.topics[1].evidence = 4
		model.topics[1].completion = 2
	recovery.method_category_uses[
		DualTopicMethodCardDefinition.Category.ORGANIZATION
	] = DualTopicRunModel.METHOD_MASTERY_THRESHOLD
	var baseline_result: Dictionary = baseline.archive_topic_early(1, 0)
	var recovery_result: Dictionary = recovery.archive_topic_early(1, 0)
	if int(recovery_result.get("evidence_gain", 0)) <= int(
		baseline_result.get("evidence_gain", 0)
	):
		return _fail("Asset recovery did not preserve extra evidence.")
	if int(recovery_result.get("completion_gain", 0)) <= int(
		baseline_result.get("completion_gain", 0)
	):
		return _fail("Asset recovery did not preserve extra completion.")
	if not bool(recovery_result.get("recovery_mastery", false)):
		return _fail("The archive result did not explain its recovery bonus.")
	return true


func _model(
	definitions: Array[DualTopicDefinition],
	seed_value: int
) -> DualTopicRunModel:
	var model := DualTopicRunModel.new()
	model.setup(seed_value, definitions)
	return model


func _definition(id_value: StringName) -> DualTopicDefinition:
	var risk := DualTopicRiskDefinition.new()
	risk.id = StringName("%s_risk" % id_value)
	risk.display_name = "测试风险"
	risk.kind = DualTopicRiskDefinition.RiskKind.DATA
	var definition := DualTopicDefinition.new()
	definition.id = id_value
	definition.display_name = String(id_value)
	definition.potential = DualTopicDefinition.Potential.MEDIUM
	definition.risk_slot_count = 1
	definition.reward_value = 2
	definition.risk_pool = [risk]
	definition.synergy_tags = PackedStringArray(["shared"])
	return definition


func _fail(message: String) -> bool:
	push_error("PHASE_TWO_BUILD_TENDENCIES: %s" % message)
	quit(1)
	return false
