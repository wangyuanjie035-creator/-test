extends Control
class_name DynamicTopicEntry

const CATALOG: ResearchTopicCatalog = preload(
	"res://data/topic_pool/starter_topic_catalog.tres"
)
const CYCLE_SCENE: PackedScene = preload(
	"res://scenes/dual_topic/dual_topic_prototype.tscn"
)
const CYCLE_ADAPTER := preload(
	"res://scripts/topic_pool/model/research_topic_cycle_adapter.gd"
)
const ACADEMIC_YEAR_SESSION := preload(
	"res://scripts/academic_year/run/academic_year_session.gd"
)
const CANDIDATE_PRESENTER := preload(
	"res://scripts/topic_pool/ui/research_topic_candidate_presenter.gd"
)
const ROUTE_PRESENTER := preload(
	"res://scripts/topic_pool/ui/research_portfolio_route_presenter.gd"
)
const OPPORTUNITY_EFFECT_ADAPTER := preload(
	"res://scripts/academic_year/model/academic_opportunity_effect_adapter.gd"
)

@export var run_seed: int = 240731
@export_range(0, 3, 1) var growth_rank: int = 0
@export var show_information_calibration: bool = true

@onready var seed_label: Label = %SeedLabel
@onready var header: Control = $Margin/Layout/Header
@onready var instruction_label: Label = %InstructionLabel
@onready var window_label: Label = %WindowLabel
@onready var year_summary_label: Label = %YearSummaryLabel
@onready var calibration_row: HBoxContainer = %CalibrationRow
@onready var information_level_option: OptionButton = %InformationLevelOption
@onready var candidate_scroll: ScrollContainer = %CandidateScroll
@onready var candidate_grid: GridContainer = %CandidateGrid
@onready var opportunity_panel: PanelContainer = %OpportunityPanel
@onready var opportunity_title: Label = %OpportunityTitle
@onready var opportunity_description: Label = %OpportunityDescription
@onready var opportunity_choice_row: HBoxContainer = %OpportunityChoiceRow
@onready var opportunity_choice_buttons: Array[Button] = [
	%OpportunityChoiceA,
	%OpportunityChoiceB,
]
@onready var reject_opportunity_button: Button = %RejectOpportunityButton
@onready var choice_area: Control = %ChoiceArea
@onready var cycle_host: Control = %CycleHost
@onready var archive_button: Button = %ArchiveButton

var portfolio: ResearchPortfolioModel
var year_session: AcademicYearSession
var current_cycle: Control
var current_candidate_id: StringName = &""
var pending_cycle_assets: Array[Dictionary] = []
var last_cycle_result: Dictionary = {}
var current_route_id: StringName = &"single"
var year_finished: bool = false
var pending_opportunity_choices: Array[Dictionary] = []
var candidate_information_level: ResearchTopicCandidatePresenter.InformationLevel = (
	ResearchTopicCandidatePresenter.InformationLevel.GUIDED
)


func _ready() -> void:
	archive_button.pressed.connect(_on_primary_button_pressed)
	for index: int in range(opportunity_choice_buttons.size()):
		opportunity_choice_buttons[index].pressed.connect(
			_resolve_opportunity_index.bind(index)
		)
	reject_opportunity_button.pressed.connect(_resolve_opportunity_choice.bind(&""))
	_setup_information_calibration()
	year_session = ACADEMIC_YEAR_SESSION.new() as AcademicYearSession
	add_child(year_session)
	year_session.start_academic_year(run_seed)
	_apply_current_cycle_context()
	_start_candidate_round()


func _setup_information_calibration() -> void:
	calibration_row.visible = show_information_calibration
	information_level_option.clear()
	information_level_option.add_item(
		"遮蔽",
		ResearchTopicCandidatePresenter.InformationLevel.VEILED
	)
	information_level_option.add_item(
		"平衡",
		ResearchTopicCandidatePresenter.InformationLevel.BALANCED
	)
	information_level_option.add_item(
		"引导（正式默认）",
		ResearchTopicCandidatePresenter.InformationLevel.GUIDED
	)
	information_level_option.select(2)
	information_level_option.item_selected.connect(_on_information_level_selected)


func _on_information_level_selected(index: int) -> void:
	candidate_information_level = information_level_option.get_item_id(index)
	if portfolio != null:
		_refresh_candidate_cards()


