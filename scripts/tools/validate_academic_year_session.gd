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
	if not bool(second_transition.get("opportunity_pending", false)):
		_fail("The first cycle transition did not offer an academic opportunity.")
		return
	if session.phase != SESSION_SCRIPT.Phase.OPPORTUNITY:
		_fail("The session did not wait for the opportunity decision.")
		return
	if bool(session.begin_current_cycle().get("success", true)):
		_fail("A new cycle started before the opportunity was resolved.")
		return
	var accepted: Dictionary = session.resolve_opportunity(true)
	if not bool(accepted.get("success", false)):
		_fail("The offered academic opportunity could not be accepted.")
		return
	var accepted_decision: Dictionary = accepted.get("decision", {})
	if int(accepted_decision.get("pressure_cost", 0)) <= 0:
		_fail("Accepting the opportunity did not expose its pressure cost.")
		return
	if session.get_current_cycle_context().get("window_id", &"") != &"summer_conference":
		_fail("Archive desk did not advance to the summer conference.")
		return

	for grade: StringName in [&"failed", &"excellent"]:
		session.begin_current_cycle()
		session.complete_current_cycle(_result(grade, &"risk_insight"), 2)
		var transition: Dictionary = session.continue_from_archive()
		if not bool(transition.get("year_finished", false)):
			var rejected: Dictionary = session.resolve_opportunity(false)
			if not bool(rejected.get("success", false)):
				_fail("The offered academic opportunity could not be rejected.")
				return
			if int(rejected.get("decision", {}).get("pressure_cost", -1)) != 0:
				_fail("Rejecting an opportunity charged pressure.")
				return
	if session.phase != SESSION_SCRIPT.Phase.YEAR_RESULT:
		_fail("Academic year did not reach its final result phase.")
		return
	var ending: Dictionary = session.get_year_ending()
	if not bool(ending.get("ready", false)):
		_fail("Academic year ending is not ready.")
		return
	if session.get_current_cycle_context() != {}:
		_fail("Finished year still exposes an active cycle.")
		return
	if Array(ending.get("opportunity_history", [])).size() != 2:
		_fail("The year ending did not retain both transition decisions.")
		return
	var destination_profile: Dictionary = ending.get("destination_profile", {})
	if StringName(destination_profile.get("id", &"unformed")) == &"unformed":
		_fail("The year ending did not summarize accepted opportunity signals.")
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
