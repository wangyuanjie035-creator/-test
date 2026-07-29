extends SceneTree

const WINDOWS: Array[ResearchWindowDefinition] = [
	preload("res://data/academic_year/windows/spring_workshop.tres"),
	preload("res://data/academic_year/windows/summer_conference.tres"),
	preload("res://data/academic_year/windows/autumn_journal.tres"),
]


func _initialize() -> void:
	var model := AcademicYearModel.new()
	if not model.setup(240731, WINDOWS):
		_fail("Model setup failed.")
		return
	if model.get_current_window().id != &"spring_workshop":
		_fail("Academic year did not begin at the spring window.")
		return
	if model.get_cycle_start_pressure() != 0:
		_fail("Opening pressure should start at zero.")
		return

	var pass_result := _result(&"pass", &"mature_method")
	if not bool(model.record_cycle_result(pass_result, 3).get("success", false)):
		_fail("Pass result was not recorded.")
		return
	if bool(model.record_cycle_result(pass_result, 3).get("success", true)):
		_fail("The same cycle accepted two results.")
		return
	if not bool(model.advance_cycle().get("success", false)):
		_fail("Could not advance to the second cycle.")
		return
	if model.get_current_window().id != &"summer_conference":
		_fail("Second cycle window is incorrect.")
		return
	if model.get_cycle_start_pressure() != 3:
		_fail("Carried pressure and window pressure were not combined.")
		return

	model.record_cycle_result(_result(&"failed", &"remediation_method"), 4)
	model.advance_cycle()
	if model.get_cycle_start_pressure() != 5:
		_fail("Failure pressure should be bounded at five.")
		return
	model.record_cycle_result(_result(&"excellent", &"mature_method"), 3)
	model.advance_cycle()
	if not model.is_finished():
		_fail("Academic year did not finish after three cycles.")
		return
	var ending := model.get_year_ending()
	if ending.get("id", &"") != &"breakthrough_year":
		_fail("Mixed pass/fail/excellent route should reach breakthrough ending.")
		return
	if model.accepted_papers != 2 or model.excellent_papers != 1:
		_fail("Publication totals are incorrect.")
		return
	if model.total_prestige != 5:
		_fail("Prestige total is incorrect.")
		return

	var empty_year := AcademicYearModel.new()
	empty_year.setup(7, WINDOWS)
	for cycle in range(AcademicYearModel.MAX_CYCLES):
		empty_year.record_cycle_result(_result(&"withdrawn", &"risk_insight"), 2)
		empty_year.advance_cycle()
	if empty_year.get_year_ending().get("id", &"") != &"unfinished_foundation":
		_fail("Zero-output route should preserve a distinct ending.")
		return
	print("ACADEMIC_YEAR_MODEL: PASS")
	quit(0)


func _result(grade: StringName, legacy_type: StringName) -> Dictionary:
	return {
		"success": true,
		"grade": grade,
		"legacy": {"type": legacy_type},
	}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