func _start_candidate_round() -> void:
	cycle_host.visible = false
	choice_area.visible = true
	opportunity_panel.visible = false
	calibration_row.visible = show_information_calibration
	candidate_scroll.visible = true
	if year_session != null and year_session.phase == AcademicYearSession.Phase.ARCHIVE_DESK:
		var begun: Dictionary = year_session.begin_current_cycle()
		if not bool(begun.get("success", false)):
			instruction_label.text = "无法开启新的研究周期。"
			return
		_apply_cycle_context(Dictionary(begun.get("context", {})))
	var generator := ResearchTopicGenerator.new()
	var typed_archetypes: Array[ResearchTopicArchetype] = []
	typed_archetypes.assign(CATALOG.archetypes)
	if not generator.setup(run_seed, growth_rank, typed_archetypes):
		instruction_label.text = "候选课题生成失败。"
		return
	generator.configure_context(_get_generation_context_tags())
	var candidates: Array[ResearchTopicCandidate] = generator.generate_candidates()
	if candidates.size() < ResearchTopicGenerator.MIN_CANDIDATES:
		instruction_label.text = "当前能力与方法无法形成合法课题组合。%s" % (
			"；".join(generator.generation_diagnostics)
		)
		return
	var capacity := 2 if growth_rank >= 1 else 1
	portfolio = ResearchPortfolioModel.new()
	portfolio.setup(candidates, capacity)
	seed_label.text = "Seed %d · 研究能力 %d · 课题槽位 %d" % [
		run_seed,
		growth_rank,
		capacity,
	]
	instruction_label.text = (
		"选择 1–%d 个课题。双课题共享行动与精力；"
		+ "有共享标签时形成协同，否则每周增加压力。"
	) % capacity
	archive_button.visible = false
	last_cycle_result.clear()
	_refresh_candidate_cards()


func _get_generation_context_tags() -> PackedStringArray:
	var tags := PackedStringArray()
	if growth_rank >= 2:
		tags.append("advanced_equipment")
	return tags


