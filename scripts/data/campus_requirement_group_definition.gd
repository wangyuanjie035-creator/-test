@tool
extends Resource
class_name CampusRequirementGroupDefinition

const MODE_ALL := &"all"
const MODE_ANY := &"any"

@export var mode: StringName = MODE_ALL
@export var items: Array[Resource] = []
