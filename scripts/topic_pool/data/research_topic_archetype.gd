@tool
extends Resource
class_name ResearchTopicArchetype

enum DifficultyTier {
	ROUTINE,
	ADVANCED,
	FRONTIER,
	FORBIDDEN,
}

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var premise: String = ""
@export var discipline: StringName = &"general"
@export var tags: PackedStringArray = []

@export_group("Generation")
@export var difficulty_tier: DifficultyTier = DifficultyTier.ROUTINE
@export_range(0, 3, 1) var base_potential: int = 0
@export_range(1, 3, 1) var base_risk_count: int = 1
@export_range(1, 5, 1) var base_reward: int = 1
@export_range(3, 8, 1) var min_deadline_weeks: int = 4
@export_range(3, 8, 1) var max_deadline_weeks: int = 6
@export var special_rule: StringName = &""
@export var risk_pool: Array[DualTopicRiskDefinition] = []


func is_valid_definition() -> bool:
	return (
		id != &""
		and not display_name.is_empty()
		and base_potential >= 0
		and base_potential <= 3
		and base_risk_count > 0
		and base_risk_count <= 3
		and base_reward > 0
		and min_deadline_weeks <= max_deadline_weeks
		and risk_pool.size() >= base_risk_count
	)
