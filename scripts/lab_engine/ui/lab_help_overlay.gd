class_name LabHelpOverlay
extends PanelContainer

signal help_closed

const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")
const EXPLANATION := "目标：8 天内把论文推进到 100。\n\n生产顺序：灵感 → 原始数据 → 整洁数据 → 图表 → 论文\n\n每天只做三个决定：\n1. 从三张候选中选一张，安装、替换或升级工位；也可维护生产线。\n2. 可选一个工位超频：多运行一次，但精力 -1、技术债 +2。\n3. 点击‘开始一天’，观察哪里成功、哪里空转。\n\n技术债 7 以上会随机停机；维护会放弃候选、降低 1 点技术债，并保障未来某日的日初停机。维护不能修复今日停机；最终日维护只降低技术债。\n先让整条生产线运转，再用自动化制造连锁爆发。"

var _close_button: Button
var _previous_focus: Control

func _ready() -> void:
	name = "HelpOverlay"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.modal_backdrop_style())
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "HelpPanel"
	panel.custom_minimum_size = Vector2(620, 430)
	panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.modal_panel_style(Color("62c7ff")))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = "怎么玩：把科研流水线接通"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var explanation := Label.new()
	explanation.text = EXPLANATION
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size", 18)
	explanation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(explanation)
	_close_button = Button.new()
	_close_button.name = "HelpCloseButton"
	_close_button.text = "明白了，开始搭建"
	_close_button.custom_minimum_size = Vector2(0, 48)
	_close_button.pressed.connect(close_help)
	box.add_child(_close_button)
	var self_path := NodePath(".")
	_close_button.focus_neighbor_top = self_path
	_close_button.focus_neighbor_bottom = self_path
	_close_button.focus_neighbor_left = self_path
	_close_button.focus_neighbor_right = self_path
	_close_button.focus_next = self_path
	_close_button.focus_previous = self_path
	_set_focus_enabled(false)
	visible = false

func open_help() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	_previous_focus = focus_owner if focus_owner != null and not is_ancestor_of(focus_owner) else null
	visible = true
	_set_focus_enabled(true)
	_close_button.grab_focus()

func close_help() -> void:
	if not visible:
		return
	visible = false
	_close_button.release_focus()
	_set_focus_enabled(false)
	call_deferred("_restore_previous_focus")
	help_closed.emit()

func _restore_previous_focus() -> void:
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree() and _previous_focus.focus_mode != Control.FOCUS_NONE:
		_previous_focus.grab_focus()
	_previous_focus = null

func _set_focus_enabled(enabled: bool) -> void:
	_close_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_help()
		get_viewport().set_input_as_handled()
