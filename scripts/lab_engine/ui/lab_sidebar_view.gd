class_name LabSidebarView
extends PanelContainer

const TOPIC_PANEL_SCRIPT := preload("res://scripts/lab_engine/ui/lab_topic_panel.gd")
const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")

signal run_requested
signal skip_requested

var _status_label: Label
var _log_label: RichTextLabel
var _topic_panel: FoldableContainer
var _action_plan_label: Label
var _run_button: Button
var _skip_button: Button

func _ready() -> void:
	name = "Sidebar"
	custom_minimum_size = Vector2(300, 0)
	add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.notebook_cover_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var notebook_title := Label.new()
	notebook_title.name = "NotebookTitle"
	notebook_title.text = "实验记录  /  DAY LOG"
	notebook_title.add_theme_font_size_override("font_size", 13)
	notebook_title.add_theme_color_override("font_color", Color("cbb987"))
	notebook_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	notebook_title.add_theme_constant_override("shadow_offset_y", 1)
	box.add_child(notebook_title)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 17)
	box.add_child(_status_label)
	_topic_panel = TOPIC_PANEL_SCRIPT.new()
	box.add_child(_topic_panel)
	_log_label = RichTextLabel.new()
	_log_label.name = "LogLabel"
	_log_label.bbcode_enabled = true
	_log_label.fit_content = false
	_log_label.scroll_active = true
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_label.add_theme_font_size_override("normal_font_size", 15)
	box.add_child(_log_label)
	var action_plan_panel := PanelContainer.new()
	action_plan_panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.resource_chip_style())
	box.add_child(action_plan_panel)
	_action_plan_label = Label.new()
	_action_plan_label.name = "ActionPlanLabel"
	_action_plan_label.text = "今日计划：尚未选择候选｜不超频"
	_action_plan_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_action_plan_label.add_theme_font_size_override("font_size", 15)
	_action_plan_label.add_theme_color_override("font_color", Color("d8e8e2"))
	action_plan_panel.add_child(_action_plan_label)
	_run_button = Button.new()
	_run_button.name = "RunButton"
	_run_button.text = "开始一天"
	_run_button.custom_minimum_size = Vector2(0, 52)
	_run_button.add_theme_font_size_override("font_size", 19)
	_run_button.pressed.connect(run_requested.emit)
	box.add_child(_run_button)
	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.text = "维护生产线（放弃候选，技术债 -1）"
	_skip_button.pressed.connect(skip_requested.emit)
	box.add_child(_skip_button)

func set_status(text: String) -> void:
	_status_label.text = text

func set_topic(snapshot: Dictionary) -> void:
	_topic_panel.render(snapshot)

func reset_topic() -> void:
	_topic_panel.reset()

func play_topic_settlement_feedback(achieved: bool) -> void:
	_topic_panel.play_settlement_feedback(achieved)

func set_log(text: String, scroll_to_bottom: bool = false) -> void:
	_log_label.text = text
	if scroll_to_bottom:
		_log_label.scroll_to_line(maxi(0, _log_label.get_line_count() - 1))

func append_log(text: String) -> void:
	_log_label.append_text("\n%s" % text)
	_log_label.scroll_to_line(maxi(0, _log_label.get_line_count() - 1))

func set_action_plan(text: String, ready: bool) -> void:
	_action_plan_label.text = text
	_action_plan_label.add_theme_color_override("font_color", Color("7ee0bf") if ready else Color("8fb7c9"))

func set_run_action(text: String, enabled: bool) -> void:
	_run_button.text = text
	_run_button.disabled = not enabled

func set_run_enabled(enabled: bool) -> void:
	_run_button.disabled = not enabled

func set_maintenance_ready(ready: bool, is_final_day: bool, today_stopped: bool) -> void:
	if is_final_day:
		_skip_button.text = "最终日：仅技术债 -1"
		if today_stopped:
			_skip_button.text += "（今日不可修复）"
		return
	var timing_hint := "今日不可修复" if today_stopped else "不修今日"
	_skip_button.text = (
		"维护：仅技术债 -1\n保障已满（%s）" % timing_hint
		if ready
		else "维护：技术债 -1\n保障未来日初停机（%s）" % timing_hint
	)

func set_interaction_enabled(enabled: bool) -> void:
	_run_button.disabled = not enabled
	_skip_button.disabled = not enabled
