extends SceneTree

const SAFE_TOPIC: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/safe_topic_a.tres"
)


func _initialize() -> void:
	if not _validate_acceptance():
		return
	if not _validate_failure():
		return
	if not _validate_withdrawal():
		return
	print("PHASE_ONE_SUBMISSION: PASS")
	quit(0)


func _validate_acceptance() -> bool:
	var run: DualTopicRunModel = _new_final_week_run()
	var topic: DualTopicState = run.topics[0]
	topic.evidence = 4
	topic.completion = 4
	for risk: DualTopicRiskState in topic.risks:
		risk.is_controlled = true
	var preview: Dictionary = run.get_submission_preview(0)
	if not bool(preview.get("ready", false)):
		return _fail("Valid simplified submission was not ready.")
	var result: Dictionary = run.resolve_run(&"submit", 0)
	if result.get("grade", &"") != &"pass":
		return _fail("Valid simplified submission was not accepted.")
	if not Array(result.get("review_comments", [])).is_empty():
		return _fail("Simplified submission generated review comments.")
	return true


func _validate_failure() -> bool:
	var run: DualTopicRunModel = _new_final_week_run()
	run.topics[0].evidence = 5
	run.topics[0].completion = 2
	var result: Dictionary = run.resolve_run(&"submit", 0)
	if result.get("grade", &"") != &"failed":
		return _fail("Incomplete simplified submission did not fail.")
	var diagnosis: Dictionary = Dictionary(result.get("diagnosis", {}))
	if diagnosis.get("reason", &"") != &"completion_insufficient":
		return _fail("Simplified failure did not expose its first cause.")
	if run.converted_failure_asset_count != 1:
		return _fail("Simplified failure did not create one failure asset.")
	return true


func _validate_withdrawal() -> bool:
	var run: DualTopicRunModel = _new_final_week_run()
	var result: Dictionary = run.resolve_run(&"withdraw", 0)
	if result.get("grade", &"") != &"withdrawn":
		return _fail("Simplified withdrawal returned the wrong grade.")
	var terms: Dictionary = Dictionary(result.get("withdrawal_terms", {}))
	if not terms.has("retained_asset") or not terms.has("cost"):
		return _fail("Simplified withdrawal did not preserve asset and cost terms.")
	return true


func _new_final_week_run() -> DualTopicRunModel:
	var run := DualTopicRunModel.new()
	assert(run.setup(240731, [SAFE_TOPIC]))
	run.week = DualTopicRunModel.MAX_WEEKS
	run.midterm_resolved = true
	run.public_requirement = &"evidence_integrity"
	run.enable_simplified_submission()
	return run


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
