extends RefCounted
class_name DualTopicM5SmokeTest

const RUN_MODEL := preload("res://scripts/dual_topic/model/dual_topic_run_model.gd")
const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_final_week_guard(failures)
	_test_pass_and_excellent_legacies(failures)
	_test_withdrawal_legacy(failures)
	_test_failure_diagnosis(failures)
	_test_final_determinism(failures)
	return failures


func _test_final_week_guard(failures: Array[String]) -> void:
	var run: DualTopicRunModel = _new_run()
	var early: Dictionary = run.resolve_run(&"submit", 0)
	_expect(early.get("reason", &"") == &"not_final_week", "Submission opened early.", failures)


func _test_pass_and_excellent_legacies(failures: Array[String]) -> void:
	var pass_run: DualTopicRunModel = _ready_for_final()
	_prepare_success(pass_run.topics[0])
	var passed: Dictionary = pass_run.resolve_run(&"submit", 0)
	_expect(passed.get("grade", &"") == &"pass", "Safe topic should pass.", failures)
	_expect(
		passed.legacy.get("type", &"") == &"mature_method",
		"Success should grant a mature method.",
		failures
	)
	_expect(
		not pass_run.resolve_run(&"submit", 0).get("success", false),
		"Final resolution should be irreversible.",
		failures
	)

	var excellent_run: DualTopicRunModel = _ready_for_final()
	_prepare_success(excellent_run.topics[1])
	var excellent: Dictionary = excellent_run.resolve_run(&"submit", 1)
	_expect(excellent.get("grade", &"") == &"excellent", "Bold topic should be excellent.", failures)


func _test_withdrawal_legacy(failures: Array[String]) -> void:
	var run: DualTopicRunModel = _ready_for_final()
	run.topics[1].risks[0].identify()
	var result: Dictionary = run.resolve_run(&"withdraw", 1)
	_expect(result.get("grade", &"") == &"withdrawn", "Withdrawal grade is wrong.", failures)
	_expect(
		result.legacy.get("type", &"") == &"risk_insight",
		"Withdrawal should grant risk insight.",
		failures
	)
	_expect(
		result.legacy.get("risk_id", &"") == run.topics[1].risks[0].definition.id,
		"Withdrawal did not preserve revealed risk.",
		failures
	)


func _test_failure_diagnosis(failures: Array[String]) -> void:
	var run: DualTopicRunModel = _ready_for_final()
	var topic: DualTopicState = run.topics[0]
	topic.completion = 5
	topic.evidence = 1
	var result: Dictionary = run.resolve_run(&"submit", 0)
	_expect(result.get("grade", &"") == &"failed", "Invalid topic did not fail.", failures)
	_expect(
		result.diagnosis.get("reason", &"") == &"evidence_insufficient",
		"Failure did not explain its evidence breakpoint.",
		failures
	)
	_expect(
		result.legacy.get("type", &"") == &"remediation_method",
		"Failure should grant a remediation method.",
		failures
	)


func _test_final_determinism(failures: Array[String]) -> void:
	var first: DualTopicRunModel = _ready_for_final()
	var second: DualTopicRunModel = _ready_for_final()
	_prepare_success(first.topics[1])
	_prepare_success(second.topics[1])
	var first_result: Dictionary = first.resolve_run(&"submit", 1)
	var second_result: Dictionary = second.resolve_run(&"submit", 1)
	_expect(
		JSON.stringify(first_result) == JSON.stringify(second_result),
		"Same seed and state should produce identical final results.",
		failures
	)


func _new_run() -> DualTopicRunModel:
	var run: DualTopicRunModel = RUN_MODEL.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	run.setup(240731, definitions)
	return run


func _ready_for_final() -> DualTopicRunModel:
	var run: DualTopicRunModel = _new_run()
	run.end_week()
	run.end_week()
	run.apply_midterm_decisions(
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.MAINTAIN
	)
	run.end_week()
	run.end_week()
	run.end_week()
	return run


func _prepare_success(topic: DualTopicState) -> void:
	topic.evidence = 5
	topic.completion = 5
	for risk: DualTopicRiskState in topic.risks:
		risk.identify()
		risk.control()


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
