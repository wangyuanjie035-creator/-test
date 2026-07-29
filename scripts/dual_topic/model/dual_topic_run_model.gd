extends RefCounted
class_name DualTopicRunModel

const MAX_WEEKS := 6
const ACTION_POINTS_PER_WEEK := 4
const MAX_ENERGY := 8
const METHOD_MASTERY_THRESHOLD := 3
const PHASE_ONE_SUBMISSION_POLICY_SCRIPT := preload(
	"res://scripts/topic_pool/model/phase_one_submission_policy.gd"
)

enum ActionType {
	INVESTIGATE,
	EXPERIMENT,
	ORGANIZE,
	WRITE,
	RECOVER,
}

var seed: int = 1
var week: int = 1
var action_points: int = ACTION_POINTS_PER_WEEK
var energy: int = MAX_ENERGY
var pressure: int = 0
var submission_minimum_evidence: int = 3
var submission_minimum_completion: int = 4
var simplified_submission_enabled: bool = false
var topics: Array[DualTopicState] = []
var action_history: Array[Dictionary] = []
var week_history: Array[Dictionary] = []
var run_assets: Array[Dictionary] = []
var midterm_resolved: bool = false
var public_requirement: StringName = &""
var final_resolved: bool = false
var final_resolution: Dictionary = {}
var final_legacy: Dictionary = {}
var carryover_history: Array[Dictionary] = []
var carryover_applied: bool = false
var method_category_uses: Array[int] = [0, 0, 0, 0, 0]
var cooperation_result_count: int = 0
var cross_topic_synergy_count: int = 0
var converted_failure_asset_count: int = 0
var review_revision_used: bool = false
var transferred_venue: bool = false
var _double_down_triggered_topics: Dictionary[int, bool] = {}
var _special_rule_triggers: Dictionary[String, bool] = {}
var _synergy_triggered_weeks: Dictionary[int, bool] = {}
var frozen_topic_indices: Dictionary[int, bool] = {}
var portfolio_action_used: bool = false
var _rng := RandomNumberGenerator.new()
var _phase_one_submission_policy: RefCounted = (
	PHASE_ONE_SUBMISSION_POLICY_SCRIPT.new()
)


func setup(run_seed: int, topic_definitions: Array[DualTopicDefinition]) -> bool:
	if topic_definitions.is_empty() or topic_definitions.size() > 2:
		push_error("DualTopicRunModel requires one or two topic definitions.")
		return false
	seed = max(1, run_seed)
	_rng.seed = seed
	week = 1
	action_points = ACTION_POINTS_PER_WEEK
	energy = MAX_ENERGY
	pressure = 0
	submission_minimum_evidence = 3
	submission_minimum_completion = 4
	simplified_submission_enabled = false
	topics.clear()
	action_history.clear()
	week_history.clear()
	run_assets.clear()
	midterm_resolved = false
	public_requirement = &""
	final_resolved = false
	final_resolution.clear()
	final_legacy.clear()
	carryover_history.clear()
	carryover_applied = false
	method_category_uses = [0, 0, 0, 0, 0]
	cooperation_result_count = 0
	cross_topic_synergy_count = 0
	converted_failure_asset_count = 0
	review_revision_used = false
	transferred_venue = false
	_double_down_triggered_topics.clear()
	_special_rule_triggers.clear()
	_synergy_triggered_weeks.clear()
	frozen_topic_indices.clear()
	portfolio_action_used = false
	for definition: DualTopicDefinition in topic_definitions:
		if definition == null or not definition.is_valid_definition():
			push_error("DualTopicRunModel received an invalid topic definition.")
			topics.clear()
			return false
		topics.append(_create_topic_state(definition))
	public_requirement = _generate_public_requirement()
	return true


func configure_submission_window(
	minimum_evidence: int,
	minimum_completion: int
) -> void:
	if not action_history.is_empty() or week != 1:
		return
	submission_minimum_evidence = clampi(minimum_evidence, 1, 5)
	submission_minimum_completion = clampi(minimum_completion, 1, 5)


func enable_simplified_submission() -> void:
	if final_resolved:
		return
	simplified_submission_enabled = true


func perform_action(action_type: ActionType, topic_index: int = -1) -> Dictionary:
	if action_points <= 0:
		return _failed_action(&"no_action_points")
	if action_type == ActionType.RECOVER:
		return _perform_recover()
	if energy <= 0:
		return _failed_action(&"no_energy")
	if topic_index < 0 or topic_index >= topics.size():
		return _failed_action(&"invalid_target")
	var topic: DualTopicState = topics[topic_index]
	if topic.is_closed:
		return _failed_action(&"topic_closed")
	if frozen_topic_indices.get(topic_index, false):
		return _failed_action(&"topic_frozen")

	var result: Dictionary
	match action_type:
		ActionType.INVESTIGATE:
			result = _perform_investigate(topic)
		ActionType.EXPERIMENT:
			result = _perform_experiment(topic)
		ActionType.ORGANIZE:
			result = _perform_organize(topic)
		ActionType.WRITE:
			result = _perform_write(topic)
		_:
			return _failed_action(&"invalid_action")
	if not bool(result.get("success", false)):
		return result

	_apply_topic_special_rule(topic_index, topic, action_type, result)
	_apply_double_down_bonus(topic_index, topic, result)
	_apply_cross_topic_synergy(topic_index, result)
	result["week"] = week
	result["topic_index"] = topic_index
	result["action_type"] = int(action_type)
	result["action_points_left"] = action_points
	result["energy_left"] = energy
	result["pressure"] = pressure
	action_history.append(result.duplicate(true))
	return result


func apply_midterm_decisions(
	first_choice: DualTopicState.Commitment,
	second_choice: DualTopicState.Commitment
) -> Dictionary:
	return apply_midterm_commitments([first_choice, second_choice])


func apply_midterm_commitments(
	choices: Array[DualTopicState.Commitment]
) -> Dictionary:
	if week != 3:
		return {"success": false, "reason": &"not_midterm_week"}
	if midterm_resolved:
		return {"success": false, "reason": &"midterm_already_resolved"}
	if choices.size() != topics.size():
		return {"success": false, "reason": &"commitment_count_mismatch"}
	var kept_topic_count: int = 0
	for choice: DualTopicState.Commitment in choices:
		if choice != DualTopicState.Commitment.STOPPED:
			kept_topic_count += 1
	if kept_topic_count == 0:
		return {"success": false, "reason": &"must_keep_one_topic"}
	for topic_index: int in range(topics.size()):
		if not topics[topic_index].can_apply_commitment(choices[topic_index]):
			return {
				"success": false,
				"reason": &"invalid_commitment",
				"topic_index": topic_index,
			}
	var outcomes: Array[Dictionary] = []
	for topic_index: int in range(topics.size()):
		var topic: DualTopicState = topics[topic_index]
		var choice: DualTopicState.Commitment = choices[topic_index]
		var asset: Dictionary = {}
		if choice == DualTopicState.Commitment.STOPPED:
			asset = _create_stop_asset(topic_index, topic)
		topic.apply_commitment(choice)
		if (
			choice == DualTopicState.Commitment.PIVOT
			and topic.definition.special_rule == &"cross_domain"
		):
			var restored_completion: int = topic.add_completion(1, &"cross_domain")
			if restored_completion > 0:
				asset["special_effect"] = &"pivot_completion_preserved"
		if choice == DualTopicState.Commitment.PIVOT:
			var replacement: DualTopicRiskState = _create_pivot_risk(topic)
			topic.replace_revealed_risk(replacement)
		if not asset.is_empty():
			run_assets.append(asset)
		outcomes.append({
			"topic_index": topic_index,
			"topic_id": topic.definition.id,
			"choice": int(choice),
			"asset": asset,
		})
	midterm_resolved = true
	return {
		"success": true,
		"week": week,
		"outcomes": outcomes,
		"active_topic_count": _count_active_topics(),
	}


