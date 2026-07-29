class_name LabCandidateButton
extends Button

const VISUAL_STYLE_SCRIPT := preload("res://scripts/lab_engine/ui/lab_visual_style.gd")
const PAPER_ART_SCRIPT := preload("res://scripts/lab_engine/ui/lab_candidate_paper_art.gd")

func setup(title: String, slot_title: String, description: String, action_hint: String, category_id: int = 0) -> void:
	custom_minimum_size = Vector2(0, 142)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text = ""
	clip_contents = true
	add_theme_stylebox_override("normal", VISUAL_STYLE_SCRIPT.paper_card_style())
	add_theme_stylebox_override("hover", VISUAL_STYLE_SCRIPT.paper_card_style(true))
	add_theme_stylebox_override("pressed", VISUAL_STYLE_SCRIPT.paper_card_style(true, true))
	add_theme_stylebox_override("focus", VISUAL_STYLE_SCRIPT.paper_card_style(true))
	add_theme_stylebox_override("disabled", VISUAL_STYLE_SCRIPT.paper_card_disabled_style())
	var paper_detail: Control = PAPER_ART_SCRIPT.new()
	add_child(paper_detail)
	_build_content(title, slot_title, description, action_hint, category_id)

func set_selected(value: bool) -> void:
	modulate = Color("ffd38a") if value else Color.WHITE
	add_theme_stylebox_override("normal", VISUAL_STYLE_SCRIPT.paper_card_style(false, false, value))
	add_theme_stylebox_override("focus", VISUAL_STYLE_SCRIPT.paper_card_style(true, false, value))

func _build_content(title: String, slot_title: String, description: String, action_hint: String, category_id: int) -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 14
	margin.offset_top = 10
	margin.offset_right = -14
	margin.offset_bottom = -10
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	margin.add_child(stack)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 7)
	stack.add_child(header)
	var category_badge: PanelContainer = PanelContainer.new()
	category_badge.name = "CategoryBadge"
	category_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	category_badge.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.candidate_badge_style(category_id))
	header.add_child(category_badge)
	var category_label: Label = Label.new()
	category_label.text = _category_name(category_id)
	category_label.add_theme_font_size_override("font_size", 12)
	category_label.add_theme_color_override("font_color", Color("f3ead4"))
	category_badge.add_child(category_label)
	var target_label: Label = Label.new()
	target_label.text = slot_title
	target_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_label.add_theme_font_size_override("font_size", 12)
	target_label.add_theme_color_override("font_color", Color("6b7472"))
	header.add_child(target_label)
	var action_badge: PanelContainer = PanelContainer.new()
	action_badge.name = "ActionBadge"
	action_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_badge.add_theme_stylebox_override("panel", VISUAL_STYLE_SCRIPT.candidate_action_style(action_hint))
	header.add_child(action_badge)
	var action_label: Label = Label.new()
	action_label.text = action_hint
	action_label.add_theme_font_size_override("font_size", 12)
	action_label.add_theme_color_override("font_color", VISUAL_STYLE_SCRIPT.INK)
	action_badge.add_child(action_label)
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", VISUAL_STYLE_SCRIPT.INK)
	stack.add_child(title_label)
	var divider: ColorRect = ColorRect.new()
	divider.color = VISUAL_STYLE_SCRIPT.category_color(category_id).darkened(0.2)
	divider.custom_minimum_size = Vector2(0, 2)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(divider)
	var effect_label: Label = Label.new()
	effect_label.text = description
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.add_theme_color_override("font_color", Color("344447"))
	stack.add_child(effect_label)

func _category_name(category_id: int) -> String:
	return ["文献", "实验", "数据", "分析", "写作", "休息"][clampi(category_id, 0, 5)]
