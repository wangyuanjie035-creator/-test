@tool
extends Resource
class_name DualTopicRiskDefinition

enum RiskKind {
	THEORY,
	DATA,
	TECHNICAL,
	EXPRESSION,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: RiskKind = RiskKind.THEORY
@export_multiline var description: String = ""


func is_valid_definition() -> bool:
	return id != &"" and not display_name.is_empty()
