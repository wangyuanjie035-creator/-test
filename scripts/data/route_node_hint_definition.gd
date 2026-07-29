@tool
extends Resource
class_name RouteNodeHintDefinition

@export var id: StringName = &""
@export var risk_label: String = ""
@export var reward_tendency: String = ""
@export var accent_color: Color = Color(0.58, 0.66, 0.78)
@export_range(0, 30, 1) var experiment_focus_weight: int = 0
@export_range(0, 30, 1) var experiment_noise_weight: int = 0
@export_range(0, 30, 1) var funds_weight: int = 0
@export_range(0, 30, 1) var mentor_focus_weight: int = 0
@export_range(0, 30, 1) var reputation_weight: int = 0
@export_range(0, 30, 1) var paper_focus_weight: int = 0
@export_range(0, 30, 1) var paper_fragments_weight: int = 0
@export_range(0, 30, 1) var project_focus_weight: int = 0
