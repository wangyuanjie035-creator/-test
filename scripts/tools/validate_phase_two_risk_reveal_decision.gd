extends SceneTree

const SAFE_TOPIC: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/safe_topic_a.tres"
)


func _initialize() -> void:
	var run := DualTopicRunModel.new()
	if not run.setup(240731, [SAFE_TOPIC]):
		_fail("Could not start the risk reveal test.")
		return
	var result: Dictionary = run.perform_action(
		DualTopicRunModel.ActionType.INVESTIGATE,
		0
	)
	if not bool(result.get("success", false)):
		_fail("Investigation did not reveal a risk.")
		return
	for field: String in [
		"risk_id",
		"risk_name",
		"risk_kind",
		"tier",
		"submission_blocked",
		"withdrawal_asset",
	]:
		if not result.has(field):
			_fail("Risk reveal omitted decision field %s." % field)
			return
	if result.get("withdrawal_asset", &"") != &"risk_insight":
		_fail("Risk reveal did not expose its withdrawal value.")
		return
	print("PHASE_TWO_RISK_REVEAL_DECISION: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