func perform_method_card(
	card: DualTopicMethodCardDefinition,
	topic_index: int = -1
) -> Dictionary:
	if card == null or not card.is_valid_definition():
		return _failed_action(&"invalid_card")
	var result: Dictionary = perform_action(card.action_type, topic_index)
	if not bool(result.get("success", false)):
		result["card_id"] = card.id
		return result
	var topic: DualTopicState = null
	if topic_index >= 0 and topic_index < topics.size():
		topic = topics[topic_index]
	_apply_method_effect(card.effect_id, topic, result)
	method_category_uses[card.category] += 1
	if card.category == DualTopicMethodCardDefinition.Category.COLLABORATION:
		cooperation_result_count += 1
	_apply_method_mastery(card.category, topic, result)
	result["card_id"] = card.id
	result["category"] = int(card.category)
	result["category_uses"] = method_category_uses[card.category]
	if not action_history.is_empty():
		action_history[action_history.size() - 1] = result.duplicate(true)
	return result


func can_perform_basic_action(
	action_type: ActionType,
	topic_index: int = -1
) -> bool:
	if action_points <= 0 or final_resolved:
		return false
	match action_type:
		ActionType.ORGANIZE:
			return (
				energy > 0
				and topic_index >= 0
				and topic_index < topics.size()
				and not topics[topic_index].is_closed
				and not frozen_topic_indices.get(topic_index, false)
			)
		ActionType.RECOVER:
			return energy < MAX_ENERGY or pressure > 0
		_:
			return false


func perform_basic_action(
	action_type: ActionType,
	topic_index: int = -1
) -> Dictionary:
	if not can_perform_basic_action(action_type, topic_index):
		return _failed_action(&"basic_action_unavailable")
	var result: Dictionary = perform_action(action_type, topic_index)
	if not bool(result.get("success", false)):
		return result
	result["basic_action"] = true
	if not action_history.is_empty():
		action_history[action_history.size() - 1] = result.duplicate(true)
	return result


func resolve_run(mode: StringName, topic_index: int = -1) -> Dictionary:
	if week != MAX_WEEKS:
		return {"success": false, "reason": &"not_final_week"}
	if not midterm_resolved:
		return {"success": false, "reason": &"midterm_not_resolved"}
	if final_resolved:
		return {"success": false, "reason": &"run_already_resolved"}
	if mode != &"submit" and mode != &"withdraw":
		return {"success": false, "reason": &"invalid_resolution_mode"}
	if topic_index < 0 or topic_index >= topics.size() or topics[topic_index].is_closed:
		return {"success": false, "reason": &"invalid_topic"}

	var topic: DualTopicState = topics[topic_index]
	var grade: StringName = &"withdrawn"
	var diagnosis: Dictionary = {}
	var review_comments: Array[Dictionary] = []
	if mode == &"submit":
		if simplified_submission_enabled:
			var evaluation: Dictionary = _evaluate_simplified_submission(topic)
			grade = StringName(evaluation.get("grade", &"failed"))
			diagnosis = Dictionary(evaluation.get("diagnosis", {}))
		else:
			grade = get_submission_result(topic_index)
			if grade != &"failed" and not _meets_public_requirement(topic):
				grade = &"failed"
			if transferred_venue and grade == &"excellent":
				grade = &"pass"
			if grade == &"failed":
				diagnosis = _diagnose_failure(topic)
				review_comments = _build_review_comments(topic_index, topic, diagnosis)
	final_legacy = _create_final_legacy(mode, grade, topic_index, topic, diagnosis)
	if mode == &"withdraw" or grade == &"failed":
		converted_failure_asset_count += 1
	final_resolution = {
		"success": true,
		"mode": mode,
		"grade": grade,
		"topic_index": topic_index,
		"topic_id": topic.definition.id,
		"public_requirement": public_requirement,
		"requirement_met": _meets_public_requirement(topic),
		"diagnosis": diagnosis,
		"review_comments": review_comments,
		"legacy": final_legacy,
		"run_assets": run_assets.duplicate(true),
		"reward_value": maxi(
			0,
			topic.definition.reward_value - (1 if transferred_venue else 0)
		),
		"submission_route": &"transferred" if transferred_venue else &"original",
		"special_rule": topic.definition.special_rule,
		"cooperation_trajectory": get_cooperation_trajectory(),
		"build_tendency": get_build_tendency_profile(),
		"submission_mode": (
			&"simplified" if simplified_submission_enabled else &"full_review"
		),
	}
	if mode == &"withdraw" and simplified_submission_enabled:
		final_resolution["withdrawal_terms"] = (
			_phase_one_submission_policy.withdrawal_terms(topic)
		)
	final_resolved = true
	return final_resolution.duplicate(true)


func apply_review_decision(
	decision: StringName,
	topic_index: int
) -> Dictionary:
	if week != MAX_WEEKS or final_resolved:
		return {"success": false, "reason": &"review_window_closed"}
	if topic_index < 0 or topic_index >= topics.size():
		return {"success": false, "reason": &"invalid_topic"}
	var topic: DualTopicState = topics[topic_index]
	if topic.is_closed:
		return {"success": false, "reason": &"topic_closed"}
	match decision:
		&"revise":
			if review_revision_used:
				return {"success": false, "reason": &"revision_already_used"}
			if action_points <= 0:
				return {"success": false, "reason": &"no_action_points"}
			if energy <= 0:
				return {"success": false, "reason": &"no_energy"}
			var diagnosis := _diagnose_failure(topic)
			if diagnosis.is_empty():
				return {"success": false, "reason": &"already_ready"}
			action_points -= 1
			spend_energy(1)
			pressure = mini(5, pressure + 1)
			review_revision_used = true
			var repair := _apply_targeted_revision(topic, diagnosis)
			var result := {
				"success": true,
				"decision": decision,
				"topic_index": topic_index,
				"week": week,
				"outcome": &"targeted_revision",
				"diagnosis": diagnosis,
				"repair": repair,
				"pressure_cost": 1,
				"action_points_left": action_points,
				"energy_left": energy,
			}
			action_history.append(result.duplicate(true))
			return result
		&"transfer":
			if transferred_venue:
				return {"success": false, "reason": &"venue_already_transferred"}
			transferred_venue = true
			submission_minimum_evidence = maxi(1, submission_minimum_evidence - 1)
			submission_minimum_completion = maxi(
				1,
				submission_minimum_completion - 1
			)
			public_requirement = &""
			pressure = mini(5, pressure + 1)
			return {
				"success": true,
				"decision": decision,
				"topic_index": topic_index,
				"week": week,
				"outcome": &"venue_transferred",
				"reward_penalty": 1,
				"pressure_cost": 1,
			}
		_:
			return {"success": false, "reason": &"invalid_review_decision"}


