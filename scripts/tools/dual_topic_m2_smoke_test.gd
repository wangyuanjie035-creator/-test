extends RefCounted
class_name DualTopicM2SmokeTest

const RUN_MODEL := preload("res://scripts/dual_topic/model/dual_topic_run_model.gd")
const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")


func run() -> Array[String]:
	var failures: Array[String] = []
	var definitions: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	var model: DualTopicRunModel = RUN_MODEL.new()
	if not model.setup(240731, definitions):
		return ["Model setup failed."]

	var topic_b: DualTopicState = model.topics[1]
	var investigated: Dictionary = model.perform_action(
		DualTopicRunModel.ActionType.INVESTIGATE,
		1
	)
	_expect(bool(investigated.success), "Investigate failed.", failures)
	_expect(
		topic_b.risks[0].knowledge_state == DualTopicRiskState.KnowledgeState.IDENTIFIED,
		"Investigate did not reveal a risk.",
		failures
	)

	var experimented: Dictionary = model.perform_action(
		DualTopicRunModel.ActionType.EXPERIMENT,
		1
	)
	_expect(bool(experimented.success), "Experiment failed.", failures)
	_expect(
		topic_b.risks[0].knowledge_state == DualTopicRiskState.KnowledgeState.VERIFIED,
		"Experiment did not verify a risk.",
		failures
	)
	_expect(model.action_points == 2, "Weekly action points were not consumed.", failures)

	for expected_week: int in range(2, DualTopicRunModel.MAX_WEEKS + 1):
		_expect(model.end_week(), "Could not advance week.", failures)
		_expect(model.week == expected_week, "Week counter is not deterministic.", failures)
	_expect(not model.end_week(), "Week six was not final.", failures)
	_expect(model.can_finish_run(), "Run cannot finish at week six.", failures)

	var committed_model: DualTopicRunModel = RUN_MODEL.new()
	committed_model.setup(240731, definitions)
	var committed_topic: DualTopicState = committed_model.topics[1]
	committed_topic.evidence = 2
	committed_topic.apply_commitment(DualTopicState.Commitment.DOUBLE_DOWN)
	var first: Dictionary = committed_model.perform_action(
		DualTopicRunModel.ActionType.ORGANIZE,
		1
	)
	var second: Dictionary = committed_model.perform_action(
		DualTopicRunModel.ActionType.ORGANIZE,
		1
	)
	_expect(int(first.get("double_down_bonus", 0)) == 1, "Double-down bonus missing.", failures)
	_expect(not second.has("double_down_bonus"), "Double-down bonus repeated.", failures)
	var pressure_before: int = committed_model.pressure
	committed_model.end_week()
	_expect(
		committed_model.pressure == pressure_before + 1,
		"Double-down weekly pressure missing.",
		failures
	)
	return failures


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
