extends Control

const CARD_BUTTON := preload("res://scripts/dual_topic/ui/dual_topic_method_card_button.gd")

@onready var session: Node = $Session
@onready var week_label: Label = %WeekLabel
@onready var resource_label: Label = %ResourceLabel
@onready var requirement_label: Label = %RequirementLabel
@onready var timeline_label: Label = %TimelineLabel
@onready var archive_label: Label = %ArchiveLabel
@onready var topic_a_button: Button = %TopicAButton
@onready var topic_b_button: Button = %TopicBButton
@onready var topic_a_body: RichTextLabel = %TopicABody
@onready var topic_b_body: RichTextLabel = %TopicBBody
@onready var topic_b_panel: PanelContainer = $Margin/Layout/Main/Research/Topics/TopicB
@onready var hand_container: HBoxContainer = %HandContainer
@onready var feedback_label: Label = %FeedbackLabel
@onready var phase_title: Label = %PhaseTitle
@onready var phase_body: Label = %PhaseBody
@onready var phase_actions: VBoxContainer = %PhaseActions
@onready var end_week_button: Button = %EndWeekButton


func _ready() -> void:
	session.state_changed.connect(_refresh)
	session.feedback_changed.connect(_on_feedback_changed)
	session.run_finished.connect(_on_run_finished)
	topic_a_button.pressed.connect(func() -> void: session.select_topic(0))
	topic_b_button.pressed.connect(func() -> void: session.select_topic(1))
	end_week_button.pressed.connect(session.advance_week)
	session.start_new_run(240731)


func start_with_topics(
	run_seed: int,
	topic_definitions: Array[DualTopicDefinition]
) -> void:
	session.start_new_run_with_topics(run_seed, topic_definitions)


func _refresh() -> void:
	var run: DualTopicRunModel = session.run_model
	week_label.text = "第 %d / 6 周  ·  Seed %d" % [run.week, run.seed]
	resource_label.text = "行动 %d/4    精力 %d/8    压力 %d/5" % [
		run.action_points,
		run.energy,
		run.pressure,
	]
	requirement_label.text = "公开要求 · %s" % _requirement_text(run.public_requirement)
	timeline_label.text = _timeline_text(run.week)
	archive_label.text = session.get_archive_summary()
	_refresh_topic(0, topic_a_button, topic_a_body)
	var has_second_topic: bool = run.topics.size() > 1
	topic_b_panel.visible = has_second_topic
	if has_second_topic:
		_refresh_topic(1, topic_b_button, topic_b_body)
	_refresh_hand()
	_refresh_phase_panel()


func _refresh_topic(
	index: int,
	select_button: Button,
	body: RichTextLabel
) -> void:
	var topic: DualTopicState = session.run_model.topics[index]
	var selected: bool = session.selected_topic_index == index
	select_button.text = "%s  %s" % [
		"◆" if selected else "◇",
		topic.definition.display_name,
	]
	select_button.disabled = topic.is_closed
	var potential_names: Array[String] = ["稳妥", "中等", "高潜力"]
	var lines: PackedStringArray = [
		"潜力：%s    证据：%d/5    完成：%d/5" % [
			potential_names[topic.potential],
			topic.evidence,
			topic.completion,
		],
		"承诺：%s" % _commitment_text(topic.commitment),
		"",
		"[b]风险档案[/b]",
	]
	if topic.risks.is_empty():
		lines.append("— 已无风险槽")
	for risk: DualTopicRiskState in topic.risks:
		lines.append(_risk_text(risk))
	body.text = "\n".join(lines)
	body.modulate = Color(0.55, 0.58, 0.60) if topic.is_closed else Color.WHITE


func _refresh_hand() -> void:
	for child: Node in hand_container.get_children():
		child.queue_free()
	for index: int in range(session.method_deck.hand.size()):
		var card: DualTopicMethodCardDefinition = session.method_deck.hand[index]
		var button: Button = CARD_BUTTON.new()
		button.setup(index, card)
		button.disabled = not session.can_play_actions() or session.run_model.final_resolved
		button.card_requested.connect(session.play_hand_card)
		hand_container.add_child(button)


