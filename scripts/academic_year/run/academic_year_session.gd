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

enum Phase {
	ARCHIVE_DESK,
	RESEARCH_CYCLE,
	CYCLE_RESULT,
	YEAR_RESULT,
}

var year_model: AcademicYearModel
var phase: Phase = Phase.ARCHIVE_DESK


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
		var ending := year_model.get_year_ending()
		year_finished.emit(ending.duplicate(true))
		state_changed.emit()
		return {"success": true, "year_finished": true, "ending": ending}
	phase = Phase.ARCHIVE_DESK
	state_changed.emit()
	return {
		"success": true,
		"year_finished": false,
		"context": get_current_cycle_context(),
	}


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
	}
