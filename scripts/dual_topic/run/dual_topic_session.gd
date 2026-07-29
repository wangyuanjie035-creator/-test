extends Node
class_name DualTopicSession

signal state_changed
signal feedback_changed(message: String, is_error: bool)
signal run_finished(result: Dictionary)

const TOPIC_A := preload("res://data/dual_topic/topics/safe_topic_a.tres")
const TOPIC_B := preload("res://data/dual_topic/topics/bold_topic_b.tres")
const METHOD_CATALOG := preload("res://data/dual_topic/methods/starter_method_catalog.tres")

var run_model: DualTopicRunModel
var method_deck: DualTopicMethodDeck
var selected_topic_index: int = 0
var pending_build_offer: Array[DualTopicMethodCardDefinition] = []
var midterm_pending: bool = false
var profile: DualTopicProfile
var topic_investments: Array[int] = [0, 0]
var category_uses: Array[int] = [0, 0, 0, 0, 0]
var build_choices: Array[String] = []
var commitment_choices: Array[DualTopicState.Commitment] = []
var _current_topic_definitions: Array[DualTopicDefinition] = []
var active_legacy_text: String = "本局无遗产加成"


func start_new_run(run_seed: int = 240731) -> void:
	var topics: Array[DualTopicDefinition] = [TOPIC_A, TOPIC_B]
	start_new_run_with_topics(run_seed, topics)


func start_new_run_with_topics(
	run_seed: int,
	topic_definitions: Array[DualTopicDefinition]
) -> void:
	if profile == null:
		profile = DualTopicProfile.new()
		profile.load_profile()
	run_model = DualTopicRunModel.new()
	method_deck = DualTopicMethodDeck.new()
	if not run_model.setup(run_seed, topic_definitions):
		feedback_changed.emit("无法开始研究周期：课题定义无效。", true)
		return
	_current_topic_definitions = topic_definitions.duplicate()
	method_deck.setup(run_seed, _catalog_as_resources())
	_apply_active_legacy()
	selected_topic_index = 0
	pending_build_offer.clear()
	midterm_pending = false
	topic_investments = [0, 0]
	category_uses = [0, 0, 0, 0, 0]
	build_choices.clear()
	commitment_choices.clear()
	_draw_week_hand()
	feedback_changed.emit(
		"调查最稳妥；没有调查牌时也可盲试、搭框架或先写提纲，但会降低收益或增加压力。",
		false
	)
	state_changed.emit()


func select_topic(topic_index: int) -> void:
	if topic_index < 0 or topic_index >= run_model.topics.size():
		return
	if run_model.topics[topic_index].is_closed:
		return
	selected_topic_index = topic_index
	state_changed.emit()


func play_hand_card(hand_index: int) -> void:
	if not can_play_actions():
		feedback_changed.emit("请先完成当前阶段的必要决策。", true)
		return
	if hand_index < 0 or hand_index >= method_deck.hand.size():
		feedback_changed.emit("该方法牌已经不在当前手牌中。", true)
		return
	var played_card: DualTopicMethodCardDefinition = method_deck.hand[hand_index]
	var result: Dictionary = method_deck.play_card(
		hand_index,
		run_model,
		selected_topic_index
	)
	if not bool(result.get("success", false)):
		feedback_changed.emit(_action_failure_text(result.get("reason", &"unknown")), true)
		state_changed.emit()
		return
	topic_investments[selected_topic_index] += 1
	category_uses[played_card.category] += 1
	feedback_changed.emit(_action_result_text(result), false)
	state_changed.emit()


func play_basic_action(action_type: DualTopicRunModel.ActionType) -> void:
	if not can_play_actions():
		feedback_changed.emit("请先完成当前阶段的必要决策。", true)
		return
	var topic_index: int = -1
	if action_type == DualTopicRunModel.ActionType.ORGANIZE:
		topic_index = _get_basic_action_topic_index()
	var result: Dictionary = run_model.perform_basic_action(action_type, topic_index)
	if not bool(result.get("success", false)):
		feedback_changed.emit(_action_failure_text(result.get("reason", &"unknown")), true)
		state_changed.emit()
		return
	if topic_index >= 0:
		selected_topic_index = topic_index
		topic_investments[topic_index] += 1
	feedback_changed.emit("基础行动 · %s" % _action_result_text(result), false)
	state_changed.emit()


func can_play_basic_action(action_type: DualTopicRunModel.ActionType) -> bool:
	if not can_play_actions():
		return false
	var topic_index: int = -1
	if action_type == DualTopicRunModel.ActionType.ORGANIZE:
		topic_index = _get_basic_action_topic_index()
	return run_model.can_perform_basic_action(action_type, topic_index)


