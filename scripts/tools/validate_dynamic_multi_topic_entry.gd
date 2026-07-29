extends SceneTree

const ENTRY_SCENE: PackedScene = preload(
	"res://scenes/topic_pool/dynamic_topic_entry.tscn"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var entry: Control = ENTRY_SCENE.instantiate()
	entry.growth_rank = 1
	root.add_child(entry)
	await process_frame
	await process_frame
	var grid := entry.get_node(
		"Margin/Layout/ChoiceArea/CandidateScroll/CandidateGrid"
	) as GridContainer
	if entry.portfolio.slot_capacity != 2:
		_fail("Growth rank one did not unlock the second topic slot.")
		return
	(grid.get_child(0) as Button).pressed.emit()
	await process_frame
	# The selected topic remains visible at index 0 so the player can undo it.
	# Pick the next candidate rather than toggling the first selection off.
	(grid.get_child(1) as Button).pressed.emit()
	await process_frame
	if entry.portfolio.active_topics.size() != 2:
		_fail("The entry desk did not retain two selected topics.")
		return
	var expected_initial_evidence := (
		1 if entry.portfolio.active_topics[0].potential == 0 else 0
	)
	var expected_initial_completion := expected_initial_evidence
	var carryover_assets: Array[Dictionary] = [{
		"type": &"early_archive",
		"evidence": 2,
		"completion": 2,
		"method_ids": [],
		"risk_insights": ["known_pattern"],
	}]
	entry.pending_cycle_assets = carryover_assets
	entry.archive_button.pressed.emit()
	await process_frame
	await process_frame
	if entry.current_cycle == null:
		_fail("The selected portfolio did not open the research cycle.")
		return
	var session: DualTopicSession = entry.current_cycle.get_node("Session")
	if session.run_model.topics.size() != 2:
		_fail("Two candidates were not adapted into the cycle.")
		return
	if session.run_model.get_portfolio_relation() == &"single":
		_fail("The cycle did not classify the two-topic relation.")
		return
	if (
		session.run_model.topics[0].evidence != expected_initial_evidence + 1
		or session.run_model.topics[0].completion != expected_initial_completion + 1
	):
		_fail("Entry desk did not redeem the previous cycle asset.")
		return
	if not entry.pending_cycle_assets.is_empty():
		_fail("Redeemed cycle assets remained available for duplication.")
		return
	print("DYNAMIC_MULTI_TOPIC_ENTRY: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
