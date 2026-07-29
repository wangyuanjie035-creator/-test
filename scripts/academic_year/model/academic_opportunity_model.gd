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


func get_destination_profile() -> Dictionary:
	var counts: Dictionary[StringName, int] = {
		&"network": 0,
		&"stable_employment": 0,
		&"independent": 0,
	}
	for decision: Dictionary in decision_history:
		var signal_id: StringName = StringName(
			decision.get("destination_signal", &"")
		)
		if signal_id in counts:
			counts[signal_id] = counts.get(signal_id, 0) + 1
	var accepted_count: int = (
		counts[&"network"]
		+ counts[&"stable_employment"]
		+ counts[&"independent"]
	)
	if accepted_count == 0:
		return {
			"id": &"unformed",
			"title": "尚未形成机会轨迹",
			"summary": "你优先保留了研究节奏，尚未向外部机会投入时间。",
			"counts": counts,
		}
	var highest: int = maxi(
		counts[&"network"],
		maxi(counts[&"stable_employment"], counts[&"independent"])
	)
	var leaders: Array[StringName] = []
	for signal_id: StringName in [&"network", &"stable_employment", &"independent"]:
		if counts[signal_id] == highest:
			leaders.append(signal_id)
	if leaders.size() > 1:
		return {
			"id": &"mixed",
			"title": "多线机会探索者",
			"summary": "你同时试探了多种外部路径，还没有把未来锁定在单一出口。",
			"counts": counts,
		}
	return _profile_for_signal(leaders[0], counts)


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


func _profile_for_signal(
	signal_id: StringName,
	counts: Dictionary[StringName, int]
) -> Dictionary:
	match signal_id:
		&"network":
			return {
				"id": &"network_builder",
				"title": "跨界协作者",
				"summary": "你把合作关系变成了未来可继续调用的研究网络。",
				"counts": counts,
			}
		&"stable_employment":
			return {
				"id": &"industry_connector",
				"title": "产业连接者",
				"summary": "你开始让研究成果与稳定就业窗口产生联系。",
				"counts": counts,
			}
		&"independent":
			return {
				"id": &"independent_translator",
				"title": "独立转化者",
				"summary": "你尝试把失败资产转成不依赖论文接收的自主路径。",
				"counts": counts,
			}
		_:
			return {
				"id": &"unformed",
				"title": "尚未形成机会轨迹",
				"summary": "这学年的外部选择还没有形成清晰方向。",
				"counts": counts,
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
