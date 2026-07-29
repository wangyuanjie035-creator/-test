extends SceneTree

const SESSION_SCRIPT := preload(
	"res://scripts/academic_year/run/academic_year_session.gd"
)
const EFFECT_ADAPTER := preload(
	"res://scripts/academic_year/model/academic_opportunity_effect_adapter.gd"
)
const TOPIC: DualTopicDefinition = preload(
	"res://data/dual_topic/topics/bold_topic_b.tres"
)


func _initialize() -> void:
	var accepting: Node = _session()
	var resting: Node = _session()
	if not _finish_first_cycle(accepting) or not _finish_first_cycle(resting):
		return

	var accepted_transition: Dictionary = accepting.continue_from_archive()
	var rested_transition: Dictionary = resting.continue_from_archive()
	var accepted_offers: Array = accepted_transition.get("opportunities", [])
	var rested_offers: Array = rested_transition.get("opportunities", [])
	if accepted_offers != rested_offers or accepted_offers.size() != 2:
		_fail("Same seed and history did not expose the same first decision.")
		return

	var chosen_id: StringName = StringName(accepted_offers[0].get("id", &""))
	var accepted: Dictionary = accepting.resolve_opportunity_choice(chosen_id)
	var rested: Dictionary = resting.resolve_opportunity_choice(&"")
	if not _expect_success(accepted, "Could not accept the first opportunity."):
		return
	if not _expect_success(rested, "Could not rest at the first transition."):
		return

	var accepted_context: Dictionary = accepted.get("context", {})
	var rested_context: Dictionary = rested.get("context", {})
	if (
		int(accepted_context.get("starting_pressure", 0))
		<= int(rested_context.get("starting_pressure", 0))
	):
		_fail("Accepting an opportunity did not reduce next-cycle tolerance.")
		return
	var accepted_opening: Dictionary = EFFECT_ADAPTER.to_opening_modifier(
		Dictionary(accepted_context.get("opportunity_decision", {}))
	)
	var rested_opening: Dictionary = EFFECT_ADAPTER.to_opening_modifier(
		Dictionary(rested_context.get("opportunity_decision", {}))
	)
	if accepted_opening.is_empty() or not rested_opening.is_empty():
		_fail("Accepting and resting did not create distinct playable openings.")
		return
	if not _opening_changes_research_state(accepted_opening):
		return

	if not _finish_second_cycle(accepting) or not _finish_second_cycle(resting):
		return
	var second_accepted_transition: Dictionary = accepting.continue_from_archive()
	var second_rested_transition: Dictionary = resting.continue_from_archive()
	if not bool(second_accepted_transition.get("opportunity_pending", false)):
		_fail("Accepted route lost the second opportunity decision.")
		return
	if not bool(second_rested_transition.get("opportunity_pending", false)):
		_fail("Rested route lost the second opportunity decision.")
		return
	var second_offers: Array = second_accepted_transition.get("opportunities", [])
	if second_offers.is_empty():
		_fail("The second transition exposed no opportunity.")
		return
	var second_choice: Dictionary = second_offers[0]
	if not bool(second_choice.get("affordable", false)):
		var alternatives: Array = second_offers.filter(
			func(offer: Dictionary) -> bool:
				return bool(offer.get("affordable", false))
		)
		if alternatives.is_empty():
			_fail("The accepted route had no legal second decision besides resting.")
			return
		second_choice = alternatives[0]
	var second_resolution: Dictionary = accepting.resolve_opportunity_choice(
		StringName(second_choice.get("id", &""))
	)
	if not _expect_success(second_resolution, "Could not accept a second opportunity."):
		return
	if not _expect_success(
		resting.resolve_opportunity_choice(&""),
		"Could not rest at the second transition."
	):
		return
	if accepting.opportunity_model.decision_history.size() != 2:
		_fail("The full-year route did not retain both opportunity decisions.")
		return
	if (
		StringName(
			accepting.opportunity_model.get_destination_profile().get("id", &"unformed")
		)
		== &"unformed"
	):
		_fail("Two accepted transitions left no visible opportunity trajectory.")
		return
	if (
		StringName(
			resting.opportunity_model.get_destination_profile().get("id", &"")
		)
		!= &"unformed"
	):
		_fail("Resting accidentally created a destination trajectory.")
		return

	print("PHASE_THREE_YEAR_CONTRAST: PASS")
	quit(0)


func _session() -> Node:
	var session: Node = SESSION_SCRIPT.new()
	root.add_child(session)
	session.start_academic_year(240731)
	return session


func _finish_first_cycle(session: Node) -> bool:
	if not _expect_success(session.begin_current_cycle(), "Could not begin cycle one."):
		return false
	return _expect_success(
		session.complete_current_cycle(_cycle_result(&"pass"), 2),
		"Could not archive cycle one."
	)


func _finish_second_cycle(session: Node) -> bool:
	if not _expect_success(session.begin_current_cycle(), "Could not begin cycle two."):
		return false
	var pressure: int = int(
		Dictionary(session.get_current_cycle_context()).get("starting_pressure", 0)
	)
	return _expect_success(
		session.complete_current_cycle(_cycle_result(&"failed"), pressure),
		"Could not archive cycle two."
	)


func _opening_changes_research_state(modifier: Dictionary) -> bool:
	var model := DualTopicRunModel.new()
	var definitions: Array[DualTopicDefinition] = [TOPIC]
	if not model.setup(240731, definitions):
		_fail("Could not configure the research model.")
		return false
	var topic: DualTopicState = model.topics[0]
	var before: Dictionary = {
		"actions": model.action_points,
		"evidence": topic.evidence,
		"completion": topic.completion,
		"revealed_risk_index": topic.get_first_revealed_risk_index(),
	}
	var applied: Dictionary = model.apply_opening_modifier(modifier)
	if not bool(applied.get("success", false)):
		_fail("The accepted opportunity could not affect the research model.")
		return false
	var after: Dictionary = {
		"actions": model.action_points,
		"evidence": topic.evidence,
		"completion": topic.completion,
		"revealed_risk_index": topic.get_first_revealed_risk_index(),
	}
	if before == after:
		_fail("The accepted opportunity changed text but not playable state.")
		return false
	return true


func _cycle_result(grade: StringName) -> Dictionary:
	return {
		"success": true,
		"grade": grade,
		"route_id": &"single",
		"legacy": {"type": &"risk_insight"},
	}


func _expect_success(result: Dictionary, message: String) -> bool:
	if bool(result.get("success", false)):
		return true
	_fail(message)
	return false


func _fail(message: String) -> void:
	push_error("PHASE_THREE_YEAR_CONTRAST: %s" % message)
	quit(1)
