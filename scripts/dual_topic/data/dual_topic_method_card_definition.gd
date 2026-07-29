extends Resource
class_name DualTopicMethodCardDefinition

enum Category {
	INVESTIGATION,
	EXPERIMENT,
	ORGANIZATION,
	COLLABORATION,
	SURVIVAL,
}

enum TargetScope {
	TOPIC,
	SELF,
}

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var category: Category = Category.INVESTIGATION
@export var target_scope: TargetScope = TargetScope.TOPIC
@export var action_type: DualTopicRunModel.ActionType = DualTopicRunModel.ActionType.INVESTIGATE
@export var effect_id: StringName = &"basic"


func is_valid_definition() -> bool:
	return (
		not id.is_empty()
		and not title.is_empty()
		and not effect_id.is_empty()
		and (
			target_scope == TargetScope.SELF
			or action_type != DualTopicRunModel.ActionType.RECOVER
		)
	)
