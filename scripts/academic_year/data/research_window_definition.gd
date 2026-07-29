@tool
extends Resource
class_name ResearchWindowDefinition

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_range(1, 10, 1) var minimum_evidence: int = 3
@export_range(1, 10, 1) var minimum_completion: int = 4
@export_range(0, 5, 1) var pressure_on_entry: int = 0
@export_range(0, 5, 1) var prestige: int = 1


func is_valid_definition() -> bool:
	return (
		id != &""
		and not display_name.is_empty()
		and minimum_evidence > 0
		and minimum_completion > 0
		and pressure_on_entry >= 0
		and pressure_on_entry <= 5
		and prestige > 0
	)