func _apply_targeted_revision(
	topic: DualTopicState,
	diagnosis: Dictionary
) -> Dictionary:
	var reason := StringName(diagnosis.get("reason", &""))
	match reason:
		&"completion_insufficient", &"reproducibility":
			return {
				"kind": &"completion",
				"amount": topic.add_completion(1, &"review_revision"),
			}
		&"evidence_insufficient", &"evidence_integrity":
			return {
				"kind": &"evidence",
				"amount": topic.add_evidence(1, &"review_revision"),
			}
		&"high_risk_unhandled", &"risk_control":
			for risk: DualTopicRiskState in topic.risks:
				if (
					risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN
					and not risk.is_controlled
				):
					risk.control()
					return {
						"kind": &"risk_control",
						"amount": 1,
						"risk_id": risk.definition.id,
					}
	return {
		"kind": &"completion",
		"amount": topic.add_completion(1, &"review_revision"),
	}


func apply_carryover_assets(
	assets: Array[Dictionary],
	target_index: int = 0
) -> Dictionary:
	if carryover_applied:
		return {"success": false, "reason": &"carryover_already_applied"}
	if week != 1 or not action_history.is_empty():
		return {"success": false, "reason": &"carryover_too_late"}
	if target_index < 0 or target_index >= topics.size():
		return {"success": false, "reason": &"invalid_target"}
	var target: DualTopicState = topics[target_index]
	var evidence_gain: int = 0
	var completion_gain: int = 0
	var risks_revealed: int = 0
	var applied_assets: int = 0
	carryover_applied = true
	for asset: Dictionary in assets:
		if applied_assets >= 2:
			break
		if asset.get("type", &"") != &"early_archive":
			continue
		applied_assets += 1
		var method_ids: Array = asset.get("method_ids", [])
		if not method_ids.is_empty() or int(asset.get("evidence", 0)) >= 2:
			evidence_gain += target.add_evidence(1, &"cycle_carryover")
		if int(asset.get("completion", 0)) >= 2:
			completion_gain += target.add_completion(1, &"cycle_carryover")
		var risk_insights: Array = asset.get("risk_insights", [])
		if not risk_insights.is_empty():
			var unknown: DualTopicRiskState = _find_risk(
				target,
				DualTopicRiskState.KnowledgeState.UNKNOWN
			)
			if unknown != null and unknown.identify():
				risks_revealed += 1
		carryover_history.append(asset.duplicate(true))
	return {
		"success": true,
		"applied_assets": applied_assets,
		"evidence_gain": evidence_gain,
		"completion_gain": completion_gain,
		"risks_revealed": risks_revealed,
		"target_index": target_index,
	}


func spend_action_points(cost: int) -> bool:
	if cost <= 0 or cost > action_points:
		return false
	action_points -= cost
	return true


func spend_energy(cost: int) -> int:
	if cost <= 0:
		return 0
	var spent := mini(energy, cost)
	energy -= spent
	if energy == 0:
		action_points = 0
		pressure = mini(5, pressure + 1)
	return spent


func freeze_topic(topic_index: int) -> Dictionary:
	if portfolio_action_used:
		return _failed_action(&"portfolio_action_used")
	if _count_active_topics() < 2:
		return _failed_action(&"single_topic")
	if topic_index < 0 or topic_index >= topics.size() or topics[topic_index].is_closed:
		return _failed_action(&"invalid_target")
	if frozen_topic_indices.get(topic_index, false):
		return _failed_action(&"topic_frozen")
	if _topic_has_action_this_week(topic_index):
		return _failed_action(&"topic_already_used")
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	frozen_topic_indices[topic_index] = true
	portfolio_action_used = true
	var result := {
		"success": true,
		"outcome": &"topic_frozen",
		"topic_index": topic_index,
		"week": week,
		"action_points_left": action_points,
		"energy_left": energy,
		"pressure": pressure,
	}
	action_history.append(result.duplicate(true))
	return result


func transfer_topic_resources(source_index: int, target_index: int) -> Dictionary:
	if portfolio_action_used:
		return _failed_action(&"portfolio_action_used")
	if source_index == target_index:
		return _failed_action(&"invalid_target")
	if (
		source_index < 0
		or source_index >= topics.size()
		or target_index < 0
		or target_index >= topics.size()
	):
		return _failed_action(&"invalid_target")
	var source: DualTopicState = topics[source_index]
	var target: DualTopicState = topics[target_index]
	if source.is_closed or target.is_closed:
		return _failed_action(&"topic_closed")
	if source.evidence < 2:
		return _failed_action(&"insufficient_transfer_evidence")
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	var spent: int = source.spend_evidence(2, &"portfolio_transfer")
	var completion_gain: int = target.add_completion(1, &"portfolio_transfer")
	pressure = mini(5, pressure + 1)
	portfolio_action_used = true
	var result := {
		"success": true,
		"outcome": &"resources_transferred",
		"source_index": source_index,
		"target_index": target_index,
		"evidence_spent": spent,
		"completion_gain": completion_gain,
		"pressure_cost": 1,
		"week": week,
		"action_points_left": action_points,
		"energy_left": energy,
		"pressure": pressure,
	}
	action_history.append(result.duplicate(true))
	return result


func archive_topic_early(source_index: int, target_index: int) -> Dictionary:
	if portfolio_action_used:
		return _failed_action(&"portfolio_action_used")
	if not midterm_resolved:
		return _failed_action(&"archive_before_midterm")
	if week >= MAX_WEEKS:
		return _failed_action(&"archive_too_late")
	if _count_active_topics() < 2 or source_index == target_index:
		return _failed_action(&"invalid_target")
	if (
		source_index < 0
		or source_index >= topics.size()
		or target_index < 0
		or target_index >= topics.size()
	):
		return _failed_action(&"invalid_target")
	var source: DualTopicState = topics[source_index]
	var target: DualTopicState = topics[target_index]
	if source.is_closed or target.is_closed:
		return _failed_action(&"topic_closed")
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	var asset: Dictionary = _create_stop_asset(source_index, source)
	asset["type"] = &"early_archive"
	var recovery_mastered: bool = (
		method_category_uses[DualTopicMethodCardDefinition.Category.ORGANIZATION]
		>= METHOD_MASTERY_THRESHOLD
	)
	var evidence_gain: int = target.add_evidence(
		int(mini(2, source.evidence / 2)) + (1 if recovery_mastered else 0),
		&"early_archive"
	)
	var completion_gain: int = target.add_completion(
		(1 if source.completion >= 2 else 0) + (1 if recovery_mastered else 0),
		&"early_archive"
	)
	var risk_revealed := false
	if _count_revealed_risks(source) > 0:
		var unknown: DualTopicRiskState = _find_risk(
			target,
			DualTopicRiskState.KnowledgeState.UNKNOWN
		)
		if unknown != null:
			risk_revealed = unknown.identify()
	source.archive_early()
	pressure = maxi(0, pressure - 1)
	portfolio_action_used = true
	asset["salvaged_evidence"] = evidence_gain
	asset["salvaged_completion"] = completion_gain
	asset["risk_revealed"] = risk_revealed
	asset["recovery_mastery"] = recovery_mastered
	run_assets.append(asset)
	var result := {
		"success": true,
		"outcome": &"topic_archived_early",
		"source_index": source_index,
		"target_index": target_index,
		"evidence_gain": evidence_gain,
		"completion_gain": completion_gain,
		"risk_revealed": risk_revealed,
		"recovery_mastery": recovery_mastered,
		"pressure_relief": 1,
		"asset": asset.duplicate(true),
		"week": week,
		"action_points_left": action_points,
		"energy_left": energy,
		"pressure": pressure,
	}
	action_history.append(result.duplicate(true))
	return result


