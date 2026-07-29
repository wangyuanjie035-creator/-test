@tool
extends Resource
class_name CampusInteractionDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export var interaction_kind: StringName = &"encounter"
@export var route_node_id: StringName = &""
@export var resource_id: StringName = &""
@export_range(0, 99, 1) var resource_amount: int = 0
@export var content_tags: Array[StringName] = []
@export var position: Vector2 = Vector2.ZERO
@export_range(0, 64, 1) var jitter_radius: int = 14
@export var marker_state: StringName = &"default"
@export var accent_color: Color = Color(0.85, 0.72, 0.36)
@export var requirement_groups: Array[Resource] = []
