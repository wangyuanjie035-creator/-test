extends SceneTree


func _initialize() -> void:
	if not _test_shared_resource_conflict():
		return
	if not _test_cross_topic_synergy():
		return
	if not _test_single_topic_has_no_portfolio_tax():
		return
	if not _test_freeze_decision():
		return
	if not _test_resource_transfer():
		return
	if not _test_early_archive_salvage():
		return
	print("MULTI_TOPIC_PORTFOLIO: PASS")
	quit(0)


func _test_shared_resource_conflict() -> bool:
	var first := _definition(&"first", PackedStringArray(["theory"]))
	var second := _definition(&"second", PackedStringArray(["engineering"]))
	var model := _model([first, second], 3101)
	if model.get_portfolio_relation() != &"conflict":
		return _fail("Unrelated topics were not classified as a conflict.")
	model.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	model.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 1)
	if model.action_points != 2:
		return _fail("Two topics did not share the same weekly action budget.")
	model.end_week()
	if model.pressure != 1:
		return _fail("Unrelated dual topics did not create weekly attention pressure.")
	return true


func _test_cross_topic_synergy() -> bool:
	var first := _definition(
		&"first_synergy",
		PackedStringArray(["engineering"]),
		&"scarce_data"
	)
	var second := _definition(&"second_synergy", PackedStringArray(["engineering"]))
	var model := _model([first, second], 3102)
	if model.get_portfolio_relation() != &"synergy":
		return _fail("Shared-tag topics were not classified as a synergy.")
	var before: int = model.topics[1].evidence
	var result := model.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 0)
	if int(result.get("synergy_evidence", 0)) != 1:
		return _fail("Evidence production did not trigger the cross-topic synergy.")
	if model.topics[1].evidence != before + 1:
		return _fail("Cross-topic synergy did not improve the other topic.")
	var second_result := model.perform_action(DualTopicRunModel.ActionType.ORGANIZE, 0)
	if int(second_result.get("synergy_evidence", 0)) != 0:
		return _fail("Cross-topic synergy triggered more than once in one week.")
	model.end_week()
	if model.pressure != 0:
		return _fail("A valid synergy still paid the unrelated-topic pressure tax.")
	return true


func _test_single_topic_has_no_portfolio_tax() -> bool:
	var model := _model(
		[_definition(&"single", PackedStringArray(["theory"]))],
		3103
	)
	model.end_week()
	if model.pressure != 0:
		return _fail("Single-topic play incorrectly paid a portfolio pressure tax.")
	return true


func _test_freeze_decision() -> bool:
	var model := _model(
		[
			_definition(&"freeze_a", PackedStringArray(["theory"])),
			_definition(&"freeze_b", PackedStringArray(["engineering"])),
		],
		3104
	)
	var result := model.freeze_topic(1)
	if not bool(result.get("success", false)) or model.action_points != 3:
		return _fail("Freezing did not consume exactly one shared action.")
	var blocked := model.perform_action(DualTopicRunModel.ActionType.INVESTIGATE, 1)
	if blocked.get("reason", &"") != &"topic_frozen":
		return _fail("A frozen topic still accepted research actions.")
	model.end_week()
	if model.pressure != 0 or not model.frozen_topic_indices.is_empty():
		return _fail("Freeze did not avoid conflict pressure or reset next week.")
	return true


func _test_resource_transfer() -> bool:
	var model := _model(
		[
			_definition(&"transfer_a", PackedStringArray(["theory"])),
			_definition(&"transfer_b", PackedStringArray(["engineering"])),
		],
		3105
	)
	model.topics[1].evidence = 3
	var before_completion: int = model.topics[0].completion
	var result := model.transfer_topic_resources(1, 0)
	if not bool(result.get("success", false)):
		return _fail("A legal topic resource transfer was rejected.")
	if model.topics[1].evidence != 1:
		return _fail("Resource transfer did not spend two source evidence.")
	if model.topics[0].completion != before_completion + 1:
		return _fail("Resource transfer did not advance the target topic.")
	if model.pressure != 1 or model.action_points != 3:
		return _fail("Resource transfer did not apply its public costs.")
	var repeated := model.transfer_topic_resources(1, 0)
	if repeated.get("reason", &"") != &"portfolio_action_used":
		return _fail("Portfolio adjustment could be repeated in one week.")
	return true