func end_week() -> bool:
	if week >= MAX_WEEKS:
		return false
	week_history.append({
		"week": week,
		"actions": _get_current_week_actions(),
		"ending_energy": energy,
		"ending_pressure": pressure,
	})
	for topic: DualTopicState in topics:
		if topic.commitment == DualTopicState.Commitment.DOUBLE_DOWN and not topic.is_closed:
			pressure = mini(5, pressure + 1)
		if (
			topic.definition.special_rule == &"deployment_exposure"
			and _count_unknown_risks(topic) > 0
			and not topic.is_closed
		):
			pressure = mini(5, pressure + 1)
	if (
		_count_attended_topics() > 1
		and _has_portfolio_metadata()
		and get_shared_synergy_tags().is_empty()
	):
		pressure = mini(5, pressure + 1)
	week += 1
	action_points = ACTION_POINTS_PER_WEEK
	_double_down_triggered_topics.clear()
	frozen_topic_indices.clear()
	portfolio_action_used = false
	if pressure < 5:
		energy = mini(MAX_ENERGY, energy + 2)
	return true


func get_shared_synergy_tags() -> PackedStringArray:
	var shared := PackedStringArray()
	if topics.size() != 2:
		return shared
	for tag: String in topics[0].definition.synergy_tags:
		if topics[1].definition.synergy_tags.has(tag):
			shared.append(tag)
	return shared


func get_portfolio_relation() -> StringName:
	if _count_active_topics() < 2:
		return &"single"
	if not _has_portfolio_metadata():
		return &"legacy"
	return &"synergy" if not get_shared_synergy_tags().is_empty() else &"conflict"


func _has_portfolio_metadata() -> bool:
	return (
		topics.size() == 2
		and not topics[0].definition.synergy_tags.is_empty()
		and not topics[1].definition.synergy_tags.is_empty()
	)


func can_finish_run() -> bool:
	return week == MAX_WEEKS


func get_draw_penalty() -> int:
	return 1 if pressure >= 5 else 0


func should_add_interference_card() -> bool:
	return pressure >= 3


func get_submission_result(topic_index: int) -> StringName:
	if topic_index < 0 or topic_index >= topics.size():
		return &"invalid"
	var topic: DualTopicState = topics[topic_index]
	if topic.meets_excellent_minimum() and _meets_window_submission_minimum(topic):
		return &"excellent"
	if (
		topic.meets_submission_minimum()
		and _meets_window_submission_minimum(topic)
	):
		return &"pass"
	return &"failed"


func get_submission_preview(topic_index: int) -> Dictionary:
	if topic_index < 0 or topic_index >= topics.size():
		return {"ready": false, "reason": &"invalid_target"}
	var topic: DualTopicState = topics[topic_index]
	if simplified_submission_enabled:
		var evaluation: Dictionary = _evaluate_simplified_submission(topic)
		return {
			"ready": bool(evaluation.get("ready", false)),
			"base_grade": evaluation.get("grade", &"failed"),
			"requirement_met": _meets_public_requirement(topic),
			"diagnosis": Dictionary(evaluation.get("diagnosis", {})),
			"review_comments": [],
			"controlled_risks": _count_controlled_risks(topic),
			"risk_count": topic.risks.size(),
			"verified_risks": _count_verified_risks(topic),
			"evidence": topic.evidence,
			"completion": topic.completion,
			"required_evidence": submission_minimum_evidence,
			"required_completion": submission_minimum_completion,
			"submission_mode": &"simplified",
		}
	var base_grade := get_submission_result(topic_index)
	var requirement_met := _meets_public_requirement(topic)
	var diagnosis: Dictionary = (
		{}
		if base_grade != &"failed" and requirement_met
		else _diagnose_failure(topic)
	)
	return {
		"ready": base_grade != &"failed" and requirement_met,
		"base_grade": base_grade,
		"requirement_met": requirement_met,
		"diagnosis": diagnosis,
		"review_comments": _build_review_comments(topic_index, topic, diagnosis),
		"controlled_risks": _count_controlled_risks(topic),
		"risk_count": topic.risks.size(),
		"verified_risks": _count_verified_risks(topic),
		"evidence": topic.evidence,
		"completion": topic.completion,
		"required_evidence": submission_minimum_evidence,
		"required_completion": submission_minimum_completion,
	}


func _evaluate_simplified_submission(topic: DualTopicState) -> Dictionary:
	return _phase_one_submission_policy.evaluate(
		topic,
		submission_minimum_evidence,
		submission_minimum_completion,
		_meets_public_requirement(topic)
	)