func freeze_topic_for_week(topic_index: int) -> void:
	if not can_play_actions():
		return
	var result: Dictionary = run_model.freeze_topic(topic_index)
	if not bool(result.get("success", false)):
		feedback_changed.emit(_portfolio_failure_text(result.get("reason", &"unknown")), true)
		state_changed.emit()
		return
	var topic_name: String = run_model.topics[topic_index].definition.display_name
	feedback_changed.emit(
		"已冻结“%s”：消耗 1 行动，本周不能再投入，但可免除双课题注意力压力。" % topic_name,
		false
	)
	state_changed.emit()


func transfer_topic_resources(source_index: int, target_index: int) -> void:
	if not can_play_actions():
		return
	var result: Dictionary = run_model.transfer_topic_resources(source_index, target_index)
	if not bool(result.get("success", false)):
		feedback_changed.emit(_portfolio_failure_text(result.get("reason", &"unknown")), true)
		state_changed.emit()
		return
	feedback_changed.emit(
		"资源转移完成：副课题证据 -2，主课题完成度 +%d，压力 +1。" % int(
			result.get("completion_gain", 0)
		),
		false
	)
	state_changed.emit()


func archive_topic_early(source_index: int, target_index: int) -> void:
	if not can_play_actions():
		return
	var result: Dictionary = run_model.archive_topic_early(source_index, target_index)
	if not bool(result.get("success", false)):
		feedback_changed.emit(_portfolio_failure_text(result.get("reason", &"unknown")), true)
		state_changed.emit()
		return
	selected_topic_index = target_index
	feedback_changed.emit(
		"止损归档完成：主课题获得证据 +%d、完成度 +%d%s；后续不再承担双课题压力。" % [
			int(result.get("evidence_gain", 0)),
			int(result.get("completion_gain", 0)),
			"、并提前识别一项风险" if bool(result.get("risk_revealed", false)) else "",
		],
		false
	)
	state_changed.emit()


func advance_week() -> void:
	if not can_play_actions():
		feedback_changed.emit("当前还有必须完成的决策。", true)
		return
	if run_model.week >= DualTopicRunModel.MAX_WEEKS:
		feedback_changed.emit("已到第 6 周，请投稿或主动撤出。", true)
		return
	method_deck.discard_hand()
	run_model.end_week()
	if run_model.week == 2 or run_model.week == 4:
		pending_build_offer = method_deck.get_build_offer(
			run_model.week,
			_catalog_as_resources()
		)
	elif run_model.week == 3:
		midterm_pending = true
	else:
		_draw_week_hand()
	feedback_changed.emit("进入第 %d 周。" % run_model.week, false)
	state_changed.emit()


func choose_build_card(choice_index: int, replace_card_id: StringName = &"") -> void:
	if pending_build_offer.is_empty():
		return
	var result: Dictionary = method_deck.apply_build_choice(
		run_model.week,
		choice_index,
		replace_card_id
	)
	if not bool(result.get("success", false)):
		feedback_changed.emit("构筑调整失败：%s" % result.get("reason", &"unknown"), true)
		return
	var chosen_card: DualTopicMethodCardDefinition = pending_build_offer[choice_index]
	build_choices.append(chosen_card.title)
	pending_build_offer.clear()
	_draw_week_hand()
	feedback_changed.emit(
		"已%s「%s」。" % [
			"加入" if result.mode == &"add" else "替换为",
			result.chosen_card_id,
		],
		false
	)
	state_changed.emit()


func resolve_midterm(
	first_choice: DualTopicState.Commitment,
	second_choice: DualTopicState.Commitment
) -> void:
	if not midterm_pending:
		return
	var result: Dictionary = run_model.apply_midterm_decisions(first_choice, second_choice)
	if not bool(result.get("success", false)):
		feedback_changed.emit("中期判断无效：%s" % result.get("reason", &"unknown"), true)
		return
	midterm_pending = false
	commitment_choices = [first_choice, second_choice]
	if run_model.topics[selected_topic_index].is_closed:
		selected_topic_index = 1 - selected_topic_index
	_draw_week_hand()
	feedback_changed.emit("中期判断已写入项目档案，之后不可撤销。", false)
	state_changed.emit()


func resolve_single_topic_midterm(choice: DualTopicState.Commitment) -> void:
	if not midterm_pending:
		return
	var choices: Array[DualTopicState.Commitment] = [choice]
	var result: Dictionary = run_model.apply_midterm_commitments(choices)
	if not bool(result.get("success", false)):
		feedback_changed.emit("单课题中期判断无效：%s" % result.get("reason", &"unknown"), true)
		return
	midterm_pending = false
	commitment_choices = choices
	_draw_week_hand()
	feedback_changed.emit("中期承诺已写入项目档案，之后不可撤销。", false)
	state_changed.emit()


