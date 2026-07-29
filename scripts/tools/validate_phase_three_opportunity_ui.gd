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
	entry.call("_show_opportunity", transition.get("opportunity", {}))
	if not entry.opportunity_panel.visible:
		_fail("The opportunity panel remained hidden.")
		return
	if entry.candidate_scroll.visible:
		_fail("Candidate selection remained visible behind the opportunity.")
		return
	if entry.opportunity_description.text.find("下一周期压力") < 0:
		_fail("The opportunity did not disclose its next-cycle pressure cost.")
		return

	entry.accept_opportunity_button.pressed.emit()
	await process_frame
	if session.phase != AcademicYearSession.Phase.RESEARCH_CYCLE:
		_fail("Accepting the opportunity did not open the next research cycle.")
		return
	if session.year_model.carried_pressure <= 0:
		_fail("The accepted opportunity did not affect next-cycle pressure.")
		return
	if entry.opportunity_panel.visible:
		_fail("The resolved opportunity remained on screen.")
		return
	print("PHASE_THREE_OPPORTUNITY_UI: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("PHASE_THREE_OPPORTUNITY_UI: %s" % message)
	quit(1)