func _build_review_comments(
	topic_index: int,
	topic: DualTopicState,
	diagnosis: Dictionary
) -> Array[Dictionary]:
	var comments: Array[Dictionary] = []
	var topic_actions: Array[Dictionary] = []
	for action: Dictionary in action_history:
		if int(action.get("topic_index", -1)) == topic_index:
			topic_actions.append(action)

	var reason := StringName(diagnosis.get("reason", &""))
	match reason:
		&"completion_insufficient":
			comments.append(_review_comment(
				&"major",
				"论文结构尚未收束；返修应优先补齐组织或写作，而不是继续扩张风险档案。",
				_last_action_week(topic_actions, [
					ActionType.ORGANIZE,
					ActionType.WRITE,
				])
			))
		&"evidence_insufficient":
			comments.append(_review_comment(
				&"major",
				"核心主张缺少足够证据；需要把已识别风险转化为可复核的试验结果。",
				_last_action_week(topic_actions, [ActionType.EXPERIMENT])
			))
		&"high_risk_unhandled", &"risk_control":
			comments.append(_review_comment(
				&"major",
				"风险档案已经暴露问题，但尚未形成控制方案；验证不等于风险受控。",
				_last_action_week(topic_actions, [
					ActionType.INVESTIGATE,
					ActionType.EXPERIMENT,
				])
			))
		&"reproducibility":
			comments.append(_review_comment(
				&"major",
				"结果可见，但复现链条不完整；需要补充验证并将过程写入论文结构。",
				_last_action_week(topic_actions, [ActionType.EXPERIMENT])
			))
		&"evidence_integrity":
			comments.append(_review_comment(
				&"major",
				"公开要求强调证据完整性，当前材料不足以支撑全部结论。",
				_last_action_week(topic_actions, [ActionType.EXPERIMENT])
			))

	var soft_action := _last_soft_prerequisite_action(topic_actions)
	if not soft_action.is_empty():
		comments.append(_review_comment(
			&"process",
			"早期曾用软前置推进研究，换来了速度，也留下了需要在返修中解释的过程债。",
			int(soft_action.get("week", 0))
		))

	var strongest_category: int = 0
	for category: int in range(1, 3):
		if method_category_uses[category] > method_category_uses[strongest_category]:
			strongest_category = category
	var category_names: Array[String] = ["调查", "实验", "组织"]
	if method_category_uses[strongest_category] > 0:
		comments.append(_review_comment(
			&"strength",
			"%s路线已经形成，是本稿最清晰的方法优势；后续返修应围绕它补短板。"
			% category_names[strongest_category],
			_first_category_week(topic_actions, strongest_category)
		))

	if comments.size() < 2:
		var investment_text := (
			"该课题只有 %d 次可追溯投入，研究链过短；返修时应先补齐最薄弱的一环。"
			% topic_actions.size()
			if topic_actions.size() < 4
			else "该课题已有 %d 次投入，但方法分布未形成明显优势，需要在返修中明确主路线。"
			% topic_actions.size()
		)
		comments.append(_review_comment(
			&"process",
			investment_text,
			_last_action_week(topic_actions, [])
		))

	if comments.is_empty():
		comments.append(_review_comment(
			&"strength",
			"证据、结构与公开要求相互吻合，建议保留当前研究路线进入送审。",
			_last_action_week(topic_actions, [])
		))
	return comments.slice(0, 3)


func _review_comment(
	severity: StringName,
	text: String,
	trace_week: int
) -> Dictionary:
	return {
		"severity": severity,
		"text": text,
		"trace_week": trace_week,
	}


func _last_action_week(actions: Array[Dictionary], types: Array) -> int:
	for index: int in range(actions.size() - 1, -1, -1):
		if types.is_empty() or int(actions[index].get("action_type", -1)) in types:
			return int(actions[index].get("week", 0))
	return 0


func _first_category_week(actions: Array[Dictionary], category: int) -> int:
	for action: Dictionary in actions:
		if int(action.get("category", -1)) == category:
			return int(action.get("week", 0))
	return 0


func _last_soft_prerequisite_action(actions: Array[Dictionary]) -> Dictionary:
	for index: int in range(actions.size() - 1, -1, -1):
		if actions[index].get("outcome", &"") in [
			&"blind_probe",
			&"framework_prepared",
			&"outline_drafted",
		]:
			return actions[index]
	return {}


func to_debug_dict() -> Dictionary:
	var topic_data: Array[Dictionary] = []
	for topic: DualTopicState in topics:
		topic_data.append(topic.to_debug_dict())
	return {
		"seed": seed,
		"week": week,
		"action_points": action_points,
		"energy": energy,
		"pressure": pressure,
		"submission_minimum_evidence": submission_minimum_evidence,
		"submission_minimum_completion": submission_minimum_completion,
		"simplified_submission_enabled": simplified_submission_enabled,
		"topics": topic_data,
		"action_history": action_history.duplicate(true),
		"week_history": week_history.duplicate(true),
		"run_assets": run_assets.duplicate(true),
		"carryover_history": carryover_history.duplicate(true),
		"carryover_applied": carryover_applied,
		"method_category_uses": method_category_uses.duplicate(),
		"cooperation_trajectory": get_cooperation_trajectory(),
		"review_revision_used": review_revision_used,
		"transferred_venue": transferred_venue,
		"midterm_resolved": midterm_resolved,
		"public_requirement": public_requirement,
		"final_resolved": final_resolved,
		"final_resolution": final_resolution.duplicate(true),
		"final_legacy": final_legacy.duplicate(true),
	}


func get_cooperation_trajectory() -> Dictionary:
	return {
		"cooperation_results": cooperation_result_count,
		"cross_topic_synergies": cross_topic_synergy_count,
		"converted_failure_assets": converted_failure_asset_count,
	}


func get_method_mastery_summary() -> String:
	var labels: Array[String] = ["调查", "实验", "组织"]
	var parts: Array[String] = []
	for category: int in range(3):
		var uses: int = method_category_uses[category]
		if uses >= METHOD_MASTERY_THRESHOLD:
			parts.append("%s专精" % labels[category])
		else:
			parts.append("%s %d/%d" % [
				labels[category],
				uses,
				METHOD_MASTERY_THRESHOLD,
			])
	var tendency: Dictionary = get_build_tendency_profile()
	return "研究风格 · %s\n当前倾向 · %s｜%s" % [
		"  ".join(parts),
		String(tendency.get("title", "")),
		String(tendency.get("next_lever", "")),
	]


func get_build_tendency_profile() -> Dictionary:
	var investigation_uses: int = method_category_uses[
		DualTopicMethodCardDefinition.Category.INVESTIGATION
	]
	var experiment_uses: int = method_category_uses[
		DualTopicMethodCardDefinition.Category.EXPERIMENT
	]
	var organization_uses: int = method_category_uses[
		DualTopicMethodCardDefinition.Category.ORGANIZATION
	]
	var recovery_score: int = organization_uses + run_assets.size() * 2
	if recovery_score > investigation_uses and recovery_score > experiment_uses:
		return {
			"id": &"asset_recovery",
			"title": "资产回收",
			"effect": "组织专精会强化中期止损，将更多证据与完成度转入主课题。",
			"next_lever": "继续组织，或在中期把副课题止损归档",
		}
	if experiment_uses > investigation_uses:
		return {
			"id": &"risky_exploration",
			"title": "冒险探索",
			"effect": "实验专精会把不稳定结果继续沉淀为额外证据。",
			"next_lever": "继续实验以突破收益上限",
		}
	return {
		"id": &"stable_replication",
		"title": "稳健复现",
		"effect": "调查专精会扩大一次行动揭示的风险信息面。",
		"next_lever": "继续调查并逐项控制风险",
	}


func _apply_method_mastery(
	category: DualTopicMethodCardDefinition.Category,
	topic: DualTopicState,
	result: Dictionary
) -> void:
	var uses: int = method_category_uses[category]
	if uses < METHOD_MASTERY_THRESHOLD:
		if uses == METHOD_MASTERY_THRESHOLD - 1:
			result["mastery_near"] = true
		return
	result["mastery_unlocked"] = uses == METHOD_MASTERY_THRESHOLD
	match category:
		DualTopicMethodCardDefinition.Category.INVESTIGATION:
			if topic == null:
				return
			var extra_risk := _find_risk(
				topic,
				DualTopicRiskState.KnowledgeState.UNKNOWN
			)
			if extra_risk != null:
				extra_risk.identify()
				result["mastery_effect"] = &"investigation_breadth"
				result["mastery_risk_id"] = extra_risk.definition.id
		DualTopicMethodCardDefinition.Category.EXPERIMENT:
			if topic == null:
				return
			var evidence_gain := topic.add_evidence(1, &"experiment_mastery")
			if evidence_gain > 0:
				result["mastery_effect"] = &"experiment_learning"
				result["mastery_evidence"] = evidence_gain
		DualTopicMethodCardDefinition.Category.ORGANIZATION:
			var restored: int = mini(1, MAX_ENERGY - energy)
			if restored > 0:
				energy += restored
				result["mastery_effect"] = &"organization_efficiency"
				result["mastery_energy"] = restored
				result["energy_left"] = energy


