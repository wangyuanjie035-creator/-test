extends SceneTree

const ENTRY_SCENE: PackedScene = preload(
	"res://scenes/topic_pool/dynamic_topic_entry.tscn"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var entry: Control = ENTRY_SCENE.instantiate()
	entry.growth_rank = 0
	root.add_child(entry)
	await process_frame
	await process_frame
	var candidate_grid := entry.get_node(
		"Margin/Layout/ChoiceArea/CandidateScroll/CandidateGrid"
	) as GridContainer
	if candidate_grid.get_child_count() < 3 or candidate_grid.get_child_count() > 5:
		_fail("Candidate desk did not render three to five choices.")
		return
	var first_card := candidate_grid.get_child(0) as Button
	first_card.pressed.emit()
	await process_frame
	entry.archive_button.pressed.emit()
	await process_frame
	if entry.current_cycle == null:
		_fail("Selecting a candidate did not open the research cycle.")
		return
	var session: Node = entry.current_cycle.get_node("Session")
	if session.run_model.topics.size() != 1:
		_fail("Dynamic entry did not start a single-topic cycle.")
		return
	if session.run_model.topics[0].definition.id != entry.current_candidate_id:
		_fail("Selected candidate was not adapted into the cycle.")
		return

	session.advance_week()
	if session.pending_build_offer.is_empty():
		_fail("Week two build offer did not occur.")
		return
	session.choose_build_card(0)
	session.advance_week()
	if not session.midterm_pending:
		_fail("Single-topic cycle did not reach its midterm.")
		return
	session.resolve_single_topic_midterm(DualTopicState.Commitment.MAINTAIN)
	if session.midterm_pending or not session.run_model.midterm_resolved:
		_fail("Single-topic midterm commitment did not resolve.")
		return
	session.advance_week()
	session.choose_build_card(0)
	session.advance_week()
	session.advance_week()
	if session.run_model.week != DualTopicRunModel.MAX_WEEKS:
		_fail("Single-topic cycle did not reach the submission week.")
		return
	session.finish_run(&"withdraw", 0)
	await process_frame
	if entry.portfolio.archive.size() != 1:
		_fail("Cycle result was not written back to the research archive.")
		return
	if not entry.archive_button.visible:
		_fail("Finished cycle did not offer a return to the archive desk.")
		return
	print("DYNAMIC_TOPIC_ENTRY: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
