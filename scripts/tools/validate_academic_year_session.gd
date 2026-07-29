extends SceneTree

const SESSION_SCRIPT := preload("res://scripts/academic_year/run/academic_year_session.gd")


func _initialize() -> void:
	var session: Node = SESSION_SCRIPT.new()
	root.add_child(session)
	session.start_academic_year(240731)
	if session.phase != SESSION_SCRIPT.Phase.ARCHIVE_DESK:
		_fail("Academic year did not open at the archive desk.")
		return
	var first: Dictionary = session.begin_current_cycle()
	if not bool(first.get("success", false)):
		_fail("First research cycle could not begin.")
		return
	var first_context: Dictionary = first.get("context", {})
	if first_context.get("window_id", &"") != &"spring_workshop":
		_fail("First research cycle received the wrong window.")
		return
	if not bool(
		session.complete_current_cycle(_result(&"pass", &"mature_method"), 3).get(
			"success",
			false
		)
	):
		_fail("First research cycle could not be archived.")
		return
	var second_transition: Dictionary = session.continue_from_archive()
	if bool(second_transition.get("year_finished", true)):
		_fail("Academic year ended after only one cycle.")
		return
	if session.get_current_cycle_context().get("window_id", &"") != &"summer_conference":
		_fail("Archive desk did not advance to the summer conference.")
		return

	for grade: StringName in [&"failed", &"excellent"]:
		session.begin_current_cycle()
		session.complete_current_cycle(_result(grade, &"risk_insight"), 2)
		session.continue_from_archive()
	if session.phase != SESSION_SCRIPT.Phase.YEAR_RESULT:
		_fail("Academic year did not reach its final result phase.")
		return
	var ending: Dictionary = session.year_model.get_year_ending()
	if not bool(ending.get("ready", false)):
		_fail("Academic year ending is not ready.")
		return
	if session.get_current_cycle_context() != {}:
		_fail("Finished year still exposes an active cycle.")
		return
	print("ACADEMIC_YEAR_SESSION: PASS")
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