func _refresh_phase_panel() -> void:
	for child: Node in phase_actions.get_children():
		child.queue_free()
	end_week_button.visible = false
	if session.run_model.final_resolved:
		_show_final_result(session.run_model.final_resolution)
	elif not session.pending_build_offer.is_empty():
		_show_build_offer()
	elif session.midterm_pending:
		_show_midterm()
	elif session.run_model.week == DualTopicRunModel.MAX_WEEKS:
		_show_submission()
	else:
		phase_title.text = "本周研究安排"
		phase_body.text = "%s\n选择课题 A/B，再使用方法牌。手牌不合适时可使用低效基础行动；基础行动不触发卡牌效果或专精。" % session.get_method_mastery_summary()
		_show_basic_actions()
		_show_portfolio_actions()
		end_week_button.visible = true
		end_week_button.disabled = false


func _show_basic_actions() -> void:
	var row := HBoxContainer.new()
	var organize := Button.new()
	organize.text = "整理现有材料（基础）"
	organize.tooltip_text = "消耗 1 行动和 1 精力；获得少量证据或完成度，不触发卡牌效果与专精。"
	organize.disabled = not session.can_play_basic_action(
		DualTopicRunModel.ActionType.ORGANIZE
	)
	organize.pressed.connect(
		session.play_basic_action.bind(DualTopicRunModel.ActionType.ORGANIZE)
	)
	row.add_child(organize)
	var recover := Button.new()
	recover.text = "喘口气（基础）"
	recover.tooltip_text = "消耗 1 行动，恢复精力或缓解压力。"
	recover.disabled = not session.can_play_basic_action(
		DualTopicRunModel.ActionType.RECOVER
	)
	recover.pressed.connect(
		session.play_basic_action.bind(DualTopicRunModel.ActionType.RECOVER)
	)
	row.add_child(recover)
	phase_actions.add_child(row)


func _show_portfolio_actions() -> void:
	if session.run_model.topics.size() != 2:
		return
	if session.run_model.portfolio_action_used:
		var used_label := Label.new()
		used_label.text = "本周课题组合调整已使用。"
		phase_actions.add_child(used_label)
		return
	var selected: int = session.selected_topic_index
	var other: int = 1 - selected
	if session.run_model.topics[other].is_closed:
		return
	var row := HBoxContainer.new()
	var freeze_button := Button.new()
	freeze_button.text = "冻结课题 %s（行动 -1）" % ("A" if other == 0 else "B")
	freeze_button.tooltip_text = "本周不能再投入该课题，并免除双课题注意力压力。"
	freeze_button.disabled = session.run_model.frozen_topic_indices.get(other, false)
	freeze_button.pressed.connect(session.freeze_topic_for_week.bind(other))
	row.add_child(freeze_button)
	var transfer_button := Button.new()
	transfer_button.text = "转移 %s → %s" % [
		"A" if other == 0 else "B",
		"A" if selected == 0 else "B",
	]
	transfer_button.tooltip_text = "副课题证据 -2，主课题完成度 +1，压力 +1。"
	transfer_button.disabled = session.run_model.topics[other].evidence < 2
	transfer_button.pressed.connect(
		session.transfer_topic_resources.bind(other, selected)
	)
	row.add_child(transfer_button)
	var archive_button := Button.new()
	archive_button.text = "止损归档 %s → %s" % [
		"A" if other == 0 else "B",
		"A" if selected == 0 else "B",
	]
	archive_button.tooltip_text = "中期承诺后关闭副课题，将已有成果与风险认知转给主课题。"
	archive_button.disabled = (
		not session.run_model.midterm_resolved
		or session.run_model.week >= DualTopicRunModel.MAX_WEEKS
	)
	archive_button.pressed.connect(
		session.archive_topic_early.bind(other, selected)
	)
	row.add_child(archive_button)
	phase_actions.add_child(row)


