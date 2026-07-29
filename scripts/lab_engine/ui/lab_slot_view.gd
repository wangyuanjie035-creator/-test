class_name LabSlotView
extends Button

const WORKSTATION_ART_SCRIPT := preload("res://scripts/lab_engine/ui/lab_workstation_art.gd")
const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")

const SLOT_TITLES: Array[String] = ["文献台", "实验台", "数据台", "分析台", "写作台", "休息区"]
const DEFAULT_TITLES: Array[String] = ["基础检索", "手工实验", "人工整理", "基础统计", "空白文档", "折叠床"]
const DEFAULT_EFFECTS: Array[String] = ["→ 灵感 +1", "灵感 1 → 原始 2", "原始 4 → 整洁 1", "整洁 1 → 图表 1", "图表 1 → 论文 5", "→ 精力 +1"]

var slot_index: int = 0
var _art: Control
var _title_label: Label
var _equipment_label: Label
var _effect_label: Label
var _status_panel: PanelContainer
var _status_label: Label
var _level_panel: PanelContainer
var _level_label: Label

func setup(index: int) -> void:
	slot_index = index
	custom_minimum_size = Vector2(0, 96)
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_theme_font_size_override("font_size", 16)
	_art = WORKSTATION_ART_SCRIPT.new()
	_art.name = "WorkstationArt%d" % index
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.setup(index)
	add_child(_art)
	_build_content()
	_build_badges()

func refresh(entry: Dictionary, card_title: String, card_effect: String, selected: bool, stopped: bool) -> void:
	var level: int = int(entry.level)
	var equipment: String = DEFAULT_TITLES[slot_index] if level == 0 else card_title
	var effect: String = DEFAULT_EFFECTS[slot_index] if level == 0 else card_effect
	var is_all_nighter: bool = StringName(entry.get("card_id", &"")) == &"all_nighter"
	text = ""
	_title_label.text = SLOT_TITLES[slot_index]
	_equipment_label.text = equipment
	_effect_label.text = "%s · 囤积中" % effect if is_all_nighter and not selected and not stopped else effect
	disabled = stopped or slot_index == 5
	_art.set_state(not stopped, selected)
	_refresh_badges(level, selected, stopped, is_all_nighter)
	_set_style(selected, stopped)

func _build_content() -> void:
	var content_margin := MarginContainer.new()
	content_margin.name = "WorkstationContent"
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", 76)
	content_margin.add_theme_constant_override("margin_right", 88)
	content_margin.add_theme_constant_override("margin_top", 8)
	content_margin.add_theme_constant_override("margin_bottom", 8)
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_margin)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(content)
	_title_label = _make_content_label(17, Color("edf2f1"))
	_equipment_label = _make_content_label(15, Color("d3dedc"))
	_effect_label = _make_content_label(15, Color("d3dedc"))
	content.add_child(_title_label)
	content.add_child(_equipment_label)
	content.add_child(_effect_label)

func _make_content_label(font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _build_badges() -> void:
	_status_panel = PanelContainer.new()
	_status_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_status_panel.offset_left = -80
	_status_panel.offset_top = 8
	_status_panel.offset_right = -8
	_status_panel.offset_bottom = 32
	_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status_panel)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_panel.add_child(_status_label)
	_level_panel = PanelContainer.new()
	_level_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_level_panel.offset_left = -62
	_level_panel.offset_top = 36
	_level_panel.offset_right = -8
	_level_panel.offset_bottom = 58
	_level_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level_panel)
	_level_label = Label.new()
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 10)
	_level_panel.add_child(_level_label)

func _refresh_badges(level: int, selected: bool, stopped: bool, is_all_nighter: bool) -> void:
	var state_kind: StringName = &"stopped" if stopped else &"selected" if selected else &"rest" if slot_index == 5 else &"online"
	_status_label.text = "停机" if stopped else "⚡ 兑现" if selected and is_all_nighter else "⚡ 超频" if selected else "休息" if slot_index == 5 else "在线"
	_status_label.add_theme_color_override("font_color", Color("fff2df") if state_kind in [&"stopped", &"selected"] else Color("d8e8e2"))
	_status_panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.workstation_badge_style(state_kind))
	_level_label.text = "基础" if level == 0 else "LV.%d" % level
	_level_label.add_theme_color_override("font_color", Color("b9c8c6"))
	_level_panel.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.workstation_badge_style(&"level"))

func pulse(success: bool, trigger_type: int, neutral: bool = false) -> void:
	var flash_color: Color = Color("6fa8bd") if neutral else Color("5ec8ff") if trigger_type == 2 else Color("ff8a5b") if trigger_type == 1 else Color("77e0a0")
	if not success:
		flash_color = Color("6fa8bd") if neutral else Color("d96363")
	modulate = flash_color
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.28)

func _set_style(selected: bool, stopped: bool) -> void:
	var style: StyleBoxFlat = VISUAL_STYLE_SCRIPT.workstation_style(selected, stopped)
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", VISUAL_STYLE_SCRIPT.workstation_style(selected, stopped, &"hover"))
	add_theme_stylebox_override("pressed", VISUAL_STYLE_SCRIPT.workstation_style(selected, stopped, &"pressed"))
	add_theme_stylebox_override("focus", VISUAL_STYLE_SCRIPT.workstation_style(true, stopped))
	add_theme_stylebox_override("disabled", style)
