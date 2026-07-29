@tool
extends Resource
class_name CampusStageDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var debug_label: String = ""
@export_range(0, 99, 1) var sort_order: int = 0
@export_range(1, 99, 1) var generation_target_interaction_count: int = 12
@export var generation_focus_tags: Array[StringName] = []
@export var generation_required_tags: Array[StringName] = []
@export var generation_theme_ids: Array[StringName] = []
@export var generation_candidate_interactions: Array[Resource] = []
@export var interactions: Array[Resource] = []
