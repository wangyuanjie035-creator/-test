@tool
extends Resource
class_name CampusRouteRequirementDefinition

const INTERCEPT_WARN_ONLY := &"warn_only"
const INTERCEPT_SOFT_GATE := &"soft_gate"
const INTERCEPT_HARD_GATE := &"hard_gate"

@export var route_node_id: StringName = &""
@export var intercept_mode: StringName = INTERCEPT_SOFT_GATE
@export var requirement_groups: Array[Resource] = []
