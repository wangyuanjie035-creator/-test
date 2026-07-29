class_name ResearchEncounterDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_range(1, 20, 1) var turn_limit: int = 5
@export_range(1, 999, 1) var target_score: int = 100
@export var is_boss: bool = false

