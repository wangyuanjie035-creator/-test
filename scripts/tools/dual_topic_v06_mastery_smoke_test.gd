extends SceneTree

const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")
const CATALOG := preload("res://data/dual_topic/methods/starter_method_catalog.tres")


func _init() -> void:
	var investigation_run := _new_run()
	var investigation_card := _card(&"targeted_reading")
	for index: int in range(3):
		var result := investigation_run.perform_method_card(
			investigation_card,
			mini(index, 1)
		)
		assert(result.success)
	assert(investigation_run.method_category_uses[0] == 3)
	assert(
		investigation_run.action_history.back().get("mastery_unlocked", false)
	)

	var experiment_run := _new_run()
	var investigation := _card(&"targeted_reading")
	var experiment := _card(&"stress_test")
	for index: int in range(3):
		if experiment_run.action_points <= 1:
			experiment_run.end_week()
		experiment_run.perform_method_card(investigation, 0)
		var experiment_result := experiment_run.perform_method_card(experiment, 0)
		assert(experiment_result.success)
	assert(experiment_run.method_category_uses[1] == 3)

	var organization_run := _new_run()
	var organization := _card(&"evidence_ledger")
	for index: int in range(3):
		var organization_result := organization_run.perform_method_card(
			organization,
			0
		)
		assert(organization_result.success)
	assert(organization_run.method_category_uses[2] == 3)
	print("DUAL_TOPIC_V06_MASTERY_SMOKE_OK")
	quit()


func _new_run() -> DualTopicRunModel:
	var run := DualTopicRunModel.new()
	assert(run.setup(240731, [TOPIC_A, TOPIC_B]))
	return run


func _card(card_id: StringName) -> DualTopicMethodCardDefinition:
	for resource: Resource in CATALOG.cards:
		var card := resource as DualTopicMethodCardDefinition
		if card.id == card_id:
			return card
	assert(false, "missing card: %s" % card_id)
	return null
