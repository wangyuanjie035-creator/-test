extends SceneTree

const RUN_MODEL := preload("res://scripts/dual_topic/model/dual_topic_run_model.gd")
const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")

var failures: Array[String] = []


func _initialize() -> void:
	_test_definitions()
	_test_seed_determinism()
	_test_risk_state_machine()
	_test_submission_rules()
	_test_midterm_choices()
	_test_six_week_action_loop()
	_test_pressure_thresholds()
	_test_double_down_weekly_cost_and_bonus()
	if failures.is_empty():
		print("DUAL_TOPIC_MODEL: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("DUAL_TOPIC_MODEL: FAIL (%d)" % failures.size())
		quit(1)


func _test_definitions() -> void:
	_expect(TOPIC_A.is_valid_definition(), "Topic A definition should be valid.")
	_expect(TOPIC_B.is_valid_definition(), "Topic B definition should be valid.")
	_expect(not TOPIC_A.can_receive_excellent, "Topic A must not receive excellent.")
	_expect(TOPIC_B.can_receive_excellent, "Topic B should be eligible for excellent.")


func _test_seed_determinism() -> void:
	var first := RUN_MODEL.new()
	var second := RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	_expect(first.setup(240731, definitions), "First deterministic setup failed.")
	_expect(second.setup(240731, definitions), "Second deterministic setup failed.")
	_expect(
		JSON.stringify(first.to_debug_dict()) == JSON.stringify(second.to_debug_dict()),
		"Same seed should generate identical topic and risk state."
	)


func _test_risk_state_machine() -> void:
	var model := RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	model.setup(240731, definitions)
	var risk: DualTopicRiskState = model.topics[1].risks[0]
	_expect(not risk.verify(), "Unknown risk must not skip directly to verified.")
	_expect(risk.identify(), "Unknown risk should become identified.")
	_expect(not risk.identify(), "Identified risk should not identify twice.")
	_expect(risk.verify(), "Identified risk should become verified.")
	_expect(not risk.verify(), "Verified risk should not verify twice.")


func _test_submission_rules() -> void:
	var model := RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	model.setup(240731, definitions)
	var topic_a: DualTopicState = model.topics[0]
	var topic_b: DualTopicState = model.topics[1]
	topic_a.evidence = 3
	topic_a.completion = 4
	for risk: DualTopicRiskState in topic_a.risks:
		risk.identify()
		risk.control()
	_expect(model.get_submission_result(0) == &"pass", "Topic A should pass at minimum.")
	topic_a.evidence = 5
	topic_a.completion = 5
	_expect(model.get_submission_result(0) == &"pass", "Topic A must never become excellent.")

	topic_b.evidence = 4
	topic_b.completion = 5
	for risk: DualTopicRiskState in topic_b.risks:
		risk.identify()
		risk.control()
	_expect(model.get_submission_result(1) == &"excellent", "Resolved Topic B should be excellent.")


func _test_midterm_choices() -> void:
	var model := RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	model.setup(240731, definitions)
	var topic_b: DualTopicState = model.topics[1]
	topic_b.completion = 2
	var original_risk_count := topic_b.risks.size()
	_expect(topic_b.apply_commitment(DualTopicState.Commitment.SPLIT), "Split should be accepted.")
	_expect(topic_b.completion == 3, "Split should add one completion.")
	_expect(topic_b.risks.size() == original_risk_count - 1, "Split should remove one risk slot.")
	_expect(
		not topic_b.apply_commitment(DualTopicState.Commitment.DOUBLE_DOWN),
		"Commitment should be irreversible."
	)


func _test_six_week_action_loop() -> void:
	var model := _new_model()
	var topic_b: DualTopicState = model.topics[1]
	var investigate: Dictionary = model.perform_action(
		DualTopicRunModel.ActionType.INVESTIGATE,
		1
	)
	_expect(bool(investigate.success), "Investigate should consume an action and reveal a risk.")
	_expect(
		topic_b.risks[0].knowledge_state == DualTopicRiskState.KnowledgeState.IDENTIFIED,
		"Investigate should identify the first unknown risk."
	)
	var experiment: Dictionary = model.perform_action(
		DualTopicRunModel.ActionType.EXPERIMENT,
		1
	)
	_expect(bool(experiment.success), "Experiment should resolve an identified risk.")
	_expect(
		topic_b.risks[0].knowledge_state == DualTopicRiskState.KnowledgeState.VERIFIED,
		"Experiment should verify the investigated risk."
	)
	_expect(model.action_points == 2, "Two actions should leave two weekly action points.")
	for expected_week in range(2, DualTopicRunModel.MAX_WEEKS + 1):
		_expect(model.end_week(), "Week %d should advance." % (expected_week - 1))
		_expect(model.week == expected_week, "Week counter should advance deterministically.")
	_expect(not model.end_week(), "Week six must be the final playable week.")
	_expect(model.can_finish_run(), "Run should be finishable at week six.")
	_expect(model.week_history.size() == 5, "Five transitions should be archived.")


func _test_pressure_thresholds() -> void:
	var model := _new_model()
	model.pressure = 3
	_expect(model.should_add_interference_card(), "Pressure three should add interference.")
	model.pressure = 5
	_expect(model.get_draw_penalty() == 1, "Pressure five should reduce next draw.")
	model.energy = 1
	var topic_b: DualTopicState = model.topics[1]
	topic_b.evidence = 2
	var result: Dictionary = model.perform_action(DualTopicRunModel.ActionType.WRITE, 1)
	_expect(bool(result.success), "A final exhausting action should still resolve.")
	_expect(model.energy == 0, "Strong action should be allowed to exhaust energy.")
	_expect(model.action_points == 0, "Energy zero should end remaining weekly actions.")
	_expect(model.pressure == 5, "Pressure should remain capped at five.")


func _test_double_down_weekly_cost_and_bonus() -> void:
	var model := _new_model()
	var topic_b: DualTopicState = model.topics[1]
	topic_b.evidence = 2
	_expect(
		topic_b.apply_commitment(DualTopicState.Commitment.DOUBLE_DOWN),
		"Double down should be accepted once."
	)
	var first: Dictionary = model.perform_action(DualTopicRunModel.ActionType.ORGANIZE, 1)
	var second: Dictionary = model.perform_action(DualTopicRunModel.ActionType.ORGANIZE, 1)
	_expect(int(first.get("double_down_bonus", 0)) == 1, "First weekly action should gain +1.")
	_expect(not second.has("double_down_bonus"), "Only the first weekly action gets the bonus.")
	var pressure_before: int = model.pressure
	model.end_week()
	_expect(model.pressure == pressure_before + 1, "Double down should add weekly pressure.")


func _new_model() -> DualTopicRunModel:
	var model := RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	_expect(model.setup(240731, definitions), "Shared model setup failed.")
	return model


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