func _perform_investigate(topic: DualTopicState) -> Dictionary:
	var risk: DualTopicRiskState = _find_risk(topic, DualTopicRiskState.KnowledgeState.UNKNOWN)
	if risk == null:
		return _failed_action(&"no_unknown_risk")
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	spend_energy(1)
	risk.identify()
	return {
		"success": true,
		"outcome": &"risk_identified",
		"risk_id": risk.definition.id,
		"risk_name": risk.definition.display_name,
		"risk_kind": int(risk.definition.kind),
		"tier": risk.tier,
		"submission_blocked": risk.is_high_unhandled(),
		"withdrawal_asset": &"risk_insight",
	}


func _perform_experiment(topic: DualTopicState) -> Dictionary:
	var risk: DualTopicRiskState = _find_risk(topic, DualTopicRiskState.KnowledgeState.IDENTIFIED)
	if risk == null:
		var unknown_risk := _find_risk(topic, DualTopicRiskState.KnowledgeState.UNKNOWN)
		if unknown_risk == null:
			return _failed_action(&"no_identified_risk")
		if not spend_action_points(1):
			return _failed_action(&"no_action_points")
		spend_energy(2)
		unknown_risk.identify()
		pressure = mini(5, pressure + 1)
		return {
			"success": true,
			"outcome": &"blind_probe",
			"risk_id": unknown_risk.definition.id,
			"evidence_gain": 0,
			"pressure_cost": 1,
		}
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	spend_energy(2)
	var experiment_result: StringName = risk.consume_experiment_result()
	risk.verify()
	var evidence_gain: int = 0
	match experiment_result:
		&"normal":
			evidence_gain = topic.add_evidence(2, &"experiment")
			risk.lower_tier()
		&"anomaly":
			evidence_gain = topic.add_evidence(1, &"experiment")
			pressure = mini(5, pressure + 1)
		&"failed":
			pressure = mini(5, pressure + 1)
		_:
			experiment_result = &"normal"
			evidence_gain = topic.add_evidence(2, &"experiment")
	return {
		"success": true,
		"outcome": experiment_result,
		"risk_id": risk.definition.id,
		"evidence_gain": evidence_gain,
	}


func _perform_organize(topic: DualTopicState) -> Dictionary:
	if topic.evidence <= 0:
		if not spend_action_points(1):
			return _failed_action(&"no_action_points")
		spend_energy(1)
		var prepared_evidence := topic.add_evidence(1, &"framework_prepared")
		return {
			"success": true,
			"outcome": &"framework_prepared",
			"evidence_gain": prepared_evidence,
			"completion_gain": 0,
		}
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	spend_energy(1)
	var completion_gain: int = topic.add_completion(1, &"organize")
	return {
		"success": true,
		"outcome": &"completion_gained",
		"completion_gain": completion_gain,
	}


func _perform_write(topic: DualTopicState) -> Dictionary:
	if topic.evidence < 2:
		if not spend_action_points(1):
			return _failed_action(&"no_action_points")
		spend_energy(2)
		var outline_gain := topic.add_completion(1, &"outline_drafted")
		pressure = mini(5, pressure + 1)
		return {
			"success": true,
			"outcome": &"outline_drafted",
			"completion_gain": outline_gain,
			"pressure_cost": 1,
		}
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	spend_energy(2)
	var completion_gain: int = topic.add_completion(2, &"write")
	return {
		"success": true,
		"outcome": &"completion_gained",
		"completion_gain": completion_gain,
	}


func _perform_recover() -> Dictionary:
	if energy >= MAX_ENERGY and pressure <= 0:
		return _failed_action(&"energy_full")
	if not spend_action_points(1):
		return _failed_action(&"no_action_points")
	var restored: int = mini(2, MAX_ENERGY - energy)
	energy += restored
	var pressure_relief: int = mini(2 if restored == 0 else 1, pressure)
	pressure = maxi(0, pressure - pressure_relief)
	var result: Dictionary = {
		"success": true,
		"outcome": &"decompressed" if restored == 0 else &"recovered",
		"energy_gain": restored,
		"pressure_relief": pressure_relief,
		"week": week,
		"topic_index": -1,
		"action_type": int(ActionType.RECOVER),
		"action_points_left": action_points,
		"energy_left": energy,
		"pressure": pressure,
	}
	action_history.append(result.duplicate(true))
	return result


func _apply_double_down_bonus(
	topic_index: int,
	topic: DualTopicState,
	result: Dictionary
) -> void:
	if topic.commitment != DualTopicState.Commitment.DOUBLE_DOWN:
		return
	if _double_down_triggered_topics.get(topic_index, false):
		return
	_double_down_triggered_topics[topic_index] = true
	var bonus_kind: StringName = &"evidence"
	var bonus_amount: int = topic.add_evidence(1, &"double_down")
	if int(result.get("completion_gain", 0)) > 0:
		bonus_kind = &"completion"
		bonus_amount = topic.add_completion(1, &"double_down")
	result["double_down_bonus_kind"] = bonus_kind
	result["double_down_bonus"] = bonus_amount


func _apply_topic_special_rule(
	topic_index: int,
	topic: DualTopicState,
	action_type: ActionType,
	result: Dictionary
) -> void:
	var rule: StringName = topic.definition.special_rule
	var trigger_key: String = "%d:%s" % [topic_index, rule]
	match rule:
		&"reproduction_bonus":
			if (
				action_type == ActionType.EXPERIMENT
				and result.get("outcome", &"") == &"normal"
				and not _special_rule_triggers.get(trigger_key, false)
			):
				result["special_evidence"] = topic.add_evidence(1, rule)
				_special_rule_triggers[trigger_key] = true
		&"negative_result_asset":
			if (
				action_type == ActionType.EXPERIMENT
				and result.get("outcome", &"") in [&"anomaly", &"failed"]
				and not _special_rule_triggers.get(trigger_key, false)
			):
				result["special_evidence"] = topic.add_evidence(1, rule)
				_special_rule_triggers[trigger_key] = true
		&"scarce_data":
			if action_type == ActionType.INVESTIGATE:
				result["special_evidence"] = topic.add_evidence(1, rule)
		&"pipeline_engine":
			if action_type == ActionType.EXPERIMENT:
				if week <= 2:
					var extra_energy_cost: int = spend_energy(1)
					result["special_energy_cost"] = extra_energy_cost
				elif week >= 4 and result.get("outcome", &"") == &"normal":
					result["special_evidence"] = topic.add_evidence(1, rule)
		&"multi_source":
			if action_type == ActionType.EXPERIMENT:
				if result.get("outcome", &"") == &"normal":
					result["special_evidence"] = topic.add_evidence(1, rule)
				else:
					pressure = mini(5, pressure + 1)
					result["special_pressure_cost"] = 1
		_:
			pass
	result["energy_left"] = energy
	result["pressure"] = pressure


