extends RefCounted
class_name AcademicOpportunityModel

const OPPORTUNITY_DEFINITION := preload(
	"res://scripts/academic_year/data/academic_opportunity_definition.gd"
)

var seed: int = 1
var definitions: Array[Resource] = []
var pending_opportunities: Array[Resource] = []
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
	pending_opportunities.clear()
	decision_history.clear()
	return true


func generate_offer(
	completed_cycles: int,
	context: Dictionary
) -> Dictionary:
	var result: Dictionary = generate_offers(completed_cycles, context)
	if not bool(result.get("success", false)):
		return result
	var offers: Array = result.get("opportunities", [])
	return {
		"success": true,
		"opportunity": offers[0] if not offers.is_empty() else {},
		"opportunities": offers,
	}


func generate_offers(
	completed_cycles: int,
	context: Dictionary
) -> Dictionary:
	if not pending_opportunities.is_empty():
		return {"success": false, "reason": &"offer_already_pending"}
	var eligible: Array[Resource] = []
	for definition: Resource in definitions:
		if _is_eligible(definition, completed_cycles, context):
			eligible.append(definition)
	if eligible.is_empty():
		return {"success": false, "reason": &"no_eligible_opportunity"}
	var start_index: int = posmod(seed + completed_cycles * 104729, eligible.size())
	var offer_count: int = mini(2, eligible.size())
	for offset: int in range(offer_count):
		pending_opportunities.append(eligible[(start_index + offset) % eligible.size()])
	return {
		"success": true,
		"opportunities": get_pending_offers(),
	}


func resolve_offer(accepted: bool) -> Dictionary:
	var selected_id: StringName = &""
	if accepted and not pending_opportunities.is_empty():
		selected_id = pending_opportunities[0].id
	return resolve_offer_choice(selected_id)


func resolve_offer_choice(selected_id: StringName) -> Dictionary:
	if pending_opportunities.is_empty():
		return {"success": false, "reason": &"no_pending_opportunity"}
	var definition: Resource
	if selected_id != &"":
		for candidate: Resource in pending_opportunities:
			if candidate.id == selected_id:
				definition = candidate
				break
		if definition == null:
			return {"success": false, "reason": &"invalid_opportunity_choice"}
	var accepted: bool = definition != null
	var record := {
		"opportunity_id": definition.id if accepted else &"",
		"accepted": accepted,
		"pressure_cost": definition.next_cycle_pressure_cost if accepted else 0,
		"effect_id": definition.effect_id if accepted else &"",
		"destination_signal": definition.destination_signal if accepted else &"",
		"declined_opportunity_ids": _get_declined_ids(selected_id),
	}
	decision_history.append(record)
	pending_opportunities.clear()
	return {
		"success": true,
		"accepted": accepted,
		"record": record.duplicate(true),
	}


func get_pending_offer() -> Dictionary:
	var offers: Array[Dictionary] = get_pending_offers()
	if offers.is_empty():
		return {}
	return offers[0]


func get_pending_offers() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for opportunity: Resource in pending_opportunities:
		offers.append(_present_opportunity(opportunity))
	return offers


func _present_opportunity(opportunity: Resource) -> Dictionary:
	return {
		"id": opportunity.id,
		"display_name": opportunity.display_name,
		"description": opportunity.description,
		"pressure_cost": opportunity.next_cycle_pressure_cost,
		"effect_id": opportunity.effect_id,
		"destination_signal": opportunity.destination_signal,
		"public_effect_text": opportunity.public_effect_text,
	}


func _get_declined_ids(selected_id: StringName) -> Array[StringName]:
	var declined: Array[StringName] = []
	for opportunity: Resource in pending_opportunities:
		if opportunity.id != selected_id:
			declined.append(opportunity.id)
	return declined


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
