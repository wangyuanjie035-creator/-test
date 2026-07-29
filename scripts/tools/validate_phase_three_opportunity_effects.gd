extends SceneTree

const ADAPTER := preload(
	"res://scripts/academic_year/model/academic_opportunity_effect_adapter.gd"
)
const TOPIC: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/bold_topic_b.tres"
)


func _initialize() -> void:
	if not _validate_collaboration():
		return
	if not _validate_industry():
		return
	if not _validate_startup():
		return
	if not _validate_rejection():
		return
	print("PHASE_THREE_OPPORTUNITY_EFFECTS: PASS")
	quit(0)


func _validate_collaboration() -> bool:
	var model: DualTopicRunModel = _model()
	var modifier: Dictionary = ADAPTER.to_opening_modifier(
		_decision(&"cooperation_opening", true)
	)
	var result: Dictionary = model.apply_opening_modifier(modifier)
	return _expect(
		bool(result.get("success", false))
		and model.action_points == DualTopicRunModel.ACTION_POINTS_PER_WEEK + 1,
		"Collaboration did not grant one opening action."
	)


func _validate_industry() -> bool:
	var model: DualTopicRunModel = _model()
	var result: Dictionary = model.apply_opening_modifier(
		ADAPTER.to_opening_modifier(_decision(&"industry_window", true))
	)
	var record: Dictionary = result.get("record", {})
	return _expect(
		int(record.get("evidence_gain", 0)) == 1
		and int(record.get("risks_revealed", 0)) == 1,
		"Industry feedback did not add evidence and reveal one risk."
	)


func _validate_startup() -> bool:
	var model: DualTopicRunModel = _model()
	var result: Dictionary = model.apply_opening_modifier(
		ADAPTER.to_opening_modifier(_decision(&"failure_asset_pilot", true))
	)
	var record: Dictionary = result.get("record", {})
	return _expect(
		int(record.get("evidence_gain", 0)) == 1
		and int(record.get("completion_gain", 0)) == 1,
		"The failure-asset pilot did not create an opening prototype."
	)


func _validate_rejection() -> bool:
	var modifier: Dictionary = ADAPTER.to_opening_modifier(
		_decision(&"cooperation_opening", false)
	)
	return _expect(modifier.is_empty(), "A rejected opportunity still granted a bonus.")


func _model() -> DualTopicRunModel:
	var model := DualTopicRunModel.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC]
	if not model.setup(240731, definitions):
		_fail("Could not prepare the research model.")
	return model


func _decision(effect_id: StringName, accepted: bool) -> Dictionary:
	return {
		"accepted": accepted,
		"effect_id": effect_id,
	}


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("PHASE_THREE_OPPORTUNITY_EFFECTS: %s" % message)
	quit(1)
