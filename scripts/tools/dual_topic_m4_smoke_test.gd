extends RefCounted
class_name DualTopicM4SmokeTest

const RUN_MODEL := preload("res://scripts/dual_topic/model/dual_topic_run_model.gd")
const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_atomic_guards(failures)
	_test_pivot(failures)
	_test_split_and_double_down(failures)
	_test_stop_asset(failures)
	return failures


func _test_atomic_guards(failures: Array[String]) -> void:
	var run: DualTopicRunModel = _new_run()
	var early: Dictionary = run.apply_midterm_decisions(
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.MAINTAIN
	)
	_expect(early.get("reason", &"") == &"not_midterm_week", "Midterm opened early.", failures)
	_advance_to_week_three(run)
	var rejected: Dictionary = run.apply_midterm_decisions(
		DualTopicState.Commitment.STOPPED,
		DualTopicState.Commitment.STOPPED
	)
	_expect(
		rejected.get("reason", &"") == &"must_keep_one_topic",
		"Both topics were allowed to stop.",
		failures
	)
	_expect(
		run.topics[0].commitment == DualTopicState.Commitment.UNDECIDED
		and run.topics[1].commitment == DualTopicState.Commitment.UNDECIDED,
		"Rejected decisions partially mutated topics.",
		failures
	)


func _test_pivot(failures: Array[String]) -> void:
	var run: DualTopicRunModel = _new_run()
	_advance_to_week_three(run)
	var topic_b: DualTopicState = run.topics[1]
	topic_b.completion = 2
	topic_b.evidence = 3
	topic_b.risks[0].identify()
	var old_risk_id: StringName = topic_b.risks[0].definition.id
	var result: Dictionary = run.apply_midterm_decisions(
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.PIVOT
	)
	_expect(bool(result.get("success", false)), "Valid pivot was rejected.", failures)
	_expect(topic_b.completion == 1, "Pivot should cost one completion.", failures)
	_expect(topic_b.evidence == 3, "Pivot should preserve evidence.", failures)
	_expect(
		topic_b.risks[0].knowledge_state == DualTopicRiskState.KnowledgeState.UNKNOWN,
		"Pivot replacement risk should return to unknown.",
		failures
	)
	_expect(topic_b.risks[0].definition.id != old_risk_id, "Pivot reused the same risk.", failures)
	var repeated: Dictionary = run.apply_midterm_decisions(
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.MAINTAIN
	)
	_expect(
		repeated.get("reason", &"") == &"midterm_already_resolved",
		"Midterm decision was reversible.",
		failures
	)


func _test_split_and_double_down(failures: Array[String]) -> void:
	var split_run: DualTopicRunModel = _new_run()
	_advance_to_week_three(split_run)
	var split_topic: DualTopicState = split_run.topics[1]
	split_topic.completion = 1
	var old_potential: int = split_topic.potential
	var old_risk_count: int = split_topic.risks.size()
	var split: Dictionary = split_run.apply_midterm_decisions(
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.SPLIT
	)
	_expect(bool(split.get("success", false)), "Split was rejected.", failures)
	_expect(split_topic.potential == old_potential - 1, "Split did not lower potential.", failures)
	_expect(split_topic.completion == 2, "Split did not add completion.", failures)
	_expect(split_topic.risks.size() == old_risk_count - 1, "Split did not remove risk.", failures)

	var double_run: DualTopicRunModel = _new_run()
	_advance_to_week_three(double_run)
	var doubled: Dictionary = double_run.apply_midterm_decisions(
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.DOUBLE_DOWN
	)
	_expect(bool(doubled.get("success", false)), "Double down was rejected.", failures)
	_expect(
		double_run.topics[1].commitment == DualTopicState.Commitment.DOUBLE_DOWN,
		"Double down commitment was not stored.",
		failures
	)


func _test_stop_asset(failures: Array[String]) -> void:
	var run: DualTopicRunModel = _new_run()
	run.topics[0].risks[0].identify()
	_advance_to_week_three(run)
	var result: Dictionary = run.apply_midterm_decisions(
		DualTopicState.Commitment.STOPPED,
		DualTopicState.Commitment.MAINTAIN
	)
	_expect(bool(result.get("success", false)), "Single-topic stop was rejected.", failures)
	_expect(run.topics[0].is_closed, "Stopped topic is still active.", failures)
	_expect(not run.topics[1].is_closed, "Retained topic was closed.", failures)
	_expect(run.run_assets.size() == 1, "Stopping should create one run asset.", failures)
	_expect(
		not run.run_assets[0].risk_insights.is_empty(),
		"Stop asset should preserve revealed risk knowledge.",
		failures
	)


func _new_run() -> DualTopicRunModel:
	var run: DualTopicRunModel = RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	run.setup(240731, definitions)
	return run


func _advance_to_week_three(run: DualTopicRunModel) -> void:
	run.end_week()
	run.end_week()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
