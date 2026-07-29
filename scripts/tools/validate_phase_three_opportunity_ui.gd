extends SceneTree

const ENTRY_SCENE: PackedScene = preload(
	"res://scenes/topic_pool/dynamic_topic_entry.tscn"
)


func _initialize() -> void:
	var entry: Control = ENTRY_SCENE.instantiate()
	root.add_child(entry)
	await process_frame

	var session: AcademicYearSession = entry.year_session
	var recorded: Dictionary = session.complete_current_cycle(
		{
			"success": true,
			"grade": &"pass",
			"route_id": &"single",
			"legacy": {"type": &"mature_method"},
		},
		2
	)
	if not bool(recorded.get("success", false)):
		_fail("Could not prepare a completed research cycle.")
		return
	var transition: Dictionary = session.continue_from_archive()
	if not bool(transition.get("opportunity_pending", false)):
		_fail("The completed cycle did not open an opportunity.")
		return
	var opportunities: Array[Dictionary] = []
	opportunities.assign(transition.get("opportunities", []))
	if opportunities.size() != 2:
		_fail("The transition did not expose two competing opportunities.")
		return
	entry.call("_show_opportunities", opportunities)
	if not entry.opportunity_panel.visible:
		_fail("The opportunity panel remained hidden.")
		return
	if entry.candidate_scroll.visible:
		_fail("Candidate selection remained visible behind the opportunity.")
		return
	if not entry.opportunity_choice_buttons[0].text.contains("代价：下一周期压力"):
		_fail("The opportunity card did not disclose its pressure cost.")
		return
	if not entry.opportunity_choice_buttons[1].visible:
		_fail("The second competing opportunity was not visible.")
		return
	if entry.opportunity_choice_buttons[1].disabled:
		_fail("An affordable opportunity was incorrectly disabled.")
		return

	var selected_id: StringName = StringName(opportunities[1].get("id", &""))
	entry.opportunity_choice_buttons[1].pressed.emit()
	await process_frame
	if session.phase != AcademicYearSession.Phase.RESEARCH_CYCLE:
		_fail("Accepting the opportunity did not open the next research cycle.")
		return
	if session.year_model.carried_pressure <= 0:
		_fail("The accepted opportunity did not affect next-cycle pressure.")
		return
	if not entry.year_summary_label.text.contains("机会轨迹"):
		_fail("The archive desk did not expose the accumulated opportunity path.")
		return
	if entry.opportunity_panel.visible:
		_fail("The resolved opportunity remained on screen.")
		return
	var decision_history: Array[Dictionary] = session.opportunity_model.decision_history
	if StringName(decision_history[0].get("opportunity_id", &"")) != selected_id:
		_fail("The UI resolved a different opportunity than the player selected.")
		return
	if Array(decision_history[0].get("declined_opportunity_ids", [])).size() != 1:
		_fail("The unselected competing opportunity remained open.")
		return
	var candidate: ResearchTopicCandidate = entry.portfolio.candidates[0]
	entry.call("_select_candidate", candidate.candidate_id)
	entry.call("_begin_selected_cycle")
	await process_frame
	var cycle_session: DualTopicSession = entry.current_cycle.get_node("Session")
	if cycle_session.run_model.opening_modifier_history.size() != 1:
		_fail("The accepted opportunity was not redeemed in the research cycle.")
		return
	print("PHASE_THREE_OPPORTUNITY_UI: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("PHASE_THREE_OPPORTUNITY_UI: %s" % message)
	quit(1)
