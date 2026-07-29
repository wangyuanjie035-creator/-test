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
@export_range(0, 3, 1) var minimum_growth_rank: int = 0
@export_range(1, 100, 1) var generation_weight: int = 50
@export_range(0, 3, 1) var base_potential: int = 0
@export_range(1, 3, 1) var base_risk_count: int = 1
@export_range(1, 5, 1) var base_reward: int = 1
@export_range(3, 8, 1) var min_deadline_weeks: int = 4
@export_range(3, 8, 1) var max_deadline_weeks: int = 6
@export var special_rule: StringName = &""
@export var risk_pool: Array[DualTopicRiskDefinition] = []

@export_group("Compatibility")
@export var generation_tags: PackedStringArray = []
@export var requires_context_tags: PackedStringArray = []
@export var forbidden_context_tags: PackedStringArray = []
@export var required_method_routes: PackedStringArray = []
@export var allowed_risk_kinds: PackedInt32Array = []
@export var safe_fallback: bool = false


func is_valid_definition() -> bool:
	return (
		id != &""
		and not display_name.is_empty()
		and minimum_growth_rank >= 0
		and minimum_growth_rank <= 3
		and generation_weight > 0
		and base_potential >= 0
		and base_potential <= 3
		and base_risk_count > 0
		and base_risk_count <= 3
		and base_reward > 0
		and min_deadline_weeks <= max_deadline_weeks
		and risk_pool.size() >= base_risk_count
		and not generation_tags.is_empty()
		and required_method_routes.size() >= 2
		and allowed_risk_kinds.size() >= base_risk_count
	)
