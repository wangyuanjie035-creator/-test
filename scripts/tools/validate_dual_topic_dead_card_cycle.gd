extends SceneTree

const SESSION_SCRIPT := preload(
	"res://scripts/dual_topic/run/dual_topic_session.gd"
)


func _initialize() -> void:
	var session: DualTopicSession = SESSION_SCRIPT.new()
	root.add_child(session)
	session.start_new_run(240731)
	var blocked_index: int = -1
	for index: int in range(session.method_deck.hand.size()):
		var card: DualTopicMethodCardDefinition = session.method_deck.hand[index]
		if card.action_type == DualTopicRunModel.ActionType.EXPERIMENT:
			for risk: DualTopicRiskState in session.run_model.topics[0].risks:
				risk.identify()
				risk.verify()
			blocked_index = index
			break
	if blocked_index < 0:
		_fail("The fixed seed did not expose a card for the dead-card test.")
		return
	if session.get_hand_card_block_reason(blocked_index) == &"":
		_fail("A card with no remaining valid risk target was shown as playable.")
		return
	var removed_id: StringName = session.method_deck.hand[blocked_index].id
	session.cycle_blocked_hand_card(blocked_index)
	if session.method_deck.hand[blocked_index].id == removed_id:
		_fail("Cycling a blocked card did not draw a replacement.")
		return
	if not session.cycled_hand_weeks.has(session.run_model.week):
		_fail("The weekly cycle limit was not recorded.")
		return
	var first_replacement_id: StringName = session.method_deck.hand[blocked_index].id
	session.cycle_blocked_hand_card(blocked_index)
	if session.method_deck.hand[blocked_index].id != first_replacement_id:
		_fail("A second dead-card cycle was allowed in the same week.")
		return
	print("DUAL_TOPIC_DEAD_CARD_CYCLE: PASS")
	quit(0)


func _fail(message: String) -> void:
	push_error("DUAL_TOPIC_DEAD_CARD_CYCLE: %s" % message)
	quit(1)