func _apply_cross_topic_synergy(topic_index: int, result: Dictionary) -> void:
	if topics.size() != 2 or topic_index < 0 or topic_index >= topics.size():
		return
	if _synergy_triggered_weeks.get(week, false):
		return
	if get_shared_synergy_tags().is_empty():
		return
	var evidence_created := (
		int(result.get("evidence_gain", 0))
		+ int(result.get("bonus_evidence", 0))
		+ int(result.get("special_evidence", 0))
	)
	if evidence_created <= 0:
		return
	var other_index := 1 - topic_index
	var other_topic: DualTopicState = topics[other_index]
	if other_topic.is_closed:
		return
	var shared_gain := other_topic.add_evidence(1, &"cross_topic_synergy")
	if shared_gain <= 0:
		return
	_synergy_triggered_weeks[week] = true
	cross_topic_synergy_count += 1
	result["synergy_evidence"] = shared_gain
	result["synergy_target_index"] = other_index
	result["synergy_tags"] = get_shared_synergy_tags()


func _apply_method_effect(
	effect_id: StringName,
	topic: DualTopicState,
	result: Dictionary
) -> void:
	match effect_id:
		&"low_risk_insight":
			if topic != null and int(result.get("tier", -1)) == DualTopicRiskState.RiskTier.LOW:
				result["bonus_evidence"] = topic.add_evidence(1, effect_id)
		&"wide_scan":
			if topic != null:
				var extra_risk: DualTopicRiskState = _find_risk(
					topic,
					DualTopicRiskState.KnowledgeState.UNKNOWN
				)
				if extra_risk != null:
					extra_risk.identify()
					result["extra_risk_id"] = extra_risk.definition.id
					pressure = mini(5, pressure + 1)
		&"pre_register":
			if topic != null:
				var identified: DualTopicRiskState = _find_risk(
					topic,
					DualTopicRiskState.KnowledgeState.IDENTIFIED
				)
				if identified != null:
					result["lowered_risk"] = identified.lower_tier()
		&"replicate":
			if topic != null and result.get("outcome", &"") == &"normal":
				var verified: DualTopicRiskState = _find_risk(
					topic,
					DualTopicRiskState.KnowledgeState.VERIFIED
				)
				if verified != null:
					result["controlled_risk"] = verified.control()
		&"learn_from_failure":
			if topic != null and result.get("outcome", &"") != &"normal":
				result["bonus_evidence"] = topic.add_evidence(1, effect_id)
		&"evidence_ledger":
			if topic != null and topic.evidence >= 3:
				result["bonus_completion"] = topic.add_completion(1, effect_id)
		&"synthesis":
			if topic != null and _are_all_risks_revealed(topic):
				result["bonus_evidence"] = topic.add_evidence(1, effect_id)
		&"milestone":
			if topic != null and topic.evidence >= 4:
				result["bonus_completion"] = topic.add_completion(1, effect_id)
		&"peer_consult":
			pressure = maxi(0, pressure - 1)
			result["pressure_relief"] = 1
		&"external_review":
			if topic != null:
				var identified: DualTopicRiskState = _find_risk(
					topic,
					DualTopicRiskState.KnowledgeState.IDENTIFIED
				)
				if identified != null:
					identified.verify()
					result["verified_risk_id"] = identified.definition.id
					pressure = mini(5, pressure + 1)
		&"shared_protocol":
			if topic != null:
				var verified: DualTopicRiskState = _find_risk(
					topic,
					DualTopicRiskState.KnowledgeState.VERIFIED
				)
				if verified != null:
					result["controlled_risk"] = verified.control()
		&"protected_time":
			if topic != null and int(result.get("completion_gain", 0)) > 0:
				energy = mini(MAX_ENERGY, energy + 1)
				result["energy_refund"] = 1
		&"strategic_pause":
			pressure = maxi(0, pressure - 1)
			result["extra_pressure_relief"] = 1
		_:
			pass
	result["energy_left"] = energy
	result["pressure"] = pressure


func _count_revealed_risks(topic: DualTopicState) -> int:
	var count: int = 0
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN:
			count += 1
	return count


func _are_all_risks_revealed(topic: DualTopicState) -> bool:
	return (
		not topic.risks.is_empty()
		and _count_revealed_risks(topic) == topic.risks.size()
	)


func _count_unknown_risks(topic: DualTopicState) -> int:
	var count: int = 0
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state == DualTopicRiskState.KnowledgeState.UNKNOWN:
			count += 1
	return count


func _find_risk(topic: DualTopicState, state: DualTopicRiskState.KnowledgeState) -> DualTopicRiskState:
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state == state:
			return risk
	return null


func _get_current_week_actions() -> Array[Dictionary]:
	var current_actions: Array[Dictionary] = []
	for action: Dictionary in action_history:
		if int(action.get("week", -1)) == week:
			current_actions.append(action.duplicate(true))
	return current_actions


func _failed_action(reason: StringName) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
		"week": week,
		"action_points_left": action_points,
		"energy_left": energy,
		"pressure": pressure,
	}


func _create_topic_state(definition: DualTopicDefinition) -> DualTopicState:
	var risk_pool := definition.risk_pool.duplicate()
	_shuffle_risk_pool(risk_pool)
	var generated_risks: Array[DualTopicRiskState] = []
	for index in range(definition.risk_slot_count):
		var risk_state := DualTopicRiskState.new()
		risk_state.setup(
			risk_pool[index],
			_rng.randi_range(
				DualTopicRiskState.RiskTier.LOW,
				DualTopicRiskState.RiskTier.HIGH
			),
			_generate_experiment_results()
		)
		generated_risks.append(risk_state)
	var topic_state := DualTopicState.new()
	topic_state.setup(definition, generated_risks)
	return topic_state


func _create_pivot_risk(topic: DualTopicState) -> DualTopicRiskState:
	var used_ids: Dictionary[StringName, bool] = {}
	for risk: DualTopicRiskState in topic.risks:
		used_ids[risk.definition.id] = true
	var candidates: Array[DualTopicRiskDefinition] = []
	for definition: DualTopicRiskDefinition in topic.definition.risk_pool:
		if not used_ids.has(definition.id):
			candidates.append(definition)
	if candidates.is_empty():
		candidates = topic.definition.risk_pool.duplicate()
	var chosen: DualTopicRiskDefinition = candidates[_rng.randi_range(0, candidates.size() - 1)]
	var replacement: DualTopicRiskState = DualTopicRiskState.new()
	replacement.setup(
		chosen,
		_rng.randi_range(DualTopicRiskState.RiskTier.LOW, DualTopicRiskState.RiskTier.HIGH),
		_generate_experiment_results()
	)
	return replacement


