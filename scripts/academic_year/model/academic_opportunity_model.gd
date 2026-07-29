extends RefCounted
class_name AcademicOpportunityModel

const OPPORTUNITY_DEFINITION := preload(
	"res://scripts/academic_year/data/academic_opportunity_definition.gd"
)

var seed: int = 1
var definitions: Array[Resource] = []
var pending_opportunity: Resource
var decision_history: Array[Dictionary] = []


func setup(
	run_seed: int,
	opportunity_definitions: Array[Resource]
) -> bool:
	if opportunity_definitions.is_empty():
		return false
	for definition: Resource in opportunity_definitions:
		if definition == null or not definition.is_valid_definition():
			return false
	seed = maxi(1, run_seed)
	definitions = opportunity_definitions.duplicate()
	pending_opportunity = null
	decision_history.clear()
	return true


func generate_offer(
	completed_cycles: int,
	context: Dictionary
) -> Dictionary:
	if pending_opportunity != null:
		return {"success": false, "reason": &"offer_already_pending"}
	var eligible: Array[Resource] = []
	for definition: Resource in definitions:
		if _is_eligible(definition, completed_cycles, context):
			eligible.append(definition)
	if eligible.is_empty():
		return {"success": false, "reason": &"no_eligible_opportunity"}
	var index: int = posmod(seed + completed_cycles * 104729, eligible.size())
	pending_opportunity = eligible[index]
	return {
		"success": true,
		"opportunity": get_pending_offer(),
	}


func resolve_offer(accepted: bool) -> Dictionary:
	if pending_opportunity == null:
		return {"success": false, "reason": &"no_pending_opportunity"}
	var definition: Resource = pending_opportunity
	var record := {
		"opportunity_id": definition.id,
		"accepted": accepted,
		"pressure_cost": definition.next_cycle_pressure_cost if accepted else 0,
		"effect_id": definition.effect_id if accepted else &"",
		"destination_signal": definition.destination_signal if accepted else &"",
	}
	decision_history.append(record)
	pending_opportunity = null
	return {
		"success": true,
		"accepted": accepted,
		"record": record.duplicate(true),
	}


func get_pending_offer() -> Dictionary:
	if pending_opportunity == null:
		return {}
	return {
		"id": pending_opportunity.id,
		"display_name": pending_opportunity.display_name,
		"description": pending_opportunity.description,
		"pressure_cost": pending_opportunity.next_cycle_pressure_cost,
		"effect_id": pending_opportunity.effect_id,
		"destination_signal": pending_opportunity.destination_signal,
		"public_effect_text": pending_opportunity.public_effect_text,
	}


func _is_eligible(
	definition: Resource,
	completed_cycles: int,
	context: Dictionary
) -> bool:
	if completed_cycles < definition.minimum_completed_cycles:
		return false
	if int(context.get("prestige", 0)) < definition.minimum_prestige:
		return false
	if (
		int(context.get("failure_assets", 0))
		< definition.minimum_failure_assets
	):
		return false
	var route_id := StringName(context.get("route_id", &"single"))
	return (
		definition.preferred_routes.is_empty()
		or definition.preferred_routes.has(String(route_id))
	)
