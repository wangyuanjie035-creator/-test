extends Node
class_name AcademicYearSession

signal state_changed
signal cycle_requested(cycle_context: Dictionary)
signal archive_ready(cycle_record: Dictionary)
signal year_finished(ending: Dictionary)

const SPRING_WINDOW: ResearchWindowDefinition = preload(
	"res://data/academic_year/windows/spring_workshop.tres"
)
const SUMMER_WINDOW: ResearchWindowDefinition = preload(
	"res://data/academic_year/windows/summer_conference.tres"
)
const AUTUMN_WINDOW: ResearchWindowDefinition = preload(
	"res://data/academic_year/windows/autumn_journal.tres"
)
const OPPORTUNITY_MODEL := preload(
	"res://scripts/academic_year/model/academic_opportunity_model.gd"
)
const LAB_COLLABORATION: Resource = preload(
	"res://data/academic_year/opportunities/lab_collaboration.tres"
)
const INDUSTRY_INTERVIEW: Resource = preload(
	"res://data/academic_year/opportunities/industry_interview.tres"
)
const STARTUP_PILOT: Resource = preload(
	"res://data/academic_year/opportunities/startup_pilot.tres"
)

enum Phase {
	ARCHIVE_DESK,
	RESEARCH_CYCLE,
	CYCLE_RESULT,
	OPPORTUNITY,
	YEAR_RESULT,
}

var year_model: AcademicYearModel
var opportunity_model: RefCounted
var phase: Phase = Phase.ARCHIVE_DESK
var last_opportunity_decision: Dictionary = {}


func start_academic_year(run_seed: int = 240731) -> void:
	year_model = AcademicYearModel.new()
	var definitions: Array[ResearchWindowDefinition] = [
		SPRING_WINDOW,
		SUMMER_WINDOW,
		AUTUMN_WINDOW,
	]
	if not year_model.setup(run_seed, definitions):
		push_error("AcademicYearSession could not start the academic year.")
		return
	opportunity_model = OPPORTUNITY_MODEL.new()
	var opportunities: Array[Resource] = [
		LAB_COLLABORATION,
		INDUSTRY_INTERVIEW,
		STARTUP_PILOT,
	]
	if not opportunity_model.setup(run_seed, opportunities):
		push_error("AcademicYearSession could not configure academic opportunities.")
		return
	last_opportunity_decision.clear()
	phase = Phase.ARCHIVE_DESK
	state_changed.emit()


func begin_current_cycle() -> Dictionary:
	if year_model == null:
		return {"success": false, "reason": &"year_not_started"}
	if phase != Phase.ARCHIVE_DESK:
		return {"success": false, "reason": &"wrong_phase"}
	var context := get_current_cycle_context()
	phase = Phase.RESEARCH_CYCLE
	cycle_requested.emit(context.duplicate(true))
	state_changed.emit()
	return {"success": true, "context": context}


func complete_current_cycle(result: Dictionary, final_pressure: int) -> Dictionary:
	if year_model == null:
		return {"success": false, "reason": &"year_not_started"}
	if phase != Phase.RESEARCH_CYCLE:
		return {"success": false, "reason": &"wrong_phase"}
	var recorded := year_model.record_cycle_result(result, final_pressure)
	if not bool(recorded.get("success", false)):
		return recorded
	phase = Phase.CYCLE_RESULT
	var record: Dictionary = recorded.get("record", {})
	archive_ready.emit(record.duplicate(true))
	state_changed.emit()
	return {"success": true, "record": record}


func continue_from_archive() -> Dictionary:
	if year_model == null:
		return {"success": false, "reason": &"year_not_started"}
	if phase != Phase.CYCLE_RESULT:
		return {"success": false, "reason": &"wrong_phase"}
	var advanced := year_model.advance_cycle()
	if not bool(advanced.get("success", false)):
		return advanced
	if year_model.is_finished():
		phase = Phase.YEAR_RESULT
		var ending := get_year_ending()
		year_finished.emit(ending.duplicate(true))
		state_changed.emit()
		return {"success": true, "year_finished": true, "ending": ending}
	var offer_result: Dictionary = opportunity_model.generate_offers(
		year_model.cycle_index,
		_get_opportunity_context()
	)
	if not bool(offer_result.get("success", false)):
		return offer_result
	phase = Phase.OPPORTUNITY
	state_changed.emit()
	return {
		"success": true,
		"year_finished": false,
		"opportunity_pending": true,
		"opportunity": opportunity_model.get_pending_offer(),
		"opportunities": opportunity_model.get_pending_offers(),
	}


func resolve_opportunity(accepted: bool) -> Dictionary:
	var selected_id: StringName = &""
	if accepted:
		var offers: Array[Dictionary] = opportunity_model.get_pending_offers()
		if not offers.is_empty():
			selected_id = StringName(offers[0].get("id", &""))
	return resolve_opportunity_choice(selected_id)


func resolve_opportunity_choice(selected_id: StringName) -> Dictionary:
	if year_model == null:
		return {"success": false, "reason": &"year_not_started"}
	if phase != Phase.OPPORTUNITY:
		return {"success": false, "reason": &"wrong_phase"}
	var resolution: Dictionary = opportunity_model.resolve_offer_choice(selected_id)
	if not bool(resolution.get("success", false)):
		return resolution
	var decision: Dictionary = resolution.get("record", {}).duplicate(true)
	if bool(decision.get("accepted", false)):
		year_model.add_transition_pressure(int(decision.get("pressure_cost", 0)))
	last_opportunity_decision = decision
	phase = Phase.ARCHIVE_DESK
	var context: Dictionary = get_current_cycle_context()
	state_changed.emit()
	return {
		"success": true,
		"decision": decision.duplicate(true),
		"context": context,
	}


func get_year_ending() -> Dictionary:
	if year_model == null:
		return {"ready": false, "reason": &"year_not_started"}
	var ending: Dictionary = year_model.get_year_ending()
	if bool(ending.get("ready", false)) and opportunity_model != null:
		ending["opportunity_history"] = opportunity_model.decision_history.duplicate(true)
	return ending


func get_current_cycle_context() -> Dictionary:
	if year_model == null or year_model.is_finished():
		return {}
	var window := year_model.get_current_window()
	return {
		"cycle": year_model.cycle_index + 1,
		"cycle_count": AcademicYearModel.MAX_CYCLES,
		"seed": year_model.seed + year_model.cycle_index * 104729,
		"window_id": window.id,
		"window_name": window.display_name,
		"window_description": window.description,
		"minimum_evidence": window.minimum_evidence,
		"minimum_completion": window.minimum_completion,
		"starting_pressure": year_model.get_cycle_start_pressure(),
		"growth_rank": year_model.get_growth_rank(),
		"topic_slot_capacity": year_model.get_topic_slot_capacity(),
		"legacy": year_model.active_legacy.duplicate(true),
		"accepted_papers": year_model.accepted_papers,
		"prestige": year_model.total_prestige,
		"opportunity_decision": last_opportunity_decision.duplicate(true),
	}


func _get_opportunity_context() -> Dictionary:
	var dominant_route: StringName = &"single"
	var highest_count: int = -1
	for route_id: StringName in [&"single", &"synergy", &"conflict"]:
		var count: int = year_model.route_counts.get(route_id, 0)
		if count > highest_count:
			highest_count = count
			dominant_route = route_id
	return {
		"prestige": year_model.total_prestige,
		"failure_assets": year_model.failed_submissions + year_model.withdrawals,
		"route_id": dominant_route,
	}