func _test_early_archive_salvage() -> bool:
	var model := _model(
		[
			_definition(&"archive_a", PackedStringArray(["theory"])),
			_definition(&"archive_b", PackedStringArray(["engineering"])),
		],
		3106
	)
	var blocked := model.archive_topic_early(1, 0)
	if blocked.get("reason", &"") != &"archive_before_midterm":
		return _fail("Early archive was available before the midterm commitment.")
	model.week = 3
	var commitments: Array[DualTopicState.Commitment] = [
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.MAINTAIN,
	]
	if not bool(model.apply_midterm_commitments(commitments).get("success", false)):
		return _fail("Could not prepare the early-archive test commitment.")
	model.topics[1].evidence = 4
	model.topics[1].completion = 3
	model.topics[1].risks[0].identify()
	model.pressure = 2
	var result := model.archive_topic_early(1, 0)
	if not bool(result.get("success", false)):
		return _fail("Legal early archive was rejected.")
	if not model.topics[1].is_closed or model.get_portfolio_relation() != &"single":
		return _fail("Early archive did not close the secondary topic.")
	if model.topics[0].evidence != 2 or model.topics[0].completion != 1:
		return _fail("Early archive did not salvage progress into the main topic.")
	if not bool(result.get("risk_revealed", false)):
		return _fail("Revealed source risk did not create target risk insight.")
	if model.pressure != 1 or model.run_assets.size() != 1:
		return _fail("Early archive did not relieve pressure or preserve its asset.")
	model.week = DualTopicRunModel.MAX_WEEKS
	var final := model.resolve_run(&"withdraw", 0)
	if (final.get("run_assets", []) as Array).size() != 1:
		return _fail("Early archive asset was missing from the final resolution.")
	var next_model := _model(
		[_definition(&"next_cycle", PackedStringArray(["theory"]))],
		3107
	)
	var carryover_assets: Array[Dictionary] = []
	carryover_assets.assign(final.get("run_assets", []))
	var carryover := next_model.apply_carryover_assets(carryover_assets)
	if not bool(carryover.get("success", false)):
		return _fail("Next cycle rejected a valid archive asset.")
	if next_model.topics[0].evidence != 1 or next_model.topics[0].completion != 1:
		return _fail("Archive asset did not change the next cycle opening state.")
	if (
		next_model.topics[0].risks[0].knowledge_state
		!= DualTopicRiskState.KnowledgeState.IDENTIFIED
	):
		return _fail("Archive risk insight did not reveal the next cycle risk.")
	if (
		next_model.apply_carryover_assets(carryover_assets).get("reason", &"")
		!= &"carryover_already_applied"
	):
		return _fail("The same archive asset could be redeemed twice.")
	return true


func _definition(
	id_value: StringName,
	tags: PackedStringArray,
	special_rule: StringName = &""
) -> DualTopicDefinition:
	var risk := DualTopicRiskDefinition.new()
	risk.id = StringName("%s_risk" % id_value)
	risk.display_name = "Test risk"
	var definition := DualTopicDefinition.new()
	definition.id = id_value
	definition.display_name = String(id_value)
	definition.potential = DualTopicDefinition.Potential.MEDIUM
	definition.initial_evidence = 0
	definition.initial_completion = 0
	definition.risk_slot_count = 1
	definition.risk_pool = [risk]
	definition.synergy_tags = tags
	definition.special_rule = special_rule
	return definition


func _model(
	definitions: Array,
	run_seed: int
) -> DualTopicRunModel:
	var model := DualTopicRunModel.new()
	var typed_definitions: Array[DualTopicDefinition] = []
	typed_definitions.assign(definitions)
	if not model.setup(run_seed, typed_definitions):
		_fail("Could not set up portfolio model.")
	return model


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