func restart_current_run() -> void:
	start_new_run_with_topics(run_model.seed, _current_topic_definitions)


func apply_cycle_carryover(assets: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = run_model.apply_carryover_assets(assets, 0)
	if not bool(result.get("success", false)):
		return result
	if int(result.get("applied_assets", 0)) > 0:
		feedback_changed.emit(
			"上一周期资产已兑现：证据 +%d、完成度 +%d、提前识别风险 %d 项。" % [
				int(result.get("evidence_gain", 0)),
				int(result.get("completion_gain", 0)),
				int(result.get("risks_revealed", 0)),
			],
			false
		)
		state_changed.emit()
	return result


func apply_academic_opening(modifier: Dictionary) -> Dictionary:
	var result: Dictionary = run_model.apply_opening_modifier(modifier, 0)
	if not bool(result.get("success", false)):
		return result
	var record: Dictionary = result.get("record", {})
	feedback_changed.emit(
		"周期机会已兑现：%s" % String(record.get("summary", "开局资源已调整")),
		false
	)
	state_changed.emit()
	return result


func finish_run(mode: StringName, topic_index: int) -> void:
	var result: Dictionary = run_model.resolve_run(mode, topic_index)
	if not bool(result.get("success", false)):
		feedback_changed.emit("无法结算：%s" % result.get("reason", &"unknown"), true)
		return
	var topic_name: String = run_model.topics[topic_index].definition.display_name
	var save_error := profile.record_result(result, topic_name)
	if save_error != OK:
		feedback_changed.emit("结算完成，但研究档案保存失败。", true)
	run_finished.emit(result)
	state_changed.emit()


func apply_review_decision(decision: StringName, topic_index: int) -> void:
	var result: Dictionary = run_model.apply_review_decision(
		decision,
		topic_index
	)
	if not bool(result.get("success", false)):
		feedback_changed.emit(
			"审稿决策无法执行：%s" % result.get("reason", &"unknown"),
			true
		)
		return
	if decision == &"revise":
		var repair: Dictionary = result.get("repair", {})
		feedback_changed.emit(
			"已按主要意见定向返修：%s +%d；消耗 1 行动、1 精力，压力 +1。" % [
				_review_repair_text(repair.get("kind", &"")),
				int(repair.get("amount", 0)),
			],
			false
		)
	else:
		feedback_changed.emit(
			"已改投稳妥期刊：投稿门槛各降低 1，公开要求取消；最高只能普通接收且收益 -1。",
			false
		)
	state_changed.emit()


func _review_repair_text(kind: StringName) -> String:
	match kind:
		&"evidence":
			return "证据"
		&"risk_control":
			return "风险控制"
		_:
			return "完成度"


func get_archive_summary() -> String:
	if profile == null:
		return "研究档案 · 尚未载入"
	return "%s\n遗产兑现 · %s" % [profile.get_summary(), active_legacy_text]


func get_method_mastery_summary() -> String:
	if run_model == null:
		return ""
	return run_model.get_method_mastery_summary()


func get_route_summary() -> String:
	var category_names: Array[String] = ["调查", "实验", "组织", "协作", "生存"]
	var used_categories: PackedStringArray = []
	for index: int in range(category_uses.size()):
		if category_uses[index] > 0:
			used_categories.append("%s%d" % [category_names[index], category_uses[index]])
	var build_text: String = "未调整构筑"
	if not build_choices.is_empty():
		build_text = "构筑：" + "、".join(build_choices)
	return "投入 A/B：%d/%d · %s\n%s" % [
		topic_investments[0],
		topic_investments[1],
		" / ".join(used_categories),
		build_text,
	]


func get_replay_challenge(result: Dictionary) -> String:
	var submitted_topic: int = int(result.get("topic_index", 0))
	if topic_investments[0] == 0 or topic_investments[1] == 0:
		return "下一局挑战：在第 3 周前同时调查两个课题，再决定主攻方向。"
	if commitment_choices.has(DualTopicState.Commitment.PIVOT):
		return "下一局挑战：不使用转向，靠前期风险调查完成投稿。"
	if category_uses[DualTopicMethodCardDefinition.Category.COLLABORATION] == 0:
		return "下一局挑战：使用一次协作方法，尝试降低高压路线的代价。"
	return "下一局挑战：改投课题 %s，比较两条路线留下的成果。" % (
		"B" if submitted_topic == 0 else "A"
	)


func can_play_actions() -> bool:
	return (
		run_model != null
		and not run_model.final_resolved
		and pending_build_offer.is_empty()
		and not midterm_pending
		and run_model.week <= DualTopicRunModel.MAX_WEEKS
	)


func _draw_week_hand() -> void:
	var draw_count: int = 5 - run_model.get_draw_penalty()
	method_deck.draw_week_hand(draw_count)


func _get_basic_action_topic_index() -> int:
	if (
		selected_topic_index >= 0
		and selected_topic_index < run_model.topics.size()
		and not run_model.topics[selected_topic_index].is_closed
		and not run_model.frozen_topic_indices.get(selected_topic_index, false)
	):
		return selected_topic_index
	for index: int in range(run_model.topics.size()):
		if (
			not run_model.topics[index].is_closed
			and not run_model.frozen_topic_indices.get(index, false)
		):
			return index
	return -1


func _catalog_as_resources() -> Array[Resource]:
	var resources: Array[Resource] = []
	for card: Resource in METHOD_CATALOG.cards:
		resources.append(card)
	return resources


func _apply_active_legacy() -> void:
	active_legacy_text = "本局无遗产加成"
	var legacy: Dictionary = profile.get_active_legacy()
	match StringName(legacy.get("type", "")):
		&"mature_method":
			var method_id := StringName(legacy.get("method_id", ""))
			var card := _find_catalog_card(method_id)
			if card != null and method_deck.add_legacy_card(card):
				active_legacy_text = "成熟方法「%s」已加入牌组" % card.title
		&"risk_insight":
			var risk_id := StringName(legacy.get("risk_id", ""))
			var revealed_name := _reveal_inherited_risk(risk_id)
			active_legacy_text = "风险认知已揭示「%s」" % revealed_name
		&"remediation_method":
			active_legacy_text = _apply_remediation(StringName(legacy.get("method_id", "")))


func _find_catalog_card(card_id: StringName) -> DualTopicMethodCardDefinition:
	for resource: Resource in METHOD_CATALOG.cards:
		var card := resource as DualTopicMethodCardDefinition
		if card != null and card.id == card_id:
			return card
	return null


func _reveal_inherited_risk(risk_id: StringName) -> String:
	for topic: DualTopicState in run_model.topics:
		for risk: DualTopicRiskState in topic.risks:
			if risk.definition.id == risk_id:
				risk.identify()
				return risk.definition.display_name
	for topic: DualTopicState in run_model.topics:
		for risk: DualTopicRiskState in topic.risks:
			if risk.knowledge_state == DualTopicRiskState.KnowledgeState.UNKNOWN:
				risk.identify()
				return risk.definition.display_name
	return "未知风险模式"


func _apply_remediation(method_id: StringName) -> String:
	var topic: DualTopicState = run_model.topics[0]
	match method_id:
		&"theory_repair", &"evidence_repair":
			topic.add_evidence(1, &"legacy_remediation")
			return "补救方法令稳妥课题开局证据 +1"
		&"writing_repair":
			topic.add_completion(1, &"legacy_remediation")
			return "表达整理令稳妥课题开局完成度 +1"
		_:
			var risk_name := _reveal_inherited_risk(&"")
			return "风险补救已揭示「%s」" % risk_name


func _portfolio_failure_text(reason: StringName) -> String:
	match reason:
		&"portfolio_action_used":
			return "本周已经进行过一次课题组合调整。"
		&"topic_already_used":
			return "该课题本周已经投入过行动，必须在投入前决定是否冻结。"
		&"insufficient_transfer_evidence":
			return "副课题至少需要 2 点证据才能进行资源转移。"
		&"topic_frozen":
			return "该课题本周已经冻结。"
		&"single_topic":
			return "单课题路线不需要组合调整。"
		&"archive_before_midterm":
			return "止损归档会改变研究承诺，必须在第 3 周中期判断完成后使用。"
		&"archive_too_late":
			return "最终周已经进入投稿结算，不能再进行止损归档。"
		_:
			return _action_failure_text(reason)


func _action_failure_text(reason: StringName) -> String:
	match reason:
		&"no_unknown_risk":
			return "该课题已没有未知风险，需要改用试验、整理或写作。"
		&"no_identified_risk":
			return "先用调查方法识别一个风险，再进行试验。"
		&"insufficient_evidence":
			return "证据不足，暂时无法整理或写作。"
		&"energy_full":
			return "精力已满，不需要恢复。"
		&"no_action_points":
			return "本周行动点已用完。"
		&"no_energy":
			return "精力已耗尽，本周结束。"
		_:
			return "该方法现在无法使用：%s。" % reason


func _action_result_text(result: Dictionary) -> String:
	var card_id: String = String(result.get("card_id", "方法"))
	var outcome: String = _outcome_text(StringName(result.get("outcome", &"")))
	var risk_feedback := _risk_reveal_feedback(result)
	if not risk_feedback.is_empty():
		outcome += "\n" + risk_feedback
	var special_feedback := _special_rule_feedback(result)
	if not special_feedback.is_empty():
		outcome += "\n" + special_feedback
	return "「%s」已作用于课题 %s：%s" % [
		card_id,
		"A" if selected_topic_index == 0 else "B",
		outcome,
	]


func _risk_reveal_feedback(result: Dictionary) -> String:
	if result.get("outcome", &"") != &"risk_identified":
		return ""
	var risk_name := String(result.get("risk_name", "未知问题"))
	var tier_names: Array[String] = ["低", "中", "高"]
	var tier: int = clampi(int(result.get("tier", 0)), 0, tier_names.size() - 1)
	var route_hint: String
	match int(result.get("risk_kind", -1)):
		DualTopicRiskDefinition.RiskKind.THEORY:
			route_hint = "优先继续调查或组织论证，再决定是否试验"
		DualTopicRiskDefinition.RiskKind.DATA:
			route_hint = "优先复现、共享协议或外部评审"
		DualTopicRiskDefinition.RiskKind.TECHNICAL:
			route_hint = "优先进行受控试验，避免直接写作兑现"
		DualTopicRiskDefinition.RiskKind.EXPRESSION:
			route_hint = "优先整理证据并补足写作结构"
		_:
			route_hint = "根据当前方法牌决定继续验证或止损"
	var submission_effect := (
		"未处理将阻断投稿"
		if bool(result.get("submission_blocked", false))
		else "验证后可继续推进投稿"
	)
	return (
		"新发现：「%s」· %s风险；%s。\n"
		+ "继续：%s；现在止损：保留风险认知。"
	) % [risk_name, tier_names[tier], submission_effect, route_hint]


func _special_rule_feedback(result: Dictionary) -> String:
	var feedback: Array[String] = []
	if bool(result.get("mastery_near", false)):
		feedback.append("研究风格即将成形：再使用 1 次同类方法即可专精")
	var mastery_effect := StringName(result.get("mastery_effect", &""))
	match mastery_effect:
		&"investigation_breadth":
			feedback.append("调查专精：额外识别 1 项风险")
		&"experiment_learning":
			feedback.append(
				"实验专精：无论结果如何，额外沉淀证据 +%d"
				% int(result.get("mastery_evidence", 0))
			)
		&"organization_efficiency":
			feedback.append(
				"组织专精：流程优化返还精力 +%d"
				% int(result.get("mastery_energy", 0))
			)
	if bool(result.get("mastery_unlocked", false)):
		feedback.append("研究风格已形成，本局后续同类方法持续获得专精收益")
	var evidence_gain := int(result.get("special_evidence", 0))
	if evidence_gain > 0:
		feedback.append("课题特性触发：证据 +%d" % evidence_gain)
	var energy_cost := int(result.get("special_energy_cost", 0))
	if energy_cost > 0:
		feedback.append("课题特性代价：精力 -%d" % energy_cost)
	var pressure_cost := int(result.get("special_pressure_cost", 0))
	if pressure_cost > 0:
		feedback.append("课题特性代价：压力 +%d" % pressure_cost)
	var synergy_gain := int(result.get("synergy_evidence", 0))
	if synergy_gain > 0:
		var target_name := "A" if int(result.get("synergy_target_index", 0)) == 0 else "B"
		feedback.append("跨课题协同：课题 %s 证据 +%d" % [target_name, synergy_gain])
	return "；".join(feedback)


func _outcome_text(outcome: StringName) -> String:
	match outcome:
		&"blind_probe":
			return "进行了盲试，识别一个风险，但压力 +1。"
		&"framework_prepared":
			return "先搭建研究框架，获得 1 证据。"
		&"outline_drafted":
			return "提前写出提纲，完成度 +1，但压力 +1。"
		&"decompressed":
			return "精力已满，改为集中减压。"
		&"risk_identified":
			return "识别了一个未知风险。"
		&"normal":
			return "试验正常，证据增加且风险降低。"
		&"anomaly":
			return "出现异常，获得少量证据且压力上升。"
		&"failed":
			return "试验失败；部分方法仍可从失败中获得证据。"
		&"completion_gained":
			return "研究表达继续成形。"
		&"recovered":
			return "恢复精力并缓解压力。"
		_:
			return "行动完成。"
