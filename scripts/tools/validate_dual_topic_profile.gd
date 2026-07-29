extends SceneTree


func _initialize() -> void:
	var before := DualTopicProfile.new()
	before.load_profile()
	var previous_count: int = int(before.legacy_counts["risk_insight"])
	var result := {
		"grade": &"withdrawn",
		"legacy": {
			"type": &"risk_insight",
			"risk_id": &"test_risk",
		},
	}
	var save_error := before.record_result(result, "测试课题")
	if save_error != OK:
		push_error("Profile save returned error %s." % save_error)
		quit(1)
		return

	var after := DualTopicProfile.new()
	after.load_profile()
	if int(after.legacy_counts["risk_insight"]) != previous_count + 1:
		push_error("Profile legacy count did not survive reload.")
		quit(1)
		return
	if after.recent_results.is_empty():
		push_error("Profile result history did not survive reload.")
		quit(1)
		return
	if int(after.recent_results.size()) > DualTopicProfile.MAX_HISTORY:
		push_error("Profile history exceeded its bounded size.")
		quit(1)
		return
	var session := DualTopicSession.new()
	root.add_child(session)
	session.start_new_run(240731)
	var identified_risks: int = 0
	for topic: DualTopicState in session.run_model.topics:
		for risk: DualTopicRiskState in topic.risks:
			if risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN:
				identified_risks += 1
	if identified_risks < 1 or not session.active_legacy_text.contains("风险认知"):
		push_error("Saved risk insight was not redeemed in the next run.")
		quit(1)
		return

	var mature_session := DualTopicSession.new()
	mature_session.profile = DualTopicProfile.new()
	mature_session.profile.last_legacy = {
		"type": "mature_method",
		"method_id": "targeted_reading",
	}
	root.add_child(mature_session)
	mature_session.start_new_run(240731)
	if mature_session.method_deck.deck_cards.size() != 16:
		push_error("Mature method was not added to the next run deck.")
		quit(1)
		return

	var baseline_session := DualTopicSession.new()
	baseline_session.profile = DualTopicProfile.new()
	root.add_child(baseline_session)
	baseline_session.start_new_run(240731)
	var baseline_evidence: int = baseline_session.run_model.topics[0].evidence
	var repair_session := DualTopicSession.new()
	repair_session.profile = DualTopicProfile.new()
	repair_session.profile.last_legacy = {
		"type": "remediation_method",
		"method_id": "evidence_repair",
	}
	root.add_child(repair_session)
	repair_session.start_new_run(240731)
	if repair_session.run_model.topics[0].evidence != baseline_evidence + 1:
		push_error("Remediation method did not correct the next run opening.")
		quit(1)
		return
	print("DUAL_TOPIC_PROFILE: PASS")
	quit(0)