func _show_build_offer() -> void:
	phase_title.text = "方法构筑 · 三选一"
	phase_body.text = "加入副本提高抽取稳定性；替换旧牌会改变路线比例。本原型不扩充卡池。"
	for index: int in range(session.pending_build_offer.size()):
		var card: DualTopicMethodCardDefinition = session.pending_build_offer[index]
		var local_index: int = index
		var card_stack := VBoxContainer.new()
		var title := Label.new()
		title.text = "「%s」· %s" % [card.title, card.description]
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_stack.add_child(title)
		var row := HBoxContainer.new()
		var add_button := Button.new()
		add_button.text = "加入副本"
		add_button.pressed.connect(
			func() -> void: session.choose_build_card(local_index)
		)
		row.add_child(add_button)
		var replacement_picker := OptionButton.new()
		var seen_ids: Dictionary[StringName, bool] = {}
		for deck_card: DualTopicMethodCardDefinition in session.method_deck.deck_cards:
			if deck_card.id == card.id or seen_ids.has(deck_card.id):
				continue
			replacement_picker.add_item(deck_card.title)
			replacement_picker.set_item_metadata(
				replacement_picker.item_count - 1,
				deck_card.id
			)
			seen_ids[deck_card.id] = true
		replacement_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(replacement_picker)
		var replace_button := Button.new()
		replace_button.text = "替换"
		replace_button.disabled = replacement_picker.item_count == 0
		replace_button.pressed.connect(
			func() -> void:
				var replace_id: StringName = replacement_picker.get_item_metadata(
					replacement_picker.selected
				)
				session.choose_build_card(local_index, replace_id)
		)
		row.add_child(replace_button)
		card_stack.add_child(row)
		phase_actions.add_child(card_stack)


func _show_midterm() -> void:
	if session.run_model.topics.size() == 1:
		phase_title.text = "第 3 周 · 不可逆判断"
		phase_body.text = "决定当前课题后半周期的研究承诺；确认后不可撤销。"
		var only_picker := _create_commitment_picker("当前课题")
		phase_actions.add_child(only_picker)
		var single_confirm := Button.new()
		single_confirm.text = "写入项目档案"
		single_confirm.pressed.connect(
			func() -> void:
				session.resolve_single_topic_midterm(
					only_picker.get_item_id(only_picker.selected)
				)
		)
		phase_actions.add_child(single_confirm)
		return
	phase_title.text = "第 3 周 · 不可逆判断"
	phase_body.text = "分别决定两个课题的未来。至少保留一个课题；确认后不能撤销。"
	var first := _create_commitment_picker("课题 A")
	var second := _create_commitment_picker("课题 B")
	phase_actions.add_child(first)
	phase_actions.add_child(second)
	var confirm := Button.new()
	confirm.text = "写入项目档案"
	confirm.pressed.connect(
		func() -> void:
			session.resolve_midterm(
				first.get_item_id(first.selected),
				second.get_item_id(second.selected)
			)
	)
	phase_actions.add_child(confirm)


func _show_submission() -> void:
	phase_title.text = "第 6 周 · 投稿窗口"
	phase_body.text = "投稿读取已形成的证据、完成度、风险和公开要求，不再进行隐藏判定。"
	for index: int in range(session.run_model.topics.size()):
		if session.run_model.topics[index].is_closed:
			continue
		var local_index: int = index
		var preview: Dictionary = session.run_model.get_submission_preview(index)
		var preview_label := Label.new()
		preview_label.text = "课题 %s · %s" % [
			"A" if index == 0 else "B",
			_submission_preview_text(preview),
		]
		preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_label.modulate = (
			Color(0.45, 0.86, 0.72)
			if bool(preview.get("ready", false))
			else Color(1.0, 0.62, 0.38)
		)
		phase_actions.add_child(preview_label)
		var review_label := Label.new()
		review_label.text = _review_comments_text(
			preview.get("review_comments", [])
		)
		review_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		review_label.modulate = Color(0.78, 0.82, 0.84)
		phase_actions.add_child(review_label)
		if (
			not bool(preview.get("ready", false))
			and not session.run_model.review_revision_used
		):
			var revise := Button.new()
			revise.text = "按主要意见返修（行动 -1、精力 -1、压力 +1）"
			revise.disabled = (
				session.run_model.action_points <= 0
				or session.run_model.energy <= 0
			)
			revise.pressed.connect(
				func() -> void:
					session.apply_review_decision(&"revise", local_index)
			)
			phase_actions.add_child(revise)
		if not session.run_model.transferred_venue:
			var transfer := Button.new()
			transfer.text = "改投稳妥期刊（门槛降低、收益 -1、最高普通接收）"
			transfer.pressed.connect(
				func() -> void:
					session.apply_review_decision(&"transfer", local_index)
			)
			phase_actions.add_child(transfer)
		var submit := Button.new()
		submit.text = "%s课题 %s" % [
			"投稿" if bool(preview.get("ready", false)) else "仍要投稿",
			"A" if index == 0 else "B",
		]
		submit.pressed.connect(func() -> void: session.finish_run(&"submit", local_index))
		phase_actions.add_child(submit)
		var withdraw := Button.new()
		withdraw.text = "主动撤出课题 %s" % ("A" if index == 0 else "B")
		withdraw.pressed.connect(func() -> void: session.finish_run(&"withdraw", local_index))
		phase_actions.add_child(withdraw)


