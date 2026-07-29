extends SceneTree

const PROTOTYPE := preload("res://scenes/dual_topic/dual_topic_prototype.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Control = PROTOTYPE.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var session: Node = scene.get_node("Session")
	_expect(session.run_model.week == 1, "UI did not start at week one.")
	_expect(session.method_deck.hand.size() == 5, "Opening hand should contain five cards.")
	_expect(scene.get_node("%HandContainer").get_child_count() == 5, "Hand buttons were not built.")
	_expect(scene.get_node("%PhaseTitle").text == "本周研究安排", "Opening phase is wrong.")
	_expect(scene.size.x >= 1279.0 and scene.size.y >= 719.0, "Root UI does not fill 1280x720.")

	session.advance_week()
	await process_frame
	_expect(session.pending_build_offer.size() == 3, "Week two build offer is missing.")
	_expect(
		scene.get_node("%PhaseTitle").text.contains("方法构筑"),
		"Build-offer panel did not appear."
	)
	session.choose_build_card(0)
	await process_frame
	_expect(session.method_deck.hand.size() == 5, "Hand was not redrawn after building.")

	session.advance_week()
	await process_frame
	_expect(session.midterm_pending, "Week three midterm is missing.")
	_expect(
		scene.get_node("%PhaseTitle").text.contains("不可逆判断"),
		"Midterm panel did not appear."
	)
	session.resolve_midterm(
		DualTopicState.Commitment.MAINTAIN,
		DualTopicState.Commitment.MAINTAIN
	)
	await process_frame
	_expect(not session.midterm_pending, "Midterm did not resolve.")

	session.advance_week()
	await process_frame
	_expect(session.pending_build_offer.size() == 3, "Week four build offer is missing.")
	session.choose_build_card(0)
	session.advance_week()
	session.advance_week()
	await process_frame
	_expect(session.run_model.week == 6, "UI flow did not reach week six.")
	_expect(
		scene.get_node("%PhaseTitle").text.contains("投稿窗口"),
		"Submission panel did not appear."
	)
	session.finish_run(&"withdraw", 1)
	await process_frame
	_expect(session.run_model.final_resolved, "Final UI action did not resolve the run.")
	_expect(scene.get_node("%PhaseTitle").text == "主动撤出", "Final result was not rendered.")
	var route_summary: String = session.get_route_summary()
	_expect(route_summary.contains("A/B"), "Route summary is missing topic investment data.")
	_expect(
		scene.get_node("%PhaseBody").text.contains(route_summary),
		"Final panel did not render the route summary."
	)
	_expect(
		not session.get_replay_challenge(session.run_model.final_resolution).is_empty(),
		"Final result did not generate a replay challenge."
	)

	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("DUAL_TOPIC_UI: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("DUAL_TOPIC_UI: FAIL (%d)" % failures.size())
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
