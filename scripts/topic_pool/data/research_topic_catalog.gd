@tool
extends Resource
class_name ResearchTopicCatalog

@export var archetypes: Array[ResearchTopicArchetype] = []


func is_valid_catalog() -> bool:
	if archetypes.size() < 3:
		return false
	var ids: Dictionary[StringName, bool] = {}
	for archetype: ResearchTopicArchetype in archetypes:
		if archetype == null or not archetype.is_valid_definition() or ids.has(archetype.id):
			return false
		ids[archetype.id] = true
	return true