func _submission_preview_text(preview: Dictionary) -> String:
	if bool(preview.get("ready", false)):
		return "已满足投稿条件"
	var diagnosis: Dictionary = preview.get("diagnosis", {})
	match diagnosis.get("reason", &""):
		&"completion_insufficient":
			return "完成度 %d/%d" % [
				int(preview.get("completion", 0)),
				int(preview.get("required_completion", 4)),
			]
		&"evidence_insufficient":
			return "证据 %d/%d" % [
				int(preview.get("evidence", 0)),
				int(preview.get("required_evidence", 3)),
			]
		&"high_risk_unhandled":
			return "仍有高风险未处理"
		&"risk_control":
			return "风险受控 %d/%d（已验证不等于受控）" % [
				int(preview.get("controlled_risks", 0)),
				int(preview.get("risk_count", 0)),
			]
		&"reproducibility":
			return "已验证 %d，完成度 %d/4" % [
				int(preview.get("verified_risks", 0)),
				int(preview.get("completion", 0)),
			]
		&"evidence_integrity":
			return "公开要求需要证据 4/4，当前 %d/4" % int(preview.get("evidence", 0))
		_:
			return "当前投稿预计失败"


func _review_comments_text(raw_comments: Array) -> String:
	var lines: PackedStringArray = ["预审意见"]
	for raw_comment: Variant in raw_comments:
		var comment: Dictionary = raw_comment
		var prefix := "优势" if comment.get("severity", &"") == &"strength" else "问题"
		var trace_week := int(comment.get("trace_week", 0))
		var trace_text := (
			"（追溯：第 %d 周）" % trace_week
			if trace_week > 0
			else "（追溯：开局状态）"
		)
		lines.append("· %s：%s %s" % [
			prefix,
			String(comment.get("text", "")),
			trace_text,
		])
	return "\n".join(lines)


func _show_final_result(result: Dictionary) -> void:
	phase_title.text = _grade_text(result.get("grade", &"failed"))
	var diagnosis: Dictionary = result.get("diagnosis", {})
	var review_text := _review_comments_text(result.get("review_comments", []))
	var legacy: Dictionary = result.get("legacy", {})
	var tendency: Dictionary = result.get("build_tendency", {})
	var topic_index: int = int(result.get("topic_index", 0))
	var topic_name: String = session.run_model.topics[topic_index].definition.display_name
	phase_body.text = "课题：%s\n公开要求：%s\n主因：%s\n\n%s\n\n构筑倾向：%s\n%s\n\n带走：%s\n档案已更新：%s\n\n本局路线\n%s\n\n%s" % [
		topic_name,
		"满足" if result.get("requirement_met", false) else "未满足",
		_diagnosis_text(diagnosis),
		review_text,
		String(tendency.get("title", "尚未成形")),
		String(tendency.get("effect", "")),
		_legacy_text(legacy),
		session.get_archive_summary(),
		session.get_route_summary(),
		session.get_replay_challenge(result),
	]
	var restart := Button.new()
	restart.text = "相同 Seed 再来一局"
	restart.pressed.connect(session.restart_current_run)
	phase_actions.add_child(restart)


