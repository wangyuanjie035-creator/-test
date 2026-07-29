extends SceneTree

const TOPIC_A: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/safe_topic_a.tres"
)
const TOPIC_B: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/bold_topic_b.tres"
)


func _initialize() -> void:
	if not _validate_full_energy_fallback():
		return
	if not _validate_empty_energy_fallback():
		return
	if not _validate_frozen_target_fallback():
		return
	print("DUAL_TOPIC_NO_DEAD_TURN: PASS")
	quit(0)


func _validate_full_energy_fallback() -> bool:
	var model: DualTopicRunModel = _new_model()
	if not model.can_perform_basic_action(
		DualTopicRunModel.ActionType.ORGANIZE,
		0
	):
		return _fail("Full-energy opening had no legal basic action.")
	var result: Dictionary = model.perform_basic_action(
		DualTopicRunModel.ActionType.ORGANIZE,
		0
	)
	if not bool(result.get("success", false)):
		return _fail("Basic organization action failed.")
	if not bool(result.get("basic_action", false)):
		return _fail("Basic action was not marked in history.")
	if model.method_category_uses != [0, 0, 0, 0, 0]:
		return _fail("Basic action incorrectly advanced method mastery.")
	return true


func _validate_empty_energy_fallback() -> bool:
	var model: DualTopicRunModel = _new_model()
	model.energy = 0
	if not model.can_perform_basic_action(DualTopicRunModel.ActionType.RECOVER):
		return _fail("Zero-energy state had no recovery fallback.")
	var result: Dictionary = model.perform_basic_action(
		DualTopicRunModel.ActionType.RECOVER
	)
	if not bool(result.get("success", false)) or model.energy <= 0:
		return _fail("Basic recovery did not restore energy.")
	return true


func _validate_frozen_target_fallback() -> bool:
	var model: DualTopicRunModel = _new_model()
	model.frozen_topic_indices[0] = true
	if model.can_perform_basic_action(
		DualTopicRunModel.ActionType.ORGANIZE,
		0
	):
		return _fail("Frozen topic accepted a basic action.")
	if not model.can_perform_basic_action(
		DualTopicRunModel.ActionType.ORGANIZE,
		1
	):
		return _fail("Active secondary topic did not preserve a legal action.")
	return true


func _new_model() -> DualTopicRunModel:
	var model := DualTopicRunModel.new()
	assert(model.setup(240731, [TOPIC_A, TOPIC_B]))
	return model


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
