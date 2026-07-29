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

@export var run_seed: int = 240731
@export_range(0, 3, 1) var growth_rank: int = 1

@onready var seed_label: Label = %SeedLabel
@onready var header: Control = $Margin/Layout/Header
@onready var instruction_label: Label = %InstructionLabel
@onready var window_label: Label = %WindowLabel
@onready var year_summary_label: Label = %YearSummaryLabel
@onready var candidate_grid: GridContainer = %CandidateGrid
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


func _ready() -> void:
	archive_button.pressed.connect(_on_primary_button_pressed)
	year_session = ACADEMIC_YEAR_SESSION.new() as AcademicYearSession
	add_child(year_session)
	year_session.start_academic_year(run_seed)
	_apply_current_cycle_context()
	_start_candidate_round()


func _start_candidate_round() -> void:
	cycle_host.visible = false
	choice_area.visible = true
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
	var candidates: Array[ResearchTopicCandidate] = generator.generate_candidates()
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


func _refresh_candidate_cards() -> void:
	for child: Node in candidate_grid.get_children():
		child.queue_free()
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
	_apply_current_cycle_context()
	instruction_label.text = "上一周期成果已进入档案。请选择下一投稿窗口的研究课题。"
	_start_candidate_round()


func _apply_current_cycle_context() -> void:
	_apply_cycle_context(year_session.get_current_cycle_context())


func _apply_cycle_context(context: Dictionary) -> void:
	if context.is_empty():
		return
	run_seed = int(context.get("seed", run_seed))
	window_label.text = "第 %d / %d 周期 · %s" % [
		int(context.get("cycle", 1)),
		int(context.get("cycle_count", 3)),
		String(context.get("window_name", "研究窗口")),
	]
	year_summary_label.text = (
		"%s  ·  投稿门槛：证据 %d / 完成度 %d  ·  起始压力 %d\n"
		+ "学年档案：已接收 %d 篇 · 声望 %d%s"
	) % [
		String(context.get("window_description", "")),
		int(context.get("minimum_evidence", 0)),
		int(context.get("minimum_completion", 0)),
		int(context.get("starting_pressure", 0)),
		int(context.get("accepted_papers", 0)),
		int(context.get("prestige", 0)),
		_legacy_context_text(Dictionary(context.get("legacy", {}))),
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


func _show_year_ending(ending: Dictionary) -> void:
	year_finished = true
	for child: Node in candidate_grid.get_children():
		child.queue_free()
	window_label.text = "学年结算"
	year_summary_label.text = (
		"%s\n%s · %s\n"
		+ "已接收 %d 篇 · 优秀 %d 篇 · 失败 %d 次 · 主动撤回 %d 次\n"
		+ "年度声望 %d · 结余压力 %d\n\n%s"
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
	if portfolio.active_topics.size() < 2:
		return "可以直接开始单课题路线，也可以再选一个课题。"
	var first: ResearchTopicCandidate = portfolio.active_topics[0]
	var second: ResearchTopicCandidate = portfolio.active_topics[1]
	var shared := PackedStringArray()
	for tag: String in first.archetype.tags:
		if second.archetype.tags.has(tag):
			shared.append(tag)
	if shared.is_empty():
		return "组合冲突：两个课题无共享标签，每周压力 +1。"
	return "组合协同：共享“%s”；每周首次产出证据时，另一课题证据 +1。" % "、".join(shared)


func _candidate_card_text(candidate: ResearchTopicCandidate) -> String:
	var tier_names: Array[String] = ["常规", "进阶", "前沿", "禁区"]
	var potential_names: Array[String] = ["普通", "进阶", "前沿", "突破"]
	var tags := "、".join(candidate.archetype.tags)
	return (
		"%s\n\n%s\n\n难度：%s    潜力：%s\n"
		+ "风险槽：%d    窗口：%d 周\n预期收益：%d\n标签：%s\n\n%s"
	) % [
		candidate.archetype.display_name,
		candidate.archetype.premise,
		tier_names[candidate.archetype.difficulty_tier],
		potential_names[candidate.potential],
		candidate.risks.size(),
		candidate.deadline_weeks,
		candidate.reward,
		tags,
		_special_rule_text(candidate.special_rule),
	]


func _special_rule_text(rule_id: StringName) -> String:
	match rule_id:
		&"reproduction_bonus":
			return "特性：首次正常复现额外获得证据。"
		&"negative_result_asset":
			return "特性：首次异常或失败也能转化为证据。"
		&"scarce_data":
			return "特性：调查本身会产生证据。"
		&"cross_domain":
			return "特性：中期转向时保留完成度。"
		&"pipeline_engine":
			return "特性：前期实验更耗精力，后期吞吐更高。"
		&"multi_source":
			return "特性：正常结果收益更高，异常冲突增加压力。"
		&"indivisible_hypothesis":
			return "特性：高收益，但不能安全拆分。"
		&"deployment_exposure":
			return "特性：未调查风险会在周末增加压力。"
		_:
			return "特性：标准研究流程。"