func _refresh_candidate_cards() -> void:
	for child: Node in candidate_grid.get_children():
		child.queue_free()
	for candidate: ResearchTopicCandidate in portfolio.active_topics:
		var selected_card := Button.new()
		selected_card.custom_minimum_size = Vector2(320.0, 250.0)
		selected_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selected_card.focus_mode = Control.FOCUS_ALL
		selected_card.text = "✓ 已立项｜点击撤回选择\n%s" % _candidate_card_text(candidate)
		selected_card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		selected_card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		selected_card.pressed.connect(_deselect_candidate.bind(candidate.candidate_id))
		candidate_grid.add_child(selected_card)
	for candidate: ResearchTopicCandidate in portfolio.candidates:
		var card := Button.new()
		card.custom_minimum_size = Vector2(320.0, 250.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_ALL
		card.text = _candidate_card_text(candidate)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.pressed.connect(_select_candidate.bind(candidate.candidate_id))
		candidate_grid.add_child(card)
	if candidate_grid.get_child_count() > 0:
		var first_card := candidate_grid.get_child(0) as Button
		first_card.grab_focus()


func _select_candidate(candidate_id: StringName) -> void:
	var selection: Dictionary = portfolio.select_candidate(candidate_id)
	if not bool(selection.get("success", false)):
		instruction_label.text = "无法立项：%s" % selection.get("reason", &"unknown")
		return
	current_candidate_id = portfolio.active_topics[0].candidate_id
	instruction_label.text = "已选 %d/%d 个课题。%s" % [
		portfolio.active_topics.size(),
		portfolio.slot_capacity,
		_selection_relation_text(),
	]
	archive_button.text = "开始研究周期（%d 个课题）" % portfolio.active_topics.size()
	archive_button.visible = true
	_refresh_candidate_cards()
	archive_button.grab_focus()


func _deselect_candidate(candidate_id: StringName) -> void:
	var selection: Dictionary = portfolio.deselect_candidate(candidate_id)
	if not bool(selection.get("success", false)):
		instruction_label.text = "无法撤回立项选择：%s" % selection.get("reason", &"unknown")
		return
	if portfolio.active_topics.is_empty():
		current_candidate_id = &""
		instruction_label.text = "尚未立项。请选择一个课题，再比较是否开启第二课题。"
		archive_button.visible = false
	else:
		current_candidate_id = portfolio.active_topics[0].candidate_id
		instruction_label.text = "已选 %d/%d 个课题。%s" % [
			portfolio.active_topics.size(),
			portfolio.slot_capacity,
			_selection_relation_text(),
		]
		archive_button.text = "开始研究周期（%d 个课题）" % portfolio.active_topics.size()
		archive_button.visible = true
	_refresh_candidate_cards()


func _begin_selected_cycle() -> void:
	if portfolio == null or portfolio.active_topics.is_empty():
		return
	var definitions: Array[DualTopicDefinition] = []
	current_route_id = _get_selected_route_id()
	for candidate: ResearchTopicCandidate in portfolio.active_topics:
		var cycle_definition: DualTopicDefinition = CYCLE_ADAPTER.create_definition(candidate)
		if cycle_definition == null:
			instruction_label.text = "无法把候选课题写入研究周期。"
			return
		definitions.append(cycle_definition)
	choice_area.visible = false
	header.visible = false
	cycle_host.visible = true
	archive_button.visible = false
	current_cycle = CYCLE_SCENE.instantiate() as Control
	cycle_host.add_child(current_cycle)
	current_cycle.start_with_topics(run_seed, definitions)
	var cycle_session := current_cycle.get_node("Session") as DualTopicSession
	cycle_session.run_finished.connect(_on_cycle_finished)
	var cycle_context: Dictionary = year_session.get_current_cycle_context()
	cycle_session.run_model.pressure = int(cycle_context.get("starting_pressure", 0))
	cycle_session.run_model.configure_submission_window(
		int(cycle_context.get("minimum_evidence", 3)),
		int(cycle_context.get("minimum_completion", 4))
	)
	cycle_session.run_model.enable_simplified_submission()
	var opportunity_modifier: Dictionary = (
		OPPORTUNITY_EFFECT_ADAPTER.to_opening_modifier(
			Dictionary(cycle_context.get("opportunity_decision", {}))
		)
	)
	if not opportunity_modifier.is_empty():
		var opportunity_result: Dictionary = cycle_session.apply_academic_opening(
			opportunity_modifier
		)
	cycle_session.state_changed.emit()
	if not pending_cycle_assets.is_empty():
		var carryover_result: Dictionary = cycle_session.apply_cycle_carryover(
			pending_cycle_assets
		)
		if bool(carryover_result.get("success", false)):
			pending_cycle_assets.clear()


func _on_cycle_finished(result: Dictionary) -> void:
	last_cycle_result = result.duplicate(true)
	pending_cycle_assets = _extract_cycle_assets(result)
	var cycle_session := current_cycle.get_node("Session") as DualTopicSession
	var academic_result: Dictionary = year_session.complete_current_cycle(
		_to_academic_result(result),
		cycle_session.run_model.pressure
	)
	if not bool(academic_result.get("success", false)):
		instruction_label.text = "周期归档失败：%s" % academic_result.get("reason", &"unknown")
		return
	var active_ids: Array[StringName] = []
	for candidate: ResearchTopicCandidate in portfolio.active_topics:
		active_ids.append(candidate.candidate_id)
	for candidate_id: StringName in active_ids:
		portfolio.archive_active_topic(candidate_id, result)
	archive_button.text = "查看研究档案 · 进入下一阶段"
	archive_button.visible = true
	archive_button.grab_focus()


func _extract_cycle_assets(result: Dictionary) -> Array[Dictionary]:
	var extracted: Array[Dictionary] = []
	var raw_assets: Array = result.get("run_assets", [])
	for raw_asset: Variant in raw_assets:
		if raw_asset is Dictionary and raw_asset.get("type", &"") == &"early_archive":
			extracted.append((raw_asset as Dictionary).duplicate(true))
	return extracted


func _on_primary_button_pressed() -> void:
	if year_finished:
		_start_next_academic_year()
		return
	if is_instance_valid(current_cycle):
		_return_to_archive()
	else:
		_begin_selected_cycle()


func _return_to_archive() -> void:
	if is_instance_valid(current_cycle):
		current_cycle.queue_free()
	current_cycle = null
	current_candidate_id = &""
	cycle_host.visible = false
	choice_area.visible = true
	header.visible = true
	var transition: Dictionary = year_session.continue_from_archive()
	if not bool(transition.get("success", false)):
		instruction_label.text = "无法推进学年：%s" % transition.get("reason", &"unknown")
		return
	if bool(transition.get("year_finished", false)):
		_show_year_ending(Dictionary(transition.get("ending", {})))
		return
	if bool(transition.get("opportunity_pending", false)):
		var opportunities: Array[Dictionary] = []
		opportunities.assign(transition.get("opportunities", []))
		_show_opportunities(opportunities)
		return
	_apply_current_cycle_context()
	instruction_label.text = "上一周期成果已进入档案。请选择下一投稿窗口的研究课题。"
	_start_candidate_round()


func _show_opportunities(opportunities: Array[Dictionary]) -> void:
	pending_opportunity_choices = opportunities.duplicate(true)
	opportunity_panel.visible = true
	calibration_row.visible = false
	candidate_scroll.visible = false
	archive_button.visible = false
	window_label.text = "周期机会竞争 · 只能选择一项"
	opportunity_title.text = "比较机会，或保守休整"
	opportunity_description.text = "选择后其他邀请立即失效；所有压力成本与开局收益均已公开。"
	opportunity_choice_row.visible = not opportunities.is_empty()
	for index: int in range(opportunity_choice_buttons.size()):
		var button: Button = opportunity_choice_buttons[index]
		button.visible = index < opportunities.size()
		if button.visible:
			button.text = _format_opportunity_choice(opportunities[index])
	instruction_label.text = "不要只看收益：更高压力会压缩下一周期的容错空间。"
	if not opportunities.is_empty():
		opportunity_choice_buttons[0].grab_focus()
	else:
		reject_opportunity_button.grab_focus()


func _resolve_opportunity_index(index: int) -> void:
	if index < 0 or index >= pending_opportunity_choices.size():
		return
	_resolve_opportunity_choice(
		StringName(pending_opportunity_choices[index].get("id", &""))
	)


func _resolve_opportunity_choice(selected_id: StringName) -> void:
	var result: Dictionary = year_session.resolve_opportunity_choice(selected_id)
	if not bool(result.get("success", false)):
		instruction_label.text = "无法处理周期机会：%s" % result.get("reason", &"unknown")
		return
	var decision: Dictionary = result.get("decision", {})
	_apply_cycle_context(Dictionary(result.get("context", {})))
	if bool(decision.get("accepted", false)):
		instruction_label.text = "已选择机会：下一周期压力 +%d。其余邀请已经关闭。" % [
			int(decision.get("pressure_cost", 0)),
		]
	else:
		instruction_label.text = "本阶段选择休整：不增加下一周期压力。"
	_start_candidate_round()


func _format_opportunity_choice(opportunity: Dictionary) -> String:
	return "%s\n\n代价：下一周期压力 +%d\n收益：%s\n\n%s" % [
		String(opportunity.get("display_name", "学术机会")),
		int(opportunity.get("pressure_cost", 0)),
		String(opportunity.get("public_effect_text", "")),
		String(opportunity.get("description", "")),
	]


func _apply_current_cycle_context() -> void:
	_apply_cycle_context(year_session.get_current_cycle_context())


func _apply_cycle_context(context: Dictionary) -> void:
	if context.is_empty():
		return
	run_seed = int(context.get("seed", run_seed))
	growth_rank = maxi(growth_rank, int(context.get("growth_rank", 0)))
	window_label.text = "第 %d / %d 周期 · %s" % [
		int(context.get("cycle", 1)),
		int(context.get("cycle_count", 3)),
		String(context.get("window_name", "研究窗口")),
	]
	year_summary_label.text = (
		"%s  ·  投稿门槛：证据 %d / 完成度 %d  ·  起始压力 %d\n"
		+ "学年档案：已接收 %d 篇 · 声望 %d%s%s"
	) % [
		String(context.get("window_description", "")),
		int(context.get("minimum_evidence", 0)),
		int(context.get("minimum_completion", 0)),
		int(context.get("starting_pressure", 0)),
		int(context.get("accepted_papers", 0)),
		int(context.get("prestige", 0)),
		_legacy_context_text(Dictionary(context.get("legacy", {}))),
		_destination_context_text(
			Dictionary(context.get("destination_profile", {}))
		),
	]


func _to_academic_result(result: Dictionary) -> Dictionary:
	return {
		"success": true,
		"grade": StringName(result.get("grade", &"failed")),
		"route_id": current_route_id,
		"legacy": Dictionary(result.get("legacy", {})).duplicate(true),
	}


func _legacy_context_text(legacy: Dictionary) -> String:
	if legacy.is_empty():
		return ""
	match StringName(legacy.get("type", &"")):
		&"mature_method":
			return "\n上周期带入：成熟方法加入本周期牌组"
		&"risk_insight":
			return "\n上周期带入：风险认知会预先揭示一项风险"
		&"remediation_method":
			return "\n上周期带入：失败补救会强化本周期开局"
		_:
			return "\n上周期带入：研究档案将在本周期兑现"


func _destination_context_text(profile: Dictionary) -> String:
	if profile.is_empty() or StringName(profile.get("id", &"unformed")) == &"unformed":
		return ""
	return "\n机会轨迹：%s · %s" % [
		String(profile.get("title", "尚未形成")),
		String(profile.get("summary", "")),
	]


func _show_year_ending(ending: Dictionary) -> void:
	year_finished = true
	for child: Node in candidate_grid.get_children():
		child.queue_free()
	window_label.text = "学年结算"
	var destination_profile: Dictionary = ending.get("destination_profile", {})
	year_summary_label.text = (
		"%s\n%s · %s\n"
		+ "已接收 %d 篇 · 优秀 %d 篇 · 失败 %d 次 · 主动撤回 %d 次\n"
		+ "年度声望 %d · 结余压力 %d\n"
		+ "机会轨迹：%s · %s\n\n%s"
	) % [
		String(ending.get("title", "一学年结束")),
		String(ending.get("route_title", "研究路线")),
		String(ending.get("route_summary", "")),
		int(ending.get("accepted_papers", 0)),
		int(ending.get("excellent_papers", 0)),
		int(ending.get("failed_submissions", 0)),
		int(ending.get("withdrawals", 0)),
		int(ending.get("prestige", 0)),
		int(ending.get("ending_pressure", 0)),
		String(destination_profile.get("title", "尚未形成机会轨迹")),
		String(destination_profile.get("summary", "")),
		_year_history_text(Array(ending.get("history", []))),
	]
	instruction_label.text = "三个研究周期已经归档。你的选择共同形成了这一学年的研究路线。"
	archive_button.text = "带着研究遗产 · 开始下一学年"
	archive_button.visible = true
	archive_button.grab_focus()


func _start_next_academic_year() -> void:
	year_finished = false
	run_seed = year_session.year_model.seed + 99_991
	pending_cycle_assets.clear()
	last_cycle_result.clear()
	year_session.start_academic_year(run_seed)
	_apply_current_cycle_context()
	instruction_label.text = "新学年开始。上一学年形成的研究遗产仍会在首个周期兑现。"
	_start_candidate_round()


func _get_selected_route_id() -> StringName:
	if portfolio == null or portfolio.active_topics.size() < 2:
		return &"single"
	var first: ResearchTopicCandidate = portfolio.active_topics[0]
	var second: ResearchTopicCandidate = portfolio.active_topics[1]
	for tag: String in first.archetype.tags:
		if second.archetype.tags.has(tag):
			return &"synergy"
	return &"conflict"


func _year_history_text(history: Array) -> String:
	var lines: PackedStringArray = []
	for raw_record: Variant in history:
		if not raw_record is Dictionary:
			continue
		var record: Dictionary = raw_record
		lines.append(
			"%s · %s · %s · 声望 +%d · 压力 %d→%d" % [
				String(record.get("window_name", "研究窗口")),
				_grade_text(StringName(record.get("grade", &"failed"))),
				_route_text(StringName(record.get("route_id", &"single"))),
				int(record.get("prestige_gained", 0)),
				int(record.get("ending_pressure", 0)),
				int(record.get("next_pressure", 0)),
			]
		)
	return "\n".join(lines)


func _grade_text(grade: StringName) -> String:
	match grade:
		&"excellent":
			return "优秀接收"
		&"pass":
			return "接收"
		&"withdrawn":
			return "主动撤回"
		_:
			return "投稿失败"


func _route_text(route_id: StringName) -> String:
	match route_id:
		&"synergy":
			return "协同双课题"
		&"conflict":
			return "冲突双课题"
		_:
			return "专注单课题"


func _selection_relation_text() -> String:
	return ROUTE_PRESENTER.format_route_profile(portfolio.active_topics)


func _candidate_card_text(candidate: ResearchTopicCandidate) -> String:
	return CANDIDATE_PRESENTER.format_candidate_card(
		candidate,
		candidate_information_level
	)