func _create_commitment_picker(label_text: String) -> OptionButton:
	var picker := OptionButton.new()
	picker.add_item("%s · 维持" % label_text, DualTopicState.Commitment.MAINTAIN)
	picker.add_item("%s · 加码" % label_text, DualTopicState.Commitment.DOUBLE_DOWN)
	picker.add_item("%s · 转向" % label_text, DualTopicState.Commitment.PIVOT)
	picker.add_item("%s · 拆分" % label_text, DualTopicState.Commitment.SPLIT)
	picker.add_item("%s · 止损" % label_text, DualTopicState.Commitment.STOPPED)
	return picker


func _risk_text(risk: DualTopicRiskState) -> String:
	if risk.knowledge_state == DualTopicRiskState.KnowledgeState.UNKNOWN:
		return "？ 未知风险"
	var tier_names: Array[String] = ["低", "中", "高"]
	var state_text: String = "已控制" if risk.is_controlled else (
		"已验证" if risk.knowledge_state == DualTopicRiskState.KnowledgeState.VERIFIED else "已识别"
	)
	return "%s · %s风险 · %s" % [
		risk.definition.display_name,
		tier_names[risk.tier],
		state_text,
	]


func _timeline_text(current_week: int) -> String:
	var segments: PackedStringArray = []
	for week: int in range(1, 7):
		segments.append("[%d]" % week if week == current_week else " %d " % week)
	return "六周时间线  " + " — ".join(segments)


func _requirement_text(requirement: StringName) -> String:
	match requirement:
		&"evidence_integrity":
			return "证据完整：证据至少 4"
		&"risk_control":
			return "风险控制：所有风险必须受控"
		&"reproducibility":
			return "可复现：完成度至少 4，且至少验证一个风险"
		_:
			return String(requirement)


func _commitment_text(commitment: DualTopicState.Commitment) -> String:
	var names: Array[String] = ["未决定", "维持", "加码", "转向", "拆分", "已止损"]
	return names[commitment]


func _grade_text(grade: StringName) -> String:
	match grade:
		&"excellent":
			return "优秀通过"
		&"pass":
			return "普通通过"
		&"withdrawn":
			return "主动撤出"
		_:
			return "投稿失败"


func _diagnosis_text(diagnosis: Dictionary) -> String:
	match diagnosis.get("reason", &""):
		&"completion_insufficient":
			return "研究表达尚未完成（%d/4）" % int(diagnosis.get("current", 0))
		&"evidence_insufficient":
			return "证据不足（%d/3）" % int(diagnosis.get("current", 0))
		&"high_risk_unhandled":
			return "仍有高风险未处理"
		&"evidence_integrity":
			return "未达到公开要求：证据完整"
		&"risk_control":
			return "未达到公开要求：风险控制"
		&"reproducibility":
			return "未达到公开要求：可复现性"
		_:
			return "无额外断点"


func _legacy_text(legacy: Dictionary) -> String:
	match legacy.get("type", &""):
		&"mature_method":
			return "成熟方法 · %s" % legacy.get("method_id", &"研究习惯")
		&"risk_insight":
			return "风险认知 · %s" % legacy.get("risk_id", &"未知风险模式")
		&"remediation_method":
			return "补救方法 · %s" % _remediation_text(legacy.get("method_id", &""))
		_:
			return "无"


func _remediation_text(method_id: StringName) -> String:
	match method_id:
		&"theory_repair":
			return "理论补强"
		&"evidence_repair":
			return "证据修复"
		&"writing_repair":
			return "表达整理"
		_:
			return "风险控制"


func _on_feedback_changed(message: String, is_error: bool) -> void:
	feedback_label.text = message
	feedback_label.modulate = Color(1.0, 0.52, 0.42) if is_error else Color(0.45, 0.86, 0.72)


func _on_run_finished(_result: Dictionary) -> void:
	_refresh()
