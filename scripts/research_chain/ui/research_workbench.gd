class_name ResearchWorkbench
extends Control

const CONTROLLER := preload("res://scripts/research_chain/run/research_run_controller.gd")
const CARD_BUTTON := preload("res://scripts/research_chain/ui/research_card_button.gd")

var _controller: ResearchRunController
var _top_label: Label
var _encounter_label: Label
var _preview_label: Label
var _hand_box: HBoxContainer
var _chain_box: HBoxContainer
var _submit_button: Button
var _skip_button: Button
var _overlay: PanelContainer
var _result_label: Label
var _last_seed: int = 1

func _ready() -> void:
	_build_interface()
	_controller = CONTROLLER.new()
	add_child(_controller)
	_controller.state_changed.connect(_refresh)
	_controller.run_finished.connect(_show_result)
	_show_archetype_choice()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = Color("15201d")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var root_box: VBoxContainer = VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 12)
	margin.add_child(root_box)
	_top_label = Label.new()
	_top_label.add_theme_font_size_override("font_size", 22)
	root_box.add_child(_top_label)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root_box.add_child(body)
	var workspace: VBoxContainer = VBoxContainer.new()
	workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(workspace)
	var chain_title: Label = Label.new()
	chain_title.text = "科研链工作台 · 点击卡牌加入，点击链中卡牌撤回"
	chain_title.add_theme_font_size_override("font_size", 18)
	workspace.add_child(chain_title)
	_chain_box = HBoxContainer.new()
	_chain_box.custom_minimum_size = Vector2(0, 142)
	_chain_box.add_theme_constant_override("separation", 8)
	workspace.add_child(_chain_box)
	var hand_title: Label = Label.new()
	hand_title.text = "本回合手牌"
	hand_title.add_theme_font_size_override("font_size", 18)
	workspace.add_child(hand_title)
	var hand_scroll: ScrollContainer = ScrollContainer.new()
	hand_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_child(hand_scroll)
	_hand_box = HBoxContainer.new()
	_hand_box.add_theme_constant_override("separation", 8)
	hand_scroll.add_child(_hand_box)
	var sidebar: PanelContainer = PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(310, 0)
	body.add_child(sidebar)
	var sidebar_box: VBoxContainer = VBoxContainer.new()
	sidebar_box.add_theme_constant_override("separation", 12)
	sidebar.add_child(sidebar_box)
	_encounter_label = Label.new()
	_encounter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_encounter_label.add_theme_font_size_override("font_size", 18)
	sidebar_box.add_child(_encounter_label)
	_preview_label = Label.new()
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_box.add_child(_preview_label)
	_submit_button = Button.new()
	_submit_button.text = "提交科研链"
	_submit_button.custom_minimum_size = Vector2(0, 54)
	_submit_button.pressed.connect(_on_submit)
	sidebar_box.add_child(_submit_button)
	_skip_button = Button.new()
	_skip_button.text = "放弃本回合（可信度 -1）"
	_skip_button.disabled = true
	_skip_button.pressed.connect(_on_skip)
	sidebar_box.add_child(_skip_button)
	_overlay = PanelContainer.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_overlay.custom_minimum_size = Vector2(560, 330)
	add_child(_overlay)

func _show_archetype_choice() -> void:
	_clear_children(_overlay)
	_overlay.visible = true
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	_overlay.add_child(box)
	var title: Label = Label.new()
	title.text = "选择本次研究路线"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	_add_choice_button(box, "复现研究 · 稳定积累可信度", &"replication")
	_add_choice_button(box, "阴性结果 · 把失败转化为成果", &"negative")
	_add_choice_button(box, "祖传代码 · 自动化爆发与技术债", &"legacy")
	var first_button: Button = box.get_child(1) as Button
	first_button.grab_focus()

func _add_choice_button(parent: VBoxContainer, title: String, archetype: StringName) -> void:
	var button: Button = Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(0, 58)
	button.pressed.connect(_start_run.bind(archetype, false))
	parent.add_child(button)

