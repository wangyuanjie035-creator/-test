extends SceneTree

const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")

var failures: Array[String] = []


func _initialize() -> void:
	var blind_model := _new_model()
	var blind_result := blind_model.perform_action(
		DualTopicRunModel.ActionType.EXPERIMENT,
		1
	)
	_expect(blind_result.get("outcome", &"") == &"blind_probe", "Experiment did not open an unknown risk.")
	_expect(blind_model.pressure == 1, "Blind experiment should add one pressure.")

	var organize_model := _new_model()
	var organize_result := organize_model.perform_action(
		DualTopicRunModel.ActionType.ORGANIZE,
		1
	)
	_expect(
		organize_result.get("outcome", &"") == &"framework_prepared",
		"Organization did not create a low-power opening."
	)
	_expect(organize_model.topics[1].evidence == 1, "Preparation should create one evidence.")

	var write_model := _new_model()
	var write_result := write_model.perform_action(DualTopicRunModel.ActionType.WRITE, 1)
	_expect(write_result.get("outcome", &"") == &"outline_drafted", "Writing did not create an outline.")
	_expect(write_model.topics[1].completion == 1, "Outline should create one completion.")
	_expect(write_model.pressure == 1, "Premature writing should add one pressure.")

	var recover_model := _new_model()
	recover_model.pressure = 2
	var recover_result := recover_model.perform_action(DualTopicRunModel.ActionType.RECOVER)
	_expect(recover_result.get("outcome", &"") == &"decompressed", "Full-energy recovery should reduce pressure.")
	_expect(recover_model.pressure == 0, "Decompression should remove two pressure.")

	if failures.is_empty():
		print("DUAL_TOPIC_SOFT_PREREQUISITES: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("DUAL_TOPIC_SOFT_PREREQUISITES: FAIL (%d)" % failures.size())
	quit(1)


func _new_model() -> DualTopicRunModel:
	var model := DualTopicRunModel.new()
	var topics: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	model.setup(240731, topics)
	return model


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
