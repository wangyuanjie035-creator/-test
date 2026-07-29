extends SceneTree


func _initialize() -> void:
	var first: ResearchTopicCandidate = _candidate(&"first")
	var second: ResearchTopicCandidate = _candidate(&"second")
	var portfolio := ResearchPortfolioModel.new()
	if not portfolio.setup([first, second], 2):
		_fail("Could not create the portfolio.")
		return
	if not bool(portfolio.select_candidate(&"first").get("success", false)):
		_fail("Could not select the first topic.")
		return
	if not bool(portfolio.select_candidate(&"second").get("success", false)):
		_fail("Could not select the second topic.")
		return
	var deselection: Dictionary = portfolio.deselect_candidate(&"second")
	if not bool(deselection.get("success", false)):
		_fail("A selected topic could not be reconsidered.")
		return
	if portfolio.active_topics.size() != 1 or portfolio.candidates.size() != 1:
		_fail("Deselection did not restore the candidate to the choice pool.")
		return
	if portfolio.candidates[0].candidate_id != &"second":
		_fail("Deselection restored the wrong topic.")
		return
	if portfolio.get_free_slot_count() != 1:
		_fail("Deselection did not reopen the topic slot.")
		return
	print("PHASE_TWO_REVERSIBLE_SELECTION: PASS")
	quit(0)


func _candidate(id_value: StringName) -> ResearchTopicCandidate:
	var candidate := ResearchTopicCandidate.new()
	candidate.candidate_id = id_value
	return candidate


func _fail(message: String) -> void:
	push_error("PHASE_TWO_REVERSIBLE_SELECTION: %s" % message)
	quit(1)
