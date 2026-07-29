@tool
extends Resource
class_name AcademicOpportunityDefinition

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Availability")
@export_range(1, 2, 1) var minimum_completed_cycles: int = 1
@export_range(0, 10, 1) var minimum_prestige: int = 0
@export_range(0, 3, 1) var minimum_failure_assets: int = 0
@export var preferred_routes: PackedStringArray = []

@export_group("Public Cost And Effect")
@export_range(0, 3, 1) var next_cycle_pressure_cost: int = 1
@export var effect_id: StringName = &""
@export var destination_signal: StringName = &""
@export_multiline var public_effect_text: String = ""


func is_valid_definition() -> bool:
	return (
		id != &""
		and not display_name.is_empty()
		and not description.is_empty()
		and minimum_completed_cycles >= 1
		and minimum_completed_cycles <= 2
		and minimum_prestige >= 0
		and minimum_failure_assets >= 0
		and next_cycle_pressure_cost >= 0
		and not effect_id.is_empty()
		and not destination_signal.is_empty()
		and not public_effect_text.is_empty()
	)