func _start_run(archetype: StringName, same_seed: bool) -> void:
	_overlay.visible = false
	_skip_button.disabled = false
	if not same_seed:
		_last_seed = int(Time.get_unix_time_from_system()) % 2147483646 + 1
	_controller.start_run(archetype, _last_seed)

func _refresh(state: Dictionary) -> void:
	var encounter: ResearchEncounterDefinition = state.encounter
	_top_label.text = "%s　回合 %d/%d　精力 %d/10　可信度 %d/10　技术债 %d/10　阴性结果 %d　论文 %d/%d" % [encounter.display_name, state.turn, encounter.turn_limit, state.energy, state.credibility, state.technical_debt, state.negative_result, state.score, encounter.target_score]
	_encounter_label.text = "%s\n\n目标：在截止前累计 %d 分\nSeed：%d\n抽牌堆 %d · 弃牌堆 %d" % [encounter.display_name, encounter.target_score, state.seed, state.draw_count, state.discard_count]
	_clear_children(_hand_box)
	for index: int in range(state.hand.size()):
		var hand_button: ResearchCardButton = CARD_BUTTON.new()
		hand_button.setup(state.hand[index])
		hand_button.pressed.connect(_controller.add_to_chain.bind(index))
		_hand_box.add_child(hand_button)
	_clear_children(_chain_box)
	for index: int in range(state.chain.size()):
		var chain_button: ResearchCardButton = CARD_BUTTON.new()
		chain_button.setup(state.chain[index])
		chain_button.pressed.connect(_controller.remove_from_chain.bind(index))
		_chain_box.add_child(chain_button)
	var preview: Dictionary = state.preview
	_submit_button.disabled = not bool(preview.get("valid", false))
	if bool(preview.get("valid", false)):
		var requirement_line: String = ""
		if encounter.is_boss:
			requirement_line = "\n审稿要求：%s\n状态：%s\n" % [preview.requirement_text, "满足（+5 分）" if preview.requirement_met else "未满足（可信度 -1）"]
		_preview_label.text = "本次预览\n%s\n基础分：%d\n连接分：%d\n流派/要求分：%d\n可信度倍率：×%.2f\n遭遇倍率：×%.2f\n\n预计获得：%d 分\n\n结算后变化\n精力 %+d　可信度 %+d\n技术债 %+d　阴性结果 %+d" % [requirement_line, preview.base_score, preview.connection_score, preview.archetype_score, preview.credibility_multiplier, preview.encounter_multiplier, preview.final_score, preview.energy_delta, preview.credibility_delta, preview.debt_delta, preview.negative_delta]
	else:
		_preview_label.text = "本次预览\n\n%s\n\n科研阶段必须保持：\n文献 → 假设 → 实验 → 数据 → 分析 → 论文" % preview.get("reason", "请选择卡牌")

func _show_result(won: bool, reason: String) -> void:
	_submit_button.disabled = true
	_skip_button.disabled = true
	_clear_children(_overlay)
	_overlay.visible = true
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	_overlay.add_child(box)
	_result_label = Label.new()
	_result_label.text = ("研究完成" if won else "本次研究结束") + "\n\n" + reason
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 24)
	box.add_child(_result_label)
	var retry_same: Button = Button.new()
	retry_same.text = "相同 Seed 重试"
	retry_same.pressed.connect(_start_run.bind(_controller.archetype, true))
	box.add_child(retry_same)
	var new_run: Button = Button.new()
	new_run.text = "再来一局（新 Seed）"
	new_run.pressed.connect(_start_run.bind(_controller.archetype, false))
	box.add_child(new_run)
	var change: Button = Button.new()
	change.text = "更换研究路线"
	change.pressed.connect(_show_archetype_choice)
	box.add_child(change)

func _on_submit() -> void:
	_controller.submit_chain()

func _on_skip() -> void:
	_controller.skip_turn()

func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
