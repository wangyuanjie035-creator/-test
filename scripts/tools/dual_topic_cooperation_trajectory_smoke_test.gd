extends SceneTree

const SAFE_TOPIC: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/safe_topic_a.tres"
)
const BOLD_TOPIC: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/bold_topic_b.tres"
)
const METHOD_CATALOG: DualTopicMethodCatalog = preload(
	"res://data/dual_topic/methods/starter_method_catalog.tres"
)


func _init() -> void:
	var run := DualTopicRunModel.new()
	assert(run.setup(240731, [SAFE_TOPIC, BOLD_TOPIC]))
	assert(run.get_cooperation_trajectory() == {
		"cooperation_results": 0,
		"cross_topic_synergies": 0,
		"converted_failure_assets": 0,
	})

	var collaboration_card := _find_collaboration_card()
	assert(collaboration_card != null)
	var collaboration_result := run.perform_method_card(collaboration_card, 0)
	assert(bool(collaboration_result.get("success", false)))
	assert(run.cooperation_result_count == 1)

	run.week = DualTopicRunModel.MAX_WEEKS
	run.midterm_resolved = true
	var resolution := run.resolve_run(&"withdraw", 0)
	assert(bool(resolution.get("success", false)))
	assert(run.converted_failure_asset_count == 1)
	assert(resolution.get("cooperation_trajectory", {}) == run.get_cooperation_trajectory())

	print("dual_topic_cooperation_trajectory_smoke_test: PASS")
	quit(0)


func _find_collaboration_card() -> DualTopicMethodCardDefinition:
	for resource: Resource in METHOD_CATALOG.cards:
		var card := resource as DualTopicMethodCardDefinition
		if card.category == DualTopicMethodCardDefinition.Category.COLLABORATION:
			return card
	return null
