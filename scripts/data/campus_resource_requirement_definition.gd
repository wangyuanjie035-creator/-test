@tool
extends Resource
class_name CampusResourceRequirementDefinition

@export var resource_id: StringName = &""
@export_range(0, 99, 1) var amount: int = 0