func _create_stop_asset(topic_index: int, topic: DualTopicState) -> Dictionary:
	var risk_insights: Array[String] = []
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN:
			risk_insights.append(String(risk.definition.id))
	var method_ids: Array[String] = []
	for action: Dictionary in action_history:
		if int(action.get("topic_index", -1)) != topic_index:
			continue
		var card_id: String = String(action.get("card_id", ""))
		if not card_id.is_empty() and not method_ids.has(card_id):
			method_ids.append(card_id)
	return {
		"type": &"stopped_topic_archive",
		"topic_id": topic.definition.id,
		"risk_insights": risk_insights,
		"method_ids": method_ids,
		"evidence": topic.evidence,
		"completion": topic.completion,
	}


func _count_active_topics() -> int:
	var count: int = 0
	for topic: DualTopicState in topics:
		if not topic.is_closed:
			count += 1
	return count


func _count_attended_topics() -> int:
	var count: int = 0
	for index: int in range(topics.size()):
		if not topics[index].is_closed and not frozen_topic_indices.get(index, false):
			count += 1
	return count


func _topic_has_action_this_week(topic_index: int) -> bool:
	for action: Dictionary in action_history:
		if (
			int(action.get("week", -1)) == week
			and int(action.get("topic_index", -1)) == topic_index
		):
			return true
	return false


func _generate_public_requirement() -> StringName:
	var requirements: Array[StringName] = [
		&"evidence_integrity",
		&"risk_control",
		&"reproducibility",
	]
	return requirements[_rng.randi_range(0, requirements.size() - 1)]


func _meets_public_requirement(topic: DualTopicState) -> bool:
	match public_requirement:
		&"evidence_integrity":
			return topic.evidence >= 4
		&"risk_control":
			for risk: DualTopicRiskState in topic.risks:
				if not risk.is_controlled:
					return false
			return true
		&"reproducibility":
			if topic.completion < 4:
				return false
			for risk: DualTopicRiskState in topic.risks:
				if risk.knowledge_state == DualTopicRiskState.KnowledgeState.VERIFIED:
					return true
			return false
		_:
			return true


func _diagnose_failure(topic: DualTopicState) -> Dictionary:
	if topic.completion < submission_minimum_completion:
		return {
			"category": &"expression",
			"reason": &"completion_insufficient",
			"current": topic.completion,
			"required": submission_minimum_completion,
		}
	if topic.evidence < submission_minimum_evidence:
		return {
			"category": &"evidence",
			"reason": &"evidence_insufficient",
			"current": topic.evidence,
			"required": submission_minimum_evidence,
		}
	for risk: DualTopicRiskState in topic.risks:
		if risk.is_high_unhandled():
			return {
				"category": _risk_kind_to_category(risk.definition.kind),
				"reason": &"high_risk_unhandled",
				"risk_id": risk.definition.id,
				"risk_was_known": (
					risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN
				),
			}
	return {
		"category": &"requirement",
		"reason": public_requirement,
		"current": _public_requirement_progress(topic),
	}


func _meets_window_submission_minimum(topic: DualTopicState) -> bool:
	return (
		topic.evidence >= submission_minimum_evidence
		and topic.completion >= submission_minimum_completion
	)


func _risk_kind_to_category(kind: DualTopicRiskDefinition.RiskKind) -> StringName:
	match kind:
		DualTopicRiskDefinition.RiskKind.THEORY:
			return &"theory"
		DualTopicRiskDefinition.RiskKind.DATA:
			return &"evidence"
		DualTopicRiskDefinition.RiskKind.TECHNICAL:
			return &"risk"
		DualTopicRiskDefinition.RiskKind.EXPRESSION:
			return &"expression"
		_:
			return &"risk"


func _public_requirement_progress(topic: DualTopicState) -> String:
	match public_requirement:
		&"evidence_integrity":
			return "%d/4 evidence" % topic.evidence
		&"risk_control":
			return "%d/%d risks controlled" % [_count_controlled_risks(topic), topic.risks.size()]
		&"reproducibility":
			return "verified=%d completion=%d/4" % [
				_count_verified_risks(topic),
				topic.completion,
			]
		_:
			return ""


func _create_final_legacy(
	mode: StringName,
	grade: StringName,
	topic_index: int,
	topic: DualTopicState,
	diagnosis: Dictionary
) -> Dictionary:
	if mode == &"withdraw":
		return {
			"type": &"risk_insight",
			"risk_id": _first_revealed_risk_id(topic),
			"topic_id": topic.definition.id,
		}
	if grade == &"pass" or grade == &"excellent":
		return {
			"type": &"mature_method",
			"method_id": _most_used_method_id(topic_index),
			"grade": grade,
			"topic_id": topic.definition.id,
		}
	return {
		"type": &"remediation_method",
		"category": diagnosis.get("category", &"risk"),
		"method_id": _remediation_method_for(diagnosis.get("category", &"risk")),
		"topic_id": topic.definition.id,
	}


func _first_revealed_risk_id(topic: DualTopicState) -> StringName:
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state != DualTopicRiskState.KnowledgeState.UNKNOWN:
			return risk.definition.id
	return &"unknown_risk_pattern"


func _most_used_method_id(topic_index: int) -> StringName:
	var counts: Dictionary[StringName, int] = {}
	var best_id: StringName = &"basic_research_routine"
	var best_count: int = 0
	for action: Dictionary in action_history:
		if int(action.get("topic_index", -1)) != topic_index:
			continue
		var card_id: StringName = StringName(action.get("card_id", &""))
		if card_id.is_empty():
			continue
		counts[card_id] = counts.get(card_id, 0) + 1
		if counts[card_id] > best_count:
			best_count = counts[card_id]
			best_id = card_id
	return best_id


func _remediation_method_for(category: StringName) -> StringName:
	match category:
		&"theory":
			return &"theory_repair"
		&"evidence":
			return &"evidence_repair"
		&"expression":
			return &"writing_repair"
		_:
			return &"risk_control_repair"


func _count_controlled_risks(topic: DualTopicState) -> int:
	var count: int = 0
	for risk: DualTopicRiskState in topic.risks:
		if risk.is_controlled:
			count += 1
	return count


func _count_verified_risks(topic: DualTopicState) -> int:
	var count: int = 0
	for risk: DualTopicRiskState in topic.risks:
		if risk.knowledge_state == DualTopicRiskState.KnowledgeState.VERIFIED:
			count += 1
	return count


func _generate_experiment_results() -> Array[StringName]:
	var results: Array[StringName] = []
	for index in range(4):
		var roll := _rng.randi_range(0, 99)
		if roll < 55:
			results.append(&"normal")
		elif roll < 82:
			results.append(&"anomaly")
		else:
			results.append(&"failed")
	return results


func _shuffle_risk_pool(pool: Array) -> void:
	for index in range(pool.size() - 1, 0, -1):
		var swap_index := _rng.randi_range(0, index)
		var current: Variant = pool[index]
		pool[index] = pool[swap_index]
		pool[swap_index] = current
